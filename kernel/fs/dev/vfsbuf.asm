;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; VFSBUF.ASM
; VFS buffer interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\serv.def
include ..\serv.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include ..\os\protseg.def
include vfs.inc

    .386p

MAX_BITMAP_COUNT =  16
MAX_PAGE_COUNT =  32

data    SEGMENT byte public 'DATA'

bitmap_count        DW ?
bitmap_section      section_typ <>
bitmap_arr          DD MAX_BITMAP_COUNT DUP (?)

zero_page_count     DW ?
zero_page_section   section_typ <>
zero_page_arr       DD MAX_PAGE_COUNT DUP (?)

data    ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern NotifyVfs:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateReq
;
;           DESCRIPTION:    Create & insert req bit 0
;
;           PARAMETERS:     DS           VFS sel
;                           EDX:EAX      Sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateReq Proc near
    push es
    push eax
    push edi
;
    push eax
    mov eax,SIZE vfs_req
    AllocateSmallGlobalMem
    pop eax
    and al,0F8h
    mov es:vfsrq_sector,eax
    mov es:vfsrq_sector+4,edx
;
    GetThread
    mov es:vfsrq_thread,ax
;
    mov di,ds:vfs_req_list
    or di,di
    je crEmpty
;    
    push fs
    push esi
;
    mov fs,di
    mov si,fs:vfsrq_prev
    mov fs:vfsrq_prev,es
    mov fs,si
    mov fs:vfsrq_next,es
    mov es:vfsrq_next,di
    mov es:vfsrq_prev,si
;
    pop esi
    pop fs
    jmp crDone
    
crEmpty:
    mov es:vfsrq_next,es
    mov es:vfsrq_prev,es
    mov ds:vfs_req_list,es

crDone:
    pop edi
    pop eax
    pop es
    ret
CreateReq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveReq
;
;           DESCRIPTION:    Remove req & signal thread
;
;           PARAMETERS:     DS           VFS sel
;                           EDX:EAX      Sector
;                           CX           Lock count in
;
;           RETURNS:        CX           Lock count out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveReq Proc near
    push es
    push fs
    push ebx
    push ebp

rqRetry:
    mov bx,ds:vfs_req_list
    or bx,bx
    jz rqDone
;
    mov bp,bx

rqLoop:
    mov es,bx
    cmp eax,es:vfsrq_sector
    jne rqNext
;
    cmp edx,es:vfsrq_sector+4
    je rqFound

rqNext:
    mov bx,es:vfsrq_next
    cmp bx,bp
    jne rqLoop
;
    jmp rqDone

rqFound:
    mov bx,es:vfsrq_next
    mov ds:vfs_req_list,bx
;
    mov bp,es
    cmp bp,bx
;
    mov bp,es:vfsrq_prev
    mov fs,bx
    mov fs:vfsrq_prev,bp
    mov fs,bp
    mov fs:vfsrq_next,bx
    jne rqSignal
;    
    mov ds:vfs_req_list,0

rqSignal:
    inc cx
    mov bx,es:vfsrq_thread
    Signal
    FreeMem
    jmp rqRetry

rqDone:
    pop ebp
    pop ebx
    pop fs
    pop es    
    ret
RemoveReq Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateBuffer
;
;       DESCRIPTION:    Create buffer
;
;       PARAMETERS:     DS      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateBuffer:near

CreateBuffer    Proc near
    mov eax,ds:vfs_buf_count
    shl eax,2
    add eax,OFFSET vfs_buf_arr
    AllocateSmallLinear
    mov edi,edx
;
    mov bx,ds
    GetSelectorBaseSize
    mov esi,edx
;
    push esi
    push edi
;
    mov ax,flat_sel
    mov es,ax
    mov ecx,OFFSET vfs_buf_arr
    rep movs byte ptr es:[edi],es:[esi]
;
    pop edi
    pop esi
;
    mov edx,esi
    mov ecx,OFFSET vfs_buf_arr
    FreeLinear
;
    mov ecx,es:[edi].vfs_buf_count
    shl ecx,2
    add ecx,OFFSET vfs_buf_arr
    mov edx,edi
    CreateDataSelector32
    mov ds,bx
    mov es,bx
;
    mov ecx,ds:vfs_buf_count
    mov edi,OFFSET vfs_buf_arr
    xor eax,eax
    rep stos dword ptr es:[edi]
    ret
CreateBuffer   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateEntry
;
;       DESCRIPTION:    Create entry
;
;       PARAMETERS:     ES        Serv flat sel
;
;       RETURNS:        EAX       Entry linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEntry    Proc near
    push ecx
    push edx
    push edi
;
    mov eax,5000h
    AllocateBigServ
;
    mov edi,edx
    mov ecx,5 * 400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov eax,edx
;
    pop edi
    pop edx
    pop ecx
    ret
CreateEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateBufEntry
;
;       DESCRIPTION:    Create
;
;       PARAMETERS:     ES        Serv flat sel
;
;       RETURNS:        EAX       Entry linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBufEntry    Proc near
    push ds
    push ecx
    push edx
    push edi
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:zero_page_section
    mov cx,ds:zero_page_count
    or cx,cx
    jz cbfeAlloc
;
    mov di,cx
    dec di
    shl di,2
    mov eax,ds:[di].zero_page_arr
    dec ds:zero_page_count
    LeaveSection ds:zero_page_section
    jmp cbfeDone

cbfeAlloc:
    LeaveSection ds:zero_page_section
;
    mov eax,1000h
    AllocateBigServ
;
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov eax,edx

cbfeDone:
    pop edi
    pop edx
    pop ecx
    pop ds
    ret
CreateBufEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeBufEntry
;
;       DESCRIPTION:    Free
;
;       PARAMETERS:     ES        Serv flat sel
;                       EAX       Entry linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBufEntry    Proc near
    push ds
    push ecx
    push edx
    push edi
;
    and ax,0F000h
    mov cx,SEG data
    mov ds,cx
    EnterSection ds:zero_page_section
    mov cx,ds:zero_page_count
    cmp cx,MAX_PAGE_COUNT
    je fbfeFree
;
    mov di,cx
    shl di,2
    mov ds:[di].zero_page_arr,eax
    inc ds:zero_page_count
    LeaveSection ds:zero_page_section
    jmp fbfeDone

fbfeFree:
    LeaveSection ds:zero_page_section
;
    mov edx,eax
    mov ecx,1000h
    FreeBigServ

fbfeDone:
    pop edi
    pop edx
    pop ecx
    pop ds
    ret
FreeBufEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateBitmapEntry
;
;       DESCRIPTION:    Create
;
;       PARAMETERS:     ES        Serv flat sel
;
;       RETURNS:        EAX       Entry linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBitmapEntry    Proc near
    push ds
    push ecx
    push edx
    push edi
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:bitmap_section
    mov cx,ds:bitmap_count
    or cx,cx
    jz cbeAlloc
;
    mov di,cx
    dec di
    shl di,2
    mov eax,ds:[di].bitmap_arr
    dec ds:bitmap_count
    LeaveSection ds:bitmap_section
    jmp cbeDone

cbeAlloc:
    LeaveSection ds:bitmap_section
;
    mov eax,4000h
    AllocateBigServ
;
    mov edi,edx
    mov ecx,4 * 400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov eax,edx

cbeDone:
    pop edi
    pop edx
    pop ecx
    pop ds
    ret
CreateBitmapEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeBitmapEntry
;
;       DESCRIPTION:    Free
;
;       PARAMETERS:     ES        Serv flat sel
;                       EAX       Entry linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBitmapEntry    Proc near
    push ds
    push ecx
    push edx
    push edi
;
    and ax,0F000h
    mov cx,SEG data
    mov ds,cx
    EnterSection ds:bitmap_section
    mov cx,ds:bitmap_count
    cmp cx,MAX_BITMAP_COUNT
    je fbeFree
;
    mov di,cx
    shl di,2
    mov ds:[di].bitmap_arr,eax
    inc ds:bitmap_count
    LeaveSection ds:bitmap_section
    jmp fbeDone

fbeFree:
    LeaveSection ds:bitmap_section
;
    mov edx,eax
    mov ecx,1000h
    FreeBigServ

fbeDone:
    pop edi
    pop edx
    pop ecx
    pop ds
    ret
FreeBitmapEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SectorCountToBlock
;
;       DESCRIPTION:    Converts between sector & count # and block #
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Sector #
;                       ECX         Sector count
;
;       RETURNS:        NC
;                         EDX:EAX   Block #
;                         ECX       Block count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SectorCountToBlock

SectorCountToBlock    Proc near
    push ebx
    push ebp
;
    mov ebp,ecx
;
    cmp edx,ds:vfs_sectors+4
    jb sctbInRange
    ja sctbFail
;
    cmp eax,ds:vfs_sectors
    jb sctbInRange

sctbFail:
    stc
    jmp sctbDone

sctbInRange:
    mov cl,3
    sub cl,ds:vfs_sector_shift
    mov bx,1
    shl bx,cl
    dec bx
    and bl,al
    jz sctbCountOk

cstbLoop:
    inc ebp
    dec eax
    sub bl,1
    jnz cstbLoop

sctbCountOk:
    dec ebp
    shr ebp,cl
    inc ebp
;
    mov cl,ds:vfs_sector_shift
    or cl,cl
    jz sctbOk

sctbShift:
    add eax,eax
    adc edx,edx
;
    sub cl,1
    jnz sctbShift

sctbOk:
    mov ecx,ebp
    clc

sctbDone:
    pop ebp
    pop ebx
    ret
SectorCountToBlock   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsSectorCountAligned
;
;       DESCRIPTION:    Check if sector & count is aligned
;
;       PARAMETERS:     DS          VFS sel
;                       EDX:EAX     Sector #
;                       ECX         Sector count
;
;       RETURNS:        NC          Aligned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public IsSectorCountAligned

IsSectorCountAligned    Proc near
    push eax
    push ebx
    push ecx
    push ebp
;
    mov ebp,ecx
;
    cmp edx,ds:vfs_sectors+4
    jb iscaInRange
    ja iscaFail
;
    cmp eax,ds:vfs_sectors
    jae iscaFail

iscaInRange:
    mov cl,3
    sub cl,ds:vfs_sector_shift
    mov bx,1
    shl bx,cl
    dec bx
    mov bh,bl
    and bl,al
    jnz iscaFail
;
    mov eax,ebp
    and bh,al
    jnz iscaFail
;
    clc
    jmp iscaDone

iscaFail:
    stc

iscaDone:
    pop ebp
    pop ecx
    pop ebx
    pop eax
    ret
IsSectorCountAligned   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SectorToBlock
;
;       DESCRIPTION:    Converts between sector # and block #
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Sector #
;
;       RETURNS:        NC
;                         EDX:EAX   Block #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SectorToBlock

SectorToBlock    Proc near
    push cx
;
    cmp edx,ds:vfs_sectors+4
    jb stbInRange
    ja stbFail
;
    cmp eax,ds:vfs_sectors
    jb stbInRange

stbFail:
    stc
    jmp stbDone

stbInRange:
    mov cl,ds:vfs_sector_shift
    or cl,cl
    jz stbOk

stbShift:
    add eax,eax
    adc edx,edx
;
    sub cl,1
    jnz stbShift

stbOk:
    clc

stbDone:
    pop cx
    ret
SectorToBlock   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BlockToSector
;
;       DESCRIPTION:    Converts between block # and sector #
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Block #
;
;       RETURNS:        NC
;                         EDX:EAX   Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BlockToSector    Proc near
    push cx
;
    mov cl,ds:vfs_sector_shift
    or cl,cl
    jz btsOk

btsShift:
    clc
    rcr edx,1
    rcr eax,1
;
    sub cl,1
    jnz btsShift

btsOk:
    clc

btsDone:
    pop cx
    ret
BlockToSector   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RelSectorToBlock
;
;       DESCRIPTION:    Convert from relative sectors to block selector
;
;       PARAMETERS:     FS                 Part sel
;                       ES:EDI             Relative sector data
;                       ECX                Entries
;
;       RETURNS:        ECX                Entries
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RelSectorToBlock

RelSectorToBlock  Proc near
    push ds
    push gs
    push eax
    push ebx
    push edx
    push esi
;
    push ecx
;
    mov ebx,ecx
    mov gs,fs:vfsp_disc_sel
    mov cl,gs:vfs_sector_shift
;
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    sub eax,fs:vfsp_sector_count
    sbb edx,fs:vfsp_sector_count+4
    jb rstbInit
;
    int 3

rstbInit:
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    add eax,fs:vfsp_start_sector
    adc edx,fs:vfsp_start_sector+4
;
    or cl,cl
    jz rstbInitOk

rstbInitShift:
    add eax,eax
    adc edx,edx
;
    sub ebp,1
    jnz rstbInitShift

rstbInitOk:
    mov ds:[esi],eax
    mov ds:[esi+4],edx
    add esi,8
    sub ebx,1
    jz rstbDone
;

rstbLoop:
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    sub eax,fs:vfsp_sector_count
    sbb edx,fs:vfsp_sector_count+4
    jb rstbConv
;
    int 3

rstbConv:
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    add eax,fs:vfsp_start_sector
    adc edx,fs:vfsp_start_sector+4
