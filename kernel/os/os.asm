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
; OS.ASM
; OS (kernel level) gate handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
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
    mov edx,osgate_linear
    mov ecx,osgate_entries SHL 4
    call local_create_data_sel16
    mov es,bx
;    
    xor al,al
    xor di,di
    rep stosb
    xor di,di
    mov es:[di].os_gate_offset,OFFSET register_gate
    mov es:[di].os_gate_sel,cs
    mov es:[di].os_gate_name_offset,OFFSET register_gate_name
    mov es:[di].os_gate_name_sel,cs
    mov cx,osgate_entries-1
    mov di,16
init_osgate_loop:
    mov es:[di].os_gate_offset,OFFSET illegal_gate
    mov es:[di].os_gate_sel,cs
    mov es:[di].os_gate_name_offset,OFFSET illegal_gate_name
    mov es:[di].os_gate_name_sel,cs
    mov es:[di].os_gate_flags,0
    add di,16
    loop init_osgate_loop
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
    mov esi,OFFSET register_long_gate
    mov edi,OFFSET register_long_gate_name
    mov ax,register_long_osgate_nr
    xor cl,cl
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
    stc
    retf32
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
    mov [bx].os_gate_sel,ax
    mov [bx].os_gate_offset,esi
    mov [bx].os_gate_name_sel,es
    mov [bx].os_gate_name_offset,edi
;
    pop bx
    pop gs
    pop fs
    pop ds
    retf32
register_gate   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RegisterLongOsGate
;
;           DESCRIPTION:    Register an OS gate to long mode code segment
;
;           PARAMETERS:     AX          GATE NUMBER
;                           CL          NUMBER OF 16-BIT PARAMETERS
;                           ESI         GATE CALL ADDRESS
;                           EDI         GATE NAME ADDRESS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_long_gate_name      DB 'Register Long Kernel Gate',0

register_long_gate   PROC far
    push ds
    push bx
;
    mov bx,ax
    mov ax,osgate_sel
    mov ds,ax
    shl bx,4
    mov [bx].os_gate_sel,long_kernel_code_sel
    mov [bx].os_gate_offset,esi
    mov [bx].os_gate_name_sel,long_kernel_code_sel
    mov [bx].os_gate_name_offset,edi
;
    pop bx
    pop ds
    retf32
register_long_gate   ENDP

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
    cmp bx,osgate_entries
    jae is_valid_fail
;    
    shl bx,4
    mov ax,cs
    cmp ax,[bx].os_gate_sel
    jne is_valid_ok
;
    mov eax,OFFSET illegal_gate
    cmp eax,[bx].os_gate_offset
    jne is_valid_ok

is_valid_fail:
    stc
    jmp is_valid_gate_done
    
is_valid_ok:   
    clc

is_valid_gate_done:
    pop bx
    pop ax
    pop ds
    retf32
is_valid_osgate ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_oscall
;
;           DESCRIPTION:    do oscall
;
;           PARAMETERS:     DS:EBX      Instruction
;                           SS:EBP       Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_oscall

do_oscall   Proc near
    push dword ptr [ebp+20]
    mov [ebp+20],ds    
    mov eax,ebx
    add eax,9
    mov [ebp+16],eax
    pop dword ptr [ebp+12]
;   
    mov edi,ds:[ebx+3]
    cmp edi,osgate_entries
    jb do_oscall_in_range
;
    mov edi,invalid_os_nr    

do_oscall_in_range:    
    shl edi,4
    mov ax,osgate_sel
    mov es,ax
;
    mov eax,es:[edi].os_gate_offset
    mov [ebp+4],eax
    movzx eax,es:[edi].os_gate_sel
    mov [ebp+8],eax
;
    push ebx
    mov bx,ds
    call local_get_selector_base_size
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    push edx
    mov edx,cr0
    pushf
    push edx
    and edx,NOT 10000h
    cli
    mov cr0,edx
;
    mov eax,es:[edi].os_gate_offset
    xchg eax,ds:[ebx+3]
;
    mov ax,es:[edi].os_gate_sel
    xchg ax,ds:[ebx+7]
;    
    mov al,90h
    xchg al,ds:[ebx]
;
    pop edx
    mov cr0,edx
    popf
    pop edx
    ret
do_oscall   Endp

code    ENDS

    END

