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
; VFSsfile.ASM
; VFS server file part
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
INCLUDE ..\os\blk.inc
INCLUDE ..\hint.inc
include ..\fs.inc
include ..\os\exec.def
include ..\filemap.inc
include vfs.inc
include vfsmsg.inc
include vfsfile.inc

    .386p

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern HandleToPartFs:near
    extern FileHandleToPartFs:near
    extern BlockToBuf:near
    extern AddToBitmap:near
    extern CreateFileSel:near
    extern UpdateFileSel:near
    extern CloseFileSel:near
    extern NotifyFileData:near
    extern NotifyFileSignal:near
    extern UnlinkRequest:near
    extern AddFileReq:near
    extern UpdateFileReq:near
    extern DisableFileReq:near
    extern FreeFileReq:near
    extern GetFileDebugInfo:near
    extern RelSectorToBlock:near

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

InitFilePart    Proc near
    push eax
    push ecx
    push edi
;
    mov ecx,MAX_VFS_FILE_COUNT - 1
    mov edi,OFFSET vfsp_file_arr
    mov es:vfsp_file_list,di
    mov eax,edi

ifpFileLoop:
    add eax,4
    mov es:[edi].ff_link,ax
    mov es:[edi].ff_sel,0
    mov edi,eax
    loop ifpFileLoop
;
    mov es:[edi].ff_link,cx
;
    pop edi
    pop ecx    
    pop eax
    ret
InitFilePart    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateFileHandle
;
;       DESCRIPTION:    Allocate file handle
;
;       PARAMETERS:     FS          Part sel
;                       EBX         VFS handle
;                       ECX         Req block linear
;                       EDX         File info linear
;                       DI          Sector size
;
;       RETURNS:        EBX         File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateFileHandle      Proc near
    push ds
    push eax
    push esi
;
    mov eax,fs
    mov ds,eax
    EnterSection ds:vfsp_req_section
;
    movzx esi,ds:vfsp_file_list
    or esi,esi
    jnz afhOk
;
    int 3
    LeaveSection ds:vfsp_req_section
    stc
    jmp afhDone

afhOk:
    mov eax,esi
    shl ebx,16
    sub eax,OFFSET vfsp_file_arr
    shr eax,2
    inc eax
    or ebx,eax
;
    call CreateFileSel
    mov ds:[esi].ff_sel,ax
;
    xor ax,ax
    xchg ax,ds:[esi].ff_link
    mov ds:vfsp_file_list,ax
    LeaveSection ds:vfsp_req_section
;
    clc

afhDone:
    pop esi
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
;                       ECX            Req block
;                       EDX            File info
;
;       RETURNS:        EBX            Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_open_file_name       DB 'Serv Open File',0

serv_open_file    Proc far
    push ds
    push fs
    push eax
    push edi
;
    call HandleToPartFs
;
    mov ds,fs:vfsp_disc_sel
    mov di,ds:vfs_bytes_per_sector
;
    mov ax,system_data_sel
    mov ds,ax
    add ecx,ds:flat_base
    add edx,ds:flat_base
    call AllocateFileHandle
;
    pop edi
    pop eax
    pop fs
    pop ds
    ret
serv_open_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServUpdateFileReq
;
;       DESCRIPTION:    Serv update VFS file req
;
;       PARAMETERS:     EBX            kernel handle
;                       EDX            req # (1-based)
;                       ESI            offset
;                       ECX            count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_update_file_req_name       DB 'Serv Update File Req',0

serv_update_file_req    Proc far
    push fs
    push gs
    push eax
    push ebx
;
    call FileHandleToPartFs
    jc sufrDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc sufrDone
;
    dec bx
    shl bx,2
    add bx,OFFSET vfsp_file_arr
    mov gs,fs:[bx].ff_sel
    or edx,edx
    stc
    jz sufrDone
;
    dec edx
    cmp edx,240
    cmc
    jc sufrDone
;
    call UpdateFileReq

sufrDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
serv_update_file_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServDisableFileReq
;
;       DESCRIPTION:    Serv disable VFS file req
;
;       PARAMETERS:     EBX            kernel handle
;                       EDX            req # (1-based)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_disable_file_req_name       DB 'Serv Disable File Req',0

serv_disable_file_req    Proc far
    push ds
    push fs
    push eax
    push ebx
