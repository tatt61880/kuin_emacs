# kuin_emacs
Emacs setting files for Kuin

#### kuin-mode.el を.emacsのload-pathで指定されたフォルダに置いてください。
#### .emacsの適切な場所に下記の5行を追加してください。
```
; Settings for Kuin
(autoload 'kuin-mode "kuin-mode" nil t)
(add-hook 'kuin-mode-hook '(lambda () (font-lock-mode 1)))
(setq auto-mode-alist
    (cons (cons "\\.kn$" 'kuin-mode) auto-mode-alist))
```
