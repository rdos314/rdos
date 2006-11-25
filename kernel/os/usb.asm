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

usb_dev_count   DW ?
usb_dev_arr     DW 256 DUP(?)

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
    push ds
    push es
    push ax
    push bx
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
    mov ax,usb_data_sel
    mov ds,ax
    mov bx,ds:usb_dev_count
    add bx,bx
    mov ds:[bx].usb_dev_arr,es
    inc ds:usb_dev_count
;
    pop di
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
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
;                       ES      Function selector
;
;       RETURNS:        FS      Pipe control selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDefaultControl    Proc near    
    push es
    push cx
    push edi
;    
    push ax
    call ds:create_control_proc
;    
    mov es:usbf_in_endpoint_arr,fs
    mov es:usbf_out_endpoint_arr,fs
;    
    mov fs:usbp_function_sel,ds
    mov fs:usbp_address,0
    mov fs:usbp_endpoint,0
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_CONTROL
    mov fs:usbp_maxlen,8
    mov fs:usbp_device_sel,0
;    
    mov eax,8
    AllocateSmallGlobalMem
    xor edi,edi
    mov es:usd_type,0
    mov es:usd_req,SET_ADDRESS
    pop ax
;
    push ax
    mov es:usd_value,ax
    mov es:usd_index,0
    mov es:usd_len,0
    mov cx,8
    call ds:add_setup_proc
    call ds:add_status_in_proc
    call ds:issue_transfer_proc
    pop ax
;  
    mov fs:usbp_address,al
    call ds:wait_for_completion_proc
    pushf
    call ds:delete_queue_proc
    FreeMem
    popf
;
    pop edi
    pop cx
    pop es
    ret
CreateDefaultControl    Endp    

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDescr
;
;		description:	Get descriptor
;
;       parameters:     FS      Pipe control selector
;                       AX      Config code
;                       CX      Size of requested data
;                       ES:EDI  Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDescr    Proc near    
    push es
    push cx
    push edi
;    
    push ax
    mov eax,8
    AllocateSmallGlobalMem
    pop ax
    xor edi,edi
    mov es:usd_type,80h
    mov es:usd_req,GET_DESCR
    mov es:usd_value,ax
    mov es:usd_index,0
    mov es:usd_len,cx
;    
    push cx
    mov cx,8
    call ds:add_setup_proc
    pop cx
    call ds:add_in_proc
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
GetDescr    Endp    

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
    push gs
    push fs
    push es
    pushad
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
;    
    mov cx,16
    mov di,OFFSET usbf_in_endpoint_arr
    xor ax,ax
    rep stosw
;    
    mov cx,16
    mov di,OFFSET usbf_out_endpoint_arr
    xor ax,ax
    rep stosw
;    
    pop ax
    call CreateDefaultControl
    jc nuaDone
;
    mov eax,8
    AllocateSmallGlobalMem
    xor edi,edi
    mov cx,8
    mov ax,100h
    call GetDescr
    movzx ax,es:udd_maxlen
    mov fs:usbp_maxlen,ax
    movzx eax,es:udd_len
    FreeMem
;
    AllocateSmallGlobalMem
    xor edi,edi
    mov cx,ax
    mov ax,100h
    call GetDescr
    mov fs:usbp_device_sel,es
    mov ax,es
    mov gs,ax
;
    xor bx,bx

nuaLoop:
    mov eax,8
    AllocateSmallGlobalMem
    xor edi,edi
    mov cx,8
    mov al,bl
    mov ah,2
    call GetDescr
    mov ax,es:ucd_size
    FreeMem
;
    AllocateSmallGlobalMem
    xor edi,edi
    mov cx,ax
    mov al,bl
    mov ah,2
    call GetDescr
    mov di,bx
    add di,di
    mov fs:[di].usbp_config_sel,es
;
    inc bl
    cmp bl,16
    je nuaDone
;    
    cmp bl,gs:udd_configs
    jb nuaLoop
    
