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
; HANDLE.ASM
; User level handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\handle.inc
INCLUDE exec.def

MAX_HANDLES = 1000h

handle_block    STRUC
hf_prev DW ?
hf_next DW ?
hs_prev DW ?
hs_next DW ?
handle_block    ENDS

handle_seg      STRUC

handle_section  section_typ <>

handle_list     DW ?
handle_arr      DW MAX_HANDLES DUP (?)

handle_seg      ENDS

handle_info     STRUC

hi_link         DW ?
hi_sign         DW ?
hi_delete       DD ?,?

handle_info     ENDS

handle_data_seg STRUC

hd_list     DW ?

handle_data_seg ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateHandleData
;
;           DESCRIPTION:    Create handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_handle_data_name DB 'Create Handle Data', 0

create_handle_data    PROC far
    push ds
    push es
    pushad
;    
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
;
    mov eax,SIZE handle_seg
    AllocateSmallGlobalMem
;
    InitSection es:handle_section
;
    mov cx,MAX_HANDLES
    mov di,2 * MAX_HANDLES + OFFSET handle_arr
    mov ax,0FFFEh

chdLoop:
    sub di,2
    mov es:[di],ax
    mov ax,di
    loop chdLoop
;
    mov es:handle_list,di
    mov ds:pr_handle_sel,es
;
    mov eax,10000h
    AllocateGlobalMem
;    
    xor bx,bx
    mov dx,8
    mov es:[bx].hf_next,dx
    mov es:[bx].hs_next,dx
    mov es:[bx].hs_prev,dx
    mov bx,dx
    mov dx,0FFF8h
    mov es:[bx].hf_prev,0
    mov es:[bx].hf_next,0
    mov es:[bx].hs_prev,0
    mov es:[bx].hs_next,dx
;
    mov ds:pr_handle_mem_sel,es
;
    popad
    pop es
    pop ds
    retf32
create_handle_data    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DestroyHandleData
;
;           DESCRIPTION:    Free handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

destroy_handle_data_name DB 'Destroy Handle Data', 0

destroy_handle_data     PROC far
    push ds
    push es
    pushad
;
    GetThread
    mov es,ax
    mov es,es:p_prog_sel
    mov ds,es:pr_handle_sel
    mov es,es:pr_handle_mem_sel
;
    xor bx,bx
    mov di,OFFSET handle_arr
    mov cx,MAX_HANDLES

dhdLoop:
    mov si,[di]
    cmp bx,es:[si].hh_handle
    jne dhdNext
;
    call delete_handle

dhdNext:
    inc bx
    add di,2
    loop dhdLoop
;
    FreeMem
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
;
    popad
    pop es
    pop ds
    retf32
destroy_handle_data     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RegisterHandle
;
;           DESCRIPTION:    Register a handle
;
;           PARAMETERS:     AX          Signature
;                           ES:EDI      Delete callback
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_handle_name    DB 'Register Handle',0

register_handle PROC far
    push ds
    push es
    push ax
;
    push es
    push eax
    mov eax,SIZE handle_info
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    pop eax
    pop es
    mov ds:hi_sign,ax
    mov ds:hi_delete,edi
    mov word ptr ds:hi_delete+4,es
;
    mov ax,handle_data_sel
    mov es,ax
    mov ax,es:hd_list
    mov ds:hi_link,ax
    mov es:hd_list,ds
;
    pop ax
    pop es
    pop ds
    retf32
register_handle ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           allocate_handle_mem
;
;           DESCRIPTION:    Allocate memory for handle
;
;           PARAMETERS:     AX       Total size of memory block
;                           ES       Handle mem sel
;
;           RETURNS:        ES:EBX   Address to memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle_mem     Proc near
    push ax
    push cx
    push si
    push di
;
    add ax,8
    xor si,si
    xor bx,bx
    mov si,es:[si].hf_next

allocate_mem_loop:
    mov cx,es:[si].hs_next
    sub cx,si
    cmp cx,ax
    jnc allocate_mem_found
