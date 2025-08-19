;;; use-editing.el --- Editing enhancement configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Evil mode, undo-tree, and other editing enhancements

;;; Code:

(use-package exec-path-from-shell
  :ensure t)

(use-package evil
  :ensure t
  :init
   (progn
      (setq evil-undo-system 'undo-tree)
      (setq evil-want-keybinding nil))
  :config
  (evil-mode 1))

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

  (general-mmap "C-h" 'windmove-left)
  (general-mmap "C-l" 'windmove-right)
  (general-mmap "C-j" 'windmove-down)
  (general-mmap "C-k" 'windmove-up)

  ;; Buffer splitting keybindings
  (general-leader-def 'normal 'override
    "|" 'split-window-horizontally
    "-" 'split-window-vertically))

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