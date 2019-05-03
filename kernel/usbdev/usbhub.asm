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
;       NAME:           CreateControl
;
;       DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Device selector
;                       ES      Function selector
;                       AH      Speed
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    int 3
    ret
CreateControl	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateBulk
;
;       DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     DS      Function selector
;                       AH      Speed
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    int 3
    ret
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateIntr
;
;   DESCRIPTION:    Create interrupt pipe
;
;   PARAMETERS:     DS      Function selector
;                   AL      Interval
;                   AH      Speed
;
;   RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    int 3
    ret
CreateIntr   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddSetup
;
;       DESCRIPTION:    Add setup transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddSetup    Proc far
    int 3
    ret 
AddSetup    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddOut
;
;       DESCRIPTION:    Add out transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddOut    Proc far
    int 3
    ret
AddOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddIn
;
;   DESCRIPTION:    Add in transaction to queue
;
;   PARAMETERS:     DS      Function selector
;                   FS      Pipe selector
;                   CX      Buffer size
;                   ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIn    Proc far
    int 3
    ret
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddStatusOut
;
;       DESCRIPTION:    Add status OUT transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusOut    Proc far
    int 3
    ret
AddStatusOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddStatusIn
;
;       DESCRIPTION:    Add status IN transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusIn    Proc far
    int 3
    ret
AddStatusIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IssueTransfer
;
;       DESCRIPTION:    Issue transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     Queue handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueTransfer    Proc far
    int 3
    ret
IssueTransfer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsTransferDone
;
;       DESCRIPTION:    Check if transfer is done
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        NC      Transfer is done
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsTransferDone   Proc far
    int 3
    ret
IsTransferDone   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForCompletion
;
;       DESCRIPTION:    Wait for transfer to complete
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion   Proc far
    int 3
    ret
WaitForCompletion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EndTransfer
;
;       DESCRIPTION:    End transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndTransfer   Proc far
    int 3
    ret
EndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WasTransferOk
;
;       DESCRIPTION:    Was transfer ok
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        NC      Transfer ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WasTransferOk   Proc far
    int 3
    ret
WasTransferOk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetDataSize
;
;       DESCRIPTION:    Get data size
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        CX      Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDataSize   Proc far
    int 3
    ret
GetDataSize   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IssueOne
;
;       DESCRIPTION:    Issue one transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueOne   Proc far
    int 3
    ret
IssueOne   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClosePipe
;
;       DESCRIPTION:    Close pipe
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePipe   Proc far
    int 3
    ret
ClosePipe   Endp

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
    int 3
    ret
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsConnected
;
;       DESCRIPTION:    Check if pipe is connected
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsConnected   Proc far
    int 3
    ret
IsConnected   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ResetPipe
;
;       DESCRIPTION:    Reset port for pipe
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetPipe   Proc far
    int 3
    ret
ResetPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LockEnum
;
;       DESCRIPTION:    Lock enumeration process
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockEnum   Proc far
    int 3
    ret
LockEnum   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlockEnum
;
;       DESCRIPTION:    Unlock enumeration process
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockEnum   Proc far
    int 3
    ret
UnlockEnum   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Has64Bit
;
;       DESCRIPTION:    Check for 64-bit support
;
;       PARAMETERS:         DS      Function selector
;
;       RETURNS:            NC      Supports 64-bit addresses
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Has64Bit   Proc far
    int 3
    ret
Has64Bit   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               IsStalled
;
;       DESCRIPTION:        Check if pipe is stalled
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;       RETURNS:            CY      Stalled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsStalled   Proc far
    int 3
    ret
IsStalled   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               ClearStalled
;
;       DESCRIPTION:        Clear stalled pipe
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;       RETURNS:            CY      Stalled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearStalled   Proc far
    int 3
    ret
ClearStalled   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetMaxLen
;
;           DESCRIPTION:    Get max len
;
;           RETURNS:        AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMaxLen   Proc far
    int 3
    ret
GetMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetMaxLen
;
;           DESCRIPTION:    Set max len
;
;           PARAMETERS:     FS      Pipe
;                           AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetMaxLen   Proc far
    int 3
    ret
SetMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               CloseControlPipe
;
;       DESCRIPTION:        Close control pipe
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseControlPipe   Proc far
    int 3
    ret
CloseControlPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           hub table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hub_tab:
ht00 DD OFFSET CreateControl,       SEG code
ht01 DD OFFSET CreateBulk,          SEG code
ht02 DD OFFSET CreateIntr,          SEG code
ht03 DD OFFSET AddSetup,            SEG code
ht04 DD OFFSET AddOut,              SEG code
ht05 DD OFFSET AddIn,               SEG code
ht06 DD OFFSET AddStatusOut,        SEG code
ht07 DD OFFSET AddStatusIn,         SEG code
ht08 DD OFFSET IssueTransfer,       SEG code
ht09 DD OFFSET IsTransferDone,      SEG code
ht0A DD OFFSET EndTransfer,         SEG code
ht0B DD OFFSET WasTransferOk,       SEG code
ht0C DD OFFSET GetDataSize,         SEG code
ht0D DD OFFSET ClosePipe,           SEG code
ht0E DD OFFSET WaitForCompletion,   SEG code
ht0F DD OFFSET ChangeAddress,       SEG code
ht10 DD OFFSET IsConnected,         SEG code
ht11 DD OFFSET ResetPipe,           SEG code
ht12 DD OFFSET LockEnum,            SEG code
ht13 DD OFFSET UnlockEnum,          SEG code
ht14 DD 0,                          0
ht15 DD 0,                          0
ht16 DD OFFSET Has64Bit,            SEG code
ht17 DD OFFSET IsStalled,           SEG code
ht18 DD OFFSET ClearStalled,        SEG code
ht19 DD OFFSET GetMaxLen,           SEG code
ht1A DD 0,                          0
ht1B DD 0,                          0
ht1C DD OFFSET SetMaxLen,           SEG code
ht1D DD OFFSET CloseControlPipe,    SEG code
hc1E DD OFFSET IssueOne,            SEG code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HubAttach
;
;   description:    Hub attach event
;
;   Parameters:     DS      Function sel
;                   DX      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HubAttach    Proc near
    stc
    ret
HubAttach    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HubDetach
;
;   description:    Hub detach event
;
;   Parameters:     DS      Function sel
;                   DX      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HubDetach    Proc near
    stc
    ret
HubDetach    Endp
       
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
    push es
    pushad
;    
    EnterSection ds:hub_section
    inc dx
    mov ebx,ds
    mov es,ebx
    mov bx,ds:hub_control_handle
;    
    mov edi,OFFSET hub_control_data
    mov es:[edi].usd_type,23h
    mov es:[edi].usd_req,SET_FEATURE
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,dx
    mov es:[edi].usd_len,0
    mov ecx,8
    WriteUsbControl
    ReqUsbStatus
    StartUsbTransaction
;
    GetSystemTime
    add eax,1000 * 1193    
    adc edx,0
    mov bx,ds:hub_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hub_control_handle
    WasUsbTransactionOk
    LeaveSection ds:hub_section
;
    popad
    pop es
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
    push es
    pushad
;    
    EnterSection ds:hub_section
    inc dx
    mov ebx,ds
    mov es,ebx
    mov bx,ds:hub_control_handle
;    
    mov edi,OFFSET hub_control_data
    mov es:[edi].usd_type,23h
    mov es:[edi].usd_req,CLEAR_FEATURE
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,dx
    mov es:[edi].usd_len,0
    mov ecx,8
    WriteUsbControl
    ReqUsbStatus
    StartUsbTransaction
;
    GetSystemTime
    add eax,1000 * 1193    
    adc edx,0
    mov bx,ds:hub_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hub_control_handle
    WasUsbTransactionOk
    LeaveSection ds:hub_section
;
    popad
    pop es
    ret
ClearPortFeature Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClearPortChange
;
;   description:    Clear port change
;
;   Parameters:     GS      Hub
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
    mov ax,16
    call ClearPortFeature
    pop ax

cpcConnectOk:    
    test ax,2
    jz cpcEnableOk
;
    push ax
    mov ax,17
    call ClearPortFeature
    pop ax

cpcEnableOk:
    test ax,4
    jz cpcSuspendOk
;
    push ax
    mov ax,18
    call ClearPortFeature
    pop ax

cpcSuspendOk:
    test ax,8
    jz cpcOverCurrentOk
;
    push ax
    mov ax,19
    call ClearPortFeature
    pop ax

cpcOverCurrentOk:
    test ax,10h
    jz cpcResetOk
;
    push ax
    mov ax,20
    call ClearPortFeature
    pop ax
                
cpcResetOk:
    pop eax
    ret
ClearPortChange Endp

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
    EnterSection ds:hub_section
    inc dx
    mov eax,ds
    mov es,eax
    mov bx,ds:hub_control_handle
;    
    mov edi,OFFSET hub_control_data
    mov es:[edi].usd_type,0A3h
    mov es:[edi].usd_req,GET_STATUS
    mov es:[edi].usd_value,0
    mov es:[edi].usd_index,dx
    mov es:[edi].usd_len,4
    mov ecx,8
    WriteUsbControl
