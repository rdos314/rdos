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
; WAIT.ASM
; Abortable single & multiple wait functionality
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME timer

GateSize = 16

INCLUDE protseg.def
INCLUDE system.def
INCLUDE driver.def
INCLUDE user.def
INCLUDE os.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE os.inc
INCLUDE handle.inc
INCLUDE wait.inc

wait_until_obj  STRUC

wu_header       wait_obj_header <>
wu_lsb          DD ?
wu_msb          DD ?

wait_until_obj  ENDS

wait_handle_seg STRUC

wh_handle_base	handle_header <>
wh_section      section_typ <>
wh_obj_list     DW ?
wh_thread       DW ?
wh_running      DB ?

wait_handle_seg ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_wait
;
;		DESCRIPTION:	Delete contents in wait handle
;
;       PARAMETERS:     DS:BX       Wait struct
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_wait Proc near
    mov dx,ds:[bx].wh_obj_list
    or dx,dx
    jz delete_wait_done

delete_wait_loop:
    mov es,dx
    mov dx,es:wo_next
    FreeMem
    or dx,dx
    jnz delete_wait_loop

delete_wait_done:
    ret
delete_wait Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateWait
;
;		DESCRIPTION:	Create a wait handle
;
;       RETURNS:        BX      Wait handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_wait_name    DB 'Create Wait', 0

create_wait Proc far
	push ds
	push cx
;
	mov cx,SIZE wait_handle_seg
	AllocateHandle
	mov [bx].hh_sign,WAIT_HANDLE
	mov [bx].wh_obj_list,0
	mov [bx].wh_running,0
	InitSection ds:[bx].wh_section 
	mov bx,[bx].hh_handle
	clc
;
    pop cx
	pop ds
	retf32
create_wait ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseWait
;
;		DESCRIPTION:	Close a wait handle
;
;       PARAMETERS:     BX      Wait handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_wait_name    DB 'Close Wait', 0

close_wait Proc far
	push ds
	push ax
;
	mov ax,WAIT_HANDLE
	DerefHandle
	jc close_wait_done
;
    call delete_wait
;
	FreeHandle
	clc

close_wait_done:
    pop ax
	pop ds
	retf32
close_wait ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_handle
;
;		DESCRIPTION:	BX			Wait handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push ax
	push bx
;
	mov ax,WAIT_HANDLE
	DerefHandle
	jc delete_handle_done
;
	call delete_wait

delete_handle_done:
	pop bx
	pop ax
	pop ds
	ret
delete_handle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			timeout_wait_until
;
;		DESCRIPTION:	Timeout on wait until
;
;       PARAMETERS:     CX       object
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timeout_wait_until Proc far
    push es
    mov es,cx
    inc es:wo_signalled
	mov bx,es:wo_thread
    Signal
    pop es
    ret
timeout_wait_until  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_wait_until
;
;		DESCRIPTION:	Init wait until
;
;       PARAMETERS:     ES       object
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_wait_until Proc far
    push es
    push eax
    push bx
    push cx
    push edx
    push di
;
    mov eax,es:wu_lsb
    mov edx,es:wu_msb
    mov bx,es
    mov cx,es
    mov ax,cs
    mov es,ax
    mov di,OFFSET timeout_wait_until
    StartTimer
;
    pop di
    pop edx
    pop cx
    pop bx
    pop eax
    pop es
    ret
init_wait_until Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			abort_wait_until
;
;		DESCRIPTION:	Abort wait until
;
;       PARAMETERS:     ES       object
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

abort_wait_until Proc far
    push bx
    mov bx,es
    StopTimer
    pop bx
    ret
abort_wait_until Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddWaitUntil
;
;		DESCRIPTION:	Add wait until to wait
;
;       PARAMETERS:     BX      Wait handle
;                       ECX     ID
;                       EDX:EAX Time to wait until
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_until_name    DB 'Add Wait Until', 0

add_wait_until Proc far
	push ds
	push es
	push eax
	push ebx
;
    push ax
	mov ax,WAIT_HANDLE
	DerefHandle
	pop ax
	jc add_wait_until_done
;
    movzx ebx,bx
    EnterSection ds:[ebx].wh_section
;    
    push eax
    mov eax,SIZE wait_until_obj
    AllocateSmallGlobalMem
    pop eax
;
    mov word ptr es:wo_init_proc, OFFSET init_wait_until
    mov word ptr es:wo_init_proc+2,cs
    mov word ptr es:wo_abort_proc, OFFSET abort_wait_until
    mov word ptr es:wo_abort_proc+2,cs
    mov es:wo_id,ecx
    mov es:wu_lsb,eax
    mov es:wu_msb,edx
;
    mov ax,ds:[bx].wh_obj_list
    mov es:wo_next,ax
    mov ds:[bx].wh_obj_list,es
;
    LeaveSection ds:[ebx].wh_section
	clc

add_wait_until_done:
    pop ebx
    pop eax
    pop es
	pop ds
	retf32
add_wait_until ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartWait
;
;		DESCRIPTION:    Start a wait
;
;       PARAMETERS:     BX      Wait handle
;
;       RETURNS:        ECX     Signalled ID
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_name    DB 'Start Wait', 0

start_wait Proc far
	push ds
	push es
	push eax
	push ebx
	push dx
;
    xor ecx,ecx
	mov ax,WAIT_HANDLE
	DerefHandle
	jc start_wait_done
