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

file_handle_seg     STRUC

fh_base       handle_header <>

fh_sel        DW ?
fh_handle     DW ?

file_handle_seg     ENDS

kernel_req_entry  STRUC

kre_pos           DD ?,?
kre_size          DD ?
kre_pages         DW ?
kre_wait          DW ?
kre_phys_arr      DD ?
kre_next          DD ?

kernel_req_entry  ENDS

kernel_file       STRUC

kf_memblk         mem_blk_header <>

kf_info_phys      DD ?,?
kf_sector_size    DW ?
kf_section        section_typ <>
kf_prog_list      DW ?
kf_part_sel       DW ?
kf_req_list       DD ?
kf_serv_handle    DD ?

kernel_file       ENDS

kernel_file_map   STRUC

kfm_flat_base     DD ?
kfm_user_base     DD ?
kfm_prog_sel      DW ?
kfm_file_sel      DW ?
kfm_kernel_sel    DW ?
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
;       NAME:           BlockToPhys
;
;       DESCRIPTION:    Convert block to phys
;
;       PARAMETERS:     ES                 Serv flat sel
;                       EDX:EAX            Sector
;
;       RETURNS:        EDX:EAX            Physical address
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BlockToPhys  Proc near
    push es
    push esi
;
    mov si,serv_flat_sel
    mov es,esi
;
    call BlockToBuf
    jc btpDone
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    stc
    jz btpDone
;
    and eax,7
    shl eax,9
    mov edx,es:[esi]
    and dx,0F000h
    or eax,edx
    movzx edx,word ptr es:[esi+4]
    clc

btpDone:
    pop esi
    pop es
    ret
BlockToPhys  Endp

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
;       PARAMETERS:     FS             Part sel
;                       EBX            VFS handle
;                       CX             Sector size
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
    mov ax,32
    mov cx,16
    mov si,SIZE kernel_file
    CreateMemBlk64
    pop ecx
;
    InitSection es:kf_section
    mov es:kf_sector_size,cx
    mov es:kf_prog_list,0
    mov es:kf_part_sel,fs
    mov es:kf_serv_handle,ebx
    mov es:kf_req_list,0
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
;       NAME:           FindReadReq
;
;       DESCRIPTION:    Find a read req. Section must be taken!
;
;       PARAMETERS:     DS             File sel
;                       EDX:EAX        Position
;
;       RETURNS:        EBX            Req ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindReadReq	Proc near
    push ds
    push esi
    push edi
;
    mov ebx,ds:kf_req_list
    mov si,flat_sel
    mov ds,esi
 
frrLoop:
    or ebx,ebx
    stc
    jz frrDone
;
    mov esi,ds:[ebx].kre_pos
    mov edi,ds:[ebx].kre_pos+4
    sub esi,eax
    sbb edi,edx
    jnz frrNext
;
    cmp esi,ds:[ebx].kre_size
    jae frrNext
;
    clc
    jmp frrDone

frrNext:
    mov ebx,ds:[ebx].kre_next
    jmp frrLoop

frrDone:
    pop edi
    pop esi
    pop ds
    ret
FindReadReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddReadReq
;
;       DESCRIPTION:    Add read req. Section must be taken!
;
;       PARAMETERS:     DS             File sel
;                       EDX:EAX        Position
;                       ECX            Size                        
;
;       RETURNS:        EBX            Req linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReadReq	Proc near
    push ds
    push es
    push esi
;
    mov bx,ds
    mov es,ebx
    mov bx,flat_sel
    mov ds,bx
;
    push eax
    push ecx
    push edx
;
    mov cx,SIZE kernel_req_entry
    AllocateMemBlk
    mov esi,edx
;
    pop edx
    pop ecx
    pop eax
;
    mov ds:[esi].kre_pos,eax
    mov ds:[esi].kre_pos+4,edx
    mov ds:[esi].kre_size,ecx
    mov ds:[esi].kre_pages,0
    mov ds:[esi].kre_wait,0
    mov ds:[esi].kre_phys_arr,0
;
    mov ebx,es:kf_req_list
    mov ds:[esi].kre_next,ebx
    mov es:kf_req_list,esi
;
    mov ebx,esi
