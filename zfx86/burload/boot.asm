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
; BOOT.ASM
; Second stage boot-loader for DOS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  boot

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\port.def
INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.inc

StartSound    Macro
    mov al,0B4h
    out 43h,al
    jmp short $+2
    mov al,10h
    out 42h,al
    jmp short $+2
    out 42h,al
    jmp short $+2
    mov al,3
    out 61h,al
                Endm    

StopSound   Macro
    mov al,0
    out 61h,al
            Endm

WriteZflByte    Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov al,data
    inc dx
    out dx,al
                Endm

ReadZflByte Macro index
    mov al,index
    mov dx,218h
    out dx,al
    inc dx
    in al,dx
            Endm

WriteZflWord    Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov ax,data
    mov dx,21Ah
    out dx,ax
                Endm

ReadZflWord Macro index
    mov al,index
    mov dx,218h
    out dx,al
    mov dx,21Ah
    in ax,dx
            Endm

WriteZflDword   Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov eax,data
    mov dx,21Ah
    out dx,eax
                Endm

ReadZflDword    Macro index
    mov al,index
    mov dx,218h
    out dx,al
    mov dx,21Ah
    in eax,dx
                Endm  
                  
WriteCCR    Macro index, data
    mov al,index
    out 22h,al
    mov al,data
    out 23h,al
            Endm

ReadCCR     Macro index
    mov al,index
    out 22h,al
    in al,23h
            Endm

WriteNB Macro index, data
    mov ax,index
    out 24h,ax
    mov ax,data
    out 26h,ax
        Endm

ReadNB  Macro index
    mov ax,index
    out 24h,ax
    in ax,26h
        ENDM

WriteSIO    Macro index, data
    mov al,index
    out 2Eh,al
    mov al,data
    out 2Fh,al
        ENDM

ReadSIO    Macro index
    mov al,index
    out 2Eh,al
    in al,2Fh
        ENDM

ReadPciDword Macro bus, device, function, index
    mov eax,80000000h OR (bus SHL 16) OR (device SHL 11) OR (function SHL 8) OR (index AND 0FFFCh)
	mov dx,0CF8h
	out dx,eax
	mov dx,0CFCh
	in eax,dx
        ENDM


WritePciDword Macro bus, device, function, index, data
    mov eax,80000000h OR (bus SHL 16) OR (device SHL 11) OR (function SHL 8) OR (index AND 0FFFCh)
	mov dx,0CF8h
	out dx,eax
    mov eax,data
	mov dx,0CFCh
    out dx,eax
	    ENDM

DefaultIdtEntry		MACRO
	dw OFFSET DefaultInt
	dw 8
	dw 8E00h
	dw 0
					ENDM

BootIdtEntry		MACRO Offs
	dw OFFSET Offs
	dw 8
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

RamNext:
    add esi,1000h
    
RamLoop:
    mov eax,AllocMemSign
    mov [esi],eax
    cmp eax,[esi]
    jne RamNext
            ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetupSerial
;
;		DESCRIPTION:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSerial    MACRO
    WriteSIO 7, 3
    WriteSIO 30h, 1
    WriteSIO 60h, 3
    WriteSIO 61h, 0F8h
;
;    WriteZflWord 18h, 3F8h
;    WriteZflByte 1Ah, 17h
;
	mov al,83h
	mov dx,3F8h + 3
	out dx,al				; set line control to divisor access
;
	mov dx,3F8h
	mov al,1
	out dx,al				; output LSB divisor latch
;
	mov dx,3F8h + 1
	mov al,0
	out dx,al				; output MSB divisor latch
;
    mov dx,3F8h + 2
    mov al,1
    out dx,al               ; enable FIFOs if present
;
	mov al,3
	mov dx,3F8h + 3
	out dx,al				; set line control 
;
	mov dx,3F8h + 1
	mov al,0
	out dx,al				; disable rx ints, disable tx, line and modem ints
;
	mov dx,3F8h + 4
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
        ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendChar
;
;		DESCRIPTION:    Send a single char
;
;       PARAMETERS:     AL      char to send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendChar    Macro
    local WaitLoop

    mov ah,al
    
