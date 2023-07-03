(asdf:defsystem pi-plates
  :version "1.0.0"
  :license "zlib"
  :author "Yukari Hafner <shinmera@tymoon.eu>"
  :maintainer "Yukari Hafner <shinmera@tymoon.eu>"
  :description "A library to interface with Pi-Plates"
  :homepage "https://Shinmera.github.io/pi-plates/"
  :bug-tracker "https://github.com/Shinmera/pi-plates/issues"
  :source-control (:git "https://github.com/Shinmera/pi-plates.git")
  :serial T
  :components ((:file "package")
               (:file "low-level")
               (:file "wrapper")
               (:file "documentation"))
  :depends-on (:cl-gpio
               :cl-spidev
               :documentation-utils))
