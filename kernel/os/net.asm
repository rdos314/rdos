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
; NET.ASM
; Basic network support module. Includes basic interface + ARP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  net

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
INCLUDE	net.inc


arp_data	STRUC

arp_class		DW ?
arp_type		DW ?
arp_hw_len		DB ?
arp_prot_len	DB ?
arp_op			DW ?

arp_data	ENDS

arp_list_struc	STRUC

arp_prev				DW ?
arp_next				DW ?
arp_timeout				DD ?,?
arp_owner               DW ?
arp_retries				DW ?
arp_protocol			DW ?
arp_logical_addr_len	DB ?
arp_logical_addr		DB ?		; variable size

arp_list_struc	ENDS

arp_rec_struc	STRUC

ar_prev		DW ?
ar_next		DW ?
ar_driver	DW ?
ar_data		DB ?

arp_rec_struc	ENDS

code	SEGMENT byte public 'CODE'

.386p
	
	assume cs:code

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			FindAddress
;
;	Purpose:		Find protocol logical address
;
;	Parameters:		DS		Protocol
;					FS:ESI	Logical address to find
;
;	Returns:		NC		Success
;					AX		Protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindAddress	Proc near
	push es
	push cx
	push edi
;
	push ds
	mov ax,net_data_sel
	mov ds,ax
	EnterSection ds:arp_section
	pop ds
	mov ax,ds:p_entry_list
find_addr_loop:
	or ax,ax
	jz find_addr_failed
;
	mov es,ax
	movzx ecx,ds:p_logical_addr_len
	push esi
	mov edi,OFFSET prot_logical_addr
	repz cmps byte ptr fs:[esi],es:[edi]
	pop esi
	jnz find_addr_check_failed
	jmp find_addr_ok
	
find_addr_check_failed:
	mov ax,es:prot_next
	jmp find_addr_loop

find_addr_failed:
	push ds
	mov ax,net_data_sel
	mov ds,ax
	LeaveSection ds:arp_section
	pop ds
	xor ax,ax
	stc
	jmp find_addr_done

find_addr_ok:
	push ds
	mov ax,net_data_sel
	mov ds,ax
	LeaveSection ds:arp_section
	pop ds
	mov ax,es
	clc

find_addr_done:
	pop edi
	pop cx
	pop es
	ret
FindAddress	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			MoveArp
;
;	Purpose:		Move arp request
;
;	Parameters:		DS		Net_data_sel
;					GS		ARP request
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveArp	Proc near
	push es
	push fs
	push ax
	push bx
	push si
	push di
;
	mov ax,gs
	mov es,ax
	mov ds:arp_send_list,es
	mov di,es:arp_next
	cmp di,ds:arp_send_list
	mov ds:arp_send_list,di
	mov si,es:arp_prev
	mov fs,di
	mov fs:arp_prev,si
	mov fs,si
	mov fs:arp_next,di
	jne move_send_arp_done
;
	mov ds:arp_send_list,0

move_send_arp_done:
	mov ax,ds:arp_answ_list
	or ax,ax
	je move_answ_arp_empty
;
	mov fs,ax
	mov si,fs:arp_prev
	mov fs:arp_prev,es
	mov fs,si
	mov fs:arp_next,es
	mov es:arp_next,ax
	mov es:arp_prev,si
	jmp move_answ_arp_done

move_answ_arp_empty:
	mov es:arp_next,es
	mov es:arp_prev,es
	mov ds:arp_answ_list,es

move_answ_arp_done:
    mov bx,es:arp_owner
    Signal
;    
	mov bx,ds:arp_thread
	Signal
;
	pop di
	pop si
	pop bx
	pop ax
	pop fs
	pop es
	ret
MoveArp	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			CheckArp
;
;	Purpose:		Check address for ARP request
;
;	Parameters:		DS		Net_data_sel
;					ES		Protocol entry
;					FS		Protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckArp	Proc near
	push gs
	push ax
	push bx
	push cx
	push si
	push di

check_arp_loop:
	mov ax,ds:arp_send_list
	or ax,ax
	jz check_arp_done
;
	mov bx,ax

check_arp_send_loop:
	mov gs,ax
	mov ax,fs
	cmp ax,gs:arp_protocol
	jne check_arp_next
;	
	mov al,gs:arp_logical_addr_len
	cmp al,fs:p_logical_addr_len
	jne check_arp_next
;
	mov si,OFFSET arp_logical_addr
	movzx cx,al
	mov di,OFFSET prot_logical_addr
	repz cmps byte ptr gs:[si],es:[di]
	jnz check_arp_next
;
	call MoveArp
	jmp check_arp_loop

check_arp_next:
	mov ax,gs:arp_next
	cmp ax,bx
	jne check_arp_send_loop

check_arp_done:
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	pop gs
	ret
CheckArp	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			InsertAddress
;
;	Purpose:		Insert protocol logical address
;
;	Parameters:		DS		Protocol
;					ES:SI	Address logical address
;					ES:DI	Address to physical
;					FS		Driver handle
;
;	Returns:		AX		Protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertAddress	Proc near
	push ds
	push es
	push fs
	push gs
	push bx
	push ecx
	push edx
	push esi
	push edi
	push bp
