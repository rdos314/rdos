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

GET_DISC_SECTORS = 0

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
;       NAME:           ServGetDiscSectors
;
;       DESCRIPTION:    Get disc sectors
;
;       PARAMETERS:     DS          Disc sel
;                       EDX:EAX     Block #
;                       ECX         Count
;                       ES          Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServGetDiscSectors   Proc near
    int 3
    clc
    mov ecx,1234
    ret
ServGetDiscSectors   Endp

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

disc_msg_tab:
dm00 DD OFFSET ServGetDiscSectors

    public HandleDiscMsg

HandleDiscMsg  Proc near
    GetThread
    mov ds:vfs_cmd_thread,ax

hdLoop:
    WaitForSignal
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jnz hdExit

hdRetry:
    EnterSection ds:vfs_cmd_section
    mov ax,ds:vfs_cmd_list
    or ax,ax
    jz hdLeave
;
    mov es,ax
;
    push ds
    push edi
;
    mov di,es:vc_next
    cmp di,ds:vfs_cmd_list
    mov ds:vfs_cmd_list,di
    mov si,es:vc_prev
    mov ds,di
    mov ds:vc_prev,si
    mov ds,si
    mov ds:vc_next,di
;
    pop edi
    pop ds
    jne hdProcess
;    
    mov ds:vfs_cmd_list,0
    
hdProcess:
    LeaveSection ds:vfs_cmd_section
;
    mov eax,es:vc_eax
    mov ebx,es:vc_ebx
    mov ecx,es:vc_ecx
    mov edx,es:vc_edx
    mov esi,es:vc_esi
    mov edi,es:vc_edi
;
    movzx ebp,es:vc_op
    shl ebp,2
    call dword ptr cs:[ebp].disc_msg_tab
;
    mov es:vc_eax,eax
    mov es:vc_ebx,ebx
    mov es:vc_ecx,ecx
    mov es:vc_edx,edx
    mov es:vc_esi,esi
    mov es:vc_edi,edi
;    
    pushfd
    pop es:vc_eflags
;
    xor bx,bx
    xchg bx,es:vc_thread
    Signal
    jmp hdRetry

hdLeave:
    LeaveSection ds:vfs_cmd_section
    jmp hdLoop

hdExit:
    ret
HandleDiscMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateMsg
;
;       DESCRIPTION:    Create disc msg
;
;       PARAMETERS:     DS      Disc sel
;                       ECX     Extra space
;
;       RETURNS:        ES      Req msg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMsg  Proc near
    push eax
    mov eax,ecx
    add eax,SIZE vfs_cmd
    AllocateSmallGlobalMem
    pop eax
;
    stc
    pushfd
    pop es:vc_eflags
;
    mov es:vc_eax,eax
    mov es:vc_ebx,ebx
    mov es:vc_ecx,ecx
    mov es:vc_edx,edx
    mov es:vc_esi,esi
    mov es:vc_edi,edi
    mov es:vc_fs,0
    mov es:vc_gs,0
    ret
CreateMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunMsg
;
;       DESCRIPTION:    Run disc msg
;
;       PARAMETERS:     DS      Disc sel
;                       ES      Req msg
;                       AX      Op
;
;       RETURNS:        ES      Reply msg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunMsg  Proc near
    mov es:vc_op,ax
;
    GetThread
    mov es:vc_thread,ax
;
    EnterSection ds:vfs_cmd_section
;
    mov ax,ds:vfs_cmd_list
    or ax,ax
    je rmEmpty
;    
    push ds
    push esi
;
    mov ds,ax
    mov si,ds:vc_prev
    mov ds:vc_prev,es
    mov ds,si
    mov ds:vc_next,es
    mov es:vc_next,ax
    mov es:vc_prev,si
;
    pop esi
    pop ds
    jmp rmLeave
    
rmEmpty:
    mov es:vc_next,es
    mov es:vc_prev,es
    mov ds:vfs_cmd_list,es

rmLeave:
    LeaveSection ds:vfs_cmd_section
;
    mov bx,ds:vfs_cmd_thread
    Signal

rmWait:
    WaitForSignal
    test ds:vfs_flags,VFS_FLAG_STOPPED
    jz rmCheck
;
    stc
    jmp rmDone

rmCheck:
    mov ax,es:vc_thread
    or ax,ax
    jnz rmWait
;
    mov eax,es:vc_eax
    mov ebx,es:vc_ebx
    mov ecx,es:vc_ecx
    mov edx,es:vc_edx
    mov esi,es:vc_esi
    mov edi,es:vc_edi
;
    push es:vc_eflags
    popfd

rmDone:
    ret
RunMsg  Endp

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
;
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
    mov cl,9
    sub cl,ds:vfs_sector_shift
    shr ebx,cl
    mov ecx,ebx
    inc ecx
    call SectorCountToBlock
;
    shl ecx,3
    call CreateMsg
;
    mov ax,GET_DISC_SECTORS
    call RunMsg
    int 3
;
    FreeMem
    pop ecx

rvdDone:
    pop ebx
    pop ds
    ret
read_vfs_disc   Endp

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
    InitSection ds:vfs_cmd_section
    mov ds:vfs_cmd_list,0
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
    ret
init_disc    Endp


code    ENDS

    END
