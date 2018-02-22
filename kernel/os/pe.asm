;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2000, Leif Ekblad
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
; PE.ASM
; PE (Portable Executable) loader
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE exec.def
INCLUDE pe.def
INCLUDE system.inc
INCLUDE ..\debevent.inc
INCLUDE ..\handle.inc
INCLUDE chandle.inc


SYS_BASE EQU 0DE000000h

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

MAX_SECTIONS EQU 32768

code    SEGMENT byte public 'CODE'
    
    assume cs:code
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyKernelDebug
;
;           DESCRIPTION:    Notify kernel debug event. Called on scheduler locked stack
;
;       PARAMETERS:     ES      Thread sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyKernelDebug   Proc far
    push ds
    push es
    push ax
    push dx
    push di
;    
    movzx dx,es:p_fault_vector
    mov ax,es:p_app_sel
    verr ax
    jnz nkeDone
;    
    mov ds,ax
    mov ax,ds:app_mod_sel
    verr ax
    jnz nkeDone
;
    mov ds,ax
;
    mov ax,es:p_debug_event
    or ax,ax
    jz nkeDone
;
    mov es,ax    
    mov di,SIZE event_struc
    mov es:[di].kexcVector,dx
    xor ax,ax
    xchg ax,ds:lib_suppress
    or ax,ax
    jnz nkeDone
;    
    mov ax,ds:lib_events
    or ax,ax
    je nkeEmpty
;
    push ds
    push si
    mov ds,ax
    mov si,ds:event_prev
    mov ds:event_prev,es
    mov ds,si
    mov ds:event_next,es
    mov es:event_next,ax
    mov es:event_prev,si
    pop si
    pop ds
    jmp nkeInsDone

nkeEmpty:
    mov es:event_next,es
    mov es:event_prev,es

nkeInsDone:
    mov ds:lib_events,es
    xor ax,ax
    mov es,ax
;
    mov ax,ds:lib_debug_wait
    or ax,ax
    jz nkeDone
;       
    mov es,ax
    SignalWait

nkeDone:
    pop di
    pop dx
    pop ax
    pop es
    pop ds
    retf16
NotifyKernelDebug   Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendEvent
;
;           DESCRIPTION:    Sent event to debugger
;
;           PARAMETERS:     DS          Lib
;                           ES          Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendEvent Proc near
    push ds
    push eax
    push bx
    ClearSignal
;
    GetThread
    push es
    mov es,ax
    mov ax,es:p_id
    pop es  
    mov es:event_thread_id,ax
;
    movzx ebx,ds:mod_debug_id
    or bx,bx
    jz seClear
;
    ModuleIdToSel
    jc seClear
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds,ds:app_mod_sel
    RequestSpinlock ds:lib_spinlock
;
    mov ax,ds:lib_events
    or ax,ax
    je seEmpty
;
    push ds
    push si
    mov ds,ax
    mov si,ds:event_prev
    mov ds:event_prev,es
    mov ds,si
    mov ds:event_next,es
    mov es:event_next,ax
    mov es:event_prev,si
    pop si
    pop ds
    jmp seInsDone

seEmpty:
    mov es:event_next,es
    mov es:event_prev,es

seInsDone:
    mov ds:lib_events,es
    xor ax,ax
    mov es,ax
    ReleaseSpinlock ds:lib_spinlock
;
    push es

seSignalLoop:
    mov ax,ds:lib_debug_wait
    or ax,ax
    jnz seSignalDo
;
    mov ax,10
    WaitMilliSec
    jmp seSignalLoop

seClear:
    mov ds:mod_debug_id,0
    jmp seDone

seSignalDo:
    mov es,ax
    SignalWait
    pop es    
    WaitForSignal

seDone:
    pop bx
    pop eax
    pop ds
    ret
SendEvent Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateKernelEvent
;
;           DESCRIPTION:    Pre-allocate kernel event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateKernelEvent   Proc near
    push ds
    push es
    push eax
    push di
;
    mov eax,SIZE kernel_exception_event_struc
    mov di,SIZE event_struc
    add ax,di
    AllocateSmallGlobalMem
    sub ax,di
    mov es:event_size,ax
    mov es:event_code,EVENT_KERNEL
;
    GetThread
    mov ds,ax
    mov ax,ds:p_id
    mov es:event_thread_id,ax
    mov ds:p_debug_event,es
;
    pop di
    pop eax 
    pop es
    pop ds   
    ret
AllocateKernelEvent   Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeKernelEvent
;
;           DESCRIPTION:    Free pre-allocated kernel event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeKernelEvent   Proc near
    push ds
    push es
    push eax
;
    GetThread
    mov ds,ax
    xor ax,ax
    xchg ax,ds:p_debug_event
    mov es,ax
    FreeMem
;
    pop eax 
    pop es
    pop ds   
    ret
FreeKernelEvent   Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ExceptionEvent
;
;           DESCRIPTION:    Exception event
;
;           PARAMETERS:     DS          Lib
;                           EBP         Exception frame
;                           EAX         Exception code
;
;           RETURNS:        ES          Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExceptionEvent Proc near
    push ebp
    mov ebp,[ebp]
    push eax
    push di
;
    push eax
    mov eax,SIZE exception_event_struc
    mov di,SIZE event_struc
    add ax,di
    AllocateSmallGlobalMem
    sub ax,di
    mov es:event_size,ax
    mov es:event_code,EVENT_EXCEPTION
    pop eax
    mov es:[di].excCode,eax
;
    lea eax,[ebp+8]
    mov es:[di].excPtr,eax
;
    push ds
    mov ax,flat_data_sel
    mov ds,ax
    mov eax,ds:[ebp+20]
    pop ds
    mov es:[di].excEip,eax
    mov es:[di].excCs,flat_code_sel
;
    pop di
    pop eax
    pop ebp
    ret
ExceptionEvent Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateProcessEvent
;
;           DESCRIPTION:    Create process debug event
;
;           PARAMETERS:     DS          Lib
;                           FS          TIB
;                           EBP         Stack frame
;
;           RETURNS:        ES          Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateProcessEvent Proc near
    push eax
    push ebx
    push di
;
    mov eax,SIZE create_process_event_struc
    mov di,SIZE event_struc
    add ax,di
    AllocateSmallGlobalMem
    sub ax,di
    mov es:event_size,ax
    mov es:event_code,EVENT_CREATE_PROCESS
;
    movzx ebx,ds:mod_c_file_handle
    mov es:[di].cpeFile,ebx
;       
    movzx ebx,ds:mod_id
    ModuleIdToSel
    mov es:[di].cpeHandle,ebx
;
    mov eax,fs:pvProcessHandle
    mov es:[di].cpeProcess,eax
    mov eax,fs:pvThreadHandle
    mov es:[di].cpeThread,eax       
    mov eax,ds:mod_base
    mov es:[di].cpeImageBase,eax
    mov eax,ds:mod_size
    mov es:[di].cpeImageSize,eax
;
    push es
    mov ax,flat_data_sel
    mov es,ax
    mov eax,ds:lib_objects
    mov eax,es:[eax].o_va
    pop es
    mov es:[di].cpeObjectRva,eax
;       
    mov eax,fs:pvBase
    mov es:[di].cpeFsLinear,eax
    mov es:[di].cpeStartCs,flat_code_sel
    mov eax,ds:lib_org_eip
    mov es:[di].cpeStartEip,eax
;
    pop di
    pop ebx
    pop eax
    ret
CreateProcessEvent Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TerminateProcessEvent
;
;           DESCRIPTION:    Terminate process debug event
;
;           PARAMETERS:         EAX         Exit code
;
;           RETURNS:        ES          Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TerminateProcessEvent Proc near
    push ebx
    push di
;
    push eax
    mov eax,SIZE terminate_process_event_struc
    mov di,SIZE event_struc
    add ax,di
    AllocateSmallGlobalMem
    sub ax,di
    mov es:event_size,ax
    mov es:event_code,EVENT_TERMINATE_PROCESS
    pop eax
;
    mov es:[di].tpeExitCode,eax
;
    pop di
    pop ebx
    ret
TerminateProcessEvent Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateThreadEvent
;
;           DESCRIPTION:    Create thread debug event
;
;           PARAMETERS:     DS          Lib
;                           FS          TIB
;                           EDX         EIP
;
;           RETURNS:        ES          Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateThreadEvent Proc near
    push eax
    push ebx
    push di
;
    mov eax,SIZE create_thread_event_struc
    mov di,SIZE event_struc
    add ax,di
    AllocateSmallGlobalMem
    sub ax,di
    mov es:event_size,ax
    mov es:event_code,EVENT_CREATE_THREAD
;
    mov eax,fs:pvThreadHandle
    mov es:[di].cteThread,eax
    mov eax,fs:pvBase
    mov es:[di].cteFsLinear,eax
    mov es:[di].cteStartEip,edx
    mov es:[di].cteStartCs,flat_code_sel
;
    pop di
    pop ebx
    pop eax
    ret
CreateThreadEvent Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TerminateThreadEvent
;
;           DESCRIPTION:    Terminate thread debug event
;
;           PARAMETERS:     DS          Lib
;                           FS          TIB
;
;           RETURNS:        ES          Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TerminateThreadEvent Proc near
    push eax
    push ebx
;
    mov eax,SIZE event_struc
    AllocateSmallGlobalMem
    mov es:event_size,0
    mov es:event_code,EVENT_TERMINATE_THREAD
;
    pop ebx
    pop eax
    ret
TerminateThreadEvent Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadDllEvent
;
;           DESCRIPTION:    Load Dll debug event
;
;           PARAMETERS:     DS          Lib
;
;           RETURNS:        ES          Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadDllEvent Proc near
    push eax
    push di
;
    mov eax,SIZE load_dll_event_struc
    mov di,SIZE event_struc
    add ax,di
    AllocateSmallGlobalMem
    sub ax,di
    mov es:event_size,ax
    mov es:event_code,EVENT_LOAD_DLL
;
    movzx ebx,ds:mod_c_file_handle
    mov es:[di].ldeFile,ebx
;       
    movzx ebx,ds:mod_id
    ModuleIdToSel
    mov es:[di].ldeHandle,ebx    
;
    mov eax,ds:mod_base
    mov es:[di].ldeImageBase,eax
;
    push es
    mov ax,flat_data_sel
    mov es,ax
    mov eax,ds:lib_objects
    mov eax,es:[eax].o_va
    pop es
    mov es:[di].ldeObjectRva,eax
;       
    mov eax,ds:mod_size
    mov es:[di].ldeImageSize,eax
;
    pop di
    pop eax
    ret
LoadDllEvent    Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeDllEvent
;
;           DESCRIPTION:    Free DLL debug event
;
;           PARAMETERS:     DS          Lib
;
;           RETURNS:        ES          Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDllEvent Proc near
    push eax
    push ebx
;
    mov eax,SIZE free_dll_event_struc
    mov di,SIZE event_struc
    add ax,di
    AllocateSmallGlobalMem
    sub ax,di
    mov es:event_size,ax
    mov es:event_code,EVENT_FREE_DLL
;       
    movzx ebx,ds:mod_id
    mov es:[di].fdeHandle,ebx    
;
    pop ebx
    pop eax
    ret
FreeDllEvent Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateSections
;
;           DESCRIPTION:    New create section
;
;           PARAMS:         GS      PE process selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section_start:

create_us_section   Proc near
    push eax
    push ecx
    push edx
    push edi
    
p1:
    mov edx,12345678h
    mov edi,edx
    mov ecx,MAX_SECTIONS
    xor eax,eax
    repnz scasd
;
    stc
    jnz csDone
;
    mov ebx,MAX_SECTIONS
    sub ebx,ecx
    push ebx
;
    dec ebx
    sub edi,4
    mov eax,16
    mul ebx
    add eax,4 * MAX_SECTIONS
    mov edx,eax

p2:    
    add edx,12345678h    
    mov [edi],edx
;    
    mov [edx].fs_handle,0
    mov [edx].fs_val,-1
    mov [edx].fs_counter,0
    mov [edx].fs_owner,0
    mov [edx].fs_sect_name,0
;
    pop ebx
    clc

csDone:
    pop edi
    pop edx
    pop ecx
    pop eax    
    ret
create_us_section   Endp

create_named_us_section   Proc near
    push eax
    push ecx
    push edx
    push edi
    push ebp
;
    mov ebp,edi
    
p1n:
    mov edx,12345678h
    mov edi,edx
    mov ecx,MAX_SECTIONS
    xor eax,eax
    repnz scasd
;
    stc
    jnz cnsDone
;
    mov ebx,MAX_SECTIONS
    sub ebx,ecx
    push ebx
;
    dec ebx
    sub edi,4
    mov eax,16
    mul ebx
    add eax,4 * MAX_SECTIONS
    mov edx,eax

p2n:    
    add edx,12345678h    
    mov [edi],edx
;    
    mov [edx].fs_handle,0
    mov [edx].fs_val,-1
    mov [edx].fs_counter,0
    mov [edx].fs_owner,0
    mov [edx].fs_sect_name,ebp
;
    pop ebx
    clc

cnsDone:
    pop ebp
    pop edi
    pop edx
    pop ecx
    pop eax    
    ret
create_named_us_section   Endp

free_us_section   Proc near
    push edx
;    
    sub ebx,1
    jc fusDone
;
    cmp ebx,MAX_SECTIONS
    jae fusDone
;
    shl ebx,2
    
p3:
    add ebx,12345678h
    xor eax,eax
    xchg eax,[ebx]
    or eax,eax
    jz fusDone
