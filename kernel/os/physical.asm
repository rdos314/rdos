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
; PHYSICAL.ASM
; Physical memory module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\driver.def

mmap_struc  STRUC

mmap_len    DD ?
mmap_base   DD ?,?
mmap_size   DD ?,?
mmap_type   DD ?

mmap_struc  ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

    extrn local_get_selector_base_size:near
    extrn local_create_data_sel16:near
    extrn AllocateRam:near

    extrn get_page_dir_attrib_proc:word
    extrn set_sys_page_dir_proc:word

code    SEGMENT byte public use16 'CODE'

    assume cs:code

      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetPhysBitmap32
;
;       DESCRIPTION:    Get 32-bit physical bitmap
;
;       RETURNS:        SI      Bitmap header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPhysBitmap32  Proc near
    mov cx,ds:phys_bitmap_count
    sub cx,1
    jc gpbDone32
    stc
    jz gpbDone32
;    
    cmp cx,31
    jbe gpbCountOk32
;
    mov cx,31

gpbCountOk32:
    mov bx,4 + phys_header_start
    mov si,bx
    xor di,di

gpbLoop32:
    mov ax,ds:[bx].phys_bitmap_free
    cmp ax,di
    jbe gpbNext32
;
    mov si,bx
    mov di,ax
    cmp ax,4000h
    jae gpbOk32

gpbNext32:
    add bx,4
    loop gpbLoop32
;
    or di,di
    stc
    jz gpbDone32

gpbOk32:
    clc

gpbDone32:
    ret
GetPhysBitmap32  Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetPhysBitmap64
;
;       DESCRIPTION:    Get 64-bit physical bitmap
;
;       RETURNS:        SI      Bitmap header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPhysBitmap64  Proc near
    mov cx,ds:phys_bitmap_count
    sub cx,32
    jc gpbDone64
;
    stc
    jz gpbDone64
;    
    mov bx,32 * 4 + phys_header_start
    mov si,bx
    xor di,di

gpbLoop64:
    mov ax,ds:[bx].phys_bitmap_free
    cmp ax,di
    jbe gpbNext64
;
    mov si,bx
    mov di,ax
    cmp ax,4000h
    jae gpbOk64

gpbNext64:
    add bx,4
    loop gpbLoop64
;
    or di,di
    stc
    jz gpbDone64

gpbOk64:
    clc

gpbDone64:
    ret
GetPhysBitmap64  Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateFromBitmap
;
;       DESCRIPTION:    Try to allocate from bitmap
;
;       PARAMETERS:     EBX     Position
;                       EDX     Max postion
;                       SI      Header offset
;                       EDI     Bitmap offset
;
;       RETURNS:        EBX     New position
;                       ECX     Allocated bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateFromBitmap  Proc near

afbLoop:
    cmp ebx,edx
    jae afbFail
;    
    mov eax,ds:[ebx+edi]
    or eax,eax
    jz afbNext
;
    bsf ecx,eax
    lock btr ds:[ebx+edi],ecx
    jc afbOk

afbNext:
    add bx,4
    jmp afbLoop

afbFail:
    mov ds:[si].phys_bitmap_pos,0
    xor bx,bx
    stc
    jmp afbDone

afbOk:
    lock dec ds:[si].phys_bitmap_free
;
    mov ax,si
    sub ax,phys_header_start
    movzx eax,ax
    shl eax,13
    add ecx,eax
;    
    mov eax,ebx
    shl eax,3
    add ecx,eax
    clc

afbDone:
    ret
AllocateFromBitmap  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalAllocatePhysical
;
;           DESCRIPTION:    Allocate physical page
;
;           PARAMETERS:     EDX:EAX         Address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_allocate_physical

local_allocate_physical       PROC near
    push ds
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,phys_bit_sel
    mov ds,ax
    xor ebx,ebx
    xor esi,esi

apRetry64:
    mov bx,ds:phys_curr_header64
    cmp bx,ds:phys_bitmap_count
    jae apNew64
