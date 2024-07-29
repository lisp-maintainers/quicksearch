;;;; Last modified: 2014-04-13 12:04:35 tkych

;; quicksearch/quicksearch.lisp


;;====================================================================
;; Quicksearch
;;====================================================================

(in-package :cl-user)

(defpackage #:quicksearch
  (:nicknames #:qs)
  (:use :cl :iterate)
  (:import-from #:anaphora
                #:aif #:awhen #:it)
  (:export #:quicksearch
           #:?
           #:config
           #:*user-agent*))

(in-package #:quicksearch)

(declaim (inline strip remove-tags))


;;--------------------------------------------------------------------
;; Utilities
;;--------------------------------------------------------------------

(defun str (&rest strings)
  "Concatenates strings"
  (with-output-to-string (s)
    (dolist (string strings)
      (write-string string s))))

(defun map-reduce (reducer mapper sequence)
  "
MAP-REDUCE is suitable for only the case that `mapper''s cost is much
expensive (e.g. QUICKSEARCH invokes DRAKMA:HTTP-REQUEST as `mapper').
For each element in `sequence' (as an argument), `mapper' is computed it
with each thread, then the results are collected by `reducer'.

Examples: (inefficient but intuitive)

  (map-reduce #'+
              (lambda (x) (expt x 2)) ;<- each thread computes this
              '(1 2 3 4))
   => 30

  (map-reduce #'append
              (lambda (x) (list (expt x 2)))
              '(1 2 3 4))
   => (1 4 9 16)

  (map-reduce (lambda (x y) (format nil \"~A~A\" x y))
              (lambda (c) (code-char (1- (char-code c))))
             \"IBM\")
   => \"HAL\"

Note:
  * Use only for expensive computation (e.g. fetching a resource on the
    web).
  * If `mapper' assigns a value for the same global variable, it will
    cause interleave.
  * Strictly, this MAP-REDUCE is not the MapReduce, but abstract model
    is the same if threads are equated with worker nodes.
"
  (reduce reducer
          (map 'vector
               (lambda (x)
                 (bordeaux-threads:make-thread
                  (lambda () (funcall mapper x))))
               sequence)
          :key #'bordeaux-threads:join-thread))


;;--------------------------------------------------------------------
;; Main
;;--------------------------------------------------------------------
;; <word>  ::= <string>
;; <source> ::= <symbol>, s.t. {quicklisp | github | cliki | bitbucket}
;; <repo>  ::= (<title> <url> <description>)
;; <repos> ::= (<repo>*)
;; <title> ::= <string>
;; <url>   ::= <string>
;; <description> ::= {<string> | NIL}

(defparameter *quicksearch-version* "0.1.03")
(defparameter *quicksearch-webpage* "http://tkych.github.io/quicksearch/")

(defparameter *user-agent*
  (format nil "Quicksearch/~A (~A ~A; ~A; ~A; ~A)"
          *quicksearch-version*
          (lisp-implementation-type)
          (lisp-implementation-version)
          (software-type)
          (software-version)
          *quicksearch-webpage*)
  "This value tells the server who is requested (i.e. User-Agent header
value). If you are embedding Quicksearch in a larger application, you
should change the value of *USER-AGENT* to your application name and
URL.")

(defvar *threading?* t)
(defparameter *description-print?* nil)
(defparameter *url-print?* nil)
(defparameter *cut-off* 50 "The maximum number of results to print, for each source.

This parameter doesn't control the number of HTTP requests.")
(defparameter *print-title?* nil)

(defun quicksearch (search-word &key
                                  (?web         t   ?web-p)
                                  (web          t)
                                  (?description nil ?description-p)
                                  (description  nil)
                                  (?url         nil ?url-p)
                                  (url          nil)
                                  (?cut-off     50  ?cut-off-p)
                                  (cut-off      50)
                                  (?quicklisp   t   ?quicklisp-p)
                                  (quicklisp    t)
                                  (?cliki       t  ?cliki-p)
                                  (cliki        t)
                                  (?github      t  ?github-p)
                                  (github       t)
                                  (bitbucket    t)
                                  (?bitbucket   t  ?bitbucket-p)
                                  ;; no impact on the results:
                                  ;; open all results in the browser?
                                  (browse nil))
  ;; 2020/03: ?key are deprecated.

  "Search for CL projects with `search-word' in Quicklisp, Cliki, GitHub
and BitBucket. `search-word' must be a string, number or symbol (symbol
will be automatically converted into downcase-string).

QUICKSEARCH accepts arguments in their long form. The function `?' is
an alias that accepts the same arguments with a short form, such as `:u'
instead of `:url'.

Keywords:
 * If `web' is NIL, it searches only on Quicklisp and does not search on Cliki, GitHub or BitBucket.
 * If `quicklisp' is NIL, it does not search on Quicklisp (also
   `cliki', `github', `bitbucket').
 * At least one search-source must be specified.
 * If `description' is T, it displays project's descriptions (except
   for Quicklisp-search).
 * If `url' is T, it display project's url.
 * `cut-off' is the max number of printing repositories for each source.

Note:
 * the keyword `cut-off' controls only printing results, nothing to do with
   the maximum number of fetching repositories (see. function CONFIG
   documentation).

 * About #\\Space in `search-word':
   When `search-word' contains a #\\Space, Quicklisp-search is
   OR-searched, whereas Cliki-search, GitHub- and BitBucket- are AND-searched.
   e.g. (quicksearch \"foo bar\")
        Quicklisp-search for \"foo\" OR \"bar\",
        Cliki-search, GitHub-, BitBucket- for \"foo\" AND \"bar\"."

  (declare (ignore ?web ?description ?url ?cut-off ?quicklisp ?cliki ?github ?bitbucket))
  (when (or ?web-p ?description-p ?url-p ?cut-off-p ?quicklisp-p ?cliki-p ?github-p ?bitbucket-p)
    (error "Arguments starting with '?' have been deprecated. Please simply use :web, :description, :url, etc."))
  (check-type search-word  (or string symbol))
  (check-type web         boolean)
  (check-type description boolean)
  (check-type url         boolean)
  (check-type cut-off     (integer 1 *))
  (check-type quicklisp   boolean)
  (check-type cliki       boolean)
  (check-type github      boolean)
  (check-type bitbucket   boolean)

  (let ((*url-print?* url)
        (*description-print?* description)
        (*cut-off* cut-off)
        (word (write-to-string search-word :case :downcase :escape nil))
        (found? nil)
        (*print-title?* nil)   ;no result, no print
        (threads '()))

    (dolist (source '(cliki github bitbucket))
      (setf (get source :error-report) nil))

    (when (and web *threading?* bordeaux-threads:*supports-threads-p*)
      ;; MAP Phase:
      ;; (Strictly, the following is not the MapReduce,
      ;;  but abstract model is the same if threads are equated with
      ;;  worker nodes.)
      (let ((drakma:*drakma-default-external-format* :utf-8))
        ;; (print 'threading) ;for DBG
        (loop :for source   :in '(cliki github bitbucket)
           :for search? :in (list cliki github bitbucket) :do
           (when (and search? (not (in-cache-p word source)))
             ;; Search word in the web, and Store result into cache.
             ;; Since each source has its own cache, lock isn't need.
             (push (search-web-by-thread word source) threads)))))

    #+quicklisp                         ;for build
    (when quicklisp
      ;; quicklisp-search is OR-search
      (dolist (w (ppcre:split " " word))
        (awhen (search-quicklisp w)
          (once-only-print-search-results word)
          (print-results it 'quicklisp)
          (setf found? t))))

    (when web
      (if (and *threading?* bordeaux-threads:*supports-threads-p*)
          (progn                        ;REDUCE Phase:
            ;; (print 'threading) ;for DBG
            (dolist (th threads) (bordeaux-threads:join-thread th))
            (loop
               :for source   :in '(cliki github bitbucket)
               :for search? :in (list cliki github bitbucket) :do
               (when search?
                 (aif (get source :error-report)
                      (progn
                        (once-only-print-search-results word)
                        (princ it))
                      (let ((search-result (search-cache word source)))
                        (when search-result
                          (once-only-print-search-results word)
                          (print-results search-result source)
                          (setf found? t)))))))

          (loop                         ;not using threads
             :for source   :in '(cliki github bitbucket)
             :for search? :in (list cliki github bitbucket) :do
             (when search?
               ;; (print 'non-threading) ;for DBG
               (multiple-value-bind
                     (repos stored?) (search-cache word source)
                 (if stored?
                     (progn
                       (once-only-print-search-results word)
                       (print-results repos source)
                       (setf found? t))
                     ;; fetch before get error-report
                     (let ((search-result (search-web word source)))
                       (aif (get source :error-report)
                            (progn
                              (once-only-print-search-results word)
                              (princ it))
                           (when search-result
                             (once-only-print-search-results word)
                             (print-results search-result source)
                             (setf found? t))))))))))

    found?))


;;--------------------------------------------------------------------
;; Search Sources
;;--------------------------------------------------------------------

;; for print search-source name
(setf (get 'quicklisp :name) "Quicklisp"
      (get 'cliki     :name) "Cliki"
      (get 'github    :name) "GitHub"
      (get 'bitbucket :name) "BitBucket")

;; for print url
(setf (get 'quicklisp :host) "~A"
      (get 'cliki     :host) "http://www.cliki.net~A"
      (get 'github    :host) "~A"       ;api-v3
      ;; (get 'github    :host) "https://github.com/~A" ;advanced
      (get 'bitbucket :host) "https://bitbucket.org~A")

;; for generate query
(setf (get 'cliki :query-format)
      "http://www.cliki.net/site/search?query=~A")

;; github api-v3 search
(setf (get 'github :query-format)
      "https://api.github.com/legacy/repos/search/~A~
       ?language=Common%20Lisp")

;; github advanced search
;; (setf (get 'github :query-format)
;;       "https://github.com/search?q=~A~
;;        &type=Repositories&ref=advsearch&l=Common+Lisp")

(setf (get 'bitbucket :query-format)
      "https://bitbucket.org/repo/all/relevance?name=~A~
       &language=common+lisp")

;; drakma options
(setf (get 'cliki     :drakma-options) nil
      (get 'github    :drakma-options) '(:preserve-uri t)
      (get 'bitbucket :drakma-options) '(:preserve-uri t))


;;--------------------------------------------------------------------
;; Search-Quicklisp
;;--------------------------------------------------------------------

(defvar *quicklisp-verbose?* nil)

#+quicklisp  ;for build
(progn

  (defparameter *installed-prefix* "!")

  (defun search-quicklisp (word)
    (loop
       :for sys :in (ql-dist:provided-systems t)
       :when (or (search word (ql-dist:name sys))
                 (search word (ql-dist:name (ql-dist:release sys))))
       :collect (list (get-title sys)
                      (when *url-print?*
                        (get-url sys))
                      (when *description-print?*
                        (get-quickdocs-url sys)))
       :into results
       :finally (progn
                  (when *quicklisp-verbose?* (set-version sys))
                  (return results))))

  (defun get-title (sys)
    (if (and *quicklisp-verbose?* (installed-p sys))
        (str *installed-prefix* (ql-dist:name sys))
        (ql-dist:name sys)))

  (defun installed-p (sys)
    (handler-case (not (ql-dist:check-local-archive-file
                        (ql-dist:release sys)))
      (ql-dist:missing-local-archive () nil)))

  (defun get-url (sys)
    ;; Memo: 2013-08-08 by tkych
    ;; Don't exchange the following conditional-clause
    ;; (ql:where-is-system (ql-dist:name sys)).
    ;; ql:where-is-system contains asdf:find-system, and
    ;; (asdf:find-system "asdf-encodings") might reload asdf.
    ;; Added: 2013-08-12 by tkych
    ;; This is not a problem if asdf is the latest version.
    (aif (nth-value 2 (asdf:locate-system (ql-dist:name sys)))
         (str (directory-namestring it)
              #.(format nil "~%      ")
              (slot-value (ql-dist:release sys)
                          'ql-dist::archive-url))
         (slot-value (ql-dist:release sys)
                     'ql-dist::archive-url)))

  (defun set-version (sys)
    (setf (get 'quicklisp :name)
          (str "Quicklisp: " (ql-dist:version (ql-dist:dist sys)))))

  (defun get-quickdocs-url (sys)
    (format nil "http://quickdocs.org/~A/"
            (ql-dist:name (ql-dist:release sys))))

  )  ;end of #+quicklisp


;;--------------------------------------------------------------------
;; Search-Cache
;;--------------------------------------------------------------------
;; <cache> ::= <hashtable> stored previous search results.
;;             For non-lock threads, each source has its own cache in
;;             symbol-plist.
;;             max-size = *cache-size* + 1
;;             [key, val] = {[<word>, <repos>] | [:history, <history>]}
;; <histroy> ::= (<word>*), max-length = *cache-size*, using as queue.
;;               The front one is the most old, last one is the most
;;               new.

(defparameter *cache-size* 4)

(defun make-cache ()                    ;for config
  (setf (get 'cliki      :cache)
        (make-hash-table :test #'equal :size (1+ *cache-size*)))
  (setf (get 'github     :cache)
        (make-hash-table :test #'equal :size (1+ *cache-size*)))
  (setf (get 'bitbucket  :cache)
        (make-hash-table :test #'equal :size (1+ *cache-size*))))

(make-cache)

(defun clear-cache ()
  (dolist (source '(cliki github bitbucket))
    (clrhash (get source :cache)))
  t)

(defun search-cache (word source)
  (gethash word (get source :cache) nil))

(defun in-cache-p (word source)
  (nth-value 1 (gethash word (get source :cache) nil)))

(defun store-cache (word repos source)
  (let* ((cache   (get source :cache))
         (history (gethash :history cache '())))
    ;; If cache is full, then remove the most old one
    (when (<= *cache-size* (length history))
      (remhash (pop history) cache))
    (setf (gethash word (get source :cache))
          repos)
    (setf (gethash :history (get source :cache))
          (append history (list word)))))


;;--------------------------------------------------------------------
;; Search-Web
;;--------------------------------------------------------------------
;; 1. FETCH word from source
;; 2. EXTRACT repos from response
;; 3. GOTO 1 if next page exists (word <-- next-url)
;; 4. STORE repos in cache
;; 5. RETURN repos

(defun search-web (word source)
  (let* ((response (handler-case
                       (fetch (gen-query word source) source)
                     (error (c)
                       (RETURN-FROM search-web
                         (progn
                           (setf (get source :error-report)
                                 (format nil "~2& ~A~%  Failed [~S]~%"
                                         (get source :name)
                                         (class-name (class-of c))))
                           nil)))))
         (repos    (extract-repos response source)))
    (awhen (extract-next-page-url response source)
      (if *threading?*
          (alexandria:appendf repos
            (map-reduce #'append
                        (lambda (url)
                          (extract-repos (fetch url source) source))
                        it))
          (loop
             :for url :in it
             :for res := (fetch url source)
             :do (alexandria:appendf
                  repos (extract-repos res source)))))
    (store-cache word repos source)
    repos))

(defun search-web-by-thread (word source)
  (bordeaux-threads:make-thread
   (lambda () (search-web word source))
   :name (format nil "~(~A~)-search" source)))


;;--------------------------------------
;; github api-v3 search
(defun gen-query (word source)
  (format nil (get source :query-format)
          (if (eq source 'github)
              (do-urlencode:urlencode word)
              (nsubstitute #\+ #\Space word :test #'char=))))

;; github advanced search
;; (defun gen-query (word source)
;;   (format nil (get source :query-format)
;;           (nsubstitute #\+ #\Space word :test #'char=)))

(defun fetch (query source)
  (apply #'drakma:http-request query
         :user-agent *user-agent* (get source :drakma-options)))


;;--------------------------------------
;; dispatch for extract repositories

(defun extract-repos (response source)
  (case source
    (cliki     (extract-cliki-repos response))
    (github    (extract-github-repos response))
    (bitbucket (extract-bitbucket-repos response))))

(defun strip (string)
  (string-trim '(#\Space #\Return #\Newline) string))

(defun remove-tags (string)
  (ppcre:regex-replace-all "(<.+?>)" string ""))

(defun extract-cliki-repos (response)
  (let* ((results (ppcre:scan-to-strings
                   "(?s)<ol start=.+?>(.+?)</ol>" response))
         (repos (ppcre:all-matches-as-strings
                 "(?s)<li>(.+?)</li>" results)))
    (when repos
      (iter (for repo :in repos)
            (ppcre:register-groups-bind (url title description)
                ("(?s)<li><a href=\"(.+?)\" class=\"internal\">(.+?)</a>\\s?<br\\s?/?>(.+?)</li>"
                 repo)
              (collect (list title url
                             (let ((desc (strip (remove-tags description))))
                               (when (string/= "" desc) desc)))))))))

;; Memo: 2014-04-13 by tkych
;;  Adding `response-string' is to fix the bug which is caused that a string
;;  is given to `octets-to-string'. This bug was found and fixed by g000001,
;;  thanks!
;;  c.f. http://g000001.cddddr.org/3606044400
(defun response-string (response)
  #+#:Error-2014-04-08
  ;; This sequence can't be decoded using UTF-8 as it is too short.
  ;;  2 octets missing at the end.
  (flexi-streams:octets-to-string response :external-format :utf-8)
  #-#:Error-2014-04-08
  (etypecase response
    (STRING response)
    (VECTOR
     (flexi-streams:octets-to-string response :external-format :utf-8))))

;; github api-v3 search
(defun extract-github-repos (response)
  (let* ((jason (yason:parse (response-string response))))
    (loop :for repo :in (gethash "repositories" jason)
          :unless (gethash "fork" repo)   ;only master is displayed
          :collect (list (gethash "name" repo)
                         (gethash "url" repo)
                         (let ((desc (gethash "description" repo)))
                           (unless (string= "" desc)
                             desc))))))

;; github advanced search
;; (defun extract-github-repos (response)
;;   (let* ((results (ppcre:scan-to-strings
;;                    "(?s)<ul class=\"repolist js-repo-list\">(.+<!-- /.body -->)"
;;                    response))
;;          (repos (ppcre:all-matches-as-strings
;;                  "(?s)<h3>(.+?)</p>"
;;                  results)))
;;     (when repos
;;       (iter (for repo :in repos)
;;             (ppcre:register-groups-bind (url title)
;;                 ("(?s)<h3>.+?<a href=\"/(.+?)\">.+?/(.+?)</a>" repo)
;;               (collect
;;                   (list (ppcre:regex-replace-all "</?em>" title "")
;;                         url
;;                         (ppcre:register-groups-bind (description)
;;                             ("(?s)<p class=\"description\">(.+?)</p>" repo)
;;                           (strip (remove-tags description))))))))))

(defun extract-bitbucket-repos (response)
  (let* ((results (ppcre:scan-to-strings
                   "(?s)<section id=\"repo-list\">(.+?)</section>"
                   response))
         (repos (ppcre:all-matches-as-strings
                 "(?s)<article class=\"repo-summary\">(.+?)</article>"
                 results)))
    (when repos
      (iter (for repo :in repos)
            (ppcre:register-groups-bind (url title)
                ("(?s)<a class=\"repo-link\" href=\"(.+?)\">.+? / (.+?)</a>"
                 repo)
              (collect (list title url
                             (ppcre:register-groups-bind (description)
                                 ("(?s)<p>(.+?)</p>" repo)
                               (strip (remove-tags description))))))))))


;;--------------------------------------
;; dispatch for extracting next url
(defun extract-next-page-url (response source)
  (case source
    (cliki     (extract-cliki-next-page-url response))
    (github    (extract-github-next-page-url response))
    (bitbucket (extract-bitbucket-next-page-url response))))

(defvar *max-num-web-search-results* 50)
(defvar *num-results-per-page* 10)

(defun max-num-next-pages ()
  (ceiling (- *max-num-web-search-results* *num-results-per-page*)
           *num-results-per-page*))

(defun extract-cliki-next-page-url (response)
  (let ((urls nil)
        (paginator (ppcre:scan-to-strings
                    "(?s)<div id=\"paginator\">(.+?)</div>" response)))
    (ppcre:do-register-groups (query)
        ("<a href=\"\\\?query=(.+?)\">" paginator)
      (push (gen-query query 'cliki) urls))
    (let ((rest-urls (nreverse (rest urls)))) ;first and last is the same.
      (subseq rest-urls
              0 (min (max-num-next-pages) (length rest-urls))))))

;; github api-v3 search
(defun extract-github-next-page-url (response)
  (declare (ignore response))
  nil)

;; for github advanced search
;; (defun extract-github-next-page-url (response)
;;   (let ((urls nil)
;;         (pagination
;;          (ppcre:scan-to-strings
;;           "(?s)<div class=\"pagination\"(.+?)</div>" response)))
;;     (ppcre:do-register-groups (next-url)
;;         ("<a href=\"(.+?)\"( (class|rel).+?)?>" pagination)
;;       (push (format nil "https://github.com~A"
;;                     (html-entities:decode-entities next-url))
;;             urls))
;;     (let ((rest-urls (nreverse (rest urls)))) ;first and last is the same.
;;       ;; (print rest-urls) ;for dbg
;;       (subseq rest-urls
;;               0 (min (max-num-next-pages) (length rest-urls))))))

(defun extract-bitbucket-next-page-url (response)
  (let ((urls nil)
        (paginator (ppcre:scan-to-strings
                    "(?s)<ol class=\"paginator\">(.+?)</ol>" response)))
    (ppcre:do-register-groups (next-url)
        ("<a href=\"(.+?)\">" paginator)
      (push next-url urls))
    (let ((rest-urls (nreverse (rest urls)))) ;first and last is the same.
      (subseq rest-urls
              0 (min (max-num-next-pages) (length rest-urls))))))


;;--------------------------------------------------------------------
;; Print-Results
;;--------------------------------------------------------------------

(defparameter *max-num-description-columns* 80)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defparameter *description-indent-num* 6))

(defun print-line (n char)
  (format t "~a~&" (make-string n :initial-element char)))

(defun print-title (word)
  (let ((title (format nil "~%SEARCH-RESULTS: ~S~%" word)))
    (format t "~a~&" title)
    (format t "~a~&" (print-line (- (length title) 2)
                                 #\=))))

(defun gen-url (url source)
  (format nil (get source :host) url))

(defun print-source (source)
  (format t "~% ~A~%" (get source :name))
  (when (or *description-print?* *url-print?*)
    (format t " ") (print-line (length (get source :name)) #\-)))

(defun once-only-print-search-results (word)
  ;; only when search-result has not printed yet, print it.
  (unless *print-title?*
    (print-title word)
    (setf *print-title?* t)))

(defun print-results (repos source)
  (when repos
    (print-source source)
    (loop :for (title url desc) :in repos
          :repeat *cut-off* :do
       (format t "~&  ~A" (html-entities:decode-entities title))
       (when *url-print?*
         (format t "~%      ~A" (gen-url url source)))
       (when *description-print?*
         (pprint-description
          (html-entities:decode-entities desc))))
    (when (< *cut-off* (length repos))
      (format t "~&  .......> ~D" (- (length repos) *cut-off*)))
    (terpri)
    t))

(defun pprint-description (desc)
  (when desc
    (let ((len (length desc))
          (max-nchars (- *max-num-description-columns*
                         *description-indent-num*)))
      (if (<= len max-nchars)
          (format t "~%      ~A" desc)
          (let ((source-pos
                 (loop :for i :downfrom max-nchars :to 0
                       :until (char= #\Space (char desc i))
                       :finally (return (1+ i)))))
            (if (zerop source-pos)
                (progn
                  (format t "~%      ~A-" (subseq desc 0 (1- max-nchars)))
                  (pprint-description (subseq desc (1- max-nchars))))
                (progn
                  (format t "~%      ~A" (subseq desc 0 (1- source-pos)))
                  (pprint-description (subseq desc source-pos)))))))))


;;--------------------------------------------------------------------
;; Configuration for Quicksearch
;;--------------------------------------------------------------------

(defun config (&key
                 ((:maximum-columns-of-description max-cols)
                  80  max-cols-supplied?)
                 ((:maximum-number-of-fetching-repositories max-repos)
                  50  max-repos-supplied?)
                 (cache-size         4   cache-size-supplied?)
                 (clear-cache?       nil clear-cache-supplied?)
                 (threading?         t   threading-supplied?)
                 (quicklisp-verbose? nil quicklisp-verbose-supplied?))

  "Function CONFIG customizes printing, fetching or caching.
If CONFIG is called with no keyword, then it sets default values.

Keywords:

 * `:maximum-columns-of-description' (default 80)
   The value must be a plus integer bigger than 5.
   If the length of description-string is bigger than this value,
   then output of description is inserted newline for easy to see.

 * `:maximum-number-of-fetching-repositories' (default 50)
   This value controls the number of fetching repositories.
   The value must be a plus integer.
   Increasing this value, the number of fetching repositories increases,
   but also source & time does.

 * `:cache-size'
   The value must be a plus integer (default 4).
   This value is the number of stored previous search-results.
   Increasing this value, the number of caching results increases, but
   also source does.

 * `:clear-cache?'
   The value must be a boolean (default NIL).
   If value is T, then clear all caches.

 * `:threading?'
   The value must be a boolean (default T).
   If value is NIL, then QUICKSEARCH becomes not to use threads for
   searching.

   Note:
     Currently on SBCL (1.1.8), threads are part of the default build on
     x86[-64] Linux only. Other platforms (x86[-64] Darwin (Mac OS X),
     x86[-64] FreeBSD, x86 SunOS (Solaris), and PPC Linux)
     experimentally supports threads and must be explicitly enabled at
     build-time. For more details, please see [SBCL manual](http://www.sbcl.org/manual/index.html#Threading).

 * `:quicklisp-verbose?'
   The value must be a boolean (default NIL).
   If value is T, then outputs version of quicklisp and whether library
   had installed your local.

   Example:
     CL-REPL> (qs:config :QUICKLISP-VERBOSE? t)
     CL-REPL> (qs:? \"json\" :q)

     SEARCH-RESULTS: \"json\"

      Quicklisp: 2013-04-20   ;<- quicklisp version
       !cl-json               ;<- if library has been installed via quicklisp, print prefix \"!\".
       !cl-json.test
       com.gigamonkeys.json   ;<- if not, none.
       json-template
       st-json
     T

Note:
 * If you would prefer permanent configuration,
   for example, add codes something like the following in the CL init
   file.

   In `.sbclrc` for SBCL, `ccl-init.lisp` for CCL:

   (ql:quickload :quicksearch)
   (qs:config :maximum-columns-of-description 50
              :maximum-number-of-fetching-repositories 20
              :cache-size 10
              :threading? nil
              :quicklisp-verbose? t)"

  (let ((result nil))
    (if (not (or max-cols-supplied?  max-repos-supplied?
                 cache-size-supplied? clear-cache-supplied?
                 threading-supplied? quicklisp-verbose-supplied?))
        (progn
          (setf *max-num-description-columns* 80
                *max-num-web-search-results*  50
                *cache-size*          4
                *threading?*          t
                *quicklisp-verbose?*  nil)
          (make-cache)
          (format t "~&Default Setting.")
          (setf result t))
        (progn

          (when max-cols-supplied?
            (check-type max-cols (not (mod #.(1+ *description-indent-num*))))
            (setf *max-num-description-columns* max-cols)
            (format t "~&Current maximum columns of description: ~D"
                    *max-num-description-columns*)
            (clear-cache)
            (setf result t))

          (when max-repos-supplied?
            (check-type max-repos-supplied? (integer 1 *))
            (setf *max-num-web-search-results* max-repos)
            (format t "~&Current maximum number of fetching repositories: ~D"
                    *max-num-web-search-results*)
            (setf result t))

          (when cache-size-supplied?
            (check-type cache-size (integer 0 *))
            (setf *cache-size* cache-size)
            (make-cache)
            (format t "~&Current cache size: ~D"  *cache-size*)
            (setf result t))

          (when clear-cache-supplied?
            (check-type clear-cache? boolean)
            (when clear-cache?
              (clear-cache)
              (format t "All caches cleaned.")
              (setf result t)))

          (when threading-supplied?
            (check-type threading? boolean)
            (if (and threading? (not bordeaux-threads:*supports-threads-p*))
                (warn "Your CL system does not support threading.")
                (progn
                  (setf *threading?* threading?)
                  (format t "~&Using threads for searching: ~S" threading?)
                  (setf result t))))

          (when quicklisp-verbose-supplied?
            (check-type quicklisp-verbose? boolean)
            (setf *quicklisp-verbose?* quicklisp-verbose?)
            (format t "~&Quicklisp verbose: ~A" quicklisp-verbose?)
            (unless quicklisp-verbose?
              (setf (get 'quicklisp :name) "Quicklisp"))
            (setf result t))
          ))

    result))


;;--------------------------------------------------------------------
;; Abbreviation for Quicksearch
;;--------------------------------------------------------------------

(defun ? (search-word &rest options)
  "? is an abbreviation wrapper for the function QUICKSEARCH.

Search options can be aggregated has letters in one keyword. Example:

(qs:? \"foo\" :ud)

is expanded as:

(qs:quicksearch \"foo\" :url t :description t)

`search-word' must be a string, number or symbol. `options' must be a
non-negative integer (as Cut-Off) and/or some keywords which consists of
some Option-Chars.

Options:
 * :cut-off:
   * The max number of printing results (default is 50). See also `*cut-off*'.
 * one-letter options (case doesn't matter):
   * d -- output Description
   * u -- output URL
   * q -- search in Quicklisp
   * c -- search in Cliki
   * g -- search in GitHub
   * b -- search in Bitbucket

Note:
 * Option-Char is idempotent (e.g. :dd <=> :d).
 * If `options' contains more than 2 :cut-off options, only the last one is applied.
 * The order of options doesn't matter (e.g. :du <=> :ud).
 * If no search-source is specified, all sources are specified
   (e.g. :d <=> :dqcgb).
 * If at most one search-source is specified, then the others are not
   specified.

Examples:
  (? \"crypt\")
  <=>
  (quicksearch \"crypt\" :description nil :url nil :cut-off 50
                       :quicklisp t :cliki t :github t :bitbucket t)

  (? \"crypt\" :du 10)
  <=>
  (quicksearch \"crypt\" :description T :url T :cut-off 10
                       :quicklisp t :cliki t :github t :bitbucket t)

  (? \"crypt\" 20 :g :d)
  <=>
  (quicksearch \"crypt\" :description T :url nil :cut-off 20
                       :quicklisp nil :cliki nil :github T :bitbucket nil)"

  (let ((cut-off *cut-off*)
        (d nil) (u nil) (q nil) (c nil) (g nil) (b nil))
    (dolist (opt options)
      (cond ((keywordp opt)
             (loop :for char :across (symbol-name opt) :do
                (case char
                  ((#\D #\d) (setf d t))
                  ((#\U #\u) (setf u t))
                  ((#\Q #\q) (setf q t))
                  ((#\C #\c) (setf c t))
                  ((#\G #\g) (setf g t))
                  ((#\B #\b) (setf b t))
                  (t         (error "~A is unknown option." char)))))
            ((and (integerp opt) (not (minusp opt)))
             (setf cut-off opt))
            (t
             (error "~S is neither keyword nor non-negative-integer."
                    opt))))
    (if (or q c g b)
        (quicksearch search-word
                     :description d :url u :cut-off cut-off
                     :quicklisp q :cliki c :github g :bitbucket b)
        (quicksearch search-word
                     :description d :url u :cut-off cut-off
                     :quicklisp T :cliki T :github T :bitbucket T))))


;;====================================================================
