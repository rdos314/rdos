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
; VFSSERV.ASM
; VFS server part
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

REPLY_DEFAULT      = 0
REPLY_BLOCK        = 1
REPLY_DATA         = 2

MAX_PART_COUNT   = 255

req_wait_header      STRUC

rw_obj              wait_obj_header <>
rw_handle           DD ?

req_wait_header      ENDS

fs_cmd      STRUC

fc_op              DD ?
fc_handle          DD ?
fc_buf             DD ?,?
fc_size            DD ?
fc_eflags          DD ?
fc_eax             DD ?
fc_ebx             DD ?
fc_ecx             DD ?
fc_edx             DD ?
fc_esi             DD ?
fc_edi             DD ?

fs_cmd      ENDS

data    SEGMENT byte public 'DATA'

drive_arr       DW MAX_PART_COUNT DUP (?)

data    ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern BlockToBuf:near
    extern BlockToBitmap:near
    extern SectorToBlock:near
    extern SectorCountToBlock:near
    extern InitFilePart:near
    extern FindVfsHandle:near
    extern HandleToPartEs:near
    extern HandleToPartFs:near
    extern HandleToDisc:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitPartSel
;
;       DESCRIPTION:    Init partition selector
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Part sel
;                       EDX:EAX     Start sector
;                       EDI:ESI     Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitPartSel

InitPartSel  Proc near
    push ecx
;
    mov es:vfsp_start_sector,eax
    mov es:vfsp_start_sector+4,edx
    mov es:vfsp_sector_count,esi
    mov es:vfsp_sector_count+4,edi
    mov es:vfsp_disc_sel,ds
;
    mov es:vfsp_cmd_unused_mask,-1
;
    mov cl,ds:vfs_disc_nr
    mov es:vfsp_disc_nr,cl
;
    InitSection es:vfsp_req_section
    InitSection es:vfsp_io_section
    mov es:vfsp_io_sel,0
;
    pop ecx
    ret
InitPartSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           TempCreatePartSel
;
;       DESCRIPTION:    Create partition selector
;
;       PARAMETERS:     DS      VFS sel
;
;       RETURNS:        BX      Part sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TempCreatePartSel  Proc near
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    mov ecx,MAX_VFS_PARTITIONS
    mov esi,OFFSET vfs_part_arr

tcpsLoop:
    mov ax,ds:[esi]
    or ax,ax
    jz tcpsFound
;
    add esi,2
    loop tcpsLoop
;
    stc
    jmp tcpsDone

tcpsFound:
    mov eax,SIZE vfs_file_part
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov eax,ds:vfs_curr_start_sector
    mov edx,ds:vfs_curr_start_sector+4
    mov esi,ds:vfs_curr_sector_count
    mov edi,ds:vfs_curr_sector_count+4
    call InitPartSel
    call InitFilePart
;
    mov ds:[esi],es
    mov eax,esi
    sub eax,OFFSET vfs_part_arr
    shr eax,1
    mov es:vfsp_part_nr,al
    mov bx,es
    clc

tcpsDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
TempCreatePartSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddDisc
;
;       DESCRIPTION:    Add disc
;
;       PARAMETERS:     DS      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_serv_name  DB 'parttool', 0
disc_cmd        DB 0

    public AddDisc

AddDisc   Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,ds
    mov fs,ax
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET disc_cmd
    mov edi,OFFSET disc_serv_name
    mov al,4
    mov bh,fs:vfs_disc_nr
    mov bl,-1
    LoadServer
    mov fs:vfs_app_sel,bx
;
    popad
    pop fs
    pop es
    pop ds
    ret
AddDisc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddFatPartition
;
;       DESCRIPTION:    Add FAT partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  Partition name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fat_serv_name  DB 'fat', 0

AddFatPartition   Proc near
    push ds
    push es
    push fs
    pushad
;
    call TempCreatePartSel
    jc afpDone
;
    mov fs,bx
    AllocateVfsDrive
    mov fs:vfsp_drive_nr,al
    movzx ebx,al
    shl ebx,1
    mov ax,SEG data
    mov ds,ax
    mov ds:[ebx].drive_arr,fs
;
    mov ax,es
    mov ds,ax
    mov esi,edi
    mov eax,6
    AllocateSmallGlobalMem
    xor edi,edi
    movs dword ptr es:[edi],ds:[esi]
    movs byte ptr es:[edi],ds:[esi]
    xor al,al
    stos byte ptr es:[edi]
;
    mov ax,es
    mov ds,ax
    xor esi,esi
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET fat_serv_name
    mov al,4
    mov bh,fs:vfsp_disc_nr
    mov bl,fs:vfsp_part_nr
    LoadServer
;
    mov fs:vfsp_app_sel,bx
;
    mov ax,ds
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem

afpDone:
    popad
    pop fs
    pop es
    pop ds
    ret
AddFatPartition   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddPartition
;
;       DESCRIPTION:    Add partition
;
;       PARAMETERS:     DS      VFS sel
;                       ES:EDI  Partition name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddPartition

AddPartition   Proc near
    push eax
;
    mov ax,es:[edi]
    cmp ax,'AF'
    jne apNotFat
;
    mov al,es:[edi+2]
    cmp al,'T'
    jne apNotFat
;
    call AddFatPartition

apNotFat:
    pop eax
    ret
AddPartition   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlinkRequest
;
;       DESCRIPTION:    Unlink request
;
;       PARAMETERS:     FS          Part sel
;                       GS          Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UnlinkRequest

UnlinkRequest    Proc near
    push eax
    push ebx
    push ecx
    push edx
;
    mov edx,gs
    mov ebx,OFFSET vfsp_req_arr
    mov ecx,MAX_VFS_REQ_COUNT

urLoop:
    mov ax,fs:[ebx]
    cmp ax,dx
    jne urNext
;
    xor ax,ax
    mov fs:[ebx],ax
    
urNext:
    add ebx,2
    loop urLoop
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
UnlinkRequest    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopPartRequests
;
;       DESCRIPTION:    Stop part requests
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopPartRequests    Proc near
    push gs
    push eax
    push ebx
    push ecx
;
    mov ebx,OFFSET vfsp_req_arr
    mov ecx,MAX_VFS_REQ_COUNT

sprLoop:
    mov ax,fs:[ebx]
    or ax,ax
    jz sprNext
;
    mov gs,ax
    xor ax,ax
    xchg ax,gs:vfsrh_wait_obj
    or ax,ax
    jz sprNext
;
    push es
    mov es,ax
    SignalWait
    pop es
    
sprNext:
    add ebx,2
    loop sprLoop
;
    pop ecx
    pop ebx
    pop eax
    pop gs
    ret
StopPartRequests    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopRequests
;
;       DESCRIPTION:    Stop requests
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public StopRequests

StopRequests    Proc near
    push fs
    push esi
    push edi
    push ebp
;
    push ebx
;
    mov ebx,OFFSET vfs_part_arr
    mov ebp,MAX_VFS_PARTITIONS

srLoop:
    mov si,ds:[ebx]
    or si,si
    jz srNext
;
    mov fs,si
    call StopPartRequests

srNext:
    add ebx,2
    sub ebp,1
    jnz srLoop
;
    pop ebx
;
    pop ebp
    pop edi
    pop esi
    pop fs
    ret
