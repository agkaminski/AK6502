CC = gcc
CFLAGS = -Wall -Werror -O2 -ansi -std=gnu99
LIBS = -lpthread

OUT = sim
OBJ =  core/addrmode.o core/alu.o core/core.o core/decoder.o core/exec.o
OBJ += bus/bus.o bus/memory.o bus/serial.o
OBJ += parser/binary.o parser/ihex.o parser/srec.o
OBJ += monitor.o main.o

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS) -I.

$(OUT): $(OBJ)
	gcc -o $@ $^ $(LIBS)

.PHONY: clean

clean:
	rm -f *.o $(OUT)
	rm -f core/*.o
	rm -f bus/*.o
	rm -f parser/*.o
