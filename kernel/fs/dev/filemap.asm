;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modifyg
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
INCLUDE ..\os\blk.inc
INCLUDE ..\os\exec.def
include vfs.inc
include vfsmsg.inc
include vfsfile.inc

  REQ_READ = 1
  REQ_FREE = 2
  REQ_CLOSE = 3
  REQ_COMPLETED = 4
  REQ_MAP = 5
  REQ_SIZE = 6
  REQ_GROW = 7
  REQ_UPDATE = 8

    .386p

file_handle_seg     STRUC

fh_base       handle_header <>

fh_sel        DW ?
fh_handle     DW ?

file_handle_seg     ENDS

kernel_req_entry  STRUC

kre_pos           DD ?,?
kre_size          DD ?
kre_block_arr     DD ?
kre_phys_arr      DD ?
kre_pages         DW ?
kre_usage         DW ?
kre_done          DW ?

kernel_req_entry  ENDS

kernel_wait_entry  STRUC

kwe_next          DD ?
kwe_pos           DD ?,?
kwe_thread        DW ?

kernel_wait_entry  ENDS

;
; must be 4 bytes!
;

kernel_mod_struc  STRUC

km_c_sel          DW ?
km_map_sel        DW ?

kernel_mod_struc  ENDS

kernel_file       STRUC

kf_blk            blk_header <>

kf_info_phys      DD ?,?
kf_info_linear    DD ?
kf_sector_size    DW ?
kf_section        section_typ <>
kf_update_section section_typ <>
kf_part_sel       DW ?
kf_req_sync       DW ?
kf_wait_thread    DW ?
kf_wr_ptr         DW ?
kf_c_handle       DW ?
kf_serv_handle    DD ?
kf_wait_list      DD ?

kf_wr_base        DD ?,?
kf_wr_size        DD ?

kf_mod_count      DD ?
kf_req_count      DD ?
kf_wait_count     DD ?
kf_block_count    DD ?
kf_phys_count     DD ?

kf_mod_arr        DD 64 DUP(?)
kf_sorted_arr     DB 256 DUP(?)
kf_handle_arr     DD 256 DUP(?)

kernel_file       ENDS

kernel_file_map   STRUC

kfm_flat_base     DD ?
kfm_user_base     DD ?
kfm_prog_sel      DW ?
kfm_file_sel      DW ?
kfm_kernel_sel    DW ?
kfm_handle        DW ?
kfm_ref_count     DW ?
kfm_section       section_typ <>
kfm_free_count    DB ?
kfm_unlink_count  DB ?
kfm_src_arr       DD 240 DUP(?)
kfm_ref_arr       DB 240 DUP(?)
kfm_free_arr      DB 240 DUP(?)
kfm_unlink_arr    DB 240 DUP(?)

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
    extern FileHandleToPartFs:near
    extern AllocateVfsHandle:near
    extern RefVfsHandle:near
    extern AllocateModHandle:near
    extern VfsRead:near
    extern VfsWrite:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CheckServ
;
;       DESCRIPTION:    Check server block consistency
;
;       PARAMETERS:     BX             Kernel file sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckServ   Proc near
    push ds
    pushad
;
    xor eax,eax
    xor edx,edx
;
    mov ds,bx
    mov ecx,ds:kf_req_count
    or ecx,ecx
    jz csDone
;
    mov esi,OFFSET kf_sorted_arr

csLoop:
    movzx ebx,ds:[esi]
    cmp bl,-1
    jne csCheck
;
    int 3
    jmp csDone

csCheck:
    mov ebx,ds:[4*ebx].kf_handle_arr
    mov edi,ds:[ebx].kre_pos
    mov ebp,ds:[ebx].kre_pos+4
    sub edi,eax
    mov ebp,edx
    jnc csNext
;
    int 3
    jmp csDone

csNext:
    mov eax,ds:[ebx].kre_pos
    mov edx,ds:[ebx].kre_pos+4
    add eax,ds:[ebx].kre_size
    adc edx,0
;
    inc esi
    loop csLoop

csDone:
    popad
    pop ds
    ret
CheckServ   Endp

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
;                       ESI                Block ptr
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BlockToPhys  Proc near
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
    ret
BlockToPhys  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetFileDebugInfo
;
;       DESCRIPTION:    Get file info
;
;       PARAMETERS:     DS             File sel
;
;       RETURNS:        EAX            Req count
;                       EBX            Wait count
;                       ECX            Block count
;                       EDX            Phys count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetFileDebugInfo

GetFileDebugInfo    Proc near
    mov eax,ds:kf_req_count
    mov ebx,ds:kf_wait_count
    mov ecx,ds:kf_block_count
    mov edx,ds:kf_phys_count
    ret
GetFileDebugInfo   Endp

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

GetFileSel      Proc near
    push fs
;
    call FileHandleToPartFs
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
;       PARAMETERS:     EBX            Serv handle
;                       EDX            File info linear
;                       DI             Sector size
;
;       RETURNS:        NC
;                         AX           File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateFileSel

CreateFileSel   Proc near
    push ds
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,8
    mov si,SIZE kernel_file
    CreateBlk
;
    InitSection ds:kf_section
    InitSection ds:kf_update_section
    mov ds:kf_sector_size,di
    mov ds:kf_part_sel,fs
    mov ds:kf_serv_handle,ebx
    mov ds:kf_wait_list,0
    mov ds:kf_req_sync,0
    mov ds:kf_wr_size,0

    mov ds:kf_req_count,0
    mov ds:kf_wait_count,0
    mov ds:kf_block_count,0
    mov ds:kf_phys_count,0
    mov ds:kf_wr_ptr,0
    mov ds:kf_c_handle,0
    mov ds:kf_mod_count,0
;
    mov ecx,256
    mov edi,OFFSET kf_handle_arr
    mov eax,-1

cfHandleInit:
    mov ds:[edi],eax
    add edi,4
    loop cfHandleInit
;
    mov ecx,256
    mov edi,OFFSET kf_sorted_arr
    mov eax,-1

cfSortedInit:
    mov ds:[edi],al
    inc edi
    loop cfSortedInit
;
    GetPageEntry
    or ax,800h
    SetPageEntry
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    and ax,NOT 800h
    SetPageEntry
;
    and ax,0F000h
    mov ds:kf_info_phys,eax
    mov ds:kf_info_phys+4,ebx
    mov ds:kf_info_linear,edx
;
    mov ax,ds
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
CreateFileSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloseFileSel
;
;       DESCRIPTION:    Close file selector
;
;       PARAMETERS:     FS             Part sel
                        AX             File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CloseFileSel

CloseFileSel   Proc near
    push ds
    push ecx
    push edx
;
    mov ds,ax
    mov edx,ds:kf_info_linear
    mov ecx,1000h
    FreeLinear
;
    DeleteBlk
;
    pop edx
    pop ecx
    pop ds
    ret
CloseFileSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddFileReq
;
;       DESCRIPTION:    Serv add VFS file req
;
;       PARAMETERS:     FS             Part sel
;                       EBX            File handle
;                       ESI            Req index
;                       EDX:EAX        Position
;                       ECX            Sector count
;
;       RETURNS:        ECX            Mapped sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddFileReq

AddFileReq   Proc near
    push ds
    push es
    push eax
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    mov di,flat_sel
    mov es,edi
;
    movzx edi,bx
    dec edi
    shl edi,2
    mov di,fs:[edi].vfsp_file_arr.ff_sel
    or di,di
    stc
    je afrDone
;
    or esi,esi
    stc
    jz afrDone
;
    mov ds,edi
    EnterSection ds:kf_section
;
    push eax
    push edx
;
    mov edi,ds:kf_info_linear
    mov eax,es:[edi].fi_bytes_per_sector       
    mul ecx
    mov ecx,eax
;
    pop edx
    pop eax
;
    push eax
    push ebx
    push edx
    push esi
;
    mov ebx,eax
    mov esi,edx
    mov eax,es:[edi].fi_fs_size
    mov edx,es:[edi].fi_fs_size+4
    sub eax,ebx
    sbb edx,esi
    jnc afrLower
;
    int 3
    xor ecx,ecx
    jmp afrRecalc

afrLower:
    or edx,edx
    jnz afrRecalc
;
    cmp eax,ecx
    jae afrRecalc
