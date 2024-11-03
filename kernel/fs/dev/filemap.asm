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
INCLUDE ..\os\blk.inc
INCLUDE ..\hint.inc
include ..\handle.inc
INCLUDE ..\filemap.inc
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
  REQ_DELETE = 9

    .386p

file_handle_seg     STRUC

fh_base       handle_header <>

fh_sel        DW ?
fh_handle     DW ?

file_handle_seg     ENDS

KRE_DONE = 0
KRE_DISABLED = 1

kernel_req_entry  STRUC

kre_pos           DD ?,?
kre_size          DD ?
kre_phys_arr      DD ?
kre_block_arr     DD ?
kre_req_size      DD ?
kre_pages         DW ?
kre_usage         DW ?
kre_flags         DW ?

kernel_req_entry  ENDS

kernel_wait_entry  STRUC

kwe_next          DD ?
kwe_pos           DD ?,?
kwe_thread        DW ?

kernel_wait_entry  ENDS

;
; must be 4 bytes!
;

proc_entry  STRUC

pe_proc_sel       DW ?
pe_map_sel        DW ?

proc_entry  ENDS

kernel_file       STRUC

kf_sys            handle_sys_interface <>

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

kf_req_count      DD ?
kf_wait_count     DD ?
kf_block_count    DD ?
kf_phys_count     DD ?

kf_sorted_arr     DB 256 DUP(?)
kf_handle_arr     DD 256 DUP(?)

kernel_file       ENDS

process_file   STRUC

pf_base          handle_proc_interface <>

pf_flat_base     DD ?
pf_map_linear    DD ?
pf_map_sel       DW ?
pf_prog_sel      DW ?
pf_file_sel      DW ?
pf_handle        DW ?
pf_ref_count     DW ?
pf_section       section_typ <>
pf_free_count    DB ?
pf_unlink_count  DB ?
pf_check         DW ?
pf_src_arr       DD 240 DUP(?)
pf_ref_arr       DB 240 DUP(?)
pf_disabled_arr  DB 240 DUP(?)
pf_free_arr      DB 240 DUP(?)
pf_unlink_arr    DB 240 DUP(?)

process_file   ENDS


handle_file   STRUC

hf_base          handle_entry_interface <>
hf_user_handle   DD ?

handle_file   ENDS


kernel_file_map  STRUC

kfm_map           file_map <>

kfm_usage         DW ?
kfm_free_count    DB ?
kfm_unlink_count  DB ?
kfm_src_arr       DD 240 DUP(?)
kfm_ref_arr       DB 240 DUP(?)
kfm_disabled_arr  DB 240 DUP(?)
kfm_free_arr      DB 240 DUP(?)
kfm_unlink_arr    DB 240 DUP(?)

kernel_file_map  ENDS

handle_kernel_file  STRUC

hkf_base         handle_kernel_interface <>

hkf_map_linear   DD ?
hkf_map_sel      DW ?

handle_kernel_file  ENDS

data    SEGMENT byte public 'DATA'

sys_section       section_typ <>
sys_handle_arr    DW SYS_HANDLE_COUNT DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern AllocateMsg:near
    extern RunMsg:near
    extern PostMsg:near
    extern IsBlockCached:near
    extern BlockToBuf:near
    extern DisableBuf:near
    extern GetDrivePart:near
    extern GetPathDrive:near
    extern GetRelDir:near
    extern FileHandleToPartFs:near
    extern AllocateLocalSysHandle:near
    extern VfsRead:near
    extern VfsWrite:near
    extern KernelRead:near
    extern KernelWrite:near
    extern UpdateWrBitmap:near

    extern CreateSysObj:near
    extern CreateKernelObj:near
    extern CreateProcObj:near
    extern CreateHandleObj:near

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
;       PARAMETERS:     DS             Sys interface
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
;                         AX           Sys interface
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
;       NAME:           UpdateFileSel
;
;       DESCRIPTION:    Update file selector
;
;       PARAMETERS:     FS             Part sel
                        AX             Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UpdateFileSel

UpdateFileSel   Proc near
    push ds
    push es
    pushad
;
    mov ds,eax
    EnterSection ds:hsi_section
;
    mov eax,flat_sel
    mov es,eax
;
    mov ecx,PROC_BITMAP_COUNT  
    mov esi,OFFSET hsi_proc_bitmap
    mov edi,OFFSET hsi_proc_arr

ufsLoop:
    mov eax,ds:[esi]
    or eax,eax
    jz ufsNext
;
    push ecx
    mov ecx,32

ufseLoop:
    mov edx,ds:[edi]
    or edx,edx
    jz ufseNext
;
    mov es:[edx].pf_check,1
;
    mov edx,es:[edx].pf_map_linear
    mov es:[edx].fm_update,1

ufseNext:
    add edi,4
    loop ufseLoop
;
    pop ecx
    jmp ufsCont

ufsNext:
    add edi,4*32

ufsCont:
    add esi,4
    loop ufsLoop

ufsKernel:
    mov bx,ds:hsi_kernel_sel
    or bx,bx
    jz ufsDone
;
    mov es,ebx
    mov es,es:hkf_map_sel
    mov es,ebx
    mov es:fm_update,1

ufsDone:
    LeaveSection ds:hsi_section
;
    popad
    pop es
    pop ds
    ret
UpdateFileSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloseFileSel
;
;       DESCRIPTION:    Close file selector
;
;       PARAMETERS:     FS             Part sel
;                       AX             Sys interface
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
;                       EDX:EAX        File pos
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
    mov ds:[edi].kre_phys_arr,0
    mov ds:[edi].kre_block_arr,0
    mov ds:[edi].kre_usage,0
;
    push ds
    mov ds,fs:vfsp_disc_sel
    movzx eax,ds:vfs_bytes_per_sector
    pop ds
    mul ecx
    mov ds:[edi].kre_size,eax
    mov ds:[edi].kre_flags,0
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
;       PARAMETERS:     DS             Sys interface
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
;       PARAMETERS:     DS             Sys interface
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
;       PARAMETERS:     DS             Sys interface
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
;       NAME:           SendDerefReq
;
;       DESCRIPTION:    Send deref req
;
;       PARAMETERS:     DS             Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendDerefReq     Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ebx,ds:kf_serv_handle
    mov fs,ds:kf_part_sel
    mov ds,fs:vfsp_disc_sel
    call AllocateMsg
    jc sdrDone
;
    mov eax,VFS_DEREF_FILE
    call RunMsg

sdrDone:
    popad
    pop fs
    pop es
    pop ds
    ret
SendDerefReq     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CalcPageCount
;
;       DESCRIPTION:    Calculate page count
;
;       PARAMETERS:     FS                 Part sel
;                       ECX                Buffered blocks
;                       GS:ESI             Block array
;
;       RETURNS:        AX                 Page count
;                       ECX                Used blocks
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcPageCount  Proc near
    push ebx
    push esi
;
    push ecx
;
    xor ebx,ebx
    or ecx,ecx
    clc
    jz cpcDone
;
    inc ebx

cpcLoop:
    sub ecx,1
    jz cpcDone
;
    add esi,8
    mov eax,gs:[esi]
    test al,7
    jnz cpcLoop
;
    inc ebx
    cmp ebx,1FFFh
    jne cpcLoop

cpcDone:
    mov eax,ecx
    pop ecx
    sub ecx,eax
    mov eax,ebx
;
    pop esi
    pop ebx
    ret
CalcPageCount  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetupReadReq
;
;       DESCRIPTION:    Setup read req
;
;       PARAMETERS:     DS                 Sys interface
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
    mov ds:[ebx].kre_req_size,ecx
    mov ds:[ebx].kre_pages,ax
    mov cx,ax
;
    inc ds:kf_phys_count
    shl cx,3
    AllocateBlk
    mov ds:[ebx].kre_phys_arr,edx
;
    inc ds:kf_block_count
    movzx eax,cx
    AllocateBigServ
    mov ds:[ebx].kre_block_arr,edx
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
;       PARAMETERS:     DS                 Sys interface
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
    push ds
    mov ds,fs:vfsp_disc_sel
    mov ax,serv_flat_sel
    mov es,eax
    pop fs
;
    mov ebx,fs:[4*ebx].kf_handle_arr
    mov edi,fs:[ebx].kre_phys_arr
    mov ebp,fs:[ebx].kre_block_arr
    mov ebx,esi
;
    mov eax,gs:[ebx]
    mov edx,gs:[ebx+4]
    call BlockToPhys
    jnc prrSave
    jmp prrDone

prrLoop:
    sub ecx,1
    jz prrDone
