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

env_handle_seg	STRUC

env_handle_base	handle_header <>

env_handle_sel  DW ?
env_handle_pos  DW ?

env_handle_seg	ENDS


env_sys_seg  STRUC

env_section     section_typ <>

env_sel         DW ?

env_sys_seg  ENDS

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
;		NAME:		    LockEnv
;
;		DESCRIPTION:	Lock env and return raw data selector
;
;		RETURNS:		BX			Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_env_name	DB 'Lock Env',0

lock_env    Proc far
    push ds
;
    mov bx,env_sys_sel
    mov ds,bx
    EnterSection ds:env_section
    mov bx,ds:env_sel
;
    pop ds
    ret
lock_env    Endp
   
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    UnlockEnv
;
;		DESCRIPTION:	Unlock env
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_env_name	DB 'Unlock Env',0

unlock_env    Proc far
    push ds
    push bx
;
    mov bx,env_sys_sel
    mov ds,bx
    LeaveSection ds:env_section
;
    pop bx
    pop ds
    ret
unlock_env    Endp
   
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    OpenEnv
;
;		DESCRIPTION:	Open envvar handle
;
;		RETURNS:		BX			Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_env_name	DB 'Open Env',0

open_env    Proc far
    push ds
	push cx
;
	mov cx,SIZE env_handle_seg
	AllocateHandle
	mov [bx].env_handle_pos,0
	mov [bx].env_handle_sel,0
	mov [bx].hh_sign,ENV_HANDLE
	mov bx,[bx].hh_handle
;
	pop cx
	pop ds
    retf32
open_env    Endp

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
    mov ax,[bx].env_handle_sel
    or ax,ax
    jz close_env_sel_ok
;
    mov es,ax
    FreeMem

close_env_sel_ok:
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

add_env_var    Proc near
    push ds
    push es
    pushad
;
    push ds
	mov ax,ENV_HANDLE
	DerefHandle
	pop ds
	jc add_env_var_done
;
    push es
    push edi
;
    LockEnv
    mov es,bx
;
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
    jmp add_env_unlock

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

add_env_unlock:    
    pushf
    UnlockEnv
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

delete_env_var    Proc near
    ret
delete_env_var    Endp

delete_env_var16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call delete_env_var
;
    pop edi
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

find_env_var    Proc near
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
;		NAME:		    GetFirstEnvVar
;
;		DESCRIPTION:	Get to the first envvar
;
;		PARAMETERS:		BX			Handle
;                       DS:(E)SI    Env var name buffer
;                       ES:(E)DI    Env var data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_first_env_var_name	DB 'Get First Env Var',0

get_first_env_var    Proc near
    ret
get_first_env_var    Endp

get_first_env_var16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call get_first_env_var
;
    pop edi
    pop esi
    ret
get_first_env_var16  Endp

get_first_env_var32:
    call get_first_env_var
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetNextEnvVar
;
;		DESCRIPTION:	Get to the next envvar
;
;		PARAMETERS:		BX			Handle
;                       DS:(E)SI    Env var name buffer
;                       ES:(E)DI    Env var data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_next_env_var_name	DB 'Get Next Env Var',0

get_next_env_var    Proc near
    ret
get_next_env_var    Endp

get_next_env_var16  Proc far
    push esi
    push edi
;
    movzx esi,si
    movzx edi,di
    call get_next_env_var
;
    pop edi
    pop esi
    ret
get_next_env_var16  Endp

get_next_env_var32:
    call get_next_env_var
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
    mov ax,[bx].env_handle_sel
    or ax,ax
    jz delete_handle_sel_ok
;
    mov es,ax
    FreeMem

delete_handle_sel_ok:
	FreeHandle
	clc

delete_handle_done:
	pop bx
	pop es
	pop ds
	ret
delete_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_ENV
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_env

init_env	PROC near
	push ds
	pusha
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
    InitSection es:env_section
    mov es:env_sel,dx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
	mov di,OFFSET delete_handle
	mov ax,ENV_HANDLE
	RegisterHandle
;
	mov si,OFFSET lock_env
	mov di,OFFSET lock_env_name
	xor cl,cl
	mov ax,lock_env_nr
	RegisterOsGate
;
	mov si,OFFSET unlock_env
	mov di,OFFSET unlock_env_name
	xor cl,cl
	mov ax,unlock_env_nr
	RegisterOsGate
;
	mov si,OFFSET open_env
	mov di,OFFSET open_env_name
	xor dx,dx
	mov ax,open_env_nr
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
	mov bx,OFFSET get_first_env_var16
	mov si,OFFSET get_first_env_var32
	mov di,OFFSET get_first_env_var_name
	mov dx,virt_ds_in OR virt_es_in
	mov ax,get_first_env_var_nr
	RegisterUserGate
;    
	mov bx,OFFSET get_next_env_var16
	mov si,OFFSET get_next_env_var32
	mov di,OFFSET get_next_env_var_name
	mov dx,virt_ds_in OR virt_es_in
	mov ax,get_next_env_var_nr
	RegisterUserGate
;	
	popa
	pop ds
	ret
init_env	ENDP

code	ENDS

	END

