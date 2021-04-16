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

data    SEGMENT byte public 'DATA'

bitmap_count    DW ?
bitmap_section  section_typ <>

bitmap_arr      DD MAX_BITMAP_COUNT DUP (?)

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
    push ecx
    push edx
    push edi
;
    mov eax,1000h
    AllocateBigServ
;
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov eax,edx
;
    pop edi
    pop edx
    pop ecx
    ret
CreateBufEntry    Endp

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
    int 3
    LeaveSection ds:bitmap_section

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
;       NAME:           LocalLockSector
;
;       DESCRIPTION:    Lock sector
;
;       PARAMETERS:     DS          VFS sel
;                       EDX:EAX     Sector #
;
;       RETURNS:        NC
;                         EBX:EAX   Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalLockSector

LocalLockSector    Proc near
    push es
    push ecx
    push edx
    push esi
    push edi
;
    mov cx,serv_flat_sel
    mov es,cx
;
    EnterSection ds:vfs_section
;
    call SectorToBlock
    jc llsFail
;
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jnz llsValid
;
    call BlockToBitmap
    mov ecx,eax
    shr ecx,3
    and ecx,1FFFFh
    bts es:[edi],ecx

llsRetry:
    or es:[esi].vfsp_ref_bitmap,1
    call CreateReq
;
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc llsSignal
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

llsSignal:
    LeaveSection ds:vfs_section
;
    mov bx,ds:vfs_server
    Signal
;
    WaitForSignal
    EnterSection ds:vfs_section
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jnz llsOk
    jmp llsRetry

llsValid:
    add es:[esi].vfsp_ref_bitmap,1
    jnc llsOk
;
    CrashGate

llsOk:
    mov bx,ax
    and bx,7
    shl bx,9
    mov eax,es:[esi]
    and ax,0F000h
    or ax,bx
    movzx ebx,word ptr es:[esi+4]
    LeaveSection ds:vfs_section
    clc
    jmp llsDone

llsFail:
    LeaveSection ds:vfs_section
    stc

llsDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop es
    ret
LocalLockSector    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalUnlockSector
;
;       DESCRIPTION:    Unlock sector
;
;       PARAMETERS:     DS          VFS sel
;                       EDX:EAX     Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LocalUnlockSector

LocalUnlockSector    Proc near
    push es
    push ecx
    push edx
    push esi
;
    mov cx,serv_flat_sel
    mov es,cx
;
    EnterSection ds:vfs_section
;
    call SectorToBlock
    jc lusLeave
;
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz lusLeave
;
    sub es:[esi].vfsp_ref_bitmap,1
    jnc lusLeave
;
    CrashGate

lusLeave:
    LeaveSection ds:vfs_section
;
    pop esi
    pop edx
    pop ecx
    pop es
    ret
LocalUnlockSector    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockMultiSectors
;
;       DESCRIPTION:    Lock multi sector
;
;       PARAMETERS:     DS          VFS sel
;                       EDX:EAX     Block #
;                       ECX         Count
;                       ES:EDI      Physical addresses
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LockMultiSectors

LockMultiSectors    Proc near
    push es
    push gs
    push ebx
    push esi
    push ebp
;
    mov si,es
    mov gs,si
;    
    mov si,serv_flat_sel
    mov es,si

lmsRetry:
    push eax
    push ecx
    push edx
    push edi
    xor ebp,ebp
;
    EnterSection ds:vfs_section

lmsReqLoop:
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jnz lmsReqNext
;
    push ecx
    call BlockToBitmap
    mov ecx,eax
    shr ecx,3
    and ecx,1FFFFh
    bts es:[edi],ecx
    pop ecx
;
    or es:[esi].vfsp_ref_bitmap,1
    call CreateReq
;
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc lmsPosOk
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

lmsPosOk:
    inc ebp

lmsReqNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz lmsReqLoop
;
    LeaveSection ds:vfs_section
    pop edi
    pop edx
    pop ecx
    pop eax
;
    or ebp,ebp
    jz lmsCheckReady

lmsWait:
    mov bx,ds:vfs_server
    Signal
;
    WaitForSignal

lmsCheckReady:
    EnterSection ds:vfs_section
;
    push eax
    push ecx
    push edx
    push edi
    xor ebp,ebp

lmsCheckLoop:
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jnz lmsCheckNext
;
    inc ebp

lmsCheckNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz lmsCheckLoop
;
    pop edi
    pop edx
    pop ecx
    pop eax
