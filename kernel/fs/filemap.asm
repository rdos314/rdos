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

kre_pos           DD ?,?
kre_size          DD ?
kre_sector_arr    DD ?
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
kf_update_count   DW ?
kf_req_sync       DW ?
kf_count          DD ?
kf_serv_handle    DD ?
kf_wait_list      DD ?
kf_sorted_arr     DD 256 DUP(?)
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
;                       CX             Sector size
;                       EDX            File info linear
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
    mov ds:kf_sector_size,cx
    mov ds:kf_map_list,0
    mov ds:kf_part_sel,fs
    mov ds:kf_count,0
    mov ds:kf_serv_handle,ebx
    mov ds:kf_wait_list,0
    mov ds:kf_update_count,0
    mov ds:kf_req_sync,0
;
    mov ecx,256
    mov edi,OFFSET kf_sorted_arr
    xor eax,eax

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
;       NAME:           FindReadReq
;
;       DESCRIPTION:    Find a read req. Section must be taken!
;
;       PARAMETERS:     DS             File sel
;                       EDX:EAX        Position
;
;       RETURNS:        EBX            Req offset
;                       ECX            Sort index
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindReadReq     Proc near
    push esi
    push edi
    push ebp
;
    mov ebp,80h
    mov ebx,OFFSET kf_sorted_arr
 
frrLoop:
    lea ebx,[ebx+4*ebp]
;
    mov ecx,ds:[ebx]
    or ecx,ecx
    jz frrLower
;
    mov esi,eax
    mov edi,edx
    sub esi,ds:[ecx].kre_pos
    sbb edi,ds:[ecx].kre_pos+4
    jb frrLower
    jnz frrHigher
;
    cmp esi,ds:[ecx].kre_size
    jae frrHigher
;
    xchg ebx,ecx
    sub ecx,OFFSET kf_sorted_arr
    shr ecx,2
    clc
    jmp frrDone

frrLower:
    lea ecx,[4*ebp]
    sub ebx,ecx

frrHigher:
    or ebp,ebp
    stc
    jz frrDone
;
    shr ebp,1
    jmp frrLoop

frrDone:
    pop ebp
    pop edi
    pop esi
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
;       RETURNS:        EBX            Req offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddReadReq      Proc near
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov esi,ds:kf_count
    cmp esi,100h
    stc
    je arrDone
;
    push ecx
    push edx
;
    mov cx,SIZE kernel_req_entry
    AllocateBlk
    mov esi,edx
;
    pop edx
    pop ecx
;
    mov ds:[esi].kre_pos,eax
    mov ds:[esi].kre_pos+4,edx
    mov ds:[esi].kre_size,ecx
    mov ds:[esi].kre_pages,0
    mov ds:[esi].kre_sector_arr,0
    mov ds:[esi].kre_phys_arr,0
    mov ds:[esi].kre_usage,0
;
    mov ebp,128
    mov ebx,OFFSET kf_sorted_arr
 
arrFind:
    lea ebx,[ebx+4*ebp]
;
    mov ecx,ds:[ebx]
    or ecx,ecx
    jz arrLower
;
    mov eax,ds:[ecx].kre_pos
    mov edx,ds:[ecx].kre_pos+4
    sub eax,ds:[esi].kre_pos
    sbb edx,ds:[esi].kre_pos+4
    jc arrHigher

arrLower:
    lea ecx,[4*ebp]
    sub ebx,ecx

arrHigher:
    shr ebp,1
    jnz arrFind

arrInsert:
    sub ebx,OFFSET kf_sorted_arr
;
    mov ecx,ds:[ebx].kf_sorted_arr
    or ecx,ecx
    jz arrFound
;
    mov eax,ds:[ecx].kre_pos
    mov edx,ds:[ecx].kre_pos+4
    sub eax,ds:[esi].kre_pos
    sbb edx,ds:[esi].kre_pos+4
    jnc arrCheckDown
;
    add ebx,4
    jmp arrFound

arrCheckDown:
    or ebx,ebx
    jz arrFound
;
    sub ebx,4
    mov ecx,ds:[ebx].kf_sorted_arr
    or ecx,ecx
    jz arrFound
;
    mov eax,ds:[ecx].kre_pos
    mov edx,ds:[ecx].kre_pos+4
    sub eax,ds:[esi].kre_pos
    sbb edx,ds:[esi].kre_pos+4
    jc arrFound
;
    add ebx,4

arrFound:
    mov eax,ebx
    shr eax,2
    mov ecx,ds:kf_count
    sub ecx,eax
    mov ebx,esi
    add eax,ecx
    lea esi,[4*eax].kf_sorted_arr
    mov edi,esi
    sub esi,4
    or ecx,ecx
    jz arrSave

arrMove:
    mov eax,ds:[esi]
    mov ds:[edi],eax
    sub esi,4
    sub edi,4
    loop arrMove

