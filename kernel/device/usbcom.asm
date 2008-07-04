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
; FTDICOM.ASM
; FTDI-based chips USB based serial port device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME ftdicom

GateSize = 16

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\usb.inc
include ..\os\com.inc

MAX_PORTS       = 16

FLAG_CTS	= 10h
FLAG_DSR	= 20h
FLAG_RI		= 40h
FLAG_RLSD	= 80h
FLAG_DR		= 100h
FLAG_OE		= 200h
FLAG_PE		= 400h
FLAG_FE		= 800h
FLAG_BI		= 1000h
FLAG_THRE	= 2000h
FLAG_TEMT	= 4000h
FLAG_FIFO_ERR	= 8000h

DEVICE_TYPE_SIO = 1
DEVICE_TYPE_FT232AM = 2
DEVICE_TYPE_FT232BM = 3
DEVICE_TYPE_FT2232C = 4

usbcom_port_struc	STRUC

ups_base_struc  com_port_struc <>

ups_device_sel      DW ?
ups_controller      DW ?
ups_device          DW ?
ups_control_wait    DW ?
ups_control_pipe    DW ?
ups_index           DW ?
ups_device_type     DW ?
ups_divisor         DD ?
ups_timer_active    DB ?
ups_data_bits       DB ?
ups_stop_bits       DB ?
ups_parity          DB ?

usbcom_port_struc	ENDS

usbcom_device_struc   STRUC

uds_base_struc    com_device_struc <>

uds_section         section_typ <>
uds_port_sel        DW ?
uds_device_type     DW ?
uds_maxsize         DW ?
uds_interface       DB ?
uds_bulk_in         DB ?
uds_bulk_out        DB ?
uds_in_handle       DW ?
uds_out_handle      DW ?
uds_in_buffer       DW ?
uds_out_buffer      DW ?
uds_in_req          DW ?
uds_out_req         DW ?
uds_delete          DB ?

usbcom_device_struc   ENDS

serial_data STRUC

sd_section          section_typ <>
sd_thread           DW ?

sd_ports            DW ?
sd_port_arr         DW MAX_PORTS DUP(?)

serial_data ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386c

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendSignal
;
;		description:	Sends signal to USB-handler thread
;
;       Parameters:     CX      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendSignal  Proc far
    push ds
    push ax
    push bx
;    
    mov ds,cx
    mov ds:ups_timer_active,0
;    
    mov ax,usbcom_data_sel
    mov ds,ax    
    mov bx,ds:sd_thread
    Signal    
;
    pop bx
    pop ax
    pop ds
    ret
SendSignal  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartSendTimer
;
;		description:	Starts send timeout
;
;       Parameters:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartSendTimer Proc near
    push es
    pushad
;	
    mov al,1    
    xchg al,ds:ups_timer_active
    or al,al
    jnz sstDone
;
	GetSystemTime
	add eax,11930
	adc edx,0
;	
	mov bx,cs
	mov es,bx
	mov di,OFFSET SendSignal
	mov bx,ds
	mov cx,bx
	StartTimer

sstDone:
    popad
    pop es
    ret
StartSendTimer Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDivisorError
;
;		description:	Get baud-rate divisor, error type
;
;		PARAMETERS:		DS      Port selector
;						ECX		baudrate
;
;       RETURNS:        ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDivisorError Proc near
    xor cx,cx
    stc
    ret
GetDivisorError Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetSioDivisor
;
;		description:	Get baud-rate divisor, SIO type
;
;		PARAMETERS:		DS      Port selector
;						ECX		baudrate
;
;       RETURNS:        ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSioDivisor Proc near
    push ax
;    
    xor al,al
    cmp ecx,300
    je gdsDone
;
    inc al
    cmp ecx,600
    je gdsDone
;
    inc al
    cmp ecx,1200
    je gdsDone
;
    inc al
    cmp ecx,2400
    je gdsDone
;
    inc al
    cmp ecx,4800
    je gdsDone
;
    inc al
    cmp ecx,9600
    je gdsDone
;
    inc al
    cmp ecx,19200
    je gdsDone
;
    inc al
    cmp ecx,38400
    je gdsDone
;
    inc al
    cmp ecx,57600
    je gdsDone
;
    inc al
    cmp ecx,115200
    je gdsDone
;
    mov al,5                        

gdsDone:                           
    movzx ecx,al
    clc
;
    pop ax
    ret
GetSioDivisor Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Get232AmDivisor
;
;		description:	Get baud-rate divisor, 232AM type
;
;		PARAMETERS:		DS      Port selector
;						ECX		baudrate
;
;       RETURNS:        ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Get232AmDivisor Proc near
    push eax
    push edx
;    
    xor edx,edx
    mov eax,48000000 / 2
    div ecx
    mov ecx,eax
    and al,7
    cmp al,7
    jne get_am_not7
;
    inc ecx

get_am_not7:
    shr ecx,3
    cmp al,1
    jne get_am_not1
;
    or cx,0C000h
    jmp get_am_part_ok

get_am_not1:
    cmp al,4
    jb get_am_not4
;
    or cx,4000h
    jmp get_am_part_ok
        
get_am_not4:
    or al,al
    je get_am_part_ok
;
    or cx,8000h

