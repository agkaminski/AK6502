#include <stdlib.h>
#include "error.h"
#include "core.h"
#include "addrmode.h"
#include "decoder.h"
#include "exec.h"
#include "bus.h"
#include "flags.h"

void core_nmi(cpustate_t *cpu, cycles_t *cycles)
{
	exec_nmi(cpu, cycles);
}

void core_irq(cpustate_t *cpu, cycles_t *cycles)
{
	exec_irq(cpu, cycles);
}

void core_reset(cpustate_t *cpu, cycles_t *cycles)
{
	exec_rst(cpu, cycles);
}

void core_step(cpustate_t *cpu, cycles_t *cycles)
{
	opinfo_t instruction;
	argtype_t argtype;
	u8 args[2];

	instruction = decode(addrmode_nextpc(cpu));
	argtype = addrmode_getArgs(cpu, args, instruction.mode, cycles);
	exec_execute(cpu, instruction.opcode, argtype, args, cycles);

	*cycles += 1;
}
