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
; FOCUS.ASM
; Virtual console handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME focus

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE user.def
INCLUDE os.def
INCLUDE driver.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE os.inc

focus_seg	STRUC

focus_thread			DW 256 DUP(?)

focus_current_thread	DW ?
focus_section			section_typ <>
focus_switched			DB ?

focus_alloc_rel			DD ?

enable_focus_hooks		DB ?
lost_focus_hooks		DB ?
got_focus_hooks			DB ?

enable_focus_arr		DD 16 DUP(?)
lost_focus_arr			DD 16 DUP(?)
got_focus_arr			DD 16 DUP(?)

focus_seg	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT
;
;		DESCRIPTION:	Init driver
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	pusha
	push ds
	mov bx,focus_code_sel
	InitDevice
;
	mov bx,video_mem_focus_sel
	mov edx,video_mem_focus_linear
	mov ecx,100000h
	CreateDataSelector16
;
	mov bx,video_mem_local_sel
	mov edx,video_mem_local_linear
	mov ecx,100000h
	CreateDataSelector16
;
	mov bx,video_focus_sel
	mov edx,video_focus_linear
	mov ecx,20000h
	CreateDataSelector16
;
	mov bx,video_local_sel
	mov edx,video_local_linear
	mov ecx,20000h
	CreateDataSelector16
;
	mov bx,focus_sel
	mov eax,SIZE focus_seg
	AllocateFixedSystemMem
	mov es,bx
	mov di,OFFSET focus_thread
	mov cx,256
	xor ax,ax
	rep stosw
	mov es:lost_focus_hooks,0
	mov es:got_focus_hooks,0
	mov es:enable_focus_hooks,0
	mov es:focus_switched,0
	mov es:focus_alloc_rel,0
	mov es:focus_current_thread,0
	InitSection es:focus_section
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_focus_process
	HookCreateProcess
;
	mov di,OFFSET free_focus_process
	HookTerminateProcess
;
	mov di,OFFSET free_thread
	HookTerminateThread
;
	mov si,OFFSET set_focus
	mov di,OFFSET set_focus_name
	xor dx,dx
	mov ax,set_focus_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET enable_focus
	mov di,OFFSET enable_focus_name
	xor dx,dx
	mov ax,enable_focus_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET hook_enable_focus
	mov di,OFFSET hook_enable_focus_name
	xor cl,cl
	mov ax,hook_enable_focus_nr
	RegisterOsGate
;
	mov si,OFFSET hook_lost_focus
	mov di,OFFSET hook_lost_focus_name
	xor cl,cl
	mov ax,hook_lost_focus_nr
	RegisterOsGate
;
	mov si,OFFSET hook_got_focus
	mov di,OFFSET hook_got_focus_name
	xor cl,cl
	mov ax,hook_got_focus_nr
	RegisterOsGate
;
	mov si,OFFSET get_focus_thread
	mov di,OFFSET get_focus_thread_name
	xor cl,cl
	mov ax,get_focus_thread_nr
	RegisterOsGate
;
	mov si,OFFSET get_thread_focus_key
	mov di,OFFSET get_thread_focus_key_name
	xor cl,cl
	mov ax,get_thread_focus_key_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_focus_linear
	mov di,OFFSET allocate_focus_linear_name
	xor cl,cl
	mov ax,allocate_focus_linear_nr
	RegisterOsGate
;
	mov si,OFFSET allocate_fixed_focus_mem
	mov di,OFFSET allocate_fixed_focus_mem_name
	xor cl,cl
	mov ax,allocate_fixed_focus_mem_nr
	RegisterOsGate
;
	pop ds
	popa
	ret
init	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetFocusThread
;
;		DESCRIPTION:	Get focus thread
;
;		RETURNS:		AX		Focus thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_focus_thread_name	DB 'Get Focus Thread',0

get_focus_thread	PROC far
	push ds
	mov ax,focus_sel
	mov ds,ax
	mov ax,ds:focus_current_thread
	pop ds
	ret
get_focus_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetThreadFocusKey
;
;		DESCRIPTION:	Get thread switch key
;
;		PARAMETERS:		BX		Thread
;
;		RETURNS:		AL		Switch key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_focus_key_name	DB 'Get Thread Focus Key',0

get_thread_focus_key	PROC far
	push ds
	push cx
	push si
;
	mov ax,focus_sel
	mov ds,ax
	mov cx,256
	mov si,OFFSET focus_thread

get_thread_key_loop:
	cmp bx,[si]
	je get_thread_key_ok
