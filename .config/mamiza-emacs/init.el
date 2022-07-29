  ;; -*- lexical binding: t; -*-

  ;; Install "gcmh" for better garbage collection system
  (use-package gcmh
    :config
    (add-to-list 'load-path "gcmh")
    (gcmh-mode 1))

  (defun mamiza/display-startup-time ()
    (message "⏲️ Emacs loaded in %s with %d garbage collections."
             (format "%.2f seconds"
                     (float-time
                      (time-subtract after-init-time before-init-time)))
             gcs-done))

  (add-hook 'emacs-startup-hook #'mamiza/display-startup-time)

  (require 'package) ;; Load emacs' default package manager to start

  ;; Setup package repositories
  (setq package-archives '(("mepla" . "https://melpa.org/packages/")
                           ("org" . "https://orgmode.org/elpa/")
                           ("elpa" . "https://elpa.gnu.org/packages/")))

  (package-initialize)
  (unless package-archive-contents
    (package-refresh-contents))

  ;; Install "use-package" to configure other packages
  (unless (package-installed-p 'use-package)
    (package-install 'use-package))

  (require 'use-package) ;; Load "use-package"

  ;; Install packages on the first launch of emacs
  (setq use-package-always-ensure t)

  ;; Be verbose (for debugging)
  (setq use-package-verbose t)

;; Install "auto-package-update" to update packages automatically
(use-package auto-package-update
  :custom
  (auto-package-update-interval 1)
  (auto-package-update-prompt-before update t)
  :config
  (auto-package-update-maybe)
  (auto-package-update-at-time "24:00"))

  (setq inhibit-startup-message t) ;; Don't display splash screen

  (set-fringe-mode 5) ;; Add a little bit of padding on the side

  (tool-bar-mode -1) ;; Don't display the toolbar
  (menu-bar-mode -1) ;; Don't display the menu bar
  (tooltip-mode -1)  ;; Don't display tooltips
  (scroll-bar-mode -1) ;; Don't display scroll bar
  (setq use-dialog-box nil) ;; Don't show any pop-up gui elements

  (global-display-line-numbers-mode t) ;; Display line numbers
  (column-number-mode) ;; Display column number

  ;; Don't display line numbers in some modes
  (dolist (mode '(term-mode-hook
                  shell-mode-hook
                  eshell-mode-hook))
    (add-hook mode (lambda () (display-line-numbers-mode 0))))

  ;; Set the font properly both in normal emacs and the daemon
  (defun mamiza/set-font-faces ()
    (set-face-attribute 'default nil :font "Iosevka" :height 180)
    (set-face-attribute 'fixed-pitch nil :font "Iosevka" :height 180)
    (set-face-attribute 'variable-pitch nil :font "Monospace" :height 180 :weight 'regular))

  (if (daemonp)
      (add-hook 'after-make-frame-functions
                (lambda (frame)
                  (setq doom-modeline-icon t)
                  (with-selected-frame frame
                    (mamiza/set-font-faces))))
    (mamiza/set-font-faces))

  ;; Install "all-the-icons"
  (use-package all-the-icons)

  ;; Install "doom-modeline"
  (use-package doom-modeline
    :init
    (doom-modeline-mode 1)
    :custom
    (doom-modeline-height 5))

  ;; Install "doom-themes"
  (use-package doom-themes)

  ;; Install "gruber-darker-theme" from tsoding
  (use-package gruber-darker-theme)

  ;; Load the selected theme here
  (load-theme 'doom-dracula t)

;; Resize texts easier
(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)

  ;; Install "which-key" to display hints for keybinding
  (use-package which-key
    :diminish which-key-mode
    :config
    (which-key-mode)
    (setq which-key-idle-delay 1))

  ;; Define a hook to disable evil in some modes
  (defun mamiza/not-evil-hook ()
    (dolist (mode '(custom-mode
                    eshell-mode
                    git-rebase-mode
                    erc-mode
                    circe-server-mode
                    circe-chat-mode
                    circe-query-mode
                    sauron-mode
                    term-mode))
      (add-to-list 'evil-emacs-state-modes mode)))

  ;; Install "evil" and adding some keybindings
  (use-package evil
    :init
    (setq evil-want-integration t)
    (setq evil-want-keybinding nil)
    (setq evil-want-C-u-scroll t)
    (setq evil-want-C-i-jump nil)
    :hook
    (evil-mode . mamiza/not-evil-hook)
    :demand t
    :config
    (evil-mode 1)
    (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)

    ;; Use viusal line motions even outside of "visual-line-mode" buffers
    (evil-global-set-key 'motion "j" 'evil-next-visual-line)
    (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

    ;; Set some initial state for some modes
    (evil-set-initial-state 'message-buffer-mode 'normal)
    (evil-set-initial-state 'dashboard-mode 'normal))

  ;; Install "evil-collection" for mode spicific evil keybindings
  (use-package evil-collection
    :after evil
    :config
    (evil-collection-init))

  ;; Install "evil-nerd-commenter" to comment lines
  (use-package evil-nerd-commenter
    :bind ("C-/" . evilnc-comment-or-uncomment-lines))

    ;; Install "general" for better keybindings
    (use-package general
      :after evil
      :config
      (general-create-definer mamiza/leader-keys
        :states '(normal visual)
        :keymaps 'override
        :prefix "SPC"
        :global-prefix "C-SPC")

      ;; TODO: Seperate all the keybindings into their respective sections
      (mamiza/leader-keys
        "SPC" '(counsel-find-file :which-key "Find file")

        "w" '(:ignore t :which "Window")
        "w=" '(balance-windows :which-key "Balance")
        "wc" '(evil-window-delete :which-key "Close")
        "wv" '(evil-window-vsplit :which-key "Vertical split")
        "ws" '(evil-window-split :which-key "Horizontal split")
        "wo" '(delete-other-windows :which-key "Kill other")
        "ww" '(evil-window-next :which-key "Next")
        "wW" '(evil-window-prev :which-key "Previous")
        "wm" '(maximize-window :which-key "Maximize")

        "b" '(:ignore t :which-key "Buffer actions")
        "bk" '(kill-current-buffer :which-key "Kill buffer")
        "bb" '(counsel-switch-buffer :which-key "Switch buffer")

        "t" '(:ignore t :which-key "Toggle")
        "tt" '(counsel-load-theme :which-key "Themes")
        "tw" '(whitespace-mode toggle :which-key "Whitespaces")

        "c" '(:ignore t :which-key "Configure")
        "cf" '(:ignore t :which-key "File")
        "cfe" '((lambda () (interactive) (find-file (expand-file-name "~/.config/emacs/emacs.org"))) :which-key "Emacs")

        "z" '(ispell-word :which-key "Spell Check")))

;; Install "helpful" for better documentation
(use-package helpful
  :commands (helpful-callable helpful-variable helpful-command helpful-key)
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

  ;; Store last cursor position in the cache directory
  (setq save-place-file "~/.cache/emacs/places")
  ;; Actually enable the feature
  (save-place-mode 1)

  (use-package evil-mc
    :after evil
    :config
    (global-evil-mc-mode 1))

  ;; Refresh file buffers if change from outside emacs
  (global-auto-revert-mode 1)
  ;; Refresh other kinds of buffers too
  (setq global-auto-revert-non-file-buffers t)

  ;; Install "rainbow-delimiters" to colorize delimiters
  (use-package rainbow-delimiters
    :hook
    (prog-mode . rainbow-delimiters-mode))

    (use-package ws-butler
      :init
      (add-hook 'org-mode-hook #'ws-butler-mode)
      (add-hook 'prog-mode-hook #'ws-butler-mode)
      (add-hook 'text-mode-hook #'ws-butler-mode))

  ;; Only display "space-mark" when "whitespace-mode" is active
  (setq whitespace-display-mappings '((space-mark 32 [183] [46])))

  (setq-default indent-tabs-mode nil)

  (electric-pair-mode 1)

(use-package csv-mode)

  (use-package flyspell-mode
    :ensure nil
    :init
    (add-hook 'text-mode-hook 'flyspell-mode)
    (add-hook 'prog-mode-hook 'flyspell-prog-mode)

    (setq ispell-program-name "hunspell")
    (setq ispell-hunspell-dict-paths-alist '(("en_US" "/usr/share/hunspell/en_US.aff")))
    (setq ispell-local-dictionary "en_US")
    (setq ispell-local-dictionary-alist '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8)))
    :commands ispell-word
    :config
    (flyspell-mode 1))

    (use-package rainbow-mode
      :commands rainbow-mode)

  (mamiza/leader-keys
    "tr" '(rainbow-mode :which-key "Rainbow Mode"))

  ;; Install "ivy" as my completion system
  (use-package ivy
    :diminish
    :bind
    (("C-f" . swiper)
    :map ivy-minibuffer-map
    ("TAB" . ivy-alt-done)
    ("C-l" . ivy-alt-done)
    ("C-j" . ivy-next-line)
    ("C-k" . ivy-previous-line)
    :map ivy-switch-buffer-map
    ("C-k" . ivy-previous-line)
    ("C-l" . ivy-done)
    ("C-d" . ivy-switch-buffer-kill)
    :map ivy-reverse-i-search-map
    ("C-k" . ivy-pervious-line)
    ("C-d" . ivy-reverse-i-search-kill))
    :config
    (setq  ivy-re-builders-alist '((t . orderless-ivy-re-builder)))
    (add-to-list 'ivy-highlight-functions-alist '(orderless-ivy-re-builder . orderless-ivy-highlight))
    (ivy-mode 1))

  ;; Install "ivy-rich" for a more friendly interface for "ivy"
  (use-package ivy-rich
    :after ivy
    :config
    (ivy-rich-mode 1))

  ;; Install "counsel" for various completion functions from "ivy"
  (use-package counsel
    :bind (("M-x" . counsel-M-x)
    ("C-x C-f" . counsel-find-file))
    :config
    ;; Don't input default things in ivy prompts
    (setq ivy-initial-inputs-alist nil)
    (counsel-mode 1))

  ;; Install "ivy-prescient" as a filtering system that uses prescient as a backend
  (use-package ivy-prescient
    :after counsel
    :custom
    (ivy-prescient-enable-filtering nil)
    :config
    (prescient-persist-mode 1)
    (ivy-prescient-mode 1))

  ;; Install "company" for code completion
  (use-package company
    :after lsp-mode
    :hook
    (lsp-mode . company-mode)
    :bind
    (:map company-active-map
          ("<tab>" . company-complete-selection))
    (:map lsp-mode-map
          ("<tab>" . company-indent-or-complete-common))
    :custom
    (company-minimum-prefix-lenght 1)
    (company-idle-delay 0.0))

    ;; Install "company-box" a company frontend with icons 
    (use-package company-box
      :hook (company-mode . company-box-mode))

  (use-package orderless
    :custom
    (completion-styles '(orderless basic))
    (completion--category-override '((file (styles basic partial-completion)))))

  ;; Install "magit" , the best package EVER
  (use-package magit
    :commands magit-status
    :custom
    (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

  (mamiza/leader-keys
    "gg" '(:ignore t :which-key "Magit")
    "gc" '(magit-clone :which-key "Clone")
    "gg" '(magit-status :which-key "Status"))

;; Install "lsp-mode" for language server support
(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (lsp-enable-which-key-integration t))

  (use-package lsp-ui
    :hook
    (lsp-mode . lsp-ui-mode)
    :custom
    (lsp-ui-doc-position 'bottom))

(use-package flycheck)

    (use-package sh-mode
      :ensure nil
      :hook
      (sh-mode . lsp-deferred))

  (use-package flymake-shellcheck
    :commands flymake-shellchek-load
    :init
    (add-hook 'sh-mode-hook 'flymake-shellcheck-load))

  ;; Install "python-mode" for python lsp support
  (use-package python-mode
    :hook
    (python-mode . lsp-deferred)
    :custom
    ;; Spicify which python binary to use in python mode
    ;; You can comment this seciton out if you have python binary as python3
    (python-shell-interpreter "python3")
    :bind
    (("C-<backspace>" . backward-kill-word)))

  (add-hook 'c-mode-hook 'lsp)
  (add-hook 'c++-mode-hook 'lsp)

            (mamiza/leader-keys
              "e" '(:ignore t :which-key "Evaluate")
              "eb" '(eval-buffer :which-key "Buffer")
              "er" '(eval-region :which-key "Region"))

    (use-package yaml-mode
      :mode "\\.yml\\'")

  (use-package vimrc-mode
    :defer t
    :config
    (add-to-list 'auto-mode-alist '("\\.vim\\(rc\\)?\\'" . vimrc-mode)))

  (use-package compile
    :ensure nil
    :commands compile
    :config
    (setq compilation-scroll-output t))

(setq compile-command nil)

  (mamiza/leader-keys "C" '(compile :which-key "Compile"))

      ;; Install "yasnippet" for snippet "backend"
      (use-package yasnippet
        :hook (prog-mode . yas-minor-mode))

      ;; Install "yasnippet-snippets" for useful snippets
      (use-package yasnippet-snippets
        :after yasnippet)

    (use-package term
      :ensure nil
      :config
      (setq explicit-shell-file-name "/usr/bin/zsh")
      (setq term-prompt-regexp "^\[.*@.*\]\$ "))


    (use-package eterm-256color
      :after term
      :hook (term-mode . eterm-256color-mode))

    (use-package vterm
      :commands vterm
      :config
      (setq vterm-shell "zsh")
      (setq vterm-max-scrollback 16384))

  (defun mamiza/configure-eshell ()
    (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

    (add-to-list 'eshell-output-filter-function 'eshell-truncate-buffer)

    (evil-normalize-keymaps)

    (setq eshell-history-size nil
          eshell-buffer-maximum-lines 16384
          eshell-scroll-to-bottom-on-input t))

  (use-package eshell
    :ensure nil
    :hook
    (eshell-first-time-mode . mamiza/configure-eshell))

    ;; Configure "dired"
    (use-package dired
      :ensure nil
      :commands (dired dired-jump)
      :config
      (evil-collection-define-key 'normal 'dired-mode-map
        "h" 'dired-up-directory
        "l" 'dired-open-file
        "c" 'dired-unmark-all-marks
        (kbd "<left>") 'dired-up-directory
        (kbd "<right>") 'dired-open-file)
      :custom
      ((dired-listing-switches "-aho --group-directories-first")))

  ;; Install "all-the-icons-dired"
  (use-package all-the-icons-dired
    :hook (dired-mode . all-the-icons-dired-mode))

  ;; Install "dired-open" for opening files with dired
  (use-package dired-open
    :commands (dired dired-jump)
    :config
    (setq dired-open-extensions '(("png" . "sxiv -b")
                                  ("mkv" . "mpv"))))

  (use-package diredfl
    :init (diredfl-global-mode 1))

  (mamiza/leader-keys
    "d" '(:ignore t :which-key "Dired")
    "dd" '(dired-jump :which-key "Here")
    "do" '(counsel-dired :which-key "Open ?"))

  ;; Don't a different file for custom variables
  (setq custom-file (concat user-emacs-directory "custom.el"))
  (when (file-exists-p custom-file)
    (load custom-file))

  ;; Store autosave and backup files in the cache directory
  (let ((backup-dir "~/.cache/emacs/backup/")
        (autosave-dir "~/.cache/emacs/autosave/"))
    (dolist (dir (list backup-dir autosave-dir))
      (when (not (file-directory-p dir))
        (make-directory dir t)))
    (setq backup-directory-alist `(("." . ,backup-dir))
          auto-save-file-name-transforms `((".*" ,autosave-dir t))
          auto-save-list-file-prefix (concat autosave-dir ".save-")
          tramp-backup-directory-alist `((".*" . ,backup-dir))
          tramp-auto-save-directory autosave-dir))

  ;; Take some precaution
  (setq backup-by-copying t
        delete-old-versions t
        version-control t
        kept-new-versions 5
        kept-old-versions 2)

  ;; Don't create lock files
  (setq create-lockfiles nil)

  (defun mamiza/org-mode-setup ()
    (org-indent-mode)
    (auto-fill-mode 0)
    (visual-line-mode 1)
    (setq evil-auto-indent nil))

  ;; Install "org"
  (use-package org
    :mode (("\\.org$" . org-mode))
    :init
    (when (not (file-directory-p "~/.local/share/emacs/"))
      (make-directory "~/.local/share/emacs/"))
    (when (not (file-exists-p "~/.local/share/emacs/agenda.org"))
      (with-temp-buffer (write-file "~/.local/share/emacs/agenda.org")))
    :hook
    (org-mode . mamiza/org-mode-setup)
    :config
    (setq org-ellipsis " >"
          org-hide-emphasis-markers t
          org-agenda-files '("~/.local/share/emacs/agenda.org")))

  ;; Enable company mode when editing org files
  (add-hook 'org-mode-hook 'company-mode)

  ;; Install "org-bullets" for better headers
  (use-package org-bullets
    :after org
    :hook
    (org-mode . org-bullets-mode))

  ;; Load "org-tempo" for org templates
  (require 'org-tempo)

  (add-to-list 'org-structure-template-alist '("sh" . "src shell"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))

        ;; Load syntax highlighting for certain languages to use in source blocks
        (with-eval-after-load 'org
          (org-babel-do-load-languages
           'org-babel-load-languages
           '((emacs-lisp . t))))

        ;; Don't ask confirmation for evaluating
        (setq org-confirm-babel-evaluate nil)

  ;; Tangle this file on save
  (defun mamiza/auto-org-babel-tangle ()
    (when (string-equal (buffer-file-name)
                        (expand-file-name "~/.config/emacs/emacs.org"))
      (let ((org-confirm-babel-evaluate nil))
        (org-babel-tangle))))

  (add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'mamiza/auto-org-babel-tangle)))

  (mamiza/leader-keys
    "o" '(:ignore t :which-key "Org")
    "ot" '(org-babel-tangle :which-key "Tangle"))