StopRequests    Endp

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
    push esi
    push edi
    push ebp
;
    movzx ebp,gs:vfsrh_entry_count
    mov ebx,SIZE vfs_req_header
    or ebp,ebp
    jz nrDone

nrCheckLoop:
    mov esi,gs:[ebx].vfsre_sector_count
    or esi,esi
    jz nrCheckNext
;
    mov esi,eax
    mov edi,edx
    sub esi,gs:[ebx].vfsre_start_sector
    sbb edi,gs:[ebx].vfsre_start_sector+4
    jc nrCheckNext
;
    or edi,edi
    jnz nrCheckNext
;
    cmp esi,gs:[ebx].vfsre_sector_count
    jae nrCheckNext
;
    inc cx
    sub gs:vfsrh_remain_count,1
    jnz nrCheckNext
;
    xor di,di
    xchg di,gs:vfsrh_wait_obj
    or di,di
    jz nrCheckNext
;
    push es
    mov es,edi
    SignalWait
    pop es
    
nrCheckNext:
    add ebx,SIZE vfs_req_entry
    sub ebp,1
    jnz nrCheckLoop

nrDone:
    pop ebp
    pop edi
    pop esi
    pop ebx
    ret
NotifyReq    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyPart
;
;       DESCRIPTION:    Notify part
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;                       EDX:EAX     Sector
;                       SI          Req mask
;                       CX          Lock count
;
;       RETURNS:        CX          Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyPart    Proc near
    push gs
    push ebx
    push esi
;
    mov bx,si

npLoop:
    or bx,bx
    jz npDone
;
    bsf si,bx
    btc bx,si
;
    movzx esi,si
    dec esi
    add esi,esi
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jnz npHandle
;
    int 3
    jmp npLoop

npHandle:
    mov gs,si
    call dword ptr gs:vfsr_callback
    jmp npLoop

npDone:
    pop esi
    pop ebx
    pop gs
    ret
NotifyPart    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           NotifyVfs
;
;       DESCRIPTION:    Notify read buffers
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       EDX:EAX     Sector
;                       BX          Req mask
;                       CX          Lock count
;
;       RETURNS:        CX          Lock count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public NotifyVfs

NotifyVfs    Proc near
    push fs
    push esi
    push edi
    push ebp
;
    push ebx
;
    mov ebx,OFFSET vfs_part_arr
    mov ebp,MAX_VFS_PARTITIONS

nvfLoop:
    mov si,ds:[ebx]
    or si,si
    jz nvfNext
;
    mov fs,si
    mov esi,eax
    mov edi,edx
    add esi,7
    adc edi,0
    sub esi,fs:vfsp_start_sector
    sbb edi,fs:vfsp_start_sector+4
    jc nvfNext
;
    sub esi,7
    sbb edi,0
    jc nvfHandle
;
    sub esi,fs:vfsp_sector_count    
    sbb edi,fs:vfsp_sector_count+4
    jnc nvfNext

nvfHandle:
    pop esi
    call NotifyPart
    push esi
    jmp nvfDone

nvfNext:
    add ebx,2
    sub ebp,1
    jnz nvfLoop
;
    mov si,ds:vfs_my_part
    or si,si
    jz nvfDone
;
    mov fs,si
    jmp nvfHandle

nvfDone:
    pop ebx
;
    pop ebp
    pop edi
    pop esi
    pop fs
    ret
NotifyVfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopPartitions
;
;       DESCRIPTION:    Stop partitions
;
;       PARAMETERS:     DS      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public StopPartitions

StopPartitions   Proc near
    push es
    push eax
    push ebx
;
    mov ecx,MAX_VFS_PARTITIONS
    mov ebx,vfs_part_arr

spLoop:
    mov ax,ds:[ebx]
    or ax,ax
    jz spNext
;
    mov es,ax
    or es:vfsp_flag,VFSP_FLAG_STOPPED

spNext:
    add ebx,2
    loop spLoop
;
    pop ebx
    pop eax
    pop es
    ret
    ret
StopPartitions   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsHandle
;
;       DESCRIPTION:    Get VFS handle
;
;       RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_handle_name       DB 'Get VFS Handle',0

get_vfs_handle    Proc far
    push ds
    push eax
;
    GetThread
    mov ds,ax
    mov bx,ds:p_prog_id
    call FindVfsHandle
;
    pop eax
    pop ds
    ret
get_vfs_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleHighToPartFs
;
;       DESCRIPTION:    Convert upper 8-bits from handle to partition selector
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        FS          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleHighToPartFs

HandleHighToPartFs    Proc near
    push eax
    push ebx
;
    or bx,bx
    jz hhtpfFail
;
    shr ebx,16
    or bx,bx
    jz hhtpfFail
;
    mov al,bh
    call HandleToDisc
    jc hhtpfFail
;
    mov fs,eax
    cmp bl,MAX_VFS_PARTITIONS
    ja hhtpfFail
;
    movzx esi,bl
    or esi,esi
    jz hhtpfDisc

hhtpfPart:
    dec esi
    mov ax,fs:[2*esi].vfs_part_arr
    or ax,ax
    jnz hhtpfReq

hhtpfFail:
    stc
    jmp hhtpfDone

hhtpfDisc:
    mov ax,ds:vfs_my_part

hhtpfReq:
    mov fs,eax
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz hhtpfFail
;
    clc

hhtpfDone:
    pop ebx
    pop eax
    ret
HandleHighToPartFs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDiscPart
;
;       DESCRIPTION:    Get VFS disc & part #
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        AH          Disc nr
;                       AL          Part nr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_disc_part_name       DB 'Get VFS Disc & Part',0

get_vfs_disc_part    Proc far
    push es
;
    call HandleToPartEs
    jc gvdpDone
;
    mov ah,es:vfsp_disc_nr
    mov al,es:vfsp_part_nr
    clc

gvdpDone:
    pop es
    ret
get_vfs_disc_part    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsStartSector
;
;       DESCRIPTION:    Get VFS start sector
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        EDX:EAX     Start sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_start_sector_name       DB 'Get VFS Start Sector',0

get_vfs_start_sector    Proc far
    push es
;
    call HandleToPartEs
    jc gvssDone
;
    mov eax,es:vfsp_start_sector
    mov edx,es:vfsp_start_sector+4
    clc

gvssDone:
    pop es
    ret
get_vfs_start_sector    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsSectors
;
;       DESCRIPTION:    Get VFS sectors
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        EDX:EAX     Sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_sectors_name       DB 'Get VFS Sectors',0

get_vfs_sectors    Proc far
    push es
;
    call HandleToPartEs
    jc gvsDone
;
    mov eax,es:vfsp_sector_count
    mov edx,es:vfsp_sector_count+4
    clc

gvsDone:
    pop es
    ret
get_vfs_sectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsBytesPerSector
;
;       DESCRIPTION:    Get VFS bytes per sector
;
;       PARAMETERS:     EBX            VFS handle
;
;       RETURNS:        AX             Bytes per sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_bytes_per_sector_name       DB 'Get VFS Bytes/Sector',0

get_vfs_bytes_per_sector    Proc far
    push es
;
    call HandleToPartEs
    jc gvbpsDone
;
    mov es,es:vfsp_disc_sel
    mov ax,es:vfs_bytes_per_sector
    clc

