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
; IP.ASM
; IP protocol
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
INCLUDE ip.inc
INCLUDE udp.inc

    extrn init_task_dhcp:near
    extrn init_task_cache:near
    extrn init_task_dns:near
    extrn init_task_icmp:near
    extrn init_task_udp:near
    extrn init_task_ntp:near
    extrn init_task_tcp:near
    extrn init_task_syslog:near
    extrn dhcp_link_up:near

    extrn init_cache:near
    extrn IsDhcpDone:near
    extrn IsDhcpEnabled:near
    extrn CalcUdpCheckSum:near

Reverse MACRO
    xchg al,ah
    rol eax,16
    xchg al,ah
        ENDM

data    SEGMENT byte public 'DATA'

my_ip               DD ?
bc_ip               DD ?
ip_mask             DD ?
gateway             DD ?
reroute_src         DD ?
reroute_dst         DD ?
reroute_ip          DD ?
ip_handle               DW ?
curr_id             DW ?
host_name_sel       DW ?
protocol_count      DW ?
protocol_arr        DW 16 DUP(?)
dhcp_no_netmask     DB ?

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ConvertOne
;
;           description:    Convert one digit
;
;           RETURNS:        AL          Digit
;                           SS:BP   Result buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvertOne      Proc near
    push ax
    push cx
;
    cmp al,100
    jb conv_10_cond
;
    xor ah,ah
    mov cl,100
    div cl
    add al,'0'
    mov [bp],al
    inc bp
    mov al,ah
    jmp conv_10

conv_10_cond:   
    cmp al,10
    jb conv_1

conv_10:
    xor ah,ah
    mov cl,10
    div cl
    add al,'0'
    mov [bp],al
    inc bp
    mov al,ah

conv_1:
    add al,'0'
    mov [bp],al
    inc bp
;
    pop cx
    pop ax
    ret
ConvertOne      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteIpEnv
;
;           description:    Write IP address to sys-env
;
;           RETURNS:        EDX         IP address
;                           ES:EDI  Variabel name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public WriteIpEnv

WriteIpEnv      Proc near
    push ds
    push es
    pushad
    sub sp,20
    mov bp,sp
;
    mov al,dl
    call ConvertOne
    mov al,'.'
    mov [bp],al
    inc bp
    shr edx,8
;
    mov al,dl
    call ConvertOne
    mov al,'.'
    mov [bp],al
    inc bp
    shr edx,8
;
    mov al,dl
    call ConvertOne
    mov al,'.'
    mov [bp],al
    inc bp
    shr edx,8
;
    mov al,dl
    call ConvertOne
    xor al,al
    mov [bp],al
;
    OpenSysEnv
;
    mov ax,es
    mov ds,ax
    mov si,di
    mov ax,ss
    mov es,ax
    mov di,sp
    AddEnvVar
    CloseEnv
;
    add sp,20
    popad
    pop es
    pop ds
    ret
WriteIpEnv      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPppIP
;
;           description:    Get PPP IP address
;
;           RETURNS:        NC          Valid
;                           EDX         My Internet IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ppp_ip_name DB 'Get PPP IP',0

get_ppp_ip      Proc far
    push ds
    mov dx,SEG data
    mov ds,dx
    mov edx,ds:my_ip
    clc
    pop ds
    retf32
get_ppp_ip      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPppDns
;
;           description:    Get PPP DNS IP address
;
;           RETURNS:        EAX         Primary DNS IP address
;                           EDX         Secondary DNS IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ppp_dns_name    DB 'Get PPP DNS IP',0

get_ppp_dns     Proc far
    xor eax,eax
    xor edx,edx
    retf32
get_ppp_dns     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           hook_ip
;
;       Purpose:        register IP receiver callback
;
;       Parameters:     AL          Protocol
;                       ES:EDI      Receiver callback
;                           AX          Size of options
;                           BX          Id
;                           CX          Size of data
;                           EDX         Source IP address
;                           DS:ESI      Options
;                           ES:EDI      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_ip_name    DB 'Hook IP',0

hook_ip Proc far
    push ds
    push es
    push eax
    push bx
;
    push ax
    mov bx,es
    mov eax,SIZE ip_protocol_data
    AllocateSmallGlobalMem
    mov dword ptr es:prot_callback,edi
    mov word ptr es:prot_callback+4,bx
    pop ax
    mov es:prot_id,al
;
    mov ax,SEG data
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
    retf32
hook_ip Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           get_ip_address
;
;       Purpose:        Get IP address of my node
;
;       Returns:        EDX         IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ip_address_name     DB 'Get IP Address',0

get_ip_address  Proc far
    push ds
;
    mov dx,SEG data
    mov ds,dx
    mov edx,ds:my_ip
;
    pop ds
    retf32
get_ip_address  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           get_gateway
;
;       Purpose:        Get IP address of gateway
;
;       Returns:        EDX         IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_gateway_name    DB 'Get Gateway',0

