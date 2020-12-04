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
; USB.ASM
; USB support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc
INCLUDE ..\wait.inc
INCLUDE usb.inc
INCLUDE ..\os\memblk.inc
INCLUDE usbdev.inc
INCLUDE ..\os\chandle.inc

MAX_ATTACH_HOOKS = 32
MAX_DETACH_HOOKS = 32

GET_STATUS = 0
CLEAR_FEATURE = 1
SET_FEATURE = 3
SET_ADDRESS = 5
GET_DESCR = 6
SET_DESCR = 7
GET_CONFIG = 8
SET_CONFIG = 9
GET_INTERFACE = 10
SET_INTERFACE = 11
SYNC_FRAME = 12

usbdev_handle_struc    STRUC

udh_base        handle_header <>
udh_dev_sel     DW ?

usbdev_handle_struc    ENDS

usbdev_dev_struc    STRUC

udd_sel          DW ?
udd_ref_count    DW ?
udd_section      section_typ <>
udd_controller   DW ?
udd_port         DB ?
udd_deleted      DB ?

usbdev_dev_struc    ENDS

pipe_wait_header    STRUC

pw_obj           wait_obj_header <>
pw_handle_sel    DW ?
pw_pipe          DB ?

pipe_wait_header    ENDS

data    SEGMENT byte public 'DATA'

usb_enum_section    section_typ <>
usb_over_current    DW ?
usb_reset_failure   DW ?

usb_func_count      DW ?
usb_func_arr        DW 256 DUP(?)

usb_attach_hooks    DW ?
usb_attach_arr      DD 2 * MAX_ATTACH_HOOKS DUP(?)

usb_detach_hooks    DW ?
usb_detach_arr      DD 2 * MAX_DETACH_HOOKS DUP(?)

data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendDevControlMsg
;
;       description:    Send control msg to device
;
;       parameters:     DS        Usb function
;                       ES        Usb device
;                       AL        Msg
;                       AH        Type
;                       BX        Index
;                       CX        Size
;                       DX        Value
;                       GS:EDI    Buffer
;
;       RETURNS:        CX        Transfer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendDevControlMsg    Proc near
    push fs
    push esi
;
    mov si,OFFSET usbd_control_buf
    mov es:[si].usd_type,ah
    mov es:[si].usd_req,al
    mov es:[si].usd_value,dx
    mov es:[si].usd_index,bx
    mov es:[si].usd_len,cx
    call fword ptr ds:control_msg_proc    
;
    pop esi
    pop fs
    ret
SendDevControlMsg    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       OpenUsbDev
;
;       description:    Open USB device
;
;       parameters:     BX      Controller #
;                       AL      Port
;
;       RETURNS:        BX      USB device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_usb_dev_name DB 'Open USB Device', 0

open_usb_dev    Proc far
    push ds
    push es
    push ax
    push cx
    push dx
    push si
;
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_func_count
    cmp bx,si
    jae oudvFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_func_arr
    or si,si
    jz oudvFail
;
    mov es,si
    cmp al,MAX_USB_HUB_PORTS
    jae oudvFail
;    
    movzx si,al
    add si,si
    mov si,es:[si].usb_handle_arr
    or si,si
    jz oudvFail
;
    mov ds,si
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    jnz oudvLeaveFail
;
    lock add ds:udd_ref_count,1
    LeaveSection ds:udd_section
;
    mov ax,ds
    mov cx,SIZE usbdev_handle_struc
    AllocateHandle
    mov [ebx].udh_dev_sel,ax
    mov [ebx].hh_sign,USB_DEV_HANDLE
    mov bx,[ebx].hh_handle
    clc
    jmp oudvDone    

oudvLeaveFail:
    LeaveSection ds:udd_section

oudvFail:
    xor bx,bx
    stc

oudvDone:
    pop si
    pop dx
    pop cx
    pop ax
    pop es
    pop ds
    retf32
open_usb_dev    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CloseUsbDev
;
;           DESCRIPTION:    Close a USB device handle
;
;           PARAMETERS:         BX          Device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_usb_dev_name     DB 'Close USB Device',0

close_usb_dev  Proc far
    push ds
    push es
    push ax
    push ebx
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc cudvDone
;
    mov es,ds:[ebx].udh_dev_sel
    lock sub es:udd_ref_count,1
    jnz cudvFreeHandle
;
    FreeMem

cudvFreeHandle:
    FreeHandle
    clc

cudvDone:
    pop ebx
    pop ax
    pop es
    pop ds
    retf32
close_usb_dev  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetUsbDevSel
;
;           DESCRIPTION:    Get USB device selector from handle
;
;           PARAMETERS:     BX          Device handle
;
;           RETURNS:        ES          Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_dev_sel_name     DB 'Get USB Device Sel',0

get_usb_dev_sel  Proc far
    push ds
    push ax
    push ebx
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc gudsDone
;
    mov es,ds:[ebx].udh_dev_sel
    clc

gudsDone:
    pop ebx
    pop ax
    pop ds
    retf32
get_usb_dev_sel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:       OpenUsbDevSel
;
;       description:    Open usb device through selector
;
;       parameters:     ES      Sel
;
;       RETURNS:        BX      USB device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_usb_dev_sel_name DB 'Open USB Device Sel', 0

open_usb_dev_sel    Proc far
    push ds
    push ax
    push cx
    push dx
    push si
;
    mov ax,es
    mov ds,ax
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    jnz oudsLeaveFail
;
    lock add ds:udd_ref_count,1
    LeaveSection ds:udd_section
;
    mov ax,ds
    mov cx,SIZE usbdev_handle_struc
    AllocateHandle
    mov [ebx].udh_dev_sel,ax
    mov [ebx].hh_sign,USB_DEV_HANDLE
    mov bx,[ebx].hh_handle
    clc
    jmp oudsDone    

oudsLeaveFail:
    LeaveSection ds:udd_section
    stc

oudsDone:
    pop si
    pop dx
    pop cx
    pop ax
    pop ds
    retf32
open_usb_dev_sel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ResetUsbDevice
;
;       DESCRIPTION:    Reset USB device
;
;       PARAMETERS:     BX      Device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_usb_dev_name  DB 'Reset USB Device',0

reset_usb_dev     Proc far
    push ds
    push es
    push ax
    push ebx
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc rdvDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz rdvLeave
;
    push ds
    mov es,ds:udd_sel    
    mov ds,es:usbd_func_sel
    call fword ptr ds:reset_dev_proc
    pop ds

rdvLeave:
    LeaveSection ds:udd_section

rdvDone:
    pop ebx
    pop ax
    pop es
    pop ds
    retf32
reset_usb_dev     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AdvanceUsbRead
;
;       description:    Advance USB read ptr
;
;       parameters:     DS        Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

advance_usb_read_name DB 'Advance USB Read ptr', 0

advance_usb_read    Proc far
    push ebx
    push esi
;
    RequestSpinlock ds:usbdp_spinlock
;
    mov bx,ds:usbdp_rd_ptr
    inc bx
    cmp bx,ds:usbdp_entry_count
    jb aurSave
;
    xor bx,bx

aurSave:
    lock and ds:usbdp_flags,NOT USB_PIPE_FLAG_FULL
    mov ds:usbdp_rd_ptr,bx
    cmp bx,ds:usbdp_wr_ptr
    jne aurRel
;
    lock or ds:usbdp_flags,USB_PIPE_FLAG_EMPTY

aurRel:
    ReleaseSpinlock ds:usbdp_spinlock
;
    xor bx,bx
    xchg bx,ds:usbdp_wait
    or bx,bx
    jz aurDone