gvbpsDone:
    pop es
    ret
get_vfs_bytes_per_sector   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsVfsActive
;
;       DESCRIPTION:    Is VFS active
;
;       PARAMETERS:     EBX         VFS Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_vfs_active_name       DB 'Is VFS Active',0

is_vfs_active    Proc far
    push es
;
    call HandleToPartEs
;
    pop es
    ret
is_vfs_active    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LoadVfsPart
;
;       DESCRIPTION:    Load partition
;
;       PARAMETERS:     EBX         VFS Handle
;                       EDX:EAX     Start sector
;                       ESI:ECX     Sector count
;                       ES:EDI      FS name
;
;       RETURNS:        EBX         Partition handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_load_part_name       DB 'Load VFS Part',0

serv_load_part    Proc far
    push fs
;
    call HandleToPartFs
    jc lpDone
;

lpDone:
    pop fs
    ret
serv_load_part   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateVfsReq
;
;       DESCRIPTION:    Create a VFS req
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_vfs_req_name       DB 'Create VFS Req',0

create_vfs_req    Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov edx,ebx
;
    call HandleToPartEs
    jc crvrDone
;
    mov eax,es
    mov ds,eax
    EnterSection ds:vfsp_req_section
;
    mov ecx,MAX_VFS_REQ_COUNT
    mov edi,OFFSET vfsp_req_arr
    xor ax,ax
    repnz scas word ptr es:[edi]
    jz crvrFound

crvrFail:
    LeaveSection ds:vfsp_req_section
    stc
    jmp crvrDone

crvrFound:
    mov bx,di
    sub bx,OFFSET vfsp_req_arr
    shr bx,1
    shl edx,8
    or edx,VFS_REQ_SIG SHL 24
    mov dl,bl
    mov ebx,edx
    sub edi,2
;
    mov eax,SIZE vfs_part_req
    AllocateBigServSel
    push edi
    xor edi,edi
    mov ecx,SIZE vfs_part_req
    shr ecx,2
    xor eax,eax
    rep stos dword ptr es:[edi]
    mov es:vfsr_callback,OFFSET NotifyReq
    pop edi
;
    mov ds:[edi],es
    LeaveSection ds:vfsp_req_section
    clc

crvrDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
create_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CloseVfsReq
;
;       DESCRIPTION:    Close a VFS req
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_vfs_req_name       DB 'Close VFS Req',0

close_vfs_req    Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    mov eax,ebx
    shr eax,16
    cmp ah,VFS_REQ_SIG
    jne clvrDone
;
    call HandleToDisc
    jc clvrDone
;
    mov ds,eax
    cmp bh,MAX_VFS_PARTITIONS
    ja clvrDone
;
    movzx esi,bh
    or esi,esi
    jz clvrDisc

clvrPart:
    dec esi
    mov ax,ds:[2*esi].vfs_part_arr
    or ax,ax
    jnz clvrReq
    jmp clvrDone

clvrDisc:
    mov ax,ds:vfs_my_part

clvrReq:
    mov ds,ax
    or bl,bl
    jz clvrDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja clvrDone
;
    movzx esi,bl
    dec esi
    xor bx,bx
    EnterSection ds:vfsp_req_section
    xchg bx,ds:[2*esi].vfsp_req_arr
    LeaveSection ds:vfsp_req_section
    or bx,bx
    jz clvrDone
;
    mov es,bx
    FreeBigServSel

clvrDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
close_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReqHandleToSel
;
;       DESCRIPTION:    Convert req handle to selector
;
;       PARAMETERS:     EBX         Req handle
;
;       RETURNS:        NC
;                           FS      Part sel
;                           GS      Req sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqHandleToSel  Proc near
    push ds
    push eax
    push esi
;
    mov eax,ebx
    shr eax,16
    cmp ah,VFS_REQ_SIG
    jne rqhsFail
;
    call HandleToDisc
    jc rqhsFail
;
    mov ds,eax
    cmp bh,MAX_VFS_PARTITIONS
    ja rqhsFail
;
    movzx esi,bh
    or esi,esi
    jz rqhsDisc

rqhsPart:
    dec esi
    mov ax,ds:[2*esi].vfs_part_arr
    or ax,ax
    jnz rqhsReq
    jmp rqhsFail

rqhsDisc:
    mov ax,ds:vfs_my_part

rqhsReq:
    mov fs,eax
    movzx esi,bl
    dec esi
    mov si,fs:[2*esi].vfsp_req_arr
    or si,si
    jz rqhsFail
;
    mov gs,si
    clc
    jmp rqhsDone

rqhsFail:
    stc

rqhsDone:
    pop esi
    pop eax
    pop ds
    ret
ReqHandleToSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartVfsReq
;
;       DESCRIPTION:    Start VFS req
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_vfs_req_name       DB 'Start VFS Req',0

start_vfs_req    Proc far
    push fs
    push gs
    push ebx
;
    call ReqHandleToSel
    jc srqDone
;
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    jz srqDone
;
    push ds
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    pop ds

srqDone:
    pop ebx
    pop gs
    pop fs
    ret
start_vfs_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsVfsReqDone
;
;       DESCRIPTION:    Is VFS req done
;
;       PARAMETERS:     EBX         Req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_vfs_req_done_name       DB 'Is VFS Req Done',0

is_vfs_req_done    Proc far
    push fs
    push gs
    push esi
;
    call ReqHandleToSel
    jc irqdDone
;
    mov esi,gs:vfsrh_remain_count
    or esi,esi
    stc
    jnz irqdDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz irqdDone
;
    clc

irqdDone:
    pop esi
    pop gs
    pop fs
    ret
is_vfs_req_done   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForReq
;
;           DESCRIPTION:    Start a wait for req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_req      PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov ebx,es:rw_handle
    call ReqHandleToSel
    jc stwrDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz stwrStop
;
    mov gs:vfsrh_wait_obj,es
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    jnz stwrStart

stwrStop:
    mov gs:vfsrh_wait_obj,0
    SignalWait
    jmp stwrDone

stwrStart:
    push ds
    mov ds,fs:vfsp_disc_sel
    mov bx,ds:vfs_server
    Signal
    pop ds

stwrDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
start_wait_for_req Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForReq
;
;           DESCRIPTION:    Stop a wait for req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_req       PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov ebx,es:rw_handle
    call ReqHandleToSel
    jc spwrDone
;
    mov gs:vfsrh_wait_obj,0

spwrDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
stop_wait_for_req Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearReq
;
;           DESCRIPTION:    Clear req
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_req       PROC far
    ret
clear_req       Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsReqIdle
;
;           DESCRIPTION:    Check if req is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_req_idle     PROC far
    push fs
    push gs
    push eax
    push ebx
;
    mov ebx,es:rw_handle
    call ReqHandleToSel
    jc iriDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz iriDone
;
    mov eax,gs:vfsrh_remain_count
    or eax,eax
    clc
    jne iriDone
;
    stc

iriDone:
    pop ebx
    pop eax
    pop gs
    pop fs
    ret
is_req_idle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddWaitForVfsReq
;
;       DESCRIPTION:    Add wait for VFS req
;
;       PARAMETERS:     EBX         Wait handle
;                       EAX         Req handle
;                       ECX         ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_vfs_req_name       DB 'Add Wait For VFS Req',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_req,   SEG code
aw1 DD OFFSET stop_wait_for_req,    SEG code
aw2 DD OFFSET clear_req,            SEG code
aw3 DD OFFSET is_req_idle,          SEG code

