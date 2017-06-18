#include "addrmode.h"
#include "error.h"
#include "decoder.h"
#include "bus.h"
#include "core.h"

static argtype_t modeAcc(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	args[0] = cpu->a;

	DEBUG("Accumulator mode, args : 0x%02x", args[0]);

	return arg_byte;
}

static argtype_t modeAbsolute(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	args[0] = core_nextpc(cpu);
	args[1] = core_nextpc(cpu);

	DEBUG("Absolute mode, args : 0x%02x%02x", args[1], args[0]);

	*cycles += 3;

	return arg_addr;
}

static argtype_t modeAbsoluteX(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = core_nextpc(cpu);
	addr |= (u16)core_nextpc(cpu) << 8;
	addr += cpu->x;

	args[0] = addr & 0xff;
	args[1] = (addr >> 8) & 0xff;

	DEBUG("Absolute, X mode, args : 0x%02x%02x", args[1], args[0]);

	*cycles += 3;

	return arg_addr;
}

static argtype_t modeAbsoluteY(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = core_nextpc(cpu);
	addr |= (u16)core_nextpc(cpu) << 8;
	addr += cpu->y;

	args[0] = addr & 0xff;
	args[1] = (addr >> 8) & 0xff;

	DEBUG("Absolute, Y mode, args : 0x%02x%02x", args[1], args[0]);

	*cycles += 3;

	return arg_addr;
}

static argtype_t modeImmediate(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	args[0] = core_nextpc(cpu);
	
	DEBUG("Immediate mode, args: 0x%02x", args[0]);

	*cycles += 1;

	return arg_byte;
}

static argtype_t modeImplicant(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	DEBUG("Implicant mode, no args");

	return arg_none;
}

static argtype_t modeIndirect(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = core_nextpc(cpu);
	addr |= (u16)core_nextpc(cpu) << 8;

	args[0] = bus_read(addr++);
	args[1] = bus_read(addr);

	DEBUG("Indirect mode, args: 0x%02x%02x from addr: 0x%04x", args[1], args[0], addr);

	*cycles += 7;

	return arg_addr;
}

static argtype_t modeIndirectX(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = core_nextpc(cpu);
	addr += cpu->x;
	addr &= 0xff;

	args[0] = bus_read(addr++);
	args[1] = bus_read(addr);

	DEBUG("Indexed indirect mode, args: 0x%02x%02x from addr: 0x%04x", args[1], args[0], addr);

	*cycles += 5;

	return arg_addr;
}

static argtype_t modeIndirectY(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	u16 zpAddr;
	u16 addr;

	zpAddr = core_nextpc(cpu);

	addr = bus_read(zpAddr++);
	addr |= (u16)bus_read(zpAddr) << 8;

	addr += cpu->y;

	args[0] = addr & 0xff;
	args[1] = (addr >> 8) & 0xff;

	DEBUG("Indirect indexed mode, args: 0x%02x%02x from addr: 0x%04x", args[1], args[0], zpAddr);

	*cycles += 5;

	return arg_addr;
}

static argtype_t modeRelative(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	s8 rel;
	u16 addr;

	rel = core_nextpc(cpu);
	addr = cpu->pc;
	addr += rel;

	arg[0] = addr & 0xff;
	arg[1] = (addr >> 8) & 0xff;

	DEBUG("Relative mode, args: 0x%02x%02x = pc + rel: 0x%02x", args[1], args[0], rel);

	*cycles += 1;

	return arg_addr;
}

static argtype_t modeZeropage(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	args[0] = core_nextpc(cpu);
	args[1] = 0;

	DEBUG("Zero Page mode, args: 0x%02x%02x", args[1], args[0]);

	*cycles += 2;

	return arg_addr;
}

static argtype_t modeZeropageX(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	args[0] = core_nextpc(cpu) + cpu->x;
	args[1] = 0;

	DEBUG("Zero Page, X mode, args: 0x%02x%02x", args[1], args[0]);

	*cycles += 2;

	return arg_addr;
}

static argtype_t modeZeropageY(cpustate_t *cpu, u8 *args, cycles_t *cycles)
{
	args[0] = core_nextpc(cpu) + cpu->y;
	args[1] = 0;

	DEBUG("Zero Page, Y mode, args: 0x%02x%02x", args[1], args[0]);

	*cycles += 2;

	return arg_addr;
}

argtype_t addrmode_getArgs(cpustate_t *cpu, u8 *args, addrmode_t mode, cycles_t *cycles)
{
	argtype_t arg_type;

	switch(mode) {
		case mode_acc:
			arg_type = modeAcc(cpu, args, cycles);
			break;

		case mode_abs:
			arg_type = modeAbsolute(cpu, args, cycles);
			break;

		case mode_abx:
			arg_type = modeAbsoluteX(cpu, args, cycles);
			break;

		case mode_aby:
			arg_type = modeAbsoluteY(cpu, args, cycles);
			break;

		case mode_imm:
			arg_type = modeImmediate(cpu, args, cycles);
			break;

		case mode_imp:
			arg_type = modeImplicant(cpu, args, cycles);
			break;

		case mode_ind:
			arg_type = modeIndirect(cpu, args, cycles);
			break;

		case mode_inx:
			arg_type = modeIndirectX(cpu, args, cycles);
			break;

		case mode_iny:
			arg_type = modeIndirectY(cpu, args, cycles);
			break;

		case mode_rel:
			arg_type = modeRelative(cpu, args, cycles);
			break;

		case mode_zp:
			arg_type = modeZeropage(cpu, args, cycles);
			break;

		case mode_zpx:
			arg_type = modeZeropageX(cpu, args, cycles);
			break;

		case mode_zpy:
			arg_type = modeZeropageY(cpu, args, cycles);
			break;

		default:
			FATAL("Invalid addressing mode");
	}

	return arg_type;
}











