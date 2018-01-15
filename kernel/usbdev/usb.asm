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
INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE usb.inc
INCLUDE usbdev.inc
INCLUDE ..\os\chandle.inc

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

pipe_copy_struc     STRUC

pc_next         DW ?
pc_user_offset  DD ?
pc_user_sel     DW ?
pc_usb_linear   DD ?
pc_size         DW ?

pipe_copy_struc     ENDS

pipe_handle_struc       STRUC

up_base         handle_header <>
up_handle_list  DD ?
up_func_sel     DW ?
up_pipe_sel     DW ?
up_pipe         DB ?
up_copy         DB ?
up_list         DW ?
up_port_sel     DW ?
up_deleted      DB ?

pipe_handle_struc       ENDS

pipe_wait_header    STRUC

pw_obj          wait_obj_header <>
pw_func_sel     DW ?
pw_port_sel     DW ?
pw_pipe         DB ?

pipe_wait_header    ENDS

req_handle_struc    STRUC

rh_base         handle_header <>
rh_func_sel     DW ?
rh_port_sel     DW ?
rh_signal       DW ?
rh_list         DW ?
rh_handle_list  DD ?
rh_flags        DB ?
rh_pipe         DB ?
rh_deleted      DB ?

req_handle_struc    ENDS

REQ_TYPE_WRITE_CONTROL   = 1
REQ_TYPE_WRITE_DATA = 2
REQ_TYPE_READ_DATA = 3
REQ_TYPE_STATUS_IN = 4
REQ_TYPE_STATUS_OUT = 5

REQ_FLAG_STARTED = 1
REQ_FLAG_ACTIVE  = 2

req_entry_struc STRUC

re_next     DW ?
re_size     DW ?
re_buf_sel      DW ?
re_type     DB ?

req_entry_struc ENDS

data    SEGMENT byte public 'DATA'

usb_enum_section    section_typ <>

usb_dev_count       DW ?
usb_dev_arr         DW 256 DUP(?)

usb_attach_hooks    DW ?
usb_attach_arr      DD 2 * MAX_ATTACH_HOOKS DUP(?)

usb_detach_hooks    DW ?
usb_detach_arr      DD 2 * MAX_DETACH_HOOKS DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateBuf32
;
;       description:    Allocate 32-bit buffer
;
;       parameters:     CX      Size
;
;       Returns:        EDX     Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBuf32   Proc near
    push eax
    push ebx
    push ecx
;
    movzx eax,cx
    AllocateBigLinear
;
    push edx

abLoop:
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    add edx,1000h
    loop abLoop
;
    pop edx
;
    pop ecx
    pop ebx
    pop eax        
    ret
AllocateBuf32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateBufSel
;
;       description:    Allocate buffer selector
;
;       parameters:     AX      Size
;                       DS      USB device sel
;
;       Returns:        ES      Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBufSel   Proc near
    call fword ptr ds:has_64bit_proc
    jnc abfNorm
;
    HasPhysical64
    jc abfNorm

abf32:
    push bx
    push ecx
    push edx
;
    movzx eax,ax
    mov ecx,eax
    call AllocateBuf32
    AllocateGdt
    CreateDataSelector16
    mov es,bx
;
    pop edx
    pop ecx
    pop bx    
    jmp abfDone

abfNorm:
    AllocateSmallGlobalMem

abfDone:        
    ret
AllocateBufSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleReadData
;
;       description:    Handle read data request
;
;       parameters:     DS:EBX  Handle data
;                       ES:EDI  Buffer
;                       CX      Size
;
;       Returns:        ES:EDI  Buffer to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleReadData  Proc near
    push eax
;    
    mov al,ds:[ebx].up_copy
    or al,al
    jz hrdDone
;
    push esi
    push edx
;    
    call AllocateBuf32
;
    mov si,es
    mov eax,SIZE pipe_copy_struc
    AllocateSmallGlobalMem
    mov es:pc_user_offset,edi
    mov es:pc_user_sel,si
    mov es:pc_usb_linear,edx
    mov es:pc_size,cx
;
    mov ax,ds:[ebx].up_list
    mov es:pc_next,ax
    mov ds:[ebx].up_list,es
;
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
;        
    pop edx
    pop esi

hrdDone:
    pop eax    
    ret
HandleReadData  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleWriteData
;
;       description:    Handle write data request
;
;       parameters:     DS:EBX  Handle data
;                       ES:EDI  Buffer
;                       CX      Size
;
;       Returns:        ES:EDI  Buffer to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleWriteData  Proc near
    push eax
;    
    mov al,ds:[ebx].up_copy
    or al,al
    jz hwdDone
;
    push edx
;    
    call AllocateBuf32
;
    push ds
    push esi
    push ecx
;
    mov esi,edi
    mov ax,es
    mov ds,ax
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
    movzx ecx,cx
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop ecx
    pop esi
    pop ds
;    
    mov eax,SIZE pipe_copy_struc
    AllocateSmallGlobalMem
    mov es:pc_user_offset,0
    mov es:pc_user_sel,0
    mov es:pc_usb_linear,edx
    mov es:pc_size,cx
;
    mov ax,ds:[ebx].up_list
    mov es:pc_next,ax
    mov ds:[ebx].up_list,es
;
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
;        
    pop edx

hwdDone:
    pop eax    
    ret
HandleWriteData  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CleanupData
;
;       description:    Cleanup after data transfer
;
;       parameters:     DS:EBX  Handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupData  Proc near  
    push eax
;    
    xor ax,ax
    xchg ax,ds:[ebx].up_list

cdLoop:    
    or ax,ax
    jz cdDone
;
    push es
    mov es,ax
;
    mov ax,es:pc_user_sel
    or ax,ax
    jz cdCopyOk
;
    push ds
    push es
    push ecx
    push esi
    push edi
;    
    movzx ecx,es:pc_size
    mov esi,es:pc_usb_linear
    mov ax,flat_sel
    mov ds,ax
    mov edi,es:pc_user_offset
    mov es,es:pc_user_sel
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds  

cdCopyOk:      
    push ecx
    push edx
;    
    mov edx,es:pc_usb_linear
    movzx ecx,es:pc_size
    FreeLinear
;
    pop edx
    pop ecx   
;     
    mov ax,es:pc_next
    FreeMem
;
    pop es    
    jmp cdLoop

cdDone:
    pop eax       
    ret
CleanupData  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CleanupPipe
;
;       description:    Cleanup after data transfer
;
;       parameters:     DS       User pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupPipe  Proc near  
    push eax
;    
    xor ax,ax
    xchg ax,ds:usbu_data_list

cpLoop:    
    or ax,ax
    jz cpDone
;
    push es
    mov es,ax
;
    mov ax,es:pc_user_sel
    or ax,ax
    jz cpCopyOk
;
    push ds
    push es
    push ecx
    push esi
    push edi
;    
    movzx ecx,es:pc_size
    mov esi,es:pc_usb_linear
    mov ax,flat_sel
    mov ds,ax
    mov edi,es:pc_user_offset
    mov es,es:pc_user_sel
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds  

cpCopyOk:      
    push ecx
    push edx
;    
    mov edx,es:pc_usb_linear
    movzx ecx,es:pc_size
    FreeLinear
;
    pop edx
    pop ecx   
;     
    mov ax,es:pc_next
    FreeMem
;
    pop es    
    jmp cpLoop

cpDone:
    pop eax       
    ret
CleanupPipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandlePipeRead
;
;       description:    Handle read data request
;
;       parameters:     DS      User pipe sel
;                       ES:EDI  Buffer
;                       CX      Size
;
;       Returns:        ES:EDI  Buffer to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePipeRead  Proc near
    push eax
;    
    mov al,ds:usbu_copy
    or al,al
    jz hprDone
;
    push esi
    push edx
;    
    call AllocateBuf32
;
    mov si,es
    mov eax,SIZE pipe_copy_struc
    AllocateSmallGlobalMem
    mov es:pc_user_offset,edi
    mov es:pc_user_sel,si
    mov es:pc_usb_linear,edx
    mov es:pc_size,cx
;
    mov ax,ds:usbu_data_list
    mov es:pc_next,ax
    mov ds:usbu_data_list,es
