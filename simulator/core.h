#ifndef _CORE_H_
#define _CORE_H_

#include "types.h"
#include "threads.h"

typedef enum { MODE_STEP, MODE_RUN } coremode_t;

u8 core_nextpc(cpustate_t *cpu);

void core_getState(cpustate_t *cpu, cycles_t *cycles);

void core_setIrq(int state);

void core_setNmi(int state);

void core_setRst(int state);

void core_setMode(coremode_t mode);

void core_kill(void);

int core_step(void);

int core_init(thread_t *thread);

#endif