;
    or cl,cl
    jz rstbBlockOk

rstbBlockShift:
    add eax,eax
    adc edx,edx
;
    sub cl,1
    jnz rstbBlockShift

rstbBlockOk:
    mov ds:[esi],eax
    mov ds:[esi+4],edx
;
    test al,7
    jz rstbNext
;
    sub eax,es:[esi-8]
    sbb edx,es:[esi-4]
    jnz rstbDone
;
    shr eax,cl
    cmp eax,1
    jne rstbDone

rstbNext:
    add esi,8
    sub ebx,1
    jnz rstbLoop

rstbDone:
    pop ecx
    sub ecx,ebx
;
    pop esi
    pop edx
    pop ebx
    pop eax
    pop gs
    pop ds
    ret
RelSectorToBlock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsBlockCached
;
;       DESCRIPTION:    Check if block is cached
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Block #
;
;       RETURNS:        NC
;                         ESI       Physical entry buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public IsBlockCached

IsBlockCached    Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    mov esi,eax
    mov ebx,edx
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    jnz ibcEntryOk
;
    call CreateEntry
    or ax,VFS_BUF_PRESENT
    mov ds:[ebx].vfs_buf_arr,eax

ibcEntryOk:
    and ax,0F000h
;
    mov ebx,esi
    shr ebx,20
    and ebx,0FFCh
    add ebx,eax
    mov eax,es:[ebx]
    or eax,eax
    jnz ibcBufPtr
;
    call CreateBufEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

ibcBufPtr:
    and ax,0F000h
;
    mov ebx,esi
    shr ebx,10
    and ebx,0FFCh
    add ebx,eax
    mov eax,es:[ebx]
    or eax,eax
    jnz ibcBufDir
;
    call CreateBufEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

ibcBufDir:
    and ax,0F000h
    and esi,0FF8h
    add esi,eax
    test es:[esi].vfsp_flags,VFS_PHYS_PRESENT
    stc
    jz ibcDone
;
    clc

ibcDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
IsBlockCached   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BlockToBuf
;
;       DESCRIPTION:    Converts between block # and physical address
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Block #
;
;       RETURNS:        NC
;                         ESI       Physical entry buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public BlockToBuf

BlockToBuf    Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    mov esi,eax
    mov ebx,edx
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    jnz btbEntryOk
;
    call CreateEntry
    or ax,VFS_BUF_PRESENT
    mov ds:[ebx].vfs_buf_arr,eax

btbEntryOk:
    and ax,0F000h
;
    mov ebx,esi
    shr ebx,20
    and ebx,0FFCh
    add ebx,eax
    mov eax,es:[ebx]
    or eax,eax
    jnz btbBufPtr
;
    call CreateBufEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

btbBufPtr:
    and ax,0F000h
;
    mov ebx,esi
    shr ebx,10
    and ebx,0FFCh
    add ebx,eax
    mov eax,es:[ebx]
    or eax,eax
    jnz btbBufDir
;
    call CreateBufEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

btbBufDir:
    and ax,0F000h
    and esi,0FF8h
    add esi,eax
    test es:[esi].vfsp_flags,VFS_PHYS_PRESENT
    jnz btbOk
;
    movzx ebx,ds:vfs_sectors_per_block
    add ds:vfs_active_count,ebx
;
    AllocatePhysical64
    mov es:[esi],eax
    mov es:[esi+4],ebx
    or es:[esi].vfsp_flags,VFS_PHYS_PRESENT
;
    inc ds:vfs_cached_pages
    mov eax,ds:vfs_cached_pages
    cmp eax,ds:vfs_max_cached_pages
    jne btbOk
;
    mov bx,ds:vfs_cmd_thread
    Signal

btbOk:
    or es:[esi].vfsp_flags,VFS_PHYS_USED
    clc

btbDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
BlockToBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DisableBuf
;
;       DESCRIPTION:    Disable physical entry
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       AX          Lock count
;                       ESI         Physical entry buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DisableBuf

DisableBuf    Proc near
    push eax
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz dbDone
;
    sub es:[esi].vfsp_ref_bitmap,ax
    jnz dbDone
;
    xor eax,eax
    mov es:[esi],eax
    mov es:[esi+4],eax
    dec ds:vfs_cached_pages
    dec ds:vfs_locked_pages

dbDone:
    pop eax
    ret
DisableBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ZeroPhysBuf
;
;       DESCRIPTION:    Zero physical buffer
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       ESI         Physical entry buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ZeroPhysBuf

ZeroPhysBuf    Proc near
    push es
    pushad
;
    mov eax,1000h
    AllocateBigLinear
    mov eax,es:[esi]
    mov ebx,es:[esi+4]
    and ax,0F000h
    or ax,813h
    SetPageEntry
;
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
    mov ecx,400h
    xor eax,eax
    rep stosd
;
    mov ecx,1000h
    FreeLinear
;
    popad
    pop es
    ret
ZeroPhysBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BlockToBitmap
;
;       DESCRIPTION:    Converts between block and bitmap
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Block #
;
;       RETURNS:        NC
;                         EDI       Bitmap buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public BlockToBitmap

BlockToBitmap    Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    mov ecx,eax
    mov ebx,edx
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    jnz btmEntryOk
;
    call CreateEntry
    or ax,VFS_BUF_PRESENT
    mov ds:[ebx].vfs_buf_arr,eax

btmEntryOk:
    mov ebx,ecx
    shr ebx,18
    and ebx,3FFCh
    and ax,0F000h
    add ebx,eax
    add ebx,1000h
    mov eax,es:[ebx]
    or eax,eax
    jnz btmBufPtr
;
    call CreateBitmapEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

btmBufPtr:
    and ax,0F000h
    mov edi,eax

btmDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
BlockToBitmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddToBitmap
;
;       DESCRIPTION:    Add req to bitmap
;
;       PARAMETERS:     DS          VFS sel
;                       EDX:EAX     Block #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddToBitmap

AddToBitmap   Proc near
    push ebx
    push ecx
    push edi
;
    push eax
    mov ecx,eax
    mov ebx,edx
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    jnz atbEntryOk
;
    call CreateEntry
    or ax,VFS_BUF_PRESENT
    mov ds:[ebx].vfs_buf_arr,eax

atbEntryOk:
    mov ebx,ecx
    shr ebx,18
    and ebx,3FFCh
    and ax,0F000h
    add ebx,eax
    add ebx,1000h
    mov eax,es:[ebx]
    or eax,eax
    jnz atbBufPtr
;
    call CreateBitmapEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

atbBufPtr:
    and ax,0F000h
    mov edi,eax
    pop eax
;
    mov ebx,eax
    shr ebx,3
    and ebx,1FFFFh
    bts es:[edi],ebx
