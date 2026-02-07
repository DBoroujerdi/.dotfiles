;;
;; Config
;;

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

(defun copy-from-osx ()
  (shell-command-to-string "pbpaste"))

(defun paste-to-osx (text &optional push)
  (let ((process-connection-type nil))
    (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
      (process-send-string proc text)
      (process-send-eof proc))))

(setq interprogram-cut-function 'paste-to-osx)
(setq interprogram-paste-function 'copy-from-osx)
      ))

(defalias 'yes-or-no-p 'y-or-n-p)


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

(dolist (hook '(text-mode-hook))
  (add-hook hook (lambda ()
                   (flyspell-mode 1)
                   (visual-line-mode 1)
                   )))

(setq explicit-shell-file-name "/bin/zsh")


;; default ansi-term binary

;; load path from shell
(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))

(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; Auto-refresh dired on file change
(add-hook 'dired-mode-hook 'auto-revert-mode)

;; Run garbage collection when idle for 30+ seconds
(run-with-idle-timer 30 t #'garbage-collect)

(setq display-line-numbers-type 'relative)

(global-goto-address-mode)
(global-display-line-numbers-mode)

;; Remeber minibufer history
;; cycle through history with M-p and M-n when in minibuffer
(setq history-length 25)
(savehist-mode 1)

;; Recent files
(recentf-mode 1)

;; Save place between sessions
(save-place-mode 1)

;; don't use graphical dialogs
(setq use-dialog-box nil)

;; Disable expensive features in large files
(add-hook 'find-file-hook
          (lambda ()
            (if (> (buffer-size) 100000)  ; Files >100KB
                (progn
                  (display-line-numbers-mode -1)
                  (visual-line-mode -1)
                  (goto-address-mode -1))
              (display-line-numbers-mode t)
              (global-goto-address-mode t))))

;; Enable clipboard integration - copy/paste between Emacs and system


(setq epg-gpg-program "gpg")

(defconst leader-key "SPC")

(setq evil-want-keybinding nil)

;; Keep custom-set-variables and friends out of my init.el
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
;; don't show errors in custom file
(load custom-file 'noerror 'nomessage)
