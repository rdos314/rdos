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
USER_HANDLE_COUNT     = 512
USER_BITMAP_COUNT     = USER_HANDLE_COUNT SHR 5

;
; this should always be 8 bytes!

proc_entry_struc       STRUC

pe_sel          DW ?
pe_handle       DW ?
pe_access       DW ?
pe_resv         DW ?

proc_entry_struc       ENDS

proc_handle_struc    STRUC

ph_linear        DD ?
ph_section       section_typ <>
ph_bitmap        DD USER_BITMAP_COUNT DUP(?)
ph_arr           DW USER_HANDLE_COUNT DUP(?)

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
    push es
;
    mov eax,flat_sel
    mov es,eax
;
    mov eax,SIZE proc_handle_struc
    AllocateSmallLinear
    mov es:[edx].ph_linear,edx
;
    lea edi,[edx].ph_bitmap
    xor eax,eax
    mov ecx,USER_BITMAP_COUNT
    rep stosd
;
    lea edi,[edx].ph_arr
    xor ax,ax
    mov ecx,USER_HANDLE_COUNT
    rep stosw
;
    InitSection es:[edx].ph_section
;
    pop es
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
    push es
    push eax
    push ecx
    push esi
    push edi
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
    mov ds:hsi_ref_count,0
    mov ds:hsi_index,0
    InitSection ds:hsi_section
;
    mov eax,ds
    mov es,eax
;
    mov edi,OFFSET hsi_proc_arr
    xor eax,eax
    mov ecx,PROC_HANDLE_COUNT
    rep stosd
;
    mov edi,OFFSET hsi_sel_arr
    xor eax,eax
    mov ecx,PROC_HANDLE_COUNT
    rep stosw
;
    mov edi,OFFSET hsi_proc_bitmap
    xor eax,eax
    mov ecx,SYS_BITMAP_COUNT
    rep stosd
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    ret
CreateSysObj   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateLocalSysHandle
;
;           DESCRIPTION:    Allocate local sys file handle
;
;           PARAMETERS:     DS          Sys handle sel
;
;           RETURNS:        EBX         Sys handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AllocateLocalSysHandle

AllocateLocalSysHandle     Proc near
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

alshLoop:
    mov eax,ds:[bx]
    not eax
    bsf edx,eax
    jnz alshOk
;
    add bx,4
    add edi,32
;
    loop alshLoop
;
    stc
    pop edx
    jmp alshLeave

alshOk:
    add edx,edi
    lock bts ds:hd_sys_bitmap,edx
    jc alshLoop
;
    pop eax
    mov ds:[2*edx].hd_sys_arr,ax
;
    mov ebx,edx
    inc ebx
    clc

alshLeave:
    LeaveSection ds:hd_section
; 
    pop edi
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
AllocateLocalSysHandle  Endp   

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
    push ecx
    push edx
    push esi
    push edi
;
    mov eax,proc_handle_sel
    mov es,eax
    mov edx,es:ph_linear
;
    mov ecx,PROC_BITMAP_COUNT  
    mov esi,OFFSET hsi_proc_bitmap
    mov edi,OFFSET hsi_proc_arr

fpLoop:
    mov eax,ds:[esi]
    or eax,eax
    jz fpNext
;
    push ecx
    mov ecx,32

fpeLoop:
    cmp edx,ds:[edi]
    jne fpeNext
;
    pop ecx
    sub edi,OFFSET hsi_proc_arr
    shl edi,2
    mov ax,ds:[2*edi].hsi_sel_arr
    clc
    jmp fpDone

fpeNext:
    add edi,4
    loop fpeLoop
;
    pop ecx
    jmp fpCont

fpNext:
    add edi,4*32

fpCont:
    add esi,4
    loop fpLoop
;
    stc

fpDone:
    pop edi
    pop esi
    pop ecx
    pop es
    ret
FindProc    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateProcObj
;
;           DESCRIPTION:    Create proc object
;
;           PARAMETERS:     EAX        Size of object
;                           DS         Sys handle sel
;
;           RETURNS:        AX         Proc handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateProcObj

cr_handle_fail    Proc far
    stc
    ret
cr_handle_fail    Endp

del_proc_fail    Proc far
    stc
    ret
del_proc_fail    Endp

CreateProcObj    Proc near
    push es
    push ebx
    push ecx
    push edx
;
    AllocateSmallLinear
;
    push ds
    AllocateLdt
    pop ds
;
    or bx,4
    mov ecx,eax
    CreateDataSelector32
    mov es,ebx
;
    mov es:hpi_create_proc,OFFSET cr_handle_fail
    mov es:hpi_create_proc+4,cs
;
    mov es:hpi_delete_proc,OFFSET del_proc_fail
    mov es:hpi_delete_proc+4,cs
;
    mov es:hpi_linear,edx
    mov es:hpi_proc_linear,0
    mov es:hpi_index,0
    mov es:hpi_ref_count,1
    mov es:hpi_sys_sel,ds
;
    mov eax,ds:hsi_index
    mov es:hpi_sys_index,eax
;
    mov eax,es
;
    pop edx
    pop ecx
    pop ebx
    pop es
    ret
CreateProcObj   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateProcHandle
;
;           DESCRIPTION:    Allocate proc handle
;
;           PARAMETERS:     DS          Sys handle sel
;                           AX          Proc handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateProcHandle     Proc near
    push es
    pushad
;
    mov ebp,eax
;
    mov ecx,PROC_BITMAP_COUNT  
    xor edi,edi
    mov bx,OFFSET hsi_proc_bitmap