add_wait_for_vfs_req    Proc far
    push ds
    push es
    push eax
    push edi
;
    push eax
    mov eax,cs
    mov es,eax
    mov ax,SIZE req_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWait
    pop eax
    jc awrqDone
;
    mov es:rw_handle,eax

awrqDone:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_vfs_req   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetReqMask
;
;       DESCRIPTION:    Get req mask
;
;       PARAMETERS:     DS          VFS sel
;                       ES          Server flat sel
;                       FS          Part sel
;                       EBX         Req handle
;
;       RETURNS:        BP          Req mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetReqMask    Proc near
    push ecx
;
    mov cl,bl
    mov bp,1
    shl bp,cl
;
    pop ecx
    ret
GetReqMask   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddVfsSectors
;
;       DESCRIPTION:    Add VFS sectors
;
;       PARAMETERS:     EBX         Req handle
;                       EDX:EAX     Start sector
;                       ECX         Sector count
;
;       RETURNS:        EBX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_vfs_sectors_name       DB 'Add VFS Sectors',0

add_vfs_sectors    Proc far
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
    push eax
    mov eax,ebx
    shr eax,24
    cmp al,VFS_REQ_SIG
    pop eax
    jne arsFail
;
    push eax
    mov eax,ebx
    shr eax,16
    call HandleToDisc
    mov ebp,eax
    pop eax
    jc arsFail
;
    mov ds,ebp
    cmp bh,MAX_VFS_PARTITIONS
    ja arsFail
;
    movzx esi,bh
    or esi,esi
    jz arsDisc

arsPart:
    dec esi
    mov si,ds:[2*esi].vfs_part_arr
    or si,si
    jnz arsPartOk
    jmp arsFail

arsDisc:
    mov si,ds:vfs_my_part

arsPartOk:
    mov fs,si
    or bl,bl
    jz arsFail
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja arsFail
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz arsFail
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz arsFail
;
    mov gs,si
    mov esi,fs:vfsp_sector_count
    mov edi,fs:vfsp_sector_count+4
    sub esi,eax
    sbb edi,edx
    jc arsFail
;
    sub esi,ecx
    sbb edi,0
    jc arsFail
;
    mov si,serv_flat_sel
    mov es,si
;
    EnterSection ds:vfs_section
;
    mov di,gs:vfsrh_deleted_count
    or di,di
    jz arsAppend
;
    dec di
    mov gs:vfsrh_deleted_count,di
;
    mov edi,SIZE vfs_req_header

arsScanLoop:
    mov esi,gs:[edi].vfsre_sector_count
    or esi,esi
    jz arsTake
;
    add edi,SIZE vfs_req_entry
    jmp arsScanLoop

arsAppend:
    movzx edi,gs:vfsrh_entry_count
    cmp di,MAX_VFS_ENTRY_COUNT
    je arsLeaveFail
;
    inc di
    mov gs:vfsrh_entry_count,di
    shl edi,4

arsTake:
    add eax,fs:vfsp_start_sector
    adc edx,fs:vfsp_start_sector+4
;
    push eax
    push ebx
    push ecx
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    mov bx,1
    shl bx,cl
    dec bx
    movzx esi,ax
    and si,bx
    shl si,9
    mov gs:[edi].vfsre_linear,esi
    not bx
    and ax,bx
    mov gs:[edi].vfsre_start_sector,eax
    mov gs:[edi].vfsre_start_sector+4,edx
;
    pop ecx
    pop ebx
    pop eax
;
    call SectorCountToBlock
    jc arsLeaveFail
;
    push ebx
    push ecx
;
    mov ebx,ecx
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shl ebx,cl
    mov gs:[edi].vfsre_sector_count,ebx
;
    pop ecx
    pop ebx
;
    call GetReqMask

arsLoop:
    call BlockToBuf
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz arsReq
;
    cmp es:[esi].vfsp_ref_bitmap,0
    jnz arsLockOk
;
    inc ds:vfs_locked_pages

arsLockOk:
    inc es:[esi].vfsp_ref_bitmap
    jmp arsNext

arsReq:
    inc gs:vfsrh_remain_count
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
    jnc arsNext
;
    mov ds:vfs_scan_pos,eax
    mov ds:vfs_scan_pos+4,edx

arsNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz arsLoop
;
    LeaveSection ds:vfs_section
;
    mov ebx,edi
    shr ebx,4
    clc
    jmp arsDone

arsLeaveFail:
    LeaveSection ds:vfs_section

arsFail:
    stc

arsDone:
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
add_vfs_sectors    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RemoveVfsSectors
;
;       DESCRIPTION:    Remove VFS sectors
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_vfs_sectors_name       DB 'Remove VFS Sectors',0

remove_vfs_sectors    Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ebp,eax
;
    mov eax,ebx
    shr eax,16
    cmp ah,VFS_REQ_SIG
    jne rrsDone
;
    call HandleToDisc
    jc rrsDone
;
    mov ds,eax
    cmp bh,MAX_VFS_PARTITIONS
    ja rrsDone
;
    movzx esi,bh
    or esi,esi
    jz rrsDisc

rrsPart:
    dec esi
    mov ax,ds:[2*esi].vfs_part_arr
    or ax,ax
    jnz rrsReq
    jmp rrsDone

rrsDisc:
    mov ax,ds:vfs_my_part

rrsReq:
    mov fs,ax
    or bl,bl
    jz rrsDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja rrsDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz rrsDone
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz rrsDone
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,ebp
    shl edi,4
;
    EnterSection ds:vfs_section
;
    xor eax,eax
    xchg eax,gs:[edi].vfsre_sector_count
    or eax,eax
    jz rrsLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    mov ecx,eax
;
    inc gs:vfsrh_deleted_count
    mov eax,gs:[edi].vfsre_start_sector
    mov edx,gs:[edi].vfsre_start_sector+4
    call SectorToBlock
    jc rrsLeave

rrsLoop:
    call BlockToBuf
    jc rrsNext
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz rrsDecRem

rrsUnlock:
    mov bx,es:[esi].vfsp_ref_bitmap
    or bx,bx
    jz rrsDecRem
;
    sub es:[esi].vfsp_ref_bitmap,1
    jnz rrsNext
;
    dec ds:vfs_locked_pages
    jmp rrsNext

rrsDecRem:
    sub gs:vfsrh_remain_count,1
    jnc rrsNext
;
    CrashGate

rrsNext:
    add eax,8
    adc edx,0
    sub ecx,1
    jnz rrsLoop

rrsLeave:
    LeaveSection ds:vfs_section

rrsDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
remove_vfs_sectors Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MapVfsReq
;
;       DESCRIPTION:    Map VFS req
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;       RETURNS:        EDX         Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_vfs_req_name       DB 'Map VFS Req',0

map_vfs_req    Proc far
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push esi
    push edi
    push ebp
;
    mov ecx,ebx
    shr ecx,16
    cmp ch,VFS_REQ_SIG
    jne mvrFail
;
    push eax
    mov al,cl
    call HandleToDisc
    mov cx,ax
    pop eax
    jc mvrFail
