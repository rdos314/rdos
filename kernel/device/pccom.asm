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
; PCCOM.ASM
; Standard serial port device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME pccom

GateSize = 16

include ..\os\system.inc
include ..\os\os.def
include ..\os\os.inc
include ..\os\user.def
include ..\os\user.inc
include ..\os\driver.def
						
		NAME pccom

port_struc	STRUC

send_count		DW ?
rec_count	  	DW ?

send_head		DW ?
rec_head		DW ?

send_tail		DW ?
rec_tail		DW ?

send_size		DW ?
rec_size		DW ?

rec_buf			DW ?
send_buf		DW ?

owner_thread	DW ?

irq				DB ?
base			DW ?

port_struc	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386c

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MODEM
;
;		DESCRIPTION:	Modem signals changed
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

modem	Proc near
	mov dx,ds:base
	add dx,6
	in al,dx
	ret
modem	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LINE_ERR
;
;		DESCRIPTION:	Line error occured
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

line_err	PROC near
	mov dx,ds:base
	add dx,5
	in al,dx
	ret
line_err	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			REC_PR
;
;		DESCRIPTION:	Received data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rec_pr	PROC near
	mov es,ds:rec_buf
	mov dx,ds:base
	cli
	in al,dx
	mov cx,ds:rec_count
	cmp cx,ds:rec_size
	je rec_exit
	inc cx
	mov ds:rec_count,cx
	mov bx,ds:rec_tail		; get tail pointer
	mov es:[bx],al				; store char
	inc bx
	cmp bx,ds:rec_size
	jnz rec_no_wrap
	xor bx,bx
rec_no_wrap:
	mov ds:rec_tail,bx
	mov bx,ds:owner_thread
	Signal
rec_exit:
	sti
	ret
rec_pr	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRANS_PR
;
;		DESCRIPTION:	Send data
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trans_pr	PROC near
	mov es,ds:send_buf
	mov dx,ds:base
	cli
	mov cx,ds:send_count
	or cx,cx					;  buffer empty ?
	jnz trans_not_empty
	mov al,1
	inc dx
	out dx,al
	jmp trans_exit
trans_not_empty:
	dec cx
	mov ds:send_count,cx
	mov bx,ds:send_head				; get head pointer
	mov al,es:[bx]						; get char
	out dx,al						; transmitt char
	inc bx
	cmp bx,ds:send_size
	jnz trans_not_wrap
	xor bx,bx
trans_not_wrap:
	mov ds:send_head,bx
trans_exit:
	sti
	ret
trans_pr	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			COM_INT
;
;		DESCRIPTION:	Serial interrupt
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serial_tab:
st_mod	DW OFFSET modem
st_tx	DW OFFSET trans_pr
st_rx	DW OFFSET rec_pr
st_li	DW OFFSET line_err

com_int	Proc far
	mov dx,ds:base
	add dx,2
	in al,dx
	test al,1
	jnz com_int_end
	mov bl,al
	xor bh,bh
	and bx,6
	call word ptr cs:[bx].serial_tab
	jmp com_int
com_int_end:
	ret
com_int	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			open_com
;
;		description:	Open a serial port
;
;		PARAMETERS:		DX				IO base address
;						AL				IRQ
;						AH				# of data bits
;						BL				# of stop bits
;						BH				parity
;						CX				baudrate divisor
;						SI				size of transmit buffer
;						DI				size of receive buffer
;
;		RETURNS:		BX		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com_name DB 'Open Com',0

port_base		EQU 2
port_parity		EQU 4
port_stop_bits	EQU 6
port_data_bits	EQU 8
port_irq		EQU 10
baud_divisor	EQU 12
send_buf_size	EQU 14
rec_buf_size	EQU 16

open_com	Proc far
	push di
	push si
	push cx
	mov cl,ah
	and ax,0Fh
	push ax
	mov al,cl
	push ax
	mov al,bl
	push ax
	mov al,bh
	push ax
	push dx
	push bp
	mov bp,sp
	push ds
	push es
	push cx
	push dx
	push di
;
	mov eax, SIZE port_struc
	AllocateSmallGlobalMem
	mov ax,es
	mov ds,ax
;
	movzx eax,word ptr [bp].send_buf_size
	mov ds:send_size,ax
	AllocateSmallGlobalMem
	mov ds:send_buf,es
	mov ds:send_count,0
	mov ds:send_head,0
	mov ds:send_tail,0
;
	movzx eax,word ptr [bp].rec_buf_size
	mov ds:rec_size,ax
	AllocateSmallGlobalMem
	mov ds:rec_buf,es
	mov ds:rec_count,0
	mov ds:rec_head,0
	mov ds:rec_tail,0
