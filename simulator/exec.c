#include "exec.h"
#include "error.h"
#include "alu.h"
#include "decoder.h"
#include "flags.h"
#include "bus.h"
#include "addrmode.h"

#define IRQ_VECTOR 0xfffe
#define RST_VECTOR 0xfffc
#define NMI_VECTOR 0xfffa

static void exec_adc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_and(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_asl(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_bcc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_bcs(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_beq(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_bit(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_bmi(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_bne(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_bpl(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_brk(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_bvc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_bvs(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_clc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_cld(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_cli(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_clv(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_cmp(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_cpx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_cpy(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_dec(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_dex(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_dey(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_eor(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_inc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_inx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_iny(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_jmp(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_jsr(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_lda(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_ldx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_ldy(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_lsr(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_nop(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_ora(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_pha(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_php(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_pla(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_plp(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_rol(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_ror(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_rti(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_rts(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_sbc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_sec(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_sed(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_sei(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_sta(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_stx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_sty(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_tax(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_tay(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_tsx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_txa(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_txs(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);
static void exec_tya(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles);

static const void (*exec_instr)(cpustate_t*, argtype_t, u8*, cycles_t*)[] = {
	
}

static void exec_push(cpustate_t *cpu, u8 data)
{
	u16 addr;

	addr = 0x0100 | cpu->sp;
	--cpu->sp;

	if (cpu->sp == 0xff)
		WARN("Stack pointer wrap-around");

	DEBUG("Pushing 0x%02x to stack: 0x%04x", data, addr);
	
	bus_write(addr, data);
}

static u8 exec_pop(cpustate_t *cpu)
{
	u16 addr;
	u8 data;

	++cpu->sp;
	addr = 0x0100 | cpu->sp;

	if (cpu->sp == 0)
		WARN("Stack pointer wrap-around");

	data = bus_read(addr);

	DEBUG("Popped 0x%02x from stack: 0x%04x", data, addr);

	return data;
}

static void exec_adc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	cpu->a = alu_add(cpu->a, arg, &cpu->flags);

	DEBUG("Adding 0x%02x to Acc, result 0x%02x", arg, cpu->a);
}

static void exec_and(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	cpu->a = alu_and(cpu->a, arg, &cpu->flags);

	DEBUG("Performing AND 0x%02x, Acc, result 0x%02x", arg, cpu->a);
}

static void exec_asl(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;
	u8 result;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	result = alu_asl(arg, 0, &cpu->flags);

	DEBUG("Performing ASL of 0x%02x, result 0x%02x", arg, result);

	if (argtype == arg_addr) {
		bus_write(addr, result);
		*cycles += 1;
	}
	else {
		cpu->a = result;
	}
}

static void exec_bcc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	if (!(cpu->flags & flag_carry)) {
		DEBUG("BCC branch taken, new pc 0x%04x", addr);
		cpu->pc = addr;
		*cycles += 1;
	}

	DEBUG("BCC branch not taken");
}

static void exec_bcs(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	if (cpu->flags & flag_carry) {
		DEBUG("BCS branch taken, new pc 0x%04x", addr);
		cpu->pc = addr;
		*cycles += 1;
	}

	DEBUG("BCS branch not taken");
}

static void exec_beq(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	if (cpu->flags & flag_zero) {
		DEBUG("BEQ branch taken, new pc 0x%04x", addr);
		cpu->pc = addr;
		*cycles += 1;
	}

	DEBUG("BEQ branch not taken");
}

static void exec_bit(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	alu_bit(cpu->a, arg, &cpu->flags);

	DEBUG("Performing BIT A: 0x%02x and 0x%02x", cpu->a, arg);
}

static void exec_bmi(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	if (cpu->flags & flag_sign) {
		DEBUG("BMI branch taken, new pc 0x%04x", addr);
		cpu->pc = addr;
		*cycles += 1;
	}

	DEBUG("BMI branch not taken");
}

static void exec_bne(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	if (!(cpu->flags & flag_zero)) {
		DEBUG("BNE branch taken, new pc 0x%04x", addr);
		cpu->pc = addr;
		*cycles += 1;
	}

	DEBUG("BNE branch not taken");
}

static void exec_bpl(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	if (!(cpu->flags & flag_sign)) {
		DEBUG("BPL branch taken, new pc 0x%04x", addr);
		cpu->pc = addr;
		*cycles += 1;
	}

	DEBUG("BPL branch not taken");
}

static void exec_brk(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u8 flags;
	u16 addr;

	cpu->pc += 1;
	exec_push(cpu, (cpu->pc >> 8) & 0xff);
	exec_push(cpu, cpu->pc & 0xff);

	flags = cpu->flags;
	flags |= 0x30;
	exec_push(cpu, flags);

	cpu->flags |= flag_irqd;

	addr = bus_read(IRQ_VECTOR);
	addr |= ((u16)bus_read(IRQ_VECTOR + 1) << 8);

	DEBUG("Performing BRK, old pc: 0x%04x, new pc: 0x%04x", cpu->pc, addr);

	cpu->pc = addr;

	*cycles += 4;
}

static void exec_bvc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	if (!(cpu->flags & flag_ovfl)) {
		DEBUG("BVC branch taken, new pc 0x%04x", addr);
		cpu->pc = addr;
		*cycles += 1;
	}

	DEBUG("BVC branch not taken");
}

static void exec_bvs(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	if (cpu->flags & flag_ovfl) {
		DEBUG("BVS branch taken, new pc 0x%04x", addr);
		cpu->pc = addr;
		*cycles += 1;
	}

	DEBUG("BVS branch not taken");
}

static void exec_clc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->flags &= ~flag_carry;

	DEBUG("Performing CLC");

	*cycles += 1;
}

static void exec_cld(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->flags &= ~flag_bcd;

	DEBUG("Performing CLD");

	*cycles += 1;
}

static void exec_cli(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->flags &= ~flag_irqd;

	DEBUG("Performing CLI");

	*cycles += 1;
}

static void exec_clv(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->flags &= ~flag_ovfl;

	DEBUG("Performing CLV");

	*cycles += 1;
}

static void exec_cmp(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	alu_cmp(cpu->a, arg, &cpu->flags);

	DEBUG("Performing CMP A: 0x%02x and 0x%02x", cpu->a, arg);
}

static void exec_cpx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	alu_cmp(cpu->x, arg, &cpu->flags);

	DEBUG("Performing CPX X: 0x%02x and 0x%02x", cpu->x, arg);
}

static void exec_cpy(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	alu_cmp(cpu->y, arg, &cpu->flags);

	DEBUG("Performing CPY Y: 0x%02x and 0x%02x", cpu->y, arg);
}

static void exec_dec(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;
	u8 result;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	result = alu_dec(arg, 0, &cpu->flags);

	DEBUG("Performing DEC of 0x%02x, result 0x%02x", arg, result);

	if (argtype == arg_addr) {
		bus_write(addr, result);
		*cycles += 1;
	}
	else {
		cpu->a = result;
	}
}

static void exec_dex(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->x = alu_dec(cpu->x, 0, flags);

	DEBUG("Performing DEX, result 0x%02x", cpu->x);

	*cycles += 1;
}

static void exec_dey(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->y = alu_dec(cpu->y, 0, flags);

	DEBUG("Performing DEY, result 0x%02x", cpu->y);

	*cycles += 1;
}

static void exec_eor(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	cpu->a = alu_eor(cpu->a, arg, &cpu->flags);

	DEBUG("Performing EOR 0x%02x, Acc, result 0x%02x", arg, cpu->a);
}

static void exec_inc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;
	u8 result;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	result = alu_inc(arg, 0, &cpu->flags);

	DEBUG("Performing INC of 0x%02x, result 0x%02x", arg, result);

	if (argtype == arg_addr) {
		bus_write(addr, result);
		*cycles += 1;
	}
	else {
		cpu->a = result;
	}
}

static void exec_inx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->x = alu_inc(cpu->x, 0, flags);

	DEBUG("Performing INX, result 0x%02x", cpu->x);

	*cycles += 1;
}

static void exec_iny(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->y = alu_inc(cpu->y, 0, flags);

	DEBUG("Performing INY, result 0x%02x", cpu->y);

	*cycles += 1;
}

static void exec_jmp(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = (args[1] << 8) | args[0];

	DEBUG("Performing JMP, old pc: 0x%04x, new pc: 0x%04x", cpu->pc, addr);

	cpu->pc = addr;

	*cycles += 1;
}

static void exec_jsr(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = cpu->pc - 1;

	exec_push(cpu, (addr >> 8) & 0xff);
	exec_push(cpu, addr & 0xff);

	addr = (args[1] << 8) | args[0];

	DEBUG("Performing JSR, old pc: 0x%04x, new pc: 0x%04x", cpu->pc, addr);

	cpu->pc = addr;

	*cycles += 2;
}

static void exec_lda(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	DEBUG("Performing LDY of 0x%02x", arg);

	cpu->a = alu_load(arg, 0, flags);
}

static void exec_ldx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	DEBUG("Performing LDY of 0x%02x", arg);

	cpu->x = alu_load(arg, 0, flags);
}

static void exec_ldy(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	DEBUG("Performing LDY of 0x%02x", arg);

	cpu->y = alu_load(arg, 0, flags);
}

static void exec_lsr(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;
	u8 result;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	result = alu_lsr(arg, 0, &cpu->flags);

	DEBUG("Performing LSR of 0x%02x, result 0x%02x", arg, result);

	if (argtype == arg_addr) {
		bus_write(addr, result);
		*cycles += 1;
	}
	else {
		cpu->a = result;
	}
}

static void exec_nop(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	*cycles += 1;
}

static void exec_ora(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	cpu->a = alu_ora(cpu->a, arg, &cpu->flags);

	DEBUG("Performing ORA 0x%02x, Acc, result 0x%02x", arg, cpu->a);
}

static void exec_pha(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	exec_push(cpu, cpu->a);

	DEBUG("Performing PHA");

	*cycles += 2;
}

static void exec_php(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u8 flags;

	flags = cpu->flags;
	flags |= 0x30;

	exec_push(cpu, flags);

	DEBUG("Performing PHP");

	*cycles += 2;
}

static void exec_pla(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->a = exec_pop(cpu);

	DEBUG("Performing PLA");

	*cycles += 2;
}

static void exec_plp(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->flags = exec_pop(cpu);
	cpu->flags &= 0xCF;

	DEBUG("Performing PLP");

	*cycles += 2;
}

static void exec_rol(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;
	u8 result;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	result = alu_rol(arg, 0, &cpu->flags);

	DEBUG("Performing ROL of 0x%02x, result 0x%02x", arg, result);

	if (argtype == arg_addr) {
		bus_write(addr, result);
		*cycles += 1;
	}
	else {
		cpu->a = result;
	}
}

static void exec_ror(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;
	u8 result;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	result = alu_ror(arg, 0, &cpu->flags);

	DEBUG("Performing ROR of 0x%02x, result 0x%02x", arg, result);

	if (argtype == arg_addr) {
		bus_write(addr, result);
		*cycles += 1;
	}
	else {
		cpu->a = result;
	}
}

static void exec_rti(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	cpu->flags = exec_pop(cpu);
	cpu->flags &= 0xCF;

	addr = exec_pop(cpu);
	addr |= (u16)exec_pop(cpu) << 8;

	DEBUG("Performing RTI, old pc: 0x%04x, new pc: 0x%04x", cpu->pc, addr);

	cpu->pc = addr;

	cycles += 3;
}

static void exec_rts(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	addr = exec_pop(cpu);
	addr |= (u16)exec_pop(cpu) << 8;
	addr += 1;

	DEBUG("Performing RTS, old pc: 0x%04x, new pc: 0x%04x", cpu->pc, addr);

	cpu->pc = addr;

	cycles += 2;
}

static void exec_sbc(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;
	u8 arg;

	if (argtype == arg_addr) {
		addr = ((u16)args[1] << 8) | args[0]; 
		arg = bus_read(addr);
		*cycles += 2;
	}
	else {
		arg = args[0];
		*cycles += 1;
	}

	cpu->a = alu_sub(cpu->a, arg, &cpu->flags);

	DEBUG("Subtracting 0x%02x from Acc, result 0x%02x", arg, cpu->a);
}

static void exec_sec(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->flags |= flag_carry;

	DEBUG("Executing SEC");

	*cycles += 1;
}

static void exec_sed(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->flags |= flag_bcd;

	DEBUG("Executing SED");

	*cycles += 1;
}

static void exec_sei(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->flags |= flag_irqd;

	DEBUG("Executing SEI");

	*cycles += 1;
}

static void exec_sta(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	if (argtype != arg_addr)
		FATAL("STA: Invalid argument type != arg_addr");

	addr = ((u16)args[1] << 8) | args[0];

	bus_write(addr, cpu->a);

	DEBUG("Stored A register at 0x%04x", addr);

	*cycles += 2;
}

static void exec_stx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	if (argtype != arg_addr)
		FATAL("STX: Invalid argument type != arg_addr");

	addr = ((u16)args[1] << 8) | args[0];

	bus_write(addr, cpu->x);

	DEBUG("Stored X register at 0x%04x", addr);

	*cycles += 2;
}

static void exec_sty(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	u16 addr;

	if (argtype != arg_addr)
		FATAL("STY: Invalid argument type != arg_addr");

	addr = ((u16)args[1] << 8) | args[0];

	bus_write(addr, cpu->y);

	DEBUG("Stored Y register at 0x%04x", addr);

	*cycles += 2;
}

static void exec_tax(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->x = cpu->a;

	DEBUG("Executing TAX");

	*cycles += 1;
}

static void exec_tay(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->y = cpu->a;

	DEBUG("Executing TAY");

	*cycles += 1;
}

static void exec_tsx(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->x = cpu->sp;

	DEBUG("Executing TSX");

	*cycles += 1;
}

static void exec_txa(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->a = cpu->x;

	DEBUG("Executing TXA");

	*cycles += 1;
}

static void exec_txs(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->sp = cpu->x;

	DEBUG("Executing TXS");

	*cycles += 1;
}

static void exec_tya(cpustate_t *cpu, argtype_t argtype, u8 *args, cycles_t *cycles)
{
	cpu->a = cpu->y;

	DEBUG("Executing TYA");

	*cycles += 1;
}
