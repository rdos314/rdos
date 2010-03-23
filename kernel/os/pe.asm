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

		NAME  pe

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE int.def
INCLUDE exec.def
INCLUDE pe.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\debevent.inc


SYS_BASE EQU 0DE000000h

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendEvent
;
;		DESCRIPTION:    Sent event to debugger
;
;		PARAMETERS:     DS		Lib
;						ES		Event
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
	mov ax,ds:lib_debug_lib
	or ax,ax
	jz seDone
;
	mov ax,pe_app_sel
	mov ds,ax
	mov ds,ds:pe_app
;	
    push esi
    mov esi,OFFSET lib_section
    EnterNewSection
    pop esi
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
	push esi
	mov esi,OFFSET lib_section
	LeaveNewSection
	pop esi
;
    push es

seSignalLoop:
    mov ax,ds:lib_debug_obj
    or ax,ax
    jnz seSignalDo
;
    mov ax,10
    WaitMilliSec
    jmp seSignalLoop

seSignalDo:
	mov es,ax
	SignalWait
	pop es
	
seDone:
	WaitForSignal
	pop bx
	pop eax
	pop ds
	ret
SendEvent Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ExceptionEvent
;
;		DESCRIPTION:    Exception event
;
;		PARAMETERS:     DS		Lib
;						EBP		Exception frame
;						EAX		Exception code
;
;		RETURNS:		ES		Event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ExceptionEvent Proc near
	push bp
	mov bp,[bp]
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
	pop bp
	ret
ExceptionEvent Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateProcessEvent
;
;		DESCRIPTION:    Create process debug event
;
;		PARAMETERS:     DS		Lib
;						FS		TIB
;						BP		Startup info
;
;		RETURNS:		ES		Event
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
	mov bx,ds:lib_file_handle
	GetFileInfo
	mov word ptr es:[di].cpeFile,ax
	mov word ptr es:[di].cpeFile+2,cx
;	
    movzx ebx,ds:mod_handle
    DerefModuleHandle
    mov es:[di].cpeHandle,ebx
;
	mov eax,fs:pvProcessHandle
	mov es:[di].cpeProcess,eax
	mov eax,fs:pvThreadHandle
	mov es:[di].cpeThread,eax	
	mov eax,ds:lib_base
	mov es:[di].cpeImageBase,eax
	mov eax,ds:lib_size
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
	mov eax,[bp].load_eip
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
;		NAME:			TerminateProcessEvent
;
;		DESCRIPTION:    Terminate process debug event
;
;		PARAMETERS:		EAX		Exit code
;
;		RETURNS:		ES		Event
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
;		NAME:			CreateThreadEvent
;
;		DESCRIPTION:    Create thread debug event
;
;		PARAMETERS:     DS		Lib
;						FS		TIB
;						EDX		EIP
;
;		RETURNS:		ES		Event
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
;		NAME:			TerminateThreadEvent
;
;		DESCRIPTION:    Terminate thread debug event
;
;		PARAMETERS:     DS		Lib
;						FS		TIB
;
;		RETURNS:		ES		Event
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
;		NAME:			LoadDllEvent
;
;		DESCRIPTION:    Load Dll debug event
;
;		PARAMETERS:     DS		Lib
;
;		RETURNS:		ES		Event
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
	mov bx,ds:lib_file_handle
	GetFileInfo
	mov word ptr es:[di].ldeFile,ax
	mov word ptr es:[di].ldeFile+2,cx
;	
    movzx ebx,ds:mod_handle
    DerefModuleHandle
    mov es:[di].ldeHandle,ebx    
;
	mov eax,ds:lib_base
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
	mov eax,ds:lib_size
	mov es:[di].ldeImageSize,eax
;
    pop di
	pop eax
	ret
LoadDllEvent	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeDllEvent
;
;		DESCRIPTION:    Free DLL debug event
;
;		PARAMETERS:     DS		Lib
;
;		RETURNS:		ES		Event
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
    movzx ebx,ds:mod_handle
    DerefModuleHandle
    mov es:[di].fdeHandle,ebx    
;
	pop ebx
	pop eax
	ret
FreeDllEvent Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateLib
;
;		DESCRIPTION:    Create lib
;
;		PARAMETERS:     FS:ESI	Image name
;						BX		File handle
;
;		RETURNS:		ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateLib	Proc near
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
	mov es:lib_usage_count,1
	push ds
	push esi
	mov ax,es
	mov ds,ax
	mov esi,OFFSET lib_section
	InitNewSection
	pop esi
	pop ds
;	
	mov es:lib_base,0
	mov es:lib_process,0
	mov es:lib_size,0
	mov es:lib_debug_lib,0
	mov es:lib_debug_obj,0
	mov es:lib_events,0
	mov es:lib_file_handle,bx
	mov es:lib_run_now,0
	mov es:lib_init_param,0
;
    mov es:mod_free_dll_proc,0
;
    mov word ptr es:mod_get_proc_proc,OFFSET get_module_proc
    mov word ptr es:mod_get_proc_proc+2,cs
;
    mov word ptr es:mod_get_resource_proc,OFFSET get_resource
    mov word ptr es:mod_get_resource_proc+2,cs
;
    mov word ptr es:mod_get_name_proc,OFFSET get_module_name
    mov word ptr es:mod_get_name_proc+2,cs
;
    mov word ptr es:mod_start_wait_for_debug_event_proc,OFFSET start_wait_for_debug_event
    mov word ptr es:mod_start_wait_for_debug_event_proc+2,cs
;
    mov word ptr es:mod_stop_wait_for_debug_event_proc,OFFSET stop_wait_for_debug_event
    mov word ptr es:mod_stop_wait_for_debug_event_proc+2,cs
;
    mov word ptr es:mod_is_debug_event_idle_proc,OFFSET is_debug_event_idle
    mov word ptr es:mod_is_debug_event_idle_proc+2,cs
;
    mov word ptr es:mod_get_debug_event_proc,OFFSET get_debug_event
    mov word ptr es:mod_get_debug_event_proc+2,cs
;
    mov word ptr es:mod_get_debug_event_data_proc,OFFSET get_debug_event_data
    mov word ptr es:mod_get_debug_event_data_proc+2,cs
;
    mov word ptr es:mod_clear_debug_event_proc,OFFSET clear_debug_event
    mov word ptr es:mod_clear_debug_event_proc+2,cs
;
    mov word ptr es:mod_continue_debug_event_proc,OFFSET continue_debug_event
    mov word ptr es:mod_continue_debug_event_proc+2,cs
;
	pop edi
	pop esi
	pop ecx
	pop eax
	ret
CreateLib	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertDll
;
;		DESCRIPTION:    Insert DLL image into module list
;
;		PARAMETERS:     ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertDll	Proc near
	push ds
	push ax
	push esi
;
	mov ax,pe_app_sel
	mov ds,ax
	mov esi,OFFSET pe_section
	EnterNewSection
;
	mov ax,ds:pe_dlls
	or ax,ax
	je ins_dll_empty
;
	push ds
	push si
	mov ds,ax
	mov si,ds:lib_prev
	mov ds:lib_prev,es
	mov ds,si
	mov ds:lib_next,es
	mov es:lib_next,ax
	mov es:lib_prev,si
	pop si
	pop ds
	jmp ins_dll_done

ins_dll_empty:
	mov es:lib_next,es
	mov es:lib_prev,es

ins_dll_done:
	mov ds:pe_dlls,es
	mov esi,OFFSET pe_section
	LeaveNewSection
;
	pop esi
	pop ax
	pop ds
	ret
InsertDll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertSysDll
;
;		DESCRIPTION:    Insert system DLL image into module list
;
;		PARAMETERS:     ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertSysDll	Proc near
	push ds
	push ax
	push esi
;
	mov ax,pe_process_sel
	mov ds,ax
	mov esi,OFFSET ppe_section
	EnterNewSection
;
	mov ax,ds:ppe_dlls
	or ax,ax
	je ins_sysdll_empty
;
	push ds
	push si
	mov ds,ax
	mov si,ds:lib_prev
	mov ds:lib_prev,es
	mov ds,si
	mov ds:lib_next,es
	mov es:lib_next,ax
	mov es:lib_prev,si
	pop si
	pop ds
	jmp ins_sysdll_done

ins_sysdll_empty:
	mov es:lib_next,es
	mov es:lib_prev,es

ins_sysdll_done:
	mov ds:ppe_dlls,es
	mov esi,OFFSET ppe_section
	LeaveNewSection
;
	pop esi
	pop ax
	pop ds
	ret
InsertSysDll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertApp
;
;		DESCRIPTION:    Insert App image into module list
;
;		PARAMETERS:     ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pe_loader_name	DB 'PE',0

InsertApp	Proc near
	push ds
	push ax
;
	mov ax,pe_app_sel
	mov ds,ax
	mov ds:pe_app,es
	mov ds:pe_env,0
	mov ds:pe_exe_name,0
