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

data    SEGMENT byte public 'DATA'

hd_section       section_typ <>
hd_proc_count    DW ?

hd_input_sel     DW ?
hd_output_sel    DW ?

hd_proc_arr      DD MAX_PROC_COUNT DUP(?)

kh_section       section_typ <>
kh_bitmap        DD KERNEL_BITMAP_COUNT DUP(?)
kh_arr           DW KERNEL_HANDLE_COUNT DUP(?)

data       ENDS

code    SEGMENT byte public 'CODE'
    
    assume cs:code

    extern OpenUserVfsFile:near
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
    inc es:hui_ref_count
    mov ds:hd_input_sel,es
;
    CreateOutputHandle
    mov es,eax
    inc es:hui_ref_count
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
    lea edi,[edx].ph_sel_arr
    xor ax,ax
    mov ecx,USER_HANDLE_COUNT
    rep stosw
;
    lea edi,[edx].ph_use_arr
    xor ax,ax
    mov ecx,USER_HANDLE_COUNT
    rep stosw
;
    lea edi,[edx].ph_wait_arr
    xor ax,ax
    mov ecx,USER_HANDLE_COUNT
    rep stosw
;
    InitSection es:[edx].ph_section
;    
    mov ax,ds:hd_input_sel
    mov fs,eax
    inc fs:hui_ref_count
    mov es:[edx].ph_sel_arr,fs
;
    mov ax,ds:hd_output_sel
    mov fs,eax
    add fs:hui_ref_count,2
    mov es:[edx].ph_sel_arr+2,fs
    mov es:[edx].ph_sel_arr+4,fs
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
;           NAME:           InitHandleObj
;
;           DESCRIPTION:    Init handle object
;
;           PARAMETERS:     ES         Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitHandleObj

handle_ok      Proc far
    clc
    ret
handle_ok      Endp

handle_fail    Proc far
    stc
    ret
handle_fail    Endp

InitHandleObj  Proc near
    mov es:hui_dup_proc,OFFSET handle_fail
    mov es:hui_dup_proc+4,cs
;
    mov es:hui_delete_proc,OFFSET handle_fail
    mov es:hui_delete_proc+4,cs
;
    mov es:hui_get_map_proc,OFFSET handle_fail
    mov es:hui_get_map_proc+4,cs
;
    mov es:hui_map_proc,OFFSET handle_fail
    mov es:hui_map_proc+4,cs
;
    mov es:hui_update_map_proc,OFFSET handle_fail
    mov es:hui_update_map_proc+4,cs
;
    mov es:hui_grow_map_proc,OFFSET handle_fail
    mov es:hui_grow_map_proc+4,cs
;
    mov es:hui_poll_proc,OFFSET handle_fail
    mov es:hui_poll_proc+4,cs
;
    mov es:hui_read_proc,OFFSET handle_fail
    mov es:hui_read_proc+4,cs
;
    mov es:hui_write_proc,OFFSET handle_fail
    mov es:hui_write_proc+4,cs
;
    mov es:hui_poll_proc,OFFSET handle_fail
    mov es:hui_poll_proc+4,cs
;
    mov es:hui_get_size_proc,OFFSET handle_fail
    mov es:hui_get_size_proc+4,cs
;
    mov es:hui_set_size_proc,OFFSET handle_fail
    mov es:hui_set_size_proc+4,cs
;
    mov es:hui_get_pos_proc,OFFSET handle_fail
    mov es:hui_get_pos_proc+4,cs
;
    mov es:hui_set_pos_proc,OFFSET handle_fail
    mov es:hui_set_pos_proc+4,cs
;
    mov es:hui_get_create_time_proc,OFFSET handle_fail
    mov es:hui_get_create_time_proc+4,cs
;
    mov es:hui_get_modify_time_proc,OFFSET handle_fail
    mov es:hui_get_modify_time_proc+4,cs
;
    mov es:hui_get_access_time_proc,OFFSET handle_fail
    mov es:hui_get_access_time_proc+4,cs
