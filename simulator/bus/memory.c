#include <stdlib.h>
#include "common/error.h"
#include "memory.h"
#include "bus.h"

struct {
	u8 *low;
	u8 *high;
} memory_global;

static void memory_low_write(u16 offset, u8 data)
{
	memory_global.low[offset] = data;
}

static u8 memory_low_read(u16 offset)
{
	return memory_global.low[offset];
}

static void memory_high_write(u16 offset, u8 data)
{
	memory_global.high[offset] = data;
}

static u8 memory_high_read(u16 offset)
{
	return memory_global.high[offset];
}

void memory_init(void)
{
	busentry_t entry;

	if ((memory_global.low = malloc(0xe000)) == NULL)
		FATAL("Out of memory");

	if ((memory_global.high = malloc(0x1000)) == NULL)
		FATAL("Out of memory");

	entry.begin = 0x0000;
	entry.end = 0xdfff;
	entry.read = memory_low_read;
	entry.write = memory_low_write;

	INFO("Adding RAM at address 0x%04x (size 0x%04x bytes)", entry.begin, entry.end - entry.begin);
	bus_register(entry);

	entry.begin = 0xf000;
	entry.end = 0xffff;
	entry.read = memory_high_read;
	entry.write = memory_high_write;

	INFO("Adding RAM at address 0x%04x (size 0x%04x bytes)", entry.begin, entry.end - entry.begin);
	bus_register(entry);
}
