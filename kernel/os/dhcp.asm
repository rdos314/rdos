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
; DHCP.ASM
; DHCP client implementation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc
INCLUDE net.inc
INCLUDE udp.inc
INCLUDE dhcp.inc

DEFAULT_LEASE = 60 * 60

Reverse MACRO
    xchg al,ah
    rol eax,16
    xchg al,ah
        ENDM

dhcp_option     STRUC

dhcp_opt_next   DW ?
dhcp_opt_code   DB ?
dhcp_opt_callb  DD ?,?

dhcp_option     ENDS

dhcp_serv_data  STRUC

dsd_orig_ident  DD ?
dsd_local_ip    DD ?
dsd_driver_sel  DW ?
dsd_hw_type     DB ?
dsd_hw_len      DB ?
dsd_hw_data     DB 10h DUP(?)

dhcp_serv_data  ENDS

dhcp_relay_entry        STRUC

dre_last_update DD ?,?
dre_driver      DW ?
dre_ip          DD ?
dre_hw_type     DB ?
dre_hw_len      DB ?
dre_hw_data     DB 10h DUP(?)

dhcp_relay_entry        ENDS


data    SEGMENT byte public 'DATA'

dhcp_ident              DD ?
dhcp_wanted_ip      DD ?
dhcp_server             DD ?
dhcp_option_list    DW ?
dhcp_driver_sel     DW ?
dhcp_lease      DD ?
dhcp_ip         DD ?
dhcp_ip2        DD ?
;dhcp_mask2      DD ?
;dhcp_gateway2       DD ?
dhcp_serv_arr       DW 256 DUP(?)
dhcp_relay_arr      DW 256 DUP(?)

dhcp_enabled    DB ?
dhcp_done       DB ?
dhcp_rebind     DB ?

data    ENDS

    extrn CalcCheckSum:near
    extrn is_ip_in_use:near
    extrn define_ip:near
    extrn get_gateway_driver:near
    extrn get_host_name:near
    extrn ping_gateway:near
    extrn GetIPNumber:near
    extrn GetValue:near
    extrn GetEnvStr:near
    extrn RebindGateway:near
    extrn CreateUnboundIp:near

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dhcp_link_up
;
;           DESCRIPTION:    Notify link up change
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public dhcp_link_up

dhcp_link_up    Proc near
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    mov ds:dhcp_lease,1

dluDone:
    pop eax
    pop ds
    ret
dhcp_link_up    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateDhcpReqBroadcast
;
;       Purpose:        Create a req DHCP broadcast header
;
;       Parameters:     CX              Number of bytes to allocate
;                       FS              Driver selector
;
;       Returns:        NC              Ok
;                       ES:EDI          Allocate buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ip_options      DB 0

CreateDhcpReqBroadcast  Proc near
    push ds
    push eax
    push ecx
    push esi
;
    mov eax,cs
    mov ds,eax
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
    pop eax
    pop ds
    ret
CreateDhcpReqBroadcast  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateUnboundDhcpBroadcast
;
;       Purpose:        Create an unbound req DHCP broadcast header
;
;       Parameters:     CX              Number of bytes to allocate
;                       FS              Driver selector
;
;       Returns:        NC              Ok
;                       ES:DI       Allocate buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateUnboundDhcpBroadcast  Proc near
    push ds
    push eax
    push ecx
    push esi
;
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET ip_options
    mov al,17
    mov ah,30
    movzx ecx,cx
    add ecx,8
    call CreateUnboundIp
    jc create_unb_req_br_done
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

create_unb_req_br_done:
    pop esi
    pop ecx
    pop eax
    pop ds
    ret
CreateUnboundDhcpBroadcast  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateDhcpReplyBroadcast
;
;       Purpose:        Create a reply DHCP broadcast header
;
;       Parameters:     CX              Number of bytes to allocate
;                       FS              Driver selector
;
;       Returns:        NC              Ok
;                       ES:DI       Allocate buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDhcpReplyBroadcast    Proc near
    push ds
    push eax
    push ecx
    push edx
    push esi
;
    mov eax,cs
    mov ds,eax
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
    mov es:[edi-8],edx   
    add edi,8
    clc

create_reply_br_done:
    pop esi
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
CreateDhcpReplyBroadcast    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendDhcpBroadcast
;
;       Purpose:        Send DHCP broadcast message
;
;       Parameters:     ES:EDI          Buffer
;                       CX              Number of bytes to send
;                       FS              Driver selector
;
;       Returns:        NC              Ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendDhcpBroadcast       Proc near
    push edi
;
    sub edi,8
    add ecx,8
    xchg cl,ch
    mov es:[edi].udp_len,cx
    xchg cl,ch
;
    mov es:[edi].udp_checksum,0
    mov ax,cx
    xchg al,ah
    add ax,1100h
    adc ax,0
    adc ax,0
    sub di,8
    add cx,8
    call CalcChecksum
    not ax
    add edi,8
    mov es:[edi].udp_checksum,ax
    sub ecx,8
    SendBroadcastIp
;
    pop eax
    ret
SendDhcpBroadcast       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindServer
;
;       Purpose:        Find server selector
;
;       Parameters:     DS:ESI   DHCP data
;                       GS      Driver selector
;
;   Returns:            AX      Server selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindServer      Proc near
    push es
    push fs
    push ebx
    push ecx
    push edx
    push ebp
;
    mov eax,SEG data
    mov fs,eax
    mov ebp,OFFSET dhcp_serv_arr+4
    mov ecx,256-2

find_serv_loop:
    push ecx
    mov ax,fs:[ebp]
    or ax,ax
    jz find_serv_next
;
    mov es,eax
    mov dl,[esi].dhcp_hw_type
    cmp dl,es:dsd_hw_type
    jne find_serv_next
;
    movzx ecx,[esi].dhcp_hw_len
    cmp cl,es:dsd_hw_len
    jne find_serv_next
;
    or cl,cl
    je find_serv_next
;    
    xor ebx,ebx

find_serv_match:
    mov dl,[ebx+esi].dhcp_hw_addr
    cmp dl,es:[ebx].dsd_hw_data
    jne find_serv_next
;
    inc ebx
    loop find_serv_match
;
    clc
    pop ecx
    jmp find_serv_done

find_serv_next:
    pop ecx
    add ebp,2
    loop find_serv_loop

find_serv_fail:
    xor ax,ax    
    stc

find_serv_done:
    pop ebp
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    ret
FindServer  Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           InitServerSel
;
;       Purpose:        Init server selector
;
;       Parameters:     DS:ESI   Original UDP data
;                       FS      Server sel
;                       GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitServerSel   Proc near
    push eax
    push ebx
    push ecx
;    
    mov eax,[esi].dhcp_id
    mov fs:dsd_orig_ident,eax
    mov fs:dsd_driver_sel,gs
    mov al,[esi].dhcp_hw_type
    mov fs:dsd_hw_type,al
    movzx ecx,[esi].dhcp_hw_len
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
    xor ebx,ebx

init_serv_loop:
    mov al,[ebx+esi].dhcp_hw_addr
    mov fs:[ebx].dsd_hw_data,al
    inc ebx
    loop init_serv_loop

init_serv_done:
    pop ecx
    pop ebx
    pop eax
    ret
InitServerSel   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateServerSel
;
;       Purpose:        Create, initializr & link server selector
;
;       Parameters:     DS:ESI   Original UDP data
;                       GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateServerSel Proc near
    push ds
    push es
    push fs
    push eax
    push ebx
    push ecx
;   
    call FindServer
    jc create_serv_new

create_serv_update:
    mov fs,eax
    call InitServerSel
    jmp create_serv_done
    
create_serv_new:
    mov eax,SIZE dhcp_serv_data
    AllocateSmallGlobalMem
    mov eax,es
    mov fs,eax
    call InitServerSel
;
    mov eax,SEG data
    mov ds,eax
;
    mov ecx,256-2
    mov ebx,OFFSET dhcp_serv_arr+4
    mov edx,ds:dhcp_ip2

create_serv_slot_loop:
    mov ax,ds:[ebx]
    or ax,ax
    jz create_serv_slot_ok