WaitLoop:
    mov dx,3F8h+5
    in al,dx
    test al,40h
    jz WaitLoop
;
    mov dx,3F8h
    mov al,ah
    out dx,al
            Endm

.code

.386p

code_base	DD ?
code_size	DD ?

NoBootText DB 'No kernel to boot up',0

KernelLowError	DB 'Low Kernel Overwrite',0
KernelMidError	DB 'Mid Kernel Overwrite',0
KernelHighError	DB 'High Kernel Overwrite',0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitSerial
;
;		DESCRIPTION:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitSerial	Proc near
    push ax
    push dx
    SetupSerial
    pop dx
    pop ax
    ret
InitSerial   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteChar
;
;		DESCRIPTION:
;
;		PARAMETERS:		AL		CHAR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteChar	Proc near
    push ax
    push dx
    SendChar
    pop dx
    pop ax
    ret
WriteChar   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCRLF
;
;		DESCRIPTION:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCRLF	Proc near
    push ax
    push dx
    mov al,0Dh
    SendChar
    mov al,0Ah
    SendChar
    pop dx
    pop ax
    ret
WriteCRLF   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SingleHex
;
;		DESCRIPTION:
;
;		PARAMETERS:		AL		Value in
;						AX		Value out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SingleHex	Proc near
	mov ah,al
	and al,0F0h
	rol al,4
	cmp al,0Ah
	jb ok_low1
	add al,7
ok_low1:
	add al,30h
	and ah,0Fh
	cmp ah,0Ah
	jb ok_high1
	add ah,7
ok_high1:
	add ah,30h
	ret
SingleHex   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexByte
;
;		DESCRIPTION:
;
;		PARAMETERS:		AL		HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte    Proc near
    push ax
	call SingleHex
	call WriteChar
	xchg al,ah
    call WriteChar
    pop ax
    ret
WriteHexByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexWord
;
;		DESCRIPTION:
;
;		PARAMETERS:		AX		HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord	Proc near
    xchg al,ah
    call WriteHexByte
    xchg al,ah
    call WriteHexByte
    ret
WriteHexWord    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexDword
;
;		DESCRIPTION:
;
;		PARAMETERS:		EAX		HEX DATA IN
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword	Proc near
    push eax
    shr eax,16
    call WriteHexWord
    pop eax
    call WriteHexWord
    ret
WriteHexDword   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteRomString
;
;		DESCRIPTION:
;
;		PARAMETERS:     SI      OFFSET TO STRING
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRomString	Proc near

WriteRomStringLoop:
    mov al,cs:[si]
    or al,al
    jz WriteRomStringDone
    call WriteChar
    inc si
    jmp WriteRomStringLoop
WriteRomStringDone:
    ret
WriteRomString  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CalcCrc
;
;		DESCRIPTION:	Calculate CRC for a byte
;
;       PARAMETERS:     AL      CRC
;                       DS:ESI  Data
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
;						EDI		Max address to search at
;
;       RETURNS:        ESI     Adapter base
;                       ECX     Size of adapter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignError	DB 'Rdos Signature Not Found ',0
SizeError	DB 'To Large Adapter ',0

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
	cmp esi,edi
	jb GetAdapterSearch
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
	je GetAdapterSignOk
;
    call InitSerial
   	mov si,OFFSET SignError
    call WriteRomString
	jmp GetAdapterCorrupt
	
GetAdapterSignOk:
	cmp [esi].typ,RdosEnd
	je GetAdapterOk
	mov edx,[esi].len
	add ecx,edx
	cmp ecx,1000000h
	jc GetAdapterSizeOk
;
    call InitSerial
	mov si,OFFSET SizeError
    call WriteRomString
	jmp GetAdapterCorrupt
	
GetAdapterSizeOk:
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
	je GetAdapterCrcOk
	jmp GetAdapterCorrupt
GetAdapterCrcOk:
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
;		DESCRIPTION:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAllAdapters  Proc near
    mov ax,system_data_sel
    mov ds,ax
	mov esi,ds:rom1_base
	mov edi,ds:rom1_size
	add edi,esi
    mov ds:rom_modules,0
    mov bx,OFFSET rom_adapters
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
	lidt [bx]
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

