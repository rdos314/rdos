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
; MP.ASM
; Multiprocessing module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME mp

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def
INCLUDE mp.inc

mp_data_seg	STRUC

mp_init_proc        DW ?
mp_startup_proc     DW ?

mp_thread           DW ?

mp_data_seg ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RealInit
;
;		DESCRIPTION:	Real mode processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0100:0000. It should contain no near jumps!

real_start:    
    mov al,0Fh
    out 70h,al
	jmp short $+2
;
    xor al,al
    out 71h,al
  	jmp short $+2
;
    mov ax,0
    mov ds,ax
    mov bx,0F00h
    mov eax,12345678h
    mov [bx],eax
    cli
    hlt

real_end:
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DelayMs
;
;		DESCRIPTION:	Delay for Init/SIPI
;
;       PARAMETERS:     AX      Delay in ms
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DelayMs Proc near
    WaitMilliSec
    ret
DelayMs Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendInitMem
;
;		DESCRIPTION:	Send init request using shared memory
;
;       PARAMETERS:     EDX     Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInitMem Proc near
    push ds
    push eax
    push edx
;    
    shl edx,24
    mov ax,apic_data_sel
    mov ds,ax
    mov ds:APIC_ICR+10h,edx
;
    mov eax,0C500h
    mov ds:APIC_ICR,eax
;    
    mov ax,1
    call DelayMs
;
    mov eax,08500h
    mov ds:APIC_ICR,eax
;
    pop edx
    pop eax
    pop ds
    ret
SendInitMem Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendInitMsr
;
;		DESCRIPTION:	Send init request using MSRs
;
;       PARAMETERS:     EDX     Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInitMsr Proc near
    push eax
    push ecx
;
    mov eax,0C500h
    mov ecx,MSR_APIC_ICR
    wrmsr
;    
    mov ax,1
    call DelayMs
;
    mov eax,08500h
    mov ecx,MSR_APIC_ICR
    wrmsr
;
    pop ecx
    pop eax
    ret
SendInitMsr Endp
           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendInit
;
;		DESCRIPTION:	Send init request
;
;       PARAMETERS:     EDX     Destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInit Proc near
    call ds:mp_init_proc
    mov ax,20
    call DelayMs
    ret
SendInit Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendStartupMem
;
;		DESCRIPTION:	Send startup request using shared memory
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendStartupMem Proc near
    push ds
    push eax
    push ecx
    push edx
;    
    shl edx,24
    mov cx,apic_data_sel
    mov ds,cx
    mov ds:APIC_ICR+10h,edx
;
    mov ah,46h
    movzx eax,ax
    mov ds:APIC_ICR,eax
;
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
SendStartupMem Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendStartupMsr
;
;		DESCRIPTION:	Send startup request using MSRs
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendStartupMsr Proc near
    push eax
    push ecx
;
    mov ah,46h
    movzx eax,ax
    mov ecx,MSR_APIC_ICR
    wrmsr
;
    pop ecx
    pop eax
    ret
SendStartupMsr Endp
           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendStartup
;
;		DESCRIPTION:	Send startup request
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendStartup Proc near
    call ds:mp_startup_proc
    mov ax,1
    call DelayMs
    ret
SendStartup Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetupMemGates
;
;		DESCRIPTION:	Set up shared memory gates for APIC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupMemGates   Proc near
    mov ax,mp_data_sel
    mov ds,ax
    mov ds:mp_init_proc, OFFSET SendInitMem
    mov ds:mp_startup_proc, OFFSET SendStartupMem
    ret
SetupMemGates   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetupMsrGates
;
;		DESCRIPTION:	Set up MSR gates for x2APIC mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupMsrGates   Proc near
    mov ax,mp_data_sel
    mov ds,ax
    mov ds:mp_init_proc, OFFSET SendInitMsr
    mov ds:mp_startup_proc, OFFSET SendStartupMsr
    ret
SetupMsrGates   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			mp_pr
;
;		DESCRIPTION:	MP test thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mp_name	DB 'MP Test',0

mp_pr:
    int 3
;    
    mov ecx,1Bh
    rdmsr
    test ah,8
    jz mp_pr_done
;
    test ah,4
    jnz mp_pr_apic_msr

mp_pr_apic_mmio:
    call SetupMemGates
    jmp mp_pr_gates_ok

mp_pr_apic_msr:
    call SetupMsrGates

mp_pr_gates_ok:     
    mov edx,1
    call SendInit
    mov al,1
    call SendStartup
    call SendStartup
    int 3
;
    mov eax,100000h
    AllocateBigLinear
;
    mov cx,100h
    mov eax,63h
    push edx

alloc_loop:
    SetPhysicalPage
    add eax,1000h
    add edx,1000h
    loop alloc_loop
;
    pop edx    
    AllocateGdt
    mov ecx,100000h
    CreateDataSelector32
    mov gs,bx
;
    int 3
    mov es,bx
    mov di,1000h
    mov ax,cs
    mov ds,ax
    mov si,OFFSET real_start
    mov cx,OFFSET real_end - OFFSET real_start
    rep movsb
;
    mov bx,467h
    mov ax,0
    mov es:[bx],ax
    mov ax,100h
    mov es:[bx+2],ax
;
    mov al,0Fh
    out 70h,al
	jmp short $+2
;
    mov al,0Ah
    out 71h,al
  	jmp short $+2
;
    mov ax,apic_data_sel
    mov ds,ax
    mov eax,0CC500h
    mov ds:APIC_ICR,eax
    int 3
    mov eax,0C8500h
    mov ds:APIC_ICR,eax
    int 3
;
    mov eax,ds:APIC_ICR
    mov al,0Fh
    out 70h,al
	jmp short $+2
;
    in al,71h
  	jmp short $+2
    int 3
;
    mov eax,0C8601h
    mov ds:APIC_ICR,eax
    int 3
;
    mov eax,ds:APIC_ICR
    

    
    mov eax,05F504D5Fh
;
    mov ebx,40Eh
    mov bx,gs:[bx]
    movzx ebx,bx
    shl ebx,4
;    
;    mov ebx,09FC00h
    mov cx,40h

find_mp_bda:
    cmp eax,gs:[ebx]
    je find_ok
;
    add ebx,10h
    loop find_mp_bda
;    
    mov ebx,0E0000h
    mov cx,2000h

find_mp_bios:
    cmp eax,gs:[ebx]
    je find_ok
;
    add ebx,10h
    loop find_mp_bios
;
    int 3
    stc
    jmp find_fail

find_ok:
    int 3
    mov eax,gs:[ebx]

find_fail:
    int 3

mp_pr_done:
    retf            

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_mp_thread
;
;		DESCRIPTION:	Init mp threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_mp_thread	PROC far
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET mp_pr
	mov di,OFFSET mp_name
	mov cx,500
	mov ax,4
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_mp_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitMpGates
;
;		DESCRIPTION:	Init mp module call-gates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_mp_gates
    
init_mp_gates	PROC near
    push ds
    push es
    pusha
;    
	mov ax,cs
	mov ds,ax
	mov es,ax
;
    popa
    pop es
    pop ds	
	ret
init_mp_gates	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitMpTasks
;
;		DESCRIPTION:	Init mp module tasks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_mp_tasks
    
init_mp_tasks	PROC near
    push ds
    push es
    pusha
;
	mov eax,SIZE mp_data_seg
	mov bx,mp_data_sel
	AllocateFixedSystemMem
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_mp_thread
	HookInitTasking
;
    popa
    pop es
    pop ds	
	ret
init_mp_tasks	ENDP


code	ENDS

	END

