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
include ..\os\pci.inc
						
		NAME pccom

MAX_PORTS       = 16
MAX_IRQS        = 16
MAX_IRQ_SHARE   = 4

IER_BITS        = 8

FLG_ENABLE_CTS  = 1
FLG_ENABLE_AUTO_RTS  = 2

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

char_time       DD ?

send_wait       DW ?

port_handle     DW ?
flgs            DB ?
base			DW ?

port_struc	ENDS

serial_port_struc   STRUC

s_base          DW ?
s_handle        DW ?
s_baud_base     DD ?

serial_port_struc   ENDS

serial_irq_struc    STRUC

serial_ports    DW ?
serial_port_arr DW MAX_IRQ_SHARE DUP(?)

serial_irq_struc    ENDS

serial_data STRUC

sd_ports    DW ?
sd_port_arr DW MAX_PORTS DUP(?)
sd_irq_arr  DW MAX_IRQS DUP(?)

serial_data ENDS

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
;		NAME:			RTS_OFF
;
;		DESCRIPTION:	Delayed RTS off
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rts_off	PROC far
    mov ds,cx
    mov di,ds:send_count
    or di,di
    jnz rts_off_done
;
    push ax
    push dx
    mov dx,ds:base
    add dx,5
    in al,dx
    test al,40h
    pop dx
    pop ax
    jnz rts_off_dis
;
	add eax,ds:char_time
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET rts_off
	mov bx,cx
	StartTimer
	jmp rts_off_done
        
rts_off_dis:
	mov dx,ds:base
	add dx,4
	in al,dx
	and al,NOT 2
	out dx,al

rts_off_done:
	ret
rts_off Endp

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
    test ds:flgs, FLG_ENABLE_AUTO_RTS
    jz trans_signal_wait
;
	GetSystemTime
	add eax,ds:char_time
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET rts_off
	mov bx,ds
	mov cx,bx
	StopTimer
	StartTimer
	mov es,ds:send_buf
    		
trans_signal_wait:
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
    xor bx,bx
    mov cx,ds:serial_ports

com_int_port_loop:
    push ds
    push bx
    push cx
;
    mov ds,ds:[bx].serial_port_arr
    mov ax,ds:s_handle
    or ax,ax
    jz com_int_inactive
;
    mov ds,ax

com_int_loop:
	mov dx,ds:base
	add dx,2
	in al,dx
	test al,1
	jnz com_int_next_port
;	
	mov bl,al
	xor bh,bh
	and bx,6
	call word ptr cs:[bx].serial_tab
	jmp com_int_loop

com_int_inactive:
	mov dx,ds:s_base
	add dx,2
	in al,dx
	test al,1
	jnz com_int_next_port
;	
    mov dx,ds:s_base
	add dx,6
	in al,dx
;	
    mov dx,ds:s_base
	add dx,5
	in al,dx
;
    mov dx,ds:s_base
	in al,dx
;	
	mov al,IER_BITS + 1
	inc dx
	out dx,al

com_int_next_port:
    pop cx
    pop bx
    pop ds
;
    add bx,2
    loop com_int_port_loop 
;       
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
	mov dx,ds:base
	inc bx
	mov al,0
	out dx,al				; disable rx, tx, line and modem ints
;	
    mov es,ds:port_handle
    mov es:s_handle,0
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
;		PARAMETERS:		AL				Port #
;						AH				# of data bits
;						BL				# of stop bits
;						BH				parity
;						ECX				baudrate
;						SI				size of transmit buffer
;						DI				size of receive buffer
;
;		RETURNS:		BX		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com_name DB 'Open Com',0

port_parity		EQU 2
port_stop_bits	EQU 4
port_data_bits	EQU 6
port_id         EQU 8
baud_rate   	EQU 10
send_buf_size	EQU 14
rec_buf_size	EQU 16
baud_divisor    EQU 18

open_com	Proc far
    sub sp,2
	push di
	push si
	push ecx
	mov cl,ah
    xor ah,ah
    push ax	
	movzx ax,cl
	push ax
	movzx ax,bl
	push ax
	movzx ax,bh
	push ax
	push bp
	mov bp,sp
	push ds
	push es
	push fs
	push cx
	push dx
	push di
;
    mov bx,com_data_sel
    mov ds,bx
    mov bx,[bp].port_id
    cmp bx,ds:sd_ports
    jae open_com_fail
;    
    add bx,bx
    mov fs,ds:[bx].sd_port_arr
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
	mov ds:flgs,0
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
	mov ax,fs:s_base
	mov ds:base,ax
	mov fs:s_handle,ds
	mov ds:port_handle,fs
;
    mov ax,start_com_port_nr
    IsValidOsGate
    jc open_com_started
;
    mov dx,fs:s_base
    StartComPort

open_com_started:   
	mov al,[bp].port_data_bits
	mov dl,al
	inc dl
	sub al,5
	and al,3
;
	mov ah,[bp].port_stop_bits
	add dl,ah
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
    inc dl
	or al,18h
	jmp open_parity_done

open_odd:
    inc dl
	or al,8

open_parity_done:
    push eax
    push ecx
    push edx
;
    push dx
