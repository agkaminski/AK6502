CC=gcc
CFLAGS=-Wall -Werror -O2 -ansi -std=gnu99
LIBS=-lpthread

OUT = sim
OBJ = addrmode.o alu.o bus.o core.o decoder.o exec.o main.o memory.o serial.o

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

$(OUT): $(OBJ)
	gcc -o $@ $^ $(LIBS)

.PHONY: clean

clean:
	rm -f *.o $(OUT) 
