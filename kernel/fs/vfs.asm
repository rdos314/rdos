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
; VFS.ASM
; Virtual file system
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\serv.def
include ..\serv.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\handle.inc
include ..\wait.inc
include vfs.inc

    .386p

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

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
    push ecx
    push edx
    push edi
;
    mov eax,4000h
    AllocateBigServ
;
    mov edi,edx
    mov ecx,4 * 400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov eax,edx
;
    pop edi
    pop edx
    pop ecx
    ret
CreateBitmapEntry    Endp

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
;                       ES          Server flat sel
;                       EDX:EAX     Sector #
;
;       RETURNS:        NC
;                         EBX:EAX   Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalLockSector    Proc near
    push edx
    push esi
    push edi
;
    call SectorToBlock
    jc llsDone
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
;
    push ax
    GetThread
    mov es:[esi].vfsp_ref_wait,ax
    pop ax
;
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc llsSignal
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

llsSignal:
    mov bx,ds:vfs_server
    Signal
;
    WaitForSignal
    int 3

llsValid:
    add es:[esi].vfsp_ref_wait,1
    jnc llsPhysRefOk
;
    CrashGate

llsPhysRefOk:
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jnz llsOk

llsOk:
    mov bx,ax
    and bx,7
    shl bx,9
    mov eax,es:[esi]
    and ax,0F000h
    or ax,bx
    movzx ebx,word ptr es:[esi+4]
    clc
;

llsFail:
    stc

llsDone:
    pop edi
    pop esi
    pop edx
    ret
LocalLockSector    Endp

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
    jz gisScanDone
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

gisScanDone:
    pop ecx

gisPtrNext:
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
    ret
GetIoBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockVfsSector
;
;       DESCRIPTION:    Lock VFS sector
;
;       PARAMETERS:     EDX:EAX     Sector #
;
;       RETURNS:        NC
;                         EBX:EAX   Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_vfs_sector_name       DB 'Lock VFS Sector',0

lock_vfs_sector    Proc far
    int 3
    ret
lock_vfs_sector    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockVfsSector
;
;       DESCRIPTION:    Unlock VFS sector
;
;       PARAMETERS:     EDX:EAX     Sector #
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_vfs_sector_name       DB 'Unlock VFS Sector',0

unlock_vfs_sector    Proc far
    int 3
    ret
unlock_vfs_sector    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitPartition
;
;       DESCRIPTION:    Init partition
;
;       PARAMETERS:     BX       VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_part_name       DB 'VFS Init',0

init_part:
    mov ds,bx
    mov ax,serv_flat_sel
    mov es,ax
;
    mov eax,123456h
    xor edx,edx
    call LocalLockSector
    int 3

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
    mov ds:vfs_max_req,bx
;
    mov ds:vfs_scan_pos,-1
    mov ds:vfs_scan_pos+4,-1
;
    call CalcParam
    call CreateBuffer
;
    push ds
;
    mov bx,ds
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET init_part
    mov edi,OFFSET init_part_name
    mov al,4
    CreateThread
;
    pop ds
;
    mov ax,serv_flat_sel
    mov es,ax

vfsLoop:
    WaitForSignal
    int 3
    call GetIoStart
    jc vfsLoop
;
    call GetIoBuf
    jc vfsLoop
;
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
;       NAME:           StartVfs
;
;       DESCRIPTION:    Start VFS
;
;       PARAMETERS:     DS:ESI  VFS table
;                       ES:EDI  Server name
;                       BX      Dev param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_vfs_name       DB 'Start VFS',0

start_vfs    Proc far
    push ds
    push eax
    push esi
;
    push es
    push ecx
    push edi
;
    mov eax,OFFSET vfs_buf_arr
    AllocateSmallGlobalMem
;
    mov ecx,SIZE vfs_table_struc
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]
    mov es:vfs_param,bx
    mov es:vfs_flags,0
    mov es:vfs_server,0
    mov bx,es
;
    pop edi
    pop ecx
    pop es
;
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET VfsServer
    mov al,4
    CreateServerProcess
;
    pop esi
    pop eax
    pop ds
    ret
start_vfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopVfs
;
;       DESCRIPTION:    Stop vfs
;
;       PARAMETERS:     BX      VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_vfs_name       DB 'Stop VFS',0

stop_vfs    Proc far
    push es
    push ebx
;
    mov es,ebx
    lock or es:vfs_flags,VFS_FLAG_STOPPED
    mov bx,es:vfs_server
    Signal
;
    pop ebx
    pop es    
    ret
stop_vfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init
;
;       description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_vfs
    mov edi,OFFSET start_vfs_name
    xor cl,cl
    mov ax,start_vfs_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_vfs
    mov edi,OFFSET stop_vfs_name
    xor cl,cl
    mov ax,stop_vfs_nr
    RegisterOsGate
;
    mov esi,OFFSET lock_vfs_sector
    mov edi,OFFSET lock_vfs_sector_name
    xor cl,cl
    mov ax,lock_vfs_sector_nr
    RegisterServGate
;
    mov esi,OFFSET unlock_vfs_sector
    mov edi,OFFSET unlock_vfs_sector_name
    xor cl,cl
    mov ax,unlock_vfs_sector_nr
    RegisterServGate
    clc
    ret
init    Endp


code    ENDS

    END init