;
	mov ax,thread_app_sel
	mov ds,ax
	mov word ptr ds:app_get_env_proc,OFFSET get_env
	mov word ptr ds:app_get_env_proc+2,cs 
	mov word ptr ds:app_get_exe_proc,OFFSET get_exe_name
	mov word ptr ds:app_get_exe_proc+2,cs 
	mov word ptr ds:app_get_cmd_line_proc,OFFSET get_cmd_line
	mov word ptr ds:app_get_cmd_line_proc+2,cs 
	mov word ptr ds:app_get_options_proc,OFFSET get_options
	mov word ptr ds:app_get_options_proc+2,cs 
	mov word ptr ds:app_set_options_proc,OFFSET set_options
	mov word ptr ds:app_set_options_proc+2,cs 
	mov word ptr ds:app_allocate_mem_proc,OFFSET allocate_mem
	mov word ptr ds:app_allocate_mem_proc+2,cs 
	mov word ptr ds:app_free_mem_proc,OFFSET free_mem
	mov word ptr ds:app_free_mem_proc+2,cs 
	mov word ptr ds:app_init_thread_proc,OFFSET init_thread
	mov word ptr ds:app_init_thread_proc+2,cs
	mov word ptr ds:app_free_thread_proc,OFFSET free_thread
	mov word ptr ds:app_free_thread_proc+2,cs
	mov word ptr ds:app_spawn_proc,OFFSET spawn_proc
	mov word ptr ds:app_spawn_proc+2,cs
	mov word ptr ds:app_clone_proc,OFFSET clone_proc
	mov word ptr ds:app_clone_proc+2,cs
	mov word ptr ds:app_close_proc,OFFSET close_proc
	mov word ptr ds:app_close_proc+2,cs
	mov word ptr ds:app_load_dll_proc,OFFSET load_dll
	mov word ptr ds:app_load_dll_proc+2,cs
	mov word ptr ds:app_loader_name,OFFSET pe_loader_name
	mov word ptr ds:app_loader_name+2,cs
;
	pop ax
	pop ds
	ret
InsertApp	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindLib
;
;		DESCRIPTION:    Search for a DLL or app module
;
;		PARAMETERS:     EDX		Virtual adress
;
;		RETURNS:		EDI		Image base
;						ES		Lib
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindLib	Proc near
	push ds
	push eax
	push ecx
	push esi
;
	mov ax,pe_process_sel
	mov ds,ax
	mov esi,OFFSET ppe_section
	EnterNewSection
;	
	mov ax,ds:ppe_dlls
	or ax,ax
	jz find_lib_not_sys
	mov si,ax
find_syslib_dll_loop:
	mov es,ax
	mov ecx,edx
	sub ecx,es:lib_base
	jc find_syslib_dll_next
	cmp ecx,es:lib_size
	jc find_syslib_ok
find_syslib_dll_next:
	mov ax,es:lib_next
	cmp ax,si
	jne find_syslib_dll_loop

find_lib_not_sys:
    mov esi,OFFSET ppe_section
    LeaveNewSection
	jmp find_lib_app

find_syslib_ok:
	mov edi,es:lib_base
    mov esi,OFFSET ppe_section
    LeaveNewSection
	clc
	jmp find_lib_done

find_lib_app:
	mov ax,pe_app_sel
	mov ds,ax
	mov esi,OFFSET pe_section
	EnterNewSection
;	
	mov ax,ds:pe_dlls
	or ax,ax
	jz find_lib_try_app
	mov si,ax
find_lib_dll_loop:
	mov es,ax
	mov ecx,edx
	sub ecx,es:lib_base
	jc find_lib_dll_next
	cmp ecx,es:lib_size
	jc find_lib_ok
find_lib_dll_next:
	mov ax,es:lib_next
	cmp ax,si
	jne find_lib_dll_loop

find_lib_try_app:
	mov ax,ds:pe_app
	or ax,ax
	jz find_lib_fail
	mov es,ax
	mov ecx,edx
	sub ecx,es:lib_base
	jc find_lib_fail
	cmp ecx,es:lib_size
	jc find_lib_ok

find_lib_fail:
    mov esi,OFFSET pe_section
    LeaveNewSection
	stc
	jmp find_lib_done

find_lib_ok:
	mov edi,es:lib_base
    mov esi,OFFSET pe_section
    LeaveNewSection
	clc

find_lib_done:
	pop esi
	pop ecx
	pop eax
	pop ds
	ret
FindLib	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindDll / FindSysDll / FindApp
;
;		DESCRIPTION:    get DLL or app from name
;
;		PARAMETERS:    	FS:ESI	DLL NAME
;
;		RETURNS:		ES		Lib handle
;						EDI		Image base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UCaseTab:
ct00 DB	0,		0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct08 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct10 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct18 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct20 DB ' ',	'!',	0FFh,	'#',	'$',	'%',	'&',	27h
ct28 DB '(',	')',	0FFh,	0FFh,	0FFh,	'-',	0,		'/'
ct30 DB '0',	'1',	'2',	'3',	'4',	'5',	'6',	'7'
ct38 DB '8',	'9',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ct40 DB '@',	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct48 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct50 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct58 DB	'X',	'Y',	'Z',	0FFh,	'\',	0FFh,	'^',	'_'
ct60 DB 60h,	'A',	'B',	'C',	'D',	'E',	'F',	'G'
ct68 DB 'H',	'I',	'J',	'K',	'L',	'M',	'N',	'O'
ct70 DB 'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W'
ct78 DB 'X',	'Y',	'Z',	'{',	0FFh,	'}',	'~',	0FFh
ct80 DB	0FFh,	0FFh,	0FFh,	0FFh,	'é',	0FFh,	'è',	0FFh
ct88 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	'é',	'è'
ct90 DB	0FFh,	0FFh,	0FFh,	0FFh,	'ô',	0FFh,	0FFh,	0FFh
ct98 DB	0FFh,	'ô',	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctA0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctA8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctB0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctB8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctC0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctC8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctD0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctD8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctE0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctE8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctF0 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh
ctF8 DB	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh,	0FFh

FindDll	Proc near
	push ds
	push ax
	push bx
	push dx
;
	mov ax,pe_app_sel
	mov ds,ax
	push esi
	mov esi,OFFSET pe_section
	EnterNewSection
	pop esi
;	
	mov ax,ds:pe_dlls
	or ax,ax
	jz find_dll_fail
	mov dx,ax
find_dll_check_dll:
	mov es,ax
	mov di,OFFSET lib_name
	push esi
find_dll_check_name:
	mov al,es:[di]
	movzx bx,al
	mov al,byte ptr cs:[bx].UCaseTab
	mov ah,fs:[esi]
	movzx bx,ah
	mov ah,byte ptr cs:[bx].UCaseTab
	cmp al,ah
	jne find_dll_next
	or al,al
	je find_dll_ok
	inc esi
	inc di
	jmp find_dll_check_name

find_dll_next:
	pop esi
	mov ax,es:lib_next
	cmp ax,dx
	jne find_dll_check_dll

find_dll_fail:
	stc
	jmp find_dll_end

find_dll_ok:
	pop esi
	mov edi,es:lib_base
	clc

find_dll_end:
	pushf
	push esi
	mov esi,OFFSET pe_section
	LeaveNewSection
	pop esi
	popf
;
	pop dx
	pop bx
	pop ax
	pop ds
	ret
FindDll	Endp

FindSysDll	Proc near
	push ds
	push ax
	push bx
	push dx
;
	mov ax,pe_process_sel
	mov ds,ax
	push esi
	mov esi,OFFSET ppe_section
	EnterNewSection
	pop esi
;	
	mov ax,ds:ppe_dlls
	or ax,ax
	jz find_sysdll_fail
	mov dx,ax
find_sysdll_check_dll:
	mov es,ax
	mov di,OFFSET lib_name
	push esi
find_sysdll_check_name:
	mov al,es:[di]
	movzx bx,al
	mov al,byte ptr cs:[bx].UCaseTab
	mov ah,fs:[esi]
	movzx bx,ah
	mov ah,byte ptr cs:[bx].UCaseTab
	cmp al,ah
	jne find_sysdll_next
	or al,al
	je find_sysdll_ok
	inc esi
	inc di
	jmp find_sysdll_check_name

find_sysdll_next:
	pop esi
	mov ax,es:lib_next
	cmp ax,dx
	jne find_sysdll_check_dll

find_sysdll_fail:
	stc
	jmp find_sysdll_end

find_sysdll_ok:
	pop esi
	mov edi,es:lib_base
	clc

find_sysdll_end:
	pushf
	push esi
	mov esi,OFFSET ppe_section
	LeaveNewSection
	pop esi
	popf
;
	pop dx
	pop bx
	pop ax
	pop ds
	ret
FindSysDll	Endp

FindApp	Proc near
	push ds
	push ax
	push bx
	push dx
;
	mov bx,pe_app_sel
	mov ds,bx
	push esi
	mov esi,OFFSET pe_section
	EnterNewSection
	pop esi
;	
	mov ax,ds:pe_app
	or ax,ax
	jz find_app_fail
	mov es,ax
	mov di,OFFSET lib_name
	push esi
find_app_check_name:
	mov al,es:[di]
	inc di
	movzx bx,al
	mov al,byte ptr cs:[bx].UCaseTab
	mov ah,fs:[esi]
	movzx bx,ah
	mov ah,byte ptr cs:[bx].UCaseTab
	cmp al,ah
	jne find_app_pop
	or al,al
	je find_app_ok
	inc esi
	inc di
	jmp find_app_check_name

