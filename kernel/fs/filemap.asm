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
INCLUDE ..\os\blk.inc
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

kre_block_arr     DD ?
kre_phys_arr      DD ?
kre_next          DD ?
kre_pages         DW ?
kre_usage         DW ?

kernel_req_entry  ENDS

kernel_wait_entry  STRUC

kwe_next          DD ?
kwe_thread        DW ?

kernel_wait_entry  ENDS

kernel_file       STRUC

kf_blk            blk_header <>

kf_info_phys      DD ?,?
kf_sector_size    DW ?
kf_section        section_typ <>
kf_map_list       DW ?
kf_part_sel       DW ?
kf_serv_sel       DW ?
kf_update_count   DW ?
kf_req_sync       DW ?
kf_resv           DW ?
kf_serv_handle    DD ?
kf_wait_list      DD ?
kf_handle_arr     DD 240 DUP(?)
kf_update_arr     DD 32 DUP(?)

kernel_file       ENDS

kernel_file_map   STRUC

kfm_flat_base     DD ?
kfm_user_base     DD ?
kfm_prog_sel      DW ?
kfm_file_sel      DW ?
kfm_kernel_sel    DW ?
kfm_next_map      DW ?
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
;                       ECX            Req block linear
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
    mov ds:kf_sector_size,di
    mov ds:kf_map_list,0
    mov ds:kf_part_sel,fs
    mov ds:kf_serv_handle,ebx
    mov ds:kf_wait_list,0
    mov ds:kf_update_count,0
    mov ds:kf_req_sync,0
;
    push ecx
;
    mov ecx,256
    mov edi,OFFSET kf_handle_arr
    mov eax,-1

cfInit:
    mov ds:[edi],eax
    add edi,4
    loop cfInit
;
    GetPageEntry
    or ax,800h
    SetPageEntry
;
    and ax,0F000h
    mov ds:kf_info_phys,eax
    mov ds:kf_info_phys+4,ebx
;
    pop edx
    GetPageEntry
    or ax,800h
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector32
    mov ds:kf_serv_sel,bx
;
    mov ax,ds
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
CreateFileSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddFileReq
;
;       DESCRIPTION:    Serv add VFS file req
;
;       PARAMETERS:     FS             Part sel
;                       EBX            File handle
;                       EDX            Req index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddFileReq

AddFileReq   Proc near
    push ds
    push es
    pushad
;
    movzx eax,bx
    dec eax
    shl eax,2
    mov ax,fs:[eax].vfsp_file_arr.ff_sel
    or ax,ax
    stc
    je afrDone
;
    or edx,edx
    stc
    jz afrDone
;
    mov ds,eax
    mov es,ds:kf_serv_sel
    EnterSection ds:kf_section
;
    mov esi,edx
    dec esi
    mov edi,esi
    shl edi,2
    shl esi,4
    add esi,OFFSET frs_arr
;
    mov cx,SIZE kernel_req_entry
    AllocateBlk
    mov ds:[edi].kf_handle_arr,edx
    mov ds:[edx].kre_pages,0
    mov ds:[edx].kre_block_arr,0
    mov ds:[edx].kre_phys_arr,0
    mov ds:[edx].kre_usage,0
;
    mov ebx,OFFSET frs_sorted
    inc es:frs_count
    mov ebp,es:frs_count
    sub ebp,1
    jbe afrInsert
 
afrFind:
    movzx ecx,byte ptr es:[ebx]
    shl ecx,4
    mov eax,es:[esi].fre_pos
    mov edx,es:[esi].fre_pos+4
    sub eax,es:[ecx].frs_arr.fre_pos
    sbb edx,es:[ecx].frs_arr.fre_pos+4
    jb afrInsert
    jnz afrNext
;
    cmp eax,es:[ecx].frs_arr.fre_size
    jb afrInsert

afrNext:
    inc ebx
    sub ebp,1
    jnz afrFind

afrInsert:
    sub ebx,OFFSET frs_sorted
    mov eax,ebx
    mov ecx,es:frs_count
    dec ecx
    sub ecx,eax
;
    mov ebx,esi
    sub ebx,OFFSET frs_arr
    shr ebx,4
    lea esi,[eax+ecx].frs_sorted
    mov edi,esi
    dec esi
    or ecx,ecx
    jz afrSave