;    
    mov si,phys_header_start
    mov eax,ebx
    shl eax,2
    add si,ax
;    
    mov edi,phys_bitmap_start
    shl eax,10
    add edi,eax
;
    mov ax,ds:[si].phys_bitmap_free
    or ax,ax
    jz apNew64
;
    movzx ebx,ds:[si].phys_bitmap_pos
    mov edx,1000h
    call AllocateFromBitmap
    jnc apOk64

apNew64:
    call GetPhysBitmap64
    jnc apNewNext64
;
    call GetPhysBitmap32
    jc apNewFirst64

apNewNext64:
    mov ax,si
    sub ax,phys_header_start
    shr ax,2
    mov ds:phys_curr_header64,ax
    jmp apRetry64

apNewFirst64:
    mov si,phys_header_start
    mov ax,ds:[si].phys_bitmap_free
    or ax,ax
    jz apFail64
;
    mov ebx,200h
    mov edx,1000h
    mov edi,phys_bitmap_start
    call AllocateFromBitmap
    jnc apOk64_0
;
    xor ebx,ebx    
    mov edx,200h
    mov edi,phys_bitmap_start
    call AllocateFromBitmap
    jnc apOk64_0

apFail64:
    stc
    jmp apDone64

apOk64_0:
    mov ax,si
    sub ax,phys_header_start
    shr ax,2
    mov ds:phys_curr_header64,ax

apOk64:
    cmp bx,ds:[si].phys_bitmap_pos
    je apRetAds64
;    
    mov ds:[si].phys_bitmap_pos,bx
;
    mov ax,ds:phys_curr_header64
    cmp ax,32
    jae apRetAds64
;
    push ecx
    call GetPhysBitmap64
    pop ecx
    jnc apUpdateHeader64
;
    mov ax,ds:phys_curr_header64
    or ax,ax
    jnz apRetAds64
;
    push ecx
    call GetPhysBitmap32
    pop ecx
    jc apRetAds64

apUpdateHeader64:    
    mov ax,si
    sub ax,phys_header_start
    shr ax,2
    mov ds:phys_curr_header64,ax

apRetAds64:    
    mov eax,ecx
    mov ebx,ecx
    shl eax,12
    shr ebx,20
    clc

apDone64:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ds
    ret
local_allocate_physical       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocatePhysical32
;
;           DESCRIPTION:    Allocate physical page
;
;           RETURNS:        EBX:EAX         Address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_physical32_name  DB 'Allocate Physical Memory32',0

allocate_physical32       PROC far
    push ds
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,phys_bit_sel
    mov ds,ax
    xor ebx,ebx
    xor esi,esi

apRetry32:
    mov bx,ds:phys_curr_header32
    cmp bx,ds:phys_bitmap_count
    jae apNew32
;    
    mov si,phys_header_start
    mov eax,ebx
    shl eax,2
    add si,ax
;    
    mov edi,phys_bitmap_start
    shl eax,10
    add edi,eax
;
    mov ax,ds:[si].phys_bitmap_free
    or ax,ax
    jz apNew32
;
    movzx ebx,ds:[si].phys_bitmap_pos
    mov edx,1000h
    call AllocateFromBitmap
    jnc apOk32

apNew32:
    call GetPhysBitmap32
    jc apNewFirst32
;
    mov ax,si
    sub ax,phys_header_start
    shr ax,2
    mov ds:phys_curr_header64,ax
    jmp apRetry32

apNewFirst32:
    mov si,phys_header_start
    mov ax,ds:[si].phys_bitmap_free
    or ax,ax
    jz apFail32
;
    mov ebx,200h
    mov edx,1000h
    mov edi,phys_bitmap_start
    call AllocateFromBitmap
    jnc apOk32_0
;
    xor ebx,ebx    
    mov edx,200h
    mov edi,phys_bitmap_start
    call AllocateFromBitmap
    jnc apOk32_0

apFail32:
    stc
    jmp apDone32

