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
; IPCACHE.ASM
; Cache of various IP parameters.
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

data    SEGMENT byte public 'DATA'

ip_cache_section    section_typ <>
ip_cache_list       DW ?
ip_cache_entry_size DW ?
ip_cache_hooks      DB ?
ip_cache_hook_arr   DD 2*16 DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

.386p
    
    assume cs:code

char_tab:
ct00 DB 0,          0,          0,          0,          0,          0,          0,          0
ct08 DB 0,          0,          0,          0,          0,          0,          0,          0
ct10 DB 0,          0,          0,          0,          0,          0,          0,          0
ct18 DB 0,          0,          0,          0,          0,          0,          0,          0
ct20 DB 0,          0,          0,          0,          0,          0,          0,          0
ct28 DB 0,          0,          0,          0,          0,          '-',    '.',    0
ct30 DB '0',    '1',    '2',    '3',    '4',    '5',    '6',    '7'
ct38 DB '8',    '9',    0,          0,          0,          0,          0,          0
ct40 DB 0,          'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct48 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct50 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct58 DB 'X',    'Y',    'Z',    0,          0,          0,          0,          0
ct60 DB 0,          'A',    'B',    'C',    'D',    'E',    'F',    'G'
ct68 DB 'H',    'I',    'J',    'K',    'L',    'M',    'N',    'O'
ct70 DB 'P',    'Q',    'R',    'S',    'T',    'U',    'V',    'W'
ct78 DB 'X',    'Y',    'Z',    0,          0,          0,          0,          0
ct80 DB 0,          0,          0,          0,          0,          0,          0,          0
ct88 DB 0,          0,          0,          0,          0,          0,          0,          0
ct90 DB 0,          0,          0,          0,          0,          0,          0,          0
ct98 DB 0,          0,          0,          0,          0,          0,          0,          0
ctA0 DB 0,          0,          0,          0,          0,          0,          0,          0
ctA8 DB 0,          0,          0,          0,          0,          0,          0,          0
ctB0 DB 0,          0,          0,          0,          0,          0,          0,          0
ctB8 DB 0,          0,          0,          0,          0,          0,          0,          0
ctC0 DB 0,          0,          0,          0,          0,          0,          0,          0
ctC8 DB 0,          0,          0,          0,          0,          0,          0,          0
ctD0 DB 0,          0,          0,          0,          0,          0,          0,          0
ctD8 DB 0,          0,          0,          0,          0,          0,          0,          0
ctE0 DB 0,          0,          0,          0,          0,          0,          0,          0
ctE8 DB 0,          0,          0,          0,          0,          0,          0,          0
ctF0 DB 0,          0,          0,          0,          0,          0,          0,          0
ctF8 DB 0,          0,          0,          0,          0,          0,          0,          0

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindHostByAddress
;
;       Purpose:        Find host by address
;
;       Parameters:         EDX         IP address to find
;
;       Returns:        AX          Host selector
;                       BX          Offset to host name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FindHostByAddress

FindHostByAddress       Proc near
    push ds
    push es
;
    mov ax,SEG data
    mov ds,ax
;
    EnterSection ds:ip_cache_section
    mov ax,ds:ip_cache_list

find_address_loop:
    or ax,ax
    jz find_address_fail
;
    mov es,ax
    cmp edx,es:host_addr
    je find_address_ok
;
    mov ax,es:host_next
    jmp find_address_loop

find_address_fail:
    LeaveSection ds:ip_cache_section
    stc
    jmp find_address_done

find_address_ok:
    LeaveSection ds:ip_cache_section
    mov ax,es
    mov bx,ds:ip_cache_entry_size
    clc

find_address_done:
    pop es
    pop ds
    ret
FindHostByAddress       Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           FindHostByName
;
;       Purpose:        Find host by name
;
;       Parameters:         ES:EDI      Host name to find
;
;       Returns:        AX              Host selector
;                       BX              Offset to name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public FindHostByName