;
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc srrDone
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

srrDone:
    pop edi
    pop ecx
    pop ebx
    ret
AddToBitmap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateWrBitmap
;
;       DESCRIPTION:    Update write bitmap
;
;       PARAMETERS:     DS          VFS sel
;                       BL          Sector mask
;                       EDX:EAX     Block #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UpdateWrBitmap

CountTab:
c00000000 DB 0
c00000001 DB 1
c00000010 DB 1
c00000011 DB 2
c00000100 DB 1
c00000101 DB 2
c00000110 DB 2
c00000111 DB 3
c00001000 DB 1
c00001001 DB 2
c00001010 DB 2
c00001011 DB 3
c00001100 DB 2
c00001101 DB 3
c00001110 DB 3
c00001111 DB 4
c00010000 DB 1
c00010001 DB 2
c00010010 DB 2
c00010011 DB 3
c00010100 DB 2
c00010101 DB 3
c00010110 DB 3
c00010111 DB 4
c00011000 DB 2
c00011001 DB 3
c00011010 DB 3
c00011011 DB 4
c00011100 DB 3
c00011101 DB 4
c00011110 DB 4
c00011111 DB 5
c00100000 DB 1
c00100001 DB 2
c00100010 DB 2
c00100011 DB 3
c00100100 DB 2
c00100101 DB 3
c00100110 DB 3
c00100111 DB 4
c00101000 DB 2
c00101001 DB 3
c00101010 DB 3
c00101011 DB 4
c00101100 DB 3
c00101101 DB 4
c00101110 DB 4
c00101111 DB 5
c00110000 DB 2
c00110001 DB 3
c00110010 DB 3
c00110011 DB 4
c00110100 DB 3
c00110101 DB 4
c00110110 DB 4
c00110111 DB 5
c00111000 DB 3
c00111001 DB 4
c00111010 DB 4
c00111011 DB 5
c00111100 DB 4
c00111101 DB 5
c00111110 DB 5
c00111111 DB 6
c01000000 DB 1
c01000001 DB 2
c01000010 DB 2
c01000011 DB 3
c01000100 DB 2
c01000101 DB 3
c01000110 DB 3
c01000111 DB 4
c01001000 DB 2
c01001001 DB 3
c01001010 DB 3
c01001011 DB 4
c01001100 DB 3
c01001101 DB 4
c01001110 DB 4
c01001111 DB 5
c01010000 DB 2
c01010001 DB 3
c01010010 DB 3
c01010011 DB 4
c01010100 DB 3
c01010101 DB 4
c01010110 DB 4
c01010111 DB 5
c01011000 DB 3
c01011001 DB 4
c01011010 DB 4
c01011011 DB 5
c01011100 DB 4
c01011101 DB 5
c01011110 DB 5
c01011111 DB 6
c01100000 DB 2
c01100001 DB 3
c01100010 DB 3
c01100011 DB 4
c01100100 DB 3
c01100101 DB 4
c01100110 DB 4
c01100111 DB 5
c01101000 DB 3
c01101001 DB 4
c01101010 DB 4
c01101011 DB 5
c01101100 DB 4
c01101101 DB 5
c01101110 DB 5
c01101111 DB 6
c01110000 DB 3
c01110001 DB 4
c01110010 DB 4
c01110011 DB 5
c01110100 DB 4
c01110101 DB 5
c01110110 DB 5
c01110111 DB 6
c01111000 DB 4
c01111001 DB 5
c01111010 DB 5
c01111011 DB 6
c01111100 DB 5
c01111101 DB 6
c01111110 DB 6
c01111111 DB 7
c10000000 DB 1
c10000001 DB 2
c10000010 DB 2
c10000011 DB 3
c10000100 DB 2
c10000101 DB 3
c10000110 DB 3
c10000111 DB 4
c10001000 DB 2
c10001001 DB 3
c10001010 DB 3
c10001011 DB 4
c10001100 DB 3
c10001101 DB 4
c10001110 DB 4
c10001111 DB 5
c10010000 DB 2
c10010001 DB 3
c10010010 DB 3
c10010011 DB 4
c10010100 DB 3
c10010101 DB 4
c10010110 DB 4
c10010111 DB 5
c10011000 DB 3
c10011001 DB 4
c10011010 DB 4
c10011011 DB 5
c10011100 DB 4
c10011101 DB 5
c10011110 DB 5
c10011111 DB 6
c10100000 DB 2
c10100001 DB 3
c10100010 DB 3
c10100011 DB 4
c10100100 DB 3
c10100101 DB 4
c10100110 DB 4
c10100111 DB 5
c10101000 DB 3
c10101001 DB 4
c10101010 DB 4
c10101011 DB 5
c10101100 DB 4
c10101101 DB 5
c10101110 DB 5
c10101111 DB 6
c10110000 DB 3
c10110001 DB 4
c10110010 DB 4
c10110011 DB 5
c10110100 DB 4
c10110101 DB 5
c10110110 DB 5
c10110111 DB 6
c10111000 DB 4
c10111001 DB 5
c10111010 DB 5
c10111011 DB 6
c10111100 DB 5
c10111101 DB 6
c10111110 DB 6
c10111111 DB 7
c11000000 DB 2
c11000001 DB 3
c11000010 DB 3
c11000011 DB 4
c11000100 DB 3
c11000101 DB 4
c11000110 DB 4
c11000111 DB 5
c11001000 DB 3
c11001001 DB 4
c11001010 DB 4
c11001011 DB 5
c11001100 DB 4
c11001101 DB 5
c11001110 DB 5
c11001111 DB 6
c11010000 DB 3
c11010001 DB 4
c11010010 DB 4
c11010011 DB 5
c11010100 DB 4
c11010101 DB 5
c11010110 DB 5
c11010111 DB 6
c11011000 DB 4
c11011001 DB 5
c11011010 DB 5
c11011011 DB 6
c11011100 DB 5
c11011101 DB 6
c11011110 DB 6
c11011111 DB 7
c11100000 DB 3
c11100001 DB 4
c11100010 DB 4
c11100011 DB 5
c11100100 DB 4
c11100101 DB 5
c11100110 DB 5
c11100111 DB 6
c11101000 DB 4
c11101001 DB 5
c11101010 DB 5
c11101011 DB 6
c11101100 DB 5
c11101101 DB 6
c11101110 DB 6
c11101111 DB 7
c11110000 DB 4
c11110001 DB 5
c11110010 DB 5
c11110011 DB 6
c11110100 DB 5
c11110101 DB 6
c11110110 DB 6
c11110111 DB 7
c11111000 DB 5
c11111001 DB 6
c11111010 DB 6
c11111011 DB 7
c11111100 DB 6
c11111101 DB 7
c11111110 DB 7
c11111111 DB 8

