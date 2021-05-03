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
; VFSSERV.ASM
; VFS server part
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
include ..\fs.inc
include ..\os\exec.def
include vfs.inc

    .386p

GET_FREE_SECTORS   = 0

MAX_PART_COUNT   = 255

req_wait_header      STRUC

rw_obj              wait_obj_header <>
rw_handle           DW ?

req_wait_header      ENDS

fs_cmd      STRUC

fc_op              DD ?
fc_handle          DD ?
fc_eflags          DD ?
fc_eax             DD ?
fc_ebx             DD ?
fc_ecx             DD ?
fc_edx             DD ?
fc_esi             DD ?
fc_edi             DD ?

fs_cmd      ENDS

drive_seg   STRUC

ds_part_sel      DW ?
ds_ref_count     DW ?
ds_drive         DB ?
ds_deleted       DB ?

drive_seg   ENDS

dir_handle_seg  STRUC

dir_handle_base handle_header <>

dir_handle_sel  DW ?

dir_handle_seg  ENDS

data    SEGMENT byte public 'DATA'

drive_arr       DW MAX_PART_COUNT DUP (?)
part_arr        DW MAX_PART_COUNT DUP (?)
drive_sel_arr   DW MAX_PART_COUNT DUP (?)
drive_section   section_typ <>

data    ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern BlockToBuf:near
    extern BlockToBitmap:near
    extern SectorToBlock:near
    extern SectorCountToBlock:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreatePartSel
;
;       DESCRIPTION:    Create partition selector
;
;       PARAMETERS:     DS      VFS sel
;
;       RETURNS:        BX      Part sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePartSel  Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    mov ecx,MAX_VFS_PARTITIONS
    mov esi,OFFSET vfs_part_arr

cpsLoop:
    mov ax,ds:[esi]
    or ax,ax
    jz cpsFound
;
    add esi,2
    loop cpsLoop
;
    stc
    jmp cpsDone

cpsFound:
    mov eax,SIZE vfs_part
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov eax,ds:vfs_curr_start_sector
    mov es:vfsp_start_sector,eax
    mov eax,ds:vfs_curr_start_sector+4
    mov es:vfsp_start_sector+4,eax
    mov eax,ds:vfs_curr_sector_count
    mov es:vfsp_sector_count,eax
    mov eax,ds:vfs_curr_sector_count+4
    mov es:vfsp_sector_count+4,eax
    mov es:vfsp_disc_sel,ds
;
    mov es:vfsp_cmd_unused_mask,-1
;
    mov ds:[esi],es
    mov eax,esi
    sub eax,OFFSET vfs_part_arr
    shr eax,1
    mov es:vfsp_part_nr,al
;
    mov al,ds:vfs_disc_nr
    mov es:vfsp_disc_nr,al
;
    mov ax,SEG data
    mov ds,ax
    mov ecx,MAX_PART_COUNT
    mov esi,OFFSET part_arr

cpsPartLoop:
    mov ax,ds:[esi]
    or ax,ax
    jz cpsPartFound
;
    add esi,2
    loop cpsPartLoop
;
    CrashGate

cpsPartFound:
    mov ds:[esi],es
    mov bx,es
    clc

cpsDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreatePartSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddFatPartition
;
;       DESCRIPTION:    Add FAT partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  Partition name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat_serv_name  DB 'fat', 0

AddFatPartition   Proc near
    push ds
    push es
    push fs
    pushad
;
    call CreatePartSel
    jc afpDone
;
    mov fs,bx
    AllocateVfsDrive
    mov fs:vfsp_drive_nr,al
    movzx ebx,al
    shl ebx,1
    mov ax,SEG data
    mov ds,ax
    mov ds:[ebx].drive_arr,fs
;
    mov ax,es
    mov ds,ax
    mov esi,edi
    mov eax,6
    AllocateSmallGlobalMem
    xor edi,edi
    movs dword ptr es:[edi],ds:[esi]
    movs byte ptr es:[edi],ds:[esi]
    xor al,al
    stos byte ptr es:[edi]
;
    mov ax,es
    mov ds,ax
    xor esi,esi
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET fat_serv_name
    mov al,4
    mov bh,fs:vfsp_disc_nr
    mov bl,fs:vfsp_part_nr
    LoadServer
;
    mov fs:vfsp_app_sel,bx
;
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem

afpDone:
    popad
    pop fs
    pop es
    pop ds
    ret
AddFatPartition   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddPartition
;
;       DESCRIPTION:    Add partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  Partition name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddPartition

AddPartition   Proc near
    push eax
;
    mov ax,es:[edi]
    cmp ax,'AF'
    jne apNotFat
;
    mov al,es:[edi+2]
    cmp al,'T'
    jne apNotFat
;
    call AddFatPartition

apNotFat:
    pop eax
    ret
AddPartition   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopPartRequests
;
;       DESCRIPTION:    Stop part requests
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopPartRequests    Proc near
    push gs
    push eax
    push ebx
    push ecx
;
    mov ebx,OFFSET vfsp_req_arr
    mov ecx,MAX_VFS_REQ_COUNT

sprLoop:
    mov ax,fs:[ebx]
    or ax,ax
    jz sprNext
;
    mov gs,ax
    xor ax,ax
    xchg ax,gs:vfsrh_wait_obj
    or ax,ax
    jz sprNext
;
    push es
    mov es,ax
    SignalWait
    pop es
    
sprNext:
    add ebx,2
    loop sprLoop
;
    pop ecx
    pop ebx
    pop eax
    pop gs
    ret
