;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage in embedded systems. For information on
; usage in commercial embedded systems, contact embedded@rdos.net
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;
; The author of this program may be contacted at leif@rdos.net
;
; BOOTPROM.ASM
; Bootloader for PROM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  bootprom

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

GateSize = 16

INCLUDE ..\os.def
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc

DRAM_SIZE 		EQU 0000E0000h
PROM_BASE		EQU 0FFFE0000h

DefaultIdtEntry		MACRO
	dw OFFSET DefaultInt
	dw device_code_sel
	dw 8E00h
	dw 0
					ENDM

BootIdtEntry		MACRO Offs
	dw OFFSET Offs
	dw device_code_sel
	dw 8E00h
	dw 0
					ENDM

BootExceptionOnePar	MACRO Entry
	push bp
	mov bp,sp
	sti
	push eax
	push ebx
	push ds
	mov al,Entry
	ShutDownPreTask
				ENDM

BootExceptionNoPar	MACRO Entry
	push dword ptr 0
	push bp
	mov bp,sp
	sti
	push eax
	push ebx
	push ds
	mov al,Entry
	ShutDownPreTask
				ENDM

FindRam     MACRO
    Local RamLoop
    Local RamNext
    Local RamFound

    mov ax,flat_sel
    mov ds,ax
    jmp RamNext
RamLoop:
	mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    je RamFound
RamNext:
    add esi,1000h
    cmp esi,DRAM_SIZE
    jc RamLoop
	stc
RamFound:
            ENDM

.code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CalcCrc
;
;		DESCRIPTION:	Calculate CRC for one byte
;
;       PARAMETERS:     AX      CRC
;                       DS:ESI  Address to data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcCrc Proc near
    push cx
    mov cl,[esi]
    inc esi
	xor ah,cl
;
	mov cx,1021h
	shl ax,1
	jnc no_xor0
	xor ax,cx
no_xor0:
	shl ax,1
	jnc no_xor1
	xor ax,cx
no_xor1:
	shl ax,1
	jnc no_xor2
	xor ax,cx
no_xor2:
	shl ax,1
	jnc no_xor3
	xor ax,cx
no_xor3:
	shl ax,1
	jnc no_xor4
	xor ax,cx
no_xor4:
	shl ax,1
	jnc no_xor5
	xor ax,cx
no_xor5:
	shl ax,1
	jnc no_xor6
	xor ax,cx
no_xor6:
	shl ax,1
	jnc no_xor7
	xor ax,cx
no_xor7:
    pop cx
    ret
CalcCrc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetAdapter
;
;		DESCRIPTION:
;
;		PARAMETERS:     ESI     Adress to start search at
;
;       RETURNS:        ESI     Adapter base
;                       ECX     Size of adapter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAdapter  Proc near
	push ds
	mov ax,flat_sel
	mov ds,ax
GetAdapterSearch:
	mov eax,[esi]
	cmp eax,RdosSign
	je GetAdapterFound
GetAdapterNext:
	add esi,1000h
	or esi,esi
	jne GetAdapterSearch
	stc
	jmp GetAdapterDone
GetAdapterCorrupt:
	pop esi
	jmp GetAdapterNext
GetAdapterFound:
	push esi
	xor ecx,ecx
GetAdapterNextDriver:
	cmp [esi].sign,RdosSign
	jne GetAdapterCorrupt
;
	cmp [esi].typ,RdosEnd
	je GetAdapterOk
	mov edx,[esi].len
	add ecx,edx
	cmp ecx,1000000h
	jnc GetAdapterCorrupt
;
	xor ax,ax
	push ecx
	push esi
	mov ecx,edx
	add esi,SIZE rdos_header
	sub ecx,SIZE rdos_header
	jz GetAdapterCrcDone
GetAdapterCrcLoop:
	call CalcCrc
	sub ecx,1
	jnz GetAdapterCrcLoop
GetAdapterCrcDone:
	pop esi
	pop ecx
	cmp ax,[esi].crc
	jne GetAdapterCorrupt
;
	add esi,edx
	jmp GetAdapterNextDriver
GetAdapterOk:
	pop esi
	clc
GetAdapterDone:
	pop ds
	ret
GetAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AdapterCrc
;
;		DESCRIPTION:
;
;		PARAMETERS:     ESI     Adapter base
;                       ECX     Size of adapter
;
;		RETURNS:		AX		Adapter CRC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdapterCrc  Proc near
	push ds
	mov ax,flat_sel
	mov ds,ax
	xor ax,ax
	push ecx
	push esi
AdapterCrcLoop:
	call CalcCrc
	sub ecx,1
	jnz AdapterCrcLoop
	pop esi
	pop ecx
	pop ds
	ret