;
	add si,2
	loop get_thread_key_loop
;
	xor ax,ax
	stc
	jmp get_thread_key_done

get_thread_key_ok:
	mov ax,si
	sub ax,OFFSET focus_thread
	shr ax,1
	clc

get_thread_key_done:
	pop si
	pop cx
	pop ds
	ret
get_thread_focus_key	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_FOCUS_LINEAR
;
;		DESCRIPTION:	Allocate focus memory
;
;		PARAMETERS:		EAX		Bytes
;
;		RETURNS:		EDX		Focus fixed address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_focus_linear_name	DB 'Allocate Focus Linear',0

allocate_focus_linear	PROC far
	push ds
	mov dx,focus_sel
	mov ds,dx
	mov edx,ds:focus_alloc_rel
	add ds:focus_alloc_rel,eax
	pop ds
	ret
allocate_focus_linear	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ALLOCATE_FIXED_FOCUS_MEM
;
;		DESCRIPTION:	Allocate focus selector
;
;		PARAMETERS:		EAX		Bytes
;
;		RETURNS:		BX		Local selector
;						DX		Focus selector
;						ES		Local selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_fixed_focus_mem_name	DB 'Allocate Fixed Focus Mem',0

allocate_fixed_focus_mem	PROC far
	push ds
	push eax
	push ecx
	push edx
;
	push bx
	push dx
	AllocateFocusLinear
	mov ecx,eax
	push edx
	add edx,io_local_linear
	CreateDataSelector16
	pop edx
;
	add edx,io_focus_linear
	pop bx
	CreateDataSelector16
	pop bx
	mov es,bx
;
	pop edx
	pop ecx
	pop eax
	pop ds
	ret
allocate_fixed_focus_mem	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Free_thread
;
;		DESCRIPTION:	Handle thread termination
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_thread	Proc far
	mov bx,focus_sel
	mov ds,bx
	mov bx,OFFSET focus_thread
	mov cx,100h
	GetThread

free_thread_loop:
	cmp ax,[bx]
	jne free_thread_next
;
	mov word ptr [bx],0
	cmp ax,ds:focus_current_thread
	jne free_thread_done
;
	mov ds:focus_switched,0
	mov ds:focus_current_thread,0
	jmp free_thread_done

free_thread_next:
	add bx,2
	loop free_thread_loop

free_thread_done:
	ret
free_thread	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_FOCUS_PROCESS
;
;		DESCRIPTION:	Init per-process data
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_focus_process	Proc far
	push ds
	push eax
	push ebx
	push cx
;
	mov ax,process_page_sel
	mov ds,ax
	mov ebx,io_local_linear SHR 10
	mov cx,400h
	xor eax,eax
init_local_loop:
	mov [ebx],eax
	add ebx,4
	loop init_local_loop	
;
	pop cx
	pop ebx
	pop eax
	pop ds
	ret
init_focus_process	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FREE_FOCUS_PROCESS
;
;		DESCRIPTION:	Free per-process data
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_focus_process	Proc far
	push ds
	push eax
	push ebx
	push cx
;
	mov ax,process_page_sel
	mov ds,ax
	mov ebx,io_local_linear SHR 10
	mov cx,400h
free_local_loop:
	mov eax,[ebx]
	or eax,eax
	jz free_local_next
;
	FreePhysical

free_local_next:
	add ebx,4
	loop free_local_loop	
;
	pop cx
	pop ebx
	pop eax
	pop ds
	ret
free_focus_process	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRAP_ENABLE_FOCUS
;
;		DESCRIPTION:	Run hooks for EnableFocus
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_enable_focus	PROC near
	mov ax,focus_sel
	mov ds,ax
	mov cl,ds:enable_focus_hooks
	or cl,cl
	je trap_enable_focus_done
	mov bx,OFFSET enable_focus_arr
trap_enable_focus_loop:
	push ds
	push bx
	push cx
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz trap_enable_focus_loop
trap_enable_focus_done:
	ret
trap_enable_focus	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRAP_LOST_FOCUS
;
;		DESCRIPTION:	Run hooks for LostFocus (before the switch)
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_lost_focus	PROC near
	mov cl,ds:lost_focus_hooks
	or cl,cl
	je trap_lost_focus_done
	mov bx,OFFSET lost_focus_arr
trap_lost_focus_loop:
	push ds
	push bx
	push cx
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz trap_lost_focus_loop
trap_lost_focus_done:
	ret
