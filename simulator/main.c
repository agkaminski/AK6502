#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include "common/error.h"
#include "core/core.h"
#include "parser/parser.h"
#include "bus/serial.h"
#include "bus/memory.h"
#include "monitor.h"

#define DEFAULT_FREQ 1000000

void usage(char *progname)
{
	printf("Usage: %s [options]\n", progname);
	printf("Options:\n");
	printf("  -f <file>    Initialize RAM with intel hex, srec or binary file.\n");
	printf("  -o <offset>  Put data from file begging at offet <offset>.\n");
	printf("  -s <freq>    Set core clock frequency to <freq> Hz (default 1 MHz)\n");
	printf("  -r           Run CPU immediately, skip interactive mode.\n");
	printf("  -h           This help.\n");
}

int main(int argc, char *argv[])
{
	cycles_t cycles;
	u16 offset = 0;
	u8 *rom = NULL;
	char path[128];
	int c;
	int mode = 0;
	int freq = DEFAULT_FREQ;

	memset(path, '\0', sizeof(path));

	while ((c = getopt(argc, argv, "o:f:s:rhv")) != -1) {
		switch (c) {
			case 'o':
				offset = strtol(optarg, NULL, 0);
				break;

			case 'f':
				strncpy(path, optarg, sizeof(path) - 1);
				path[sizeof(path) - 1] = '\0';
				break;

			case 's':
				freq = strtol(optarg, NULL, 10);
				if (freq == 0) {
					WARN("Invalid frequency. Falling back to default.");
					freq = DEFAULT_FREQ;
				}
				break;

			case 'r':
				mode = 1;
				break;

			case 'h':
				printf("AK6502 CPU simulator. Made by Aleksander Kaminski in 2017.\n");
				usage(argv[0]);
				return 0;

			case 'v':
				printf("AK6502 CPU simulator. Made by Aleksander Kaminski 2017.\n");
				printf("Version: %s\n", VERSION);
				return 0;

			case '?':
				if (optopt == 'o' || optopt == 'f')
					fprintf(stderr, "Option -%c requires an argument.\n", optopt);
				else if (isprint(optopt))
					fprintf(stderr, "Unknown option `-%c'.\n", optopt);
				else
					fprintf (stderr, "Unknown option character `\\x%x'.\n", optopt);
			default:
				usage(argv[0]);
				return -1;
		}
	}

	if (path[0] != '\0') {
		INFO("Initializing RAM from %s file at offset 0x%04x", path, offset);

		if ((rom = malloc(65536)) == NULL)
			FATAL("Out of memory!");

		if (parse_file(path, offset, rom, 65536) < 0) {
			WARN("Could not parse initialization file");
			free(rom);
			rom = NULL;
		}
	}

	if (mode && rom == NULL) {
		WARN("Memory has not been initialized, canceling run mode.");
		mode = 0;
	}

	memory_init(rom);
	free(rom);

	serial_init();
	core_init();
	core_setSpeed(freq);

	INFO("Resetting CPU...");
	core_rst();
	INFO("Ready.");

	monitor(mode);

	core_getState(NULL, &cycles);
	INFO("Ending simulation. CPU took total of %u cycles.", cycles);

	return 0;
}
