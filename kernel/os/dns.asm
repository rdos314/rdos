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
; DNS.ASM
; Simple client-only DNS implementation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  dns

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
INCLUDE	ip.inc
INCLUDE dns.inc

Reverse	MACRO
	xchg al,ah
	rol eax,16
	xchg al,ah
		ENDM

	extrn GetHostNameSize:near
	extrn FindHostByName:near
	extrn FindHostByAddress:near
	extrn DefineHostByName:near

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			DecodeNameRequest
;
;	Purpose:		Decode DNS name request answer
;
;	Parameters:		ES:DI		DNS answer
;
;	Returns:		NC			ok
;					EDX			IP address
;					CY			error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeNameRequest	Proc near
	push ax
	push cx
;
	mov ax,es:[di].dns_id
	cmp ax,fs:dns_id
	jne decode_name_inv_resp
	mov ax,es:[di].dns_op
	xchg al,ah
	test ah,80h
	jz decode_name_inv_resp
	mov dx,es:[di].dns_qdcount
	xchg dl,dh
	cmp dx,1
	jne decode_name_inv_resp
	mov dx,es:[di].dns_ancount
	xchg dl,dh
	or dx,dx
	jz decode_name_inv_resp
	add di,SIZE dns_header
	sub cx,SIZE dns_header
	jc decode_name_inv_resp
	jz decode_name_inv_resp

decode_name_question:
	movzx ax,byte ptr es:[di]
	or ax,ax
	jz decode_name_question_opt
	add di,ax
	sub cx,ax
	jc decode_name_inv_resp
	inc di
	sub cx,1
	jz decode_name_inv_resp
	jmp decode_name_question	

decode_name_question_opt:
	add di,1
	sub cx,5
	jc decode_name_inv_resp
	mov ax,es:[di]
	xchg al,ah
	cmp ax,1
	jnz decode_name_inv_resp
	add di,2
	mov ax,es:[di]
	xchg al,ah
	cmp ax,1
	jnz decode_name_inv_resp
	add di,2

decode_name_answer:
	or cx,cx
	jz short decode_name_inv_resp
	mov al,es:[di]
	test al,80h
	jnz decode_name_answer_ref
	movzx ax,al
	or ax,ax
	jz decode_name_answer_opt
	add di,ax
	sub cx,ax
	jc decode_name_inv_resp
	inc di
	sub cx,1
	jz decode_name_inv_resp
	jmp decode_name_answer

decode_name_answer_ref:
	add di,2
	sub cx,2
	jc decode_name_inv_resp

decode_name_answer_opt:
	sub cx,SIZE dns_host_answer
	jc decode_name_inv_resp
	mov ax,es:[di].dns_atype
	xchg al,ah
	cmp ax,1
	jne decode_name_skip_answer
	mov ax,es:[di].dns_aclass
	xchg al,ah
	cmp ax,1
	jne decode_name_skip_answer
	mov ax,es:[di].dns_alen
	xchg al,ah
	cmp ax,4
	jne decode_name_inv_resp
	add di,SIZE dns_host_answer
	sub cx,4
	jc decode_name_inv_resp
	mov edx,es:[di]
	FreeMem
	clc
	jmp decode_name_done

decode_name_skip_answer:
	mov ax,es:[di].dns_alen
	add di,SIZE dns_host_answer
	xchg al,ah
	sub cx,ax
	jc decode_name_inv_resp
	add di,ax
	sub dx,1
	jnz decode_name_answer

decode_name_inv_resp:
	FreeMem
	stc

decode_name_done:
	pop cx
	pop ax
	ret
DecodeNameRequest	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			NameToIp
;
;	Purpose:		Convert host address to IP address
;
;	Parameters:		ES:(E)DI	Host name
;
;	Returns:		NC			ok
;					EDX			IP address
;					CY			error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

name_to_ip_name DB 'Name To IP',0

name_to_ip	Proc near
	push ds
	push es
	push fs
	push gs
	push eax
	push bx
	push ecx
	push esi
	push edi
	push ebp
;
	mov ax,es
	mov gs,ax
	mov ebp,edi
	call FindHostByName
	jc name_to_ip_lookup
;
	mov ds,ax
	mov edx,ds:host_addr
	jmp name_to_ip_done

name_to_ip_lookup:
	call GetHostNameSize
	jc name_to_ip_fail
