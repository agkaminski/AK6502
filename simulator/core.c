#include <stdlib.h>
#include "core.h"

struct {
	u16 pc;
	u8 a;
	u8 x;
	u8 y;
	u8 sp;
	u8 flags;
} core_regs;


enum {
	flag_carry = 0x01;
	flag_zero =  0x02;
	flag_irqd =  0x04;
	flag_bcd =   0x08;
	flag_brk =   0x10;
	flag_ovrf =  0x40;
	flag_sign =  0x80;
};





void core_init(void)
{
	core_regs.a = 0;
	core_regs.x = 0;
	core_regs.y = 0;
	core_regs.sp = 0xff;
	core_regs.pc = 0xfffc;
	core_regs.flags = flag_irqd;
}