;;; -*- mode: Lisp; Syntax: Common-Lisp; -*-
;;;
;;; Copyright (c) 2009 by the authors.
;;;
;;; See LICENCE for details.

(in-package :projectured)

;;;;;;
;;; IO map

(def iomap iomap/text->graphics (iomap)
  ((graphics-element-indices :type sequence)
   (first-character-indicies :type sequence)
   (last-character-indicies :type sequence)))

;;;;;;
;;; Projection

(def projection text->graphics ()
  ())

;;;;;;
;;; Construction

(def (function e) make-projection/text->graphics ()
  (make-projection 'text->graphics))

;;;;;;
;;; Construction

(def (macro e) text->graphics ()
  `(make-projection/text->graphics))

;;;;;;
;;; Printer

(def printer text->graphics (projection recursion input input-reference)
  (declare (ignore input-reference))
  (bind ((graphics-element-indices nil)
         (first-character-indicies nil)
         (last-character-indicies nil)
         (line-heights (iter outer
                             (text/map-split input #\NewLine
                                             (lambda (start-element-index start-character-index end-element-index end-character-index)
                                               (declare (ignore start-character-index end-character-index))
                                               (in outer (collect (iter (for index :from start-element-index :below end-element-index)
                                                                        (for element = (elt (elements-of input) index))
                                                                        (etypecase element
                                                                          (text/spacing)
                                                                          (text/character
                                                                           (maximize (2d-y (measure-text " " (font-of element)))))
                                                                          (text/string
                                                                           (maximize (2d-y (measure-text " " (font-of element)))))
                                                                          (image/image
                                                                           (bind ((image (make-graphics/image (make-2d 0 0) element))
                                                                                  (size (size-of (make-bounding-rectangle image))))
                                                                             (maximize (2d-y size))))))))))
                             (until #t)))
         (elements (iter outer
                         (with y = 0)
                         (with x = 0)
                         (with line-index = 0)
                         (with output-index = 0)
                         (with content-index = 0)
                         (for input-index :from 0)
                         (for element :in-sequence (elements-of input))
                         (etypecase element
                           (text/spacing
                            (incf x (ecase (unit-of element)
                                      (:pixel (size-of element))
                                      (:space (* (size-of element)
                                                 (2d-x (measure-text " " (font-of element))))))))
                           (text/character
                            (not-yet-implemented))
                           (text/string
                            (bind ((content (content-of element)))
                              (iter (for line :in (split-sequence #\NewLine content))
                                    (unless (first-iteration-p)
                                      (setf x 0)
                                      (incf y (elt line-heights line-index))
                                      (incf line-index))
                                    (unless (zerop (length line))
                                      (for line-height = (elt line-heights line-index))
                                      (for size = (measure-text line (font-of element)))
                                      (for text = (make-graphics/text (make-2d x (+ y (- line-height (2d-y size)))) line
                                                                      :font (font-of element)
                                                                      :font-color (font-color-of element)
                                                                      :fill-color (fill-color-of element)))
                                      (awhen (line-color-of element)
                                        (incf output-index)
                                        (in outer (collect (make-graphics/rectangle (make-2d x y) (make-2d (2d-x size) line-height) :fill-color it))))
                                      (in outer (collect text))
                                      (incf x (2d-x size))
                                      (push output-index graphics-element-indices)
                                      (incf output-index)
                                      (push content-index first-character-indicies)
                                      (incf content-index (length line))
                                      (push content-index last-character-indicies))
                                    (unless (first-iteration-p)
                                      (incf content-index)))))
                           ;; TODO: recurse and use the resulting graphics
                           (image/image
                            (bind ((image (make-graphics/image (make-2d x y) element))
                                   (size (size-of (make-bounding-rectangle image))))
                              (in outer (collect image))
                              (incf output-index)
                              (incf x (2d-x size)))))))
         ((:values preceding-selection-elements following-selection-elements)
          (labels ((graphics-character-index (text-character-index)
                     (iter (for index :from 0)
                           (for first-character-index :in (reverse first-character-indicies))
                           (for last-character-index :in (reverse last-character-indicies))
                           (when (<= first-character-index text-character-index last-character-index)
                             (return (values (elt (reverse graphics-element-indices) index) (- text-character-index first-character-index)))))))
            (pattern-case (selection-of input)
              (((the character (text/elt (the text/text document) ?text-character-index)))
               (bind (((:values graphics-element-index graphics-character-index) (graphics-character-index ?text-character-index))
                      (text-graphics (elt elements graphics-element-index))
                      (offset-text (subseq (text-of text-graphics) 0 graphics-character-index))
                      (text (subseq (text-of text-graphics) graphics-character-index (1+ graphics-character-index)))
                      (location (location-of text-graphics))
                      (font (font-of text-graphics))
                      (offset (2d-x (measure-text offset-text font))))
                 (values nil (list (make-graphics/rectangle (+ location (make-2d offset 0)) (measure-text text font)
                                                            :fill-color *color/solarized/background/light*)))))
              (((the sequence-position (text/pos (the text/text document) ?text-character-index)))
               (bind (((:values graphics-element-index graphics-character-index) (graphics-character-index ?text-character-index))
                      (text-graphics (elt elements graphics-element-index))
                      (text (subseq (text-of text-graphics) 0 graphics-character-index))
                      (location (location-of text-graphics))
                      (font (font-of text-graphics))
                      (offset (2d-x (measure-text text font)))
                      (height (2d-y (measure-text "" font))))
                 (values nil (list (make-graphics/line (+ location (make-2d offset 0))
                                                       (+ location (make-2d offset height))
                                                       :stroke-color *color/black*)
                                   (make-graphics/line (+ location (make-2d (- offset 2) 0))
                                                       (+ location (make-2d (+ offset 2) 0))
                                                       :stroke-color *color/black*)
                                   (make-graphics/line (+ location (make-2d (- offset 2) height))
                                                       (+ location (make-2d (+ offset 2) height))
                                                       :stroke-color *color/black*)))))
              (((the sequence-box (text/subbox (the text/text document) ?b ?c)))
               (iter (with top = nil)
                     (with left = nil)
                     #+nil(with right = nil)
                     (for character-index :from ?b :to ?c)
                     (for (values graphics-element-index graphics-character-index) = (graphics-character-index character-index))
                     (when graphics-character-index
                       (for graphics-element = (elt elements graphics-element-index))
                       (typecase graphics-element
                         (graphics/text
                          (bind ((text (subseq (text-of graphics-element) 0 graphics-character-index))
                                 (location (location-of graphics-element))
                                 (font (font-of graphics-element))
                                 (offset (2d-x (measure-text text font)))
                                 (height (2d-y (measure-text "" font))))
                            (unless left
                              (setf left (+ (2d-x location) offset)))
                            ;; TODO: support rectangular
                            #+nil(setf right (+ (2d-x location) offset))
                            ;; TODO: to support tree
                            (maximizing (+ (2d-x location) offset) :into right)
                            (unless top
                              (setf top (2d-y location)))
                            (maximizing (+ (2d-y location) height) :into bottom)))))
                     (finally
                      (return (values (list (make-graphics/rectangle (make-2d left top)
                                                                     (make-2d (- right left) (- bottom top))
                                                                     :fill-color *color/solarized/background/light*))
                                      (list (make-graphics/rectangle (make-2d (- left 1) (- top 1))
                                                                     (make-2d (- right left -2) (- bottom top -2))
                                                                     :stroke-color *color/black*))))))))))
         (output (make-graphics/canvas (append preceding-selection-elements elements following-selection-elements)
                                       (make-2d 0 0))))
    (make-iomap 'iomap/text->graphics
                :projection projection :recursion recursion
                :input input :output output
                :graphics-element-indices (nreverse graphics-element-indices)
                :first-character-indicies (nreverse first-character-indicies)
                :last-character-indicies (nreverse last-character-indicies))))

;;;;;;
;;; Reader

(def function text->graphics/read-backward (command printer-iomap)
  (bind ((operation (operation-of command)))
    (awhen (typecase operation
             (operation/replace-selection
              (pattern-case (selection-of operation)
                (((the character (elt (the string document) ?graphics-character-index))
                  (the string (text-of (the graphics/text document)))
                  (the graphics/text (elt (the sequence document) ?graphics-element-index))
                  (the sequence (elements-of (the graphics/canvas document))))
                 (bind ((text-character-index (+ ?graphics-character-index (elt (first-character-indicies-of printer-iomap) (position ?graphics-element-index (graphics-element-indices-of printer-iomap))))))
                   (make-operation/replace-selection (input-of printer-iomap) `((the sequence-position (text/pos (the text/text document) ,text-character-index))))))))
             (operation/describe
              (pattern-case (target-of operation)
                (((the character (elt (the string document) ?graphics-character-index))
                  (the string (text-of (the graphics/text document)))
                  (the graphics/text (elt (the sequence document) ?graphics-element-index))
                  (the sequence (elements-of (the graphics/canvas document))))
                 (bind ((text-character-index (+ ?graphics-character-index (elt (first-character-indicies-of printer-iomap) (position ?graphics-element-index (graphics-element-indices-of printer-iomap))))))
                   (make-instance 'operation/describe :target `((the character (text/elt (the text/text document) ,text-character-index))))))))
             (operation/show-context-sensitive-help
              operation))
      (make-command (gesture-of command) it
                    :domain (domain-of command)
                    :description (description-of command)))))

(def reader text->graphics (projection recursion input printer-iomap)
  (declare (ignore projection recursion))
  (bind ((printer-input (input-of printer-iomap))
         (text-command (text/read-operation printer-input (gesture-of input)))
         (document-command (document/read-operation printer-input (gesture-of input)))
         (graphics-command (awhen (graphics/read-operation (output-of printer-iomap) (gesture-of input))
                             (text->graphics/read-backward it printer-iomap))))
    (merge-commands text-command document-command graphics-command input)))