(lang dune 3.3)

(cram enable)

(generate_opam_files true)

(package
 (name Lama)
 (synopsis
  "A programming language (initualy developed by JetBrains Research) for educational purposes as an exemplary language to introduce the domain of programming languages, compilers, and tools.")
 (depends
  posix-uname
  GT
  (ostap
   (>= 0.6))))