apOk32_0:
    mov ax,si
    sub ax,phys_header_start
    shr ax,2
    mov ds:phys_curr_header32,ax

apOk32:
    cmp bx,ds:[si].phys_bitmap_pos
    je apRetAds32
;    
    mov ds:[si].phys_bitmap_pos,bx
    mov ax,ds:phys_curr_header32
    or ax,ax
    jnz apRetAds32
;
    push ecx
    call GetPhysBitmap32
    pop ecx
    jc apRetAds32
;
    mov ax,si
    sub ax,phys_header_start
    shr ax,2
    mov ds:phys_curr_header32,ax

apRetAds32:    
    mov eax,ecx
    shl eax,12
    xor ebx,ebx
    clc

apDone32:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ds
    retf32
allocate_physical32       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocatePhysical64
;
;           DESCRIPTION:    Allocate physical page
;
;           RETURNS:        EBX:EAX         Address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_physical64_name  DB 'Allocate Physical Memory64',0

allocate_physical64       PROC far
    call local_allocate_physical
    retf32
allocate_physical64       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateDmaPhysical
;
;           DESCRIPTION:    Allocate DMA physical page
;
;           PARAMETERS:         EAX         Address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_dma_physical_name      DB 'Allocate DMA Physical Memory',0

allocate_dma_physical   PROC far
    push ds
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,phys_bit_sel
    mov ds,ax
;    
    mov si,phys_header_start
    mov ax,ds:[si].phys_bitmap_free
    or ax,ax
    jz apFailDma
;
    xor ebx,ebx    
    mov edx,200h
    mov edi,phys_bitmap_start
    call AllocateFromBitmap
    jnc apOkDma

apFailDma:
    stc
    jmp apDoneDma

apOkDma:
    mov eax,ecx
    shl eax,12
    xor ebx,ebx
    clc

apDoneDma:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ds
    retf32
allocate_dma_physical   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalFreePhysical
;
;           DESCRIPTION:    Free physical page
;
;           PARAMETERS:     EBX:EAX         Address
;                           
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public local_free_physical

local_free_physical   PROC near
    push ds
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    mov cx,phys_bit_sel
    mov ds,cx
;
    mov ecx,ebx
    shl ecx,20
    mov esi,eax
    shr esi,12
    add ecx,esi
    mov ebx,ecx
    shr ebx,15
    and ecx,7FFFh
;
    cmp bx,ds:phys_bitmap_count
    jb fpDo
;
    int 3

fpDo:
    mov edi,ebx
    shl edi,12
    add edi,phys_bitmap_start
    lock bts ds:[edi],ecx
    jnc fpOk
;
    int 3

fpOk:
;
    shl ebx,2
    add ebx,phys_header_start
    lock inc ds:[ebx].phys_bitmap_free
;
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
local_free_physical   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreePhysical
;
;           DESCRIPTION:    Free physical page
;
;           PARAMETERS:     EBX:EAX         Address
;                           
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_physical_name      DB 'Free Physical Memory',0

free_physical   PROC far
    call local_free_physical
    retf32
free_physical   ENDP

      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateMultBitmap
;
;       DESCRIPTION:    Allocate multiple entries in bitmap
;
;       PARAMETERS:     DS:EDI      Bitmap
;                       DX          Number of dwords wanted
;
;       RETURNS:        EDI         Position in bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateMultBitmap   Proc near
    push bx
    push cx
    push esi
;    
    mov cx,400h
    xor bx,bx    
    mov esi,edi

ambLoop:
    mov eax,ds:[edi]
    cmp eax,-1
    jne ambReset
;
    inc bx
    cmp bx,dx
    je ambOk
;        
    add edi,4
    jmp ambNext
    
ambReset:    
    add edi,4
    mov esi,edi
    xor bx,bx

ambNext:
    loop ambLoop
;    
    stc
    jmp ambDone

ambOk:
    mov edi,esi
    clc

ambDone:
    pop esi
    pop cx
    pop bx
    ret    