get_am_part_ok: 
    cmp cx,1
    jnz get_am_done
;
    xor cx,cx

get_am_done:
    clc
;    
    pop edx
    pop eax    
    ret
Get232AmDivisor Endp
        
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Get232BmDivisor
;
;		description:	Get baud-rate divisor, 232BM type
;
;		PARAMETERS:		DS      Port selector
;						ECX		baudrate
;
;       RETURNS:        ECX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fractab:
bft00    DB 0
bft01    DB 3
bft02    DB 2
bft03    DB 4
bft04    DB 1
bft05    DB 5
bft06    DB 6
bft07    DB 7

Get232BmDivisor Proc near
    push eax
    push bx
    push edx
;    
    xor edx,edx
    mov eax,48000000 / 2
    div ecx
    mov ecx,eax
    shr ecx,3
;
    movzx bx,cl
    and bl,7
    movzx eax,byte ptr cs:[bx].fractab
    shl eax,14
    or ecx,eax
;
    cmp ecx,1
    jne get_bm_not1
;
    xor ecx,ecx

get_bm_not1:
    cmp ecx,4001h
    jne get_bm_not4001
;
    mov ecx,1

get_bm_not4001:            
    clc
;    
    pop edx
    pop bx
    pop eax    
    ret
Get232BmDivisor Endp
        
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetBaudDivisor
;
;		description:	Get baud-rate divisor
;
;		PARAMETERS:		DS      Port selector
;						ECX		baudrate
;
;       RETURNS:        CX     Divisor to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BaudDivisorTab:
gbd00   DW OFFSET GetDivisorError
gbd01   DW OFFSET GetSioDivisor
gbd02   DW OFFSET Get232AmDivisor
gbd03   DW OFFSET Get232BmDivisor
gbd04   DW OFFSET Get232BmDivisor
gbdend  DW OFFSET GetDivisorError

GetBaudDivisor  Proc near
    push bx
;    
    mov bx,ds:ups_device_type
    add bx,bx
    add bx,OFFSET BaudDivisorTab
    cmp bx,OFFSET gbdend
    jbe gbdCall
;
    mov bx,OFFSET gbdend    

gbdCall:
    call word ptr cs:[bx]
;    
    pop bx
    ret
GetBaudDivisor  Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ResetSio
;
;		DESCRIPTION:	Reset SIO
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_sio	PROC near
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,0
    mov es:usd_value,0
    mov es:usd_index,dx
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
    ret
reset_sio Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetLatencyTimer
;
;		DESCRIPTION:	Set latency timer
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_latency_timer	PROC near
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,9
    mov es:usd_value,10
    mov es:usd_index,dx
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
    ret
set_latency_timer Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetBaud
;
;		DESCRIPTION:	Set baudrate
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_baud	PROC near
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,3
;    
    mov ax,word ptr ds:ups_divisor
    mov es:usd_value,ax
;
    mov ax,word ptr ds:ups_divisor+2   
    cmp ds:ups_device_type,DEVICE_TYPE_FT2232C
    jne set_baud_index_ok
;
    shl ax,8
    or ax,dx

set_baud_index_ok:
    mov es:usd_index,ax    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
    ret
set_baud Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetData
;
;		DESCRIPTION:	Set data format
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_data	PROC near
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,4
;    
    mov al,ds:ups_data_bits
    mov ah,ds:ups_parity
;
    cmp ah,'E'
    je set_data_even
;
    cmp ah,'O'
    je set_data_odd

set_data_none:    
    xor ah,ah
    jmp set_data_parity_ok

set_data_even:
    mov ah,2
    jmp set_data_parity_ok

set_data_odd:
    mov ah,1

set_data_parity_ok:
    mov cl,ds:ups_stop_bits
    cmp cl,2
    jb set_data_stop_ok
;
    or ah,10h

set_data_stop_ok:
    mov es:usd_value,ax
    mov es:usd_index,dx
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
    ret
set_data Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			open_com
;
;		description:	Open a serial port
;
;		PARAMETERS:		DS      Port selector
;		        		ES		Device selector
;						AH		# of data bits
;						BL		# of stop bits
;						BH		parity
;						ECX		baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com	Proc far
    push ds
    pushad
;
    mov ds:ups_timer_active,0
    mov ds:ups_data_bits,ah
    mov ds:ups_stop_bits,bl
    mov ds:ups_parity,bh
;    
    mov ax,es:uds_device_type
    mov ds:ups_device_type,ax
    call GetBaudDivisor
    jc open_com_done
;
    mov ds:ups_divisor,ecx
;
    CreateWait
    mov ds:ups_control_wait,bx
;
    mov bx,ds:ups_controller
    mov ax,ds:ups_device
    xor dl,dl
    OpenUsbPipe
    mov ds:ups_control_pipe,bx
;
    mov ax,ds:ups_control_pipe
    mov bx,ds:ups_control_wait
    movzx ecx,bx
    AddWaitForUsbPipe
;    
    call reset_sio
    jc open_com_done
;
    call set_latency_timer
    jc open_com_done   
;    
    call set_data
    jc open_com_done
;
    call set_baud
    jc open_com_done
;    
    call set_dtr    
    call set_rts
    call disable_cts
