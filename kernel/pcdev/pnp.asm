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
; PNP.ASM
; Plug-and-play support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

    .386p

data    SEGMENT byte public 'DATA'

PnpSection      section_typ <>

data    ENDS

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPnpByte
;
;           DESCRIPTION:    Read a 8-bit PNP register
;
;           PARAMETERS:     CH          Device
;                           CL          Register
;
;           RETURNS:        AL         Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_pnp_byte_name     DB 'Read Pnp Byte',0

read_pnp_byte  Proc far
    push ds
    push dx
;
    mov dx,SEG data
    mov ds,dx
    EnterNewSection ds:PnpSection
;
    mov dx,2Eh
    mov al,87h
    out dx,al
    out dx,al
;
    mov al,7
    out dx,al
    inc dx
    mov al,ch
    out dx,al
    dec dx
;
    mov al,cl
    out dx,al
    inc dx
    in al,dx
    dec dx
;
    push ax
    mov al,0AAh
    out dx,al
    pop ax
    LeaveNewSection ds:PnpSection    
;
    pop dx
    pop ds
    retf32
read_pnp_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePnpByte
;
;           DESCRIPTION:    Write a 8-bit PnP register
;
;           PARAMETERS:     CH          Device
;                           CL          Register
;                           AL          Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_pnp_byte_name     DB 'Write Pnp Byte',0

write_pnp_byte  Proc far
    push ds
    push dx
    push ax
;
    mov dx,SEG data
    mov ds,dx
    EnterNewSection ds:PnpSection
;
    push ax
    mov dx,2Eh
    mov al,87h
    out dx,al
    out dx,al
;
    mov al,7
    out dx,al
    inc dx
    mov al,ch
    out dx,al
    dec dx
;
    mov al,cl
    out dx,al
    inc dx
    pop ax
    out dx,al
    dec dx
;
    mov al,0AAh
    out dx,al
    LeaveNewSection ds:PnpSection
;
    pop ax
    pop dx
    pop ds
    retf32
write_pnp_byte  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    INIT PnP DEVICE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,SEG data
    mov ds,ax
    InitSection ds:PnpSection
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET read_pnp_byte
    mov edi,OFFSET read_pnp_byte_name
    xor cl,cl
    mov ax,read_pnp_byte_nr
    RegisterOsGate
;
    mov esi,OFFSET write_pnp_byte
    mov edi,OFFSET write_pnp_byte_name
    xor cl,cl
    mov ax,write_pnp_byte_nr
    RegisterOsGate
    clc
    ret
init    Endp

code    ENDS

    END init