;
	mov bp,di
	mov gs,fs:d_class
	mov bx,fs
	mov ax,es
	mov fs,ax
	mov eax,OFFSET prot_logical_addr
	add al,ds:p_logical_addr_len
	adc ah,0
	add al,gs:addr_len
	adc ah,0
	AllocateSmallGlobalMem
	mov es:prot_class,gs
	mov es:prot_driver,bx
	mov al,gs:addr_len
	mov es:prot_hardware_addr_len,al
	mov al,ds:p_logical_addr_len
	mov es:prot_logical_addr_len,al		
	mov di,OFFSET prot_logical_addr
	movzx cx,ds:p_logical_addr_len
	rep movs byte ptr es:[di],fs:[si]
	mov si,bp
	movzx cx,gs:addr_len
	rep movs byte ptr es:[di],fs:[si]
;
	mov ax,ds
	mov fs,ax
	mov ax,net_data_sel
	mov ds,ax
	EnterSection ds:arp_section
	mov di,fs:p_entry_list
	mov fs:p_entry_list,es
	mov es:prot_next,di
	call CheckArp
	LeaveSection ds:arp_section
	mov ax,es
;
	pop bp
	pop edi
	pop esi
	pop edx
	pop ecx
	pop bx
	pop gs
	pop fs
	pop es
	pop ds
	ret
InsertAddress	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			SendArp
;
;	Purpose:		Send arp request to all drivers
;
;	Parameters:		DS		Protocol
;					FS:ESI	Logical address send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendArp	Proc near
	push ds
	push es
	push fs
	push gs
	pushad
;
	mov ax,ds
	mov gs,ax
	mov ax,net_data_sel
	mov ds,ax
	mov cx,ds:class_count
	mov bx,OFFSET class_arr
	or cx,cx
	jz send_arp_done
send_arp_class_loop:
	push ds
	push bx
	push cx
	mov ds,ds:[bx]
	mov cx,ds:driver_count
	mov bx,OFFSET driver_arr
	or cx,cx
	jz send_arp_class_next
;
	mov eax,4
	add al,gs:p_logical_addr_len
	adc ah,0
	add al,ds:addr_len
	adc ah,0
	add ax,ax
	mov ebp,eax
;
	mov cx,ds:driver_count
	mov bx,OFFSET driver_arr
send_arp_driver_loop:
	push cx
;
	mov ecx,ebp
	push fs
	mov fs,ds:[bx]
	call fs:d_get_buffer
	pop fs
;
	mov ah,ds:class_id
	xor al,al
	mov es:[di].arp_class,ax
	mov dx,gs:p_packet_type
	xchg dl,dh
	mov es:[di].arp_type,dx
	xchg dl,dh
	mov al,ds:addr_len
	mov es:[di].arp_hw_len,al
	mov al,gs:p_logical_addr_len
	mov es:[di].arp_prot_len,al
	mov es:[di].arp_op,100h
	add edi,SIZE arp_data
;
	movzx cx,ds:addr_len
	push fs
	push esi
	mov fs,ds:[bx]
;
	push ds
	call fs:d_address
	rep movs byte ptr es:[edi],ds:[esi]
	pop ds
;	
	pop esi
	pop fs
;	
	movzx cx,gs:p_logical_addr_len
	push si
	mov si,OFFSET p_logical_my_addr
	rep movs byte ptr es:[di],gs:[si]
	pop si
	movzx cx,ds:addr_len
	xor al,al
	rep stosb
	movzx ecx,gs:p_logical_addr_len
	push esi
	rep movs byte ptr es:[edi],fs:[esi]
;
	push fs
	mov fs,ds:[bx]
	mov esi,OFFSET broadcast_addr
	mov ecx,ebp
	xor di,di
	mov dx,806h
	call fs:d_send
	pop fs
	pop esi
;	
	add bx,2
	pop cx
	sub cx,1
	jnz send_arp_driver_loop

send_arp_class_next:	
	pop cx
	pop bx
	pop ds
	add bx,2
	sub cx,1
	jnz send_arp_class_loop
;
send_arp_done:
	popad
	pop gs
	pop fs
	pop es
	pop ds
	ret
SendArp	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			ReceivedArp
;
;	Purpose:		Received arp request
;
;	Parameters:		ES		message
;					FS		driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceivedArp	Proc near
	push ds
	push fs
	push gs
	push ax
	push bx
	push cx
	push dx
	push bp
;
	mov bp,fs
	mov dx,es:ar_data.arp_type
	xchg dl,dh
	mov ax,net_data_sel
	mov ds,ax
	mov cx,ds:protocol_count
	mov bx,OFFSET protocol_arr
	or cx,cx
	jz receive_arp_done
receive_arp_loop:
	mov fs,[bx]
	cmp dx,fs:p_packet_type
	je receive_arp_found
	add bx,2
	loop receive_arp_loop
	jmp receive_arp_done

