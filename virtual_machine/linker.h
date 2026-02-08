#ifndef LINKER_H
#define LINKER_H

#include "decoder.h"
#include "module_manager.h"
#include "stddef.h"

insn *decode_and_link(module_manager *mm, memory *mem);

#endif
