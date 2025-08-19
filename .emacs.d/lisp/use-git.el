;;; use-git.el --- Version control configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Git and version control configuration

;;; Code:

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

(provide 'use-git)
;;; use-git.el ends here