;
    mov ecx,eax

afrRecalc:
    mov eax,ecx
    xor edx,edx
    div es:[edi].fi_bytes_per_sector
    mov ecx,eax
;
    pop esi
    pop edx
    pop ebx
    pop eax
;
    push ecx
;
    or ecx,ecx
    stc
    jz afrLeave
;
    dec esi
;
    push ecx
    push edx
;
    inc ds:kf_req_count
    mov cx,SIZE kernel_req_entry
    AllocateBlk
    mov ds:[4*esi].kf_handle_arr,edx
    mov edi,edx
;
    pop edx
    pop ecx
;
    mov ds:[edi].kre_pos,eax
    mov ds:[edi].kre_pos+4,edx
    mov ds:[edi].kre_pages,0
    mov ds:[edi].kre_block_arr,0
    mov ds:[edi].kre_phys_arr,0
    mov ds:[edi].kre_usage,0
;
    push ds
    mov ds,fs:vfsp_disc_sel
    movzx eax,ds:vfs_bytes_per_sector
    pop ds
    mul ecx
    mov ds:[edi].kre_size,eax
    mov ds:[edi].kre_done,0
;
    mov ebx,OFFSET kf_sorted_arr
    mov ebp,ds:kf_req_count
    sub ebp,1
    jbe afrInsert
 
afrFind:
    movzx ecx,byte ptr ds:[ebx]
    mov ecx,ds:[4*ecx].kf_handle_arr
    mov eax,ds:[edi].kre_pos
    mov edx,ds:[edi].kre_pos+4
    sub eax,ds:[ecx].kre_pos
    sbb edx,ds:[ecx].kre_pos+4
    jb afrInsert
;
    inc ebx
    sub ebp,1
    jnz afrFind

afrInsert:
    sub ebx,OFFSET kf_sorted_arr
    mov eax,ebx
    mov ecx,ds:kf_req_count
    dec ecx
    sub ecx,eax
;
    mov ebx,esi
    lea esi,[eax+ecx].kf_sorted_arr
    mov edi,esi
    dec esi
    or ecx,ecx
    jz afrSave

afrMove:
    mov al,ds:[esi]
    mov ds:[edi],al
    dec esi
    dec edi
    loop afrMove

afrSave:
    mov ds:[edi],bl
    clc

afrLeave:
    pop ecx
    LeaveSection ds:kf_section

afrDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
AddFileReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindReq
;
;       DESCRIPTION:    Find a req. Section must be taken!
;
;       PARAMETERS:     DS             File sel
;                       EDX:EAX        Position
;
;       RETURNS:        EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindReq     Proc near
    push ecx
    push esi
    push edi
    push ebp
;
;    mov bx,ds
;    call CheckServ
;
    mov ebp,ds:kf_req_count
    or ebp,ebp
    stc
    jz frDone
;
    mov ebx,OFFSET kf_sorted_arr
 
frLoop:
    movzx ecx,byte ptr ds:[ebx]
    mov esi,eax
    mov edi,edx
    mov ecx,ds:[4*ecx].kf_handle_arr
    sub esi,ds:[ecx].kre_pos
    sbb edi,ds:[ecx].kre_pos+4
    jb frDone
    jnz frNext
;
    cmp esi,ds:[ecx].kre_size
    jae frNext
;
    movzx ebx,byte ptr ds:[ebx]
    clc
    jmp frDone

frNext:
    inc ebx
    sub ebp,1
    jnz frLoop
;
    stc

frDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
FindReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddWaitReq
;
;       DESCRIPTION:    Add wait req. Section must be taken!
;
;       PARAMETERS:     DS             File sel
;                       EDX:EAX        Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddWaitReq      Proc near
    push ecx
    push esi
;
    push eax
    push edx
;
    inc ds:kf_wait_count
    ClearSignal
    mov cx,SIZE kernel_wait_entry
    AllocateBlk
    mov esi,edx
;
    GetThread
    mov ds:[esi].kwe_thread,ax
;
    pop edx
    pop eax
;
    mov ds:[esi].kwe_pos,eax
    mov ds:[esi].kwe_pos+4,edx
;
    mov ecx,ds:kf_wait_list
    mov ds:[esi].kwe_next,ecx
    mov ds:kf_wait_list,esi
;
    pop esi
    pop ecx
    ret
AddWaitReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddReq
;
;       DESCRIPTION:    Add req
;
;       PARAMETERS:     DS             File sel
;                       EBX            OP
;                       EDX:EAX        Par64
;                       ECX            Par32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReq     Proc near
    push ds
    push es
    push ebx
    push esi
    push edi
;
    mov edi,ds:kf_serv_handle
    mov ds,ds:kf_part_sel
    EnterSection ds:vfsp_io_section

arRetry:
    push eax
    mov ax,ds:vfsp_io_sel
    or ax,ax
    jz arDone
;
    mov es,eax
    movzx esi,ds:vfsp_io_wr_ptr
    mov ax,es:[esi].fqe_op
    or ax,ax
    pop eax
    jz arRoom
;
    LeaveSection ds:vfsp_io_section
;
    mov ax,25
    WaitMilliSec
;
    EnterSection ds:vfsp_io_section
 
arRoom:
    mov es:[esi].fqe_p64,eax
    mov es:[esi].fqe_p64+4,edx
    mov es:[esi].fqe_p32,ecx
    mov es:[esi].fqe_handle,di
    mov es:[esi].fqe_op,bx
    add si,10h
    and si,0FFFh
    mov ds:vfsp_io_wr_ptr,si
;
    mov bx,ds:vfsp_io_thread
    or bx,bx
    jz arDone
;
    Signal

arDone:
    LeaveSection ds:vfsp_io_section
;
    pop edi
    pop esi
    pop ebx
    pop es
    pop ds
    ret
AddReq     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendCloseReq
;
;       DESCRIPTION:    Send close req
;
;       PARAMETERS:     DS             File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCloseReq     Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ecx,ds:kf_wr_size
    or ecx,ecx
    jz scrWrDone
;
    mov eax,ds:kf_wr_base
    mov edx,ds:kf_wr_base+4
    mov ebx,REQ_UPDATE
    call AddReq

scrWrDone:
    mov ebx,REQ_CLOSE
    call AddReq
;
    mov ebx,ds:kf_serv_handle
    mov fs,ds:kf_part_sel
    mov ds,fs:vfsp_disc_sel
    call AllocateMsg
    jc scrDone
;
    mov eax,VFS_CLOSE_FILE
    call RunMsg

scrDone:
    popad
    pop fs
    pop es
    pop ds
    ret
SendCloseReq     Endp

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
    push es
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    push esi
    push ecx
;
    mov ds,fs:vfsp_disc_sel
    mov bx,serv_flat_sel
    mov es,ebx
;
    xor ebx,ebx
    or ecx,ecx
    clc
    jz cpcDone
;
    inc ebx
;
    mov esi,[esp+4]
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
    mov esi,[esp+4]
    add esi,8
    mov [esp+4],esi
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
    pop esi
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop es
    pop ds
    ret
CalcPageCount  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetupReadReq
;
;       DESCRIPTION:    Setup read req
;
;       PARAMETERS:     DS                 File sel
;                       EBX                Req id
;                       AX                 Pages
;                       ECX                Blocks
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupReadReq   Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    shl ecx,9
    mov ebx,ds:[4*ebx].kf_handle_arr
;    mov ds:[ebx].kre_size,ecx
    mov ds:[ebx].kre_pages,ax
    inc ds:kf_block_count
    mov cx,ax
    shl cx,2
    AllocateBlk
    mov ds:[ebx].kre_block_arr,edx
;
    inc ds:kf_phys_count
    shl cx,1
    AllocateBlk
    mov ds:[ebx].kre_phys_arr,edx
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
SetupReadReq  Endp

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
;                       EBX                Req id
;                       ECX                Buffered blocks
;                       GS:ESI             Sector array
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessReadReq  Proc near
    push ds
    push es
    push fs
    pushad
;
    push esi
;
    push ds
    mov ds,fs:vfsp_disc_sel
    mov ax,serv_flat_sel
    mov es,eax
    pop fs
;
    mov ebx,fs:[4*ebx].kf_handle_arr
    mov edi,fs:[ebx].kre_block_arr
    mov ebp,fs:[ebx].kre_phys_arr