StopPartRequests    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopRequests
;
;       DESCRIPTION:    Stop requests
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public StopRequests

StopRequests    Proc near
    push fs
    push esi
    push edi
    push ebp
;
    push ebx
;
    mov ebx,OFFSET vfs_part_arr
    mov ebp,MAX_VFS_PARTITIONS

srLoop:
    mov si,ds:[ebx]
    or si,si
    jz srNext
;
    mov fs,si
    call StopPartRequests

srNext:
    add ebx,2
    sub ebp,1
    jnz srLoop
;
    pop ebx
;
    pop ebp
    pop edi
    pop esi
    pop fs
    ret
StopRequests    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyPart
;
;       DESCRIPTION:    Notify part
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;                       EDX:EAX     Sector
;                       SI          Req mask
;                       CX          Lock count
;
;       RETURNS:        CX          Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyPart    Proc near
    push gs
    push ebx
    push esi
    push edi
    push ebp
;
    mov bx,si
    push ebx

npLoop:
    pop ebx
    or bx,bx
    jz npDone
;
    bsf si,bx
    btc bx,si
;
    push ebx
    movzx esi,si
    dec esi
    add esi,esi
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz npLoop
;
    mov gs,si
    movzx ebp,gs:vfsrh_entry_count
    mov ebx,SIZE vfs_req_header
    or ebp,ebp
    jz npLoop

npCheckLoop:
    mov esi,gs:[ebx].vfsre_sector_count
    or esi,esi
    jz npCheckNext
;
    mov esi,eax
    mov edi,edx
    sub esi,gs:[ebx].vfsre_start_sector
    sbb edi,gs:[ebx].vfsre_start_sector+4
    jc npCheckNext
;
    or edi,edi
    jnz npCheckNext
;
    cmp esi,gs:[ebx].vfsre_sector_count
    jae npCheckNext
;
    inc cx
    sub gs:vfsrh_remain_count,1
    jnz npCheckNext
;
    xor di,di
    xchg di,gs:vfsrh_wait_obj
    or di,di
    jz npCheckNext
;
    push es
    mov es,edi
    SignalWait
    pop es
    
npCheckNext:
    add ebx,SIZE vfs_req_entry
    sub ebp,1
    jnz npCheckLoop
;
    jmp npLoop

npDone:
    pop ebp
    pop edi
    pop esi
    pop ebx
    pop gs
    ret
NotifyPart    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyVfs
;
;       DESCRIPTION:    Notify read buffers
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Sector
;                       BX          Req mask
;                       CX          Lock count
;
;       RETURNS:        CX          Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NotifyVfs

NotifyVfs    Proc near
    push fs
    push esi
    push edi
    push ebp
;
    push ebx
;
    mov ebx,OFFSET vfs_part_arr
    mov ebp,MAX_VFS_PARTITIONS

nvfLoop:
    mov si,ds:[ebx]
    or si,si
    jz nvfNext
;
    mov fs,si
    mov esi,eax
    mov edi,edx
    add esi,7
    adc edi,0
    sub esi,fs:vfsp_start_sector
    sbb edi,fs:vfsp_start_sector+4
    jc nvfNext
;
    sub esi,7
    sbb edi,0
    jc nvfHandle
;
    sub esi,fs:vfsp_sector_count    
    sbb edi,fs:vfsp_sector_count+4
    jnc nvfNext

nvfHandle:
    pop esi
    call NotifyPart
    push esi

nvfNext:
    add ebx,2
    sub ebp,1
    jnz nvfLoop
;
    pop ebx
;
    pop ebp
    pop edi
    pop esi
    pop fs
    ret
NotifyVfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopPartitions
;
;       DESCRIPTION:    Stop partitions
;
;       PARAMETERS:     DS      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public StopPartitions

StopPartitions   Proc near
    push es
    push eax
    push ebx
;
    mov ecx,MAX_VFS_PARTITIONS
    mov ebx,vfs_part_arr

spLoop:
    mov ax,ds:[ebx]
    or ax,ax
    jz spNext
;
    mov es,ax
    or es:vfsp_flag,VFSP_FLAG_STOPPED

spNext:
    add ebx,2
    loop spLoop
;
    pop ebx
    pop eax
    pop es
    ret
    ret
StopPartitions   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsHandle
;
;       DESCRIPTION:    Get VFS handle
;
;       RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_handle_name       DB 'Get VFS Handle',0

get_vfs_handle    Proc far
    push ds
    push es
    push eax
    push esi
;
    GetThread
    mov ds,ax
    mov bx,ds:p_prog_id
;
    mov ax,SEG data
    mov ds,ax

gvfshRetry:
    mov esi,OFFSET part_arr
    mov ecx,MAX_PART_COUNT

gvfshLoop:
    mov ax,ds:[esi]
    or ax,ax
    jz gvfshNext
;
    mov es,ax
    cmp bx,es:vfsp_app_sel
    je gvfshFound

gvfshNext:
    add esi,2
    loop gvfshLoop
;
    mov ax,10
    WaitMilliSec
    jmp gvfshRetry

gvfshFound:
    sub esi,OFFSET part_arr
    shr esi,1
    inc esi
    mov ebx,esi
;
    pop esi
    pop eax
    pop es
    pop ds
    ret
get_vfs_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleToPart
;
;       DESCRIPTION:    Convert from handle to partition selector
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        ES          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleToPart    Proc near
    push eax
    push ebx
;
    mov ax,SEG data
    mov es,ax
    or bx,bx
    jz htpFail
;
    cmp ebx,MAX_PART_COUNT
    jbe htpInRange

