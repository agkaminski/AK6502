#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common/error.h"
#include "core/flags.h"
#include "bus/bus.h"
#include "core/addrmode.h"
#include "core/decoder.h"
#include "core/exec.h"
#include "monitor.h"

typedef enum { cmd_none, cmd_help, cmd_step, cmd_run, cmd_trig, cmd_cpu, cmd_quit } cmd_t;

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
	word[*pos] = '\0';

	return 1;
}

static void help(void)
{
	printf("Available commands:\n");
	printf("\t"GRN"h"RESET"elp - displays this message\n");
	printf("\t"GRN"s"RESET"tep - proceeds simulation by one instruction\n");
	printf("\t"GRN"r"RESET"un - continuous simulation. Press s to stop\n");
	printf("\t"GRN"c"RESET"pu - show current cpu state\n");
	printf("\t"GRN"t"RESET"rigger <type> - cause event (rst, irq, nmi)\n");

	printf("\t"GRN"q"RESET"uit - exits simulation\n");
	printf("\n");
}

static void show_cpu(cpustate_t *cpu)
{
	printf("--------------------------------------\n");
	printf("| A    | X    | Y    | SP   | PC     |\n");

	printf("| 0x%02x ", cpu->a);
	printf("| 0x%02x ", cpu->x);
	printf("| 0x%02x ", cpu->y);
	printf("| 0x%02x ", cpu->sp);
	printf("| 0x%04x |\n", cpu->pc);

	printf("--------------------------------------\n");
	printf("| FL | N | V | - | B | D | I | Z | C |\n");

	printf("|    ");
	printf("| %01d ", !!(cpu->flags & flag_sign));
	printf("| %01d ", !!(cpu->flags & flag_ovrf));
	printf("| - ");
	printf("| %01d ", !!(cpu->flags & flag_brk));
	printf("| %01d ", !!(cpu->flags & flag_bcd));
	printf("| %01d ", !!(cpu->flags & flag_irqd));
	printf("| %01d ", !!(cpu->flags & flag_zero));
	printf("| %01d |\n", !!(cpu->flags & flag_carry));

	printf("--------------------------------------\n");
}

static void step_cpu(cpustate_t *cpu, cycles_t *cycles)
{
	opinfo_t instruction;
	argtype_t argtype;
	u8 opcode, args[2];
	u16 pc;

	pc = cpu->pc;
	opcode = addrmode_nextpc(cpu);
	instruction = decode(opcode);
	argtype = addrmode_getArgs(cpu, args, instruction.mode, cycles);
	exec_execute(cpu, instruction.opcode, argtype, args, cycles);

	*cycles += 1;

	printf("0x%04x: 0x%02x (%s)\n", pc, opcode, opcodetostring(instruction.opcode));
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
	else if (strcmp("q", cmd) == 0 || strcmp("quit", cmd) == 0)
		return cmd_quit;

	return cmd_none;
}

void monitor(cpustate_t *cpu, cycles_t *cycles)
{
	int pos;
	char *line;
	char word[32];
	size_t linesz;
	cmd_t lastcmd = cmd_none;

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
				step_cpu(cpu, cycles);
				break;

			case cmd_run:
				//TODO
				break;

			case cmd_cpu:
				show_cpu(cpu);
				break;

			case cmd_trig:
				//TODO
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
