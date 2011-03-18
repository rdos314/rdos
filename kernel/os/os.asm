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
; OS.ASM
; OS (kernel level) gate handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def

gate_entry      STRUC
gate_offset         DD ?
gate_sel            DW ?
gate_name_offset    DD ?
gate_name_sel       DW ?
gate_flags          DW ?
gate_entry      ENDS

code    SEGMENT byte public 'CODE'

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

    extrn local_get_selector_base_size:near
    extrn local_create_trap_gate_sel:near

    extrn local_allocate_fixed_system_mem:near

    extrn enter_code_patch:near
    extrn leave_code_patch:near

    assume cs:code


test_gate_name  DB 'Test', 0

test_gate   Proc far
    mov ax,3456h
    retf32
test_gate   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_OSGATE
;
;           DESCRIPTION:    Init module
;
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_osgate

init_osgate     PROC near
    push ds
    push es
    pusha
;    
    mov ax,cs
    mov ds,ax
;
    mov bx,osgate_sel
    mov eax,osgate_entries SHL 4
    call local_allocate_fixed_system_mem
    mov cx,osgate_entries SHL 4
    xor al,al
    xor di,di
    rep stosb
    xor di,di
    mov es:[di].gate_offset,OFFSET register_gate
    mov es:[di].gate_sel,cs
    mov es:[di].gate_name_offset,OFFSET register_gate_name
    mov es:[di].gate_name_sel,cs
    mov cx,osgate_entries-1
    mov di,16
init_osgate_loop:
    mov es:[di].gate_sel,0
    mov es:[di].gate_offset,0
    mov es:[di].gate_name_offset,OFFSET illegal_gate_name
    mov es:[di].gate_name_sel,cs
    mov es:[di].gate_flags,0
    add di,16
    loop init_osgate_loop
;
    mov di,register_old_osgate_nr SHL 4
    mov es:[di].gate_offset,OFFSET register_old_gate
    mov es:[di].gate_sel,cs
    mov es:[di].gate_name_offset,OFFSET register_old_gate_name
    mov es:[di].gate_name_sel,cs
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET is_valid_osgate
    mov edi,OFFSET is_valid_osgate_name
    mov ax,is_valid_osgate_nr
    xor cl,cl
    RegisterOsGate
;
    mov esi,OFFSET test_gate
    mov edi,OFFSET test_gate_name
    xor cl,cl
    mov ax,test_gate_nr
    RegisterOsGate
;
    popa
    pop es
    pop ds
    ret
init_osgate     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_GATE
;
;           DESCRIPTION:    Register an OS gate
;
;           PARAMETERS:         AX          GATE NUMBER
;                           CL          NUMBER OF 16-BIT PARAMETERS
;                           DS:ESI  GATE CALL ADDRESS
;                           ES:EDI  GATE NAME ADDRESS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

illegal_gate_name       DB 'Undefined Gate',0

illegal_gate    PROC far
    mov ax,1231h
    mov es,ax
    int 3
    ret
illegal_gate    ENDP

register_gate_name      DB 'Register Kernel Gate',0

register_gate   PROC far
    push ds
    push fs
    push gs
    push bx
;
    push ds
    mov bx,ax
    mov ax,osgate_sel
    mov ds,ax
    pop ax
    shl bx,4
    mov [bx].gate_sel,ax
    mov [bx].gate_offset,esi
    mov [bx].gate_name_sel,es
    mov [bx].gate_name_offset,edi
;
    pop bx
    pop gs
    pop fs
    pop ds
    retf32
register_gate   ENDP

register_old_gate_name      DB 'Register Old Kernel Gate',0

register_old_gate   PROC far
    push ds
    push fs
    push gs
    push bx
;
    push ds
    mov bx,ax
    mov ax,osgate_sel
    mov ds,ax
    pop ax
    shl bx,4
    mov [bx].gate_sel,ax
    mov [bx].gate_offset,esi
    mov [bx].gate_name_sel,es
    mov [bx].gate_name_offset,edi
;
    pop bx
    pop gs
    pop fs
    pop ds
    retf32
register_old_gate   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IS_VALID_OSGATE
;
;           DESCRIPTION:    Check if a gate number is registered
;
;           PARAMETERS:         AX          GATE NUMBER
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_valid_osgate_name    DB 'Is Valid Kernel Gate',0

is_valid_osgate PROC far
    push ds
    push ax
    push bx
;
    mov bx,ax
    mov ax,osgate_sel
    mov ds,ax
    shl bx,4
    mov ax,[bx].gate_sel
    or ax,ax
    clc
    jnz is_valid_gate_done
