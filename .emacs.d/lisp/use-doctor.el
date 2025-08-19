(defun me/doctor-error (format &rest arguments)
  "Signal an error with `user-error' using FORMAT and ARGUMENTS."
  (apply #'user-error (concat "[Doctor] " format) arguments))

(let ((current emacs-version)
      (target "30"))
  (when (version< current target)
    (me/doctor-error "Emacs %s is not supported. Install %s" current target)))
