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

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
						
		NAME pccom


IER_BITS        = 8

FLG_ENABLE_CTS  = 1

serial_wait_header	STRUC

sw_obj			wait_obj_header <>
sw_handle		DW ?

serial_wait_header	ENDS


serial_handle_seg		STRUC

serial_handle_base	handle_header <>

port_sel            DW ?

serial_handle_seg		ENDS

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

avail_obj   	DW ?

send_wait       DW ?

irq				DB ?
flgs            DB ?
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
;	
	test al,10h
	jz modem_no_cts
;
    test ds:flgs, FLG_ENABLE_CTS
    jz modem_no_cts
;    
	mov cx,ds:send_count
	or cx,cx
	jz modem_no_cts
;
	mov dx,ds:base
	inc dx
	mov al,IER_BITS + 3
	out dx,al

modem_no_cts:	
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
;
	xor bx,bx
	
rec_no_wrap:
	mov ds:rec_tail,bx
;
    mov bx,ds:avail_obj
    or bx,bx
    jz rec_exit
;
    mov es,bx
    SignalWait
	mov ds:avail_obj,0
	
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

trans_end:	
	mov al,IER_BITS + 1
	inc dx
	out dx,al
;
    mov bx,ds:send_wait
    or bx,bx
    jz trans_exit
;
    Signal
	jmp trans_exit
	
trans_not_empty:	
    test ds:flgs, FLG_ENABLE_CTS
    jz trans_send
;
	add dx,6
	in al,dx
	sub dx,6
	test al,10h
	jz trans_end

trans_send:
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
;		NAME:			Delete_handle
;
;		DESCRIPTION:	Delete handle (called from handle module)
;
;		PARAMETERS:		BX			COM HANDLE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push es
	push ax
	push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc delete_handle_done
;
    push [bx].port_sel
    FreeHandle
    pop ds
;
    mov ax,stop_com_port_nr
    IsValidOsGate
    jc delete_handle_stopped
;
    mov dx,ds:base
    StopComPort

delete_handle_stopped:
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

delete_handle_done:
	pop dx
	pop ax
	pop es
	pop ds
	ret
delete_handle	Endp

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
;
    mov ax,SERIAL_HANDLE
	mov cx,SIZE serial_handle_seg
	AllocateHandle
	mov [bx].port_sel,es
	mov [bx].hh_sign,SERIAL_HANDLE
	mov bx,[bx].hh_handle
	push bx
;
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
	mov ds:avail_obj,0
	mov ds:send_wait,0
;
	mov ax,[bp].port_base
	mov ds:base,ax
	mov al,[bp].port_irq
	mov ds:irq,al
	mov ds:flgs,0
	mov cx,cs
	mov es,cx
	mov di,OFFSET com_int
	RequestPrivateIrqHandler
;
    mov ax,start_com_port_nr
    IsValidOsGate
    jc open_com_started
;
    mov dx,[bp].port_base
    StartComPort

open_com_started:    
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
    inc dx
    mov al,1
    out dx,al               ; enable FIFOs if present
;
	pop ax
	inc dx
	out dx,al				; set line control 
;
	sub dx,2
	mov al,IER_BITS + 1
	out dx,al				; enable rx ints and delta ints, disable tx, line ints
;
	add dx,3
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
;
	mov dx,ds:base
	in al,dx
	add dx,5
	in al,dx
	inc dx
	in al,dx
;
	pop bx
;
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
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc close_com_done
;
    push [bx].port_sel
    FreeHandle
    pop ds
;
    mov ax,stop_com_port_nr
    IsValidOsGate
    jc close_com_stopped
;
    mov dx,ds:base
    StopComPort

close_com_stopped:
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


close_com_done:
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
;		NAME:			EnableCts
;
;		DESCRIPTION:	Enable CTS signal
;
;		PARAMETERS:		BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts_name DB 'Enable CTS',0

enable_cts	PROC far
    push ds
    push ax
    push bx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc enable_cts_done
;
	mov ds,[bx].port_sel
    or ds:flgs,FLG_ENABLE_CTS

enable_cts_done:
    pop bx
    pop ax
    pop ds
    retf32
enable_cts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DisableCts
;
;		DESCRIPTION:	Disable CTS signal
;
;		PARAMETERS:		BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts_name DB 'Disable CTS',0

disable_cts	PROC far
    push ds
    push ax
    push bx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc disable_cts_done
;
	mov ds,[bx].port_sel
    and ds:flgs,NOT FLG_ENABLE_CTS

