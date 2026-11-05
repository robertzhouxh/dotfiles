;;; emacs-solo-ai.el --- AI terminal launchers (Ollama, Gemini, Claude, opencode)  -*- lexical-binding: t; -*-
;;
;; Author: Rahul Martim Juliato
;; URL: https://github.com/LionyxML/emacs-solo
;; Package-Requires: ((emacs "30.1"))
;; Keywords: tools, convenience
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;;
;; Provides interactive functions to launch AI chat sessions
;; (Ollama, Gemini, Claude, opencode) inside `ansi-term' buffers.  Supports
;; sending selected regions as context.

;;; Code:

(use-package emacs-solo-ai
  :ensure nil
  :no-require t
  :defer t
  :bind (("C-c C-8" . emacs-solo/claude-tui-chat)
         ("C-c C-9" . emacs-solo/opencode-chat))
  :init
  (defun emacs-solo/ollama-run-model ()
    "Run `ollama list`, let the user choose a model.
And open it in `ansi-term`.
If a region is selected, use it as a query.
If a prompt is provided, it's prepended."
    (interactive)
    (let* ((output (shell-command-to-string "ollama list"))
           (models (mapcar (lambda (line) (car (split-string line)))
                           (cdr (split-string output "\n" t))))
           (selected (completing-read "Select Ollama model: " models nil t))
           (region-text (when (use-region-p)
                          (buffer-substring-no-properties (region-beginning)
                                                          (region-end))))
           (prompt (read-string "Ollama Prompt (optional): " nil nil nil)))
      (when (and selected (not (string-empty-p selected)))
        (ansi-term "/bin/sh")
        (sit-for 1)
        (let* ((body (string-join (delq nil (list prompt region-text)) "\n"))
               (escaped-body (replace-regexp-in-string "\"" "\\\\\"" body))
               (command (format "printf \"%s\" | ollama run %s" escaped-body selected)))
          (term-send-raw-string command)
          (term-send-raw-string "\n")))))


  (defun emacs-solo/gemini-chat ()
    "Start a new interactive `gemini` session in an `ansi-term` buffer.
This provides better rendering for the CLI's rich text user interface."
    (interactive)
    (let* ((default-directory (or (vc-root-dir)
                                  (and emacs-solo-ai-scratch-path
                                       (file-directory-p emacs-solo-ai-scratch-path)
                                       emacs-solo-ai-scratch-path)
                                  default-directory))
           (buffer-name (generate-new-buffer-name
                         (format "gemini-chat:%s"
                                 (file-name-nondirectory (directory-file-name default-directory))))))
      (let ((proc-buffer (ansi-term "gemini" buffer-name)))
        (with-current-buffer proc-buffer
          (pop-to-buffer proc-buffer)
          (setq-local column-number-mode nil)))))


  ;; ---------- Claude Code TUI ----------

  (defcustom emacs-solo-claude-executable "claude"
    "Path to the `claude' executable used by the terminal launcher."
    :type 'string
    :group 'tools)

  (defun emacs-solo/claude-tui-chat ()
    "Start or reuse an interactive `claude' TUI session in an `ansi-term' buffer.

If a region is active, prompts for a query and sends the region as
context.  Reuses a live buffer for the current project when present."
    (interactive)
    (require 'term)
    (let* ((source-file (buffer-file-name))
           (project-root (vc-root-dir))
           (default-directory (or project-root
                                  (and emacs-solo-ai-scratch-path
                                       (file-directory-p emacs-solo-ai-scratch-path)
                                       emacs-solo-ai-scratch-path)
                                  default-directory))
           (file-ref (when source-file
                       (if project-root
                           (file-relative-name source-file project-root)
                         source-file)))
           (file-prefix (when file-ref
                          (format "On file @%s " file-ref)))
           (region-text (when (use-region-p)
                          (buffer-substring-no-properties (region-beginning) (region-end))))
           (query (when region-text
                    (read-string "Prompt about this region: " file-prefix)))
           (initial-input (when region-text
                            (format "%s\n\n```\n%s\n```" query region-text)))
           (base-name (format "claude:tui-%s"
                              (file-name-nondirectory (directory-file-name default-directory))))
           (term-buffer-name (format "*%s*" base-name))
           (existing-buffer (get-buffer term-buffer-name)))
      (if (and existing-buffer
               (buffer-live-p existing-buffer)
               (get-buffer-process existing-buffer))
          ;; Reuse existing buffer — switch and send input
          (progn
            (pop-to-buffer existing-buffer)
            (when initial-input
              (let ((proc (get-buffer-process existing-buffer)))
                (term-send-string proc "\e[200~")
                (term-send-string proc initial-input)
                (term-send-string proc "\e[201~"))))
        ;; Kill stale buffer if process is dead
        (when (and existing-buffer (not (get-buffer-process existing-buffer)))
          (kill-buffer existing-buffer))
        ;; Create new session
        (let* ((resize-fn (make-symbol "emacs-solo--claude-tui-resize"))
               (proc-buffer (ansi-term emacs-solo-claude-executable base-name)))
          (fset resize-fn
                (lambda (frame)
                  (if (buffer-live-p proc-buffer)
                      (when-let* ((win (get-buffer-window proc-buffer frame)))
                        (with-current-buffer proc-buffer
                          (term-reset-size (window-body-height win)
                                           (window-body-width win))))
                    (remove-hook 'window-size-change-functions resize-fn))))
          (add-hook 'window-size-change-functions resize-fn)
          (with-current-buffer proc-buffer
            (pop-to-buffer proc-buffer)
            (when-let* ((win (get-buffer-window proc-buffer t)))
              (term-reset-size (window-body-height win) (window-body-width win))
              ;; HACK: makes claude aware of the real window width
              (run-at-time
               0.1 nil
               (lambda (w)
                 (when (window-live-p w)
                   (with-selected-window w
                     (shrink-window-horizontally 1)
                     (redisplay t)
                     (enlarge-window-horizontally 1)
                     (redisplay t))))
               win))
            (setq-local column-number-mode nil)
            (setq-local term-buffer-maximum-size 2048))
          (when initial-input
            (run-at-time 0.5 nil
                         (lambda (buf input)
                           (when (buffer-live-p buf)
                             (let ((proc (get-buffer-process buf)))
                               (when proc
                                 (term-send-string proc "\e[200~")
                                 (term-send-string proc input)
                                 (term-send-string proc "\e[201~")))))
                         proc-buffer initial-input))))))


  (defun emacs-solo/opencode-chat ()
    "Start or reuse an interactive `opencode-chat' session in an `ansi-term' buffer.

This provides interaction with opencode AI assistant, supporting task-based
model selection (general, explore, code-reviewer, etc.). If a region is
active, it prompts for a query and sends context with the query to opencode.
If an opencode buffer for the current project already exists with a live
process, it reuses it. Otherwise, a new session is started.

Keybindings are configured in `opencode/chat-model-suffix' for common
task types like 'general', 'explore', 'code-reviewer', 'fixer', 'planner',
and 'explainer'."
    (interactive)
    (let* ((source-file (buffer-file-name))
           (project-root (vc-root-dir))
           (default-directory (or project-root
                                  (and emacs-solo-ai-scratch-path
                                       (file-directory-p emacs-solo-ai-scratch-path)
                                       emacs-solo-ai-scratch-path)
                                  default-directory))
           (file-ref (when source-file
                       (if project-root
                           (file-relative-name source-file project-root)
                         source-file)))
           (file-prefix (when file-ref
                          (format "On file @%s " file-ref)))
           (region-text (when (use-region-p)
                          (buffer-substring-no-properties (region-beginning) (region-end))))
           (query (when region-text
                    (read-string "Prompt about this region: " file-prefix)))
           (initial-input (when region-text
                            (format "%s\n\n```\n%s\n```" query region-text)))
           (base-name (format "opencode:%s"
                              (file-name-nondirectory (directory-file-name default-directory))))
           (term-buffer-name (format "*%s*" base-name))
           (existing-buffer (get-buffer term-buffer-name)))
      (if (and existing-buffer
               (buffer-live-p existing-buffer)
               (get-buffer-process existing-buffer))
          ;; Reuse existing buffer — just switch and send input
          (progn
            (pop-to-buffer existing-buffer)
            (when initial-input
              (let ((proc (get-buffer-process existing-buffer)))
                (term-send-string proc "\e[200~")
                (term-send-string proc initial-input)
                (term-send-string proc "\e[201~"))))
        ;; Kill stale buffer if process is dead
        (when (and existing-buffer (not (get-buffer-process existing-buffer)))
          (kill-buffer existing-buffer))
        ;; Create new session
        (let* ((resize-fn (make-symbol "emacs-solo--opencode-resize"))
               (proc-buffer (ansi-term "opencode" base-name)))
          (fset resize-fn
                (lambda (frame)
                  (if (buffer-live-p proc-buffer)
                      (when-let* ((win (get-buffer-window proc-buffer frame)))
                        (with-current-buffer proc-buffer
                          (term-reset-size (window-body-height win)
                                           (window-body-width win))))
                    (remove-hook 'window-size-change-functions resize-fn))))
          (add-hook 'window-size-change-functions resize-fn)
          (with-current-buffer proc-buffer
            (pop-to-buffer proc-buffer)
            (when-let* ((win (get-buffer-window proc-buffer t)))
              (term-reset-size (window-body-height win) (window-body-width win))
              ;; HACK: makes opencode aware of the real window width
              (run-at-time
               0.1 nil
               (lambda (w)
                 (when (window-live-p w)
                   (with-selected-window w
                     (shrink-window-horizontally 1)
                     (redisplay t)
                     (enlarge-window-horizontally 1)
                     (redisplay t))))
               win))
            (setq-local column-number-mode nil)
            (setq-local term-buffer-maximum-size 2048)))))))

(provide 'emacs-solo-ai)
;;; emacs-solo-ai.el ends here
