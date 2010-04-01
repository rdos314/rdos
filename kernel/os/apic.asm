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
INCLUDE port.def
INCLUDE system.def
INCLUDE apic.inc
INCLUDE proc.inc

apic_data_seg	STRUC

mp_init_proc        DW ?
mp_startup_proc     DW ?
mp_int_proc         DW ?

mp_thread           DW ?

mp_processor_sign   DD ?
mp_apic             DD ?
mp_processor_sel    DW ?

apic_arr            DW 256 DUP(?)

apic_data_seg ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Tables
;
;		DESCRIPTION:	GDT for protected mode initialization of AP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0000:0F80h

table_start:

gdt0:
	dw 0
	dd 0
	dw 0
gdt8:
	dw 28h-1
	dd 92000F80h
	dw 0
gdt10:
	dw 0FFFFh
	dd 9A001400h
	dw 0
gdt18:
	dw 0FFFFh
	dd 92000000h
	dw 0
gdt20:
	dw 0FFFFh
	dd 92001800h
	dw 0

table_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RealMode
;
;		DESCRIPTION:	Real mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 0100:0000. It should contain no near jumps!

real_start:    
    cli
    mov al,0Fh
    out 70h,al
	jmp short $+2
;
    xor al,al
    out 71h,al
  	jmp short $+2
;
    xor ax,ax
    mov ds,ax
;    
    mov bx,0F88h
    lgdt fword ptr ds:[bx]
;
	mov eax,cr0
	or al,1
	mov cr0,eax
;
	db 0EAh
	dw 0
	dw 10h

real_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ProtMode
;
;		DESCRIPTION:	Unpaged, protected mode AP processor init
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01400. It should contain no near jumps!
        
prot_start:
    mov ax,18h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov sp,0F00h
;
    mov ax,20h
    mov es,ax
    mov eax,es:ap_cr3
    mov cr3,eax
;    
    db 66h
    lgdt fword ptr es:ap_gdt
;    
    db 66h
    lidt fword ptr es:ap_idt
;
    mov dx,es:ap_ss
;    
    mov eax,cr0
    or eax,80000000h        
    mov cr0,eax
;
    db 0EAh
    dw OFFSET ApInit
    dw apic_code_sel

prot_end:
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Paging
;
;		DESCRIPTION:	Paging variables for AP initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this code is loaded at 01800h. The code is relative to GDT selector 20h

page_struc  STRUC

ap_ss   DW ?
ap_cr3  DD ?
ap_gdt  DB 6 DUP(?)
ap_idt  DB 6 DUP(?)

page_struc  ENDS
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ApInit
;
;		DESCRIPTION:	Paged entry-point for AP initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ApInit:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
;
    mov ss,dx
    mov sp,200h    
;
    mov ax,flat_sel
    mov ds,ax    
;    
    call InitApic
;
    mov ax,apic_data_sel
    mov ds,ax
    mov eax,12345678h
    mov ds:mp_processor_sign,eax
    GetApicId
    mov ds:mp_apic,edx
    sti
    hlt
    int 3

   
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
    push ds
    push es
    pushad
;
    mov dx,system_data_sel
    mov ds,dx
    movzx eax,ax
    mov ecx,1193
    mul ecx
;        
    mov ecx,ds:apic_tics
    shl ecx,16
    mov cx,ds:apic_rest
    shl eax,16
    mul ecx
    inc edx
;
    mov ax,apic_mem_sel
    mov es,ax    
    mov es:APIC_INIT_COUNT,edx

dmLoop:
    mov eax,es:APIC_CURR_COUNT
    or eax,eax
    jnz dmLoop
;       
    popad
    pop es
    pop ds
    ret
DelayMs Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetId
;
;		DESCRIPTION:	Get own ID, memory mode
;
;       RETURNS:        EDX     Apic ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_id_name    DB 'Get Apic ID',0

get_id_mem  Proc far
    push ds
    push ax
;    
    mov ax,apic_mem_sel
    mov ds,ax
    mov edx,ds:APIC_ID
    shr edx,24
;
    pop ax
    pop ds
    ret
get_id_mem Endp

get_id_msr Proc far
    push eax
    push ecx
;
    mov ecx,MSR_APIC_ID
    rdmsr
    mov edx,eax
