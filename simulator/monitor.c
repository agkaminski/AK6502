#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "common/error.h"
#include "bus/bus.h"
#include "core/core.h"
#include "monitor.h"

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

	printf("\t"GRN"q"RESET"uit - exits simulation\n");
	printf("\n");
}

void monitor(cpustate_t *cpu, cycles_t *cycles)
{
	int pos;
	char *line;
	char word[32];
	size_t linesz;

	printf("AK6502 simulator monitor ready.\n");
	printf("Input "GRN"help"RESET" to see available commands\n");

	while (1) {
		printf("> ");

		line = NULL;
		linesz = 0;
		linesz = getline(&line, &linesz, stdin);
		pos = 0;

		if (!next_word(line, &pos, word, sizeof(word)))
			continue;

		if (strcmp("h", word) == 0 || strcmp("help", word) == 0) {
			help();
		}
		else if (strcmp("s", word) == 0 || strcmp("step", word) == 0) {
			// TODO
		}
		else if (strcmp("r", word) == 0 || strcmp("run", word) == 0) {
			//TODO
		}
		else if (strcmp("q", word) == 0 || strcmp("quit", word) == 0) {
			free(line);
			break;
		}
		else {
			printf("Unrecognized command %s\n", word);
		}

		free(line);
	}
}
