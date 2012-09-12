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
; GDT.ASM
; GDT handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE proc.inc


    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn local_create_data_sel16:near


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CREATE_GDT
;
;           DESCRIPTION:    Create GDT descriptor
;
;           PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public create_gdt

create_gdt      PROC near
    push ds
    push es
    pusha
;
    mov bx,gdt_sel
    mov ds,bx
    mov bx,temp_sel
    mov ecx,10000h
    mov edx,gdt_linear
    call local_create_data_sel16
    mov es,bx
;
    xor si,si
    xor di,di
    mov cx,1000h
    rep movsb
    xor al,al
    mov cx,0E048h
    rep stosb
    mov ds,bx
    mov word ptr [bx],0F047h ; initial size = F048 (F000 + private core space)
    mov si,bx
    mov di,gdt_sel
    movsd
    movsd
;
    mov eax,[bx+2]
    mov cl,[bx+7]
    mov [bx+4],eax
    mov [bx+7],cl
    mov ax,[bx]
    mov [bx+2],ax
    db 66h
    lgdt fword ptr [bx+2]
;
    mov ax,gdt_sel
    mov ds,ax
    mov cx,0D048h
    shr cx,3
    mov si,2000h
    xor bx,bx

init_free_dt_loop:
    mov [si],bx
    mov bx,si
    add si,8
    loop init_free_dt_loop
;
    mov si,bx
    xor bx,bx
    mov [bx],si
;
    mov ax,system_data_sel
    mov ds,ax
    InitSection ds:gdt_section
;
    popa
    pop es
    pop ds
    ret
create_gdt      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT_GDT
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;                           
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_gdt

init_gdt    PROC near
    pusha
    push ds
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_core_gdt
    mov edi,OFFSET create_core_gdt_name
    xor cl,cl
    mov ax,create_core_gdt_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_gdt
    mov edi,OFFSET allocate_name
    xor cl,cl
    mov ax,allocate_gdt_nr
    RegisterOsGate
;       
    mov esi,OFFSET free_gdt
    mov edi,OFFSET free_name
    xor cl,cl
    mov ax,free_gdt_nr
    RegisterOsGate
;       
    mov esi,OFFSET get_free_gdt
    mov edi,OFFSET get_free_gdt_name
    xor dx,dx
    mov ax,get_free_gdt_nr
    RegisterBimodalUserGate
;
    mov edx,gdt_core_linear
    mov bx,core_data_sel
    mov ecx,SIZE processor_seg
    CreateDataSelector16
;
    xor edx,edx
    mov bx,__0000
    mov ecx,1000h
    CreateDataSelector16
;
    mov edx,400h
    mov bx,__0040
    mov ecx,300h
    CreateDataSelector16
;
    mov edx,0A0000h
    mov bx,__A000
    mov ecx,10000h
    CreateDataSelector16
;
    mov edx,0B0000h
    mov bx,__B000
    mov ecx,8000h
    CreateDataSelector16
;
    mov edx,0B8000h
    mov bx,__B800
    mov ecx,8000h
    CreateDataSelector16
;
    mov edx,0C0000h
    mov bx,__C000
    mov ecx,10000h
    CreateDataSelector16
;
    mov edx,0F0000h
    mov bx,__F000
    mov ecx,10000h
    CreateDataSelector16
;
    pop ds
    popa
    ret
init_gdt    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCoreGdt
;
;           DESCRIPTION:    Create a new GDT for a processor core
;
;           RETURNS:        CX      Size of GDT
;                           EDX     Linear base address of GDT
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_core_gdt_name   DB 'Create Core Gdt',0

create_core_gdt    PROC far
    push ds
    push es
    push eax
    push ebx
    push esi
    push edi
;   
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    mov eax,system_linear - gdt_core_linear
    AllocateBigLinear
    mov ebx,edx
    add edx,gdt_linear - gdt_core_linear
;    
    mov edi,edx
    mov esi,gdt_linear
    mov ecx,48h SHR 2
    rep movs dword ptr es:[edi],ds:[esi]
;
    sub edi,8
    mov [edi+2],ebx
    mov al,92h
    xchg al,[edi+5]
    mov [edi+7],al
    add edi,8
;
    mov ecx,0Fh
    CopySysPageEntries
;
    mov bx,gdt_sel
    mov ds,bx
    mov cx,[bx]
    inc cx
;
    pop edi
    pop esi
    pop ebx
    pop eax
    pop es
    pop ds    
    retf32
create_core_gdt     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ALLOCATE_GDT
;
;           DESCRIPTION:    Allocate GDT selector
;
;           RETURNS:        BX          GDT entry / selector
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_name   DB 'Allocate Gdt',0

allocate_gdt    PROC far
    push ds
    push es
    push si
    push di
;
    mov si,system_data_sel
    mov ds,si
    mov si,gdt_sel
    mov es,si
    EnterSection ds:gdt_section
    xor di,di
    mov si,es:[di]
    or si,si
    jnz alloc_gdt_room
;
    int 3
    push ds
    push cx
    mov si,gdt_sel
    mov cx,es:[si]
    inc cx
    or cx,cx
    jnz alloc_gdt_not_full
;
    int 3

alloc_gdt_not_full:
    add word ptr es:[si],1000h
;
    xor bx,bx
    mov eax,es:[si+2]
    mov cl,es:[si+7]
    mov es:[bx+4],eax
    mov es:[bx+7],cl
    mov ax,es:[si]
    mov es:[bx+2],ax
    db 66h
    lgdt fword ptr es:[bx+2]
    mov bx,gdt_sel
    mov ds,bx
;
    mov si,es:[bx]
    inc si
    sub si,1000h
    mov cx,1000h SHR 3
    xor bx,bx

extend_gdt_loop:
    mov es:[si],bx
    mov bx,si
    add si,8
    loop extend_gdt_loop
;
    mov si,bx
    xor bx,bx
    mov es:[bx],si
    pop cx
    pop ds

alloc_gdt_room:
    mov bx,si
    mov si,es:[si]
    mov es:[di],si
    LeaveSection ds:gdt_section
;
    pop di
    pop si
    pop es
    pop ds
    retf32
allocate_gdt    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FREE_GDT
;
;           DESCRIPTION:    Free GDT selector
;
;           PARAMETERS:         BX          GDT entry / selector
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_name       DB 'Free Gdt',0

free_gdt    PROC far
    push ds
    push es
    push si
;
    mov si,system_data_sel
    mov ds,si
    mov si,gdt_sel
    mov es,si
;
    EnterSection ds:gdt_section
    mov byte ptr es:[bx+5],0
    xor si,si
    mov si,es:[si]
    mov es:[bx],si
    xor si,si
    mov es:[si],bx
    LeaveSection ds:gdt_section
;
    pop si
    pop es
    pop ds
    retf32
free_gdt    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetFreeGdtEntries
;
;           DESCRIPTION:    Get Free GDT entries
;
;           RETURNS:        AX      Number of free entries
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_gdt_name       DB 'Get Free Gdt Entries',0

get_free_gdt    PROC far
    push ds
    push es
    push si
    push di
;
    xor ax,ax
    mov si,system_data_sel
    mov ds,si
    mov si,gdt_sel
    mov es,si
    EnterSection ds:gdt_section
    xor di,di
    mov si,es:[di]

gfgLoop:
    or si,si
    jz gfgDone
;
    inc ax
    or ax,ax
    jz gfgDone
;
    mov si,es:[si]
    jmp gfgLoop

gfgDone:
    LeaveSection ds:gdt_section
;
    pop di
    pop si
    pop es
    pop ds
    retf32
get_free_gdt    Endp

code    ENDS

.186

END
