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

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc
include ..\usbdev\hub.inc

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

hub_list        DW ?

hub_section     section_typ <>

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ProcessHubDescr
;
;   description:    Process Hub descriptor
;
;   Parameters:     GS      Hub
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessHubDescr  Proc near
    push es
    pushad
;    
    mov ax,gs
    mov es,ax
    mov bx,gs:hub_control_handle
;    
    mov di,OFFSET hub_control_data
    mov es:[di].usd_type,0A0h
    mov es:[di].usd_req,GET_DESCR
    mov es:[di].usd_value,2900h
    mov es:[di].usd_index,0
    mov es:[di].usd_len,HUB_BUF_SIZE
    mov cx,8
    WriteUsbControl
;
    mov cx,HUB_BUF_SIZE
    mov di,OFFSET hub_buf
    mov es:[di].uhd_type,0
    ReqUsbData    
;    
    WriteUsbStatus
    StartUsbTransaction
;
    GetSystemTime
    add eax,1000 * 1193    
    adc edx,0
    mov bx,gs:hub_wait_handle
    WaitWithTimeout
;    
    mov bx,gs:hub_control_handle
    WasUsbTransactionOk
    jc ghdDone
;
    mov cl,es:[di].uhd_type
    cmp cl,29h
    stc
    jne ghdDone
;
    movzx cx,es:[di].uhd_ports
    mov gs:hub_ports,cx
;
    mov cx,es:[di].uhd_info
    mov gs:hub_info,cx
;
    movzx cx,es:[di].uhd_power_time
    shl cx,1
    mov gs:hub_power_time,cx        
;
    mov cx,gs:hub_ports
    mov bx,OFFSET hub_port_arr

phdLoop:
    mov gs:[bx].hps_status,0
    mov gs:[bx].hps_dev_port,0
    add bx,4
    loop phdLoop
;               
    clc    

ghdDone:    
    popad
    pop es
    ret
ProcessHubDescr Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetPortStatus
;
;   description:    Get port status
;
;   Parameters:     GS      Hub
;                   DX      Port
;
;   Returns:        AX      Port status
;                   DX      Status change
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPortStatus  Proc near
    push es
    push bx
    push cx
    push di
;    
    mov ax,gs
    mov es,ax
    mov bx,gs:hub_control_handle
;    
    mov di,OFFSET hub_control_data
    mov es:[di].usd_type,0A3h
    mov es:[di].usd_req,GET_STATUS
    mov es:[di].usd_value,0
    mov es:[di].usd_index,dx
    mov es:[di].usd_len,4
    mov cx,8
    WriteUsbControl
;
    mov cx,4
    mov di,OFFSET hub_buf
    mov es:[di].uhd_type,0
    ReqUsbData    
;    
    WriteUsbStatus
    StartUsbTransaction
;
    GetSystemTime
    add eax,1000 * 1193    
    adc edx,0
    mov bx,gs:hub_wait_handle
    WaitWithTimeout
;    
    mov bx,gs:hub_control_handle
    WasUsbTransactionOk
    jc gpsDone
;    
    mov di,OFFSET hub_buf
    mov ax,es:[di]
    mov dx,es:[di+2]
    clc    

gpsDone:    
    pop di
    pop cx
    pop bx
    pop es
    ret
GetPortStatus Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetPortFeature
;
;   description:    Set port feature
;
;   Parameters:     GS      Hub
;                   DX      Port
;                   AX      Feature
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPortFeature  Proc near
    push es
    pushad
;    
    mov bx,gs
    mov es,bx
    mov bx,gs:hub_control_handle
;    
    mov di,OFFSET hub_control_data
    mov es:[di].usd_type,23h
    mov es:[di].usd_req,SET_FEATURE
    mov es:[di].usd_value,ax
    mov es:[di].usd_index,dx
    mov es:[di].usd_len,0
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    StartUsbTransaction
;
    GetSystemTime
    add eax,1000 * 1193    
    adc edx,0
    mov bx,gs:hub_wait_handle
    WaitWithTimeout
;    
    mov bx,gs:hub_control_handle
    WasUsbTransactionOk
;
    popad
    pop es
    ret
SetPortFeature Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateHub
;
;   description:    Create hub
;
;   Parameters:     GS      Hub
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateHub  Proc near
    push es
    pushad
;
    CreateWait
    mov gs:hub_wait_handle,bx
