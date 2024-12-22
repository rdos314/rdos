;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2017, Leif Ekblad
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
; CHANDLE.ASM
; C-library handle compatibility layer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
include ..\wait.inc
INCLUDE ..\driver.def
INCLUDE ..\os\exec.def
INCLUDE vfs.inc

    .386p

MAX_HANDLES           = 512
SYS_HANDLE_COUNT      = 1024
SYS_BITMAP_COUNT      = SYS_HANDLE_COUNT SHR 5
HANDLE_WAIT_OBJ_COUNT = 8

;
; this should always be 16 bytes!
;

sys_handle_struc    STRUC

sh_type              DW ?
sh_sel               DW ?
sh_ref_count         DW ?
sh_read_wait_sel     DW ?
sh_write_wait_sel    DW ?
sh_exc_wait_sel      DW ?
sh_resv              DW ?,?

sys_handle_struc    ENDS

;
; this should always be 16 bytes!

handle_proc_struc       STRUC

hp_pos          DD ?,?
hp_handle       DW ?
hp_access       DW ?
hp_vfs_sel      DW ?
hp_vfs_handle   DW ?

handle_proc_struc       ENDS


handle_wait_struc     STRUC

hw_handle            DW ?
hw_count             DW ?
hw_arr               DW HANDLE_WAIT_OBJ_COUNT DUP(?)

handle_wait_struc     ENDS

handle_struc    STRUC

h_section       section_typ <>
h_arr           DD 4 * MAX_HANDLES DUP(?)

handle_struc    ENDS

socket_wait_header STRUC

sw_obj          wait_obj_header <>
sw_handle       DW ?

socket_wait_header ENDS

data    SEGMENT byte public 'DATA'

hd_section       section_typ <>
hd_proc_count    DW ?

hd_proc_arr      DW MAX_PROC_COUNT DUP(?)
hd_sys_bitmap    DD SYS_BITMAP_COUNT DUP(?)
hd_sys_arr       DD 4 * SYS_HANDLE_COUNT DUP(?)

data       ENDS


code    SEGMENT byte public 'CODE'
    
    assume cs:code

    extern MapVfsFile_:near
    extern GrowVfsFile_:near
    extern UpdateVfsFile_:near
    extern DeleteVfsFile_:near
    extern GetVfsFileInfo:near
    extern GetVfsFilePos:near
    extern SetVfsFilePos:near
    extern GetVfsFileSize:near
    extern SetVfsFileSize:near
    extern DupVfsFile:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateCHandle
;
;           DESCRIPTION:    Create C handle
;
;           RETURNS:        AX          C handle selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_c_handle_name DB 'Create C Handle', 0

create_c_handle Proc far
    push ds
    push es
    push ebx
    push ecx
    push edx
    push esi
    push edi
;    
    mov eax,SEG data
    mov ds,eax
;
    mov edi,OFFSET hd_sys_arr
    inc ds:[edi].sh_ref_count
;
    add edi,16
    add ds:[edi].sh_ref_count,2
;
    mov eax,SIZE handle_struc
    AllocateSmallGlobalMem
;    
    mov edi,OFFSET h_arr
    mov es:[edi].hp_handle,1
    mov es:[edi].hp_access,IO_READ OR IO_ISTTY
    mov es:[edi].hp_vfs_sel,0
    mov es:[edi].hp_vfs_handle,0
    mov es:[edi].hp_pos,0
    mov es:[edi].hp_pos+4,0
;
    add edi,16
    mov es:[edi].hp_handle,2
    mov es:[edi].hp_access,IO_WRITE OR IO_ISTTY
    mov es:[edi].hp_vfs_sel,0
    mov es:[edi].hp_vfs_handle,0
    mov es:[edi].hp_pos,0
    mov es:[edi].hp_pos+4,0
;
    add edi,16
    mov es:[edi].hp_handle,2
    mov es:[edi].hp_access,IO_WRITE OR IO_ISTTY
    mov es:[edi].hp_vfs_sel,0
    mov es:[edi].hp_vfs_handle,0
    mov es:[edi].hp_pos,0
    mov es:[edi].hp_pos+4,0
;    
    mov ecx,MAX_HANDLES - 3

nsLoop:
    add edi,16
    mov es:[edi].hp_handle,0
    mov es:[edi].hp_access,0
    mov es:[edi].hp_vfs_sel,0
    mov es:[edi].hp_vfs_handle,0
    mov es:[edi].hp_pos,0
    mov es:[edi].hp_pos+4,0
    loop nsLoop
;    
    InitSection es:h_section
;
    EnterSection ds:hd_section
    movzx ebx,ds:hd_proc_count
    shl ebx,1
    mov ds:[ebx].hd_proc_arr,es
    inc ds:hd_proc_count
    LeaveSection ds:hd_section
;
    mov eax,es
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx    
    pop es
    pop ds
    ret
create_c_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloneCHandle
;
;           DESCRIPTION:    Clone C handle
;
;           PARAMETERS:     AX          Incoming C handle sel
;
;           RETURNS:        AX          Cloned C handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_c_handle_name  DB 'Clone C Handle', 0

clone_c_handle  Proc far
    push ds
    push es
    push ebx
    push ecx
;
    mov ds,eax
;
    mov eax,SIZE handle_struc
    AllocateSmallGlobalMem
    InitSection es:h_section
;    
    mov ecx,MAX_HANDLES
    xor ebx,ebx

ncLoop:
    push ebx
    push ecx
;
    shl ebx,4
    add ebx,OFFSET h_arr
;
    mov es:[ebx].hp_handle,0
    mov es:[ebx].hp_access,0
    mov es:[ebx].hp_vfs_sel,0
    mov es:[ebx].hp_vfs_handle,0
    mov es:[ebx].hp_pos,0
    mov es:[ebx].hp_pos+4,0
;
    EnterSection ds:h_section
    mov ax,ds:[ebx].hp_handle
    or ax,ax
    jz ncNextLeave
;
    mov es:[ebx].hp_handle,ax
;
    push ds
    push ebx
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
    add ds:[ebx].sh_ref_count,1
;
    pop ebx
    pop ds
;
    mov ax,ds:[ebx].hp_access
    mov es:[ebx].hp_access,ax
;
    mov ax,ds:[ebx].hp_vfs_sel
    mov es:[ebx].hp_vfs_sel,ax
;
    mov eax,ds:[ebx].hp_pos
    mov es:[ebx].hp_pos,eax
    mov eax,ds:[ebx].hp_pos+4
    mov es:[ebx].hp_pos+4,eax

ncNextLeave:
    LeaveSection ds:h_section

ncNext:
    pop ecx
    pop ebx
;
    inc ebx
    sub ecx,1
    jnz ncLoop
;
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:hd_section
    movzx ebx,ds:hd_proc_count
    shl ebx,1
    mov ds:[ebx].hd_proc_arr,es
    inc ds:hd_proc_count
    LeaveSection ds:hd_section
;
    mov eax,es
;
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
clone_c_handle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteCHandle
;
;           DESCRIPTION:    Delete C Handle
;
;           PARAMETERS:     AX        C handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_c_handle_name DB 'Delete C Handle', 0

delete_c_handle Proc far
    push ds
    push es
    pushad
;
    mov edx,SEG data
    mov ds,edx
;
    EnterSection ds:hd_section
    movzx ecx,ds:hd_proc_count
    mov ebx,OFFSET hd_proc_arr

ntUnlinkLoop:
    cmp ax,ds:[ebx]
    je ntUnlinkFound
;
    add ebx,2
    loop ntUnlinkLoop
;
    int 3

ntUnlinkFound:
    sub ecx,1
    jz ntUnlinked
;
    mov dx,ds:[ebx+2]
    mov ds:[ebx],dx
    add ebx,2
    sub ecx,1
    jna ntUnlinkFound

ntUnlinked:
    dec ds:hd_proc_count
    LeaveSection ds:hd_section
;
    mov ds,eax
;    
    mov ecx,MAX_HANDLES
    xor ebx,ebx

ntLoop:
    push ecx
    push ebx
;
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
    or ax,ax
    jz ntNext
;
    pop ebx
    CloseHandle
    push ebx

ntNext:
    pop ebx
    pop ecx
;
    inc ebx
    sub ecx,1
    jnz ntLoop
;
    mov eax,ds
    mov es,eax
    xor ax,ax
    mov ds,eax
    FreeMem
;
    popad
    pop es
    pop ds
    ret
delete_c_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           allocate_c_handle
;
;           DESCRIPTION:    Allocate C handle
;
;           PARAMETERS:     AX          Handle type
;                           DX          Sel
;
;           RETURNS:        BX          Entry handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_c_handle_name  DB 'Allocate C Handle', 0

allocate_c_handle     Proc far
    push ds
    push eax
    push ecx
    push edx
    push edi
;
    push eax
    push edx
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:hd_section
;
    mov ecx,SYS_BITMAP_COUNT  
    xor edi,edi
    mov bx,OFFSET hd_sys_bitmap

achLoop:
    mov eax,ds:[bx]
    not eax
    bsf edx,eax
    jnz achOk
;
    add bx,4
    add edi,32
;
    loop achLoop
;
    stc
    pop edx
    pop eax
    jmp achLeave

achOk:
    add edx,edi
    bts ds:hd_sys_bitmap,edx
;    
    mov edi,edx
    shl edi,4
    add edi,OFFSET hd_sys_arr
;
    pop edx
    pop eax
;
    mov ds:[edi].sh_type,ax
    mov ds:[edi].sh_sel,dx
    mov ds:[edi].sh_ref_count,1
    mov ds:[edi].sh_read_wait_sel,0
    mov ds:[edi].sh_write_wait_sel,0
    mov ds:[edi].sh_exc_wait_sel,0
;
    mov ebx,edi
    sub ebx,OFFSET hd_sys_arr
    shr ebx,4
    inc bx
    clc

achLeave:
    LeaveSection ds:hd_section
; 
    pop edi
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
allocate_c_handle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ref_c_handle
;
;           DESCRIPTION:    Allocate C handle
;
;           PARAMETERS:     AX          Handle type
;                           BX          Entry handle
;                           DX          Sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ref_c_handle_name  DB 'Ref C Handle', 0

ref_c_handle     Proc far
    push ds
    push edi
;
    mov di,SEG data
    mov ds,edi
    EnterSection ds:hd_section
;
    cmp bx,SYS_BITMAP_COUNT
    jae rchLeaveFail
;
    or bx,bx
    jz rchLeaveFail
;
    push eax
    push edx
;
    movzx edi,bx
    dec edi
    shl edi,4
    add edi,OFFSET hd_sys_arr
;
    movzx eax,bx
    dec eax
    bt ds:hd_sys_bitmap,eax
;
    pop edx
    pop eax
    jnc rchLeaveFail
;
    cmp ax,ds:[edi].sh_type
    jne rchLeaveFail
;
    cmp dx,ds:[edi].sh_sel
    jne rchLeaveFail
;
    add ds:[edi].sh_ref_count,1
    clc
    jmp rchLeave

rchLeaveFail:
    stc

rchLeave: 
    LeaveSection ds:hd_section
;
    pop edi
    pop ds
    ret
ref_c_handle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           allocate_proc_handle
;
;           DESCRIPTION:    Allocate process handle
;
;           PARAMETERS:     DS          C handle sel
;                           BX          C Handle
;                           CX          Mode
;                           EDX:EAX     Position
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public allocate_proc_handle

allocate_proc_handle     Proc near
    push esi
;
    push ecx
    push edx
;
    mov ecx,MAX_HANDLES
    mov esi,OFFSET h_arr
    EnterSection ds:h_section

aphLoop:    
    mov dx,ds:[esi].hp_handle
    or dx,dx
    jz aphFound
;
    add esi,16
    loop aphLoop
;
    pop edx
    pop ecx
    LeaveSection ds:h_section
    stc
    jmp aphDone

aphFound:    
    pop edx
    pop ecx
;
    mov ds:[esi].hp_handle,bx
    mov ds:[esi].hp_access,cx
    mov ds:[esi].hp_vfs_sel,0
    mov ds:[esi].hp_vfs_handle,0
    mov ds:[esi].hp_pos,eax
    mov ds:[esi].hp_pos+4,edx
    LeaveSection ds:h_section
;
    mov ebx,esi
    sub ebx,OFFSET h_arr
    shr ebx,4
    movzx ebx,bx
    clc

aphDone:   
    pop esi
    ret