;    
    mov ebx,eax
    mov eax,[ebx].fs_handle
    or eax,eax
    jz fusDone
;    
    UserGateApp cleanup_futex_nr

fusDone:
    xor ebx,ebx
;
    pop edx
    ret
free_us_section   Endp

enter_us_section    Proc near
    push eax
    push ebx
;    
    sub ebx,1
    jc eusDone
;
    cmp ebx,MAX_SECTIONS
    jae eusDone
;
    shl ebx,2
    
p4:
    add ebx,12345678h
    mov ebx,[ebx]
    or ebx,ebx
    jz eusDone
;            
    str ax
    cmp ax,[ebx].fs_owner
    jne eusLock
;
    inc [ebx].fs_counter
    jmp eusDone

eusLock:
    lock add [ebx].fs_val,1
    jc eusTake
;
    mov eax,1
    xchg ax,[ebx].fs_val
    cmp ax,-1
    jne eusBlock

eusTake:
    str ax
    mov [ebx].fs_owner,ax
    mov [ebx].fs_counter,1
    jmp eusDone

eusBlock:
    push edi
    mov edi,[ebx].fs_sect_name
    or edi,edi
    jnz eusNamedBlock
;    
    UserGateApp acquire_futex_nr
    jmp eusBlockPop

eusNamedBlock:
    UserGateApp acquire_named_futex_nr

eusBlockPop:
    pop edi

eusDone:
    pop ebx
    pop eax    
    ret
enter_us_section   Endp

leave_us_section    Proc near
    push eax
    push ebx
;    
    sub ebx,1
    jc lusDone
;
    cmp ebx,MAX_SECTIONS
    jae lusDone
;
    shl ebx,2
    
p5:
    add ebx,12345678h
    mov ebx,[ebx]
    or ebx,ebx
    jz lusDone
;
    str ax
    cmp ax,[ebx].fs_owner
    jne lusDone
;
    sub [ebx].fs_counter,1
    jnz lusDone
;
    mov [ebx].fs_owner,0
    lock sub [ebx].fs_val,1
    jc lusDone
;
    mov [ebx].fs_val,-1
    UserGateApp release_futex_nr

lusDone:
    pop ebx
    pop eax
    ret
leave_us_section    Endp

section_end:        

CreateSections  Proc near
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    mov esi,OFFSET section_start
    mov eax,OFFSET section_end
    sub eax,esi
    mov ecx,eax
    call allocate_mem
    mov edi,edx
;
    mov ax,flat_data_sel
    mov es,ax
    rep movs byte ptr es:[edi],cs:[esi]
;
    sub edx,OFFSET section_start
;    
    mov edi,edx
    add edi,OFFSET create_us_section
    mov gs:ppr_create_section_proc,edi
;    
    mov edi,edx
    add edi,OFFSET create_named_us_section
    mov gs:ppr_create_named_section_proc,edi
;    
    mov edi,edx
    add edi,OFFSET free_us_section
    mov gs:ppr_delete_section_proc,edi
;    
    mov edi,edx
    add edi,OFFSET enter_us_section
    mov gs:ppr_enter_section_proc,edi
;    
    mov edi,edx
    add edi,OFFSET leave_us_section
    mov gs:ppr_leave_section_proc,edi
;
    mov esi,edx
    mov eax,MAX_SECTIONS * 16  ; 4 bytes for index + 12 bytes for data
    call allocate_mem
    mov edi,edx
;
    mov ecx,MAX_SECTIONS  ; only initialize indexes
    xor eax,eax
    rep stosd
;
    mov edi,esi
    add edi,OFFSET p1 + 1
    mov es:[edi],edx
;
    mov edi,esi
    add edi,OFFSET p2 + 2
    mov es:[edi],edx
;
    mov edi,esi
    add edi,OFFSET p1n + 1
    mov es:[edi],edx
;
    mov edi,esi
    add edi,OFFSET p2n + 2
    mov es:[edi],edx
;
    mov edi,esi
    add edi,OFFSET p3 + 2
    mov es:[edi],edx
;
    mov edi,esi
    add edi,OFFSET p4 + 2
    mov es:[edi],edx
;
    mov edi,esi
    add edi,OFFSET p5 + 2
    mov es:[edi],edx
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax    
    pop es    
    ret
CreateSections     ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SectionPatch
;
;           DESCRIPTION:    Patch sections to local calls
;
;           PARAMS:         DS:EBX      Instruction buffer
;                           GS          PE process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section_patch     PROC far
    mov ax,ds
    cmp ax,flat_code_sel
    jne spFail
;    
    mov ax,ds:[ebx+2]
    cmp ax,create_user_section_nr
    je spCreate
;    
    cmp ax,create_named_user_section_nr
    je spCreateNamed
;    
    cmp ax,delete_user_section_nr
    je spDelete
;    
    cmp ax,enter_user_section_nr
    je spEnter
;    
    cmp ax,leave_user_section_nr
    je spLeave
;
    jmp spFail    

spCreate:
    push es
    push edx
    push ecx
    push esi
;
    mov esi,ebx
    push ebx
    mov bx,ds
    GetSelectorBaseSize
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax    
;
    mov eax,gs:ppr_create_section_proc    
    sub eax,esi
    sub eax,6
    xchg eax,ds:[ebx+2]
;
    mov ax,9090h
    xchg ax,ds:[ebx+6]
;
    mov ax,0E890h    
    xchg ax,ds:[ebx]
    clc
;
    pop esi
    pop ecx
    pop edx
    pop es
    ret

spCreateNamed:
    push es
    push edx
    push ecx
    push esi
;
    mov esi,ebx
    push ebx
    mov bx,ds
    GetSelectorBaseSize
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax    
;
    mov eax,gs:ppr_create_named_section_proc
    sub eax,esi
    sub eax,6
    xchg eax,ds:[ebx+2]
;
    mov ax,9090h
    xchg ax,ds:[ebx+6]
;
    mov ax,0E890h    
    xchg ax,ds:[ebx]
    clc
;
    pop esi
    pop ecx
    pop edx
    pop es
    ret

spDelete:
    push es
    push edx
    push ecx
    push esi
;
    mov esi,ebx
    push ebx
    mov bx,ds
    GetSelectorBaseSize
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax    
;
    mov eax,gs:ppr_delete_section_proc    
    sub eax,esi
    sub eax,6
    xchg eax,ds:[ebx+2]
;
    mov ax,9090h
    xchg ax,ds:[ebx+6]
;
    mov ax,0E890h    
    xchg ax,ds:[ebx]
    clc
;
    pop esi
    pop ecx
    pop edx
    pop es
    ret

spEnter:
    push es
    push edx
    push ecx
    push esi
;
    mov esi,ebx
    push ebx
    mov bx,ds
    GetSelectorBaseSize
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax    
;
    mov eax,gs:ppr_enter_section_proc    
    sub eax,esi
    sub eax,6
    xchg eax,ds:[ebx+2]
;
    mov ax,9090h
    xchg ax,ds:[ebx+6]
;
    mov ax,0E890h    
    xchg ax,ds:[ebx]
    clc
;
    pop esi
    pop ecx
    pop edx
    pop es
    ret

spLeave:
    push es
    push edx
    push ecx
    push esi
;
    mov esi,ebx
    push ebx
    mov bx,ds
    GetSelectorBaseSize
    pop ebx
    add ebx,edx
    mov ax,flat_sel
    mov ds,ax    
;
    mov eax,gs:ppr_leave_section_proc    
    sub eax,esi
    sub eax,6
    xchg eax,ds:[ebx+2]
;
    mov ax,9090h
    xchg ax,ds:[ebx+6]
;
    mov ax,0E890h    
    xchg ax,ds:[ebx]
    clc
;
    pop esi
    pop ecx
    pop edx
    pop es
    ret

spFail:
    stc
    ret
section_patch  Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateLib
;
;           DESCRIPTION:    Create lib
;
;           PARAMETERS:     FS:ESI      Image name
;                           BX          C file handle
;                           EDX         File position
;
;           RETURNS:        ES          Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateLib       Proc near
    push eax
    push ecx
    push esi
    push edi
;
    xor cx,cx
    push esi

create_lib_size_loop:
    mov al,fs:[esi]
    or al,al
    jz create_lib_size_ok
;
    cmp al,'.'
    jz create_lib_size_ok
    inc cx
    inc esi
    jmp create_lib_size_loop

create_lib_size_ok:
    pop esi
    movzx eax,cx
    mov edi,OFFSET lib_name
    add eax,edi
    inc eax
    AllocateSmallGlobalMem
;
    rep movs byte ptr es:[edi],fs:[esi]
    mov byte ptr es:[edi],0
;       
    mov es:mod_name_offs,OFFSET lib_name
    mov es:mod_sel,flat_code_sel
    mov es:mod_base,0
    mov es:mod_base+4,0
    mov es:mod_size,0
    mov es:mod_size+4,0
    mov es:mod_debug_id,0
    mov es:lib_debug_wait,0
    mov es:lib_events,0
    mov es:mod_c_file_handle,bx
    mov es:lib_file_pos,edx
    mov es:lib_init_param,0
    mov es:lib_mem_blocks,0
    InitSpinlock es:lib_spinlock
    InitSection es:lib_section
    mov es:mod_loader,pe_loader_sel
;
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
CreateLib       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InsertApp
;
;           DESCRIPTION:    Insert App image into module list
;
;           PARAMETERS:     ES          Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertApp       Proc near
    push ds
    push es
    pushad
;
    GetThread
    mov ds,ax
    mov ds:p_loader,pe_loader_sel
;
    mov ds,ds:p_app_sel
    mov ds:app_fork_proc,OFFSET fork_proc
    mov ds:app_fork_proc+4,cs
    mov ds:app_close_proc,OFFSET close_proc
    mov ds:app_close_proc+4,cs
    mov ds:app_fatal_error_exit_proc,OFFSET fatal_error_exit
    mov ds:app_fatal_error_exit_proc+4,cs
;
    popad
    pop es
    pop ds
    ret
InsertApp       Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindLib
;
;           DESCRIPTION:    Search for a DLL or app module
;
;           PARAMETERS:     EDX         Virtual adress
;
;           RETURNS:        EDI         Image base
;                           ES          Lib
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindLib Proc near
    push ds
    push eax
    push ebx
;
    GetThread
    mov ds,eax
    mov bx,ds:p_prog_id
    FindModuleByAddress
    jc flDone
;
    ModuleIdToSel
    jc flDone
;
    mov es,ebx
    mov edi,es:mod_base
    clc

flDone:
    pop ebx
    pop eax
    pop ds
    ret
FindLib Endp
               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FindObject
;
;           DESCRIPTION:    Search for a object
;
;           PARAMETERS:     ES          Lib handle
;                           EDX         Virtual adress
;
;           RETURNS:        ESI         Object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindObject      Proc near
    push eax
    push ecx
;
    mov edi,es:mod_base
    mov esi,es:lib_header
    movzx ecx,[esi].peh_objects
    mov esi,es:lib_objects
find_object_loop:
    mov eax,edx
    sub eax,edi
    sub eax,[esi].o_va
    jc find_object_fail
    cmp eax,[esi].o_virt_size
    jc find_object_ok
    add esi,SIZE object_struc
    loop find_object_loop

find_object_fail:
    stc
    jmp find_object_done

find_object_ok:
    clc

find_object_done:
    pop ecx
    pop eax
    ret
FindObject      Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RelocPage
;
;           DESCRIPTION:    Relocate a single page
;
;           PARAMETERS:     ES          Lib handle
;                           EDX         Allocate buffer
;                           EBP         Real address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reloc_nop       Proc near
    ret
reloc_nop       Endp

reloc_high      Proc near
    push ecx
    mov ecx,edi
    shr ecx,16
    and ax,0FFFh
    movzx eax,ax
    add eax,edx
    add [eax],cx
    pop ecx
    ret
reloc_high      Endp

reloc_low       Proc near
    and ax,0FFFh
    movzx eax,ax
    add eax,edx
    add [eax],di
    ret
reloc_low       Endp

reloc_highlow   Proc near
    and ax,0FFFh
    movzx eax,ax
    add eax,edx
    add [eax],edi
    ret
reloc_highlow   Endp

reloc_highadj   Proc near
    int 3
    ret
reloc_highadj   Endp

reloc_tab:
rt0     DD OFFSET reloc_nop
rt1     DD OFFSET reloc_high
rt2     DD OFFSET reloc_low
rt3     DD OFFSET reloc_highlow
rt4     DD OFFSET reloc_highadj
rt5     DD OFFSET reloc_nop
rt6     DD OFFSET reloc_nop
rt7     DD OFFSET reloc_nop
rt8     DD OFFSET reloc_nop
rt9     DD OFFSET reloc_nop
rtA     DD OFFSET reloc_nop
rtB     DD OFFSET reloc_nop
rtC     DD OFFSET reloc_nop
rtD     DD OFFSET reloc_nop
rtE     DD OFFSET reloc_nop
rtF     DD OFFSET reloc_nop

RelocPage       Proc near
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    mov ebx,es:lib_header
    mov edi,es:mod_base
    mov ecx,[ebx].peh_fixup_size
    mov esi,[ebx].peh_fixup_va      
;
    or ecx,ecx
    jz reloc_object_done
;       
    or esi,esi
    jz reloc_object_done
;
    add esi,edi
reloc_object_fixup_search:
    or esi,esi
    jz reloc_object_done
    mov eax,[esi].fixup_va
    or eax,eax
    je reloc_object_done