receive_arp_found:
	mov al,es:ar_data.arp_prot_len
	cmp al,fs:p_logical_addr_len
	jne receive_arp_done
	mov ds,[bx]
	mov ax,es
	mov fs,ax
	mov esi,SIZE arp_data + OFFSET ar_data
	movzx ecx,es:ar_data.arp_hw_len
	add esi,ecx
	push fs
	call FindAddress
	jnc receive_arp_check_dest
;
	mov edi,SIZE arp_data + OFFSET ar_data
	mov fs,bp
	call InsertAddress

receive_arp_check_dest:
	pop fs
	mov bx,bp
;
	mov ax,es:ar_data.arp_op
	xchg al,ah
	cmp ax,1
	jne receive_arp_not_req
; 
	mov di,SIZE arp_data + OFFSET ar_data
	xor ch,ch
	mov cl,es:ar_data.arp_hw_len
	add di,cx
	add di,cx
	mov cl,es:ar_data.arp_prot_len
	add di,cx
	mov si,OFFSET p_logical_my_addr
	repz cmps byte ptr [si],es:[di]
	jnz receive_arp_forward_req
;
	push es
	mov fs,bx
	mov ax,es
	mov gs,ax
;
	mov cx,SIZE arp_data
	xor ah,ah
	mov al,gs:ar_data.arp_hw_len
	add cx,ax
	add cx,ax
	mov al,gs:ar_data.arp_prot_len
	add cx,ax
	add cx,ax
	call fs:d_get_buffer
;
	mov bp,di
	mov cx,SIZE arp_data
	mov si,OFFSET ar_data
	rep movs byte ptr es:[di],gs:[si]
	mov es:[bp].arp_op,200h
;
	movzx ecx,gs:ar_data.arp_hw_len
	push ds
	call fs:d_address
	rep movs byte ptr es:[edi],ds:[esi]
	pop ds
;
	movzx ecx,gs:ar_data.arp_prot_len
	mov si,OFFSET p_logical_my_addr
	rep movsb
;
	mov bp,di
	movzx ecx,gs:ar_data.arp_hw_len
	add cl,gs:ar_data.arp_prot_len
	adc ch,0
	mov si,SIZE arp_data + OFFSET ar_data
	rep movs byte ptr es:[di],gs:[si]
;
	mov ax,es
	mov ds,ax
	movzx esi,bp
	mov cx,SIZE arp_data
	xor ah,ah
	mov al,gs:ar_data.arp_hw_len
	add cx,ax
	add cx,ax
	mov al,gs:ar_data.arp_prot_len
	add cx,ax
	add cx,ax
	mov dx,806h
	call fs:d_send
	pop es
	jmp receive_arp_done

receive_arp_forward_req:
	jmp receive_arp_done

receive_arp_not_req:
	cmp ax,2
	jne receive_arp_done

receive_arp_done:
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	pop gs
	pop fs
	pop ds
	ret
ReceivedArp	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			RegisterNetClass
;
;	Purpose:		Register driver class
;
;	Parameters:		AL		class id
;					CX		Size of address
;					DS:SI	Broadcast address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_net_class_name	DB 'Register Net Class',0

register_net_class	Proc far
	push ds
	push es
	push bx
	push cx
	push si
	push di
;
	push eax
	mov eax,OFFSET broadcast_addr
	add ax,cx
	AllocateSmallGlobalMem
	pop eax
	mov es:class_id,al
	mov es:addr_len,cl
	mov es:driver_count,0
	mov di,OFFSET broadcast_addr
	rep movsb
;
	mov bx,net_data_sel
	mov ds,bx
	mov bx,ds:class_count
	inc ds:class_count
	add bx,bx
	mov ds:[bx].class_arr,es	
;
	pop di
	pop si
	pop cx
	pop bx
	pop es
	pop ds
	ret
register_net_class	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			RegisterNetProtocol
;
;	Purpose:		Register net protocol
;
;	Parameters:		CX		Size of address
;					DX		Packet type
;					DS:SI	My address
;					ES:DI	receiver callback
;						ECX		size
;						DX		packet type
;						DS:SI	source address
;						ES		data selector
;
;	Returns:		BX		Protocol handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_net_protocol_name	DB 'Register Net Protocol',0

register_net_protocol	Proc far
	push ds
	push es
	push cx
	push si
	push di
	push bp
;
	mov bp,es
	push eax
	mov eax,OFFSET p_logical_my_addr
	add ax,cx
	AllocateSmallGlobalMem
	pop eax
	mov word ptr es:p_callback,di
	mov word ptr es:p_callback+2,bp
	mov es:p_logical_addr_len,cl
	mov es:p_packet_type,dx
	mov es:p_entry_list,0
	mov di,OFFSET p_logical_my_addr
	rep movsb
;
	mov ax,net_data_sel
	mov ds,ax
	mov bx,ds:protocol_count
	inc ds:protocol_count
	add bx,bx
	mov ds:[bx].protocol_arr,es
	mov bx,es
;
	pop bp
	pop di
	pop si
	pop cx
	pop es
	pop ds
	ret
register_net_protocol	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			ReceiveData
;
;	Purpose:		Receive data from driver
;
;	Parameters:		FS		driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveData	Proc near
	push ds
	push es
	push gs
	push eax
	push bx
	push ecx
	push dx
	push edi
