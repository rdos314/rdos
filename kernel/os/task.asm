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
; TASK.ASM
; Scheduling and thread handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME task

GateSize = 16

INCLUDE system.def
INCLUDE kdebug.def
INCLUDE driver.def
INCLUDE port.def
INCLUDE protseg.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE system.inc
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc

timer_struc	STRUC
timer_next		DW ?
timer_id		DW ?
timer_lsb		DD ?
timer_msb		DD ?
timer_offset	DW ?
timer_sel		DW ?
timer_owner		DW ?
timer_struc	ENDS

task_seg	SEGMENT AT 0

ptab			DW 256 DUP(?)

prio_act		DW ?

thread_act		DW ?

timer_nesting	DW ?

help_call_ip	DW ?
help_call_cs	DW ?

clock_tics		DW ?
system_time		DD ?,?
time_diff		DD ?,?

update_tics		DD ?

preempt_lsb		DD ?
preempt_msb		DD ?

signal_list		DW ?

timer_head		DW ?
timer_free		DW ?
timer_entries	DB 256 * SIZE timer_struc DUP(?)

task_seg_size	DB ?

task_seg	ENDS

	.386p

UpdateClock	MACRO
	local update_not_big
	mov al,80h
	out TIMER_CONTROL,al
	jmp short $+2
	in al,TIMER2
	mov ah,al
	jmp short $+2
	in al,TIMER2
	xchg al,ah
	mov dx,ax
	xchg ax,clock_tics
	sub ax,dx
	movzx eax,ax
	add ds:system_time,eax
	adc ds:system_time+4,0
	add es:p_lsb_tics,eax
	adc es:p_msb_tics,0
					ENDM

GetUpdateTics	MACRO
	mov ax,100h
	cli
	out TIMER0,al
	xchg ah,al
	jmp short $+2
	out TIMER0,al
	UpdateClock
	LocalGetSystemTime
	xor al,al
	out TIMER_CONTROL,al
	jmp short $+2
	in al,TIMER0
	mov ah,al
	jmp short $+2
	in al,TIMER0
	xchg al,ah
	neg ax
	add ax,100h
	movzx eax,ax
	add eax,eax
	add eax,eax
	mov update_tics,eax
					ENDM

LocalGetSystemTime	MACRO
	mov eax,system_time
	mov edx,system_time+4
					ENDM

LocalReloadTimer	MACRO
	out TIMER0,al
	xchg al,ah
	jmp short $+2
	out TIMER0,al
;
	in al,INT0_MASK
	and al,NOT 1
	out INT0_MASK,al
					ENDM

LocalRemoveTimer	MACRO
	local timer_return

	cli
	mov bx,timer_head
	mov ax,[bx].timer_next
	mov timer_head,ax
	sti
	mov cx,[bx].timer_id
	mov eax,[bx].timer_lsb
	mov edx,[bx].timer_msb	
	push bx
	push cs
	push OFFSET timer_return	
	push dword ptr [bx].timer_offset
	xor bx,bx
	mov ds,bx
	mov es,bx
	retf

timer_return:
	pop bx
	mov ax,task_sel
	mov ds,ax
	cli
	mov ax,timer_free
	mov [bx].timer_next,ax
	mov timer_free,bx
	sti
					ENDM

LocalStartTimer	MACRO
	LOCAL start_try_next
	LOCAL start_insert
	mov si,timer_free
	mov [si].timer_owner,bx
	mov bx,[si].timer_next
	mov timer_free,bx
	mov [si].timer_lsb,eax
	mov [si].timer_msb,edx
	mov [si].timer_id,cx
	mov [si].timer_offset,di
	mov [si].timer_sel,es
	mov bx,OFFSET timer_head
	push si
start_try_next:
	mov si,bx
	mov bx,[bx].timer_next
	cmp edx,[bx].timer_msb
	jc start_insert
	jnz start_try_next
	cmp eax,[bx].timer_lsb
	jnc start_try_next
start_insert:
	pop [si].timer_next
	mov si,[si].timer_next
	mov [si].timer_next,bx
				ENDM

LocalStopTimer	MACRO
	LOCAL timer_stop_next
	LOCAL timer_stop_this
	LOCAL timer_stop_done
	mov cx,bx
	mov bx,OFFSET timer_head
timer_stop_next:
	mov si,bx
	mov bx,[bx].timer_next
	or bx,bx
	je timer_stop_done
	cmp cx,[bx].timer_owner
	jne timer_stop_next
timer_stop_this:
	mov ax,[bx].timer_next
	mov [si].timer_next,ax
	mov ax,timer_free
	mov [bx].timer_next,ax
	mov timer_free,bx
timer_stop_done:
				ENDM

GetPrioThread	MACRO
	LOCAL find_prio_lower
	LOCAL find_prio_loop
	LOCAL find_prio_done
	LOCAL find_prio_end
	mov si,prio_act
	mov ax,[si]
	or ax,ax
	je find_prio_lower
	mov es,ax
	mov ax,es:p_next
	mov [si],ax
	jmp find_prio_end	
find_prio_lower:
	sub si,2
	jnc find_prio_loop
	ShutDownTask
find_prio_loop:
	mov ax,[si]
	or ax,ax
	jne find_prio_done
	sub si,2
	jnc find_prio_loop
	ShutDownTask
find_prio_done:
	mov prio_act,si
find_prio_end:
				ENDM

;	ds:di	list
;	es		block

InsertBlock	MACRO
	LOCAL ins_empty
	LOCAL ins_done
	mov es:p_sleep_sel,ds
	mov word ptr es:p_sleep_offset,di
	mov word ptr es:p_sleep_offset+2,0
	push di
	mov di,[di]
	or di,di
	je ins_empty
	push ds
	push si
	mov ds,di
	mov si,ds:p_prev
	mov ds:p_prev,es
	mov ds,si
	mov ds:p_next,es
	mov es:p_next,di
	mov es:p_prev,si
	pop si
	pop ds
	pop di
	jmp ins_done
ins_empty:
	mov es:p_next,es
	mov es:p_prev,es
	pop di
	mov [di],es
ins_done:
		ENDM

;	ds:si		list
;	es			block

RemoveBlock	MACRO
	LOCAL rem_done
	push si
	mov es,[si]
	push di
	push ds
	mov di,es:p_next
	cmp di,[si]
	mov [si],di
	mov si,es:p_prev
	mov ds,di
	mov ds:p_prev,si
	mov ds,si
	mov ds:p_next,di
	pop ds
	pop di
	pop si
	jne rem_done
	mov word ptr [si],0
rem_done:
		ENDM
		
InsertBlock32	MACRO
	LOCAL ins_empty
	LOCAL ins_done
	mov es:p_sleep_sel,ds
	mov es:p_sleep_offset,edi
	push di
	mov di,[edi]
	or di,di
	je ins_empty
	push ds
	push si
	mov ds,di
	mov si,ds:p_prev
	mov ds:p_prev,es
	mov ds,si
	mov ds:p_next,es
	mov es:p_next,di
	mov es:p_prev,si
	pop si
	pop ds
	pop di
	jmp ins_done
ins_empty:
	mov es:p_next,es
	mov es:p_prev,es
	pop di
	mov [edi],es
ins_done:
		ENDM

RemoveBlock32	MACRO
	LOCAL rem_done
	push esi
	mov es,[esi]
	push di
	push ds
	mov di,es:p_next
	cmp di,[esi]
	mov [esi],di
	mov si,es:p_prev
	mov ds,di
	mov ds:p_prev,si
	mov ds,si
	mov ds:p_next,di
	pop ds
	pop di
	pop esi
	jne rem_done
	mov word ptr [esi],0
rem_done:
		ENDM