;
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
;        
    pop edx
    pop esi

hprDone:
    pop eax    
    ret
HandlePipeRead  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandlePipeWrite
;
;       description:    Handle write data request
;
;       parameters:     DS      User pipe sel
;                       ES:EDI  Buffer
;                       CX      Size
;
;       Returns:        ES:EDI  Buffer to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePipeWrite  Proc near
    push eax
;    
    mov al,ds:usbu_copy
    or al,al
    jz hpwDone
;
    push edx
;    
    call AllocateBuf32
;
    push ds
    push esi
    push ecx
;
    mov esi,edi
    mov ax,es
    mov ds,ax
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
    movzx ecx,cx
    rep movs byte ptr es:[edi],ds:[esi]
;
    pop ecx
    pop esi
    pop ds
;    
    mov eax,SIZE pipe_copy_struc
    AllocateSmallGlobalMem
    mov es:pc_user_offset,0
    mov es:pc_user_sel,0
    mov es:pc_usb_linear,edx
    mov es:pc_size,cx
;
    mov ax,ds:usbu_data_list
    mov es:pc_next,ax
    mov ds:usbu_data_list,es
;
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
;        
    pop edx

hpwDone:
    pop eax    
    ret
HandlePipeWrite  Endp

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
    InitSection ds:usb_section
    mov ax,ds
    mov es,ax
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usb_port_arr
    xor ax,ax
    rep stosw
;    
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usb_attach_thread_arr
    xor ax,ax
    rep stosw
;    
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usb_detach_thread_arr
    xor ax,ax
    rep stosw
;    
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usb_reset_thread_arr
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
    retf32
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
    mov ah,es:usbf_speed
    call fword ptr ds:create_control_proc
;    
    mov es:usbf_in_endpoint_arr,fs    
    mov es:usbf_out_endpoint_arr,fs    
    mov fs:usbp_function_sel,es
    mov fs:usbp_address,0
    mov fs:usbp_endpoint,0
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_CONTROL
    mov fs:usbp_maxlen,8
    mov fs:usbp_device_sel,0
    mov fs:usbp_signal,0
    mov fs:usbp_wait,0
;
    ClearSignal
    GetThread
    mov fs:usbp_signal,ax
;    
    push ds
    mov ax,fs
    mov ds,ax
    InitSection ds:usbp_section
    pop ds
;    
    mov ax,word ptr ds:address_device_proc+4
    or ax,ax
    jz cdcSendAddress
;
    pop ax
    mov fs:usbp_address,al
    call fword ptr ds:address_device_proc
    pushf
    jmp cdcDone        

cdcSendAddress:    
    mov eax,8
    call AllocateBufSel
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
    call fword ptr ds:add_setup_proc
    call fword ptr ds:add_status_in_proc
    call fword ptr ds:issue_transfer_proc
    pop ax
;  
    mov fs:usbp_address,al
;
    mov cx,100    

cdcLoop:
    call fword ptr ds:is_transfer_done_proc
    jnc cdcOk
;
    call fword ptr ds:is_connected_proc
    jc cdcFail
;
    mov ax,25
    WaitMilliSec
;
    loop cdcLoop

cdcFail:
    stc
    pushf
    jmp cdcDone
            
cdcOk:    
    call fword ptr ds:wait_for_completion_proc
    pushf
    FreeMem
    call fword ptr ds:change_address_proc

cdcDone:
    push ds
    mov cx,SEG data
    mov ds,cx
    LeaveSection ds:usb_enum_section
    pop ds
;        
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
;                       ES      Usb function selector
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
    mov ah,es:usbf_speed
    call fword ptr ds:create_bulk_proc    
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
    mov fs:usbp_endpoint,dl
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_BULK
    mov fs:usbp_maxlen,cx
    mov fs:usbp_device_sel,0
    mov fs:usbp_signal,0
    mov fs:usbp_wait,0
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
;                       ES      USB function selector
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
    mov ah,es:usbf_speed
    call fword ptr ds:create_interrupt_proc    
    movzx bx,dl
    and bx,0Fh
    add bx,bx    
    mov es:[bx].usbf_in_endpoint_arr,fs
;    
    and dl,0Fh
    mov fs:usbp_function_sel,es
    mov al,es:usbf_address
    mov fs:usbp_address,al
    mov fs:usbp_endpoint,dl
    mov fs:usbp_seq,0
    mov fs:usbp_mode,MODE_INTR
    mov fs:usbp_maxlen,cx
    mov fs:usbp_device_sel,0
    mov fs:usbp_signal,0
    mov fs:usbp_wait,0
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
    call AllocateBufSel
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
    call fword ptr ds:add_setup_proc
    pop cx
;
    pop edi
    pop cx
    pop es
;    
    call fword ptr ds:add_in_proc
    call fword ptr ds:add_status_out_proc
    call fword ptr ds:issue_transfer_proc
    call fword ptr ds:wait_for_completion_proc
;    
    pushf
    mov es,bx
    FreeMem    
    call fword ptr ds:get_data_size_proc
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
    push ax
    push bx
    push cx
    push es
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
    call fword ptr ds:close_pipe_proc
;
    pop es
    pop cx
    pop bx
    pop ax
    ret
ClosePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsValidUsbPipeSel
;
;           description:    Check if selector is a valid USB pipe selector
;
;       parameters:     DS      Device sel
;                       AX      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_valid_usb_pipe_sel_name  DB 'Is Valid USB Pipe Sel', 0

is_valid_usb_pipe_sel    Proc far
    push es
    push bx
    push cx
    push si
;    
    mov cx,MAX_USB_HUB_PORTS
    mov si,OFFSET usb_port_arr

ivupFunctionLoop:
    push cx
    mov cx,[si]
    or cx,cx
    jz ivupFunctionNext
;    
    mov es,cx
    mov cx,es:usb_function_sel
    or cx,cx
    jz ivupFunctionNext
;
    mov es,cx
    mov bx,OFFSET usbf_in_endpoint_arr
    mov cx,16

ivupCheckIn:
    cmp ax,es:[bx]
    je ivupOk
;
    add bx,2
    loop ivupCheckIn
;
    mov bx,OFFSET usbf_out_endpoint_arr
    mov cx,16            

ivupCheckOut:
    cmp ax,es:[bx]
    je ivupOk
;
    add bx,2
    loop ivupCheckOut

ivupFunctionNext:
    pop cx
    add si,2
    loop ivupFunctionLoop
;
    stc
    jmp ivupDone

ivupOk:
    pop cx
    clc

ivupDone:   
    pop si
    pop cx
    pop bx
    pop es
    retf32
is_valid_usb_pipe_sel    Endp    

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
    verr ax
    jnz ceDone

ceClose:
    push fs
;    
    mov fs,ax
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
;           PARAMETERS:     BX      Controller #
;                           AL      Device address (1..128)
;                           DS      USB device
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_usb_attach PROC near
    push ds
    push es
    push cx
    push si
;       
    mov cx,SEG data
    mov es,cx
    mov cx,es:usb_attach_hooks
    or cx,cx
    je trap_attach_done
    
    mov si,OFFSET usb_attach_arr

trap_attach_loop:
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    call fword ptr es:[si]
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
;       
    add si,8
    loop trap_attach_loop

trap_attach_done:
    pop si
    pop cx
    pop es
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
;           PARAMETERS:     BX      Controller #
;                           AL      Device address (1..128)
;                           DS      USB device
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_usb_detach PROC near
    push ds
    push es
    push cx
    push si
;       
    mov cx,SEG data
    mov es,cx
    mov cx,es:usb_detach_hooks
    or cx,cx
    je trap_detach_done
    
    mov si,OFFSET usb_detach_arr

trap_detach_loop:
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    call fword ptr es:[si]
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
;       
    add si,8
    loop trap_detach_loop

trap_detach_done:
    pop si
    pop cx
    pop es
    pop ds
    ret
trap_usb_detach ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockUsb
;
;           description:    Lock USB (for RESET)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_usb_name DB 'Lock USB', 0

lock_usb       Proc far
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:usb_enum_section
    pop ax
    pop ds
    retf32
