#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include "binary.h"
#include "error.h"

typedef struct {
	u16 addr;
	u8 size;
	u8 type;
	u8 data[];
} ihexline_t;

static int ihex_nextLine(int fd, char *buff, size_t bufflen)
{
	char c;
	int ret, count = 0;

	ret = read(fd, &c, 1);

	while (ret > 0 && c != '\n' && c != '\0') {
		if (ret < 0) {
			WARN("Error reading file");
			return -1;
		}

		count += ret;

		if (ret == 0) {
			DEBUG("End of file");
			break;
		}

		if (count > bufflen - 2) {
			WARN("Buffer depleted, aborting");
			return -1;
		}

		*(buff + count) = c;

		ret = read(fd, &c, 1);
	}

	*(buff + count) = '\0';

	return count;
}

static int ihex_hextobyte(char *buff, u8 *data)
{
	u8 tmp;

	tmp = *buff++;

	if (tmp - '0' <= '9')
		*data = tmp - '0';
	else if (tmp - 'a' <= 'f')
		*data = tmp - 'a' + 10;
	else if (tmp - 'A' <= 'F')
		*data = tmp - 'A' + 10;
	else
		return -1;

	*data = *data << 8;
	tmp = *buff;

	if (tmp - '0' <= '9')
		*data += tmp - '0';
	else if (tmp - 'a' <= 'f')
		*data += tmp - 'a' + 10;
	else if (tmp - 'A' <= 'F')
		*data += tmp - 'A' + 10;
	else
		return -1;

	return 0;
}

static int ihex_parseLine(ihexline_t *data, size_t datalen, char *buff, size_t bufflen)
{
	unsigned int i;
	u8 tmp;
	u8 chksum;

	if (bufflen < 12) {
		WARN("Buffer can't hold single ihex line");
		return -1;
	}

	if (*buff++ != ':') {
		WARN("Corrupted ihex file, no : start code");
		return -1;
	}

	if (ihex_hextobyte(buff, &data->size)) {
		WARN("Corrupted ihex file, not a hex value");
		return -1;
	}

	chksum = data->size;

	if (size + 12 > bufflen || size > datalen) {
		WARN("Buffer can't hold this ihex line (data size %u)", size);
		return -1;
	}

	if (ihex_hextobyte(buff, &data->addr)) {
		WARN("Corrupted ihex file, not a hex value");
		return -1;
	}

	chksum += data->addr;

	if (ihex_hextobyte(buff, &tmp)) {
		WARN("Corrupted ihex file, not a hex value");
		return -1;
	}

	chksum += tmp;
	data->addr = (data->addr << 8) + tmp;

	if (ihex_hextobyte(buff, &data->type)) {
		WARN("Corrupted ihex file, not a hex value");
		return -1;
	}

	chksum += type;

	if (data->type != 0 && data->type != 1) {
		WARN("Unsupported entry type: %u", data->type);
		return -1;
	}

	for (i = 0; i < data->size; ++i) {
		if (ihex_hextobyte(buff, &data->data[i])) {
			WARN("Corrupted ihex file, not a hex value");
			return -1;
		}

		chksum += data->data[i];
	}

	if (ihex_hextobyte(buff, &tmp)) {
		WARN("Corrupted ihex file, not a hex value");
		return -1;
	}

	chksum += tmp;

	if (chksum != 0) {
		WARN("Checksum error");
		return -1;
	}

	return 0;
}

int ihex_parse(const char *path, u16 offset, u8 *buff, size_t bufflen)
{
	ihexline_t *data;
	char line[256 + 12];
	u8 data_buff[256 + sizeof(ihexline_t)];
	int fd, ret, count = 0;

	if ((fd = fopen(path, O_RDONLY)) < 0) {
		WARN("Could not open file %s", path);
		return -1;
	}

	while (1) {
		ret = ihex_nextLine(fd, line, sizeof(line));

		if (ret < 0) {
			close(fd);
			return -1;
		}
		else if (ret == 0) {
			break;
		}

		if (ihex_parseLine(data, 256, line, sizeof(line)) < 0) {
			close(fd);
			return -1;
		}

		if (data->type == 0)
			break;

		if (data->addr + data->size > bufflen) {
			data->size = bufflen - data->addr - 1;
			WARN("Not writing data above buffer limit");
		}

		memcpy(buff + data->addr, data->data, data->size);
		count += data->size;
	}

	close(fd);

	return count;
}
