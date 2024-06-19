;;; sonic-pi-tool.el --- Communicate with Sonic Pi through sonic-pi-tool -*- lexical-binding: t -*-

(require 'cl-lib)
(require 'highlight)

(defvar flash-time 0.5)

(defface eval-sonic-pi-flash
  '((((class color)) (:background "#F23444" :foreground "white" :bold nil))
    (t (:inverse-video t)))
  "Face for highlighting sexps during evaluation."
  :group 'eval-sonic-pi)

(defface eval-sonic-pi-flash-error
  '((((class color)) (:foreground "red" :bold nil))
    (t (:inverse-video t)))
  "Face for highlighting sexps signaled errors during evaluation."
  :group 'eval-sonic-pi)

(defun sonic-pi-tool-command (cmd &rest args)
  (apply 'start-process "sonic-pi-tool" nil "sonic-pi-tool" cmd args))

(defun sonic-pi-eval-text (start end)
  "Evaluate text between start and end position in the current buffer."
  (sonic-pi-tool-command "eval" (buffer-substring-no-properties start end)))

(defun sonic-pi-send-file ()
  "Evaluate contents of file of current buffer."
  (sonic-pi-tool-command (format "eval-file %s" (buffer-file-name))))

(defun sonic-pi-send-region ()
  "Send a region to Sonic Pi."
  (interactive)
  (sonic-pi-eval-text (region-beginning) (region-end))
  (hlt-highlight-regexp-region (region-beginning) (region-end) ".+" 'eval-sonic-pi-flash nil)
  (run-at-time flash-time nil 'hlt-unhighlight-region nil nil nil))

(defun sonic-pi-send-buffer ()
  "Send the current buffer to Sonic Pi."
  (interactive)


  ;;TODO: I don't understand overlays very well. Something other overlay is blocking our overlay
  ;;When we remove just ours, we never see any new overlays appear :(
  ;;(remove-overlays (window-start) (window-end) 'sonic-pi-gutter t)
  (dolist (o (overlays-in (window-start) (window-end)))
    (delete-overlay o)
    ;;(when (overlay-get o 'sonic-pi-gutter) (delete-overlay o))
    )
  (sonic-pi-eval-text (point-min) (point-max))
  ;; NOTE: to fix issue [https://github.com/repl-electric/sonic-pi.el/issues/21] use
  ;; (save-buffer)
  ;;(sonic-pi-osc-send-file)
  (hlt-highlight-regexp-region nil nil ".+" 'eval-sonic-pi-flash nil)
  (run-at-time flash-time nil 'hlt-unhighlight-region))

(defun sonic-pi--send (region)
  "Helper function to send and highlighting region."
  (cl-destructuring-bind (start end) region
    (sonic-pi-eval-text start end)
    (hlt-highlight-regexp-region start end ".+" 'eval-sonic-pi-flash nil))
  (run-at-time flash-time nil 'hlt-unhighlight-region nil nil nil))

(defun sonic-pi-send-live-loop ()
  "send a live-loop to sonic via osc"
  (interactive)
  (sonic-pi--send (sonic-pi--live-loop-region)))

(defun sonic-pi-smart-send ()
  "If region is active, send it,
else if there is an enclosing `live_loop' or `with_fx' send it,
else send current line."
  (interactive)
  (sonic-pi--send (sonic-pi--smart-region)))

(defun sonic-pi--smart-region ()
  "Find region for smart-send command."
  (if (region-active-p)
      (list (region-beginning) (region-end))
    (or (sonic-pi--live-loop-region)
        (list (line-beginning-position) (line-end-position)))))

(defun sonic-pi--live-loop-region ()
  "Find region with `live_loop' or `with_fx'."
  (when-let (start (save-excursion (re-search-backward "^\\(live_loop\\|with_fx\\)" nil t)))
    (list start (save-excursion (ruby-end-of-block) (line-end-position)))))

(defun sonic-pi-ping ()
  "Test if sonic pi server is really, really there."
  (interactive)
  (sonic-pi-tool-command "check"))

(provide 'sonic-pi-tool)

;;; sonic-pi-tool.el ends here