;
    mov esi,[esp]
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jnc prrSave
    jmp prrDone

prrLoop:
    sub ecx,1
    jz prrDone
;
    mov esi,[esp]
    add esi,8
    mov [esp],esi
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jc prrDone
;
    test eax,0FFFh
    jnz prrLoop

prrSave:
    mov fs:[ebp],eax
    mov fs:[ebp+4],edx
    add ebp,8
;
    mov fs:[edi],esi
    add edi,4
    jmp prrLoop

prrDone:
    pop esi
;
    popad
    pop fs
    pop es
    pop ds
    ret
ProcessReadReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SignalReadReq
;
;       DESCRIPTION:    Signal read req done
;
;       PARAMETERS:     DS                 File sel
;                       EDX:EAX            Position
;                       ECX                Size
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignalReadReq  Proc near
    push ebx
    push ecx
    push esi
    push edi
    push ebp
;
    xor esi,esi
    xchg esi,ds:kf_wait_list
    
srrLoop:
    or esi,esi
    jz srrDone
;
    mov edi,ds:[esi].kwe_pos
    mov ebp,ds:[esi].kwe_pos+4
    sub edi,eax
    sbb ebp,edx
    jc srrSkip
;
    or ebp,ebp
    jnz srrSkip
;
    cmp edi,ecx
    jae srrSkip
;
    mov bx,ds:[esi].kwe_thread
    Signal
;
    push ecx
    push edx
;
    mov edx,esi
    dec ds:kf_wait_count
    mov cx,SIZE kernel_wait_entry
    FreeBlk
;
    pop edx
    pop ecx
    jmp srrNext

srrSkip:
    mov ebp,ds:[esi].kwe_next
    mov edi,ds:kf_wait_list
    mov ds:[esi].kwe_next,edi
    mov ds:kf_wait_list,esi
    mov esi,ebp
    jmp srrLoop

srrNext:
    mov esi,ds:[esi].kwe_next
    jmp srrLoop

srrDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
SignalReadReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForReq
;
;       DESCRIPTION:    Wait for req
;
;       PARAMETERS:     FS             Kernel process sel
;                       GS             File sel
;                       EDX:EAX        Req position
;
;       RETURNS:        EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForReq      Proc near
    push ds
    push esi
    push edi
;
    mov esi,gs
    mov ds,esi
;
    EnterSection ds:kf_section
    call FindReq
    jnc wfrCheck
;
    call AddWaitReq
    LeaveSection ds:kf_section
;
    mov ebx,REQ_READ
    call AddReq
    call UpdateMap

wfrWait:
    WaitForSignal
;
    EnterSection ds:kf_section
    call FindReq
    jnc wfrCheck
;
    LeaveSection ds:kf_section
;
    push eax
    mov ax,20
    WaitMilliSec
    pop eax
    jmp wfrDone

wfrCheck:
    mov esi,ds:[4*ebx].kf_handle_arr
    mov esi,ds:[esi].kre_phys_arr
    or esi,esi
    jnz wfrLock
;
    call AddWaitReq
    LeaveSection ds:kf_section
    jmp wfrWait

wfrLock:
    mov esi,ds:[4*ebx].kf_handle_arr
;
    mov di,ds:[esi].kre_usage
    inc di
    mov ds:[esi].kre_usage,di
    sub di,1
    LeaveSection ds:kf_section
    clc
    jnz wfrDone
;
    push ebx
    mov cx,bx
    mov bx,REQ_MAP
    call AddReq
    pop ebx
    clc
    jmp wfrDone

wfrLeave:
    LeaveSection ds:kf_section

wfrDone:
    pop edi
    pop esi
    pop ds
    ret
WaitForReq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForGrow
;
;       DESCRIPTION:    Wait for grow
;
;       PARAMETERS:     FS             Kernel process sel
;                       GS             File sel
;                       EDX:EAX        Req position
;                       ECX            Increase
;
;       RETURNS:        EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForGrow      Proc near
    push ds
    push esi
    push edi
;
    mov esi,gs
    mov ds,esi
;
    push eax
    push edx
;
    add eax,ecx
    adc edx,0
;
    mov ebx,REQ_GROW
    call AddReq
;
    pop edx
    pop eax
;
    EnterSection ds:kf_section
    call FindReq
    jnc wfgCheck
;
    call AddWaitReq
    LeaveSection ds:kf_section
;
    call UpdateMap

wfgWait:
    WaitForSignal
;
    EnterSection ds:kf_section
    call FindReq
    jnc wfgCheck
;
    LeaveSection ds:kf_section
;
    push eax
    mov ax,20
    WaitMilliSec
    pop eax
    jmp wfgDone

wfgCheck:
    mov esi,ds:[4*ebx].kf_handle_arr
    mov esi,ds:[esi].kre_phys_arr
    or esi,esi
    jnz wfgLock
;
    call AddWaitReq
    LeaveSection ds:kf_section
    jmp wfgWait

wfgLock:
    mov esi,ds:[4*ebx].kf_handle_arr
;
    mov di,ds:[esi].kre_usage
    inc di
    mov ds:[esi].kre_usage,di
    sub di,1
    LeaveSection ds:kf_section
    clc
    jnz wfgDone
;
    push ebx
    mov cx,bx
    mov bx,REQ_MAP
    call AddReq
    pop ebx
    clc
    jmp wfgDone

wfgLeave:
    LeaveSection ds:kf_section

wfgDone:
    pop edi
    pop esi
    pop ds
    ret
WaitForGrow    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeReq
;
;       DESCRIPTION:    Free req
;
;       PARAMETERS:     GS             File sel
;                       EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeReq      Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
;    push ebx
;    mov ebx,gs
;    call CheckServ
;    pop ebx
;
    mov esi,gs
    mov ds,esi
    EnterSection ds:kf_section
;
    mov esi,ds:[4*ebx].kf_handle_arr
    sub ds:[esi].kre_usage,1
    jnz frLeave
;
    mov al,bl
    mov esi,OFFSET kf_sorted_arr
    mov ecx,ds:kf_req_count

frFind:
    cmp al,ds:[esi]
    je frMove
;
    inc esi
    loop frFind
;
    jmp frLeave

frMove:
    mov al,ds:[esi+1]
    mov ds:[esi],al
    inc esi
    loop frMove
;
    dec ds:kf_req_count
    LeaveSection ds:kf_section
;
    push ebx
    mov cx,bx
    mov bx,REQ_FREE
    call AddReq
;
;    mov bx,ds
;    call CheckServ
    pop ebx
    jmp frEnd

frLeave:
    LeaveSection ds:kf_section

frEnd:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
FreeReq      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockMap
;
;       DESCRIPTION:    Lock map
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockMap     Proc near
    push es
    push eax
    push ebx
;
    mov ebx,es:fm_handle_ptr
    add ebx,OFFSET fh_futex
    mov ax,flat_data_sel
    mov es,eax
;    
    str ax
    cmp ax,es:[ebx].fs_owner
    jne lmLock
;
    inc es:[ebx].fs_counter
    jmp lmDone

lmLock:
    lock add es:[ebx].fs_val,1
    jc lmTake
;
    mov eax,1
    xchg ax,es:[ebx].fs_val
    cmp ax,-1
    jne lmBlock

lmTake:
    str ax
    mov es:[ebx].fs_owner,ax
    mov es:[ebx].fs_counter,1
    jmp lmDone

lmBlock:
    push edi
    mov edi,es:[ebx].fs_sect_name
    AcquireNamedFutex
    pop edi

lmDone:
    pop ebx
    pop eax
    pop es
    ret
LockMap     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockMap
;
;       DESCRIPTION:    Unlock map
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockMap     Proc near
    push es
    push eax
    push ebx
;
    mov ebx,es:fm_handle_ptr
    add ebx,OFFSET fh_futex
    mov ax,flat_data_sel
    mov es,eax
;
    str ax
    cmp ax,es:[ebx].fs_owner
    jne umDone
;
    sub es:[ebx].fs_counter,1
    jnz umDone
;
    mov es:[ebx].fs_owner,0
    lock sub es:[ebx].fs_val,1
    jc umDone