;    
    mov ds:ups_device_sel,es
    mov dx,ds
    mov ax,es
    mov ds,ax
    EnterSection ds:uds_section
    mov ds:uds_port_sel,dx
    LeaveSection ds:uds_section       
;
    mov ax,usbcom_data_sel
    mov ds,ax    
    mov bx,ds:sd_thread
    Signal    
    clc

open_com_done:
    popad
    pop ds
	ret
open_com	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			close_com
;
;		description:	Close serial port
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com	Proc far
    push ds
    push bx
;
    mov al,ds:ups_timer_active
    or al,al
    jz ccTimerClosed
;
    mov bx,ds
    StopTimer
    mov ds:ups_timer_active,0
    
ccTimerClosed:   
    call reset_rts
    call reset_dtr
;    
    mov bx,ds:ups_control_wait
    CloseWait
;
    mov bx,ds:ups_control_pipe
    CloseUsbPipe    
;    
    mov ax,ds
    mov bx,ds:ups_device_sel
    or bx,bx
    jz ccNoDevice
;
    mov ds,bx    
    EnterSection ds:uds_section
    mov ds:uds_port_sel,0
    LeaveSection ds:uds_section       

ccNoDevice:    
    mov ds,ax
    mov ds:ups_device_sel,0
;
    mov bx,usbcom_data_sel
    mov ds,bx
    mov bx,ds:sd_thread
    Signal    
;
    pop bx
    pop ds    
	ret
close_com	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			EnableCts
;
;		DESCRIPTION:	Enable CTS signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_cts	PROC far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
    mov dx,200h
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,2
    mov es:usd_value,0
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
    ret
enable_cts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DisableCts
;
;		DESCRIPTION:	Disable CTS signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_cts	PROC far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,2
    mov es:usd_value,0
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
    ret
disable_cts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			EnableAutoRts
;
;		DESCRIPTION:	Enable automatic RTS on send
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_auto_rts	PROC far
    ret
enable_auto_rts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DisableAutoRts
;
;		DESCRIPTION:	Disable automatic RTS on send
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_auto_rts	PROC far
    ret
disable_auto_rts Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FlushCom
;
;		DESCRIPTION:	Flush com
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

flush_com	PROC far
    ret
flush_com Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			start_send
;
;		description:	Start send
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send	PROC far
    call StartSendTimer
	ret
start_send	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			set_dtr
;
;		description:	Set DTR signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dtr	Proc far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,1
    mov es:usd_value,101h
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
	ret
set_dtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			reset_dtr
;
;		description:	Reset DTR signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_dtr	Proc far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,1
    mov es:usd_value,100h
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;    
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
	ret
reset_dtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			set_rts
;
;		description:	Set RTS signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_rts	Proc far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,1
    mov es:usd_value,202h
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
	ret
set_rts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			reset_rts
;
;		description:	Reset RTS signal
;
;		PARAMETERS:		DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_rts	Proc far
    push es
    pushad
;
    mov bx,ds:ups_control_pipe
    mov dx,ds:ups_index
    inc dx
;    
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,40h
    mov es:usd_req,1
    mov es:usd_value,200h
    mov es:usd_index,dx    
    mov es:usd_len,0
    xor di,di
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:ups_control_wait
    WaitWithTimeout
;
    mov bx,ds:ups_control_pipe
    IsUsbPipeIdle
    cmc
    pushf
    UnlockUsbPipe
    popf
;
    popad
    pop es    
	ret
reset_rts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        create_port
;
;		description:	Create port selector
;
;		RETURNS:		ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_tab:
pt00 DW OFFSET open_com,   	        usbcom_code_sel
pt01 DW OFFSET close_com,           usbcom_code_sel
pt02 DW OFFSET enable_cts,          usbcom_code_sel
pt03 DW OFFSET disable_cts,         usbcom_code_sel
pt04 DW OFFSET set_dtr,             usbcom_code_sel
pt05 DW OFFSET reset_dtr,           usbcom_code_sel
pt06 DW OFFSET set_rts,             usbcom_code_sel
pt07 DW OFFSET reset_rts,           usbcom_code_sel
pt08 DW OFFSET enable_auto_rts,     usbcom_code_sel
pt09 DW OFFSET disable_auto_rts,    usbcom_code_sel
pt10 DW OFFSET flush_com,           usbcom_code_sel
pt11 DW OFFSET start_send,          usbcom_code_sel

create_port	Proc far
    pushad
;
    mov eax,SIZE usbcom_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET port_tab
    xor di,di
    mov cx,12
    rep movs dword ptr es:[di],cs:[si]
;
    movzx ax,ds:uds_interface
    mov es:ups_index,ax    
    mov ax,ds:cd_controller
    mov es:ups_controller,ax
    mov ax,ds:cd_device
    mov es:ups_device,ax
;        
    popad
	ret
create_port	Endp


PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    OpenPort
;
;		DESCRIPTION:    Open port
;
;       PARAMETERS:     FS      Usbcom_data_sel
;                       DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPort    Proc near
    movzx eax,ds:uds_maxsize
    AllocateSmallGlobalMem
    mov ds:uds_in_buffer,es
;
    movzx eax,ds:uds_maxsize
    inc eax
    AllocateSmallGlobalMem
    mov ds:uds_out_buffer,es
