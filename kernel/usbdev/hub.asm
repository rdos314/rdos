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
INCLUDE ..\os\memblk.inc
include usbdev.inc
include hub.inc

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
hub_list_section section_typ <>

hub_dev_count    DW ?
hub_dev_arr      DW MAX_DEVICES DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Block
;
;       DESCRIPTION:    Block
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Block   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:lock_proc
    pop ds
    ret
Block   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Unblock
;
;       DESCRIPTION:    Unblock
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Unblock   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:unlock_proc
    pop ds
    ret
Unblock Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateAddress
;
;       DESCRIPTION:    Allocate address
;
;       PARAMETERS:     DS      Device selector
;
;       RETURNS:        AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateAddress   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:allocate_address_proc
    pop ds
    ret
AllocateAddress Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeAddress
;
;       DESCRIPTION:    Free address
;
;       PARAMETERS:     DS      Device selector
;                       AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeAddress   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:free_address_proc
    pop ds
    ret
FreeAddress     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDev
;
;       DESCRIPTION:    Create device
;
;       PARAMETERS:     DS      Function selector
;                       AL      Address
;                       AH      Speed
;                       BX      Hub sel
;                       DX      Port #
;
;       RETURNS:        ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDev   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:create_dev_proc
    pop ds
;
    push ax
    mov ax,ds:hub_server_thread
    mov es:usbd_parent_thread,ax
    pop ax
    ret
CreateDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeDev
;
;       DESCRIPTION:    Free device
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDev   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:free_dev_proc
    pop ds
    ret
FreeDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PowerOffPort
;
;       DESCRIPTION:    Power off port
;
;       PARAMETERS:     DS      Function selector
;                       DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerOffPort   Proc far
    push eax
    push edx
;
    movzx dx,dl
    mov ax,PORT_POWER
    call ClearPortFeature
;
    pop edx
    pop eax
    ret
PowerOffPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PowerOnPort
;
;       DESCRIPTION:    Power on port
;
;       PARAMETERS:     DS      Function selector
;                       DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerOnPort   Proc far
    push eax
    push edx
;
    movzx dx,dl
    mov ax,PORT_POWER
    call SetPortFeature
;
    pop edx
    pop eax
    ret
PowerOnPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ResetPort
;
;       DESCRIPTION:    Reset port
;
;       PARAMETERS:     DS      Function selector
;                       DL      Port
;
;       RETURNS:        AL      Speed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetPort   Proc far
    push ecx
    push edi
;
    movzx edi,dl
    add edi,edi
    add edi,OFFSET hub_status_arr
;
    mov ax,ds:[edi]
    test al,1
    jz rpFail
;
    movzx dx,dl
    mov ax,PORT_RESET
    call SetPortFeature
;        
    mov cx,10

rpWaitLoop:
    push edx
    GetSystemTime
    add eax,1193 * 200
    adc edx,0
    WaitForSignalWithTimeout
    pop edx
;
    mov ax,ds:[edi]
    test ax,1
    jz rpFail
;
    test ax,2
    jnz rpIsEnabled
;
    loop rpWaitLoop
;
    jmp rpFail

rpIsEnabled:
    mov ax,25
    WaitMilliSec
;
    mov ax,ds:[edi]
    test al,2
    jz rpFail
;
    mov ax,ds:[edi]
    test ax,200h
    jnz rpLowSpeed
;
    test ax,400h
    jnz rpHighSpeed

rpFullSpeed:
    mov al,1
    clc
    jmp rpDone

rpHighSpeed:
    mov al,2
    clc
    jmp rpDone

rpLowSpeed:
    mov al,0
    clc
    jmp rpDone

rpFail:
    stc

rpDone: 
    pop edi
    pop ecx
    ret
ResetPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisablePort
;
;       DESCRIPTION:    Disable port
;
;       PARAMETERS:     DS      Function selector
;                       DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisablePort   Proc far
    push eax
    push edx
    push edi
;
    movzx dx,dl
    movzx edi,dl
    add edi,edi
    add edi,OFFSET hub_status_arr
;
    mov ax,ds:[edi]
    test ax,1
    jz dpDone
;
    mov ax,PORT_ENABLE
    call ClearPortFeature    
;
    mov ax,50
    WaitMilliSec

