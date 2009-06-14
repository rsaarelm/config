;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Preliminaries

; We might want to do something only when Emacs is first run and have other
; things be re-evaluated while the .emacs is being developed further. Make a
; variable for it.

(defvar first-evaluation-of-dot-emacs t)

; Add local elisp stuff

(add-to-list 'load-path "~/.elisp/")

; Help debugging errors in .emacs

(setq debug-on-error t)

; Use UTF-8 by default.

(prefer-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Visual settings

; Note: It's important to set the default font _before_ invoking color-theme.
; Otherwise Emacs seems to get confused about window dimensions.

(defun my-set-font (font-spec)
  (setq default-frame-alist
	(cons
	 (cons 'font font-spec)
	 default-frame-alist)))

(my-set-font "-misc-fixed-medium-*-*-*-15-*-*-*-*-*-*-*")

(when (string= (system-name) "erebus")
  (my-set-font "-misc-fixed-medium-*-*-*-12-*-*-*-*-*-*-*"))


(require 'color-theme)
(if window-system
    (color-theme-goldenrod)
  (color-theme-hober))

; Kill the GUI clutter
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HTML editing

;;; Use nxml-mode instead of html-mode for html files.
(add-to-list 'auto-mode-alist '("\\.html\\'" . nxml-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-mode

; Some settings inspired by http://doc.norang.ca/org-mode.html

; Manually load a new org-mode
(let
    ((orgmode-dir "~/.elisp/org-mode"))
  (if (file-exists-p orgmode-dir)
    (progn
      (setq load-path (cons (concat orgmode-dir "/lisp") load-path))
      (require 'org-install))))

; Prevent conflict with shift-dir keys for switching buffer
; The config variable used to be org-CUA-compatible.
(setq org-replace-disputed-keys t)

; Start org-mode for .org files.
(add-to-list 'auto-mode-alist '("\\.\\(org\\|org_archive\\)$" . org-mode))

; Custom settings in org-mode
(add-hook 'org-mode-hook
          (lambda ()
            ; flyspell for automatic spell checking
            (flyspell-mode 1)))

; Set the state of todo-style items to STARTED when clocking them.
(defun my-clock-in-switch (state)
  (cond ((string= state "TODO") "STARTED")
        ((string= state "WAITING") "STARTED")
        ((string= state "SOMEDAY") "STARTED")
        ((string= state "CANCELED") "STARTED")
        (t state)))

(setq org-clock-in-switch-to-state #'my-clock-in-switch)

; Make the clock persist across sessions
(setq org-clock-persist t)
(org-clock-persistence-insinuate)

; Restart clock from old time if there is an open clock line.
(setq org-clock-in-resume t)

(setq org-clock-out-remove-zero-time-clocks t)

; Don't clock out when moving task to DONE, allow manual finishing touches
; within the clocked time.
(setq org-clock-out-when-done nil)

; Timestamp done TODO items.
(setq org-log-done t)

(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)

; Make latex preview white on black to match the color theme.
(setq org-format-latex-options
      '(:foreground "White" :background "Black" :scale 1.2
        :matchers ("begin" "$" "$$" "\\(" "\\[")))

; Require braces for subscripts and superscripts, fixes the annoying
; subscript-itis from underscores in regular text.
(setq org-export-with-sub-superscripts '{})

; Setup the sequence of org-mode todo keywords.
;
; TODO: Tasks you know how to finish, can be finished in a single day and you
; are actively committed to finish.
;
; STARTED: Tasks you have started working on or tasks that are always ongoing
; such as following the news and answering email.
;
; WAITING: Tasks that can't be started before something else happens. Should
; explain what they're waiting on in the task text.
;
; SOMEDAY: Tasks you aren't actively committed to finish them. "I'll do it
; someday, maybe."
;
; PROJECT: Tasks you are committed to doing, but are too big or vague to be
; TODO items.
; 
; CANCELED: Canceled tasks. Should explain why the task was canceled.
;
; DONE: Finished tasks.
(setq org-todo-keywords
      '((sequence "TODO(t!)" "STARTED(s)" "|" "DONE(d!/!)")
        (sequence "WAITING(w@/!)" "SOMEDAY(S!)" "PROJECT(P!)" "|" "CANCELED(c@/!)")))

(setq org-todo-keyword-faces
      '(("TODO" :foreground "chartreuse" :weight bold)
        ("STARTED" :foreground "green yellow" :weight bold)
        ("DONE" :foreground "forest green" :weight bold)
        ("WAITING" :foreground "indian red" :weight bold)
        ("SOMEDAY" :foreground "medium orchid" :weight bold)
        ("PROJECT" :foreground "turquoise" :weight bold)
        ("CANCELED" :foreground "steel blue" :weight bold)))

; State triggers
;
; We want CANCELED and WAITING states to show up in subtasks as well. Do this
; by assigning tags to the tasks on setting the state.
;
; We also use a NEXT action tag, which gets removed if the task ends up
; waiting or done.
(setq org-todo-state-tags-triggers
      '(("CANCELED" ("CANCELED" . t))
        ("WAITING" ("WAITING" . t) ("NEXT"))
        ("SOMEDAY" ("WAITING" . t))
        (done ("NEXT") ("WAITING"))
        ("TODO" ("WAITING") ("CANCELED"))
        ("STARTED" ("WAITING") ("CANCELED"))
        ("PROJECT" ("CANCELED") ("PROJECT" . t))))

; Quick tags, add with C-c C-q
(setq org-tag-alist '(("NEXT" . ?n)
                      ("WAITING" . ?w)
                      ("REFILE" . ?r)))

; Custom agenda
(setq org-agenda-custom-commands 
      '(("P" "Projects" tags "/!PROJECT" ((org-use-tag-inheritance nil)))
        ("s" "Started Tasks" todo "STARTED" ((org-agenda-todo-ignore-with-date nil)))
        ("w" "Tasks waiting on something" tags "WAITING" ((org-use-tag-inheritance nil)))
        ("r" "Refile New Notes and Tasks" tags "REFILE" ((org-agenda-todo-ignore-with-date nil)))
        ("n" "Notes" tags "NOTES" nil)))

; Define stuck projects as PROJECT-tag trees ones without a NEXT action.
(setq org-stuck-projects '("/PROJECT" nil ("NEXT") ""))

; Support for task effort estimates

; Do effort estimates by going into column mode with C-c C-x C-c and choosing
; a value in the Effort field.

; Set up the effort value for column-mode view.
(setq org-columns-default-format "%80ITEM(Task) %10Effort(Effort){:} %10CLOCKSUM")
; Set up predefined effort values.
(setq org-global-properties '(("Effort_ALL" . "0:10 0:30 1:00 2:00 3:00 4:00 5:00 6:00 8:00")))

; Appointments from org agenda

; Rebuild reminders whenever agenda is modified.
; XXX: Clears all appts set via other means.
(defun regenerate-org-appt ()
  (interactive)
  (setq appt-time-msg-list nil)
  (org-agenda-to-appt))

(regenerate-org-appt)

(add-hook 'org-finalize-agenda 'regenerate-org-appt)

(appt-activate t)

; Bring up the next day's appointments after midnight.
(run-at-time "24:01" nil 'my-org-agenda-to-appt)

; Org and remember mode
(require 'remember)
(org-remember-insinuate)

; Key binding for doing org-remember
; XXX: Clobbers regexp-search backwards.
(global-set-key (kbd "C-M-r") 'org-remember)

; Collection bins for notes and tasks entered via remember.
; You can add the line
; #+FILETAGS: REFILE
; in the collection files to mark the entries as ones that should be refiled
; to more proper locations in due course.

; Put remember files in home or work subdir depending on which exists.
(let* ((prefix
        (cond ((file-exists-p "~/org/home") "~/org/home/")
              ((file-exists-p "~/org/work") "~/org/work/")
              (t "~/org/")))
       
       (tasks-file (concat prefix "tasks.org"))
       (notes-file (concat prefix "notes.org")))

  (setq org-remember-templates `(("todo" ?t "* TODO %?
  %u
  %a" ,tasks-file bottom nil)
                                 ("note" ?n "* %?
  %u
  %a" ,notes-file bottom nil))))

; Refiling settings

(setq org-completion-use-ido t)
(setq org-refile-targets '((org-agenda-files :maxlevel . 5) (nil :maxlevel . 5)))
(setq org-refile-use-outline-path (quote file))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C / C++

(setq c-basic-offset 2)

; Modified k&r. Don't indent namespaces since nested namespaces will then lead
; to unnecessary multiple indent levels.
(defconst personal-c-style
  '("k&r"
;    (c-offsets-alist . ((innamespace . 0) (defun-open . 0) ))))
    (c-offsets-alist . ((defun-open . 0) (inline-open . 0) ))))

(c-add-style "personal-c-style" personal-c-style)

(setq c-default-style '((other . "personal-c-style")))

; Keep the clock running on the remember item.
(setq org-remember-clock-out-on-exit nil)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; C#

(autoload 'csharp-mode "csharp-mode" "Major mode for editing C# code." t)
(setq auto-mode-alist (append '(("\\.cs$" . csharp-mode)) auto-mode-alist))

(defun insert-doc-comment-skeleton (tagname arg)
  (c-indent-command)
  (insert (format "/// <%s" tagname))
  (if arg (insert (format " name=\"%s\"" arg)))
  (insert ">")
  (newline-and-indent)
  (insert "///")
  (newline-and-indent)
  (insert (format "/// </%s>" tagname))
  (forward-line -1)
  (end-of-line)
  (insert " "))

(defun insert-doc-comment ()
  (interactive)
  (let ((elem (read-string "Element name? "))
        (arg (read-string "Parameter name? (Leave empty to skip) ")))
    (insert-doc-comment-skeleton elem (if (string= arg "") nil arg))))

(defun my-csharp-mode-hook ()
  ; Interpret the XML tags of C# doc comments as paragraph separators so that
  ; fill-paragraph can be cleanly applied to text between them.
  ; Modified from the initial cc-mode paragraph-separate value:
  ; "[ \t]*\\(//+\\|\\**\\)[ \t]*$\\|^"
  (setq paragraph-separate "[ \t]*\\(//+\\|\\**\\)[ \t]*\\($\\|<[^>]*>[ \t]*\\)\\|^")

  ; XXX: csharp-mode-map doesn't seem to work, c-mode-map does?
  (define-key c-mode-map "\C-c\C-z" 'insert-doc-comment))

(add-hook 'csharp-mode-hook 'my-csharp-mode-hook)

;;; Ant / NAnt files
(setq auto-mode-alist (append '(("\\.build$" . xml-mode)) auto-mode-alist))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SML

;;; MLB modle
(autoload 'esml-mlb-mode "esml-mlb-mode")
(add-to-list 'auto-mode-alist '("\\.mlb\\'" . esml-mlb-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Python

(setq py-indent-offset 2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lua

(setq lua-indent-level 2)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; File templates

(if (>= emacs-major-version 22)
    (add-to-list 'find-file-not-found-functions 'add-file-template)
  (print "Old Emacs, template system inactive."))

(defun parent-dir-conjunction (func)
  "Start from the current directory and iterate towards the root
  directory. Apply func to each directory, and return the first
  non-nil result func returns. If func returns nil for all
  directories, return nil."
  (let ((path (file-name-directory (buffer-file-name)))
        (result nil)
        )
    (while (and (not result) (> (length path) 0))
      (setq result (funcall func path))
      (setq path (if (string-equal path "/")
                     ""
                   (file-name-directory (substring path 0 -1)))))
    result))

(defun file-in-dir-p (dir file)
  "Return full path to file if file is found in dir, nil otherwise."
  ; XXX: Returns directories as well.
  (let ((fullpath (concat dir file)))
    (if (file-readable-p fullpath) fullpath nil)))

(defun find-file-in-parent-dirs (filename)
  "Look for a specific file in current and parent directories.
  Return full path to file if found. Return nil otherwise."
  (parent-dir-conjunction (lambda (path) (file-in-dir-p path filename))))

(defun add-file-template ()
  (let* ((file-name (buffer-file-name))
         (extension (file-name-extension file-name))
         (template-name (concat "file-template-" extension))
         (template-file (find-file-in-parent-dirs template-name)))
    (if (and extension template-file)
        (load template-file))))

(defun insert-cpp-namespace (namespace)
  "Print a nested namespace from a list of namespace names."
  (if namespace
      (progn
        (insert (format "namespace %s {\n" (car namespace)))
        (insert-cpp-namespace (cdr namespace))
        (insert "}\n"))
    (insert "\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Vimpulse mode

; Permutate HJKL bindings to make sense with a Colemak keymap.
(defun viper-colemak-hjkl ()
  (interactive)
  (define-key viper-vi-global-user-map "j" 'viper-backward-char)
  (define-key viper-vi-global-user-map "k" 'viper-next-line)
  (define-key viper-vi-global-user-map "h" 'viper-previous-line)
  (define-key viper-vi-global-user-map "l" 'viper-forward-char))

(defun vimpulse-on ()
  (interactive)
  (require 'rect-mark)               ; Vim-style rectangle selection highlight
  (setq viper-mode t)                ; enable Viper at load time
  (setq viper-ex-style-editing nil)  ; can backspace past start of insert / line
  (require 'viper)                   ; load Viper
  (require 'vimpulse)                ; load Vimpulse
  (viper-colemak-hjkl)
  (setq woman-use-own-frame nil)     ; don't create new frame for manpages
  (setq woman-use-topic-at-point t)) ; don't prompt upon K key (manpage display)

; (vimpulse-on)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Version control

; Don't ask about following symlinks to svn files.
(setq vc-follow-symlinks nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Custom key bindings

; Bind autocomplete to C-Tab
(global-set-key (kbd "C-<tab>") 'dabbrev-expand)
(define-key minibuffer-local-map (kbd "C-<tab>") 'dabbrev-expand)

; Use C-q as backward-kill-word. The quoted-insert is rare and can be beyond a
; more complex binding.

(global-set-key "\C-q" 'backward-kill-word)
(global-set-key "\C-\M-q" 'quoted-insert)

; Accessing various modes from anywhere

; Allow F9 to serve as a prefix key
(global-set-key (kbd "<f9>") (make-sparse-keymap))

; Show org agenda
(global-set-key (kbd "<f9> a") 'org-agenda)
; Show calendar
(global-set-key (kbd "<f9> c") 'calendar)
; Show calculator
(global-set-key (kbd "<f9> l") 'calc)
; Go to currently clocked task
(global-set-key (kbd "<f9> o") 'org-clock-goto)

; Moving up and down is useful, moving to next and previous word is useful.
; These should both be under the same mode key. M-n and M-p are unbound, so...

(global-set-key "\M-p" 'previous-line)
(global-set-key "\M-n" 'next-line)

; Buffer and window navigation

(defun exhume-buffer ()
  "Switch to the buffer at the bottom of the buffer list. Opposite to (bury-buffer)."
  (interactive)
  (switch-to-buffer (car (reverse (buffer-list)))))

(defun in-other-buffer (f)
  "Perform a function when switched to the other window."
  (interactive)
  (other-window 1)
  (funcall f)
  (other-window -1))

; Buffer navigation
(global-set-key [f12] 'exhume-buffer)
(global-set-key [f11] 'bury-buffer)

(global-set-key [C-f12] (lambda () (interactive) (in-other-buffer 'exhume-buffer)))
(global-set-key [C-f11] (lambda () (interactive) (in-other-buffer 'bury-buffer)))

; Replace the useless default buffer list with a better one.
(global-set-key "\C-x\C-b" 'buffer-menu)

; Window navigation
(global-set-key (kbd "C-,") (lambda () (interactive) (other-window -1)))
(global-set-key (kbd "C-.") 'other-window)

; Vim-style jumping to the opposing paren
(defun goto-match-paren (arg)
  "Go to the matching parenthesis if on parenthesis, otherwise insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))
(global-set-key (kbd "C-%") 'goto-match-paren)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Global settings

; Do not use physical tabs.
(setq-default indent-tabs-mode nil)
(setq column-number-mode t)

; Insert automatic line breaks in text mode.
(add-hook 'text-mode-hook 'turn-on-auto-fill)
(setq-default fill-column 78)

; Do not use doubled space after a period.
(setq sentence-end-double-space nil)

; Syntax highlighting is nice.
(global-font-lock-mode 1)

; Highlighted selections are also nice.
(transient-mark-mode 1)

(mouse-wheel-mode t)

; Backup files are messy, maybe we don't want them.
(setq make-backup-files nil)

; No bell.
(setq visible-bell t)

; No blink
(blink-cursor-mode 0)

; Start the server so we can use emacsclient
; This doesn't work in MS Windows, so we use the conditional.
(when (and first-evaluation-of-dot-emacs (not (eq window-system 'w32)))
   (server-start))

; I like to see everything on the screen
(set-variable 'truncate-lines t)

; And with modern monitors I can even keep my partial width windows at least
; 80 columns wide.
(set-variable 'truncate-partial-width-windows nil)

; Move between windows with shift + arrow keys. (The default compatibility fix
; with org-mode only handles shift-arrows)
(windmove-default-keybindings)

; We've seen it already.
(setq inhibit-startup-message t)

; Quicker line removal. Use C-k to erase even non-empty lines when at column 1.
(setq kill-whole-line t)

; Autocleanse end-of-line whitespace.
; (Commented out for now, can't be used when developing code collaboratively
; since it messes up patches with whitespace elimination noise.)
;(add-hook 'before-save-hook 'delete-trailing-whitespace)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc functions

; Whether two strings are equal up to the length of the shortest string.
(defun has-prefix (prefix string) (eq (string-match prefix string) 0))

(defun current-year () (format-time-string "%Y"))

(defun roll ()
  "Roll dice interactively."
  (interactive)
  (let* ((dice-str (split-string (read-string "Roll ?d? ") "d"))
         (n (string-to-int (car dice-str)))
         (d (string-to-int (cadr dice-str)))
         (res 0))
    (while (> n 0)
      (setq res (+ res (+ 1 (random d))))
      (setq n (- n 1)))
    (print res)))

(defun join-strings (seq &optional separator)
  "Join a sequence of strings into one string with a separator."
  (if seq
      (if (cdr seq) ; If more than one item, put the separator between them.
          (concat (car seq) separator (join-strings (cdr seq) separator))
        (car seq))
    ""))

(defun prefix-lines-with (prefix text)
  (let* ((lines (split-string text "\n"))
         (prefixed-lines (map 'list (lambda (line) (concat prefix line)) lines)))
    (join-strings prefixed-lines "\n")))

(defun cpp-comment (text)
  "Convert a text block into a C++ style comment."
  (prefix-lines-with "// " text))

(defun scheme-comment (text)
  "Convert a text block into a Scheme comment."
  (prefix-lines-with "; " text))

(defun lua-comment (text)
  "Convert a text block into a Lua comment."
  (prefix-lines-with "-- " text))

(defun mit-license-text ()
  (let
      ((author "Risto Saarelma"))
    (concat
     "The MIT License\n"
     "\n"
     (format "Copyright (c) %s %s\n" (current-year) author)
     "\n"
     "Permission is hereby granted, free of charge, to any person obtaining a copy\n"
     "of this software and associated documentation files (the \"Software\"), to deal\n"
     "in the Software without restriction, including without limitation the rights\n"
     "to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"
     "copies of the Software, and to permit persons to whom the Software is\n"
     "furnished to do so, subject to the following conditions:\n"
     "\n"
     "The above copyright notice and this permission notice shall be included in\n"
     "all copies or substantial portions of the Software.\n"
     "\n"
     "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n"
     "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n"
     "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n"
     "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n"
     "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n"
     "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN\n"
     "THE SOFTWARE.\n")))

(defun mit-header-cpp ()
  (interactive)
  (insert (cpp-comment (mit-license-text)) "\n"))

(defun mit-header-lua ()
  (interactive)
  (insert (lua-comment (mit-license-text)) "\n"))

; Some unmaintained HTML scraping tools.
(defun extract-title-from-html-buffer ()
  (beginning-of-buffer)
  (let* ((open "<title>")
         (close "</title>")
         (title-begin (re-search-forward open))
         (title-end (- (re-search-forward close) (length close))))
    (buffer-substring title-begin title-end)))

(defun scrape-title (url)
  "Return the title of the page an URL points to."
  (condition-case nil
    (let
        ((buffer (url-retrieve-synchronously url)))
      (with-current-buffer buffer
        (extract-title-from-html-buffer)))
  (error url)))

; BUG: Broken with non-HTML files. Don't use. The scraper code is probably dodgy even with HTML.
(defun bib-url ()
  "Insert an org node for a WWW resource"
  (interactive)
  (let*
      ((url (read-from-minibuffer "URL: "))
       (id (read-from-minibuffer "Id tag: "))
       ; Try to scrape a title from the URL's site. If this fail, use id
       (title-attempt (scrape-title url))
       (title (if (= title-attempt url) id title-attempt)))
    (org-insert-heading-after-current)
    (insert
     (concat "<<<" id ">>> " title " :www:\n"
             "   :PROPERTIES:\n"
             "   :bibtexcat: misc\n"
             "   :bibtexid: " id "\n"
             "   :title:   " title "\n"
             "   :URL:     " url "\n"
             "   :read_date: " (format-time-string "%Y-%m-%d") "\n"
             "   :END:\n"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Load host-specific configurations

; Load local configuration elisp files from the designated directory.
(let ((local-config-dir "~/.elisp/local"))
  (if (file-directory-p local-config-dir)
      (mapc #'load (directory-files local-config-dir t "\\.el$"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Final touches

(setq first-evaluation-of-dot-emacs nil)

(setq debug-on-error nil)
