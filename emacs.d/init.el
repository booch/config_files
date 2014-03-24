;;; Emacs Custom Configuration.

;; Load Prelude.
(setq prelude-init-file (expand-file-name "prelude/init.el" user-emacs-directory))
(if (file-exists-p prelude-init-file)

  (windmove-default-keybindings 'meta) ;; Allow shifted cursor keys to be used to select text.

  (load prelude-init-file)

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
)

;; Set whitespace-mode to highlight (only) hard tabs and trailing whitespace.
(setq whitespace-style '(face tabs trailing))

;; Set color theme. Acceptable light themes: adwaita. Acceptable dark themes: zenburn tango-dark
(load-theme 'adwaita)

;; Store customize UI changes in .emacs.d/custom.el. (Revert Prelude's change.)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(if (file-exists-p custom-file)
  (load custom-file)
)

;; Load keymap changes.
(setq keymap-file (expand-file-name "keymap.el" user-emacs-directory))
(if (file-exists-p keymap-file)
  (load keymap-file)
)

(global-set-key (kbd "<home>") 'move-beginning-of-line)
(global-set-key (kbd "<end>") 'move-end-of-line)
