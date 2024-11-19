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
; VFSdir.ASM
; VFS dir part
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
include vfsmsg.inc

    .386p

MAX_PART_COUNT   = 255

REPLY_DEFAULT      = 0
REPLY_BLOCK        = 1

drive_seg   STRUC

ds_ref_count     DW ?
ds_drive         DB ?
ds_deleted       DB ?

drive_seg   ENDS

dir_handle_seg  STRUC

dh_base          handle_header <>

dh_linear        DD ?
dh_user          DD ?
dh_count         DD ?
dh_header_size   DD ?
dh_size          DD ?

dir_handle_seg  ENDS

dir_info_struc  STRUC

dis_linear       DD ?
dis_header_size  DD ?
dis_count        DD ?

dir_info_struc  ENDS

dir_entry_struc  STRUC

des_inode         DD ?,?
des_size          DD ?,?
des_cr_time       DD ?,?
des_acc_time      DD ?,?
des_mod_time      DD ?,?
des_attrib        DD ?
des_flags         DD ?
des_uid           DD ?
des_gid           DD ?
des_pos           DD ?
des_name_size     DW ?
des_name          DB ?

dir_entry_struc  ENDS

data    SEGMENT byte public 'DATA'

drive_arr       DW MAX_PART_COUNT DUP (?)
drive_section   section_typ <>

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern AllocateMsg:near
    extern AddMsgBuffer:near
    extern RunMsg:near
    extern GetDrivePart:near
    extern MapBlockToUser:near
    extern FreeUserBlock:near
    extern FreeBlock:near

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
    push ebx
;
    call GetDrivePart
    or bx,bx
    stc
    jz cvdDone
;
    clc

cvdDone:
    pop ebx
    ret
check_vfs_drive   Endp

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
    call GetDrivePart
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
;       NAME:           CreateDriveSel
;
;       DESCRIPTION:    Create drive sel
;
;       PARAMETERS:     AL           Drive #
;
;       RETURNS:        NC
;                         BX         Drive sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDriveSel   Proc near
    push ds
    push es
    push edx
;
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:drive_section
;
    movzx ebx,al
    shl ebx,1
    mov dx,ds:[ebx].drive_arr
    or dx,dx
    jz cdsCreate
;
    mov es,dx
    lock add es:ds_ref_count,1
    clc
    jmp cdsLeave

cdsCreate:
    push eax
    mov eax,SIZE drive_seg
    AllocateSmallGlobalMem
    pop eax
;
    mov es:ds_ref_count,1
    mov es:ds_deleted,0
    mov es:ds_drive,al
    mov ds:[ebx].drive_arr,es
    mov bx,es   
    clc

cdsLeave:
    LeaveSection ds:drive_section
;
    pop edx
    pop es
    pop ds
    ret
CreateDriveSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeDriveSel
;
;       DESCRIPTION:    Free drive sel
;
;       PARAMETERS:     BX           Drive sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDriveSel   Proc near
    push ds
    push es
    push eax
;
    mov es,bx
    lock sub es:ds_ref_count,1
    jnz fdsDone
;
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:drive_section
    movzx ebx,es:ds_drive
    shl ebx,1
    mov ax,es
    cmp ax,ds:[ebx].drive_arr
    jne fdsLeave
;
    mov ds:[ebx].drive_arr,0

fdsLeave:
    LeaveSection ds:drive_section

fdsFree:
    FreeMem

fdsDone:
    xor bx,bx
;
    pop eax
    pop es
    pop ds
    ret
FreeDriveSel   Endp

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

    public GetPathDrive

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
;       NAME:           CloneRelDir
;
;       DESCRIPTION:    Clone relative dir
;
;       PARAMETERS:     AL          Drive
;                       BX          Start dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloneRelDir    Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    push bx
    call GetDrivePart
    pop ax
    or bx,bx
    jz crdFail
;
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    movzx eax,ax
    call AllocateMsg
    jc crdFail
;
    mov eax,VFS_CLONE_REL_DIR
    call RunMsg

crdFail:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
CloneRelDir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeRelDir
;
;       DESCRIPTION:    Free relative dir
;
;       PARAMETERS:     AL          Drive
;                       BX          Start dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeRelDir    Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    push bx
    call GetDrivePart
    pop ax
    or bx,bx
    jz frdFail
