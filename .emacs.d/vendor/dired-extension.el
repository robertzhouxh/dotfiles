<!DOCTYPE html>
<html><head><title>EmacsWiki: dired-extension.el</title><link rel="alternate" type="application/wiki" title="Edit this page" href="https://www.emacswiki.org/emacs?action=edit;id=dired-extension.el" /><link type="text/css" rel="stylesheet" href="https://www.emacswiki.org/light.css" /><meta name="robots" content="INDEX,FOLLOW" /><link rel="alternate" type="application/rss+xml" title="EmacsWiki" href="https://www.emacswiki.org/emacs?action=rss" /><link rel="alternate" type="application/rss+xml" title="EmacsWiki: dired-extension.el" href="https://www.emacswiki.org/emacs?action=rss;rcidonly=dired-extension.el" />
<link rel="alternate" type="application/rss+xml"
      title="Emacs Wiki with page content"
      href="https://www.emacswiki.org/full.rss" />
<link rel="alternate" type="application/rss+xml"
      title="Emacs Wiki with page content and diff"
      href="https://www.emacswiki.org/full-diff.rss" />
<link rel="alternate" type="application/rss+xml"
      title="Emacs Wiki including minor differences"
      href="https://www.emacswiki.org/minor-edits.rss" />
<link rel="alternate" type="application/rss+xml"
      title="Changes for dired-extension.el only"
      href="https://www.emacswiki.org/emacs?action=rss;rcidonly=dired-extension.el" /><meta content="width=device-width" name="viewport" />
<script type="text/javascript" src="/outliner-toc.js"></script>
<script type="text/javascript">

  function addOnloadEvent(fnc) {
    if ( typeof window.addEventListener != "undefined" )
      window.addEventListener( "load", fnc, false );
    else if ( typeof window.attachEvent != "undefined" ) {
      window.attachEvent( "onload", fnc );
    }
    else {
      if ( window.onload != null ) {
	var oldOnload = window.onload;
	window.onload = function ( e ) {
	  oldOnload( e );
	  window[fnc]();
	};
      }
      else
	window.onload = fnc;
    }
  }

  // https://stackoverflow.com/questions/280634/endswith-in-javascript
  if (typeof String.prototype.endsWith !== 'function') {
    String.prototype.endsWith = function(suffix) {
      return this.indexOf(suffix, this.length - suffix.length) !== -1;
    };
  }

  var initToc=function() {

    var outline = HTML5Outline(document.body);
    if (outline.sections.length == 1) {
      outline.sections = outline.sections[0].sections;
    }

    if (outline.sections.length > 1
	|| outline.sections.length == 1
           && outline.sections[0].sections.length > 0) {

      var toc = document.getElementById('toc');

      if (!toc) {
	var divs = document.getElementsByTagName('div');
	for (var i = 0; i < divs.length; i++) {
	  if (divs[i].getAttribute('class') == 'toc') {
	    toc = divs[i];
	    break;
	  }
	}
      }

      if (!toc) {
	var h2 = document.getElementsByTagName('h2')[0];
	if (h2) {
	  toc = document.createElement('div');
	  toc.setAttribute('class', 'toc');
	  h2.parentNode.insertBefore(toc, h2);
	}
      }

      if (toc) {
        var html = outline.asHTML({createLinks: true, skipToHeader: true});
        toc.innerHTML = html;

	items = toc.getElementsByTagName('a');
	for (var i = 0; i < items.length; i++) {
	  while (items[i].textContent.endsWith('✎')) {
            var text = items[i].childNodes[0].nodeValue;
	    items[i].childNodes[0].nodeValue = text.substring(0, text.length - 1);
	  }
	}
      }
    }
  }

  addOnloadEvent(initToc);
  </script>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" /></head><body class="default" lang="en"><header><a class="logo" href="https://www.emacswiki.org/emacs/SiteMap"><img alt="[Home]" class="logo" src="https://www.emacswiki.org/images/logo218x38.png" /></a><nav><span class="gotobar bar"><a class="local" href="https://www.emacswiki.org/emacs/SiteMap">SiteMap</a> <a class="local" href="https://www.emacswiki.org/emacs/Search">Search</a> <a class="local" href="https://www.emacswiki.org/emacs/ElispArea">ElispArea</a> <a class="local" href="https://www.emacswiki.org/emacs/HowTo">HowTo</a> <a class="local" href="https://www.emacswiki.org/emacs/Glossary">Glossary</a> <a class="local" href="https://www.emacswiki.org/emacs/RecentChanges">RecentChanges</a> <a class="local" href="https://www.emacswiki.org/emacs/News">News</a> <a class="local" href="https://www.emacswiki.org/emacs/Problems">Problems</a> <a class="local" href="https://www.emacswiki.org/emacs/Suggestions">Suggestions</a> </span><form method="get" action="https://www.emacswiki.org/emacs" enctype="multipart/form-data" accept-charset="utf-8" class="search"><p><label for="search">Search:</label> <input type="text" name="search"  size="15" accesskey="f" id="search" /> <label for="searchlang">Language:</label> <input type="text" name="lang"  size="5" id="searchlang" /> <input type="submit" name="dosearch" value="Go!" /></p></form></nav><h1><a href="https://www.emacswiki.org/emacs?search=%22dired-extension%5c.el%22" rel="nofollow" title="Click to search for references to this page">dired-extension.el</a></h1></header><div class="wrapper"><div class="content browse" lang="en"><p class="download"><a href="https://www.emacswiki.org/emacs/download/dired-extension.el">Download</a> <a href="https://github.com/emacsmirror/emacswiki.org/blob/master/dired-extension.el">Git</a></p><pre>;;; dired-extension.el --- Some extension for dired

