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

vfs_cmd      STRUC

vc_prev            DW ?
vc_next            DW ?
vc_thread          DW ?
vc_op              DW ?

vc_eflags          DD ?
vc_eax             DD ?
vc_ebx             DD ?
vc_ecx             DD ?
vc_edx             DD ?
vc_esi             DD ?
vc_edi             DD ?
vc_fs              DW ?
vc_gs              DW ?

vfs_cmd      ENDS


data    SEGMENT byte public 'DATA'

disc_arr        DW MAX_DISC_COUNT DUP (?)

data    ENDS


;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    extern SectorCountToBlock:near
    extern SectorToBlock:near
    extern InvalidateCache:near
    extern StopPartitions:near
    extern StopRequests:near

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

    public CreateDiscSel

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
    mov es:vfs_cached_pages,0
;
; test only
;
    mov es:vfs_max_cached_pages,1500
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
;       NAME:           FindVfsHandle
;
;       DESCRIPTION:    Find VFS handle
;
;       PARAMETERS:     BX          Prog id
;
;       RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FindVfsHandle

FindVfsHandle    Proc near
    push ds
    push es
    push fs
    push eax
    push esi
;
    mov ax,SEG data
    mov fs,ax

fvhRetry:
    xor esi,esi
    mov ecx,MAX_DISC_COUNT

fvhDiscLoop:
    mov ax,fs:[2*esi].disc_arr
    or ax,ax
    jz fvhDiscNext
;
    mov ds,ax
    cmp bx,ds:vfs_app_sel
    jne fvhCheckPart
;
    xor ebx,ebx
    jmp fvhFound

fvhCheckPart:
    push esi
    push ecx
;
    xor esi,esi
    mov ecx,MAX_VFS_PARTITIONS

fvhPartLoop:
    mov ax,ds:[2*esi].vfs_part_arr
    or ax,ax
    jz fvhPartNext
;
    mov es,ax
    cmp bx,es:vfsp_app_sel
    jne fvhPartNext
;
    inc esi
    mov ebx,esi
;
    pop ecx
    pop esi
    jmp fvhFound
    
fvhPartNext:
    add esi,2
    loop fvhPartLoop
;
    pop ecx
    pop esi

fvhDiscNext:
    inc esi
    loop fvhDiscLoop
;
    mov ax,10
    WaitMilliSec
    jmp fvhRetry

fvhFound:
    mov ax,si
    inc ax
    mov bh,al
    or ebx,VFS_HANDLE_SIG SHL 24
;
    pop esi
    pop eax
    pop fs
    pop es
    pop ds
    ret
FindVfsHandle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleToDisc
;
;       DESCRIPTION:    Convert from handle to disc sel
;
;       PARAMETERS:     AL          Disc part of handle
;
;       RETURNS:        AX          Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleToDisc

HandleToDisc    Proc near
    push ds
    push ebx
;
    or al,al
    jz htdFail
;
    mov bx,SEG data
    mov ds,ebx
;
    movzx ebx,al
    dec ebx
    cmp ebx,MAX_DISC_COUNT
    jae htdFail
;
    mov ax,ds:[2*ebx].disc_arr
    or ax,ax
    jz htdFail
;
    clc
    jmp htdDone

htdFail:
    stc
    
htdDone:
    pop ebx
    pop ds
    ret
HandleToDisc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleToPartEs
;
;       DESCRIPTION:    Convert from handle to partition selector
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        ES          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleToPartEs

HandleToPartEs    Proc near
    push eax
    push esi
;
    or bh,bh
    jz htpeFail
;
    mov eax,ebx
    shr eax,24
    cmp al,VFS_HANDLE_SIG
    jne htpeFail
;
    mov ax,SEG data
    mov es,ax
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jb htpeInRange

htpeFail:
    stc
    jmp htpeDone

htpeInRange:
    movzx esi,bh
    dec esi
    mov ax,es:[2*esi].disc_arr
    or ax,ax
    jz htpeFail
;
    mov es,eax
    movzx esi,bl
    or esi,esi
    jz htpeDisc
;
    dec esi
    mov ax,es:[2*esi].vfs_part_arr
    jmp htpeValidate

htpeDisc:
    mov ax,es:vfs_my_part

htpeValidate:
    or ax,ax
    jz htpeFail
;
    mov es,ax
    test es:vfsp_flag,VFSP_FLAG_STOPPED
    jnz htpeFail
;
    clc

htpeDone:
    pop esi
    pop eax
    ret
HandleToPartEs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           HandleToPartFs
;
;       DESCRIPTION:    Convert from handle to partition selector
;
;       PARAMETERS:     EBX         VFS Handle
;
;       RETURNS:        FS          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleToPartFs

HandleToPartFs    Proc near
    push eax
    push esi
;
    or bh,bh
    jz htpfFail
;
    mov eax,ebx
    shr eax,24
    cmp al,VFS_HANDLE_SIG
    jne htpfFail
;
    mov ax,SEG data
    mov fs,ax
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jb htpfInRange

htpfFail:
    stc
    jmp htpfDone

htpfInRange:
    movzx esi,bh
    dec esi
    mov ax,fs:[2*esi].disc_arr
    or ax,ax
    jz htpfFail
;
    mov fs,eax
    movzx esi,bl
    or esi,esi
    jz htpfDisc
;
    dec esi
    mov ax,fs:[2*esi].vfs_part_arr
    jmp htpfValidate

htpfDisc:
    mov ax,fs:vfs_my_part

htpfValidate:
    or ax,ax
    jz htpfFail
;
    mov fs,ax
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz htpfFail
;
    clc

htpfDone:
    pop esi
    pop eax
    ret