;
    mov es:hui_set_modify_time_proc,OFFSET handle_fail
    mov es:hui_set_modify_time_proc+4,cs
;
    mov es:hui_is_eof_proc,OFFSET handle_fail
    mov es:hui_is_eof_proc+4,cs
;
    mov es:hui_is_device_proc,OFFSET handle_fail
    mov es:hui_is_device_proc+4,cs
;
    mov es:hui_is_ip4_proc,OFFSET handle_fail
    mov es:hui_is_ip4_proc+4,cs
;
    mov es:hui_input_size_proc,OFFSET handle_fail
    mov es:hui_input_size_proc+4,cs
;
    mov es:hui_output_size_proc,OFFSET handle_fail
    mov es:hui_output_size_proc+4,cs
;
    mov es:hui_free_proc,OFFSET handle_fail
    mov es:hui_free_proc+4,cs
;
    mov es:hui_ref_count,0
    ret
InitHandleObj    Endp

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
    mov es:[2*ebx].ph_sel_arr,ds
    inc ds:hui_ref_count
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
;           NAME:           SetUserHandle
;
;           DESCRIPTION:    Set user handle
;
;           PARAMETERS:     DS          Handle interface
;                           EBX         User handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetUserHandle     Proc near
    push ds
    push es
    push eax
;
    mov eax,ds
    mov es,eax
    mov eax,proc_handle_sel
    mov ds,eax
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae suhFail
;
    EnterSectionUseFlags ds:ph_section
    xor ax,ax
    xchg ax,ds:[2*ebx].ph_sel_arr
    or ax,ax
    jnz suhClose
;
    lock bts ds:ph_bitmap,ebx
    jnc suhSet
    jmp suhLeaveFail

suhClose:
    sub ds:[2*ebx].ph_use_arr,1
    jc suhLeaveOk
;
    GetThread
    mov ds:[2*ebx].ph_wait_arr,ax

suhWait:
    LeaveSectionUseFlags ds:ph_section
    WaitForSignal
    EnterSection ds:ph_section
    mov ax,ds:[2*ebx].ph_use_arr
    cmp ax,-1
    jne suhWait

suhLeaveOk:
    add ds:[2*ebx].ph_use_arr,1
;
    mov ds,eax
    sub ds:hui_ref_count,1
    jnz suhTake
;
    call fword ptr ds:hui_free_proc

suhTake:
    mov eax,proc_handle_sel
    mov ds,eax

suhSet:
    inc es:hui_ref_count
;
    mov ds:[2*ebx].ph_sel_arr,es
    LeaveSectionUseFlags ds:ph_section
    clc
    jmp suhDone

suhLeaveFail:
    LeaveSectionUseFlags ds:ph_section

suhFail:
    stc

suhDone:
    pop eax
    pop es
    pop ds
    ret
SetUserHandle  Endp   

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
    call OpenUserVfsFile
    jnc ohInit
;
    OpenLegacyHandle
    jc ohDone

ohInit:
    call AllocateUserHandle
    jc ohDone

ohCheckTrunc:
    test cx,O_CREAT OR O_TRUNC
    jz ohSizeOk
;
    xor eax,eax
    xor edx,edx
    SetHandleSize64

ohSizeOk:
    call OpenToIo
    mov ds:hui_io_mode,ax
    clc

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
    push eax
    push ebx
;
    movzx ebx,bx
    mov eax,proc_handle_sel
    mov ds,eax
;
    cmp ebx,USER_HANDLE_COUNT
    jae chFail
;
    EnterSectionUseFlags ds:ph_section
    xor ax,ax
    xchg ax,ds:[2*ebx].ph_sel_arr
    or ax,ax
    jz chLeaveFail
;
    sub ds:[2*ebx].ph_use_arr,1
    jc chLeaveInc
;
    push eax
    GetThread
    mov ds:[2*ebx].ph_wait_arr,ax
    pop eax

