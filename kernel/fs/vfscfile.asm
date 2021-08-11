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

MAX_FILE_REQ_ENTRIES = 8
MAX_FILE_REQ_COUNT   = 64
MAX_FILE_USERS       = 256
MAX_FILE_WAITS       = 16

file_handle_seg  STRUC

fh_base          handle_header <>

fh_pos           DD ?,?
fh_attrib        DD ?
fh_file_handle   DD ?
fh_part_sel      DW ?
fh_file_sel      DW ?

file_handle_seg  ENDS

file_req_header    STRUC

frh_req_handle     DD ?
frh_entry_size     DW ?
frh_entries        DW ?
frh_req_ptr        DW ?
frh_pad            DW ?

file_req_header    ENDS

file_req_entry    STRUC

fre_pos            DD ?,?
fre_size           DD ?
fre_last_size      DW ?
fre_pages          DW ?
fre_arr            DD ?,?

file_req_entry    ENDS

file_req_link  STRUC

frl_pos            DD ?,?
frl_size           DD ?
frl_ptr            DD ?
frl_link           DW ?
frl_wait_list      DW ?

file_req_link  ENDS

file_wait  STRUC

fw_thread          DW ?
fw_link            DW ?

file_wait  ENDS

file_struc    STRUC

fse_info          DB 1000h DUP(?)  ; aliased file info

fse_insert        DD ?
fse_sector_size   DW ?
fse_req_count     DW ?
fse_req_list      DW ?
fse_wait_list     DW ?
fse_section       section_typ <>
fse_pad           DW ?

fse_wait_arr      DD MAX_FILE_WAITS DUP(?)
fse_user_arr      DD MAX_FILE_USERS DUP(?)
fse_req_arr       DD MAX_FILE_REQ_COUNT DUP(?,?,?,?,?)
fse_sorted_arr    DD MAX_FILE_REQ_COUNT DUP(?)

file_struc    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

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
    mov es:fse_insert,SIZE file_struc
    InitSection es:fse_section
;
    mov edi,OFFSET fse_user_arr
    xor eax,eax
    mov ecx,MAX_FILE_USERS
    rep stosd
;
    mov ecx,MAX_FILE_WAITS - 1
    mov edi,OFFSET fse_wait_arr
    mov es:fse_wait_list,di
    mov eax,edi

cfsWaitLoop:
    add eax,4
    mov es:[edi].fw_link,ax
    mov es:[edi].fw_thread,0
    mov edi,eax
    loop cfsWaitLoop
;
    mov es:[edi].fw_link,cx
;
    mov ecx,MAX_FILE_REQ_COUNT - 1
    mov edi,OFFSET fse_req_arr
    mov es:fse_req_list,di
    mov eax,edi

cfsReqLoop:
    add eax,20
    mov es:[edi].frl_link,ax
    mov es:[edi].frl_wait_list,0
    mov es:[edi].frl_ptr,0
    mov es:[edi].frl_pos,0
    mov es:[edi].frl_pos+4,0
    mov edi,eax
    loop cfsReqLoop
;
    mov es:[edi].frl_link,cx
;
    mov edi,OFFSET fse_sorted_arr
    xor eax,eax
    mov ecx,MAX_FILE_REQ_COUNT
    rep stosd
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
;       NAME:           FindReq
;
;       DESCRIPTION:    Find a file req
;
;       PARAMETERS:     FS             Part sel
;                       DS             File sel
;                       EDX:EAX        Position
;
;       RETURNS:        EBX            Req ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindReq	Proc near
    push esi
    push edi
;
    EnterSection ds:fse_section
;
    mov ebx,OFFSET fse_sorted_arr
    mov esi,MAX_FILE_REQ_COUNT / 2

frLoop:
    mov edi,ds:[ebx+4*esi]
    or edi,edi
    jz frNext
;
    cmp edx,ds:[edi].frl_pos+4
    jb frNext
    jz frUp
;
    cmp eax,ds:[edi].frl_pos
    jb frNext

frUp:
    lea ebx,[ebx+4*esi]

frNext:
    shr esi,1
    jnz frLoop
;
    mov ebx,ds:[ebx]
    or ebx,ebx
    jz frFail
;
    push eax
    push edx
;
    sub eax,ds:[ebx].frl_pos
    sbb edx,ds:[ebx].frl_pos+4
    mov esi,eax
;
    pop edx
    pop eax
    jnz frFail
;
    cmp esi,ds:[ebx].frl_size
    ja frFail
;
    clc
    jmp frLeave

frFail:
    stc

frLeave:
    LeaveSection ds:fse_section
;
    pop edi
    pop esi
    ret
FindReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InsertReq
;
;       DESCRIPTION:    Insert a file req
;
;       PARAMETERS:     FS             Part sel
;                       DS             File sel
;                       EBX            Req ptr
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertReq	Proc near
    push ecx
    push esi
    push edi
;
    EnterSection ds:fse_section
;
    mov esi,OFFSET fse_sorted_arr
    mov edi,MAX_FILE_REQ_COUNT / 2

irLoop:
    mov ecx,ds:[esi+4*edi]
    or ecx,ecx
    jz irNext
;
    cmp edx,ds:[ecx].frl_pos+4
    jb irNext
    jz irUp
;
    cmp eax,ds:[ecx].frl_pos
    jb irNext

irUp:
    lea esi,[esi+4*edi]

irNext:
    shr edi,1
    jnz irLoop
;
    push esi
;
    sub esi,OFFSET fse_sorted_arr
    shr esi,2
    mov ecx,MAX_FILE_REQ_COUNT
    sub ecx,esi
    or ecx,ecx
    jz irSave
;
    sub ecx,1
    jz irSave
;
    mov esi,OFFSET fse_sorted_arr + 4 * MAX_FILE_REQ_COUNT - 4

irMove:
    mov edi,ds:[esi-4]
    mov ds:[esi],edi
    sub esi,4
    loop irMove

irSave:
    pop esi
    mov ds:[esi],ebx
;
    LeaveSection ds:fse_section
;
    pop edi
    pop esi
    pop ecx
    ret
InsertReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddReq
;
;       DESCRIPTION:    Add a file req
;
;       PARAMETERS:     FS             Part sel
;                       DS             File sel
;                       EDX:EAX        Position
;                       ECX            Size
;
;       RETURNS:        EBX            Req ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReq	Proc near
    push ds
    push es
    push eax
    push esi
    push edi
;
    EnterSection ds:fse_section
;
    movzx ebx,ds:fse_req_list
    or ebx,ebx
    jnz arDo
;
    int 3

arDo:
    mov di,ds:[ebx].frl_link
    mov ds:fse_req_list,di
    mov ds:[ebx].frl_link,0
;
    mov ds:[ebx].frl_pos,eax
    mov ds:[ebx].frl_pos+4,edx
    mov ds:[ebx].frl_size,ecx
    mov ds:[ebx].frl_ptr,0
    mov ds:[ebx].frl_wait_list,0
    LeaveSection ds:fse_section
;
    call InsertReq
    call FindReq
;
    push ebx
;
    mov esi,ebx
    sub esi,OFFSET fse_req_arr
    shr esi,4
    inc esi
;
    mov ebx,ds:fi_serv_handle
    mov ds,fs:vfsp_disc_sel
    call AllocateMsg
;
    mov eax,VFS_REQ_FILE
    call PostMsg
;
    pop ebx
;
    pop edi
    pop esi
    pop eax
    pop es
    pop ds
    ret
AddReq  Endp

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
    movzx ebx,ds:fse_sector_size
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
;                       ECX         Number of sectors to discard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleFileData

HandleFileData	Proc near
    push ds
    push fs
    push eax
    push ebx
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
    jc hfdFail
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc hfdFail
;
    movzx ecx,bx
    dec ecx
    shl ecx,2
    mov cx,fs:[ecx].vfsp_file_arr.ff_sel
    or cx,cx
    stc
    je hfdFail
;
    mov ds,ecx
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
    jne hfdFail
;
    mov ecx,es:[edi]
    add edi,4
;
    or ecx,ecx
    clc
    jz hfdDone
;
    EnterSection ds:fse_section
    mov esi,ds:fse_insert
    mov ebp,esi
;    mov ds:[ebp].frh_pos,eax
;    mov ds:[ebp].frh_pos+4,edx
    mov ds:[ebp].frh_req_handle,ebx
    mov ds:[ebp].frh_entries,0
    add esi,SIZE file_req_header

hfdLoop:
    mov ebx,esi
    call AddOneEntry
    or ecx,ecx
    jz hfdCheckLast
;
    mov bx,ds:[ebp].frh_entries
    inc bx
    mov ds:[ebp].frh_entries,bx
    cmp bx,MAX_FILE_REQ_ENTRIES
    je hfdSave
;
    jmp hfdLoop

hfdCheckLast:
    cmp ds:[ebx].fre_last_size,0
    jz hfdSave
;
    cmp ds:[ebx].fre_pages,2
    jbe hfdSave
;
    push eax
    push edx
;
    xor dx,dx
    mov ax,ds:[ebx].fre_last_size
    div ds:fse_sector_size
    movzx ecx,ax
;
    pop edx
    pop eax
;
    push esi