;
    add ebx,8
    mov eax,gs:[ebx]
    test al,7
    jnz prrLoop
;
    mov edx,gs:[ebx+4]
    call BlockToPhys
    jc prrDone

prrSave:
    mov fs:[edi],eax
    mov fs:[edi+4],edx
    add edi,8
;
    mov eax,gs:[ebx]
    mov edx,gs:[ebx+4]
    mov es:[ebp],eax
    mov es:[ebp+4],edx
    add ebp,8
    jmp prrLoop

prrDone:
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
;       PARAMETERS:     DS                 Sys interface
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
;       PARAMETERS:     FS             Proc interface
;                       GS             Sys interface
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
;       PARAMETERS:     FS             Proc interface
;                       GS             Sys interface
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
;       PARAMETERS:     DS             Sys interface
;                       EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeReq      Proc near
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
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
    EnterSection ds:kf_update_section
    xor ecx,ecx
    xchg ecx,ds:kf_wr_size
    or ecx,ecx
    jz frWrDone
;
    push ebx
    mov eax,ds:kf_wr_base
    mov edx,ds:kf_wr_base+4
    mov ebx,REQ_UPDATE
    call AddReq
    pop ebx

frWrDone:
    LeaveSection ds:kf_update_section
;
    push ebx
    mov cx,bx
    mov ebx,REQ_FREE
    call AddReq
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
    ret
FreeReq      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateFile
;
;       DESCRIPTION:    Update file
;
;       PARAMETERS:     DS             Sys interface
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateFile      Proc near
    push ebx
    push esi
;
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
    ret
UpdateFile      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SendUpdate
;
;       DESCRIPTION:    Send update
;
;       PARAMETERS:     DS             Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendUpdate  Proc near
    push ecx
;
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
    ret
SendUpdate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockMap
;
;       DESCRIPTION:    Lock map
;
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
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
;       PARAMETERS:     ES             Proc map sel
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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
;                       EDI            Req id            
;
;       RETURNS:        BX             Entry offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateMapEntry      Proc near
    movzx ebx,ds:pf_free_count
    or bx,bx
    stc
    je ameDone
;
    inc es:fm_count
    dec bx
    mov ds:pf_free_count,bl
    mov bl,ds:[bx].pf_free_arr
    mov ds:[ebx].pf_ref_arr,1
    mov ds:[4*ebx].pf_src_arr,edi
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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
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
    sub edx,ds:pf_flat_base
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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
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
    movzx bx,ds:pf_unlink_count
    mov ds:[bx].pf_unlink_arr,al
    inc bl
    mov ds:pf_unlink_count,bl
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
;       NAME:           AddDirtyMap
;
;       DESCRIPTION:    Signal written page
;
;       PARAMETERS:     DS             Proc interface
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
;
    call SyncFileSize
;
    push ds
    mov ds,ds:pf_file_sel
    call UpdateFile
    pop ds

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
;       PARAMETERS:     DS             Proc interface
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
    add edx,ds:pf_flat_base

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
;       PARAMETERS:     DS             Proc interface
;                       ES:EDI         Req entry
;                       BX             Sorted index
;                       ESI            Index
;
;       RETRURNS:       CY             Entry freed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    add esi,OFFSET pf_ref_arr


CheckMap  Proc near
    push eax
;
    xor al,al
    xchg al,ds:[esi].pf_disabled_arr
    or al,al
    jnz cmFree
;
    call CheckDirtyMap
;
    test al,20h
    jz cmNone
;
    add byte ptr ds:[esi].pf_ref_arr,1
    jnc cmOk
;
    dec byte ptr ds:[esi].pf_ref_arr
    jmp cmOk

cmNone:
    mov al,ds:[esi].pf_ref_arr
    or al,al
    jz cmFree
;
    sub byte ptr ds:[esi].pf_ref_arr,1
    jnz cmOk

cmFree:
    mov ds:[esi].pf_ref_arr,0
    call FreeMap
    stc
    jmp cmDone

cmOk:
    clc

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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
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
    add edx,ds:pf_flat_base
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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
;                       FS             User flat sel
;                       GS             Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkMap  Proc near
    push ebx
    push ecx
    push edx
;
    movzx ecx,ds:pf_unlink_count
    mov ebx,OFFSET pf_unlink_arr

urmLoop:
    mov al,ds:[ebx]
    call UnlinkLinear
;
    push ds
    push eax
    push ebx
;
    movzx ebx,al
    mov ebx,ds:[4*ebx].pf_src_arr
    mov eax,gs
    mov ds,eax
    call FreeReq
;
    pop ebx
    pop eax
    pop ds
;
    movzx edx,ds:pf_free_count
    mov ds:[edx].pf_free_arr,al
    inc dl
    mov ds:pf_free_count,dl

    inc ebx
    loop urmLoop
;
    mov ds:pf_unlink_count,0
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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
;                       GS             Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateUnlinked  Proc near
    push eax
;
    movzx eax,ds:pf_unlink_count
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
;       PARAMETERS:     DS              Proc interface
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
    mov edx,ds:pf_map_linear
    mov edx,es:[edx].fm_handle_ptr
    mov eax,es:[edx].fh_req_size    
    mov edx,es:[edx].fh_req_size+4
;
    mov bx,flat_sel
    mov es,ebx
    mov ds,ds:pf_file_sel
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
;       NAME:           UpdateMap
;
;       DESCRIPTION:    Update map requests
;
;       PARAMETERS:     FS             Proc interface
;                       GS             Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMap  Proc near
    push ds
    push es
    pushad
;
    mov eax,fs
    mov ds,eax
    mov es,ds:pf_map_sel
    mov es:fm_update,0
    mov ebx,OFFSET fm_sorted_arr
    mov ecx,es:fm_count
    EnterSection ds:pf_section
    or ecx,ecx
    jz umLeave

umLoop:
    mov al,es:[ebx]
    cmp al,-1
    je umLeave
;
    movzx esi,al
    movzx edi,al
    shl edi,4
    add edi,OFFSET fm_entry_arr
    call CheckMap
    jc umSkip

umNext:
    inc ebx

umSkip:
    loop umLoop

umLeave:
    call UpdateUnlinked
;
    LeaveSection ds:pf_section
;
    call SyncFileSize
;
    push ds
    mov ds,ds:pf_file_sel
    call SendUpdate
    pop ds
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
;       PARAMETERS:     DS             Proc interface
;                       ES             Proc map sel
;                       GS             Sys interface
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
    EnterSection ds:pf_section
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
    LeaveSection ds:pf_section
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
;       PARAMETERS:     DS             Proc interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteMap  Proc near
    push es
    push gs
    pushad
;
    mov es,ds:pf_map_sel
    mov gs,ds:pf_file_sel
    mov ebx,OFFSET fm_sorted_arr
    mov ecx,240
    EnterSection ds:pf_section

dmLoop:
    mov al,es:[ebx]
    cmp al,-1
    je dmLeave
;
    movzx esi,al
    add esi,OFFSET pf_ref_arr
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
    LeaveSection ds:pf_section
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
    lock bts ds:[esi].kre_flags, KRE_DONE
    jc nfdLeave
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
;       NAME:           UpdateFileReq
;
;       DESCRIPTION:    Update file req
;
;       PARAMETERS:     FS                 Part sel                       
;                       GS                 Sys interface
;                       EDX                Req id
;                       ESI                Offset
;                       ECX                Count
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UpdateFileReq

WriteMaskTab:
wm00 DB 001h, 1
wm01 DB 003h, 2
wm02 DB 00Fh, 4
wm03 DB 0FFh, 8

UpdateFileReq  Proc near
    push ds
    push es
    push gs
    pushad
;
    mov ds,fs:vfsp_disc_sel
    EnterSection ds:vfs_section
;    
    mov ebx,gs:[4*edx].kf_handle_arr
    mov ebp,gs:[ebx].kre_req_size
    push ebp
;    
    mov ax,serv_flat_sel
    mov es,eax
;
    or ebp,ebp
    jz ufrDone
;
    mov ebp,gs:[ebx].kre_block_arr
    mov edx,gs:[ebx].kre_phys_arr
    mov edx,gs:[edx]
    and edx,0FFFh
;
    or esi,esi
    jz ufrOffsetDone
;
    movzx eax,ds:vfs_bytes_per_sector

ufrOffsetLoop:
    add dx,ax
    test dx,0FFFh
    jnz ufrOffsetNext
;
    add ebp,8
    xor edx,edx    

ufrOffsetNext:
    sub [esp],eax
    jz ufrDone