;
    pop ecx
    pop eax
    ret
get_id_msr Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetProcessor
;
;		DESCRIPTION:	Get processor #
;
;       RETURNS:        AX  Processor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_processor_id_name    DB 'Get Processor ID',0

get_processor_mem  Proc far
    push ds
    push ebx
;    
    mov ax,apic_mem_sel
    mov ds,ax
    mov ebx,ds:APIC_ID
    shr ebx,24
    add bx,bx
    mov ax,apic_data_sel
    mov ds,ax
    mov ax,ds:[bx].apic_arr
;
    pop ebx
    pop ds
    retf32
get_processor_mem Endp

get_processor_msr Proc far
    push ds
    push bx
    push ecx
;
    mov ecx,MSR_APIC_ID
    rdmsr
    movzx bx,al
    add bx,bx
    mov ax,apic_data_sel
    mov ds,ax
    mov ax,ds:[bx].apic_arr
;
    pop ecx
    pop bx
    pop ds
    retf32
get_processor_msr Endp
   
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
    mov ax,apic_mem_sel
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
    push ds
    push ax
;    
    mov ax,apic_data_sel
    mov ds,ax
    call ds:mp_init_proc
    mov ax,20
    call DelayMs
;
    pop ax
    pop ds    
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
    mov cx,apic_mem_sel
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
    push ds
    push ax
    push bx
;    
    mov bx,apic_data_sel
    mov ds,bx
    call ds:mp_startup_proc
    mov ax,1
    call DelayMs
;
    pop bx
    pop ax
    pop ds    
    ret
SendStartup Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendIntMem
;
;		DESCRIPTION:	Send int request using shared memory
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendIntMem Proc near
    push ds
    push eax
    push ecx
    push edx
;    
    shl edx,24
    mov cx,apic_mem_sel
    mov ds,cx
    mov ds:APIC_ICR+10h,edx
;
    mov ah,40h
    movzx eax,ax
    mov ds:APIC_ICR,eax
;
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
SendIntMem Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendIntMsr
;
;		DESCRIPTION:	Send int request using MSRs
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendIntMsr Proc near
    push eax
    push ecx
;
    mov ah,40h
    movzx eax,ax
    mov ecx,MSR_APIC_ICR
    wrmsr
;
    pop ecx
    pop eax
    ret
SendIntMsr Endp
           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendInt
;
;		DESCRIPTION:	Send int request
;
;       PARAMETERS:     EDX     Destination
;                       AL      Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendInt Proc near
    push ds
    push ax
    push bx
;    
    mov bx,apic_data_sel
    mov ds,bx
    call ds:mp_int_proc
;
    pop bx
    pop ax
    pop ds    
    ret
SendInt Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendProcessorResume
;
;		DESCRIPTION:	Send a resume request
;
;       PARAMETERS:     FS      Processor selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_processor_resume_name    DB 'Send Processor Resume',0

send_processor_resume  Proc far
    ret
send_processor_resume  Endp
       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SetupMemGates
;
;		DESCRIPTION:	Set up shared memory gates for APIC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupMemGates   Proc near
    mov ax,apic_data_sel
    mov ds,ax
    mov ds:mp_init_proc, OFFSET SendInitMem
    mov ds:mp_startup_proc, OFFSET SendStartupMem
    mov ds:mp_int_proc, OFFSET SendIntMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET get_id_mem
	mov di,OFFSET get_id_name
	xor cl,cl
	mov ax,get_apic_id_nr
	RegisterOsGate
;
	mov si,OFFSET send_processor_resume
	mov di,OFFSET send_processor_resume_name
	xor cl,cl
	mov ax,send_processor_resume_nr
	RegisterOsGate
;
	mov si,OFFSET get_processor_mem
	mov di,OFFSET get_processor_id_name
	xor dx,dx
	mov ax,get_processor_id_nr
	RegisterBimodalUserGate
;    
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
    mov ax,apic_data_sel
    mov ds,ax
    mov ds:mp_init_proc, OFFSET SendInitMsr
    mov ds:mp_startup_proc, OFFSET SendStartupMsr
    mov ds:mp_int_proc, OFFSET SendIntMsr
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET get_id_msr
	mov di,OFFSET get_id_name
	xor cl,cl
	mov ax,get_apic_id_nr
	RegisterOsGate