;
    mov ds,ecx
    cmp bh,MAX_VFS_PARTITIONS
    ja mvrFail
;
    movzx esi,bh
    or esi,esi
    jz mvrDisc

mvrPart:
    dec esi
    mov si,ds:[2*esi].vfs_part_arr
    or si,si
    jnz mvrReq

mvrFail:
    stc
    jmp mvrDone

mvrDisc:
    mov si,ds:vfs_my_part

mvrReq:
    mov fs,si
    or bl,bl
    jz mvrFail
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja mvrFail
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz mvrFail
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz mvrFail
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,eax
    shl edi,4
;
    EnterSection ds:vfs_section
;
    mov eax,gs:[edi].vfsre_sector_count
    or eax,eax
    stc
    jz mvrLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    mov ecx,eax
;
    shl eax,12
    AllocateLocalLinear
    mov ebp,edx
;
    mov eax,gs:[edi].vfsre_start_sector
    mov edx,gs:[edi].vfsre_start_sector+4
    call SectorToBlock
    jc mvrLeave
;
    push ebp

mvrLoop:
    call BlockToBuf
    jc mvrNext
;
    test es:[esi].vfsp_flags,VFS_PHYS_VALID
    jz mvrNext
;
    push eax
    push edx
;
    mov edx,ebp
    mov eax,es:[esi]
    and ax,0F000h
    or ax,867h
    movzx ebx,word ptr es:[esi+4]
    SetPageEntry
;
    pop edx
    pop eax

mvrNext:
    add ebp,1000h
    add eax,8
    adc edx,0
    sub ecx,1
    jnz mvrLoop
;
    pop edx
    mov eax,gs:[edi].vfsre_linear
    and eax,0E00h
    add edx,eax
    mov gs:[edi].vfsre_linear,edx
;
    mov bx,system_data_sel
    mov es,bx
    sub edx,es:flat_base
    clc

mvrLeave:
    LeaveSection ds:vfs_section

mvrDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds
    ret
map_vfs_req Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnmapVfsReq
;
;       DESCRIPTION:    Unmap VFS req
;
;       PARAMETERS:     EBX         Req handle
;                       EAX         Req #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unmap_vfs_req_name       DB 'Map VFS Req',0

unmap_vfs_req    Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
;
    mov ecx,ebx
    shr ecx,16
    cmp ch,VFS_REQ_SIG
    jne umvrDone
;
    push eax
    mov al,cl
    call HandleToDisc
    mov cx,ax
    pop eax
    jc umvrDone
;
    mov ds,ecx
    cmp bh,MAX_VFS_PARTITIONS
    ja umvrDone
;
    movzx esi,bh
    or esi,esi
    jz umvrDisc

umvrPart:
    dec esi
    mov si,ds:[2*esi].vfs_part_arr
    or si,si
    jnz umvrReq
    jmp umvrDone

umvrDisc:
    mov si,ds:vfs_my_part

umvrReq:
    mov fs,si
    or bl,bl
    jz umvrDone
;
    cmp bl,MAX_VFS_REQ_COUNT
    ja umvrDone
;
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz umvrDone
;
    movzx esi,bl
    dec esi
    shl esi,1
    mov si,fs:[esi].vfsp_req_arr
    or si,si
    jz umvrDone
;
    mov gs,si
    mov ds,fs:vfsp_disc_sel
    mov si,serv_flat_sel
    mov es,si
    mov edi,eax
    shl edi,4
;
    EnterSection ds:vfs_section
;
    mov eax,gs:[edi].vfsre_sector_count
    or eax,eax
    stc
    jz umvrLeave
;
    mov cl,3
    sub cl,ds:vfs_sector_shift
    shr eax,cl
    shl eax,12
    mov ecx,eax
    mov edx,gs:[edi].vfsre_linear
    and edx,0FFFFF000h
    jz umvrLeave
;
    FreeLinear
;
    mov edx,gs:[edi].vfsre_linear
    and edx,0FFFh
    mov gs:[edi].vfsre_linear,edx

umvrLeave:
    LeaveSection ds:vfs_section

umvrDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
unmap_vfs_req    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForVfsCmd
;
;       DESCRIPTION:    Wait for VFS cmd
;
;       PARAMETERS:     EBX        VFS handle
;
;       RETURNS:        EDX        Msg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_vfs_cmd_name DB 'Wait For VFS Cmd', 0

wait_for_vfs_cmd   Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    call HandleToPartEs
    jc wfcDone
;
    mov ax,es
    mov ds,ax
;
    GetThread
    mov ds:vfsp_cmd_thread,ax
    jmp wfcCheck

wfcRetry:
    test ds:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz wfcDone
;
    WaitForSignal

wfcCheck:
    test ds:vfsp_flag,VFSP_FLAG_STOPPED
    stc
    jnz wfcDone
;
    movzx ebx,ds:vfsp_cmd_head
    mov al,ds:[ebx].vfsp_cmd_ring
    cmp bl,ds:vfsp_cmd_tail
    je wfcRetry
;
    inc bl
    cmp bl,34
    jb wfcSaveHead
;
    xor bl,bl

wfcSaveHead:
    mov ds:vfsp_cmd_head,bl
;
    movzx ebx,al
    mov ds:vfsp_cmd_curr,ebx
    dec ebx
    shl ebx,4
    add ebx,OFFSET vfsp_cmd_arr
    mov edx,ds:[ebx].vfss_server_linear
    or edx,edx
    jnz wfcMap
;
    mov eax,1000h
    AllocateLocalLinear
    mov ds:[ebx].vfss_server_linear,edx

wfcMap:
    push ds
    push edx
;
    mov eax,[ebx].vfss_phys
    mov ebx,[ebx].vfss_phys+4
    or ax,867h
;
    mov cx,system_data_sel
    mov ds,cx
    add edx,ds:flat_base
    SetPageEntry
;
    pop edx
    pop ds
    clc

wfcDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
wait_for_vfs_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReplyVfsCmd
;
;       DESCRIPTION:    Reply on VFS run cmd
;
;       PARAMETERS:     EBX        VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_vfs_cmd_name DB 'Reply VFS Cmd', 0

reply_vfs_cmd   Proc far
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    mov es:[edi].fc_op,REPLY_DEFAULT
;
    call HandleToPartEs
    jc rfcDone
;
    mov esi,es:vfsp_cmd_curr
    dec esi
    shl esi,4
    add esi,OFFSET vfsp_cmd_arr
    xor bx,bx
    xchg bx,es:[esi].vfss_thread
    Signal
;
    mov edx,es:[esi].vfss_server_linear
    mov eax,es:[esi].vfss_phys
    mov ebx,es:[esi].vfss_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov es,cx
    add edx,es:flat_base
    SetPageEntry

rfcDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
reply_vfs_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReplyVfsPost
;
;       DESCRIPTION:    Serv reply VFS post cmd
;
;       PARAMETERS:     EBX            VFS req handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_vfs_post_name       DB 'Reply VFS Post',0

reply_vfs_post    Proc far
    push es
    push fs
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    call HandleToPartFs
    jc rvfpDone
;
    mov ebp,ebx
    mov esi,fs:vfsp_cmd_curr
    dec esi
    mov ebx,esi
    shl ebx,4
    add ebx,OFFSET vfsp_cmd_arr