chWait:
    LeaveSectionUseFlags ds:ph_section
    WaitForSignal
    EnterSection ds:ph_section
;
    add ds:[2*ebx].ph_use_arr,1
    jc chLeave
;
    sub ds:[2*ebx].ph_use_arr,1
    jmp chWait

chLeaveInc:
    add ds:[2*ebx].ph_use_arr,1

chLeave:
    mov ds:[2*ebx].ph_wait_arr,0
    LeaveSectionUseFlags ds:ph_section
;
    btc ds:ph_bitmap,ebx
    jnc chFail
;
    mov ds,eax
    sub ds:hui_ref_count,1
    jnz chOk
;
    call fword ptr ds:hui_free_proc
    clc
    jmp chDone

chLeaveFail:
    LeaveSectionUseFlags ds:ph_section

chFail:
    stc

chOk:
    clc

chDone:
    pop ebx
    pop eax
    pop ds
    ret
CloseHandleObj     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DeleteHandleObj
;
;           DESCRIPTION:    Delete handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteHandleObj     Proc near
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
    jae dhoFail
;
    mov si,ds:[2*ebx].ph_sel_arr
    or si,si
    jz dhoFail
;
    mov ds,esi
    call fword ptr ds:hui_delete_proc
    jnc dhoDone

dhoFail:
    xor eax,eax
    xor edi,edi
    stc

dhoDone:
    pop esi
    pop ebx
    pop ds
    ret
DeleteHandleObj     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockInterface
;
;           DESCRIPTION:    Lock interface
;
;           PARAMETERS:     BX          Handle
;
;           RETURNS:        NC          OK
;                             DS        Handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockInterface   Proc near
    push esi
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    movzx ebx,bx
;
    cmp ebx,USER_HANDLE_COUNT
    jae liFail
;
    EnterSectionUseFlags ds:ph_section
    mov si,ds:[2*ebx].ph_sel_arr
    or si,si
    jz liLeaveFail
;
    add ds:[2*ebx].ph_use_arr,1
    LeaveSectionUseFlags ds:ph_section
;    
    mov ds,esi
    clc
    pop esi
    ret

liLeaveFail:
    LeaveSectionUseFlags ds:ph_section

liFail:
    xor esi,esi
    mov ds,esi
    stc
    pop esi
    ret
LockInterface  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockInterface
;
;           DESCRIPTION:    Unlock interface
;
;           PARAMETERS:     EBX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockInterface   Proc near
    push ds
    push esi
    pushfd
;
    mov esi,proc_handle_sel
    mov ds,esi
;
    EnterSectionUseFlags ds:ph_section
    sub ds:[2*ebx].ph_use_arr,1
    jnc uiOk
;
    push ebx
;
    mov bx,ds:[2*ebx].ph_wait_arr
    or bx,bx
    jz uiSigOk
;
    Signal

uiSigOk:
    pop ebx

uiOk:
    LeaveSectionUseFlags ds:ph_section
;
    popfd
    pop esi
    pop ds
    ret
UnlockInterface  Endp
    
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
;
    call LockInterface
    jc dupFail
;
    call fword ptr ds:hui_dup_proc
    call UnlockInterface
    jc dupFail
;
    mov ds,eax
    call AllocateUserHandle
    jnc dupDone

dupFail:
    stc

dupDone:
    pop eax
    pop ds
    ret
DupHandleObj   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Dup2HandleObj
;
;           DESCRIPTION:    Dup2 handle
;
;           PARAMETERS:     BX          Src handle
;                           AX          Dest handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Dup2HandleObj   Proc near
    push ds
    push eax
    push edx
;
    mov edx,eax
;
    call LockInterface
    jc dup2Fail
;
    call fword ptr ds:hui_dup_proc
    call UnlockInterface
    jc dup2Fail
;
    mov ds,eax
    mov ebx,edx
    call SetUserHandle
    jnc dup2Done

dup2Fail:
    stc

dup2Done:
    pop edx
    pop eax
    pop ds
    ret
