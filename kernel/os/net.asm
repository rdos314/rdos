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
; NET.ASM
; Basic network support module. Includes basic interface + ARP
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


arp_data    STRUC

arp_class           DW ?
arp_type        DW ?
arp_hw_len          DB ?
arp_prot_len    DB ?
arp_op          DW ?

arp_data    ENDS

arp_list_struc  STRUC

arp_prev                DW ?
arp_next                DW ?
arp_timeout                 DD ?,?
arp_owner           DW ?
arp_retries                 DW ?
arp_protocol            DW ?
arp_logical_addr_len    DB ?
arp_logical_addr        DB ?        ; variable size

arp_list_struc  ENDS

arp_rec_struc   STRUC

ar_prev     DW ?
ar_next     DW ?
ar_driver       DW ?
ar_data     DB ?

arp_rec_struc   ENDS


capture_block   STRUC

cb_prev     DD ?
cb_next     DD ?
cb_sec      DD ?
cb_us       DD ?
cb_len1     DD ?
cb_len2     DD ?

capture_block   ENDS

data    SEGMENT byte public 'DATA'

capture_handle      DW ?
capture_thread      DW ?
capture_list    DD ?
capture_section     section_typ <>

arp_section             section_typ <>
arp_rec_list        DW ?
arp_send_list       DW ?
arp_answ_list       DW ?
arp_thread              DW ?
ppp_handle              DW ?
class_count             DW ?
class_arr               DW 20h DUP(?)
protocol_count      DW ?
protocol_arr        DW 20h DUP(?)

net_link_up_hooks      DB ?
net_link_up_hook_arr   DD 2*16 DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindAddress
;
;       Purpose:        Find protocol logical address
;
;       Parameters:         DS          Protocol
;                       FS:ESI  Logical address to find
;
;       Returns:        NC          Success
;                       AX          Protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindAddress     Proc near
    push es
    push cx
    push edi
;
    push ds
    mov ax,SEG data
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
    repz cmps byte ptr fs:[esi],[edi]
    pop esi
    jnz find_addr_check_failed
    jmp find_addr_ok
    
find_addr_check_failed:
    mov ax,es:prot_next
    jmp find_addr_loop

find_addr_failed:
    push ds
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:arp_section
    pop ds
    xor ax,ax
    stc
    jmp find_addr_done

find_addr_ok:
    push ds
    mov ax,SEG data
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
FindAddress     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           MoveArp
;
;       Purpose:        Move arp request
;
;       Parameters:         DS          Net_data_sel
;                       GS          ARP request
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveArp Proc near
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
MoveArp Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CheckArp
;
;       Purpose:        Check address for ARP request
;
;       Parameters:         DS          Net_data_sel
;                       ES          Protocol entry
;                       FS          Protocol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckArp    Proc near
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
    repz cmps byte ptr gs:[si],[di]
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
CheckArp    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           InsertAddress
;
;       Purpose:        Insert protocol logical address
;
;       Parameters:         DS          Protocol
;                       ES:SI   Address logical address
;                       ES:DI   Address to physical
;                       FS          Driver handle
;
;       Returns:        AX          Protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertAddress   Proc near
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
    mov ax,SEG data
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
InsertAddress   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateAddress
;
;       Purpose:        Update protocol logical address
;
;       Parameters:     DS          Protocol
;                       ES:DI       Address to physical
;                       FS          Driver handle
;                       AX          Protocol selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateAddress   Proc near
    push ds
    push es
    push ecx
    push esi
    push edi
;
    mov cx,es
    mov ds,cx
    mov es,ax
    mov si,di
;    
    mov di,OFFSET prot_logical_addr
    movzx cx,es:prot_logical_addr_len
    add di,cx
    movzx cx,es:prot_hardware_addr_len
    rep movs byte ptr es:[di],ds:[si]
;
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    ret
UpdateAddress   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendArp
;
;       Purpose:        Send arp request to all drivers
;
;       Parameters:         DS          Protocol
;                       FS:ESI  Logical address send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendArp Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,ds
    mov gs,ax
    mov ax,SEG data
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
    call fword ptr fs:d_get_link_state
    jc send_arp_driver_fail
;    
    call fword ptr fs:d_get_buffer
    clc

send_arp_driver_fail:    
    pop fs
    jc send_arp_driver_next
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
    call fword ptr fs:d_address
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
    push ds
    mov fs,ds:[bx]
    mov esi,OFFSET broadcast_addr
    mov ecx,ebp
    xor di,di
    mov dx,806h
    call fword ptr fs:d_send
    pop ds
    pop fs
    pop esi

send_arp_driver_next:       
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
SendArp Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceivedArp
;
;       Purpose:        Received arp request
;
;       Parameters:         ES          message
;                       FS          driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceivedArp     Proc near
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
    mov ax,SEG data
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
    jnc receive_arp_update_src
;
    mov edi,SIZE arp_data + OFFSET ar_data
    mov fs,bp
    call InsertAddress
    jmp receive_arp_check_dest

receive_arp_update_src:
    mov edi,SIZE arp_data + OFFSET ar_data
    mov fs,bp
    call UpdateAddress

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
    repz cmps byte ptr ds:[si],[di]
    jnz receive_arp_forward_req
;
    mov fs,bx
    mov ax,es
    mov gs,ax
;
    call fword ptr fs:d_get_link_state
    jc receive_arp_done
;
    push es
    mov cx,SIZE arp_data
    xor ah,ah
    mov al,gs:ar_data.arp_hw_len
    add cx,ax
    add cx,ax
    mov al,gs:ar_data.arp_prot_len
    add cx,ax
    add cx,ax
