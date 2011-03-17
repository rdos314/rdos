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
; USB.ASM
; USB support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE usb.inc

MAX_ATTACH_HOOKS = 32
MAX_DETACH_HOOKS = 32

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


pipe_handle_struc       STRUC

up_base         handle_header <>
up_func_sel     DW ?
up_pipe_sel         DW ?
up_pipe     DB ?

pipe_handle_struc       ENDS

pipe_wait_header    STRUC

pw_obj          wait_obj_header <>
pw_func_sel         DW ?
pw_pipe_sel     DW ?

pipe_wait_header    ENDS

req_handle_struc    STRUC

rh_base         handle_header <>
rh_func_sel     DW ?
rh_pipe_sel         DW ?
rh_signal       DW ?
rh_list     DW ?
rh_flags    DB ?

req_handle_struc    ENDS

REQ_TYPE_WRITE_CONTROL   = 1
REQ_TYPE_WRITE_DATA = 2
REQ_TYPE_READ_DATA = 3
REQ_TYPE_STATUS_IN = 4
REQ_TYPE_STATUS_OUT = 5

REQ_FLAG_STARTED = 1
REQ_FLAG_LOCKED  = 2
REQ_FLAG_ACTIVE  = 4

req_entry_struc STRUC

re_next     DW ?
re_size     DW ?
re_buf_sel      DW ?
re_type     DB ?

req_entry_struc ENDS

data    SEGMENT byte public 'DATA'

usb_dev_count       DW ?
usb_dev_arr     DW 256 DUP(?)

usb_attach_hooks    DW ?
usb_attach_arr      DW 2 * MAX_ATTACH_HOOKS DUP(?)

usb_detach_hooks    DW ?
usb_detach_arr      DW 2 * MAX_DETACH_HOOKS DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitUsbDevice
;
;           description:    Init USB device selector
;
;       parameters:     DS      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_usb_device_name DB 'Init USB Device', 0

init_usb_device Proc far
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
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:usb_dev_count
    mov es:usb_controller_id,bx
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateDefaultControl
;
;           description:    Create default control-pipe
;
;       parameters:     AL      Future device address
;               DS      USB device selector
;               ES      Function selector
;
;       RETURNS:    FS      Pipe control selector
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
    mov al,es:usbf_speed
    mov fs:usbp_speed,al
    mov fs:usbp_function_sel,es
    mov fs:usbp_address,0
    mov fs:usbp_endpoint,0
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_CONTROL
    mov fs:usbp_maxlen,8
    mov fs:usbp_device_sel,0
    mov fs:usbp_usage,1
;    
    push ds
    mov ax,fs
    mov ds,ax
    InitSection ds:usbp_section
    pop ds
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
    FreeMem
    call ds:change_address_proc
    popf
;
    pop edi
    pop cx
    pop es
    ret
CreateDefaultControl    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateBulk
;
;           description:    Create bulk-pipe
;
;       parameters:     DS      USB device selector
;               CX      Max data size
;               DL      Pipe # (bit 7 is direction)
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk    Proc near    
    push es
    push ax
    push bx
    push dx
;    
    call ds:create_bulk_proc    
    movzx bx,dl
    and bx,0Fh
    add bx,bx    
    test dl,80h
    jz cbOut

cbIn:
    mov es:[bx].usbf_in_endpoint_arr,fs
    jmp cbEndpointOK

cbOut:
    mov es:[bx].usbf_out_endpoint_arr,fs

cbEndpointOk:    
    and dl,0Fh
    mov fs:usbp_function_sel,es
    mov al,es:usbf_address
    mov fs:usbp_address,al
    mov al,es:usbf_speed
    mov fs:usbp_speed,al
    mov fs:usbp_endpoint,dl
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_BULK
    mov fs:usbp_maxlen,cx
    mov fs:usbp_device_sel,0
    mov fs:usbp_usage,1
;
    push ds
    mov ax,fs
    mov ds,ax
    InitSection ds:usbp_section
    pop ds    
;
    pop dx
    pop bx
    pop ax
    pop es
    ret
CreateBulk    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateInterrupt
;
;           description:    Create interrupt-pipe
;
;       parameters:     DS      USB device selector
;               CX      Max data size
;               DL      Pipe #
;               DH      Interval
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateInterrupt    Proc near    
    push es
    push ax
    push bx
    push dx
;    
    mov al,dh
    call ds:create_interrupt_proc    
    movzx bx,dl
    and bx,0Fh
    add bx,bx    
    mov es:[bx].usbf_in_endpoint_arr,fs
;    
    and dl,0Fh
    mov fs:usbp_function_sel,es
    mov al,es:usbf_address
    mov fs:usbp_address,al
    mov al,es:usbf_speed
    mov fs:usbp_speed,al
    mov fs:usbp_endpoint,dl
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_INTR
    mov fs:usbp_maxlen,cx
    mov fs:usbp_device_sel,0
    mov fs:usbp_usage,1
;
    push ds
    mov ax,fs
    mov ds,ax
    InitSection ds:usbp_section
    pop ds    
;
    pop dx
    pop bx
    pop ax
    pop es
    ret
CreateInterrupt    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDescr
;
;           description:    Get descriptor
;
;       parameters:     FS      Pipe control selector
;               AX      Config code
;               CX      Size of requested data
;               ES:EDI  Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDescr    Proc near    
    push es
    push bx
;    
    push es
    push cx
    push edi
;    
    push ax
    mov eax,8
    AllocateSmallGlobalMem
    mov bx,es
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
;
    pop edi
    pop cx
    pop es
;    
    call ds:add_in_proc
    call ds:add_status_out_proc
    call ds:issue_transfer_proc
    call ds:wait_for_completion_proc