;; Author: Andy Stewart lazycat.manatee@gmail.com
;; Maintainer: Andy Stewart lazycat.manatee@gmail.com
;; Copyright (C) 2008 ~ 2016, Andy Stewart, all rights reserved.
;; Created: 2008-10-11 22:57:07
;; Version: 0.3
;; Last-Updated: 2018-07-02 17:30:09
;; URL:
;; Keywords: dired
;; Compatibility: GNU Emacs 27.0.50

;; This file is not part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Features that might be required by this library:
;;
;;

;;; Overview:
;;
;; This package is some extension for `dired'.
;;

;;; Commentary:
;;
;; This package is some extension for `dired'.
;;

;;; Installation:
;;
;; Put dired-extension.el to your load-path.
;; The load-path is usually ~/elisp/.
;; It's set in your ~/.emacs like this:
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;;
;; And the following to your ~/.emacs startup file.
;;
;; (require 'dired-extension)
;;
;; No need more

;;; Configuration:
;;
;;
;;

;;; Change log:
;;
;; 2016/07/02
;;      * Move function `file-binary-p' to `moccur-extension.el'
;;
;; 2016/06/29
;;      * Move moccur function to `moccur-extension.el'.
;;
;; 2016/6/6
;;      * Build new function `moccur-grep-find-without-binary-files' that make `moccur-grep-find-pwd' remove binary files from search result.
;;        I hate cross binary files in moccur search result.
;;
;; 2008/10/11
;;      * First released.
;;

;;; Acknowledgements:
;;
;;
;;

;;; TODO
;;
;;
;;

;;; Require

;;; Code:
(defvar my-dired-omit-status t
  "The status of dired omit file.")
(defvar my-dired-omit-regexp "^\\.?#\\|^\\..*"
  "The regexp string that matching omit files.")
(defvar my-dired-omit-extensions '(".cache")
  "The list that matching omit file's extension.")

;; Advice `dired-run-shell-command' with asynchronously.
(defadvice dired-run-shell-command (around dired-run-shell-command-async activate)
  "Postfix COMMAND argument of `dired-run-shell-command' with an ampersand.
If there is none yet, so that it is run asynchronously."
  (let* ((cmd (ad-get-arg 0))
         (cmd-length (length cmd))
         (last-cmd-char (substring cmd
                                   (max 0 (- cmd-length 1))
                                   cmd-length)))
    (unless (string= last-cmd-char "&amp;")
      (ad-set-arg 0 (concat cmd "&amp;")))
    (save-window-excursion ad-do-it)))

(defun dired-sort-method ()
  "The sort method of `dired'."
  (let (buffer-read-only)
    (forward-line 2) ;; beyond dir. header
    (sort-regexp-fields t "^.*$" "[ ]*." (point) (point-max))))

(defun dired-omit-method ()
  "The omit method of dired."
  (when my-dired-omit-status
    (setq dired-omit-mode t)
    (setq dired-omit-files my-dired-omit-regexp)
    (setq dired-omit-extensions my-dired-omit-extensions)))

(defun dired-toggle-omit ()
  "Toggle omit status of dired files."
  (interactive)
  (if my-dired-omit-status
      (let ((dired-omit-size-limit nil))
        (setq dired-omit-mode nil)
        (dired-omit-expunge)
        (setq my-dired-omit-status nil))
    (setq dired-omit-mode t)
    (setq my-dired-omit-status t))
  (revert-buffer))

