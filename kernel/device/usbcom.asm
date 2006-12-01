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
; USBCOM.ASM
; USB based serial port device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME usbcom

GateSize = 16

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\usb.inc
include ..\os\com.inc

MAX_PORTS       = 16

usbcom_port_struc	STRUC

ups_base_struc  com_port_struc <>

usbcom_port_struc	ENDS

usbcom_device_struc   STRUC

uds_base_struc    com_device_struc <>

usbcom_device_struc   ENDS

serial_data STRUC

sd_ports    DW ?
sd_port_arr DW MAX_PORTS DUP(?)

serial_data ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386c

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
    push eax
    push cx
    push si
    push di
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
    pop di
    pop si
    pop cx
    pop eax
	ret
create_port	Endp
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
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov eax,SIZE serial_data
	mov bx,usbcom_data_sel
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
