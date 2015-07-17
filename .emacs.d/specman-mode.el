;; @(#) specman-mode.el -- Mode for editing specman files
;; @(#) $Id: specman-mode.el,v 1.23 2013/05/23 07:03:00 pouyet Exp $
;; @(#) $Keywords: tools $
;; $KnownCompatibility: 24.3 $

;; This file is not part of Emacs


;; Copyright (C) 2013 Cadence Design Systems, Inc.
;; Authors:      Uri Maoz <urim@cadence.com>
;;               Michael McNamara <mac@cadence.com>
;;               Yaron Peri <yperi@cadence.com>
;; Maintainer:   
;; Created:      May 25 2013


;; LCD Archive Entry:
;; specman-mode|Michael McNamara|mac@verisity.com|
;; Specman Major mode. auto indents, colorizes, code in the 'e language|
;; 25-May-2013|$Revision: 1.23 $|~/misc/specman-mode.el.Z|

;; COPYRIGHT NOTICE
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with GNU Emacs.  If you did not, write to the Free Software Foundation,
;; Inc., 675 Mass Ave., Cambridge, MA 02139, USA.

;;
;; =============================================================================
;; SPECMAN MODE - A Major mode for writing in 'e'
;; =============================================================================
;;

;; ....................................................... &t-install ...
;; Put this file on your Emacs-Lisp load path, add following into your
;; ~/.emacs startup file
;;
;;   (require 'specman-mode)
;;
;; Or add the following code to your .emacs:
;;  
;; (autoload 'specman-mode "specman-mode" "Specman code editing mode" t) 
;;
;; (setq auto-mode-alist 
;;       (remove-duplicates
;;        (append (list 
;;                 (cons "\\.e\\'" 'specman-mode)
;;                 (cons "\\.ecom\\'" 'specman-mode)
;;                 (cons "\\.erld\\'" 'specman-mode))
;;                auto-mode-alist)))
;; 
;;
;;; Commetary:
;;
;;  specman-mode is a major mode for editing code written in the 'e' language
;;
(require 'cl)

(defconst specman-mode-version "$$Revision: 1.23 $$"
  "Version of this Specman mode.")

(defun specman-version ()
  "Inform caller of the version of this file"
  (interactive)
  (message (concat "Using specman-mode version " 
		   (substring specman-mode-version 12 -3 )) )
  )

(autoload 'specman-mode "specman-mode" "Specman code editing mode" t) 

(setq auto-mode-alist 
      (remove-duplicates
       (append (list 
                (cons "\\.e\\'" 'specman-mode)
                (cons "\\.ecom\\'" 'specman-mode)
                (cons "\\.erld\\'" 'specman-mode))
               auto-mode-alist)))

(add-hook 'specman-mode-hook
	  (lambda ()
            (turn-on-font-lock)
	    (setq indent-tabs-mode nil)
	    (setq write-file-hooks nil)))

(add-hook 'speedbar-load-hook
          (lambda ()
            (speedbar-add-supported-extension ".e")))

(defmacro specman-safe (&rest body)
  "Safely execute BODY, return nil if an error occurred."
  `(condition-case nil
       (progn ,@body)
     (error nil)))

(if (fboundp 'eval-when-compile)
    (eval-when-compile
      (condition-case nil
          (require 'cl)	;; FSF emacs's imenu needs cl, but doesn't (require 'cl)
        (error nil))
      (condition-case nil
          (require 'imenu)
        (error nil))
      (condition-case nil
	  (unless (fboundp 'imenu-add-to-menubar)
	    (defun imenu-add-to-menubar (a) ))
	(error nil))
      (condition-case nil
	  (require 'reporter)
        (error nil))
      (condition-case nil
	  (if (boundp 'current-menubar)
	      nil ;; great
	    (defmacro set-buffer-menubar (&rest args) nil)
	    (defmacro add-submenu (&rest args) nil))
	(error nil))
      (condition-case nil
	  (require 'func-menu)
	(error nil))
      (condition-case nil
	  (unless (fboundp 'char=)
	    (defun char= (a b)
	      (= a b)))
	(error nil))
      (if (and (featurep 'custom) (fboundp 'custom-declare-variable))
	  nil ;; We've got what we needed
	;; We have the old custom-library, hack around it!
	(defmacro defgroup (&rest args)  nil)
	(defmacro customize (&rest args)
	  (message "Sorry, Customize is not available with this version of emacs"))
	(defmacro defcustom (var value doc &rest args)
	  `(defvar ,var ,value , doc))
	)
      (if (fboundp 'defface)
	  nil ;; great!
	(defmacro defface (var value doc &rest args)
	  `(make-face ,var))
	)
      (if (and (featurep 'custom) (fboundp 'customize-group))
	  nil ;; We've got what we needed
	;; We have an intermediate custom-library, hack around it!
	(defmacro customize-group (var &rest args)
	  `(customize ,var) )
	)
      (if (and (featurep 'custom) (fboundp 'custom-declare-variable))
	  nil ;; We've got what we needed
	;; We have the old custom-library, hack around it!
	(defmacro defgroup (&rest args)  nil)
	(defmacro customize (&rest args)
	  (message "Sorry, Customize is not available with this version of emacs"))
	(defmacro defcustom (var value doc &rest args)
	  `(defvar ,var ,value ,doc))
	)
      
      (if (and (featurep 'custom) (fboundp 'customize-group))
	  nil ;; We've got what we needed
	;; We have an intermediate custom-library, hack around it!
	(defmacro customize-group (var &rest args)
	  `(customize ,var))
	)
      (condition-case nil
          (require 'easymenu)
        (error nil))))

;; If you install xemacs-devel, you will get a 10-20% speedup.
;; if not, you get this:
(unless (fboundp 'regexp-opt)
  (defun regexp-opt (strings &optional paren)
    (let ((open (if paren "\\(" ""))
          (close (if paren "\\)" ""))
          )
      (concat open (mapconcat 'regexp-quote strings "\\|") close))))

;; TODO: this is also defined above, not sure why
(unless (fboundp 'char=)
  (defun char= (a b)
    (= a b)))

(if (not (boundp 'imenu-generic-expression))
    (defvar imenu-generic-expression))

(unless (boundp 'font-lock-constant-face)
  (make-face 'font-lock-constant-face)
  (set-face-foreground 'font-lock-constant-face "CadetBlue"))

(if (< max-specpdl-size 3000) 
    (setq max-specpdl-size 3000))


;; =================================================
;; SPECMAN CUSTOMIZABLE VARS
;; =================================================
;;; - Customizable variables

(defgroup specman-mode nil
  "Facilitates easy editing of Specman source text"
  :group 'languages
  )

(defcustom specman-basic-offset 3
  "*Indentation of Specman statements with respect to containing block."
  :group 'specman-mode
  :type 'integer
  )

(defconst specman-tab-width specman-basic-offset
  "*Tab stop width"
  )

(defcustom specman-continued-line-offset 2
  "*Indentation of continued Specman statements with respect to first line of statement."
  :group 'specman-mode
  :type 'integer
  )

(defcustom specman-auto-newline nil
  "*ON (or non nil) means to automatically newline after inserting a semicolon."
  :group 'specman-mode
  :type 'boolean
  )

(defcustom specman-auto-endcomments nil
  "*ON (or non nil) means to automatically add a comment when closing a code block."
  :group 'specman-mode
  :type 'boolean
  )

(defcustom specman-auto-endcomments-for-major-scopes-only t
  "*ON (or non nil) means that end-comments are only applied to struct and method scopes."
  :group 'specman-mode
  :type 'boolean
  )

(defcustom specman-auto-endcomments-kill-existing-comment t
  "*ON (or non nil) means that redoing an end-comment replaces an existing end-comment."
  :group 'specman-mode
  :type 'boolean
  )

(defcustom specman-max-line-length 150
  "*The maximum number of characters that should be in a line."
  :group 'specman-mode
  :type 'integer
  )

(defcustom specman-highlight-beyond-max-line-length t
  "*ON (or non nil) means to highlight text beyond specman-max-line-length."
  :group 'specman-mode
  :type 'boolean
  )

(defface specman-highlight-beyond-max-line-length-face
  '((t (:underline t)))
  "Face used to highlight text beyond the defined maximum line length."
  :group 'specman-mode
  )

(defcustom specman-highlight-punctuation t
  "*ON (or non nil) means to highlight punctuation symbols."
  :group 'specman-mode
  :type 'boolean
  )

(defface specman-punctuation-face
  '((t (:foreground "SteelBlue")))
  "Face used to highlight punctuation symbols - significant because they are mostly a single char."
  :group 'specman-mode
  )

(defcustom specman-compile-command "${SPECMAN_HOME}/bin/sn_compile.sh "
  "String used to compile e files."
  :group 'specman-mode
  )

(defcustom specman-make-command "/usr/bin/make "
  "String used to invoke make"
  :group 'specman-mode
  )

(defcustom specman-index-menu-active t
  "*ON (or non nil) means that the 'Specman-Index' menu is active."
  :group 'specman-mode
  :type 'boolean
  )

(defcustom specman-date-scientific-format nil
  "*If non-nil, dates are written in scientific format (e.g. 1997/09/17),
in european format otherwise (e.g. 17.09.1997). The braindead american
format (e.g. 09/17/1997) is not supported."
  :group 'specman-mode
  :type 'boolean
  )

(defcustom specman-company "ACME Company"
  "*Default name of Company for specman header. If set will become buffer local. "
  :group 'specman-mode
  :type 'string  
  )

(defcustom specman-project "Roadrunner"
  "*Default name of Project for specman header. If set will become buffer local."
  :group 'specman-mode
  :type 'string  
  )


;; =================================================
;; SPECMAN REGULAR EXPRESSIONS
;; =================================================

(defconst specman-ex-code-regexp "^\\(?:\\('>\\)\\|\\(<'\\)\\)" 
  "Regular Expression that matches ex-code tokens")

;; Matthew Lovell <lovell@fc.hp.com>
;;   Up to one level of parentheses is allowed in the parameter
;;   list to a method.  The regex pattern for that portion if
;;   from J. Friedl's "Mastering Regular Expressions"

(defconst specman-legal-name-regexp "\\(?:[a-zA-Z][a-zA-Z0-9_]*\\)"
  "e legal name")

(defconst specman-method-definition-regexp
  "\\(?:\\(?:private\\|package\\|protected\\)[ \t\n]+\\)?\\([A-Za-z0-9_]+\\)[ \t\n]*([^()]*\\(?:([^()]*)[^()]*\\)*)[^-/;]*?[ \t\n]+is[a-z \t\n]*{"
  "Regexp that identifies methods (arg 1)")

(defconst specman-on-event-method-definition-regexp
  "\\(on[ \t\n]+[A-Za-z0-9_]+\\)[ \t\n]*{"
  "Regexp that identifies on-event methods (arg 1)")

(defconst specman-class-definition-regexp
  (concat
   "\\("
   "\\(?:\\(?:package[ \t\n]*\\)?struct[ \t\n]+[A-Za-z0-9_]+\\)"
   "\\|"
   "\\(?:extend[ \t\n]+[^{]+\\)"
   "\\|"
   "\\(?:\\(?:package[ \t\n]*\\)?unit[ \t\n]+[A-Za-z0-9_]+\\)"
   "\\)")
  "Regexp that identifies major class scopes (arg 1)")

(defconst specman-when-subtype-definition-regexp
  "\\(when[ \t\n]+[^{]+\\)"
  "Regexp that identifies when subtypes (arg 1)")

(defconst specman-define-regexp
  "\\(define[ \t]*<[^>]+>\\)"
  "Regexp that identifies define scopes (arg 1)")

(defconst specman-macro-and-define-regexp
   "\\(\\(?:#?define\\|#ifn?def\\|#else\\)[ \t\n]+[^ \t\n]+\\)"
  "Regexp that identifies macro and define scopes (arg 1)")

(defconst specman-top-level-container-definition-regexp
  (concat
   "\\("
   "\\(?:\\(?:package[ \t\n]*\\)?struct[ \t\n]+[A-Za-z0-9_]+\\)"
   "\\|"
   "\\(?:extend[ \t\n]+[^{]+\\)"
   "\\|"
   "\\(?:\\(?:package[ \t\n]*\\)?unit[ \t\n]+[A-Za-z0-9_]+\\)"
   "\\|"
   "\\(?:\\(?:#?define\\|#ifn?def\\|#else\\)[ \t\n]+[^ \t\n]+\\)"
   "\\)")
  "Regexp that identifies all specman container scopes (arg 1)")

(defconst specman-container-scope-definition-regexp
  (concat
   "\\("
   "\\(?:\\(?:package[ \t\n]*\\)?struct[ \t\n]+[A-Za-z0-9_]+\\)"
   "\\|"
   "\\(?:extend[ \t\n]+[^{]+\\)"
   "\\|"
   "\\(?:\\(?:package[ \t\n]*\\)?unit[ \t\n]+[A-Za-z0-9_]+\\)"
   "\\|"
   "\\(?:\\(?:#?define\\|#ifn?def\\|#else\\)[ \t\n]+[^ \t\n]+\\)"
   "\\|"
   "\\(?:when[ \t\n]+[^{]+\\)"
   "\\)")
  "Regexp that identifies all specman container scopes (arg 1)")


(defconst specman-field-definition-regexp
  "\\(?:\\(?:private\\|package\\|protected\\)[ \t\n]+\\)?\\([A-Za-z0-9_]+\\)[ \t\n]*:[ \t\n]*\\(?:\\*?[A-Za-z0-9_]+\\|\\[[^\\[]*\\]\\)"
  "Regexp that identifies field definitions (arg 1)")

(defconst specman-variable-definition-regexp
  "var[ \t\n]+\\([A-Za-z0-9_]+\\)[ \t\n]*:=?[ \t\n]*[{*+-]?[ \t\n]*\\([A-Za-z0-9_]+\\)"
  "Regexp that identifies variable definitions (arg 1)")

(defconst specman-event-definition-regexp
  "\\(?:\\(?:private\\|package\\|protected\\)[ \t\n]+\\)?event[ \t\n]+\\([A-Za-z0-9_]+\\)"
  "Regexp that identifies event definitions (arg 1)")

(defconst specman-type-definition-regexp
  "\\(?:package[ \t\n]*\\)?\\(?:method_\\)?type[ \t\n]+\\([A-Za-z0-9_]+\\)[ \t\n]*:[ \t\n]*\\["
  "Regexp that identifies type definitions (arg 1)")

(defconst specman-cover-definition-regexp
  "cover[ \t\n]+\\([A-Za-z0-9_]+\\)[ \t\n]+is"
  "Regexp that identifies cover definitions (arg 1)")

(eval-and-compile
(defconst specman-symbol-begin-regexp
  "\\<"
  "Regexp that identifies the beginning of a symbol")

(defconst specman-symbol-end-regexp
  "\\>"
  "Regexp that identifies the end of a symbol"))

(defconst specman-number-regexp
  (concat
   "\\("

   ;; this is ugly, but the only way I could find to count + and - as
   ;; number symbols but maintaining that numbers have to come after
   ;; a symbol beginning
   "\\(?:"
   "[+-]"
   "\\|"
   specman-symbol-begin-regexp
   "\\)"
   
   "\\(?:"
   "[0-9]+"
   "\\|"
   "0b[01]+"
   "\\|"
   "0o[0-7]+"
   "\\|"
   "0[xh][0-9a-fA-F]+"
   "\\)"
   
   "[kKmM]?"
   "\\)"
   specman-symbol-end-regexp)
  "Regexp that identifies numbers (arg1)")


(defconst specman-method-definition-regexp-full
  (concat "^[ \t]*" specman-method-definition-regexp))

(defconst specman-on-event-method-definition-regexp-full
  (concat "^[ \t]*" specman-on-event-method-definition-regexp))

(defconst specman-class-definition-regexp-full
  (concat "^[ \t]*" specman-class-definition-regexp))

(defconst specman-when-subtype-definition-regexp-full
  (concat "^[ \t]*" specman-when-subtype-definition-regexp))

(defconst specman-define-regexp-full
  (concat "^[ \t]*" specman-define-regexp))

(defconst specman-macro-and-define-regexp-full
  (concat "^[ \t]*" specman-macro-and-define-regexp))

(defconst specman-container-scope-definition-regexp-full
  (concat "^[ \t]*" specman-container-scope-definition-regexp))

(defconst specman-field-definition-regexp-full
  (concat "^[ \t]*" specman-field-definition-regexp))

(defconst specman-variable-definition-regexp-full
  (concat "^[ \t]*" specman-variable-definition-regexp))

(defconst specman-event-definition-regexp-full
  (concat "^[ \t]*" specman-event-definition-regexp))

(defconst specman-type-definition-regexp-full
  (concat "^[ \t]*" specman-type-definition-regexp))

(defconst specman-cover-definition-regexp-full
  (concat "^[ \t]*" specman-cover-definition-regexp))


;; =================================================
;; SPECMAN SEARCHES AND QUERIES
;; =================================================

(defsubst specman-re-search-forward (REGEXP BOUND NOERROR &optional within-code-region)
  "Like re-search-forward, but skips over matches in comments or strings"
  (let ((start-pos
         (point))
        (full-regexp
         (concat
          "\\(//\\|--\\)\\|\\(^'>\\)\\|\\(\"\\)\\|\\(/\\*\\)\\|\\("
          REGEXP
          "\\)"))
        )
    
    (unless within-code-region
      (specman-skip-forward-comment-or-string))
    
    (store-match-data '(nil nil))
    (while (and (if BOUND
                    (<= (point) BOUND)
                  t)
                (re-search-forward full-regexp BOUND NOERROR)
                (cond
                 (;; e line comment
                  (match-beginning 1)
                  
                  (progn
                    (forward-line 1)
                    t)
                  )
                 (;; ex-code region
                  (match-beginning 2)
                  
                  (progn
                    (re-search-forward "^<'" BOUND 'move)
                    t)
                  )
                 (;; string
                  (match-beginning 3)
                  
                  (progn
                    ;; to also consider the next character, for ""
                    (goto-char (match-beginning 3))
                    (re-search-forward "\\(?:[^\\]\\|[\\][\\]\\)\"" BOUND 'move)
                    t)
                  )
                 (;; c multi-line comment
                  (match-beginning 4)

                  (progn
                    (re-search-forward "\\*/" BOUND 'move)
                    t)
                  )
                 (;; the regexp
                  (match-beginning 5)

                  (progn
                    (goto-char (match-beginning 5))
                    (looking-at REGEXP)  ;; to reset match-data
                    nil)
                  )
                 )
                (progn
                  (store-match-data '(nil nil))
                  (if BOUND
                      (< (point) BOUND)
                    t))
                ))
    (goto-char (if (match-end 0)
                   (match-end 0)
                 start-pos))
    (match-end 0)))

(defsubst specman-re-search-backward (REGEXP BOUND NOERROR &optional within-code-region)
  "Like re-search-backward, but skips over matches in comments or strings"
  (let ((start-pos
         (point))
        (full-regexp
         (concat
          "\\(^<'\\)\\|\\(\"\\)\\|\\(\\*/\\)\\|\\("
          REGEXP
          "\\)"))
        )

    (unless within-code-region
      (specman-skip-backward-comment-or-string))
    
    (store-match-data '(nil nil))
    (while (and (if BOUND
                    (>= (point) BOUND)
                  t)
                (re-search-backward full-regexp BOUND NOERROR)
                (cond
                 (;; ex-code region
                  (match-beginning 1)
                  
                  (progn
                    (re-search-backward "^'>" BOUND 'move)
                    t)
                  )
                 (;; string
                  (match-beginning 2)
                  
                  (progn
                    ;; NOTE: this approach is more elegant, but slower than the code below
                    ;;(if (specman-within-string-p)
                    ;;    (re-search-backward "[^\\]\"" BOUND 'move)
                    ;;  (re-search-backward "//\\|--" (specman-beg-of-line-pos) 'move))
                    (when (save-match-data
                           (back-to-indentation)
                           (re-search-forward "\\(//\\|--\\)\\|\\([^\\]\"\\)" (match-beginning 2) 'move)
                           (if (match-beginning 1)  ;; a comment and not a string
                               (progn
                                 (goto-char (match-beginning 1)) ;; go to the comment beginning
                                 nil)                            ;; and fail, staying there
                             t))
                      (goto-char (match-beginning 2))            ;; return to the string
                      (when                                      ;; and find the string opener
                          (re-search-backward "\\(?:[^\\]\\|[\\][\\]\\)\\(\"\\)" BOUND 'move)
                        (goto-char (match-beginning 1))))
                    t)
                  )
                 (;; c multi-line comment
                  (match-beginning 3)

                  (progn
                    (re-search-backward "/\\*" BOUND 'move)
                    t)
                  )
                 (;; the regexp
                  (match-beginning 4)

                  (let ((failed-match nil)
                        )
                    (goto-char (match-beginning 4))
                    (looking-at REGEXP)  ;; to reset match-data
                    (save-match-data
                      ;; if a comment is not found then point is left on the
                      ;; beginning of the line but the goto-char below fixes this.
                      ;; note: the while checks that the comment prefix is not in a string
                      (while (and (re-search-backward "//\\|--" (specman-beg-of-line-pos) 'move)
                                  (if (specman-within-string-p)
                                      t
                                    (progn
                                      (setq failed-match t)
                                      nil)))))
                    failed-match
                    )
                  )
                 )
                (progn
                  (store-match-data '(nil nil))
                  (if BOUND
                      (> (point) BOUND)
                    t))
                ))
    (goto-char (if (match-beginning 0)
                   (match-beginning 0)
                 start-pos))
    (match-beginning 0)))

(defsubst specman-beg-of-line-pos ()
  (save-excursion
    (beginning-of-line)
    (point)))

(defsubst specman-end-of-line-pos ()
  (save-excursion
    (end-of-line)
    (point)))

(defsubst specman-within-comment-p ()
  (or (specman-within-line-comment-p)
      (specman-within-region-comment-p))
  )

(defsubst specman-empty-line-p ()
  (looking-at "^[ \t]*$"))

(defun specman-within-string-p ()
  (save-excursion
    (nth 3 (parse-partial-sexp (point-min) (point)))))

(defsubst specman-line-within-string-p ()
  (save-excursion
    (beginning-of-line)
    (specman-within-string-p)))

(defsubst specman-prepared-buffer-substring (beg end)
  "Remove extra spaces and new-lines from strings."
  (save-match-data
    (if (eq emacs-kind 'emacs)
        (replace-regexp-in-string "[ \t\n]+"
                                    " "
                                    (replace-regexp-in-string "^[ \t\n]+\\|[ \t\n]+$"
                                                              ""
                                                              (buffer-substring beg
                                                                                end)))
      (replace-in-string (replace-in-string (buffer-substring beg
                                                              end)
                                            "^[ \t\n]+\\|[ \t\n]+$"
                                            "")
                         "[ \t\n]+"
                         " "))))


;; =================================================
;; SPECMAN SCOPE QUERIES
;; =================================================

(defvar global-scope-index nil
  "Used as a global reference for cached refs to scopes for performance.
Initialized for performace intensive operations without user interaction
(e.g. region indentation) and must be cleared afterwards.")
(make-variable-buffer-local 'global-scope-index)

(defstruct scope-descriptor paren match parent paren-parent)

(defun specman-create-scope-index ()
  "Create a list of scope descriptors, each of which is a list of 3 members:
scope, matching-scope and parent-scope-opener"

  (save-excursion
    (save-match-data
      (let ((scope-index
             nil
             )
            (scope-stack
             nil
             )
            (paren-stack
             nil
             )
            (buffer-end
             (point-max)
             )
            (top-scope-opener
             (point-min-marker)
             )
            (end-scope-closer
             (point-max-marker)
             )
            (search-regexp
             (concat                      "\\("
                     "{\\|("              "\\)\\|\\("
                     "}\\|)"              "\\)\\|\\("
                     "//\\|--"            "\\)\\|\\("
                     "^'>"                "\\)\\|\\("
                     "\""                 "\\)\\|\\("
                     "/\\*"               "\\)")
             )
            )
        
      (goto-char (point-min))

      ;; for completeness - have a top pseudo-scope for the whole file
      (set-marker-insertion-type top-scope-opener t)
      (set-marker-insertion-type end-scope-closer t)
      (push (cons top-scope-opener
                  (make-scope-descriptor
                   :paren  top-scope-opener
                   :match  end-scope-closer
                   :parent top-scope-opener
                   :paren-parent nil))
            scope-index)
      
      (when (re-search-forward "^<'" buffer-end t)
        (while (and (< (point) buffer-end)
                    (re-search-forward search-regexp buffer-end 'move))
          
          (cond
           ;; new scope
           ((match-beginning 1)

            (save-excursion
              (goto-char (match-beginning 1))
              
              (let* ((point-marker
                      (point-marker)
                      )
                     (is-scope
                      (looking-at "{")
                      )
                     (parent
                      (if scope-stack
                          (scope-descriptor-paren (car scope-stack))
                        top-scope-opener)
                      )
                     (paren-parent
                      (if paren-stack
                          (scope-descriptor-paren (car paren-stack))
                        nil)
                      )
                     (point-descriptor
                      (make-scope-descriptor
                       :paren  point-marker
                       :match  end-scope-closer ;; place holder until the closer is found
                       :parent parent
                       :paren-parent paren-parent)
                      )
                     )
                (set-marker-insertion-type point-marker t)
            
                (push (cons point-marker
                            point-descriptor)
                      scope-index)
                (if is-scope
                    (push point-descriptor scope-stack)
                  (push point-descriptor paren-stack))))
            )
           ;; close scope
           ((match-beginning 2)

            (save-excursion
              (goto-char (match-beginning 2))
              
              (let* ((point-marker
                      (point-marker)
                      )
                     (is-scope
                      (looking-at "}")
                      )
                     (has-match
                      (if is-scope
                          scope-stack
                        paren-stack)
                      )
                     (match
                      (when has-match
                        (if is-scope
                            (pop scope-stack)
                          (pop paren-stack)))
                      )
                     (parent
                      (if scope-stack
                          (scope-descriptor-paren (car scope-stack))
                        top-scope-opener)
                      )
                     (paren-parent
                      (if paren-stack
                          (scope-descriptor-paren (car paren-stack))
                        nil)
                      )
                     )
                (set-marker-insertion-type point-marker t)
            
                (if has-match
                    (let ((point-descriptor
                           (make-scope-descriptor
                            :paren  point-marker
                            :match  (scope-descriptor-paren match)
                            :parent parent
                            :paren-parent paren-parent)
                           )
                          )
                      (setf (scope-descriptor-match match) point-marker)
                      
                      (push (cons point-marker
                                  point-descriptor)
                            scope-index)
                      )
                  ;; currently no error checking for unmatched scopes - here for closing scope
                  (progn
                    (push (cons point-marker
                                (make-scope-descriptor
                                 :paren  point-marker
                                 :match  top-scope-opener
                                 :parent parent
                                 :paren-parent paren-parent))
                          scope-index))
                  )

;; TODO: clear any dangling open parens which aren't closed within the
;; scope being closed now.  nice idea, maybe should be explored more,
;; but doesn't work for now.
                
;;                 (when match
;;                   (let ((close-to-point
;;                          (scope-descriptor-paren match)
;;                          )
;;                         (stack-to-clear
;;                          (if is-scope
;;                              paren-stack
;;                            scope-stack)
;;                          )
;;                         (continue
;;                          t
;;                          )
;;                         )
;;                     (while (and continue
;;                                 stack-to-clear)
;;                       (if (< close-to-point
;;                              (scope-descriptor-paren (car stack-to-clear)))
;;                           (pop stack-to-clear)
;;                         (setq continue nil)))
;;                     ))
                ))
            )
           ;; comment
           ((match-beginning 3)
            
            (forward-line 1)
            )
           ;; end e-code region
           ((match-beginning 4)
            
            (re-search-forward "^<'" buffer-end 'move)
            )
           ;; string
           ((match-beginning 5)

            ;; to also consider the next character, for ""
            (goto-char (match-beginning 0))
            
            (re-search-forward "\\(?:[^\\]\\|[\\][\\]\\)\"" buffer-end 'move)
            )
           ;; c multi-line comment
           ((match-beginning 6)

            (re-search-forward "\\*/" buffer-end 'move)
            )
           )
          )
        ;; currently no error checking for unmatched scopes - here for opening scope
        )

      ;; for aesthetic reasons - the list is arranged as a stack, so it is backward
      (reverse scope-index)
      ))))

(defun specman-clear-scope-descriptor-and-key (key value)
  "Clear a scope index entry.  Intended for use with maphash."
    (let ((opener
           (scope-descriptor-paren value))
          (closer
           (scope-descriptor-match value))
          (parent
           (scope-descriptor-parent value))
          )
      ;; some scope markers can be nil
      (when key
        (set-marker key nil))
      (when opener
        (set-marker opener nil))
      (when closer
        (set-marker closer nil))
      (when parent
        (set-marker parent nil))))
  

(defun specman-clear-scope-index (scope-index)
  "Clear a scope index by setting all markers to nil, so they no longer
have an updating cost and the index itself to nil."
  (while scope-index
    (specman-clear-scope-descriptor-and-key (caar scope-index)
                                            (cdar scope-index))
    (setq scope-index
          (cdr scope-index))))

(defun specman-format-scope-descriptor-and-key (key value)
  "format a scope index entry.  Intended for use with maphash."
  (format "%d => <%d %d> %d^\n"
          (marker-position key)
          (marker-position (scope-descriptor-paren value))
          (marker-position (scope-descriptor-match value))
          (marker-position (scope-descriptor-parent value))))

(defun specman-print-scope-index (scope-index)
  "Print a scope index."
  (if scope-index
      (while scope-index
        (specman-format-scope-descriptor-and-key (caar scope-index)
                                                 (cdar scope-index))
        (setq scope-index
              (cdr scope-index)))
    (message "Trying to print an empty scope-index.")))

(defun specman-scope-index-up-list (scope-index &optional within-code-region)
  (let ((result
         nil)
        )
    (when (specman-re-search-backward "\\((\\)\\|\\()\\|{\\|}\\)"
                                      nil
                                      t
                                      within-code-region)
      ;; at match-beginning 1 we're done, otherwise:
      (if (match-beginning 2)
          (let* ((point-marker
                  (point-marker))
                 (scope-descriptor
                  (assoc point-marker
                         scope-index))
                 (parent-opener
                  (when scope-descriptor
                    (scope-descriptor-paren-parent (cdr scope-descriptor))))
                 )
            (set-marker point-marker nil)
            (when parent-opener
              (setq result (marker-position parent-opener))))
        (setq result (point))
        ))
    (when result
      (goto-char result))
    result))

(defun specman-scope-index-up-scope (scope-index &optional within-code-region)
  (if (specman-re-search-backward "\\({\\)\\|\\(}\\|(\\|)\\)"
                                  nil
                                  t
                                  within-code-region)
      ;; at match-beginning 1 we're done, otherwise:
      (when (match-beginning 2)
        (let* ((point-marker
                (point-marker))
               (scope-descriptor
                (assoc point-marker
                       scope-index))
               (parent-opener
                (when scope-descriptor
                  (scope-descriptor-parent (cdr scope-descriptor))))
               )
          (unless parent-opener
            (error (print (format "scope - %d %d"
                                  (point)
                                  (if parent-opener
                                      (marker-position parent-opener)
                                    -1)))))
        ;;(assert parent-opener)
        (goto-char parent-opener)
        (set-marker point-marker nil)))
    (goto-char (point-min)))
  (point))

(defun specman-scope-index-down-scope (scope-index &optional within-code-region)
  (if (specman-re-search-forward "\\({\\|(\\|)\\)\\|\\(}\\)"
                                 (point-max)
                                 t
                                 within-code-region)
      (progn
        (backward-char)  ;; to be exactly on the paren
        ;; at match-beginning 2 we're done, otherwise:
        (when (match-beginning 1)
          (let* ((point-marker
                  (point-marker))
                 (scope-descriptor
                  nil)
                 (parent-opener
                  (progn
                    (setq scope-descriptor
                          (assoc point-marker
                                 scope-index))
                    (when scope-descriptor
                        (scope-descriptor-parent (cdr scope-descriptor)))))
                 (parent-closer
                  (progn
                    (when parent-opener
                      (setq scope-descriptor
                            (assoc parent-opener
                                   scope-index))
                      (when scope-descriptor
                        (scope-descriptor-match (cdr scope-descriptor))))))
                 )
            (goto-char (if parent-closer
                           parent-closer
                         (point-max)))
            (set-marker point-marker nil))))
    (goto-char (point-max)))
  (point))

;; find the top containing scope - for specman-beg-of-defun
;; the problem is that it has worse performance than the current implementation.
;; this can be solved by having the scope index refer to scope-descriptors
;; instead of markers, as it does now.  this will allow fast traversal of the
;; scope index.
;; TODO: one day...
;;
;; (defun specman-scope-index-top-scope (scope-index &optional within-code-region)
;;   "Find the topmost scope point is contained in."
;;   (if (specman-re-search-backward "\\({\\)\\|\\(}\\|(\\|)\\)"
;;                                   nil
;;                                   t
;;                                   within-code-region)

;;       (let ((continue
;;              t)
;;             (opener-position
;;              (match-beginning 1))
;;             (top-scope
;;              (point-min))
;;             )
;;         (while continue
;;           (let* ((point-marker
;;                   (point-marker))
;;                  (scope-descriptor
;;                   (assoc point-marker
;;                          scope-index))
;;                  (current-opener
;;                   (when scope-descriptor
;;                     (if opener-position
;;                         (scope-descriptor-paren (cdr scope-descriptor))
;;                       (scope-descriptor-parent (cdr scope-descriptor)))))
;;                  (parent-descriptor
;;                   (when current-opener
;;                     (assoc current-opener
;;                            scope-index)))
;;                  (parent-opener
;;                   (when parent-descriptor
;;                     (scope-descriptor-parent (cdr parent-descriptor))))
;;                  )

;;             (setq opener-position t)
;;             (set-marker point-marker nil)
          
;;             (unless parent-opener
;; ;;               (error (print (format "scope - %d %d"
;; ;;                                     (point)
;; ;;                                     (if current-opener
;; ;;                                         (marker-position current-opener)
;; ;;                                       -1)))))
;;               (setq continue nil)
;;               (goto-char (point-min)))

;;             (setq top-scope current-opener)
;;             (goto-char parent-opener)
;;             (when (equal (point)
;;                          (point-min))
;;               (setq continue nil))))

;;         (goto-char top-scope))
    
;;     (goto-char (point-min)))

;;   (point)
;;   )

(defun specman-create-global-scope-index ()
  (setq global-scope-index (specman-create-scope-index)))

(defun specman-clear-global-scope-index ()
  (specman-clear-scope-index global-scope-index)
  (setq global-scope-index nil))

(defun specman-print-global-scope-index ()
  (specman-print-scope-index global-scope-index))


;; =================================================
;; SPECMAN SYNTAX TABLE
;; =================================================

(defconst specman-emacs-features
  (let ((major (and (boundp 'emacs-major-version)
		    emacs-major-version))
	(minor (and (boundp 'emacs-minor-version)
		    emacs-minor-version))
	flavor comments )
    ;; figure out version numbers if not already discovered
    (and (or (not major) (not minor))
	 (string-match "\\([0-9]+\\).\\([0-9]+\\)" emacs-version)
	 (setq major (string-to-int (substring emacs-version
					       (match-beginning 1)
					       (match-end 1)))
	       minor (string-to-int (substring emacs-version
					       (match-beginning 2)
					       (match-end 2)))))
    (if (not (and major minor))
	(error "Cannot figure out the major and minor version numbers."))
    ;; calculate the major version
    (cond
     ((= major 4)  (setq major 'v18))	;Epoch 4
     ((= major 18) (setq major 'v18))	;Emacs 18
     ((= major 19) (setq major 'v19	;Emacs 19
			 flavor (if (or (string-match "Lucid" emacs-version)
					(string-match "XEmacs" emacs-version))
				    'XEmacs 'FSF)))
     ((> major 19) (setq major 'v20
			 flavor (if (or (string-match "Lucid" emacs-version)
					(string-match "XEmacs" emacs-version))
				    'XEmacs 'FSF)))
     ;; I don't know
     (t (error "Cannot recognize major version number: %s" major)))
    ;; XEmacs 19 uses 8-bit modify-syntax-entry flags, as do all
    ;; patched Emacs 19, Emacs 18, Epoch 4's.  Only Emacs 19 uses a
    ;; 1-bit flag.  Let's be as smart as we can about figuring this
    ;; out.
    (if (or (eq major 'v20) (eq major 'v19))
	(let ((table (copy-syntax-table)))
	  (modify-syntax-entry ?a ". 12345678" table)
	  (cond
	   ;; XEmacs pre 20 and Emacs pre 19.30 use vectors for syntax tables.
	   ((vectorp table)
	    (if (= (logand (lsh (aref table ?a) -16) 255) 255)
		(setq comments '8-bit)
	      (setq comments '1-bit)))
	   ;; XEmacs 20 is known to be 8-bit
	   ((eq flavor 'XEmacs) (setq comments '8-bit))
	   ;; Emacs 19.30 and beyond are known to be 1-bit
	   ((eq flavor 'FSF) (setq comments '1-bit))
	   ;; Don't know what this is
	   (t (error "Couldn't figure out syntax table format."))
	   ))
      ;; Emacs 18 has no support for dual comments
      (setq comments 'no-dual-comments))
    ;; lets do some minimal sanity checking.
    (if (or
	 ;; Lemacs before 19.6 had bugs
	 (and (eq major 'v19) (eq flavor 'XEmacs) (< minor 6))
	 ;; Emacs 19 before 19.21 has known bugs
	 (and (eq major 'v19) (eq flavor 'FSF) (< minor 21))
	 )
	(with-output-to-temp-buffer "*specman-mode warnings*"
	  (print (format
		  "The version of Emacs that you are running, %s,
has known bugs in its syntax parsing routines which will affect the
performance of specman-mode. You should strongly consider upgrading to the
latest available version.  Specman-mode may continue to work, after a
fashion, but strange indentation errors could be encountered."
		  emacs-version))))
    ;; Emacs 18, with no patch is not too good
    (if (and (eq major 'v18) (eq comments 'no-dual-comments))
	(with-output-to-temp-buffer "*specman-mode warnings*"
	  (print (format
		  "The version of Emacs 18 you are running, %s,
has known deficiencies in its ability to handle the dual specman
comments, [e.g. the // and -- comments]. You really should strongly
consider upgrading to one of the latest Emacs 19\'s.  In Emacs 18, you
may also experience performance degradations.  Emacs 19 has some new
built-in routines which will speed things up for you.  Because of
these inherent problems, specman-mode is not supported on emacs-18."
		  emacs-version))))
    ;; Emacs 18 with the syntax patches are no longer supported
    (if (and (eq major 'v18) (not (eq comments 'no-dual-comments)))
	(with-output-to-temp-buffer "*specman-mode warnings*"
	  (print (format
  "You are running a syntax patched Emacs 18 variant.  While this should
work for you, you may want to consider upgrading to Emacs 19.
The syntax patches are no longer supported either for specman-mode."))))
    (list major comments ))
  "A list of features extant in the Emacs you are using.
There are many flavors of Emacs out there, each with different
features supporting those needed by specman-mode.  Here's the current
supported list, along with the values for this variable:

 Vanilla Emacs 18/Epoch 4:   (v18 no-dual-comments flock-syntax-before-1930)
 Emacs 18/Epoch 4 (patch2):  (v18 8-bit flock-syntax-after-1930)
 XEmacs (formerly Lucid) 19: (v19 8-bit flock-syntax-after-1930)
 XEmacs >= 20:               (v20 8-bit flock-syntax-after-1930)
 Emacs 19.1-19.30:           (v19 8-bit flock-syntax-before-1930)
 Emacs 19.31-19.xx:          (v19 8-bit flock-syntax-after-1930)
 Emacs >=20:                 (v20 1-bit flock-syntax-after-1930)."
  )

(defun specman-populate-syntax-table (table)
  (modify-syntax-entry ?_  "w"        table)  ;; underscore is a part of words
  (modify-syntax-entry ?{  "(}"       table)
  (modify-syntax-entry ?}  "){"       table)
  (modify-syntax-entry ?\( "()"       table)
  (modify-syntax-entry ?\) ")("       table)
  (modify-syntax-entry ?\[ "(]"       table)
  (modify-syntax-entry ?\] ")["       table)
  (modify-syntax-entry ?\% "."        table)
  (modify-syntax-entry ?\@ "."        table)  ;; for events
  (modify-syntax-entry ?\' "."        table)
  (modify-syntax-entry ?\< "."        table)
  (modify-syntax-entry ?\> "."        table)
  (modify-syntax-entry ?\\ "\\"       table)
  (modify-syntax-entry ?\n "."        table)
  table
  )

(defun specman-setup-dual-comments (table)
  ;; Set up TABLE to handle comments
  ;; unfortunately, emacs can't handle 2 styles of dual comments
  ;; properly, so only // is defined here.  -- is handled
  ;; separately.  xemacs can, but we must use something which
  ;; is compatible for both emacsen.
  ;; instead, the second comment style /*...*/ is used, although
  ;; it is only a valid syntax in the context of c routines.
  
  (cond
   ((memq '8-bit specman-emacs-features)
    ;; XEmacs (formerly Lucid) has the best implementation
    
;;    (modify-syntax-entry ?/  ". 12" table)
;;    (modify-syntax-entry ?-  ". 56" table)
;;    (modify-syntax-entry ?\n "> 37" table)
;;    (modify-syntax-entry ?\f "> 37" table)
    (modify-syntax-entry ?/  ". 1258" table)
    (modify-syntax-entry ?*  ". 67" table)
    (modify-syntax-entry ?\n "> 3" table)
    (modify-syntax-entry ?\f "> 3" table)
    )
   ((memq '1-bit specman-emacs-features)
    ;; Emacs 19 does things differently, but we can work with it
    
;;    (modify-syntax-entry ?/  ". 12" table)
;;    (modify-syntax-entry ?\n ">"    table)
;;    (modify-syntax-entry ?\f ">"    table)
;;    (modify-syntax-entry ?-  "< 12b" table)
;;    (modify-syntax-entry ?\n "> b"    table)
;;    (modify-syntax-entry ?\f "> b"    table)
    (modify-syntax-entry ?/  ". 124" table)
    (modify-syntax-entry ?*  ". 23b" table)
    (modify-syntax-entry ?\n ">"    table)
    (modify-syntax-entry ?\f ">"    table)
    ))
  )

(defvar emacs-kind nil)

;; emacs or xemacs
(if (or (string-match "Lucid" emacs-version)
        (string-match "XEmacs" emacs-version))
    (setq specman-emacs-kind 'xemacs)
  (setq specman-emacs-kind 'emacs))


;; =================================================
;; SPECMAN IMENU FEATURE
;; =================================================

(defun specman-imenu-split-menu (index-alist max-items)
  
  (let ((result-alist
         nil)
        (sub-alist
         nil)
        (counter
         max-items)
        )
    ;; break the index list into sub-lists in the result list
    (while index-alist
      (if (> counter 0)
          (progn
            (setq counter (1- counter))
            (push (car index-alist)
                  sub-alist)
            (setq index-alist (cdr index-alist)))
        (progn
          (setq counter max-items)
          (setq sub-alist (reverse sub-alist))
          (push (cons (format "From: %s" (caar sub-alist))
                      sub-alist)
                result-alist)
          (setq sub-alist nil))))

    ;; handle what is left in the sub-list
    (if result-alist
        (progn
          (setq sub-alist (reverse sub-alist))
          (push (cons (format "From: %s" (caar sub-alist))
                      sub-alist)
                result-alist))
      (setq result-alist sub-alist))

    (setq index-alist (reverse result-alist))

    ;; return result
    index-alist))

(defun specman-imenu-create-menu-for-region (reg-start reg-end scope-index-param)
  ;; function accepts a region because it is used recursively

  (let ((scope-regexp
         specman-container-scope-definition-regexp)
        (method-regexp
        specman-method-definition-regexp)
        (on-event-regexp
        specman-on-event-method-definition-regexp)
        (event-regexp
        specman-event-definition-regexp)
        (type-regexp
        specman-type-definition-regexp)
        (cover-regexp
        specman-cover-definition-regexp)
        (field-regexp
        specman-field-definition-regexp)

        ;; these are used to avoid possible parsing errors on the blocks they start
        (keep-soft-select-regexp
        "\\(keep[ \t\n]+soft[ \t\n]+[^;]+==[ \t\n]+select[ \t\n]*{\\)")
        (gen-keeping-regexp
        "gen[ \t\n]*\\([A-Za-z0-9_]+\\)[ \t\n]*keeping[ \t\n]*{")
         
        (index-alist
        nil)
        (event-alist
        nil)
        (type-alist
        nil)
        (cover-alist
        nil)
        (field-alist
        nil)

        (scope-index
         scope-index-param)
        )
    
    (let ((common-regexp
           (concat
            "^[ \t]*"
            "\\(?:"
           
            "\\(?:"
            scope-regexp
            "\\)\\|\\(?:"
            method-regexp
            "\\)\\|\\(?:"
            on-event-regexp
            "\\)\\|\\(?:"
            event-regexp
            "\\)\\|\\(?:"
            type-regexp
            "\\)\\|\\(?:"
            cover-regexp
            "\\)\\|\\(?:"
            field-regexp
            "\\)\\|\\(?:"
            keep-soft-select-regexp
            "\\)\\|\\(?:"
            gen-keeping-regexp
            "\\)"
           
            "\\)"))
          )

      (unless scope-index-param
        (specman-create-global-scope-index)
        (setq scope-index global-scope-index))
    
      ;; containers and methods are inserted as they occur into the main list,
      ;; all other types get their own sub-menus.
      (save-excursion
        (goto-char reg-start)
        (specman-skip-forward-comment-or-string)
        (while (specman-re-search-forward common-regexp
                                          reg-end
                                          t
                                          t)
          (cond
           (;;  container
            (match-beginning 1)
          
            (progn
              (save-match-data
                (specman-re-search-forward "{"
                                           (point-max)
                                           t
                                           t))
              (push (cons (specman-prepared-buffer-substring (match-beginning 1)
                                                             (match-end 1))
                          (cons (cons "==  DEFINITION  =="
                                      (copy-marker (match-beginning 1)))
                                (specman-imenu-create-menu-for-region
                                 (point)
                                 (save-excursion
                                   (specman-scope-index-down-scope scope-index t))
                                 scope-index)))
                    index-alist)

              (specman-scope-index-down-scope scope-index t)
              )
            )
           (;;  method
            (match-beginning 2)
          
            (push (cons (concat
                         (specman-prepared-buffer-substring (match-beginning 2)
                                                            (match-end 2))
                         "()")
                        (copy-marker (match-beginning 2)))
                  index-alist)
            )
           (;;  on event method
            (match-beginning 3)

            (push (cons (specman-prepared-buffer-substring (match-beginning 3)
                                                           (match-end 3))
                        (copy-marker (match-beginning 3)))
                  index-alist)
            )
           (;;  event
            (match-beginning 4)

            (push (cons (specman-prepared-buffer-substring (match-beginning 4)
                                                           (match-end 4))
                        (copy-marker (match-beginning 4)))
                  event-alist)
            )
           (;;  type
            (match-beginning 5)

            (push (cons (specman-prepared-buffer-substring (match-beginning 5)
                                                           (match-end 5))
                        (copy-marker (match-beginning 5)))
                  type-alist)
            )
           (;;  cover group
            (match-beginning 6)

            (progn
              (push (cons (specman-prepared-buffer-substring (match-beginning 6)
                                                             (match-end 6))
                          (copy-marker (match-beginning 6)))
                    cover-alist)
            
              ;; avoid parsing the cover group
              (specman-re-search-forward "{"
                                         (point-max)
                                         t
                                         t)
              (specman-scope-index-down-scope scope-index t))
            )
           (;;  field
            (match-beginning 7)

            (push (cons (specman-prepared-buffer-substring (match-beginning 7)
                                                           (match-end 7))
                        (copy-marker (match-beginning 7)))
                  field-alist)
            )
           (;;  keep - used to skip soft selects, where the weights look like fields
            (match-beginning 8)

            ;; point is already beyond the opening paren
            (specman-scope-index-down-scope scope-index t)
            )
           (;;  gen keeping - skip the scope to avoid confusion
            (match-beginning 9)

            ;; point is already beyond the opening paren
            (specman-scope-index-down-scope scope-index t)
            )
           )
          )

        ;; order and collect all entries
      
        (when index-alist
          (setq index-alist
          (specman-imenu-split-menu (reverse index-alist)
                                    imenu-max-items)))
        (when cover-alist
          (push (cons "* Cover Groups *"
                      (specman-imenu-split-menu (reverse cover-alist)
                                                imenu-max-items))
          index-alist))
        (when event-alist
          (push (cons "* Events *"
                      (specman-imenu-split-menu (reverse event-alist)
                                                imenu-max-items))
          index-alist))
        (when field-alist
          (push (cons "* Fields *"
                      (specman-imenu-split-menu (reverse field-alist)
                                                imenu-max-items))
          index-alist))
        (when type-alist
          (push (cons "* Types *"
                      (specman-imenu-split-menu (reverse type-alist)
                                                imenu-max-items))
          index-alist))
        )

      (unless scope-index-param
        (specman-clear-global-scope-index))
      
      index-alist
      ))
  )

(defvar imenu--split-submenus-enable t
  "Toggle sub-menu splitting behavior of imenu which can mess up preformatted menus")
(make-variable-buffer-local 'imenu--split-submenus-enable)

;;  prevent the imenu--split-submenus operation in specman-mode buffers,
;;  as it reorders the index-alist and ruins the prepared order.
(defadvice imenu--split-submenus (around specman-disable-imenu-split-submenus (ALIST) activate)
  "enable toggling imenu--split-submenus on/off"
  (if imenu--split-submenus-enable
      ad-do-it
    (setq ad-return-value ALIST)))

(defun specman-imenu-create-menu ()
  (let (imenu
        )
  (message "Creating Specman-Index for Buffer")
  (setq imenu (specman-imenu-create-menu-for-region (point-min) (point-max) nil))
  (message nil)
  imenu))


;; =================================================
;; SPECMAN UTILITY
;; =================================================

;; Macros
(defmacro inc (num &optional val) 
  "increment the value of num"
  (setq num (+ num (or val 1))))

(defmacro for (var from init to final do &rest body)
  "Execute a simple \"for\" loop, e.g.,
    (for i from 1 to 10 do (print i))."
;;  '(let ((,var ,init))
;;     (while (<= ,var ,final)
;;       ,(append body
;;                (setq ,var (+ 1 ,var))))))
  (list 'let (list (list var init))
        (cons 'while 
              (cons (list '<= var final)
                    (append body (list (list 'setq var (list '+ '1 var))))))))

(defun safe-char= (a b)
  "Safe execution of char= which can accept-nil"
  (or (and a
           b
           (char= a b))
      (not (or a
               b))
      )
  )

(defun specman-search-forward-minus-comment (limit)
  "Look for a -- comment between point and a given limit"
  (let ((continue
         t
         )
        (return-val
         nil
         )
        )
    (while (and continue
                (< (point) limit)
                (search-forward "--" limit t))
      (if (specman-within-string-p)
          (or (search-forward "\"" limit t)
              (setq continue nil))
        (progn
          (setq continue nil)
          (goto-char (match-beginning 0))
          (setq return-val (point)))))
    return-val))


(defun specman-skip-forward-comment-or-string ()
 "Move beyond and return true if in a string or comment"
 (let ((state
	(save-excursion
	  (parse-partial-sexp (point-min) (point)))
        )
       )
   (save-match-data
     (cond
      (;; outside e-code block
       (save-excursion
         (re-search-forward "^\\(?:\\(<'\\)\\|\\('>\\)\\)" (point-max) t)
         (not (match-beginning 2)))
       
       (if (match-end 1)
           (goto-char (match-end 1))
         (goto-char (point-max)))
       t
       )
      (;; inside string
       (nth 3 state)
       
       (re-search-forward "\\(?:[^\\]\\|[\\][\\]\\)\"")
       (goto-char (match-end 0))
       t
       )
      (;; inside // comment (/*...*/ also)
       (nth 4 state)

       (if (save-excursion
             (goto-char (nth 8 state))
             (looking-at "//"))
           ;; in //... comment
           (forward-line 1)
         ;; in /*...*/ comment
         (search-forward "*/" (point-max) t))
       t
       )
      (;; true if we are in a -- ... EOL region
       (save-excursion
         (let ((cur-position (point))
               )
           (back-to-indentation)
           (specman-search-forward-minus-comment cur-position)))
       
       (forward-line 1)
       t
       )
      (;; default
       t
       
       nil
       )
      )
     )
   )
 )

(defun specman-skip-backward-comment-or-string ()
 "Move to the begining and return true if in a string or comment"
 (let ((state
	(save-excursion
	  (parse-partial-sexp (point-min) (point)))
        )
       )
   (save-match-data
     (cond
      (;; outside e-code block
       (save-excursion
         (re-search-backward "^\\(?:\\(<'\\)\\|\\('>\\)\\)" (point-min) t)
         (not (match-beginning 1)))
       
       (if (match-beginning 2)
           (goto-char (match-beginning 2))
         (goto-char (point-min)))
       t
       )
      (;; inside string
       (nth 3 state)
       
       (re-search-backward "\\(?:[^\\]\\|[\\][\\]\\)\"")
       (goto-char (match-beginning 0))
       t)
      (;; inside // comment (/*...*/ also)
       (nth 4 state)
       
       ;;(search-backward "//")
       (goto-char (nth 8 state))
       t
       )
      (;; true if we are in a -- ... EOL region
       (save-excursion
         (let ((cur-position (point))
               )
           (back-to-indentation)
           (specman-search-forward-minus-comment cur-position)))
       
       (goto-char (match-beginning 0))
       t)
      (;; default
       t
       
       nil)
      )
     )
   )
 )

(defun specman-forward-ws (&optional bound)
  "Forward skip over syntactic whitespace"
  (skip-chars-forward " \t\n")
  (while 
      (cond
       ((looking-at "[ \t\n]") (skip-chars-forward "[ \t\n]"))
       ((looking-at "--")      (forward-to-indentation 1))
       ((looking-at "//")      (forward-to-indentation 1))
       ((looking-at "^'>")     (search-forward "\n<'" nil t))
       (t
	nil))))

(defun specman-within-paren-p ()	
  "Return true if in a parenthetical expression"
  (save-excursion
    (specman-up-list)))

(defun specman-within-line-comment-p ()
  "Return point if in a // or -- comment."
  (or (save-excursion
        (let ((state
               (parse-partial-sexp (point-min) (point)))
              )
          (and (nth 4 state)
               (goto-char (nth 8 state))
               (if (looking-at "//")
                   (point)
                 nil))))
      (save-excursion ;; true if we are in a -- ... EOL region
        (let ((cur-position
               (point))
              )
          (back-to-indentation)
          (if (specman-search-forward-minus-comment cur-position)
              (point)
            nil)))))

(defun specman-line-within-comment-p ()
  "Return true if the current line is fully commented-out as a line comment."
  (save-excursion
    (back-to-indentation)
    (looking-at "//\\|--")))

(defun specman-line-within-star-comment-p ()
  "Return true if the current line is fully in a star comment."
  (save-excursion
    (back-to-indentation)
    (nth 4 (parse-partial-sexp (point-min) (point)))))

(defun specman-line-within-star-comment-or-string-p ()
  "Return true if the current line begins within a string or a star comment."
  (save-excursion
    (back-to-indentation)
    (let* ((point-status
            (parse-partial-sexp (point-min) (point))
            )
           (in-string
            (nth 3 point-status)
            )
           (in-star-comment
            (nth 4 point-status)
            )
           )
      (or in-string
          in-star-comment)))
  )

(defun specman-indent-pos ()
  (save-excursion
    (back-to-indentation)
    (point)))

(defun specman-indent-col ()
  (save-excursion
    (back-to-indentation)
    (current-column)))


(defun specman-insert-tab ()
  "Better tab insertion - normal in string, using spaces until tab-stop
otherwise."
  (interactive)
  ;; if we are inside a string, put plain tab
  (if (specman-within-string-p)
      (insert "\t")
    (progn
      (insert " ")
      (while (not (eq (% (current-column) specman-tab-width) 0))
	(insert " ")))))

(defun specman-remove-tab ()
  "Better tab removal - remove a tab or spaces until tab-stop according
to context."
  (interactive)
  ;; if we are inside a string, delete one char
  (let ((start-with-space
         (safe-char= (char-before) ?\  )
         )
        )
    (delete-backward-char 1)
    (if (and (not (specman-within-string-p))
             start-with-space)
	(while (and (not (eq (% (current-column) 
                                specman-tab-width)
                             0))
                    (safe-char= (char-before) ?\  ))
	  (delete-backward-char 1)))))

(defun specman-kill-entire-line ()
  "Kill entire line and indent"
  (interactive)
  (kill-entire-line)
  (specman-activate-indent)
  )

;; =================================================
;; SPECMAN MODE MAP
;; =================================================
(defconst specman-mode-map 
  (let ((map (make-sparse-keymap)))
    (define-key map [(tab)]                     'specman-activate-indent)
    (define-key map [(iso-left-tab)]            'specman-insert-tab)
    (define-key map "\C-c\C-t"                  'specman-insert-tab)
    (define-key map "\C-c\C-a"                  'specman-redo-endcomments)
    (define-key map "\C-c\C-b"                  'specman-submit-bug-report)
    (define-key map [(backspace)]               'specman-remove-tab)
    (define-key map "\r"                        'specman-insert-newline)
    ;(define-key map ";"                         'specman-electric-semicolon)
	(define-key map [(control c) (control ?\;)] 'specman-insert-auto-endcomment)
    (define-key map "\C-c\C-l"                  'eval-from-minibuffer)
    ;(define-key map "\C-c@"                     'specman-toggle-hide-comments)
    ;(define-key map "{"                         'specman-insert-curly-opener)
	(define-key map [(control {)]               'specman-open-e-code-block)
    (define-key map "}"                         'specman-insert-curly-closer)
    (define-key map "("                         'specman-insert-parens-opener)
    (define-key map ")"                         'specman-insert-parens-closer)
    (define-key map "["                         'specman-insert-bracket-opener)
    (define-key map "]"                         'specman-insert-bracket-closer)
    (define-key map "'"                         'specman-insert-tick)
    (define-key map "<"                         'specman-insert-lt)
    (define-key map ">"                         'specman-insert-gt)
    (define-key map [(control c) (control ?-)]  'specman-insert-minus-comment)
    (define-key map [(control c) (control ?/)]  'specman-insert-slash-comment)
    (define-key map [(control c) (control ?_)]  'specman-minor-comment-separator)
    (define-key map [(control c) (control ?=)]  'specman-major-comment-separator)
    (define-key map [(control c) ?f]            'specman-development-file-header)
    (define-key map [(control c) ?s]            'specman-struct-and-define-header-compact)
    (define-key map [(control c) ?m]            'specman-method-header-compact)
    (define-key map [(control c) (control ?<)]  'specman-open-e-code-section)
    (define-key map [(control c) (control ?>)]  'specman-exclude-code-region)
    (define-key map [(control c) ?{]            'specman-open-e-code-block)
    (define-key map [(control c) (control d)]   'specman-describe-context)
    (define-key map "\C-c\C-c"                  'comment-region)
    (define-key map "\C-c\C-u"                  'specman-uncomment-region)
    (define-key map [(meta q)]                  'specman-realign-comment)
	(define-key map [(control d)]               'specman-kill-entire-line)
	(define-key map [(shift insert)]            'specman-yank)
    map)
  "Keymap used in Specman mode."
  )

;; TODO: not sure what this is for, but it's disabled along
;;       with the rest of hide-comments
;;(defconst hide-ifdef-mode-prefix-key [(control c) @]
;;  "Prefix key for all Hide-Ifdef mode commands.")


;; =================================================
;; SPECMAN FONTLOCK SUPPORT
;; =================================================
(defvar specman-mode-syntax-table nil
  "Syntax table used in specman-mode buffers.")

(defconst specman-font-lock-keywords nil
  "Default highlighting for Specman mode.")

(defconst specman-font-lock-keywords-1 nil
  "Subdued level highlighting for Specman mode.")

(defconst specman-font-lock-keywords-2 nil
  "Medium level highlighting for Specman mode.
See also `specman-font-lock-extra-types'.")

(defconst specman-font-lock-keywords-3 nil
  "Gaudy level highlighting for Specman mode.
See also `specman-font-lock-extra-types'.")

(let 
    (
     (specman-types-keywords
      (eval-when-compile
        (concat
         specman-symbol-begin-regexp
         "\\("
         (regexp-opt
          '(
            ;; predefined types
            ;; ----------------
            "bit" "bits" "bool" "byte" "bytes"
            "int" "uint" "long" "nibble" "index"
            "file" "string"
            "time" "e_time_units"
            "semaphore" "message_logger"
            "untyped"

            ;; port types
            ;; ----------
            "any_port" "any_buffer_port" "any_call_port" "any_event_port"
            "any_method_port" "any_simple_port"

            ;; sequence types
            ;; --------------
            "any_sequence" "any_sequence_item" "any_sequence_driver"

            ))
         "\\)"
         specman-symbol-end-regexp)))

     (specman-constant-keywords
      (eval-when-compile
        (concat
         specman-symbol-begin-regexp
         "\\("
         (regexp-opt
          '(
            ;; type constants
            ;; --------------
            "TRUE" "FALSE" "UNDEF" "NULL" "MAX_INT" "MIN_INT" "MAX_UINT"

            ;; error constants
            ;; ---------------
            "ERROR" "ERROR_BREAK_RUN" "ERROR_AUTOMATIC"
            "ERROR_CONTINUE" "WARNING" "IGNORE"

            ;; radix constants
            ;; ---------------
            "BIN" "DEC" "HEX"
            ))
         "\\)"
         specman-symbol-end-regexp)))

     (specman-macro-keywords
      (concat
       "<";;specman-symbol-begin-regexp
       "\\("
       
       "\\(?:[^']+\'"
       "\\("
       "statement"
       "\\|"
       "action"
       "\\|"
       "command"
       "\\|"
       "struct_member"
       "\\|"
       "exp"
       "\\|"
       "type"
       "\\|"
       "block"
       "\\|"
       "num"
       "\\|"
       "file"
       "\\)"
       specman-symbol-end-regexp
       "\\)"
         
       "\\|"
         
       "\\(?:\\(?:[^']+\'\\)?"
       "\\(?:"
       "statement" 
       "\\|"
       "action" 
       "\\|"
       "command" 
       "\\|"
       "struct_member" 
       "\\|"
       "exp" 
       "\\|"
       "name" 
       "\\|"
       "file" 
       "\\|"
       "num" 
       "\\|"
       "block" 
       "\\|"
       "Type" 
       "\\|"
       "any" 
       "\\)"
       "\\(?:|[A-Za-z0-9_]+\\)?"
       "\\)"

       "\\|"

       "\\(?:"
       "[0-9]+"
       "\\|"
       "\\?"
       "\\)"

       "\\)"
       ">";;specman-symbol-end-regexp
       ))

     (specman-function-keywords
      (eval-when-compile
	(concat
         specman-symbol-begin-regexp
         "\\("
         (regexp-opt
          '(
            ;; list pseudo methods
            ;; -------------------

            ;; list - modify
            "add" "add0" "clear" "delete" "fast_delete" "insert" "pop" "pop0"
            "push" "push0" "resize"

            ;; list - general
            "apply" ;; "copy" - also for any_struct
            "count" "exists" ;; "field" - already exists
            "first" "first_index" "get_indices" "has" "is_a_permutation" "is_empty"
            "last" "last_index"
            "max" "max_index" "max_value"
            "min" "min_index" "min_value"
            "reverse" "size" "sort" "sort_by_field" "split" "top" "top0" "unique"

            ;; list - sublist
            "all" "all_indices"

            ;; list - math and logic
            "and_all" "average" "or_all" "product" "sum"

            ;; list - crc
            "crc_8" "crc_32" "crc_32_flip"

            ;; list - keyed list
            "key" "key_index" "key_exists"

            
            ;; string pseudo methods
            ;; ---------------------

            ;; string - convert to string
            "append" "appendf" "quote" "to_string"

            ;; string - manipulate substrings
            "str_join" "str_split" "str_split_all" "str_sub"

            ;; string - manipulate regular expressions
            "str_match" "str_replace" "str_insensitive"

            ;; string - change the radix of a numeric expression
            "bin" "dec" "hex"

            ;; string - manipulate the length of an expression
            "str_chop" "str_empty" "str_exactly" "str_len" "str_pad"

            ;; string - useful within macros
            "quote" "str_expand_dots"

            ;; string - manipulate the case of characters within a string
            "str_lower" "str_upper" "str_insensitive"


            ;; deep copy and compare
            ;; ---------------------
            "deep_copy" "deep_compare" "deep_compare_physical"


            ;; bitwise operations
            ;; ------------------
            "bitwise_and" "bitwise_or" "bitwise_xor"
            "bitwise_nand" "bitwise_nor" "bitwise_xnor"

            
            ;; arithmetic
            ;; ----------
            ;; "min" "max" - already in list
            "abs" "odd" "even" "ilog2" "ilog10" "ipow" "isqrt" "div_round_up"


            ;; output
            ;; ------
            "out" "outf"


            ;; configuration routines
            ;; ----------------------
            "set_config" "get_config" "write_config" "read_config"
            "set_retain_state" "get_retain_state"


            ;; specman command
            ;; ---------------
            "specman"
            

            ;; os interface routines
            ;; ---------------------
            "spawn" "spawn_check" "system" "output_from" "output_from_check"
            "get_symbol" "date_time" "getpid"


            ;; Simulation-Related Routines
            ;; ---------------------------
            "simulator_command" "stop_run"


            ;; low level file routines
            ;; -----------------------
            "files.write_string_list" "files.add_file_type"
            "files.close" "files.flush" "files.open"
            "files.read" "files.read_lob"
            "files.write" "files.write_lob"
            
            
            ;; reading and writing structs
            ;; ---------------------------
            "files.read_ascii_struct" "files.read_binary_struct"
            "files.write_ascii_struct" "files.write_binary_struct"


            ;; On-the-Fly Garbage Collection Routine
            ;; -------------------------------------
            "do_otf_gc"

            
            ;; Constructs for Packing and Unpacking
            ;; ------------------------------------
            "pack" "unpack" "swap" "do_pack" "do_unpack"


            ;; dut error routines
            ;; ------------------
            "dut_error" "dut_errorf" "set_check"


            ;; user error routines
            ;; -------------------
            "error" "warning" "fatal"


            ;; messages
            ;; --------
            "message" "messagef"


            ;; predefined global test phase methods
            ;; ------------------------------------
            "setup_test" "generate_test" "start_test" "run_test" "extract_test"
            "check_test" "finalize_test"

            
            ;; predefined sys methods
            ;; ----------------------
            "wave_setup" "setup"

            
            ;; predefined any_struct methods
            ;; -----------------------------
            "init" "pre_generate" "post_generate" "check" "extract" "finalize"
            "quit" "run" "rerun" "copy" "do_print" "print_line"

            
            ;; predefined unit-related any_struct methods
            ;; ------------------------------------------
            "get_unit" "get_enclosing_unit" "try_enclosing_unit" "set_unit"

            
            ;; predefined any_unit methods
            ;; ---------------------------
            "hdl_path" "full_hdl_path" "e_path" "agent" "get_parent_unit"

            
            ;; language pseudo-methods
            ;; -----------------------
            "declared_type" "type" "field" "unsafe" "source_location"
            "source_method" "as_a" "all_values"
            "in_sequence" "in_unit"
            "unsafe"

            
            ;; semaphore methods
            ;; -----------------
            "up" "down" "try_up" "try_down" "set_value" "get_value"
            "set_max_value" "get_max_value" "lock" "release"

            
            ;; tcm related methods
            ;; -------------------
            "get_current_handle" "get_handles_by_name" "get_handles_by_type"
            "kill" "terminate_branch" "terminate_thread"

            
            ;; coverage methods
            ;; ----------------
            "set_external_cover" "write_cover_file"

            "covers.include_tests"
            "covers.set_weight" "covers.set_at_least" "covers.set_cover"
            "covers.get_contributing_runs" "covers.get_unique_buckets"
            "covers.get_overall_grade" "covers.get_ecov_name"
            "covers.get_test_name" "covers.get_seed"

            "range"


            ;; generation methods
            ;; ------------------
            "is_all_iterations" "reset_soft" "size" "value" "read_only"
            "gen_before_subtypes" "reset_gen_before_subtypes"


            ;; temporal methods
            ;; ----------------
            "true" "change" "fall" "rise"


            ;; sequence methods
            ;; ----------------

            ;; interface - any_sequence_item
            "get_depth" "get_driver" "nice_string"
            
            ;; interface - any_sequence
            "get_index" "grab" "is_blocked" "is_relevant"
            "start_sequence" "body" "stop" "ungrab"
            "mid_do"
            "post_body" "post_do" "post_trace"
            "pre_body" "pre_do"
            ;; inherited from any_sequence_item:
            ;; "get_depth" "get_driver" "nice_string"

            ;; interface - any_sequence_driver
            "current_grabber" "get_current_item" "get_index" "get_item_trace_list"
            "get_next_item" "get_num_items_sent" "get_sequence_trace_list"
            "get_trace_list" "is_grabbed" ;; "last" - also keyword of list
            "try_next_item" "check_is_relevant" "delay_clock" "get_sub_drivers"
            "read" "regenerate_data" "send_to_bfm" "wait_for_sequences" "write"


            ;; port methods
            ;; ------------
            ;; TODO: add cvl stuff
            "bind"
            
            ))
         "\\)"
         "[ \t]*(") ;; NOTE: it's possible to also add \n to the separators
                    ;; before the opening paren, but that messes up font-lock.

        ))

     (specman-keywords
      (eval-when-compile
	(concat
         specman-symbol-begin-regexp
         "\\(" 
         (regexp-opt
          '(
            ;; language keywords
            ;; -----------------
            ;; "also" "only" "inline" "undefined" "empty" - handled when prefixed by "is"
            "is" "a" "as" "computed" "with"
            "assert" "compute" "import" "new" "try"

            "struct" "extend" "unit" "when" "like"
            ;; define/ifdef/etc' - handled differently
            "def_err"
            
            "print" "report"

            "list" "of" "key"

            "private" "package" "protected"

            ;; handled seperately so they can have a different face for emphasis
            ;; "result" "return" "me" "it" "index" "prev"

            "routine" "type" "method_type" "var" "attribute"

            
            ;; packing keywords
            ;; ----------------
            "packing.low" "packing.low_big_endian" "packing.high"
            "packing.high_big_endian" "packing.network" "packing.global_default" 
            

            ;; logic keywords
            ;; --------------
            "and" "or" "xor" "not"
            "nand" "nor" "nxor"


            ;; control flow keywords
            ;; ---------------------
            "if" "then" "else"
            "case" "default"
            "while" "do" "repeat" "until" "continue" "break"
            "for" "each" "in" "using" "reverse" ;; "index" - also language keyword
            "from" "to" "step" ;; "down to" - handled differently
            "matching"

            
            ;; generation keywords
            ;; -------------------
            "before" "keep" "keeping" "soft" "select" "gen"
            "others" "pass" "edges" "min" "max"

            
            ;; coverage keywords
            ;; -----------------
            "cover" "item" "transition" "cross" ;; "using" - also in control flow
            "ignore" "illegal" "per_instance" "no_collect" "no_trace"
            "at_least" "ranges" "radix" ;; "when" - also in language
            ;; name, text, weight - these are not proper keywords and are valid in
            ;; other contexts as well, so commented out.

            
            ;; temporal keywords
            ;; -----------------
            ;; logic - "not" "and" "or"
            "eventually" "fail" "detach" "delay" "cycle" "consume" "exec"
            "now" ;; - described as logic in the e-ref
            "assume" "expect" "wait" "sync" "on";; "event" - handled differently
            "event" "start" "emit"

            
            ;; predefined events - moved with general events expression, doesn't work here
            ;; -----------------
            ;;"@any" "@tick_start" "@tick_end" "@start_of_test"
            ;;"@end_of_test" "@quit" "@new_time"

            ;; port keywords
            ;; -------------
            ;; TODO: add cvl stuff
            "deep_copy" "deep_compare" "deep_compare_physical" "deep_all"
            "normal" "reference" "ignore"
            "external" "empty" "undefined"
            "force" "in" "out" "inout"

            ;; sequences keywords
            ;; ------------------

            "sequence"
            
            ;; - any_sequence_item
            ;; fields: "parent_sequence" "driver"
            
            ;; - any_sequence
            ;; fields: "parent_sequence" "driver" "kind"
            ;; events:
            ;;"@ended" "@started"  -- moved with other events
            
            ;; - any_sequence_driver
            ;; fields: "bfm_interaction_mode" "max_random_count"
            ;;         "max_random_depth" "num_of_last_items"
            ;;         "gen_and_start_main"
            ;; events:
            ;;"@clock" "@item_done"  -- moved with other events
            
            ))
         "\\)"
         specman-symbol-end-regexp)
        ))

     (specman-multi-word-keywords
      ;; TODO: does eval-when-compile help here?
      (eval-when-compile
        (concat
         specman-symbol-begin-regexp
         "\\("
         
         "\\(\\(?:all\\|first\\)[ \t\n]+of\\)\\|"

         "\\(check[ \t\n]+that\\)\\|"
           
         "\\(each[ \t\n]+\\(?:file\\|line\\)\\)\\|"
         "\\(in[ \t\n]+file\\)\\|"
         "\\(down[ \t\n]+to\\)\\|"
           
         "\\(in[ \t\n]+range\\)\\|"
           
         "\\(is[ \t\n]+\\(?:not[ \t\n]+\\)?an?\\)\\|"
         "\\(is[ \t\n]+"
         "\\(?:"
         "also"
         "\\|"
         "first"
         "\\|"
         "inline\\(?:[ \t\n]+only\\)?"
         "\\|"
         "only"
         "\\|"
         "\\(?:not[ \t\n]+\\)?empty"
         "\\|"
         "undefined"
         "\\|"
         "[cC][ \t\n]+routine"
         "\\)"
         "\\)\\|"
         "\\(is[ \t\n]+instance\\)\\|"
           
         "\\(state[ \t\n]+machine\\)\\|"
            
         "\\(verilog[ \t\n]+"
         "\\(?:"
         "code"
         "\\|"
         "function"
         "\\|"
         "import"
         "\\|"
         "simulator"
         "\\|"
         "task"
         "\\|"
         "time"
         "\\|"
         "trace"
         "\\|"
         "variable"
         "\\)"
         "\\)\\|"

         "\\(vhdl[ \t\n]+"
         "\\(?:"
         "code"
         "\\|"
         "driver"
         "\\|"
         "function"
         "\\|"
         "object"
         "\\|"
         "procedure"
         "\\|"
         "simulator"
         "\\|"
         "time"
         "\\)"
         "\\)\\|"
            
         "\\([cC][ \t\n]+export\\)\\|"

         ;; cvl declarations
         "\\(cvl[ \t\n]+\\(?:method\\|call\\(?:back\\)?\\)\\(?:[ \t\n]+async\\)\\)"
            
         ;; port declaration
         "\\(\\(?:\\(?:in\\|out\\|intout\\)[ \t\n]+\\)?simple_port[ \t\n]+of\\)"
         "\\(\\(?:in\\|out\\|intout\\)[ \t\n]+\\(?:buffer\\|call\\|event\\|method\\)_port[ \t\n]+of\\)"

         "\\)"
         specman-symbol-end-regexp
         ))
      )
     )

  (setq specman-font-lock-keywords
	(list
         ;;(cons "\\(//.*$\\)\\|\\(--.*$\\)" '(0 font-lock-comment-face)) ;; not needed
         ;; Fontify all types
         (cons specman-types-keywords
               '(0 'font-lock-type-face append))
         ;; Fontify return and result keywords seperately for emphasis
         (cons (concat
                specman-symbol-begin-regexp
                "re\\(?:sult\\|turn\\)"
                specman-symbol-end-regexp)
               '(0 'font-lock-type-face append))
         ;; Fontify special var/fields keywords "me" "it" "index" "prev" seperately for emphasis
         (cons (concat
                specman-symbol-begin-regexp
                "\\(?:me\\|it\\|index\\|prev\\)"
                specman-symbol-end-regexp)
               '(0 'font-lock-type-face append))
		 ;; Fontify all constants
         (cons specman-constant-keywords
               '(0 'font-lock-constant-face append))
         ;; Fontify macros
         (cons (concat
                "#"
                "\\("
                "ifn?def"
                "\\|"
                "else"
                "\\|"
                "undef"
                "\\|"
                "define"
                "\\)"
                specman-symbol-end-regexp
                
                "\\|"
                
                specman-symbol-begin-regexp
                "define"
                specman-symbol-end-regexp)
               '(0 'font-lock-keyword-face append))
         ;; Fontify numbers
         (cons specman-number-regexp
               '(1 'font-lock-constant-face append))
         ;; Fontify all builtin keywords
         (cons specman-keywords
               '(0 'font-lock-keyword-face append))
         ;; Fontify multi-word keywords
         (cons specman-multi-word-keywords
               '(0 'font-lock-keyword-face append))))

  ;; Fontify punctuation
  (when specman-highlight-punctuation
    (setq specman-font-lock-keywords
          (append specman-font-lock-keywords
                  (list
                   (cons "[][\.\,\;\:\*\|\&\!\(\)\{\}\=\$\<\>\'\#\%\-\+\@]"
                         '(0 'specman-punctuation-face append))))))


  ;; Fontify comments
  ;; - '//' comments handled as syntax in both emacsen but '--' only in
  ;;   xemacs.
  ;; - this handles '--' comments
  ;;   - using this even in xemacs, which should be able to handle 2 fully
  ;;     independent comment types, but fails to do so in e.g. version 21.1
  (setq specman-font-lock-keywords
        (append specman-font-lock-keywords
                (list
                 '(specman-match-minus-comments
                   (0 'font-lock-comment-face t))
                 )))

  (setq specman-font-lock-keywords-1
        (append specman-font-lock-keywords
                (list
                 ;; Additionally fontify pre-defined functions
                 ;; - using keep to prevent bold highlight in comments
                 (cons specman-function-keywords
                       '(1 'font-lock-function-name-face keep))
                 )))

  (setq specman-font-lock-keywords-2
        (append specman-font-lock-keywords-1 
                (list
                 ;; Fontify user defined methods
                 (cons specman-method-definition-regexp-full
                       '(1 'font-lock-function-name-face prepend))
                 ;; Fontify user defined variables
                 (cons specman-variable-definition-regexp-full
                       '(1 'font-lock-variable-name-face prepend))
                 ;; Fontify user defined fields (and more)
                 ;; - not using regexp-full so method arguments
                 ;;   and type definitions are also highlighted
                 ;;   using this regexp.
                 (cons specman-field-definition-regexp
                       '(1 'font-lock-variable-name-face append))
                 ;; Fontify user defined events
                 (cons specman-event-definition-regexp-full
                       '(1 'font-lock-variable-name-face append))
                 ;; Fontify user defined cover groups
                 (cons specman-cover-definition-regexp-full
                       '(1 'font-lock-variable-name-face append))
                 ;; Fontify user defined on event methods
                 (cons specman-on-event-method-definition-regexp-full
                       '(1 'font-lock-function-name-face append))
                 )))

  (setq specman-font-lock-keywords-3
        (append specman-font-lock-keywords-2  
                (list
                 ;; Fontify as comments anything not in e-code scope
                 ;; (i.e. delimited by <'...'>)
                 '(specman-match-ex-code-regions 
                   (0 'font-lock-comment-face t))
                 ;; Highlight text beyond specman-max-line-length
                 '(specman-match-beyond-max-line-length
                   (0 'specman-highlight-beyond-max-line-length-face t))
                 ;; Fontify 'TODO' as keyword (for TODO comments)
                 (cons "\\<TODO[ \t]?[:-]"
                       '(0 'font-lock-warning-face t))
                 
                 ;; Fontify predefined events as keywords
                 (cons (concat "@\\("
                               
                               "any"            "\\|"
                               "tick_start"     "\\|"
                               "tick_end"       "\\|"
                               "start_of_test"  "\\|"
                               "end_of_test"    "\\|"
                               "quit"           "\\|"
                               "new_time"       "\\|"
                               "ended"          "\\|"
                               "started"        "\\|"
                               "clock"          "\\|"
                               "item_done"
                               
                               "\\)"
                               specman-symbol-end-regexp)
                       '(0 'font-lock-keyword-face append))
                 ;; Fontify events as constants
                 (cons "@\\([a-zA-Z0-9_.]+\\)"
                       '(1 'font-lock-constant-face append))
                 
                 ;; Fontify macro keywords as constants
                 (cons specman-macro-keywords
                       ;;'(0 'font-lock-constant-face append))
                       '(1 'font-lock-constant-face append))
                 )
                nil))
  )

;; =================================================
;; SPECMAN UTILITY FUNCTIONS
;; =================================================

(defun specman-up-list (&optional within-code-region)
  "Move up one list, skipping over specman's many comment styles. 
   Return point of opener if we are in a list"
  
  (if global-scope-index
      (specman-scope-index-up-list global-scope-index within-code-region)
    (let (
          ;; this can be wrong when there is a list within a
          ;; parens, but there is a check below that will recover
          ;; from that case.
          (lim
           (save-excursion
             (specman-beg-of-defun within-code-region)))
          (nest
           1)
          (start-point
           (point))
          tb
          )

      (unless within-code-region
        (specman-skip-backward-comment-or-string))
    
      (catch 'skip
        (while (and (> (point) lim)
                    (specman-re-search-backward "[()}]"
                                                lim
                                                t
                                                t))
          (setq tb (char-after))
          (cond
           ((= tb ?\( ) (setq nest (1- nest)))
           ((= tb ?\) ) (setq nest (1+ nest)))
         
           ;; this skips the block and also moves point
           ((= tb ?\} ) (setq lim (save-excursion
                                    (specman-up-scope t)
                                    (if (specman-re-search-backward ";" nil t t)
                                        (point)
                                      (point-min)))))
         
           )
          (if (= 0 nest)
              (throw 'skip (point)))
          )
        ;; if we reached this point then the search failed
        (goto-char start-point)
        nil)
      )
    ))

(defun specman-up-scope (&optional within-code-region)
  "Move up one scope, skipping over specman's many comment styles.
   Return point of opener if we are in a list"

  (if global-scope-index
      (specman-scope-index-up-scope global-scope-index within-code-region)
    (let ((lim (save-excursion
                 (specman-beg-of-defun within-code-region t)))
          (nest 1)
          tb
          )

      (unless within-code-region
        (specman-skip-backward-comment-or-string))
      
      (catch 'skip
        (while
            (and (> (point) lim)
                 (specman-re-search-backward "[{}]"
                                             lim
                                             'move
                                             t))
          (setq tb (char-syntax (char-after)))
          (cond
           ((= tb ?\() (setq nest (1- nest)))
           ((= tb ?\)) (setq nest (1+ nest)))
           )
          (if (= 0 nest)
              (throw 'skip (point)))
          )
        ;; if we reached this point then the search failed
        (goto-char (point-min))
        (throw 'skip (point)))
      )
    ))

(defun specman-down-scope (&optional within-code-region)
  "Move down one scope, skipping over specman's many comment styles.
   Return point of closer if we are in a list"

  (if global-scope-index
      (specman-scope-index-down-scope global-scope-index within-code-region)
    (let (
          (lim
           (save-excursion
             (specman-end-of-e-code)
             (point))
           )
          (nest
           1
           )
          )

      (unless within-code-region
        (specman-skip-forward-comment-or-string))
      
      (catch 'skip
        (while
            (and (< (point) lim)
                 (specman-re-search-forward "\\({\\)\\|\\(}\\)\\|\\(//\\|--\\)\\|\\(^'>\\)\\|\\(\"\\)"
                                            lim
                                            'move
                                            t))
          (setq tb (char-syntax (char-before)))
          (cond
           ((match-beginning 1)
            (setq nest (1+ nest))
            )
           ((match-beginning 2)
            (setq nest (1- nest))
            )
           ((match-beginning 3)
            (forward-line 1)
            )
           ((match-beginning 4)
            (re-search-forward "^<'" lim 'move)
            )
           ((match-beginning 5)
            (re-search-forward "\"" lim 'move)
            )
           )
          (if (= 0 nest)
              (throw 'skip (point)))
          )
        ;; if we reached this point then the search failed
        (goto-char (point-max))
        (throw 'skip (point)))
      )
    ))

(defun specman-within-ex-code-point ()
  "Return point if within ex-code region, else nil."
  (save-excursion
    (if (re-search-backward "^\\(?:\\('>\\)\\|\\(<'\\)\\)" nil 'm)
	(if (match-beginning 2)
            nil
          (point))
      (point))))

(defun specman-within-region-comment-p ()
  "Return true if point is in a region comment:
   - either outside e-code region <'...'>
   - or in a /*...*/ comment, but not on the opening line"

  (or (specman-within-ex-code-point)
      (specman-line-within-star-comment-p)))

(defun specman-start-ex-code-point (limit)
  "Return point before comment starts if before LIMIT, else nil."
  (save-excursion
    (when (re-search-forward "^'>" limit t)
      (match-beginning 0))))

(defun specman-end-ex-code-point (limit)
  "Return point after comment ends if before LIMIT, else nil."
  (save-excursion
    (when (re-search-forward "^<'" limit t)
      (match-end 0))))

(defvar ecom-syntax-highlight nil
  "True if the current buffer is an .ecom file and should be syntax
 highlighted as such (i.e. ignore ex-code-regions).")
(make-variable-buffer-local 'ecom-syntax-highlight)

(defun specman-match-ex-code-regions (limit)
  "Match a non code block, setting match-data and returning t, else nil."
  (when (not ecom-syntax-highlight)
    (when (< (point) limit)
      (let ((start
             (or (specman-within-ex-code-point)
                 (specman-start-ex-code-point limit)))
            (case-fold-search
             t)
            (origin
             (point))
            )
        (when start
          (goto-char start)
          (let ((end
                 (or (specman-end-ex-code-point limit)
                     limit))
                )
            (goto-char end)
            (store-match-data (list start end))
            (if (= (point) origin)
                nil
              t)))))))

(defun specman-match-minus-comments (limit)
  "Match a '-- ... EOL' region, setting match-data and returning t, else nil."
  (when (< (point) limit)
    (let ((start
           (progn
             (beginning-of-line)
             (specman-search-forward-minus-comment limit)))
          )
      (when start
        (goto-char start)
        (let ((end
               (progn
                 (forward-line)
                 (if (< (point) limit)
                     (point)
                   limit)))
              )
          (store-match-data (list start end))
          t)))))

(defun specman-search-forward-long-line (limit)
  (when (< specman-max-line-length
           (current-column))
    (forward-line)) ;; so we don't return a value smaller than point
  (let ((continue
         t)
        (return-val
         nil)
        )
  (while continue
    (if (>= (point) limit)
        (setq continue nil)
      (progn
        (end-of-line)
        (if (<= (current-column)
                specman-max-line-length)
            (forward-line)
          (progn
            (setq continue nil)
            (move-to-column specman-max-line-length)
            (when (< (point) limit)
              (store-match-data (list (point) (point)))
              (setq return-val (point))))))))
  return-val))
    
(defun specman-match-beyond-max-line-length (limit)
  "Match text beyond the max line length, setting match-data and returning t, else nil."
  (when (and specman-highlight-beyond-max-line-length
             (< (point) limit))
    (let ((start
           (specman-search-forward-long-line limit))
          )
      (when start
        (let ((end
               (progn
                 (end-of-line)
                 (if (< (point) limit)
                     (point)
                   limit)))
              )
          (forward-line)
          (store-match-data (list start end))
          t)))))


;; =================================================
;; SPECMAN Hide/show comments
;; =================================================
;; seems to affect only ex-code regions.
;; TODO: can this be made to work?

;; (require 'hideif)
;; (defvar specman-comment-hiding nil "Non-nil when text may be hidden.")

;; (defun specman-toggle-hide-comments ()
;;   "Toggle the hiding of comments in Specman mode"
;;   (interactive)
  
;;   (specman-outline-comments (not specman-comment-hiding)))

;; (defun specman-outline-comments (flag)
;;   "Hide/or show block comments"
;;   (interactive)
  
;;   (let ((hif-outside-read-only buffer-read-only)
;;         (inhibit-read-only t)
;;         )
;;     (setq selective-display t)
;;     (setq hide-ifdef-hiding t)
;;     (hide-ifdef-guts))
  
;;     (setq selective-display t)
;;     (setq specman-comment-hiding (if flag t nil))
    
;;     (save-excursion
;;       (goto-char (point-min))
;;       (let ((e (point-max))
;;             )
;;         (while (and
;;                 (< (point) e)
;;                 (specman-match-ex-code-regions e))
;;           (if flag
;;               (hide-ifdef-region (match-beginning 0)
;;                                  (match-end 0))
;;             (hif-show-ifdef-region (match-beginning 0)
;;                                    (match-end 0)))))))


;; =================================================
;; SPECMAN Menus
;; =================================================
(defvar specman-xemacs-menu
  '("Specman"
    ("Move"
     ["Beginning of specification"	                specman-beg-of-defun t]
     ["End of specification"	                       	specman-end-of-defun t]
     )
    "----"
    ("Comments"
     ["Redo/insert comments on every };"                specman-redo-endcomments t]
     ["Redo/insert comments on current line"            specman-insert-auto-endcomment t]
     ["Insert -- comment"                               specman-insert-minus-comment t]
     ["Insert // comment"                               specman-insert-slash-comment t]
     ["Comment region"                                  comment-region t]
     ["UnComment region"                                specman-uncomment-region t]
     ["Exclude code region"                             specman-exclude-code-region t]
     ;;["Toggle hiding comment blocks"                    specman-toggle-hide-comments t]
     ["Realign comment"                                 specman-realign-comment t]
     )
    ("Formatting"
     ["Minor comment separator"                         specman-minor-comment-separator t]
     ["Major comment separator"                         specman-major-comment-separator t]
     ["Insert standard file header"                     specman-header t]
     ["Insert R&D file header"                          specman-development-file-header t]
     ["Insert struct/define header"                     specman-struct-and-define-header-compact t]
     ["Insert detailed struct/define header"            specman-struct-and-define-header-full t]
     ["Insert method header"                            specman-method-header-compact t]
     ["Insert detailed method header"                   specman-method-header-full t]
     ["Insert headers for all structs/defines/methods"  specman-add-struct-and-method-headers t]
     ["Insert e-code section"                           specman-open-e-code-section t]
     ["Insert e-code block"                             specman-open-e-code-block t]
     )
    "----"
    ["Specman compile"                                  specman-compile t]
    ["Make"                                             specman-make t]
    "----"
    ["Describe cursor context"                          specman-describe-context t]
    "----"
    ["Submit bug report"                                specman-submit-bug-report t]
    ["Customize Specman Mode..."                        specman-customize t]
    ["Customize Specman Fonts & Colors"                 specman-font-customize t]
    )
  "Emacs menu for SPECMAN mode."
  )

(unless (string-match "XEmacs" emacs-version)
  (easy-menu-define
    specman-menu
    specman-mode-map
    "Menu for Specman mode"
    specman-xemacs-menu))

(defun specman-customize ()
  "Link to customize screen for Specman"
  (interactive)
  (customize-group 'specman-mode)
  )

(defun specman-font-customize ()
  "Link to customize fonts used for Specman"
  (interactive)
  (customize-apropos "font-lock-*" 'faces)
  )

(defun specman-compile ()
  "Invoke compile, customized for specman"
  (interactive)
  (let ((compile-command
         (concat specman-compile-command
                 buffer-file-name))
        (compilation-read-command
         t)
        )
    (call-interactively 'compile compile-command)
    )
  )

(defun specman-make ()
  "Invoke make, customized for specman"
  (interactive)
  (let ((compile-command
         specman-make-command)
        (compilation-read-command
         t)
        )
    (call-interactively 'compile compile-command)
    )
  )

(defconst specman-beg-of-defun-query-regexp
  (concat
   "^"
   "\\(?:"
   "\\(<'\\)"
   "\\|"
   specman-top-level-container-definition-regexp
   "\\)"
   )
  "Internal - regexp used to find top level containter definitions.")

(defun specman-beg-of-defun (&optional within-code-region
                                       no-up-scope-call)
  "Move backward to the beginning of the current struct or procedure,
   or failing that - to the beginning of the e-code section in the file."
  (interactive)
  
  ;; no-up-scope-call - only to be used from within specman-up-scope to prevent recursion.
  ;; normally this should still give the same result (maybe a little slower), except
  ;; within macros.
  (unless no-up-scope-call
    (specman-up-scope within-code-region))
  
  ;; a fairly decent approximate implementation. assumes that major definitions
  ;; are properly indented to the beginning a line, so very little comment
  ;; checking is needed.
  ;;
  ;; TODO: the way this should really be done is by finding the
  ;; top-most container - i.e. the one that calling specman-up-scope
  ;; from reaches point-min.  this is very expensive in terms of
  ;; performance currently, but can be solved by handling using the
  ;; global-scope-index mechanism.  specman-scope-index-top-scope was
  ;; an attempt to do that, but it's not mature yet.
  (while (and
          ;; failure means the beginning of the buffer was reached
          (re-search-backward specman-beg-of-defun-query-regexp nil t)
          ;; failure means a major definition was matched (i.e. (match-beginning 2) is true)
          (match-beginning 1)
          ;; failure means the beginning of the buffer was reached - success repeats the search
          (re-search-backward "^'>" nil t)))
  (point)
  )

(defun specman-end-of-e-code ()
   "Move to the end of the e-code in this file."
   (interactive)
   
   (goto-char (point-max))
   (re-search-backward "\\(^'>\\)" nil t)
   )

(defun specman-end-of-defun ()
  "Move forward to the end of the current struct or procedure,
   or failing that - to the end of the e-code section in the file."
  (interactive)

  (specman-beg-of-defun)
  (if (looking-at "<'")
      (specman-end-of-e-code)
    (progn
      (specman-re-search-forward "{" (point-max) t)
      (specman-down-scope))
    )
  )

;; =================================================

(put 'specman-mode 'font-lock-defaults
     '((specman-font-lock-keywords 
        specman-font-lock-keywords-1
        specman-font-lock-keywords-2
        specman-font-lock-keywords-3)
       nil ;; nil means highlight strings & comments as well as keywords
       nil ;; nil means keywords must match case
       nil ;; syntax table handled elsewhere
       specman-beg-of-defun ;; function to move to beginning of reasonable region to highlight
       ))

;;; Hacks for FSF
(require 'font-lock)
(defvar specman-need-fld nil)
(defvar font-lock-defaults-alist nil)	;In case we are XEmacs
(if specman-need-fld
    (let ((specman-mode-defaults
	   '((specman-font-lock-keywords 
	      specman-font-lock-keywords-1
	      specman-font-lock-keywords-2
	      specman-font-lock-keywords-3)
	     nil ;; nil means highlight strings & comments as well as keywords
	     nil ;; nil means keywords must match case
	     nil ;; syntax table handled elsewhere
	     specman-beg-of-defun ;; function to move to beginning of reasonable region to highlight
	     )))
      (setq font-lock-defaults-alist
	    (append
	     font-lock-defaults-alist
	     (list (cons 'specman-mode  specman-mode-defaults)))
	    )
      (setq specman-need-fld 0)))

;; =================================================
;; SPECMAN MODE - MAIN FUNCTION
;; =================================================

(defvar specman-mode-abbrev-table nil
  "Abbrev table in use in Specman-mode buffers."
  )
(define-abbrev-table 'specman-mode-abbrev-table ())

(defun specman-mode ()
  "Major mode for editing Specman code.

Automatically indents and colorizes E code.

To submit a problem report, enter \\[specman-submit-bug-report] from a
specman mode buffer. This automatically sets up a mail buffer with
version information already added. You just need to add a description
of the problem, including a reproducible test case, and send the
message.

To tune the fonts and colors to your preference, enter
\\[specman-font-customize].

To tune other user tunable options, enter
\\[specman-customize].

Key Bindings:
=================================
\\{specman-mode-map}"
  (interactive)
  
  (kill-all-local-variables)
  (use-local-map specman-mode-map)
  (setq major-mode 'specman-mode)
  (setq mode-name "Specman")
  (setq write-file-hooks nil)
  (setq local-abbrev-table specman-mode-abbrev-table)
  (setq specman-mode-syntax-table (make-syntax-table))
  (specman-populate-syntax-table specman-mode-syntax-table)

  ;; add extra comment syntax
  (specman-setup-dual-comments specman-mode-syntax-table)
  (set-syntax-table specman-mode-syntax-table)

  ;; initializations
  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'specman-indent-line)
  (set (make-local-variable 'font-lock-defaults)
	(get 'specman-mode 'font-lock-defaults))
 
 
  (make-local-variable 'comment-start)
  (make-local-variable 'comment-end)
  (make-local-variable 'block-comment-start)
  (make-local-variable 'block-comment-end)
  (make-local-variable 'comment-multi-line)
  (make-local-variable 'comment-start-skip)
  (make-local-variable 'comment-column)
  (make-local-variable 'normal-auto-fill-function)
  (make-local-variable 'indent-region-function)
  (make-local-variable 'comment-indent-function)
  (setq comment-indent-function 'specman-comment-indent)
  (setq comment-start "// "
        comment-end ""
        comment-start-skip "\\(\\(\\(//\\)\\|\\(--\\)\\|\\(/\\*\\)\\)[ \t]*\\)"
        comment-column 48
        comment-multi-line t
        ;;normal-auto-fill-function 'specman-do-auto-fill ;; TODO: someday...
        indent-region-function 'specman-indent-region)

  (make-local-variable 'case-fold-search)
  (make-local-variable 'indent-region-function)
  (setq indent-region-function 'specman-indent-region)
  (setq case-fold-search t)

  (setq ecom-syntax-highlight
        (string-match "\\.ecom\\'"
                      (buffer-file-name)))

  ;; setup the comment indent variable in a Emacs version portable way
  ;; ignore any byte compiler warnings you might get here
  (if (boundp 'comment-indent-function)
      (progn
	(make-local-variable 'comment-indent-function)
	(setq comment-indent-function 'specman-comment-indent))
    (make-local-variable 'comment-indent-function)
    (setq comment-indent-function 'specman-comment-indent))
  
  ;; Make a menu bar
  (if (string-match "XEmacs" emacs-version)
      (progn
        (if (and current-menubar
                 (not (assoc "Specman" current-menubar)))
            (progn
              (set-buffer-menubar (copy-sequence current-menubar))
              (add-submenu nil specman-xemacs-menu))) ))
  
  ;; imenu setup - setup the function that creates the specman index
  (when specman-index-menu-active
    (setq imenu--split-submenus-enable nil)
    (setq imenu-create-index-function 'specman-imenu-create-menu)
    (imenu-add-to-menubar "Specman-Index")
    )
  
  (run-hooks 'specman-mode-hook)
  )

;; =================================================
;; SPECMAN INDENTATION
;; =================================================

(defun specman-comment-indent (&optional arg)
  "return the column number the line should be indented to."
  (cond
   ((specman-within-line-comment-p)
    
    (save-excursion
      (re-search-backward comment-start-skip nil t)
      (current-column))
    )
   (comment-column
    
    comment-column
    )
   (t
    
    (save-excursion
      (re-search-backward comment-start-skip nil t)
      (current-column))
    )
   )
  )

(defun specman-indent-line-keep-pos ()
  "Main indent function for specman-mode"
  (let ((start-pos  (specman-indent-col))
        (curr-pos   (current-column))
        offset
        )
    
    (setq offset (- curr-pos start-pos))
    (specman-indent-line)
    (move-to-column (+ (specman-indent-col)
                       offset))
    )
  )

(defun specman-indent-region (beg-region end-region)
  "Indent region for specman."
  (interactive)
  
  (message "Wait while indenting .... ")
  
  (save-excursion
    (goto-char beg-region)
    
    (when (and beg-region
               end-region)
      
      (let ((curr-line
             0)
            (num-lines
             1)
            (start-line-point
             0)
            (line-comment-indent
             nil)
            )

        (specman-create-global-scope-index)
        
	(goto-char beg-region)
	(beginning-of-line)
	(setq start-line-point (point))
        
        (goto-char end-region)
        (beginning-of-line)
        (setq num-lines
              (+ (count-lines start-line-point
                              (point))
                 1))
        
        (goto-char start-line-point)

        ;; skip any region comment in the beginning of the region,
        ;; with progress message.
        ;; TODO: inefficient - jump to the end immediately and count
        ;;       lines some other way.
        (when (specman-within-region-comment-p)
          (while (and (specman-within-region-comment-p)
                      (< curr-line
                         num-lines))
            (setq curr-line (+ curr-line 1))
            (when (= 0 (% curr-line 10))
              (message "indented %d/%d lines ..." curr-line num-lines))
            (forward-line 1))
          )

        ;; indent line (special case for full line comments)
	(while (< curr-line
                  num-lines)
          
	  (unless (or (looking-at "^[ \t]*$") ;; do nothing for an empty line
                      (specman-line-within-star-comment-or-string-p))
            (if (specman-line-within-comment-p)
                ;; use the same indent for sequences of line-comments
                (if line-comment-indent
                    (indent-line-to line-comment-indent)
                  (setq line-comment-indent (specman-indent-line t)))
               (progn
                 (when line-comment-indent
                   (setq line-comment-indent nil))
                 (specman-indent-line t)
                 )
               )
            )

          ;; print progress message
	  (setq curr-line (+ curr-line 1))
          (when (= 0 (% curr-line 10))
            (message "indented %d/%d lines ..." curr-line num-lines))
          
          (forward-line 1)
          
          ;; skip ex-code regions with progress message
          ;; TODO: have this work like the the region comment skipping
          ;;       section at the beginning.  better form and also does
          ;;       star comments (or at least will be, after the way it
          ;;       moves to the end while counting lines is rewritten).
          (when (looking-at "^'>")
            (while (and (not (looking-at "^<'"))
                        (< curr-line
                           num-lines))
              (setq curr-line (+ curr-line 1))
              (when (= 0 (% curr-line 10))
                (message "indented %d/%d lines ..." curr-line num-lines))
              (forward-line 1))
            (forward-line 1))
          )

        (specman-clear-global-scope-index)
        
	(goto-char start-line-point)
        ))
    )
  
  (message nil)
  )

(defun specman-beg-of-statement (&optional within-code-region)
  "Move to start of statement and return point"
  (let* ((lim
          (save-excursion
            (specman-up-scope within-code-region))
          )
         (found-statement-closer
          nil
          )
         (last
          (save-excursion
            ;; have to be careful here to prevent finding the end of the current
            ;; statement/action but still not entering any new scope while checking that.
            (specman-re-search-backward "[;)}]" (specman-beg-of-line-pos) t within-code-region)
            
            (unless (looking-at ";")
              (forward-char))
            
            (if (and (> (point) lim)
                     (progn
                       ;; look for a terminating ';' in the current scope
                       (while
                           (and (specman-re-search-backward "\\(;\\)\\|\\(\}\\)\\|\\(\)\\)" lim t t)
                                (cond
                                 ;; found a statement/action termination - stop with success
                                 ((match-beginning 1)
                                  (progn
                                    (setq found-statement-closer t)
                                    nil))
                                 ;; found a scope end
                                 ((match-beginning 2)
                                  (specman-up-scope t))
                                 ;; found a parens closer
                                 ((match-beginning 3)
                                  (specman-up-list t))
                                 )))
                       found-statement-closer))
                (progn
                  (forward-to-indentation 1)
                  (specman-forward-ws)
                  (point))
              (progn
                (goto-char lim)
                (if (equal (point) ;; enter the scope
                           (point-min))
                    (re-search-forward "^<'" nil t)
                  (forward-char 1))
                (specman-forward-ws)
                (forward-to-indentation 0)
                (point))))
          )
         )
    
    last
    )
  )


;; TODO: this, down to specman-add-syntax, doesn't seem to be in use
;;       and can probably be removed.
;;
;; SPECMAN - MAIN GET LINE TYPE
;; (defconst specman-offsets-alist-default
;;   '((string                . -1000)
;;     (block-open            . 0)
;;     (block-close           . 0)
;;     (statement             . 0)
;;     (statement-cont        . specman-lineup-statement-cont)
;;     (statement-block-intro . +)
;;     (statement-case-intro  . +)
;;     (case-alternative      . +)
;;     (comment               . specman-lineup-comment)
;;     (arglist-intro         . +)
;;     (arglist-cont          . 0)
;;     (arglist-cont-nonempty . specman-lineup-arglist)
;;     (arglist-close         . specman-lineup-arglist)
;;     (entity                . 0)
;;     (configuration         . 0)
;;     (package               . 0)
;;     (architecture          . 0)
;;     (package-body          . 0)
;;     )
;;   "Default settings for offsets of syntactic elements.
;; Do not change this constant!  See the variable `specman-offsets-alist' for
;; more information.")

;; (defvar specman-offsets-alist (copy-alist specman-offsets-alist-default)
;;   "*Association list of syntactic element symbols and indentation offsets.
;; Each cons cell in this list has the form:
;;     (SYNTACTIC-SYMBOL . OFFSET)")

;; (defvar specman-syntactic-context nil
;;   "Buffer local variable containing syntactic analysis list.")
;; (make-variable-buffer-local 'specman-syntactic-context)

;; (defmacro specman-add-syntax (symbol &optional relpos)
;;   "Append syntax in SYMBOL to the syntax list."
;;   `(setq specman-syntactic-context
;; 	 (cons (cons ,symbol ,relpos) specman-syntactic-context)))


(defun specman-indent-line (&optional within-code-region)
  "Indent the current line as SPECMAN code.  Returns the amount of
indentation change."
  (interactive)

  (when (or within-code-region
            (not (or (specman-within-string-p)
                     ;; the case of un-indented scope opener, which otherwise
                     ;; would be considered as being outside a code region.
                     (save-excursion
                       (beginning-of-line)
                       (looking-at "[ \t]*<'"))
                     (specman-within-region-comment-p))))
    (let* ((start-position
            (set-marker (make-marker) (point))
            )
           (indent
            (specman-get-offset within-code-region t)
            )
           (shift-amt
            (- indent
               (current-indentation))
            )
           )

      (unless (zerop shift-amt)
        (delete-region (specman-beg-of-line-pos)
                       (specman-indent-pos))
        (beginning-of-line)
        (indent-to indent))

      ;; TODO: this section deals with moving the point forward to the
      ;; new indentation when applicable.  most of the times the
      ;; function is called this isn't needed and just wastes
      ;; performance.  attempting to remove this didn't work well,
      ;; maybe because it's the indentation function for the mode.
      ;; (will replacing it with specman-indent-line-keep-pos solve
      ;; the problem?)
      (unless within-code-region
        (if (< (point)
               (specman-indent-pos))
            (back-to-indentation)
          ;; If initial point was within line's indentation, position after
          ;; the indentation.  Else stay at same point in text.
          (when (< (point) start-position)
            (goto-char start-position))))
      
      (set-marker start-position nil)
      (run-hooks 'specman-special-indent-hook)
      
      indent
      )
    )
  )

(defun specman-scope-offset (parenloc)
  "determine the amount to indent code based on the enclosing scope."
  
  (save-excursion
    (back-to-indentation)
    
    (let ((c
           (char-after)
           )
          (beg-of-line
           (point)
           )
          (uncontinued-line
           ;; NOTE: some people like to have "else {" clauses after
           ;; "if {" to also be un-indented.  this turned out to be a
           ;; problem because there are other "else" types in e
           ;; (e.g. after "check that...").  the check turns out to be
           ;; too complex to be justified.
           (looking-at "{")
           )
          )
      
      (goto-char parenloc)
      (cond

       (;; Open scope or list
	(safe-char= (char-after) ?\{)

        (let* ((beg-after-last-termination
                (save-excursion
                  (goto-char beg-of-line)
                  (or (specman-re-search-backward ";" parenloc t t)
                      (goto-char parenloc))
                  (forward-char)
                  (specman-forward-ws)
                  (point)))
               (continuing-line-offset
                (if (or uncontinued-line
                        (<= beg-of-line
                            beg-after-last-termination)) ;; not before current
                    0                                    ;; leave as is
                  specman-continued-line-offset))        ;; indent as non-terminated
               )
          (forward-char 1)
          (skip-chars-forward " \t")     ;; move position to end of whitespace
          (if (or (looking-at "//\\|--") ;; either comment
                  (eolp))                ;; or end-of-line
              (progn                     ;; indent normally
                (goto-char parenloc)
                (if (save-excursion                        ;; special case:
                      (and (specman-up-list t)             ;; scope within a parens is a
                           (safe-char= (char-after) ?\())) ;; list argument to a function
                    (back-to-indentation)                  ;; so indent according to last line
                  (goto-char (specman-beg-of-statement t)))  ;; normally indent to statement
                (if (safe-char= c ?\})
                    (current-column)
                  (+ (current-column) 
                     specman-basic-offset
                     continuing-line-offset)))
            (if (safe-char= c ?\})            ;; leave at same column as non-comment char
                (progn
                  (goto-char parenloc)
                  (current-column))
              (+ (current-column)
                 continuing-line-offset))))
        )

       (;; Inside ( )
	(safe-char= (char-after) ?\()

        (let* ((beg-after-last-termination
                (save-excursion
                  (goto-char beg-of-line)
                  (if (let ((continue-flag
                             t)
                            (result-point
                             nil)
                            )
                        ;; find a ',' not within an internal parens (which can happen
                        ;; e.g. in the scope of a logical condition).  done within
                        ;; a save-excursion scope because we may only find an ending
                        ;; parens and never a ',' and then we don't want to keep the
                        ;; position.
                        (save-excursion
                          (while (and
                                  continue-flag
                                  (specman-re-search-backward "\\(,\\)\\|\\()\\)" parenloc t t))
                            (if (match-beginning 2)
                                (specman-up-list t)
                              (progn
                                (setq continue-flag nil)
                                (setq result-point (point))))))
                        
                        (when result-point
                          (goto-char result-point))
                        
                        result-point)
                      
                      (progn
                        (forward-char)
                        (specman-forward-ws)
                        (point))
                    nil))
                )
               (continuing-line-offset
                (if (or (not beg-after-last-termination) ;; not found
                        uncontinued-line
                        (<= beg-of-line
                            beg-after-last-termination)) ;; not before current
                    0                                    ;; leave as is
                  specman-continued-line-offset))        ;; indent as non-terminated
               )

          (+ (if (safe-char= c ?\))           ;; add offset for non-terminated lines
                 0                            ;; which are not the closing parens 
               continuing-line-offset)
             (progn
               (forward-char 1)
               (skip-chars-forward " \t")     ;; move position to end of whitespace
               (if (or (looking-at "//\\|--") ;; either comment
                       (eolp))                ;; or end-of-line
                   (progn                     ;; indent normally
                     (back-to-indentation)
                     (+ (current-column)
                        specman-basic-offset))
                 (if (safe-char= c ?\))       ;; leave at same column as non-comment char
                     (progn
                       (goto-char parenloc)
                       (current-column))
                   (current-column)))))))

       (;; Inside [ ]
	(safe-char= (char-after) ?\[)
        (progn
          (forward-char 1)
          (skip-chars-forward " \t")     ;; move position to end of whitespace
          (if (or (looking-at "//\\|--") ;; either comment
                  (eolp))                ;; or end-of-line
              (progn                     ;; indent normally
                (goto-char (specman-beg-of-statement t))
                (if (safe-char= c ?\])
                    (current-column)
                  (progn
                    (+ (current-column) 
                       specman-basic-offset))))
            (if (safe-char= c ?\])       ;; leave at same column as non-comment char
                (progn
                  (goto-char parenloc)
                  (current-column))
              (current-column))))
        )

       (;; new statement
        ;; - works because the scope search always goes to the buffer
        ;;   start in this case
        (equal (point)
               (point-min))

        (let* ((beg-after-last-termination
                (save-excursion
                  (goto-char beg-of-line)
                  (or (specman-re-search-backward ";" parenloc t t)
                      (goto-char parenloc))
                  (end-of-line)
                  (specman-forward-ws)
                  (point)))
               (continuing-line-offset
                (if (<= beg-of-line
                        beg-after-last-termination)  ;; not before current
                    0                                ;; leave as is
                specman-continued-line-offset))      ;; indent as non-terminated
               )

        (beginning-of-line)
        (+ (current-column)
           continuing-line-offset))
        )
       
       (;; Everything else
	t
        
	(current-column)
        )
       )
      )
    )
  )

(defun specman-get-offset (&optional within-code-region
                                     out-of-string-quotes)
  (let (pos
        )
    (save-excursion
      (beginning-of-line)
      
      (cond
       (;; line within string
        ;; - out-of-string-quotes is an optimization to make sure that
        ;;   specman-line-within-string-p isn't called more than once,
        ;;   as it is expensive.
        (and (not out-of-string-quotes)
             (specman-line-within-string-p))
        
        0
        )
        
       (;; scope starter/closer
        (save-excursion
          (beginning-of-line)
          (looking-at "^[ \t]*\\(?:'>\\|<'\\)"))

        0
        )

       (;; search for relevant scope
        (save-excursion
          (specman-re-search-backward "\\(\\[\\)\\|\\([](){}]\\)"
                                      (save-excursion
                                        (specman-beg-of-defun within-code-region))
                                      t
                                      within-code-region))

        (cond
         (;; within square brackets
          (match-beginning 1)
          
          (specman-scope-offset (match-beginning 1))
          )
         
         (;; check if within paren
          (save-excursion
            (setq pos (specman-up-list within-code-region)))
          
          (specman-scope-offset pos)
          )
         
         (;; find scope start - common case.
          ;; always matches because specman-up-scope never returns nil
          (save-excursion
            (setq pos (specman-up-scope within-code-region)))
        
          (specman-scope-offset pos)
          )
         )
        )

       (;; corner case - not within any scope
        t

        0
        )
       )
      )
    )
  )
       

;; =================================================
;; SPECMAN - AUTO ENDCOMMENTS
;; =================================================

(defun specman-remove-encapsulation (str)
  "Remove encapsulation keyword from start of string"
  (if (string-match "^[ \t\n]*\\(private\\|package\\|protected\\)[ \t\n]+" str)
	  (replace-match "" t t str nil)
	str)
  )

;; Call this only after calling specman-remove-encapsulation()
(defun specman-format-method-comment (str)
  "Format method comment - remove parameter list and lonely is"
  (let (method-name
		(is-part-regexp "\\(is\\(?:[ \t\n]+\\(also\\|only\\|first\\|inline[ \t\n]+only\\|inline\\)\\)?\\)")
		is-what)
	(string-match (concat "\\([a-zA-Z0-9_]+\\).*" is-part-regexp) str)
	(setq 
	 method-name (concat (match-string 1 str) "()")
	 is-what (match-string 3 str))

	(if is-what
		(concat method-name " is " is-what)
	  method-name))
  )

(defun specman-kill-line-comment ()
  "Kill line comment (//|--) on this line, else return nil."
  (save-excursion
    (end-of-line)
    (let ((comment-start
           (specman-within-line-comment-p))
          )
      (when comment-start
        (goto-char comment-start)
        (delete-region comment-start (specman-end-of-line-pos))
        (delete-horizontal-space)
        t))))

(defun specman-insert-auto-endcomment (&optional kill-existing-comment
                                                 skip-scope-closer-check)
  "Add ending comment after a }; indicating what block is thereby closed.
- With KILL-EXISTING-COMMENT, remove what was there before.
- With SKIP-SCOPE-CLOSER-CHECK, skip the check."
  (interactive)

  (save-excursion
    (when (and (or skip-scope-closer-check
                   (progn
                     (beginning-of-line)
                     (specman-re-search-forward "};" (specman-end-of-line-pos) t)))
               (or kill-existing-comment
                   (save-excursion
                     (end-of-line)
                     (not (specman-within-comment-p)))))
      
      (let ((container-name-regexp
             
             specman-container-scope-definition-regexp
             )
            (skip
             
             nil
             )
            str
            scope-start
            construct-type
			)
        
        (save-excursion
          (beginning-of-line)
          (specman-up-scope)
          (setq scope-start (point))
          (goto-char (specman-beg-of-statement))

          (setq str
                (cond 
                 (;; method
                  (looking-at specman-method-definition-regexp)
                  
                  (let ((beg (match-beginning 0))
                        (end (match-end 0))
                        )
					(setq construct-type "method")
                    (specman-prepared-buffer-substring beg end))
                  )
                 (;; on event
				  (looking-at specman-on-event-method-definition-regexp)
                  (let ((beg (match-beginning 0))
                        (end (match-end 0))
                        )
					(setq construct-type "event")
                    (specman-prepared-buffer-substring beg end))
				  )

				 (;; struct, extend, unit, define
                  (looking-at container-name-regexp)
                  
                  (let ((beg (match-beginning 0))
                        (end (match-end 0))
                        )
					(setq construct-type "container")
                    (specman-prepared-buffer-substring beg end))
                  )
                 (;; stop if major scopes only
                  specman-auto-endcomments-for-major-scopes-only
                  
                  (setq skip t)
                  )
                 (;; else clause
                  (looking-at "}[ \t\n]*else")
                  
                  (progn
                    (goto-char (match-beginning 0))
                    (specman-up-scope t)
                    
                    (let ((define-end-point (point))
                          )
                      (goto-char (specman-beg-of-statement))
                      (concat "! "
                              (specman-prepared-buffer-substring (point)
                                                                 define-end-point))))
                  )
                 (;; any scope
                  t
                  
                  (specman-prepared-buffer-substring (point)
                                                     scope-start)
                  )
                 )
                ))
        
		(unless skip
		  (if construct-type
			  (setq str (specman-remove-encapsulation str)))
		  (if (string= construct-type "method")
			  (setq str (specman-format-method-comment str)))
		  (end-of-line)
          (when kill-existing-comment
            (specman-kill-line-comment))
		  ;(message "str = \"%s\"" str)
          (insert (concat
                   " -- "
                   (if (> (length str)
                          30)
                       (concat (substring str 0 30 )
                               "..." )
                     str))))
        ))))

(defun specman-electric-semicolon ()
  "Insert `;' character and reindent the line (using last-command-char -
 the activating key, `;' in this case)."
  (interactive)

  (let ((last-char (char-before)))
	(insert ";") ; Don't use last-command-char, cause this function may be called from another function
  	(when (and specman-auto-endcomments
			   (safe-char= last-char ?\} )
			   (not (specman-within-string-p))
			   (not (specman-within-comment-p)))
	  
	  (specman-insert-auto-endcomment t t))
	) ; let

  ;; TODO: is this wrong when inside a comment?
  (specman-indent-line)
  (end-of-line)
  (when specman-auto-newline
    (delete-horizontal-space)
    (newline-and-indent)))

(defun specman-redo-endcomments ()
  "Relabel all '};' tokens in the buffer with the reason for the scope."
  (interactive)
  
  (specman-redo-endcomments-internal (point-min-marker)
                                     (point-max-marker)
                                     specman-auto-endcomments-kill-existing-comment))

(defun specman-redo-endcomments-for-region (beg end)
  "Relabel all '};' tokens in the given region with the reason for the scope."
  (interactive "r")
  
  (specman-redo-endcomments-internal beg
                                     end
                                     specman-auto-endcomments-kill-existing-comment))

(defun specman-redo-endcomments-internal (beg
                                          end
                                          &optional kill-existing-end-comment)
  "Relabel all '};' tokens in the region with the reason for the scope.
With KILL-EXISTING-END-COMMENT, first kill any existing labels."

  (let ((counter
         0)
        
        (oldpos
         (point))
        )
    
    (goto-char beg)
    
    (if (> (- end beg)
           200)
        (message "Redoing end-comments"))

    (specman-skip-forward-comment-or-string)
    (setq counter
          (count-lines beg (point)))
    
    (while (and (> end (point))
                (specman-re-search-forward "};" nil t t))
      (specman-insert-auto-endcomment kill-existing-end-comment)
      (setq counter (1+ counter))
      (if (= 0 (% counter 10))
          (message "%d lines autocommented" counter)))
    
    (goto-char oldpos)
    
    (message  "%d lines autocommented" counter)
    ))

;; =================================================
;; SPECMAN - INSERT SPECIAL CHARS
;; =================================================

(defun specman-insert-newline ()
  "Insert newline and indent."
  (interactive)
  (newline)
  (specman-indent-line))

(defun specman-activate-indent ()
  "Just indent line and go to its beginning."
  (interactive)
  (specman-indent-line)
  (back-to-indentation))

(defun specman-insert-curly-opener ()
  "Insert { and indent."
  (interactive)
  (insert "{")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-curly-closer ()
  "Insert } and indent."
  (interactive)
  (insert "}")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-minus ()
  "Insert - and indent."
  (interactive)
  (insert "-")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-slash ()
  "Insert / and indent."
  (interactive)
  (insert "/")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-parens-opener ()
  "Insert ( and indent."
  (interactive)
  (insert "(")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-parens-closer ()
  "Insert ) and indent."
  (interactive)
  (insert ")")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-bracket-opener ()
  "Insert [ and indent."
  (interactive)
  (insert "[")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-bracket-closer ()
  "Insert ] and indent."
  (interactive)
  (insert "]")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-tick ()
  "Insert ' and indent."
  (interactive)
  (insert "'")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-lt ()
  "Insert < and indent."
  (interactive)
  (insert "<")
  (specman-indent-line-keep-pos)
  )

(defun specman-insert-gt ()
  "Insert > and indent."
  (interactive)
  (insert ">")
  (specman-indent-line-keep-pos)
  )

(defun specman-yank ()
  "Yank (paste) and indent"
  (interactive)
  ;; Need this because of bug in emacs: when another function calls
  ;; yank-clipboard-selection it does not overwrite selected text, but when it
  ;; is invoked by a key command it does.
  (if (selection-owner-p)
	  (delete-primary-selection))

  (setq start (line-number))
  (yank-clipboard-selection)
  (setq end (line-number))
  (save-excursion
	(goto-line start)
	(while (<= (line-number) end)
	  (specman-activate-indent)
	  (forward-line 1))
	)
  )


;; -----------------------------------------------------------------------------
;;  Scope Queries
;; -----------------------------------------------------------------------------
(defun specman-describe-context ()
  "Show the struct and method scope (as applicable) of the current cursor
 position"
  (interactive)

  (let ((method-name-regexp
         (concat "\\(?:"
                 specman-method-definition-regexp
                 "\\|"
                 specman-on-event-method-definition-regexp
                 "\\)"))
        (container-name-regexp
         specman-container-scope-definition-regexp)
        (description-list
         nil)
        )

    (save-excursion
      (specman-up-scope)
      
      (while (> (point) (point-min))
        
        (goto-char (specman-beg-of-statement t))
        
        (cond
         ((looking-at container-name-regexp)
          
          (push (specman-prepared-buffer-substring (match-beginning 1)
                                                   (match-end 1))
                description-list)
          )
         ((looking-at method-name-regexp)
          
          (if (looking-at specman-method-definition-regexp)
              (progn
                (back-to-indentation)
                (push (concat
                       "method "
                       (specman-prepared-buffer-substring (match-beginning 1)
                                                          (match-end 1)))
                      description-list))
            (progn
            (back-to-indentation)
            (assert (looking-at specman-on-event-method-definition-regexp))
            (push (specman-prepared-buffer-substring (match-beginning 1)
                                                     (match-end 1))
                  description-list)))
          )
         )
        (specman-up-scope t)
        )
      
      (if description-list
          (message (mapconcat 'identity description-list " / "))
        (message "Not within any relevant scope"))
      )))


;--============================================================================--
;;  Code Formatting
;--============================================================================--

;; -----------------------------------------------------------------------------
(defun specman-comment-line-w-minus ()
  "Insert a -- comment before the current line and reindent it."
  (interactive)

  (indent-according-to-mode)
  (back-to-indentation)
  (insert "--  "))

;; -----------------------------------------------------------------------------
(defun specman-comment-line-w-slash ()
  "Insert a // comment before the current line and reindent it."
  (interactive)

  (indent-according-to-mode)
  (back-to-indentation)
  (insert "//  "))

;; -----------------------------------------------------------------------------
(defun specman-exclude-code-region (beg end)
  "Comment a code section by excluding it using Specman code brackets <''>."
  (interactive "r")

  (goto-char beg)
  (beginning-of-line)
  (insert "'>\n")
  (goto-char end)
  (forward-line 1)
  (beginning-of-line)
  (insert "<'\n"))

;; -----------------------------------------------------------------------------
(defun specman-uncomment-region (beg end)
  "Uncomment the given region by removing the first 2 chars of every line."
  (interactive "r")

  ;; original implementation - simple but dumb
  ;;(comment-region beg end '-2)
  ;;(indent-region beg end nil))
  
  (let ((end-marker
         (set-marker (make-marker) end))
        )
    (goto-char beg)
  
    (while (< (point)
              end-marker)
    (when (specman-line-within-comment-p)
      (comment-region (specman-beg-of-line-pos)
                      (specman-end-of-line-pos)
                      -2))
    (specman-indent-line)
    (forward-line 1))
  
    (set-marker end-marker nil)))

;; -----------------------------------------------------------------------------
(defun specman-minor-comment-separator ()
  "Insert minuses from the cursor to the maximum line length,
never less than 2 characters."
  (interactive)

  (let ((cur-col
         (current-column))
        (counter
         (- specman-max-line-length (current-column)))
        )
    (when (<= cur-col
            (- specman-max-line-length 2))
        (while (> counter 0)
          (progn
            (insert "-")
            (setq counter (- counter 1)))))
    (newline)
    (indent-to-left-margin)
    (indent-to cur-col)))

;; -----------------------------------------------------------------------------
(defun specman-major-comment-separator ()
  "Insert a comment line of '=', prefixed and suffixed by '--',
never less than 4 characters."
  (interactive)

  (let ((cur-col
         (current-column))
        (counter
         (- specman-max-line-length (current-column) 4))
       )
    (when (<= cur-col
              (- specman-max-line-length 4))
        (progn
          (insert "--")
          (while (> counter 0)
            (insert "=")
            (setq counter (- counter 1)))
          (insert "--")))
    (newline)
    (indent-to-left-margin)
    (indent-to cur-col)))

;; -----------------------------------------------------------------------------
(defun specman-development-file-header ()
  "Insert a Specman R&D file header."
  (interactive)
  
  (goto-char 0)
  (insert "\

--------------------------------------------------------------------------------
  Copyright (c) <year> by Cadence. This model is the confidential and
  proprietary property of Cadence and the possession or use of this file
  requires a written license from Cadence.
--------------------------------------------------------------------------------


--============================================================================--
  Title :  <title>
  Team  :  <team>

  File  :  <filename>
--============================================================================--
  Description:
  <description>
--============================================================================--


  ")
  
  (indent-according-to-mode)
  (goto-char 0)
  (search-forward "<year>")
  (replace-match "" t t)
  (specman-insert-year)
  (let (string)
    (setq string (read-string "title: "))
    (search-forward "<title>")
    (replace-match string t t)
    (setq string (read-string "team: "))
    (search-forward "<team>")
    (replace-match string t t)
    (search-forward "<filename>")
    (replace-match (file-name-nondirectory (buffer-file-name)) t t)
    (search-forward "<description>")
    (replace-match "" t t)))

;; -----------------------------------------------------------------------------
(defun specman-struct-and-define-header-compact ()
  "Create a compact struct/define header."
  (interactive)
  (specman-struct-and-define-header-internal nil t))

(defun specman-struct-and-define-header-full ()
  "Create a documented struct/define header."
  (interactive)
  (specman-struct-and-define-header-internal nil nil))

(defun specman-struct-and-define-header-internal (current-line compact-header)
  "Create a struct/define header above the current line.  compact-header includes
the struct/define name only, otherwise a full header with comments."

  (if (not (or (and current-line  ;; better performance without search
                    (progn
                      (beginning-of-line)
                      t))
               (and (forward-line) ;; so as to check also current line
                    (specman-re-search-backward (concat
                                                 "^[ \t]*\\("
                                                 
                                                 "\\("
                                                 specman-class-definition-regexp
                                                 "\\)\\|\\("
                                                 specman-define-regexp
                                                 "\\)"
                                                 
                                                 "\\)")
                                                nil
                                                t))))
          
      (message "No struct/define definition found above current position ...")
    
    (let ((struct-name
           (cond
            ((looking-at specman-class-definition-regexp-full)
               
             (specman-prepared-buffer-substring (match-beginning 1)
                                                (match-end 1))
             )
            ((looking-at specman-define-regexp-full)
               
             (specman-prepared-buffer-substring (match-beginning 1)
                                                (match-end 1))
             )
            (t
             (error "Struct/Define definition match failed ...")
             )
            )
           )
          (header-indent
           0)
          )

      ;; go backward over any comments and add a newline if there is no empty
      ;; line there.
      (forward-line -1)
      (back-to-indentation)
      (while (looking-at "//\\|--")
        (forward-line -1)
        (back-to-indentation))
      (when (not (looking-at "[ \t]*$"))
        (end-of-line)
        (specman-insert-newline))
      (forward-line 1)
      (beginning-of-line)

      (if (looking-at "^[ \t]*--=*--\\(\n[ \t]*--[^\n]*\\)+\n[ \t]*--=*--")
          (message (format "Skipping definition of \"%s\" - it already has a header." struct-name))
        (progn
          ;; add the header
          (indent-according-to-mode)
          (setq header-indent (current-column))
          (specman-major-comment-separator)
          (let ((start
                 (point))
                )
            (if compact-header
                (progn
                  (indent-to-left-margin)
                  (insert "\
--  <struct>
")

                  (forward-line -2)
                  (for i from 1 to 2 do (progn
                                          (forward-line)
                                          (indent-to header-indent)))
                  (specman-major-comment-separator)
                  (goto-char start)
                  (search-forward "<struct>")
                  (replace-match struct-name t t)
                  (end-of-line))
              (progn
              (indent-to-left-margin)
              (insert "\
--  Struct      :  <struct>
--  Description :  <description>
--  Note        :  <note>
")
              (forward-line -4)
              (for i from 1 to 4 do (progn
                                      (forward-line)
                                      (indent-to header-indent)))
              (specman-major-comment-separator)
              (goto-char start)
              (search-forward "<struct>")
              (replace-match struct-name t t)
        
              (let ((indent
                     (save-excursion
                       (forward-line 1)
                       (back-to-indentation)
                       (current-column)))
                    (specman-buffer
                     (current-buffer))
                    next-buffer
                    )
                (search-forward "<note>")
                (specman-comment-start-entry "Note"
                                             "<Note> "
                                             "--              :  "
                                             indent
                                             (set-marker (make-marker) (match-beginning 0))
                                             t
                                             specman-buffer
                                             nil
                                             (set-marker (make-marker) (match-end 0)))
                (setq next-buffer (current-buffer))
                (switch-to-buffer-other-window specman-buffer)
                (goto-char start)
                (search-forward "<description>")
                (specman-comment-start-entry "Description"
                                             "<Description> "
                                             "--              :  "
                                             indent
                                             (set-marker (make-marker) (match-beginning 0))
                                             t
                                             next-buffer
                                             t
                                             (set-marker (make-marker) (match-end 0))))
              ))))))))

;; -----------------------------------------------------------------------------
(defun specman-method-header-compact ()
  "Create a compact method header."
  (interactive)
  (specman-method-header-internal nil t))

(defun specman-method-header-full ()
  "Create a documented method header."
  (interactive)
  (specman-method-header-internal nil nil))

(defun specman-method-header-internal (current-line compact-header)
  "Create a method header above the current line.  compact-header includes the
method name only, otherwise a full header with comments."

  (if (not (or (and current-line  ;; better performance without search
                    (progn
                      (beginning-of-line)
                      t))
               (and (forward-line) ;; so as to check also current line
                    (specman-re-search-backward (concat
                                                 "^[ \t]*\\("
                                                 
                                                 "\\("
                                                 specman-method-definition-regexp
                                                 "\\)\\|\\("
                                                 specman-on-event-method-definition-regexp
                                                 "\\)"
                                                 
                                                 "\\)")
                                                nil
                                                t))))
      
      (message "No method definition found above current position ...")
        
    (let ((method-name
           (cond
            ((looking-at specman-method-definition-regexp-full)
               
             (specman-prepared-buffer-substring (match-beginning 1)
                                                (match-end 1))
             )
            ((looking-at specman-on-event-method-definition-regexp-full)
               
             (specman-prepared-buffer-substring (match-beginning 1)
                                                (match-end 1))
             )
            (t
             (error "Method definition match failed ...")
             )
            )
           )
          (header-indent
           0)
          )

      ;; go backward over any comments and add a newline if there is no empty
      ;; line there.
      (forward-line -1)
      (back-to-indentation)
      (while (looking-at "//\\|--")
        (forward-line -1)
        (back-to-indentation))
      (when (not (looking-at "[ \t]*$"))
        (end-of-line)
        (specman-insert-newline))
      (forward-line 1)
      (beginning-of-line)

      (if (looking-at "^[ \t]*--+\\(\n[ \t]*--[^\n]*\\)+\n[ \t]*--+")
          (message (format "Skipping method \"%s\" - it already has a header." method-name))
        (progn
          ;; add the header
          (indent-according-to-mode)
          (setq header-indent (current-column))
          (specman-minor-comment-separator)
          (let ((start
                 (point))
                )
            (if compact-header
                (progn
                  (indent-to-left-margin)
                  (insert "\
--  <method>
")
                  (forward-line -2)
                  (for i from 1 to 2 do (progn
                                          (forward-line)
                                      (indent-to header-indent)))
                  (specman-minor-comment-separator)
                  (goto-char start)
                  (search-forward "<method>")
                  (replace-match method-name t t)
                  (end-of-line))
              (progn
                (indent-to-left-margin)
                (insert "\
--  Method      :  <method>
--  Description :  <description>
--  Parameters  :  <parameters>
--  Return Val  :  <return val>
--  Note        :  <note>
")
                (forward-line -6)
                (for i from 1 to 6 do (progn
                                        (forward-line)
                                        (indent-to header-indent)))
                (specman-minor-comment-separator)
                (goto-char start)
                (search-forward "<method>")
                (replace-match method-name t t)

                (let ((indent
                       (save-excursion
                         (forward-line 1)
                         (back-to-indentation)
                         (current-column)))
                      (specman-buffer
                       (current-buffer))
                      next-buffer
                      )
                  (search-forward "<note>")
                  (specman-comment-start-entry "Note"
                                               "<Note> "
                                               "--              :  "
                                               indent
                                               (set-marker (make-marker) (match-beginning 0))
                                               t
                                               specman-buffer
                                               nil
                                               (set-marker (make-marker) (match-end 0)))
                  (setq next-buffer (current-buffer))
                  (switch-to-buffer-other-window specman-buffer)
                  (goto-char start)
                  (search-forward "<return val>")
                  (specman-comment-start-entry "Return-Val"
                                               "<Return Val> "
                                               "--              :  "
                                               indent
                                               (set-marker (make-marker) (match-beginning 0))
                                               t
                                               next-buffer
                                               t
                                               (set-marker (make-marker) (match-end 0)))
                  (setq next-buffer (current-buffer))
                  (switch-to-buffer-other-window specman-buffer)
                  (goto-char start)
                  (search-forward "<parameters>")
                  (specman-comment-start-entry "Parameters"
                                               "<Parameters> "
                                               "--              :  "
                                               indent
                                               (set-marker (make-marker) (match-beginning 0))
                                               t
                                               next-buffer
                                               t
                                               (set-marker (make-marker) (match-end 0)))
                  (setq next-buffer (current-buffer))
                  (switch-to-buffer-other-window specman-buffer)
                  (goto-char start)
                  (search-forward "<description>")
                  (specman-comment-start-entry "Description"
                                               "<Description> "
                                               "--              :  "
                                               indent
                                               (set-marker (make-marker) (match-beginning 0))
                                               t
                                               next-buffer
                                               t
                                               (set-marker (make-marker) (match-end 0)))
                  )))))))))

;; -----------------------------------------------------------------------------
(defun specman-add-struct-and-method-headers ()
  "Open struct and method headers for the entire buffer."
  (interactive)

  (let ((main-regexp
         (concat
          "^[ \t]*\\("
          
          "\\("
          specman-class-definition-regexp
          "\\)\\|\\("
          specman-define-regexp
          "\\)\\|\\("
          specman-method-definition-regexp
          "\\)\\|\\("
          specman-on-event-method-definition-regexp
          "\\)"
          
          "\\)"))
        (counter
         0)
        )
    
    (save-excursion
      (goto-char (point-max))
      (specman-skip-backward-comment-or-string)
      (while (specman-re-search-backward main-regexp nil t t)
        (setq counter (1+ counter))
        (when (= 0 (% counter 10))
          (message "%d headers ..." counter))
        (save-excursion
          (if (or (looking-at specman-class-definition-regexp-full)
                  (looking-at specman-define-regexp-full))
              (specman-struct-and-define-header-internal t t)
              (specman-method-header-internal t t))))
      )
    (message "%d headers processed" counter)
    )
  )


;; -----------------------------------------------------------------------------
(defun specman-open-e-code-section ()
  "Open a new e-code section.  If already in a code section, start a new one."
  (interactive)

  (if (not (specman-within-ex-code-point))
      
      ;; already in code region - find the end, creating it if necessary
      (progn
        (unless (re-search-forward "^'>$" nil t)
          (goto-char (point-max))
          (newline)
          (insert "'>"))
        (newline)
        (newline))

    (progn
      (beginning-of-line)
      
      (cond (;; was on the closer, jump to the next line
             (looking-at "'>")
             
             (end-of-line)
             (newline)
             )
            (;; not on an empty line, move it down
             (looking-at ".*[^ \t]+")
             
             (newline)
             (previous-line 1)
             )
            )
      
      (newline)
      (previous-line 1)))

;  (insert "<'") (indent-according-to-mode)
;  (end-of-line) (newline)
;  (insert "'>") (indent-according-to-mode)
;  (previous-line 1) (end-of-line)
;  (specman-insert-newline)

  (insert "<'") (newline 4)
  (insert "'>")
  (previous-line 2)
  )

;; -----------------------------------------------------------------------------
(defun specman-open-e-code-block ()
  "Open code block"
  (interactive)

  ;; add a space between the opening parens and the last
  ;; word, if needed.
  (when (not (or (equal (char-before) ? )
                 (equal (char-before) ?\t)))
    (insert " "))
  
  (insert "{") (indent-according-to-mode)
  (end-of-line) (newline)
  (insert "}") 
  (specman-electric-semicolon)
  (indent-according-to-mode)
  (previous-line 1) (end-of-line)
  (specman-insert-newline))

;; -----------------------------------------------------------------------------
(defun yook-specman-open-e-code-block ()
  "Open code block and sometimes a comment after it(not implemented yet)"
  (interactive)
  
  ;; add a space between the opening parens and the last
  ;; word, if needed.
  (when (not (or (equal (char-before) ? )
				 (equal (char-before) ?\t)))
    (insert " "))
  
  (insert "{") (indent-according-to-mode)
  (end-of-line) (newline)
  (insert "};") (indent-according-to-mode)
  (previous-line 1) (end-of-line)
  (specman-insert-newline))


;; -----------------------------------------------------------------------------
(defun specman-realign-comment ()
  "If the comment in the current line is longer than specman-max-line-length,
break it into several lines, so that specman-max-line-length is respected
as much as possible.  comment style is preserved."
  (interactive)

  (if (save-excursion
        (beginning-of-line)
        (not (re-search-forward "[^ \t]" (specman-end-of-line-pos) t)))

      ;; warn if empty line
      (message "realign-comment doesn't work on empty lines.")

    ;; otherwise realign-comment
    (let* ((comment-prefix
            (progn
              (beginning-of-line)
              (or (re-search-forward "\\(\/\/+[ \t]*\\|\-\-+[ \t]*\\)[^ \t]"
                                     (specman-end-of-line-pos)
                                     t)
                  (re-search-forward "\\(\\)[^ \t]" ;; the empty match is for buffer-substring
                                     (specman-end-of-line-pos)
                                     t))
              (buffer-substring (match-beginning 1) (match-end 1)))
            )
           (comment-column
            (save-excursion
              (goto-char (match-beginning 1))
              (current-column))
            )
           )
      
      (skip-chars-forward "^ \t\n") ;; end of first word in comment line
      
      (while (not (looking-at "[ \t]*$"))
        (if (save-excursion
              (skip-chars-forward " \t")
              (skip-chars-forward "^ \t\n")
              (> (current-column)
                 specman-max-line-length))
            (progn
              (newline)
              (insert (make-string comment-column ?\ ))
              (insert comment-prefix)
              (re-search-forward "[ \t]*")
              (replace-match "" t)))
        (skip-chars-forward " \t")
        (skip-chars-forward "^ \t\n")) ;; end of first word in comment line
      
      (if (not (eolp))
          (progn
            (kill-line)
            (newline)
            (previous-line 1)
            (end-of-line)))
      )))

;; -----------------------------------------------------------------------------
(defun specman-insert-comment (prefix)
  "Insert a comment in the current location.  A comment buffer is opened for
   text editing with auto-fill mode (line length being handled automatically).
   The comment style is preserved if already entered."

  (specman-comment-start-entry "Entry"
                               "<Comment Entry> "
                               prefix
                               (current-column)
                               (set-marker (make-marker) (point))))

(defun specman-insert-minus-comment ()
  "Start entry of a -- comment, or if currently inside a comment - edit it."
  (interactive)
  (if (specman-within-comment-p)
      (specman-reedit-comment)
    (specman-insert-comment "--  ")))

(defun specman-insert-slash-comment ()
  "Start entry of a // comment, or if currently inside a comment - edit it."
  (interactive)
  (if (specman-within-comment-p)
      (specman-reedit-comment)
    (specman-insert-comment "//  ")))

;; -----------------------------------------------------------------------------
(defun specman-internal-is-matching-comment-line (comment-column comment-prefix)
  "used in specman-reedit-comment to find all lines matching the current comment
style.  returns:
- nil   - match failed.
- clean - a line with a matching comment only.
- first - a line with text that ends with a matching comment, so a first line."
  (save-excursion
    (end-of-line)
    (if (> comment-column
           (current-column))
        nil
      (progn
        (forward-char (- comment-column
                         (current-column)))
        (and (looking-at comment-prefix)
             (if (re-search-backward "[^ \t]" (specman-beg-of-line-pos) t)
                 'first
               'clean))))))

(defun specman-reedit-comment ()

  (let (comment-text
        comment-prefix
        comment-column
        (beg-marker (make-marker))
        (end-marker (make-marker))
        )
    (or
     ;; an ex-code region comment
     (save-excursion
       (and (if (re-search-backward "^\\(?:\\('>\\)\\|\\(<'\\)\\)" nil t)
                (match-beginning 1)
              (goto-char (point-min)))
            (progn
              (if (looking-at "'>")
                  (forward-line))
              (set-marker beg-marker (point))
              (or (and (re-search-forward "^<'" nil t)
                       (goto-char (match-beginning 0)))
                  (goto-char (point-max)))
              (set-marker end-marker (point))
                
              (setq comment-text (buffer-substring beg-marker
                                                   end-marker))
              (setq comment-prefix "")
              (setq comment-column 0)
              )))
     ;; normal comment
     (progn
       ;; comment prefix
       (beginning-of-line)
       ;;(re-search-forward "\\(\/\/+[ \t]*\\|\-\-+[ \t]*\\)[^ \t]"
       (re-search-forward "\\(\/\/+[ \t]*\\|\-\-+[ \t]*\\)"
                          (specman-end-of-line-pos)
                          nil)
       (setq comment-prefix (buffer-substring (match-beginning 1)
                                                (match-end 1)))
       ;; comment column
       (save-excursion
         (goto-char (match-beginning 1))
         (setq comment-column (current-column)))
       ;; mark comment region
       (while (specman-internal-is-matching-comment-line comment-column
                                                         comment-prefix)
         (forward-line -1))
       (forward-line)
       (re-search-forward comment-prefix (specman-end-of-line-pos) nil)
       (goto-char (match-beginning 0))
         
       (set-marker beg-marker (point))
       (setq comment-text (buffer-substring (match-end 0)
                                            (specman-end-of-line-pos)))
       (end-of-line)
       (set-marker end-marker (point))
         
       (forward-line)
       (while
           (equal (specman-internal-is-matching-comment-line comment-column
                                                             comment-prefix)
                  'clean)
         (re-search-forward comment-prefix (specman-end-of-line-pos) nil)
         (setq comment-text
               (concat comment-text
                       "\n"
                       (buffer-substring (match-end 0)
                                         (specman-end-of-line-pos))))
         (set-marker end-marker (specman-end-of-line-pos))
         (forward-line))
       )
     )

    (specman-comment-start-entry "Comment-Edit"
                                 "<Comment Edit> "
                                 comment-prefix
                                 comment-column
                                 beg-marker
                                 nil
                                 (current-buffer)
                                 nil
                                 end-marker
                                 comment-text)
    ))
  

;; -----------------------------------------------------------------------------
;; provide a specman-header function.
;; -----------------------------------------------------------------------------


(defun specman-header ()
  "Insert a standard Specman file header."
  (interactive)
  (let ((start (point)))
  (insert "\
//-----------------------------------------------------------------------------
// Title         : <title>
// Project       : <project>
//-----------------------------------------------------------------------------
// File          : <filename>
// Author        : <author>
// Created       : <credate>
// Last modified : <moddate>
//-----------------------------------------------------------------------------
// Description :
// <description>
//-----------------------------------------------------------------------------
// Copyright (c) <copydate> by <company>. This model is the confidential and
// proprietary property of <company> and the possession or use of this
// file requires a written license from <company>.
//------------------------------------------------------------------------------
// Modification history :
// <modhist>
//-----------------------------------------------------------------------------

")
    (goto-char start)
    (search-forward "<filename>")
    (replace-match (buffer-name) t t)
    (search-forward "<author>") (replace-match "" t t)
    (insert (user-full-name))
    (insert "  <" (user-login-name) "@" (system-name) ">")
    (search-forward "<credate>") (replace-match "" t t)
    (specman-insert-date)
    (search-forward "<moddate>") (replace-match "" t t)
    (specman-insert-date)
    (search-forward "<copydate>") (replace-match "" t t)
    (specman-insert-year)
    (search-forward "<modhist>") (replace-match "" t t)
    (specman-insert-date)
    (insert " : created")
    (goto-char start)
    (let (string)
      (setq string (read-string "title: "))
      (search-forward "<title>")
      (replace-match string t t)
      (setq string (read-string "project: " specman-project))
      (make-variable-buffer-local 'specman-project)
      (setq specman-project string)
      (search-forward "<project>")
      (replace-match string t t)
      (setq string (read-string "Company: " specman-company))
      (make-variable-buffer-local 'specman-company)
      (setq specman-company string)
      (search-forward "<company>")
      (replace-match string t t)
      (search-forward "<company>")
      (replace-match string t t)
      (search-forward "<company>")
      (replace-match string t t)
      (search-backward "<description>")
      (replace-match "" t t)
  )))

;; specman-header Uses the specman-insert-date function

(defun specman-insert-date ()
  "Insert date from the system."
  (interactive)
  (let ((timpos)
        )
    (setq timpos (point))
    (if specman-date-scientific-format
	(shell-command  "date \"+@%Y/%m/%d\"" t)
      (shell-command  "date \"+@%d.%m.%Y\"" t))
    (search-forward "@")
    (delete-region timpos (point))
    (end-of-line))
  (delete-char 1))

(defun specman-insert-year ()
  "Insert year from the system."
  (interactive)
  (let ((timpos)
        )
    (setq timpos (point))
    (shell-command  "date \"+@%Y\"" t)
    (search-forward "@")
    (delete-region timpos (point))
    (end-of-line))
  (delete-char 1))


;--============================================================================--
;; Bug reporting
;--============================================================================--

(require 'reporter)

(defun specman-submit-bug-report ()
  "Submit via mail a bug report on specman-mode.el"
  (interactive)
  (let ((reporter-prompt-for-summary-p t))
    (reporter-submit-bug-report
     "support@cadence.com"
     (concat "specman-mode v" (substring specman-mode-version 12 -3))
     '(
       specman-basic-offset
       specman-continued-line-offset
       specman-line-up-bracket
       specman-line-up-paren
       specman-auto-newline
       specman-tab-width
       specman-date-scientific-format
       specman-company
       specman-project
       )
     nil nil
     (concat "Hello,

I want to report a bug.  I've read the `Bugs' section of `Info' on
Emacs, so I know how to make a clear and unambiguous report.  To get
to that Info section, I typed

M-x info RET m " invocation-name " RET m bugs RET

Before I go further, I want to say that Specman mode has changed my
life.  I save so much time, my files are colored nicely, my co workers
finally respect my coding ability... until now.  I'd really appreciate
anything you could do to help me out with this extremely minor
deficiency in the product.

To reproduce the bug, start a fresh Emacs via " invocation-name "
-no-init-file -no-site-file'.  In a new buffer, in specman mode, type
the code included below.

Given those lines, I expected 

  TELL ME WHAT YOU EXPECTED

to happen;
but instead, 

  TELL ME THE BAD THING THAT HAPPENED

happens!.

  GIVE ME CODE SUFFICIENT TO DEMONSTRATE THE PROBLEM

== The code: =="))))



;; =============================================================================
;; SPECMAN COMMENT MODE
;; =============================================================================

;; -----------------------------------------------------------------------------
;; The major mode function.
;;

(defun specman-comment-mode ()
  "Major mode for editing comments for Specman.

While you are entering a comment for a version, the following
additional bindings will be in effect.

\\[specman-comment-finish]           proceed with check in, ending comment

Entry to the specman-comment-mode calls the value of text-mode-hook, then
the value of specman-comment-mode-hook.

Global user options:
"
  (interactive)

  ;; Major modes are supposed to just (kill-all-local-variables)
  ;; but we rely on specman-comment-parent-buffer already having been set
  ;;
  ;;(let ((parent specman-comment-parent-buffer))
  ;;  (kill-all-local-variables)
  ;;  (set (make-local-variable 'specman-comment-parent-buffer) parent))

  (setq major-mode 'specman-comment-mode)
  (setq mode-name "Specman/Comment")

  (set-syntax-table text-mode-syntax-table)
  (use-local-map specman-comment-mode-map)
  (setq local-abbrev-table text-mode-abbrev-table)

  (make-local-variable 'specman-comment-operands)

  (set-buffer-modified-p nil)
  (setq buffer-file-name nil)
  (run-hooks 'text-mode-hook 'specman-comment-mode-hook))

;; -----------------------------------------------------------------------------
;; The keymap.
;;

(defvar specman-comment-mode-map nil)
(if specman-comment-mode-map
    nil
  (setq specman-comment-mode-map (make-sparse-keymap))
  (define-key specman-comment-mode-map "\C-c\C-c" 'specman-comment-finish))

;; -----------------------------------------------------------------------------
;; Constants.
;;

;; -----------------------------------------------------------------------------
;; Variables.
;;

(defvar specman-comment-prefix nil)
(defvar specman-comment-indent nil)
(defvar specman-comment-ignore-first-line-prefix nil)
(defvar specman-comment-window-config nil)
(defvar specman-comment-chained-comment nil)

(defvar specman-comment-begin-mark nil)
(defvar specman-comment-end-mark nil)

;; In several contexts, this is a local variable that points to the buffer for
;; which it was made (either a file, or a Specman dired buffer).
;;
(defvar specman-comment-parent-buffer nil)

(make-variable-buffer-local 'specman-comment-prefix)
(make-variable-buffer-local 'specman-comment-indent)
(make-variable-buffer-local 'specman-comment-ignore-first-line-prefix)
(make-variable-buffer-local 'specman-comment-window-config)
(make-variable-buffer-local 'specman-comment-chained-comment)
(make-variable-buffer-local 'specman-comment-begin-mark)
(make-variable-buffer-local 'specman-comment-end-mark)
(make-variable-buffer-local 'specman-comment-parent-buffer)

;; -----------------------------------------------------------------------------
;; Commands and functions
;;

;; -----------------------------------------------------------------------------
(defun specman-comment-start-entry (uniquifier
                                    prompt
                                    prefix
                                    indent
                                    beg-mark
                                    &optional ignore-first
                                              parent-buffer
                                              chained-comment
                                              end-mark
                                              comment-seed)

  "Accept a comment by popping up a specman-comment-mode buffer
with a name derived from UNIQUIFIER, and emitting PROMPT in the minibuffer.

The argument PREFIX is added before all lines except the first, with INDENT
spaces added before it.

the BEG-MARK specifies where the comment text should be inserted, with an optional
END-MARK allowing replacement instead of insertion.

Optional 6th argument specifies to not add the prefix to the first line when non-nil.

Optional 7th argument specifies a PARENT-BUFFER to return to when the operation
is complete.

Optional 8th argument specifies if the window configuration should be restored,
which is true for normal comment buffers but false for chained comment buffers
(those where a comment buffer when finished passes focus to another one).

Optional 10th argument specifies a COMMENT-SEED to insert in the comment buffer for
the user to edit."

  (let ((comment-buffer     (get-buffer-create (format "*Comment-%s*" uniquifier)))
        (old-window-config  (current-window-configuration))
        (parent             (or parent-buffer
                                (current-buffer)))
        )
    (pop-to-buffer comment-buffer)

    (setq specman-comment-window-config             old-window-config)
    (setq specman-comment-parent-buffer             parent)
    (setq specman-comment-prefix                    prefix)
    (setq specman-comment-indent                    indent)
    (setq specman-comment-ignore-first-line-prefix  ignore-first)
    (setq specman-comment-begin-mark                beg-mark)
    (setq specman-comment-end-mark                  end-mark)
    (setq specman-comment-chained-comment           chained-comment)

    (setq pop-up-windows t)

    (specman-comment-mode)
    (auto-fill-mode 1)
    (setq fill-column (- specman-max-line-length
                         indent
                         (length prefix)))
    
    (if comment-seed
        (insert comment-seed))
    
    (message "%s  Type C-c C-c when done." prompt)))

;; -----------------------------------------------------------------------------
(defun specman-comment-cleanup ()

  ;; Remove useless whitespace.
  ;;
  (goto-char (point-min))
  (while (re-search-forward "[ \t]+$" nil t)
    (replace-match ""))

  ;; Remove trailing newlines, whitespace.
  ;; 
;;  (goto-char (point-max))
;;  (skip-chars-backward " \n\t")
;;  (delete-region (point) (point-max))

  ;; Add the prefix to each line
  ;;
  (goto-char (point-min))
  (if (not specman-comment-ignore-first-line-prefix)
      (insert specman-comment-prefix))
  (while (search-forward "\n" nil t)
    (insert (make-string specman-comment-indent ?\ ))
    (insert specman-comment-prefix)))

;; -----------------------------------------------------------------------------
(defun specman-comment-finish ()
  "Complete the operation implied by the current comment."
  (interactive)

  ;;Clean and record the comment in the ring.
  ;;
  (let ((comment-buffer (current-buffer))
        (comment-text   (progn
                          (specman-comment-cleanup)
                          (buffer-string)))
        )

    ;; Return to "parent" buffer of this operation.
    ;; Remove comment window.
    ;;
    (let ((old-window-config  specman-comment-window-config)
          (chained-comment    specman-comment-chained-comment)
          (beg-mark           specman-comment-begin-mark)
          (end-mark           specman-comment-end-mark)
          (edited-buffer      (marker-buffer specman-comment-begin-mark))
          )
      (set-buffer edited-buffer)
      (delete-windows-on comment-buffer)
      (kill-buffer comment-buffer)
      
      (save-excursion
        (if (markerp end-mark)
            (delete-region beg-mark end-mark))
        (goto-char beg-mark)
        (insert comment-text))

      (pop-to-buffer specman-comment-parent-buffer)
      (if (and old-window-config
               (not chained-comment))
          (set-window-configuration old-window-config)))))


;; =============================================================================
;; SPECMAN ADAPTIVE AUTO FILL
;; =============================================================================
;; Require package filladapt

(when (require 'filladapt nil t)

(add-hook 'specman-mode-hook
  '(lambda () (auto-fill-mode 1)))
(add-hook 'specman-mode-hook
  '(lambda () (filladapt-mode 1)))

; The e comment token in the token table must appeat before the bullet token
; since the bullet regexp include "-+". That's why we put it in the begining of
; the list. The order in the other lists is not important.
; C++ style comments are already recognized.
(setcar filladapt-token-table '("---*" e-comment))
(setcar filladapt-token-match-table '(e-comment e-comment))
(setcar filladapt-token-conversion-table '(e-comment . exact)))



;;; specman-comment mode definition ends here
;; -----------------------------------------------------------------------------


;; -----------------------------------------------------------------------------
;; BUGS:
;; -----------------------------------------------------------------------------
;; - When closing } is on same line as container (e.g. foo() is {};) auto comment
;;   is wrong
;; - Doesn't detect methods when parameter has (bits:) modifier. Note that there
;;   may be any number of parantheses nested.
;; -----------------------------------------------------------------------------
;; TODO:
;; -----------------------------------------------------------------------------
;;
;; - review TODO comments embedded in the code.
;; - add commands to syntax for editing ecoms.
;; - specman interaction mode.
;; - hideshow interaction (exists in a partial form, commented out)
;;   - comments
;;   - folding (struct, method)
;; - headers
;;   - optimize creation of headers
;;   - generalize header creation into modular functions, to make it easy
;;     to add and change headers.
;;     - while at it, add a test header:
;;       "File:\nAuthor:\nDate:\nPurpose:\nExpected:"...
;; - indentation uglyness:
;;   - the indentation abstraction for [] is ugly.
;;   - problems with a scope in a paren - handled twice.
;; - specman-max-line-length defaults to 80, while x/emacs natively opens 80
;;   characters wide.  this would be fine, but (newline) is also a character
;;   and causes wrap-around by default - which is ugly.
;;   - can be solved by changing the default width in .emacs, but this is
;;     a little too demanding.  on the other hand, changing the default to 79
;;     because x/emacs is stupid isn't too nice either.
;;
;; 
;; -----------------------------------------------------------------------------
;; ISSUES:
;; -----------------------------------------------------------------------------
;;
;; * consider c-code comments in all re-searches
;;
;; - C code #: indentation is messed up
;;   - add "C code #:" and "end #" to up/down scope queries.
;;   - mixed major-mode?
;;
;; - indentation inconsistency - comments are indented as a normal line,
;;   but insertion in comment mode (or comment-realign) has a nicer
;;   indentation, where the first comment line determines the indentation.
;;   since this comment may be on a normal line, the comment indentation
;;   is variable.
;;   - comment indentation should be sensitive to such comment blocks.
;;
;; - usability - some things are not intuitive, and there is not much in
;;   the way of help...
;;   - method/struct headers - need to be called from within the relevant
;;     scope, or on the definition line.  This is not obvious - e.g. why
;;     not just call it anywhere, but that makes it act strange.
;;
;;
;; -----------------------------------------------------------------------------
;; CHANGES:
;; -----------------------------------------------------------------------------
;;
;; - reviewed most of the code and removed a lot of old cruft.
;; - better performance.
;; - external is a keyword.
;; - fixed specman-open-e-code-block optional space addition.
;; - describe-context:  added on event methods, fixed context name acquisition.
;; - specman-index: fully supported.
;; - specman-index: activation customizable (on by default).
;; - field highlighting fixed.
;; - added event highlighting.
;; - 'TODO:' in comments is now highlighted as warning.
;; - <field> : *<name> now works.
;; - punctuation is now highlighted (controled by customizable variable)
;;   and it has its own face (because it's always single char).
;; - make specman-tab-width be specman-basic-offset
;; - fixed customize-group for specman.
;; - add number highlighting.
;; - fixed event highlighting.
;; - reviewed, revised and organized keyword list for syntax highlighting.
;; - added syntax highlighting for macro definition keywords.
;; - general events and special events are highlighted differently.
;; - describe context - complete also for when and internal ifdefs.
;; - headers:
;;   - more intelligent - find the the first definition above using regexps.
;;   - define now supported.
;;   - added a compact mode which includes just the name, so it doesn't need
;;     any user interaction.  this mode is now default so all the shortcuts
;;     activate it.  the full mode is accessible through the menu.
;;   - the header is added above any comments directly above the definition.
;;   - an empty line is added above the header, if there isn't one already.
;;   - added an automatic mode which adds all headers to the current buffer,
;;     accessible through the menu.
;;   - headers ignore structs with existing headers.
;; - package|private|protected structs, units, extends, fields, types, etc'
;; - fixed specman-closer-p:
;;   error if enter is pressed on last line and there is no terminating '>
;; - specman-beg-of-statement ok now (was - check: C style for loop messes
;;   indentation (for {i = 0; i < 10; i += 1} {}))
;; - better handling for specman compile and make
;; - dont indent in ex-code regions.
;; - optimized all scope and paren search by using a global data structure
;;   which is prepared once (a hash table).
;; - result/return - special face.
;; - if (index != it_index) && (path is a fields_constraint_path (fcp)
;;   the if highlights as a function.
;; - 'add' highlight in - result.add({<e1'exp>; <e2'exp>});
;; - indentation of else in check that expression.
;; - fixed bug in specman-skip-backward-comment-or-string when skipping back
;;   over strings.
;; - improved specman-open-e-code-section
;; - added highlighting for read_only()
;; - fixed indentation bug with continued lines in new statements.
;; - \\w is [a-zA-Z0-9_] in syntax-table
;; - added ".e" as a speedbar supported extension - allows traversing e
;;   files internal structure, as computed with specman-index, using the
;;   speedbar.
;; - delete key doesn't delete region even when delete-region option is set
;;   - deprecated specman-delete-char
;; - can't open new e-code section on an empty file.
;; - can't edit a new comment when it's empty.
;; - can't indent region when there are too many closing parens.
;; - fix move to start/end
;; - add a full region scope locating function.
;; - major optimization effort with many rewrites, centering mostly on
;;   then indentation code path:
;;   specman-re-search-*, specman-indent-region, specman-indent-line,
;;   specman-imenu-create-menu, specman-up-list,
;;   specman-skip-forward-comment-or-string, specman-scope-offset,
;;   specman-beg-of-statement, specman-beg-of-defun.
;; - changed verisity references to cadence references.
;;
;; -----------------------------------------------------------------------------

(provide 'specman-mode)
(run-hooks 'specman-mode-load-hook)
 
;;; specman-mode.el ends here