get_gateway     Proc far
    push ds
;
    mov dx,SEG data
    mov ds,dx
    mov edx,ds:gateway
;
    pop ds
    retf32
get_gateway     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           get_ip_mask
;
;       Purpose:        Get IP mask
;
;       Returns:        EDX         IP mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ip_mask_name    DB 'Get IP Mask',0

get_ip_mask     Proc far
    push ds
;
    mov dx,SEG data
    mov ds,dx
    mov edx,ds:ip_mask
;
    pop ds
    retf32
get_ip_mask     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           create_ip_header
;
;       Purpose:        create an IP header, and allocate space for data
;
;       Parameters:     AL          Protocol
;                       AH          Time to live
;                       ECX         Size of data
;                       EDX         Destination IP
;                       DS:ESI  Options
;
;       Returns:        ES:EDI  Ip data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_ip_header_name   DB 'Create IP Header',0

create_ip_header    Proc far
    push ds
    push fs
    push eax
    push bx
    push ecx
    push esi
    push ebp

create_header_dhcp_loop:
    call IsDhcpDone
    jnc create_header_dhcp_done
;
    push ax
    mov ax,10
    WaitMilliSec
    pop ax
    jmp create_header_dhcp_loop

create_header_dhcp_done:
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
    mov bx,SEG data
    mov fs,bx
    mov bx,fs:ip_handle
;
    cmp edx,fs:my_ip
    je create_header_local
;
    cmp dl,127
    je create_header_local
;
    push edx
    and edx,fs:ip_mask
    mov eax,fs:my_ip
    and eax,fs:ip_mask
    cmp eax,edx
    pop edx
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

create_header_local:
    mov di,6
    movzx eax,cx
    add ax,di
    AllocateSmallGlobalMem
    mov es:[di].ip_source,edx
    jmp create_header_fill

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
    mov es:[di].ip_frags,40h
    pop ax
    mov es:[di].ip_ttl,ah
    mov es:[di].ip_proto,al
    mov es:[di].ip_checksum,0
    mov ax,SEG data
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
    retf32
create_ip_header    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CalcChecksum
;
;       Purpose:        Calculate checksum for IP header
;
;       Parameters:         DS:DI   IP header
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
    xor     dx,dx
    clc
    
calc_checksum_loop:
    lodsw
    adc     dx,ax
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

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           send_ip_data
;
;       Purpose:        send IP data
;
;       Parameters:     ES          Data selector, IP datagram
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_ip_data_name       DB 'Send IP Data',0

send_ip_data    Proc far
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
    mov ax,SEG data
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
    mov ax,fs
    mov ds,ax
    mov esi,OFFSET gateway
    SendNet
    jmp send_done

send_self:
    xor eax,eax
    mov ds,ax
    mov ax,cs
    push eax
    xor ax,ax
    push ax
    call near ptr Receive
;
    xor ax,ax
    mov ds,ax
    FreeMem
    jmp send_done

send_local_net:
    push ds:[di].ip_dest
    mov ax,ss
    mov ds,ax
    movzx esi,sp
    SendNet
    pop eax

send_done:
    pop edi
    pop esi
    pop ecx
    pop dx
    pop bx
    pop eax
    pop fs
    pop ds
    retf32
send_ip_data    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           create_broadcast_ip
;
;       Purpose:        create a broadcast IP header, and allocate space for data
;
;       Parameters:     AL          Protocol
;                       AH          Time to live
;                       ECX         Size of data
;                       DS:ESI      Options
;                       FS          Driver handle
;
;       Returns:        ES:EDI  Ip data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_broadcast_ip_name    DB 'Create Broadcast IP',0

create_broadcast_ip     Proc far
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
create_broad_opt_loop:
    mov al,[esi]
    or al,al
    jz create_broad_alloc
    inc esi
    inc cx
    cmp al,1
    jz create_broad_opt_loop
;
    movzx eax,byte ptr [esi]
    dec al
    add cx,ax
    add esi,eax
    jmp create_broad_opt_loop

create_broad_alloc:     
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
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:ip_handle
    GetBroadcastBuffer
    pop ax
    pop cx
    pop dx
    pop ds
    jc create_broad_fail

create_broad_fill:
    mov bp,di
    mov es:[0],di
    dec ax
    shr ax,2
    inc ax
    or al,40h
    mov es:[di].ip_hdr_ver,al
    mov es:[di].ip_tos,0
    xchg cl,ch
    mov es:[di].ip_size,cx
    mov es:[di].ip_frags,40h
    mov es:[di].ip_ttl,dh
    mov es:[di].ip_proto,dl
    mov es:[di].ip_checksum,0
;
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:curr_id
    inc ds:curr_id
    xchg al,ah
    mov es:[di].ip_id,ax
    mov eax,ds:bc_ip
    mov es:[di].ip_source,eax
    mov es:[di].ip_dest,-1
    pop ds
;
    add edi,SIZE ip_header