;
    mov bx,gs:hub_controller
    mov al,gs:hub_device
    xor dl,dl
    OpenUsbPipe
    mov gs:hub_control_handle,bx
;
    mov ax,gs:hub_control_handle
    mov bx,gs:hub_wait_handle
    xor ecx,ecx
    AddWaitForUsbPipe
;    
    mov bx,gs:hub_controller
    mov al,gs:hub_device
    mov dl,gs:hub_intr
    OpenUsbPipe
    mov gs:hub_status_handle,bx
;
    CreateUsbReq
    mov gs:hub_status_req,bx
;
    mov cx,gs:hub_status_size
    movzx eax,cx
    AllocateSmallGlobalMem
    mov gs:hub_status_sel,es
    AddReadUsbDataReq
;
    GetThread
    mov bx,gs:hub_status_req
    mov cx,gs:hub_status_size
    StartUsbReq    
;
    popad
    pop es
    ret
CreateHub   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HubAttach
;
;   description:    Hub attach event
;
;   Parameters:     GS      Hub
;                   BX      Port status
;                   DX      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HubAttach    Proc near
    push ds
    push ax
    push bx
;    
    mov ds,gs:hub_dev_sel
    call ds:allocate_hub_port_proc
    jc haDone
;
    mov gs:[bx].hps_dev_port,al
    test gs:[bx].hps_status,200h
    jnz haLowSpeed
;
    test gs:[bx].hps_status,400h
    jnz haHighSpeed

haFullSpeed:
    mov ah,1
    jmp haAttach

haHighSpeed:
    mov ah,2
    jmp haAttach

haLowSpeed:
    mov ah,0
        
haAttach:
    NotifyUsbAttach

haDone:    
    pop bx
    pop ax
    pop ds
    ret
HubAttach   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HubDetach
;
;   description:    Hub detach event
;
;   Parameters:     GS      Hub
;                   DX      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HubDetach    Proc near
    push ds
    push ax
    push bx
;    
    int 3
    mov ds,gs:hub_dev_sel
    mov al,gs:[bx].hps_dev_port
    NotifyUsbAttach
;
    pop bx
    pop ax
    pop ds
    ret
HubDetach   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           UpdatePorts
;
;   description:    Update ports
;
;   Parameters:     GS      Hub
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePorts    Proc near
    pushad
;
    mov cx,gs:hub_ports
    mov bx,OFFSET hub_port_arr
    mov si,1

upLoop:
    mov dx,si
    call GetPortStatus
    jc upNext
;    
    test ax,100h
    jnz upHasPower
;
    mov gs:[bx].hps_status,ax
    mov dx,si
    mov ax,PORT_POWER
    call SetPortFeature    
    jmp upNext

upHasPower:
    test ax,1
    jz upNotConnected
;
    mov gs:[bx].hps_status,ax
    test ax,2
    jnz upNext
;        
    push ds
    mov ds,gs:hub_dev_sel
    call ds:lock_enum_proc
    pop ds
;
    mov dx,si
    mov ax,PORT_RESET
    call SetPortFeature    

upWaitLoop:
    mov dx,si
    call GetPortStatus
    jc upUnlock
;
    test ax,1
    jz upUnlock
;
    test ax,2
    jnz upIsEnabled
;
    mov ax,25
    WaitMilliSec
    jmp upWaitLoop
 
upIsEnabled:
    mov gs:[bx].hps_status,ax
;    
    mov dx,si
    call HubAttach 

upUnlock:   
    push ds 
    mov ds,gs:hub_dev_sel
    call ds:unlock_enum_proc
    pop ds
    jmp upNext

upNotConnected:
    xchg ax,gs:[bx].hps_status
    test ax,1
    jz upNext
;
    mov dx,si
    call HubDetach

upNext:    
    add bx,4
    inc si
    loop upLoop
;           
    popad
    ret
UpdatePorts    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           PollStatus
;
;   description:    Poll Hub status
;
;   Parameters:     GS      Hub
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollStatus    Proc near
    mov bx,gs:hub_status_req
    IsUsbReqStarted
    jnc psStarted
;
    StartUsbReq
    jmp psDone        

psStarted:
    IsUsbReqReady
    jc psDone
;
    GetUsbReqData
    mov ax,gs:hub_status_sel
    StartUsbReq

psDone:
    ret
