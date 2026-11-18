;;; doctor.el --- Health check and package snapshot  -*- lexical-binding: t; -*-
;;;
;;; M-x suhas/doctor  (SPC c h)   what works, what is missing, and what to
;;;                               install -- run it first on any new machine.
;;; M-x suhas/package-snapshot    (SPC c s) record installed package versions
;;;                               in package-versions.eld (commit that file).
;;; M-x suhas/package-drift       (SPC c d) compare this machine to the snapshot.

(require 'cl-lib)

;;; ------------------------------------------------------------
;;; Doctor
;;; ------------------------------------------------------------

(defun suhas/doctor--exe (&rest names)
  "First of NAMES found on `exec-path', or nil."
  (seq-some #'executable-find names))

(defun suhas/doctor--line (status label detail)
  "One report line. STATUS is `ok', `warn', `fail' or `info'."
  (format "  %-6s %-30s %s\n"
          (pcase status ('ok "[ok]") ('warn "[warn]") ('fail "[FAIL]") (_ "[..]"))
          label detail))

(defun suhas/doctor--report ()
  "Return the health report as a string."
  (let ((out ""))
    (cl-flet ((add (status label detail)
                (setq out (concat out (suhas/doctor--line status label detail))))
              (heading (title)
                (setq out (concat out "\n" title "\n"))))
      (heading "EMACS")
      (add (if (version< emacs-version "31.1") 'fail 'ok)
           "Emacs version" (format "%s (needs 31.1+)" emacs-version))
      (add (if (fboundp 'module-load) 'ok 'fail)
           "dynamic modules"
           (if (fboundp 'module-load) "available (the terminal needs this)"
             "MISSING: this Emacs cannot load native modules; the terminal will not work"))
      (add (if (sqlite-available-p) 'ok 'warn)
           "sqlite" "needed by org-roam and forge")
      (add (if (native-comp-available-p) 'ok 'info)
           "native compilation" "optional; makes packages faster")
      (add 'info "init time" (emacs-init-time))
      (add (if suhas/failed-modules 'fail 'ok)
           "modules"
           (if suhas/failed-modules
               (format "FAILED to load: %s (see *Warnings*)"
                       (mapconcat #'identity suhas/failed-modules ", "))
             (format "all %d loaded" (1+ (length suhas/modules)))))
      (add (if suhas--package-install-failed 'fail 'ok)
           "packages"
           (if suhas--package-install-failed
               "an install FAILED this session (network/proxy?); restart when fixed"
             (format "%d active" (length package-activated-list))))
      (add (if (file-exists-p (expand-file-name "local.el" user-emacs-directory)) 'ok 'info)
           "local.el" "your machine settings (SPC c o to open / create)")

      (heading "REQUIRED TOOLS")
      (dolist (spec '(("git" "git")
                      ("ripgrep (rg)" "rg")
                      ("fd" "fd" "fdfind")))
        (let ((found (apply #'suhas/doctor--exe (cdr spec))))
          (add (if found 'ok 'fail) (car spec)
               (or found "NOT FOUND -- SPC s f / SPC s g need it"))))

      (heading "CODE FOLDERS")
      (let ((roots (suhas/repo-roots)))
        (add (if roots 'ok 'warn) "repo roots"
             (if roots
                 (mapconcat #'abbreviate-file-name roots ", ")
               "none exist; set `suhas/repo-root-candidates' in local.el"))
        (add 'info "project scan depth" (number-to-string suhas/repo-root-depth)))

      (when (fboundp 'suhas/treesit-status)
        (heading (format "TREE-SITTER GRAMMARS (this Emacs loads ABI %d-%d; SPC c g builds missing ones)"
                         (treesit-library-abi-version t) (treesit-library-abi-version)))
        (add (if (and (suhas/doctor--exe "git") (suhas/doctor--exe "cc" "gcc" "clang")) 'ok 'warn)
             "build tools" "git and a C compiler are needed to build grammars")
        (pcase-dolist (`(,lang ,state ,detail) (suhas/treesit-status))
          (add (pcase state ('ok 'ok) ('broken 'fail) (_ 'info))
               (symbol-name lang)
               (pcase state
                 ('ok (format "installed (ABI %s)" detail))
                 ('broken (format "DOES NOT LOAD: %s -- rebuild with C-u SPC c g" detail))
                 (_ "not installed; the classic mode (if any) is used")))))

      (heading "LANGUAGE SERVERS (install the ones you use)")
      (dolist (spec `(("Python"      ,@(if suhas/python-lsp-command
                                           (list (car suhas/python-lsp-command))
                                         '("pylsp" "basedpyright-langserver"
                                           "pyright-langserver" "ruff")))
                      ("JS/TS/TSX"   "tsgo" "typescript-language-server")
                      ("C/C++"       "clangd")
                      ("Rust"        "rust-analyzer")
                      ("Go"          "gopls")
                      ("Java"        "jdtls")
                      ("Bash"        "bash-language-server")
                      ("YAML"        "yaml-language-server")))
        (let ((found (apply #'suhas/doctor--exe (cdr spec))))
          (add (if found 'ok 'info) (car spec) (or found "not installed"))))

      (heading "FORMATTERS (SPC e f, when the language server does not format)")
      (dolist (spec '(("Python" "black" "ruff")
                      ("JS/TS/YAML" "prettier")
                      ("C/C++" "clang-format")
                      ("Rust" "rustfmt")
                      ("Go" "gofmt")
                      ("Shell" "shfmt")))
        (let ((found (apply #'suhas/doctor--exe (cdr spec))))
          (add (if found 'ok 'info) (car spec) (or found "not installed"))))

      (heading "WORKFLOW")
      (add (if (suhas/doctor--exe "direnv") 'ok 'info) "direnv (per-project env)"
           (or (suhas/doctor--exe "direnv") "not installed; project venvs will not be picked up"))
      (add (if (suhas/doctor--exe "aspell" "hunspell" "ispell") 'ok 'info) "spellcheck"
           (or (suhas/doctor--exe "aspell" "hunspell" "ispell") "not installed; commit-message spellcheck is off"))
      (add (if (suhas/doctor--exe "node") 'ok 'info) "node"
           (or (suhas/doctor--exe "node") "not installed; pyright and the typescript server need it"))
      (add (cond ((fboundp 'ghostel--new) 'ok)
                 ((locate-library "ghostel") 'info)
                 (t 'warn))
           "ghostel (terminal)"
           (cond ((fboundp 'ghostel--new) "native module loaded")
                 ((locate-library "ghostel") "installed; the first SPC t t downloads its native module")
                 (t "not installed yet (installs on a start with network access)")))
      (add 'info "shell environment"
           (cond ((null suhas/shell-env-variables) "not imported on this platform")
                 ((file-exists-p suhas/env-cache-file)
                  "cached in env-cache.el (M-x suhas/env-refresh re-imports)")
                 (t "inherited from the launching shell")))

      (heading "DISPLAY")
      (if (display-graphic-p)
          (add (if (find-font (font-spec :family suhas/font-family)) 'ok 'info)
               "font" (format "%s%s" suhas/font-family
                              (if (find-font (font-spec :family suhas/font-family))
                                  "" " (not installed; using the default font)")))
        (add 'info "display" "terminal Emacs: C-; C-' C-, C-` are unavailable; use C-c n / p / b / t")))
    out))

(defun suhas/doctor ()
  "Show a health report: what works, what is missing (SPC c h)."
  (interactive)
  (let ((buf (get-buffer-create "*semacs-doctor*"))
        (report (suhas/doctor--report)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "semacs doctor\n")
        (insert report)
        (insert "\n[ok] fine   [warn] works but degraded   [FAIL] broken   [..] optional / FYI\n")
        (goto-char (point-min)))
      (special-mode))
    (pop-to-buffer buf)))

;;; ------------------------------------------------------------
;;; Package snapshot (a poor man's lockfile)
;;; ------------------------------------------------------------

(defconst suhas/package-snapshot-file
  (expand-file-name "package-versions.eld" user-emacs-directory)
  "Tracked record of the package versions this config was last known to work with.")

(defun suhas/--installed-package-versions ()
  "Alist (NAME . VERSION-STRING) of installed packages, sorted by name."
  (require 'package)
  (unless package--initialized (package-initialize t))
  (sort (mapcar (lambda (entry)
                  (cons (symbol-name (car entry))
                        (package-version-join
                         (package-desc-version (cadr entry)))))
                package-alist)
        (lambda (a b) (string< (car a) (car b)))))

(defun suhas/package-snapshot ()
  "Write installed package versions to `suhas/package-snapshot-file' (SPC c s).
Commit the file. On another machine, `suhas/package-drift' shows what differs
from it, which is the first thing to check when it works on one machine only."
  (interactive)
  (with-temp-file suhas/package-snapshot-file
    (let ((print-length nil) (print-level nil))
      (insert (format ";; semacs package snapshot -- generated by M-x suhas/package-snapshot\n"))
      (insert (format ";; Emacs %s\n" emacs-version))
      (prin1 `(:emacs ,emacs-version :packages ,(suhas/--installed-package-versions))
             (current-buffer))
      (insert "\n")))
  (message "Wrote %s (%d packages)"
           (abbreviate-file-name suhas/package-snapshot-file)
           (length package-alist)))

(defun suhas/package-drift ()
  "Report packages whose version differs from the snapshot (SPC c d)."
  (interactive)
  (if (not (file-exists-p suhas/package-snapshot-file))
      (user-error "No snapshot yet; run M-x suhas/package-snapshot on a working setup")
    (let* ((snap (with-temp-buffer
                   (insert-file-contents suhas/package-snapshot-file)
                   (goto-char (point-min))
                   (read (current-buffer))))
           (want (plist-get snap :packages))
           (have (suhas/--installed-package-versions))
           lines)
      (dolist (w want)
        (let ((h (assoc (car w) have)))
          (cond ((null h) (push (format "  missing   %s (snapshot %s)" (car w) (cdr w)) lines))
                ((not (equal (cdr h) (cdr w)))
                 (push (format "  differs   %s: have %s, snapshot %s" (car w) (cdr h) (cdr w)) lines)))))
      (dolist (h have)
        (unless (assoc (car h) want)
          (push (format "  extra     %s %s (not in snapshot)" (car h) (cdr h)) lines)))
      (if (null lines)
          (message "Packages match the snapshot (Emacs %s there, %s here)."
                   (plist-get snap :emacs) emacs-version)
        (with-current-buffer (get-buffer-create "*semacs-drift*")
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert (format "Snapshot made with Emacs %s; this is Emacs %s\n\n"
                            (plist-get snap :emacs) emacs-version))
            (insert (mapconcat #'identity (nreverse lines) "\n") "\n"))
          (special-mode)
          (goto-char (point-min))
          (pop-to-buffer (current-buffer)))))))

(suhas/leader
 "c h" #'suhas/doctor
 "c g" #'suhas/treesit-install
 "c s" #'suhas/package-snapshot
 "c d" #'suhas/package-drift)

;;; doctor.el ends here
