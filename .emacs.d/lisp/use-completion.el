;;; use-completion.el --- Completion framework configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Completion, selection, and narrowing frameworks

;;; Code:

(use-package vertico
  :ensure t
  :quelpa (vertico :fetcher github
                   :repo "minad/vertico"
                   :branch "main"
                   :files ("*.el" "extensions/*.el"))
  :init (vertico-mode))

(use-package prescient
  :ensure t
  :after vertico
  :config (progn
            (prescient-persist-mode +1)
            (vertico-prescient-mode)))

(use-package vertico-prescient
  :ensure t
  :after vertico prescient)

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
    "s b" 'consult-line
    "s L" 'consult-line-multi
    "s o" 'consult-outline
    "s m" 'consult-mark
    "s M" 'consult-global-mark))

(use-package company
  :ensure t
  :diminish company-mode
  :config
  (add-hook 'after-init-hook 'global-company-mode))

(provide 'use-completion)
;;; use-completion.el ends here