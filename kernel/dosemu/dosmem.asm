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
; DOSMEM.ASM
; DOS memory allocation.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE dos.inc

DOS_HANDLER_START = 100h
DOS_MEM_START = 102h

dos_mem_struc   STRUC
dos_mem_id          DB ?
dos_mem_psp         DW ?
dos_mem_size    DW ?
dos_mem_pad         DB ?
dos_mem_sel         DW ?
dos_mem_struc   ENDS

    .386p

    extrn get_prot_psp:near
    extrn get_virt_psp:near
    extrn set_virt_psp:near

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_DOS_LINEAR
;
;           DESCRIPTION:    Allocate DOS linear
;
;           PARAMETERS:         EAX         Bytes
;
;           RETURNS:        EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dos_linear_name    DB 'Allocate Dos Linear',0

allocate_dos_linear     PROC far
    push ds
    push es
    push eax
    push ebx
    push cx
    mov bx,dos_process_sel
    mov ds,bx
    EnterSection ds:dos_mem_section
    dec eax
    shr eax,4
    add ax,2
    mov dl,8
    jc dos_alloc_error
;
    mov bx,DOS_MEM_START
    movzx edx,bx
    shl edx,4
;
    mov bx,flat_sel
    mov ds,bx
dos_alloc_loop:
    mov cl,[edx].dos_mem_id
    cmp cl,4Dh
    je dos_alloc_mem_ok
    cmp cl,5Ah
    je dos_alloc_mem_ok
    mov dl,7
    jmp dos_alloc_error
dos_alloc_mem_ok:
    mov bx,[edx].dos_mem_psp
    or bx,bx
    jnz dos_try_next
    cmp ax,[edx].dos_mem_size
    jc dos_alloc_do
    je dos_alloc_do
dos_try_next:
    xor ebx,ebx
    mov bx,[edx].dos_mem_size
    shl ebx,4
    add edx,ebx
    add edx,10h         
    cmp cl,4Dh
    je dos_alloc_loop
    mov dl,8
    jmp dos_alloc_error
dos_alloc_do:
    GetPsp
    mov [edx].dos_mem_psp,bx
    mov cx,[edx].dos_mem_size
    sub cx,ax
    jz dos_alloc_done
    cmp cx,1
    je dos_alloc_done
    dec ax
    mov [edx].dos_mem_size,ax
    xor ebx,ebx
    mov bx,ax
    inc bx
    shl ebx,4
    add ebx,edx
    mov [ebx].dos_mem_psp,0
    mov [ebx].dos_mem_size,cx
    mov cl,4Dh
    xchg cl,[edx].dos_mem_id
    mov [ebx].dos_mem_id,cl
dos_alloc_done:
    mov bx,dos_process_sel
    mov ds,bx
    LeaveSection ds:dos_mem_section
    add edx,10h
    clc
    pop cx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
dos_alloc_error:
    mov bx,dos_process_sel
    mov ds,bx
    LeaveSection ds:dos_mem_section
    stc
    pop cx
    pop ebx
    pop eax
    movzx ax,dl
    mov edx,0F0000h
    pop es
    pop ds
    retf32
allocate_dos_linear     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResizeDosLinear
;
;           DESCRIPTION:    Resize dos memory block
;
;           PARAMETERS:         EAX         Wanted size
;                           EDX         Linear base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

resize_dos_linear_name  DB 'Resize Dos Linear',0

resize_dos_linear       PROC far
    push ds
    push ebx
    push ecx
    push edx
;
    push eax
    push ebx
    mov ecx,eax
    mov ax,dos_process_sel
    mov ds,ax
    EnterSection ds:dos_mem_section
    mov ax,flat_sel
    mov ds,ax
    xor ebx,ebx
    GetPsp
    dec bx
    shl ebx,4
    sub edx,10h
resize_dos_find_loop:
    mov al,[ebx].dos_mem_id
    cmp al,4Dh
    je resize_dos_id_ok
    cmp al,5Ah
    je resize_dos_id_ok
    mov ax,dos_process_sel
    mov ds,ax
    LeaveSection ds:dos_mem_section
    pop ebx
    pop eax
    xor ebx,ebx
    mov ax,7
    stc
    jmp resize_dos_done

