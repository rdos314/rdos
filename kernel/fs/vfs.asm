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
;       NAME:           CreateEntry
;
;       DESCRIPTION:    Create entry
;
;       RETURNS:        EAX       Entry linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEntry    Proc near
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigServ
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov eax,edx
;
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
CreateEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LocalLockSector
;
;       DESCRIPTION:    Lock sector
;
;       PARAMETERS:     ES          VFS sel
;                       EDX:EAX     Sector #
;
;       RETURNS:        NC
;                         EBX:EAX   Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalLockSector    Proc near
    int 3
;
    mov eax,es:[bx]
    test ax,VFS_BUF_PRESENT
    jnz llsEntryOk
;
    call CreateEntry
    or ax,VFS_BUF_PRESENT
    mov es:[bx],eax

llsEntryOk:


llsDone:
    ret
LocalLockSector    Endp

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
;       NAME:           CalcParam
;
;       DESCRIPTION:    Calculate schedule params
;
;       PARAMETERS:     ES      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam    Proc near
    mov eax,es:vfs_sectors
    mov edx,es:vfs_sectors+4
    mov bx,es:vfs_bytes_per_sector
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
    mov es:vfs_sector_shift,al
;
    add eax,1
    adc edx,0
    mov es:vfs_blocks,eax
    mov es:vfs_blocks+4,edx
;
    mov ebx,eax
    rol ebx,3
    and bl,7
    shl edx,3
    or dl,bl
    inc edx
    mov es:vfs_buf_count,edx
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
;       PARAMETERS:     ES      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBuffer    Proc near
    mov eax,es:vfs_buf_count
    shl eax,2
    add eax,OFFSET vfs_buf_arr
    AllocateSmallLinear
    mov edi,edx
;
    mov bx,es
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
    mov es,bx
;
    mov ecx,es:vfs_buf_count
    mov edi,OFFSET vfs_buf_arr
    xor eax,eax
    rep stos dword ptr es:[edi]
    ret
CreateBuffer   Endp    

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
    mov es,bx
    mov es:vfs_server,ax
;
    mov bx,es:vfs_param
    call fword ptr es:vfs_init
    jc vfsTerm
;
    int 3
    mov es:vfs_sectors,eax
    mov es:vfs_sectors+4,edx
    mov es:vfs_bytes_per_sector,cx
    mov es:vfs_max_req,bx
;
    call CalcParam
    call CreateBuffer
;
    mov ax,serv_flat_sel
    mov ds,ax
    mov eax,5000h
    AllocateBigServ
    mov al,ds:[edx]
    add edx,5000h
    mov al,ds:[edx]
;
    xor eax,eax
    xor edx,edx
    call LocalLockSector

vfsLoop:
    WaitForSignal
;
    test es:vfs_flags,VFS_FLAG_STOPPED
    jnz vfsExit
;
    jmp vfsLoop

vfsExit:
    mov bx,es:vfs_param
    call fword ptr es:vfs_exit

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
