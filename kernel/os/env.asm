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
; ENV.ASM
; Environment string handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME env

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\handle.inc

	.386p

ENV_MODE_GLOBAL		= 1
ENV_MODE_PROCESS	= 2

env_handle_seg	STRUC

env_handle_base	handle_header <>

env_handle_mode	DB ?

env_handle_seg	ENDS

env_sys_seg  STRUC

env_sys_section     section_typ <>

env_sys_raw_sel         DW ?

env_sys_seg  ENDS

env_proc_seg  STRUC

env_proc_section     section_typ <>

env_proc_raw_sel         DW ?

env_proc_seg  ENDS

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			load_set_var
;
;		DESCRIPTION:	Load SET variables
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_set_var	Proc near
	push ax
	push edx
	push esi
	add edx,SIZE rdos_header
	mov esi,edx	
	
init_set_var_loop:
	lods byte ptr [esi]
	stosb
	or al,al
	jne init_set_var_loop
;
	pop esi
	pop edx
	pop ax
	ret
load_set_var	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			load_path
;
;		DESCRIPTION:	Load PATH variables
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

path_text DB 'PATH'

load_path	Proc near
	push eax
	push edx
	push esi
	add edx,SIZE rdos_header
	mov esi,edx
	mov eax,dword ptr cs:path_text
	stosd
	mov al,'='
	stosb
init_path_var_loop:
	lods byte ptr [esi]
	stosb
	or al,al
	jne init_path_var_loop
	pop esi
	pop edx
	pop eax
	ret
load_path	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			load_adapter_env
;
;		DESCRIPTION:	Install all variables from adapter
;
;		PARAMETERS:		edx		base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

load_adapter_env	Proc near
	push ds
	push ax
	push bx
	push edx
	mov ax,flat_sel
	mov ds,ax
load_adapter_env_loop:
	mov ax,[edx].typ
	cmp ax,RdosSet
	jne not_load_set
	call load_set_var
	jmp load_adapter_env_next
not_load_set:
	cmp ax,RdosPath
	jne not_load_path
	call load_path
	jmp load_adapter_env_next
not_load_path:
	cmp ax,RdosEnd
	je load_adapter_env_done
load_adapter_env_next:
	add edx,[edx].len
	jmp load_adapter_env_loop
load_adapter_env_done:
	pop edx
	pop bx
	pop ax
	pop ds
	ret
load_adapter_env	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    LockSysEnv
;
;		DESCRIPTION:	Lock system env and return raw data selector
;
;		RETURNS:		BX			Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_sys_env_name	DB 'Lock Sys Env',0

lock_sys_env    Proc far
    push ds
;
    mov bx,env_sys_sel
    mov ds,bx
    EnterSection ds:env_sys_section
    mov bx,ds:env_sys_raw_sel
;
    pop ds
    ret
lock_sys_env    Endp
   
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    UnlockSysEnv
;
;		DESCRIPTION:	Unlock system env
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_sys_env_name	DB 'Unlock Sys Env',0

unlock_sys_env    Proc far
    push ds
    push bx
;
    mov bx,env_sys_sel
    mov ds,bx
    LeaveSection ds:env_sys_section
;
    pop bx
    pop ds
    ret
unlock_sys_env    Endp
   
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    LockProcEnv
;
;		DESCRIPTION:	Lock process env and return raw data selector
;
;		RETURNS:		BX			Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_proc_env_name	DB 'Lock Proc Env',0

lock_proc_env    Proc far
    push ds
;
    mov bx,env_proc_sel
    mov ds,bx
    EnterSection ds:env_proc_section
    mov bx,ds:env_proc_raw_sel
;
    pop ds
    ret
lock_proc_env    Endp
   
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    UnlockProcEnv
;
;		DESCRIPTION:	Unlock process env
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_proc_env_name	DB 'Unlock Proc Env',0

unlock_proc_env    Proc far
    push ds
    push bx
