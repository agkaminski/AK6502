#define _GNU_SOURCE

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include "common/error.h"
#include "common/threads.h"
#include "bus.h"
#include "serial.h"

#define SERIAL_BASE 0xe000

struct {
	int ptyfd;

	u8 fifo[256];
	int rpos;
	int wpos;

	thread_t thread;
	mutex_t mutex;
	cond_t cond;
} serial_global;

static int serial_isEmpty(void)
{
	if (serial_global.rpos == serial_global.wpos)
		return 1;

	return 0;
}

static int serial_isFull(void)
{
	if (serial_global.rpos == (serial_global.wpos + 1) % sizeof(serial_global.fifo))
		return 1;

	return 0;
}

static void serial_push(u8 data)
{
	lock(&serial_global.mutex);
	while (serial_isFull())
		thread_wait(&serial_global.cond, &serial_global.mutex);

	serial_global.fifo[serial_global.wpos] = data;
	serial_global.wpos = (serial_global.wpos + 1) % sizeof(serial_global.fifo);
	unlock(&serial_global.mutex);
}

static u8 serial_pop(void)
{
	u8 data;

	lock(&serial_global.mutex);
	thread_signal(&serial_global.cond);

	if (serial_isEmpty()) {
		unlock(&serial_global.mutex);
		return 0;
	}

	data = serial_global.fifo[serial_global.rpos];
	serial_global.rpos = (serial_global.rpos + 1) % sizeof(serial_global.fifo);
	unlock(&serial_global.mutex);

	return data;
}

static void serial_write(u16 offset, u8 data)
{
	switch (offset) {
		case 0:
			write(serial_global.ptyfd, &data, sizeof(data));
			DEBUG("Wrote '%c' to serial", data);
			break;

		case 1:
			WARN("Write at offset 1 takes no effect");
			break;

		default:
			FATAL("Invalid offset - bug in bus control");
			break;
	}
}

static u8 serial_read(u16 offset)
{
	u8 data = 0;

	switch (offset) {
		case 0:
			data = serial_pop();
			break;

		case 1:
			lock(&serial_global.mutex);
			data = !!serial_isEmpty();
			unlock(&serial_global.mutex);
			break;

		default:
			FATAL("Invalid offset - bug in bus control");
			break;
	}

	return data;
}

static void *serial_thread(void *arg)
{
	u8 data;

	while (1) {
		read(serial_global.ptyfd, &data, sizeof(data));
		DEBUG("Read '%c' from serial", data);
		serial_push(data);
	}

	return NULL;
}

void serial_init(void)
{
	busentry_t entry;

	serial_global.ptyfd = getpt();
	if (serial_global.ptyfd < 0)
		FATAL("Could not create ptty");

	if (grantpt(serial_global.ptyfd) < 0 || unlockpt(serial_global.ptyfd) < 0)
		FATAL("ptty error");

	serial_global.rpos = 0;
	serial_global.wpos = 0;

	mutex_init(&serial_global.mutex);
	thread_condInit(&serial_global.cond);

	entry.begin = SERIAL_BASE;
	entry.end = SERIAL_BASE + 1;
	entry.read = serial_read;
	entry.write = serial_write;

	INFO("Adding UART driver at address 0x%04x - 0x%04x", entry.begin, entry.end);
	bus_register(entry);

	INFO("Serial communication is available on %s", ptsname(serial_global.ptyfd));
	thread_create(&serial_global.thread, serial_thread, NULL);
}