;
    add eax,edi
    cmp eax,ebp
    je reloc_object_fixup_found
;       
    mov eax,[esi].fixup_size
    add esi,eax
    sub ecx,eax
    jz reloc_object_done
    jnc reloc_object_fixup_search
    jmp reloc_object_done

reloc_object_fixup_found:
    sub edi,[ebx].peh_image_base
    mov ecx,[esi].fixup_size
    add esi,OFFSET fixup_data
    sub ecx,OFFSET fixup_data
reloc_object_reloc_loop:
    lods word ptr [esi]
    sub ecx,2
    movzx bx,ah
    shr bx,4
    shl bx,2
    call dword ptr cs:[bx].reloc_tab
    or ecx,ecx
    jnz reloc_object_reloc_loop

reloc_object_done:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret
RelocPage       Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckReloc
;
;           DESCRIPTION:    Check if any relocation span pages
;
;           PARAMETERS:     ES          Lib handle
;                           EBP         Real address
;
;       RETURNS:    CY      Relocation spans pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reloc_size_tab:
rs0     DB 0
rs1     DB 2
rs2     DB 2
rs3     DB 4
rs4     DB 0
rs5     DB 0
rs6     DB 0
rs7     DB 0
rs8     DB 0
rs9     DB 0
rsA     DB 0
rsB     DB 0
rsC     DB 0
rsD     DB 0
rsE     DB 0
rsF     DB 0

CheckReloc      Proc near
    push eax
    push ebx
    push ecx
    push esi
;
    mov ebx,es:lib_header
    mov edi,es:mod_base
    mov ecx,[ebx].peh_fixup_size
    mov esi,[ebx].peh_fixup_va      
;
    or ecx,ecx
    jz check_reloc_ok
;       
    or esi,esi
    jz check_reloc_ok
;
    add esi,edi

check_reloc_fixup_search:
    or esi,esi
    jz check_reloc_ok
    
    mov eax,[esi].fixup_va
    or eax,eax
    je check_reloc_ok
;
    add eax,edi
    cmp eax,ebp
    je check_reloc_fixup_found
;       
    mov eax,[esi].fixup_size
    add esi,eax
    sub ecx,eax
    jz check_reloc_ok
    jnc check_reloc_fixup_search
    jmp check_reloc_ok

check_reloc_fixup_found:
    mov ecx,[esi].fixup_size
    add esi,OFFSET fixup_data
    sub ecx,OFFSET fixup_data

check_reloc_loop:
    lods word ptr [esi]
    sub ecx,2
    movzx bx,ah
    shr bx,4
    movzx bx,byte ptr cs:[bx].reloc_size_tab
    or bx,bx
    jz check_reloc_next
;       
    and ax,0FFFh
    add ax,bx
    dec ax
    test ax,1000h
    jnz check_reloc_failed

check_reloc_next:       
    or ecx,ecx
    jnz check_reloc_loop

check_reloc_ok:
    clc
    jmp check_reloc_done
    
check_reloc_failed:
    stc

check_reloc_done:
    pop esi
    pop ecx
    pop ebx
    pop eax
    ret
CheckReloc      Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           load_object
;
;           DESCRIPTION:    Demand load object
;
;           PARAMETERS:     EDX         LINEAR ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_object     Proc far
    push ds
    push es
    pushad
;       
    mov ax,system_data_sel
    mov ds,ax
    mov ecx,ds:flat_base
    sub edx,ecx
    mov ax,flat_data_sel
    mov ds,ax
    and dx,0F000h
;
    call FindLib
    jc load_object_done
;
    call FindObject
    jc load_object_done
;
    push ds
    mov ax,es
    mov ds,ax
    EnterSection ds:mod_section
;
    push edx
    add edx,ecx
    HasPageEntry
    pop edx
    pop ds
    jnc load_object_leave
;
    xor eax,eax
    mov ebp,edx
;    
    mov ebx,es:lib_header
    cmp edi,[ebx].peh_image_base
    je load_object_size_ok

load_object_get_size:
    call CheckReloc
    jnc load_object_size_ok
;
    add eax,1000h
    add ebp,1000h
    jmp load_object_get_size

load_object_size_ok:
    mov ebp,edx
    add eax,1000h
    AllocateLocalLinear
    push edx    
    push eax
;
    sub edx,ecx
;
    push eax
    push edx
    push ebp

load_object_load_loop:
    call LoadPage
    jc load_object_load_done
;
    sub eax,1000h
    jz load_object_load_done
;    
    add edx,1000h
    add ebp,1000h
    jmp load_object_load_loop

load_object_load_done:
    call MapFromImage
    mov ebx,eax
;
    pop ebp
    pop edx
    pop eax
;    
    sub eax,ebx
;
    push eax
    push edx
    push ebp    
;
    mov ebx,es:lib_header
    cmp edi,[ebx].peh_image_base
    je load_object_map

load_object_reloc_loop:
    call RelocPage
;
    sub eax,1000h
    jz load_object_map
;    
    add edx,1000h
    add ebp,1000h
    jmp load_object_reloc_loop

load_object_map:
    pop ebp
    pop edx
    pop eax
;
    pop ebx
    call MapToImage
;
    mov ecx,ebx
    pop edx
    FreeLinear

load_object_leave:
    mov ax,es
    mov ds,ax
    LeaveSection ds:mod_section
    
load_object_done:
    popad
    pop es
    pop ds
    retf16
load_object     Endp 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ImportObject
;
;           DESCRIPTION:    Import an object
;
;           PARAMETERS:     EBX         Address of import ordinal + name        
;                           GS          Lib handle of export DLL
;                           ES          Lib handle of import DLL/APP
;                           
;           RETURNS:        EAX         Virtual address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnresolvedMsg DB 'Cannot find imported function ',0

ImportObject    Proc near
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    mov esi,gs:mod_base
    mov edi,esi
    mov esi,gs:lib_header
    mov esi,[esi].peh_export_va
    add esi,edi
;
    mov ax,[ebx]
    or ax,ax
    jz import_by_name
;
    movzx eax,ax
    sub eax,[esi].exp_ordinal_base
    jc import_by_name
;
    cmp eax,[esi].exp_name_count
    jnc import_by_name
    jmp import_by_name

import_by_ordinal:
    int 3
    mov ecx,[esi].exp_name_count
    mov edx,[esi].exp_ordinal_base

import_by_ordinal_loop:
    cmp ax,[edx]
    je import_by_ordinal_found
    add edx,2
    sub ecx,1
    jnz import_by_ordinal_loop
    int 3
    jmp import_object_done
    
import_by_ordinal_found:

import_by_name:
    add ebx,2
    mov ecx,[esi].exp_name_count
    mov edx,[esi].exp_name_va
    add edx,edi

import_by_name_loop:
    push ebx
    push esi
    mov esi,[edx]
    add esi,edi

import_by_name_search:
    mov al,[esi]
    mov ah,[ebx]
    cmp al,ah
    jne import_by_name_next
;
    or al,ah
    jz import_by_name_ok
;
    inc ebx
    inc esi
    jmp import_by_name_search

import_by_name_next:
    pop esi
    pop ebx
    add edx,4
    loop import_by_name_loop
    jmp import_object_done

import_by_name_ok:
    pop esi
    pop ebx
;    
    sub edx,[esi].exp_name_va
    sub edx,edi
;
    shr edx,1
    add edx,[esi].exp_ordinal_va
    add edx,edi
    movzx edx,word ptr [edx]
;
    shl edx,2
    add edx,[esi].exp_entry_point_va
    add edx,edi
    mov eax,[edx]
    add eax,edi

import_object_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ImportObject    Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           BindImport
;
;           DESCRIPTION:    Bind imported functions
;
;           PARAMETERS:     EDX         Import descr
;                           GS          Export Lib handle
;                           ES          Import Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BindImport      Proc near
    push eax
    push edx
    push esi
    push edi
;
    mov esi,gs:mod_base
    mov edi,es:mod_base
    mov eax,gs:lib_header
    mov eax,[eax].peh_export_va
    or eax,eax
    je bind_import_done
;
    add eax,esi
    mov edx,[edx].imp_first_thunk_va
    add edx,edi

bind_import_loop:
    mov ebx,[edx]
    or ebx,ebx
    jz bind_import_done
;
    add ebx,edi
    call ImportObject
    mov [edx],eax
    add edx,4
    jmp bind_import_loop

bind_import_done:
    pop edi
    pop esi
    pop edx
    pop eax
    ret
BindImport      Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadImportedDlls
;
;           DESCRIPTION:    Load imported DLLs
;
;           PARAMETERS:     ES          Lib
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadImportedDlls    Proc near
    push fs
    push gs
    pushad
;
    mov edi,es:mod_base
    mov ax,flat_data_sel
    mov fs,ax
;
    mov edx,es:lib_header
    mov edx,[edx].peh_import_va
    or edx,edx
    jz load_import_dlls_done
;
    add edx,edi

load_import_dlls_loop:
    mov esi,[edx].imp_dll_name_va
    or esi,esi
    jz load_import_dlls_done
;
    push es
    push edi
;
    mov eax,ds
    mov es,eax
    add edi,esi
    LoadDll
    jc load_import_dll_fail
;
    ModuleIdToSel
    jc load_import_dll_fail
;
    mov gs,bx
    jmp load_import_dll_bind

load_import_dll_fail:
    int 3

load_import_dll_bind:
    pop edi
    pop es
    jc load_import_dlls_loop
;       
    call BindImport
;
    add edx,SIZE import_descr
    jmp load_import_dlls_loop

load_import_dlls_done:
    popad
    pop gs
    pop fs
    ret
LoadImportedDlls    Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeImportDlls
;
;           DESCRIPTION:    Free imported DLLs
;
;           PARAMETERS:     ES          Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeImportedDlls    Proc near
    push eax
    push edx
    push esi
;
    mov edi,es:mod_base
    mov edx,es:lib_header
    mov edx,[edx].peh_import_va
    or edx,edx
    jz free_import_dlls_done
;
    add edx,edi

free_import_dlls_loop:
    mov esi,[edx].imp_dll_name_va
    or esi,esi
    jz free_import_dlls_done
;
    push ds
    push fs
    pushad
;
    mov eax,ds
    mov fs,eax
    add esi,edi
;
    GetThread
    mov ds,ax
    movzx ebx,ds:p_prog_id
    FindModuleByName
    jc free_import_one_done
;
    FreeDll

free_import_one_done:
    popad
    pop fs
    pop ds
;
    add edx,SIZE import_descr
    jmp free_import_dlls_loop

free_import_dlls_done:
    pop esi
    pop edx
    pop eax
    ret
FreeImportedDlls    Endp
                                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           fixup_dll
;
;           DESCRIPTION:    Fixup DLL
;
;           PARAMETERS:     BX          Module sel
;                           DX          Debug module ID
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fixup_dll       PROC far
    mov ax,flat_data_sel
    mov ds,eax
    mov es,bx
    call FixupImage
;
    mov es:mod_debug_id,dx
    mov ecx,es:mod_size
    call LoadImportedDlls
;
    mov dx,es:mod_debug_id
    or dx,dx
    jz fdNodeb
;
    mov ax,es
    mov ds,ax
    call LoadDllEvent
    call SendEvent

fdNodeb:
    mov edx,1
    call AddUserStack
    ret
fixup_dll  Endp
             
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LoadPage
;
;           DESCRIPTION:    Load a single page in the image file
;
;           PARAMETERS:     ECX     Flat base
;               EDX         Allocate address
;                   ESI         Image object
;               EDI     Image base
;               EBP     Image address
;               DS      Flat data sel
;               ES      Lib sel
;
;       RETURNS:    NC      Load success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadPage    Proc near
    pushad
;
    push edx
    mov edx,ebp
    add edx,ecx
    HasPageEntry
    pop edx
    cmc
    jc load_page_done
;       
    test [esi].o_flags,80h
    jz load_page_from_file

load_page_zero:
    push es
    push edi
    mov ax,ds
    mov es,ax
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop edi
    pop es
    clc
    jmp load_page_done

load_page_from_file:
    mov bx,es:mod_c_file_handle
    mov eax,ebp
    sub eax,edi
    sub eax,[esi].o_va
    mov ecx,[esi].o_phys_size
    sub ecx,eax
    jnc load_page_file
;
    xor ecx,ecx 
    jmp load_page_size_ok
    
load_page_file:
    cmp ecx,1000h
    jc load_page_size_ok
    mov ecx,1000h

load_page_size_ok:
    push es
    push edx
    push edi
    mov edi,edx
    mov edx,eax
    mov ax,ds
    mov es,ax
    add edx,[esi].o_phys_offset
    ReadCFile
    jnc load_page_pad
;
    xor eax,eax

load_page_pad:    
    add edi,eax
    mov ecx,1000h
    sub ecx,eax
    shr ecx,2
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop edi
    pop edx
    pop es
    clc

load_page_done:
    popad
    ret
LoadPage    Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapFromImage
;
;           DESCRIPTION:    Map image file to the allocate buffer
;
;           PARAMETERS:     EAX     Size to map
;               ECX     Flat base
;               EDX         Allocated address
;                   ESI         Image object
;               EDI     Image base
;               EBP     Image address
;               DS      Flat data sel
;               ES      Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapFromImage    Proc near
    pushad
;    
    add edx,ecx
    add ebp,ecx
;
    or eax,eax
    jz map_from_image_done
;    
    mov ecx,eax
    shr ecx,12
    mov esi,ebp
    mov edi,edx
    CopyPageEntries

