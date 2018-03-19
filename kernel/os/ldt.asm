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
; LDT.ASM
; LDT handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE int.def
INCLUDE protseg.def
INCLUDE exec.def

ldt_start       EQU 80h

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_LDT
;
;           DESCRIPTION:    Init module
;
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_ldt

init_ldt    PROC near
    pusha
    push ds
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov esi,OFFSET create_ldt
    mov edi,OFFSET create_ldt_name
    xor cl,cl
    mov ax,create_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET destroy_ldt
    mov edi,OFFSET destroy_ldt_name
    xor cl,cl
    mov ax,destroy_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET allocate_ldt
    mov edi,OFFSET allocate_name
    xor cl,cl
    mov ax,allocate_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET free_ldt
    mov edi,OFFSET free_name
    xor cl,cl
    mov ax,free_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET allocate_multiple_ldt
    mov edi,OFFSET allocate_multiple_name
    xor cl,cl
    mov ax,allocate_multiple_ldt_nr
    RegisterOsGate
;       
    mov esi,OFFSET get_free_ldt
    mov edi,OFFSET get_free_ldt_name
    xor dx,dx
    mov ax,get_free_ldt_nr
    RegisterBimodalUserGate
    pop ds
    popa
    ret
init_ldt    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CREATE_LDT
;
;           DESCRIPTION:    Create LDT for process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_ldt_name   DB 'Create LDT', 0

create_ldt      PROC far
    push ds
    push es
    pushad
;
    mov eax,10000h
    AllocateBigLinear
    AllocateGdt
    mov cx,1000h
    CreateLdtSelector
;
    GetThread
    mov es,ax
    mov es:p_ldt,bx
;
    mov ds,es:p_prog_sel
    mov ds:pr_ldt_sel,bx
    lldt bx
;
    AllocateGdt
    CreateDataSelector16
    GetThread
    mov es,ax
    mov es:p_ldt_sel,bx
    mov ds:pr_ldt_data_sel,bx
    mov es,bx
    xor di,di
    mov dx,8
    mov cx,200h

init_ldt_loop:
    mov ax,dx
    stosw
    xor ax,ax
    stosw
    stosw
    stosw
    add dx,8
    loop init_ldt_loop
;
    sub di,8
    stosw
;
    InitSection ds:pr_ldt_section
    mov ds:pr_ldt_free,ldt_start
;       
    popad
    pop es
    pop ds
    retf32
create_ldt      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DESTROY_LDT
;
;           DESCRIPTION:    Destroy LDT
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

destroy_ldt_name DB 'Destroy LDT', 0

destroy_ldt     PROC far
    push ds
    push es
    push ax
    push bx
;
    GetThread
    mov ds,ax
;
    xor bx,bx
    xchg bx,ds:p_ldt
    xor ax,ax
    lldt ax
    FreeGdt
;
    xor ax,ax
    xchg ax,ds:p_ldt_sel
    mov es,ax
    FreeMem
;
    pop bx
    pop ax
    pop es
    pop ds
    retf32
destroy_ldt     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_LDT
;
;           DESCRIPTION:    Allocate LDT descriptor entry
;
;           RETURNS:        DS:BX          Selector
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_name   DB 'Allocate Ldt',0

allocate_ldt    PROC far
    push es
    push ax
    push di
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
;
    mov bx,ds   
    push bx
    mov ds,bx
    mov es,bx
    EnterSection ds:pr_ldt_section
    mov ds,ds:pr_ldt_data_sel

allocate_ldt_again:
    mov bx,es:pr_ldt_free
    or bx,bx
    jnz allocate_ldt_ok
;
    push ds
    push ax
    push cx
    push dx
    push es
    mov ax,ds
    mov es,ax
    GetThread
    mov ds,ax
    mov bx,ds:p_ldt
    mov ax,gdt_sel
    mov ds,ax
    mov ax,[bx]
    add ax,1000h
    mov [bx],ax
    mov bx,es
    mov [bx],ax
    mov es,bx
    sub ax,0FFFh
    mov di,ax
    mov dx,ax
    add dx,8
    mov cx,200h

extend_ldt_loop:
    mov ax,dx
    stosw
    xor ax,ax
    stosw
    stosw
    stosw
    add dx,8
    loop extend_ldt_loop
;
    sub di,8
    stosw
    sub dx,1008h
    pop es
    mov es:pr_ldt_free,dx
    sldt ax
    lldt ax
    pop dx
    pop cx
    pop ax
    pop ds
    jmp allocate_ldt_again

allocate_ldt_ok:
    mov di,[bx]
    cmp di,0FFFFh
    jne al1
    int 3

al1:
    mov es:pr_ldt_free,di
    mov di,ds
    pop ds
    LeaveSection ds:pr_ldt_section
    mov ds,di
    and bl,NOT 7
;
    pop di
    pop ax
    pop es
    retf32
