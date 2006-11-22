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
; PCI.ASM
; PCI support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME usb

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE usb.inc


GET_STATUS = 0
CLEAR_FEATURE = 1
SET_FEATURE = 3
SET_ADDRESS = 5
GET_DESCR = 6
SET_DESCR = 7
GET_CONFIG = 8
SET_CONFIG = 9
GET_INTERFACE = 10
SET_INTERFACE = 11
SYNC_FRAME = 12

	.386p

data    STRUC

ddumy   DW ?

data    ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitUsbDevice
;
;		description:	Init USB device selector
;
;       parameters:     DS      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_usb_device_name DB 'Init USB Device', 0

init_usb_device	Proc far
    push es
    push ax
    push cx
    push di
;
    mov ax,ds
    mov es,ax
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usb_port_sel_arr
    xor ax,ax
    rep stosw
;
    mov cx,128
    mov di,OFFSET usb_addr_arr
    xor ax,ax
    rep stosw
;
    pop di
    pop cx
    pop ax
    pop es
    ret
init_usb_device   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NotifyUsbAttach
;
;		description:	Notify USB attach event
;
;       parameters:     AL      Usb port
;                       DS      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_usb_attach_name DB 'Notify USB Attach', 0

notify_usb_attach	Proc far
    push fs
    push es
    push ax
    push bx
    push cx
    push di
;    
    movzx bx,al
    add bx,bx
    mov ax,ds
    mov es,ax
;
    mov di,OFFSET usb_addr_arr
    mov cx,128
    add di,2
    xor ax,ax
    repnz scasw
    sub di,2
;
    mov eax,SIZE usb_function_struc
    AllocateSmallGlobalMem
    mov ds:[di],es
    mov ds:[bx].usb_port_sel_arr,es
    sub di,OFFSET usb_addr_arr
    shr di,1
    mov ax,di
    mov es:usbf_address,al
;
    push ax
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usbf_port_sel_arr    
    xor ax,ax
    rep stosw
    pop ax
;    
    push ax
    call ds:create_control_proc
;    
    mov fs:usbp_function_sel,ds
    mov fs:usbp_address,0
    mov fs:usbp_endpoint,0
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_CONTROL
    mov fs:usbp_maxlen,64
;    
    call ds:start_queue_proc
    int 3
    mov cx,8
    call ds:allocate_buf_proc
    mov es:[edi].usd_type,0
    mov es:[edi].usd_req,SET_ADDRESS
    movzx ax,fs:usbp_address
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,0
    call ds:add_setup_proc
    call ds:add_status_proc
    call ds:issue_transfer_proc
    pop ax
    mov fs:usbp_address,al
;
    pop di
    pop cx
    pop bx
    pop ax
    pop es
    pop fs
    ret
notify_usb_attach   Endp

usb_setup_data  STRUC

usd_type        DB ?
usd_req         DB ?
usd_value       DW ?
usd_index       DW ?
usd_len         DW ?

usb_setup_data  ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	INIT PCI DEVICE
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
	mov bx,usb_code_sel
	InitDevice
;
	mov eax,SIZE data
	mov bx,usb_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov es,bx
	mov cx,ax
	mov al,al
	xor di,di
	rep stosb
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET init_usb_device
	mov di,OFFSET init_usb_device_name
	xor cl,cl
	mov ax,init_usb_device_nr
	RegisterOsGate
;
	mov si,OFFSET notify_usb_attach
	mov di,OFFSET notify_usb_attach_name
	xor cl,cl
	mov ax,notify_usb_attach_nr
	RegisterOsGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
