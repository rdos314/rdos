;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
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
; FILEMAP.ASM
; File mapping in user space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.def
include ..\handle.inc
INCLUDE ..\filemap.inc
INCLUDE ..\os\memblk.inc
INCLUDE ..\os\exec.def
include vfs.inc
include vfsmsg.inc
include vfsfile.inc

    .386p

kernel_file       STRUC

kf_memblk         mem_blk_header <>

kf_info_phys      DD ?,?
kf_sector_size    DW ?
kf_section        section_typ <>
kf_prog_list      DW ?

kernel_file       ENDS

kernel_file_map   STRUC

kfm_wait_arr      DW 224 DUP(?)
kfm_flat_base     DD ?
kfm_map_base      DD ?
kfm_prog_sel      DW ?
kfm_file_sel      DW ?
kfm_next_map      DW ?
kfm_section       section_typ <>

kernel_file_map   ENDS

data    SEGMENT byte public 'DATA'

sys_section       section_typ <>

data    ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern AllocateMsg:near
    extern RunMsg:near
    extern PostMsg:near
    extern BlockToBuf:near
    extern GetDrivePart:near
    extern GetPathDrive:near
    extern GetRelDir:near
    extern HandleHighToPartFs:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetFileSel
;
;       DESCRIPTION:    Get file selector
;
;       PARAMETERS:     EBX            File handle
;
;       RETURNS:        NC
;                         AX           File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFileSel	Proc near
    push fs
;
    mov al,VFS_FILE_SIGN
    call HandleHighToPartFs
    jc gfsDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc gfsDone
;
    movzx eax,bx
    dec eax
    shl eax,2
    mov ax,fs:[eax].vfsp_file_arr.ff_sel
    or ax,ax
    stc
    je gfsDone
;
    clc

gfsDone:
    pop fs
    ret
GetFileSel     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateFileSel
;
;       DESCRIPTION:    Create file selector
;
;       PARAMETERS:     CX             Sector size
;                       EDX            File info linear
;
;       RETURNS:        NC
;                         AX           File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateFileSel

CreateFileSel	Proc near
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    push ecx
    mov ax,8
    mov cx,16
    mov si,SIZE kernel_file - SIZE mem_blk_header
    CreateMemBlk64
    pop ecx
;
    InitSection es:kf_section
    mov es:kf_sector_size,cx
    mov es:kf_prog_list,0
;
    GetPageEntry
    or ax,800h
    SetPageEntry
;
    and ax,0F000h
    mov es:kf_info_phys,eax
    mov es:kf_info_phys+4,ebx
;
    mov ax,es
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CreateFileSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProgSel
;
;       DESCRIPTION:    Get program selector
;
;       PARAMETERS:     DS		File sel
;
;       RETURNS:        NC
;                         AX            Prog sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetProgSel	Proc near
    push es
    push ebx
;
    GetThread
    mov es,ax
    mov bx,es:p_prog_sel
;
    EnterSection ds:kf_section
    mov ax,ds:kf_prog_list

gpsLoop:
    or ax,ax
    stc
    jz gpsDone
;
    mov es,eax
    cmp bx,es:kfm_prog_sel
    clc
    je gpsDone
;
    mov ax,es:kfm_next_map
    jmp gpsLoop

gpsDone:
    LeaveSection ds:kf_section
;
    pop ebx
    pop es
    ret
GetProgSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateProgSel
;
;       DESCRIPTION:    Create program selector
;
;       PARAMETERS:     DS		File sel
;
;       RETURNS:        NC
;                         AX            Prog sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateProgSel	Proc near
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,system_data_sel
    mov es,ax
    mov ebx,es:flat_base
;
    GetThread
    mov es,ax
    mov si,es:p_prog_sel
;
    mov ax,flat_data_sel
    mov es,eax
;
    mov eax,3000h
    AllocateLocalLinear
;
    sub edx,ebx
    mov edi,edx
    xor eax,eax
    mov ecx,800h
    rep stosd
    int 3
;
    push ebx
    push edx
;
    add edx,ebx
    GetPageEntry
    mov al,65h
    SetPageEntry