resize_dos_id_ok:
    cmp ebx,edx
    je resize_dos_found
    cmp al,5Ah
    je resize_dos_mem_inv
    xor eax,eax
    mov ax,[ebx].dos_mem_size
    shl eax,4
    add ebx,eax
    add ebx,10h         
    jmp resize_dos_find_loop

resize_dos_mem_inv:
    mov ax,dos_process_sel
    mov ds,ax
    LeaveSection ds:dos_mem_section
    pop ebx
    pop eax
    xor ebx,ebx
    mov ax,9
    stc
    jmp resize_dos_done

resize_dos_found:
    xor ebx,ebx
    mov bx,[edx].dos_mem_size
    shl ebx,4
    mov eax,ebx
    sub eax,ecx
    jc resize_dos_grow
    je resize_dos_leave
    cmp eax,10h
    je resize_dos_leave
resize_dos_shrink:
    mov al,4Dh
    xchg al,[edx].dos_mem_id
    cmp al,5Ah
    je resize_dos_split
    add ebx,edx
    add ebx,10h
    mov ax,[ebx].dos_mem_psp
    or ax,ax
    mov al,[ebx].dos_mem_id
    jnz resize_dos_join
    push ax
    mov ax,[edx].dos_mem_size
    add ax,[ebx].dos_mem_size
    inc ax
    movzx ebx,ax
    shl ebx,4
    pop ax
    jmp resize_dos_split

resize_dos_join:
    sub ebx,10h
    sub ebx,edx

resize_dos_split:
    shr ebx,4
    push bx
    mov ebx,edx
    add ebx,ecx
    add ebx,10h
    mov [ebx].dos_mem_id,al
    mov [ebx].dos_mem_psp,0
    pop ax
    shr ecx,4
    mov [edx].dos_mem_size,cx
    sub ax,cx
    dec ax
    mov [ebx].dos_mem_size,ax
    jmp resize_dos_leave

resize_dos_grow:
    add ebx,edx
    add ebx,10h
    mov ax,[ebx].dos_mem_psp
    or ax,ax
    jz resize_dos_grow_free
resize_dos_grow_insuff:
    mov ax,[ebx].dos_mem_psp
    or ax,ax
    mov ax,[ebx].dos_mem_size
    jnz resize_dos_grow_insuff_occupied
    sub ebx,edx
    shr ebx,4
    add ax,bx
resize_dos_grow_insuff_occupied:
    mov bx,ax
    mov ax,dos_process_sel
    mov ds,ax
    LeaveSection ds:dos_mem_section
    pop eax
    pop eax
    mov ax,8
    stc
    jmp resize_dos_done

resize_dos_grow_free:
    movzx eax,[ebx].dos_mem_size
    shl eax,4
    add eax,ebx
    sub eax,edx
    sub eax,ecx
    jc resize_dos_grow_insuff
    jz resize_dos_grow_nosplit
    add ecx,10h
    jc resize_dos_grow_nosplit
    jz resize_dos_grow_nosplit
    shr ecx,4
    dec cx
    mov [edx].dos_mem_size,cx
    shl ecx,4
    add edx,ecx
    add edx,10h
    shr eax,4
    dec ax
    mov [edx].dos_mem_size,ax
    mov al,[ebx].dos_mem_id
    mov [edx].dos_mem_id,al
    mov [edx].dos_mem_psp,0     
    jmp resize_dos_leave
resize_dos_grow_nosplit:    
    shr ecx,4
    mov al,[ebx].dos_mem_id
    mov [edx].dos_mem_id,al
    mov [edx].dos_mem_size,cx
resize_dos_leave:
    mov ax,dos_process_sel
    mov ds,ax
    LeaveSection ds:dos_mem_section
    pop ebx
    pop eax
    clc

resize_dos_done:
    pop edx
    pop ecx
    pop ebx
    pop ds
    retf32