;
    call fword ptr fs:d_get_buffer
;
    mov bp,di
    mov cx,SIZE arp_data
    mov si,OFFSET ar_data
    rep movs byte ptr es:[di],gs:[si]
    mov es:[bp].arp_op,200h
;
    movzx ecx,gs:ar_data.arp_hw_len
    push ds
    call fword ptr fs:d_address
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
    call fword ptr fs:d_send
    pop es
    jmp receive_arp_done

receive_arp_forward_req:
    mov esi,SIZE arp_data + OFFSET ar_data
    movzx ecx,es:ar_data.arp_hw_len
    add esi,ecx
    add esi,ecx
    mov cl,es:ar_data.arp_prot_len
    add si,cx
    call FindAddress
    jc receive_arp_forward_non_existant
;
    mov ds,ax
    cmp bp,ds:prot_driver
    je receive_arp_done
;
    mov ax,es
    mov gs,ax
    mov fs,bp
;
    call fword ptr fs:d_get_link_state
    jc receive_arp_done
;
    push es
    mov cx,SIZE arp_data
    xor ah,ah
    mov al,gs:ar_data.arp_hw_len
    add cx,ax
    add cx,ax
    mov al,gs:ar_data.arp_prot_len
    add cx,ax
    add cx,ax
    call fword ptr fs:d_get_buffer
;
    mov bp,di
    mov cx,SIZE arp_data
    mov si,OFFSET ar_data
    rep movs byte ptr es:[di],gs:[si]
    mov es:[bp].arp_op,200h
;
    movzx ecx,gs:ar_data.arp_hw_len
    push ds
    call fword ptr fs:d_address
    rep movs byte ptr es:[edi],ds:[esi]
    pop ds
;
    movzx ecx,gs:ar_data.arp_prot_len
    mov si,OFFSET prot_logical_addr
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
    call fword ptr fs:d_send
    pop es
    jmp receive_arp_done

receive_arp_forward_non_existant:
; ds protocol selector
; es ARP req
; bp driver sel
    mov fs,bp    
    mov gs,fs:d_class
    mov cx,gs:driver_count
    mov bx,OFFSET driver_arr

receive_arp_forward_driver_loop:
    push gs
    push bx
    push cx
;
    cmp bp,gs:[bx]
    je receive_arp_forward_driver_next
;
    mov fs,gs:[bx]
    mov ax,es
    mov gs,ax
;
    call fword ptr fs:d_get_link_state
    jc receive_arp_forward_driver_next
;
    push es
    mov cx,SIZE arp_data
    xor ah,ah
    mov al,gs:ar_data.arp_hw_len
    add cx,ax
    add cx,ax
    mov al,gs:ar_data.arp_prot_len
    add cx,ax
    add cx,ax
    call fword ptr fs:d_get_buffer
;
    mov si,OFFSET ar_data
    mov cx,SIZE arp_data
    rep movs byte ptr es:[di],gs:[si]
;
    movzx ecx,gs:ar_data.arp_hw_len
    push ds
    push cx
    push esi
    call fword ptr fs:d_address
    rep movs byte ptr es:[edi],ds:[esi]
    pop esi
    pop cx
    pop ds
    add si,cx
;
    movzx ecx,gs:ar_data.arp_prot_len
    rep movs byte ptr es:[di],gs:[si]
;
    movzx ecx,gs:ar_data.arp_hw_len
    rep movs byte ptr es:[di],gs:[si]
;
    movzx ecx,gs:ar_data.arp_prot_len
    rep movs byte ptr es:[di],gs:[si]
;
    mov ds,fs:d_class
    mov esi,OFFSET broadcast_addr
    mov cx,SIZE arp_data
    xor ah,ah
    mov al,gs:ar_data.arp_hw_len
    add cx,ax
    add cx,ax
    mov al,gs:ar_data.arp_prot_len
    add cx,ax
    add cx,ax
    mov dx,806h
    call fword ptr fs:d_send
    pop es    

receive_arp_forward_driver_next:
    pop cx
    pop bx
    pop gs
    add bx,2
    sub cx,1
    jnz receive_arp_forward_driver_loop
;
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
ReceivedArp     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetNetDriver
;
;       Purpose:        Get bet driver for logical address
;
;       Parameters:     BX          Protocol
;                       FS:ESI  Logical address to find
;
;       Returns:        NC          Success
;                       BX          Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_net_driver_name     DB 'Get Net Driver',0

get_net_driver  Proc far
    push ds
    push ax
    mov ds,bx
    call FindAddress    
    jc get_net_driver_done
;
    mov ds,ax    
    mov bx,ds:prot_driver

get_net_driver_done:    
    pop ax
    pop ds
    retf32
get_net_driver  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RegisterNetClass
;
;       Purpose:        Register driver class
;
;       Parameters:     AL          class id
;                       CX          Size of address
;                       DS:ESI      Broadcast address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_net_class_name DB 'Register Net Class',0

register_net_class      Proc far
    push ds
    push es
    push bx
    push ecx
    push esi
    push edi
;
    push eax
    mov eax,OFFSET broadcast_addr
    add ax,cx
    AllocateSmallGlobalMem
    pop eax
    mov es:class_id,al
    mov es:addr_len,cl
    mov es:driver_count,0
    movzx ecx,cl
    mov edi,OFFSET broadcast_addr
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:class_count
    inc ds:class_count
    add bx,bx
    mov ds:[bx].class_arr,es    
;
    pop edi
    pop esi
    pop ecx
    pop bx
    pop es
    pop ds
    retf32