lock_usb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockUsb
;
;           description:    Unlock USB (for RESET)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_usb_name DB 'Unlock USB', 0

unlock_usb       Proc far
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:usb_enum_section
    pop ax
    pop ds
    retf32
unlock_usb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddUsbFunction
;
;       Description:    Add USB function
;
;       Parameters:     DS      USB device selector
;                       ES      USB function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddUsbFunction       Proc near
    push fs
    push ax
    push bx
    push cx
    push di
;
    movzx bx,es:usbf_port
    add bx,bx
    mov ax,ds:[bx].usb_port_arr
    or ax,ax
    jnz aufAdd
;    
    push es
    mov eax,SIZE usb_port_struc
    AllocateSmallGlobalMem
    mov es:usb_handle_list,0
    mov es:usb_req_list,0
    mov es:usb_function_sel,0
    mov es:usb_port,bl
    InitSection es:usb_sync_section
;
    mov cx,16
    mov di,OFFSET usb_in_pipe_arr
    xor ax,ax
    rep stosw
;
    mov cx,16
    mov di,OFFSET usb_out_pipe_arr
    xor ax,ax
    rep stosw
;
    mov ax,es
    pop es
    mov ds:[bx].usb_port_arr,ax

aufAdd:
    mov fs,ax
    mov fs:usb_function_sel,es
;
    pop di
    pop cx
    pop bx
    pop ax
    pop fs
    ret
AddUsbFunction	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RemoveUsbFunction
;
;       Description:    Remove USB function
;
;       Parameters:     DS      USB device selector
;                       AL      Port
;
;       Returns:        NC
;                           ES  USB function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveUsbFunction       Proc near
    push ds
    push ax
    push ebx
;
    movzx bx,al
    add bx,bx
    mov ax,ds:[bx].usb_port_arr
    or ax,ax
    stc
    jz rufDone
;
    mov ds,ax
    EnterSection ds:usb_sync_section
;
    mov cx,16
    mov si,OFFSET usb_in_pipe_arr

rufInLoop:
    mov ax,ds:[si]
    or ax,ax
    jz rufInNext
;
    push ds
    mov ds,ax
    EnterSection ds:usbu_section
    mov ds:usbu_pipe_sel,0
    mov ds:usbu_deleted,1
    LeaveSection ds:usbu_section
    pop ds

rufInNext:
    add si,2
    loop rufInLoop
;
    mov cx,16
    mov si,OFFSET usb_out_pipe_arr

rufOutLoop:
    mov ax,ds:[si]
    or ax,ax
    jz rufOutNext
;
    push ds
    mov ds,ax
    EnterSection ds:usbu_section
    mov ds:usbu_pipe_sel,0
    mov ds:usbu_deleted,1
    LeaveSection ds:usbu_section
    pop ds

rufOutNext:
    add si,2
    loop rufOutLoop
;
    xor ax,ax
    xchg ax,ds:usb_function_sel
;
    mov ebx,ds:usb_handle_list
    or ebx,ebx
    jz rufHandleDone
;
    push ax
    GetThread
    mov es,ax    
    mov es,es:p_app_sel
    mov es,es:app_handle_mem_sel
    pop ax

rufHandleLoop:
    mov es:[ebx].up_deleted,1
    mov ebx,es:[ebx].up_handle_list
    or ebx,ebx
    jnz rufHandleLoop

rufHandleDone:
    mov ebx,ds:usb_req_list
    or ebx,ebx
    jz rufReqDone
;
    push ax
    GetThread
    mov es,ax    
    mov es,es:p_app_sel
    mov es,es:app_handle_mem_sel
    pop ax

rufReqLoop:
    mov es:[ebx].rh_deleted,1
    mov ebx,es:[ebx].rh_handle_list
    or ebx,ebx
    jnz rufReqLoop

rufReqDone:
    LeaveSection ds:usb_sync_section
;
    or ax,ax
    stc
    jz rufDone
;
    mov es,ax
    clc

rufDone:
    pop ebx
    pop ax
    pop ds
    ret
RemoveUsbFunction	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NotifyUsbAttach
;
;       Description:    Notify USB attach event
;
;       Parameters:     DS      USB device selector
;                       ES      USB function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_usb_attach_name DB 'Notify USB Attach', 0

attach_text DB 'Attach', 0

notify_usb_attach       Proc far
    push gs
    push fs
    push es
    pushad
;
    mov al,es:usbf_slot
    or al,al
    jnz nuaSlot
;
    push es
    mov ax,ds
    mov es,ax
;
    mov di,OFFSET usb_addr_arr
    mov cx,128
    add di,2
    xor ax,ax
    repnz scasw
    sub di,2
    sub di,OFFSET usb_addr_arr
    shr di,1
    mov ax,di
    pop es
    
nuaSlot:
    mov es:usbf_address,al
    movzx di,al
    add di,di
    add di,OFFSET usb_addr_arr
    mov ds:[di],es
;
    call AddUsbFunction
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
    call AllocateBufSel

nuaRetry:
    call fword ptr ds:is_connected_proc
    jc nuaFreeDone
;
    xor edi,edi
    mov cx,8
    mov ax,100h
    call GetDescr
    movzx ax,es:udd_maxlen
    or ax,ax
    jz nuaRetry
;
    cmp ax,fs:usbp_maxlen
    je nuaLenOk
;    
    mov fs:usbp_maxlen,ax
    call fword ptr ds:set_max_len_proc
    
nuaLenOk:
    movzx eax,es:udd_len
    FreeMem
;
    call fword ptr ds:is_connected_proc
    jc nuaDone
;    
    call AllocateBufSel
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
    call fword ptr ds:is_connected_proc
    jc nuaDone
;    
    mov eax,8
    call AllocateBufSel
    xor edi,edi
    mov cx,8
    mov al,bl
    mov ah,2
    call GetDescr
    movzx eax,es:ucd_size
    FreeMem
;
    call fword ptr ds:is_connected_proc
    jc nuaDone
;
    call AllocateBufSel
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
    call fword ptr ds:is_connected_proc
    jc nuaDone
;    
    xor ax,ax
    mov gs,ax
    mov bx,ds:usb_controller_id
    mov al,fs:usbp_address
    call trap_usb_attach
    clc
    jmp nuaDone

nuaFreeDone:
    FreeMem    
    stc
    
nuaDone:
    mov fs:usbp_signal,0
;
    jnc nuaPipeOk
;
    call fword ptr ds:is_connected_proc
    jc nuaDoClose
;
    call fword ptr ds:close_control_pipe_proc

nuaDoClose:
    call ClosePipe
    stc

nuaPipeOk:
    popad
    pop es
    pop fs
    pop gs
    retf32
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

detach_text DB 'Detach', 0

notify_usb_detach       Proc far
    push es
    pushad
;
    call RemoveUsbFunction
    jc nudDone
; 
    mov bx,ds:usb_controller_id
    mov al,es:usbf_address
    call trap_usb_detach      
    call CloseDevice

nudDone:    
    popad
    pop es
    retf32
notify_usb_detach   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CleanupReq
;
;           DESCRIPTION:    Clean up req handle
;
;           PARAMETERS:     DS:EBX          Handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupReq	Proc near
    push ds
    push es
    push eax
    push esi
    push bp
;
    mov bp,ds:[ebx].rh_port_sel
    mov es,bp
;
    push ds
    mov ds,bp
    EnterSection ds:usb_sync_section
    pop ds
;
    mov esi,es:usb_req_list    
    cmp ebx,esi
    jne crListLoop
;
    mov esi,ds:[esi].rh_handle_list
    mov es:rh_handle_list,esi
    jmp crListDone

crListLoop:
    cmp ebx,ds:[esi].rh_handle_list
    jne crListNext
;
    mov eax,ds:[ebx].rh_handle_list
    mov ds:[esi].rh_handle_list,eax
    jmp crListDone

crListNext:
    mov esi,ds:[esi].rh_handle_list
    or esi,esi
    jnz crListLoop

crListDone:    
    mov ds,bp
    LeaveSection ds:usb_sync_section
;
    pop bp
    pop esi
    pop eax
    pop es
    pop ds
    ret