find_app_pop:
	pop esi

find_app_fail:
	stc
	jmp find_app_end

find_app_ok:
	pop esi
	mov edi,es:lib_base
	clc

find_app_end:
	pushf
	push esi
	mov esi,OFFSET pe_section
	LeaveNewSection
	pop esi
	popf
;
	pop dx
	pop bx
	pop ax
	pop ds
	ret
FindApp	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenDll
;
;		DESCRIPTION:    Open DLL file
;
;		PARAMETERS:     FS:ESI	DLL name
;
;		RETURNS:		BX		File handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnknownDllMsg	DB 'Can', 27h, 't find ',0
PathName		DB 'PATH',0

OpenDll	Proc near	
	push ds
	push es
	push ax
	push cx
	push esi
	push edi
;
	mov di,fs
	mov es,di
	mov edi,esi
;
	xor cl,cl
	UserGateForce32 open_file_nr
	jnc open_dll_done
;
    LockProcEnv
    mov ds,bx
	mov ebx,esi
	xor si,si
	mov ax,cs
	mov es,ax
	mov di,OFFSET PathName
find_path_loop:
	cmpsb
	jnz find_path_next
	mov al,es:[di]
	or al,al
	jnz find_path_loop
	mov al,[si]
	cmp al,'='
	je find_path_found

find_path_next:
	lodsb
	or al,al
	jnz find_path_next
	mov al,[si]
	or al,al
	mov di,OFFSET PathName
	jne find_path_loop
	jmp find_path_failed

find_path_found:
	mov eax,1000h
	AllocateBigMem
;
	xor di,di
	inc si
find_path_move_loop:
	lodsb
	or al,al
	jz find_path_move_ok
	cmp al,';'
	je find_path_move_ok
	stosb
	jmp find_path_move_loop	

find_path_move_ok:
	push ebx
find_path_name_loop:
	mov al,fs:[ebx]
	inc ebx
	stosb
	or al,al
	jnz find_path_name_loop
	pop ebx
;
    push bx
	xor di,di
	xor cl,cl
	OpenFile
	jnc find_path_file_ok
;
    pop bx
	mov al,[si-1]
	or al,al
	jnz find_path_move_loop
;
	FreeMem

find_path_failed:
	stc
	jmp open_dll_unlock

find_path_file_ok:
    add sp,2
	FreeMem
	clc
	
open_dll_unlock:
    pushf
    UnlockProcEnv
    popf

open_dll_done:
	pop edi
	pop esi
	pop cx
	pop ax
	pop es
	pop ds
	ret
OpenDll Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindObject
;
;		DESCRIPTION:    Search for a object
;
;		PARAMETERS:     ES		Lib handle
;						EDI		Image base
;						EDX		Virtual adress
;
;		RETURNS:		ESI		Object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindObject	Proc near
	push eax
	push cx
;
	mov esi,es:lib_header
	mov cx,[esi].peh_objects
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
	pop cx
	pop eax
	ret
FindObject	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RelocObject
;
;		DESCRIPTION:    Relocate a object
;
;		PARAMETERS:     ES		Lib handle
;						EDI		Image base
;						EDX		Linear address
;                       EBP     Virtual address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reloc_nop	Proc near
	ret
reloc_nop	Endp

reloc_high	Proc near
	push ecx
	mov ecx,edi
	shr ecx,16
	and ax,0FFFh
	movzx eax,ax
	add eax,edx
	add [eax],cx
	pop ecx
	ret
reloc_high	Endp

reloc_low	Proc near
	and ax,0FFFh
	movzx eax,ax
	add eax,edx
	add [eax],di
	ret
reloc_low	Endp

reloc_highlow	Proc near
	and ax,0FFFh
	movzx eax,ax
	add eax,edx
	add [eax],edi
	ret
reloc_highlow	Endp

reloc_highadj	Proc near
	int 3
	ret
reloc_highadj	Endp

reloc_tab:
rt0	DW OFFSET reloc_nop
rt1	DW OFFSET reloc_high
rt2	DW OFFSET reloc_low
rt3	DW OFFSET reloc_highlow
rt4	DW OFFSET reloc_highadj
rt5	DW OFFSET reloc_nop
rt6	DW OFFSET reloc_nop
rt7	DW OFFSET reloc_nop
rt8	DW OFFSET reloc_nop
rt9	DW OFFSET reloc_nop
rtA	DW OFFSET reloc_nop
rtB	DW OFFSET reloc_nop
rtC	DW OFFSET reloc_nop
rtD	DW OFFSET reloc_nop
rtE	DW OFFSET reloc_nop
rtF	DW OFFSET reloc_nop

RelocObject	Proc near
	push eax
	push ebx
	push ecx
	push esi
	push edi
;
	mov ebx,es:lib_header
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
	mov eax,[esi].fixup_size
	add esi,eax
	sub ecx,eax
	jz reloc_object_done
	jnc reloc_object_fixup_search
	jmp reloc_object_done

reloc_object_fixup_found:
	sub edi,[ebx].peh_image_base
	or edi,edi
	jz reloc_object_done
;
	mov ecx,[esi].fixup_size
	add esi,OFFSET fixup_data
	sub ecx,OFFSET fixup_data
reloc_object_reloc_loop:
	lods word ptr [esi]
	sub ecx,2
	movzx bx,ah
	shr bx,4
	shl bx,1
	call word ptr cs:[bx].reloc_tab
	or ecx,ecx
	jnz reloc_object_reloc_loop

reloc_object_done:
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop eax
	ret
RelocObject	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RunDll
;
;		DESCRIPTION:    Init DLL
;
;		PARAMETERS:     DS:EDI	Image base
;						ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunDll	Proc near
	push ds
	push es
	push fs
	push gs
	pushad
;
    mov fs,es:lib_fs
	mov eax,es:lib_header
	mov eax,[eax].peh_entry_point
	or eax,eax
	jz rdDone
;	
	add eax,edi
	push eax
	movzx eax,es:lib_init_param
    movzx ebx,es:mod_handle
    mov edx,1
	CallPM32

rdDone:
	popad
	pop gs
	pop fs
	pop es
	pop ds
	ret
RunDll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ImportObject
;
;		DESCRIPTION:    Import an object
;
;		PARAMETERS:     EBX		Address of import ordinal + name		
;						ESI		Image base of export DLL
;						GS		Lib handle of export DLL
;						EDI		Image base of import DLL/APP
;						ES		Lib handle of import DLL/APP
;						
;		RETURNS:		EAX		Virtual address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnresolvedMsg DB 'Cannot find imported function ',0

ImportObject	Proc near
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
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
	sub edx,[esi].exp_name_va
	add edx,[esi].exp_entry_point_va
	mov eax,[esi].exp_ordinal_va
	mov eax,[edx]
	add eax,edi

import_object_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret
ImportObject	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			BindImport
;
;		DESCRIPTION:    Bind imported functions
;
;		PARAMETERS:     EDX		Import descr
;						ESI		Export image base
;						GS		Export Lib handle
;						EDI		Import Image base
;						ES		Import Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BindImport	Proc near
	push eax
	push edx
	push esi
	push edi
;
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
BindImport	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadImportedDlls
;
;		DESCRIPTION:    Load imported DLLs
;
;		PARAMETERS:     EDI		Image base
;						ES		Lib
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadImportedDlls	Proc near
	push fs
	push gs
	push eax
	push edx
	push esi
;
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
	add esi,edi
	call LoadPeDll
	mov esi,edi
	mov ax,es
	mov gs,ax
	pop edi
	pop es
	jc load_import_dlls_loop
;	
	call BindImport
;
	add edx,SIZE import_descr
	jmp load_import_dlls_loop

load_import_dlls_done:
	pop esi
	pop edx
	pop eax
	pop gs
	pop fs
	ret
LoadImportedDlls	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeImportDlls
;
;		DESCRIPTION:    Free imported DLLs
;
;		PARAMETERS:     ES		Lib handle
;						EDI		Image base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeImportedDlls	Proc near
	push eax
	push edx
	push esi
;
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
	push es
	push fs
	push edi
	mov ax,ds
	mov fs,ax
	add esi,edi
	call FindSysDll
	jnc free_do
;
	call FindDll
	jc fidf

free_do:
	call FreePeDll

fidf:
	pop edi
	pop fs
	pop es
;
	add edx,SIZE import_descr
	jmp free_import_dlls_loop

free_import_dlls_done:
	pop esi
	pop edx
	pop eax
	ret
FreeImportedDlls	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NotifyDll
;
;		DESCRIPTION:   	Notify one DLL
;
;		PARAMETERS:     EDI		Image base
;						ES		Lib
;						ESI		DLL name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyDll	Proc near
	push es
	push edx
	push edi
;
	mov dx,es:lib_debug_lib
	call FindSysDll
	jnc notify_check_debug
;
	call FindDll
	jc notify_dll_done

notify_check_debug:
	mov edi,es:lib_base
	xchg dx,es:lib_debug_lib
	or dx,dx
	jnz notify_dll_done
