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
; EXEC.ASM
; Basic executable loader support module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  Exec

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE system.def
INCLUDE system.inc
INCLUDE protseg.def
INCLUDE driver.def
INCLUDE int.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE exec.def

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_LOAD_EXE
;
;		DESCRIPTION:	Add hook for LoadExe
;
;		PARAMETERS:		ES:DI		Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_load_exe_name	DB 'Hook Load Exe',0

hook_load_exe	PROC far
	push ds
	push ax
	push bx
	mov ax,exec_sys_sel
	mov ds,ax
	mov al,ds:load_exe_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET load_exe_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:load_exe_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_load_exe	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LOAD_EXE_FILE
;
;		DESCRIPTION:	Load executable file
;
;		PARAMETERS:     BX		File handle
;						DS:ESI	File name
;						ES:EDI	Command line
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_exe_file	PROC near
	mov ax,exec_sys_sel
	mov fs,ax
	mov cl,fs:load_exe_hooks
	or cl,cl
	stc
	je load_exe_file_done
;
	mov ax,OFFSET load_exe_arr

load_exe_file_loop:
	push fs
	push ax
	push cx
;
	push bx
	mov bx,ax
	mov eax,fs:[bx]
	pop bx
;
	push cs
	push OFFSET load_exe_file_ret
	push eax
	retf

load_exe_file_ret:
	pop cx
	pop ax
	pop fs
	jnc load_exe_file_done
;
	add ax,4
	dec cl
	jnz load_exe_file_loop
;
	stc

load_exe_file_done:
	ret
load_exe_file	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			enter_load
;
;		DESCRIPTION:   	Make a global copy of parameters
;
;		PARAMETERS:     DS:ESI		Filename
;						ES:EDI		Command line
;
;       RETURN VALUE:   DS:ESI		Global filename
;						ES:EDI		Global command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_load	Proc near
	push eax
	push ecx
;
	xor ecx,ecx
	push esi

enter_clone_file_size_loop:
	lods byte ptr [esi]
	or al,al
	jz enter_clone_file_size_ok
;
	inc ecx
	jmp enter_clone_file_size_loop

enter_clone_file_size_ok:
	pop esi
;
	push es
	push edi
	inc ecx	
	mov eax,ecx
	AllocateSmallGlobalMem
	xor edi,edi
	rep movs byte ptr es:[edi],[esi]
	mov ax,es
	mov ds,ax
	pop edi
	pop es
;
	xor ecx,ecx
	push edi

enter_clone_cmd_size_loop:
	mov al,es:[edi]
	inc edi
	or al,al
	jz enter_clone_cmd_size_ok
;
	inc ecx
	jmp enter_clone_cmd_size_loop

enter_clone_cmd_size_ok:
	pop edi
;
	inc ecx
	push ds
	push esi
	mov ax,es
	mov ds,ax
	mov esi,edi
	mov eax,ecx
	AllocateSmallGlobalMem
	xor edi,edi
	rep movs byte ptr es:[edi],[esi]
	mov ax,es
	mov ds,ax
	pop esi
	pop ds
;
	xor esi,esi
	xor edi,edi
;
	pop ecx
	pop eax
	ret
enter_load	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			leave_load
;
;		DESCRIPTION:    Free global copy of parameters
;
;		PARAMETERS:     DS:ESI		Filename
;						ES:EDI		Command line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_load	Proc near
	push ax
	FreeMem
	mov ax,ds
	mov es,ax
	xor ax,ax
	mov ds,ax
	FreeMem
	pop ax
	ret
leave_load	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_program16/32
;
;		DESCRIPTION:    Load executable file
;
;		PARAMETERS:     DS:(E)SI	Filename
;						ES:(E)DI	Command line
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_exe_name	DB 'Load Exe',0
	
load_program16:
	pop ax
	pop dx
	movzx edx,dx
	push edx
	movzx eax,ax
	push eax
	SimSti
	SaveContext
	xor eax,eax
	push eax
	push eax
	push eax
	push eax
	push eax
	push eax
	push eax
;
	movzx esi,si
	movzx edi,di
	GetPsp
	call enter_load
	OpenApp
	SetPsp
	push es
	push di
	mov ax,thread_app_sel
	mov es,ax
	mov es:app_context,bx
