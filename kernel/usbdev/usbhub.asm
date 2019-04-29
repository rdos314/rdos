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
; HUB.ASM
; Implements HUB class for USB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc
include ..\usbdev\usbhub.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

MAX_DEVICES = 256

GET_STATUS = 0
CLEAR_FEATURE = 1
SET_FEATURE = 3
GET_DESCR = 6
SET_DESCR = 7
CLEAR_TT = 8
RESET_TT = 9
GET_TT_STATE = 10
STOP_TT = 11

PORT_CONNECTION     = 0
PORT_ENABLE         = 1
PORT_SUSPEND        = 2
PORT_OVER_CURRENT   = 3
PORT_RESET          = 4
PORT_POWER          = 8
PORT_LOW_SPEED      = 9
C_PORT_CONNECTION   = 16
C_PORT_ENABLE       = 17
C_PORT_SUSPEND      = 18
C_PORT_OVER_CURRENT = 19
C_PORT_RESET        = 20
PORT_TEST           = 21
PORT_INDICATOR      = 22

data    SEGMENT byte public 'DATA'

hub_dead_list    DW ?
hub_section      section_typ <>

hub_dev_count    DW ?
hub_dev_arr      DW MAX_DEVICES DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Usb hub threads
;
;   DESCRIPTION:    
;
;   PARAMETERS:     BX      Hub selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_hub_recreate:
    mov ds,ebx
;
    GetThread
    mov ds:hub_thread,ax
    or ds:hub_flags,FLAG_HUB_REINIT
    and ds:hub_flags,NOT FLAG_HUB_DISCONNECT
;
    mov eax,ds
    mov es,eax
    jmp tSignalled

usb_hub_start:
    mov ds,ebx
;
    GetThread
    mov ds:hub_detach,0
    mov ds:hub_thread,ax
;
    mov eax,ds
    mov es,eax

tLoop:
    WaitForSignal

tSignalled:
    test es:hub_flags,FLAG_HUB_DISCONNECT
    jnz tExit
;
    jmp tLoop

tExit:
    mov ds:hub_thread,0
    mov bx,ds:hub_detach
    Signal

tFail:
    TerminateThread

       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HexToAscii
;
;   DESCRIPTION:    
;
;   PARAMETERS:     AL      Number to convert
;
;   RETURNS:        AX      Ascii result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HexToAscii      PROC near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;
    add ah,7

ok_high1:
    add ah,30h
    ret
HexToAscii      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           FindAnyDevice
;
;    Description:    Search for dead device
;
;    Parameters:     DS         Data seg
;                    ES   	Descriptor
;                    ESI        Vendor & product
;                    EBP	Descriptor size
;
;    Returns:        ECX	Number of matches
;                    GS         CDC sel of last match
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindAnyDevice	Proc near
    push ds
    push eax
    push ebx
    push edx
    push edi
;
    xor ecx,ecx
;
    mov bx,ds:hub_dead_list
    or bx,bx
    jz fadDone
;
    mov dx,bx

fadLoop:
    mov ds,ebx
    mov ax,ds:hub_vendor
    shl eax,16
    mov ax,ds:hub_product
    cmp eax,esi
    jne fadNext
;
    movzx eax,ds:hub_dev_descr_size
    cmp eax,ebp
    jne fadNext
;
    push ecx
    push esi
;
    mov ecx,ebp
    mov esi,OFFSET hub_dev_descr_buf
    xor edi,edi
    repe cmpsb
;
    pop esi
    pop ecx
    jnz fadNext
;
    inc ecx
    mov eax,ds
    mov gs,eax

fadNext:
    mov bx,ds:hub_next
    cmp bx,dx
    jne fadLoop

fadDone:
    pop edi
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
FindAnyDevice	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           FindSpecificDevice
;
;    Description:    Search for dead device
;
;    Parameters:     DS      Data seg
;                    BX      Controller #
;                    AL      Device address
;
;    Returns:        NC	     Found
;                        GS  CDC sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindSpecificDevice	Proc near
    push ds
    push ecx
    push edx