CleanupReq	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddReqBlock
;
;           description:    Add an request block
;
;       parameters:     DS:EBX   Req handle struc
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
    mov ax,ds:[ebx].rh_list
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
    mov ds:[ebx].rh_list,es

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
    push bp
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc curDone
;       
    mov al,ds:[ebx].up_deleted
    or al,al
    stc
    jnz curDone
;
    mov ax,ds:[ebx].up_func_sel
    mov dl,ds:[ebx].up_pipe
    mov bp,ds:[ebx].up_port_sel
;
    mov ds,bp
    EnterSection ds:usb_sync_section
    mov esi,ds:usb_req_list
;       
    mov cx,SIZE req_handle_struc
    AllocateHandle
    mov [ebx].rh_func_sel,ax
    mov [ebx].rh_port_sel,bp
    mov [ebx].rh_handle_list,esi
    mov [ebx].rh_list,0
    mov [ebx].rh_signal,0
    mov [ebx].rh_flags,0
    mov [ebx].rh_deleted,0
    mov [ebx].rh_pipe,dl
    mov [ebx].hh_sign,USB_REQ_HANDLE
    mov esi,ebx
    mov bx,[ebx].hh_handle
;
    mov ds,bp
    mov ds:usb_req_list,esi
    LeaveSection ds:usb_sync_section
    clc

curDone:
    pop bp
    pop cx
    pop ax
    pop fs
    pop ds
    retf32
create_usb_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddWriteUsbControlReq
;
;       description:    Add write control req
;
;       parameters:     BX      Req handle
;                       CX      Size of data
;                       AX      Additional data size
;
;       Returns:        ES      Data selector (do not free)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_write_usb_control_req_name DB 'Add Write USB control req', 0

add_write_usb_control_req       Proc far
    push ds
    push eax
    push ebx
;
    push ax
    mov ax,USB_REQ_HANDLE
    DerefHandle
    pop ax
    jc awucDone
;
    push ds
    mov ds,ds:[ebx].rh_func_sel
    movzx eax,ax
    call AllocateBufSel     
    mov ax,es
    pop ds
;    
    call AddReqBlock
    mov es:re_type,REQ_TYPE_WRITE_CONTROL
    mov es:re_size,cx
    mov es:re_buf_sel,ax
    mov es,ax    
    clc
    
awucDone:    
    pop ebx
    pop eax
    pop ds
    retf32
add_write_usb_control_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddWriteUsbDataReq
;
;       description:    Add write data req
;
;       parameters:     BX      Req handle
;                       CX      Size of data
;                       AX      Additional data size
;               
;       Returns:        ES      Data selector (do not free)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_write_usb_data_req_name DB 'Add Write USB data req', 0

add_write_usb_data_req  Proc far
    push ds
    push ax
    push ebx
;
    push ax
    mov ax,USB_REQ_HANDLE
    DerefHandle
    pop ax
    jc awudDone
;
    push ds
    mov ds,ds:[ebx].rh_func_sel
    add ax,cx
    movzx eax,ax
    call AllocateBufSel     
    mov ax,es
    pop ds
;
    call AddReqBlock
    mov es:re_type,REQ_TYPE_WRITE_DATA
    mov es:re_size,cx
    mov es:re_buf_sel,ax
    mov es,ax    
    clc
    
awudDone:    
    pop ebx
    pop ax
    pop ds
    retf32
add_write_usb_data_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddReadUsbDataReq
;
;       description:    Add read data req
;
;       parameters:     BX      Req handle
;                       CX      Size of data
;                       AX      Additional data size
;               
;       Returns:        ES      Data selector (do not free)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_read_usb_data_req_name DB 'Add Read USB data req', 0

add_read_usb_data_req   Proc far
    push ds
    push ax
    push ebx
;
    push ax
    mov ax,USB_REQ_HANDLE
    DerefHandle
    pop ax
    jc arudDone
;
    push ds
    mov ds,ds:[ebx].rh_func_sel
    add ax,cx
    movzx eax,ax
    call AllocateBufSel     
    mov ax,es
    pop ds
;
    call AddReqBlock
    mov es:re_type,REQ_TYPE_READ_DATA
    mov es:re_size,cx
    mov es:re_buf_sel,ax
    mov es,ax
    clc
    
arudDone:    
    pop ebx
    pop ax
    pop ds
    retf32
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
    push ebx
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
    pop ebx
    pop ax
    pop es
    pop ds
    retf32
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
    push ebx
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
    pop ebx
    pop ax
    pop es
    pop ds
    retf32
add_usb_status_out_req   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LockReqPipe
;
;           DESCRIPTION:    Lock and get pipe & function selector from handle
;
;           PARAMETERS:     DS:EBX          Handle data
;
;           RETURNS:        NC	
;				DS          Function sel
;                           	FS	    Pipe sel
;                           BP              Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockReqPipe	Proc near
    push ax
    push dx
    push si
    push di
;
    mov bp,ds:[ebx].rh_port_sel
    mov di,ds:[ebx].rh_func_sel
    mov dl,ds:[ebx].rh_pipe
    mov ds,bp
    EnterSection ds:usb_sync_section
    mov ax,ds:usb_function_sel
    or ax,ax
    jz lrpFail
;
    mov ds,ax
    and dl,8Fh
    test dl,80h
    jz lrpOut    

lrpIn:
    movzx si,dl
    and si,0Fh
    add si,si
    mov ax,ds:[si].usbf_in_endpoint_arr
    or ax,ax
    jnz lrpOk
;
    jmp lrpFail

lrpOut:
    movzx si,dl
    add si,si
    mov ax,ds:[si].usbf_out_endpoint_arr
    or ax,ax
    jnz lrpOk    

lrpFail:
    xor ax,ax
    mov ds,ax
    mov fs,ax
    stc
    jmp lrpDone

lrpOk:
    mov ds,di
    mov fs,ax
    clc

lrpDone:
    pop di
    pop si
    pop dx
    pop ax
    ret
LockReqPipe	Endp


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
    call fword ptr ds:add_setup_proc
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
    call fword ptr ds:add_out_proc
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
    call fword ptr ds:add_in_proc
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
    call fword ptr ds:add_status_in_proc
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
    call fword ptr ds:add_status_out_proc
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
    push ebx
    push bp
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc surDone
;
    mov al,ds:[ebx].rh_deleted
    or al,al
    stc
    jnz surDone
;
    or ds:[ebx].rh_flags,REQ_FLAG_STARTED OR REQ_FLAG_ACTIVE
    mov ax,ds:[ebx].rh_list
;
    call LockReqPipe
    jc surLeave
;
    call fword ptr ds:end_transfer_proc

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
    GetThread
    mov fs:usbp_signal,ax
    call fword ptr ds:issue_transfer_proc

surLeave:
    mov ds,bp
    LeaveSection ds:usb_sync_section

surDone:    
    pop bp
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
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
    push ebx
    push bp
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc sturEnd
;
    mov al,ds:[ebx].rh_deleted
    or al,al
    stc
    jnz sturDone
;
    push ds
    push ebx
;
    call LockReqPipe
    jc sturLeave
;
    call fword ptr ds:end_transfer_proc

sturLeave:
    mov ds,bp
    LeaveSection ds:usb_sync_section
;
    pop ebx
    pop ds
;
    mov ax,5
    WaitMilliSec    

sturDone:
    and ds:[ebx].rh_flags,NOT (REQ_FLAG_STARTED OR REQ_FLAG_ACTIVE)

sturEnd:
    pop bp
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
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
    push ebx
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc iursDone
;
    test ds:[ebx].rh_flags,REQ_FLAG_STARTED
    stc
    jz iursDone
;
    clc

iursDone:       
    pop ebx
    pop ax
    pop ds
    retf32
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
    push ebx
    push bp
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc iurrDone
;
    mov al,ds:[ebx].rh_deleted
    or al,al
    clc
    jnz iurrDone
;
    test ds:[ebx].rh_flags,REQ_FLAG_ACTIVE
    stc
    jz iurrDone
;
    push ds
    push ebx
;
    call LockReqPipe
    jc iurrLeave
;
    call fword ptr ds:is_transfer_done_proc

iurrLeave:
    mov ds,bp
    LeaveSection ds:usb_sync_section