;
    call FileHandleToPartFs
    jc sdfrDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc sdfrDone
;
    dec bx
    shl bx,2
    add bx,OFFSET vfsp_file_arr
    mov ds,fs:[bx].ff_sel
    or edx,edx
    stc
    jz sdfrDone
;
    dec edx
    cmp edx,240
    cmc
    jc sdfrDone
;
    call DisableFileReq

sdfrDone:
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
serv_disable_file_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServFreeFileReq
;
;       DESCRIPTION:    Serv free VFS file req
;
;       PARAMETERS:     EBX            kernel handle
;                       EDX            req # (1-based)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_free_file_req_name       DB 'Serv Free File Req',0

serv_free_file_req    Proc far
    push ds
    push fs
    push eax
    push ebx
;
    call FileHandleToPartFs
    jc sffrDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc sffrDone
;
    dec bx
    shl bx,2
    add bx,OFFSET vfsp_file_arr
    mov ds,fs:[bx].ff_sel
    or edx,edx
    stc
    jz sffrDone
;
    dec edx
    cmp edx,240
    cmc
    jc sffrDone
;
    call FreeFileReq

sffrDone:
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
serv_free_file_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServUpdateFile
;
;       DESCRIPTION:    Serv update VFS file
;
;       PARAMETERS:     EBX            kernel handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_update_file_name       DB 'Serv Update File',0

serv_update_file    Proc far
    push fs
    push eax
    push ecx
;
    call FileHandleToPartFs
    jc sufDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc sufDone
;
    dec bx
    shl bx,2
    add bx,OFFSET vfsp_file_arr
    mov ax,fs:[bx].ff_sel
;
    or ax,ax
    jz sufDone
;
    call UpdateFileSel

sufDone:
    pop ecx
    pop eax
    pop fs
    ret
serv_update_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServCloseFile
;
;       DESCRIPTION:    Serv close VFS file req
;
;       PARAMETERS:     EBX            kernel handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_close_file_name       DB 'Serv Close File',0

serv_close_file    Proc far
    push ds
    push fs
    push eax
    push ecx
;
    call FileHandleToPartFs
    jc scfDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc scfDone
;
    mov eax,fs
    mov ds,eax
    EnterSection ds:vfsp_req_section
;
    xor ax,ax
    dec bx
    shl bx,2
    add bx,OFFSET vfsp_file_arr
    xchg ax,ds:[bx].ff_sel
;
    or ax,ax
    jz scfLeave
;
    call CloseFileSel
;
    mov ax,ds:vfsp_file_list
    mov ds:[bx].ff_link,ax
    mov ds:vfsp_file_list,bx

scfLeave:
    LeaveSection ds:vfsp_req_section

scfDone:
    pop ecx
    pop eax
    pop fs
    pop ds
    ret
serv_close_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServFileInfo
;
;       DESCRIPTION:    Serv file info
;
;       PARAMETERS:     EBX            kernel handle
;
;       RETURNS:        EAX            Req count
;                       EBX            Wait count
;                       ECX            Block count
;                       EDX            Phys count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_file_info_name       DB 'Serv File Info',0

serv_file_info    Proc far
    push ds
    push fs
;
    call FileHandleToPartFs
    jc sfiDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    cmc
    jc sfiDone
;
    dec bx
    shl bx,2
    add bx,OFFSET vfsp_file_arr
    mov ds,fs:[bx].ff_sel
    call GetFileDebugInfo
    clc

sfiDone:
    pop fs
    pop ds
    ret
serv_file_info    Endp

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
    push es
    push eax
    push ebx
    push edx
    push esi
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
    call NotifyFileData
    call UnlinkRequest
;
    mov eax,gs
    mov es,eax
    xor eax,eax
    mov gs,eax
    FreeBigServSel
    jmp nrqDone
    
nrqScanNext:
    add ebx,4
    sub ebp,1
    jnz nrqScanLoop

nrqDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    pop es
    ret
NotifyReq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetMinMax
;
;       DESCRIPTION:    Get min & max MSB sector values
;
;       PARAMETERS:     ECX             Size
;                       DS:ESI          Data
;
;       RETURNS:        EAX             Min
;                       EBX             Max
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMinMax Proc near
    push ecx
    push esi