create_broad_copy_opt:
    mov al,[esi]
    or al,al
    jz create_broad_pad
    movs byte ptr es:[edi],ds:[esi]
    cmp al,1
    je create_broad_copy_opt
    movzx ecx,byte ptr [esi]
    rep movs byte ptr es:[edi],ds:[esi]
    jmp create_broad_copy_opt

create_broad_pad:
    mov si,di
    sub si,bp
    xor al,al
create_broad_pad_loop:
    test si,3
    jz create_broad_ok
    stos byte ptr es:[edi]
    inc si
    jmp create_broad_pad_loop           

create_broad_fail:
    xor ax,ax
    mov es,ax
    xor edi,edi
    stc
    jmp create_broad_done

create_broad_ok:
    clc

create_broad_done:
    pop ebp
    pop esi
    pop ecx
    pop bx
    pop eax
    retf32
create_broadcast_ip     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CreateUnboundIp
;
;       Purpose:        create a broadcast IP header and use IP = 0 as source
;
;       Parameters:     AL          Protocol
;                       AH          Time to live
;                       ECX         Size of data
;                       DS:ESI      Options
;                       FS          Driver handle
;
;       Returns:        ES:EDI  Ip data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CreateUnboundIp

CreateUnboundIp     Proc near
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

create_unb_broad_opt_loop:
    mov al,[esi]
    or al,al
    jz create_unb_broad_alloc
;
    inc esi
    inc cx
    cmp al,1
    jz create_unb_broad_opt_loop
;
    movzx eax,byte ptr [esi]
    dec al
    add cx,ax
    add esi,eax
    jmp create_unb_broad_opt_loop

create_unb_broad_alloc:     
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
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:ip_handle
    GetBroadcastBuffer
    pop ax
    pop cx
    pop dx
    pop ds
    jc create_unb_broad_fail

create_unb_broad_fill:
    mov bp,di
    mov es:[0],di
    dec ax
    shr ax,2
    inc ax
    or al,40h
    mov es:[di].ip_hdr_ver,al
    mov es:[di].ip_tos,0
    xchg cl,ch
    mov es:[di].ip_size,cx
    mov es:[di].ip_frags,40h
    mov es:[di].ip_ttl,dh
    mov es:[di].ip_proto,dl
    mov es:[di].ip_checksum,0
;
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:curr_id
    inc ds:curr_id
    xchg al,ah
    mov es:[di].ip_id,ax
    mov es:[di].ip_source,0
    mov es:[di].ip_dest,-1
    pop ds
;
    add edi,SIZE ip_header

create_unb_broad_copy_opt:
    mov al,[esi]
    or al,al
    jz create_unb_broad_pad
;
    movs byte ptr es:[edi],ds:[esi]
    cmp al,1
    je create_unb_broad_copy_opt
;
    movzx ecx,byte ptr [esi]
    rep movs byte ptr es:[edi],ds:[esi]
    jmp create_unb_broad_copy_opt

create_unb_broad_pad:
    mov si,di
    sub si,bp
    xor al,al

create_unb_broad_pad_loop:
    test si,3
    jz create_unb_broad_ok
;
    stos byte ptr es:[edi]
    inc si
    jmp create_unb_broad_pad_loop           

create_unb_broad_fail:
    xor ax,ax
    mov es,ax
    xor edi,edi
    stc
    jmp create_unb_broad_done

create_unb_broad_ok:
    clc

create_unb_broad_done:
    pop ebp
    pop esi
    pop ecx
    pop bx
    pop eax
    ret
CreateUnboundIp     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           send_broadcast_ip
;
;       Purpose:        send broadcast IP data
;
;       Parameters:     ES          Data selector, IP datagram
;                       FS          Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_broadcast_ip_name  DB 'Send Broadcast IP',0

send_broadcast_ip       Proc far
    push ds
    push eax
    push bx
    push ecx
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
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:ip_handle
    SendBroadcast
;
    pop edi
    pop ecx
    pop bx
    pop eax
    pop ds
    retf32
send_broadcast_ip       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           create_driver_ip
;
;       Purpose:        create an IP header for a specific driver, and allocate space for data
;
;       Parameters:     AL          Protocol
;                       AH          Time to live
;                       ECX         Size of data
;                       EDX         IP address
;                       DS:ESI      Options
;                       FS          Driver handle
;
;       Returns:        ES:EDI  Ip data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_driver_ip_name    DB 'Create Driver IP',0

create_driver_ip     Proc far
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

create_driver_opt_loop:
    mov al,[esi]
    or al,al
    jz create_driver_alloc
    inc esi
    inc cx
    cmp al,1
    jz create_driver_opt_loop
;
    movzx eax,byte ptr [esi]
    dec al
    add cx,ax
    add esi,eax
    jmp create_driver_opt_loop

create_driver_alloc:     
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
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:ip_handle
    GetNetDriverBuffer
    mov es:[di].ip_dest,edx
;
    pop ax
    pop cx
    pop dx
    pop ds
    jc create_driver_fail