;
	push es
	push edi
	mov eax,ecx
	add eax,SIZE dns_header + SIZE dns_host_query + 2
	AllocateSmallGlobalMem
	pop esi
	pop ds
	push ax
	mov edi,SIZE dns_header
	xor ecx,ecx
name_to_ip_move_loop:
	push esi
	xor cl,cl
name_to_ip_move_dot_loop:
	mov al,[esi]
	cmp al,'.'
	je name_to_ip_move_part
	or al,al
	je name_to_ip_move_part
	inc esi
	inc cl
	jmp name_to_ip_move_dot_loop
	
name_to_ip_move_part:
	pop esi
	mov al,cl
	stosb
	rep movs byte ptr es:[edi],[esi]
	lods byte ptr [esi]
	cmp al,'.'
	je name_to_ip_move_loop
;
	xor al,al
	stosb
	mov ax,ip_data_sel
	mov ds,ax
	cli
	mov ax,ds:dns_curr_id
	inc ds:dns_curr_id
	sti
	mov es:dns_id,ax
	mov es:dns_op,1
	mov es:dns_qdcount,100h		; = 1
	mov es:dns_ancount,0
	mov es:dns_nscount,0
	mov es:dns_arcount,0
	mov ax,100h
	stosw						; qtype = 1
	stosw						; qclass = 1
	mov ax,es
	mov fs,ax
	pop cx	
;
	mov edx,ds:dns1
	mov bx,53
	mov eax,2000
	push cx
	or edx,edx
	jz name_to_ip_ppp
;
	xor di,di
	QueryUdp
	jc name_to_ip_second
;
	call DecodeNameRequest
	jnc name_to_ip_ok

name_to_ip_second:
	pop cx
	mov ax,fs
	mov es,ax
;
	mov edx,ds:dns2
	mov bx,53
	mov eax,2000
	push cx
	or edx,edx
	jz name_to_ip_ppp
;
	xor di,di
	QueryUdp
	jc name_to_ip_ppp
;
	call DecodeNameRequest
	jnc name_to_ip_ok

name_to_ip_ppp:
	pop cx
	mov ax,fs
	mov es,ax
;
	GetPppDns
	mov edx,eax
	mov bx,53
	mov eax,2000
	push cx
	or edx,edx
	jz name_to_ip_fail
;
	xor di,di
	QueryUdp
	jc name_to_ip_ppp_second
;
	call DecodeNameRequest
	jnc name_to_ip_ok

name_to_ip_ppp_second:
	pop cx
	mov ax,fs
	mov es,ax
;
	GetPppDns
	mov bx,53
	mov eax,2000
	push cx
	or edx,edx
	jz name_to_ip_fail
;
	xor di,di
	QueryUdp
	jc name_to_ip_fail
	call DecodeNameRequest
	jnc name_to_ip_ok

name_to_ip_fail:
	pop ax
	mov ax,fs
	mov es,ax
	xor ax,ax
	mov fs,ax
	FreeMem
	stc
	jmp name_to_ip_done

name_to_ip_ok:
	pop ax
	mov ax,fs
	mov es,ax
	xor ax,ax
	mov fs,ax
	FreeMem
	mov ax,gs
	mov es,ax
	mov edi,ebp
	call DefineHostByName
	clc

name_to_ip_done:
	pop ebp
	pop edi
	pop esi
	pop ecx
	pop bx
	pop eax
	pop gs
	pop fs
	pop es
	pop ds
	ret
name_to_ip	Endp

name_to_ip16	Proc far
	push edi
	movzx edi,di
	call name_to_ip
	pop edi
	ret
name_to_ip16	Endp

name_to_ip32	Proc far
	call name_to_ip
	retf32
name_to_ip32	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			DecodeNodeRequest
;
;	Purpose:		Decode DNS node answer
;
;	Parameters:		ES:EDI		DNS answer
;
;	Returns:		NC			ok
;					EDI			node name offset
;					CY			error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeNodeRequest	Proc near
	push ax
	push cx
