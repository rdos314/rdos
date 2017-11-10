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

id_hook_struc   STRUC

ih_id       DD ?
ih_mask     DD ?
ih_offset   DD ?
ih_sel      DW ?
ih_param    DW ?

id_hook_struc   ENDS


capture_block   STRUC

cc_prev     DD ?
cc_next     DD ?
cc_time     DD ?,?
cc_id       DD ?
cc_data     DD ?,?
cc_size     DB ?

capture_block   ENDS

data    SEGMENT byte public 'DATA'

cd_thread        DW ?
cd_controller    DW ?
cd_control_pipe  DW ?
cd_control_wait  DW ?
cd_in_pipe       DW ?
cd_in_wait       DW ?
cd_out_pipe      DW ?
cd_out_wait      DW ?
cd_device        DB ?
cd_active        DB ?

can_send_section section_typ <>

in_buf           DB 10 DUP(?)
out_buf          DB 10 DUP(?)

can_active       DB ?
can_extra        DB ?

hw_id            DB ?
rdos_major       DB ?
rdos_minor       DB ?
ver_major        DB ?
ver_minor        DB ?
ver_sub          DB ?

can_id_hook_arr  DD 15 * 4 DUP(?)

capture_handle          DW ?
capture_thread          DW ?
capture_list            DD ?
capture_section         section_typ <>

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
;       NAME:           OpenPipes
;
;       DESCRIPTION:    Open pipes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPipes   Proc near
    mov bx,ds:cd_control_wait
    or bx,bx
    jz opCreateControlWait
;
    CloseWait

opCreateControlWait:
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
;
    mov bx,ds:cd_in_wait
    or bx,bx
    jz opCreateInWait
;
    CloseWait

opCreateInWait:
    CreateWait
    mov ds:cd_in_wait,bx
;
    mov bx,ds:cd_controller
    movzx ax,ds:cd_device
    mov dl,81h
    OpenUsbPipe
    mov ds:cd_in_pipe,bx
;
    mov ax,ds:cd_in_pipe
    mov bx,ds:cd_in_wait
    movzx ecx,bx
    AddWaitForUsbPipe
;
    mov bx,ds:cd_out_wait
    or bx,bx
    jz opCreateOutWait
;
    CloseWait

opCreateOutWait:
    CreateWait
    mov ds:cd_out_wait,bx
;
    mov bx,ds:cd_controller
    movzx ax,ds:cd_device
    mov dl,2
    OpenUsbPipe
    mov ds:cd_out_pipe,bx
;
    mov ax,ds:cd_out_pipe
    mov bx,ds:cd_out_wait
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
    jc gsvDone
;
    mov bx,OFFSET cd_data
    mov al,[bx]
    mov ds:hw_id,al
    mov al,[bx+1]
    mov ds:rdos_major,al
    mov al,[bx+2]
    mov ds:rdos_minor,al
    mov al,[bx+4]
    mov ds:ver_major,al
    mov al,[bx+5]
    mov ds:ver_minor,al
    mov al,[bx+6]
    mov ds:ver_sub,al

gsvDone:
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
;       NAME:           StartModules
;
;       DESCRIPTION:    Start modules
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartModules   Proc near
    mov bx,ds:cd_control_pipe
    LockUsbPipe
;
    mov cx,8
    mov di,OFFSET cd_setup
    mov es:[di].usd_type,41h
    mov es:[di].usd_req,91h
    mov es:[di].usd_value,0
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
StartModules  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           StartCanCom
;
;       DESCRIPTION:    Start can communication
;
;       RETURNS:        EAX     Number of devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_can_com_name    DB 'Start Can Com', 0

start_can_com   Proc far
    push ds
    push es
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov ds:can_active,0

sccWait:
    mov ax,ds:cd_control_pipe
    or ax,ax
    jnz sccDo
;
    mov ax,250
    WaitMilliSec
    jmp sccWait

sccDo:
    call PowerDownModules
    mov ax,500
    WaitMilliSec
;
    call PowerUpModules
    mov ax,5000
    WaitMilliSec
;
    call StartModules
    mov ax,500
    WaitMilliSec
    mov ds:can_active,1
;
    mov eax,1
    pop es
    pop ds
    retf32
start_can_com  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CaptureThread
;
;           description:    Capture thread
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

capture_thread_name DB 'Can Capture', 0

capture_thread_pr:
    mov bx,SEG data
    mov ds,bx
    GetThread
    mov ds:capture_thread,ax
    LeaveSection ds:capture_section
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov bx,ds:capture_handle
    xor eax,eax
    SetFilePos
    SetFileSize

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
    mov eax,es:[edx].cc_next
    mov ebx,es:[edx].cc_prev
    mov es:[ebx].cc_next,eax
    mov es:[eax].cc_prev,ebx
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
    add edi,OFFSET cc_time
    mov ecx,SIZE capture_block - OFFSET cc_time
    UserGateForce32 write_file_nr