AllocateMultBitmap   Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMultPhys64
;
;       DESCRIPTION:    Get multiple entries, 64-bit version
;
;       PARAMETERS:     CX          Number of entries wanted
;                       DX          Number of dwords needed
;
;       RETURNS:        BX          Bitmap #
;                       SI          Header offset
;                       EDI         Offset in bitmap         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMultPhys64   Proc near
    push bp
;    
    mov bx,32
    mov bp,ds:phys_bitmap_count
    sub bp,bx
    jbe gmpFail64

gmpLoop64:
    mov si,bx
    shl si,2
    add si,phys_header_start
    cmp cx,ds:[si].phys_bitmap_free
    ja gmpNext64
;
    movzx edi,bx
    shl edi,12
    add edi,phys_bitmap_start
    call AllocateMultBitmap
    jnc gmpDone64

gmpNext64:
    inc bx
    sub bp,1
    jnz gmpLoop64

gmpFail64:
    stc

gmpDone64:
    pop bp
    ret
GetMultPhys64  Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMultPhys32
;
;       DESCRIPTION:    Get multiple entries, 32-bit version
;
;       PARAMETERS:     CX          Number of entries wanted
;                       DX          Number of dwords needed
;
;       RETURNS:        BX          Bitmap #
;                       SI          Header offset
;                       EDI         Offset in bitmap         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMultPhys32   Proc near
    push bp
;    
    mov bp,ds:phys_bitmap_count
    cmp bp,32
    jbe gmpCountOk32
;
    mov bp,32

gmpCountOk32:    
    mov bx,1
    sub bp,bx
    jbe gmpFail32

gmpLoop32:
    mov si,bx
    shl si,2
    add si,phys_header_start
    cmp cx,ds:[si].phys_bitmap_free
    ja gmpNext32
;
    movzx edi,bx
    shl edi,12
    add edi,phys_bitmap_start
    call AllocateMultBitmap
    jnc gmpDone32

gmpNext32:
    inc bx
    sub bp,1
    jnz gmpLoop32

gmpFail32:
    stc

gmpDone32:
    pop bp
    ret
GetMultPhys32  Endp

      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMultPhysDma
;
;       DESCRIPTION:    Get multiple entries, DMA version
;
;       PARAMETERS:     CX          Number of entries wanted
;                       DX          Number of dwords needed
;
;       RETURNS:        BX          Bitmap #
;                       SI          Header offset
;                       EDI         Offset in bitmap         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMultPhysDma   Proc near
    xor bx,bx
    mov si,phys_header_start
    cmp cx,ds:[si].phys_bitmap_free
    ja gmpFailDma
;
    mov edi,phys_bitmap_start
    call AllocateMultBitmap
    jmp gmpDoneDma

gmpFailDma:
    stc

gmpDoneDma:
    ret
GetMultPhysDma  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateMultiplePhysical64
;
;           DESCRIPTION:    Allocate multiple physical page
;
;           PARAMETERS:     ECX         Number of pages
;
;           RETURN:         EBX:EAX     Physical base address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_multiple_physical64_name DB 'Allocate 64-bit Multiple Physical Memory',0

allocate_multiple_physical64      PROC far
    push ds
    push edx
    push esi
    push edi    
;    
    mov ax,phys_bit_sel
    mov ds,ax
;
    mov edx,ecx
    dec edx
    and dl,0E0h
    shr edx,5
    inc dx

ampRetry64:
    call GetMultPhys64
    jnc ampTake64
;
    call GetMultPhys32
    jnc ampTake64
;
    call GetMultPhysDma
    jc ampDone64

ampTake64:            
    xor eax,eax

ampMark64:    
    lock btr ds:[edi],eax     
    jnc ampRetry64
;    
    lock dec ds:[si].phys_bitmap_free
    inc eax
    cmp eax,ecx
    jb ampMark64
;
    mov ax,si
    sub ax,phys_header_start
    movzx eax,ax
    shl eax,13
    mov edx,eax
;    
    mov eax,edi
    and ax,0FFFh
    shl eax,3
    add edx,eax
