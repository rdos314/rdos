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
; IP.ASM
; IP protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  ip

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
INCLUDE	ip.inc

	extrn init_dns:near
	extrn init_icmp:near
	extrn init_cache:near

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetPppIP
;
;		description:	Get PPP IP address
;
;		RETURNS:		NC		Valid
;						EDX		My Internet IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ppp_ip_name	DB 'Get PPP IP',0

get_ppp_ip	Proc far
	push ds
	mov dx,ip_data_sel
	mov ds,dx
	mov edx,ds:my_ip
	clc
	pop ds
	ret
get_ppp_ip	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetPppDns
;
;		description:	Get PPP DNS IP address
;
;		RETURNS:		EAX		Primary DNS IP address
;						EDX		Secondary DNS IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ppp_dns_name	DB 'Get PPP DNS IP',0

get_ppp_dns	Proc far
	xor eax,eax
	xor edx,edx
	retf32
get_ppp_dns	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDns
;
;		description:	Get DNS IP address
;
;		RETURNS:		EAX		Primary DNS IP address
;						EDX		Secondary DNS IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dns_name	DB 'Get DNS IP',0

get_dns	Proc far
	push ds
	mov dx,ip_data_sel
	mov ds,dx
	mov eax,ds:dns1
	mov edx,ds:dns2
	pop ds
	retf32
get_dns	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			hook_ip
;
;	Purpose:		register IP receiver callback
;
;	Parameters:		AL		Protocol
;					ES:DI	Receiver callback
;						AX		Size of options
;						BX		Id
;						CX		Size of data
;						EDX		Source IP address
;						DS:ESI	Options
;						ES:EDI	Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_ip_name	DB 'Hook IP',0

hook_ip	Proc far
	push ds
	push es
	push eax
	push bx
;
	push ax
	mov bx,es
	mov eax,SIZE ip_protocol_data
	AllocateSmallGlobalMem
	mov word ptr es:prot_callback,di
	mov word ptr es:prot_callback+2,bx
	pop ax
	mov es:prot_id,al
;
	mov ax,ip_data_sel
	mov ds,ax
	mov bx,ds:protocol_count
	inc ds:protocol_count
	add bx,bx
	mov ds:[bx].protocol_arr,es
;
	pop bx
	pop eax
	pop es
	pop ds
	ret
hook_ip	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			get_ip_address
;
;	Purpose:		Get IP address of my node
;
;	Returns:		EDX		IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ip_address_name	DB 'Get IP Address',0

get_ip_address	Proc far
	push ds
;
	mov dx,ip_data_sel
	mov ds,dx
	mov edx,ds:my_ip
;
	pop ds
	retf32
get_ip_address	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			create_ip_header
;
;	Purpose:		create an IP header, and allocate space for data
;
;	Parameters:		AL		Protocol
;					AH		Time to live
;					ECX		Size of data
;					EDX		Destination IP
;					DS:ESI	Options
;
;	Returns:		ES:EDI	Ip data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_ip_header_name	DB 'Create IP Header',0

create_ip_header	Proc far
	push ds
	push fs
	push eax
	push bx
	push ecx
	push esi
	push ebp
;
	push ds
	push ax
	push cx
	mov cx,SIZE ip_header
	push esi
create_header_opt_loop:
	mov al,[esi]
	or al,al
	jz create_header_alloc
	inc esi
	inc cx
	cmp al,1
	jz create_header_opt_loop
;
	movzx eax,byte ptr [esi]
	dec al
	add cx,ax
	add esi,eax
	jmp create_header_opt_loop

create_header_alloc:	
	pop esi
	mov bx,cx
	dec cx
	and cx,NOT 3
	add cx,4
	movzx eax,cx
	pop cx
	add ax,cx
;
	push ax
	push bx
	mov cx,ax
	mov bx,ip_data_sel
	mov fs,bx
	mov bx,fs:ip_handle
;
	push edx
	and edx,fs:ip_mask
	mov eax,fs:my_ip
	and eax,fs:ip_mask
	cmp eax,edx
	pop edx
	je create_header_not_ppp