;
    add edx,1000000h
    add ebx,2
    loop create_serv_slot_loop
;   
    xor eax,eax
    mov fs,eax
    FreeMem
    stc
    jmp create_serv_done
    
create_serv_slot_ok:
    mov fs:dsd_local_ip,edx
    mov ds:[ebx],fs
    clc

create_serv_done:   
    pop ecx
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    ret
CreateServerSel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindRelay
;
;       Purpose:        Find relay request
;
;       Parameters:     ES:EDI           UDP data
;
;       Returns:        NC
;                       AX          Relay selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindRelay       Proc near
    push ds
    push fs
    push ebx
    push ecx
    push ebp
;
    mov eax,SEG data
    mov ds,eax
;
    mov ebx,OFFSET dhcp_relay_arr
    mov ecx,256

frLoop:
    mov ax,ds:[ebx]
    or ax,ax
    jz frNext
;
    mov fs,eax
    mov al,es:[edi].dhcp_hw_type
    cmp al,fs:dre_hw_type
    jne frNext
;
    mov al,es:[edi].dhcp_hw_len
    cmp al,fs:dre_hw_len
    jne frNext
;
    push ecx
    movzx ecx,al
    xor ebp,ebp

frCompLoop:
    mov al,es:[ebp+edi].dhcp_hw_addr
    cmp al,fs:[ebp].dre_hw_data
    je frCompNext
;
    pop ecx
    jmp frNext

frCompNext:
    inc ebp
    loop frCompLoop
;
    pop ecx
    mov eax,fs
    clc
    jmp frDone

frNext:
    add ebx,2
    loop frLoop
;
    stc

frDone:
    pop ebp
    pop ecx
    pop ebx
    pop fs
    pop ds
    ret
FindRelay    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SetHwAddress
;
;       Purpose:        Set hardware address
;
;       Parameters:     DS:ESI   source DHCP header
;                       ES:EDI   dest DHCP header
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetHwAddress    Proc near
    push eax
    push ecx
    push esi
    push edi
;    
    mov ecx,34h
    add esi,OFFSET dhcp_hw_addr
    add edi,OFFSET dhcp_hw_addr
    xor eax,eax
    rep movsd
;
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
SetHwAddress    Endp    

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServLeaseSize
;
;       Purpose:        Size of IP lease time
;
;       Returns:        ECX              Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServLeaseSize   Proc near
    mov ecx,6
    ret
ServLeaseSize   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServLeaseData
;
;       Purpose:        Copy IP lease time
;
;       Parameters:     FS      Dhcp server data selector
;                       ES:EDI  Position to copy at
;                       ECX     Byte remaining
;
;       Returns:        ES:EDI  New dest
;                       ECX     new size
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
    sub ecx,6
;
    pop eax
    ret
ServLeaseData   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServRenewSize
;
;       Purpose:        Size of renewal msg
;
;       Returns:        ECX              Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServRenewSize   Proc near
    mov ecx,6
    ret
ServRenewSize   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServRenewData
;
;       Purpose:        Add renew 
;
;       Parameters:     FS      Dhcp server data selector
;                       ES:EDI           Position to copy at
;                       ECX      Byte remaining
;
;       Returns:        ES:EDI       New dest
;                       ECX      new size
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
    sub ecx,6
;
    pop eax
    ret
ServRenewData   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServRebindSize
;
;       Purpose:        Size of rebind msg
;
;       Returns:        ECX              Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServRebindSize  Proc near
    mov ecx,6
    ret
ServRebindSize  Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServRebindData
;
;       Purpose:        Add rebind
;
;       Parameters:     FS      Dhcp server data selector
;                       ES:EDI           Position to copy at
;                       ECX      Byte remaining
;
;       Returns:        ES:EDI       New dest
;                       ECX      new size
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
    sub ecx,6
;
    pop eax
    ret
ServRebindData  Endp
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqIpSize
;
;       Purpose:        Size of client IP
;
;       Parameters:     ES:EDI       DHCP header
;
;       Returns:        ECX              Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqIpSize   Proc near
    mov ecx,6
    ret
ServReqIpSize   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqIpData
;
;       Purpose:        Copy client IP
;
;       Parameters:     FS      Dhcp server data selector
;                       ES:EDI           Position to copy at
;                       ECX      Byte remaining
;
;       Returns:        ES:EDI       New position
;                       ECX      Byte remaining
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
    sub ecx,6
;
    pop eax
    pop ds
    ret
ServReqIpData   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqMaskSize
;
;       Purpose:        Size of net mask
;
;       Parameters:     ES:EDI       DHCP header
;
;       Returns:        ECX              Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqMaskSize Proc near
    mov ecx,6
    ret
ServReqMaskSize Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqMaskData
;
;       Purpose:        Add net mask
;
;       Parameters:     FS      Dhcp server data selector
;                       ES:EDI           Position to copy at
;                       ECX      Byte remaining
;
;       Returns:        ES:EDI       New position
;                       ECX      Byte remaining
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
    sub ecx,6
;
    pop edx
    pop eax
    ret
ServReqMaskData Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqGwSize
;
;       Purpose:        Size of gateway
;
;       Parameters:     ES:EDI       DHCP header
;
;       Returns:        ECX              Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqGwSize   Proc near
    mov ecx,6
    ret
ServReqGwSize   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqGwData
;
;       Purpose:        Add gateway
;
;       Parameters:     FS      Dhcp server data selector
;                       ES:EDI           Position to copy at
;                       ECX      Byte remaining
;
;       Returns:        ES:EDI       New position
;                       ECX      Byte remaining
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
    sub ecx,6
;
    pop edx
    pop eax
    pop ds
    ret
ServReqGwData   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqDnsSize
;
;       Purpose:        Size DNS
;
;       Parameters:     ES:EDI       DHCP header
;
;       Returns:        ECX              Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqDnsSize  Proc near
    push edx
;
    mov ecx,2
    GetDns
    or eax,eax
    jz ServReqDnsSizeDone
;
    add ecx,4
    or edx,edx
    jz ServReqDnsSizeDone
;
    add ecx,4

ServReqDnsSizeDone:   
    pop edx
    ret
ServReqDnsSize  Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqDnsData
;
;       Purpose:        Add dns servers
;
;       Parameters:     FS      Dhcp server data selector
;                       ES:EDI           Position to copy at
;                       ECX      Byte remaining
;
;       Returns:        ES:EDI       New position
;                       ECX      Byte remaining
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqDnsData  Proc near
    push eax
    push edx
;
    mov al,6
    stosb
;       
    push ecx
    call ServReqDnsSize
    mov al,cl
    sub al,2
    stosb
    pop ecx
    sub ecx,2
;
    GetDns
    or eax,eax
    jz ServReqDnsDataDone
;
    stosd
    mov eax,edx
    sub ecx,4
;       
    or eax,eax
    jz ServReqDnsDataDone
;
    stosd
    sub ecx,4
    
ServReqDnsDataDone:
    pop edx
    pop eax
    ret
ServReqDnsData  Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqIdSize
;
;       Purpose:        Size server ID field
;
;       Parameters:     ES:DI       DHCP header
;
;       Returns:        ECX              Size of server ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServReqIdSize   Proc near
    mov ecx,6
    ret
ServReqIdSize   Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServReqIdData
;
;       Purpose:        Add server ID field
;
;       Parameters:     FS      Dhcp server data selector
;                       ES:EDI           Position to copy at
;                       ECX      Byte remaining
;
;       Returns:        ES:EDI       New position
;                       ECX      Byte remaining
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
    sub ecx,6
;
    pop edx
    pop eax
    pop ds
    ret
ServReqIdData   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindOption
;
;       Purpose:        Find option
;
;       Parameters:     ES:EDI    DHCP message
;                       ECX       Message size
;                       AL       Option
;
;       Returns:        EBX       Option position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindOption   Proc near
    push eax
    push ecx
    push edi
;
    add edi,SIZE dhcp_header
    sub ecx,SIZE dhcp_header

    mov ebx,OFFSET DiscReqOptTab

foLoop:
    mov ah,es:[edi]
    cmp ah,-1
    je foFail
;
    cmp al,ah
    je foOk
;
    movzx bx,es:[edi+1]
    add ebx,2
    sub ecx,ebx
    jbe foFail
