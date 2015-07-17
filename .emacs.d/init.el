;;; package --- Summary:

;;; Commentary:

;;; code:

;; Packages ====================================================================

(when (>= emacs-major-version 24)
  (setq package-list '(
		       ace-jump-mode
		       anzu
;		       auctex
		       color-theme-sanityinc-tomorrow
		       company
		       company-irony
		       cyberpunk-theme
		       diff-hl
		       ecb
		       evil-numbers
		       flx-ido
		       helm
		       helm-gtags
		       ido-vertical-mode
		       irony
		       magit
		       move-text
		       multi-term
		       multiple-cursors
		       origami
		       rainbow-delimiters
		       smex
		       undo-tree
		       yasnippet
		       solarized-theme
		       planet-theme
		       use-package
		       xcscope
		       zenburn-theme
		       ))
  (require 'package)

  (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
  (add-to-list 'package-archives '("SC" . "http://joseito.republika.pl/sunrise-commander/") t)

  ;; activate all the packages (in particular autoloads)
  (package-initialize)

  ;; fetch the list of packages available
  (unless package-archive-contents
    (package-refresh-contents))
  ;; install the missing packages
  (dolist (package package-list)
    (unless (package-installed-p package)
      (package-install package))))

;; Emacs modes =================================================================
(require 'use-package)

(defmacro hook-into-modes (func modes)
  `(dolist (mode-hook ,modes)
     (add-hook mode-hook ,func)))

;; Disable
(blink-cursor-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode 0)

;; Enable
(column-number-mode 1)
(electric-pair-mode 1)
(winner-mode 1)
(ido-mode t)
(ido-vertical-mode 1)
(show-paren-mode t)
(global-font-lock-mode t)
(global-undo-tree-mode t)
(global-anzu-mode t)
(global-diff-hl-mode t)

(load-theme 'solarized-dark t)

;; Variables ===================================================================
(set-face-attribute 'default nil :height 100)
(setq initial-scratch-message nil)
(setq inhibit-startup-message t)
(setq transient-mark-mode t)
(setq tab-width 4)
(setq indent-tabs-mode nil)
(setq require-final-newline 't)
(setq ediff-split-window-function 'split-window-horizontally)
(setq grep-command "grep -rin ")
(setq frame-title-format "%b - emacs")
(setq c-default-style "linux" c-basic-offset 4)
(setq bookmark-default-file "~/.emacs.d/bookmarks.emacs")
(setq undo-tree-mode-lighter " UT")

(autoload 'ibuffer "ibuffer" "List buffers." t)

;; Hooks =======================================================================
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;; Init files ==================================================================
(add-to-list 'load-path (expand-file-name "~/.emacs.d/init"))

(require 'key-bindings)
(require 'init-misc-def)
(require 'init-company)
(require 'init-cedet)
;(require 'init-auctex)
(require 'init-yasnippet)
(require 'init-move-text)
(require 'init-ace-jump)
(require 'init-org-mode)
(require 'init-ecb)
(require 'init-multiple-cursors)
;(require 'init-clearcase)
(require 'init-helm)
(require 'init-evil-numbers)
(require 'init-term)
