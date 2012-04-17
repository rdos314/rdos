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
; USER.ASM
; USER (app level) gate handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\user.def
INCLUDE ..\os.inc
INCLUDE ..\user.inc
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

    extrn local_allocate_fixed_system_mem:near

    extrn translate_segment:near
    extrn translate_selector:near

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_USERGATE
;
;           DESCRIPTION:    Init module
;
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_usergate

init_usergate   PROC near
    push ds
    push es
    pusha
;    
    mov bx,usergate_sel
    mov eax,usergate_entries SHL 5
    call local_allocate_fixed_system_mem
    xor al,al
    xor di,di
    mov cx,usergate_entries SHL 5
    rep stosb
    xor di,di
    mov cx,usergate_entries
init_usergate_loop:
    mov es:[di].user_gate_name_offset,OFFSET illegal_gate_name
    mov es:[di].user_gate_name_sel,cs
    mov es:[di].user_gate_entry_offset16,OFFSET illegal_gate32
    mov es:[di].user_gate_entry_sel16,cs
    mov es:[di].user_gate_entry_offset32,OFFSET illegal_gate32
    mov es:[di].user_gate_entry_sel32,cs     
    mov es:[di].user_gate_syscall_offset,-1
    add di,32
    loop init_usergate_loop
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET register_bimodal_usergate
    mov edi,OFFSET register_bimodal_usergate_name
    xor cl,cl
    mov ax,register_bimodal_usergate_nr
    RegisterOsGate
;
    mov esi,OFFSET register_usergate
    mov edi,OFFSET register_usergate_name
    xor cl,cl
    mov ax,register_usergate_nr
    RegisterOsGate
;
    mov esi,OFFSET register_usergate16
    mov edi,OFFSET register_usergate16_name
    xor cl,cl
    mov ax,register_usergate16_nr
    RegisterOsGate
;
    mov esi,OFFSET register_usergate32
    mov edi,OFFSET register_usergate32_name
    xor cl,cl
    mov ax,register_usergate32_nr
    RegisterOsGate
;
    mov esi,OFFSET register_bimodal_syscall
    mov edi,OFFSET register_bimodal_syscall_name
    xor cl,cl
    mov ax,register_bimodal_syscall_nr
    RegisterOsGate
;
    mov esi,OFFSET register_syscall
    mov edi,OFFSET register_syscall_name
    xor cl,cl
    mov ax,register_syscall_nr
    RegisterOsGate
;
    mov esi,OFFSET is_valid_usergate
    mov edi,OFFSET is_valid_usergate_name
    xor dx,dx
    mov ax,is_valid_usergate_nr
    RegisterBimodalUserGate
;
    popa
    pop es
    pop ds
    ret
init_usergate   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ILLEGAL_GATE
;
;           DESCRIPTION:    Illegal gate
;
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

illegal_gate_name       DB 'Undefined Gate',0

illegal_gate16  Proc far
    stc
    ret
illegal_gate16  Endp

illegal_gate32: 
    stc
    retf32


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsValidUsergate
;
;           DESCRIPTION:    Check if a gate number is registered
;
;           PARAMETERS:         AX          GATE NUMBER
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_valid_usergate_name  DB 'Is Valid User Gate',0

is_valid_usergate       PROC far
    push ds
    push ax
    push bx
;
    mov bx,ax
    mov ax,usergate_sel
    mov ds,ax
    shl bx,5
    mov ax,[bx].user_gate_entry_sel32
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
is_valid_usergate       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_BIMODAL_USERGATE
;
;           DESCRIPTION:    Register bimodal 16- & 32-bit gate
;
;           PARAMETERS:     AX          GATE NUMBER
;                           DX          SEGMENT TRANSFER
;                           DS:ESI   16- AND 32-BIT GATE CALL ADDRESS
;                           ES:EDI   GATE NAME ADDRESS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_bimodal_usergate_name  DB 'Register Bimodal User Gate',0

register_bimodal_usergate       PROC far
    push fs
    push bx
    push dx
;
    mov bx,usergate_sel
    mov fs,bx
    mov bx,ax
    shl bx,5
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset16,esi
    mov fs:[bx].user_gate_entry_sel16,ds
    mov fs:[bx].user_gate_entry_offset32,esi
    mov fs:[bx].user_gate_entry_sel32,ds
    xchg dx,fs:[bx].user_gate_transfer
    or dx,dx
    jz register_bimodal_user_done