;
    mov es:[ebx].fs_val,-1
    ReleaseFutex

umDone:
    pop ebx
    pop eax
    pop es
    ret
UnlockMap     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindReadMap
;
;       DESCRIPTION:    Find a read map
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;                       EDX:EAX        Position
;
;       RETURNS:        EBX            Req offset
;                       ECX            Sort index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindReadMap     Proc near
    push esi
    push edi
    push ebp
;
    mov ebp,es:fm_count
    or ebp,ebp
    stc
    jz frmDone
;
    mov ebx,OFFSET fm_sorted_arr
 
frmLoop:
    movzx ecx,byte ptr es:[ebx]
    shl ecx,4
    mov esi,eax
    mov edi,edx
    sub esi,es:[ecx].fm_entry_arr.fmb_pos
    sbb edi,es:[ecx].fm_entry_arr.fmb_pos+4
    jb frmDone
    jnz frmNext
;
    cmp esi,es:[ecx].fm_entry_arr.fmb_size
    jae frmNext
;
    xchg ebx,ecx
    clc
    jmp frmDone

frmNext:
    inc ebx
    sub ebp,1
    jnz frmLoop
;
    stc

frmDone:
    pop ebp
    pop edi
    pop esi
    ret
FindReadMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateMapEntry
;
;       DESCRIPTION:    Add read map entry
;
;       PARAMETERS:     DS             Kernel processes
;                       EDI            Req id            
;
;       RETURNS:        BX             Entry offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateMapEntry      Proc near
    movzx ebx,ds:kfm_free_count
    or bx,bx
    stc
    je ameDone
;
    inc es:fm_count
    dec bx
    mov ds:kfm_free_count,bl
    mov bl,ds:[bx].kfm_free_arr
    mov ds:[ebx].kfm_ref_arr,1
    mov ds:[4*ebx].kfm_src_arr,edi
    shl bx,4
    add bx,OFFSET fm_entry_arr
    clc

ameDone:
    ret
AllocateMapEntry      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapEntry
;
;       DESCRIPTION:    Map entry
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;                       GS:ESI         Physical address buffer
;                       BX             Entry offset
;                       ECX            Pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapEntry      Proc near
    push eax
    push ecx
    push edx
    push edi
;
    mov eax,ecx
    shl eax,12
    AllocateLocalLinear
;
    push ebx
    push edx
    push esi
;
    mov eax,gs:[esi]
    test eax,0FFFh
    jz meUser

meKernel:
    mov di,803h
    jmp meLoop

meUser:
    mov di,807h

meLoop:
    mov eax,gs:[esi]
    mov ebx,gs:[esi+4]
    and ax,0F000h
    or ax,di
    SetPageEntry
;
    add edx,1000h
    add esi,8
    loop meLoop
;
    pop esi
    pop edx
    pop ebx
;
    sub edx,ds:kfm_flat_base
    mov eax,gs:[esi]
    and ax,0FFFh
    or dx,ax
    mov es:[ebx].fmb_base,edx
;
    pop edi
    pop edx
    pop ecx
    pop eax
    ret
MapEntry      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddReadMap
;
;       DESCRIPTION:    Add read map
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;                       BX             Entry offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReadMap      Proc near
    pushad
;
    movzx esi,bx
    mov ebx,OFFSET fm_sorted_arr
    mov ebp,es:fm_count
    sub ebp,1
    jbe armInsert
 
armFind:
    movzx ecx,byte ptr es:[ebx]
    shl ecx,4
    mov eax,es:[esi].fmb_pos
    mov edx,es:[esi].fmb_pos+4
    sub eax,es:[ecx].fm_entry_arr.fmb_pos
    sbb edx,es:[ecx].fm_entry_arr.fmb_pos+4
    jb armInsert
    jnz armNext
;
    cmp eax,ds:[ecx].fm_entry_arr.fmb_size
    jb armInsert

armNext:
    inc ebx
    sub ebp,1
    jnz armFind

armInsert:
    sub ebx,OFFSET fm_sorted_arr
    mov eax,ebx
    mov ecx,es:fm_count
    dec ecx
    sub ecx,eax
;
    mov ebx,esi
    sub ebx,OFFSET fm_entry_arr
    shr ebx,4
    lea esi,[eax+ecx].fm_sorted_arr
    mov edi,esi
    dec esi
    or ecx,ecx
    jz armSave

armMove:
    mov al,es:[esi]
    mov es:[edi],al
    dec esi
    dec edi
    loop armMove

armSave:
    mov es:[edi],bl
    clc

armDone:
    popad
    ret
AddReadMap      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeMap
;
;       DESCRIPTION:    Free map
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;                       BX             Sorted index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeMap  Proc near
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    movzx ebx,bx
    mov ecx,es:fm_count
    sub ecx,ebx
    inc ecx
    mov al,es:[ebx]

fmLoop:
    mov ah,es:[ebx+1]
    mov es:[ebx],ah
    inc ebx
    loop fmLoop
;
    dec es:fm_count
    movzx bx,ds:kfm_unlink_count
    mov ds:[bx].kfm_unlink_arr,al
    inc bl
    mov ds:kfm_unlink_count,bl
;
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
FreeMap Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateFile
;
;       DESCRIPTION:    Update file
;
;       PARAMETERS:     DS             File req
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateFile      Proc near
    push ds
    push ebx
    push esi
;
    call SyncFileSize
;
    mov ds,ds:kfm_file_sel
    EnterSection ds:kf_update_section
;
    mov ebx,ds:kf_wr_size
    or ebx,ebx
    jz ufNew

ufAdd:
    push eax
    push edx
;
    sub eax,ebx
    sbb edx,0
    cmp eax,ds:kf_wr_base
    jne ufSend
;
    cmp edx,ds:kf_wr_base+4
    jne ufSend
;
    pop edx
    pop eax
    add ds:kf_wr_size,ecx    
    jmp ufLeave

ufSend:
    mov ebx,REQ_UPDATE
    call AddReq
;
    pop edx
    pop eax

ufNew:
    mov ds:kf_wr_base,eax
    mov ds:kf_wr_base+4,edx
    mov ds:kf_wr_size,ecx

ufLeave:
    LeaveSection ds:kf_update_section
;
    pop esi
    pop ebx
    pop ds
    ret
UpdateFile      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddDirtyMap
;
;       DESCRIPTION:    Signal written page
;
;       PARAMETERS:     DS             File sel
;                       ES:EDI         Req entry
;                       BX             Sorted index
;                       EDX            Linea address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDirtyMap  Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov ecx,es:[edi].fmb_size
    test cx,0FFFh
    jnz admDone
;
    mov eax,es:[edi].fmb_base
    test ax,0FFFh
    jnz admDone
;
    sub edx,es:[edi].fmb_base
    mov eax,es:[edi].fmb_pos
    add eax,edx
    mov edx,es:[edi].fmb_pos+4
    adc edx,0
    mov ecx,1000h
    call UpdateFile

admDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AddDirtyMap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CheckDirtyMap
;
;       DESCRIPTION:    Check map for written pages
;
;       PARAMETERS:     DS:ESI         Reference
;                       ES:EDI         Req entry
;                       BX             Sorted index
;
;       RETURNS:        AX             Page bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDirtyMap  Proc near
    push ebx
    push ecx
    push edx
    push ebp
;
    xor bp,bp
    mov ecx,es:[edi].fmb_size
    mov edx,es:[edi].fmb_base
    add ecx,edx
    and dx,0F000h
    sub ecx,edx
    dec ecx
    shr ecx,12
    inc ecx
    add edx,ds:kfm_flat_base

cdmLoop:
    GetPageEntry
    test ax,60h
    jz cdmNext
;
    test al,40h
    jz cdmClear
;
    call AddDirtyMap

cdmClear:
    or bp,ax
    and al,NOT 60h
    SetPageEntry

cdmNext:
    add edx,1000h
    loop cdmLoop
;
    mov ax,bp
    and al,60h
;
    pop ebp
    pop edx
    pop ecx
    pop ebx
    ret
CheckDirtyMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CheckMap
;
;       DESCRIPTION:    Check map
;
;       PARAMETERS:     DS:ESI         Reference
;                       ES:EDI         Req entry
;                       BX             Sorted index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckMap  Proc near
    push eax