map_from_image_done:
    popad
    ret
MapFromImage  Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MapToImage
;
;           DESCRIPTION:    Map allocate buffer to the image file
;
;           PARAMETERS:     EAX     Size to map
;               EBX     Size of buffer
;               ECX     Flat base
;               EDX         Allocated address
;                   ESI         Image object
;               EDI     Image base
;               EBP     Image address
;               DS      Flat data sel
;               ES      Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MapToImage    Proc near
    pushad
;
    sub ebx,eax
    shr ebx,12
    push ebx
    push edx
;    
    mov edi,ebp
    mov ebp,[esi].o_flags
    mov esi,edx
    add esi,ecx
    add edi,ecx
;
    mov ecx,eax
    shr ecx,12

map_to_image_loop:
    mov edx,esi
    GetPageEntry
;
    push eax
    push ebx
    xor eax,eax
    xor ebx,ebx
    SetPageEntry    
    pop ebx
    pop eax
;
    test al,1
    jnz map_to_image_valid
;
    xor eax,eax
    xor ebx,ebx
    jmp map_to_image_save       

map_to_image_valid:
    test ebp,80000000h
    jnz map_to_image_save

    and al,NOT 2

map_to_image_save:
    mov edx,edi
    SetPageEntry
;    
    add esi,1000h
    add edi,1000h
    loop map_to_image_loop
;
    pop edx
    pop ecx
    or ecx,ecx
    jz map_to_image_done
;
    xor eax,eax

map_to_image_reset:
    SetPageEntry
    add edx,1000h
    loop map_to_image_reset

map_to_image_done:    
    popad
    ret
MapToImage  Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateImage
;
;           DESCRIPTION:    Create memory image of header
;
;           PARAMETERS:     FS:ESI      Image name
;                           ES          Lib handle
;
;           RETURNS:        EDI         Image base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateImage     Proc near
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push ebp
;
    mov bx,system_data_sel
    mov ds,bx
    mov ebp,ds:flat_base
;
    mov bx,flat_data_sel
    mov ds,bx
;
    mov bx,es:mod_c_file_handle
    mov edx,es:lib_file_pos
    push edx
    push es
    mov eax,SIZE pe_header
    AllocateLocalMem
    mov ecx,eax
    xor edi,edi
    ReadCFile   
    mov ecx,es:peh_image_size
    mov edx,es:peh_image_base
    mov si,es:peh_nthdr_size
    mov di,es:peh_objects
    FreeMem
    pop es
;
    pop eax
    mov es:lib_header,eax
    mov es:mod_base,edx
    mov es:mod_size,ecx
;
    movzx ecx,si
    add ecx,eax
    add ecx,24
    mov es:lib_objects,ecx
;
    mov ax,SIZE object_struc
    mul di
    push dx
    push ax
;
    mov edx,es:mod_base
    mov eax,es:mod_size
    add edx,ebp
    ReserveLocalLinear
    jnc create_image_alloced
;
    AllocateLocalLinear
    mov es:mod_base,edx

create_image_alloced:
    sub edx,ebp
    SetFlatLinearInvalid
;
    pop eax
    add eax,es:lib_objects
    mov ecx,eax
    SetFlatLinearValid
;
    add es:lib_header,edx
    add es:lib_objects,edx
    mov es:mod_base,edx
;
    push es
    push edx
    mov ax,ds
    mov es,ax
    mov edi,edx
    xor edx,edx
    ReadCFile
    pop edx
    pop es
;
    mov esi,es:lib_header
    movzx ecx,[esi].peh_objects
    mov esi,es:lib_objects
;
    push es
    mov ax,cs
    mov es,ax
hook_object_loop:
    mov edx,[esi].o_va
    add edx,edi
    add edx,ebp
    mov eax,[esi].o_virt_size
    cmp eax,[esi].o_phys_size
    jae hook_object_do
    mov eax,[esi].o_phys_size
    mov [esi].o_virt_size,eax
hook_object_do:
    push di
    mov di,OFFSET load_object
    HookPage
    pop di
    add esi,SIZE object_struc
    loop hook_object_loop
    pop es
;
    pop ebp
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
CreateImage     Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FixupImage
;
;           DESCRIPTION:    Fixup image
;
;           PARAMETERS:     ES          Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
FixupImage      Proc near
    push ds
    push es
    pushad
;
    mov bx,system_data_sel
    mov ds,bx
    mov ebp,ds:flat_base
;
    mov bx,flat_data_sel
    mov ds,bx
;
    mov edi,es:mod_base
    mov esi,es:lib_header
    mov eax,[esi].peh_fixup_size
    mov edx,[esi].peh_fixup_va      
    or edx,edx
    jz fixup_done
;
    add edx,edi
    call FindObject
    jc fixup_done
;
    mov ecx,eax
    mov edi,edx
    add edx,ebp
    mov eax,ecx
    UnhookPage
;
    mov bx,es:mod_c_file_handle
    mov edx,[esi].o_phys_offset
    mov ax,ds
    mov es,ax
    ReadCFile

fixup_done:
    popad
    pop es
    pop ds
    ret
FixupImage      Endp
                      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Preload
;
;           DESCRIPTION:    Preload image
;
;           PARAMETERS:     ES          Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preload Proc near
    push eax
    push ecx
    push edx
    push esi
;
    mov edi,es:mod_base
    mov esi,es:lib_header
    movzx ecx,[esi].peh_objects
    mov esi,es:lib_objects
PreloadAllLoop:
    mov edx,[esi].o_va
    add edx,edi
    mov eax,[esi].o_virt_size
PreloadOneLoop:
    mov al,[edx]
    xor al,al
    add edx,1000h
    sub eax,1000h
    ja PreloadOneLoop
;
    add esi,SIZE object_struc
    loop PreloadAllLoop
;
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
Preload Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitStack
;
;           DESCRIPTION:    Init stack and TIB
;
;           PARAMETERS:     ES      Lib handle
;                           EBP     Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitStack       Proc near
    push fs
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    mov edi,es:mod_base
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov ebx,ds:flat_base
    push bx
;
    mov eax,1000h
    AllocateLocalLinear
    AllocateLdt
    or bx,7
    mov ecx,eax     
    CreateDataSelector32
    mov [ebp].load_fs,bx
    mov fs,bx
    pop bx
    pop ds
    sub edx,ebx
    mov fs:pvBase,edx
;
    mov dword ptr [ebp].load_ss,flat_data_sel
    mov esi,es:lib_header
    mov eax,[esi].peh_stack_reserve_size
    AllocateLocalLinear
    sub edx,ebx
    mov [ebp].load_ebx,edx
    mov fs:pvFirstExcept,-1
    mov fs:pvStackUserBottom,edx
    mov fs:pvStackUserSize,eax
    add edx,eax
    sub edx,88h
    mov fs:pvTEB,edx
    GetThread
    push es
    mov es,ax
    movzx eax,es:p_id
    pop es
    mov fs:pvThreadHandle,eax
    mov fs:pvProcessHandle,eax
    mov [edx+24h],eax
    mov [ebp].load_ebp,edx
    sub edx,10h
    mov [ebp].load_ecx,edx
    sub edx,100h
    mov fs:pvTLSArray,edx
;
    sub edx,8
    mov fs:pvTLSBitmap,edx
    mov dword ptr [edx],-1
    mov dword ptr [edx+4],-1
;
    mov eax,[esi].peh_tls_va
    or eax,eax
    jz init_stack_no_tls
;
    push es
    push ecx
    push edx
;
    mov eax,[esi].peh_tls_va
    add eax,edi
    mov esi,[eax].tls_start_data_va
    mov ecx,[eax].tls_end_data_va
    push eax
    sub ecx,esi
    mov eax,ecx
    and ax,0F000h
    add eax,1000h
    AllocateLocalLinear
    sub edx,ebx
    push edi
    mov edi,edx
    mov bx,ds
    mov es,bx
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
    pop eax
    int 3
    mov eax,[eax].tls_index_va
    mov eax,[eax]
;       
    mov esi,fs:pvTLSArray
    mov [esi+4*eax],edx
    mov esi,fs:pvTLSBitmap
    btr [esi],eax

init_tls_skipped:
    pop edx
    pop ecx
    pop es

init_stack_no_tls:
    mov eax,-1
    sub edx,4
    mov [edx],eax
    sub edx,4
    mov [edx],eax
    sub edx,4
    mov [edx],eax
    sub edx,4
    mov [edx],eax
    sub edx,4
    mov [edx],eax
;
    xor eax,eax
    mov fs:pvStackUserTop,edx
    mov [edx],eax                       ; reserved
    sub edx,4
    mov [edx],eax                       ; reason
    sub edx,4
    movzx eax,es:mod_id
    mov dword ptr [edx],eax             ; module handle
    mov fs:pvModuleHandle,eax
    sub edx,4
    xor eax,eax
    mov [edx],eax                       ; return address
    sub edx,4
    mov [edx],edx
    mov [ebp].load_esp,edx
;
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop fs
    ret
InitStack       Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RunImage
;
;           DESCRIPTION:    Setup registers to run image
;
;           PARAMETERS:     ES          Lib handle
;                           EBP         Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunImage    Proc near
    push eax
    push ebx
    push edx
;
    mov edi,es:mod_base
    mov dword ptr [ebp].load_cs,flat_code_sel
    mov eax,es:lib_header
    mov eax,[eax].peh_entry_point
    add eax,edi
    mov [ebp].load_eip,eax
    mov [ebp].load_eax,eax
    mov dword ptr [ebp].load_edi,0
    mov word ptr [ebp+2].load_eflags,0
    mov ax,7202h
    SetFlags
    mov [ebp].load_eflags,ax
    mov dword ptr [ebp].load_ds,flat_data_sel
    mov dword ptr [ebp].load_es,flat_data_sel
;
    pop edx
    pop ebx
    pop eax
    ret
RunImage    Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           is_valid_exe
;
;           DESCRIPTION:    Check for valid exe
;
;           PARAMETERS:     BX      C file handle
;
;           RETURNS:        GS      Process sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_valid_exe Proc far
    push es
    push ecx
    push edx
    push esi
    push edi
;
    xor edx,edx
    mov eax,SIZE pe_process_struc
    AllocateSmallGlobalMem
    mov ecx,40h
    xor edi,edi
    ReadCFile
    jc iseFail
;
    cmp ax,40h
    jne iseFail
;
    mov ax,es:exeh_signature
    cmp ax,5A4Dh
    jne iseFail
;
    mov ax,es:exeh_reloc_offs
    cmp ax,40h
    jne iseFail
;
    mov ax,es:[3Ch]
    movzx edx,ax
    mov ecx,40h
    ReadCFile   
    jc iseFail
;
    mov ax,es:[0]
    cmp ax,'EP'
    jne iseFail
;
    mov ax,es
    mov gs,ax
    clc
    jmp iseDone

iseFail:
    FreeMem
    stc

iseDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop es
    ret
is_valid_exe Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_module
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:     DS:ESI      Image name
;                           ES:EDI  Command line
;                           BX      C file handle
;
;           RETURNS:        BX      Module selector
;                           AL      Bitness
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_module Proc far
    push ds
    push es
    push fs
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,ds
    mov fs,ax
    mov ax,flat_data_sel
    mov ds,ax
;
    xor edx,edx
    mov eax,40h
    AllocateSmallGlobalMem
    mov ecx,eax
    xor edi,edi
    ReadCFile
    jc imFail
;
    cmp ax,40h
    jne imFail
;
    mov ax,es:exeh_signature
    cmp ax,5A4Dh
    jne imFail
;
    mov ax,es:exeh_reloc_offs
    cmp ax,40h
    jne imFail
;
    mov ax,es:[3Ch]
    movzx edx,ax
    mov ecx,40h
    ReadCFile   
    jc imFail
;
    mov ax,es:[0]
    cmp ax,'EP'
    jne imFail
;
    movzx ecx,cx
    sub edx,ecx
;
    FreeMem
    call CreateLib    
    call CreateImage
;
    mov al,32
    mov bx,es
    clc
    jmp imDone

imFail:
    FreeMem
    stc

imDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop fs
    pop es
    pop ds
    ret
init_module  Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitDebug
;
;           DESCRIPTION:    Pre DLL import debug setup
;
;           PARAMETERS:     DX      Debug module ID
;                           EBP     Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDebug Proc near
    push ds
    push es
    pushad
;
    mov ax,flat_data_sel
    mov ds,ax
    mov esi,[ebp].load_eip
    mov esi,ds:[esi-4]
    mov es:lib_org_eip,esi
    mov eax,ds:[esi+1]
    add eax,esi
    add eax,5
    mov [ebp].load_eip,eax
;
    add esi,5
    call InitDebugUserStack
;
    GetThread
    mov ds,ax
;
    call AllocateKernelEvent
    mov word ptr ds:p_debug_proc,OFFSET NotifyKernelDebug
    mov word ptr ds:p_debug_proc+2,cs
;
    mov es:mod_debug_id,dx
    mov es:lib_init_param,dx
;
    mov ax,es
    mov ds,ax
    mov fs,[ebp].load_fs
    call CreateProcessEvent
    call SendEvent
;
    popad
    pop es
    pop ds
    ret
InitDebug   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FixupDebug
;
;           DESCRIPTION:    Post DLL import debug setup
;
;           PARAMETERS:     DX      Debug sel
;                           EBP     Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FixupDebug Proc near
    push ds
    push es
    pushad
;
    call FixupDebugUserStack
