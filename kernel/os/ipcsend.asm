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
; IPCSEND.ASM
; Sender part of local IPC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  ipcsend

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE exec.def
INCLUDE system.def
INCLUDE system.inc
INCLUDE ip.inc
INCLUDE	ipc.inc

ipc_list_data	STRUC

il_ml_list			mailslot_list_data <>
il_send_base		DD ?
il_send_size		DD ?
il_send_glob_base	DD ?
il_send_glob_size	DD ?
il_send_glob_sel	DW ?
il_send_thread		DW ?
il_reply_max_size	DD ?
il_reply_base		DD ?
il_reply_glob_base	DD ?
il_reply_glob_size	DD ?
il_reply_glob_sel	DW ?
il_reply_thread		DW ?

ipc_list_data	ENDS


code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

	extrn SelectorToLinear:near
	extrn ReplyLocal:near
	extrn QueueReceiveRequest:near
	extrn CopyToReceiver:near

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CopyFromSender
;
;		DESCRIPTION:	Copy message from sender
;
;		PARAMETERS:		DS			Mailslot
;						ES			SMP list entry
;						FS:ESI		Message buffer
;
;		RETURNS:		ECX			Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyFromSender	Proc near
	push eax
	push bx
	push edx
	push esi
	push edi
;
	push ds
	push es
	mov ecx,es:il_send_size
	mov ds,es:il_send_glob_sel
	mov ax,fs
	mov es,ax
	mov edi,esi
	xor esi,esi
	rep movs byte ptr es:[edi],ds:[esi]
	pop es
	pop ds
;
	push ds
	mov ax,process_page_sel
	mov ds,ax
;
	mov ecx,es:il_send_glob_size
	shr ecx,12
	mov esi,es:il_send_glob_base
	shr esi,10
	mov eax,2

do_rec_zero:
	mov [esi],eax
	add esi,4
	sub ecx,1
	jnz do_rec_zero
;
	pop ds
	mov bx,es:il_send_glob_sel
	FreeGdt
;
	mov edx,es:il_send_glob_base
	mov ecx,es:il_send_glob_size
	FreeLinear
;
	mov eax,es:il_reply_max_size
	mov ds:m_send_max_size,eax
	mov eax,es:il_reply_base
	mov ds:m_send_base,eax
	mov eax,es:il_reply_glob_base
	mov ds:m_send_glob_base,eax
	mov eax,es:il_reply_glob_size
	mov ds:m_send_glob_size,eax
	mov ax,es:il_reply_glob_sel
	mov ds:m_send_glob_sel,ax
	mov ax,es:il_reply_thread
	mov ds:m_send_thread,ax
	mov ecx,es:il_send_size
	FreeMem
	LeaveSection ds:m_section
;
	pop edi
	pop esi
	pop edx
	pop bx
	pop eax
	ret
CopyFromSender	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			InsertSend
;
;		DESCRIPTION:	Insert send request
;
;		PARAMETERS:		DS			Mailslot
;						ES:EDI		Reply buffer
;						ECX			Max reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertSend	Proc near
	pushad
;
	call SelectorToLinear
	mov al,es:[edi]
	mov al,es:[edi+ecx-1]
;
	mov ds:m_reply_callb,OFFSET ReplyLocal
	GetThread
	mov ds:m_send_thread,ax
	mov ds:m_send_base,edx
	mov ds:m_send_max_size,ecx
	mov eax,edx
	add eax,ecx
	dec eax
	and ax,0F000h
	add eax,1000h
	and dx,0F000h
	sub eax,edx
	mov ds:m_send_glob_size,eax
	AllocateBigLinear
	mov ds:m_send_glob_base,edx
	mov ax,word ptr ds:m_send_base
	and ax,0FFFh
	or dx,ax
	AllocateGdt
	mov ecx,ds:m_send_max_size
	CreateDataSelector32
	mov ds:m_send_glob_sel,bx
	mov ecx,ds:m_send_glob_size
	shr ecx,12
	mov esi,ds:m_send_base
	and si,0F000h
	shr esi,10
	mov edi,ds:m_send_glob_base
	shr edi,10
;
	push ds
	mov ax,process_page_sel
	mov ds,ax

ins_send_copy:
	mov eax,[esi]
	mov [edi],eax
	add esi,4
	add edi,4
	sub ecx,1
	jnz ins_send_copy
	pop ds		
;
	popad
	ret
InsertSend	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			QueueSend
;
;		DESCRIPTION:	Queue a send
;
;		PARAMETERS:		DS			Mailslot
;						FS:ESI		Send buffer
;						ECX			Send size
;						ES:EDI		Reply buffer
;						EAX			Max reply size
;
;		RETURNS:		GS			SMP list entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

QueueSend	Proc near
	push es
	pushad
;
	push ds
	mov ebp,ecx
	mov ecx,eax
	push es
	mov eax,SIZE ipc_list_data
	AllocateSmallGlobalMem
	mov ax,es
	mov gs,ax
	pop es
;
	call SelectorToLinear
	mov al,es:[edi]
	mov al,es:[edi+ecx-1]
