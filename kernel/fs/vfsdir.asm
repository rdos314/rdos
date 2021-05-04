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

    .386p

MAX_PART_COUNT   = 255

GET_DIR            = 1

REPLY_DEFAULT      = 0
REPLY_BLOCK        = 1

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
drive_section   section_typ <>

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern AllocateMsg:near
    extern RunMsg:near
    extern MapBlock:near
    extern GetDrivePart:near

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
    push ebx
;
    call GetDrivePart
    mov bx,SEG data
    or bx,bx
    stc
    jz gvcdDone
;
    xor bl,bl
    mov es:[edi],bl
    clc

gvcdDone:
    pop ebx
    ret
get_vfs_cur_dir   Endp

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
    jz odCreate
;
    mov es,dx
    lock add es:ds_ref_count,1
    clc
    jmp odLeave

odCreate:
    push ebx
    call GetDrivePart
    mov dx,bx
    pop ebx
    or dx,dx
    stc
    jz odLeave
;
    push eax
    mov eax,SIZE drive_seg
    AllocateSmallGlobalMem
    pop eax
;
    mov es:ds_part_sel,dx
    mov es:ds_ref_count,1
    mov es:ds_deleted,0
    mov es:ds_drive,al
    mov ds:[ebx].drive_arr,es
    mov bx,es   
    clc

odLeave:
    LeaveSection ds:drive_section
;
    pop edx
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
    cmp ax,ds:[ebx].drive_arr
    jne cdLeave
;
    mov ds:[ebx].drive_arr,0

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
    push ds
    push es
    push fs
    push gs
    push eax
    push ecx
    push esi
    push edi
;    
    mov eax,es
    mov gs,eax
;
    call GetPathDrive
    jc ovdDone
;
    call GetDrivePart
    or bx,bx
    stc
    jz ovdDone
;
    mov esi,edi
    xor eax,eax
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    call AllocateMsg

ovdCopyPath:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz ovdCopyPath
;
    mov eax,GET_DIR
    call RunMsg
    jc ovdDone
;
    call MapBlock

ovdDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
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
init_dir    Endp

code    ENDS

    END
