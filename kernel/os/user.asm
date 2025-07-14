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
    extrn local_create_data_sel16:near

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
    mov edx,usergate_linear
    mov ecx,usergate_entries SHL USER_GATE_SHIFT
    call local_create_data_sel16
    mov es,bx
;
    xor al,al
    xor di,di
    mov cx,usergate_entries SHL USER_GATE_SHIFT
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
    mov es:[di].user_gate_syscall_flags,0
    mov es:[di].user_gate_syscall_par,0
    mov es:[di].user_gate_syscall_par+1,0
    mov es:[di].user_gate_syscall_par+2,0
    add di,1 SHL USER_GATE_SHIFT
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
    mov esi,OFFSET link_usergate
    mov edi,OFFSET link_usergate_name
    xor cl,cl
    mov ax,link_usergate_nr
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
    push eax
    push bx
;
    mov bx,ax
    mov ax,usergate_sel
    mov ds,ax
    cmp bx,usergate_entries
    jae is_valid_gate_fail
;    
    shl bx,USER_GATE_SHIFT
;
    mov ax,cs
    cmp ax,[bx].user_gate_entry_sel32
    jne is_valid_gate_ok
;
    mov eax,OFFSET illegal_gate32
    cmp eax,[bx].user_gate_entry_offset32
    jne is_valid_gate_ok

is_valid_gate_fail:
    stc
    jmp is_valid_gate_done
    
is_valid_gate_ok:   
    clc

is_valid_gate_done:
    pop bx
    pop eax
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
    shl bx,USER_GATE_SHIFT
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
    shl bx,USER_GATE_SHIFT
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
;           NAME:           Link_USERGATE
;
;           DESCRIPTION:    Link 16- & 32-bit gate
;
;           PARAMETERS:     AX       GATE NUMBER
;                           DX       SEGMENT TRANSFER
;                           DS:EBX   16-BIT GATE CALL ADDRESS
;                           DS:ESI   32-BIT GATE CALL ADDRESS
;                           ES:EDI   GATE NAME ADDRESS
;
;           RETURNS:        DX:EAX   Previous 32-bit gate call address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

link_usergate_name  DB 'Link User Gate',0

link_usergate       PROC far
    push fs
    push bx
    push ecx
;
    mov ecx,ebx
    mov bx,usergate_sel
    mov fs,bx
    mov bx,ax
    shl bx,USER_GATE_SHIFT
    mov eax,fs:[bx].user_gate_entry_offset32
    push fs:[bx].user_gate_entry_sel32
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset16,ecx
    mov fs:[bx].user_gate_entry_sel16,ds
    mov fs:[bx].user_gate_entry_offset32,esi
    mov fs:[bx].user_gate_entry_sel32,ds
    xchg dx,fs:[bx].user_gate_transfer
    or dx,dx
    jz link_user_done
;
    xchg dx,fs:[bx].user_gate_transfer
    
link_user_done:
    pop dx
;
    pop ecx
    pop bx
    pop fs
    retf32
link_usergate       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           REGISTER_BIMODAL_SYSCALL
;
;           DESCRIPTION:    Register bimodal 16- & 32-bit gate + syscall
;
;           PARAMETERS:     AX       Gate number
;                           ECX      Syscall flags + par
;                           DX       Segment transfer
;                           DS:ESI   16 and 32-bit far call address
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
    shl bx,USER_GATE_SHIFT
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset16,esi
    mov fs:[bx].user_gate_entry_sel16,ds
    mov fs:[bx].user_gate_entry_offset32,esi
    mov fs:[bx].user_gate_entry_sel32,ds
    mov dword ptr fs:[bx].user_gate_syscall_flags,ecx
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
;                           ECX      Syscall flags + par
;                           DX       Segment transfer
;                           DS:EBX   16-bit far call address
;                           DS:ESI   32-bit far call address
;                           ES:EDI   Gate name address
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_syscall_name  DB 'Register Syscall',0

register_syscall       PROC far
    push fs
    push bx
    push dx
    push ebp
;
    mov ebp,ebx
    mov bx,usergate_sel
    mov fs,bx
    mov bx,ax
    shl bx,USER_GATE_SHIFT
    mov fs:[bx].user_gate_name_offset,edi
    mov fs:[bx].user_gate_name_sel,es
    mov fs:[bx].user_gate_entry_offset16,ebp
    mov fs:[bx].user_gate_entry_sel16,ds
    mov fs:[bx].user_gate_entry_offset32,esi
    mov fs:[bx].user_gate_entry_sel32,ds
    mov dword ptr fs:[bx].user_gate_syscall_flags,ecx
    xchg dx,fs:[bx].user_gate_transfer
    or dx,dx
    jz register_syscall_done
;
    xchg dx,fs:[bx].user_gate_transfer
    
register_syscall_done:
    pop ebp
    pop dx
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
    shl bx,USER_GATE_SHIFT
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
    shl bx,USER_GATE_SHIFT
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
    mov bx,[ebp].trap_es
    call translate_segment
    mov es,bx