SetEnviroment	MACRO
	mov ax,process_page_sel
	mov ds,ax
	mov eax,es:p_cr3
	mov cr3,eax
	mov ebx,thread_block_linear SHR 10
	mov eax,es:p_thread_page
	mov [ebx],eax
	mov ebx,app_linear SHR 10
	mov eax,es:p_app_page
	mov [ebx],eax
;
	mov ax,sys_dir_sel
	mov ds,ax
	mov bx,io_focus_linear SHR 20
	mov eax,[bx]
	mov bx,process_dir_sel
	mov ds,bx
	mov bx,io_focus_linear SHR 20
	mov [bx],eax	
		ENDM

code	SEGMENT byte public use16 'CODE'

	assume cs:code,ds:task_seg

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			INIT_TASK
;
;		DESCRIPTION:	Init module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_task

	extrn allocate_fixed_system_mem:near

init_task	PROC near
	pusha
	push ds
	mov bx,task_sel
	mov eax,OFFSET task_seg_size
	push cs
	call allocate_fixed_system_mem
;
	mov ax,task_sel
	mov ds,ax
	mov timer_nesting,-1
	mov signal_list,0
	mov help_call_ip,0
	mov system_time,0
	mov system_time+4,0
	mov time_diff,0
	mov time_diff+4,0
	mov bx,OFFSET ptab
	mov prio_act,bx
	mov cx,256
ptab_init:
	mov word ptr [bx],0
	inc bx
	inc bx
	loop ptab_init
;
	mov bx,OFFSET timer_entries
	mov [bx].timer_next,0
	mov [bx].timer_msb,0FFFFFFFFh
	mov [bx].timer_lsb,0FFFFFFFFh
	mov timer_head,bx
;
	mov update_tics,0
;
	mov cx,0FFh
	add bx,SIZE timer_struc
	mov timer_free,bx
timer_free_list_create:
	mov ax,bx
	add ax,SIZE timer_struc
	mov [bx].timer_next,ax
	mov bx,ax
	loop timer_free_list_create
;
	mov thread_act,virt_thread_sel
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET start_timer
	mov di,OFFSET start_timer_name
	xor cl,cl
	mov ax,start_timer_nr
	RegisterOsGate
;
	mov si,OFFSET stop_timer
	mov di,OFFSET stop_timer_name
	xor cl,cl
	mov ax,stop_timer_nr
	RegisterOsGate
;
	mov si,OFFSET wake_thread
	mov di,OFFSET wake_thread_name
	xor cl,cl
	mov ax,wake_thread_nr
	RegisterOsGate
;
	mov si,OFFSET sleep_thread
	mov di,OFFSET sleep_thread_name
	xor cl,cl
	mov ax,sleep_thread_nr
	RegisterOsGate
;
	mov si,OFFSET wake32_thread
	mov di,OFFSET wake32_thread_name
	xor cl,cl
	mov ax,wake32_thread_nr
	RegisterOsGate
;
	mov si,OFFSET sleep32_thread
	mov di,OFFSET sleep32_thread_name
	xor cl,cl
	mov ax,sleep32_thread_nr
	RegisterOsGate
;
	mov si,OFFSET clear_signal
	mov di,OFFSET clear_signal_name
	xor cl,cl
	mov ax,clear_signal_nr
	RegisterOsGate
;
	mov si,OFFSET signal_thread
	mov di,OFFSET signal_thread_name
	xor cl,cl
	mov ax,signal_nr
	RegisterOsGate
;
	mov si,OFFSET wait_for_signal
	mov di,OFFSET wait_for_signal_name
	xor cl,cl
	mov ax,wait_for_signal_nr
	RegisterOsGate
;
	mov si,OFFSET get_thread_pr
	mov di,OFFSET get_thread_name
	xor cl,cl
	mov ax,get_thread_nr
	RegisterUserGate
;
	mov si,OFFSET get_cpu_time
	mov di,OFFSET get_cpu_time_name
	xor cl,cl
	mov ax,get_cpu_time_nr
	RegisterUserGate
;
	mov si,OFFSET init_task_pr
	mov di,OFFSET init_task_name
	xor cl,cl
	mov ax,init_task_nr
	RegisterOsGate
;
	mov si,OFFSET wait_run_task
	mov di,OFFSET wait_run_task_name
	xor cl,cl
	mov ax,wait_run_task_nr
	RegisterOsGate
;
	mov si,OFFSET wait_sleep_task
	mov di,OFFSET wait_sleep_task_name
	xor cl,cl
	mov ax,wait_sleep_task_nr
	RegisterOsGate
;
	mov si,OFFSET change_enviroment
	mov di,OFFSET change_enviroment_name
	xor cl,cl
	mov ax,change_enviroment_nr
	RegisterOsGate
;
	mov si,OFFSET swap_out
	mov di,OFFSET swap_name
	xor cl,cl
	mov ax,swap_nr
	RegisterUserGate
;
	mov si,OFFSET wait_milli_sec
	mov di,OFFSET wait_milli_name
	xor cl,cl
	mov ax,wait_milli_nr
	RegisterUserGate
	mov bx,ax
	mov dx,0
	mov ax,wait_virt_milli_nr
	RegisterVirtUserGate
;
	mov si,OFFSET wait_micro_sec
	mov di,OFFSET wait_micro_name
	xor cl,cl
	mov ax,wait_micro_nr
	RegisterUserGate
	mov bx,ax
	mov dx,0
	mov ax,wait_virt_micro_nr
	RegisterVirtUserGate
;
	mov si,OFFSET wait_until
	mov di,OFFSET wait_until_name
	xor cl,cl
	mov ax,wait_until_nr
	RegisterUserGate
	mov bx,ax
	xor dx,dx
	mov ax,wait_virt_until_nr
	RegisterVirtUserGate
;
	mov si,OFFSET get_system_time
	mov di,OFFSET get_system_time_name
	xor cl,cl
	mov ax,get_system_time_nr
	RegisterUserGate
;
	mov si,OFFSET get_time
	mov di,OFFSET get_time_name
	xor cl,cl
	mov ax,get_time_nr
	RegisterUserGate
;
	mov si,OFFSET time_to_system_time
	mov di,OFFSET time_to_system_time_name
	xor cl,cl
	mov ax,time_to_system_time_nr
	RegisterUserGate
;
	mov si,OFFSET system_time_to_time
	mov di,OFFSET system_time_to_time_name
	xor cl,cl
	mov ax,system_time_to_time_nr
	RegisterUserGate
;
	mov si,OFFSET set_system_time
	mov di,OFFSET set_system_time_name
	xor cl,cl
	mov ax,set_system_time_nr
	RegisterOsGate
;
	mov si,OFFSET sim_sti
	mov di,OFFSET sim_sti_name
	xor cl,cl
	mov ax,sim_sti_nr
	RegisterOsGate
;
	mov si,OFFSET sim_cli
	mov di,OFFSET sim_cli_name
	xor cl,cl
	mov ax,sim_cli_nr
	RegisterOsGate
;
	mov si,OFFSET sim_set_flags
	mov di,OFFSET sim_set_flags_name
	xor cl,cl
	mov ax,sim_set_flags_nr
	RegisterOsGate
;
	mov si,OFFSET sim_get_flags
	mov di,OFFSET sim_get_flags_name
	xor cl,cl
	mov ax,sim_get_flags_nr
	RegisterOsGate
;
	mov si,OFFSET update_time
	mov di,OFFSET update_time_name
	xor cl,cl
	mov ax,update_time_nr
	RegisterOsGate
;
	mov si,OFFSET debug_break
	mov di,OFFSET debug_break_name
	xor cl,cl
	mov ax,debug_break_nr
	RegisterOsGate
;
	mov si,OFFSET enter_section
	mov di,OFFSET enter_section_name
	xor cl,cl
	mov ax,enter_section_nr
	RegisterUserGate
	mov bx,ax
	mov dx,virt_ds_in
	mov ax,enter_virt_section_nr
	RegisterVirtUserGate
