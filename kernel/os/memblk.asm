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

MEM_BLK_BASE_SIGN     = 0B45Ah
MEM_BLK_EXTEND_SIGN   = 0A56Ah

LARGE_ENTRIES = 256

mem_blk_info	STRUC

mblk_bitmap_offset   DW ?
mblk_data_offset     DW ?
mblk_bitmap_dd_count DW ?
mblk_free_bits       DW ?
mblk_size_shift      DB ?
mblk_is64            DB ?
mblk_large_sel       DW ?
mblk_ext_count       DW ?
mblk_ext_size        DW ?
mblk_ext_arr         DW ?

mem_blk_info	ENDS

mem_blk_extend	STRUC

mblke_header          mem_blk_header <>

mblke_bitmap_offset   DW ?
mblke_data_offset     DW ?
mblke_bitmap_dd_count DW ?
mblke_free_bits       DW ?
mblke_size_shift      DB ?
mblke_pad             DB ?

mem_blk_extend	ENDS

mem_blk_large   STRUC

mblkl_physical_base   DD ?,?
mblkl_linear_base     DD ?
mblkl_size            DD ?

mem_blk_large   ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateLargeSel
;
;   DESCRIPTION:    Create and return large selector
;
;   PARAMETERS:     ES      Memory block selector
;
;   RETURNS:        DS      Large sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateLargeSel     Proc near
    push eax
    push ebx
    push esi
;
    mov si,es:mblk_info_offset
    mov bx,es:[si].mblk_large_sel
    or bx,bx
    jnz clsDone
;
    push es
    push eax
    push ecx
    push edi
;
    mov eax,1000h
    AllocateGlobalMem
    mov ecx,400h
    xor edi,edi
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov bx,es
;
    pop edi
    pop ecx
    pop eax
    pop es
;
    mov ax,es:[si].mblk_large_sel
    or ax,ax
    jz clsExchange
;
    push es
    mov es,ax
    FreeMem
    pop es
    jmp clsDone

clsExchange:
    xchg bx,es:[si].mblk_large_sel
    or bx,bx
    jz clsDone
;
    push es
    push bx
;
    xchg bx,es:[si].mblk_large_sel
    mov es,bx
    FreeMem
;
    pop bx
    pop es

clsDone:
    mov ds,es:[si].mblk_large_sel
;
    pop esi
    pop ebx
    pop eax
    ret
CreateLargeSel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateLargeBlock
;
;   DESCRIPTION:    Allocate large block
;
;   PARAMETERS:     ES      Memory block selector
;                   CX      Size
;
;   RETURNS:        ECX     Block size
;                   EDX     Linear address
;                   EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateLargeBlock  Proc near
    push esi
;
    movzx ecx,cx
    dec ecx
    and ecx,0F000h
    add ecx,1000h
;
    mov eax,ecx
    AllocateBigLinear
;
    cmp ecx,1
    je albOne

albMulti:
    mov si,es:mblk_info_offset
    mov al,es:[si].mblk_is64
    or al,al
    jnz albm64
;
    AllocateMultiplePhysical32
    jmp albmPaging

albm64:
    AllocateMultiplePhysical64

albmPaging:
    push eax
    push ecx
    push edx
;
    mov al,13h

albmPageLoop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    loop albmPageLoop
;
    pop edx
    pop ecx
    pop eax
    jmp albDone

albOne:
    mov si,es:mblk_info_offset
    mov al,es:[si].mblk_is64
    or al,al
    jnz albo64
;
    AllocatePhysical32
    jmp alboPaging

albo64:
    AllocatePhysical64

alboPaging:
    mov al,13h
    SetPageEntry
    xor al,al

albDone:
    shl ecx,12
;
    pop esi
    ret
AllocateLargeBlock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateEntry
;
;   DESCRIPTION:    Allocate new entry
;
;   PARAMETERS:     ES      Memory block selector
;
;   RETURNS:        DS:SI   Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateEntry  Proc near
    push eax
    push ecx
;
    call CreateLargeSel
;
    xor si,si
    mov cx,LARGE_ENTRIES

aleLoop:
    mov eax,ds:[si].mblkl_size
    or eax,eax
    jnz aleNext
;
    mov eax,1
    xchg eax,ds:[si].mblkl_size
    cmp eax,1
    je aleNext
;
    or eax,eax
    clc
    jz aleDone
;
    mov ds:[si].mblkl_size,eax

aleNext:    
    add si,SIZE mem_blk_large
    loop aleLoop
;
    stc

aleDone:
    pop ecx
    pop eax
    ret
AllocateEntry  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeEntry
;
;   DESCRIPTION:    Free large entry
;
;   PARAMETERS:     DS:SI   Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeEntry  Proc near
    push ecx
    push edx
;
    xor ecx,ecx
    xchg ecx,ds:[si].mblkl_size
;
    xor edx,edx
    xchg edx,ds:[si].mblkl_linear_base
;
    mov ds:[si].mblkl_physical_base,0
    mov ds:[si].mblkl_physical_base+4,0
;
    FreeLinear
;
    pop edx
    pop ecx
    ret
FreeEntry  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FindPhysical
;
;   DESCRIPTION:    Find large entry based on physical address
;
;   PARAMETERS:     ES      Memory block selector
;                   EBX:EAX Physical address
;
;   RETURNS:        DS:SI   Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindPhysical  Proc near
    mov si,es:mblk_info_offset
    mov si,es:[si].mblk_large_sel
    or si,si
    stc
    jz fpeDone
;
    push ecx
    push edx
    push edi
;
    mov ds,si
    xor si,si
    mov cx,LARGE_ENTRIES