create_driver_fill:
    mov bp,di
    mov es:[0],di
    dec ax
    shr ax,2
    inc ax
    or al,40h
    mov es:[di].ip_hdr_ver,al
    mov es:[di].ip_tos,0
    xchg cl,ch
    mov es:[di].ip_size,cx
    mov es:[di].ip_frags,40h
    mov es:[di].ip_ttl,dh
    mov es:[di].ip_proto,dl
    mov es:[di].ip_checksum,0
;
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:curr_id
    inc ds:curr_id
    xchg al,ah
    mov es:[di].ip_id,ax
    mov eax,ds:bc_ip
    mov es:[di].ip_source,eax
    pop ds
;
    add edi,SIZE ip_header

create_driver_copy_opt:
    mov al,[esi]
    or al,al
    jz create_driver_pad
    movs byte ptr es:[edi],ds:[esi]
    cmp al,1
    je create_driver_copy_opt
    movzx ecx,byte ptr [esi]
    rep movs byte ptr es:[edi],ds:[esi]
    jmp create_driver_copy_opt

create_driver_pad:
    mov si,di
    sub si,bp
    xor al,al
    
create_driver_pad_loop:
    test si,3
    jz create_driver_ok
    stos byte ptr es:[edi]
    inc si
    jmp create_driver_pad_loop           

create_driver_fail:
    xor ax,ax
    mov es,ax
    xor edi,edi
    stc
    jmp create_driver_done

create_driver_ok:
    clc

create_driver_done:
    pop ebp
    pop esi
    pop ecx
    pop bx
    pop eax
    retf32
create_driver_ip     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           send_driver_ip
;
;       Purpose:        send driver IP data
;
;       Parameters:     ES          Data selector, IP datagram
;                       FS          Driver selector
;                       DS:ESI      Dest address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_driver_ip_name  DB 'Send Driver IP',0

send_driver_ip       Proc far
    push ds
    push eax
    push bx
    push ecx
    push edi
;
    push ds
    mov ax,es
    mov ds,ax
    mov di,ds:[0]
    call CalcChecksum
;
    movzx ecx,ds:[di].ip_size
    xchg cl,ch
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:ip_handle
;
    pop ds
    SendNetDriver
;
    pop edi
    pop ecx
    pop bx
    pop eax
    pop ds
    retf32
send_driver_ip       Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           receive
;
;       Purpose:        received IP data
;
;       Parameters:         ECX         size
;                       DX          packet type
;                       DS:ESI   source address
;                       ES:EDI  data selector, IP datagram
;                       FS          driver sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

no_options      DB 0

receive Proc far
    push ds
    push fs
    push gs
    push eax
    push bx
    push ecx
    push esi
    push bp
;
    mov ax,fs
    mov gs,ax
;    
    mov bp,di
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
    mov ax,SEG data
    mov ds,ax
    mov eax,es:[di].ip_source
    cmp al,127
    je receive_dhcp_done
;    
    or eax,eax
    jz receive_net_add_ok
;    
    mov bx,ds:ip_handle
    push edi
    lea edi,[di].ip_source
    AddNetSourceAddress
    pop edi

receive_net_add_ok:
    call IsDhcpDone
    jnc receive_dhcp_done
;
    mov al,es:[di].ip_proto
    cmp al,17
    jne receive_done
;
    mov al,es:[di].ip_hdr_ver
    and al,0Fh
    shl al,2
    xor ah,ah
    mov si,di
    add si,ax       
;
    mov ax,es:[si].udp_source
    xchg al,ah
    cmp ax,67
    jne receive_done
;
    mov ax,es:[si].udp_dest
    xchg al,ah
    cmp ax,68
    jne receive_done
    jmp receive_this_node

receive_dhcp_done:
    mov eax,es:[di].ip_dest
    rol eax,8
    cmp al,-1
    je receive_this_node
;
    ror eax,8
    cmp eax,ds:my_ip
    je receive_this_node
;
    cmp al,127
    je receive_this_node
;
    cmp al,239
    je receive_this_node
;
    push edx
    mov edx,ds:ip_mask
    not edx
    or edx,ds:my_ip
    cmp eax,edx
    pop edx
    je receive_this_node
;   
    rol eax,8
    cmp al,255
    je receive_done
;
    push es
    push gs    
    push di
;    
    mov ax,es
    mov gs,ax
    mov si,di
    mov cx,gs:[si].ip_size
    xchg cl,ch
    sub cx,SIZE ip_header
;
    mov edx,ds:reroute_src
    or edx,edx
    jz receive_not_reroute
;
    cmp edx,gs:[si].ip_dest
    jnz receive_test_src_reroute
;
    mov al,gs:[si].ip_proto
    cmp al,17
    jnz receive_not_reroute
;
    mov edx,gs:[si].ip_source
    mov ds:reroute_ip,edx
;
    mov edx,ds:reroute_dst
    mov gs:[si].ip_dest,edx
