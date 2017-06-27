#ifndef _CORE_H_
#define _CORE_H_

#include "common/types.h"

void core_nmi(cpustate_t *cpu, cycles_t *cycles);

void core_irq(cpustate_t *cpu, cycles_t *cycles);

void core_reset(cpustate_t *cpu, cycles_t *cycles);

void core_step(cpustate_t *cpu, cycles_t *cycles);

#endif
