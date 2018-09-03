#lang scribble/manual
@require[@for-label[stretchable-snip
                    racket/base racket/class racket/gui/base]]

@title{stretchable-snip}
@author+email["Roman Klochkov" "kalimehtar@mail.ru"]

@defmodule[stretchable-snip]

This package provides mixins to make stretchable snips. Stretchable snups have @racket[on-size] method, that will
be called, when the size of the canvas is changed. It can be used to implement snips, whose view depends on the size of
the editor-canvas, such as horizontal rule.

All stretchable snips should implement @racket[stretchable<%>] and be placed inside stretchable @racket[editor-canvas%] (either
@racket[stretchable-editor-canvas%], or result of @racket[stretchable-editor-canvas-mixin]). To implement @racket[stretchable<%>]
one may use @racket[stretchable-snip-mixin] or @racket[stretchable-snip-static-mixin]. If you build @racket[stretchable<%>], remember,
that @racket[on-size] is called only when editor's @racket[on-size] is called. If your snip may be added to already shown editor, you
should also override @racket[set-admin].  See @racket[hr%] source for example:

@(racketblock
  (define hr%
    (class* image-snip% (stretchable<%>)
      (inherit set-bitmap)
      (super-make-object (make-object bitmap% 1 1))
      (define/override (set-admin adm)
        (when adm        
          (define-values (w h) (canvas-client-size (send (send adm get-editor) get-canvas)))
          (on-size w h))
        (super set-admin adm))
      (define/public (on-size w h)
        (set-bitmap (draw-line w))))))

@racket[canvas-client-size] returns correct size of availaible space inside the canvas.

@defmixin[stretchable-editor-canvas-mixin (editor-canvas%) ()]{Returns stretchable version of its argument.}

@defclass[stretchable-editor-canvas% editor-canvas% ()]{
A @racket[stretchable-editor-canvas%] is @racket[(stretchable-editor-canvas-mixin editor-canvas%)]}

@definterface[stretchable<%> ()]{The @racket[stretchable<%>] should be implemented by all snips, whose @racket[on-size]
method shoul be called, when editor's size changes.}

@defclass[hr% image-snip% (stretchable<%>)]{This is a snip, that display horizontal rule like <HR> tag in HTML.}

@defmixin[stretchable-snip-mixin (snip%) ()]{Returns stretchable version of its argument with @racket[on-size] argument.
@defconstructor/auto-super[([on-size ((is-a?/c stretchable<%>) dimension-integer? dimension-integer? . -> . any) (λ (this w h) (void))])]{
  Returns snip with given @racket[on-size] method}                                                                                        
}

@defproc[(stretchable-snip-static-mixin (call-on-size ((is-a?/c stretchable<%>) dimension-integer? dimension-integer? . -> . any) (λ (this w h) (void)))) (make-mixin-contract snip%)]{
Returns stretchable version of its argument with @racket[call-on-size], called from the @racket[on-size] method.                                                                                                                                    
}

@defproc[(canvas-client-size (canvas (is-a?/c editor-canvas%))) (values dimension-integer? dimension-integer?)]{
Return client width and height for given canvas. Unlike @racket[get-client-size] method of @racket[window<%>], @racket[canvas-client-size]
subtract canvas's inset and return available to draw space.}