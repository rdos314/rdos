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

SYS_BITMAP_COUNT      = SYS_HANDLE_COUNT SHR 5
USER_HANDLE_COUNT     = 512
USER_BITMAP_COUNT     = USER_HANDLE_COUNT SHR 5

KERNEL_HANDLE_COUNT   = 64
KERNEL_BITMAP_COUNT   = KERNEL_HANDLE_COUNT SHR 5

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

hd_input_sel     DW ?
hd_output_sel    DW ?

hd_proc_arr      DD MAX_PROC_COUNT DUP(?)
hd_sys_bitmap    DD SYS_BITMAP_COUNT DUP(?)
hd_sys_arr       DW SYS_HANDLE_COUNT DUP(?)

kh_section       section_typ <>
kh_bitmap        DD KERNEL_BITMAP_COUNT DUP(?)
kh_arr           DW KERNEL_HANDLE_COUNT DUP(?)

data       ENDS

code    SEGMENT byte public 'CODE'
    
    assume cs:code

    extern OpenVfsFile:near
    extern OpenKernelVfsFile:near

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
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:hd_input_sel
    or ax,ax
    jnz cpStdOk
;
    push es

    CreateInputHandle
    mov es,eax
    inc es:hei_ref_count
    mov ds:hd_input_sel,es
;
    CreateOutputHandle
    mov es,eax
    inc es:hei_ref_count
    mov ds:hd_output_sel,es
;
    pop es

cpStdOk:
    push es
    push fs
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
    mov ax,ds:hd_input_sel
    mov fs,eax
    inc fs:hei_ref_count
    mov es:[edx].ph_arr,fs
;
    mov ax,ds:hd_output_sel
    mov fs,eax
    add fs:hei_ref_count,2
    mov es:[edx].ph_arr+2,fs
    mov es:[edx].ph_arr+4,fs
;
    mov es:[edx].ph_bitmap,7
;
    pop fs
    pop es
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
;           NAME:           InitSysObj
;
;           DESCRIPTION:    Init sys object
;
;           PARAMETERS:     ES         Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sys_fail    Proc far
    stc
    ret
sys_fail    Endp

InitSysObj  Proc near
    push eax
    push ecx
    push edi
;
    mov es:hsi_create_proc_proc,OFFSET sys_fail
    mov es:hsi_create_proc_proc+4,cs
;
    mov es:hsi_create_kernel_proc,OFFSET sys_fail
    mov es:hsi_create_kernel_proc+4,cs
;
    mov es:hsi_create_handle_proc,OFFSET sys_fail
    mov es:hsi_create_handle_proc+4,cs
;
    mov es:hsi_delete_proc,OFFSET sys_fail
    mov es:hsi_delete_proc+4,cs
;
    mov es:hsi_kernel_sel,0
    mov es:hsi_ref_count,0
    mov es:hsi_index,0
    InitSection es:hsi_section
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
    pop ecx
    pop eax
    ret
InitSysObj  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSysObj
;
;           DESCRIPTION:    Create sys object
;
;           PARAMETERS:     EAX        Size of object
;
;           RETURNS:        DS         Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateSysObj

CreateSysObj    Proc near
    push es
    push eax
    push ecx
    push esi
;
    mov esi,eax
    mov ax,8
    CreateBlk
;
    mov eax,ds
    mov es,eax
;
    call InitSysObj
;
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
;           PARAMETERS:     DS          Sys interface
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
;       PARAMETERS:     DS              Sys interface
;
;       RETURNS:        NC
;                         AX            Proc interface
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
    pop edx
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
;           PARAMETERS:     DS         Sys interface
;                           EAX        Size of oebject
;                           EDX        Linear address of object
;                           
;           RETURNS:        AX         Proc interface
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
    mov es:hpi_ref_count,0
    mov es:hpi_sys_sel,ds
;
    mov eax,ds:hsi_index
    mov es:hpi_sys_index,eax
;
    mov eax,es
;
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
;           PARAMETERS:     DS          Sys interface
;                           AX          Proc interface
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
    mov ds:[2*ebx].hsi_sel_arr,bp
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
;           NAME:           InitHandleObj
;
;           DESCRIPTION:    Init handle object
;
;           PARAMETERS:     ES         Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handle_ok      Proc far
    clc
    ret
handle_ok      Endp

handle_fail    Proc far
    stc
    ret
handle_fail    Endp

InitHandleObj  Proc near
    mov es:hei_dup_proc,OFFSET handle_fail
    mov es:hei_dup_proc+4,cs
;
    mov es:hei_get_map_proc,OFFSET handle_fail
    mov es:hei_get_map_proc+4,cs
;
    mov es:hei_map_proc,OFFSET handle_fail
    mov es:hei_map_proc+4,cs
;
    mov es:hei_update_map_proc,OFFSET handle_fail
    mov es:hei_update_map_proc+4,cs
;
    mov es:hei_grow_map_proc,OFFSET handle_fail
    mov es:hei_grow_map_proc+4,cs
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
    mov es:hei_poll_proc,OFFSET handle_fail
    mov es:hei_poll_proc+4,cs
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
    mov es:hei_delete_proc,OFFSET handle_fail
    mov es:hei_delete_proc+4,cs
;
    mov es:hei_ref_count,0
    mov es:hei_index,0
    mov es:hei_proc_sel,0
    mov es:hei_proc_index,0
    mov es:hei_sys_sel,0
    mov es:hei_sys_index,0
    ret
InitHandleObj    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateHandleObj
;
;           DESCRIPTION:    Create proc object
;
;           PARAMETERS:     DS         Proc interface
;                           EAX        Size of oebject
;                           EDX        Linear address of object
;
;           RETURNS:        AX         Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateHandleObj

CreateHandleObj    Proc near
    push ds
    push es
    push ebx
    push ecx
;
    push ds
    AllocateLdt
    pop ds
;
    or bx,4
    mov ecx,eax
    CreateDataSelector32
    mov es,ebx
    call InitHandleObj
;
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
;           NAME:           OpenHandleObj
;
;           DESCRIPTION:    Open handle
;
;           PARAMETERS:     ES:EDI      Name
;                           CX          Mode
;
;           RETURNS:        EBX         Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenHandleObj     Proc near
    push ds
    push es
    push eax
;  
    call OpenVfsFile
    jc ohLegacy
;
    EnterSection ds:hsi_section
;
    call FindProc
    jnc ohProcOk
;
    inc ds:hsi_ref_count
;
    call fword ptr ds:hsi_create_proc_proc
    jc ohFail
;
    call AllocateProcHandle
    jc ohFail

ohProcOk:
    mov es,eax
    add es:hpi_ref_count,1
;
    LeaveSection ds:hsi_section
;
    mov ds,eax
    call fword ptr ds:hpi_create_proc
    jc ohFail