;
	mov ax,net_data_sel
	mov ds,ax

receive_data_loop:
	ClearSignal
	call fs:d_preview
	jc receive_data_done
	mov edi,ecx
;
	cmp dx,806h
	jne receive_data_not_arp
;
	or ecx,ecx
	jz receive_data_arp_rec
;
	mov eax,ecx
	mov edi,OFFSET ar_data
	add eax,edi
	AllocateSmallGlobalMem
	call fs:d_receive
	call fs:d_remove
	jmp receive_data_handle_arp

receive_data_arp_rec:
	call fs:d_receive
	call fs:d_remove
;
	push ds
	mov esi,edi
	mov ax,es
	mov ds,ax
	mov eax,ecx
	mov edi,OFFSET ar_data
	add eax,edi
	AllocateSmallGlobalMem
	rep movs byte ptr es:[edi],[esi]
	mov bx,es
	mov ax,ds
	mov es,ax
	pop ds
	FreeMem
	mov es,bx

receive_data_handle_arp:
	mov es:ar_driver,fs
	EnterSection ds:arp_section
	mov ax,ds:arp_rec_list
	or ax,ax
	je ins_ar_empty
;
	push ds
	mov ds,ax
	mov si,ds:ar_prev
	mov ds:ar_prev,es
	mov ds,si
	mov ds:ar_next,es
	mov es:ar_next,ax
	mov es:ar_prev,si
	pop ds
	jmp ins_ar_done

ins_ar_empty:
	mov es:ar_next,es
	mov es:ar_prev,es
	mov ds:arp_rec_list,es

ins_ar_done:
	xor ax,ax
	mov es,ax
	LeaveSection ds:arp_section
	mov bx,ds:arp_thread
	Signal
	jmp receive_data_loop

receive_data_not_arp:
	mov cx,ds:protocol_count
	or cx,cx
	jz receive_data_remove
	mov bx,OFFSET protocol_arr
receive_data_prot_loop:
	mov gs,[bx]
	cmp dx,gs:p_packet_type
	jne receive_data_prot_next
;
	or edi,edi
	jz receive_data_norm_rec
;
	mov ecx,edi
	mov eax,ecx
	AllocateSmallGlobalMem
	xor di,di

receive_data_norm_rec:
	call fs:d_receive
	call fs:d_remove
	call gs:p_callback
	xor ax,ax
	mov es,ax
	jmp receive_data_loop

receive_data_prot_next:
	add bx,2
	loop receive_data_prot_loop

receive_data_remove:
	or edi,edi
	jz receive_data_norm_remove
;
	mov ecx,edi
    call fs:d_remove
    jmp receive_data_loop

receive_data_norm_remove:
	call fs:d_receive
	call fs:d_remove
	FreeMem
	jmp receive_data_loop

receive_data_done:
	pop edi
	pop dx
	pop ecx
	pop bx
	pop eax
	pop gs
	pop es
	pop ds
	ret
ReceiveData	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			NetThread
;
;	Purpose:		Net thread
;
;	Parameters:		BX		Driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetThread:
	mov fs,bx
	GetThread
	mov fs:d_thread,ax
net_thread_loop:
	call ReceiveData
	WaitForSignal
	jmp net_thread_loop

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			RegisterNetDriver
;
;	Purpose:		Register net driver
;
;	Parameters:		AL		Class
;					ECX		Max data size
;					DS:SI	Dispatch table
;					ES:DI	Driver name
;
;	Returns:		BX		Driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_net_driver_name	DB 'Register Net Driver',0

register_net_driver	Proc far
	push ds
	push fs
	push ax
	push cx
	push si
;
	push es
	push di
;
	push eax
	mov eax,SIZE driver_data
	AllocateSmallGlobalMem
	pop eax
	mov es:d_packet_size,ecx
	mov di,OFFSET d_preview
	mov cx,SIZE driver_data - OFFSET d_preview
	rep movsb
;
	mov bx,net_data_sel
	mov ds,bx
	mov cx,ds:class_count
	xor bx,bx
	or cx,cx
	jz register_driver_done
	mov bx,OFFSET class_arr
register_driver_loop:
	mov fs,[bx]
	cmp al,fs:class_id
	je register_driver_insert
	add bx,2
	loop register_driver_loop
	xor bx,bx
	jmp register_driver_done

register_driver_insert:
	mov bx,fs:driver_count
	inc fs:driver_count
	add bx,bx
	mov fs:[bx].driver_arr,es
	mov es:d_class,fs
	mov bx,es

register_driver_done:
;
	pop di
	pop es
;
	mov ax,cs
	mov ds,ax
	mov si,OFFSET NetThread
	mov cx,400h
	mov ax,20
	CreateThread
;
	pop si
	pop cx
	pop ax
	pop fs
	pop ds
	ret
register_net_driver	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			RegisterPppDriver
;
;	Purpose:		Register PPP driver
;
;	Parameters:		DS:SI	Dispatch table
;
;	Returns:		BX		Driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_ppp_driver_name	DB 'Register PPP Driver',0