disable_cts_done:
    pop bx
    pop ax
    pop ds
    retf32
disable_cts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FlushCom
;
;		DESCRIPTION:	Flush com
;
;		PARAMETERS:		BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com_name DB 'Flush Com',0

flush_com	PROC far
    push ds
    push ax
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc flush_com_done
;
	mov ds,[bx].port_sel
	cli
;
	mov dx,ds:base
	mov al,IER_BITS + 1
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

flush_com_done:
    pop ax
    pop ds
    retf32
flush_com Endp

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
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc com_read_done
;
	mov ds,[bx].port_sel
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
;		NAME:			get_com_receive_space
;
;		description:	Get space in receive buffer
;
;		PARAMETERS:		BX			Port handle
;
;		RETURNS:		EAX         Free space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_com_receive_space_name DB 'Get Com Receive Space',0

get_com_receive_space	PROC far
	push ds
	push bx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc get_com_rec_space_done
;
	mov ds,[bx].port_sel
    mov ax,ds:rec_size
    sub ax,ds:rec_count
    movzx eax,ax

get_com_rec_space_done:
    pop bx
	pop ds
	retf32
get_com_receive_space	ENDP

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
    push ax
    mov ax,SERIAL_HANDLE
    DerefHandle
    pop ax
    jc com_send_full
;
	mov ds,[bx].port_sel
	mov es,ds:send_buf
	cli
	mov cx,ds:send_count
	cmp cx,ds:send_size
	je com_send_full
;	
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
    test ds:flgs, FLG_ENABLE_CTS
    jz com_send_enable
;
	mov dx,ds:base
	add dx,6
	in al,dx
	test al,10h
	jz com_send_ok

com_send_enable:
	mov dx,ds:base
	inc dx
	mov al,IER_BITS + 3
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
;		NAME:			wait_for_send_completed_com
;
;		description:	Wait until send buffer is empty
;
;		PARAMETERS:		BX			Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_send_completed_com_name DB 'Wait For Send Completed Com',0

wait_for_send_completed_com	PROC far
	push ds
	push bx
	push cx
;
    push ax
    mov ax,SERIAL_HANDLE
    DerefHandle
    pop ax
    jc wait_for_send_completed_done
;
	mov ds,[bx].port_sel
    GetThread
    mov ds:send_wait,ax
;    
	ClearSignal

	mov cx,ds:send_count
	or cx,cx
	jz wait_for_send_completed_done
;
    WaitForSignal

wait_for_send_completed_done:
	pop cx
	pop bx
	pop ds
	retf32
wait_for_send_completed_com	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_com_send_space
;
;		description:	Get space in send buffer
;
;		PARAMETERS:		BX			Port handle
;
;		RETURNS:		EAX         Free space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_com_send_space_name DB 'Get Com Send Space',0

get_com_send_space	PROC far
	push ds
	push bx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc get_com_send_space_done
;
	mov ds,[bx].port_sel
    mov ax,ds:send_size
    sub ax,ds:send_count
    movzx eax,ax

get_com_send_space_done:
    pop bx
	pop ds
	retf32
get_com_send_space	ENDP

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
	push bx
	push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc set_dtr_done
;
	mov ds,[bx].port_sel
	mov dx,ds:base
	add dx,4
	in al,dx
	or al,1
	out dx,al

set_dtr_done:
	pop dx
	pop bx
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
	push bx
	push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc reset_dtr_done
;
	mov ds,[bx].port_sel
	mov dx,ds:base
	add dx,4
	in al,dx
	and al,NOT 1
	out dx,al	

reset_dtr_done:
	pop dx
	pop bx
	pop ax
	pop ds
	retf32
reset_dtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			set_rts
;
;		description:	Set RTS signal
;
;		PARAMETERS:		BX		Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts_name DB 'Set Rts',0

set_rts	Proc far
	push ds
	push ax
	push bx
	push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc set_rts_done
;
	mov ds,[bx].port_sel
	mov dx,ds:base
	add dx,4
	in al,dx
	or al,2
	out dx,al

set_rts_done:
	pop dx
	pop bx
	pop ax
	pop ds
	retf32
set_rts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			reset_rts
;
;		description:	Reset RTS signal
;
;		PARAMETERS:		BX		Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts_name DB 'Reset Rts',0

reset_rts	Proc far
	push ds
	push ax
	push bx
	push dx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc reset_rts_done
;
	mov ds,[bx].port_sel
	mov dx,ds:base
	add dx,4
	in al,dx
	and al,NOT 2
	out dx,al	