htpFail:
    stc
    jmp htpDone

htpInRange:
    dec ebx
    add ebx,ebx
    mov ax,es:[ebx].part_arr
    or ax,ax
    jz htpFail
;
    mov es,ax
    test es:vfsp_flag,VFSP_FLAG_STOPPED
    jnz htpFail
;
    clc

htpDone:
    pop ebx
    pop eax
    ret
HandleToPart    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsSectors
;
;       DESCRIPTION:    Get VFS sectors
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        EDX:EAX     Sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_sectors_name       DB 'Get VFS Sectors',0

get_vfs_sectors    Proc far
    push es
;
    call HandleToPart
    jc gvsDone
;
    mov eax,es:vfsp_sector_count
    mov edx,es:vfsp_sector_count+4
    clc

gvsDone:
    pop es
    ret
get_vfs_sectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsVfsActive
;
;       DESCRIPTION:    Is VFS active
;
;       PARAMETERS:     EBX         VFS Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_vfs_active_name       DB 'Is VFS Active',0

is_vfs_active    Proc far
    push es
;
    call HandleToPart
;
    pop es
    ret
is_vfs_active    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateVfsReq
;
;       DESCRIPTION:    Create a VFS req
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_vfs_req_name       DB 'Create VFS Req',0

create_vfs_req    Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov dh,bl
;
    call HandleToPart
    jc crvrDone
;
    mov eax,es
    mov ds,eax
    mov ecx,MAX_VFS_REQ_COUNT
    mov edi,OFFSET vfsp_req_arr
    xor ax,ax
    repnz scas word ptr es:[edi]
    jz crvrFound

crvrFail:
    stc
    jmp crvrDone

crvrFound:
    mov bx,di
    sub bx,OFFSET vfsp_req_arr
    shr bx,1
    mov bh,dh
    sub edi,2
;
    mov eax,SIZE vfs_part_req
    AllocateBigServSel
    mov ds:[edi],es
;
    xor edi,edi
    mov ecx,SIZE vfs_part_req
    shr ecx,2
    xor eax,eax
    rep stos dword ptr es:[edi]
    clc

crvrDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloseVfsReq
;
;       DESCRIPTION:    Close a VFS req
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_vfs_req_name       DB 'Close VFS Req',0

close_vfs_req    Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    mov ax,SEG data
    mov ds,ax
    or bh,bh
    jz clvrDone
;
    cmp bh,MAX_PART_COUNT
    ja clvrDone
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov ax,ds:[esi].part_arr
    or ax,ax
    jz clvrDone
;
    mov ds,ax
    or bl,bl
    jz clvrDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja clvrDone
;
    movzx esi,bl
    dec esi
    shl esi,1
    xor bx,bx
    xchg bx,ds:[esi].vfsp_req_arr
    or bx,bx
    jz clvrDone
;
    mov es,bx
    FreeBigServSel

clvrDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
close_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReqHandleToSel
;
;       DESCRIPTION:    Convert req handle to selector
;
;       PARAMETERS:     EBX         Req handle
;
;       RETURNS:        NC
;                           FS      Part sel
;                           GS      Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqHandleToSel  Proc near
    push ds
    push esi
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz rqhsFail
;
    cmp bh,MAX_PART_COUNT
    ja rqhsFail
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz rqhsFail
;
    mov fs,si
    or bl,bl
    jz rqhsFail
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja rqhsFail
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz rqhsFail
;
    mov gs,si
    clc
    jmp rqhsDone

rqhsFail:
    stc

rqhsDone:
    pop esi
    pop ds
    ret
ReqHandleToSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartVfsReq
;
;       DESCRIPTION:    Start VFS req
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_vfs_req_name       DB 'Start VFS Req',0

start_vfs_req    Proc far
    push fs
    push gs
    push ebx
;
    call ReqHandleToSel
    jc srqDone
;
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    jz srqDone
;
    push ds
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    pop ds

srqDone:
    pop ebx
    pop gs
    pop fs
    ret
start_vfs_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsVfsReqDone
;
;       DESCRIPTION:    Is VFS req done
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_vfs_req_done_name       DB 'Is VFS Req Done',0

is_vfs_req_done    Proc far
    push fs
    push gs
    push esi
;
    call ReqHandleToSel
    jc irqdDone
;
    mov esi,gs:vfsrh_remain_count
    or esi,esi
    stc
    jnz irqdDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz irqdDone
;
    clc

irqdDone:
    pop esi
    pop gs
    pop fs
    ret
is_vfs_req_done   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForReq
;
;           DESCRIPTION:    Start a wait for req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_req      PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov bx,es:rw_handle
    call ReqHandleToSel
    jc stwrDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz stwrStop
;
    mov gs:vfsrh_wait_obj,es
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    jnz stwrStart

stwrStop:
    mov gs:vfsrh_wait_obj,0
    SignalWait
    jmp stwrDone

stwrStart:
    push ds
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    pop ds

stwrDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
start_wait_for_req Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForReq
;
;           DESCRIPTION:    Stop a wait for req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_req       PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov bx,es:rw_handle
    call ReqHandleToSel
    jc spwrDone
;
    mov gs:vfsrh_wait_obj,0

spwrDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
stop_wait_for_req Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearReq
;
;           DESCRIPTION:    Clear req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_req       PROC far
    ret
clear_req       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsReqIdle
;
;           DESCRIPTION:    Check if req is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_req_idle     PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov bx,es:rw_handle
    call ReqHandleToSel
    jc iriDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz iriDone
;
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    clc
    jne iriDone
;
    stc

iriDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
is_req_idle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddWaitForVfsReq
;
;       DESCRIPTION:    Add wait for VFS req
;
;       PARAMETERS:     EBX         Wait handle
;                       EAX         Req handle
;                       ECX         ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_vfs_req_name       DB 'Add Wait For VFS Req',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_req,   SEG code
aw1 DD OFFSET stop_wait_for_req,    SEG code
aw2 DD OFFSET clear_req,            SEG code
aw3 DD OFFSET is_req_idle,          SEG code

add_wait_for_vfs_req    Proc far
    push ds
    push es
    push eax
    push edi
;
    push ax
    mov eax,cs
    mov es,eax
    mov ax,SIZE req_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop ax
    jc awrqDone
;
    mov es:rw_handle,ax

awrqDone:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_vfs_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetReqMask
;
;       DESCRIPTION:    Get req mask
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;                       EBX         Req handle
;
;       RETURNS:        BP          Req mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetReqMask    Proc near
    push ecx
;
    mov cl,bl
    mov bp,1
    shl bp,cl
;
    pop ecx
    ret
GetReqMask   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddVfsSectors
;
;       DESCRIPTION:    Add VFS sectors
;
;       PARAMETERS:     EBX         Req handle
;                       EDX:EAX     Start sector
;                       ECX         Sector count
;
;       RETURNS:        EBX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_vfs_sectors_name       DB 'Add VFS Sectors',0

add_vfs_sectors    Proc far
    push ds
    push es
    push fs
    push gs
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz arsFail
;
    cmp bh,MAX_PART_COUNT
    ja arsFail
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz arsFail
;
    mov fs,si
    or bl,bl
    jz arsFail
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja arsFail
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz arsFail
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz arsFail
;
    mov gs,si
    mov esi,fs:vfsp_sector_count
    mov edi,fs:vfsp_sector_count+4
    sub esi,eax
    sbb edi,edx
    jc arsFail
;
    sub esi,ecx
    sbb edi,0
    jc arsFail
;
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
;
    EnterSection ds:vfs_section
;
    mov di,gs:vfsrh_deleted_count
    or di,di
    jz arsAppend
;
    dec di
    mov gs:vfsrh_deleted_count,di
;
    mov edi,SIZE vfs_req_header

arsScanLoop:
    mov esi,gs:[edi].vfsre_sector_count
    or esi,esi
    jz arsTake
;
    add edi,SIZE vfs_req_entry
    jmp arsScanLoop

arsAppend:
    movzx edi,gs:vfsrh_entry_count
    cmp di,MAX_VFS_ENTRY_COUNT
    je arsLeaveFail
;
    inc di
    mov gs:vfsrh_entry_count,di
    shl edi,4

arsTake:
    add eax,fs:vfsp_start_sector
    adc edx,fs:vfsp_start_sector+4
;
    push eax
    push ebx
    push ecx
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    mov bx,1
    shl bx,cl
    dec bx
    movzx esi,ax
    and si,bx
    shl si,9
    mov gs:[edi].vfsre_linear,esi
    not bx
    and ax,bx
    mov gs:[edi].vfsre_start_sector,eax
    mov gs:[edi].vfsre_start_sector+4,edx
;
    pop ecx
    pop ebx
    pop eax
;
    call SectorCountToBlock
    jc arsLeaveFail
;
    push ebx
    push ecx
;
    mov ebx,ecx
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shl ebx,cl
    mov gs:[edi].vfsre_sector_count,ebx
;
    pop ecx
    pop ebx
;
    call GetReqMask

arsLoop:
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz arsReq
;
    cmp es:[esi].vfsp_ref_bitmap,0
    jnz arsLockOk
;
    inc ds:vfs_locked_pages

arsLockOk:
    inc es:[esi].vfsp_ref_bitmap
    jmp arsNext

arsReq:
    inc gs:vfsrh_remain_count
    or es:[esi].vfsp_ref_bitmap,bp
;
    push edi
;
    call BlockToBitmap
    mov ebx,eax
    shr ebx,3
    and ebx,1FFFFh
    bts es:[edi],ebx
;
    pop edi
;
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc arsNext
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

arsNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz arsLoop
;
    LeaveSection ds:vfs_section
;
    mov ebx,edi
    shr ebx,4
    clc
    jmp arsDone

arsLeaveFail:
    LeaveSection ds:vfs_section

arsFail:
    stc

arsDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
add_vfs_sectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RemoveVfsSectors
;
;       DESCRIPTION:    Remove VFS sectors
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_vfs_sectors_name       DB 'Remove VFS Sectors',0

remove_vfs_sectors    Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz rrsDone
;
    cmp bh,MAX_PART_COUNT
    ja rrsDone
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz rrsDone
;
    mov fs,si
    or bl,bl
    jz rrsDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja rrsDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz rrsDone
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz rrsDone
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,eax
    shl edi,4
;
    EnterSection ds:vfs_section
;
    xor eax,eax
    xchg eax,gs:[edi].vfsre_sector_count
    or eax,eax
    jz rrsLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    mov ecx,eax
;
    inc gs:vfsrh_deleted_count
    mov eax,gs:[edi].vfsre_start_sector
    mov edx,gs:[edi].vfsre_start_sector+4
    call SectorToBlock
    jc rrsLeave

rrsLoop:
    call BlockToBuf
    jc rrsNext
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz rrsDecRem

rrsUnlock:
    mov bx,es:[esi].vfsp_ref_bitmap
    or bx,bx
    jz rrsDecRem
;
    sub es:[esi].vfsp_ref_bitmap,1
    jnz rrsNext