;
    pop esi
    pop es
    pop ds
    ret
AddReadReq      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitReadReq
;
;       DESCRIPTION:    Wait read req. Section must be taken!
;
;       PARAMETERS:     DS             File sel
;                       EBX            Req linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitReadReq	Proc near
    push es
    push fs
    push eax
    push esi
;
    mov ax,flat_sel
    mov es,eax
    ClearSignal
;
    GetThread
    mov fs,eax
    mov ax,es:[ebx].kre_wait
    mov fs:p_link,ax
    mov es:[ebx].kre_wait,es
;
    LeaveSection ds:kf_section
    WaitForSignal
    EnterSection ds:kf_section
;
    pop esi
    pop eax
    pop fs
    pop es
    ret
WaitReadReq      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendReadReq
;
;       DESCRIPTION:    Send read req
;
;       PARAMETERS:     DS             File sel
;                       EDX:EAX        Position
;                       ECX            Size                        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendReadReq	Proc near
    push ds
    push es
    push fs
    push eax
    push ebx
;
    mov ebx,ds:kf_serv_handle
    dec ebx
    mov fs,ds:kf_part_sel
    mov ds,fs:vfsp_disc_sel
    call AllocateMsg
;
    mov eax,VFS_REQ_FILE
    call PostMsg
;
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
SendReadReq     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ProcessReadReq
;
;       DESCRIPTION:    Process read req
;
;       PARAMETERS:     DS                 File sel
;                       FS                 Part sel
;                       AX                 Pages needed
;                       EBX                Req linear
;                       ECX                Buffered blocks
;                       GS:ESI             Sector array
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessReadReq  Proc near
    push ds
    push es
    pushad
;
    push ecx
    push ebx
;
    mov cx,ds
    mov es,cx
    mov cx,ax
    shl cx,3
    AllocateMemBlk
    mov edi,edx
;
    pop ebx
    pop ecx
;
    mov ax,flat_sel
    mov es,eax
    mov es:[ebx].kre_phys_arr,edi
;
    mov eax,ecx
    shl eax,9
    mov es:[ebx].kre_size,eax
;
    mov ds,fs:vfsp_disc_sel
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jc prrDone
;
    mov es:[edi],eax
    mov es:[edi+4],edx
    add edi,8

prrLoop:
    sub ecx,1
    jz prrDone
;
    add esi,8
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jc prrDone
;
    test eax,0FFFh
    jnz prrLoop
;
    mov es:[edi],eax
    mov es:[edi+4],edx
    add edi,8
    jmp prrLoop

prrDone:
    popad
    pop es
    pop ds
    ret
ProcessReadReq  Endp

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
    push ebp
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
    mov eax,1000h
    AllocateBigLinear
    mov ebp,edx
;
    mov eax,3000h
    AllocateLocalLinear
;
    sub edx,ebx
    mov edi,edx
    xor eax,eax
    mov ecx,800h
    rep stosd
;
    mov eax,edx
    add eax,1000h
    mov es:[edx].fm_handle_ptr,eax
    add eax,1000h
    mov es:[edx].fm_info_ptr,eax
;
    push ebx
    push edx
;
    add edx,ebx
    add edx,2000h
    mov eax,ds:kf_info_phys
    mov ebx,ds:kf_info_phys+4
    or ax,865h
    SetPageEntry
;
    sub edx,2000h
    GetPageEntry
    and ax,0F000h
    or ax,865h
    SetPageEntry
;
    mov edx,ebp
    and ax,0F000h
    or ax,67h
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
    mov es:kfm_user_base,edx
    mov es:kfm_prog_sel,si
    mov es:kfm_file_sel,ds
;
    AllocateGdt
    mov ecx,1000h
    mov edx,ebp
    CreateDataSelector32
    mov es:kfm_kernel_sel,bx
;
    EnterSection ds:kf_section
    mov bx,ds:kf_prog_list
    mov es:kfm_next_map,bx
    mov ds:kf_prog_list,es
    LeaveSection ds:kf_section
    mov ax,es
;
    pop ebp
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
;       NAME:           AllocateUserHandle
;
;       DESCRIPTION:    Allocate user handle
;
;       PARAMETERS:     DS		Prog sel
;
;       RETURNS:        NC
;                         BX            User handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateUserHandle	Proc near
    push es
    push eax
    push ecx
    push edx
    push esi