;
    mov bx,ds:cd_controller
    mov ax,ds:cd_device
    mov dl,ds:uds_bulk_in
    OpenUsbPipe
    mov ds:uds_in_handle,bx
;
    CreateUsbReq
    mov ds:uds_in_req,bx    
    mov cx,ds:uds_maxsize
    mov es,ds:uds_in_buffer
    AddReadUsbDataReq
;
    mov bx,ds:cd_controller
    mov ax,ds:cd_device
    mov dl,ds:uds_bulk_out
    OpenUsbPipe    
    mov ds:uds_out_handle,bx
;
    CreateUsbReq
    mov ds:uds_out_req,bx
    mov cx,ds:uds_maxsize
    mov es,ds:uds_out_buffer
    AddWriteUsbDataReq
    ret
OpenPort    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    ClosePort
;
;		DESCRIPTION:    Close port
;
;       PARAMETERS:     FS      Usbcom_data_sel
;                       DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePort    Proc near
    xor ax,ax
    mov es,ax
;    
    mov bx,ds:uds_in_req
    CloseUsbReq
    mov ds:uds_in_req,0
;
    mov bx,ds:uds_in_handle
    CloseUsbPipe    
    mov ds:uds_in_handle,0
;
    mov bx,ds:uds_out_req
    CloseUsbReq
    mov ds:uds_out_req,0
;
    mov bx,ds:uds_out_handle
    CloseUsbPipe    
    mov ds:uds_out_handle,0
;
    mov es,ds:uds_in_buffer
    FreeMem    
    mov ds:uds_in_buffer,0
;
    mov es,ds:uds_out_buffer
    FreeMem    
    mov ds:uds_out_buffer,0
    ret
ClosePort   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    PollRead
;
;		DESCRIPTION:    Poll input-buffer
;
;       PARAMETERS:     FS      Usbcom_data_sel
;                       DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollRead    Proc near
    push ds
    push fs
    mov fs,ds:uds_in_buffer
    mov ds,ds:uds_port_sel
	mov es,ds:rec_buf
	mov si,2

prGetLoop:
	lods byte ptr fs:[si]
	cli
	mov dx,ds:rec_count
	cmp dx,ds:rec_size
	je prSignal
;	
	inc dx
	mov ds:rec_count,dx
	mov bx,ds:rec_tail
	mov es:[bx],al
	inc bx
	cmp bx,ds:rec_size
	jnz prWrapOk
;
	xor bx,bx
	
prWrapOk:
	mov ds:rec_tail,bx
	sti
    loop prGetLoop

prSignal:
    sti
    mov bx,ds:avail_obj
    or bx,bx
    jz prDone
;
    mov es,bx
    SignalWait
	mov ds:avail_obj,0
	
prDone:
    pop fs
    pop ds
    ret
PollRead    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    PollWrite
;
;		DESCRIPTION:    Poll output-buffer
;
;       PARAMETERS:     FS      Usbcom_data_sel
;                       DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollWrite    Proc near
    push ds
    push fs
;   
    mov bp,ds:uds_maxsize
    mov es,ds:uds_out_buffer
    mov ds,ds:uds_port_sel
    mov al,ds:ups_timer_active
    or al,al
    jnz pwDone
;    
    xor di,di
	mov fs,ds:send_buf
    cmp ds:uds_device_type,DEVICE_TYPE_SIO
    jne pwStartOk
;
    mov di,1

pwStartOk:
    xor cx,cx
	mov dx,ds:send_count
	or dx,dx
	jz pwDone

pwLoop:
    cli
	mov dx,ds:send_count
	or dx,dx
	jz pwSend
;	
   	dec dx
	mov ds:send_count,dx
	mov bx,ds:send_head
	mov al,fs:[bx]
	stosb
	inc bx
	cmp bx,ds:send_size
	jnz pwWrapOk
;	
	xor bx,bx

pwWrapOk:
	mov ds:send_head,bx
	sti
;
    inc cx
    cmp cx,bp
    jb pwLoop

pwSend:
    sti
    mov ax,ds:send_size    
    or ax,ax
    jz pwTimerOk
;
    call StartSendTimer        

pwTimerOk:
    cmp ds:uds_device_type,DEVICE_TYPE_SIO
    jne pwDone
;
    mov al,cl
    shl al,2
    or al,1
    mov es:[0],al    
    inc cx

pwDone:
    pop fs
    pop ds    
    ret
PollWrite   Endp    
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    HandleDevice
;
;		DESCRIPTION:    Handle device
;
;       PARAMETERS:     FS      Usbcom_data_sel
;                       DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleDevice    Proc near
    push ds
;
    mov ax,ds:uds_port_sel
    or ax,ax
    jz hdClosed

hdOpen:
    mov bx,ds:uds_in_req
    or bx,bx
    jnz hdIsOpen
;
    mov al,ds:uds_delete
    or al,al
    jnz hdDone
;
    call OpenPort        

hdIsOpen:    
    mov bx,ds:uds_in_req
    IsUsbReqStarted
    jnc hdOpenOk
;
    StartUsbReq

hdOpenOk:    
    mov bx,ds:uds_in_req
    IsUsbReqReady
    jc hdReadDone