;
    add edi,ebx
    jmp foLoop

foOk:
    mov ebx,edi
    clc
    jmp foDone

foFail:
    stc

foDone:
    pop edi
    pop ecx
    pop eax
    ret
Findoption      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindOptionEnd
;
;       Purpose:        Find option end
;
;       Parameters:     ES:EDI    DHCP message
;                       ECX       Message size
;
;       Returns:        EBX       Option end position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindOptionEnd   Proc near
    push ecx
    push edi
;
    add edi,SIZE dhcp_header
    sub ecx,SIZE dhcp_header

    mov ebx,OFFSET DiscReqOptTab

foeLoop:
    mov al,es:[edi]
    cmp al,-1
    je foeOk
;
    movzx bx,es:[edi+1]
    add ebx,2
    sub ecx,ebx
    jbe foeFail
;
    add edi,ebx
    jmp foeLoop

foeOk:
    mov ebx,edi
    clc
    jmp foeDone

foeFail:
    stc

foeDone:
    pop edi
    pop ecx
    ret
FindoptionEnd   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetRequestedIpSize
;
;       Purpose:        Get size of requested IP address
;
;       Parameters:     ES:EDI    DHCP message
;                       ECX       Message size
;
;       Returns:        EAX       Additional size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRequestedIpSize   Proc near
    push ebx
;
    mov al,50
    call FindOption
    jc grisFailed
;
    xor eax,eax
    jmp grisDone

grisFailed:
    mov eax,6

grisDone:
    pop ebx
    ret
GetRequestedIpSize      Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateRequestedIp
;
;       Purpose:        Update requested IP address
;
;       Parameters:     ES:EDI    DHCP message
;                       ECX       Message size
;
;       Returns:        ECX       New message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateRequestedIp   Proc near
    push eax
    push ebx
;
    mov al,50
    call FindOption
    jc urqAdd
;
    mov eax,ds:dhcp_ip2
    mov es:[ebx+2],eax
    jmp urqDone

urqAdd:
    call FindOptionEnd
    jc urqDone
;
    mov eax,ds:dhcp_ip2
    mov byte ptr es:[ebx],50
    mov byte ptr es:[ebx+1],4
    mov es:[ebx+2],eax
    mov byte ptr es:[ebx+6],-1
    add ecx,6

urqDone:
    pop ebx
    pop eax
    ret
UpdateRequestedIp       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetLeaseSize
;
;       Purpose:        Get size of lease time
;
;       Parameters:     ES:EDI    DHCP message
;                       ECX       Message size
;
;       Returns:        EAX       Additional size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetLeaseSize   Proc near
    push ebx
;
    mov al,51
    call FindOption
    jc glsFailed
;
    xor eax,eax
    jmp glsDone

glsFailed:
    mov eax,6

glsDone:
    pop ebx
    ret
GetLeaseSize    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateLease
;
;       Purpose:        Update lease time
;
;       Parameters:     ES:EDI    DHCP message
;                       ECX       Message size
;
;       Returns:        ECX       New message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLease   Proc near
    push eax
    push ebx
;
    mov al,51
    call FindOption
    jc ulAdd
;
    mov eax,DEFAULT_LEASE
    Reverse
    mov es:[ebx+2],eax
    jmp ulDone

ulAdd:
    call FindOptionEnd
    jc ulDone
;
    mov eax,DEFAULT_LEASE
    Reverse
    mov byte ptr es:[ebx],51
    mov byte ptr es:[ebx+1],4
    mov es:[ebx+2],eax
    mov byte ptr es:[ebx+6],-1
    add ecx,6

ulDone:
    pop ebx
    pop eax
    ret
UpdateLease     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateReplyServerIp
;
;       Purpose:        Update reply server IP
;
;       Parameters:     ES:EDI    DHCP message
;                       ECX       Message size
;
;       Returns:        ECX       New message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateReplyServerIp   Proc near
    push eax
    push ebx
    push edx
;
    mov al,54
    call FindOption
    jc urpsiDone
;
    GetIpAddress
    mov es:[ebx+2],edx

urpsiDone:
    pop edx
    pop ebx
    pop eax
    ret
UpdateReplyServerIp     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateReqServerIp
;
;       Purpose:        Update req server IP
;
;       Parameters:     ES:EDI    DHCP message
;                       ECX       Message size
;
;       Returns:        ECX       New message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateReqServerIp   Proc near
    push eax
    push ebx
;
    mov al,54
    call FindOption
    jc urqsiDone
;
    push ds
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:dhcp_server    
    mov es:[ebx+2],eax
    pop ds

urqsiDone:
    pop ebx
    pop eax
    ret
UpdateReqServerIp       Endp
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveDiscover
;
;       Purpose:        Receive discover
;
;       Parameters:     ES:EDI  UDP data
;                       GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                   data-proc

DiscReqOptTab:
dro00 DW OFFSET ServReqMaskSize,    OFFSET ServReqMaskData
dro01 DW OFFSET ServReqGwSize,      OFFSET ServReqGwData
dro02 DW OFFSET ServReqDnsSize,     OFFSET ServReqDnsData
dro03 DW OFFSET ServLeaseSize,      OFFSET ServLeaseData
dro04 DW OFFSET ServReqIdSize,      OFFSET ServReqIdData
dro05 DW OFFSET ServRenewSize,      OFFSET ServRenewData
dro06 DW OFFSET ServRebindSize,     OFFSET ServRebindData
dro07 DW -1


ReceiveDiscover Proc near
    push ds
    push es
    push fs
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    mov eax,SEG data
    mov ds,eax
    mov al,ds:dhcp_done
    or al,al
    jz discover_req_done
;    
    mov al,ds:dhcp_enabled
    or al,al
    jz discover_not_relay
;
    call FindRelay
    jc discover_relay_alloc
;
    mov fs,eax
    jmp discover_relay_ok

discover_relay_alloc:
    push ecx
    mov ebx,OFFSET dhcp_relay_arr
    mov ecx,256

discover_alloc_mac_loop:
    mov ax,ds:[ebx]
    or ax,ax
    jz discover_alloc_mac_do
;
    add ebx,2
    loop discover_alloc_mac_loop

discover_alloc_fail:
    pop ecx
    jmp discover_req_done

discover_alloc_mac_do:
    mov al,es:[edi].dhcp_hw_len
    or al,al
    jz discover_alloc_fail
;
    push es
    mov eax,SIZE dhcp_relay_entry
    AllocateSmallGlobalMem
    mov eax,es
    mov fs,eax
    pop es
    mov ds:[ebx],ax
;
    mov fs:dre_last_update,0
    mov fs:dre_last_update+4,0
    mov fs:dre_ip,0
    mov fs:dre_driver,gs
    mov al,es:[edi].dhcp_hw_type
    mov fs:dre_hw_type,al
;
    mov al,es:[edi].dhcp_hw_len
    mov fs:dre_hw_len,al
;
    movzx ecx,al

    xor ebp,ebp

discover_alloc_mac_copy:
    mov al,es:[ebp+edi].dhcp_hw_addr
    mov fs:[ebp].dre_hw_data,al
    inc ebp
    loop discover_alloc_mac_copy
;
    pop ecx

discover_relay_ok:
    push es
    push ecx
;
    mov eax,ds:dhcp_ip2
    or eax,eax
    jz discover_req_ip_size_ok
;
    call GetRequestedIpSize
    add ecx,eax

discover_req_ip_size_ok:
    call GetLeaseSize
    add ecx,eax
;
    mov eax,es
    mov fs,eax
    mov esi,edi
;
    push fs
    mov fs,ds:dhcp_driver_sel
    call CreateUnboundDhcpBroadcast
    pop fs
    pop ecx
;
    push ecx
    push edi
    sub esi,8
    sub edi,8
    add ecx,8

discover_relay_copy_data:
    mov al,fs:[esi]
    stosb
    inc esi
    loop discover_relay_copy_data
;
    pop edi
    pop ecx
;
    mov eax,ds:dhcp_ip2
    or eax,eax
    jz discover_update_req_ip_ok
;
    call UpdateRequestedIp