afrMove:
    mov al,es:[esi]
    mov es:[edi],al
    dec esi
    dec edi
    loop afrMove

afrSave:
    mov es:[edi],bl
    LeaveSection ds:kf_section
    clc

afrDone:
    popad
    pop es
    pop ds
    ret
AddFileReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddUpdate
;
;       DESCRIPTION:    Add to update
;
;       PARAMETERS:     DS             File sel
;                       EBX            Req offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddUpdate     Proc near
    push fs
    push ebx
    push ecx
    push esi
;
    mov esi,OFFSET kf_update_arr
    movzx ecx,ds:kf_update_count
    cmp ecx,32
    jb auNoOv
;
    int 3

auNoOv:
    or ecx,ecx
    jz auIns

auCheck:
    cmp ebx,ds:[esi]
    je auDone
;
    add esi,4
    loop auCheck

auIns:
    movzx esi,ds:kf_update_count
    mov ds:[4*esi].kf_update_arr,ebx
    inc ds:kf_update_count
;
    or esi,esi
    jnz auDone
;
    mov fs,ds:kf_part_sel
    mov ebx,ds:kf_serv_handle
    dec ebx
    cmp ebx,MAX_VFS_FILE_COUNT
    jae auDone
;
    mov esi,OFFSET vfsp_file_update_map
    bts fs:[esi],ebx
    jc auDone
;
    mov al,1
    xchg al,fs:vfsp_update_req
    or al,al
    jnz auDone
;
    mov bx,fs:vfsp_cmd_thread
    Signal

auDone:
    pop esi
    pop ecx
    pop ebx
    pop fs
    ret
AddUpdate   Endp

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
    push es
    push ecx
    push esi
    push edi
    push ebp
;
    mov es,ds:kf_serv_sel
    mov ebp,es:frs_count
    or ebp,ebp
    stc
    jz frDone
;
    mov ebx,OFFSET frs_sorted
 
frLoop:
    movzx ecx,byte ptr es:[ebx]
    shl ecx,4
    mov esi,eax
    mov edi,edx
    sub esi,es:[ecx].frs_arr.fre_pos
    sbb edi,es:[ecx].frs_arr.fre_pos+4
    jb frDone
    jnz frNext
;
    cmp esi,es:[ecx].frs_arr.fre_size
    jae frNext
;
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
    pop es
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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddWaitReq      Proc near
    push eax
    push ecx
    push edx
;
    ClearSignal
    mov cx,SIZE kernel_wait_entry
    AllocateBlk
;
    GetThread
    mov ds:[edx].kwe_thread,ax
    mov eax,ds:kf_wait_list
    mov ds:[edx].kwe_next,eax
    mov ds:kf_wait_list,edx
;
    pop edx
    pop ecx
    pop eax
    ret
AddWaitReq  Endp

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

SendReadReq     Proc near
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
    push eax
    push ebx
;
    mov ebx,ds:kf_serv_handle
    dec ebx
    mov fs,ds:kf_part_sel
    mov ds,fs:vfsp_disc_sel
    call AllocateMsg
;
    mov eax,VFS_CLOSE_FILE
    call PostMsg
;
    pop ebx
    pop eax
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
;       NAME:           MergeReq
;
;       DESCRIPTION:    Merge req with previous req
;
;       PARAMETERS:     DS                 File sel
;                       FS                 Part sel
;                       EBX                Req index
;                       ECX                Buffered blocks
;                       GS:ESI             Sector array
;
;       RETURNS:        ECX                Remaining blocks
;                       GS:ESI             Sector array
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mr_struc   STRUC

mrs_prev_index    DB ?
mrs_curr_index    DB ?
mrs_count         DW ?
mrs_pos           DD ?
mrs_blocks        DD ?
mrs_offset        DD ?
mrs_ptr           DD ?

mr_struc   ENDS

MergeReq  Proc near
    push ds
    push es
    push fs
    push eax
    push ebx
    push edx
    push edi
    push ebp
;
    sub esp,SIZE mr_struc
    mov ebp,esp
;
    mov es,ds:kf_serv_sel
    mov [ebp].mrs_blocks,ecx
    mov [ebp].mrs_pos,esi
    mov [ebp].mrs_count,0
;
    mov ecx,es:frs_count
    or ecx,ecx
    jz mrrDone
;
    mov edi,OFFSET frs_sorted
    cmp bl,es:[edi]
    je mrrDone