nuaDone:
    popad
    pop es
    pop fs
    pop gs
    ret
notify_usb_attach   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetUsbDevice
;
;		description:	Get USB device descriptor
;
;       parameters:     BX          Controller #
;                       AL          Device address (1..128)
;                       (E)CX       Buffer size
;                       ES:(E)DI    Buffer
;
;       Returns:        (E)AX       Size of descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_device_name DB 'Get USB Device', 0

get_usb_device	Proc near
    push ds
    push esi
;
    mov si,usb_data_sel
    mov ds,si
    mov si,ds:usb_dev_count
    cmp bx,si
    jae gudFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz gudFail
;
    mov ds,si
    cmp al,128
    jae gudFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_addr_arr
    or si,si
    jz gudFail
;
    mov ds,si
    mov si,ds:usbf_in_endpoint_arr
    or si,si
    jz gudFail
;
    mov ds,si
    mov si,ds:usbp_device_sel
    or si,si
    jz gudFail
;
    push ecx
    push edi
;
    mov ds,si
    xor esi,esi
    movzx ax,ds:udd_len
    cmp cx,ax
    jbe gudCopy
;
    mov cx,ax

gudCopy:
    movzx ecx,cx
    mov eax,ecx
    rep movs byte ptr es:[edi],[esi]        
;
    pop edi
    pop ecx
    clc
    jmp gudDone

gudFail:
    xor eax,eax    
    stc

gudDone:                
    pop esi
    pop ds
    ret
get_usb_device  Endp

get_usb_device32:
    call get_usb_device
    retf32

get_usb_device16    Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_usb_device
;
    pop edi
    pop ecx
    ret
get_usb_device16    Endp        

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetUsbConfig
;
;		description:	Get USB config descriptor
;
;       parameters:     BX          Controller #
;                       AL          Device address (1..128)
;                       DL          Config #
;                       (E)CX       Buffer size
;                       ES:(E)DI    Buffer
;
;       Returns:        (E)AX       Size of descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_config_name DB 'Get USB Config', 0

get_usb_config	Proc near
    push ds
    push esi
;
    mov si,usb_data_sel
    mov ds,si
    mov si,ds:usb_dev_count
    cmp bx,si
    jae gucFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz gucFail
;
    mov ds,si
    cmp al,128
    jae gucFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_addr_arr
    or si,si
    jz gucFail
;
    mov ds,si
    mov si,ds:usbf_in_endpoint_arr
    or si,si
    jz gucFail
;
    cmp dl,16
    jae gucFail
;    
    mov ds,si
    movzx si,dl
    add si,si
    mov si,ds:[si].usbp_config_sel
    or si,si
    jz gucFail
;
    push ecx
    push edi
;
    mov ds,si
    xor esi,esi
    mov ax,ds:ucd_size
    cmp cx,ax
    jbe gucCopy
;
    mov cx,ax

gucCopy:
    movzx ecx,cx
    mov eax,ecx
    rep movs byte ptr es:[edi],[esi]        
;
    pop edi
    pop ecx
    clc
    jmp gucDone

gucFail:
    xor eax,eax    
    stc

gucDone:                
    pop esi
    pop ds
    ret
get_usb_config  Endp

get_usb_config32:
    call get_usb_config
    retf32

get_usb_config16    Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_usb_config
;
    pop edi
    pop ecx
    ret
get_usb_config16    Endp        

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
	xor al,al
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
	mov bx,OFFSET get_usb_device16
	mov si,OFFSET get_usb_device32
	mov di,OFFSET get_usb_device_name
	mov dx,virt_es_in
	mov ax,get_usb_device_nr
	RegisterUserGate
;
	mov bx,OFFSET get_usb_config16
	mov si,OFFSET get_usb_config32
	mov di,OFFSET get_usb_config_name
	mov dx,virt_es_in
	mov ax,get_usb_config_nr
	RegisterUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