;
    mov ds,eax
    inc ds:hei_ref_count
    call AllocateUserHandle
    jc ohFail

ohCheckTrunc:
    test cx,O_CREAT OR O_TRUNC
    jz ohSizeOk
;
    xor eax,eax
    xor edx,edx
    SetHandleSize64

ohSizeOk:
    call OpenToIo
    mov ds:hei_io_mode,ax
    clc
    jmp ohDone

ohLegacy:  
    OpenLegacyHandle
    jc ohFail
;
    EnterSection ds:hsi_section
    inc ds:hsi_ref_count
    LeaveSection ds:hsi_section
;
    call fword ptr ds:hsi_create_handle_proc
    jc ohFail
;
    mov ebx,ds:hsi_index

    mov ds,eax
    mov ds:hei_sys_index,ebx
;
    inc ds:hei_ref_count
    call AllocateUserHandle
    jnc ohCheckTrunc

ohFail:
    xor ebx,ebx
    stc

ohDone:
    pop eax
    pop es
    pop ds
    ret
OpenHandleObj     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseHandleObj
;
;           DESCRIPTION:    Close handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseHandleObj     Proc near
    push ds
    push es
    pushad
;
    movzx ebx,bx
    mov eax,proc_handle_sel
    mov ds,eax
;
    cmp ebx,USER_HANDLE_COUNT
    jae chFail
;
    xor ax,ax
    xchg ax,ds:[2*ebx].ph_arr
    or ax,ax
    jz chFail
;
    btc ds:ph_bitmap,ebx
    jnc chFail
;
    mov ds,eax
    sub ds:hei_ref_count,1
    jnz chOk
;
    mov es,eax
    call fword ptr ds:hei_delete_proc
;
    mov ax,ds:hei_proc_sel
    or ax,ax
    jnz chCheckProc
;
    mov ax,ds:hei_sys_sel
    or ax,ax
    jz chOk
;
    mov ebx,ds:hei_sys_index
    mov ds,eax
    EnterSection ds:hsi_section
    jmp chCheckSys

chCheckProc:
    mov ebx,ds:hei_proc_index
    cmp ebx,PROC_HANDLE_COUNT
    jbe chProcHighOk
;
    int 3

chProcHighOk:
    sub ebx,1
    jae chProcLowOk
;
    int 3

chProcLowOk:
    mov ds,ds:hei_proc_sel
    FreeMem
;
    mov ebp,ds
    mov es,ebp
    mov ds,ds:hpi_sys_sel
    EnterSection ds:hsi_section
;
    sub es:hpi_ref_count,1
    jnz chLeave
;
    xor ax,ax
    xchg ax,ds:[2*ebx].hsi_sel_arr
    cmp ax,bp
    je chSelOk
;
    int 3

chSelOk:
    xor eax,eax
    xchg eax,ds:[4*ebx].hsi_proc_arr
;
    btc ds:hsi_proc_bitmap,ebx
    jc chBitOk
;
    int 3

chBitOk:
    mov ds,ebp
    call fword ptr ds:hpi_delete_proc
;
    mov ebx,ds:hpi_sys_index
    mov ds,ds:hpi_sys_sel

chCheckSys:
    cmp ebx,SYS_HANDLE_COUNT
    jbe chSysHighOk
;
    int 3

chSysHighOk:
    sub ebx,1
    jae chSysLowOk
;
    int 3

chSysLowOk:
    FreeMem

    sub ds:hsi_ref_count,1
    jnz chLeave
;
    mov edx,ds
    mov eax,SEG data
    mov es,eax
    xor ax,ax
    xchg ax,es:[2*ebx].hd_sys_arr
    cmp ax,dx
    je chSysOk
;
    int 3

chSysOk:
    btc es:hd_sys_bitmap,ebx
    jc chSysBitOk
;
    int 3

chSysBitOk:
    LeaveSection ds:hsi_section
    call fword ptr ds:hsi_delete_proc
    clc
    jmp chDone

chLeave:
    LeaveSection ds:hsi_section
    clc
    jmp chDone

chFail:
    stc

chOk:
    clc

chDone:
    popad
    pop es
    pop ds
    ret
CloseHandleObj     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DupHandleObj
;
;           DESCRIPTION:    Dup handle
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EBX         New handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DupHandleObj   Proc near
    push ds
    push eax
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae dhFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz dhFail
;
    mov ds,esi
    call fword ptr ds:hei_dup_proc
    jc dhFail
;
    mov ds,eax
    inc ds:hei_ref_count
    call AllocateUserHandle
    jnc dhDone

dhFail:
    stc

dhDone:
    pop esi
    pop eax
    pop ds
    ret
DupHandleObj   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleMapObj
;
;           DESCRIPTION:    Get handle map
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Map index
;                           EDI         Map linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHandleMapObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae ghmFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghmFail
;
    mov ds,esi
    test ds:hei_io_mode,IO_READ
    jz ghmFail
;
    call fword ptr ds:hei_get_map_proc
    jnc ghmDone

ghmFail:
    xor eax,eax
    xor edi,edi
    stc

ghmDone:
    pop esi
    pop ebx
    pop ds
    ret
GetHandleMapObj     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapHandleObj
;
;           DESCRIPTION:    Map handle
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     File position
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapHandleObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae mhFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz mhFail
;
    mov ds,esi
    test ds:hei_io_mode,IO_READ
    jz mhFail
;
    call fword ptr ds:hei_map_proc
    jnc mhDone

mhFail:
    stc

mhDone:
    pop esi
    pop ebx
    pop ds
    ret
MapHandleObj     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateHandleMapObj
;
;           DESCRIPTION:    Update handle map
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateHandleMapObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae uhmFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz uhmFail
;
    mov ds,esi
    call fword ptr ds:hei_update_map_proc
    jnc uhmDone

uhmFail:
    stc

uhmDone:
    pop esi
    pop ebx
    pop ds
    ret
UpdateHandleMapObj     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GrowHandleMapObj
;
;           DESCRIPTION:    Grow handle map
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     Position
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GrowHandleMapObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae ghmoFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghmoFail
;
    mov ds,esi
    call fword ptr ds:hei_grow_map_proc
    jnc ghmoDone

ghmoFail:
    stc

ghmoDone:
    pop esi
    pop ebx
    pop ds
    ret
GrowHandleMapObj     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadHandleObj
;
;           DESCRIPTION:    Read handle
;
;           PARAMETERS:     BX          Handle
;                           ES:EDI      Buffer
;                           ECX         Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadHandleObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae rhFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz rhFail
;
    mov ds,esi
    test ds:hei_io_mode,IO_READ
    jz rhFail
;
    call fword ptr ds:hei_read_proc
    mov eax,ecx
    jnc rhDone

rhFail:
    xor eax,eax
    stc