arrSave:
    mov ds:[edi],ebx
    inc ds:kf_count
    clc

arrDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
AddReadReq      Endp

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
;       NAME:           MergeReadReq
;
;       DESCRIPTION:    Merge read req with previous req
;
;       PARAMETERS:     DS                 File sel
;                       FS                 Part sel
;                       EBX                Req offset
;                       ECX                Buffered blocks
;                       EBP                Req index
;                       GS:ESI             Sector array
;
;       RETURNS:        ECX                Remaining blocks
;                       GS:ESI             Sector array
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MergeReadReq  Proc near
    push ds
    push es
    push eax
    push ebx
    push edx
    push edi
    push ebp
    sub esp,4
;
    or ebp,ebp
    jz mrrDone
;
    mov edi,ebp
    dec edi
    mov edi,ds:[4*edi].kf_sorted_arr
;
    mov eax,ds:[ebx].kre_pos
    mov edx,ds:[ebx].kre_pos+4
    sub eax,ds:[edi].kre_pos
    sbb edx,ds:[edi].kre_pos+4
    or edx,edx
    jnz mrrDone
;
    cmp eax,ds:[edi].kre_size
    jnz mrrDone
;
    mov edx,ds:[edi].kre_phys_arr
    mov edx,ds:[edx]
    add edx,eax
    and edx,0FFFh
    mov [esp],edx
    jz mrrDone
;
    movzx edx,ds:[edi].kre_pages
    dec edx
    shl edx,3
    add edx,ds:[edi].kre_phys_arr
    mov ebp,edx
;
    mov eax,ds
    mov es,eax
    mov ds,fs:vfsp_disc_sel

mrrLoop:
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jc mrrDone
;
    test ax,0FFFh
    jz mrrDone
;
    sub eax,es:[ebp]
    sbb edx,es:[ebp+4]
    jnz mrrDone
;
    cmp eax,[esp]
    jne mrrDone
;
    add es:[ebx].kre_pos,200h
    adc es:[ebx].kre_pos+4,0
    add es:[edi].kre_size,200h
    add esi,8
    sub ecx,1
    jz mrrDone
;
    add eax,200h
    test eax,0FFFh
    jz mrrDone
;
    mov [esp],eax
    jmp mrrLoop

mrrDone:
    add esp,4
    pop ebp
    pop edi
    pop edx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
MergeReadReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetupReadReq
;
;       DESCRIPTION:    Setup read req
;
;       PARAMETERS:     DS                 File sel
;                       EBX                Req offset
;                       AX                 Pages
;                       ECX                Blocks
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupReadReq   Proc near
    push eax
    push ecx
    push edx
;
    mov ds:[ebx].kre_pages,ax
    shl ecx,9
    mov ds:[ebx].kre_size,ecx
;
    mov cx,ax
    shl cx,3
    AllocateBlk
    mov ds:[ebx].kre_sector_arr,edx
;
    AllocateBlk
    mov ds:[ebx].kre_phys_arr,edx
;
    pop edx
    pop ecx
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
    mov ax,ds
    mov es,eax
    mov edi,ds:[ebx].kre_sector_arr
    mov ebp,ds:[ebx].kre_phys_arr
;
    mov ds,fs:vfsp_disc_sel
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
    call BlockToPhys
    jnc prrSave
    jmp prrDone

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

prrSave:
    mov es:[ebp],eax
    mov es:[ebp+4],edx
    add ebp,8
;
    mov eax,gs:[esi]
    mov edx,gs:[esi+4]
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
;       NAME:           LockReq
;
;       DESCRIPTION:    Lock req
;
;       PARAMETERS:     GS             File sel
;                       EDX:EAX        Req position
;
;       RETURNS:        EBX            Req offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockReq      Proc near
    push ds
    push ecx
;
    mov ebx,gs
    mov ds,ebx
;
    EnterSection ds:kf_section
    call FindReadReq
    jc lrLeave
;
    mov ecx,ds:[ebx].kre_phys_arr
    or ecx,ecx
    stc
    jz lrLeave
;
    inc ds:[ebx].kre_usage
    clc

lrLeave:
    LeaveSection ds:kf_section
;
    pop ecx
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
;       RETURNS:        EBX            Req offset
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
    push ecx
    call FindReadReq
    pop ecx
    jnc irCheck
;
    call AddReadReq
    call AddWaitReq
    call SendReadReq
;
    LeaveSection ds:kf_section
;
    call UpdateMap
    WaitForSignal
    jmp irRetry

irCheck:
    mov esi,ds:[ebx].kre_phys_arr
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
;       DESCRIPTION:    Issue req
;
;       PARAMETERS:     GS             File sel
;                       EBX            Entry
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
    mov esi,gs
    mov ds,esi
    EnterSection ds:kf_section
;
    sub ds:[ebx].kre_usage,1
    jnz frLeave