;
    inc edi
    sub ecx,1
    jz mrrDone

mrrFind:
    cmp bl,es:[edi]
    je mrrFound
;
    inc edi
    loop mrrFind
;
    int 3
    jmp mrrDone

mrrFound:
    mov [ebp].mrs_curr_index,bl
    mov al,es:[edi-1]
    mov [ebp].mrs_prev_index,al
;
    movzx edi,al
    shl edi,4
    add edi,OFFSET frs_arr
;
    movzx ebx,bl
    shl ebx,4
    add ebx,OFFSET frs_arr
;
    mov eax,es:[ebx].fre_pos
    mov edx,es:[ebx].fre_pos+4
    sub eax,es:[edi].fre_pos
    sbb edx,es:[edi].fre_pos+4
    or edx,edx
    jnz mrrDone
;
    cmp eax,es:[edi].fre_size
    jnz mrrDone
;
    movzx edi,[ebp].mrs_prev_index
    mov edi,ds:[4*edi].kf_handle_arr
    mov edx,ds:[edi].kre_phys_arr
    mov edx,ds:[edx]
    add edx,eax
    and edx,0FFFh
    mov [ebp].mrs_offset,edx
    jz mrrDone
;
    movzx edx,ds:[edi].kre_pages
    dec edx
    shl edx,3
    add edx,ds:[edi].kre_phys_arr
    mov [ebp].mrs_ptr,edx
;
    push ds
    mov ds,fs:vfsp_disc_sel
    mov ax,serv_flat_sel
    mov es,eax
    pop fs

mrrLoop:
    mov esi,[ebp].mrs_pos
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jc mrrUpdate
;
    test ax,0FFFh
    jz mrrUpdate
;
    mov esi,[ebp].mrs_ptr
    sub eax,fs:[esi]
    sbb edx,fs:[esi+4]
    jnz mrrUpdate
;
    cmp eax,[ebp].mrs_offset
    jne mrrUpdate
;
    add [ebp].mrs_count,200h
    add [ebp].mrs_pos,8
    sub [ebp].mrs_blocks,1
    jz mrrUpdate
;
    add eax,200h
    test eax,0FFFh
    jz mrrUpdate
;
    mov [ebp].mrs_offset,eax
    jmp mrrLoop

mrrUpdate:
    movzx eax,[ebp].mrs_count
    or eax,eax
    jz mrrDone
;
    mov ds,fs:kf_serv_sel
    movzx ebx,[ebp].mrs_curr_index
    shl ebx,4
    add ds:[ebx].frs_arr.fre_pos,eax
    adc ds:[ebx].frs_arr.fre_pos+4,0
;
    movzx ebx,[ebp].mrs_prev_index
    shl ebx,4
    add ds:[ebx].frs_arr.fre_size,eax

mrrDone:
    mov ecx,[ebp].mrs_blocks
    mov esi,[ebp].mrs_pos
    add esp,SIZE mr_struc
;
    pop ebp
    pop edi
    pop edx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
MergeReq  Endp

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
    push es
    push eax
    push ebx
    push ecx
    push edx
;
    shl ecx,9
    mov es,ds:kf_serv_sel
    mov edx,ebx
    shl edx,4
    mov es:[edx].frs_arr.fre_size,ecx
;
    mov ebx,ds:[4*ebx].kf_handle_arr
    mov ds:[ebx].kre_pages,ax
    mov cx,ax
    shl cx,2
    AllocateBlk
    mov ds:[ebx].kre_block_arr,edx
;
    shl cx,1
    AllocateBlk
    mov ds:[ebx].kre_phys_arr,edx
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
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
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignalReadReq  Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    xor edx,edx
    xchg edx,ds:kf_wait_list
    
srrLoop:
    or edx,edx
    jz srrDone
;
    mov eax,ds:[edx].kwe_next
    mov bx,ds:[edx].kwe_thread
    Signal
;
    mov cx,SIZE kernel_wait_entry
    FreeBlk
;
    mov edx,eax
    jmp srrLoop

srrDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
SignalReadReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UpdateReq
;
;       DESCRIPTION:    Update req
;
;       PARAMETERS:     DS                 File sel
;                       ES                 Serv flat sel
;                       FS                 Part sel                       
;                       GS                 Disc sel
;                       EBX                Req offset
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateReq  Proc near
    pushad
