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
    extern GetPartSel:near

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
;       NAME:           AddReq
;
;       DESCRIPTION:    Add as a req
;
;       PARAMETERS:     DS          Req sel
;                       FS          Part sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReq    Proc near
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov eax,fs
    mov es,eax

adLoop:
    mov ecx,MAX_VFS_READ_COUNT
    mov edi,OFFSET vfsp_req_arr + 2 * MAX_VFS_REQ_COUNT
    xor ax,ax
    repnz scas word ptr es:[edi]
    jz adFound
;
    mov ax,10
    WaitMilliSec
    jmp adLoop

adFound:
    sub edi,2
    mov es:[edi],ds
;
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
AddReq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CopySectors
;
;       DESCRIPTION:    Copy sectors & convert to blocks
;
;       PARAMETERS:     FS          Part sel
;                       ECX         Size
;                       DS:ESI      Sector buf
;                       ES:EDI      Block buf
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

copy512  Proc near
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    mov es:[edi],eax
    mov es:[edi+4],edx
    add esi,8
    add edi,8
    loop copy512
    ret
copy512  Endp

copy1k  Proc near
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    add eax,eax
    adc edx,edx
    mov es:[edi],eax
    mov es:[edi+4],edx
    add esi,8
    add edi,8
    loop copy1k
    ret
copy1k  Endp

copy2k  Proc near
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    add eax,eax
    adc edx,edx
    add eax,eax
    adc edx,edx
    mov es:[edi],eax
    mov es:[edi+4],edx
    add esi,8
    add edi,8
    loop copy2k
    ret
copy2k  Endp

copy4k  Proc near
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    add eax,eax
    adc edx,edx
    add eax,eax
    adc edx,edx
    add eax,eax
    adc edx,edx
    mov es:[edi],eax
    mov es:[edi+4],edx
    add esi,8
    add edi,8
    loop copy4k
    ret
copy4k  Endp

copy_tab:
ct00 dd OFFSET copy512
ct01 dd OFFSET copy1k
ct02 dd OFFSET copy2k
ct03 dd OFFSET copy4k

CopySectors    Proc near
    push gs
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    or ecx,ecx
    jz csDone
;
    mov gs,fs:vfsp_disc_sel
    movzx ebx,gs:vfs_sector_shift
    shl ebx,3
    call dword ptr cs:[ebx].copy_tab

csDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop gs
    ret
CopySectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateReqSel
;
;       DESCRIPTION:    Create req selector
;
;       PARAMETERS:     FS              Part sel
;                       ECX             Size
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
    shl ebx,4
;
    mov eax,ecx
    inc eax
    shl eax,4
    add ebx,eax
    mov eax,ecx
    inc eax
    shl eax,3
    add eax,ebx
    add eax,SIZE vfs_read_entry
;
    AllocateBigMem
;
    pop ebx
    pop eax
;
    mov es:vfs_rd_start_msb,eax
    sub ebx,eax
    inc ebx
    mov es:vfs_rd_msb_count,ebx
    mov es:vfs_rd_sectors,ecx
;
    mov edi,SIZE vfs_read_entry
    mov es:vfs_rd_chain_ptr,edi
;
    mov esi,edx
    call CopySectors
;
    mov ecx,es:vfs_rd_sectors
    shl ecx,3
    add edi,ecx
    mov es:vfs_rd_sorted_ptr,edi
;
    mov ecx,es:vfs_rd_sectors
    inc ecx
    mov eax,-1
    shl ecx,1
    rep stosd
    mov es:vfs_rd_index_ptr,edi
;
    mov ecx,es:vfs_rd_sectors
    inc ecx
    shl ecx,1
    mov eax,-1
    rep stosd
    mov es:vfs_rd_msb_ptr,edi
;
    mov ecx,es:vfs_rd_msb_count
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
;       PARAMETERS:     DS              Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SortMsbReq  Proc near
    pushad
;
    mov edx,ds:vfs_rd_start_msb
    mov edi,ds:vfs_rd_sorted_ptr
    mov esi,ds:vfs_rd_index_ptr
    mov ebx,ds:vfs_rd_msb_ptr

smrMsbLoop:
    mov ds:[ebx].vfsm_rd_ptr,edi
    push ebx
