;;;; trivial-scgi.lisp by Randall Randall, Dec 20, 2004.
;;;; 
;;;; This file is in the public domain.
;;;; This is trivial-scgi-0.2a   
;;;; Releases of trivial-scgi will track trivial-sockets releases on
;;;;  which they depend.  Any improvement to this package will be 
;;;;  released with a letter upgrade (e.g. 0.2g), but no numerical upgrade
;;;;  until trivial-sockets by Daniel Barlow moves to a new version.
;;;; 
;;;; This package depends on trvial-sockets, which you can find through
;;;;  this link: http://www.cliki.net/trivial-sockets  (if not, please let
;;;;  me know so I can update this).
;;;; 
;;;; SCGI is a fast, simple replacement for traditional CGI, in the mode of 
;;;;  FastCGI, but easier to implement.  There exists a mod_scgi for Apache 1 and 2,
;;;;  and a CGI translator for those sites unable to access Apache directly.  More
;;;;  information can be found here: http://www.mems-exchange.org/software/scgi/ .
;;;; 
;;;; This file contains no code, explicitly or by inclusion, from the SCGI codebase,
;;;;  and was produced by reference to http://python.ca/nas/scgi/protocol.txt .
;;;; 
;;;; To use, read the docstring for WITH-SCGI-SERVER, and documentation for your
;;;;  copy of SCGI.  An example is provided that works with the examples in the
;;;;  SCGI package noted above.
;;;; 
;;;; No threading or other multi-processing support is included in this.  Such things
;;;;  are currently beyond the scope of trivial-sockets, and therefore this package.
;;;; 
;;;; Changes:
;;;;  0.2a initial release
;;;; 

