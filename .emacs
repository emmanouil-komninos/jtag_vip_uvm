;; GNU Emacs 23.2.1 (x86_64-redhat-linux-gnu, GTK+ Version 2.10.4) of 2010-09-21 on centos5-64


;; (setq load-path (cons (expand-file-name "~/el") load-path)) 
(setq load-path (cons (expand-file-name "/home/emmkom/.emacs.d") load-path))
(push (expand-file-name "/home/emmkom/.emacs.d") load-path)

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(case-fold-search t)
 '(cua-mode t nil (cua-base))
 '(current-language-environment "Latin-1")
 '(default-input-method "latin-1-prefix")
 '(global-font-lock-mode t nil (font-lock))
 '(inhibit-startup-screen t)
 '(load-home-init-file t t)
 '(mouse-wheel-mode t nil (mwheel))
 '(save-abbrevs (quote silently))
 '(set-fill-column 80)
 '(show-paren-mode t)
 '(specman-auto-endcomments t)
 '(specman-auto-newline t)
 '(specman-max-line-length 80)
 '(tool-bar-mode nil)
 '(tooltip-mode nil)
 '(truncate-lines nil)
 '(visible-bell t)
 '(whitespace-style (quote (trailing tabs tab-mark spaces trailing lines space-before-tab newline indentation empty space-after-tab space-mark tab-mark newline-mark))))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "dark slate gray" :foreground "wheat" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 98 :width normal :foundry "unknown" :family "DejaVu LGC Sans"))))
 '(whitespace-tab ((((class color) (background dark)) (:background "grey22" :foreground "aquamarine3" :inverse-video t)))))

(global-set-key "\M-g" 'goto-line)
(define-key global-map [f1] 'linum-mode)
(define-key global-map [f2] 'shell)

(define-key function-key-map [delete] [F20]) 
(global-set-key [F20] 'delete-char)

;Enable cua mode
;(cua-mode t)
(cua-selection-mode t)

(c-add-style "teklatechcodingstyle" 
         '((c-basic-offset . 2) 
           (c-comment-only-line-offset . 0) 
           (c-hanging-braces-alist . ((substatement-open before after))) 
	   (c-doc-comment-style . (doxygen))
           (c-offsets-alist . ((topmost-intro        . 0) 
                   (topmost-intro-cont   . 0) 
                   (substatement         . 2) 
                   (substatement-open    . 0) 
                   (statement-case-open  . 2) 
                   (statement-cont       . 2) 
                   (access-label         . 0) 
                   (inclass              . 2) 
                   (inline-open          . 2) 
                   (innamespace          . 0) 
                   )))) 

;; treat all tabs to spaces 
(defun my-c-mode-hook () 
  (setq c-basic-offset 2) 
  (setq indent-tabs-mode nil) 
  (setq show-trailing-whitespace t)) 
;; c++ uses mycodingstyle 
(defun my-c++-mode-hook () 
  (c-set-style "teklatechcodingstyle")) 


; c/c++ mode 
(add-hook 'c-mode-common-hook 
          '(lambda() 
             (c-set-style "teklatechcodingstyle") 
             (setq tab-width 2) 
	     (setq indent-tabs-mode nil) 
             (setq c-basic-offset tab-width))) 


(add-hook 'tcl-mode-hook
  (lambda ()
    (tcl-auto-fill-mode t)
    (setq tab-width 1) 
    (setq indent-tabs-mode nil)
    (setq tcl-electric-hash-style nil)
    (local-set-key [return] 'newline-and-indent)
  )
)

;; titlebar = buffer unless filename
(setq frame-title-format '(buffer-name "%f" ("%b")))

(setq tab-width 2) 
(setq-default indent-tabs-mode nil)

; verilog mode
(defun prepend-path ( my-path )
(setq load-path (cons (expand-file-name my-path) load-path)))
	  
(defun append-path ( my-path )
(setq load-path (append load-path (list (expand-file-name my-path)))))
;; Look first in the directory ~/elisp for elisp files
(prepend-path "~/.elisp")
;; Load verilog mode only when needed
(autoload 'verilog-mode "verilog-mode" "Verilog mode" t )
;; Any files that end in .v, .dv or .sv should be in verilog mode
(add-to-list 'auto-mode-alist '("\\.[ds]?v\\'" . verilog-mode))
;; Any files in verilog mode should have their keywords colorized
(add-hook 'verilog-mode-hook '(lambda () (font-lock-mode 1)))

(setq verilog-mode-hook '(lambda ()
                           ;; User specifications
                           (setq verilog-indent-level             2
                                 verilog-indent-level-module      2
                                 verilog-indent-level-declaration 2
                                 verilog-indent-level-behavioral  2
                                 verilog-indent-level-directive   1
                                 verilog-case-indent              2
                                 verilog-auto-newline             t
                                 verilog-auto-indent-on-newline   t
                                 verilog-tab-always-indent        t
                                 verilog-auto-endcomments         t
                                 verilog-minimum-comment-distance 120
                                 verilog-indent-begin-after-if    t
                                 verilog-auto-lineup              'declarations
                                 verilog-highlight-p1800-keywords nil)))

; Auto decide on c or c++ header
(defun c-c++-header ()
  "sets either c-mode or c++-mode, whichever is appropriate for
header"
  (interactive)
  (let ((c-file (concat (substring (buffer-file-name) 0 -1) "c")))
    (if (file-exists-p c-file)
        (c-mode)
      (c++-mode))))
(add-to-list 'auto-mode-alist '("\\.h\\'" . c-c++-header))



(defadvice c-lineup-C-comments (before c-lineup-C-comments-handle-doxygen activate)
  (let ((langelm (ad-get-arg 0)))
    (save-excursion
      (save-match-data 
        (goto-char (1+ (c-langelem-pos langelem)))
        (if (progn
              (beginning-of-line)
              ;; only when the langelm is of form (c . something)
              ;; and we're at a doxygen comment line
              (and (eq 'c (car langelm))
                   (looking-at "^\\(\\s-*\\)/\\*+//\\*\\*$")))
            ;; set the goal position to what we want
            (ad-set-arg 0 (cons 'c (match-end 1))))))))



(defun minibufferp (&optional buf) 
  "return t if buffer is a minibuffer."
  (if (string-match "^ \\*Minibuf-[0-9]+\\*$"
      (if (stringp buf)
          buf
        (buffer-name buf)))
  t)  
)


;; (require 'ido)
;; (ido-mode t)
;; (setq ido-enable-flex-matching t)
;; (setq ido-auto-merge-work-directories-length -1)

;; (global-set-key [(tab)] 'krisb-tab)
;; (defun krisb-tab ()
;;   "This krisb tab is minibuffer compliant: it acts as usual in
;; the minibuffer. Else, if mark is active, indents region. Else indents the
;; current line."
;;   (interactive)
;;   (if (minibufferp)
;;       (unless (minibuffer-complete)
;;         (dabbrev-expand nil)
;;         )
;;     (if mark-active
;;         (indent-region (region-beginning) (region-end) nil)
;;       (indent-for-tab-command)
;;       )
;;     )
;;   )

(autoload 'specman-mode "specman-mode" "Specman code editing mode" t)
(push '("\\.e\\'" . specman-mode) auto-mode-alist)
(push '("\\.e3\\'" . specman-mode) auto-mode-alist)
(push '("\\.ecom\\'" . specman-mode) auto-mode-alist)
(push '("\\.load\\'" . specman-mode) auto-mode-alist)
(push '("\\.erld\\'" . specman-mode) auto-mode-alist)
(push '("\\.etst\\'" . specman-mode) auto-mode-alist)