;
	mov si,OFFSET leave_section
	mov di,OFFSET leave_section_name
	xor cl,cl
	mov ax,leave_section_nr
	RegisterUserGate
	mov bx,ax
	mov dx,virt_ds_in
	mov ax,leave_virt_section_nr
	RegisterVirtUserGate
;
	mov si,OFFSET leave_section_sleep
	mov di,OFFSET leave_section_sleep_name
	xor cl,cl
	mov ax,leave_section_sleep_nr
	RegisterUserGate
;
	mov si,OFFSET get_debug_thread16
	mov di,OFFSET get_debug_thread_name
	xor cl,cl
	mov ax,get_debug_thread_nr
	RegisterUserGate16
	mov si,OFFSET get_debug_thread32
	mov di,OFFSET get_debug_thread_name
	xor cl,cl
	mov ax,get_debug_thread_nr
	RegisterUserGate32
	mov bx,ax
	xor dx,dx
	mov ax,get_virt_debug_thread_nr
	RegisterVirtUserGate
;
	mov si,OFFSET get_debug_tss16
	mov di,OFFSET get_debug_tss_name
	xor cl,cl
	mov ax,get_debug_tss_nr
	RegisterUserGate16
	mov si,OFFSET get_debug_tss32
	mov di,OFFSET get_debug_tss_name
	xor cl,cl
	mov ax,get_debug_tss_nr
	RegisterUserGate32
	mov bx,ax
	mov dx,virt_es_in
	mov ax,get_virt_debug_tss_nr
	RegisterVirtUserGate
;
	mov si,OFFSET debug_trace
	mov di,OFFSET debug_trace_name
	xor cl,cl
	mov ax,debug_trace_nr
	RegisterUserGate
	mov bx,ax
	xor dx,dx
	mov ax,debug_virt_trace_nr
	RegisterVirtUserGate
;
	mov si,OFFSET debug_pace
	mov di,OFFSET debug_pace_name
	xor cl,cl
	mov ax,debug_pace_nr
	RegisterUserGate
	mov bx,ax
	xor dx,dx
	mov ax,debug_virt_pace_nr
	RegisterVirtUserGate
;
	mov si,OFFSET debug_go
	mov di,OFFSET debug_go_name
	xor cl,cl
	mov ax,debug_go_nr
	RegisterUserGate
	mov bx,ax
	xor dx,dx
	mov ax,debug_virt_go_nr
	RegisterVirtUserGate
;
	mov si,OFFSET debug_next
	mov di,OFFSET debug_next_name
	xor cl,cl
	mov ax,debug_next_nr
	RegisterUserGate
	mov bx,ax
	xor dx,dx
	mov ax,debug_virt_next_nr
	RegisterVirtUserGate
;
	mov di,OFFSET check_list
	HookState
;
	pop ds
	popa
	ret
init_task	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadWord
;
;		DESCRIPTION:	Read a word in another thread
;
;		PARAMETERS:		DX:ESI	Address
;						ES		TSS
;
;		RETURNS:		AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadWord	Proc near
	push bx
	push cx
	push esi
	mov bx,es:tss_thread
	test es:tss_eflags+2,2
	jz read_word_prot
read_word_virt:
	ReadThreadSegment
	mov cx,ax
	inc si
	ReadThreadSegment
	mov ah,al
	mov al,cl
	jmp read_word_done
read_word_prot:
	ReadThreadSelector
	mov cx,ax
	inc esi
	ReadThreadSelector
	mov ah,al
	mov al,cl
read_word_done:
	pop esi
	pop cx
	pop bx	
	ret
ReadWord	Endp

page

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteWord
;
;		DESCRIPTION:	Write a word in another thread
;
;		PARAMETERS:		DX:ESI	Address
;						ES		TSS
;						AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteWord	Proc near
	push bx
	push cx
	push esi
	mov cx,ax
	mov bx,es:tss_thread
	test es:tss_eflags+2,2
	jz write_word_prot
write_word_virt:
	mov al,cl
	WriteThreadSegment
	inc si
	mov al,ch
	WriteThreadSegment
	jmp write_word_done
write_word_prot:
	mov al,cl
	WriteThreadSelector
	inc esi
	mov al,ch
	WriteThreadSelector
write_word_done:
	pop esi
	pop cx
	pop bx	
	ret
WriteWord	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GET_DEBUG_THREAD
;
;		DESCRIPTION:	Get currently debugged thread
;
;		PARAMETERS:		AX		DEBUG THREAD OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_thread	PROC near
	push ds
	push es
	push cx
	push dx
	push si
	mov ax,kdebug_data_sel
	mov ds,ax
	mov cx,ds:debug_thread
	mov ax,system_data_sel
	mov ds,ax
	mov si,OFFSET debug_list
	mov ax,[si]
	or ax,ax
	jz get_debug_done
	mov dx,ax
get_debug_try_next:
	cmp ax,cx
	je get_debug_default
	mov es,ax
	mov ax,es:p_next
	cmp dx,ax
	je get_debug_new
	jmp get_debug_try_next
get_debug_new:
	mov cx,[si]
get_debug_default:
	mov ax,kdebug_data_sel
	mov ds,ax
	mov ds:debug_thread,cx
	mov ax,cx
get_debug_done:
	pop si
	pop dx
	pop cx
	pop es
	pop ds
	ret
get_debug_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GET_DEBUG_THREAD
;
;		DESCRIPTION:	Get currently debugged thread syscall
;
;		PARAMETERS:		AX			THREAD BLOCK OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_thread_name	DB 'Get Debug Thread',0

get_debug_thread16	PROC far
	call get_debug_thread
	ret
get_debug_thread16	ENDP

get_debug_thread32	PROC far
	call get_debug_thread
	retf32
get_debug_thread32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GET_DEBUG_TSS
;
;		DESCRIPTION:	Get currently debugged TSS
;
;		PARAMETERS:		ES:(E)DI	BUFFER FOR TSS
;						AX			THREAD BLOCK OR 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_debug_tss_name	DB 'Get Debug TSS',0

get_debug_tss16	PROC far
	push ds
	push si
	call get_debug_thread
	or ax,ax
	jz get_debug_tss_done16
	mov ds,ax
	mov ds,ds:p_tss_data_sel
	xor si,si
	mov cx,OFFSET tss_bitmap_space
	rep movsb
get_debug_tss_done16:	
	pop si
	pop ds
	ret
get_debug_tss16	ENDP

get_debug_tss32	PROC far
	push ds
	push esi
	call get_debug_thread
	or ax,ax
	jz get_debug_tss_done32
	mov ds,ax
	mov ds,ds:p_tss_data_sel
	xor esi,esi
	mov ecx,OFFSET tss_bitmap_space
	rep movs byte ptr es:[edi],[esi]
get_debug_tss_done32:	
	pop esi
	pop ds
	retf32
get_debug_tss32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DEBUG_TRACE
;
;		DESCRIPTION:	Trace one instruction in debugged thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_trace_name	DB 'Debug Trace',0

debug_trace	PROC far
	push ds
	push es
	pushad
	call get_debug_thread
	or ax,ax
	jz debug_trace_done
	mov bx,ax
	mov es,bx
	mov es,es:p_tss_data_sel
	mov dx,es:tss_cs
	mov esi,dword ptr es:tss_eip
	call ReadWord
	push ax
	add esi,2
	call ReadWord
	mov dx,ax
	pop ax	
	cmp al,0CDh
	jne debug_trace_trace
;
	test es:tss_eflags+2,2
	jz debug_trace_trace
	and es:tss_eflags+2,NOT 2
	mov dx,vm_int_sel
	movzx esi,ah
	shl esi,2
	call ReadWord
	push ax
	add si,2
	call ReadWord
	mov dx,ax
	pop bx