rhDone:
    pop esi
    pop ebx
    pop ds
    ret
ReadHandleObj     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHandleObj
;
;           DESCRIPTION:    Write handle
;
;           PARAMETERS:     BX          Handle
;                           ES:EDI      Buffer
;                           ECX         Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHandleObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae whFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz whFail
;
    mov ds,esi
    test ds:hei_io_mode,IO_WRITE
    jz whFail
;
    call fword ptr ds:hei_write_proc
    mov eax,ecx
    jnc whDone

whFail:
    xor eax,eax
    stc

whDone:
    pop esi
    pop ebx
    pop ds
    ret
WriteHandleObj     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PollHandleObj
;
;           DESCRIPTION:    Poll handle
;
;           PARAMETERS:     BX          Handle
;                           ES:EDI      Buffer
;                           ECX         Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollHandleObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae phFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz phFail
;
    mov ds,esi
    test ds:hei_io_mode,IO_READ
    jz phFail
;
    call fword ptr ds:hei_poll_proc
    mov eax,ecx
    jnc phDone

phFail:
    xor eax,eax
    stc

phDone:
    pop esi
    pop ebx
    pop ds
    ret
PollHandleObj     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandlePosObj
;
;           DESCRIPTION:    Get handle pos
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDX:EAX   Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHandlePosObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae ghpFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghpFail
;
    mov ds,esi
    call fword ptr ds:hei_get_pos_proc
    jmp ghpDone

ghpFail:
    xor eax,eax
    xor edx,edx
    stc

ghpDone:
    pop esi
    pop ebx
    pop ds
    ret
GetHandlePosObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandlePosObj
;
;           DESCRIPTION:    Set handle pos
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetHandlePosObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae shpFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz shpFail
;
    mov ds,esi
    call fword ptr ds:hei_set_pos_proc
    jmp shpDone

shpFail:
    stc

shpDone:
    pop esi
    pop ebx
    pop ds
    ret
SetHandlePosObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleSizeObj
;
;           DESCRIPTION:    Get handle size
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDX:EAX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHandleSizeObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae ghsFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghsFail
;
    mov ds,esi
    call fword ptr ds:hei_get_size_proc
    jmp ghsDone

ghsFail:
    xor eax,eax
    xor edx,edx
    stc

ghsDone:
    pop esi
    pop ebx
    pop ds
    ret
GetHandleSizeObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleSizeObj
;
;           DESCRIPTION:    Set handle size
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetHandleSizeObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae shsFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz shsFail
;
    mov ds,esi
    call fword ptr ds:hei_set_size_proc
    jmp shsDone

shsFail:
    stc

shsDone:
    pop esi
    pop ebx
    pop ds
    ret
SetHandleSizeObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleCreateObj
;
;           DESCRIPTION:    Get handle create time
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDX:EAX     Tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHandleCreateObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae ghctFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghctFail
;
    mov ds,esi
    call fword ptr ds:hei_get_create_time_proc
    jmp ghctDone

ghctFail:
    GetTime
    stc

ghctDone:
    pop esi
    pop ebx
    pop ds
    ret
GetHandleCreateObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleModifyObj
;
;           DESCRIPTION:    Get handle modify time
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDX:EAX     Tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHandleModifyObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae ghmtFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghmtFail
;
    mov ds,esi
    call fword ptr ds:hei_get_modify_time_proc
    jmp ghmtDone

ghmtFail:
    GetTime
    stc

ghmtDone:
    pop esi
    pop ebx
    pop ds
    ret
GetHandleModifyObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleAccessObj
;
;           DESCRIPTION:    Get handle access time
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDX:EAX     Tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHandleAccessObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae ghatFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghatFail
;
    mov ds,esi
    call fword ptr ds:hei_get_access_time_proc
    jmp ghatDone

ghatFail:
    GetTime
    stc

ghatDone:
    pop esi
    pop ebx
    pop ds
    ret
GetHandleAccessObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleModifyObj
;
;           DESCRIPTION:    Set handle modify time
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     Tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetHandleModifyObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae shmtFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz shmtFail
;
    mov ds,esi
    call fword ptr ds:hei_set_modify_time_proc
    jmp shmtDone

shmtFail:
    stc

shmtDone:
    pop esi
    pop ebx
    pop ds
    ret
SetHandleModifyObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EofHandleObj
;
;           DESCRIPTION:    Eof 
;
;           PARAMETERS:     BX          Handle

;           RETURNS:        EAX         Eof status (0 = not eof, 1 = eof)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EofHandleObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae eohFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz eohFail
;
    mov ds,esi
    call fword ptr ds:hei_is_eof_proc
    jmp eohDone

eohFail:
    stc

eohDone:
    pop esi
    pop ebx
    pop ds
    ret
EofHandleObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsHandleDeviceObj
;
;           DESCRIPTION:    Is handle device?
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        NC          Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsHandleDeviceObj     Proc near
    push ds
    push ebx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae ihdFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ihdFail
;
    mov ds,esi
    call fword ptr ds:hei_is_device_proc
    jmp ihdDone

ihdFail:
    stc

ihdDone:
    pop esi
    pop ebx
    pop ds
    ret
IsHandleDeviceObj     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitSysHandle
;
;           DESCRIPTION:    Init sys object
;
;           PARAMETERS:     ES         Sys interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sys_handle_name  DB 'Init Sys Handle', 0

init_sys_handle_pr     Proc far
    call InitSysObj
    ret
init_sys_handle_pr     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitHandle
;
;           DESCRIPTION:    Init handle object
;
;           PARAMETERS:     ES         Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_handle_name  DB 'Init Handle', 0

init_handle     Proc far
    call InitHandleObj
    ret
init_handle     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateSysHandle
;
;           DESCRIPTION:    Allocate sys file handle
;
;           PARAMETERS:     DS          Sys interface
;
;           RETURNS:        EBX         Sys handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_sys_handle_name  DB 'Allocate Sys Handle', 0

allocate_sys_handle     Proc far
    call AllocateLocalSysHandle
    ret
allocate_sys_handle     Endp

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

open_handle16    PROC far
    push edi
    movzx edi,di
    call OpenHandleObj
    pop edi
    ret
open_handle16    ENDP

open_handle32    PROC far
    call OpenHandleObj
    ret
open_handle32    ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseHandle
;
;           DESCRIPTION:    Close handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_handle_name  DB 'Close Handle', 0

close_handle     Proc far
    call CloseHandleObj
    ret
close_handle     Endp

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
    call DupHandleObj
    ret
dup_handle     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleMap
;
;           DESCRIPTION:    Get handle map
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDI         Flat address of file info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_map_name  DB 'Get Handle Map', 0

get_handle_map   Proc far
    call GetHandleMapObj
    ret
