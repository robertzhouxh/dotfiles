;;; emacs-init-font.el --- 字体配置 -*- lexical-binding: t; -*-

(require 'emacs-init-path)

;; ---- 字体 ----
(defun my/available-font (font-list)
  "从 FONT-LIST 中获取第一个可用字体。"
  (catch 'font
    (dolist (font font-list)
      (when (member font (font-family-list))
        (throw 'font font)))))

(setq my/ef (my/available-font '("Sarasa Mono SC"
                                  "JetBrainsMono Nerd Font"
                                  "JetBrainsMono"
                                  "Monaco"
                                  "Iosevka Comfy"
                                  "Cascadia Code")))

(setq my/cf (my/available-font '("Sarasa Mono SC"
                                  "等距更纱黑体 SC"
                                  "LXGW WenKai Mono"
                                  "Microsoft YaHei Mono")))

(defun my/load-font-setup ()
  "设置中英文字体。"
  (when my-graphic-p
    (let ((english-font (or my/ef "Monaco"))
          (chinese-font (or my/cf "PingFang SC"))
          (font-size 180))
      (set-face-attribute 'default nil :family english-font :height font-size)
      (dolist (charset '(kana han symbol cjk-misc bopomofo))
        (set-fontset-font (frame-parameter nil 'font) charset
                          (font-spec :family chinese-font :height font-size))))))

(add-hook 'after-init-hook 'my/load-font-setup)

;; ---- macOS Emoji 字体 ----
(when my-sys-mac-p
  (set-fontset-font t 'emoji '("Apple Color Emoji" . "iso10646-1") nil 'prepend))

(provide 'emacs-init-font)
;;; init-font.el ends here
