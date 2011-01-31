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

Reverse MACRO
        xchg al,ah
        rol eax,16
        xchg al,ah
                ENDM

dhcp_option     STRUC

dhcp_opt_next   DW ?
dhcp_opt_code   DB ?
dhcp_opt_callb  DD ?

dhcp_option     ENDS

dhcp_serv_data  STRUC

dsd_orig_ident  DD ?
dsd_local_ip    DD ?
dsd_driver_sel  DW ?
dsd_hw_type     DB ?
dsd_hw_len      DB ?
dsd_hw_data     DB 10h DUP(?)

dhcp_serv_data  ENDS

data    SEGMENT byte public 'DATA'

dhcp_ident                      DD ?
dhcp_wanted_ip          DD ?
dhcp_server                     DD ?
dhcp_option_list        DW ?
dhcp_driver_sel     DW ?
dhcp_ip             DD ?
dhcp_ip2            DD ?
;dhcp_mask2          DD ?
;dhcp_gateway2       DD ?
dhcp_serv_arr       DW 256 DUP(?)

dhcp_enabled        DB ?

data    ENDS

    extrn is_ip_in_use:near
        extrn define_ip:near
        extrn get_gateway_driver:near
        extrn ping_gateway:near
        extrn GetIPNumber:near
        extrn GetValue:near

code    SEGMENT byte public 'CODE'

.386p
        
        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CalcChecksum
;
;               DESCRIPTION:    Calculate checksum for UDP
;
;               PARAMETERS:             AX              Checksum in
;                                               CX              Size of data
;                                               ES:DI   Data
;
;               RETURNS:                AX              Checksum out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcChecksum    Proc near
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
CalcChecksum    Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   CreateDhcpReqBroadcast
;
;       Purpose:                Create a req DHCP broadcast header
;
;       Parameters:             CX                      Number of bytes to allocate
;                                       FS                      Driver selector
;
;       Returns:                NC                      Ok
;                                       ES:DI           Allocate buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ip_options      DB 0

CreateDhcpReqBroadcast  Proc near
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
        jc create_req_br_done
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

create_req_br_done:
        pop esi
        pop ecx
        pop ax
        pop ds
        ret
CreateDhcpReqBroadcast  Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   CreateDhcpReplyBroadcast
;
;       Purpose:                Create a reply DHCP broadcast header
;
;       Parameters:             CX                      Number of bytes to allocate
;                                       FS                      Driver selector
;
;       Returns:                NC                      Ok
;                                       ES:DI           Allocate buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDhcpReplyBroadcast        Proc near
        push ds
        push ax
        push ecx
        push edx
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
        jc create_reply_br_done
;       
        mov ax,68
        xchg al,ah
        mov es:[edi].udp_dest,ax
;
        mov ax,67
        xchg al,ah
        mov es:[edi].udp_source,ax
;
    GetIpAddress
    mov es:[di-8],edx   
        add edi,8
        clc

create_reply_br_done:
        pop esi
        pop edx
        pop ecx
        pop ax
        pop ds
        ret
CreateDhcpReplyBroadcast        Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   SendDhcpBroadcast
;
;       Purpose:                Send DHCP broadcast message
;
;       Parameters:             ES:EDI          Buffer
;                                       CX                      Number of bytes to send
;                                       FS                      Driver selector
;
;       Returns:                NC                      Ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendDhcpBroadcast       Proc near
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
SendDhcpBroadcast       Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   FindServer
;
;       Purpose:                Find server selector
;
;       Parameters:             DS:SI   DHCP data
;                   GS      Driver selector
;
;   Returns:        AX      Server selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindServer      Proc near
    push es
    push fs
    push bx
    push cx
    push dx
    push bp
;
    mov ax,SEG data
    mov fs,ax
    mov bp,OFFSET dhcp_serv_arr+4
    mov cx,256-2

find_serv_loop:
    push cx
    mov ax,fs:[bp]
    or ax,ax
    jz find_serv_next
;
    mov es,ax
    mov dl,[si].dhcp_hw_type
    cmp dl,es:dsd_hw_type
    jne find_serv_next
;
    movzx cx,[si].dhcp_hw_len
    cmp cl,es:dsd_hw_len
    jne find_serv_next
;
    or cl,cl
    je find_serv_next
;    
    xor bx,bx

find_serv_match:
    mov dl,[bx+si].dhcp_hw_addr
    cmp dl,es:[bx].dsd_hw_data
    jne find_serv_next
;
    inc bx
    loop find_serv_match
;
    clc
    pop cx
    jmp find_serv_done

find_serv_next:
    pop cx
    add bp,2
    loop find_serv_loop

find_serv_fail:
    xor ax,ax        
    stc

find_serv_done:
    pop bp
    pop dx
    pop cx
    pop bx
    pop fs
    pop es
    ret
FindServer  Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   InitServerSel
;
;       Purpose:                Init server selector
;
;       Parameters:             DS:SI   Original UDP data
;                   FS      Server sel
;                   GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitServerSel   Proc near
    push eax
    push bx
    push cx
;    
        mov eax,[si].dhcp_id
        mov fs:dsd_orig_ident,eax
    mov fs:dsd_driver_sel,gs
    mov al,[si].dhcp_hw_type
    mov fs:dsd_hw_type,al
    movzx cx,[si].dhcp_hw_len
    cmp cl,10h
    jb init_serv_len_ok
