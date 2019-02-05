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
; USBBUS.ASM
; Implements USB bus class
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
include ..\os\com.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

FLAG_UDS_DISCONNECT = 2
FLAG_UDS_REINIT = 4

usbcom_port_struc       STRUC

ups_base_struc  com_port_struc <>

ups_device_sel      DW ?
ups_controller      DW ?
ups_device          DW ?
ups_control_wait    DW ?
ups_control_pipe    DW ?
ups_index           DW ?
ups_divisor         DD ?
ups_timer_active    DB ?
ups_data_bits       DB ?
ups_stop_bits       DB ?
ups_parity          DB ?
ups_control         DB ?

usbcom_port_struc       ENDS

usbcom_device_struc   STRUC

uds_base_struc      com_device_struc <>

uds_section         section_typ <>
uds_port_sel        DW ?
uds_in_size         DW ?
uds_out_size        DW ?
uds_interface       DB ?
uds_bulk_in         DB ?
uds_bulk_out        DB ?
uds_in_handle       DW ?
uds_out_handle      DW ?
uds_in_buffer       DW ?
uds_out_buffer      DW ?
uds_in_req          DW ?
uds_out_req         DW ?
uds_link            DW ?
uds_flag            DB ?
uds_port_nr         DW ?

usbcom_device_struc   ENDS

data    SEGMENT byte public 'DATA'

sd_thread       DW ?
sd_dead         DW ?
sd_spinlock     spinlock_typ <>
sd_port         DW ?

data	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitCom
;
;           description:    Init com port
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitCom   Proc near
    ret
InitCom   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           open_com
;
;           description:    Open a serial port
;
;           PARAMETERS:         DS      Port selector
;                       ES          Device selector
;                           AH          # of data bits
;                           BL          # of stop bits
;                           BH          parity
;                           ECX         baudrate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_com    Proc far
    push ds
    pushad
;
    mov ds:ups_timer_active,0
    mov ds:ups_data_bits,ah
    mov ds:ups_stop_bits,bl
    mov ds:ups_parity,bh
;
    CreateWait
    mov ds:ups_control_wait,bx
;
    mov bx,ds:ups_controller
    mov ax,ds:ups_device
    xor dl,dl
    OpenUsbPipe
    mov ds:ups_control_pipe,bx
;
    mov ax,ds:ups_control_pipe
    mov bx,ds:ups_control_wait
    movzx ecx,bx
    AddWaitForUsbPipe
;    
    call InitCom
;    
    mov ds:ups_device_sel,es
    mov dx,ds
    mov ax,es
    mov ds,ax
    EnterSection ds:uds_section
    mov ds:uds_port_sel,dx
    LeaveSection ds:uds_section       
;
    mov ax,SEG data
    mov ds,ax    
    mov bx,ds:sd_thread
    Signal    
    clc
;
    popad
    pop ds
    ret
open_com Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           close_com
;
;           description:    Close serial port
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_com   Proc far
    push ds
    push bx
;
    int 3
;
    pop bx
    pop ds    
    ret
close_com   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetPort
;
;           DESCRIPTION:    Reset com
;
;           PARAMETERS:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_port       PROC far
    push ds
    push es
    push ax
    push cx
    push di
;
    mov bx,ds:ups_controller
    mov ax,ds:ups_device
    xor dl,dl
    OpenUsbPipe
    ResetUsbPipe
    CloseUsbPipe
;
    pop di
    pop cx
    pop ax
    pop es
    pop ds
    ret
reset_port Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           start_send
;
;           description:    Start send
;
;           PARAMETERS:         DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_send      PROC far
    push es
    push ax
;    
    mov ax,ds:ups_device_sel
    or ax,ax
    jz ssDone
;    
    mov es,ax
    test es:uds_flag,FLAG_UDS_DISCONNECT
    jz ssOk
;
    mov ds:send_count,0
    jmp ssDone

ssOk:    
    call StartSendTimer

ssDone:
    pop ax
    pop es    
    ret
start_send      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       CreatePort
;
;           description:    Create port selector
;
;           RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_req	Proc near
    ret
error_req	Endp