;
    movzx ebx,bx
    EnterSection ds:[ebx].wh_section
    mov al,ds:[bx].wh_running
    or al,al
    jnz start_wait_stopped_leave
;
    GetThread
    mov ds:[bx].wh_thread,ax
    ClearSignal
    mov dx,ds:[bx].wh_obj_list
    or dx,dx
    jz start_wait_start_leave

start_wait_start_loop:
    mov es,dx
    mov es:wo_thread,ax
    mov es:wo_signalled,0
    call es:wo_init_proc
    mov dx,es:wo_next
    or dx,dx
    jnz start_wait_start_loop

start_wait_start_leave:
    inc ds:[bx].wh_running
    LeaveSection ds:[ebx].wh_section

start_wait_do:
    WaitForSignal
;
    EnterSection ds:[ebx].wh_section
    mov al,ds:[bx].wh_running
    or al,al
    jz start_wait_stopped_leave
;
    dec ds:[bx].wh_running
    mov ax,ds:[bx].wh_obj_list
    or ax,ax
    jz start_wait_stopped_leave

start_wait_stop_loop:
    mov es,ax
    mov ax,es:wo_signalled
    or ax,ax
    jz start_wait_stop_next
;
    mov ecx,es:wo_id
    call es:wo_abort_proc

start_wait_stop_next:
    mov ax,es:wo_next
    or ax,ax
    jnz start_wait_stop_loop

start_wait_stopped_leave:
    LeaveSection ds:[ebx].wh_section
    clc

start_wait_done:
    pop dx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
start_wait  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopWait
;
;		DESCRIPTION:    Stop a wait
;
;       PARAMETERS:     BX      Wait handle
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_name    DB 'Stop Wait', 0

stop_wait Proc far
	push ds
	push es
	push eax
	push ebx
;
	mov ax,WAIT_HANDLE
	DerefHandle
	jc stop_wait_done
;
    movzx ebx,bx
    EnterSection ds:[ebx].wh_section
    mov al,ds:[bx].wh_running
    or al,al
    jz stop_wait_leave
;
    dec ds:[bx].wh_running
    mov ax,ds:[bx].wh_obj_list
    or ax,ax
    jz stop_wait_signal

stop_wait_loop:
    mov es,ax
    mov ax,es:wo_signalled
    or ax,ax
    jz stop_wait_next
;
    call es:wo_abort_proc

stop_wait_next:
    mov ax,es:wo_next
    or ax,ax
    jnz stop_wait_loop

stop_wait_signal:
    push bx
    mov bx,ds:[bx].wh_thread
    Signal
    pop bx

stop_wait_leave:
    LeaveSection ds:[ebx].wh_section
    clc

stop_wait_done:
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
stop_wait  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddWait
;
;		DESCRIPTION:    Add a generic wait object
;
;       PARAMETERS:     AX      Extra bytes needed in wait object
;                       BX      Wait handle
;                       ECX     Signalled ID
;                       DS:SI   Init procedure (wait object in ES)
;                       ES:DI   Abort procedure (wait object in ES)
;
;       RETURNS:        ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_name   DB 'Add Wait', 0

add_wait    Proc far
	push ds
	push fs
	push eax
	push ebx
	push dx
;
    mov dx,ds
    mov fs,dx
;
    push ax
	mov ax,WAIT_HANDLE
	DerefHandle
	pop ax
	jc add_wait_done
;
    movzx ebx,bx
    EnterSection ds:[ebx].wh_section
;    
    mov dx,es
    movzx eax,ax
    add eax,SIZE wait_until_obj
    AllocateSmallGlobalMem
;
    mov word ptr es:wo_init_proc,si
    mov word ptr es:wo_init_proc+2,fs
    mov word ptr es:wo_abort_proc,di
    mov word ptr es:wo_abort_proc+2,dx
    mov es:wo_id,ecx
;
    mov ax,ds:[bx].wh_obj_list
    mov es:wo_next,ax
    mov ds:[bx].wh_obj_list,es
;
    LeaveSection ds:[ebx].wh_section
	clc

add_wait_done:
    pop dx
    pop ebx
    pop eax
    pop fs
	pop ds
    ret
add_wait    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SignalWait
;
;		DESCRIPTION:	Signal object
;
;       PARAMETERS:     ES      object
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_wait_name    DB 'Signal Wait',0

signal_wait Proc far
    push bx
    inc es:wo_signalled
	mov bx,es:wo_thread
    Signal
    pop bx
    ret
signal_wait Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	Init device-driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
	mov bx,wait_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov ax,WAIT_HANDLE
	mov di,OFFSET delete_handle
	RegisterHandle
;
	mov si,OFFSET add_wait
	mov di,OFFSET add_wait_name
	mov ax,add_wait_nr
	RegisterOsGate
;
	mov si,OFFSET signal_wait
	mov di,OFFSET signal_wait_name
	mov ax,signal_wait_nr
	RegisterOsGate
;
	mov si,OFFSET create_wait
	mov di,OFFSET create_wait_name
	xor dx,dx
	mov ax,create_wait_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_wait
	mov di,OFFSET close_wait_name
	xor dx,dx
	mov ax,close_wait_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET add_wait_until
	mov di,OFFSET add_wait_until_name
	xor dx,dx
	mov ax,add_wait_until_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET start_wait
	mov di,OFFSET start_wait_name
	xor dx,dx
	mov ax,start_wait_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET stop_wait
	mov di,OFFSET stop_wait_name
	xor dx,dx
	mov ax,stop_wait_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init
