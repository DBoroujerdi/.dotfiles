(print "Loading early-init.el" #'external-debugging-output)

(when (getenv-internal "DEBUG")
  (setq-default
   debug-on-error t
   init-file-debug t))


(setq-default
 default-frame-alist
 '(
   ;;(background-color . "#3F3F3F")       ; Default background color
   (bottom-divider-width . 4)           ; Thin horizontal window divider
   ;;(foreground-color . "#DCDCCC")       ; Default foreground color
   (fullscreen . maximized)             ; Maximize the window by default
   (horizontal-scroll-bars . nil)       ; No horizontal scroll-bars
   (left-fringe . 8)                    ; Thin left fringe
   (menu-bar-lines . 0)                 ; No menu bar
   (right-divider-width . 4)            ; Thin vertical window divider
   (right-fringe . 8)                   ; Thin right fringe
   (tool-bar-lines . 0)                 ; No tool bar
   (undecorated-round . t)              ; Enable round corners
   (vertical-scroll-bars . nil))        ; No vertical scroll-bars
 load-prefer-newer t)                   ; Avoid old byte-compiled dependencies