allocate_proc_handle  Endp   
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateCProcHandle
;
;           DESCRIPTION:    Allocate C process handle
;
;           PARAMETERS:     BX          C Handle
;                           CX          Mode
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_c_proc_handle_name DB 'Allocate C Proc Handle', 0

allocate_c_proc_handle     Proc far
    push ds
    push eax
    push ecx
    push edx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    mov ax,bx
    push ecx
    mov ecx,MAX_HANDLES
    mov ebx,OFFSET h_arr
    EnterSection ds:h_section

acphLoop:    
    mov dx,ds:[ebx].hp_handle
    or dx,dx
    jz acphFound
;
    add bx,16
    loop acphLoop
;
    pop ecx
    LeaveSection ds:h_section
    stc
    jmp acphDone

acphFound:    
    pop ecx
    mov ds:[ebx].hp_handle,ax
    mov ds:[ebx].hp_access,cx
    mov ds:[ebx].hp_vfs_sel,0
    mov ds:[ebx].hp_vfs_handle,0
    mov ds:[ebx].hp_pos,0
    mov ds:[ebx].hp_pos+4,0
    LeaveSection ds:h_section
;
    sub ebx,OFFSET h_arr
    shr ebx,4
    clc
    movzx ebx,bx

acphDone:   
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
allocate_c_proc_handle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RefVfsHandle
;
;           DESCRIPTION:    Reference VFS handle
;
;           PARAMETERS:     BX          Entry handle
;                           DS          File sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RefVfsHandle

RefVfsHandle     Proc near
    push ds
    push eax
    push edx
    push edi
;
    mov dx,ds
    mov ax,SEG data
    mov ds,eax
    EnterSection ds:hd_section
;
    cmp bx,SYS_BITMAP_COUNT
    jae rvhLeaveFail
;
    or bx,bx
    jz rvhLeaveFail
;
    movzx edi,bx
    dec edi
    shl edi,4
    add edi,OFFSET hd_sys_arr
;
    movzx eax,bx
    dec eax
    bt ds:hd_sys_bitmap,eax
    jnc rvhLeaveFail
;
    cmp ds:[edi].sh_type,C_HANDLE_VFS
    jne rvhLeaveFail
;
    cmp dx,ds:[edi].sh_sel
    jne rvhLeaveFail
;
    add ds:[edi].sh_ref_count,1
    clc
    jmp rvhLeave

rvhLeaveFail:
    stc

rvhLeave: 
    LeaveSection ds:hd_section
;
    pop edi
    pop edx
    pop eax
    pop ds
    ret
RefVfsHandle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenToIo
;
;       DESCRIPTION:    Convert open flags to IO flags
;
;       PARAMETERS:     CX              Open flags
;
;       RETURNS:        AX              IO flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenToIo      Proc near
    mov al,cl
    and al,3
    cmp al,O_RDWR
    je otiRdWr
;
    cmp al,O_RDONLY
    je otiRdOnly
;
    cmp al,O_WRONLY
    je otiWrOnly
;
    xor ax,ax
    jmp otiAccessOk

otiRdWr:
    mov ax,IO_READ OR IO_WRITE
    jmp otiAccessOk

otiRdOnly:
    mov ax,IO_READ
    jmp otiAccessOk

otiWrOnly:
    mov ax,IO_WRITE

otiAccessOk:
    test cx,O_APPEND
    jz otiAppendOk
;
    or ax,IO_APPEND 

otiAppendOk:
    ret
OpenToIo  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateProcHandle
;
;           DESCRIPTION:    Allocate proc handle
;
;           PARAMETERS:     AX          Map sel
;                           BX          Proc sel
;                           CX          Mode
;                           DX          Proc handle
;
;           RETURNS:        BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateProcHandle

AllocateProcHandle     Proc near
    push ds
    push eax
    push edx
    push esi
;
    mov esi,edx
;
    push eax
    push ebx
    push ecx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    mov ecx,MAX_HANDLES
    mov ebx,OFFSET h_arr
    EnterSection ds:h_section

amhLoop:    
    mov dx,ds:[ebx].hp_handle
    or dx,dx
    jz amhFound
;
    add ebx,16
    loop amhLoop
;
    pop ecx
    pop edx
    pop eax
    LeaveSection ds:h_section
    stc
    jmp amhDone

amhFound:        
    pop ecx
    pop edx
    pop eax
;
    mov ds:[ebx].hp_handle,dx
    mov ds:[ebx].hp_vfs_sel,ax
    mov ds:[ebx].hp_vfs_handle,si
    mov ds:[ebx].hp_pos,0
    mov ds:[ebx].hp_pos+4,0
;
    call OpenToIo
    mov ds:[ebx].hp_access,ax
;
    LeaveSection ds:h_section
;
    sub ebx,OFFSET h_arr
    shr ebx,4
    clc
    movzx ebx,bx

amhDone:   
    pop esi
    pop edx
    pop eax
    pop ds
    ret
AllocateProcHandle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenHandle
;
;           DESCRIPTION:    Open C handle
;
;           PARAMETERS:     ES:(E)DI    Name
;                           CX          Mode
;
;           RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_handle_name  DB 'Open C Handle', 0

open_handle     Proc near
    push ds
    push eax
    push ecx
    push edx
    push ebp
;
    OpenLegacyFile
    jc ohFail
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    call OpenToIo
;
    push ecx
    mov cx,ax
    xor eax,eax
    xor edx,edx
    call allocate_proc_handle
    pop ecx
    jnc ohCom
;
    int 3

ohCom:
    test cx,O_CREAT OR O_TRUNC
    jz ohSizeOk
;
    xor eax,eax
    xor edx,edx
    SetHandleSize64

ohSizeOk:
    clc
    jmp ohDone

ohFail:
    xor ebx,ebx
    jmp ohDone

ohDone:
    pop ebp
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
open_handle     Endp

open_handle16    PROC far
    push edi
    movzx edi,di
    call open_handle
    pop edi
    ret
open_handle16    ENDP

open_handle32    PROC far
    call open_handle
    ret
open_handle32    ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteHandle
;
;           DESCRIPTION:    Delete C handle object (file)
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle_name  DB 'Delete C Handle', 0

delete_handle     Proc far
    push ds
    push ebx
    push edx
    push esi
    push ebp
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    pop eax
;    
    cmp bx,MAX_HANDLES
    jae duhDone
;   
    mov si,bx
    shl esi,16
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov si,ds:[ebx].hp_vfs_sel
    mov bp,ds:[ebx].hp_handle
;
    cmp bp,SYS_HANDLE_COUNT
    jae duhDone
;    
    or bp,bp
    jz duhDone
;
    movzx ebx,bp
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov ebp,SEG data
    mov ds,ebp
;
    movzx ebp,ds:[ebx].sh_type
    cmp ebp,C_HANDLE_VFS
    stc
    jne vuhDone
;    
    call DeleteVfsFile_

duhDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop ds    
    ret
delete_handle    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseHandle
;
;           DESCRIPTION:    Close C handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_handle_name  DB 'Close C Handle', 0

close_dummy     Proc near
    ret
close_dummy     Endp

close_file      Proc near
    mov bx,ax
    CloseLegacyFile
    ret
close_file      Endp

close_tcp_socket	Proc near
    mov bx,ax
    CloseTcpSocket
    ret
close_tcp_socket	Endp

close_udp_socket	Proc near
    mov bx,ax
    CloseUdpSocket
    ret
close_udp_socket	Endp

close_vfs      Proc near
    ret
close_vfs      Endp

close_tab:
ct00  DD OFFSET close_dummy
ct01  DD OFFSET close_file
ct02  DD OFFSET close_dummy
ct03  DD OFFSET close_dummy
ct04  DD OFFSET close_tcp_socket
ct05  DD OFFSET close_udp_socket
ct06  DD OFFSET close_vfs
ct07  DD OFFSET close_dummy
ct08  DD OFFSET close_dummy
ct09  DD OFFSET close_dummy


close_handle     Proc far
    push ds
    push eax
    push ebx
    push ecx
    push edx
    push ebp
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ax,ds:pf_c_handle_sel
    or ax,ax
    jz chFail
;
    mov ds,eax
;    
    cmp bx,MAX_HANDLES
    jae chFail
;
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    EnterSection ds:h_section
;
    mov ds:[ebx].hp_access,0
    mov ds:[ebx].hp_pos,0
    mov ds:[ebx].hp_pos+4,0
;
    xor ax,ax
    xchg ax,ds:[ebx].hp_handle
;
    xor dx,dx
    xchg dx,ds:[ebx].hp_vfs_sel
;
    xor bp,bp
    xchg bp,ds:[ebx].hp_vfs_handle
    LeaveSection ds:h_section
;
    or dx,dx
    jz chVfsOk
;
    push eax
;
    mov eax,edx
    mov ebx,ebp
;    call FreeUserHandle
;    call CloseVfsProc
;
    pop eax

chVfsOk:
    cmp ax,SYS_HANDLE_COUNT
    jae chFail
;    
    or ax,ax
    jz chFail
;
    movzx ebx,ax
    dec ebx
    mov ecx,ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:hd_section
;
    sub ds:[ebx].sh_ref_count,1
    jnz chLeave
;
    xor ax,ax
    xchg ax,ds:[ebx].sh_sel
    movzx ebp,ds:[ebx].sh_type
;    mov bx,ds:[ebx].sh_handle
    btr ds:hd_sys_bitmap,ecx
;
    cmp ebp,10
    jae chLeave
;
    call dword ptr cs:[4*ebp].close_tab

chLeave:
    LeaveSection ds:hd_section
    xor ebx,ebx
    jmp chDone

chFail:
    xor ebx,ebx

chDone:
    pop ebp
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds    
    ret
close_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleMap
;
;           DESCRIPTION:    Get mapping info for VFS file
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Index
;                           EDI         Flat address of file info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_map_name  DB 'Get C Handle Map', 0

get_handle_map     Proc far
    push ds
    push ebx
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghmmFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
;
    movzx eax,ds:[ebx].hp_vfs_handle
    or eax,eax
    jz ghmmFail
;
    mov bx,ds:[ebx].hp_vfs_sel
    or bx,bx
    jz ghmmFail
;
    call GetVfsFileInfo
    clc
    jmp ghmmDone

ghmmFail:
    xor eax,eax
    xor edi,edi
    stc

ghmmDone:
    pop ebx
    pop ds    
    ret
get_handle_map     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapHandle
;
;           DESCRIPTION:    Map handle
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     File position
;;                          ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_handle_name  DB 'Map Handle', 0

map_handle     Proc far
    push ds
    push ebx
    push edx
    push esi
    push ebp
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    pop eax
;    
    cmp bx,MAX_HANDLES
    jae vmhDone
;   
    mov si,bx
    shl esi,16
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov si,ds:[ebx].hp_access
    test si,IO_READ
    jz vmhDone
;
    mov si,ds:[ebx].hp_vfs_sel
    mov bp,ds:[ebx].hp_handle
;
    cmp bp,SYS_HANDLE_COUNT
    jae vmhDone
;    
    or bp,bp
    jz vmhDone
;
    movzx ebx,bp
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov ebp,SEG data
    mov ds,ebp
;
    movzx ebp,ds:[ebx].sh_type
    cmp ebp,C_HANDLE_VFS
    stc
    jne vmhDone
;    
    call MapVfsFile_

vmhDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop ds    
    ret
map_handle     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateHandle
;
;           DESCRIPTION:    Update handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_handle_name  DB 'Update Handle', 0

update_handle     Proc far
    push ds
    push ebx
    push edx
    push esi
    push ebp
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    pop eax
;    
    cmp bx,MAX_HANDLES
    jae vuhDone
;   
    mov si,bx
    shl esi,16
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov si,ds:[ebx].hp_access
    test si,IO_READ
    jz vuhDone
;
    mov si,ds:[ebx].hp_vfs_sel
    mov bp,ds:[ebx].hp_handle
;
    cmp bp,SYS_HANDLE_COUNT
    jae vuhDone
;    
    or bp,bp
    jz vuhDone
;
    movzx ebx,bp
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov ebp,SEG data
    mov ds,ebp
;
    movzx ebp,ds:[ebx].sh_type
    cmp ebp,C_HANDLE_VFS
    stc
    jne vuhDone
;    
    call UpdateVfsFile_

vuhDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop ds    
    ret
update_handle     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GrowHandle
;
;           DESCRIPTION:    Grow handle
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     File position
;;                          ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

grow_handle_name  DB 'Grow Handle', 0

