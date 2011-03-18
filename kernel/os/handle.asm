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
; HANDLE.ASM
; User level handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\handle.inc

MAX_HANDLES = 400h

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
hi_delete       DD ?

handle_info     ENDS

handle_data_seg STRUC

hd_list         DW ?

handle_data_seg ENDS

clone_seg   STRUC

c_list      DW ?
c_arr       DW MAX_HANDLES DUP (?)

c_mem_sel   DW ?

clone_seg   ENDS

code    SEGMENT byte public 'CODE'

.386p
        
        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RegisterHandle
;
;               DESCRIPTION:    Register a handle
;
;               PARAMETERS:             AX              Signature
;                                               ES:DI   Delete callback
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
        mov word ptr ds:hi_delete,di
        mov word ptr ds:hi_delete+2,es
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
        ret
register_handle ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CheckSizeList
;
;               DESCRIPTION:    Check mem size list consistence
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_size_list Proc near
    push ds
    pusha
;    
        mov si,handle_mem_sel
        mov ds,si
        xor si,si
        mov bx,[si].hs_next

check_size_loop:
    cmp bx,si
    ja check_size_gt
;
    int 3 

check_size_gt:
    cmp bx,0FFF8h
    je check_size_done
;
    mov si,bx
    mov bx,[si].hs_next    
    jmp check_size_loop

check_size_done:
    popa
    pop ds
        ret
check_size_list Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CheckHandleMem
;
;               DESCRIPTION:    Check handle mem consistency
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_handle_mem    Proc near
    call check_size_list
    ret
check_handle_mem    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   allocate_handle_mem
;
;               DESCRIPTION:    Allocate memory for handle
;
;               PARAMETERS:             AX              Total size of memory block
;
;               RETURNS:                DS:BX   Address to memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle_mem     Proc near
        push ax
        push cx
        push si
        push di
;
    call check_handle_mem
    
        add ax,8
        mov si,handle_mem_sel
        mov ds,si
        xor si,si
        xor bx,bx
        mov si,[si].hf_next

allocate_mem_loop:
        mov cx,[si].hs_next
        sub cx,si
        cmp cx,ax
        jnc allocate_mem_found
;
        mov bx,si
        mov si,[si].hf_next
        jmp allocate_mem_loop

allocate_mem_found:
        sub cx,ax
        cmp cx,8
        jc allocate_mem_no_split
;
        mov bx,ax
        add bx,si
;       
        mov di,[si].hs_next
        mov [bx].hs_next,di
        mov [bx].hs_prev,si
        mov [si].hs_next,bx
        mov [di].hs_prev,bx
;
        mov di,[si].hf_next
        mov [bx].hf_next,di
        mov [si].hf_next,bx
        or di,di
        jz allocate_mem_last_free
;
        mov [di].hf_prev,bx

allocate_mem_last_free:
        mov di,[si].hf_prev
        mov [bx].hf_prev,di
        or di,di
        jz allocate_mem_fixup
;
        mov [di].hf_next,bx
        jmp allocate_mem_fixup

allocate_mem_no_split:
        mov di,[si].hf_prev
        mov bx,[si].hf_next
        mov [di].hf_next,bx
        mov [bx].hf_prev,di

allocate_mem_fixup:
        xor di,di
        mov bx,[di].hf_next
        cmp bx,si
        jnz allocate_mem_final
;
        mov bx,[si].hf_next
        mov [di].hf_next,bx

allocate_mem_final:
        xor di,di
        mov bx,[di].hs_prev
        mov cx,[si].hs_next
        cmp bx,cx
        jnc allocate_mem_no_biggest_block
;
        mov [di].hs_prev,cx

allocate_mem_no_biggest_block:  
        dec di
        mov [si].hf_prev,di
        mov [si].hf_next,di
;
        lea bx,[si+8]
    call check_handle_mem   
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
;               NAME:                   free_handle_mem
;
;               DESCRIPTION:    Free memory for handle
;
;               PARAMETERS:             DS:BX           Offset to memory block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_handle_mem PROC near
    call check_handle_mem   
    push ax
        push bx
        push si
        push di
;
        mov si,bx
        sub si,8
        mov di,[si].hs_prev
        or di,di
        jz free_handle_no_merge_down
;
        mov di,[di].hf_next
        inc di
        or di,di
        jz free_handle_no_merge_down
;
        mov di,si
        mov si,[di].hs_prev
        mov bx,[di].hs_next
        mov [si].hs_next,bx
        mov [bx].hs_prev,si
        jmp free_handle_test_up

free_handle_no_merge_down:
        xor di,di
        mov [si].hf_prev,di
        mov bx,[di].hf_next
        mov [si].hf_next,bx
        mov [di].hf_next,si
        mov [bx].hf_prev,si

free_handle_test_up:
    mov ax,[si].hs_next
    mov di,ax
        mov di,[di].hf_prev
        inc di
        or di,di
        jz free_handle_no_merge_up