;
    push ds
    push di
;
    mov di,gs
    mov ds,di
    mov di,si
    call CalcCheckSum
;
    mov di,si
    mov al,ds:[di].ip_hdr_ver
    and al,0Fh
    shl al,2
    xor ah,ah
    add di,SIZE ip_header
    call CalcUdpCheckSum
;
    pop di
    pop ds
    jmp receive_not_reroute

receive_test_src_reroute:
    mov edx,ds:reroute_ip
    or edx,edx
    jz receive_not_reroute
;
    cmp edx,gs:[si].ip_dest
    jnz receive_not_reroute
;
    mov edx,ds:reroute_dst
    cmp edx,gs:[si].ip_source
    jnz receive_not_reroute
;
    mov al,gs:[si].ip_proto
    cmp al,17
    jnz receive_not_reroute
;
    mov edx,ds:reroute_src
    mov gs:[si].ip_source,edx
;
    push ds
    push di
;
    mov di,gs
    mov ds,di
    mov di,si
    call CalcCheckSum
;
    mov di,si
    mov al,ds:[di].ip_hdr_ver
    and al,0Fh
    shl al,2
    xor ah,ah
    add di,SIZE ip_header
    call CalcUdpCheckSum
;
    pop di
    pop ds

receive_not_reroute:
    mov si,di
    mov ah,gs:[si].ip_ttl
    mov al,gs:[si].ip_proto
    mov edx,gs:[si].ip_dest
;
    push si
    mov si,cs
    mov ds,si       
    mov esi,OFFSET no_options
    CreateIpHeader
    pop si
    jc receive_forward_fail
;
    sub di,SIZE ip_header
    mov cx,gs:[si].ip_size
    xchg cl,ch
    rep movs byte ptr es:[di],gs:[si]
    SendIp

receive_forward_fail:
    pop di
    pop gs
    pop es
    jmp receive_done

receive_this_node:
    mov es:[0],bp
    mov cx,ds:protocol_count
    or cx,cx
    jz receive_done
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
    call fword ptr fs:prot_callback
    jmp receive_done

receive_prot_next:
    add bx,2
    loop receive_prot_loop
    jmp receive_done

receive_pop_fail:
    pop edx
    
receive_done:
    pop bp
    pop esi
    pop ecx
    pop bx
    pop eax
    pop gs
    pop fs
    pop ds
    retf32
receive Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_gateway_driver
;
;           description:    Get driver handle for gateway
;
;           RETURNS:        BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_gateway_driver

get_gateway_driver      Proc near
    push fs
    push ax
    push esi
;    
    mov ax,SEG data
    mov fs,ax
    mov bx,fs:ip_handle
    mov esi,OFFSET gateway
    GetNetDriver
;
    pop esi
    pop ax
    pop fs
    ret
get_gateway_driver  Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           get_host_name
;
;           description:    Get host name
;
;           RETURNS:        AX  Host name sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public get_host_name

get_host_name      Proc near
    push es
    mov ax,SEG data
    mov es,ax
    mov ax,es:host_name_sel
    pop es
    ret
get_host_name  Endp    



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ping_gateway
;
;           description:    Ping gateway
;
;       Parameters:     EAX     Timeout
;
;           RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public ping_gateway

ping_gateway    Proc near
    push ds
    push edx
;    
    mov dx,SEG data
    mov ds,dx
    mov edx,ds:gateway
    Ping
;
    pop edx
    pop ds
    ret
ping_gateway  Endp      


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           is_ip_in_use
;
;           description:    Check if IP is already in use
;
;       PARAMETERS:     EDX     IP
;
;           RETURNS:        NC      In use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public is_ip_in_use

is_ip_in_use    Proc near
    push ds
    push ax
    push bx
    push esi
;    
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:ip_handle
;
    push edx
    mov ax,ss
    mov ds,ax
    mov si,sp
    movzx esi,si
;    
    IsNetAddressValid
    pop edx
;
    pop esi
    pop bx
    pop ax
    pop ds
    ret
is_ip_in_use  Endp      


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           define_ip
;
;           description:    Define IP
;
;           RETURNS:        EAX         IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public define_ip

define_ip       Proc near
    push es
    push ax
    push bx
    push edx
    push esi
    push di
;
    push ds
    mov dx,SEG data
    mov ds,dx
    mov ds:bc_ip,eax
    cmp eax,ds:my_ip
    pushf
;
    mov ds:my_ip,eax
    mov esi,OFFSET my_ip
    mov bx,ds:ip_handle
    DefineProtocolAddress
    popf
    pop ds
    je define_ip_done
;
    mov edx,eax
    mov ax,cs
    mov es,ax
    mov di,OFFSET ip_name
    call WriteIpEnv

define_ip_done:
    pop di
    pop esi
    pop edx
    pop bx
    pop ax
    pop es
    ret
