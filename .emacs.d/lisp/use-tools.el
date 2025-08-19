;;; use-tools.el --- Development tools configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Development tools including vterm, which-key, and claude-code-ide

;;; Code:

(use-package which-key
  :ensure t
  :diminish which-key-mode
  :config
  (progn
    (which-key-setup-side-window-bottom))
  :init
  (which-key-mode))

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

(provide 'use-tools)
;;; use-tools.el ends here