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
;		NAME:			CreateDefaultControl
;
;		description:	Create default control-pipe
;
;       parameters:     AL      Future device address
;                       DS      USB device selector
;
;       RETURNS:        FS      Pipe control selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDefaultControl    Proc near    
    push cx
    push edi
;    
    push ax
    call ds:create_control_proc
;    
    mov fs:usbp_function_sel,ds
    mov fs:usbp_address,0
    mov fs:usbp_endpoint,0
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_CONTROL
    mov fs:usbp_maxlen,8
;    
    mov cx,8
    call ds:allocate_buf_proc
    mov es:[edi].usd_type,0
    mov es:[edi].usd_req,SET_ADDRESS
    pop ax
;
    push ax
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,0
    call ds:add_setup_proc
    call ds:add_status_in_proc
    call ds:issue_transfer_proc
    pop ax
;  
    mov fs:usbp_address,al
    call ds:wait_for_completion_proc
    pushf
    call ds:delete_queue_proc
    popf
;
    pop edi
    pop cx
    ret
CreateDefaultControl    Endp    

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDeviceDescr
;
;		description:	Get device-descriptor
;
;       parameters:     FS      Pipe control selector
;                       CX      Size of requested data
;                       ES:EDI  Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDeviceDescr    Proc near    
    push es
    push cx
    push edi
;    
    push cx
    mov cx,8
    call ds:allocate_buf_proc
    mov es:[edi].usd_type,80h
    mov es:[edi].usd_req,GET_DESCR
    mov es:[edi].usd_value,100h
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,1024
    call ds:add_setup_proc
    pop cx
;    
    mov ax,cx
    xor dx,dx
    mov cx,fs:usbp_maxlen
    div ax
    mov cx,ax
    push dx
    or cx,cx
    jz gddLastPart
    
gddLoop:
    push cx
    mov cx,fs:usbp_maxlen
    call ds:allocate_buf_proc
    call ds:add_in_proc
    pop cx
    loop gddLoop

gddLastPart:
    pop cx
    or cx,cx
    jz gddInDone
;    
    call ds:allocate_buf_proc
    call ds:add_in_proc

gddInDone:    
    call ds:add_status_out_proc
    call ds:issue_transfer_proc
    call ds:wait_for_completion_proc
;
    pop edi
    pop cx
    pop es
;    
    pushf
    call ds:get_data_proc
    call ds:delete_queue_proc
    popf
    ret
GetDeviceDescr    Endp    

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
    int 3
    call CreateDefaultControl
    jc nuaDone
;
    mov eax,8
    AllocateSmallGlobalMem
    xor edi,edi
    mov cx,8
    call GetDeviceDescr
    movzx ax,es:udd_maxlen
    mov fs:usbp_maxlen,ax
    movzx eax,es:udd_len
    FreeMem
;
    AllocateSmallGlobalMem
    xor edi,edi
    mov cx,ax
    call GetDeviceDescr
    
nuaDone:
    pop di
    pop cx
    pop bx
    pop ax
    pop es
    pop fs
    ret
notify_usb_attach   Endp

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
