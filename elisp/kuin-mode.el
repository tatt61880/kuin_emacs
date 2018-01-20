;;; kuin-mode.el
;;  Maintainer:    @tatt61880
;;  Last Modified: 2018/01/20 23:24:45.
;;
;;; How to use
;;  1. Put this file (kuin-mode.el) into emacs setting folder.
;;  2. Add next 5 lines into .emacs
;;    ; Settings for Kuin
;;    (autoload 'kuin-mode "kuin-mode" nil t)
;;    (add-hook 'kuin-mode-hook '(lambda () (font-lock-mode 1)))
;;    (setq auto-mode-alist
;;    (cons (cons "\\.kn$" 'kuin-mode) auto-mode-alist))
;;

(defvar kuin-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_  "w"    table)
    (modify-syntax-entry ?{  "<" table)
    (modify-syntax-entry ?}  ">" table)
    table)
  "Syntax table used in kuin-mode buffers.")

(defvar kuin-font-lock-defaults
  (list
    'kuin-font-lock-keywords
    nil ; keywords-only = nil
    nil ; case-fold = nil i.e. case-sensitiveh
    nil ; syntax-alist
    'beginning-of-line
    ))

(defconst kuin-font-lock-keywords
          '(
            ("\\<end \\(block\\|class\\|enum\\|for\\|func\\|if\\|switch\\|try\\|while\\)\\>" (0 font-lock-string-face)) ; for yasnippet (yasnippet neglects string-face, fortunately.)

            ("\\<\\w+#\\w*[a-z_]\\w*\\>"             (0 font-lock-warning-face))    ; " a-z _ contained post # => Warning
            ("\\<2#[0-1]+\\>"                        (0 font-lock-constant-face))
            ("\\<8#[0-7]+\\>"                        (0 font-lock-constant-face))
            ("\\<16#[0-9A-F]+\\>"                    (0 font-lock-constant-face))
            ("\\<[0-9]+#[0-9A-Z]+\\>"                (0 font-lock-warning-face))    ; e.g. 100#1, 3#3 => Warning
            ("\\<[1-9][0-9]*\\(\\.[0-9]+\\)?\\>"     (0 font-lock-constant-face))
            ("\\<0\\(\\.[0-9]+\\)?\\>"               (0 font-lock-constant-face))
            ("\\<[0-9]\\w*\\>"                       (0 font-lock-warning-face))

            ("\\<include\\>" (0 font-lock-keyword-face))
            ("\\<const\\>" (0 font-lock-keyword-face))
            ("\\<\\(class\\|enum\\|alias\\)\\>" (0 font-lock-keyword-face))
            ("\\<\\(int\\|float\\|char\\|bool\\|list\\|stack\\|queue\\|dict\\)\\>" (0 font-lock-type-face))
            ("\\<\\(bit8\\|bit16\\|bit32\\|bit64\\)\\>" (0 font-lock-type-face))
            ("\\<func\\>" (0 font-lock-function-name-face))
            ("\\<\\(skip\\|block\\|end\\|var\\|do\\|break\\|ret\\|assert\\|dbg\\)\\>" (0 font-lock-keyword-face))

            ("\\<\\(case\\|default\\)\\>"                   (0 font-lock-keyword-face))
            ("\\<\\(if\\|else\\|elif\\|switch\\)\\>"        (0 font-lock-keyword-face))
            ("\\<\\(while\\|for\\)\\>"                      (0 font-lock-keyword-face))
            ("\\<\\(throw\\|try\\|catch\\|finally\\)\\>"    (0 font-lock-keyword-face))
            ("\\<\\(true\\|false\\)\\>"                     (0 font-lock-constant-face))
            ("\\<\\(null\\|inf\\)\\>"                 (0 font-lock-constant-face))

            ("'''"          (0 font-lock-warning-face))
            ("'[\n\r\t]+'"  (0 font-lock-warning-face))
            ("'\\\\.'"      (0 font-lock-constant-face)); char '\.'
            ("'[^\\s\\\\]'" (0 font-lock-constant-face)); char '.'
            ("\"[^\"]*\""   (0 font-lock-string-face))  ; FIXME for "__\"__"

            ("!="   (0 font-lock-warning-face))
            ("==+"  (0 font-lock-warning-face))

            ("="    (0 font-lock-keyword-face))
            ("<>"   (0 font-lock-keyword-face))
            ("<="   (0 font-lock-keyword-face))
            ("<"    (0 font-lock-keyword-face))
            (">="   (0 font-lock-keyword-face))
            (">"    (0 font-lock-keyword-face))
            )
          "Additional expressions to highlight in Kuin mode.")

;====================================

(defcustom kuin-indent 4
           "Number of columns for a unit of indentation in Kuin mode."
           :type 'integer
           :group 'kuin)

(put 'kuin-indent 'safe-local-variable 'integerp)

(defvar kuin-indent-index 0 "Internal use.")
(defvar kuin-current-column 0 "Internal use.")
(defvar kuin-current-column-from-right 0 "Internal use.")

(defun kuin-indent-line ()
  "Indent current line as Kuin code."
  (save-excursion
    (while (progn ; move to non-blank
             (not (or (equal (forward-line -1) -1)
                      (not (looking-at "^\s*$"))
                      ))))
    (if (string= "font-lock-comment-face" (get-char-property (point) 'face))
      ()
      (if (string-match "^\s*\\<\\(func\\|class\\|enum\\|if\\|elif\\|else\\|switch\\|case\\|default\\|while\\|for\\|try\\|catch\\|finally\\|block\\)\\>"
                        (buffer-substring-no-properties (point-at-bol) (point-at-eol)))
        ; Indent (current-indent > prev-line-indent)
        (setq kuin-indent-index (+ (current-indentation) kuin-indent))
        ; current-indent = prev-line-indent
        (setq kuin-indent-index (current-indentation))
        )))
  (save-excursion
    (beginning-of-line)
    (if (string= "font-lock-comment-face" (get-char-property (point) 'face))
      ()
      (if (string-match "^\s*\\<\\(end\\|elif\\|else\\|case\\|default\\|catch\\|finally\\)\\>" (buffer-substring-no-properties (point-at-bol) (point-at-eol)))
        ; Unindent (current-indent < prev-line-indent)
        (setq kuin-indent-index (- kuin-indent-index kuin-indent))
        )))

  (save-excursion ; first-line-indent = 0
    (beginning-of-line)
    (if (equal (forward-line -1) -1)
      (setq kuin-indent-index 0)
      ))

  (save-excursion
    (beginning-of-line)
    (re-search-forward "[\s\t]*")
    (replace-match "")
    )

  (setq kuin-current-column (current-column))
  (end-of-line)
  (setq kuin-current-column-from-right (- (current-column) kuin-current-column))

  (beginning-of-line)
  (indent-to kuin-indent-index)

  (end-of-line)
  (move-to-column (- (current-column) kuin-current-column-from-right))
  )

(add-hook 'kuin-mode-hook
          '(lambda ()
             (setq indent-tabs-mode nil)
             ))

(define-derived-mode kuin-mode fundamental-mode "Kuin"
                     "Major mode for Kuin."
                     (set-syntax-table kuin-mode-syntax-table)
                     (setq mode-name "Kuin")
                     (setq case-fold-search nil)
                     (set (make-local-variable 'adaptive-fill-mode) nil)
                     (set (make-local-variable 'indent-line-function) #'kuin-indent-line)
                     (define-key kuin-mode-map "\C-m" 'reindent-then-newline-and-indent)
                     (set (make-local-variable 'font-lock-defaults) kuin-font-lock-defaults )
                     (set (make-local-variable 'parse-sexp-ignore-comments) nil)
                     (setq yas/buffer-local-condition
                           '(or (not (memq (get-text-property (1- (point)) 'face)
                                           '(font-lock-comment-face font-lock-doc-face font-lock-string-face)))
                                '(require-snippet-condition . force-in-comment))) ; for yasnippet
                     (run-hooks 'kuin-mode-hook)
                     )

(provide 'kuin-mode)

;; kuin-mode.el EOF