;
	push dx
	push bx
	or es:tss_eflags+2,2
	mov bx,es:tss_thread
	mov dx,es:tss_ss
	movzx esi,es:tss_esp
	sub esi,6
	pop ax
	pop cx
	xchg ax,es:tss_eip
	xchg cx,es:tss_cs
	add ax,2
	call WriteWord
	mov ax,cx
	add esi,2
	call WriteWord
	mov ax,es:tss_eflags
	add esi,2
	call WriteWord
	sub es:tss_esp,6
	jmp debug_trace_done
debug_trace_trace:
	mov eax,dr7
	and ax,0FFFCh
	mov dr7,eax
	mov es:tss_dr7,eax
	mov bx,es:tss_thread
	mov ax,es:tss_eflags
	or ax,100h
	mov es:tss_eflags,ax
	mov ax,system_data_sel
	mov ds,ax
	mov si,OFFSET debug_list
	mov [si],bx
	mov es,ax
	Wake
debug_trace_done:
	popad
	pop es
	pop ds
	retf32
debug_trace	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DEBUG_PACE
;
;		DESCRIPTION:	Pace one instruction in debugged thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_pace_name	DB 'Debug Pace',0


load_break	PROC far
	mov ax,thread_tss_sel
	mov ds,ax
	mov eax,ds:tss_dr0
	mov dr0,eax
	mov eax,ds:tss_dr1
	mov dr1,eax
	mov eax,ds:tss_dr2
	mov dr2,eax
	mov eax,ds:tss_dr3
	mov dr3,eax
	mov eax,ds:tss_dr7
	mov dr7,eax
	and ax,0FFh
	jz load_break_done
	mov ds:tss_t,1
load_break_done:
	ret
load_break	ENDP


debug_pace	PROC far
	push ds
	push es
	pushad
	call get_debug_thread
	or ax,ax
	jz debug_pace_done
	mov bx,ax
	mov es,bx
	mov es,es:p_tss_data_sel
	mov dx,es:tss_cs
	mov esi,dword ptr es:tss_eip
	call ReadWord
	push ax
	add esi,2
	call ReadWord
	mov dx,ax
	pop ax
	xor ebx,ebx
	add bx,2
	cmp al,0E2h
	je debug_pace_step
	cmp al,0CDh
	je debug_pace_step
	inc bx
	cmp al,0E8h
	je debug_pace_step
	add bx,2
	cmp ax,00B0Fh
	jne debug_pace_not_gate
	cmp dl,66h
	jne debug_pace_step
	inc bx
	jmp debug_pace_step
debug_pace_not_gate:
	cmp al,9Ah
	je debug_pace_step
	inc bx
	cmp ax,9A66h
	je debug_pace_step
	jmp debug_pace_trace
debug_pace_step:
	push ax
	mov ax,es:tss_eflags+2
	test ax,2
	jz debug_pace_step_prot
	pop ax
	xor eax,eax
	xor edx,edx
	mov ax,es:tss_cs
	shl eax,4
	mov dx,es:tss_eip
	add eax,edx
	jmp debug_pace_step_do
debug_pace_step_prot:
	mov si,es:tss_cs
	test si,4
	jz debug_pace_step_gdt
	xor eax,eax
	mov ds,es:tss_thread
	mov ds,ds:p_ldt_sel
	mov si,es:tss_cs
	and si,0FFF8h
	pop ax
	cmp al,0E8h
	jne debug_pace_ldt16
	mov al,[si+6]
	test al,40h
	jz debug_pace_ldt16
	add bx,2
debug_pace_ldt16:
	mov eax,[si+2]
	rol eax,8
	mov al,[si+7]
	ror eax,8
	add eax,dword ptr es:tss_eip
	jmp debug_pace_step_do
debug_pace_step_gdt:
	and si,0FFF8h
	mov ax,gdt_sel
	mov ds,ax
	pop ax
	cmp al,0E8h
	jne debug_pace_gdt16
	mov al,[si+6]
	test al,40h
	jz debug_pace_gdt16
	add bx,2
debug_pace_gdt16:
	mov eax,[si+2]
	rol eax,8
	mov al,[si+7]
	ror eax,8
	add eax,dword ptr es:tss_eip
debug_pace_step_do:
	add eax,ebx
	mov es:tss_dr0,eax
	mov eax,es:tss_dr7
	and eax,0FFF0FFFCh
	or ax,1
	mov es:tss_dr7,eax
	mov es:tss_t,1
	mov ax,es:tss_eflags
	and ax,NOT 100h
	mov es:tss_eflags,ax
	jmp debug_pace_do
debug_pace_trace:
	mov eax,dr7
	and ax,0FFFCh
	mov dr7,eax
	mov es:tss_dr7,eax
	mov ax,es:tss_eflags
	or ax,100h
	mov es:tss_eflags,ax
debug_pace_do:
;
	mov bx,es:tss_thread
	mov ds,bx
	mov ds:p_trap_ads,OFFSET load_break
	mov ds:p_trap_ads+2,cs
;
	mov ax,system_data_sel
	mov ds,ax
	mov si,OFFSET debug_list
	mov [si],bx
	mov es,ax
	Wake
debug_pace_done:
	popad
	pop es
	pop ds
	retf32
debug_pace	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DEBUG_GO
;
;		DESCRIPTION:	Run currently debugged thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_go_name	DB 'Debug Go',0

debug_go	PROC far
	push ds
	push es
	pushad
	call get_debug_thread
	or ax,ax
	jz debug_go_done
	mov bx,ax
	mov es,bx
	mov es,es:p_tss_data_sel
	mov eax,dr7
	and ax,0FFFCh
	mov dr7,eax
	mov es:tss_dr7,eax
	mov ax,es:tss_eflags
	and ax,NOT 100h
	mov es:tss_eflags,ax
;
	mov ax,system_data_sel
	mov ds,ax
	mov si,OFFSET debug_list
	mov [si],bx
	mov es,ax
	Wake
debug_go_done:
	popad
	pop es
	pop ds
	retf32
debug_go	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DEBUG_NEXT
;
;		DESCRIPTION:	Select next thread as currently debugged
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_next_name	DB 'Debug Next',0

debug_next	PROC far
	push ds
	push es
	push ax
	push si
	mov ax,system_data_sel
	mov ds,ax
	mov si,OFFSET debug_list
	mov ax,[si]
	or ax,ax
	je debug_next_end
	mov es,ax
	mov es,es:p_next
	mov [si],es
	mov ax,kdebug_data_sel
	mov ds,ax
	mov ds:debug_thread,es
debug_next_end:
	pop si
	pop ax
	pop es
	pop ds
	retf32
debug_next	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			VIRT_sti
;
;		DESCRIPTION:	Simulate STI
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public virt_sti

virt_sti	PROC near
	mov bx,thread_sel
	mov ds,bx
	mov ds,ds:p_process_sel
	mov ds:ms_virt_flags,7200h
virt_sti_test_wake:
	cli
	cmp ds:ms_wait_sti,0
	jz virt_sti_nowake
	push si
	mov si,OFFSET ms_wait_sti
	Wake
	pop si
	jmp virt_sti_test_wake
virt_sti_nowake:
	sti
	inc byte ptr [bp].vm_eip
	ret
virt_sti	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			sim_sti
;
;		DESCRIPTION:	Simulate STI
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_sti_name	DB 'Simulate Sti',0

sim_sti	PROC far
	push ds
	push bx
	sti
	mov bx,thread_sel
	mov ds,bx
	mov ds,ds:p_process_sel
	mov ds:ms_virt_flags,7200h
sim_sti_test_wake:
	cmp ds:ms_wait_sti,0
	jz sim_sti_nowake
	push si
	mov si,OFFSET ms_wait_sti
	Wake
	pop si
	jmp sim_sti_test_wake