get_handle_map    ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapHandle
;
;           DESCRIPTION:    Map handle
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     File position
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_handle_name  DB 'Map Handle', 0

map_handle   Proc far
    call MapHandleObj
    ret
map_handle    ENDP

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
    call UpdateHandleMapObj
    ret
update_handle    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GrowHandle
;
;           DESCRIPTION:    Grow handle
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     File position
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

grow_handle_name  DB 'Grow Handle', 0

grow_handle     Proc far
    call GrowHandleMapObj
    ret
grow_handle    ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadHandle
;
;           DESCRIPTION:    Read handle
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_handle_name  DB 'Read Handle', 0

read_handle16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call ReadHandleObj
;
    pop edi
    pop ecx
    ret
read_handle16    ENDP

read_handle32    PROC far
    call ReadHandleObj
    ret
read_handle32    ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteHandle
;
;           DESCRIPTION:    Write handle
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_handle_name  DB 'Write Handle', 0

write_handle16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call WriteHandleObj
;
    pop edi
    pop ecx
    ret
write_handle16    ENDP

write_handle32    PROC far
    call WriteHandleObj
    ret
write_handle32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PollHandle
;
;           DESCRIPTION:    Poll handle
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        EAX         Read count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

poll_handle_name  DB 'Poll C Handle', 0

poll_handle16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call PollHandleObj
;
    pop edi
    pop ecx
    ret
poll_handle16    ENDP

poll_handle32    PROC far
    call PollHandleObj
    ret
poll_handle32    ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandlePos
;
;           DESCRIPTION:    Get handle pos
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        (EDX:)EAX   Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_pos32_name  DB 'Get Handle Pos 32', 0
get_handle_pos64_name  DB 'Get Handle Pos 64', 0

get_handle_pos32     Proc far
    push edx
;
    call GetHandlePosObj
    jc ghpFail32
;
    or edx,edx
    jnz ghpFail32
;
    clc
    jmp ghpDone32

ghpFail32:
    stc

ghpDone32:
    pop edx
    ret
get_handle_pos32     Endp        

get_handle_pos64     Proc far
    call GetHandlePosObj
    ret
get_handle_pos64     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandlePos
;
;           DESCRIPTION:    Set handle pos
;
;           PARAMETERS:     BX          Handle
;                           (EDX:)EAX   Position
;
;           RETURNS:        (EDX:)EAX   Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_pos32_name  DB 'Set Handle Pos 32', 0
set_handle_pos64_name  DB 'Set Handle Pos 64', 0

set_handle_pos32     Proc far
    push edx
;
    xor edx,edx
    call SetHandlePosObj
    jnc shpDone32

shpFail32:
    call GetHandlePosObj    
    jc shpZero32
;
    stc
    jmp shpDone32

shpZero32:
    xor eax,eax
    stc

shpDone32:
    pop edx
    ret
set_handle_pos32     Endp        

set_handle_pos64     Proc far
    call SetHandlePosObj
    jnc shpDone64
;
    call GetHandlePosObj
    jc shpZero64
;
    stc
    jmp shpDone64

shpZero64:
    xor eax,eax
    xor edx,edx
    stc

shpDone64:
    ret
set_handle_pos64     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleSize
;
;           DESCRIPTION:    Get handle size
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        (EDX:)EAX   Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_size32_name  DB 'Get C Handle Size 32', 0
get_handle_size64_name  DB 'Get C Handle Size 64', 0

get_handle_size32     Proc far
    push edx
;
    call GetHandleSizeObj
    jc ghsFail32
;
    or edx,edx
    jnz ghsFail32
;
    clc
    jmp ghsDone32

ghsFail32:
    stc

ghsDone32:
    pop edx
    ret
get_handle_size32     Endp        

get_handle_size64     Proc far
    call GetHandleSizeObj
    ret
get_handle_size64     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleSize
;
;           DESCRIPTION:    Set handle size
;
;           PARAMETERS:     BX          Handle
;                           (EDX:)EAX   Position
;
;           RETURNS:        (EDX:)EAX   Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_size32_name  DB 'Set Handle Size 32', 0
set_handle_size64_name  DB 'Set Handle Size 64', 0

set_handle_size32     Proc far
    push edx
;
    or edx,edx
    jnz shsFail32
;
    call SetHandleSizeObj
    jnc shsDone32

shsFail32:
    call GetHandleSizeObj    
    jc shsZero32
;
    stc
    jmp shsDone32

shsZero32:
    xor eax,eax
    stc

shsDone32:
    pop edx
    ret
set_handle_size32     Endp        

set_handle_size64     Proc far
    call SetHandleSizeObj
    jnc shsDone64
;
    call GetHandleSizeObj
    jc shsZero64
;
    stc
    jmp shsDone64

shsZero64:
    xor eax,eax
    xor edx,edx
    stc

shsDone64:
    ret
set_handle_size64     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetHandleCreateTime
;                           GetHandleModifyTime
;                           GetHandleAccessTime
;
;           DESCRIPTION:    Get handle time
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EDX:EAX     Time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_handle_create_time_name  DB 'Get Handle Create Time', 0
get_handle_modify_time_name  DB 'Get Handle Modify Time', 0
get_handle_access_time_name  DB 'Get Handle Access Time', 0

get_handle_create_time     Proc far
    call GetHandleCreateObj
    ret
get_handle_create_time     Endp        

get_handle_modify_time     Proc far
    call GetHandleModifyObj
    ret
get_handle_modify_time     Endp        

get_handle_access_time     Proc far
    call GetHandleAccessObj
    ret
get_handle_access_time     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetHandleModifyTime
;
;           DESCRIPTION:    Set handle time
;
;           PARAMETERS:     BX          Handle
;                           EDX:EAX     Time
;
;           RETURNS:        EAX         Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_handle_modify_time_name  DB 'Set Handle Modify Time', 0

set_handle_modify_time     Proc far
    call SetHandleModifyObj
    ret
set_handle_modify_time     Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EofHandle
;
;           DESCRIPTION:    Eof for handle
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        EAX         Eof status (-1 = error, 0 = not eof, 1 = eof)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

eof_handle_name  DB 'Eof Handle', 0

eof_handle     Proc far
    call EofHandleObj
    jnc eofDone
;
    mov eax,1
    stc

eofDone:
    ret
eof_handle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsDevice
;
;           DESCRIPTION:    Is handle device?
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        NC          Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_handle_device_name  DB 'Is Handle Device?', 0

is_handle_device     Proc far
    call IsHandleDeviceObj
    ret
is_handle_device  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateKernelObj
;
;           DESCRIPTION:    Create kernel object
;
;           PARAMETERS:     DS         Sys interface
;                           EAX        Size of object
;                           EDX        Linear address of object        
;                           
;           RETURNS:        AX         Kernel interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateKernelObj

crk_fail    Proc far
    stc
    ret
crk_fail    Endp