fpeLoop:
    mov edx,ds:[si].mblkl_size
    or edx,edx
    jz fpeNext
;
    mov edx,eax
    sub edx,ds:[si].mblkl_physical_base
    jc fpeNext
;
    mov edi,ebx
    sbb edi,ds:[si].mblkl_physical_base+4
    jnz fpeNext
;
    cmp edx,ds:[si].mblkl_size
    ja fpeNext
;
    pop edi
    pop edx
    pop ecx
    clc
    jmp fpeDone

fpeNext:
    add si,SIZE mem_blk_large
    loop fpeLoop
;
    pop edi
    pop edx
    pop ecx
    stc

fpeDone:
    ret
FindPhysical  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FindLinear
;
;   DESCRIPTION:    Find large entry based on linear address
;
;   PARAMETERS:     ES      Memory block selector
;                   EDX     Linear address
;
;   RETURNS:        DS:SI   Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindLinear  Proc near
    mov si,es:mblk_info_offset
    mov si,es:[si].mblk_large_sel
    or si,si
    stc
    jz fleDone
;
    push eax
    push ecx
;
    mov ds,si
    xor si,si
    mov cx,LARGE_ENTRIES

fleLoop:
    mov eax,ds:[si].mblkl_size
    or eax,eax
    jz fleNext
;
    mov eax,edx
    sub eax,ds:[si].mblkl_linear_base
    jc fleNext
;
    cmp eax,ds:[si].mblkl_size
    ja fleNext
;
    pop ecx
    pop eax
    clc
    jmp fleDone

fleNext:
    add si,SIZE mem_blk_large
    loop fleLoop
;
    pop ecx
    pop eax
    stc

fleDone:
    ret
FindLinear  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeLargeSel
;
;   DESCRIPTION:    Free large selector
;
;   PARAMETERS:     ES      Memory block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeLargeSel     Proc near
    push si
;
    mov si,es:mblk_info_offset
    mov si,es:[si].mblk_large_sel
    or si,si
    jz flsDone
;
    push ds
    push eax
    push ecx
;
    mov ds,si
    xor si,si
    mov cx,LARGE_ENTRIES

flsLoop:
    mov eax,ds:[si].mblkl_size
    or eax,eax
    jz flsNext
;
    call FreeEntry

flsNext:
    add si,SIZE mem_blk_large
    loop flsLoop
;
    pop ecx
    pop eax
;
   mov si,ds
    pop ds
;
    push es
    mov es,si
    FreeMem
    pop es

flsDone:
    pop si
    ret
FreeLargeSel     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateLarge
;
;   DESCRIPTION:    Allocate large block
;
;   PARAMETERS:     ES      Memory block selector
;                   CX      Size
;
;   RETURNS:        EDX     Linear address
;                   EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateLarge  Proc near
    push ds
    push si
;
    call AllocateEntry
    jc alDone
;
    push ecx
    call AllocateLargeBlock
    mov ds:[si].mblkl_physical_base,eax
    mov ds:[si].mblkl_physical_base+4,ebx
    mov ds:[si].mblkl_linear_base,edx
    mov ds:[si].mblkl_size,ecx
    pop ecx
    clc

alDone:
    pop si
    pop ds
    ret
AllocateLarge  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreePhysicalLarge
;
;   DESCRIPTION:    Free mem block based on physical address
;
;   PARAMETERS:     ES      Memory block selector
;                   EBX:EAX Physical address
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePhysicalLarge  Proc near
    push ds
    push si
;
    call FindPhysical
    jc fplDone
;
    call FreeEntry

fplDone:
    pop si
    pop ds
    ret
FreePhysicalLarge  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeLinearLarge
;
;   DESCRIPTION:    Free mem block based on linear address
;
;   PARAMETERS:     ES      Memory block selector
;                   EDX     Linear address
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeLinearLarge  Proc near
    push ds
    push si
;
    call FindLinear
    jc fllDone
;
    call FreeEntry

fllDone:
    pop si
    pop ds
    ret
FreeLinearLarge  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           PhysicalToLinearLarge
;
;   DESCRIPTION:    Convert between physical and linear address
;
;   PARAMETERS:     ES      Memory block selector
;                   EBX:EAX Physical address
;
;   RETURNS:        EDX     Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PhysicalToLinearLarge  Proc near
    push ds
    push si
;
    call FindPhysical
    jc ptllDone
;
    mov edx,eax
    sub edx,ds:[si].mblkl_physical_base
    add edx,ds:[si].mblkl_linear_base
    clc

ptllDone:
    pop si
    pop ds
    ret
PhysicalToLinearLarge  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           LinearToPhysicalLarge
;
;   DESCRIPTION:    Convert between linear and physical address
;
;   PARAMETERS:     ES      Memory block selector
;                   EDX     Linear address
;
;   RETURNS:        EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinearToPhysicalLarge  Proc near
    push ds
    push si
;
    call FindLinear
    jc ltplDone
;
    mov eax,edx
    sub eax,ds:[si].mblkl_linear_base
    add eax,ds:[si].mblkl_physical_base
    mov ebx,ds:[si].mblkl_physical_base+4
    clc

ltplDone:
    pop si
    pop ds
    ret
LinearToPhysicalLarge  Endp

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

CreateBlock     Proc near
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
    mov al,13h
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
CreateBlock     Endp

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
    mov es:mblk_sign,MEM_BLK_BASE_SIGN
;
    test si,1
    jz ibStartOk
;
    inc si

ibStartOk:
    mov es:mblk_info_offset,si
    mov es:[si].mblk_ext_size,cx
    mov es:[si].mblk_ext_count,0
    mov es:[si].mblk_large_sel,0
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
    mov es:[si].mblk_bitmap_dd_count,ax
