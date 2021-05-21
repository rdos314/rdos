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

file_handle_seg  STRUC

fh_base          handle_header <>

fh_pos           DD ?,?
fh_attrib        DD ?
fh_vfs_sel       DW ?
fh_vfs_handle    DW ?

file_handle_seg  ENDS

; must be 16 bytes!

file_req_struc   STRUC

fr_pos           DD ?,?
fr_size          DD ?
fr_handle        DD ?

file_req_struc   ENDS

; must be dword aligned!

file_info_struc  STRUC

fi_header            share_block_struc <>
fi_fs_size           DD ?,?
fi_req_size          DD ?,?
fi_access            DD ?,?
fi_modify            DD ?,?
fi_attrib            DD ?
fi_flags             DD ?
fi_uid               DD ?
fi_gid               DD ?
fi_kernel_handle     DD ?
fi_serv_handle       DD ?
fi_disc              DB ?
fi_drive             DB ?
fi_part              DB ?
fi_pad               DB ?
fi_req_max_size      DD ?
fi_req_count         DD ?

file_info_struc  ENDS

; must be word aligned!

file_sel         STRUC

fs_header        share_block_struc <>
fs_section       section_typ <>

fs_handle_count  DD ?
fs_max_size      DD ?

fs_handle_arr    DW ?

file_sel         ENDS


handle_req_struc STRUC

hr_sector_count  DD ?
hr_sector_arr    DD ?
hr_file_handle   DD ?
hr_wait_sel      DW ?
hr_data_sel      DW ?
hr_pend_sel      DW ?
hr_ref_count     DW ?
hr_used          DB ?
hr_pad           DB ?

handle_req_struc   ENDS


req_sel          STRUC

rs_header        share_block_struc <>

rs_handle_count  DD ?
rs_max_size      DD ?

req_sel          ENDS


req_msb_struc  STRUC

rqm_ptr        DD ?
rqm_count      DD ?

req_msb_struc  ENDS

req_sel_struc  STRUC

rqs_sectors    DD ?
rqs_start_msb  DD ?
rqs_msb_count  DD ?

rqs_chain_ptr  DD ?
rqs_sorted_ptr DD ?
rqs_index_ptr  DD ?
rqs_msb_ptr    DD ?

req_sel_struc  ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern AllocateMsg:near
    extern AddMsgBuffer:near
    extern RunMsg:near
    extern GetDrivePart:near
    extern GetPathDrive:near
    extern GetRelDir:near
    extern HandleToPart:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServOpenFile
;
;       DESCRIPTION:    Serv open VFS file req
;
;       PARAMETERS:     EBX            VFS handle
;                       EDX            Share block
;
;       RETURNS:        EBX            Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_open_file_name       DB 'Serv Open File',0

serv_open_file    Proc far
    push ds
    push es
    push eax
    push ecx
    push edi
;
    call HandleToPart
    mov bx,flat_sel
    mov ds,bx
;
    mov al,es:vfsp_disc_nr
    mov ds:[edx].fi_disc,al
;
    mov al,es:vfsp_drive_nr
    mov ds:[edx].fi_drive,al
;
    mov al,es:vfsp_part_nr
    mov ds:[edx].fi_part,al
;
    ServToSystemShareBlock
;
    mov bx,vfs_file_sel
    mov ds,bx
    EnterSection ds:fs_section
;
    mov ecx,ds:fs_max_size
    cmp ecx,ds:fs_handle_count
    jne sofScan
;
    mov ebx,ecx
    inc ecx
    mov ds:fs_max_size,ecx
;
    mov edi,ebx
    add edi,edi
    add edi,OFFSET fs_handle_arr
    test di,0FFFh
    jnz sofDone
;
    push es
    mov ax,ds
    mov es,ax
    GrowShareBlock
    pop es
    jmp sofDone

sofScan:
    int 3
    xor ebx,ebx
    mov edi,OFFSET fs_handle_arr

sofLoop:
    mov ax,ds:[edi]
    or ax,ax
    jz sofDone