;
    push es
    mov es,bx
    SignalWait
    pop es

aurDone:
    pop esi
    pop ebx
    retf32
advance_usb_read	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AdvanceUsbWrite
;
;       description:    Advance USB write ptr
;
;       parameters:     DS        Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

advance_usb_write_name DB 'Advance USB Write ptr', 0

advance_usb_write    Proc far
    push ebx
    push esi
;
    RequestSpinlock ds:usbdp_spinlock
;
    mov bx,ds:usbdp_wr_ptr
    inc bx
    cmp bx,ds:usbdp_entry_count
    jb auwSave
;
    xor bx,bx

auwSave:
    lock and ds:usbdp_flags,NOT USB_PIPE_FLAG_EMPTY
    mov ds:usbdp_wr_ptr,bx
    cmp bx,ds:usbdp_rd_ptr
    jne auwRel
;
    lock or ds:usbdp_flags,USB_PIPE_FLAG_FULL

auwRel:
    ReleaseSpinlock ds:usbdp_spinlock
;
    xor bx,bx
    xchg bx,ds:usbdp_wait
    or bx,bx
    jz auwDone
;
    push es
    mov es,bx
    SignalWait
    pop es

auwDone:
    pop esi
    pop ebx
    retf32
advance_usb_write	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendUsbDevControlMsg
;
;       description:    Send control msg to USB device
;
;       parameters:     BX        Handle
;                       AL        Msg
;                       AH        Type
;                       DX        Value
;                       SI        Index
;                       CX        Size
;                       ES:(E)DI  Buffer
;
;       RETURNS:        CX        Transfer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_usb_dev_control_msg_name DB 'Send Device Control Msg', 0

send_usb_dev_control_msg    Proc near
    push ds
    push es
    push gs
    push ebx
    push esi
;
    push ax
    mov ax,USB_DEV_HANDLE
    DerefHandle
    pop ax
    jc sudcmDone
;
    push ax
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    pop ax
    stc
    jnz sudcmLeave
;
    push ds
;
    mov bx,es
    mov gs,bx
    mov es,ds:udd_sel    
;
    mov bx,OFFSET usbd_control_buf
    mov es:[bx].usd_type,ah
    mov es:[bx].usd_req,al
    mov es:[bx].usd_value,dx
    mov es:[bx].usd_index,si
    mov es:[bx].usd_len,cx
    mov ds,es:usbd_func_sel
    call fword ptr ds:control_msg_proc    
;
    pop ds

sudcmLeave:
    LeaveSection ds:udd_section

sudcmDone:
    pop esi
    pop ebx
    pop gs
    pop es
    pop ds
    ret
send_usb_dev_control_msg    Endp

send_usb_dev_control_msg16    Proc far
    push edi
    movzx edi,di
    call send_usb_dev_control_msg
    pop edi
    retf32
send_usb_dev_control_msg16      Endp

send_usb_dev_control_msg32    Proc far
    call send_usb_dev_control_msg
    retf32
send_usb_dev_control_msg32      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ConfigUsbPipe
;
;       description:    Configure USB pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;                       CX        Buffer entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

config_usb_pipe_name DB 'Configure Usb Pipe', 0

config_usb_pipe	Proc far
    push ds
    push es
    push gs
    pushad
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc cdpDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz cdpLeaveFail
;
    mov es,ds:udd_sel    
    mov ax,es:usbd_curr_config
    or ax,ax
    jz cdpLeaveFail
;
    mov gs,ax
    xor edi,edi
    movzx bx,gs:ucd_len
    add di,bx

cdpDescrLoop:
    mov al,gs:[di].udd_type
    cmp al,5
    jne cdpNextDescr
;
    cmp dl,gs:[di].ued_address
    jne cdpNextDescr
;
    mov al,gs:[di].ued_attrib
    and al,3
    cmp al,2
    je cdpBulk
;
    cmp al,3
    jne cdpLeaveFail

cdpIntr:
    mov dh,gs:[di].ued_interval
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:create_intr_pipe_proc
    pop ds
    jmp cdpSave

cdpBulk:
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:create_bulk_pipe_proc
    pop ds

cdpSave:
    push es
    mov es,bx
;
    mov es:usbdp_flags,USB_PIPE_FLAG_EMPTY
    mov es:usbdp_rd_ptr,0
    mov es:usbdp_wr_ptr,0
    mov es:usbdp_wait,0
    InitSpinlock es:usbdp_spinlock
;
    mov si,di
    mov di,OFFSET usbdp_descr
    mov cx,SIZE usb_endpoint_descr
    rep movs es:[di],gs:[si]
;
    pop es
;
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
;
    test dl,80h
    jz cdpOut

cdpIn:
    mov es:[si].usbd_in_pipe_arr,bx
    jmp cdpLeave

cdpOut:
    mov es:[si].usbd_out_pipe_arr,bx

cdpLeave:
    clc
    LeaveSection ds:udd_section
    jmp cdpDone

cdpNextDescr:
    movzx bx,gs:[di].ucd_len
    or bx,bx
    jz cdpLeaveFail
;
    add di,bx
    cmp di,gs:ucd_size
    jb cdpDescrLoop    

cdpLeaveFail:
    LeaveSection ds:udd_section
    stc

cdpDone:
    popad
    pop gs
    pop es
    pop ds    
    retf32
config_usb_pipe Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EnableUsbPipe
;
;       description:    Enable USB pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_usb_pipe_name DB 'Enable Usb Pipe', 0

enable_usb_pipe	Proc far
    push ds
    push es
    push gs
    push eax
    push ebx
    push esi
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc edpDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz edpLeave
;
    mov es,ds:udd_sel    
;
    test dl,80h
    jnz edpIn

edpOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_out_pipe_arr
    or bx,bx
    stc
    jz edpLeave
;
    mov gs,bx
    test gs:usbdp_flags,USB_PIPE_FLAG_ENABLED
    clc
    jnz edpDone
;
    lock or gs:usbdp_flags,USB_PIPE_FLAG_ENABLED
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:enable_pipe_proc
    pop ds
    jmp edpLeave

edpIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_in_pipe_arr
    or bx,bx
    stc
    jz edpLeave
;
    mov gs,bx
    test gs:usbdp_flags,USB_PIPE_FLAG_ENABLED
    clc
    jnz edpLeave
;
    lock or gs:usbdp_flags,USB_PIPE_FLAG_ENABLED
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:enable_pipe_proc
    pop ds

edpLeave:
    LeaveSection ds:udd_section

edpDone:
    pop esi
    pop ebx
    pop eax
    pop gs
    pop es
    pop ds    
    retf32
enable_usb_pipe Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisableUsbPipe
;
;       description:    Disable USB pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_usb_pipe_name DB 'Disable Usb Pipe', 0

disable_usb_pipe	Proc far
    push ds
    push es
    push gs
    push eax
    push ebx
    push esi
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc ddpDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz ddpLeave
;
    mov es,ds:udd_sel    
;
    test dl,80h
    jnz ddpIn

ddpOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_out_pipe_arr
    or bx,bx
    stc
    jz ddpLeave
;
    mov gs,bx
    test gs:usbdp_flags,USB_PIPE_FLAG_ENABLED
    clc
    jz ddpLeave
;
    lock and gs:usbdp_flags,NOT USB_PIPE_FLAG_ENABLED
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:disable_pipe_proc
    pop ds
    jmp ddpLeave

ddpIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_in_pipe_arr
    or bx,bx
    stc
    jz ddpLeave
;
    mov gs,bx
    test gs:usbdp_flags,USB_PIPE_FLAG_ENABLED
    clc
    jz ddpLeave