;
	mov di,si
	mov ax,ds
	mov es,ax
	xor cx,cx
	OpenFile
	pop di
	pop es
	jc load_fail16
;
	call load_exe_file
	jc load_close_fail16
;
	call leave_load
	test byte ptr [bp+2].load_eflags,2
	jnz load_prog_vm16
;
	mov ds,[bp].load_ds
	mov es,[bp].load_es
	mov fs,[bp].load_fs
	mov gs,[bp].load_gs

load_prog_vm16:
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	iretd

load_close_fail16:
	CloseFile

load_fail16:
	call leave_load
	CloseApp
;
	mov ax,thread_app_sel
	mov ds,ax
	mov bx,ds:app_context
	RestoreContext
	stc
	retf32
	
load_program32:
	SimSti
	SaveContext
	xor eax,eax
	push eax
	push eax
	push eax
	push eax
	push eax
	push eax
	push eax
;
	call enter_load
	OpenApp
	push es
	push edi
	mov ax,thread_app_sel
	mov es,ax
	mov es:app_context,bx	
	mov edi,esi
	mov ax,ds
	mov es,ax
	xor cx,cx
	UserGateForce32 open_file_nr
	pop edi
	pop es
	jc load_fail32
;
	call load_exe_file
	jc load_close_fail32
;
	call leave_load
	mov ds,[bp].load_ds
	mov es,[bp].load_es
	mov fs,[bp].load_fs
	mov gs,[bp].load_gs
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	iretd

load_close_fail32:
	CloseFile

load_fail32:
	call leave_load
	CloseApp
;
	mov ax,thread_app_sel
	mov ds,ax
	mov bx,ds:app_context
	RestoreContext
	stc
	retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load_process
;
;		DESCRIPTION:    Run program as process
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_cmd_line	DB 0, 0Dh

load_process:
	SimSti
	mov ax,exec_sys_sel
	mov ds,ax
	mov ax,ds:focus_nr
	inc ds:focus_nr
	EnableFocus
	SetFocus
	mov es,bx
	xor di,di
	mov al,es:[di+1]
	cmp al,':'
	jne load_process_default_drive
	mov al,es:[di]
	sub al,'a'
	jnc load_process_set_drive
	add al,20h
load_process_set_drive:
	SetCurDrive
load_process_default_drive:
	SaveContext
	xor eax,eax
	push eax
	push eax
	push eax
	push eax
	push eax
	push eax
	push eax
;
	push ds
	mov ax,thread_app_sel
	mov ds,ax
	mov ds:app_context,bx
	mov ax,es
	mov ds,ax
	mov si,di
	xor bx,bx
	pop ds
	movzx edi,di
	xor cl,cl
	OpenFile
	jc load_process_fail
;
	mov ax,es
	mov ds,ax
	xor esi,esi
	mov ax,cs
	mov es,ax
	mov di,OFFSET load_cmd_line
	call load_exe_file
	jc load_process_close_fail
;
	test byte ptr [bp+2].load_eflags,2
	jnz load_process_vm
;
	mov ds,[bp].load_ds
	mov es,[bp].load_es
	mov fs,[bp].load_fs
	mov gs,[bp].load_gs

load_process_vm:
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	iretd

load_process_close_fail:
	CloseFile

load_process_fail:
	TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			spawn_program16/32
;
;		DESCRIPTION:    Load & detach executable file
;
;		PARAMETERS:     DS:(E)SI	Filename
;						ES:(E)DI	Command line
;						EDX			Loader parameter
;
;       RETURN VALUE:   AX		Thread handle
;						DX		Application handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawn_exe_name	DB 'Spawn Exe',0

spawn_startup	Proc far
	mov gs,bx
	mov ax,exec_sys_sel
	mov ds,ax
	mov ax,ds:focus_nr
	inc ds:focus_nr
	EnableFocus
	SetFocus
	SaveContext
	xor eax,eax
	push eax
	push eax
	push eax
	push eax
	push eax
	push eax
	push eax
;
	mov ax,thread_app_sel
	mov ds,ax
	mov ds:app_context,bx
	mov ax,es
	mov ds,ax
	mov si,di
	xor bx,bx
;
	xor di,di
	mov es,gs:s_name
	xor cx,cx
	OpenFile
	jc spawn_fail