discover_update_req_ip_ok:
    call UpdateReqServerIp
    call UpdateLease
;
    or es:[edi].dhcp_flags,80h
;
    mov fs,ds:dhcp_driver_sel
    call SendDhcpBroadcast
;
    pop es
    jmp discover_req_done

discover_not_relay:
    mov eax,ds:dhcp_ip2
    or eax,eax
    jz discover_req_done
;
    mov eax,gs
    mov fs,eax
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    mov eax,ecx
    sub eax,esi
    sub eax,SIZE dhcp_header
    sub ecx,eax
    mov edx,ecx
    mov ebx,OFFSET DiscReqOptTab

discover_req_size_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz discover_req_size_ok
;
    call word ptr cs:[ebx]
    add edx,ecx
    add ebx,4
    jmp discover_req_size_loop

discover_req_size_ok:
    mov ecx,edx
    call CreateDhcpReplyBroadcast
;    
    push fs
    push ecx
    push esi
    push edi
;
    mov es:[edi].dhcp_op,2
    mov al,[esi].dhcp_hw_type
    mov es:[edi].dhcp_hw_type,al
    mov al,[esi].dhcp_hw_len
    mov es:[edi].dhcp_hw_len,al
    mov es:[edi].dhcp_hops,0
    mov eax,[esi].dhcp_id
    mov es:[edi].dhcp_id,eax     
    mov es:[edi].dhcp_elapsed,0
    mov es:[edi].dhcp_flags,80h
    mov es:[edi].dhcp_client_ip,0
    mov es:[edi].dhcp_relay_ip,0
    mov es:[edi].dhcp_magic,63538263h
    mov es:[edi].dhcp_msg_code,53
    mov es:[edi].dhcp_msg_len,1
    mov es:[edi].dhcp_msg_type,2
    call SetHwAddress

discover_server_loop:
    call FindServer
    jc discover_req_new

discover_ident_init:
    mov fs,eax
    call InitServerSel
    mov eax,fs:dsd_local_ip
    jmp discover_req_options

discover_req_new:
    call CreateServerSel
    jmp discover_server_loop

discover_req_options:
    mov es:[edi].dhcp_req_ip,eax
;       
    mov eax,SEG data
    mov ds,eax
    GetIpAddress
    mov es:[edi].dhcp_server_ip,edx
;
    add esi,SIZE dhcp_header
    add edi,SIZE dhcp_header
    sub ecx,SIZE dhcp_header

    mov ebx,OFFSET DiscReqOptTab

discover_req_data_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz discover_req_data_ok
;
    call word ptr cs:[ebx+2]
    add ebx,4
    jmp discover_req_data_loop

discover_req_data_ok:
    mov al,-1
    stosb
    dec ecx
;
    xor al,al
    rep stosb
;    
    pop edi
    pop esi
    pop ecx
    pop fs
    call SendDhcpBroadcast

discover_req_done:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop fs    
    pop es
    pop ds
    ret
ReceiveDiscover Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveRelayOffer
;
;       Purpose:        Receive relay offer
;
;       Parameters:     ES:EDI  UDP data
;                       AX      Relay data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveRelayOffer Proc near
    push ds
    push es
    push fs
    push gs
    push ebx
    push esi
    push edi
;
    mov gs,eax
    mov fs,gs:dre_driver
;
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    call CreateUnboundDhcpBroadcast
;
    push ecx
    push edi
    sub esi,8
    sub edi,8
    add ecx,8
    rep movsb
    pop edi
    pop ecx
;
    call UpdateReplyServerIp
;
    or es:[edi].dhcp_flags,80h
    call SendDhcpBroadcast
;
    pop edi
    pop esi
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
ReceiveRelayOffer Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveRequest
;
;       Purpose:        Receive request
;
;       Parameters:     ES:EDI  UDP data
;                       GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                   data-proc

ReqReqOptTab:
rro00 DW OFFSET ServReqMaskSize,    OFFSET ServReqMaskData
rro01 DW OFFSET ServReqGwSize,      OFFSET ServReqGwData
rro02 DW OFFSET ServReqDnsSize,     OFFSET ServReqDnsData
rro03 DW OFFSET ServLeaseSize,      OFFSET ServLeaseData
rro04 DW OFFSET ServReqIdSize,      OFFSET ServReqIdData
rro05 DW OFFSET ServRenewSize,      OFFSET ServRenewData
rro06 DW OFFSET ServRebindSize,     OFFSET ServRebindData
rro07 DW -1

ReceiveRequest  Proc near
    push ds
    push es
    push fs
    push ebx
    push esi
    push edi
;
    mov eax,SEG data
    mov ds,eax
    mov al,ds:dhcp_done
    or al,al
    jz req_req_done
;    
    mov al,ds:dhcp_enabled
    or al,al
    jz req_not_relay
;
    call FindRelay
    jc req_not_relay
;
    mov fs,eax
    push es
    push ecx
;
    call GetLeaseSize
    add ecx,eax
;
    mov eax,es
    mov fs,eax
    mov esi,edi
;
    push fs
    mov fs,ds:dhcp_driver_sel
    call CreateUnboundDhcpBroadcast
    pop fs
    pop ecx
;
    push ecx
    push edi
    sub esi,8
    sub edi,8
    add ecx,8

req_relay_copy_data:
    mov al,fs:[esi]
    stosb
    inc esi
    loop req_relay_copy_data
;
    pop edi
    pop ecx
;
    call UpdateReqServerIp
    call UpdateLease
    or es:[edi].dhcp_flags,80h
;
    mov fs,ds:dhcp_driver_sel
    call SendDhcpBroadcast
;
    pop es
    jmp req_req_done

req_not_relay:
    mov eax,es
    mov ds,eax
    mov esi,edi
    call FindServer
    jc req_req_done
;
    mov fs,eax
    mov eax,[esi].dhcp_id
    cmp eax,fs:dsd_orig_ident
    jne req_req_done
;    
    mov eax,gs
    mov fs,eax
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    mov eax,ecx
    sub eax,esi
    sub eax,SIZE dhcp_header
    sub ecx,eax
    mov edx,ecx
    mov ebx,OFFSET ReqReqOptTab

req_req_size_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz req_req_size_ok
;
    call word ptr cs:[ebx]
    add edx,ecx
    add ebx,4
    jmp req_req_size_loop

req_req_size_ok:
    mov ecx,edx
    call CreateDhcpReplyBroadcast
;    
    push fs
    push ecx
    push esi
    push edi
;
    mov es:[edi].dhcp_op,2
    mov al,[esi].dhcp_hw_type
    mov es:[edi].dhcp_hw_type,al
    mov al,[esi].dhcp_hw_len
    mov es:[edi].dhcp_hw_len,al
    mov es:[edi].dhcp_hops,0
    mov eax,[esi].dhcp_id
    mov es:[edi].dhcp_id,eax     
    mov es:[edi].dhcp_elapsed,0
    mov es:[edi].dhcp_flags,80h
    mov es:[edi].dhcp_client_ip,0
    mov es:[edi].dhcp_relay_ip,0
    mov es:[edi].dhcp_magic,63538263h
    mov es:[edi].dhcp_msg_code,53
    mov es:[edi].dhcp_msg_len,1
    mov es:[edi].dhcp_msg_type,5
    call SetHwAddress
;
    call FindServer
    mov fs,eax
    mov eax,fs:dsd_local_ip
    mov es:[edi].dhcp_req_ip,eax
;       
    GetIpAddress
    mov es:[edi].dhcp_server_ip,edx
;
    add esi,SIZE dhcp_header
    add edi,SIZE dhcp_header
    sub ecx,SIZE dhcp_header

    mov ebx,OFFSET ReqReqOptTab

req_req_data_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz req_req_data_ok
;
    call word ptr cs:[ebx+2]
    add ebx,4
    jmp req_req_data_loop

req_req_data_ok:
    mov al,-1
    stosb
    dec ecx
;
    xor al,al
    rep stosb
;    
    pop edi
    pop esi
    pop ecx
    pop fs
    call SendDhcpBroadcast

req_req_done:
    pop edi
    pop esi
    pop ebx
    pop fs    
    pop es
    pop ds
    ret