rom_gdt:
gdt0:
	dw 0
	dd 0
	dw 0
gdt8:
	dw 10h*8-1
	dd 920F0000h + OFFSET rom_idt
	dw 0
gdt10:
	dw 28h-1
	dd 920F0000h + OFFSET rom_gdt
	dw 0
gdt18:
	dw 0FFFFh
	dd 9A0F0000h
	dw 0
gdt20:
	dw 0FFFFh
	dd 92000000h
	dw 8Fh

rom_idt:
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


init:
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
	mov ds:ram1_size,0A0000h
	mov ds:ram2_base,100000h
	mov eax,cs:code_base
	mov ds:rom1_base,eax
	sub eax,ds:ram2_base
	mov ds:ram2_size,eax
	mov eax,cs:code_size
	mov ds:rom1_size,eax
	mov ds:rom2_size,0
	mov ds:rom_shadow,0
;
    mov ax,gdt_sel
    mov ss,ax
    mov sp,1000h
;
    call GetAllAdapters
	call StartShutDownDevice
	call GetBootDevice
	jnc DoBoot
;
    call InitSerial
    mov si,OFFSET NoBootText
    call WriteRomString
DoStop:
	jmp DoStop
	
DoBoot:
	push esi
	mov ax,flat_sel
	mov ds,ax
	mov ax,gdt_sel
	mov es,ax
;
	mov ebx,0B8000h
	mov ax,720h
GetVideoLoop:
	mov [ebx],ax
	cmp ax,[ebx]
	je GetVideoSel
	mov ebx,0B0000h
GetVideoSel:
	mov si,dosB800
	mov word ptr es:[si],0FFFh
	mov es:[si+2],ebx
	mov byte ptr es:[si+5],92h
	mov word ptr es:[si+6],0

GetVideoDone:
	pop esi
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitRdos
;
;		DESCRIPTION:    Init RDOS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OkText DB 'Everything is OK',0

InitRdos:
    xor esi,esi
    FindRam
    mov edx,esi
    mov edi,esi
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET gdt_cs_sel
    add edi,device_code_sel
    mov ecx,2*2
    rep movs dword ptr es:[edi],[esi]
    mov ax,10h
    mov ds,ax
    mov esi,edx
    mov ebx,gdt_sel
    add ebx,esi
    mov word ptr [ebx],0FFFh
    mov [ebx+2],esi
    mov byte ptr [ebx+5],92h
    mov word ptr [ebx+6],0
    lgdt [esi+gdt_sel]
	db 0EAh
	dw OFFSET rdos_startup
	dw device_code_sel

rdos_startup:
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
    mov ax,gdt_sel
    mov ss,ax
    mov sp,1000h
;
	xor edi,edi
	ReadNB 20Fh
;
	mov bx,ax
	test bx,101h
	jz size_dram_bank0_done
;
	ReadNB 202h
	shr ax,9
	and al,7
	mov	cl,al
	mov eax,200000h
	shl eax,cl
	add edi,eax
	
size_dram_bank0_done:
	test bx,202h
	jz size_dram_bank1_done
;
	ReadNB 205h
	shr ax,9
	and al,7
	mov	cl,al
	mov eax,200000h
	shl eax,cl
	add edi,eax
	
size_dram_bank1_done:
	test bx,404h
	jz size_dram_bank2_done
;
	ReadNB 208h
	shr ax,9
	and al,7
	mov	cl,al
	mov eax,200000h
	shl eax,cl
	add edi,eax
	
size_dram_bank2_done:
	test bx,808h
	jz size_dram_bank3_done
;
	ReadNB 20Bh
	shr ax,9
	and al,7
	mov	cl,al
	mov eax,200000h
	shl eax,cl
	add edi,eax
	
size_dram_bank3_done:
	mov ds:ram1_size,edi
	mov ds:ram2_size,0
;
	WriteZflDword 2Ah, 0FFFFFFh
	WriteZflDword 26h, 0