;
	call Preload
	push ds
	push es
	mov ax,es
	mov ds,ax
	call LoadDllEvent
	call SendEvent
	pop es
	pop ds
;
	mov edx,es:lib_header
	mov edx,[edx].peh_import_va
	or edx,edx
	jz notify_dll_done
;
	add edx,edi
notify_dll_loop:
	mov esi,[edx].imp_dll_name_va
	or esi,esi
	jz notify_dll_done
;
	add esi,edi
	call NotifyDll
;
	add edx,SIZE import_descr
	jmp notify_dll_loop

notify_dll_done:
	pop edi
	pop edx
	pop es
	ret
NotifyDll	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NotifyImportedDlls
;
;		DESCRIPTION:   	Notify imported DLLs
;
;		PARAMETERS:     EDI		Image base
;						ES		Lib
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyImportedDlls	Proc near
	push fs
	push gs
	push eax
	push edx
	push esi
;
	mov ax,flat_data_sel
	mov ds,ax
	mov fs,ax
;
	mov edx,es:lib_header
	mov edx,[edx].peh_import_va
	or edx,edx
	jz notify_import_dlls_done
;
	add edx,edi
notify_import_dlls_loop:
	mov esi,[edx].imp_dll_name_va
	or esi,esi
	jz notify_import_dlls_done
;
	add esi,edi
	call NotifyDll
;
	add edx,SIZE import_descr
	jmp notify_import_dlls_loop

notify_import_dlls_done:
	pop esi
	pop edx
	pop eax
	pop gs
	pop fs
	ret
NotifyImportedDlls	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartDll
;
;		DESCRIPTION:   	Start one DLL
;
;		PARAMETERS:     EDI		Image base
;						ES		Lib
;						ESI		DLL name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDll	Proc near
	push es
	push edx
	push edi
;
	mov dx,es:lib_init_param
	call FindSysDll
	jnc start_dll_found
;
	call FindDll
	jc start_dll_done

start_dll_found:
	mov ax,1
	xchg ax,es:lib_run_now
	or ax,ax
	jnz start_dll_done
;
	mov es:lib_init_param,dx
	mov edi,es:lib_base
	call RunDll
;
	mov edx,es:lib_header
	mov edx,[edx].peh_import_va
	or edx,edx
	jz start_dll_done
;
	add edx,edi
start_dll_loop:
	mov esi,[edx].imp_dll_name_va
	or esi,esi
	jz start_dll_done
;
	add esi,edi
	call StartDll
;
	add edx,SIZE import_descr
	jmp start_dll_loop

start_dll_done:
	pop edi
	pop edx
	pop es
	ret
StartDll	Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartImportedDlls
;
;		DESCRIPTION:   	Start imported DLLs
;
;		PARAMETERS:     EDI		Image base
;						ES		Lib
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartImportedDlls	Proc near
	push fs
	push gs
	push eax
	push edx
	push esi
;
	mov ax,flat_data_sel
	mov ds,ax
	mov fs,ax
;
	mov edx,es:lib_header
	mov edx,[edx].peh_import_va
	or edx,edx
	jz start_import_dlls_done
;
	add edx,edi
start_import_dlls_loop:
	mov esi,[edx].imp_dll_name_va
	or esi,esi
	jz start_import_dlls_done
;
	add esi,edi
	call StartDll
;
	add edx,SIZE import_descr
	jmp start_import_dlls_loop

start_import_dlls_done:
	pop esi
	pop edx
	pop eax
	pop gs
	pop fs
	ret
StartImportedDlls	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadPeDll
;
;		DESCRIPTION:    Load a PE Dll
;
;		PARAMETERS:     FS:ESI	DLL name
;						ES		Owner lib
;
;		RETURNS:		EDI		Image base of Dll
;						ES		Lib handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadPeDll	PROC near
    push gs
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push bp
;
    mov ax,es
    mov gs,ax
	call FindSysDll
	jnc load_dll_usage
;
	call FindDll
	jc load_dll_do

load_dll_usage:
	inc es:lib_usage_count
	mov edi,es:lib_base
	jmp load_dll_done

load_dll_do:
	mov dx,gs:lib_debug_lib
	mov bp,gs:lib_run_now
	call OpenDll
	jc load_dll_fail_nofree
;
	mov eax,40h
	AllocateSmallGlobalMem
	mov cx,ax
	xor di,di
	ReadFile
	jc load_dll_fail
	cmp ax,40h
	jne load_dll_fail
	mov ax,es:exeh_signature
	cmp ax,5A4Dh
	jne load_dll_fail
	mov ax,es:exeh_reloc_offs
	cmp ax,40h
	jne load_dll_fail
	mov ax,es:[3Ch]
	movzx eax,ax
	SetFilePos
	mov cx,40h
	ReadFile   
	jc load_dll_fail
	mov ax,es:[0]
	cmp ax,'EP'
	jne load_dll_fail
;
	GetFilePos
	movzx ecx,cx
	sub eax,ecx
	SetFilePos
;
	FreeMem
	call CreateLib
    mov word ptr es:mod_free_dll_proc,OFFSET free_dll	
    mov word ptr es:mod_free_dll_proc+2,cs
	CreateModule
;	
	call CreateImage
	mov edi,es:lib_base
	cmp edi,SYS_BASE
	jae load_pe_ins_sys
;
	call InsertDll
	jmp load_pe_ins_done

load_pe_ins_sys:
	call InsertSysDll

load_pe_ins_done:
	mov es:lib_debug_lib,dx
	mov ax,gs:lib_fs
	mov es:lib_fs,ax
	mov es:lib_run_now,bp
	mov ecx,es:lib_size
	call LoadImportedDlls
;
	or dx,dx
	jz load_dll_nodeb
;
	call Preload
	push ds
	push es
	mov ax,es
	mov ds,ax
	call LoadDllEvent
	call SendEvent
	pop es
	pop ds

load_dll_nodeb:
	call RunDll
	clc
	jmp load_dll_done

load_dll_fail:
	FreeMem
load_dll_fail_nofree:
	xor edi,edi
	stc

load_dll_done:
	pop bp
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop gs
	ret
LoadPeDll	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreePeDll
;
;		DESCRIPTION:    Free PE DLL
;
;       PARAMETERS:		ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePeDll	Proc near
	sub es:lib_usage_count,1
	jnz free_pe_dll_done
;
	push ds
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov dx,es:lib_debug_lib
	or dx,dx
	jz fdNotifyDone
;
	push es
	mov ax,es
	mov ds,ax
	call FreeDllEvent
	call SendEvent
	pop es

fdNotifyDone:
	mov ax,flat_data_sel
	mov ds,ax
	mov eax,es:lib_header
	mov eax,[eax].peh_entry_point
	or eax,eax
	jz fdMod
;	
    push ds
    push es
    push fs
    pushad
;        
	add eax,es:lib_base
	push eax
	movzx eax,es:lib_init_param
    movzx ebx,es:mod_handle
    mov edx,0
	CallPM32
;
    popad
    pop fs
    pop es
    pop ds	

fdMod:
    FreeModule
;    
	mov ax,pe_app_sel
	mov ds,ax
	mov esi,OFFSET pe_section
	EnterNewSection
;	
	mov ds:pe_dlls,es
	mov ax,es:lib_prev
	cmp ax,ds:pe_dlls
	push ds
	mov ds:pe_dlls,ax
	mov si,es:lib_next
	mov ds,ax
	mov ds:lib_next,si
	mov ds,si
	mov ds:lib_prev,ax
	pop ds
	jne free_pe_dll_removed
;
	mov ds:pe_dlls,0

free_pe_dll_removed:
    mov esi,OFFSET pe_section
    LeaveNewSection
;
	mov ax,flat_data_sel
	mov ds,ax
	mov edi,es:lib_base
	call FreeImportedDlls
	mov edx,es:lib_base
	mov ecx,es:lib_size
	mov bx,es:lib_file_handle
	CloseFile
	add edx,local_page_linear
	FreeLinear
	FreeMem
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ds

free_pe_dll_done:
	ret
FreePeDll Endp
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_object
;
;		DESCRIPTION:    Demand load object
;
;		PARAMETERS:     EDX		LINEAR ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_object	Proc far
	push ds
	push es
	pushad
	sub edx,local_page_linear
	mov ax,flat_data_sel
	mov ds,ax
	and dx,0F000h
;
	call FindLib
	jc load_object_done
;
    mov ax,es
    mov ds,ax
    mov esi,OFFSET lib_section
    EnterNewSection
;
	mov cx,process_page_sel
	mov ds,cx
	mov eax,edx
    add eax,local_page_linear
	shr eax,10
;
	mov eax,[eax]
	test al,1
	jnz load_object_leave
;	
	mov ax,flat_data_sel
	mov ds,ax
	call FindObject
	jc load_object_leave
;
    mov ebp,edx
    mov eax,1000h
    AllocateLocalLinear
    sub edx,local_page_linear
;
	test [esi].o_flags,80h
	jz load_object_from_file

load_object_init:
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
	jmp load_object_leave