;
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
;       PARAMETERS:     FS              Part sel
;                       ECX             Size
;                       DS:ESI          Data
;                       EAX             Min MSB
;                       EBX             Max MSB
;
;       RETURNS:        ES              Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateReqSel Proc near
    pushad
;
    mov ebp,esi
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
    shl ecx,1
    rep movs dword ptr es:[edi],ds:[esi]
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
;       NAME:           StartOneRead
;
;       DESCRIPTION:    Start one read
;
;       PARAMETERS:     FS          Part sel
;                       EDX         MSB sector
;                       GS:EDI      LSB sector array
;                       ECX         Sector count
;                       BP          Req bitmap
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartOneRead  Proc near

srorLoop:
    mov eax,gs:[edi]
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz srorReq
;
    cmp es:[esi].vfsp_ref_bitmap,0
    jnz srorLockOk
;
    inc ds:vfs_locked_pages

srorLockOk:
    inc es:[esi].vfsp_ref_bitmap
    jmp srorNext

srorReq:
    inc gs:vfs_rd_remain_count
    test bp,es:[esi].vfsp_ref_bitmap
    jnz srorNext
;
    or es:[esi].vfsp_ref_bitmap,bp
    call AddToBitmap

srorNext:
    add edi,4
    sub ecx,1
    jnz srorLoop
;
    ret
StartOneRead    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartRead
;
;       DESCRIPTION:    Start read req
;
;       PARAMETERS:     DS          Req sel
;                       FS          Part sel
;                       BX          Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartRead        Proc near
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
    jnz srrDone
;
    mov ds,fs:vfsp_disc_sel
    mov eax,serv_flat_sel
    mov es,eax
    EnterSection ds:vfs_section
;
    mov edi,gs:vfs_rd_msb_ptr
    mov ecx,gs:vfs_rd_msb_count
    mov edx,gs:vfs_rd_start_msb

srrLoop:
    push ecx
    push edi
;
    mov ecx,gs:[edi].vfsm_rd_count
    mov edi,gs:[edi].vfsm_rd_ptr
    call StartOneRead

srrNext:
    pop edi
    pop ecx
;
    inc edx
    add edi,16
    loop srrLoop
;
    LeaveSection ds:vfs_section

srrDone:
    pop ebp
    pop edi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop es
    pop ds
    ret
StartRead     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartWrite
;
;       DESCRIPTION:    Start write req
;
;       PARAMETERS:     DS          Req sel
;                       FS          Part sel
;                       BX          Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartWrite        Proc near
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
    jnz srwDone
;
    mov ds,fs:vfsp_disc_sel
    mov eax,serv_flat_sel
    mov es,eax
    EnterSection ds:vfs_section
;
    mov edi,gs:vfs_rd_msb_ptr
    mov ecx,gs:vfs_rd_msb_count
    mov edx,gs:vfs_rd_start_msb

srwLoop:
    push ecx
    push edi
;
    mov ecx,gs:[edi].vfsm_rd_count
    mov edi,gs:[edi].vfsm_rd_ptr
    call StartOneRead

srwNext:
    pop edi
    pop ecx
;
    inc edx
    add edi,16
    loop srwLoop
;
    LeaveSection ds:vfs_section

srwDone:
    pop ebp
    pop edi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop es
    pop ds
    ret
StartWrite     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServFileReadReq
;
;       DESCRIPTION:    Serv add VFS file read req
;
;       PARAMETERS:     EBX            File handle
;                       ESI            Req index
;                       EDX:EAX        Position
;                       ECX            Sector count
;                       ES:EDI         Sector buf
;
;       RETURNS:        ECX            Cached count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_file_read_req_name       DB 'Serv Add File Read Req',0

serv_file_read_req    Proc far
    push ds
    push es
    push fs
    push gs
    push ebx
    push esi
    push edi
    push ebp
;
    mov ebp,ebx
    call FileHandleToPartFs
    cmc
    jnc safrFail
;
    cmp bx,MAX_VFS_FILE_COUNT    
    jnc safrFail
;
    or ecx,ecx
    jz safrFail
;
    call RelSectorToBlock
;
    or ecx,ecx
    jz safrFail
;
    call AddFileReq
    jc safrFail
;
    mov edx,esi
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    call GetMinMax
    call CreateReqSel
;
    mov eax,es
    mov ds,eax
;
    mov ds:vfs_rd_file_handle,ebp
    mov ds:vfs_rd_index,edx
    mov ds:vfs_rd_req_handle,0