;
    dec ds:vfs_locked_pages
    jmp rrsNext

rrsDecRem:
    sub gs:vfsrh_remain_count,1
    jnc rrsNext
;
    CrashGate

rrsNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz rrsLoop

rrsLeave:
    LeaveSection ds:vfs_section

rrsDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
remove_vfs_sectors Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapVfsReq
;
;       DESCRIPTION:    Map VFS req
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;       RETURNS:        EDX         Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_vfs_req_name       DB 'Map VFS Req',0

map_vfs_req    Proc far
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push esi
    push edi
    push ebp
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz mvrFail
;
    cmp bh,MAX_PART_COUNT
    ja mvrFail
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz mvrFail
;
    mov fs,si
    or bl,bl
    jz mvrFail
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja mvrFail
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz mvrFail
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz mvrFail
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,eax
    shl edi,4
;
    EnterSection ds:vfs_section
;
    mov eax,gs:[edi].vfsre_sector_count
    or eax,eax
    stc
    jz mvrLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    mov ecx,eax
;
    shl eax,12
    AllocateLocalLinear
    mov ebp,edx
;
    mov eax,gs:[edi].vfsre_start_sector
    mov edx,gs:[edi].vfsre_start_sector+4
    call SectorToBlock
    jc mvrLeave
;
    push ebp

mvrLoop:
    call BlockToBuf
    jc mvrNext
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz mvrNext
;
    push eax
    push edx
;
    mov edx,ebp
    mov eax,es:[esi]
    and ax,0F000h
    or ax,867h
    movzx ebx,word ptr es:[esi+4]
    SetPageEntry
;
    pop edx
    pop eax

mvrNext:
    add ebp,1000h
    add eax,8
    adc edx,0
    sub ecx,1
    jnz mvrLoop
;
    pop edx
    mov eax,gs:[edi].vfsre_linear
    and eax,0E00h
    add edx,eax
    mov gs:[edi].vfsre_linear,edx
;
    mov bx,system_data_sel
    mov es,bx
    sub edx,es:flat_base
    clc

mvrLeave:
    LeaveSection ds:vfs_section
    jmp mvrDone

mvrFail:
    stc

mvrDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
map_vfs_req Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnmapVfsReq
;
;       DESCRIPTION:    Unmap VFS req
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unmap_vfs_req_name       DB 'Map VFS Req',0

unmap_vfs_req    Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov si,SEG data
    mov ds,si
    or bh,bh
    jz umvrDone
;
    cmp bh,MAX_PART_COUNT
    ja umvrDone
;
    movzx esi,bh
    dec esi
    add esi,esi
    mov si,ds:[esi].part_arr
    or si,si
    jz umvrDone
;
    mov fs,si
    or bl,bl
    jz umvrDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja umvrDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz umvrDone
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz umvrDone
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,eax
    shl edi,4
;
    EnterSection ds:vfs_section
;
    mov eax,gs:[edi].vfsre_sector_count
    or eax,eax
    stc
    jz umvrLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    shl eax,12
    mov ecx,eax
    mov edx,gs:[edi].vfsre_linear
    and edx,0FFFFF000h
    jz umvrLeave
;
    FreeLinear
;
    mov edx,gs:[edi].vfsre_linear
    and edx,0FFFh
    mov gs:[edi].vfsre_linear,edx

umvrLeave:
    LeaveSection ds:vfs_section

umvrDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
unmap_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForVfsCmd
;
;       DESCRIPTION:    Wait for VFS cmd
;
;       PARAMETERS:     EBX        VFS handle
;
;       RETURNS:        EDX        Msg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_vfs_cmd_name DB 'Wait For VFS Cmd', 0

wait_for_vfs_cmd   Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    call HandleToPart
    jc wfcDone
;
    mov ax,es
    mov ds,ax
;
    GetThread
    mov ds:vfsp_cmd_thread,ax

wfcRetry:
    test ds:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz wfcDone
;
    WaitForSignal
;
    test ds:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz wfcDone
;
    movzx ebx,ds:vfsp_cmd_head
    mov al,ds:[ebx].vfsp_cmd_ring
    cmp bl,ds:vfsp_cmd_tail
    je wfcRetry
;
    inc bl
    cmp bl,34
    jb wfcSaveHead
;
    xor bl,bl

wfcSaveHead:
    mov ds:vfsp_cmd_head,bl
;
    movzx ebx,al
    mov ds:vfsp_cmd_curr,ebx
    dec ebx
    shl ebx,4
    add ebx,OFFSET vfsp_cmd_arr
    mov edx,ds:[ebx].vfss_server_linear
    or edx,edx
    jnz wfcMap
;
    mov eax,1000h
    AllocateLocalLinear
    mov ds:[ebx].vfss_server_linear,edx

wfcMap:
    push ds
    push edx
;
    mov eax,[ebx].vfss_phys
    mov ebx,[ebx].vfss_phys+4
    or ax,867h
;
    mov cx,system_data_sel
    mov ds,cx
    add edx,ds:flat_base
    SetPageEntry
;
    pop edx
    pop ds
    clc

wfcDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
wait_for_vfs_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReplyVfsCmd
;
;       DESCRIPTION:    Reply on VFS cmd
;
;       PARAMETERS:     EBX        VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_vfs_cmd_name DB 'Reply VFS Cmd', 0

reply_vfs_cmd   Proc far
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    call HandleToPart
    jc rfcDone
;
    mov esi,es:vfsp_cmd_curr
    dec esi
    shl esi,4
    add esi,OFFSET vfsp_cmd_arr
    xor bx,bx
    xchg bx,es:[esi].vfss_thread
    Signal