(defun dired-get-size ()
  "Get total size of marked files with `du' command.
If not marked any files, default is current file or directory."
  (interactive)
  (let ((files (dired-get-marked-files)))
    (with-temp-buffer
      (apply 'call-process "/usr/bin/du" nil t nil "-sch" files)
      (message "Size of all marked files: %s"
               (progn
                 (re-search-backward "\\(^[0-9.,]+[A-Za-z]+\\).*\\(total\\|总用量\\)$")
                 (match-string 1))))))

(defun dired-rename-with-copy ()
  "Rename name in Dired, and copy current name in yank."
  (interactive)
  (dired-copy-filename-as-kill)
  (dired-do-rename))

(defun dired-up-directory-single ()
  "Return up directory in single window.
When others visible window haven't current buffer, kill old buffer after `dired-up-directory'.
Otherwise, just `dired-up-directory'."
  (interactive)
  (let ((old-buffer (current-buffer))
        (current-window (selected-window)))
    (dired-up-directory)
    (catch 'found
      (walk-windows
       (lambda (w)
         (with-selected-window w
           (when (and (not (eq current-window (selected-window)))
                      (equal old-buffer (current-buffer)))
             (throw 'found "Found current dired buffer in others visible window.")))))
      (kill-buffer old-buffer))))

(defun dired-find-file+ ()
  "Like `dired-find-file'.
When open directory, if others visible window have this directory, do `find-file'.
Otherwise do `find-alternate-file'.
When open file, always use `find-file'."
  (interactive)
  (set-buffer-modified-p nil)
  (let ((file (dired-get-file-for-visit))
        (old-buffer (current-buffer))
        (current-window (selected-window)))
    (if (file-directory-p file)
        (catch 'found
          (walk-windows
           (lambda (w)
             (with-selected-window w
               (when (and (not (eq current-window (selected-window)))
                          (equal old-buffer (current-buffer)))
                 (find-file file)
                 (throw 'found "Found current dired buffer in others visible window.")))))
          (find-alternate-file file))
      (find-file file))))

(defun dired-serial-rename (dir ext name start)
  "Rename sequentially a set of file with the extension EXT.
In a repertory DIR with the name name + the start number start."
  (interactive "fDir: \nsExt(no dot): \nsName: \nnStart: ")
  (find-file dir)
  (let (ls-dir
        new-ls-dir
        n
        c)
    (setq ls-dir (file-expand-wildcards (format "*.%s" ext) t))
    (setq new-ls-dir nil)
    (setq n 0)
    (while (&lt; n (length ls-dir))
      (if (&lt; start 10)
          (push (concat dir name (format "0%s" start) "." ext) new-ls-dir)
        (push (concat dir name (format "%s" start) "." ext) new-ls-dir))
      (incf start)
      (incf n))
    (setq ls-dir (reverse ls-dir))
    (setq c 0)
    (dolist (i ls-dir)
      (rename-file i (nth c new-ls-dir))
      (incf c))))

(defun dired-next-file-line ()
  "Move to the next dired line that have a file or directory name on it."
  (interactive)
  (call-interactively 'dired-next-line)
  (if (eobp)
      (dired-previous-line 1)))

(defun dired-move-to-first-file ()
  "Move cursor to first file of dired."
  (interactive)
  (goto-char (point-min))
  (while (not (dired-move-to-filename))
    (call-interactively 'dired-next-line)))

(defun dired-move-to-last-file ()
  "Move cursor to last file of dired."
  (interactive)
  (goto-char (point-max))
  (while (not (dired-move-to-filename))
    (call-interactively 'dired-previous-line)))

(defun dired-previous-file-line ()
  "Move to the previous dired line that have a file or directory name on it."
  (interactive)
  (call-interactively 'dired-previous-line)
  (if (not (dired-move-to-filename))
      (dired-next-line 1)))

(defun dired-nautilus ()
  "Load current directory with nautilus."
  (interactive)
  (shell-command
   (concat "nautilus " (dired-current-directory))))

(defun dired-touch-now (touch-file)
  "Do `touch' command with TOUCH-FILE."
  (interactive "sTouch file: ")
  (cd (dired-current-directory))
  (shell-command
   (concat "touch \""
           ;; if filename is begin with `-', add '-- ' before file-name
           (if (string-match "^-.*" touch-file) "-- ")
           touch-file "\""))
  (sit-for 0.1)
  (revert-buffer)
  (dired-goto-file (concat (dired-current-directory) touch-file)))

(defun dired-gnome-open-file ()
  "Opens the current file in a Dired buffer."
  (interactive)
  (gnome-open-file (dired-get-file-for-visit)))

(defun gnome-open-file (filename)
  "gnome-opens the specified file."
  (interactive "fFile to open: ")
  (let ((process-connection-type nil))
    (start-process "" nil "/usr/bin/xdg-open" filename)))

(defun gnome-open-buffer ()
  "Open current buffer file with gnome."
  (interactive)
  (gnome-open-file buffer-file-name))

(defun dir-file-ext-my (file)
  "Given a full file's path name, returns a list of directory, filename
and extension.  The extension contains the ., and the directory
contains the /
See also file-name-directory and file-name-nondirectory.."
  (interactive "s String: ")
  (with-temp-buffer
    (insert file)
    (goto-char (point-max))
    (let ((aa (progn
                (goto-char (point-max))
                (search-backward "/" nil t)))
          (bb (progn
                (goto-char (point-max))
                (search-backward "." nil t))))
      (setq aa (if (null aa) (point-min) (+ aa 1)))
      (if (null bb) (setq bb (point-max)))
      (if (&gt; aa bb) (setq bb (point-max))) ;that means that the . occurs in
                                        ;the path name rather than filename.
      (let ((cc
             (list
              (buffer-substring (point-min) aa)
              (buffer-substring aa bb)
              (buffer-substring bb (point-max)))))
        (if (interactive-p) (message "%S" cc))
        cc))))

(defun find-lisp-find-dired-pwd (regexp)
  "Find files in DIR, matching REGEXP."
  (interactive "sMatching regexp: ")
  (find-lisp-find-dired default-directory regexp))

(provide 'dired-extension)
;;; dired-extension.el ends here</pre></div><div class="wrapper close"></div></div><footer><hr /><span class="translation bar"><br />  <a class="translation new" href="https://www.emacswiki.org/emacs?action=translate;id=dired-extension.el;missing=de_es_fr_it_ja_ko_pt_ru_se_uk_zh" rel="nofollow">Add Translation</a></span><div class="edit bar"><a accesskey="c" class="comment local edit" href="https://www.emacswiki.org/emacs/Comments_on_dired-extension.el">Talk</a> <a accesskey="e" class="edit" href="https://www.emacswiki.org/emacs?action=edit;id=dired-extension.el" rel="nofollow" title="Click to edit this page">Edit this page</a> <a class="history" href="https://www.emacswiki.org/emacs?action=history;id=dired-extension.el" rel="nofollow">View other revisions</a> <a class="admin" href="https://www.emacswiki.org/emacs?action=admin;id=dired-extension.el" rel="nofollow">Administration</a></div><div class="time">Last edited 2018-07-02 09:32 UTC by <a class="author" href="https://www.emacswiki.org/emacs/AndyStewart">AndyStewart</a> <a class="diff" href="https://www.emacswiki.org/emacs?action=browse;diff=2;id=dired-extension.el" rel="nofollow">(diff)</a></div><div style="float:right; margin-left:1ex;">
<!-- Creative Commons License -->
<a class="licence" href="https://creativecommons.org/licenses/GPL/2.0/"><img alt="CC-GNU GPL" style="border:none" src="/pics/cc-GPL-a.png" /></a>
<!-- /Creative Commons License -->
</div>

<!--
<rdf:RDF xmlns="http://web.resource.org/cc/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
<Work rdf:about="">
   <license rdf:resource="https://creativecommons.org/licenses/GPL/2.0/" />
  <dc:type rdf:resource="http://purl.org/dc/dcmitype/Software" />
</Work>

<License rdf:about="https://creativecommons.org/licenses/GPL/2.0/">
   <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
   <permits rdf:resource="http://web.resource.org/cc/Distribution" />
   <requires rdf:resource="http://web.resource.org/cc/Notice" />
   <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
   <requires rdf:resource="http://web.resource.org/cc/ShareAlike" />
   <requires rdf:resource="http://web.resource.org/cc/SourceCode" />
</License>
</rdf:RDF>
-->

<p class="legal">
This work is licensed to you under version 2 of the
<a href="https://www.gnu.org/">GNU</a> <a href="/GPL">General Public License</a>.
Alternatively, you may choose to receive this work under any other
license that grants the right to use, copy, modify, and/or distribute
the work, as long as that license imposes the restriction that
derivative works have to grant the same rights and impose the same
restriction. For example, you may choose to receive this work under
the
<a href="https://www.gnu.org/">GNU</a>
<a href="/FDL">Free Documentation License</a>, the
<a href="https://creativecommons.org/">CreativeCommons</a>
<a href="https://creativecommons.org/licenses/sa/1.0/">ShareAlike</a>
License, the XEmacs manual license, or
<a href="/OLD">similar licenses</a>.
</p>
<p class="legal" style="padding-top: 0.5em">Please note our <a href="/emacs/Privacy">Privacy Statement</a>.</p>
</footer>
</body>
</html>