load_object_from_file:
	mov bx,es:lib_file_handle
	mov eax,ebp
	sub eax,edi
	sub eax,[esi].o_va
	mov ecx,[esi].o_phys_size
	sub ecx,eax
	jnc load_object_file
;
    xor ecx,ecx	
    jmp load_object_size_ok
	
load_object_file:
	cmp ecx,1000h
	jc load_object_size_ok
	mov ecx,1000h

load_object_size_ok:
	add eax,[esi].o_phys_offset
	SetFilePos	
;
	push es
	push edi
	mov ax,ds
	mov es,ax
	mov edi,edx
	UserGateForce32 read_file_nr
	add edi,eax
	mov ecx,1000h
	sub ecx,eax
	shr ecx,2
	xor eax,eax
	rep stos dword ptr es:[edi]
	pop edi
	pop es
;
	call RelocObject
;
	mov ecx,[esi].o_flags
	mov ax,process_page_sel
	mov ds,ax
    add edx,local_page_linear
    add ebp,local_page_linear
    push edx
	shr edx,10
	shr ebp,10
;
    xor eax,eax
	xchg eax,[edx]
;
	test ecx,80000000h
	jnz load_object_save

	and al,NOT 2

load_object_save:
	mov ds:[ebp],eax
;
    pop edx
    mov ecx,1000h
    FreeLinear

load_object_leave:
    mov ax,es
    mov ds,ax
    mov esi,OFFSET lib_section
    LeaveNewSection
    
load_object_done:
	popad
	pop es
	pop ds
	ret
load_object	Endp 
                                          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateImage
;
;		DESCRIPTION:    Create memory image of header
;
;		PARAMETERS:     FS:ESI	Image name
;						ES		Lib handle
;
;		RETURNS:		EDI		Image base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateImage	Proc near
	push eax
	push bx
	push ecx
	push edx
	push esi
;
	mov bx,es:lib_file_handle
	GetFilePos
	push eax
	push es
	mov eax,SIZE pe_header
	AllocateLocalMem
	mov cx,ax
	xor di,di
	ReadFile   
	mov ecx,es:peh_image_size
	mov edx,es:peh_image_base
	mov si,es:peh_nthdr_size
	mov di,es:peh_objects
	FreeMem
	pop es
;
	pop eax
	mov es:lib_header,eax
	mov es:lib_base,edx
	mov es:lib_size,ecx
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
	mov edx,es:lib_base
	mov eax,es:lib_size
    add edx,local_page_linear
	ReserveLocalLinear
	jnc create_image_alloced
	AllocateLocalLinear

create_image_alloced:
	sub edx,local_page_linear
	SetFlatLinearInvalid
;
	pop eax
	add eax,es:lib_objects
	mov ecx,eax
	SetFlatLinearValid
;
	add es:lib_header,edx
	add es:lib_objects,edx
	mov es:lib_base,edx
;
	xor eax,eax
	SetFilePos
;
	push es
	mov ax,ds
	mov es,ax
	mov edi,edx
	UserGateForce32 read_file_nr
	pop es
;
	mov esi,es:lib_header
	mov cx,[esi].peh_objects
	mov esi,es:lib_objects
;
	push es
	mov ax,cs
	mov es,ax
hook_object_loop:
	mov edx,[esi].o_va
	add edx,edi
	add edx,local_page_linear
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
	mov eax,[esi].o_phys_offset
	SetFilePos
;
	push es
	push edi
	mov edi,edx
	add edx,local_page_linear
	mov eax,ecx
	UnhookPage
	mov ax,ds
	mov es,ax
	UserGateForce32 read_file_nr
	pop edi
	pop es

fixup_done:
	pop esi
	pop edx
	pop ecx
	pop bx
	pop eax
	ret
CreateImage	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Preload
;
;		DESCRIPTION:    Preload image
;
;		PARAMETERS:     EDI		Image base
;						ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preload	Proc near
	push eax
	push ecx
	push edx
	push esi
;
	mov esi,es:lib_header
	mov cx,[esi].peh_objects
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
Preload	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitStack
;
;		DESCRIPTION:    Init stack and TIB
;
;		PARAMETERS:     EDI	Image base
;						ES	Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitStack	Proc near
	push fs
	push eax
	push ecx
	push edx
	push esi
;
	push ds
	push bx
	mov eax,1000h
	AllocateLocalLinear
	AllocateLdt
	or bx,7
	mov ecx,eax	
	CreateDataSelector32
	mov [bp].load_fs,bx
	mov es:lib_fs,bx
	mov fs,bx
	sub edx,local_page_linear
	mov fs:pvBase,edx
	pop bx
	pop ds
;
	mov dword ptr [bp].load_ss,flat_data_sel
	mov esi,es:lib_header
	mov eax,[esi].peh_stack_reserve_size
	AllocateLocalLinear
	sub edx,local_page_linear
	mov [bp].load_ebx,edx
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
	mov [bp].load_ebp,edx
	sub edx,10h
	mov [bp].load_ecx,edx
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
	sub edx,local_page_linear
	push edi
	mov edi,edx
	mov bx,ds
	mov es,bx
	rep movs byte ptr es:[edi],[esi]
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
	mov [edx],eax						; reserved
	sub edx,4
	mov [edx],eax						; reason
	sub edx,4
	movzx eax,es:mod_handle
	mov dword ptr [edx],eax				; module handle
	mov fs:pvModuleHandle,eax
	sub edx,4
	xor eax,eax
	mov [edx],eax						; return address
	sub edx,4
	mov [edx],edx
	mov [bp].load_esp,edx
;
	pop esi
	pop edx
	pop ecx
	pop eax
	pop fs
	ret
InitStack	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RunImage
;
;		DESCRIPTION:    Setup registers to run image
;
;		PARAMETERS:     EDI		Image base
;						ES		Lib handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunImage	Proc near
	push eax
	push ebx
	push edx
;
	mov dword ptr [bp].load_cs,flat_code_sel
	mov eax,es:lib_header
	mov eax,[eax].peh_entry_point
	add eax,edi
	mov [bp].load_eip,eax
	mov [bp].load_eax,eax
	mov dword ptr [bp].load_edi,0
	mov word ptr [bp+2].load_eflags,0
	mov ax,7202h
	SetFlags
	mov [bp].load_eflags,ax
	mov dword ptr [bp].load_ds,flat_data_sel
	mov dword ptr [bp].load_es,flat_data_sel
;
	pop edx
	pop ebx
	pop eax
	ret
RunImage	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_pe
;
;		DESCRIPTION:    Load portable executable file
;
;		PARAMETERS:     BX		file handle
;						DS:ESI	File name
;						ES:EDI	Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_pe	Proc far
	push ds
	push es
	push fs
	push esi
	push edi
;
	push ax
	mov ax,ds
	mov fs,ax
	mov ax,flat_data_sel
	mov ds,ax
;
	xor eax,eax
	SetFilePos
	mov eax,40h
	AllocateSmallGlobalMem
	mov cx,ax
	xor di,di
	ReadFile
	jc load_pe_fail
	cmp ax,40h
	jne load_pe_fail
	mov ax,es:exeh_signature
	cmp ax,5A4Dh
	jne load_pe_fail
	mov ax,es:exeh_reloc_offs
	cmp ax,40h
	jne load_pe_fail
	mov ax,es:[3Ch]
	movzx eax,ax
	SetFilePos
	mov cx,40h
	ReadFile   
	jc load_pe_fail
	mov ax,es:[0]
	cmp ax,'EP'
	jne load_pe_fail
;
	GetFilePos
	movzx ecx,cx
	sub eax,ecx
	SetFilePos
;
	FreeMem
	call CreateLib
	SetModule
;	
	xor ax,ax
	mov fs,ax
;
	mov al,32
	SetBitness
;
	call CreateImage
	call InsertApp
	call InitStack
	call LoadImportedDlls
	pop ax
	call RunImage
	pop edi
	pop esi
	pop fs
	pop es
	pop ds
;
	push ds
	push es
	push fs
	push esi
	push edi
;
	mov ax,pe_app_sel
	mov fs,ax
;
	xor ecx,ecx
	push edi

load_pe_cmd_size:
	mov al,es:[edi]
	inc edi
	inc ecx
	or al,al
	jnz load_pe_cmd_size
;
	pop edi
	xor ebx,ebx
	push esi

load_pe_name_size:
	mov al,[esi]
	inc esi
	inc ebx
	or al,al
	jnz load_pe_name_size
;
	pop esi
;
	mov eax,ecx
	add eax,ebx
	UserGateForce32 allocate_app_mem_nr	
	mov fs:pe_cmd_line,edx
	mov fs:pe_options,0
;
	push es
	push ecx
	push edi
	mov ax,flat_data_sel
	mov es,ax
	mov edi,edx
	mov ecx,ebx
	rep movs byte ptr es:[edi],[esi]
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
	rep movs byte ptr es:[edi],[esi]
	clc
	jmp load_pe_done

load_pe_fail:
	pop ax
	FreeMem
	stc

load_pe_done:
	pop edi
	pop esi
	pop fs
	pop es
	pop ds
	ret
load_pe	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitThread
;
;		DESCRIPTION:    Init thread
;
;		PARAMETERS:     DS		TSS selector of new thread
;						EAX		Stack size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread	PROC far
	push es
	push fs
	push eax
	push ebx
	push edx
	push esi
	push edi
