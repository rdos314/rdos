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
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
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

pipe_handle_struc	STRUC

up_base			handle_header <>
up_func_sel     DW ?
up_pipe_sel		DW ?

pipe_handle_struc	ENDS

pipe_wait_header	STRUC

pw_obj			wait_obj_header <>
pw_func_sel		DW ?
pw_pipe_sel     DW ?

pipe_wait_header	ENDS

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
    mov fs:usbp_usage,1
    InitSection fs:usbp_section
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
;		NAME:		    ClosePipe
;
;		description:    Close pipe
;
;       parameters:     FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePipe   Proc near
    push es
    push ax
    push bx
    push cx
;
    mov ax,fs:usbp_device_sel
    or ax,ax
    jz cpDevOk
;
    mov es,ax
    FreeMem

cpDevOk:
    mov cx,16
    mov bx,OFFSET usbp_config_sel

cpConfLoop:
    mov ax,fs:[bx]
    or ax,ax
    jz cpConfNext
;
    mov es,ax
    FreeMem

cpConfNext:
    add bx,2
    loop cpConfLoop        
;
    call ds:close_pipe_proc
;
    pop cx
    pop bx
    pop ax
    pop es    
    ret
ClosePipe   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CloseEndpoint
;
;		description:    Close endpoint
;
;       parameters:     ES      Device
;                       AL      Endpoint #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseEndpoint   Proc near
    push ax
    push bx
;
    movzx bx,al
    add bx,bx
    mov ax,es:[bx].usbf_in_endpoint_arr
    or ax,ax
    jnz ceClose
;
    mov ax,es:[bx].usbf_out_endpoint_arr
    or ax,ax
    jz ceDone

ceClose:
    push fs
    mov es:[bx].usbf_in_endpoint_arr,0
    mov es:[bx].usbf_out_endpoint_arr,0
    mov fs,ax
    call ClosePipe    
    pop fs
    
ceDone:
    pop bx
    pop ax
    ret
CloseEndpoint   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CloseDevice
;
;		description:    Close device and cleanup resources
;
;       parameters:     ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseDevice Proc near    
    push ax
    push bx
    push cx
    push dx
;    
    mov cx,MAX_USB_HUB_PORTS
    mov bx,OFFSET usbf_port_sel_arr

cdCloseHubLoop:
    mov ax,es:[bx]
    or ax,ax
    jz cdCloseHubNext
;
    push es
    mov es,ax
    call CloseDevice
    pop es            

cdCloseHubNext:
    add bx,2
    loop cdCloseHubLoop
;
    movzx bx,es:usbf_address
    add bx,bx
    mov ds:[bx].usb_addr_arr,0
;
    mov cx,16
    mov bx,OFFSET usbf_in_endpoint_arr
    xor al,al

cdCloseInLoop:
    mov dx,es:[bx]
    or dx,dx
    jz cdCloseInNext
;
    call CloseEndpoint

cdCloseInNext:
    inc al
    add bx,2
    loop cdCloseInLoop           
;
    mov cx,16
    mov bx,OFFSET usbf_out_endpoint_arr
    xor al,al

cdCloseOutLoop:
    mov dx,es:[bx]
    or dx,dx
    jz cdCloseOutNext
;
    call CloseEndpoint

cdCloseOutNext:
    inc al
    add bx,2
    loop cdCloseOutLoop           
;
    FreeMem
;
    pop dx
    pop cx
    pop bx
    pop ax    
    ret
CloseDevice Endp
    
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
;		NAME:			NotifyUsbDetach
;
;		description:	Notify USB detach event
;
;       parameters:     AL      Usb port
;                       DS      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_usb_detach_name DB 'Notify USB Detach', 0

notify_usb_detach	Proc far
    push es
    pushad
;
    movzx bx,al
    add bx,bx
    xor ax,ax
    xchg ax,ds:[bx].usb_port_sel_arr
    or ax,ax
    jz nudDone
;    
    mov es,ax
    call CloseDevice

nudDone:    
    popad
    pop es
    ret
notify_usb_detach   Endp

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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenUsbPipe
;
;		description:	Open USB pipe
;
;       parameters:     BX      Controller #
;                       AL      Device address (1..128)
;                       DL      Pipe #
;
;       RETURNS:        BX      Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_usb_pipe_name DB 'Open USB Pipe', 0