;
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    movzx eax,ax
    call AllocateMsg
    jc frdFail
;
    mov eax,VFS_UNLOCK_REL_DIR
    call RunMsg

frdFail:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
FreeRelDir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetRelDir
;
;       DESCRIPTION:    Get relative dir
;
;       PARAMETERS:     AL          Drive
;
;       RETURNS:        AX          Start dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetRelDir

GetRelDir    Proc near
    push ds
    push ebx
;
    movzx bx,al
    shl bx,1
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    mov ax,ds:[bx].pc_vfs_sel_arr
    or ax,ax
    jz grdDone
;
    push es
    mov es,ax
    xor ax,ax
    cmp es:ds_deleted,0
    jnz grdHasHandle
;    
    mov ax,ds:[bx].pc_vfs_handle_arr

grdHasHandle:
    pop es
 
grdDone:
    pop ebx
    pop ds
    ret
GetRelDir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetRelDir
;
;       DESCRIPTION:    Set relative dir
;
;       PARAMETERS:     AL          Drive
;                       BX          Start dir handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetRelDir    Proc near
    push ds
    push es
    push esi
;
    movzx si,al
    shl si,1
;
    push ax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_cur_dir_sel
    pop ax
;
    push bx
;
    mov bx,ds:[si].pc_vfs_sel_arr
    or bx,bx
    jz srdOpen
;
    mov es,bx
    cmp es:ds_deleted,0
    jz srdLink
;
    call FreeDriveSel

srdOpen:
    call CreateDriveSel
    mov ds:[si].pc_vfs_sel_arr,bx
    mov es,bx

srdLink:    
    pop bx    
    xchg bx,ds:[si].pc_vfs_handle_arr
    or bx,bx
    jz srdDone
;
    call FreeRelDir
 
srdDone:
    pop esi
    pop es
    pop ds
    ret
SetRelDir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloneVfsCurDir
;
;       DESCRIPTION:    Clone cur dir
;
;       PARAMETERS:     DS          Source dir
;                       ES          Dest dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_vfs_cur_dir_name DB 'Clone VFS Cur Dir', 0

clone_vfs_cur_dir   Proc far
    push fs
    push eax
    push ebx
    push ecx
;
    xor ebx,ebx
    mov ecx,32

cvcdLoop:
    mov ax,ds:[bx].pc_vfs_sel_arr
    or ax,ax
    jz cvcdClear
;
    mov fs,ax
    cmp fs:ds_deleted,0
    jnz cvcdClear
;
    lock add fs:ds_ref_count,1
    mov es:[bx].pc_vfs_sel_arr,fs
    mov ax,ds:[bx].pc_vfs_handle_arr
    or ax,ax
    jz cvcdSave
;
    push ax
    push bx
;
    xchg ax,bx
    shr al,1
    call CloneRelDir
;
    pop bx
    pop ax

cvcdSave:
    mov es:[bx].pc_vfs_handle_arr,ax
    jmp cvcdNext

cvcdClear:
    mov es:[bx].pc_vfs_sel_arr,0
    mov es:[bx].pc_vfs_handle_arr,0

cvcdNext:
    add bx,2
    loop cvcdLoop
;
    pop ecx
    pop ebx
    pop eax
    pop fs
    ret
clone_vfs_cur_dir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeVfsCurDir
;
;       DESCRIPTION:    Free vfs cur dir
;
;       PARAMETERS:     AX          Drive sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_vfs_cur_dir_name DB 'Free VFS Cur Dir', 0

free_vfs_cur_dir   Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push esi
;
    mov es,ax
;
    xor esi,esi
    mov ecx,32

fvcdLoop:
    mov ax,es:[si].pc_vfs_sel_arr
    or ax,ax
    jz fvcdNext
;
    mov ds,ax
    cmp ds:ds_deleted,0
    jnz fvcdFree
;
    mov bx,es:[si].pc_vfs_handle_arr
    or bx,bx
    jz fvcdFree
;
    mov ax,si
    shr ax,1
    call FreeRelDir

fvcdFree:
    mov bx,es:[si].pc_vfs_sel_arr
    call FreeDriveSel

fvcdNext:
    add si,2
    loop fvcdLoop
;
    FreeMem
    clc
