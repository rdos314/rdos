OUTPUT = bootx64.efi

EFI_CC ?= gcc

CFLAGS = -Iinc -Iefi -Iefi/inc -Iefi/inc/x86_64 -Iefi/inc/protocol -Wall -Wextra -Wno-long-long -g -ffreestanding

OBJS = efimain.o console.o data.o file.o malloc.o printf.o string.o strtod.o strtol.o strtoll.o strtoull.o scanf.o abort.o serial.o efilibc.o atof.o misc.o

all: $(OUTPUT)

%.o: %.c Makefile
	$(EFI_CC) -c -o $@ $< $(CFLAGS)
	
$(OUTPUT): $(OBJS)
	$(EFI_CC) -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main -o $(OUTPUT) $(OBJS) -lgcc

.PHONY: clean

clean:
	rm -f *.o $(OUTPUT)