;    
    pushf
    mov es,bx
    FreeMem    
    call ds:get_data_size_proc
    popf
;
    pop bx
    pop es   
    ret
GetDescr    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClosePipe
;
;           description:    Close pipe
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseEndpoint
;
;           description:    Close endpoint
;
;       parameters:     ES      Device
;               AL      Endpoint # (bit 7 is direction)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseEndpoint   Proc near
    push ax
    push bx
;
    movzx bx,al
    and bx,0Fh
    add bx,bx
    test al,80h
    jz cOut

cIn:
    mov ax,es:[bx].usbf_in_endpoint_arr
    mov es:[bx].usbf_in_endpoint_arr,0
    jmp cEndpointOK

cOut:
    mov ax,es:[bx].usbf_out_endpoint_arr
    mov es:[bx].usbf_out_endpoint_arr,0

cEndpointOk:    
    or ax,ax
    jz ceDone

ceClose:
    push fs
    mov fs,ax
    sub fs:usbp_usage,1
    jnz ceCloseDone
;    
    call ClosePipe    

ceCloseDone:
    pop fs
    
ceDone:
    pop bx
    pop ax
    ret
CloseEndpoint   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseDevice
;
;           description:    Close device and cleanup resources
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
    mov bx,OFFSET usbf_out_endpoint_arr
    xor al,al

cdCloseOutEndpointLoop:
    mov dx,es:[bx]
    or dx,dx
    jz cdCloseOutEndpointNext
;
    call CloseEndpoint

cdCloseOutEndpointNext:
    inc al
    add bx,2
    loop cdCloseOutEndpointLoop       
;
    mov cx,15
    mov bx,OFFSET usbf_in_endpoint_arr
    add bx,2
    mov al,81h

cdCloseInEndpointLoop:
    mov dx,es:[bx]
    or dx,dx
    jz cdCloseInEndpointNext
;
    call CloseEndpoint

cdCloseInEndpointNext:
    inc al
    add bx,2
    loop cdCloseInEndpointLoop       
;
    FreeMem
;
    pop dx
    pop cx
    pop bx
    pop ax    
    ret
CloseDevice Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TrapUsbAttach
;
;           DESCRIPTION:    Run notification handlers for attach
;
;           PARAMETERS:         BX      Controller #
;               AL      Device address (1..128)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_usb_attach PROC near
    push ds
    push cx
    push si
;       
    mov cx,SEG data
    mov ds,cx
    mov cx,ds:usb_attach_hooks
    or cx,cx
    je trap_attach_done
    
    mov si,OFFSET usb_attach_arr

trap_attach_loop:
    push ds
    push si
    push cx
    call dword ptr [si]
    pop cx
    pop si
    pop ds
;       
    add si,4
    loop trap_attach_loop

trap_attach_done:
    pop si
    pop cx
    pop ds
    ret
trap_usb_attach ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TrapUsbDetach
;
;           DESCRIPTION:    Run notification handlers for detach
;
;           PARAMETERS:         BX      Controller #
;               AL      Device address (1..128)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_usb_detach PROC near
    push ds
    push cx
    push si
;       
    mov cx,SEG data
    mov ds,cx
    mov cx,ds:usb_detach_hooks
    or cx,cx
    je trap_detach_done
    
    mov si,OFFSET usb_detach_arr

trap_detach_loop:
    push ds
    push si
    push cx
    call dword ptr [si]
    pop cx
    pop si
    pop ds
;       
    add si,4
    loop trap_detach_loop

trap_detach_done:
    pop si
    pop cx
    pop ds
    ret
trap_usb_detach ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyUsbAttach
;
;           description:    Notify USB attach event
;
;       parameters:     AL      Usb port
;               AH      Speed, 0 = low speed
;               DS      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_usb_attach_name DB 'Notify USB Attach', 0

notify_usb_attach       Proc far
    push gs
    push fs
    push es
    pushad
;
    movzx bx,al
    mov dl,ah
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
    mov es:usbf_port,bl
    mov ds:[di],es
    add bx,bx
    mov ds:[bx].usb_port_sel_arr,es
    sub di,OFFSET usb_addr_arr
    shr di,1
    mov ax,di
    mov es:usbf_address,al
    mov es:usbf_speed,dl
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
    pop ax
;
    call CreateDefaultControl
    jc nuaDone
;
    mov eax,8
    AllocateSmallGlobalMem

nuaRetry:
    call ds:is_connected_proc
    jc nuaDone
;
    xor edi,edi
    mov cx,8
    mov ax,100h
    call GetDescr
    movzx ax,es:udd_maxlen
    or ax,ax
    jz nuaRetry
;
    mov fs:usbp_maxlen,ax
    movzx eax,es:udd_len
    FreeMem
;
    call ds:is_connected_proc
    jc nuaDone
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
    call ds:is_connected_proc
    jc nuaDone
;    
    mov eax,8
    AllocateSmallGlobalMem
    xor edi,edi
    mov cx,8
    mov al,bl
    mov ah,2
    call GetDescr
    movzx eax,es:ucd_size
    FreeMem
;
    call ds:is_connected_proc
    jc nuaDone
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
    je nuaNotify
;    
    cmp bl,gs:udd_configs
    jb nuaLoop

nuaNotify:
    call ds:is_connected_proc
    jc nuaDone
;
    xor ax,ax
    mov gs,ax
    mov bx,ds:usb_controller_id
    mov al,fs:usbp_address
    call trap_usb_attach
    
nuaDone:
    popad
    pop es
    pop fs
    pop gs
    ret
notify_usb_attach   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyUsbDetach
;
;           description:    Notify USB detach event
;
;       parameters:     AL      Usb port
;               DS      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_usb_detach_name DB 'Notify USB Detach', 0