;
    mov ax,ds:[ebx].kre_usage
    or ax,ax
    jnz urDone

urFree:
    mov ebp,ebx
    int 3
;    mov ecx,ds:[ebx].kre_size
    mov edi,ds:[ebx].kre_block_arr
    mov edx,ds:[ebx].kre_phys_arr
    mov edx,ds:[edx]
    and edx,0FFFh
    shr edx,9
    mov eax,8
    sub eax,edx

urFreeLoop:
    shl eax,9
    cmp ecx,eax
    jae urFreeAll
;
    mov eax,ecx

urFreeAll:
    sub ecx,eax
    shr eax,9
;    
    mov esi,ds:[edi]
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz urFreeNext
;
    sub es:[esi].vfsp_ref_bitmap,ax
    jnc urOk
;
    int 3

urOk:
    jnz urFreeNext
;
    dec gs:vfs_locked_pages

urFreeNext:
    or ecx,ecx
    jz urFreeEntry
;
    add edi,4
    mov eax,8
    jmp urFreeLoop

urFreeEntry:
    mov ebx,ebp
    mov cx,ds:[ebx].kre_pages
    shl cx,2
    mov edx,ds:[ebx].kre_block_arr
    FreeBlk
;
    shl cx,1
    mov edx,ds:[ebx].kre_phys_arr
    FreeBlk
;
    mov edx,ebp
    mov cx,SIZE kernel_req_entry
    FreeBlk

urDone:
    popad
    ret
UpdateReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockReq
;
;       DESCRIPTION:    Lock req
;
;       PARAMETERS:     GS             File sel
;                       EDX:EAX        Req position
;
;       RETURNS:        EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockReq      Proc near
    push ds
    push eax
    push ecx
;
    mov ebx,gs
    mov ds,ebx
;
    EnterSection ds:kf_section
    call FindReq
    jc lrLeave
;
    mov eax,ds:[4*ebx].kf_handle_arr
    mov ecx,ds:[eax].kre_phys_arr
    or ecx,ecx
    stc
    jz lrLeave
;
    inc ds:[eax].kre_usage
    clc

lrLeave:
    LeaveSection ds:kf_section
;
    pop ecx
    pop eax
    pop ds
    ret
LockReq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IssueReq
;
;       DESCRIPTION:    Issue req
;
;       PARAMETERS:     FS             Kernel process sel
;                       GS             File sel
;                       BX             Handle
;                       EDX:EAX        Req position
;                       ECX            Req size
;
;       RETURNS:        EBX            Req id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueReq      Proc near
    push ds
    push esi
    push edi
;
    mov esi,gs
    mov ds,esi

irRetry:
    EnterSection ds:kf_section
    call FindReq
    jnc irCheck
;
    call AddWaitReq
    call SendReadReq
;
    LeaveSection ds:kf_section
;
    call UpdateMap
    WaitForSignal
    jmp irRetry

irCheck:
    mov esi,ds:[4*ebx].kf_handle_arr
    mov esi,ds:[esi].kre_phys_arr
    or esi,esi
    jnz irLeave
;
    call AddWaitReq
    LeaveSection ds:kf_section
    WaitForSignal
    jmp irRetry

irLeave:
    inc ds:[ebx].kre_usage
    LeaveSection ds:kf_section
;
    pop edi
    pop esi
    pop ds
    ret
IssueReq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeReq
;
;       DESCRIPTION:    Free req
;
;       PARAMETERS:     GS             File sel
;                       EBX            Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeReq      Proc near
    int 3
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
    push ds
    push eax
    push ebx
;
    mov ax,flat_data_sel
    mov ds,eax
    mov ebx,es:fm_handle_ptr
    lock inc ds:[ebx].fh_lock_count
;
    pop ebx
    pop eax
    pop ds
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
    push ds
    push eax
    push ebx
;
    mov ax,flat_data_sel
    mov ds,eax
    mov ebx,es:fm_handle_ptr
    lock dec ds:[ebx].fh_lock_count
;
    pop ebx
    pop eax
    pop ds
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
;                       EDI            Src pointer            
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
;
    mov eax,ecx
    shl eax,12
    AllocateLocalLinear
;
    push ebx
    push edx
    push esi

