;;; package --- Summary
;;; Commentary:
;;; Code:

;; Optimize garbage collection during startup
(setq gc-cons-threshold (* 800 1024 1024))
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 100 1024 1024))))

(message "Running as user %s .."
	 ((lambda ()
	    (getenv
	     (if (equal system-type 'windows-nt) "USERNAME" "USER")))))

(add-to-list 'load-path (expand-file-name "lisp/" user-emacs-directory))

(load "use-doctor")            ;; Emacs startup checks
(load "use-package-bootstrap") ;; Bootstrap package management
(load "use-config")            ;; All the setq's
(load "use-editing")           ;; Evil, undo-tree, smartparens
(load "use-completion")        ;; Vertico, prescient, consult, company
(load "use-project")           ;; Projectile
(load "use-git")               ;; Magit
(load "use-navigation")        ;; Search and navigation tools
(load "use-lsp")               ;; Language server protocol
(load "use-ui")                ;; Themes and UI
(load "use-tools")             ;; Development tools
(load "use-functions")         ;; My custom functions
(load "use-keys")              ;; Additional keys
(load "use-server")            ;; Daemon/server config