resize_dos_linear       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_DOS_LINEAR
;
;           DESCRIPTION:    Free DOS memory
;
;           PARAMETERS:         EDX         Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dos_linear_name    DB 'Free Dos Linear',0

free_dos_linear PROC far
    push ds
    push ebx
    push ecx
    push edx
;
    mov ax,dos_process_sel
    mov ds,ax
    EnterSection ds:dos_mem_section
    xor ebx,ebx
    mov ebx,DOS_MEM_START SHL 4
    mov ax,flat_sel
    mov ds,ax
    mov ecx,ebx
    sub edx,10h
free_dos_loop:
    mov al,[ebx].dos_mem_id
    cmp al,4Dh
    je free_dos_mem_ok
    cmp al,5Ah
    je free_dos_mem_ok
    mov ax,dos_process_sel
    mov ds,ax
    LeaveSection ds:dos_mem_section
    mov ax,7
    stc
    jmp free_dos_done

free_dos_mem_ok:
    cmp ebx,edx
    je free_dos_found
    cmp al,5Ah
    je free_dos_mem_inv
    mov ecx,ebx
    xor eax,eax
    mov ax,[ebx].dos_mem_size
    shl eax,4
    add ebx,eax
    add ebx,10h         
    jmp free_dos_loop
free_dos_mem_inv:
    mov ax,dos_process_sel
    mov ds,ax
    LeaveSection ds:dos_mem_section
    mov ax,9
    stc
    jmp free_dos_done

free_dos_found:
    mov ax,[ecx].dos_mem_psp
    or ax,ax
    jnz free_dos_no_merge_down
    mov bl,[edx].dos_mem_id
    mov ax,[ecx].dos_mem_size
    add ax,[edx].dos_mem_size
    inc ax
    mov edx,ecx
    mov [edx].dos_mem_size,ax
    mov [edx].dos_mem_id,bl
free_dos_no_merge_down:
    mov al,[edx].dos_mem_id
    cmp al,5Ah
    je free_dos_no_merge_up
    xor ecx,ecx
    mov cx,[edx].dos_mem_size
    shl ecx,4
    add ecx,edx
    add ecx,10h
    mov ax,[ecx].dos_mem_psp
    or ax,ax
    jnz free_dos_no_merge_up
    mov bl,[ecx].dos_mem_id
    mov ax,[edx].dos_mem_size
    add ax,[ecx].dos_mem_size
    inc ax
    mov [edx].dos_mem_size,ax
    mov [edx].dos_mem_id,bl
free_dos_no_merge_up:
    mov [edx].dos_mem_psp,0
    xor eax,eax
    mov ax,[edx].dos_mem_size
    shl eax,4       
    add edx,10h
    add eax,edx
    mov ax,dos_process_sel
    mov ds,ax

free_dos_leave:
    LeaveSection ds:dos_mem_section
    clc

free_dos_done:
    pop edx
    pop ecx
    pop ebx
    pop ds
    retf32
free_dos_linear ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FREE_APP_MEM
;
;           DESCRIPTION:    Free app memory
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public free_app_mem

free_app_mem    PROC near
    push ds
    push es
    push eax
    push ebx
    push cx
;
    call get_prot_psp
    or bx,bx
    jz free_app_mem_done

free_dos_prog_mem_start:
    mov bx,dos_process_sel
    mov ds,bx
    EnterSection ds:dos_mem_section
    mov edx,DOS_MEM_START SHL 4
    mov bx,flat_sel
    mov ds,bx
free_dos_prog_mem_loop:
    mov cl,[edx].dos_mem_id
    cmp cl,4Dh
    je free_dos_prog_mem_ok
    cmp cl,5Ah
    je free_dos_prog_mem_ok
    jmp free_dos_prog_mem_done
free_dos_prog_mem_ok:
    call get_virt_psp
    cmp bx,[edx].dos_mem_psp
    jne free_dos_prog_mem_next
    mov bx,dos_process_sel
    mov ds,bx
    LeaveSection ds:dos_mem_section
    add edx,10h
    FreeLinear
    jmp free_dos_prog_mem_start