ReceiveRequest Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveRelayAck
;
;       Purpose:        Receive relay ACK
;
;       Parameters:     ES:EDI  UDP data
;                       AX      Relay data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveRelayAck Proc near
    push ds
    push es
    push fs
    push gs
    push ebx
    push edx
    push esi
    push edi
;
    mov gs,eax
    mov fs,gs:dre_driver
    mov edx,es:[edi].dhcp_req_ip
    mov gs:dre_ip,edx
    GetSystemTime
    mov gs:dre_last_update,eax
    mov gs:dre_last_update+4,edx
;
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    call CreateUnboundDhcpBroadcast
;
    push ecx
    push edi
    sub esi,8
    sub edi,8
    add ecx,8
    rep movsb
    pop edi
    pop ecx
;
    call UpdateReplyServerIp
;
    or es:[edi].dhcp_flags,80h
    call SendDhcpBroadcast
;
    pop edi
    pop esi
    pop edx
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
ReceiveRelayAck Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveRelayNak
;
;       Purpose:        Receive relay NAK
;
;       Parameters:     ES:EDI  UDP data
;                       AX      Relay data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveRelayNak Proc near
    push ds
    push es
    push fs
    push gs
    push ebx
    push esi
    push edi
;
    mov gs,eax
    mov fs,gs:dre_driver
;
    mov eax,es
    mov ds,eax
    mov esi,edi
;
    call CreateUnboundDhcpBroadcast
;
    push ecx
    push edi
    sub esi,8
    sub edi,8
    add ecx,8
    rep movsb
    pop edi
    pop ecx
;
    call UpdateReplyServerIp
;
    or es:[edi].dhcp_flags,80h
    call SendDhcpBroadcast
;
    pop edi
    pop esi
    pop ebx
    pop gs
    pop fs
    pop es
    pop ds
    ret
ReceiveRelayNak Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveiServerDhcp
;
;       Purpose:        Receive notify from UDP
;
;       Parameters:     GS      Net driver selector
;                       ES:EDI      UDP data
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
    push eax
    push ebx
;
    mov eax,SEG data
    mov ds,eax
;
    mov ax,ds:dhcp_driver_sel
    mov ebx,gs
    or ax,ax
    jz receive_serv_check_enabled
;
    cmp ax,bx
    je receive_serv_free
    jmp receive_serv_ok

receive_serv_check_enabled:
    mov al,ds:dhcp_enabled
    or al,al
    jnz receive_serv_free

receive_serv_ok:
    mov ax,es:[edi].udp_source
    xchg al,ah
    cmp ax,68
    jne receive_serv_free
;
    mov ax,es:[edi].udp_dest
    xchg al,ah
    cmp ax,67
    jne receive_serv_free
;
    add edi,8
    sub ecx,8
    sub ecx,SIZE dhcp_header
    jb receive_serv_free
;
    add ecx,SIZE dhcp_header
    mov al,es:[edi].dhcp_op
    cmp al,1
    jne receive_serv_free
;
    mov al,es:[edi].dhcp_msg_code
    cmp al,53
    jne receive_serv_free
;
    movzx ebx,es:[edi].dhcp_msg_type
    cmp ebx,8
    jae receive_serv_free
;
    add ebx,ebx
    call word ptr cs:[ebx].serv_receive_tab  

receive_serv_free:
    pop ebx
    pop eax
    pop ds
    ret
ReceiveServerDhcp       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ClientSize
;
;       Purpose:        Size of client hardware address
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;
;       Returns:        ECX              Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClientSize      Proc near
    movzx ecx,ds:addr_len
    add ecx,2
    ret
ClientSize      Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ClientData
;
;       Purpose:        Copy client hardware address
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;                       ES:EDI       Position to copy at
;
;       Returns:        ES:EDI       New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClientData      Proc near
    push ds
    push esi
    push ecx
;
    movzx ecx,ds:addr_len
    mov al,61
    stosb
    mov es:[edi],cl
    inc edi
    call fword ptr fs:d_address
    rep movsb
;
    pop ecx
    pop esi
    pop ds
    ret
ClientData      Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ParamSize
;
;       Purpose:        Size of parameters
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;
;       Returns:        CX              Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParamSize       Proc near
    push ds
    push ebx
;
    mov ecx,2
    mov ebx,SEG data
    mov ds,ebx
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
    pop ebx
    pop ds
    ret
ParamSize       Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ParamData
;
;       Purpose:        Fill in param data
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;                       ES:EDI       Position to copy at
;
;       Returns:        ES:EDI       New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ParamData       Proc near
    push ds
    push ebx
    push esi
    push ecx
;
    xor cl,cl
    mov al,55
    stosb
    mov esi,edi
    inc edi
;
    mov ebx,SEG data
    mov ds,ebx
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
    mov es:[esi],cl
;
    pop ecx
    pop esi
    pop ebx
    pop ds
    ret
ParamData       Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           LeaseSize
;
;       Purpose:        Size of IP lease time
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;
;       Returns:        ECX              Size of client address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LeaseSize       Proc near
    mov ecx,6
    ret
LeaseSize       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           LeaseData
;
;       Purpose:        Copy IP lease time
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;                       ES:EDI       Position to copy at
;
;       Returns:        ES:EDI       New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LeaseData       Proc near
    push eax
;
    mov al,51
    stosb
    mov al,4
    stosb
    mov eax,DEFAULT_LEASE
    Reverse
    stosd
;
    pop eax
    ret
LeaseData       Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServerSize
;
;       Purpose:        Size of server IP
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;
;       Returns:        ECX              Size of server IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ServerSize      Proc near
    mov ecx,6
    ret
ServerSize      Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ServerData
;
;       Purpose:        Copy server IP
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;                       ES:EDI       Position to copy at
;
;       Returns:        ES:EDI       New position
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
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:dhcp_server
    stosd
;
    pop eax
    pop ds
    ret
ServerData      Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReqIpSize
;
;       Purpose:        Size of client IP
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;
;       Returns:        ECX              Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqIpSize       Proc near
    mov ecx,6
    ret
ReqIpSize       Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReqIpData
;
;       Purpose:        Copy client IP
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;                       ES:EDI       Position to copy at
;
;       Returns:        ES:EDI       New position
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
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:dhcp_wanted_ip
    stosd
;
    pop eax
    pop ds
    ret
ReqIpData       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           HostNameSize
;
;       Purpose:        Size of client host name
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;
;       Returns:        ECX              Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HostNameSize       Proc near
    push ds
    push eax
    push esi
;    
    call get_host_name
    mov ds,eax
    xor esi,esi
    mov ecx,2

hnsLoop:
    lodsb
    or al,al
    jz hnsOk
;
    inc ecx
    jmp hnsLoop

hnsOk:
    pop esi
    pop eax
    pop ds
    ret
HostNameSize       Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           HostNameData
;
;       Purpose:        Copy client host name
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;                       ES:EDI       Position to copy at
;
;       Returns:        ES:EDI       New position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HostNameData       Proc near
    push ds
    push eax
    push ecx
    push esi
;
    call get_host_name
    mov ds,eax
    xor esi,esi
;
    mov al,12
    stosb
;
    push edi
    inc edi
;    
    xor esi,esi
    xor ecx,ecx

hndLoop:
    lodsb
    or al,al
    jz hndOk
;
    stosb
    inc ecx
    jmp hndLoop

hndOk:
    pop esi
    mov es:[esi],cl
;
    pop esi
    pop ecx
    pop eax
    pop ds
    ret
HostNameData       Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DeclIpSize
;
;       Purpose:        Size of declined IP
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;
;       Returns:        ECX              Size of client IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeclIpSize      Proc near
    mov ecx,6
    ret
DeclIpSize      Endp
    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DeclIpData
;
;       Purpose:        Copy declined client IP
;
;       Parameters:     DS              Class selector
;                       FS              Driver selector
;                       ES:EDI       Position to copy at
;
;       Returns:        ES:EDI       New position
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
    mov eax,SEG data
    mov ds,eax
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
;           NAME:           DhcpDiscover
;
;           DESCRIPTION:    Send DHCP discover for a driver
;
;       PARAMETERS:         DS              Class selector
;                           FS              Driver selector
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                   data-proc

