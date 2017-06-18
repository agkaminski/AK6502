#ifndef _EXEC_H_
#define _EXEC_H_

#include "types.h"

void exec_execute(cpustate_t *cpu, opcode_t instruction, argtype_t argtype, u8 *args, cycles_t *cycles);

void exec_irq(cpustate_t *cpu, cycles_t *cycles);

void exec_nmi(cpustate_t *cpu, cycles_t *cycles);

void exec_rst(cpustate_t *cpu, cycles_t *cycles);

#endif