;
    call CheckDirtyMap
;
    test al,20h
    jz cmNone
;
    add byte ptr ds:[esi],1
    jnc cmDone
;
    dec byte ptr ds:[esi]
    jmp cmDone

cmNone:
    mov al,ds:[esi]
    or al,al
    jz cmFree
;
    sub byte ptr ds:[esi],1
    jnz cmDone

cmFree:
    call FreeMap

cmDone:
    pop eax
    ret
CheckMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlinkLinear
;
;       DESCRIPTION:    Unlink linear address
;
;       PARAMETERS:     ES             Kernel mapping sel
;                       AL             Entry #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkLinear  Proc near
    push ecx
    push edx
    push esi
;
    movzx esi,al
    shl esi,4
    add esi,OFFSET fm_entry_arr
    xor edx,edx
    xchg edx,es:[esi].fmb_base
    or edx,edx
    jz ulDone
;
    add edx,ds:kfm_flat_base
    mov ecx,edx
    add ecx,es:[esi].fmb_size
    dec ecx
    shr ecx,12
    inc ecx
    shl ecx,12
    shr edx,12
    shl edx,12
    sub ecx,edx
    FreeLinear

ulDone:
    pop esi
    pop edx
    pop ecx
    ret
UnlinkLinear   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlinkedMap
;
;       DESCRIPTION:    Unlink entries
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;                       FS             User flat sel
;                       GS             File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkMap  Proc near
    push ebx
    push ecx
    push edx
;
    movzx ecx,ds:kfm_unlink_count
    mov ebx,OFFSET kfm_unlink_arr

urmLoop:
    mov al,ds:[ebx]
    call UnlinkLinear
;
    push ebx
    movzx ebx,al
    mov ebx,ds:[4*ebx].kfm_src_arr
    call FreeReq
    pop ebx
;
    movzx edx,ds:kfm_free_count
    mov ds:[edx].kfm_free_arr,al
    inc dl
    mov ds:kfm_free_count,dl

    inc ebx
    loop urmLoop
;
    mov ds:kfm_unlink_count,0
;
    pop edx
    pop ecx
    pop ebx
    ret
UnlinkMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateUnlinked
;
;       DESCRIPTION:    Update unlinked entries
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;                       GS             File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateUnlinked  Proc near
    push eax
;
    movzx eax,ds:kfm_unlink_count
    or eax,eax
    jz uuDone
;
    push fs
    push ebx
;
    mov ax,flat_data_sel
    mov fs,eax
    mov ebx,es:fm_handle_ptr
    mov ax,fs:[ebx].fh_futex.fs_owner
    or ax,ax
    jnz uuPop
;
    call UnlinkMap

uuPop:
    pop ebx
    pop fs
    
uuDone:
    pop eax
    ret
UpdateUnlinked Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SyncFileSize
;
;       DESCRIPTION:    Sync file size from userspace
;
;       PARAMETERS:     DS              Mod sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SyncFileSize      Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    mov bx,flat_data_sel
    mov es,ebx
    mov edx,ds:kfm_user_base
    mov edx,es:[edx].fm_handle_ptr
    mov eax,es:[edx].fh_req_size    
    mov edx,es:[edx].fh_req_size+4
;
    mov bx,flat_sel
    mov es,ebx
    mov ds,ds:kfm_file_sel
    mov esi,ds:kf_info_linear
    mov ebx,es:[esi].fi_size
    sub ebx,eax
    mov ebx,es:[esi].fi_size+4
    sbb ebx,edx
    jnc sfsDone
;
    mov es:[esi].fi_size,eax
    mov es:[esi].fi_size+4,edx

sfsDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
SyncFileSize      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendUpdate
;
;       DESCRIPTION:    Send update
;
;       PARAMETERS:     DS             Module sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendUpdate  Proc near
    push ds
    push ecx
;
    call SyncFileSize
;
    mov ds,ds:kfm_file_sel
    EnterSection ds:kf_update_section
;
    xor ecx,ecx
    xchg ecx,ds:kf_wr_size
    or ecx,ecx
    jz suLeave
;
    push eax
    push ebx
    push edx
;
    mov eax,ds:kf_wr_base
    mov edx,ds:kf_wr_base+4
    mov ebx,REQ_UPDATE
    call AddReq
;
    pop edx
    pop ebx
    pop eax
    
suLeave:
    LeaveSection ds:kf_update_section
;
    pop ecx
    pop ds
    ret
SendUpdate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateMap
;
;       DESCRIPTION:    Update map requests
;
;       PARAMETERS:     FS             Kernel processes
;                       GS             File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMap  Proc near
    push ds
    push es
    pushad
;
    mov eax,fs
    mov ds,eax
    mov es,ds:kfm_kernel_sel
    mov ebx,OFFSET fm_sorted_arr
    mov ecx,es:fm_count
    EnterSection ds:kfm_section
    or ecx,ecx
    jz umLeave

umLoop:
    mov al,es:[ebx]
    cmp al,-1
    je umLeave
;
    movzx esi,al
    add esi,OFFSET kfm_ref_arr
    movzx edi,al
    shl edi,4
    add edi,OFFSET fm_entry_arr
    call CheckMap

umNext:
    inc ebx
    loop umLoop

umLeave:
    call UpdateUnlinked
;
    LeaveSection ds:kfm_section
;
    call SendUpdate
;
    popad
    pop es
    pop ds
    ret
UpdateMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SyncMap
;
;       DESCRIPTION:    Sync map from file sel
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;                       GS             File sel
;                       EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SyncMap  Proc near
    pushad
;
    mov edi,ebx
    mov ebx,gs:[4*ebx].kf_handle_arr
    mov eax,gs:[ebx].kre_pos
    mov edx,gs:[ebx].kre_pos+4
    mov ecx,gs:[ebx].kre_size
;
    mov esi,gs:[ebx].kre_phys_arr
    movzx ebp,gs:[ebx].kre_pages
;
    EnterSection ds:kfm_section
;
    push ecx
    call FindReadMap
    pop ecx
    jc smAdd
;
    mov edi,gs:[4*edi].kf_handle_arr
    dec gs:[edi].kre_usage
    stc
    jmp smLeave

smAdd:
    call AllocateMapEntry
    mov es:[bx].fmb_pos,eax
    mov es:[bx].fmb_pos+4,edx
    mov es:[bx].fmb_size,ecx
;
    mov ecx,ebp
    call MapEntry
    call AddReadMap
    clc

smLeave:
    LeaveSection ds:kfm_section
;
    popad
    ret
SyncMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteMap
;
;       DESCRIPTION:    Delete all mapped requests
;
;       PARAMETERS:     DS             Mod sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteMap  Proc near
    push es
    push gs
    pushad
;
    mov es,ds:kfm_kernel_sel
    mov gs,ds:kfm_file_sel
    mov ebx,OFFSET fm_sorted_arr
    mov ecx,240
    EnterSection ds:kfm_section

dmLoop:
    mov al,es:[ebx]
    cmp al,-1
    je dmLeave
;
    movzx esi,al
    add esi,OFFSET kfm_ref_arr
    movzx edi,al
    shl edi,4
    add edi,OFFSET fm_entry_arr    
    call CheckDirtyMap
    call FreeMap
    jmp dmLoop

dmNext:
    inc ebx
    loop dmLoop

dmLeave:
    call UpdateUnlinked
;
    LeaveSection ds:kfm_section
;
    popad
    pop gs
    pop es
    ret
DeleteMap  Endp

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

NotifyFileData  Proc near
    push ds
    push fs
    push gs
    pushad
;
    mov ebx,gs:vfs_rd_file_handle
    call FileHandleToPartFs
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
    stc
    jz nfdDone
;
    mov ds,ebx
    mov ebx,gs:vfs_rd_index
    or ebx,ebx
    stc
    je nfdDone
;
    EnterSection ds:kf_section
;
    dec ebx
    mov esi,ds:[4*ebx].kf_handle_arr
    mov ax,1
    xchg ax,ds:[esi].kre_done
    or ax,ax
    jne nfdLeave
;
    mov esi,gs:vfs_rd_chain_ptr
    call CalcPageCount
    call SetupReadReq
    call ProcessReadReq
;
    push ebx
    mov cx,bx
    mov bx,REQ_COMPLETED
    call AddReq
    pop ebx

