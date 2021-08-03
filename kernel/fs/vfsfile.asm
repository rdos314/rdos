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

MAX_FILE_REQ_ENTRIES = 8
MAX_FILE_REQ_COUNT   = 64
MAX_FILE_USERS       = 256

file_req_entry    STRUC

fre_pos            DD ?,?
fre_size           DD ?
fre_last_size      DW ?
fre_pages          DW ?
fre_arr            DD ?,?

file_req_entry    ENDS

file_req_handle    STRUC

frh_handle        DW ?
frh_count         DW ?
 
file_req_handle    ENDS

file_sys_entry    STRUC

fse_sector_size   DW ?
fse_req_count     DW ?
fse_insert        DW ?
fse_pad           DW ?

fse_user_arr      DD MAX_FILE_USERS DUP(?)
fse_req_arr       DW MAX_FILE_REQ_COUNT DUP(?,?)
fse_sorted_arr    DW MAX_FILE_REQ_COUNT DUP(?)

file_sys_entry    ENDS

file_handle_seg  STRUC

fh_base          handle_header <>

fh_pos           DD ?,?
fh_attrib        DD ?
fh_vfs_sel       DW ?
fh_vfs_handle    DD ?

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

file_info_struc  ENDS

; must be word aligned!

file_sel         STRUC

fs_header        share_block_struc <>
fs_section       section_typ <>

fs_handle_count  DD ?
fs_max_size      DD ?

fs_handle_arr    DW ?

file_sel         ENDS


file_part_req_struc  STRUC

fr_sel           DW ?
fr_link          DW ?

file_part_req_struc  ENDS

file_part_struc  STRUC

ff_link          DW ?
ff_info          DW ?
ff_sys           DW ?
ff_pad           DW ?

file_part_struc  ENDS

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
    extern BlockToBuf:near
    extern BlockToBitmap:near
    extern GetCmdData:near
    extern NotifyFileReply:near
    extern NotifyErrorReply:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitFilePart
;
;       DESCRIPTION:    Init file partition
;
;       PARAMETERS:     ES             Partition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitFilePart

InitFilePart	Proc near
    push eax
    push ecx
    push edi
;
    mov ecx,MAX_VFS_FILE_COUNT - 1
    mov edi,OFFSET vfsp_file_arr
    mov es:vfsp_file_list,di
    mov eax,edi

ifpFileLoop:
    add eax,8
    mov es:[edi].ff_link,ax
    mov es:[edi].ff_info,0
    mov es:[edi].ff_sys,0
    mov es:[edi].ff_pad,0
    mov edi,eax
    loop ifpFileLoop
;
    mov es:[edi].ff_link,cx
;
    mov ecx,MAX_VFS_FILE_REQ_COUNT - 1
    mov edi,OFFSET vfsp_file_req_arr
    mov es:vfsp_req_list,di
    mov eax,edi

ifpReqLoop:
    add eax,4
    mov es:[edi].fr_link,ax
    mov es:[edi].fr_sel,0
    mov edi,eax
    loop ifpReqLoop
;
    mov es:[edi].fr_link,cx
;
    pop edi
    pop ecx    
    pop eax
    ret
InitFilePart    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetFileReq
;
;       DESCRIPTION:    Get file req
;
;       PARAMETERS:     ES                 Partition
;                       EAX                File req handle
;                       DS:EDI             Req
;
;       RETURNS:        FS                 File req
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetFileReq

GetFileReq	Proc near
    push ds
    push eax
;
    or eax,eax
    jz gfrFail
;
    dec eax
    cmp eax,MAX_VFS_FILE_REQ_COUNT
    jae gfrFail
;
    shl eax,2
    add eax,OFFSET vfsp_file_req_arr
    mov fs,es:[eax].fr_sel
    clc
    jmp gfrDone

gfrFail:
    stc

gfrDone:
    pop eax
    pop ds
    ret
GetFileReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddFileData
;
;       DESCRIPTION:    Add file data to reply
;
;       PARAMETERS:     DS:EDI             Sector buffer
;                       ES                 Partition
;                       FS                 File req
;
;       RETURNS:        EBX                File req handle
;                       ECX                Sector count
;                       EDX:EAX            File offset
;                       ESI                Sector size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddFileData

AddFileData	Proc near
    push ds
    push es
    push gs
    push edi
    push ebp
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
    jz afdOk

afdLoop:
    mov eax,fs:[edi]
    mov edx,fs:[edi+4]
    call BlockToBuf
    jc afdFail
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz afdFail
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
    loop afdLoop

afdOk:
    mov ebx,fs:vfs_rd_handle
    mov eax,fs:vfs_rd_start
    mov edx,fs:vfs_rd_start+4
    mov ecx,fs:vfs_rd_sectors
    movzx esi,ds:vfs_bytes_per_sector
    clc
    jmp afdDone
    
afdFail:
    xor ecx,ecx
    stc

afdDone:
    pop ebp
    pop edi
    pop gs
    pop es
    pop ds
    ret
AddFileData     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateSysFile
;
;       DESCRIPTION:    Allocate sys file entry
;
;       PARAMETERS:     CX             Sector size
;
;       RETURNS:        NC
;                         AX           File sys sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateSysFile    Proc near
    push es
    push ebx
    push ecx
    push edx
    push edi
;
    push ecx
    mov eax,SIZE file_sys_entry
    AllocateBigLinear
    AllocateGdt
    mov ecx,SIZE file_sys_entry
    CreateDataSelector32
    pop ecx
;
    mov es,ebx
    mov es:fse_sector_size,cx
    mov es:fse_req_count,0
    mov es:fse_insert,SIZE file_sys_entry
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
AllocateSysFile   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateFileHandle
;
;       DESCRIPTION:    Allocate file handle
;
;       PARAMETERS:     ES          File info sel
;                       FS          Part sel
;                       CX          Sector size
;
;       RETURNS:        EBX         File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateFileHandle	Proc near
    push ds
    push eax
;
    mov eax,fs
    mov ds,eax
    EnterSection ds:vfsp_req_section
;
    movzx ebx,ds:vfsp_file_list
    or ebx,ebx
    jnz afhOk
;
    int 3
    LeaveSection ds:vfsp_req_section
    stc
    jmp afhDone

afhOk:
    mov ds:[ebx].ff_info,es
;
    call AllocateSysFile
    mov ds:[ebx].ff_sys,ax
;
    xor ax,ax
    xchg ax,ds:[ebx].ff_link
    mov ds:vfsp_file_list,ax
    LeaveSection ds:vfsp_req_section
;
    movzx eax,ds:vfsp_part_nr
    inc eax
    shl eax,24
    sub ebx,OFFSET vfsp_file_arr
    shr ebx,2
    inc ebx
    or ebx,eax
    clc

afhDone:
    pop eax
    pop ds
    ret
AllocateFileHandle Endp

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
    push fs
    push eax
    push ecx
;
    call HandleToPart
;
    mov ds,es:vfsp_disc_sel
    mov cx,ds:vfs_bytes_per_sector
;
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
    mov eax,es
    mov fs,eax    
;
    ServToSystemShareBlock
;
    call AllocateFileHandle
;
    pop ecx
    pop eax
    pop fs
    pop es
    pop ds
    ret
serv_open_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyReq
;
;       DESCRIPTION:    Notify req
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;                       GS          Req sel
;                       EDX:EAX     Sector
;                       SI          Req mask
;                       CX          Lock count
;
;       RETURNS:        CX          Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyReq    Proc near
    push ebx
    push edx
    push edi
    push ebp
;
    sub edx,gs:vfs_rd_start_msb
    jc nrqDone
;
    cmp edx,gs:vfs_rd_msb_count
    jae nrqDone
;
    shl edx,4
    add edx,gs:vfs_rd_msb_ptr
    mov edi,edx
    mov ebx,gs:[edi].vfsm_rd_ptr
    mov ebp,gs:[edi].vfsm_rd_size
;
    shr ebp,1
    jz nrqScan

nrqBinLoop:
    lea edx,[4*ebp]
    add ebx,edx
    cmp eax,gs:[ebx]
    ja nrqBinNext
;
    sub ebx,edx

nrqBinNext:
    shr ebp,1
    jnz nrqBinLoop