;
    mov ax,flat_data_sel
    mov ds,ax
    mov esi,es:lib_org_eip
    mov eax,[ebp].load_eip
    sub eax,esi
    sub eax,5
    mov ds:[esi+1],eax
    mov [ebp].load_eip,esi
;
    popad
    pop es
    pop ds
    ret
FixupDebug  Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           fixup_exe
;
;           DESCRIPTION:    Fixup exe
;
;           PARAMETERS:     BX      Module sel
;                           DX      Debug sel
;                           GS      PE process sel
;                           EBP     Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fixup_exe Proc far
    push ds
    push es
    push fs
    push edx
    push esi
    push edi
;
    mov ax,flat_data_sel
    mov ds,eax
    mov es,bx
;
    push dx
    call CreateSections
    call FixupImage
    call InsertApp
    call InitStack
    call RunImage
    pop dx
;
    or dx,dx
    jz feNoPreDebug
;
    call InitDebug

feNoPreDebug:
    push dx
    call LoadImportedDlls
    pop dx
;
    or dx,dx
    jz feNoPostDebug
;
    call FixupDebug

feNoPostDebug:
    pop edi
    pop esi
    pop edx
    pop fs
    pop es
    pop ds
    ret
fixup_exe Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           setup_names
;
;           DESCRIPTION:    Setup names
;
;           PARAMETERS:     DS:ESI  File name
;                           ES:EDI  Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_names Proc far
    push ds
    push es
    push fs
    push edx
    push esi
    push edi
;
    GetThread
    mov fs,ax
    mov fs,fs:p_app_sel
;
    xor ecx,ecx
    push edi

load_exe_cmd_size:
    mov al,es:[edi]
    inc edi
    inc ecx
    or al,al
    jnz load_exe_cmd_size
;
    pop edi
    xor ebx,ebx
    push esi

load_exe_name_size:
    mov al,[esi]
    inc esi
    inc ebx
    or al,al
    jnz load_exe_name_size
;
    pop esi
;
    mov eax,ecx
    add eax,ebx
    AllocateAppMem
    mov fs:app_cmd_line,edx
;
    push es
    push ecx
    push edi
    mov ax,flat_data_sel
    mov es,ax
    mov edi,edx
    mov ecx,ebx
    rep movs byte ptr es:[edi],ds:[esi]
    mov edx,edi
    pop edi
    pop ecx
    pop es  
;
    mov esi,edi
    mov edi,edx
    mov ax,es
    mov ds,ax
    mov ax,flat_data_sel
    mov es,ax
    mov byte ptr es:[edi-1],' '
    rep movs byte ptr es:[edi],ds:[esi]
    clc
    jmp load_exe_done

load_exe_fail:
    pop ax
    FreeMem
    stc

load_exe_done:
    pop edi
    pop esi
    pop edx
    pop fs
    pop es
    pop ds
    ret
setup_names Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           create_process
;
;           DESCRIPTION:    Create process
;
;           PARAMETERS:     BX                 Module selector
;                           ES:EDI             Thread name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_process    Proc far
    GetExeStart32
;
    mov ax,2
    mov ecx,stack0_size
    CreateProcess
    ret
create_process  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           unload_user_exe
;
;           DESCRIPTION:    Unload user exe
;
;           PARAMETERS:     BX                 Module selector
;                           EBP                Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_user_exe        Proc far
    mov es,bx
    mov ax,flat_data_sel
    mov ds,ax
    mov edi,es:mod_base
    call FreeImportedDlls
    ret
unload_user_exe        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           unload_kernel_exe
;
;           DESCRIPTION:    Unload kernel exe
;
;           PARAMETERS:     BX                 Module selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_kernel_exe        Proc far
    mov ds,bx
    mov ax,ds:mod_debug_id
    or ax,ax
    jz ukDone
;
    call TerminateProcessEvent
    call SendEvent

ukDone:
    ret
unload_kernel_exe        Endp
                                              
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitThread
;
;           DESCRIPTION:    Init thread
;
;           PARAMETERS:     DS          TSS selector of new thread
;                           EAX         Stack size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread     PROC far
    push es
    push fs
    push eax
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    push eax
    mov ax,system_data_sel
    mov fs,ax
    mov ebp,fs:flat_base
    mov ax,flat_data_sel
    mov fs,ax
    mov es,word ptr ds:p_rbx
    mov ebx,es:pvModuleHandle
    mov edx,es:pvProcessHandle
    push es
    push bx
    ModuleIdToSel
    mov es,ebx
    mov esi,es:lib_header
    mov edi,es:mod_base
    pop bx
    pop es
;       
    mov ecx,es:pvArbitrary
    push ds
    push bx
    push ecx
    push edx
    mov eax,1000h
    AllocateLocalLinear
    AllocateLdt
    or bx,7
    mov ecx,eax     
    CreateDataSelector32
    mov es,bx
    sub edx,ebp
    mov es:pvBase,edx
    pop edx
    pop ecx
    pop bx
    pop ds
;
    mov es:pvArbitrary,ecx
    mov es:pvModuleHandle,ebx
    mov es:pvProcessHandle,edx
    mov ds:p_fs,es
    mov ds:p_ds,fs
    mov ds:p_ss,fs
    mov ds:p_es,fs
    mov ds:p_cs,flat_code_sel
    mov ds:p_gs,0
    pop eax
    add eax,200h
    and ax,0F000h
    add eax,1000h
    AllocateLocalLinear
    sub edx,ebp
    mov dword ptr ds:p_rbx,edx
    mov es:pvFirstExcept,-1
    mov es:pvStackUserBottom,edx
    mov es:pvStackUserSize,eax
    add edx,eax
    sub edx,88h
    mov es:pvTEB,edx
    movzx eax,ds:p_id
    mov es:pvThreadHandle,eax
    mov fs:[edx+24h],eax
    mov dword ptr ds:p_rbp,edx
    sub edx,10h
    mov dword ptr ds:p_rcx,edx
    sub edx,100h
    mov es:pvTLSArray,edx
    sub edx,8
;
    mov es:pvTLSBitmap,edx
    mov dword ptr fs:[edx],-1
    mov dword ptr fs:[edx+4],-1
;
    mov eax,fs:[esi].peh_tls_va
    or eax,eax
    jz init_thread_no_tls
;
    push ecx
    push edx
;
    mov eax,fs:[esi].peh_tls_va
    add eax,edi
    mov esi,fs:[eax].tls_start_data_va
    mov ecx,fs:[eax].tls_end_data_va
    push eax
    sub ecx,esi
    mov eax,ecx
    and ax,0F000h
    add eax,1000h
    AllocateLocalLinear
    sub edx,ebp
    push es
    push edi
    mov edi,edx
    mov bx,fs
    mov es,bx
    rep movs byte ptr es:[edi],fs:[esi]
    pop edi
    pop es
    pop eax
    mov eax,fs:[eax].tls_index_va
    mov eax,fs:[eax]
    mov esi,es:pvTLSArray
    mov fs:[esi+4*eax],edx
    mov esi,es:pvTLSBitmap
    btr fs:[esi],eax
;
    pop edx
    pop ecx

init_thread_no_tls:
    sub edx,14h
    xor eax,eax
    mov es:pvStackUserTop,edx
    mov fs:[edx],eax                        ; reserved
    sub edx,4
    mov fs:[edx],eax                        ; reason
    sub edx,4
    mov eax,es:pvModuleHandle
    mov dword ptr fs:[edx],eax                  ; module handle
    sub edx,4
    xor eax,eax
    mov fs:[edx],eax                        ; return address
    sub edx,4
    mov dword ptr ds:p_rsp,edx
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    pop fs
    pop es
    ret
init_thread     Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           regs_to_user
;
;       DESCRIPTION:    Move registers to user-space
;
;       PARAMETERS:     EBP                Stack frame
;
;       RETURNS:        DS:ESI             User registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

thread_code_size  = 32

regs_init_start:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    popfd
    retn thread_code_size
regs_init_end:

regs_to_user   Proc far
    push eax
;
    mov ds,[ebp].load_ss
    mov esi,[ebp].load_esp
    sub esi,thread_code_size + 8 * 4
;
    mov [ebp].load_esp,esi
;
    mov eax,[ebp].load_eflags
    mov [esi].user_eflags,eax
;
    mov eax,[ebp].load_eax
    mov [esi].user_eax,eax
;
    mov eax,[ebp].load_ebx
    mov [esi].user_ebx,eax
;
    mov eax,[ebp].load_ecx
    mov [esi].user_ecx,eax
;
    mov eax,[ebp].load_edx
    mov [esi].user_edx,eax
;
    mov eax,[ebp].load_esi
    mov [esi].user_esi,eax
;
    mov eax,[ebp].load_edi
    mov [esi].user_edi,eax
;
    mov eax,[ebp].load_eip
    mov [esi].user_ret,eax
;
    push ds
    push es
    push esi
    push edi
;
    mov edi,esi
    add edi,8 * 4
    mov [ebp].load_eip,edi
    mov es,[ebp].load_ss
    mov eax,cs
    mov ds,eax
    mov eax,edi
    mov esi,OFFSET regs_init_start
    mov ecx,OFFSET regs_init_end - OFFSET regs_init_start
    rep movsb
;
    pop edi
    pop esi
    pop es
    pop ds
;
    pop eax
    ret
regs_to_user  Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           add_user_gate
;
;       DESCRIPTION:    Add call gate to user stack
;
;       PARAMETERS:     EBP                Stack frame
;                       BX                 Gate selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gate_init_start:
    retn thread_code_size
gate_init_end:

add_user_gate   Proc far
    push ds
    push es
    push eax
    push esi
    push edi
;
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    sub edi,thread_code_size + 4
    mov [ebp].load_esp,edi
;
    mov eax,[ebp].load_eip
    stosd
;
    mov [ebp].load_eip,edi
;
    mov al,9Ah
    stosb
;
    xor eax,eax
    stosd
;
    mov ax,bx
    stosw
;
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET gate_init_start
    mov ecx,OFFSET gate_init_end - OFFSET gate_init_start
    rep movsb
;
    pop edi
    pop esi
    pop eax
    pop es
    pop ds
    ret
add_user_gate  Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitUserStack
;
;           DESCRIPTION:    Setup register restore
;
;           PARAMETERS:     EBP                Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

thread_code_size  = 32

thread_init_start:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    clc
    retn thread_code_size
thread_init_end:

InitUserStack   Proc near
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    sub edi,thread_code_size + 6 * 4
    mov [ebp].load_esp,edi
;
    mov eax,[ebp].load_edi
    stosd
;
    mov eax,[ebp].load_esi
    stosd
;
    mov eax,[ebp].load_edx
    stosd
;
    mov eax,[ebp].load_ecx
    stosd
;
    mov eax,[ebp].load_eax
    stosd
;
    mov eax,[ebp].load_eip
    stosd
;
    mov [ebp].load_eip,edi
;
    mov eax,cs
    mov ds,eax
    mov eax,edi
    mov esi,OFFSET thread_init_start
    mov ecx,OFFSET thread_init_end - OFFSET thread_init_start
    rep movsb
    ret
InitUserStack  Endp                  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddUserStack
;
;           DESCRIPTION:    Add call frame
;
;           PARAMETERS:     BX                 Dll ID
;                           EDX                DLL code
;                           EBP                Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

thread_user_start:
    pop edx
    pop ebx
    pop eax
    retn
thread_user_back:
    retn thread_code_size
thread_user_end:

AddUserStack    Proc near
    mov ax,flat_sel
    mov ds,ax
    mov gs,bx
;    
    mov ebx,gs:lib_header
    mov eax,ds:[ebx].peh_entry_point
    or eax,eax
    jz ausDone
;
    add eax,gs:mod_base
    push eax
;
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    sub edi,thread_code_size + 6 * 4
    mov [ebp].load_esp,edi
;
    mov eax,edx
    stosd
;
    movzx eax,gs:mod_id
    stosd
;
    movzx eax,gs:lib_init_param
    stosd
;
    pop eax
    stosd
;
    mov eax,edi
    add eax,8
    add eax,OFFSET thread_user_back - OFFSET thread_user_start
    stosd
;
    mov eax,[ebp].load_eip
    stosd
;
    mov [ebp].load_eip,edi
;
    mov eax,cs
    mov ds,eax
    mov eax,edi
    mov esi,OFFSET thread_user_start
    mov ecx,OFFSET thread_user_end - OFFSET thread_user_start
    rep movsb

ausDone:
    ret
AddUserStack    Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PutOnUserStack
;
;           DESCRIPTION:    Put address on call frame
;
;           PARAMETERS:     ESI                Address
;                           EDX                P
;                           EBP                Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

put_user_start:
    retn
put_user_back:
    retn thread_code_size
put_user_end:

PutOnUserStack    Proc near
    mov ax,flat_sel
    mov ds,ax
    mov gs,bx
;    
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    sub edi,thread_code_size + 4 * 4
    mov [ebp].load_esp,edi
;
    mov eax,esi
    stosd
;
    mov eax,edi
    add eax,12
    add eax,OFFSET put_user_back - OFFSET put_user_start
    stosd
;
    mov eax,edx
    stosd
;
    mov eax,[ebp].load_eip
    stosd
;
    mov [ebp].load_eip,edi
;
    mov eax,cs
    mov ds,eax
    mov eax,edi
    mov esi,OFFSET put_user_start
    mov ecx,OFFSET put_user_end - OFFSET put_user_start
    rep movsb
    ret
PutOnUserStack    Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitDebugUserStack
;
;           DESCRIPTION:    Init debugger stack
;
;           PARAMETERS:     EBP                Stack frame
;                           ESI                Return address from call
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDebugUserStack   Proc near
    push ds
    push es
    pushad
