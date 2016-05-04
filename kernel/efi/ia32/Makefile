OUTPUT = bootia32.efi

EFI_CC ?= gcc

CFLAGS = -I../inc -I../efi -I../efi/inc -I../efi/inc/ia32 -I../efi/inc/protocol -Wall -Wextra -Wno-long-long -g -ffreestanding

OBJS = efimain.o data.o misc.o

all: $(OUTPUT)

%.o: %.c Makefile
	$(EFI_CC) -c -o $@ $< $(CFLAGS)
	
$(OUTPUT): $(OBJS)
	$(EFI_CC) -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e _efi_main -o $(OUTPUT) $(OBJS) -lgcc

.PHONY: clean

clean:
	rm -f *.o $(OUTPUT)