;
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
free_vfs_cur_dir   Endp

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
    push gs
    pushad
;
    mov ebx,es
    mov gs,ebx
;
    call GetDrivePart
    or bx,bx
    stc
    jz gvcdDone
;
    call GetRelDir
    or ax,ax
    jz gvcdRoot
;
    push ds
    push es
    push fs
;
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    push edi
    call AllocateMsg
    pop edi
    jc gvcdSent
;
    mov ecx,512
    call AddMsgBuffer
;
    mov eax,VFS_GET_REL_DIR
    call RunMsg

gvcdSent:
    pop fs
    pop es
    pop ds
    jmp gvcdDone

gvcdRoot:
    xor bl,bl
    mov es:[edi],bl
    clc

gvcdDone:
    popad
    pop gs
    ret
get_vfs_cur_dir   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetVfsCurDir
;
;       DESCRIPTION:    Set VFS cur dir
;
;       PARAMETERS:     ES:EDI    Path
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_vfs_cur_dir_name DB 'Set VFS Cur Dir', 0

set_vfs_cur_dir   Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov eax,es
    mov gs,eax
;
    call GetPathDrive
    jc svcdFail
;
    call GetDrivePart
    or bx,bx
    jz svcdFail
;
    push eax
;
    mov ah,es:[edi]
    cmp ah,'/'
    je svcdRoot
;
    cmp ah,'\'
    je svcdRoot

svcdRel:
    call GetRelDir
    jmp svcdHasStart

svcdRoot:
    inc edi
    xor ax,ax

svcdHasStart:
    mov esi,edi
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    movzx eax,ax
    call AllocateMsg
    jnc svcdCopyPath
;
    pop eax
    jmp svcdFail

svcdCopyPath:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz svcdCopyPath
;
    mov eax,VFS_LOCK_REL_DIR
    call RunMsg
    mov bx,ax
    pop eax
    jc svcdFail
;
    call SetRelDir
    clc
    jmp svcdDone

svcdFail:
    stc

svcdDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
set_vfs_cur_dir   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadVfsDir
;
;       DESCRIPTION:    Read VFS dir
;
;       PARAMETERS:     ES:EDI         Pathname
;                       DS:ESI         Info
;
;       RETURNS:        NC
;                         BX           Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadVfsDir    Proc near
    push es
    push fs
    push gs
    push eax
    push ecx
    push edi
    push ebp
;    
    push ds
    push esi
;
    mov eax,es
    mov gs,eax
;
    call GetPathDrive
    jc rvdFail
;
    call GetDrivePart
    or bx,bx
    jz rvdFail
;
    mov ah,es:[edi]
    cmp ah,'/'
    je rvdRoot
;
    cmp ah,'\'
    je rvdRoot

rvdRel:
    call GetRelDir
    jmp rvdHasStart

rvdRoot:
    inc edi
    xor ax,ax

rvdHasStart:
    mov esi,edi
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    movzx eax,ax
    call AllocateMsg
    jc rvdFail

rvdCopyPath:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz rvdCopyPath
;
    mov eax,VFS_GET_DIR
    call RunMsg
    jc rvdFail
;
    push ecx
    mov cx,SIZE dir_handle_seg
    AllocateHandle
    pop ecx
;
    mov [ebx].dh_size,0
    mov [ebx].dh_linear,ebp
    mov [ebx].dh_count,ecx
    mov [ebx].dh_header_size,eax
    mov [ebx].hh_sign,VFS_DIR_HANDLE
;
    mov edx,ebp
    call MapBlockToUser
    mov [ebx].dh_user,edx
;
    mov bx,[ebx].hh_handle
;
    pop esi
    pop ds
;
    add edx,SIZE share_block_struc
    mov ds:[esi].dis_linear,edx
    mov ds:[esi].dis_header_size,eax
    mov ds:[esi].dis_count,ecx
    clc
    jmp rvdDone

rvdFail:
    pop esi
    pop ds
    stc

rvdDone:
    pop ebp
    pop edi
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    ret
ReadVfsDir    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadLegacyDir
;
;       DESCRIPTION:    Read legacy dir
;
;       PARAMETERS:     ES:EDI         Pathname
;                       DS:ESI         Info
;
;       RETURNS:        NC             OK
;                         BX           Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ReadLegacyDir    Proc near
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    OpenDir
    jc rldDone
