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
;       NAME:           StartVfs
;
;       DESCRIPTION:    Start VFS
;
;       PARAMETERS:     DS:ESI  Server startup proc
;                       ES:EDI  Server thread name
;                       BX      Data passed to server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_vfs_name       DB 'Start VFS',0

start_vfs    Proc far
    push ax
    mov al,4
    CreateServerProcess
    pop ax
    ret
start_vfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateVfs
;
;       DESCRIPTION:    Create VFS
;
;       PARAMETERS:     EDX:EAX Sectors
;                       CX      Bytes per sector
;
;       RETURNS:        ES      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateVfs   Proc near
    push eax
    mov eax,SIZE vfs_struc
    AllocateSmallGlobalMem
    pop eax
;
    mov es:vfs_sectors,eax
    mov es:vfs_sectors+4,edx
    mov es:vfs_bytes_per_sector,cx
    ret
CreateVfs  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenDynamicVfs
;
;       DESCRIPTION:    Open dynamic vfs
;
;       PARAMETERS:     EDX:EAX Sectors
;                       CX      Bytes per sector
;
;       RETURNS:        BX      VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_dynamic_vfs_name       DB 'Open Dynamic VFS',0

open_dynamic_vfs    Proc far
    push es
;
    int 3
    call CreateVfs
;
    mov bx,es
;
    pop es
    ret
open_dynamic_vfs    Endp

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
    mov esi,OFFSET open_dynamic_vfs
    mov edi,OFFSET open_dynamic_vfs_name
    xor cl,cl
    mov ax,open_dynamic_vfs_nr
    RegisterOsGate
    clc
    ret
init    Endp


code    ENDS

    END init
