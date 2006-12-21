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
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc

wait_handle_seg STRUC

wh_handle_base	handle_header <>
wh_section      section_typ <>
wh_obj_list     DW ?
wh_thread       DW ?
wh_running      DB ?

wait_handle_seg ENDS

signal_wait_header	STRUC

sig_obj			wait_obj_header <>
sig_handle		DW ?

signal_wait_header	ENDS

signal_handle_seg		STRUC

sig_handle_base	handle_header <>

sig_wait_obj            DW ?
sig_state               DB ?

signal_handle_seg		ENDS


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
	mov [bx].wh_thread,0
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
;		NAME:			IsWaitIdle
;
;		DESCRIPTION:    Check if wait is idle
;
;       PARAMETERS:     BX      Wait handle
;
;       RETURNS:        NC
;							ECX     Non-idle ID
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_wait_idle_name    DB 'Is Wait Idle', 0

is_wait_idle Proc far
	push ds
	push es
	push eax
	push ebx
	push dx
;
    xor ecx,ecx
	mov ax,WAIT_HANDLE
	DerefHandle
	jc is_wait_idle_done
;
    movzx ebx,bx
    EnterSection ds:[ebx].wh_section
    mov dx,ds:[bx].wh_obj_list
    or dx,dx
    jz is_wait_idle_ok_leave

is_wait_idle_loop:
    mov es,dx
    call es:wo_idle_proc
	jc is_wait_idle_fail_leave
;
    mov dx,es:wo_next
    or dx,dx
    jnz is_wait_idle_loop

is_wait_idle_ok_leave:
    LeaveSection ds:[ebx].wh_section
	clc
	jmp is_wait_idle_done

is_wait_idle_fail_leave:
	mov ecx,es:wo_id
    LeaveSection ds:[ebx].wh_section
	stc

is_wait_idle_done:
    pop dx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
is_wait_idle  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WaitWithoutTimeout
;
;		DESCRIPTION:    Wait without timeout
;
;       PARAMETERS:     BX      Wait handle
;
;       RETURNS:        ECX     Signalled ID
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_no_timeout_name    DB 'Wait Without Timeout', 0

wait_no_timeout Proc far
	push ds
	push es
	push eax
	push ebx
	push dx
;
    xor ecx,ecx
	mov ax,WAIT_HANDLE
	DerefHandle
	jc wait_no_timeout_done
;
    movzx ebx,bx
    EnterSection ds:[ebx].wh_section
    mov al,ds:[bx].wh_running
    or al,al
    jnz wait_no_timeout_stopped_leave
;
    GetThread
    mov ds:[bx].wh_thread,ax
    ClearSignal
    mov dx,ds:[bx].wh_obj_list
    or dx,dx
    jz wait_no_timeout_start_leave

wait_no_timeout_start_loop:
    mov es,dx
    mov es:wo_thread,ax
    mov es:wo_signalled,0
    call es:wo_init_proc
    mov dx,es:wo_next
    or dx,dx
    jnz wait_no_timeout_start_loop

wait_no_timeout_start_leave:
    inc ds:[bx].wh_running
    LeaveSection ds:[ebx].wh_section

wait_no_timeout_do:
    WaitForSignal
;
    EnterSection ds:[ebx].wh_section
    mov al,ds:[bx].wh_running
    or al,al
    jz wait_no_timeout_stopped_leave
;
    dec ds:[bx].wh_running
    mov ax,ds:[bx].wh_obj_list
    or ax,ax
    jz wait_no_timeout_stopped_leave

wait_no_timeout_stop_loop:
    mov es,ax
    mov ax,es:wo_signalled
    or ax,ax
    jnz wait_no_timeout_stop_signalled
;
    call es:wo_abort_proc
	jmp wait_no_timeout_stop_next

wait_no_timeout_stop_signalled:
	or ecx,ecx
	jnz wait_no_timeout_stop_next
;
    mov ecx,es:wo_id
    call es:wo_clear_proc

wait_no_timeout_stop_next:
    mov ax,es:wo_next
    or ax,ax
    jnz wait_no_timeout_stop_loop

wait_no_timeout_stopped_leave:
    LeaveSection ds:[ebx].wh_section
    clc

wait_no_timeout_done:
    pop dx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