;
    pop ebx
    pop ds
    jc iurrDone
;
    and ds:[ebx].rh_flags,NOT REQ_FLAG_STARTED
    clc
    
iurrDone:       
    pop bp
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
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
    push ebx
    push bp
;
    xor cx,cx
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc gurdDone
;
    mov al,ds:[ebx].rh_deleted
    or al,al
    stc
    jnz gurdDone
;
    test ds:[ebx].rh_flags,REQ_FLAG_ACTIVE
    stc
    jz gurdDone
;
    mov ax,ds:[ebx].rh_list
    call LockReqPipe
    jc gurdLeave
;
    call fword ptr ds:was_transfer_ok_proc
    jc gurdLeave

gurdReqLoop:
    or ax,ax
    clc
    jz gurdLeave
;
    mov es,ax
    mov al,es:re_type
    cmp al,REQ_TYPE_READ_DATA
    jne gurdNext
;    
    call fword ptr ds:get_data_size_proc
    jmp gurdLeave

gurdNext:
    mov ax,es:re_next    
    jmp gurdReqLoop

gurdLeave:
    mov ds,bp
    LeaveSection ds:usb_sync_section

gurdDone:       
    pop bp
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
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
    push bp
;
    mov ax,USB_REQ_HANDLE
    DerefHandle
    jc crDone
;
    call CleanupReq
    mov al,ds:[ebx].rh_deleted
    or al,al
    jnz crFreeList
;
    test ds:[ebx].rh_flags,REQ_FLAG_STARTED
    jz crFreeList
;
    push ds
    push ebx
;
    call LockReqPipe
    jc curLeave
;
    call fword ptr ds:end_transfer_proc

curLeave:
    mov ds,bp
    LeaveSection ds:usb_sync_section
;
    pop ebx
    pop ds
;    
    mov ax,5
    WaitMilliSec    

crFreeList:
    mov ax,ds:[ebx].rh_list

crFreeLoop:
    or ax,ax
    jz crFreeHandle
;
    cmp ax,-1
    jz crFreeHandle
;
    mov es,ax
    mov ax,es:re_buf_sel
    or ax,ax
    jz crBufFree
;
    push es
    mov es,ax
    FreeMem
    pop es
    
crBufFree:    
    mov ax,es:re_next    
    FreeMem
    jmp crFreeLoop

crFreeHandle:
   FreeHandle

crDone: 
    pop bp
    pop ax
    pop fs
    pop es
    pop ds
    retf32
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
    retf32
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
    retf32
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
    push bx
    push cx
    push esi
    push edi
    push bp
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
    movzx si,fs:usbf_port
    add si,si
    mov bp,ds:[si].usb_port_arr
;
    mov si,fs:usbf_in_endpoint_arr
    or si,si
    jz cudFail
;
    mov fs,si    
    ClearSignal
    GetThread
    mov fs:usbp_signal,ax
;
    mov eax,8
    call AllocateBufSel
    xor edi,edi
    mov es:usd_type,0
    mov es:usd_req,SET_CONFIG
    movzx ax,dl
    mov es:usd_value,ax
    mov es:usd_index,0
    mov es:usd_len,0
;    
    mov cx,8
    call fword ptr ds:add_setup_proc
    call fword ptr ds:add_status_in_proc
    call fword ptr ds:issue_transfer_proc
    call fword ptr ds:wait_for_completion_proc
    call fword ptr ds:was_transfer_ok_proc
;
    mov fs:usbp_signal,0
;
    pushf
    FreeMem
    popf
    jc cudFail
;
    mov cx,16
    xor si,si
    mov es,fs:usbp_function_sel

cudFindConfigLoop:
    mov ax,fs:[si].usbp_config_sel
    or ax,ax
    jz cudFindConfigNext
;
    mov gs,ax
    cmp dl,gs:ucd_config_id
    je cudFindConfigOk

cudFindConfigNext:
    add si,2
    loop cudFindConfigLoop
;
    jmp cudFail

cudFindConfigOk:
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
    or cx,cx
    jz cudFail
;
    add di,cx
    cmp di,gs:ucd_size
    jb cudDescrLoop    
;
    or bp,bp
    jz cudConfig
;
    push ds
    mov ds,bp
    EnterSection ds:usb_sync_section
;
    mov cx,16
    mov si,OFFSET usb_in_pipe_arr
    mov di,OFFSET usbf_in_endpoint_arr

cudInLoop:
    mov ax,ds:[si]
    or ax,ax
    jz cudInNext
;
    push ds
    mov ds,ax
    EnterSection ds:usbu_section
    mov ax,es:[di]
    mov ds:usbu_pipe_sel,ax
    LeaveSection ds:usbu_section
    pop ds

cudInNext:
    add si,2
    add di,2
    loop cudInLoop
;
    mov cx,16
    mov si,OFFSET usb_out_pipe_arr
    mov di,OFFSET usbf_out_endpoint_arr

cudOutLoop:
    mov ax,ds:[si]
    or ax,ax
    jz cudOutNext
;
    push ds
    mov ds,ax
    EnterSection ds:usbu_section
    mov ax,es:[di]
    mov ds:usbu_pipe_sel,ax
    LeaveSection ds:usbu_section
    pop ds

cudOutNext:
    add si,2
    add di,2
    loop cudOutLoop
;
    LeaveSection ds:usb_sync_section
    pop ds

cudConfig:
    mov ax,word ptr ds:config_device_proc+4
    or ax,ax
    clc
    jz cudDone
;
    call fword ptr ds:config_device_proc
    jmp cudDone

cudFail:
    stc
    
cudDone: 
    pop bp
    pop edi
    pop esi
    pop cx
    pop bx
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
;   NAME:           GetUsbInterface
;
;   description:    Get USB interface
;
;   parameters:     BX      Controller #
;                   AL      Device address (1..128)
;                   DX      Interface #
;
;   Returns:        CL      Alt setting
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_interface_name DB 'Get USB Interface', 0

get_usb_interface       Proc far
    push ds
    push es
    push fs
    push ax
    push bx
    push esi
    push edi
;    
    xor cl,cl
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_dev_count
    cmp bx,si
    jae guiFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz guiFail
;
    mov ds,si
    cmp al,128
    jae guiFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_addr_arr
    or si,si
    jz guiFail
;
    mov fs,si
    mov si,fs:usbf_in_endpoint_arr
    or si,si
    jz guiFail
;
    mov fs,si    
    ClearSignal
    GetThread
    mov fs:usbp_signal,ax
;
    mov eax,9
    call AllocateBufSel
    xor edi,edi
    mov es:usd_type,81h
    mov es:usd_req,GET_INTERFACE
    mov es:usd_value,0
    mov es:usd_index,dx
    mov es:usd_len,1
;    
    mov cx,8
    call fword ptr ds:add_setup_proc
;
    mov edi,8
    xor dl,dl
    mov es:[edi],dl
    mov cx,1
    call fword ptr ds:add_in_proc
    call fword ptr ds:add_status_out_proc
    call fword ptr ds:issue_transfer_proc
    call fword ptr ds:wait_for_completion_proc
    mov fs:usbp_signal,0
;
    pushf
    call fword ptr ds:get_data_size_proc
    mov cl,es:[edi]
    FreeMem
    popf
    jmp guiDone

guiFail:
    stc
    
guiDone: 
    pop edi
    pop esi
    pop bx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
get_usb_interface    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetUsbInterface
;
;   description:    Set USB interface
;
;   parameters:     BX      Controller #
;                   AL      Device address (1..128)
;                   DX      Interface #
;                   CL      Alt setting
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_usb_interface_name DB 'Set USB Interface', 0

set_usb_interface       Proc far
    push ds
    push es
    push fs
    push ax
    push bx
    push cx
    push esi
    push edi
;    
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_dev_count
    cmp bx,si
    jae suiFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz suiFail
;
    mov ds,si
    cmp al,128
    jae suiFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_addr_arr
    or si,si
    jz suiFail
;
    mov fs,si
    mov si,fs:usbf_in_endpoint_arr
    or si,si
    jz suiFail
;
    mov fs,si    
    ClearSignal
    GetThread
    mov fs:usbp_signal,ax
