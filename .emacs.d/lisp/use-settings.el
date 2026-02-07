
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

;; Backups
(setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups")))
      vc-make-backup-files t
      version-control t
      kept-old-versions 0
      kept-new-versions 10
      delete-old-versions t
      backup-by-copying t)

;; Keep custom-set-variables and friends out of my init.el
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
;; don't show errors in custom file
(load custom-file 'noerror 'nomessage)

;; set font
(set-frame-font "Zed Plex Mono" nil t)

;; set modeline font
;; (set-face-attribute 'mode-line nil :family "Zed Plex Mono")

;; automatically load buffer when file changes outside of emacs
(global-auto-revert-mode t)

;; This makes my Emacs startup time ~35% faster.
(setq gc-cons-threshold 100000000)

;; inserts newline on C-n when on last line in the buffer
(setq next-line-add-newlines t)

;; prefer spaces over tabs
(setq-default indent-tabs-mode nil)

;; reload TAGS file automatically
;; stops that annoying popup dialogue box
(setq tags-revert-without-query 1)

;; typed text replaces selected
(delete-selection-mode 1)

(if (eq system-type 'darwin)
    (progn
      ;; Cmd as meta
      ;; (setq mac-option-key-is-meta nil)
      ;; (setq mac-command-key-is-meta t)
      ;; (setq mac-option-modifier 'super) ; make opt key do Super
      ;; (setq mac-command-modifier 'meta)
      ))

(defalias 'yes-or-no-p 'y-or-n-p)

;; disable toolbar
(tool-bar-mode -1)

;; solid cursor
(blink-cursor-mode 0)

;; disable scroll bar
(scroll-bar-mode -1)

;; no tool bar
(tool-bar-mode 0)

;; no menu bar
(menu-bar-mode 0)

;; no default start up screen
(setq inhibit-startup-screen t)

(setq inhibit-splash-screen t)

;; no initial scratch text
(setq initial-scratch-message nil)

;; buffer line spacing
(setq-default line-spacing 5)

;; go full screen on start
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; limit the number of times a frame can split
(setq split-width-threshold 200)
(setq split-height-threshold 120)

(setq delete-old-versions -1)

(setq coding-system-for-read 'utf-8)
(setq coding-system-for-write 'utf-8)

;; delete trailing whitespace on save action
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Save here instead of littering current directory with emacs backup files
(setq backup-directory-alist `(("." . "~/.emacs.d/.saves")))

;; Mousewheel scrolling can be quite annoying, lets fix it to scroll smoothly.
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)


;; suppress bell sounds
(setq ring-bell-function 'ignore)
(setq visible-bell nil)

;; delete excess backup versions silently
(setq delete-old-versions -1)

;; use version control
(setq version-control t)

;; make backups file even when in version controlled dir
(setq vc-make-backup-files t)

;; don't ask for confirmation when opening symlinked file
(setq vc-follow-symlinks t)

;; transform backups file name
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)))

;; sentence SHOULD end with only a point.
(setq sentence-end-double-space nil)

;; toggle wrapping text at the 80th character
(setq default-fill-column 80)

;; quick fix to get around the exceeding max-lisp-eval-depth errors
(setq max-lisp-eval-depth 10000)
