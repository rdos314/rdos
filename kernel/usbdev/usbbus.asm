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
; USBBUS.ASM
; Implements USB bus class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include usb.inc
INCLUDE ..\os\protseg.def
include ..\os\com.inc

    .386p

FLAG_UDS_DISCONNECT = 2
FLAG_UDS_REINIT = 4

usbcom_port_struc       STRUC

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
ups_control         DB ?

usbcom_port_struc       ENDS

usbcom_device_struc   STRUC

uds_base_struc      com_device_struc <>

uds_section         section_typ <>
uds_port_sel        DW ?
uds_device_type     DW ?
uds_in_size         DW ?
uds_out_size        DW ?
uds_interface       DB ?
uds_bulk_in         DB ?
uds_bulk_out        DB ?
uds_in_handle       DW ?
uds_out_handle      DW ?
uds_in_buffer       DW ?
uds_out_buffer      DW ?
uds_in_req          DW ?
uds_out_req         DW ?
uds_link            DW ?
uds_port_offset     DW ?
uds_flag            DB ?
uds_port_nr         DW ?

usbcom_device_struc   ENDS

data    SEGMENT byte public 'DATA'

sd_thread       DW ?
sd_dead         DW ?
sd_spinlock     spinlock_typ <>
sd_port         DW ?

data	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UsbComThread
;
;           DESCRIPTION:    Com-port handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usbcom_thread_name  DB 'USB Bus Com', 0

usbcom_thread:
    mov ax,SEG data
    mov fs,ax
    GetThread
    mov fs:sd_thread,ax

utLoop:
    WaitForSignal
;
    mov ax,fs:sd_port
    or ax,ax
    jz utLoop
;
    mov ds,ax
    push cx
    push si
;
;    EnterSection ds:uds_section
;    call HandleDevice
;    LeaveSection ds:uds_section
;
    pop si
    pop cx
    jmp utLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       OpenPort
;
;           description:    Open port selector
;
;           RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPort Proc far
    int 3
    ret
OpenPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateDevice
;
;   DESCRIPTION:    Handle device attach
;
;   PARAMETERS:     AL      Device address
;                   BX      Controller id
;                   ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDevice Proc near
    push ds
    push es
    pushad
;    
    push dx
    push di
    mov dx,SEG data
    mov ds,dx
    mov dx,ds:sd_thread
    or dx,dx
    jnz cdThreadStarted
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
    mov cx,stack0_size
    CreateThread
;
    pop di
    pop si
    pop ax
    pop es
    pop ds
        
cdThreadStarted:
    push bx
    xor bx,bx
    xor bp,bp
    xor dx,dx
    xor si,si
    movzx cx,es:[di].uid_len
    add di,cx

cdDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne cdDescrDone
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,2
    jne cdDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz cdBulkIn

cdBulkOut:
    cmp si,2
    jae cdDescrNext
;
    inc si
    and cl,0Fh
    mov dl,cl
    mov bx,es:[di].ued_maxsize
    jmp cdDescrNext

cdBulkIn:
    cmp si,2
    jae cdDescrNext
;
    inc si
    and cl,8Fh
    mov dh,cl
    mov bp,es:[di].ued_maxsize
    
cdDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb cdDescrLoop    
    
cdDescrDone:
    shl ebp,16
    mov bp,bx    
    pop bx
;    
    mov cx,dx
    pop di
    pop dx
;    
    or cl,cl
    jz cdDone
;
    or ch,ch
    jz cdDone
;    
    mov dx,ds:sd_dead
    or dx,dx
    jz cdNoRecover
;
    mov ds:sd_dead,0
    mov ds,dx
    EnterSection ds:uds_section
    mov al,ds:uds_flag
    or al,FLAG_UDS_REINIT
    and al,NOT FLAG_UDS_DISCONNECT
    mov ds:uds_flag,al
;    
    mov ax,SEG data
    mov ds,ax
    mov ds:sd_port,dx
;
    mov ds,dx    
    LeaveSection ds:uds_section
;    
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_thread
    Signal    
    jmp cdDone
    
cdNoRecover:
    push cx
    mov cl,es:[di].uid_id
    push ax
    mov eax,SIZE usbcom_device_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:uds_interface,cl
    pop dx
    mov es:uds_port_sel,0
    mov es:uds_bulk_in,dh
    mov es:uds_bulk_out,dl