;
    mov bx,si
    mov si,es:[si].hf_next
    jmp allocate_mem_loop

allocate_mem_found:
    sub cx,ax
    cmp cx,8
    jc allocate_mem_no_split
;
    mov bx,ax
    add bx,si
;       
    mov di,es:[si].hs_next
    mov es:[bx].hs_next,di
    mov es:[bx].hs_prev,si
    mov es:[si].hs_next,bx
    mov es:[di].hs_prev,bx
;
    mov di,es:[si].hf_next
    mov es:[bx].hf_next,di
    mov es:[si].hf_next,bx
    or di,di
    jz allocate_mem_last_free
;
    mov es:[di].hf_prev,bx

allocate_mem_last_free:
    mov di,es:[si].hf_prev
    mov es:[bx].hf_prev,di
    or di,di
    jz allocate_mem_fixup
;
    mov es:[di].hf_next,bx
    jmp allocate_mem_fixup

allocate_mem_no_split:
    mov di,es:[si].hf_prev
    mov bx,es:[si].hf_next
    mov es:[di].hf_next,bx
    mov es:[bx].hf_prev,di

allocate_mem_fixup:
    xor di,di
    mov bx,es:[di].hf_next
    cmp bx,si
    jnz allocate_mem_final
;
    mov bx,es:[si].hf_next
    mov es:[di].hf_next,bx

allocate_mem_final:
    xor di,di
    mov bx,es:[di].hs_prev
    mov cx,es:[si].hs_next
    cmp bx,cx
    jnc allocate_mem_no_biggest_block
;
    mov es:[di].hs_prev,cx

allocate_mem_no_biggest_block:  
    dec di
    mov es:[si].hf_prev,di
    mov es:[si].hf_next,di
;
    lea bx,[si+8]
;
    pop di
    pop si
    pop cx
    pop ax
    ret
allocate_handle_mem     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           free_handle_mem
;
;           DESCRIPTION:    Free memory for handle
;
;           PARAMETERS:     ES:EBX       Offset to memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_handle_mem PROC near
    push ax
    push bx
    push si
    push di
;
    mov si,bx
    sub si,8
    mov di,es:[si].hs_prev
    or di,di
    jz free_handle_no_merge_down
;
    mov di,es:[di].hf_next
    inc di
    or di,di
    jz free_handle_no_merge_down
;
    mov di,si
    mov si,es:[di].hs_prev
    mov bx,es:[di].hs_next
    mov es:[si].hs_next,bx
    mov es:[bx].hs_prev,si
    jmp free_handle_test_up

free_handle_no_merge_down:
    xor di,di
    mov es:[si].hf_prev,di
    mov bx,es:[di].hf_next
    mov es:[si].hf_next,bx
    mov es:[di].hf_next,si
    mov es:[bx].hf_prev,si

free_handle_test_up:
    mov ax,es:[si].hs_next
    mov di,ax
    mov di,es:[di].hf_prev
    inc di
    or di,di
    jz free_handle_no_merge_up
;
    cmp ax,0FFF8h
    je free_handle_no_merge_up
;
    push si
    mov si,es:[si].hs_next
    mov di,es:[si].hf_prev
    mov bx,es:[si].hf_next
    or di,di
    jz fm1_handle_bypass
;
    mov es:[di].hf_next,bx

fm1_handle_bypass:
    or bx,bx
    jz fm2_handle_bypass
;
    mov es:[bx].hf_prev,di

fm2_handle_bypass:
    xor di,di
    mov bx,es:[di].hf_next
    cmp bx,si
    jne fm3_handle_bypass
;
    mov bx,es:[bx].hf_next
    mov es:[di].hf_next,bx

fm3_handle_bypass:
    pop si
    mov bx,es:[si].hs_next
    mov bx,es:[bx].hs_next
    mov es:[bx].hs_prev,si
    mov es:[si].hs_next,bx

free_handle_no_merge_up:
    xor di,di
    mov bx,es:[di].hs_prev
    mov di,es:[si].hs_next
    cmp di,bx
    jc free_handle_not_limit_page