meLoop:
    mov eax,gs:[esi]
    mov ebx,gs:[esi+4]
    and ax,0F000h
    or ax,807h
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
;
    mov ecx,es:fm_count
    movzx ebx,bx
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
    pop ecx
    pop ebx
    pop eax
    ret
FreeMap Endp

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
    push ecx
    push edx
    push ebp
;
    push ebx
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

cmLoop:
    GetPageEntry
    test ax,60h
    jz cmNext
;
    or bp,ax
    and al,NOT 60h
    SetPageEntry

cmNext:
    add edx,1000h
    loop cmLoop
;
    pop ebx
;
    mov ax,bp
    and al,60h
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
    pop ebp
    pop edx
    pop ecx
    pop eax
    ret
CheckMap  Endp

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
    mov eax,fs:[ebx].fh_lock_count
    or eax,eax
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
    mov ecx,240
    EnterSection ds:kfm_section

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
    push fs
    pushad
;
    mov fs,gs:kf_serv_sel
    mov edi,ebx
    shl edi,4
    add edi,OFFSET frs_arr
    mov eax,fs:[edi].fre_pos
    mov edx,fs:[edi].fre_pos+4
    mov ecx,fs:[edi].fre_size
;
    mov ebx,gs:[4*ebx].kf_handle_arr
    mov edi,ebx
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
    dec gs:[edi].kre_usage
    mov es:[ebx].fm_entry_arr.fmb_size,ecx
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
    pop fs
    ret
SyncMap  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteMap
;
;       DESCRIPTION:    Delete all mapped requests
;
;       PARAMETERS:     DS             Kernel processes
;                       GS             File sel
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
;       NAME:           MapReq
;
;       DESCRIPTION:    Map req
;
;       PARAMETERS:     DS             Kernel processes
;                       ES             Kernel mapping sel
;                       GS             File sel
;                       BX             Handle
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapReq      Proc near
    push es
    push fs
    push gs
    pushad
;
    mov esi,ds
    mov fs,esi
    mov es,ds:kfm_kernel_sel
    mov gs,ds:kfm_file_sel
;
    EnterSection ds:kfm_section
    push ecx
    call FindReadMap
    pop ecx
    LeaveSection ds:kfm_section
    jnc mrDone
;
    call LockReq
    jc mrIssue
;
    call SyncMap
    jmp mrDone

mrIssue:
    call IssueReq
    call SyncMap
    jnc mrDone
;
    push ds
    mov ds,gs:kf_serv_sel
    mov esi,ebx
    shl esi,4
    add esi,OFFSET frs_arr
    mov eax,ds:[esi].fre_pos
    mov edx,ds:[esi].fre_pos+4
    add eax,ds:[esi].fre_size
    adc edx,0
    pop ds
;
    call LockReq
    jc mrDone
;
    call SyncMap

mrDone:
    popad
    pop gs
    pop fs
    pop es
    ret
MapReq   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProgSel
;
;       DESCRIPTION:    Get program selector
;
;       PARAMETERS:     DS              File sel
;
;       RETURNS:        NC
;                         AX            Prog sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetProgSel      Proc near
    push es
    push ebx
;
    GetThread
    mov es,ax
    mov bx,es:p_prog_sel
;
    EnterSection ds:kf_section
    mov ax,ds:kf_map_list

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
;       NAME:           UnlinkProgSel
;
;       DESCRIPTION:    Unlink program selector
;
;       PARAMETERS:     DS              File sel
;                       AX              Prog sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkProgSel      Proc near
    push es
    push eax
    push edx
;
    mov dx,ax
;
    xor ax,ax
    mov es,eax
    mov ax,ds:kf_map_list

upsLoop:
    or ax,ax
    stc
    jz upsDone
;
    cmp dx,ax
    je upsUnlink
;
    mov es,eax
    mov ax,es:kfm_next_map
    jmp upsLoop

upsUnlink:
    mov ax,es
    or ax,ax
    jz upsRoot
;
    push es
    mov es,edx
    mov ax,es:kfm_next_map
    pop es
    mov es:kfm_next_map,ax
    jmp upsDone

upsRoot:
    mov es,edx
    mov ax,es:kfm_next_map
    mov ds:kf_map_list,ax

upsDone:
    pop edx
    pop eax
    pop es
    ret
UnlinkProgSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateProgSel
;
;       DESCRIPTION:    Create program selector
;
;       PARAMETERS:     DS              File sel
;
;       RETURNS:        NC
;                         AX            Prog sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateProgSel   Proc near
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