;
    sub esi,1
    jnz ufrOffsetLoop

ufrOffsetDone:
    xor bh,bh
    and dx,0FFFh
    jz ufrPosOk

ufrPosLoop:
    inc bh
    sub dx,ds:vfs_bytes_per_sector
    jnz ufrPosLoop

ufrPosOk:
    push ecx
    movzx eax,ds:vfs_sector_shift
    mov dx,cs:[2*eax].WriteMaskTab
    mov al,dh
    mul bh
    mov cl,al
    mov bh,dl
    shl bh,cl
    mov cl,dh
    pop edx
;
    or edx,edx
    jz ufrDone
;
    xor bl,bl
    movzx eax,ds:vfs_bytes_per_sector

ufrSectorLoop:
    or bl,bh
    rol bh,cl
    sub [esp],eax
    jz ufrWrLast
;
    test bh,1
    jz ufrSectorNext
;
    push edx
    mov eax,es:[ebp]
    mov edx,es:[ebp+4]
    call UpdateWrBitmap
    pop edx
;
    xor bl,bl
    add ebp,8

ufrSectorNext:
    sub edx,1
    jnz ufrSectorLoop

ufrWrLast:
    or bl,bl
    jz ufrDone
;
    mov eax,es:[ebp]
    mov edx,es:[ebp+4]
    call UpdateWrBitmap

ufrDone:
    pop ebp
    LeaveSection ds:vfs_section
;
    mov bx,ds:vfs_server
    Signal
;
    popad
    pop gs
    pop es
    pop ds
    ret
UpdateFileReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DisableFileReq
;
;       DESCRIPTION:    Disable file req
;
;       PARAMETERS:     DS                 Sys interface
;                       FS                 Part sel                       
;                       EDX                Req id
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DisableFileReq

DisableFileReq  Proc near
    push es
    push gs
    pushad
;
    EnterSection ds:hsi_section
    mov ebx,ds:[4*edx].kf_handle_arr
    lock bts ds:[ebx].kre_flags,KRE_DISABLED
;
    mov ecx,PROC_BITMAP_COUNT  
    mov esi,OFFSET hsi_proc_bitmap
    mov edi,OFFSET hsi_proc_arr

dfrLoop:
    mov eax,ds:[esi]
    or eax,eax
    jz dfrNext
;
    push ecx
    mov ecx,32

dfreLoop:
    mov esi,ds:[edi]
    or esi,esi
    jz dfreNext
;
    push ds
    push ebx
    push ecx
;
    mov eax,flat_sel
    mov ds,eax
    EnterSection ds:[esi].pf_section
;
    mov ecx,240
    xor ebx,ebx

dfrmLoop:
    mov al,ds:[esi+ebx].pf_ref_arr
    or al,al
    jz dfrmNext
;
    cmp edx,ds:[esi+4*ebx].pf_src_arr
    jne dfrmNext
;
    mov ds:[esi+ebx].pf_disabled_arr,1
    jmp dfrmLeave

dfrmNext:
    inc ebx
    loop dfrmLoop

dfrmLeave:
    LeaveSection ds:[esi].pf_section
; 
    pop ecx
    pop ebx
    pop ds

dfreNext:
    add edi,4
    loop dfreLoop
;
    pop ecx
    jmp dfrCont

dfrNext:
    add edi,4*32

dfrCont:
    add esi,4
    sub ecx,1
    jnz dfrLoop

dfrKernel:
    LeaveSection ds:hsi_section
;
    EnterSection ds:hsi_section
    mov ax,ds:hsi_kernel_sel
    or ax,ax
    jz dfrkLeave
;
    mov es,eax
    mov es,es:hkf_map_sel
    mov ecx,240
    xor ebx,ebx

dfrkLoop:
    mov al,es:[ebx].kfm_ref_arr
    or al,al
    jz dfrkNext
;
    cmp edx,es:[4*ebx].kfm_src_arr
    jne dfrkNext
;
    mov es:[ebx].kfm_disabled_arr,1
    jmp dfrkLeave

dfrkNext:
    inc ebx
    loop dfrkLoop

dfrkLeave:
    LeaveSection ds:hsi_section

dfrCache:
    mov ebx,ds:[4*edx].kf_handle_arr
    mov ecx,ds:[ebx].kre_req_size
;
    mov eax,ds
    mov gs,eax
;    
    mov ax,serv_flat_sel
    mov es,eax
;
    mov ebp,ebx
    or ecx,ecx
    jz dfrcDone
;
    mov edi,ds:[ebx].kre_block_arr
    mov edx,ds:[ebx].kre_phys_arr
    mov edx,ds:[edx]
    and edx,0FFFh
    jnz dfrcDone
;
    mov ds,fs:vfsp_disc_sel
    EnterSection ds:vfs_section

dfrcLoop:
    mov eax,1000h
    cmp ecx,eax
    jae dfrcAll
;
    mov eax,ecx

dfrcAll:
    sub ecx,eax
    shr eax,9
;    
    push eax
    mov eax,es:[edi]
    mov edx,es:[edi+4]
    call IsBlockCached
    pop eax
    jc dfrcNext
;
    call DisableBuf

dfrcNext:
    or ecx,ecx
    jz dfrcEntry
;
    add edi,8
    jmp dfrcLoop

dfrcEntry:
    LeaveSection ds:vfs_section

dfrcDone:
    popad
    pop gs
    pop es
    ret
DisableFileReq  Endp

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
    mov ecx,ds:[ebx].kre_req_size
;
    mov eax,ds
    mov gs,eax
;    
    mov ax,serv_flat_sel
    mov es,eax
;
    mov ebp,ebx
    or ecx,ecx
    jz ffrReq
;
    xor edi,edi
    mov edx,ds:[ebx].kre_phys_arr
    mov edx,ds:[edx]
    and edx,0FFFh
    shr edx,9
    mov eax,8
    sub eax,edx
    mov ds,fs:vfsp_disc_sel
    EnterSection ds:vfs_section

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
    push eax
    push edx
;
    mov edx,gs:[ebx].kre_block_arr
    mov eax,es:[edx+edi]
    mov edx,es:[edx+edi+4]
    call IsBlockCached
;
    pop edx
    pop eax
    jc ffrFreePhys
;
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
    dec ds:vfs_locked_pages
    jmp ffrFreeNext

ffrFreePhys:
    push eax
    push ebx
;
    mov ebx,gs:[ebx].kre_phys_arr
    mov eax,gs:[ebx+edi]
    mov ebx,gs:[ebx+edi+4]
    FreePhysical
;
    pop ebx
    pop eax

ffrFreeNext:
    or ecx,ecx
    jz ffrFreeEntry
;
    add edi,8
    mov eax,8
    jmp ffrFreeLoop

ffrFreeEntry:
    LeaveSection ds:vfs_section
;
    mov eax,gs
    mov ds,eax
    mov ebx,ebp
    mov cx,ds:[ebx].kre_pages
    dec ds:kf_phys_count
    shl cx,3
    mov edx,ds:[ebx].kre_phys_arr
    FreeBlk
;
    dec ds:kf_block_count
    mov edx,ds:[ebx].kre_block_arr
    movzx ecx,cx
    FreeBigServ

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
;       NAME:           LockMap
;
;       DESCRIPTION:    Lock map
;
;       PARAMETERS:     FS:ESI          Proc map ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public LockMap_

LockMap_      Proc near
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
LockMap_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockMap
;
;       DESCRIPTION:    Unlock map
;
;       PARAMETERS:     FS:ESI          Proc map ptr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UnlockMap_

UnlockMap_      Proc near
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
UnlockMap_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapVfsFile
;
;       DESCRIPTION:    Map VFS file
;
;       PARAMETERS:     ESI            Handle (high) + Proc interface (low)
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
    mov es,ds:pf_map_sel
    mov gs,ds:pf_file_sel
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
;       PARAMETERS:     ESI            Handle (high) + Proc interface (low)
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
    mov es,ds:pf_map_sel
    mov gs,ds:pf_file_sel
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
;       PARAMETERS:     ESI            Handle (high) + Proc interface (low)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UpdateVfsFile_

UpdateVfsFile_      Proc near
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
    mov es,ds:pf_map_sel
    mov gs,ds:pf_file_sel
    call UpdateMap
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
UpdateVfsFile_      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteVfsFile_
;
;       DESCRIPTION:    Delete VFS file
;
;       PARAMETERS:     ESI            Handle (high) + Proc interface (low)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DeleteVfsFile_

DeleteVfsFile_  Proc near
    push ds
    push eax
    push ebx
    push ecx