reset_rts_done:
	pop dx
	pop bx
	pop ax
	pop ds
	retf32
reset_rts	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartWaitForCom
;
;		DESCRIPTION:	Start a wait for com
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_com	PROC far
    push ds
    push ax
    push bx
;
    mov bx,es:sw_handle
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc start_wait_for_done
;
	mov ds,[bx].port_sel
	mov ds:avail_obj,es
	mov ax,ds:rec_count
	or ax,ax
	je start_wait_for_done
;
	mov ds:avail_obj,0
    SignalWait

start_wait_for_done:
    pop bx
    pop ax
    pop ds
    ret
start_wait_for_com Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopWaitForCom
;
;		DESCRIPTION:	Stop a wait for com
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_com	PROC far
    push ds
    push ax
    push bx
;
    mov bx,es:sw_handle
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc stop_wait_done
;
	mov ds,[bx].port_sel
	mov ds:avail_obj,0

stop_wait_done:
    pop bx
    pop ax
    pop ds
    ret
stop_wait_for_com Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ClearCom
;
;		DESCRIPTION:	Clear com
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_com	PROC far
    ret
clear_com Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsComIdle
;
;		DESCRIPTION:	Check if com is idle
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_com_idle	PROC far
    push ds
    push ax
    push bx
;
    mov bx,es:sw_handle
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc is_idle_done
;
	mov ds,[bx].port_sel
	mov ax,ds:rec_count
	or ax,ax
	clc
	je is_idle_done
;
	stc

is_idle_done:
    pop bx
    pop ax
    pop ds
    ret
is_com_idle Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddWaitForCom
;
;		DESCRIPTION:	Add a wait for serial port
;
;		PARAMETERS:		AX      Serial handle
;                       BX      Wait handle
;                       ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_com_name	DB 'Add Wait For Com',0

add_wait_tab:
aw0	DW OFFSET start_wait_for_com,    	com_code_sel
aw1 DW OFFSET stop_wait_for_com,		com_code_sel
aw2	DW OFFSET clear_com,				com_code_sel
aw3	DW OFFSET is_com_idle,		    	com_code_sel

add_wait_for_com	PROC far
	push ds
	push es
	push eax
	push di
;
    push ax
    mov ax,cs
    mov es,ax
   	mov ax,SIZE serial_wait_header - SIZE wait_obj_header
    mov di,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;
	mov es:sw_handle,ax

add_wait_done:
    pop di
    pop eax
    pop es
    pop ds
	retf32
add_wait_for_com	ENDP

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
	mov di,OFFSET delete_handle
	mov ax,SERIAL_HANDLE
	RegisterHandle
;
	mov si,OFFSET add_wait_for_com
	mov di,OFFSET add_wait_for_com_name
	xor dx,dx
	mov ax,add_wait_for_com_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET open_com
	mov di,OFFSET open_com_name
	xor dx,dx
	mov ax,open_com_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_com
	mov di,OFFSET close_com_name
	xor dx,dx
	mov ax,close_com_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET flush_com
	mov di,OFFSET flush_com_name
	xor dx,dx
	mov ax,flush_com_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET read_com
	mov di,OFFSET read_com_name
	xor dx,dx
	mov ax,read_com_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_com
	mov di,OFFSET write_com_name
	xor dx,dx
	mov ax,write_com_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET wait_for_send_completed_com
	mov di,OFFSET wait_for_send_completed_com_name
	xor dx,dx
	mov ax,wait_for_send_completed_com_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET enable_cts
	mov di,OFFSET enable_cts_name
	xor dx,dx
	mov ax,enable_cts_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET disable_cts
	mov di,OFFSET disable_cts_name
	xor dx,dx
	mov ax,disable_cts_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_dtr
	mov di,OFFSET set_dtr_name
	xor dx,dx
	mov ax,set_dtr_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET reset_dtr
	mov di,OFFSET reset_dtr_name
	xor dx,dx
	mov ax,reset_dtr_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_rts
	mov di,OFFSET set_rts_name
	xor dx,dx
	mov ax,set_rts_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET reset_rts
	mov di,OFFSET reset_rts_name
	xor dx,dx
	mov ax,reset_rts_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_com_receive_space
	mov di,OFFSET get_com_receive_space_name
	xor dx,dx
	mov ax,get_com_receive_space_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_com_send_space
	mov di,OFFSET get_com_send_space_name
	xor dx,dx
	mov ax,get_com_send_space_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds	
	ret
init	Endp


code	ENDS

	END init