Dup2HandleObj   Endp
        
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
;
    call LockInterface
    jc ghmDone
;
    test ds:hui_io_mode,IO_READ
    stc
    jz ghmUnlock
;
    call fword ptr ds:hui_get_map_proc

ghmUnlock:
    call UnlockInterface
    jnc ghmDone

ghmFail:
    xor eax,eax
    xor edi,edi
    stc

ghmDone:
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
;
    call LockInterface
    jc mhDone
;
    test ds:hui_io_mode,IO_READ
    stc
    jz mhUnlock
;
    call fword ptr ds:hui_map_proc

mhUnlock:
    call UnlockInterface

mhDone:
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
;
    call LockInterface
    jc uhmDone
;
    call fword ptr ds:hui_update_map_proc
    call UnlockInterface

uhmDone:
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
;
    call LockInterface
    jc ghmoDone
;
    call fword ptr ds:hui_grow_map_proc
    call UnlockInterface

ghmoDone:
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
;
    call LockInterface
    jc rhFail
;
    test ds:hui_io_mode,IO_READ
    stc
    jz rhUnlock
;
    call fword ptr ds:hui_read_proc
    mov eax,ecx

rhUnlock:
    call UnlockInterface
    jnc rhDone

rhFail:
    xor eax,eax
    stc

rhDone:
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
;
    call LockInterface
    jc whFail
;
    test ds:hui_io_mode,IO_WRITE
    stc
    jz whUnlock
;
    call fword ptr ds:hui_write_proc
    mov eax,ecx

whUnlock:
    call UnlockInterface
    jnc whDone

whFail:
    xor eax,eax
    stc

whDone:
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
;
    call LockInterface
    jc phFail
;
    test ds:hui_io_mode,IO_READ
    stc
    jz phUnlock
;
    call fword ptr ds:hui_poll_proc
    mov eax,ecx

phUnlock:
    call UnlockInterface
    jnc phDone

phFail:
    xor eax,eax
    stc

phDone:
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
;
    call LockInterface
    jc ghpFail
;
    call fword ptr ds:hui_get_pos_proc
    call UnlockInterface
    jnc ghpDone

ghpFail:
    xor eax,eax
    xor edx,edx
    stc

ghpDone:
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
;
    call LockInterface
    jc shpDone
;
    call fword ptr ds:hui_set_pos_proc
    call UnlockInterface

shpDone:
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
;
    call LockInterface
    jc ghsFail
;
    call fword ptr ds:hui_get_size_proc
    call UnlockInterface
    jnc ghsDone

ghsFail:
    xor eax,eax
    xor edx,edx
    stc

ghsDone:
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
;
    call LockInterface
    jc shsDone
;
    call fword ptr ds:hui_set_size_proc
    call UnlockInterface

shsDone:
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
;
    call LockInterface
    jc ghctFail
;
    call fword ptr ds:hui_get_create_time_proc
    call UnlockInterface
    jnc ghctDone

ghctFail:
    GetTime
    stc

ghctDone:
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
;
    call LockInterface
    jc ghmtFail
;
    call fword ptr ds:hui_get_modify_time_proc
    call UnlockInterface
    jnc ghmtDone

ghmtFail:
    GetTime
    stc

ghmtDone:
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
;
    call LockInterface
    jc ghatFail
;
    call fword ptr ds:hui_get_access_time_proc
    call UnlockInterface
    jnc ghatDone

ghatFail:
    GetTime
    stc

ghatDone:
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
;
    call LockInterface
    jc shmtDone
;
    call fword ptr ds:hui_set_modify_time_proc
    call UnlockInterface

shmtDone:
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
;
    call LockInterface
    jc eohDone
;
    call fword ptr ds:hui_is_eof_proc
    call UnlockInterface

eohDone:
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
;
    call LockInterface
    jc ihdDone
;
    call fword ptr ds:hui_is_device_proc
    call UnlockInterface

ihdDone:
    pop ds
    ret
IsHandleDeviceObj     Endp        

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
    jnc oh16Done
