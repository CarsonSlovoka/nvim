;;; elisp-indent.el --- Indent Emacs Lisp from stdin -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'elisp-mode)

(let ((coding-system-for-read 'utf-8-unix)
      (coding-system-for-write 'utf-8-unix))
  (condition-case err
      (with-temp-buffer
        ;; 從 equalprg 的 stdin 讀取內容
        (insert-file-contents "/dev/stdin")

        (emacs-lisp-mode)

        (setq-local indent-tabs-mode nil)

        ;; indent-region 會輸出：
        ;;   Indenting region...
        ;;   Indenting region...done
        ;;
        ;; equalprg 的 stdout 必須保持乾淨，因此暫時封鎖 message
        (let ((inhibit-message t)
              (message-log-max nil))
          (cl-letf (((symbol-function 'message)
                     (lambda (&rest _args) nil)))
            (indent-region (point-min) (point-max))))

        ;; 唯一允許輸出到 stdout 的內容
        (princ
         (buffer-substring-no-properties
          (point-min)
          (point-max))))

    (error
     ;; 錯誤寫到 stderr，不要污染 Neovim buffer
     (princ
      (format "elisp-indent: %s\n"
              (error-message-string err))
      #'external-debugging-output)
     (kill-emacs 1))))