wait_no_timeout  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			timeout_wait
;
;		DESCRIPTION:	Timeout on wait 
;
;       PARAMETERS:     CX       thread to signal
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

timeout_wait Proc far
	mov bx,cx
    Signal
    ret
timeout_wait  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WaitWithTimeout
;
;		DESCRIPTION:    Wait with timeout
;
;       PARAMETERS:     BX      Wait handle
;						EDX:EAX	Timeout time
;
;       RETURNS:        ECX     Signalled ID
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_timeout_name    DB 'Wait With Timeout', 0

wait_timeout Proc far
	push ds
	push es
	push eax
	push ebx
	push dx
	push di
;
	push ax
    xor ecx,ecx
	mov ax,WAIT_HANDLE
	DerefHandle
	pop ax
	jc wait_timeout_done
;
    movzx ebx,bx
    EnterSection ds:[ebx].wh_section
	push ax
    mov al,ds:[bx].wh_running
    or al,al
	pop ax
    jnz wait_timeout_stopped_leave
;
	push eax
	push edx
    GetThread
    mov ds:[bx].wh_thread,ax
    ClearSignal
    mov dx,ds:[bx].wh_obj_list
    or dx,dx
    jz wait_timeout_start_timer

wait_timeout_start_loop:
    mov es,dx
    mov es:wo_thread,ax
    mov es:wo_signalled,0
    call es:wo_init_proc
    mov dx,es:wo_next
    or dx,dx
    jnz wait_timeout_start_loop

wait_timeout_start_timer:
	GetThread
	mov cx,ax
    mov ax,cs
    mov es,ax
	pop edx
	pop eax
;
	push bx
	mov bx,cx
    mov di,OFFSET timeout_wait
    StartTimer
	pop bx
;
    inc ds:[bx].wh_running
    LeaveSection ds:[ebx].wh_section

wait_timeout_do:
    WaitForSignal
;
	push bx
	mov bx,cx
	StopTimer
	pop bx
;
    xor ecx,ecx
    EnterSection ds:[ebx].wh_section
    mov al,ds:[bx].wh_running
    or al,al
    jz wait_timeout_stopped_leave
;
    dec ds:[bx].wh_running
    mov ax,ds:[bx].wh_obj_list
    or ax,ax
    jz wait_timeout_stopped_leave

wait_timeout_stop_loop:
    mov es,ax
    mov ax,es:wo_signalled
    or ax,ax
    jnz wait_timeout_stop_signalled
;
    call es:wo_abort_proc
	jmp wait_timeout_stop_next

wait_timeout_stop_signalled:
	or ecx,ecx
	jnz wait_timeout_stop_next
;
    mov ecx,es:wo_id
    call es:wo_clear_proc

wait_timeout_stop_next:
    mov ax,es:wo_next
    or ax,ax
    jnz wait_timeout_stop_loop

wait_timeout_stopped_leave:
    LeaveSection ds:[ebx].wh_section
    clc

wait_timeout_done:
	pop di
    pop dx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
wait_timeout  Endp

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
    jnz stop_wait_next
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
;                       ES:DI   Method table
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
	push cx
	push si
	push di
;
	mov si,es
	mov fs,si
	mov si,di
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
    movzx eax,ax
    add eax,SIZE wait_obj_header
    AllocateSmallGlobalMem
;
    mov es:wo_id,ecx
	mov di,OFFSET wo_init_proc
	mov cx,4
	rep movs dword ptr es:[di],fs:[si]
;
    mov ax,ds:[bx].wh_obj_list
    mov es:wo_next,ax
    mov ds:[bx].wh_obj_list,es
;
    mov al,ds:[bx].wh_running
    or al,al
    jz awLeave
;
    mov ax,ds:[bx].wh_thread
    or ax,ax
    jz awLeave
;
    push bx
    mov bx,ax
    Signal
    pop bx

awLeave:
    LeaveSection ds:[ebx].wh_section
	clc

add_wait_done:
	pop di
	pop si
    pop cx
    pop ebx
    pop eax
	pop fs
	pop ds
    ret
add_wait    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RemoveWait
;
;		DESCRIPTION:    Remove a wait object
;
;       PARAMETERS:     BX      Wait handle
;                       ECX     Signal ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

