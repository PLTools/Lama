(lang dune 3.3)

(cram enable)

(generate_opam_files true)

(package
 (name Lama)
 (allow_empty)
 (synopsis "TODO")
 (depends
  posix-uname
  GT
  (ostap
   (>= 0.6))))