;
    mov ecx,SIZE capture_block
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
;   NAME:           NotifyMsg
;
;   Description:    Notify reception of ethernet packet
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyMsg  Proc near
    push ds
    push si
;
    mov si,SEG data
    mov ds,si
    EnterSection ds:capture_section
    mov si,ds:capture_thread
    or si,si
    jz nmLeave
;    
    push es
    pushad
;    
    push eax
    push edx
    mov dx,flat_sel
    mov es,dx
    mov eax,SIZE capture_block
    AllocateSmallLinear
    mov edi,edx
    GetTime
    mov es:[edi].cc_time,eax
    mov es:[edi].cc_time+4,edx
    pop edx
    pop eax
;    
    mov es:[edi].cc_id,ebx
    mov es:[edi].cc_data,eax
    mov es:[edi].cc_data+4,edx
    mov es:[edi].cc_size,cl
    mov edx,edi
;
    mov bx,SEG data
    mov ds,bx
;
    mov eax,ds:capture_list
    or eax,eax
    jne nmQueue

nmEmpty:
    mov es:[edx].cc_prev,edx
    mov es:[edx].cc_next,edx
    mov ds:capture_list,edx
    jmp nmSignal

nmQueue:
    mov ebx,es:[eax].cc_prev
    mov es:[eax].cc_prev,edx
    mov es:[ebx].cc_next,edx
    mov es:[edx].cc_prev,ebx
    mov es:[edx].cc_next,eax    

nmSignal:
    mov bx,ds:capture_thread
    Signal
;
    popad
    pop es

nmLeave:
    LeaveSection ds:capture_section
;    
    pop si
    pop ds    
    ret
NotifyMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           HandleMsg
;
;   DESCRIPTION:    Notify CAN message
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


HandleMsg   Proc near
    push ds
    push es
;
    call NotifyMsg
;
    push eax
    push ecx
;
    mov si,OFFSET can_id_hook_arr
    mov cx,15

hmIdLoop:
    mov di,ds:[si].ih_sel
    or di,di
    jz hmIdNext
;
    mov eax,ds:[si].ih_mask
    and eax,ebx
    cmp eax,ds:[si].ih_id
    je hmIdOk

hmIdNext:
    add si,16
    loop hmIdLoop
;
    pop ecx
    pop eax
    jmp hmDone

hmIdOk:
    mov ax,ds
    mov es,ax
;
    pop ecx
    pop eax
;
    mov ds,es:[si].ih_param
    call fword ptr es:[si].ih_offset

hmDone:
    pop es
    pop ds
    ret
HandleMsg   Endp

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
    call OpenPipes
    call GetSoftwareVersion
    jc utEnd
;
    mov edi,OFFSET in_buf
    mov bx,ds:cd_in_pipe
    mov ecx,10
    ReqUsbData
    StartUsbTransaction

utPipeOk:
    mov bx,ds:cd_in_wait
    WaitWithoutTimeout
;
    mov bx,ds:cd_in_pipe
    IsUsbTransactionDone
    jc utPipeOk
;
    WasUsbTransactionOk
;
    mov edi,OFFSET in_buf
    mov cl,[di+1]
    and cl,0Fh
    movzx ebx,word ptr [di]
    xchg bl,bh
    and bl,0F0h
    shl ebx,14
    mov eax,[di+2]
    mov edx,[di+6]
    call HandleMsg
;
    mov bx,ds:cd_in_pipe
    mov ecx,10
    mov edi,OFFSET in_buf
    ReqUsbData
    StartUsbTransaction
    jmp utPipeOk

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
    mov ds:can_active,0
    mov ds:cd_controller,0
    mov ds:cd_device,0
    mov ds:cd_active,0
    mov ds:cd_control_pipe,0
    mov ds:cd_in_pipe,0
    mov ds:cd_out_pipe,0

udDone:
    popad
    pop es
    pop ds
    retf32
usb_detach  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateCanIdHook
;
;   DESCRIPTION:    Create an id-based filter hook
;
;   PARAMETERS:     EAX       Identifier 
;                   EDX       Identifier mask
;                   DS        Param
;                   ES:EDI    Hook callback
;                       DS        Param
;                       EDX:EAX   Data
;                       CL        Size (0..8)
;                       EBX       Identifier
;
;   RETURNS:        BX        Buffer #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_id_hook_name   DB 'Create CAN ID Hook', 0

create_id_hook    Proc far
    push ds
    push es
    push cx
    push esi
    push bp
;    
    xor ax,ax
    mov bp,ds
    mov bx,SEG data
    mov ds,bx
;
    mov bx,OFFSET can_id_hook_arr
    mov cx,15