;    
    mov ecx,[bp].baud_rate
    mov eax,fs:s_baud_base
    xor edx,edx
    div ecx
    mov [bp].baud_divisor,ax
;        
    mov eax,[bp].baud_rate    
    mov ecx,eax
    mov eax,1193000
    xor edx,edx
    div ecx             ; eax = 1193000 / baudrate
;
    pop dx
    movzx edx,dl
    mul edx             ; eax = char tics
    mov ds:char_time,eax
;
    pop edx
    pop ecx
    pop eax
;
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
	clc
	jmp open_com_done

open_com_fail:
    xor bx,bx
    stc

open_com_done:
	pop di
	pop dx
	pop cx
	pop fs
	pop es
	pop ds
	pop bp
	add sp,18
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
	mov dx,ds:base
	inc bx
	mov al,0
	out dx,al				; disable rx, tx, line and modem ints
;	
    mov es,ds:port_handle
    mov es:s_handle,0
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
	mov ax,100
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
;		NAME:			EnableAutoRts
;
;		DESCRIPTION:	Enable automatic RTS on send
;
;		PARAMETERS:		BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_auto_rts_name DB 'Enable Auto RTS',0

enable_auto_rts	PROC far
    push ds
    push ax
    push bx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc enable_auto_rts_done
;
	mov ds,[bx].port_sel
    or ds:flgs,FLG_ENABLE_AUTO_RTS
;
	mov dx,ds:base
	add dx,4
	in al,dx
	and al,NOT 2
	out dx,al

enable_auto_rts_done:
    pop bx
    pop ax
    pop ds
    retf32
enable_auto_rts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DisableAutoRts
;
;		DESCRIPTION:	Disable automatic RTS on send
;
;		PARAMETERS:		BX      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_auto_rts_name DB 'Disable Auto RTS',0

disable_auto_rts	PROC far
    push ds
    push ax
    push bx
;
    mov ax,SERIAL_HANDLE
    DerefHandle
    jc disable_auto_rts_done
;
	mov ds,[bx].port_sel
    and ds:flgs,NOT FLG_ENABLE_AUTO_RTS
;    
	mov dx,ds:base
	add dx,4
	in al,dx
	or al,2
	out dx,al

disable_auto_rts_done:
    pop bx
    pop ax
    pop ds
    retf32
disable_auto_rts Endp

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
    test ds:flgs, FLG_ENABLE_AUTO_RTS
    jz com_send_start
;
	mov bx,ds
	StopTimer
;	
	mov dx,ds:base
	add dx,4
	in al,dx
	or al,2
	out dx,al

com_send_start:
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitDetect
;
;		DESCRIPTION:    Init detect
;
;       PARAMETERS:     DX      Base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDetect  Proc near
    push dx
	mov al,83h
	add dx,3
	out dx,al				; set line control to divisor access
;
	sub dx,3
	mov al,12
	out dx,al				; output LSB divisor latch
;
	inc dx
	mov al,0
	out dx,al				; output MSB divisor latch
;
    inc dx
    mov al,1
    out dx,al               ; enable FIFOs if present
;
	mov al,3
	inc dx
	out dx,al				; set line control 
;
	sub dx,2
	mov al,0
	out dx,al				; enable rx ints and delta ints, disable tx, line ints
;
	add dx,3
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
	pop dx
;
    push dx
	in al,dx
	add dx,2
	in al,dx
	add dx,3
	in al,dx
	inc dx
	in al,dx
	pop dx
	ret
InitDetect  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DetectIrq
;
;		DESCRIPTION:    Detect IRQ for a serial base address
;
;       PARAMETERS:     DX      Base
;
;		RETURNS:		AL      IRQ
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DetectIrq   Proc near
    push bx
    push cx
    push bp
;    
    SetupIrqDetect
;
    push dx
    inc dx
	mov al,IER_BITS + 2
	out dx,al				; enable tx ints and delta ints, line ints
;
	add dx,3
	mov al,0Bh
	out dx,al				; modem control, DTR = high, RTS = high
    pop dx
;   
    push dx
	in al,dx
	add dx,2
	in al,dx
	add dx,3
	in al,dx
	inc dx
	in al,dx
	pop dx
;
    mov cx,1000h

diLoop1:
    loop diLoop1    
;
    PollIrqDetect
    or ax,ax
    stc
    jz diDone
;
    mov bp,ax
;    
    push dx
	inc dx
	xor al,al
	out dx,al
	pop dx
;
    push dx
    in al,dx
    add dx,2
    in al,dx
    add dx,2
    in al,dx
    add dx,2
    in al,dx
    pop dx
;
    mov cx,1000h

diLoop2:
    loop diLoop2
;
    SetupIrqDetect
;
    mov cx,1000h

diLoop3:
    loop diLoop3
;
    PollIrqDetect
;
    not ax
    and ax,bp
    stc
    jz diDone
;
    xor cx,cx
    mov bx,1

diGetNrLoop:
    test ax,bx
    jnz diGetNrDone
;
    shl bx,1
    inc cx
    jmp diGetNrLoop

diGetNrDone:
    not bx
    and ax,bx
    stc
    jnz diDone