delk_proc_fail    Proc far
    stc
    ret
delk_proc_fail    Endp

CreateKernelObj    Proc near
    push es
    push ebx
    push ecx
;
    AllocateGdt
;
    mov ecx,eax
    CreateDataSelector32
    mov es,ebx
;
    mov es:hki_read_proc,OFFSET crk_fail
    mov es:hki_read_proc+4,cs
;
    mov es:hki_write_proc,OFFSET crk_fail
    mov es:hki_write_proc+4,cs
;
    mov es:hki_delete_proc,OFFSET delk_proc_fail
    mov es:hki_delete_proc+4,cs
;
    mov es:hki_ref_count,0
    mov es:hki_sys_sel,ds
;
    mov eax,ds:hsi_index
    mov es:hki_sys_index,eax
;
    mov eax,es
;
    pop ecx
    pop ebx
    pop es
    ret
CreateKernelObj   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateKernelHandle
;
;           DESCRIPTION:    Create kernel handle
;
;           PARAMETERS:     DS         Sys interface
;                           EAX        Size of object
;                           EDX        Linear address of object        
;                           
;           RETURNS:        AX         Kernel interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_kernel_handle_name  DB 'Create Kernel Handle', 0

create_kernel_handle     Proc far
    call CreateKernelObj
    ret
create_kernel_handle     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenKernelHandle
;
;           DESCRIPTION:    Open kernel handle
;
;           PARAMETERS:     ES:EDI    Filename
;                           CX        Mode
;
;           RETURNS:        BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_kernel_handle_name DB 'Open Kernel Handle', 0

open_kernel_handle Proc far
    push ds
    push es
    push eax
;  
    call OpenVfsFile
    jnc okhOpen
;
    OpenLegacyHandle
    jc okhFail

okhOpen:
    EnterSection ds:hsi_section
    mov ax,ds:hsi_kernel_sel
    or ax,ax
    jnz okhKernOk
;
    inc ds:hsi_ref_count
    call fword ptr ds:hsi_create_kernel_proc
    mov ds:hsi_kernel_sel,ax

okhKernOk:
    mov es,eax
    inc es:hki_ref_count
    LeaveSection ds:hsi_section
;
    mov ebx,es:hki_sys_index
    clc
    jmp okhDone

okhFail:
    xor ebx,ebx
    stc

okhDone:
    pop eax
    pop es
    pop ds
    ret
open_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseKernelHandle
;
;           DESCRIPTION:    Close kernel handle
;
;           PARAMETERS:     BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_kernel_handle_name DB 'Close Kernel Handle', 0

close_kernel_handle Proc far
    push ds
    push es
    pushad
;
    mov eax,SEG data
    mov es,eax
;
    movzx ebx,bx
    cmp ebx,SYS_HANDLE_COUNT
    ja ckhFail
;
    sub ebx,1
    jc ckhFail
;
    mov ax,es:[2*ebx].hd_sys_arr
    or ax,ax
    jz ckhFail
;
    mov ds,eax
    mov ebp,eax
    EnterSection ds:hsi_section
;
    mov ax,ds:hsi_kernel_sel
    or ax,ax
    jz ckhLeaveFail
;
    mov ds,eax
    sub ds:hki_ref_count,1
    jz ckhFree
;
    mov ds,ebp
    jmp ckhLeaveOk

ckhFree:
    mov ds,ebp
    xor ax,ax
    xchg ax,ds:hsi_kernel_sel
    mov ds,eax
    mov es,eax
    call fword ptr ds:hki_delete_proc
;
    mov ds,ebp
    FreeMem
;
    sub ds:hsi_ref_count,1
    jnz ckhLeaveOk
;
    mov eax,SEG data
    mov es,eax
;
    mov edx,ds
    xor ax,ax
    xchg ax,es:[2*ebx].hd_sys_arr
    cmp ax,dx
    je ckhSysOk
;
    int 3

ckhSysOk:
    btc es:hd_sys_bitmap,ebx
    jc ckhSysBitOk
;
    int 3

ckhSysBitOk:
    LeaveSection ds:hsi_section
    call fword ptr ds:hsi_delete_proc
    clc
    jmp ckhDone

ckhLeaveFail:
    LeaveSection ds:hsi_section

ckhFail:
    stc
    jmp ckhDone

ckhLeaveOk:
    LeaveSection ds:hsi_section
    clc

ckhDone:
    popad
    pop es
    pop ds
    ret
close_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadKernelHandle
;
;           DESCRIPTION:    Read with kernel handle
;
;           PARAMETERS:     BX        Handle
;                           EDX:EAX   Position
;                           ES:EDI    Buffer
;                           ECX       Size
;
;           RETURNS:        ECX       Read size
;                           EDX:EAX   New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_kernel_handle_name DB 'Read Kernel Handle', 0

read_kernel_handle Proc far
    push ds
    push ebx
    push esi
;
    mov esi,SEG data
    mov ds,esi
;
    movzx ebx,bx
    cmp ebx,SYS_HANDLE_COUNT
    ja rkhFail
;
    sub ebx,1
    jc rkhFail
;
    mov si,ds:[2*ebx].hd_sys_arr
    or si,si
    jz rkhFail
;
    mov ds,esi
    mov si,ds:hsi_kernel_sel
    or si,si
    jz rkhFail
;
    mov ds,esi
    call fword ptr ds:hki_read_proc
    jnc rkhDone

rkhFail:
    xor ecx,ecx
    stc

rkhDone:
    pop esi
    pop ebx
    pop ds
    ret
read_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteKernelHandle
;
;           DESCRIPTION:    Write with kernel handle
;
;           PARAMETERS:     BX        Handle
;                           EDX:EAX   Position
;                           ES:EDI    Buffer
;                           ECX       Size
;
;           RETURNS:        ECX       Read size
;                           EDX:EAX   New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_kernel_handle_name DB 'Write Kernel Handle', 0

write_kernel_handle Proc far
    push ds
    push ebx
    push esi
;
    mov esi,SEG data
    mov ds,esi
;
    movzx ebx,bx
    cmp ebx,SYS_HANDLE_COUNT
    ja wkhFail
;
    sub ebx,1
    jc wkhFail
;
    mov si,ds:[2*ebx].hd_sys_arr
    or si,si
    jz wkhFail
;
    mov ds,esi
    mov si,ds:hsi_kernel_sel
    or si,si
    jz wkhFail
;
    mov ds,esi
    call fword ptr ds:hki_write_proc
    jnc wkhDone

wkhFail:
    xor ecx,ecx
    stc

wkhDone:
    pop ebp
    pop ebx
    pop ds
    ret
write_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenLegacyFile
;
;           DESCRIPTION:    Open legacy file
;
;           PARAMETERS:     ES:(E)DI    File name
;                           
;           RETURNS:        BX          File handle
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_legacy_file_name  DB 'Open Legacy File',0