port_tab:
pt00 DD OFFSET open_com,               SEG code
pt01 DD OFFSET close_com,              SEG code
pt02 DD OFFSET error_req,              SEG code
pt03 DD OFFSET error_req,              SEG code
pt04 DD OFFSET error_req,              SEG code
pt05 DD OFFSET error_req,              SEG code
pt06 DD OFFSET error_req,              SEG code
pt07 DD OFFSET error_req,              SEG code
pt08 DD OFFSET error_req,              SEG code
pt09 DD OFFSET error_req,              SEG code
pt10 DD OFFSET error_req,              SEG code
pt11 DD OFFSET start_send,             SEG code
pt12 DD OFFSET reset_port,             SEG code

CreatePort  Proc far
    pushad
;
    mov eax,SIZE usbcom_port_struc
    AllocateSmallGlobalMem
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov si,OFFSET port_tab
    xor di,di
    mov cx,2 * 13
    rep movs dword ptr es:[di],cs:[si]
;
    movzx ax,ds:uds_interface
    mov es:ups_index,ax    
    mov ax,ds:cd_controller
    mov es:ups_controller,ax
    mov ax,ds:cd_device
    mov es:ups_device,ax
;    
    popad
    retf32
CreatePort  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       OpenPort
;
;           description:    Open port selector
;
;           RETURNS:        ES      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPort Proc far
    int 3
    mov bx,ds:cd_controller
    mov ax,ds:cd_device
    mov dl,ds:uds_bulk_in
    OpenUsbPipe
    mov ds:uds_in_handle,bx
;
    CreateUsbReq
    mov ds:uds_in_req,bx    
;    
    mov cx,ds:uds_in_size
    xor ax,ax
    AddReadUsbDataReq
    mov ds:uds_in_buffer,es
;
    mov bx,ds:cd_controller
    mov ax,ds:cd_device
    mov dl,ds:uds_bulk_out
    OpenUsbPipe    
    mov ds:uds_out_handle,bx
;
    CreateUsbReq
    mov ds:uds_out_req,bx
;    
    mov cx,ds:uds_out_size
    mov ax,1
    AddWriteUsbDataReq
    mov ds:uds_out_buffer,es
    ret
OpenPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClosePort
;
;           DESCRIPTION:    Close port
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePort    Proc near
    mov ax,50
    WaitMilliSec
;    
    xor ax,ax
    mov es,ax
;    
    mov bx,ds:uds_in_req
    CloseUsbReq
    mov ds:uds_in_req,0
;
    mov bx,ds:uds_in_handle
    CloseUsbPipe    
    mov ds:uds_in_handle,0
;
    mov bx,ds:uds_out_req
    CloseUsbReq
    mov ds:uds_out_req,0
;
    mov bx,ds:uds_out_handle
    CloseUsbPipe    
    mov ds:uds_out_handle,0
    mov ds:uds_in_buffer,0
    mov ds:uds_out_buffer,0
    ret
ClosePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReInit
;
;           DESCRIPTION:    Reinit port
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReInit    Proc near
    push ds
    push es
    push cx
    push di
;    
    mov ax,ds
    mov es,ax
    mov ds,es:uds_port_sel
;
    mov bx,es:cd_controller
    mov ax,es:cd_device
    xor dl,dl
    OpenUsbPipe
    mov ds:ups_control_pipe,bx
;
    CreateWait
    mov ds:ups_control_wait,bx
;
    mov ax,ds:ups_control_pipe
    mov bx,ds:ups_control_wait
    movzx ecx,bx
    AddWaitForUsbPipe
;
    call InitCom
;
    pop di
    pop cx
    pop es
    pop ds
    ret
ReInit  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendSignal
;
;           description:    Sends signal to USB-handler thread
;
;       Parameters:     CX      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendSignal  Proc far
    push ds
    push ax
    push bx
;    
    verw cx
    jnz ssiDone
;    
    mov ds,cx
    mov ds:ups_timer_active,0
;    
    mov ax,SEG data
    mov ds,ax    
    mov bx,ds:sd_thread
    Signal    

ssiDone:
    pop bx
    pop ax
    pop ds
    retf32
