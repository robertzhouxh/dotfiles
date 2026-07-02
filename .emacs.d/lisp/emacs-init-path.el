;;; init-path.el --- 路径常量 -*- lexical-binding: t; -*-

(defconst my-emacs-dir (file-name-as-directory
                         (file-truename user-emacs-directory))
  "Emacs 配置目录（跟随符号链接）。")

(defconst my-cache-dir (expand-file-name "var/" my-emacs-dir)
  "Emacs 运行时缓存目录。")

(defconst my-packages-dir (expand-file-name "packages/" my-cache-dir)
  "包安装目录。")

(defconst my-sys-mac-p (eq system-type 'darwin)
  "是否运行在 macOS。")

(defconst my-sys-linux-p (eq system-type 'gnu/linux)
  "是否运行在 GNU/Linux。")

(defconst my-graphic-p (display-graphic-p)
  "是否为图形界面。")

;; Rime 用户数据目录
(defvar my-rime-user-data-dir
  (cond
   (my-sys-mac-p (concat (getenv "HOME") "/Library/Rime"))
   (my-sys-linux-p (concat (getenv "HOME") "/.config/fcitx/rime/")))
  "Rime 输入法用户数据目录。")

;; PlantUML
(defvar my-plantuml-jar-path
  (cond
   (my-sys-mac-p "/opt/homebrew/Cellar/plantuml/1.2025.7/libexec/plantuml.jar")
   (my-sys-linux-p "/opt/plantuml/plantuml.jar"))
  "PlantUML JAR 文件路径。")

(defvar my-module-header-root
  (cond
   (my-sys-mac-p "/opt/homebrew/include/")
   (my-sys-linux-p "/usr/local/include"))
  "C 模块头文件根目录。")

(setenv "EMACS_MODULE_HEADER_ROOT" my-module-header-root)

(provide 'emacs-init-path)
;;; init-path.el ends here