open_legacy_file32  Proc far
    push ecx
;
    mov cx,O_RDWR
    call OpenHandleObj
;
    pop ecx
    ret
open_legacy_file32  Endp

open_legacy_file16     PROC far
    push ecx
    push edi
;
    movzx edi,di
    mov cx,O_RDWR
    call OpenHandleObj
;
    pop edi
    pop ecx
    ret
open_legacy_file16     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateLegacyFile
;
;           DESCRIPTION:    Create legacy file
;
;           PARAMETERS:     ES:(E)DI        File name
;
;           RETURNS:        BX              File handle
;                           NC              Success
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_legacy_file_name    DB 'Create Legacy File',0

create_legacy_file32  Proc far
    push ecx
;
    mov cx,O_RDWR OR O_CREAT
    call OpenHandleObj
;
    pop ecx
    ret
create_legacy_file32  Endp

create_legacy_file16   PROC far
    push ecx
    push edi
;
    movzx edi,di
    mov cx,O_RDWR OR O_CREAT
    call OpenHandleObj
;
    pop edi
    pop ecx
    ret
create_legacy_file16   ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseLegacyFile
;
;           DESCRIPTION:    Close legacy file
;
;           PARAMETERS:     BX              File handle
;                           NC              Success
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_legacy_file_name DB 'Close Legacy File',0

close_legacy_file   Proc far
    call CloseHandleObj
    ret
close_legacy_file   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DuplLegacyFile
;
;           DESCRIPTION:    Duplicate legacy file handle
;
;           PARAMETERS:     AX              Old file handle
;
;           RETURNS:        BX              New file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dupl_legacy_file_name  DB 'Dupl Legacy File',0

dupl_legacy_file  Proc far
    mov ebx,eax
    DupHandle
    ret
dupl_legacy_file  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetLegacyFileSize
;
;           DESCRIPTION:    Get legacy file size
;
;           PARAMETERS:     BX              File handle
;                   
;           RETURNS:        (EDX:)EAX       Size of file
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_legacy_file_size32_name      DB 'Get Legacy File Size 32',0
get_legacy_file_size64_name      DB 'Get Legacy File Size 64',0

get_legacy_file_size32   Proc far
    push edx
;
    call GetHandleSizeObj
    jc glhsFail32
;
    or edx,edx
    jnz glhsFail32
;
    clc
    jmp glhsDone32

glhsFail32:
    stc

glhsDone32:
    pop edx
    ret
get_legacy_file_size32   Endp

get_legacy_file_size64   Proc far
    call GetHandleSizeObj
    ret
get_legacy_file_size64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetLegacyFileSize
;
;           DESCRIPTION:    Set legacy file size
;
;           PARAMETERS:     BX              File handle
;                           (EDX:)EAX       Size of file
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_legacy_file_size32_name      DB 'Set Legacy File Size 32',0
set_legacy_file_size64_name      DB 'Set Legacy File Size 64',0

set_legacy_file_size32   Proc far
    push edx
;
    or edx,edx
    jnz slhsFail32
;
    call SetHandleSizeObj
    jnc slhsDone32

slhsFail32:
    call GetHandleSizeObj    
    jc slhsZero32
;
    stc
    jmp slhsDone32

slhsZero32:
    xor eax,eax
    stc

slhsDone32:
    pop edx
    ret
set_legacy_file_size32   Endp

set_legacy_file_size64   Proc far
    call SetHandleSizeObj
    jnc slhsDone64
;
    call GetHandleSizeObj
    jc slhsZero64
;
    stc
    jmp slhsDone64

slhsZero64:
    xor eax,eax
    xor edx,edx
    stc

slhsDone64:
    ret
set_legacy_file_size64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetLegacyFilePos
;
;           DESCRIPTION:    Get legacy file position
;
;           PARAMETERS:     BX              File handle
;               
;           RETURNS:        (EDX:)EAX       File position
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_legacy_file_pos32_name       DB 'Get Legacy File Position 32',0
get_legacy_file_pos64_name       DB 'Get Legacy File Position 64',0

get_legacy_file_pos32   Proc far
    push edx
;
    call GetHandlePosObj
    jc glhpFail32
;
    or edx,edx
    jnz glhpFail32
;
    clc
    jmp glhpDone32

glhpFail32:
    stc

glhpDone32:
    pop edx
    ret
get_legacy_file_pos32   Endp

get_legacy_file_pos64   Proc far
    call GetHandlePosObj
    ret
get_legacy_file_pos64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetLegacyFilePos
;
;           DESCRIPTION:    Set legacy file position
;
;           PARAMETERS:     BX              File handle
;                           (EDX:)EAX       File position
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_legacy_file_pos32_name       DB 'Set Legacy File Position 32',0
set_legacy_file_pos64_name       DB 'Set Legacy File Position 64',0


set_legacy_file_pos32   Proc far
    push edx
;
    xor edx,edx
    call SetHandlePosObj
    jnc slhpDone32

slhpFail32:
    call GetHandlePosObj    
    jc slhpZero32
;
    stc
    jmp slhpDone32

slhpZero32:
    xor eax,eax
    stc

slhpDone32:
    pop edx
    ret
set_legacy_file_pos32   Endp

set_legacy_file_pos64   Proc far
    call SetHandlePosObj
    jnc slhpDone64
;
    call GetHandlePosObj
    jc slhpZero64
;
    stc
    jmp slhpDone64

slhpZero64:
    xor eax,eax
    xor edx,edx
    stc

slhpDone64:
    ret
set_legacy_file_pos64   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetLegacyFileTime
;
;           DESCRIPTION:    Get legacy file time & date
;
;           PARAMETERS:     BX              File handle
;               
;           RETURNS:        EDX:EAX         File time & date
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_legacy_file_time_name      DB 'Get Legacy File Time',0

get_legacy_file_time   Proc far
    call GetHandleModifyObj
    ret
get_legacy_file_time   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetLegacyFileTime
;
;           DESCRIPTION:    Set legacy file time & date
;
;           PARAMETERS:     BX              File handle
;                           EDX:EAX         Time & date
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_legacy_file_time_name      DB 'Set Legacy File Time',0

set_legacy_file_time   Proc far
    call SetHandleModifyObj
    ret
set_legacy_file_time   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadLegacyFile
;
;           DESCRIPTION:    Read legacy file
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        (E)AX       Bytes read
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_legacy_file_name  DB 'Read Legacy File',0

read_legacy_file32   Proc far
    call ReadHandleObj
    ret
read_legacy_file32   Endp

read_legacy_file16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call ReadHandleObj
;
    pop edi
    pop ecx
    ret