;
    mov edx,fs:[ebx].vfss_server_linear
    mov eax,fs:[ebx].vfss_phys
    mov ebx,fs:[ebx].vfss_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov es,cx
    add edx,es:flat_base
    SetPageEntry
;
    lock bts fs:vfsp_cmd_free_mask,esi

rvfpDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop es
    ret
reply_vfs_post    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReplyVfsBlockCmd
;
;       DESCRIPTION:    Reply on VFS block cmd
;
;       PARAMETERS:     EBX        VFS handle
;                       EDX        Block flat
;                       EDI        Data block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_vfs_block_cmd_name DB 'Reply VFS Block Cmd', 0

reply_vfs_block_cmd   Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    push ebx
;
    mov es:[edi].fc_op,REPLY_BLOCK
;
    add edi,SIZE fs_cmd
    movzx ecx,es:[edx].sb_pages
    mov eax,ecx
    stosd
;
    lock add es:[edx].sb_usage,1
    or ecx,ecx
    jz rfbcSend

rfbcCopy:
    GetPageEntry
    and ax,0F000h
    stosd
    mov eax,ebx
    stosd
;
    add edx,1000h
    loop rfbcCopy

rfbcSend:
    pop ebx
;
    call HandleToPartEs
    jc rfbcDone
;
    mov esi,es:vfsp_cmd_curr
    dec esi
    shl esi,4
    add esi,OFFSET vfsp_cmd_arr
    xor bx,bx
    xchg bx,es:[esi].vfss_thread
    Signal
;
    mov edx,es:[esi].vfss_server_linear
    mov eax,es:[esi].vfss_phys
    mov ebx,es:[esi].vfss_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov ds,cx
    add edx,ds:flat_base
    SetPageEntry

rfbcDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
reply_vfs_block_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReplyVfsDataCmd
;
;       DESCRIPTION:    Reply on VFS data cmd
;
;       PARAMETERS:     EBX        VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reply_vfs_data_cmd_name DB 'Reply VFS Data Cmd', 0

reply_vfs_data_cmd   Proc far
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    mov es:[edi].fc_op,REPLY_DATA
;
    call HandleToPartEs
    jc rvdcDone
;
    mov esi,es:vfsp_cmd_curr
    dec esi
    shl esi,4
    add esi,OFFSET vfsp_cmd_arr
    xor bx,bx
    xchg bx,es:[esi].vfss_thread
    Signal
;
    mov edx,es:[esi].vfss_server_linear
    mov eax,es:[esi].vfss_phys
    mov ebx,es:[esi].vfss_phys+4
    or ax,863h
    mov cx,system_data_sel
    mov es,cx
    add edx,es:flat_base
    SetPageEntry

rvdcDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
reply_vfs_data_cmd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMsgEntry
;
;       DESCRIPTION:    Get fs msg entry
;
;       PARAMETERS:     DS      VFS sel
;                       FS      Part sel
;
;       RETURNS:        EBX     FS entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMsgEntry  Proc near
    push ecx

gmeRetry:
    mov ebx,fs:vfsp_cmd_free_mask
    or ebx,ebx
    jz gmeTryUnused
;
    bsf ecx,ebx
    lock btc fs:vfsp_cmd_free_mask,ecx
    jc gmeOk
    jmp gmeRetry

gmeTryUnused:
    mov ebx,fs:vfsp_cmd_unused_mask
    or ebx,ebx
    jz gmeBlock
;
    bsf ecx,ebx
    lock btc fs:vfsp_cmd_unused_mask,ecx
    jc gmeAlloc
    jmp gmeRetry

gmeBlock:
    int 3
    jmp gmeRetry

gmeAlloc:
    mov ebx,ecx
    shl ebx,4
    add ebx,OFFSET vfsp_cmd_arr
;
    push eax
    push ebx
    push edx
    push edi
;
    mov edi,ebx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov fs:[edi].vfss_phys,eax
    mov fs:[edi].vfss_phys+4,ebx
;
    or al,63h
    SetPageEntry
;    
    mov ecx,1000h
    AllocateGdt
    mov fs:[edi].vfss_sel,bx
    CreateDataSelector32
;
    mov fs:[edi].vfss_server_linear,0
    mov fs:[edi].vfss_thread,0
;
    pop edi
    pop edx
    pop ebx
    pop eax
;
    clc
    jmp gmeDone

gmeOk:
    mov ebx,ecx
    shl ebx,4
    add ebx,OFFSET vfsp_cmd_arr

gmeDone:
    pop ecx
    ret
GetMsgEntry  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateMsg
;
;       DESCRIPTION:    Allocate fs msg
;
;       PARAMETERS:     DS      VFS sel
;                       FS      Part sel
;
;       RETURNS:        EBX     Msg entry
;                       ES      Msg buffer
;                       EDI     FS msg data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateMsg

AllocateMsg  Proc near
    push ebx
    call GetMsgEntry
    mov es,fs:[ebx].vfss_sel
    mov es:fc_size,0
    pop es:fc_ebx
;
    stc
    pushfd
    pop es:fc_eflags
;
    mov es:fc_eax,eax
    mov es:fc_ecx,ecx
    mov es:fc_edx,edx
    mov es:fc_esi,esi
    mov es:fc_edi,edi
;
    mov edi,SIZE fs_cmd
    ret
AllocateMsg  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddMsgBuffer
;
;       DESCRIPTION:    Add msg buffer
;
;       PARAMETERS:     DS      VFS sel
;                       ES      Msg buffer
;                       FS      Part sel
;                       GS:EDI  Data buffer
;                       ECX     Size of buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddMsgBuffer

AddMsgBuffer  Proc near
    mov es:fc_buf,edi
    mov es:fc_buf+4,gs
    mov es:fc_size,ecx
    ret
AddMsgBuffer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           no_reply
;
;       DESCRIPTION:    No reply processing
;
;       PARAMETERS:     ES      Msg buf
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

no_reply   Proc near
    xor ebp,ebp
    clc
    ret
no_reply   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           block_reply
;
;       DESCRIPTION:    Block reply processing
;
;       PARAMETERS:     ES      Msg buf
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

block_reply  Proc near
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    mov esi,SIZE fs_cmd
    mov ecx,es:[esi]
    add esi,4
    mov eax,ecx
    shl eax,12
    AllocateBigLinear
    mov ebp,edx

brpLoop:
    mov eax,es:[esi]
    mov ebx,es:[esi+4]
    or ax,863h
    SetPageEntry
;
    add esi,8
    add edx,1000h
;
    loop brpLoop
;
    clc
;
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
block_reply  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           data_reply
;
;       DESCRIPTION:    Data reply processing
;
;       PARAMETERS:     ES      Msg buf
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

data_reply  Proc near
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    xor ebp,ebp
    mov eax,es
    mov ds,eax
    mov esi,SIZE fs_cmd
    mov ecx,ds:fc_size
    or ecx,ecx
    jz drpDone
;
    lods dword ptr ds:[esi]
    or eax,eax
    jz drpDone
;
    cmp eax,ecx
    jae drpCopy
;
    mov ecx,eax

drpCopy:
    mov ebp,ecx
    les edi,ds:fc_buf
    rep movs byte ptr es:[edi],ds:[esi]

