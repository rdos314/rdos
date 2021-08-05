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
; VFScfile.ASM
; VFS file client part
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
include vfsfile.inc

    .386p

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern AllocateMsg:near
    extern RunMsg:near
    extern GetDrivePart:near
    extern GetPathDrive:near
    extern GetRelDir:near
    extern HandleHighToPartFs:near

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
    push ebx
    push ecx
    mov cx,SIZE file_handle_seg
    AllocateHandle
    pop ecx
    pop eax
;
    mov [ebx].fh_vfs_sel,fs
    mov [ebx].fh_vfs_handle,eax
    mov [ebx].fh_attrib,ecx
    mov [ebx].fh_pos,0
    mov [ebx].fh_pos+4,0
    mov [ebx].hh_sign,VFS_FILE_HANDLE
    mov bx,[ebx].hh_handle
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
    push edi
    movzx edi,di
    call open_vfs_file
    pop edi
    ret
open_vfs_file16  Endp

open_vfs_file32  Proc far
    call open_vfs_file
    ret
open_vfs_file32  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetFileBlock
;
;       DESCRIPTION:    Get file block
;
;       PARAMETERS:     DS:EBX             File handle
;
;       RETURNS:        GS                 File block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFileBlock   Proc near
    push fs
    push eax
    push ebx
;
    mov al,FILE_SIGN
    mov ebx,ds:[ebx].fh_vfs_handle
    call HandleHighToPartFs
    jc gfbDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc gfbDone
;
    movzx ebx,bx
    dec ebx
    shl ebx,2
    mov ax,fs:[ebx].vfsp_file_arr.ff_sel
    or ax,ax
    stc
    je gfbDone
;
    mov gs,eax
    clc

gfbDone:
    pop ebx
    pop eax
    pop fs
    ret
GetFileBlock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TryRead
;
;       DESCRIPTION:    Try to read block
;
;       PARAMETERS:     GS             File block
;                       EDX:EAX        Position
;                       ECX            Size
;
;       RETURNS:        NC
;                         EAX          Read size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TryRead   Proc near
    push ecx
;
    mov ecx,0
    or ecx,ecx 
    stc
    jz trDone
;
    int 3

trDone:
    pop ecx
    ret
TryRead   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddFileReq
;
;       DESCRIPTION:    Add file req
;
;       PARAMETERS:     FS             VFS sel
;                       GS             File block
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFileReq   Proc near
    push ds
    push eax
    push ebx
;
    mov ds,fs:vfsp_disc_sel
    mov ebx,gs:fi_serv_handle
    call AllocateMsg
;
    mov eax,VFS_REQ_FILE
    call RunMsg
;
    pop ebx
    pop eax
    pop ds
    ret
AddFileReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadVfsFile
;
;       DESCRIPTION:    Read VFS file
;
;       PARAMETERS:     BX             Handle
;                       ES:(E)DI       Buffer
;                       (E)CX          Size
;
;       RETURNS:        NC
;                         EAX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_vfs_file_name       DB 'Read VFS File',0

read_vfs_file    Proc near
    push ds
    push fs
    push gs
    push eax
    push ebx
    push edx
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jc rvfDone
;
    call GetFileBlock
    jc rvfDone

rvfTry:
    mov eax,ds:[ebx].fh_pos
    mov edx,ds:[ebx].fh_pos+4
    call TryRead
    jc rvfReq
;
    int 3

rvfReq:
    mov fs,ds:[ebx].fh_vfs_sel
    call AddFileReq
    jnc rvfTry

rvfDone:
    pop edx
    pop ebx
    pop eax
    pop gs
    pop fs
    pop ds
    ret
read_vfs_file    Endp

read_vfs_file16  Proc far
    push ecx
    push edi
    movzx ecx,cx
    movzx edi,di
    call read_vfs_file
    pop edi
    pop ecx
    ret
read_vfs_file16  Endp

read_vfs_file32  Proc far
    call read_vfs_file
    ret
read_vfs_file32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddOneEntry
;
;       DESCRIPTION:    Add one file req entry
;
;       PARAMETERS:     DS:ESI      File req entry
;                       ES:EDI      Sector data
;                       EDX:EAX     Start position
;                       ECX         Sector count
;                       EBX         Sector size
;
;       RETURNS:        DS:ESI      Updated
;                       ES:EDI      Updated
;                       ECX         Updated
;                       EDX:EAX     Updated
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddOneEntry	Proc near
    push ebx
    push ebp