nfdSignal:
    mov esi,ds:[4*ebx].kf_handle_arr
    mov eax,ds:[esi].kre_pos
    mov edx,ds:[esi].kre_pos+4
    mov ecx,ds:[esi].kre_size
    call SignalReadReq

nfdLeave:
    LeaveSection ds:kf_section
    clc

nfdDone:
    popad
    pop gs
    pop fs
    pop ds
    ret
NotifyFileData  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyFileSignal
;
;       DESCRIPTION:    Notify file signal
;
;       PARAMETERS:     FS             Partition
;                       EBX            File handle
;                       EDX:EAX        Position
;                       ECX            Size
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NotifyFileSignal

NotifyFileSignal  Proc near
    push ds
    push ebx
;
    movzx ebx,bx
    dec ebx
    shl ebx,2
    mov bx,fs:[ebx].vfsp_file_arr.ff_sel
    or bx,bx
    stc
    je nfdDone
;
    mov ds,ebx
    EnterSection ds:kf_section
    call SignalReadReq
    LeaveSection ds:kf_section

nfsDone:
    pop ebx
    pop ds
    ret
NotifyFileSignal  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeFileReq
;
;       DESCRIPTION:    Free file req
;
;       PARAMETERS:     DS                 File sel
;                       FS                 Part sel                       
;                       EDX                Req id
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeFileReq

FreeFileReq  Proc near
    push es
    push gs
    pushad
;    
    mov ebx,ds:[4*edx].kf_handle_arr
    mov ecx,ds:[ebx].kre_size
;    
    mov ax,serv_flat_sel
    mov es,eax
    mov gs,fs:vfsp_disc_sel
;
    mov ebp,ebx
    or ecx,ecx
    jz ffrReq
;
    mov edi,ds:[ebx].kre_block_arr
    mov edx,ds:[ebx].kre_phys_arr
    mov edx,ds:[edx]
    and edx,0FFFh
    shr edx,9
    mov eax,8
    sub eax,edx

ffrFreeLoop:
    shl eax,9
    cmp ecx,eax
    jae ffrFreeAll
;
    mov eax,ecx

ffrFreeAll:
    sub ecx,eax
    shr eax,9
;    
    mov esi,ds:[edi]
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz ffrFreeNext
;
    sub es:[esi].vfsp_ref_bitmap,ax
    jnc ffrOk
;
    int 3

ffrOk:
    jnz ffrFreeNext
;
    dec gs:vfs_locked_pages

ffrFreeNext:
    or ecx,ecx
    jz ffrFreeEntry
;
    add edi,4
    mov eax,8
    jmp ffrFreeLoop

ffrFreeEntry:
    mov ebx,ebp
    mov cx,ds:[ebx].kre_pages
    dec ds:kf_block_count
    shl cx,2
    mov edx,ds:[ebx].kre_block_arr
    FreeBlk
;
    dec ds:kf_phys_count
    shl cx,1
    mov edx,ds:[ebx].kre_phys_arr
    FreeBlk

ffrReq:
    mov edx,ebp
    mov cx,SIZE kernel_req_entry
    FreeBlk

ffrDone:
    popad
    pop gs
    pop es
    ret
FreeFileReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindVfsMod
;
;       DESCRIPTION:    Find VFS module
;
;       PARAMETERS:     DS              File sel
;
;       RETURNS:        NC
;                         AX            Map sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindVfsMod      Proc near
    push es
    push ebx
    push ecx
;
    GetThread
    mov es,ax
    mov es,es:p_proc_sel
    mov ax,es:pf_c_handle_sel
;
    mov ebx,OFFSET kf_mod_arr
    mov ecx,ds:kf_mod_count
    or ecx,ecx
    stc
    jz fvmDone

fvmLoop:
    cmp ax,ds:[ebx].km_c_sel
    je fvmFound
;
    add ebx,4
    loop fvmLoop
;
    stc
    jmp fvmDone

fvmFound:
    mov ax,ds:[ebx].km_map_sel
    clc

fvmDone:
    pop ecx
    pop ebx
    pop es
    ret
FindVfsMod    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddVfsMod
;
;       DESCRIPTION:    Add VFS module
;
;       PARAMETERS:     DS              File sel
;                       AX              Map sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddVfsMod      Proc near
    push eax
    push ebx
;
    mov ebx,ds:kf_mod_count
    shl ebx,2
    add ebx,OFFSET kf_mod_arr
    mov ds:[ebx].km_map_sel,ax
;
    push ds
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ax,ds:pf_c_handle_sel
;
    pop ds
;
    mov ds:[ebx].km_c_sel,ax
    inc ds:kf_mod_count
;
    pop ebx
    pop eax
    ret
AddVfsMod    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RemoveVfsMod
;
;       DESCRIPTION:    Remove VFS module
;
;       PARAMETERS:     DS              File sel
;                       AX              Map sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveVfsMod      Proc near
    push eax
    push ebx
    push ecx
;
    mov ebx,OFFSET kf_mod_arr
    mov ecx,ds:kf_mod_count
    or ecx,ecx
    jnz rvmLoop
;
    int 3
    jmp rvmDone

rvmLoop:
    cmp ax,ds:[ebx].km_map_sel
    je rvmFound
;
    add ebx,4
    loop rvmLoop
;
    int 3
    jmp rvmDone

rvmFound:
    mov eax,ds:[ebx+4]
    mov ds:[ebx],eax
    add ebx,4
    loop rvmFound
;
    dec ds:kf_mod_count

rvmDone:
    pop ecx
    pop ebx
    pop eax
    ret
RemoveVfsMod      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateVfsMod
;
;       DESCRIPTION:    Create VFS module sel
;
;       PARAMETERS:     DS              File sel
;
;       RETURNS:        NC
;                         AX            mod sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateVfsMod   Proc near
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
;
    mov eax,-1
    mov ecx,3Dh
    rep stosd
;
    xor eax,eax
    mov ecx,7C3h
    rep stosd
;
    mov eax,edx
    add eax,1000h
    mov es:[edx].fm_handle_ptr,eax
    add eax,1000h
    mov es:[edx].fm_info_ptr,eax
;
    mov ax,flat_data_sel
    mov es,eax
    mov eax,edx
    add eax,1000h
    mov ecx,eax
    add eax,OFFSET fh_futex
    mov es:[eax].fs_handle,0
    mov es:[eax].fs_val,-1
    mov es:[eax].fs_counter,0
    mov es:[eax].fs_owner,0
    add ecx,1000h
    add ecx,OFFSET fi_name
    mov es:[eax].fs_sect_name,ecx
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
    or ax,867h
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
    shr ecx,1
    rep stosw
;
    mov ecx,240
    mov es:kfm_free_count,cl
;
    mov edi,OFFSET kfm_free_arr
    mov al,cl
    dec al

cvmsLoop:
    stosb
    dec al
    loop cvmsLoop
;
    mov es:kfm_flat_base,ebx
    mov es:kfm_user_base,edx
    mov es:kfm_prog_sel,si
    mov es:kfm_file_sel,ds
    mov es:kfm_handle,0
    mov es:kfm_ref_count,0
;
    AllocateGdt
    mov ecx,1000h
    mov edx,ebp
    CreateDataSelector32
    mov es:kfm_kernel_sel,bx
    mov eax,es
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CreateVfsMod      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteVfsMod
;
;       DESCRIPTION:    Delete VFS module sel
;
;       PARAMETERS:     AX              Mod sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteVfsMod   Proc near
    push ds
    push es
    push fs
    push eax
    push ebx
    push ecx
    push edx
;
    push eax
;
    mov ds,eax
    mov ds,ds:kfm_kernel_sel
    mov ax,flat_data_sel
    mov es,eax
    mov ebx,ds:fm_handle_ptr
    add ebx,OFFSET fh_futex
    mov eax,es:[ebx].fs_handle
    or eax,eax
    jz dpsPop
;
    CleanupFutex

dpsPop:
    pop ds
;
    mov es,ds:kfm_kernel_sel
    FreeMem
;
    mov eax,ds
    mov es,eax
;
    xor eax,eax
    mov ds,eax
;
    mov edx,es:kfm_user_base
    add edx,es:kfm_flat_base
    mov ecx,3000h
    FreeLinear
