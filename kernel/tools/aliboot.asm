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
; ALIBOOT.ASM
; Bootloader for Ali6117 based cards
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  aliboot

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

GateSize = 16

INCLUDE \rdos\os\system.def
INCLUDE \rdos\os\protseg.def
INCLUDE \rdos\os\system.inc

PROM_BASE		EQU 00FE0000h

OpenAli	MACRO
	mov al,13h
	out 22h,al
	jmp short $+2
	mov al,0C5h
	out 23h,al
	jmp short $+2
		ENDM

CloseAli	MACRO
	mov al,13h
	out 22h,al
	jmp short $+2
	mov al,0
	out 23h,al
	jmp short $+2
		ENDM

; al data
; ah index

WriteAli	MACRO
	xchg ah,al
	out 22h,al
	jmp short $+2
	xchg ah,al
	out 23h,al
	jmp short $+2
			ENDM

; al data
; ah index

ReadAli		MACRO
	mov al,ah
	out 22h, al
	jmp short $+2
	in al,23h
			ENDM


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
    cmp esi,0A0000h
    jc RamLoop
	stc
RamFound:
            ENDM

.code
.386p

	org 0F000h

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
;
	call AdapterCrc
	call AddAdapter
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:	Init (power-up)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DefaultInt:
	hlt

rom_gdt:
gdt0:
	dw 0
	dd 0
	dw 0
gdt8:
	dw 10h*8-1
	dd 92FF0000h + OFFSET rom_idt
	dw 00000h
gdt10:
	dw 28h-1
	dd 92FF0000h + OFFSET rom_gdt
	dw 00000h
gdt18:
	dw 0FFFFh
	dd 9AFF0000h
	dw 00000h
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
	dd 00FF0000h + OFFSET rom_idt

gdt_reg:
	dw 28h-1
	dd 00FF0000h + OFFSET rom_gdt

; memory mode total
; type pattern memory Type

MemConfigTab:
	dw 0011h, 0000h, 0001h ; 0
	dw 1111h, 0010h, 0002h ; 1
	dw 0311h, 0020h, 0003h ; 2
	dw 3311h, 0030h, 0005h ; 3
	dw 0511h, 0040h, 0009h ; 4
	dw 0002h, 0050h, 0001h ; 5
	dw 0022h, 0060h, 0002h ; 6
	dw 0322h, 0070h, 0004h ; 7
	dw 3322h, 0080h, 0006h ; 8
	dw 0522h, 0090h, 000ah ; 9	
	dw 5522h, 00a0h, 0012h ; 10
	dw 0032h, 00b0h, 0003h ; 11
	dw 0332h, 00c0h, 0005h ; 12
	dw 0052h, 00d0h, 0009h ; 13
	dw 0003h, 00e0h, 0002h ; 14
	dw 0033h, 00f0h, 0004h ; 15
	dw 0333h, 0008h, 0006h ; 16
	dw 3333h, 0018h, 0008h ; 17	
	dw 0533h, 0028h, 000ch ; 18
	dw 5533h, 0038h, 0014h ; 19
	dw 0053h, 0048h, 000ah ; 20
	dw 0553h, 0058h, 0012h ; 21
	dw 5553h, 0068h, 001ah ; 22
	dw 0004h, 0078h, 0004h ; 23
	dw 0044h, 0088h, 0008h ; 24
	dw 5544h, 0098h, 0018h ; 25
	dw 0054h, 00a8h, 000ch ; 26
	dw 0005h, 00b8h, 0008h ; 27	
	dw 0055h, 00c8h, 0010h ; 28
	dw 0555h, 00d8h, 0018h ; 29
	dw 5555h, 00e8h, 0020h ; 30
	dw 0066h, 00f8h, 0040h ; 31

init:
	cli
	db 66h
	lgdt fword ptr cs:gdt_reg
;
	db 66h
    lidt fword ptr cs:idt_reg
;
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
	OpenAli

wait_gate1:
	in al,64h
	and al,2
	jnz wait_gate1
;
	mov al,0D1h
	out 64h,al

wait_gate2:
	in al,64h
	and al,2
	jnz wait_gate2
;
	mov al,0DFh
	out 60h,al

wait_gate3:
	in al,64h
	and al,2
	jnz wait_gate3
;
	xor cx,cx

gate_wait:
	inc ax
	loop gate_wait
;
	mov ah,10h
	ReadAli
	and al,00000111b
	or al,01010000b
	WriteAli
;
	mov ah,3Ch
	ReadAli
	or al,00000010b
	WriteAli
	and al, 11111101b
;
	mov word ptr ds:[0h], 0aaaah
	mov word ptr ds:[1000h], 05555h ; dummy write
	cmp word ptr ds:[0h], 0aaaah
	je Is_EDO_type_DRAM

Is_Fast_Page_Mode_Type_DRAM:
	WriteAli
	jmp Finish_DRAM_Type_Detection

Is_EDO_Type_DRAM:
	WriteAli
;
	mov ah,37h
	ReadAli
	or al,00000001b
	WriteAli