;
	mov ax,[bp].port_base
	mov ds:base,ax
	mov al,[bp].port_irq
	mov ds:irq,al
	mov cx,cs
	mov es,cx
	mov di,OFFSET com_int
	RequestPrivateIrqHandler
;
	mov al,[bp].port_data_bits
	sub al,5
	and al,3
;
	mov ah,[bp].port_stop_bits
	dec ah
	and ah,1
	shl ah,2
	or al,ah
;
	mov ah,[bp].port_parity
	cmp ah,'E'
	je open_even
	cmp ah,'O'
	je open_odd
	jmp open_parity_done

open_even:
	or al,18h
	jmp open_parity_done

open_odd:
	or al,8

open_parity_done:
	push ax
	or al,80h
	mov dx,ds:base
	add dx,3
	out dx,al				; set line control to divisor access
;
	sub dx,3
	mov al,[bp].baud_divisor
	out dx,al				; output LSB divisor latch
;
	inc dx
	mov al,[bp].baud_divisor+1
	out dx,al				; output MSB divisor latch
;
	pop ax
	add dx,2
	out dx,al				; set line control 
;
	sub dx,2
	mov al,1
	out dx,al				; enable rx ints, disable tx, line and modem ints
;
	add dx,3
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
;
	mov bx,ds
	pop di
	pop dx
	pop cx
	pop es
	pop ds
	pop bp
	add sp,16
	retf32 
open_com	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			close_com
;
;		description:	Close serial port
;
;		PARAMETERS:		BX		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com_name DB 'Close Com',0

close_com	Proc far
	push ds
	push es
	push ax
	push dx
;
	mov ds,bx
	mov al,ds:irq
	ReleasePrivateIrqHandler
;
	mov dx,ds:base
	inc bx
	mov al,0
	out dx,al				; disable rx, tx, line and modem ints
;
	mov es,ds:send_buf
	FreeMem
	mov es,ds:rec_buf
	FreeMem
;
	mov ax,ds
	xor bx,bx
	mov ds,bx
	mov es,ax
	FreeMem
;
	mov ax,500
	WaitMilliSec
;
	pop dx
	pop ax
	pop es
	pop ds
	retf32
close_com	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			flush_com
;
;		description:	Clears receive & transmit queues
;
;		PARAMETERS:		BX		Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com_name DB 'Flush Com',0

flush_com	Proc far
	push ds
	push ax
	push dx
;
	mov ds,bx
	cli
;
	mov dx,ds:base
	mov al,1
	inc dx
	out dx,al
;
	mov ds:send_count,0
	mov ds:send_head,0
	mov ds:send_tail,0
	mov ds:rec_count,0
	mov ds:rec_head,0
	mov ds:rec_tail,0
	sti
;
	pop dx
	pop ax
	pop ds
	retf32
flush_com	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			poll_com
;
;		description:	Check if data is available from port
;
;		PARAMETERS:		BX			Port handle
;
;		RETURNS:		AX			Number of bytes in buffer			
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_com_name DB 'Poll Com',0

poll_com	PROC far
	push ds
	mov ds,bx
	mov ax,ds:rec_count
	pop ds
	retf32
poll_com	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			wait_for_com
;
;		description:	Wait with timeout for data
;
;		PARAMETERS:		BX			Port handle
;						EAX			Timeout in ms
;
;		RETURNS:		AX			# of available bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_com_name DB 'Wait For Com',0

WaitForCharTimeout	Proc far
	mov bx,cx
	Signal
	ret
WaitForCharTimeout	Endp

wait_for_com	PROC far
	push ds
	push es
	push ebx
	push cx
	push edx
	push di
;
	mov ds,bx
	mov ebx,eax
	GetThread
	mov ds:owner_thread,ax
	ClearSignal
;
	mov ax,ds:rec_count
	or ax,ax
	jnz done
;
	mov eax,1193
	mul ebx
	push edx
	push eax
	GetSystemTime
	pop ebx
	add eax,ebx
	pop ebx
	adc edx,ebx
	mov bx,cs
	mov es,bx
	mov di,OFFSET WaitForCharTimeout
	mov bx,ds:owner_thread
	mov cx,bx
	StartTimer
	WaitForSignal
	StopTimer
	mov ax,ds:rec_count
done:
	pop di
	pop edx
	pop cx
	pop ebx
	pop es
	pop ds
	retf32