;
    mov ax,es:[si].mblk_ext_size
    add ax,ax
    add ax,es:[si].mblk_bitmap_dd_count
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
    mov es:[si].mblk_bitmap_dd_count,ax
;
    mov bx,es:[si].mblk_data_offset
    sub bx,ax
    mov es:[si].mblk_bitmap_offset,bx
;
    mov bx,es:[si].mblk_free_bits
    mov cl,3
    shr bx,cl
    mov ax,es:[si].mblk_bitmap_dd_count
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
    mov ax,es:[si].mblk_bitmap_dd_count
    shr ax,2
    mov es:[si].mblk_bitmap_dd_count,ax
;
    popa
    ret
InitBlock     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           InitExtend
;
;   DESCRIPTION:    Init extended memory block
;
;   PARAMETERS:     ES      Memory block selector
;                   CL      Size shift
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitExtend     Proc near
    pusha
;
    mov es:mblk_sign,MEM_BLK_EXTEND_SIGN
    mov es:mblke_size_shift,cl
;
    mov bx,SIZE mem_blk_extend
    mov ax,1000h
    sub ax,bx
    shr ax,cl
    mov es:mblke_free_bits,ax
    dec ax
    shr ax,3
    inc ax
    mov es:mblke_bitmap_dd_count,ax
;
    add ax,SIZE mem_blk_extend
    dec ax
    mov cl,es:mblke_size_shift
    add cl,3
    shr ax,cl
    inc ax
    shl ax,cl
    mov es:mblke_data_offset,ax
;
    mov bx,ax
    mov ax,1000h
    sub ax,bx
    mov cl,es:mblke_size_shift
    shr ax,cl    
    mov es:mblke_free_bits,ax
    dec ax
    shr ax,5
    inc ax
    shl ax,2
    mov es:mblke_bitmap_dd_count,ax
;
    mov bx,es:mblke_data_offset
    sub bx,ax
    mov es:mblke_bitmap_offset,bx
;
    mov bx,es:mblke_free_bits
    mov cl,3
    shr bx,cl
    mov ax,es:mblke_bitmap_dd_count
    sub ax,bx
    jz ieDone
;
    mov dl,-1
    mov bx,es:mblke_data_offset

iePadLoop:
    dec bx
    mov es:[bx],dl
    sub ax,1
    jnz iePadLoop
    
ieDone:
    mov ax,es:mblke_bitmap_dd_count
    shr ax,2
    mov es:mblke_bitmap_dd_count,ax
;
    popa
    ret
InitExtend     Endp    

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
    push esi
;
    AllocatePhysical32
    call CreateBlock
;
    pop esi
    pop ebx
    pop eax
;
    call InitBlock
    push si
    mov si,es:mblk_info_offset
    mov es:[si].mblk_is64,0
    pop si
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
    push esi
;
    AllocatePhysical64
    call CreateBlock
;
    pop esi
    pop ebx
    pop eax
;
    call InitBlock
    push si
    mov si,es:mblk_info_offset
    mov es:[si].mblk_is64,1
    pop si
    retf32
create_mem_blk64     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeMemBlk
;
;   DESCRIPTION:    Free memory block
;
;   PARAMETERS:     ES      Memory block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_mem_blk_name    DB 'Free Mem Blk', 0

free_mem_blk     Proc far
    push eax
    push ecx
    push esi
;
    mov ax,es:mblk_sign
    cmp ax,MEM_BLK_BASE_SIGN
    je fmbSignOk
;
    int 3
    stc
    jmp fmbDone

fmbSignOk:
    call FreeLargeSel
    mov si,es:mblk_info_offset
    mov cx,es:[si].mblk_ext_size
    lea si,[si].mblk_ext_arr

fmbLoop:
    mov ax,es:[si]
    or ax,ax
    je fmbNext
;
    cmp ax,-1
    je fmbNext
;
    push es
    mov es,ax
    FreeMem
    pop es

fmbNext:
    add si,2
    loop fmbLoop
;
    FreeMem
    clc

fmbDone:
    pop esi
    pop ecx
    pop eax    
    retf32
free_mem_blk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateExtend
;
;   DESCRIPTION:    Create extend memory block selector
;
;   PARAMETERS:     ES      Memory block selector
;
;   RETURNS:        AX      Extended memory block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateExtend     Proc near
    push es
    push ebx
    push ecx
    push esi
;
    mov si,es:mblk_info_offset
    mov cl,es:[si].mblk_size_shift
;
    mov al,es:[si].mblk_is64
    or al,al
    jnz ce64
;
    AllocatePhysical32
    call CreateBlock
    jmp ceInit

ce64:
    AllocatePhysical64
    call CreateBlock

ceInit:
    call InitExtend
    mov ax,es
;
    pop esi
    pop ecx
    pop ebx
    pop es
    ret
CreateExtend     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBit1
;
;   DESCRIPTION:    Allocate single bit block
;
;   PARAMETERS:     ES      Memory block selector
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBit1    Proc near
    push eax
    push ecx
    push edx
;
    mov bx,es:[si].mblk_bitmap_offset
    mov cx,es:[si].mblk_bitmap_dd_count
    xor dx,dx

abLoop1:
    mov eax,es:[bx]
    cmp eax,-1
    je abNext1
;
    push ecx
    not eax
    bsf ecx,eax
;
    add cx,dx
    mov bx,es:[si].mblk_bitmap_offset
    lock bts es:[bx],cx
    mov bx,cx
    pop ecx
    jc abLoop1
    jmp abDone1

