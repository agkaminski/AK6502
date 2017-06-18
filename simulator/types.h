#ifndef _TYPES_H_
#define _TYPES_H_

typedef u8 unsigned char
typedef u16 unsigned short
typedef u32 unsigned long
typedef u64 unsigned long long

typedef s8 signed char
typedef s16 signed short
typedef s32 signed long
typedef s64 signed long long

typedef struct {
	u16 pc;
	u8 a;
	u8 x;
	u8 y;
	u8 sp;
	u8 flags;
} cpustate_t;

typedef unsigned int cycles_t;

#endif