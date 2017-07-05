#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common/error.h"
#include "core/flags.h"
#include "bus/bus.h"
#include "core/addrmode.h"
#include "core/decoder.h"
#include "core/core.h"
#include "parser/parser.h"
#include "monitor.h"

typedef enum { cmd_none, cmd_help, cmd_step, cmd_run, cmd_trig, cmd_cpu,
	cmd_speed, cmd_load, cmd_write, cmd_dump, cmd_put, cmd_quit } cmd_t;

static inline int is_separator(char c)
{
	return c == '\r' || c == '\n' || c == ' ' || c == '\t';
}

static int next_word(const char *line, int *pos, char *word, size_t wordsz)
{
	int bpos;

	while (line[*pos] != '\0' && is_separator(line[*pos]))
		++(*pos);

	if (line[*pos] == '\0')
		return 0;

	bpos = *pos;

	while (line[*pos] != '\0' && !is_separator(line[*pos]))
		++(*pos);

	if (*pos - bpos > wordsz) {
		printf("Argument is too long\n");
		return 0;
	}

	memcpy(word, &line[bpos], *pos - bpos);
	word[*pos - bpos] = '\0';

	return 1;
}

static void help(void)
{
	printf("Available commands:\n");
	printf("\t"GRN"h"RESET"elp - displays this message\n");
	printf("\t"GRN"s"RESET"tep - proceeds simulation by one instruction\n");
	printf("\t"GRN"r"RESET"un - continuous simulation. Press s to stop\n");
	printf("\t"GRN"c"RESET"pu - show current cpu state\n");
	printf("\t"GRN"f"RESET"requency - set run mode cpu speed (in Hz)\n");
	printf("\t"GRN"t"RESET"rigger <type> - cause event (rst, irq, nmi)\n");
	printf("\t"GRN"l"RESET"oad <path> <offset> - loads content of the file <path> to the memory\n");
	printf("\t"GRN"w"RESET"rite <offset> [data] - interactive write starting at <offset>\n");
	printf("\t"GRN"d"RESET"ump <offset> <count> - dumps <count> bytes from memory at <offset>\n");
	printf("\t"GRN"p"RESET"ut <reg> <val> - sets register (A, X, Y, SP, PC, FLAGS) to val\n");

	printf("\t"GRN"q"RESET"uit - exits simulation\n");
	printf("\n");
}

static void show_cpu(void)
{
	cpustate_t cpu;
	cycles_t cycles;

	core_getState(&cpu, &cycles);

	printf("--------------------------------------\n");
	printf("| A    | X    | Y    | SP   | PC     |\n");

	printf("| 0x%02x ", cpu.a);
	printf("| 0x%02x ", cpu.x);
	printf("| 0x%02x ", cpu.y);
	printf("| 0x%02x ", cpu.sp);
	printf("| 0x%04x |\n", cpu.pc);

	printf("--------------------------------------\n");
	printf("| FL | N | V | - | B | D | I | Z | C |\n");

	printf("| AG ");
	printf("| %01d ", !!(cpu.flags & flag_sign));
	printf("| %01d ", !!(cpu.flags & flag_ovrf));
	printf("| - ");
	printf("| %01d ", !!(cpu.flags & flag_brk));
	printf("| %01d ", !!(cpu.flags & flag_bcd));
	printf("| %01d ", !!(cpu.flags & flag_irqd));
	printf("| %01d ", !!(cpu.flags & flag_zero));
	printf("| %01d |\n", !!(cpu.flags & flag_carry));

	printf("--------------------------------------\n");
	printf("Runtime: %u cycles.\n", cycles);
}

static void step_cpu(void)
{
	cpustate_t cpu;
	opinfo_t instruction;
	u8 opcode;
	u16 pc;

	core_getState(&cpu, NULL);
	pc = cpu.pc;
	opcode = addrmode_nextpc(&cpu);
	instruction = decode(opcode);

	core_step();

	printf("0x%04x: 0x%02x (%s)\n", pc, opcode, opcodetostring(instruction.opcode));
}

static void run_cpu(void)
{
	core_run();
	printf("CPU is running. Press any key to stop...\n");
	getchar();
	core_stop();
}