dpDone:
    pop edi
    pop edx
    pop eax
    ret
DisablePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisableDev
;
;       DESCRIPTION:    Disable device
;
;       PARAMETERS:     DS      Function selector
;                       DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisableDev   Proc far
    push eax
    push edx
    push edi
;
    movzx dx,es:usbd_port
    movzx edi,dl
    add edi,edi
    add edi,OFFSET hub_status_arr
;
    mov ax,ds:[edi]
    test ax,1
    jz ddDone
;
    mov ax,PORT_ENABLE
    call ClearPortFeature    
;
    mov ax,50
    WaitMilliSec
;
    mov ax,ds:[edi]
    test ax,1
    jz ddDone
;
    mov al,es:usbd_speed
    cmp al,2
    je ddDisable
;
    mov al,es:usbd_address
    call ClearControlTT
;
    xor al,al
    call ClearControlTT

ddDisable:
    mov ax,PORT_POWER
    call ClearPortFeature    
;
    mov ax,200
    WaitMilliSec
;
    mov ax,PORT_POWER
    call SetPortFeature    
;
    mov ax,20
    WaitMilliSec
;
    call GetPortStatus

ddDone:
    pop edi
    pop edx
    pop eax
    ret
DisableDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddressDev
;
;       DESCRIPTION:    Address device
;
;       PARAMETERS:     DS      Device selector
;                       AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddressDev   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:address_device_proc
    pop ds
    ret
AddressDev      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ConfigDev
;
;       DESCRIPTION:    Config device
;
;       PARAMETERS:     DS      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigDev   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:config_device_proc
    pop ds
    ret
ConfigDev       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateControl
;
;       DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device selector
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:create_control_proc
    pop ds
    ret
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsPortConnected
;
;       DESCRIPTION:    Check if port is connected
;
;       PARAMETERS:     DS      Function selector
;                       DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsPortConnected   Proc far
    push eax
    push ebx
;
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    stc
    jnz ipcDone
;
    movzx ebx,dl
    add ebx,ebx
    test ds:[ebx].hub_status_arr,1
    stc
    jz ipcDone
;
    push ds
    push es
;
    movzx ebx,ds:hub_port
    add ebx,ebx
    mov ds,ds:hub_parent_sel
    mov es,ds:[ebx].usb_dev_arr
    call fword ptr ds:is_dev_connected_proc
;
    pop es
    pop ds

ipcDone:
    pop ebx
    pop eax
    ret
IsPortConnected   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsDeviceConnected
;
;       DESCRIPTION:    Check if device is connected
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsDeviceConnected   Proc far
    push eax
    push ebx
;
    test es:usbd_flags,DEV_FLAG_DETACHED
    stc
    jnz idcDone
;
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    stc
    jnz idcDone
;
    movzx ebx,es:usbd_port
    add ebx,ebx
    test ds:[ebx].hub_status_arr,1
    stc
    jz idcDone
;
    push ds
    push es
;
    movzx ebx,ds:hub_port
    add ebx,ebx
    mov ds,ds:hub_parent_sel
    mov es,ds:[ebx].usb_dev_arr
    call fword ptr ds:is_dev_connected_proc
;
    pop es
    pop ds

idcDone:
    pop ebx
    pop eax
    ret
IsDeviceConnected   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ControlMsg
;
;       DESCRIPTION:    Send message over control pipe
;
;       PARAMETERS:     ES      Usb device
;                       GS:EDI  Buffer
;                       CX      Size
;
;       RETURNS:        NC      OK
;                          CX   Transfer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ControlMsg   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:control_msg_proc
    pop ds
    ret
ControlMsg   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateBulkPipe
;
;       DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     ES      Device
;                       CX      Buffer count
;                       DL      Pipe #
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CreateBulkPipe   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:create_bulk_pipe_proc
    pop ds
    ret
CreateBulkPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateIntrPipe
;
;       DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     ES      Device
;                       CX      Buffer count
;                       DL      Pipe #
;                       DH      Interval
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntrPipe   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:create_intr_pipe_proc
    pop ds
    ret
CreateIntrPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPacket
;
;       DESCRIPTION:    Open packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       CX      Packet count
;
;       RETURNS:        BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPacket   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:open_packet_proc
    pop ds
    ret
OpenPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClosePacket
;
;       DESCRIPTION:    Close packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;                       BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePacket   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:close_packet_proc
    pop ds
    ret
ClosePacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartPacket
;
;       DESCRIPTION:    Start packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartPacket   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:start_packet_proc
    pop ds
    ret
StartPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReqPacket
;
;       DESCRIPTION:    Req pipe packet
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;       RETURNS:        EDX     Buffer linear
;                       CX      Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqPacket   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:req_packet_proc
    pop ds
    ret
ReqPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RelPacket
;
;       DESCRIPTION:    Release pipe packet
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RelPacket   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:rel_packet_proc
    pop ds
    ret
RelPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenRaw
;
;       DESCRIPTION:    Open raw interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       CX      Buffer size
;
;       RETURNS:        BX      Raw sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenRaw   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:open_raw_proc
    pop ds
    ret
OpenRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseRaw
;
;       DESCRIPTION:    Close raw interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;                       BX      Raw sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseRaw   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:close_raw_proc
    pop ds
    ret
CloseRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadRaw
;
;       DESCRIPTION:    Read raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       EDX     Linear buffer
;                       CX      Size
;
;       RETURNS:        CX      Read size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadRaw   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:read_raw_proc
    pop ds
    ret
ReadRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteRaw
;
;       DESCRIPTION:    Write raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       EDX     Linear buffer
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRaw   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:write_raw_proc
    pop ds
    ret
WriteRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FinishRaw
;
;       DESCRIPTION:    Finish raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;       RETURNS:        NC
;                         CX    Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FinishRaw   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:finish_raw_proc
    pop ds
    ret
FinishRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsRunning
;
;       DESCRIPTION:    Check if running
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsRunning   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:is_running_proc
    pop ds
    ret
IsRunning   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkPipes
;
;       DESCRIPTION:    Unlink pipes
;
;       PARAMETERS:     ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkPipes   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:unlink_proc
    pop ds
    ret
UnlinkPipes   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ChangeAddress
;
;   DESCRIPTION:    Change address for pipe
;
;   PARAMETERS:     DS      Function selector
;                   FS      Pipe selector
;                   AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:change_address_proc
    pop ds
    ret
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateMaxLen
;
;           DESCRIPTION:    Update max len
;
;           PARAMETERS:     ES      Device
;                           AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMaxLen   Proc far
    push ds
    mov ds,ds:hub_parent_sel
    call fword ptr ds:update_control_maxlen_proc
    pop ds
    ret
UpdateMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           hub table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hub_tab:
ht00 DD OFFSET Block,               SEG code
ht01 DD OFFSET Unblock,             SEG code
ht02 DD OFFSET PowerOffPort,        SEG code
ht03 DD OFFSET PowerOnPort,         SEG code
ht04 DD OFFSET ResetPort,           SEG code
ht05 DD OFFSET DisablePort,         SEG code
ht06 DD OFFSET DisableDev,          SEG code
ht07 DD OFFSET IsPortConnected,     SEG code
ht08 DD OFFSET IsRunning,           SEG code
ht09 DD OFFSET AllocateAddress,     SEG code
ht0A DD OFFSET FreeAddress,         SEG code
ht0B DD OFFSET CreateDev,           SEG code
ht0C DD OFFSET UnlinkPipes,         SEG code
ht0D DD OFFSET IsDeviceConnected,   SEG code
ht0E DD OFFSET FreeDev,             SEG code
ht0F DD OFFSET CreateControl,       SEG code
ht10 DD OFFSET CreateBulkPipe,      SEG code
ht11 DD OFFSET CreateIntrPipe,      SEG code
ht12 DD OFFSET AddressDev,          SEG code
ht13 DD OFFSET ChangeAddress,       SEG code
ht14 DD OFFSET UpdateMaxLen,        SEG code
ht15 DD OFFSET ControlMsg,          SEG code
ht16 DD OFFSET ConfigDev,           SEG code
ht17 DD OFFSET OpenPacket,          SEG code
ht18 DD OFFSET ClosePacket,         SEG code
ht19 DD OFFSET StartPacket,         SEG code
ht1A DD OFFSET ReqPacket,           SEG code
ht1B DD OFFSET RelPacket,           SEG code
ht1C DD OFFSET OpenRaw,             SEG code
ht1D DD OFFSET CloseRaw,            SEG code
ht1E DD OFFSET ReadRaw,             SEG code
ht1F DD OFFSET WriteRaw,            SEG code
ht20 DD OFFSET FinishRaw,           SEG code
       
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
;   NAME:           SetPortFeature
;
;   description:    Set port feature
;
;   Parameters:     DS      Function sel
;                   DX      Port [0..ports]
;                   AX      Feature
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPortFeature  Proc near
    pushad