;
    mov cx,ds:hub_dead_list
    or cx,cx
    stc
    jz fsdDone
;
    mov dx,cx

fsdLoop:
    mov ds,ecx
    cmp bx,ds:hub_controller
    jne fsdNext
;
    cmp al,ds:hub_device
    jne fsdNext
;
    mov ecx,ds
    mov gs,ecx
    clc
    jmp fsdDone

fsdNext:
    mov cx,ds:hub_next
    cmp cx,dx
    jne fsdLoop
;
    stc

fsdDone:
    pop edx
    pop ecx    
    pop ds
    ret
FindSpecificDevice	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_attach
;
;   description:    USB attach callback
;
;   Parameters:     BX      Controller #
;                   AL      Device address
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hub_name    DB 'Usb Hub ', 0

usb_attach  Proc far
    push ds
    push es
    pushad
;
    push ax
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop ax
    xor di,di
    push ax
    GetUsbDevice
    cmp ax,cx
    pop ax
    jne uaDone
;
    mov cl,es:udd_class
    cmp cl,9
    jne uaDone
;
    mov si,es:udd_vendor
    shl esi,16
    mov si,es:udd_prod
;
    xor dl,dl
    mov ecx,1000h
    xor edi,edi
    push eax
    GetUsbConfig
    mov ecx,eax
    pop eax
    or ecx,ecx
    jz uaFail
;
    mov ebp,ecx
    mov dl,es:ucd_config_id
    xor edi,edi
    movzx ecx,es:ucd_len
    add edi,ecx

uaCheckLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,4
    jne uaCheckNext
;    
    mov cl,es:[edi].uid_class
    cmp cl,9
    je uaConfig

uaCheckNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz uaFail
;    
    add edi,ecx
    cmp di,es:ucd_size
    jb uaCheckLoop
    jmp uaFail

uaConfig:
    mov cx,SEG data
    mov ds,ecx
    EnterSection ds:hub_section
;
    call FindAnyDevice
    or ecx,ecx
    jz uaNotDead
;
    cmp ecx,1
    je uaRecreate
;
    call FindSpecificDevice
    jc uaNotDead

uaRecreate:
    push ds
    mov si,gs
    mov di,gs:hub_next
    cmp di,si
    mov ds:hub_dead_list,di
    mov si,gs:hub_prev
    mov ds,di
    mov ds:hub_prev,si
    mov ds,si
    mov ds:hub_next,di
    pop ds
    jne uaReConfig
;    
    mov ds:hub_dead_list,0

uaReConfig:
    LeaveSection ds:hub_section
;
    ConfigUsbDevice
    jc uaFail
;
    mov gs:hub_controller,bx
    mov gs:hub_device,al
;
    mov ebx,gs
    mov ds,ebx
;
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi
    mov esi,OFFSET hub_name

uaReCopyCdc:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz uaReCopyDone
;
    stosb
    jmp uaReCopyCdc

uaReCopyDone:
    mov ax,ds:hub_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:hub_device
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    xor edi,edi
    mov edx,cs
    mov ds,edx
    mov esi,OFFSET usb_hub_recreate
    mov eax,3
    mov ecx,stack0_size
    CreateThread
    jmp uaDone

uaNotDead:
    LeaveSection ds:hub_section
;
    push eax
    push ebx
    push esi
;
    mov ebx,edi
    mov eax,es
    mov ds,eax
;
    mov eax,OFFSET hub_dev_descr_buf
    add eax,ebp
    AllocateSmallGlobalMem
;
    mov ecx,ebp
    xor esi,esi
    mov edi,OFFSET hub_dev_descr_buf
    rep movsb
;
    push es
    mov eax,ds
    mov es,eax
    xor eax,eax
    mov ds,eax
    FreeMem
    pop es
;
    mov es:hub_dev_descr_size,bp
    mov edi,ebx
    add edi,OFFSET hub_dev_descr_buf
    add ebp,OFFSET hub_dev_descr_buf
;
    pop esi
    pop ebx
    pop eax
