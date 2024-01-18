;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Daniel Herrera Rendón")
(setq user-mail-address "daniel.herrera.rendon@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))
;; (setq doom-font (font-spec :family "Hack" :size 22)) ;; thinkpad
(setq doom-font (font-spec :family "Hack" :size 32)) ;; desktop

;; (setq doom-font (font-spec :family "JetBrains Mono" :size 24)
;;       doom-big-font (font-spec :family "JetBrains Mono" :size 36)
;;       doom-variable-pitch-font (font-spec :family "Overpass" :size 24)
;;       doom-serif-font (font-spec :family "IBM Plex Mono" :weight 'light))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-one)
(setq doom-theme 'gruber-darker)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; (direnv-mode)


(setq-default cursor-type 'bar)

;; (load-theme 'gruber-darker t)
;; (load-theme 'doom-gruvbox t)
;; (load-theme 'doom-one t)
;; (load-theme 'doom-vibrant t)
;; (load-theme 'doom-dark+ t)

(setq tab-width 2
      indent-tabs-mode nil)
(setq-default indent-tabs-mode nil)

;; ;; make whitespace-mode use just basic coloring
;; (setq whitespace-style (quote (spaces tabs newline space-mark tab-mark newline-mark)))

;; (setq whitespace-display-mappings
;;       ;; all numbers are Unicode codepoint in decimal. try (insert-char 182 ) to see it
;;       '(
;;         (space-mark 32 [183] [46]) ; 32 SPACE, 183 MIDDLE DOT 「·」, 46 FULL STOP 「.」
;;         (newline-mark 10 [182 10]) ; 10 LINE FEED
;;         (tab-mark 9 [9655 9] [92 9]) ; 9 TAB, 9655 WHITE RIGHT-POINTING TRIANGLE 「▷」
;;         ))
;; (global-whitespace-mode 1)

(setq-default ispell-program-name "/run/current-system/sw/bin/aspell")

(use-package counsel
  :bind
  (("M-y" . counsel-yank-pop)
   :map ivy-minibuffer-map
   ("M-y" . ivy-next-line)))

;; (setq display-line-numbers-type 'relative)

(setq-default
 delete-by-moving-to-trash t                      ; Delete files to trash
 tab-width 2                                      ; Set width for tabs
 uniquify-buffer-name-style 'forward              ; Uniquify buffer names
 window-combination-resize t)                      ; take new window space from all other windows (not just current)
 

(setq undo-limit 80000000                         ; Raise undo-limit to 80Mb
      auto-save-default t                         ; Nobody likes to loose work, I certainly don't
      inhibit-compacting-font-caches t            ; When there are lots of glyphs, keep them in memory
      truncate-string-ellipsis "…")               ; Unicode ellispis are nicer than "...", and also save /precious/ space

(delete-selection-mode 1)                         ; Replace selection when inserting text
;; (display-time-mode 1)                             ; Enable time in the mode-line
;; (display-battery-mode 1)                          ; On laptops it's nice to know how much power you have
(global-subword-mode 1)                           ; Iterate through CamelCase words


;; Does not work.
;; (map! :n [mouse-8] #'better-jumper-jump-backward
;;       :n [mouse-9] #'better-jumper-jump-forward)

(use-package! keycast
  :commands keycast-mode
  :config
  (define-minor-mode keycast-mode
    "Show current command and its key binding in the mode line."
    :global t
    (if keycast-mode
        (progn
          (add-hook 'pre-command-hook 'keycast-mode-line-update t)
          (add-to-list 'global-mode-string '("" mode-line-keycast " ")))
      (remove-hook 'pre-command-hook 'keycast-mode-line-update)
      (setq global-mode-string (remove '("" mode-line-keycast " ") global-mode-string))))
  (custom-set-faces!
    '(keycast-command :inherit doom-modeline-debug
                      :height 0.9)
    '(keycast-key :inherit custom-modified
                  :height 1.1
                  :weight bold)))

(use-package centaur-tabs
  :demand
  :config
  (centaur-tabs-mode t)
  :bind
  ("C-<prior>" . centaur-tabs-backward)
  ("C-<next>" . centaur-tabs-forward))

(after! centaur-tabs
  (centaur-tabs-mode -1)
  (setq centaur-tabs-height 16
        centaur-tabs-set-icons t
        centaur-tabs-modified-marker "o"
        centaur-tabs-close-button "×"
        centaur-tabs-set-bar 'above)
        centaur-tabs-gray-out-icons 'buffer)
  ;; (centaur-tabs-change-fonts "P22 Underground Book" 160))
;; (setq x-underline-at-descent-line t)

;; (use-package company
;;   :bind (:map company-active-map
;;          ("C-n" . company-select-next)
;;          ("C-p" . company-select-previous))
;;   :config
;;   (global-company-mode t))

;; (after! company
;;   (setq company-idle-delay 0.0
;;         company-minimum-prefix-length 2
;;         company-transformers nil)
;;   (setq company-show-numbers t)
;;   ;; (define-key company-active-map (kbd "C-n") 'company-select-next-or-abort)
;;   ;; (define-key company-active-map (kbd "C-j") 'company-select-previous-or-abort)

;; (defun ora-company-number ()
;;   "Forward to `company-complete-number'.
;; Unless the number is potentially part of the candidate.
;; In that case, insert the number."
;;   (interactive)
;;   (let* ((k (this-command-keys))
;;          (re (concat "^" company-prefix k)))
;;     (if (or (cl-find-if (lambda (s) (string-match re s))
;;                         company-candidates)
;;             (> (string-to-number k)
;;                (length company-candidates))
;;             (looking-back "[0-9]+\\.[0-9]*" (line-beginning-position)))
;;         (self-insert-command 1)
;;       (company-complete-number
;;        (if (equal k "0")
;;            10
;;          (string-to-number k))))))

;; (defun ora--company-good-prefix-p (orig-fn prefix)
;;   (unless (and (stringp prefix) (string-match-p "\\`[0-9]+\\'" prefix))
;;     (funcall orig-fn prefix)))
;; (advice-add 'company--good-prefix-p :around #'ora--company-good-prefix-p)

;; (let ((map company-active-map))
;;   (mapc (lambda (x) (define-key map (format "%d" x) 'ora-company-number))
;;         (number-sequence 0 9))
;;   (define-key map " " (lambda ()
;;                         (interactive)
;;                         (company-abort)
;;                         (self-insert-command 1)))
;;   (define-key map (kbd "<return>") nil))
;;   )

;; (setq-default history-length 1000)
;; (setq-default prescient-history-length 1000)

;; (set-company-backend! '(nix-mode)
;;   '(:separate company-nixos-options
;;               company-tabnine
;;               company-files
;;               company-yasnippet
;;               ))

;; (set-company-backend! '(text-mode
;;                         markdown-mode
;;                         gfm-mode)
;;   '(:seperate company-ispell
;;               company-files
;;               company-yasnippet
;;               company-dabbrev))

;; (set-company-backend! '(c-mode
;;                         c++-mode
;;                         ess-mode
;;                         haskell-mode
;;                         ;;emacs-lisp-mode
;;                         lisp-mode
;;                         sh-mode
;;                         php-mode
;;                         python-mode
;;                         go-mode
;;                         ruby-mode
;;                         rust-mode
;;                         js-mode
;;                         css-mode
;;                         web-mode
;;                         )
;;   '(:separate company-tabnine
;;               company-files
;;               company-yasnippet))

;; (setq +lsp-company-backend '(company-lsp :with company-tabnine :separate))

;; (use-package! company-tabnine
;;   :when (featurep! :completion company)
;;   :config
;;   (setq company-tabnine--disable-next-transform nil)
;;   (defun my-company--transform-candidates (func &rest args)
;;     (if (not company-tabnine--disable-next-transform)
;;         (apply func args)
;;       (setq company-tabnine--disable-next-transform nil)
;;       (car args)))

;;   (defun my-company-tabnine (func &rest args)
;;     (when (eq (car args) 'candidates)
;;       (setq company-tabnine--disable-next-transform t))
;;     (apply func args))

;;   (advice-add #'company--transform-candidates :around #'my-company--transform-candidates)
;;   (advice-add #'company-tabnine :around #'my-company-tabnine)
;;   ;; Trigger completion immediately.
;;   ;; (setq company-idle-delay 0)

;;   ;; Number the candidates (use M-1, M-2 etc to select completions).
;;   (setq company-show-numbers t)

;;   ;; Use the tab-and-go frontend.
;;   ;; Allows TAB to select and complete at the same time.
;;   (company-tng-configure-default)
;;   (setq company-frontends
;;         '(company-tng-frontend
;;           company-pseudo-tooltip-frontend
;;           company-echo-metadata-frontend))
;;   )

(after! flyspell (require 'flyspell-lazy) (flyspell-lazy-mode 1))

;; (setq ispell-dictionary "en_GBs_au_SCOWL_80_0_k_hr")
;; (setq ispell-personal-dictionary (expand-file-name ".hunspell_personal" doom-private-dir))

;; (add-hook 'doom-load-theme-hook 'theme-magic-from-emacs)

(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

;; (use-package dante
;;   :ensure t
;;   :after haskell-mode
;;   :commands 'dante-mode
;;   :init

;;   (add-hook 'haskell-mode-hook 'flycheck-mode)
;;   (add-hook 'haskell-mode-hook 'company-mode)
;;   (add-hook 'haskell-mode-hook 'dante-mode)
;;   ;; :bind (:map dante-mode-map
;;   ;;        ("M-." . my-lookup-def)
;;   ;;        )
;;   :config
;;   (setq-default dante-repl-command-line
;;                 '("cabal" "new-repl" dante-target "--builddir=dist-newstyle/dante")))

;; (use-package flycheck-haskell
;;   :commands flycheck-haskell-setup)

;; (use-package eglot
;;   :ensure t
;;   :config
;;   (add-to-list 'eglot-server-programs '(haskell-mode . ("ghcide" "--lsp"))))

(use-package direnv
  :config
  ;; enable globally
  (direnv-mode)
  ;; exceptions
  ; (add-to-list 'direnv-non-file-modes 'foobar-mode)

  ;; nix-shells make too much spam -- hide
  ;; (setq direnv-always-show-summary nil)

  :hook
  ;; ensure direnv updates before flycheck and lsp
  ;; https://github.com/wbolster/emacs-direnv/issues/17
  ;; (flycheck-before-syntax-check . direnv-update-environment)
  (lsp-before-open-hook . direnv-update-environment)

  :custom
  ;; quieten logging
  (warning-suppress-types '((direnv))))

(use-package lsp-haskell
 :ensure t
 :after (haskell-mode lsp-mode)
 :config
 (setq lsp-haskell-server-path "haskell-language-server")
 (setq lsp-haskell-formatting-provider "stylish-haskell")
 ;; Comment/uncomment this line to see interactions between lsp client/server.
 (setq lsp-log-io t)
)

(use-package haskell-mode
  :custom
  (haskell-process-type 'cabal-repl)
  (haskell-process-load-or-reload-prompt t)
  :ensure t
  :defer t
  :init
  (defun my-save ()
    "Save with formating"
    (interactive)
    (progn (haskell-mode-stylish-buffer)
           (save-buffer)))
  ;; (add-hook 'haskell-mode-hook 'haskell-decl-scan-mode)
  ;; :hook (;; (haskell-mode . rvl/stylish-on-save)
  ;;        (haskell-mode . direnv-update-environment))
  :bind (:map haskell-mode-map
         ("C-c h" . hoogle)
         ("C-c sh" . haskell-mode-stylish-buffer)
         ("C-c C-," . haskell-navigate-imports)
         ;; ("C-x C-s" . my-save)
         ;; ("M-.". my-lookup-def)
         )
  :config (message "Loaded haskell-mode")
  (setq haskell-mode-stylish-haskell-path "stylish-haskell")
  (setq haskell-hoogle-url "https://www.stackage.org/lts/hoogle?q=%s"))

;; (defun my-lookup-def ()
;;     "recenter buffer after defenition lookup"
;;     (interactive)
;;     (progn (call-interactively '+lookup/definition)
;;            (recenter-top-bottom)))

;; (map! "M-." 'my-lookup-def)

;; (use-package lsp-mode
;;   :commands lsp-mode)