AdapterCrc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddAdapter
;
;		DESCRIPTION:
;
;		PARAMETERS:     ESI     Adapter base
;						ECX     Size of adapter
;                       AX		Adapter CRC
;						BX		Current Adapter record
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddAdapter	Proc near
	push dx
	push di
	add ecx,SIZE rdos_header
	mov di,OFFSET rom_adapters
	mov dx,ds:rom_modules
AddAdapterCheck:
	or dx,dx
	jz AddAdapterDo
	cmp ecx,[di].adapter_size
	jne AddAdapterCheckNext
	cmp ax,[di].adapter_crc
	je AddAdapterEnd
AddAdapterCheckNext:
	dec dx
	add di,SIZE adapter_typ
	jmp AddAdapterCheck
AddAdapterDo:
    inc ds:rom_modules
    mov [bx].adapter_base,esi
    mov [bx].adapter_size,ecx
    mov [bx].adapter_crc,ax
    add bx,SIZE adapter_typ
AddAdapterEnd:
	pop di
	pop dx
	ret
AddAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetAllAdapters
;
;		DESCRIPTION:	Get all adapters
;
;		PARAMETERS:     ESI     Adress to start search at
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllAdapters  Proc near
    mov ax,system_data_sel
    mov ds,ax
    mov ds:rom_modules,0
    mov bx,OFFSET rom_adapters
	mov esi,PROM_BASE
get_adapters_loop:
    call GetAdapter
    jc get_adapters_done
	call AdapterCrc
	call AddAdapter
    add esi,ecx
    dec esi
    and si,0F000h
    add esi,1000h
    jmp get_adapters_loop
get_adapters_done:
    ret
GetAllAdapters  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartShutdownDevice
;
;		DESCRIPTION:	Starts shutdown-device
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartShutDownDevice	Proc near
    mov ax,system_data_sel
    mov ds,ax
	mov ax,flat_sel
	mov es,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
	or cx,cx
	jz StartShutDeviceEnd
StartShutAdapterLoop:
	push bx
	push cx
	mov esi,[bx].adapter_base
StartShutDeviceLoop:
	cmp es:[esi].typ,RdosShutDown
	je StartShutDeviceDo
	cmp es:[esi].typ,RdosEnd
	je StartShutNextAdapter
	add esi,es:[esi].len
	jmp StartShutDeviceLoop
StartShutNextAdapter:
	pop cx
	pop bx
	add bx,SIZE adapter_typ
	loop StartShutAdapterLoop
	jmp StartShutDeviceEnd
StartShutDeviceDo:
	pop cx
	pop bx
;
	push ds
	push es
	pushad
	push cs
	push OFFSET StartShutDeviceInitied
	mov ax,flat_sel
	mov ds,ax
	mov bx,shutdown_code_sel
	push bx
	mov ecx,[esi].len
	add esi,SIZE rdos_header
	push word ptr [esi].init_ip
	add esi,SIZE device_header
	mov ax,gdt_sel
	mov ds,ax
	dec cx
	mov [bx],cx
	mov [bx+2],esi
	mov ah,9Ah
	xchg ah,[bx+5]
	xor al,al
	mov [bx+6],ax
	retf
StartShutDeviceInitied:
	mov ax,gdt_sel
	mov ds,ax
	mov bx,idt_sel
	mov eax,[bx+2]
	sub eax,OFFSET rom_idt
	add eax,OFFSET boot_idt
	mov [bx+2],eax
	mov al,[bx+7]
	xchg al,[bx+5]
	db 66h
	lidt [bx]
	xchg al,[bx+5]
	popad
	pop es
	pop ds
;
StartShutDeviceEnd:	
	ret
StartShutDownDevice	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetBootDevice
;
;		DESCRIPTION:	Get header of boot-device
;
;		RETURNS:		NC
;						ESI			Boot device base
;						CY			No boot device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBootDevice	Proc near
    mov ax,system_data_sel
    mov ds,ax
	mov ax,flat_sel
	mov es,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
	or cx,cx
	jz GetBootDeviceFail
GetBootAdapterLoop:
	push bx
	push cx
	mov esi,[bx].adapter_base
GetBootDeviceLoop:
	cmp es:[esi].typ,RdosKernel
	je GetBootDeviceOk
	cmp es:[esi].typ,RdosEnd
	je GetBootNextAdapter
	add esi,es:[esi].len
	jmp GetBootDeviceLoop
GetBootNextAdapter:
	pop cx
	pop bx
	add bx,SIZE adapter_typ
	loop GetBootAdapterLoop
	jmp GetBootDeviceFail
GetBootDeviceOk:
	pop cx
	pop bx
	clc
	jmp GetBootDeviceEnd