allocate_ldt    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_MULTIPLE_LDT
;
;           DESCRIPTION:    Allocate multiple continous LDT descriptors
;
;           PARAMETERS:         CX          Number of descriptor
;                           
;           RETURNS:        BX          Base selector
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_multiple_name  DB 'Allocate Multiple Ldt',0

allocate_mldt_extend    PROC near
    push ax
    push cx
    push dx
    push es
    mov ax,ds
    mov es,ax
    GetThread
    mov ds,ax
    mov bx,ds:p_ldt
    mov ax,gdt_sel
    mov ds,ax
    mov ax,[bx]
    add ax,1000h
    mov [bx],ax
    mov bx,es
    mov [bx],ax
    mov es,bx
    sub ax,0FFFh
    mov di,ax
    mov dx,ax
    add dx,8
    mov cx,200h

extend_mldt_loop:
    mov ax,dx
    stosw
    xor ax,ax
    stosw
    stosw
    stosw
    add dx,8
    loop extend_mldt_loop
;
    sub di,8
    stosw
    pop es
    sub dx,1008h
    mov es:pr_ldt_free,dx
    pop dx
    add dx,1000h
    pop cx
    pop ax
    ret
allocate_mldt_extend    ENDP

allocate_multiple_ldt   PROC far
    push ds
    push es
    push ax
    push dx
    push si
    push di
    GetThread
    mov ds,ax
    mov bx,ds:p_ldt
    mov ax,gdt_sel
    mov ds,ax
    mov dx,[bx]
    inc dx
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel 
    pop ax
    mov bx,ds
    mov es,bx
    push ds
    EnterSection ds:pr_ldt_section
    mov ds,ds:pr_ldt_data_sel
    mov bx,ldt_start

allocate_mldt_retry_loop:
    push cx

allocate_mldt_loop:
    mov al,[bx+5]
    add bx,8
    or al,al
    jz allocate_mldt_free
;
    pop cx
    jmp allocate_mldt_retry_loop

allocate_mldt_free:
    cmp bx,dx
    jne allocate_mldt_next
;
    call allocate_mldt_extend

allocate_mldt_next:
    loop allocate_mldt_loop
;
    pop cx
    push cx
    mov dx,cx
    shl dx,3
    sub bx,dx
    mov ax,es:pr_ldt_free

allocate_mldt_head_first_loop:
    sub ax,bx
    jc allocate_mldt_head_unalloc
;
    cmp ax,dx
    jnc allocate_mldt_head_unalloc
;
    add ax,bx
    mov si,ax
    mov ax,[si]
    mov es:pr_ldt_free,ax
    loop allocate_mldt_head_first_loop
;
    jmp allocate_mldt_end

allocate_mldt_head_unalloc:
    add ax,bx
    mov si,ax
    mov di,ax

allocate_mldt_selector_head_loop:
    mov ax,[si]
    sub ax,bx
    jc allocate_mldt_save_head
;
    cmp ax,dx
    jnc allocate_mldt_save_head
;
    mov si,[si]
    loop allocate_mldt_selector_head_loop

allocate_mldt_save_head:
    mov si,[si]
    mov [di],si
    mov di,si
    or cx,cx
    jnz allocate_mldt_selector_head_loop

allocate_mldt_end:
    pop cx
    pop ds
    LeaveSection ds:pr_ldt_section
;
    pop di
    pop si
    pop dx
    pop ax
    pop es
    pop ds
    retf32
allocate_multiple_ldt   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FREE_LDT
;
;           DESCRIPTION:    Free a LDT descriptor
;
;           PARAMETERS:         BX          Selector
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_name       DB 'Free Ldt',0

free_ldt    PROC far
    push ds
    push es
    push ax
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
    and bl,NOT 7
;       
    EnterSection ds:pr_ldt_section
    mov es,ds:pr_ldt_data_sel
    mov byte ptr es:[bx+5],0
    mov ax,ds:pr_ldt_free
    mov es:[bx],ax
    mov ds:pr_ldt_free,bx
    LeaveSection ds:pr_ldt_section
;
    pop ax
    pop es
    pop ds
    retf32
free_ldt    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFreeLdt
;
;           DESCRIPTION:    Get free entries in LDT
;
;           RETURNS:        AX		Free entries
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_ldt_name   DB 'Get Free Ldt',0

get_free_ldt    PROC far
    push ds
    push es
    push ebx
    push ecx
    push edx
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_prog_sel
;
    EnterSection ds:pr_ldt_section
    mov bx,ds:pr_ldt_data_sel
    mov es,bx
;
    GetSelectorBaseSize
    shr ecx,3
    mov ax,2000h
    sub ax,cx
;
    mov bx,ds:pr_ldt_free

gfLoop:
    or bx,bx
    jz gfDone
;
    inc ax
;
    mov di,es:[bx]
    cmp di,0FFFFh
    je gfDone
;
    mov bx,di
    jmp gfLoop

gfDone:
    LeaveSection ds:pr_ldt_section
;
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    retf32
get_free_ldt    ENDP

code    ENDS

END