;
    mov cl,10h

init_serv_len_ok:    
    mov fs:dsd_hw_len,cl
;    
    or cl,cl
    jz init_serv_done
;    
    xor bx,bx

init_serv_loop:
    mov al,[bx+si].dhcp_hw_addr
    mov fs:[bx].dsd_hw_data,al
    inc bx
    loop init_serv_loop

init_serv_done:
    pop cx
    pop bx
    pop eax
    ret
InitServerSel   Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   CreateServerSel
;
;       Purpose:                Create, initializr & link server selector
;
;       Parameters:             DS:SI   Original UDP data
;                   GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateServerSel Proc near
    push ds
    push es
    push fs
    push eax
    push bx
    push cx
;   
    call FindServer
    jc create_serv_new

create_serv_update:
    mov fs,ax
    call InitServerSel
    jmp create_serv_done
    
create_serv_new:
        mov eax,SIZE dhcp_serv_data
        AllocateSmallGlobalMem
        mov ax,es
        mov fs,ax
    call InitServerSel
;
        mov ax,SEG data
        mov ds,ax
;
    mov bx,OFFSET dhcp_serv_arr+4
    mov edx,ds:dhcp_ip2

create_serv_slot_loop:
    mov ax,ds:[bx]
    or ax,ax
    jz create_serv_slot_ok
;
    add edx,1000000h
    add bx,2
    loop create_serv_slot_loop
;   
    xor ax,ax
    mov fs,ax
    FreeMem
    stc
    jmp create_serv_done
    
create_serv_slot_ok:
    mov fs:dsd_local_ip,edx
    mov ds:[bx],fs
    clc

create_serv_done:   
    pop cx
    pop bx
    pop eax
    pop fs
    pop es
    pop ds
    ret
CreateServerSel Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   SetHwAddress
;
;       Purpose:                Set hardware address
;
;       Parameters:             DS:SI   source DHCP header
;                   ES:DI   dest DHCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetHwAddress    Proc near
    push eax
    push cx
    push si
        push di
;    
        mov cx,34h
        add si,OFFSET dhcp_hw_addr
        add di,OFFSET dhcp_hw_addr
        xor eax,eax
        rep movsd
;
        pop di
    pop si
        pop cx
    pop eax
    ret
SetHwAddress    Endp    

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServLeaseSize
;
;       Purpose:                Size of IP lease time
;
;       Returns:                CX                      Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServLeaseSize   Proc near
        mov cx,6
        ret
ServLeaseSize   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServLeaseData
;
;       Purpose:                Copy IP lease time
;
;       Parameters:             FS          Dhcp server data selector
;                   ES:DI               Position to copy at
;                   CX          Byte remaining
;
;       Returns:                ES:DI           New dest
;                   CX          new size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServLeaseData   Proc near
        push eax
;
        mov al,51
        stosb
        mov al,4
        stosb
        mov eax,-1
        stosd
        sub cx,6
;
        pop eax
        ret
ServLeaseData   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServRenewSize
;
;       Purpose:                Size of renewal msg
;
;       Returns:                CX                      Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServRenewSize   Proc near
        mov cx,6
        ret
ServRenewSize   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServRenewData
;
;       Purpose:                Add renew 
;
;       Parameters:             FS          Dhcp server data selector
;                   ES:DI               Position to copy at
;                   CX          Byte remaining
;
;       Returns:                ES:DI           New dest
;                   CX          new size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServRenewData   Proc near
        push eax
;
        mov al,58
        stosb
        mov al,4
        stosb
        mov eax,0FFFFFF7Fh
        stosd
        sub cx,6
;
        pop eax
        ret
ServRenewData   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServRebindSize
;
;       Purpose:                Size of rebind msg
;
;       Returns:                CX                      Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServRebindSize  Proc near
        mov cx,6
        ret
ServRebindSize  Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServRebindData
;
;       Purpose:                Add rebind
;
;       Parameters:             FS          Dhcp server data selector
;                   ES:DI               Position to copy at
;                   CX          Byte remaining
;
;       Returns:                ES:DI           New dest
;                   CX          new size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServRebindData  Proc near
        push eax
;
        mov al,59
        stosb
        mov al,4
        stosb
        mov eax,0F9FFFFDFh
        stosd
        sub cx,6
;
        pop eax
        ret
ServRebindData  Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqIpSize
;
;       Purpose:                Size of client IP
;
;       Parameters:             ES:DI       DHCP header
;
;       Returns:                CX                      Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqIpSize   Proc near
        mov cx,6
        ret
ServReqIpSize   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqIpData
;
;       Purpose:                Copy client IP
;
;       Parameters:             FS          Dhcp server data selector
;                   ES:DI               Position to copy at
;                   CX          Byte remaining
;
;       Returns:                ES:DI           New position
;                   CX          Byte remaining
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqIpData   Proc near
        push ds
        push eax
;
        mov al,50
        stosb
        mov al,4
        stosb
;
        mov eax,fs:dsd_local_ip
        stosd
    sub cx,6
;
        pop eax
        pop ds
        ret
ServReqIpData   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqMaskSize
;
;       Purpose:                Size of net mask
;
;       Parameters:             ES:DI       DHCP header
;
;       Returns:                CX                      Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqMaskSize Proc near
        mov cx,6
        ret
