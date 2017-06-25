#ifndef _ERROR_H_
#define _ERROR_H_

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define NDEBUG 0

#define RED   "\x1B[31m"
#define GRN   "\x1B[32m"
#define YEL   "\x1B[33m"
#define RESET "\x1B[0m"

static inline void fatal(const char *fname, int lineno, const char *fcname, const char *msg, ...)
{
	va_list va_arg;

	fprintf(stderr, RED "[FATAL] [%s] @%d (%s): ", fname, lineno, fcname);
	fprintf(stderr, msg, va_arg);
	fprintf(stderr, "\nSimulation stopped.\n" RESET);
	fprintf(stderr, "Press Any Key to Exit...\n");
	getchar();
	exit(1);
}

static inline void warn(const char *fname, int lineno, const char *fcname, const char *msg, ...)
{
	va_list va_arg;

	fprintf(stderr, YEL "[WARNING] [%s] @%d (%s): ", fname, lineno, fcname);
	fprintf(stderr, msg, va_arg);
	fprintf(stderr, "\n" RESET);
}

static inline void debug(const char *fname, int lineno, const char *fcname, const char *msg, ...)
{
	va_list va_arg;

	fprintf(stderr, GRN "[DEBUG] [%s] @%d (%s): ", fname, lineno, fcname);
	fprintf(stderr, msg, va_arg);
	fprintf(stderr, "\n" RESET);
}

#define FATAL(msg, ...) fatal(__FILE__, __LINE__, __func__, msg, ##__VA_ARGS__)

#define WARN(msg, ...) warn(__FILE__, __LINE__, __func__, msg, ##__VA_ARGS__)

#define DEBUG(msg, ...) debug(__FILE__, __LINE__, __func__, msg, ##__VA_ARGS__)

#endif