;    
    mov eax,edx
    mov ebx,edx
    shl eax,12
    shr ebx,20
    clc

ampDone64:
    pop edi
    pop esi
    pop edx
    pop ds
    retf32
allocate_multiple_physical64      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateMultiplePhysical32
;
;           DESCRIPTION:    Allocate multiple physical page
;
;           PARAMETERS:     ECX         Number of pages
;
;           RETURN:         EBX:EAX     Physical base address
;                                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_multiple_physical32_name DB 'Allocate 32-bit Multiple Physical Memory',0

allocate_multiple_physical32      PROC far
    push ds
    push edx
    push esi
    push edi    
;    
    mov ax,phys_bit_sel
    mov ds,ax
;
    mov edx,ecx
    dec edx
    and dl,0E0h
    shr edx,5
    inc dx

ampRetry32:
    call GetMultPhys32
    jnc ampTake32
;
    call GetMultPhysDma
    jc ampDone32

ampTake32:            
    xor eax,eax

ampMark32:    
    lock btr ds:[edi],eax     
    jnc ampRetry32
;    
    lock dec ds:[si].phys_bitmap_free
    inc eax
    cmp eax,ecx
    jb ampMark32
;
    mov ax,si
    sub ax,phys_header_start
    movzx eax,ax
    shl eax,13
    mov edx,eax
;    
    mov eax,edi
    and ax,0FFFh
    shl eax,3
    add edx,eax
;    
    mov eax,edx
    mov ebx,edx
    shl eax,12
    shr ebx,20
    clc

ampDone32:
    pop edi
    pop esi
    pop edx
    pop ds
    retf32
allocate_multiple_physical32      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:          GET_PHYSICAL_ENTRY_Type
;
;    DESCRIPTION:   Get physical entry type
;
;    PARAMETERS:    EBX         Entry #
;
;    RETURNS:       NC          OK
;                   EAX         Type
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_physical_entry_type_name  DB 'Get Physical Entry Type',0

get_physical_entry_type   PROC far
    push ds
    push ecx
    push esi
;
    mov ax,system_data_sel
    mov ds,ax
    movzx ecx,ds:multiboot_size
    mov ds,ds:multiboot_sel
;
    or cx,cx
    jz gpetFail
;
    xor esi,esi    
    or bx,bx
    jz gpetFound

gpetLoop:
    mov eax,ds:[esi].mmap_len
    add eax,4
    add esi,eax
    cmp esi,ecx
    je gpetFail
;
    sub bx,1
    jnz gpetLoop

gpetFound:
    mov eax,ds:[esi].mmap_type
    clc
    jmp gpetDone
    
gpetFail:
    stc

gpetDone:            
    pop esi
    pop ecx
    pop ds
    retf32
get_physical_entry_type   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:          GET_PHYSICAL_ENTRY_BASE
;
;    DESCRIPTION:   Get physical entry base
;
;    PARAMETERS:    EBX         Entry #
;
;    RETURNS:       NC          OK
;                   EDX:EAX     Base
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_physical_entry_base_name  DB 'Get Physical Entry Base',0

get_physical_entry_base   PROC far
    push ds
    push ecx
    push esi
;
    mov ax,system_data_sel
    mov ds,ax
    movzx ecx,ds:multiboot_size
    mov ds,ds:multiboot_sel
;
    or cx,cx
    jz gpebFail
;
    xor esi,esi    
    or bx,bx
    jz gpebFound

gpebLoop:
    mov eax,ds:[esi].mmap_len
    add eax,4
    add esi,eax
    cmp esi,ecx
    je gpebFail
;
    sub bx,1
    jnz gpebLoop

gpebFound:
    mov eax,ds:[esi].mmap_base
    mov ebx,ds:[esi].mmap_base+4
    clc
    jmp gpebDone
    
gpebFail:
    stc

gpebDone:            
    pop esi
    pop ecx
    pop ds
    retf32
