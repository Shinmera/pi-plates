#|
 This file is a part of pi-plates
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:cl-user)
(defpackage #:pi-plates-cffi
  (:nicknames #:org.shirakumo.pi-plates.lli)
  (:use #:cl)
  ;; low-level.lisp
  (:export
   ))

(defpackage #:pi-plates
  (:nicknames #:org.shirakumo.pi-plates)
  (:use #:cl)
  ;; wrapper.lisp
  (:export
   ))