sim_sti_nowake:
	pop bx
	pop ds
	ret
sim_sti	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			virt_cli
;
;		DESCRIPTION:	Simulate CLI
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public virt_cli

virt_cli	PROC near
	mov bx,thread_sel
	mov ds,bx
	mov bx,ds:p_thread_sel
	mov ds,ds:p_process_sel
	cli
	mov ds:ms_cli_thread,bx
	mov ds:ms_virt_flags,7000h
	sti
	inc byte ptr [bp].vm_eip
	ret
virt_cli	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			sim_cli
;
;		DESCRIPTION:	Simulate CLI
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_cli_name	DB 'Simulate Cli',0

sim_cli	PROC far
	push ds
	push bx
	mov bx,thread_sel
	mov ds,bx
	mov bx,ds:p_thread_sel
	mov ds,ds:p_process_sel
	cli
	mov ds:ms_cli_thread,bx
	mov ds:ms_virt_flags,7000h
	sti
	pop bx
	pop ds
	ret
sim_cli	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			set_flags
;
;		DESCRIPTION:	Simulate set flags
;
;		PARAMETERS:		AX		FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public set_flags

set_flags	PROC near
	mov bx,thread_sel
	mov ds,bx
	mov bx,ds:p_thread_sel
	mov ds,ds:p_process_sel
	cli
	mov ds:ms_cli_thread,bx
	mov bx,ax
	and bx,200h
	or bx,7000h
	mov ds:ms_virt_flags,bx
	sti
	test bx,200h
	jz set_flags_nowake
set_flags_test_wake:
	cmp ds:ms_wait_sti,0
	jz set_flags_nowake
	push si
	mov si,OFFSET ms_wait_sti
	Wake
	pop si
	jmp set_flags_test_wake
set_flags_nowake:
	and ax,NOT 7000h
	or ax,200h
	ret
set_flags	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			sim_set_flags
;
;		DESCRIPTION:	Simulate set flags
;
;		PARAMETERS:		AX		FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_set_flags_name	DB 'Set Flags',0

sim_set_flags	PROC far
	push ds
	push bx
	call set_flags
	pop bx
	pop ds
	ret
sim_set_flags	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_flags
;
;		DESCRIPTION:	Modify int bit in simulated flags
;
;		PARAMETERS:		AX		FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public get_flags

get_flags	PROC near
	mov bx,thread_sel
	mov ds,bx
	mov ds,ds:p_process_sel
	and ax,NOT 200h
	mov bx,ds:ms_virt_flags
	and bx,200h
	or ax,bx
	or ax,7000h
	ret
get_flags	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			sim_get_flags
;
;		DESCRIPTION:	Modify int bit in simulated flags
;
;		PARAMETERS:		AX		FLAGS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sim_get_flags_name	DB 'Get Flags',0

sim_get_flags	PROC far
	push ds
	push bx
	call get_flags
	pop bx
	pop ds
	ret
sim_get_flags	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetNextThread
;
;		DESCRIPTION:	Get next thread to run
;
;		PARAMETERS:	
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetNextThread	Proc near
	push es
get_next_int_loop:
	GetPrioThread
	mov es,ax
	mov es,es:p_process_sel
	test es:ms_virt_flags,200h
	jnz get_next_int_ok
	cmp ax,es:ms_cli_thread
	jz get_next_int_ok
	mov ax,es
	mov si,prio_act
	RemoveBlock              
	push ds  
	mov ds,ax
	mov di,OFFSET ms_wait_sti
	InsertBlock
	pop ds
	jmp get_next_int_loop
get_next_int_ok:
	LocalGetSystemTime
	add eax,1193
	adc edx,0
	mov preempt_lsb,eax
	mov preempt_msb,edx
	pop es
	ret
GetNextThread	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdateTimer
;
;		DESCRIPTION:	Update timers
;						uses EAX,BX and EDX
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateTimer	Proc near
	cli
	add timer_nesting,1
	jc update_timer_loop
	dec timer_nesting
	jmp update_timer_done
update_timer_loop:
	mov es,thread_act
	cli
	UpdateClock
	LocalGetSystemTime
	add eax,update_tics
	adc edx,0
	mov bx,timer_head
	mov ecx,preempt_msb
	cmp ecx,[bx].timer_msb
	jc check_preempt
	jnz check_timer
	mov ecx,preempt_lsb
	cmp ecx,[bx].timer_lsb
	jc check_preempt

check_timer:
	sub eax,[bx].timer_lsb
	sbb edx,[bx].timer_msb
	jc reload_timer
	LocalRemoveTimer
	jmp update_timer_loop

check_preempt:
	sub eax,preempt_lsb
	sbb edx,preempt_msb
	jc reload_timer
	sti
	nop
	cli
	call GetNextThread
	sti
	jmp update_timer_loop

reload_timer:
	sub timer_nesting,1
	jnc update_timer_done
	neg eax
	LocalReloadTimer
;
	mov si,prio_act
	mov ax,[si]
	cmp ax,thread_act
	je update_timer_done
	UpdateClock
	LocalGetSystemTime
	add eax,1193
	adc edx,0
	mov preempt_lsb,eax
	mov preempt_msb,edx
	mov si,prio_act
	mov es,[si]
	mov thread_act,es
	str ax
	mov si,es:p_tss_sel
	cmp ax,si
	je update_timer_done
	SetEnviroment
	mov ax,task_sel
	mov ds,ax
	mov es,ax
	mov help_call_cs,si
	jmp dword ptr help_call_ip
update_timer_done:
	ret
UpdateTimer	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SCHEDULE
;
;		DESCRIPTION:	Schedule new thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

schedule	PROC near
	push ds
	push es
	pushad
;
	mov ax,task_sel
	mov ds,ax
	cli
	call GetNextThread
	call UpdateTimer
	sti
;
	popad
	pop es
	pop ds
	ret
schedule	ENDP

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ENTER_INT
;
;		DESCRIPTION:	Enter interrupt notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public enter_int

enter_int	Proc near		
	mov ax,task_sel
	mov ds,ax
	inc ds:timer_nesting
	ret
enter_int	Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LEAVE_INT
;
;		DESCRIPTION:	Leave interrupt notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public leave_int

leave_int	Proc near
	mov ax,task_sel
	mov ds,ax
	sub ds:timer_nesting,1
	jnc leave_int_done
	call UpdateTimer
leave_int_done:
	ret
leave_int	Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TIMER_INT
;
;		DESCRIPTION:	Timer interrupt handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public timer_int

timer_int:
	push ds
	push es
	pushad
;
	in al,INT0_MASK
	or al,1
	out INT0_MASK,al
;
	mov al,20h
	out INT0_CONTROL,al
	mov ax,task_sel
	mov ds,ax
	call UpdateTimer
;
	popad
	pop es
	pop ds
	iretd

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			START_TIMER
;
;		DESCRIPTION:	Start a timer
;
;		PARAMETERS:		EDX:EAX		Timeout time
;						ES:DI		Callback
;						BX			Owner
;						CX			ID
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_timer_name DB 'Start Timer',0

start_timer	PROC far
	push ds
	push es
	pushad
;
	mov si,task_sel
	mov ds,si
	cli
	LocalStartTimer
	call UpdateTimer
	sti
;
	popad
	pop es
	pop ds
	ret
start_timer	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			STOP_TIMER
;
;		DESCRIPTION:	Stop timer
;
;		PARAMETERS:		BX			Owner
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_timer_name DB 'Stop Timer',0

stop_timer	PROC far
	push ds
	push es
	pushad
;
	mov si,task_sel
	mov ds,si
	cli
	LocalStopTimer
	call UpdateTimer
	sti
;
	popad
	pop es
	pop ds
	ret