;
    or ebp,ebp
    jz lmsGetData
;
    LeaveSection ds:vfs_section
    jmp lmsWait

lmsGetData:
    push eax
    push ecx
    push edx
    push edi
;
    mov ebp,edi

lmsGetLoop:
    call BlockToBuf
;
    add es:[esi].vfsp_ref_bitmap,1
;
    mov ebx,es:[esi]
    and bx,0F000h
    mov gs:[ebp],ebx
    add ebp,4
    movzx ebx,word ptr es:[esi+4]
    mov gs:[ebp],ebx
    add ebp,4
;
    add eax,8
    adc edx,0
    sub ecx,1
    jnz lmsGetLoop
;    
    pop edi
    pop edx
    pop ecx
    pop eax
;
    LeaveSection ds:vfs_section
    clc
;
    pop ebp
    pop esi
    pop ebx
    pop gs
    pop es
    ret
LockMultiSectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockMultiSectors
;
;       DESCRIPTION:    Unlock multi sectors
;
;       PARAMETERS:     DS          VFS sel
;                       EDX:EAX     Block #
;                       ECX         Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UnlockMultiSectors

UnlockMultiSectors    Proc near
    push es
    push ecx
    push edx
    push esi
;
    mov si,serv_flat_sel
    mov es,si
;
    EnterSection ds:vfs_section

ulmsLoop:
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz ulmsNext
;
    sub es:[esi].vfsp_ref_bitmap,1

ulmsNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz ulmsLoop
;
    LeaveSection ds:vfs_section
;
    pop esi
    pop edx
    pop ecx
    pop es
    ret
UnlockMultiSectors    Endp

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
;
    mov cx,serv_flat_sel
    mov es,cx
;
    EnterSection ds:vfs_section

icSearch:
    mov ebx,ds:vfs_cache_discard_pos+4
    shl ebx,2
    mov eax,ds:[ebx].vfs_buf_arr
    or eax,eax
    jnz icEntryOk
;
    shr ebx,2
    inc ebx
    cmp ebx,ds:vfs_buf_count
    jb icBufOk
;
    xor ebx,ebx

icBufOk:
    mov ds:vfs_cache_discard_pos,0
    mov ds:vfs_cache_discard_pos+4,ebx
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
    jnz icBufPtr

icEntryLoop:
    add ebx,4
    add esi,4
    test esi,0FFFh
    jz icEntryRetry
;
    mov eax,es:[esi]
    or eax,eax
    jz icEntryLoop

icEntryRetry:
    shl ebx,20
    mov ds:vfs_cache_discard_pos,ebx
    jmp icSearch

icBufPtr:
    and ax,0F000h
;
    mov ebx,ds:vfs_cache_discard_pos
    shr ebx,10
    and ebx,0FFCh
    mov esi,ebx
    add esi,eax
    mov eax,es:[esi]
    or eax,eax
    jnz icBufDir

icBufPtrLoop:
    add ebx,4
    add esi,4
    test esi,0FFFh
    jz icBufPtrRetry
;
    mov eax,es:[esi]
    or eax,eax
    jz icBufPtrLoop

icBufPtrRetry:
    shl ebx,10
    mov ds:vfs_cache_discard_pos,ebx
    jmp icSearch

icBufDir:
    and ax,0F000h
    mov esi,eax
;
    mov ecx,512

icLoop:
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz icNext
;
    cmp es:[esi].vfsp_ref_bitmap,0
    jne icNext
;
    btc es:[esi].vfsp_flags,VFS_PHYS_USED_BIT
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
    add ds:vfs_cache_discard_pos,1000h
    adc ds:vfs_cache_discard_pos+4,0
;        
    LeaveSection ds:vfs_section

icDone:
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
    WaitForSignal

hdRetry:
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
    mov al,es:[esi].vfsp_wr_bitmap
    or al,al
    jz hdWriteDone
;
    int 3

hdWriteDone:
    call ClearIoBitmap
    LeaveSection ds:vfs_section
    jmp hdRetry

hdLeave:
    LeaveSection ds:vfs_section
    jmp hdLoop

hdRead:
    call GetReadIo
    call ClearIoBitmap
    call BlockToSector
    LeaveSection ds:vfs_section
;
    push es
    mov es,ds:vfs_req_buf
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_read
    pop es
    jc hdFail
;
    EnterSection ds:vfs_section
    call NotifyReadBuf
;
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
    ret
init_buf    Endp

code    ENDS

    END
