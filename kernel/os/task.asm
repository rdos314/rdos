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

INCLUDE kdebug.def
INCLUDE ..\driver.def
INCLUDE port.def
INCLUDE protseg.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE apic.inc
INCLUDE proc.inc

section_num	EQU 512

user_section	STRUC

ucs_value	DW ?
ucs_list	DW ?
ucs_owner	DW ?
ucs_count	DW ?

user_section	ENDS

section_to_offset	MACRO reg
	dec reg
	shl reg,3
	add reg,OFFSET section_list
					ENDM

offset_to_section	MACRO reg
	sub reg,OFFSET section_list
	shr reg,3
	inc reg
					ENDM

allocate_section	MACRO
	push ax
	mov bx,ds:section_free_list
	mov ax,[bx]
	mov ds:section_free_list,ax
	pop ax
				ENDM

free_section	MACRO
	push ax
	mov ax,ds:section_free_list
	mov [bx],ax
	mov ds:section_free_list,bx
	pop ax
			ENDM

section_proc_seg	STRUC

section_free_list		DW ?
section_list			DB 8 * section_num DUP(?)
section_handle_section	section_typ <>

section_proc_seg	ENDS

timer_struc	STRUC
timer_next		DW ?
timer_id		DW ?
timer_lsb		DD ?
timer_msb		DD ?
timer_offset	DW ?
timer_sel		DW ?
timer_owner		DW ?
timer_struc	ENDS

task_seg	STRUC

ptab			    DW 256 DUP(?)

prio_act		    DW ?

thread_act		    DW ?

timer_nesting	    DW ?

help_call_ip	    DW ?
help_call_cs	    DW ?

init_clock_proc     DW ?
update_clock_proc   DW ?
reload_timer_proc   DW ?

tsc_sub_tics        DD ?
tsc_guard           DD ?
last_tsc            DD ?

clock_tics		    DW ?
system_time		    DD ?,?
time_diff		    DD ?,?

apic_mul_tics       DD ?
apic_mul_rest       DW ?

update_tics		    DD ?

preempt_lsb		    DD ?
preempt_msb		    DD ?

signal_list		    DW ?
has_signal          DB ?

try_lock_proc       DW ?
lock_proc           DW ?
unlock_proc         DW ?

processor_count     DW ?
processor_arr       DW 256 DUP(?)

timer_head		    DW ?
timer_free		    DW ?
timer_entries	    DB 256 * SIZE timer_struc DUP(?)

task_seg_size	    DB ?

task_seg	ENDS

	.386p

LocalGetSystemTime	MACRO
	mov eax,ds:system_time
	mov edx,ds:system_time+4
					ENDM

LocalRemoveTimer	MACRO
	local timer_return

	cli
	mov bx,ds:timer_head
	mov ax,[bx].timer_next
	mov ds:timer_head,ax
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
	mov ax,ds:timer_free
	mov [bx].timer_next,ax
	mov ds:timer_free,bx
	sti
					ENDM

LocalStartTimer	MACRO
	LOCAL start_try_next
	LOCAL start_insert
	mov si,ds:timer_free
	mov [si].timer_owner,bx
	mov bx,[si].timer_next
	mov ds:timer_free,bx
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
	mov ax,ds:timer_free
	mov [bx].timer_next,ax
	mov ds:timer_free,bx
timer_stop_done:
				ENDM

GetPrioThread	MACRO
	LOCAL find_prio_lower
	LOCAL find_prio_loop
	LOCAL find_prio_done
	LOCAL find_prio_end
	mov si,ds:prio_act
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
	mov ds:prio_act,si
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

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitPitClock
;
;		DESCRIPTION:	Init clock using PIT timer 2
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPitClock	Proc near
    push ds
    push ax
;
    mov ax,task_sel
    mov ds,ax
;    
	mov al,0B4h
	out TIMER_CONTROL,al
	jmp short $+2
	mov al,0
	out TIMER2,al
	jmp short $+2
	out TIMER2,al
	mov ds:clock_tics,0
	jmp short $+2
	mov al,0Dh
	out 61h,al
;
    pop ax
    pop ds	
	ret
InitPitClock    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdatePitClock
;
;		DESCRIPTION:	Update clock using PIT timer 2
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePitClock	Proc near
	mov al,80h
	out TIMER_CONTROL,al
	jmp short $+2
	in al,TIMER2
	mov ah,al
	jmp short $+2
	in al,TIMER2
	xchg al,ah
	mov dx,ax
	xchg ax,ds:clock_tics
	sub ax,dx
	movzx eax,ax
	add ds:system_time,eax
	adc ds:system_time+4,0
	mov dx,ds:thread_act
	or dx,dx
	jz upcDone
;
    mov es,dx
	add es:p_lsb_tics,eax
	adc es:p_msb_tics,0

upcDone:
	ret
UpdatePitClock  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitTscClock
;
;		DESCRIPTION:	Init clock using TSC
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTscClock	Proc near
    push es
    pushad
;    
    mov ax,system_data_sel
    mov es,ax
    mov edx,10000h
    xor eax,eax
    mov ecx,es:tsc_tics
    shl ecx,16
    mov cx,es:tsc_rest
    div ecx
    mov ds:tsc_sub_tics,eax
;    
	rdtsc
	mov ds:last_tsc,eax
	mov ds:tsc_guard,0
;
    popad
    pop es	
	ret
InitTscClock    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdateTscClock
;
;		DESCRIPTION:	Update clock using TSC
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateTscClock	Proc near
    rdtsc
	mov edx,ds:last_tsc
	mov ds:last_tsc,eax
	sub eax,edx
	mul ds:tsc_sub_tics
	add ds:tsc_guard,eax
	pushf
	adc ds:system_time,edx
	adc ds:system_time+4,0
;
	mov ax,ds:thread_act
	or ax,ax
	jz utcNoThread
;
	popf
    mov es,ax
	adc es:p_lsb_tics,edx
	adc es:p_msb_tics,0
	jmp utcDone

utcNoThread:
    popf
	
utcDone:
	ret
UpdateTscClock  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetPitUpdateTics
;
;		DESCRIPTION:	Get PIT update tics
;
;		PARAMETERS:		DS      Task sel
;                       EAX     Drift in tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPitUpdateTics	Proc near
	mov ax,30h
	out TIMER_CONTROL,al
;
	mov ax,100h
	cli
	out TIMER0,al
	xchg ah,al
	jmp short $+2
	out TIMER0,al
	call ds:update_clock_proc
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
	mov ds:update_tics,eax
	mov ds:reload_timer_proc,OFFSET ReloadPitTimer
;
	in al,INT0_MASK
	and al,NOT 1
	out INT0_MASK,al
	ret
GetPitUpdateTics    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReloadPitTimer
;
;		DESCRIPTION:	Reload PIT timer
;
;		PARAMETERS:		DS      Task sel
;                       AX      Reload count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReloadPitTimer	Proc near
	out TIMER0,al
	xchg al,ah
	jmp short $+2
	out TIMER0,al
;
	in al,INT0_MASK
	and al,NOT 1
	out INT0_MASK,al
	ret
ReloadPitTimer  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetApicTics
;
;		DESCRIPTION:	Get parameters for APIC timer operation
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetApicTics	Proc near
    push es
    pushad