;
    mov ds,esi
;
    GetThreadHandle
    movzx ecx,ax
;
    mov ds,ds:pf_file_sel
    mov ebx,REQ_DELETE
    call AddReq
;
    WaitForSignal
;
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
DeleteVfsFile_  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddKernelDirtyMap
;
;       DESCRIPTION:    Signal written page
;
;       PARAMETERS:     DS             Sys interface
;                       ES:EDI         Req entry
;                       BX             Sorted index
;                       EDX            Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddKernelDirtyMap  Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov ecx,es:[edi].fmb_size
    test cx,0FFFh
    jnz akdmDone
;
    mov eax,es:[edi].fmb_base
    test ax,0FFFh
    jnz akdmDone
;
    sub edx,es:[edi].fmb_base
    mov eax,es:[edi].fmb_pos
    add eax,edx
    mov edx,es:[edi].fmb_pos+4
    adc edx,0
    mov ecx,1000h
    call UpdateFile

akdmDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AddKernelDirtyMap   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CheckKernelDirtyMap
;
;       DESCRIPTION:    Check kernel map for written pages
;
;       PARAMETERS:     DS             Sys interface
;                       ES:EDI         Req entry
;                       BX             Sorted index
;
;       RETURNS:        AX             Page bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckKernelDirtyMap  Proc near
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

ckdmLoop:
    GetPageEntry
    test ax,60h
    jz ckdmNext
;
    test al,40h
    jz ckdmClear
;
    call AddKernelDirtyMap

ckdmClear:
    or bp,ax
    and al,NOT 60h
    SetPageEntry

ckdmNext:
    add edx,1000h
    loop ckdmLoop
;
    mov ax,bp
    and al,60h
;
    pop ebp
    pop edx
    pop ecx
    pop ebx
    ret
CheckKernelDirtyMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeKernelMap
;
;       DESCRIPTION:    Free kernel map
;
;       PARAMETERS:     DS             Sys interface
;                       ES             Kernel map sel
;                       BX             Sorted index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeKernelMap  Proc near
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

fkmLoop:
    mov ah,es:[ebx+1]
    mov es:[ebx],ah
    inc ebx
    loop fkmLoop
;
    dec es:fm_count
    movzx bx,es:kfm_unlink_count
    mov es:[bx].kfm_unlink_arr,al
    inc bl
    mov es:kfm_unlink_count,bl
;
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
FreeKernelMap Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CheckKernelMap
;
;       DESCRIPTION:    Check kernel map
;
;       PARAMETERS:     DS             Sys interface
;                       ES:EDI         Req entry
;                       BX             Sorted index
;                       ESI            Index
;
;       RETRURNS:       CY             Entry freed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckKernelMap  Proc near
    push eax
;
    xor al,al
    xchg al,es:[esi].kfm_disabled_arr
    or al,al
    jnz ckmFree
;
    call CheckKernelDirtyMap
;
    test al,20h
    jz ckmNone
;
    add byte ptr es:[esi].kfm_ref_arr,1
    jnc ckmOk
;
    dec byte ptr es:[esi].kfm_ref_arr
    jmp ckmOk

ckmNone:
    mov al,es:[esi].kfm_ref_arr
    or al,al
    jz ckmFree
;
    sub byte ptr es:[esi].kfm_ref_arr,1
    jnz ckmOk

ckmFree:
    mov es:[esi].kfm_ref_arr,0
    call FreeKernelMap
    stc
    jmp ckmDone

ckmOk:
    clc

ckmDone:
    pop eax
    ret
CheckKernelMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlinkKernelLinear
;
;       DESCRIPTION:    Unlink kernel linear address
;
;       PARAMETERS:     ES             Kernel map sel
;                       AL             Entry #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkKernelLinear  Proc near
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
    jz uklDone
;
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

uklDone:
    pop esi
    pop edx
    pop ecx
    ret
UnlinkKernelLinear   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateKernelUnlinked
;
;       DESCRIPTION:    Update kernel unlinked entries
;
;       PARAMETERS:     DS             Sys interface
;                       ES             Kernel map sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateKernelUnlinked  Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    movzx ecx,es:kfm_unlink_count
    or ecx,ecx
    jz ukuDone
;
    mov ebx,OFFSET kfm_unlink_arr

ukuLoop:
    mov al,es:[ebx]
    call UnlinkKernelLinear
;
    push ebx
    movzx ebx,al
    mov ebx,es:[4*ebx].kfm_src_arr
    call FreeReq
    pop ebx
;
    movzx edx,es:kfm_free_count
    mov es:[edx].kfm_free_arr,al
    inc dl
    mov es:kfm_free_count,dl

    inc ebx
    loop ukuLoop
;
    mov es:kfm_unlink_count,0

ukuDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
UpdateKernelUnlinked Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateKernelMap
;
;       DESCRIPTION:    Update kernel map requests
;
;       PARAMETERS:     DS             Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateKernelMap  Proc near
    push ds
    push es
    pushad
;
    EnterSection ds:hsi_section
;
    mov es,ds:hsi_kernel_sel
    mov es,es:hkf_map_sel
    mov es:fm_update,0
    mov ebx,OFFSET fm_sorted_arr
    mov ecx,es:fm_count
    or ecx,ecx
    jz ukmLeave

ukmLoop:
    mov al,es:[ebx]
    cmp al,-1
    je ukmLeave
;
    movzx esi,al
    movzx edi,al
    shl edi,4
    add edi,OFFSET fm_entry_arr
    call CheckKernelMap
    jc ukmSkip

ukmNext:
    inc ebx

ukmSkip:
    loop ukmLoop

ukmLeave:
    call UpdateKernelUnlinked
;
    LeaveSection ds:hsi_section
;
    call SendUpdate
;
    popad
    pop es
    pop ds
    ret
UpdateKernelMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateKernelMapEntry
;
;       DESCRIPTION:    Allocate map entry
;
;       PARAMETERS:     DS             Sys interface
;                       ES             Kernel map sel
;                       EDI            Req id            
;
;       RETURNS:        BX             Entry offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateKernelMapEntry      Proc near
    movzx ebx,es:kfm_free_count
    or bx,bx
    stc
    je akmeDone
;
    inc es:fm_count
    dec bx
    mov es:kfm_free_count,bl
    mov bl,es:[bx].kfm_free_arr
    mov es:[ebx].kfm_ref_arr,1
    mov es:[4*ebx].kfm_src_arr,edi
    shl bx,4
    add bx,OFFSET fm_entry_arr
    clc

akmeDone:
    ret
AllocateKernelMapEntry      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapKernelEntry
;
;       DESCRIPTION:    Map kernel entry
;
;       PARAMETERS:     DS             Sys interface
;                       ES             Kernel map sel
;                       DS:ESI         Physical address buffer
;                       BX             Entry offset
;                       ECX            Pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapKernelEntry      Proc near
    push eax
    push ecx
    push edx
;
    mov eax,ecx
    shl eax,12
    AllocateBigLinear
;
    push ebx
    push edx
    push esi

mkeLoop:
    mov eax,ds:[esi]
    mov ebx,ds:[esi+4]
    and ax,0F000h
    or ax,803h
    SetPageEntry
;
    add edx,1000h
    add esi,8
    loop mkeLoop
;
    pop esi
    pop edx
    pop ebx
;
    mov eax,ds:[esi]
    and ax,0FFFh
    or dx,ax
    mov es:[ebx].fmb_base,edx
;
    pop edx
    pop ecx
    pop eax
    ret
MapKernelEntry      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddKernelMap
;
;       DESCRIPTION:    Add kernel map
;
;       PARAMETERS:     DS             Sys interface
;                       ES             Kernel map sel
;                       BX             Entry offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddKernelMap      Proc near
    pushad
;
    movzx esi,bx
    mov ebx,OFFSET fm_sorted_arr
    mov ebp,es:fm_count
    sub ebp,1
    jbe akmInsert
 
akmFind:
    movzx ecx,byte ptr es:[ebx]
    shl ecx,4
    mov eax,es:[esi].fmb_pos
    mov edx,es:[esi].fmb_pos+4
    sub eax,es:[ecx].fm_entry_arr.fmb_pos
    sbb edx,es:[ecx].fm_entry_arr.fmb_pos+4
    jb akmInsert
    jnz akmNext
;
    cmp eax,ds:[ecx].fm_entry_arr.fmb_size
    jb akmInsert

akmNext:
    inc ebx
    sub ebp,1
    jnz akmFind

akmInsert:
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
    jz akmSave

