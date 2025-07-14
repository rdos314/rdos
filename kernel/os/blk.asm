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
; BLK.ASM
; Block interface module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE blk.inc

BLK_BASE_SIGN     = 0C45Ah
BLK_EXTEND_SIGN   = 06FA6h

blk_info	STRUC

blk_bitmap_offset   DW ?
blk_data_offset     DW ?
blk_bitmap_dd_count DW ?
blk_free_bits       DW ?
blk_size_shift      DB ?
blk_spinlock        DB ?

blk_info	ENDS

blk_extend	STRUC

blke_sign            DW ?
blke_bitmap_offset   DW ?
blke_data_offset     DW ?
blke_bitmap_dd_count DW ?
blke_free_bits       DW ?
blke_size_shift      DB ?
blke_pad             DB ?

blk_extend	ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateBlock
;
;   DESCRIPTION:    Create new block
;
;   RETURNS:        DS      Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBlock     Proc near
    push es
    pushad
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector32
    mov ds,bx
    mov es,bx
;
    xor edi,edi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov ds:blk_linear,edx
    mov ds:blk_size,1000h
;
    popad
    pop es
    ret
CreateBlock     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           InitBlock
;
;   DESCRIPTION:    Init memory block
;
;   PARAMETERS:     DS      Memory block selector
;                   AX      Base allocation size
;                   SI      Header size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitBlock     Proc near
    pusha
;
    mov ds:blk_sign,BLK_BASE_SIGN
;
    test si,1
    jz ibStartOk
;
    inc si

ibStartOk:
    mov ds:blk_info_offset,si
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
    mov ds:[si].blk_size_shift,cl
;
    mov bx,si
    add bx,SIZE blk_info
    mov ax,1000h
    sub ax,bx
    shr ax,cl
    mov ds:[si].blk_free_bits,ax
    dec ax
    shr ax,3
    inc ax
    mov ds:[si].blk_bitmap_dd_count,ax
;
    mov ax,ds:[si].blk_bitmap_dd_count
    add ax,SIZE blk_info
    add ax,si
    dec ax
    mov cl,ds:[si].blk_size_shift
    add cl,3
    shr ax,cl
    inc ax
    shl ax,cl
    mov ds:[si].blk_data_offset,ax
;
    mov bx,ax
    mov ax,1000h
    sub ax,bx
    mov cl,ds:[si].blk_size_shift
    shr ax,cl    
    mov ds:[si].blk_free_bits,ax
    dec ax
    shr ax,5
    inc ax
    shl ax,2
    mov ds:[si].blk_bitmap_dd_count,ax
;
    mov bx,ds:[si].blk_data_offset
    sub bx,ax
    mov ds:[si].blk_bitmap_offset,bx
;
    mov bx,ds:[si].blk_free_bits
    mov cl,3
    shr bx,cl
    mov ax,ds:[si].blk_bitmap_dd_count
    sub ax,bx
    jz ibDone
;
    mov dl,-1
    mov bx,ds:[si].blk_data_offset

ibPadLoop:
    dec bx
    mov ds:[bx],dl
    sub ax,1
    jnz ibPadLoop
    
ibDone:
    mov ax,ds:[si].blk_bitmap_dd_count
    shr ax,2
    mov ds:[si].blk_bitmap_dd_count,ax
;
    mov ds:[si].blk_spinlock,0
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
;   PARAMETERS:     DS      Memory block selector
;                   EDX     Block offset
;                   CL      Size shift
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitExtend     Proc near
    push es
    pushad
;
    push ecx
    mov ax,ds
    mov es,eax
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop ecx
;
    mov ds:[edx].blke_sign,BLK_EXTEND_SIGN
    mov ds:[edx].blke_size_shift,cl
;
    mov bx,SIZE blk_extend
    mov ax,1000h
    sub ax,bx
    shr ax,cl
    mov ds:[edx].blke_free_bits,ax
    dec ax
    shr ax,3
    inc ax
    mov ds:[edx].blke_bitmap_dd_count,ax