;
    GetUsbReqData
    UsbReqDone
    StartUsbReq
    sub cx,2
    jbe hdReadDone
;
    call PollRead

hdReadDone:
    mov bx,ds:uds_out_req
    IsUsbReqStarted
    jc hdCheckWrite
;    
    IsUsbReqReady
    jc hdDone
;
    UsbReqDone
    push ds
    mov ds,ds:uds_port_sel
    mov bx,ds:send_wait
    pop ds
    or bx,bx
    jz hdCheckWrite
;    
    Signal

hdCheckWrite:
    call PollWrite
    or cx,cx
    jz hdDone
;
    mov bx,ds:uds_out_req
    StartUsbReq
    jmp hdDone

hdClosed:
    mov bx,ds:uds_in_req
    or bx,bx
    jz hdDone
;    
    IsUsbReqReady
    jc hdIsClosed
;
    UsbReqDone

hdIsClosed:
    mov al,ds:uds_delete
    or al,al
    jz hdDone
;
    call ClosePort
    
hdDone:
    pop ds
    ret
HandleDevice    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UsbComThread
;
;		DESCRIPTION:    Com-port handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usbcom_thread_name  DB 'USB Com', 0

usbcom_thread:
    mov ax,usbcom_data_sel
    mov fs,ax
    GetThread
    mov fs:sd_thread,ax

utLoop:
    WaitForSignal
;
    mov cx,fs:sd_ports
    or cx,cx
    jz utEnd
;
    xor si,si

utDevLoop:
    mov ax,fs:[si].sd_port_arr
    or ax,ax
    jz utDevNext
;
    mov ds,ax
    push cx
    push si
;
    EnterSection ds:uds_section
    call HandleDevice
    LeaveSection ds:uds_section
;
    pop si
    pop cx
    
utDevNext:
    add si,2
    loop utDevLoop
;        
    jmp utLoop

utEnd:
    retf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddPort
;
;		DESCRIPTION:    Add port to list of available ports
;
;       PARAMETERS:     AL      Device address
;                       BX      Controller id
;                       DX      Device type
;                       ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPort Proc near
    push ds
    push es
    pushad
;    
    push dx
    push di
    mov dx,usbcom_data_sel
    mov ds,dx
    mov dx,ds:sd_thread
    or dx,dx
    jnz apThreadStarted
;
	mov ds:sd_thread,-1
    push ds
    push es
    push ax
    push si
    push di    
;    
	mov dx,cs
	mov ds,dx
	mov es,dx
	mov di,OFFSET usbcom_thread_name
	mov si,OFFSET usbcom_thread
	mov ax,2
	mov cx,100h
	CreateThread
;
    pop di
    pop si
    pop ax
    pop es
    pop ds
    	    
apThreadStarted:
    xor dx,dx
    movzx cx,es:[di].uid_len
    add di,cx

apDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne apDescrDone
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,2
    jne apDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz apBulkIn
;
    and cl,0Fh
    mov dl,cl
    jmp apDescrNext

apBulkIn:
    and cl,0Fh
    mov dh,cl
    mov bp,es:[di].ued_maxsize
    
apDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb apDescrLoop    
    	
apDescrDone:
    mov cx,dx
    pop di
    pop dx
;    
    or cl,cl
    jz apDone
;
    or ch,ch
    jz apDone
;        
    push cx
    mov cl,es:[di].uid_id
    push ax
    mov eax,SIZE usbcom_device_struc
	AllocateSmallGlobalMem
	pop ax
    mov es:uds_interface,cl
	mov es:uds_device_type,dx
	pop dx
	mov es:uds_port_sel,0
	mov es:uds_bulk_in,dh
	mov es:uds_bulk_out,dl
	mov es:uds_maxsize,bp
	mov es:uds_in_handle,0
	mov es:uds_in_req,0
	mov es:uds_in_buffer,0
	mov es:uds_out_handle,0
	mov es:uds_out_req,0
	mov es:uds_out_buffer,0
	mov es:uds_delete,0
	InitSection es:uds_section
;
    mov si,ds:sd_ports
    add si,si
    mov ds:[si].sd_port_arr,es
    inc ds:sd_ports
;
    mov dx,es
    mov ds,dx
    mov dx,cs
    mov es,dx
    mov di,OFFSET create_port
    movzx dx,al
    mov ax,bx
    AddComPort

apDone:
    popad
    pop es
    pop ds	
    ret