remove_wait_name   DB 'Remove Wait', 0

remove_wait    Proc far
	push ds
	push es
	push ax
	push ebx
	push dx
;
	mov ax,WAIT_HANDLE
	DerefHandle
	jc remove_wait_done
;
    movzx ebx,bx
    EnterSection ds:[ebx].wh_section
;
    xor dx,dx
    mov ax,ds:[bx].wh_obj_list
    
remove_wait_loop:
    or ax,ax
    jz remove_wait_leave
;
    mov es,ax
    cmp ecx,es:wo_id
    je remove_wait_do
;
    mov dx,es
    mov ax,es:wo_next
    jmp remove_wait_loop

remove_wait_do:
    mov ax,es:wo_next
    FreeMem
    or dx,dx
    jz remove_wait_head
;
    mov es,dx
    mov es:wo_next,ax
    jmp remove_wait_loop

remove_wait_head:
    mov ds:[bx].wh_obj_list,ax
    jmp remove_wait_loop

remove_wait_leave:
    LeaveSection ds:[ebx].wh_section
	clc

remove_wait_done:
    pop dx
    pop ebx
    pop ax
    pop es
	pop ds
    retf32
remove_wait    Endp

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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delete_signal_handle
;
;		DESCRIPTION:	Delete signal handle (called from handle module)
;
;		PARAMETERS:		BX		Signal handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_signal_handle	Proc far
	push ds
	push es
	push ax
	push dx
;
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc delete_signal_handle_done
;
    FreeHandle

delete_signal_handle_done:
	pop dx
	pop ax
	pop es
	pop ds
	ret
delete_signal_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateSignal
;
;		DESCRIPTION:	Create a new signal handle
;
;		RETURNS:		BX		Signal handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_signal_name DB 'Create Signal',0

create_signal   Proc far
    push ds
    push ax
    push cx
;    
    mov ax,SIGNAL_HANDLE
	mov cx,SIZE signal_handle_seg
	AllocateHandle
	mov [bx].sig_wait_obj,0
	mov [bx].sig_state,0
	mov [bx].hh_sign,SIGNAL_HANDLE
	mov bx,[bx].hh_handle
;
    pop cx
    pop ax
    pop ds
    retf32
create_signal   Endp	

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ResetSignal
;
;		DESCRIPTION:	Reset signal (to inactive)
;
;		PARAMETERS:		BX		Signal handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_signal_name DB 'Reset Signal',0

reset_signal   Proc far
    push ds
    push ax
    push bx
;    
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc reset_sig_done
;
    mov ds:[bx].sig_state,0

reset_sig_done:
    sti
    pop bx
    pop ax
    pop ds
    retf32
reset_signal Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IsSignalled
;
;		DESCRIPTION:    Is signal active (CLC)
;
;		PARAMETERS:		BX		Signal handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_signalled_name DB 'Is Signalled',0

is_signalled   Proc far
    push ds
    push ax
    push bx
;    
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc is_sig_done
;
    mov al,ds:[bx].sig_state
    or al,al
    stc
    jz is_sig_done
;
    clc

is_sig_done:
    pop bx
    pop ax
    pop ds
    retf32
is_signalled Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetSignal
;
;		DESCRIPTION:	Set signal (to active)
;
;		PARAMETERS:		BX		Signal handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_signal_name DB 'Set Signal',0

set_signal   Proc far
    push ds
    push es
    push ax
    push bx
;    
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc set_sig_done
;
    cli
    mov ds:[bx].sig_state,1
    mov ax,ds:[bx].sig_wait_obj
    or ax,ax
    jz set_sig_done
;
    mov es,ax
    SignalWait
	mov ds:[bx].sig_wait_obj,0

set_sig_done:
    sti
    pop bx
    pop ax
    pop es
    pop ds
    retf32
set_signal Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeSignal
;
;		DESCRIPTION:	Free a signal handle
;
;		PARAMETERS:		BX		Signal handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_signal_name DB 'Free Signal',0

free_signal   Proc far
    push ds
    push ax
;    
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc free_sig_done
;
    FreeHandle

free_sig_done:
    pop ax
    pop ds
    retf32
free_signal Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartWaitForSignal
;
;		DESCRIPTION:	Start a wait for signal
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_signal	PROC far
    push ds
    push ax
    push bx
