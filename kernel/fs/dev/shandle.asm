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
; SHANDLE.ASM
; Sys handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
include ..\wait.inc
INCLUDE ..\os\blk.inc
INCLUDE ..\hint.inc
INCLUDE ..\driver.def
INCLUDE ..\os\exec.def
INCLUDE vfs.inc

    .386p

SYS_HANDLE_COUNT      = 1024
SYS_BITMAP_COUNT      = SYS_HANDLE_COUNT SHR 5
PROC_COUNT            = 512

;
; this should always be 8 bytes!

proc_entry_struc       STRUC

pe_sel          DW ?
pe_handle       DW ?
pe_access       DW ?
pe_resv         DW ?

proc_entry_struc       ENDS

proc_handle_struc    STRUC

ph_section       section_typ <>
ph_arr           DD 2 * PROC_COUNT DUP(?)

proc_handle_struc    ENDS

data    SEGMENT byte public 'DATA'

hd_section       section_typ <>
hd_proc_count    DW ?

hd_proc_arr      DD MAX_PROC_COUNT DUP(?)
hd_sys_bitmap    DD SYS_BITMAP_COUNT DUP(?)
hd_sys_arr       DW SYS_HANDLE_COUNT DUP(?)

data       ENDS

code    SEGMENT byte public 'CODE'
    
    assume cs:code

    extern OpenVfsFile:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateProcHandle
;
;           DESCRIPTION:    Create proc handle
;
;           PARAMETERS:     ES          New process thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_proc_handle_name DB 'Create Proc Handle', 0

create_proc_handle Proc far
    push ds
    pushad
;
    mov eax,flat_sel
    mov ds,eax
;
    mov eax,SIZE proc_handle_struc
    AllocateSmallLinear
;    
    lea edi,[edx].ph_arr
    mov ds:[edi].pe_sel,0
    mov ds:[edi].pe_handle,1
    mov ds:[edi].pe_access,IO_READ OR IO_ISTTY
;
    add edi,8
    mov ds:[edi].pe_sel,0
    mov ds:[edi].pe_handle,2
    mov ds:[edi].pe_access,IO_WRITE OR IO_ISTTY
;
    add edi,8
    mov ds:[edi].pe_sel,0
    mov ds:[edi].pe_handle,2
    mov ds:[edi].pe_access,IO_WRITE OR IO_ISTTY
;    
    mov ecx,PROC_COUNT - 3

nsLoop:
    add edi,8
    mov ds:[edi].pe_sel,0
    mov ds:[edi].pe_handle,0
    mov ds:[edi].pe_access,0
    loop nsLoop
;    
    InitSection ds:[edx].ph_section
;    
    mov eax,SEG data
    mov ds,eax
;
    EnterSection ds:hd_section
    movzx ebx,ds:hd_proc_count
    shl ebx,2
    mov ds:[ebx].hd_proc_arr,edx
    inc ds:hd_proc_count
    LeaveSection ds:hd_section
;
    mov ds,es:p_proc_sel
    mov ds:pf_handle_linear,edx
;
    popad
    pop ds
    ret
create_proc_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ApplyProcHandle
;
;           DESCRIPTION:    Apply proc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

apply_proc_handle_name DB 'Apply Proc Handle', 0

apply_proc_handle Proc far
    push ds
    push eax
    push edx
;
    GetThread
    mov ds,eax
    mov ds,ds:p_proc_sel
    mov edx,ds:pf_handle_linear
    mov bx,proc_handle_sel
    mov ecx,SIZE proc_handle_struc
    CreateDataSelector32

aphDone:
    pop edx
    pop eax
    pop ds
    ret
apply_proc_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSysObj
;
;           DESCRIPTION:    Create sys object
;
;           PARAMETERS:     EAX        Size of object
;
;           RETURNS:        DS         Sys handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateSysObj

cr_proc_fail    Proc far
    stc
    ret
cr_proc_fail    Endp

del_sys_fail    Proc far
    stc
    ret
del_sys_fail    Endp

CreateSysObj    Proc near
    push eax
    push esi
;
    mov esi,eax
    mov ax,8
    CreateBlk