register_ppp_driver	Proc far
	push ds
	push es
	push ax
	push cx
	push si
	push di
;
	push eax
	mov eax,SIZE driver_data
	AllocateSmallGlobalMem
	pop eax
	mov es:d_packet_size,ecx
	mov di,OFFSET d_preview
	mov cx,SIZE driver_data - OFFSET d_preview
	rep movsb
;
	mov bx,net_data_sel
	mov ds,bx
	mov ds:ppp_handle,es
	mov bx,es
;
	pop di
	pop si
	pop cx
	pop ax
	pop es
	pop ds
	ret
register_ppp_driver	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			AddNetSourceAddress
;
;	Purpose:		Add source address of packet
;
;	Parameters:		BX		protocol handle
;					ES		packet
;                   FS      driver
;					EDI		source address offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_net_source_address_name	DB 'Add Net Source Address',0

add_net_source_address	Proc far
	push ds
	push fs
	push ax
	push esi
	push edi
	push bp
;
	mov bp,fs
	mov ds,bx
	mov ax,es
	mov fs,ax
	mov esi,edi
	call FindAddress
	jnc add_src_address_done
;
	mov fs,bp
	push esi
	call fs:d_get_address
	mov edi,esi
	pop esi
	call InsertAddress

add_src_address_done:
    pop bp
	pop edi
	pop esi
	pop ax
	pop fs
	pop ds
	ret
add_net_source_address	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			GetNetBuffer
;
;	Purpose:		Get network buffer
;
;	Parameters:		BX		protocol handle
;					ECX		size of data
;					DS:ESI	dest address
;
;	returns:		ES:EDI	address of data
;					NC	success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_net_buffer_name	DB 'Get Net Buffer',0

get_net_buffer	Proc far
	push fs
	push eax
;
	mov ax,ds
	mov fs,ax
	mov ds,bx
	call FindAddress
	jnc get_net_buffer_do
;
	push bx
	push es
	push cx
	push si
;
	movzx eax,ds:p_logical_addr_len
	add ax,OFFSET arp_logical_addr
	AllocateSmallGlobalMem
	mov es:arp_protocol,ds
	mov es:arp_retries,3
	mov es:arp_timeout,0
	mov es:arp_timeout+4,0
	GetThread
	mov es:arp_owner,ax
	mov al,ds:p_logical_addr_len
	mov es:arp_logical_addr_len,al
	mov di,OFFSET arp_logical_addr
	movzx cx,al
	rep movs byte ptr es:[di],fs:[si]
;
	mov ax,net_data_sel
	mov ds,ax
	EnterSection ds:arp_section
	mov ax,ds:arp_send_list
	or ax,ax
	je get_buf_arp_empty
;
    push fs
	mov fs,ax
	mov si,fs:arp_prev
	mov fs:arp_prev,es
	mov fs,si
	mov fs:arp_next,es
	mov es:arp_next,ax
	mov es:arp_prev,si
	pop fs
	jmp get_buf_arp_done

get_buf_arp_empty:
	mov es:arp_next,es
	mov es:arp_prev,es
	mov ds:arp_send_list,es

get_buf_arp_done:
	LeaveSection ds:arp_section
	pop si
	pop cx
	pop es
	mov bx,ds:arp_thread
	Signal
	pop bx
;	
	mov ds,bx
	WaitForSignal
	call FindAddress
	jc get_net_buf_done

get_net_buffer_do:
	mov ds,ax
	mov fs,ds:prot_driver
	call fs:d_get_buffer
	clc

get_net_buf_done:
	pop eax
	pop fs
	ret
get_net_buffer	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			SendNet
;
;	Purpose:		Send data to network
;
;	Parameters:		BX		protocol handle
;					ECX		size of data
;					DS:ESI	dest address
;					ES		address of data
;
;	returns:		NC	success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_net_name	DB 'Send Net',0

send_net	Proc far
	push fs
	push eax
	push di
;
	mov ax,ds
	mov fs,ax
	mov ds,bx
	call FindAddress
	jnc send_start
;
	push bx
	push es
	push cx
	push si
;
	movzx eax,ds:p_logical_addr_len
	add ax,OFFSET arp_logical_addr
	AllocateSmallGlobalMem
	mov es:arp_protocol,ds
	mov es:arp_retries,3
	mov es:arp_timeout,0
	mov es:arp_timeout+4,0
	GetThread
	mov es:arp_owner,ax
	mov al,ds:p_logical_addr_len
	mov es:arp_logical_addr_len,al
	mov di,OFFSET arp_logical_addr
	movzx cx,al
	rep movs byte ptr es:[di],fs:[si]
;
	mov ax,net_data_sel
	mov ds,ax
	EnterSection ds:arp_section
	mov ax,ds:arp_send_list
	or ax,ax
	je ins_arp_empty
;
    push fs
	mov fs,ax
	mov si,fs:arp_prev
	mov fs:arp_prev,es
	mov fs,si
	mov fs:arp_next,es
	mov es:arp_next,ax
	mov es:arp_prev,si
	pop fs
	jmp ins_arp_done

