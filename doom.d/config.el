(setq user-full-name "Daniel Herrera Rendón")
(setq user-mail-address "daniel.herrera.rendon@gmail.com")
(setq doom-font (font-spec :family "Hack" :size 32)) ;; desktop
(setq doom-theme 'gruber-darker)
(setq org-directory "~/org/")
(setq display-line-numbers-type t)
(setq-default cursor-type 'bar)
(setq tab-width 2
      indent-tabs-mode nil)
(setq-default indent-tabs-mode nil)
(setq-default ispell-program-name "/run/current-system/sw/bin/aspell")

(use-package counsel
  :bind
  (("M-y" . counsel-yank-pop)
   :map ivy-minibuffer-map
   ("M-y" . ivy-next-line)))
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
(global-subword-mode 1)                           ; Iterate through CamelCase words

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

(defvar flymake-allowed-file-name-masks)

(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

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

(use-package agda2-mode
  :load-path "/nix/store/8fkvkwvbssa4ssrp4cac50fqicirrnl2-Agda-2.7.0-data/share/ghc-9.6.6/x86_64-linux-ghc-9.6.6/Agda-2.7.0/emacs-mode"
  :config
  (setq agda2-program-name "agda"))
