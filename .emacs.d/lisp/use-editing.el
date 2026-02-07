;;; use-editing.el --- Editing enhancement configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Evil mode, undo-tree, and other editing enhancements

;;; Code:

(use-package exec-path-from-shell
  :ensure t)

(use-package evil
  :ensure t
  :demand t
  :init
   (progn
      (setq evil-undo-system 'undo-tree)
      (setq evil-want-keybinding nil))
  :config
  (evil-mode 1)
  (add-hook 'evil-insert-state-entry-hook (lambda () (setq cursor-type 'bar)))
  (add-hook 'evil-insert-state-exit-hook  (lambda () (setq cursor-type 'box))))

(use-package undo-tree
  :quelpa (undo-tree :fetcher gitlab :repo "tsc25/undo-tree")
  :diminish undo-tree-mode
  :init
  (global-undo-tree-mode)
  :config
  (general-def 'normal
    "U" 'undo-tree-visualize)
  (setq undo-tree-history-directory-alist '(("." . "~/.emacs.d./.cache"))))

(use-package evil-collection
  :after evil
  :diminish evil-collection-unimpaired-mode
  :config
  (evil-collection-init))

(use-package general
  :config
  (general-evil-setup)

  (general-create-definer general-leader-def
    :prefix leader-key)

  (general-mmap "M-h" 'windmove-left)
  (general-mmap "M-l" 'windmove-right)
  (general-mmap "M-j" 'windmove-down)
  (general-mmap "M-k" 'windmove-up)

  ;; Buffer splitting keybindings
  (general-leader-def 'normal 'override
    "|" 'split-window-horizontally
    "-" 'split-window-vertically)

  ;; Code navigation
  (general-leader-def 'normal 'override
    "g d" 'xref-find-definitions
    "g r" 'xref-find-references
    "g b" 'xref-go-back
    "g f" 'xref-go-forward))

(use-package smartparens
  :diminish smartparens-mode
  :config
  (progn
    (require 'smartparens-config)
    (smartparens-global-mode t)))

(use-package prog-mode
  :config (progn
            (add-hook 'prog-mode-hook (lambda ()
(require 'grep)
     (setq-local grep-find-ignored-directories
                 (cons "node_modules" (default-value 'grep-find-ignored-directories)))
     ))))

(provide 'use-editing)
;;; use-editing.el ends here