;    
    EnterSection ds:hub_section
    inc dx
    mov bx,ds:hub_device_handle
    mov si,dx
    mov dx,ax
    xor cx,cx
    mov al,SET_FEATURE
    mov ah,23h
    SendUsbDeviceControlMsg
    LeaveSection ds:hub_section
;
    popad
    ret
SetPortFeature Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClearPortFeature
;
;   description:    Clear port feature
;
;   Parameters:     DS      Function sel
;                   DX      Port [0..ports]
;                   AX      Feature
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearPortFeature  Proc near
    pushad
;    
    EnterSection ds:hub_section
    inc dx
    mov bx,ds:hub_device_handle
    mov si,dx
    mov dx,ax
    mov al,CLEAR_FEATURE
    mov ah,23h
    xor cx,cx
    SendUsbDeviceControlMsg
    LeaveSection ds:hub_section
;
    popad
    ret
ClearPortFeature Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClearPortChange
;
;   description:    Clear port change
;
;   Parameters:     DS      Hub
;                   DX      Port #
;                   AX      Status change
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearPortChange  Proc near
    push eax
;
    shr eax,16
    test ax,1
    jz cpcConnectOk
;
    push ax
    mov ax,C_PORT_CONNECTION
    call ClearPortFeature
    pop ax

cpcConnectOk:    
    test ax,2
    jz cpcEnableOk
;
    push ax
    mov ax,C_PORT_ENABLE
    call ClearPortFeature
    pop ax

cpcEnableOk:
    test ax,4
    jz cpcSuspendOk
;
    push ax
    mov ax,C_PORT_SUSPEND
    call ClearPortFeature
    pop ax

cpcSuspendOk:
    test ax,10h
    jz cpcResetOk
;
    push ax
    mov ax,C_PORT_RESET
    call ClearPortFeature
    pop ax
;
    push ebx
    push edi
;
    movzx edi,dx
    add edi,edi
;
    mov bx,ds:[edi].usb_thread_arr
    cmp bx,-1
    je cpcSigAttachOK
;
    Signal

cpcSigAttachOk:
    pop edi
    pop ebx
                
cpcResetOk:
    pop eax
    ret
ClearPortChange Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClearControlTT
;
;   description:    Clear control TT
;
;   Parameters:     DS      Function sel
;                   AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearControlTT  Proc near
    pushad
;    
    EnterSection ds:hub_section
    mov bx,ds:hub_device_handle    
    movzx ax,al
    shl ax,4
    mov dx,ax
    mov si,1
    xor cx,cx
    mov ah,23h
    mov al,CLEAR_TT
    SendUsbDeviceControlMsg
    LeaveSection ds:hub_section
;
    popad
    ret
ClearControlTT Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;   NAME:           GetPortStatus
;
;   description:    Get port status
;
;   Parameters:     GS      Hub
;                   DX      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPortStatus  Proc near
    push es
    pushad
;    
    push dx
    EnterSection ds:hub_section
;
    mov eax,ds
    mov es,eax
    inc dx
    mov bx,ds:hub_device_handle    
    mov ah,0A3h
    mov al,GET_STATUS
    mov si,dx
    xor dx,dx
    mov cx,4
    mov edi,OFFSET hub_buf
    SendUsbDeviceControlMsg
;
    LeaveSection ds:hub_section
    pop dx
    jc gpsDone
;    
    movzx edi,dx
    add edi,edi
    mov eax,dword ptr ds:hub_buf
    mov ds:[edi].hub_status_arr,ax
;
    call ClearPortChange
    clc    

gpsDone:    
    popad
    pop es
    ret
GetPortStatus Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdatePort
;
;       DESCRIPTION:    Update root-hub port status
;
;       PARAMETERS:     DS      Function selector
;                       DX      Port # (0..ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push eax
    push ebx
    push edi
;    
    movzx edi,dx
    add edi,edi