;
    add ax,SIZE blk_extend
    dec ax
    mov cl,ds:[edx].blke_size_shift
    add cl,3
    shr ax,cl
    inc ax
    shl ax,cl
    mov ds:[edx].blke_data_offset,ax
;
    mov bx,ax
    mov ax,1000h
    sub ax,bx
    mov cl,ds:[edx].blke_size_shift
    shr ax,cl    
    mov ds:[edx].blke_free_bits,ax
    dec ax
    shr ax,5
    inc ax
    shl ax,2
    mov ds:[edx].blke_bitmap_dd_count,ax
;
    mov bx,ds:[edx].blke_data_offset
    sub bx,ax
    mov ds:[edx].blke_bitmap_offset,bx
;
    mov bx,ds:[edx].blke_free_bits
    mov cl,3
    shr bx,cl
    mov ax,ds:[edx].blke_bitmap_dd_count
    sub ax,bx
    jz ieDone
;
    mov cl,-1
    movzx ebx,ds:[edx].blke_data_offset

iePadLoop:
    dec ebx
    mov ds:[edx+ebx],cl
    sub ax,1
    jnz iePadLoop
    
ieDone:
    mov ax,ds:[edx].blke_bitmap_dd_count
    shr ax,2
    mov ds:[edx].blke_bitmap_dd_count,ax
;
    popad
    pop es
    ret
InitExtend     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateBlk
;
;   DESCRIPTION:    Create new block
;
;   PARAMETERS:     AX      Base allocation size
;                   SI      Reserved size
;
;   RETURNS:        DS      Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_blk_name    DB 'Create Blk', 0

create_blk     Proc far
    call CreateBlock
    call InitBlock
    retf32
create_blk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           DeleteBlk
;
;   DESCRIPTION:    Delete block
;
;   PARAMETERS:     DS      Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_blk_name    DB 'Delete Blk', 0

delete_blk     Proc far
    push es
    push eax
;
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
;
    mov ax,es:blk_sign
    cmp ax,BLK_BASE_SIGN
    je fmbSignOk
;
    int 3
    stc
    jmp fmbDone

fmbSignOk:
    FreeMem
    clc

fmbDone:
    pop eax    
    pop es
    retf32
delete_blk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           Extend
;
;   DESCRIPTION:    Extend block size
;
;   PARAMETERS:     DS      Block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Extend     Proc near
    pushad
;
    mov si,ds:blk_info_offset
    mov al,1
    xchg al,ds:[si].blk_spinlock
    or al,al
    stc
    jnz eDone
;
    mov eax,ds:blk_size
    add eax,1000h
    AllocateBigLinear
;
    mov esi,ds:blk_linear
    mov edi,edx
    mov ecx,ds:blk_size
    shr ecx,12
    push edx

ePageCopy:
    mov edx,esi
    GetPageEntry
;
    mov edx,edi
    SetPageEntry
;
    add esi,1000h
    add edi,1000h
    loop ePageCopy
;
    pop edx
    mov bx,ds
    mov ecx,ds:blk_size
    add ecx,1000h
    CreateDataSelector32
    mov ds,bx
;
    xchg edx,ds:blk_linear
    mov ecx,ds:blk_size
;
    push ecx
    push edx
;
    mov edx,ecx
    mov si,ds:blk_info_offset
    mov cl,ds:[si].blk_size_shift
    call InitExtend
;
    pop edx
    pop ecx
;
    shr ecx,12
    FlushTlb
;
    mov ecx,ds:blk_size
    add ds:blk_size,1000h
    mov ds:[si].blk_spinlock,0
;
    push ecx
    push edx
;
    shr ecx,12

ePageClear:
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    add edx,1000h
    loop ePageClear
;
    pop edx
    pop ecx
    FreeLinear
    clc

eDone:
    popad
    ret
Extend     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBit1
;
;   DESCRIPTION:    Allocate single bit block
;
;   PARAMETERS:     DS          Block selector
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
    mov bx,ds:[si].blk_bitmap_offset
    mov cx,ds:[si].blk_bitmap_dd_count
    xor dx,dx