translate_not_es_in:
    test al,virt_fs_in
    jz translate_not_fs_in
    mov bx,[ebp].trap_fs
    call translate_segment
    mov fs,bx
translate_not_fs_in:
    test al,virt_gs_in
    jz translate_not_gs_in
    mov bx,[ebp].trap_gs
    call translate_segment
    mov gs,bx
translate_not_gs_in:
    test al,virt_ds_in
    jz translate_not_ds_in
    mov bx,[ebp].trap_ds
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
    mov [ebp].trap_ds,bx
translate_out_ds_done:
    mov bx,es
    or bx,bx
    jz translate_out_es_done
    xor ax,ax
    mov es,ax
    call translate_selector
    jc translate_out_es_done
    mov [ebp].trap_es,bx
translate_out_es_done:
    mov bx,fs
    or bx,bx
    jz translate_out_fs_done
    xor ax,ax
    mov fs,ax
    call translate_selector
    jc translate_out_fs_done
    mov [ebp].trap_fs,bx
translate_out_fs_done:
    mov bx,gs
    or bx,bx
    jz translate_out_gs_done
    xor ax,ax
    mov gs,ax
    call translate_selector
    jc translate_out_gs_done
    mov [ebp].trap_gs,bx
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
    shl bx,USER_GATE_SHIFT
    mov ax,usergate_sel
    mov ds,ax
;
    add word ptr [ebp].trap_eip,8
    mov ax,[ebp+2].trap_eflags
    and ax,NOT 1
    mov [ebp+2].trap_eflags,ax
    mov ax,ds:[bx].user_gate_transfer
;
    push ax
    push bp
;
    push 0
    push cs
    push 0
    push OFFSET gate_return
    mov ax,[ebp].trap_eflags
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
    mov eax,[ebp].trap_eax
    mov ebx,[ebp].trap_ebx
    mov bp,[ebp].trap_ebp
    iret

gate_return:
    pop bp
    mov [ebp].trap_eax,eax
    mov [ebp].trap_ebx,ebx
    pushf
    pop ax
    and ax,NOT 7000h
    mov [ebp].trap_eflags,ax
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
;                           SS:EBP      Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_usercall16

do_usercall16   Proc near
    push dword ptr [ebp+20]
    mov [ebp+20],ds    
    mov eax,ebx
    add eax,9
    mov [ebp+16],eax
    pop dword ptr [ebp+12]
;   
    mov edi,ds:[ebx+3]
    cmp edi,usergate_entries    
    jb do_user_in_range16
;
    mov edi,invalid_user_nr

do_user_in_range16:    
    shl edi,USER_GATE_SHIFT
    mov ax,usergate_sel
    mov es,ax
;
    mov eax,es:[edi].user_gate_entry_offset16
    mov [ebp+4],eax
    movzx eax,es:[edi].user_gate_entry_sel16
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
    mov eax,es:[edi].user_gate_entry_offset16
    xchg eax,ds:[ebx+3]
;
    mov ax,es:[edi].user_gate_entry_sel16
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
do_usercall16   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_usercall32
;
;           DESCRIPTION:    do usercall32
;
;           PARAMETERS:     DS:EBX      Instruction
;                           SS:EBP      Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_usercall32

do_usercall32   Proc near
    push dword ptr [ebp+20]
    mov [ebp+20],ds    
    mov eax,ebx
    add eax,9
    mov [ebp+16],eax
    pop dword ptr [ebp+12]
;   
    mov edi,ds:[ebx+3]
    cmp edi,usergate_entries    
    jb do_user_in_range32
;
    mov edi,invalid_user_nr

do_user_in_range32:    
    shl edi,USER_GATE_SHIFT
    mov ax,usergate_sel
    mov es,ax
;
    mov eax,es:[edi].user_gate_entry_offset32
    mov [ebp+4],eax
    movzx eax,es:[edi].user_gate_entry_sel32
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
    mov eax,es:[edi].user_gate_entry_offset32
    xchg eax,ds:[ebx+3]
;
    mov ax,es:[edi].user_gate_entry_sel32
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
do_usercall32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           do_usergate32
;
;           DESCRIPTION:    do usergate32
;
;           PARAMETERS:     DS:EBX      Instruction
;                           SS:EBP      Stack frame
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public do_usergate32

do_usergate32   Proc near
    AppPatch
    jnc do_usergate32_done

do_usergate32_norm:    
    mov edi,ds:[ebx+2]
    cmp edi,usergate_entries    
    jb do_usergate_in_range32
;
    mov edi,invalid_user_nr

do_usergate_in_range32:    
    shl edi,USER_GATE_SHIFT
    mov ax,usergate_sel
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
    push edx
    mov edx,cr0
    pushf
    push edx
    and edx,NOT 10000h
    cli
    mov cr0,edx
;
    xor eax,eax
    xchg eax,ds:[ebx+2]
;
    mov ax,es:[edi].user_gate_sel32
    xchg ax,ds:[ebx+6]
;    
    mov al,90h
    xchg al,ds:[ebx]
;
    pop edx
    mov cr0,edx
    popf
    pop edx

do_usergate32_done:    
    ret
do_usergate32  Endp

code    ENDS

    END

