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
; ANIO.ASM
; Analog IO power-management module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME anio

GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\wait.inc
INCLUDE ..\..\kernel\handle.inc

	.386p

adc_wait_header	STRUC

ad_obj			wait_obj_header <>
ad_handle		DW ?

adc_wait_header	ENDS

adc_handle_seg	STRUC

adc_handle_base	handle_header <>

ad_time		DD ?,?
ad_channel		DB ?

adc_handle_seg		ENDS

WriteZflByte    Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov al,data
    inc dx
    out dx,al
                Endm

ReadZflByte Macro index
    mov al,index
    mov dx,218h
    out dx,al
    inc dx
    in al,dx
            Endm

WriteZflWord    Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov ax,data
    mov dx,21Ah
    out dx,ax
                Endm

ReadZflWord Macro index
    mov al,index
    mov dx,218h
    out dx,al
    mov dx,21Ah
    in ax,dx
            Endm

WriteZflDword   Macro index, data
    mov al,index
    mov dx,218h
    out dx,al
    mov eax,data
    mov dx,21Ah
    out dx,eax
                Endm

ReadZflDword    Macro index
    mov al,index
    mov dx,218h
    out dx,al
    mov dx,21Ah
    in eax,dx
                Endm  

code	SEGMENT byte public use16 'CODE'

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Delete_handle
;
;		DESCRIPTION:	Delete handle (called from handle module)
;
;		PARAMETERS:		BX			ADC HANDLE
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_handle	Proc far
	push ds
	push bx
;
	mov ax,ADC_HANDLE
	DerefHandle
	jc delete_handle_done
;
	FreeHandle
	clc

delete_handle_done:
	pop bx
	pop ds
	ret
delete_handle	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			OpenAdc
;
;		DESCRIPTION:	Open ADC handle
;
;		PARAMETERS:		AX		Channel #
;
;		RETURNS:		BX		ADC handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_adc_name	DB 'Open Adc', 0

open_adc	Proc far
	push ds
	push ax
	push cx
    mov ax,ADC_HANDLE
	mov cx,SIZE adc_handle_seg
	AllocateHandle
	pop cx
	pop ax
	mov [bx].ad_channel,al
	mov [bx].ad_time,0
	mov [bx].ad_time+4,0
	mov [bx].hh_sign,ADC_HANDLE
	mov bx,[bx].hh_handle
	pop ds
	retf32
open_adc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			close_adc
;
;		description:	Close adc handle
;
;		PARAMETERS:		BX		adc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_adc_name DB 'Close Adc',0

close_adc	Proc far
	push ds
	push ax
;
    mov ax,ADC_HANDLE
    DerefHandle
    jc close_adc_done
;
    FreeHandle

close_adc_done:
	pop ax
	pop ds
	retf32
close_adc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			define_adc_time
;
;		description:	Define time for next ADC conversion
;
;		PARAMETERS:		BX		adc handle
;						EDX:EAX	next ADC conversion
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_adc_time_name DB 'Define Adc Time',0

define_adc_time	Proc far
	push ds
	push bx
;
	push ax
    mov ax,ADC_HANDLE
    DerefHandle
	pop ax
    jc close_adc_done
;
	mov [bx].ad_time,eax
	mov [bx].ad_time+4,edx
	clc

define_adc_done:
	pop bx
	pop ds
	retf32
define_adc_time	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReadAdc
;
;		DESCRIPTION:	Do an AD conversion
;
;		PARAMETERS:		BX		adc handle
;
;		RETURNS:		EAX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_adc_name	DB 'Read Adc', 0

read_adc	Proc far
	push ds
	push bx
	push dx
;
    mov ax,ADC_HANDLE
    DerefHandle
    jc read_adc_done
;
; test code
;
;	mov eax,10000
;	jmp read_adc_done
;
	mov dx,28Fh
	in al,dx
;
	mov dx,282h
	mov al,[bx].ad_channel
	shl al,4
	or al,[bx].ad_channel
	out dx,al
;
	inc dx
	mov al,0
	out dx,al

read_adc_settle:
	in al,dx
	test al,20h
	jnz read_adc_settle
;
	mov dx,280h
	mov al,80h
	out dx,al
;
	mov dx,283h

read_adc_wait:
	in al,dx
	test al,80h
	jnz read_adc_wait