;
    mov eax,100h
    AllocateSmallGlobalMem
;
    mov ds:[esi].dis_linear,0
    mov ds:[esi].dis_header_size,SIZE dir_entry_struc
    mov ds:[esi].dis_count,0
;
    xor dx,dx

rldSizeLoop:
    push ebx
    push edx
;
    xor edi,edi
    mov ecx,100h
    ReadDir
;
    pop edx
    pop ebx
    jc rldSizeDone
;
    add ds:[esi].dis_linear,SIZE dir_entry_struc

rldSizeOne:
    mov al,es:[edi]
    or al,al
    jz rldSizeFound
;
    inc ds:[esi].dis_linear
    inc edi
    jmp rldSizeOne

rldSizeFound:
    inc ds:[esi].dis_count
    inc dx
    jmp rldSizeLoop

rldSizeDone:
    FreeMem
;
    mov eax,ds:[esi].dis_linear
    AllocateLocalLinear
    mov edi,edx
;
    mov ax,system_data_sel
    mov es,eax
    sub edx,es:flat_base
    mov ds:[esi].dis_linear,edx
;
    mov ax,flat_sel
    mov es,eax
    xor edx,edx
    mov ebp,edi
    add edi,OFFSET des_name

rldGetLoop:
    cmp edx,ds:[esi].dis_count
    je rldGetDone
;
    push ebx
    push edx
;
    lea edi,[ebp].des_name
    mov ecx,100h
    ReadDir
;
    mov es:[ebp].des_cr_time,eax
    mov es:[ebp].des_cr_time+4,edx
;
    mov es:[ebp].des_acc_time,eax
    mov es:[ebp].des_acc_time+4,edx
;
    mov es:[ebp].des_mod_time,eax
    mov es:[ebp].des_mod_time+4,edx
;
    movzx ebx,bx
    mov es:[ebp].des_attrib,ebx
;
    pop edx
    pop ebx
    jc rldGetDone
;
    mov es:[ebp].des_inode,edx
    mov es:[ebp].des_inode+4,0
;
    mov es:[ebp].des_size,ecx
    mov es:[ebp].des_size+4,0
;
    mov es:[ebp].des_flags,0
    mov es:[ebp].des_uid,0
    mov es:[ebp].des_gid,0
    mov es:[ebp].des_pos,0
;
    mov es:[ebp].des_name_size,0

rldGetSize:
    mov al,es:[edi]
    or al,al
    jz rldGetSizeFound
;
    inc es:[ebp].des_name_size
    inc edi
    jmp rldGetSize

rldGetSizeFound:
    inc edx
    movzx eax,es:[ebp].des_name_size
    add ebp,eax
    add ebp,SIZE dir_entry_struc
    jmp rldGetLoop

rldGetDone:
    CloseDir
;
    mov edx,ebp
    mov ebp,ds:[esi].dis_linear
    sub edx,ebp
    mov ecx,ds:[esi].dis_count
;
    push ds
    push esi
;
    mov cx,SIZE dir_handle_seg
    AllocateHandle
;
    mov [ebx].dh_size,edx
    mov [ebx].dh_user,0
    mov [ebx].dh_linear,ebp
    mov [ebx].dh_count,ecx
    mov [ebx].dh_header_size,eax
    mov [ebx].hh_sign,VFS_DIR_HANDLE
;
    mov bx,[ebx].hh_handle
;
    pop esi
    pop ds
    clc

rldDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
ReadLegacyDir    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenVfsDir
;
;       DESCRIPTION:    Open VFS dir
;
;       PARAMETERS:     ES:(E)DI       Pathname
;                       DS:(E)SI       Info
;
;       RETURNS:        NC
;                         BX           Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_vfs_dir_name       DB 'Open VFS Dir',0

open_vfs_dir16  Proc far
    push esi
    push edi
    movzx esi,si
    movzx edi,di
;
    mov ds:[esi].dis_linear,0
    mov ds:[esi].dis_header_size,0
    mov ds:[esi].dis_count,0
;
    call ReadVfsDir
    jnc ovfDone16
;
    call ReadLegacyDir

ovfDone16:
    pop edi
    pop esi
    ret
open_vfs_dir16  Endp

