;;; sonic-pi-mode.el --- Minor mode for SonicPi interactions -*- lexical-binding: t -*-

(require 'sonic-pi-tool)

(defun sonic-pi-quit ()
  "Shutdown SonicPi"
  (interactive)
  (sonic-pi-messages-buffer-cleanup)
  (sonic-pi-sonic-server-cleanup))

(defun sonic-pi-restart         () (interactive) (sonic-pi-quit) (sonic-pi-jack-in))
(defun sonic-pi-stop-all        () (interactive) (sonic-pi-tool-command "stop"))
(defun sonic-pi-start-recording (filename) (interactive "FSave to:") (sonic-pi-tool-command (format "record %s" filename)))

(defvar sonic-pi-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c M-j") 'sonic-pi-jack-in)
    (define-key map (kbd "C-c M-c") 'sonic-pi-connect)
    (define-key map (kbd "C-c C-k") 'sonic-pi-send-buffer)
    (define-key map (kbd "C-c C-r") 'sonic-pi-send-region)
    (define-key map (kbd "C-c C-q") 'sonic-pi-quit)
    (define-key map (kbd "C-c C-b") 'sonic-pi-stop-all)
    (define-key map (kbd "C-c C-c") 'sonic-pi-send-live-loop)
    map))

;;;###autoload
(define-derived-mode
  sonic-pi-mode
  ruby-mode
  "π"
  "Minor mode for SonicPi interaction from a Ruby buffer."
  :init-value nil
  :global     nil
  :lighter " π"
  :keymap sonic-pi-mode-map)

(add-to-list 'auto-mode-alist '("\\.spi$" . sonic-pi-mode))

(provide 'sonic-pi-mode)

;;; sonic-pi-mode.el ends here
