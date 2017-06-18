#ifndef _ADDRMODE_H_
#define _ADDRMODE_H_

#include "types.h"

typedef enum { arg_none, arg_byte, arg_addr } argtype_t;

argtype_t addrmode_getArgs(cpustate_t *cpu, u8 *args, addrmode_t mode, cycles_t *cycles);

#endif