;
	mov esi,0FFFFFFF0h
	mov eax,es:[esi]
	mov ebx,es:[esi+4]
	mov ecx,es:[esi+8]
	mov edx,es:[esi+12]
	mov edi,1000h

size_flash_loop:
	mov esi,0FFFFFFF0h
	sub esi,edi	
	cmp eax,es:[esi]
	jne size_flash_next
;
	cmp ebx,es:[esi+4]
	jne size_flash_next
;
	cmp ecx,es:[esi+8]
	jne size_flash_next
;
	cmp edx,es:[esi+12]
	je size_flash_found

size_flash_next:
	shl edi,1
	cmp edi,1000000h
	jne size_flash_loop	

size_flash_found:
	mov esi,1000000h
	sub esi,edi
	dec edi
;
; cannot do this yet!!
; 
;	WriteZflDword 26h, esi
;	WriteZflDword 2Ah, edi 
;
	inc edi
	or esi,0FF000000h
	mov eax,dword ptr cs:adapter_start
	mov ds:rom1_base,eax
	neg eax
	mov ds:rom1_size,eax
;
	mov ds:rom2_size,0
	mov ds:rom_shadow,1
;
    call InitSerial
    mov al,'A'
    call WriteChar
    call GetAllAdapters
    mov al,'B'
    call WriteChar
	call StartShutDownDevice
    mov al,'C'
    call WriteChar
	call GetBootDevice
    mov al,'D'
    call WriteChar
;
    mov ax,1234h
    mov ds,ax

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FatalError
;
;		DESCRIPTION:	Fatal error dump to COM1
;
;       PARAMETERS:     DI      Offset of error text in code segment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FatalError:
    SetupSerial

fatal_char_loop:
    mov al,cs:[di]
    or al,al
    jz fatal_stop_loop
;
    SendChar
    inc di
    jmp fatal_char_loop

fatal_stop_loop:
	jmp fatal_stop_loop	

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitSdram
;
;		DESCRIPTION:    Detect & init SDRAM
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveAx  Macro
    mov bp,ax
    shl eax,16
    mov ax,bp
        Endm

SaveBx  Macro
    mov bp,bx
    shl ebx,16
    mov bx,bp
        Endm

SaveCx  Macro
    mov bp,cx
    shl ecx,16
    mov cx,bp
        Endm

SaveDx  Macro
    mov bp,dx
    shl edx,16
    mov dx,bp
        Endm

RestoreAx   Macro
    shr eax,16
        Endm

RestoreBx   Macro
    shr ebx,16
        Endm

RestoreCx   Macro
    shr ecx,16
        Endm

RestoreDx   Macro
    shr edx,16
        Endm

dram_failed     DB 'SDRAM not found',0 
        
InitDram:
    WriteNB 4, 2
    WriteNB 239h, 1249h
    WriteNB 11Ch, 0000h
;
    ReadNB 11Ah
    mov bx,ax
    or bx,7
    WriteNB 11Ah, bx
;
    xor bx,bx
    mov cx,4

check_bank_loop:
    ReadNB 119h
    mov di,ax
    and di,0FFEh
    WriteNB 119h, di
;
    WriteNB 20Fh, 0000h
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    mov bx,80h
    shl bx,cl
;
    ReadNB 20Fh
    or bx,ax
    WriteNB 20Fh, bx
;
    WriteNB 214h, 0000h
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;    
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx
    WriteNB dx, 0000h
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    dec cx
    mov ax,3
    mul cx
;
    xchg ax,bx
    add bx,204h
    WriteNB bx, 0FC71h        
;
    mov bx,cx
    shl bx,1
    or bx,221h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,229h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,221h
;
    mov cx,8

check_mode_loop:
    and bx,0FFE7h
    WriteNB 213h, bx
;
    or bx,18h
    WriteNB 213h, bx
    loop check_mode_loop
;
    and bx,6
    or bx,231h    
    WriteNB 213h, bx
;
    and bx,6
    or bx,220h
    WriteNB 213h, bx
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;    
    mov esi,00800000h    
    mov dword ptr [esi],5A5A5A5Ah
    mov dword ptr [esi+100h],0
    mov eax,[esi]
    cmp eax,5A5A5A5Ah
    jz init_dram_cont
