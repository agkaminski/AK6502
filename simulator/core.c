#include <stdlib.h>
#include "error.h"
#include "core.h"
#include "addrmode.h"
#include "decoder.h"
#include "exec.h"
#include "bus.h"
#include "flags.h"

#define TIME_PER_CYCLE 1 /* us */

struct {
	cpustate_t cpu;
	cycles_t cycles;
	int state;
	int irq_state;
	int nmi_state;
	int rst_state;
	int step;
	int run;
	int end;

	mutex_t mutex;
	cond_t cond;
} core_global;

enum { STATE_STALL, STATE_NORMAL, STATE_NMI, STATE_IRQ, STATE_RST, STATE_END };

static core_reset(cpustate_t *cpu, cycles_t *cycles)
{
	exec_rst(cpu, cycles);
}

static core_nmi(cpustate_t *cpu, cycles_t *cycles)
{
	exec_nmi(cpu, cycles);
}

static core_irq(cpustate_t *cpu, cycles_t *cycles)
{
	exec_irq(cpu, cycles);
}

static void core_normal(cpustate_t *cpu, cycles_t *cycles)
{
	opinfo_t instruction;
	argtype_t argtype;
	u8 args[2];

	instruction = decode(core_nextpc(cpu));
	argtype = addrmode_getArgs(cpu, args, instruction.mode, &cycles);
	exec_execute(cpu, instruction.opcode, argtype, args, &cycles);

	*cycles += 1;
}

static void core_thread(void *arg)
{
	cycles_t cycles;
	int lastNmi;

	lastNmi = 0;

	core_reset(&core_global.cpu, &core_global.cycles);

	while (1) {
		lock(&core_global.mutex);
		while (1) {
			if (core_global.rst_state != 0) {
				core_global.state = STATE_RST;
				break;
			}
			else if (core_global.nmi_state != 0 && lastNmi == 0) {
				lastNmi = 1;
				core_global.state = STATE_NMI;
				break;
			}
			else if ((core_global.irq_state != 0) && !(core_global.cpu.flags & flag_irqd)) {
				core_global.state = STATE_IRQ;
				break;
			}
			else if (core_global.run != 0) {
				core_global.state = STATE_NORMAL;
				break;
			}
			else if (core_global.step != 0) {
				core_global.state = STATE_NORMAL;
				break;
			}
			else if (core_global.end != 0) {
				core_global.state = STATE_END;
				break;
			}
			else {
				core_global.state = STATE_STALL;
			}

			thread_wait(&core_global.cond, &core_global.mutex);
		}

		if (core_global.state == STATE_END) {
			unlock(&core_global.mutex);
			thread_exit(NULL);
		}

		if (!core_global.nmi_state)
			lastNmi = 0;

		cycles = core_global.cycles;

		switch(core_global.state) {
			case STATE_RST:
				core_reset(&core_global.cpu, &core_global.cycles);
				break;

			case STATE_NMI:
				core_nmi(&core_global.cpu, &core_global.cycles);
				break;

			case STATE_IRQ:
				core_irq(&core_global.cpu, &core_global.cycles);
				break;

			case STATE_NORMAL:
				core_normal(&core_global.cpu, &core_global.cycles);
				break;

			default:
				unlock(&core_global.mutex);
				FATAL("Invalid core state");
				lock(&core_global.mutex);
				break;
		}

		cycles = core_global.cycles - cycles;

		unlock(&core_global.mutex);

		thread_sleep(TIME_PER_CYCLE * cycles);
	}
}


u8 core_nextpc(cpustate_t *cpu)
{
	u8 data;

	data = bus_read(cpu->pc);

	DEBUG("Read 0x%02x from pc: 0x%04x", data, cpu->pc);

	++cpu->pc;

	if (cpu->pc == 0)
		WARN("Program counter wrap-around");

	return data;
}

void core_getState(cpustate_t *cpu, cycles_t *cycles)
{
	lock(&core_global.mutex);
	*cpu = core_global.cpu;
	*cycles = core_global.cycles;
	unlock(&core_global.mutex);
}

void core_setIrq(int state)
{
	lock(&core_global.mutex);
	core_global.irq_state = !!state;
	thread_signal(&core_global.cond);
	unlock(&core_global.mutex);
}

void core_setNmi(int state)
{
	lock(&core_global.mutex);
	core_global.nmi_state = !!state;
	thread_signal(&core_global.cond);
	unlock(&core_global.mutex);
}

void core_setRst(int state)
{
	lock(&core_global.mutex);
	core_global.rst_state = !!state;
	thread_signal(&core_global.cond);
	unlock(&core_global.mutex);
}

void core_setMode(coremode_t mode)
{
	lock(&core_global.mutex);
	if (mode == MODE_STEP) {
		core_global.run = 0;
		core_global.step = 0;
	}
	else {
		core_global.run = 1;
		core_global.step = 0;
		thread_signal(&core_global.cond);
	}
	unlock(&core_global.mutex);
}

void core_kill(void)
{
	lock(&core_global.mutex);
	core_global.end = 1;
	thread_signal(&core_global.cond);
	unlock(&core_global.mutex);
}

int core_step(void)
{
	lock(&core_global.mutex);
	if (core_global.step != 0) {
		unlock(&core_global.mutex);
		return -1;
	}
	core_global.step = 1;
	thread_signal(&core_global.cond);
	unlock(&core_global.mutex);
	return 0;
}

int core_init(thread_t *thread)
{
	core_global.state = STATE_RST;
	core_global.cycles = 0;
	core_global.irq_state = 0;
	core_global.nmi_state = 0;
	core_global.rst_state = 1;
	core_global.step = 0;
	core_global.run = 0;
	core_global.end = 0;

	mutex_init(&core_global.mutex);
	thread_condInit(&core_global.cond);

	return thread_create(thread, core_thread, NULL);
}