open_usb_pipe    Proc far
    push ds
    push es
    push fs
    push ax
    push cx
    push dx
    push si
;
    mov si,usb_data_sel
    mov ds,si
    mov si,ds:usb_dev_count
    cmp bx,si
    jae oupFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz oupFail
;
    mov es,si
    cmp al,128
    jae oupFail
;    
    movzx si,al
    add si,si
    mov si,es:[si].usb_addr_arr
    or si,si
    jz oupFail
;
    cmp dl,16
    jae oupFail
;    
    mov ds,si
    movzx si,dl
    add si,si
    mov dx,ds:[si].usbf_in_endpoint_arr
    or dx,dx
    jnz oupCreateHandle
;
    mov dx,ds:[si].usbf_out_endpoint_arr
    or dx,dx
    jnz oupCreateHandle    
;
    int 3
    jmp oupFail

oupCreateHandle:    
	mov cx,SIZE pipe_handle_struc
	AllocateHandle
	mov [bx].up_func_sel,es
	mov [bx].up_pipe_sel,dx
	mov [bx].hh_sign,USB_PIPE_HANDLE
	mov bx,[bx].hh_handle
;
    mov fs,dx
    inc fs:usbp_usage
	clc
	jmp oupDone

oupFail:
    stc

oupDone:
    pop si
    pop dx
    pop cx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
open_usb_pipe    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseUsbPipe
;
;		DESCRIPTION:	Close a USB pipe handle
;
;		PARAMETERS:		BX		Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_usb_pipe_name	DB 'Close USB Pipe',0

close_usb_pipe	Proc far
	push ds
	push fs
	push ax
	push bx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc cupDone
;
    push ds
    push bx
	mov fs,ds:[bx].up_pipe_sel
	sub fs:usbp_usage,1
    jnz cupCloseDone
;	
	mov ds,ds:[bx].up_func_sel
	call ClosePipe

cupCloseDone:
	pop bx
	pop ds
	FreeHandle
	clc

cupDone:
	pop bx
	pop ax
	pop fs
	pop ds
	retf32
close_usb_pipe	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_handle
;
;		DESCRIPTION:	BX			USB pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push fs
	push ax
	push bx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc delete_handle_done
;
    push ds
    push bx
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ClosePipe
	pop bx
	pop ds
	FreeHandle
	clc

delete_handle_done:
	pop bx
	pop ax
	pop fs
	pop ds
	ret
delete_handle	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartWaitForPipe
;
;		DESCRIPTION:	Start a wait for pipe
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_pipe	PROC far
    push ds
    push fs
;    
    int 3
    mov fs,es:pw_pipe_sel
    mov fs:usbp_wait_obj,es
    mov ds,es:pw_func_sel
	call ds:issue_transfer_proc
;	
    pop fs
    pop ds        
    ret
start_wait_for_pipe Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopWaitForPipe
;
;		DESCRIPTION:	Stop a wait for pipe
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_pipe	PROC far
    push ds
    mov ds,es:pw_pipe_sel
    mov ds:usbp_wait_obj,0
    pop ds        
    ret
stop_wait_for_pipe Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ClearWaitForPipe
;
;		DESCRIPTION:	Clear wait for pipe
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_wait_for_pipe	PROC far
    ret
clear_wait_for_pipe Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsPipeIdle
;
;		DESCRIPTION:	Check if pipe is idle
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_pipe_idle	PROC far
    int 3
    push ds
    push fs
;
    mov ds,es:pw_func_sel
    mov fs,es:pw_pipe_sel
    call ds:is_pipe_signalled_proc
;
    pop fs
    pop ds        
    ret
is_pipe_idle Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddWaitForPipe
;
;		DESCRIPTION:	Add a wait for pipe
;
;		PARAMETERS:		BX      Wait handle
;                       AX      Pipe handle
;                       ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_pipe_name	DB 'Add Wait For Pipe',0

add_wait_tab:
aw0	DW OFFSET start_wait_for_pipe, 	    usb_code_sel
aw1 DW OFFSET stop_wait_for_pipe,		usb_code_sel
aw2	DW OFFSET clear_wait_for_pipe,	    usb_code_sel
aw3	DW OFFSET is_pipe_idle, 			usb_code_sel