wait_for_com	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			read_com
;
;		description:	Read a byte from port
;
;		PARAMETERS:		BX			Port handle
;
;		RETURNS:		AL			Received byte
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_com_name DB 'Read Com',0

read_com	PROC far
	push ds
	push es
	push bx
	push cx
	mov ds,bx
	mov es,ds:rec_buf
;
	cli
	mov cx,ds:rec_count
	or cx,cx
	jz com_read_no_char
	mov bx,ds:rec_head
	mov al,es:[bx]			; get char from buffer
	dec cx
	mov ds:rec_count,cx
	inc bx
	cmp bx,ds:rec_size
	jnz com_read_nix_wrap
	xor bx,bx
com_read_nix_wrap:
	mov ds:rec_head,bx
	sti
	xor ah,ah
	jmp com_read_done
com_read_no_char:
	sti
	mov ax,-1
com_read_done:
	pop cx
	pop bx
	pop es
	pop ds
	retf32
read_com	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			write_com
;
;		description:	Write byte to port
;
;		PARAMETERS:		BX			Port handle
;						AL			Data
;
;		RETURNS:		0			OK
;						-1			Buffer overflow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_com_name DB 'Write Com',0

write_com	PROC far
	push ds
	push es
	push bx
	push cx
	push dx
;
	mov ds,bx
	mov es,ds:send_buf
	cli
	mov cx,ds:send_count
	cmp cx,ds:send_size
	je com_send_full
	mov bx,ds:send_tail
	mov es:[bx],al
	inc bx
	cmp bx,ds:send_size
	jnz com_send_no_wrap
	xor bx,bx
com_send_no_wrap:
	mov ds:send_tail,bx
	or cx,cx
	jnz com_send_ok
;
	mov dx,ds:base
	inc dx
	mov al,3
	out dx,al
com_send_ok:
	inc cx
	mov ds:send_count,cx
com_send_ok_done:
	sti
	xor ax,ax
	jmp com_send_end
com_send_full:
	sti
	mov ax,-1
com_send_end:
;
	pop dx
	pop cx
	pop bx
	pop es
	pop ds
	retf32
write_com	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			set_dtr
;
;		description:	Set DTR signal
;
;		PARAMETERS:		BX		Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr_name DB 'Set Dtr',0

set_dtr	Proc far
	push ds
	push ax
	push dx
;
	mov ds,bx
	mov dx,ds:base
	add dx,4
	mov al,0Bh
	out dx,al
;
	pop dx
	pop ax
	pop ds
	retf32
set_dtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			reset_dtr
;
;		description:	Reset DTR signal
;
;		PARAMETERS:		BX		Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr_name DB 'Reset Dtr',0

reset_dtr	Proc far
	push ds
	push ax
	push dx
;
	mov ds,bx
	mov dx,ds:base
	add dx,4
	mov al,0Ah
	out dx,al	
;
	pop dx
	pop ax
	pop ds
	retf32
reset_dtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		description:	Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
	mov bx,com_code_sel
	InitDevice
;	
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET open_com
	mov di,OFFSET open_com_name
	xor cl,cl
	mov ax,open_com_nr
	RegisterUserGate
;
	mov si,OFFSET close_com
	mov di,OFFSET close_com_name
	xor cl,cl
	mov ax,close_com_nr
	RegisterUserGate
;
	mov si,OFFSET flush_com
	mov di,OFFSET flush_com_name
	xor cl,cl
	mov ax,flush_com_nr
	RegisterUserGate
;
	mov si,OFFSET poll_com
	mov di,OFFSET poll_com_name
	xor cl,cl
	mov ax,poll_com_nr
	RegisterUserGate
;
	mov si,OFFSET wait_for_com
	mov di,OFFSET wait_for_com_name
	xor cl,cl
	mov ax,wait_for_com_nr
	RegisterUserGate
;
	mov si,OFFSET read_com
	mov di,OFFSET read_com_name
	xor cl,cl
	mov ax,read_com_nr
	RegisterUserGate
;
	mov si,OFFSET write_com
	mov di,OFFSET write_com_name
	xor cl,cl
	mov ax,write_com_nr
	RegisterUserGate
;
	mov si,OFFSET set_dtr
	mov di,OFFSET set_dtr_name
	xor cl,cl
	mov ax,set_dtr_nr
	RegisterUserGate
;
	mov si,OFFSET reset_dtr
	mov di,OFFSET reset_dtr_name
	xor cl,cl
	mov ax,reset_dtr_nr
	RegisterUserGate
;
	popa
	pop es
	pop ds	
	ret
init	Endp


code	ENDS

	END init
