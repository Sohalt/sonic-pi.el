;;; sonic-pi.el --- A Emacs client for SonicPi

;; Copyright 2014 Joseph Wilk

;; Author: Joseph Wilk <joe@josephwilk.net>
;; URL: http://www.github.com/repl-electric/sonic-pi.el
;; Version: 0.1.0
;; Package-Requires: ((cl-lib "0.5") (dash "2.2.0") (emacs "24") (highlight "0"))
;; Keywords: SonicPi, Ruby

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; This file is not part of GNU Emacs.

;;; Commentary:

;;; Installation:

;;  M-x package-install sonic-pi
;;
;;  You need to have sonic-pi-tool installed and on your PATH
;;
;;; Usage:

;; M-x sonic-pi-jack-in

;;; Code:

(defgroup sonic-pi nil
  "A client for interacting with the SonicPi Server."
  :prefix "sonic-pi-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/repl-electric/sonic-pi.el")
  :link '(emacs-commentary-link :tag "Commentary" "Sonic Pi for Emacs"))

(require 'sonic-pi-mode)
(require 'sonic-pi-tool)

(defvar sonic-pi-margin-size 1)

(defconst sonic-pi-message-buffer-name "*sonic-pi-messages*")
(defcustom sonic-pi-log-messages t
  "If non-nil, log protocol messages to the `sonic-pi-message-buffer-name' buffer."
  :type 'boolean
  :group 'sonic)

(defvar sonic-pi-tool-cmd "sonic-pi-tool")
(defun sonic-pi-server-cmd () (format "%s start-server" sonic-pi-tool-cmd))
(defun sonic-pi-logs-cmd () (format "%s logs" sonic-pi-tool-cmd))

(defun sonic-pi--sonic-pi-tool-present-p ()
  "Check sonic-pi server exists"
  (executable-find "sonic-pi-tool"))

(defun sonic-pi-valid-setup-p ()
  (cond
   ((not (sonic-pi--sonic-pi-tool-present-p)) (progn (message "Could not find a sonic-pi-tool on PATH") nil))
   ((sonic-pi--sonic-pi-tool-present-p) t)
   (t nil)))

(defun sonic-pi-messages-buffer-init ()
  (when sonic-pi-log-messages
    (when (get-buffer sonic-pi-message-buffer-name)
      (with-current-buffer
          sonic-pi-message-buffer-name
        (erase-buffer)))
    (start-file-process-shell-command
     "sonic-pi-logs"
     sonic-pi-message-buffer-name
     ;;FIXME properly wait for sonic pi to start
     (format "sleep 5;%s"(sonic-pi-logs-cmd)))
    (display-buffer sonic-pi-message-buffer-name)))

(defun sonic-pi-sonic-server-cleanup ()
  (when (get-process "sonic-pi-server")
    (delete-process "sonic-pi-server")))

(defun sonic-pi-messages-buffer-cleanup ()
  (when (get-process "sonic-pi-logs")
    (delete-process "sonic-pi-logs")))


;;;###autoload
(defun sonic-pi-jack-in (&optional prompt-project)
  "Boot and connect to the SonicPi Server"
  (interactive)
  (when (sonic-pi-valid-setup-p)
    (if (not (get-process "sonic-pi-server"))
        (progn
          (message "Starting SonicPi server...")
          (start-file-process-shell-command
           "sonic-pi-server"
           "*sonic-pi-server-messages*"
           (sonic-pi-server-cmd))))
    (set-window-margins (get-buffer-window) sonic-pi-margin-size)
    (sonic-pi-connect)
    (message "Ready!")))

;;;###autoload
(defun sonic-pi-connect (&optional prompt-project)
  "Assumes SonicPi server is running and connects"
  (interactive)
  (when (sonic-pi-valid-setup-p)
    (sonic-pi-messages-buffer-init)))

(provide 'sonic-pi)

;;; sonic-pi.el ends here
