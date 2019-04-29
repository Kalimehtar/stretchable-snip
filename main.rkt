#lang racket/base
(require racket/contract/base racket/gui/base racket/class)

(define snip-mixin-contract (make-mixin-contract snip%))

(define stretchable<%> (interface ((class->interface snip%)) on-size))

(provide/contract
  [stretchable-editor-canvas-mixin (make-mixin-contract editor-canvas%)]
  [stretchable-editor-canvas% (subclass?/c editor-canvas%)]
  [stretchable<%> interface?]
  [hr% (and/c (subclass?/c snip%) (implementation?/c stretchable<%>))]
  [stretchable-snip-mixin snip-mixin-contract]
  [stretchable-snip-static-mixin
   (-> ((is-a?/c stretchable<%>) dimension-integer? dimension-integer? . -> . any)
       snip-mixin-contract)]
  [canvas-client-size
   ((is-a?/c editor-canvas%) . -> . (values dimension-integer? dimension-integer?))])

(define (canvas-client-size ed)
  (define-values (cl-w cl-h) (send ed get-client-size))
  (values (- cl-w (* 2 (send ed horizontal-inset)) 3)
          (- cl-h (* 2 (send ed vertical-inset)) 1)))

(define stretchable-editor-canvas-mixin
  (mixin ((class->interface editor-canvas%)) ()
    (inherit get-editor)
    (super-new)
    (define/override (on-size w h)                              
      (define-values (cl-w cl-h) (canvas-client-size this))
      (let loop ([sn (send (get-editor) find-first-snip)])
        (when sn          
          (when (is-a? sn stretchable<%>)
            (send sn on-size cl-w cl-h))
          (loop (send sn next))))
      (super on-size w h))))

(define stretchable-editor-canvas% (stretchable-editor-canvas-mixin editor-canvas%))

(define (draw-line w)
  (define _w (max w 1))
  (define line (make-bitmap _w 1))
  (define dc (new bitmap-dc% [bitmap line]))
  (send dc set-brush "gray" 'solid)
  (send dc draw-rectangle 0 0 _w 1)
  line)

(define hr%
  (class* image-snip% (stretchable<%>)
    (inherit set-bitmap)
    (super-make-object (make-object bitmap% 1 1))
    (define/override (set-admin adm)
      (when adm
        (define canvas (send (send adm get-editor) get-canvas))
        (when canvas
          (define-values (w h) (canvas-client-size canvas))
          (on-size w h)))
      (super set-admin adm))
    (define/public (on-size w h)
      (set-bitmap (draw-line w)))))

(define stretchable-snip-mixin
  (mixin ((class->interface snip%)) (stretchable<%>)
    (super-new)
    (init-field [(cb-on-size on-size) (λ (this w h) (void))])
    (define/override (set-admin adm)
      (when adm
        (define canvas (send (send adm get-editor) get-canvas))
        (when canvas
          (define-values (w h) (canvas-client-size canvas))
          (on-size w h)))
      (super set-admin adm))
    (define/public (on-size w h)
      (cb-on-size this w h))))

(define (stretchable-snip-static-mixin cb-on-size)
  (mixin ((class->interface snip%)) (stretchable<%>)
    (super-new)
    (define/override (set-admin adm)
      (when adm
        (define canvas (send (send adm get-editor) get-canvas))
        (when canvas
          (define-values (w h) (canvas-client-size canvas))
          (on-size w h)))
      (super set-admin adm))
    (define/public (on-size w h)
      (cb-on-size this w h))))


(module+ test
  (define (demo)
    (define hr2% ((stretchable-snip-static-mixin
                   (λ (this w __)
                     (send this set-bitmap (draw-line w))))
                  image-snip%))
    (define hr3% (stretchable-snip-mixin image-snip%))
    (define fr (new frame% [label "test"] [width 400] [height 400]))
    (define text (new text%))
    (define ed (new stretchable-editor-canvas% [parent fr] [editor text]))
    (send text insert "line 1\n")
    (send text insert (new hr%))
    (send text insert "\nline 2\n")
    (send text insert (new hr2%))
    (send text insert "\nline 3\n")
    (send text insert (new hr3% [on-size (λ (this w __)
                                           (send this set-bitmap (draw-line w)))]))
    (send text insert "\nline 4")
    (send fr show #t)))
