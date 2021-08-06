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

file_handle_seg  STRUC

fh_base          handle_header <>

fh_pos           DD ?,?
fh_attrib        DD ?
fh_file_handle   DD ?
fh_part_sel      DW ?
fh_file_sel      DW ?

file_handle_seg  ENDS

file_req_entry    STRUC

fre_pos            DD ?,?
fre_size           DD ?
fre_last_size      DW ?
fre_pages          DW ?
fre_arr            DD ?,?

file_req_entry    ENDS

file_entry    STRUC

fse_info          DB 1000h DUP(?)  ; aliased file info

fse_sector_size   DW ?
fse_req_count     DW ?
fse_insert        DW ?
fse_pend_list     DW ?
fse_section       section_typ <>
fse_pad           DW ?

fse_user_arr      DD MAX_FILE_USERS DUP(?)
fse_req_arr       DW MAX_FILE_REQ_COUNT DUP(?,?)
fse_sorted_arr    DW MAX_FILE_REQ_COUNT DUP(?)

file_entry    ENDS

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

CreateFileSel    Proc near
    push es
    push ebx
    push ecx
    push edx
    push edi
;
    GetPageEntry
    push eax
    push ebx
;
    or ax,800h
    SetPageEntry
;
    push ecx
    mov eax,10000h
    AllocateBigLinear
    AllocateGdt
    mov ecx,10000h
    CreateDataSelector32
    pop ecx
;
    mov es,ebx
;
    pop ebx
    pop eax
    and ax,0F000h
    or ax,63h
    SetPageEntry
;
    mov es:fse_sector_size,cx
    mov es:fse_req_count,0
    mov es:fse_pend_list,0
    mov es:fse_insert,SIZE file_entry
    InitSection es:fse_section
;
    mov edi,OFFSET fse_user_arr
    xor ax,ax
    mov ecx,MAX_FILE_USERS
    rep stosw
;
    mov edi,OFFSET fse_req_arr
    xor ax,ax
    mov ecx,MAX_FILE_REQ_COUNT
    rep stosw
;
    mov edi,OFFSET fse_sorted_arr
    xor ax,ax
    mov ecx,MAX_FILE_REQ_COUNT
    rep stosw
;
    mov eax,es
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CreateFileSel   Endp

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
    mov esi,ebx
    push ecx
    mov cx,SIZE file_handle_seg
    AllocateHandle
    pop ecx
;
    push ebx
    mov ebx,esi
    mov al,FILE_SIGN
    call HandleHighToPartFs
    pop ebx
    jc ovfFail
;
    cmp si,MAX_VFS_FILE_COUNT    
    cmc
    jc ovfFail
;
    movzx eax,si
    dec eax
    shl eax,2
    mov ax,fs:[eax].vfsp_file_arr.ff_sel
    or ax,ax
    je ovfFail
;
    mov [ebx].fh_part_sel,fs
    mov [ebx].fh_file_handle,esi
    mov [ebx].fh_file_sel,ax
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
;       PARAMETERS:     FS             Part sel
;                       DS             File sel
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFileReq   Proc near
    push ds
    push eax
    push ebx
    push edx
;
    mov ebx,ds:fi_serv_handle
    mov ds,fs:vfsp_disc_sel
    call AllocateMsg
;
    mov eax,VFS_REQ_FILE
    call RunMsg
;
    pop edx
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
    push ebx
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jc rvfDone
;
    push eax
    push edx
;
    mov eax,ds:[ebx].fh_pos
    mov edx,ds:[ebx].fh_pos+4
    mov fs,ds:[ebx].fh_part_sel
    mov ds,ds:[ebx].fh_file_sel    

rvfTry:
    call TryRead
    jc rvfReq
;
    int 3

rvfReq:
    call AddFileReq
    jnc rvfTry

rvfDone:
    pop edx
    pop eax
;
    mov ds:[ebx].fh_pos,eax
    mov ds:[ebx].fh_pos+4,edx
;
    pop ebx
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
;
;       RETURNS:        EBP         Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleFileData

HandleFileData	Proc near
    push ds
    push fs
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    mov ebx,es:[edi]
    add edi,4
;
    push eax
    mov al,FILE_SIGN
    call HandleHighToPartFs
    pop eax
    jc hfdDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc hfdDone
;
    movzx eax,bx
    dec eax
    shl eax,2
    mov ax,fs:[eax].vfsp_file_arr.ff_sel
    or ax,ax
    stc
    je hfdDone
;
    mov ds,eax
    mov ecx,ebx
    shr ecx,24
    mov ebx,es:[edi]
    add edi,4
;
    push ebx
    shr ebx,16
    mov ch,bh
    cmp bl,REQ_SIGN
    pop ebx
    stc
    jne hfdDone
;
    cmp cl,ch
    stc
    jne hfdDone
;
    mov ecx,es:[edi]
    add edi,4
;
    or ecx,ecx
    clc
    jz hfdDone
;
    EnterSection ds:fse_section
    LeaveSection ds:fse_section

hfdDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop fs
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