PollStatus  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hub_thread
;
;   DESCRIPTION:    HUB thread
;
;   PARAMETERS:     BX      Hub selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hub_thread_handler:
    mov gs,bx
    GetThread
    mov gs:hub_thread,ax
;
    call CreateHub
    call ProcessHubDescr
    jc hub_exit

hub_thread_loop:
    call UpdatePorts
;
    mov ax,gs:hub_power_time
    WaitMilliSec
;
    jmp hub_thread_loop

hub_exit:
        

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
    xor dl,dl
    mov cx,1000h
    xor di,di
    push ax
    GetUsbConfig
    mov cx,ax
    pop ax
    or cx,cx
    jz uaDone
;
    mov dl,es:ucd_config_id
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaCheckLoop:
    mov cl,es:[di].ucd_type
    cmp cl,4
    jne uaCheckNext
;    
    mov cl,es:[di].uid_class
    cmp cl,9
    je uaConfig

uaCheckNext:
    movzx cx,es:[di].ucd_len
    or cx,cx
    jz uaDone
;    
    add di,cx
    cmp di,es:ucd_size
    jb uaCheckLoop
    jmp uaDone

uaConfig:
    ConfigUsbDevice
    jc uaDone
;
    push es 
    push ax
    push ax
    mov eax,SIZE hub_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:hub_controller,bx
    mov es:hub_device,al
    mov es:hub_status_size,0
    mov es:hub_intr,0
    mov es:hub_info,0
    mov es:hub_power_time,0
    mov es:hub_dev_sel,ds
    mov ax,es
    mov gs,ax
    pop ax
    pop es
;
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne uaDescrNext

uaDescrDo:
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,3
    jne uaDescrNext
;
    mov cl,es:[di].ued_address
    mov gs:hub_intr,cl
;
    mov cx,es:[di].ued_maxsize
    mov gs:hub_status_size,cx

uaDescrNext:
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    

uaOk:
    mov al,gs:hub_intr
    or al,al
    jnz uaValid
;
    push es
    mov ax,gs
    mov es,ax
    xor ax,ax
    mov gs,ax
    FreeMem
    pop es
    jmp uaDone

uaValid:
    mov ax,SEG data
    mov ds,ax
    mov bx,gs
;
    EnterSection ds:hub_section   
    mov ax,ds:hub_list
    or ax,ax
    jz uaInsEmpty

uaInsLoop:
    mov gs,ax
    mov ax,gs:hub_next
    or ax,ax
    jnz uaInsLoop
;
    mov gs:hub_next,bx
    jmp uaInsDone

uaInsEmpty:
    mov ds:hub_list,bx

uaInsDone:    
    mov gs,bx
    mov gs:hub_next,0
    LeaveSection ds:hub_section
;
    push es            
    mov eax,100h
    AllocateSmallGlobalMem
    xor di,di
    mov si,OFFSET hub_name

uaCopyHub:
    mov al,cs:[si]
    inc si
    or al,al
    jz uaCopyDone
;
    stosb
    jmp uaCopyHub

uaCopyDone:
    mov ax,gs:hub_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,gs:hub_device
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;            
    mov bx,gs
    xor di,di
    mov dx,cs
    mov ds,dx
    mov si,OFFSET hub_thread_handler
    mov ax,3
    mov cx,stack0_size
    CreateThread
;
    FreeMem
    pop es

uaDone:    
    FreeMem
;
    popad
    pop es
    pop ds
    retf32
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
    int 3
    mov dx,SEG data
    mov ds,dx
;        
    popad
    pop es
    pop ds
    retf32
usb_detach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           IsUsbHubPortConnected
;
;   description:    Check if Hub port is connected
;
;   Parameters:     GS      Hub selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_hub_port_connected_name  DB 'Is Usb Hub Port Connected', 0

is_usb_hub_port_connected  Proc far
    push ax
    push si
;    
    mov si,dx
    dec si
    shl si,2
    mov ax,gs:[si].hub_port_arr.hps_status
    test al,1
    clc
    jnz iuhDone
;    
    stc

iuhDone:
    pop si
    pop ax    
    retf32
is_usb_hub_port_connected  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init
;
;           description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov bx,SEG data
    mov ds,bx
    mov ds:hub_list,0
    InitSection ds:hub_section
;       
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET is_usb_hub_port_connected
    mov edi,OFFSET is_usb_hub_port_connected_name
    xor cl,cl
    mov ax,is_usb_hub_port_connected_nr
    RegisterOsGate
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
