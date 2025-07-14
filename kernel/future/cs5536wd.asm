;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; CS5536WD.ASM
; CS5536 watchdog support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def


	.386p

; ECX       MSR register
; EDX:EAX   Value   
rdmsr	MACRO
	db 0Fh
	db 32h
        ENDM

; ECX       MSR register
; EDX:EAX   Value
wrmsr	MACRO
	db 0Fh
	db 30h
        ENDM
      
wd_data_seg	SEGMENT AT 0

IoBase      DW ?

wd_data_seg ENDS


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
    push ds
    push eax
    push ecx
    push edx
;
    int 3
;
    mov ax,wd_data_sel
    mov ds,ax
;    
    mov dx,ds:IoBase
    add dx,28h
    mov ax,0FFFFh
    out dx,ax
;    
    mov dx,ds:IoBase
    add dx,2Ah
    mov ax,1000
    out dx,ax
;    
    mov dx,ds:IoBase
    add dx,2Ch
    xor ax,ax
    out dx,ax
;    
    mov dx,ds:IoBase
    add dx,2Eh
    in ax,dx
    or ax,4000h
    out dx,ax
;    
    mov ecx,51400029h
    rdmsr
    or eax,20000000h
    wrmsr
    rdmsr    
;    
    mov dx,ds:IoBase
    add dx,2Eh
    in ax,dx
    or ax,8000h
    out dx,ax
;
    in ax,dx
    sub dx,2
    in ax,dx    
;    
    xor edx,edx
    mov ecx,1000
    div ecx
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
    pop ecx
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
    GetDebugThreadSel
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
	mov bx,wd_code_sel
	InitDevice
;
	mov eax,SIZE wd_data_seg
	mov bx,wd_data_sel
	AllocateFixedSystemMem
    mov ecx,5140000dh
    rdmsr
    test dl,1
    jz iDone
;    
	mov es:IoBase,ax
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

iDone:
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