;    
    push ds
	mov ax,cs
	mov ds,ax
	mov al,40h
	mov bl,0
	mov esi,OFFSET apic_int 
	CreateIntGateSelector
	pop ds
;    
    mov ax,system_data_sel
    mov es,ax
    mov eax,es:apic_tics
    mov ds:apic_mul_tics,eax
    mov ax,es:apic_rest
    mov ds:apic_mul_rest,ax
;
    mov edx,10000h
    xor eax,eax
    mov ecx,es:apic_tics
    shl ecx,16
    mov cx,es:apic_rest
    div ecx
    mov esi,eax
;
	mov eax,80000000h
	cli
    mov bx,apic_mem_sel
    mov es,bx
    mov es:APIC_INIT_COUNT,eax    
    push esi
	call ds:update_clock_proc
	LocalGetSystemTime
	pop esi
    mov eax,es:APIC_CURR_COUNT    
	neg eax
	add eax,80000000h
	mul esi
	add eax,eax
	adc edx,edx
	add eax,80000000h
	adc edx,0
	mov ds:update_tics,edx
	mov ds:reload_timer_proc,OFFSET ReloadApicTimer
;
    mov eax,40h
    mov es:APIC_TIMER,eax
;
    popad
    pop es	
	ret
GetApicTics    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReloadApicTimer
;
;		DESCRIPTION:	Reload APIC timer
;
;		PARAMETERS:		DS      Task sel
;                       AX      Reload count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReloadApicTimer	Proc near
    mov ecx,ds:apic_mul_tics
    shl ecx,16
    mov cx,ds:apic_mul_rest
    shl eax,16
    mul ecx
    inc edx
    mov ax,apic_mem_sel
    mov es,ax    
    mov es:APIC_INIT_COUNT,edx
	ret
ReloadApicTimer  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			NotifyTimeDrift
;
;		DESCRIPTION:	Notification of time drift
;
;		PARAMETERS:		DS      System data sel
;                       EAX     Drift in tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_time_drift_name	DB 'Notify Time Drift',0

MAX_DRIFT = 250000

notify_time_drift	Proc far
    push es
    push eax
    push ecx
    push edx
;    
	mov cx,task_sel
	mov es,cx
;
    sub es:time_diff,eax
    sbb es:time_diff,0
;    
    mov ecx,ds:tsc_tics
    or ecx,ecx
    jz ntdPit
;
;    cmp eax,MAX_DRIFT
;    jge ntdSetPit
;
;    cmp eax,-MAX_DRIFT
;    jle ntdSetPit
;
    mov ecx,es:tsc_sub_tics
    shr ecx,3
    imul ecx
;
    mov ecx,1193182
    idiv ecx
;        
    sub es:tsc_sub_tics,eax
    jmp ntdDone

ntdSetPit:
    mov ds:tsc_tics,0
    and ds:cpu_feature_flags, NOT 10h
    call InitPitClock
	mov es:update_clock_proc,OFFSET UpdatePitClock
    jmp ntdDone

ntdPit:

ntdDone:
    pop edx
    pop ecx
    pop eax
    pop es
	ret
notify_time_drift  Endp

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
	extrn allocate_fixed_process_mem:near

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
	mov ds:try_lock_proc,OFFSET TryLockSingle
	mov ds:lock_proc,OFFSET LockSingle
	mov ds:unlock_proc,OFFSET UnlockSingle
	mov ds:timer_nesting,-1
	mov ds:signal_list,0
	mov ds:has_signal,0
	mov ds:help_call_ip,0
	mov ds:system_time,0
	mov ds:system_time+4,0
	mov ds:time_diff,0
	mov ds:time_diff+4,0
	mov bx,OFFSET ptab
	mov ds:prio_act,bx
;
	mov cx,256
ptab_init:
	mov word ptr [bx],0
	add bx,2
	loop ptab_init
;
	mov bx,OFFSET processor_arr
	mov ds:processor_count,0
;
	mov cx,256
proc_init:
	mov word ptr [bx],0
	add bx,2
	loop proc_init
;
	mov bx,OFFSET timer_entries
	mov [bx].timer_next,0
	mov [bx].timer_msb,0FFFFFFFFh
	mov [bx].timer_lsb,0FFFFFFFFh
	mov ds:timer_head,bx
;	
	mov cx,0FFh
	add bx,SIZE timer_struc
	mov ds:timer_free,bx
timer_free_list_create:
	mov ax,bx
	add ax,SIZE timer_struc
	mov [bx].timer_next,ax
	mov bx,ax
	loop timer_free_list_create
;
	mov ds:thread_act,0
;
	mov eax,SIZE section_proc_seg
	mov bx,section_proc_sel
	push cs
	call allocate_fixed_process_mem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET test_gate
	mov di,OFFSET test_gate_name
	xor cl,cl
	mov ax,test_nr
	RegisterOsGate
;
	mov si,OFFSET create_processor
	mov di,OFFSET create_processor_name
	xor cl,cl
	mov ax,create_processor_nr
	RegisterOsGate
;
	mov si,OFFSET enter_int
	mov di,OFFSET enter_int_name
	xor cl,cl
	mov ax,enter_int_nr
	RegisterOsGate
;
	mov si,OFFSET leave_int
	mov di,OFFSET leave_int_name
	xor cl,cl
	mov ax,leave_int_nr
	RegisterOsGate
;
	mov si,OFFSET debug_exception
	mov di,OFFSET debug_exception_name
	xor cl,cl
	mov ax,debug_exception_nr
	RegisterOsGate
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
	mov si,OFFSET wait_for_signal_timeout
	mov di,OFFSET wait_for_signal_timeout_name
	xor cl,cl
	mov ax,wait_for_signal_timeout_nr
	RegisterOsGate
;
	mov si,OFFSET cpu_reset
	mov di,OFFSET cpu_reset_name
	xor dx,dx
	mov ax,cpu_reset_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_thread_pr
	mov di,OFFSET get_thread_name
	xor dx,dx
	mov ax,get_thread_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_processor
	mov di,OFFSET get_processor_name
	xor dx,dx
	mov ax,get_processor_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_cpu_time
	mov di,OFFSET get_cpu_time_name
	xor dx,dx
	mov ax,get_cpu_time_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET change_enviroment
	mov di,OFFSET change_enviroment_name
	xor cl,cl
	mov ax,change_enviroment_nr
	RegisterOsGate
;
	mov si,OFFSET swap_out
	mov di,OFFSET swap_name
	xor dx,dx
	mov ax,swap_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET wait_milli_sec
	mov di,OFFSET wait_milli_name
	xor dx,dx
	mov ax,wait_milli_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET wait_micro_sec
	mov di,OFFSET wait_micro_name
	xor dx,dx
	mov ax,wait_micro_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET wait_until
	mov di,OFFSET wait_until_name
	xor dx,dx
	mov ax,wait_until_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET notify_time_drift
	mov di,OFFSET notify_time_drift_name
	xor cl,cl
	mov ax,notify_time_drift_nr
	RegisterOsGate
;
	mov si,OFFSET get_system_time
	mov di,OFFSET get_system_time_name
	xor dx,dx
	mov ax,get_system_time_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_time
	mov di,OFFSET get_time_name
	xor dx,dx
	mov ax,get_time_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET time_to_system_time
	mov di,OFFSET time_to_system_time_name
	xor dx,dx
	mov ax,time_to_system_time_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET system_time_to_time
	mov di,OFFSET system_time_to_time_name
	xor dx,dx
	mov ax,system_time_to_time_nr
	RegisterBimodalUserGate
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
	RegisterOsGate