;
	push eax
	mov ax,flat_data_sel
	mov fs,ax
	mov es,ds:tss_ebx
	mov ebx,es:pvModuleHandle
	mov edx,es:pvProcessHandle
	push es
	push bx
	DerefModuleHandle
	mov es,bx
	mov esi,es:lib_header
	mov edi,es:lib_base
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
	sub edx,local_page_linear
	mov es:pvBase,edx
	pop edx
	pop ecx
	pop bx
	pop ds
;
	mov es:pvArbitrary,ecx
	mov es:pvModuleHandle,ebx
	mov es:pvProcessHandle,edx
	mov ds:tss_fs,es
	mov ds:tss_ds,fs
	mov ds:tss_ss,fs
	mov ds:tss_es,fs
	mov ds:tss_cs,flat_code_sel
	mov ds:tss_gs,0
	pop eax
	add eax,200h
	and ax,0F000h
	add eax,1000h
	AllocateLocalLinear
	sub edx,local_page_linear
	mov dword ptr ds:tss_ebx,edx
	mov es:pvFirstExcept,-1
	mov es:pvStackUserBottom,edx
	mov es:pvStackUserSize,eax
	add edx,eax
	sub edx,88h
	mov es:pvTEB,edx
	mov ax,ds:tss_thread
	push es
	mov es,ax
	movzx eax,es:p_id
	pop es
	mov es:pvThreadHandle,eax
	mov fs:[edx+24h],eax
	mov dword ptr ds:tss_ebp,edx
	sub edx,10h
	mov dword ptr ds:tss_ecx,edx
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
	sub edx,local_page_linear
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
	mov fs:[edx],eax						; reserved
	sub edx,4
	mov fs:[edx],eax						; reason
	sub edx,4
	mov eax,es:pvModuleHandle
	mov dword ptr fs:[edx],eax				; module handle
	sub edx,4
	xor eax,eax
	mov fs:[edx],eax						; return address
	sub edx,4
	mov dword ptr ds:tss_esp,edx
;
	pop edi
	pop esi
	pop edx
	pop ebx
	pop eax
	pop fs
	pop es
	ret
init_thread	Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			start_thread
;
;		DESCRIPTION:    Start thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_thread	PROC far
	push ds
	push es
	pushad
;
    or bp,bp
    je start_thread_done
;    
	mov ax,thread_app_sel
	mov ds,ax
	mov ax,word ptr ds:app_loader_name
	cmp ax,OFFSET pe_loader_name
	jne start_thread_done
;
	mov ax,cs
	cmp ax,word ptr ds:app_loader_name+2
	jne start_thread_done
;
	mov ax,[bp].vm_cs
	cmp ax,flat_code_sel
	jnz start_thread_done
;
	mov edx,[bp].vm_eip
	mov ax,pe_app_sel
	mov ds,ax
	mov ds,ds:pe_app	
	mov ax,ds:lib_debug_lib
	or ax,ax
	jz start_thread_done
;
	call CreateThreadEvent
	call SendEvent

start_thread_done:
	popad
	pop es
	pop ds
	ret
start_thread	Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeThread
;
;		DESCRIPTION:    Free stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread	Proc far
	mov ax,thread_app_sel
	mov ds,ax
	mov ax,word ptr ds:app_loader_name
	cmp ax,OFFSET pe_loader_name
	jne free_thread_no_debug
;
	mov ax,cs
	cmp ax,word ptr ds:app_loader_name+2
	jne free_thread_no_debug
;
	mov ax,pe_app_sel
	mov ds,ax
	mov ds,ds:pe_app	
	mov ax,ds:lib_debug_lib
	or ax,ax
	jz free_thread_no_debug
;
	call TerminateThreadEvent
	call SendEvent
	
free_thread_no_debug:
	mov ebx,fs:pvModuleHandle
	DerefModuleHandle
	mov es,bx
	mov ax,flat_data_sel
	mov ds,ax
	mov esi,es:lib_header
	mov edi,es:lib_base
	mov eax,[esi].peh_tls_va
	or eax,eax
	jz free_thread_no_tls
;
	add eax,edi
	mov edx,[eax].tls_index_va
	mov edx,[edx]
	mov esi,fs:pvTLSArray
	mov edx,[esi+4*edx]
	add edx,local_page_linear
;
	mov ecx,[eax].tls_end_data_va
	sub ecx,[eax].tls_start_data_va
	FreeLinear

free_thread_no_tls:
	mov edx,fs:pvStackUserBottom
	add edx,local_page_linear
	mov ecx,fs:pvStackUserSize
	FreeLinear	
	mov ax,fs
	mov es,ax
	xor ax,ax
	mov fs,ax
	FreeMem
	ret
free_thread	Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			spawn_proc
;
;		DESCRIPTION:    Spawn callback
;
;		PARAMETERS:		GS		spawn selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kernel_dll		DB 'kernel32.dll',0
debug_startup	DB 'DebugStartup',0

spawn_proc	Proc far
	mov ax,pe_app_sel
	mov ds,ax
	mov es,ds:pe_app
	mov ax,flat_data_sel
	mov ds,ax
	mov fs,[bp].load_fs
;
	xor edx,edx
	mov ax,word ptr gs:s_loader_name
	cmp ax,OFFSET pe_loader_name
	jne spawn_param_ok
;
	mov ax,cs
	cmp ax,word ptr gs:s_loader_name+2
	jne spawn_param_ok
;	
	mov dx,gs:s_param
    	
spawn_param_ok:
	mov es:lib_debug_lib,dx
	mov es:lib_init_param,dx
	mov edi,es:lib_base
	mov es:lib_run_now,1
	call StartImportedDlls
;
	mov dx,es:lib_debug_lib
	or dx,dx
	jz spawn_no_debug
;
	call Preload
	push ds
	push es
	mov ax,es
	mov ds,ax
	call CreateProcessEvent
	call SendEvent
	pop es
	pop ds
	call NotifyImportedDlls
;
	mov ax,cs
	mov es,ax
	mov edi,OFFSET kernel_dll
	UserGateForce32 get_module_nr
	jc spawn_wd_debug
;
	mov edi,OFFSET debug_startup
	UserGateForce32 get_module_proc_nr
	jc spawn_wd_debug
;
	xchg esi,[bp].load_eip
	mov eax,[bp].load_esp
	mov ds,[bp].load_ss
	sub eax,4
	mov [eax],esi
	mov [bp].load_esp,eax
	ret

spawn_wd_debug:	
    push es
    mov ax,flat_data_sel
    mov es,ax
    mov esi,[bp].load_eip
    mov esi,es:[esi-4]
    mov [bp].load_eip,esi
    pop es

spawn_no_debug:
	ret
spawn_proc	Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			clone_proc
;
;		DESCRIPTION:    Request to clone environment
;
;       RETURNS:        ES      Clone selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clone_proc	Proc far
    push ds
    pushad
;    
    mov eax,SIZE pe_clone_seg
    AllocateSmallGlobalMem
    mov es:pcs_entries,0
;
	mov ax,pe_app_sel
	mov ds,ax
	mov ds,ds:pe_app
    mov ax,ds:lib_file_handle
    mov es:pcs_file_handle,ax
;
    popad
    pop ds    
    ret
clone_proc  Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			close_proc
;
;		DESCRIPTION:    Close app callback
;
;		PARAMETERS:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_proc	Proc far
	mov ax,thread_app_sel
	mov ds,ax
	mov ax,word ptr ds:app_loader_name
	cmp ax,OFFSET pe_loader_name
	jne free_process_no_debug
;
	mov ax,cs
	cmp ax,word ptr ds:app_loader_name+2
	jne free_process_no_debug
;
	mov ax,pe_app_sel
	mov ds,ax
	mov ds,ds:pe_app	
	mov ax,ds:lib_debug_lib
	or ax,ax
	jz free_process_no_debug
;
	call TerminateProcessEvent
	call SendEvent

free_process_no_debug:
	ret
close_proc	Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartWaitForDebugEvent
;
;		DESCRIPTION:    Start wait for an debug event from process
;
;		PARAMETERS:		BX        Debugged lib_sel
;                       ES        Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_debug_event Proc far
	push ds
	push ax
;
    mov ds,bx
	ClearSignal
	mov ds:lib_debug_obj,es

	mov ax,ds:lib_events
	or ax,ax
    jz start_wait_done
;
	mov ds:lib_debug_obj,0
    SignalWait

start_wait_done:    
    pop ax
	pop ds	
	ret
start_wait_for_debug_event Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StopWaitForDebugEvent
;
;		DESCRIPTION:    Stop wait for an debug event from process
;
;		PARAMETERS:		BX      Debugged lib_sel
;                       ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_debug_event Proc far
	push ds
;
    mov ds,bx
	mov ds:lib_debug_obj,0
;	
	pop ds	
	ret
stop_wait_for_debug_event Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IsDebugEventIdle
;
;		DESCRIPTION:    Check if debug event is idle
;
;		PARAMETERS:		BX      Debugged lib_sel
;                       ES      Wait object
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
;		NAME:			GetDebugEvent
;
;		DESCRIPTION:    Get debug event from process
;
;		PARAMETERS:		BX        Debugged lib_sel
;
;       RETURNS:        AX        Thread ID
;                       BL        Event type  
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_event Proc far
	push ds
	push es
	push esi
