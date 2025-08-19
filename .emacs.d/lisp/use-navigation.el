;;; use-navigation.el --- Search and navigation configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Search, grep, and navigation tools configuration

;;; Code:

(use-package fzf-native
  :straight
  (:repo "dangduc/fzf-native"
   :host github
   :files (:defaults "*.c" "*.h" "*.txt"))
  :init
  (setq fzf-native-always-compile-module t)
  :config
  (fzf-native-load-own-build-dyn))

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

(use-package spotlight
  :ensure t)

(provide 'use-navigation)
;;; use-navigation.el ends here