;
	xor esi,esi
	xor edi,edi
	mov ds,gs:s_name
	mov es,gs:s_cmd
;
	call load_exe_file
	jc spawn_close_fail
;
	mov gs:s_ret_code,0
	GetThread
	mov gs:s_thread,ax
	mov ax,thread_app_sel
	mov ds,ax
	mov ax,ds:app_sel
	mov gs:s_app,ax
	mov ax,gs
	mov ds,ax
	mov es,ax
	LeaveSection ds:s_sect1
	EnterSection ds:s_sect2
;
	mov ax,10
	WaitMilliSec
;
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_spawn_proc
	or eax,eax
	jz spawn_notify_done
;
	call ds:app_spawn_proc

spawn_notify_done:
	mov ds,gs:s_name
	mov es,gs:s_cmd
	call leave_load
;
	mov ax,gs
	mov es,ax
	xor ax,ax
	mov gs,ax
	FreeMem
;
	test byte ptr [bp+2].load_eflags,2
	jnz spawn_vm16
;
	mov ds,[bp].load_ds
	mov es,[bp].load_es
	mov fs,[bp].load_fs
	mov gs,[bp].load_gs

spawn_vm16:
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	iretd

spawn_close_fail:
	CloseFile

spawn_fail:
	mov gs:s_ret_code,-1
	mov ax,gs
	mov ds,ax
	LeaveSection ds:s_sect1
	EnterSection ds:s_sect2
;
	mov ax,10
	WaitMilliSec
;
	mov ds,gs:s_name
	mov es,gs:s_cmd
	call leave_load
;
	mov ax,gs
	mov es,ax
	xor ax,ax
	mov gs,ax
	FreeMem
;
	mov ax,thread_app_sel
	mov ds,ax
	mov bx,ds:app_context
	RestoreContext
	ret
spawn_startup	Endp

spawn_program	Proc near
	push ds
	push es
	push fs
	push bx
	push cx
	push esi
	push edi
;
	call enter_load
	push es
	mov eax,SIZE spawn_struc
	AllocateSmallGlobalMem
	mov ax,es
	mov fs,ax
	pop es
	mov fs:s_name,ds
	mov fs:s_cmd,es
	mov fs:s_param,edx
;
	push ds
	mov ax,thread_app_sel
	mov ds,ax
	mov eax,ds:app_loader_name
	mov fs:s_loader_name,eax
	pop ds
;
	mov fs:s_sect1.cs_value,-1
	mov fs:s_sect1.cs_list,0
	mov fs:s_sect2.cs_value,-1
	mov fs:s_sect2.cs_list,0
;	
	mov ax,ds
	mov es,ax
	mov ax,cs
	mov ds,ax
	mov ax,cs
	mov ds,ax
	mov si,OFFSET spawn_startup
	mov bx,fs
	mov ax,2
	mov ecx,200h
	CreateProcess
;
	mov ax,fs
	mov ds,ax
	EnterSection ds:s_sect1
	mov ax,ds:s_thread
	mov dx,ds:s_app
	mov bx,ds:s_ret_code
	LeaveSection ds:s_sect2
;
	xor cx,cx
	mov ds,cx
	mov fs,cx
;
	or bx,bx
	jz spawn_ok
;
	stc
	jmp spawn_done

spawn_ok:
	clc

spawn_done:
	pop edi
	pop esi
	pop cx
	pop bx
	pop fs
	pop es
	pop ds
	ret
spawn_program	Endp
	
spawn_program16	Proc far
	push esi
	push edi
;
	movzx esi,si
	movzx edi,di
	call spawn_program
;
	pop edi
	pop esi
	ret
spawn_program16	Endp
	
spawn_program32	Proc far
	call spawn_program
	retf32
spawn_program32	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			unload_exe
;
;		DESCRIPTION:    Unload running program
;
;		PARAMETERS:		AX		Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unload_exe_name DB 'Unload Exe',0
	
unload_exe	Proc far
	push ax
	UnhookKeyboard
	UnhookMouse
	mov ax,thread_app_sel
	mov ds,ax
	push ds:app_context
	CloseApp
	pop bx
	mov ax,thread_app_sel
	mov ds,ax
	pop ax
	mov ds:app_exit_code,ax
	RestoreContext
	clc
	retf32