;
    inc ebx
    add edi,2
    loop sofLoop
;
    CrashGate

sofDone:
    inc ds:fs_handle_count
    mov ds:[edi],es
    LeaveSection ds:fs_section
;
    inc ebx
;
    pop edi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
serv_open_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateReq
;
;       DESCRIPTION:    Allocate req
;
;       PARAMETERS:     ECX            Sector count
;                       EDI            Sector buf
;                       ES             File sel
;
;       RETURNS:        EBX            Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateReq  Proc near
    push ds
    push eax
    push edx
    push esi
;
    mov ax,vfs_req_sel
    mov ds,ax
;
    push ecx
;
    mov ecx,ds:rs_max_size
    cmp ecx,ds:rs_handle_count
    jne arScan
;
    mov ebx,ecx
    inc ecx
    mov ds:rs_max_size,ecx
;
    mov eax,SIZE handle_req_struc
    mul ebx
    mov esi,eax
    add esi,SIZE req_sel
    mov eax,esi
    add eax,SIZE handle_req_struc
    movzx edx,ds:sb_pages
    shl edx,12
    cmp eax,edx
    jbe arFound
;
    push es
    mov ax,ds
    mov es,ax
    GrowShareBlock
    pop es
    jmp arFound

arScan:
    int 3
    xor ebx,ebx
    mov esi,SIZE req_sel

arLoop:
    mov al,ds:[esi].hr_used
    or al,al
    jz arFound
;
    inc ebx
    add esi,SIZE handle_req_struc
    loop arLoop
;
    CrashGate

arFound:
    pop ecx
;
    inc ds:rs_handle_count
    mov ds:[esi].hr_sector_count,ecx
    mov ds:[esi].hr_sector_arr,edi
;
    mov eax,es:fi_kernel_handle
    mov ds:[esi].hr_file_handle,eax
;
    mov ds:[esi].hr_wait_sel,0
    mov ds:[esi].hr_data_sel,0
    mov ds:[esi].hr_pend_sel,0
    mov ds:[esi].hr_ref_count,0
    mov ds:[esi].hr_used,1
;
    inc ebx
;
    pop esi
    pop edx
    pop eax
    pop ds
    ret
AllocateReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServAddFileReq
;
;       DESCRIPTION:    Serv add VFS file req
;
;       PARAMETERS:     EBX            File handle
;                       EDX:EAX        File pos
;                       ECX            Sector count
;                       ESI            Sector size
;                       ES:EDI         Sector buf
;
;       RETURNS:        EAX            Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_add_file_req_name       DB 'Serv Add File Req',0

serv_add_file_req    Proc far
    push ds
    push es
    push ebx
    push esi
;
    or ebx,ebx
    stc
    jz safDone
;
    dec ebx
    shl ebx,1
;
    push eax
    mov eax,vfs_file_sel
    mov ds,eax
    pop eax
;
    EnterSection ds:fs_section
    mov bx,ds:[ebx].fs_handle_arr
    or bx,bx
    stc
    jz safLeave
;
    mov es,bx
    call AllocateReq
;
    push edi
;
    push eax
    push ebx
    push ecx
;
    mov ecx,es:fi_req_max_size
    cmp ecx,es:fi_req_count
    jne safScan
;
    mov ebx,ecx
    inc ecx
    mov es:fi_req_max_size,ecx
;
    mov edi,ebx
    shl edi,4
    add edi,SIZE file_info_struc
    test di,0FFFh
    jnz safFound
;
    GrowShareBlock
    jmp safFound

safScan:
    int 3
    xor ebx,ebx
    mov edi,SIZE file_info_struc

safLoop:
    mov eax,es:[edi]
    or eax,eax
    jz safFound
;
    inc ebx
    add edi,4
    loop safLoop
;
    CrashGate

safFound:
    pop ecx
    pop ebx
    pop eax
;
    inc es:fi_req_count
    mov es:[edi].fr_handle,ebx
    mov es:[edi].fr_pos,eax
    mov es:[edi].fr_pos+4,edx
