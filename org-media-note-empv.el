;;; org-media-note-empv.el --- empv integration for org-media-note -*- lexical-binding: t; -*-

;;; Commentary:
;;; Code:
;;;; Requirements

(require 'org-media-note-core)

;;;; Variables

(defvar org-media-note-last-play-speed 1.0
  "Last play speed.")

(defvar org-media-note-last-volume 100.0
  "Last volume level.")

;;;; Commands
(defun org-media-note-play-smart (arg)
  "Open media file in empv based on the current context.
If ARG argument is provided, force playing from beginning."
  (interactive "P")
  (cl-multiple-value-bind (file-or-url start-time end-time)
      (org-media-note--get-media-info)
    (when file-or-url
      (org-media-note--follow-link file-or-url
                                   (if arg nil start-time)
                                   (if arg nil end-time)))))

(defun org-media-note-seek (direction)
  "Seek in the given DIRECTION according to the configured method and value."
  (interactive)
  (let ((was-pause (eq (org-media-note--get-property "pause") t))
        (backward? (eq direction 'backward)))
    (cl-case org-media-note-seek-method
      (seconds (empv--send-command (list "seek"
                                         (if backward?
                                             (- org-media-note-seek-value)
                                           org-media-note-seek-value)
                                         "relative")))
      (percentage (empv--send-command (list "seek"
                                             (if backward?
                                                 (- org-media-note-seek-value)
                                               org-media-note-seek-value)
                                             "relative-percent")))
      (frames (progn
                (dotimes (_ org-media-note-seek-value)
                  (empv--send-command (list (if backward? "frame-back-step" "frame-step")))))
              (sleep-for 0.3) ;; without this, frame seek cannot resume play
              (when (not was-pause)
                (empv-resume))))))

(defun org-media-note-change-speed-by (speed-step)
  "Modify playing media's speed by SPEED-STEP."
  (let ((current-speed (org-media-note--get-property "speed")))
    (empv--send-command (list "set_property" "speed" (+ current-speed speed-step)))))

(defun org-media-note-mpv-toggle-speed ()
  "Toggle playback speed of media."
  (interactive)
  (let ((current-speed (org-media-note--get-property "speed")))
    (if (= current-speed 1.0)
        (empv--send-command (list "set_property" "speed" org-media-note-last-play-speed))
      (setq org-media-note-last-play-speed current-speed)
      (empv--send-command (list "set_property" "speed" 1)))))

(defun org-media-note-change-volume-by (step)
  "Set playing volume by STEP."
  (empv--send-command (list "add" "volume" step))
  (setq org-media-note-last-volume (org-media-note--get-property "volume")))

(defun org-media-note-mpv-toggle-volume ()
  "Toggle playback volume of media."
  (interactive)
  (let ((current-volume (org-media-note--get-property "volume")))
    (if (= 100.0 current-volume)
        (empv--send-command (list "set_property" "volume" org-media-note-last-volume))
      (progn
        (setq org-media-note-last-volume current-volume)
        (empv--send-command (list "set_property" "volume" 100))))))


;;;; Footer
(provide 'org-media-note-empv)
;;; org-media-note-empv.el ends here