;
    WriteNB 20Fh, 0
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    mov bx,8000h
    rol bx,cl
    ReadNB 20Fh
    or bx,ax
    WriteNB 20Fh, bx
;
    WriteNB 214h, 1
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx
;    
    WriteNB dx, 0008
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    dec cx
    mov ax,3
    mul cx
    xchg ax,bx
    add bx,204h
    WriteNB bx, 0FC71h
;
    mov bx,cx
    shl bx,1
    or bx,221h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,229h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,221h
;
    mov cx,8

l3bd:
    and bx,0FFE7h
    WriteNB 213h, bx
;
    or bx,18h
    WriteNB 213h, bx
    loop l3bd 
;
    and bx,6
    or bx,231h
    WriteNB 213h, bx
;
    and bx,6
    or bx,220h
    WriteNB 213h, bx
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;
    mov esi,00800000h    
    mov dword ptr [esi],5A5A5A5Ah
    mov dword ptr [esi+100h],0
    mov eax,[esi]
    cmp eax,5A5A5A5Ah
    jz init_dram_cont
;
    dec cx
    jnz check_bank_loop       
;   
    jmp check_bank_done

init_dram_cont:
    ReadNB 119h
    or ax,1
    mov di,ax
    WriteNB 119h, di
;
    ReadNB 20Fh
    or bx,ax
;
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx
;
    ReadNB dx
    or ax,2A00h
    mov di,ax
;
    mov esi,4
        
check_bank_col_loop:
    WriteNB dx, di

check_bank_mem_loop:
    mov ebp,00800000h    
    mov dword ptr ds:[ebp],1A56E2C6h
    mov dword ptr ds:[esi+ebp],5A5A5A5Ah
    mov eax,ds:[ebp]
    cmp eax,1A56E2C6h
    jnz check_bank_first_failed
;
    mov eax,ds:[esi+ebp]
    cmp eax,5A5A5A5Ah
    jnz check_bank_next
;
    shl esi,1
    cmp esi,ebp
    jnz check_bank_mem_loop
;
    shr esi,1
    jmp check_bank_next

check_bank_first_failed:
    mov eax,esi
    cmp eax,1000000h
    ja check_bank_next
;
    shl eax,1    
    test bx,0FFh
    jz check_bank_col_ok
;
    shl eax,1

check_bank_col_ok:
    and ax,3000h
    and di,0CFFFh
    or di,ax
    mov esi,4
    jmp check_bank_col_loop

check_bank_next:
    shr esi,17
    bsf eax,esi
    dec ax
    shl ax,9
    and di,0F1FFh
    or di,ax
;
    WriteNB 20Fh, 0
;
    and si,0FFh
    or di,si
    WriteNB dx, di
;
    dec cl
    jnz check_bank_loop

check_bank_done:
    ReadNB 119h
    or ax,1
    mov di,ax
    WriteNB 119h, di
;
    WriteNB 20Fh, 0000h
;
    mov cx,1
    mov di,1
    xor dx,dx
    mov bp,dx
    shl ebp,16

setup_bank_loop:
    mov ch,cl
    test bx,cx
    jz l622
;
    xchg cx,di
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx 
    xchg cx,di
    ReadNB dx
;           
    mov si,ax
    and si,000FFh
    and ax,0FF00h
    shr ebp,16
    mov dx,bp
    shl ebp,16
    add ax,dx
    add dx,si
    mov bp,dx
    shl ebp,16
    mov si,ax
;
    xchg cx,di
    SaveAx
    SaveCx
    xor ch,ch
    dec cl
    mov ax,3
    mul cx
    xchg ax,dx
    add dx,202h
    RestoreAx
    RestoreCx
    xchg cx,di
    WriteNB dx, si

l622:
    cmp di,4
    jz l62d
;
    shl cl,1
    inc di
    jmp setup_bank_loop

l62d:
    mov cx,1
    mov di,1

l633:
    test bl,cl
    jz l7b2
;
    xchg cx,di
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    mov bx,8000h
    rol bx,cl
