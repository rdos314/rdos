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
; NTP.ASM
; NTP protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  ntp

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE system.def
INCLUDE protseg.def
INCLUDE driver.def
INCLUDE int.def
INCLUDE user.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE os.inc
INCLUDE exec.def
INCLUDE ne.def
INCLUDE system.inc
INCLUDE	ntp.inc

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			GetTimestamp
;
;	Purpose:		Get current time in time-stamp format
;
;	Returns:		EDX:EAX		Time-stamp time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetTimestamp	Proc near
	push ecx
;
	GetSystemTime
	sub edx,1				; UTC + 1 time-zone
	sub edx,0FE2440h		; rel to 1/1 1900 (no leap in 1900)
	mov ecx,edx
	mov edx,3600
	mul edx
	push eax	
	push edx
	mov eax,3600
	mul ecx
	pop ecx
	add eax,ecx
	mov edx,eax
	pop eax
;
	pop ecx	
	ret
GetTimestamp	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			SyncTime
;
;	Purpose:		Sync time with NTP
;
;	Parameters:		IP address of NTP-server
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sync_time_name DB 'Synchronize Time',0

sync_time	Proc far
	push ds
	push es
	push ax
	push bx
	push cx
	push edx
	push si
	push di
;
	mov ax,ntp_data_sel
	mov ds,ax
	mov es,ax
	mov cx,SIZE ntp_header
	mov di,OFFSET ntp_req
	xor al,al
	rep stosb
	mov di,OFFSET ntp_req
	mov ds:ntp_req.ntp_flag,1Bh
	mov ds:ntp_req.ntp_strat,3
	mov ds:ntp_req.ntp_poll,100
	mov ds:ntp_req.ntp_precision,-20
;
	push edx
	call GetTimestamp
	xchg al,ah
	ror eax,16
	xchg al,ah
	mov ds:ntp_req.ntp_orginate_timestamp+4,eax
	xchg dl,dh
	ror edx,16
	xchg dl,dh
	mov ds:ntp_req.ntp_orginate_timestamp,edx		; t1
	pop edx
;
	mov cx,SIZE ntp_header
	mov bx,123
	mov eax,2000
	QueryUdp
	jc sync_time_done
;
	call GetTimestamp								; t4
	mov ebx,es:[di].ntp_transmit_timestamp+4		; t3
	xchg bl,bh
	ror ebx,16
	xchg bl,bh
	mov ecx,es:[di].ntp_transmit_timestamp
	xchg cl,ch
	ror ecx,16
	xchg cl,ch
	sub eax,ebx										; t4 - t3
	sbb edx,ecx
	push eax
	push edx	
;
	mov ebx,ds:ntp_req.ntp_orginate_timestamp+4		; t1
	xchg bl,bh
	ror ebx,16
	xchg bl,bh
	mov ecx,ds:ntp_req.ntp_orginate_timestamp
	xchg cl,ch
	ror ecx,16
	xchg cl,ch	
	mov eax,es:[di].ntp_receive_timestamp+4			; t2
	xchg al,ah
	ror eax,16
	xchg al,ah
	mov edx,es:[di].ntp_receive_timestamp
	xchg dl,dh
	ror edx,16
	xchg dl,dh
	sub eax,ebx
	sbb edx,ecx										; t2 - t1
;
	pop ecx
	pop ebx											; t4 - t3
	sub eax,ebx
	sub edx,ecx										; t2 - t1 - (t4 - t3)
	mov ebx,eax
	mov ecx,edx
	test ecx,80000000h
	pushf
	jz diff_pos
diff_neg:
	not ebx
	not ecx
diff_pos:
	mov eax,ecx
	xor edx,edx
	mov edi,3600*2
	div edi
	push eax
	mov eax,ebx
	div edi
	pop edx
	popf
	jz sync_diff_found
	not eax
	not edx
sync_diff_found:
	FreeMem
	UpdateTime
	clc
sync_time_done:
	pop di
	pop si
	pop edx
	pop cx
	pop bx
	pop ax
	pop es
	pop ds
	retf32
sync_time	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:    Init NTP driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	push ds
	push es
	pusha
;
	mov bx,ntp_code_sel
	InitDevice
;
	mov eax,SIZE ntp_data
	mov bx,ntp_data_sel
	AllocateFixedSystemMem
	mov es,bx
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET sync_time
	mov di,OFFSET sync_time_name
	xor dx,dx
	mov ax,sync_time_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code    ENDS

        END init