abLoop1:
    mov eax,ds:[bx]
    cmp eax,-1
    je abNext1
;
    push ecx
    not eax
    bsf ecx,eax
;
    add cx,dx
    mov bx,ds:[si].blk_bitmap_offset
    lock bts ds:[bx],cx
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
;   PARAMETERS:     DS          Block selector
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
    mov bx,ds:[si].blk_bitmap_offset
    mov cx,ds:[si].blk_bitmap_dd_count
    xor dx,dx

abLoop2:
    mov eax,ds:[bx]
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
    mov bx,ds:[si].blk_bitmap_offset
    lock bts ds:[bx],ax
    jc abLoop2
;
    inc ax
    lock bts ds:[bx],ax
    jc abBitRevert2
;
    mov bx,bp
    clc
    jmp abDone2

abBitRevert2:
    dec ax
    lock btr ds:[bx],ax
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
;   PARAMETERS:     DS          Block selector
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
    mov bx,ds:[si].blk_bitmap_offset
    mov cx,ds:[si].blk_bitmap_dd_count
    xor dx,dx

abLoop4:
    mov eax,ds:[bx]
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
    mov bx,ds:[si].blk_bitmap_offset
    lock bts ds:[bx],ax
    jc abLoop4
;
    inc ax
    lock bts ds:[bx],ax
    jc abBitRevert41
;
    inc ax
    lock bts ds:[bx],ax
    jc abBitRevert42
;
    inc ax
    lock bts ds:[bx],ax
    jc abBitRevert43
;
    mov bx,bp
    clc
    jmp abDone4

abBitRevert43:
    dec ax
    lock btr ds:[bx],ax

abBitRevert42:
    dec ax
    lock btr ds:[bx],ax

abBitRevert41:
    dec ax
    lock btr ds:[bx],ax
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
;   PARAMETERS:     DS          Block selector
;                   AX          Byte count
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
    mov bx,ds:[si].blk_bitmap_offset
    mov cx,ds:[si].blk_bitmap_dd_count
    shl cx,2
    mov dx,bp

abtCheck:
    mov al,ds:[bx]
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
    xchg al,ds:[bx]
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
    sub bx,ds:[si].blk_bitmap_offset
    shl bx,3
    clc
    jmp abtDone

abtRestore:
    mov ds:[bx],al

abtRevert:
    or dx,dx
    jz abtNext
;
    inc bx
    dec dx
    xor al,al
    mov ds:[bx],al
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
;   PARAMETERS:     DS:EDX      Extended offset
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtendBit1      Proc near
    push eax
    push ecx
    push edi
;
    movzx ebx,ds:[edx].blke_bitmap_offset
    mov cx,ds:[edx].blke_bitmap_dd_count
    xor di,di

aebLoop1:
    mov eax,ds:[ebx+edx]
    cmp eax,-1
    je aebNext1
;
    push ecx
    not eax
    bsf ecx,eax
;    
    add cx,di
    mov bx,ds:[edx].blke_bitmap_offset
    lock bts ds:[ebx+edx],cx
    mov bx,cx
    pop ecx
    jc aebLoop1
    jmp aebDone1

aebNext1:
    add di,32
    add ebx,4
    loop aebLoop1
;
    stc

aebDone1:
    pop edi
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
;   PARAMETERS:     DS:EDX      Extended offset
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtendBit2      Proc near
    push eax
    push ecx
    push esi
    push edi
;
    movzx ebx,ds:[edx].blke_bitmap_offset
    add ebx,edx
    mov cx,ds:[edx].blke_bitmap_dd_count
    xor di,di

aebLoop2:
    mov eax,ds:[ebx]
    cmp eax,-1
    je aebNext2
;
    xor si,si

aebBitLoop2:
    rcr eax,1
    jc aebSkip2
;
    rcr eax,1
    jc aebBitNext2
;
    add si,di
    mov ax,si
    movzx ebx,ds:[edx].blke_bitmap_offset
    add ebx,edx
    lock bts ds:[ebx],ax
    jc aebLoop2
;
    inc ax
    lock bts ds:[ebx],ax
    jc aebRevert2