grow_handle     Proc far
    push ds
    push ebx
    push edx
    push esi
    push ebp
;
    push eax
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    pop eax
;    
    cmp bx,MAX_HANDLES
    jae vghDone
;   
    mov si,bx
    shl esi,16
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov si,ds:[ebx].hp_access
    test si,IO_READ
    jz vghDone
;
    mov si,ds:[ebx].hp_vfs_sel
    mov bp,ds:[ebx].hp_handle
;
    cmp bp,SYS_HANDLE_COUNT
    jae vghDone
;    
    or bp,bp
    jz vghDone
;
    movzx ebx,bp
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov ebp,SEG data
    mov ds,ebp
;
    movzx ebp,ds:[ebx].sh_type
    cmp ebp,C_HANDLE_VFS
    stc
    jne vghDone
;    
    call GrowVfsFile_

vghDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop ds    
    ret
grow_handle     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PollHandle
;
;           DESCRIPTION:    Poll C handle
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_handle_name  DB 'Poll C Handle', 0

poll_dummy      Proc near
    stc
    ret
poll_dummy      Endp

poll_file       Proc near
    ReadLegacyFile
    ret
poll_file       Endp

poll_tcp_socket       Proc near
    PollTcpSocket
    ret
poll_tcp_socket       Endp

poll_udp_socket       Proc near
    PollUdpSocket
    ret
poll_udp_socket       Endp

poll_vfs_file        Proc near
;    call ReadVfsFile
    ret
poll_vfs_file        Endp

poll_tab:
pt00  DD OFFSET poll_dummy
pt01  DD OFFSET poll_file
pt02  DD OFFSET poll_dummy
pt03  DD OFFSET poll_dummy
pt04  DD OFFSET poll_tcp_socket
pt05  DD OFFSET poll_udp_socket
pt06  DD OFFSET poll_vfs_file
pt07  DD OFFSET poll_dummy
pt08  DD OFFSET poll_dummy
pt09  DD OFFSET poll_dummy

poll_handle     Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae phFail
;   
    mov si,bx
    shl esi,16
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_access
    test ax,IO_READ
    jz phFail
;
    mov si,ds:[ebx].hp_vfs_sel
    or si,si
    jnz phGetVfs
;
    mov eax,ds:[ebx].hp_pos
    mov edx,ds:[ebx].hp_pos+4
    jmp phGetOk

phGetVfs:
    push ebx
    push ecx
;
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call GetVfsFilePos
;
    pop ecx
    pop ebx

phGetOk:
    mov bp,ds:[ebx].hp_handle
;
    cmp bp,SYS_HANDLE_COUNT
    jae phFail
;    
    or bp,bp
    jz phFail
;
    push ds
    push ebx
;
    movzx ebx,bp
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov ebp,SEG data
    mov ds,ebp
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].poll_tab
;
    pop ebx
    pop ds
;
    mov eax,ecx
    jmp phDone

phFail:
    mov eax,-1

phDone:
    pop ebp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds    
    ret
poll_handle     Endp

poll_handle16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call poll_handle
;
    pop edi
    pop ecx
    ret
poll_handle16    ENDP

poll_handle32    PROC far
    call poll_handle
    ret
poll_handle32    ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadHandle
;
;           DESCRIPTION:    Read C handle
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_handle_name  DB 'Read C Handle', 0

read_dummy      Proc near
    stc
    ret
read_dummy      Endp

read_stdin       Proc near
    ReadCConsole
    clc
    ret
read_stdin       Endp

read_file       Proc near
    ReadLegacyFile
    ret
read_file       Endp

read_tcp_socket       Proc near
    ReadTcpSocket
    ret
read_tcp_socket       Endp

read_udp_socket       Proc near
    ReadUdpSocket
    ret
read_udp_socket       Endp

read_vfs_file        Proc near
;    call ReadVfsFile
    ret
read_vfs_file        Endp

read_tab:
rt00  DD OFFSET read_dummy
rt01  DD OFFSET read_file
rt02  DD OFFSET read_stdin
rt03  DD OFFSET read_dummy
rt04  DD OFFSET read_tcp_socket
rt05  DD OFFSET read_udp_socket
rt06  DD OFFSET read_vfs_file
rt07  DD OFFSET read_dummy
rt08  DD OFFSET read_dummy
rt09  DD OFFSET read_dummy

read_handle     Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae rhFail
;   
    mov si,bx
    shl esi,16
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_access
    test ax,IO_READ
    jz rhFail
;
    mov si,ds:[ebx].hp_vfs_sel
    or si,si
    jnz rhGetVfs
;
    mov eax,ds:[ebx].hp_pos
    mov edx,ds:[ebx].hp_pos+4
    jmp rhGetOk

rhGetVfs:
    push ebx
    push ecx
;
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call GetVfsFilePos
;
    pop ecx
    pop ebx

rhGetOk:
    mov bp,ds:[ebx].hp_handle
;
    cmp bp,SYS_HANDLE_COUNT
    jae rhFail
;    
    or bp,bp
    jz rhFail
;
    push ds
    push ebx
;
    movzx ebx,bp
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov ebp,SEG data
    mov ds,ebp
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].read_tab
;
    pop ebx
    pop ds
    jc rhFail
;
    or si,si
    jnz rhSetVfs
;
    mov ds:[ebx].hp_pos,eax
    mov ds:[ebx].hp_pos+4,edx
    jmp rhSetOk

rhSetVfs:
    push ebx
    push ecx
;
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call SetVfsFilePos
;
    pop ecx
    pop ebx

rhSetOk:
    mov eax,ecx
    jmp rhDone

rhFail:
    xor eax,eax
    stc

rhDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds    
    ret
read_handle     Endp

read_handle16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call read_handle
;
    pop edi
    pop ecx
    ret
read_handle16    ENDP

read_handle32    PROC far
    call read_handle
    ret
read_handle32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHandle
;
;           DESCRIPTION:    Write C handle
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        EAX         Written count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_handle_name  DB 'Write C Handle', 0

write_dummy     Proc near
    stc
    ret
write_dummy     Endp

write_stdout      Proc near
    WriteCConsole
    ret
write_stdout      Endp

write_file      Proc near
    WriteLegacyFile
    clc
    ret
write_file      Endp

write_tcp_socket      Proc near
    WriteTcpSocket
    ret
write_tcp_socket      Endp

write_udp_socket      Proc near
    WriteUdpSocket
    ret
write_udp_socket      Endp

write_vfs_file        Proc near
;    call WriteVfsFile
    ret
write_vfs_file        Endp

write_tab:
wt00  DD OFFSET write_dummy
wt01  DD OFFSET write_file
wt02  DD OFFSET write_dummy
wt03  DD OFFSET write_stdout
wt04  DD OFFSET write_tcp_socket
wt05  DD OFFSET write_udp_socket
wt06  DD OFFSET write_vfs_file
wt07  DD OFFSET write_dummy
wt08  DD OFFSET write_dummy
wt09  DD OFFSET write_dummy

write_handle     Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae whFail
;   
    mov si,bx
    shl esi,16
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_access
    test ax,IO_WRITE
    jz whFail
;
    mov si,ds:[ebx].hp_vfs_sel
;
    test ax,IO_APPEND
    jnz whGetAppend
;
    or si,si
    jnz whGetVfs
;
    mov eax,ds:[ebx].hp_pos
    mov edx,ds:[ebx].hp_pos+4
    jmp whGetOk

whGetVfs:
    push ebx
    push ecx
;
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call GetVfsFilePos
;
    pop ecx
    pop ebx
    jmp whGetOk

whGetAppend:
    push ebx
;
    mov ebx,esi
    shr ebx,16
    GetHandleSize64
;
    pop ebx

whGetOk:
    mov bp,ds:[ebx].hp_handle
;
    cmp bp,SYS_HANDLE_COUNT
    jae whFail
;    
    or bp,bp
    jz whFail
;
    push ds
    push ebx
;
    movzx ebx,bp
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov ebp,SEG data
    mov ds,ebp
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].write_tab

whWriteOk:
    pop ebx
    pop ds
    jc whFail
;
    or si,si
    jnz whSetVfs
;
    mov ds:[ebx].hp_pos,eax
    mov ds:[ebx].hp_pos+4,edx
    jmp whSetOk

whSetVfs:
    push ebx
    push ecx
;
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call SetVfsFilePos
;
    pop ecx
    pop ebx

whSetOk:
    mov eax,ecx
    jmp whDone

whFail:
    xor eax,eax
    stc

whDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds    
    ret
write_handle    Endp

write_handle16  Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call write_handle
;
    pop edi
    pop ecx
    ret
write_handle16    ENDP

write_handle32    PROC far
    call write_handle
    ret
write_handle32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DupHandle
;
;           DESCRIPTION:    Dup C handle
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EBX         New handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dup_handle_name  DB 'Dup C Handle', 0

dup_handle     Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae dhFail
;   
    movzx esi,bx
    shl esi,4
    add esi,OFFSET h_arr
    mov bx,ds:[esi].hp_handle
;
    cmp bx,SYS_HANDLE_COUNT
    jae dhFail
;    
    or bx,bx
    jz dhFail
;
    mov edi,SEG data
    mov es,edi
    movzx edi,bx
    dec edi
    shl edi,4
    add edi,OFFSET hd_sys_arr
    inc es:[edi].sh_ref_count
;
    mov bp,ds:[esi].hp_vfs_sel
    or bp,bp
    jnz dhVfs
;
    mov eax,ds:[esi].hp_pos
    mov edx,ds:[esi].hp_pos+4
    jmp dhAlloc

dhVfs:
    push ebx
    mov bx,ds:[esi].hp_vfs_sel
    mov cx,ds:[esi].hp_vfs_handle
    call GetVfsFilePos
    pop ebx

dhAlloc:
    mov cx,ds:[esi].hp_access
    call allocate_proc_handle
    jc dhFailDec
;
    or bp,bp
    jz dhDone
;
    push ebx
    mov bx,ds:[esi].hp_vfs_sel
    call DupVfsFile   
    pop ebx
;
    mov ax,ds:[esi].hp_vfs_sel
    movzx esi,bx
    shl esi,4
    add esi,OFFSET h_arr
    mov ds:[esi].hp_vfs_sel,ax
    mov ds:[esi].hp_vfs_handle,dx
    clc
    jmp dhDone

dhFailDec:
    dec es:[edi].sh_ref_count

dhFail:
    mov ebx,-1
    stc

dhDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds    
    ret
dup_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Dup2Handle
;
;           DESCRIPTION:    Dup2 C handle
;
;           PARAMETERS:     BX          Src handle
;                           AX          Dest handle
;
;           RETURNS:        EBX         New handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dup2_handle_name  DB 'Dup2 C Handle', 0

dup2_handle     Proc far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    mov bp,ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae dh2Fail
;   
    movzx esi,bx
    shl esi,4
    add esi,OFFSET h_arr
    mov ax,ds:[esi].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae dh2Fail
;    
    or ax,ax
    jz dh2Fail
;   
    movzx edi,bp
    shl edi,4
    add edi,OFFSET h_arr
    mov ax,ds:[edi].hp_handle
    or ax,ax
    jz dh2Dup
;
    cmp ax,SYS_HANDLE_COUNT
    jae dh2Fail
;    
    or ax,ax
    jz dh2Fail
;
    mov bx,bp
    CloseHandle

dh2Dup:
    mov bx,bp
;
    mov eax,SEG data
    mov es,eax
    movzx eax,ds:[esi].hp_handle
    dec eax
    shl eax,4
    add eax,OFFSET hd_sys_arr
    inc es:[eax].sh_ref_count
;
    mov bp,ds:[esi].hp_vfs_sel
    or bp,bp
    jnz dh2Vfs
;
    mov eax,ds:[esi].hp_pos
    mov edx,ds:[esi].hp_pos+4
    jmp dh2Copy

dh2Vfs:
    push ebx
    mov bx,bp
    mov cx,ds:[esi].hp_vfs_handle
    call GetVfsFilePos
    pop ebx

dh2Copy:
    EnterSection ds:h_section
    mov cx,ds:[esi].hp_access
    mov ds:[edi].hp_access,cx
;
    mov cx,ds:[esi].hp_handle
    mov ds:[edi].hp_handle,cx
    LeaveSection ds:h_section
;
    or bp,bp
    jz dh2Dev
;
    push ebx
    mov bx,bp
    call DupVfsFile   
    pop ebx