DiscOptTab:
d00 DW OFFSET ClientSize,       OFFSET ClientData
d01 DW OFFSET ParamSize,        OFFSET ParamData
d02 DW OFFSET LeaseSize,        OFFSET LeaseData
d03 DW OFFSET ReqIpSize,        OFFSET ReqIpData
d04 DW OFFSET HostNameSize,     OFFSET HostNameData
d05 DW -1

DhcpDiscover    Proc far
    mov edx,SIZE dhcp_header + 1
    mov ebx,OFFSET DiscOptTab

dhcp_disc_size_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz dhcp_disc_size_ok
;
    call word ptr cs:[ebx]
    add edx,ecx
    add ebx,4
    jmp dhcp_disc_size_loop

dhcp_disc_size_ok:
    mov ecx,edx
    push ecx
    call CreateUnboundDhcpBroadcast
    jc dhcp_disc_fail
;
    mov es:[edi].dhcp_op,1
    mov al,ds:class_id
    mov es:[edi].dhcp_hw_type,al
    mov al,ds:addr_len
    mov es:[edi].dhcp_hw_len,al
    mov es:[edi].dhcp_hops,0
    push ds
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:dhcp_ident
    or eax,eax
    jnz dhcp_ident_ok
;       
    GetSystemTime

dhcp_ident_ok:
    mov ds:dhcp_ident,eax
    pop ds
    mov es:[edi].dhcp_id,eax
    mov es:[edi].dhcp_elapsed,0
    mov es:[edi].dhcp_flags,80h
    mov es:[edi].dhcp_client_ip,0
    mov es:[edi].dhcp_req_ip,0
    mov es:[edi].dhcp_server_ip,0
    mov es:[edi].dhcp_relay_ip,0
    mov es:[edi].dhcp_magic,63538263h
    mov es:[edi].dhcp_msg_code,53
    mov es:[edi].dhcp_msg_len,1
    mov es:[edi].dhcp_msg_type,1
;
    push edi
    mov ecx,34h
    add edi,OFFSET dhcp_hw_addr
    xor eax,eax
    rep stosd
    pop edi
;
    movzx ecx,ds:addr_len
    push ds
    push edi
    call fword ptr fs:d_address
    add edi,OFFSET dhcp_hw_addr
    rep movsb
    pop edi
    pop ds
;
    push edi
    add edi,SIZE dhcp_header
    mov ebx,OFFSET DiscOptTab

dhcp_disc_data_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz dhcp_disc_data_ok
;
    call word ptr cs:[ebx+2]
    add ebx,4
    jmp dhcp_disc_data_loop

dhcp_disc_data_ok:
    mov al,-1
    stosb
;
    pop edi
    pop ecx
    call SendDhcpBroadcast
    jmp dhcp_disc_done

dhcp_disc_fail:
    pop ecx

dhcp_disc_done:
    retf32
DhcpDiscover    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DhcpRequest
;
;           DESCRIPTION:    Send DHCP request for a driver
;
;       PARAMETERS:     DS              Class selector
;                           FS              Driver selector
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                   data-proc

ReqOptTab:
ro00 DW OFFSET ClientSize,          OFFSET ClientData
ro01 DW OFFSET ParamSize,           OFFSET ParamData
ro02 DW OFFSET LeaseSize,           OFFSET LeaseData
ro03 DW OFFSET ReqIpSize,           OFFSET ReqIpData
ro04 DW OFFSET ServerSize,          OFFSET ServerData
ro05 DW OFFSET HostNameSize,        OFFSET HostNameData
ro06 DW -1

DhcpRequest     Proc far
    mov edx,SIZE dhcp_header + 1
    mov ebx,OFFSET ReqOptTab

dhcp_req_size_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz dhcp_req_size_ok
;
    call word ptr cs:[ebx]
    add edx,ecx
    add ebx,4
    jmp dhcp_req_size_loop

dhcp_req_size_ok:
    push ds
    mov eax,SEG data
    mov ds,eax
    mov al,ds:dhcp_rebind
    pop ds
;
    mov ecx,edx
    push ecx
    or al,al
    jz dhcp_req_renew
;
    call CreateUnboundDhcpBroadcast
    jmp dhcp_req_header_ok

dhcp_req_renew:
    call CreateDhcpReqBroadcast

dhcp_req_header_ok:
    jc dhcp_req_fail
;
    mov es:[edi].dhcp_op,1
    mov al,ds:class_id
    mov es:[edi].dhcp_hw_type,al
    mov al,ds:addr_len
    mov es:[edi].dhcp_hw_len,al
    mov es:[edi].dhcp_hops,0
    push ds
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:dhcp_ident
    pop ds
    mov es:[edi].dhcp_id,eax
    mov es:[edi].dhcp_elapsed,0
    mov es:[edi].dhcp_flags,80h
    mov es:[edi].dhcp_client_ip,0
    mov es:[edi].dhcp_req_ip,0
    mov es:[edi].dhcp_server_ip,0
    mov es:[edi].dhcp_relay_ip,0
    mov es:[edi].dhcp_magic,63538263h
    mov es:[edi].dhcp_msg_code,53
    mov es:[edi].dhcp_msg_len,1
    mov es:[edi].dhcp_msg_type,3
;
    push edi
    mov ecx,34h
    add edi,OFFSET dhcp_hw_addr
    xor eax,eax
    rep stosd
    pop edi
;
    movzx ecx,ds:addr_len
    push ds
    push edi
    call fword ptr fs:d_address
    add edi,OFFSET dhcp_hw_addr
    rep movsb
    pop edi
    pop ds
;
    push edi
    add edi,SIZE dhcp_header
    mov ebx,OFFSET ReqOptTab

dhcp_req_data_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz dhcp_req_data_ok
;
    call word ptr cs:[ebx+2]
    add ebx,4
    jmp dhcp_req_data_loop

dhcp_req_data_ok:
    mov al,-1
    stosb
;
    pop edi
    pop ecx
    call SendDhcpBroadcast
    jmp dhcp_req_done

dhcp_req_fail:
    pop ecx

dhcp_req_done:
    retf32
DhcpRequest     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DhcpDecline
;
;           DESCRIPTION:    Send DHCP decline for a driver
;
;       PARAMETERS:     DS              Class selector
;                           FS              Driver selector
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;       size-proc                   data-proc

DeclOptTab:
de00 DW OFFSET ClientSize,          OFFSET ClientData
de01 DW OFFSET DeclIpSize,          OFFSET DeclIpData
de02 DW OFFSET ServerSize,          OFFSET ServerData
de03 DW -1

DhcpDecline     Proc far
    mov edx,SIZE dhcp_header + 1
    mov ebx,OFFSET DeclOptTab

dhcp_decl_size_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz dhcp_decl_size_ok
;
    call word ptr cs:[ebx]
    add edx,ecx
    add ebx,4
    jmp dhcp_decl_size_loop

dhcp_decl_size_ok:
    mov ecx,edx
    push ecx
    call CreateDhcpReqBroadcast
    mov es:[edi].dhcp_op,1
    mov al,ds:class_id
    mov es:[edi].dhcp_hw_type,al
    mov al,ds:addr_len
    mov es:[edi].dhcp_hw_len,al
    mov es:[edi].dhcp_hops,0
;
    push ds
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:dhcp_ident
    pop ds
    mov es:[edi].dhcp_id,eax
    mov es:[edi].dhcp_elapsed,0
    mov es:[edi].dhcp_flags,0
    mov es:[edi].dhcp_client_ip,0
    mov es:[edi].dhcp_req_ip,0
    mov es:[edi].dhcp_server_ip,0
    mov es:[edi].dhcp_relay_ip,0
    mov es:[edi].dhcp_magic,63538263h
    mov es:[edi].dhcp_msg_code,53
    mov es:[edi].dhcp_msg_len,1
    mov es:[edi].dhcp_msg_type,4
;
    push edi
    mov ecx,34h
    add edi,OFFSET dhcp_hw_addr
    xor eax,eax
    rep stosd
    pop edi
;
    movzx ecx,ds:addr_len
    push ds
    push edi
    call fword ptr fs:d_address
    add edi,OFFSET dhcp_hw_addr
    rep movsb
    pop edi
    pop ds