register_net_class      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RegisterNetProtocol
;
;       Purpose:        Register net protocol
;
;       Parameters:     CX          Size of address
;                       DX          Packet type
;                       DS:ESI      My address
;                       ES:EDI      receiver callback
;                           ECX         size
;                           DX          packet type
;                           DS:ESI      source address
;                           ES          data selector
;
;       Returns:        BX          Protocol handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_net_protocol_name      DB 'Register Net Protocol',0

default_cachable Proc far
    clc
    retf32
default_cachable Endp

register_net_protocol   Proc far
    push ds
    push es
    push ecx
    push esi
    push edi
    push bp
;
    mov bp,es
    push eax
    mov eax,OFFSET p_logical_my_addr
    add ax,cx
    AllocateSmallGlobalMem
    pop eax
    mov es:p_callback,edi
    mov word ptr es:p_callback+4,bp
    mov es:p_is_cachable,OFFSET default_cachable
    mov es:p_is_cachable+4,cs
    mov es:p_logical_addr_len,cl
    mov es:p_packet_type,dx
    mov es:p_entry_list,0
    movzx ecx,cl
    mov edi,OFFSET p_logical_my_addr
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:protocol_count
    inc ds:protocol_count
    add bx,bx
    mov ds:[bx].protocol_arr,es
    mov bx,es
;
    pop bp
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    retf32
register_net_protocol   Endp


        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SetupNetCachable
;
;       Purpose:        Setup net cachable
;
;       Parameters:     BX          Protocol handle
;                       ES:EDI      Cachable handler
;                         ES:EDI    Address to check
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_net_cachable_name      DB 'Setup Net Cachable',0

setup_net_cachable   Proc far
    push ds
;
    mov ds,bx
    mov ds:p_is_cachable,edi
    mov ds:p_is_cachable+4,es
;
    pop ds
    retf32
setup_net_cachable   Endp       
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReceiveData
;
;       Purpose:        Receive data from driver
;
;       Parameters:         FS          driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveData     Proc near
    push ds
    push es
    push gs
    push eax
    push bx
    push ecx
    push dx
    push edi

receive_data_loop:
    mov ax,SEG data
    mov ds,ax
;
    ClearSignal
    call fword ptr fs:d_preview
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
    call fword ptr fs:d_receive
    call fword ptr fs:d_remove
    jmp receive_data_handle_arp

receive_data_arp_rec:
    call fword ptr fs:d_receive
    push ds
    mov esi,edi
    mov ax,es
    mov ds,ax
    mov eax,ecx
    mov edi,OFFSET ar_data
    add eax,edi
    AllocateSmallGlobalMem
    rep movs byte ptr es:[edi],ds:[esi]
    mov bx,es
    mov ax,ds
    mov es,ax
    pop ds
    call fword ptr fs:d_remove
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
;
    call fword ptr fs:d_receive
    call fword ptr fs:d_remove
    call fword ptr gs:p_callback
;
    xor ax,ax
    mov ds,ax
    FreeMem
    jmp receive_data_loop

receive_data_norm_rec:
    call fword ptr fs:d_receive
    call fword ptr gs:p_callback
    call fword ptr fs:d_remove
;
    xor ax,ax
    mov ds,ax
    FreeMem
    jmp receive_data_loop

receive_data_prot_next:
    add bx,2
    loop receive_data_prot_loop

receive_data_remove:
    or edi,edi
    jz receive_data_norm_remove
;
    mov ecx,edi
    call fword ptr fs:d_remove
    jmp receive_data_loop

receive_data_norm_remove:
    call fword ptr fs:d_receive
    call fword ptr fs:d_remove
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
ReceiveData     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           CheckLink
;
;       Purpose:        Check link state
;
;       Parameters:     FS          driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckLink   Proc near
    call fword ptr fs:d_get_link_state
    jc check_link_down

check_link_up:
    mov ax,fs:d_link_up
    or ax,ax
    jnz check_link_done
;
    mov fs:d_link_up,1
;
    mov ax,SEG data
    mov ds,ax
    mov cl,ds:net_link_up_hooks
    or cl,cl
    je check_link_done
;
    mov bx,OFFSET net_link_up_hook_arr

check_link_loop:
    push ds
    push ebx
    push ecx
    call fword ptr [bx]
    pop ecx
    pop ebx
    pop ds
    add bx,8
    dec cl
    jnz check_link_loop
;
    jmp check_link_done

check_link_down:    
    mov fs:d_link_up,0

check_link_done:
    ret
CheckLink   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           NetThread
;
;       Purpose:        Net thread
;
;       Parameters:         BX          Driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetThread:
    mov fs,bx
    GetThread
    mov fs:d_thread,ax
net_thread_loop:
    call CheckLink
    call ReceiveData
;
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
    jmp net_thread_loop

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RegisterNetDriver
;
;       Purpose:        Register net driver
;
;       Parameters:     AL          Class
;                       ECX         Max data size
;                       DS:ESI      Dispatch table
;                       ES:EDI      Driver name
;
;       Returns:        BX          Driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_net_driver_name    DB 'Register Net Driver',0

register_net_driver     Proc far
    push ds
    push fs
    push ax
    push ecx
    push esi
;
    push es
    push edi
;
    push eax
    mov eax,SIZE driver_data
    AllocateSmallGlobalMem
    pop eax
    mov es:d_packet_size,ecx
    mov es:d_thread,0
    mov edi,OFFSET d_preview
    mov ecx,SIZE driver_data - OFFSET d_preview
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov bx,SEG data
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
    mov es:d_link_up,1
    mov bx,es