unload_exe	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetExitCode
;
;		DESCRIPTION:    Get exit code
;
;		RETURNS:		AX		Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_exit_code_name DB 'Get Exit Code',0
	
get_exit_code	Proc far
	push ds
	mov ax,thread_app_sel
	mov ds,ax
	mov ax,ds:app_exit_code
	pop ds
	retf32
get_exit_code	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			run_process
;
;		DESCRIPTION:	Run processes in adapter
;
;		PARAMETERS:		DS:EDX	device header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

run_process	PROC near
	push ds
	push es
	pushad
	mov ecx,[edx].len
	sub ecx,SIZE rdos_header
	add edx,SIZE rdos_header
    mov esi,edx
	mov eax,1000h
	AllocateGlobalMem
	xor edi,edi
	rep movs dword ptr es:[edi],[esi]
	xor edi,edi
	mov bx,es
	mov ax,cs
	mov ds,ax
	mov si,OFFSET load_process
	mov ax,2
	mov ecx,200h
	CreateProcess
	popad
	pop es
	pop ds
	ret
run_process	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_adapter_process
;
;		DESCRIPTION:	Start all processes in adapter
;
;		PARAMETERS:		edx		base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_adapter_process	Proc near
	push ds
	push ax
	push bx
	push edx
	mov ax,flat_sel
	mov ds,ax
init_adapter_process_loop:
	mov ax,[edx].typ
	cmp ax,RdosCommand
	jne not_run_process
	call run_process
	jmp init_adapter_process_next
not_run_process:
	cmp ax,RdosEnd
	je init_adapter_process_done
init_adapter_process_next:
	add edx,[edx].len
	jmp init_adapter_process_loop
init_adapter_process_done:
	pop edx
	pop bx
	pop ax
	pop ds
	ret
init_adapter_process	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_sys
;
;		DESCRIPTION:    Start all processes
;
;       RETURN VALUE:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sys	PROC far
	push ds
	push es
	pushad
;
	mov ax,system_data_sel
	mov ds,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
init_sys_loop:
	mov edx,[bx].adapter_base
	call init_adapter_process
	add bx,SIZE adapter_typ
	loop init_sys_loop
;
	popad
	pop es
	pop ds
	ret
init_sys	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_exec
;
;		DESCRIPTION:    init module
;
;       RETURN VALUE:   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_exec

init_exec	PROC near
	pusha
	push ds
;
	mov eax,SIZE exec_sys_seg
	mov bx,exec_sys_sel
	AllocateFixedSystemMem
	mov es:focus_nr,3Bh
	mov es:load_exe_hooks,0
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_sys
	HookInitTasking
;
	mov si,OFFSET hook_load_exe
	mov di,OFFSET hook_load_exe_name
	xor cl,cl
	mov ax,hook_load_exe_nr
	RegisterOsGate
;
	mov si,OFFSET load_program16
	mov di,OFFSET load_exe_name
	xor cl,cl
	mov ax,load_exe_nr
	RegisterUserGate16
;
	mov si,OFFSET load_program32
	xor cl,cl
	mov ax,load_exe_nr
	RegisterUserGate32
;
	mov si,OFFSET load_program16
	mov bx,ax
	mov dx,virt_ds_in OR virt_es_in
	mov ax,load_virt_exe_nr
	RegisterVirtUserGate
;
	mov si,OFFSET unload_exe
	mov di,OFFSET unload_exe_name
	xor cl,cl
	mov ax,unload_exe_nr
	RegisterUserGate
;
	mov si,OFFSET spawn_program16
	mov di,OFFSET spawn_exe_name
	xor cl,cl
	mov ax,spawn_exe_nr
	RegisterUserGate16
;
	mov si,OFFSET spawn_program32
	mov di,OFFSET spawn_exe_name
	xor cl,cl
	mov ax,spawn_exe_nr
	RegisterUserGate32
;
	mov bx,ax
	mov dx,virt_es_in OR virt_ds_in
	mov ax,spawn_virt_exe_nr
	RegisterVirtUserGate
;
	mov si,OFFSET get_exit_code
	mov di,OFFSET get_exit_code_name
	xor cl,cl
	mov ax,get_exit_code_nr
	RegisterUserGate
;
	pop ds
	popa
	ret
init_exec	ENDP


code    ENDS

        END