get_physical_entry_base   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:          GET_PHYSICAL_ENTRY_Size
;
;    DESCRIPTION:   Get physical entry size
;
;    PARAMETERS:    EBX         Entry #
;
;    RETURNS:       NC          OK
;                   EDX:EAX     Size
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_physical_entry_size_name  DB 'Get Physical Entry Size',0

get_physical_entry_size   PROC far
    push ds
    push ecx
    push esi
;
    mov ax,system_data_sel
    mov ds,ax
    movzx ecx,ds:multiboot_size
    mov ds,ds:multiboot_sel
;
    or cx,cx
    jz gpesFail
;
    xor esi,esi    
    or bx,bx
    jz gpesFound

gpesLoop:
    mov eax,ds:[esi].mmap_len
    add eax,4
    add esi,eax
    cmp esi,ecx
    je gpesFail
;
    sub bx,1
    jnz gpesLoop

gpesFound:
    mov eax,ds:[esi].mmap_size
    mov ebx,ds:[esi].mmap_size+4
    clc
    jmp gpesDone
    
gpesFail:
    stc

gpesDone:            
    pop esi
    pop ecx
    pop ds
    retf32
get_physical_entry_size   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GET_FREE_PHYSICAL_MEM
;
;           DESCRIPTION:    Get free physical memory
;
;           PARAMETERS:     EDX:EAX         # of free bytes
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_physical_name  DB 'Get Free Physical Memory',0

get_free_physical_mem   PROC far
    push ds
    push ecx
    push esi
    push edi
;
    mov ax,phys_bit_sel
    mov ds,ax
;
    xor eax,eax
    xor edx,edx
;    
    mov si,phys_header_start
    mov cx,ds:phys_bitmap_count

gfpLoop:
    movzx edi,ds:[si].phys_bitmap_free
    shl edi,12
    add eax,edi
    adc edx,0
;
    add si,4
    loop gfpLoop
;    
    pop edi
    pop esi
    pop ecx
    pop ds
    retf32
get_free_physical_mem   ENDP
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddPhys
;
;       DESCRIPTION:    Add physical entry
;
;       PARAMETERS:     EBX:EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPhys   Proc near
    push ds
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    mov cx,phys_bit_sel
    mov ds,cx
;
    mov ecx,ebx
    shl ecx,20
    mov esi,eax
    shr esi,12
    add ecx,esi
    mov ebx,ecx
    shr ebx,15
    and ecx,7FFFh

apRetry:
    cmp bx,ds:phys_bitmap_count
    jb apDo
;
    push es
    push ecx
;    
    mov ax,ds
    mov es,ax
;
    movzx edi,ds:phys_bitmap_count
    shl edi,2
    add edi,phys_header_start
    mov ds:[edi].phys_bitmap_pos,0
    mov ds:[edi].phys_bitmap_free,0
;    
    movzx edi,ds:phys_bitmap_count
    shl edi,12
    add edi,phys_bitmap_start
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;    
    inc ds:phys_bitmap_count
;    
    pop ecx
    pop es
    jmp apRetry
    
apDo:
    mov edi,ebx
    shl edi,12
    add edi,phys_bitmap_start
    lock bts ds:[edi],ecx
;
    shl ebx,2
    add ebx,phys_header_start
    lock inc ds:[ebx].phys_bitmap_free
;
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AddPhys Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FillupPhysicalMem
;
;           DESCRIPTION:    Fillup physical mem structure 
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fillup_physical_mem   Proc near
    push eax
    push ebx
    push esi

fillup_phys_mem_loop:
    mov eax,cr0
    and eax,NOT 80000000h
    mov cr0,eax    
;
    call AllocateRam
    jc fillup_phys_mem_done
;
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax    
;
    xor ebx,ebx
    mov eax,esi
    call AddPhys
    jmp fillup_phys_mem_loop

fillup_phys_mem_done:
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax    
;
    pop esi
    pop ebx
    pop eax
    ret