register_driver_done:
    pop edi
    pop es
;
    mov ax,cs
    mov ds,ax
    mov si,OFFSET NetThread
    mov cx,stack0_size
;    mov ax,20
    mov ax,3
    CreateThread
;
    pop esi
    pop ecx
    pop ax
    pop fs
    pop ds
    retf32
register_net_driver     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           RegisterPppDriver
;
;       Purpose:        Register PPP driver
;
;       Parameters:     DS:ESI   Dispatch table
;
;       Returns:        BX          Driver handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

register_ppp_driver_name    DB 'Register PPP Driver',0

register_ppp_driver     Proc far
    push ds
    push es
    push ax
    push ecx
    push esi
    push edi
;
    push eax
    mov eax,SIZE driver_data
    AllocateSmallGlobalMem
    pop eax
    mov es:d_packet_size,ecx
    mov es:d_thread,0
    mov edi,OFFSET d_preview
    mov ecx,SIZE driver_data - OFFSET d_preview
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov bx,SEG data
    mov ds,bx
    mov ds:ppp_handle,es
    mov bx,es
;
    pop edi
    pop esi
    pop ecx
    pop ax
    pop es
    pop ds
    ret
register_ppp_driver     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           AddNetSourceAddress
;
;       Purpose:        Add source address of packet
;
;       Parameters:     BX          protocol handle
;                       ES          packet
;                       FS          driver
;                       EDI         source address offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_net_source_address_name     DB 'Add Net Source Address',0

add_net_source_address  Proc far
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
    jnc add_src_address_update
;
    call fword ptr ds:p_is_cachable
    jc add_src_address_done
;
    mov fs,bp
    push esi
    call fword ptr fs:d_get_address
    mov edi,esi
    pop esi
    call InsertAddress
    jmp add_src_address_done

add_src_address_update:
    mov fs,bp
    push esi
    call fword ptr fs:d_get_address
    mov edi,esi
    pop esi
    call UpdateAddress

add_src_address_done:
    pop bp
    pop edi
    pop esi
    pop ax
    pop fs
    pop ds
    retf32
add_net_source_address  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           IsNetAddressValid
;
;       Purpose:        Check if network address is valid (in use)
;
;       Parameters:     BX      protocol handle
;                       DS:ESI  dest address
;
;       returns:        NC      Address is valid / in use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_net_address_valid_name       DB 'Is Net Address Valid',0

is_net_address_valid    Proc far
    push ds
    push fs
    push eax
;
    mov ax,ds
    mov fs,ax
    mov ds,bx
    call FindAddress
    jnc is_valid_done
;
    push bx
    push es
    push cx
    push si
    push di
;
    movzx eax,ds:p_logical_addr_len
    add ax,OFFSET arp_logical_addr
    AllocateSmallGlobalMem
    mov es:arp_protocol,ds
    mov es:arp_retries,2
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
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:arp_section
    mov ax,ds:arp_send_list
    or ax,ax
    je check_address_arp_empty
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
    jmp check_address_arp_done

check_address_arp_empty:
    mov es:arp_next,es
    mov es:arp_prev,es
    mov ds:arp_send_list,es

check_address_arp_done:
    LeaveSection ds:arp_section
    pop di
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

is_valid_done:
    pop eax
    pop fs
    pop ds
    retf32
is_net_address_valid    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetNetBuffer
;
;       Purpose:        Get network buffer
;
;       Parameters:     BX      protocol handle
;                       ECX     size of data
;                       DS:ESI  dest address
;
;       returns:        ES:EDI  address of data
;                       NC      success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_net_buffer_name     DB 'Get Net Buffer',0

get_net_buffer  Proc far
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
    push di
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
    mov ax,SEG data
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
    pop di
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
    call fword ptr fs:d_get_link_state
    jc get_net_buf_done
;
    call fword ptr fs:d_get_buffer
    clc

get_net_buf_done:
    pop eax
    pop fs
    retf32
get_net_buffer  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetNetAddress
;
;       Purpose:        Get network address
;
;       Parameters:     BX      protocol handle
;                       DS:ESI  logical address
;
;       returns:        ES:EDI  physical address
;                       ECX     size of physical address
;                       NC      success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_net_address_name     DB 'Get Net Address',0

get_net_address  Proc far
    push fs
    push ds
    push eax
    push ebx
;
    mov ax,ds
    mov fs,ax
    mov ds,bx
    call FindAddress
    jnc get_adr_do
;
    push bx
    push es
    push cx
    push si
    push di
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
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:arp_section
    mov ax,ds:arp_send_list
    or ax,ax
    je get_adr_arp_empty
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
    jmp get_adr_arp_done

get_adr_arp_empty:
    mov es:arp_next,es
    mov es:arp_prev,es
    mov ds:arp_send_list,es

get_adr_arp_done:
    LeaveSection ds:arp_section
    pop di
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
    jc get_adr_done

get_adr_do:
    mov es,ax
    movzx eax,es:prot_logical_addr_len
    mov edi,OFFSET prot_logical_addr
    add edi,eax
    movzx ecx,es:prot_hardware_addr_len
    clc

get_adr_done:
    pop ebx
    pop eax
    pop ds
    pop fs
    retf32
get_net_address  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetNetMac
;
;       Purpose:        Get network mac
;
;       Parameters:     BX      protocol handle
;                       DS:ESI  logical address
;                       ES:EDI  MAC buffer
;
;       returns:        NC      success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_net_mac_name     DB 'Get Net Mac',0