SendSignal  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartSendTimer
;
;           description:    Starts send timeout
;
;       Parameters:     DS      Port selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartSendTimer Proc near
    push es
    pushad
;       
    mov al,1    
    xchg al,ds:ups_timer_active
    or al,al
    jnz sstDone
;
    GetSystemTime
    add eax,11930
    adc edx,0
;       
    mov bx,cs
    mov es,bx
    mov edi,OFFSET SendSignal
    mov bx,ds
    mov cx,bx
    StartTimer

sstDone:
    popad
    pop es
    ret
StartSendTimer Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PollRead
;
;           DESCRIPTION:    Poll input-buffer
;
;       PARAMETERS:     FS      SEG data
;               DS      Function sel
;               SI      Buffer offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollRead    Proc near
    push ds
    push fs
    mov fs,ds:uds_in_buffer
    mov ds,ds:uds_port_sel
    mov es,ds:rec_buf

prGetLoop:
    lods byte ptr fs:[si]
    RequestSpinlock ds:com_spinlock
    mov dx,ds:rec_count
    cmp dx,ds:rec_size
    je prSignal
;       
    inc dx
    mov ds:rec_count,dx
    mov bx,ds:rec_tail
    mov es:[bx],al
    inc bx
    cmp bx,ds:rec_size
    jnz prWrapOk
;
    xor bx,bx
    
prWrapOk:
    mov ds:rec_tail,bx
    ReleaseSpinlock ds:com_spinlock
    loop prGetLoop
    jmp prSigRel

prSignal:
    ReleaseSpinlock ds:com_spinlock

prSigRel:
    xor bx,bx
    xchg bx,ds:avail_obj
    or bx,bx
    jz prDone
;
    mov es,bx
    SignalWait
    
prDone:
    pop fs
    pop ds
    ret
PollRead    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PollWrite
;
;           DESCRIPTION:    Poll output-buffer
;
;       PARAMETERS:     FS      SEG data
;               DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollWrite    Proc near
    push ds
    push fs
;   
    xor cx,cx
    mov bp,ds:uds_out_size
    mov ax,ds:uds_out_buffer
    or ax,ax
    jz pwDone
;    
    mov es,ax
    mov ds,ds:uds_port_sel
    mov al,ds:ups_timer_active
    or al,al
    jnz pwDone
;    
    xor di,di
    mov fs,ds:send_buf
    mov dx,ds:send_count
    or dx,dx
    jz pwDone

pwLoop:
    RequestSpinlock ds:com_spinlock
    mov dx,ds:send_count
    or dx,dx
    jz pwSend
;       
    dec dx
    mov ds:send_count,dx
    mov bx,ds:send_head
    mov al,fs:[bx]
    stosb
    inc bx
    cmp bx,ds:send_size
    jnz pwWrapOk
;       
    xor bx,bx

pwWrapOk:
    mov ds:send_head,bx
    ReleaseSpinlock ds:com_spinlock
;
    inc cx
    cmp cx,bp
    jb pwLoop
    jmp pwSendRel

pwSend:
    ReleaseSpinlock ds:com_spinlock

pwSendRel:
    mov ax,ds:send_size    
    or ax,ax
    jz pwDone
;
    call StartSendTimer    

pwDone:
    pop fs
    pop ds    
    ret
PollWrite   Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HandleDevice
;
;           DESCRIPTION:    Handle device
;
;       PARAMETERS:     FS      SEG data
;               DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleDevice    Proc near
    push ds
;
    test ds:uds_flag,FLAG_UDS_DISCONNECT
    jnz hdDone

hdConn:
    mov ax,ds:uds_port_sel
    or ax,ax
    jz hdClosed

hdOpen:
    mov bx,ds:uds_in_req
    or bx,bx
    jnz hdIsOpen
;
    call OpenPort    
;
    test ds:uds_flag,FLAG_UDS_REINIT
    jz hdIsOpen    
;
    call ReInit
    and ds:uds_flag,NOT FLAG_UDS_REINIT

hdIsOpen:    
    mov bx,ds:uds_in_req
    IsUsbReqStarted
    jnc hdOpenOk
;
    StartUsbReq

