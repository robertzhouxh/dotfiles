;;; package --- Summary
;;; Commentary:
;;; Code:

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;	Setup pkg repo and install use-package
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(require 'package)
(setq package-enable-at-startup nil)
;;(setq package-archives '(("gnu"   . "http://elpa.emacs-china.org/gnu/")
;;                         ("melpa" . "http://elpa.emacs-china.org/melpa/")
;;                         ("marmalade" . "http://marmalade-repo.org/packages/")))

(unless (assoc-default "melpa" package-archives)
  (add-to-list 'package-archives '("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/") t))
(unless (assoc-default "org" package-archives)
  (add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t))
(unless (assoc-default "marmalade" package-archives)
  (add-to-list 'package-archives '("gnu" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")))
(setq package-pinned-packages '((gtags . "marmalade")))
(package-initialize)

;;; auto install use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(setq use-package-verbose t)
(setq use-package-always-ensure t)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;	setup the load path
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(defvar vendor-dir (expand-file-name "vendor" user-emacs-directory))
(defvar lisp-dir (expand-file-name "lisp" user-emacs-directory))

(add-to-list 'load-path lisp-dir)
(add-to-list 'load-path vendor-dir)

(let ((files (directory-files-and-attributes vendor-dir t)))
  (dolist (file files)
    (let ((filename (car file))
          (dir (nth 1 file)))
      (when (and dir
                 (not (string-suffix-p "." filename)))
        (add-to-list 'load-path (car file))))))

(let ((default-directory "/usr/local/share/emacs/site-lisp/"))
  (normal-top-level-add-subdirs-to-load-path))

;; proxy?
;(setq url-proxy-services `(("http" . "127.0.0.1:8123")
;                           ("https" . "127.0.0.1:8123")))
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;	load my own configurations
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
(require 'init-bootstrap)
(require 'init-utils)
(require 'init-plantform)
(require 'init-pkgs)
(require 'init-evil)
(require 'init-org)
(require 'init-languages)
(require 'init-maps)

(provide 'init)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-names-vector
   ["#32302F" "#FB4934" "#B8BB26" "#FABD2F" "#83A598" "#D3869B" "#17CCD5" "#EBDBB2"])
 '(aw-keys (quote (106 107 108 105 111 104 121 117 112)) t)
 '(cider-repl-history-file "~/.emacs.d/cider-history")
 '(cider-repl-history-size 5000)
 '(cider-repl-pop-to-buffer-on-connect t)
 '(cider-repl-result-prefix "; => ")
 '(cider-repl-use-clojure-font-lock t)
 '(cider-repl-use-pretty-printing t)
 '(cider-repl-wrap-history t)
 '(cider-show-error-buffer nil)
 '(custom-safe-themes
   (quote
    ("4780d7ce6e5491e2c1190082f7fe0f812707fc77455616ab6f8b38e796cbffa9" "f0dc4ddca147f3c7b1c7397141b888562a48d9888f1595d69572db73be99a024" "9129c2759b8ba8e8396fe92535449de3e7ba61fd34569a488dd64e80f5041c9f" "97965ccdac20cae22c5658c282544892959dc541af3e9ef8857dbf22eb70e82b" "f8067b7d0dbffb29a79e0843797efabdf5e1cf326639874d8b407e9b034136a4" "f8fb7488faa7a70aee20b63560c36b3773bd0e4c56230a97297ad54ff8263930" "5057614f7e14de98bbc02200e2fe827ad897696bfd222d1bcab42ad8ff313e20" "4b19d61c560a93ef90767abe513c11f236caec2864617d718aa366618133704c" "801a567c87755fe65d0484cb2bded31a4c5bb24fd1fe0ed11e6c02254017acb2" "51043b04c31d7a62ae10466da95a37725638310a38c471cc2e9772891146ee52" "abdb1863bc138f43c29ddb84f614b14e3819982936c43b974224641b0b6b8ba4" "5b52a4d0d95032547f718e1574d3a096c6eaf56117e188945ae873bdb3200066" "bffa9739ce0752a37d9b1eee78fc00ba159748f50dc328af4be661484848e476" "dbade2e946597b9cda3e61978b5fcc14fa3afa2d3c4391d477bdaeff8f5638c5" "341b2570a9bbfc1817074e3fad96a7eff06a75d8e2362c76a2c348d0e0877f31" "3e335d794ed3030fefd0dbd7ff2d3555e29481fe4bbb0106ea11c660d6001767" "1b6f7535c9526a5dbf9fb7e3604d0280feb7a07b970caf21ebd276ddc93ef07a" "cc0dbb53a10215b696d391a90de635ba1699072745bf653b53774706999208e3" "30289fa8d502f71a392f40a0941a83842152a68c54ad69e0638ef52f04777a4c" "fd944f09d4d0c4d4a3c82bd7b3360f17e3ada8adf29f28199d09308ba01cc092" "f07729f5245b3c8b3c9bd1780cbe6f3028a9e1ed45cad7a15dd1a7323492b717" "8aca557e9a17174d8f847fb02870cb2bb67f3b6e808e46c0e54a44e3e18e1020" "cd736a63aa586be066d5a1f0e51179239fe70e16a9f18991f6f5d99732cabb32" "49ec957b508c7d64708b40b0273697a84d3fee4f15dd9fc4a9588016adee3dad" "43c808b039893c885bdeec885b4f7572141bd9392da7f0bd8d8346e02b2ec8da" "a3fa4abaf08cc169b61dea8f6df1bbe4123ec1d2afeb01c17e11fdc31fc66379" "4697a2d4afca3f5ed4fdf5f715e36a6cac5c6154e105f3596b44a4874ae52c45" "6d589ac0e52375d311afaa745205abb6ccb3b21f6ba037104d71111e7e76a3fc" "10461a3c8ca61c52dfbbdedd974319b7f7fd720b091996481c8fb1dded6c6116" "100e7c5956d7bb3fd0eebff57fde6de8f3b9fafa056a2519f169f85199cc1c96" "88049c35e4a6cedd4437ff6b093230b687d8a1fb65408ef17bfcf9b7338734f6" "6b2636879127bf6124ce541b1b2824800afc49c6ccd65439d6eb987dbf200c36" "9f08dacc5b23d5eaec9cccb6b3d342bd4fdb05faf144bdcd9c4b5859ac173538" "36c2b7efdc064944eb067e56c7ec65808a6cee0f63ce068b693fb30b110e57e5" "d3e333eaa461c82a124f7e7a7a9637d56fc3019478becb1847952804ca67743e" "f153e8ed90e4d79cf2c61560da2b3091d2f3b94da42aaddc707012be4608cf52" "291588d57d863d0394a0d207647d9f24d1a8083bb0c9e8808280b46996f3eb83" "b9cbfb43711effa2e0a7fbc99d5e7522d8d8c1c151a3194a4b176ec17c9a8215" "30f7c9e85d7fad93cf4b5a97c319f612754374f134f8202d1c74b0c58404b8df" "98cc377af705c0f2133bb6d340bf0becd08944a588804ee655809da5d8140de6" "12ae26f3493216be1bc0bbd28732671e8672bc3c631f1cea042a1040b136058a" "a4c9e536d86666d4494ef7f43c84807162d9bd29b0dfd39bdf2c3d845dcc7b2e" "3629b62a41f2e5f84006ff14a2247e679745896b5eaa1d5bcfbc904a3441b0cd" "8aebf25556399b58091e533e455dd50a6a9cba958cc4ebb0aab175863c25b9a4" default)))
 '(doom-themes-enable-bold t)
 '(doom-themes-enable-italic t)
 '(package-selected-packages
   (quote
    (em-unix em-term highlight-indentation dockerfile-mode docker geiser racket-mode ansible markdown-mode web-mode js2-mode go-eldoc company-go paredit color-identifiers-mode ac-slime slime lua-mode bpr yasnippet yaml-mode wsd-mode which-key use-package uimage rainbow-mode rainbow-delimiters ox-ioslide org-page org-evil org-bullets multiple-cursors magit json-reformat hippie-exp-ext highlight-symbol helm-projectile helm-descbinds helm-ag git-gutter flycheck exec-path-from-shell evil-surround evil-leader evil-indent-textobject dired-k diminish company comment-dwim-2 ag)))
 '(pdf-view-midnight-colors (quote ("#FDF4C1" . "#282828")))
 '(pos-tip-background-color "#36473A")
 '(pos-tip-foreground-color "#FFFFC8")
 '(safe-local-variable-values
   (quote
    ((eval setq inferior-erlang-machine-options
	   (let*
	       ((d
		 (dir-locals-find-file "."))
		(p
		 (file-name-directory
		  (if
		      (stringp d)
		      d
		    (car d)))))
	     (list "-pa"
		   (expand-file-name "ebin" p)
		   "-env" "ERL_LIBS"
		   (expand-file-name "lib" p))))))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(aw-leading-char-face ((t (:height 4.0 :foreground "#f1fa8c"))))
 '(company-preview ((t (:foreground "darkgray" :underline t))))
 '(company-preview-common ((t (:inherit company-preview))))
 '(company-tooltip ((t (:background "lightgray" :foreground "black"))))
 '(company-tooltip-common ((((type x)) (:inherit company-tooltip :weight bold)) (t (:inherit company-tooltip))))
 '(company-tooltip-common-selection ((((type x)) (:inherit company-tooltip-selection :weight bold)) (t (:inherit company-tooltip-selection))))
 '(company-tooltip-selection ((t (:background "steelblue" :foreground "white"))))
 '(doom-modeline-bar ((t (:background "#6272a4"))))
 '(symbol-overlay-default-face ((t (:inherit (quote region)))))
 '(symbol-overlay-face-1 ((t (:inherit (quote highlight)))))
 '(symbol-overlay-face-2 ((t (:inherit (quote font-lock-builtin-face) :inverse-video t))))
 '(symbol-overlay-face-3 ((t (:inherit (quote warning) :inverse-video t))))
 '(symbol-overlay-face-4 ((t (:inherit (quote font-lock-constant-face) :inverse-video t))))
 '(symbol-overlay-face-5 ((t (:inherit (quote error) :inverse-video t))))
 '(symbol-overlay-face-6 ((t (:inherit (quote dired-mark) :inverse-video t :bold nil))))
 '(symbol-overlay-face-7 ((t (:inherit (quote success) :inverse-video t))))
 '(symbol-overlay-face-8 ((t (:inherit (quote dired-symlink) :inverse-video t :bold nil)))))

(provide 'dired+)