akmMove:
    mov al,es:[esi]
    mov es:[edi],al
    dec esi
    dec edi
    loop akmMove

akmSave:
    mov es:[edi],bl
    clc

akmDone:
    popad
    ret
AddKernelMap      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SyncKernelMap
;
;       DESCRIPTION:    Sync kernel map from file sel
;
;       PARAMETERS:     DS             Sys interface
;                       ES             Kernel mapping sel
;                       EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SyncKernelMap  Proc near
    pushad
;
    mov edi,ebx
    mov ebx,ds:[4*ebx].kf_handle_arr
    mov eax,ds:[ebx].kre_pos
    mov edx,ds:[ebx].kre_pos+4
    mov ecx,ds:[ebx].kre_size
;
    mov esi,ds:[ebx].kre_phys_arr
    movzx ebp,ds:[ebx].kre_pages
;
    push ecx
    call FindReadMap
    pop ecx
    jc skmAdd
;
    mov edi,ds:[4*edi].kf_handle_arr
    dec ds:[edi].kre_usage
    stc
    jmp skmDone

skmAdd:
    call AllocateKernelMapEntry
    mov es:[bx].fmb_pos,eax
    mov es:[bx].fmb_pos+4,edx
    mov es:[bx].fmb_size,ecx
;
    mov ecx,ebp
    call MapKernelEntry
    call AddKernelMap
    clc

skmDone:
    popad
    ret
SyncKernelMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateKernelFile
;
;       DESCRIPTION:    Update kernel file
;
;       PARAMETERS:     SI              Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UpdateKernelFile_

UpdateKernelFile_      Proc near
    push ds
    pushad
;
    mov ds,esi
    call UpdateKernelMap
;
    popad
    pop ds
    ret
UpdateKernelFile_      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForKernelReq
;
;       DESCRIPTION:    Wait for kernel req
;
;       PARAMETERS:     DS             Sys interface
;                       EDX:EAX        Req position
;
;       RETURNS:        EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForKernelReq   Proc near
    push ecx
    push esi
    push edi
;
    EnterSection ds:kf_section
    call FindReq
    jnc wfkrCheck
;
    call AddWaitReq
    LeaveSection ds:kf_section
;
    mov ebx,REQ_READ
    call AddReq
    call UpdateKernelMap

wfkrWait:
    WaitForSignal
;
    EnterSection ds:kf_section
    call FindReq
    jnc wfkrCheck
;
    LeaveSection ds:kf_section
;
    push eax
    mov ax,20
    WaitMilliSec
    pop eax
    jmp wfkrDone

wfkrCheck:
    mov esi,ds:[4*ebx].kf_handle_arr
    mov esi,ds:[esi].kre_phys_arr
    or esi,esi
    jnz wfkrLock
;
    call AddWaitReq
    LeaveSection ds:kf_section
    jmp wfkrWait

wfkrLock:
    mov esi,ds:[4*ebx].kf_handle_arr
;
    mov di,ds:[esi].kre_usage
    inc di
    mov ds:[esi].kre_usage,di
    sub di,1
    LeaveSection ds:kf_section
    clc
    jnz wfkrDone
;
    push ebx
    mov cx,bx
    mov bx,REQ_MAP
    call AddReq
    pop ebx
    clc
    jmp wfkrDone

wfkrLeave:
    LeaveSection ds:kf_section

wfkrDone:
    pop edi
    pop esi
    pop ecx
    ret
WaitForKernelReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForKernelGrow
;
;       DESCRIPTION:    Wait for kernel grow
;
;       PARAMETERS:     DS             Sys interface
;                       EDX:EAX        Req position
;                       ECX            Increase
;
;       RETURNS:        EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForKernelGrow      Proc near
    push ecx
    push esi
    push edi
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
    jnc wfkgCheck
;
    call AddWaitReq
    LeaveSection ds:kf_section
;
    call UpdateKernelMap

wfkgWait:
    WaitForSignal
;
    EnterSection ds:kf_section
    call FindReq
    jnc wfkgCheck
;
    LeaveSection ds:kf_section
;
    push eax
    mov ax,20
    WaitMilliSec
    pop eax
    jmp wfkgDone

wfkgCheck:
    mov esi,ds:[4*ebx].kf_handle_arr
    mov esi,ds:[esi].kre_phys_arr
    or esi,esi
    jnz wfkgLock
;
    call AddWaitReq
    LeaveSection ds:kf_section
    jmp wfkgWait

wfkgLock:
    mov esi,ds:[4*ebx].kf_handle_arr
;
    mov di,ds:[esi].kre_usage
    inc di
    mov ds:[esi].kre_usage,di
    sub di,1
    LeaveSection ds:kf_section
    clc
    jnz wfkgDone
;
    push ebx
    mov cx,bx
    mov bx,REQ_MAP
    call AddReq
    pop ebx
    clc
    jmp wfkgDone

wfkgLeave:
    LeaveSection ds:kf_section

wfkgDone:
    pop edi
    pop esi
    pop ecx
    ret
WaitForKernelGrow    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapKernelFile
;
;       DESCRIPTION:    Map kernel file
;
;       PARAMETERS:     SI             Sys interface
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public MapKernelFile_

MapKernelFile_      Proc near
    push ds
    push es
    pushad
;
    mov ds,esi
    call WaitForKernelReq
    jc mkfDone
;
    mov es,ds:hsi_kernel_sel
    mov es,es:hkf_map_sel
    call SyncKernelMap

mkfDone:
    popad
    pop es
    pop ds
    ret
MapKernelFile_   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GrowKernelFile
;
;       DESCRIPTION:    Grow kernel file
;
;       PARAMETERS:     SI             Sys interface
;                       EDX:EAX        Current size
;                       ECX            Grow amount
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GrowKernelFile_

GrowKernelFile_      Proc near
    push ds
    push es
    pushad
;
    mov ds,esi
    call WaitForKernelGrow
    jc gkfDone
;
    mov es,ds:hsi_kernel_sel
    mov es,es:hkf_map_sel
    call SyncKernelMap

gkfDone:
    popad
    pop es
    pop ds
    ret
GrowKernelFile_      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsFilePos
;
;       DESCRIPTION:    Get VFS file pos
;
;       PARAMETERS:     BX             Proc interface
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
    mov eax,ds:pf_map_linear
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
;       PARAMETERS:     BX             Proc interface
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
    mov edi,ds:pf_map_linear
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
;       PARAMETERS:     BX             Proc interface
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
    inc ds:pf_ref_count
;    call AllocateUserHandle
    movzx edi,dx
    dec edi
    shl edi,3
;
    mov ax,flat_data_sel
    mov es,eax
    mov eax,ds:pf_map_linear
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
;           NAME:           DupKernelVfsFile
;
;           DESCRIPTION:    Dup kernel VFS file
;
;           PARAMETERS:     BX          Sys interface
;                           
;           RETURNS:        BX          File handle entry
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DupKernelVfsFile

DupKernelVfsFile    Proc near
    push ds
    push eax
    push edx
;
    mov ds,ebx
    EnterSection ds:kf_section
;
    mov bx,ds:kf_c_handle
    or bx,bx
    jz dkvfNew
;
    call SendDerefReq
    jmp dkvfHandleOk

dkvfNew:
    call AllocateLocalSysHandle
    mov ds:kf_c_handle,bx

dkvfHandleOk:
;    call FindVfsProc
    jnc dkvfModOk
;
;    call CreateVfsProc
;    call AddVfsProc

dkvfModOk:
    LeaveSection ds:kf_section
;
;    call AllocateUserHandle
;    call AllocateProcHandle
    jnc dkvfModHOk
;
    int 3
    jmp dkvfFail

dkvfModHOk:
    mov ds,eax
    inc ds:pf_ref_count
    clc
    jmp dkvfDone

dkvfFail:
    stc

dkvfDone:
    pop edx
    pop eax
    pop ds
    ret
DupKernelVfsFile   Endp

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

delete_vfs_file    Proc near
    push ebx
    push ecx
;
    xor ecx,ecx    
    call OpenVfsFile
    jc dvfFail
;
    push ebx
    DeleteHandle
    pop ebx
;
    CloseHandle
    clc
    jmp dvfDone

dvfFail:
    stc

dvfDone:
    pop ecx
    pop ebx
    ret
delete_vfs_file    Endp

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
;       NAME:           GetMapSel
;
;       DESCRIPTION:    Read handle
;
;       PARAMETERS:     DS              Handle interface
;
;       RETURNS:        EAX               Map index
;                       EDI               Map linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMapSel    Proc far
    push ds