;
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    sub edi,4
    mov [ebp].load_esp,edi
;
    mov eax,esi
    stosd
;
    popad
    pop es
    pop ds
    ret
InitDebugUserStack   Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FixupDebugUserStack
;
;           DESCRIPTION:    Fixup debugger stack
;
;           PARAMETERS:     EBP                Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

thread_debug_start:
    add esp,4
    retn thread_code_size
thread_debug_end:

FixupDebugUserStack   Proc near
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov ds,ax
;
    mov es,[ebp].load_ss
    mov edi,[ebp].load_esp
    sub edi,thread_code_size + 4
    mov [ebp].load_esp,edi
;
    mov eax,[ebp].load_eip
    stosd
    mov [ebp].load_eip,edi
;
    mov eax,cs
    mov ds,eax
    mov eax,edi
    mov esi,OFFSET thread_debug_start
    mov ecx,OFFSET thread_debug_end - OFFSET thread_debug_start
    rep movsb
;
    popad
    pop es
    pop ds
    ret
FixupDebugUserStack   Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_thread
;
;           DESCRIPTION:    Start thread
;
;           PARAMETERS:     EBP                Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_thread    PROC far
    push ds
    push es
    push gs
    pushad
;    
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
;
    mov edx,[ebp].load_eip
    mov ds,ds:app_mod_sel
    mov ax,ds:mod_debug_id
    or ax,ax
    jz start_thread_notify
;
    call AllocateKernelEvent
    call CreateThreadEvent
    call SendEvent

start_thread_notify:    
    call InitUserStack
;
    GetThread
    mov ds,ax
    mov dx,ds:p_prog_id
    mov ax,1

start_thread_dlls_loop:
    mov bx,dx
    GetModuleByIndex
    jc start_thread_done
;
    ModuleIdToSel
    jc start_thread_dlls_next
;    
    push eax
    push edx
;
    mov edx,2
    call AddUserStack
;
    pop edx
    pop eax

start_thread_dlls_next:
    inc ax
    jmp start_thread_dlls_loop

start_thread_done:
    popad
    pop gs
    pop es
    pop ds
    ret
start_thread    Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeThreadUser
;
;           DESCRIPTION:    Free thread, user callback part
;
;           PARAMETERS:     EBP                Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread_user     Proc far
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel

    mov ax,ds:mod_debug_id
    or ax,ax
    jz ftuDebugOk
;
    call FreeKernelEvent

ftuDebugOk:
    GetThread
    mov ds,ax
    mov dx,ds:p_prog_id
    mov ax,1

ftuDllsLoop:
    mov bx,dx
    GetModuleByIndex
    jc ftuDone
;
    ModuleIdToSel
    jc ftuDllsNext
;    
    push eax
    push edx
;
    mov edx,3
    call AddUserStack
;
    pop edx
    pop eax

ftuDllsNext:
    inc ax
    jmp ftuDllsLoop

ftuDone:
    ret
free_thread_user     Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeThreadKernel
;
;           DESCRIPTION:    Free thread, kernel part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread_kernel     Proc far
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel    
    mov ds,ds:app_mod_sel   
    mov ax,ds:mod_debug_id
    or ax,ax
    jz ftkNoDebug
;
    call TerminateThreadEvent
    call SendEvent
    
ftkNoDebug:
    mov ax,system_data_sel
    mov ds,ax
    mov ebp,ds:flat_base
;
    mov ebx,fs:pvModuleHandle
    ModuleIdToSel
    mov es,ebx
    mov ax,flat_data_sel
    mov ds,eax
    mov esi,es:lib_header
    mov edi,es:mod_base
    mov eax,[esi].peh_tls_va
    or eax,eax
    jz ftkNoTls
;
    add eax,edi
    mov edx,[eax].tls_index_va
    mov edx,[edx]
    mov esi,fs:pvTLSArray
    mov edx,[esi+4*edx]
    add edx,ebp
;
    mov ecx,[eax].tls_end_data_va
    sub ecx,[eax].tls_start_data_va
    FreeLinear

ftkNoTls:
    mov edx,fs:pvStackUserBottom
    add edx,ebp
    mov ecx,fs:pvStackUserSize
    FreeLinear      
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
    ret
free_thread_kernel     Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CopyForkPages
;
;           DESCRIPTION:    Copy pages in forked process
;
;           PARAMETERS:     EDX         Linear address
;                           ECX         Number of pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyForkPages   Proc near
    push ds
    push es
    pushad
;
    mov ax,flat_sel
    mov ds,ax
    mov es,ax
;
    mov esi,edx
    push ecx
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    pop ecx

cfpLoop:
    mov edx,esi
    GetPageEntry
    test al,1
    jz cfpNext
;
    test ax,400h
    jz cfpNext
;
    push ecx
    push esi
    push edi
    mov ecx,400h
    rep movs dword ptr es:[edi],ds:[esi]
    pop edi
    pop esi
    pop ecx
;
    mov edx,edi
    GetPageEntry
;
    mov edx,esi
    SetPageEntry
;
    mov edx,edi
    xor eax,eax
    xor ebx,ebx
    SetPageEntry

cfpNext:
    add esi,1000h
    loop cfpLoop
;
    mov ecx,1000h
    FreeLinear
;
    popad
    pop es
    pop ds
    ret
CopyForkPages   Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           fork_proc
;
;           DESCRIPTION:    Fork
;
;           RETURNS:        Child:  EAX = 0
;                           Parent: EAX = child thread selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fork_proc      Proc far
    push ebx
    push ecx
;
    GetThread
    push es
    mov es,ax
    lock and es:p_flags,NOT THREAD_FLAG_FORK_COMPLETED
    pop es
;
    push eax
;
    mov ebx,fs:pvModuleHandle
    ModuleIdToSel
    push ebx
;
    mov eax,fs:pvFirstExcept
    push eax
;
    mov eax,fs:pvArbitrary
    push eax
;
    mov eax,fs:pvStackUserTop
    push eax
;
    mov eax,fs:pvStackUserBottom
    push eax
;
    mov eax,fs:pvStackUserSize
    push eax
;
    mov eax,fs:pvTLSBitmap
    push eax
;
    mov eax,fs:pvTLSArray
    push eax
;
    mov eax,fs:pvBase
    push eax
;
    ClearSignal
    ForkProcess
    or ax,ax
    jz fork_child

fork_parent:
    push es
    mov es,ax
;
    push ds
    push dx
;
    movzx eax,bx
;
    pop dx
    pop ds
;
    GetThread
    mov es,ax

fork_wait_child:
    test es:p_flags,THREAD_FLAG_FORK_COMPLETED
    jnz fork_child_completed
;
    WaitForSignal
    jmp fork_wait_child
    
fork_child_completed:
    mov ax,100
    WaitMilliSec
;
    pop es
    pop ebx
    pop ebx
    pop ebx
    pop ebx
    pop ebx
    pop ebx
    pop ebx
    pop ebx
    pop ebx
    pop ebx
;
    pop ecx
    pop ebx
    jmp fork_done

fork_child:
    push ds
    push es
    push bx
    push ecx
    push edx
;
    mov ax,system_data_sel
    mov fs,ax
;
    mov eax,1000h
    AllocateLocalLinear
    AllocateLdt
    or bx,7
    mov ecx,eax     
    CreateDataSelector32
    mov es,bx
    sub edx,fs:flat_base
    mov es:pvBase,edx
;
    mov ax,es
    mov fs,ax
;
    pop edx
    pop ecx
    pop bx
    pop es
    pop ds
;
    pop eax
    mov fs:pvBase,eax
;
    pop eax
    mov fs:pvTLSArray,eax
;
    pop eax
    mov fs:pvTLSBitmap,eax
;
    pop eax
    mov fs:pvStackUserSize,eax
;
    pop eax
    mov fs:pvStackUserBottom,eax
;
    pop eax
    mov fs:pvStackUserTop,eax
;
    pop eax
    mov fs:pvArbitrary,eax
;
    pop eax
    mov fs:pvFirstExcept,eax
;
    pop eax
;
    push es
    mov es,ax
;    SetModule
    pop es
;
    mov al,32
    SetBitness
;
    push ds
;
    GetThread
    mov ds,ax
;
    movzx eax,ds:p_id
    mov fs:pvThreadHandle,eax
    mov fs:pvProcessHandle,eax
;
    mov ds,ds:p_app_sel        
    movzx eax,ds:app_mod_id
    mov fs:pvModuleHandle,eax
;
    mov ds,ds:app_mod_sel
    mov ax,ds:mod_debug_id
    or ax,ax
    jz fork_notify_ok
;
    push ds
    push es
    pushad
;
    mov edx,stack0_size - 10h
    mov edx,ss:[edx]
;
    call CreateThreadEvent
    call SendEvent
;
    popad
    pop es
    pop ds

fork_notify_ok:    
    push edx
    mov edx,fs:pvStackUserBottom
    mov ecx,fs:pvStackUserSize
    dec ecx
    shr ecx,12
    inc ecx
    call CopyForkPages
    pop edx
;
    pop ds
;
    pop ebx
;
    mov ds,bx
    lock or ds:p_flags,THREAD_FLAG_FORK_COMPLETED
    Signal
;
    pop ecx
    pop ebx
    xor eax,eax

fork_done:    
    ret
fork_proc  Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_proc
;
;           DESCRIPTION:    Close app callback
;
;           PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_proc      Proc far
    ret
close_proc      Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartWaitForDebugEvent
;
;           DESCRIPTION:    Start wait for an debug event from process
;
;           PARAMETERS:         BX    Debugged lib_sel
;               ES    Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_debug_event Proc far
    push ds
    push ax
;
    mov ds,bx
    ClearSignal
    mov ds:lib_debug_wait,es

    mov ax,ds:lib_events
    or ax,ax
    jz start_wait_done
;
    mov ds:lib_debug_wait,0
    SignalWait

start_wait_done:    
    pop ax
    pop ds  
    ret
start_wait_for_debug_event Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopWaitForDebugEvent
;
;           DESCRIPTION:    Stop wait for an debug event from process
;
;           PARAMETERS:         BX      Debugged lib_sel
;               ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_debug_event Proc far
    push ds
;
    mov ds,bx
    mov ds:lib_debug_wait,0
;       
    pop ds  
    ret
stop_wait_for_debug_event Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsDebugEventIdle
;
;           DESCRIPTION:    Check if debug event is idle
;
;           PARAMETERS:         BX      Debugged lib_sel
;               ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_debug_event_idle Proc far
    push ds
    push ax
;
    mov ds,bx
    mov ax,ds:lib_events
    or ax,ax
    clc
    je is_idle_done
;
    stc

is_idle_done:
    pop ax
    pop ds  
    ret
is_debug_event_idle Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDebugEvent
;
;           DESCRIPTION:    Get debug event from process
;
;           PARAMETERS:         BX    Debugged lib_sel
;
;       RETURNS:    AX    Thread ID
;               BL    Event type  
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event Proc far
    push ds
    push es
    push si
;
    mov ds,bx
    RequestSpinlock ds:lib_spinlock
    mov ax,ds:lib_events
    or ax,ax
    jz gdeLeaveFail
;       
    mov es,ax
    mov ax,es:event_prev
    cmp ax,ds:lib_events
    push ds
    mov ds:lib_events,ax
    mov si,es:event_next
    mov ds,ax
    mov ds:event_next,si
    mov ds,si
    mov ds:event_prev,ax
    pop ds
    jne gdeRemoved
;
    mov ds:lib_events,0

gdeRemoved:
    ReleaseSpinlock ds:lib_spinlock
;
    mov ds:lib_curr_event,es
    mov bl,es:event_code
    mov ax,es:event_thread_id
    clc
    jmp gdeDone

gdeLeaveFail:
    ReleaseSpinlock ds:lib_spinlock
    xor bl,bl
    xor ax,ax
    stc

gdeDone:
    pop si
    pop es
    pop ds  
    ret
get_debug_event Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDebugEventData
;
;           DESCRIPTION:    Get event data
;
;           PARAMETERS:         BX    Debugged lib_sel
;               ES:EDI     Event buffer
;               
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event_data Proc far
    push ds
    push eax
    push ebx
    push ecx
    push esi
;       
    mov ds,bx
    mov ds,ds:lib_curr_event
;       
    mov esi,SIZE event_struc
    movzx ecx,ds:event_size
    push edi
    rep movs byte ptr es:[edi],ds:[esi]
    pop edi
;
    mov al,ds:event_code
;    
    cmp al,EVENT_CREATE_PROCESS
    je gdedDuplFile
    cmp al,EVENT_LOAD_DLL
    jne gdedDone

gdedDuplFile:
    mov bx,es:[edi+4]
    mov ds,bx
    mov bx,ds:mod_id
    mov es:[edi+4],bx   
    mov ds:lib_local_handle,bx
;
    mov ax,es:[edi]
    mov cx,es:[edi+2]
    DuplFileInfo
    movzx eax,bx
    mov es:[edi],eax
;
    jmp gdedDone

gdedDone:
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop ds  
    ret
get_debug_event_data Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearDebugEvent
;
;           DESCRIPTION:    Clear debug event
;
;           PARAMETERS:         BX      Debugged lib_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_debug_event Proc far
    push ds
    push es
    push bx
;
    mov ds,bx
    mov bx,ds:lib_curr_event
    or bx,bx
    jz clear_debug_done
;
    mov es,bx   
    mov al,es:event_code
    cmp al,EVENT_KERNEL
    je clear_debug_done
