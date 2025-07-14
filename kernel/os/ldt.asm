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

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extern InitServMem:near

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
    mov esi,OFFSET create_private_ldt
    mov edi,OFFSET create_private_ldt_name
    xor cl,cl
    mov ax,create_private_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET destroy_ldt
    mov edi,OFFSET destroy_ldt_name
    xor cl,cl
    mov ax,destroy_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET clone_ldt
    mov edi,OFFSET clone_ldt_name
    xor cl,cl
    mov ax,clone_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET reset_ldt
    mov edi,OFFSET reset_ldt_name
    xor cl,cl
    mov ax,reset_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET create_shared_ldt
    mov edi,OFFSET create_shared_ldt_name
    xor cl,cl
    mov ax,create_shared_ldt_nr
    RegisterOsGate
;    
    mov esi,OFFSET destroy_shared_ldt
    mov edi,OFFSET destroy_shared_ldt_name
    xor cl,cl
    mov ax,destroy_shared_ldt_nr
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
;           NAME:           InitLdt
;
;           DESCRIPTION:    Init ldt
;
;           PARAMETERS:     DS           Ldt obj
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitLdt      PROC near
    push ds
    push es
    push fs
    pushad
;
    GetThread
    mov fs,ax
    mov fs:p_ldt_obj,ds
;
    mov eax,10000h
    AllocateBigLinear
    AllocateGdt
    mov cx,1000h
    CreateLdtSelector
;
    mov fs:p_ldt,bx
    mov ds:ldt_sel,bx
    lldt bx
;
    AllocateGdt
    CreateDataSelector16
    mov fs:p_ldt_sel,bx
    mov ds:ldt_data_sel,bx
    mov es,bx
    xor di,di
    mov dx,8
    mov cx,200h

ilLoop:
    mov ax,dx
    stosw
    xor ax,ax
    stosw
    stosw
    stosw
    add dx,8
    loop ilLoop
;
    sub di,8
    stosw
;
    InitSection ds:ldt_section
    mov ds:ldt_free,ldt_start
;       
    popad
    pop fs
    pop es
    pop ds
    ret
InitLdt      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreatePrivateLdt
;
;           DESCRIPTION:    Create private LDT (for app processes)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_private_ldt_name   DB 'Create Private LDT', 0

create_private_ldt      PROC far
    push ds
    push es
    push eax
;
    mov eax,SIZE ldt_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
;
    GetThread
    mov es,ax
    mov es,es:p_proc_sel
    mov es:pf_ldt_obj,ds
;
    call InitLdt
;
    pop eax
    pop es
    pop ds
    retf32
create_private_ldt      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSharedLdt
;
;           DESCRIPTION:    Create shared LDT (for server processes)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_shared_ldt_name   DB 'Create Shared LDT', 0

create_shared_ldt      PROC far
    push ds
    push es
    push bx
;
    CreateServDir
    call InitServMem
    mov ds,bx
;
    call InitLdt
;
    pop bx
    pop es
    pop ds
    retf32
create_shared_ldt      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloneLdt
;
;           DESCRIPTION:    Create a new LDT and copy entries from the current
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_ldt_name   DB 'Clone LDT', 0

clone_ldt      PROC far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov eax,SIZE ldt_struc
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
;
    GetThread
    mov fs,ax
    mov ds,fs:p_ldt_obj
    EnterSection ds:ldt_section
;
    mov ax,ds:ldt_free
    push ax
;
    mov eax,10000h
    AllocateBigLinear
;
    mov bx,fs:p_ldt_sel
    mov ax,gdt_sel
    mov ds,ax
    movzx ecx,word ptr ds:[bx]
    inc ecx
    mov ds,bx
;
    AllocateGdt
    CreateDataSelector32
    mov es,bx
    xor esi,esi
    xor edi,edi
    shr ecx,2
    rep movs dword ptr es:[edi],ds:[esi]
;
    mov ds,fs:p_ldt_obj
    LeaveSection ds:ldt_section
;
    mov fs:p_ldt_sel,bx
    mov gs:ldt_data_sel,bx
;
    AllocateGdt
    CreateLdtSelector
;
    mov fs:p_ldt,bx
    mov gs:ldt_sel,bx
    lldt bx
;
    mov fs:p_ldt_obj,gs
