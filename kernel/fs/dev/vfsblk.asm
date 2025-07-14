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
; VFSBLK.ASM
; VFS memory block interface module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def

VFS_BLK_BASE_SIGN     = 0C6ACh
VFS_BLK_EXTEND_SIGN   = 02A34h

vfs_blk_header	STRUC

vblk_physical_base   DD ?,?
vblk_linear_base     DD ?
vblk_info_offset     DW ?
vblk_sign            DW ?

vfs_blk_header	ENDS

vfs_blk_info	STRUC

vblk_bitmap_offset   DW ?
vblk_data_offset     DW ?
vblk_bitmap_dd_count DW ?
vblk_free_bits       DW ?
vblk_size_shift      DB ?
vblk_pad             DB ?
vblk_ext_count       DW ?
vblk_ext_size        DW ?
vblk_ext_arr         DW ?

vfs_blk_info	ENDS

vfs_blk_extend	STRUC

vblke_header          vfs_blk_header <>

vblke_bitmap_offset   DW ?
vblke_data_offset     DW ?
vblke_bitmap_dd_count DW ?
vblke_free_bits       DW ?
vblke_size_shift      DB ?
vblke_pad             DB ?

vfs_blk_extend	ENDS

    .386p

code    SEGMENT byte public 'CODE'

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
    mov es:vblk_linear_base,edx
    mov es:vblk_physical_base,eax
    mov es:vblk_physical_base+4,ebx
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
;                   CX      Additional blocks
;                   SI      Reserved size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitBlock     Proc near
    pusha
;
    mov es:vblk_sign,VFS_BLK_BASE_SIGN
;
    test si,1
    jz ibStartOk
;
    inc si

ibStartOk:
    mov es:vblk_info_offset,si
    mov es:[si].vblk_ext_size,cx
    mov es:[si].vblk_ext_count,0
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
    mov es:[si].vblk_size_shift,cl
;
    mov bx,es:[si].vblk_ext_size
    add bx,bx
    add bx,OFFSET vblk_ext_arr
    add bx,es:vblk_info_offset
    mov ax,1000h
    sub ax,bx
    shr ax,cl
    mov es:[si].vblk_free_bits,ax
    dec ax
    shr ax,3
    inc ax
    mov es:[si].vblk_bitmap_dd_count,ax
;
    mov ax,es:[si].vblk_ext_size
    add ax,ax
    add ax,es:[si].vblk_bitmap_dd_count
    add ax,OFFSET vblk_ext_arr
    add ax,es:vblk_info_offset
    dec ax
    mov cl,es:[si].vblk_size_shift
    add cl,3
    shr ax,cl
    inc ax
    shl ax,cl
    mov es:[si].vblk_data_offset,ax
;
    mov bx,ax
    mov ax,1000h
    sub ax,bx
    mov cl,es:[si].vblk_size_shift
    shr ax,cl    
    mov es:[si].vblk_free_bits,ax
    dec ax
    shr ax,5
    inc ax
    shl ax,2
    mov es:[si].vblk_bitmap_dd_count,ax
;
    mov bx,es:[si].vblk_data_offset
    sub bx,ax
    mov es:[si].vblk_bitmap_offset,bx
;
    mov bx,es:[si].vblk_free_bits
    mov cl,3
    shr bx,cl
    mov ax,es:[si].vblk_bitmap_dd_count
    sub ax,bx
    jz ibDone
;
    mov dl,-1
    mov bx,es:[si].vblk_data_offset

ibPadLoop:
    dec bx
    mov es:[bx],dl
    sub ax,1
    jnz ibPadLoop
    
ibDone:
    mov ax,es:[si].vblk_bitmap_dd_count
    shr ax,2
    mov es:[si].vblk_bitmap_dd_count,ax
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
    mov es:vblk_sign,VFS_BLK_EXTEND_SIGN
    mov es:vblke_size_shift,cl