;
    mov edx,es:[esi].vfss_server_linear
    mov eax,es:[esi].vfss_phys
    mov ebx,es:[esi].vfss_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov es,cx
    add edx,es:flat_base
    SetPageEntry

rfcDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
reply_vfs_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMsgEntry
;
;       DESCRIPTION:    Get fs msg entry
;
;       PARAMETERS:     DS      VFS sel
;                       FS      Part sel
;
;       RETURNS:        EBX     FS entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMsgEntry  Proc near
    push ecx

gmeRetry:
    mov ebx,fs:vfsp_cmd_free_mask
    or ebx,ebx
    jz gmeTryUnused
;
    bsf ecx,ebx
    lock btc fs:vfsp_cmd_free_mask,ecx
    jc gmeOk
    jmp gmeRetry

gmeTryUnused:
    mov ebx,fs:vfsp_cmd_unused_mask
    or ebx,ebx
    jz gmeBlock
;
    bsf ecx,ebx
    lock btc fs:vfsp_cmd_unused_mask,ecx
    jc gmeAlloc
    jmp gmeRetry

gmeBlock:
    CrashGate

gmeAlloc:
    mov ebx,ecx
    shl ebx,4
    add ebx,OFFSET vfsp_cmd_arr
;
    push eax
    push ebx
    push edx
    push edi
;
    mov edi,ebx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov fs:[edi].vfss_phys,eax
    mov fs:[edi].vfss_phys+4,ebx
;
    or al,63h
    SetPageEntry
;    
    mov ecx,1000h
    AllocateGdt
    mov fs:[edi].vfss_sel,bx
    CreateDataSelector32
;
    mov fs:[edi].vfss_server_linear,0
    mov fs:[edi].vfss_thread,0
;
    pop edi
    pop edx
    pop ebx
    pop eax
;
    clc
    jmp gmeDone

gmeOk:
    mov ebx,ecx
    shl ebx,4
    add ebx,OFFSET vfsp_cmd_arr

gmeDone:
    pop ecx
    ret
GetMsgEntry  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateMsg
;
;       DESCRIPTION:    Allocate fs msg
;
;       PARAMETERS:     DS      VFS sel
;                       FS      Part sel
;
;       RETURNS:        EBX     Msg entry
;                       ES      Msg buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateMsg  Proc near
    push ebx
    call GetMsgEntry
    mov es,fs:[ebx].vfss_sel
    pop es:fc_ebx
;
    stc
    pushfd
    pop es:fc_eflags
;
    mov es:fc_eax,eax
    mov es:fc_ecx,ecx
    mov es:fc_edx,edx
    mov es:fc_esi,esi
    mov es:fc_edi,edi
    ret
AllocateMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunMsg
;
;       DESCRIPTION:    Run disc msg
;
;       PARAMETERS:     DS      VFS sel
;                       FS      Part sel
;                       ES      Msg buf
;                       EAX     Op
;                       EBX     Msg entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunMsg  Proc near
    push ebp
;
    mov esi,ebx
    mov es:fc_op,eax
;
    GetThread
    mov fs:[esi].vfss_thread,ax
;
    sub ebx,OFFSET vfsp_cmd_arr
    shr ebx,4
    mov al,bl
    inc al
;
    movzx ebx,fs:vfsp_cmd_tail
    mov fs:[ebx].vfsp_cmd_ring,al
    inc bl
    cmp bl,34
    jb rmSaveTail
;
    xor bl,bl

rmSaveTail:
    mov fs:vfsp_cmd_tail,bl
;
    mov bx,fs:vfsp_cmd_thread
    Signal

rmWait:
    WaitForSignal
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jz rmCheck
;
    stc
    jmp rmDone

rmCheck:
    mov bx,fs:[esi].vfss_thread
    or bx,bx
    jnz rmWait
;
    mov ebp,es:fc_eax
    mov ebx,es:fc_ebx
    mov ecx,es:fc_ecx
    mov edx,es:fc_edx
    mov esi,es:fc_esi
    mov edi,es:fc_edi
;
    dec al
    movzx eax,al
    lock bts fs:vfsp_cmd_free_mask,eax
;
    mov eax,ebp
    push es:fc_eflags
    popfd
;

rmDone:
    pop ebp
    ret
RunMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TestServ
;
;       DESCRIPTION:    Test server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_serv_name DB 'Test Serv', 0

test_serv   Proc far
    WaitForSignal
    ret
test_serv   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CheckVfsDrive
;
;       DESCRIPTION:    Check VFS drive
;
;       PARAMETERS:     AL        Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_vfs_drive_name DB 'Check VFS Drive', 0

check_vfs_drive   Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz cvdDone
;
    clc

cvdDone:
    pop ebx
    pop ds
    ret
check_vfs_drive   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsCurDir
;
;       DESCRIPTION:    Get VFS cur dir
;
;       PARAMETERS:     AL        Drive #
;                       ES:EDI    Path
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_cur_dir_name DB 'Get VFS Cur Dir', 0

get_vfs_cur_dir   Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvcdDone
;
    xor bl,bl
    mov es:[edi],bl
    clc

gvcdDone:
    pop ebx
    pop ds
    ret
get_vfs_cur_dir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDriveDisc
;
;       DESCRIPTION:    Get VFS drive disc
;
;       PARAMETERS:     AL    Drive #
;
;       RETURNS:        AL    Disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_drive_disc_name DB 'Get VFS Drive Disc', 0