;
    pop ax
    mov gs:ldt_free,ax
    InitSection gs:ldt_section
;
    mov es,fs:p_proc_sel
    mov es:pf_ldt_obj,gs
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    retf32
clone_ldt      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetLdt
;
;           DESCRIPTION:    Remove user-mode entries from LDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_ldt_name   DB 'Reset LDT', 0

reset_ldt      PROC far
    push ds
    push es
    pushad
;
    GetThread
    mov ds,ax
    mov ds,ds:p_ldt_obj
    EnterSection ds:ldt_section
;
    mov bx,ds:ldt_data_sel
    mov ax,gdt_sel
    mov es,ax
    movzx ecx,word ptr es:[bx]
    inc ecx
    mov es,bx
;
    xor bx,bx

rlLoop:
    mov al,es:[bx+5]
    test al,80h
    jz rlNext
;
    mov al,es:[bx+7]
    and al,0C0h
    cmp al,0C0h
    je rlNext
;
    mov byte ptr es:[bx+5],0
    mov ax,ds:ldt_free
    mov es:[bx],ax
    mov ds:ldt_free,bx

rlNext:
    add bx,8
    sub ecx,8
    jnz rlLoop
;
    LeaveSection ds:ldt_section
;
    popad
    pop es
    pop ds
    retf32
reset_ldt      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DestroyLdt
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
    mov ds,ds:p_proc_sel
;
    xor bx,bx
    xchg bx,ds:pf_ldt_obj
    or bx,bx
    jz dlDone
;
    mov ds,bx
;
    xor bx,bx
    xchg bx,ds:ldt_sel
    xor ax,ax
    lldt ax
    FreeGdt
;
    xor ax,ax
    xchg ax,ds:ldt_data_sel
    mov es,ax
    FreeMem
;
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem

dlDone:
    pop bx
    pop ax
    pop es
    pop ds
    retf32
destroy_ldt     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DestroySharedLdt
;
;           DESCRIPTION:    Destroy shared LDT
;
;           PARAMETERS:         
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

destroy_shared_ldt_name DB 'Destroy Shared LDT', 0

destroy_shared_ldt     PROC far
    push ds
    push es
    push ax
    push bx
;
    GetThread
    mov ds,ax
;
    xor bx,bx
    xchg bx,ds:p_ldt_obj
    mov ds,bx
;
    xor bx,bx
    xchg bx,ds:ldt_sel
    xor ax,ax
    lldt ax
    FreeGdt
;
    xor ax,ax
    xchg ax,ds:ldt_data_sel
    mov es,ax
    FreeMem
;
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
;
    pop bx
    pop ax
    pop es
    pop ds
    retf32
destroy_shared_ldt     ENDP

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
    mov ds,ds:p_ldt_obj
;
    mov bx,ds   
    push bx
    mov ds,bx
    mov es,bx
    EnterSection ds:ldt_section
    mov ds,ds:ldt_data_sel

allocate_ldt_again:
    mov bx,es:ldt_free
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
    mov es:ldt_free,dx
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
    mov es:ldt_free,di
    mov di,ds
    pop ds
    LeaveSection ds:ldt_section
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
    mov es:ldt_free,dx
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
    mov ds,ds:p_ldt_obj 
    pop ax
    mov bx,ds
    mov es,bx
    push ds
    EnterSection ds:ldt_section
    mov ds,ds:ldt_data_sel
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
    mov ax,es:ldt_free

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
    mov es:ldt_free,ax
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
    LeaveSection ds:ldt_section
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
    mov ds,ds:p_ldt_obj
    and bl,NOT 7
;
    EnterSection ds:ldt_section
    mov es,ds:ldt_data_sel
    mov byte ptr es:[bx+5],0
    mov ax,ds:ldt_free
    mov es:[bx],ax
    mov ds:ldt_free,bx
    LeaveSection ds:ldt_section
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
;           RETURNS:        AX          Free entries
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
    mov ds,ds:p_ldt_obj
;
    EnterSection ds:ldt_section
    mov bx,ds:ldt_data_sel
    mov es,bx
;
    GetSelectorBaseSize
    shr ecx,3
    mov ax,2000h
    sub ax,cx
;
    mov bx,ds:ldt_free

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
    LeaveSection ds:ldt_section
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