FindHostByName  Proc near
    push ds
    push fs
    push esi
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:ip_cache_section
    mov ax,ds:ip_cache_list

find_name_loop:
    or ax,ax
    jz find_name_fail
;
    mov fs,ax
    push edi
;
    movzx esi,ds:ip_cache_entry_size

find_name_check:
    movzx bx,byte ptr es:[edi]
    or bl,bl
    jz find_name_check_end
;
    mov al,byte ptr cs:[bx].char_tab
    or al,al
    jz find_name_fail_pop
;
    movzx bx,byte ptr fs:[esi]
    cmp al,byte ptr cs:[bx].char_tab
    jnz find_name_next
;
    inc esi
    inc edi
    jmp find_name_check

find_name_check_end:
    or bl,fs:[esi]
    jz find_name_ok
    
find_name_next:
    pop edi
;
    mov ax,fs:host_next
    jmp find_name_loop

find_name_fail_pop:
    pop edi

find_name_fail:
    LeaveSection ds:ip_cache_section
    stc
    jmp find_name_done

find_name_ok:
    pop edi
    LeaveSection ds:ip_cache_section
    mov ax,fs
    mov bx,ds:ip_cache_entry_size
    clc

find_name_done:
    pop esi
    pop fs
    pop ds
    ret
FindHostByName  Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           InitHostData
;
;       Purpose:        Init host data
;
;       Parameters:         ES          Host sel
;                       EDX         IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitHostData    Proc near
    mov es:host_addr,edx
    mov es:host_rto,3 * 1193000
    mov es:host_rtt,0
    mov es:host_rtm,0
;
    push ds
    push ax
    mov ax,es
    mov ds,ax
    InitSection ds:host_section
    pop ax
    pop ds
    ret
InitHostData    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateHost
;
;       Purpose:        Update host in cache
;
;       Parameters:         ES          Host entry selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public UpdateHost

UpdateHost      Proc near
    push ds
    push es
    push fs
    push ax
    push edx
;
    mov ax,SEG data
    mov ds,ax
;
    EnterSection ds:ip_cache_section
    mov bx,ds:ip_cache_list
    xor ax,ax
    mov edx,es:host_addr

update_host_loop:
    or bx,bx
    jz update_host_insert
;
    mov fs,bx
    cmp edx,fs:host_addr
    jz update_host_do
;
    mov ax,bx
    mov bx,fs:host_next
    jmp update_host_loop

update_host_do:
    push ds
    push cx
    push si
    push di
    mov cx,ds:ip_cache_entry_size
    xor si,si
    xor di,di
    rep movs byte ptr es:[di],fs:[si]
    mov ax,gdt_sel
    mov ds,ax
    mov si,fs
    mov di,es
    mov eax,[si]
    xchg eax,[di]
    mov eax,[si+4]
    xchg eax,[di+4]
    pop di
    pop si
    pop cx
    pop ds
    FreeMem
    LeaveSection ds:ip_cache_section
    jmp update_host_done

update_host_insert:
    mov ax,ds:ip_cache_list
    mov ds:ip_cache_list,es
    mov es:host_next,ax
    LeaveSection ds:ip_cache_section

update_host_done:
    pop edx
    pop ax
    pop fs
    pop es
    pop ds
    ret
UpdateHost      Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           InitHost
;
;       Purpose:        Init host cache entry
;
;       Parameters:         ES          Host entry selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitHost    Proc near
    push ds
    push es
    push eax
    push edx
    push esi
    push edi
;
    mov ax,SEG data
    mov ds,ax
    mov cl,ds:ip_cache_hooks
    or cl,cl
    je init_host_done
;
    mov bx,OFFSET ip_cache_hook_arr

init_host_loop:
    push ds
    push ebx
    push ecx
    call fword ptr [bx]
    pop ecx
    pop ebx
    pop ds
    add bx,8
    dec cl
    jnz init_host_loop

