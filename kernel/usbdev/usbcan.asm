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
; USBCAN.ASM
; USB can driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include usb.inc
INCLUDE ..\os\protseg.def


data    SEGMENT byte public 'DATA'

cd_thread        DW ?
cd_controller    DW ?
cd_control_pipe  DW ?
cd_control_wait  DW ?
cd_device        DB ?
cd_active        DB ?

cd_setup         usb_setup_data <>
cd_data          DB 8 DUP(?)

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleCan
;
;       DESCRIPTION:    Handle CAN 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleCan	Proc near

    mov ax,20
    WaitMilliSec
    ret
HandleCan       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPipes
;
;       DESCRIPTION:    Open pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPipes   Proc near
    mov bx,ds:cd_control_wait
    or bx,bx
    jz opCreateWait
;
    CloseWait

opCreateWait:
    CreateWait
    mov ds:cd_control_wait,bx
;
    mov bx,ds:cd_controller
    movzx ax,ds:cd_device
    xor dl,dl
    OpenUsbPipe
    mov ds:cd_control_pipe,bx
;
    mov ax,ds:cd_control_pipe
    mov bx,ds:cd_control_wait
    movzx ecx,bx
    AddWaitForUsbPipe
    ret
OpenPipes  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetSoftwareVersion
;
;       DESCRIPTION:    Get software version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSoftwareVersion   Proc near
    mov bx,ds:cd_control_pipe
    LockUsbPipe
;
    mov cx,8
    mov di,OFFSET cd_setup
    mov es:[di].usd_type,0C1h
    mov es:[di].usd_req,92h
    mov es:[di].usd_value,0
    mov es:[di].usd_index,0
    mov es:[di].usd_len,6
    WriteUsbControl
;
    mov cx,6
    mov di,OFFSET cd_data
    ReqUsbData
;
    WriteUsbStatus
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:cd_control_wait
    WaitWithTimeout
;    
    mov bx,ds:cd_control_pipe
    WasUsbTransactionOk
    pushf
    UnlockUsbPipe
    popf
    ret
GetSoftwareVersion  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetBufferSize
;
;       DESCRIPTION:    Get max buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBufferSize   Proc near
    mov bx,ds:cd_control_pipe
    LockUsbPipe
;
    mov cx,8
    mov di,OFFSET cd_setup
    mov es:[di].usd_type,0C1h
    mov es:[di].usd_req,83h
    mov es:[di].usd_value,0
    mov es:[di].usd_index,0
    mov es:[di].usd_len,4
    WriteUsbControl
;
    mov cx,4
    mov di,OFFSET cd_data
    ReqUsbData
;
    WriteUsbStatus
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:cd_control_wait
    WaitWithTimeout
;    
    mov bx,ds:cd_control_pipe
    WasUsbTransactionOk
    pushf
    UnlockUsbPipe
    popf
    ret
GetBufferSize  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PowerUpModules
;
;       DESCRIPTION:    Power up modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerUpModules   Proc near
    mov bx,ds:cd_control_pipe
    LockUsbPipe
;
    mov cx,8
    mov di,OFFSET cd_setup
    mov es:[di].usd_type,41h
    mov es:[di].usd_req,93h
    mov es:[di].usd_value,101h
    mov es:[di].usd_index,0
    mov es:[di].usd_len,0
    WriteUsbControl
;    
    ReqUsbStatus
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:cd_control_wait
    WaitWithTimeout
;    
    mov bx,ds:cd_control_pipe
    WasUsbTransactionOk
    pushf
    UnlockUsbPipe
    popf
    ret
PowerUpModules  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PowerDownModules
;
;       DESCRIPTION:    Power down modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerDownModules   Proc near
    mov bx,ds:cd_control_pipe
    LockUsbPipe
;
    mov cx,8
    mov di,OFFSET cd_setup
    mov es:[di].usd_type,41h
    mov es:[di].usd_req,93h
    mov es:[di].usd_value,100h
    mov es:[di].usd_index,0
    mov es:[di].usd_len,0
    WriteUsbControl
;    
    ReqUsbStatus
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:cd_control_wait
    WaitWithTimeout
;    
    mov bx,ds:cd_control_pipe
    WasUsbTransactionOk
    pushf
    UnlockUsbPipe
    popf
    ret
PowerDownModules  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           USB CAN thread
;
;       DESCRIPTION:    USB can thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usbcan_thread_name DB 'USB Can', 0

usbcan_thread:
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    GetThread
    mov ds:cd_thread,ax

utLoop:
    mov al,ds:cd_active
    or al,al
    jz utEnd
;
    mov ax,ds:cd_control_pipe
    or ax,ax
    jnz utPipeOk
;
    int 3
    call OpenPipes
    call PowerUpModules
    call PowerDownModules
    call GetSoftwareVersion

utPipeOk:
    call HandleCan
    jmp utLoop

utEnd:
    mov ds:cd_thread,0
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddDevice
;
;       DESCRIPTION:    Add device
;
;       PARAMETERS:     AL      Device address
;                       BX      Controller id
;                       ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice Proc near
    push ds
    push es
    pushad
;
    mov dx,SEG data
    mov ds,dx
    mov ds:cd_device,al
    mov ds:cd_controller,bx
    mov ds:cd_active,1
;
    mov dx,ds:cd_thread
    or dx,dx
    jnz adThreadStarted
;
    mov ds:cd_thread,-1    
    mov dx,cs
    mov ds,dx
    mov es,dx
    mov di,OFFSET usbcan_thread_name
    mov si,OFFSET usbcan_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
        
adThreadStarted:
    popad
    pop es
    pop ds      
    ret
AddDevice Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_attach
;
;           description:    USB attach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

canTab:
cc00    DW 06F9h,       5555h
 
usb_attach  Proc far
    push es
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
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,1
    mov bp,OFFSET canTab

uaLoop:
    cmp si,cs:[bp]
    jne uaNext
;
    cmp di,cs:[bp+2]
    je uaFound

uaNext:
    add bp,4
    loop uaLoop    
;
    jmp uaDone    

uaFound:
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
    ConfigUsbDevice
    jc uaDone
;
    call AddDevice
    jmp uaDone
    
uaDone:
    FreeMem
;
    pop es    
    retf32
usb_attach  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       usb_detach
;
;           description:    USB detach callback
;
;           Parameters:     BX      Controller #
;               AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    mov dx,SEG data
    mov ds,dx
    cmp bx,ds:cd_controller
    jne udDone
;
    cmp al,ds:cd_device
    jne udDone
;
    mov ds:cd_controller,0
    mov ds:cd_device,0
    mov ds:cd_active,0
    mov ds:cd_control_pipe,0

udDone:
    popad
    pop es
    pop ds
    retf32
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
    mov bx,SEG data
    mov es,bx
    mov es:cd_thread,0
    mov es:cd_controller,0
    mov es:cd_device,0
    mov es:cd_active,0
    mov ds:cd_control_pipe,0
;       
    mov ax,cs
    mov ds,ax
    mov es,ax
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