;
    push eax
    push edx
;
    mov eax,esi
    mul ecx
    mov es:[edi].fr_size,eax
;
    pop edx
    pop eax
;
    pop edi

safLeave:
    LeaveSection ds:fs_section

safDone:
    mov eax,ebx
;
    pop esi
    pop ebx
    pop es
    pop ds
    ret
serv_add_file_req    Endp

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
    mov [ebx].fh_vfs_handle,ax
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
    push ds
    push eax
    push ebx
;
    movzx ebx,ds:[ebx].fh_vfs_handle
    or ebx,ebx
    stc
    jz gfbDone
;
    dec ebx
    add ebx,ebx
;
    mov ax,vfs_file_sel
    mov ds,eax
    EnterSection ds:fs_section
    add ebx,OFFSET fs_handle_arr
    mov ax,ds:[ebx]
    LeaveSection ds:fs_section
;
    or ax,ax
    stc
    jz gfbDone
;
    mov gs,ax
    clc

gfbDone:
    pop ebx
    pop eax
    pop ds
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
    mov ecx,gs:fi_req_count
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
;       NAME:           GetRandomRange
;
;       DESCRIPTION:    Get random number range
;
;       PARAMETERS:     EAX          Range
;
;       RETURNS:        EAX          Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRandomRange  Proc near
    push edx
    mov edx,eax
    GetRandom
    mul edx
    mov eax,edx
    pop edx
    ret
GetRandomRange Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateRandomSectors
;
;       DESCRIPTION:    Create random sectors
;
;       RETURNS:        ECX             Size
;                       EDX             Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRandomSectors Proc near
    push eax
    push esi
    push edi
    push ebp
;
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    mov eax,100
    call GetRandomRange
    mov ecx,eax
    inc ecx
;
    shl eax,3
    push ecx
    AllocateBigLinear
    pop ecx
    mov edi,edx
;
    mov eax,10
    call GetRandomRange
    mov esi,eax
;
    mov eax,10
    call GetRandomRange
    mov ebp,eax
;
    push ecx

crsLoop:
    GetRandom
    stosd
;
    mov eax,esi
    call GetRandomRange
    add eax,ebp
    stosd
;
    loop crsLoop
;
    pop ecx
;
    pop ebp
    pop edi
    pop esi
    pop eax
    ret
CreateRandomSectors Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMinMaxMsb
;
;       DESCRIPTION:    Get min & max MSB sector values
;
;       PARAMETERS:     ECX             Size
;                       EDX             Data
;
;       RETURNS:        EAX             Min
;                       EBX             Max
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMinMax Proc near
    push ecx
    push esi
;
    mov esi,edx
    add esi,4
    mov eax,ds:[esi]
    mov ebx,eax

gmmLoop:
    cmp eax,ds:[esi]
    jbe gmmNotMin
;
    mov eax,ds:[esi]

gmmNotMin:
    cmp ebx,ds:[esi]
    jae gmmNotMax
;
    mov ebx,ds:[esi]

gmmNotMax:
    add esi,8
    loop gmmLoop
;
    pop esi
    pop ecx   
    ret
GetMinMax Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateReqSel
;
;       DESCRIPTION:    Create req selector
;
;       PARAMETERS:     ECX             Size
;                       EDX             Data
;                       EAX             Min MSB
;                       EBX             Max MSB
;
;       RETURNS:        ES              Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateReqSel Proc near
    pushad
;
    push eax
    push ebx
;
    sub ebx,eax
    inc ebx
    shl ebx,3
;
    mov eax,ecx
    shl eax,4
    add eax,ebx
    add eax,SIZE req_sel_struc
;
    AllocateBigMem
;
    pop ebx
    pop eax
;
    mov es:rqs_start_msb,eax
    sub ebx,eax
    inc ebx
    mov es:rqs_msb_count,ebx
    mov es:rqs_sectors,ecx
;
    mov edi,SIZE req_sel_struc
    mov es:rqs_chain_ptr,edi
