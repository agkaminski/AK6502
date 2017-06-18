#include "alu.h"
#include "types.h"
#include "flags.h"

void alu_flags(u16 result, u8 *flags, u8 mask)
{
	if (mask & flag_carry) {
		if (result > 0xff)
			*flags |= flag_carry;
		else
			*flags &= ~flag_carry;
	}

	if (mask & flag_zero) {
		if (result & 0xff == 0)
			*flags |= flag_zero;
		else
			*flags &= ~flag_zero;
	}

	if (mask & flag_sign) {
		if (result & 0x80)
			*flags |= flag_sign;
		else
			*flags &= ~flag_sign;
	}
}

u8 alu_add(u8 a, u8 b, u8 *flags)
{
	u16 result;

	result = a + b;

	if (*flags & flag_carry)
		++result;

	if (flags & flag_bcd) {
		if ((a & 0xf) + (b & 0xf) > 9)
			result += 0x06;

		if ((result >> 4) > 9)
			result += 0x60;
	}

	alu_flags(result, flags, flag_carry | flag_sign | flag_zero);

	if ((a ^ result) & (b ^ result) & 0x80)
		*flags |= flag_ovfl;

	return result & 0xff;
}

u8 alu_sub(u8 a, u8 b, u8 *flags)
{
	u16 result;

	result = a - b;

	if (!(*flags & flag_carry))
		++result;

	if (flags & flag_bcd) {
		if ((a & 0xf) + (b & 0xf) > 9)
			result += 0x06;

		if ((result >> 4) > 9)
			result += 0x60;
	}

	alu_flags(result, flags, flag_carry | flag_sign | flag_zero)

	if ((a ^ result) & (b ^ result) & 0x80)
		*flags |= flag_ovfl;

	return result & 0xff;
}

u8 alu_inc(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a + 1;

	alu_flags(result, flags, flag_sign | flag_zero);

	return result;
}

u8 alu_dec(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a - 1;

	alu_flags(result, flags, flag_sign | flag_zero);

	return result;
}

u8 alu_and(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a & b;

	alu_flags(result, flags, flag_sign | flag_zero);

	return result;
}

u8 alu_or(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a | b;

	alu_flags(result, flags, flag_sign | flag_zero);

	return result;
}

u8 alu_eor(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a ^ b;

	alu_flags(result, flags, flag_sign | flag_zero);

	return result;
}

u8 alu_rol(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a << 1;

	if (flags & flag_carry)
		result |= 1;

	alu_flags(result, flags, flag_sign | flag_zero);

	if (a & 0x80)
		flags |= flag_carry;
	else
		flags &= ~flag_carry;

	return result;
}

u8 alu_ror(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a >> 1;

	if (flags & flag_carry)
		result |= 0x80;

	alu_flags(result, flags, flag_sign | flag_zero);

	if (a & 0x80)
		flags |= flag_carry;
	else
		flags &= ~flag_carry;

	return result;
}

u8 alu_asl(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a << 1;

	alu_flags(result, flags, flag_sign | flag_zero);

	return result;
}

u8 alu_lsr(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a >> 1;

	alu_flags(result, flags, flag_sign | flag_zero);

	return result;
}

u8 alu_bit(u8 a, u8 b, u8 *flags)
{
	u8 result;

	result = a & b;

	alu_flags(result, flags, flag_sign | flag_zero);

	if (result & 0x40)
		flags |= flag_ovfl;
	else
		flags &= ~flag_ovfl;

	return result;
}

u8 alu_cmp(u8 a, u8 b, u8 *flags)
{
	u16 result;

	result = a - b + 1;

	alu_flags(result, flags, flag_carry | flag_sign | flag_zero)

	return result & 0xff;
}

u8 alu_load(u8 a, u8 b, u8 *flags)
{
	alu_flags(a, flags, flag_zero | flag_sign);

	return a;
}