drpDone:
    clc
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
data_reply  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunMsg
;
;       DESCRIPTION:    Run disc msg
;
;       PARAMETERS:     DS      VFS sel
;                       FS      Part sel
;                       ES      Msg buf
;                       EAX     Op
;                       EBX     Msg entry
;
;       RETURNS:        EBP     Reply data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RunMsg

reply_tab:
r00 DD OFFSET no_reply
r01 DD OFFSET block_reply
r02 DD OFFSET data_reply

RunMsg  Proc near
    mov esi,ebx
    mov es:fc_op,eax
;
    GetThread
    mov fs:[esi].vfss_thread,ax
;
    sub ebx,OFFSET vfsp_cmd_arr
    shr ebx,4
    mov al,bl
    inc al
;
    movzx ebx,fs:vfsp_cmd_tail
    mov fs:[ebx].vfsp_cmd_ring,al
    inc bl
    cmp bl,34
    jb rmSaveTail
;
    xor bl,bl

rmSaveTail:
    mov fs:vfsp_cmd_tail,bl
;
    mov bx,fs:vfsp_cmd_thread
    Signal

rmWait:
    WaitForSignal
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jz rmCheck
;
    stc
    jmp rmDone

rmCheck:
    mov bx,fs:[esi].vfss_thread
    or bx,bx
    jnz rmWait
;
    mov ebp,es:fc_eax
    mov ebx,es:fc_ebx
    mov ecx,es:fc_ecx
    mov edx,es:fc_edx
    mov esi,es:fc_esi
    mov edi,es:fc_edi
;
    dec al
    movzx eax,al
    push es:fc_eflags
    push ebp
    push eax
;
    xor ebp,ebp
    push es:fc_eflags
    popfd
    jc rmFree
;
    push ebx
    mov ebx,es:fc_op
    shl ebx,2
    call dword ptr cs:[ebx].reply_tab
    pop ebx

rmFree:
    pop eax
    lock bts fs:vfsp_cmd_free_mask,eax
;
    pop eax
    popfd

rmDone:
    ret
RunMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PostMsg
;
;       DESCRIPTION:    Queue disc msg
;
;       PARAMETERS:     DS      VFS sel
;                       FS      Part sel
;                       ES      Msg buf
;                       EAX     Op
;                       EBX     Msg entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public PostMsg

PostMsg  Proc near
    push eax
    push ebx
;
    mov es:fc_op,eax
    mov fs:[ebx].vfss_thread,0
;
    sub ebx,OFFSET vfsp_cmd_arr
    shr ebx,4
    mov al,bl
    inc al
;
    movzx ebx,fs:vfsp_cmd_tail
    mov fs:[ebx].vfsp_cmd_ring,al
    inc bl
    cmp bl,34
    jb pmSaveTail
;
    xor bl,bl

pmSaveTail:
    mov fs:vfsp_cmd_tail,bl
;
    mov bx,fs:vfsp_cmd_thread
    Signal
;
    pop ebx
    pop eax
    ret
PostMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           MapBlockToUser
;
;       DESCRIPTION:    Map block to user
;
;       PARAMETERS:     EDX     Block
;
;       RETURNS:        EDX     User mapped block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public MapBlockToUser

MapBlockToUser  Proc near
    push ds
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    mov ax,flat_sel
    mov ds,ax
    mov esi,edx
    movzx ecx,ds:[esi].sb_pages
    mov eax,ecx
    shl eax,12
    AllocateLocalLinear
    mov edi,edx
;
    push edx

mbtuLoop:
    mov edx,esi
    GetPageEntry
    and ax,0F000h
    or ax,825h
;
    mov edx,edi
    SetPageEntry
;
    add esi,1000h
    add edi,1000h
    loop mbtuLoop
;
    pop edx
;
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
MapBlockToUser  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeUserBlock
;
;       DESCRIPTION:    Free user block
;
;       PARAMETERS:     EDX     Block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeUserBlock

FreeUserBlock  Proc near
    push ds
    push ecx
    push edx
;
    mov cx,flat_sel
    mov ds,cx
    movzx ecx,ds:[edx].sb_pages
    shl ecx,12
    FreeLinear
;
    pop edx
    pop ecx
    pop ds
    ret
FreeUserBlock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeBlock
;
;       DESCRIPTION:    Free block
;
;       PARAMETERS:     EDX     Block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FreeBlock

FreeBlock  Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    mov cx,flat_sel
    mov ds,cx
    lock sub ds:[edx].sb_usage,1
    jz fbFreePhys
;
    movzx ecx,ds:[edx].sb_pages
    shl ecx,12
    FreeLinear
    jmp fbDone

fbFreePhys:
    movzx ecx,ds:[edx].sb_pages

fbFreeLoop:
    GetPageEntry
    test al,1
    jz fbFreeNext
;
    and ax,0F000h
    FreePhysical
;
    xor eax,eax
    xor ebx,ebx
    SetPageEntry

fbFreeNext:
    add edx,1000h
    loop fbFreeLoop

fbDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
FreeBlock  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartVfsIoServer
;
;       DESCRIPTION:    Start VFS IO server
;
;       PARAMETERS:     EBX         VFS Handle
;                       EDX         Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_vfs_io_server_name       DB 'Start VFS IO Server',0

start_vfs_io_server    Proc far
    push es
    push fs
    push eax
    push ebx
    push ecx
    push edi
;
    call HandleToPartFs
    jc svioDone
;
    GetPageEntry
    push eax
    push ebx
;
    and ax,0F000h
    or ax,867h
    SetPageEntry
;
    mov eax,1000h
    AllocateBigLinear
;
    pop ebx
    pop eax
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector32
    mov fs:vfsp_io_sel,bx
;
    mov fs:vfsp_io_wr_ptr,0
    mov fs:vfsp_io_thread,0
;
    clc

svioDone:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop es
    ret
start_vfs_io_server    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ServWaitIoServer
;
;       DESCRIPTION:    Serv wait VFS IO queue
;
;       PARAMETERS:     EBX            VFS handle
;                       EDX            Current position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_wait_io_server_name       DB 'Serv Wait Io Server',0

serv_wait_io_server    Proc far
    push ds
    push fs
    push eax
    push ebx
    push edx
;
    call HandleToPartFs
    jc swfqDone
;
    ClearSignal
;
    mov eax,fs
    mov ds,eax
    EnterSection ds:vfsp_io_section
;
    GetThread
    mov ds:vfsp_io_thread,ax
;
    shl edx,4
    movzx ebx,ds:vfsp_io_wr_ptr
    cmp ebx,edx
    LeaveSection ds:vfsp_io_section
    jne swfqDone
;
    WaitForSignal

swfqClear:
    mov ds:vfsp_io_thread,0

swfqDone:
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
serv_wait_io_server    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TestServ
;
;       DESCRIPTION:    Test server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_serv_name DB 'Test Serv', 0

test_serv   Proc far
    WaitForSignal
    ret
test_serv   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDrivePart
;
;       DESCRIPTION:    Get drive part sel
;
;       PARAMETERS:     AL        Drive #
;
;       RETURNS:        BX        Part sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetDrivePart

GetDrivePart   Proc near
    push ds
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    shl bx,1
    mov bx,ds:[bx].drive_arr
;
    pop ds
    ret