get_net_mac  Proc far
    push ds
    push es
    push fs
    push eax
    push ebx
    push esi
    push edi
;
    mov ax,ds
    mov fs,ax
    mov ds,bx
    call FindAddress
    jc gnmDone
;
    mov fs,ax
    mov fs,fs:prot_driver
    mov ax,es
    mov ds,ax
    mov esi,edi
    call fword ptr fs:d_get_mac
    jc gnmDone
;
    mov eax,es:[edi]
    mov ds:[esi],eax
    mov ax,es:[edi+4]
    mov ds:[esi+4],ax

gnmDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds
    retf32
get_net_mac  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendNet
;
;       Purpose:        Send data to network
;
;       Parameters:     BX          protocol handle
;                       ECX         size of data
;                       DS:ESI      dest address
;                       ES          address of data
;
;       returns:        NC      success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_net_name   DB 'Send Net',0

send_net    Proc far
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
    mov ax,SEG data
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
    call fword ptr fs:d_send
    pop esi
    pop dx

send_done:
    xor ax,ax
    mov ds,ax
;
    pop di
    pop eax
    pop fs
    retf32
send_net    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetBroadcastBuffer
;
;       Purpose:        Get a broadcast buffer
;
;       Parameters:     FS          driver handle
;                       ECX         size of data
;                       ES:EDI  address of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_broadcast_buffer_name       DB 'Get Broadcast Buffer',0

get_broadcast_buffer    Proc far
    call fword ptr fs:d_get_link_state
    jc gbbDone
;
    call fword ptr fs:d_get_buffer

gbbDone:
    retf32
get_broadcast_buffer    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendBroadcast
;
;       Purpose:        Send broadcast message
;
;       Parameters:     BX          protocol
;                       FS          driver handle
;                       ECX         size of data
;                       ES:EDI  address of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_broadcast_name     DB 'Send Broadcast',0

send_broadcast  Proc far
    push ds
    push esi
;
    mov ds,bx
    mov dx,ds:p_packet_type
    mov ds,fs:d_class
    mov esi,OFFSET broadcast_addr
    call fword ptr fs:d_send
;
    pop esi
    pop ds
    retf32
send_broadcast  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetNetDriverBuffer
;
;       Purpose:        Get a net driver buffer
;
;       Parameters:     FS      driver handle
;                       ECX     size of data
;                       ES:EDI  address of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_net_driver_buffer_name       DB 'Get Net Driver Buffer',0

get_net_driver_buffer    Proc far
    call fword ptr fs:d_get_link_state
    jc gndbDone
;
    call fword ptr fs:d_get_buffer

gndbDone:
    retf32
get_net_driver_buffer    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendNetDriver
;
;       Purpose:        Send message to driver
;
;       Parameters:     BX          protocol
;                       FS          driver handle
;                       ECX         size of data
;                       DS:ESI      driver dest address
;                       ES:EDI      address of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_net_driver_name     DB 'Send Net Driver',0

send_net_driver  Proc far
    push ds
    mov ds,bx
    mov dx,ds:p_packet_type
    pop ds
;    
    call fword ptr fs:d_send
;
    retf32
send_net_driver  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           ReqArp
;
;       Purpose:        Send ARP request
;
;       Parameters:     BX          protocol
;                       FS          driver handle
;                       DS:ESI      logical destination
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_arp_name     DB 'Req Arp',0

req_arp  Proc far
    push ds
    push gs
    push ecx
    push esi
    push edi
    push bp
;
    call fword ptr fs:d_get_link_state
    jc req_arp_done
;
    mov bp,ds
    mov gs,bx
    mov ds,fs:d_class
;
    mov ecx,4
    add cl,gs:p_logical_addr_len
    adc ch,0
    add cl,ds:addr_len
    adc ch,0
    add cx,cx
    call fword ptr fs:d_get_buffer
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
    movzx ecx,ds:addr_len
    push ds
    push esi
    call fword ptr fs:d_address
    rep movs byte ptr es:[edi],ds:[esi]
    pop esi
    pop ds
;    
    movzx cx,gs:p_logical_addr_len
    push si
    mov si,OFFSET p_logical_my_addr
    rep movs byte ptr es:[di],gs:[si]
    pop si
;    
    xor al,al
    movzx cx,ds:addr_len
    rep stosb
;    
    push ds
    mov ds,bp
    movzx ecx,gs:p_logical_addr_len
    rep movs byte ptr es:[edi],ds:[esi]
    pop ds
;
    mov ecx,4
    add cl,gs:p_logical_addr_len
    adc ch,0
    add cl,ds:addr_len
    adc ch,0
    movzx ecx,cx
    add ecx,ecx
    mov dx,806h
    mov esi,OFFSET broadcast_addr
    call fword ptr fs:d_send

req_arp_done:
    pop bp
    pop edi
    pop esi
    pop ecx
    pop gs
    pop ds
    retf32
req_arp  Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           NetBroadcast
;
;       Purpose:        Broadcast to all devices
;
;       Parameters:     ES:EDI   Callback for each driver
;                           FS          driver handle
;                           GS          passed unchanged
;                           EDX         passed unchanged
;                           ESI         passed unchanged
;                           EBP         passed unchanged
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

net_broadcast_name      DB 'Net Broadcast',0

net_broadcast   Proc far
    push ds
    push fs
    pushad
;
    mov ax,SEG data
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
    xor eax,eax
    mov ax,cs
    push eax
    mov ax,OFFSET net_br_driver_next
    push eax
    mov ax,es
    push eax
    push edi
    retf32

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
    retf32