;
    mov di,bx
    add di,1000h
    xor bx,bx
    mov es:[bx].hs_prev,si

free_handle_not_limit_page:
    pop di
    pop si
    pop bx
    pop ax
    ret
free_handle_mem ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateHandle
;
;           DESCRIPTION:    Allocate a handle
;
;           PARAMETERS:     CX          Size of data
;                       
;
;           RETURNS:        DS:EBX   Address to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle_name    DB 'Allocate Handle',0

allocate_handle PROC far
    push es
    push ax
    push si
;
    push ax
    GetThread
    mov ds,ax    
    mov ds,ds:p_prog_sel
    mov es,ds:pr_handle_mem_sel
    mov ds,ds:pr_handle_sel
    pop ax
;
    EnterSection ds:handle_section
    mov ax,cx
    call allocate_handle_mem
    mov es:[bx].hh_sign,0

alloc_retry:
    mov si,ds:handle_list
    mov ax,[si]
    mov ds:handle_list,ax
    mov [si],bx
    cmp si,OFFSET handle_arr
    jbe alloc_retry
;       
    LeaveSection ds:handle_section
;       
    mov ax,es
    mov ds,ax
;
    sub si,OFFSET handle_arr
    shr si,1
    mov [bx].hh_handle,si
    movzx ebx,bx
;
    pop si
    pop ax
    pop es
    retf32
allocate_handle ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeHandle
;
;           DESCRIPTION:    Free a handle
;
;           PARAMETERS:     DS:EBX          Offset to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_handle_name    DB 'Free Handle',0

free_handle     PROC far
    push ax
    push si
    push ds
    push es
;
    GetThread
    mov ds,ax    
    mov ds,ds:p_prog_sel
    mov es,ds:pr_handle_mem_sel
    mov ds,ds:pr_handle_sel
;
    EnterSection ds:handle_section
    mov si,es:[bx].hh_handle
    mov es:[bx].hh_sign,0
    mov es:[bx].hh_handle,0
    call free_handle_mem
;
    shl si,1
    add si,OFFSET handle_arr
    mov ax,ds:handle_list
    mov [si],ax
    mov ds:handle_list,si
    LeaveSection ds:handle_section
    xor bx,bx
;
    pop es
    pop ds
    pop si
    pop ax
    retf32
free_handle     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DerefHandle
;
;           DESCRIPTION:    Deref a handle
;
;           PARAMETERS:     AX          Signature
;                           BX          Handle
;
;           RETURNS:        NC
;                               DS:EBX  Address to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

deref_handle_name       DB 'Deref Handle',0

deref_handle    PROC far
    push es
    push dx
    push si
;
    cmp bx,MAX_HANDLES
    jae deref_fail
;
    push ax
    GetThread
    mov ds,ax    
    mov ds,ds:p_prog_sel
    mov es,ds:pr_handle_mem_sel
    mov ds,ds:pr_handle_sel
    pop ax
;
    mov si,bx
    EnterSection ds:handle_section
    mov bx,word ptr [bx+si].handle_arr
    LeaveSection ds:handle_section
;
    mov dx,es
    mov ds,dx
    cmp ax,[bx].hh_sign
    jne deref_fail
;
    movzx ebx,bx
    cmp si,[bx].hh_handle
    clc
    je deref_done

deref_fail:
    xor ebx,ebx
    mov ds,bx
    stc

deref_done:     
    pop si
    pop dx
    pop es
    retf32
deref_handle    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           verify_mem_list
;
;           DESCRIPTION:    Verify handle is in mem list
;
;           PARAMETERS:         SI          handle mem block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

verify_mem_list Proc near
    push ax
    push si
;
    lea ax,[si-8]
    xor si,si
    mov si,es:[si].hs_next

verify_mem_loop:
    cmp ax,si
    clc
    je verify_mem_done
;
    mov si,es:[si].hs_next
    or si,si
    jnz verify_mem_loop
;
    stc

verify_mem_done:
    pop si
    pop ax
    ret