add_wait_for_pipe	PROC far
	push ds
	push es
	push fs
	push eax
	push bx
	push di
;
    push bx
    mov bx,ax
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc add_wait_pop_done
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
    pop bx
;
    mov ax,cs
    mov es,ax
   	mov ax,SIZE pipe_wait_header - SIZE wait_obj_header
    mov di,OFFSET add_wait_tab
    AddWait
    jc add_wait_done
;
    mov es:pw_func_sel,ds
	mov es:pw_pipe_sel,fs
	clc
	jmp add_wait_done

add_wait_pop_done:
    pop bx
    
add_wait_done:
    pop di
    pop bx
    pop eax
    pop fs
    pop es
    pop ds
	retf32
add_wait_for_pipe	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LockUsbPipe
;
;		DESCRIPTION:	Lock USB pipe
;
;		PARAMETERS:		BX		    Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_usb_pipe_name	DB 'Lock USB Pipe',0

lock_usb_pipe   Proc far
	push ds
	push ax
	push bx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc lupDone
;
    mov ds,ds:[bx].up_pipe_sel
    EnterSection ds:usbp_section

lupDone:
	pop bx
	pop ax
	pop ds
    retf32
lock_usb_pipe   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UnlockUsbPipe
;
;		DESCRIPTION:	Unlock USB pipe
;
;		PARAMETERS:		BX		    Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_usb_pipe_name	DB 'Unlock USB Pipe',0

unlock_usb_pipe   Proc far
	push ds
	push fs
	push ax
	push bx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc uupDone
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:delete_queue_proc
	mov ax,fs
	mov ds,ax
    LeaveSection ds:usbp_section

uupDone:
	pop bx
	pop ax
	pop fs
	pop ds
    retf32
unlock_usb_pipe   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteUsbControl
;
;		DESCRIPTION:	Write USB control
;
;		PARAMETERS:		BX		    Pipe handle
;                       CX          Size of data to request
;                       ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_usb_control_name	DB 'Write USB Control',0

write_usb_control16	Proc far
	push ds
	push fs
	push ax
	push bx
	push cx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc wucDone16
;
    movzx edi,di
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:add_setup_proc

wucDone16:
    pop cx
	pop bx
	pop ax
	pop fs
	pop ds
	ret
write_usb_control16	Endp

write_usb_control32	Proc far
	push ds
	push fs
	push ax
	push bx
	push cx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc wucDone32
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:add_setup_proc

wucDone32:
    pop cx
	pop bx
	pop ax
	pop fs
	pop ds
	retf32
write_usb_control32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReqUsbData
;
;		DESCRIPTION:	Setup request for input data on pipe
;
;		PARAMETERS:		BX		Pipe handle
;                       CX      Size of data to request
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_usb_data_name	DB 'Request USB Data',0

req_usb_data	Proc far
	push ds
	push fs
	push ax
	push bx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc rudDone
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:add_in_proc

rudDone:
	pop bx
	pop ax
	pop fs
	pop ds
	retf32
req_usb_data	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetUsbData
;
;		DESCRIPTION:	Get data from previous input req
;
;		PARAMETERS:		BX		    Pipe handle
;                       CX          Size of data to request
;                       ES:(E)DI    Buffer
;
;       RETURNS:        AX          Actual size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_data_name	DB 'Get USB Data',0

get_usb_data16	Proc far
	push ds
	push fs
	push bx
	push cx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc gudDone16
;
    movzx edi,di
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:get_data_proc
	mov ax,cx

gudDone16:
    pop cx
	pop bx
	pop fs
	pop ds
	ret
get_usb_data16	Endp

get_usb_data32	Proc far
	push ds
	push fs
	push bx
	push cx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc gudDone32
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:get_data_proc
	movzx eax,cx

gudDone32:
    pop cx
	pop bx
	pop fs
	pop ds
	retf32
get_usb_data32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteUsbData
;
;		DESCRIPTION:	Write USB data
;
;		PARAMETERS:		BX		    Pipe handle
;                       CX          Size of data to request
;                       ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_usb_data_name	DB 'Write USB Data',0

write_usb_data16	Proc far
	push ds
	push fs
	push ax
	push bx
	push cx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc wudDone16
;
    movzx edi,di
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:add_out_proc

