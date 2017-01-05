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
   #:cmd
   #:cmd-int
   #:firmware-revision
   #:hardware-revision
   #:id
   #:program-memory
   #:find-plates
   #:interrupts
   #:aout
   #:aoutv
   #:dout
   #:toggle-dout
   #:sw-state
   #:sw-int
   #:sw-power
   #:led
   #:toggle-led
   #:din
   #:din-interrupt
   #:ain
   #:ainv
   #:reset
   #:connect
   #:disconnect))

(defpackage #:pi-plates
  (:nicknames #:org.shirakumo.pi-plates)
  (:use #:cl)
  ;; wrapper.lisp
  (:export
   ))