;
    mov bx,SIZE vfs_blk_extend
    mov ax,1000h
    sub ax,bx
    shr ax,cl
    mov es:vblke_free_bits,ax
    dec ax
    shr ax,3
    inc ax
    mov es:vblke_bitmap_dd_count,ax
;
    add ax,SIZE vfs_blk_extend
    dec ax
    mov cl,es:vblke_size_shift
    add cl,3
    shr ax,cl
    inc ax
    shl ax,cl
    mov es:vblke_data_offset,ax
;
    mov bx,ax
    mov ax,1000h
    sub ax,bx
    mov cl,es:vblke_size_shift
    shr ax,cl    
    mov es:vblke_free_bits,ax
    dec ax
    shr ax,5
    inc ax
    shl ax,2
    mov es:vblke_bitmap_dd_count,ax
;
    mov bx,es:vblke_data_offset
    sub bx,ax
    mov es:vblke_bitmap_offset,bx
;
    mov bx,es:vblke_free_bits
    mov cl,3
    shr bx,cl
    mov ax,es:vblke_bitmap_dd_count
    sub ax,bx
    jz ieDone
;
    mov dl,-1
    mov bx,es:vblke_data_offset

iePadLoop:
    dec bx
    mov es:[bx],dl
    sub ax,1
    jnz iePadLoop
    
ieDone:
    mov ax,es:vblke_bitmap_dd_count
    shr ax,2
    mov es:vblke_bitmap_dd_count,ax
;
    popa
    ret
InitExtend     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CreateVfsBlk
;
;   DESCRIPTION:    Create new VFS memory block
;
;   PARAMETERS:     AX      Base allocation size
;                   CX      Minimum additional blocks
;                   SI      Reserved size
;
;   RETURNS:        ES      Memory block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateVfsBlk

CreateVfsBlk     Proc near
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
    ret
CreateVfsBlk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           DeleteVfsBlk
;
;   DESCRIPTION:    Delete VFS memory block
;
;   PARAMETERS:     ES      Memory block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DeleteVfsBlk

DeleteVfsBlk     Proc near
    push eax
    push ecx
    push esi
;
    mov ax,es:vblk_sign
    cmp ax,VFS_BLK_BASE_SIGN
    je dmbSignOk
;
    int 3
    stc
    jmp dmbDone

dmbSignOk:
    mov si,es:vblk_info_offset
    movzx ecx,es:[si].vblk_ext_size
    lea si,[si].vblk_ext_arr

dmbLoop:
    mov ax,es:[si]
    or ax,ax
    je dmbNext
;
    cmp ax,-1
    je dmbNext
;
    push es
    mov es,ax
    FreeMem
    pop es

dmbNext:
    add si,2
    loop dmbLoop
;
    FreeMem
    clc

dmbDone:
    pop esi
    pop ecx
    pop eax    
    ret
DeleteVfsBlk     Endp    

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
    mov si,es:vblk_info_offset
    mov cl,es:[si].vblk_size_shift
    AllocatePhysical64
    call CreateBlock
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
    mov bx,es:[si].vblk_bitmap_offset
    movzx ecx,es:[si].vblk_bitmap_dd_count
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
    mov bx,es:[si].vblk_bitmap_offset
    lock bts es:[bx],cx
    mov bx,cx
    pop ecx
    jc abLoop1
