;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; PNP.ASM
; Plug-and-play support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

data    SEGMENT byte public 'DATA'

PnpSection      section_typ <>

data    ENDS

    .386p

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
    EnterSection ds:PnpSection
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
    LeaveSection ds:PnpSection    
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
    EnterSection ds:PnpSection
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
    LeaveSection ds:PnpSection
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