;
    stc

is_valid_gate_done:
    pop bx
    pop ax
    pop ds
    retf32
is_valid_osgate ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DO_OLD_OSCALL16
;
;           DESCRIPTION:    Translate old 16-bit gate
;
;           PARAMETERS:         DS:EBX      Fault address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_old_oscall16

do_old_oscall16     PROC near
    push es
    push ecx
    push edx
    push di
;
    mov ax,system_data_sel
    mov es,ax
    pushf
    cli

odo16_lock_loop:
    mov ax,1
    xchg ax,es:osgate_spinlock
    or ax,ax
    jz odo16_locked
;
    pause
    jmp odo16_lock_loop

odo16_locked: 
    mov al,ds:[ebx]
    cmp al,90h
    je odo16_patched
;    
    cmp al,66h
    je odo16_has_ov
;    
    mov di,ds:[ebx+1]
    jmp odo16_ov_done

odo16_has_ov:
    mov di,ds:[ebx+2]

odo16_ov_done:    
    shl di,4
    mov ax,osgate_sel
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
    mov ax,[bp].vm_eflags
    mov [bp+12],ax
    mov ax,[bp].vm_cs
    mov [bp+16],ax
    mov ax,[bp].vm_eip
    add ax,8
    mov [bp+14],ax  
;
    mov ax,es:[di].gate_sel
    cmp ax,[bp+16]
    je odo16_direct
;
    mov [bp+10],ax
    mov eax,es:[di].gate_offset
    mov [bp+8],ax

    call enter_code_patch
    mov ax,0F5F5h
    shl eax,16
    mov ax,es:[di].gate_sel
    xchg eax,ds:[ebx+4]
;    
    mov eax,es:[di].gate_offset
    shl eax,16
    mov ax,9A90h
    xchg eax,ds:[ebx]
;
    mov ax,9090h
    xchg ax,ds:[ebx+6]
    call leave_code_patch
    jmp odo16_retry

odo16_direct:
    mov [bp+10],ax
    mov eax,es:[di].gate_offset
    mov [bp+8],ax
    sub ax,[bp+14]
    add ax,2
    call enter_code_patch
    movzx eax,ax
    or eax,0F5F50000h
    xchg eax,ds:[ebx+4]
;
    mov eax,0E80E9090h
    xchg eax,ds:[ebx]
;
    mov ax,9090h
    xchg ax,ds:[ebx+6]
    call leave_code_patch
    jmp odo16_retry

odo16_patched:
    mov ax,[bp].vm_eflags
    mov [bp+12],ax
    mov ax,[bp].vm_cs
    mov [bp+16],ax
    mov ax,[bp].vm_eip
    add ax,8
    mov [bp+14],ax  
;
    mov ax,ds:[ebx]
    cmp ax,9A90h
    je odo16_patch_far

odo16_patch_near:
    mov ax,[bp].vm_cs
    mov [bp+10],ax
    mov ax,ds:[ebx+4]
    add ax,[bp+14]
    sub ax,2
    mov [bp+8],ax
    jmp odo16_retry

odo16_patch_far:
    mov ax,ds:[ebx+4]
    mov [bp+10],ax
    mov ax,ds:[ebx+2]
    mov [bp+8],ax
    
odo16_retry:
    mov ax,system_data_sel
    mov es,ax
    mov es:osgate_spinlock,0
    popf
;
    pop di
    pop edx
    pop ecx
    pop es
;
    mov ds,[bp].pm_ds
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov sp,bp
    pop bp
    add sp,6
    iret
do_old_oscall16     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_oscall
;
;           DESCRIPTION:    do oscall
;
;           PARAMETERS:     DS:EBX      Instruction
;                           SS:BP       Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_oscall

do_oscall   Proc near
    push dword ptr [bp+20]
    mov [bp+20],ds    
    mov eax,ebx
    add eax,9
    mov [bp+16],eax
    pop dword ptr [bp+12]
;   
    mov edi,ds:[ebx+3]
    shl edi,4
    mov ax,osgate_sel
    mov es,ax
;
    mov eax,es:[edi].gate_offset
    mov [bp+4],eax
    movzx eax,es:[edi].gate_sel
    mov [bp+8],eax
;
    push ebx
    mov bx,ds
    call local_get_selector_base_size
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov eax,es:[edi].gate_offset
    xchg eax,ds:[ebx+3]
;
    mov ax,es:[edi].gate_sel
    xchg ax,ds:[ebx+7]
;    
    mov al,90h
    xchg al,ds:[ebx]
    ret
do_oscall   Endp

code    ENDS

    END

