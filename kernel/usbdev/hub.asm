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
; HUB.ASM
; Implements HUB class for USB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc

hub_struc   STRUC

hub_next            DW ?

hub_controller      DW ?
hub_device          DB ?
hub_intr            DB ?

hub_status_handle   DW ?

hub_status_size     DW ?
hub_status_sel      DW ?
hub_status_req      DW ?

hub_struc   ENDS

data    SEGMENT byte public 'DATA'

hub_thread      DW ?

hub_attach_list DW ?
hub_detach_list DW ?

hub_list        DW ?

hub_section     section_typ <>

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateHub
;
;   description:    Create hub
;
;   Parameters:     ES      Hub
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateHub  Proc near
    pushad
;    
    mov bx,es:hub_controller
    mov al,es:hub_device
    mov dl,es:hub_intr
    OpenUsbPipe
    mov es:hub_status_handle,bx
;
    CreateUsbReq
    mov es:hub_status_req,bx
;
    push es
    mov cx,es:hub_status_size
    movzx eax,cx
    AllocateSmallGlobalMem
    AddReadUsbDataReq
    mov bx,es
    pop es
;
    mov es:hub_status_sel,bx
;
    mov ax,ds:hub_thread
    mov bx,es:hub_status_req
    mov cx,es:hub_status_size
    StartUsbReq    
;
    IsUsbReqStarted
    jc chDone
;
    IsUsbReqReady
    jc chDone
;
    GetUsbReqData
    mov ax,es:hub_status_sel
;
    mov ax,ds:hub_list
    mov es:hub_next,ax
    mov ds:hub_list,es

chDone:
    popad
    ret
CreateHub   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           hub_thread
;
;           DESCRIPTION:    HUB thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hub_thread_name  DB 'USB Hub', 0

hub_thread_handler:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:hub_thread,ax
    int 3
    EnterSection ds:hub_section
    xor ax,ax
    xchg ax,ds:hub_attach_list
    LeaveSection ds:hub_section

hthAttachLoop:
    or ax,ax
    jz hthAttachOk
;
    mov es,ax
    mov ax,es:hub_next
    call CreateHub
    jmp hthAttachLoop

hthAttachOk:    
    WaitForSignal
    
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_attach
;
;   description:    USB attach callback
;
;   Parameters:     BX      Controller #
;                   AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_attach  Proc far
    push ds
    push es
    pushad
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
    jne uaDone
;
    mov cl,es:udd_class
    cmp cl,9
    jne uaDone
;
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
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaCheckLoop:
    mov cl,es:[di].ucd_type
    cmp cl,4
    jne uaCheckNext
;    
    mov cl,es:[di].uid_class
    cmp cl,9
    je uaConfig

uaCheckNext:
    movzx cx,es:[di].ucd_len
    or cx,cx
    jz uaDone
;    
    add di,cx
    cmp di,es:ucd_size
    jb uaCheckLoop
    jmp uaDone

uaConfig:
    ConfigUsbDevice
    jc uaDone
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne uaDescrNext
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,3
    jne uaDescrNext
;
    mov dl,es:[di].ued_address
    mov cx,es:[di].ued_maxsize
    jmp uaOk

uaDescrNext:
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    
    jmp uaDone

uaOk:
    push es 
    push ax
    mov eax,SIZE hub_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:hub_controller,bx
    mov es:hub_device,al
    mov es:hub_intr,dl
    mov es:hub_status_size,cx
;
    mov ax,SEG data
    mov ds,ax
    mov bx,es
;
    EnterSection ds:hub_section   
    mov ax,ds:hub_attach_list
    or ax,ax
    jz uaInsEmpty

uaInsLoop:
    mov es,ax
    mov ax,es:hub_next
    or ax,ax
    jnz uaInsLoop
;
    mov es:hub_next,bx
    jmp uaInsDone

uaInsEmpty:
    mov ds:hub_attach_list,bx

uaInsDone:    
    mov es,bx
    mov es:hub_next,0
    LeaveSection ds:hub_section
    pop es
;
    mov bx,ds:hub_thread
    or bx,bx
    jz uaCreate
;
    Signal
    jmp uaDone

uaCreate:    
    push es            
    mov dx,cs
    mov ds,dx
    mov es,dx
    mov di,OFFSET hub_thread_name
    mov si,OFFSET hub_thread_handler
    mov ax,3
    mov cx,stack0_size
    CreateThread
    pop es

uaDone:    
    FreeMem
;
    popad
    pop es
    pop ds
    retf32
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_detach
;
;   description:    USB detach callback
;
;   Parameters:     BX      Controller #
;                   AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    mov dx,SEG data
    mov ds,dx
;        
    popad
    pop es
    pop ds
    retf32
usb_detach  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov bx,SEG data
    mov ds,bx
    mov ds:hub_thread,0
    mov ds:hub_attach_list,0
    mov ds:hub_detach_list,0
    mov ds:hub_list,0
    InitSection ds:hub_section
;       
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
init    Endp

code    ENDS

    END init