cpsLoop:
    stosb
    dec al
    loop cpsLoop
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
    mov bx,ds:kf_map_list
    mov es:kfm_next_map,bx
    mov ds:kf_map_list,es
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
;       NAME:           DeleteProgSel
;
;       DESCRIPTION:    Delete program selector
;
;       PARAMETERS:     DS              File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteProgSel   Proc near
    push es
    push eax
    push ecx
    push edx
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
    pop eax
    pop es
    ret
DeleteProgSel      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocateUserHandle
;
;       DESCRIPTION:    Allocate user handle
;
;       PARAMETERS:     DS              Prog sel
;
;       RETURNS:        NC
;                         BX            User handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateUserHandle      Proc near
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
;       NAME:           FreeUserHandle
;
;       DESCRIPTION:    Free user handle
;
;       PARAMETERS:     DS              Prog sel
;                       BX              Handle    
;
;       RETURNS:        CY              No more open handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeUserHandle      Proc near
    push es
    push eax
    push ecx
    push edx
;
    or bx,bx
    clc
    jz fuhDone
;
    mov dx,flat_data_sel
    mov es,edx
    mov edx,ds:kfm_user_base
    mov edx,es:[edx].fm_handle_ptr
    add edx,OFFSET fh_bitmap
;
    dec bx
    movzx ebx,bx
    lock btc es:[edx],ebx
;
    mov ecx,15

fuhLoop:
    mov eax,es:[edx]
    or eax,eax
    clc
    jnz fuhDone
;
    add edx,4
    loop fuhLoop
;
    stc

fuhDone:
    pop edx
    pop ecx
    pop eax
    pop es
    ret
FreeUserHandle      Endp

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
    stc
    jz nfdDone
;
    mov ds,ebx
    mov es,ds:kf_serv_sel
    mov ebx,gs:vfs_rd_index
    or ebx,ebx
    stc
    je nfdDone
;
    EnterSection ds:kf_section
;
    mov eax,ebx
    dec ebx
    mov esi,ebx
    shl esi,4
    xchg eax,es:[esi].frs_arr.fre_handle
    cmp eax,-1
    jne nfdLeave
;
    mov esi,gs:vfs_rd_chain_ptr
    call MergeReq
;
    call CalcPageCount
    call SetupReadReq
    call ProcessReadReq
    call SignalReadReq

nfdLeave:
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
;       NAME:           NotifyFileUpdate
;
;       DESCRIPTION:    Notify file data
;
;       PARAMETERS:     DS                 File sel
;                       FS                 Part sel                       
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NotifyFileUpdate

NotifyFileUpdate  Proc near
    push es
    push gs
    pushad
;
    mov ax,serv_flat_sel
    mov es,eax
    mov gs,fs:vfsp_disc_sel
    EnterSection ds:kf_section
;
    mov esi,OFFSET kf_update_arr
    movzx ecx,ds:kf_update_count
    or ecx,ecx
    jz nfuReset

nfuLoop:
    mov ebx,ds:[esi]
    call UpdateReq
    add esi,4
    loop nfuLoop

nfuReset:
    mov ds:kf_update_count,0
;
    mov ax,ds:kf_map_list
    or ax,ax
    jnz nfuLeave
;
    call SendCloseReq
    jmp nfuDone

nfuLeave:
    LeaveSection ds:kf_section

nfuDone:
    popad
    pop gs
    pop es
    ret
NotifyFileUpdate  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           vfs_file_info
;
;       DESCRIPTION:    VFS file info
;
;       PARAMETERS:     BX             Handle
;
;       RETURNS:        EAX            Handle #
;                       EDI            File info base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vfs_file_info_name       DB 'VFS File Info',0
 
vfs_file_info   Proc far
    push ds
    push ebx
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jc vfiDone
;
    movzx eax,ds:[ebx].fh_handle
    mov ds,ds:[ebx].fh_sel
    mov edi,ds:kfm_user_base
    clc

vfiDone:
    pop ebx
    pop ds
    ret
vfs_file_info   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           map_vfs_file
;
;       DESCRIPTION:    Map VFS file
;
;       PARAMETERS:     BX             Handle
;                       EDX:EAX        Position
;                       ECX            Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_vfs_file_name       DB 'Map VFS File',0
 