stop_timer	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_first_thread
;
;		DESCRIPTION:	Init first thread
;
;		PARAMETERS:		ES		Thread control block
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_first_thread

init_first_thread	Proc near
	mov ax,task_sel
	mov ds,ax
	mov di,es:p_prio
	mov prio_act,di
	InsertBlock
;
	mov ax,30h
	out TIMER_CONTROL,al
	GetUpdateTics
;
	mov al,0B4h
	out TIMER_CONTROL,al
	jmp short $+2
	mov al,0
	out TIMER2,al
	jmp short $+2
	out TIMER2,al
	mov clock_tics,0
	jmp short $+2
	mov al,0Dh
	out 61h,al
;
	in al,INT0_MASK
	and al,NOT 1
	out INT0_MASK,al
;
	call GetNextThread
	call UpdateTimer
	sti
	ret
init_first_thread	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CHANGE_ENVIROMENT
;
;		DESCRIPTION:	Change thread environment (fixed thread addresses)
;
;		PARAMETERS:		AX		THREAD
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

change_enviroment_name	DB 'Change Enviroment',0

change_enviroment	Proc far
	push ds
	push es
	push eax
	push ebx
	mov es,ax
	SetEnviroment
	mov ds,es:p_tss_data_sel
	lldt ds:tss_ldt
	pop ebx
	pop eax
	pop es	
	pop ds
	ret
change_enviroment	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			INIT_TASK_PR,WAIT_RUN_TASK,WAIT_SLEEP_TASK
;
;		DESCRIPTION:	Task handling. Obsolete, should not be used
;
;		PARAMETERS:		AX		CALLING THREAD
;						DS:DI	SLEEP LIST
;						EDX		ERROR CODE
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_task_name	DB 'Init Task',0

init_task_pr:
	push ds
	push es
	push fs
	push si
	push di
	mov si,task_sel
	mov ds,si
	mov es,thread_act
	mov fs,es:p_tss_data_sel
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,0
	cli
	UpdateClock
	RemoveBlock
	push es
	jmp schedule_task

wait_sleep_task_name	DB 'Wait Sleep Task',0

wait_sleep_task:
	push ds
	push es
	push fs
	push si
	push di
;
	push ds
	push ax
	mov si,task_sel
	mov ds,si
	mov es,thread_act
	mov fs,es:p_tss_data_sel
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,0
	cli
	UpdateClock
	RemoveBlock
	mov ax,es
	pop es
	pop ds
	push ax
	InsertBlock
	mov si,task_sel
	mov ds,si
	jmp schedule_task

wait_run_task_name	DB 'Wait Run Task',0
	
wait_run_task	Proc far
	push ds
	push es
	push fs
	push si
	push di
	push ax
	mov si,task_sel
	mov ds,si
	mov es,thread_act
	mov fs,es:p_tss_data_sel
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,0
	cli
	UpdateClock
	RemoveBlock
	mov ax,es
	pop es
	push ax
	mov di,es:p_prio
	InsertBlock
	cmp di,prio_act
	jb schedule_task
	mov prio_act,di
	jmp leave_task_end
schedule_task:
	call GetNextThread
	mov si,prio_act
	mov es,[si]
leave_task_end:
	mov thread_act,es
	mov si,es:p_tss_sel
	mov fs:tss_back_link,si
	pushf
	pop ax
	or ax,4000h
	push ax
	popf
	SetEnviroment
	mov ax,gdt_sel
	mov es,ax
	mov fs,ax
	mov ax,task_sel
	mov ds,ax
	mov byte ptr es:[si+5],8Bh
	mov ax,sp
	iretd
	xor edx,edx
	cmp ax,sp
	je enter_task_no_error_code
	pop edx
enter_task_no_error_code:
	mov es,thread_act
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,0
	UpdateClock
	RemoveBlock
	mov ax,es
	pop es
	push ax
	mov di,es:p_prio
	InsertBlock
	mov thread_act,es
	push ds
	SetEnviroment
	pop ds
	mov es,es:p_tss_data_sel
	mov si,es:tss_back_link
	mov bx,gdt_sel
	mov es,bx
	mov byte ptr es:[si+5],89h
	pushf
	pop ax
	and ax,NOT 4000h
	push ax
	popf
	cmp di,prio_act
	jb enter_prio_lower
	mov prio_act,di
	sti
	jmp enter_task_end
enter_prio_lower:
	pushad
	call GetNextThread
	call UpdateTimer
	sti
	popad
enter_task_end:
	pop ax
	pop di
	pop si
	pop fs
	pop es
	pop ds
	ret
wait_run_task	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WAKE_NEW
;
;		DESCRIPTION:	Wake-up a newly create thread
;
;		PARAMETERS:		ES			Thread
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public wake_new

wake_new	PROC near
	mov ax,task_sel
	mov ds,ax
	cli
	mov di,es:p_prio
	InsertBlock
	cmp di,prio_act
	jb cr_prio_lower
	mov prio_act,di
	xor ax,ax
	mov es,ax
	call GetNextThread
	call UpdateTimer
cr_prio_lower:
	sti
	ret
wake_new	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SWAP
;
;		DESCRIPTION:	Voluntarily swap. Should not be used!
;
;		PARAMETER:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

swap_name	DB 'Swap',0

swap_out	PROC far
	push ds
	push es
	pushad
	mov ax,task_sel
	mov ds,ax
	cli
	call GetNextThread
	call UpdateTimer
	sti
	popad
	pop es
	pop ds
	retf32
swap_out	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WAKE
;
;		DESCRIPTION:	Wake up thread
;
;		PARAMETERS:		DS:SI		Thread list
;						EAX			Status to thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wake_thread_name	DB 'Wake',0

wake_thread	PROC far
	push ds
	push es
	pushad
;
	cli
	mov di,[si]
	or di,di
	jz wake_done
	RemoveBlock
	mov di,task_sel
	mov ds,di
	mov di,es:p_prio
	mov es:p_data,eax
	InsertBlock
	cmp di,prio_act
	jb wake_done
	mov prio_act,di
	call GetNextThread
	call UpdateTimer
wake_done:
	sti
	popad
	pop es
	pop ds
	ret
wake_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SLEEP
;
;		DESCRIPTION:	Suspend thread
;
;		PARAMETERS:		DS:DI	Suspend list
;
;		RETURNS:		EAX		Wake-up status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sleep_thread_name	DB 'Sleep',0

sleep_thread	PROC far
	push ds
	push es
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov cx,ds
	mov si,task_sel
	mov ds,si
	cli
	mov es,thread_act
	mov si,es:p_prio
	RemoveBlock
	mov ds,cx
	InsertBlock
	mov cx,task_sel
	mov ds,cx
	call GetNextThread
	call UpdateTimer
	sti
	mov es,thread_act
	mov eax,es:p_data
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop es
	pop ds
	ret
sleep_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WAKE32_THREAD
;
;		DESCRIPTION:	Wake up thread
;
;		PARAMETERS:		DS:ESI		Thread list
;						EAX			Status to thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wake32_thread_name	DB 'Wake32',0

wake32_thread	PROC far
	push ds
	push es
	pushad
;
	cli
	mov di,[esi]
	or di,di
	jz wake32_done
	RemoveBlock32
	mov di,task_sel
	mov ds,di
	mov di,es:p_prio
	mov es:p_data,eax
	InsertBlock
	cmp di,prio_act
	jb wake32_done
	mov prio_act,di
	call GetNextThread
	call UpdateTimer
wake32_done:
	sti
;
	popad
	pop es
	pop ds
	ret
wake32_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SLEEP32
;
;		DESCRIPTION:	Suspend thread
;
;		PARAMETERS:		DS:EDI	Suspend list
;
;		RETURNS:		EAX		Wake up status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sleep32_thread_name	DB 'Sleep32',0

