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

MEM_BLK_SIGN    = 0B45Ah

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
    mov es:mblk_sign,MEM_BLK_SIGN
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
    mov si,es:mblk_info_offset
    mov es:[si].mblk_is64,0
;
    pop esi
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
    push esi
;
    AllocatePhysical64
    call CreateBlock
;
    mov si,es:mblk_info_offset
    mov es:[si].mblk_is64,1
;
    pop esi
    pop ebx
    pop eax
;
    call InitBlock
    retf32
create_mem_blk64     Endp    

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
    not eax
    bsf ecx,eax
;
    add cx,dx
    mov bx,es:[si].mblk_bitmap_offset
    lock bts es:[bx],cx
    jc abLoop1
;
    mov bx,cx
    clc
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
    not eax
    bsf ecx,eax
;    
    add cx,dx
    mov bx,es:mblke_bitmap_offset
    lock bts es:[bx],cx
    jc aebLoop1
;
    mov bx,cx
    clc
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
    int 3

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
    cmp ax,MEM_BLK_SIGN
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
    int 3

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
    cmp ax,MEM_BLK_SIGN
    je ambSignOk
;
    int 3
    stc
    jmp ambDone

ambSignOk:
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
