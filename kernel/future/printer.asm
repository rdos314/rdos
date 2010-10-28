;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
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
; PRINTER.ASM
; PC printer driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Delay
;
;		DESCRIPTION:	Wait for i/o port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Delay	Proc near
	jcxz short $+2
	jcxz short $+2
	ret
Delay	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitPulse
;
;		DESCRIPTION:	Wait until keyboard port is pulsed a number of times
;
;		PARAMETERS:     CX      Number of pulses to wait for (13.4 us)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitPulse   Proc near
    push ax
WaitPulseLow:
    in al,61h
    test al,10h
    jz WaitPulseLow
    dec cx
    jz WaitPulseDone
WaitPulseHigh:
    in al,61h
    test al,10h
    jnz WaitPulseHigh
    dec cx
    jnz WaitPulseLow
WaitPulseDone:
    pop ax
    ret
WaitPulse   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetPrinterPort
;
;		DESCRIPTION:	Get printer port
;
;		PARAMETERS:     DX      Printer #
;
;		RETURNS:		DX		Printer port or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_tab:
lpt1	DW 378h
lpt2	DW 0
lpt3	DW 0
lpt4	DW 0

GetPrinterPort	Proc near
	mov bx,dx
	shl bx,1
	mov dx,word ptr cs:[bx].port_tab
	ret
GetPrinterPort	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_PRINTER
;
;		DESCRIPTION:	Init printer
;
;		PARAMETERS:		DX		PRINTER #
;
;		RETURNS:		NC		SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_printer_name	DB 'Init Printer',0

init_printer	PROC far
	push ax
	push dx
	call GetPrinterPort
	or dx,dx
	stc
	jz init_printer_done
	mov al,8
	inc dx
	inc dx
	out dx,al
	mov cx,400h
	call WaitPulse
	mov al,0Ch
	out dx,al
	clc
init_printer_done:
	pop dx
	pop ax
	retf32
init_printer	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CHECK_PRINTER
;
;		DESCRIPTION:	Check printer
;
;		PARAMETERS:		DX		PRINTER #
;
;		RETURNS:		AL		STATUS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_printer_name	DB 'Check Printer',0

check_printer	PROC far
	push dx
	xor al,al
	call GetPrinterPort
	or dx,dx
	jz check_printer_done
	inc dx
	call Delay
	in al,dx
	call Delay
	in al,dx
	xor al,048h
	and al,0F8h
check_printer_done:
	pop dx
	retf32
check_printer	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WRITE_PRINTER
;
;		DESCRIPTION:	Write to printer
;
;		PARAMETERS:		DX		PRINTER #
;						AL		CHAR
;
;		RETURNS:		NC		Ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_printer_name	DB 'Write Printer',0

write_printer	PROC far
	push ax
	push bx
	push cx
	push dx
	call GetPrinterPort
	or dx,dx
	stc
	jz write_printer_done
	out dx,al
	call Delay
	inc dx
	in al,dx
	call Delay
	mov cx,60
WritePrinterBusyLoop:
	in al,dx
	test al,80h
	jnz WritePrinterReady
	mov ax,100
	WaitMicroSec
	loop WritePrinterBusyLoop
	stc
	jmp write_printer_done
WritePrinterReady:
	call Delay
	mov al,0Dh
	inc dx
	cli
	out dx,al
	call Delay
	mov al,0Ch
	out dx,al
	sti
	clc
write_printer_done:
	pop dx
	pop cx
	pop bx
	pop ax
	retf32
write_printer	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INT17
;
;		DESCRIPTION:	Handle INT 17
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_char_vm	Proc far
	WritePrinter
	jnc print_char_notimeout
	push dx
	call GetPrinterPort
	inc dx
	in al,dx
	pop dx
	and al,0F8h
	or al,1
	xor al,48h
	mov ah,al
	mov al,[bp].vm_eax
	ret
print_char_notimeout:
	CheckPrinter
	mov ah,al
	mov al,[bp].vm_eax
	ret
print_char_vm	Endp

init_printer_vm	Proc far
	InitPrinter
	CheckPrinter
	mov ah,al
	mov al,[bp].vm_eax
	ret
init_printer_vm	Endp

check_printer_vm	Proc far
	CheckPrinter
	mov ah,al
	mov al,[bp].vm_eax
	ret
check_printer_vm	Endp
		
printer_error	Proc far
	ret
printer_error	Endp
					
printer_tab:
p0	DW OFFSET print_char_vm
p1	DW OFFSET init_printer_vm
p2	DW OFFSET check_printer_vm
pend DW OFFSET printer_error

int17:
	SimSti
	cmp dx,3
	jnb printer_error
	mov bl,ah
	xor bh,bh
	cmp bx,3
	jc printer_call_do
	mov bx,3
printer_call_do:
	add bx,bx
	push word ptr cs:[bx].printer_tab
	mov bx,[bp].vm_ebx
	retn

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Init
;
;		DESCRIPTION:	Init device
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	pusha
	push ds
	mov bx,printer_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov al,17h
	mov di,OFFSET int17
	HookVMInt
;
	mov si,OFFSET init_printer
	mov di,OFFSET init_printer_name
	xor dx,dx
	mov ax,init_printer_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET check_printer
	mov di,OFFSET check_printer_name
	xor dx,dx
	mov ax,check_printer_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_printer
	mov di,OFFSET write_printer_name
	xor dx,dx
	mov ax,write_printer_nr
	RegisterBimodalUserGate
;
	pop ds
	popa
	ret
init	ENDP

code	ENDS

	END init