;
    mov ebx,-1

oh16Done:
    pop edi
    ret
open_handle16    ENDP

open_handle32    PROC far
    call OpenHandleObj
    jnc oh32Done
;
    mov ebx,-1

oh32Done:
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
;           NAME:           DeleteHandle
;
;           DESCRIPTION:    Delete handle
;
;           PARAMETERS:     BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle_name  DB 'Delete Handle', 0

delete_handle     Proc far
    call DeleteHandleObj
    ret
delete_handle     Endp

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
    jnc dhDone
;
    mov ebx,-1

dhDone:
    ret
dup_handle     Endp

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
    call Dup2HandleObj
    jc dh2Failed
;
    movzx ebx,ax
    clc
    jmp dh2Done

dh2Failed:
    mov ebx,-1
    stc

dh2Done:
    ret
dup2_handle    Endp
        
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
;           NAME:           InitKernelObj
;
;           DESCRIPTION:    Init kernel interface
;
;           PARAMETERS:	    ES	Kernel handle interface
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitKernelObj

crk_fail    Proc far
    stc
    ret
crk_fail    Endp

fk_proc_fail    Proc far
    stc
    ret
fk_proc_fail    Endp

InitKernelObj    Proc near
    mov es:hki_read_proc,OFFSET crk_fail
    mov es:hki_read_proc+4,cs
;
    mov es:hki_write_proc,OFFSET crk_fail
    mov es:hki_write_proc+4,cs
;
    mov es:hki_free_proc,OFFSET fk_proc_fail
    mov es:hki_free_proc+4,cs
;
    mov es:hki_ref_count,0
    ret
InitKernelObj   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitKernelHandle
;
;           DESCRIPTION:    Init kernel handle
;
;           PARAMETERS:	    ES	Kernel handle interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_kernel_handle_name  DB 'Create Kernel Handle', 0

init_kernel_handle     Proc far
    call InitKernelObj
    ret
init_kernel_handle     Endp

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
    call OpenKernelVfsFile
    jnc okhOpen
;
    OpenLegacyKernelHandle
    jc okhFail

okhOpen:
    call AllocateKernelHandle
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
    push ebx
    push esi
;
    mov esi,SEG data
    mov ds,esi
;
    movzx ebx,bx
    cmp ebx,KERNEL_HANDLE_COUNT
    ja ckhFail
;
    sub ebx,1
    jc ckhFail
;
    mov si,ds:[2*ebx].kh_arr
    or si,si
    jz ckhFail
;
    mov ds,esi
    call fword ptr ds:hki_free_proc
    jmp ckhDone

ckhFail:
    stc

ckhDone:
    pop esi
    pop ebx
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
    cmp ebx,KERNEL_HANDLE_COUNT
    ja rkhFail
;
    sub ebx,1
    jc rkhFail
;
    mov si,ds:[2*ebx].kh_arr
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
    cmp ebx,KERNEL_HANDLE_COUNT
    ja wkhFail
;
    sub ebx,1
    jc wkhFail
;
    mov si,ds:[2*ebx].kh_arr
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
;       NAME:           Test gate
;
;       DESCRIPTION:    Test
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_gate_name DB 'Test', 0
test_file      DB 'e:/test.bin', 0

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
    OpenKernelHandle
    jc tgDone
;
    mov eax,1024
    AllocateSmallGlobalMem
    xor edi,edi
;
    xor edx,edx
    xor eax,eax
    mov ecx,25
    ReadKernelHandle
;
    mov eax,15667
    mov ecx,25
    ReadKernelHandle
;
    mov eax,98877
    mov ecx,25
    ReadKernelHandle
;
    mov eax,5546
    mov ecx,25
    ReadKernelHandle
;
    mov ecx,123
    CloseKernelHandle

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
    mov esi,OFFSET init_kernel_handle
    mov edi,OFFSET init_kernel_handle_name
    xor cl,cl
    mov ax,init_kernel_handle_nr
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