;
	mov ax,es:[di].dns_id
	cmp ax,fs:dns_id
	jne decode_node_inv_resp
	mov ax,es:[di].dns_op
	xchg al,ah
	test ah,80h
	jz decode_node_inv_resp
	mov dx,es:[di].dns_qdcount
	xchg dl,dh
	cmp dx,1
	jne decode_node_inv_resp
	mov dx,es:[di].dns_ancount
	xchg dl,dh
	or dx,dx
	jz decode_node_inv_resp
	add di,SIZE dns_header
	sub cx,SIZE dns_header
	jc decode_node_inv_resp
	jz decode_node_inv_resp

decode_node_question:
	int 3
	movzx ax,byte ptr es:[di]
	or ax,ax
	jz decode_node_question_opt
	add di,ax
	sub cx,ax
	jc decode_node_inv_resp
	inc di
	sub cx,1
	jz decode_node_inv_resp
	jmp decode_node_question	

decode_node_question_opt:
	add di,1
	sub cx,5
	jc decode_node_inv_resp
	mov ax,es:[di]
	xchg al,ah
	cmp ax,1
	jnz decode_node_inv_resp
	add di,2
	mov ax,es:[di]
	xchg al,ah
	cmp ax,1
	jnz decode_node_inv_resp
	add di,2

decode_node_answer:
	or cx,cx
	jz short decode_node_inv_resp
	mov al,es:[di]
	test al,80h
	jnz decode_node_answer_ref
	movzx ax,al
	or ax,ax
	jz decode_node_answer_opt
	add di,ax
	sub cx,ax
	jc decode_node_inv_resp
	inc di
	sub cx,1
	jz decode_node_inv_resp
	jmp decode_node_answer

decode_node_answer_ref:
	add di,2
	sub cx,2
	jc decode_node_inv_resp

decode_node_answer_opt:
	sub cx,SIZE dns_host_answer
	jc decode_node_inv_resp
	mov ax,es:[di].dns_atype
	xchg al,ah
	cmp ax,1
	jne decode_node_skip_answer
	mov ax,es:[di].dns_aclass
	xchg al,ah
	cmp ax,1
	jne decode_node_skip_answer
	mov ax,es:[di].dns_alen
	xchg al,ah
	cmp ax,4
	jne decode_node_inv_resp
	add di,SIZE dns_host_answer
	sub cx,4
	jc decode_node_inv_resp
	mov edx,es:[di]
	FreeMem
	clc
	jmp decode_node_done

decode_node_skip_answer:
	mov ax,es:[di].dns_alen
	add di,SIZE dns_host_answer
	xchg al,ah
	sub cx,ax
	jc decode_node_inv_resp
	add di,ax
	sub dx,1
	jnz decode_node_answer

decode_node_inv_resp:
	FreeMem
	stc

decode_node_done:
	pop cx
	pop ax
	ret
DecodeNodeRequest	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			DigitToString
;
;	Purpose:		Convert IP address to text notation
;
;	Parameters:		AL			Digit
;					ES:DI		Buffer
;					CX			Count 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DigitToString	Proc near
	push di
	inc di
	xor cx,cx
	xor ah,ah
digit_100_loop:
	sub al,100
	jc digit_100_done
	inc ah
	jmp digit_100_loop

digit_100_done:
	add al,100
	or ah,ah
	jz digit_10_loop
;
	add ah,'0'
	mov es:[di],ah
	inc di
	inc cx
	xor ah,ah

digit_10_loop:
	sub al,10
	jc digit_10_done
	inc ah
	jmp digit_10_loop

digit_10_done:
	add al,10
	or cx,cx
	jnz digit_10_save
;
	or ah,ah
	jz digit1

digit_10_save:
	add ah,'0'
	mov es:[di],ah
	inc di
	inc cx
	xor ah,ah

digit1:
	add al,'0'
	mov es:[di],al
	inc cx
	pop di
	mov es:[di],cl
	inc di
	add di,cx
	ret
DigitToString	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			IpToName
;
;	Purpose:		Convert IP address to host name
;
;	Parameters:		EDX			IP address
;					ES:(E)DI	Host name buffer
;					(E)CX		Size of name buffer
;
;	Returns:		NC			ok
;					CY			error
;					(E)AX		Length of host name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ip_to_name_name DB 'IP To Name',0

ReverseDomain	DB 7,'IN-ADDR',4,'ARPA',0

ip_to_name	Proc near
	push ds
	push es
	push fs
	push bx
	push ecx
	push edx
	push esi
;
	push es
	push ecx
	push edi