;
    mov ds:[edi].hp_vfs_sel,bp
    mov ds:[edi].hp_vfs_handle,dx
    clc
    jmp dh2Done

dh2Dev:
    mov ds:[edi].hp_pos,eax
    mov ds:[edi].hp_pos+4,edx
    clc
    jmp dh2Done

dh2Fail:
    mov ebx,-1
    stc

dh2Done:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds    
    ret
dup2_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleSize
;
;           DESCRIPTION:    Get C handle size
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        (EDX:)EAX   Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_size32_name  DB 'Get C Handle Size 32', 0
get_handle_size64_name  DB 'Get C Handle Size 64', 0

get_size_dummy      Proc near
    stc
    ret
get_size_dummy      Endp

get_size_file       Proc near
    GetLegacyFileSize
    ret
get_size_file       Endp

get_size_vfs       Proc near
    call GetVfsFileSize
    ret
get_size_vfs       Endp

get_size_tab:
gst00  DD OFFSET get_size_dummy
gst01  DD OFFSET get_size_file
gst02  DD OFFSET get_size_dummy
gst03  DD OFFSET get_size_dummy
gst04  DD OFFSET get_size_dummy
gst05  DD OFFSET get_size_dummy
gst06  DD OFFSET get_size_vfs
gst07  DD OFFSET get_size_dummy
gst08  DD OFFSET get_size_dummy
gst09  DD OFFSET get_size_dummy

get_handle_size32     Proc far
    push ds
    push ebx
    push edx
    push ebp
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghsFail32
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghsFail32
;    
    or ax,ax
    jz ghsFail32
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].get_size_tab
    jnc ghsDone32  

ghsFail32:
    xor eax,eax
    stc

ghsDone32:
    pop ebp
    pop edx
    pop ebx
    pop ds    
    ret
get_handle_size32     Endp        

get_handle_size64     Proc far
    push ds
    push ebx
    push ebp
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghsFail64
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghsFail64
;    
    or ax,ax
    jz ghsFail64
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].get_size_tab
    jc ghsFail64
;
    clc
    jmp ghsDone64

ghsFail64:
    xor eax,eax
    xor edx,edx
    stc

ghsDone64:
    pop ebp
    pop ebx
    pop ds    
    ret
get_handle_size64     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleSize
;
;           DESCRIPTION:    Set C handle size
;
;           PARAMETERS:     BX          Handle
;                           (EDX:)EAX   Size
;
;           RETURNS:        (EDX:)EAX   Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_size32_name  DB 'Set C Handle Size 32', 0
set_handle_size64_name  DB 'Set C Handle Size 64', 0

set_size_dummy      Proc near
    stc
    ret
set_size_dummy      Endp

set_size_file       Proc near
    SetLegacyFileSize
    ret
set_size_file       Endp

set_size_vfs       Proc near
    call SetVfsFileSize
    ret
set_size_vfs       Endp

set_size_tab:
sst00  DD OFFSET set_size_dummy
sst01  DD OFFSET set_size_file
sst02  DD OFFSET set_size_dummy
sst03  DD OFFSET set_size_dummy
sst04  DD OFFSET set_size_dummy
sst05  DD OFFSET set_size_dummy
sst06  DD OFFSET set_size_vfs
sst07  DD OFFSET set_size_dummy
sst08  DD OFFSET set_size_dummy
sst09  DD OFFSET set_size_dummy

set_handle_size32     Proc far
    push ds
    push ebx
    push edx
    push esi
    push ebp
;
    push eax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae shsFail32
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae shsFail32
;    
    or ax,ax
    jz shsFail32
;
    mov si,ds:[ebx].hp_vfs_sel
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    pop eax
    xor edx,edx
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].set_size_tab
    jnc shsDone32
;
    mov eax,-1
    stc
    jmp shsDone32

shsFail32:
    pop eax
    mov eax,-1
    stc

shsDone32:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop ds    
    ret
set_handle_size32     Endp        

set_handle_size64     Proc far
    push ds
    push ebx
    push esi
    push ebp
;
    push eax
    push edx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae shsFail64
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae shsFail64
;    
    or ax,ax
    jz shsFail64
;
    mov si,ds:[ebx].hp_vfs_sel
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    pop edx
    pop eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].set_size_tab
    jnc shsDone64
;
    mov eax,-1
    mov edx,-1
    stc
    jmp shsDone64

shsFail64:
    pop edx
    pop eax
    mov eax,-1
    mov edx,-1
    stc

shsDone64:
    pop ebp
    pop esi
    pop ebx
    pop ds    
    ret
set_handle_size64     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleCreateTime
;                           GetHandleModifyTime
;                           GetHandleAccessTime
;
;           DESCRIPTION:    Get C handle time
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDX:EAX     Time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_time_dummy      Proc near
    stc
    ret
get_time_dummy      Endp

get_time_file       Proc near
    GetLegacyFileTime
    ret
get_time_file       Endp

get_handle_create_time_name  DB 'Get C Handle Create Time', 0

get_create_time_tab:
gctt00  DD OFFSET get_time_dummy
gctt01  DD OFFSET get_time_file
gctt02  DD OFFSET get_time_dummy
gctt03  DD OFFSET get_time_dummy
gctt04  DD OFFSET get_time_dummy
gctt05  DD OFFSET get_time_dummy
gctt06  DD OFFSET get_time_dummy
gctt07  DD OFFSET get_time_dummy
gctt08  DD OFFSET get_time_dummy
gctt09  DD OFFSET get_time_dummy

get_handle_create_time     Proc far
    push ds
    push ebx
    push ebp
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghctFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghctFail
;    
    or ax,ax
    jz ghctFail
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].get_create_time_tab
    jnc ghctDone

ghctFail:
    mov eax,-1
    mov edx,-1

ghctDone:
    pop ebp
    pop ebx
    pop ds    
    ret
get_handle_create_time     Endp        

get_handle_modify_time_name  DB 'Get C Handle Modify Time', 0

get_modify_time_tab:
gmtt00  DD OFFSET get_time_dummy
gmtt01  DD OFFSET get_time_file
gmtt02  DD OFFSET get_time_dummy
gmtt03  DD OFFSET get_time_dummy
gmtt04  DD OFFSET get_time_dummy
gmtt05  DD OFFSET get_time_dummy
gmtt06  DD OFFSET get_time_dummy
gmtt07  DD OFFSET get_time_dummy
gmtt08  DD OFFSET get_time_dummy
gmtt09  DD OFFSET get_time_dummy

get_handle_modify_time     Proc far
    push ds
    push ebx
    push ebp
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghmtFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghmtFail
;    
    or ax,ax
    jz ghmtFail
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].get_modify_time_tab
    jnc ghmtDone

ghmtFail:
    mov eax,-1
    mov edx,-1

ghmtDone:
    pop ebp
    pop ebx
    pop ds    
    ret
get_handle_modify_time     Endp        

get_handle_access_time_name  DB 'Get C Handle Access Time', 0

get_access_time_tab:
gatt00  DD OFFSET get_time_dummy
gatt01  DD OFFSET get_time_file
gatt02  DD OFFSET get_time_dummy
gatt03  DD OFFSET get_time_dummy
gatt04  DD OFFSET get_time_dummy
gatt05  DD OFFSET get_time_dummy
gatt06  DD OFFSET get_time_dummy
gatt07  DD OFFSET get_time_dummy
gatt08  DD OFFSET get_time_dummy
gatt09  DD OFFSET get_time_dummy

get_handle_access_time     Proc far
    push ds
    push ebx
    push ebp
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghatFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghatFail
;    
    or ax,ax
    jz ghatFail
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].get_access_time_tab
    jnc ghatDone

ghatFail:
    mov eax,-1
    mov edx,-1

ghatDone:
    pop ebp
    pop ebx
    pop ds    
    ret
get_handle_access_time     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleModifyTime
;
;           DESCRIPTION:    Set C handle modify time
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     Time
;
;           RETURNS:        EAX         Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_modify_time_name  DB 'Set C Handle Modify Time', 0

set_time_dummy      Proc near
    stc
    ret
set_time_dummy      Endp

set_time_file       Proc near
    SetLegacyFileTime
    ret
set_time_file       Endp

set_time_tab:
stt00  DD OFFSET set_time_dummy
stt01  DD OFFSET set_time_file
stt02  DD OFFSET set_time_dummy
stt03  DD OFFSET set_time_dummy
stt04  DD OFFSET set_time_dummy
stt05  DD OFFSET set_time_dummy
stt06  DD OFFSET set_time_dummy
stt07  DD OFFSET set_time_dummy
stt08  DD OFFSET set_time_dummy
stt09  DD OFFSET set_time_dummy

set_handle_time     Proc far
    push ds
    push ebx
    push ebp
;
    push eax
    push edx
;
    mov esi,eax
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae shtFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae shtFail
;    
    or ax,ax
    jz shtFail
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    pop edx
    pop eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].set_time_tab
    mov eax,0
    jnc shtDone
    mov eax,-1
    jmp shtDone

shtFail:
    pop edx
    pop eax
    mov eax,-1

shtDone:
    pop ebp
    pop ebx
    pop ds    
    ret
set_handle_time     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleMode
;
;           DESCRIPTION:    Get C handle mode
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_mode_name  DB 'Get C Handle Mode', 0

get_handle_mode     Proc far
    push ds
    push ebx
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghmFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    movzx eax,ds:[ebx].hp_access
    jmp ghmDone

ghmFail:
    mov eax,-1

ghmDone:
    pop ebx
    pop ds    
    ret
get_handle_mode     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleMode
;
;           DESCRIPTION:    Set C handle mode
;
;           PARAMETERS:     BX          Handle
;                           EAX         Mode
;
;           RETURNS:        EAX         Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_mode_name  DB 'Set C Handle Mode', 0

set_handle_mode     Proc far
    push ds
    push ebx
    push edx
;
    mov edx,eax
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae shmFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ds:[ebx].hp_access,dx
    xor eax,eax
    jmp shmDone

shmFail:
    mov eax,-1

shmDone:
    pop edx
    pop ebx
    pop ds    
    ret
set_handle_mode     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandlePos
;
;           DESCRIPTION:    Get C handle pos
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        (EDX:)EAX   Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_pos32_name  DB 'Get C Handle Pos 32', 0
get_handle_pos64_name  DB 'Get C Handle Pos 64', 0

get_handle_pos32     Proc far
    push ds
    push ebx
    push ecx
    push edx
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghpFail32
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_vfs_sel
    or ax,ax
    jnz ghpVfs32
;
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghpFail32
;    
    or ax,ax
    jz ghpFail32
;
    mov eax,ds:[ebx].hp_pos
    jmp ghpDone32

ghpVfs32:
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call GetVfsFilePos
    jmp ghpDone32

ghpFail32:
    xor eax,eax
    stc

ghpDone32:
    pop edx
    pop ecx
    pop ebx
    pop ds    
    ret
get_handle_pos32     Endp        

get_handle_pos64     Proc far
    push ds
    push ebx
    push ecx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ghpFail64
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_vfs_sel
    or ax,ax
    jnz ghpVfs64
;
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ghpFail64
;    
    or ax,ax
    jz ghpFail64
;
    mov eax,ds:[ebx].hp_pos
    mov edx,ds:[ebx].hp_pos+4
    jmp ghpDone64

ghpVfs64:
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call GetVfsFilePos
    jmp ghpDone64

ghpFail64:
    xor eax,eax
    xor edx,edx
    stc

ghpDone64:
    pop ecx
    pop ebx
    pop ds    
    ret
get_handle_pos64     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandlePos
;
;           DESCRIPTION:    Set C handle pos
;
;           PARAMETERS:     BX          Handle
;                           (EDX:)EAX   Position
;
;           RETURNS:        (EDX:)EAX   Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_pos32_name  DB 'Set C Handle Pos 32', 0
set_handle_pos64_name  DB 'Set C Handle Pos 64', 0

set_handle_pos32     Proc far
    push ds
    push ebx
    push ecx
    push edx
;
    xor edx,edx
    push eax
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    pop eax
;    
    cmp bx,MAX_HANDLES
    jae shpFail32
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov cx,ds:[ebx].hp_handle
;
    cmp cx,SYS_HANDLE_COUNT
    jae shpFail32
;    
    or cx,cx
    jz shpFail32
;
    mov cx,ds:[ebx].hp_vfs_sel
    or cx,cx
    jnz shpVfs32