;
    mov ds,bx
    mov esi,OFFSET lib_section
    EnterNewSection
;
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
    mov esi,OFFSET lib_section
    LeaveNewSection
;
    mov ds:lib_curr_event,es
    mov bl,es:event_code
    mov ax,es:event_thread_id
    clc
    jmp gdeDone

gdeLeaveFail:
    mov esi,OFFSET lib_section
    LeaveNewSection
	xor bl,bl
	xor ax,ax
    stc

gdeDone:
	pop esi
	pop es
	pop ds	
	ret
get_debug_event Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDebugEventData
;
;		DESCRIPTION:    Get event data
;
;		PARAMETERS:		BX        Debugged lib_sel
;                       ES:EDI     Event buffer
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
	rep movs byte ptr es:[edi],[esi]
	pop edi
;
    mov al,ds:event_code
    cmp al,EVENT_FREE_DLL
    je gdedFreeDll
;    
	cmp al,EVENT_CREATE_PROCESS
	je gdedDuplFile
	cmp al,EVENT_LOAD_DLL
	jne gdedDone

gdedDuplFile:
    mov bx,es:[edi+4]
    mov ds,bx
    AliasModuleHandle
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

gdedFreeDll:
    mov bx,es:[edi]
    mov ds,bx
    mov bx,ds:lib_local_handle
    mov es:[edi],bx	

gdedDone:
	pop esi
	pop ecx
	pop ebx
	pop eax
	pop ds	
	ret
get_debug_event_data Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ClearDebugEvent
;
;		DESCRIPTION:    Clear debug event
;
;		PARAMETERS:		BX      Debugged lib_sel
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
	FreeMem

clear_debug_done:
	mov ds:lib_curr_event,0
;	
	pop bx
	pop es
	pop ds
	ret
clear_debug_event Endp

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ContinueDebugEvent
;
;		DESCRIPTION:    Continue debugged thread
;
;		PARAMETERS:		EAX		Thread
;                       BX      Debugged lib_sel
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

PAGE
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NotifyPeException
;
;		DESCRIPTION:    Notify of a exception
;
;		PARAMETERS:		EBP		Exception frame
;						EAX		Exception code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_pe_exception_name DB 'Notify Pe Exception',0

notify_pe_exception	Proc far
	push ds
	push dx
;
    push ebx
	mov ebx,fs:pvModuleHandle
	DerefModuleHandle
	mov ds,bx
	pop ebx
;	
	mov dx,ds:lib_debug_lib
	or dx,dx
	jz neDone
;	
	pop dx
	pop ds
;
	sub sp,8
	push bp
	mov bp,sp
	push eax
	push ebx
	push ds
	push es
;
	mov ebx,fs:pvModuleHandle
	DerefModuleHandle
	mov ds,bx
	call ExceptionEvent
;
	mov ds,[bp].vm_ss
	mov ebx,[bp].vm_esp
;
	mov eax,[ebx]
	mov [bp].vm_eax,eax
	add ebx,4
;
	mov ax,[ebx]
	mov [bp].pm_ds,ax
	add ebx,4
;
	push bp
	mov ebp,[ebx]
	pop bp
	mov ax,[ebx]
	mov [bp].vm_bp,ax
	add ebx,4
;
	mov ax,[ebx]
	push ax
	add ebx,4
;
	add ebx,12
	mov eax,[ebx]
	mov [bp].vm_eip,eax
	add ebx,4
;
	mov ax,[ebx]
	mov [bp].vm_cs,ax
	add ebx,4
;
	mov eax,[ebx]
	SetFlags
	mov [bp].vm_eflags,eax	
	add ebx,4
;
	add ebx,8
	mov [bp].vm_esp,ebx
;
	GetThread
	push es
	mov es,ax
	mov ax,es:p_id
	pop es
	mov es:event_thread_id,ax
;
	mov ax,pe_app_sel
	mov ds,ax
	mov ds,ds:pe_app
	push esi
	mov esi,OFFSET lib_section
	EnterNewSection
	pop esi
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
	xor ax,ax
	mov es,ax
	cli
	push esi
	mov esi,OFFSET lib_section
	LeaveNewSection
	pop esi
;
	mov ax,ds:lib_debug_obj
	or ax,ax
	jz neSignalDone
;	
    mov es,ax
	SignalWait

neSignalDone:
	pop ax
	pop es
	DebugException

neDone:
	pop dx
	pop ds
	retf32
notify_pe_exception Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AllocateMem
;
;		DESCRIPTION:	Allocate memory
;
;		PARAMETERS:		EAX	Number of bytes
;
;		RETURNS:		EDX Offset within flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_mem	PROC far
	push ds
	push es
	push eax
	push ecx
	push esi
;
	dec eax
	and ax,0F000h
	add eax,1000h
	mov ecx,eax
	push ecx
	AllocateLocalLinear
	sub edx,local_page_linear
;
	mov eax,SIZE pe_mem_struc
	AllocateLocalMem
	pop ecx
	mov es:mem_base,edx
	mov es:mem_size,ecx
	mov ax,pe_app_sel
	mov ds,ax
	mov esi,OFFSET pe_section
	EnterNewSection
;
	mov ax,ds:pe_mem_blocks
	or ax,ax
	je alloc_ins_empty
;
	push ds
	mov ds,ax
	mov si,ds:mem_prev
	mov ds:mem_prev,es
	mov ds,si
	mov ds:mem_next,es
	mov es:mem_next,ax
	mov es:mem_prev,si
	pop ds
	jmp alloc_ins_done

alloc_ins_empty:
	mov es:mem_next,es
	mov es:mem_prev,es

alloc_ins_done:
	mov ds:pe_mem_blocks,es
	mov esi,OFFSET pe_section
	LeaveNewSection
;
    pop esi
	pop ecx
	pop eax
	pop es
	pop ds
	ret
allocate_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeMem
;
;		DESCRIPTION:	Free memory
;
;		PARAMETERS:		EDX Offset within flat selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_mem	PROC far
	push ds
	push es
	push eax
	push ecx
	push edx
	push esi
	push edi
;
	mov ax,pe_app_sel
	mov ds,ax
	mov esi,OFFSET pe_section
	EnterNewSection

free_mem_more:
	mov ax,ds:pe_mem_blocks
	or ax,ax
	jz free_mem_failed
	mov si,ax
free_mem_loop:
	mov es,ax

    cmp edx,es:mem_base
    je free_mem_ok

free_mem_next:
	mov ax,es:mem_next
	cmp ax,si
	jne free_mem_loop

free_mem_failed:
	jmp free_mem_done

free_mem_ok:
	mov edx,es:mem_base
	add edx,local_page_linear
	mov ecx,es:mem_size
	FreeLinear
	mov ds:pe_mem_blocks,es
	mov ax,es:mem_prev
	cmp ax,ds:pe_mem_blocks
	pushf
	push ds
	mov ds:pe_mem_blocks,ax
	mov si,es:mem_next
	mov ds,ax
	mov ds:mem_next,si
	mov ds,si
	mov ds:mem_prev,ax
	pop ds
	FreeMem
	popf
	jne free_mem_done

free_mem_last_block:
	mov ds:pe_mem_blocks,0

free_mem_done:
    mov esi,OFFSET pe_section
    LeaveNewSection
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	pop es
	pop ds
	ret
free_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReservePEMem
;
;		DESCRIPTION:	Reserve PE memory
;
;		PARAMETERS:		EAX	Number of bytes
;						BX  Handle of owner
;						EDX Offset within flat selector
;
;		RETURNS:		NC	SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reserve_pe_mem_name	DB 'Reserve PE Mem',0

reserve_pe_mem	PROC far
	push eax
	push edx
    add edx,local_page_linear
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
	retf32
reserve_pe_mem	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ShowExceptionText
;
;		DESCRIPTION:	Decide whether app should show exception text and
;                       exit or stop execution on exception.
;
;		RETURNS:		EAX  0 stop execution
;                            1 show exception text and exit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

show_exception_text_name	DB 'Show Exception Text',0

show_exception_text	PROC far
    push es
    push ebx
;    
    mov ebx,fs:pvModuleHandle
	DerefModuleHandle
	mov es,bx
	mov ax,es:lib_debug_lib
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
	retf32
show_exception_text	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_dll
;
;		DESCRIPTION:    Load DLL
;
;       PARAMETERS:		ES:EDI	name of dll to load
;
;		RETURNS:		BX      Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_dll	Proc far
	push ds
	push es
	push fs
	push gs
	push eax
	push ecx
	push edx
	push esi
	push edi
;
	mov al,es:[edi]
	mov esi,edi
	mov bx,word ptr fs:pvModuleHandle
    DerefModuleHandle
	jc load_dll_pr_done
;
    mov di,fs
	mov ax,es
	mov fs,ax
    mov es,bx
    mov es:lib_fs,di
	mov ax,flat_data_sel
	mov ds,ax
	call LoadPeDll
	mov bx,es