;
    mov bx,es:sig_handle
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc start_wait_for_done
;
    cli
	mov ds:[bx].sig_wait_obj,es
	mov al,ds:[bx].sig_state
	or al,al
	je start_wait_for_done
;
    mov ds:[bx].sig_state,0
	mov ds:[bx].sig_wait_obj,0
	sti
    SignalWait

start_wait_for_done:
    sti
    pop bx
    pop ax
    pop ds
    ret
start_wait_for_signal Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopWaitForSignal
;
;		DESCRIPTION:	Stop a wait for signal
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_signal	PROC far
    push ds
    push ax
    push bx
;
    mov bx,es:sig_handle
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc stop_wait_signal_done
;
	mov ds:[bx].sig_wait_obj,0

stop_wait_signal_done:
    pop bx
    pop ax
    pop ds
    ret
stop_wait_for_signal Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ClearSignal
;
;		DESCRIPTION:	Clear signal
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_signal	PROC far
    push ds
    push ax
    push bx
;
    mov bx,es:sig_handle
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc clear_signal_done
;
	mov ds:[bx].sig_state,0

clear_signal_done:
    pop bx
    pop ax
    pop ds
    ret
clear_signal Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsSignalIdle
;
;		DESCRIPTION:	Check if signal is idle
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_signal_idle	PROC far
    push ds
    push ax
    push bx
;
    mov bx,es:sig_handle
    mov ax,SIGNAL_HANDLE
    DerefHandle
    jc is_idle_done
;
	mov al,ds:[bx].sig_state
	or al,al
	clc
	je is_idle_done
;
	stc

is_idle_done:
    pop bx
    pop ax
    pop ds
    ret
is_signal_idle Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddWaitForSignal
;
;		DESCRIPTION:	Add a wait for a signal object
;
;		PARAMETERS:		AX      Signal handle
;                       BX      Wait handle
;                       ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_signal_name	DB 'Add Wait For Signal',0

add_wait_tab:
aw0	DW OFFSET start_wait_for_signal,   	wait_code_sel
aw1 DW OFFSET stop_wait_for_signal,		wait_code_sel
aw2	DW OFFSET clear_signal,				wait_code_sel
aw3	DW OFFSET is_signal_idle,		   	wait_code_sel

add_wait_for_signal	PROC far
	push ds
	push es
	push eax
	push di
;
    push ax
    mov ax,cs
    mov es,ax
   	mov ax,SIZE signal_wait_header - SIZE wait_obj_header
    mov di,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_signal_done
;
	mov es:sig_handle,ax

add_wait_signal_done:
    pop di
    pop eax
    pop es
    pop ds
	retf32
add_wait_for_signal	ENDP

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
	mov ax,SIGNAL_HANDLE
	mov di,OFFSET delete_signal_handle
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
	mov si,OFFSET is_wait_idle
	mov di,OFFSET is_wait_idle_name
	xor dx,dx
	mov ax,is_wait_idle_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET wait_no_timeout
	mov di,OFFSET wait_no_timeout_name
	xor dx,dx
	mov ax,wait_no_timeout_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET wait_timeout
	mov di,OFFSET wait_timeout_name
	xor dx,dx
	mov ax,wait_timeout_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET stop_wait
	mov di,OFFSET stop_wait_name
	xor dx,dx
	mov ax,stop_wait_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET remove_wait
	mov di,OFFSET remove_wait_name
	xor dx,dx
	mov ax,remove_wait_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET create_signal
	mov di,OFFSET create_signal_name
	xor dx,dx
	mov ax,create_signal_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET reset_signal
	mov di,OFFSET reset_signal_name
	xor dx,dx
	mov ax,reset_signal_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET is_signalled
	mov di,OFFSET is_signalled_name
	xor dx,dx
	mov ax,is_signalled_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_signal
	mov di,OFFSET set_signal_name
	xor dx,dx
	mov ax,set_signal_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET free_signal
	mov di,OFFSET free_signal_name
	xor dx,dx
	mov ax,free_signal_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET add_wait_for_signal
	mov di,OFFSET add_wait_for_signal_name
	xor dx,dx
	mov ax,add_wait_for_signal_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code	ENDS

	END init