;
	mov si,OFFSET leave_section
	mov di,OFFSET leave_section_name
	xor cl,cl
	mov ax,leave_section_nr
	RegisterOsGate
;
	mov si,OFFSET create_user_section
	mov di,OFFSET create_user_section_name
	xor dx,dx
	mov ax,create_user_section_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET create_blocked_user_section
	mov di,OFFSET create_blocked_user_section_name
	xor dx,dx
	mov ax,create_blocked_user_section_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET delete_user_section
	mov di,OFFSET delete_user_section_name
	xor dx,dx
	mov ax,delete_user_section_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET enter_user_section
	mov di,OFFSET enter_user_section_name
	xor dx,dx
	mov ax,enter_user_section_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET leave_user_section
	mov di,OFFSET leave_user_section_name
	xor dx,dx
	mov ax,leave_user_section_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET get_debug_thread16
	mov si,OFFSET get_debug_thread32
	mov di,OFFSET get_debug_thread_name
	xor dx,dx
	mov ax,get_debug_thread_nr
	RegisterUserGate
;
	mov bx,OFFSET get_debug_tss16
	mov si,OFFSET get_debug_tss32
	mov di,OFFSET get_debug_tss_name
	mov dx,virt_es_in
	mov ax,get_debug_tss_nr
	RegisterUserGate
;
	mov si,OFFSET debug_trace
	mov di,OFFSET debug_trace_name
	xor dx,dx
	mov ax,debug_trace_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET debug_pace
	mov di,OFFSET debug_pace_name
	xor dx,dx
	mov ax,debug_pace_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET debug_go
	mov di,OFFSET debug_go_name
	xor dx,dx
	mov ax,debug_go_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET debug_next
	mov di,OFFSET debug_next_name
	xor dx,dx
	mov ax,debug_next_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET update_time
	mov di,OFFSET update_time_name
	xor cl,cl
	mov ax,update_time_nr
	RegisterBimodalUserGate
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
	and dl,0FEh
	cmp dl,0D6h
	jne debug_pace_step
	add bx,3
	jmp debug_pace_step
debug_pace_not_gate:
	cmp al,9Ah
	je debug_pace_step
	inc bx
	cmp ax,9A66h
	jne debug_pace_trace
;
    add bx,2
    
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
	mov si,ds:prio_act
	RemoveBlock              
	push ds  
	mov ds,ax
	mov di,OFFSET ms_wait_sti
	InsertBlock
	pop ds
	jmp get_next_int_loop
get_next_int_ok:
	call ds:update_clock_proc
	LocalGetSystemTime
	add eax,1193
	adc edx,0
	mov ds:preempt_lsb,eax
	mov ds:preempt_msb,edx
	pop es
	ret
GetNextThread	Endp


PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			LoadCurrentThread
;
;		DESCRIPTION:	Load register-state for current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadCurrentThread:
	mov ax,task_sel
	mov ds,ax

load_timer_loop:
	cli
	call ds:update_clock_proc
	LocalGetSystemTime
	add eax,ds:update_tics
	adc edx,0
	mov bx,ds:timer_head
	mov ecx,ds:preempt_msb
	cmp ecx,[bx].timer_msb
	jc load_check_preempt
	jnz load_check_timer
;	
	mov ecx,ds:preempt_lsb
	cmp ecx,[bx].timer_lsb
	jc load_check_preempt

load_check_timer:
	sub eax,[bx].timer_lsb
	sbb edx,[bx].timer_msb
	jc load_reload_timer
;	
	LocalRemoveTimer
	jmp load_timer_loop

load_check_preempt:
	sub eax,ds:preempt_lsb
	sbb edx,ds:preempt_msb
	jc load_reload_timer
;
    mov eax,-1	

load_reload_timer:
	neg eax
	call ds:reload_timer_proc
;
	mov si,ds:prio_act
	mov ax,[si]
	cmp ax,ds:thread_act
	je load_do
;
	call ds:update_clock_proc
	LocalGetSystemTime
	add eax,1193
	adc edx,0
	mov ds:preempt_lsb,eax
	mov ds:preempt_msb,edx

load_do:
	mov si,ds:prio_act
	mov es,[si]
	mov ds:thread_act,es
;	
	mov ax,gdt_sel
	mov ds,ax
	mov bx,es:p_tss_sel
	and byte ptr ds:[bx+5],NOT 2
	ltr bx
;	
	mov ax,task_sel
	mov ds,ax
	SetEnviroment
    mov ds,es:p_tss_data_sel
;
    mov eax,cr0
    or al,8
    mov cr0,eax    
;
    lldt ds:tss_ldt
;    
    test dword ptr ds:tss_eflags,20000h
    jnz load_vm
;
    test word ptr ds:tss_cs,3
    jnz load_pm_app

load_kernel:
    mov ax,word ptr ds:tss_ss
    mov ss,ax
    mov esp,dword ptr ds:tss_esp
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;	
    mov ecx,dword ptr ds:tss_ecx
    mov edx,dword ptr ds:tss_edx
    mov ebx,dword ptr ds:tss_ebx
    mov ebp,dword ptr ds:tss_ebp
    mov esi,dword ptr ds:tss_esi
    mov edi,dword ptr ds:tss_edi
;
    mov ax,word ptr ds:tss_es
	verr ax
	jz load_kernel_es
;
	xor ax,ax
	
load_kernel_es:
	mov es,ax
;	
    mov ax,word ptr ds:tss_fs
	verr ax
	jz load_kernel_fs
;
	xor ax,ax
	
load_kernel_fs:
	mov fs,ax
;	
    mov ax,word ptr ds:tss_gs
	verr ax
	jz load_kernel_gs
;
	xor ax,ax
	
load_kernel_gs:
	mov gs,ax
;	
    mov ax,word ptr ds:tss_ds
	verr ax
	jz load_kernel_ds
;
	xor ax,ax
	
load_kernel_ds:
    test ds:tss_t,1
    pushf
    push ax
    push dword ptr ds:tss_eax
;
    mov ax,task_sel
    mov ds,ax
    call ds:unlock_proc
;    
    pop eax
    pop ds
    popf
    jz load_kernel_t_ok
;    
	push dword ptr 0
	push bp
	mov bp,sp
	push eax
	push ebx
	push ds
	mov ax,thread_tss_sel
	mov ds,ax
	mov ds:tss_t,0
	mov ax,thread_sel
	mov ds,ax
	call dword ptr ds:p_trap_ads
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4

load_kernel_t_ok:
    iretd

load_pm_app:    
    mov ax,word ptr ds:tss_ess0
    mov ss,ax
    mov esp,dword ptr ds:tss_esp0
;
    push dword ptr ds:tss_ss
    push dword ptr ds:tss_esp
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;	
    mov ecx,dword ptr ds:tss_ecx
    mov edx,dword ptr ds:tss_edx
    mov ebx,dword ptr ds:tss_ebx
    mov ebp,dword ptr ds:tss_ebp
    mov esi,dword ptr ds:tss_esi
    mov edi,dword ptr ds:tss_edi
;
    mov ax,word ptr ds:tss_es
	verr ax
	jz load_pm_app_es