;
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
    mov bx,es:[si].vblk_bitmap_offset
    movzx ecx,es:[si].vblk_bitmap_dd_count
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
    mov bx,es:[si].vblk_bitmap_offset
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
    mov bx,es:[si].vblk_bitmap_offset
    movzx ecx,es:[si].vblk_bitmap_dd_count
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
    mov bx,es:[si].vblk_bitmap_offset
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
    sub ecx,1
    jnz abLoop4
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
    mov bx,es:[si].vblk_bitmap_offset
    movzx ecx,es:[si].vblk_bitmap_dd_count
    shl ecx,2
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
    sub bx,es:[si].vblk_bitmap_offset
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
    mov bx,es:vblke_bitmap_offset
    movzx ecx,es:vblke_bitmap_dd_count
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
    mov bx,es:vblke_bitmap_offset
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
    mov bx,es:vblke_bitmap_offset
    movzx ecx,es:vblke_bitmap_dd_count
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
    mov bx,es:vblke_bitmap_offset
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
    mov bx,es:vblke_bitmap_offset
    movzx ecx,es:vblke_bitmap_dd_count
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
    mov bx,es:vblke_bitmap_offset
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
    sub ecx,1
    jnz aebLoop4
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
    mov bx,es:vblke_bitmap_offset
    movzx ecx,es:vblke_bitmap_dd_count
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
    sub bx,es:vblke_bitmap_offset
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
;   RETURNS:        BX      Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBase    Proc near
    push eax
    push ecx
    push edx
    push esi
;
    mov si,es:vblk_info_offset
;
    mov bx,es:[si].vblk_free_bits
    or bx,bx
    stc
    jz abDone
;
    mov ax,cx
    mov cl,es:[si].vblk_size_shift
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
    lock sub es:[si].vblk_free_bits,ax
    jmp abOk

ab1:
    call AllocateBit1
    jc abDone
;
    lock sub es:[si].vblk_free_bits,1
    jmp abOk

ab2:
    call AllocateBit2
    jc abDone
;
    lock sub es:[si].vblk_free_bits,2
    jmp abOk

ab4:
    call AllocateBit4
    jc abDone
;
    lock sub es:[si].vblk_free_bits,4
    jmp abOk

abOk:
    shl bx,cl
    add bx,es:[si].vblk_data_offset
    clc

abDone:
    pop esi
    pop edx
    pop ecx
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
;   PARAMETERS:     ES      Extended memory block selector
;                   CX      Size
;
;   RETURNS:        BX      Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtend  Proc near
    push eax
    push ecx
    push edx
    push esi
;
    mov ax,es:vblk_sign
    cmp ax,VFS_BLK_EXTEND_SIGN
    je aeSignOk
;
    int 3
    stc
    jmp aeDone

aeSignOk:
    mov ax,es:vblke_free_bits
    or ax,ax
    stc
    jz aeDone
;
    mov ax,cx
    mov cl,es:vblke_size_shift
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
    lock sub es:vblke_free_bits,ax
    jmp aeOk

ae1:
    call AllocateExtendBit1
    jc aeDone
;
    lock sub es:vblke_free_bits,1
    jmp aeOk

ae2:
    call AllocateExtendBit2
    jc aeDone
;
    lock sub es:vblke_free_bits,2
    jmp aeOk

ae4:
    call AllocateExtendBit4
    jc aeDone
;
    lock sub es:vblke_free_bits,4
    jmp aeOk

aeOk:
    shl bx,cl
    add bx,es:vblke_data_offset
    clc

aeDone:
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
AllocateExtend  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateVfsBlk
;
;   DESCRIPTION:    Allocate VFS memory block
;
;   PARAMETERS:     ES      Memory block selector
;                   CX      Size
;
;   RETURNS:        DX      Block #
;                   BX      Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateVfsBlk

AllocateVfsBlk     Proc near
    push ecx
    push esi
    push edi
    push ebp
;
    mov ax,es:vblk_sign
    cmp ax,VFS_BLK_BASE_SIGN
    je ambSignOk
;
    int 3
    stc
    jmp ambDone

ambSignOk:
    call AllocateBase
    jc ambExtend
;
    xor dx,dx
    jmp ambDone

ambExtend:
    mov si,es:vblk_info_offset
    mov bp,es:[si].vblk_ext_size
    lea di,[si].vblk_ext_arr

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
    lock add es:[si].vblk_ext_count,1

ambCheck:
    push es
    mov es,ax
    call AllocateExtend
    pop es
    jc ambExtendNext