ServReqMaskSize Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqMaskData
;
;       Purpose:                Add net mask
;
;       Parameters:             FS          Dhcp server data selector
;                   ES:DI               Position to copy at
;                   CX          Byte remaining
;
;       Returns:                ES:DI           New position
;                   CX          Byte remaining
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqMaskData Proc near
        push eax
        push edx
;
        mov al,1
        stosb
        mov al,4
        stosb
;
    GetIpMask
    mov eax,edx
        stosd
    sub cx,6
;
    pop edx
        pop eax
        ret
ServReqMaskData Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqGwSize
;
;       Purpose:                Size of gateway
;
;       Parameters:             ES:DI       DHCP header
;
;       Returns:                CX                      Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqGwSize   Proc near
        mov cx,6
        ret
ServReqGwSize   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqGwData
;
;       Purpose:                Add gateway
;
;       Parameters:             FS          Dhcp server data selector
;                   ES:DI               Position to copy at
;                   CX          Byte remaining
;
;       Returns:                ES:DI           New position
;                   CX          Byte remaining
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqGwData   Proc near
        push ds
        push eax
        push edx
;
        mov al,3
        stosb
        mov al,4
        stosb
;
    GetIpAddress
    mov eax,edx
        stosd
    sub cx,6
;
    pop edx
        pop eax
        pop ds
        ret
ServReqGwData   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqDnsSize
;
;       Purpose:                Size DNS
;
;       Parameters:             ES:DI       DHCP header
;
;       Returns:                CX                      Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqDnsSize  Proc near
    push edx
;
        mov cx,2
    GetDns
    or eax,eax
    jz ServReqDnsSizeDone
;
    add cx,4
    or edx,edx
    jz ServReqDnsSizeDone
;
    add cx,4

ServReqDnsSizeDone:   
    pop edx
        ret
ServReqDnsSize  Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqDnsData
;
;       Purpose:                Add dns servers
;
;       Parameters:             FS          Dhcp server data selector
;                   ES:DI               Position to copy at
;                   CX          Byte remaining
;
;       Returns:                ES:DI           New position
;                   CX          Byte remaining
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqDnsData  Proc near
        push eax
        push edx
;
        mov al,6
        stosb
;       
    push cx
    call ServReqDnsSize
    mov al,cl
    sub al,2
        stosb
        pop cx
        sub cx,2
;
    GetDns
    or eax,eax
    jz ServReqDnsDataDone
;
        stosd
        mov eax,edx
        sub cx,4
;       
    or eax,eax
    jz ServReqDnsDataDone
;
        stosd
        sub cx,4
        
ServReqDnsDataDone:
    pop edx
        pop eax
        ret
ServReqDnsData  Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqIdSize
;
;       Purpose:                Size server ID field
;
;       Parameters:             ES:DI       DHCP header
;
;       Returns:                CX                      Size of server ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqIdSize   Proc near
        mov cx,6
        ret
ServReqIdSize   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServReqIdData
;
;       Purpose:                Add server ID field
;
;       Parameters:             FS          Dhcp server data selector
;                   ES:DI               Position to copy at
;                   CX          Byte remaining
;
;       Returns:                ES:DI           New position
;                   CX          Byte remaining
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqIdData   Proc near
        push ds
        push eax
        push edx
;
        mov al,54
        stosb
        mov al,4
        stosb
;
    GetIpAddress
    mov eax,edx
        stosd
    sub cx,6
;
    pop edx
        pop eax
        pop ds
        ret
ServReqIdData   Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReceiveDiscover
;
;       Purpose:                Receive discover
;
;       Parameters:             ES:EDI  UDP data
;                   GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                               data-proc

DiscReqOptTab:
dro00 DW OFFSET ServReqMaskSize,        OFFSET ServReqMaskData
dro01 DW OFFSET ServReqGwSize,      OFFSET ServReqGwData
dro02 DW OFFSET ServReqDnsSize,     OFFSET ServReqDnsData
dro03 DW OFFSET ServLeaseSize,          OFFSET ServLeaseData
dro04 DW OFFSET ServReqIdSize,          OFFSET ServReqIdData
dro05 DW OFFSET ServRenewSize,          OFFSET ServRenewData
dro06 DW OFFSET ServRebindSize,         OFFSET ServRebindData
dro07 DW -1

ReceiveDiscover Proc near
    push ds
    push es
    push fs
    push bx
    push si
    push di
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:dhcp_driver_sel
    or ax,ax
    jz discover_req_done
;    
    mov eax,ds:dhcp_ip2
    or eax,eax
    jz discover_req_done
;
    mov ax,gs
    mov fs,ax
    mov ax,es
    mov ds,ax
    mov si,di
;
    mov ax,cx
    sub ax,si
    sub ax,SIZE dhcp_header
    sub cx,ax
        mov dx,cx
        mov bx,OFFSET DiscReqOptTab

discover_req_size_loop:
        mov ax,cs:[bx]
        cmp ax,-1
        jz discover_req_size_ok
;
        call word ptr cs:[bx]
        add dx,cx
        add bx,4
        jmp discover_req_size_loop

discover_req_size_ok:
    mov cx,dx
        call CreateDhcpReplyBroadcast
;    
    push fs
    push cx
    push si
    push di