map_vfs_file   Proc far
    push ds
    push es
    push gs
    pushad
;
    push eax
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    pop eax
    jc mvfDone
;
    mov si,ds:[ebx].fh_sel
    mov bx,ds:[ebx].fh_handle
    mov ds,esi
    call MapReq

mvfDone:
    popad
    pop gs
    pop es
    pop ds
    ret
map_vfs_file    Endp

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
;       NAME:           close_vfs_file
;
;       DESCRIPTION:    Close VFS file
;
;       PARAMETERS:     DS             Prog sel
;                       BX             Map Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_vfs_file  Proc near
    push ds
    mov ds,ds:kfm_file_sel
    EnterSection ds:kf_section
    pop ds
;
    call FreeUserHandle
    jnc cvfLeaveFile
;
    push ds
    mov ax,ds
    mov ds,ds:kfm_file_sel
    call UnlinkProgSel
    LeaveSection ds:kf_section
    pop ds
;
    call DeleteMap
    call DeleteProgSel
    jmp cvfDone

cvfLeaveFile:
    push ds
    mov ds,ds:kfm_file_sel
    LeaveSection ds:kf_section
    pop ds

cvfDone:
    ret
close_vfs_file  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           close_vfs_file
;
;       DESCRIPTION:    Close file
;
;       PARAMETERS:     BX             Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_file_name       DB 'Close VFS File',0

org_close DD ?,?

close_file  Proc far
    push ds
    push eax
    push ebx
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jnc cVfs
;
    pop ebx
    pop eax
    pop ds
    jmp fword ptr cs:org_close

cVfs:
    mov ax,ds:[ebx].fh_sel
    mov bx,ds:[ebx].fh_handle
    mov ds,eax
    call close_vfs_file
;
    pop ebx
    pop eax
    pop ds
    ret
close_file  Endp

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
;                       BP             File handle
;
;       RETURNS:        NC
;                         EAX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_vfs_file  Proc near
    push edx
;    
    int 3
    call GetPos

rvfRetry:
    push ecx
    mov es,ds:kfm_kernel_sel
    call FindReadMap
    pop ecx
    jnc rvfDo
;
    push ebx
    mov bx,bp
    MapVfsFile
    pop ebx
    jnc rvfRetry

rvfDo:
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
    push ecx
    push edi
;
    push ds
    push ebx
    push ebp
;
    movzx ecx,cx
    movzx edi,di
    mov bp,bx
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jnc rVfs16
;
    pop ebp
    pop ebx
    pop ds
;
    call fword ptr cs:org_read
;
    pop edi
    pop ecx
    ret

rVfs16:
    mov ax,ds:[ebx].fh_sel
    mov bx,ds:[ebx].fh_handle
    mov ds,eax
    call read_vfs_file
;
    pop ebp
    pop ebx
    pop ds
;
    pop edi
    pop ecx
    ret
read_file16  Endp

read_file32  Proc far
    push ds
    push ebx
    push ebp
;
    mov bp,bx
;
    mov ax,VFS_FILE_HANDLE
    DerefHandle
    jnc rVfs32
;
    pop ebp
    pop ebx
    pop ds
    jmp fword ptr cs:org_read

rVfs32:
    mov ax,ds:[ebx].fh_sel
    mov bx,ds:[ebx].fh_handle
    mov ds,eax
    call read_vfs_file
;
    pop ebp
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
    mov ax,ds:[ebx].fh_sel
    mov bx,ds:[ebx].fh_handle
    mov ds,eax
    call close_vfs_file
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
    mov ebx,OFFSET close_file
    mov esi,OFFSET close_file
    mov edi,OFFSET close_file_name
    xor dx,dx
    mov ax,close_file_nr
    LinkUserGate
    mov dword ptr fs:org_close,eax
    mov word ptr fs:org_close+4,dx
;
    mov esi,OFFSET vfs_file_info
    mov edi,OFFSET vfs_file_info_name
    xor dx,dx
    mov ax,vfs_file_info_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET map_vfs_file
    mov edi,OFFSET map_vfs_file_name
    xor dx,dx
    mov ax,map_vfs_file_nr
    RegisterBimodalUserGate
;
    mov ebx,fs
    xor eax,eax
    mov fs,eax
    FreeGdt    
    ret
init_client_file    Endp

code    ENDS

    END