;
    mov bx,env_proc_sel
    mov ds,bx
    LeaveSection ds:env_proc_section
;
    pop bx
    pop ds
    ret
unlock_proc_env    Endp
   
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    OpenSysEnv
;
;		DESCRIPTION:	Open system envvar handle
;
;		RETURNS:		BX			Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_sys_env_name	DB 'Open Sys Env',0

open_sys_env    Proc far
    push ds
	push cx
;
	mov cx,SIZE env_handle_seg
	AllocateHandle
	mov [bx].env_handle_mode,ENV_MODE_GLOBAL
	mov [bx].hh_sign,ENV_HANDLE
	mov bx,[bx].hh_handle
;
	pop cx
	pop ds
    retf32
open_sys_env    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    OpenProcEnv
;
;		DESCRIPTION:	Open process envvar handle
;
;		RETURNS:		BX			Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_proc_env_name	DB 'Open Proc Env',0

open_proc_env    Proc far
    push ds
	push cx
;
	mov cx,SIZE env_handle_seg
	AllocateHandle
	mov [bx].env_handle_mode,ENV_MODE_PROCESS
	mov [bx].hh_sign,ENV_HANDLE
	mov bx,[bx].hh_handle
;
	pop cx
	pop ds
    retf32
open_proc_env    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CloseEnv
;
;		DESCRIPTION:	Close envvar handle
;
;		PARAMETERS:		BX			Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_env_name	DB 'Close Env',0

close_env   Proc far
    push ds
    push es
    push ax
;
	mov ax,ENV_HANDLE
	DerefHandle
	jc close_env_done
;
	FreeHandle
	clc

close_env_done:
    pop ax
    pop es
    pop ds
    retf32
close_env   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddEnvVar
;
;		DESCRIPTION:	Add a envvar
;
;		PARAMETERS:		BX			Handle
;                       DS:(E)SI    Env var name buffer
;                       ES:(E)DI    Env var data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_env_var_name	DB 'Add Env Var',0

add_env_base	Proc near
    push es
    push edi
;
    mov es,bx
    mov ebp,esi
    xor edi,edi

add_env_search_loop:
	cmps byte ptr ds:[esi],es:[edi]
	jnz add_env_next
;
	mov al,[esi]
	or al,al
	jnz add_env_search_loop
;
	mov al,es:[edi]
	cmp al,'='
	je add_env_var_found

add_env_next:
    mov al,es:[edi]
    inc edi
	or al,al
	jnz add_env_next
;
	mov al,es:[edi]
	or al,al
	mov esi,ebp
	jne add_env_search_loop
	jmp add_env_new

add_env_var_found:
    inc edi
    push esi
    push edi
;
    xor ebx,ebx
    xor ecx,ecx

add_env_curr_var_loop:
    inc edi
    inc ebx
    mov al,es:[edi]
    or al,al
    jnz add_env_curr_var_loop
;
    inc ecx
    jmp add_env_check_end

add_env_size_var_loop:
    inc edi
    inc ecx
    mov al,es:[edi]
    or al,al
    jnz add_env_size_var_loop

add_env_check_end:
    inc edi
    inc ecx
    mov al,es:[edi]
    or al,al
    jnz add_env_size_var_loop
;
    pop edi
    pop esi
;
    mov edx,ecx
    push esi
    push edi
    mov esi,edi
    add esi,ebx
    rep movs byte ptr es:[edi],es:[esi]
    pop edi
    pop esi
;
    pop esi
    pop ds
;
    push esi
    xor ecx,ecx

add_env_data_size_loop:
    lods byte ptr [esi]
    inc ecx
    or al,al
    jnz add_env_data_size_loop
;
    push ecx
    push edi
;    
    mov esi,edi
    add edi,ecx
    dec edi
    mov ecx,edx
    add esi,ecx
    add edi,ecx
    dec esi
    dec edi
    std
    rep movs byte ptr es:[edi],es:[esi]
    cld