free_dos_prog_mem_next:
    xor ebx,ebx
    mov bx,[edx].dos_mem_size
    shl ebx,4
    add edx,ebx
    add edx,10h         
    cmp cl,4Dh
    je free_dos_prog_mem_loop
free_dos_prog_mem_done:
    mov bx,dos_process_sel
    mov ds,bx
    LeaveSection ds:dos_mem_section

free_app_mem_done:
    pop cx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
free_app_mem    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AVAILABLE_DOS_LINEAR
;
;           DESCRIPTION:    Available DOS memory
;
;           RETURNS:        EAX         Free bytes
;                           EDX         Largest block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

available_dos_linear_name       DB 'Available Dos Linear',0

available_dos_linear    PROC far
    push ds
    push ebx
    push ecx
    mov bx,dos_process_sel
    mov ds,bx
    EnterSection ds:dos_mem_section
    mov ebx,DOS_MEM_START SHL 4
    mov ax,flat_sel
    mov ds,ax
    xor eax,eax
    xor edx,edx
dos_avail_loop:
    mov cl,[ebx].dos_mem_id
    cmp cl,4Dh
    je dos_avail_mem_ok
    cmp cl,5Ah
    je dos_avail_mem_ok
    jmp dos_avail_done
dos_avail_mem_ok:
    mov cx,[ebx].dos_mem_psp
    or cx,cx
    jnz dos_avail_try_next
    movzx ecx,[ebx].dos_mem_size
    shl ecx,4
    add eax,ecx
    cmp edx,ecx
    jnc dos_avail_try_next
    mov edx,ecx
dos_avail_try_next:
    mov cl,[ebx].dos_mem_id
    cmp cl,4Dh
    jne dos_avail_done
    xor ecx,ecx
    mov cx,[ebx].dos_mem_size
    shl ecx,4
    add ebx,ecx
    add ebx,10h         
    jmp dos_avail_loop
dos_avail_done:
    or eax,eax
    jz dos_avail_nothing1
    sub eax,10h
dos_avail_nothing1:
    or edx,edx
    jz dos_avail_nothing2
    sub edx,10h
dos_avail_nothing2:
    mov bx,dos_process_sel
    mov ds,bx
    LeaveSection ds:dos_mem_section
    pop ecx
    pop ebx
    pop ds
    retf32
available_dos_linear    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ALLOCATE_DOS_MEM16
;
;           DESCRIPTION:    Allocate DOS memory
;
;           PARAMETERS:         EAX         Bytes
;
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dos_mem_name   DB 'Allocate Dos Memory',0

allocate_dos_mem16      PROC far
    push ds
    push bx
    push ecx
    push edx
    push eax
    AllocateDosLinear
    jc allocate_dos_mem_fail16
    cmp eax,10000h
    jc allocate_dos_mem_single
allocate_dos_mem_multiple:
    mov ecx,eax
    shr ecx,16
    inc cx
    AllocateMultipleLdt
    jmp allocate_dos_mem_setup_ldt
allocate_dos_mem_single:
    mov cx,1
    AllocateLdt
allocate_dos_mem_setup_ldt:
    push ax
    mov ax,flat_sel
    mov ds,ax
    mov [edx].dos_mem_sel,bx
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_sel
    pop ax
;       
    push bx
allocate_dos_mem_ldt_loop:
    cmp cx,1
    je allocate_dos_mem_final_ldt
    mov word ptr [bx],0FFFFh
    mov [bx+2],edx
    mov byte ptr [bx+5],0F2h
    mov word ptr [bx+6],0
    add edx,10000h
    jmp allocate_dos_mem_next_ldt
allocate_dos_mem_final_ldt:
    dec ax
    mov [bx],ax
    mov [bx+2],edx
    mov byte ptr [bx+5],0F2h
    mov word ptr [bx+6],0
allocate_dos_mem_next_ldt:
    add bx,8
    loop allocate_dos_mem_ldt_loop
    pop bx
    or bx,7
    mov es,bx
    pop eax
    pop edx
    pop ecx
    pop bx
    pop ds
    clc
    retf32