;
    lock and gs:usbdp_flags,NOT USB_PIPE_FLAG_ENABLED
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:disable_pipe_proc
    pop ds

ddpLeave:
    LeaveSection ds:udd_section

ddpDone:
    pop esi
    pop ebx
    pop eax
    pop gs
    pop es
    pop ds    
    retf32
disable_usb_pipe Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForPipe
;
;           DESCRIPTION:    Start a wait for pipe
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_pipe     PROC far
    push ds
    push fs
    push gs
    pushad
;
    mov dl,es:pw_pipe
    mov ds,es:pw_handle_sel
    EnterSection ds:udd_section
    mov bx,es
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz bwfpLeaveSignal
;
    mov es,ds:udd_sel    
;
    mov ax,flat_sel
    mov fs,ax
;
    test dl,80h
    jnz bwfpIn

bwfpOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov si,es:[si].usbd_out_pipe_arr
    or si,si
    jz bwfpLeaveSignal
;
    mov gs,si
    test gs:usbdp_flags,USB_PIPE_FLAG_ENABLED
    jz bwfpLeaveSignal
;
    mov gs:usbdp_wait,bx
    test gs:usbdp_flags,USB_PIPE_FLAG_FULL
    jnz bwfpLeave
    jmp bwfpCheckSignal

bwfpIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov si,es:[si].usbd_in_pipe_arr
    or si,si
    jz bwfpLeaveSignal
;
    mov gs,si
    test gs:usbdp_flags,USB_PIPE_FLAG_ENABLED
    jz bwfpLeaveSignal
;
    mov gs:usbdp_wait,bx
    test gs:usbdp_flags,USB_PIPE_FLAG_EMPTY
    jnz bwfpLeave

bwfpCheckSignal:
    xor bx,bx
    xchg bx,gs:usbdp_wait
    or bx,bx
    jz bwfpLeave

bwfpLeaveSignal:
    push es    
    mov es,bx
    SignalWait
    pop es

bwfpLeave:
    LeaveSection ds:udd_section
;
    popad
    pop gs
    pop fs
    pop ds
    retf32
start_wait_for_pipe Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForPipe
;
;           DESCRIPTION:    Stop a wait for pipe
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_pipe      PROC far
    push ax
    push dx
;
    mov dl,es:pw_pipe
    mov ds,es:pw_handle_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz ewfpLeave

ewfpLeave:
    LeaveSection ds:udd_section

ewfpDone:
    pop dx
    pop ax
    retf32
stop_wait_for_pipe Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearWaitForPipe
;
;           DESCRIPTION:    Clear wait for pipe
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_wait_for_pipe     PROC far
    push ds
    push fs
    push gs
    pushad
;
    mov dl,es:pw_pipe
    mov ds,es:pw_handle_sel
    EnterSection ds:udd_section
    mov bx,es
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz cwfpLeave
;
    mov es,ds:udd_sel    
;
    mov ax,flat_sel
    mov fs,ax
;
    test dl,80h
    jnz cwfpIn

cwfpOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov si,es:[si].usbd_out_pipe_arr
    or si,si
    jz cwfpLeave
;
    mov gs,si
    mov gs:usbdp_wait,0
    jmp cwfpLeave

cwfpIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov si,es:[si].usbd_in_pipe_arr
    or si,si
    jz cwfpLeave
;
    mov gs,si
    mov gs:usbdp_wait,0

cwfpLeave:
    LeaveSection ds:udd_section
;
    popad
    pop gs
    pop fs
    pop ds
    retf32
clear_wait_for_pipe Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsPipeIdle
;
;           DESCRIPTION:    Check if pipe is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_pipe_idle    PROC far
    retf32
is_pipe_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           DeleteWaitPipe
;
;           DESCRIPTION:    Decrease lock
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_wait_pipe    PROC far
    push ds
    push es
;
    mov ds,es:pw_handle_sel
    lock sub ds:udd_ref_count,1
    jnz dwpDone
;
    push es
    mov es,es:pw_handle_sel
    FreeMem
    pop es

dwpDone:
    pop es
    pop ds
    retf32
delete_wait_pipe Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForPipe
;
;           DESCRIPTION:    Add a wait for pipe
;
;           PARAMETERS:     BX      Wait handle
;                           AX      Device handle
;                           DL      Pipe #
;                           ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_dev_pipe_name  DB 'Add Wait For Dev Pipe',0

add_wait_tab:
aw0 DD OFFSET start_wait_for_pipe,      SEG code
aw1 DD OFFSET stop_wait_for_pipe,       SEG code
aw2 DD OFFSET clear_wait_for_pipe,      SEG code
aw3 DD OFFSET is_pipe_idle,             SEG code
aw4 DD OFFSET delete_wait_pipe,         SEG code

add_wait_for_dev_pipe       PROC far
    push ds
    pushad
;
    mov bp,bx
    mov bx,ax
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc awpDone
;
    mov si,ds:[ebx].udh_dev_sel
    mov ds,si
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz awpLeave
;
    lock add ds:udd_ref_count,1
;
    mov bx,bp
    mov ax,cs
    mov es,ax
    mov ax,SIZE pipe_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_tab
    AddWaitDelete
    jnc awpSave
;
    lock sub ds:udd_ref_count,1
    stc
    jmp awpLeave

awpSave:
    mov es:pw_handle_sel,si
    mov es:pw_pipe,dl
    clc

awpLeave:
    LeaveSection ds:udd_section

awpDone:
    popad
    pop ds
    retf32
add_wait_for_dev_pipe       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_dev_handle
;
;           DESCRIPTION:    BX              USB dev handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_dev_handle   Proc far
    push ds
    push es
    push ebx
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc ddhDone
;
    mov es,ds:[ebx].udh_dev_sel
    lock sub es:udd_ref_count,1
    jnz ddhFreeHandle
;
    FreeMem

ddhFreeHandle:
    FreeHandle
    clc

ddhDone:
    pop ebx
    pop es
    pop ds
    retf32
delete_dev_handle   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitUsbFunction
;
;           description:    Init USB function selector
;
;       parameters:     DS      USB function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_usb_function_name DB 'Init USB Function', 0

init_usb_function Proc far
    push ds
    push es
    push ax
    push bx
    push cx
    push di
;
    InitSection ds:usb_section
    mov ax,ds
    mov es,ax
;
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usb_dev_arr
    xor ax,ax
    rep stosw
;
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usb_thread_arr
    xor ax,ax
    rep stosw
;
    mov cx,MAX_USB_HUB_PORTS
    mov di,OFFSET usb_handle_arr
    xor ax,ax
    rep stosw
;
    mov cx,127
    mov di,OFFSET usb_linear_dev_arr
    xor eax,eax
    rep stosd
;
    mov eax,1
    mov di,OFFSET usb_addr_bitmap
    stosd
    xor eax,eax
    stosd
    stosd
    stosd
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:usb_func_count
    mov es:usb_controller_id,bx
    mov es:usb_hub_id,0
    mov es:usb_route_depth,0
    mov es:usb_route_str,0
    add bx,bx
    mov ds:[bx].usb_func_arr,es
    inc ds:usb_func_count
;
    pop di
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
    retf32
init_usb_function   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TrapUsbAttach
;
;           DESCRIPTION:    Run notification handlers for attach
;
;           PARAMETERS:     BX      Controller #
;                           AH      Port #
;                           AL      Device address (1..128)
;                           DS      USB function
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_usb_attach PROC near
    push ds
    push es
    push cx
    push si
