#lang scribble/manual
@require[@for-label[stretchable-snip
                    racket/base racket/class racket/gui/base]]

@title{stretchable-snip}
@author+email["Roman Klochkov" "kalimehtar@mail.ru"]

@defmodule[stretchable-snip]

This package provides mixins to make stretchable snips. Stretchable snups have @racket[on-size] method, that will
be called, at any time, when the size of the canvas is changed. It can be used to implement snips, which view depends on the size of
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
      (init-field [margin 40])
      (super-make-object (make-object bitmap% 1 1))
      (define/override (set-admin adm)
        (when adm
          (define w (box 0))
          (define h (box 0))
          (send adm get-view #f #f w h #f)
          (on-size (unbox w) (unbox h)))
        (super set-admin adm))
      (define/public (on-size w h)
        (set-bitmap (draw-line (- w margin)))))))

@defmixin[stretchable-editor-canvas-mixin (editor-canvas%) ()]{Returns stretchable version of its argument.}

@defclass[stretchable-editor-canvas% editor-canvas% ()]{
A @racket[stretchable-editor-canvas%] is @racket[(stretchable-editor-canvas-mixin editor-canvas%)]}

@definterface[stretchable<%> ()]{The @racket[stretchable<%>] should be implemented by all snips, whose @racket[on-size]
method shoul be called, when editor's size changes.}

@defclass[hr% image-snip% (stretchable<%>)]{This is a snip, that display horizontal rule like <HR> tag in HTML.

@defconstructor[([delta dimension-integer? 40])]{Create @racket[hr%] snip with @racket[delta] from the right end of the canvas.}}

@defmixin[stretchable-snip-mixin (snip%) ()]{Returns stretchable version of its argument with @racket[on-size] argument.
@defconstructor/auto-super[([on-size (object? dimension-integer? dimension-integer? . -> . any) (λ (this w h) (void))])]{
  Returns snip with given @racket[on-size] method}                                                                                        
}

@defproc[(stretchable-snip-static-mixin (call-on-size (object? dimension-integer? dimension-integer? . -> . any) (λ (this w h) (void)))) (make-mixin-contract snip%)]{
Returns stretchable version of its argument with @racket[call-on-size], called from the @racket[on-size] method.                                                                                                                                    
}