;
        mov es:[di].dhcp_op,2
        mov al,[si].dhcp_hw_type
        mov es:[di].dhcp_hw_type,al
        mov al,[si].dhcp_hw_len
        mov es:[di].dhcp_hw_len,al
        mov es:[di].dhcp_hops,0
    mov eax,[si].dhcp_id
    mov es:[di].dhcp_id,eax     
        mov es:[di].dhcp_elapsed,0
        mov es:[di].dhcp_flags,80h
    mov es:[di].dhcp_client_ip,0
        mov es:[di].dhcp_relay_ip,0
        mov es:[di].dhcp_magic,63538263h
        mov es:[di].dhcp_msg_code,53
        mov es:[di].dhcp_msg_len,1
        mov es:[di].dhcp_msg_type,2
        call SetHwAddress

discover_server_loop:
    call FindServer
    jc discover_req_new

discover_ident_init:
    mov fs,ax
    call InitServerSel
    mov eax,fs:dsd_local_ip
    jmp discover_req_options

discover_req_new:
    call CreateServerSel
    jmp discover_server_loop

discover_req_options:
        mov es:[di].dhcp_req_ip,eax
;       
    mov ax,SEG data
    mov ds,ax
    GetIpAddress
        mov es:[di].dhcp_server_ip,edx
;
        add si,SIZE dhcp_header
        add di,SIZE dhcp_header
        sub cx,SIZE dhcp_header

        mov bx,OFFSET DiscReqOptTab

discover_req_data_loop:
        mov ax,cs:[bx]
        cmp ax,-1
        jz discover_req_data_ok
;
        call word ptr cs:[bx+2]
        add bx,4
        jmp discover_req_data_loop

discover_req_data_ok:
        mov al,-1
        stosb
    dec cx
;
    xor al,al
    rep stosb
;    
    pop di
    pop si
    pop cx
    pop fs
        call SendDhcpBroadcast

discover_req_done:
    pop di
    pop si
    pop bx
    pop fs    
    pop es
    pop ds
    FreeMem
    ret
ReceiveDiscover Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReceiveRequest
;
;       Purpose:                Receive request
;
;       Parameters:             ES:EDI  UDP data
;                   GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                               data-proc

ReqReqOptTab:
rro00 DW OFFSET ServReqMaskSize,        OFFSET ServReqMaskData
rro01 DW OFFSET ServReqGwSize,      OFFSET ServReqGwData
rro02 DW OFFSET ServReqDnsSize,     OFFSET ServReqDnsData
rro03 DW OFFSET ServLeaseSize,          OFFSET ServLeaseData
rro04 DW OFFSET ServReqIdSize,          OFFSET ServReqIdData
rro05 DW OFFSET ServRenewSize,          OFFSET ServRenewData
rro06 DW OFFSET ServRebindSize,         OFFSET ServRebindData
rro07 DW -1

ReceiveRequest  Proc near
    push ds
    push es
    push fs
    push bx
    push si
    push di
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:dhcp_driver_sel
    or ax,ax
    jz req_req_done
;
    mov ax,es
    mov ds,ax
    mov si,di
    call FindServer
    jc req_req_done
;
    mov fs,ax
    mov eax,[si].dhcp_id
    cmp eax,fs:dsd_orig_ident
    jne req_req_done
;    
    mov ax,gs
    mov fs,ax
    mov ax,es
    mov ds,ax
    mov si,di
;
    mov ax,cx
    sub ax,si
    sub ax,SIZE dhcp_header
    sub cx,ax
        mov dx,cx
        mov bx,OFFSET ReqReqOptTab

req_req_size_loop:
        mov ax,cs:[bx]
        cmp ax,-1
        jz req_req_size_ok
;
        call word ptr cs:[bx]
        add dx,cx
        add bx,4
        jmp req_req_size_loop

req_req_size_ok:
    mov cx,dx
        call CreateDhcpReplyBroadcast
;    
    push fs
    push cx
    push si
    push di
;
        mov es:[di].dhcp_op,2
        mov al,[si].dhcp_hw_type
        mov es:[di].dhcp_hw_type,al
        mov al,[si].dhcp_hw_len
        mov es:[di].dhcp_hw_len,al
        mov es:[di].dhcp_hops,0
    mov eax,[si].dhcp_id
    mov es:[di].dhcp_id,eax     
        mov es:[di].dhcp_elapsed,0
        mov es:[di].dhcp_flags,80h
    mov es:[di].dhcp_client_ip,0
        mov es:[di].dhcp_relay_ip,0
        mov es:[di].dhcp_magic,63538263h
        mov es:[di].dhcp_msg_code,53
        mov es:[di].dhcp_msg_len,1
        mov es:[di].dhcp_msg_type,5
        call SetHwAddress
;
    call FindServer
    mov fs,ax
    mov eax,fs:dsd_local_ip
        mov es:[di].dhcp_req_ip,eax
;       
    GetIpAddress
        mov es:[di].dhcp_server_ip,edx
;
        add si,SIZE dhcp_header
        add di,SIZE dhcp_header
        sub cx,SIZE dhcp_header

        mov bx,OFFSET ReqReqOptTab

req_req_data_loop:
        mov ax,cs:[bx]
        cmp ax,-1
        jz req_req_data_ok