;
    mov es:hub_product,si
    shr esi,16
    mov es:hub_vendor,si
    mov es:hub_controller,bx
    mov es:hub_device,al
    mov es:hub_intr,0
    mov es:hub_detach,0
    mov es:hub_flags,0
    mov es:hub_thread,0
    jmp uaDevNext

uaDevLoop:
    mov cl,es:[edi].ucd_type
    cmp cl,5
    jne uaDevNext
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,3
    jne uaDevNext
;
    mov cl,es:[di].ued_address
    mov es:hub_intr,cl
;
    mov cx,es:[di].ued_maxsize
    mov es:hub_status_size,cx

uaDevNext:
    movzx ecx,es:[edi].ucd_len
    or ecx,ecx
    jz uaFail
;    
    add edi,ecx
    cmp edi,ebp
    jb uaDevLoop

uaDevOk:
    mov al,es:hub_intr
    or al,al
    jz uaFail
;
    mov bx,es:hub_controller
    mov al,es:hub_device
    ConfigUsbDevice
    jc uaFail
;
    mov edi,SEG data
    mov ds,edi
    movzx esi,ds:hub_dev_count
    add esi,esi
    mov ds:[esi].hub_dev_arr,es
    inc ds:hub_dev_count
;
    mov ebx,es
    mov ds,ebx
;
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi
    mov esi,OFFSET hub_name

uaCopyCdc:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz uaCopyDone
;
    stosb
    jmp uaCopyCdc

uaCopyDone:
    mov ax,ds:hub_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:hub_device
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    xor edi,edi
    mov edx,cs
    mov ds,edx
    mov esi,OFFSET usb_hub_start
    mov eax,3
    mov ecx,stack0_size
    CreateThread
    jmp uaDone

uaFail:

uaDone:    
    FreeMem
;
    popad
    pop es
    pop ds
    ret
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_detach
;
;   description:    USB detach callback
;
;   Parameters:     BX      Controller #
;                   AL      Device address
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    movzx ax,al
    mov edx,SEG data
    mov ds,edx
    mov esi,OFFSET hub_dev_arr
    movzx ecx,ds:hub_dev_count
    or ecx,ecx
    jz udDone

udCheckLoop:
    mov dx,[esi]
    or dx,dx
    jz udCheckNext
;
    mov es,dx
    cmp bx,es:hub_controller
    jne udCheckNext
;
    cmp al,es:hub_device
    jne udCheckNext
;
    GetThread
    mov es:hub_detach,ax
;
    or es:hub_flags,FLAG_HUB_DISCONNECT
    mov bx,es:hub_thread
    or bx,bx
    jz udRemove
;
    mov ecx,10

udSignal:
    Signal
;
    WaitForSignal
    mov bx,es:hub_thread
    or bx,bx
    jz udRemove
;
    loop udSignal

udRemove:
    EnterSection ds:hub_section
    mov di,ds:hub_dead_list
    or di,di
    je udInsEmpty
;
    push ds
    push si
;
    mov ds,di
    mov si,ds:hub_prev
    mov ds:hub_prev,es
    mov ds,si
    mov ds:hub_next,es
    mov es:hub_next,di
    mov es:hub_prev,si
;
    pop si
    pop ds
    jmp udInsDone
    
udInsEmpty:
    mov es:hub_next,es
    mov es:hub_prev,es
    mov ds:hub_dead_list,es

udInsDone:
    LeaveSection ds:hub_section
    jmp udDone

udCheckNext:
    add esi,2    
    sub ecx,1
    jnz udCheckLoop

udDone:
    popad
    pop es
    pop ds
    ret
usb_detach  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ebx,SEG data
    mov ds,ebx
    mov ds:hub_dead_list,0
    mov ds:hub_dev_count,0
    InitSection ds:hub_section
;       
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov edi,OFFSET usb_attach
    HookUsbAttach
;
    mov edi,OFFSET usb_detach
    HookUsbDetach
    clc
    ret
init    Endp

code    ENDS

    END init