ins_arp_empty:
	mov es:arp_next,es
	mov es:arp_prev,es
	mov ds:arp_send_list,es

ins_arp_done:
	LeaveSection ds:arp_section
	pop si
	pop cx
	pop es
	mov bx,ds:arp_thread
	Signal
	pop bx
;
    WaitForSignal
    mov ds,bx	
    call FindAddress
    jc send_done

send_start:
	push dx
	push esi
	mov dx,ds:p_packet_type
	mov ds,ax
	mov fs,ds:prot_driver
	movzx eax,ds:prot_logical_addr_len
	mov esi,OFFSET prot_logical_addr
	add esi,eax
	xor di,di
	call fs:d_send
	pop esi
	pop dx

send_done:
	xor ax,ax
	mov ds,ax
;
	pop di
	pop eax
	pop fs
	ret
send_net	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			GetBroadcastBuffer
;
;	Purpose:		Get a broadcast buffer
;
;	Parameters:		FS		driver handle
;					ECX		size of data
;					ES:EDI	address of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_broadcast_buffer_name	DB 'Get Broadcast Buffer',0

get_broadcast_buffer	Proc far
	call fs:d_get_buffer
	ret
get_broadcast_buffer	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			SendBroadcast
;
;	Purpose:		Send broadcast message
;
;	Parameters:		BX		protocol
;					FS		driver handle
;					ECX		size of data
;					ES:EDI	address of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_broadcast_name	DB 'Send Broadcast',0

send_broadcast	Proc far
	push ds
	push esi
;
	mov ds,bx
	mov dx,ds:p_packet_type
	mov ds,fs:d_class
	mov esi,OFFSET broadcast_addr
	call fs:d_send
;
	pop esi
	pop ds
	ret
send_broadcast	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			NetBroadcast
;
;	Purpose:		Broadcast to all devices
;
;	Parameters:		ES:DI	Callback for each driver
;						FS		driver handle
;						GS		passed unchanged
;						EDX		passed unchanged
;						ESI		passed unchanged
;						EBP		passed unchanged
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

net_broadcast_name	DB 'Net Broadcast',0

net_broadcast	Proc far
	push ds
	push fs
	pushad
;
	mov ax,net_data_sel
	mov ds,ax
	mov cx,ds:class_count
	mov bx,OFFSET class_arr
	or cx,cx
	jz net_br_done

net_br_class_loop:
	push ds
	push bx
	push cx
	mov ds,ds:[bx]
	mov cx,ds:driver_count
	mov bx,OFFSET driver_arr
	or cx,cx
	jz net_br_class_next
;
	mov cx,ds:driver_count
	mov bx,OFFSET driver_arr

net_br_driver_loop:
	push cx
;
	push ds
	push es
	push gs
	pushad
;
	mov fs,ds:[bx]
	push cs
	push OFFSET net_br_driver_next
	push es
	push di
	retf

net_br_driver_next:
	popad
	pop gs
	pop es
	pop ds
;
	add bx,2
	pop cx
	sub cx,1
	jnz net_br_driver_loop

net_br_class_next:	
	pop cx
	pop bx
	pop ds
	add bx,2
	sub cx,1
	jnz net_br_class_loop

net_br_done:
	popad
	pop fs
	pop ds
	ret
net_broadcast	ENDP

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			GetPppBuffer
;
;	Purpose:		Get PPP buffer
;
;	Parameters:		BX		protocol handle
;					ECX		size of data
;
;	returns:		ES:EDI	address of data
;					NC	success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ppp_buffer_name	DB 'Get Ppp Buffer',0

get_ppp_buffer	Proc far
	push fs
;
	mov ax,net_data_sel
	mov fs,ax
	mov ax,fs:ppp_handle
	or ax,ax
	jz get_ppp_done
;
	mov fs,ax
	call fs:d_get_buffer

get_ppp_done:
	pop fs
	ret
get_ppp_buffer	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			SendPpp
;
;	Purpose:		Send data to PPP driver
;
;	Parameters:		ECX		size of data
;					ES		address of data
;
;	returns:		NC	success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_ppp_name	DB 'Send PPP',0

send_ppp	Proc far
	push ds
	push fs
	push eax
	push di
;
	mov ax,net_data_sel
	mov ds,ax
	mov ax,ds:ppp_handle
	or ax,ax
	jz send_ppp_done
;
	mov fs,ax
	xor di,di
	call fs:d_send

send_ppp_done:
	pop di
	pop eax
	pop fs
	pop ds
	ret
send_ppp	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			NetReceived
;
;	Purpose:		Net received callback. Called from ISR
;
;	Parameters:		BX		Driver handle
;					
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

net_received_name	DB 'Net Received',0

net_received	Proc far
	push ds
	push ax
	push bx
	mov ax,net_data_sel
	mov ds,ax
	cmp bx,ds:ppp_handle
	jne net_received_normal
;
	push fs
	mov fs,bx
	call ReceiveData
	pop fs
	jmp net_received_done

net_received_normal:
	mov ds,bx
	mov bx,ds:d_thread
	Signal

net_received_done:
	pop bx
	pop ax
	pop ds
	ret
net_received	Endp