init_host_done:
    pop edi
    pop esi
    pop edx
    pop eax
    pop es
    pop ds
    ret
InitHost    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetHostNameSize
;
;       Purpose:        Get host name size
;
;       Parameters:         ES:EDI      Host name
;
;       Returns:        CX              Size of host name (0 if invalid)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public GetHostNameSize

GetHostNameSize Proc near
    push ax
    push bx
    push edi
;
    xor cx,cx
get_name_size_loop:
    movzx bx,es:[edi]
    or bl,bl
    jz get_name_size_ok     
;
    mov al,byte ptr cs:[bx].char_tab
    or al,al
    jz get_name_size_fail
;
    inc cx
    inc edi
    jmp get_name_size_loop

get_name_size_fail:
    stc
    xor cx,cx
    jmp get_name_size_done

get_name_size_ok:
    clc

get_name_size_done:
    pop edi
    pop bx
    pop ax
    ret
GetHostNameSize Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DefineHostByAddress
;
;       Purpose:        Define host by address
;
;       Parameters:         EDX         IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DefineHostByAddress

DefineHostByAddress     Proc near
    push ds
    push es
    push eax
    push di
;
    push ds
    mov ax,SEG data
    mov ds,ax
    movzx eax,ds:ip_cache_entry_size
    mov di,ax
    inc ax
    pop ds
    AllocateSmallGlobalMem
    call InitHostData
    mov byte ptr es:[di],0
    call InitHost
    call UpdateHost
;
    pop di
    pop eax
    pop es
    pop ds
    ret
DefineHostByAddress     Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           DefineHostByName
;
;       Purpose:        Define host by name
;
;       Parameters:         EDX         IP address
;                       ES:EDI  Host name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public DefineHostByName

DefineHostByName    Proc near
    push ds
    push es
    push eax
    push cx
    push esi
    push di
;
    call GetHostNameSize
    jc define_name_done
;
    mov ax,es
    mov fs,ax
    mov esi,edi
    push ds
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:ip_cache_entry_size
    mov di,ax
    pop ds
    add ax,cx
    inc ax
    movzx eax,ax
    AllocateSmallGlobalMem
    call InitHostData

define_name_copy_loop:
    lods byte ptr fs:[esi]
    stosb
    loop define_name_copy_loop
;
    xor al,al
    stosb
    call InitHost
    call UpdateHost
    clc

define_name_done:
    pop di
    pop esi
    pop cx
    pop eax
    pop es
    pop ds
    ret
DefineHostByName    Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           HookIpCache
;
;       Purpose:        Hook on create new IP cache entry
;
;       Parameters:     ES:EDI   Cache entry callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_ip_cache_name      DB 'Hook IP Cache', 0

hook_ip_cache   Proc far
    push ds
    push ax
    push bx
    mov ax,SEG data
    mov ds,ax
    mov al,ds:ip_cache_hooks
    mov bl,al
    xor bh,bh
    shl bx,3
    add bx,OFFSET ip_cache_hook_arr
    mov [bx],edi
    mov [bx+4],es
    inc al
    mov ds:ip_cache_hooks,al
    pop bx
    pop ax
    pop ds
    retf32
hook_ip_cache   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           AllocateIpCacheMem
;
;       Purpose:        Allocate memory in IP cache entry
;
;       Parameters:     AX          Amount of memory to allocate
;
;       Returns:        BX          Offset within IP cache entry for data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_ip_cache_mem_name      DB 'Allocate IP Cache Memory', 0

allocate_ip_cache_mem   Proc far
    push ds
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:ip_cache_entry_size
    add ds:ip_cache_entry_size,ax
    pop ds
    retf32