;
	mov si,OFFSET get_processor_msr
	mov di,OFFSET get_processor_id_name
	xor dx,dx
	mov ax,get_processor_id_nr
	RegisterBimodalUserGate
;	
    ret
SetupMsrGates   Endp

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:		    StartCore
;
;		DESCRIPTION:	Start a CPU core
;
;       PARAMETERS:     EDX         APIC ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartCore   Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,apic_data_sel
    mov fs,ax
;    
    mov ebp,edx    
    mov eax,2000h
    AllocateBigLinear
;
    mov eax,63h
    SetPhysicalPage
;    
    mov eax,1063h
    add edx,1000h
    SetPhysicalPage
    sub edx,1000h
;
    AllocateGdt
    mov ecx,2000h
    CreateDataSelector32
    mov es,bx
    mov ax,cs
    mov ds,ax
;
    mov di,0F80h
    mov si,OFFSET table_start
    mov cx,OFFSET table_end - OFFSET table_start
    rep movsb
;
    mov di,1000h
    mov si,OFFSET real_start
    mov cx,OFFSET real_end - OFFSET real_start
    rep movsb
;
    mov di,1400h
    mov si,OFFSET prot_start
    mov cx,OFFSET prot_end - OFFSET prot_start
    rep movsb
;
    mov di,1800h
    mov eax,cr3
    mov es:[di].ap_cr3,eax
;
    db 66h
    sgdt fword ptr es:[di].ap_gdt
;
    db 66h
    sidt fword ptr es:[di].ap_idt
;
    push es
    mov eax,200h
    AllocateSmallGlobalMem
    mov ax,es
    pop es
    mov es:[di].ap_ss,ax
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
    mov fs:mp_processor_sign,0
;
    xchg edx,ebp
    call SendInit
;
    mov eax,fs:mp_processor_sign
    cmp eax,12345678h
    je scOk
;    
    mov al,1
    call SendStartup
;
    mov cx,250

scLoop1:
    mov eax,fs:mp_processor_sign
    cmp eax,12345678h
    je scOk
;    
    mov ax,1
    call DelayMs    
    loop scLoop1
;
    mov al,1    
    call SendStartup
;    
    mov cx,250

scLoop2:
    mov eax,fs:mp_processor_sign
    cmp eax,12345678h
    je scOk
;    
    mov ax,1
    call DelayMs    
    loop scLoop2
;
    stc
    jmp scDone

scOk:
    clc

scDone:
    pushf
;
    mov al,0Fh
    out 70h,al
	jmp short $+2
;
    xor al,al
    out 71h,al
  	jmp short $+2
;
    mov edx,ebp
    xor eax,eax
    add edx,1000h
    SetPhysicalPage
    sub edx,1000h
;    
    SetPhysicalPage
    FreeMem
;
    popf   
    popad
    pop fs
    pop es
    pop ds
    ret
StartCore   Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			apic_pr
;
;		DESCRIPTION:	APIC test thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

apic_name	DB 'Apic Test',0

apic_pr:
    int 3 
    GetProcessor
    mov edx,fs:ps_apic
;    
    mov ax,apic_data_sel
    mov ds,ax
    mov eax,ds:mp_processor_sign
    mov edx,ds:mp_apic
    mov fs,ds:mp_processor_sel
    mov edx,fs:ps_apic
;
    
    GetProcessor
    mov al,80h
    mov edx,1

    SendProcessorResume
    SendProcessorResume
    SendProcessorResume
    int 3
    
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

apic_pr_done:
    retf            

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_apic_thread
;
;		DESCRIPTION:	Init apic threads
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_apic_thread	PROC far
	push ds
	push es
	pusha
;
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test ax,200h
;    jz init_thread_done
;    
;    mov ecx,1Bh
;    rdmsr
;    test ah,8
;    jz init_thread_done
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;	
	mov si,OFFSET apic_pr
	mov di,OFFSET apic_name
	mov cx,500
	mov ax,4
	CreateThread

init_thread_done:
	popa
	pop es
	pop ds
	ret
init_apic_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitApic
;
;		DESCRIPTION:    Init APIC timer
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


InitApic    Proc near
    mov bx,apic_mem_sel
    mov es,bx
;
    mov eax,8700h
    mov es:APIC_LINT0,eax