sleep32_thread	PROC far
	push ds
	push es
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov cx,ds
	mov si,task_sel
	mov ds,si
	cli
	mov es,thread_act
	mov si,es:p_prio
	RemoveBlock
	mov ds,cx
	InsertBlock32
	mov cx,task_sel
	mov ds,cx
	call GetNextThread
	call UpdateTimer
	sti
	mov es,thread_act
	mov eax,es:p_data
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop es
	pop ds
	ret
sleep32_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ClearSignal
;
;		DESCRIPTION:	Set status to unsignaled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_signal_name	DB 'Clear Signal',0

clear_signal	PROC far
	push ds
	push ax
;
	mov ax,task_sel
	mov ds,ax
	mov ds,ds:thread_act
	mov ds:p_signal,0
;
	pop ax
	pop ds
	ret
clear_signal	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SIGNAL_THREAD
;
;		DESCRIPTION:	Send a signal to a thread
;
;		PARAMETERS:		BX			Thread to signal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_thread_name	DB 'Signal',0

signal_thread	PROC far
	push ds
	push es
	pushad
;
	mov ax,task_sel
	mov ds,ax
	or bx,bx
	jz find_signal_done
	mov es,bx
	cli
	mov es:p_signal,1
	mov si,OFFSET signal_list
	mov ax,[si]
	or ax,ax
	jz find_signal_done
	mov dx,ax
find_signal_loop:
	cmp dx,bx
	je find_signal_wake
	mov es,dx
	mov dx,es:p_next
	cmp dx,ax
	jne find_signal_loop
	jmp find_signal_done

find_signal_wake:
	mov [si],bx
	RemoveBlock
	mov di,es:p_prio
	InsertBlock
	cmp di,prio_act
	jbe find_signal_done
	mov prio_act,di
	call GetNextThread
	call UpdateTimer

find_signal_done:
	sti
	popad
	pop es
	pop ds
	ret
signal_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForSignal
;
;		DESCRIPTION:	Wait for a signal
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_signal_name	DB 'Wait For Signal',0

wait_for_signal	PROC far
	push ds
	push es
	pushad
;
	mov ax,task_sel
	mov ds,ax
	cli
	mov es,thread_act
	xor al,al
	xchg al,es:p_signal
	or al,al
	jnz wait_for_signal_done
;
	mov si,es:p_prio
	RemoveBlock
	mov di,OFFSET signal_list
	InsertBlock
	call GetNextThread
	call UpdateTimer
;
	mov ax,task_sel
	mov ds,ax
	mov es,thread_act
	mov es:p_signal,0
	
wait_for_signal_done:
	sti
;
	popad
	pop es
	pop ds
	ret
wait_for_signal	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			enter_section
;
;		DESCRIPTION:	Enter section
;
;		PARAMETERS:		DS:ESI		ADDRESS OF SECTION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_section_name	DB 'Enter Critical Section',0

enter_section	PROC far
	push ds
	push es
	push fs
	pushad
;
	mov ax,ds
	mov fs,ax
	mov ebx,esi
	mov ax,task_sel
	mov ds,ax
	cli
	cmp fs:[ebx].cs_list,-1
	jne enter_section_check_value
;
	mov fs:[ebx].cs_list,0
	jmp enter_section_done

enter_section_check_value:
	cmp fs:[ebx].cs_value,-1
	je enter_section_done

enter_section_block:
	push di
	mov es,thread_act
	mov si,es:p_prio
	RemoveBlock
;
	mov es:p_sleep_sel,fs
	mov es:p_sleep_offset,ebx
	add es:p_sleep_offset,OFFSET cs_list
	mov di,fs:[ebx].cs_list
	or di,di
	je enter_ins_empty
	mov ds,di
	mov si,ds:p_prev
	mov ds:p_prev,es
	mov ds,si
	mov ds:p_next,es
	mov es:p_next,di
	mov es:p_prev,si
	jmp enter_inserted
enter_ins_empty:
	mov es:p_next,es
	mov es:p_prev,es
	mov fs:[ebx].cs_list,es
enter_inserted:
	pop di
	mov ax,task_sel
	mov ds,ax
	call GetNextThread
	call UpdateTimer
enter_section_done:
	sti
	popad
	pop fs
	pop es
	pop ds
	retf32
enter_section	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			leave_section
;
;		DESCRIPTION:	Leave section
;
;		PARAMETERS:		DS:ESI		ADDRESS OF SECTION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_section_name	DB 'Leave Critical Section',0
 
leave_section	PROC far
	push ds
	push es
	push fs
	pushad
;
	mov ax,ds
	mov fs,ax
	mov ebx,esi
	mov ax,task_sel
	mov ds,ax
	cli
	mov ax,fs:[ebx].cs_list
	or ax,ax
	jnz leave_section_unblock
;
	mov fs:[ebx].cs_list,-1
	jmp leave_section_done

leave_section_unblock:
	mov es,ax
	mov di,es:p_prev
	cmp di,fs:[ebx].cs_list
	mov fs:[ebx].cs_list,di
	mov si,es:p_next
	mov ds,di
	mov ds:p_next,si
	mov ds,si
	mov ds:p_prev,di
	jne leave_section_empty
	mov word ptr fs:[ebx].cs_list,0
leave_section_empty:
	mov ax,task_sel
	mov ds,ax
	mov di,es:p_prio
	InsertBlock
	cmp di,prio_act
	jb leave_section_done
	mov prio_act,di
	xor ax,ax
	mov es,ax
	call GetNextThread
	call UpdateTimer
leave_section_done:
	sti
	popad
	pop fs
	pop es
	pop ds
	retf32
leave_section	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			leave_section_sleep
;
;		DESCRIPTION:	Leave section and sleep
;
;		PARAMETERS:		DS:ESI		ADDRESS OF SECTION
;						FS:EDI		SLEEP LIST
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_section_sleep_name	DB 'Leave Critical Section Sleep',0
 
leave_section_sleep	PROC far
	push ds
	push es
	push fs
	pushad
;
	push ds
	push esi
	mov cx,fs
	mov ax,task_sel
	mov ds,ax
	cli
	mov es,thread_act
	mov si,es:p_prio
	RemoveBlock
	mov ds,cx
	InsertBlock32
	pop ebx
	pop fs
	add fs:[ebx].cs_value,1
	jc leave_section_sleep_done
	mov ax,fs:[ebx].cs_list
	or ax,ax
	jz leave_section_sleep_done
	mov es,ax
	mov di,es:p_prev
	cmp di,fs:[ebx].cs_list
	mov fs:[ebx].cs_list,di
	mov si,es:p_next
	mov ds,di
	mov ds:p_next,si
	mov ds,si
	mov ds:p_prev,di
	jne leave_section_sleep_empty
	mov word ptr fs:[ebx].cs_list,0
leave_section_sleep_empty:
	mov ax,task_sel
	mov ds,ax
	mov di,es:p_prio
	InsertBlock
	cmp di,prio_act
	jb leave_section_sleep_done
	mov prio_act,di
leave_section_sleep_done:
	call GetNextThread
	call UpdateTimer
	sti
	popad
	pop fs
	pop es
	pop ds
	retf32
leave_section_sleep	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			get_thread
;
;		DESCRIPTION:	Get current thread control block
;
;		PARAMETERS:		AX		Thread
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public get_thread

get_thread	PROC far
	push ds
	mov ax,task_sel
	verr ax
	jz get_thread_norm
get_thread_pre_tasking:
	mov ax,virt_thread_sel
	jmp get_thread_done
get_thread_norm:
	mov ds,ax
	mov ax,thread_act
	verr ax
	jnz get_thread_pre_tasking
get_thread_done:
	pop ds
	ret
get_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetThread
;
;		DESCRIPTION:	Get current thread
;
;		PARAMETERS:		AX		Thread
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_thread_name	DB 'Get Thread',0