allocate_dos_mem_fail16:
    mov dx,ax
    pop eax
    mov ax,dx
    xor dx,dx
    mov es,dx
    pop edx
    pop ecx
    pop bx
    pop ds
    stc
    retf32
allocate_dos_mem16      ENDP

allocate_dos_mem32      PROC far
    push ds
    push eax
    push bx
    push cx
    push edx
    AllocateDosLinear
    jc allocate_dos_mem_end32
    AllocateLdt
    dec eax
    mov [bx],ax
    mov [bx+2],edx
    mov dl,0F2h
    xchg dl,[bx+5]
    shr eax,16
    and ax,0Fh
    or ax,40h
    or ah,dl
    mov [bx+6],ax
    or bx,7
    mov es,bx
allocate_dos_mem_end32:
    pop edx
    pop cx
    pop bx
    pop eax
    pop ds
    retf32
allocate_dos_mem32      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_DOS_MEM
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_dos_mem

init_dos_mem    PROC near
    pusha
    push ds
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET allocate_dos_linear
    mov edi,OFFSET allocate_dos_linear_name
    xor cl,cl
    mov ax,allocate_dos_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET resize_dos_linear
    mov edi,OFFSET resize_dos_linear_name
    xor cl,cl
    mov ax,resize_dos_linear_nr
    RegisterOsGate
;
    mov esi,OFFSET free_dos_linear
    mov edi,OFFSET free_dos_linear_name
    xor cl,cl
    mov ax,free_dos_linear_nr
    RegisterOsGate
;
    mov ebx,OFFSET allocate_dos_mem16
    mov esi,OFFSET allocate_dos_mem32
    mov edi,OFFSET allocate_dos_mem_name
    mov dx,virt_es_out
    mov ax,allocate_dos_mem_nr
    RegisterUserGate
;
    mov esi,OFFSET available_dos_linear
    mov edi,OFFSET available_dos_linear_name
    xor cl,cl
    mov ax,available_dos_linear_nr
    RegisterOsGate
;
    pop ds
    popa
    ret
init_dos_mem    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_DOS_PROCESS_MEM
;
;           DESCRIPTION:    Init per-process data
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_process_mem


dos_int_vect:
    ReflectVMToPM 20h
    ReflectVMToPM 21h
    ReflectVMToPm 22h
    ReflectVMToPm 23h
    ReflectVMToPm 24h

init_process_mem    PROC near
    push ds
    push es
    push eax
    push edx
    push di
;
    mov ax,dos_process_sel
    mov ds,ax
    InitSection ds:dos_mem_section
;
    LockSysEnv
    mov ds,bx
    mov ax,flat_sel
    mov es,ax
    movzx eax,bx
    xor esi,esi
    mov edi,DOS_MEM_START SHL 4 + 10h
    lsl ecx,eax
    rep movs byte ptr es:[edi],ds:[esi]
    xor ax,ax
    stos word ptr es:[edi]
    mov edx,edi
    dec edx
    and dl,0F0h
    add edx,10h
    mov ebx,edx
    shr ebx,4
    UnlockSysEnv
;
    mov edi,DOS_HANDLER_START SHL 4
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET dos_int_vect
    mov ecx,5
    rep movs dword ptr es:[edi],ds:[esi]
;
    mov ax,flat_sel
    mov ds,ax
    mov byte ptr [edx],5Ah
    mov word ptr [edx+1],0
    mov ecx,edx
    shr ecx,4
    inc cx
    neg cx
    add cx,0A000h
    mov [edx+3],cx
;
    mov edx,DOS_MEM_START SHL 4
    mov byte ptr [edx],4Dh
    mov word ptr [edx+1],0FFFFh
    sub bx,DOS_MEM_START+1
    mov [edx+3],bx
;
    mov dx,DOS_HANDLER_START
    xor ax,ax
    mov bx,4 * 20h
    mov cx,5

init_vect_loop:
    mov [bx],ax
    mov [bx+2],dx
    add ax,4
    add bx,4
    loop init_vect_loop
;
    pop di
    pop edx
    pop eax
    pop es
    pop ds
    ret
init_process_mem    ENDP

code    ENDS

END

