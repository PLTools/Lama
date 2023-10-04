#include "../gc.h"

int main () {
  push_extra_root(NULL);
  pop_extra_root((void **)239);
}