;;; helm-git-grep-test.el --- helm-git-grep: unit test suite

;; Copyright (C) 2016 Yasuyuki Oka <yasuyk@gmail.com>

;; Author: Yasuyuki Oka <yasuyk@gmail.com>
;; URL: https://github.com/yasuyk/helm-git-grep

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Unit test suite of helm-git-grep

;;; Code:


(eval-when-compile (require 'cl))

(require 'helm-git-grep)
(require 'ert)
(require 'mocker)

(defun should-equal (a b)
    (should (equal a b)))
(defun should-not-equal (a b)
    (should-not (equal a b)))

(ert-deftest ert--helm-git-grep-showing-leading-and-trailing-lines-option ()
  (let ((helm-git-grep-showing-leading-and-trailing-lines t))
    (should-equal (helm-git-grep-showing-leading-and-trailing-lines-option) "-1"))
  (let ((helm-git-grep-showing-leading-and-trailing-lines t)
        (helm-git-grep-showing-leading-and-trailing-lines-number 2))
    (should-equal (helm-git-grep-showing-leading-and-trailing-lines-option) "-2"))
  (should-equal (helm-git-grep-showing-leading-and-trailing-lines-option) nil)
  (should-equal (helm-git-grep-showing-leading-and-trailing-lines-option t) ""))

(ert-deftest ert--helm-git-grep-rgs ()
  (should-equal (helm-git-grep-args nil)
                '("--no-pager" "grep" "--full-name" "-n" "--no-color" "-i"))
  (let ((helm-git-grep-ignore-case nil))
     (should-equal (helm-git-grep-args nil)
                   '("--no-pager" "grep" "--full-name" "-n" "--no-color"))))

(ert-deftest ert--helm-git-grep-highlight-match ()
  (let* ((helm-input "defun")
         (result (helm-git-grep-highlight-match "(defun abc())")))
    (should-equal (get-text-property 0 'face result) nil)
    (cl-loop for x from 1 to (length helm-input)
             do (should-equal (get-text-property x 'face result) 'helm-git-grep-match))
    (cl-loop for x from (1+ (length helm-input)) to  (length result)
             do (should-equal (get-text-property x 'face result) nil)))
  (let* ((helm-input "begin match put")
         (result (helm-git-grep-highlight-match "(put-text-property (match-beginning 1) (match-end 1)")))
    (should-equal (get-text-property 0 'face result) nil)
    (cl-loop for x from 1 to (length "put")
             do (should-equal (get-text-property x 'face result) 'helm-git-grep-match))
    (cl-loop for x from 4 to (length "-text-property (")
             do (should-equal (get-text-property x 'face result) nil))
    (cl-loop for x from 20 to (length "match")
             do (should-equal (get-text-property x 'face result) 'helm-git-grep-match))
    (cl-loop for x from 25 to (length "-beginning 1) (")
             do (should-equal (get-text-property x 'face result) nil))
    (cl-loop for x from 40 to (length "match")
             do (should-equal (get-text-property x 'face result) 'helm-git-grep-match))
    (cl-loop for x from 40 to (length "-end 1)")
             do (should-equal (get-text-property x 'face result) 'helm-git-grep-match))))

(ert-deftest ert--helm-git-grep-get-input-symbol ()
  (let ((expected "helm"))
    (with-temp-buffer
      (insert expected)
      (goto-char (point-min))
      (should-equal (helm-git-grep-get-input-symbol) expected))
    (with-temp-buffer
      (insert expected)
      (goto-char (point-min))
      (activate-mark)
      (goto-char (point-max))
      (should-equal (helm-git-grep-get-input-symbol) expected))))

(ert-deftest ert--helm-git-grep-get-isearch-input-symbol ()
  ;; return isearch-string
  (let* ((expected "defun")
         (isearch-regexp expected)
         (isearch-string expected))
    (should-equal (helm-git-grep-get-isearch-input-symbol) expected))
  (let* ((expected "\\^defun")
         (isearch-regexp nil)
         (isearch-string "^defun"))
    (should-equal (helm-git-grep-get-isearch-input-symbol) expected)))

(ert-deftest ert--helm-git-grep ()
  (mocker-let ((helm-git-grep-1 () ((:output t))))
    (should (helm-git-grep))))

(ert-deftest ert--helm-git-grep-at-point-symbol-is-nil ()
  (mocker-let ((helm-git-grep-get-input-symbol () ((:output nil)))
               (helm-git-grep-1 (input) ((:input '("") :output t))))
    (should (helm-git-grep-at-point))))

(ert-deftest ert--helm-git-grep-at-point-do-deactivate-mark ()
  (let ((helm-git-grep-at-point-deactivate-mark t)
        (mark-active t))
    (mocker-let ((helm-git-grep-get-input-symbol () ((:output "helm")))
                 (helm-git-grep-1 (input) ((:input '("helm ") :output t)))
                 (deactivate-mark () ((:max-occur 1))))
      (should (helm-git-grep-at-point)))))

(ert-deftest ert--helm-git-grep-from-isearch ()
    (mocker-let ((helm-git-grep-get-isearch-input-symbol () ((:output "helm")))
                 (helm-git-grep-1 (input) ((:input '("helm") :output t)))
                 (isearch-exit () ((:max-occur 1))))
      (should (helm-git-grep-from-isearch))))

(ert-deftest ert--helm-git-grep-from-helm ()
  (let ((helm-input "helm"))
    (mocker-let ((helm-exit-and-execute-action (action) ((:input-matcher 'functionp :output t))))
      (should (helm-git-grep-from-helm)))))

(provide 'helm-git-grep-test)

;; Local Variables:
;; coding: utf-8
;; End:

;;; helm-git-grep-test.el ends here
