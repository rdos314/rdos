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
; VFSfile.ASM
; VFS file part
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

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern AllocateMsg:near
    extern AddMsgBuffer:near
    extern RunMsg:near
    extern GetDrivePart:near
    extern GetPathDrive:near
    extern GetRelDir:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenVfsFile
;
;       DESCRIPTION:    Open VFS file
;
;       PARAMETERS:     ES:(E)DI       Pathname
;
;       RETURNS:        NC
;                         BX           Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_vfs_file_name       DB 'Open VFS File',0

open_vfs_file    Proc near
    push ds
    push es
    push fs
    push gs
    push eax
    push ecx
    push esi
    push edi
    push ebp
;
    mov eax,es
    mov gs,eax
;
    call GetPathDrive
    jc ovfFail
;
    call GetDrivePart
    or bx,bx
    jz ovfFail
;
    mov ah,es:[edi]
    cmp ah,'/'
    je ovfRoot
;
    cmp ah,'\'
    je ovfRoot

ovfRel:
    call GetRelDir
    jmp ovfHasStart

ovfRoot:
    inc edi
    xor ax,ax

ovfHasStart:
    mov esi,edi
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    movzx eax,ax
    call AllocateMsg

ovfCopyPath:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz ovfCopyPath
;
    mov eax,VFS_OPEN_FILE
    call RunMsg
    jc ovfFail
;
    clc
    jmp ovfDone

ovfFail:
    stc

ovfDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
open_vfs_file    Endp

open_vfs_file16  Proc far
    push esi
    push edi
    movzx esi,si
    movzx edi,di
    call open_vfs_file
    pop edi
    pop esi
    ret
open_vfs_file16  Endp

open_vfs_file32  Proc far
    call open_vfs_file
    ret
open_vfs_file32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_file
;
;       description:    Init file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_file

init_file    Proc near
    mov ax,cs
    mov ds,ax
    mov es,ax 
;
    mov ebx,OFFSET open_vfs_file16
    mov esi,OFFSET open_vfs_file32
    mov edi,OFFSET open_vfs_file_name
    mov dx,virt_es_in
    mov ax,open_vfs_file_nr
    RegisterUserGate
    ret
init_file    Endp

code    ENDS

    END