net_broadcast   ENDP

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetPppBuffer
;
;       Purpose:        Get PPP buffer
;
;       Parameters:     BX          protocol handle
;                       ECX         size of data
;
;       returns:        ES:EDI  address of data
;                       NC      success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ppp_buffer_name     DB 'Get Ppp Buffer',0

get_ppp_buffer  Proc far
    push fs
;
    mov ax,SEG data
    mov fs,ax
    mov ax,fs:ppp_handle
    or ax,ax
    jz get_ppp_done
;
    mov fs,ax
    call fword ptr fs:d_get_link_state
    jc get_ppp_done
;
    call fword ptr fs:d_get_buffer

get_ppp_done:
    pop fs
    retf32
get_ppp_buffer  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           SendPpp
;
;       Purpose:        Send data to PPP driver
;
;       Parameters:         ECX         size of data
;                       ES          address of data
;
;       returns:        NC      success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_ppp_name   DB 'Send PPP',0

send_ppp    Proc far
    push ds
    push fs
    push eax
    push di
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:ppp_handle
    or ax,ax
    jz send_ppp_done
;
    mov fs,ax
    xor di,di
    call fword ptr fs:d_send

send_ppp_done:
    pop di
    pop eax
    pop fs
    pop ds
    retf32
send_ppp    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           NetReceived
;
;       Purpose:        Net received callback. Called from ISR
;
;       Parameters:     BX          Driver handle
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

net_received_name       DB 'Net Received',0

net_received    Proc far
    push ds
    push ax
    push bx
    mov ax,SEG data
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
    retf32
net_received    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DefineProtocolAddress
;
;       Purpose:        Define protocol address
;
;       Parameters:         BX          Driver handle
;                           DS:ESI  Address
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

define_protocol_address_name    DB 'Define Protocol Address',0

define_protocol_address Proc far
    push ds
    push es
    push ecx
    push esi
    push edi
;
    mov es,bx
    movzx ecx,es:p_logical_addr_len
    mov edi,OFFSET p_logical_my_addr
    rep movs byte ptr es:[edi],ds:[esi]
;       
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    retf32
define_protocol_address Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResendTimeout
;
;           description:    Send a signal to arp thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResendTimeout   Proc far
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:arp_thread
    Signal
    retf32
ResendTimeout   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetEnvString
;
;           description:    Find an enviroment variable
;
;           PARAMETERS:         ES:DI       var name
;
;           RETURNS:        NC              found
;                               DS:SI   address of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEnvString    proc near
    push bx
    LockSysEnv
    mov ds,bx
    xor si,si
    mov ax,cs
find_var_str_loop:
    mov al,[si]
    or al,al
    stc
    jz find_var_str_done
    push di
find_var_char_str_loop:
    cmpsb
    jnz find_var_str_next
    mov al,es:[di]
    or al,al
    jnz find_var_char_str_loop
    mov al,[si]
    cmp al,'='
    je find_var_str_found

find_var_str_next:
    lodsb
    or al,al
    jnz find_var_str_next
    pop di
    jmp find_var_str_loop

find_var_str_found:
    pop di
    inc si
    clc
find_var_str_done:
    pushf
    UnlockSysEnv
    popf
;
    pop bx
    ret
GetEnvString    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           arp_thread
;
;           DESCRIPTION:    arp thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

arp_thread_name DB 'ARP',0
capture_str         DB 'NET.CAPTURE',0

arp_thread_pr:
    mov ax,cs
    mov es,ax
    mov di,OFFSET capture_str
    call GetEnvString
    jc capture_done
;
    mov di,si
    mov ax,ds
    mov es,ax
    xor cl,cl
    OpenFile
    jnc capture_setup
;
    xor cx,cx
    CreateFile
    jc capture_done

capture_setup:    
    StartNetCapture

capture_done:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:arp_thread,ax

arp_thread_loop:
    WaitForSignal
    mov bx,ds:arp_thread
    StopTimer

arp_rec_loop:
    mov ax,SEG data
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
    mov edi,OFFSET ResendTimeout
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetTimestamp
;
;           description:    Get pcap compatible timestamp
;
;       returns:    EDX:EAX Timestamp
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetTimestamp    Proc near
    push esi
    push ebx
    push cx
;    
    GetTime
    push eax
    BinaryToTime
;    
    push ax
;
    push dx
    sub dx,1970
    movzx esi,dx
    mov eax,365
    mul esi
    dec si
    shr si,2
    inc si
    add esi,eax
    pop dx    
;    
    PassedDays      ; ax = passed days   
    movzx eax,ax    
    add eax,esi
;    
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
;
    pop cx
    pop ebx
    pop esi
    ret
GetTimestamp    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           HookNetLinkUp
;
;       Purpose:        Hook on net link up
;
;       Parameters:     ES:EDI   Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_net_link_up_name      DB 'Hook Net Link Up', 0

hook_net_link_up   Proc far
    push ds
    push ax
    push bx
;
    mov ax,SEG data
    mov ds,ax
    mov al,ds:net_link_up_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET net_link_up_hook_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:net_link_up_hooks,al
;
    pop bx
    pop ax
    pop ds
    retf32
hook_net_link_up   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CaptureThread
;
;           description:    Capture thread
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

capture_thread_name DB 'Net Capture', 0

capture_thread_pr:
    mov bx,SEG data
    mov ds,bx
    GetThread
    mov ds:capture_thread,ax
    LeaveSection ds:capture_section
;    
    mov ax,flat_sel
    mov es,ax
    mov eax,24
    AllocateSmallLinear
    mov edi,edx
;    
    mov bx,ds:capture_handle
    GetFileSize32
    cmp eax,24
    jc ctpRewrite