;
    mov ecx,4
    mov edi,OFFSET hub_buf
    mov es:[edi].uhd_type,0
    ReqUsbData    
;    
    WriteUsbStatus
    StartUsbTransaction
;
    push edx
    GetSystemTime
    add eax,1000 * 1193    
    adc edx,0
    mov bx,es:hub_control_wait
    WaitWithTimeout
    pop edx
;    
    mov bx,es:hub_control_handle
    WasUsbTransactionOk
    LeaveSection ds:hub_section
    jc gpsDone
;    
    dec dx
    mov eax,dword ptr ds:hub_buf
    call ClearPortChange
;
    movzx edi,dx
    add edi,edi
    mov ds:[edi].hub_status_arr,ax
    clc    

gpsDone:    
    popad
    pop es
    ret
GetPortStatus Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AttachThread
;
;   DESCRIPTION:    Attach thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

attach_thread_name  DB 'Hub Attach ', 0

attach_thread:
    int 3
    mov cl,dl
    mov ds,bx
;    
    movzx edi,cl
    add edi,edi
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[edi].usb_attach_thread_arr,ax
    LeaveSection ds:usb_section
;
    LockUsb
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz atUnlock
;
    test ds:[edi].hub_status_arr,1
    jz atUnlock
;
    movzx dx,cl
    mov ax,PORT_RESET
    call SetPortFeature
;        
    mov cx,40

atWaitLoop:
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz atUnlock
;
    mov ax,ds:[edi].hub_status_arr
    test ax,1
    jz atUnlock
;
    test ax,2
    jnz atIsEnabled
;
    mov ax,25
    WaitMilliSec
    loop atWaitLoop
;
    jmp atUnlock    

atIsEnabled:
    movzx dx,cl
    call HubAttach 
    jnc atDone
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz atUnlock
;
    test ds:[edi].hub_status_arr,1
    jz atUnlock
;
    movzx dx,cl
    mov ax,PORT_POWER
    call ClearPortFeature    
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz atUnlock
;
    test ds:[edi].hub_status_arr,1
    jz atUnlock
;
    mov ax,250
    WaitMilliSec
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz atUnlock
;
    test ds:[edi].hub_status_arr,1
    jz atUnlock
;
    movzx dx,cl
    mov ax,PORT_POWER
    call SetPortFeature    
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz atUnlock
;
    mov ax,ds:hub_power_time
    WaitMilliSec

atUnlock:
    UnlockUsb

atDone:
    EnterSection ds:usb_section
    mov ds:[edi].usb_attach_thread_arr,0
    LeaveSection ds:usb_section
;
    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           DetachThread
;
;   DESCRIPTION:    Detach thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

detach_thread_name  DB 'Hub Detach ', 0

detach_thread:
    mov cl,dl
    mov ds,bx
;
    movzx edi,cl
    add edi,edi
;    
    EnterSection ds:usb_section
    GetThread
    mov ds:[edi].usb_detach_thread_arr,ax
    LeaveSection ds:usb_section
;
    movzx dx,cl
    call HubDetach
;
    EnterSection ds:usb_section
    mov ds:[edi].usb_detach_thread_arr,0
    LeaveSection ds:usb_section    
    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetThread
;
;   DESCRIPTION:    Reset thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_thread_name  DB 'Hub Reset ', 0

reset_thread:
    mov cl,dl
    mov ds,bx
;
    movzx edi,cl
    add edi,edi
;    
    EnterSection ds:usb_section
    GetThread
    mov ds:[edi].usb_reset_thread_arr,ax
    LeaveSection ds:usb_section
;
    movzx dx,cl
    call HubDetach
;
    LockUsb
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz rtUnlock
;
    test ds:[edi].hub_status_arr,1
    jz rtUnlock
;
    movzx dx,cl
    mov ax,PORT_RESET
    call SetPortFeature
;        
    mov cx,40

rtWaitLoop:
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz rtUnlock
;
    mov ax,ds:[edi].hub_status_arr
    test ax,1
    jz rtUnlock
;
    test ax,2
    jnz rtIsEnabled
;
    mov ax,25
    WaitMilliSec
    loop rtWaitLoop
;
    jmp rtUnlock    

rtIsEnabled:
    movzx dx,cl
    call HubAttach 
    jnc rtDone
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz rtUnlock
;
    test ds:[edi].hub_status_arr,1
    jz rtUnlock
;
    movzx dx,cl
    mov ax,PORT_POWER
    call ClearPortFeature    
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz rtUnlock
;
    test ds:[edi].hub_status_arr,1
    jz rtUnlock