notify_usb_detach       Proc far
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
    mov bx,ds:usb_controller_id
    mov al,es:usbf_address
    call trap_usb_detach      
    call CloseDevice

nudDone:    
    popad
    pop es
    ret
notify_usb_detach   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddReqBlock
;
;           description:    Add an request block
;
;       parameters:     DS:BX   Req handle struc
;               
;       Returns:    ES      Req block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReqBlock     Proc near
    push eax
;    
    mov eax,SIZE req_entry_struc
    AllocateSmallGlobalMem
    mov es:re_type,0
    mov es:re_next,0
;
    mov ax,ds:[bx].rh_list
    or ax,ax
    je arbEmpty
;       
    push ds

arbLoop:
    mov ds,ax
    mov ax,ds:re_next
    or ax,ax
    jnz arbLoop
;
    mov ds:re_next,es
    pop ds
    jmp arbDone
    
arbEmpty:
    mov ds:[bx].rh_list,es

arbDone:
    pop eax    
    ret
AddReqBlock Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateUsbReq
;
;           description:    Create an asynchronous USB req handle
;
;       parameters:     BX      Pipe handle
;               
;       Returns:    BX      Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_usb_req_name DB 'Create USB req', 0

create_usb_req  Proc far
    push ds
    push fs
    push ax
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc curDone
;       
    mov fs,ds:[bx].up_pipe_sel
    mov ax,ds:[bx].up_func_sel
;       
    mov cx,SIZE req_handle_struc
    AllocateHandle
    mov [bx].rh_func_sel,ax
    mov [bx].rh_pipe_sel,fs
    mov [bx].rh_list,0
    mov [bx].rh_signal,0
    mov [bx].rh_flags,0
    mov [bx].hh_sign,USB_REQ_HANDLE
    mov bx,[bx].hh_handle
    clc

curDone:
    pop cx
    pop ax
    pop fs
    pop ds
    ret
create_usb_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddWriteUsbControlReq
;
;           description:    Add write control req
;
;       parameters:     BX      Req handle
;               CX      Size of data
;               ES      Data selector (do not free)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_write_usb_control_req_name DB 'Add Write USB control req', 0

add_write_usb_control_req       Proc far
    push ds
    push es
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc awucDone
;
    mov ax,es
    call AddReqBlock
    mov es:re_type,REQ_TYPE_WRITE_CONTROL
    mov es:re_size,cx
    mov es:re_buf_sel,ax
    clc
    
awucDone:    
    pop bx
    pop ax
    pop es
    pop ds
    ret
add_write_usb_control_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddWriteUsbDataReq
;
;           description:    Add write data req
;
;       parameters:     BX      Req handle
;               CX      Size of data
;               ES      Data selector (do not free)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_write_usb_data_req_name DB 'Add Write USB data req', 0

add_write_usb_data_req  Proc far
    push ds
    push es
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc awudDone
;
    mov ax,es
    call AddReqBlock
    mov es:re_type,REQ_TYPE_WRITE_DATA
    mov es:re_size,cx
    mov es:re_buf_sel,ax
    clc
    
awudDone:    
    pop bx
    pop ax
    pop es
    pop ds
    ret
add_write_usb_data_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddReadUsbDataReq
;
;           description:    Add read data req
;
;       parameters:     BX      Req handle
;               CX      Size of data
;               ES      Data selector (do not free)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_read_usb_data_req_name DB 'Add Read USB data req', 0

add_read_usb_data_req   Proc far
    push ds
    push es
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc arudDone
;
    mov ax,es
    call AddReqBlock
    mov es:re_type,REQ_TYPE_READ_DATA
    mov es:re_size,cx
    mov es:re_buf_sel,ax
    clc
    
arudDone:    
    pop bx
    pop ax
    pop es
    pop ds
    ret
add_read_usb_data_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddUsbStatusInReq
;
;           description:    Add status in req
;
;       parameters:     BX      Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_usb_status_in_req_name DB 'Add USB status in req', 0

add_usb_status_in_req   Proc far
    push ds
    push es
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc ausiDone
;
    call AddReqBlock
    mov es:re_type,REQ_TYPE_STATUS_IN
    mov es:re_size,0
    mov es:re_buf_sel,0
    clc
    
ausiDone:    
    pop bx
    pop ax
    pop es
    pop ds
    ret
add_usb_status_in_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddUsbStatusOutReq
;
;           description:    Add status out req
;
;       parameters:     BX      Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_usb_status_out_req_name DB 'Add USB status out req', 0

add_usb_status_out_req  Proc far
    push ds
    push es
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc ausoDone
;
    call AddReqBlock
    mov es:re_type,REQ_TYPE_STATUS_OUT
    mov es:re_size,0
    mov es:re_buf_sel,0
    clc
    
ausoDone:    
    pop bx
    pop ax
    pop es
    pop ds
    ret
add_usb_status_out_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqWriteControl
;
;           description:    Do Write control req
;
;       parameters:     DS      Function sel
;               ES      Req sel
;               FS      Pipe sel
;               CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqWriteControl Proc near
    push es
    push edi
;       
    mov es,es:re_buf_sel
    xor edi,edi
    call ds:add_setup_proc
;       
    pop edi
    pop es      
    ret
ReqWriteControl Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqWriteData
;
;           description:    Do Write data req
;
;       parameters:     DS      Function sel
;               ES      Req sel
;               FS      Pipe sel
;               CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqWriteData    Proc near
    push es
    push edi
;       
    mov es,es:re_buf_sel
    xor edi,edi
    call ds:add_out_proc
;       
    pop edi
    pop es      
    ret
