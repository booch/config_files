;;; Emacs Custom Configuration.

;; Load Prelude.
(load "~/.emacs.d/prelude/init.el")

;; Configure Prelude.
(setq prelude-guru nil) ;; Don't disable cursor keys.
(require 'prelude-ido) ;; Super charges Emacs completion for C-x C-f and more
(require 'prelude-c)
(require 'prelude-coffee)
(require 'prelude-css)
(require 'prelude-emacs-lisp)
(require 'prelude-js)
(require 'prelude-key-chord) ;; Binds useful features to key combinations
(require 'prelude-org) ;; Org-mode helps you keep TODO lists, notes and more
(require 'prelude-python)
(require 'prelude-ruby)
(require 'prelude-scala)
(require 'prelude-scss)
(require 'prelude-web) ;; Emacs mode for web templates
(require 'prelude-xml)

;; Set whitespace-mode to highlight (only) hard tabs and trailing whitespace.
(setq whitespace-style '(face tabs trailing))

;; Store customize UI changes in .emacs.d/custom.el. (Revert Prelude's change.)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file)
