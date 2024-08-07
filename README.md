
Quicksearch
===========

Quicksearch is a search-engine-interface for Common Lisp.
The goal of Quicksearch is to find a CL library quickly.
For example, if you want to find libraries about json, just type `(qs:? "json")`
at the REPL.

The function `quicksearch` searches for CL projects on Quicklisp, Cliki,
GitHub and BitBucket, then outputs results in the REPL.
The function `?` is an abbreviation wrapper for `quicksearch`.

`quicksearch` accepts arguments in a long form: `:url`,
`:description`, etc, and `?` has the same in their short form: `:u`,
`:d`, and they are agglutinated: `(qs:? :gq)` to limit the search to `:github` and `:quicklisp`.

Quicksearch was created by @tkych: [https://github.com/tkych/quicksearch](https://github.com/tkych/quicksearch).

About this fork: see our CHANGELOG.

Depends-on
----------

 * [bordeaux-threads](http://common-lisp.net/project/bordeaux-threads/)
 * [alexandria](http://common-lisp.net/project/alexandria/)
 * [anaphora](http://common-lisp.net/project/anaphora/)
 * [cl-ppcre](http://weitz.de/cl-ppcre/)
 * [dexador](https://github.com/fukamachi/dexador/)
 * [html-entities](https://code.google.com/p/html-entities/)
 * [yason](http://common-lisp.net/project/yason/)
 * [flexi-streams](http://weitz.de/flexi-streams/)
 * [do-urlencode](https://github.com/drdo/do-urlencode)


Installation
------------

#### cl-test-grid results:

 - http://common-lisp.net/project/cl-test-grid/library/quicksearch.html


##### Auto:

 0. CL-REPL> `(ql:quickload :quicksearch)`


##### Manual:

 0. SHELL$   `git clone https://github.com/tkych/quicksearch.git`
 1. CL-REPL> `(push #p"/path-to-quicksearch/quicksearch/" asdf:*central-registry*)`
 2. CL-REPL> `(ql:quickload :quicksearch)` or `(asdf:load-system :quicksearch)`


Examples
--------

##### Simple search:

    CL-REPL> (qs:? "crypt") ;<=> (qs:quicksearch "crypt")

    SEARCH-RESULTS: "crypt"

     Quicklisp
     ---------
      crypt
          http://beta.quicklisp.org/archive/cl-crypt/2012-05-20/cl-crypt-20120520-git.tgz
          http://quickdocs.org/cl-crypt/
      crypto-shortcuts
          http://beta.quicklisp.org/archive/crypto-shortcuts/2020-10-16/crypto-shortcuts-20201016-git.tgz
          http://quickdocs.org/crypto-shortcuts/
      ironclad/kdf/bcrypt
          http://beta.quicklisp.org/archive/ironclad/2022-11-06/ironclad-v0.58.tgz
          http://quickdocs.org/ironclad/

     […]

     Cliki
     -----
     ARC4
         http://www.cliki.net/ARC4
         A Common Lisp implementation of ARC4 (trademark: RC4), a stream cipher,
         can be found below
     JARW
         http://www.cliki.net/JARW
         Dr John AR Williams' utilities
     VLM_on_Linux
         http://www.cliki.net/VLM_on_Linux
         This page gives some additional hints on running the Symbolics Virtual
         Lisp Machine (VLM) port to

     GitHub
     ------
        crypto-shortcuts
            https://github.com/Shinmera/crypto-shortcuts
            Collection of common cryptography functions
        cl-crypt
            https://github.com/renard/cl-crypt
            Common-Lisp implementation of unix crypt function
        cl-crypto
            https://github.com/billstclair/cl-crypto
            Pure lisp crypto, written from specs
        cryptopoem
            https://github.com/daniel-cussen/cryptopoem
            Analysis for Virgil's cryptographic epic poem, the Aeneid

      […]

    T

 * If search-results is not null, then results are printed and return T.
 * Since bitbucket-result is null, it is not printed.


##### URL, description:

Quicksearch printed the projects' short description and their URL by default.

To not print them, set their variables to NIL: `*url-print?*` and `*description-print?*`.

    CL-REPL> (qs:? "crypt") ;<=> (qs:quicksearch "crypt" :description t :url t)

 * A symbol (as search-word) is automatically converted into a downcase-string.
 * The function QUICKSEARCH's options are redundant, but explanatory.
 * The function ?'s options are not explanatory, but minimum.

##### Null result:

    CL-REPL> (qs:? "supercalifragilisticexpialidocious") ;<=> (qs:quicksearch "supercalifragilisticexpialidocious")
    NIL

 * If it raises a threading error, probably your CL system might be not support threads.
   In this case, please type `(qs:config :threading? nil)` at REPL, then try it again.
 * If search-results is null, then just return NIL.


##### Search targets, max printed projects

You can use long and short parameters to specify where to search.

Quicksearch defaults to GitHub, Quicklisp, Cliki and bitbucket.

Only search on GitHub with a short `:g` option, and limit the number of printed results to 4:

    CL-REPL> (qs:? "crypt" :g 4) ;<=> (qs:quicksearch "crypt"
                                 ;                    :cut-off 4
                                 ;                    :quicklisp nil :cliki nil :bitbucket nil)

    SEARCH-RESULTS: "crypt"
    =======================

     GitHub
     ------
      cl-crypt
          https://github.com/renard/cl-crypt
      cl-crypto
          https://github.com/bgs100/cl-crypto
      cl-crypto
          https://github.com/billstclair/cl-crypto
      cryptography
          https://github.com/MorganBauer/cryptography
      .......> 2
    T

 * If option `:g` is on, then only GitHub results are printed
   (also `:q` - quicklisp, `:c` - cliki, `:b` - bitbutcket. these options are addable).
 * If cut-off is supplied (above 4), then the number of output results is bellow cut-off
   (the number (above 2) after `.......>` is number of remains).
 * The order of options doesn't change the results.
   (e.g. `:ug 4` <=> `4 :gu` <=> `:u 4 :g` <=> ...).


##### Config:

    CL-REPL> (qs:? "lisp-koans" 1) ;<=> (qs:quicksearch "lisp-koans"
                                   ;                     :cut-off 1)

    SEARCH-RESULTS: "lisp-koans"
    ============================

     GitHub
     ------
      lisp-koans
          https://github.com/google/lisp-koans
          Common Lisp Koans is a language learning exercise in the same vein as the
          ruby koans, python koans and others.   It is a port of the prior koans
          with some modifications to highlight lisp-specific features.  Structured
          as ordered groups of broken unit tests, the project guides the learner
          progressively through many Common Lisp language features.
      .......> 4
    T

    CL-REPL> (qs:config :maximum-columns-of-description 50)
    Current maximum columns of description: 50
    T

    CL-REPL> (qs:? 'lisp-koans :du 1)

    SEARCH-RESULTS: "lisp-koans"
    ============================

     GitHub
     ------
      lisp-koans
          https://github.com/google/lisp-koans
          Common Lisp Koans is a language learning
          exercise in the same vein as the ruby koans,
          python koans and others.   It is a port of
          the prior koans with some modifications to
          highlight lisp-specific features.
          Structured as ordered groups of broken unit
          tests, the project guides the learner
          progressively through many Common Lisp
          language features.
      .......> 4
    T

 * `:maximum-columns-of-description` controls in printing description (default is 80).


Reference Manual
----------------

#### [function] QUICKSEARCH _search-word_ _&key_ _:web_ _:description_ _:url_ _:cut-off_ _:quicklisp_ _:cliki_ _:github_ _:bitbucket_

QUICKSEARCH searches for CL projects with _search-word_ in Quicklisp, Cliki, GitHub and BitBucket.
_search-word_ must be a string, number or symbol (symbol will be automatically converted into downcase-string).


##### Keywords:

 * If _:web_ is NIL, it does not search in Cliki, GitHub and BitBucket.
 * If _:quicklisp_ is NIL, it does not search in Quicklisp (also _:cliki_, _:github_, _:bitbucket_).
 * At least one search-space must be specified.
 * If _:description_ is T, it displays project's descriptions (QuickDocs-url for Quicklisp-search).
 * If _:url_ is T, it display project's url.
 * _:cut-off_ is the max number of results to print for each source. It doesn't limit the number of HTTP requests. See the CONFIG for this.


##### Note: about spaces in the search term

 * About #\Space in _search-word_:

   In case _search-word_ contains #\Space, Quicklisp-search is OR-search,
   whereas Cliki-search, GitHub-, BitBucket- is AND-search.

   e.g. (quicksearch "foo bar")
     Quicklisp-search for "foo" OR "bar".
     Cliki-search, GitHub-, BitBucket- for "foo" AND "bar".


#### [function] ? _search-word_ _&rest_ _options_

? is abbreviation wrapper for function QUICKSEARCH.
_search-word_ must be a string, number or symbol.
_options_ must be a non-negative integer (as Cut-Off) and/or some keywords which consists of some Option-Chars.


##### Examples:

    (? "crypt")
    <=>
    (quicksearch "crypt" :description T :url T :cut-off 50
                         :quicklisp t :cliki t :github t :bitbucket t)

    (? "crypt" :du 10)
    <=>
    (quicksearch "crypt" :description T :url T :cut-off 10
                         :quicklisp t :cliki t :github t :bitbucket t)

    (? "crypt" 20 :g)
    <=>
    (quicksearch "crypt" :description T :url T :cut-off 20
                         :quicklisp nil :cliki nil :github T :bitbucket nil)


##### Options:

 * Cut-Off:
   * The max number of printing results (default is 50).

 * one-letter options (case doesn't matter):
   * d -- output Description (or QuickDocs-url for Quicklisp-search) (t by default)
   * u -- output URL (t by default)
   * q -- search in Quicklisp
   * c -- search in Cliki
   * g -- search in GitHub
   * b -- search in Bitbucket

NOTE: we changed the default (2024-07) to print the short description and
project URL, there is currently no keyword to *not* print them. Use
the global variables or a CONFIG (?).


##### Note:

 * Option-Char is idempotent (e.g. :dd <=> :d).
 * The order of Option-Chars is nothing to do with output. (e.g. :du <=> :ud)
 * If _options_ contains more than 2 Cut-Offs, only last one is applied.
 * The order of _options_ is nothing to do with output (except for some Cut-Offs).
 * If no search space is specified, all spaces is specified (e.g. :d <=> :dqcgb)
 * If at most one search space is specified, then others are not specified.


#### [function] CONFIG _&key_ _maximum-columns-of-description_ _maximum-number-of-fetching-repositories_ _cache-size_ _clear-cache?_ _threading?_ _quicklisp-verbose?_

Function CONFIG customizes printing, fetching or caching.


##### Keywords:

 * _:maximum-columns-of-description_
   The value must be a plus integer bigger than 5.
   If the length of description-string is bigger than this value,
   then output of description is inserted newline for easy to see.
   Default value is 80.

 * _:maximum-number-of-fetching-repositories_
   This value controls the number of fetching repositories.
   The value must be a plus integer.
   Increasing this value, the number of fetching repositories increases, but also space & time does.
   Default value is 50.

 * _:cache-size_
   The value must be a plus integer.
   This value is the number of stored previous search-results.
   Increasing this value, the number of caching results increases, but also space does.
   Default value is 4.

 * _:clear-cache?_
   The value must be a boolean.
   If value is T, then clear all caches.

 * _:threading?_
   The value must be a boolean (default T).
   If value is NIL, then QUICKSEARCH becomes not to use threads for searching.

   Note:
     Currently in SBCL (1.1.8), threads are part of the default build on x86[-64] Linux only.
     Other platforms (x86[-64] Darwin (Mac OS X), x86[-64] FreeBSD, x86 SunOS (Solaris),
     and PPC Linux) experimentally supports threads and must be explicitly enabled at build-time.
     For more details, please see [SBCL manual](http://www.sbcl.org/manual/index.html#Threading).

 * _quicklisp-verbose?_
   The value must be a boolean (default NIL).
   If value is T, then outputs version of quicklisp and whether library had installed your local.

   Example:
```
     CL-REPL> (qs:config :quicklisp-verbose? T)
     CL-REPL> (qs:? "json" :q)

     SEARCH-RESULTS: "json"

      Quicklisp: 2013-04-20   ;<- quicklisp version
       !cl-json               ;<- if library has installed via quicklisp, print prefix "!".
       !cl-json.test
       com.gigamonkeys.json   ;<- if not, none.
       json-template
       st-json
     T
```


##### Note:

If you would prefer permanent config, for example,
add codes something like the following in the CL init file.

In `.sbclrc` for SBCL, `ccl-init.lisp` for CCL:

    (ql:quickload :quicksearch)
    (qs:config :maximum-columns-of-description 50
               :maximum-number-of-fetching-repositories 20
               :cache-size 2
               :threading? nil
               :quicklisp-verbose? t)


#### [special variable] \*USER-AGENT\*

\*user-agent\* tells the server who is requested (i.e. User-Agent header value).
If you are embedding quicksearch in a larger application, you should
change the value of \*user-agent\* to your application name and URL.


TODO
----

- ADD search-space: Common-Lisp.net


Author, License, Copyright
--------------------------

- Takaya OCHIAI  <#.(reverse "moc.liamg@lper.hcykt")>

- MIT License

- Copyright (C) 2013 Takaya OCHIAI