fillup_physical_mem   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddRegion
;
;   DESCRIPTION:    Add a region of physical memory
;
;   PARAMETERS:     ESI     Memory block
;                   EBP     Low limit
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddRegion   Proc near
    mov eax,[esi].mmap_base
    mov ebx,[esi].mmap_base+4
;
    dec eax
    and ax,0F000h
    add eax,1000h
;
    mov ecx,[esi].mmap_base
    sub ecx,eax
;
    mov edx,[esi].mmap_size
    mov edi,[esi].mmap_size+4
    sub edx,ecx
    and dx,0F000h
;
    mov ecx,cr0
    or ecx,80000000h
    mov cr0,ecx    
;
    or ebx,ebx
    jnz arLoop
;
    cmp eax,ebp
    jae arLoop
;
    mov ecx,ebp
    sub ecx,eax
;
    sub edx,ecx
    sbb edi,0
    mov eax,ebp

arLoop:
    mov ecx,edx
    or ecx,edi
    jz arDone

    call AddPhys
;
    add eax,1000h
    adc ebx,0
;
    sub edx,1000h
    sbb edi,0
    jmp arLoop

arDone:
    ret
AddRegion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           RemoveRomImage
;
;   DESCRIPTION:    Remove rom image
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveRomImage  Proc near
    push ds
    push es
;    
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov es,ax
;
    movzx ecx,es:multiboot_mmap_len
    mov edx,es:multiboot_mmap_addr
;    
    xor ebx,ebx

rriLoop:    
    mov eax,ds:[edx+ebx].mmap_base+4
    or eax,eax
    jnz rriNext
;    
    mov eax,ds:[edx+ebx].mmap_base
    cmp eax,es:rom1_base
    ja rriNext
;
    add eax,ds:[edx+ebx].mmap_size
    cmp eax,es:rom1_base
    jbe rriNext
;
    mov eax,ds:[edx+ebx].mmap_base
    mov ds:[edx+ecx].mmap_base,eax
    mov eax,ds:[edx+ebx].mmap_base+4
    mov ds:[edx+ecx].mmap_base+4,eax
    mov eax,ds:[edx+ebx].mmap_type
    mov ds:[edx+ecx].mmap_type,eax
    mov ds:[edx+ecx].mmap_len,20
;
    mov eax,es:rom1_base
    add eax,es:rom1_size
    sub eax,ds:[edx+ebx].mmap_base
    add ds:[edx+ebx].mmap_base,eax
    sub ds:[edx+ebx].mmap_size,eax
;
    mov eax,es:rom1_base
    sub eax,ds:[edx+ecx].mmap_base
    mov ds:[edx+ecx].mmap_size,eax
    mov ds:[edx+ecx].mmap_size+4,0
;    
    add ecx,20 + 4
    
rriNext:
    mov eax,ds:[edx+ebx].mmap_len
    add eax,4
    add ebx,eax
    cmp ebx,ecx
    jnz rriLoop
;    
    mov es:multiboot_mmap_len,cx
;
    pop es
    pop ds    
    ret
RemoveRomImage  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           RemoveLongImage
;
;   DESCRIPTION:    Remove long image
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveLongImage  Proc near
    push ds
    push es
;    
    mov ax,flat_sel
    mov ds,ax
    mov ax,system_data_sel
    mov es,ax
;
    movzx ecx,es:multiboot_mmap_len
    mov edx,es:multiboot_mmap_addr
;    
    xor ebx,ebx

rliLoop:    
    mov eax,ds:[edx+ebx].mmap_base+4
    or eax,eax
    jnz rliNext
;    
    mov eax,ds:[edx+ebx].mmap_base
    cmp eax,es:long_base
    ja rliNext
;
    add eax,ds:[edx+ebx].mmap_size
    cmp eax,es:long_base
    jbe rliNext
;
    mov eax,ds:[edx+ebx].mmap_base
    mov ds:[edx+ecx].mmap_base,eax
    mov eax,ds:[edx+ebx].mmap_base+4
    mov ds:[edx+ecx].mmap_base+4,eax
    mov eax,ds:[edx+ebx].mmap_type
    mov ds:[edx+ecx].mmap_type,eax
    mov ds:[edx+ecx].mmap_len,20
