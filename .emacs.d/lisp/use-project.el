;;; use-project.el --- Project management configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Project management and workspace configuration

;;; Code:

(require 'project)

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

(provide 'use-project)
;;; use-project.el ends here