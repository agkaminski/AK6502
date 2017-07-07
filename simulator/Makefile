CC = gcc
CFLAGS = -Wall -Werror -O2 -ansi -std=gnu99
LIBS = -lpthread
VERSION = -DVERSION=\"0.1\"
DEBUG = -DNDEBUG
INSTALL_PATH = /usr/bin/

OUT = simak65
OBJ =  core/addrmode.o core/alu.o core/core.o core/decoder.o core/exec.o
OBJ += bus/bus.o bus/memory.o bus/serial.o
OBJ += parser/binary.o parser/ihex.o parser/srec.o parser/parser.o
OBJ += monitor.o main.o

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) $(VERSION) $(DEBUG) -I.

$(OUT): $(OBJ)
	gcc -o $@ $^ $(LIBS)

install:
	cp $(OUT) $(INSTALL_PATH)/$(OUT)

clean:
	rm -f *.o $(OUT)
	rm -f core/*.o
	rm -f bus/*.o
	rm -f parser/*.o

.PHONY: clean
.PHONY: install