UpdateWrBitmap   Proc near
    push ebx
    push ecx
    push esi
    push edi
    push ebp
;
    push eax
    push ebx
;
    mov esi,eax
    mov ebx,edx
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    jnz uwbEntryOk
;
    call CreateEntry
    or ax,VFS_BUF_PRESENT
    mov ds:[ebx].vfs_buf_arr,eax

uwbEntryOk:
    mov ebp,eax
    and ax,0F000h
;
    mov ebx,esi
    shr ebx,20
    and ebx,0FFCh
    add ebx,eax
    mov eax,es:[ebx]
    or eax,eax
    jnz uwbBufPtr
;
    call CreateBufEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

uwbBufPtr:
    and ax,0F000h
;
    mov ebx,esi
    shr ebx,10
    and ebx,0FFCh
    add ebx,eax
    mov eax,es:[ebx]
    or eax,eax
    jnz uwbBufDir
;
    call CreateBufEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

uwbBufDir:
    and ax,0F000h
    and esi,0FF8h
    add esi,eax
;
    pop ebx
    pop eax
;
    push eax
    push ecx
;
    test es:[esi].vfsp_flags,VFS_PHYS_PRESENT
    jnz uwbValid
;
    int 3

uwbValid:
    mov al,es:[esi].vfsp_wr_bitmap
    and al,bl
    xor al,bl
;
    or es:[esi].vfsp_wr_bitmap,bl
;
    movzx eax,al
    mov al,byte ptr cs:[eax].CountTab
;
    mov cl,ds:vfs_sector_shift
    shr al,cl
;
    movzx eax,al
    add ds:vfs_active_count,eax
;
    pop ecx
    pop eax
;
    push eax
    mov ebx,eax
    mov eax,ebp
    shr ebx,18
    and ebx,3FFCh
    and ax,0F000h
    add ebx,eax
    add ebx,1000h
    mov eax,es:[ebx]
    or eax,eax
    jnz uwbBitmapPtr
;
    call CreateBitmapEntry
    or ax,VFS_BUF_PRESENT
    mov es:[ebx],eax

uwbBitmapPtr:
    and ax,0F000h
    mov edi,eax
    pop eax
;
    mov ebx,eax
    shr ebx,3
    and ebx,1FFFFh
    bts es:[edi],ebx
;
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc uwbDone
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

uwbDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
UpdateWrBitmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InvalidateCache
;
;       DESCRIPTION:    Invalidate cache entries
;
;       PARAMETERS:     DS          VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InvalidateCache

InvalidateCache    Proc near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov cx,serv_flat_sel
    mov es,cx
;
    EnterSection ds:vfs_section

icSearch:
    mov ebx,ds:vfs_cache_discard_pos+4
    cmp ebx,ds:vfs_buf_count
    jae icBufRestart
;
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    jnz icEntryOk

icNextMsb:
    inc ds:vfs_cache_discard_pos+4
    jmp icSearch

icBufRestart:
    mov ds:vfs_cache_discard_pos,0
    mov ds:vfs_cache_discard_pos+4,0
    jmp icSearch

icEntryOk:
    and ax,0F000h
;
    mov ebx,ds:vfs_cache_discard_pos
    shr ebx,20
    and ebx,0FFCh
    mov esi,ebx
    add esi,eax
    mov eax,es:[esi]
    or eax,eax
    jnz icBufPtrCont

icEntryLoop:
    add ebx,4
    add esi,4
    test esi,0FFFh
    jz icNextMsb

icEntryNext:
    mov eax,es:[esi]
    or eax,eax
    jz icEntryLoop
;
    shl ebx,20
    mov ds:vfs_cache_discard_pos,ebx

icBufPtrCont:
    and ax,0F000h
    mov ebx,ds:vfs_cache_discard_pos
    shr ebx,10
    and ebx,0FFCh
    mov ebp,ebx
    mov esi,ebx
    add esi,eax
    mov eax,es:[esi]
    or eax,eax
    jnz icBufDirCont

icBufPtrLoop:
    add ebx,4
    add esi,4
    test esi,0FFFh
    jnz icBufPtrNext
;
    shl ebx,10
    mov eax,ds:vfs_cache_discard_pos
    and eax,0FFC00000h
    add ebx,eax
    mov ds:vfs_cache_discard_pos,ebx
    pushf
;
    or ebp,ebp
    jnz icBufPtrMsb
;
    mov ebx,ds:vfs_cache_discard_pos+4
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    and ax,0F000h
;
    mov ebx,ds:vfs_cache_discard_pos
    shr ebx,20
    and ebx,0FFCh
    sub ebx,4
    mov esi,ebx
    add esi,eax
    xor eax,eax
    xchg eax,es:[esi]
    and ax,0F000h
    call FreeBufEntry

icBufPtrMsb:
    popf
    adc ds:vfs_cache_discard_pos+4,0
    jmp icSearch

icBufPtrNext:
    mov eax,es:[esi]
    or eax,eax
    jz icBufPtrLoop
;
    shl ebx,10
    mov ecx,ds:vfs_cache_discard_pos
    and ecx,0FFC00000h
    add ebx,ecx
    mov ds:vfs_cache_discard_pos,ebx

icBufDirCont:
    xor ebp,ebp
    and ax,0F000h
    mov esi,eax
;
    mov ecx,512

icLoop:
    test es:[esi].vfsp_flags,VFS_PHYS_PRESENT
    jz icNext
;
    inc ebp
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz icNext
;
    cmp es:[esi].vfsp_ref_bitmap,0
    jne icNext
;
    cmp es:[esi].vfsp_wr_bitmap,0
    jne icNext
;
    btr es:[esi].vfsp_flags,VFS_PHYS_USED_BIT
    jc icNext
;
    xor eax,eax
    xchg eax,es:[esi]
    xor ebx,ebx
    xchg ebx,es:[esi+4]
    and ax,0F000h
    FreePhysical
    dec ds:vfs_cached_pages

icNext:
    add esi,8
    loop icLoop
;
    or ebp,ebp
    jnz icLeave
;
    mov ebx,ds:vfs_cache_discard_pos+4
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    and ax,0F000h
;
    mov ebx,ds:vfs_cache_discard_pos
    shr ebx,20
    and ebx,0FFCh
    mov esi,ebx
    add esi,eax
    mov eax,es:[esi]
    and ax,0F000h
;
    mov ebx,ds:vfs_cache_discard_pos
    shr ebx,10
    and ebx,0FFCh
    mov esi,ebx
    add esi,eax
    xor eax,eax
    xchg eax,es:[esi]
    and ax,0F000h
    call FreeBufEntry

