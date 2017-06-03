CC = iverilog
FLAGS = -v -Wall -Winfloop
OUTPUT = AK6502.iv
MODULES = cpu/AK6502.v cpu/addsub.v cpu/alu.v cpu/control_unit.v cpu/opdecoder.v cpu/ucode.v
TESTBENCH = verification/AK6502_tb.v verification/ram.v

all:
	$(CC) $(FLAGS) -o $(OUTPUT) $(MODULES) $(TESTBENCH)

clean:
	rm $(OUTPUT)
