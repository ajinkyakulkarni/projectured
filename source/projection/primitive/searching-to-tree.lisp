;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) by the authors.
;;;
;;; See LICENCE for details.

(in-package :projectured)

;;;;;;
;;; Projection

(def projection searching/search->graphics/canvas ()
  ())

(def projection searching/result->tree/node ()
  ())

(def projection searching/result-element->tree/node ()
  ())

;;;;;;
;;; Construction

(def function make-projection/searching/search->graphics/canvas ()
  (make-projection 'searching/search->graphics/canvas))

(def function make-projection/searching/result->tree/node ()
  (make-projection 'searching/result->tree/node))

(def function make-projection/searching/result-element->tree/node ()
  (make-projection 'searching/result-element->tree/node))

;;;;;;
;;; Construction

(def macro searching/search->graphics/canvas ()
  `(make-projection/searching/search->graphics/canvas))

(def macro searching/result->tree/node ()
  `(make-projection/searching/result->tree/node))

(def macro searching/result-element->tree/node ()
  `(make-projection/searching/result-element->tree/node))

;;;;;;
;;; Forward mapper

(def forward-mapper searching/search->graphics/canvas ()
  (pattern-case -reference-
    (((the string (search-of (the searching/search document)))
      (the string (subseq (the string document) ?start-index ?end-index)))
     `((the text/text (content-of (the widget/text document)))
       (the text/text (text/subseq (the text/text document) ,?start-index ,?end-index))))
    (((the graphics/canvas (printer-output (the searching/search document) ?projection ?recursion)) . ?rest)
     (when (eq -projection- ?projection)
       ?rest))))

(def forward-mapper searching/result->tree/node ()
  (pattern-case -reference-
    (((the sequence (elements-of (the searching/result document)))
      (the ?type (elt (the sequence document) ?index))
      . ?rest)
     (bind ((element-iomap (elt (child-iomaps-of -printer-iomap-) ?index)))
       (values `((the sequence (children-of (the tree/node document)))
                 (the tree/node (elt (the sequence document) ,?index))
                 (the sequence (children-of (the tree/node document)))
                 (the ,(document-type (output-of element-iomap)) (elt (the sequence document) 0)))
               ?rest
               element-iomap)))
    (((the tree/node (printer-output (the searching/result document) ?projection ?recursion)) . ?rest)
     (when (eq -projection- ?projection)
       ?rest))))

(def forward-mapper searching/result-element->tree/node ()
  (pattern-case -reference-
    (((the ?type (document-of (the searching/result-element document)))
      . ?rest)
     (bind ((content-iomap (content-iomap-of -printer-iomap-)))
       (values `((the sequence (children-of (the tree/node document)))
                 (the ,(document-type (output-of content-iomap)) (elt (the sequence document) 1)))
               (nthcdr (length (path-of -printer-input-)) ?rest)
               content-iomap)))
    (((the tree/node (printer-output (the searching/result-element document) ?projection ?recursion)) . ?rest)
     (when (eq -projection- ?projection)
       ?rest))))

;;;;;;
;;; Backward mapper

(def backward-mapper searching/search->graphics/canvas ()
  (pattern-case -reference-
    (?a
     (append `((the graphics/canvas (printer-output (the searching/search document) ,-projection- ,-recursion-))) -reference-))))

(def backward-mapper searching/result->tree/node ()
  (pattern-case -reference-
    (((the sequence (children-of (the tree/node document)))
      (the ?type (elt (the sequence document) ?index))
      . ?rest)
     (bind ((element-iomap (elt (child-iomaps-of -printer-iomap-) ?index)))
       (values `((the sequence (elements-of (the searching/result document)))
                 (the ,(document-type (input-of element-iomap)) (elt (the sequence document) ,?index)))
               ?rest
               element-iomap)))
    (?a
     (append `((the tree/node (printer-output (the searching/result document) ,-projection- ,-recursion-))) -reference-))))

(def backward-mapper searching/result-element->tree/node ()
  (pattern-case -reference-
    (((the sequence (children-of (the tree/node document)))
      (the ?type (elt (the sequence document) 1))
      . ?rest)
     (bind ((content-iomap (content-iomap-of -printer-iomap-)))
       (values `((the ,(document-type (document-of -printer-input-)) (document-of (the searching/result-element document)))
                 ,@(path-of -printer-input-))
               ?rest
               content-iomap)))
    (?a
     (append `((the tree/node (printer-output (the searching/result-element document) ,-projection- ,-recursion-))) -reference-))))

;;;;;;
;;; Printer

(def printer searching/search->graphics/canvas ()
  (bind ((output-selection (as (print-selection (make-iomap/compound -projection- -recursion- -input- -input-reference- nil nil #+nil(as (list (va document-iomap) (va search-iomap) (va result-iomap))))
                                                (selection-of -input-)
                                                'forward-mapper/searching/search->graphics/canvas)))
         (document-iomap (as (recurse-printer -recursion- (document-of -input-)
                                              `((document-of (the searching/search document))
                                                ,@(typed-reference (document-type -input-) -input-reference-)))))
         (search-iomap (as (awhen (search-of -input-)
                             (bind ((empty? (zerop (length it)))
                                    (widget (widget/text (:position (make-2d 970 0) :margin (make-inset :all 5)
                                                          :margin-color (color/lighten *color/solarized/yellow* 0.75)
                                                          :content-fill-color (color/lighten *color/solarized/yellow* 0.75)
                                                          :selection output-selection)
                                              (text/text (:selection (as (nthcdr 1 (va output-selection))))
                                                #+nil(text/string "Search: " :font *font/ubuntu/regular/24* :font-color *color/solarized/gray*)
                                                (text/string (if empty?
                                                                 "enter search string"
                                                                 it)
                                                             :font *font/ubuntu/regular/24*
                                                             :font-color (if empty? (color/lighten *color/solarized/red* 0.75) *color/solarized/red*))))))
                               (recurse-printer -recursion- widget
                                                `((search-of (the searching/search document))
                                                  ,@(typed-reference (document-type -input-) -input-reference-)))))))
         (result-iomap (as (awhen (result-of -input-)
                             (recurse-printer -recursion- it
                                              `((result-of (the searching/search document))
                                                ,@(typed-reference (document-type -input-) -input-reference-))))))
         (output (make-graphics/canvas (as (append (aif (va result-iomap)
                                                        (list (output-of it))
                                                        (list (output-of (va document-iomap))))
                                                   (when (or (va result-iomap)
                                                             (and (pattern-case (selection-of -input-)
                                                                    (((the string (search-of (the searching/search document)))
                                                                      (the string (subseq (the string document) 0 0)))
                                                                     #t))
                                                                  (va search-iomap)))
                                                     (list (output-of (va search-iomap))))))
                                       (make-2d 0 0))))
    (make-iomap/compound -projection- -recursion- -input- -input-reference- output (as (list (va document-iomap) (va search-iomap) (va result-iomap))))))

(def printer searching/result->tree/node ()
  (bind ((element-iomaps (as (map-ll* (ll (elements-of -input-))
                                      (lambda (element index)
                                        (recurse-printer -recursion- (value-of element)
                                                         `((elt (the sequence document) ,index)
                                                           (the sequence (elements-of (the searching/result document)))
                                                           ,@(typed-reference (document-type -input-) -input-reference-)))))))
         (output-selection (as (print-selection (make-iomap/compound -projection- -recursion- -input- -input-reference- nil element-iomaps)
                                                (selection-of -input-)
                                                'forward-mapper/searching/result->tree/node)))
         (output (as (make-tree/node (map-ll* (va element-iomaps)
                                              (lambda (element index)
                                                (bind ((element-iomap (value-of element)))
                                                  (tree/node (:indentation 0 :selection (as (nthcdr 2 (va output-selection))))
                                                    (tree/leaf (:selection (as (nthcdr 4 (va output-selection))))
                                                      (text/text (:selection (as (nthcdr 5 (va output-selection))))
                                                        (text/string (format nil "~Ath match" index) :font *font/liberation/serif/regular/24* :font-color *color/solarized/content/dark* :line-color *color/solarized/background/lighter*)))
                                                    (tree/clone (output-of element-iomap) :indentation 0 :selection (as (nthcdr 2 (va output-selection))))))))
                                     :separator (text/text () (text/string " " :font *font/ubuntu/monospace/regular/24* :font-color *color/solarized/gray*))
                                     :selection output-selection))))
    (make-iomap/compound -projection- -recursion- -input- -input-reference- output element-iomaps)))

(def printer searching/result-element->tree/node ()
  (bind ((content-iomap (recurse-printer -recursion- (eval-reference (document-of -input-) (flatten-reference (path-of -input-)))
                                         `((document-of (the searching/result-element document))
                                           ,@(typed-reference (document-type -input-) -input-reference-))))
         (output-selection (as (print-selection (make-iomap/content -projection- -recursion- -input- -input-reference- nil content-iomap)
                                                (selection-of -input-)
                                                'forward-mapper/searching/result-element->tree/node)))
         (output (as (tree/node (:selection output-selection)
                       (tree/leaf (:selection (as (nthcdr 2 (va output-selection))))
                         (text/make-text (elements-of (printer-output (document/reference ()
                                                                        (path-of -input-))
                                                                      (document/reference->text/text)))
                                         :selection (as (nthcdr 3 (va output-selection)))))
                       (tree/clone (output-of content-iomap) :indentation 0 :selection (as (nthcdr 2 (va output-selection))))))))
    (make-iomap/content -projection- -recursion- -input- -input-reference- output content-iomap)))

;;;;;;
;;; Reader

(def reader searching/search->graphics/canvas ()
  (bind ((document (document-of -printer-input-))
         (search (search-of -printer-input-))
         (result (result-of -printer-input-)))
    (merge-commands (gesture-case (gesture-of -input-)
                      ((make-key-press-gesture :scancode-s :control)
                       :domain "Search" :description "Starts editing search string"
                       :operation (cond ((not search)
                                         (make-operation/compound (list (make-operation/functional (lambda () (setf (search-of -printer-input-) "")))
                                                                        (make-operation/replace-selection -printer-input-
                                                                                                          `((the string (search-of (the searching/search document)))
                                                                                                            (the string (subseq (the string document) 0 0)))))))
                                        ((pattern-case (selection-of -printer-input-)
                                           (((the string (search-of (the searching/search document)))
                                             . ?rest)
                                            #f)
                                           (?a
                                            #t))
                                         (make-operation/replace-selection -printer-input-
                                                                           `((the string (search-of (the searching/search document)))
                                                                             (the string (subseq (the string document) 0 0)))))))
                      ((make-key-press-gesture :scancode-s :control)
                       :domain "Search" :description "Replaces document with search result"
                       :operation (when (and search (not (zerop (length search))))
                                    (pattern-case (selection-of -printer-input-)
                                      (((the string (search-of (the searching/search document)))
                                        . ?rest)
                                       (bind ((search-result (make-searching/result (mapcar (lambda (reference)
                                                                                              (searching/result-element (reference)
                                                                                                document))
                                                                                            (default-searcher (search-of -printer-input-) document)))))
                                         (make-operation/compound (list (make-operation/functional (lambda () (setf (result-of -printer-input-) search-result)))
                                                                        (make-operation/replace-selection -printer-input- `((the ,(document-type document) (document-of (the searching/search document))))))))))))
                      ((make-key-press-gesture :scancode-s '(:shift :control))
                       :domain "Search" :description "Reverts search result to the original document"
                       :operation (when (result-of -printer-input-)
                                    (make-operation/compound (list (make-operation/functional (lambda () (setf (result-of -printer-input-) nil)))
                                                                   (make-operation/replace-selection -printer-input- `((the ,(document-type result) (result-of (the searching/search document))))))))))
                    (bind ((result-iomap (elt (child-iomaps-of -printer-iomap-) 0))
                           (result-command (recurse-reader -recursion- -input- result-iomap)))
                      (make-command (gesture-of -input-)
                                    (operation/extend -printer-input- `((the ,(document-type result) (result-of (the searching/search document)))) (operation-of result-command))
                                    :domain (domain-of result-command)
                                    :description (description-of result-command)))
                    #+nil
                    (bind ((document-iomap (elt (child-iomaps-of printer-iomap) 0))
                           (document-command (recurse-reader recursion input document-iomap)))
                      (make-command (gesture-of input)
                                    (operation/extend printer-input `((the ,(document-type document) (document-of (the searching/search document)))) (operation-of document-command))
                                    :domain (domain-of document-command)
                                    :description (description-of document-command)))
                    #+nil(command/read-selection recursion input printer-iomap 'forward-mapper/searching/search->graphics/canvas 'backward-mapper/searching/search->graphics/canvas)
                    #+nil(command/read-backward recursion input printer-iomap 'backward-mapper/searching/search->graphics/canvas nil)
                    (make-nothing-command (gesture-of -input-)))))

(def reader searching/result->tree/node ()
  (merge-commands (command/read-selection -recursion- -input- -printer-iomap- 'forward-mapper/searching/result->tree/node 'backward-mapper/searching/result->tree/node)
                  (command/read-backward -recursion- -input- -printer-iomap- 'backward-mapper/searching/result->tree/node nil)
                  (make-nothing-command (gesture-of -input-))))

(def reader searching/result-element->tree/node ()
  (merge-commands (command/read-selection -recursion- -input- -printer-iomap- 'forward-mapper/searching/result-element->tree/node 'backward-mapper/searching/result-element->tree/node)
                  (command/read-backward -recursion- -input- -printer-iomap- 'backward-mapper/searching/result-element->tree/node nil)
                  (make-nothing-command (gesture-of -input-))))