;   
    mov bx,ds 
    mov ax,ds:[edi].hub_status_arr
    NotifyUsbPortState
;
    pop edi
    pop ebx
    pop eax
    ret
UpdatePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           UpdatePorts
;
;   description:    Update ports
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePorts    Proc near
    push ax
    push dx
;
    xor dx,dx

uhpLoop:
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz uhpDone
;
    call UpdatePort
;
    inc dx
    cmp dx,ds:hub_ports
    jb uhpLoop

uhpDone:           
    pop dx
    pop ax
    ret
UpdatePorts    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UpdateClose
;
;       DESCRIPTION:    Update & close
;
;       PARAMETERS:     DS      Function selector
;                       DX      Port # (0..ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateClose   Proc near
    push ebx
    push edi
;    
    movzx edi,dx
    add edi,edi
;
    xor bx,bx
    xchg bx,ds:[edi].hub_status_arr
    test bx,1
    jnz ucSignal
;
    mov bx,ds:[edi].usb_thread_arr
    or bx,bx
    stc
    jnz ucDone
;
    clc
    jmp ucDone

ucSignal:
    EnterSection ds:usb_section
    mov bx,ds:[edi].usb_thread_arr
    or bx,bx
    clc
    jz ucLeave
;    
    Signal
    stc

ucLeave:
    LeaveSection ds:usb_section

ucDone:                
    pop edi
    pop ebx
    ret
UpdateClose   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClosePorts
;
;   description:    Update ports
;
;   Parameters:     DS      Function sel
;
;   Returns:        NC      All ports closed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePorts    Proc near
    push ax
    push dx
;
    xor dx,dx

chpoLoop:
    call UpdateClose
    jc chpfNext
;
    inc dx
    cmp dx,ds:hub_ports
    jb chpoLoop
;
    clc
    jmp chpDone

chpfLoop:
    call UpdateClose

chpfNext:
    inc dx
    cmp dx,ds:hub_ports
    jb chpfLoop
;
    stc

chpDone:           
    pop dx
    pop ax
    ret
ClosePorts    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateHub
;
;   description:    Create hub
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateHub  Proc near
    push es
    pushad
;
    mov bx,ds:hub_controller
    mov al,ds:hub_port
    GetUsbAddress
    mov ds:hub_address,al
;
    mov bx,ds:hub_controller
    mov al,ds:hub_port
    OpenUsbDevice
    mov ds:hub_device_handle,bx
;    
    mov bx,ds:hub_device_handle
    mov dl,ds:hub_intr
    mov cx,8
    mov ax,5
    OpenUsbPacketPipe
;
    CreateWait
    mov ds:hub_wait_handle,bx
;
    mov ax,ds:hub_device_handle
    mov dl,ds:hub_intr
    mov ecx,ds
    AddWaitForUsbDevicePipe
;
    popad
    pop es
    ret
CreateHub   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CloseHub
;
;   description:    Close hub
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseHub  Proc near
    push bx
;
    mov bx,ds:hub_device_handle
    mov dl,ds:hub_intr
    CloseUsbPipe
;
    mov bx,ds:hub_wait_handle
    CloseWait
;    
    mov bx,ds:hub_device_handle
    CloseUsbDevice
;
    pop bx
    ret
CloseHub   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           InitPorts
;
;   description:    Init ports
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPorts    Proc near
    push eax
    push edx
    push esi
;
    xor dx,dx
    mov esi,OFFSET hub_adr_arr

ipLoop:
    mov ax,PORT_POWER
    call SetPortFeature    
;
    xor al,al
    mov ds:[esi],al
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz ipDone
;
    inc dx
    inc esi
    cmp dx,ds:hub_ports
    jb ipLoop

ipDone:           
    pop esi
    pop edx
    pop eax
    ret
InitPorts    Endp
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Usb hub port
;
;   DESCRIPTION:    
;
;   PARAMETERS:     BX      Hub selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hub_port_name    DB 'Hub Port ', 0

usb_hub_port:
    mov ds,ebx
;
    GetThread
    mov ds:hub_port_thread,ax

tpLoop:
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz tpExit
;    
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
;
    call UpdatePorts
    jmp tpLoop

tpExit:
    call ClosePorts
    jnc tpClosed