;
    mov ds:[ebx].hp_pos,eax
    mov ds:[ebx].hp_pos+4,edx
    jmp shpDone32

shpVfs32:
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call SetVfsFilePos
    jmp shpDone32

shpFail32:
    mov eax,-1

shpDone32:
    pop edx
    pop ecx
    pop ebx
    pop ds    
    ret
set_handle_pos32     Endp        

set_handle_pos64     Proc far
    push ds
    push ebx
    push ecx
;
    push eax
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    pop eax
;    
    cmp bx,MAX_HANDLES
    jae shpFail64
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov cx,ds:[ebx].hp_handle
;
    cmp cx,SYS_HANDLE_COUNT
    jae shpFail64
;    
    or cx,cx
    jz shpFail64
;
    mov cx,ds:[ebx].hp_vfs_sel
    or cx,cx
    jnz shpVfs64
;
    mov ds:[ebx].hp_pos,eax
    mov ds:[ebx].hp_pos+4,edx
    jmp shpDone64

shpVfs64:
    mov cx,ds:[ebx].hp_vfs_handle
    mov bx,ds:[ebx].hp_vfs_sel
    call SetVfsFilePos
    jmp shpDone64

shpFail64:
    mov eax,-1
    mov edx,-1

shpDone64:
    pop ecx
    pop ebx
    pop ds    
    ret
set_handle_pos64     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EofHandle
;
;           DESCRIPTION:    Eof for C handle
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Eof status (-1 = error, 0 = not eof, 1 = eof)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eof_handle_name  DB 'Eof C Handle', 0

eof_dummy      Proc near
    mov eax,-1
    ret
eof_dummy      Endp

eof_stdin      Proc near
    PollKeyboard
    jc eof_stdin_ok
;
    xor eax,eax
    ret

eof_stdin_ok:
    mov eax,1
    ret
eof_stdin      Endp

eof_stdout      Proc near
    mov eax,1
    ret
eof_stdout      Endp

eof_file       Proc near
    GetLegacyFileSize
    cmp eax,edx
    je eof_file_ok
;
    xor eax,eax
    ret

eof_file_ok:
    mov eax,1
    ret
eof_file       Endp

eof_tab:
et00  DD OFFSET eof_dummy
et01  DD OFFSET eof_file
et02  DD OFFSET eof_stdin
et03  DD OFFSET eof_stdout
et04  DD OFFSET eof_dummy
et05  DD OFFSET eof_dummy
et06  DD OFFSET eof_dummy
et07  DD OFFSET eof_dummy
et08  DD OFFSET eof_dummy
et09  DD OFFSET eof_dummy

eof_handle     Proc far
    push ds
    push ebx
    push edx
    push ebp
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ehFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
    mov edx,ds:[ebx].hp_pos
;
    cmp ax,SYS_HANDLE_COUNT
    jae ehFail
;    
    or ax,ax
    jz ehFail
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].eof_tab
    jmp ehDone

ehFail:
    mov eax,-1

ehDone:
    pop ebp
    pop edx
    pop ebx
    pop ds    
    ret
eof_handle     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsHandleDevice
;
;           DESCRIPTION:    Check if C handle is device
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        NC          Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_handle_device_name  DB 'Is C Handle Device', 0

not_device      Proc near
    stc
    ret
not_device      Endp

is_device      Proc near
    clc
    ret
is_device      Endp

dev_tab:
idt00  DD OFFSET not_device
idt01  DD OFFSET not_device
idt02  DD OFFSET is_device
idt03  DD OFFSET is_device
idt04  DD OFFSET not_device
idt05  DD OFFSET not_device
idt06  DD OFFSET not_device
idt07  DD OFFSET not_device
idt08  DD OFFSET not_device
idt09  DD OFFSET not_device

is_handle_device     Proc far
    push ds
    push ebx
    push ebp
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ihdFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ihdFail
;    
    or ax,ax
    jz ihdFail
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].dev_tab
    jmp ihdDone

ihdFail:
    stc

ihdDone:
    pop ebp
    pop ebx
    pop ds    
    ret
is_handle_device     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsIpv4Socket
;
;           DESCRIPTION:    Check for IPv4 socket
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        NC          IPv4 socket
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_ipv4_socket_name  DB 'Is IPv4 Socket', 0

is_ipv4_socket	Proc far
    push ds
    push eax
    push ebx
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae iisFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae iisFail
;    
    or ax,ax
    jz iisFail
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
;
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:[ebx].sh_type
    cmp ax,C_HANDLE_TCP_SOCKET
    je iisOk
;
    cmp ax,C_HANDLE_UDP_SOCKET
    jne iisFail

iisOk:
    clc
    jmp iisDone

iisFail:
    stc

iisDone:
    pop ebx
    pop eax
    pop ds
    ret
is_ipv4_socket	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ConnectIpv4Socket
;
;           DESCRIPTION:    Connect IPv4 socket
;
;           PARAMETERS:    IN  BX                socket handle
;                          IN  EDX               IP
;                          IN  SI                port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

connect_ipv4_socket_name  DB 'Connect IPv4 Socket', 0

connect_ipv4_socket	Proc far
    push ds
    push eax
    push ebx
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae cisFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae cisFail
;    
    or ax,ax
    jz cisFail
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
;
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:[ebx].sh_type
    cmp ax,C_HANDLE_TCP_SOCKET
    je cisTcp
;
    cmp ax,C_HANDLE_UDP_SOCKET
    jne cisFail

cisUpd:
    ConnectUdpSocket
    mov ds:[ebx].sh_sel,ax
    jmp cisDone

cisTcp:
    ConnectTcpSocket
    mov ds:[ebx].sh_sel,ax
    jmp cisDone

cisFail:
    stc

cisDone:
    pop ebx
    pop eax
    pop ds
    ret
connect_ipv4_socket	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          GetHandleReadBufCount
;
;           DESCRIPTION:   Get number of bytes available input buffer
;
;           PARAMETERS:    IN  BX                Handle
;
;           RETURNS:       NC 
;                              OUT ECX           Bytes in input buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_read_buf_count_name  DB 'Get Handle Read Buffer Count', 0

read_buf_dummy      Proc near
    stc
    ret
read_buf_dummy      Endp

read_buf_stdin       Proc near
    PollKeyboard
    jnc rbstdin1
;
    xor ecx,ecx
    clc
    ret

rbstdin1:
    mov ecx,1
    clc
    ret
read_buf_stdin       Endp

read_buf_file       Proc near
    mov ecx,eax
    GetLegacyFileSize
    sub ecx,eax
    neg ecx
    clc
    ret
read_buf_file       Endp

read_buf_tcp_socket       Proc near
    GetTcpSocketReadCount
    ret
read_buf_tcp_socket       Endp

read_buf_udp_socket       Proc near
    GetUdpSocketReadCount
    ret
read_buf_udp_socket       Endp

read_buf_tab:
rbt00  DD OFFSET read_buf_dummy
rbt01  DD OFFSET read_buf_file
rbt02  DD OFFSET read_buf_stdin
rbt03  DD OFFSET read_buf_dummy
rbt04  DD OFFSET read_buf_tcp_socket
rbt05  DD OFFSET read_buf_udp_socket
rbt06  DD OFFSET read_buf_dummy
rbt07  DD OFFSET read_buf_dummy
rbt08  DD OFFSET read_buf_dummy
rbt09  DD OFFSET read_buf_dummy

GetReadBufCount	Proc near
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    cmp bx,MAX_HANDLES
    jae grbcFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov eax,ds:[ebx].hp_pos
    mov edx,ds:[ebx].hp_pos+4
    mov bp,ds:[ebx].hp_handle
;
    cmp bp,SYS_HANDLE_COUNT
    jae grbcFail
;    
    or bp,bp
    jz grbcFail
;
    push ds
    push ebx
;
    mov ebx,SEG data
    mov ds,ebx
;
    movzx ebx,bp
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].read_buf_tab
;
    pop ebx
    pop ds
    jc grbcFail
;
    jmp grbcDone

grbcFail:
    xor ecx,ecx
    stc

grbcDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    ret
GetReadBufCount	Endp

get_handle_read_buf_count	Proc far
    push ds
    push eax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    call GetReadBufCount
;
    pop eax
    pop ds
    ret
get_handle_read_buf_count	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          GetHandleWriteBufSpace
;
;           DESCRIPTION:   Get number of bytes available output buffer
;
;           PARAMETERS:    IN  BX                Handle
;
;           RETURNS:       NC
;                              OUT ECX           Space in output buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_write_buf_space_name  DB 'Get Handle Write Buffer Space', 0

write_buf_dummy      Proc near
    stc
    ret
write_buf_dummy      Endp

write_buf_stdout       Proc near
    mov ecx,1
    clc
    ret
write_buf_stdout       Endp

write_buf_file       Proc near
    GetLegacyFileSize
    mov ecx,7FFFFFFFh
    sub ecx,eax
    clc
    ret
write_buf_file       Endp

write_buf_tcp_socket       Proc near
    GetTcpSocketWriteSpace
    ret
write_buf_tcp_socket       Endp

write_buf_udp_socket       Proc near
    mov ecx,512
    clc
    ret
write_buf_udp_socket       Endp

write_buf_tab:
wbt00  DD OFFSET write_buf_dummy
wbt01  DD OFFSET write_buf_file
wbt02  DD OFFSET write_buf_dummy
wbt03  DD OFFSET write_buf_stdout
wbt04  DD OFFSET write_buf_tcp_socket
wbt05  DD OFFSET write_buf_udp_socket
wbt06  DD OFFSET write_buf_dummy
wbt07  DD OFFSET write_buf_dummy
wbt08  DD OFFSET write_buf_dummy
wbt09  DD OFFSET write_buf_dummy

GetWriteBufSpace	Proc near
    push eax
    push ebx
    push edx
    push esi
    push ebp
;    
    cmp bx,MAX_HANDLES
    jae gwbsFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae gwbsFail
;    
    or ax,ax
    jz gwbsFail
;
    push ds
    push ebx
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].write_buf_tab
;
    pop ebx
    pop ds
    jc gwbsFail
;
    jmp gwbsDone

gwbsFail:
    xor ecx,ecx
    stc

gwbsDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    ret
GetWriteBufSpace	Endp

get_handle_write_buf_space	Proc far
    push ds
    push eax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    call GetWriteBufSpace
;    
    pop eax
    pop ds    
    ret
get_handle_write_buf_space	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          HasHandleException
;
;           DESCRIPTION:   Has handle exception
;
;           PARAMETERS:    IN  BX                Handle
;                          OUT CY		 Has exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_handle_exception_name  DB 'Has Handle Exception', 0

exc_dummy      Proc near
    clc
    ret
exc_dummy      Endp

exc_stdin       Proc near
    clc
    ret
exc_stdin       Endp

exc_tcp_socket       Proc near
    HasTcpSocketException
    ret
exc_tcp_socket       Endp

exc_tab:
eht00  DD OFFSET exc_dummy
eht01  DD OFFSET exc_dummy
eht02  DD OFFSET exc_stdin
eht03  DD OFFSET exc_dummy
eht04  DD OFFSET exc_tcp_socket
eht05  DD OFFSET exc_dummy
eht06  DD OFFSET exc_dummy
eht07  DD OFFSET exc_dummy
eht08  DD OFFSET exc_dummy
eht09  DD OFFSET exc_dummy

HasException	Proc near
    push eax
    push ebx
    push ebp
;
    cmp bx,MAX_HANDLES
    jae heFail
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae heFail
;    
    or ax,ax
    jz heFail
;
    push ds
    push ebx
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].exc_tab
;
    pop ebx
    pop ds
    jmp heDone

heFail:
    clc

heDone:
    pop ebp
    pop ebx
    pop eax
    ret
HasException	Endp

has_handle_exception	Proc far
    push ds
    push eax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    call HasException
;
    pop eax
    pop ds    
    ret
has_handle_exception	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SignalReadHandle
;
;           DESCRIPTION:    Signal read handle
;
;           PARAMETERS:     BX	Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_read_handle_name	DB 'Signal Read Handle', 0

signal_read_handle	Proc far
    push ds
    push es
    push eax
    push edx
;
    mov eax,SEG data
    mov ds,eax
    movzx ebx,bx
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
;
    EnterSection ds:hd_section
    xor ax,ax
    xchg ax,ds:[ebx].sh_read_wait_sel
    or ax,ax
    jz srhLeave
;
    push ds
    push ecx
    push esi