icLeave:
    add ds:vfs_cache_discard_pos,1000h
    adc ds:vfs_cache_discard_pos+4,0
;        
    LeaveSection ds:vfs_section

icDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
InvalidateCache    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetIoStart
;
;       DESCRIPTION:    Get IO start position
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;
;       RETURNS:        NC
;                         EDX:EAX   Block #
;                         EDI       Bitmap buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIoStart    Proc near
    xor ebp,ebp

gisEntryLoop:
    mov ebx,ds:vfs_scan_pos+4
    cmp ebx,ds:vfs_buf_count
    jb gisEntryRangeOk
;
    mov ds:vfs_scan_pos,0
    mov ds:vfs_scan_pos+4,0
    mov ebx,ds:vfs_scan_pos+4

gisEntryRangeOk:
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    jz gisNextEntry
;
    mov ebx,ds:vfs_scan_pos
    shr ebx,18
    and ebx,3FFCh
    mov esi,ebx
    shl esi,18
    mov ecx,4000h
    sub ecx,ebx
    shr ecx,2
;
    and ax,0F000h
    add ebx,eax
    add ebx,1000h

gisPtrLoop:
    mov eax,es:[ebx]
    or eax,eax
    jnz gisPtrScan
;
    add esi,1 SHL 20
    jmp gisPtrNext

gisPtrScan:
    push ecx
;
    and ax,0F000h
    mov edi,eax
;
    mov eax,ds:vfs_scan_pos
    shr eax,6
    and eax,3FFCh
    mov ecx,4000h
    sub ecx,eax
    shr ecx,2
    add edi,eax
    shl eax,6
    add esi,eax
    mov eax,es:[edi]
    or eax,eax
    jz gisScan
;
    push ecx
    mov ecx,ds:vfs_scan_pos
    shr ecx,3
    and ecx,1Fh
    shr eax,cl
    or eax,eax
    jz gisScanAdv
;
    shl ecx,3
    add esi,ecx
    bsf ecx,eax
    shl ecx,3
    add esi,ecx
;
    mov eax,esi
    mov edx,ds:vfs_scan_pos+4
;
    pop ecx
    pop ecx
    clc
    jmp gisDone

gisScanAdv:
    pop ecx

gisScan:
    add esi,1 SHL 8
    add edi,4
    sub ecx,1
    jz gisScanDone
;
    mov edx,ecx
    xor eax,eax
    repz scas dword ptr es:[edi]
    jz gisScanFixup
;
    sub edx,ecx
    dec edx
    shl edx,8
    add esi,edx
;
    sub edi,4
    mov eax,es:[edi]
    bsf ecx,eax
    shl ecx,3
    add esi,ecx
;
    mov eax,esi
    mov edx,ds:vfs_scan_pos+4
;
    pop ecx
    clc
    jmp gisDone

gisScanFixup:
    shl edx,8
    add esi,edx
;
    mov eax,ds:vfs_scan_pos
    and eax,0FFFFFh
    jnz gisScanDone
;
    xor eax,eax
    xchg eax,es:[ebx]
    call FreeBitmapEntry

gisScanDone:
    pop ecx

gisPtrNext:
    mov ds:vfs_scan_pos,esi
    add ebx,4
    sub ecx,1
    jnz gisPtrLoop

gisNextEntry:
    mov ds:vfs_scan_pos,0
    mov ecx,ds:vfs_scan_pos+4
    inc ecx
    mov ds:vfs_scan_pos+4,ecx
    cmp ecx,ds:vfs_buf_count
    jb gisEntryLoop
;
    or ebp,ebp
    stc
    jnz gisDone
;
    inc ebp
    mov ds:vfs_scan_pos+4,0
    jmp gisEntryLoop
    
gisDone:
    ret
GetIoStart   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetIoBuf
;
;       DESCRIPTION:    Get start IO buf
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Block #
;
;       RETURNS:        NC
;                         ESI       Physical entry buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIoBuf    Proc near
    push eax
    push edx
;
    mov esi,eax
    mov ebx,edx
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    stc
    jz gibDone
;
    and ax,0F000h
;
    mov ebx,esi
    shr ebx,20
    and ebx,0FFCh
    add ebx,eax
    mov eax,es:[ebx]
    or eax,eax
    stc
    jz gibDone
;
    and ax,0F000h
;
    mov ebx,esi
    shr ebx,10
    and ebx,0FFCh
    add ebx,eax
    mov eax,es:[ebx]
    or eax,eax
    stc
    jz gibDone
;
    and ax,0F000h
    and esi,0FF8h
    add esi,eax
    clc

gibDone:
    pop edx
    pop eax
    ret
GetIoBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetReadIo
;
;       DESCRIPTION:    Get number of read sectors
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       ESI         Physical entry buf
;
;       RETURNS:        ECX         Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetReadIo    Proc near
    push eax
    push edx
    push esi
;
    mov fs,ds:vfs_req_buf
    xor ecx,ecx
    xor edx,edx
  
griBlockLoop:
    mov bp,ds:vfs_sectors_per_block
    movzx ebx,word ptr es:[esi+4]
    mov eax,es:[esi]
    and ax,0F000h

griSave:    
    mov fs:[edx],eax
    mov fs:[edx+4],ebx
    add ax,ds:vfs_bytes_per_sector
    add edx,8
    inc cx
    sub bp,1
    jnz griSave
;
    cmp cx,ds:vfs_max_req
    jae griDone
;
    add esi,8
    test si,0FFFh
    jz griDone
;
    test es:[esi].vfsp_flags,VFS_PHYS_PRESENT
    jz griDone
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz griBlockLoop

griDone:
    pop esi
    pop edx
    pop eax
    ret
