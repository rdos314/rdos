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
; MEMBLK.ASM
; Memory block interface module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE memblk.inc

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateBlock
;
;   DESCRIPTION:    Create new memory block
;
;   PARAMETERS:     EBX:EAX Physical address
;
;   RETURNS:        ES      Memory block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBlock	Proc near
    pushad
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    push eax
    push ebx
;
    mov al,63h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector32
    mov es,bx
;
    xor edi,edi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop ebx
    pop eax
;
    mov es:mblk_linear_base,edx
    mov es:mblk_physical_base,eax
    mov es:mblk_physical_base+4,ebx
;
    popad
    ret
CreateBlock	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           InitBlock
;
;   DESCRIPTION:    Init memory block
;
;   PARAMETERS:     ES      Memory block selector
;                   AX      Base allocation size
;                   CX      Minimum additional blocks
;                   SI      Reserved size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitBlock     Proc near
    pusha
;
    test si,1
    jz ibStartOk
;
    inc si

ibStartOk:
    mov es:mblk_info_offset,si
    mov es:[si].mblk_ext_size,cx
;
    xor cl,cl
    dec ax

ibShiftLoop:
    or ax,ax
    jz ibShiftOk;
;
    shr ax,1
    inc cl
    jmp ibShiftLoop

ibShiftOk:
    mov es:[si].mblk_size_shift,cl
;
    mov bx,es:[si].mblk_ext_size
    add bx,bx
    add bx,OFFSET mblk_ext_arr
    add bx,es:mblk_info_offset
    mov ax,1000h
    sub ax,bx
    shr ax,cl
    mov es:[si].mblk_free_bits,ax
    dec ax
    shr ax,3
    inc ax
    mov es:[si].mblk_bitmap_size,ax
;
    mov ax,es:[si].mblk_ext_size
    add ax,ax
    add ax,es:[si].mblk_bitmap_size
    add ax,OFFSET mblk_ext_arr
    add ax,es:mblk_info_offset
    dec ax
    mov cl,es:[si].mblk_size_shift
    add cl,3
    shr ax,cl
    inc ax
    shl ax,cl
    mov es:[si].mblk_data_offset,ax
;
    mov bx,ax
    mov ax,1000h
    sub ax,bx
    mov cl,es:[si].mblk_size_shift
    shr ax,cl    
    mov es:[si].mblk_free_bits,ax
    dec ax
    shr ax,5
    inc ax
    shl ax,2
    mov es:[si].mblk_bitmap_size,ax
;
    mov bx,es:[si].mblk_data_offset
    sub bx,ax
    mov es:[si].mblk_bitmap_offset,bx
; 
    mov ax,es:[si].mblk_bitmap_offset
    sub ax,OFFSET mblk_ext_arr
    sub ax,es:mblk_info_offset
    shr ax,1
    mov es:[si].mblk_ext_size,ax
;
    mov bx,es:[si].mblk_free_bits
    mov cl,3
    shr bx,cl
    mov ax,es:[si].mblk_bitmap_size
    sub ax,bx
    jz ibDone
;
    mov dl,-1
    mov bx,es:[si].mblk_data_offset

ibPadLoop:
    dec bx
    mov es:[bx],dl
    sub ax,1
    jnz ibPadLoop
    
ibDone:
    popa
    ret
InitBlock     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateMemBlk32
;
;   DESCRIPTION:    Create new 32-bit memory block
;
;   PARAMETERS:     AX      Base allocation size
;                   CX      Minimum additional blocks
;                   SI      Reserved size
;
;   RETURNS:        ES      Memory block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_mem_blk32_name    DB 'Create 32-bit Mem Blk', 0

create_mem_blk32     Proc far
    push eax
    push ebx
;
    AllocatePhysical32
    call CreateBlock
;
    pop ebx
    pop eax
;
    call InitBlock
    retf32
create_mem_blk32     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateMemBlk64
;
;   DESCRIPTION:    Create new 64-bit memory block
;
;   PARAMETERS:     AX      Base allocation size
;                   CX      Minimum additional blocks
;                   SI      Reserved size
;
;   RETURNS:        ES      Memory block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_mem_blk64_name    DB 'Create 64-bit Mem Blk', 0

create_mem_blk64     Proc far
    push eax
    push ebx
;
    AllocatePhysical64
    call CreateBlock
;
    pop ebx
    pop eax
;
    call InitBlock
    retf32
create_mem_blk64     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateMemBlk
;
;   DESCRIPTION:    Allocate memory block
;
;   PARAMETERS:     CX      Size
;
;   RETURNS:        EDX     Linear address
;                   EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem_blk_name    DB 'Allocate Mem Blk', 0

allocate_mem_blk     Proc far
    int 3
    retf32
allocate_mem_blk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           init_mem_blk
;
;   DESCRIPTION:    Init memory block
;
;   PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_mem_blk
    
init_mem_blk   PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_mem_blk32
    mov edi,OFFSET create_mem_blk32_name
    xor cl,cl
    mov ax,create_mem_blk32_nr
    RegisterOsGate
;
    mov esi,OFFSET create_mem_blk64
    mov edi,OFFSET create_mem_blk64_name
    xor cl,cl
    mov ax,create_mem_blk64_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_mem_blk
    mov edi,OFFSET allocate_mem_blk_name
    xor cl,cl
    mov ax,allocate_mem_blk_nr
    RegisterOsGate
;
    clc
;
    ret
init_mem_blk  ENDP

code    ENDS

    END
