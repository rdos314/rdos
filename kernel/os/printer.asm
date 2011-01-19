;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; PRINTER.ASM
; Printer base class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include printer.inc

MAX_PORTS = 32

printer_handle_seg  STRUC

printer_handle_base  handle_header <>

printer_handle_seg  ENDS

data    SEGMENT byte public 'DATA'

p_port_count    DW ?
p_port_arr      DW MAX_PORTS DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Delete_handle
;
;       DESCRIPTION:    Delete handle (called from handle module)
;
;       PARAMETERS:     BX              PRINTER HANDLE
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,PRINTER_HANDLE
    DerefHandle
    jc delete_handle_done
;
    FreeHandle

delete_handle_done:
    pop dx
    pop ax
    pop es
    pop ds
    ret
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init
;
;       description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov di,OFFSET delete_handle
    mov ax,PRINTER_HANDLE
    RegisterHandle
;
    mov bx,SEG data
    mov es,bx
    mov cx,2 + 2 * MAX_PORTS
    xor di,di
    xor al,al
    rep stosb
    clc
    ret
init    Endp


code    ENDS

    END init