;
    push eax
    push edx
;
    mov ds:[esi].fre_pos,eax
    mov ds:[esi].fre_pos+4,edx
;
    mov ds:[esi].fre_last_size,0
    mov ds:[esi].fre_pages,0
;
    mov ebp,esi
    add ebp,OFFSET fre_arr
;
    mov eax,es:[edi]
    mov edx,es:[edi+4]
    test ax,0FFFh
    jz aoeFirstDone
;
    mov ds:[esi].fre_last_size,bx
    inc ds:[esi].fre_pages
    mov ds:[ebp],eax
    mov ds:[ebp+4],edx
    add ebp,8

aoeFirstLoop:
    add edi,8
    sub ecx,1
    jz aoeDone
;
    add eax,ebx
    test ax,0FFFh
    jz aoeFirstDone
;
    cmp eax,es:[edi]
    jnz aoeDone
;
    cmp edx,es:[edi+4]
    jnz aoeDone
;
    add ds:[esi].fre_last_size,bx
    jmp aoeFirstLoop

aoeFirstDone:
    mov ds:[ebp],eax
    mov ds:[ebp+4],edx
    add ebp,8
;
    mov ds:[esi].fre_last_size,bx
    inc ds:[esi].fre_pages

aoePageLoop:
    add edi,8
    sub ecx,1
    jz aoeDone
;
    add eax,ebx
    test ax,0FFFh
    jz aoePageNext
;
    cmp eax,es:[edi]
    jnz aoeDone
;
    cmp edx,es:[edi+4]
    jnz aoeDone
;
    add ds:[esi].fre_last_size,bx
    jmp aoePageLoop

aoePageNext:
    mov ds:[esi].fre_last_size,0
    jmp aoeFirstDone

aoeDone:
    movzx ebx,ds:[esi].fre_pages
    dec ebx
    shl ebx,12
;
    mov eax,ds:[esi].fre_arr
    and eax,0FFFh
    sub ebx,eax
;
    movzx eax,ds:[esi].fre_last_size
    add ebx,eax
    mov ds:[esi].fre_size,ebx

aoeSizeDone:
    pop edx
    pop eax
;
    add eax,ebx
    adc edx,0
;
    mov esi,ebp
;
    pop ebp
    pop ebx
    ret
AddOneEntry     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleFileData
;
;       DESCRIPTION:    Handle file data message
;
;       PARAMETERS:     ES:EDI      Sector data
;                       EDX:EAX     Start position
;                       BX          Req handle
;                       ECX         Sector count
;                       ESI         Sector size
;
;       RETURNS:        EBP         Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleFileData

HandleFileData	Proc near
    push ds
    push es
    push eax
    push ebx
    push esi
    push edi
;
    mov ebp,ebx
    dec ebp
    shl ebp,2
;    add ebp,OFFSET fs_handle_arr
;
;    mov bx,vfs_file_sel
;    mov ds,bx
;    EnterSection ds:fs_section
;    mov bx,ds:[ebp].fse_file_sel
;    LeaveSection ds:fs_section
    or bx,bx
    stc
    jz hfdDone
;
    mov ds,bx
    movzx esi,ds:fse_insert

hfdLoop:
    or ecx,ecx
    clc
    jz hfdDone
;
    call AddOneEntry
    mov ds:fse_insert,si
    jmp hfdLoop
;
    clc

hfdDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop es
    pop ds
    ret
HandleFileData  Endp

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
    mov ax,cs
    mov ds,ax
    mov es,ax 
;
    mov edi,OFFSET delete_handle
    mov ax,VFS_FILE_HANDLE
    RegisterHandle
;
    mov ebx,OFFSET open_vfs_file16
    mov esi,OFFSET open_vfs_file32
    mov edi,OFFSET open_vfs_file_name
    mov dx,virt_es_in
    mov ax,open_vfs_file_nr
    RegisterUserGate
;
    mov ebx,OFFSET read_vfs_file16
    mov esi,OFFSET read_vfs_file32
    mov edi,OFFSET read_vfs_file_name
    mov dx,virt_es_in
    mov ax,read_vfs_file_nr
    RegisterUserGate
    ret
init_client_file    Endp

code    ENDS

    END
