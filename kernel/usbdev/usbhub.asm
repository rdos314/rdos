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

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc
include ..\usbdev\usbhub.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

GET_STATUS = 0
CLEAR_FEATURE = 1
SET_FEATURE = 3
GET_DESCR = 6
SET_DESCR = 7
CLEAR_TT = 8
RESET_TT = 9
GET_TT_STATE = 10
STOP_TT = 11

PORT_CONNECTION     = 0
PORT_ENABLE         = 1
PORT_SUSPEND        = 2
PORT_OVER_CURRENT   = 3
PORT_RESET          = 4
PORT_POWER          = 8
PORT_LOW_SPEED      = 9
C_PORT_CONNECTION   = 16
C_PORT_ENABLE       = 17
C_PORT_SUSPEND      = 18
C_PORT_OVER_CURRENT = 19
C_PORT_RESET        = 20
PORT_TEST           = 21
PORT_INDICATOR      = 22

data    SEGMENT byte public 'DATA'

hub_list        DW ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_attach
;
;   description:    USB attach callback
;
;   Parameters:     BX      Controller #
;                   AL      Device address
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hub_name    DB 'Usb Hub ', 0

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
    int 3
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
    push es 
    push ax
    push ax
    mov eax,SIZE usb_hub_dev_struc
    AllocateSmallGlobalMem
    pop ax
;    mov es:hub_controller,bx
;    mov es:hub_device,al
;    mov es:hub_dev_sel,ds
    mov ax,es
    mov gs,ax
    pop ax
    pop es
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne uaDescrNext

uaDescrDo:
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,3
    jne uaDescrNext
;
    mov cl,es:[di].ued_address
    mov gs:hub_intr,cl
;
    mov cx,es:[di].ued_maxsize
    mov gs:hub_status_size,cx

uaDescrNext:
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    

uaOk:
    mov al,gs:hub_intr
    or al,al
    jnz uaValid
;
    push es
    mov ax,gs
    mov es,ax
    xor ax,ax
    mov gs,ax
    FreeMem
    pop es
    jmp uaDone

uaValid:
;
    FreeMem
    pop es

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
;   NAME:           usb_detach
;
;   description:    USB detach callback
;
;   Parameters:     BX      Controller #
;                   AL      Device address
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    ret
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