;       
    mov cx,SEG data
    mov es,cx
    mov cx,es:usb_attach_hooks
    or cx,cx
    je trap_attach_done
    
    mov si,OFFSET usb_attach_arr

trap_attach_loop:
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    call fword ptr es:[si]
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
;       
    add si,8
    loop trap_attach_loop

trap_attach_done:
    pop si
    pop cx
    pop es
    pop ds
    ret
trap_usb_attach ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           TrapUsbDetach
;
;           DESCRIPTION:    Run notification handlers for detach
;
;           PARAMETERS:     BX      Controller #
;                           AH      Port #
;                           AL      Device address (1..128)
;                           DS      USB function
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

trap_usb_detach PROC near
    push ds
    push es
    push cx
    push si
;       
    mov cx,SEG data
    mov es,cx
    mov cx,es:usb_detach_hooks
    or cx,cx
    je trap_detach_done
    
    mov si,OFFSET usb_detach_arr

trap_detach_loop:
    push ds
    push es
    push ax
    push bx
    push cx
    push si
    call fword ptr es:[si]
    pop si
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
;       
    add si,8
    loop trap_detach_loop

trap_detach_done:
    pop si
    pop cx
    pop es
    pop ds
    ret
trap_usb_detach ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockUsb
;
;           description:    Lock USB (for RESET)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

lock_usb_name DB 'Lock USB', 0

lock_usb       Proc far
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:usb_enum_section
    pop ax
    pop ds
    retf32
lock_usb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockUsb
;
;           description:    Unlock USB (for RESET)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlock_usb_name DB 'Unlock USB', 0

unlock_usb       Proc far
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:usb_enum_section
    pop ax
    pop ds
    retf32
unlock_usb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateUsbAddress
;
;       Description:    Allocate USB address
;
;       PARAMETERS:     DS      Function sel
;
;       RETURNS:        AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

allocate_usb_address_name DB 'Allocate USB Address', 0

allocate_usb_address       Proc far
    push ebx
    push ecx
    push esi

auaRetry:
    mov si,OFFSET usb_addr_bitmap
    xor al,al
    mov cx,4

auaLoop:
    mov ebx,ds:[si]
    cmp ebx,-1
    je auaNext
;
    not ebx
    bsf ecx,ebx
    add al,cl
    jmp auaTake

auaNext:
    add al,32
    add si,4
    loop auaNext
;
    stc
    jmp auaDone

auaTake:
    movzx eax,al
    bts ds:usb_addr_bitmap,eax
    jc auaRetry

auaDone:
    pop esi
    pop ecx
    pop ebx
    retf32
allocate_usb_address      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeUsbAddress
;
;       Description:    Free USB address
;
;       PARAMETERS:     DS      Function sel
;                       AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_usb_address_name DB 'Free USB Address', 0

free_usb_address       Proc far
    push eax
    movzx eax,al
    btc ds:usb_addr_bitmap,eax
    cmc
    pop eax
    retf32
free_usb_address       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddressUsbDevice
;
;       Description:    Address usb device
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

address_usb_dev_name DB 'Address USB Device', 0

address_usb_dev       Proc far
    pushad
;
    mov di,OFFSET usbd_control_buf
    movzx ax,al
    mov es:[di].usd_type,0
    mov es:[di].usd_req,SET_ADDRESS
    mov es:[di].usd_value,ax
    mov es:[di].usd_index,0
    mov es:[di].usd_len,0
    call fword ptr ds:control_msg_proc
;
    popad
    retf32
address_usb_dev       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitUsbDev
;
;       Description:    Init usb device
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       AL      Address
;                       AH      Speed
;                       BX      Hub selector
;                       DX      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_usb_dev_name DB 'Init USB Device', 0

init_usb_dev       Proc far
    pusha
;
    mov es:usbd_func_sel,ds
    mov es:usbd_hub_sel,bx
    mov es:usbd_port,dl
    mov es:usbd_address,al
    mov es:usbd_speed,ah
    mov es:usbd_flags,0
    mov es:usbd_maxlen,8
    mov es:usbd_curr_config,0
;
    dec al
    movzx di,al
    shl di,2
    mov edx,es:mblk_linear_base
    mov ds:[di].usb_linear_dev_arr,edx
;
    xor ax,ax
    mov cx,15
    mov di,OFFSET usbd_in_pipe_arr
    rep stosw
;
    mov cx,15
    mov di,OFFSET usbd_out_pipe_arr
    rep stosw
;
    or bx,bx
    jz usdNoHub
;
    mov es:usbd_func_sel,bx

usdNoHub:
    popa
    retf32
init_usb_dev       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeUsbDev
;
;       Description:    Free usb device
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_usb_dev_name DB 'Free USB Device', 0

free_usb_dev       Proc far
    pushad
;    
    mov al,es:usbd_address
    call fword ptr ds:free_address_proc
;
    mov cx,16
    mov bx,OFFSET usbd_config_sel

fudConfLoop:
    mov ax,es:[bx]
    or ax,ax
    jz fudConfNext
;
    push es
    mov es,ax
    FreeMem
    pop es

fudConfNext:
    add bx,2
    loop fudConfLoop    
;
    mov ax,10
    WaitMilliSec
;
    mov al,es:usbd_address
    dec al
    movzx di,al
    shl di,2
    mov ds:[di].usb_linear_dev_arr,0
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

fudInLoop:
    mov bx,es:[si]
    or bx,bx
    jz fudInNext
;
    push es
    mov es,bx
    FreeMem
    pop es

fudInNext:
    add si,2
    loop fudInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

fudOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz fudOutNext
;
    push es
    mov es,bx
    FreeMem
    pop es

fudOutNext:
    add si,2
    loop fudOutLoop
;
    mov ax,10
    WaitMilliSec
;
    FreeMemBlk
;
    popad
    retf32
free_usb_dev       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddUsbDevice
;
;       Description:    Add USB device
;
;       Parameters:     DS      USB function selector
;                       ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_usb_device_name DB 'Add USB Device', 0

add_usb_device       Proc far
    push ds
    push es
    push fs
    pushad
;
    mov eax,es
    mov fs,eax
;
    mov eax,SIZE usbdev_dev_struc
    AllocateSmallGlobalMem
;
    mov ax,ds:usb_controller_id
    mov es:udd_controller,ax
;
    mov al,fs:usbd_port
    mov es:udd_port,al
;
    mov fs:usbd_dev_sel,es
    mov es:udd_sel,fs
    mov es:udd_deleted,0
    mov es:udd_ref_count,1
    InitSection es:udd_section
;
    movzx bx,al
    add bx,bx
    mov ds:[bx].usb_handle_arr,es
    mov ds:[bx].usb_dev_arr,fs
;
    popad
    pop fs
    pop es
    pop ds
    retf32
add_usb_device  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadUsbDescriptors
;
;       Description:    Read USB descriptors
;
;       Parameters:     DS      USB function selector
;                       ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_usb_descriptors_name DB 'Read USB Descriptors', 0

read_usb_descriptors       Proc far
    push gs
    push es
    pushad
;
    mov ax,es
    mov gs,ax
    mov edi,OFFSET usbd_device_descr
    mov si,OFFSET usbd_control_buf
    mov es:[si].usd_type,80h
    mov es:[si].usd_req,GET_DESCR
    mov es:[si].usd_value,100h
    mov es:[si].usd_index,0
    mov es:[si].usd_len,8
    call fword ptr ds:control_msg_proc
    jc rudDone
;
    cmp cx,8
    stc
    jnz rudDone
