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
; VFS.ASM
; Virtual file system
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
include vfs.inc

    .386p

MAX_DISC_COUNT   =  16

data    SEGMENT byte public 'DATA'

disc_arr        DW MAX_DISC_COUNT DUP (?)

data    ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern init_buf:near
    extern init_server:near
    extern init_part:near

    extern HandleDisc:near
    extern CreateBuffer:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunVfsReq
;
;       DESCRIPTION:    Run VFS req
;
;       PARAMETERS:     DS      Disc sel
;                       ES      Req sel`
;                       AX      Op
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunVfsReq  Proc near
    push eax
;
    mov es:vch_op,ax
    GetThread
    mov es:vch_thread,ax
;
    EnterSection ds:vfs_section
;
    mov ax,ds:vfs_req_list
    or ax,ax
    je rvrEmpty
;    
    push ds
    push esi
;
    mov ds,ax
    mov si,ds:vch_prev
    mov ds:vch_prev,es
    mov ds,si
    mov ds:vch_next,es
    mov es:vch_next,ax
    mov es:vch_prev,si
;
    pop esi
    pop ds
    jmp rvrWait
    
rvrEmpty:
    mov es:vch_next,es
    mov es:vch_prev,es
    mov ds:vfs_req_list,es

rvrWait:
    LeaveSection ds:vfs_section
;
    WaitForSignal
;
    pop eax
    ret
RunVfsReq  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDiscSel
;
;       DESCRIPTION:    Create partition selector
;
;       PARAMETERS:     DS:ESI  VFS table
;                       BX      Param
;
;       RETURNS:        BX      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDiscSel  Proc near
    push es
    push fs
    push ecx
    push esi
    push edi
    push ebp
;
    mov ax,SEG data
    mov fs,ax
    InstallVfsDisc
;
    movzx ebp,al
    shl ebp,1
    add ebp,OFFSET disc_arr
;
    mov eax,OFFSET vfs_buf_arr
    AllocateSmallGlobalMem
;
    mov ecx,SIZE vfs_table_struc
    xor edi,edi
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov ecx,OFFSET vfs_buf_arr - SIZE vfs_table_struc
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov fs:[ebp],es
    mov es:vfs_param,bx
    mov es:vfs_flags,0
    mov es:vfs_server,0
;
    mov eax,ebp
    sub eax,OFFSET disc_arr
    shr eax,1
    mov es:vfs_disc_nr,al
;
    mov bx,es
    clc

cdsDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop fs
    pop es
    ret
CreateDiscSel   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CalcParam
;
;       DESCRIPTION:    Calculate schedule params
;
;       PARAMETERS:     DS      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam    Proc near
    mov eax,ds:vfs_sectors
    mov edx,ds:vfs_sectors+4
    mov bx,ds:vfs_bytes_per_sector
    xor cl,cl

cpSectorLoop:
    cmp bx,1000h
    jae cpSectorOk
;
    clc
    rcr edx,1
    rcr eax,1
    shl bx,1
    inc cl
    jmp cpSectorLoop

cpSectorOk:
    mov bl,3
    sub bl,cl
    mov ds:vfs_sector_shift,bl
;
    add eax,1
    adc edx,0
    mov ds:vfs_blocks,eax
    mov ds:vfs_blocks+4,edx
;
    mov ebx,eax
    rol ebx,3
    and bl,7
    shl edx,3
    or dl,bl
    inc edx
    mov ds:vfs_buf_count,edx
;
    mov ax,1
    shl ax,cl
    mov ds:vfs_sectors_per_block,ax
;
    ret
CalcParam    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           PartThread
;
;       DESCRIPTION:    Partition thread
;
;       PARAMETERS:     BX       VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

part_thread_name       DB 'VFS',0

part_thread:
    mov ds,bx
    call init_part
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreatePartThread
;
;       DESCRIPTION:    Start part thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePartThread Proc near
    push ds
    push es
    pushad
;
    mov bx,ds
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET part_thread
    mov edi,OFFSET part_thread_name
    mov al,4
    CreateThread
;
    popad
    pop es
    pop ds
    ret
CreatePartThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           VfsServer
;
;       DESCRIPTION:    Vfs server
;
;       PARAMETERS:     BX      VFS sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VfsServer:
    GetThread
    mov ds,bx
    mov ds:vfs_server,ax
;
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_init
    jc vfsTerm
;
    mov ds:vfs_sectors,eax
    mov ds:vfs_sectors+4,edx
    mov ds:vfs_bytes_per_sector,cx
;
    and bl,0F8h    
    mov ds:vfs_max_req,bx
    movzx eax,bx
    shl eax,3
    AllocateSmallServ
    mov ds:vfs_req_buf,es
;
    mov bx,ds
    mov es,bx
    mov edi,OFFSET vfs_vendor_str
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_get_vendor
;
    mov ds:vfs_scan_pos,-1
    mov ds:vfs_scan_pos+4,-1
    mov ds:vfs_active_count,0
    mov ds:vfs_req_list,0
    InitSection ds:vfs_section
;
    call CalcParam
    call CreateBuffer
    call CreatePartThread
    call HandleDisc
    int 3

vfsExit:
    mov bx,ds:vfs_param
    call fword ptr ds:vfs_exit

vfsTerm:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartVfs
;
;       DESCRIPTION:    Start VFS
;
;       PARAMETERS:     DS:ESI  VFS table
;                       ES:EDI  Server name
;                       BX      Dev param
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_vfs_name       DB 'Start VFS',0

start_vfs    Proc far
    push ds
    push eax
    push esi
;
    call CreateDiscSel
    jc svfsDone
;
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET VfsServer
    mov al,4
    CreateServerProcess

svfsDone:
    pop esi
    pop eax
    pop ds
    ret
start_vfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StopVfs
;
;       DESCRIPTION:    Stop vfs
;
;       PARAMETERS:     BX      VFS handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_vfs_name       DB 'Stop VFS',0

stop_vfs    Proc far
    push es
    push ebx
;
    mov es,ebx
    lock or es:vfs_flags,VFS_FLAG_STOPPED
    mov bx,es:vfs_server
    Signal
;
    pop ebx
    pop es    
    ret
stop_vfs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDiscInfo
;
;       DESCRIPTION:    Get VFS disc info
;
;       PARAMETERS:     AL          Disc #
;
;       RETURNS:        CX          Bytes / sector
;                       EDX:EAX     Total sectors
;                       SI          BIOS sectors / cylinder
;                       DI          BIOS heads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_disc_info_name       DB 'Get VFS Disc Info',0

get_vfs_disc_info    Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov ax,ds:[ebx].disc_arr
    or ax,ax
    stc
    jz gvdiDone
;
    mov ds,ax
    mov cx,ds:vfs_bytes_per_sector
    mov eax,ds:vfs_sectors
    mov edx,ds:vfs_sectors+4
    mov si,-1
    mov di,-1
    clc

gvdiDone:
    pop ebx
    pop ds
    ret
get_vfs_disc_info   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVfsDiscVendorInfo
;
;       DESCRIPTION:    Get VFS disc vendor info
;
;       PARAMETERS:     AL          Disc #
;                       ES:EDI      Vendor buffer
;                       ECX         Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_vfs_disc_vendor_info_name       DB 'Get VFS Disc Vendor Info',0

get_vfs_disc_vendor_info    Proc far
    push ds
    push ebx
;
    mov bx,SEG data
    mov ds,bx
    movzx ebx,al
    shl ebx,1
    mov bx,ds:[ebx].disc_arr
    or bx,bx
    stc
    jz gvdviDone
;
    sub ecx,1
    jbe gvdviDone
;
    cmp ecx,255
    jb gdvdiSizeOk
;
    mov ds,bx
    mov esi,OFFSET vfs_vendor_str
    mov ecx,255

gdvdiSizeOk:
    xor edx,edx

gdvdiCopy:
    lodsb
    or al,al
    jz gdvdiEob
;
    inc edx
    stos byte ptr es:[edi]
    loop gdvdiCopy

gdvdiEob:    

gdvdiTrim:
    sub edx,1
    jbe gdvdiTerm    
;
    mov al,es:[edi-1]
    cmp al,' '
    jne gdvdiTerm 
;       
    sub edi,1
    jmp gdvdiTrim

gdvdiTerm:
    xor al,al
    stos byte ptr es:[edi]
    clc

gvdviDone:
    pop ebx
    pop ds
    ret
get_vfs_disc_vendor_info   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadRawSectors
;
;       DESCRIPTION:    Read raw sectors
;
;       PARAMETERS:     DS              Disc sel
;                       EDX:EAX         Sector
;                       ECX             Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadRawSectors  Proc near
    push eax
    mov eax,ecx
    shl eax,3
    add eax,SIZE vfs_cmd_read
    AllocateSmallGlobalMem
    pop eax
;
    mov es:vcr_sector,eax
    mov es:vcr_sector+4,edx
    mov es:vcr_count,ecx
    mov ax,VFS_READ_MSG
    call RunVfsReq

    ret
ReadRawSectors  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadVfsDisc
;
;       DESCRIPTION:    Read VFS disc
;
;       PARAMETERS:     BL              Disc #
;                       EDX:EAX         Sector
;                       ES:EDI          Buffer
;                       ECX             Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_vfs_disc_name       DB 'Read VFS Disc',0

read_vfs_disc    Proc far
    push ds
    push ebx
;
    int 3
    push bx
    mov bx,SEG data
    mov ds,bx
    pop bx
    movzx ebx,bx
    shl ebx,1
    mov bx,ds:[ebx].disc_arr
    or bx,bx
    stc
    jz rvdDone
;
    push ecx
    mov ds,bx
    mov ebx,ecx
    dec ebx
    sub cl,ds:vfs_sector_shift
    add cl,9
    shr ebx,cl
    mov ecx,ebx
    inc ecx
    call ReadRawSectors
    pop ecx

rvdDone:
    pop ebx
    pop ds
    ret
read_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init
;
;       description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    call init_buf
    call init_server
;
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET disc_arr
    mov ecx,MAX_DISC_COUNT
    xor ax,ax
    rep stos word ptr es:[edi]
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_vfs
    mov edi,OFFSET start_vfs_name
    xor cl,cl
    mov ax,start_vfs_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_vfs
    mov edi,OFFSET stop_vfs_name
    xor cl,cl
    mov ax,stop_vfs_nr
    RegisterOsGate
;
    mov esi,OFFSET get_vfs_disc_info
    mov edi,OFFSET get_vfs_disc_info_name
    xor cl,cl
    mov ax,get_vfs_disc_info_nr
    RegisterOsGate
;
    mov esi,OFFSET get_vfs_disc_vendor_info
    mov edi,OFFSET get_vfs_disc_vendor_info_name
    xor cl,cl
    mov ax,get_vfs_disc_vendor_info_nr
    RegisterOsGate
;
    mov esi,OFFSET read_vfs_disc
    mov edi,OFFSET read_vfs_disc_name
    xor cl,cl
    mov ax,read_vfs_disc_nr
    RegisterOsGate
    clc
    ret
init    Endp


code    ENDS

    END init