;
    mov eax,ds:hf_user_handle
;
    mov ds,ds:hei_proc_sel
    mov edi,ds:pf_map_linear
    clc
;
    pop ds
    ret
GetMapSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapSel
;
;       DESCRIPTION:    Map file
;
;       PARAMETERS:     DS             Handle interface
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapSel      Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov si,ds:hei_proc_sel
    mov ds,esi
    mov fs,esi
    mov es,ds:pf_map_sel
    mov gs,ds:pf_file_sel
;
    call WaitForReq
    jc msDone
;
    call LockMap
    call SyncMap
    pushf
    call UnlockMap
    popf

msDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
MapSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateMapSel
;
;       DESCRIPTION:    Update map file
;
;       PARAMETERS:     DS             Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMapSel      Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov si,ds:hei_proc_sel
    mov ds,esi
    mov fs,esi
    mov es,ds:pf_map_sel
    mov gs,ds:pf_file_sel
    call UpdateMap
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
UpdateMapSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GrowMapSel
;
;       DESCRIPTION:    Grow map file
;
;       PARAMETERS:     DS             Handle interface
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowMapSel      Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov si,ds:hei_proc_sel
    mov ds,esi
    mov fs,esi
    mov es,ds:pf_map_sel
    mov gs,ds:pf_file_sel
;
    call WaitForGrow
    jc gmsDone
;
    call LockMap
    call SyncMap
    pushf
    call UnlockMap
    popf

gmsDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
GrowMapSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadHandleSel
;
;       DESCRIPTION:    Read handle
;
;       PARAMETERS:     DS              Handle interface
;                       ES:EDI          Buffer
;                       ECX             Size
;
;       RETURNS:        ECX             Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadHandleSel    Proc far
    push ds
    push fs
    push ebx
    push edx
    push esi
    push ebp
;
    mov ebp,ds:hf_user_handle
    mov ds,ds:hei_proc_sel
    mov bx,flat_data_sel
    mov fs,ebx
;
    dec ebp
    shl ebp,3
;
    mov esi,ds:pf_map_linear
    mov eax,fs:[esi].fm_handle_ptr
    add eax,OFFSET fh_pos_arr
    add ebp,eax
    mov eax,fs:[ebp]
    mov edx,fs:[ebp+4]
;
    push eax
    push edx
    push ebp
;
    mov ebx,ds
    xor ebp,ebp
    call VfsRead
;
    pop ebp
    pop edx
    pop eax
;
    add eax,ecx
    adc edx,0
;
    mov fs:[ebp],eax
    mov fs:[ebp+4],edx
;
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop fs
    pop ds
    ret
ReadHandleSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteHandleSel
;
;       DESCRIPTION:    Write handle
;
;       PARAMETERS:     DS              Handle interface
;                       ES:EDI          Buffer
;                       ECX             Size
;
;       RETURNS:        ECX             Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHandleSel    Proc far
    push ds
    push fs
    push ebx
    push edx
    push esi
    push ebp
;
    mov ebp,ds:hf_user_handle
    mov ds,ds:hei_proc_sel
    mov bx,flat_data_sel
    mov fs,ebx
;
    dec ebp
    shl ebp,3
;
    mov esi,ds:pf_map_linear
    mov eax,fs:[esi].fm_handle_ptr
    add eax,OFFSET fh_pos_arr
    add ebp,eax
    mov eax,fs:[ebp]
    mov edx,fs:[ebp+4]
;
    push eax
    push edx
    push ebp
;
    mov ebx,ds
    xor ebp,ebp
    call VfsWrite
;
    pop ebp
    pop edx
    pop eax
;
    add eax,ecx
    adc edx,0
;
    mov fs:[ebp],eax
    mov fs:[ebp+4],edx
;
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop fs
    pop ds
    ret
WriteHandleSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           PollHandleSel
;
;       DESCRIPTION:    Poll handle
;
;       PARAMETERS:     DS              Handle interface
;                       ES:EDI          Buffer
;                       ECX             Size
;
;       RETURNS:        ECX             Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollHandleSel    Proc far
    push ds
    push fs
    push ebx
    push edx
    push esi
    push ebp
;
    mov ebp,ds:hf_user_handle
    mov ds,ds:hei_proc_sel
    mov bx,flat_data_sel
    mov fs,ebx
;
    dec ebp
    shl ebp,3
;
    mov esi,ds:pf_map_linear
    mov eax,fs:[esi].fm_handle_ptr
    add eax,OFFSET fh_pos_arr
    add ebp,eax
    mov eax,fs:[ebp]
    mov edx,fs:[ebp+4]
;
    push eax
    push edx
    push ebp
;
    mov ebx,ds
    xor ebp,ebp
    call VfsRead
;
    pop ebp
    pop edx
    pop eax
;
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop fs
    pop ds
    ret
PollHandleSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetPosSel
;
;       DESCRIPTION:    Get handle pos
;
;       PARAMETERS:     DS              Handle interface
;
;       RETURNS:        EDX:EAX         Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPosSel    Proc far
    push ds
    push esi
;
    mov eax,ds:hf_user_handle
    dec eax
    shl eax,3
;
    mov ds,ds:hei_proc_sel
    mov esi,ds:pf_map_linear
    mov edx,flat_data_sel
    mov ds,edx
;
    mov edx,ds:[esi].fm_handle_ptr
    add edx,OFFSET fh_pos_arr
    add edx,eax
    mov eax,ds:[edx]
    mov edx,ds:[edx+4]
;
    pop esi
    pop ds
    ret
GetPosSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetPosSel
;
;       DESCRIPTION:    Set handle pos
;
;       PARAMETERS:     DS              Handle interface
;                       EDX:EAX         Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPosSel    Proc far
    push ds
    push ebx
    push ecx
    push esi
;
    mov ebx,ds:hf_user_handle
    dec ebx
    shl ebx,3
;
    mov ds,ds:hei_proc_sel
    mov esi,ds:pf_map_linear
    mov ecx,flat_data_sel
    mov ds,ecx
;
    mov ecx,ds:[esi].fm_handle_ptr
    add ecx,OFFSET fh_pos_arr
    add ebx,ecx
    mov ds:[ebx],eax
    mov ds:[ebx+4],edx
;
    pop esi
    pop ecx
    pop ebx
    pop ds
    ret
SetPosSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSizeSel
;
;       DESCRIPTION:    Get handle size
;
;       PARAMETERS:     DS              Handle interface
;
;       RETURNS:        EDX:EAX         Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSizeSel    Proc far
    push ds
    push edi
;
    mov ds,ds:hei_sys_sel
    mov edi,ds:kf_info_linear
    mov ax,flat_sel
    mov ds,eax
    mov eax,ds:[edi].fi_size
    mov edx,ds:[edi].fi_size+4       
;
    pop edi
    pop ds
    ret
GetSizeSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetSizeSel
;
;       DESCRIPTION:    Set file size
;
;       PARAMETERS:     DS              Handle interface
;                       EDX:EAX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSizeSel    Proc far
    push ds
    push ecx
;
    mov ds,ds:hei_sys_sel
    push eax
    GetThreadHandle
    movzx ecx,ax
    pop eax
;
    mov ebx,REQ_SIZE
    call AddReq
;
    WaitForSignal
;
    pop ecx
    pop ds
    ret
SetSizeSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsEofSel
;
;       DESCRIPTION:    Is eof?
;
;       PARAMETERS:     DS              Handle interface
;
;       RETURNS:        EAX             0 = false, 1 = true
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsEofSel    Proc far
    push ds
    push es
    push esi
;
    mov ax,flat_sel
    mov es,eax
;
    mov eax,ds:hf_user_handle
    dec eax
    shl eax,3
;
    push ds
    mov ds,ds:hei_proc_sel
    mov esi,ds:pf_map_linear
    pop ds
;
    mov edx,es:[esi].fm_handle_ptr
    add edx,OFFSET fh_pos_arr
    add edx,eax
    mov eax,es:[edx]
    mov edx,es:[edx+4]
;
    mov ds,ds:hei_sys_sel
    mov esi,ds:kf_info_linear
    sub eax,ds:[esi].fi_size
    sbb edx,ds:[esi].fi_size+4       
    jc ieNo

ieYes:
    mov eax,1
    jmp ieDone

ieNo:
    xor eax,eax

ieDone:
    clc
;
    pop esi
    pop es
    pop ds
    ret
IsEofSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCreateSel
;
;       DESCRIPTION:    Get handle create time
;
;       PARAMETERS:     DS              Handle interface
;
;       RETURNS:        EDX:EAX         Tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCreateSel    Proc far
    push ds
    push edi