;
	mov dx,280h
	in al,dx
	mov ah,al
	inc dx
	in al,dx
	xchg al,ah
	movsx eax,ax
	clc

read_adc_done:
	pop dx
	pop bx
	pop ds
	retf32
read_adc	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			adc_timeout
;
;		DESCRIPTION:	Timeout on ADC 
;
;       PARAMETERS:     CX       object to signal
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

adc_timeout Proc far
	push es
    mov es,cx
    SignalWait
	pop es
    ret
adc_timeout  Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StartWaitAdc
;
;		DESCRIPTION:	Start a wait for ADC
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_adc	PROC far
    push ds
	push es
    push eax
    push bx
	push cx
	push edx
	push di
;
    mov bx,es:ad_handle
    mov ax,ADC_HANDLE
    DerefHandle
    jc start_wait_for_done
;
	mov cx,es
	mov eax,[bx].ad_time
	mov edx,[bx].ad_time+4
;
    mov bx,cs
    mov es,bx
	mov bx,cx
    mov di,OFFSET adc_timeout
    StartTimer
	clc

start_wait_for_done:
	pop di
	pop edx
	pop cx
    pop bx
    pop eax
	pop es
    pop ds
    ret
start_wait_for_adc Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			StopWaitForAdc
;
;		DESCRIPTION:	Stop a wait for ADC
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_adc	PROC far
    push ds
    push ax
    push bx
	push cx
;
    mov bx,es:ad_handle
    mov ax,ADC_HANDLE
    DerefHandle
    jc stop_wait_done
;
	mov cx,es
	mov bx,cx
	StopTimer

stop_wait_done:
	pop cx
    pop bx
    pop ax
    pop ds
    ret
stop_wait_for_adc Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ClearAdc
;
;		DESCRIPTION:	Clear adc
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_adc	PROC far
    ret
clear_adc Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsAdcIdle
;
;		DESCRIPTION:	Check if ADC is idle
;
;		PARAMETERS:		ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_adc_idle	PROC far
    push ds
    push eax
    push bx
	push edx
;
    mov bx,es:ad_handle
    mov ax,ADC_HANDLE
    DerefHandle
    jc is_idle_done
;
	GetSystemTime
	sub eax,[bx].ad_time
	sbb edx,[bx].ad_time+4
	cmc

is_idle_done:
	pop edx
    pop bx
    pop eax
    pop ds
    ret
is_adc_idle Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddWaitForAdc
;
;		DESCRIPTION:	Add a wait for ADC
;
;		PARAMETERS:		AX      Adc handle
;                       BX      Wait handle
;                       ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_adc_name	DB 'Add Wait For Adc',0

add_wait_tab:
aw0	DW OFFSET start_wait_for_adc,    	anio_code_sel
aw1 DW OFFSET stop_wait_for_adc,		anio_code_sel
aw2	DW OFFSET clear_adc,				anio_code_sel
aw3	DW OFFSET is_adc_idle,		    	anio_code_sel

add_wait_for_adc	PROC far
	push ds
	push es
	push eax
	push di
;
    push ax
    mov ax,cs
    mov es,ax
   	mov ax,SIZE adc_wait_header - SIZE wait_obj_header
    mov di,OFFSET add_wait_tab
    AddWait
    pop ax
    jc add_wait_done
;
	mov es:ad_handle,ax

add_wait_done:
    pop di
    pop eax
    pop es
    pop ds
	retf32
add_wait_for_adc	ENDP

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
	mov bx,anio_code_sel
	InitDevice
;
	WriteZflWord 20h, 280h
	WriteZflByte 22h, 1Fh
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET delete_handle
	mov ax,ADC_HANDLE
	RegisterHandle
;
	mov si,OFFSET add_wait_for_adc
	mov di,OFFSET add_wait_for_adc_name
	xor dx,dx
	mov ax,add_wait_for_adc_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET open_adc
	mov di,OFFSET open_adc_name
	xor dx,dx
	mov ax,open_adc_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_adc
	mov di,OFFSET close_adc_name
	xor dx,dx
	mov ax,close_adc_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET define_adc_time
	mov di,OFFSET define_adc_time_name
	mov ax,define_adc_time_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET read_adc
	mov di,OFFSET read_adc_name
	mov ax,read_adc_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