;
    mov ecx,24
    UserGateForce32 read_file_nr
    cmp eax,24
    jne ctpRewrite
;
    mov eax,es:[edi]
    cmp eax,0A1B2C3D4h
    jne ctpRewrite
;
    GetFileSize32
    SetFilePos32
;
    mov ecx,24
    mov edx,edi
    FreeLinear    
    jmp ctpLoop

ctpRewrite:
    xor eax,eax
    SetFilePos32
    SetFileSize32
;
    mov edx,edi
;    
    mov eax,0A1B2C3D4h
    stos dword ptr es:[edi]
;
    mov ax,2
    stos word ptr es:[edi]
; 
    mov ax,4
    stos word ptr es:[edi]
;
    xor eax,eax
    stos dword ptr es:[edi]
;
    xor eax,eax
    stos dword ptr es:[edi]
;
    mov eax,0FFFFh
    stos dword ptr es:[edi]
;
    mov eax,1
    stos dword ptr es:[edi]
;     
    mov ecx,24
    mov edi,edx
    UserGateForce32 write_file_nr
;
    mov ecx,24
    mov edx,edi
    FreeLinear         

ctpLoop:
    WaitForSignal

ctpMore:
    EnterSection ds:capture_section    
    mov ax,ds:capture_thread
    or ax,ax
    jz ctpExit
;
    mov edx,ds:capture_list
    or edx,edx
    jz ctpNext
;
    push ebx
    mov eax,es:[edx].cb_next
    mov ebx,es:[edx].cb_prev
    mov es:[ebx].cb_next,eax
    mov es:[eax].cb_prev,ebx
    pop ebx
    cmp eax,edx
    jne ctpUnlink
;
    mov ds:capture_list,0
    jmp ctpWrite

ctpUnlink:
    mov ds:capture_list,eax

ctpWrite:       
    LeaveSection ds:capture_section
;    
    mov edi,edx
    mov ecx,es:[edi].cb_len1
    add ecx,16
    add edi,8
    UserGateForce32 write_file_nr
;
    add ecx,8
    FreeLinear    
    jmp ctpMore
    
ctpNext:
    LeaveSection ds:capture_section
    jmp ctpLoop

ctpExit:  
    mov ds:capture_thread,0
    LeaveSection ds:capture_section
    retf    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyEthernetPacket
;
;           description:    Notify reception of ethernet packet
;
;       parameters:         ECX     Size of packet
;                          ES:EDI  Pointer to packet
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_ethernet_packet_name DB 'Notify Ethernet Packet', 0

notify_ethernet_packet  Proc far
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:capture_section
    mov ax,ds:capture_thread
    or ax,ax
    jz nepLeave
;    
    push es
    pushad
;    
    mov ax,es
    mov ds,ax
    mov esi,edi
    mov bx,flat_sel
    mov es,bx
    mov eax,SIZE capture_block
    add eax,ecx
    AllocateSmallLinear
    mov edi,edx
;    
    call GetTimestamp
    mov es:[edi].cb_sec,edx
    mov es:[edi].cb_us,eax
    mov es:[edi].cb_len1,ecx
    mov es:[edi].cb_len2,ecx
    mov edx,edi
    add edi,SIZE capture_block
    rep movs byte ptr es:[edi],ds:[esi]
;
    mov bx,SEG data
    mov ds,bx
;
    mov eax,ds:capture_list
    or eax,eax
    jne nepQueue

nepEmpty:
    mov es:[edx].cb_prev,edx
    mov es:[edx].cb_next,edx
    mov ds:capture_list,edx
    jmp nepSignal

nepQueue:
    mov ebx,es:[eax].cb_prev
    mov es:[eax].cb_prev,edx
    mov es:[ebx].cb_next,edx
    mov es:[edx].cb_prev,ebx
    mov es:[edx].cb_next,eax    

nepSignal:
    mov bx,ds:capture_thread
    Signal
;
    popad
    pop es

nepLeave:
    LeaveSection ds:capture_section
;    
    pop ax
    pop ds    
    retf32
notify_ethernet_packet  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartNetCapture
;
;           description:    Start capturing net-packets
;
;       parameters:     BX      File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_net_capture_name DB 'Start Net Capture', 0

start_net_capture       Proc
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    push di
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:capture_section
;
    mov ds:capture_handle,bx
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET capture_thread_pr
    mov di,OFFSET capture_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;       
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
    retf32
start_net_capture       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopNetCapture
;
;           description:    Stop capturing net-packets
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_net_capture_name DB 'Stop Net Capture', 0

stop_net_capture    Proc
    push ds
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:capture_section
    xor bx,bx
    xchg bx,ds:capture_thread
    or bx,bx
    jz sncThreadDone
;    
    Signal
    mov bx,ds:capture_handle
    CloseFile

sncThreadDone:
    mov ds:capture_handle,0
    LeaveSection ds:capture_section    
;
    pop bx
    pop ds    
    retf32
stop_net_capture    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_net
;
;           DESCRIPTION:    init net driver
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_net    Proc far
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
    mov cx,stack0_size
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_net    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           DESCRIPTION:    Init net driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

internet_broadcast      DB -1, -1, -1, -1
ether_broadcast     DB -1, -1, -1, -1, -1, -1
sernet_broadcast    DB -1