;
        call word ptr cs:[bx+2]
        add bx,4
        jmp req_req_data_loop

req_req_data_ok:
        mov al,-1
        stosb
    dec cx
;
    xor al,al
    rep stosb
;    
    pop di
    pop si
    pop cx
    pop fs
        call SendDhcpBroadcast

req_req_done:
    pop di
    pop si
    pop bx
    pop fs    
    pop es
    pop ds
    FreeMem
    ret
ReceiveRequest Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReceiveiServerDhcp
;
;       Purpose:                Receive notify from UDP
;
;       Parameters:             GS      Net driver selector
;                   ES:EDI      UDP data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReceiveServerDhcp

serv_receive_tab:
sr00    DW OFFSET ReceiveError
sr01    DW OFFSET ReceiveDiscover
sr02    DW OFFSET ReceiveError
sr03    DW OFFSET ReceiveRequest
sr04    DW OFFSET ReceiveError
sr05    DW OFFSET ReceiveError
sr06    DW OFFSET ReceiveError
sr07    DW OFFSET ReceiveError
sr08    DW OFFSET ReceiveError

ReceiveServerDhcp       Proc near
        push ds
        push ax
        push bx
;
        mov ax,SEG data
        mov ds,ax
;
    mov ax,ds:dhcp_driver_sel
    mov bx,gs
    or ax,ax
    jz receive_serv_free    
;
    cmp ax,bx
    je receive_serv_free
;
        mov ax,es:[di].udp_source
        xchg al,ah
        cmp ax,68
        jne receive_serv_free
;
        mov ax,es:[di].udp_dest
        xchg al,ah
        cmp ax,67
        jne receive_serv_free
;
        add di,8
        sub cx,8
        sub cx,SIZE dhcp_header
        jb receive_serv_free
;
        add cx,SIZE dhcp_header
        mov al,es:[di].dhcp_op
        cmp al,1
        jne receive_serv_free
;
        mov al,es:[di].dhcp_msg_code
        cmp al,53
        jne receive_serv_free
;
        movzx bx,es:[di].dhcp_msg_type
        cmp bx,8
        jae receive_serv_free
;
        add bx,bx
        call word ptr cs:[bx].serv_receive_tab  
        jmp receive_serv_done

receive_serv_free:
        FreeMem

receive_serv_done:
        pop bx
        pop ax
        pop ds
        ret
ReceiveServerDhcp       Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ClientSize
;
;       Purpose:                Size of client hardware address
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;
;       Returns:                CX                      Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClientSize      Proc near
        movzx cx,ds:addr_len
        add cx,2
        ret
ClientSize      Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ClientData
;
;       Purpose:                Copy client hardware address
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;                                       ES:DI           Position to copy at
;
;       Returns:                ES:DI           New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClientData      Proc near
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
ClientData      Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ParamSize
;
;       Purpose:                Size of parameters
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;
;       Returns:                CX                      Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParamSize       Proc near
        push ds
        push bx
;
        mov cx,2
        mov bx,SEG data
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
ParamSize       Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ParamData
;
;       Purpose:                Fill in param data
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;                                       ES:DI           Position to copy at
;
;       Returns:                ES:DI           New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParamData       Proc near
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
        mov bx,SEG data
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
ParamData       Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   LeaseSize
;
;       Purpose:                Size of IP lease time
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;
;       Returns:                CX                      Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LeaseSize       Proc near
        mov cx,6
        ret
LeaseSize       Endp
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   LeaseData
;
;       Purpose:                Copy IP lease time
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;                                       ES:DI           Position to copy at
;
;       Returns:                ES:DI           New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LeaseData       Proc near
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
LeaseData       Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServerSize
;
;       Purpose:                Size of server IP
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;
;       Returns:                CX                      Size of server IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServerSize      Proc near
        mov cx,6
        ret
ServerSize      Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ServerData
;
;       Purpose:                Copy server IP
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;                                       ES:DI           Position to copy at
;
;       Returns:                ES:DI           New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServerData      Proc near
        push ds
        push eax
;
        mov al,54
        stosb
        mov al,4
        stosb
;
        mov ax,SEG data
        mov ds,ax
        mov eax,ds:dhcp_server
        stosd
;
        pop eax
        pop ds
        ret
ServerData      Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReqIpSize
;
;       Purpose:                Size of client IP
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;
;       Returns:                CX                      Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqIpSize       Proc near
        mov cx,6
        ret
ReqIpSize       Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReqIpData
;
;       Purpose:                Copy client IP
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;                                       ES:DI           Position to copy at
;
;       Returns:                ES:DI           New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqIpData       Proc near
        push ds
        push eax
;
        mov al,50
        stosb
        mov al,4
        stosb
;
        mov ax,SEG data
        mov ds,ax
        mov eax,ds:dhcp_wanted_ip
        stosd
;
        pop eax
        pop ds
        ret
ReqIpData       Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   DeclIpSize
;
;       Purpose:                Size of declined IP
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;
;       Returns:                CX                      Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeclIpSize      Proc near
        mov cx,6
        ret
DeclIpSize      Endp
        
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   DeclIpData
;
;       Purpose:                Copy declined client IP
;
;       Parameters:             DS                      Class selector
;                                       FS                      Driver selector
;                                       ES:DI           Position to copy at
;
;       Returns:                ES:DI           New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeclIpData      Proc near
        push ds
        push eax