;
    mov eax,es:long_base
    add eax,es:long_size
    sub eax,ds:[edx+ebx].mmap_base
    add ds:[edx+ebx].mmap_base,eax
    sub ds:[edx+ebx].mmap_size,eax
;
    mov eax,es:long_base
    sub eax,ds:[edx+ecx].mmap_base
    mov ds:[edx+ecx].mmap_size,eax
    mov ds:[edx+ecx].mmap_size+4,0
;    
    add ecx,20 + 4
    
rliNext:
    mov eax,ds:[edx+ebx].mmap_len
    add eax,4
    add ebx,eax
    cmp ebx,ecx
    jnz rliLoop
;    
    mov es:multiboot_mmap_len,cx
;
    pop es
    pop ds    
    ret
RemoveLongImage  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_PHYSICAL
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_physical

init_physical   PROC near
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:ram2_size
    or eax,eax
    jz init_phys_multiboot
;
    call fillup_physical_mem
    jmp init_phys_done

init_phys_multiboot:    
    mov eax,cr0
    and eax,NOT 80000000h
    mov cr0,eax    
    call RemoveRomImage
    mov eax,ds:long_size
    or eax,eax
    jz init_phys_long_ok
;
    call RemoveLongImage
        
init_phys_long_ok:
    movzx ecx,ds:multiboot_mmap_len
    mov esi,ds:multiboot_mmap_addr
    mov ebp,ds:alloc_base
    add ebp,1000h
    mov ax,flat_sel
    mov ds,ax

init_phys_loop:
    mov eax,[esi].mmap_type
    cmp eax,1
    jne init_phys_next
;    
    push ecx
    push esi
    call AddRegion
    pop esi
    pop ecx
;
    mov eax,cr0
    and eax,NOT 80000000h
    mov cr0,eax    

init_phys_next:
    mov eax,[esi].mmap_len
    add eax,4
    add esi,eax
    sub ecx,eax
    jnz init_phys_loop

init_phys_done:                    
    mov eax,cr0
    or eax,80000000h
    mov cr0,eax    
    ret
init_physical   ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_PHYSICAL_GATES
;
;           DESCRIPTION:    Init module syscalls
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_physical_gates

init_physical_gates     PROC near
    pusha
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_physical_entry_type
    mov edi,OFFSET get_physical_entry_type_name
    xor dx,dx
    mov ax,get_physical_entry_type_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_physical_entry_base
    mov edi,OFFSET get_physical_entry_base_name
    xor dx,dx
    mov ax,get_physical_entry_base_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_physical_entry_size
    mov edi,OFFSET get_physical_entry_size_name
    xor dx,dx
    mov ax,get_physical_entry_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_free_physical_mem
    mov edi,OFFSET get_free_physical_name
    xor dx,dx
    mov ax,get_free_physical_nr
    RegisterBimodalUserGate
;       
    mov esi,OFFSET free_physical
    mov edi,OFFSET free_physical_name
    xor cl,cl
    mov ax,free_physical_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_physical32
    mov edi,OFFSET allocate_physical32_name
    xor cl,cl
    mov ax,allocate_physical32_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_physical64
    mov edi,OFFSET allocate_physical64_name
    xor cl,cl
    mov ax,allocate_physical64_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_dma_physical
    mov edi,OFFSET allocate_dma_physical_name
    xor cl,cl
    mov ax,allocate_dma_physical_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_multiple_physical32
    mov edi,OFFSET allocate_multiple_physical32_name
    xor cl,cl
    mov ax,allocate_multiple_physical32_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_multiple_physical32
    mov edi,OFFSET allocate_multiple_physical32_name
    xor cl,cl
    mov ax,allocate_multiple_physical64_nr
    RegisterOsGate
;    
    pop ds
    popa
    ret
init_physical_gates     ENDP

code    ENDS

    END