;    
    FreeMem

clear_debug_done:
    mov ds:lib_curr_event,0
;       
    pop bx
    pop es
    pop ds
    ret
clear_debug_event Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ContinueDebugEvent
;
;           DESCRIPTION:    Continue debugged thread
;
;           PARAMETERS:         EAX         Thread
;               BX      Debugged lib_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

continue_debug_event Proc far
    push es
    push bx
    push cx
    push dx
    push si
;
    mov bx,ax
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov ax,[si]
    or ax,ax
    jz continue_debug_signal
;
    mov dx,ax

continue_debug_loop:
    mov ds,ax
    cmp bx,ds:p_id
    je continue_debug_found
;
    mov ax,ds:p_next
    cmp ax,dx
    jne continue_debug_loop
    jmp continue_debug_signal

continue_debug_found:
    mov bx,ds
    mov ax,system_data_sel
    mov ds,ax
    mov si,OFFSET debug_list
    mov [si],bx
    Wake
    jmp continue_debug_done
    
continue_debug_signal:
    ThreadToSel
    jc continue_debug_done
;    
    Signal

continue_debug_done:
    xor ax,ax
    mov ds,ax
;    
    pop si
    pop dx
    pop cx
    pop bx
    pop es
    ret
continue_debug_event Endp

                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyPeException
;
;           DESCRIPTION:    Notify of a exception
;
;           PARAMETERS:     EBP         Exception frame
;                           EAX         Exception code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exc_tab:
e00 DD 0C000008Eh
e01 DD 080000004h
e02 DD 0
e03 DD 080000003h
e04 DD 0C0000095h
e05 DD 0C000008Ch
e06 DD 0C000001Dh
e07 DD 0
e08 DD 0
e09 DD 0
e0A DD 0
e0B DD 0
e0C DD 0C00000FDh
e0D DD 0C0000096h
e0E DD 0C0000005h
e0F DD 0

notify_pe_exception_name DB 'Notify Pe Exception',0

notify_pe_exception     Proc far
    push ds
    push dx
;
    push ebx
    mov ebx,fs:pvModuleHandle
    ModuleIdToSel
    mov ds,ebx
    pop ebx
;       
    mov dx,ds:mod_debug_id
    or dx,dx
    jz neDone
;       
    pop dx
    pop ds
;
    sub esp,4
    push dword ptr 0
    push ebp
    mov ebp,esp
    push eax
    push ebx
;
    push ecx
    push dx
;    
    mov ebx,OFFSET exc_tab
    mov ecx,10h
    mov dl,14h
    mov dh,0

find_exc_loop:    
    cmp eax,cs:[ebx]
    jne find_exc_next
;
    mov dl,dh

find_exc_next:
    add ebx,4
    inc dh
    loop find_exc_loop
;
    movzx bx,dl 
    pop dx
    pop ecx   
;    
    push bx
    push ds
    push es
;
    mov ebx,fs:pvModuleHandle
    ModuleIdToSel
    mov ds,ebx
    call ExceptionEvent
;
    mov ds,[ebp].trap_ss
    mov ebx,[ebp].trap_esp
;
    mov eax,[ebx]
    mov [ebp].trap_eax,eax
    add ebx,4
;
    mov ax,[ebx]
    mov [ebp].trap_pds,ax
    add ebx,4
;
    mov eax,[ebx]
    mov [ebp].trap_ebp,eax
    add ebx,4
;
    mov ax,[ebx]
    push ax
    add ebx,4
;
    add ebx,12
    mov eax,[ebx]
    mov [ebp].trap_eip,eax
    add ebx,4
;
    mov ax,[ebx]
    mov [ebp].trap_cs,ax
    add ebx,4
;
    mov eax,[ebx]
    SetFlags
    mov [ebp].trap_eflags,eax  
    add ebx,4
;
    add ebx,8
    mov [ebp].trap_esp,ebx
;
    GetThread
    push es
    mov es,ax
    mov ax,es:p_id
    pop es
    mov es:event_thread_id,ax
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds,ds:app_mod_sel
    LockTask
    RequestSpinlock ds:lib_spinlock
;
    mov ax,ds:lib_events
    or ax,ax
    je neEmpty
;
    push ds
    push si
    mov ds,ax
    mov si,ds:event_prev
    mov ds:event_prev,es
    mov ds,si
    mov ds:event_next,es
    mov es:event_next,ax
    mov es:event_prev,si
    pop si
    pop ds
    jmp neInsDone

neEmpty:
    mov es:event_next,es
    mov es:event_prev,es

neInsDone:
    mov ds:lib_events,es
    ReleaseSpinlock ds:lib_spinlock
    xor ax,ax
    mov es,ax
;
    mov ax,ds:lib_debug_wait
    or ax,ax
    jz neSignalDone
;       
    mov es,ax
    SignalWait

neSignalDone:
    mov ds:lib_suppress,1
    pop ax
    pop es
    LockedDebugException

neDone:
    pop dx
    pop ds
    ret
notify_pe_exception Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AllocateMem
;
;           DESCRIPTION:    Allocate memory
;
;           PARAMETERS:         EAX     Number of bytes
;
;           RETURNS:        EDX Offset within flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem    PROC far
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    dec eax
    and ax,0F000h
    add eax,1000h
    mov ecx,eax
    push ecx
    AllocateLocalLinear
    mov ax,system_data_sel
    mov ds,ax
    sub edx,ds:flat_base
    mov ax,flat_sel
    mov es,ax
;
    push edx
    mov eax,SIZE pe_mem_struc
    AllocateLocalLinear
    mov edi,edx
    pop edx
;        
    pop ecx
    mov es:[edi].mem_base,edx
    mov es:[edi].mem_size,ecx
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds,ds:app_mod_sel   
    EnterSection ds:lib_section     
;
    mov eax,ds:lib_mem_blocks
    or eax,eax
    je alloc_ins_empty
;
    mov esi,es:[eax].mem_prev
    mov es:[eax].mem_prev,edi
    mov es:[esi].mem_next,edi
    mov es:[edi].mem_next,eax
    mov es:[edi].mem_prev,esi
    jmp alloc_ins_done

alloc_ins_empty:
    mov es:[edi].mem_next,edi
    mov es:[edi].mem_prev,edi

alloc_ins_done:
    mov ds:lib_mem_blocks,edi
    LeaveSection ds:lib_section     
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
allocate_mem    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FreeMem
;
;           DESCRIPTION:    Free memory
;
;           PARAMETERS:         EDX Offset within flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_mem    PROC far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds,ds:app_mod_sel   
    mov ax,flat_sel
    mov es,ax
    EnterSection ds:lib_section     

free_mem_more:
    mov eax,ds:lib_mem_blocks
    or eax,eax
    jz free_mem_failed
;
    mov esi,eax
free_mem_loop:
    cmp edx,es:[eax].mem_base
    je free_mem_ok

free_mem_next:
    mov eax,es:[eax].mem_next
    cmp eax,esi
    jne free_mem_loop

free_mem_failed:
    jmp free_mem_done

free_mem_ok:
    mov edi,eax
;
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov edx,es:[edi].mem_base
    add edx,ds:flat_base
    pop ds
;
    mov ecx,es:[edi].mem_size
    FreeLinear
    mov ds:lib_mem_blocks,edi
    mov eax,es:[edi].mem_prev
    cmp eax,ds:lib_mem_blocks
    pushf
    mov ds:lib_mem_blocks,eax
    mov esi,es:[edi].mem_next
    mov es:[eax].mem_next,esi
    mov es:[esi].mem_prev,eax
;    
    mov edx,edi
    mov ecx,SIZE pe_mem_struc
    FreeLinear
    popf
    jne free_mem_done

free_mem_last_block:
    mov ds:lib_mem_blocks,0

free_mem_done:
    LeaveSection ds:lib_section     
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
free_mem    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DebugAllocateMem
;
;           DESCRIPTION:    Allocate memory, debug mode
;
;           PARAMETERS:         EAX     Number of bytes
;
;           RETURNS:        EDX Offset within flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_allocate_mem      PROC far
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    push eax
    dec eax
    and ax,0F000h
    add eax,1000h
    mov ecx,eax
    push ecx
    AllocateDebugLocalLinear
    mov ax,system_data_sel
    mov ds,ax
    sub edx,ds:flat_base
    mov ax,flat_sel
    mov es,ax
;
    push edx
    mov eax,SIZE pe_mem_struc
    AllocateLocalLinear
    mov edi,edx
    pop edx
;        
    pop ecx
    mov es:[edi].mem_base,edx
    mov es:[edi].mem_size,ecx
    pop eax
    mov es:[edi].mem_alloc,eax
;
    cmp eax,ecx
    je debug_alloc_fill_ok
;
    push es
    push ecx
    push edi
    mov edi,edx
    add edi,eax
    sub ecx,eax
;
    mov ax,flat_data_sel
    mov es,ax   
    mov al,0A5h
    rep stos byte ptr es:[edi]
    pop edi
    pop ecx
    pop es

debug_alloc_fill_ok:
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds,ds:app_mod_sel   
    EnterSection ds:lib_section     
;
    mov eax,ds:lib_mem_blocks
    or eax,eax
    je debug_alloc_ins_empty
;
    mov esi,es:[eax].mem_prev
    mov es:[eax].mem_prev,edi
    mov es:[esi].mem_next,edi
    mov es:[edi].mem_next,eax
    mov es:[edi].mem_prev,esi
    jmp debug_alloc_ins_done

debug_alloc_ins_empty:
    mov es:[edi].mem_next,edi
    mov es:[edi].mem_prev,edi

debug_alloc_ins_done:
    mov ds:lib_mem_blocks,edi
    LeaveSection ds:lib_section     
;
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    ret
debug_allocate_mem      ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DebugFreeMem
;
;           DESCRIPTION:    Free memory, debug mode
;
;           PARAMETERS:         EDX Offset within flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_free_mem  PROC far
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov ds,ds:app_mod_sel   
    mov ax,flat_sel
    mov es,ax
    EnterSection ds:lib_section     

debug_free_mem_more:
    mov eax,ds:lib_mem_blocks
    or eax,eax
    jz debug_free_mem_failed
;
    mov esi,eax
    
debug_free_mem_loop:
    cmp edx,es:[eax].mem_base
    je debug_free_mem_ok

debug_free_mem_next:
    mov eax,es:[eax].mem_next
    cmp eax,esi
    jne debug_free_mem_loop

debug_free_mem_failed:
    int 3
    jmp free_mem_done

debug_free_mem_ok:
    mov edi,eax
;    
    mov edx,es:[edi].mem_base
    mov ecx,es:[edi].mem_size
    mov eax,es:[edi].mem_alloc
    cmp eax,ecx
    je debug_free_mem_check_done
;
    push ecx
    push edi
    mov edi,edx
    add edi,eax
    sub ecx,eax
;
    mov al,0A5h
    repe scas byte ptr es:[edi]
    pop edi
    pop ecx
;
    jz debug_free_mem_check_done
;
    int 3
    
debug_free_mem_check_done:
    push ds
    mov ax,system_data_sel
    mov ds,ax
    mov edx,es:[edi].mem_base
    add edx,ds:flat_base
    pop ds
    mov ecx,es:[edi].mem_size
    FreeLinear
;
    mov ds:lib_mem_blocks,edi
    mov eax,es:[edi].mem_prev
    cmp eax,ds:lib_mem_blocks
    pushf
    mov ds:lib_mem_blocks,eax
    mov esi,es:[edi].mem_next
    mov es:[eax].mem_next,esi
    mov es:[esi].mem_prev,eax
;    
    mov edx,edi
    mov ecx,SIZE pe_mem_struc
    FreeLinear
    popf
    jne debug_free_mem_done

debug_free_mem_last_block:
    mov ds:lib_mem_blocks,0

debug_free_mem_done:
    LeaveSection ds:lib_section     
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
debug_free_mem  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReservePEMem
;
;           DESCRIPTION:    Reserve PE memory
;
;           PARAMETERS:         EAX     Number of bytes
;                           BX  Handle of owner
;                           EDX Offset within flat selector
;
;           RETURNS:        NC      SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reserve_pe_mem_name     DB 'Reserve PE Mem',0

reserve_pe_mem  PROC far
    push eax
    push edx
;       
    push ds
    push bx
    mov bx,system_data_sel
    mov ds,bx
    add edx,ds:flat_base
    pop bx
    pop ds
;
    cmp edx,flat_size
    jnc reserve_pe_mem_done
;
    dec eax
    and ax,0F000h
    add eax,1000h
    ReserveLocalLinear

reserve_pe_mem_done:
    pop edx
    pop eax
    ret
reserve_pe_mem  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ShowExceptionText
;
;           DESCRIPTION:    Decide whether app should show exception text and
;               exit or stop execution on exception.
;
;           RETURNS:        EAX  0 stop execution
;                1 show exception text and exit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_exception_text_name    DB 'Show Exception Text',0

show_exception_text     PROC far
    push es
    push ebx
;    
    mov ebx,fs:pvModuleHandle
    ModuleIdToSel
    mov es,ebx
    or ebx,ebx
    jz setStop
;
    mov ax,es:mod_debug_id
    or ax,ax
    jnz setStop
;
    GetWatchdogTics
    or eax,eax
    jnz setStop

setCont:
    mov eax,1
    jmp setDone

setStop:
    xor eax,eax 

setDone:
    pop ebx
    pop es    
    ret