static void trigger(char *type)
{
	if (strcmp(type, "rst") == 0) {
		core_rst();
	}
	else if (strcmp(type, "nmi") == 0) {
		core_nmi();
	}
	else if (strcmp(type, "irq") == 0) {
		core_irq();
	}
	else {
		printf("Unknown trigger '%s'\n", type);
		return;
	}

	printf("Trigger request %s has been sent\n", type);
}

static void speed(char *freq)
{
	unsigned int hz;

	hz = strtol(freq, NULL, 10);

	printf("Setting core frequency to %u Hz\n", hz);
	core_setSpeed(hz);
}

static void load(char *line, int pos)
{
	char path[32];
	char buff[32];
	u8 *mem;
	u16 offset;
	int count, i;

	if (!next_word(line, &pos, path, sizeof(path))) {
		printf("Command load requires argument.\n");
		return;
	}

	if (!next_word(line, &pos, buff, sizeof(buff)))
		offset = 0;
	else
		offset = strtol(buff, NULL, 16);

	if ((mem = malloc(65536)) == NULL) {
		WARN("Out of memory!");
		return;
	}

	count = parse_file(path, offset, mem, 65536);

	for (i = 0; i < count; ++i) {
		if (offset + i > 65535)
			break;
		bus_write(offset + i, mem[offset + i]);
	}

	if (count < 0)
		printf("Failed to read file %s\n", path);
	else
		printf("Read %d bytes.\n", count);

	free(mem);
}

static void write(char *line, int pos)
{
	char buff[32];
	u16 offset;
	size_t i = 0;

	if (!next_word(line, &pos, buff, sizeof(buff))) {
		printf("Command write requires argument.\n");
		return;
	}
	offset = strtol(buff, NULL, 16);

	if (!next_word(line, &pos, buff, sizeof(buff))) {
		printf("Interactive mode.\n");
		printf("Enter 'n' to leave data unchanged, 'q' to exit.\n");

		while (1) {
			if ((size_t)offset + i > 65535)
				break;

			printf("%04x\t%02x\t", (unsigned int)(offset + i), bus_read(offset + i));

			while (scanf("%2s", buff) != 1);

			while ((buff[3] = getchar()) != EOF && buff[3] != '\n');

			if (buff[0] == 'q')
				break;

			if (buff[0] == 'n')
				continue;

			buff[3] = '\0';

			bus_write(offset + i++, strtol(buff, NULL, 16));
		}
	}
	else {
		do {
			if ((size_t)offset + i > 65535)
				break;
			bus_write(offset + i++, strtol(buff, NULL, 16));
		} while (next_word(line, &pos, buff, sizeof(buff)));
	}

	printf("Wrote %u bytes.\n", (unsigned int)i);
}

static void dump(char *line, int pos)
{
	char buff[32];
	u16 offset;
	size_t count, i;

	if (!next_word(line, &pos, buff, sizeof(buff))) {
		printf("Command dump requires 2 arguments.\n");
		return;
	}
	offset = strtol(buff, NULL, 16);

	if (!next_word(line, &pos, buff, sizeof(buff))) {
		printf("Command dump requires 2 arguments.\n");
		return;
	}
	count = strtol(buff, NULL, 16);

	printf("Dumping %u bytes beggining at address %u...\n", (unsigned int)count, offset);

	for (i = 0; i < count; ++i) {
		if ((size_t)offset + i > 65535)
			break;
		if (!(i % 16))
			printf("\n%04x\t", (unsigned int)(offset + i));
		printf(" %02x", bus_read(offset + i));
	}
	printf("\n");
}