;
	call FindHostByAddress
	jc ip_to_name_lookup
;
	mov ds,ax
	mov al,[bx]
	or al,al
	jnz ip_to_name_registered

ip_to_name_lookup:
	mov ecx,29
	mov eax,ecx
	add eax,SIZE dns_header + SIZE dns_host_query + 2
	AllocateSmallGlobalMem
	mov edi,SIZE dns_header
	xor ecx,ecx
	mov al,dl
	call DigitToString
	shr edx,8
	mov al,dl
	call DigitToString
	shr edx,8
	mov al,dl
	call DigitToString
	mov al,dh
	call DigitToString	
	mov ax,cs
	mov ds,ax
	mov si,OFFSET ReverseDomain
	mov cx,7
	rep movsw
;
	mov ax,ip_data_sel
	mov ds,ax
	cli
	mov ax,ds:dns_curr_id
	inc ds:dns_curr_id
	sti
	mov es:dns_id,ax
	mov es:dns_op,1
	mov es:dns_qdcount,100h		; = 1
	mov es:dns_ancount,0
	mov es:dns_nscount,0
	mov es:dns_arcount,0
	mov ax,0C00h
	stosw						; qtype = 12 (PTR)
	mov ax,100h
	stosw						; qclass = 1
	mov ax,es
	mov fs,ax
	mov cx,di
	mov edx,ds:dns1
	mov bx,53
	mov eax,2000
	push cx
	or edx,edx
	jz ip_to_name_fail
;
	xor di,di
	QueryUdp
	jc ip_to_name_second
	call DecodeNodeRequest
	jnc ip_to_name_ok
ip_to_name_second:
	pop cx
	mov ax,fs
	mov es,ax
	mov edx,ds:dns2
	mov bx,53
	mov eax,2000
	push cx
	or edx,edx
	jz ip_to_name_fail
;
	xor di,di
	QueryUdp
	jc ip_to_name_fail
	call DecodeNodeRequest
	jnc ip_to_name_ok

ip_to_name_fail:
	pop ax
	mov ax,fs
	mov es,ax
	xor ax,ax
	mov fs,ax
	FreeMem
	pop edi
	pop ecx
	pop es
	stc
	jmp ip_to_name_done

ip_to_name_ok:
	pop ax
	pop edi
	pop ecx
	pop es
;
; decode it here!
;
	mov ax,fs
	mov es,ax
	xor ax,ax
	mov fs,ax
	FreeMem
	stc
	jmp ip_to_name_done

ip_to_name_registered:
	pop edi
	pop ecx
	pop es
	xor edx,edx
	mov si,bx

ip_to_name_retr_loop:
	or ecx,ecx
	jz ip_to_name_retr_done
;
	dec ecx
	inc edx
	lodsb
	stos byte ptr es:[edi]
	or al,al
	jnz ip_to_name_retr_loop

ip_to_name_retr_done:
	mov eax,edx
	clc

ip_to_name_done:
	pop esi
	pop edx
	pop ecx
	pop bx
	pop fs
	pop es
	pop ds
	ret
ip_to_name	Endp

ip_to_name16	Proc far
	push ecx
	push edi
	movzx ecx,cx
	movzx edi,di
	call ip_to_name
	pop edi
	pop ecx
	ret
ip_to_name16	Endp

ip_to_name32	Proc far
	call ip_to_name
	retf32
ip_to_name32	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:    Init tcp driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public init_dns

init_dns	PROC near
	mov ax,ip_data_sel
	mov ds,ax
	mov ds:dns_curr_id,1
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET name_to_ip16
	mov di,OFFSET name_to_ip_name
	xor cl,cl
	mov ax,name_to_ip_nr
	RegisterUserGate16
	mov si,OFFSET name_to_ip32
	mov di,OFFSET name_to_ip_name
	xor cl,cl
	mov ax,name_to_ip_nr
	RegisterUserGate32
;
	mov si,OFFSET ip_to_name16
	mov di,OFFSET ip_to_name_name
	xor cl,cl
	mov ax,ip_to_name_nr
	RegisterUserGate16
	mov si,OFFSET ip_to_name32
	mov di,OFFSET ip_to_name_name
	xor cl,cl
	mov ax,ip_to_name_nr
	RegisterUserGate32
;
	ret
init_dns	ENDP

code    ENDS

        END