;
	xor ax,ax
	
load_pm_app_es:
	mov es,ax
;	
    mov ax,word ptr ds:tss_fs
	verr ax
	jz load_pm_app_fs
;
	xor ax,ax
	
load_pm_app_fs:
	mov fs,ax
;	
    mov ax,word ptr ds:tss_gs
	verr ax
	jz load_pm_app_gs
;
	xor ax,ax
	
load_pm_app_gs:
	mov gs,ax
;	
    mov ax,word ptr ds:tss_ds
	verr ax
	jz load_pm_app_ds
;
	xor ax,ax
	
load_pm_app_ds:
    test ds:tss_t,1
    pushf
    push ax
    push dword ptr ds:tss_eax
;    
    mov ax,task_sel
    mov ds,ax
    call ds:unlock_proc
;    
    pop eax
    pop ds
    popf
    jz load_pm_t_ok
;    
	push dword ptr 0
	push bp
	mov bp,sp
	push eax
	push ebx
	push ds
	mov ax,thread_tss_sel
	mov ds,ax
	mov ds:tss_t,0
	mov ax,thread_sel
	mov ds,ax
	call dword ptr ds:p_trap_ads
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4

load_pm_t_ok:
    iretd

load_vm:
    mov ax,word ptr ds:tss_ess0
    mov ss,ax
    mov esp,dword ptr ds:tss_esp0
;
    push dword ptr ds:tss_gs
    push dword ptr ds:tss_fs
    push dword ptr ds:tss_ds
    push dword ptr ds:tss_es
    push dword ptr ds:tss_ss
    push dword ptr ds:tss_esp
    push dword ptr ds:tss_eflags
    push dword ptr ds:tss_cs
    push dword ptr ds:tss_eip
;
    mov eax,dword ptr ds:tss_eax
    mov ecx,dword ptr ds:tss_ecx
    mov edx,dword ptr ds:tss_edx
    mov ebx,dword ptr ds:tss_ebx
    mov ebp,dword ptr ds:tss_ebp
    mov esi,dword ptr ds:tss_esi
    mov edi,dword ptr ds:tss_edi
;
    test ds:tss_t,1
    jz load_vm_t_ok
;    
	push dword ptr 0
	push bp
	mov bp,sp
	push eax
	push ebx
	push ds
	mov ds:tss_t,0
	mov ax,thread_sel
	mov ds,ax
	call dword ptr ds:p_trap_ads
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4

load_vm_t_ok:
    push ax
    mov ax,task_sel
    mov ds,ax
    call ds:unlock_proc
    pop ax
    iretd

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdatePreempt
;
;		DESCRIPTION:	Update preemption
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePreempt	Proc near
	cli
	add ds:timer_nesting,1
	jnc update_preempt_done
;
	call ds:update_clock_proc
	LocalGetSystemTime
	add eax,1193 / 4
	adc edx,0
	sub eax,ds:preempt_lsb
	sbb edx,ds:preempt_msb
	jc update_preempt_done
;	
	sti
	nop
	cli
	call GetNextThread
	sti

update_preempt_done:
    dec ds:timer_nesting
    ret
UpdatePreempt   Endp

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
	add ds:timer_nesting,1
	jnc update_timer_done
;	
    mov ax,ds:thread_act
    or ax,ax
    jz update_timer_load
;
    mov es,ax    
    mov ds,es:p_tss_data_sel
    mov dword ptr ds:tss_eip,OFFSET update_timer_done
    pushfd
    pop dword ptr ds:tss_eflags
    mov dword ptr ds:tss_eax,eax
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_edx,edx
    mov dword ptr ds:tss_ebx,ebx
    mov dword ptr ds:tss_esp,esp
    mov dword ptr ds:tss_ebp,ebp
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov word ptr ds:tss_es,es
    mov word ptr ds:tss_cs,cs
    mov word ptr ds:tss_ss,ss
    mov word ptr ds:tss_ds,ds
    mov word ptr ds:tss_fs,fs
    mov word ptr ds:tss_gs,gs
	mov ax,task_sel
	mov ds,ax

update_timer_load:
    jmp LoadCurrentThread

update_timer_done:
    dec ds:timer_nesting
	ret
UpdateTimer	Endp
	
PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveCurrentThread
;
;		DESCRIPTION:	Save state of current thread
;
;       PARAMETERS:     Stack, return IP
;
;       RETURNS:        SS:SP       Processor stack
;                       DS          Task sel
;                       FS          Processor selector
;                       ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveCurrentThread	Proc near	
    push ds
    push ax
;
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
;        
    mov ds,ds:thread_act
    mov ds,ds:p_tss_data_sel
    pushfd
    pop dword ptr ds:tss_eflags
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_edx,edx
    mov dword ptr ds:tss_ebx,ebx
    mov dword ptr ds:tss_ebp,ebp
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov word ptr ds:tss_es,es
    mov word ptr ds:tss_cs,cs
    mov word ptr ds:tss_ss,ss
    mov word ptr ds:tss_fs,fs
    mov word ptr ds:tss_gs,gs
;
    pop ax
    mov dword ptr ds:tss_eax,eax
;
    pop word ptr ds:tss_ds
    pop bp
    pop dx
    movzx edx,dx
    mov dword ptr ds:tss_eip,edx
    mov dword ptr ds:tss_esp,esp
    mov edx,dword ptr ds:tss_edx
;
    push ax
    push bx
    mov ax,task_sel
    mov ds,ax
    GetProcessorNr
    mov bx,ax
    add bx,bx
    mov fs,ds:[bx].processor_arr
    pop bx
    pop ax
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
    push bp
;
    xor bp,bp
    mov es,bp
    mov gs,bp    
    ret
SaveCurrentThread   Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveLockedThread
;
;		DESCRIPTION:	Save state of current thread when lock is already taken
;
;       PARAMETERS:     Stack, return IP
;
;       RETURNS:        SS:SP       Processor stack
;                       DS          Task sel
;                       FS          Processor selector
;                       ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveLockedThread	Proc near	
    push ds
    push ax
;
    mov ax,task_sel
    mov ds,ax
;        
    mov ds,ds:thread_act
    mov ds,ds:p_tss_data_sel
    pushfd
    pop dword ptr ds:tss_eflags
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_edx,edx
    mov dword ptr ds:tss_ebx,ebx
    mov dword ptr ds:tss_ebp,ebp
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
    mov word ptr ds:tss_es,es
    mov word ptr ds:tss_cs,cs
    mov word ptr ds:tss_ss,ss
    mov word ptr ds:tss_fs,fs
    mov word ptr ds:tss_gs,gs
;
    pop ax
    mov dword ptr ds:tss_eax,eax
;
    pop word ptr ds:tss_ds
    pop bp
    pop dx
    movzx edx,dx
    mov dword ptr ds:tss_eip,edx
    mov dword ptr ds:tss_esp,esp
    mov edx,dword ptr ds:tss_edx
;
    push ax
    push bx
    mov ax,task_sel
    mov ds,ax
    GetProcessorNr
    mov bx,ax
    add bx,bx
    mov fs,ds:[bx].processor_arr
    pop bx
    pop ax
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
    push bp
;
    xor bp,bp
    mov es,bp
    mov gs,bp    
    ret
