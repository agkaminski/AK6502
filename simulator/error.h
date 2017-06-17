#ifndef _ERROR_H_
#define _ERROR_H_

#include <stdio.h>
#include <stdlib.h>

#define NDEBUG 0

#define RED   "\x1B[31m"
#define GRN   "\x1B[32m"
#define YEL   "\x1B[33m"
#define RESET "\x1B[0m"

static inline void fatal(const char *fname, int lineno, const char *fcname, const char *msg, ...)
{
	fprintf(stderr, RED"[FATAL] [%s] @%d (%s): "msg"\n", fname, lineno, fcname, __VA_ARGS__);
	fprintf(stderr, "Simulation stopped.\n"RESET);
	fprintf(stderr, "Press Any Key to Exit...\n");
	getchar();
	exit(1);
}

static inline void warn(const char *fname, int lineno, const char *fcname, const char *msg, ...)
{
	fprintf(stderr, YEL"[WARNING] [%s] @%d (%s): "msg"\n"RESET, fname, lineno, fcname, __VA_ARGS__);
}

static inline void debug(const char *fname, int lineno, const char *fcname, const char *msg, ...)
{
	fprintf(stderr, GRN"[DEBUG] [%s] @%d (%s): "msg"\n"RESET, fname, lineno, fcname, __VA_ARGS__);
}

#define FATAL(msg, ...) fatal(__FILE__, __LINE__, __func__, msg, ##__VA_ARGS__);
		
#define WARN(msg, ...) warn(__FILE__, __LINE__, __func__, msg, ##__VA_ARGS__);

#define DEBUG(msg, ...) debug(__FILE__, __LINE__, __func__, msg, ##__VA_ARGS__);

#endif