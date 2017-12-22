#|
 This file is a part of pi-plates
 (c) 2016 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.pi-plates.lli)

(defvar *base-address* 8)
(defvar *frame-pin* 25)
(defvar *interrupt-pin* 22)
(defvar *spi*)
(defvar *vcc* (make-array 8 :element-type 'float))

(defmacro with-frame ((var &rest contents) &body body)
  `(unwind-protect
        (let ((,var (cffi:make-shareable-byte-vector ,(length contents))))
          ,@(loop for content in contents for i from 0
                  collect `(setf (aref ,var ,i) ,content))
          (setf (gpio:value *frame-pin*) T)
          ,@body)
     (setf (gpio:value *frame-pin*) NIL)))

(defun address (plate)
  (+ *base-address* plate))

(defun cmd (plate command &optional (p1 0) (p2 0) (bytes 0))
  (check-type plate (integer 0 8))
  (with-frame (frame (address plate) command p1 p2)
    (cl-spidev-lli:transmit *spi* frame 300000 40 8)
    (unwind-protect
         (when (< 0 bytes)
           ;; Wtf?
           (sleep 0.0001)
           (loop with frame = (make-array 1 :initial-element 0
                                            :element-type '(unsigned-byte 8))
                 for i from 0 to bytes
                 collect (aref (cl-spidev-lli:transmit *spi* frame 500000 40 8) 0)))
      (sleep 0.0003))))

(defun cmd-int (plate command &optional (p1 0) (p2 0))
  (let ((response (cmd plate command p1 p2 size)))
    (+ (* 256 (aref response 0))
       (aref response 1))))

(defun firmware-revision (plate)
  (let* ((response (aref (cmd plate #x03 0 0 1) 0))
         (whole (float (ash response -4)))
         (point (float (logand response #x0F))))
    (+ whole (/ point 10.0))))

(defun hardware-revision (plate)
  (let* ((response (aref (cmd plate #x02 0 0 1) 0))
         (whole (float (ash response -4)))
         (point (float (logand response #x0F))))
    (+ whole (/ point 10.0))))

(defun try-plate (plate)
  (- (aref (cmd plate #x00 0 0 1) 0) 8))

(defun id (plate)
  (let* ((bytes (cmd plate #x01 0 0 20))
         (string (make-array (or (find 0 bytes) 20) :element-type 'character
                                                    :initial-element #\Nul)))
    (map-into string #'code-char bytes)))

(defun program-memory (plate address)
  (cmd-int plate #xF0 (ash address -8) (logand address #xFF)))

(defun find-plates ()
  (loop for i from 0 to *max-address*
        when (= (try-address i) i)
        collect i))

(defun (setf interrupts) (value plate)
  (if value
      (cmd plate #x04)
      (cmd plate #x05)))

(defun interrupts (plate)
  (cmd-int plate #x06))

(defun aout (plate channel)
  (check-type channel (integer 0 1))
  (cmd-int plate (+ #x42 channel)))

(defun (setf aout) (value plate channel)
  (check-type value (unsigned-byte 10))
  (check-type channel (integer 0 1))
  (cmd plate (+ #x40 channel)
       (ash value -8)
       (- value (ash (ash value -8) 8))))

(defun aoutv (plate channel)
  (/ (* (pwm plate channel) (aref *vcc* plate)) 1024.0))

(defun (setf aoutv) (value plate channel)
  (check-type value (float 0.0 4.097))
  (setf (pwm plate channel) (round (* 1024 (/ value (aref *vcc* plate))))))

(defun dout (plate bit)
  (check-type bit (integer 0 6))
  (ldb (byte 1 bit) (aref (cmd plate #x13 0 0 1) 0)))

(defun (setf dout) (value plate bit)
  (check-type bit (integer 0 6))
  (if value
      (cmd plate #x10 bit)
      (cmd plate #x11 bit)))

(defun toggle-dout (plate bit)
  (check-type bit (integer 0 6))
  (cmd plate #x12 bit))

;; Dunno how these three are related exactly
(defun sw-state (plate)
  (aref (cmd plate #x50 0 0 1) 0))

(defun (setf sw-int) (value plate)
  (if value
      (cmd plate #x51)
      (cmd plate #x52)))

(defun (setf sw-power) (value plate)
  (if value
      (cmd plate #x53)
      (cmd plate #x54)))

(defun led (plate led)
  (check-type led (integer 0 1))
  (< 0 (aref (cmd plate #x63 led 0 1) 0)))

(defun (setf led) (value plate led)
  (check-type led (integer 0 1))
  (if value
      (cmd plate #x60 led)
      (cmd plate #x61 led)))

(defun toggle-led (value led)
  (check-type led (integer 0 1))
  (cmd plate #x62 led))

(defun din (plate bit)
  (check-type bit (integer 0 7))
  (< 0 (aref (cmd plate #x20 bit 0 1) 0)))

(defun (setf din-interrupt) (edge plate bit)
  (check-type bit (integer 0 7))
  (ecase edge
    (:falling (cmd plate #x21 bit))
    (:rising (cmd plate #x22 bit))
    (:both (cmd plate #x23 bit))
    (NIL (cmd plate #x24 bit))))

(defun ain (plate channel)
  (check-type channel (integer 0 8))
  (let ((value (cmd-int plate #x30 channel)))
    ;; WTF?
    (if (= 8 channel)
        (* 2 value)
        value)))

(defun ainv (plate channel)
  ;; Why does this not use the VCC?
  (* 4.096 1/1024 (ain plate channel)))

(defun reset (plate)
  (dotimes (pin 7)
    (setf (dout plate pin) NIL))
  (setf (aout plate 0) 0)
  (setf (aout plate 1) 0))

(defun connect (&optional (spi "0.1"))
  (setf *spi* (spidev:open spi))
  (gpio:export *frame-pin* *interrupt-pin*)
  (setf (gpio:direction *frame-pin*) :out)
  (setf (gpio:value *frame-pin*) 0)
  (setf (gpio:direction *interrupt-pin*) :in)
  (setf (gpio:edge *interrupt-pin*) :rising)
  (let ((plates (find-plates)))
    (dolist (plate plates plates)
      (reset plate)
      (setf (aref *vcc* plate) (ainv plate 8)))))

(defun disconnect ()
  (spidev:close *spi*)
  (gpio:unexport *frame-pin* *interrupt-pin*))