;
        mov al,50
        stosb
        mov al,4
        stosb
;
        mov ax,SEG data
        mov ds,ax
        mov eax,ds:dhcp_ip
        stosd
;
        pop eax
        pop ds
        ret
DeclIpData      Endp
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DhcpDiscover
;
;               DESCRIPTION:    Send DHCP discover for a driver
;
;       PARAMETERS:     DS                      Class selector
;                                               FS                      Driver selector
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                               data-proc

DiscOptTab:
d00     DW OFFSET ClientSize,           OFFSET ClientData
d01 DW OFFSET ParamSize,                OFFSET ParamData
d02 DW OFFSET LeaseSize,                OFFSET LeaseData
d03 DW OFFSET ReqIpSize,                OFFSET ReqIpData
d04     DW -1

DhcpDiscover    Proc far
        mov dx,SIZE dhcp_header + 1
        mov bx,OFFSET DiscOptTab

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
        call CreateDhcpReqBroadcast
        mov es:[di].dhcp_op,1
        mov al,ds:class_id
        mov es:[di].dhcp_hw_type,al
        mov al,ds:addr_len
        mov es:[di].dhcp_hw_len,al
        mov es:[di].dhcp_hops,0
        push ds
        mov ax,SEG data
        mov ds,ax
        mov eax,ds:dhcp_ident
        or eax,eax
        jnz dhcp_ident_ok
;       
        GetSystemTime

dhcp_ident_ok:
        mov ds:dhcp_ident,eax
        pop ds
        mov es:[di].dhcp_id,eax
        mov es:[di].dhcp_elapsed,0
        mov es:[di].dhcp_flags,80h
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
        mov bx,OFFSET DiscOptTab

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
DhcpDiscover    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DhcpRequest
;
;               DESCRIPTION:    Send DHCP request for a driver
;
;       PARAMETERS:     DS                      Class selector
;                                               FS                      Driver selector
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                               data-proc

ReqOptTab:
ro00 DW OFFSET ClientSize,              OFFSET ClientData
ro01 DW OFFSET ParamSize,               OFFSET ParamData
ro02 DW OFFSET LeaseSize,               OFFSET LeaseData
ro03 DW OFFSET ReqIpSize,               OFFSET ReqIpData
ro04 DW OFFSET ServerSize,              OFFSET ServerData
ro05 DW -1

DhcpRequest     Proc far
        mov dx,SIZE dhcp_header + 1
        mov bx,OFFSET ReqOptTab

dhcp_req_size_loop:
        mov ax,cs:[bx]
        cmp ax,-1
        jz dhcp_req_size_ok
;
        call word ptr cs:[bx]
        add dx,cx
        add bx,4
        jmp dhcp_req_size_loop

dhcp_req_size_ok:
        mov cx,dx
        push cx
        call CreateDhcpReqBroadcast
        mov es:[di].dhcp_op,1
        mov al,ds:class_id
        mov es:[di].dhcp_hw_type,al
        mov al,ds:addr_len
        mov es:[di].dhcp_hw_len,al
        mov es:[di].dhcp_hops,0
        push ds
        mov ax,SEG data
        mov ds,ax
        mov eax,ds:dhcp_ident
        pop ds
        mov es:[di].dhcp_id,eax
        mov es:[di].dhcp_elapsed,0
        mov es:[di].dhcp_flags,80h
        mov es:[di].dhcp_client_ip,0
        mov es:[di].dhcp_req_ip,0
        mov es:[di].dhcp_server_ip,0
        mov es:[di].dhcp_relay_ip,0
        mov es:[di].dhcp_magic,63538263h
        mov es:[di].dhcp_msg_code,53
        mov es:[di].dhcp_msg_len,1
        mov es:[di].dhcp_msg_type,3
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
        mov bx,OFFSET ReqOptTab

dhcp_req_data_loop:
        mov ax,cs:[bx]
        cmp ax,-1
        jz dhcp_req_data_ok
;
        call word ptr cs:[bx+2]
        add bx,4
        jmp dhcp_req_data_loop

dhcp_req_data_ok:
        mov al,-1
        stosb
;
        pop di
        pop cx
        call SendDhcpBroadcast
        ret
DhcpRequest     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DhcpDecline
;
;               DESCRIPTION:    Send DHCP decline for a driver
;
;       PARAMETERS:     DS                      Class selector
;                                               FS                      Driver selector
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                               data-proc

DeclOptTab:
de00 DW OFFSET ClientSize,              OFFSET ClientData
de01 DW OFFSET DeclIpSize,              OFFSET DeclIpData
de02 DW OFFSET ServerSize,              OFFSET ServerData
de03 DW -1

DhcpDecline     Proc far
        mov dx,SIZE dhcp_header + 1
        mov bx,OFFSET DeclOptTab

dhcp_decl_size_loop:
        mov ax,cs:[bx]
        cmp ax,-1
        jz dhcp_decl_size_ok
;
        call word ptr cs:[bx]
        add dx,cx
        add bx,4
        jmp dhcp_decl_size_loop

dhcp_decl_size_ok:
        mov cx,dx
        push cx
        call CreateDhcpReqBroadcast
        mov es:[di].dhcp_op,1
        mov al,ds:class_id
        mov es:[di].dhcp_hw_type,al
        mov al,ds:addr_len
        mov es:[di].dhcp_hw_len,al
        mov es:[di].dhcp_hops,0
