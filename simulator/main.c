#include <stdio.h>
#include "core.h"
#include "serial.h"
#include "memory.h"

int main(int argc, char *argv[])
{
	thread_t core_thread;

	memory_init();
	serial_init();
	core_init(&core_thread);

	while (1) {
		core_step();
		thread_sleep(1000);
	}

	return 0;
}