read_legacy_file16   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteLegacyFile
;
;           DESCRIPTION:    Write legacy file
;
;           PARAMETERS:     BX          Handle
;                           ES:(E)DI    Buffer
;                           (E)CX       Size
;
;           RETURNS:        (E)AX       Bytes written
;                           NC          Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_legacy_file_name DB 'Write Legacy File',0

write_legacy_file32   Proc far
    call WriteHandleObj
    ret
write_legacy_file32   Endp

write_legacy_file16   Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call WriteHandleObj
;
    pop edi
    pop ecx
    ret
write_legacy_file16   Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateKernelHandle
;
;           DESCRIPTION:    Allocate kernel handle
;
;           PARAMETERS:     DS          Kernel handle interface
;
;           RETURNS:        EBX         Kernel handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateKernelHandle     Proc near
    push es
    push eax
    push ecx
    push edx
    push edi
;
    mov eax,SEG data
    mov es,eax
;
    mov ecx,KERNEL_BITMAP_COUNT  
    xor edi,edi
    mov bx,OFFSET kh_bitmap

alkhLoop:
    mov eax,es:[bx]
    not eax
    bsf edx,eax
    jnz alkhOk
;
    add bx,4
    add edi,32
;
    loop alkhLoop
;
    stc
    jmp alkhDone

alkhOk:
    add edx,edi
    lock bts es:kh_bitmap,edx
    jc alkhLoop
;
    mov ebx,edx
    mov es:[2*ebx].kh_arr,ds
    inc ebx
    clc

alkhDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
AllocateKernelHandle  Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenKernelHandle
;
;           DESCRIPTION:    Open kernel handle
;
;           PARAMETERS:     ES:EDI    Filename
;                           CX        Mode
;
;           RETURNS:        BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_new_kernel_handle_name DB 'Open Kernel Handle', 0

open_new_kernel_handle Proc far
    push ds
    push es
    push eax
;  
    call OpenKernelVfsFile
    jnc onkhOpen
;
    int 3
    OpenLegacyKernelHandle
    jc onkhFail

onkhOpen:
    call AllocateKernelHandle
    jmp onkhDone

onkhFail:
    xor ebx,ebx
    stc

onkhDone:
    pop eax
    pop es
    pop ds
    ret
open_new_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseKernelHandle
;
;           DESCRIPTION:    Close kernel handle
;
;           PARAMETERS:     BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_new_kernel_handle_name DB 'Close Kernel Handle', 0

close_new_kernel_handle Proc far
    push ds
    push es
    pushad
;
    mov eax,SEG data
    mov es,eax
;
    movzx ebx,bx
    cmp ebx,SYS_HANDLE_COUNT
    ja cnkhFail
;
    sub ebx,1
    jc cnkhFail
;
    mov ax,es:[2*ebx].hd_sys_arr
    or ax,ax
    jz cnkhFail
;
    mov ds,eax
    mov ebp,eax
    EnterSection ds:hsi_section
;
    mov ax,ds:hsi_kernel_sel
    or ax,ax
    jz cnkhLeaveFail
;
    mov ds,eax
    sub ds:hki_ref_count,1
    jz cnkhFree
;
    mov ds,ebp
    jmp cnkhLeaveOk

cnkhFree:
    mov ds,ebp
    xor ax,ax
    xchg ax,ds:hsi_kernel_sel
    mov ds,eax
    mov es,eax
    call fword ptr ds:hki_delete_proc
;
    mov ds,ebp
    FreeMem
;
    sub ds:hsi_ref_count,1
    jnz cnkhLeaveOk
;
    mov eax,SEG data
    mov es,eax
;
    mov edx,ds
    xor ax,ax
    xchg ax,es:[2*ebx].hd_sys_arr
    cmp ax,dx
    je cnkhSysOk
;
    int 3

cnkhSysOk:
    btc es:hd_sys_bitmap,ebx
    jc cnkhSysBitOk
;
    int 3

cnkhSysBitOk:
    LeaveSection ds:hsi_section
    call fword ptr ds:hsi_delete_proc
    clc
    jmp cnkhDone

cnkhLeaveFail:
    LeaveSection ds:hsi_section

cnkhFail:
    stc
    jmp cnkhDone

cnkhLeaveOk:
    LeaveSection ds:hsi_section
    clc

cnkhDone:
    popad
    pop es
    pop ds
    ret
close_new_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadKernelHandle
;
;           DESCRIPTION:    Read with kernel handle
;
;           PARAMETERS:     BX        Handle
;                           EDX:EAX   Position
;                           ES:EDI    Buffer
;                           ECX       Size
;
;           RETURNS:        ECX       Read size
;                           EDX:EAX   New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_new_kernel_handle_name DB 'Read Kernel Handle', 0

read_new_kernel_handle Proc far
    push ds
    push ebx
    push esi
;
    mov esi,SEG data
    mov ds,esi
;
    movzx ebx,bx
    cmp ebx,KERNEL_HANDLE_COUNT
    ja rnkhFail
;
    sub ebx,1
    jc rnkhFail
;
    mov si,ds:[2*ebx].kh_arr
    or si,si
    jz rnkhFail
;
    mov ds,esi
    call fword ptr ds:hki_read_proc
    jnc rnkhDone

rnkhFail:
    xor ecx,ecx
    stc

rnkhDone:
    pop esi
    pop ebx
    pop ds
    ret
read_new_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteKernelHandle
;
;           DESCRIPTION:    Write with kernel handle
;
;           PARAMETERS:     BX        Handle
;                           EDX:EAX   Position
;                           ES:EDI    Buffer
;                           ECX       Size
;
;           RETURNS:        ECX       Read size
;                           EDX:EAX   New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_new_kernel_handle_name DB 'Write Kernel Handle', 0

write_new_kernel_handle Proc far
    push ds
    push ebx
    push esi
;
    mov esi,SEG data
    mov ds,esi
;
    movzx ebx,bx
    cmp ebx,KERNEL_HANDLE_COUNT
    ja wnkhFail
;
    sub ebx,1
    jc wnkhFail
;
    mov si,ds:[2*ebx].kh_arr
    or si,si
    jz wnkhFail
;
    mov ds,esi
    call fword ptr ds:hki_write_proc
    jnc wnkhDone

wnkhFail:
    xor ecx,ecx
    stc

wnkhDone:
    pop ebp
    pop ebx
    pop ds
    ret
write_new_kernel_handle Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Test gate
;
;       DESCRIPTION:    Test
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_gate_name DB 'Test', 0
test_file      DB 'c:/rdos.bin', 0

test_gate    Proc far
    push ds
    push es
    push ecx
    push edi
;
    mov ecx,cs
    mov es,ecx
    mov edi,OFFSET test_file
    mov cx,O_RDWR
    OpenNewKernelHandle
    jc tgDone
;
    mov eax,1024
    AllocateSmallGlobalMem
    xor edi,edi
;
    xor edx,edx
    xor eax,eax
    mov ecx,25
    ReadNewKernelHandle