abNext1:
    add dx,32
    add bx,4
    loop abLoop1
;
    stc

abDone1:
    pop edx
    pop ecx
    pop eax
    ret
AllocateBit1    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBit2
;
;   DESCRIPTION:    Allocate a two bit block
;
;   PARAMETERS:     ES      Memory block selector
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBit2    Proc near
    push eax
    push ecx
    push edx
    push ebp
;
    mov bx,es:[si].mblk_bitmap_offset
    mov cx,es:[si].mblk_bitmap_dd_count
    xor dx,dx

abLoop2:
    mov eax,es:[bx]
    cmp eax,-1
    je abNext2
;
    xor bp,bp

abBitLoop2:
    rcr eax,1
    jc abSkip2
;
    rcr eax,1
    jc abBitNext2
;
    add bp,dx
    mov ax,bp
    mov bx,es:[si].mblk_bitmap_offset
    lock bts es:[bx],ax
    jc abLoop2
;
    inc ax
    lock bts es:[bx],ax
    jc abBitRevert2
;
    mov bx,bp
    clc
    jmp abDone2

abBitRevert2:
    dec ax
    lock btr es:[bx],ax
    jmp abLoop2

abSkip2:
    rcr eax,1

abBitNext2:
    add bp,2
    cmp bp,32
    jne abBitLoop2

abNext2:
    add dx,32
    add bx,4
    loop abLoop2
;
    stc

abDone2:
    pop ebp
    pop edx
    pop ecx
    pop eax
    ret
AllocateBit2    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBit4
;
;   DESCRIPTION:    Allocate a four bit block
;
;   PARAMETERS:     ES      Memory block selector
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBit4    Proc near
    push eax
    push ecx
    push edx
    push ebp
;
    mov bx,es:[si].mblk_bitmap_offset
    mov cx,es:[si].mblk_bitmap_dd_count
    xor dx,dx

abLoop4:
    mov eax,es:[bx]
    cmp eax,-1
    je abNext4
;
    xor bp,bp

abBitLoop4:
    rcr eax,1
    jc abSkip43
;
    rcr eax,1
    jc abSkip42
;
    rcr eax,1
    jc abSkip41
;
    rcr eax,1
    jc abBitNext4
;
    add bp,dx
    mov ax,bp
    mov bx,es:[si].mblk_bitmap_offset
    lock bts es:[bx],ax
    jc abLoop4
;
    inc ax
    lock bts es:[bx],ax
    jc abBitRevert41
;
    inc ax
    lock bts es:[bx],ax
    jc abBitRevert42
;
    inc ax
    lock bts es:[bx],ax
    jc abBitRevert43
;
    mov bx,bp
    clc
    jmp abDone4

abBitRevert43:
    dec ax
    lock btr es:[bx],ax

abBitRevert42:
    dec ax
    lock btr es:[bx],ax

abBitRevert41:
    dec ax
    lock btr es:[bx],ax
    jmp abLoop4

abSkip43:
    rcr eax,1

abSkip42:
    rcr eax,1

abSkip41:
    rcr eax,1

abBitNext4:
    add bp,4
    cmp bp,32
    jne abBitLoop4

abNext4:
    add dx,32
    add bx,4
    loop abLoop4
;
    stc

abDone4:
    pop ebp
    pop edx
    pop ecx
    pop eax
    ret
AllocateBit4    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateByte
;
;   DESCRIPTION:    Allocate byte block
;
;   PARAMETERS:     ES      Memory block selector
;                   AX      Byte count
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateByte    Proc near
    push eax
    push ecx
    push edx
    push ebp    
;
    mov bp,ax
    mov bx,es:[si].mblk_bitmap_offset
    mov cx,es:[si].mblk_bitmap_dd_count
    shl cx,2
    mov dx,bp

abtCheck:
    mov al,es:[bx]
    or al,al
    jnz abtNext
;
    sub dx,1
    jz abtTake
;
    inc bx
    loop abtCheck
;
    stc
    jmp abtDone

abtTake:
    mov al,-1
    xchg al,es:[bx]
    cmp al,-1
    je abtRevert
;
    or al,al
    jne abtRestore
;
    inc dx
    cmp dx,bp
    je abtTaken
;
    dec bx
    jmp abtTake

abtTaken:
    sub bx,es:[si].mblk_bitmap_offset
    shl bx,3
    clc
    jmp abtDone

abtRestore:
    mov es:[bx],al

abtRevert:
    or dx,dx
    jz abtNext
;
    inc bx
    dec dx
    xor al,al
    mov es:[bx],al
    jmp abtRevert

abtNext:
    inc bx    
    mov dx,bp
    sub cx,1
    jnz abtCheck
;
    stc

abtDone:
    pop ebp
    pop edx
    pop ecx
    pop eax
    ret
AllocateByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateExtendBit1
;
;   DESCRIPTION:    Allocate single bit block
;
;   PARAMETERS:     ES          Extended memory block selector
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtendBit1      Proc near
    push eax
    push ecx
    push edx
;
    mov bx,es:mblke_bitmap_offset
    mov cx,es:mblke_bitmap_dd_count
    xor dx,dx

aebLoop1:
    mov eax,es:[bx]
    cmp eax,-1
    je aebNext1
;
    push ecx
    not eax
    bsf ecx,eax
;    
    add cx,dx
    mov bx,es:mblke_bitmap_offset
    lock bts es:[bx],cx
    mov bx,cx
    pop ecx
    jc aebLoop1
    jmp aebDone1

aebNext1:
    add dx,32
    add bx,4
    loop aebLoop1
;
    stc

aebDone1:
    pop edx
    pop ecx
    pop eax
    ret
