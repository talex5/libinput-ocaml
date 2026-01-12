(lang dune 3.18)
(name libinput)
(using ctypes 0.3)
(formatting disabled)
(generate_opam_files true)

(source (github talex5/libinput-ocaml))
(license ISC)
(authors "Thomas Leonard")
(maintainers "Thomas Leonard")
(documentation "https://talex5.github.io/libinput-ocaml/")

(package
 (name libinput)
 (synopsis "OCaml bindings for libinput")
 (description "Input device management and event handling library")
 (depends
  (ocaml (>= 5.3.0))
  (ctypes (>= 0.23.0))
  (ctypes-foreign (>= 0.23.0))
  (fmt (>= 0.8.9))))
