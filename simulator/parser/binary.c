#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include "binary.h"
#include "common/error.h"

int binary_parse(const char *path, u16 offset, u8 *buff, size_t bufflen)
{
	int count = offset, ret;
	int fd = open(path, O_RDONLY);

	if (fd < 0) {
		WARN("Could not open file %s", path);
		return -1;
	}

	DEBUG("Starting reading file %s", path);

	while (count < bufflen) {
		ret = read(fd, buff + count, (count + 256 >= bufflen) ? bufflen - count - 1 : 256);
		count += ret;

		if (ret < 0) {
			WARN("Error while reading file %s", path);
			return -1;
		}
		else if (ret == 0) {
			DEBUG("Finished reading file %s", path);
			break;
		}
	}

	if (ret != 0 && !(count < bufflen))
		WARN("Stopped reading file because it could not fit in buffer");

	return count;
}