;
        push ds
        mov ax,SEG data
        mov ds,ax
        mov eax,ds:dhcp_ident
        pop ds
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
        mov es:[di].dhcp_msg_type,4
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
        mov bx,OFFSET DeclOptTab

dhcp_decl_data_loop:
        mov ax,cs:[bx]
        cmp ax,-1
        jz dhcp_decl_data_ok
;
        call word ptr cs:[bx+2]
        add bx,4
        jmp dhcp_decl_data_loop

dhcp_decl_data_ok:
        mov al,-1
        stosb
;
        pop di
        pop cx
        call SendDhcpBroadcast
        ret
DhcpDecline     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   AddDhcpOption
;
;               DESCRIPTION:    Add a requested DHCP option to ask for
;
;       PARAMETERS:     AL                      Option code
;                                               ES:DI           Callback
;                                                       ES:DI   Pointer to option data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_dhcp_option_name    DB 'Add DHCP Option',0

add_dhcp_option Proc far
        push ds
        push es
        push ax
        push dx
;
        mov dx,es
        push eax
        mov eax,SIZE dhcp_option
        AllocateSmallGlobalMem
        pop eax
        mov es:dhcp_opt_code,al
        mov word ptr es:dhcp_opt_callb,di
        mov word ptr es:dhcp_opt_callb+2,dx
        mov ax,SEG data
        mov ds,ax
        mov ax,ds:dhcp_option_list
        mov es:dhcp_opt_next,ax
        mov ds:dhcp_option_list,es
;
        pop dx
        pop ax
        pop es
        pop ds
        ret
add_dhcp_option Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   IsDhcpDone
;
;               DESCRIPTION:    Check if DHCP is finished
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public IsDhcpDone

IsDhcpDone      Proc near
        push ds
        push ax
;
        mov ax,SEG data
        mov ds,ax
        mov ax,ds:dhcp_driver_sel
        or ax,ax
        stc
        jz is_dhcp_done
;
        clc

is_dhcp_done:
        pop ax
        pop ds
        ret
IsDhcpDone      Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReceiveError
;
;       Purpose:                Receive error
;
;       Parameters:             ES:EDI  UDP data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveError    Proc near
        FreeMem
        ret
ReceiveError    Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReceiveOffer
;
;       Purpose:                Receive offer
;
;       Parameters:             ES:EDI  UDP data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveOffer    Proc near
        push ds
        push fs
        push ax
        push bx
        push si
;       
        mov ax,SEG data
        mov ds,ax
        mov eax,es:[di].dhcp_req_ip
        mov ds:dhcp_wanted_ip,eax
;
        mov eax,ds:dhcp_server
        or eax,eax
        jnz receive_offer_leave
;
        add di,SIZE dhcp_header

receive_offer_loop:
        mov al,es:[di]
        cmp al,54
        jne receive_offer_next
;
        mov eax,es:[di+2]
        mov ds:dhcp_server,eax
;
        push es
        push di
        mov ax,cs
        mov es,ax
        mov di,OFFSET DhcpRequest
        NetBroadcast
        pop di
        pop es
        jmp receive_offer_leave

receive_offer_next:
        inc di
        sub cx,1
        jz receive_offer_leave
;
        movzx ax,byte ptr es:[di]
        inc ax
        add di,ax
        sub cx,ax
        ja receive_offer_loop

receive_offer_leave:
        FreeMem

receive_offer_done:
    pop si
        pop bx
        pop ax
        pop fs
        pop ds
        ret
ReceiveOffer    Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReceiveAck
;
;       Purpose:                Receive ACK
;
;       Parameters:             ES:EDI  UDP data
;                   GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveAck      Proc near
        push ds
        push fs
        push eax
        push bx
        push edx
;
        mov edx,es:[di].dhcp_req_ip
        mov ax,SEG data
        mov ds,ax
        mov ds:dhcp_ip,edx
;
        add di,SIZE dhcp_header

receive_ack_loop:
        mov al,es:[di]
        cmp al,-1
        je receive_ack_leave
;
        mov bx,ds:dhcp_option_list

receive_ack_opt_loop:
        or bx,bx
        jz receive_ack_next
;
        mov fs,bx
        mov bx,fs:dhcp_opt_next
        cmp al,fs:dhcp_opt_code
        jne receive_ack_opt_loop
;
        push cx
        push di
        movzx cx,byte ptr es:[di+1]
        add di,2
        call fs:dhcp_opt_callb
        pop di
        pop cx

receive_ack_next:
        inc di
        sub cx,1
        jz receive_ack_leave
;
        movzx ax,byte ptr es:[di]
        inc ax
        add di,ax
        sub cx,ax
        ja receive_ack_loop

receive_ack_leave:
        mov ds:dhcp_driver_sel,gs

receive_ack_done:
        FreeMem
;
    pop edx
        pop bx
        pop eax
        pop fs
        pop ds
        ret
ReceiveAck      Endp

            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:                   ReceiveClientDhcp
;
;       Purpose:                Receive notify from UDP
;
;       Parameters:             GS      Net driver selector
;                   ES:EDI      UDP data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public ReceiveClientDhcp

