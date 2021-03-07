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
; Shared.ASM
; Shared gate handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\shared.def
INCLUDE ..\shared.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE gate.def

code    SEGMENT byte public 'CODE'

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

    extrn local_get_selector_base_size:near
    extrn local_create_trap_gate_sel:near
    extrn local_create_data_sel16:near

    extrn local_allocate_fixed_system_mem:near

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_SHARED
;
;           DESCRIPTION:    Init module
;
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_shared_gate

init_shared_gate     PROC near
    push ds
    push es
    pusha
;    
    mov ax,cs
    mov ds,ax
;
    mov bx,shared_gate_sel
    mov edx,shared_gate_linear
    mov ecx,shared_gate_entries SHL 4
    call local_create_data_sel16
    mov es,bx
;    
    xor di,di
    mov cx,shared_gate_entries

init_shared_gate_loop:
    mov es:[di].shared_gate_proc_offset,OFFSET illegal_gate
    mov es:[di].shared_gate_proc_sel,cs
    mov es:[di].shared_gate_name_offset,OFFSET illegal_gate_name
    mov es:[di].shared_gate_name_sel,cs
    add di,16
    loop init_shared_gate_loop
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET register_shared_gate
    mov edi,OFFSET register_shared_gate_name
    mov ax,register_shared_gate_nr
    xor cl,cl
    RegisterOsGate
;
    popa
    pop es
    pop ds
    ret
init_shared_gate     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_GATE
;
;           DESCRIPTION:    Register a shared gate
;
;           PARAMETERS:     AX          Gate number
;                           DS:ESI      Gate call address
;                           ES:EDI      Gate name address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

illegal_gate_name       DB 'Undefined Gate',0

illegal_gate    PROC far
    stc
    retf32
illegal_gate    ENDP

register_shared_gate_name      DB 'Register Shared Gate',0

register_shared_gate   PROC far
    push ds
    push fs
    push gs
    push bx
;
    push ds
    mov bx,ax
    mov ax,shared_gate_sel
    mov ds,ax
    pop ax
    shl bx,4
    mov [bx].shared_gate_proc_sel,ax
    mov [bx].shared_gate_proc_offset,esi
    mov [bx].shared_gate_name_sel,es
    mov [bx].shared_gate_name_offset,edi
;
    pop bx
    pop gs
    pop fs
    pop ds
    retf32
register_shared_gate   ENDP

code    ENDS

    END