cihLoop:
    mov si,ds:[bx].ih_sel
    or si,si
    jz cihFound
;
    add bx,16        
    loop cihLoop
;
    stc
    jmp cihDone

cihFound:
    mov ds:[bx].ih_id,eax
    mov ds:[bx].ih_mask,edx
    mov ds:[bx].ih_param,bp
    mov ds:[bx].ih_offset,edi
    mov ds:[bx].ih_sel,es
;            
    sub bx,OFFSET can_id_hook_arr
    shr bx,4
    inc bx
    clc
    
cihDone:
    pop bp
    pop esi
    pop cx
    pop es
    pop ds    
    retf32
create_id_hook    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           DeleteCanIdHook
;
;   DESCRIPTION:    Delete an id-based filter hook
;
;   PARAMETERS:     BX        Buffer #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_id_hook_name   DB 'Delete CAN ID Hook', 0

delete_id_hook    Proc far    
    or bx,bx
    jz dihDone
;
    cmp bx,15
    jae dihDone
;        
    push ds
    push es
    push ax
    push bx
;    
    mov ax,SEG data
    mov ds,ax
;    
    dec bx
    shl bx,4
    add bx,OFFSET can_id_hook_arr
    mov ds:[bx].ih_id,0
    mov ds:[bx].ih_mask,0
    mov ds:[bx].ih_param,0
    mov ds:[bx].ih_offset,0
    mov ds:[bx].ih_sel,0
;    
    pop bx
    pop ax
    pop es
    pop ds    
    
dihDone:
    clc
    retf32
delete_id_hook    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendCanBusMsg
;
;   DESCRIPTION:    Send CAN bus message
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_can_bus_msg_name   DB 'Send CAN Bus Message', 0

send_can_bus_msg    Proc far
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
;
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov es,ax
;
    EnterSection ds:can_send_section

scbWait:
    mov al,ds:can_active
    or al,al
    jnz scbActive
;
    mov ax,100
    WaitMilliSec
    jmp scbWait

scbActive:
    pop ax
;
    call NotifyMsg
;
    mov edi,OFFSET out_buf
    mov byte ptr [di],0
    mov [di+1],cl
    shr ebx,14
    xchg bl,bh
    or [di],bx
    mov [di+2],eax
    mov [di+6],edx
;
    mov bx,ds:cd_out_pipe
    mov ecx,10
    mov edi,OFFSET out_buf
    WriteUsbData
    StartUsbTransaction    

scbRetry:
    mov bx,ds:cd_out_wait
    WaitWithoutTimeout
;
    mov bx,ds:cd_out_pipe
    IsUsbTransactionDone
    jc scbRetry
;
    mov bx,ds:cd_out_pipe
    WasUsbTransactionOk
    jnc scbLeave
;
    int 3

scbLeave:
    LeaveSection ds:can_send_section

scbDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds
    retf32
send_can_bus_msg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartCanCapture
;
;           description:    Start capturing CAN-packets
;
;       parameters:     BX      File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_can_capture_name DB 'Start Can Capture', 0

start_can_capture       Proc
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
start_can_capture       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopCanCapture
;
;           description:    Stop capturing can-packets
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_can_capture_name DB 'Stop Can Capture', 0

stop_can_capture    Proc
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
stop_can_capture    Endp

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
    mov es:cd_control_pipe,0
    mov es:cd_in_pipe,0
    mov es:cd_out_pipe,0
    mov es:can_active,0
    InitSection es:can_send_section
    InitSection es:capture_section
    mov es:capture_handle,0
    mov es:capture_thread,0
    mov es:capture_list,0
;
    mov di,OFFSET can_id_hook_arr
    mov cx,4 * 15
    xor eax,eax
    rep stosd
;       
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET start_can_com
    mov edi,OFFSET start_can_com_name
    mov ax,start_can_com_nr
    RegisterOsGate
;
    mov esi,OFFSET create_id_hook
    mov edi,OFFSET create_id_hook_name
    mov ax,create_can_id_hook_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_id_hook
    mov edi,OFFSET delete_id_hook_name
    mov ax,delete_can_id_hook_nr
    RegisterOsGate
;
    mov esi,OFFSET send_can_bus_msg
    mov edi,OFFSET send_can_bus_msg_name
    mov ax,send_can_bus_msg_nr
    RegisterOsGate
;
    mov esi,OFFSET send_can_bus_msg
    mov edi,OFFSET send_can_bus_msg_name
    mov ax,send_can_bus_block_nr
    RegisterOsGate
;
    mov esi,OFFSET start_can_capture
    mov edi,OFFSET start_can_capture_name
    xor dx,dx
    mov ax,start_can_capture_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_can_capture
    mov edi,OFFSET stop_can_capture_name
    xor dx,dx
    mov ax,stop_can_capture_nr
    RegisterBimodalUserGate
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