;
    mov eax,8
    call AllocateBufSel
    xor edi,edi
    mov es:usd_type,1
    mov es:usd_req,SET_INTERFACE
    movzx ax,cl
    mov es:usd_value,ax
    mov es:usd_index,dx
    mov es:usd_len,0
;    
    mov cx,8
    call fword ptr ds:add_setup_proc
    call fword ptr ds:add_status_in_proc
    call fword ptr ds:issue_transfer_proc
    call fword ptr ds:wait_for_completion_proc
    mov fs:usbp_signal,0
;
    pushf
    FreeMem
    popf
    jmp suiDone

suiFail:
    stc
    
suiDone: 
    pop edi
    pop esi
    pop cx
    pop bx
    pop ax
    pop fs
    pop es
    pop ds
    retf32
set_usb_interface    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CleanupHandle
;
;           DESCRIPTION:    Clean up USB handle
;
;           PARAMETERS:     DS:EBX          Handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupHandle	Proc near
    push ds
    push es
    push eax
    push esi
    push bp
;
    mov bp,ds:[ebx].up_port_sel
    mov es,bp
;
    push ds
    mov ds,bp
    EnterSection ds:usb_sync_section
    pop ds
;
    mov esi,es:usb_handle_list    
    cmp ebx,esi
    jne chListLoop
;
    mov esi,ds:[esi].up_handle_list
    mov es:usb_handle_list,esi
    jmp chListDone

chListLoop:
    cmp ebx,ds:[esi].up_handle_list
    jne chListNext
;
    mov eax,ds:[ebx].up_handle_list
    mov ds:[esi].up_handle_list,eax
    jmp chListDone

chListNext:
    mov esi,ds:[esi].up_handle_list
    or esi,esi
    jnz chListLoop

chListDone:    
    call CleanupData
    mov ds,bp
    LeaveSection ds:usb_sync_section
;
    pop bp
    pop esi
    pop eax
    pop es
    pop ds
    ret
CleanupHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LockAndGetPipe
;
;           DESCRIPTION:    Lock and get pipe & function selector from handle
;
;           PARAMETERS:     DS:EBX          Handle data
;
;           RETURNS:        NC	
;				DS          Function sel
;                           	FS	    Pipe sel
;                           BP              Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockAndGetPipe	Proc near
    push ax
    push dx
    push si
    push di
;
    mov bp,ds:[ebx].up_port_sel
    mov di,ds:[ebx].up_func_sel
    mov dl,ds:[ebx].up_pipe
    mov ds,bp
    EnterSection ds:usb_sync_section
    mov ax,ds:usb_function_sel
    or ax,ax
    jz lgpFail
;
    mov ds,ax
    and dl,8Fh
    test dl,80h
    jz lgpOut    

lgpIn:
    movzx si,dl
    and si,0Fh
    add si,si
    mov ax,ds:[si].usbf_in_endpoint_arr
    or ax,ax
    jnz lgpOk
;
    jmp lgpFail

lgpOut:
    movzx si,dl
    add si,si
    mov ax,ds:[si].usbf_out_endpoint_arr
    or ax,ax
    jnz lgpOk    

lgpFail:
    xor ax,ax
    mov ds,ax
    mov fs,ax
    stc
    jmp lgpDone

lgpOk:
    mov ds,di
    mov fs,ax
    clc

lgpDone:
    pop di
    pop si
    pop dx
    pop ax
    ret
LockAndGetPipe	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       CreateUserPipe
;
;       description:    Create user pipe
;
;       parameters:     DS	Port sel
;                       ES      Function sel
;                       DL      Pipe #
;                       DH      Copy
;
;       RETURNS:        AX      User pipe
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateUserPipe	Proc near
    push ds
    push es
    push bx
    push si
;
    mov bx,es
    mov eax,SIZE usb_user_pipe_struc
    AllocateSmallGlobalMem
;
    InitSection es:usbu_section
    mov es:usbu_func_sel,bx
    mov es:usbu_port_sel,ds
    mov es:usbu_data_list,0
    mov es:usbu_pipe,dl
    mov es:usbu_copy,dh
    mov es:usbu_deleted,0
;
    mov ax,ds:usb_function_sel
    or ax,ax
    jz cupSave
;
    mov ds,ax
    and dl,8Fh
    test dl,80h
    jz cupOut    

cupIn:
    movzx si,dl
    and si,0Fh
    add si,si
    mov ax,ds:[si].usbf_in_endpoint_arr
    jmp cupSave

cupOut:
    movzx si,dl
    add si,si
    mov ax,ds:[si].usbf_out_endpoint_arr
    jmp cupSave

cupSave:
    mov es:usbu_pipe_sel,ax
    mov ax,es
;
    pop si
    pop bx
    pop es
    pop ds
    ret
CreateUserPipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       OpenUsbPipe
;
;       description:    Open USB pipe
;
;       parameters:     BX      Controller #
;                       AL      Device address (1..128)
;                       DL      Pipe # (bit 7 is direction)
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
    push esi
    push edi
    push ebp
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
    mov fs,si
    movzx bx,fs:usbf_port
    add bx,bx
    mov bp,es:[bx].usb_port_arr
    or bp,bp
    jz oupFail
;
    xor dh,dh
    and dl,8Fh
;
    mov ax,es
    mov ds,ax
    call fword ptr ds:has_64bit_proc
    jnc oupAlloc
;
    HasPhysical64
    jc oupAlloc
;
    mov dh,1

oupAlloc:
    mov ds,bp
    and dl,8Fh
    test dl,80h
    jz oupOut    

oupIn:
    movzx si,dl
    and si,0Fh
    add si,si
    mov ax,ds:[si].usb_in_pipe_arr
    or ax,ax
    jnz oupOk
;
    call CreateUserPipe
    mov ds:[si].usb_in_pipe_arr,ax
    jmp oupOk

oupOut:
    movzx si,dl
    add si,si
    mov ax,ds:[si].usb_out_pipe_arr
    or ax,ax
    jnz oupOk    
;
    call CreateUserPipe
    mov ds:[si].usb_out_pipe_arr,ax

oupOk:
    mov esi,ds:usb_handle_list
    mov cx,SIZE pipe_handle_struc
    AllocateHandle
    mov [ebx].up_func_sel,es
    mov [ebx].up_pipe_sel,ax
    mov [ebx].up_pipe,dl
    mov [ebx].up_copy,dh
    mov [ebx].up_list,0
    mov [ebx].up_handle_list,esi
    mov [ebx].up_port_sel,bp
    mov [ebx].up_deleted,0
    mov [ebx].hh_sign,USB_PIPE_HANDLE
    mov esi,ebx
    mov bx,[ebx].hh_handle
;
    mov ds,bp
    mov ds:usb_handle_list,esi
    clc
    jmp oupDone

oupFail:
    stc

oupDone:
    pop ebp
    pop edi
    pop esi
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
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc cupDone
;
    call CleanupHandle
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz cupFree
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz cupLeave
;
    mov fs,ax
    mov fs:usbp_signal,0
    mov fs:usbp_wait,0

cupLeave:
    LeaveSection ds:usbu_section

cupFree:
    mov ds:usbu_deleted,0
;
    FreeHandle
    clc

cupDone:
    pop ebx
    pop ds
    retf32
close_usb_pipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetUsbPipe
;
;           DESCRIPTION:    Reset USB pipe
;
;           PARAMETERS:         BX          Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_usb_pipe_name  DB 'Reset USB Pipe',0

reset_usb_pipe     Proc far
    push ds
    push fs
    push ax
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc rupDone
;
    mov ds,ds:[ebx].up_pipe_sel
    call CleanupPipe
;
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz rupDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz rupLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:reset_pipe_proc
    pop ds

rupLeave:
    LeaveSection ds:usbu_section

rupDone:
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
reset_usb_pipe     Endp

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
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc delete_handle_done
;
    call CleanupHandle
    FreeHandle
    clc

delete_handle_done:
    pop ebx
    pop ds
    retf32
delete_handle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           LockWaitPipe
;
;           DESCRIPTION:    Lock and get pipe & function selector from wait object
;
;           PARAMETERS:     ES	            Wait object
;
;           RETURNS:        NC	
;				DS          Function sel
;                           	FS	    Pipe sel
;                           BP              Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockWaitPipe	Proc near
    push ax
    push dx
    push si
    push di