;
	cmp dl,127
	je create_header_not_ppp
;
	mov eax,fs:gateway
	or eax,eax
	jz create_header_ppp
;
	push ds
	push esi
	push eax
	mov ax,ss
	mov ds,ax
	movzx esi,sp
	GetNetBuffer
	jc create_header_gw_pop
;	
	mov eax,fs:my_ip
	mov es:[di].ip_source,eax

create_header_gw_pop:
	pop eax
	pop esi
	pop ds
	jnc create_header_fill
	jmp create_header_fail_pop

create_header_ppp:
	GetPppBuffer
;	
	push edx
	GetPppIp
	mov es:[di].ip_source,edx
	pop edx
	jmp create_header_fill

create_header_not_ppp:
	push ds
	push esi
	push edx
	mov ax,ss
	mov ds,ax
	movzx esi,sp
	GetNetBuffer
	jc create_header_local_pop
;	
	mov eax,fs:my_ip
	mov es:[di].ip_source,eax

create_header_local_pop:
	pop edx
	pop esi
	pop ds
	jnc create_header_fill
	jmp create_header_fail_pop

create_header_fill:
	mov bp,di
	mov es:[0],di
	pop ax
	dec ax
	shr ax,2
	inc ax
	or al,40h
	mov es:[di].ip_hdr_ver,al
	mov es:[di].ip_tos,0
	pop ax
	xchg al,ah
	mov es:[di].ip_size,ax
	mov es:[di].ip_frags,0
	pop ax
	mov es:[di].ip_ttl,ah
	mov es:[di].ip_proto,al
	mov es:[di].ip_checksum,0
	mov ax,ip_data_sel
	mov ds,ax
	mov ax,ds:curr_id
	inc ds:curr_id
	xchg al,ah
	mov es:[di].ip_id,ax
	mov es:[di].ip_dest,edx

create_header_ip_done:
	pop ds
;
	add edi,SIZE ip_header
create_header_copy_opt:
	mov al,[esi]
	or al,al
	jz create_header_pad
	movs byte ptr es:[edi],ds:[esi]
	cmp al,1
	je create_header_copy_opt
	movzx ecx,byte ptr [esi]
	rep movs byte ptr es:[edi],ds:[esi]
	jmp create_header_copy_opt

create_header_pad:
	mov si,di
	sub si,bp
	xor al,al
create_header_pad_loop:
	test si,3
	jz create_header_ok
	stos byte ptr es:[edi]
	inc si
	jmp create_header_pad_loop		

create_header_fail_pop:
	xor ax,ax
	mov es,ax
	xor edi,edi
	pop ax
	pop ax
	pop ax
	pop ds
	stc
	jmp create_header_done

create_header_ok:
	clc

create_header_done:
	pop ebp
	pop esi
	pop ecx
	pop bx
	pop eax
	pop fs
	pop ds	
	ret
create_ip_header	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:		    CalcChecksum
;
;	Purpose:		Calculate checksum for IP header
;
;	Parameters:		DS:DI   IP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcChecksum    Proc near
    push ax
    push cx
    push dx
    push si
;    
	mov ds:[di].ip_checksum,0
	movzx cx,ds:[di].ip_hdr_ver
	and cl,0Fh
	shl cl,1
	mov si,di
	xor	dx,dx
	clc
	
calc_checksum_loop:
	lodsw
	adc	dx,ax
	loop calc_checksum_loop
;	
    adc dx,0
    adc dx,0
	not dx
	mov ds:[di].ip_checksum,dx
;
    pop si
    pop dx
    pop cx
    pop ax	
	ret
CalcChecksum    Endp	

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			send_ip_data
;
;	Purpose:		send IP data
;
;	Parameters:		ES		Data selector, IP datagram
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_ip_data_name	DB 'Send IP Data',0

send_ip_data	Proc far
    push ds
	push fs
	push eax
	push bx
	push dx
	push ecx
	push esi
	push edi