GetReadIo   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetWriteIo
;
;       DESCRIPTION:    Get number of write sectors
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       BL          Sector count in first block
;                       BH          Start sector in first block
;                       ESI         Physical entry buf
;
;       RETURNS:        ECX         Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SizeBaseTab:
t00000000 DB 00h
t00000001 DB 01h
t00000010 DB 11h
t00000011 DB 02h
t00000100 DB 21h
t00000101 DB 03h
t00000110 DB 12h
t00000111 DB 03h
t00001000 DB 31h
t00001001 DB 04h
t00001010 DB 13h
t00001011 DB 04h
t00001100 DB 22h
t00001101 DB 04h
t00001110 DB 13h
t00001111 DB 04h
t00010000 DB 41h
t00010001 DB 05h
t00010010 DB 14h
t00010011 DB 05h
t00010100 DB 23h
t00010101 DB 05h
t00010110 DB 14h
t00010111 DB 05h
t00011000 DB 32h
t00011001 DB 05h
t00011010 DB 14h
t00011011 DB 05h
t00011100 DB 23h
t00011101 DB 05h
t00011110 DB 14h
t00011111 DB 05h
t00100000 DB 51h
t00100001 DB 06h
t00100010 DB 15h
t00100011 DB 06h
t00100100 DB 24h
t00100101 DB 06h
t00100110 DB 15h
t00100111 DB 06h
t00101000 DB 33h
t00101001 DB 06h
t00101010 DB 15h
t00101011 DB 06h
t00101100 DB 24h
t00101101 DB 06h
t00101110 DB 15h
t00101111 DB 06h
t00110000 DB 42h
t00110001 DB 06h
t00110010 DB 15h
t00110011 DB 06h
t00110100 DB 24h
t00110101 DB 06h
t00110110 DB 15h
t00110111 DB 06h
t00111000 DB 33h
t00111001 DB 06h
t00111010 DB 15h
t00111011 DB 06h
t00111100 DB 24h
t00111101 DB 06h
t00111110 DB 15h
t00111111 DB 06h
t01000000 DB 61h
t01000001 DB 07h
t01000010 DB 16h
t01000011 DB 07h
t01000100 DB 25h
t01000101 DB 07h
t01000110 DB 16h
t01000111 DB 07h
t01001000 DB 34h
t01001001 DB 07h
t01001010 DB 16h
t01001011 DB 07h
t01001100 DB 25h
t01001101 DB 07h
t01001110 DB 16h
t01001111 DB 07h
t01010000 DB 43h
t01010001 DB 07h
t01010010 DB 16h
t01010011 DB 07h
t01010100 DB 25h
t01010101 DB 07h
t01010110 DB 16h
t01010111 DB 07h
t01011000 DB 34h
t01011001 DB 07h
t01011010 DB 16h
t01011011 DB 07h
t01011100 DB 25h
t01011101 DB 07h
t01011110 DB 16h
t01011111 DB 07h
t01100000 DB 52h
t01100001 DB 07h
t01100010 DB 16h
t01100011 DB 07h
t01100100 DB 25h
t01100101 DB 07h
t01100110 DB 16h
t01100111 DB 07h
t01101000 DB 34h
t01101001 DB 07h
t01101010 DB 16h
t01101011 DB 07h
t01101100 DB 25h
t01101101 DB 07h
t01101110 DB 16h
t01101111 DB 07h
t01110000 DB 43h
t01110001 DB 07h
t01110010 DB 16h
t01110011 DB 07h
t01110100 DB 25h
t01110101 DB 07h
t01110110 DB 16h
t01110111 DB 07h
t01111000 DB 34h
t01111001 DB 07h
t01111010 DB 16h
t01111011 DB 07h
t01111100 DB 25h
t01111101 DB 07h
t01111110 DB 16h
t01111111 DB 07h
t10000000 DB 71h
t10000001 DB 08h
t10000010 DB 17h
t10000011 DB 08h
t10000100 DB 26h
t10000101 DB 08h
t10000110 DB 17h
t10000111 DB 08h
t10001000 DB 35h
t10001001 DB 08h
t10001010 DB 17h
t10001011 DB 08h
t10001100 DB 26h
t10001101 DB 08h
t10001110 DB 17h
t10001111 DB 08h
t10010000 DB 44h
t10010001 DB 08h
t10010010 DB 17h
t10010011 DB 08h
t10010100 DB 26h
t10010101 DB 08h
t10010110 DB 17h
t10010111 DB 08h
t10011000 DB 35h
t10011001 DB 08h
t10011010 DB 17h
t10011011 DB 08h
t10011100 DB 26h
t10011101 DB 08h
t10011110 DB 17h
t10011111 DB 08h
t10100000 DB 53h
t10100001 DB 08h
t10100010 DB 17h
t10100011 DB 08h
t10100100 DB 26h
t10100101 DB 08h
t10100110 DB 17h
t10100111 DB 08h
t10101000 DB 35h
t10101001 DB 08h
t10101010 DB 17h
t10101011 DB 08h
t10101100 DB 26h
t10101101 DB 08h
t10101110 DB 17h
t10101111 DB 08h
t10110000 DB 44h
t10110001 DB 08h
t10110010 DB 17h
t10110011 DB 08h
t10110100 DB 26h
t10110101 DB 08h
t10110110 DB 17h
t10110111 DB 08h
t10111000 DB 35h
t10111001 DB 08h
t10111010 DB 17h
t10111011 DB 08h
t10111100 DB 26h
t10111101 DB 08h
t10111110 DB 17h
t10111111 DB 08h
t11000000 DB 62h
t11000001 DB 08h
t11000010 DB 17h
t11000011 DB 08h
t11000100 DB 26h
t11000101 DB 08h
t11000110 DB 17h
t11000111 DB 08h
t11001000 DB 35h
t11001001 DB 08h
t11001010 DB 17h
t11001011 DB 08h
t11001100 DB 26h
t11001101 DB 08h
t11001110 DB 17h
t11001111 DB 08h
t11010000 DB 44h
t11010001 DB 08h
t11010010 DB 17h
t11010011 DB 08h
t11010100 DB 26h
t11010101 DB 08h
t11010110 DB 17h
t11010111 DB 08h
t11011000 DB 35h
t11011001 DB 08h
t11011010 DB 17h
t11011011 DB 08h
t11011100 DB 26h
t11011101 DB 08h
t11011110 DB 17h
t11011111 DB 08h
t11100000 DB 53h
t11100001 DB 08h
t11100010 DB 17h
t11100011 DB 08h
t11100100 DB 26h
t11100101 DB 08h
t11100110 DB 17h
t11100111 DB 08h
t11101000 DB 35h
t11101001 DB 08h
t11101010 DB 17h
t11101011 DB 08h
t11101100 DB 26h
t11101101 DB 08h
t11101110 DB 17h
t11101111 DB 08h
t11110000 DB 44h
t11110001 DB 08h
t11110010 DB 17h
t11110011 DB 08h
t11110100 DB 26h
t11110101 DB 08h
t11110110 DB 17h
t11110111 DB 08h
t11111000 DB 35h
t11111001 DB 08h
t11111010 DB 17h
t11111011 DB 08h
t11111100 DB 26h
t11111101 DB 08h
t11111110 DB 17h
t11111111 DB 08h

GetWriteIo    Proc near
    push eax
    push ebx
    push edx
    push esi
    push edi
;
    mov fs,ds:vfs_req_buf
    xor ecx,ecx
    xor edx,edx

gwiBlockLoop:
    movzx edi,bl
    sub ds:vfs_active_count,edi
    jnc gwiCountOk
;
    int 3

gwiCountOk:
    movzx edi,word ptr es:[esi+4]
    mov eax,es:[esi]
    and ax,0F000h
;
    push ecx
;
    push eax
    push edx