;
    mov ax,100
    WaitMilliSec
    jmp tpExit

tpClosed:
    mov ds:hub_port_thread,0
    mov bx,ds:hub_status_thread
    Signal

tpFail:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreatePortThread
;
;   description:    Create hub port thread
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePortThread        Proc near
    push ds
    push es
    pushad
;
    mov eax,100h
    AllocateSmallGlobalMem
;
    xor edi,edi
    mov esi,OFFSET hub_port_name

cptCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz cptCopyDone
;
    stosb
    jmp cptCopyLoop

cptCopyDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    mov al,' '
    stosb
;
    mov ax,ds:hub_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:hub_port
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    mov ebx,ds
    xor edi,edi
    mov edx,cs
    mov ds,edx
    mov esi,OFFSET usb_hub_port
    mov eax,3
    mov ecx,stack0_size
    CreateThread
;
    FreeMem
;
    popad
    pop es
    pop ds
    ret
CreatePortThread        Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           Usb hub status
;
;   DESCRIPTION:    
;
;   PARAMETERS:     BX      Hub selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hub_status_name    DB 'Hub Status ', 0

usb_hub_status:
    mov ds,ebx
    mov es,ebx
;
    GetThread
    mov ds:hub_status_thread,ax
    and ds:hub_flags,NOT FLAG_HUB_DISCONNECT
;
    call CreateHub
    call InitPorts
;
    mov ax,ds:hub_power_time
    WaitMilliSec
;
    xor dx,dx

tsStatusLoop:
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz tsLoop
;
    call GetPortStatus
;
    inc dx
    cmp dx,ds:hub_ports
    jb tsStatusLoop
;
    call CreatePortThread

tsLoop:
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz tsExit
;    
    mov bx,ds:hub_device_handle
    IsUsbDeviceConnected
    jc tsWaitDisc
;
    mov bx,ds:hub_wait_handle
    WaitWithoutTimeout
;
    mov ebx,ds
    mov es,ebx
    mov edi,OFFSET hub_buf
    mov bx,ds:hub_device_handle
    mov dl,ds:hub_intr
    GetUsbPacketPipe
    jc tsLoop
;
    or cx,cx
    jz tsLoop
;
    mov bx,cx
    mov al,es:[edi]
    shr al,1
    xor dx,dx

tsChangeByteLoop:
    mov ecx,8

tsChangeBitLoop:
    test al,1
    jz tsChangeNext
;
    call GetPortStatus
;
    push ebx
    mov bx,ds:hub_port_thread
    Signal
    pop ebx

tsChangeNext:
    shr al,1
    inc dx
    loop tsChangeBitLoop
;
    sub bx,1
    jz tsNext
;
    inc edi
    mov al,es:[edi]
    jmp tsChangeByteLoop

tsNext:
    jmp tsLoop

tsSignalled:
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz tsExit
;
    jmp tsLoop

tsWaitDisc:
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz tsExit
;
    mov ax,25
    WaitMilliSec
    jmp tsWaitDisc

tsExit:
    mov bx,ds:hub_port_thread
    or bx,bx
    jz tsPortDone
;
    mov ecx,10

tsPortSignal:
    Signal
;
    WaitForSignal
    mov bx,ds:hub_port_thread
    or bx,bx
    jz tsPortDone
;
    loop tsPortSignal

tsPortDone:
    call CloseHub
;
    mov ds:hub_status_thread,0

tsFail:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           FindAnyDevice
;
;    Description:    Search for dead device
;
;    Parameters:     DS         Data seg
;                    ES         Descriptor
;                    ESI        Vendor & product
;                    EBP        Descriptor size
;
;    Returns:        ECX        Number of matches
;                    GS         CDC sel of last match
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindAnyDevice   Proc near
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
FindAnyDevice   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;    NAME:           FindSpecificDevice
;
;    Description:    Search for dead device
;
;    Parameters:     DS      Data seg
;                    BX      Controller #
;                    AL      Port #
;
;    Returns:        NC      Found
;                        GS  CDC sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindSpecificDevice      Proc near
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
    cmp al,ds:hub_port
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
FindSpecificDevice      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateStatusThread
;
;   description:    Create hub status thread
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateStatusThread      Proc near
    push ds
    push es
    pushad
;
    mov eax,100h
    AllocateSmallGlobalMem
