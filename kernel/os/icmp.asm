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
; ICMP.ASM
; ICMP protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  icmp

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE driver.def
INCLUDE int.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE exec.def
INCLUDE ne.def
INCLUDE system.inc
INCLUDE ip.inc

TYPE_ECHO_REPLY = 0
TYPE_UNREACHABLE = 3
TYPE_QUENCH = 4
TYPE_REDIRECT = 5
TYPE_ECHO_REQ = 8
TYPE_TIMEOUT = 11
TYPE_PARAMETER_ERROR = 12
TYPE_TIMESTAMP_REQ = 13
TYPE_TIMESTAMP_REPLY = 14
TYPE_INFO_REQ = 15
TYPE_INFO_REPLY = 16

icmp_header	STRUC

icmp_type		DB ?
icmp_code		DB ?
icmp_checksum	DW ?
icmp_data		DB ?

icmp_header	ENDS

Reverse	MACRO
	xchg al,ah
	rol eax,16
	xchg al,ah
		ENDM

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CalcChecksum
;
;		DESCRIPTION:    Calculate checksum for TCP
;
;		PARAMETERS:		AX		Checksum in
;						CX		Size of data
;						ES:DI	Data
;
;		RETURNS:		AX		Checksum out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcChecksum	Proc near
	push ds
	push cx
	push dx
	push si
;
	mov si,es
	mov ds,si
	mov si,di
	mov dx,ax
	shr cx,1
	pushf
	clc
checksum_loop:
	lodsw
	adc dx,ax
	loop checksum_loop
	adc dx,0
	adc dx,0
	popf
	jnc calc_checksum_done
	xor ah,ah
	lodsb
	add dx,ax
	adc dx,0
	adc dx,0
calc_checksum_done:
	mov ax,dx
;
	pop si
	pop dx
	pop cx
	pop ds
	ret
CalcChecksum	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			ReceiveEchoReply
;
;	Purpose:		Received echo reply from IP
;
;	Parameters:		ECX		Size of data
;					EDX		Source IP address
;					DS:ESI	Options
;					ES:EDI	IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveEchoReply	Proc near
	mov ax,ip_data_sel
	mov ds,ax
	mov bx,ds:ping_thread
	or bx,bx
	jz receive_echo_reply_done
;
	mov eax,ds:ping_id
	cmp eax,dword ptr es:[edi].icmp_data
	jne receive_echo_reply_done
	mov ds:ping_status,1
	Signal

receive_echo_reply_done:
	ret
ReceiveEchoReply	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			ReceiveEchoReq
;
;	Purpose:		Received echo from IP
;
;	Parameters:		ECX		Size of data
;					EDX		Source IP address
;					DS:ESI	Options
;					ES:EDI	IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveEchoReq	Proc near
	mov es:[di].icmp_type,0
	mov es:[di].icmp_checksum,0
	xor ax,ax
	call CalcChecksum
	not ax
	mov es:[di].icmp_checksum,ax
;
	xor ax,ax
	mov ds,ax
	mov eax,es:ip_source
	xchg eax,es:ip_dest
	mov es:ip_source,eax
	SendIp
	ret
ReceiveEchoReq	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			Receive
;
;	Purpose:		Receive notify from IP
;
;	Parameters:		AX		Size of options
;					ECX		Size of data
;					EDX		Source IP address
;					DS:ESI	Options
;					ES:EDI	IP Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveDiscard	Proc near
	ret
ReceiveDiscard	Endp

ReceiveTab:
rt00 DW OFFSET ReceiveEchoReply
rt01 DW OFFSET ReceiveDiscard
rt02 DW OFFSET ReceiveDiscard
rt03 DW OFFSET ReceiveDiscard
rt04 DW OFFSET ReceiveDiscard
rt05 DW OFFSET ReceiveDiscard
rt06 DW OFFSET ReceiveDiscard
rt07 DW OFFSET ReceiveDiscard
rt08 DW OFFSET ReceiveEchoReq
rt09 DW OFFSET ReceiveDiscard
rt0A DW OFFSET ReceiveDiscard
rt0B DW OFFSET ReceiveDiscard
rt0C DW OFFSET ReceiveDiscard
rt0D DW OFFSET ReceiveDiscard
rt0E DW OFFSET ReceiveDiscard
rt0F DW OFFSET ReceiveDiscard

Receive	Proc far
	push ax
	push bx
;
	xor ax,ax
	call CalcChecksum
	not ax
	or ax,ax
	jnz receive_done
;
	movzx bx,es:[di].icmp_type
	cmp bl,16
	ja receive_done
;
	shl bx,1
	call word ptr cs:[bx].ReceiveTab

receive_done:
	xor ax,ax
	mov ds,ax
	FreeMem
;
	pop bx
	pop ax
	ret
Receive	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			Ping
;
;	Purpose:		Ping node
;
;	Parameters:		EAX		Timeout in ms
;					EDX		Dest IP address
;
;	Returns:		NC		Ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ping_name	DB 'Ping',0

PingTimeout	Proc far
	mov bx,ip_data_sel
	mov ds,bx
	mov bx,ds:ping_thread
	Signal
	ret
PingTimeout	Endp

PingOptions DB 0

ping_node Proc far 
	push ds
	push es
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
	push ebp
;
	push eax
	mov ax,ip_data_sel
	mov ds,ax
	EnterSection ds:ping_section
	push edx
	GetSystemTime
	mov ds:ping_id,eax
	mov ebp,eax
	GetThread
	mov ds:ping_thread,ax
	mov ds:ping_status,0
	ClearSignal
;
	mov dx,cs
	mov ds,dx
	mov esi,OFFSET PingOptions
	xor edx,edx
	mov ecx,1000
	div ecx
	pop edx
	or ah,al
	mov al,1
	mov ecx,40
	CreateIpHeader
	mov es:[di].icmp_type,8
	mov es:[di].icmp_code,0
	mov es:[di].icmp_checksum,0
	mov dword ptr es:[di].icmp_data,ebp
	push cx
	push di
	add di,8
	mov cx,32
	mov al,'r'
	rep stosb
	pop di
	pop cx
	xor ax,ax
	call CalcChecksum
	not ax
	mov es:[di].icmp_checksum,ax
	SendIp
	mov ax,ip_data_sel
	mov ds,ax
	mov ax,cs
	mov es,ax
	mov di,OFFSET PingTimeout
	pop eax
	mov edx,1192
	mul edx
	mov ecx,eax
	GetSystemTime
	add eax,ecx
	adc edx,0
	mov bx,ds:ping_thread
	StartTimer
	WaitForSignal
	StopTimer
	mov ds:ping_thread,0
	mov al,ds:ping_status
	LeaveSection ds:ping_section
;
	or al,al
	stc
	jz ping_done
	clc
ping_done:
	pop ebp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop es
	pop ds
	retf32
ping_node	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:    Init ICMP driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_icmp

init_icmp	PROC near
	mov ax,ip_data_sel
	mov ds,ax
	InitSection ds:ping_section
	mov ds:ping_thread,0
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov al,1
	mov di,OFFSET Receive
	HookIp
;
	mov si,OFFSET ping_node
	mov di,OFFSET ping_name
	xor cl,cl
	mov ax,ping_nr
	RegisterUserGate
	ret
init_icmp	ENDP

code    ENDS

        END