;
    call SortMsbReq
    call SortLsbReq
    call CreateReq
    call StartRead
;
    mov eax,ds:vfs_rd_remain_count
    or eax,eax
    jz safrProcess
;
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    jmp safrDone

safrProcess:    
    mov eax,ds
    mov gs,eax
    call UnlinkRequest
;
    mov ds,fs:vfsp_disc_sel
    EnterSection ds:vfs_section
    call NotifyFileData
    LeaveSection ds:vfs_section
;
    mov eax,gs
    mov es,eax
    xor eax,eax
    mov gs,eax
    FreeBigServSel
    jmp safrDone

safrFail:
    xor ecx,ecx

safrDone:
    pop ebp
    pop edi
    pop esi
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
serv_file_read_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           PrepareWrite
;
;       DESCRIPTION:    Prepare to write
;
;       PARAMETERS:     FS          Part sel
;                       DS:EDI      Sector array
;                       ECX         Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrepareWrite  Proc near
    push ds
    push es
    push gs
    pushad
;
    mov eax,ds
    mov gs,eax
    mov ds,fs:vfsp_disc_sel
    mov eax,serv_flat_sel
    mov es,eax
;
    EnterSection ds:vfs_section
;
    mov eax,gs:[edi]
    add eax,fs:vfsp_start_sector
    test al,7
    jz pwCheckMid

pwStartLoop:
    add edi,8
    sub ecx,1
    jz pwDone
;
    mov eax,gs:[edi]
    add eax,fs:vfsp_start_sector
    test al,7
    jnz pwStartLoop

pwCheckMid:
    cmp ecx,8
    jb pwDone

pwMidLoop:
    mov eax,gs:[edi]
    mov edx,gs:[edi+4]
    add eax,fs:vfsp_start_sector
    adc edx,fs:vfsp_start_sector+4
    call BlockToBuf
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jnz pwMidNext
;
    or es:[esi].vfsp_flags,VFS_PHYS_VALID
    mov es:[esi].vfsp_ref_bitmap,1
    inc ds:vfs_locked_pages
    or byte ptr gs:[edi+7],80h

pwMidNext:
    add edi,8
    sub ecx,1
    jz pwDone
;
    mov eax,gs:[edi]
    add eax,fs:vfsp_start_sector
    test al,7
    jnz pwMidLoop
;
    cmp ecx,8
    jae pwMidLoop

pwDone:
    LeaveSection ds:vfs_section
;
    popad
    pop gs
    pop es
    pop ds
    ret
PrepareWrite    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CleanupWrite
;
;       DESCRIPTION:    Clean up locks after write
;
;       PARAMETERS:     FS          Part sel
;                       DS:EDI      Sector array
;                       ECX         Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupWrite  Proc near
    push ds
    push es
    push gs
    pushad
;
    mov eax,ds
    mov gs,eax
    mov ds,fs:vfsp_disc_sel
    mov eax,serv_flat_sel
    mov es,eax
;
    EnterSection ds:vfs_section

cwLoop:
    mov edx,gs:[edi+4]
    test edx,80000000h
    jz cwNext
;
    and byte ptr gs:[edi+7],7Fh
    mov edx,gs:[edi+4]
    mov eax,gs:[edi]    
    add eax,fs:vfsp_start_sector
    adc edx,fs:vfsp_start_sector+4
    call BlockToBuf
;
    sub es:[esi].vfsp_ref_bitmap,1
    jnz cwNext
;
    dec ds:vfs_locked_pages

cwNext:
    add edi,8
    loop cwLoop
;
    LeaveSection ds:vfs_section
;
    popad
    pop gs
    pop es
    pop ds
    ret
CleanupWrite    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServFileWriteReq
;
;       DESCRIPTION:    Serv add VFS file write req
;
;       PARAMETERS:     EBX            File handle
;                       ESI            Req index
;                       EDX:EAX        Position
;                       ECX            Sector count
;                       ES:EDI         Sector buf
;
;       RETURNS:        ECX            Cached count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_file_write_req_name       DB 'Serv Add File Write Req',0

serv_file_write_req    Proc far
    push ds
    push es
    push fs
    push gs
    push ebx
    push esi
    push ebp
;
    mov ebp,ebx
    call FileHandleToPartFs
    cmc
    jnc safwFail