SaveLockedThread   Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SkipCurrentThread
;
;		DESCRIPTION:	Skip current thread (no save of registers)
;
;       RETURNS:        SS:SP       Processor stack
;                       DS          Task sel
;                       FS          Processor selector
;                       ES, GS      Clear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SkipCurrentThread	Proc near	
    push ax
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
    pop ax
;    
    pop bp
;
    push ax
    push bx
    mov ax,task_sel
    mov ds,ax
    GetProcessorNr
    mov bx,ax
    add bx,bx
    mov fs,ds:[bx].processor_arr	
    pop bx
    pop ax
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
    push bp
;
    xor bp,bp
    mov es,bp
    mov gs,bp    
    ret
SkipCurrentThread   Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DebugException
;
;		DESCRIPTION:	Save current state from stack + local registers
;
;       PARAMETERS:     SS:BP       Exception stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

debug_exception_name    DB 'Debug Exception', 0

debug_exception:
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
;        
    mov ds,ds:thread_act
    mov ds,ds:p_tss_data_sel
;
	mov eax,[bp].vm_eax
	mov dword ptr ds:tss_eax,eax
	mov eax,[bp].vm_ebx
	mov dword ptr ds:tss_ebx,eax
    mov dword ptr ds:tss_ecx,ecx
    mov dword ptr ds:tss_edx,edx
    mov dword ptr ds:tss_esi,esi
    mov dword ptr ds:tss_edi,edi
	mov eax,ebp
	mov ax,[bp]
	mov dword ptr ds:tss_ebp,eax
;	
	mov eax,[bp].vm_eflags
	mov dword ptr ds:tss_eflags,eax
	mov ax,[bp].vm_cs
	mov ds:tss_cs,ax
	mov eax,[bp].vm_eip
	mov dword ptr ds:tss_eip,eax
;	
    test dword ptr [bp].vm_eflags,20000h
    jnz debug_vm

debug_pm:
	mov al,[bp].vm_cs
	test al,3
	jz debug_kernel
;
	mov ax,[bp].vm_ss
	mov ds:tss_ss,ax
	mov eax,[bp].vm_esp
	mov dword ptr ds:tss_esp,eax
	jmp debug_pm_common
	
debug_kernel:
    mov ax,ss
    mov ds:tss_ss,ax
    mov ax,bp
    add ax,vm_esp
    movzx eax,ax
	mov dword ptr ds:tss_esp,eax
	
debug_pm_common:
	mov ax,[bp].pm_ds
	mov ds:tss_ds,ax
	mov ax,es
	mov ds:tss_es,ax
	mov ax,fs
	mov ds:tss_fs,ax
	mov ax,gs
	mov ds:tss_gs,ax
	jmp debug_save_ok

debug_vm:
	mov ax,[bp].vm_gs
	mov ds:tss_gs,ax
	mov ax,[bp].vm_fs
	mov ds:tss_fs,ax
	mov ax,[bp].vm_ds
	mov ds:tss_ds,ax
	mov ax,[bp].vm_es
	mov ds:tss_es,ax
	mov ax,[bp].vm_ss
	mov ds:tss_ss,ax
	mov eax,[bp].vm_esp
	mov dword ptr ds:tss_esp,eax

debug_save_ok:
    movzx dx,byte ptr [bp].vm_err+2
    mov ax,task_sel
    mov ds,ax
    GetProcessorNr
    mov bx,ax
    add bx,bx
    mov fs,ds:[bx].processor_arr
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
;
    xor ax,ax
    mov es,ax
    mov gs,ax    
;
	mov es,ds:thread_act
	mov es:p_error_code,dx
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
;
	mov ax,system_data_sel
	mov ds,ax
	mov di,OFFSET debug_list	
	InsertBlock
;	
    mov ax,task_sel
    mov ds,ax
	call GetNextThread
    jmp LoadCurrentThread

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DoubleFault
;
;		DESCRIPTION:	Handle double fault exception (from task-gate)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public double_fault
    
double_fault:
    pushf
    pop ax
    and ax,NOT 4000h
    push ax
    popf
;	
	mov ax,gdt_sel
	mov ds,ax
	mov bx,double_tss_sel
	and byte ptr ds:[bx+5],NOT 2
;    
    mov ax,task_sel
    mov ds,ax
    call ds:lock_proc
;	
    mov ax,task_sel
    mov ds,ax
    GetProcessorNr
    mov bx,ax
    add bx,bx
    mov fs,ds:[bx].processor_arr
;    
    mov ss,fs:ps_ss
    mov sp,fs:ps_sp
;
    xor ax,ax
    mov es,ax
    mov gs,ax    
;
	mov es,ds:thread_act
	mov es:p_error_code,8
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
;
	mov ax,system_data_sel
	mov ds,ax
	mov di,OFFSET debug_list	
	InsertBlock
;	
    mov ax,task_sel
    mov ds,ax
	call GetNextThread
    jmp LoadCurrentThread

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TestGate
;
;		DESCRIPTION:	Test gate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

test_gate_name	DB 'Test Gate',0

test_gate	Proc far
    int 3
    push OFFSET test_gate_done
    call SaveCurrentThread
;
	mov bx,1193
	mul bx
	push dx
	push ax
	pop ebx
	mov es,ds:thread_act
	cli
	call ds:update_clock_proc
	LocalGetSystemTime
	sti
	add eax,ebx
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET wake_until
	mov cx,ds:thread_act
	xor bx,bx
	cli
	LocalStartTimer
	mov es,ds:thread_act
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
	call GetNextThread
    jmp LoadCurrentThread

test_gate_done:
    int 3
    ret
test_gate   Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateProcessor
;
;		DESCRIPTION:	Create processor
;
;       RETURNS:        AX      Processor #
;                       ES      Processor sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_processor_name	DB 'Create Processor',0

create_processor	Proc far
    push ds
    push si
;    
    mov eax,SIZE processor_seg
    AllocateSmallGlobalMem
;
    push es
    mov eax,200h    
    AllocateSmallGlobalMem
    mov ax,es
    pop es
    mov es:ps_ss,ax
    mov es:ps_sp,200h
;
	mov ax,task_sel
	mov ds,ax
	mov ax,ds:processor_count
	mov si,ax
	add si,si
	mov [si].processor_arr,es
	inc ds:processor_count
;
    mov es:ps_id,ax	
    mov es:ps_cr3,0
;
    pop si
    pop ds	
	ret
create_processor	Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TryLockSingle
;
;		DESCRIPTION:	Try t lock, single processor version
;
;       PARAMETERS:     DS      Task_sel
;
;       RETURNS:        CY      Owner of section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TryLockSingle	Proc near
	add ds:timer_nesting,1
	ret
TryLockSingle	Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LockSingle
;
;		DESCRIPTION:	Lock, single processor version
;
;       PARAMETERS:     DS      Task_sel
;
;       RETURNS:        CY      Owner of section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockSingle	Proc near
	add ds:timer_nesting,1
	ret
LockSingle	Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UnlockSingle
;
;		DESCRIPTION:	Unlock, single processor version
;
;       PARAMETERS:     DS      Task_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


UnlockSingle	Proc near
    push es
    push ax

usRetry:    
    sub ds:timer_nesting,1
	jnc usDone
;	
    mov al,ds:has_signal
    or al,al
    jz usNoSignal
;
    add ds:timer_nesting,1
    jnc usRetry
;
    push OFFSET usDone
    call SaveLockedThread
