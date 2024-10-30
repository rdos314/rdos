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
;           RETURNS:        DS         Sys interface
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
    mov ds:hsi_create_proc_proc,OFFSET cr_proc_fail
    mov ds:hsi_create_proc_proc+4,cs
;
    mov ds:hsi_create_kernel_proc,OFFSET cr_proc_fail
    mov ds:hsi_create_kernel_proc+4,cs
;
    mov ds:hsi_delete_proc,OFFSET del_sys_fail
    mov ds:hsi_delete_proc+4,cs
;
    mov ds:hsi_kernel_sel,0
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

handle_fail    Proc far
    stc
    ret
handle_fail    Endp

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
    mov es:hei_delete_proc,OFFSET handle_fail
    mov es:hei_delete_proc+4,cs
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
    push es
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
    stc

ohDone:
    pop eax
    pop es
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
;           NAME:           CloseHandle
;
;           DESCRIPTION:    Close handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_handle_name  DB 'Close Handle', 0

close_handle     Proc far
    push ds
    push es
    pushad
;
    movzx ebx,bx
    mov eax,proc_handle_sel
    mov ds,eax
;
    cmp ebx,USER_HANDLE_COUNT
    ja chFail
;
    sub ebx,1
    jc chFail
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
    mov es,eax
    call fword ptr ds:hei_delete_proc
;
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
    mov ds,ds:hpi_sys_sel
    FreeMem
;
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

chDone:
    popad
    pop es
    pop ds
    ret
close_handle     Endp
        
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

read_handle     Proc near
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
    ja rhFail
;
    sub ebx,1
    jc rhFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz rhFail
;
    mov ds,esi
    call fword ptr ds:hei_read_proc
    jmp rhDone

rhFail:
    xor eax,eax
    stc

rhDone:
    pop esi
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

write_handle     Proc near
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
    ja whFail
;
    sub ebx,1
    jc whFail
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz whFail
;
    mov ds,esi
    call fword ptr ds:hei_write_proc
    jmp rhDone

whFail:
    xor eax,eax
    stc

whDone:
    pop esi
    pop ebx
    pop ds
    ret
write_handle     Endp

write_handle16   Proc far
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
;           NAME:           GetHandlePos
;
;           DESCRIPTION:    Get handle pos
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
    push edx
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    ja ghpFail32
;
    sub ebx,1
    jc ghpFail32
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghpFail32
;
    mov ds,esi
    call fword ptr ds:hei_get_pos_proc
    jmp ghpDone32

ghpFail32:
    xor eax,eax
    stc

ghpDone32:
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
get_handle_pos32     Endp        

get_handle_pos64     Proc far
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
    ja ghpFail64
;
    sub ebx,1
    jc ghpFail64
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz ghpFail64
;
    mov ds,esi
    call fword ptr ds:hei_get_pos_proc
    jmp ghpDone64

ghpFail64:
    xor eax,eax
    xor edx,edx
    stc

ghpDone64:
    pop esi
    pop ebx
    pop ds
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

set_handle_pos32_name  DB 'Set C Handle Pos 32', 0
set_handle_pos64_name  DB 'Set C Handle Pos 64', 0

set_handle_pos32     Proc far
    push ds
    push ebx
    push edx
    push esi
;
    xor edx,edx
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    ja shpFail32
;
    sub ebx,1
    jc shpFail32
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz shpFail32
;
    mov ds,esi
    call fword ptr ds:hei_set_pos_proc
    call fword ptr ds:hei_get_pos_proc
    jmp shpDone32

shpFail32:
    xor eax,eax
    stc

shpDone32:
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
set_handle_pos32     Endp        

set_handle_pos64     Proc far
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
    ja shpFail64
;
    sub ebx,1
    jc shpFail64
;
    mov si,ds:[2*ebx].ph_arr
    or si,si
    jz shpFail64
;
    mov ds,esi
    call fword ptr ds:hei_set_pos_proc
    call fword ptr ds:hei_get_pos_proc
    jmp shpDone64

shpFail64:
    xor eax,eax
    xor edx,edx
    stc

shpDone64:
    pop esi
    pop ebx
    pop ds
    ret
set_handle_pos64     Endp        

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
    jc okhFail
;
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
    jmp ohDone

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
    mov esi,OFFSET open_kernel_handle
    mov edi,OFFSET open_kernel_handle_name
    xor cl,cl
    mov ax,open_new_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET close_kernel_handle
    mov edi,OFFSET close_kernel_handle_name
    xor cl,cl
    mov ax,close_new_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET read_kernel_handle
    mov edi,OFFSET read_kernel_handle_name
    xor cl,cl
    mov ax,read_new_kernel_handle_nr
    RegisterOsGate
;
    mov esi,OFFSET write_kernel_handle
    mov edi,OFFSET write_kernel_handle_name
    xor cl,cl
    mov ax,write_new_kernel_handle_nr
    RegisterOsGate
;
    mov ebx,OFFSET open_handle16
    mov esi,OFFSET open_handle32
    mov edi,OFFSET open_handle_name
    mov dx,virt_es_in
    mov ax,open_new_handle_nr
    RegisterUserGate
;
    mov esi,OFFSET close_handle
    mov edi,OFFSET close_handle_name
    xor cl,cl
    mov ax,close_new_handle_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET read_handle16
    mov esi,OFFSET read_handle32
    mov edi,OFFSET read_handle_name
    mov dx,virt_es_in
    mov ax,read_new_handle_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_handle16
    mov esi,OFFSET write_handle32
    mov edi,OFFSET write_handle_name
    mov dx,virt_es_in
    mov ax,write_new_handle_nr
    RegisterUserGate
;
    mov esi,OFFSET get_handle_pos32
    mov edi,OFFSET get_handle_pos32_name
    xor cl,cl
    mov ax,get_new_handle_pos32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_handle_pos64
    mov edi,OFFSET get_handle_pos64_name
    xor cl,cl
    mov ax,get_new_handle_pos64_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_pos32
    mov edi,OFFSET set_handle_pos32_name
    xor cl,cl
    mov ax,set_new_handle_pos32_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_handle_pos64
    mov edi,OFFSET set_handle_pos64_name
    xor cl,cl
    mov ax,set_new_handle_pos64_nr
    RegisterBimodalUserGate
;
    popad
    pop es
    pop ds
    ret
init_sys_handle     ENDP

code    ENDS

    END