;
    push edi
    add edi,SIZE dhcp_header
    mov ebx,OFFSET DeclOptTab

dhcp_decl_data_loop:
    mov ax,cs:[ebx]
    cmp ax,-1
    jz dhcp_decl_data_ok
;
    call word ptr cs:[ebx+2]
    add ebx,4
    jmp dhcp_decl_data_loop

dhcp_decl_data_ok:
    mov al,-1
    stosb
;
    pop edi
    pop ecx
    call SendDhcpBroadcast
    retf32
DhcpDecline     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddDhcpOption
;
;           DESCRIPTION:    Add a requested DHCP option to ask for
;
;       PARAMETERS:     AL              Option code
;                       ES:EDI          Callback
;                              ES:EDI   Pointer to option data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_dhcp_option_name    DB 'Add DHCP Option',0

add_dhcp_option Proc far
    push ds
    push es
    push eax
    push edx
;
    mov edx,es
    push eax
    mov eax,SIZE dhcp_option
    AllocateSmallGlobalMem
    pop eax
    mov es:dhcp_opt_code,al
    mov dword ptr es:dhcp_opt_callb,edi
    mov word ptr es:dhcp_opt_callb+4,dx
    mov eax,SEG data
    mov ds,eax
    mov ax,ds:dhcp_option_list
    mov es:dhcp_opt_next,ax
    mov ds:dhcp_option_list,es
;
    pop edx
    pop eax
    pop es
    pop ds
    retf32
add_dhcp_option Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsDhcpDone
;
;           DESCRIPTION:    Check if DHCP is finished
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public IsDhcpDone

IsDhcpDone      Proc near
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    mov al,ds:dhcp_done
    or al,al
    stc
    jz is_dhcp_done
;
    clc

is_dhcp_done:
    pop eax
    pop ds
    ret
IsDhcpDone      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsDhcpActive
;
;           DESCRIPTION:    Check if DHCP is active
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public IsDhcpActive

IsDhcpActive      Proc near
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    mov eax,ds:dhcp_server
    or eax,eax
    jnz is_dhcp_active_ok
;
    mov eax,ds:dhcp_lease
    cmp eax,1
    ja is_dhcp_active_ok
;
    stc
    jmp is_dhcp_active_done

is_dhcp_active_ok:
    clc

is_dhcp_active_done:
    pop eax
    pop ds
    ret
IsDhcpActive      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsDhcpEnabled
;
;           DESCRIPTION:    Check if DHCP is enabled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public IsDhcpEnabled

IsDhcpEnabled      Proc near
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    mov al,ds:dhcp_enabled
    or al,al
    stc
    jz is_dhcp_enabled_done
;
    clc

is_dhcp_enabled_done:
    pop eax
    pop ds
    ret
IsDhcpEnabled      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveError
;
;       Purpose:        Receive error
;
;       Parameters:         ES:EDI  UDP data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveError    Proc near
    ret
ReceiveError    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveNak
;
;       Purpose:        Receive NAK
;
;       Parameters:         ES:EDI  UDP data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveNak    Proc near
    push ds
    push eax
;       
    mov eax,SEG data
    mov ds,eax
    mov ds:dhcp_server,0
    mov ds:dhcp_lease,1    
    inc ds:dhcp_ident
;
    pop eax
    pop ds
    ret
ReceiveNak    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveOffer
;
;       Purpose:        Receive offer
;
;       Parameters:         ES:EDI  UDP data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveOffer    Proc near
    push ds
    push fs
    push eax
    push ebx
    push esi
;       
    mov eax,SEG data
    mov ds,eax
    mov al,ds:dhcp_enabled
    or al,al
    jnz receive_offer_ok
;
    mov ds:dhcp_driver_sel,gs
    jmp receive_offer_leave

receive_offer_ok:
    mov eax,es:[edi].dhcp_req_ip
    mov ds:dhcp_wanted_ip,eax
;
    mov eax,ds:dhcp_server
    or eax,eax
    jnz receive_offer_leave
;
    add edi,SIZE dhcp_header

receive_offer_loop:
    mov al,es:[edi]
    cmp al,54
    jne receive_offer_next
;
    mov eax,es:[edi+2]
    mov ds:dhcp_server,eax
;
    push es
    push edi
    mov eax,cs
    mov es,eax
    mov edi,OFFSET DhcpRequest
    NetBroadcast
    pop edi
    pop es
    jmp receive_offer_leave

receive_offer_next:
    inc edi
    sub ecx,1
    jz receive_offer_leave
;
    movzx eax,byte ptr es:[edi]
    inc eax
    add edi,eax
    sub ecx,eax
    ja receive_offer_loop

receive_offer_leave:
    pop esi
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
ReceiveOffer    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveAck
;
;       Purpose:        Receive ACK
;
;       Parameters:         ES:EDI  UDP data
;                       GS      Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveAck      Proc near
    push ds
    push fs
    push eax
    push ebx
    push edx
;
    mov edx,es:[edi].dhcp_req_ip
    mov eax,SEG data
    mov ds,eax
    mov ds:dhcp_ip,edx
;
    add edi,SIZE dhcp_header

receive_ack_loop:
    mov al,es:[edi]
    cmp al,-1
    je receive_ack_leave
;
    mov bx,ds:dhcp_option_list

receive_ack_opt_loop:
    or bx,bx
    jz receive_ack_next
;
    mov fs,ebx
    mov bx,fs:dhcp_opt_next
    cmp al,fs:dhcp_opt_code
    jne receive_ack_opt_loop
;
    push ecx
    push edi
    movzx ecx,byte ptr es:[edi+1]
    add edi,2
    call fword ptr fs:dhcp_opt_callb
    pop edi
    pop ecx

receive_ack_next:
    inc edi
    sub ecx,1
    jz receive_ack_leave
;
    movzx eax,byte ptr es:[edi]
    inc eax
    add edi,eax
    sub ecx,eax
    ja receive_ack_loop

receive_ack_leave:
    mov ds:dhcp_driver_sel,gs
    mov ds:dhcp_done,1
;
    mov eax,ds:dhcp_ip
    call define_ip
;
    mov al,ds:dhcp_rebind
    or al,al
    jz receive_ack_done
;
    call RebindGateway
    mov ds:dhcp_rebind,0

receive_ack_done:
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    ret
ReceiveAck      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveClientDhcp
;
;       Purpose:        Receive notify from UDP
;
;       Parameters:         GS      Net driver selector
;                       ES:EDI      UDP data
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
cr06    DW OFFSET ReceiveNak
cr07    DW OFFSET ReceiveError
cr08    DW OFFSET ReceiveError

rl_receive_tab:
rr00    DW OFFSET ReceiveError
rr01    DW OFFSET ReceiveError
rr02    DW OFFSET ReceiveRelayOffer
rr03    DW OFFSET ReceiveError
rr04    DW OFFSET ReceiveError
rr05    DW OFFSET ReceiveRelayAck
rr06    DW OFFSET ReceiveRelayNak
rr07    DW OFFSET ReceiveError
rr08    DW OFFSET ReceiveError

ReceiveClientDhcp       Proc near
    push ds
    push eax
    push ebx
    push edx
;
    mov eax,SEG data
    mov ds,eax
;
    mov ax,es:[edi].udp_source
    xchg al,ah
    cmp ax,67
    jne receive_cl_free
;
    mov ax,es:[edi].udp_dest
    xchg al,ah
    mov dx,ax
    cmp ax,68
    je receive_cl_dest_ok
;
    cmp ax,67
    jne receive_cl_free

receive_cl_dest_ok:
    add edi,8
    sub ecx,8
    sub ecx,SIZE dhcp_header
    jb receive_cl_free
;
    add ecx,SIZE dhcp_header
    mov al,es:[edi].dhcp_op
    cmp al,2
    jne receive_cl_free
;
    mov al,es:[edi].dhcp_msg_code
    cmp al,53
    jne receive_cl_free
;
    movzx ebx,es:[edi].dhcp_msg_type
    cmp ebx,8
    jae receive_cl_free
;
    cmp dx,67
    je receive_cl_free    
;
    call FindRelay
    jc receive_cl_local