AddPort Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        AttachFTDI
;
;		description:	Attach FTDI devices
;
;		Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ftTab:
ft00	DW 0403h,	0F2D0h	; ACTZWAVE
ft01	DW 0403h,	0FC60h	; IRTRANS
ft02	DW 0403h,	0D070h	; IPLft
ft03	DW 0403h,	08372h	; SIO
ft04	DW 0403h,	06001h	; 8U232AM
ft05	DW 0403h,	06006h	; 8U232AM_ALT
ft06	DW 0403h,	06010h	; 8U2232C
ft07	DW 0403h,	0FA10h	; RELAIS
ft08	DW 1209h,	01002h	; IOBOARD
ft09	DW 1209h,	01006h	; MINI_IOBOARD
ft0A	DW 0403h,	0FC08h	; XF_632
ft0B	DW 0403h,	0FC09h	; XF_634
ft0C	DW 0403h,	0FC0Ah	; XF_547
ft0D	DW 0403h,	0FC0Bh	; XF_633
ft0E	DW 0403h,	0FC0Ch	; XF_631
ft0F	DW 0403h,	0FC0Dh	; XF_635
ft10	DW 0403h,	0FC0Eh	; XF_640
ft11	DW 0403h,	0FC0Fh	; XF_642
ft12	DW 0403h,	0FC82h	; DSS20
ft13	DW 0DCDh,	00001h	; NF_RIC
ft14	DW 0403h,	0FE38h	; VNHCOCftB_D
ft15	DW 0403h,	0FA00h	; MTXORB_0
ft16	DW 0403h,	0FA01h	; MTXORB_1
ft17	DW 0403h,	0FA02h	; MTXORB_2
ft18	DW 0403h,	0FA03h	; MTXORB_3
ft19	DW 0403h,	0FA04h	; MTXORB_4
ft1A	DW 0403h,	0FA05h	; MTXORB_5
ft1B	DW 0403h,	0FA06h	; MTXORB_6
ft1C	DW 0403h,	0F0C0h	; PERLE_ULTRAPORT
ft1D	DW 0403h,	0F208h	; PIEGROUP
ft1E	DW 0C52h,	02101h	; Sealevel
ft1F	DW 0C52h,	02102h	; Sealevel
ft20	DW 0C52h,	02103h	; Sealevel
ft21	DW 0C52h,	02104h	; Sealevel
ft22	DW 0C52h,	02211h	; Sealevel
ft23	DW 0C52h,	02221h	; Sealevel
ft24	DW 0C52h,	02212h	; Sealevel
ft25	DW 0C52h,	02222h	; Sealevel
ft26	DW 0C52h,	02213h	; Sealevel
ft27	DW 0C52h,	02223h	; Sealevel
ft28	DW 0C52h,	02411h	; Sealevel
ft29	DW 0C52h,	02421h	; Sealevel
ft2A	DW 0C52h,	02431h	; Sealevel
ft2B	DW 0C52h,	02441h	; Sealevel
ft2C	DW 0C52h,	02412h	; Sealevel
ft2D	DW 0C52h,	02422h	; Sealevel
ft2E	DW 0C52h,	02432h	; Sealevel
ft2F	DW 0C52h,	02442h	; Sealevel
ft30	DW 0C52h,	02413h	; Sealevel
ft31	DW 0C52h,	02423h	; Sealevel
ft32	DW 0C52h,	02433h	; Sealevel
ft33	DW 0C52h,	02443h	; Sealevel
ft34	DW 0C52h,	02811h	; Sealevel
ft35	DW 0C52h,	02821h	; Sealevel
ft36	DW 0C52h,	02831h	; Sealevel
ft37	DW 0C52h,	02841h	; Sealevel
ft38	DW 0C52h,	02851h	; Sealevel
ft39	DW 0C52h,	02861h	; Sealevel
ft3A	DW 0C52h,	02871h	; Sealevel
ft3B	DW 0C52h,	02881h	; Sealevel
ft3C	DW 0C52h,	02812h	; Sealevel
ft3D	DW 0C52h,	02822h	; Sealevel
ft3E	DW 0C52h,	02832h	; Sealevel
ft3F	DW 0C52h,	02842h	; Sealevel
ft40	DW 0C52h,	02852h	; Sealevel
ft41	DW 0C52h,	02862h	; Sealevel
ft42	DW 0C52h,	02872h	; Sealevel
ft43	DW 0C52h,	02882h	; Sealevel
ft44	DW 0C52h,	02813h	; Sealevel
ft45	DW 0C52h,	02823h	; Sealevel
ft46	DW 0C52h,	02833h	; Sealevel
ft47	DW 0C52h,	02843h	; Sealevel
ft48	DW 0C52h,	02853h	; Sealevel
ft49	DW 0C52h,	02863h	; Sealevel
ft50	DW 0C52h,	02873h	; Sealevel
ft51	DW 0C52h,	02883h	; Sealevel
ft52	DW 0ACDh,	00300h	; IDTECH_IDT1221U
ft53	DW 0B39h,	00421h	; OCT_ft101
ft54	DW 0403h,	0FA78h	; HE_TIRA1
ft55	DW 0403h,	0F850h	; ftB_UIRT
ft56	DW 0403h,	0FC70h	; PROTEGO_SPECIAL_1
ft57	DW 0403h,	0FC71h	; PROTEGO_R2X0
ft58	DW 0403h,	0FC72h	; PROTEGO_SPECIAL_3
ft59	DW 0403h,	0FC73h	; PROTEGO_SPECIAL_4
ft5A	DW 0403h,	0E808h	; GUDEADS
ft5B	DW 0403h,	0E809h	; GUDEADS
ft5C	DW 0403h,	0E80Ah	; GUDEADS
ft5D	DW 0403h,	0E80Bh	; GUDEADS
ft5E	DW 0403h,	0E80Ch	; GUDEADS
ft5F	DW 0403h,	0E80Dh	; GUDEADS
ft60	DW 0403h,	0E80Eh	; GUDEADS
ft61	DW 0403h,	0E80Fh	; GUDEADS
ft62	DW 0403h,	0E888h	; GUDEADS
ft63	DW 0403h,	0E889h	; GUDEADS
ft64	DW 0403h,	0E88Ah	; GUDEADS
ft65	DW 0403h,	0E88Bh	; GUDEADS
ft66	DW 0403h,	0E88Ch	; GUDEADS
ft67	DW 0403h,	0E88Dh	; GUDEADS
ft68	DW 0403h,	0E88Eh	; GUDEADS
ft69	DW 0403h,	0E88Fh	; GUDEADS
ft6A	DW 0403h,	0FB58h	; ELV_UR100
ft6B	DW 0403h,	0FB5Ah	; ELV_UM100
ft6C	DW 0403h,	0FB5Bh	; ELV_UO100
ft6D	DW 0403h,	0F06Eh	; ELV_ALC8500
ft6E	DW 0403h,	0E6C8h	; PYRAMID
ft6F	DW 0403h,	0F06Fh	; FHZ1000PC
ft70	DW 0403h,	0F448h	; LINX_SDMftBQSS
ft71	DW 0403h,	0F449h	; LINX_MASTERDEVEL2
ft72	DW 0403h,	0F44Ah	; LINX_FUTURE_0
ft73	DW 0403h,	0F44Bh	; LINX_FUTURE_1
ft74	DW 0403h,	0F44Ch	; LINX_FUTURE_2
ft75	DW 0403h,	0F9D0h	; CCSICDU20
ft76	DW 0403h,	0F9D1h	; CCSICDU40
ft77	DW 0403h,	0FAD0h	; INSIDE_ACCESSO
ft78	DW 093Ch,	00601h	; INTREPID_CALUECAN
ft79	DW 093Ch,	00701h	; INTREPID_NEOVI
ft7A	DW 0F94h,	00001h	; FALCOM_TWIST
ft7B	DW 0F94h,	00005h	; FALCOM_SAMBA
ft7C	DW 0403h,	0F680h	; SUUNTO_SPORTS
ft7D	DW 0403h,	0FD60h	; RM_CANVIEW
ft7E	DW 0856h,	0AC01h	; BANDB
ft7F	DW 0856h,	0AC02h	; BANDB
ft80	DW 0856h,	0AC03h	; BANDB
ft81	DW 0403h,	0E520h	; EVER_ECO_PRO
ft82	DW 0403h,	08372h	; 4N_GALXY_DE_0
ft83	DW 0403h,	0F3C0h	; 4N_GALXY_DE_1
ft84	DW 0403h,	0F3C1h	; 4N_GALXY_DE_2
ft85	DW 0403h,	0D388h	; XSENS_CONV_0
ft86	DW 0403h,	0D389h	; XSENS_CONV_1
ft87	DW 0403h,	0D38Ah	; XSENS_CONV_2
ft88	DW 0403h,	0D38Bh	; XSENS_CONV_3
ft89	DW 0403h,	0D38Ch	; XSENS_CONV_4
ft8A	DW 0403h,	0D38Dh	; XSENS_CONV_5
ft8B	DW 0403h,	0D38Eh	; XSENS_CONV_6
ft8C	DW 0403h,	0D38Fh	; XSENS_CONV_7
ft8D	DW 1342h,	00202h	; MOBILITY
ft8E	DW 0403h,	0E548h	; ACTIVE_ROBOTS
ft8F	DW 0403h,	0EEE8h	; MHAM_KW
ft90	DW 0403h,	0EEE9h	; MHAM_YS
ft91	DW 0403h,	0EEEAh	; MHAM_Y6
ft92	DW 0403h,	0EEEBh	; MHAM_Y8
ft93	DW 0403h,	0EEECh	; MHAM_IC
ft94	DW 0403h,	0EEEDh	; MHAM_DB9
ft95	DW 0403h,	0EEEEh	; MHAM_RS232
ft96	DW 0403h,	0EEEFh	; MHAM_Y9
ft97	DW 0403h,	0EC88h	; TERATRONIK_VCP
ft98	DW 0403h,	0EC89h	; TERATRONIK_D2XX
ft99	DW 0DEEEh,	00300h	; EVOLUTION
ft9A	DW 0403h,	0DF28h	; ARTEMIS
ft9B	DW 0403h,	0DF30h	; ATIK_ATK16
ft9C	DW 0403h,	0DF32h	; ATIK_ATK16C
ft9D	DW 0403h,	0DF31h	; ATIK_ATK16HR
ft9E	DW 0403h,	0DF33h	; ATIK_ATK16HRC
ft9F	DW 0D46h,	02020h	; KOBIL_CONV_B1
ftA0	DW 0D46h,	02021h	; KOBIL_CONV_KAAN
ftA1	DW 0D3Ah,	00300h	; POSIFLEX
ftA2	DW 0403h,	0FF20h	; TTftB
ftA3	DW 0403h,	0EA90h	; ECLO_COM_1WIRE
ftA4	DW 0403h,	0DC00h	; WESTREX_777
ftA5	DW 0403h,	0DC01h	; WESTREX_8900F
ftA6	DW 0403h,	0FA88h	; PCDJ_DAC2
ftA7	DW 0403h,	0C7D0h	; RRCIRKITS
ftA8	DW 0403h,	0C991h	; ASK_RDR400
ftA9	DW 0C26h,	00004h	; ICOM_ID1
ftAA	DW 5050h,	00400h	; PAPOUCH
ftAB	DW 0403h,	0DD20h	; ACG_HFDUAL

