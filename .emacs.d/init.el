;;; package --- Summary
;;; Commentary:
;;; Code:

;;
;; Bootstrap package management
;;

(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

;; Backups
(setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups")))
      vc-make-backup-files t
      version-control t
      kept-old-versions 0
      kept-new-versions 10
      delete-old-versions t
      backup-by-copying t)

(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("elpa" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

;;
;; Bootstrap package management
;;

(unless (package-installed-p 'quelpa)
  (with-temp-buffer
    (url-insert-file-contents "https://raw.githubusercontent.com/quelpa/quelpa/master/quelpa.el")
    (eval-buffer)
    (quelpa-self-upgrade)))

(package-initialize)

;; If never connected to repositories before, download package descriptions so
;; `use-package' can trigger installation of missing packages.
(when (not package-archive-contents)
    (package-refresh-contents))
(quelpa
 '(quelpa-use-package
   :fetcher git
   :url "https://github.com/quelpa/quelpa-use-package.git"))

(require 'quelpa-use-package)

(setq use-package-ensure-function 'quelpa)

;; Keep custom-set-variables and friends out of my init.el
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
;; don't show errors in custom file
(load custom-file 'noerror 'nomessage)

;;
;; End of package management bootstrap
;;

(message "Running as user %s .."
	 ((lambda ()
	    (getenv
	     (if (equal system-type 'windows-nt) "USERNAME" "USER")))))

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

(dolist (hook '(text-mode-hook))
  (add-hook hook (lambda ()
                   (flyspell-mode 1)
                   (visual-line-mode 1)
                   )))

(use-package exec-path-from-shell
  :ensure t)

;; default ansi-term binary
(setq explicit-shell-file-name "/bin/zsh")

;; load path from shell
(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))

(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)

;; Auto-refresh dired on file change
(add-hook 'dired-mode-hook 'auto-revert-mode)

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

(setq epg-gpg-program "gpg")

;;
;; Packages
;;

(defconst leader-key "SPC")

(setq evil-want-keybinding nil)

(use-package evil
  :ensure t
  :init
   (progn
      (setq evil-undo-system 'undo-tree)
      (setq evil-want-keybinding nil))
  :config
  (evil-mode 1))

(use-package eldoc
  :diminish eldoc-mode)

(use-package undo-tree
  :quelpa (undo-tree :fetcher gitlab :repo "tsc25/undo-tree")
  :diminish undo-tree-mode
  :init
  (global-undo-tree-mode)
  :config
  (general-def 'normal
    "U" 'undo-tree-visualize)
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d./.cache"))))

(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package evil-collection
  :after evil
  :diminish evil-collection-unimpaired-mode
  :ensure t
  :config
  (evil-collection-init))

(use-package general
  :ensure t
  :config
  (general-evil-setup)

  (general-create-definer general-leader-def
    :prefix leader-key)

  (general-mmap "C-h" 'windmove-left)
  (general-mmap "C-l" 'windmove-right)
  (general-mmap "C-j" 'windmove-down)
  (general-mmap "C-k" 'windmove-up)

  ;; Buffer splitting keybindings
  (general-leader-def 'normal 'override
    "|" 'split-window-horizontally
    "-" 'split-window-vertically))

(use-package smartparens
  :ensure t
  :diminish smartparens-mode
  :config
  (progn
    (require 'smartparens-config)
    (smartparens-global-mode t)))

(use-package vertico-prescient
  :ensure t
  :after vertico prescient)

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
              ("C-c C-e" . markdown-do)))

(use-package prescient
  :ensure t
  :after vertico
  :config (progn
            (prescient-persist-mode +1)
            (vertico-prescient-mode)))

(use-package projectile
  :ensure t
  :diminish projectile-mode
  :init
  (setq projectile-project-search-path '("~/projects/"))
  :config
  (progn
    (projectile-mode +1)
    (general-leader-def 'normal 'override
      "p p" 'projectile-commander
      "p f" 'projectile-find-file
      "p g" 'projectile-grep
      "p r" 'projectile-ripgrep
      "p v" 'projectile-run-vterm)))

(use-package which-key
  :ensure t
  :diminish which-key-mode
  :config
  (progn
    (which-key-setup-side-window-bottom))
  :init
  (which-key-mode))

(use-package prog-mode
  :config (progn
            (add-hook 'prog-mode-hook (lambda ()
(require 'grep)
     (setq-local grep-find-ignored-directories
                 (cons "node_modules" (default-value 'grep-find-ignored-directories)))
     ))))

(require 'project)

(use-package vertico
  :ensure t
  :quelpa (vertico :fetcher github
                   :repo "minad/vertico"
                   :branch "main"
                   :files ("*.el" "extensions/*.el"))
  :init (vertico-mode)
  )

(use-package consult
  :ensure t
  :config
  (general-leader-def 'normal 'override
    "b b" 'consult-buffer
    "f r" 'consult-recent-file
    "s c" 'consult-grep
    "s C" 'consult-git-grep
    "s i" 'consult-imenu
    "s I" 'consult-imenu-multi
    "s l" 'consult-line
    "s L" 'consult-line-multi
    "s o" 'consult-outline
    "s m" 'consult-mark
    "s M" 'consult-global-mark))

(use-package magit
  :ensure t
  :config
  (general-def 'normal "C-r" 'magit-refresh)
  (general-leader-def 'normal 'override
   "g g" 'magit-status
   "g s" 'magit-status
   "g l" 'magit-log))

(use-package magit-todos
  :after magit
  :ensure t
  :init
  (magit-todos-mode))


(use-package fzf
  :ensure t
  :config
  (setq fzf/args "-x --color bw --print-query --margin=1,0 --no-hscroll"
        fzf/executable "fzf"
        fzf/git-grep-args "-i --line-number %s"
        ;; Use ripgrep for fzf-grep
        fzf/grep-command "rg --no-heading -nH"
        ;; If nil, the fzf buffer will appear at the top of the window
        fzf/position-bottom t
        fzf/window-height 15)

  (general-leader-def 'normal 'override
    "s p" 'fzf-projectile
    "s g" 'fzf-git-grep
    "s f" 'fzf-grep))

;; Grep configuration
(use-package grep
  :config
  (progn
    ;; Use ripgrep if available
    (when (executable-find "rg")
      (setq grep-program "rg")
      (setq grep-find-use-xargs nil)
      (setq grep-use-null-device nil))

    ;; Custom grep functions
    (defun my/grep-project ()
      "Grep in current project using projectile."
      (interactive)
      (if (projectile-project-p)
          (call-interactively 'projectile-grep)
        (call-interactively 'grep)))

    (defun my/ripgrep-project ()
      "Ripgrep in current project using projectile."
      (interactive)
      (if (projectile-project-p)
          (call-interactively 'projectile-ripgrep)
        (call-interactively 'rgrep)))

    ;; Grep keybindings
    (general-leader-def 'normal 'override
      "/"   'my/ripgrep-project
      "s s" 'my/grep-project
      "s r" 'my/ripgrep-project
      "s d" 'grep-find
      "s l" 'lgrep
      "s R" 'rgrep)))

(use-package ag
  :ensure t
  :config
  (setq ag-highlight-search t)
  (setq ag-reuse-buffers t)
  (setq ag-reuse-window t)
  (general-leader-def 'normal 'override
    "s a" 'ag-project
    "s A" 'ag))

;; ripgrep support
(use-package ripgrep
  :ensure t
  :config
  (general-leader-def 'normal 'override
    "s R" 'ripgrep-regexp))

(use-package terraform-mode
  :ensure t
  :init (progn
          (setq terraform-format-on-save 't)
  :config (progn
            (with-eval-after-load 'eglot
              (add-to-list 'eglot-server-programs
                           '(terraform-mode . ("terraform-ls" "serve"))))
            (add-hook 'terraform-mode-hook #'eglot-ensure))))


;; not working..
(use-package vterm
  :ensure t
  :config (progn
            (print "vterm config")
            (add-hook 'vterm-mode-hook (lambda ()
                                         (print "vterm hook 2")
                                         (setq-local display-line-numbers-mode nil)))))

(use-package claude-code-ide
  :ensure t
  :quelpa (claude-code-ide :fetcher github
                           :repo "manzaltu/claude-code-ide.el")
  :after vterm
  :config
  (progn
    ;; Use vterm as the terminal backend
    (setq claude-code-ide-terminal-backend 'vterm)
    ;; Configure window placement
    (setq claude-code-ide-window-side 'right)
    (setq claude-code-ide-window-width 100)
    ;; Enable Emacs MCP tools integration
    (claude-code-ide-emacs-tools-setup))
  :general
  (general-leader-def 'normal 'override
    "a c" 'claude-code-ide-menu
    "a i" 'claude-code-ide
    "a p" 'claude-code-ide-send-prompt
    "a s" 'claude-code-ide-stop))

;;
;; LSP
;;

(use-package eglot
  :ensure t
  :config
  ;; Configure eglot settings
  (setq eglot-autoshutdown t)
  (setq eglot-sync-connect 1)
  (setq eglot-connect-timeout 10)
  (setq eglot-events-buffer-size 0)
  (setq eglot-ignored-server-capabilities '(:documentHighlightProvider))

  ;; Add server programs
  (add-to-list 'eglot-server-programs
               '((typescript-mode typescript-ts-mode tsx-ts-mode) . ("typescript-language-server" "--stdio")))

  ;; Keybindings for LSP actions
  (general-leader-def 'normal 'override
    "l a" 'eglot-code-actions
    "l r" 'eglot-rename
    "l f" 'eglot-format
    "l d" 'xref-find-definitions
    "l R" 'xref-find-references
    "l i" 'eglot-find-implementation
    "l t" 'eglot-find-typeDefinition
    "l s" 'eglot-reconnect
    "l S" 'eglot-shutdown
    "l h" 'eldoc))

(use-package typescript-mode
  :ensure t
  :mode (("\\.ts\\'" . typescript-mode)
         ("\\.tsx\\'" . tsx-ts-mode))
  :hook ((typescript-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode . eglot-ensure))
  :config
  ;; Set indentation
  (setq typescript-indent-level 2))

(use-package company
  :ensure t
  :diminish company-mode
  :config
  (add-hook 'after-init-hook 'global-company-mode))

(use-package spotlight
  :ensure t)

(use-package prettier-js
  :ensure t
  :hook ((js-mode . prettier-js-mode)
         (js-ts-mode . prettier-js-mode)
         (js2-mode . prettier-js-mode)
         (typescript-mode . prettier-js-mode)
         (typescript-ts-mode . prettier-js-mode)
         (tsx-ts-mode . prettier-js-mode)
         (json-mode . prettier-js-mode)
         (json-ts-mode . prettier-js-mode)
         (css-mode . prettier-js-mode)
         (css-ts-mode . prettier-js-mode)
         (scss-mode . prettier-js-mode)
         (html-mode . prettier-js-mode)
         (web-mode . prettier-js-mode)
         (yaml-mode . prettier-js-mode)
         (yaml-ts-mode . prettier-js-mode)
         (markdown-mode . prettier-js-mode)
         (graphql-mode . prettier-js-mode))
  :config
  ;; Use local prettier if available
  (setq prettier-pre-warm 'none)
  (setq prettier-js-use-modules-bin t)

  ;; Prettier keybindings
  (general-leader-def 'normal 'override
    "c f" 'prettier-prettify
    "c F" 'prettier-prettify-region))

(use-package diminish
  :ensure t)

(use-package tree-sitter
  :ensure t
  :config
  :after tree-sitter-langs
  (progn
    (require 'tree-sitter-langs)
    (global-tree-sitter-mode)
    (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)))

(use-package tree-sitter-langs
  :ensure t)

(use-package yaml-mode
  :ensure t)

(use-package doom-themes
  :ensure t
  :after all-the-icons
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-one t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  (doom-themes-neotree-config)
  ;; or for treemacs users
  (setq doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

;;(set-frame-font "SFMono" nil t)


(use-package all-the-icons
  :ensure t
  :if (display-graphic-p))

;; set modeline font
;;(set-face-attribute 'mode-line nil :family "SFMono")

(load "~/.emacs.d/init-functions.el")
(load "~/.emacs.d/init-keys.el")

;;
;; Emacs Server Configuration
;;

;; Start server for emacsclient connections
(require 'server)

;; Ensure server directory exists with proper permissions
(when (not (file-directory-p server-auth-dir))
  (make-directory server-auth-dir t)
  (set-file-modes server-auth-dir #o700))

;; Start server if not already running
(unless (server-running-p)
  (server-start))

;; Configure server settings
(setq server-client-instructions nil)  ; Don't show instructions in client
(setq server-window 'pop-to-buffer)    ; How to display client buffers

;; Function to gracefully handle client frames
(add-hook 'server-switch-hook
          (lambda ()
            (when (current-local-map)
              (use-local-map (copy-keymap (current-local-map))))
            (local-set-key (kbd "C-x k") 'server-edit)))

;; Handle emacsclient frame parameters
(add-to-list 'default-frame-alist '(client . nowait))

(put 'dired-find-alternate-file 'disabled nil)