ReqWriteData Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqReadData
;
;           description:    Do read data req
;
;       parameters:     DS      Function sel
;               ES      Req sel
;               FS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqReadData     Proc near
    push es
    push cx
    push edi
;       
    xor edi,edi
    mov cx,es:re_size
    mov es,es:re_buf_sel
    call ds:add_in_proc
;       
    pop edi
    pop cx
    pop es
    ret
ReqReadData Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqStatusIn
;
;           description:    Do status in
;
;       parameters:     DS      Function sel
;               ES      Req sel
;               FS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqStatusIn     Proc near
    call ds:add_status_in_proc
    ret
ReqStatusIn Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReqStatusOut
;
;           description:    Do status out
;
;       parameters:     DS      Function sel
;               ES      Req sel
;               FS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqStatusOut    Proc near
    call ds:add_status_out_proc
    ret
ReqStatusOut Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartUsbReq
;
;           description:    Start req
;
;       parameters:     AX      Thread to signal
;               BX      Req handle
;               CX      Size of out buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_usb_req_name DB 'Start USB req', 0

req_tab:
rt01 DW OFFSET ReqWriteControl
rt02 DW OFFSET ReqWriteData
rt03 DW OFFSET ReqReadData
rt04 DW OFFSET ReqStatusIn
rt05 DW OFFSET ReqStatusOut   

start_usb_req   Proc far
    push ds
    push fs
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc surDone
;
    test ds:[bx].rh_flags,REQ_FLAG_LOCKED
    jnz surStart
;
    push ds
    mov ds,[bx].rh_pipe_sel
    EnterSection ds:usbp_section
    pop ds
    or ds:[bx].rh_flags,REQ_FLAG_LOCKED

surStart:    
    or ds:[bx].rh_flags,REQ_FLAG_STARTED OR REQ_FLAG_ACTIVE
    mov ax,ds:[bx].rh_list
    mov fs,ds:[bx].rh_pipe_sel
    mov ds,ds:[bx].rh_func_sel

surReqLoop:
    or ax,ax
    jz surIssue
;
    mov es,ax
    movzx bx,es:re_type
    or bx,bx    
    jz surIssue
;
    cmp bx,5
    ja surIssue
;
    dec bx
    add bx,bx
    call word ptr cs:[bx].req_tab
    mov ax,es:re_next    
    jmp surReqLoop

surIssue:
    ClearSignal
    call ds:issue_transfer_proc

surDone:    
    pop bx
    pop ax
    pop fs
    pop ds
    ret
start_usb_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopUsbReq
;
;           description:    Stop req
;
;       parameters:     BX      Req handle
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_usb_req_name DB 'Stop USB req', 0

stop_usb_req    Proc far
    push ds
    push fs
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc sturEnd
;
    push ds
    mov fs,ds:[bx].rh_pipe_sel
    mov ds,ds:[bx].rh_func_sel
    call ds:end_transfer_proc
    pop ds
;
    mov ax,5
    WaitMilliSec    
;    
    test ds:[bx].rh_flags,REQ_FLAG_LOCKED
    jz sturDone
;
    push ds
    mov ds,[bx].rh_pipe_sel
    LeaveSection ds:usbp_section
    pop ds
    and ds:[bx].rh_flags,NOT REQ_FLAG_LOCKED

sturDone:
    and ds:[bx].rh_flags,NOT (REQ_FLAG_STARTED OR REQ_FLAG_ACTIVE)

sturEnd:
    pop bx
    pop ax
    pop fs
    pop ds
    ret
stop_usb_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsUsbReqStarted
;
;           description:    Check if request is started
;
;       parameters:     BX      Req handle
;
;       Returns:    NC      Req is started
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_req_started_name DB 'Is USB Req Started', 0

is_usb_req_started      Proc far
    push ds
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc iursDone
;
    test ds:[bx].rh_flags,REQ_FLAG_STARTED
    stc
    jz iursDone
;
    clc

iursDone:       
    pop bx
    pop ax
    pop ds
    ret
is_usb_req_started   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsUsbReqReady
;
;           description:    Check if request is ready
;
;       parameters:     BX      Req handle
;
;       Returns:    NC      Req is done
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_req_ready_name DB 'Is USB Req Ready', 0

is_usb_req_ready    Proc far
    push ds
    push fs
    push ax
    push bx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc iurrDone
;
    test ds:[bx].rh_flags,REQ_FLAG_ACTIVE
    stc
    jz iurrDone
;
    push ds
    mov fs,ds:[bx].rh_pipe_sel
    mov ds,ds:[bx].rh_func_sel
    call ds:is_transfer_done_proc
    pop ds
    jc iurrDone
;
    and ds:[bx].rh_flags,NOT REQ_FLAG_STARTED
    clc
    
iurrDone:       
    pop bx
    pop ax
    pop fs
    pop ds
    ret
is_usb_req_ready   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetUsbReqData
;
;           description:    Get req data
;
;       parameters:     BX      Req handle
;
;       Returns:    NC      Req is done
;               CX      Bytes transfered to buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_req_data_name DB 'Get USB Req Data', 0

get_usb_req_data    Proc far
    push ds
    push fs
    push ax
    push bx
;
    xor cx,cx
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc gurdDone
;
    test ds:[bx].rh_flags,REQ_FLAG_ACTIVE
    stc
    jz gurdDone
;
    mov fs,ds:[bx].rh_pipe_sel
    mov ax,ds:[bx].rh_list
    mov ds,ds:[bx].rh_func_sel
    call ds:was_transfer_ok_proc
    jc gurdDone

gurdReqLoop:
    or ax,ax
    clc
    jz gurdDone