;
    movzx ax,es:[di].udd_maxlen
    or ax,ax
    stc
    jz rudDone
;
    cmp ax,es:usbd_maxlen
    je rudLenOk
;    
    mov es:usbd_maxlen,ax
    call fword ptr ds:update_control_maxlen_proc

rudLenOk:
    movzx eax,es:[di].udd_len
    cmp ax,18
    stc
    jne rudDone
;
    mov es:[si].usd_len,ax
    call fword ptr ds:control_msg_proc
    jc rudDone
;
    cmp ax,18
    stc
    jnz rudDone
;
    mov bh,-1
    xor bl,bl

rudLoop:
    mov ax,es
    mov gs,ax
    mov edi,OFFSET usbd_temp_buf
;
    mov al,bl
    mov ah,2
    mov es:[si].usd_type,80h
    mov es:[si].usd_req,GET_DESCR
    mov es:[si].usd_value,ax
    mov es:[si].usd_index,0
    mov es:[si].usd_len,8
    call fword ptr ds:control_msg_proc
    jnc rudGetFull
;
    or bx,bx
    stc
    jz rudDone
;
    clc
    jmp rudDone

rudGetFull:
    mov al,es:[di].ucd_config_id
    cmp al,bh
    clc
    je rudDone
;
    mov bh,al
    mov cx,es:[di].ucd_size
;
    push es
    movzx eax,cx
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
    xor edi,edi
    pop es
;
    mov es:[si].usd_len,cx
    call fword ptr ds:control_msg_proc
    jnc rudSave
;
    push es
    mov ax,gs
    mov es,ax
    xor ax,ax
    mov gs,ax
    FreeMem
    pop es
    stc
    jmp rudDone

rudSave:
    movzx di,bl
    add di,di
    mov es:[di].usbd_config_sel,gs
    inc bl
    jmp rudLoop

rudDone:
    popad
    pop es
    pop gs
    retf32
read_usb_descriptors   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NotifyUsbAttach
;
;       Description:    Notify USB attach event
;
;       Parameters:     DS      USB function selector
;                       ES      USB device selector
;                       FS      Control pipe
;                       AL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_usb_attach_name DB 'Notify USB Attach', 0

attach_text DB 'Attach', 0

notify_usb_attach       Proc far
    push es
    pushad
;
    mov bx,ds:usb_controller_id
    call trap_usb_attach
    clc
;
    popad
    pop es
    retf32
notify_usb_attach   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlinkUsbDevice
;
;           description:    Unlink USB device
;
;       parameters:         DS      USB function selector
;                           ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

unlink_usb_dev_name DB 'Unlink USB Device', 0

unlink_usb_dev       Proc far
    pushad
;
    lock or es:usbd_flags,FLAG_DETACHED
    movzx bx,es:usbd_port
    add bx,bx
    xor ax,ax
    mov ds:[bx].usb_dev_arr,ax
    xchg ax,ds:[bx].usb_handle_arr
    or ax,ax
    jz uudDone
;
    push ds
    mov ds,ax
    mov ds:udd_deleted,1
    EnterSection ds:udd_section
    LeaveSection ds:udd_section
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

uudInLoop:
    mov bx,es:[si]
    or bx,bx
    jz uudInNext
;
    push es
    mov es,bx
    xor bx,bx
    xchg bx,es:usbdp_wait
    or bx,bx
    jz uudInPop
;
    mov es,bx
    SignalWait

uudInPop:
    pop es

uudInNext:
    add si,2
    loop uudInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

uudOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz uudOutNext
;
    push es
    mov es,bx
    xor bx,bx
    xchg bx,es:usbdp_wait
    or bx,bx
    jz uudOutPop
;
    mov es,bx
    SignalWait

uudOutPop:
    pop es

uudOutNext:
    add si,2
    loop uudOutLoop
;
    lock sub ds:udd_ref_count,1
    pop ds
    jnz uudDone
;
    push es
    mov es,ax
    FreeMem
    pop es

uudDone:
    call fword ptr ds:unlink_proc
;
    popad
    retf32
unlink_usb_dev     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyUsbDetach
;
;           description:    Notify USB detach event
;
;       parameters:         AL      Usb port
;                           DS      USB function selector
;                           ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_usb_detach_name DB 'Notify USB Detach', 0

notify_usb_detach       Proc far
    push es
    pushad
; 
    mov bx,ds:usb_controller_id
    call trap_usb_detach      

nudDone:    
    popad
    pop es
    retf32
notify_usb_detach   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               GetUsbHubDescriptor
;
;       description:        Get USB hub descriptor
;
;       parameters:         BX       Controller #
;                           AL       Device port #
;                           CX       Buffer size
;                           ES:EDI   Buffer
;
;       Returns:            AX       Size of descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_hub_descr_name DB 'Get USB Hub Descriptor', 0

get_hub_descr  Proc near
    push ds
    push es
    push gs
    push ebx
    push esi
;
    mov si,es
    mov gs,si
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_func_count
    cmp bx,si
    jae ghdFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_func_arr
    or si,si
    jz ghdFail
;
    mov ds,si
    cmp al,MAX_USB_HUB_PORTS
    jae ghdFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz ghdFail
;
    mov es,si
    mov si,OFFSET usbd_control_buf
    mov es:[si].usd_type,0A0h
    mov es:[si].usd_req,GET_DESCR
    mov es:[si].usd_value,2900h
    mov es:[si].usd_index,0
    mov es:[si].usd_len,cx
    call fword ptr ds:control_msg_proc    
    jc ghdFail
;
    mov ax,cx
    clc
    jmp ghdDone

ghdFail:
    xor ax,ax
    stc

ghdDone:        
    pop esi
    pop ebx
    pop gs
    pop es
    pop ds
    retf32
get_hub_descr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetUsbDevice
;
;       description:    Get USB device descriptor
;
;       parameters:     BX      Controller #
;                       AL      Port #
;                       (E)CX       Buffer size
;                       ES:(E)DI    Buffer
;
;       Returns:    (E)AX       Size of descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_device_name DB 'Get USB Device', 0

get_usb_device  Proc near
    push ds
    push esi
;
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_func_count
    cmp bx,si
    jae gudFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_func_arr
    or si,si
    jz gudFail
;
    mov ds,si
    cmp al,MAX_USB_HUB_PORTS
    jae gudFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz gudFail
;
    push ecx
    push edi
;
    mov ds,si
    mov esi,OFFSET usbd_device_descr
    movzx ax,ds:[si].udd_len
    cmp cx,ax
    jbe gudCopy
;
    mov cx,ax

gudCopy:
    movzx ecx,cx
    mov eax,ecx
    rep movs byte ptr es:[edi],ds:[esi]    
;
    pop edi
    pop ecx
    clc
    jmp gudDone

gudFail:
    xor eax,eax    
    stc

gudDone:        
    pop esi
    pop ds
    ret
get_usb_device  Endp

get_usb_device32:
    call get_usb_device
    retf32

get_usb_device16    Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_usb_device
;
    pop edi
    pop ecx
    retf32
get_usb_device16    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetUsbConfig
;
;           description:    Get USB config descriptor
;
;       parameters:     BX      Controller #
;                       AL      Port #
;                       DL      Config #
;                       (E)CX       Buffer size
;                       ES:(E)DI    Buffer
;
;       Returns:    (E)AX       Size of descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_config_name DB 'Get USB Config', 0

get_usb_config  Proc near
    push ds
    push esi
;
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_func_count
    cmp bx,si
    jae gucFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_func_arr
    or si,si
    jz gucFail
;
    mov ds,si
    cmp al,MAX_USB_HUB_PORTS
    jae gucFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz gucFail