GetBootDeviceFail:	
	stc
GetBootDeviceEnd:
	ret
GetBootDevice	Endp

DefaultInt:
	hlt

rom_gdt:
gdt0:
	dw 0
	dd 0
	dw 0
gdt8:
	dw 10h*8-1
	dd 92FFF000h + OFFSET rom_idt
	dw 0FF00h
gdt10:
	dw 28h-1
	dd 92FFF000h + OFFSET rom_gdt
	dw 0FF00h
gdt18:
	dw 0FFFFh
	dd 9AFFF000h
	dw 0FF00h
gdt20:
	dw 0FFFFh
	dd 92000000h
	dw 8Fh

rom_idt:
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry
	DefaultIdtEntry

Boot0:
	BootExceptionNoPar 0

Boot1:
	BootExceptionNoPar 1

Boot2:
	BootExceptionNoPar 2

Boot3:
	BootExceptionNoPar 3

Boot4:
	BootExceptionNoPar 4

Boot5:
	BootExceptionNoPar 5

Boot6:
	BootExceptionNoPar 6

Boot7:
	BootExceptionNoPar 7

Boot8:
	BootExceptionNoPar 8

Boot9:
	BootExceptionNoPar 9

BootA:
	BootExceptionNoPar 0Ah

BootB:
	BootExceptionOnePar 0Bh

BootC:
	BootExceptionOnePar 0Ch

BootD:
	BootExceptionOnePar 0Dh

BootE:
	BootExceptionNoPar 0Eh

BootF:
	BootExceptionNoPar 0Fh

boot_idt:
	BootIdtEntry Boot0
	BootIdtEntry Boot1
	BootIdtEntry Boot2
	BootIdtEntry Boot3
	BootIdtEntry Boot4
	BootIdtEntry Boot5
	BootIdtEntry Boot6
	BootIdtEntry Boot7
	BootIdtEntry Boot8
	BootIdtEntry Boot9
	BootIdtEntry BootA
	BootIdtEntry BootB
	BootIdtEntry BootC
	BootIdtEntry BootD
	BootIdtEntry BootE
	BootIdtEntry BootF

idt_reg:
	dw 10h*8-1
	dd 0FFFFF000h + OFFSET rom_idt

gdt_reg:
	dw 28h-1
	dd 0FFFFF000h + OFFSET rom_gdt

init:
	cli
	db 66h
	lgdt cs:fword ptr gdt_reg + 0F000h
	db 66h
    lidt cs:fword ptr idt_reg + 0F000h
	xor ax,ax
	lahf
	mov ebx,cr0
	or bl,1
	mov cr0,ebx
	db 0EAh
	dw OFFSET prot_init
	dw device_code_sel

prot_init:
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
;
    xor esi,esi
    FindRam
    mov edx,esi
    mov edi,esi
    xor esi,esi
    mov ax,gdt_sel
    mov ds,ax
    mov ecx,2*5
    rep movs dword ptr es:[edi],[esi]
    mov ax,flat_sel
    mov ds,ax
    mov esi,edx
    mov ebx,gdt_sel
    add ebx,esi
    mov word ptr [ebx],0FFFh
    mov [ebx+2],esi
    mov byte ptr [ebx+5],92h
    mov word ptr [ebx+6],0
    lgdt [esi+gdt_sel]
;
    FindRam
    mov ax,gdt_sel
    mov ds,ax
    mov bx,system_data_sel
    mov word ptr [bx],0FFFh
    mov [bx+2],esi
    mov byte ptr [bx+5],92h
    mov word ptr [bx+6],0
;
    mov ax,system_data_sel
    mov ds,ax
    mov ds:alloc_base,esi
;
    mov ax,gdt_sel
    mov ss,ax
    mov sp,1000h
;
    call GetAllAdapters
	call StartShutDownDevice
	call GetBootDevice
	jnc DoBoot
	hlt
DoBoot:
	mov ax,system_data_sel
	mov ds,ax
	mov ds:ram1_size,DRAM_SIZE
	mov ds:ram2_size,0
	mov ds:rom1_base,PROM_BASE
	mov ds:rom1_size,-PROM_BASE
	mov ds:rom2_size,0
	mov ds:rom_shadow,1
;
	mov ax,flat_sel
	mov ds,ax
	push kernel_code
	mov ecx,[esi].len
	add esi,SIZE rdos_header
	push [esi].init_ip
	add esi,SIZE device_header
	mov ax,gdt_sel
	mov ds,ax
	dec cx
	mov bx,kernel_code
	mov [bx],cx
	mov [bx+2],esi
	mov ah,9Ah
	xchg ah,[bx+5]
	xor al,al
	mov [bx+6],ax
	retf

	END init