;
    mov dx,di
    lea di,[si].vblk_ext_arr
    sub dx,di
    shr dx,1
    inc dx
    clc
    jmp ambDone

ambExtendNext:
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
    ret
AllocateVfsBlk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           PhysicalToVfsBlk
;
;   DESCRIPTION:    Convert between physical and VFA block
;
;   PARAMETERS:     ES      Memory block selector
;                   EBX:EAX Physical address
;
;   RETURNS:        DX      Block #
;                   BX      Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PhysicalToVfsBlk

PhysicalToVfsBlk     Proc near
    push es
    push eax
;
    xor dx,dx
;
    push eax
;
    and ax,0F000h
    cmp eax,es:vblk_physical_base
    jne ptlCheckExt
;
    cmp ebx,es:vblk_physical_base+4
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
    mov si,ds:vblk_info_offset
    movzx ecx,ds:[si].vblk_ext_count
    or cx,cx
    stc
    jz ptlDone
;
    lea di,[si].vblk_ext_arr 

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
    cmp eax,es:vblk_physical_base
    jne ptlExtNext
;
    cmp ebx,es:vblk_physical_base+4
    jne ptlExtNext
;
    mov dx,di
    lea di,[si].vblk_ext_arr 
    sub dx,di
    shr dx,1
    inc dx
    jmp ptlExtDone

ptlExtNext:
    add di,2
    loop ptlExtLoop
;
    pop edi
    pop esi
    pop ecx
    pop ds
;
    pop eax
    stc
    jmp ptlDone

ptlExtDone:
    pop edi
    pop esi
    pop ecx
    pop ds

ptlFound:
    pop eax
;
    mov bx,ax
    and bx,0FFFh
    clc

ptlDone:
    pop eax
    pop es
    ret
PhysicalToVfsBlk     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeBase
;
;   DESCRIPTION:    Free in base block
;
;   PARAMETERS:     ES      Memory block selector
;                   BX      Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBase    Proc near
    mov si,es:vblk_info_offset
    mov di,es:[si].vblk_bitmap_offset
    sub bx,es:[si].vblk_data_offset
    jnc fbBaseOk
;
    int 3
    stc
    jmp fbDone

fbBaseOk:
    mov ax,cx
    mov cl,es:[si].vblk_size_shift
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
    lock add es:[si].vblk_free_bits,ax
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
    lock add es:[si].vblk_free_bits,1
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
    lock add es:[si].vblk_free_bits,2
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
    lock add es:[si].vblk_free_bits,4
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
;                   BX      Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeExt    Proc near
    mov di,es:vblke_bitmap_offset
    sub bx,es:vblke_data_offset
    jnc feBaseOk
;
    int 3
    stc
    jmp feDone

feBaseOk:
    mov ax,cx
    mov cl,es:vblke_size_shift
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
    lock add es:vblke_free_bits,ax
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
    lock add es:vblke_free_bits,1
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
    lock add es:vblke_free_bits,2
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
    lock add es:vblke_free_bits,4
    clc

feDone:
    ret
FreeExt    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeVfsBlk
;
;   DESCRIPTION:    Free VFS mem block
;
;   PARAMETERS:     ES      Memory block selector
;                   DX      Block #
;                   BX      Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeVfsBlk

FreeVfsBlk     Proc near
    pushad
;
    or dx,dx
    jnz fpExt
;
    call FreeBase
    jmp fpDone
    
fpExt:
    mov si,es:vblk_info_offset
    dec dx
    cmp dx,ds:[si].vblk_ext_count
    jae fpDone
;
    shl dx,1
    lea di,[si].vblk_ext_arr 
    add di,dx
    mov ax,ds:[di]
    or ax,ax
    jz fpDone
;
    cmp ax,-1
    jz fpDone
;
    push es
    mov es,ax
    call FreeExt
    pop es

fpDone:
    popad
    ret
FreeVfsBlk     Endp

code    ENDS

    END