;
    cmp dl,16
    jae gucFail
;    
    mov ds,si
    movzx si,dl
    add si,si
    mov si,ds:[si].usbd_config_sel
    or si,si
    jz gucFail
;
    push ecx
    push edi
;
    mov ds,si
    xor esi,esi
    mov ax,ds:ucd_size
    cmp cx,ax
    jbe gucCopy
;
    mov cx,ax

gucCopy:
    movzx ecx,cx
    mov eax,ecx
    rep movs byte ptr es:[edi],ds:[esi]    
;
    pop edi
    pop ecx
    clc
    jmp gucDone

gucFail:
    xor eax,eax    
    stc

gucDone:        
    pop esi
    pop ds
    ret
get_usb_config  Endp

get_usb_config32:
    call get_usb_config
    retf32

get_usb_config16    Proc far
    push ecx
    push edi
;
    movzx ecx,cx
    movzx edi,di
    call get_usb_config
;
    pop edi
    pop ecx
    retf32
get_usb_config16    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ConfigUsb
;
;       description:    Configure USB
;
;       parameters:     BX      Controller #
;                       AL      Port #
;                       CX      Hub sel
;                       DL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigUsb      Proc near
    push ds
    push es
    push fs
    push gs
    push ax
    push bx
    push esi
    push edi
    push bp
    push cx
;
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_func_count
    cmp bx,si
    jae cudFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_func_arr
    or si,si
    jz cudFail
;
    mov ds,si
    cmp al,MAX_USB_HUB_PORTS
    jae cudFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz cudFail
;
    mov es,si
    mov cx,16
    xor si,si

cudFindConfigLoop:
    mov ax,es:[si].usbd_config_sel
    or ax,ax
    jz cudFindConfigNext
;
    mov gs,ax
    cmp dl,gs:ucd_config_id
    je cudFindConfigOk

cudFindConfigNext:
    add si,2
    loop cudFindConfigLoop
;
    jmp cudFail

cudFindConfigOk:
    mov di,OFFSET usbd_control_buf
    mov es:[di].usd_type,0
    mov es:[di].usd_req,SET_CONFIG
    movzx ax,dl
    mov es:[di].usd_value,ax
    mov es:[di].usd_index,0
    mov es:[di].usd_len,0
    call fword ptr ds:control_msg_proc
    jc cudFail

cudConfig:
    pop cx
    call fword ptr ds:config_device_proc
    jc cudDone
;
    mov es:usbd_curr_config,gs
    jmp cudDone

cudFail:
    pop cx
    stc
    
cudDone: 
    pop bp
    pop edi
    pop esi
    pop bx
    pop ax
    pop gs
    pop fs
    pop es
    pop ds
    ret
ConfigUsb    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ConfigUsbDevice
;
;       description:    Configure USB device
;
;       parameters:     BX      Controller #
;                       AL      Device address (1..128)
;                       AH      Port
;                       DL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

config_usb_device_name DB 'Config USB Device', 0

config_usb_device       Proc near
    push cx
    xor cx,cx
    call ConfigUsb
    pop cx
    retf32
config_usb_device    Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateRoute
;
;       description:    Create route string
;
;       parameters:     BX      Controller #
;                       AL      Port
;                       CX      Hub sel
;                       DL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRoute      Proc near
    push ds
    push edx
    push esi
;
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_func_count
    cmp bx,si
    jae crrDone
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_func_arr
    or si,si
    jz crrDone
;
    push es
    push eax
    push ecx
;
    mov es,ecx
    mov ds,si
    mov dl,ds:usb_hub_id
    or dl,dl
    jnz crrAdd
;
    inc al
    mov es:usb_root_port,al
    jmp crrPop

crrAdd:
    mov al,ds:usb_root_port
    mov es:usb_root_port,al
;
    mov cl,ds:usb_route_depth
    shl cl,2
    movzx eax,al
    inc eax
    shl eax,cl
    or eax,ds:usb_route_str
    mov es:usb_route_str,eax
;
    shr cl,2
    inc cl
    mov es:usb_route_depth,cl

crrPop:
    pop ecx    
    pop eax
    pop es

crrDone:
    pop esi
    pop edx
    pop ds
    ret
CreateRoute  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ConfigUsbHub
;
;       description:    Configure USB dhub
;
;       parameters:     BX      Controller #
;                       AL      Port #
;                       CX      Hub sel
;                       DL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

config_usb_hub_name DB 'Config USB Hub', 0

config_usb_hub       Proc near
    push ax
    call CreateRoute
    call ConfigUsb
    pop ax
    retf32
config_usb_hub    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HookUsbAttach
;
;           description:    Hook USB attach event
;
;       parameters:     ES:EDI       Callback 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_usb_attach_name DB 'Hook USB Attach', 0

hook_usb_attach Proc far
    push ds
    push bx
;       
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:usb_attach_hooks
    shl bx,3
    add bx,OFFSET usb_attach_arr
    mov [bx],edi
    mov [bx+4],es
    inc ds:usb_attach_hooks
;
    pop bx
    pop ds
    retf32
hook_usb_attach   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HookUsbDetach
;
;           description:    Hook USB detach event
;
;       parameters:     ES:EDI       Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_usb_detach_name DB 'Hook USB Detach', 0

hook_usb_detach Proc far
    push ds
    push bx
;       
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:usb_detach_hooks
    shl bx,3
    add bx,OFFSET usb_detach_arr
    mov [bx],edi
    mov [bx+4],es
    inc ds:usb_detach_hooks
;
    pop bx
    pop ds
    retf32
hook_usb_detach   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetUsbOverCurrent
;
;           description:    Set USB overcurrent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_usb_over_current_name DB 'Set USB Over Current', 0

set_usb_over_current Proc far
    push ds
    push bx
;       
    mov bx,SEG data
    mov ds,bx
    mov ds:usb_over_current,1
;
    pop bx
    pop ds
    retf32
set_usb_over_current   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HasUsbOverCurrent
;
;           description:    Has USB overcurrent
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_usb_over_current_name DB 'Has USB Over Current', 0

has_usb_over_current Proc far
    push ds
    push bx
;       
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:usb_over_current
    or bx,bx
    clc
    jnz huscDone
;
    stc

huscDone:
    pop bx
    pop ds
    retf32
has_usb_over_current   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetUsbResetFailed
;
;           description:    Set USB reset failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_usb_reset_failed_name DB 'Set USB Reset Failed', 0

set_usb_reset_failed Proc far
    push ds
    push bx
;       
    mov bx,SEG data
    mov ds,bx
    mov ds:usb_reset_failure,1
;
    pop bx
    pop ds
    retf32
set_usb_reset_failed   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HasUsbResetFailed
;
;           description:    Has USB reset failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_usb_reset_failed_name DB 'Has USB Reset Failed', 0

has_usb_reset_failed Proc far
    push ds
    push bx
;       
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:usb_reset_failure
    or bx,bx
    clc
    jnz hurfDone
;
    stc

hurfDone:
    pop bx
    pop ds
    retf32
has_usb_reset_failed   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;  obsolete code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_pipe_connected_name DB 'Is Usb Pipe Connected', 0

is_usb_pipe_connected       Proc far
    clc
    retf32
is_usb_pipe_connected       Endp

open_usb_pipe_name DB 'Open USB Pipe', 0

open_usb_pipe    Proc far
    stc
    retf32
open_usb_pipe    Endp

close_usb_pipe_name     DB 'Close USB Pipe',0

close_usb_pipe  Proc far
    retf32
close_usb_pipe  Endp
    