get_vfs_drive_disc   Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvddDone
;
    mov ds,bx
    mov al,ds:vfsp_disc_nr
    clc

gvddDone:
    pop ebx
    pop ds
    ret
get_vfs_drive_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDriveStart
;
;       DESCRIPTION:    Get VFS drive start
;
;       PARAMETERS:     AL        Drive #
;
;       RETURNS:        EDX:EAX   Start sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_drive_start_name DB 'Get VFS Drive Start', 0

get_vfs_drive_start   Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvdbDone
;
    mov ds,bx
    mov eax,ds:vfsp_start_sector
    mov edx,ds:vfsp_start_sector+4
    clc

gvdbDone:
    pop ebx
    pop ds
    ret
get_vfs_drive_start   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDriveSize
;
;       DESCRIPTION:    Get VFS drive size
;
;       PARAMETERS:     AL        Drive #
;
;       RETURNS:        EDX:EAX   Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_drive_size_name DB 'Get VFS Drive Size', 0

get_vfs_drive_size   Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvdeDone
;
    mov ds,bx
    mov eax,ds:vfsp_sector_count
    mov edx,ds:vfsp_sector_count+4
    clc

gvdeDone:
    pop ebx
    pop ds
    ret
get_vfs_drive_size   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDriveFree
;
;       DESCRIPTION:    Get VFS drive free
;
;       PARAMETERS:     AL        Drive #
;
;       RETURNS:        EDX:EAX   Free sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_drive_free_name DB 'Get VFS Drive Free', 0

get_vfs_drive_free   Proc far
    push ds
    push es
    push fs
    push ebx
    push ecx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvdfDone
;
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    call AllocateMsg
;
    mov eax,GET_FREE_SECTORS
    call RunMsg

gvdfDone:
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
get_vfs_drive_free   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsVfsPath
;
;       DESCRIPTION:    Check if VFS path
;
;       PARAMETERS:     ES:(E)DI    Pathname
;
;       RETURNS:        NC          Is VFS path
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_vfs_path_name       DB 'Is VFS Path',0

is_vfs_path    Proc near
    push eax
;
    mov ax,es:[edi]
    or al,al
    stc
    je ivpDone
;
    cmp ah,':'
    jne ivpCurr
;
    sub al,'A'
    jc ivpDone
;
    cmp al,26
    jc ivpCheck
;
    sub al,20h
    jc ivpDone
;
    cmp al,26
    jc ivpCheck
;
    stc
    jmp ivpDone

ivpCurr:
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    mov al,ds:pc_drive
    pop ds

ivpCheck:
    push ebx
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    pop ebx
    stc
    jz ivpDone
;
    clc

ivpDone:
    pop eax
    ret
is_vfs_path  Endp

is_vfs_path16  Proc far
    push edi
    movzx edi,di
    call is_vfs_path
    pop edi
    ret
is_vfs_path16  Endp

is_vfs_path32  Proc far
    call is_vfs_path
    ret
is_vfs_path32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           open_drive
;
;       DESCRIPTION:    Open drive
;
;       PARAMETERS:     AL           Drive #
;
;       RETURNS:        NC
;                         BX         Drive sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_drive   Proc near
    push ds
    push es
;
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:drive_section
;
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_sel_arr
    or bx,bx
    jz odCreate
;
    mov es,bx
    lock add es:ds_ref_count,1
    clc
    jmp odLeave

odCreate:
    mov bx,ds:[ebx].drive_sel_arr
    or bx,bx
    stc
    jz odLeave
;
    push eax
    mov eax,SIZE drive_seg
    AllocateSmallGlobalMem
    pop eax
;
    mov es:ds_part_sel,bx
    mov es:ds_ref_count,1
    mov es:ds_deleted,0
    mov es:ds_drive,al
    mov bx,es
    clc

odLeave:
    LeaveSection ds:drive_section
;
    pop es
    pop ds
    ret
open_drive   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           close_drive
;
;       DESCRIPTION:    Close drive
;
;       PARAMETERS:     BX           Drive sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_drive   Proc near
    push ds
    push es
    push eax
;
    mov es,bx
    lock sub es:ds_ref_count,1
    jnz cdDone
;
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:drive_section
    movzx ebx,es:ds_drive
    shl ebx,1
    mov ax,es
    cmp ax,ds:[ebx].drive_sel_arr
    jne cdLeave
;
    mov ds:[ebx].drive_sel_arr,0

cdLeave:
    LeaveSection ds:drive_section

cdFree:
    FreeMem

cdDone:
    xor bx,bx
;
    pop eax
    pop es
    pop ds
    ret
close_drive   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetPathDrive
;
;       DESCRIPTION:    Get path drive
;
;       PARAMETERS:     ES:EDI      Pathname
;
;       RETURNS:        AL          Drive
;                       ES:EDI      Updated pathname without drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPathDrive    Proc near
    mov ax,es:[edi]
    or al,al
    stc
    je gpdDone
;
    cmp ah,':'
    jne gpdCurr
;
    sub al,'A'
    jc gpdDone
;
    cmp al,26
    jc gpdAdv
;
    sub al,20h
    jc gpdDone
;
    cmp al,26
    jc gpdAdv
;
    stc
    jmp gpdDone

gpdCurr:
    push ds
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    mov al,ds:pc_drive
    pop ds
    clc
    jmp gpdDone

gpdAdv:
    add edi,2
    clc

gpdDone:
    ret
GetPathDrive   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenVfsDir
;
;       DESCRIPTION:    Open VFS dir
;
;       PARAMETERS:     ES:(E)DI       Pathname
;
;       RETURNS:        NC
;                         BX           Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_vfs_dir_name       DB 'Open VFS Dir',0

