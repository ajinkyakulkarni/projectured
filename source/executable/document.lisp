;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) by the authors.
;;;
;;; See LICENCE for details.

(in-package :projectured)

;;;;;;
;;; Document

(def function make-file-document (filename)
  (bind ((content (if filename
                      (if (probe-file filename)
                          (call-loader filename)
                          (call-maker filename))
                      (funcall (find-maker 'pred)))))
    (document/document (:filename (or filename "document.pred")
                        :selection `((the ,(document-type content) (content-of (the document/document document)))
                                     ,@(selection-of content)))
      content)))

(def function make-default-document (document)
  (widget/shell (:size (make-2d 1280 720))
    (document/reflection (:selection `((the widget/scroll-pane (content-of (the document/reflection document)))
                                       (the document/clipboard (content-of (the widget/scroll-pane document)))
                                       (the ,(document-type document) (content-of (the document/clipboard document)))))
      (widget/scroll-pane (:position 0 :size (make-2d 1280 720) :margin (make-inset :all 5) :selection `((the document/clipboard (content-of (the widget/scroll-pane document)))
                                                                                                         (the ,(document-type document) (content-of (the document/clipboard document)))
                                                                                                         ,@(selection-of document)))
        (document/clipboard (:selection `((the ,(document-type document) (content-of (the document/clipboard document)))
                                          ,@(selection-of document)))
          document)))))

;;;;;;
;;; Example

(def function make-graphics-example ()
  (make-graphics/canvas (list (make-graphics/viewport (make-graphics/canvas (list (make-graphics/point (make-2d 50 150) :stroke-color *color/red*)
                                                                                  (make-graphics/line (make-2d 150 300) (make-2d 50 400) :stroke-color *color/blue*)
                                                                                  (make-graphics/rectangle (make-2d 200 200) (make-2d 100 100) :stroke-color *color/green*)
                                                                                  (make-graphics/rounded-rectangle (make-2d 120 180) (make-2d 50 50) 10 :fill-color *color/dark-yellow*)
                                                                                  (make-graphics/polygon (list (make-2d 150 100) (make-2d 160 160) (make-2d 100 150)) :stroke-color *color/black*)
                                                                                  (make-graphics/bezier (list (make-2d 100 100) (make-2d 200 120) (make-2d 180 200) (make-2d 300 200)) :stroke-color *color/black*)
                                                                                  (make-graphics/circle (make-2d 50 250) 50 :stroke-color *color/black* :fill-color *color/blue*)
                                                                                  (make-graphics/ellipse (make-2d 50 50) (make-2d 100 50) :stroke-color *color/red*)
                                                                                  (make-graphics/text (make-2d 200 150) "hello world" :font *font/default* :font-color *color/default* :fill-color *color/light-cyan*)
                                                                                  (make-graphics/image (make-2d 300 0) (make-image/file (resource-pathname "image/projectured.png"))))
                                                                            0)
                                                      (make-2d 50 50)
                                                      (make-2d 700 400))
                              (make-graphics/rectangle (make-2d 50 50)
                                                       (make-2d 700 400)
                                                       :stroke-color *color/red*))
                        0))

(def function save-graphics-example ()
  (call-saver (system-relative-pathname :projectured.executable "example/graphics.pred") (make-graphics-example)))

(def function make-mixed-example ()
  (book/book (:title "Example")
    (book/chapter (:title "Text")
      (book/paragraph (:alignment :justified)
        (call-loader (system-relative-pathname :projectured.executable "example/lorem-ipsum.txt"))))
    (book/chapter (:title "JSON")
      (call-loader (system-relative-pathname :projectured.executable "example/contact-list.json")))
    (book/chapter (:title "XML")
      (call-loader (system-relative-pathname :projectured.executable "example/hello-world.html")))))

(def function save-mixed-example ()
  (call-saver (system-relative-pathname :projectured.executable "example/mixed.pred") (make-mixed-example)))

(def function make-factorial-example ()
  (bind ((factorial-argument (make-common-lisp/required-function-argument (make-lisp-form/symbol* 'num)))
         (factorial-function (make-common-lisp/function-definition (make-lisp-form/symbol "FACTORIAL" "COMMON-LISP-USER")
                                                                   (list-ll factorial-argument)
                                                                   nil
                                                                   :allow-other-keys #f
                                                                   :documentation "The FACTORIAL function computes the product of all integers between 1 and NUM.")))
    (setf (body-of factorial-function)
          (list-ll (make-common-lisp/if (make-common-lisp/application (make-lisp-form/symbol* '<)
                                                                      (list-ll (make-common-lisp/variable-reference factorial-argument)
                                                                               (make-common-lisp/constant* 2)))
                                        (make-common-lisp/constant* 1)
                                        (make-common-lisp/application (make-lisp-form/symbol* '*)
                                                                      (list-ll (make-common-lisp/variable-reference factorial-argument)
                                                                               (make-common-lisp/application (make-common-lisp/function-reference factorial-function)
                                                                                                             (list-ll (make-common-lisp/application
                                                                                                                       (make-lisp-form/symbol* '-)
                                                                                                                       (list-ll (make-common-lisp/variable-reference factorial-argument)
                                                                                                                                (make-common-lisp/constant* 1))))))))))
    factorial-function))

(def function save-factorial-example ()
  (call-saver (system-relative-pathname :projectured.executable "example/factorial.pred") (make-factorial-example)))

(def function make-fibonacci-example (&optional suffix)
  (bind ((fibonacci-argument (make-common-lisp/required-function-argument (make-lisp-form/symbol* 'num)))
         (fibonacci-function (make-common-lisp/function-definition (make-lisp-form/symbol (string+ "FIBONACCI" suffix) "COMMON-LISP-USER")
                                                                   (list-ll fibonacci-argument)
                                                                   nil
                                                                   :allow-other-keys #f
                                                                   :documentation "The FIBONACCI function computes an element of the Fibonacci series at the index determined by NUM.")))
    (setf (body-of fibonacci-function)
          (list-ll (make-common-lisp/if (make-common-lisp/application (make-lisp-form/symbol* '<)
                                                                      (list-ll (make-common-lisp/variable-reference fibonacci-argument)
                                                                               (make-common-lisp/constant* 2)))
                                        (make-common-lisp/variable-reference fibonacci-argument)
                                        (make-common-lisp/application (make-lisp-form/symbol* '+)
                                                                      (list-ll (make-common-lisp/application (make-common-lisp/function-reference fibonacci-function)
                                                                                                             (list-ll (make-common-lisp/application
                                                                                                                       (make-lisp-form/symbol* '-)
                                                                                                                       (list-ll (make-common-lisp/variable-reference fibonacci-argument)
                                                                                                                                (make-common-lisp/constant* 1)))))
                                                                               (make-common-lisp/application (make-common-lisp/function-reference fibonacci-function)
                                                                                                             (list-ll (make-common-lisp/application
                                                                                                                       (make-lisp-form/symbol* '-)
                                                                                                                       (list-ll (make-common-lisp/variable-reference fibonacci-argument)
                                                                                                                                (make-common-lisp/constant* 2))))))))))
    fibonacci-function))

(def function save-fibonacci-example ()
  (call-saver (system-relative-pathname :projectured.executable "example/fibonacci.pred") (make-fibonacci-example)))

(def function make-evaluator-example ()
  (bind ((factorial-function (make-factorial-example)))
    (evaluator/toplevel ()
      (evaluator/form ()
        factorial-function)
      (evaluator/form ()
        (make-common-lisp/application (make-common-lisp/function-reference factorial-function)
                                      (list-ll (make-common-lisp/constant* 12)))))))

(def function save-evaluator-example ()
  (call-saver (system-relative-pathname :projectured.executable "example/evaluator.pred") (make-evaluator-example)))

(def function make-scaling-example (&optional (function-count 100))
  (bind ((fibonacci-functions-map (make-hash-table))
         (fibonacci-functions (iter (for i :from 0 :below function-count)
                                    (for fibonacci-function = (make-fibonacci-example (format nil "~4,'0,d" i)))
                                    (setf (gethash i fibonacci-functions-map) fibonacci-function)
                                    (collect fibonacci-function))))
    (iter (for fibonacci-function :in fibonacci-functions)
          (setf (function-of (operator-of (elt (arguments-of (else-of (elt (body-of fibonacci-function) 0))) 0)))
                (gethash (random function-count) fibonacci-functions-map))
          (setf (function-of (operator-of (elt (arguments-of (else-of (elt (body-of fibonacci-function) 0))) 1)))
                (gethash (random function-count) fibonacci-functions-map)))
    (make-common-lisp/toplevel (ll fibonacci-functions))))

(def function save-scaling-example ()
  (call-saver (system-relative-pathname :projectured.executable "example/scaling.pred") (make-scaling-example)))

(def function make-user-guide-example ()
  (book/book (:title "User Guide")
    (book/chapter (:title "Introduction")
      (book/paragraph ()
        (text/text ()
          (text/string "Welcome to ProjecturEd, a generic purpose projectional editor." :font *font/liberation/serif/regular/24* :font-color *color/solarized/content/darker*))))))

(def function save-user-guide-example ()
  (call-saver (system-relative-pathname :projectured.executable "example/user-guide.pred") (make-user-guide-example)))