;
    mov bp,es:pw_port_sel
    mov di,es:pw_func_sel
    mov dl,es:pw_pipe
    mov ds,bp
    EnterSection ds:usb_sync_section
    mov ax,ds:usb_function_sel
    or ax,ax
    jz lwpFail
;
    mov ds,ax
    and dl,8Fh
    test dl,80h
    jz lwpOut    

lwpIn:
    movzx si,dl
    and si,0Fh
    add si,si
    mov ax,ds:[si].usbf_in_endpoint_arr
    or ax,ax
    jnz lwpOk
;
    jmp lwpFail

lwpOut:
    movzx si,dl
    add si,si
    mov ax,ds:[si].usbf_out_endpoint_arr
    or ax,ax
    jnz lwpOk    

lwpFail:
    xor ax,ax
    mov ds,ax
    mov fs,ax
    stc
    jmp lwpDone

lwpOk:
    mov ds,di
    mov fs,ax
    clc

lwpDone:
    pop di
    pop si
    pop dx
    pop ax
    ret
LockWaitPipe	Endp
    
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
    push bp
;
    call LockWaitPipe
    jc swfpSignal
;
    mov fs:usbp_wait,es
;
    call fword ptr ds:is_transfer_done_proc
    jc swfpDone
;    
    mov fs:usbp_wait,0

swfpSignal:
    SignalWait

swfpDone:
    mov ds,bp
    LeaveSection ds:usb_sync_section
;
    pop bp
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
    push bp
;
    call LockWaitPipe
    jc swDone
;
    mov fs:usbp_wait,0

swDone:
    mov ds,bp
    LeaveSection ds:usb_sync_section
;
    pop bp
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
    push bp
;
    call LockWaitPipe
    jc ipdDone
;
    call fword ptr ds:is_transfer_done_proc
    cmc

ipdDone:
    mov ds,bp
    LeaveSection ds:usb_sync_section
;
    pop bp
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
    push ebx
    push edx
    push edi
;
    push bx
    mov bx,ax
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc add_wait_pop_done
;
    mov fs,ds:[ebx].up_port_sel
    mov dl,ds:[ebx].up_pipe
    mov ds,ds:[ebx].up_func_sel
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
    mov es:pw_port_sel,fs
    mov es:pw_pipe,dl
    clc
    jmp add_wait_done

add_wait_pop_done:
    pop bx
    
add_wait_done:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    retf32
add_wait_for_pipe       ENDP

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
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc wucDone16
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz wucDone16
;
    push es
    push edi
;    
    movzx edi,di
    call HandlePipeWrite
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz wucLeave16
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_setup_proc
    pop ds

wucLeave16:
    LeaveSection ds:usbu_section
;
    pop edi
    pop es

wucDone16:
    pop cx
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
write_usb_control16     Endp

write_usb_control32     Proc far
    push ds
    push fs
    push ax
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc wucDone32
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz wucDone32
;
    push es
    push edi
;
    call HandlePipeWrite 
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz wucLeave32
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_setup_proc
    pop ds

wucLeave32:
    LeaveSection ds:usbu_section
;
    pop edi
    pop es    

wucDone32:
    pop cx
    pop ebx
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
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc rudDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz rudDone
;
    push es
    push edi
;
    call HandlePipeRead
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz rudLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_in_proc
    pop ds

rudLeave:
    LeaveSection ds:usbu_section
;
    pop edi
    pop es    

rudDone:
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
req_usb_data    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReqUsbDataNoCopy
;
;           DESCRIPTION:    Setup request for input data on pipe, low buffer memory
;
;           PARAMETERS:     BX          Pipe handle
;                           CX          Size of buffer
;                           ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_usb_data_no_copy_name       DB 'Request USB Data, No Copy',0

req_usb_data_no_copy    Proc far
    push ds
    push fs
    push ax
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc rudncDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz rudncDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz rudncLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_in_proc
    pop ds

rudncLeave:
    LeaveSection ds:usbu_section

rudncDone:
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
req_usb_data_no_copy    Endp


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
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc gudFail16
;
    mov ds,ds:[ebx].up_pipe_sel
    call CleanupPipe
;    
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz gudFail16
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz gudLeave16
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:get_data_size_proc
    pop ds

gudLeave16:
    LeaveSection ds:usbu_section
    jc gudFail16
;
    mov ax,cx
    clc
    jmp gudDone16

gudFail16:
    xor ax,ax
    stc

gudDone16:
    pop cx
    pop ebx
    pop fs
    pop ds
    retf32
get_usb_data_size16     Endp

get_usb_data_size32     Proc far
    push ds
    push fs
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc gudFail32
;
    mov ds,ds:[ebx].up_pipe_sel
    call CleanupPipe
;
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz gudFail32
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz gudLeave32
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:get_data_size_proc
    pop ds

gudLeave32:
    LeaveSection ds:usbu_section
    jc gudFail32
;
    movzx eax,cx
    jmp gudDone32

gudFail32:
    xor eax,eax

gudDone32:
    pop cx
    pop ebx
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
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc wudDone16
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz wudDone16
;
    push es
    push edi
;    
    movzx edi,di
    call HandlePipeWrite
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz wudLeave16
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_out_proc
    pop ds

wudLeave16:
    LeaveSection ds:usbu_section
;
    pop edi
    pop es

wudDone16:
    pop cx
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
write_usb_data16    Endp

write_usb_data32    Proc far
    push ds
    push fs
    push ax
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc wudDone32
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz wudDone32
;
    push es
    push edi
;
    call HandlePipeWrite
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz wudLeave32
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_out_proc
    pop ds

wudLeave32:
    LeaveSection ds:usbu_section
;   
    pop edi
    pop es    

wudDone32:
    pop cx
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
write_usb_data32    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WriteUsbDataNoCopy
;
;           DESCRIPTION:    Write USB data
;
;           PARAMETERS:     BX          Pipe handle
;                           CX      Size of data to request
;                           ES:(E)DI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_usb_data_no_copy_name     DB 'Write USB Data, No Copy',0

write_usb_data_no_copy    Proc far
    push ds
    push fs
    push ax
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc wudncDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz wudncDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz wudncLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_out_proc
    pop ds

wudncLeave:
    LeaveSection ds:usbu_section

wudncDone:
    pop cx
    pop ebx
    pop ax
    pop fs
    pop ds
    retf32
write_usb_data_no_copy    Endp


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
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc rusDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz rusDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz rusLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_status_in_proc
    pop ds

rusLeave:
    LeaveSection ds:usbu_section

rusDone:
    pop cx
    pop ebx
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
    push ebx
    push cx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc wusDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz wusDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz wusLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:add_status_out_proc
    pop ds

wusLeave:
    LeaveSection ds:usbu_section

wusDone:
    pop cx
    pop ebx
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
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc sutDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz sutDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz sutLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:issue_transfer_proc
    pop ds

sutLeave:
    LeaveSection ds:usbu_section

sutDone:
    pop ebx
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
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc iutdDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz iutdDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz iutdLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:is_transfer_done_proc
    pop ds

iutdLeave:
    LeaveSection ds:usbu_section

iutdDone:
    pop ebx
    pop fs
    pop ds
    retf32
is_usb_trans_done       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsUsbConnected
;
;           DESCRIPTION:    Check if connected
;
;           PARAMETERS:         BX          Pipe handle
;
;       RETURNS:    NC      Connected
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_connected_name  DB 'Is USB Connected',0

is_usb_connected       Proc far
    push ds
    push fs
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc iucdDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz iucdDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz iucdLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:is_connected_proc
    pop ds

iucdLeave:
    LeaveSection ds:usbu_section

iucdDone:
    pop ebx
    pop fs
    pop ds
    retf32
is_usb_connected       Endp


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
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc wutoDone
;
    mov ds,ds:[ebx].up_pipe_sel
    call CleanupPipe
;
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz wutoDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz wutoLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:was_transfer_ok_proc
    pop ds

wutoLeave:
    LeaveSection ds:usbu_section

wutoDone:
    pop ebx
    pop fs
    pop ds
    retf32