;
    mov bx,flat_data_sel
    mov es,ebx
    mov edx,ds:kfm_user_base
    mov edx,es:[edx].fm_handle_ptr
    add edx,OFFSET fh_bitmap
    mov ecx,15
    xor esi,esi

auhLoop:
    mov eax,es:[edx]
    cmp eax,-1
    je auhNext
;
    not eax
    bsf ebx,eax
;
    lock bts es:[edx],ebx
    jc auhLoop
;
    add ebx,esi
;
    mov esi,ebx
    mov edx,ds:kfm_user_base
    mov edx,es:[edx].fm_handle_ptr
    shl esi,3
    add edx,esi
    xor eax,eax
    mov es:[edx],eax
    add edx,4
    mov es:[edx],eax
;
    inc ebx
    clc
    jmp auhDone

auhNext:
    add esi,32
    add edx,4
    loop auhLoop
;
    stc

auhDone:
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
AllocateUserHandle      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetPos
;
;       DESCRIPTION:    Get file position
;
;       PARAMETERS:     DS             Prog sel
;                       BX             Map Handle
;
;       RETURNS:        NC
;                         EDX:EAX      Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPos  Proc near
    push es
;
    mov ax,flat_data_sel
    mov es,eax
;
    or bx,bx
    jz gpFail
;
    cmp bx,15*32
    jb gpConv

gpFail:
    stc
    jmp gpDone

gpConv:
    movzx eax,bx
    dec eax
    shl eax,3
    mov edx,ds:kfm_user_base
    mov edx,es:[edx].fm_handle_ptr
    add edx,eax
    mov eax,es:[edx]
    mov edx,es:[edx+4]
    clc

gpDone:
    pop es
    ret
GetPos  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetPos
;
;       DESCRIPTION:    Get file position
;
;       PARAMETERS:     DS             Prog sel
;                       BX             Map Handle
;                       EDX:EAX        Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPos  Proc near
    push es
    push ecx
    push esi
;
    mov cx,flat_data_sel
    mov es,ecx
;
    or bx,bx
    jz spFail
;
    cmp bx,15*32
    jb spSave

spFail:
    stc
    jmp spDone

spSave:
    movzx ecx,bx
    dec ecx
    shl ecx,3
    mov esi,ds:kfm_user_base
    mov esi,es:[esi].fm_handle_ptr
    add esi,ecx
    mov es:[esi],eax
    mov es:[esi+4],edx
    clc

spDone:
    pop esi
    pop ecx
    pop es
    ret
SetPos  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CalcPageCount
;
;       DESCRIPTION:    Calculate page count
;
;       PARAMETERS:     FS                 Part sel
;                       ECX                Buffered blocks
;                       GS:ESI             Sector array
;
;       RETURNS:        AX                 Page count
;                       ECX                Used blocks
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcPageCount  Proc near
    push ds
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    push ecx
;
    xor ebx,ebx
    or ecx,ecx
    clc
    jz cpcDone
;
    inc ebx
;
    mov ds,fs:vfsp_disc_sel
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jc cpcDone
;
    mov edi,eax
    mov ebp,edx

cpcLoop:
    sub ecx,1
    jz cpcDone
;
    add esi,8
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jc cpcDone
;
    test eax,0FFFh
    jz cpcFirst

cpcMid:
    add edi,200h
    cmp edi,eax
    jne cpcNext
;
    cmp ebp,edx
    je cpcLoop
    jmp cpcNext

cpcFirst:
    mov ebp,edx
    mov dx,di
    and dx,0FFFh
    cmp dx,0E00h
    jne cpcDone
;
    mov edi,eax
    inc ebx
    cmp ebx,1FFFh
    je cpcDone

cpcNext:
    jmp cpcLoop

cpcDone:
    mov eax,ecx
    pop ecx
    sub ecx,eax
    mov eax,ebx
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
CalcPageCount  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockSectors
;
;       DESCRIPTION:    Unlock non-used sectors
;
;       PARAMETERS:     FS                 Part sel
;                       ECX                Used blocks
;                       GS                 File req
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockSectors  Proc near
    push ds
    push es
    pushad