hdOpenOk:    
    mov bx,ds:uds_in_req
    IsUsbReqReady
    jc hdReadDone
;
    GetUsbReqData
    jc hdReadRestart
;    
    xor si,si
    or cx,cx
    jz hdReadRestart
;    
    call PollRead

hdReadRestart:
    mov bx,ds:uds_in_req
    StartUsbReq

hdReadDone:
    mov bx,ds:uds_out_req
    IsUsbReqStarted
    jc hdCheckWrite
;    
    IsUsbReqReady
    jc hdDone
;
    push ds
    mov ds,ds:uds_port_sel
    mov bx,ds:send_wait
    pop ds
    or bx,bx
    jz hdCheckWrite
;    
    Signal

hdCheckWrite:
    call PollWrite
    or cx,cx
    jz hdDone
;
    mov bx,ds:uds_out_req
    StartUsbReq
    jmp hdDone

hdClosed:
    and ds:uds_flag,NOT FLAG_UDS_REINIT
;
    mov bx,ds:uds_in_req
    or bx,bx
    jz hdDone

hdIsClosed:
    call ClosePort
    
hdDone:
    xor ax,ax
    mov es,ax
    pop ds
    ret
HandleDevice    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UsbComThread
;
;           DESCRIPTION:    Com-port handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usbcom_thread_name  DB 'USB Bus Com', 0

usbcom_thread:
    mov ax,SEG data
    mov fs,ax
    GetThread
    mov fs:sd_thread,ax

utLoop:
    WaitForSignal
;
    mov ax,fs:sd_port
    or ax,ax
    jz utLoop
;
    mov ds,ax
    push cx
    push si
;
    EnterSection ds:uds_section
    call HandleDevice
    LeaveSection ds:uds_section
;
    pop si
    pop cx
    jmp utLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateDevice
;
;   DESCRIPTION:    Handle device attach
;
;   PARAMETERS:     AL      Device address
;                   BX      Controller id
;                   ES:DI   Interface descriptor + endpoints
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDevice Proc near
    push ds
    push es
    pushad
;    
    push dx
    push di
    mov dx,SEG data
    mov ds,dx
    mov dx,ds:sd_thread
    or dx,dx
    jnz cdThreadStarted
;
    mov ds:sd_thread,-1
    push ds
    push es
    push ax
    push si
    push di    
;    
    mov dx,cs
    mov ds,dx
    mov es,dx
    mov di,OFFSET usbcom_thread_name
    mov si,OFFSET usbcom_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    pop di
    pop si
    pop ax
    pop es
    pop ds
        
cdThreadStarted:
    push bx
    xor bx,bx
    xor bp,bp
    xor dx,dx
    xor si,si
    movzx cx,es:[di].uid_len
    add di,cx

cdDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,5
    jne cdDescrDone
;
    mov cl,es:[di].ued_attrib
    and cl,3
    cmp cl,2
    jne cdDescrNext
;
    mov cl,es:[di].ued_address
    test cl,80h    
    jnz cdBulkIn

cdBulkOut:
    inc si
    and cl,0Fh
    mov dl,cl
    mov bx,es:[di].ued_maxsize
    jmp cdDescrNext

cdBulkIn:
    inc si
    and cl,8Fh
    mov dh,cl
    mov bp,es:[di].ued_maxsize
    
cdDescrNext:    
    cmp si,2
    je cdDescrDone
;
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb cdDescrLoop    
    
cdDescrDone:
    shl ebp,16
    mov bp,bx    
    pop bx
;    
    mov cx,dx
    pop di
    pop dx
;    
    or cl,cl
    jz cdDone
;
    or ch,ch
    jz cdDone
;    
    mov dx,ds:sd_dead
    or dx,dx
    jz cdNoRecover
;
    mov ds:sd_dead,0
    mov ds,dx
    EnterSection ds:uds_section
    mov al,ds:uds_flag
    or al,FLAG_UDS_REINIT
    and al,NOT FLAG_UDS_DISCONNECT
    mov ds:uds_flag,al
;    
    mov ax,SEG data
    mov ds,ax
    mov ds:sd_port,dx
