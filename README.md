Last modified : 2013-06-11 19:42:49 tkych

Version: 0.0.92 (alpha)


Quicksearch: Search CL Library, Quickly
=======================================

Quicksearch is a search-engine-interface for Common Lisp.
The goal of Quicksearch is to find the CL library quickly.
For example, if you will find the library about json, just type `(qs:? "json")` at REPL.

The function QUICKSEARCH searches for CL projects in Quicklisp, Cliki, 
Github and BitBucket, then outputs results in REPL.
The wrapper function ? is abbreviation for QUICKSEARCH.


Depends-on
----------

 * [iterate](http://common-lisp.net/project/iterate/)
 * [alexandria](http://common-lisp.net/project/alexandria/)
 * [anaphora](http://common-lisp.net/project/anaphora/)
 * [cl-ppcre](http://weitz.de/cl-ppcre/)
 * [drakma](http://weitz.de/drakma/)
 * [html-entities](https://code.google.com/p/html-entities/)
 * [bordeaux-threads](http://common-lisp.net/project/bordeaux-threads/)


Installation
------------

0. SHELL>   `git clone https://github.com/tkych/quicksearch.git`
1. CL-REPL> `(push #p"/path-to-quicksearch/quicksearch/" asdf:*central-registry*)`
2. CL-REPL> `(ql:quickload :quicksearch)`


Examples
--------

##### Null result:
```lisp
CL-REPL> (qs:? "supercalifragilisticexpialidocious") ;<=> (qs:quicksearch "supercalifragilisticexpialidocious")
NIL
```

 * If it raises a threading error, probably your CL system might be not support threads.
   In this case, please type `(qs:config :threading-p nil)` at REPL, then try it again.
 * If search-results is null, then just return NIL.
 

##### Simple search:
```lisp
CL-REPL> (qs:? "crypt") ;<=> (qs:quicksearch "crypt")

SEARCH-RESULTS: "crypt"

 Quicklisp
  crypt

 Cliki
  ARC4
  JARW
  VLM_on_Linux

 GitHub
  cl-crypt
  cl-crypto
  cl-crypto
  cryptography
  cryptoschool
  Cryptopsaras
T
```

 * If search-results is not null, then results are printed and return T.
 * Since bitbucket-result is null, it is not printed.


##### Description:
```lisp
CL-REPL> (qs:? 'Crypt :d) ;<=> (qs:quicksearch 'Crypt :?description t)

SEARCH-RESULTS: "crypt"
=======================

 Quicklisp
 ---------
  crypt

 Cliki
 -----
  ARC4
      A Common Lisp implementation of ARC4, a Cryptography code, can be found on
      the
  JARW
      Dr John AR Williams' utilities
  VLM_on_Linux
      Instructions for running the Symbolics VLM virtual machine on Linux

 GitHub
 ------
  cl-crypt
      Common-Lisp implementation of unix crypt function
  cl-crypto
      A common lisp package of ciphers, public-key algorithms, etc.
  cl-crypto
      Pure lisp crypto, written from specs
  cryptography
      implementations of ciphers for cryptography class
  cryptoschool
      Lisp files related to the cryptography class being taught by Ben Warner
  Cryptopsaras
      Reads files generated by Acinonyx.
T
```

 * A symbol (as search-word) is automatically converted into a downcase-string.
 * If option `:d` is on, then the description of the project is printed (except for Quicklisp-search).
 * The function QUICKSEARCH's options are redundant, but explanatory.
 * The function ?'s options are not explanatory, but minimum.


##### URL, Space, Cutoff:
```lisp
CL-REPL> (qs:? "crypt" :dug 4) ;<=> (qs:quicksearch "crypt"
                               ;                    :?description t :?url t :?cut-off 4
                               ;                    :?quicklisp nil :?cliki nil :?bitbucket nil)

SEARCH-RESULTS: "crypt"
=======================

 GitHub
 ------
  cl-crypt
      https://github.com/renard/cl-crypt
      Common-Lisp implementation of unix crypt function
  cl-crypto
      https://github.com/bgs100/cl-crypto
      A common lisp package of ciphers, public-key algorithms, etc.
  cl-crypto
      https://github.com/billstclair/cl-crypto
      Pure lisp crypto, written from specs
  cryptography
      https://github.com/MorganBauer/cryptography
      implementations of ciphers for cryptography class
  .......> 2
T
```

 * If option `:u` is on, then the url of the project is printed.
 * If option `:g` is on, then only github-results are printed
   (also `:q` - quicklisp, `:c` - cliki, `:b` - bitbutcket. these options are additive).
 * If cut-off is supplied (above 4), then the number of output results is bellow cut-off
   (the number (above 2) after `.......>` is number of remains).
 * The order of options is nothing to do with search-result
   (e.g. `:dug 4` <=> `4 :gud` <=> `:du 4 :g` <=> ...).


##### Config:
```lisp
CL-REPL> (qs:? 'lisp-koans :du 1) ;<=> (qs:quicksearch 'lisp-koans
                                  ;                    :?description t :?url t :?cut-off 1)

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
  .......> 2
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
  .......> 2
T
```

 * `:maximum-columns-of-description` controls in printing description (default is 80).



Referece Manual
---------------

#### [function] QUICKSEARCH _search-word_ _&key_ _?web_ _?description_ _?url_ _?cut-off_ _?quicklisp_ _?cliki_ _?github_ _?bitbucket_

QUICKSEARCH searches for CL projects with _search-word_ in Quicklisp, Cliki, Github and BitBucket.
_search-word_ must be a string, number or symbol (symbol will be automatically converted into downcase-string).


##### Keywords:

 * If _?web_ is NIL, it does not search in Cliki, Github and BitBucket.
 * If _?quicklisp_ is NIL, it does not search in Quicklisp (also _?cliki_, _?github_, _?bitbucket_).
 * At least one search-space must be specified.
 * If _?description_ is T, it displays project's descriptions (except for Quicklisp-search).
 * If _?url_ is T, it display project's url.
 * _?cut-off_ is the max number of printing repositories each space.


##### Note:

 * _?cut-off_ controls only printing results,
   nothing to do with the max number of fetching repositories.
   c.f. function CONFIG documentation

 * About #\Space in _search-word_:
 
   In case _search-word_ contains #\Space, Quicklisp-search is OR-search,
   whereas Cliki-search, Github-, BitBucket- is AND-search.

   e.g. (quicksearch "foo bar")
     Quicklisp-search for "foo" OR "bar".
     Cliki-search, GitHub-, BitBucket- for "foo" AND "bar".


#### [function] ? _search-word_ _&rest_ _options_

? is abbreviation wrapper for function QUICKSEARCH.
_search-word_ must be a string, number or symbol.
_options_ must be a plus integer (as Cut-Off) or-and some keywords which consists of some Option-Chars.


##### Examples:

    (? "crypt")
    <=>
    (quicksearch "crypt" :?description nil :?url nil :?cut-off 50
                         :?quicklisp t :?cliki t :?github t :?bitbucket t)

    (? "crypt" :du 10)
    <=>
    (quicksearch "crypt" :?description T :?url T :?cut-off 10
                         :?quicklisp t :?cliki t :?github t :?bitbucket t)

    (? "crypt" 20 :g :d)
    <=>
    (quicksearch "crypt" :?description T :?url nil :?cut-off 20
                         :?quicklisp nil :?cliki nil :?github T :?bitbucket nil)


##### Options:

 * Cut-Off:
   * The max number of printing results.

 * Option-Chars:
   * d, D -- output Description
   * u, U -- output URL
   * q, Q -- search in Quicklisp
   * c, C -- search in Cliki
   * g, G -- search in Github
   * b, B -- search in Bitbucket


##### Note:

 * Option-Char is idempotent (e.g. :dd <=> :d).
 * The order of Option-Chars is nothing to do with output. (e.g. :du <=> :ud)
 * If _options_ contains more than 2 Cut-Offs, only last one is applied.
 * The order of _options_ is nothing to do with output (except for some Cut-Offs).
 * If no search space is specified, all spaces is specified (e.g. :d <=> :dqcgb)
 * If at most one search space is specified, then others are not specified.


#### [function] CONFIG _&key_ _maximum-columns-of-description_ _maximum-number-of-fetching-repositories_ _cache-size_ _clear-cache_ _threading-p_

Function CONFIG customizes quicksearch's internal parameters which control printing, fetching or caching.


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

 * _:clear-cache_
   The value must be a boolean.
   If value is T, then clear all caches.

 * _:threading-p_
   The value must be a boolean (default T).
   If value is NIL, then QUICKSEARCH becomes not to use threads for searching.

   Note:
     Currently in SBCL (1.1.8), threads are part of the default build on x86[-64] Linux only.
     Other platforms (x86[-64] Darwin (Mac OS X), x86[-64] FreeBSD, x86 SunOS (Solaris),
     and PPC Linux) experimentally supports threads and must be explicitly enabled at build-time.
     For more details, please see [SBCL manual](http://www.sbcl.org/manual/index.html#Threading).


##### Note:

If you would prefer permanent config, for example, add the following codes in the CL init file.

In `.sbclrc` for SBCL, `ccl-init.lisp` for CCL:

    (ql:quickload :quicksearch)
    (qs:config :maximum-columns-of-description 50
               :maximum-number-of-fetching-repositories 20
               :cache-size 2
               :threading-p nil)


TODO
----

- ADD search-space: Common-Lisp.net
- ADD search-space: Google code


Author, License, Copyright
--------------------------

- Takaya OCHIAI  <#.(reverse "moc.liamg@lper.hcykt")>

- MIT License

- Copyright (C) 2013 Takaya OCHIAI