show_exception_text     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           FatalErrorExit
;
;           DESCRIPTION:    Fatal error exit handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


fatal_error_exit     PROC far
    mov ax,wd_code_sel
    verr ax
    jnz feeDone
;
    mov ax,2500
    WaitMilliSec
;
    SoftReset

feeDone:
    ret
fatal_error_exit     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_current_dll
;
;           DESCRIPTION:    Get current DLL
;
;       PARAMETERS:         ES:EDI  entry point
;
;           RETURNS:        BX      Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_current_dll    Proc far
    push ds
    push es
    push eax
    push edx
    push edi
;       
    mov edx,edi
    mov ax,flat_data_sel
    mov ds,ax
    and dx,0F000h
    call FindLib
    mov bx,es
;
    pop edi
    pop edx
    pop eax
    pop es
    pop ds    
    ret
get_current_dll     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           unload_dll
;
;           DESCRIPTION:    Unload DLL
;
;       PARAMETERS:         BX      Lib sel
;                           EBP     Stack frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wep_name DB 'WEP', 0

unload_dll    Proc far
    mov es,bx
    mov dx,es:mod_debug_id
    or dx,dx
    jz udNotifyDone
;
    push es
    mov ax,es
    mov ds,ax
    call FreeDllEvent
    call SendEvent
    pop es

udNotifyDone:
    push es
    call InitUserStack
;
    mov edx,0
    call AddUserStack
    pop es
;
    push es
    mov bx,es:mod_id
    mov eax,cs
    mov es,eax
    mov edi,OFFSET wep_name
    GetModuleProc
    pop es
    jc udWepOk
;
    push es
    call PutOnUserStack
    pop es

udWepOk:
    mov ax,flat_data_sel
    mov ds,ax
    mov edi,es:mod_base
    call FreeImportedDlls
    ret
unload_dll    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           free_dll
;
;           DESCRIPTION:    Free DLL
;
;       PARAMETERS:         BX      Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll    Proc far
    mov ax,system_data_sel
    mov ds,ax
    mov es,bx
;
    mov edx,es:mod_base
    add edx,ds:flat_base
    mov ecx,es:mod_size
    FreeLinear
    ret
free_dll    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleProc
;
;           DESCRIPTION:    Get module procedure
;
;       PARAMETERS:         BX          Lib sel
;                           ES:EDI  Proc name
;                           
;           RETURNS:        DS:ESI  Proc address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_proc Proc far
    push eax
    push ebx
    push ecx
    push edx
;
    push es
    mov es,bx
    mov edx,es:mod_base
    mov ax,flat_data_sel
    mov ds,ax
    mov esi,es:lib_header
    mov esi,[esi].peh_export_va
    pop es
;       
    or esi,esi
    jz get_proc_fail
;
    add esi,edx
    mov ecx,[esi].exp_name_count
    mov ebx,[esi].exp_name_va
    add ebx,edx
    or ecx,ecx
    jz get_proc_fail

get_proc_loop:
    push esi
    push edi
    mov esi,[ebx]
    add esi,edx

get_proc_search:
    mov al,[esi]
    mov ah,es:[edi]
    cmp al,ah
    jne get_proc_next
;
    or al,ah
    jz get_proc_ok
;
    inc esi
    inc edi
    jmp get_proc_search

get_proc_next:
    pop edi
    pop esi
    jz get_proc_ok
;
    add ebx,4
    loop get_proc_loop

get_proc_fail:
    xor esi,esi
    stc
    jmp get_proc_done

get_proc_ok:
    pop edi
    pop esi
    sub ebx,[esi].exp_name_va
    sub ebx,edx
    shr ebx,1
    mov eax,[esi].exp_ordinal_va
    add eax,edx
    movzx ebx,word ptr [eax+ebx]
    shl ebx,2   
    add ebx,[esi].exp_entry_point_va
    add ebx,edx
    mov esi,[ebx]
    add esi,edx
    clc

get_proc_done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
get_module_proc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetModuleName
;
;           DESCRIPTION:    Get module name
;
;       PARAMETERS:         BX          Handle
;                           ECX         Max name size
;                           ES:EDI  Name buffer
;                           
;           RETURNS:        EAX         Bytes copied
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_name Proc far
    or ecx,ecx
    clc
    jz get_name_done
;
    push ds
    push ebx
    push ecx
    push esi
    push edi
;
    xor eax,eax
    mov ds,bx
    xor ebx,ebx
    mov esi,OFFSET lib_name
get_name_loop:
    lodsb
    stos byte ptr es:[edi]
    or al,al
    jz get_name_ok
    inc ebx
    sub ecx,1
    jnz get_name_loop
;
    mov byte ptr es:[edi-1],0

get_name_ok:
    mov eax,ebx
;       
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop ds
    clc

get_name_done:
    ret
get_module_name Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDllResource
;
;           DESCRIPTION:    Get DLL resource
;
;       PARAMETERS:         BX      Lib sel
;                           EAX         Resource id
;                           EDX         Resource type
;                           
;           RETURNS:        DS:ESI  Resource VA
;                           ECX         Resource size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_resource    Proc far
    push eax
    push ebx
    push edx
    push edi
    push ebp
;
    mov edi,eax
    mov ebp,edx
;
    push es
    mov es,bx
    mov edx,es:mod_base
    mov esi,es:lib_header
    mov cx,flat_data_sel
    mov ds,cx
    mov ecx,[esi].peh_resource_size
    mov esi,[esi].peh_resource_va
    add esi,edx
    mov edx,esi
    movzx ecx,[esi].res_ids
    add esi,OFFSET res_data
    or ecx,ecx
    jz get_resource_fail_pop

get_resource_type_loop:
    cmp ebp,[esi]
    je get_resource_type_found
;
    add esi,8
    loop get_resource_type_loop
    jmp get_resource_fail_pop

get_resource_type_found:
    mov eax,[esi+4]
    test eax,80000000h
    jz get_resource_fail_pop
;
    and eax,7FFFFFFFh
    mov esi,eax
    add esi,edx
    movzx ecx,[esi].res_ids
    add esi,OFFSET res_data
    or ecx,ecx
    jz get_resource_fail_pop
;
    mov eax,edi
    cmp ebp,6
    jne get_resource_id_loop
;
    shr eax,4
    inc eax

get_resource_id_loop:
    cmp eax,[esi]
    je get_resource_id_found
;
    add esi,8
    loop get_resource_id_loop
    jmp get_resource_fail_pop

get_resource_id_found:
    and edi,0Fh
    mov eax,[esi+4]
    test eax,80000000h
    jz get_resource_found
;
    and eax,7FFFFFFFh
    mov esi,eax
    add esi,edx
    movzx ecx,[esi].res_ids
    add esi,OFFSET res_data
    or ecx,ecx
    jnz get_resource_id_found
    jmp get_resource_fail_pop

get_resource_found:
    add eax,edx
    mov ecx,[eax+4]
    mov esi,[eax]
    add esi,es:mod_base
    cmp ebp,6
    jne get_resource_ok_pop

get_resource_entry_loop:
    movzx ecx,word ptr [esi]
    or edi,edi
    jz get_resource_ok
;
    add esi,ecx
    add esi,ecx
    add esi,2
    dec edi
    jmp get_resource_entry_loop

get_resource_ok:    
    add esi,2

get_resource_ok_pop:
    pop es
    clc
    jmp get_resource_done

get_resource_fail_pop:
    pop es

get_resource_fail:
    xor esi,esi
    stc
    jmp get_resource_done

get_resource_done:
    pop ebp
    pop edi
    pop edx
    pop ebx
    pop eax
    ret
get_resource    Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetExeName
;
;           DESCRIPTION:    Get exe-file name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exe_name    Proc far
    push ds
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
;
    mov edi,ds:app_name
    or edi,edi
    jnz get_exe_done
;       
    mov esi,OFFSET app_exe_name

get_exe_size_loop:
    lodsb
    or al,al
    jnz get_exe_size_loop
;
    mov eax,esi
    sub eax,OFFSET app_exe_name
    mov ecx,eax
    AllocateAppMem
    mov edi,edx
    mov esi,OFFSET app_exe_name
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov ds:app_name,edx
    mov edi,edx

get_exe_done:
    clc
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
get_exe_name    Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetEnv
;
;           DESCRIPTION:    Get environment block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env Proc far
    push ds
    push eax
    push ebx
    push ecx
    push edx
    push esi
;
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov edi,ds:app_env
    or edi,edi
    jnz get_env_done
;       
    LockProcEnv
    mov ds,bx
    xor esi,esi

get_env_size_loop:
    lodsb
    or al,al
    jnz get_env_size_loop
;
    lodsb
    or al,al
    jnz get_env_size_loop
;
    mov ecx,esi
    mov eax,ecx
    AllocateAppMem
    mov edi,edx
    xor esi,esi
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov ds:app_env,edx
    mov edi,edx
;
    UnlockProcEnv

get_env_done:
    clc
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
get_env Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetCmdLine
;
;           DESCRIPTION:    Get command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cmd_line    Proc far
    push ds
    push ax
;       
    GetThread
    mov ds,ax
    mov ds,ds:p_app_sel
    mov edi,ds:app_cmd_line
;       
    clc
    pop ax
    pop ds
    ret
get_cmd_line    Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           stop_debug
;
;           DESCRIPTION:    Stop debugging
;
;           PARAMETERS:     BX      Module selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_debug  Proc far
    push ds
    push es
    pushad
;
    mov ds,bx
    mov bx,ds:lib_curr_event
    mov es,bx   
    FreeMem
    mov ds:lib_curr_event,0

sdLoop:
    RequestSpinlock ds:lib_spinlock
    mov ax,ds:lib_events
    or ax,ax
    jz sdLeaveDone
;       
    mov es,ax
    mov ax,es:event_prev
    cmp ax,ds:lib_events
    push ds
    mov ds:lib_events,ax
    mov si,es:event_next
    mov ds,ax
    mov ds:event_next,si
    mov ds,si
    mov ds:event_prev,ax
    pop ds
    jne sdRemoved
;
    mov ds:lib_events,0

sdRemoved:
    ReleaseSpinlock ds:lib_spinlock
;
    FreeMem
    jmp sdLoop

sdLeaveDone:
    ReleaseSpinlock ds:lib_spinlock
;
    mov ds:lib_debug_wait,0
;
    popad
    pop es
    pop ds
    ret
stop_debug   Endp
                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init pe loader module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loader_tab:
l00 DD OFFSET is_valid_exe,               SEG code
l01 DD OFFSET init_module,                SEG code
l02 DD OFFSET create_process,             SEG code
l03 DD OFFSET fixup_exe,                  SEG code
l04 DD OFFSET setup_names,                SEG code
l05 DD OFFSET unload_user_exe,            SEG code
l06 DD OFFSET unload_kernel_exe,          SEG code
l07 DD OFFSET section_patch,              SEG code
l08 DD OFFSET get_exe_name,               SEG code
l09 DD OFFSET get_cmd_line,               SEG code
l10 DD OFFSET get_env,                    SEG code
l11 DD OFFSET init_thread,                SEG code
l12 DD OFFSET start_thread,               SEG code
l13 DD OFFSET free_thread_user,           SEG code
l14 DD OFFSET free_thread_kernel,         SEG code
l15 DD OFFSET allocate_mem,               SEG code
l16 DD OFFSET free_mem,                   SEG code
l17 DD OFFSET debug_allocate_mem,         SEG code
l18 DD OFFSET debug_free_mem,             SEG code
l19 DD OFFSET init_module,                SEG code
l20 DD OFFSET fixup_dll,                  SEG code
l21 DD OFFSET unload_dll,                 SEG code
l22 DD OFFSET free_dll,                   SEG code
l23 DD OFFSET get_current_dll,            SEG code
l24 DD OFFSET get_module_proc,            SEG code
l25 DD OFFSET get_resource,               SEG code
l26 DD OFFSET get_module_name,            SEG code
l27 DD OFFSET start_wait_for_debug_event, SEG code
l28 DD OFFSET stop_wait_for_debug_event,  SEG code
l29 DD OFFSET is_debug_event_idle,        SEG code
l30 DD OFFSET get_debug_event,            SEG code
l31 DD OFFSET get_debug_event_data,       SEG code
l32 DD OFFSET clear_debug_event,          SEG code
l33 DD OFFSET continue_debug_event,       SEG code
l34 DD OFFSET regs_to_user,               SEG code
l35 DD OFFSET add_user_gate,              SEG code
l36 DD OFFSET stop_debug,                 SEG code

init    PROC far
    mov eax,SIZE loader_interface_struc
    mov bx,pe_loader_sel
    AllocateFixedSystemMem
    xor di,di
    mov si,OFFSET loader_tab
    mov cx,SIZE loader_interface_struc
    rep movs byte ptr es:[di],cs:[si]
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov bx,pe_loader_sel
    RegisterLoader
;
    mov esi,OFFSET notify_pe_exception
    mov edi,OFFSET notify_pe_exception_name
    xor dx,dx
    mov ax,notify_pe_exception_nr
    RegisterUserGate32
;
    mov esi,OFFSET reserve_pe_mem
    mov edi,OFFSET reserve_pe_mem_name
    xor dx,dx
    mov ax,reserve_pe_mem_nr
    RegisterUserGate32
;
    mov esi,OFFSET show_exception_text
    mov edi,OFFSET show_exception_text_name
    xor dx,dx
    mov ax,show_exception_text_nr
    RegisterUserGate32
    clc
    ret
init    ENDP

code    ENDS

    END init