nrqScan:
    mov edx,ebx
    sub edx,gs:[edi].vfsm_rd_ptr
    shr edx,2
    mov ebp,gs:[edi].vfsm_rd_count
    sub ebp,edx
    jbe nrqDone

nrqScanLoop:
    mov edx,gs:[ebx]
    and dl,0F8h
    cmp eax,edx
    ja nrqScanNext
    jne nrqDone
;
    inc cx
    sub gs:vfs_rd_remain_count,1
    jnz nrqScanNext
;
    xor ax,ax
    xchg ax,gs:vfs_rd_req_sel
    or ax,ax
    jz nrqDone
;
    push ds
    push es
    push fs
;
    mov ds,eax
    call GetCmdData
;
    mov ebx,fs
    mov es,ebx
    mov ebx,gs
    mov fs,ebx
    call AddFileData
    jc nrqNotifyError
;
    call NotifyFileReply
    jmp nrqPop

nrqNotifyError:
    call NotifyErrorReply

nrqPop:
    pop fs
    pop es
    pop ds
    jc nrqFree
;

nrqFree:
    jmp nrqDone
    
nrqScanNext:
    add ebx,4
    sub ebp,1
    jnz nrqScanLoop

nrqDone:
    pop ebp
    pop edi
    pop edx
    pop ebx
    ret
NotifyReq    Endp

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
    AllocateBigServSel
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
;       NAME:           CreateReq
;
;       DESCRIPTION:    Create a disc req
;
;       PARAMETERS:     DS          Req sel
;                       FS          Part sel
;
;       RETURNS:        BX          Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateReq    Proc near
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
    push ebp
;
    mov ds:vfsr_callback, OFFSET NotifyReq
    mov ebp,ds
;
    mov eax,fs
    mov ds,eax
    mov es,eax

crLoop:
    EnterSection ds:vfsp_req_section
    mov ecx,MAX_VFS_REQ_COUNT
    mov edi,OFFSET vfsp_req_arr
    xor ax,ax
    repnz scas word ptr es:[edi]
    jz crFound
;
    LeaveSection ds:vfsp_req_section
    mov ax,10
    WaitMilliSec
    jmp crLoop

crFound:
    sub edi,2
    mov es:[edi],bp
    LeaveSection ds:vfsp_req_section
;
    mov bx,di
    sub bx,OFFSET vfsp_req_arr
    shr bx,1
    inc bx
;
    pop ebp
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
CreateReq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartOneReq
;
;       DESCRIPTION:    Start one req
;
;       PARAMETERS:     FS          Part sel
;                       EDX         MSB sector
;                       GS:EDI      LSB sector array
;                       ECX         Sector count
;                       BP          Ref bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartOneReq  Proc near

sroLoop:
    mov eax,gs:[edi]
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz sroReq
;
    cmp es:[esi].vfsp_ref_bitmap,0
    jnz sroLockOk
;
    inc ds:vfs_locked_pages

sroLockOk:
    inc es:[esi].vfsp_ref_bitmap
    jmp sroNext

sroReq:
    inc gs:vfs_rd_remain_count
    or es:[esi].vfsp_ref_bitmap,bp
;
    push edi
;
    call BlockToBitmap
    mov ebx,eax
    shr ebx,3
    and ebx,1FFFFh
    bts es:[edi],ebx
;
    pop edi
;
    mov ebx,ds:vfs_scan_pos
    and ebx,ds:vfs_scan_pos+4
    add ebx,1
    jnc sroNext
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

sroNext:
    add edi,4
    sub ecx,1
    jnz sroLoop
;
    ret
StartOneReq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartReq
;
;       DESCRIPTION:    Start req
;
;       PARAMETERS:     DS          Req sel
;                       FS          Part sel
;                       BX          Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartReq	Proc near
    push ds
    push es
    push gs
    push eax
    push ecx
    push edx
    push edi
    push ebp
;
    mov eax,ds
    mov gs,eax
    mov gs:vfs_rd_remain_count,0
;
    mov cl,bl
    mov bp,1
    shl bp,cl
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz srDone
;
    mov ds,fs:vfsp_disc_sel
    mov eax,serv_flat_sel
    mov es,eax
    EnterSection ds:vfs_section