;
    mov ds,ds:hei_sys_sel
    mov edi,ds:kf_info_linear
    mov ax,flat_sel
    mov ds,eax
    mov eax,ds:[edi].fi_create
    mov edx,ds:[edi].fi_create+4       
;
    pop edi
    pop ds
    ret
GetCreateSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetModifySel
;
;       DESCRIPTION:    Get handle modidy time
;
;       PARAMETERS:     DS              Handle interface
;
;       RETURNS:        EDX:EAX         Tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetModifySel    Proc far
    push ds
    push edi
;
    mov ds,ds:hei_sys_sel
    mov edi,ds:kf_info_linear
    mov ax,flat_sel
    mov ds,eax
    mov eax,ds:[edi].fi_modify
    mov edx,ds:[edi].fi_modify+4       
;
    pop edi
    pop ds
    ret
GetModifySel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetAccessSel
;
;       DESCRIPTION:    Get handle access time
;
;       PARAMETERS:     DS              Handle interface
;
;       RETURNS:        EDX:EAX         Tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAccessSel    Proc far
    push ds
    push edi
;
    mov ds,ds:hei_sys_sel
    mov edi,ds:kf_info_linear
    mov ax,flat_sel
    mov ds,eax
    mov eax,ds:[edi].fi_access
    mov edx,ds:[edi].fi_access+4       
;
    pop edi
    pop ds
    ret
GetAccessSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteHandleSel
;
;       DESCRIPTION:    Delete handle sel
;
;       PARAMETERS:     DS              Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteHandleSel      Proc far
    push ds
    push eax
    push ebx
    push edx
;
    mov ebx,ds:hf_user_handle
    or ebx,ebx
    jz dhsDone
;
    mov ds,ds:hei_proc_sel
    call SyncFileSize
;
    mov edx,ds:pf_map_linear
    mov eax,flat_data_sel
    mov ds,eax
    mov edx,ds:[edx].fm_handle_ptr
    add edx,OFFSET fh_bitmap
;
    dec ebx
    lock btc ds:[edx],ebx
    jc dhsDone
;
    int 3

dhsDone:
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
DeleteHandleSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitHandleSel
;
;       DESCRIPTION:    Init handle sel
;
;       PARAMETERS:     ES              Handle interface
;                       EBX             Map index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitHandleSel   Proc near
    inc ebx
    mov es:hf_user_handle,ebx
;
    mov es:hei_dup_proc, OFFSET DupSel
    mov es:hei_dup_proc+4,cs
;
    mov es:hei_get_map_proc, OFFSET GetMapSel
    mov es:hei_get_map_proc+4,cs
;
    mov es:hei_map_proc, OFFSET MapSel
    mov es:hei_map_proc+4,cs
;
    mov es:hei_update_map_proc, OFFSET UpdateMapSel
    mov es:hei_update_map_proc+4,cs
;
    mov es:hei_grow_map_proc, OFFSET GrowMapSel
    mov es:hei_grow_map_proc+4,cs
;
    mov es:hei_read_proc, OFFSET ReadHandleSel
    mov es:hei_read_proc+4,cs
;
    mov es:hei_write_proc, OFFSET WriteHandleSel
    mov es:hei_write_proc+4,cs
;
    mov es:hei_poll_proc, OFFSET PollHandleSel
    mov es:hei_poll_proc+4,cs
;
    mov es:hei_get_pos_proc, OFFSET GetPosSel
    mov es:hei_get_pos_proc+4,cs
;
    mov es:hei_set_pos_proc, OFFSET SetPosSel
    mov es:hei_set_pos_proc+4,cs
;
    mov es:hei_get_size_proc, OFFSET GetSizeSel
    mov es:hei_get_size_proc+4,cs
;
    mov es:hei_set_size_proc, OFFSET SetSizeSel
    mov es:hei_set_size_proc+4,cs
;
    mov es:hei_get_create_time_proc, OFFSET GetCreateSel
    mov es:hei_get_create_time_proc+4,cs
;
    mov es:hei_get_modify_time_proc, OFFSET GetModifySel
    mov es:hei_get_modify_time_proc+4,cs
;
    mov es:hei_get_access_time_proc, OFFSET GetAccessSel
    mov es:hei_get_access_time_proc+4,cs
;
    mov es:hei_is_eof_proc, OFFSET IsEofSel
    mov es:hei_is_eof_proc+4,cs
;
    mov es:hei_delete_proc, OFFSET DeleteHandleSel
    mov es:hei_delete_proc+4,cs
;
    ret
InitHandleSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DupSel
;
;       DESCRIPTION:    Dup handle sel
;
;       PARAMETERS:     DS              Handle interface
;
;       RETURNS:        NC
;                         AX            Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DupSel      Proc far
    push ds
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov bx,flat_data_sel
    mov es,ebx
;
    mov ax,ds:hei_io_mode
    push eax
;
    mov eax,ds:hf_user_handle
    dec eax
    shl eax,3
;
    mov ds,ds:hei_proc_sel
    mov esi,ds:pf_map_linear
;
    mov edx,es:[esi].fm_handle_ptr
    add edx,OFFSET fh_pos_arr
    add edx,eax
    mov eax,es:[edx]
    mov edx,es:[edx+4]
;
    push edx
    push eax
;
    mov edx,es:[esi].fm_handle_ptr
    add edx,OFFSET fh_bitmap
    mov ecx,15
    xor esi,esi

dusLoop:
    mov eax,es:[edx]
    cmp eax,-1
    je dusNext
;
    not eax
    bsf ebx,eax
;
    lock bts es:[edx],ebx
    jc dusLoop
;
    inc ds:hpi_ref_count
;
    add ebx,esi
    mov esi,ebx
    mov edx,ds:pf_map_linear
    mov edx,es:[edx].fm_handle_ptr
    shl esi,3
    add edx,esi
    add edx,OFFSET fh_pos_arr
;
    pop eax
    mov es:[edx],eax
    add edx,4
;
    pop eax
    mov es:[edx],eax
;
    mov eax,SIZE handle_file
    AllocateSmallLinear
;
    call CreateHandleObj
    mov es,eax
;
    call InitHandleSel
;
    pop eax
    mov es:hei_io_mode,ax
    mov eax,es
    clc
    jmp dusDone

dusNext:
    add esi,32
    add edx,4
    sub ecx,1
    jnz dusLoop
;
    add esp,12
    stc

dusDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
DupSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateHandleSel
;
;       DESCRIPTION:    Create handle sel
;
;       PARAMETERS:     DS              Handle proc interface
;                       CX              Access
;
;       RETURNS:        NC
;                         AX            Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateHandleSel      Proc far
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov edi,ecx
    mov bx,flat_data_sel
    mov es,ebx
    mov edx,ds:pf_map_linear
    mov edx,es:[edx].fm_handle_ptr
    add edx,OFFSET fh_bitmap
    mov ecx,15
    xor esi,esi

chsLoop:
    mov eax,es:[edx]
    cmp eax,-1
    je chsNext
;
    not eax
    bsf ebx,eax
;
    lock bts es:[edx],ebx
    jc chsLoop
;
    add ebx,esi
;
    mov esi,ebx
    mov edx,ds:pf_map_linear
    mov edx,es:[edx].fm_handle_ptr
    shl esi,3

    add edx,esi
    add edx,OFFSET fh_pos_arr
    xor eax,eax
    mov es:[edx],eax
    add edx,4
    mov es:[edx],eax
;
    mov eax,SIZE handle_file
    AllocateSmallLinear
;
    call CreateHandleObj
    mov es,eax
;
    call InitHandleSel
    clc
    jmp chsDone

chsNext:
    add esi,32
    add edx,4
    sub ecx,1
    jnz chsLoop
;
    stc

chsDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CreateHandleSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteProcSel
;
;       DESCRIPTION:    Delete proc sel
;
;       PARAMETERS:     DS              Proc interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteProcSel   Proc far
    push es
    push eax
    push ebx
    push ecx
    push edx
;
    call DeleteMap
;
    push ds
    mov ds,ds:pf_map_sel
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
    mov es,ds:pf_map_sel
    FreeMem
;
    mov edx,ds:pf_map_linear
    add edx,ds:pf_flat_base
    mov ecx,3000h
    FreeLinear
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
DeleteProcSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateProcSel
;
;       DESCRIPTION:    Create proc sel
;
;       PARAMETERS:     DS              Sys handle sel
;
;       RETURNS:        NC
;                         AX            Proc handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateProcSel   Proc far
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
    mov es:[edx].fm_update,0
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
    or ax,63h
    SetPageEntry