;
    cmp bx,MAX_VFS_FILE_COUNT    
    jnc safwFail
;
    or ecx,ecx
    jz safwFail
;
    call RelSectorToBlock
;
    or ecx,ecx
    jz safwFail
;
    push ecx
    call AddFileReq
    pop eax
    jc safwFail
;
    push ecx
    mov ecx,eax
;
    mov edx,esi
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    call GetMinMax
    call CreateReqSel
    call PrepareWrite
;
    push ds
    push edi
;
    mov eax,es
    mov ds,eax
    mov ds:vfs_rd_file_handle,ebp
    mov ds:vfs_rd_index,edx
    mov ds:vfs_rd_req_handle,0
;
    call SortMsbReq
    call SortLsbReq
    call CreateReq
    call StartRead
;
    mov eax,ds
    pop edi
    pop ds
;
    push eax
    call CleanupWrite
    pop ds
;
    mov eax,ds:vfs_rd_remain_count
    or eax,eax
    jz safwProcess
;
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    jmp safwComplete

safwProcess:    
    mov eax,ds
    mov gs,eax
    call UnlinkRequest
;
    mov ds,fs:vfsp_disc_sel
    EnterSection ds:vfs_section
    call NotifyFileData
    LeaveSection ds:vfs_section
;
    mov eax,gs
    mov es,eax
    xor eax,eax
    mov gs,eax
    FreeBigServSel

safwComplete:
    pop ecx
    jmp safwDone

safwFail:
    xor ecx,ecx
    stc

safwDone:
    pop ebp
    pop esi
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
serv_file_write_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServNotifyFileReq
;
;       DESCRIPTION:    Serv notify VFS file req
;
;       PARAMETERS:     EBX            File handle
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_notify_file_req_name       DB 'Serv Notify File Req',0

serv_notify_file_req    Proc far
    push fs
;
    call FileHandleToPartFs
    cmc
    jnc snfDone
;
    cmp bx,MAX_VFS_FILE_COUNT    
    jnc snfDone
;
    call NotifyFileSignal
    clc

snfDone:
    pop fs
    ret
serv_notify_file_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_server_file
;
;       description:    Init file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_server_file

init_server_file    Proc near
    mov ax,cs
    mov ds,ax
    mov es,ax 
;
    mov esi,OFFSET serv_open_file
    mov edi,OFFSET serv_open_file_name
    xor cl,cl
    mov ax,serv_open_file_nr
    RegisterServGate
;
    mov esi,OFFSET serv_update_file_req
    mov edi,OFFSET serv_update_file_req_name
    xor cl,cl
    mov ax,serv_update_file_req_nr
    RegisterServGate
;
    mov esi,OFFSET serv_disable_file_req
    mov edi,OFFSET serv_disable_file_req_name
    xor cl,cl
    mov ax,serv_disable_file_req_nr
    RegisterServGate
;
    mov esi,OFFSET serv_free_file_req
    mov edi,OFFSET serv_free_file_req_name
    xor cl,cl
    mov ax,serv_free_file_req_nr
    RegisterServGate
;
    mov esi,OFFSET serv_update_file
    mov edi,OFFSET serv_update_file_name
    xor cl,cl
    mov ax,serv_update_file_nr
    RegisterServGate
;
    mov esi,OFFSET serv_close_file
    mov edi,OFFSET serv_close_file_name
    xor cl,cl
    mov ax,serv_close_file_nr
    RegisterServGate
;
    mov esi,OFFSET serv_notify_file_req
    mov edi,OFFSET serv_notify_file_req_name
    xor cl,cl
    mov ax,serv_notify_file_req_nr
    RegisterServGate
;
    mov esi,OFFSET serv_file_read_req
    mov edi,OFFSET serv_file_read_req_name
    xor cl,cl
    mov ax,serv_file_read_req_nr
    RegisterServGate
;
    mov esi,OFFSET serv_file_write_req
    mov edi,OFFSET serv_file_write_req_name
    xor cl,cl
    mov ax,serv_file_write_req_nr
    RegisterServGate
;
    mov esi,OFFSET serv_file_info
    mov edi,OFFSET serv_file_info_name
    xor cl,cl
    mov ax,serv_file_info_nr
    RegisterServGate
    ret
init_server_file    Endp

code    ENDS

    END