load_dll_pr_done:	
	pop edi
	pop esi
	pop edx
	pop ecx
	pop eax
	pop gs
	pop fs
	pop es
	pop ds
	ret
load_dll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			free_dll
;
;		DESCRIPTION:    Free DLL
;
;       PARAMETERS:		ES		Lib sel
;                       BX      Lib sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_dll	Proc far
	call FreePeDll
	ret
free_dll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetModuleProc
;
;		DESCRIPTION:    Get module procedure
;
;       PARAMETERS:		BX		Lib sel
;						ES:EDI	Proc name
;						
;		RETURNS:		DS:ESI	Proc address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_proc	Proc far
	push eax
	push ebx
	push ecx
	push edx
;
	push es
	mov es,bx
	mov edx,es:lib_base
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
get_module_proc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetModuleName
;
;		DESCRIPTION:    Get module name
;
;       PARAMETERS:		BX		Handle
;						ECX		Max name size
;						ES:EDI	Name buffer
;						
;		RETURNS:		EAX		Bytes copied
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_module_name	Proc far
	or ecx,ecx
	clc
	jz get_name_done
;
	push ds
	push ebx
	push ecx
	push si
	push edi
;
	xor eax,eax
	mov ds,bx
	xor ebx,ebx
	mov si,OFFSET lib_name
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
	pop si
	pop ecx
	pop ebx
	pop ds
	clc

get_name_done:
	ret
get_module_name	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDll
;
;		DESCRIPTION:    Get DLL handle
;
;       PARAMETERS:		ES:EDI	DLL name
;						
;		RETURNS:		EBX		DLL handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dll_handle_name	DB 'Get DLL',0

get_dll_handle	Proc far
	push es
	push fs
	push esi
;
	mov si,es
	mov fs,si
	mov esi,edi
;
	call FindSysDll
	jnc get_dll_handle_ok
;
	call FindDll
	jnc get_dll_handle_ok
;
	call FindApp
	jc get_dll_handle_done

get_dll_handle_ok:
	movzx ebx,es:mod_handle

get_dll_handle_done:
	pop esi
	pop fs
	pop es
	retf32
get_dll_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDllResource
;
;		DESCRIPTION:    Get DLL resource
;
;       PARAMETERS:		BX      Lib sel
;						EAX		Resource id
;						EDX		Resource type
;						
;		RETURNS:		DS:ESI	Resource VA
;						ECX		Resource size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_resource	Proc far
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
	mov edx,es:lib_base
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
	add esi,es:lib_base
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
get_resource	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitProcess
;
;		DESCRIPTION:    init a process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process	Proc far
	push ds
	push esi
;	
	mov ax,pe_process_sel
	mov ds,ax
	mov ds:ppe_dlls,0
	mov esi,OFFSET ppe_section
	InitNewSection
;
    pop esi	
	pop ds
	ret
init_process	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenApp
;
;		DESCRIPTION:    open app callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_app	Proc far
	push ds
	push esi
;	
	mov ax,pe_app_sel
	mov ds,ax
	mov ds:pe_dlls,0
	mov ds:pe_app,0
	mov ds:pe_mem_blocks,0
	mov esi,OFFSET pe_section
	InitNewSection
;
    pop esi	
	pop ds
	ret
open_app	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			close_app
;
;		DESCRIPTION:    Close app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_app	Proc far
	mov ax,pe_app_sel
	mov ds,ax
	mov ax,ds:pe_app
	or ax,ax
	jz close_app_done
;	
    mov es,ax
    ResetModule
;
	mov ax,flat_data_sel
	mov ds,ax
	xor edx,edx
	mov eax,-1
	mov bx,es
	UserGateForce32 free_app_mem_nr
	mov edi,es:lib_base
	push es
	call FreeImportedDlls
	pop es
;
	mov esi,es:lib_header
	mov eax,[esi].peh_tls_va
	or eax,eax
	jz unload_no_tls
;
	add eax,edi
	mov edx,[eax].tls_index_va
	mov edx,[edx]
	mov esi,fs:pvTLSArray
	mov edx,[esi+4*edx]
	add edx,local_page_linear
;
	mov ecx,[eax].tls_end_data_va
	sub ecx,[eax].tls_start_data_va
	FreeLinear

unload_no_tls:
	mov edx,es:lib_base
	mov ecx,es:lib_size
	mov bx,es:lib_file_handle
	CloseFile
	add edx,local_page_linear
	FreeLinear
	FreeMem
;
	mov edx,fs:pvStackUserBottom
	add edx,local_page_linear
	mov ecx,fs:pvStackUserSize
	FreeLinear	
	mov ax,fs
	mov es,ax
	xor ax,ax
	mov fs,ax
	FreeMem

close_app_done:
	ret
close_app	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetExeName
;
;		DESCRIPTION:    Get exe-file name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exe_name	Proc far
	push ds
	push eax
	push ebx
	push ecx
	push edx
	push esi
;
	mov ax,pe_app_sel
	mov ds,ax
	mov edi,ds:pe_exe_name
	or edi,edi
	jnz get_exe_done
;	
	mov ax,thread_app_sel
	mov ds,ax
	mov si,OFFSET app_exe_name

get_exe_size_loop:
	lodsb
	or al,al
	jnz get_exe_size_loop
;
	mov ax,si
	sub ax,OFFSET app_exe_name
	movzx eax,ax
	mov ecx,eax
	UserGateForce32 allocate_app_mem_nr
	mov edi,edx
	mov esi,OFFSET app_exe_name
	rep movs byte ptr es:[edi],[esi]
;
	mov ax,pe_app_sel
	mov ds,ax
	mov ds:pe_exe_name,edx
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
get_exe_name	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetEnv
;
;		DESCRIPTION:    Get environment block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env	Proc far
	push ds
	push eax
	push ebx
	push ecx
	push edx
	push esi
;
	mov ax,pe_app_sel
	mov ds,ax
	mov edi,ds:pe_env
	or edi,edi
	jnz get_env_done
;	
    LockProcEnv
	mov ds,bx
	xor si,si

get_env_size_loop:
	lodsb
	or al,al
	jnz get_env_size_loop
;
	lodsb
	or al,al
	jnz get_env_size_loop
;
	movzx ecx,si
	mov eax,ecx
	UserGateForce32 allocate_app_mem_nr
	mov edi,edx
	xor esi,esi
	rep movs byte ptr es:[edi],[esi]
;
	mov ax,pe_app_sel
	mov ds,ax
	mov ds:pe_env,edx
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
get_env	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetCmdLine
;
;		DESCRIPTION:    Get command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cmd_line	Proc far
	push ds
	mov di,pe_app_sel
	mov ds,di
	mov edi,ds:pe_cmd_line
	clc
	pop ds
	ret
get_cmd_line	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetOptions
;
;		DESCRIPTION:    Set options
;
;       PARAMETERS:     ES  Option selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_options	Proc far
	push ds
	push es
	pusha
;
    mov ax,es
    mov ds,ax
    xor si,si
    xor cx,cx

set_opt_size:
    lodsb
    inc cx
    or al,al
    jnz set_opt_size
;
    lodsb
    inc cx
    or al,al
    jnz set_opt_size
;
	mov eax,ecx
	UserGateForce32 allocate_app_mem_nr
	mov edi,edx
	xor esi,esi
	mov ax,flat_data_sel
	mov es,ax
	rep movs byte ptr es:[edi],[esi]
;        
   	mov ax,pe_app_sel
	mov ds,ax
	mov ds:pe_options,edx
;
	clc
	popa
	pop es
	pop ds
	ret
set_options	Endp
                                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetOptions
;
;		DESCRIPTION:    Get options
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_options	Proc far
	push ds
	mov di,pe_app_sel
	mov ds,di
	mov edi,ds:pe_options
	clc
	pop ds
	ret
get_options	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:    Init pe loader module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
;
	mov bx,pe_code_sel
	InitDevice
;
	mov bx,pe_app_sel
	mov eax,SIZE pe_data_seg
	AllocateFixedAppMem
;
	mov bx,pe_process_sel
	mov eax,SIZE pe_process_seg
	AllocateFixedProcessMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_process
	HookCreateProcess
;
	mov di,OFFSET start_thread
	HookCreateThread
;
	mov di,OFFSET load_pe
	HookLoadExe
;
	mov di,OFFSET open_app
	HookOpenApp
;
	mov di,OFFSET close_app
	HookCloseApp
;
	mov si,OFFSET notify_pe_exception
	mov di,OFFSET notify_pe_exception_name
	xor dx,dx
	mov ax,notify_pe_exception_nr
	RegisterUserGate32
;
	mov si,OFFSET get_dll_handle
	mov di,OFFSET get_dll_handle_name
	xor dx,dx
	mov ax,get_module_nr
	RegisterUserGate32
;
	mov si,OFFSET reserve_pe_mem
	mov di,OFFSET reserve_pe_mem_name
	xor dx,dx
	mov ax,reserve_pe_mem_nr
	RegisterUserGate32
;
	mov si,OFFSET show_exception_text
	mov di,OFFSET show_exception_text_name
	xor dx,dx
	mov ax,show_exception_text_nr
	RegisterUserGate32
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code    ENDS

        END init
