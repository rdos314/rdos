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
; WD.ASM
; Software watchdog support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
        NAME wd
        
GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def

wd_data_seg STRUC

wd_tics                 DD ?

fault_disc              DB ?
fault_start_sector      DD ?
fault_sectors           DD ?

wd_data_seg ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WdTimeout
;
;		DESCRIPTION:	Watchdog timeout - do reset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WdTimeout:
    CpuReset
    jmp WdTimeout

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartWatchdog
;
;		DESCRIPTION:	Start watchdog
;
;       PARAMETERS:     EAX      Timeout in milliseconds 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_watchdog_name DB 'Start Watchdog', 0

start_watchdog   Proc far
    push es
    pushad
;   
    mov bx,wd_data_sel
    mov es,bx
	mov edx,1193
	mul edx
	mov es:wd_tics,eax
;	
	GetSystemTime
	add eax,es:wd_tics
	adc edx,0
;
	mov bx,cs
	mov es,bx
	mov di,OFFSET WdTimeout
	mov bx,wd_data_sel
	StartTimer
;
    popad
    pop es	
    retf32
start_watchdog   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			KickWatchdog
;
;		DESCRIPTION:	Kick watchdog
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kick_watchdog_name DB 'Kick Watchdog', 0

kick_watchdog   Proc far
    push es
    pushad
;    
    GetDebugThread
    or ax,ax
    jnz kw_done
;       
	GetSystemTime
    mov bx,wd_data_sel
    mov es,bx
	add eax,es:wd_tics
	adc edx,0
;
	mov bx,cs
	mov es,bx
	mov di,OFFSET WdTimeout
	mov bx,wd_data_sel
	StopTimer
	StartTimer

kw_done:
    popad	
    pop es
    retf32
kick_watchdog   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StopWatchdog
;
;		DESCRIPTION:	Stop watchdog
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_watchdog_name DB 'Stop Watchdog', 0

stop_watchdog   Proc far
    push es
    push bx    
;    
	mov bx,wd_data_sel
	mov es,bx
	StopTimer
    mov es:wd_tics,0	
;
    pop bx
    pop es
    retf32
stop_watchdog   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetWatchdogTics
;
;		DESCRIPTION:	Get watchdog tics
;
;       RETURNS:        EAX == 0 not running
;                       EAX != 0, EAX tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_watchdog_tics_name DB 'Get Watchdog Tics', 0

get_watchdog_tics   Proc far
    push es
    push bx    
;    
	mov bx,wd_data_sel
	mov es,bx
    mov eax,es:wd_tics
;
    pop bx
    pop es
    retf32
get_watchdog_tics   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DefineFaultSave
;
;		DESCRIPTION:	Define fault save position on disc
;
;       PARAMETERS:     AL      Disc #
;                       EDX     Start sector #
;                       ECX     Number of available sectors
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_fault_save_name	DB 'Define Fault Save',0

define_fault_save	PROC far
    push ds
    push bx
;
    mov bx,wd_data_sel
    mov ds,bx
    mov ds:fault_disc,al
    mov ds:fault_start_sector,edx
    mov ds:fault_sectors,ecx
;    
    pop bx
    pop ds
    retf32
define_fault_save   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ClearFaultSave
;
;		DESCRIPTION:	Clear fault save data
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_fault_save_name	DB 'Clear Fault Save',0

clear_fault_save	PROC far
    retf32
clear_fault_save   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetFaultThreadState
;
;		DESCRIPTION:	Get fault thread state
;
;       PARAMETERS:     AX          Thread #
;                       ES:E(DI)    State buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_fault_thread_state_name	DB 'Get Fault Thread State',0

get_fault_thread_state	PROC near
    stc
    ret
get_fault_thread_state   Endp

get_fault_thread_state16	Proc far
	push edi
	movzx edi,di
	call get_fault_thread_state
	pop edi
	ret
get_fault_thread_state16	Endp

get_fault_thread_state32	Proc far
	call get_fault_thread_state
	Retf32
get_fault_thread_state32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetFaultThreadTss
;
;		DESCRIPTION:	Get fault thread tss
;
;       PARAMETERS:     AX          Thread #
;                       ES:E(DI)    Tss buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_fault_thread_tss_name	DB 'Get Fault Thread Tss',0

get_fault_thread_tss	PROC near
    stc
    ret
get_fault_thread_tss   Endp

get_fault_thread_tss16	Proc far
	push edi
	movzx edi,di
	call get_fault_thread_tss
	pop edi
	ret
get_fault_thread_tss16	Endp

get_fault_thread_tss32	Proc far
	call get_fault_thread_tss
	Retf32
get_fault_thread_tss32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:	Initialize module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
;
	mov bx,wd_code_sel
	InitDevice
;
	mov eax,SIZE wd_data_seg
	mov bx,wd_data_sel
	AllocateFixedSystemMem
	mov es,bx
	mov es:wd_tics,0
	mov es:fault_sectors,0
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET start_watchdog
	mov di,OFFSET start_watchdog_name
	xor dx,dx
	mov ax,start_watchdog_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET kick_watchdog
	mov di,OFFSET kick_watchdog_name
	xor dx,dx
	mov ax,kick_watchdog_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET stop_watchdog
	mov di,OFFSET stop_watchdog_name
	xor dx,dx
	mov ax,stop_watchdog_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_watchdog_tics
	mov di,OFFSET get_watchdog_tics_name
	xor dx,dx
	mov ax,get_watchdog_tics_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET define_fault_save
	mov di,OFFSET define_fault_save_name
	xor dx,dx
	mov ax,define_fault_save_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET clear_fault_save
	mov di,OFFSET clear_fault_save_name
	xor dx,dx
	mov ax,clear_fault_save_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET get_fault_thread_state16
	mov si,OFFSET get_fault_thread_state32
	mov di,OFFSET get_fault_thread_state_name
	mov dx,virt_es_in
	mov ax,get_fault_thread_state_nr
	RegisterUserGate
;
	mov bx,OFFSET get_fault_thread_tss16
	mov si,OFFSET get_fault_thread_tss32
	mov di,OFFSET get_fault_thread_tss_name
	mov dx,virt_es_in
	mov ax,get_fault_thread_tss_nr
	RegisterUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