;    
    mov es,ds:thread_act
    mov ax,ds:prio_act
    cmp ax,es:p_prio
    jbe usSigPrioOk
;
    cli
    call GetNextThread

usSigPrioOk:
    mov ds:has_signal,0
    cli
	mov si,OFFSET signal_list
	mov ax,[si]
	or ax,ax
	jz usSignalDone
;	
	mov dx,ax

usSignalLoop:
	mov es,dx
	mov cl,es:p_signal
	or cl,cl
	jz usSignalNext
;
	mov [si],dx
	RemoveBlock
	mov di,es:p_prio
	InsertBlock
	cmp di,ds:prio_act
	jbe usSignalPrioOk
;	
	mov ds:prio_act,di
	call GetNextThread

usSignalPrioOk:
	mov si,OFFSET signal_list
    mov ax,[si]
	or ax,ax
	jz usSignalDone
;	
    mov dx,ax
    jmp usSignalLoop

usSignalNext:	
	mov dx,es:p_next
	cmp dx,ax
	jne usSignalLoop

usSignalDone:
    jmp LoadCurrentThread

usNoSignal:
    mov es,ds:thread_act
    mov ax,ds:prio_act
    cmp ax,es:p_prio
    jbe usDone
;
    push OFFSET usDone
    call SaveCurrentThread
    cli
    call GetNextThread
    jmp LoadCurrentThread

usDone:
    pop ax
    pop es
	ret
UnlockSingle	Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EnterInt
;
;		DESCRIPTION:	Enter interrupt notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_int_name	DB 'Enter Int',0

enter_int	Proc far
	mov ax,task_sel
	mov ds,ax
	call ds:lock_proc
	ret
enter_int	Endp

PAGE	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LeaveInt
;
;		DESCRIPTION:	Leave interrupt notification
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_int_name	DB 'Leave Int',0

leave_int	Proc far
	mov ax,task_sel
	mov ds,ax
	call ds:unlock_proc
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
	call UpdatePreempt
	call UpdateTimer
;
	popad
	pop es
	pop ds
	iretd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			apic_int
;
;		DESCRIPTION:	APIC int
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

apic_int:
	push ds
	push es
	pushad
;
    mov ax,apic_mem_sel
    mov ds,ax
    xor eax,eax
    mov ds:APIC_EOI,eax	
;
	mov ax,task_sel
	mov ds,ax
	call UpdatePreempt
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

init_first_thread:
	mov ax,task_sel
	mov ds,ax
	call ds:lock_proc
	mov di,es:p_prio
	mov ds:prio_act,di
	InsertBlock
;
    mov ax,system_data_sel
    mov es,ax
	mov ds:update_tics,0
	mov ds:init_clock_proc,OFFSET InitPitClock
	mov ds:update_clock_proc,OFFSET UpdatePitClock
    mov eax,es:tsc_tics
    or eax,eax
    jz timer_clock_done
;
	mov ds:init_clock_proc,OFFSET InitTscClock
	mov ds:update_clock_proc,OFFSET UpdateTscClock

timer_clock_done:
    test es:cpu_feature_flags,200h
    jz init_use_pit_timer

init_use_apic_timer:
    call GetApicTics
    jmp init_timer_sel_ok

init_use_pit_timer:
    call GetPitUpdateTics

init_timer_sel_ok:
    call ds:init_clock_proc
;
	call GetNextThread
	jmp LoadCurrentThread

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
;		NAME:			WAKE_NEW
;
;		DESCRIPTION:	Wake-up a newly create thread
;
;		PARAMETERS:		ES			Thread
;												
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public wake_new

wake_new	PROC near
    mov dx,es
    push OFFSET wake_new_done
    call SaveCurrentThread
;
    mov es,dx
	cli
	mov di,es:p_prio
	InsertBlock
	cmp di,ds:prio_act
	jb wake_new_lower
;	
	mov ds:prio_act,di
	call GetNextThread

wake_new_lower:
    jmp LoadCurrentThread

wake_new_done:
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
    push OFFSET swap_out_done
    call SaveCurrentThread
;
	cli
	call GetNextThread
    jmp LoadCurrentThread

swap_out_done:
	retf32
swap_out	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CleanupThread
;
;		DESCRIPTION:	Free resources for current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public cleanup_thread
    
cleanup_thread:
    call SkipCurrentThread
;    
    cli	
	mov es,ds:thread_act
	mov si,es:p_prio
	RemoveBlock
	push es
;
	call GetNextThread
;
	mov si,ds:prio_act
	mov es,[si]
	mov ds:thread_act,es
;	
	mov ax,gdt_sel
	mov ds,ax
	mov bx,es:p_tss_sel
	and byte ptr ds:[bx+5],NOT 2
	ltr bx
;
	SetEnviroment
    mov ds,es:p_tss_data_sel
;
    lldt ds:tss_ldt
;
	pop es
	sti
;
	push es
	mov es,es:p_tss_data_sel
	mov es,es:tss_ess0
	FreeMem
	pop es
;
	mov bx,es:p_tss_data_sel
	FreeGdt
;
	mov bx,es:p_tss_sel
	FreeGdt
;
	FreeMem
    jmp LoadCurrentThread

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CleanupProcess
;
;		DESCRIPTION:	Free resources for current process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public cleanup_process
    
cleanup_process:
    call SkipCurrentThread
;    
    cli	
	mov es,ds:thread_act
	mov si,es:p_prio
	RemoveBlock
	push es
;
	call GetNextThread
;
	mov si,ds:prio_act
	mov es,[si]
	mov ds:thread_act,es
;	
	mov ax,gdt_sel
	mov ds,ax
	mov bx,es:p_tss_sel
	and byte ptr ds:[bx+5],NOT 2
	ltr bx
;
	SetEnviroment
    mov ds,es:p_tss_data_sel
;
    lldt ds:tss_ldt
;
	pop es
	sti
	mov ax,es:p_process_sel
	push es
	mov es,ax
	FreeMem
	pop es
;
	mov bx,es
	mov ax,process_dir_sel
	mov ds,ax
	mov si,alias_linear SHR 20
	mov eax,es:p_cr3
	mov [si],eax
	mov eax,cr3
	mov cr3,eax
;
    mov ax,flat_sel
    mov ds,ax
	mov cx,400h
	mov edx,alias_linear + (handle_linear SHR 10)

cleanup_process_linear_loop:
	mov eax,[edx]
	test al,1
	jz cleanup_process_linear_next
;
	FreePhysical

cleanup_process_linear_next:
	add edx,4
	loop cleanup_process_linear_loop
;
	mov ax,process_page_sel
	mov ds,ax
	mov edx,(alias_linear + (handle_linear SHR 10)) SHR 10
	mov eax,[edx]
	FreePhysical
;
	mov eax,es:p_cr3
	FreePhysical
;
	push es
	mov es,es:p_tss_data_sel
	mov es,es:tss_ess0
	FreeMem
	pop es
;
	mov bx,es:p_tss_data_sel
	FreeGdt
;
	mov bx,es:p_tss_sel
	FreeGdt
;
	FreeMem
    jmp LoadCurrentThread

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
    push dx
    mov dx,ds
    push OFFSET wake_done
    call SaveCurrentThread
;
    mov ds,dx
	cli
	mov di,[si]
	or di,di
	jz wake_reload