;
    cmp ax,0FFF8h
    je free_handle_no_merge_up
;
        push si
        mov si,[si].hs_next
        mov di,[si].hf_prev
        mov bx,[si].hf_next
        or di,di
        jz fm1_handle_bypass
;
        mov [di].hf_next,bx

fm1_handle_bypass:
        or bx,bx
        jz fm2_handle_bypass
;
        mov [bx].hf_prev,di

fm2_handle_bypass:
        xor di,di
        mov bx,[di].hf_next
        cmp bx,si
        jne fm3_handle_bypass
;
        mov bx,[bx].hf_next
        mov [di].hf_next,bx

fm3_handle_bypass:
        pop si
        mov bx,[si].hs_next
        mov bx,[bx].hs_next
        mov [bx].hs_prev,si
        mov [si].hs_next,bx

free_handle_no_merge_up:
        xor di,di
        mov bx,[di].hs_prev
        mov di,[si].hs_next
        cmp di,bx
        jc free_handle_not_limit_page
;
        mov di,bx
        add di,1000h
        xor bx,bx
        mov [bx].hs_prev,si

free_handle_not_limit_page:
        pop di
        pop si
        pop bx
        pop ax
    call check_handle_mem   
        ret
free_handle_mem ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   AllocateHandle
;
;               DESCRIPTION:    Allocate a handle
;
;               PARAMETERS:             CX              Size of data
;                                       
;
;               RETURNS:                DS:BX   Address to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_handle_name    DB 'Allocate Handle',0

allocate_handle PROC far
        push ax
        push si
;
        mov si,handle_sel
        mov ds,si
        EnterSection ds:handle_section
        mov ax,cx
        call allocate_handle_mem
        mov [bx].hh_sign,0
;
        mov ax,handle_sel
        mov ds,ax

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
        mov ax,handle_mem_sel
        mov ds,ax
;
        sub si,OFFSET handle_arr
        shr si,1
        mov [bx].hh_handle,si
;
        pop si
        pop ax
        ret
allocate_handle ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   FreeHandle
;
;               DESCRIPTION:    Free a handle
;
;               PARAMETERS:             BX              Offset to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_handle_name        DB 'Free Handle',0

free_handle     PROC far
        push ds
        push ax
        push si
;
        mov ax,handle_sel
        mov ds,ax
        EnterSection ds:handle_section
        mov ax,handle_mem_sel
        mov ds,ax
        mov si,[bx].hh_handle
        call free_handle_mem
        mov [bx].hh_sign,0
        mov [bx].hh_handle,0
;
        mov ax,handle_sel
        mov ds,ax
        shl si,1
        add si,OFFSET handle_arr
        mov ax,ds:handle_list
        mov [si],ax
        mov ds:handle_list,si
        LeaveSection ds:handle_section
        xor bx,bx
;
        pop si
        pop ax
        pop ds
        ret
free_handle     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   CloneHandleMem
;
;               DESCRIPTION:    Clone handle mem for fork
;
;
;               RETURNS:                ES      Clone sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_handle_mem_name   DB 'Clone Handle Mem',0

clone_handle_mem        PROC far
    push ds
    push gs
        push eax
        push si
        push di
;
    mov eax,SIZE clone_seg
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
;
    mov eax,10000h
    AllocateGlobalMem
    mov gs:c_mem_sel,es
;    
        mov ax,handle_sel
        mov ds,ax
        EnterSection ds:handle_section
;
    mov ax,handle_mem_sel
    mov ds,ax
    xor si,si
    xor di,di
    mov cx,4000h
    rep movsd
;
    mov ax,gs
    mov es,ax
        mov ax,handle_sel
        mov ds,ax
    mov ax,ds:handle_list
    mov es:c_list,ax
    mov si,OFFSET handle_arr
    mov di,OFFSET c_arr
    mov cx,MAX_HANDLES
    rep movsw
;    
        LeaveSection ds:handle_section
;
    pop di
        pop si
        pop eax
        pop gs
        pop ds
        ret
clone_handle_mem        ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   DerefHandle
;
;               DESCRIPTION:    Deref a handle
;
;               PARAMETERS:             AX              Signature
;                                               BX              Handle
;
;               RETURNS:                NC
;                                               DS:BX   Address to handle data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

deref_handle_name       DB 'Deref Handle',0

deref_handle    PROC far
        push dx
        push si
;
        cmp bx,MAX_HANDLES
        jae deref_fail
;
        mov dx,handle_sel
        mov ds,dx
        mov si,bx
        EnterSection ds:handle_section
        mov bx,word ptr [bx+si].handle_arr
        LeaveSection ds:handle_section
        mov dx,handle_mem_sel
        mov ds,dx
        cmp ax,[bx].hh_sign
        jne deref_fail