;
    ReadNB 20Fh
    or bx,ax
    WriteNB 20Fh, bx
;
    WriteNB 214h, 0001h
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    dec cx
    mov ax,3
    mul cx
    xchg ax,bx
    add bx,204h
    WriteNB bx, 0FC71h
;
    mov bx,cx
    shl bx,1
    or bx,221h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,229h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,221h
;
    mov cx,8

l763:
    and bx,0FFE7h
    WriteNB 213h, bx
; 
    or bx,18h
    WriteNB 213h, bx
    loop l763
;
    and bx,6
    or bx,231h
    WriteNB 213h, bx
;
    and bx,6
    or bx,220h
    WriteNB 213h, bx
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
    xchg cx,di
    jmp l92e

l7b2:
    test cl,bh
    jz l92e
;
    xchg cx,di
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    mov bx,80h
    rol bx,cl
;
    ReadNB 20Fh
    or bx,ax
    WriteNB 20Fh, bx
;
    WriteNB 214h, 0000h
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
;
    SaveAx
    SaveBx
    SaveCx
    SaveDx
;
    dec cx
    mov ax,3
    mul cx
    xchg ax,bx
    add bx,204h
    WriteNB bx, 0FC71h
;
    mov bx,cx
    shl bx,1
    or bx,221h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,229h
    WriteNB 213h, bx
;
    mov bx,cx
    shl bx,1
    or bx,221h
;
    mov cx,8

l8e2:
    and bx,0FFE7h
    WriteNB 213h, bx
; 
    or bx,18h
    WriteNB 213h, bx
    loop l8e2
;
    and bx,6
    or bx,231h
    WriteNB 213h, bx
;
    and bx,6
    or bx,220h
    WriteNB 213h, bx
;
    RestoreAx
    RestoreBx
    RestoreCx
    RestoreDx
    xchg cx,di

l92e:
    cmp di,4
    jz l939
;
    shl cl,1
    inc di
    jmp l633

l939:
    SaveAx
    SaveCx
;
    WriteNB 211h, 0000h
;
    mov cx,-1
    
init_dram_delay:   
    loop init_dram_delay
;
    RestoreAx
    RestoreCx
;
    ReadNB 21Ah
    and ax,0FFF8h
    mov di,ax
    WriteNB 21Ah, di
;
    ReadNB 20Fh
    or al,al
    jz init_dram_failed
;
    xor esi,esi
    mov eax,2AFC478Ah
    mov [esi],eax
    cmp eax,[esi]
    je InitRdos
    
init_dram_failed:
    mov di,OFFSET dram_failed
    jmp FatalError

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			prot_init
;
;		DESCRIPTION:	Basic ZFX86 chip-set initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

prot_init:
	mov ax,10h
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
;
    WriteCCR 0C2h, 0E2h
;
    ReadCCR 0C3h
    or al,8
    mov ah,al
    WriteCCR 0C3h, ah
;     
    WriteNB 20Fh, 0
    WriteNB 11Bh, 210h
    WriteNB 11Dh, 3D0h
    WriteNB 110h, 0
    WriteNB 111h, 0
    WriteNB 112h, 0
    WriteNB 113h, 0
    WriteNB 114h, 0
    WriteNB 115h, 0
    WriteNB 117h, 0
    WriteNB 118h, 0
    WriteNB 119h, 6Bh
    WriteNB 11Ah, 220h
    WriteNB 11Eh, 0
    WriteNB 11Fh, 0
    WriteNB 120h, 0
    WriteNB 200h, 0
    WriteNB 201h, 0
    WriteNB 202h, 0
    WriteNB 204h, 0FFFFh
    WriteNB 205h, 0
    WriteNB 207h, 0FFFFh
    WriteNB 208h, 0
    WriteNB 20Ah, 0FFFFh
    WriteNB 20Bh, 0
    WriteNB 20Dh, 0FFFFh
    WriteNB 20Eh, 0
    WriteNB 20Fh, 0
    WriteNB 213h, 321h
    WriteNB 214h, 0    
;
    WritePciDword 0, 12h, 0, 4, 0280000Fh