;	
	RemoveBlock
	mov di,task_sel
	mov ds,di
	mov di,es:p_prio
	mov es:p_data,eax
	InsertBlock
	cmp di,ds:prio_act
	jb wake_reload
;	
	mov ds:prio_act,di
	call GetNextThread

wake_reload:
    jmp LoadCurrentThread
	
wake_done:
    pop dx
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
    mov ax,ds
;
    push OFFSET sleep_thread_done
    call SaveCurrentThread
;
	mov cx,ax
	mov ax,task_sel
	mov ds,ax
	cli
	mov es,ds:thread_act
	mov si,es:p_prio
	RemoveBlock
	mov ds,cx
	InsertBlock
	mov ax,task_sel
	mov ds,ax
	call GetNextThread
    jmp LoadCurrentThread

sleep_thread_done:
	mov ax,task_sel
	mov ds,ax
	mov es,ds:thread_act
	mov eax,es:p_data
	pop es
	pop ds
	ret
sleep_thread	ENDP

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
    push ax
;
    or bx,bx
    jz signal_done
;    
	mov ax,task_sel
	mov ds,ax
	call ds:try_lock_proc
;
    mov es,bx
    mov es:p_signal,1
    mov ds:has_signal,1
;
    call ds:unlock_proc
    
signal_done:       
    pop ax
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
    push ax
;
	mov ax,task_sel
	mov ds,ax
	cli
	mov ds,ds:thread_act
	xor al,al
	xchg al,ds:p_signal
	or al,al
	jnz wait_for_signal_done
;
    sti
    push OFFSET wait_for_signal_clear
    call SaveCurrentThread
;
	mov ax,task_sel
	mov ds,ax
	mov es,ds:thread_act
	mov si,es:p_prio
    cli
	RemoveBlock
	mov di,OFFSET signal_list
	InsertBlock
	call GetNextThread
	jmp LoadCurrentThread

wait_for_signal_clear:
	mov ax,task_sel
	mov ds,ax
	mov ds,ds:thread_act
	mov ds:p_signal,0
	
wait_for_signal_done:
	sti
	pop ax
	pop ds
	ret
wait_for_signal	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			signal_timeout
;
;		DESCRIPTION:	Signal timeout handler
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

signal_timeout	PROC far
    mov bx,cx
    Signal
    ret
signal_timeout  Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForSignalWithTimeout
;
;		DESCRIPTION:	Wait for a signal with timeout
;
;		PARAMETERS:		EDX:EAX     Timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_signal_timeout_name	DB 'Wait For Signal With Timeout',0

wait_for_signal_timeout	PROC far
    push ds
    push cx
;
	mov cx,task_sel
	mov ds,cx
	cli
	mov ds,ds:thread_act
	xor cl,cl
	xchg cl,ds:p_signal
	or cl,cl
	jnz wait_for_signal_timeout_done
;
    sti
    push OFFSET wait_for_signal_timeout_clear
    call SaveCurrentThread
;
	mov cx,task_sel
	mov ds,cx
    mov cx,cs
    mov es,cx
    mov di,OFFSET signal_timeout    
    mov bx,ds:thread_act
    mov cx,bx
    StartTimer
;
	cli
	mov es,ds:thread_act
	mov si,es:p_prio
	RemoveBlock
	mov di,OFFSET signal_list
	InsertBlock
	call GetNextThread
	jmp LoadCurrentThread

wait_for_signal_timeout_clear:
    push bx
	mov cx,task_sel
	mov ds,cx
	mov bx,ds:thread_act
	mov ds,bx
	StopTimer
	mov ds:p_signal,0
	pop bx
	
wait_for_signal_timeout_done:
    sti
	pop cx
	pop ds
	ret
wait_for_signal_timeout	ENDP

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
    push dx
    mov dx,ds
;
    push OFFSET enter_section_done
    call SaveCurrentThread
;
    mov gs,dx
	mov ebx,esi
	mov ax,task_sel
	mov ds,ax
	mov es,ds:thread_act
	mov si,es:p_prio
	cli
	RemoveBlock
;
	mov es:p_sleep_sel,gs
	mov es:p_sleep_offset,ebx
	add es:p_sleep_offset,OFFSET cs_list
	mov di,gs:[ebx].cs_list
	or di,di
	je enter_ins_empty
;	
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
	mov gs:[ebx].cs_list,es
	
enter_inserted:
	mov ax,task_sel
	mov ds,ax
	call GetNextThread
    jmp LoadCurrentThread
    	
enter_section_done:
    pop dx
	ret
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
	jz leave_section_done
;
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
	cmp di,ds:prio_act
	jb leave_section_done
	mov ds:prio_act,di
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
	ret
leave_section	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_process_task
;
;		DESCRIPTION:	Init process task
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_process_task

init_process_task	Proc near
	mov ax,section_proc_sel
	mov ds,ax
;
	InitSection ds:section_handle_section
	mov cx,section_num
	mov di,8 * section_num + OFFSET section_list

init_section_tab_loop:
	mov ax,di
	sub di,8
	mov ds:[di],ax
	loop init_section_tab_loop
;
	mov ds:section_free_list,di
	ret
init_process_task	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			create_user_section
;
;		DESCRIPTION:	Create user section
;
;		RETURNS:		BX		Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_user_section_name	DB 'Create User Section',0

create_user_section	PROC far
	push ds
	push eax
;
	mov ax,section_proc_sel
	mov ds,ax
	EnterSection ds:section_handle_section
	allocate_section
	mov ds:[bx].ucs_value,0
	mov ds:[bx].ucs_list,0
	mov ds:[bx].ucs_owner,0
	mov ds:[bx].ucs_count,0
	LeaveSection ds:section_handle_section
	offset_to_section bx
	clc
;
	pop eax
	pop ds
	retf32
create_user_section	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			create_blocked_user_section
;
;		DESCRIPTION:	Create blocked user section
;
;		RETURNS:		BX		Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_blocked_user_section_name	DB 'Create Blocked User Section',0

create_blocked_user_section	PROC far
	push ds
	push eax
;
	mov ax,section_proc_sel
	mov ds,ax
	EnterSection ds:section_handle_section
	allocate_section
	mov ds:[bx].ucs_value,-1
	mov ds:[bx].ucs_list,0
	mov ds:[bx].ucs_owner,-1
	mov ds:[bx].ucs_count,1
	LeaveSection ds:section_handle_section
	offset_to_section bx
	clc
;
	pop eax
	pop ds
	retf32
create_blocked_user_section	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_user_section
;
;		DESCRIPTION:	Delete user section
;
;		PARAMETERS:		BX		Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_user_section_name	DB 'Delete User Section',0

delete_user_section	PROC far
	push ds
	push eax
;
	mov ax,section_proc_sel
	mov ds,ax
	EnterSection ds:section_handle_section
	section_to_offset bx
	mov ax,[bx]
	dec ax
	test ah,80h
	jz free_section_done
;
	free_section

free_section_done:
	LeaveSection ds:section_handle_section
	xor bx,bx
	clc
;
	pop eax
	pop ds
	retf32
delete_user_section	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			enter_user_section
;
;		DESCRIPTION:	Enter user section
;
;		PARAMETERS:		BX		Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enter_user_section_name	DB 'Enter User Section',0

enter_user_section	PROC far
	push ds
	push ax
	push bx
;
	mov ax,section_proc_sel
	mov ds,ax
	section_to_offset bx
	mov ax,[bx].ucs_value
	dec ax
	test ah,80h
	jz enter_user_section_fail