define_ip       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           define_mask
;
;       Purpose:        Define IP mask
;
;       Parameters:     ECX          Size of msg
;                       ES:EDI       mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_mask     Proc far
    push ds
    push es
    push ax
    push edx
    push di
;
    mov ax,SEG data
    mov ds,ax
    mov edx,es:[di]
    cmp edx,ds:ip_mask
    je define_mask_done
;
    mov ds:ip_mask,edx
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET mask_name
    call WriteIpEnv

define_mask_done:
    pop di
    pop edx
    pop ax
    pop es
    pop ds
    retf32
define_mask     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           define_gateway
;
;       Purpose:        Define gateway
;
;       Parameters:     ECX              Size of msg
;                       ES:EDI       gateway
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_gateway  Proc far
    push ds
    push es
    push ax
    push edx
    push di
;
    mov ax,SEG data
    mov ds,ax
    mov edx,es:[di]
    cmp edx,ds:gateway
    je define_gateway_done
;
    mov ds:gateway,edx
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET gateway_name
    call WriteIpEnv

define_gateway_done:
    pop di
    pop edx
    pop ax
    pop es
    pop ds
    retf32
define_gateway  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RebindGateway
;
;       Purpose:        Rebind gateway
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RebindGateway

RebindGateway   Proc near        
    push ds
    push fs
    push ax
    push bx
    push esi
;
    mov ax,SEG data
    mov fs,ax
    mov esi,OFFSET gateway
    mov bx,fs:ip_handle
    GetNetDriver
    jc rgDone
;
    mov fs,bx
    mov ax,SEG data
    mov ds,ax
    mov esi,OFFSET gateway
    mov bx,ds:ip_handle
    ReqArp

rgDone:
    pop esi
    pop bx
    pop ax
    pop fs
    pop ds
    ret
RebindGateway   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RebindIp
;
;       Purpose:        Rebind IP
;
;       Parameters:     EDX             IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RebindIP

RebindIP        Proc near        
    push ds
    push fs
    push ax
    push bx
    push esi
    push ebp
    mov ebp,esp
    push edx
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ss
    mov fs,ax
    lea esi,[ebp-4]
    mov bx,ds:ip_handle
    GetNetDriver
    jc riDone
;
    mov fs,bx
    mov bx,ds:ip_handle
    mov ax,ss
    mov ds,ax
    lea esi,[ebp-4]
    ReqArp

riDone:
    pop edx
    pop ebp
    pop esi
    pop bx
    pop ax
    pop fs
    pop ds
    ret
RebindIP        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetIPNumber
;
;       Purpose:        received IP data
;
;       Parameters:         ES:DI   Name
;
;       Returns:        NC          Found
;                       EAX         IP number
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetIPNumber
    
GetIPNumber     Proc near
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
GetIPNumber     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetEnvStr
;
;       Purpose:        Get environment string
;
;       Parameters:     ES:DI   Name
;
;       Returns:        NC          Found
;                       AX          Sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetEnvStr
    
GetEnvStr     Proc near
    push ds
    push es
    push ebx
    push cx
    push si
    push di
;
    LockSysEnv
    mov ds,bx
    xor si,si

gesRetry:
    push di

gesLoop:
    cmpsb
    jnz gesNext
;
    mov al,es:[di]
    or al,al
    jnz gesLoop
;
    mov al,[si]
    cmp al,'='
    je gesFound

gesNext:
    pop di

gesNextBp:
    lodsb
    or al,al
    jnz gesNextBp
;
    mov al,[si]
    or al,al
    jne gesRetry
;
    stc
    jmp gesDone

gesFound:
    pop di
    xor ebx,ebx
    inc si
;
    xor cx,cx
    push si

gesSizeLoop:
    lodsb
    or al,al
    je gesSizeOk
;
    inc cx
    jmp gesSizeLoop

gesSizeOk:
    inc cx
    movzx eax,cx
    AllocateSmallGlobalMem
;
    pop si
    xor di,di
    rep movsb
    mov ax,es
    clc

gesDone:
    pushf
    UnlockSysEnv
    popf
;
    pop di
    pop si
    pop cx
    pop ebx
    pop es
    pop ds
    ret
GetEnvStr     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetValue
;
;       Purpose:        Get value from environment
;
;       Parameters:         ES:DI   Name
;
;       Returns:        NC          Found
;                   AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetValue
    
GetValue    Proc near
    push ds
    push bx
    push cx
    push si
;
    LockSysEnv
    mov ds,bx
    xor si,si
    
find_val:
    push di

find_val_loop:
    cmpsb
    jnz find_val_next
;       
    mov al,es:[di]
    or al,al
    jnz find_val_loop
    mov al,[si]
    cmp al,'='
    je find_val_found

find_val_next:
    pop di

find_val_next_bp:
    lodsb
    or al,al
    jnz find_val_next_bp
;
    mov al,[si]
    or al,al
    jne find_val
;
    xor ax,ax
    stc
    jmp find_val_done

find_val_found:
    pop di
    inc si  
    xor ax,ax