HandleToPartFs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FileHandleToPartFs
;
;       DESCRIPTION:    Convert from file handle to partition selector
;
;       PARAMETERS:     EBX         File handle
;
;       RETURNS:        FS          VFS part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FileHandleToPartFs

FileHandleToPartFs    Proc near
    push eax
    push ebx
    push esi
;
    mov ax,SEG data
    mov fs,ax
    shr ebx,16
    movzx eax,bh
    dec ax
    cmp ax,MAX_DISC_COUNT
    jb fhtpfInRange

fhtpfFail:
    stc
    jmp fhtpfDone

fhtpfInRange:
    movzx esi,bh
    dec esi
    mov ax,fs:[2*esi].disc_arr
    or ax,ax
    jz fhtpfFail
;
    mov fs,eax
    movzx esi,bl
    or esi,esi
    jz fhtpfFail
;
    dec esi
    mov ax,fs:[2*esi].vfs_part_arr
    or ax,ax
    jz fhtpfFail
;
    mov fs,ax
    test fs:vfsp_flag,VFSP_FLAG_STOPPED
    jnz fhtpfFail
;
    clc

fhtpfDone:
    pop esi
    pop ebx
    pop eax
    ret
FileHandleToPartFs    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleDiscMsg
;
;       DESCRIPTION:    Handle disc msg
;
;       PARAMETERS:     DS      Disc sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public HandleDiscMsg

HandleDiscMsg  Proc near
    GetThread
    mov ds:vfs_cmd_thread,ax

hdLoop:
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit
;
    WaitForSignal
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit

hdRetry:
    mov eax,ds:vfs_cached_pages
    cmp eax,ds:vfs_max_cached_pages
    jb hdCheckCmd
;
    call InvalidateCache

hdCheckCmd:
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit
;
    mov eax,ds:vfs_cached_pages
    cmp eax,ds:vfs_max_cached_pages
    jb hdLoop
    jmp hdRetry

hdExit:
    call StopPartitions
    call StopRequests
    mov al,ds:vfs_disc_nr
    RemoveVfsDisc
;
    mov bx,SEG data
    mov ds,bx
    movzx bx,al
    shl bx,1
    mov ds:[bx].disc_arr,0
    int 3
    ret
HandleDiscMsg  Endp

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
    push ecx
    push esi
    push edi
;
    push bx
    mov bx,SEG data
    mov ds,bx
    mov bx,flat_sel
    mov fs,bx
    pop bx
    movzx ebx,bx
    shl ebx,1
    mov bx,ds:[ebx].disc_arr
    or bx,bx
    stc
    jz rvdDone
;
    mov ds,bx
    int 3
    clc

rvdDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop ds
    ret
read_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteVfsDisc
;
;       DESCRIPTION:    Write VFS disc
;
;       PARAMETERS:     BL              Disc #
;                       EDX:EAX         Sector
;                       ES:EDI          Buffer
;                       ECX             Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_vfs_disc_name       DB 'Write VFS Disc',0

write_vfs_disc    Proc far
    push ds
    push ebx
    push ecx
    push esi
    push edi
;
    push bx
    mov bx,SEG data
    mov ds,bx
    mov bx,flat_sel
    mov fs,bx
    pop bx
    movzx ebx,bx
    shl ebx,1
    mov bx,ds:[ebx].disc_arr
    or bx,bx
    stc
    jz wvdDone
;
    mov ds,bx
    int 3
    clc

wvdDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop ds
    ret
write_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           IsVfsDisc
;
;       DESCRIPTION:    Check if VFS disc
;
;       PARAMETERS:     AL              Disc #
;
;       RETURNS:        NC              VFS disc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_vfs_disc_name       DB 'Is Vfs Disc',0

is_vfs_disc    Proc far
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
    jz ivdDone
;
    clc

ivdDone:
    pop ebx
    pop ds
    ret
is_vfs_disc   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDiscCache
;
;       DESCRIPTION:    Get current size of disc cache
;
;       PARAMETERS:     AL              Disc #
;
;       RETURNS:        EDX:EAX         Size of disc cache in bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_cache_name       DB 'Get Disc Cache',0

get_disc_cache    Proc far
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
    jz gdcDone
;
    mov ds,bx
    mov eax,ds:vfs_cached_pages
    mov edx,1000h
    mul edx
    clc

gdcDone:
    pop ebx
    pop ds
    ret
get_disc_cache   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDiscLocked
;
;       DESCRIPTION:    Get currently locked size
;
;       PARAMETERS:     AL              Disc #
;
;       RETURNS:        EDX:EAX         Locked size in bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_disc_locked_name       DB 'Get Disc Locked',0

get_disc_locked    Proc far
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
    jz gdlDone
;
    mov ds,bx
    mov eax,ds:vfs_locked_pages
    mov edx,1000h
    mul edx
    clc

gdlDone:
    pop ebx
    pop ds
    ret
get_disc_locked   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           init_disc
;
;       description:    Init disc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_disc

init_disc    Proc near
    mov ax,SEG data
    mov ds,ax
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
;
    mov esi,OFFSET write_vfs_disc
    mov edi,OFFSET write_vfs_disc_name
    xor cl,cl
    mov ax,write_vfs_disc_nr
    RegisterOsGate
;
    mov esi,OFFSET is_vfs_disc
    mov edi,OFFSET is_vfs_disc_name
    xor dx,dx
    mov ax,is_vfs_disc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_disc_cache
    mov edi,OFFSET get_disc_cache_name
    xor dx,dx
    mov ax,get_disc_cache_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_disc_locked
    mov edi,OFFSET get_disc_locked_name
    xor dx,dx
    mov ax,get_disc_locked_nr
    RegisterBimodalUserGate
    ret
init_disc    Endp


code    ENDS

    END