GetDrivePart   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDriveDisc
;
;       DESCRIPTION:    Get VFS drive disc
;
;       PARAMETERS:     AL    Drive #
;
;       RETURNS:        AL    Disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_drive_disc_name DB 'Get VFS Drive Disc', 0

get_vfs_drive_disc   Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvddDone
;
    mov ds,bx
    mov al,ds:vfsp_disc_nr
    clc

gvddDone:
    pop ebx
    pop ds
    ret
get_vfs_drive_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDriveStart
;
;       DESCRIPTION:    Get VFS drive start
;
;       PARAMETERS:     AL        Drive #
;
;       RETURNS:        EDX:EAX   Start sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_drive_start_name DB 'Get VFS Drive Start', 0

get_vfs_drive_start   Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvdbDone
;
    mov ds,bx
    mov eax,ds:vfsp_start_sector
    mov edx,ds:vfsp_start_sector+4
    clc

gvdbDone:
    pop ebx
    pop ds
    ret
get_vfs_drive_start   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDriveSize
;
;       DESCRIPTION:    Get VFS drive size
;
;       PARAMETERS:     AL        Drive #
;
;       RETURNS:        EDX:EAX   Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_drive_size_name DB 'Get VFS Drive Size', 0

get_vfs_drive_size   Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvdeDone
;
    mov ds,bx
    mov eax,ds:vfsp_sector_count
    mov edx,ds:vfsp_sector_count+4
    clc

gvdeDone:
    pop ebx
    pop ds
    ret
get_vfs_drive_size   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDriveFree
;
;       DESCRIPTION:    Get VFS drive free
;
;       PARAMETERS:     AL        Drive #
;
;       RETURNS:        EDX:EAX   Free sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_drive_free_name DB 'Get VFS Drive Free', 0

get_vfs_drive_free   Proc far
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edi
    push ebp
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].drive_arr
    or bx,bx
    stc
    jz gvdfDone
;
    mov fs,bx
    mov ds,fs:vfsp_disc_sel
;
    call AllocateMsg
;
    mov eax,VFS_GET_FREE_SECTORS
    call RunMsg

gvdfDone:
    pop ebp
    pop edi
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
get_vfs_drive_free   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_server
;
;       description:    Init server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_server

init_server    Proc near
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET drive_arr
    mov ecx,MAX_PART_COUNT
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_vfs_handle
    mov edi,OFFSET get_vfs_handle_name
    xor cl,cl
    mov ax,get_vfs_handle_nr
    RegisterServGate
;
    mov esi,OFFSET is_vfs_active
    mov edi,OFFSET is_vfs_active_name
    xor cl,cl
    mov ax,is_vfs_active_nr
    RegisterServGate
;
    mov esi,OFFSET get_vfs_disc_part
    mov edi,OFFSET get_vfs_disc_part_name
    xor cl,cl
    mov ax,get_vfs_disc_part_nr
    RegisterServGate
;
    mov esi,OFFSET get_vfs_start_sector
    mov edi,OFFSET get_vfs_start_sector_name
    xor cl,cl
    mov ax,get_vfs_start_sector_nr
    RegisterServGate
;
    mov esi,OFFSET get_vfs_sectors
    mov edi,OFFSET get_vfs_sectors_name
    xor cl,cl
    mov ax,get_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET get_vfs_bytes_per_sector
    mov edi,OFFSET get_vfs_bytes_per_sector_name
    xor cl,cl
    mov ax,get_vfs_bytes_per_sector_nr
    RegisterServGate
;
    mov esi,OFFSET start_vfs_io_server
    mov edi,OFFSET start_vfs_io_server_name
    xor cl,cl
    mov ax,start_vfs_io_serv_nr
    RegisterServGate
;
    mov esi,OFFSET serv_wait_io_server
    mov edi,OFFSET serv_wait_io_server_name
    xor cl,cl
    mov ax,serv_wait_io_serv_nr
    RegisterServGate
;
    mov esi,OFFSET serv_load_part
    mov edi,OFFSET serv_load_part_name
    xor cl,cl
    mov ax,serv_load_part_nr
    RegisterServGate
;
    mov esi,OFFSET create_vfs_req
    mov edi,OFFSET create_vfs_req_name
    xor cl,cl
    mov ax,create_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET close_vfs_req
    mov edi,OFFSET close_vfs_req_name
    xor cl,cl
    mov ax,close_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET start_vfs_req
    mov edi,OFFSET start_vfs_req_name
    xor cl,cl
    mov ax,start_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET is_vfs_req_done
    mov edi,OFFSET is_vfs_req_done_name
    xor cl,cl
    mov ax,is_vfs_req_done_nr
    RegisterServGate
;
    mov esi,OFFSET add_wait_for_vfs_req
    mov edi,OFFSET add_wait_for_vfs_req_name
    xor cl,cl
    mov ax,add_wait_for_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET wait_for_vfs_cmd
    mov edi,OFFSET wait_for_vfs_cmd_name
    xor cl,cl
    mov ax,wait_for_vfs_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET reply_vfs_cmd
    mov edi,OFFSET reply_vfs_cmd_name
    xor cl,cl
    mov ax,reply_vfs_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET reply_vfs_post
    mov edi,OFFSET reply_vfs_post_name
    xor cl,cl
    mov ax,reply_vfs_post_nr
    RegisterServGate
;
    mov esi,OFFSET reply_vfs_block_cmd
    mov edi,OFFSET reply_vfs_block_cmd_name
    xor cl,cl
    mov ax,reply_vfs_block_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET reply_vfs_data_cmd
    mov edi,OFFSET reply_vfs_data_cmd_name
    xor cl,cl
    mov ax,reply_vfs_data_cmd_nr
    RegisterServGate
;
    mov esi,OFFSET test_serv
    mov edi,OFFSET test_serv_name
    mov ax,test_serv_nr
    RegisterServGate
;
    mov esi,OFFSET add_vfs_sectors
    mov edi,OFFSET add_vfs_sectors_name
    xor cl,cl
    mov ax,add_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET remove_vfs_sectors
    mov edi,OFFSET remove_vfs_sectors_name
    xor cl,cl
    mov ax,remove_vfs_sectors_nr
    RegisterServGate
;
    mov esi,OFFSET map_vfs_req
    mov edi,OFFSET map_vfs_req_name
    xor cl,cl
    mov ax,map_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET unmap_vfs_req
    mov edi,OFFSET unmap_vfs_req_name
    xor cl,cl
    mov ax,unmap_vfs_req_nr
    RegisterServGate
;
    mov esi,OFFSET get_vfs_drive_disc
    mov edi,OFFSET get_vfs_drive_disc_name
    xor dx,dx
    mov ax,get_vfs_drive_disc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_vfs_drive_start
    mov edi,OFFSET get_vfs_drive_start_name
    xor dx,dx
    mov ax,get_vfs_drive_start_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_vfs_drive_size
    mov edi,OFFSET get_vfs_drive_size_name
    xor dx,dx
    mov ax,get_vfs_drive_size_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_vfs_drive_free
    mov edi,OFFSET get_vfs_drive_free_name
    xor dx,dx
    mov ax,get_vfs_drive_free_nr
    RegisterBimodalUserGate
    ret
init_server    Endp

code    ENDS

    END