;
    pop edi
    pop ecx
    pop esi
;
    rep movs byte ptr es:[edi],[esi]
    clc
    jmp add_env_base_done

add_env_new:
	mov esi,ebp

add_env_new_var:
    lods byte ptr [esi]
    or al,al
    jz add_env_assign
;
    stos byte ptr es:[edi]
    jmp add_env_new_var

add_env_assign:
    mov al,'='
    stos byte ptr es:[edi]
;
    pop esi
    pop ds

add_env_new_data:
    lods byte ptr [esi]
    stos byte ptr es:[edi]
    or al,al
    jnz add_env_new_data
;
    xor al,al
    stos byte ptr es:[edi]

add_env_base_done:
	ret
add_env_base	Endp

add_env_var    Proc near
    push ds
    push es
    pushad
;
    push ds
	mov ax,ENV_HANDLE
	DerefHandle
	mov al,[bx].env_handle_mode
	pop ds
	jc add_env_var_done
;
	cmp al,ENV_MODE_GLOBAL
	je add_sys_env
;
    LockProcEnv
	call add_env_base
    pushf
    UnlockProcEnv
    popf
	jmp add_env_var_done

add_sys_env:
    LockSysEnv
	call add_env_base
    pushf
    UnlockSysEnv
    popf

add_env_var_done:    
    popad
    pop es
    pop ds
    ret
add_env_var    Endp

add_env_var16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call add_env_var
;
    pop edi
    pop esi
    ret
add_env_var16  Endp

add_env_var32:
    call add_env_var
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    DeleteEnvVar
;
;		DESCRIPTION:	Delete an envvar
;
;		PARAMETERS:		BX			Handle
;                       DS:(E)SI    Env var name buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_env_var_name	DB 'Delete Env Var',0

delete_env_base	Proc near
    mov ebp,esi
    xor edi,edi
	xor ecx,ecx
	xor ebx,ebx

del_env_search_loop:
	cmps byte ptr ds:[esi],es:[edi]
	jnz del_env_next
;
	inc ebx
	mov al,[esi]
	or al,al
	jnz del_env_search_loop
;
	mov al,es:[edi]
	cmp al,'='
	je del_env_var_found

del_env_next:
    mov al,es:[edi]
    inc edi
	or al,al
	jnz del_env_next
;
	mov esi,ebp
	xor ebx,ebx
	mov al,es:[edi]
	or al,al
	jne del_env_search_loop
;
	stc
	jmp del_env_base_done

del_env_var_found:
	mov eax,edi
	sub eax,ebx
	push eax
    inc edi
	inc ebx

del_env_data_loop:
    inc edi
    inc ebx
    mov al,es:[edi]
    or al,al
    jnz del_env_data_loop
;
    inc ebx
    jmp del_env_check_end

del_env_size_var_loop:
    inc edi
    inc ecx
    mov al,es:[edi]
    or al,al
    jnz del_env_size_var_loop

del_env_check_end:
    inc edi
    inc ecx
    mov al,es:[edi]
    or al,al
    jnz del_env_size_var_loop
;
    pop edi
;
    mov edx,ecx
    mov esi,edi
    add esi,ebx
    rep movs byte ptr es:[edi],es:[esi]
    clc

del_env_base_done:
	ret
delete_env_base	Endp    

delete_env_var    Proc near
    push ds
    push es
    pushad
;
    push ds
	mov ax,ENV_HANDLE
	DerefHandle
	mov al,[bx].env_handle_mode
	pop ds
	jc del_env_var_done
;
	cmp al,ENV_MODE_GLOBAL
	je del_sys_env
;
    LockProcEnv
    mov es,bx
	call delete_env_base
    pushf
    UnlockProcEnv
    popf
	jmp del_env_var_done

