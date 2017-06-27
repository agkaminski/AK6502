#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common/error.h"
#include "core/core.h"
#include "bus/serial.h"
#include "bus/memory.h"

int main(int argc, char *argv[])
{
	cpustate_t cpu;
	cycles_t cycles;
	u16 offset;

	if (argc == 1) {
		INFO("No ROM file specified.");
	}
	else if (argc == 2) {
		INFO("Initializing RAM from %s ihex file...", argv[1]);
		//TODO
	}
	else if (argc == 3) {
		offset = strtol(argv[2], NULL, 0);
		INFO("Initializing RAM from %s file at offset %u", argv[1], offset);
		//TODO
	}

	memory_init();
	serial_init();

	INFO("Resetting CPU...");
	core_reset(&cpu, &cycles);
	INFO("Ready.");

	while (1) {
		core_step(&cpu, &cycles);
		getchar();
	}

	return 0;
}