AllocateExtendBit1      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateExtendBit2
;
;   DESCRIPTION:    Allocate a two bit block
;
;   PARAMETERS:     ES      Extended memory block selector
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtendBit2      Proc near
    push eax
    push ecx
    push edx
    push ebp
;
    mov bx,es:mblke_bitmap_offset
    mov cx,es:mblke_bitmap_dd_count
    xor dx,dx

aebLoop2:
    mov eax,es:[bx]
    cmp eax,-1
    je aebNext2
;
    xor bp,bp

aebBitLoop2:
    rcr eax,1
    jc aebSkip2
;
    rcr eax,1
    jc aebBitNext2
;
    add bp,dx
    mov ax,bp
    mov bx,es:mblke_bitmap_offset
    lock bts es:[bx],ax
    jc aebLoop2
;
    inc ax
    lock bts es:[bx],ax
    jc aebRevert2
;
    mov bx,bp
    clc
    jmp aebDone2

aebRevert2:
    dec ax
    lock btr es:[bx],ax
    jmp aebLoop2

aebSkip2:
    rcr eax,1

aebBitNext2:
    add bp,2
    cmp bp,32
    jne aebBitLoop2

aebNext2:
    add dx,32
    add bx,4
    loop aebLoop2
;
    stc

aebDone2:
    pop ebp
    pop edx
    pop ecx
    pop eax
    ret
AllocateExtendBit2      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateExtendBit4
;
;   DESCRIPTION:    Allocate a four bit block
;
;   PARAMETERS:     ES      Extended memory block selector
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtendBit4    Proc near
    push eax
    push ecx
    push edx
    push ebp
;
    mov bx,es:mblke_bitmap_offset
    mov cx,es:mblke_bitmap_dd_count
    xor dx,dx

aebLoop4:
    mov eax,es:[bx]
    cmp eax,-1
    je aebNext4
;
    xor bp,bp

aebBitLoop4:
    rcr eax,1
    jc aebSkip43
;
    rcr eax,1
    jc aebSkip42
;
    rcr eax,1
    jc aebSkip41
;
    rcr eax,1
    jc aebBitNext4
;
    add bp,dx
    mov ax,bp
    mov bx,es:mblke_bitmap_offset
    lock bts es:[bx],ax
    jc aebLoop4
;
    inc ax
    lock bts es:[bx],ax
    jc aebBitRevert41
;
    inc ax
    lock bts es:[bx],ax
    jc aebBitRevert42
;
    inc ax
    lock bts es:[bx],ax
    jc aebBitRevert43
;
    mov bx,bp
    clc
    jmp aebDone4

aebBitRevert43:
    dec ax
    lock btr es:[bx],ax

aebBitRevert42:
    dec ax
    lock btr es:[bx],ax

aebBitRevert41:
    dec ax
    lock btr es:[bx],ax
    jmp abLoop4

aebSkip43:
    rcr eax,1

aebSkip42:
    rcr eax,1

aebSkip41:
    rcr eax,1

aebBitNext4:
    add bp,4
    cmp bp,32
    jne aebBitLoop4

aebNext4:
    add dx,32
    add bx,4
    loop aebLoop4
;
    stc

aebDone4:
    pop ebp
    pop edx
    pop ecx
    pop eax
    ret
AllocateExtendBit4    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateExtendByte
;
;   DESCRIPTION:    Allocate byte block
;
;   PARAMETERS:     ES      Extended memory block selector
;                   AX      Byte count
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtendByte    Proc near
    push eax
    push ecx
    push edx
    push ebp    
;
    mov bp,ax
    mov bx,es:mblke_bitmap_offset
    mov cx,es:mblke_bitmap_dd_count
    shl cx,2
    mov dx,bp

aebtCheck:
    mov al,es:[bx]
    or al,al
    jnz aebtNext
;
    sub dx,1
    jz aebtTake
;
    inc bx
    loop aebtCheck
;
    stc
    jmp aebtDone

aebtTake:
    mov al,-1
    xchg al,es:[bx]
    cmp al,-1
    je aebtRevert
;
    or al,al
    jne aebtRestore
;
    inc dx
    cmp dx,bp
    je aebtTaken
;
    dec bx
    jmp aebtTake

aebtTaken:
    sub bx,es:mblke_bitmap_offset
    shl bx,3
    clc
    jmp aebtDone

aebtRestore:
    mov es:[bx],al

aebtRevert:
    or dx,dx
    jz aebtNext
;
    inc bx
    dec dx
    xor al,al
    mov es:[bx],al
    jmp aebtRevert

aebtNext:
    inc bx    
    mov dx,bp
    sub cx,1
    jnz aebtCheck
;
    stc

aebtDone:
    pop ebp
    pop edx
    pop ecx
    pop eax
    ret
AllocateExtendByte    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBase
;
;   DESCRIPTION:    Allocate in base block
;
;   PARAMETERS:     ES      Memory block selector
;                   CX      Size
;
;   RETURNS:        EDX     Linear address
;                   EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBase    Proc near
    push ecx
    push esi
;
    mov si,es:mblk_info_offset
;
    mov bx,es:[si].mblk_free_bits
    or bx,bx
    stc
    jz abDone
;
    mov ax,cx
    mov cl,es:[si].mblk_size_shift
    dec ax
    shr ax,cl
    jz ab1
;
    shr ax,1
    jz ab2
;
    shr ax,1
    jz ab4
;
    shr ax,1
    inc ax
    call AllocateByte
    jc abDone
;
    shl ax,3
    lock sub es:[si].mblk_free_bits,ax
    jmp abOk

ab1:
    call AllocateBit1
    jc abDone
