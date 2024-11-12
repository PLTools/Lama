(lang dune 3.11)

(name Lama)

(cram enable)

(generate_opam_files true)

(bug_reports "https://github.com/PLTools/Lama/issues")

(homepage "https://github.com/PLTools/Lama")

(maintainers "http://github.com/Kakadu")

(authors "http://github.com/dboulytchev" "http://github.com/danyaberezun")

(license GPL-3.0-only)

(package
 (name Lama)
 (synopsis
  "A programming language (initially developed by JetBrains Research) for educational purposes as an exemplary language to introduce the domain of programming languages, compilers, and tools")
 (depends
  posix-uname
  GT
  (ostap
   (>= 0.6))))