;
        cmp si,[bx].hh_handle
        clc
        je deref_done

deref_fail:
        xor bx,bx
        mov ds,bx
        stc

deref_done:     
        pop si
        pop dx
        ret
deref_handle    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   INIT_PROCESS
;
;               DESCRIPTION:    Init per-process data
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process    PROC far
        push ds
        push es
        pushad
;
        mov ax,handle_mem_sel
        mov ds,ax
        xor bx,bx
        mov dx,8
        mov [bx].hf_next,dx
        mov [bx].hs_next,dx
        mov [bx].hs_prev,dx
        mov bx,dx
        mov dx,0FFF8h
        mov [bx].hf_prev,0
        mov [bx].hf_next,0
        mov [bx].hs_prev,0
        mov [bx].hs_next,dx
;
        mov ax,handle_sel
        mov ds,ax
        InitSection ds:handle_section
;
        mov cx,MAX_HANDLES
        mov di,2 * MAX_HANDLES + OFFSET handle_arr
        mov ax,0FFFEh

init_handle_loop:
        sub di,2
        mov [di],ax
        mov ax,di
        loop init_handle_loop
;
        mov ds:handle_list,di
;
        popad
        pop es
        pop ds
        retf32
init_process    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   verify_mem_list
;
;               DESCRIPTION:    Verify handle is in mem list
;
;               PARAMETERS:             SI              handle mem block
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
;               NAME:                   GetFreeHandles
;
;               DESCRIPTION:    Get number of free handles
;
;               RETURNS:        AX      Free handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_handles_name   DB 'Get Free Handles', 0

get_free_handles        Proc far
    push ds
        push si
;
        mov si,handle_sel
        mov ds,si
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
get_free_handles        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetFreeHandleMem
;
;               DESCRIPTION:    Get amount of free handle memory
;
;               RETURNS:        EAX      Free handle memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_handle_mem_name        DB 'Get Free Handle Mem', 0

get_free_handle_mem     Proc far
    push ds
        push si
;
        mov si,handle_sel
        mov ds,si
        EnterSection ds:handle_section
;
    xor eax,eax
        mov si,handle_mem_sel
        mov ds,si
;
        xor si,si
        mov si,[si].hf_next

get_free_mem_loop:
        mov cx,[si].hs_next
        sub cx,si
        movzx ecx,cx
        add eax,ecx
;
        mov si,[si].hf_next
        or si,si
        jnz get_free_mem_loop
;
        mov si,handle_sel
        mov ds,si
        LeaveSection ds:handle_section
;
    pop si
    pop ds
        retf32
get_free_handle_mem     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   delete_handle
;
;               DESCRIPTION:    Delete handle
;
;               PARAMETERS:             SI              handle mem block
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
        call es:hi_delete
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
;               NAME:                   FREE_PROCESS
;
;               DESCRIPTION:    Free per-process data
;
;               PARAMETERS:             
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public free_handle_process

free_handle_process     PROC near
        push ds
        push es
        pushad
;
        mov ax,handle_sel
        mov ds,ax
        mov ax,handle_mem_sel
        mov es,ax
        xor bx,bx
        mov di,OFFSET handle_arr
        mov cx,MAX_HANDLES

free_handle_loop:
        mov si,[di]
        cmp bx,es:[si].hh_handle
        jne free_handle_next
;
        call verify_mem_list
        jc free_handle_next
;
        call delete_handle

free_handle_next:
        inc bx
        add di,2
        loop free_handle_loop
;
        popad
        pop es
        pop ds
        ret
free_handle_process     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init_handle
;
;               DESCRIPTION:    Init handle
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
        mov eax,SIZE handle_seg
        mov bx,handle_sel
        AllocateFixedProcessMem
;
        mov edx,handle_linear
        mov ecx,10000h
        mov bx,handle_mem_sel
        CreateDataSelector16
;
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov edi,OFFSET init_process
        NewHookCreateProcess
;
        mov esi,OFFSET register_handle
        mov edi,OFFSET register_handle_name
        xor cl,cl
        mov ax,register_handle_nr
        RegisterOldOsGate
;
        mov esi,OFFSET allocate_handle
        mov edi,OFFSET allocate_handle_name
        xor cl,cl
        mov ax,allocate_handle_nr
        RegisterOldOsGate
;
        mov esi,OFFSET free_handle
        mov edi,OFFSET free_handle_name
        xor cl,cl
        mov ax,free_handle_nr
        RegisterOldOsGate
;
        mov esi,OFFSET deref_handle
        mov edi,OFFSET deref_handle_name
        xor cl,cl
        mov ax,deref_handle_nr
        RegisterOldOsGate
;
        mov esi,OFFSET clone_handle_mem
        mov edi,OFFSET clone_handle_mem_name
        xor cl,cl
        mov ax,clone_handle_mem_nr
        RegisterOldOsGate
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