;
    xchg dx,fs:[bx].user_gate_transfer
    
register_bimodal_user_done:
    pop dx
    pop bx
    pop fs
    retf32
register_bimodal_usergate       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_USERGATE
;
;           DESCRIPTION:    Register 16- & 32-bit gate
;
;           PARAMETERS:     AX          GATE NUMBER
;                           DX          SEGMENT TRANSFER
;                           DS:EBX   16-BIT GATE CALL ADDRESS
;                           DS:ESI   32-BIT GATE CALL ADDRESS
;                           ES:EDI   GATE NAME ADDRESS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_usergate_name  DB 'Register User Gate',0

register_usergate       PROC far
    push fs
    push bx
    push ecx
    push dx
;
    mov ecx,ebx
    mov bx,usergate_sel
    mov fs,bx
    mov bx,ax
    shl bx,5
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset16,ecx
    mov fs:[bx].user_gate_entry_sel16,ds
    mov fs:[bx].user_gate_entry_offset32,esi
    mov fs:[bx].user_gate_entry_sel32,ds
    xchg dx,fs:[bx].user_gate_transfer
    or dx,dx
    jz register_user_done
;
    xchg dx,fs:[bx].user_gate_transfer
    
register_user_done:
    pop dx
    pop ecx
    pop bx
    pop fs
    retf32
register_usergate       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_BIMODAL_SYSCALL
;
;           DESCRIPTION:    Register bimodal 16- & 32-bit gate + syscall
;
;           PARAMETERS:     AX       Gate number
;                           DX       Segment transfer
;                           DS:ESI   16 and 32-bit far call address
;                           DS:EBP   32-bit near call address
;                           ES:EDI   GATE NAME ADDRESS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_bimodal_syscall_name  DB 'Register Bimodal Syscall',0

register_bimodal_syscall       PROC far
    push fs
    push bx
    push dx
;
    mov bx,usergate_sel
    mov fs,bx
    mov bx,ax
    shl bx,5
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset16,esi
    mov fs:[bx].user_gate_entry_sel16,ds
    mov fs:[bx].user_gate_entry_offset32,esi
    mov fs:[bx].user_gate_entry_sel32,ds
    mov fs:[bx].user_gate_syscall_offset,ebp
    xchg dx,fs:[bx].user_gate_transfer
    or dx,dx
    jz register_bimodal_syscall_done
;
    xchg dx,fs:[bx].user_gate_transfer
    
register_bimodal_syscall_done:
    pop dx
    pop bx
    pop fs
    retf32
register_bimodal_syscall       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_SYSCALL
;
;           DESCRIPTION:    Register 16- & 32-bit gate + syscall
;
;           PARAMETERS:     AX       Gate number
;                           DX       Segment transfer
;                           DS:EBX   16-bit far call address
;                           DS:ESI   32-bit far call address
;                           DS:EBP   32-bit near call address
;                           ES:EDI   Gate name address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_syscall_name  DB 'Register Syscall',0

register_syscall       PROC far
    push fs
    push bx
    push ecx
    push dx
;
    mov ecx,ebx
    mov bx,usergate_sel
    mov fs,bx
    mov bx,ax
    shl bx,5
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset16,ecx
    mov fs:[bx].user_gate_entry_sel16,ds
    mov fs:[bx].user_gate_entry_offset32,esi
    mov fs:[bx].user_gate_entry_sel32,ds
    mov fs:[bx].user_gate_syscall_offset,ebp
    xchg dx,fs:[bx].user_gate_transfer
    or dx,dx
    jz register_syscall_done
;
    xchg dx,fs:[bx].user_gate_transfer
    
register_syscall_done:
    pop dx
    pop ecx
    pop bx
    pop fs
    retf32
register_syscall       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_USERGATE16
;
;           DESCRIPTION:    Register 16-bit gate
;
;           PARAMETERS:     AX          GATE NUMBER
;                           DX          SEGMENT TRANSFER
;                           DS:ESI   16-BIT GATE CALL ADDRESS
;                           ES:EDI   GATE NAME ADDRESS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_usergate16_name    DB 'Register 16-bit User Gate',0