;
    lock sub es:[si].mblk_free_bits,1
    jmp abOk

ab2:
    call AllocateBit2
    jc abDone
;
    lock sub es:[si].mblk_free_bits,2
    jmp abOk

ab4:
    call AllocateBit4
    jc abDone
;
    lock sub es:[si].mblk_free_bits,4
    jmp abOk

abOk:
    shl bx,cl
    add bx,es:[si].mblk_data_offset
    movzx ecx,bx
    mov edx,es:mblk_linear_base
    add edx,ecx
    mov eax,es:mblk_physical_base
    add eax,ecx
    mov ebx,es:mblk_physical_base+4
    clc

abDone:
    pop esi
    pop ecx
    ret
AllocateBase    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateExtend
;
;   DESCRIPTION:    Allocate from extended block
;
;   PARAMETERS:     ES      Extended memory block selector
;                   CX      Size
;
;   RETURNS:        EDX     Linear address
;                   EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtend  Proc near
    push ecx
    push esi
;
    mov ax,es:mblk_sign
    cmp ax,MEM_BLK_EXTEND_SIGN
    je aeSignOk
;
    int 3
    stc
    jmp aeDone

aeSignOk:
    mov ax,es:mblke_free_bits
    or ax,ax
    stc
    jz aeDone
;
    mov ax,cx
    mov cl,es:mblke_size_shift
    dec ax
    shr ax,cl
    je ae1
;
    shr ax,1
    jz ae2
;
    shr ax,1
    jz ae4
;
    shr ax,1
    inc ax
    call AllocateExtendByte
    jc aeDone
;
    shl ax,3
    lock sub es:mblke_free_bits,ax
    jmp aeOk

ae1:
    call AllocateExtendBit1
    jc aeDone
;
    lock sub es:mblke_free_bits,1
    jmp aeOk

ae2:
    call AllocateExtendBit2
    jc aeDone
;
    lock sub es:mblke_free_bits,2
    jmp aeOk

ae4:
    call AllocateExtendBit4
    jc aeDone
;
    lock sub es:mblke_free_bits,4
    jmp aeOk

aeOk:
    shl bx,cl
    add bx,es:mblke_data_offset
    movzx ecx,bx
    mov edx,es:mblk_linear_base
    add edx,ecx
    mov eax,es:mblk_physical_base
    add eax,ecx
    mov ebx,es:mblk_physical_base+4
    clc

aeDone:
    pop esi
    pop ecx
    ret
AllocateExtend  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateMemBlk
;
;   DESCRIPTION:    Allocate memory block
;
;   PARAMETERS:     ES      Memory block selector
;                   CX      Size
;
;   RETURNS:        EDX     Linear address
;                   EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem_blk_name    DB 'Allocate Mem Blk', 0

allocate_mem_blk     Proc far
    push ecx
    push esi
    push edi
    push ebp
;
    mov ax,es:mblk_sign
    cmp ax,MEM_BLK_BASE_SIGN
    je ambSignOk
;
    int 3
    stc
    jmp ambDone

ambSignOk:
    cmp cx,0C00h
    jb ambSmall
;
    call AllocateLarge
    jmp ambDone

ambSmall:
    call AllocateBase
    jnc ambDone

ambExtend:
    mov si,es:mblk_info_offset
    mov bp,es:[si].mblk_ext_size
    lea di,[si].mblk_ext_arr

ambExtendLoop:
    mov ax,es:[di]
    cmp ax,-1
    stc
    je ambExtendNext
;
    or ax,ax
    jne ambCheck
;
    mov ax,-1
    xchg ax,es:[di]
    cmp ax,-1
    stc
    je ambExtendNext
;
    or ax,ax
    jz ambAllocate
;
    mov es:[di],ax
    jmp ambCheck

ambAllocate:
    call CreateExtend
    mov es:[di],ax
    lock add es:[si].mblk_ext_count,1

ambCheck:
    push es
    mov es,ax
    call AllocateExtend
    pop es

ambExtendNext:
    jnc ambDone
;
    add di,2
    sub bp,1
    jnz ambExtendLoop
;
    int 3
    stc

ambDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    retf32
allocate_mem_blk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           PhysicalToLinearMemBlk
;
;   DESCRIPTION:    Convert between physical and linear address
;
;   PARAMETERS:     ES      Memory block selector
;                   EBX:EAX Physical address
;
;   RETURNS:        EDX     Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

physical_to_linear_mem_blk_name    DB 'Physical To Linear Mem Blk', 0

physical_to_linear_mem_blk     Proc far
    push es
;
    push eax
;
    and ax,0F000h
    cmp eax,es:mblk_physical_base
    jne ptlCheckExt
;
    cmp ebx,es:mblk_physical_base+4
    je ptlFound

ptlCheckExt:
    push ds
    push ecx
    push esi
    push edi
;
    mov dx,es
    mov ds,dx
;
    mov si,ds:mblk_info_offset
    mov cx,ds:[si].mblk_ext_count
    or cx,cx
    jz ptlLarge
;
    lea di,[si].mblk_ext_arr 

ptlExtLoop:
    mov dx,ds:[di]
    or dx,dx
    jz ptlExtNext
;
    cmp dx,-1
    je ptlExtNext
;
    mov es,dx
;
    cmp eax,es:mblk_physical_base
    jne ptlExtNext
;
    cmp ebx,es:mblk_physical_base+4
    je ptlExtDone

ptlExtNext:
    add di,2
    loop ptlExtLoop

ptlLarge:
    pop edi
    pop esi
    pop ecx
    pop ds
;
    pop eax
;
    call PhysicalToLinearLarge
    jmp ptlDone

