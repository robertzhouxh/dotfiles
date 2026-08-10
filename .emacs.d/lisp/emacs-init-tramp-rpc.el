;;; emacs-init-tramp-rpc.el --- TRAMP-RPC integration -*- lexical-binding: t; -*-

;; Use the high-performance RPC backend only for explicit /rpc: paths; the
;; built-in /ssh: backend and its default remain unchanged.
(use-package tramp-rpc
  :after tramp
  :vc (:url "https://github.com/ArthurHeymans/emacs-tramp-rpc"
       :rev :newest
       :lisp-dir "lisp"))

(provide 'emacs-init-tramp-rpc)
;;; emacs-init-tramp-rpc.el ends here