;
	mov gs:ml_rec_callb,OFFSET CopyFromSender
	mov gs:ml_reply_callb,OFFSET ReplyLocal
	GetThread
	mov gs:il_reply_thread,ax
	mov gs:il_reply_base,edx
	mov gs:il_reply_max_size,ecx
	mov eax,edx
	add eax,ecx
	dec eax
	and ax,0F000h
	add eax,1000h
	and dx,0F000h
	sub eax,edx
	mov gs:il_reply_glob_size,eax
	AllocateBigLinear
	mov gs:il_reply_glob_base,edx
	mov ax,word ptr gs:il_reply_base
	and ax,0FFFh
	or dx,ax
	AllocateGdt
	mov ecx,gs:il_reply_max_size
	CreateDataSelector32
	mov gs:il_reply_glob_sel,bx
;
	mov edx,esi
	mov ecx,gs:il_reply_glob_size
	shr ecx,12
	mov esi,gs:il_reply_base
	and si,0F000h
	shr esi,10
	mov edi,gs:il_reply_glob_base
	shr edi,10
;
	mov ax,process_page_sel
	mov ds,ax

queue_send_copy:
	mov eax,[esi]
	mov [edi],eax
	add esi,4
	add edi,4
	sub ecx,1
	jnz queue_send_copy
;
	mov edi,edx
	mov ecx,ebp
	mov ax,fs
	mov es,ax
	call SelectorToLinear
	mov al,es:[edi]
	mov al,es:[edi+ecx-1]
;
	GetThread
	mov gs:il_send_thread,ax
	mov gs:il_send_base,edx
	mov gs:il_send_size,ecx
	mov eax,edx
	add eax,ecx
	dec eax
	and ax,0F000h
	add eax,1000h
	and dx,0F000h
	sub eax,edx
	mov gs:il_send_glob_size,eax
	AllocateBigLinear
	mov gs:il_send_glob_base,edx
	mov ax,word ptr gs:il_send_base
	and ax,0FFFh
	or dx,ax
	AllocateGdt
	mov ecx,gs:il_send_size
	CreateDataSelector32
	mov gs:il_send_glob_sel,bx
	mov ecx,gs:il_send_glob_size
	shr ecx,12
	mov esi,gs:il_send_base
	and si,0F000h
	shr esi,10
	mov edi,gs:il_send_glob_base
	shr edi,10
;
	mov ax,process_page_sel
	mov ds,ax

queue_send_rep_copy:
	mov eax,[esi]
	mov [edi],eax
	add esi,4
	add edi,4
	sub ecx,1
	jnz queue_send_rep_copy
;
	pop ds
	mov ax,gs
	mov es,ax
	call QueueReceiveRequest
;
	popad
	pop es
	ret
QueueSend	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RemoveSend
;
;		DESCRIPTION:	Remove send request
;
;		PARAMETERS:		ECX		Size of reply buffer
;						ESI		Global base
;						EDI		Local base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveSend	Proc near
	pushad
;
	mov edx,esi
	shr ecx,12
	push ecx
	shr esi,10
	and di,0F000h
	shr edi,10
;
	push ds
	mov ax,process_page_sel
	mov ds,ax

rem_send_copy:
	mov eax,2
	xchg eax,[esi]
	mov [edi],eax
	add esi,4
	add edi,4
	sub ecx,1
	jnz rem_send_copy
	pop ds
;
	pop ecx
	shl ecx,12
	FreeLinear
;
	popad
	ret
RemoveSend	Endp

PAGE
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			SendLocal
;
;		DESCRIPTION:	Send a local message
;
;		PARAMETERS:		DS			Mailslot selector
;						FS:ESI		Message buffer
;						ECX			Message size
;						ES:EDI		Reply buffer
;						EBP			Max reply size
;
;		RETURNS:		ECX			Reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SendLocal

SendLocal	Proc near
	push fs
	push gs
	push eax
	push esi
	push edi
;
	EnterSection ds:m_section
	ClearSignal
	mov ax,ds:m_rec_thread
	or ax,ax
	jz send_local_busy
;
	mov ax,ds:m_send_thread
	or ax,ax
	jz send_local_idle

send_local_busy:
	mov eax,ebp
	call QueueSend
	mov ecx,gs:il_reply_glob_size
	mov esi,gs:il_reply_glob_base
	mov edi,gs:il_reply_base
	xor ax,ax
	mov gs,ax
	LeaveSection ds:m_section
	jmp send_local_wait

send_local_idle:
	push ecx
	mov ecx,ebp
	call InsertSend
	pop ecx
	push ds:m_send_glob_size
	push ds:m_send_glob_base
	push ds:m_send_base
	call CopyToReceiver
	pop edi
	pop esi
	pop ecx

send_local_wait:
	WaitForSignal
	call RemoveSend
	push ds
	GetThread
	mov ds,ax
	mov ecx,ds:p_data
	pop ds
	clc
;
	pop edi
	pop esi
	pop eax
	pop fs
	pop gs
	ret
SendLocal	Endp

code    ENDS

        END
