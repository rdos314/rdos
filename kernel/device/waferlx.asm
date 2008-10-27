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
; Waferlx.ASM
; Wafer LX support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
        NAME waferlx
        
GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def


	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code


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
    push eax
    push ebx
    push edx
;
    xor edx,edx
    mov ebx,1000
    div ebx
    or eax,eax
    jnz swNotZero
;
    mov al,1

swNotZero:
    test eax,0FFFFFF00h
    jz swNoOv
;
    mov al,255

swNoOv:       
    mov dx,443h
    out dx,al
;    
    pop edx
    pop ebx
    pop eax
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
    push ax
    push dx
;    
    GetDebugThread
    or ax,ax
    jnz kw_done
;    
    mov dx,443h
    in al,dx

kw_done:
    pop dx
    pop ax
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
    push ax
    push dx
;    
    mov dx,843h
    in al,dx
;
    pop dx
    pop ax
    retf32
stop_watchdog   Endp

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
	mov bx,bsp_code_sel
	InitDevice
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
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