;
    ReadPciDword 0, 12h, 0, 0Ch
    and ax,0FF00h
    mov edi,eax
    WritePciDword 0, 12h, 0, 4, edi
;
    ReadPciDword 0, 12h, 0, 40h
    and eax,0FF0000h
    or eax,02000019h
    mov edi,eax
    WritePciDword 0, 12h, 0, 40h, edi
;    
    WritePciDword 0, 12h, 0, 10h, 00008101h
    WritePciDword 0, 12h, 0, 50h, 029A557Bh
;
    ReadPciDword 0, 12h, 0, 58h
    and eax,0FFFFh
    or eax,28CF0000h
    mov edi,eax
    WritePciDword 0, 12h, 0, 58h, edi
;
    ReadPciDword 0, 12h, 0, 5Ch
    xor ax,ax
    mov edi,eax
    WritePciDword 0, 12h, 0, 5Ch, edi
;    
    ReadPciDword 0, 12h, 0, 80h
    mov al,1
    mov edi,eax
    WritePciDword 0, 12h, 0, 80h, edi
;    
    ReadPciDword 0, 12h, 1, 4
    xor al,al
    mov edi,eax
    WritePciDword 0, 12h, 1, 4, edi
;
    ReadPciDword 0, 12h, 2, 4
    mov al,5
    mov edi,eax
    WritePciDword 0, 12h, 2, 4, edi
;
    ReadPciDword 0, 12h, 3, 4
    mov al,3
    mov edi,eax
    WritePciDword 0, 12h, 3, 4, edi
;
    WritePciDword 0, 12h, 3, 40h, 0FFFFFFC1h
    WritePciDword 0, 12h, 3, 10h, 00008201h
;
    ReadPciDword 0, 13h, 0, 4
    mov al,7
    mov edi,eax
    WritePciDword 0, 13h, 0, 4, edi
;
    ReadPciDword 0, 13h, 0, 0Ch
    xor ax,ax
    mov edi,eax
    WritePciDword 0, 13h, 0, 0Ch, edi     
;
    WritePciDword 0, 12h, 0, 44h, 02FE0000h
;
    mov dx,8200h
    mov eax,05000000h
    out dx,eax
;
    mov dx,8204h
    mov eax,00000030h
    out dx,eax
;
    mov dx,8208h
    mov eax,00009200h
    out dx,eax
;
    WriteSIO 21h, 1
    WriteSIO 22h, 0
;
    WriteCCR 0C1h, 0
    jmp InitDram

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			startup
;
;		DESCRIPTION:	Boot-up code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; beyond this point offset-addresses must not be used!!

startup:
    mov bx,0FFD8h
	db 66h
	lgdt fword ptr cs:[bx]
;
	mov bx,0FFD0h
	db 66h
	lidt fword ptr cs:[bx]
;
	xor ax,ax
	mov ss,ax
;
	mov eax,cr0
	or al,1
	mov cr0,eax
	db 0EAh
	dw OFFSET prot_init
	dw 8

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DefaultInt
;
;		DESCRIPTION:	Boot-time exception handlers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExceptionText DB 'Exception Fault in Boot ',0

DefaultInt:
	mov di,OFFSET ExceptionText
	jmp FatalError


; this must always reside at FFFFFF50, and should always be 128 bytes long!!

boot_idt:
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

; this must always reside at FFFFFFD0, and should always be 32 bytes long!!

; boot idt address

	DW 7Fh
	DD 0FFFFFF50h
	DW 0

; null sel, and gdt base address

	DW 17h
	DD 0FFFFFFD8h
	DW 0

gdt_cs_sel:

    DW OFFSET boot_vect + 0Fh
    DW OFFSET boot_vect      ; must be patched to FFF0 - OFFSET boot_vect
    DW 9BFFh
    DW 0FF00h

; flat sel

	DW 0FFFFh
	DD 92000000h
	DW 008Fh

; this must reside at FFFFFFF0, and should always be 16 bytes long!!

boot_vect:
    jmp startup

    DB 'RDOS boot'

adapter_start:
	DD 0					; must be patched to start of adapters

	END boot_vect