;
    mov ds:hsi_create_proc,OFFSET cr_proc_fail
    mov ds:hsi_create_proc+4,cs
;
    mov ds:hsi_delete_proc,OFFSET del_sys_fail
    mov ds:hsi_delete_proc+4,cs
;
    mov ds:hsi_proc_count,0
    mov ds:hsi_index,0
    InitSection ds:hsi_section
;
    pop esi
    pop eax
    ret
CreateSysObj   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateVfsSysHandle
;
;           DESCRIPTION:    Allocate VFS sys file handle
;
;           PARAMETERS:     DS          Sys handle sel
;
;           RETURNS:        EBX         Sys handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateVfsSysHandle

AllocateVfsSysHandle     Proc near
    push ds
    push eax
    push ecx
    push edx
    push edi
;
    push ds
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:hd_section
;
    mov ecx,SYS_BITMAP_COUNT  
    xor edi,edi
    mov bx,OFFSET hd_sys_bitmap

avhLoop:
    mov eax,ds:[bx]
    not eax
    bsf edx,eax
    jnz avhOk
;
    add bx,4
    add edi,32
;
    loop avhLoop
;
    stc
    pop edx
    jmp avhLeave

avhOk:
    add edx,edi
    bts ds:hd_sys_bitmap,edx
;
    pop eax
    mov ds:[2*edx].hd_sys_arr,ax
;
    mov ebx,edx
    inc bx
    clc

avhLeave:
    LeaveSection ds:hd_section
; 
    pop edi
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
AllocateVfsSysHandle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindProc
;
;       DESCRIPTION:    Find proc sel
;
;       PARAMETERS:     DS              Sys handle sel
;
;       RETURNS:        NC
;                         AX            Proc handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindProc      Proc near
    push es
    push ebx
    push ecx
;
    movzx ecx,ds:hsi_proc_count
    or ecx,ecx
    jz fpFail
;
;    GetThread
;    mov es,ax
;    mov es,es:p_proc_sel
;    mov ax,es:pf_c_handle_sel
;
;    mov ebx,OFFSET kf_proc_arr
;    mov ecx,ds:kf_proc_count
;    or ecx,ecx
;    stc
;    jz fvmDone

fvmLoop:
;    cmp ax,ds:[ebx].pe_proc_sel
;    je fvmFound
;
;    add ebx,4
;    loop fvmLoop
;

fpFail:
    stc
;    jmp fvmDone

fvmFound:
;    mov ax,ds:[ebx].pe_map_sel
;    clc

fvmDone:
    pop ecx
    pop ebx
    pop es
    ret
FindProc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenHandle
;
;           DESCRIPTION:    Open handle
;
;           PARAMETERS:     ES:(E)DI    Name
;                           CX          Mode
;
;           RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_handle_name  DB 'Open Handle', 0

open_handle     Proc near
    push ds
    push eax
    push ecx
    push edx
    push ebp
;  
    call OpenVfsFile
    jc ohFail
;
    call FindProc
;

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
;           NAME:           init_shandle
;
;           DESCRIPTION:    Init sys handle module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_sys_handle

init_sys_handle     PROC near
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
    rep stosd
;
    mov edi,OFFSET hd_sys_bitmap
    xor eax,eax
    mov ecx,SYS_BITMAP_COUNT
    rep stosd
;
    mov edi,OFFSET hd_sys_arr
    xor ax,ax
    mov ecx,SYS_HANDLE_COUNT
    rep stosw
;
    InitSection es:hd_section
    mov es:hd_sys_bitmap,3
    mov es:hd_proc_count,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET create_proc_handle
    mov edi,OFFSET create_proc_handle_name
    xor cl,cl
    mov ax,create_proc_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET apply_proc_handle
    mov edi,OFFSET apply_proc_handle_name
    xor cl,cl
    mov ax,apply_proc_handle_nr
    RegisterOsGate
;
    mov ebx,OFFSET open_handle16
    mov esi,OFFSET open_handle32
    mov edi,OFFSET open_handle_name
    mov dx,virt_es_in
    mov ax,open_new_handle_nr
    RegisterUserGate
;
    popad
    pop es
    pop ds
    ret
init_sys_handle     ENDP

code    ENDS

    END