;
    mov ax,serv_flat_sel
    mov es,eax
;
    mov eax,gs:vfs_rd_sectors
    sub eax,ecx
    jz usDone
;
    shl ecx,3   
    mov ebx,gs:vfs_rd_chain_ptr
    add ebx,ecx
    mov ecx,eax
;
    mov ds,fs:vfsp_disc_sel

usLoop:
    mov eax,gs:[ebx] 
    mov edx,gs:[ebx+4] 
    call BlockToBuf
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz usNext
;
    sub es:[esi].vfsp_ref_bitmap,1
    jnz usNext
;
    dec ds:vfs_locked_pages

usNext:
    add ebx,8
;
    loop usLoop

usDone:
    popad
    pop es
    pop ds
    ret
UnlockSectors  Endp

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
    push ds
    push es
    push fs
    pushad
;
    mov ebx,gs:vfs_rd_file_handle
    mov al,VFS_FILE_SIGN
    call HandleHighToPartFs
    jc nfdDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc nfdDone
;
    movzx ebx,bx
    dec ebx
    shl ebx,2
    mov bx,fs:[ebx].vfsp_file_arr.ff_sel
    or bx,bx
    stc
    je nfdDone
;
    mov ecx,gs:vfs_rd_sectors
    or ecx,ecx
    jz nfdDone
;
    mov ds,ebx
    EnterSection ds:kf_section
    mov eax,gs:vfs_rd_start
    mov edx,gs:vfs_rd_start+4
    call FindReadReq
    jnc nfdProc
;
    xor ecx,ecx
    jmp nfdUnlock

nfdProc:
    mov esi,gs:vfs_rd_chain_ptr
    call CalcPageCount
    call ProcessReadReq

nfdUnlock:
    call UnlockSectors
    int 3
;
    LeaveSection ds:kf_section
    clc

nfdDone:
    popad
    pop fs
    pop es
    pop ds
    ret
NotifyFileData  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           open_vfs_file
;
;       DESCRIPTION:    Open VFS file
;
;       PARAMETERS:     ES:(E)DI       Pathname
;
;       RETURNS:        NC
;                         BX           Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    mov ds,eax
    call GetProgSel
    jnc ovfHasProc
;
    call CreateProgSel

ovfHasProc:
    mov ds,eax
    call AllocateUserHandle
    jc ovfFail
;
    mov ax,bx
    mov dx,ds
    mov cx,SIZE file_handle_seg
    AllocateHandle
    mov [ebx].fh_sel,dx
    mov [ebx].fh_handle,ax
    mov [ebx].hh_sign,VFS_FILE_HANDLE
    movzx ebx,[ebx].hh_handle
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
;       NAME:           read_vfs_file
;
;       DESCRIPTION:    Read VFS file
;
;       PARAMETERS:     DS             Prog sel
;                       BX             Map Handle
;                       ES:EDI         Buffer
;                       ECX            Size
;
;       RETURNS:        NC
;                         EAX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_vfs_file  Proc near
    push edx
;    
    call GetPos
;
    mov ds,ds:kfm_file_sel
    EnterSection ds:kf_section
    call FindReadReq
    jnc rvfCheck
;
    call AddReadReq
    call SendReadReq

rvfCheck:
    call WaitReadReq
    int 3
    LeaveSection ds:kf_section
;
    pop edx
    ret
read_vfs_file  Endp

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
    push ds
    push ebx
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jc rfOrg16
;
    mov ax,ds:[ebx].fh_sel
    mov bx,ds:[ebx].fh_handle
    mov ds,eax
    call read_vfs_file
    jmp rfDone16

rfOrg16:
    call fword ptr cs:org_read

rfDone16:
    pop edi
    pop ecx
    pop ebx
    pop ds
    ret
read_file16  Endp

read_file32  Proc far
    push ds
    push ebx
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jc rfOrg32
;
    mov ax,ds:[ebx].fh_sel
    mov bx,ds:[ebx].fh_handle
    mov ds,eax
    call read_vfs_file
    jmp rfDone32

rfOrg32:
    call fword ptr cs:org_read

rfDone32:
    pop ebx
    pop ds
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