;
    mov ds,dx    
    LeaveSection ds:uds_section
;    
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_thread
    Signal    
    jmp cdDone
    
cdNoRecover:
    push cx
    mov cl,es:[di].uid_id
    push ax
    mov eax,SIZE usbcom_device_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:uds_interface,cl
    pop dx
    mov es:uds_port_sel,0
    mov es:uds_bulk_in,dh
    mov es:uds_bulk_out,dl
;       
    mov es:uds_out_size,bp
    shr ebp,16
    mov es:uds_in_size,bp
    mov es:uds_in_handle,0
    mov es:uds_in_req,0
    mov es:uds_in_buffer,0
    mov es:uds_out_handle,0
    mov es:uds_out_req,0
    mov es:uds_out_buffer,0
    mov es:uds_flag,0
;
    push ds
    mov si,es
    mov ds,si
    InitSection ds:uds_section
    pop ds
;
    mov ds:sd_port,es
    mov dx,es
    mov ds,dx
    mov dword ptr ds:cd_create_proc,OFFSET OpenPort
    mov dword ptr ds:cd_create_proc+4,cs
;    
    movzx dx,al
    mov ax,bx
    AddComPort
    mov ds:uds_port_nr,ax

cdDone:
    popad
    pop es
    pop ds      
    ret
CreateDevice Endp

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

devTab:
dt00    DW 054Dh,       1001h

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
    mov si,es:udd_vendor
    mov di,es:udd_prod

    mov cx,1
    mov bp,OFFSET devTab

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
    xor di,di
    movzx cx,es:ucd_len
    add di,cx

uaDescrLoop:
    mov cl,es:[di].udd_type
    cmp cl,4
    jne uaDescrNext
; 
    call CreateDevice
    jmp uaDone

uaDescrNext:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaDescrLoop    

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
    int 3
    movzx ax,al
    mov dx,SEG data
    mov ds,dx
    mov dx,ds:sd_port
    or dx,dx
    jz udDone
;
    mov es,dx
    cmp bx,es:cd_controller
    jne udDone
;
    cmp ax,es:cd_device
    jne udDone
;
    mov ds,dx
    EnterSection ds:uds_section
    or ds:uds_flag,FLAG_UDS_DISCONNECT
;    
    mov dx,SEG data
    mov ds,dx
    mov ds:sd_port,0
    mov ds:sd_dead,es
;
    mov ax,es
    mov ds,ax
    call ClosePort
;
    mov ax,ds:uds_port_sel
    or ax,ax
    jz udPortHandleOk
;
    push es
    mov es,ax
    mov bx,es:ups_control_wait
    CloseWait
    mov es:ups_control_wait,0
;    
    mov bx,es:ups_control_pipe
    CloseUsbPipe    
    mov es:ups_control_pipe,0
;
    mov es:send_count,0
    mov bx,es:send_wait
    or bx,bx
    jz udPortSendOk
;
    Signal    

udPortSendOk:
    pop es

udPortHandleOk:    
    LeaveSection ds:uds_section    

udDone:
    popad
    pop es
    pop ds
    ret
usb_detach  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetComPar
;
;   DESCRIPTION:    Get com param
;
;   PARAMETERS:     AL      Port #
;
;   RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_com_par_name    DB 'Get USB Bus Param', 0

get_com_par Proc far
    push ds
    push es
    push bx
;
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:sd_port
    or bx,bx
    jz gcpFail
;
    mov es,bx
    cmp ax,es:uds_port_nr
    je gcpFound

gcpFail:
    stc
    jmp gcpDone

gcpFound:
    clc

gcpDone:
    pop bx
    pop es
    pop ds
    ret
get_com_par     ENDP    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov ax,SEG data
    mov ds,eax
    mov ds:sd_thread,0
    mov ds:sd_port,0
    mov ds:sd_dead,0
    InitSpinlock ds:sd_spinlock
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
;
    mov esi,OFFSET get_com_par
    mov edi,OFFSET get_com_par_name
    xor dx,dx
    mov ax,get_usb_bus_par_nr
    RegisterBimodalUserGate
    clc
    ret
Init    Endp
        
code    ENDS

    END Init