ptlExtDone:
    pop edi
    pop esi
    pop ecx
    pop ds

ptlFound:
    pop eax
;
    movzx edx,ax
    and dx,0FFFh
    or edx,es:mblk_linear_base
    clc

ptlDone:
    pop es
    retf32
physical_to_linear_mem_blk     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           LinearToPhysicalMemBlk
;
;   DESCRIPTION:    Convert between linear and physical address
;
;   PARAMETERS:     ES      Memory block selector
;                   EDX     Linear address
;
;   RETURNS:        EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

linear_to_physical_mem_blk_name    DB 'Linear To Physical Mem Blk', 0

linear_to_physical_mem_blk     Proc far
    push es
;
    push edx
;
    and dx,0F000h
    cmp edx,es:mblk_linear_base
    je ltpFound
;
    push ds
    push ecx
    push esi
    push edi
;
    mov ax,es
    mov ds,ax
;
    mov si,ds:mblk_info_offset
    mov cx,ds:[si].mblk_ext_count
    or cx,cx
    jz ltpLarge
;
    lea di,[si].mblk_ext_arr 

ltpExtLoop:
    mov ax,ds:[di]
    or ax,ax
    jz ltpExtNext
;
    cmp ax,-1
    je ltpExtNext
;
    mov es,ax
;
    cmp edx,es:mblk_linear_base
    je ltpExtDone

ltpExtNext:
    add di,2
    loop ltpExtLoop

ltpLarge:
    pop edi
    pop esi
    pop ecx
    pop ds
;
    pop edx
;
    call LinearToPhysicalLarge
    jmp ltpDone

ltpExtDone:
    pop edi
    pop esi
    pop ecx
    pop ds

ltpFound:
    pop edx
;
    movzx eax,dx
    and ax,0FFFh
    or eax,es:mblk_physical_base
    mov ebx,es:mblk_physical_base+4
    clc

ltpDone:
    pop es
    retf32
linear_to_physical_mem_blk     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeBase
;
;   DESCRIPTION:    Free in base block
;
;   PARAMETERS:     ES      Memory block selector
;                   AX      Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBase    Proc near
    mov si,es:mblk_info_offset
    mov di,es:[si].mblk_bitmap_offset
    mov bx,ax
    sub bx,es:[si].mblk_data_offset
    jnc fbBaseOk
;
    int 3
    stc
    jmp fbDone

fbBaseOk:
    mov ax,cx
    mov cl,es:[si].mblk_size_shift
    shr bx,cl
;
    dec ax
    shr ax,cl
    jz fb1
;
    shr ax,1
    jz fb2
;
    shr ax,1
    jz fb4
;
    shr ax,1
    inc ax
;
    shr bx,3
    add di,bx
    mov cx,ax

fbByteLoop:
    xor dl,dl
    xchg dl,es:[di]
    cmp dl,-1
    je fbByteNext
;
    int 3
    stc
    jmp fbDone

fbByteNext:
    inc di
    loop fbByteLoop
;
    shl ax,3    
    lock add es:[si].mblk_free_bits,ax
    clc
    jmp fbDone

fb1:
    lock btr es:[di],bx
    jc fb1Ok1
;
    int 3
    stc
    jmp fbDone

fb1Ok1:
    lock add es:[si].mblk_free_bits,1
    jmp fbDone

fb2:
    lock btr es:[di],bx
    jc fb2Ok1
;
    int 3
    stc
    jmp fbDone

fb2Ok1:
    inc bx
    lock btr es:[di],bx
    jc fb2Ok2
;
    int 3
    stc
    jmp fbDone

fb2Ok2:
    lock add es:[si].mblk_free_bits,2
    jmp fbDone

fb4:
    lock btr es:[di],bx
    jc fb4Ok1
;
    int 3
    stc
    jmp fbDone

fb4Ok1:
    inc bx
    lock btr es:[di],bx
    jc fb4Ok2
;
    int 3
    stc
    jmp fbDone

fb4Ok2:
    inc bx
    lock btr es:[di],bx
    jc fb4Ok3
;
    int 3
    stc
    jmp fbDone

fb4Ok3:
    inc bx
    lock btr es:[di],bx
    jc fb4Ok4
;
    int 3
    stc
    jmp fbDone

fb4Ok4:
    lock add es:[si].mblk_free_bits,4
    clc

fbDone:
    ret
FreeBase    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeExt
;
;   DESCRIPTION:    Free in extended block
;
;   PARAMETERS:     ES      Extended memory block selector
;                   AX      Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeExt    Proc near
    mov di,es:mblke_bitmap_offset
    mov bx,ax
    sub bx,es:mblke_data_offset
    jnc feBaseOk
;
    int 3
    stc
    jmp feDone

feBaseOk:
    mov ax,cx
    mov cl,es:mblke_size_shift
    shr bx,cl
;
    dec ax
    shr ax,cl
    jz fe1
;
    shr ax,1
    jz fe2
;
    shr ax,1
    jz fe4
;
    shr ax,1
    inc ax
;
    shr bx,3
    add di,bx
    mov cx,ax

feByteLoop:
    xor dl,dl
    xchg dl,es:[di]
    cmp dl,-1
    je feByteNext
;
    int 3
    stc
    jmp feDone

feByteNext:
    inc di
    loop feByteLoop
;
    shl ax,3    
    lock add es:mblke_free_bits,ax
    clc
    jmp feDone

fe1:
    lock btr es:[di],bx
    jc fe1Ok1
;
    int 3
    stc
    jmp feDone

fe1Ok1:
    lock add es:mblke_free_bits,1
    jmp feDone