open_vfs_dir    Proc near
    push eax
;    
    call GetPathDrive
    jc ovdDone
;
    call open_drive
    jc ovdDone
;
    call close_drive

ovdDone:
    pop eax
    ret
open_vfs_dir    Endp

open_vfs_dir16  Proc far
    push edi
    movzx edi,di
    call open_vfs_dir
    pop edi
    ret
open_vfs_dir16  Endp

open_vfs_dir32  Proc far
    call open_vfs_dir
    ret
open_vfs_dir32  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete handle
;
;           DESCRIPTION:    Delete a handle (called from handle module)
;
;           PARAMETERS:     BX              HANDLE TO DIR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ax
    push ebx
    push esi
;
    mov ax,VFS_DIR_HANDLE
    DerefHandle
    jc dhDone
;
    mov esi,ebx
    mov bx,[ebx].dir_handle_sel
    or bx,bx
    stc
    jz dhDone
;
;    call CloseDirBase
    mov ebx,esi
    FreeHandle
    clc

dhDone:
    pop esi
    pop ebx
    pop ax
    pop ds
    ret
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_server
;
;       description:    Init server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_server

init_server    Proc near
    mov ax,SEG data
    mov es,ax
    InitSection es:drive_section
    mov edi,OFFSET part_arr
    mov ecx,MAX_PART_COUNT
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov edi,OFFSET drive_arr
    mov ecx,MAX_PART_COUNT
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov edi,OFFSET drive_sel_arr
    mov ecx,MAX_PART_COUNT
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET delete_handle
    mov ax,VFS_DIR_HANDLE
    RegisterHandle
;
    mov esi,OFFSET get_vfs_handle
    mov edi,OFFSET get_vfs_handle_name
    xor cl,cl
    mov ax,get_vfs_handle_nr
    RegisterServGate
;
    mov esi,OFFSET is_vfs_active
    mov edi,OFFSET is_vfs_active_name
    xor cl,cl
    mov ax,is_vfs_active_nr
    RegisterServGate
;
    mov esi,OFFSET get_vfs_sectors
    mov edi,OFFSET get_vfs_sectors_name
    xor cl,cl
    mov ax,get_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET create_vfs_req
    mov edi,OFFSET create_vfs_req_name
    xor cl,cl
    mov ax,create_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET close_vfs_req
    mov edi,OFFSET close_vfs_req_name
    xor cl,cl
    mov ax,close_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET start_vfs_req
    mov edi,OFFSET start_vfs_req_name
    xor cl,cl
    mov ax,start_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET is_vfs_req_done
    mov edi,OFFSET is_vfs_req_done_name
    xor cl,cl
    mov ax,is_vfs_req_done_nr
    RegisterServGate
;
    mov esi,OFFSET add_wait_for_vfs_req
    mov edi,OFFSET add_wait_for_vfs_req_name
    xor cl,cl
    mov ax,add_wait_for_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET wait_for_vfs_cmd
    mov edi,OFFSET wait_for_vfs_cmd_name
    xor cl,cl
    mov ax,wait_for_vfs_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET reply_vfs_cmd
    mov edi,OFFSET reply_vfs_cmd_name
    xor cl,cl
    mov ax,reply_vfs_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET test_serv
    mov edi,OFFSET test_serv_name
    mov ax,test_serv_nr
    RegisterServGate
;
    mov esi,OFFSET add_vfs_sectors
    mov edi,OFFSET add_vfs_sectors_name
    xor cl,cl
    mov ax,add_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET remove_vfs_sectors
    mov edi,OFFSET remove_vfs_sectors_name
    xor cl,cl
    mov ax,remove_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET map_vfs_req
    mov edi,OFFSET map_vfs_req_name
    xor cl,cl
    mov ax,map_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET unmap_vfs_req
    mov edi,OFFSET unmap_vfs_req_name
    xor cl,cl
    mov ax,unmap_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET check_vfs_drive
    mov edi,OFFSET check_vfs_drive_name
    xor cl,cl
    mov ax,check_vfs_drive_nr
    RegisterOsGate
;
    mov esi,OFFSET get_vfs_cur_dir
    mov edi,OFFSET get_vfs_cur_dir_name
    xor cl,cl
    mov ax,get_vfs_cur_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET get_vfs_drive_disc
    mov edi,OFFSET get_vfs_drive_disc_name
    xor dx,dx
    mov ax,get_vfs_drive_disc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_vfs_drive_start
    mov edi,OFFSET get_vfs_drive_start_name
    xor dx,dx
    mov ax,get_vfs_drive_start_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_vfs_drive_size
    mov edi,OFFSET get_vfs_drive_size_name
    xor dx,dx
    mov ax,get_vfs_drive_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_vfs_drive_free
    mov edi,OFFSET get_vfs_drive_free_name
    xor dx,dx
    mov ax,get_vfs_drive_free_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET is_vfs_path16
    mov esi,OFFSET is_vfs_path32
    mov edi,OFFSET is_vfs_path_name
    mov dx,virt_es_in
    mov ax,is_vfs_path_nr
    RegisterUserGate
;
    mov ebx,OFFSET open_vfs_dir16
    mov esi,OFFSET open_vfs_dir32
    mov edi,OFFSET open_vfs_dir_name
    mov dx,virt_es_in
    mov ax,open_vfs_dir_nr
    RegisterUserGate
    ret
init_server    Endp

code    ENDS

    END