;
    mov eax,400h
    mov es:APIC_LINT1,eax 
;   
    mov eax,10000h
    mov es:APIC_LERROR,eax
;
    mov eax,10000h
    mov es:APIC_THERMAL,eax
;
    mov eax,10000h
    mov es:APIC_PERF,eax
;
    mov eax,10000h
    mov es:APIC_TIMER,eax
;
    mov eax,es:APIC_SPUR
    or eax,100h
    mov al,0Fh
    mov es:APIC_SPUR,eax    
;
    mov eax,0Bh
    mov es:APIC_DIV_CONFIG,eax
    ret
InitApic    Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitApicTimer
;
;		DESCRIPTION:    Init APIC timer
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_tics   MACRO
    mov al,0
	out TIMER_CONTROL,al
	jmp short $+2
	in al,TIMER0
	mov ah,al
	jmp short $+2
	in al,TIMER0
	xchg al,ah
	        ENDM

InitApicTimer Proc near    
    mov ax,system_data_sel
    mov ds,ax
;    
    mov ecx,1Bh
    rdmsr
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
    and ax,0F000h
    or ax,33h
    SetPhysicalPage    
    mov bx,apic_mem_sel
    mov ecx,1000h
    CreateDataSelector16
    call InitApic

init_tsc_start:
    xor cx,cx    

init_tsc_wait_start_high:
    read_tics    
    test ax,8000h
    jnz init_tsc_wait_start_high_ok
    loop init_tsc_wait_start_high    

init_tsc_wait_start_high_ok:
    xor cx,cx    

init_tsc_wait_start_low:
    read_tics    
    test ax,8000h
    jz init_tsc_wait_start_low_ok
    loop init_tsc_wait_start_low

init_tsc_wait_start_low_ok:    
    mov eax,-1
    mov es:APIC_INIT_COUNT,eax

init_apic_start_done:
    xor cx,cx

init_tsc_wait_high:    
    read_tics
    test ax,8000h
    jnz init_tsc_wait_high_ok
    loop init_tsc_wait_high

init_tsc_wait_high_ok:
    xor cx,cx

init_tsc_wait_low:    
    read_tics
    test ax,8000h
    jz init_tsc_wait_low_ok
    loop init_tsc_wait_low

init_tsc_wait_low_ok:
    mov eax,-1
    sub eax,es:APIC_CURR_COUNT    
    xor edx,edx
    mov ecx,8000h
    div ecx
;
    mov ds:apic_tics,eax
    mov ds:apic_rest,dx    
;    
    ret
InitApicTimer Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Init
;
;		DESCRIPTION:	Init apic mp module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pushad
;	
	mov bx,apic_code_sel
	InitDevice
;
	mov eax,SIZE apic_data_seg
	mov bx,apic_data_sel
	AllocateFixedSystemMem
	mov di,OFFSET apic_arr
	xor ax,ax
	mov cx,100h
	rep stosw
;
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test ax,200h
    jz init_apic_gates_ok
;
    test ax,10h
    jz init_apic_timer_ok
;    
    call InitApicTimer

init_apic_timer_ok:    
    mov ax,system_data_sel
    mov ds,ax
    mov eax,ds:cpu_feature_flags
    test ax,20h
    jz init_apic_mmio
;    
    mov ecx,1Bh
    rdmsr
    test ah,8
    jz init_apic_start_cpu
;
    test ah,4
    jnz init_apic_msr

init_apic_mmio:
    call SetupMemGates
    jmp init_apic_start_cpu

init_apic_msr:
    call SetupMsrGates

init_apic_start_cpu:
    GetProcessor
    GetApicId
    mov fs:ps_apic,edx
    xor dl,1    
    call StartCore
    jc init_apic_gates_ok
;    
    CreateProcessor    
	mov bx,apic_data_sel
	mov ds,bx
    mov ds:mp_processor_sel,es
;
    movzx bx,dl
    add bx,bx
    mov [bx].apic_arr,ax
;
    mov edx,ds:mp_apic
    mov es:ps_apic,edx

init_apic_gates_ok:     
    mov ax,cs
	mov es,ax
	mov di,OFFSET init_apic_thread
	HookInitTasking
;
    popad
    pop es
    pop ds	
	ret
init	ENDP

code	ENDS

	END init