(defpackage :trivial-scgi 
  (:nicknames :scgi)
  (:use :cl :trivial-sockets)
  (:export #:with-scgi-server))

(in-package :trivial-scgi)

;; These are here because any given CL may not match ASCII with char codes

(defconstant ascii ; this is all the ASCII I expect to see in headers.  
  '((9  . #\Tab)   (10 . #\Linefeed) (13 . #\Return)
    (32 . #\Space) (33 . #\!) (34 . #\") (35 . #\#) (36 . #\$) 
    (37 . #\%) (38 . #\&) (39 . #\') (40 . #\() (41 . #\))
    (42 . #\*) (43 . #\+) (44 . #\,) (45 . #\-) (46 . #\.) 
    (47 . #\/) (48 . #\0) (49 . #\1) (50 . #\2) (51 . #\3)
    (52 . #\4) (53 . #\5) (54 . #\6) (55 . #\7) (56 . #\8)
    (57 . #\9) (58 . #\:) (59 . #\;) (60 . #\<) (61 . #\=)
    (62 . #\>) (63 . #\?) (64 . #\@) (65 . #\A) (66 . #\B)
    (67 . #\C) (68 . #\D) (69 . #\E) (70 . #\F) (71 . #\G)
    (72 . #\H) (73 . #\I) (74 . #\J) (75 . #\K) (76 . #\L)
    (77 . #\M) (78 . #\N) (79 . #\O) (80 . #\P) (81 . #\Q)
    (82 . #\R) (83 . #\S) (84 . #\T) (85 . #\U) (86 . #\V)
    (87 . #\W) (88 . #\X) (89 . #\Y) (90 . #\Z) (91 . #\[)
    (92 . #\\) (93 . #\]) (94 . #\^) (95 . #\_) (96 . #\`)
    (97 . #\a) (98 . #\b) (99 . #\c) (100 . #\d) (101 . #\e)
    (102 . #\f) (103 . #\g) (104 . #\h) (105 . #\i) (106 . #\j)
    (107 . #\k) (108 . #\l) (109 . #\m) (110 . #\n) (111 . #\o)
    (112 . #\p) (113 . #\q) (114 . #\r) (115 . #\s) (116 . #\t)
    (117 . #\u) (118 . #\v) (119 . #\w) (120 . #\x) (121 . #\y)
    (122 . #\z) (123 . #\{) (124 . #\|) (125 . #\}) (126 . #\~)))

(defconstant ascii-colon 58) ; shortcuts for brevity
(defconstant ascii-nul   0)  ; because SCGI uses these as markers
;; also comma, but we don't care about that.

(defmacro with-scgi-server ((headers-var content-var 
                                         &key (port 4000) (queue-size 500))
                            &body body)
  "Takes a symbol for headers hash table variable name, and for the content variable
name, and two integer keyword args: PORT defaults to 4000, since that's what the SCGI
documentation uses as an example, and QUEUE-SIZE defaults to 500, for no particular
reason."
  (let ((server      (gensym "SERV"))
        (stream      (gensym "STREAM"))
        (content-len (gensym "CONTENT-LEN")))
    `(with-server (,server (:port ,port :backlog ,queue-size))
      (loop
       (let ((,stream (accept-connection ,server :element-type '(unsigned-byte 8))))
         (write-sequence 
          (let* ((,headers-var (read-headers ,stream))
                 (,content-len (parse-integer (gethash "CONTENT_LENGTH" ,headers-var)))
                 (,content-var (read-content ,stream ,content-len)))
            ,@body)
          ,stream)
         (force-output ,stream)
         (close ,stream))))))

(defun read-headers (stream)
  "Takes the SCGI stream with nothing already read, and returns a hash table of 
ASCII keys and values."
  (let* ((length (parse-integer (map 'string #'code-ascii 
                                     (read-until ascii-colon stream))))
         (header-vector (make-array length))
         (headers       (make-hash-table :test #'EQUAL)))
    (read-sequence header-vector stream)
    (read-byte stream) ; throw away the comma
    (let ((index 0))
      (do () ((= (length header-vector) index) headers)
        (let* ((pos (position ascii-nul header-vector :start index))
               (key (subseq header-vector index pos)))
          (setf index (1+ pos))
          (let ((pos (position ascii-nul header-vector :start index)))
            (setf (gethash (map 'string #'code-ascii key) headers)
                  (map 'string #'code-ascii (subseq header-vector index pos)))
            (setf index (1+ pos))))))))
  
(defun read-content (stream length)
  "Takes a stream and a length to read from it, and returns a non-adjustable vector
containing the data so read."
  (when (plusp length)
    (let ((content-vector (make-array length)))
      (read-sequence content-vector stream) 
      content-vector)))

(defun ascii-code (character)
  "Analogous to CHAR-CODE, but only for ASCII which might be found in an SCGI header."
  (car (rassoc character ascii)))

(defun code-ascii (integer)
  "Analogous to CODE-CHAR, but only for ASCII which might be found in an SCGI header."
  (cdr (assoc integer ascii)))

(defun read-until (until stream)
  "Takes a stop byte and a stream, and reads the stream collecting the output until
it finds the stop byte."
  (do ((out       (make-array 0 :adjustable T :fill-pointer T))
       (this-byte (read-byte stream) (read-byte stream)))
      ((eql this-byte until) out)
    (vector-push-extend this-byte out)))


(defun example ()
  "Example of use."
  (with-scgi-server (headers content) ; :port will be 4000, :queue-size 500.
    (let ((out (concatenate 'vector 
                            (map 'vector #'ascii-code "Content-Type: text/plain")
                            #(10 13 10 13))))
      (maphash (lambda (k v) 
                 (setf out 
                       (concatenate 'vector 
                                    out 
                                    (map 'vector #'ascii-code k)
                                    (map 'vector #'ascii-code ": ")
                                    (map 'vector #'ascii-code v)
                                    #(10))))
               headers)
      (concatenate 'vector out 
                   #(10 10) 
                   (map 'vector #'ascii-code "Content: ") 
                   #(10) 
                   content))))




