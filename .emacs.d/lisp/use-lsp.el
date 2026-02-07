;;; use-lsp.el --- LSP and language support configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Language Server Protocol and language-specific configurations

;;; Code:

(use-package eglot
  :ensure t
  :defer t
  :hook ((prog-mode . eglot-ensure))
  :config
  ;; Configure eglot settings
  (setq eglot-autoshutdown t)
  (setq eglot-sync-connect 1)
  (setq eglot-connect-timeout 10)
  (setq eglot-events-buffer-size 0)
  (setq eglot-ignored-server-capabilities '(:documentHighlightProvider))

  ;; Configure project root detection for Go modules
  (require 'project)

  (defun project-find-go-module (dir)
    (when-let ((root (locate-dominating-file dir "go.mod")))
      (cons 'go-module root)))

  (cl-defmethod project-root ((project (head go-module)))
    (cdr project))

  (add-hook 'project-find-functions #'project-find-go-module)

  ;; Add server programs..

  ;; Add go lsp server
  (add-to-list 'eglot-server-programs
               '((typescript-mode typescript-ts-mode tsx-ts-mode) . ("typescript-language-server" "--stdio")))

;; Add auto-format hook for Go
(defun eglot-format-buffer-before-save ()
  (add-hook 'before-save-hook #'eglot-format-buffer -10 t))

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

(use-package go-mode
  :ensure t
  :defer t
  :mode ("\\.go\\'" . go-mode)
  :hook ((go-mode . eglot-ensure)
         (go-mode . go-mod-mode))
  :after eglot
  :config
  ;; Set Go indentation settings
  (setq go-indent-mode t)
  (setq go-tab-width 2)
  (setq go-echo-keystrokes 0.1)
  (setq go-add-tags t)
  (setq go-remove-tags t)
  (setq gofmt-command "goimports")
  (setq-default eglot-workspace-configuration
                '((:gopls .
                          ((staticcheck . t)
                           (matcher . "CaseSensitive")))))

  (add-to-list 'eglot-server-programs
               '((go-mode) . ("gopls")))

  (add-hook 'go-mode-hook #'eglot-format-buffer-before-save)

  ;; Auto-organize imports before saving
  (add-hook 'before-save-hook
            (lambda ()
              (when (derived-mode-p 'go-mode)
                (call-interactively 'eglot-code-action-organize-imports)))
            nil t)

  (add-hook 'before-save-hook
    (lambda ()
        (call-interactively 'eglot-code-action-organize-imports))
    nil t)
  (add-hook 'before-save-hook 'gofmt-before-save)

  (add-hook 'go-mode-hook 'lsp-deferred)
  (add-hook 'go-mode-hook 'subword-mode)
  (add-hook 'go-mode-hook (lambda ()
                          (setq tab-width 4)
                          (flycheck-add-next-checker 'lsp 'go-vet)
                          (flycheck-add-next-checker 'lsp 'go-staticcheck))))

(use-package terraform-mode
  :ensure t
  :init (progn
          (setq terraform-format-on-save 't)
  :config (progn
            (with-eval-after-load 'eglot
              (add-to-list 'eglot-server-programs
                           '(terraform-mode . ("terraform-ls" "serve"))))
            (add-hook 'terraform-mode-hook #'eglot-ensure))))

(use-package yaml-mode
  :ensure t)

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown")
  :bind (:map markdown-mode-map
              ("C-c C-e" . markdown-do)))

(use-package prettier-js
  :ensure t
  :defer t
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

(use-package tree-sitter
  :ensure t
  :demand t
  :config
  (global-tree-sitter-mode)
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

(use-package tree-sitter-langs
  :ensure t
  :demand t)

(use-package treesit-auto
  :ensure t
  :demand t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; Helper function to test gopls connection
(defun test-gopls-connection ()
  "Test manual gopls connection for debugging."
  (interactive)
  (let ((proc (start-process "gopls-test" "*gopls-test*" "gopls" "-remote=auto" "serve")))
    (set-process-sentinel proc
      (lambda (process event)
        (message "gopls process: %s, event: %s" process event)))))

(use-package eldoc
  :diminish eldoc-mode)

(provide 'use-lsp)
;;; use-lsp.el ends here