static void put(char *line, int pos)
{
	char buff[5];
	char reg[6];
	u16 val;
	cpustate_t cpu;

	if (!next_word(line, &pos, reg, sizeof(reg))) {
		printf("Command dump requires 2 arguments.\n");
		return;
	}

	if (!next_word(line, &pos, buff, sizeof(buff))) {
		printf("Command dump requires 2 arguments.\n");
		return;
	}

	val = strtol(buff, NULL, 16);

	core_getState(&cpu, NULL);

	if (strcmp(reg, "A") == 0 || strcmp(reg, "a") == 0) {
		cpu.a = val & 0xff;
		printf("Setting A register to 0x%02x\n", val & 0xff);
	}
	else if (strcmp(reg, "X") == 0 || strcmp(reg, "x") == 0) {
		cpu.x = val & 0xff;
		printf("Setting X register to 0x%02x\n", val & 0xff);
	}
	else if (strcmp(reg, "Y") == 0 || strcmp(reg, "y") == 0) {
		cpu.y = val & 0xff;
		printf("Setting Y register to 0x%02x\n", val & 0xff);
	}
	else if (strcmp(reg, "SP") == 0 || strcmp(reg, "sp") == 0) {
		cpu.sp = val & 0xff;
		printf("Setting stack pointer to 0x%02x\n", val & 0xff);
	}
	else if (strcmp(reg, "PC") == 0 || strcmp(reg, "pc") == 0) {
		cpu.pc = val;
		printf("Setting program counter to 0x%04x\n", val);
	}
	else if (strcmp(reg, "FLAGS") == 0 || strcmp(reg, "flags") == 0) {
		cpu.flags = val & 0xff;
		printf("Setting status register to 0x%02x\n", val & 0xff);
	}
	else {
		printf("Unknown reg %s\n", reg);
	}

	core_setState(&cpu);
}

static cmd_t decode_cmd(const char *cmd)
{
	if (strcmp("h", cmd) == 0 || strcmp("help", cmd) == 0)
		return cmd_help;
	else if (strcmp("s", cmd) == 0 || strcmp("step", cmd) == 0)
		return cmd_step;
	else if (strcmp("r", cmd) == 0 || strcmp("run", cmd) == 0)
		return cmd_run;
	else if (strcmp("c", cmd) == 0 || strcmp("cpu", cmd) == 0)
		return cmd_cpu;
	else if (strcmp("t", cmd) == 0 || strcmp("trigger", cmd) == 0)
		return cmd_trig;
	else if (strcmp("f", cmd) == 0 || strcmp("frequency", cmd) == 0)
		return cmd_speed;
	else if (strcmp("l", cmd) == 0 || strcmp("load", cmd) == 0)
		return cmd_load;
	else if (strcmp("w", cmd) == 0 || strcmp("write", cmd) == 0)
		return cmd_write;
	else if (strcmp("d", cmd) == 0 || strcmp("dump", cmd) == 0)
		return cmd_dump;
	else if (strcmp("p", cmd) == 0 || strcmp("put", cmd) == 0)
		return cmd_put;
	else if (strcmp("q", cmd) == 0 || strcmp("quit", cmd) == 0)
		return cmd_quit;

	return cmd_none;
}

void monitor(int mode)
{
	int pos;
	char *line;
	char word[32];
	size_t linesz;
	cmd_t lastcmd = cmd_none;

	if (mode) {
		run_cpu();
	}

	printf("AK6502 simulator monitor ready.\n");
	printf("Input "GRN"help"RESET" to see available commands\n");

	while (lastcmd != cmd_quit) {
		printf("> ");

		line = NULL;
		linesz = 0;
		linesz = getline(&line, &linesz, stdin);
		pos = 0;

		if (!next_word(line, &pos, word, sizeof(word))) {
			if (lastcmd == cmd_none)
				continue;
		}
		else {
			lastcmd = decode_cmd(word);
		}

		switch (lastcmd) {
			case cmd_help:
				help();
				break;

			case cmd_step:
				step_cpu();
				break;

			case cmd_run:
				run_cpu();
				break;

			case cmd_cpu:
				show_cpu();
				break;

			case cmd_trig:
				if (!next_word(line, &pos, word, sizeof(word)))
					printf("Command trigger requires argument.\n");
				else
					trigger(word);
				break;

			case cmd_speed:
				if (!next_word(line, &pos, word, sizeof(word)))
					printf("Command frequency requires argument.\n");
				else
					speed(word);
				break;

			case cmd_load:
				load(line, pos);
				break;

			case cmd_write:
				write(line, pos);
				break;

			case cmd_dump:
				dump(line, pos);
				break;

			case cmd_put:
				put(line, pos);
				break;

			case cmd_quit:
				break;

			default:
				printf("Unrecognized command %s\n", word);
				break;
		};

		free(line);
	}
}
