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
; FILEMAP.ASM
; File mapping in user space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\filemap.inc

    .386p

;
; should be 16 bytes or less
; used for kfm_buf_arr
;

kernel_map_buf    STRUC

kmb_user_ptr      DD ?
kmb_data_offset   DW ?
kmb_data_index    DW ?
kmb_bitmap_offset DW ?
kmb_bitmap_index  DW ?
kmb_wait_list     DW ?

kernel_map_buf    ENDS

kernel_file_map   STRUC

kfm_section       section_typ <>
kfm_sector_size   DW ?
kfm_flat_base     DD ?
kfm_block_arr     DW 16 DUP(?)
kfm_buf_arr       DD 4 * 256 DUP(?)

kernel_file_map   ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBlock
;
;   DESCRIPTION:    Allocate new memory block
;
;   RETURNS:        ES      User mode block selector
;                   DS      Kernel mode selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlock     Proc near
    pushad
;
    mov eax,SIZE kernel_file_map
    AllocateSmallGlobalMem
;
    xor edi,edi
    mov ecx,SIZE kernel_file_map
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov eax,es
    mov ds,eax
;
    mov ax,system_data_sel
    mov es,ax
    mov eax,es:flat_base
    mov ds:kfm_flat_base,eax
;
    mov eax,1000h
    AllocateLocalLinear
;
    sub edx,ds:kfm_flat_base    
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector32
    add edx,ds:kfm_flat_base    
    mov es,bx
;
    xor edi,edi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov es:fmh_adr,edx
;
    popad
    ret
AllocateBlock     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           InitBlock
;
;   DESCRIPTION:    Init memory block
;
;   PARAMETERS:     ES      User mode block selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitBlock     Proc near
    pushad
;
    mov es:fmh_sign,FILE_MAP_BASE_SIGN
;
    mov cl,3
    mov es:fmh_size_shift,cl
;
    mov bx,SIZE file_map_entry
    mov ax,1000h
    sub ax,bx
    shr ax,cl
    mov es:fmh_free_bits,ax
    dec ax
    shr ax,3
    inc ax
    mov es:fmh_bitmap_dd_count,ax
;
    mov ax,SIZE file_map_entry
    dec ax
    mov cl,es:fmh_size_shift
    add cl,3
    shr ax,cl
    inc ax
    shl ax,cl
    mov es:fmh_data_offset,ax
;
    mov bx,ax
    mov ax,1000h
    sub ax,bx
    mov cl,es:fmh_size_shift
    shr ax,cl    
    mov es:fmh_free_bits,ax
    dec ax
    shr ax,5
    inc ax
    shl ax,2
    mov es:fmh_bitmap_dd_count,ax
;
    mov bx,es:fmh_data_offset
    sub bx,ax
    mov es:fmh_bitmap_offset,bx
;
    mov bx,es:fmh_free_bits
    mov cl,3
    shr bx,cl
    mov ax,es:fmh_bitmap_dd_count
    sub ax,bx
    jz ibDone
;
    mov dl,-1
    mov bx,es:fmh_data_offset

ibPadLoop:
    dec bx
    mov es:[bx],dl
    sub ax,1
    jnz ibPadLoop
    
ibDone:
    mov ax,es:fmh_bitmap_dd_count
    shr ax,2
    mov es:fmh_bitmap_dd_count,ax
;
    popad
    ret
InitBlock     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateExtend
;
;   DESCRIPTION:    Allocate new extended memory block
;
;   PARAMETERS:     DS      Kernel mode selector
;
;   RETURNS:        ES      User mode extend selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateExtend     Proc near
    pushad
;
    mov eax,1000h
    AllocateLocalLinear
;
    sub edx,ds:kfm_flat_base    
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector32
    add edx,ds:kfm_flat_base    
    mov es,bx
;
    xor edi,edi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov es:fmh_adr,edx
;
    popad
    ret
AllocateExtend     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           InitExtend
;
;   DESCRIPTION:    Init extended memory block
;
;   PARAMETERS:     ES      User mode extend selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitExtend     Proc near
    pusha
;
    mov es:fmh_sign,FILE_MAP_EXTEND_SIGN
;
    mov cl,3
    mov es:fmh_size_shift,cl
;
    mov bx,SIZE file_map_header
    mov ax,1000h
    sub ax,bx
    shr ax,cl
    mov es:fmh_free_bits,ax
    dec ax
    shr ax,3
    inc ax
    mov es:fmh_bitmap_dd_count,ax
;
    add ax,SIZE file_map_header
    dec ax
    mov cl,es:fmh_size_shift
    add cl,3
    shr ax,cl
    inc ax
    shl ax,cl
    mov es:fmh_data_offset,ax
;
    mov bx,ax
    mov ax,1000h
    sub ax,bx
    mov cl,es:fmh_size_shift
    shr ax,cl    
    mov es:fmh_free_bits,ax
    dec ax
    shr ax,5
    inc ax
    shl ax,2
    mov es:fmh_bitmap_dd_count,ax
;
    mov bx,es:fmh_data_offset
    sub bx,ax
    mov es:fmh_bitmap_offset,bx
;
    mov bx,es:fmh_free_bits
    mov cl,3
    shr bx,cl
    mov ax,es:fmh_bitmap_dd_count
    sub ax,bx
    jz ieDone
;
    mov dl,-1
    mov bx,es:fmh_data_offset

iePadLoop:
    dec bx
    mov es:[bx],dl
    sub ax,1
    jnz iePadLoop
    