alphLoop:
    mov eax,ds:[bx]
    not eax
    bsf edx,eax
    jnz alphOk
;
    add bx,4
    add edi,32
;
    loop alphLoop
;
    stc
    jmp alphDone

alphOk:
    add edx,edi
    lock bts ds:hsi_proc_bitmap,edx
    jc alphLoop
;
    mov ebx,proc_handle_sel
    mov es,ebx
    mov ebx,edx
    mov edx,es:ph_linear
    mov ds:[4*ebx].hsi_proc_arr,edx
    mov ds:[2*ebx].hsi_sel_arr,es
;
    mov es,ebp
    inc ebx
    mov es:hpi_index,ebx
    mov es:hpi_proc_linear,edx
    clc

alphDone:
    popad
    pop es
    ret
AllocateProcHandle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateHandleObj
;
;           DESCRIPTION:    Create proc object
;
;           PARAMETERS:     EAX        Size of object
;                           DS         Proc handle sel
;
;           RETURNS:        AX         Handle sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateHandleObj

handle_fail    Proc far
    stc
    ret
handle_fail    Endp

CreateHandleObj    Proc near
    push ds
    push es
    push ebx
    push ecx
    push edx
;
    AllocateSmallLinear
;
    push ds
    AllocateLdt
    pop ds
;
    or bx,4
    mov ecx,eax
    CreateDataSelector32
    mov es,ebx
;
    mov es:hei_dup_proc,OFFSET handle_fail
    mov es:hei_dup_proc+4,cs
;
    mov es:hei_get_map_proc,OFFSET handle_fail
    mov es:hei_get_map_proc+4,cs
;
    mov es:hei_poll_proc,OFFSET handle_fail
    mov es:hei_poll_proc+4,cs
;
    mov es:hei_read_proc,OFFSET handle_fail
    mov es:hei_read_proc+4,cs
;
    mov es:hei_write_proc,OFFSET handle_fail
    mov es:hei_write_proc+4,cs
;
    mov es:hei_get_size_proc,OFFSET handle_fail
    mov es:hei_get_size_proc+4,cs
;
    mov es:hei_set_size_proc,OFFSET handle_fail
    mov es:hei_set_size_proc+4,cs
;
    mov es:hei_get_pos_proc,OFFSET handle_fail
    mov es:hei_get_pos_proc+4,cs
;
    mov es:hei_set_pos_proc,OFFSET handle_fail
    mov es:hei_set_pos_proc+4,cs
;
    mov es:hei_get_create_time_proc,OFFSET handle_fail
    mov es:hei_get_create_time_proc+4,cs
;
    mov es:hei_get_modify_time_proc,OFFSET handle_fail
    mov es:hei_get_modify_time_proc+4,cs
;
    mov es:hei_get_access_time_proc,OFFSET handle_fail
    mov es:hei_get_access_time_proc+4,cs
;
    mov es:hei_set_modify_time_proc,OFFSET handle_fail
    mov es:hei_set_modify_time_proc+4,cs
;
    mov es:hei_is_eof_proc,OFFSET handle_fail
    mov es:hei_is_eof_proc+4,cs
;
    mov es:hei_is_device_proc,OFFSET handle_fail
    mov es:hei_is_device_proc+4,cs
;
    mov es:hei_is_ip4_proc,OFFSET handle_fail
    mov es:hei_is_ip4_proc+4,cs
;
    mov es:hei_input_size_proc,OFFSET handle_fail
    mov es:hei_input_size_proc+4,cs
;
    mov es:hei_output_size_proc,OFFSET handle_fail
    mov es:hei_output_size_proc+4,cs
;
    mov es:hei_delete,OFFSET handle_fail
    mov es:hei_delete+4,cs
;
    mov es:hei_index,0
    mov es:hei_proc_sel,ds
;
    mov eax,ds:hpi_index
    mov es:hei_proc_index,eax
;
    mov ds,ds:hpi_sys_sel
    mov es:hei_sys_sel,ds
;
    mov eax,ds:hsi_index
    mov es:hei_sys_index,eax
;
    mov eax,es
;
    pop edx
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
CreateHandleObj   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateUserHandle
;
;           DESCRIPTION:    Allocate user handle
;
;           PARAMETERS:     DS          Handle interface
;
;           RETURNS:        EBX         User handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateUserHandle     Proc near
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov eax,proc_handle_sel
    mov es,eax
;
    mov ecx,USER_BITMAP_COUNT  
    xor edi,edi
    mov bx,OFFSET ph_bitmap

aluhLoop:
    mov eax,es:[bx]
    not eax
    bsf edx,eax
    jnz aluhOk
;
    add bx,4
    add edi,32
;
    loop aluhLoop
;
    stc
    jmp aluhDone

aluhOk:
    add edx,edi
    lock bts es:ph_bitmap,edx
    jc aluhLoop
;
    mov ebx,edx
    mov es:[2*ebx].ph_arr,ds
;
    inc ebx
    clc

aluhDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
AllocateUserHandle  Endp   

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
;  
    call OpenVfsFile
    jc ohFail
;
    EnterSection ds:hsi_section
;
    call FindProc
    jnc ohProcOk
;
    call fword ptr ds:hsi_create_proc
    jc ohFail
;
    call AllocateProcHandle
    jc ohFail

ohProcOk:
    LeaveSection ds:hsi_section
;
    mov ds,eax
;
    call fword ptr ds:hpi_create_proc
    jc ohFail
;
    call AllocateUserHandle
    jc ohFail
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