;
    FreeMem
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
DeleteVfsMod      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateUserHandle
;
;       DESCRIPTION:    Allocate user handle
;
;       PARAMETERS:     AX              Mod sel
;
;       RETURNS:        NC
;                         DX            User handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateUserHandle      Proc near
    push ds
    push es
    push eax
    push ebx
    push ecx
    push esi
;
    mov ds,eax
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
    add edx,OFFSET fh_pos_arr
    xor eax,eax
    mov es:[edx],eax
    add edx,4
    mov es:[edx],eax
;
    inc ebx
    mov edx,ebx
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
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
AllocateUserHandle      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeUserHandle
;
;       DESCRIPTION:    Free user handle
;
;       PARAMETERS:     AX              Mod sel
;                       BX              Handle    
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeUserHandle

FreeUserHandle      Proc near
    push ds
    push es
    push edx
;
    or bx,bx
    jz fuhDone
;
    mov ds,eax
    mov dx,flat_data_sel
    mov es,edx
    mov edx,ds:kfm_user_base
    mov edx,es:[edx].fm_handle_ptr
    add edx,OFFSET fh_bitmap
;
    dec bx
    movzx ebx,bx
    lock btc es:[edx],ebx
    jc fuhDone
;
    int 3

fuhDone:
    pop edx
    pop es
    pop ds
    ret
FreeUserHandle      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockMod
;
;       DESCRIPTION:    Lock mod
;
;       PARAMETERS:     FS:ESI          User map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LockMod_

LockMod_      Proc near
    push es
    push eax
    push ebx
;
    mov ebx,fs:[esi].fm_handle_ptr
    add ebx,OFFSET fh_futex
    mov ax,flat_data_sel
    mov es,eax
;    
    str ax
    cmp ax,es:[ebx].fs_owner
    jne lmmLock
;
    inc es:[ebx].fs_counter
    jmp lmmDone

lmmLock:
    lock add es:[ebx].fs_val,1
    jc lmmTake
;
    mov eax,1
    xchg ax,es:[ebx].fs_val
    cmp ax,-1
    jne lmmBlock

lmmTake:
    str ax
    mov es:[ebx].fs_owner,ax
    mov es:[ebx].fs_counter,1
    jmp lmmDone

lmmBlock:
    push edi
    mov edi,es:[ebx].fs_sect_name
    AcquireNamedFutex
    pop edi

lmmDone:
    pop ebx
    pop eax
    pop es
    ret
LockMod_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockMod
;
;       DESCRIPTION:    Inlock mod
;
;       PARAMETERS:     FS:ESI          User map
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UnlockMod_

UnlockMod_      Proc near
    push es
    push eax
    push ebx
;
    mov ebx,fs:[esi].fm_handle_ptr
    add ebx,OFFSET fh_futex
    mov ax,flat_data_sel
    mov es,eax
;
    str ax
    cmp ax,es:[ebx].fs_owner
    jne ummDone
;
    sub es:[ebx].fs_counter,1
    jnz ummDone
;
    mov es:[ebx].fs_owner,0
    lock sub es:[ebx].fs_val,1
    jc ummDone
;
    mov es:[ebx].fs_val,-1
    ReleaseFutex

ummDone:
    pop ebx
    pop eax
    pop es
    ret
UnlockMod_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsFileInfo
;
;       DESCRIPTION:    Get VFS file info
;
;       PARAMETERS:     BX             Mod sel
;
;       RETURNS:        EDI            File info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetVfsFileInfo

GetVfsFileInfo     Proc near
    push ds
    mov ds,ebx
    mov edi,ds:kfm_user_base
    pop ds
    ret
GetVfsFileInfo    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapVfsFile
;
;       DESCRIPTION:    Map VFS file
;
;       PARAMETERS:     ESI            Handle (high) + Mod sel (low)
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public MapVfsFile_

MapVfsFile_      Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ds,esi
    mov fs,esi
    shr esi,16
    mov bx,si
;
    mov es,ds:kfm_kernel_sel
    mov gs,ds:kfm_file_sel
;
    call WaitForReq
    jc mcvfDone
;
    call LockMap
    call SyncMap
    pushf
    call UnlockMap
    popf

mcvfDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
MapVfsFile_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GrowVfsFile
;
;       DESCRIPTION:    Grow VFS file
;
;       PARAMETERS:     ESI            Handle (high) + Mod sel (low)
;                       EDX:EAX        Current size
;                       ECX            Increase
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GrowVfsFile_

GrowVfsFile_      Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ds,esi
    mov fs,esi
    shr esi,16
    mov bx,si
;
    mov es,ds:kfm_kernel_sel
    mov gs,ds:kfm_file_sel
;
    call WaitForGrow
    jc gvfsDone
;
    call LockMap
    call SyncMap
    pushf
    call UnlockMap
    popf

gvfsDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
GrowVfsFile_      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateVfsFile
;
;       DESCRIPTION:    Update VFS file
;
;       PARAMETERS:     ESI            Handle (high) + Mod sel (low)
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UpdateVfsFile_

UpdateVfsFile_      Proc near
    push ds
    mov ds,si
    call UpdateFile
    pop ds
    ret
UpdateVfsFile_      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloseVfsMod
;
;       DESCRIPTION:    Close VFS module sel
;
;       PARAMETERS:     AX            Mod sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CloseVfsMod

CloseVfsMod   Proc near
    push ds
;
    mov ds,eax
    call SyncFileSize
;
    sub ds:kfm_ref_count,1
    jnz cvmDone
;
    call DeleteMap
;
    mov ds,ds:kfm_file_sel
    call RemoveVfsMod
;
    call DeleteVfsMod

cvmDone:
    pop ds
    ret
CloseVfsMod   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenVfsFile
;
;           DESCRIPTION:    Open VFS file
;
;           PARAMETERS:     ES:EDI      Filename
;                           CX          Mode
;                           
;           RETURNS:        BX          File handle entry
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OpenVfsFile

OpenVfsFile    Proc near
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
    push ecx
    xor ecx,ecx
    movzx eax,ax
    call AllocateMsg
    pop ecx
    jc ovfFail

ovfCopyPath:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz ovfCopyPath
;
    test cx,O_CREAT
    jz ovfOpen

ovfCreate:
    push ecx
    mov eax,VFS_CREATE_FILE
    call RunMsg
    pop ecx
    jnc ovfFound
    jmp ovfFail

ovfOpen:
    push ecx
    mov eax,VFS_OPEN_FILE
    call RunMsg
    pop ecx
    jc ovfFail

ovfFound:
    call GetFileSel
    jc ovfFail
;
    mov ds,eax
    EnterSection ds:kf_section
;
    mov bx,ds:kf_c_handle
    or bx,bx
    jz ovfNew
;
    call RefVfsHandle
    jmp ovfHandleOk

ovfNew:
    call AllocateVfsHandle
    mov ds:kf_c_handle,bx

ovfHandleOk:
    call FindVfsMod
    jnc ovfModOk
;
    call CreateVfsMod
    call AddVfsMod

ovfModOk:
    LeaveSection ds:kf_section
;
    call AllocateUserHandle
    call AllocateModHandle
    jnc ovfModHOk
;
    int 3
    jmp ovfFail

ovfModHOk:
    mov ds,eax
    inc ds:kfm_ref_count
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
OpenVfsFile   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadVfsFile
;
;       DESCRIPTION:    Read VFS file
;
;       PARAMETERS:     BX		File sel
;                       EDX:EAX         Position
;                       ES:EDI          Buffer
;                       ECX             Size
;                       ESI             Mod sel (low) & handle (high)
;
;       RETURNS:        ECX             Count
;                       EDX:EAX         New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ReadVfsFile

ReadVfsFile    Proc near
    push fs
    push ebx
    push esi
    push ebp
;
    mov ebp,esi
;
    push eax
    push edx
;
    mov fs,si
    mov esi,fs:kfm_user_base
    mov ebx,flat_data_sel
    mov fs,ebx
    mov ebx,ebp
    xor ebp,ebp
    call VfsRead
;
    pop edx
    pop eax
;
    add eax,ecx
    adc edx,0
;
    pop ebp
    pop esi
    pop ebx
    pop fs
    ret