receive_cl_relay:
    add ebx,ebx
    call word ptr cs:[ebx].rl_receive_tab    
    jmp receive_cl_free

receive_cl_local:
    mov eax,ds:dhcp_ident
    cmp eax,es:[edi].dhcp_id
    jne receive_cl_check
;
    add ebx,ebx
    call word ptr cs:[ebx].cl_receive_tab    
    jmp receive_cl_free

receive_cl_check:
    mov eax,ds:dhcp_server
    or eax,eax
    jz receive_cl_free
;
    add edi,SIZE dhcp_header

receive_cl_insp_loop:
    mov al,es:[edi]
    cmp al,54
    jne receive_cl_insp_next
;
    mov eax,es:[edi+2]
    cmp eax,ds:dhcp_server
    je receive_cl_free
;
    mov ds:dhcp_server,0
    mov ds:dhcp_lease,1    
    inc ds:dhcp_ident
    jmp receive_cl_free

receive_cl_insp_next:
    inc edi
    sub ecx,1
    jz receive_cl_free
;
    movzx eax,byte ptr es:[edi]
    inc eax
    add edi,eax
    sub ecx,eax
    ja receive_cl_insp_loop

receive_cl_free:
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
ReceiveClientDhcp       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           define_lease
;
;       Purpose:        Define lease
;
;       Parameters:     ECX          Size of msg
;                       ES:EDI       Lease time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_lease_time      Proc far
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    or ecx,ecx
    jz define_lease_done
;
    mov eax,es:[edi]
    Reverse
    sub eax,10
    ja define_lease_save
;
    mov eax,1

define_lease_save:
    mov ds:dhcp_lease,eax

define_lease_done:
    pop eax
    pop ds
    retf32
define_lease_time      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           HandleDiscoverDhcp
;
;       Purpose:        Handle discover DHCP
;
;       Parameters:     DS           Data seg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleDiscoverDhcp   Proc near
    mov ds:dhcp_driver_sel,0
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET DhcpDiscover
    NetBroadcast
;
    mov ax,500
    WaitMilliSec    
;    
    mov ax,ds:dhcp_driver_sel
    or ax,ax
    jz hdidFailed
;
    mov edx,ds:dhcp_ip
    call is_ip_in_use
    jc hdidOk
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET DhcpDecline
    NetBroadcast

hdidFailed:
    stc
    jmp hdidDone

hdidOk:
    clc

hdidDone:
    ret
HandleDiscoverDhcp  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           HandleRenewDhcp
;
;       Purpose:        Handle renew DHCP
;
;       Parameters:     DS           Data seg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRenewDhcp   Proc near
    mov ds:dhcp_driver_sel,0
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET DhcpRequest
    NetBroadcast
;
    mov ax,500
    WaitMilliSec    
;    
    mov ax,ds:dhcp_driver_sel
    or ax,ax
    jz hrdFailed
;
    mov edx,ds:dhcp_ip
    call is_ip_in_use
    jc hrdOk
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET DhcpDecline
    NetBroadcast

hrdFailed:
    stc
    jmp hdidDone

hrdOk:
    clc

hrdDone:
    ret
HandleRenewDhcp  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           HandleDisabledDhcp
;
;       Purpose:        Handle disabled DHCP
;
;       Parameters:     DS           Data seg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleDisabledDhcp   Proc near
    mov ds:dhcp_done,1
;    
    call get_gateway_driver
    jnc hddOk
;
    mov eax,250
    call ping_gateway
    jc hddDone
;    
    call get_gateway_driver
    jc hddDone

hddOk:
    mov ds:dhcp_driver_sel,bx

hddDone:    
    mov eax,ds:dhcp_ip
    call define_ip
    ret
HandleDisabledDhcp   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           dhcp_thread
;
;           DESCRIPTION:    dhcp thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dhcp_thread_name    DB 'DHCP',0

ip_name         DB 'IP',0
host_name       DB 'HOST',0

dhcp_thread_pr:
    mov ax,250
    WaitMilliSec
;
    mov ebx,SEG data
    mov ds,ebx
;       
    GetIpAddress
    mov ds:dhcp_ip,edx
;
    mov ecx,8

dtRedo:
    mov al,ds:dhcp_enabled
    or al,al
    jz dtDisabled

dtEnabled:
    mov eax,ds:dhcp_server
    or eax,eax
    jz dtDiscover

dtRenew:
    inc ds:dhcp_ident
    call HandleRenewDhcp
    jnc dtNext

dtFail:
    mov ecx,8
    mov ds:dhcp_server,0
    mov ds:dhcp_lease,1    
    mov ds:dhcp_rebind,1    
    inc ds:dhcp_ident

dtDiscover:
    call HandleDiscoverDhcp
    jnc dtNext
;    
    mov ds:dhcp_server,0
    mov ds:dhcp_lease,1    
    jmp dtNext

dtDisabled:
    call HandleDisabledDhcp
    jmp dtDone

dtNext:
    or ecx,ecx
    jz dtWait
;
    sub ecx,1
    jnz dtWait
;
    mov ds:dhcp_done,1

dtWait:
    mov ax,1000
    WaitMilliSec    
;
    sub ds:dhcp_lease,1
    jnz dtWait
;
    jmp dtRedo

dtDone:
    retf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetDhcpEntry
;
;           DESCRIPTION:    Get DHCP entry
;
;           PARAMETERS:     AX          Entry #
;
;           RETURNS:        EDX         IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dhcp_entry_name    DB 'Get DHCP Entry', 0

get_dhcp_entry Proc far
    push ds
;
    mov ebx,SEG data
    mov ds,ebx
    mov ebx,OFFSET dhcp_relay_arr
    or ah,ah
    jnz gdeFail
;  
    movzx eax,ax
    add eax,eax
    add ebx,eax
    mov ax,ds:[ebx]
    or ax,ax
    jz gdeFail
;
    mov ds,eax
    mov eax,ds:dre_last_update
    mov edx,ds:dre_last_update+4
    mov ebx,ds:dre_ip
    or ebx,ebx
    jz gdeFail
;
    clc
    jmp gdeDone

gdeFail:
    stc

gdeDone:
    pop ds
    retf32
get_dhcp_entry Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_task_dhcp
;
;           DESCRIPTION:    Init dhcp driver, tasking part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dhcp_name           DB 'DHCP', 0
dhcp_ip_name        DB 'DHCP.IP',0

    public init_task_dhcp

init_task_dhcp       PROC near
    mov ebx,SEG data
    mov ds,ebx
    mov es,ebx
    mov es:dhcp_option_list,0
    mov es:dhcp_driver_sel,0
    mov es:dhcp_server,0
    mov es:dhcp_done,0
    mov es:dhcp_rebind,0
    mov es:dhcp_lease,DEFAULT_LEASE
    GetIpAddress
    mov es:dhcp_wanted_ip,edx
    mov es:dhcp_ident,0
    mov edi,OFFSET dhcp_serv_arr
    mov ecx,256
    xor ax,ax
    rep stosw
;
    mov edi,OFFSET dhcp_relay_arr
    mov ecx,256
    xor ax,ax
    rep stosw
;
    mov eax,es
    mov ds,eax
    mov eax,cs
    mov es,eax
;
    mov edi,OFFSET dhcp_ip_name
    call GetIPNumber
    mov ds:dhcp_ip2,eax
;
    mov ds:dhcp_enabled,1
    mov edi,OFFSET dhcp_name
    call GetValue       
    jc init_dhcp_enabled_ok
;
    mov ds:dhcp_enabled,al

init_dhcp_enabled_ok:
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET get_dhcp_entry
    mov edi,OFFSET get_dhcp_entry_name
    xor dx,dx
    mov ax,get_dhcp_entry_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_dhcp_option
    mov edi,OFFSET add_dhcp_option_name
    xor cl,cl
    mov ax,add_dhcp_option_nr
    RegisterOsGate
;
    mov al,51
    mov edi,OFFSET define_lease_time
    AddDhcpOption
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET dhcp_thread_pr
    mov edi,OFFSET dhcp_thread_name
    mov ax,3
    mov ecx,stack0_size
    CreateThread
;
    ret
init_task_dhcp       ENDP

code    ENDS

    END