fe2:
    lock btr es:[di],bx
    jc fe2Ok1
;
    int 3
    stc
    jmp feDone

fe2Ok1:
    inc bx
    lock btr es:[di],bx
    jc fe2Ok2
;
    int 3
    stc
    jmp feDone

fe2Ok2:
    lock add es:mblke_free_bits,2
    jmp feDone

fe4:
    lock btr es:[di],bx
    jc fe4Ok1
;
    int 3
    stc
    jmp feDone

fe4Ok1:
    inc bx
    lock btr es:[di],bx
    jc fe4Ok2
;
    int 3
    stc
    jmp feDone

fe4Ok2:
    inc bx
    lock btr es:[di],bx
    jc fe4Ok3
;
    int 3
    stc
    jmp feDone

fe4Ok3:
    inc bx
    lock btr es:[di],bx
    jc fe4Ok4
;
    int 3
    stc
    jmp feDone

fe4Ok4:
    lock add es:mblke_free_bits,4
    clc

feDone:
    ret
FreeExt    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreePhysicalMemBlk
;
;   DESCRIPTION:    Free mem block based on physical address
;
;   PARAMETERS:     ES      Memory block selector
;                   EBX:EAX Physical address
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_physical_mem_blk_name    DB 'Free Physical Mem Blk', 0

free_physical_mem_blk     Proc far
    push ds
    push es
    pushad
;
    cmp cx,0C00h
    jb fpSmall
;
    call FreePhysicalLarge
    jmp fpDone

fpSmall:
    mov dx,ax
    and dx,0FFFh
;
    and ax,0F000h
    cmp eax,es:mblk_physical_base
    jne fpCheckExt
;
    cmp ebx,es:mblk_physical_base+4
    jne fpCheckExt
;
    mov ax,dx
    call FreeBase
    jmp fpDone
    
fpCheckExt:
    mov bp,cx
    mov si,es
    mov ds,si
;
    mov si,ds:mblk_info_offset
    mov cx,ds:[si].mblk_ext_count
    or cx,cx
    jnz fpDoCheck
;
    int 3
    stc
    jmp fpDone

fpDoCheck:
    lea di,[si].mblk_ext_arr 

fpExtLoop:
    push cx
;
    mov cx,ds:[di]
    or cx,cx
    jz fpExtNext
;
    cmp cx,-1
    je fpExtNext
;
    mov es,cx
;
    cmp eax,es:mblk_physical_base
    jne fpExtNext
;
    cmp ebx,es:mblk_physical_base+4
    jne fpExtNext
;
    mov ax,dx
    mov cx,bp
    call FreeExt
;
    pop cx
    jmp fpDone

fpExtNext:
    pop cx
    add di,2
    loop fpExtLoop
;
    int 3
    stc

fpDone:
    popad
    pop es
    pop ds
    retf32
free_physical_mem_blk     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeLinearMemBlk
;
;   DESCRIPTION:    Free mem block based on linear address
;
;   PARAMETERS:     ES      Memory block selector
;                   EDX     Linear address
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_linear_mem_blk_name    DB 'Free Linear Mem Blk', 0

free_linear_mem_blk     Proc far
    push ds
    push es
    pushad
;
    cmp cx,0C00h
    jb flSmall
;
    call FreeLinearLarge
    jmp flDone

flSmall:
    mov ax,dx
    and ax,0FFFh
;
    and dx,0F000h
    cmp edx,es:mblk_linear_base
    jne flCheckExt
;
    call FreeBase
    jmp flDone
    
flCheckExt:
    mov bp,cx
    mov si,es
    mov ds,si
;
    mov si,ds:mblk_info_offset
    mov cx,ds:[si].mblk_ext_count
    or cx,cx
    jnz flDoCheck
;
    int 3
    stc
    jmp flDone

flDoCheck:
    lea di,[si].mblk_ext_arr 

flExtLoop:
    mov bx,ds:[di]
    or bx,bx
    jz flExtNext
;
    cmp bx,-1
    je flExtNext
;
    mov es,bx
;
    cmp edx,es:mblk_linear_base
    jne flExtNext
;
    mov cx,bp
    call FreeExt
    jmp flDone

flExtNext:
    add di,2
    loop flExtLoop
;
    int 3
    stc

flDone:
    popad
    pop es
    pop ds
    retf32
free_linear_mem_blk     Endp

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
    mov esi,OFFSET free_mem_blk
    mov edi,OFFSET free_mem_blk_name
    xor cl,cl
    mov ax,free_mem_blk_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_mem_blk
    mov edi,OFFSET allocate_mem_blk_name
    xor cl,cl
    mov ax,allocate_mem_blk_nr
    RegisterOsGate
;
    mov esi,OFFSET linear_to_physical_mem_blk
    mov edi,OFFSET linear_to_physical_mem_blk_name
    xor cl,cl
    mov ax,linear_to_physical_mem_blk_nr
    RegisterOsGate
;
    mov esi,OFFSET physical_to_linear_mem_blk
    mov edi,OFFSET physical_to_linear_mem_blk_name
    xor cl,cl
    mov ax,physical_to_linear_mem_blk_nr
    RegisterOsGate
;
    mov esi,OFFSET free_physical_mem_blk
    mov edi,OFFSET free_physical_mem_blk_name
    xor cl,cl
    mov ax,free_physical_mem_blk_nr
    RegisterOsGate
;
    mov esi,OFFSET free_linear_mem_blk
    mov edi,OFFSET free_linear_mem_blk_name
    xor cl,cl
    mov ax,free_linear_mem_blk_nr
    RegisterOsGate
    clc
    ret
init_mem_blk  ENDP

code    ENDS

    END