;
    mov es,ax
    mov al,es:re_type
    cmp al,REQ_TYPE_READ_DATA
    jne gurdNext
;    
    call ds:get_data_size_proc
    jmp gurdDone

gurdNext:
    mov ax,es:re_next    
    jmp gurdReqLoop

gurdDone:       
    pop bx
    pop ax
    pop fs
    pop ds
    ret
get_usb_req_data   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseUsbReq
;
;           description:    Close USB req
;
;       parameters:     BX      Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_usb_req_name DB 'Close USB req', 0

close_usb_req   Proc far
    push ds
    push es
    push fs
    push ax
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc crDone
;
    test ds:[bx].rh_flags,REQ_FLAG_STARTED
    jz crFreeList
;
    push ds
    mov fs,ds:[bx].rh_pipe_sel
    mov ds,ds:[bx].rh_func_sel
    call ds:end_transfer_proc
    pop ds
;    
    mov ax,5
    WaitMilliSec    

crFreeList:
    mov ax,ds:[bx].rh_list

crFreeLoop:
    or ax,ax
    jz crFreeHandle
;
    cmp ax,-1
    jz crFreeHandle
;
    mov es,ax
    mov ax,es:re_next    
    FreeMem
    jmp crFreeLoop

crFreeHandle:
    test ds:[bx].rh_flags,REQ_FLAG_LOCKED
    jz crLockOk
;
    push ds
    mov ds,[bx].rh_pipe_sel
    LeaveSection ds:usbp_section
    pop ds

crLockOk:
    FreeHandle

crDone: 
    pop ax
    pop fs
    pop es
    pop ds
    ret
close_usb_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetUsbDevice
;
;           description:    Get USB device descriptor
;
;       parameters:     BX      Controller #
;               AL      Device address (1..128)
;               (E)CX       Buffer size
;               ES:(E)DI    Buffer
;
;       Returns:    (E)AX       Size of descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_device_name DB 'Get USB Device', 0

get_usb_device  Proc near
    push ds
    push esi
;
    mov si,SEG data
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
    rep movs byte ptr es:[edi],ds:[esi]    
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetUsbConfig
;
;           description:    Get USB config descriptor
;
;       parameters:     BX      Controller #
;               AL      Device address (1..128)
;               DL      Config #
;               (E)CX       Buffer size
;               ES:(E)DI    Buffer
;
;       Returns:    (E)AX       Size of descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_config_name DB 'Get USB Config', 0

get_usb_config  Proc near
    push ds
    push esi
;
    mov si,SEG data
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
    rep movs byte ptr es:[edi],ds:[esi]    
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
;           NAME:           ConfigUsbDevice
;
;           description:    Configure USB device
;
;       parameters:     BX      Controller #
;               AL      Device address (1..128)
;               DL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

config_usb_device_name DB 'Config USB Device', 0

config_usb_device       Proc near
    push ds
    push es
    push fs
    push gs
    push ax
    push cx
    push esi
    push edi
;    
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_dev_count
    cmp bx,si
    jae cudFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz cudFail
;
    mov ds,si
    cmp al,128
    jae cudFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_addr_arr
    or si,si
    jz cudFail
;
    mov fs,si
    mov si,fs:usbf_in_endpoint_arr
    or si,si
    jz cudFail
;
    mov fs,si    
    mov eax,8
    AllocateSmallGlobalMem
    xor edi,edi
    mov es:usd_type,0
    mov es:usd_req,SET_CONFIG
    movzx ax,dl
    mov es:usd_value,ax
    mov es:usd_index,0
    mov es:usd_len,0
;    
    mov cx,8
    call ds:add_setup_proc
    call ds:add_status_in_proc
    call ds:issue_transfer_proc
    call ds:wait_for_completion_proc
;
    pushf
    FreeMem
    popf
    jc cudFail
;
    mov es,fs:usbp_function_sel
    movzx si,dl
    dec si
    add si,si
    mov gs,fs:[si].usbp_config_sel
    xor di,di
    movzx cx,gs:ucd_len
    add di,cx

cudDescrLoop:
    mov al,gs:[di].udd_type
    cmp al,5
    jne cudNextDescr
;
    mov al,gs:[di].ued_attrib
    and al,3
    cmp al,2
    je cudCreateBulk
;
    cmp al,3
    je cudCreateInterrupt
;
    jmp cudNextDescr

cudCreateBulk:
    mov cx,gs:[di].ued_maxsize
    mov dl,gs:[di].ued_address
    and dl,8Fh
    call CreateBulk
    mov dl,gs:[di].ued_address
    and dl,80h
    mov fs:usbp_dir,dl
    jmp cudNextDescr

cudCreateInterrupt:
    mov cx,gs:[di].ued_maxsize
    mov dl,gs:[di].ued_address
    and dl,0Fh
    mov dh,gs:[di].ued_interval
    call CreateInterrupt
    mov dl,gs:[di].ued_address
    and dl,80h
    mov fs:usbp_dir,dl
    
cudNextDescr:
    movzx cx,gs:[di].ucd_len
    add di,cx
    cmp di,gs:ucd_size
    jb cudDescrLoop    
;
    clc    
    jmp cudDone

cudFail:
    stc
    
cudDone: 
    pop edi
    pop esi
    pop cx
    pop ax
    pop gs
    pop fs
    pop es
    pop ds
    retf32
config_usb_device    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenUsbPipe
;
;           description:    Open USB pipe
;
;       parameters:     BX      Controller #
;               AL      Device address (1..128)
;               DL      Pipe # (bit 7 is direction)
;
;       RETURNS:    BX      Pipe handle
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
    push di
;
    mov si,SEG data
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
    and dl,8Fh
    test dl,80h
    jz oupOut    

