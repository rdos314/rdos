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
; CPU.ASM
; CPU properties module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME cpu

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.def

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetCpuVersion
;
;		DESCRIPTION:	Get CPU version
;
;		PARAMETERS:	    ES:(E)DI)     CPU vendor string buffer
;
;       RETURNS:        AL            CPU version
;                       EBX           CPU frequency
;                       EDX           Feature flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cpu_version_name DB 'Get Cpu Version', 0

get_cpu_version	Proc near
    push ds
    push ecx
    push esi
    push edi
;    
    mov ax,system_data_sel
    mov ds,ax
;
    mov ecx,1193182
    movzx eax,ds:tsc_rest
    shl eax,16
    mul ecx
    mov esi,edx
;    
    mov eax,ds:tsc_tics
    mul ecx
    add eax,esi
    adc edx,0    
    add eax,500000
    adc edx,0
;
    mov ecx,1000000
    div ecx
    mov ebx,eax
;    
    mov ecx,13
    mov esi,OFFSET cpu_vendor
    rep movs byte ptr es:[edi],[esi]
;    
    mov al,ds:cpu_type
    mov edx,ds:cpu_feature_flags
;
    pop edi
    pop esi
    pop ecx
    pop ds
    ret
get_cpu_version Endp

get_cpu_version16   Proc far
    push edi
    movzx edi,di
    call get_cpu_version
    pop esi
    ret
get_cpu_version16   Endp

get_cpu_version32   Proc far
    call get_cpu_version
    retf32
get_cpu_version32   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InitCpuGates
;
;		DESCRIPTION:	Init cpu module call-gates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_cpu_gates
    
init_cpu_gates	PROC near
    push ds
    push es
    pusha
;    
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov bx,OFFSET get_cpu_version16
	mov si,OFFSET get_cpu_version32
	mov di,OFFSET get_cpu_version_name
	mov dx,virt_es_in
	mov ax,get_cpu_version_nr
	RegisterUserGate
;
    popa
    pop es
    pop ds	
	ret
init_cpu_gates	ENDP


code	ENDS

	END
