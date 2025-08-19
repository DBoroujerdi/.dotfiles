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