verify_mem_list Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetFreeHandles
;
;           DESCRIPTION:    Get number of free handles
;
;           RETURNS:    AX      Free handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_handles_name   DB 'Get Free Handles', 0

get_free_handles    Proc far
    push ds
    push si
;
    GetThread
    mov ds,ax    
    mov ds,ds:p_prog_sel
    mov ds,ds:pr_handle_sel
    EnterSection ds:handle_section
;
    xor ax,ax       
    mov si,ds:handle_list

get_free_loop:
    cmp si,0FFFEh
    je get_free_done
;
    mov si,[si]
    inc ax
    jmp get_free_loop 

get_free_done:   
    LeaveSection ds:handle_section
;
    pop si
    pop ds
    retf32
get_free_handles    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetFreeHandleMem
;
;           DESCRIPTION:    Get amount of free handle memory
;
;           RETURNS:    EAX      Free handle memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_handle_mem_name    DB 'Get Free Handle Mem', 0

get_free_handle_mem     Proc far
    push ds
    push es
    push si
;
    GetThread
    mov ds,ax    
    mov ds,ds:p_prog_sel
    mov es,ds:pr_handle_mem_sel
    mov ds,ds:pr_handle_sel
    EnterSection ds:handle_section
;
    xor eax,eax
;
    xor si,si
    mov si,es:[si].hf_next

get_free_mem_loop:
    mov cx,es:[si].hs_next
    sub cx,si
    movzx ecx,cx
    add eax,ecx
;
    mov si,es:[si].hf_next
    or si,si
    jnz get_free_mem_loop
;
    LeaveSection ds:handle_section
;
    pop si
    pop es
    pop ds
    retf32
get_free_handle_mem     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           delete_handle
;
;           DESCRIPTION:    Delete handle
;
;           PARAMETERS:         SI          handle mem block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc near
    push ds
    push es
    push ax
    push bx
    push dx
;
    mov ax,handle_data_sel
    mov ds,ax
;
    mov bx,es:[si].hh_handle
    mov dx,es:[si].hh_sign
    mov ax,ds:hd_list

delete_handle_loop:
    or ax,ax
    jz delete_handle_done
;
    mov es,ax
    cmp dx,es:hi_sign
    jne delete_handle_next
;
    push ds
    push es
    pushad
    call fword ptr es:hi_delete
    popad
    pop es
    pop ds
    jmp delete_handle_done

delete_handle_next:
    mov ax,es:hi_link
    jmp delete_handle_loop

delete_handle_done:
    pop dx
    pop bx
    pop ax
    pop es
    pop ds
    ret
delete_handle   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_handle
;
;           DESCRIPTION:    Init handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_handle

init_handle     PROC near
    push ds
    push es
    pusha
;
    mov eax,SIZE handle_data_seg
    mov bx,handle_data_sel
    AllocateFixedSystemMem
    mov es:hd_list,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_handle_data
    mov edi,OFFSET create_handle_data_name
    xor cl,cl
    mov ax,create_handle_data_nr
    RegisterOsGate
;
    mov esi,OFFSET destroy_handle_data
    mov edi,OFFSET destroy_handle_data_name
    xor cl,cl
    mov ax,destroy_handle_data_nr
    RegisterOsGate
;
    mov esi,OFFSET register_handle
    mov edi,OFFSET register_handle_name
    xor cl,cl
    mov ax,register_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_handle
    mov edi,OFFSET allocate_handle_name
    xor cl,cl
    mov ax,allocate_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET free_handle
    mov edi,OFFSET free_handle_name
    xor cl,cl
    mov ax,free_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET deref_handle
    mov edi,OFFSET deref_handle_name
    xor cl,cl
    mov ax,deref_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET get_free_handles
    mov edi,OFFSET get_free_handles_name
    xor dx,dx
    mov ax,get_free_handles_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_free_handle_mem
    mov edi,OFFSET get_free_handle_mem_name
    xor dx,dx
    mov ax,get_free_handle_mem_nr
    RegisterBimodalUserGate
;
    popa
    pop es
    pop ds
    ret
init_handle     ENDP

code    ENDS

    END