allocate_ip_cache_mem   Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           LookupIpCache
;
;       Purpose:        Lookup IP cache entry
;
;       Parameters:     EDX         IP address
;
;       Returns:        ES          Cache entry selector
;                       EDI         Offset to host name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lookup_ip_cache_name    DB 'Lookup IP Cache', 0

lookup_ip_cache Proc far
    call FindHostByAddress
    jnc lookup_ok
;
    call DefineHostByAddress
    call FindHostByAddress

lookup_ok:
    mov es,ax
    movzx edi,bx
    retf32
lookup_ip_cache Endp

        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           GetHostTimeout
;
;       Purpose:        Get host timeout
;
;       Parameters:     DS          Cache entry selector
;
;       Returns:        EAX         Host timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_host_timeout_name   DB 'Get Host Timeout',0

get_host_timeout    Proc far
    mov eax,ds:host_rto
    retf32
get_host_timeout    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:           UpdateRoundTripTime
;
;       Purpose:        Update host RTT
;
;       Parameters:     DS          Cache entry selector
;                       EAX         Round trip time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_round_trip_time_name     DB 'Update Round Trip Time',0

update_round_trip_time  Proc far
    push eax
    push edx
;
    EnterSection ds:host_section
    mov ecx,ds:host_rtt
    or ecx,ecx
    jz update_rto_first
;
    sar ecx,3
    sub eax,ecx
    add ds:host_rtt,eax
;
    test eax,80000000h
    jz update_rto_pos
;
    neg eax
update_rto_pos:
    mov ecx,ds:host_rtm
    sar ecx,2
    sub eax,ecx
    add ds:host_rtm,eax
    jmp update_rto_bound

update_rto_first:
    sal eax,1
    mov ds:host_rtm,eax
    sal eax,2
    mov ds:host_rtt,eax

update_rto_bound:
    mov eax,ds:host_rtt
    sar eax,3
    add eax,ds:host_rtm
    mov ecx,eax
    sar ecx,2
    add eax,ecx
    cmp eax,240 * 1193000
    jb update_rto_small
;
    mov eax,240 * 1193000

update_rto_small:
    mov ds:host_rto,eax
    LeaveSection ds:host_section
;
    pop edx
    pop eax
    retf32
update_round_trip_time  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_task_cache
;
;           DESCRIPTION:    Init IP cache, tasking part
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_task_cache

LocalHost   DB 'LocalHost', 0
LocalIp     DB 127,0,0,0

init_task_cache PROC near
    mov ax,cs
    mov es,ax
    mov edi,OFFSET LocalHost
    mov edx,dword ptr cs:LocalIp
    call DefineHostByName
    ret
init_task_cache Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_cache
;
;           DESCRIPTION:    Init IP cache
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_cache

init_cache      PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET hook_ip_cache
    mov edi,OFFSET hook_ip_cache_name
    xor cl,cl
    mov ax,hook_ip_cache_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_ip_cache_mem
    mov edi,OFFSET allocate_ip_cache_mem_name
    xor cl,cl
    mov ax,allocate_ip_cache_mem_nr
    RegisterOsGate
;
    mov esi,OFFSET lookup_ip_cache
    mov edi,OFFSET lookup_ip_cache_name
    xor cl,cl
    mov ax,lookup_ip_cache_nr
    RegisterOsGate
;
    mov esi,OFFSET get_host_timeout
    mov edi,OFFSET get_host_timeout_name
    xor cl,cl
    mov ax,get_host_timeout_nr
    RegisterOsGate
;
    mov esi,OFFSET update_round_trip_time
    mov edi,OFFSET update_round_trip_time_name
    xor cl,cl
    mov ax,update_round_trip_time_nr
    RegisterOsGate
;
    mov ax,SEG data
    mov ds,ax
    mov ds:ip_cache_list,0
    mov ds:ip_cache_hooks,0
    mov ds:ip_cache_entry_size, SIZE host_entry
    InitSection ds:ip_cache_section
    ret
init_cache      ENDP

code    ENDS

    END