PAGE
	    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 	Name:			DefineProtocolAddress
;
;	Purpose:		Define protocol address
;
;	Parameters:		BX		Driver handle
;                   DS:ESI  Address
;					
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_protocol_address_name	DB 'Define Protocol Address',0

define_protocol_address	Proc far
	push ds
	push es
	push ecx
	push esi
	push edi
;
    mov es,bx
    movzx ecx,es:p_logical_addr_len
    mov edi,OFFSET p_logical_my_addr
    rep movs byte ptr es:[edi],[esi]
;	
    pop edi
    pop esi
    pop ecx
    pop es
	pop ds
	ret
define_protocol_address Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ResendTimeout
;
;		description:	Send a signal to arp thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResendTimeout	Proc far
	mov bx,net_data_sel
	mov ds,bx
	mov bx,ds:arp_thread
	Signal
	ret
ResendTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			arp_thread
;
;		DESCRIPTION:    arp thread
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

arp_thread_name	DB 'ARP',0

arp_thread_pr:
	mov ax,net_data_sel
	mov ds,ax
	GetThread
	mov ds:arp_thread,ax

arp_thread_loop:
	WaitForSignal
	mov bx,ds:arp_thread
	StopTimer

arp_rec_loop:
	mov ax,net_data_sel
	mov ds,ax
	EnterSection ds:arp_section
	mov ax,ds:arp_rec_list
	or ax,ax
	jz arp_rec_done
;
	mov es,ax
	mov di,es:ar_next
	cmp di,ds:arp_rec_list
	mov ds:arp_rec_list,di
	mov si,es:ar_prev
	mov fs,di
	mov fs:ar_prev,si
	mov fs,si
	mov fs:ar_next,di
	jne arp_rec_handle
;
	mov ds:arp_rec_list,0

arp_rec_handle:
	LeaveSection ds:arp_section
	mov fs,es:ar_driver
	call ReceivedArp
	FreeMem
	jmp arp_rec_loop

arp_rec_done:
	mov bx,ds:arp_send_list
	or bx,bx
	jz arp_send_done
;
	mov cx,bx
	GetSystemTime

arp_send_loop:
	mov es,bx
	mov ebx,es:arp_timeout
	sub ebx,eax
	mov ebx,es:arp_timeout+4
	sbb ebx,edx
	jnc arp_send_next
;
	sub es:arp_retries,1
	jz arp_send_remove
;
	LeaveSection ds:arp_section
	add eax,1193 * 250 
	adc edx,0
	mov es:arp_timeout,eax
	mov es:arp_timeout+4,edx
	mov ds,es:arp_protocol
	mov ax,es
	mov fs,ax
	mov esi,OFFSET arp_logical_addr
	call SendArp
	jmp arp_rec_loop

arp_send_remove:
	mov ds:arp_send_list,es
	mov di,es:arp_next
	cmp di,ds:arp_send_list
	mov ds:arp_send_list,di
	mov si,es:arp_prev
	mov fs,di
	mov fs:arp_prev,si
	mov fs,si
	mov fs:arp_next,di
	jne arp_send_remove_done
;
	mov ds:arp_send_list,0

arp_send_remove_done:
	LeaveSection ds:arp_section
	mov bx,es:arp_owner
	Signal
	xor ax,ax
	mov fs,ax
	FreeMem
	jmp arp_rec_loop

arp_send_next:
	mov bx,es:arp_next
	cmp bx,cx
	jne arp_send_loop
;
	mov bx,cs
	mov es,bx
	mov di,OFFSET ResendTimeout
	GetSystemTime
	add eax,1193 * 250
	adc edx,0
	mov bx,ds:arp_thread
	StartTimer
	
arp_send_done:
	mov ax,ds:arp_answ_list
	or ax,ax
	jz arp_answ_done
;
	mov es,ax
	mov di,es:arp_next
	cmp di,ds:arp_answ_list
	mov ds:arp_answ_list,di
	mov si,es:arp_prev
	mov fs,di
	mov fs:arp_prev,si
	mov fs,si
	mov fs:arp_next,di
	jne arp_answ_handle
;
	mov ds:arp_answ_list,0

arp_answ_handle:
	LeaveSection ds:arp_section
	jmp arp_rec_loop
	
arp_answ_done:
	LeaveSection ds:arp_section
	jmp arp_thread_loop

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetTimestamp
;
;		description:	Get pcap compatible timestamp
;
;       returns:        EDX:EAX Timestamp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetTimestamp    Proc near
    GetTime
    push eax
    BinaryToTime
;    
    push ax
    PassedDays      ; ax = passed days
    movzx eax,ax
    mov edx,24
    mul edx
    movzx edx,bh
    add eax,edx
    mov edx,60
    mul edx
    movzx edx,bl
    add eax,edx
    pop bx
    mov edx,60
    mul edx
    movzx edx,bh
    add edx,eax 
;
    pop ebx
    push edx
;    
    mov eax,3600
    mul ebx
    mov ebx,1000000
    mul ebx
    mov eax,edx
;    
    pop edx  
    ret