;
    movzx bp,bl
    and bp,0Fh
    mov ax,ds:vfs_bytes_per_sector
    movzx dx,bh
    mul dx
    mov cx,ax
;
    pop edx
    pop eax
;
    add ax,cx
    pop ecx

gwiSave:    
    mov fs:[edx],eax
    mov fs:[edx+4],edi
    add ax,ds:vfs_bytes_per_sector
    add edx,8
    inc cx
    sub bp,1
    jnz gwiSave
;
    cmp cx,ds:vfs_max_req
    jae gwiDone
;
    add bl,bh
    movzx bx,bl
    cmp bx,ds:vfs_sectors_per_block
    jne gwiDone
;
    add esi,8
    test si,0FFFh
    jz gwiDone
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz gwiDone
;
    xor bl,bl
    xchg bl,es:[esi].vfsp_wr_bitmap
    or bl,bl
    jz gwiDone
;
    movzx ebx,bl
    mov bl,byte ptr cs:[ebx].SizeBaseTab
    mov bh,bl
    and bh,0F0h
    jnz gwiDone
;
    push ecx
    and bl,0Fh
    mov cl,ds:vfs_sector_shift
    shr bl,cl
    pop ecx
    jmp gwiBlockLoop

gwiDone:
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret
GetWriteIo   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ClearIoBitmap
;
;       DESCRIPTION:    Clear IO bitmap
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       ECX         Sectors
;                       EDX:EAX     Block #
;                       EDI         Bitmap entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearIoBitmap    Proc near
    push ebx
    push ecx
;
    mov ds:vfs_scan_pos,eax
    add ds:vfs_scan_pos,ecx
;
    mov bx,ax
    and ebx,0FFh
    shr ebx,3

cibLoop:
    btr es:[edi],ebx
    inc ebx
    sub ecx,8
    ja cibLoop
;
    pop ecx
    pop ebx
    ret
ClearIoBitmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ClearCurrIoBitmap
;
;       DESCRIPTION:    Clear current IO bitmap
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Block #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearCurrIoBitmap    Proc near
    push eax
    push ebx
    push ecx
    push edi
;
    mov ebx,edx
    shl ebx,2
    mov edi,ds:[ebx].vfs_buf_arr
    or edi,edi
    jz ccibDone
;
    mov ebx,eax
    shr ebx,18
    and ebx,3FFCh
    mov ecx,4000h
    sub ecx,ebx
    shr ecx,2
;
    and di,0F000h
    add ebx,edi
    add ebx,1000h
;
    xor eax,eax
    xchg eax,es:[ebx]
    call FreeBitmapEntry
;
    mov ds:vfs_scan_pos,-1
    mov ds:vfs_scan_pos+4,-1

ccibDone:
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret
ClearCurrIoBitmap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyReadBuf
;
;       DESCRIPTION:    Notify read buffers
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Sector
;                       ESI         Physical entry buf
;                       ECX         Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyReadBuf    Proc near
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push ebp
;
    mov ebp,ecx
  
nrbLoop:
    xor cx,cx

    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz nrbOk
;
    CrashGate

nrbOk:
    or es:[esi].vfsp_flags,VFS_PHYS_VALID
    mov bx,es:[esi].vfsp_ref_bitmap
    or bx,bx
    jz nrbNext
;
    and bx,0FFFEh
    jz nrbPartOk
;
    call NotifyVfs

nrbPartOk:
    movzx ebx,ds:vfs_sectors_per_block
    sub ds:vfs_active_count,ebx
;
    mov bx,es:[esi].vfsp_ref_bitmap
    test bx,1
    jz nrbNext
;
    call RemoveReq

nrbNext:
    or cx,cx
    jz nrbLockedOK
;
    inc ds:vfs_locked_pages

nrbLockedOk:
    mov es:[esi].vfsp_ref_bitmap,cx
    add eax,8
    adc edx,0
    add esi,8
    sub bp,ds:vfs_sectors_per_block
    ja nrbLoop
;
    pop ebp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
NotifyReadBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleDiscReq
;
;       DESCRIPTION:    Handle disc req
;
;       PARAMETERS:     DS          VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleDiscReq

HandleDiscReq    Proc near
    mov ax,serv_flat_sel
    mov es,ax

hdLoop:
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc hdRetry
;
    and ds:vfs_flags,NOT VFS_FLAG_BUSY
    WaitForSignal
    or ds:vfs_flags,VFS_FLAG_BUSY

hdRetry:
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit
;
    EnterSection ds:vfs_section
;
    call GetIoStart
    jc hdLeave
;
    call GetIoBuf
    jc hdLeave
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz hdRead

hdWrite:
    xor bl,bl
    xchg bl,es:[esi].vfsp_wr_bitmap
    or bl,bl
    jz hdWriteDone
;
    movzx ebx,bl
    mov bl,byte ptr cs:[ebx].SizeBaseTab
    mov bh,bl
    and bh,0F0h
    shr bh,4
    and bl,0Fh
    mov cl,ds:vfs_sector_shift
    shr bl,cl
    shr bh,cl
    or al,bh
;
    call GetWriteIo
    call ClearIoBitmap
    call BlockToSector
    LeaveSection ds:vfs_section
;
    push es
    push edi
    mov es,ds:vfs_req_buf
    xor edi,edi
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_write
    pop edi
    pop es
    jc hdFail
;
    EnterSection ds:vfs_section
    jmp hdCheckMore

hdWriteDone:
    mov ecx,8
    call ClearIoBitmap
    LeaveSection ds:vfs_section
    jmp hdRetry

hdLeave:
    mov ds:vfs_scan_pos,-1
    mov ds:vfs_scan_pos+4,-1
    LeaveSection ds:vfs_section
    jmp hdLoop

hdRead:
    call GetReadIo
    call ClearIoBitmap
    call BlockToSector
    LeaveSection ds:vfs_section
;
    push es
    push edi
    mov es,ds:vfs_req_buf
    xor edi,edi
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_read
    pop edi
    pop es
    jc hdFail
;
    EnterSection ds:vfs_section
    call NotifyReadBuf

hdCheckMore:
    mov ebx,ds:vfs_active_count
    or ebx,ebx
    jnz hdMore
;
    call ClearCurrIoBitmap
    LeaveSection ds:vfs_section
    jmp hdLoop

hdMore:
    LeaveSection ds:vfs_section
    jmp hdRetry

hdFail:
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit
    jmp hdLoop

hdExit:
    ret
HandleDiscReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_buf
;
;       description:    Init buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_buf

init_buf    Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:bitmap_count,0
    InitSection ds:bitmap_section
;
    mov ds:zero_page_count,0
    InitSection ds:zero_page_section
;
    ret
init_buf    Endp

code    ENDS

    END