;       
    mov es:uds_out_size,bp
    shr ebp,16
    mov es:uds_in_size,bp
    mov es:uds_in_handle,0
    mov es:uds_in_req,0
    mov es:uds_in_buffer,0
    mov es:uds_out_handle,0
    mov es:uds_out_req,0
    mov es:uds_out_buffer,0
    mov es:uds_flag,0
;
    push ds
    mov si,es
    mov ds,si
    InitSection ds:uds_section
    pop ds
;
    mov ds:sd_port,es
    mov es:uds_port_offset,si
;
    mov dx,es
    mov ds,dx
    mov dword ptr ds:cd_create_proc,OFFSET OpenPort
    mov dword ptr ds:cd_create_proc+4,cs
;    
    movzx dx,al
    mov ax,bx
    AddComPort
    mov ds:uds_port_nr,ax

cdDone:
    popad
    pop es
    pop ds      
    ret
CreateDevice Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseDevice
;
;           DESCRIPTION:    Close device
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseDevice    Proc near
    mov ax,50
    WaitMilliSec
;    
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
    mov ds:uds_in_buffer,0
    mov ds:uds_out_buffer,0
    ret
CloseDevice   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_attach
;
;           description:    USB attach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

devTab:
dt00    DW 054Dh,       1001h

usb_attach  Proc far
    push ds
    push es
    pushad
;    
    int 3
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
    jne uaDone
;
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,1
    mov bp,OFFSET devTab

uaLoop:
    cmp si,cs:[bp]
    jne uaNext
;
    cmp di,cs:[bp+2]
    je uaFound

uaNext:
    add bp,4
    loop uaLoop    
;
    jmp uaDone    

uaFound:
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz uaDone
;
    mov dl,es:ucd_config_id
    ConfigUsbDevice
    jc uaDone
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne uaDescrNext
; 
    mov dx,si
    call CreateDevice
    jmp uaDone

uaDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    

uaDone:
    FreeMem
;
    popad
    pop es
    pop ds
    ret
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_detach
;
;           description:    USB detach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    int 3
    movzx ax,al
    mov dx,SEG data
    mov ds,dx
    mov dx,ds:sd_port
    or dx,dx
    jz udDone
;
    mov es,dx
    cmp bx,es:cd_controller
    jne udDone
;
    cmp ax,es:cd_device
    jne udDone
;
    mov ds,dx
    EnterSection ds:uds_section
    or ds:uds_flag,FLAG_UDS_DISCONNECT
;    
    mov dx,SEG data
    mov ds,dx
    mov ds:sd_port,0
    mov ds:sd_dead,es
;
    mov ax,es
    mov ds,ax
    call CloseDevice
;
    mov ax,ds:uds_port_sel
    or ax,ax
    jz udPortHandleOk
;
    push es
    mov es,ax
    mov bx,es:ups_control_wait
    CloseWait
    mov es:ups_control_wait,0
;    
    mov bx,es:ups_control_pipe
    CloseUsbPipe    
    mov es:ups_control_pipe,0
;
    mov es:send_count,0
    mov bx,es:send_wait
    or bx,bx
    jz udPortSendOk
;
    Signal    

udPortSendOk:
    pop es

udPortHandleOk:    
    LeaveSection ds:uds_section    

udDone:
    popad
    pop es
    pop ds
    ret
usb_detach  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           test_thread
;
;           DESCRIPTION:    test thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_thread:
    int 3
    mov bx,ds:cd_controller
    mov ax,ds:cd_device
    mov dl,ds:uds_bulk_in
    OpenUsbPipe
    mov ds:uds_in_handle,bx
;
    CreateUsbReq
    mov ds:uds_in_req,bx    
;    
    mov cx,ds:uds_in_size
    xor ax,ax
    AddReadUsbDataReq
    mov ds:uds_in_buffer,es
;
    mov bx,ds:cd_controller
    mov ax,ds:cd_device
    mov dl,ds:uds_bulk_out
    OpenUsbPipe    
    mov ds:uds_out_handle,bx
;
    CreateUsbReq
    mov ds:uds_out_req,bx
;    
    mov cx,ds:uds_out_size
    mov ax,1
    AddWriteUsbDataReq
    mov ds:uds_out_buffer,es
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov ax,SEG data
    mov ds,eax
    mov ds:sd_thread,0
    mov ds:sd_port,0
    mov es:sd_dead,0
    InitSpinlock es:sd_spinlock
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
Init    Endp
        
code    ENDS

    END Init