;
    mov ebx,ds:vfs_rd_chain_ptr
    mov ecx,ds:vfs_rd_sectors
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
    mov ds:[ebx].vfsm_rd_count,ebp
    mov ds:[ebx].vfsm_rd_size,ebp
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
    mov ds:[ebx].vfsm_rd_size,ecx
    sub ecx,ds:[ebx].vfsm_rd_count
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
    add ebx,16
    inc edx
    mov eax,edx
    sub eax,ds:vfs_rd_start_msb
    cmp eax,ds:vfs_rd_msb_count
    jne smrMsbLoop
;
    popad
    ret
SortMsbReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SortOneReq
;
;       DESCRIPTION:    Sort one req
;
;       PARAMETERS:     DS              Req sel
;                       EBX             Sorted & index offset
;                       ECX             Entry count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

so_new_ind EQU 0
so_min     EQU 4

SortOneReq  Proc near
    pushad
;
    mov esi,ds:vfs_rd_sorted_ptr
    mov edi,ds:vfs_rd_index_ptr
    add esi,ebx
    add edi,ebx

sorRetry:
    xor ebx,ebx
;
    push ecx
    push esi
    push edi
;
    mov eax,-1
    push eax
    push ecx
    mov ebp,esp
;
    dec ecx
    inc ebx

sorSortLoop:
    mov eax,ds:[4*ebx+esi]
    cmp eax,ds:[4*ebx+esi-4]
    jae sorSortNext
;
    cmp ebx,[ebp].so_new_ind
    jae sorScan
;
    mov [ebp].so_new_ind,ebx

sorScan:
    push ecx
;
    xor edx,edx
    mov ecx,ebx
    shr ecx,1
    jz sorIntFound

sorIntLoop:
    add edx,ecx
;
    cmp eax,ds:[4*edx+esi]
    jae sorIntNext
;
    sub edx,ecx

sorIntNext:
    shr ecx,1
    jnz sorIntLoop

sorIntFound:
    cmp eax,ds:[4*edx+esi]
    jbe sorIntSwap
;
    inc edx
    cmp eax,ds:[4*edx+esi]
    jb sorIntSwap
;
    cmp eax,[ebp].so_min
    jae sorIntDone
;
    mov [ebp].so_min,eax
    jmp sorIntDone

sorIntSwap:
    cmp edx,[ebp].so_new_ind
    jae sorXch
;
    mov [ebp].so_new_ind,edx

sorXch:
    mov eax,ds:[4*edx+esi]
    xchg eax,ds:[4*ebx+esi]
    mov ds:[4*edx+esi],eax
;
    mov eax,ds:[4*edx+edi]
    xchg eax,ds:[4*ebx+edi]
    mov ds:[4*edx+edi],eax

sorIntDone:
    pop ecx

sorSortNext:
    inc ebx
    loop sorSortLoop
;
    pop eax
    pop edx
;
    pop edi
    pop esi
    pop ecx
;
    cmp ecx,eax
    jbe sorDone

sorAdvanceLoop:
    add esi,4
    add edi,4
    dec ecx
    cmp ecx,1
    jbe sorDone
;
    cmp edx,ds:[esi]
    jb sorRetry
;
    sub eax,1
    jnc sorAdvanceLoop
;
    jmp sorRetry

sorDone:
    popad
    ret
SortOneReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SortLsbReq
;
;       DESCRIPTION:    Sort req selector, LSB part
;
;       PARAMETERS:     DS              Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SortLsbReq  Proc near
    push ebx
    push ecx
;
    mov ebx,ds:vfs_rd_msb_ptr
    mov ecx,ds:vfs_rd_msb_count

slrLoop:
    push ebx
    push ecx
;
    mov ecx,ds:[ebx].vfsm_rd_size
    mov ebx,ds:[ebx].vfsm_rd_ptr
    cmp ecx,1
    jbe slrNext
;
    sub ebx,ds:vfs_rd_sorted_ptr
    call SortOneReq

slrNext:
    pop ecx
    pop ebx
;
    add ebx,16
    loop slrLoop
;
    pop ecx
    pop ebx
    ret
SortLsbReq  Endp

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
    push fs
    push gs
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
    push ds