;
    mov ax,cx
    clc    

diDone:
    pop bp
    pop cx
    pop bx
    ret
DetectIrq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddPort
;
;		DESCRIPTION:    Add port to list of available ports
;
;       PARAMETERS:     DX      Base
;                       AL      IRQ
;                       ECX     Baud base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPort Proc near
    push ds
    push es
    pushad
;    
    push ax
    mov ax,com_data_sel
    mov ds,ax
;
    mov eax,SIZE serial_port_struc
	AllocateSmallGlobalMem
	mov es:s_base,dx
	mov es:s_handle,0
	mov es:s_baud_base,ecx
	pop ax
	movzx dx,al
;
    mov bx,ds:sd_ports
    add bx,bx
    mov ds:[bx].sd_port_arr,es
    inc ds:sd_ports
;
    mov bx,dx
    add bx,bx
    mov ax,ds:[bx].sd_irq_arr
    or ax,ax
    jnz apAddIrqPort
;
    push es
    push ds
    mov eax,SIZE serial_irq_struc
    AllocateSmallGlobalMem
    mov es:serial_ports,0
    mov ax,es
    pop ds
    mov ds:[bx].sd_irq_arr,ax
    pop es

apAddIrqPort:
    mov ds,ax
    mov bx,ds:serial_ports
    add bx,bx
    mov ds:[bx].serial_port_arr,es 
    inc ds:serial_ports   
;
    popad
    pop es
    pop ds	
    ret
AddPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RequestIRQs
;
;		DESCRIPTION:    Request IRQs for all ports
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RequestIRQs Proc near
    push ds
    push es
    pushad
;    
    mov ax,com_data_sel
    mov ds,ax
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET com_int
;    
    mov cx,MAX_IRQS
    mov bx,OFFSET sd_irq_arr
    xor al,al

riLoop:
    mov dx,[bx]
    or dx,dx
    jz riNext
;    
    push ds
    mov ds,dx
    RequestPrivateIrqHandler
    pop ds

riNext:
    inc al
    add bx,2
    loop riLoop
;
    popad
    pop es
    pop ds	
    ret
RequestIRQs Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitPciAdapter
;
;		DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;		RETURNS:		NC		Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName	DB 'SerialPCI',0

PciVendorTab:
pci00	DW 1409h, 7168h
pci01 	DW 0,	  0

InitPciAdapter	Proc near
	mov si,OFFSET PciVendorTab
init_pci_loop:
	xor ax,ax
	mov dx,cs:[si]
	mov cx,cs:[si+2]
	or dx,dx
	stc
	jz init_pci_done
;
	FindPciDevice
	jnc init_pci_found
;
	add si,4
	jmp init_pci_loop

init_pci_found:
	xor ch,ch
	mov cl,PCI_command_reg
	ReadPciWord
	or al,PCI_command_IO OR PCI_command_busmstr
	WritePciWord
;
	mov cl,10h
	ReadPciDword
	mov dx,ax
	and dx,0FF00h
;
	xor ch,ch
	mov cl,PCI_interrupt_line
	ReadPciByte
;
    mov ecx,921600
    call AddPort
;
    add dx,8
    call AddPort    
	clc

init_pci_done:
	ret
InitPciAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_pci
;
;		DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

detect_name	DB 'Serial PCI',0

detect_thread	proc far
    mov ax,100
    WaitMilliSec
; 
    mov dx,3F8h
    call InitDetect
; 
    mov dx,2F8h
    call InitDetect
; 
    mov dx,3E8h
    call InitDetect
; 
    mov dx,2E8h
    call InitDetect
; 
    mov dx,3F8h
    call DetectIrq
    jc dt1
;
    mov ecx,115200
    call AddPort    
    call InitDetect

dt1:
    mov dx,2F8h
    call DetectIrq
    jc dt2
;
    mov ecx,115200
    call AddPort
    call InitDetect

dt2:   
    mov dx,3E8h
    call DetectIrq
    jc dt3
;    
    mov ecx,115200
    call AddPort
    call InitDetect

dt3:   
    mov dx,2E8h
    call DetectIrq
    jc dtpci
;    
    mov ecx,115200
    call AddPort
    call InitDetect

dtpci:
	call InitPciAdapter
	call RequestIRQs
    int 3    
    mov ax,com_data_sel
    mov ds,ax
    mov cx,ds:serial_ports
	ret
detect_thread	endp
	
init_pci	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET detect_name
	mov si,OFFSET detect_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_pci	Endp

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
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_pci
	HookInitTasking
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
	mov si,OFFSET enable_auto_rts
	mov di,OFFSET enable_auto_rts_name
	xor dx,dx
	mov ax,enable_auto_rts_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET disable_auto_rts
	mov di,OFFSET disable_auto_rts_name
	xor dx,dx
	mov ax,disable_auto_rts_nr
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
	mov eax,SIZE serial_data
	mov bx,com_data_sel
	AllocateFixedSystemMem
	mov cx,SIZE serial_data
	xor di,di
	xor al,al
	rep stosb
;
	popa
	pop es
	pop ds	
	ret
init	Endp


code	ENDS

	END init
