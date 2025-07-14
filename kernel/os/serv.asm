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
; Serv.ASM
; Server gate handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\serv.def
INCLUDE ..\serv.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE gate.def
INCLUDE servdev.def

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
;           NAME:           INIT_SERVER
;
;           DESCRIPTION:    Init module
;
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_serv_gate

init_serv_gate     PROC near
    push ds
    push es
    pusha
;    
    mov ax,cs
    mov ds,ax
;
    mov bx,serv_gate_sel
    mov edx,serv_gate_linear
    mov ecx,serv_gate_entries SHL 4
    call local_create_data_sel16
    mov es,bx
;    
    xor di,di
    mov cx,serv_gate_entries

init_serv_gate_loop:
    mov es:[di].serv_gate_proc_offset,OFFSET illegal_gate
    mov es:[di].serv_gate_proc_sel,cs
    mov es:[di].serv_gate_name_offset,OFFSET illegal_gate_name
    mov es:[di].serv_gate_name_sel,cs
    add di,16
    loop init_serv_gate_loop
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET register_serv_gate
    mov edi,OFFSET register_serv_gate_name
    mov ax,register_serv_gate_nr
    xor cl,cl
    RegisterOsGate
;
    mov esi,OFFSET register_priv_serv_gate
    mov edi,OFFSET register_priv_serv_gate_name
    mov ax,register_priv_serv_gate_nr
    xor cl,cl
    RegisterOsGate
;
    popa
    pop es
    pop ds
    ret
init_serv_gate     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_GATE
;
;           DESCRIPTION:    Register a server gate
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

register_serv_gate_name      DB 'Register Server Gate',0

register_serv_gate   PROC far
    push ds
    push fs
    push gs
    push bx
;
    push ds
    mov bx,ax
    mov ax,serv_gate_sel
    mov ds,ax
    pop ax
    shl bx,4
    mov [bx].serv_gate_proc_sel,ax
    mov [bx].serv_gate_proc_offset,esi
    mov [bx].serv_gate_name_sel,es
    mov [bx].serv_gate_name_offset,edi
;
    pop bx
    pop gs
    pop fs
    pop ds
    retf32
register_serv_gate   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_PRIVATE_GATE
;
;           DESCRIPTION:    Register a private server gate
;
;           PARAMETERS:     AX          Gate number
;                           DS:ESI      Gate call address
;                           ES:EDI      Gate name address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_priv_serv_gate_name      DB 'Register Private Server Gate',0

register_priv_serv_gate   PROC far
    push ds
    push fs
    push gs
    push bx
;
    push ds
    mov bx,ax
;
    GetThread
    mov ds,ax
    mov ax,ds:p_serv_sel
    or ax,ax
    jnz reg_priv_do
;
    stc
    pop ax
    jmp reg_priv_done

reg_priv_do:
    mov ds,ax
    mov ax,ds:serv_gate_sel
    or ax,ax
    jnz reg_priv_has_sel
;
    push es
    push cx
    push di
;
    mov eax,serv_gate_entries SHL 4
    AllocateSmallGlobalMem
;    
    xor di,di
    mov cx,serv_gate_entries

reg_priv_loop:
    mov es:[di].serv_gate_proc_offset,OFFSET illegal_gate
    mov es:[di].serv_gate_proc_sel,cs
    mov es:[di].serv_gate_name_offset,OFFSET illegal_gate_name
    mov es:[di].serv_gate_name_sel,cs
    add di,16
    loop reg_priv_loop
;
    mov ds:serv_gate_sel,es
    mov ax,es
;
    pop di
    pop cx
    pop es

reg_priv_has_sel:
    mov ds,ax
    pop ax
;
    shl bx,4
    mov [bx].serv_gate_proc_sel,ax
    mov [bx].serv_gate_proc_offset,esi
    mov [bx].serv_gate_name_sel,es
    mov [bx].serv_gate_name_offset,edi
    clc

reg_priv_done:
    pop bx
    pop gs
    pop fs
    pop ds
    retf32
register_priv_serv_gate   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_user_serv
;
;           DESCRIPTION:    do user mode serv
;
;           PARAMETERS:     DS:EBX      Instruction
;                           SS:EBP      Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_user_serv

do_user_serv   Proc near
    push fs
;
    GetThread
    mov fs,ax
    mov ax,fs:p_serv_sel
    or ax,ax
    jz do_user_serv_done
;
    mov fs,ax
;
    mov edi,ds:[ebx+2]
    cmp edi,serv_gate_entries    
    jb do_user_serv_in_range
;
    mov edi,invalid_serv_nr

do_user_serv_in_range:    
    mov ax,fs:serv_gate_sel
    or ax,ax
    jnz do_user_serv_priv
;
    mov ax,serv_gate_sel

do_user_serv_priv:
    mov es,ax
;    
    push ebx
    mov bx,ds
    call local_get_selector_base_size
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov ax,fs:[2*edi].serv_gate_arr
    or ax,ax
    jnz do_user_serv_defined
;
    push ds
    push bx
    push esi
;
    AllocateLdt
    or bx,7
    mov fs:[2*edi].serv_gate_arr,bx
;
    shl edi,SERV_GATE_SHIFT
    mov esi,es:[edi].serv_gate_proc_offset
    mov ds,es:[edi].serv_gate_proc_sel
    xor cl,cl
    CreateCallGateSelector32
    mov ax,bx
;
    pop esi
    pop bx
    pop ds

do_user_serv_defined:
    push edx
    mov edx,cr0
    pushf
    push edx
    and edx,NOT 10000h
    cli
    mov cr0,edx
;
    xchg ax,ds:[ebx+6]
;
    xor eax,eax
    xchg eax,ds:[ebx+2]
;    
    mov al,90h
    xchg al,ds:[ebx]
;
    pop edx
    mov cr0,edx
    popf
    pop edx

do_user_serv_done:
    pop fs
    ret
do_user_serv   Endp

code    ENDS

    END