;
    mov bx,si
    clc
    jmp aebDone2

aebRevert2:
    dec ax
    lock btr ds:[ebx],ax
    jmp aebLoop2

aebSkip2:
    rcr eax,1

aebBitNext2:
    add si,2
    cmp si,32
    jne aebBitLoop2

aebNext2:
    add di,32
    add ebx,4
    loop aebLoop2
;
    stc

aebDone2:
    pop edi
    pop esi
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
;   PARAMETERS:     DS:EDX      Extended offset
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtendBit4    Proc near
    push eax
    push ecx
    push esi
    push edi
;
    movzx ebx,ds:[edx].blke_bitmap_offset
    add ebx,edx
    mov cx,ds:[edx].blke_bitmap_dd_count
    xor di,di

aebLoop4:
    mov eax,ds:[ebx]
    cmp eax,-1
    je aebNext4
;
    xor si,si

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
    add si,di
    mov ax,si
    movzx ebx,ds:[edx].blke_bitmap_offset
    add ebx,edx
    lock bts ds:[ebx],ax
    jc aebLoop4
;
    inc ax
    lock bts ds:[ebx],ax
    jc aebBitRevert41
;
    inc ax
    lock bts ds:[ebx],ax
    jc aebBitRevert42
;
    inc ax
    lock bts ds:[ebx],ax
    jc aebBitRevert43
;
    mov bx,si
    clc
    jmp aebDone4

aebBitRevert43:
    dec ax
    lock btr ds:[ebx],ax

aebBitRevert42:
    dec ax
    lock btr ds:[ebx],ax

aebBitRevert41:
    dec ax
    lock btr ds:[ebx],ax
    jmp abLoop4

aebSkip43:
    rcr eax,1

aebSkip42:
    rcr eax,1

aebSkip41:
    rcr eax,1

aebBitNext4:
    add si,4
    cmp si,32
    jne aebBitLoop4

aebNext4:
    add di,32
    add ebx,4
    sub cx,1
    jnz aebLoop4
;
    stc

aebDone4:
    pop edi
    pop esi
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
;   PARAMETERS:     DS:EDX      Extended offset
;                   AX          Byte count
;
;   RETURNS:        NC
;                       BX      Memory bit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtendByte    Proc near
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    mov si,ax
    movzx ebx,ds:[edx].blke_bitmap_offset
    add ebx,edx
    mov cx,ds:[edx].blke_bitmap_dd_count
    shl cx,2
    mov di,si

aebtCheck:
    mov al,ds:[ebx]
    or al,al
    jnz aebtNext
;
    sub di,1
    jz aebtTake
;
    inc ebx
    loop aebtCheck
;
    stc
    jmp aebtDone

aebtTake:
    mov al,-1
    xchg al,ds:[ebx]
    cmp al,-1
    je aebtRevert
;
    or al,al
    jne aebtRestore
;
    inc di
    cmp di,si
    je aebtTaken
;
    dec ebx
    jmp aebtTake

aebtTaken:
    sub ebx,edx
    sub bx,ds:[edx].blke_bitmap_offset
    shl bx,3
    clc
    jmp aebtDone

aebtRestore:
    mov ds:[ebx],al

aebtRevert:
    or di,di
    jz aebtNext
;
    inc ebx
    dec di
    xor al,al
    mov ds:[ebx],al
    jmp aebtRevert

aebtNext:
    inc ebx    
    mov di,si
    sub cx,1
    jnz aebtCheck
;
    stc

aebtDone:
    pop edi
    pop esi
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
;   PARAMETERS:     DS          Block selector
;                   CX          Size
;
;   RETURNS:        EDX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBase    Proc near
    push eax
    push ebx
    push ecx
    push esi
;
    mov si,ds:blk_info_offset
;
    mov bx,ds:[si].blk_free_bits
    or bx,bx
    stc
    jz abDone
;
    mov ax,cx
    mov cl,ds:[si].blk_size_shift
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
    lock sub ds:[si].blk_free_bits,ax
    jmp abOk

