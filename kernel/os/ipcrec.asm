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
; IPCREC.ASM
; Receiver part of local IPC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  ipcrec

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE int.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE exec.def
INCLUDE ne.def
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE	ipc.inc

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

	extrn SelectorToLinear:near

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			ReplyLocal
;
;		DESCRIPTION:	Reply
;
;		PARAMETERS:		DS			Mailslot
;						ES:EDI		Message buffer
;						ECX			Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReplyLocal 

ReplyLocal	Proc near
	push ds
	push es
	push ax
	push bx
	push ecx
	push esi
	push edi
;
	cmp ecx,ds:m_send_max_size
	jbe do_reply_inrange
;
	mov ecx,ds:m_send_max_size

do_reply_inrange:
	mov ds:m_send_size,ecx
	push ds
	mov ax,es
	mov es,ds:m_send_glob_sel
	mov ds,ax
	mov esi,edi	
	xor edi,edi
	rep movs byte ptr es:[edi],[esi]
	xor ax,ax
	mov es,ax
	pop ds
;
	mov bx,ds:m_send_glob_sel
	FreeGdt
;
	xor bx,bx
	xchg bx,ds:m_send_thread
	mov es,bx
	mov eax,ds:m_send_size
;
	mov es:p_data,eax
	xor ax,ax
	mov es,ax
	Signal
;
	pop edi
	pop esi
	pop ecx
	pop bx
	pop ax
	pop es
	pop ds
	ret
ReplyLocal	Endp

code    ENDS

        END