;
    mov esi,OFFSET kf_sorted_arr
    mov ecx,ds:kf_count

frFind:
    cmp ebx,ds:[esi]
    je frMove
;
    add esi,4
    loop frFind
;
    jmp frLeave

frMove:
    mov eax,ds:[esi+4]
    mov ds:[esi],eax
    add esi,4
    loop frMove
;
    dec ds:kf_count
;
    call AddUpdate

frLeave:
    LeaveSection ds:kf_section
;
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
    xor ebx,ebx
    mov ebp,80h
 
frmLoop:
    movzx ecx,byte ptr es:[ebx+ebp].fm_sorted_arr
    cmp cl,0FFh
    jz frmLower
;
    shl ecx,4
    mov esi,eax
    mov edi,edx
    sub esi,es:[ecx].fm_entry_arr.fmb_pos
    sbb edi,es:[ecx].fm_entry_arr.fmb_pos+4
    jb frmLower
    jnz frmHigher
;
    cmp esi,es:[ecx].fm_entry_arr.fmb_size
    jae frmHigher
;
    add ebx,ebp
    xchg ebx,ecx
    clc
    jmp frmDone

frmHigher:
    add ebx,ebp

frmLower:
    or ebp,ebp
    stc
    jz frmDone
;
    shr ebp,1
    jmp frmLoop

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
    mov ebp,80h
    xor ebx,ebx
 
armFind:
    movzx ecx,byte ptr es:[ebx+ebp].fm_sorted_arr
    cmp cl,0FFh
    jz armLower
;
    shl ecx,4
    mov eax,es:[ecx].fm_entry_arr.fmb_pos
    mov edx,es:[ecx].fm_entry_arr.fmb_pos+4
    sub eax,es:[esi].fmb_pos
    sbb edx,es:[esi].fmb_pos+4
    jnc armHigher

armHigher:
    add ebx,ebp

armLower:
    shr ebp,1
    jnz armFind

armInsert:
    movzx ecx,byte ptr es:[ebx].fm_sorted_arr
    cmp cl,0FFh
    jz armFound
;
    shl ecx,4
    mov eax,es:[ecx].fm_entry_arr.fmb_pos
    mov edx,es:[ecx].fm_entry_arr.fmb_pos+4
    sub eax,es:[esi].fmb_pos
    sbb edx,es:[esi].fmb_pos+4
    jnc armCheckDown
;
    inc ebx
    jmp armFound

armCheckDown:
    or ebx,ebx
    jz armFound
;
    dec ebx
    movzx ecx,byte ptr es:[ebx].fm_sorted_arr
    cmp cl,0FFh
    jz armFound
;
    shl ecx,4
    mov eax,es:[ecx].fm_entry_arr.fmb_pos
    mov edx,es:[ecx].fm_entry_arr.fmb_pos+4
    sub eax,es:[esi].fmb_pos
    sbb edx,es:[esi].fmb_pos+4
    jc armFound
;
    inc ebx

armFound:
    mov eax,ebx
    mov ecx,es:fm_count
    dec ecx
    sub ecx,eax
    mov ebx,esi
    sub ebx,OFFSET fm_entry_arr
    shr ebx,4
    add eax,ecx
    lea esi,[eax].fm_sorted_arr
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
;                       GS:EBX         File entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SyncMap  Proc near
    pushad
;
    mov edi,ebx
    mov eax,gs:[ebx].kre_pos
    mov edx,gs:[ebx].kre_pos+4
    mov ecx,gs:[ebx].kre_size
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
    ret
SyncMap  Endp

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
    mov eax,gs:[ebx].kre_pos
    mov edx,gs:[ebx].kre_pos+4
    add eax,gs:[ebx].kre_size
    adc edx,0
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
    jz nfdDone
;
    mov ds,ebx
    EnterSection ds:kf_section
    mov eax,gs:vfs_rd_start
    mov edx,gs:vfs_rd_start+4
    push ecx
    call FindReadReq
    mov ebp,ecx
    pop ecx
    jnc nfdProc
;
    xor ecx,ecx
    jmp nfdUnlock

nfdProc:
    mov esi,gs:vfs_rd_chain_ptr
    call MergeReadReq
;
    push ecx
    call CalcPageCount
    call SetupReadReq
    call ProcessReadReq
    pop ecx
;
    call SignalReadReq

nfdUnlock:
    call UnlockSectors
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
;       NAME:           NotifyFileUpdate
;
;       DESCRIPTION:    Notify file data
;
;       PARAMETERS:     FS                 Part sel
;                       GS                 File req
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NotifyFileUpdate

NotifyFileUpdate  Proc near
    int 3
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
    push ds
    push ebx
    push ecx
    push edi
    push ebp
;
    movzx ecx,cx
    movzx edi,di
    mov bp,bx
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
    pop ebp
    pop edi
    pop ecx
    pop ebx
    pop ds
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