;
    mov ax,250
    WaitMilliSec
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz rtUnlock
;
    test ds:[edi].hub_status_arr,1
    jz rtUnlock
;
    movzx dx,cl
    mov ax,PORT_POWER
    call SetPortFeature    
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz rtUnlock
;
    test ds:[edi].hub_status_arr,1
    jz rtUnlock
;
    mov ax,ds:hub_power_time
    WaitMilliSec

rtUnlock:
    UnlockUsb

rtDone:
    EnterSection ds:usb_section
    mov ds:[edi].usb_reset_thread_arr,0
    LeaveSection ds:usb_section    
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartThread
;
;       DESCRIPTION:    Start thread
;
;       PARAMETERS:     DS      Function sel (passed as bx)
;                       DX      Passed through
;                       AX      Prio
;                       ESI     Entry
;                       EDI     Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartThread Proc near
    push es            
    push ax
;
    push esi
;
    mov esi,edi
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi

sfCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz sfCopyDone
;
    stosb
    jmp sfCopyLoop

sfCopyDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,dl
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    pop esi         
;
    mov ebx,ds
    xor edi,edi
    mov eax,cs
    mov ds,eax
    pop ax
    mov ecx,stack0_size
    CreateThread
;
    FreeMem
    pop es
    ret
StartThread Endp
        
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
    push ds
    pushad
;    
    movzx edi,dx
    add edi,edi
;    
    mov eax,1
    mov cx,dx
    shl eax,cl
    test eax,ds:hub_reset
    jz upNoReset
;
    not eax
    lock and ds:hub_reset,eax
;        
    mov ax,ds:[edi].hub_status_arr
    test al,1
    jz upNoReset
;
    mov bx,ds:[edi].hub_port_arr
    or bx,bx
    jz upNoReset
;    
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_reset_thread_arr,-1
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov dx,cx
    mov esi,OFFSET reset_thread
    mov edi,OFFSET reset_thread_name
    mov ax,2
    call StartThread
    jmp upDone
    
upNoReset:
    mov ax,ds:[edi].hub_status_arr
    test al,1
    jz upDetach
    
upAttach:
    mov bx,ds:[edi].hub_port_arr
    or bx,bx
    jnz upCheckTimeout
;    
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_attach_thread_arr,-1
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov dx,cx
    mov esi,OFFSET attach_thread
    mov edi,OFFSET attach_thread_name
    mov ax,2
    call StartThread
    jmp upDone

upDetach:
    mov bx,ds:[edi].hub_port_arr
    or bx,bx
    jz upCheckTimeout
;    
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_detach_thread_arr,-1    
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov dx,cx
    mov esi,OFFSET detach_thread
    mov edi,OFFSET detach_thread_name
    mov ax,2
    call StartThread
    jmp upDone

upCheckTimeout:
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jz upDone
;
    GetSystemTime
    sub eax,ds:[4*edi].usb_timeout_arr
    sbb edx,ds:[4*edi].usb_timeout_arr+4
    jc upDone
;
    mov ax,ds:[edi].usb_retry_arr
    inc ax
    mov ds:[edi].usb_retry_arr,ax
;
    cmp ax,100
    jb upNotFatal
;
    int 3

upNotFatal:
    cmp ax,10
    jnz upDoSignal
;   
;    mov eax,es:[2*edi].HcPortSc
;    and al,NOT 4
;    mov es:[2*edi].HcPortSc,eax

upDoSignal:
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;
    EnterSection ds:usb_section
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,bx
    jz upCheckDetach
;
    Signal
    jmp upLeave

upCheckDetach:    
    mov bx,ds:[edi].usb_detach_thread_arr
    or bx,bx
    jz upCheckReset
;
    Signal
    jmp upLeave
            
upCheckReset:    
    mov bx,ds:[edi].usb_reset_thread_arr
    or bx,bx
    jz upLeave
;
    Signal

upLeave:
    LeaveSection ds:usb_section
                
upDone:    
    popad
    pop ds    
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
    CreateWait
    mov ds:hub_control_wait,bx
;
    mov bx,ds:hub_controller
    mov al,ds:hub_device
    xor dl,dl
    OpenUsbPipe
    mov ds:hub_control_handle,bx
;
    mov ax,ds:hub_control_handle
    mov bx,ds:hub_control_wait
    xor ecx,ecx
    AddWaitForUsbPipe
;    
    mov bx,ds:hub_controller
    mov al,ds:hub_device
    mov dl,ds:hub_intr
    OpenUsbPipe
    mov ds:hub_status_handle,bx
;
    mov bx,ds:hub_status_handle
    CreateUsbReq
    mov ds:hub_status_req,bx