;
    mov bx,ds:[ebx].fs_handle_arr
    or bx,bx
    stc
    jz safLeave
;
    mov gs,bx
    movzx bx,gs:fi_part
    call GetPartSel
    jc safLeave
;
    push eax
    push edx
;
    mov eax,es
    mov ds,eax
    mov edx,edi
    call GetMinMax
    call CreateReqSel
;
    pop edx
    pop eax
    jc safLeave
;
    mov eax,es
    mov ds,eax
    call SortMsbReq
    call SortLsbReq
    call AddReq

safLeave:
    pop ds
    LeaveSection ds:fs_section

safDone:
    pop esi
    pop ebx
    pop gs
    pop fs
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


;
;
; test only
;
;


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
    mov eax,1000
    call GetRandomRange
    mov ecx,eax
    inc ecx
;
    mov eax,ecx
    shl eax,3
    push ecx
    AllocateBigLinear
    pop ecx
    mov edi,edx
;
    mov eax,25
    call GetRandomRange
    mov esi,eax
;
    mov eax,25
    call GetRandomRange
    mov ebp,eax
;
    push ecx

crsLoop:
    mov eax,0FFFFh
    call GetRandomRange
    or ah,ah
    jne crsBig

crsSmall:
    movsx eax,al
    jmp crsSave

crsBig:
    GetRandom

crsSave:
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
;       NAME:           FindReq
;
;       DESCRIPTION:    Find a request
;
;       PARAMETERS:     DS              Req sel
;                       EDX:EAX         Sector
;
;       RETURNS:        NC              Found
;                         EAX           Entry index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindReq  Proc near
    push ebx
    push ecx
    push edx
    push ebp
;
    sub edx,ds:vfs_rd_start_msb
    jc frFail
;
    cmp edx,ds:vfs_rd_msb_count
    jae frFail
;
    shl edx,4
    add edx,ds:vfs_rd_msb_ptr
    mov ebx,ds:[edx].vfsm_rd_ptr
    mov ebp,ebx
    mov ecx,ds:[edx].vfsm_rd_size
    shr ecx,1
    jz frCheck

frLoop:
    lea edx,[4*ecx]
    add ebx,edx
    cmp eax,ds:[ebx]
    je frFound
    ja frNext
;
    sub ebx,edx

frNext:
    shr ecx,1
    jnz frLoop

frCheck:
    cmp eax,ds:[ebx]
    je frFound

frFail:
    stc
    jmp frDone

frFound:
    cmp eax,-1
    jne frOk

frMax:
    cmp ebx,ebp
    je frOk
;
    cmp eax,ds:[ebx-4]
    jne frOk
;
    sub ebx,4
    jmp frMax

frOk:
    sub ebx,ds:vfs_rd_sorted_ptr
    shr ebx,2
    mov eax,ebx
    clc

frDone:
    pop ebp
    pop edx
    pop ecx
    pop ebx
    ret
FindReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CheckReq
;
;       DESCRIPTION:    Check correctness of request
;
;       PARAMETERS:     DS              Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckReq  Proc near
    pushad
;
    mov ebx,ds:vfs_rd_chain_ptr
    mov esi,ds:vfs_rd_index_ptr
    mov ecx,ds:vfs_rd_sectors

crLoop:
    mov eax,ds:[ebx]
    mov edx,ds:[ebx+4]
    call FindReq
    jc crFail
;
    mov edx,ds:[4*eax+esi]
    mov eax,ds:[edx]
    cmp eax,ds:[ebx]
    jne crFail
;
    mov eax,ds:[edx+4]
    cmp eax,ds:[ebx+4]
    je crNext

crFail:
    int 3
    stc
    jmp crDone

crNext:
    add ebx,8
    loop crLoop
;
    clc

crDone:
    popad
    ret
CheckReq  Endp

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

tRetry:
    call GetMinMax
    call CreateReqSel
;
    mov eax,es
    mov ds,eax
;
    call SortMsbReq
    call SortLsbReq
;
    call CheckReq
    jnc tNext
;
    int 3
    xor eax,eax
    mov ds,eax
    FreeMem
    jmp tRetry

tNext:
    push ecx
    shl ecx,3
    FreeLinear
    pop ecx
;
    xor eax,eax
    mov ds,eax
    FreeMem
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