;
    mov ds,eax
    movzx ecx,ds:hw_count
    mov esi,OFFSET hw_arr
    
srhLoop:
    lodsw
    mov es,ax
    SignalWait
    loop srhLoop
;
    mov ax,ds
    pop esi
    pop ecx
    pop ds
;
    mov es,ax
    FreeMem

srhLeave:
    LeaveSection ds:hd_section
;
    pop edx
    pop eax
    pop es
    pop ds
    ret
signal_read_handle      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForRead
;
;           DESCRIPTION:    Start a wait for read data
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_read_dummy      Proc near
    SignalReadHandle
    ret
start_read_dummy      Endp

start_read_stdin       Proc near
    StartReadStdin
    ret
start_read_stdin       Endp

start_read_file       Proc near
    StartReadLegacyFile
    ret
start_read_file       Endp

start_read_tcp_socket       Proc near
    StartReadTcpSocket
    ret
start_read_tcp_socket       Endp

start_read_udp_socket       Proc near
    StartReadUdpSocket
    ret
start_read_udp_socket       Endp

start_wait_read_tab:
swrt00  DD OFFSET start_read_dummy
swrt01  DD OFFSET start_read_file
swrt02  DD OFFSET start_read_stdin
swrt03  DD OFFSET start_read_dummy
swrt04  DD OFFSET start_read_tcp_socket
swrt05  DD OFFSET start_read_udp_socket
swrt06  DD OFFSET start_read_dummy
swrt07  DD OFFSET start_read_dummy
swrt08  DD OFFSET start_read_dummy
swrt09  DD OFFSET start_read_dummy

start_wait_for_read       PROC far
    push ds
    pushad
;
    mov bx,es:sw_handle
    GetHandleReadBufferCount
    jc swfrSignal
;
    or ecx,ecx
    jz swfrCheck

swfrSignal:
    SignalWait
    jmp swfrDone

swfrCheck:
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae swfrDone
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae swfrDone
;    
    or ax,ax
    jz swfrDone
;
    push ds
    push es
    push ebx
    push edi
;
    movzx edi,ax
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    EnterSection ds:hd_section
;
    mov bp,es
    mov ax,ds:[bx].sh_read_wait_sel
    or ax,ax
    jnz swfrAdd
;
    mov eax,SIZE handle_wait_struc
    AllocateSmallGlobalMem
    mov es:hw_handle,di
    mov es:hw_count,1
    mov es:hw_arr,bp
    mov ds:[bx].sh_read_wait_sel,es
    LeaveSection ds:hd_section
;
    mov ax,di
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].start_wait_read_tab
    jmp swfrLinked

swfrAdd:
    mov es,ax
    mov di,es:hw_count
    cmp di,HANDLE_WAIT_OBJ_COUNT
    je swfrLeave
;
    shl edi,1
    mov es:[edi].hw_arr,bp
    inc es:hw_count

swfrLeave:
    LeaveSection ds:hd_section

swfrLinked:
    pop edi
    pop ebx
    pop es
    pop ds

swfrDone:
    popad
    pop ds    
    ret
start_wait_for_read Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForRead
;
;           DESCRIPTION:    Stop a wait for socket read
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_read_dummy      Proc near
    ret
stop_read_dummy      Endp

stop_read_stdin       Proc near
    StopReadStdin
    ret
stop_read_stdin       Endp

stop_read_file       Proc near
    StopReadLegacyFile
    ret
stop_read_file       Endp

stop_read_tcp_socket       Proc near
    StopReadTcpSocket
    ret
stop_read_tcp_socket       Endp

stop_read_udp_socket       Proc near
    StartReadUdpSocket
    ret
stop_read_udp_socket       Endp

stop_wait_read_tab:
ewrt00  DD OFFSET stop_read_dummy
ewrt01  DD OFFSET stop_read_file
ewrt02  DD OFFSET stop_read_stdin
ewrt03  DD OFFSET stop_read_dummy
ewrt04  DD OFFSET stop_read_tcp_socket
ewrt05  DD OFFSET stop_read_udp_socket
ewrt06  DD OFFSET stop_read_dummy
ewrt07  DD OFFSET stop_read_dummy
ewrt08  DD OFFSET stop_read_dummy
ewrt09  DD OFFSET stop_read_dummy

stop_wait_for_read    PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ewfrDone
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov edx,ds:[ebx].hp_pos
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ewfrDone
;    
    or ax,ax
    jz ewfrDone
;
    push ds
    push ebx
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    EnterSection ds:hd_section
    mov ax,ds:[ebx].sh_read_wait_sel
    or ax,ax
    jz ewfrLeave
;
    push ds
    push ecx
    push edx
    push esi
;
    mov ds,ax
    movzx ecx,ds:hw_count
    mov esi,OFFSET hw_arr
    mov dx,es

ewfrFindLoop:
    lodsw
    cmp ax,dx
    je ewfrFound
;
    loop ewfrFindLoop
    jmp ewfrRemoved

ewfrFound:
    sub ecx,1
    jz ewfrRemove

ewfrMoveLoop:
    mov ax,ds:[esi]
    mov ds:[esi-2],ax
    add esi,2
    loop ewfrMoveLoop

ewfrRemove:
    sub ds:hw_count,1
    jnz ewfrRemoved
;
    push es
    mov eax,ds
    mov es,eax
    xor eax,eax
    mov ds,eax
    FreeMem
    pop es
;
    pop esi
    pop edx
    pop ecx
    pop ds
    mov ds:[ebx].sh_read_wait_sel,0
    LeaveSection ds:hd_section
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].stop_wait_read_tab
    jmp ewfrPop

ewfrRemoved:
    pop esi
    pop edx
    pop ecx
    pop ds

ewfrLeave:
    LeaveSection ds:hd_section

ewfrPop:
    pop ebx
    pop ds

ewfrDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    ret
stop_wait_for_read Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearRead
;
;           DESCRIPTION:    Clear read
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_read    PROC far
    ret
clear_read Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasReadData
;
;           DESCRIPTION:    Check if read data is available
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_read_data      PROC far
    push bx
    push ecx
;
    mov bx,es:sw_handle
    GetHandleReadBufferCount
    cmc
    jnc hrdDone
;
    or ecx,ecx
    stc
    jz hrdDone
;
    clc

hrdDone:
    pop ecx
    pop bx
    ret
has_read_data Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          AddWaitForHandleRead
;
;           DESCRIPTION:   Add wait for handle read
;
;           PARAMETERS:    IN  AX                Handle
;                          IN  BX                Wait handle
;                          IN  ECX               Object ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_handle_read_name  DB 'Add Wait For Handle Read', 0

add_wait_read_tab:
awr0 DD OFFSET start_wait_for_read,    SEG code
awr1 DD OFFSET stop_wait_for_read,     SEG code
awr2 DD OFFSET clear_read,             SEG code
awr3 DD OFFSET has_read_data,          SEG code

add_wait_for_handle_read	Proc far
    push ds
    push es
    push eax
    push edi
;
    push eax
    mov eax,cs
    mov es,eax
    mov ax,SIZE socket_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_read_tab
    AddWait
    pop eax
    jc awrDone
;
    mov es:sw_handle,ax

awrDone:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_handle_read	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SignalWriteHandle
;
;           DESCRIPTION:    Signal write handle
;
;           PARAMETERS:     BX	Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_write_handle_name	DB 'Signal Write Handle', 0

signal_write_handle	Proc far
    push ds
    push eax
    push edx
;
    mov ax,SEG data
    mov ds,eax
    movzx ebx,bx
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
;
    EnterSection ds:hd_section
    xor ax,ax
    xchg ax,ds:[ebx].sh_write_wait_sel
    or ax,ax
    jz swhLeave
;
    push ds
    push ecx
    push esi
;
    mov ds,ax
    movzx ecx,ds:hw_count
    mov esi,OFFSET hw_arr
    
swhLoop:
    lodsw
    mov es,ax
    SignalWait
    loop swhLoop
;
    mov eax,ds
    pop esi
    pop ecx
    pop ds
;
    mov es,eax
    FreeMem

swhLeave:
    LeaveSection ds:hd_section
;
    pop edx
    pop eax
    pop ds
    ret
signal_write_handle      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForWrite
;
;           DESCRIPTION:    Start a wait for write data
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_write_dummy      Proc near
    ret
start_write_dummy      Endp

start_write_tcp_socket       Proc near
    StartWriteTcpSocket
    ret
start_write_tcp_socket       Endp

start_wait_write_tab:
swwt00  DD OFFSET start_write_dummy
swwt01  DD OFFSET start_write_dummy
swwt02  DD OFFSET start_write_dummy
swwt03  DD OFFSET start_write_dummy
swwt04  DD OFFSET start_write_tcp_socket
swwt05  DD OFFSET start_write_dummy
swwt06  DD OFFSET start_write_dummy
swwt07  DD OFFSET start_write_dummy
swwt08  DD OFFSET start_write_dummy
swwt09  DD OFFSET start_write_dummy

start_wait_for_write       PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae swfwDone
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov edx,ds:[ebx].hp_pos
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae swfwDone
;    
    or ax,ax
    jz swfwDone
;
    push ds
    push es
    push ebx
    push edi
;
    movzx edi,ax
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    EnterSection ds:hd_section
;
    mov bp,es
    mov ax,ds:[ebx].sh_write_wait_sel
    or ax,ax
    jnz swfwAdd
;
    mov eax,SIZE handle_wait_struc
    AllocateSmallGlobalMem
    mov es:hw_handle,di
    mov es:hw_count,1
    mov es:hw_arr,bp
    mov ds:[ebx].sh_write_wait_sel,es
    LeaveSection ds:hd_section
;
    mov ax,di
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].start_wait_write_tab
    jmp swfwLinked

swfwAdd:
    mov es,ax
    mov di,es:hw_count
    cmp di,HANDLE_WAIT_OBJ_COUNT
    je swfwLeave
;
    shl edi,1
    mov es:[edi].hw_arr,bp
    inc es:hw_count

swfwLeave:
    LeaveSection ds:hd_section

swfwLinked:
    pop edi
    pop ebx
    pop es
    pop ds

swfwDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    ret
start_wait_for_write Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForWrite
;
;           DESCRIPTION:    Stop a wait for socket write
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_write_dummy      Proc near
    ret
stop_write_dummy      Endp

stop_write_tcp_socket       Proc near
    StopWriteTcpSocket
    ret
stop_write_tcp_socket       Endp

stop_wait_write_tab:
ewwt00  DD OFFSET stop_write_dummy
ewwt01  DD OFFSET stop_write_dummy
ewwt02  DD OFFSET stop_write_dummy
ewwt03  DD OFFSET stop_write_dummy
ewwt04  DD OFFSET stop_write_tcp_socket
ewwt05  DD OFFSET stop_write_dummy
ewwt06  DD OFFSET stop_write_dummy
ewwt07  DD OFFSET stop_write_dummy
ewwt08  DD OFFSET stop_write_dummy
ewwt09  DD OFFSET stop_write_dummy

stop_wait_for_write    PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ewfwDone
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov edx,ds:[ebx].hp_pos
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ewfwDone
;    
    or ax,ax
    jz ewfwDone
;
    push ds
    push ebx
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    EnterSection ds:hd_section
    mov ax,ds:[ebx].sh_write_wait_sel
    or ax,ax
    jz ewfwLeave
;
    push ds
    push ecx
    push edx
    push esi
;
    mov ds,eax
    movzx ecx,ds:hw_count
    mov esi,OFFSET hw_arr
    mov dx,es

ewfwFindLoop:
    lodsw
    cmp ax,dx
    je ewfwFound
;
    loop ewfwFindLoop
    jmp ewfwRemoved

ewfwFound:
    sub ecx,1
    jz ewfwRemove

ewfwMoveLoop:
    mov ax,ds:[esi]
    mov ds:[esi-2],ax
    add esi,2
    loop ewfwMoveLoop

ewfwRemove:
    sub ds:hw_count,1
    jnz ewfwRemoved
;
    push es
    mov eax,ds
    mov es,eax
    xor eax,eax
    mov ds,eax
    FreeMem
    pop es
;
    pop esi
    pop edx
    pop ecx
    pop ds
    mov ds:[ebx].sh_write_wait_sel,0
    LeaveSection ds:hd_section
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].stop_wait_write_tab
    jmp ewfwPop

ewfwRemoved:
    pop esi
    pop edx
    pop ecx
    pop ds

ewfwLeave:
    LeaveSection ds:hd_section