oupIn:
    mov ds,si
    movzx si,dl
    and si,0Fh
    add si,si
    mov di,ds:[si].usbf_in_endpoint_arr
    or di,di
    jnz oupCreateHandle    
;
    int 3
    jmp oupFail

oupOut:
    mov ds,si
    movzx si,dl
    add si,si
    mov di,ds:[si].usbf_out_endpoint_arr
    or di,di
    jnz oupCreateHandle    
;
    int 3
    jmp oupFail

oupCreateHandle:    
    mov cx,SIZE pipe_handle_struc
    AllocateHandle
    mov [bx].up_func_sel,es
    mov [bx].up_pipe_sel,di
    mov [bx].up_pipe,dl
    mov [bx].hh_sign,USB_PIPE_HANDLE
    mov bx,[bx].hh_handle
;
    mov fs,di
    inc fs:usbp_usage
    clc
    jmp oupDone

oupFail:
    stc

oupDone:
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
open_usb_pipe    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseUsbPipe
;
;           DESCRIPTION:    Close a USB pipe handle
;
;           PARAMETERS:         BX          Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_usb_pipe_name     DB 'Close USB Pipe',0

close_usb_pipe  Proc far
    push ds
    push es
    push fs
    push ax
    push bx
    push dx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc cupDone
;
    push ds
    push bx
    mov dl,ds:[bx].up_pipe
    mov fs,ds:[bx].up_pipe_sel
    sub fs:usbp_usage,1
    jnz cupCloseDone
;       
    mov ds,ds:[bx].up_func_sel
    mov ax,fs:usbp_device_sel
    or ax,ax
    jz cupCloseDone
;
    mov es,ax
    movzx bx,fs:usbp_endpoint
    and bx,0Fh
    add bx,bx    
;
    test dl,80h
    jz cupOut

cupIn:   
    mov es:[bx].usbf_in_endpoint_arr,0
    jmp cupClose

cupOut:
    mov es:[bx].usbf_out_endpoint_arr,0

cupClose:    
    call ClosePipe

cupCloseDone:
    pop bx
    pop ds
    FreeHandle
    clc

cupDone:
    pop dx
    pop bx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
close_usb_pipe  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    BX              USB pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
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
    sub fs:usbp_usage,1
    jnz delete_handle_pipe_ok
;       
    call ClosePipe

delete_handle_pipe_ok:
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
delete_handle   Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForPipe
;
;           DESCRIPTION:    Start a wait for pipe
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_pipe     PROC far
    push ds
    push fs
;    
    mov fs,es:pw_pipe_sel
    mov ds,es:pw_func_sel
    call ds:issue_transfer_proc
;       
    pop fs
    pop ds    
    retf32
start_wait_for_pipe Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForPipe
;
;           DESCRIPTION:    Stop a wait for pipe
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_pipe      PROC far
    push ds
    push fs
;    
    mov fs,es:pw_pipe_sel
;    
    mov ds,es:pw_func_sel   
    call ds:end_transfer_proc
;       
    pop fs
    pop ds    
    retf32
stop_wait_for_pipe Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearWaitForPipe
;
;           DESCRIPTION:    Clear wait for pipe
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_wait_for_pipe     PROC far
    retf32
clear_wait_for_pipe Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsPipeIdle
;
;           DESCRIPTION:    Check if pipe is idle
;
;           PARAMETERS:         ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_pipe_idle    PROC far
    push ds
    push fs
;
    mov ds,es:pw_func_sel
    mov fs,es:pw_pipe_sel
    call ds:is_transfer_done_proc
    cmc
;
    pop fs
    pop ds    
    retf32
is_pipe_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForPipe
;
;           DESCRIPTION:    Add a wait for pipe
;
;           PARAMETERS:         BX      Wait handle
;               AX      Pipe handle
;               ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_pipe_name  DB 'Add Wait For Pipe',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_pipe,      SEG code
aw1 DD OFFSET stop_wait_for_pipe,       SEG code
aw2 DD OFFSET clear_wait_for_pipe,      SEG code
aw3 DD OFFSET is_pipe_idle,             SEG code

add_wait_for_pipe       PROC far
    push ds
    push es
    push fs
    push eax
    push bx
    push edi
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
    mov edi,OFFSET add_wait_tab
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
    pop edi
    pop bx
    pop eax
    pop fs
    pop es
    pop ds
    retf32
add_wait_for_pipe       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LockUsbPipe
;
;           DESCRIPTION:    Lock USB pipe
;
;           PARAMETERS:         BX          Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_usb_pipe_name      DB 'Lock USB Pipe',0

lock_usb_pipe   Proc far
    push ds
    push ax
    push bx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc lupDone
;
    push ds
    mov ds,ds:[bx].up_pipe_sel
    EnterSection ds:usbp_section
    pop ds

lupDone:
    pop bx
    pop ax
    pop ds
    retf32
lock_usb_pipe   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UnlockUsbPipe
;
;           DESCRIPTION:    Unlock USB pipe
;
;           PARAMETERS:         BX          Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_usb_pipe_name    DB 'Unlock USB Pipe',0

unlock_usb_pipe   Proc far
    push ds
    push ax
    push bx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc uupDone
;       
    push ds
    mov ds,ds:[bx].up_pipe_sel
    LeaveSection ds:usbp_section
    pop ds

uupDone:
    pop bx
    pop ax
    pop ds
    retf32
unlock_usb_pipe   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteUsbControl
;
;           DESCRIPTION:    Write USB control
;
;           PARAMETERS:         BX          Pipe handle
;               CX      Size of data to request
;               ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_usb_control_name  DB 'Write USB Control',0

write_usb_control16     Proc far
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
write_usb_control16     Endp