add_wait_for_pipe_name DB 'Add Wait for pipe', 0

add_wait_for_pipe       PROC far
    stc
    retf32
add_wait_for_pipe       ENDP

req_usb_data_name       DB 'Request USB Data',0

req_usb_data    Proc far
    stc
    retf32
req_usb_data    Endp

req_usb_data_no_copy_name       DB 'Request USB Data, No Copy',0

req_usb_data_no_copy    Proc far
    stc
    retf32
req_usb_data_no_copy    Endp

get_usb_data_size_name  DB 'Get USB Data Size',0

get_usb_data_size16     Proc far
    stc
    retf32
get_usb_data_size16     Endp

get_usb_data_size32     Proc far
    stc
    retf32
get_usb_data_size32     Endp

write_usb_data_name     DB 'Write USB Data',0

write_usb_data16    Proc far
    stc
    retf32
write_usb_data16    Endp

write_usb_data32    Proc far
    stc
    retf32
write_usb_data32    Endp

write_usb_data_no_copy_name     DB 'Write USB Data, No Copy',0

write_usb_data_no_copy    Proc far
    stc
    retf32
write_usb_data_no_copy    Endp

start_usb_trans_name    DB 'Start USB Transaction',0

start_usb_trans Proc far
    stc
    retf32
start_usb_trans Endp

is_usb_trans_done_name  DB 'Is USB Transaction Done',0

is_usb_trans_done       Proc far
    stc
    retf32
is_usb_trans_done       Endp

is_usb_connected_name  DB 'Is USB Connected',0

is_usb_connected       Proc far
    stc
    retf32
is_usb_connected       Endp

was_usb_trans_ok_name   DB 'Was USB Transaction Ok',0

was_usb_trans_ok    Proc far
    stc
    retf32
was_usb_trans_ok    Endp

start_one_usb_trans_name   DB 'Start One USB Transaction',0

start_one_usb_trans    Proc far
    stc
    retf32
start_one_usb_trans    Endp

is_usb_pipe_stalled_name   DB 'Is Usb Pipe Stalled',0

is_usb_pipe_stalled    Proc far
    stc
    retf32
is_usb_pipe_stalled    Endp

create_usb_req_name DB 'Create USB req', 0

create_usb_req  Proc far
    stc
    retf32
create_usb_req   Endp

add_write_usb_data_req_name DB 'Add Write USB data req', 0

add_write_usb_data_req  Proc far
    stc
    retf32
add_write_usb_data_req   Endp

add_read_usb_data_req_name DB 'Add Read USB data req', 0

add_read_usb_data_req   Proc far
    stc
    retf32
add_read_usb_data_req   Endp

start_usb_req_name DB 'Start USB req', 0

start_usb_req   Proc far
    stc
    retf32
start_usb_req   Endp

stop_usb_req_name DB 'Stop USB req', 0

stop_usb_req    Proc far
    stc
    retf32
stop_usb_req   Endp

is_usb_req_started_name DB 'Is USB Req Started', 0

is_usb_req_started      Proc far
    stc
    retf32
is_usb_req_started   Endp

is_usb_req_ready_name DB 'Is USB Req Ready', 0

is_usb_req_ready    Proc far
    stc
    retf32
is_usb_req_ready   Endp

get_usb_req_data_name DB 'Get USB Req Data', 0

get_usb_req_data    Proc far
    stc
    retf32
get_usb_req_data   Endp

close_usb_req_name DB 'Close USB req', 0

close_usb_req   Proc far
    stc
    retf32
close_usb_req   Endp

init_usb_control_pipe_name DB 'Init USB Control Pipe', 0

init_usb_control_pipe    Proc far
    retf32
init_usb_control_pipe    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    INIT PCI DEVICE
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
    mov ax,SEG data
    mov ds,ax
    InitSection ds:usb_enum_section
    mov ds:usb_func_count,0
    mov ds:usb_attach_hooks,0
    mov ds:usb_detach_hooks,0
    mov ds:usb_over_current,0
    mov ds:usb_reset_failure,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ax,USB_DEV_HANDLE
    mov edi,OFFSET delete_dev_handle
    RegisterHandle
;
    mov esi,OFFSET init_usb_function
    mov edi,OFFSET init_usb_function_name
    xor cl,cl
    mov ax,init_usb_function_nr
    RegisterOsGate
;
    mov esi,OFFSET lock_usb
    mov edi,OFFSET lock_usb_name
    xor cl,cl
    mov ax,lock_usb_nr
    RegisterOsGate
;
    mov esi,OFFSET unlock_usb
    mov edi,OFFSET unlock_usb_name
    xor cl,cl
    mov ax,unlock_usb_nr
    RegisterOsGate
;
    mov esi,OFFSET init_usb_control_pipe
    mov edi,OFFSET init_usb_control_pipe_name
    xor cl,cl
    mov ax,init_usb_control_pipe_nr
    RegisterOsGate
;
    mov esi,OFFSET add_usb_device
    mov edi,OFFSET add_usb_device_name
    xor cl,cl
    mov ax,add_usb_device_nr
    RegisterOsGate
;
    mov esi,OFFSET get_hub_descr
    mov edi,OFFSET get_hub_descr_name
    xor cl,cl
    mov ax,get_usb_hub_descriptor_nr
    RegisterOsGate
;
    mov esi,OFFSET read_usb_descriptors
    mov edi,OFFSET read_usb_descriptors_name
    xor cl,cl
    mov ax,read_usb_descriptors_nr
    RegisterOsGate
;
    mov esi,OFFSET config_usb_hub
    mov edi,OFFSET config_usb_hub_name
    xor cl,cl
    mov ax,config_usb_hub_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_usb_attach
    mov edi,OFFSET notify_usb_attach_name
    xor cl,cl
    mov ax,notify_usb_attach_nr
    RegisterOsGate
;
    mov esi,OFFSET notify_usb_detach
    mov edi,OFFSET notify_usb_detach_name
    xor cl,cl
    mov ax,notify_usb_detach_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_usb_attach
    mov edi,OFFSET hook_usb_attach_name
    xor cl,cl
    mov ax,hook_usb_attach_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_usb_detach
    mov edi,OFFSET hook_usb_detach_name
    xor cl,cl
    mov ax,hook_usb_detach_nr
    RegisterOsGate
;
    mov esi,OFFSET allocate_usb_address
    mov edi,OFFSET allocate_usb_address_name
    xor cl,cl
    mov ax,allocate_usb_address_nr
    RegisterOsGate
;
    mov esi,OFFSET free_usb_address
    mov edi,OFFSET free_usb_address_name
    xor cl,cl
    mov ax,free_usb_address_nr
    RegisterOsGate
;
    mov esi,OFFSET init_usb_dev
    mov edi,OFFSET init_usb_dev_name
    xor cl,cl
    mov ax,init_usb_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET unlink_usb_dev
    mov edi,OFFSET unlink_usb_dev_name
    xor cl,cl
    mov ax,unlink_usb_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET advance_usb_read
    mov edi,OFFSET advance_usb_read_name
    xor cl,cl
    mov ax,advance_usb_read_nr
    RegisterOsGate
;
    mov esi,OFFSET advance_usb_write
    mov edi,OFFSET advance_usb_write_name
    xor cl,cl
    mov ax,advance_usb_write_nr
    RegisterOsGate
;
    mov esi,OFFSET free_usb_dev
    mov edi,OFFSET free_usb_dev_name
    xor cl,cl
    mov ax,free_usb_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET address_usb_dev
    mov edi,OFFSET address_usb_dev_name
    xor cl,cl
    mov ax,address_usb_dev_nr
    RegisterOsGate