open_vfs_dir32  Proc far
    mov ds:[esi].dis_linear,0
    mov ds:[esi].dis_header_size,0
    mov ds:[esi].dis_count,0
;
    call ReadVfsDir
    jnc ovfDone32
;
    call ReadLegacyDir

ovfDone32:
    ret
open_vfs_dir32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloseVfsDir
;
;       DESCRIPTION:    Close VFS dir
;
;       PARAMETERS:     BX           Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_vfs_dir_name       DB 'Close VFS Dir',0

close_vfs_dir    Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
;
    mov ax,VFS_DIR_HANDLE
    DerefHandle
    jc ccdDone
;
    mov ecx,ds:[ebx].dh_size
    or ecx,ecx
    jz ccdVfs
;
    mov edx,ds:[ebx].dh_user
    mov ax,system_data_sel
    mov es,eax
    add edx,es:flat_base
    FreeLinear
    jmp ccdHandle

ccdVfs:
    mov edx,ds:[ebx].dh_user
    call FreeUserBlock
;
    mov edx,ds:[ebx].dh_linear
    call FreeBlock

ccdHandle:
    FreeHandle
    clc

ccdDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
close_vfs_dir  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDirEntryAttrib
;
;       DESCRIPTION:    Get VFS dir entry attrib
;
;       PARAMETERS:     ES:EDI    Pathname
;
;       RETURNS:        NC
;                         EAX     Attribute
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_dir_entry_attrib_name DB 'Get VFS Dir Entry Attrib', 0

get_vfs_dir_entry_attrib   Proc far
    push ds
    push es
    push fs
    push gs
    push ebx
    push ecx
    push esi
    push edi
;    
    mov eax,es
    mov gs,eax
;
    call GetPathDrive
    jc gvdeaDone
;
    call GetDrivePart
    or bx,bx
    stc
    jz gvdeaDone
;
    mov ah,es:[edi]
    cmp ah,'/'
    je gvdeaRoot
;
    cmp ah,'\'
    je gvdeaRoot

gvdeaRel:
    call GetRelDir
    jmp gvdeaHasStart

gvdeaRoot:
    inc edi
    xor ax,ax

gvdeaHasStart:
    mov esi,edi
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    movzx eax,ax
    call AllocateMsg
    jc gvdeaDone

gvdeaCopyPath:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz gvdeaCopyPath
;
    mov eax,VFS_GET_DIR_ENTRY_ATTRIB
    call RunMsg

gvdeaDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
get_vfs_dir_entry_attrib   Endp

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
    push edx
;
    mov ax,VFS_DIR_HANDLE
    DerefHandle
    jc dhDone
;
    mov edx,ds:[ebx].dh_user
    call FreeUserBlock
;
    mov edx,ds:[ebx].dh_linear
    call FreeBlock
;
    FreeHandle
    clc

dhDone:
    pop edx
    pop ebx
    pop ax
    pop ds
    ret
delete_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_dir
;
;       description:    Init dir
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_dir

init_dir    Proc near
    mov ax,SEG data
    mov es,ax
    InitSection es:drive_section
;
    mov edi,OFFSET drive_arr
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
    mov esi,OFFSET clone_vfs_cur_dir
    mov edi,OFFSET clone_vfs_cur_dir_name
    xor cl,cl
    mov ax,clone_vfs_cur_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET free_vfs_cur_dir
    mov edi,OFFSET free_vfs_cur_dir_name
    xor cl,cl
    mov ax,free_vfs_cur_dir_nr
    RegisterOsGate
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
    mov esi,OFFSET set_vfs_cur_dir
    mov edi,OFFSET set_vfs_cur_dir_name
    xor cl,cl
    mov ax,set_vfs_cur_dir_nr
    RegisterOsGate
;
    mov esi,OFFSET get_vfs_dir_entry_attrib
    mov edi,OFFSET get_vfs_dir_entry_attrib_name
    xor cl,cl
    mov ax,get_vfs_dir_entry_attrib_nr
    RegisterOsGate
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
;
    mov esi,OFFSET close_vfs_dir
    mov edi,OFFSET close_vfs_dir_name
    xor dx,dx
    mov ax,close_vfs_dir_nr
    RegisterBimodalUserGate
    ret
init_dir    Endp

code    ENDS

    END
