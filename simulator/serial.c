#include <unistd.h>
#include "serial.h"
#include "bus.h"
#include "error.h"
#include "threads.h"

#define SERIAL_BASE 0xe000

struct {
	int infd;
	int outfd;

	u8 fifo[32];
	int rpos;
	int wpos;

	thread_t thread;
	mutex_t mutex;
	cond_t cond;
} serial_global;

static void serial_pipeWrite(u8 data)
{
	//TODO
}

static u8 serial_pipeRead(void)
{
	//TODO
}

static void serial_write(u16 offset, u8 data)
{
	switch (offset) {
		case 0:
			serial_pipeWrite(data);
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
	u8 data;

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
}

static void serial_thread(void *arg)
{
	u8 data;

	while (1) {
		data = serial_pipeRead();
		serial_push(data);
	}
}

void serial_init(void)
{
	busentry_t entry;

	//TODO PIPES

	serial_global.rpos = 0;
	serial_global.wpos = 0;

	mutex_init(&serial_global.mutex);
	thread_condInit(&serial_global.cond);

	entry.begin = SERIAL_BASE;
	entry.end = SERIAL_BASE + 1;
	entry.read = serial_read;
	entry.write = serial_write;

	bus_register(entry);

	thread_create(&serial_global.thread, serial_thread, NULL);
}