register_usergate16     PROC far
    push fs
    push bx
    push dx
;
    mov bx,usergate_sel
    mov fs,bx
    mov bx,ax
    shl bx,5
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset16,esi
    mov fs:[bx].user_gate_entry_sel16,ds
    xchg dx,fs:[bx].user_gate_transfer
    or dx,dx
    jz register_user16_done
;
    xchg dx,fs:[bx].user_gate_transfer
    
register_user16_done:
    pop dx
    pop bx
    pop fs
    retf32
register_usergate16     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_USERGATE32
;
;           DESCRIPTION:    Register 32-bit gate
;
;           PARAMETERS:     AX          GATE NUMBER
;                           DS:ESI   32-BIT GATE CALL ADDRESS
;                           ES:EDI   GATE NAME ADDRESS
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_usergate32_name    DB 'Register 32-bit User Gate',0

register_usergate32     PROC far
    push fs
    push bx
;
    mov bx,usergate_sel
    mov fs,bx
    mov bx,ax
    shl bx,5
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset32,esi
    mov fs:[bx].user_gate_entry_sel32,ds
;
    pop bx
    pop fs
    retf32
register_usergate32     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRANSLATE_SEGMENTS
;
;           DESCRIPTION:    AL          Segment transfer
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

translate_segments      PROC near
    test al,virt_es_in
    jz translate_not_es_in
    mov bx,[bp].vm_es
    call translate_segment
    mov es,bx
translate_not_es_in:
    test al,virt_fs_in
    jz translate_not_fs_in
    mov bx,[bp].vm_fs
    call translate_segment
    mov fs,bx
translate_not_fs_in:
    test al,virt_gs_in
    jz translate_not_gs_in
    mov bx,[bp].vm_gs
    call translate_segment
    mov gs,bx
translate_not_gs_in:
    test al,virt_ds_in
    jz translate_not_ds_in
    mov bx,[bp].vm_ds
    call translate_segment
    mov ds,bx
    jmp translate_seg_end
translate_not_ds_in:
    xor bx,bx
    mov ds,bx
translate_seg_end:
    ret
translate_segments      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TRANSLATE_SELECTORS
;
;           DESCRIPTION:    AL          Segment transfer
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

translate_selectors     PROC near
    mov bx,ds
    or bx,bx
    jz translate_out_ds_done
    xor ax,ax
    mov ds,ax
    call translate_selector
    jc translate_out_ds_done
    mov [bp].vm_ds,bx
translate_out_ds_done:
    mov bx,es
    or bx,bx
    jz translate_out_es_done
    xor ax,ax
    mov es,ax
    call translate_selector
    jc translate_out_es_done
    mov [bp].vm_es,bx
translate_out_es_done:
    mov bx,fs
    or bx,bx
    jz translate_out_fs_done
    xor ax,ax
    mov fs,ax
    call translate_selector
    jc translate_out_fs_done
    mov [bp].vm_fs,bx
translate_out_fs_done:
    mov bx,gs
    or bx,bx
    jz translate_out_gs_done
    xor ax,ax
    mov gs,ax
    call translate_selector
    jc translate_out_gs_done
    mov [bp].vm_gs,bx
translate_out_gs_done:
    ret
translate_selectors     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DO_USERGATE_VM
;
;           DESCRIPTION:    Translate a V86 mode usergate
;
;           PARAMETERS:         DS:EBX      Fault address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_usergate_vm

do_usergate_vm  PROC near
    mov bx,ds:[ebx+1]
    shl bx,5
    mov ax,usergate_sel
    mov ds,ax
;
    add word ptr [bp].vm_eip,8
    mov ax,[bp+2].vm_eflags
    and ax,NOT 1
    mov [bp+2].vm_eflags,ax
    mov ax,ds:[bx].user_gate_transfer
;
    push ax
    push bp
;
    push 0
    push cs
    push 0
    push OFFSET gate_return
    mov ax,[bp].vm_eflags
    and ax,03FFFh
    push ax
    push ds:[bx].user_gate_entry_sel16
    push ds:[bx].user_gate_entry_offset16

do_virtgate_translate:
    mov ax,ds:[bx].user_gate_transfer
    and al,virt_seg_in
    jz do_no_translate_seg