AttachFTDI  Proc near
    push es
;    
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor di,di
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne aftDone
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,0ACh
    mov bp,OFFSET ftTab

aftLoop:
    cmp si,cs:[bp]
    jne aftNext
;
    cmp di,cs:[bp+2]
    je aftFound

aftNext:
    add bp,4
    loop aftLoop        
;
    jmp aftDone    

aftFound:
    mov si,es:udd_device
;    
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz aftDone
;
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    jc aftDone
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

aftDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne aftDescrNext
;
    cmp si,200h
    jae aftNotSio
; 
    mov dx,DEVICE_TYPE_SIO
    call AddPort
    jmp aftDone

aftNotSio:
    cmp si,400h
    jae aftNotAm
;
    mov dx,DEVICE_TYPE_FT232AM
    call AddPort
    jmp aftDone

aftNotAm:
    mov cl,es:ucd_interface_count
    cmp cl,1
    ja aftMore
;
    mov dx,DEVICE_TYPE_FT232BM
    call AddPort
    jmp aftDone

aftMore:
    mov dx,DEVICE_TYPE_FT2232C 
    call AddPort

aftDescrNext:
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb aftDescrLoop    
    
aftDone:
    FreeMem
;
    pop es    
    ret
AttachFTDI  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        AttachPL2303
;
;		description:	Attach PL2303 devices
;
;		Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

