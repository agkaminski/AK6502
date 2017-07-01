#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common/error.h"
#include "parser/parser.h"
#include "core/core.h"
#include "bus/serial.h"
#include "bus/memory.h"

int main(int argc, char *argv[])
{
	cpustate_t cpu;
	cycles_t cycles;
	u16 offset;
	u8 *rom = NULL;

	if (argc == 1) {
		INFO("No ROM file specified.");
	}
	else if (argc == 2 || argc == 3) {
		if (argc == 3)
			offset = strtol(argv[2], NULL, 0);
		else
			offset = 0;

		INFO("Initializing RAM from %s file at offset %u", argv[1], offset);

		if ((rom = malloc(65536)) == NULL)
			FATAL("Out of memory!");

		if (parse_file(argv[1], offset, rom, 65536) < 0) {
			WARN("Could not parse initialization file");
			free(rom);
			rom = NULL;
		}
	}
	else {
		printf("Usage: %s [initialization file] [offset]\n", argv[0]);
		return -1;
	}

	memory_init(rom);
	free(rom);

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