;
    call translate_segments
    jmp do_virt_func

do_no_translate_seg:
    xor ax,ax
    mov ds,ax

do_virt_func:
    mov eax,[bp].vm_eax
    mov ebx,[bp].vm_ebx
    mov bp,[bp].vm_bp
    iret

gate_return:
    pop bp
    mov [bp].vm_eax,eax
    mov [bp].vm_ebx,ebx
    pushf
    pop ax
    and ax,NOT 7000h
    mov [bp].vm_eflags,ax
    pop ax
    or al,al
    jz gate_exit
;
    call translate_selectors

gate_exit:
    ret
do_usergate_vm  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_usercall16
;
;           DESCRIPTION:    do usercall16
;
;           PARAMETERS:     DS:EBX      Instruction
;                           SS:BP       Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_usercall16

do_usercall16   Proc near
    push dword ptr [bp+20]
    mov [bp+20],ds    
    mov eax,ebx
    add eax,9
    mov [bp+16],eax
    pop dword ptr [bp+12]
;   
    mov edi,ds:[ebx+3]
    shl edi,5
    mov ax,usergate_sel
    mov es,ax
;
    mov eax,es:[edi].user_gate_entry_offset16
    mov [bp+4],eax
    movzx eax,es:[edi].user_gate_entry_sel16
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
    mov eax,es:[edi].user_gate_entry_offset16
    xchg eax,ds:[ebx+3]
;
    mov ax,es:[edi].user_gate_entry_sel16
    xchg ax,ds:[ebx+7]
;    
    mov al,90h
    xchg al,ds:[ebx]
    ret
do_usercall16   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_usercall32
;
;           DESCRIPTION:    do usercall32
;
;           PARAMETERS:     DS:EBX      Instruction
;                           SS:BP       Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_usercall32

do_usercall32   Proc near
    push dword ptr [bp+20]
    mov [bp+20],ds    
    mov eax,ebx
    add eax,9
    mov [bp+16],eax
    pop dword ptr [bp+12]
;   
    mov edi,ds:[ebx+3]
    shl edi,5
    mov ax,usergate_sel
    mov es,ax
;
    mov eax,es:[edi].user_gate_entry_offset32
    mov [bp+4],eax
    movzx eax,es:[edi].user_gate_entry_sel32
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
    mov eax,es:[edi].user_gate_entry_offset32
    xchg eax,ds:[ebx+3]
;
    mov ax,es:[edi].user_gate_entry_sel32
    xchg ax,ds:[ebx+7]
;    
    mov al,90h
    xchg al,ds:[ebx]
    ret
do_usercall32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_usergate32
;
;           DESCRIPTION:    do usergate32
;
;           PARAMETERS:     DS:EBX      Instruction
;                           SS:BP       Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_usergate32

do_usergate32   Proc near
    mov edi,ds:[ebx+2]
    shl edi,5
    mov ax,usergate_sel
    mov es,ax
;
    mov eax,es:[edi].user_gate_syscall_offset
    cmp eax,-1
    je do_usergate_not_syscall
;
    mov ax,ds
    cmp ax,flat_code_sel
    jne do_usergate_not_syscall    
;
    mov ax,syscall_patch_nr
    IsValidOsGate
    jz do_usergate_not_syscall
;
    SyscallPatch
    jnc do_usergate32_done

do_usergate_not_syscall:    
    push ebx
    mov bx,ds
    call local_get_selector_base_size
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax
;
    mov ax,es:[edi].user_gate_sel32
    or ax,ax
    jnz do_usergate32_defined
;
    push ds
    push bx
    push esi
    AllocateGdt
    or bx,3
    mov es:[edi].user_gate_sel32,bx
    mov esi,es:[edi].user_gate_entry_offset32
    mov ds,es:[edi].user_gate_entry_sel32
    xor cl,cl
    CreateCallGateSelector32
    mov ax,bx
    pop esi
    pop bx
    pop ds

do_usergate32_defined:
    xor eax,eax
    xchg eax,ds:[ebx+2]
;
    mov ax,es:[edi].user_gate_sel32
    xchg ax,ds:[ebx+6]
;    
    mov al,90h
    xchg al,ds:[ebx]

do_usergate32_done:    
    ret
do_usergate32  Endp

code    ENDS

    END