ab1:
    call AllocateBit1
    jc abDone
;
    lock sub ds:[si].blk_free_bits,1
    jmp abOk

ab2:
    call AllocateBit2
    jc abDone
;
    lock sub ds:[si].blk_free_bits,2
    jmp abOk

ab4:
    call AllocateBit4
    jc abDone
;
    lock sub ds:[si].blk_free_bits,4
    jmp abOk

abOk:
    shl bx,cl
    add bx,ds:[si].blk_data_offset
    movzx edx,bx
    clc

abDone:
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret
AllocateBase    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateExtend
;
;   DESCRIPTION:    Allocate from extended block
;
;   PARAMETERS:     DS:EDX      Extended offset
;                   CX          Size
;
;   RETURNS:        EDX         Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtend  Proc near
    push eax
    push ebx
    push ecx
    push esi
;
    mov ax,ds:[edx].blke_sign
    cmp ax,BLK_EXTEND_SIGN
    je aeSignOk
;
    int 3
    stc
    jmp aeDone

aeSignOk:
    mov ax,ds:[edx].blke_free_bits
    or ax,ax
    stc
    jz aeDone
;
    mov ax,cx
    mov cl,ds:[edx].blke_size_shift
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
    lock sub ds:[edx].blke_free_bits,ax
    jmp aeOk

ae1:
    call AllocateExtendBit1
    jc aeDone
;
    lock sub ds:[edx].blke_free_bits,1
    jmp aeOk

ae2:
    call AllocateExtendBit2
    jc aeDone
;
    lock sub ds:[edx].blke_free_bits,2
    jmp aeOk

ae4:
    call AllocateExtendBit4
    jc aeDone
;
    lock sub ds:[edx].blke_free_bits,4
    jmp aeOk

aeOk:
    shl bx,cl
    add bx,ds:[edx].blke_data_offset
    movzx ebx,bx
    add edx,ebx
    clc

aeDone:
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret
AllocateExtend  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBlk
;
;   DESCRIPTION:    Allocate block
;
;   PARAMETERS:     DS      Block selector
;                   CX      Size
;
;   RETURNS:        EDX     Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_blk_name    DB 'Allocate Blk', 0

allocate_blk     Proc far
    push eax
;
    mov ax,ds:blk_sign
    cmp ax,BLK_BASE_SIGN
    je ambSignOk
;
    int 3
    stc
    jmp ambDone

ambSignOk:
    call AllocateBase
    jnc ambDone

ambExtend:
    mov edx,1000h

ambExtendLoop:
    cmp edx,ds:blk_size
    jne ambCheck
;
    call Extend
    jc ambSignOk

ambCheck:
    call AllocateExtend
    jnc ambDone
;
    add edx,1000h
    cmp edx,100000h
    jne ambExtendLoop
;
    int 3
    stc

ambDone:
    pop eax
    retf32
allocate_blk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeBase
;
;   DESCRIPTION:    Free in base block
;
;   PARAMETERS:     DS      Block selector
;                   DX      Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBase    Proc near
    mov si,ds:blk_info_offset
    mov di,ds:[si].blk_bitmap_offset
    mov bx,dx
    sub bx,ds:[si].blk_data_offset
    jnc fbBaseOk
;
    int 3
    stc
    jmp fbDone

fbBaseOk:
    mov ax,cx
    mov cl,ds:[si].blk_size_shift
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
    xchg dl,ds:[di]
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
    lock add ds:[si].blk_free_bits,ax
    clc
    jmp fbDone

fb1:
    lock btr ds:[di],bx
    jc fb1Ok1
;
    int 3
    stc
    jmp fbDone

fb1Ok1:
    lock add ds:[si].blk_free_bits,1
    jmp fbDone

fb2:
    lock btr ds:[di],bx
    jc fb2Ok1
;
    int 3
    stc
    jmp fbDone

fb2Ok1:
    inc bx
    lock btr ds:[di],bx
    jc fb2Ok2
;
    int 3
    stc
    jmp fbDone

fb2Ok2:
    lock add ds:[si].blk_free_bits,2
    jmp fbDone