;
    movzx esi,ds:[ebx].fre_last_size
    sub ds:[ebx].fre_size,esi
    sub eax,esi
    sbb edx,0
;
    pop esi
;
    mov ds:[ebx].fre_last_size,0
    dec ds:[ebx].fre_pages
    sub esi,8

hfdSave:
;    sub eax,ds:[ebp].frh_pos
;    mov ds:[ebp].frh_size,eax
;
    mov ds:fse_insert,esi
    sub esi,ebp
    mov ds:[ebp].frh_entry_size,si
;
    LeaveSection ds:fse_section
    clc
    jmp hfdDone

hfdFail:
    xor ecx,ecx
    stc

hfdDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
HandleFileData  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyFileData
;
;       DESCRIPTION:    Notify file data
;
;       PARAMETERS:     FS                 Partition
;                       GS                 File req
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NotifyFileData

NotifyFileData	Proc near
    push ds
    push es
    push gs
    push ebx
    push ecx
    push edi
    push ebp
;
    mov ebx,gs:vfs_rd_file_handle
    mov al,FILE_SIGN
    call HandleHighToPartFs
    pop eax
    jc nfdFail
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc nfdFail
;
    movzx ecx,bx
    dec ecx
    shl ecx,2
    mov cx,fs:[ecx].vfsp_file_arr.ff_sel
    or cx,cx
    stc
    je nfdFail
;
    mov ds,ecx



    mov ds:[edi],eax
    add edi,4
;
    mov eax,gs:vfs_rd_req_handle
    mov ds:[edi],eax
    add edi,4
;
    mov eax,gs:vfs_rd_sectors
    mov ds:[edi],eax
    add edi,4
;
    mov eax,ds
    mov gs,eax
    mov ebp,edi
;
    mov ds,es:vfsp_disc_sel
    mov eax,serv_flat_sel
    mov es,eax
;
    mov edi,fs:vfs_rd_chain_ptr
    mov ecx,fs:vfs_rd_sectors
    or ecx,ecx
    jz nfdOk

nfdLoop:
    mov eax,fs:[edi]
    mov edx,fs:[edi+4]
    call BlockToBuf
    jc nfdFail
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz nfdFail
;
    and eax,7
    shl eax,9
    mov ebx,es:[esi]
    and bx,0F000h
    or eax,ebx
    movzx ebx,word ptr es:[esi+4]
;
    mov gs:[ebp],eax
    mov gs:[ebp+4],ebx
;
    add edi,8
    add ebp,8
    loop nfdLoop

nfdOk:
    mov eax,fs:vfs_rd_start
    mov edx,fs:vfs_rd_start+4
    movzx esi,ds:vfs_bytes_per_sector
    clc
    jmp nfdDone
    
nfdFail:
    xor ecx,ecx
    stc

nfdDone:
    pop ebp
    pop edi
    pop ecx
    pop ebx
    pop gs
    pop es
    pop ds
    ret
NotifyFileData     Endp

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
;       NAME:           WaitForReq
;
;       DESCRIPTION:    Wait for a file req
;
;       PARAMETERS:     FS             Part sel
;                       DS             File sel
;                       EBX            Req ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForReq	Proc near
    push eax
    push esi

wfrRetry:
    EnterSection ds:fse_section
;
    mov eax,ds:[ebx].frl_ptr
    or eax,eax
    jnz wfrLeave
;
    movzx esi,ds:fse_wait_list
    or esi,esi
    jnz wfrDo
;
    LeaveSection ds:fse_section
    mov ax,10
    WaitMilliSec
    jmp wfrRetry

wfrDo:
    mov ax,ds:[esi].fw_link
    mov ds:fse_wait_list,ax
;
    mov ax,ds:[ebx].frl_wait_list
    mov ds:[esi].fw_link,ax
    mov ds:[ebx].frl_wait_list,si
;
    GetThread
    mov ds:[esi].fw_thread,ax
    LeaveSection ds:fse_section

wfrWait:
    WaitForSignal
;
    mov eax,ds:[ebx].frl_ptr
    or eax,eax
    jz wfrWait

wfrLeave:
    LeaveSection ds:fse_section
;
    pop esi
    pop eax
    ret
WaitForReq      Endp

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
    push ds
    push eax
    push edx
;
    mov eax,ds:[ebx].fh_pos
    mov edx,ds:[ebx].fh_pos+4
    mov fs,ds:[ebx].fh_part_sel
    mov ds,ds:[ebx].fh_file_sel    
;
    call FindReq
    jnc rvfDo
;
    call AddReq

rvfDo:
    call WaitForReq

rvfDone:
    pop edx
    pop eax
    pop ds
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