GetTimestamp    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NotifyEthernetPacket
;
;		description:	Notify reception of ethernet packet
;
;       parameters:     ECX     Size of packet
;                       ES:EDI  Pointer to packet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_ethernet_packet_name DB 'Notify Ethernet Packet', 0

notify_ethernet_packet	Proc far
	ret
notify_ethernet_packet	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartNetCapture
;
;		description:	Start capturing net-packets
;
;       parameters:     BX      File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_net_capture_name DB 'Start Net Capture', 0

start_net_capture	Proc
	retf32
start_net_capture	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StopNetCapture
;
;		description:	Stop capturing net-packets
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_net_capture_name DB 'Stop Net Capture', 0

stop_net_capture	Proc
	retf32
stop_net_capture	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_net
;
;		DESCRIPTION:    init net driver
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_net	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET arp_thread_pr
	mov di,OFFSET arp_thread_name
	mov ax,3
	mov cx,256
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_net	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		DESCRIPTION:    Init net driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

internet_broadcast	DB -1, -1, -1, -1
ether_broadcast		DB -1, -1, -1, -1, -1, -1
sernet_broadcast	DB -1

init	PROC far
	push ds
	push es
	pusha
;
	mov bx,net_code_sel
	InitDevice
;
	mov eax,SIZE net_data
	mov bx,net_data_sel
	AllocateFixedSystemMem
	mov es,bx
	mov es:class_count,0
	mov es:protocol_count,0
	mov es:ppp_handle,0
	mov es:arp_rec_list,0
	mov es:arp_send_list,0
	mov es:arp_answ_list,0
	mov es:arp_thread,0
	InitSection es:arp_section
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_net
	HookInitTasking
;
	mov si,OFFSET register_net_class
	mov di,OFFSET register_net_class_name
	xor cl,cl
	mov ax,register_net_class_nr
	RegisterOsGate
;
	mov si,OFFSET register_net_protocol
	mov di,OFFSET register_net_protocol_name
	xor cl,cl
	mov ax,register_net_protocol_nr
	RegisterOsGate
;
	mov si,OFFSET register_net_driver
	mov di,OFFSET register_net_driver_name
	xor cl,cl
	mov ax,register_net_driver_nr
	RegisterOsGate
;
	mov si,OFFSET register_ppp_driver
	mov di,OFFSET register_ppp_driver_name
	xor cl,cl
	mov ax,register_ppp_driver_nr
	RegisterOsGate
;
	mov si,OFFSET define_protocol_address
	mov di,OFFSET define_protocol_address_name
	xor cl,cl
	mov ax,define_protocol_addr_nr
	RegisterOsGate
;
	mov si,OFFSET get_net_buffer
	mov di,OFFSET get_net_buffer_name
	xor cl,cl
	mov ax,get_net_buffer_nr
	RegisterOsGate
;
	mov si,OFFSET send_net
	mov di,OFFSET send_net_name
	xor cl,cl
	mov ax,send_net_nr
	RegisterOsGate
;
	mov si,OFFSET get_broadcast_buffer
	mov di,OFFSET get_broadcast_buffer_name
	xor cl,cl
	mov ax,get_broadcast_buffer_nr
	RegisterOsGate
;
	mov si,OFFSET send_broadcast
	mov di,OFFSET send_broadcast_name
	xor cl,cl
	mov ax,send_broadcast_nr
	RegisterOsGate
;
	mov si,OFFSET net_broadcast
	mov di,OFFSET net_broadcast_name
	xor cl,cl
	mov ax,net_broadcast_nr
	RegisterOsGate
;
	mov si,OFFSET get_ppp_buffer
	mov di,OFFSET get_ppp_buffer_name
	xor cl,cl
	mov ax,get_ppp_buffer_nr
	RegisterOsGate
;
	mov si,OFFSET send_ppp
	mov di,OFFSET send_ppp_name
	xor cl,cl
	mov ax,send_ppp_nr
	RegisterOsGate
;
	mov si,OFFSET net_received
	mov di,OFFSET net_received_name
	xor cl,cl
	mov ax,net_received_nr
	RegisterOsGate
;
	mov si,OFFSET add_net_source_address
	mov di,OFFSET add_net_source_address_name
	xor cl,cl
	mov ax,add_net_source_address_nr
	RegisterOsGate
;
	mov si,OFFSET notify_ethernet_packet
	mov di,OFFSET notify_ethernet_packet_name
	xor cl,cl
	mov ax,notify_ethernet_packet_nr
	RegisterOsGate
;
	mov si,OFFSET ether_broadcast
	mov cx,6
	mov al,1
	RegisterNetClass
;
	mov si,OFFSET sernet_broadcast
	mov cx,1
	mov al,100
	RegisterNetClass
;
	mov si,OFFSET internet_broadcast
	mov cx,4
	mov al,0
	RegisterNetClass
;
	mov si,OFFSET start_net_capture
	mov di,OFFSET start_net_capture_name
	xor dx,dx
	mov ax,start_net_capture_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET stop_net_capture
	mov di,OFFSET stop_net_capture_name
	xor dx,dx
	mov ax,stop_net_capture_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	ENDP

code    ENDS

        END init