;
	mov ax,es
	mov ds,ax
	mov di,ds:[0]
    call CalcChecksum
;
	movzx ecx,ds:[di].ip_size
	xchg cl,ch
;
	mov ax,ip_data_sel
	mov fs,ax
	mov bx,fs:ip_handle
	mov eax,ds:[di].ip_dest
	cmp eax,fs:my_ip
	je send_self
;
	cmp al,127
	je send_self
;
	and eax,fs:ip_mask
	mov esi,fs:my_ip
	and esi,fs:ip_mask
	cmp eax,esi
	je send_local_net
;
	mov eax,fs:gateway
	or eax,eax
	jnz send_gateway

send_ppp:	
	SendPpp
	jmp send_done

send_gateway:
    push ds
    mov ax,fs
    mov ds,ax
	mov esi,OFFSET gateway
	SendNet
	pop ds
	jmp send_done

send_self:
	xor ax,ax
	mov ds,ax
	push cs
	call near ptr Receive
	jmp send_done

send_local_net:
	mov esi,OFFSET ip_dest
	add esi,edi
	SendNet

send_done:
	pop edi
	pop esi
	pop ecx
	pop dx
	pop bx
	pop eax
	pop fs
	pop ds
	ret
send_ip_data	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			receive
;
;	Purpose:		received IP data
;
;	Parameters:		ECX		size
;					DX		packet type
;					DS:SI	source address
;					ES:EDI	data selector, IP datagram
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

receive	Proc far
	push ds
	push fs
	push eax
	push bx
	push ecx
	push esi
;
	mov es:[0],di
	mov ax,es:[di].ip_size
	xchg al,ah
	cmp ax,cx
	ja receive_done
;
	movzx cx,es:[di].ip_hdr_ver
	and cl,0Fh
	cmp cl,5
	jc receive_done
;
	shl cl,1
	xor bx,bx
	mov si,di
	clc
receive_checksum_loop:
	lods word ptr es:[si]
	adc bx,ax
	loop receive_checksum_loop
	adc bx,0
	adc bx,0
	not bx
	or bl,bh
	jnz receive_done

receive_check_ok:
	mov ax,ip_data_sel
	mov ds,ax
	mov eax,es:[di].ip_dest
	cmp eax,ds:my_ip
	je receive_this_node
	cmp eax,-1
	je receive_this_node
	cmp al,127
	je receive_this_node
	push edx
	GetPppIp
	jc receive_pop_fail
	cmp eax,edx
	pop edx
	jne receive_forward
receive_this_node:
	mov cx,ds:protocol_count
	or cx,cx
	jz receive_fail
	mov bx,OFFSET protocol_arr
receive_prot_loop:
	mov fs,[bx]
	mov al,fs:prot_id
	cmp al,es:[di].ip_proto
	jne receive_prot_next
;
	mov ax,es
	mov ds,ax
	mov bx,ds:[di].ip_id
	xchg bl,bh
	mov cx,ds:[di].ip_size
	xchg cl,ch
	mov al,ds:[di].ip_hdr_ver
	and al,0Fh
	shl al,2
	xor ah,ah
	sub cx,ax
	mov edx,ds:[di].ip_source
	add edi,SIZE ip_header
	mov esi,edi
	sub ax,SIZE ip_header
	add di,ax
	call fs:prot_callback
	jmp receive_done

receive_prot_next:
	add bx,2
	loop receive_prot_loop
	jmp receive_fail

receive_forward:
	mov bx,ds:ip_handle
	mov ax,es
	mov ds,ax
	movzx ecx,es:[di].ip_size
	xchg cl,ch
	mov esi,OFFSET ip_dest
	add esi,edi
;	SendNet
	jmp receive_fail

receive_pop_fail:
	pop edx

receive_fail:
	xor ax,ax
	mov ds,ax
	FreeMem
	
receive_done:
	pop esi
	pop ecx
	pop bx
	pop eax
	pop fs
	pop ds
	ret