write_usb_control32     Proc far
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
write_usb_control32     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReqUsbData
;
;           DESCRIPTION:    Setup request for input data on pipe
;
;           PARAMETERS:         BX          Pipe handle
;               CX      Size of buffer
;               ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_usb_data_name       DB 'Request USB Data',0

req_usb_data    Proc far
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
req_usb_data    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetUsbDataSize
;
;           DESCRIPTION:    Get data size from previous input req
;
;           PARAMETERS:         BX          Pipe handle
;
;       RETURNS:    (E)AX       Actual size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_data_size_name  DB 'Get USB Data Size',0

get_usb_data_size16     Proc far
    push ds
    push fs
    push bx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc gudDone16
;
    mov fs,ds:[bx].up_pipe_sel
    mov ds,ds:[bx].up_func_sel
    call ds:get_data_size_proc
    mov ax,cx

gudDone16:
    pop cx
    pop bx
    pop fs
    pop ds
    ret
get_usb_data_size16     Endp

get_usb_data_size32     Proc far
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
    call ds:get_data_size_proc
    movzx eax,cx

gudDone32:
    pop cx
    pop bx
    pop fs
    pop ds
    retf32
get_usb_data_size32     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteUsbData
;
;           DESCRIPTION:    Write USB data
;
;           PARAMETERS:         BX          Pipe handle
;               CX      Size of data to request
;               ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_usb_data_name     DB 'Write USB Data',0

write_usb_data16    Proc far
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
write_usb_data16    Endp

write_usb_data32    Proc far
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
write_usb_data32    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReqUsbStatus
;
;           DESCRIPTION:    Request status input
;
;           PARAMETERS:         BX          Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_usb_status_name     DB 'Request USB Status',0

req_usb_status  Proc far
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
req_usb_status  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteUsbStatus
;
;           DESCRIPTION:    Write status output
;
;           PARAMETERS:         BX          Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_usb_status_name   DB 'Write USB Status',0

write_usb_status    Proc far
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
write_usb_status    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartUsbTransaction
;
;           DESCRIPTION:    Start USB transaction
;
;           PARAMETERS:         BX          Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_usb_trans_name    DB 'Start USB Transaction',0

start_usb_trans Proc far
    push ds
    push fs
    push bx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc sutDone
;
    mov fs,ds:[bx].up_pipe_sel
    mov ds,ds:[bx].up_func_sel
    call ds:issue_transfer_proc

sutDone:
    pop bx
    pop fs
    pop ds
    retf32
start_usb_trans Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsUsbTransactionDone
;
;           DESCRIPTION:    Check if transaction is done
;
;           PARAMETERS:         BX          Pipe handle
;
;       RETURNS:    NC      Done
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_trans_done_name  DB 'Is USB Transaction Done',0

is_usb_trans_done       Proc far
    push ds
    push fs
    push bx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc iutdDone
;
    mov fs,ds:[bx].up_pipe_sel
    mov ds,ds:[bx].up_func_sel
    call ds:is_transfer_done_proc

iutdDone:
    pop bx
    pop fs
    pop ds
    retf32
is_usb_trans_done       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WasUsbTransactionOk
;
;           DESCRIPTION:    Check if transaction was performed ok
;
;           PARAMETERS:         BX          Pipe handle
;
;       RETURNS:    NC      Done
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

was_usb_trans_ok_name   DB 'Was USB Transaction Ok',0

was_usb_trans_ok    Proc far
    push ds
    push fs
    push bx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc wutoDone
;
    mov fs,ds:[bx].up_pipe_sel
    mov ds,ds:[bx].up_func_sel
    call ds:was_transfer_ok_proc

wutoDone:
    pop bx
    pop fs
    pop ds
    retf32
was_usb_trans_ok    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetUsbInfo
;
;           DESCRIPTION:    Get pipe info
;
;           PARAMETERS:         BX          Pipe handle
;
;       RETURNS:    FS      Pipe sel
;               DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_info_name       DB 'Get USB Info',0

get_usb_info    Proc far
    push bx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc guiDone
;
    mov fs,ds:[bx].up_pipe_sel
    mov ds,ds:[bx].up_func_sel

guiDone:
    pop cx
    pop bx
    ret
get_usb_info    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HookUsbAttach
;
;           description:    Hook USB attach event
;
;       parameters:     ES:DI       Callback 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_usb_attach_name DB 'Hook USB Attach', 0

hook_usb_attach Proc far
    push ds
    push bx
;       
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:usb_attach_hooks
    shl bx,2
    add bx,OFFSET usb_attach_arr
    mov [bx],di
    mov [bx+2],es
    inc ds:usb_attach_hooks
;
    pop bx
    pop ds
    ret
hook_usb_attach   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HookUsbDetach
;
;           description:    Hook USB detach event
;
;       parameters:     ES:DI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_usb_detach_name DB 'Hook USB Detach', 0

hook_usb_detach Proc far
    push ds
    push bx
;       
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:usb_detach_hooks
    shl bx,2
    add bx,OFFSET usb_detach_arr
    mov [bx],di
    mov [bx+2],es
    inc ds:usb_detach_hooks
;
    pop bx
    pop ds
    ret
hook_usb_detach   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    INIT PCI DEVICE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ax,USB_PIPE_HANDLE
    mov di,OFFSET delete_handle
    RegisterHandle
;
    mov esi,OFFSET init_usb_device
    mov edi,OFFSET init_usb_device_name
    xor cl,cl
    mov ax,init_usb_device_nr
    RegisterOldOsGate
;
    mov esi,OFFSET notify_usb_attach
    mov edi,OFFSET notify_usb_attach_name
    xor cl,cl
    mov ax,notify_usb_attach_nr
    RegisterOldOsGate