ReadVfsFile    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteVfsFile
;
;       DESCRIPTION:    Write VFS file
;
;       PARAMETERS:     BX		File sel
;                       EDX:EAX         Position
;                       ES:EDI          Buffer
;                       ECX             Size
;                       ESI             Mod sel (low) & handle (high)
;
;       RETURNS:        ECX             Count
;                       EDX:EAX         New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteVfsFile

WriteVfsFile    Proc near
    push fs
    push ebx
    push esi
    push ebp
;
    mov ebp,esi
;
    push eax
    push edx
;
    mov fs,si
    mov esi,fs:kfm_user_base
    mov ebx,flat_data_sel
    mov fs,ebx
    mov ebx,ebp
    xor ebp,ebp
    call VfsWrite
;
    pop edx
    pop eax
;
    add eax,ecx
    adc edx,0
;
    pop ebp
    pop esi
    pop ebx
    pop fs
    ret
WriteVfsFile    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           delete_vfs_file
;
;       DESCRIPTION:    Delete VFS file
;
;       PARAMETERS:     ES:EDI         Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_vfs_file    Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov eax,es
    mov gs,eax
;
    call GetPathDrive
    jc dvfFail
;
    call GetDrivePart
    or bx,bx
    jz dvfFail
;
    mov ah,es:[edi]
    cmp ah,'/'
    je dvfRoot
;
    cmp ah,'\'
    je dvfRoot

dvfRel:
    call GetRelDir
    jmp dvfHasStart

dvfRoot:
    inc edi
    xor ax,ax

dvfHasStart:
    mov esi,edi
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    movzx eax,ax
    call AllocateMsg
    jc dvfFail

dvfCopyPath:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz dvfCopyPath
;
    mov eax,VFS_DELETE_FILE
    call RunMsg
    jnc dvfDone

dvfFail:
    stc

dvfDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
delete_vfs_file    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloseVfsFile
;
;       DESCRIPTION:    Close VFS file
;
;       PARAMETERS:     BX             File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CloseVfsFile

CloseVfsFile  Proc near
    push ds
    mov ds,ebx
    call SendCloseReq
    pop ds
    ret
CloseVfsFile  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsFilePos
;
;       DESCRIPTION:    Get VFS file pos
;
;       PARAMETERS:     BX             Mod sel
;                       CX             User handle
;
;       RETURNS:        EDX:EAX        Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetVfsFilePos

GetVfsFilePos  Proc near
    push ds
    push es
;
    mov ds,ebx
    mov ax,flat_data_sel
    mov es,eax
;
    movzx edx,cx
    dec edx
    shl edx,3
;
    mov eax,ds:kfm_user_base
    mov eax,es:[eax].fm_handle_ptr
    add eax,OFFSET fh_pos_arr
    add edx,eax
    mov eax,es:[edx]
    mov edx,es:[edx+4]
    clc
;
    pop es
    pop ds
    ret
GetVfsFilePos  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetVfsFilePos
;
;       DESCRIPTION:    Set VFS file pos
;
;       PARAMETERS:     BX             Mod sel
;                       CX             User handle
;                       EDX:EAX        Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetVfsFilePos

SetVfsFilePos  Proc near
    push ds
    push es
    push ecx
    push edi
;
    mov ds,ebx
    mov di,flat_data_sel
    mov es,edi
;
    movzx ecx,cx
    dec ecx
    shl ecx,3
;
    mov edi,ds:kfm_user_base
    mov edi,es:[edi].fm_handle_ptr
    add edi,OFFSET fh_pos_arr
    add edi,ecx
    mov es:[edi],eax
    mov es:[edi+4],edx
    clc
;
    pop edi
    pop ecx
    pop es
    pop ds
    ret
SetVfsFilePos  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DupVfsFile
;
;       DESCRIPTION:    Dup VFS file
;
;       PARAMETERS:     BX             Mod sel
;                       EDX:EAX        Position
;
;       RETURNS:        DX             Dest user handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DupVfsFile

DupVfsFile  Proc near
    push ds
    push es
    push eax
    push edi
;
    push edx
    push eax
;
    mov eax,ebx
    mov ds,eax
;
    inc ds:kfm_ref_count
    call AllocateUserHandle
    movzx edi,dx
    dec edi
    shl edi,3
;
    mov ax,flat_data_sel
    mov es,eax
    mov eax,ds:kfm_user_base
    mov eax,es:[eax].fm_handle_ptr
    add eax,OFFSET fh_pos_arr
    add edi,eax
;
    pop eax
    stos dword ptr es:[edi]
;
    pop eax
    stos dword ptr es:[edi]
    clc
;
    pop edi
    pop eax
    pop es
    pop ds
    ret
DupVfsFile  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteFile
;
;       DESCRIPTION:    Delete file
;
;       PARAMETERS:     ES:(E)DI       Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_file_name       DB 'Delete VFS File',0

org_delete DD ?,?

delete_file16  Proc far
    push ecx
    push edi
    movzx edi,di
    call delete_vfs_file
    jnc dvf16Done
;
    call fword ptr cs:org_delete

dvf16Done:
    pop edi
    pop ecx
    ret
delete_file16  Endp

delete_file32  Proc far
    call delete_vfs_file
    jnc dvf32Done
;
    call fword ptr cs:org_delete

dvf32Done:
    ret
delete_file32  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           set_vfs_file_size
;
;       DESCRIPTION:    Set VFS file size
;
;       PARAMETERS:     DS             Prog sel
;                       EDX:EAX        Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_vfs_file_size  Proc near
    push ds
    push es
    push fs
    pushad
;    
    mov bx,ds:kfm_file_sel
    or bx,bx
    stc
    jz svfsDone
;
    mov ds,ebx
    mov ebx,REQ_SIZE
    call AddReq

svfsDone:
    popad
    pop fs
    pop es
    pop ds
    ret
set_vfs_file_size  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           create_vfs_dir
;
;       DESCRIPTION:    Create VFS dir
;
;       PARAMETERS:     ES:(E)DI       Pathname
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_vfs_dir    Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov eax,es
    mov gs,eax
;
    call GetPathDrive
    jc cvdFail
;
    call GetDrivePart
    or bx,bx
    jz cvdFail
;
    mov ah,es:[edi]
    cmp ah,'/'
    je cvdRoot
;
    cmp ah,'\'
    je cvdRoot

cvdRel:
    call GetRelDir
    jmp cvdHasStart

cvdRoot:
    inc edi
    xor ax,ax

cvdHasStart:
    mov esi,edi
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    movzx eax,ax
    call AllocateMsg
    jc cvdFail

cvdCopyPath:
    lods byte ptr gs:[esi]
    stosb
    or al,al
    jnz cvdCopyPath
;
    mov eax,VFS_CREATE_DIR
    call RunMsg
    jmp cvdDone

cvdFail:
    stc

cvdDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
create_vfs_dir    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MakeDir
;
;       DESCRIPTION:    Create directory
;
;       PARAMETERS:     ES:(E)DI       Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

make_dir_name       DB 'Create VFS Dir',0

org_make_dir DD ?,?

make_dir16  Proc far
    push edi
    movzx edi,di
    call create_vfs_dir
    jnc mdvf16Done
;
    call fword ptr cs:org_make_dir

mdvf16Done:
    pop edi
    ret
make_dir16  Endp

make_dir32  Proc far
    call create_vfs_dir
    jnc mdf32Done
;
    call fword ptr cs:org_make_dir

mdf32Done:
    ret
make_dir32  Endp

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
    mov ebx,OFFSET make_dir16
    mov esi,OFFSET make_dir32
    mov edi,OFFSET make_dir_name
    mov dx,virt_es_in
    mov ax,make_dir_nr
    LinkUserGate
    mov dword ptr fs:org_make_dir,eax
    mov word ptr fs:org_make_dir+4,dx
;
    mov ebx,OFFSET delete_file16
    mov esi,OFFSET delete_file32
    mov edi,OFFSET delete_file_name
    mov dx,virt_es_in
    mov ax,delete_file_nr
    LinkUserGate
    mov dword ptr fs:org_delete,eax
    mov word ptr fs:org_delete+4,dx
;
    mov ebx,fs
    xor eax,eax
    mov fs,eax
    FreeGdt    
    ret
init_client_file    Endp

code    ENDS

    END
