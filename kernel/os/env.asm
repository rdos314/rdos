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

INCLUDE system.def
INCLUDE protseg.def
INCLUDE driver.def
INCLUDE user.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE os.inc
INCLUDE system.inc


	.386p


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
	mov ax,es
	mov ds,ax
	movzx eax,di
	mov bx,env_sel
	AllocateFixedSystemMem
	mov cx,ax
	xor si,si
	xor di,di
	rep movsb
	mov ax,ds
	mov es,ax
	xor ax,ax
	mov ds,ax
	FreeMem
;	
	popa
	pop ds
	ret
init_env	ENDP

code	ENDS

	END