Finish_DRAM_Type_Detection:
	mov ah,10h
	ReadAli
	and al,00000111b
	or al,11101000b
	WriteAli
	xor dx,dx ; store DRAM mode
	mov esi,3000h ; A13, A12 enable - bank 3

sizing_bank_23:
	mov edi,800h ; A11
	and dl,0f0h
	or dl,5 ; 5 --- 4M
	mov word ptr ds:[esi+edi], 0aa99h
	mov word ptr ds:[esi], 099aah ; dummy write
	cmp word ptr ds:[esi+edi], 0aa99h
	jz sizing_bank_23_end ; 4M, go to test next bank
;
	mov edi,400h ; A10
	and dl,0f0h
	or dl,3 ; 3 --- 1M
	mov word ptr ds:[esi+edi], 0bb88h
	mov word ptr ds:[esi], 088bbh ; dummy write
	cmp word ptr ds:[esi+edi], 0bb88h
	jz sizing_bank_23_end ; 1M, go to test next bank
;
	mov edi,2h ; A1
	and dl,0f0h
	or dl,1 ; 1 --- 256K
	mov word ptr ds:[esi+edi], 0cc77h
	mov word ptr ds:[esi], 077cch ; dummy write
	cmp word ptr ds:[esi+edi], 0cc77h
	jz sizing_bank_23_end ; 256K, go to test next bank
;
	and dl,0f0h ; none in this bank

sizing_bank_23_end:
	cmp esi,2000h
	jz short sizing_bank_01_begin ; finish sizing bank 3 and 2
;
	sub esi,1000h
	shl dx,4
	jmp sizing_bank_23 ; go to sizing bank 2

sizing_bank_01_begin:
	mov ah,10h
	ReadAli
	and al,00000111b
	or al,11111000b
	WriteAli

sizing_bank_01:
	shl dx,4 ; next bank
	mov edi,1000h ; A12
	and dl,0f0h
	or dl,6 ; 6 --- 16M
	mov word ptr ds:[esi+edi], 0dd66h
	mov word ptr ds:[esi], 066ddh ; dummy write
	cmp word ptr ds:[esi+edi], 0dd66h
	jz sizing_bank_01_end ; 16M, go to test next bank
;
	mov edi,800h ; A11
	and dl,0f0h
	or dl,5 ; 5 --- 4M
	mov word ptr ds:[esi+edi], 0ee55h
	mov word ptr ds:[esi], 055eeh ; dummy write
	cmp word ptr ds:[esi+edi], 0ee55h
	jz sizing_bank_01_end ; 4M, go to test next bank
;
	mov edi,400h ; A10
	and dl,0f0h
	or dl,3 ; 3 --- 1M
	mov word ptr ds:[esi+edi], 0ff44h
	mov word ptr ds:[esi], 044ffh ; dummy write
	cmp word ptr ds:[esi+edi], 0ff44h
	jz short is_1or2M ; 1 or 2M, go to is_1or2M to check
;
	mov edi,2 ; A1
	and dl,0f0h
	or dl,1 ; 1 --- 256K
	mov word ptr ds:[esi+edi], 012abh
	mov word ptr ds:[esi], 0ab12h ; dummy write
	cmp word ptr ds:[esi+edi], 012abh
	jz short is_2or5K ; 256 or 512K, go to is_2or5K to check
;
	and dl,0f0h ; none in this bank
	jmp short sizing_bank_01_end

is_1or2M:
	mov edi,1000000h ; A24
	mov word ptr ds:[esi+edi],034cdh
	mov word ptr ds:[esi],0ed34h ; dummy write
	cmp word ptr ds:[esi+edi],034cdh
	jnz short sizing_bank_01_end ; 1M
;
	and dl,0f0h
	or dl,4 ; 2M
	jmp short sizing_bank_01_end

is_2or5K:
	mov edi,100000 ; A20
	mov word ptr ds:[esi+edi], 056efh
	mov word ptr ds:[esi], 0ef56h ; dummy write
	cmp word ptr ds:[esi+edi], 056efh
	jnz short sizing_bank_01_end ; 256K
;
	and dl,0f0h
	or dl,2 ; 512K

sizing_bank_01_end:
	or esi,esi
	jz short sizing_memory_end
;
	xor esi,esi ; bank 0
	jmp sizing_bank_01

sizing_memory_end:
	mov si,OFFSET MemConfigTab
	mov cx,32

check_mode:
	mov ax,cs:[si]
	cmp dx,ax
	jz short check_mode_end
;
	add si,6
	loop check_mode

check_mode_end:
	mov bx,cs:[si+2]
	mov ah,10h
	ReadAli
	and al,00000111b
	or al, bl
	WriteAli
;
	movzx ebp,byte ptr cs:[si+4]
	shl ebp,20
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
	mov ds:ram1_size,0A0000h
	mov ds:ram2_base,100000h
	sub ebp,100000h
	mov ds:ram2_size,ebp
	mov ds:rom1_base,PROM_BASE
	mov ds:rom1_size,1F000h
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
