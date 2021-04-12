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

    extern init_part:near
    extern NotifyReadBuf:near

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

    public RemoveReq

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
;       NAME:           CalcParam
;
;       DESCRIPTION:    Calculate schedule params
;
;       PARAMETERS:     DS      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam    Proc near
    mov eax,ds:vfs_sectors
    mov edx,ds:vfs_sectors+4
    mov bx,ds:vfs_bytes_per_sector
    xor cl,cl

cpSectorLoop:
    cmp bx,1000h
    jae cpSectorOk
;
    clc
    rcr edx,1
    rcr eax,1
    shl bx,1
    inc cl
    jmp cpSectorLoop

cpSectorOk:
    mov bl,3
    sub bl,cl
    mov ds:vfs_sector_shift,bl
;
    add eax,1
    adc edx,0
    mov ds:vfs_blocks,eax
    mov ds:vfs_blocks+4,edx
;
    mov ebx,eax
    rol ebx,3
    and bl,7
    shl edx,3
    or dl,bl
    inc edx
    mov ds:vfs_buf_count,edx
;
    mov ax,1
    shl ax,cl
    mov ds:vfs_sectors_per_block,ax
;
    ret
CalcParam    Endp

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
    AllocatePhysical64
    mov es:[esi],eax
    mov es:[esi+4],ebx
    or es:[esi].vfsp_flags,VFS_PHYS_PRESENT

btbOk:
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
    movzx ebx,ds:vfs_sectors_per_block
    add ds:vfs_active_count,ebx
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
    jnz griBlockLoop

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
;       NAME:           PartThread
;
;       DESCRIPTION:    Partition thread
;
;       PARAMETERS:     BX       VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

part_thread_name       DB 'VFS',0

part_thread:
    mov ds,bx
    call init_part
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreatePartThread
;
;       DESCRIPTION:    Start part thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePartThread Proc near
    push ds
    push es
    pushad
;
    mov bx,ds
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET part_thread
    mov edi,OFFSET part_thread_name
    mov al,4
    CreateThread
;
    popad
    pop es
    pop ds
    ret
CreatePartThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           VfsServer
;
;       DESCRIPTION:    Vfs server
;
;       PARAMETERS:     BX      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public VfsServer

VfsServer:
    GetThread
    mov ds,bx
    mov ds:vfs_server,ax
;
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_init
    jc vfsTerm
;
    mov ds:vfs_sectors,eax
    mov ds:vfs_sectors+4,edx
    mov ds:vfs_bytes_per_sector,cx
;
    and bl,0F8h    
    mov ds:vfs_max_req,bx
    movzx eax,bx
    shl eax,3
    AllocateSmallServ
    mov ds:vfs_req_buf,es
;
    mov bx,ds
    mov es,bx
    mov edi,OFFSET vfs_vendor_str
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_get_vendor
;
    mov ds:vfs_scan_pos,-1
    mov ds:vfs_scan_pos+4,-1
    mov ds:vfs_active_count,0
    mov ds:vfs_req_list,0
    InitSection ds:vfs_section
;
    call CalcParam
    call CreateBuffer
    call CreatePartThread
;
    mov ax,serv_flat_sel
    mov es,ax

vfsLoop:
    WaitForSignal

vfsRetry:
    EnterSection ds:vfs_section
;
    call GetIoStart
    jc vfsLeave
;
    call GetIoBuf
    jc vfsLeave
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz vfsRead

vfsWrite:
    int 3
    LeaveSection ds:vfs_section
    jmp vfsRetry

vfsLeave:
    LeaveSection ds:vfs_section
    jmp vfsLoop

vfsRead:
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
    jc vfsFail
;
    EnterSection ds:vfs_section
    call NotifyReadBuf
    sub ds:vfs_active_count,ecx
    jnz vfsMore
;
    call ClearCurrIoBitmap
    LeaveSection ds:vfs_section
    jmp vfsLoop

vfsMore:
    LeaveSection ds:vfs_section
    jmp vfsRetry

vfsFail:
    int 3

    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz vfsExit
;
    jmp vfsLoop

vfsExit:
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_exit

vfsTerm:
    TerminateThread

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