;
    xor edi,edi
    mov esi,OFFSET hub_status_name

cstCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz cstCopyDone
;
    stosb
    jmp cstCopyLoop

cstCopyDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    mov al,' '
    stosb
;
    mov ax,ds:hub_controller
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,ds:hub_port
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    mov ebx,ds
    xor edi,edi
    mov edx,cs
    mov ds,edx
    mov esi,OFFSET usb_hub_status
    mov eax,3
    mov ecx,stack0_size
    CreateThread
;
    FreeMem
;
    popad
    pop es
    pop ds
    ret
CreateStatusThread      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ProcessHubDescr
;
;   description:    Process Hub descriptor
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessHubDescr  Proc near
    push es
    pushad
;    
    mov ax,ds
    mov es,ax
    mov bx,ds:hub_controller
    mov al,ds:hub_port
    mov ecx,SIZE usb_hub_descr
    mov edi,OFFSET hub_buf
    GetUsbHubDescriptor
    jc ghdDone
;
    mov cl,es:[edi].uhd_type
    cmp cl,29h
    stc
    jne ghdDone
;
    movzx cx,es:[edi].uhd_ports
    mov ds:hub_ports,cx
;
    mov cx,es:[edi].uhd_info
    mov ds:hub_info,cx
;
    movzx cx,es:[edi].uhd_power_time
    shl cx,1
    mov ds:hub_power_time,cx                       
    clc    

ghdDone:    
    popad
    pop es
    ret
ProcessHubDescr Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           usb_attach
;
;   description:    USB attach callback
;
;   Parameters:     BX      Controller #
;                   AL      Port #
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_attach  Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    push eax
    mov eax,ds
    mov fs,eax
;
    mov eax,1000h
    AllocateSmallGlobalMem
    mov cx,SIZE usb_device_descr
    pop eax
;
    xor di,di
    push eax
    GetUsbDevice
    cmp ax,cx
    pop eax
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
    EnterSection ds:hub_list_section
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
    LeaveSection ds:hub_list_section
;
    mov cx,gs
    ConfigUsbHub
    jc uaFail
;
    mov gs:hub_controller,bx
    mov gs:hub_port,al
    mov gs:hub_parent_sel,fs
;
    push ax
    GetThread
    mov gs:hub_server_thread,ax
    pop ax
;
    mov ebx,gs
    mov ds,ebx
;
    call CreateStatusThread
    jmp uaDone

uaNotDead:
    LeaveSection ds:hub_list_section
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
    mov es:hub_port,al
    mov es:hub_intr,0
    mov es:hub_flags,0
    mov es:hub_status_thread,0
    mov es:hub_port_thread,0
    InitSection es:hub_section
;
    push ax
    GetThread
    mov es:hub_server_thread,ax
    pop ax
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
    mov eax,es
    mov ds,eax
    call ProcessHubDescr
    jc uaFailDs

uaDevConfig:
    InitUsbFunction
;
    mov ds:usb_hub_id,-1
    mov bx,ds:hub_controller
    mov al,ds:hub_port
    mov cx,ds
    ConfigUsbHub
    jc uaFailDs
;
    mov ebx,ds
    mov eax,SEG data
    mov ds,eax
    movzx esi,ds:hub_dev_count
    add esi,esi
    mov ds:[esi].hub_dev_arr,bx
    inc ds:hub_dev_count
    mov ds,ebx
;
    mov esi,OFFSET hub_tab
    xor edi,edi
    mov ecx,2*21h

uaTabLoop:
    lods dword ptr cs:[esi]
    mov ds:[edi],eax
    add edi,4
    loop uaTabLoop    
;
    mov ds:hub_parent_sel,fs
;
    call CreateStatusThread
    jmp uaDone

uaFailDs:
    mov eax,ds
    mov es,eax
    xor eax,eax
    mov ds,eax

uaFail:
    FreeMem

uaDone:    
    popad
    pop gs
    pop fs
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
;                   AH      Port #
;                   AL      Device address
;                   DS      USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
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
    cmp al,es:hub_port
    jne udCheckNext
;
    or es:hub_flags,FLAG_HUB_DISCONNECT
;
    EnterSection ds:hub_list_section
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
    LeaveSection ds:hub_list_section
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
    InitSection ds:hub_list_section
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