trap_lost_focus	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TRAP_GOT_FOCUS
;
;		DESCRIPTION:	Run hooks for GotFocus (after the switch)
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_got_focus	PROC near
	mov cl,ds:got_focus_hooks
	or cl,cl
	je trap_got_focus_done
	mov bx,OFFSET got_focus_arr
trap_got_focus_loop:
	push ds
	push bx
	push cx
	call dword ptr [bx]
	pop cx
	pop bx
	pop ds
	add bx,4
	dec cl
	jnz trap_got_focus_loop
trap_got_focus_done:
	ret
trap_got_focus	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_ENABLE_FOCUS
;
;		DESCRIPTION:	Add hook for EnableFocus
;
;		PARAMETERS:		ES:DI		CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_enable_focus_name	DB 'Hook Enable Focus',0

hook_enable_focus	PROC far
	push ds
	push ax
	push bx
	mov ax,focus_sel
	mov ds,ax
	mov al,ds:enable_focus_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET enable_focus_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:enable_focus_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_enable_focus	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_LOST_FOCUS
;
;		DESCRIPTION:	Add hook for LostFocus
;
;		PARAMETERS:		ES:DI		CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_lost_focus_name	DB 'Hook Lost Focus',0

hook_lost_focus	PROC far
	push ds
	push ax
	push bx
	mov ax,focus_sel
	mov ds,ax
	mov al,ds:lost_focus_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET lost_focus_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:lost_focus_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_lost_focus	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			HOOK_GOT_FOCUS
;
;		DESCRIPTION:	Add hook for GotFocus
;
;		PARAMETERS:		ES:DI		CALLBACK ADDRESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_got_focus_name	DB 'Hook Got Focus',0

hook_got_focus	PROC far
	push ds
	push ax
	push bx
	mov ax,focus_sel
	mov ds,ax
	mov al,ds:got_focus_hooks
	mov bl,al
	xor bh,bh
	shl bx,2
	add bx,OFFSET got_focus_arr
	mov [bx],di
	mov [bx+2],es
	inc al
	mov ds:got_focus_hooks,al
	pop bx
	pop ax
	pop ds
	ret
hook_got_focus	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SET_FOCUS
;
;		DESCRIPTION:	Set input focus
;
;		PARAMETERS:		AL	KEY NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_focus_name	DB 'Set Focus',0

set_focus	PROC far
	push ds
	push es
	pushad
	mov bx,focus_sel
	mov ds,bx
	EnterSection ds:focus_section
	xor bh,bh
	mov bl,al
	add bx,bx
	mov ax,ds:[bx].focus_thread
	or ax,ax
	jz set_focus_done
	mov bx,ax
	cmp ds:focus_switched,0
	jz set_focus_no_lost
	push bx
	call trap_lost_focus
	pop bx
set_focus_no_lost:
	mov ds:focus_switched,1
	mov ds:focus_current_thread,bx
	mov ds,bx
	mov eax,cr3
	push eax
	mov eax,ds:p_cr3
	mov bx,process_dir_sel
	mov ds,bx
	mov bx,io_local_linear SHR 20
	cli
	mov cr3,eax
	mov edx,[bx]
	pop eax
	mov cr3,eax
	sti
	mov bx,io_focus_linear SHR 20
	mov [bx],edx
	mov ax,sys_dir_sel
	mov ds,ax
	mov [bx],edx
;
	mov bx,focus_sel
	mov ds,bx
	call trap_got_focus
set_focus_done:
	LeaveSection ds:focus_section
	popad
	pop es
	pop ds
	retf32
set_focus	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ENABLE_FOCUS
;
;		DESCRIPTION:	Enable focus
;
;		PARAMETERS:		AL	KEY NUMBER
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_focus_name	DB 'Enable Focus',0

enable_focus	PROC far
	push ds
	push es
	push bx
;
	mov bx,focus_sel
	mov ds,bx
	xor bh,bh
	mov bl,al
	GetThread
	add bx,bx

enable_focus_loop:
	cmp ds:[bx].focus_thread,0
	jne enable_focus_next
;
	mov ds:[bx].focus_thread,ax
	jmp enable_focus_done

enable_focus_next:
	add bx,2
	cmp bx,200h
	jne enable_focus_loop

enable_focus_done:
	pushad
	call trap_enable_focus
	popad
;
	mov ax,bx
	shr ax,1
;
	pop bx
	pop es
	pop ds
	retf32
enable_focus	ENDP

code	ENDS

.186

END init