ewfwPop:
    pop ebx
    pop ds

ewfwDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    ret
stop_wait_for_write Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearWrite
;
;           DESCRIPTION:    Clear write
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_write    PROC far
    ret
clear_write Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasWriteData
;
;           DESCRIPTION:    Check if write data is possible
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_write_data      PROC far
    push ebx
    push ecx
;
    mov bx,es:sw_handle
    GetHandleWriteBufferSpace
    cmc
    jnc hwdDone
;
    or ecx,ecx
    stc
    jz hwdDone
;
    clc

hwdDone:
    pop ecx
    pop ebx
    ret
has_write_data Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          AddWaitForHandleWrite
;
;           DESCRIPTION:   Add wait for handle write
;
;           PARAMETERS:    IN  AX                Handle
;                          IN  BX                Wait handle
;                          IN  ECX               Object ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_handle_write_name  DB 'Add Wait For Handle Write', 0

add_wait_write_tab:
aww0 DD OFFSET start_wait_for_write,    SEG code
aww1 DD OFFSET stop_wait_for_write,     SEG code
aww2 DD OFFSET clear_write,             SEG code
aww3 DD OFFSET has_write_data,          SEG code

add_wait_for_handle_write	Proc far
    push ds
    push es
    push eax
    push edi
;
    push eax
    mov eax,cs
    mov es,eax
    mov ax,SIZE socket_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_write_tab
    AddWait
    pop eax
    jc awwDone
;
    mov es:sw_handle,ax

awwDone:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_handle_write	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SignalExceptionHandle
;
;           DESCRIPTION:    Signal exception handle
;
;           PARAMETERS:     BX	Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_exc_handle_name	DB 'Signal Exception Handle', 0

signal_exc_handle	Proc far
    push ds
    push eax
    push edx
;
    mov eax,SEG data
    mov ds,eax
    movzx ebx,bx
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
;
    EnterSection ds:hd_section
    xor ax,ax
    xchg ax,ds:[ebx].sh_exc_wait_sel
    or ax,ax
    jz sehLeave
;
    push ds
    push ecx
    push esi
;
    mov ds,eax
    movzx ecx,ds:hw_count
    mov esi,OFFSET hw_arr
    
sehLoop:
    lodsw
    mov es,eax
    SignalWait
    loop sehLoop
;
    mov eax,ds
    pop esi
    pop ecx
    pop ds
;
    mov es,eax
    FreeMem

sehLeave:
    LeaveSection ds:hd_section
;
    pop edx
    pop eax
    pop ds
    ret
signal_exc_handle      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForExc
;
;           DESCRIPTION:    Start a wait for exception
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_exc_dummy      Proc near
    ret
start_exc_dummy      Endp

start_exc_tcp_socket       Proc near
    StartExceptionTcpSocket
    ret
start_exc_tcp_socket       Endp

start_wait_exc_tab:
swet00  DD OFFSET start_exc_dummy
swet01  DD OFFSET start_exc_dummy
swet02  DD OFFSET start_exc_dummy
swet03  DD OFFSET start_exc_dummy
swet04  DD OFFSET start_exc_tcp_socket
swet05  DD OFFSET start_exc_dummy
swet06  DD OFFSET start_exc_dummy
swet07  DD OFFSET start_exc_dummy
swet08  DD OFFSET start_exc_dummy
swet09  DD OFFSET start_exc_dummy

start_wait_for_exc       PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae swfeDone
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov edx,ds:[ebx].hp_pos
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae swfeDone
;    
    or ax,ax
    jz swfeDone
;
    push ds
    push es
    push ebx
    push edi
;
    movzx edi,ax
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    EnterSection ds:hd_section
;
    mov bp,es
    mov ax,ds:[ebx].sh_exc_wait_sel
    or ax,ax
    jnz swfeAdd
;
    mov eax,SIZE handle_wait_struc
    AllocateSmallGlobalMem
    mov es:hw_handle,di
    mov es:hw_count,1
    mov es:hw_arr,bp
    mov ds:[ebx].sh_exc_wait_sel,es
    LeaveSection ds:hd_section
;
    mov ax,di
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].start_wait_exc_tab
    jmp swfeLinked

swfeAdd:
    mov es,eax
    movzx edi,es:hw_count
    cmp di,HANDLE_WAIT_OBJ_COUNT
    je swfeLeave
;
    shl edi,1
    mov es:[edi].hw_arr,bp
    inc es:hw_count

swfeLeave:
    LeaveSection ds:hd_section

swfeLinked:
    pop edi
    pop ebx
    pop es
    pop ds

swfeDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    ret
start_wait_for_exc Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForExc
;
;           DESCRIPTION:    Stop a wait for socket exception
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_exc_dummy      Proc near
    ret
stop_exc_dummy      Endp

stop_exc_tcp_socket       Proc near
    StopExceptionTcpSocket
    ret
stop_exc_tcp_socket       Endp

stop_wait_exc_tab:
ewet00  DD OFFSET stop_exc_dummy
ewet01  DD OFFSET stop_exc_dummy
ewet02  DD OFFSET stop_exc_dummy
ewet03  DD OFFSET stop_exc_dummy
ewet04  DD OFFSET stop_exc_tcp_socket
ewet05  DD OFFSET stop_exc_dummy
ewet06  DD OFFSET stop_exc_dummy
ewet07  DD OFFSET stop_exc_dummy
ewet08  DD OFFSET stop_exc_dummy
ewet09  DD OFFSET stop_exc_dummy

stop_wait_for_exc    PROC far
    push ds
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov bx,es:sw_handle
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
;    
    cmp bx,MAX_HANDLES
    jae ewfeDone
;   
    movzx ebx,bx
    shl ebx,4
    add ebx,OFFSET h_arr
    mov ax,ds:[ebx].hp_handle
;
    cmp ax,SYS_HANDLE_COUNT
    jae ewfeDone
;    
    or ax,ax
    jz ewfeDone
;
    push ds
    push ebx
;
    movzx ebx,ax
    dec ebx
    shl ebx,4
    add ebx,OFFSET hd_sys_arr
    mov eax,SEG data
    mov ds,eax
;
    EnterSection ds:hd_section
    mov ax,ds:[ebx].sh_exc_wait_sel
    or ax,ax
    jz ewfeLeave
;
    push ds
    push ecx
    push edx
    push esi
;
    mov ds,eax
    movzx ecx,ds:hw_count
    mov esi,OFFSET hw_arr
    mov dx,es

ewfeFindLoop:
    lodsw
    cmp ax,dx
    je ewfeFound
;
    loop ewfeFindLoop
    jmp ewfeRemoved

ewfeFound:
    sub ecx,1
    jz ewfeRemove

ewfeMoveLoop:
    mov ax,ds:[esi]
    mov ds:[esi-2],ax
    add esi,2
    loop ewfeMoveLoop

ewfeRemove:
    sub ds:hw_count,1
    jnz ewfeRemoved
;
    push es
    mov eax,ds
    mov es,eax
    xor eax,eax
    mov ds,eax
    FreeMem
    pop es
;
    pop esi
    pop edx
    pop ecx
    pop ds
    mov ds:[ebx].sh_exc_wait_sel,0
    LeaveSection ds:hd_section
;
    movzx ebp,ds:[ebx].sh_type
    mov bx,ds:[ebx].sh_sel
    call dword ptr cs:[4*ebp].stop_wait_exc_tab
    jmp ewfePop

ewfeRemoved:
    pop esi
    pop edx
    pop ecx
    pop ds

ewfeLeave:
    LeaveSection ds:hd_section

ewfePop:
    pop ebx
    pop ds

ewfeDone:
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop ds    
    ret
stop_wait_for_exc Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearExc
;
;           DESCRIPTION:    Clear exception
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_exc    PROC far
    ret
clear_exc Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           HasExcData
;
;           DESCRIPTION:    Check for pending exception
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_exc_data      PROC far
    push ebx
;
    mov bx,es:sw_handle
    HasHandleException
    cmc
;
    pop ebx
    ret
has_exc_data Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:          AddWaitForHandleException
;
;           DESCRIPTION:   Add wait for handle exception
;
;           PARAMETERS:    IN  AX                Handle
;                          IN  BX                Wait handle
;                          IN  ECX               Object ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_handle_exception_name  DB 'Add Wait For Handle Exception', 0

add_wait_exc_tab:
awe0 DD OFFSET start_wait_for_exc,    SEG code
awe1 DD OFFSET stop_wait_for_exc,     SEG code
awe2 DD OFFSET clear_exc,             SEG code
awe3 DD OFFSET has_exc_data,          SEG code

add_wait_for_handle_exception	Proc far
    push ds
    push es
    push eax
    push edi
;
    push eax
    mov eax,cs
    mov es,eax
    mov ax,SIZE socket_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_exc_tab
    AddWait
    pop eax
    jc aweDone
;
    mov es:sw_handle,ax

aweDone:
    pop edi
    pop eax
    pop es
    pop ds
    ret
add_wait_for_handle_exception	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateTcpSocket
;
;       DESCRIPTION:    Create TCP socket
;
;       PARAMETERS:     OUT BX        Tcp handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_tcp_socket_name DB 'Create Tcp Socket', 0

create_tcp_socket    Proc far
    push es
    push eax
    push edx
;
    xor dx,dx
    mov ax,C_HANDLE_TCP_SOCKET
    AllocateCHandle
;
    mov cx,IO_READ OR IO_WRITE
    AllocateCProcHandle
;
    pop edx
    pop eax
    pop es
    ret
create_tcp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateUdpSocket
;
;       DESCRIPTION:    Create UDP socket
;
;       PARAMETERS:     OUT BX        Udp handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_udp_socket_name DB 'Create Udp Socket', 0

create_udp_socket    Proc far
    push es
    push eax
    push edx
;
    xor dx,dx
    mov ax,C_HANDLE_UDP_SOCKET
    AllocateCHandle
;
    mov cx,IO_READ OR IO_WRITE
    AllocateCProcHandle
;
    pop edx
    pop eax
    pop es
    ret
create_udp_socket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckSelect
;
;       DESCRIPTION:    Check for active handle
;
;       PARAMETERS:     DS        Handle sel
;                       ES:EDI    Read, write and exception masks
;                       CX        Handle count
;
;       RETURNS:        NC        Some active handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckSelect    Proc near
    push eax
    push ebx
    push ecx
    push edi
    push ebp
;
    or cx,cx
    jz csFail
;
    mov bp,cx
    xor bx,bx

csReadLoop:
    mov ah,1
    mov al,es:[edi]
    cmp cx,8
    jb csReadBit
;
    or al,al
    jnz csReadBit
;
    add bx,8
    sub cx,8
    jz csWrite
;
    inc edi
    jmp csReadLoop

csReadBit:
    test al,ah
    jz csReadNext
;
    push ecx
    call GetReadBufCount
    jc csReadPopNext
;
    or ecx,ecx
    stc
    jz csReadPopNext
;
    clc

csReadPopNext:
    pop ecx
    jnc csDone

csReadNext:
    inc bx
    shl ah,1
    sub cx,1
    test cx,7
    jnz csReadBit
;
    or cx,cx
    jz csWrite
;
    inc edi
    jmp csReadLoop

csWrite:
    mov cx,bp
    inc edi
    xor bx,bx

csWriteLoop:
    mov ah,1
    mov al,es:[edi]
    cmp cx,8
    jb csWriteBit
;
    or al,al
    jnz csWriteBit
;
    add bx,8
    sub cx,8
    jz csExc
;
    inc edi
    jmp csWriteLoop

csWriteBit:
    test al,ah
    jz csWriteNext
;
    push ecx
    call GetWriteBufSpace
    jc csWritePopNext
;
    or ecx,ecx
    stc
    jz csWritePopNext
;
    clc

csWritePopNext:
    pop ecx
    jnc csDone

csWriteNext:
    inc bx
    shl ah,1
    sub cx,1
    test cx,7
    jnz csWriteBit
;
    or cx,cx
    jz csExc
;
    inc edi
    jmp csWriteLoop

csExc:
    mov cx,bp
    inc edi
    xor bx,bx

csExcLoop:
    mov ah,1
    mov al,es:[edi]
    cmp cx,8
    jb csExcBit
;
    or al,al
    jnz csExcBit
;
    add bx,8
    sub cx,8
    jz csFail
;
    inc edi
    jmp csExcLoop

csExcBit:
    test al,ah
    jz csExcNext
;
    push ecx
    call HasException
    jc csExcPopNext
