#include "../gc.h"

#include <stddef.h>

int main () {
  for (size_t i = 0; i < MAX_EXTRA_ROOTS_NUMBER + 1; ++i) { push_extra_root(NULL); }
}