ieDone:
    mov ax,es:fmh_bitmap_dd_count
    shr ax,2
    mov es:fmh_bitmap_dd_count,ax
;
    popa
    ret
InitExtend     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           AllocateBit1
;
;   DESCRIPTION:    Allocate single bit block
;
;   PARAMETERS:     ES          User mode block selector
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
    mov bx,es:fmh_bitmap_offset
    movzx ecx,es:fmh_bitmap_dd_count
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
    mov bx,es:fmh_bitmap_offset
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
;   PARAMETERS:     ES          User mode block selector
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
    mov bx,es:fmh_bitmap_offset
    movzx ecx,es:fmh_bitmap_dd_count
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
    mov bx,es:fmh_bitmap_offset
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
;   PARAMETERS:     ES          User mode block selector
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
    mov bx,es:fmh_bitmap_offset
    movzx ecx,es:fmh_bitmap_dd_count
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
    mov bx,es:fmh_bitmap_offset
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
;   PARAMETERS:     ES          User mode block selector
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
    mov bx,es:fmh_bitmap_offset
    movzx ecx,es:fmh_bitmap_dd_count
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
    sub bx,es:fmh_bitmap_offset
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
;   NAME:           AllocateBase
;
;   DESCRIPTION:    Allocate in block
;
;   PARAMETERS:     ES      User mode block selector
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
    mov bx,es:fmh_free_bits
    or bx,bx
    stc
    jz abDone
;
    mov ax,cx
    mov cl,es:fmh_size_shift
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
    lock sub es:fmh_free_bits,ax
    jmp abOk

ab1:
    call AllocateBit1
    jc abDone
;
    lock sub es:fmh_free_bits,1
    jmp abOk

ab2:
    call AllocateBit2
    jc abDone
;
    lock sub es:fmh_free_bits,2
    jmp abOk

ab4:
    call AllocateBit4
    jc abDone
;
    lock sub es:fmh_free_bits,4
    jmp abOk

abOk:
    shl bx,cl
    add bx,es:fmh_data_offset
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
;   NAME:           AllocateBlk
;
;   DESCRIPTION:    Allocate memory block
;
;   PARAMETERS:     ES      User mode file selector
;                   DS      Kernel mode selector
;                   CX      Size
;
;   RETURNS:        DX      Block #
;                   BX      Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlk     Proc near
    push ecx
    push esi
    push edi
    push ebp
;
    mov ax,es:fmh_sign
    cmp ax,FILE_MAP_BASE_SIGN
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
    mov bp,15
    mov edi,2

ambExtendLoop:
    mov ax,ds:[edi].kfm_block_arr
    cmp ax,-1
    stc
    je ambExtendNext
;
    or ax,ax
    jne ambCheck
;
    mov ax,-1
    xchg ax,ds:[edi].kfm_block_arr
    cmp ax,-1
    stc
    je ambExtendNext
;
    or ax,ax
    jz ambAllocate
;
    mov ds:[edi].kfm_block_arr,ax
    jmp ambCheck

ambAllocate:
    push es
;
    call AllocateExtend
    mov ds:[edi].kfm_block_arr,es
;
    call InitExtend
    call AllocateBase
;
    pop es
    jmp ambValidate

ambCheck:
    push es
    mov es,ax
    call AllocateBase
    pop es

ambValidate:
    jc ambExtendNext
;
    mov dx,di
    shr dx,1
    inc dx
    clc
    jmp ambDone

ambExtendNext:
    add edi,2
    sub bp,1
    jnz ambExtendLoop
;
    stc

ambDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
AllocateBlk     Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeBase
;
;   DESCRIPTION:    Free memory block
;
;   PARAMETERS:     ES      User mode block selector
;                   BX      Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBase    Proc near
    mov di,es:fmh_bitmap_offset
    sub bx,es:fmh_data_offset
    jnc fbBaseOk
;
    int 3
    stc
    jmp fbDone

fbBaseOk:
    mov ax,cx
    mov cl,es:fmh_size_shift
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
    lock add es:fmh_free_bits,ax
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
    lock add es:fmh_free_bits,1
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
    lock add es:fmh_free_bits,2
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
    lock add es:fmh_free_bits,4
    clc

fbDone:
    ret
FreeBase    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           FreeBlk
;
;   DESCRIPTION:    Free memory block
;
;   PARAMETERS:     ES      User mode file selector
;                   DS      Kernel mode selector
;                   DX      Block #
;                   BX      Offset
;                   CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBlk     Proc near
    pushad
;
    cmp dx,16
    jae fpDone
;    
    movzx edi,dx
    shl edi,1
    mov ax,ds:[edi].kfm_block_arr
    or ax,ax
    jz fpDone
;
    cmp ax,-1
    jz fpDone
;
    push es
    mov es,ax
    call FreeBase
    pop es

fpDone:
    popad
    ret
FreeBlk     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateFileSel
;
;       DESCRIPTION:    Create file selector
;
;       PARAMETERS:     CX             Sector size
;                       EDX            File info linear
;
;       RETURNS:        NC
;                         AX           File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateFileSel

CreateFileSel	Proc near
    push ds
    push es
;
    int 3
    call AllocateBlock
    call InitBlock
;
    InitSection ds:kfm_section
    mov ds:kfm_sector_size,cx
    mov ax,ds
;
    pop es
    pop ds
    ret
CreateFileSel   Endp

code    ENDS

    END