;
    or ecx,ecx
    stc
    jz csExcPopNext
;
    clc

csExcPopNext:
    pop ecx
    jnc csDone

csExcNext:
    inc bx
    shl ah,1
    sub cx,1
    test cx,7
    jnz csExcBit
;
    or cx,cx
    jz csFail
;
    inc edi
    jmp csExcLoop

csFail:
    stc

csDone:
    pop ebp
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret
CheckSelect    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdateSelect
;
;       DESCRIPTION:    Update select states
;
;       PARAMETERS:     DS        Handle sel
;                       ES:EDI    Read, write and exception masks
;                       CX        Handle count
;
;       RETURNS:        ECX       Non blocked handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSelect    Proc near
    push eax
    push ebx
    push edx
    push edi
    push ebp
;
    xor edx,edx
    or cx,cx
    jz usDone
;
    mov bp,cx
    xor bx,bx

usReadLoop:
    mov ah,1
    mov al,es:[edi]
    cmp cx,8
    jb usReadBit
;
    or al,al
    jnz usReadBit
;
    add bx,8
    sub cx,8
    jz usWrite
;
    inc edi
    jmp usReadLoop

usReadBit:
    test al,ah
    jz usReadNext
;
    push ecx
    call GetReadBufCount
    jc usReadClear
;
    or ecx,ecx
    jz usReadClear
;
    inc edx
    jmp usReadPopNext

usReadClear:
    mov cl,ah
    not cl
    and al,cl

usReadPopNext:
    pop ecx

usReadNext:
    inc bx
    shl ah,1
    sub cx,1
    test cx,7
    jnz usReadBit
;
    mov es:[edi],al
    or cx,cx
    jz usWrite
;
    inc edi
    jmp usReadLoop

usWrite:
    mov cx,bp
    inc edi
    xor bx,bx

usWriteLoop:
    mov ah,1
    mov al,es:[edi]
    cmp cx,8
    jb usWriteBit
;
    or al,al
    jnz usWriteBit
;
    add bx,8
    sub cx,8
    jz usWrite
;
    inc edi
    jmp usWriteLoop

usWriteBit:
    test al,ah
    jz usWriteNext
;
    push ecx
    call GetWriteBufSpace
    jc usWriteClear
;
    or ecx,ecx
    jz usWriteClear
;
    inc edx
    jmp usWritePopNext

usWriteClear:
    mov cl,ah
    not cl
    and al,cl

usWritePopNext:
    pop ecx

usWriteNext:
    inc bx
    shl ah,1
    sub cx,1
    test cx,7
    jnz usWriteBit
;
    mov es:[edi],al
    or cx,cx
    jz usExc
;
    inc edi
    jmp usWriteLoop

usExc:
    mov cx,bp
    inc edi
    xor bx,bx

usExcLoop:
    mov ah,1
    mov al,es:[edi]
    cmp cx,8
    jb usExcBit
;
    or al,al
    jnz usExcBit
;
    add bx,8
    sub cx,8
    jz usDone
;
    inc edi
    jmp usExcLoop

usExcBit:
    test al,ah
    jz usExcNext
;
    push ecx
    call HasException
    jc usExcClear
;
    inc edx
    jmp usExcPopNext

usExcClear:
    mov cl,ah
    not cl
    and al,cl

usExcPopNext:
    pop ecx

usExcNext:
    inc bx
    shl ah,1
    sub cx,1
    test cx,7
    jnz usExcBit
;
    mov es:[edi],al
    or cx,cx
    jz usDone
;
    inc edi
    jmp usExcLoop

usDone:
    mov ecx,edx
;
    pop ebp
    pop edi
    pop edx
    pop ebx
    pop eax
    ret
UpdateSelect    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Select
;
;       DESCRIPTION:    Select implementation
;
;       PARAMETERS:     ES:(E)DI    Read, write and exception masks
;                       (E)CX       Mask size
;
;       RETURNS:        ECX         Number of available handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

select_name DB 'Select', 0

select    Proc near
    call CheckSelect
    jnc sUpdate
;
    int 3

sUpdate:
    call UpdateSelect
    ret
select    Endp

select16    Proc far
    push ds
    push eax
    push edi
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    movzx ecx,cx
    movzx edi,di
    call select
;
    pop edi
    pop eax
    pop ds
    ret
select16    Endp

select32    Proc far
    push ds
    push eax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_proc_sel
    mov ds,ds:pf_c_handle_sel
    call select
;
    pop eax
    pop ds
    ret
select32    Endp

       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_chandle
;
;           DESCRIPTION:    Init C handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_handle

init_handle     PROC near
    push ds
    push es
    pushad
;
    mov bx,SEG data
    mov es,bx
;
    mov edi,OFFSET hd_proc_arr
    xor eax,eax
    mov ecx,MAX_PROC_COUNT
    rep stosw
;
    mov edi,OFFSET hd_sys_bitmap
    xor eax,eax
    mov ecx,SYS_BITMAP_COUNT
    rep stosd
;
    mov edi,OFFSET hd_sys_arr
    xor eax,eax
    mov ecx,4 * SYS_HANDLE_COUNT
    rep stosd
;
    InitSection es:hd_section
    mov es:hd_sys_bitmap,3
    mov es:hd_proc_count,0
;
    mov edi,OFFSET hd_sys_arr
    mov es:[edi].sh_type,C_HANDLE_STDIN
    mov es:[edi].sh_sel,0
    mov es:[edi].sh_ref_count,1
    mov es:[edi].sh_read_wait_sel,0
    mov es:[edi].sh_write_wait_sel,0
    mov es:[edi].sh_exc_wait_sel,0
;
    add edi,16
    mov es:[edi].sh_type,C_HANDLE_STDOUT
    mov es:[edi].sh_sel,0
    mov es:[edi].sh_ref_count,2
    mov es:[edi].sh_read_wait_sel,0
    mov es:[edi].sh_write_wait_sel,0
    mov es:[edi].sh_exc_wait_sel,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET create_c_handle
    mov edi,OFFSET create_c_handle_name
    xor cl,cl
    mov ax,create_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET clone_c_handle
    mov edi,OFFSET clone_c_handle_name
    xor cl,cl
    mov ax,clone_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_c_handle
    mov edi,OFFSET delete_c_handle_name
    xor cl,cl
    mov ax,delete_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_c_handle
    mov edi,OFFSET allocate_c_handle_name
    xor cl,cl
    mov ax,allocate_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET ref_c_handle
    mov edi,OFFSET ref_c_handle_name
    xor cl,cl
    mov ax,ref_c_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_c_proc_handle
    mov edi,OFFSET allocate_c_proc_handle_name
    xor cl,cl
    mov ax,allocate_c_proc_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET signal_read_handle
    mov edi,OFFSET signal_read_handle_name
    xor cl,cl
    mov ax,signal_read_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET signal_write_handle
    mov edi,OFFSET signal_write_handle_name
    xor cl,cl
    mov ax,signal_write_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET signal_exc_handle
    mov edi,OFFSET signal_exc_handle_name
    xor cl,cl
    mov ax,signal_exc_handle_nr
    RegisterOsGate
;
    mov ebx,OFFSET open_handle16
    mov esi,OFFSET open_handle32
    mov edi,OFFSET open_handle_name
    mov dx,virt_es_in
    mov ax,open_handle_nr
    RegisterUserGate
;
    mov esi,OFFSET delete_handle
    mov edi,OFFSET delete_handle_name
    xor cl,cl
    mov ax,delete_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_handle
    mov edi,OFFSET close_handle_name
    xor cl,cl
    mov ax,close_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_map
    mov edi,OFFSET get_handle_map_name
    xor cl,cl
    mov ax,get_handle_map_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET update_handle
    mov edi,OFFSET update_handle_name
    xor cl,cl
    mov ax,update_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET map_handle
    mov edi,OFFSET map_handle_name
    xor cl,cl
    mov ax,map_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET grow_handle
    mov edi,OFFSET grow_handle_name
    xor cl,cl
    mov ax,grow_handle_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET poll_handle16
    mov esi,OFFSET poll_handle32
    mov edi,OFFSET poll_handle_name
    mov dx,virt_es_in
    mov ax,poll_handle_nr
    RegisterUserGate
;
    mov ebx,OFFSET read_handle16
    mov esi,OFFSET read_handle32
    mov edi,OFFSET read_handle_name
    mov dx,virt_es_in
    mov ax,read_handle_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_handle16
    mov esi,OFFSET write_handle32
    mov edi,OFFSET write_handle_name
    mov dx,virt_es_in
    mov ax,write_handle_nr
    RegisterUserGate
;
    mov esi,OFFSET dup_handle
    mov edi,OFFSET dup_handle_name
    xor cl,cl
    mov ax,dup_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET dup2_handle
    mov edi,OFFSET dup2_handle_name
    xor cl,cl
    mov ax,dup2_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_size32
    mov edi,OFFSET get_handle_size32_name
    xor cl,cl
    mov ax,get_handle_size32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_size64
    mov edi,OFFSET get_handle_size64_name
    xor cl,cl
    mov ax,get_handle_size64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_size32
    mov edi,OFFSET set_handle_size32_name
    xor cl,cl
    mov ax,set_handle_size32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_size64
    mov edi,OFFSET set_handle_size64_name
    xor cl,cl
    mov ax,set_handle_size64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_mode
    mov edi,OFFSET get_handle_mode_name
    xor cl,cl
    mov ax,get_handle_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_mode
    mov edi,OFFSET set_handle_mode_name
    xor cl,cl
    mov ax,set_handle_mode_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_pos32
    mov edi,OFFSET get_handle_pos32_name
    xor cl,cl
    mov ax,get_handle_pos32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_pos64
    mov edi,OFFSET get_handle_pos64_name
    xor cl,cl
    mov ax,get_handle_pos64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_pos32
    mov edi,OFFSET set_handle_pos32_name
    xor cl,cl
    mov ax,set_handle_pos32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_pos64
    mov edi,OFFSET set_handle_pos64_name
    xor cl,cl
    mov ax,set_handle_pos64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET eof_handle
    mov edi,OFFSET eof_handle_name
    xor cl,cl
    mov ax,eof_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_handle_device
    mov edi,OFFSET is_handle_device_name
    xor cl,cl
    mov ax,is_handle_device_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_create_time
    mov edi,OFFSET get_handle_create_time_name
    xor cl,cl
    mov ax,get_handle_create_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_modify_time
    mov edi,OFFSET get_handle_modify_time_name
    xor cl,cl
    mov ax,get_handle_modify_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_access_time
    mov edi,OFFSET get_handle_access_time_name
    xor cl,cl
    mov ax,get_handle_access_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_time
    mov edi,OFFSET set_handle_modify_time_name
    xor cl,cl
    mov ax,set_handle_modify_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_ipv4_socket
    mov edi,OFFSET is_ipv4_socket_name
    xor cl,cl
    mov ax,is_ipv4_socket_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET connect_ipv4_socket
    mov edi,OFFSET connect_ipv4_socket_name
    xor cl,cl
    mov ax,connect_ipv4_socket_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_handle_read
    mov edi,OFFSET add_wait_for_handle_read_name
    xor cl,cl
    mov ax,add_wait_for_handle_read_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_handle_write
    mov edi,OFFSET add_wait_for_handle_write_name
    xor cl,cl
    mov ax,add_wait_for_handle_write_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_handle_exception
    mov edi,OFFSET add_wait_for_handle_exception_name
    xor cl,cl
    mov ax,add_wait_for_handle_exception_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_read_buf_count
    mov edi,OFFSET get_handle_read_buf_count_name
    xor cl,cl
    mov ax,get_handle_read_buf_count_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_write_buf_space
    mov edi,OFFSET get_handle_write_buf_space_name
    xor cl,cl
    mov ax,get_handle_write_buf_space_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_handle_exception
    mov edi,OFFSET has_handle_exception_name
    xor cl,cl
    mov ax,has_handle_exception_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_tcp_socket
    mov edi,OFFSET create_tcp_socket_name
    xor dx,dx
    mov ax,create_tcp_socket_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_udp_socket
    mov edi,OFFSET create_udp_socket_name
    xor dx,dx
    mov ax,create_udp_socket_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET select16
    mov esi,OFFSET select32
    mov edi,OFFSET select_name
    mov dx,virt_es_in
    mov ax,select_nr
    RegisterUserGate
;
    popad
    pop es
    pop ds
    ret
init_handle     ENDP

code    ENDS

    END