;
    mov eax,15667
    mov ecx,25
    ReadNewKernelHandle
;
    mov eax,98877
    mov ecx,25
    ReadNewKernelHandle
;
    mov eax,5546
    mov ecx,25
    ReadNewKernelHandle
;
    mov ecx,123
    CloseNewKernelHandle

tgDone:
    pop edi
    pop ecx
    pop es
    pop ds
    ret
test_gate    Endp

       
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
    mov edi,OFFSET kh_bitmap
    xor eax,eax
    mov ecx,KERNEL_BITMAP_COUNT
    rep stosd
;
    mov edi,OFFSET kh_arr
    xor ax,ax
    mov ecx,KERNEL_HANDLE_COUNT
    rep stosw
;
    InitSection es:hd_section
    InitSection es:kh_section
    mov es:hd_sys_bitmap,3
    mov es:hd_proc_count,0
    mov es:hd_input_sel,0
    mov es:hd_output_sel,0
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
    mov esi,OFFSET init_handle
    mov edi,OFFSET init_handle_name
    xor cl,cl
    mov ax,init_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET init_sys_handle_pr
    mov edi,OFFSET init_sys_handle_name
    xor cl,cl
    mov ax,init_sys_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_sys_handle
    mov edi,OFFSET allocate_sys_handle_name
    xor cl,cl
    mov ax,allocate_sys_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET create_kernel_handle
    mov edi,OFFSET create_kernel_handle_name
    xor cl,cl
    mov ax,create_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET open_kernel_handle
    mov edi,OFFSET open_kernel_handle_name
    xor cl,cl
    mov ax,open_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET close_kernel_handle
    mov edi,OFFSET close_kernel_handle_name
    xor cl,cl
    mov ax,close_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET read_kernel_handle
    mov edi,OFFSET read_kernel_handle_name
    xor cl,cl
    mov ax,read_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET write_kernel_handle
    mov edi,OFFSET write_kernel_handle_name
    xor cl,cl
    mov ax,write_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET open_new_kernel_handle
    mov edi,OFFSET open_new_kernel_handle_name
    xor cl,cl
    mov ax,open_new_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET close_new_kernel_handle
    mov edi,OFFSET close_new_kernel_handle_name
    xor cl,cl
    mov ax,close_new_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET read_new_kernel_handle
    mov edi,OFFSET read_new_kernel_handle_name
    xor cl,cl
    mov ax,read_new_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET write_new_kernel_handle
    mov edi,OFFSET write_new_kernel_handle_name
    xor cl,cl
    mov ax,write_new_kernel_handle_nr
    RegisterOsGate
;
    mov ebx,OFFSET open_handle16
    mov esi,OFFSET open_handle32
    mov edi,OFFSET open_handle_name
    mov dx,virt_es_in
    mov ax,open_handle_nr
    RegisterUserGate
;
    mov esi,OFFSET close_handle
    mov edi,OFFSET close_handle_name
    xor cl,cl
    mov ax,close_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET dup_handle
    mov edi,OFFSET dup_handle_name
    xor cl,cl
    mov ax,dup_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_map
    mov edi,OFFSET get_handle_map_name
    xor cl,cl
    mov ax,get_handle_map_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET map_handle
    mov edi,OFFSET map_handle_name
    xor cl,cl
    mov ax,map_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET update_handle
    mov edi,OFFSET update_handle_name
    xor cl,cl
    mov ax,update_handle_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET grow_handle
    mov edi,OFFSET grow_handle_name
    xor cl,cl
    mov ax,grow_handle_nr
    RegisterBimodalUserGate
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
    mov ebx,OFFSET poll_handle16
    mov esi,OFFSET poll_handle32
    mov edi,OFFSET poll_handle_name
    mov dx,virt_es_in
    mov ax,poll_handle_nr
    RegisterUserGate
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
    mov esi,OFFSET set_handle_modify_time
    mov edi,OFFSET set_handle_modify_time_name
    xor cl,cl
    mov ax,set_handle_modify_time_nr
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
    mov ebx,OFFSET open_legacy_file16
    mov esi,OFFSET open_legacy_file32
    mov edi,OFFSET open_legacy_file_name
    mov dx,virt_es_in
    mov ax,open_file_nr
    RegisterUserGate
;
    mov ebx,OFFSET create_legacy_file16
    mov esi,OFFSET create_legacy_file32
    mov edi,OFFSET create_legacy_file_name
    mov dx,virt_es_in
    mov ax,create_file_nr
    RegisterUserGate
;
    mov esi,OFFSET close_legacy_file
    mov edi,OFFSET close_legacy_file_name
    xor dx,dx
    mov ax,close_file_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET dupl_legacy_file
    mov edi,OFFSET dupl_legacy_file_name
    xor dx,dx
    mov ax,dupl_file_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_size32
    mov edi,OFFSET get_legacy_file_size32_name
    xor dx,dx
    mov ax,get_file_size32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_size64
    mov edi,OFFSET get_legacy_file_size64_name
    xor dx,dx
    mov ax,get_file_size64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_size32
    mov edi,OFFSET set_legacy_file_size32_name
    xor dx,dx
    mov ax,set_file_size32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_size64
    mov edi,OFFSET set_legacy_file_size64_name
    xor dx,dx
    mov ax,set_file_size64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_pos32
    mov edi,OFFSET get_legacy_file_pos32_name
    xor dx,dx
    mov ax,get_file_pos32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_pos64
    mov edi,OFFSET get_legacy_file_pos64_name
    xor dx,dx
    mov ax,get_file_pos64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_pos32
    mov edi,OFFSET set_legacy_file_pos32_name
    xor dx,dx
    mov ax,set_file_pos32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_pos64
    mov edi,OFFSET set_legacy_file_pos64_name
    xor dx,dx
    mov ax,set_file_pos64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_legacy_file_time
    mov edi,OFFSET get_legacy_file_time_name
    xor dx,dx
    mov ax,get_file_time_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_legacy_file_time
    mov edi,OFFSET set_legacy_file_time_name
    xor dx,dx
    mov ax,set_file_time_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_legacy_file16
    mov esi,OFFSET read_legacy_file32
    mov edi,OFFSET read_legacy_file_name
    mov dx,virt_es_in
    mov ax,read_file_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_legacy_file16
    mov esi,OFFSET write_legacy_file32
    mov edi,OFFSET write_legacy_file_name
    mov dx,virt_es_in
    mov ax,write_file_nr
    RegisterUserGate
;
    mov esi,OFFSET test_gate
    mov edi,OFFSET test_gate_name
    xor dx,dx
    mov ax,test_gate_nr
    RegisterBimodalUserGate
;
    popad
    pop es
    pop ds
    ret
init_sys_handle     ENDP

code    ENDS

    END