find_val_digit:
    mov bl,[si]
    inc si
    sub bl,'0'
    jc find_val_save
;
    cmp bl,10
    jnc find_val_save
;       
    mov cx,10
    mul cx
    add al,bl
    adc ah,0
    jmp find_val_digit

find_val_save:
    clc

find_val_done:
    pushf
    UnlockSysEnv
    popf
;
    pop si
    pop cx
    pop bx
    pop ds
    ret
GetValue    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           LinkUpArp
;
;       Purpose:        Send link-up ARP identification
;
;       Parameters:     FS      Driver sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

link_up_arp  Proc far
    push ds
    push bx
;    
    call dhcp_link_up
;
    call IsDhcpEnabled
    jnc link_up_done
;    
    mov bx,SEG data
    mov ds,bx
    mov esi,OFFSET gateway
    mov bx,ds:ip_handle
    ReqArp

link_up_done:
    pop bx
    pop ds    
    retf32
link_up_arp Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           IpToMac
;
;       Purpose:        Get Mac of IP address
;
;       Parameters:     EDX             IP
;                       ES:(E)DI        Mac buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ip_to_mac_name   DB 'IP to MAC',0

ip_to_mac       proc near
    push ds
    push fs
    pushad

itmDhcpLoop:
    call IsDhcpDone
    jnc itmDhcpDone
;
    push ax
    mov ax,10
    WaitMilliSec
    pop ax
    jmp itmDhcpLoop

itmDhcpDone:
    mov bx,SEG data
    mov fs,bx
    mov bx,fs:ip_handle
;
    push edx
    and edx,fs:ip_mask
    mov eax,fs:my_ip
    and eax,fs:ip_mask
    cmp eax,edx
    pop edx
    stc
    jnz itmDone
;
    push es
    push edi
    push edx
    mov ax,ss
    mov ds,ax
    mov esi,esp
    GetNetAddress
;
    mov ax,es
    mov ds,ax
    mov esi,edi
;
    pop ebx
    pop edi
    pop es
    jc itmDone
;       
    rep movs byte ptr es:[edi],ds:[esi]
    clc

itmDone:
    popad
    pop fs
    pop ds  
    ret
ip_to_mac    Endp

ip_to_mac32:
    call ip_to_mac
    retf32

ip_to_mac16   PROC far
    push edi
    movzx edi,di
    call ip_to_mac
    pop edi
    retf32
ip_to_mac16   ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetMac
;
;       Purpose:        Get Mac of local network adapter
;
;       Parameters:     ES:(E)DI        Mac buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_mac_name   DB 'Get MAC',0

get_mac proc near
    push ds
    push fs
    pushad

gmDhcpLoop:
    call IsDhcpDone
    jnc gmDhcpDone
;
    push ax
    mov ax,10
    WaitMilliSec
    pop ax
    jmp gmDhcpLoop

gmDhcpDone:
    mov bx,SEG data
    mov fs,bx
    mov bx,fs:ip_handle
;
    mov dx,SEG data
    mov ds,dx
    mov edx,ds:gateway
    push edx
    mov ax,ss
    mov ds,ax
    mov esi,esp
    GetNetMac
    pop edx

gmDone:
    popad
    pop fs
    pop ds  
    ret
get_mac    Endp

get_mac32:
    call get_mac
    retf32

get_mac16   PROC far
    push edi
    movzx edi,di
    call get_mac
    pop edi
    retf32
get_mac16   ENDP
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           IsCachable
;
;       Purpose:        Check if IP is cachable
;
;       Parameters:     ES:EDI      Ip address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_cachable     Proc far
    push ds
    push eax
    push edx
;    
    call IsDhcpDone
    jnc icCheck
;
    clc
    jmp icDone

icCheck:
    mov ax,SEG data
    mov ds,ax
    mov eax,ds:gateway
    and eax,ds:ip_mask
    mov edx,es:[edi]
    and edx,ds:ip_mask
    cmp eax,edx
    clc
    je icDone
;
    stc

icDone:
    pop edx
    pop eax
    pop ds
    retf32
is_cachable     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_tasking
;
;           DESCRIPTION:    Init tasking
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ip_name             DB 'IP',0
mask_name           DB 'NETMASK',0
gateway_name        DB 'GATEWAY',0
dhcp_no_mask_name   DB 'DHCP.NO.NETMASK',0
host_name           DB 'HOST',0
default_host        DB 'RDOS',0

init_tasking    Proc far
    push ds
    push es
    pushad
;    
    mov ax,SEG data
    mov ds,ax    
    mov ax,cs
    mov es,ax
    mov di,OFFSET ip_name
    call GetIPNumber
    mov ds:my_ip,eax
;
    mov di,OFFSET mask_name
    call GetIpNumber
    mov ds:ip_mask,eax
;
    mov di,OFFSET gateway_name
    call GetIPNumber
    mov ds:gateway,eax