del_sys_env:
    LockSysEnv
    mov es,bx
	call delete_env_base
    pushf
    UnlockSysEnv
    popf

del_env_var_done:    
    popad
    pop es
    pop ds
    ret
delete_env_var    Endp

delete_env_var16  Proc far
    push esi
    movzx esi,si
    call delete_env_var
    pop esi
    ret
delete_env_var16  Endp

delete_env_var32:
    call delete_env_var
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    FindEnvVar
;
;		DESCRIPTION:	Find a envvar
;
;		PARAMETERS:		BX			Handle
;                       DS:(E)SI    Env var name buffer
;                       ES:(E)DI    Env var data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

find_env_var_name	DB 'Find Env Var',0

find_env_base	Proc near
    push es
    push edi
;
    mov es,bx
    mov ebp,esi
    xor edi,edi

find_env_search_loop:
	cmps byte ptr ds:[esi],es:[edi]
	jnz find_env_next
;
	mov al,[esi]
	or al,al
	jnz find_env_search_loop
;
	mov al,es:[edi]
	cmp al,'='
	je find_env_var_found

find_env_next:
    mov al,es:[edi]
    inc edi
	or al,al
	jnz find_env_next
;
	mov esi,ebp
	mov al,es:[edi]
	or al,al
	jne find_env_search_loop
;
    pop edi
    pop es
;
    xor al,al
    stos byte ptr es:[edi]
	stc
	jmp find_env_base_done

find_env_var_found:    
    mov bx,es
    mov ds,bx
    mov esi,edi
;
    pop edi
    pop es
;
    inc esi

find_env_copy_loop:
    lods byte ptr [esi]
    stos byte ptr es:[edi]
    or al,al
    jnz find_env_copy_loop
;
    clc

find_env_base_done:
	ret
find_env_base	Endp    

find_env_var    Proc near
    push ds
    push es
    pushad
;
    push ds
	mov ax,ENV_HANDLE
	DerefHandle
	mov al,[bx].env_handle_mode
	pop ds
	jc find_env_var_done
;
	cmp al,ENV_MODE_GLOBAL
	je find_sys_env
;
    LockProcEnv
	call find_env_base
    pushf
    UnlockProcEnv
    popf
	jmp find_env_var_done

find_sys_env:
    LockSysEnv
	call find_env_base
    pushf
    UnlockSysEnv
    popf

find_env_var_done:    
    popad
    pop es
    pop ds
    ret
find_env_var    Endp

find_env_var16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call find_env_var
;
    pop edi
    pop esi
    ret
find_env_var16  Endp

find_env_var32:
    call find_env_var
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetEnvSize
;
;		DESCRIPTION:	Get size raw env data 
;
;		PARAMETERS:		BX			Handle
;
;       RETURNS:        (E)AX       Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env_size_name	DB 'Get Env Size',0

get_env_size_base	Proc near	
	xor esi,esi
    xor ecx,ecx

get_env_var_size_loop:
	lods byte ptr [esi]
	inc ecx
	or al,al
	jnz get_env_var_size_loop
;
	mov al,[esi]
	or al,al
	jnz get_env_var_size_loop
;
    inc ecx
	ret
get_env_size_base	Endp

get_env_size:
    push ds
    push es
    push bx
    push ecx
    push esi
;
	mov ax,ENV_HANDLE
	DerefHandle
	jc get_env_size_done
;
	mov al,ds:[bx].env_handle_mode
	cmp al,ENV_MODE_GLOBAL
	je get_sys_env_size
;
    LockProcEnv
	mov ds,bx
	call get_env_size_base
    UnlockProcEnv
	clc
	jmp get_env_size_done

get_sys_env_size:
    LockSysEnv
	mov ds,bx
	call get_env_size_base
    UnlockSysEnv
	clc

get_env_size_done:
    mov eax,ecx