get_thread_pr	PROC far
	push ds
	mov ax,task_sel
	mov ds,ax
	mov ax,thread_act
	pop ds
	retf32
get_thread_pr	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetCpuTime
;
;		DESCRIPTION:	Get used CPU time
;
;		PARAMETERS:		BX		Thread
;		
;		RETURNS:		EDX:EAX		Used CPU time				
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cpu_time_name	DB 'Get CPU time',0

get_cpu_time	PROC far
	push ds
	mov ds,bx
	mov eax,ds:p_lsb_tics
	mov edx,ds:p_msb_tics
	pop ds
	retf32
get_cpu_time	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WAIT_UNTIL
;
;		DESCRIPTION:	Wait until time occurs.
;
;		PARAMETERS:		EDX:EAX		System time to wait until
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_until_name	DB 'Wait Until',0

wait_until	PROC far
	push ds
	push es
	pushad
;
	mov bx,task_sel
	mov ds,bx
	mov bx,cs
	mov es,bx
	mov di,OFFSET wake_until
	mov cx,thread_act
	xor bx,bx
	cli
	LocalStartTimer
	mov es,thread_act
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
	call GetNextThread
	call UpdateTimer
	sti
;
	popad
	pop es
	pop ds
	retf32
wait_until	ENDP

wake_until	PROC far
	mov ax,task_sel
	mov ds,ax
	mov es,cx
	cli
	mov di,es:p_prio
	InsertBlock
	cmp di,prio_act
	jbe wake_until_lower
	mov prio_act,di
	LocalGetSystemTime
	add eax,1193
	adc edx,0
	mov preempt_lsb,eax
	mov preempt_msb,edx
wake_until_lower:
	sti
	ret
wake_until	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WAIT_MILLI_SEC
;
;		DESCRIPTION:	Wait a number of ms
;
;		PARAMETERS:		AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_milli_name	DB 'Wait Milli Sec',0

wait_milli_sec	PROC far
	push ds
	push es
	pushad
;
	mov bx,task_sel
	mov ds,bx
	mov bx,1193
	mul bx
	push dx
	push ax
	pop ebx
	mov es,thread_act
	cli
	UpdateClock
	LocalGetSystemTime
	sti
	add eax,ebx
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET wake_until
	mov cx,thread_act
	xor bx,bx
	cli
	LocalStartTimer
	mov es,thread_act
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
	call GetNextThread
	call UpdateTimer
	sti
;
	popad
	pop es
	pop ds
	retf32
wait_milli_sec	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WAIT_MICRO_SEC
;
;		DESCRIPTION:	Wait a number of us
;
;		PARAMETERS:		AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_micro_name	DB 'Wait Micro Seconds',0

wait_micro_sec	PROC far
	push ds
	push es
	pushad
;
	mov bx,task_sel
	mov ds,bx
	movzx eax,ax
	mov ebx,78184
	mul ebx
	push dx
	push eax
	pop ax
	pop ebx
	mov es,thread_act
	cli
	UpdateClock
	LocalGetSystemTime
	sti
	add eax,ebx
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET wake_until
	mov cx,thread_act
	xor bx,bx
	cli
	LocalStartTimer
	mov es,thread_act
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
	call GetNextThread
	call UpdateTimer
	sti
;
	popad
	pop es
	pop ds
	retf32
wait_micro_sec	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CHECK_LIST
;
;		DESCRIPTION:	Check if thread is in list
;
;		PARAMETERS:		BX:EAX   	address of list
;						CX:EDX   	cs:eip
;						BX:EAX   	returned data to write
;						ES:EDI   	state string
;						NC	    	processed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Wait_state DB 'Wait',0
Ready_state DB 'Ready',0
Signal_state DB 'Signal',0
Debug_state DB 'Debug',0

check_list	Proc far
	cmp eax,1
	jnz check_not_wait
	mov ax,cs
	mov es,ax
	mov edi,OFFSET Wait_state
	xor eax,eax
	xor bx,bx
	clc
	ret
check_not_wait:
	cmp bx,task_sel
	jne check_not_task
	cmp eax,OFFSET signal_list
	jne check_not_signal
	mov ax,cs
	mov es,ax
	mov edi,OFFSET Signal_state
	xor eax,eax
	xor bx,bx
	clc
	ret
check_not_signal:
	mov ax,cs
	mov es,ax
	mov edi,OFFSET Ready_state
	mov bx,cx
	mov eax,edx
	clc
	ret
check_not_task:
	cmp bx,system_data_sel
	jne check_not_system
	cmp eax,OFFSET debug_list
	jne check_not_system
	mov ax,cs
	mov es,ax
	mov edi,OFFSET Debug_state
	mov bx,cx
	mov eax,edx
	clc
	ret
check_not_system:
	stc
	ret
check_list	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DebugBreak
;
;		DESCRIPTION:	Put thread in debug list
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_break_name	DB 'Debug Break',0

debug_break:
	test byte ptr [bp+2].vm_eflags,2
	jz debug_break_prot

debug_break_virt:
	int 46h

debug_break_prot:
	test byte ptr [bp].vm_cs,3
	jz debug_break_kernel
	int 45h

debug_break_kernel:
	add sp,8
	int 45h

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetSystemTime
;
;		DESCRIPTION:	Return system time.
;
;		PARAMETERS:		EDX:EAX		Binary time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_system_time_name	DB 'Get System Time',0

get_system_time	PROC far
	push ds
	push es
	mov ax,task_sel
	mov ds,ax
	mov es,thread_act
	cli
	UpdateClock
	LocalGetSystemTime
	sti
	pop es
	pop ds
	retf32
get_system_time	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetTime
;
;		DESCRIPTION:	Return user time
;
;		PARAMETERS:		EDX:EAX		Binary user time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_time_name	DB 'Get Time',0

get_time	PROC far
	push ds
	push es
	mov ax,task_sel
	mov ds,ax
	mov es,thread_act
	cli
	UpdateClock
	LocalGetSystemTime
	add eax,time_diff
	adc edx,time_diff+4
	sti
	pop es
	pop ds
	retf32
get_time	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			TimeToSystemTime
;
;		DESCRIPTION:	Converts real time to system time
;
;		PARAMETERS:		EDX:EAX		Real time
;
;		RETURNS:		EDX:EAX		System time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

time_to_system_time_name	DB 'Time To System Time',0

time_to_system_time	PROC far
	cli
	sub eax,time_diff
	sbb edx,time_diff+4
	sti
	retf32
time_to_system_time	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SystemTimeToTime
;
;		DESCRIPTION:	Converts system time to real time
;
;		PARAMETERS:		EDX:EAX		System time
;
;		RETURNS:		EDX:EAX		Real time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

system_time_to_time_name	DB 'System Time To Time',0

system_time_to_time	PROC far
	cli
	add eax,time_diff
	adc edx,time_diff+4
	sti
	retf32
system_time_to_time	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetSystemTime
;
;		DESCRIPTION:	Set system time. Must not be called after tasking is
;						started.
;
;		PARAMETERS:		EDX:EAX		Binary time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_system_time_name	DB 'Set System Time',0

set_system_time	PROC far
	push ds
	push bx
	mov bx,task_sel
	mov ds,bx
	mov system_time,eax
	mov system_time+4,edx
	pop bx
	pop ds
	ret
set_system_time	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdateTime
;
;		DESCRIPTION:	Sets difference between real time and system time
;
;		PARAMETERS:		EDX:EAX		Difference
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_time_name	DB 'Update Time',0

update_time	PROC far
	push ds
	push bx
	mov bx,task_sel
	mov ds,bx
	cli
	mov time_diff,eax
	mov time_diff+4,edx
	sti
	UpdateRtc
	pop bx
	pop ds
	ret
update_time	ENDP

code	ENDS

	END

