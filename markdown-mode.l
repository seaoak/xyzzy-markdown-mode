;; -*- mode:lisp; package:markdown-mode -*-

;; markdown.l ( http://www.geocities.jp/kiaswebsite/xyzzy/markdown.html )
;; Rev: 227 を元に改変
;;
;; License
;; =======
;;
;; Copyright (c) 2011 Yousuke Ushiki <citrus.yubeshi@gmail.com>
;; Copyright (c) 2005,2006 kia
;;
;; Permission is hereby granted, free of charge, to any person obtaining a
;; copy of this software and associated documentation files (the "Software"),
;; to deal in the Software without restriction, including without
;; limitation the rights to use, copy, modify, merge, publish, distribute,
;; sublicense, and/or sell copies of the Software, and to permit persons to
;; whom the Software is furnished to do so, subject to the following
;; conditions:
;;
;; The above copyright notice and this permission notice shall be included
;; in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
;; OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;;
;;

(provide "markdown")

(in-package "editor")
(export '(markdown-mode))

(defpackage "markdown-mode"
  (:nicknames "md")
  (:use "lisp" "editor"))

(in-package "md")
(export '(*markdown-mode-map*
	  *markdown-mode-hook*
	  *markdown-use-setext-style*
	  *h1-style* *h2-style* *h3-style* *h4-style* *h5-style* *h6-style*
	  *italic-style* *bold-style* *italic-bold-style*
	  *listmarker-style* *code-style*
	  ))

(defvar *markdown-default-horizontal-rule* "*****")

(defparameter *h1-style* '(:color 7 4 :line :bold))
(defparameter *h2-style* '(:color 7 14 :line :bold))
(defparameter *h3-style* '(:color 9 0 :underline :bold))
(defparameter *h4-style* '(:color 11 0 :underline))
(defparameter *h5-style* '(:color 14 0))
(defparameter *h6-style* '(:color 12 0))
(defparameter *listmarker-style* '(:color 10 0 :bold))
(defparameter *code-style* '(:keyword 1))
(defparameter *italic-style* '(:keyword 2))
(defparameter *bold-style* '(:color 0 0 :bold))
(defparameter *italic-bold-style* '(:keyword 2 :bold))
;(defparameter *horizontal-line-style* '(:color 0 0 :line :underline))

(defun make-regexp-keyword-list ()
  (compile-regexp-keyword-list
   `(("^# .+" nil ,*h1-style*)
     ("^## .+" nil ,*h2-style*)
     ("^### .+" nil ,*h3-style*)
     ("^#### .+" nil ,*h4-style*)
     ("^##### .+" nil ,*h5-style*)
     ("^###### .+" nil ,*h6-style*)
     ("^[ \t]*[*+-] " nil ,*listmarker-style*)
;     ("^[^ \n][^\n]+\n=+$" nil ,(remove :line *h1-style*))
;     ("^[^ \n][^\n]+\n-+$" nil ,(remove :line *h2-style*))
     ("^=+$" nil ,(remove :line *h1-style*))
     ("^-+$" nil ,(remove :line *h2-style*))
;     ("\n\\([-*_]\\)\\1\\1+\n" nil ,*horizontal-line-style*)
     ("`[^\n`]+`" nil ,*code-style*)
     ("\\*\\*\\*[^\n*]+\\*\\*\\*" nil ,*italic-bold-style*)
     ("\\*\\*[^\n*]+\\*\\*" nil ,*bold-style*)
     ("\\*[^\n*]+\\*" nil ,*italic-style*)
     ("___[^\n_]+___" nil ,*italic-bold-style*)
     ("__[^\n_]+__" nil ,*bold-style*)
     ("_[^\n_]+_" nil ,*italic-style*)
     )))

(defvar *markdown-use-setext-style* t)

(defvar *markdown-prefix-key* '(#\C-c))

(defvar *markdown-mode-map* nil)
(defun setup-keymap ()
  (unless *markdown-mode-map*
    (let ((m (setq *markdown-mode-map* (make-sparse-keymap))))
      (flet ((pk (c) `(,@*markdown-prefix-key* ,c)))
	(define-key m #\RET 'markdown-newline)
	(define-key m (pk #\1) 'markdown-set-header-1)
	(define-key m (pk #\2) 'markdown-set-header-2)
	(define-key m (pk #\3) 'markdown-set-header-3)
	(define-key m (pk #\4) 'markdown-set-header-4)
	(define-key m (pk #\5) 'markdown-set-header-5)
	(define-key m (pk #\6) 'markdown-set-header-6)
	(define-key m (pk #\f) 'markdown-next-header)
	(define-key m (pk #\b) 'markdown-previous-header)
	(define-key m (pk #\h) 'markdown-set-header)
	(define-key m (pk #\-) 'markdown-horizontal-rule)
	(define-key m (pk #\^) 'markdown-reindent-with-marker-removal)
	(define-key m (pk #\>) 'markdown-shift-region)
	(define-key m (pk #\<) 'markdown-unshift-region)
	(define-key m (pk #\C-q) 'markdown-quote-region)))))

(defvar *markdown-mode-hook* nil)

(defvar *markdown-quote-re* "\\(?:[ \t]*>\\)+[ \t]*")

(defun markdown-quote-skip ()
  (if (looking-at *markdown-quote-re*)
      (let ((s (match-string 0)))
        (goto-char (+ (point) (length s)))
        s)
    ""))

(defun markdown-atx-header-p ()
  (save-excursion
    (goto-bol)
    (markdown-quote-skip)
    (when (looking-at "\\(#\\{1,6\\}\\)[ \t]*[^#]+[ \t]*#*$")
      (length (match-string 1)))))

(defun markdown-setext-header-p ()
  (save-excursion
    (let* ((q (progn (goto-bol) (markdown-quote-skip)))
           (col (progn (goto-eol) (- (current-column) (length q)))))
      (when (forward-line)
        (goto-bol)
        (when (and (string= q (markdown-quote-skip))
                   (looking-at "\\(?:=+\\|-+\\)")
                   (= (length (match-string 0)) col))
          (following-char))))))

(defun markdown-header-p ()
  (or (markdown-atx-header-p) (markdown-setext-header-p)))

(defun markdown-unset-atx-header ()
  (save-excursion
    (save-restriction
      (let ((end (progn (goto-eol) (point))))
        (goto-bol)
        (markdown-quote-skip)
        (narrow-to-region (point) end)
        (replace-buffer "#+[ \t]*\\(.+[^# \t]\\)[ \t]*#*" "\\1" :regexp t)))))

(defun markdown-unset-setext-header ()
  (save-excursion
    (goto-eol)
    (let ((beg (point)))
      (forward-line)
      (goto-eol)
      (delete-region beg (point)))))

(defun markdown-unset-header ()
  (cond ((markdown-atx-header-p) (markdown-unset-atx-header))
        ((markdown-setext-header-p) (markdown-unset-setext-header))))

(defun markdown-search-preceding-header ()
  (save-excursion
    (while (forward-line -1)
      (let ((p (markdown-header-p)))
        (and p (return p))))))

(defun markdown-setext-header-exists-p ()
  (save-excursion
    (goto-char (point-min))
    (or (markdown-setext-header-p)
        (while (forward-line)
          (if (markdown-setext-header-p)
              (return t))))))

(defun markdown-atx-header (n)
  (save-excursion
    (goto-bol)
    (markdown-quote-skip)
    (insert #\# n)
    (insert #\SPC)))

(defun markdown-setext-header (c)
  (save-excursion
    (goto-bol)
    (let ((q (markdown-quote-skip)))
      (goto-eol)
      (let ((col (- (current-column) (length q))))
        (when (> col 0)
          (insert #\LFD q)
          (insert c col))))))

(defun markdown-set-header-by-guess ()
  (let ((ph (or (markdown-search-preceding-header)
                (if *markdown-use-setext-style* #\= 1))))
    (if (numberp ph)
        (markdown-atx-header ph)
      (markdown-setext-header ph))))

(defun markdown-set-header (&optional num)
  (interactive "*p")
  (if (eq *prefix-args* 'universal-argument)
      (markdown-unset-header)
    (if (null num)
        (unless (markdown-header-p)
          (markdown-set-header-by-guess))
      (cond
       ((<= 1 num 2)
        (markdown-unset-header)
        (if (or *markdown-use-setext-style* (markdown-setext-header-exists-p))
            (markdown-setext-header (if (= num 1) #\= #\-))
          (markdown-atx-header num)))
       ((<= 3 num 6)
        (markdown-unset-header)
        (markdown-atx-header num))))))

(defun markdown-set-header-1 () (interactive) (markdown-set-header 1))
(defun markdown-set-header-2 () (interactive) (markdown-set-header 2))
(defun markdown-set-header-3 () (interactive) (markdown-set-header 3))
(defun markdown-set-header-4 () (interactive) (markdown-set-header 4))
(defun markdown-set-header-5 () (interactive) (markdown-set-header 5))
(defun markdown-set-header-6 () (interactive) (markdown-set-header 6))

(defvar *markdown-horizontal-rule-re*
  (format nil "^\\(?:~A\\)??\\(\\([-*]\\)\\(?: *\\2\\)\\{2,\\}\\)[ \t]*$" *markdown-quote-re*))

(defun markdown-horizontal-rule-p ()
  (save-excursion
    (goto-bol)
    (looking-at *markdown-horizontal-rule-re*)))

(defun markdown-search-horizontal-rule ()
  (save-excursion
    (goto-char (point-min))
    (while (scan-buffer *markdown-horizontal-rule-re* :regexp t :tail t)
      (let ((hr (match-string 1))
            (ch (char (match-string 2) 0)))
        (unless (and (char= ch #\-)
                     (save-excursion
                       (and (forward-line -1)
                            (markdown-setext-header-p))))
          (return hr))))))

(defun markdown-horizontal-rule ()
  (interactive)
  (save-excursion
    (let ((q (progn (goto-bol) (markdown-quote-skip)))
          (hr (or (markdown-search-horizontal-rule)
                  *markdown-default-horizontal-rule*)))
      (goto-bol)
      (insert q hr #\LFD))))

(defun markdown-preceding-marker-and-spaces ()
  (save-excursion
    (goto-bol)
    (let ((q (markdown-quote-skip)))
      (cond ((and (not (markdown-horizontal-rule-p)) (looking-at "[ \t]*[-+*][ \t]+"))
             (concat q (match-string 0)))
            ((looking-at "\\([ \t]*\\)\\([0-9]+\\)\\.\\([ \t]*\\)")
             (let ((indent (match-string 1))
                   (num (parse-integer (match-string 2)))
                   (ts (match-string 3)))
               (concat q
                       indent
                       (format nil "~D." (1+ num))
                       (unless (string= ts "")
                         (if (find #\TAB ts)
                             ts
                           (if (= (length (format nil "~D" (1+ num)))
                                  (length (format nil "~D" num)))
                               ts
                             (substring ts 1)))))))
            ((looking-at "[ \t]+")
             (match-string 0))
            (t q)))))

(defun markdown-newline ()
  (interactive)
  (insert #\LFD (markdown-preceding-marker-and-spaces)))

(defun markdown-tab-indentation-exists-p ()
  (save-excursion
    (goto-char (point-min))
    (scan-buffer "^\t+[^ \t]" :regexp t)))

(defun markdown-shift-region (start end &optional (num 1))
  (interactive "*r\np")
  (when (eq *prefix-args* 'universal-argument)
    (setq num -1))
  (let ((col (* num (if (markdown-tab-indentation-exists-p)
                        (tab-columns)
                      4))))
    (shift-region start end col)))

(defun markdown-unshift-region (start end &optional (num -1))
  (interactive "*r\np")
  (when (> num 0)
    (setq num (- num)))
  (markdown-shift-region start end num))

(defun markdown-reindent-with-marker-removal ()
  (interactive)
  (let* ((mas (markdown-preceding-marker-and-spaces))
         (indent (progn (string-match "^[ \t]*" mas) (match-string 0)))
         (new-indent (format nil "~A~A" indent (if (or (string-match "^\t+$" indent) (markdown-tab-indentation-exists-p)) "\t" "    "))))
    (save-excursion
      (goto-bol)
      (insert new-indent)
      (let ((p (point)))
        (delete-region p (+ p (length mas)))))))

(defun markdown-unquote-region (from to)
  (interactive "*r")
  (save-excursion
    (save-restriction
      (narrow-to-region from to)
      (goto-char from)
      (replace-buffer "^[ \t]*>[ \t]*" "" :regexp t))))

(defun markdown-quote-region (from to)
  (interactive "*r")
  (if (eq *prefix-args* 'universal-argument)
      (markdown-unquote-region from to)
    (let ((*quotation-prefix* "> "))
      (quote-region from to))))

(defun markdown-search-header (&optional (dir 1))
  (save-excursion
    (while (forward-line dir)
      (when (markdown-header-p)
        (return (point))))))

(defun markdown-next-header ()
  (interactive)
  (let ((p (markdown-search-header)))
    (when p
      (goto-char p))))

(defun markdown-previous-header ()
  (interactive)
  (let ((p (markdown-search-header -1)))
    (when p
      (goto-char p))))


;;; mode definition
(defvar-local ed::*markdown-mode* nil)

(defun ed::markdown-mode (&optional (arg nil sv))
  (interactive "p")
  (setup-keymap)
  (use-keymap *markdown-mode-map*)
  (unless (local-variable-p '#0=regexp-keyword-list)
    (make-local-variable '#0#))
  (setq #0# (append #0# (make-regexp-keyword-list))
	buffer-mode 'ed::markdown-mode
	mode-name "Markdown")
  (run-hooks '*markdown-mode-hook*)
  t)

;;; markdown-mode.l ends here.