cl_receive_tab:
cr00    DW OFFSET ReceiveError
cr01    DW OFFSET ReceiveError
cr02    DW OFFSET ReceiveOffer
cr03    DW OFFSET ReceiveError
cr04    DW OFFSET ReceiveError
cr05    DW OFFSET ReceiveAck
cr06    DW OFFSET ReceiveError
cr07    DW OFFSET ReceiveError
cr08    DW OFFSET ReceiveError

ReceiveClientDhcp       Proc near
        push ds
        push ax
        push bx
        push dx
;
        mov ax,SEG data
        mov ds,ax
;
        mov ax,es:[di].udp_source
        xchg al,ah
        cmp ax,67
        jne receive_cl_free
;
        mov ax,es:[di].udp_dest
        xchg al,ah
        mov dx,ax
        cmp ax,68
        je receive_cl_dest_ok
;
        cmp ax,67
        jne receive_cl_free

receive_cl_dest_ok:
        add di,8
        sub cx,8
        sub cx,SIZE dhcp_header
        jb receive_cl_free
;
        add cx,SIZE dhcp_header
        mov al,es:[di].dhcp_op
        cmp al,2
        jne receive_cl_free
;
        mov al,es:[di].dhcp_msg_code
        cmp al,53
        jne receive_cl_free
;
        movzx bx,es:[di].dhcp_msg_type
        cmp bx,8
        jae receive_cl_free
;
    cmp dx,67
    je receive_cl_free    
;
        mov eax,ds:dhcp_ident
        cmp eax,es:[di].dhcp_id
        jne receive_cl_free
;
        add bx,bx
        call word ptr cs:[bx].cl_receive_tab    
        jmp receive_cl_done

receive_cl_free:
    xor ax,ax
    mov ds,ax
        FreeMem

receive_cl_done:
    pop dx
        pop bx
        pop ax
        pop ds
        ret
ReceiveClientDhcp       Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   dhcp_thread
;
;               DESCRIPTION:    dhcp thread
;
;       PARAMETERS:     
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dhcp_thread_name        DB 'DHCP',0

dhcp_thread_pr:
        mov ax,250
        WaitMilliSec
;
        mov bx,SEG data
        mov ds,bx
;       
    GetIpAddress
    mov ds:dhcp_ip,edx
;       
        mov al,ds:dhcp_enabled
        or al,al
        jz dhcp_thread_disabled
;    
    mov cx,8

dhcp_thread_retry:    
        mov ds:dhcp_server,0
;       
        mov ax,cs
        mov es,ax
        mov di,OFFSET DhcpDiscover
        NetBroadcast
;
    mov ax,500
    WaitMilliSec        
;    
        mov bx,SEG data
        mov ds,bx
    mov ax,ds:dhcp_driver_sel
    or ax,ax
    jz dhcp_thread_failed
;
    mov edx,ds:dhcp_ip
        call is_ip_in_use
        jc dhcp_thread_done
;
        mov ax,cs
        mov es,ax
        mov di,OFFSET DhcpDecline
        NetBroadcast

dhcp_thread_failed:
    loop dhcp_thread_retry    

dhcp_thread_disabled:    
    mov ds:dhcp_driver_sel,1
;    
    call get_gateway_driver
    jnc dhcp_gw_ok
;
    mov eax,250
    call ping_gateway
    jc dhcp_thread_done
;    
    call get_gateway_driver
    jc dhcp_thread_done

dhcp_gw_ok:
    mov ds:dhcp_driver_sel,bx

dhcp_thread_done:    
    mov eax,ds:dhcp_ip
    call define_ip
        retf


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Init_dhcp_thread
;
;               DESCRIPTION:    init DHCP thread
;
;       PARAMETERS:     
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dhcp_thread        Proc far
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
init_dhcp_thread        Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init_dhcp
;
;               DESCRIPTION:    Init dhcp driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dhcp_name           DB 'DHCP', 0
dhcp_ip_name            DB 'DHCP.IP',0

        public init_dhcp

init_dhcp       PROC near
        mov bx,SEG data
        mov ds,bx
        mov es,bx
        mov es:dhcp_option_list,0
        mov es:dhcp_driver_sel,0
        mov es:dhcp_server,0
        GetIpAddress
        mov es:dhcp_wanted_ip,edx
        mov es:dhcp_ident,0
        mov di,OFFSET dhcp_serv_arr
        mov cx,256
        xor ax,ax
        rep stosw
        mov es:dhcp_serv_arr,-1
        mov es:dhcp_serv_arr+2,-1
;
    mov ax,es
    mov ds,ax
        mov ax,cs
        mov es,ax
;
        mov di,OFFSET dhcp_ip_name
        call GetIPNumber
        mov ds:dhcp_ip2,eax
;
    mov ds:dhcp_enabled,1
    mov di,OFFSET dhcp_name
    call GetValue       
    jc init_dhcp_enabled_ok
;
    mov ds:dhcp_enabled,al

init_dhcp_enabled_ok:
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov di,OFFSET init_dhcp_thread
        HookInitTasking
;
        mov esi,OFFSET add_dhcp_option
        mov edi,OFFSET add_dhcp_option_name
        xor cl,cl
        mov ax,add_dhcp_option_nr
        RegisterOsGate
;
        ret
init_dhcp       ENDP

code    ENDS

        END