;    
    pop esi
    pop ecx
    pop bx
    pop es
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetEnvData
;
;		DESCRIPTION:	Get raw env data
;
;		PARAMETERS:		BX			Handle
;                       ES:(E)DI    Env data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_env_data_name	DB 'Get Env Data',0

get_env_data_base	Proc near	
	xor esi,esi

get_env_var_data_loop:
	lods byte ptr [esi]
	stos byte ptr es:[edi]
	or al,al
	jnz get_env_var_data_loop
;
	mov al,[esi]
	or al,al
	jnz get_env_var_data_loop
;
	stos byte ptr es:[edi]
	ret
get_env_data_base	Endp

get_env_data    Proc near
    push ds
    push es
    pushad
;
	mov ax,ENV_HANDLE
	DerefHandle
	jc get_env_data_done
;
	mov al,ds:[bx].env_handle_mode
	cmp al,ENV_MODE_GLOBAL
	je get_sys_env
;
    LockProcEnv
	mov ds,bx
	call get_env_data_base
    UnlockProcEnv
	clc
	jmp get_env_data_done

get_sys_env:
    LockSysEnv
	mov ds,bx
	call get_env_data_base
    UnlockSysEnv
	clc

get_env_data_done:
    popad
    pop es
    pop ds
    ret
get_env_data    Endp

get_env_data16  Proc far
    push edi
;
    movzx edi,di
    call get_env_data
;
    pop edi
    ret
get_env_data16  Endp

get_env_data32:
    call get_env_data
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    SetEnvData
;
;		DESCRIPTION:	Set raw env data
;
;		PARAMETERS:		BX			Handle
;                       ES:(E)DI    Env data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_env_data_name	DB 'Set Env Data',0

set_env_data_base	Proc near	
	xor edi,edi

set_env_var_data_loop:
	lods byte ptr [esi]
	stos byte ptr es:[edi]
	or al,al
	jnz set_env_var_data_loop
;
	mov al,[esi]
	or al,al
	jnz set_env_var_data_loop
;
	stos byte ptr es:[edi]
	ret
set_env_data_base	Endp

set_env_data    Proc near
    push ds
    push es
    pushad
;
	mov esi,edi
	push es
	mov ax,ENV_HANDLE
	DerefHandle
	mov al,ds:[bx].env_handle_mode
	pop ds
	jc set_env_data_done
;
	cmp al,ENV_MODE_GLOBAL
	je set_sys_env
;
    LockProcEnv
	mov es,bx
	call set_env_data_base
    UnlockProcEnv
	clc
	jmp set_env_data_done

set_sys_env:
    LockSysEnv
	mov es,bx
	call set_env_data_base
    UnlockSysEnv
	clc

set_env_data_done:
    popad
    pop es
    pop ds
    ret
set_env_data    Endp

set_env_data16  Proc far
    push edi
;
    movzx edi,di
    call set_env_data
;
    pop edi
    ret
set_env_data16  Endp

set_env_data32:
    call set_env_data
    retf32

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delete_handle
;
;		DESCRIPTION:	Delete handle (called from handle module)
;
;		PARAMETERS:		BX			ENV HANDLE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push es
	push bx
;
	mov ax,ENV_HANDLE
	DerefHandle
	jc delete_handle_done
;
	FreeHandle
	clc

delete_handle_done:
	pop bx
	pop es
	pop ds
	ret
delete_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitProcess
;
;		DESCRIPTION:	Init process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_process	Proc far
	push ds
	push es
	pushad
;
	LockSysEnv
	mov ds,bx
	xor si,si
;
	mov eax,4000h
	AllocateGlobalMem
	xor di,di

init_proc_var_loop:
	lodsb
	stosb
	or al,al
	jnz init_proc_var_loop
;
	mov al,[si]
	or al,al
	jnz init_proc_var_loop
;
	xor al,al
	stosb
;
	UnlockSysEnv
;
	mov ax,env_proc_sel
	mov ds,ax
	InitSection ds:env_proc_section
	mov ds:env_proc_raw_sel,es
