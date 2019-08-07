;;; org-caldav-oauth2.el --- Oauth2 addon for org-caldav  -*- lexical-binding: t -*-

;; Copyright (C) 2012-2017 Free Software Foundation, Inc.

;; Author: David Engster <deng@randomsample.de>
;; Maintainer: Daniel Kraus <daniel@kraus.my>
;; URL: https://github.com/dakra/org-caldav.el
;; Version: 0.1
;; Keywords: calendar, caldav
;; Package-Requires: ((emacs "24.3") (org "8.3") (org-caldav "0.1") oauth2)
;;
;; This file is not part of GNU Emacs.
;;
;; org-caldav-oauth2.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; org-caldav-oauth2.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:

;; Oauth addon for org-caldav.
;;
;; See README for more info.

;;; Code:

(require 'org-caldav)
(require 'oauth2)


(defcustom org-caldav-oauth2-providers
  '((google "https://accounts.google.com/o/oauth2/v2/auth"
 	    "https://www.googleapis.com/oauth2/v4/token"
	    "https://www.googleapis.com/auth/calendar"
	    "https://apidata.googleusercontent.com/caldav/v2/%s/events"))
  "List of providers that need OAuth2.

Each must be of the form

    IDENTIFIER AUTH-URL TOKEN-URL RESOURCE-URL CALENDAR-URL

where IDENTIFIER is a symbol that can be set in `org-caldav-url'
and '%s' in the CALENDAR-URL denotes where
`org-caldav-calendar-id' must be placed to generate a valid
events URL for a calendar."
  :type 'list
  :group 'org-caldav)

(defcustom org-caldav-oauth2-client-id nil
  "Client ID for OAuth2 authentication."
  :type 'string
  :group 'org-caldav)

(defcustom org-caldav-oauth2-client-secret nil
  "Client secret for OAuth2 authentication."
  :type 'string
  :group 'org-caldav)


;; Internal variables
(defvar org-caldav-oauth2-tokens nil
  "Tokens for OAuth2 authentication.")


(defun org-caldav-oauth2-check (provider)
  "Check if we have to do OAuth2 authentication for PROVIDER.
If that is the case, also check that everything is installed and
configured correctly, and throw an user error otherwise."
  (when (null (assoc provider org-caldav-oauth2-providers))
    (user-error (concat "No OAuth2 provider found for %s in "
                        "`org-caldav-oauth2-providers'")
                (symbol-name provider)))
  (when (or (null org-caldav-oauth2-client-id)
            (null org-caldav-oauth2-client-secret))
    (user-error (concat "You need to set oauth-client ID and secret "
                        "for OAuth2 authentication"))))

(defun org-caldav-oauth2-retrieve-token (provider calendar-id)
  "Do OAuth2 authentication for PROVIDER with CALENDAR-ID."
  ;; We need to do oauth. Check if it is available.
  (org-caldav-oauth2-check org-caldav-url)
  (let ((cached-token
         (assoc
          (concat (symbol-name provider) "__" calendar-id)
          org-caldav-oauth2-tokens)))
    (if cached-token
        (cdr cached-token)
      (let* ((ids (assoc provider org-caldav-oauth2-providers))
             (token (oauth2-auth-and-store (nth 1 ids) (nth 2 ids) (nth 3 ids)
                                           org-caldav-oauth2-client-id
                                           org-caldav-oauth2-client-secret)))
        (when (null token)
          (user-error "OAuth2 authentication failed"))
        (setq org-caldav-oauth2-tokens
              (append org-caldav-oauth2-tokens
                      (list (cons (concat (symbol-name provider) "__" calendar-id)
                                  token))))
        token))))

(defun org-caldav-oauth2-url-retrieve-synchronously (url &optional
                                                         request-method
                                                         request-data
                                                         extra-headers)
  "Retrieve URL with REQUEST-METHOD, REQUEST-DATA and EXTRA-HEADERS with OAuth2."
  (oauth2-url-retrieve-synchronously
   (org-caldav-oauth2-retrieve-token org-caldav-url org-caldav-calendar-id)
   url request-method request-data extra-headers))

(provide 'org-caldav-oauth2)

;;; org-caldav-oauth2.el ends here