init    PROC far
    mov bx,SEG data
    mov ds,bx
    mov es,bx
    mov ds:class_count,0
    mov ds:protocol_count,0
    mov ds:ppp_handle,0
    mov ds:arp_rec_list,0
    mov ds:arp_send_list,0
    mov ds:arp_answ_list,0
    mov ds:arp_thread,0
    mov ds:capture_handle,0
    mov ds:capture_thread,0
    mov ds:capture_list,0
    mov ds:net_link_up_hooks,0
    InitSection ds:arp_section
    InitSection ds:capture_section
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_net
    HookInitTasking
;
    mov esi,OFFSET is_net_address_valid
    mov edi,OFFSET is_net_address_valid_name
    xor cl,cl
    mov ax,is_net_address_valid_nr
    RegisterOsGate
;
    mov esi,OFFSET get_net_driver
    mov edi,OFFSET get_net_driver_name
    xor cl,cl
    mov ax,get_net_driver_nr
    RegisterOsGate
;
    mov esi,OFFSET register_net_class
    mov edi,OFFSET register_net_class_name
    xor cl,cl
    mov ax,register_net_class_nr
    RegisterOsGate
;
    mov esi,OFFSET register_net_protocol
    mov edi,OFFSET register_net_protocol_name
    xor cl,cl
    mov ax,register_net_protocol_nr
    RegisterOsGate
;
    mov esi,OFFSET setup_net_cachable
    mov edi,OFFSET setup_net_cachable_name
    xor cl,cl
    mov ax,setup_net_cachable_nr
    RegisterOsGate
;
    mov esi,OFFSET register_net_driver
    mov edi,OFFSET register_net_driver_name
    xor cl,cl
    mov ax,register_net_driver_nr
    RegisterOsGate
;
    mov esi,OFFSET register_ppp_driver
    mov edi,OFFSET register_ppp_driver_name
    xor cl,cl
    mov ax,register_ppp_driver_nr
    RegisterOsGate
;
    mov esi,OFFSET define_protocol_address
    mov edi,OFFSET define_protocol_address_name
    xor cl,cl
    mov ax,define_protocol_addr_nr
    RegisterOsGate
;
    mov esi,OFFSET get_net_buffer
    mov edi,OFFSET get_net_buffer_name
    xor cl,cl
    mov ax,get_net_buffer_nr
    RegisterOsGate
;
    mov esi,OFFSET get_net_address
    mov edi,OFFSET get_net_address_name
    xor cl,cl
    mov ax,get_net_address_nr
    RegisterOsGate
;
    mov esi,OFFSET get_net_mac
    mov edi,OFFSET get_net_mac_name
    xor cl,cl
    mov ax,get_net_mac_nr
    RegisterOsGate
;
    mov esi,OFFSET send_net
    mov edi,OFFSET send_net_name
    xor cl,cl
    mov ax,send_net_nr
    RegisterOsGate
;
    mov esi,OFFSET get_broadcast_buffer
    mov edi,OFFSET get_broadcast_buffer_name
    xor cl,cl
    mov ax,get_broadcast_buffer_nr
    RegisterOsGate
;
    mov esi,OFFSET send_broadcast
    mov edi,OFFSET send_broadcast_name
    xor cl,cl
    mov ax,send_broadcast_nr
    RegisterOsGate
;
    mov esi,OFFSET get_net_driver_buffer
    mov edi,OFFSET get_net_driver_buffer_name
    xor cl,cl
    mov ax,get_net_driver_buffer_nr
    RegisterOsGate
;
    mov esi,OFFSET send_net_driver
    mov edi,OFFSET send_net_driver_name
    xor cl,cl
    mov ax,send_net_driver_nr
    RegisterOsGate
;
    mov esi,OFFSET net_broadcast
    mov edi,OFFSET net_broadcast_name
    xor cl,cl
    mov ax,net_broadcast_nr
    RegisterOsGate
;
    mov esi,OFFSET get_ppp_buffer
    mov edi,OFFSET get_ppp_buffer_name
    xor cl,cl
    mov ax,get_ppp_buffer_nr
    RegisterOsGate
;
    mov esi,OFFSET send_ppp
    mov edi,OFFSET send_ppp_name
    xor cl,cl
    mov ax,send_ppp_nr
    RegisterOsGate
;
    mov esi,OFFSET net_received
    mov edi,OFFSET net_received_name
    xor cl,cl
    mov ax,net_received_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_net_link_up
    mov edi,OFFSET hook_net_link_up_name
    xor cl,cl
    mov ax,hook_net_link_up_nr
    RegisterOsGate
;
    mov esi,OFFSET add_net_source_address
    mov edi,OFFSET add_net_source_address_name
    xor cl,cl
    mov ax,add_net_source_address_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_ethernet_packet
    mov edi,OFFSET notify_ethernet_packet_name
    xor cl,cl
    mov ax,notify_ethernet_packet_nr
    RegisterOsGate
;
    mov esi,OFFSET req_arp
    mov edi,OFFSET req_arp_name
    xor cl,cl
    mov ax,req_arp_nr
    RegisterOsGate
;
    mov esi,OFFSET ether_broadcast
    mov cx,6
    mov al,1
    RegisterNetClass
;
    mov esi,OFFSET sernet_broadcast
    mov cx,1
    mov al,100
    RegisterNetClass
;
    mov esi,OFFSET internet_broadcast
    mov cx,4
    mov al,0
    RegisterNetClass
;
    mov esi,OFFSET start_net_capture
    mov edi,OFFSET start_net_capture_name
    xor dx,dx
    mov ax,start_net_capture_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_net_capture
    mov edi,OFFSET stop_net_capture_name
    xor dx,dx
    mov ax,stop_net_capture_nr
    RegisterBimodalUserGate
    clc
    ret
init    ENDP

code    ENDS

    END init