;
    mov di,OFFSET host_name
    call GetEnvStr
    jnc iHostOk
;
    push ds
    push es
    mov eax,5
    AllocateSmallGlobalMem
    xor di,di
    mov si,OFFSET default_host
    mov cx,5
    rep movs byte ptr es:[di],cs:[si]
    mov ax,es
    pop es
    pop ds
    
iHostOk:    
    mov ds:host_name_sel,ax
;
    mov ds:dhcp_no_netmask,0
    mov di,OFFSET dhcp_no_mask_name
    call GetValue       
    jc iMaskValueOk
;
    mov ds:dhcp_no_netmask,al

iMaskValueOk:
    mov al,ds:dhcp_no_netmask
    push ax
;        
    call init_task_dhcp
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    pop ax
    or al,al
    jnz iMaskDone
;    
    mov al,1
    mov edi,OFFSET define_mask
    AddDhcpOption

iMaskDone:
    mov al,3
    mov edi,OFFSET define_gateway
    AddDhcpOption
;
    call init_task_cache
    call init_task_dns
    call init_task_icmp
    call init_task_udp
    call init_task_ntp
    call init_task_tcp
    call init_task_syslog
;
    popad
    pop es
    pop ds
    retf32
init_tasking    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init net driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reroute_ip_src_name    DB 'REROUTE.SRC',0
reroute_ip_dst_name    DB 'REROUTE.DST',0

init    PROC far
    mov bx,SEG data
    mov es,bx
    mov ds,bx
    mov ds:protocol_count,0
    mov ds:curr_id,1
    mov ds:reroute_ip,0
;
    mov ax,cs
    mov es,ax
    mov di,OFFSET reroute_ip_src_name
    call GetIPNumber
    mov ds:reroute_src,eax
;
    mov di,OFFSET reroute_ip_dst_name
    call GetIPNumber
    mov ds:reroute_dst,eax
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET hook_ip
    mov edi,OFFSET hook_ip_name
    xor cl,cl
    mov ax,hook_ip_nr
    RegisterOsGate
;
    mov esi,OFFSET get_ppp_ip
    mov edi,OFFSET get_ppp_ip_name
    xor cl,cl
    mov ax,get_ppp_ip_nr
    RegisterOsGate
;
    mov esi,OFFSET get_ppp_dns
    mov edi,OFFSET get_ppp_dns_name
    xor dx,dx
    mov ax,get_ppp_dns_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_ip_header
    mov edi,OFFSET create_ip_header_name
    xor cl,cl
    mov ax,create_ip_header_nr
    RegisterOsGate
;
    mov esi,OFFSET send_ip_data
    mov edi,OFFSET send_ip_data_name
    xor cl,cl
    mov ax,send_ip_data_nr
    RegisterOsGate
;
    mov esi,OFFSET create_broadcast_ip
    mov edi,OFFSET create_broadcast_ip_name
    xor cl,cl
    mov ax,create_broadcast_ip_nr
    RegisterOsGate
;
    mov esi,OFFSET send_broadcast_ip
    mov edi,OFFSET send_broadcast_ip_name
    xor cl,cl
    mov ax,send_broadcast_ip_nr
    RegisterOsGate
;
    mov esi,OFFSET create_driver_ip
    mov edi,OFFSET create_driver_ip_name
    xor cl,cl
    mov ax,create_driver_ip_nr
    RegisterOsGate
;
    mov esi,OFFSET send_driver_ip
    mov edi,OFFSET send_driver_ip_name
    xor cl,cl
    mov ax,send_driver_ip_nr
    RegisterOsGate
;
    mov esi,OFFSET get_ip_address
    mov edi,OFFSET get_ip_address_name
    xor dx,dx
    mov ax,get_ip_address_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_gateway
    mov edi,OFFSET get_gateway_name
    xor dx,dx
    mov ax,get_gateway_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_ip_mask
    mov edi,OFFSET get_ip_mask_name
    xor dx,dx
    mov ax,get_ip_mask_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET ip_to_mac16
    mov esi,OFFSET ip_to_mac32
    mov edi,OFFSET ip_to_mac_name
    mov dx,virt_es_in
    mov ax,ip_to_mac_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_mac16
    mov esi,OFFSET get_mac32
    mov edi,OFFSET get_mac_name
    mov dx,virt_es_in
    mov ax,get_mac_address_nr
    RegisterUserGate
;
    mov cx,4
    mov dx,800h
    mov ax,SEG data
    mov ds,ax
    mov ds:my_ip,0
    mov ds:bc_ip,0
    mov ds:host_name_sel,0
    mov esi,OFFSET my_ip
    mov edi,OFFSET receive
    RegisterNetProtocol
    mov ds:ip_handle,bx
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET is_cachable
    SetupNetCachable
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_tasking
    HookInitTasking
;
    mov edi,OFFSET link_up_arp
    HookNetLinkUp
;   
    call init_cache 
    clc
    ret
init    ENDP

code    ENDS

    END init
