%%%% written for 2.19.65

%% c/p from lily-library.scm (it is not public)
#(define (sign x)
  (if (= x 0)
      0
      (if (< x 0) -1 1)))
      
#(define (radians->degree radians)
  (/ (* radians 180) PI))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Glissando with text
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Reads from Glissando.details
%%%%   - glissando-text
%%%%   - glissando-text-font-size
%%%%   - glissando-text-padding

#(define* ((gliss-plus-text #:optional always-add-text) grob)
  (let*  ((orig-grob (ly:grob-original grob))
          (broken-beams (ly:spanner-broken-into orig-grob))
          (stil (ly:line-spanner::print grob)))
    (if (or (null? broken-beams)
            (and (pair? broken-beams)
                 (or
                    always-add-text
                    (equal? grob (car broken-beams)))))
        (if (not (ly:stencil? stil))
            #f
            (let* ((layout (ly:grob-layout grob))
                   (line-thickness
                     (ly:output-def-lookup layout 'line-thickness))
                   (props
                     (ly:grob-alist-chain
                       grob
                       (ly:output-def-lookup layout 'text-font-defaults)))
                   (font
                     (ly:paper-get-font
                     layout
                     (cons
                       '((font-encoding . fetaMusic) (font-name . #f))
                       props)))
                   (trill-glyph
                     (ly:font-get-glyph font "scripts.trill_element"))
                   (trill-glyph-height
                     (interval-length (ly:stencil-extent trill-glyph Y)))
                   (zigzag-width
                     (ly:grob-property grob 'zigzag-width))
                   (thickness (ly:grob-property grob 'thickness))
                   (thick
                     (if (number? thickness)
                         (/ thickness 10)
                         line-thickness))
                   (style (ly:grob-property grob 'style))
                   (corr
                     (cond ((eq? style 'trill)
                             trill-glyph-height)
                           ((eq? style 'zigzag)
                             (+ thick zigzag-width))
                           (else 0)))
                   (stil-x-ext (ly:stencil-extent stil X))
                   (stil-y-ext (ly:stencil-extent stil Y))
                   (stil-x-length (- (cdr stil-x-ext) (car stil-x-ext)))
                   (stil-y-length (- (cdr stil-y-ext) (car stil-y-ext)))
                   (details (ly:grob-property grob 'details))
                   (gliss-text
                     (assoc-get 'glissando-text details "gliss."))
                   (gliss-text-font-size
                     (assoc-get 'glissando-text-font-size details -5))
                   (gliss-text-padding
                     (assoc-get 'glissando-text-padding details 0.5))
                   (left-bound-info (ly:grob-property grob 'left-bound-info))
                   (y-left (assoc-get 'Y left-bound-info))
                   (right-bound-info (ly:grob-property grob 'right-bound-info))
                   (y-right (assoc-get 'Y right-bound-info))
                   (slant (sign (- y-right y-left)))
                   (gradient
                     (/ (- stil-y-length corr) stil-x-length))
                   ;; `ly:stencil-rotate' needs an angle in degrees...
                   ;; TODO use ly:angle ?
                   (alpha
                     (radians->degree
                       (angle
                         (make-rectangular
                           stil-x-length
                           (- stil-y-length corr line-thickness)))))
                   (text-stencil
                     (grob-interpret-markup
                       grob
                         (make-halign-markup CENTER
                           (make-fontsize-markup
                             gliss-text-font-size
                             gliss-text))))
                   (text-stencil-height
                     (interval-length (ly:stencil-extent text-stencil Y)))
                   (y-move
                     (+
                       (/ text-stencil-height 2)
                       gliss-text-padding))
                   (rotated-text-stil
                     (ly:stencil-rotate text-stencil (* slant alpha) 0 0))
                   (text-center-X
                     (interval-center (ly:stencil-extent rotated-text-stil X)))
                   (translated-text-stencil
                     (ly:stencil-translate
                       rotated-text-stil
                       ;; Constuction-helpers
                       ;text-stencil
                       ;(make-cross-stencil '(0 . 0)) ;; not included atm
                       (cons
                         (+
                           (car stil-x-ext)
                           (/ stil-x-length 2)
                           (* slant -1 y-move gradient))
                         (+
                           (car stil-y-ext)
                           (/ stil-y-length 2)
                           y-move)))))
            (ly:stencil-add
              stil
              ;; Construction-helpers
              ;;
              ;(make-line-stencil
              ;  0.1
              ;  (+ (car stil-x-ext)(/ stil-x-length 2))
              ;  (+ (car stil-y-ext)(/ stil-y-length 2))
              ;  (+ (car stil-x-ext)(/ stil-x-length 2)(* slant -1 10 gradient))
              ;  10)
              ;;
              ;; (2) colors the text-part
              ;;
              ;(stencil-with-color translated-text-stencil red)
              translated-text-stencil
              )))
        stil)))

glissandoTextOn =
  \temporary \override Glissando.stencil =
    #(gliss-plus-text
      ;; change to true, if added text is wished for both parts of a broken
      ;; glissando
      ;; TODO added text at second parts needs to be improved, vertical
      ;; positioning is sometimes bad
      #f)

glissandoTextOff = \revert Glissando.stencil