;
    mov cx,ds:hub_status_size
    xor ax,ax
    AddReadUsbDataReq
    mov ds:hub_status_sel,es
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
    mov bx,ds:hub_status_req
    CloseUsbReq
;    
    mov bx,ds:hub_status_handle
    CloseUsbPipe
;    
    mov bx,ds:hub_control_handle
    CloseUsbPipe
;    
    mov bx,ds:hub_control_wait
    CloseWait
;
    pop bx
    ret
CloseHub   Endp

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
    mov bx,ds:hub_control_handle
;    
    mov edi,OFFSET hub_control_data
    mov es:[edi].usd_type,0A0h
    mov es:[edi].usd_req,GET_DESCR
    mov es:[edi].usd_value,2900h
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,HUB_BUF_SIZE
    mov ecx,8
    WriteUsbControl
;
    mov ecx,HUB_BUF_SIZE
    mov edi,OFFSET hub_buf
    mov es:[edi].uhd_type,0
    ReqUsbData    
;    
    WriteUsbStatus
    StartUsbTransaction
;
    GetSystemTime
    add eax,1000 * 1193    
    adc edx,0
    mov bx,ds:hub_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hub_control_handle
    WasUsbTransactionOk
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
;
    movzx ecx,ds:hub_ports
    mov ebx,OFFSET hub_port_arr
    xor ax,ax

phdLoop:
    mov ds:[ebx],ax
    add ebx,2
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
;   NAME:           InitPorts
;
;   description:    Init ports
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPorts    Proc near
    push ax
    push dx
;
    xor dx,dx

ipLoop:
    mov ax,PORT_POWER
    call SetPortFeature    
;        
    test ds:hub_flags,FLAG_HUB_DISCONNECT
    jnz ipDone
;
    inc dx
    cmp dx,ds:hub_ports
    jb ipLoop

ipDone:           
    pop dx
    pop ax
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

hub_port_name    DB 'Usb Hub Port ', 0

usb_hub_port:
    int 3
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
    mov ds:hub_port_thread,0
    mov bx,ds:hub_detach
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

CreatePortThread	Proc near
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
CreatePortThread	Endp
        
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

hub_status_name    DB 'Usb Hub Status ', 0

usb_hub_status:
    mov ds,ebx
;
    GetThread
    mov ds:hub_detach,0
    mov ds:hub_status_thread,ax
    and ds:hub_flags,NOT FLAG_HUB_DISCONNECT
;
    call CreateHub
    call ProcessHubDescr
    jc tsExit
;
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
    mov bx,ds:hub_status_req
    IsUsbReqStarted
    jnc tsWaitSignal
;
    GetThread
    StartUsbReq    

tsWaitSignal:
    WaitForSignal
;
    mov bx,ds:hub_status_req
    IsUsbReqReady
    jc tsNext
;
    GetUsbReqData
    cmp cx,ds:hub_status_size
    jne tsNext
;
    mov bx,cx
    mov es,ds:hub_status_sel
    xor edi,edi
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
    mov bx,ds:hub_detach
    Signal

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
;   NAME:           CreateStatusThread
;
;   description:    Create hub status thread
;
;   Parameters:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateStatusThread	Proc near
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
CreateStatusThread	Endp

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
    ConfigUsbDevice
    jc uaFail
;
    mov gs:hub_controller,bx
    mov gs:hub_device,al
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
    mov es:hub_device,al
    mov es:hub_intr,0
    mov es:hub_detach,0
    mov es:hub_flags,0
    mov es:hub_status_thread,0
    mov es:hub_port_thread,0
    mov es:hub_reset,0
    InitSection es:hub_section
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
    mov eax,SEG data
    mov ds,eax
    movzx esi,ds:hub_dev_count
    add esi,esi
    mov ds:[esi].hub_dev_arr,es
    inc ds:hub_dev_count
;
    mov esi,OFFSET hub_tab
    xor edi,edi
    mov ecx,2*1Fh

uaTabLoop:
    lods dword ptr cs:[esi]
    mov es:[edi],eax
    add edi,4
    loop uaTabLoop    
;
    mov ebx,es
    mov ds,ebx
    InitUsbDevice
;
    call CreateStatusThread
    jmp uaDone

uaFail:
    FreeMem

uaDone:    
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
;
    mov bx,es:hub_status_thread
    or bx,bx
    jz udStatusOk
;
    mov ecx,10

udStatusSignal:
    Signal
;
    WaitForSignal
    mov bx,es:hub_status_thread
    or bx,bx
    jz udStatusOk
;
    loop udStatusSignal

udStatusOk:
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