;
    mov esi,OFFSET notify_usb_detach
    mov edi,OFFSET notify_usb_detach_name
    xor cl,cl
    mov ax,notify_usb_detach_nr
    RegisterOldOsGate
;
    mov esi,OFFSET hook_usb_attach
    mov edi,OFFSET hook_usb_attach_name
    xor cl,cl
    mov ax,hook_usb_attach_nr
    RegisterOldOsGate
;
    mov esi,OFFSET hook_usb_detach
    mov edi,OFFSET hook_usb_detach_name
    xor cl,cl
    mov ax,hook_usb_detach_nr
    RegisterOldOsGate
;
    mov esi,OFFSET create_usb_req
    mov edi,OFFSET create_usb_req_name
    xor cl,cl
    mov ax,create_usb_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET add_write_usb_control_req
    mov edi,OFFSET add_write_usb_control_req_name
    xor cl,cl
    mov ax,add_write_usb_control_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET add_write_usb_data_req
    mov edi,OFFSET add_write_usb_data_req_name
    xor cl,cl
    mov ax,add_write_usb_data_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET add_read_usb_data_req
    mov edi,OFFSET add_read_usb_data_req_name
    xor cl,cl
    mov ax,add_read_usb_data_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET add_usb_status_in_req
    mov edi,OFFSET add_usb_status_in_req_name
    xor cl,cl
    mov ax,add_usb_status_in_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET add_usb_status_out_req
    mov edi,OFFSET add_usb_status_out_req_name
    xor cl,cl
    mov ax,add_usb_status_out_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET start_usb_req
    mov edi,OFFSET start_usb_req_name
    xor cl,cl
    mov ax,start_usb_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET stop_usb_req
    mov edi,OFFSET stop_usb_req_name
    xor cl,cl
    mov ax,stop_usb_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET is_usb_req_started
    mov edi,OFFSET is_usb_req_started_name
    xor cl,cl
    mov ax,is_usb_req_started_nr
    RegisterOldOsGate
;
    mov esi,OFFSET is_usb_req_ready
    mov edi,OFFSET is_usb_req_ready_name
    xor cl,cl
    mov ax,is_usb_req_ready_nr
    RegisterOldOsGate
;
    mov esi,OFFSET get_usb_req_data
    mov edi,OFFSET get_usb_req_data_name
    xor cl,cl
    mov ax,get_usb_req_data_nr
    RegisterOldOsGate
;
    mov esi,OFFSET close_usb_req
    mov edi,OFFSET close_usb_req_name
    xor cl,cl
    mov ax,close_usb_req_nr
    RegisterOldOsGate
;
    mov esi,OFFSET get_usb_info
    mov edi,OFFSET get_usb_info_name
    xor cl,cl
    mov ax,get_usb_info_nr
    RegisterOldOsGate
;
    mov ebx,OFFSET get_usb_device16
    mov esi,OFFSET get_usb_device32
    mov edi,OFFSET get_usb_device_name
    mov dx,virt_es_in
    mov ax,get_usb_device_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_usb_config16
    mov esi,OFFSET get_usb_config32
    mov edi,OFFSET get_usb_config_name
    mov dx,virt_es_in
    mov ax,get_usb_config_nr
    RegisterUserGate
;
    mov esi,OFFSET config_usb_device
    mov edi,OFFSET config_usb_device_name
    xor dx,dx
    mov ax,config_usb_device_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_usb_pipe
    mov edi,OFFSET open_usb_pipe_name
    xor dx,dx
    mov ax,open_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_usb_pipe
    mov edi,OFFSET close_usb_pipe_name
    xor dx,dx
    mov ax,close_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_pipe
    mov edi,OFFSET add_wait_for_pipe_name
    xor dx,dx
    mov ax,add_wait_for_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET lock_usb_pipe
    mov edi,OFFSET lock_usb_pipe_name
    xor dx,dx
    mov ax,lock_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET unlock_usb_pipe
    mov edi,OFFSET unlock_usb_pipe_name
    xor dx,dx
    mov ax,unlock_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET write_usb_control16
    mov esi,OFFSET write_usb_control32
    mov edi,OFFSET write_usb_control_name
    mov dx,virt_es_in
    mov ax,write_usb_control_nr
    RegisterUserGate
;
    mov esi,OFFSET req_usb_data
    mov edi,OFFSET req_usb_data_name
    xor dx,dx
    mov ax,req_usb_data_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_usb_data_size16
    mov esi,OFFSET get_usb_data_size32
    mov edi,OFFSET get_usb_data_size_name
    mov dx,virt_es_in
    mov ax,get_usb_data_size_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_usb_data16
    mov esi,OFFSET write_usb_data32
    mov edi,OFFSET write_usb_data_name
    mov dx,virt_es_in
    mov ax,write_usb_data_nr
    RegisterUserGate
;
    mov esi,OFFSET req_usb_status
    mov edi,OFFSET req_usb_status_name
    xor dx,dx
    mov ax,req_usb_status_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET write_usb_status
    mov edi,OFFSET write_usb_status_name
    xor dx,dx
    mov ax,write_usb_status_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET start_usb_trans
    mov edi,OFFSET start_usb_trans_name
    xor dx,dx
    mov ax,start_usb_transaction_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_usb_trans_done
    mov edi,OFFSET is_usb_trans_done_name
    xor dx,dx
    mov ax,is_usb_trans_done_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET was_usb_trans_ok
    mov edi,OFFSET was_usb_trans_ok_name
    xor dx,dx
    mov ax,was_usb_trans_ok_nr
    RegisterBimodalUserGate
    clc
    ret
init    Endp

code    ENDS

    END init
