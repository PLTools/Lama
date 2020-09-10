define pp
  p (char*) Bstringval ((void*) $arg0)    
end    

define pc
  p (char*) Bstringval ((void*) ((*(int**)($ebp-4)) [$arg0]))
end