;
    mov edi,gs:vfs_rd_msb_ptr
    mov ecx,gs:vfs_rd_msb_count
    mov edx,gs:vfs_rd_start_msb

srLoop:
    push ecx
    push edi
;
    mov ecx,gs:[edi].vfsm_rd_size
    mov edi,gs:[edi].vfsm_rd_ptr
    call StartOneReq

srNext:
    pop edi
    pop ecx
;
    inc edx
    add edi,16
    loop srLoop
;
    LeaveSection ds:vfs_section
    mov eax,gs:vfs_rd_remain_count
    or eax,eax
    clc
    jz srDone
;
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    clc

srDone:
    pop ebp
    pop edi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop es
    pop ds
    ret
StartReq     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateFileReq
;
;       DESCRIPTION:    Allocate file req entry
;
;       PARAMETERS:     FS          Part sel
;
;       RETURNS:        EBP         File req entry offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateFileReq	Proc near
    push ds
    push eax
;
    mov eax,fs
    mov ds,eax
    EnterSection ds:vfsp_req_section
;
    movzx ebp,ds:vfsp_req_list
    or ebp,ebp
    jnz afrOk
;
    int 3
    LeaveSection ds:vfsp_req_section
    stc
    jmp afrDone

afrOk:
    mov ax,ds:[ebp].fr_sel
    or ax,ax
    jz afrEmpty
;
    int 3
    LeaveSection ds:vfsp_req_section
    stc
    jmp afrDone

afrEmpty:
    mov ds:[ebp].fr_sel,-1
    mov ax,ds:[ebp].fr_link
    mov ds:vfsp_req_list,ax
    clc
    LeaveSection ds:vfsp_req_section
    clc

afrDone:
    pop eax
    pop ds
    ret
AllocateFileReq Endp

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
;                       ESI            Src of req
;                       ES:EDI         Sector buf
;
;       RETURNS:        EAX            File req handle
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
    push ebp
;
    or ebx,ebx
    stc
    jz safDone
;
    push es
    push ebx
;
    shr ebx,24
    call HandleToPart
;
    mov eax,es
    mov fs,eax
;
    pop ebx
    pop es
    jc safDone
;
    movzx ebx,bx
    or bx,bx
    stc
    jz safDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc safDone
;
    call AllocateFileReq
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
    jc safFail
;
    mov es:vfs_rd_start,eax
    mov es:vfs_rd_start+4,edx
    mov es:vfs_rd_handle,0
    mov es:vfs_rd_req_sel,0
;
    mov eax,es
    mov ds,eax
    call SortMsbReq
    call SortLsbReq
    call CreateReq
    call StartReq
    jc safFail
;
    mov eax,ds
    mov fs:[ebp].fr_sel,ax
    movzx eax,fs:vfsp_part_nr
    shl eax,24
    sub ebp,OFFSET vfsp_file_req_arr
    shr ebp,2
    inc ebp
    or eax,ebp
    mov es:vfs_rd_handle,ebp
    clc
    jmp safLeave

safFail:
    mov word ptr fs:[ebp],0

safLeave:
    pop ds
    LeaveSection ds:fs_section
    jnc safDone
;
    xor eax,eax

safDone:
    pop ebp
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
    push ds
    push es
    push eax
    push ebx
;
    mov ebx,ds:[ebx].fh_vfs_handle
    or ebx,ebx
    stc
    jz gfbDone
;
    push ebx
    shr ebx,24
    call HandleToPart
    mov eax,es
    mov gs,eax
    pop ebx
    jc gfbDone
;
    movzx ebx,bx
    or bx,bx
    stc
    jz gfbDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc gfbDone
;
    dec ebx
    shl ebx,2
    mov ax,ds:[ebx].ff_info
    or ax,ax
    stc
    je gfbDone
;
    mov gs,eax
    clc

gfbDone:
    pop ebx
    pop eax
    pop es
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
    add ebp,OFFSET fs_handle_arr
;
    mov bx,vfs_file_sel
    mov ds,bx
    EnterSection ds:fs_section
;    mov bx,ds:[ebp].fse_file_sel
    LeaveSection ds:fs_section
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
    ret
init_file    Endp

code    ENDS

    END