wudDone16:
    pop cx
	pop bx
	pop ax
	pop fs
	pop ds
	ret
write_usb_data16	Endp

write_usb_data32	Proc far
	push ds
	push fs
	push ax
	push bx
	push cx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc wudDone32
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:add_out_proc

wudDone32:
    pop cx
	pop bx
	pop ax
	pop fs
	pop ds
	retf32
write_usb_data32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReqUsbStatus
;
;		DESCRIPTION:	Request status input
;
;		PARAMETERS:		BX		    Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_usb_status_name	DB 'Request USB Status',0

req_usb_status	Proc far
	push ds
	push fs
	push bx
	push cx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc rusDone
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:add_status_in_proc

rusDone:
    pop cx
	pop bx
	pop fs
	pop ds
	retf32
req_usb_status	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteUsbStatus
;
;		DESCRIPTION:	Write status output
;
;		PARAMETERS:		BX		    Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_usb_status_name	DB 'Write USB Status',0

write_usb_status	Proc far
	push ds
	push fs
	push bx
	push cx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc wusDone
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:add_status_out_proc

wusDone:
    pop cx
	pop bx
	pop fs
	pop ds
	retf32
write_usb_status	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsUsbPipeIdle
;
;		DESCRIPTION:	Check if pipe is idle
;
;		PARAMETERS:		BX		    Pipe handle
;
;       RETURNS:        NC          Busy
;                       CY          Idle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_pipe_idle_name	DB 'Is USB Pipe Idle',0

is_usb_pipe_idle	Proc far
	push ds
	push fs
	push bx
;
	mov ax,USB_PIPE_HANDLE
	DerefHandle
	jc iupiDone
;
	mov fs,ds:[bx].up_pipe_sel
	mov ds,ds:[bx].up_func_sel
	call ds:is_pipe_signalled_proc

iupiDone:
	pop bx
	pop fs
	pop ds
	retf32
is_usb_pipe_idle	Endp

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
	mov ax,USB_PIPE_HANDLE
	mov di,OFFSET delete_handle
	RegisterHandle
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
	mov si,OFFSET notify_usb_detach
	mov di,OFFSET notify_usb_detach_name
	xor cl,cl
	mov ax,notify_usb_detach_nr
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
	mov si,OFFSET open_usb_pipe
	mov di,OFFSET open_usb_pipe_name
	xor dx,dx
	mov ax,open_usb_pipe_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_usb_pipe
	mov di,OFFSET close_usb_pipe_name
	xor dx,dx
	mov ax,close_usb_pipe_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET add_wait_for_pipe
	mov di,OFFSET add_wait_for_pipe_name
	xor dx,dx
	mov ax,add_wait_for_usb_pipe_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET lock_usb_pipe
	mov di,OFFSET lock_usb_pipe_name
	xor dx,dx
	mov ax,lock_usb_pipe_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET unlock_usb_pipe
	mov di,OFFSET unlock_usb_pipe_name
	xor dx,dx
	mov ax,unlock_usb_pipe_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET write_usb_control16
	mov si,OFFSET write_usb_control32
	mov di,OFFSET write_usb_control_name
	mov dx,virt_es_in
	mov ax,write_usb_control_nr
	RegisterUserGate
;
	mov si,OFFSET req_usb_data
	mov di,OFFSET req_usb_data_name
	xor dx,dx
	mov ax,req_usb_data_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET get_usb_data16
	mov si,OFFSET get_usb_data32
	mov di,OFFSET get_usb_data_name
	mov dx,virt_es_in
	mov ax,get_usb_data_nr
	RegisterUserGate
;
	mov bx,OFFSET write_usb_data16
	mov si,OFFSET write_usb_data32
	mov di,OFFSET write_usb_data_name
	mov dx,virt_es_in
	mov ax,write_usb_data_nr
	RegisterUserGate
;
	mov si,OFFSET req_usb_status
	mov di,OFFSET req_usb_status_name
	xor dx,dx
	mov ax,req_usb_status_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET write_usb_status
	mov di,OFFSET write_usb_status_name
	xor dx,dx
	mov ax,write_usb_status_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET is_usb_pipe_idle
	mov di,OFFSET is_usb_pipe_idle_name
	xor dx,dx
	mov ax,is_usb_pipe_idle_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