;
	popad
	pop es
	pop ds
	ret
init_process	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


init	PROC far
	push ds
	pusha
;	
	mov bx,env_code_sel
	InitDevice
;
	mov eax,4000h
	AllocateGlobalMem
;
	xor di,di
	mov ax,system_data_sel
	mov ds,ax
	mov cx,ds:rom_modules
	mov bx,OFFSET rom_adapters
    
init_device_loop:
	mov edx,[bx].adapter_base
	call load_adapter_env
	add bx,SIZE adapter_typ
	loop init_device_loop	
;
	xor al,al
	stosb
;
    mov dx,es
	mov eax,SIZE env_sys_seg
	mov bx,env_sys_sel
	AllocateFixedSystemMem
;
    InitSection es:env_sys_section
    mov es:env_sys_raw_sel,dx
;
	mov eax,SIZE env_proc_seg
	mov bx,env_proc_sel
	AllocateFixedProcessMem
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
	mov di,OFFSET init_process
	HookCreateProcess
;
	mov di,OFFSET delete_handle
	mov ax,ENV_HANDLE
	RegisterHandle
;
	mov si,OFFSET lock_sys_env
	mov di,OFFSET lock_sys_env_name
	xor cl,cl
	mov ax,lock_sys_env_nr
	RegisterOsGate
;
	mov si,OFFSET unlock_sys_env
	mov di,OFFSET unlock_sys_env_name
	xor cl,cl
	mov ax,unlock_sys_env_nr
	RegisterOsGate
;
	mov si,OFFSET lock_proc_env
	mov di,OFFSET lock_proc_env_name
	xor cl,cl
	mov ax,lock_proc_env_nr
	RegisterOsGate
;
	mov si,OFFSET unlock_proc_env
	mov di,OFFSET unlock_proc_env_name
	xor cl,cl
	mov ax,unlock_proc_env_nr
	RegisterOsGate
;
	mov si,OFFSET open_sys_env
	mov di,OFFSET open_sys_env_name
	xor dx,dx
	mov ax,open_sys_env_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET open_proc_env
	mov di,OFFSET open_proc_env_name
	xor dx,dx
	mov ax,open_proc_env_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_env
	mov di,OFFSET close_env_name
	xor dx,dx
	mov ax,close_env_nr
	RegisterBimodalUserGate
;    
	mov bx,OFFSET add_env_var16
	mov si,OFFSET add_env_var32
	mov di,OFFSET add_env_var_name
	mov dx,virt_ds_in OR virt_es_in
	mov ax,add_env_var_nr
	RegisterUserGate
;    
	mov bx,OFFSET delete_env_var16
	mov si,OFFSET delete_env_var32
	mov di,OFFSET delete_env_var_name
	mov dx,virt_ds_in
	mov ax,delete_env_var_nr
	RegisterUserGate
;    
	mov bx,OFFSET find_env_var16
	mov si,OFFSET find_env_var32
	mov di,OFFSET find_env_var_name
	mov dx,virt_ds_in OR virt_es_in
	mov ax,find_env_var_nr
	RegisterUserGate
;
	mov si,OFFSET get_env_size
	mov di,OFFSET get_env_size_name
	xor dx,dx
	mov ax,get_env_size_nr
	RegisterBimodalUserGate
;    
	mov bx,OFFSET get_env_data16
	mov si,OFFSET get_env_data32
	mov di,OFFSET get_env_data_name
	mov dx,virt_es_in
	mov ax,get_env_data_nr
	RegisterUserGate
;    
	mov bx,OFFSET set_env_data16
	mov si,OFFSET set_env_data32
	mov di,OFFSET set_env_data_name
	mov dx,virt_es_in
	mov ax,set_env_data_nr
	RegisterUserGate
;	
	popa
	pop ds
	ret
init	ENDP

code	ENDS

	END init