receive	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			GetIPNumber
;
;	Purpose:		received IP data
;
;	Parameters:		ES:DI	Name
;
;	Returns:		NC		Found
;					EAX		IP number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIPNumber	Proc near
	push ds
	push ebx
	push cx
	push si
;
    LockSysEnv
	mov ds,bx
	xor si,si
find_ip:
	push di
find_ip_loop:
	cmpsb
	jnz find_ip_next
	mov al,es:[di]
	or al,al
	jnz find_ip_loop
	mov al,[si]
	cmp al,'='
	je find_ip_found

find_ip_next:
	pop di

find_ip_next_bp:
	lodsb
	or al,al
	jnz find_ip_next_bp
	mov al,[si]
	or al,al
	jne find_ip
	xor eax,eax
	stc
	jmp find_ip_done

find_ip_found:
	pop di
	xor ebx,ebx
	inc si
	mov cx,4
find_ip_decode:
	xor al,al
find_ip_digit:
	mov dl,[si]
	inc si
	sub dl,'0'
	jc find_ip_save
	cmp dl,10
	jnc find_ip_save
	mov ah,10
	mul ah
	add al,dl
	jmp find_ip_digit

find_ip_save:
	mov bl,al
	ror ebx,8
	loop find_ip_decode		
;
	mov eax,ebx
	clc

find_ip_done:
    pushf
    UnlockSysEnv
    popf
;
	pop si
	pop cx
	pop ebx
	pop ds
	ret
GetIPNumber	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:    Init net driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ip_name			DB 'IP',0
dns1_name		DB 'DNS1',0
dns2_name		DB 'DNS2',0
mask_name		DB 'NETMASK',0
gateway_name	DB 'GATEWAY',0

init	PROC far
	push ds
	push es
	pusha
;
	mov bx,ip_code_sel
	InitDevice
;
	mov eax,SIZE ip_data
	mov bx,ip_data_sel
	AllocateFixedSystemMem
	mov es,bx
	mov ds,bx
	mov ds:protocol_count,0
	mov ds:curr_id,1
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET ip_name
	call GetIPNumber
	mov ds:my_ip,eax
;
	mov di,OFFSET dns1_name
	call GetIPNumber
	mov ds:dns1,eax
;
	mov di,OFFSET dns2_name
	call GetIPNumber
	mov ds:dns2,eax
;
	mov di,OFFSET mask_name
	call GetIpNumber
	mov ds:ip_mask,eax
;
	mov di,OFFSET gateway_name
	call GetIPNumber
	mov ds:gateway,eax
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET hook_ip
	mov di,OFFSET hook_ip_name
	xor cl,cl
	mov ax,hook_ip_nr
	RegisterOsGate
;
	mov si,OFFSET get_ppp_ip
	mov di,OFFSET get_ppp_ip_name
	xor cl,cl
	mov ax,get_ppp_ip_nr
	RegisterOsGate
;
	mov si,OFFSET get_dns
	mov di,OFFSET get_dns_name
	xor dx,dx
	mov ax,get_dns_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET get_ppp_dns
	mov di,OFFSET get_ppp_dns_name
	xor dx,dx
	mov ax,get_ppp_dns_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET create_ip_header
	mov di,OFFSET create_ip_header_name
	xor cl,cl
	mov ax,create_ip_header_nr
	RegisterOsGate
;
	mov si,OFFSET send_ip_data
	mov di,OFFSET send_ip_data_name
	xor cl,cl
	mov ax,send_ip_data_nr
	RegisterOsGate
;
	mov si,OFFSET get_ip_address
	mov di,OFFSET get_ip_address_name
	xor dx,dx
	mov ax,get_ip_address_nr
	RegisterBimodalUserGate
;
	mov cx,4
	mov dx,800h
	mov ax,ip_data_sel
	mov ds,ax
	mov si,OFFSET my_ip
	mov di,OFFSET receive
	RegisterNetProtocol
	mov ds:ip_handle,bx
;
	call init_cache
	call init_dns
	call init_icmp
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code    ENDS

        END init