;
    mov esi,OFFSET get_usb_dev_sel
    mov edi,OFFSET get_usb_dev_sel_name
    xor cl,cl
    mov ax,get_usb_dev_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET open_usb_dev_sel
    mov edi,OFFSET open_usb_dev_sel_name
    xor cl,cl
    mov ax,open_usb_dev_sel_nr
    RegisterOsGate
;
    mov esi,OFFSET is_usb_pipe_connected
    mov edi,OFFSET is_usb_pipe_connected_name
    xor cl,cl
    mov ax,is_usb_pipe_connected_nr
    RegisterOsGate
;
    mov esi,OFFSET create_usb_req
    mov edi,OFFSET create_usb_req_name
    xor cl,cl
    mov ax,create_usb_req_nr
    RegisterOsGate
;
    mov esi,OFFSET add_write_usb_data_req
    mov edi,OFFSET add_write_usb_data_req_name
    xor cl,cl
    mov ax,add_write_usb_data_req_nr
    RegisterOsGate
;
    mov esi,OFFSET add_read_usb_data_req
    mov edi,OFFSET add_read_usb_data_req_name
    xor cl,cl
    mov ax,add_read_usb_data_req_nr
    RegisterOsGate
;
    mov esi,OFFSET start_usb_req
    mov edi,OFFSET start_usb_req_name
    xor cl,cl
    mov ax,start_usb_req_nr
    RegisterOsGate
;
    mov esi,OFFSET stop_usb_req
    mov edi,OFFSET stop_usb_req_name
    xor cl,cl
    mov ax,stop_usb_req_nr
    RegisterOsGate
;
    mov esi,OFFSET is_usb_req_started
    mov edi,OFFSET is_usb_req_started_name
    xor cl,cl
    mov ax,is_usb_req_started_nr
    RegisterOsGate
;
    mov esi,OFFSET is_usb_req_ready
    mov edi,OFFSET is_usb_req_ready_name
    xor cl,cl
    mov ax,is_usb_req_ready_nr
    RegisterOsGate
;
    mov esi,OFFSET get_usb_req_data
    mov edi,OFFSET get_usb_req_data_name
    xor cl,cl
    mov ax,get_usb_req_data_nr
    RegisterOsGate
;
    mov esi,OFFSET close_usb_req
    mov edi,OFFSET close_usb_req_name
    xor cl,cl
    mov ax,close_usb_req_nr
    RegisterOsGate
;
    mov esi,OFFSET req_usb_data_no_copy
    mov edi,OFFSET req_usb_data_no_copy_name
    xor cl,cl
    mov ax,req_usb_data_no_copy_nr
    RegisterOsGate
;
    mov esi,OFFSET write_usb_data_no_copy
    mov edi,OFFSET write_usb_data_no_copy_name
    xor cl,cl
    mov ax,write_usb_data_no_copy_nr
    RegisterOsGate
;
    mov esi,OFFSET set_usb_over_current
    mov edi,OFFSET set_usb_over_current_name
    xor cl,cl
    mov ax,set_usb_over_current_nr
    RegisterOsGate
;
    mov esi,OFFSET set_usb_reset_failed
    mov edi,OFFSET set_usb_reset_failed_name
    xor cl,cl
    mov ax,set_usb_reset_failed_nr
    RegisterOsGate
;
    mov ebx,OFFSET get_usb_device16
    mov esi,OFFSET get_usb_device32
    mov edi,OFFSET get_usb_device_name
    mov dx,virt_es_in
    mov ax,get_usb_device_nr
    RegisterUserGate
;
    mov ebx,OFFSET get_usb_config16
    mov esi,OFFSET get_usb_config32
    mov edi,OFFSET get_usb_config_name
    mov dx,virt_es_in
    mov ax,get_usb_config_nr
    RegisterUserGate
;
    mov esi,OFFSET config_usb_device
    mov edi,OFFSET config_usb_device_name
    xor dx,dx
    mov ax,config_usb_device_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_usb_pipe
    mov edi,OFFSET open_usb_pipe_name
    xor dx,dx
    mov ax,open_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_usb_pipe
    mov edi,OFFSET close_usb_pipe_name
    xor dx,dx
    mov ax,close_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_pipe
    mov edi,OFFSET add_wait_for_pipe_name
    xor dx,dx
    mov ax,add_wait_for_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET req_usb_data
    mov edi,OFFSET req_usb_data_name
    xor dx,dx
    mov ax,req_usb_data_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_usb_data_size16
    mov esi,OFFSET get_usb_data_size32
    mov edi,OFFSET get_usb_data_size_name
    mov dx,virt_es_in
    mov ax,get_usb_data_size_nr
    RegisterUserGate
;
    mov ebx,OFFSET write_usb_data16
    mov esi,OFFSET write_usb_data32
    mov edi,OFFSET write_usb_data_name
    mov dx,virt_es_in
    mov ax,write_usb_data_nr
    RegisterUserGate
;
    mov esi,OFFSET start_usb_trans
    mov edi,OFFSET start_usb_trans_name
    xor dx,dx
    mov ax,start_usb_transaction_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_usb_trans_done
    mov edi,OFFSET is_usb_trans_done_name
    xor dx,dx
    mov ax,is_usb_trans_done_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_usb_connected
    mov edi,OFFSET is_usb_connected_name
    xor dx,dx
    mov ax,is_usb_connected_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET was_usb_trans_ok
    mov edi,OFFSET was_usb_trans_ok_name
    xor dx,dx
    mov ax,was_usb_trans_ok_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET start_one_usb_trans
    mov edi,OFFSET start_one_usb_trans_name
    xor dx,dx
    mov ax,start_one_usb_trans_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET is_usb_pipe_stalled
    mov edi,OFFSET is_usb_pipe_stalled_name
    xor dx,dx
    mov ax,is_usb_pipe_stalled_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_usb_over_current
    mov edi,OFFSET has_usb_over_current_name
    xor dx,dx
    mov ax,has_usb_over_current_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET has_usb_reset_failed
    mov edi,OFFSET has_usb_reset_failed_name
    xor dx,dx
    mov ax,has_usb_reset_failed_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_usb_dev
    mov edi,OFFSET open_usb_dev_name
    xor dx,dx
    mov ax,open_usb_dev_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_usb_dev
    mov edi,OFFSET close_usb_dev_name
    xor dx,dx
    mov ax,close_usb_dev_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET reset_usb_dev
    mov edi,OFFSET reset_usb_dev_name
    xor dx,dx
    mov ax,reset_usb_dev_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET send_usb_dev_control_msg16
    mov esi,OFFSET send_usb_dev_control_msg32
    mov edi,OFFSET send_usb_dev_control_msg_name
    mov dx,virt_es_in
    mov ax,send_usb_dev_control_msg_nr
    RegisterUserGate
;
    mov esi,OFFSET config_usb_pipe
    mov edi,OFFSET config_usb_pipe_name
    xor dx,dx
    mov ax,config_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET enable_usb_pipe
    mov edi,OFFSET enable_usb_pipe_name
    xor dx,dx
    mov ax,enable_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET disable_usb_pipe
    mov edi,OFFSET disable_usb_pipe_name
    xor dx,dx
    mov ax,disable_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_dev_pipe
    mov edi,OFFSET add_wait_for_dev_pipe_name
    xor dx,dx
    mov ax,add_wait_for_usb_dev_pipe_nr
    RegisterBimodalUserGate
    clc
    ret
init    Endp

code    ENDS

    END init