;
    add edx,2000h
    mov eax,ds:kf_info_phys
    mov ebx,ds:kf_info_phys+4
    or ax,865h
    SetPageEntry
;
    pop edx
    pop ebx
;
    mov eax,SIZE kernel_file_map
    AllocateSmallGlobalMem
;
    xor edi,edi
    xor eax,eax
    mov ecx,SIZE kernel_file_map
    shr ecx,2
    rep stosd
;
    mov es:kfm_flat_base,ebx
    mov es:kfm_map_base,edx
    mov es:kfm_prog_sel,si
    mov es:kfm_file_sel,ds
;
    EnterSection ds:kf_section
    mov bx,ds:kf_prog_list
    mov es:kfm_next_map,bx
    mov ds:kf_prog_list,es
    LeaveSection ds:kf_section
    mov ax,es
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CreateProgSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyFileData
;
;       DESCRIPTION:    Notify file data
;
;       PARAMETERS:     GS                 File req
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NotifyFileData

NotifyFileData	Proc near
    int 3
    ret
NotifyFileData  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenFile
;
;       DESCRIPTION:    Open file
;
;       PARAMETERS:     ES:(E)DI       Pathname
;
;       RETURNS:        NC
;                         BX           Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file_name       DB 'Open VFS File',0

org_open DD ?,?

open_vfs_file    Proc near
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
    call GetFileSel
    jc ovfFail
;
    int 3
    mov ds,eax
    call GetProgSel
    jnc ovfHasProc
;
    call CreateProgSel

ovfHasProc:
    mov ds,eax
    clc
    jmp ovfDone

ovfFail:
    stc

ovfDone:
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
open_vfs_file    Endp

open_file16  Proc far
    push edi
    movzx edi,di
    call open_vfs_file
    jnc ovf16Done
;
    call fword ptr cs:org_open

ovf16Done:
    pop edi
    ret
open_file16  Endp

open_file32  Proc far
    call open_vfs_file
    jnc ovf32Done
;
    call fword ptr cs:org_open

ovf32Done:
    ret
open_file32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadFile
;
;       DESCRIPTION:    Read file
;
;       PARAMETERS:     BX             Handle
;                       ES:(E)DI       Buffer
;                       (E)CX          Size
;
;       RETURNS:        NC
;                         EAX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_file_name       DB 'Read VFS File',0

org_read DD ?,?

read_file16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call fword ptr cs:org_read
;
    pop edi
    pop ecx
    ret
read_file16  Endp

read_file32  Proc far
    call fword ptr cs:org_read
    ret
read_file32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete handle
;
;           DESCRIPTION:    Delete a handle (called from handle module)
;
;           PARAMETERS:     BX              HANDLE TO FILE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle   Proc far
    push ds
    push ax
    push ebx
    push edx
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jc dhDone
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
;       NAME:           init_client_file
;
;       description:    Init file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_client_file

init_client_file    Proc near
    mov bx,SEG data
    mov ds,ebx
    InitSection ds:sys_section
;
    mov ebx,cs
    mov ds,ebx
    mov es,ebx
    GetSelectorBaseSize
    AllocateGdt
    CreateDataSelector32
    mov fs,bx
;
    mov edi,OFFSET delete_handle
    mov ax,VFS_FILE_HANDLE
    RegisterHandle
;
    mov ebx,OFFSET open_file16
    mov esi,OFFSET open_file32
    mov edi,OFFSET open_file_name
    mov dx,virt_es_in
    mov ax,open_file_nr
    LinkUserGate
    mov dword ptr fs:org_open,eax
    mov word ptr fs:org_open+4,dx
;
    mov ebx,OFFSET read_file16
    mov esi,OFFSET read_file32
    mov edi,OFFSET read_file_name
    mov dx,virt_es_in
    mov ax,read_file_nr
    LinkUserGate
    mov dword ptr fs:org_read,eax
    mov word ptr fs:org_read+4,dx
;
    mov ebx,fs
    xor eax,eax
    mov fs,eax
    FreeGdt    
    ret
init_client_file    Endp

code    ENDS

    END