;
	str ax
	cli
	sub ds:[bx].ucs_value,1
	jc enter_user_section_done
;
	cmp ax,ds:[bx].ucs_owner
	jne enter_user_section_block
;
	add ds:[bx].ucs_value,1
	jmp enter_user_section_done

enter_user_section_block:
	push ds
	push es
	push fs
	pushad
;
	movzx ebx,bx
	mov ax,ds
	mov fs,ax
	mov ax,task_sel
	mov ds,ax
	mov es,ds:thread_act
	mov si,es:p_prio
	RemoveBlock
;
	mov es:p_sleep_sel,fs
	mov es:p_sleep_offset,ebx
	add es:p_sleep_offset,OFFSET ucs_list
	mov di,fs:[bx].ucs_list
	or di,di
	je enter_user_ins_empty
;
	mov ds,di
	mov si,ds:p_prev
	mov ds:p_prev,es
	mov ds,si
	mov ds:p_next,es
	mov es:p_next,di
	mov es:p_prev,si
	jmp enter_user_inserted

enter_user_ins_empty:
	mov es:p_next,es
	mov es:p_prev,es
	mov fs:[bx].ucs_list,es

enter_user_inserted:
	mov ax,task_sel
	mov ds,ax
	call GetNextThread
	call UpdateTimer
;
	popad
	pop fs
	pop es
	pop ds

enter_user_section_done:
	mov ds:[bx].ucs_owner,ax
	inc ds:[bx].ucs_count
	sti

enter_user_section_fail:
	pop bx
	pop ax
	pop ds
	retf32
enter_user_section	ENDP

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			leave_user_section
;
;		DESCRIPTION:	Leave user section
;
;		PARAMETERS:		BX		Section handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

leave_user_section_name	DB 'Leave User Section',0
 
leave_user_section	PROC far
	push ds
	push ax
	push bx
;
	mov ax,section_proc_sel
	mov ds,ax
	section_to_offset bx
	mov ax,[bx].ucs_value
	test ah,80h
	jz leave_user_section_done
;
	cli
	sub ds:[bx].ucs_count,1
	jnz leave_user_section_done
;
	add ds:[bx].ucs_value,1
	jc leave_user_section_done
;
    mov ds:[bx].ucs_owner,-1
	push es
	push fs
	pushad
;
	mov ax,ds
	mov fs,ax
	mov ax,task_sel
	mov ds,ax
;
	mov ax,fs:[bx].ucs_list
	or ax,ax
	jz leave_user_section_pop
;
	mov es,ax
	mov di,es:p_next
	cmp di,fs:[bx].ucs_list
	mov fs:[bx].ucs_list,di
	mov si,es:p_prev
	mov ds,di
	mov ds:p_prev,si
	mov ds,si
	mov ds:p_next,di
	jne leave_user_section_empty
;
	mov word ptr fs:[bx].ucs_list,0

leave_user_section_empty:
	mov ax,task_sel
	mov ds,ax
	mov di,es:p_prio
	InsertBlock
	cmp di,ds:prio_act
	jb leave_user_section_pop
;
	mov ds:prio_act,di
	xor ax,ax
	mov es,ax
	call GetNextThread
	call UpdateTimer

leave_user_section_pop:
	popad
	pop fs
	pop es

leave_user_section_done:
	sti
	pop bx
	pop ax
	pop ds
	retf32
leave_user_section	ENDP

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
	mov ax,ds:thread_act
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
	mov ax,ds:thread_act
	pop ds
	retf32
get_thread_pr	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetProcessor
;
;		DESCRIPTION:	Get current processor
;
;		RETURNS:		AX		Processor
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_processor_name	DB 'Get Processor',0

get_processor	PROC far
    xor ax,ax
	retf32
get_processor	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CpuReset
;
;		DESCRIPTION:	Trigger a CPU reset
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cpu_reset_name	DB 'Cpu Reset',0

cpu_reset	PROC far
	cli
wait_gate1:
	in al,64h
	and al,2
	jnz wait_gate1
	mov al,0D1h
	out 64h,al
wait_gate2:
	in al,64h
	and al,2
	jnz wait_gate2
	mov al,0FEh
	out 60h,al
;
	xor eax,eax
	mov cr3,eax

reset_wait:
    jmp reset_wait
    
	retf32
cpu_reset	ENDP

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
    push OFFSET wait_until_done
    call SaveCurrentThread
;
	mov bx,cs
	mov es,bx
	mov di,OFFSET wake_until
	mov cx,ds:thread_act
	xor bx,bx
	cli
	LocalStartTimer
	mov es,ds:thread_act
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
	call GetNextThread
    jmp LoadCurrentThread

wait_until_done:
	retf32
wait_until	ENDP

wake_until	PROC far
	mov ax,task_sel
	mov ds,ax
	mov es,cx
	cli
	mov di,es:p_prio
	InsertBlock
	cmp di,ds:prio_act
	jbe wake_until_lower
	mov ds:prio_act,di
	LocalGetSystemTime
	add eax,1193
	adc edx,0
	mov ds:preempt_lsb,eax
	mov ds:preempt_msb,edx
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
    push OFFSET wait_milli_done
    call SaveCurrentThread
;
	mov bx,1193
	mul bx
	push dx
	push ax
	pop ebx
	mov es,ds:thread_act
	cli
	call ds:update_clock_proc
	LocalGetSystemTime
	sti
	add eax,ebx
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET wake_until
	mov cx,ds:thread_act
	xor bx,bx
	cli
	LocalStartTimer
	mov es,ds:thread_act
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
	call GetNextThread
    jmp LoadCurrentThread

wait_milli_done:
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
    push OFFSET wait_micro_done
    call SaveCurrentThread
;
	movzx eax,ax
	mov ebx,78184
	mul ebx
	push dx
	push eax
	pop ax
	pop ebx
	mov es,ds:thread_act
	cli
	call ds:update_clock_proc
	LocalGetSystemTime
	sti
	add eax,ebx
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET wake_until
	mov cx,ds:thread_act
	xor bx,bx
	cli
	LocalStartTimer
	mov es,ds:thread_act
	mov si,es:p_prio
	mov es:p_sleep_sel,0
	mov es:p_sleep_offset,1
	RemoveBlock
	call GetNextThread
    jmp LoadCurrentThread

wait_micro_done:
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
	DebugException

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
	mov es,ds:thread_act
	cli
	call ds:update_clock_proc
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
	mov es,ds:thread_act
	cli
	call ds:update_clock_proc
	LocalGetSystemTime
	add eax,ds:time_diff
	adc edx,ds:time_diff+4
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
	push ds
	push bx
	mov bx,task_sel
	mov ds,bx
;
	cli
	sub eax,ds:time_diff
	sbb edx,ds:time_diff+4
	sti
;
	pop bx
	pop ds
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
	push ds
	push bx
	mov bx,task_sel
	mov ds,bx
;
	cli
	add eax,ds:time_diff
	adc edx,ds:time_diff+4
	sti
;
	pop bx
	pop ds
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
	mov ds:system_time,eax
	mov ds:system_time+4,edx
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
	mov ds:time_diff,eax
	mov ds:time_diff+4,edx
	sti
	pop bx
	pop ds
	retf32
update_time	ENDP

code	ENDS

	END