plTab:
pl00	DW 06FBh,	02303h	; PL2303
pl01	DW 06FBh,	004BBh	; PL2303
pl02	DW 06FBh,	0AAA0h	; PL2303
pl03	DW 06FBh,	0AAA2h	; PL2303
pl04	DW 0557h,	02008h	; ATEN
pl05	DW 0547h,	02008h	; ATEN
pl06	DW 04BBh,	00A03h	; ATEN
pl07	DW 056Eh,	05003h	; ELCOM
pl08	DW 056Eh,	05004h	; ELCOM
pl09	DW 0EBAh,	01080h	; ITEGNO
pl0A	DW 0EBAh,	02080h	; ITEGNO
pl0B	DW 0DF7h,	00620h	; MA620
pl0C	DW 0584h,	0B000h	; RATOC
pl0D	DW 2478h,	02008h	; TRIPP
pl0E	DW 1453h,	04026h	; RADIOSHACK
pl0F	DW 0731h,	00528h	; DCU10
pl10	DW 6189h,	02068h	; SITECOM
pl11	DW 11F7h,	002DFh	; ALCATEL
pl12	DW 04E8h,	08001h	; SAMSUNG
pl13	DW 11F5h,	00001h	; SIEMENS
pl14	DW 11F5h,	00003h	; SIEMENS
pl15	DW 11F5h,	00004h	; SIEMENS
pl16	DW 0745h,	00001h	; SYNTECH
pl17	DW 078Bh,	01234h	; NOKIA
pl18	DW 10B5h,	0AC70h	; CA-42
pl19	DW 079Bh,	00027h	; SAGEM
pl1A	DW 0413h,	02101h	; LEADTEK
pl1B	DW 0E55h,	0110Bh	; SPEEDDRAGON
pl1C	DW 0EA0h,	06858h	; OTI
 
AttachPL2303  Proc near
    push es
;    
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor di,di
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne aplDone
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,01Dh
    mov bp,OFFSET plTab

aplLoop:
    cmp si,cs:[bp]
    jne aplNext
;
    cmp di,cs:[bp+2]
    je aplFound

aplNext:
    add bp,4
    loop aplLoop        
;
    jmp aplDone    

aplFound:
    int 3
    mov si,es:udd_device
;    
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz aplDone
;
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    jc aplDone
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

aplDescrLoop:
    mov cl,es:[di].udd_type

aplDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb aplDescrLoop    
    
aplDone:
    FreeMem
;
    pop es    
    ret
AttachPL2303  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        usb_attach
;
;		description:	USB attach callback
;
;		Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_attach  Proc far
    call AttachFTDI
    call AttachPL2303
    ret
usb_attach  Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        usb_detach
;
;		description:	USB detach callback
;
;		Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    int 3
    ret
usb_detach  Endp

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
	mov bx,usbcom_code_sel
	InitDevice
;
	mov eax,SIZE serial_data
	mov bx,usbcom_data_sel
	AllocateFixedSystemMem
	mov cx,SIZE serial_data
	xor di,di
	xor al,al
	rep stosb
	InitSection es:sd_section
	mov es:sd_ports,0
	mov es:sd_thread,0
;	
	mov ax,cs
	mov ds,ax
	mov es,ax
;
    mov di,OFFSET usb_attach
    HookUsbAttach
;
    mov di,OFFSET usb_detach
    HookUsbDetach
;
	popa
	pop es
	pop ds	
	ret
init	Endp

code	ENDS

	END init