fb4:
    lock btr ds:[di],bx
    jc fb4Ok1
;
    int 3
    stc
    jmp fbDone

fb4Ok1:
    inc bx
    lock btr ds:[di],bx
    jc fb4Ok2
;
    int 3
    stc
    jmp fbDone

fb4Ok2:
    inc bx
    lock btr ds:[di],bx
    jc fb4Ok3
;
    int 3
    stc
    jmp fbDone

fb4Ok3:
    inc bx
    lock btr ds:[di],bx
    jc fb4Ok4
;
    int 3
    stc
    jmp fbDone

fb4Ok4:
    lock add ds:[si].blk_free_bits,4
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
;   PARAMETERS:     DS:EDX      Extended offset
;                   CX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeExt    Proc near
    mov bx,dx
    and bx,0FFFh
    and dx,0F000h
    movzx edi,ds:[edx].blke_bitmap_offset
    add edi,edx
    sub bx,ds:[edx].blke_data_offset
    jnc feBaseOk
;
    int 3
    stc
    jmp feDone

feBaseOk:
    mov ax,cx
    mov cl,ds:[edx].blke_size_shift
    shr ebx,cl
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
    mov cx,ax
;
    movzx ebx,bx
    shr ebx,3
    add edi,ebx

feByteLoop:
    xor dl,dl
    xchg dl,ds:[edi]
    cmp dl,-1
    je feByteNext
;
    int 3
    stc
    jmp feDone

feByteNext:
    inc edi
    loop feByteLoop
;
    xor dl,dl
    shl ax,3    
    lock add ds:[edx].blke_free_bits,ax
    clc
    jmp feDone

fe1:
    lock btr ds:[edi],bx
    jc fe1Ok1
;
    int 3
    stc
    jmp feDone

fe1Ok1:
    lock add ds:[edx].blke_free_bits,1
    jmp feDone

fe2:
    lock btr ds:[edi],bx
    jc fe2Ok1
;
    int 3
    stc
    jmp feDone

fe2Ok1:
    inc bx
    lock btr ds:[edi],bx
    jc fe2Ok2
;
    int 3
    stc
    jmp feDone

fe2Ok2:
    lock add ds:[edx].blke_free_bits,2
    jmp feDone

fe4:
    lock btr ds:[edi],bx
    jc fe4Ok1
;
    int 3
    stc
    jmp feDone

fe4Ok1:
    inc bx
    lock btr ds:[edi],bx
    jc fe4Ok2
;
    int 3
    stc
    jmp feDone

fe4Ok2:
    inc bx
    lock btr ds:[edi],bx
    jc fe4Ok3
;
    int 3
    stc
    jmp feDone

fe4Ok3:
    inc bx
    lock btr ds:[edi],bx
    jc fe4Ok4
;
    int 3
    stc
    jmp feDone

fe4Ok4:
    lock add ds:[edx].blke_free_bits,4
    clc

feDone:
    ret
FreeExt    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeBlk
;
;   DESCRIPTION:    Free block based on linear address
;
;   PARAMETERS:     DS      Block selector
;                   EDX     Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_blk_name    DB 'Free Blk', 0

free_blk     Proc far
    pushad
;
    cmp edx,1000h
    jae flCheckExt
;
    call FreeBase
    jmp flDone
    
flCheckExt:
    call FreeExt

flDone:
    popad
    retf32
free_blk     Endp

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

    public init_blk
    
init_blk   PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET create_blk
    mov edi,OFFSET create_blk_name
    xor cl,cl
    mov ax,create_blk_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_blk
    mov edi,OFFSET delete_blk_name
    xor cl,cl
    mov ax,delete_blk_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_blk
    mov edi,OFFSET allocate_blk_name
    xor cl,cl
    mov ax,allocate_blk_nr
    RegisterOsGate
;
    mov esi,OFFSET free_blk
    mov edi,OFFSET free_blk_name
    xor cl,cl
    mov ax,free_blk_nr
    RegisterOsGate
    clc
    ret
init_blk  ENDP

code    ENDS

    END