was_usb_trans_ok    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartOneUsbTransaction
;
;           DESCRIPTION:    Issue a single transfer
;
;           PARAMETERS:         BX          Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_one_usb_trans_name   DB 'Start One USB Transaction',0

start_one_usb_trans    Proc far
    push ds
    push fs
    push ebx
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc soutDone
;
    mov ds,ds:[ebx].up_pipe_sel
    mov al,ds:usbu_deleted
    or al,al
    stc
    jnz soutDone
;
    EnterSection ds:usbu_section
    mov ax,ds:usbu_pipe_sel
    or ax,ax
    stc
    jz soutLeave
;
    push ds
    mov fs,ax
    mov ds,ds:usbu_func_sel
    call fword ptr ds:issue_one_proc
    pop ds

soutLeave:
    LeaveSection ds:usbu_section

soutDone:
    pop ebx
    pop fs
    pop ds
    retf32
start_one_usb_trans    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsUsbPipeStalled
;
;           DESCRIPTION:    Check if pipe is stalled
;
;           PARAMETERS:         BX          Pipe handle
;
;       RETURNS:    CY          Stalled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_pipe_stalled_name   DB 'Is Usb Pipe Stalled',0

is_usb_pipe_stalled    Proc far
    push ds
    push fs
    push ebx
    push bp
;
    mov ax,USB_PIPE_HANDLE
    DerefHandle
    jc iupsDone
;
    mov al,ds:[ebx].up_deleted
    or al,al
    stc
    jnz iupsDone
;
    call LockAndGetPipe
    jc iupsLeave
;
    call fword ptr ds:is_stalled_proc

iupsLeave:
    mov ds,bp
    LeaveSection ds:usb_sync_section

iupsDone:
    pop bp
    pop ebx
    pop fs
    pop ds
    retf32
is_usb_pipe_stalled    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HookUsbAttach
;
;           description:    Hook USB attach event
;
;       parameters:     ES:EDI       Callback 
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
    shl bx,3
    add bx,OFFSET usb_attach_arr
    mov [bx],edi
    mov [bx+4],es
    inc ds:usb_attach_hooks
;
    pop bx
    pop ds
    retf32
hook_usb_attach   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HookUsbDetach
;
;           description:    Hook USB detach event
;
;       parameters:     ES:EDI       Callback
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
    shl bx,3
    add bx,OFFSET usb_detach_arr
    mov [bx],edi
    mov [bx+4],es
    inc ds:usb_detach_hooks
;
    pop bx
    pop ds
    retf32
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
    mov ax,SEG data
    mov ds,ax
    InitSection ds:usb_enum_section
    mov ds:usb_dev_count,0
    mov ds:usb_attach_hooks,0
    mov ds:usb_detach_hooks,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ax,USB_PIPE_HANDLE
    mov edi,OFFSET delete_handle
    RegisterHandle
;
    mov esi,OFFSET init_usb_device
    mov edi,OFFSET init_usb_device_name
    xor cl,cl
    mov ax,init_usb_device_nr
    RegisterOsGate
;
    mov esi,OFFSET lock_usb
    mov edi,OFFSET lock_usb_name
    xor cl,cl
    mov ax,lock_usb_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_usb
    mov edi,OFFSET unlock_usb_name
    xor cl,cl
    mov ax,unlock_usb_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_usb_attach
    mov edi,OFFSET notify_usb_attach_name
    xor cl,cl
    mov ax,notify_usb_attach_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_usb_detach
    mov edi,OFFSET notify_usb_detach_name
    xor cl,cl
    mov ax,notify_usb_detach_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_usb_attach
    mov edi,OFFSET hook_usb_attach_name
    xor cl,cl
    mov ax,hook_usb_attach_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_usb_detach
    mov edi,OFFSET hook_usb_detach_name
    xor cl,cl
    mov ax,hook_usb_detach_nr
    RegisterOsGate
;
    mov esi,OFFSET is_valid_usb_pipe_sel
    mov edi,OFFSET is_valid_usb_pipe_sel_name
    xor cl,cl
    mov ax,is_valid_usb_pipe_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET create_usb_req
    mov edi,OFFSET create_usb_req_name
    xor cl,cl
    mov ax,create_usb_req_nr
    RegisterOsGate
;
    mov esi,OFFSET add_write_usb_control_req
    mov edi,OFFSET add_write_usb_control_req_name
    xor cl,cl
    mov ax,add_write_usb_control_req_nr
    RegisterOsGate
;
    mov esi,OFFSET add_write_usb_data_req
    mov edi,OFFSET add_write_usb_data_req_name
    xor cl,cl
    mov ax,add_write_usb_data_req_nr
    RegisterOsGate
;
    mov esi,OFFSET add_read_usb_data_req
    mov edi,OFFSET add_read_usb_data_req_name
    xor cl,cl
    mov ax,add_read_usb_data_req_nr
    RegisterOsGate
;
    mov esi,OFFSET add_usb_status_in_req
    mov edi,OFFSET add_usb_status_in_req_name
    xor cl,cl
    mov ax,add_usb_status_in_req_nr
    RegisterOsGate
;
    mov esi,OFFSET add_usb_status_out_req
    mov edi,OFFSET add_usb_status_out_req_name
    xor cl,cl
    mov ax,add_usb_status_out_req_nr
    RegisterOsGate
;
    mov esi,OFFSET start_usb_req
    mov edi,OFFSET start_usb_req_name
    xor cl,cl
    mov ax,start_usb_req_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_usb_req
    mov edi,OFFSET stop_usb_req_name
    xor cl,cl
    mov ax,stop_usb_req_nr
    RegisterOsGate
;
    mov esi,OFFSET is_usb_req_started
    mov edi,OFFSET is_usb_req_started_name
    xor cl,cl
    mov ax,is_usb_req_started_nr
    RegisterOsGate
;
    mov esi,OFFSET is_usb_req_ready
    mov edi,OFFSET is_usb_req_ready_name
    xor cl,cl
    mov ax,is_usb_req_ready_nr
    RegisterOsGate
;
    mov esi,OFFSET get_usb_req_data
    mov edi,OFFSET get_usb_req_data_name
    xor cl,cl
    mov ax,get_usb_req_data_nr
    RegisterOsGate
;
    mov esi,OFFSET close_usb_req
    mov edi,OFFSET close_usb_req_name
    xor cl,cl
    mov ax,close_usb_req_nr
    RegisterOsGate
;
    mov esi,OFFSET req_usb_data_no_copy
    mov edi,OFFSET req_usb_data_no_copy_name
    xor cl,cl
    mov ax,req_usb_data_no_copy_nr
    RegisterOsGate
;
    mov esi,OFFSET write_usb_data_no_copy
    mov edi,OFFSET write_usb_data_no_copy_name
    xor cl,cl
    mov ax,write_usb_data_no_copy_nr
    RegisterOsGate
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
    mov esi,OFFSET get_usb_interface
    mov edi,OFFSET get_usb_interface_name
    xor dx,dx
    mov ax,get_usb_interface_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_usb_interface
    mov edi,OFFSET set_usb_interface_name
    xor dx,dx
    mov ax,set_usb_interface_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_usb_pipe
    mov edi,OFFSET open_usb_pipe_name
    xor dx,dx
    mov ax,open_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_usb_pipe
    mov edi,OFFSET reset_usb_pipe_name
    xor dx,dx
    mov ax,reset_usb_pipe_nr
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
    mov esi,OFFSET is_usb_connected
    mov edi,OFFSET is_usb_connected_name
    xor dx,dx
    mov ax,is_usb_connected_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET was_usb_trans_ok
    mov edi,OFFSET was_usb_trans_ok_name
    xor dx,dx
    mov ax,was_usb_trans_ok_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET start_one_usb_trans
    mov edi,OFFSET start_one_usb_trans_name
    xor dx,dx
    mov ax,start_one_usb_trans_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_usb_pipe_stalled
    mov edi,OFFSET is_usb_pipe_stalled_name
    xor dx,dx
    mov ax,is_usb_pipe_stalled_nr
    RegisterBimodalUserGate
    clc
    ret
init    Endp

code    ENDS

    END init
