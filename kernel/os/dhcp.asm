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
; DHCP.ASM
; DHCP client implementation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  dhcp

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE exec.def
INCLUDE system.inc
INCLUDE net.inc
INCLUDE udp.inc
INCLUDE dhcp.inc

Reverse	MACRO
	xchg al,ah
	rol eax,16
	xchg al,ah
		ENDM

dhcp_option	STRUC

dhcp_opt_next	DW ?
dhcp_opt_code	DB ?
dhcp_opt_callb	DD ?

dhcp_option	ENDS

dhcp_data	STRUC

dhcp_option_list	DW ?

dhcp_data	ENDS

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CalcChecksum
;
;		DESCRIPTION:    Calculate checksum for UDP
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
; 	Name:			CreateDcpBroadcast
;
;	Purpose:		Create a DHCP broadcast header
;
;	Parameters:		CX			Number of bytes to allocate
;					FS			Driver selector
;
;	Returns:		NC			Ok
;					ES:DI		Allocate buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ip_options	DB 0

CreateDhcpBroadcast	Proc near
	push ds
	push ax
	push ecx
	push esi
;
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET ip_options
	mov al,17
	mov ah,30
	movzx ecx,cx
	add ecx,8
	CreateBroadcastIp
	jc create_br_done
;	
	mov ax,67
	xchg al,ah
	mov es:[edi].udp_dest,ax
;
	mov ax,68
	xchg al,ah
	mov es:[edi].udp_source,ax
	add edi,8
	clc

create_br_done:
	pop esi
	pop ecx
	pop ax
	pop ds
	ret
CreateDhcpBroadcast	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			SendDhcpBroadcast
;
;	Purpose:		Send DHCP broadcast message
;
;	Parameters:		ES:EDI		Buffer
;					CX			Number of bytes to send
;					FS			Driver selector
;
;	Returns:		NC			Ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendDhcpBroadcast	Proc near
	push di
;
	sub di,8
	add cx,8
	xchg cl,ch
	mov es:[di].udp_len,cx
	xchg cl,ch
;
	mov es:[di].udp_checksum,0
	mov ax,cx
	xchg al,ah
	add ax,1100h
	adc ax,0
	adc ax,0
	sub di,8
	add cx,8
	call CalcChecksum
	not ax
	add di,8
	mov es:[di].udp_checksum,ax
	sub cx,8
	SendBroadcastIp
;
	pop ax
	ret
SendDhcpBroadcast	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			ClientSize
;
;	Purpose:		Size of client hardware address
;
;	Parameters:		DS			Class selector
;					FS			Driver selector
;
;	Returns:		CX			Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClientSize	Proc near
	movzx cx,ds:addr_len
	add cx,2
	ret
ClientSize	Endp
	
PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			ClientData
;
;	Purpose:		Copy client hardware address
;
;	Parameters:		DS			Class selector
;					FS			Driver selector
;					ES:DI		Position to copy at
;
;	Returns:		ES:DI		New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClientData	Proc near
	push ds
	push si
	push cx
;
	movzx cx,ds:addr_len
	mov al,61
	stosb
	mov es:[di],cl
	inc di
	call fs:d_address
	rep movsb
;
	pop cx
	pop si
	pop ds
	ret
ClientData	Endp
	
PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			ParamSize
;
;	Purpose:		Size of parameters
;
;	Parameters:		DS			Class selector
;					FS			Driver selector
;
;	Returns:		CX			Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParamSize	Proc near
	push ds
	push bx
;
	mov cx,2
	mov bx,dhcp_data_sel
	mov ds,bx
	mov bx,ds:dhcp_option_list

param_size_loop:
	or bx,bx
	jz param_size_done
;
	inc cx
	mov ds,bx
	mov bx,ds:dhcp_opt_next
	jmp param_size_loop

param_size_done:
	pop bx
	pop ds
	ret
ParamSize	Endp
	
PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			ParamData
;
;	Purpose:		Fill in param data
;
;	Parameters:		DS			Class selector
;					FS			Driver selector
;					ES:DI		Position to copy at
;
;	Returns:		ES:DI		New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParamData	Proc near
	push ds
	push bx
	push si
	push cx
;
	xor cl,cl
	mov al,55
	stosb
	mov si,di
	inc di
;
	mov bx,dhcp_data_sel
	mov ds,bx
	mov bx,ds:dhcp_option_list

param_data_loop:
	or bx,bx
	jz param_data_done
;
	inc cl
	mov ds,bx
	mov al,ds:dhcp_opt_code
	stosb
;
	mov bx,ds:dhcp_opt_next
	jmp param_data_loop

param_data_done:
	mov es:[si],cl
;
	pop cx
	pop si
	pop bx
	pop ds
	ret
ParamData	Endp
	
PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			LeaseSize
;
;	Purpose:		Size of IP lease time
;
;	Parameters:		DS			Class selector
;					FS			Driver selector
;
;	Returns:		CX			Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LeaseSize	Proc near
	mov cx,6
	ret
LeaseSize	Endp
	
PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			LeaseData
;
;	Purpose:		Copy IP lease time
;
;	Parameters:		DS			Class selector
;					FS			Driver selector
;					ES:DI		Position to copy at
;
;	Returns:		ES:DI		New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LeaseData	Proc near
	push eax
;
	mov al,51
	stosb
	mov al,4
	stosb
	mov eax,-1
	stosd
;
	pop eax
	ret
LeaseData	Endp
	
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DhcpDiscover
;
;		DESCRIPTION:    Send DHCP discover for a driver
;
;       PARAMETERS:     DS			Class selector
;						FS			Driver selector
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;   	size-proc				data-proc

DhcpOptTab:
d00	DW OFFSET ClientSize,		OFFSET ClientData
d01 DW OFFSET ParamSize,		OFFSET ParamData
d02 DW OFFSET LeaseSize,		OFFSET LeaseData
d03	DW -1

DhcpDiscover	Proc far
	mov dx,SIZE dhcp_header + 1
	mov bx,OFFSET DhcpOptTab

dhcp_disc_size_loop:
	mov ax,cs:[bx]
	cmp ax,-1
	jz dhcp_disc_size_ok
;
	call word ptr cs:[bx]
	add dx,cx
	add bx,4
	jmp dhcp_disc_size_loop

dhcp_disc_size_ok:
	mov cx,dx
	push cx
	call CreateDhcpBroadcast
	mov es:[di].dhcp_op,1
	mov al,ds:class_id
	mov es:[di].dhcp_hw_type,al
	mov al,ds:addr_len
	mov es:[di].dhcp_hw_len,al
	mov es:[di].dhcp_hops,0
	GetSystemTime
	mov es:[di].dhcp_id,eax
	mov es:[di].dhcp_elapsed,0
	mov es:[di].dhcp_flags,0
	mov es:[di].dhcp_client_ip,0
	mov es:[di].dhcp_req_ip,0
	mov es:[di].dhcp_server_ip,0
	mov es:[di].dhcp_relay_ip,0
	mov es:[di].dhcp_magic,63538263h
	mov es:[di].dhcp_msg_code,53
	mov es:[di].dhcp_msg_len,1
	mov es:[di].dhcp_msg_type,1
;
	push di
	mov cx,34h
	add di,OFFSET dhcp_hw_addr
	xor eax,eax
	rep stosd
	pop di
;
	movzx cx,ds:addr_len
	push ds
	push di
	call fs:d_address
	add di,OFFSET dhcp_hw_addr
	rep movsb
	pop di
	pop ds
;
	push di
	add di,SIZE dhcp_header
	mov bx,OFFSET DhcpOptTab

dhcp_disc_data_loop:
	mov ax,cs:[bx]
	cmp ax,-1
	jz dhcp_disc_data_ok
;
	call word ptr cs:[bx+2]
	add bx,4
	jmp dhcp_disc_data_loop

dhcp_disc_data_ok:
	mov al,-1
	stosb
;
	pop di
	pop cx
	call SendDhcpBroadcast
	ret
DhcpDiscover	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AddDhcpOption
;
;		DESCRIPTION:    Add a requested DHCP option to ask for
;
;       PARAMETERS:     AL			Option code
;						ES:DI		Callback
;							ES:DI	Pointer to option data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_dhcp_option_name	DB 'Add DHCP Option',0

add_dhcp_option	Proc far
	push ds
	push es
	push ax
;
	push eax
	mov eax,SIZE dhcp_option
	AllocateSmallGlobalMem
	pop eax
	mov es:dhcp_opt_code,al
	mov word ptr es:dhcp_opt_callb,di
	mov word ptr es:dhcp_opt_callb+2,es
	mov ax,dhcp_data_sel
	mov ds,ax
	mov ax,ds:dhcp_option_list
	mov es:dhcp_opt_next,ax
	mov ds:dhcp_option_list,es
;
	pop ax
	pop es
	pop ds
	ret
add_dhcp_option	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			dhcp_thread
;
;		DESCRIPTION:    dhcp thread
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dhcp_thread_name	DB 'DHCP',0

dhcp_thread_pr:
	mov ax,250
	WaitMilliSec
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET DhcpDiscover
	NetBroadcast
	int 3
	retf

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_dhcp_thread
;
;		DESCRIPTION:    init DHCP thread
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dhcp_thread	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET dhcp_thread_pr
	mov di,OFFSET dhcp_thread_name
	mov ax,3
	mov cx,256
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_dhcp_thread	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_dhcp
;
;		DESCRIPTION:    Init dhcp driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_dhcp

init_dhcp	PROC near
	mov eax,SIZE dhcp_data
	mov bx,dhcp_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov es:dhcp_option_list,0
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_dhcp_thread
	HookInitTasking
;
	mov si,OFFSET add_dhcp_option
	mov di,OFFSET add_dhcp_option_name
	xor cl,cl
	mov ax,add_dhcp_option_nr
	RegisterOsGate
;
	ret
init_dhcp	ENDP

code    ENDS

        END
