[v] add `let pattern = e1 in e2` as a synonym for `case e1 of pattern -> e2 esac`
[v] add `x = y` as a non-associative binary operator, as a sugar for `compare (x, y) == 0`
[ ] `multi-let` a-la `let p_1 = e_1, ..., p_n = e_n in ...`
[ ] `pattern := e`
[ ] check call's argument number both 
    * statically for calls with statically known function names, and 
    * dynamically
[ ] rewrite parser using methril?
[ ] debugger
[ ] add check that forbids pointer arithmetics
[ ] generate PIE
[ ] make prefix `L` customizable during compilation (in preprocessing / compiler flag)
[ ] generate function tables
[ ] add `return` ? both local and non-local ?
[ ] add loop `break`s, both local and non-local
[ ] partial function application ?
[ ] annotations for dynamic "type/kind" check, also in function params 
[ ] Bitwise operators
[ ] Float arithmetics
[ ] Big numbers
[ ] Local modules and imports inside scopes ?
[ ] Monotone Framework for data-flow analysis
[ ] Documentation for stdlib and runtime; Automatically convertion to .tex/html/md