;
    mov esi,edx
    rep movsd
    mov es:rqs_sorted_ptr,edi
;
    mov ecx,es:rqs_sectors
    mov eax,-1
    shl ecx,1
    rep stosd
    mov es:rqs_index_ptr,edi
;
    mov ecx,es:rqs_sectors
    mov eax,-1
    rep stosd
    mov es:rqs_msb_ptr,edi
;
    mov ecx,es:rqs_msb_count
    shl ecx,1
    xor eax,eax
    rep stosd   
;
    popad
    ret
CreateReqSel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SortMsbReq
;
;       DESCRIPTION:    Sort req selector, MSB part
;
;       PARAMETERS:     ES              Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SortMsbReq  Proc near
    push ds
    pushad
;
    mov eax,es
    mov ds,eax
;
    mov edx,ds:rqs_start_msb
    mov edi,ds:rqs_sorted_ptr
    mov esi,ds:rqs_index_ptr
    mov ebx,ds:rqs_msb_ptr

smrMsbLoop:
    mov ds:[ebx].rqm_ptr,edi
    push ebx
;
    mov ebx,ds:rqs_chain_ptr
    mov ecx,ds:rqs_sectors
    xor ebp,ebp

smrSectorLoop:
    cmp edx,ds:[ebx+4]
    jne smrSectorNext
;
    mov eax,ds:[ebx]
    mov ds:[edi],eax
    mov ds:[esi],ebx
    add esi,4
    add edi,4
    inc ebp

smrSectorNext:
    add ebx,8
    loop smrSectorLoop
;
    pop ebx
;
    mov ds:[ebx].rqm_count,ebp
;
    or ebp,ebp
    jz smrMsbNext
;
    xor cl,cl
    sub ebp,1
    jz smrAdjustDone
    
smrAdjustLoop:
    inc cl
    shr ebp,1
    jnz smrAdjustLoop

smrAdjustDone:
    mov eax,1
    shl eax,cl
    mov ecx,eax
    sub ecx,ds:[ebx].rqm_count
    jz smrMsbNext
;
    mov eax,-1

smrPadLoop:
    mov ds:[esi],eax
    mov ds:[edi],eax
    add esi,4
    add edi,4
    loop smrPadLoop

smrMsbNext:
    add ebx,SIZE req_msb_struc
    inc edx
    mov eax,edx
    sub eax,ds:rqs_start_msb
    cmp eax,ds:rqs_msb_count
    jne smrMsbLoop
;
    popad
    pop ds
    ret
SortMsbReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TestGate
;
;       DESCRIPTION:    Test sector ordering
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_gate_name       DB 'Test Gate',0

test_gate    Proc far
    push ds
    push es
    pushad
;
    call CreateRandomSectors
    call GetMinMax
    call CreateReqSel
    call SortMsbReq
;
    popad
    pop es
    pop ds
    ret
test_gate    Endp

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
;       NAME:           init_file
;
;       description:    Init file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_file

init_file    Proc near
    mov bx,vfs_file_sel
    CreateFixedShareBlock
;
    InitSection es:fs_section
    mov es:fs_handle_count,0
    mov es:fs_max_size,0
;
    mov bx,vfs_req_sel
    CreateFixedShareBlock
;
    mov es:rs_handle_count,0
    mov es:rs_max_size,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax 
;
    mov edi,OFFSET delete_handle
    mov ax,VFS_FILE_HANDLE
    RegisterHandle
;
    mov esi,OFFSET serv_open_file
    mov edi,OFFSET serv_open_file_name
    xor cl,cl
    mov ax,serv_open_file_nr
    RegisterServGate
;
    mov esi,OFFSET serv_add_file_req
    mov edi,OFFSET serv_add_file_req_name
    xor cl,cl
    mov ax,serv_add_file_req_nr
    RegisterServGate
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
;
    mov esi,OFFSET test_gate
    mov edi,OFFSET test_gate_name
    xor dx,dx
    mov ax,test_gate_nr
    RegisterBimodalUserGate
    ret
init_file    Endp

code    ENDS

    END