;
    mov eax,SIZE process_file
    AllocateBigLinear
;
    call CreateProcObj
    mov es,eax
;
    pop edx
    pop ebx
;
    xor eax,eax
    mov edi,SIZE pf_base
    mov ecx,SIZE process_file
    sub ecx,edi
    push ecx
    shr ecx,2
    rep stosd
    pop ecx
    and ecx,3
    rep stosb
;
    mov ecx,240
    mov es:pf_free_count,cl
;
    mov edi,OFFSET pf_free_arr
    mov al,cl
    dec al

cvmsLoop:
    stosb
    dec al
    loop cvmsLoop
;
    mov es:pf_flat_base,ebx
    mov es:pf_map_linear,edx
    mov es:pf_prog_sel,si
    mov es:pf_file_sel,ds
    mov es:pf_handle,0
    mov es:pf_ref_count,0
;
    mov es:hpi_create_proc,OFFSET CreateHandleSel
    mov es:hpi_create_proc+4,cs
;
    mov es:hpi_delete_proc,OFFSET DeleteProcSel
    mov es:hpi_delete_proc+4,cs
;
    push ds
    AllocateLdt
    pop ds
    or bx,4
    mov ecx,1000h
    mov edx,ebp
    CreateDataSelector32
    mov es:pf_map_sel,bx
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
CreateProcSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadKernelSel
;
;       DESCRIPTION:    Read kernel file
;
;       PARAMETERS:     DS              Kernel interface
;                       EDX:EAX         Position
;                       ES:EDI          Buffer
;                       ECX             Size
;
;       RETURNS:        ECX             Count
;                       EDX:EAX         New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadKernelSel    Proc far
    push ds
    push es
    push fs
    push ebx
    push esi
    push ebp
;
    push eax
    push edx
;
    movzx ebx,ds:hki_sys_sel
    mov fs,ds:hkf_map_sel
    xor esi,esi
    xor ebp,ebp
    call KernelRead
;
    pop edx
    pop eax
;
    add eax,ecx
    adc edx,0
    clc
;
    pop ebp
    pop esi
    pop ebx
    pop fs
    pop es
    pop ds
    ret
ReadKernelSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteKernelSel
;
;       DESCRIPTION:    Write kernel file
;
;       PARAMETERS:     DS              Kernel interface
;                       EDX:EAX         Position
;                       ES:EDI          Buffer
;                       ECX             Size
;
;       RETURNS:        ECX             Count
;                       EDX:EAX         New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteKernelSel    Proc far
    push ds
    push es
    push fs
    push ebx
    push esi
    push ebp
;
    push eax
    push edx
;
    movzx ebx,ds:hki_sys_sel
    mov fs,ds:hkf_map_sel
    xor esi,esi
    xor ebp,ebp
    call KernelWrite
;
    pop edx
    pop eax
;
    add eax,ecx
    adc edx,0
    clc
;
    pop ebp
    pop esi
    pop ebx
    pop fs
    pop es
    pop ds
    ret
WriteKernelSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteKernelSel
;
;       DESCRIPTION:    Delete kernel sel
;
;       PARAMETERS:     DS              Kernel interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteKernelSel  Proc far
    push ds
    push es
    pushad
;
    mov es,ds:hkf_map_sel
    mov ds,ds:hki_sys_sel
;
    mov ebx,OFFSET fm_sorted_arr
    mov ecx,240

dkmLoop:
    mov al,es:[ebx]
    cmp al,-1
    je dkmUnlink
;
    movzx esi,al
    add esi,OFFSET kfm_ref_arr
    movzx edi,al
    shl edi,4
    add edi,OFFSET fm_entry_arr    
    call CheckKernelDirtyMap
    call FreeKernelMap
    jmp dkmLoop

dkmNext:
    inc ebx
    loop dkmLoop

dkmUnlink:
    call UpdateKernelUnlinked
;
    FreeMem
;
    popad
    pop es
    pop ds
    ret
DeleteKernelSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateKernelSel
;
;       DESCRIPTION:    Create kernel sel
;
;       PARAMETERS:     DS              Sys handle sel
;
;       RETURNS:        NC
;                         AX            Kernel handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateKernelSel   Proc far
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,flat_sel
    mov es,eax
;
    mov eax,SIZE kernel_file_map
    AllocateBigLinear
    mov edi,edx
;
    mov eax,-1
    mov ecx,3Dh
    rep stosd
;
    xor eax,eax
    mov ecx,3C3h
    rep stosd
;
    mov ecx,SIZE kernel_file_map - 1000h
    rep stosb
;
    mov eax,ds:kf_info_linear
    mov es:[edx].fm_handle_ptr,eax
    mov es:[edx].fm_info_ptr,20h
    mov es:[edx].fm_update,0
;
    AllocateGdt
    mov ecx,SIZE kernel_file_map
    CreateDataSelector32
    mov es,bx
;
    mov ecx,240
    mov es:kfm_free_count,cl
;
    mov edi,OFFSET kfm_free_arr
    mov al,cl
    dec al

ckmLoop:
    stosb
    dec al
    loop ckmLoop
;
    mov eax,SIZE handle_kernel_file
    AllocateSmallLinear
;
    call CreateKernelObj
    mov es,eax
;
    mov es:hki_read_proc,OFFSET ReadKernelSel
    mov es:hki_read_proc+4,cs
;
    mov es:hki_write_proc,OFFSET WriteKernelSel
    mov es:hki_write_proc+4,cs
;
    mov es:hki_delete_proc,OFFSET DeleteKernelSel
    mov es:hki_delete_proc+4,cs
;
    mov es:hkf_map_linear,edx
    mov es:hkf_map_sel,bx
;
    mov eax,es
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CreateKernelSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteSysSel
;
;       DESCRIPTION:    Delete sys sel
;
;       PARAMETERS:     DS              Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteSysSel   Proc far
    push ds
    push es
    push fs
    pushad
;
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
DeleteSysSel   Endp

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
;                         AX           Sys interface
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
    mov eax,SIZE kernel_file
    call CreateSysObj
;
    mov ds:hsi_create_proc_proc,OFFSET CreateProcSel
    mov ds:hsi_create_proc_proc+4,cs
;
    mov ds:hsi_create_kernel_proc,OFFSET CreateKernelSel
    mov ds:hsi_create_kernel_proc+4,cs
;
    mov ds:hsi_delete_proc, OFFSET DeleteSysSel
    mov ds:hsi_delete_proc+4,cs
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
;           NAME:           InsertSysArr
;
;           DESCRIPTION:    Insert new file into sys array
;
;           PARAMETERS:     AX          Sys interface
;                           
;           RETURNS:        NC          Added to list
;                           CY          Already in list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertSysArr    Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov ebx,SEG data
    mov ds,ebx
    EnterSection ds:sys_section
;
    mov ecx,SYS_HANDLE_COUNT
    mov ebx,OFFSET sys_handle_arr

isaLoop:
    mov dx,ds:[ebx+ecx]
    or dx,dx
    jz isaNext
;
    cmp dx,ax
    je isaFound
    ja isaNext
;
    add ebx,ecx

isaNext:
    shr ecx,1
    test cl,1
    jz isaLoop
;
    mov dx,ds:[ebx]
    or dx,dx
    jz isaInsert
;
    cmp dx,ax
    je isaFound
    ja isaInsert
;
    add ebx,2

isaInsert:
    xchg ax,ds:[ebx]
    add ebx,2
    or ax,ax
    jnz isaInsert
;
    clc
    jmp isaLeave

isaFound:
    stc

isaLeave:
    LeaveSection ds:sys_section
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
InsertSysArr    Endp

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
;           RETURNS:        DS          Sys handle obj
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public OpenVfsFile

OpenVfsFile    Proc near
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
    call InsertSysArr
;
    mov ds,eax
    EnterSection ds:hsi_section
;
    mov ebx,ds:hsi_index
    or ebx,ebx
    jz ovfNew
;
    call SendDerefReq
    jmp ovfHandleOk

ovfNew:
    call AllocateLocalSysHandle
    mov ds:hsi_index,ebx

ovfHandleOk:
    LeaveSection ds:hsi_section
;
    clc
    jmp ovfDone

ovfFail:
    xor eax,eax
    mov ds,eax
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
    ret
OpenVfsFile   Endp

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
    mov es,ebx
    InitSection es:sys_section
;
    mov edi,OFFSET sys_handle_arr
    mov ecx,SYS_HANDLE_COUNT
    xor ax,ax
    rep stosw
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
