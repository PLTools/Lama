define pp
  p (char*) Lstring ((void*) $arg0)    
end    

define pc
  p (char*) Lstring ((void*) ((*(int**)($ebp-4)) [$arg0]))
end
