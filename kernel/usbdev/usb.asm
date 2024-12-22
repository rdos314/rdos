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
INCLUDE hub.inc

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

usb_event_handle_struc    STRUC

ueh_base        handle_header <>
ueh_sel         DW ?

usb_event_handle_struc    ENDS

usb_event_struc    STRUC

ues_next        DW ?
ues_size        DW ?
ues_rd_ptr      DW ?
ues_wr_ptr      DW ?
ues_wait        DW ?

ues_event_arr   DW ?,?,?,?

usb_event_struc    ENDS    

event_wait_header    STRUC

ew_obj         wait_obj_header <>
ew_sel         DW ?

event_wait_header    ENDS


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

usb_func_count      DW ?
usb_func_arr        DW 256 DUP(?)

usb_event_section   section_typ <>
usb_event_list      DW ?

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
;       NAME:           OpenUsbEvent
;
;       DESCRIPTION:    Open USB event
;
;       PARAMETERS:     CX      Max events
;
;       RETURNS:        BX      Event handle       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_usb_event_name DB 'Open USB Event', 0

open_usb_event    Proc far
    push ds
    push es
    push eax
    push ecx
    push esi
    push edi
;
    movzx eax,cx
    shl eax,3
    add ax,OFFSET ues_event_arr
    AllocateSmallGlobalMem
    mov es:ues_size,cx
    mov es:ues_rd_ptr,0
    mov es:ues_wr_ptr,0
    mov es:ues_wait,0
;
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:usb_func_count
    mov bx,OFFSET usb_func_arr
    xor si,si

oueFuncLoop:
    mov ax,ds:[bx]
    or ax,ax
    jz oueFuncNext
;
    push ds
    push ecx
    push ebx
;
    xor di,di
    mov ds,ax
;
    mov eax,ds:usb_oc_bitmap
    or eax,eax
    jz oueCurrentOk
;
    mov ecx,32
    xor dx,dx

oueCurrentLoop:
    test al,1
    jz oueCurrentNext
;
    push bx
    mov bx,es:ues_wr_ptr
    shl bx,3
    add bx,OFFSET ues_event_arr
    mov es:[bx].ue_event,USB_EVENT_OVER_CURRENT
    mov es:[bx].ue_controller,si
    mov es:[bx].ue_port,dx
    mov es:[bx].ue_pipe,-1
    inc es:ues_wr_ptr
    pop bx

oueCurrentNext:
    inc dx
    shr eax,1
    loop oueCurrentLoop

oueCurrentOk:
    call fword ptr ds:is_running_proc
    jnc oueFuncOk
;
    push bx
    mov bx,es:ues_wr_ptr
    shl bx,3
    add bx,OFFSET ues_event_arr
    mov es:[bx].ue_event,USB_EVENT_CONTROLLER_ERROR
    mov es:[bx].ue_controller,si
    mov es:[bx].ue_port,-1
    mov es:[bx].ue_pipe,-1
    inc es:ues_wr_ptr
    pop bx

oueFuncOk:
    mov cx,MAX_USB_HUB_PORTS
    mov bx,OFFSET usb_dev_arr

oueDevLoop:
    mov ax,ds:[bx]    
    or ax,ax
    jz oueDevNext
;
    mov ax,es:ues_wr_ptr
    inc ax
    cmp ax,es:ues_size
    je oueDevNext
;
    push bx
    mov bx,es:ues_wr_ptr
    shl bx,3
    add bx,OFFSET ues_event_arr
    mov es:[bx].ue_event,USB_EVENT_ATTACH
    mov es:[bx].ue_controller,si
    mov es:[bx].ue_port,di
    mov es:[bx].ue_pipe,-1
    inc es:ues_wr_ptr
    pop bx

oueDevNext:
    inc di
    add bx,2
    loop oueDevLoop

oueFuncNext:
    pop ebx
    pop ecx
    pop ds
;
    inc si
    add bx,2
    sub cx,1
    jnz oueFuncLoop
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:usb_event_section
    mov ax,ds:usb_event_list
    mov es:ues_next,ax
    mov ds:usb_event_list,es
    LeaveSection ds:usb_event_section
;
    mov cx,SIZE usb_event_handle_struc
    AllocateHandle
    mov [ebx].ueh_sel,es
    mov [ebx].hh_sign,USB_EVENT_HANDLE
    mov bx,[ebx].hh_handle
    clc

oueDone:
    pop edi
    pop esi
    pop ecx
    pop eax
    pop es
    pop ds
    retf32
open_usb_event    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Name:       DeleteEventSel
;
;       Purpose:    Delete event sel
;
;       Parameters: ES       Event sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteEventSel    Proc near
    push ds
    push ax
    push bx
    push ecx
    push edx
;
    mov bx,es
    mov dx,es:ues_next
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:usb_event_section
;       
    mov ax,ds:usb_event_list
    cmp ax,bx
    jne desLoop
;
    mov ds:usb_event_list,dx
    jmp desUnlinked

desLoop:
    or ax,ax
    jz desUnlinked
;       
    mov ds,ax
    mov cx,ax
    mov ax,ds:ues_next
    cmp ax,bx
    jne desLoop
;
    mov ds,cx
    mov ds:ues_next,bx

desUnlinked:
    mov ax,SEG data
    mov ds,ax
    LeaveSection ds:usb_event_section
;
    FreeMem
;
    pop edx
    pop ecx
    pop bx
    pop ax
    pop ds
    ret
DeleteEventSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseUsbEvent
;
;       DESCRIPTION:    Close event handle
;
;       PARAMETERS:     BX      Event handle       
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_usb_event_name DB 'Close USB Event', 0

close_usb_event    Proc far
    push ds
    push es
    push ax
;
    mov ax,USB_EVENT_HANDLE
    DerefHandle
    jc cueDone
;
    mov es,[ebx].ueh_sel
    FreeHandle
    call DeleteEventSel

cueDone:
    pop ax
    pop es
    pop ds
    retf32
close_usb_event    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StartWaitForEvent
;
;           DESCRIPTION:    Start a wait for event
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_wait_for_event     PROC far
    push ds
    push ax
;
    mov ds,es:ew_sel
    mov ax,ds:ues_rd_ptr
    cmp ax,ds:ues_wr_ptr
    je swfeWait
;
    SignalWait
    jmp swfeDone

swfeWait:
    mov ds:ues_wait,es

swfeDone:
    pop ax
    pop ds
    retf32
start_wait_for_event Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           StopWaitForEvent
;
;           DESCRIPTION:    Stop a wait for event
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_wait_for_event      PROC far
    push ds
;
    mov ds,es:ew_sel
    mov ds:ues_wait,0
;
    pop ds
    retf32
stop_wait_for_event Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ClearWaitForEvent
;
;           DESCRIPTION:    Clear wait for event
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_wait_for_event     PROC far
    push ds
;
    mov ds,es:ew_sel
    mov ds:ues_wait,0
;
    pop ds
    retf32
clear_wait_for_event Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           IsEventIdle
;
;           DESCRIPTION:    Check if event is idle
;
;           PARAMETERS:     ES      Wait object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_event_idle    PROC far
    clc
    retf32
is_event_idle Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddWaitForUsbEvent
;
;           DESCRIPTION:    Add a wait for USB event
;
;           PARAMETERS:     BX      Wait handle
;                           AX      Event handle
;                           ECX     Signalled ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_wait_for_usb_event_name  DB 'Add Wait For USB Event',0

add_wait_event_tab:
awe0 DD OFFSET start_wait_for_event,      SEG code
awe1 DD OFFSET stop_wait_for_event,       SEG code
awe2 DD OFFSET clear_wait_for_event,      SEG code
awe3 DD OFFSET is_event_idle,             SEG code

add_wait_for_usb_event       PROC far
    push ds
    push es
    pushad
;
    mov bp,bx
    mov bx,ax
    mov ax,USB_EVENT_HANDLE
    DerefHandle
    jc aweDone
;
    mov si,ds:[ebx].ueh_sel
    mov bx,bp
    mov ax,cs
    mov es,ax
    mov ax,SIZE event_wait_header - SIZE wait_obj_header
    mov edi,OFFSET add_wait_event_tab
    AddWait
    jc aweDone
;
    mov es:ew_sel,si
    clc

aweDone:
    popad
    pop es
    pop ds
    retf32
add_wait_for_usb_event       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetUsbEvent
;
;       DESCRIPTION:    Get event
;
;       PARAMETERS:     BX         Event handle       
;                       ES:(E)DI   Event buffer
;
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_event_name DB 'Get USB Event', 0

get_usb_event    Proc near
    push ds
    push ebx
    push ecx
    push esi
    push edi
;
    mov ax,USB_EVENT_HANDLE
    DerefHandle
    jc gueDone
;
    mov ds,[ebx].ueh_sel
    mov bx,ds:ues_rd_ptr
    cmp bx,ds:ues_wr_ptr
    stc
    je gueDone
;
    movzx esi,bx
    shl esi,3
    add esi,OFFSET ues_event_arr
    mov ecx,SIZE usb_event
    rep movs byte ptr es:[edi],ds:[esi]
;
    inc bx
    cmp bx,ds:ues_size
    jb gueSave
;
    xor bx,bx

gueSave:
    mov ds:ues_rd_ptr,bx
    clc

gueDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop ds
    ret
get_usb_event    Endp

get_usb_event32  Proc far
    call get_usb_event
    retf32
get_usb_event32  Endp

get_usb_event16  Proc far
    push edi
    movzx edi,di
    call get_usb_event
    pop edi
    retf32
get_usb_event16  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Delete_event_handle
;
;           DESCRIPTION:    Delete event handle (called from handle module)
;
;           PARAMETERS:     BX         USB event handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_event_handle    Proc far
    push ds
    push es
    push ax
    push dx
;
    mov ax,USB_EVENT_HANDLE
    DerefHandle
    jc dehDone
;
    push [ebx].ueh_sel
    FreeHandle
    pop ds
;    
    or ax,ax
    stc
    jz dehDone
;    
    mov es,ax
    call DeleteEventSel
    clc

dehDone:
    pop dx
    pop ax
    pop es
    pop ds
    retf32
delete_event_handle    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddEvent
;
;       DESCRIPTION:    Add USB event
;
;       PARAMETERS:     ES      Event sel
;                       AX      Event
;                       BX      Controller
;                       SI      Port
;                       DL      Pipe
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddEvent        Proc near
    push di
;
    mov di,es:ues_wr_ptr
    inc di
    cmp di,es:ues_size
    jc aeSave
;
    xor di,di

aeSave:
    cmp di,es:ues_rd_ptr
    je aeDone
;
    push di
    mov di,es:ues_wr_ptr
    shl di,3
    add di,OFFSET ues_event_arr
    mov es:[di].ue_event,ax
    mov es:[di].ue_controller,bx
    mov es:[di].ue_port,si
    mov es:[di].ue_pipe,dl
    pop di
    mov es:ues_wr_ptr,di
;
    xor di,di
    xchg di,es:ues_wait
    or di,di
    jz aeDone
;
    push es
    mov es,di
    SignalWait
    pop es

aeDone:
    pop di
    ret
AddEvent        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DistEvent
;
;       DESCRIPTION:    Distribute USB event
;
;       PARAMETERS:     AX      Event
;                       BX      Controller
;                       SI      Port
;                       DL      Pipe
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DistEvent       Proc near
    push ds
    push es
    push cx
;
    mov cx,SEG data
    mov ds,cx
    EnterSection ds:usb_event_section
    mov cx,ds:usb_event_list

dueLoop:
    or cx,cx
    jz dueLeave
;
    mov es,cx
    call AddEvent
    mov cx,es:ues_next
    jmp dueLoop

dueLeave:
    LeaveSection ds:usb_event_section
;
    pop cx
    pop es
    pop ds
    ret
DistEvent       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReportUsbFuncEvent
;
;           DESCRIPTION:    Report USB function event
;
;           PARAMETERS:     AX      Event #
;                           DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

report_usb_func_event_name     DB 'Report USB Function Event',0

report_usb_func_event  Proc far
    push bx
    push dx
    push si
;
    mov bx,ds:usb_controller_id
    mov si,-1
    mov dl,-1
    call DistEvent
;
    pop si
    pop dx
    pop bx
    retf32
report_usb_func_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReportUsbDeviceEvent
;
;           DESCRIPTION:    Report USB device event
;
;           PARAMETERS:     AX      Event #
;                           DS      Function sel
;                           ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

report_usb_dev_event_name     DB 'Report USB Device Event',0

report_usb_dev_event  Proc far
    push bx
    push dx
    push si
;
    mov bx,ds:usb_controller_id
    movzx si,es:usbd_port
    mov dl,-1
    call DistEvent
;
    pop si
    pop dx
    pop bx
    retf32
report_usb_dev_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReportUsbPipeEvent
;
;           DESCRIPTION:    Report USB pipe event
;
;           PARAMETERS:     AX      Event #
;                           ES      Device sel
;                           DL      Pipe #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

report_usb_pipe_event_name     DB 'Report USB Pipe Event',0

report_usb_pipe_event  Proc far
    push ds
    push bx
    push dx
    push si
;
    mov ds,es:usbd_func_sel
    mov bx,ds:usb_controller_id
    movzx si,es:usbd_port
    call DistEvent
;
    pop si
    pop dx
    pop bx
    pop ds
    retf32
report_usb_pipe_event  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReportUsbRegPipeEvent
;
;           DESCRIPTION:    Report USB pipe event
;
;           PARAMETERS:     AX      Event #
;                           DS      Function sel
;                           SI      Port
;                           DL      Pipe #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

report_usb_reg_pipe_event_name     DB 'Report USB Reg Pipe Event',0

report_usb_reg_pipe_event  Proc far
    push bx
;
    mov bx,ds:usb_controller_id
    call DistEvent
;
    pop bx
    retf32
report_usb_reg_pipe_event  Endp

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
;       NAME:           IsUsbDeviceConnected
;
;       DESCRIPTION:    Is USB device connected
;
;       PARAMETERS:     BX      Device handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_usb_dev_connected_name  DB 'Is USB Device Connected',0

is_usb_dev_connected     Proc far
    push ds
    push es
    push ax
    push ebx
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc idvcDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz idvcLeave
;
    mov es,ds:udd_sel    
    test es:usbd_flags,DEV_FLAG_DETACHED
    stc
    jnz idvcLeave
;
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:is_dev_connected_proc
    pop ds

idvcLeave:
    LeaveSection ds:udd_section

idvcDone:
    pop ebx
    pop ax
    pop es
    pop ds
    retf32
is_usb_dev_connected     Endp

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
    push eax
    push ebx
    push ecx
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
    mov cl,es:usbd_port
    mov eax,1
    shl eax,cl
    lock or ds:usb_reset_bitmap,eax
;
    mov bx,ds:usb_controller_id
    movzx si,es:usbd_port
    mov ax,USB_EVENT_RESET
    mov dl,-1
    call DistEvent
;
    mov bx,es:usbd_thread
    Signal
;
    pop ds

rdvLeave:
    LeaveSection ds:udd_section

rdvDone:
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    retf32
reset_usb_dev     Endp

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
;       NAME:           GetPipe
;
;       description:    Get pipe selector
;
;       parameters:     DS        Function
;                       ES        Device
;                       DL        Pipe #
;
;       RETURNS:        GS        Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPipe Proc near
    push bx
    push si
;
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
;
    test dl,80h
    jz gpOut

gpIn:
    mov bx,es:[si].usbd_in_pipe_arr
    jmp gpFound

gpOut:
    mov bx,es:[si].usbd_out_pipe_arr

gpFound:
    or bx,bx
    stc
    jz gpDone
;
    mov gs,bx
    clc

gpDone:
    pop si
    pop bx
    ret
GetPipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ConfigPipe
;
;       description:    Configure pipe
;
;       parameters:     DS        Function
;                       ES        Device
;                       DL        Pipe #
;
;       RETURNS:        GS        Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigPipe      Proc near
    pushad
;
    mov ax,es:usbd_curr_config
    or ax,ax
    jz cpFail
;
    mov gs,ax
    xor edi,edi
    movzx bx,gs:ucd_len
    add di,bx

cpDescrLoop:
    mov al,gs:[di].udd_type
    cmp al,5
    jne cpNextDescr
;
    cmp dl,gs:[di].ued_address
    jne cpNextDescr
;
    mov al,gs:[di].ued_attrib
    and al,3
    cmp al,2
    je cpBulk
;
    cmp al,3
    jne cpFail

cpIntr:
    mov dh,gs:[di].ued_interval
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:create_intr_pipe_proc
    pop ds
    jmp cpSave

cpBulk:
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:create_bulk_pipe_proc
    pop ds

cpSave:
    push es
    mov es,bx
;
    mov es:usbp_wait,0
    mov es:usbp_flags,0
    mov es:usbp_packet_sel,0
    mov es:usbp_raw_sel,0
;
    mov si,di
    mov di,OFFSET usbp_descr
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
    jz cpOut

cpIn:
    mov es:[si].usbd_in_pipe_arr,bx
    jmp cpOk

cpOut:
    mov es:[si].usbd_out_pipe_arr,bx

cpOk:
    mov gs,bx
    clc
    jmp cpDone

cpNextDescr:
    movzx bx,gs:[di].ucd_len
    or bx,bx
    jz cpFail
;
    add di,bx
    cmp di,gs:ucd_size
    jb cpDescrLoop    

cpFail:
    xor ax,ax
    mov gs,ax
    stc
    jmp cpDone

cpDone:
    popad
    ret
ConfigPipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClearPipe
;
;       description:    Clear pipe
;
;       parameters:     DS        Function
;                       ES        Device
;                       GS        Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearPipe       Proc near
    push bx
;
    xor bx,bx
    xchg bx,gs:usbp_packet_sel
    or bx,bx
    jz clpPacketOk
;
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:close_packet_proc
    pop ds

clpPacketOk:    
    xor bx,bx
    xchg bx,gs:usbp_raw_sel
    or bx,bx
    jz clpDone
;
    push ds
;
    push bx
    mov ds,bx
    mov bx,ds:usbr_wait_dev
    CloseWaitDev
    pop bx
;
    mov ds,es:usbd_func_sel
    call fword ptr ds:close_raw_proc
;
    pop ds
     
clpDone:    
    test gs:usbp_flags,PIPE_FLAG_FAULT
    clc
    jz clpOk
;
    stc

clpOk:
    pop bx
    ret
ClearPipe       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartReconfigPipe
;
;       description:    Start to reconfigure pipe
;
;       parameters:     DS        Function
;                       ES        Device
;                       DL        Pipe #
;
;       RETURNS:        GS        Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartReconfigPipe       Proc near
    push bx
;
    call GetPipe
    jc srpConfig
;
    call ClearPipe
    jmp srpDone

srpConfig:
    call ConfigPipe

srpDone:
    pop bx
    ret
StartReconfigPipe       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPacket
;
;       description:    Open packet sel
;
;       PARAMETERS:     ES        Device
;                       GS        Pipe sel
;                       CX        Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPacket  Proc near
    push ds
    push bx
;
    mov ds,es:usbd_func_sel
    call fword ptr ds:open_packet_proc
    mov gs:usbp_packet_sel,bx
;
    mov ds,bx
    mov ds:usbpk_rd_ptr,0
    mov ds:usbpk_wr_ptr,0
    InitSection ds:usbpk_section
;
    pop bx
    pop ds
    ret
OpenPacket  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenRaw
;
;       description:    Open raw sel
;
;       PARAMETERS:     ES        Device
;                       GS        Pipe sel
;                       CX        Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

raw_text DB 'USB Raw ', 0

OpenRaw  Proc near
    push ds
    push bx
    push cx
    push si
    push di
;
    mov ds,es:usbd_func_sel
    call fword ptr ds:open_raw_proc
    mov gs:usbp_raw_sel,bx
;
    mov ds,bx
    CreateWaitDev
    mov ds:usbr_wait_dev,bx
;
    mov si,OFFSET raw_text
    mov di,OFFSET usbr_name

orCopy:
    mov al,cs:[si]
    or al,al
    jz orVal
;
    mov ds:[di],al
    inc si
    inc di
    jmp orCopy

orVal:
    mov al,gs:ued_address
    call HexToAscii
    mov ds:[di],ax
;
    add di,2
    xor al,al
    mov ds:[di],al
;
    pop di
    pop si
    pop cx
    pop bx
    pop ds
    ret
OpenRaw  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenUsbPacketPipe
;
;       description:    Open USB packet pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;                       CX        Buffered packets
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_usb_packet_pipe_name DB 'Open Usb Packet Pipe', 0

open_usb_packet_pipe    Proc far
    push ds
    push es
    push gs
    pushad
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc cuppDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    jnz cuppLeaveFail
;
    mov es,ds:udd_sel    
    call StartReconfigPipe
    jc cuppLeaveFail
;
    test dl,80h
    jz cuppOut

cuppIn:
    call OpenPacket
;
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:start_packet_proc
    pop ds
    jmp cuppOk

cuppOut:
    mov ax,gs:ued_maxsize
    mul cx
    mov cx,ax
    call OpenRaw

cuppOk:
    LeaveSection ds:udd_section
    clc
    jmp cuppDone

cuppLeaveFail:
    LeaveSection ds:udd_section
    stc

cuppDone:
    popad
    pop gs
    pop es
    pop ds    
    retf32
open_usb_packet_pipe Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenUsbRawPipe
;
;       description:    Open USB raw pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;                       CX        Buffer size
;                       AX        Timeout
;
;       RETURNS:        ES        Buffer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_usb_raw_pipe_name DB 'Open Usb Raw Pipe', 0

open_usb_raw_pipe       Proc far
    push ds
    push gs
    pushad
;
    push dx
    mov dx,1193
    mul dx
    push dx
    push ax
    pop esi
    pop dx
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc curpDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    jnz curpLeaveFail
;
    mov es,ds:udd_sel    
    call StartReconfigPipe
    jc curpLeaveFail
;
    call OpenRaw
;
    mov es,gs:usbp_raw_sel
    mov es:usbr_timeout,esi
    mov es,es:usbr_buf_sel
;
    LeaveSection ds:udd_section
    clc
    jmp curpDone

curpLeaveFail:
    LeaveSection ds:udd_section
    stc

curpDone:
    popad
    pop gs
    pop ds    
    retf32
open_usb_raw_pipe Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseUsbPipe
;
;       description:    Close USB pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_usb_pipe_name DB 'Close Usb Pipe', 0

close_usb_pipe  Proc far
    push ds
    push es
    push gs
    push eax
    push ebx
    push esi
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc cupDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz cupLeave
;
    mov es,ds:udd_sel    
    call GetPipe
    jc cupLeave
;
    call ClearPipe

cupLeave:
    LeaveSection ds:udd_section

cupDone:
    pop esi
    pop ebx
    pop eax
    pop gs
    pop es
    pop ds    
    retf32
close_usb_pipe Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PostUsbRawPipe
;
;       description:    Post USB raw pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;                       CX        Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

post_usb_raw_pipe_name DB 'Post Usb Raw Pipe', 0

post_usb_raw_pipe Proc far
    push ds
    push es
    push gs
    push eax
    push ebx
    push esi
    push edi
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc purpDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz purpLeave
;
    mov es,ds:udd_sel    
;
    test dl,80h
    jz purpOut

purpIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_in_pipe_arr
    or bx,bx
    stc
    jz purpLeave
;
    mov gs,bx
    test gs:usbp_flags,PIPE_FLAG_FAULT
    stc
    jnz purpLeave
;
    push ds
    mov ds,gs:usbp_raw_sel
    push es
    mov ax,ds
    mov es,ax
    mov edi,OFFSET usbr_name
    mov bx,ds:usbr_wait_dev
    PrepareWaitDev
    pop es
;
    mov ds,es:usbd_func_sel
    call fword ptr ds:read_raw_proc
;
    mov ds,gs:usbp_raw_sel
    push eax
    push edx
    GetSystemTime
    add eax,ds:usbr_timeout
    adc edx,0
    mov bx,ds:usbr_wait_dev
    WaitForDev
    pop edx
    pop eax
;
    mov ds,es:usbd_func_sel
    call fword ptr ds:finish_raw_proc
    pop ds
    jmp purpLeave

purpOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_out_pipe_arr
    or bx,bx
    stc
    jz purpLeave
;
    mov gs,bx
    test gs:usbp_flags,PIPE_FLAG_FAULT
    stc
    jnz purpLeave
;
    push ds
    mov ds,gs:usbp_raw_sel
    push es
    mov ax,cs
    mov es,ax
    mov edi,OFFSET raw_text
    mov bx,ds:usbr_wait_dev
    PrepareWaitDev
    pop es
;
    mov ds,es:usbd_func_sel
    call fword ptr ds:write_raw_proc
;
    mov ds,gs:usbp_raw_sel
    push eax
    push edx
    GetSystemTime
    add eax,ds:usbr_timeout
    adc edx,0
    mov bx,ds:usbr_wait_dev
    WaitForDev
    pop edx
    pop eax
;
    mov ds,es:usbd_func_sel
    call fword ptr ds:finish_raw_proc
    pop ds

purpLeave:
    LeaveSection ds:udd_section

purpDone:
    pop edi
    pop esi
    pop ebx
    pop eax
    pop gs
    pop es
    pop ds    
    retf32
post_usb_raw_pipe Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetUsedPackets
;
;       description:    Get used USB pipe packets
;
;       parameters:     GS        Pipe sel
;
;       returns:        CX        Buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetUsedPackets  Proc near
    push ds
;
    mov cx,gs:usbp_packet_sel
    or cx,cx
    jz gupDone
;
    mov ds,cx
    mov cx,ds:usbpk_wr_ptr
    sub cx,ds:usbpk_rd_ptr
    jnc gupDone
;
    add cx,ds:usbpk_entry_count

gupDone:
    pop ds
    ret
GetUsedPackets  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetFreePackets
;
;       description:    Get free USB pipe packets
;
;       parameters:     GS        Pipe sel
;
;       returns:        CX        Buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFreePackets  Proc near
    push ds
    push ax
;
    mov cx,gs:usbp_packet_sel
    or cx,cx
    jz gfpEnd
;
    mov ds,cx
    mov ax,ds:usbpk_tail_ptr
    sub ax,ds:usbpk_rd_ptr
    jnc gfpDone
;
    add ax,ds:usbpk_entry_count

gfpDone:
    mov cx,ds:usbpk_entry_count
    sub cx,ax
    dec cx

gfpEnd:
    pop ax
    pop ds
    ret
GetFreePackets  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetUsedUsbBuffers
;
;       description:    Get used USB pipe buffers
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;
;       returns:        CX        Buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_used_usb_buffers_name DB 'Get Used Usb Buffers', 0

get_used_usb_buffers    Proc far
    push ds
    push es
    push gs
    push eax
    push ebx
    push esi
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc guubDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz guubLeave
;
    mov es,ds:udd_sel    
;
    test dl,80h
    jnz guubIn

guubOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_out_pipe_arr
    or bx,bx
    stc
    jz guubLeave
;
    mov gs,bx
    call GetUsedPackets
    clc
    jmp guubLeave

guubIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_in_pipe_arr
    or bx,bx
    stc
    jz guubLeave
;
    mov gs,bx
    call GetUsedPackets
    clc

guubLeave:
    LeaveSection ds:udd_section

guubDone:
    pop esi
    pop ebx
    pop eax
    pop gs
    pop es
    pop ds    
    retf32
get_used_usb_buffers Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetFreeUsbBuffers
;
;       description:    Get free USB pipe buffers
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;
;       returns:        CX        Buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_free_usb_buffers_name DB 'Get Free Usb Buffers', 0

get_free_usb_buffers    Proc far
    push ds
    push es
    push gs
    push eax
    push ebx
    push esi
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc gfubDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz gfubLeave
;
    mov es,ds:udd_sel    
;
    test dl,80h
    jnz gfubIn

gfubOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_out_pipe_arr
    or bx,bx
    stc
    jz gfubLeave
;
    mov gs,bx
    call GetFreePackets
    clc
    jmp gfubLeave

gfubIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_in_pipe_arr
    or bx,bx
    stc
    jz gfubLeave
;
    mov gs,bx
    call GetFreePackets
    clc

gfubLeave:
    LeaveSection ds:udd_section

gfubDone:
    pop esi
    pop ebx
    pop eax
    pop gs
    pop es
    pop ds    
    retf32
get_free_usb_buffers Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetUsbBufferSize
;
;       description:    Get buffer size for pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;
;       returns:        CX        Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_buffer_size_name DB 'Get Usb Buffer Size', 0

get_usb_buffer_size     Proc far
    push ds
    push es
    push gs
    push eax
    push ebx
    push esi
;
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc gubsDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz gubsLeave
;
    mov es,ds:udd_sel    
;
    test dl,80h
    jnz gubsIn

gubsOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_out_pipe_arr
    or bx,bx
    stc
    jz gubsLeave
;
    mov gs,bx
    mov cx,gs:ued_maxsize
    clc
    jmp gubsLeave

gubsIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_in_pipe_arr
    or bx,bx
    stc
    jz gubsLeave
;
    mov gs,bx
    mov cx,gs:ued_maxsize
    clc

gubsLeave:
    LeaveSection ds:udd_section

gubsDone:
    pop esi
    pop ebx
    pop eax
    pop gs
    pop es
    pop ds    
    retf32
get_usb_buffer_size Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadPacket
;
;       description:    Read using packet interface
;
;       parameters:     GS        Pipe sel
;                       BP:EDI    Buffer
;
;       returns:        CX        Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPacket      Proc near
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:req_packet_proc
    jc rpkDone
;
    movzx ecx,cx
    push es
    push ecx
;
    mov ax,flat_sel
    mov fs,ax
    mov es,bp
    mov esi,edx
    rep movs byte ptr es:[edi],fs:[esi]
;
    pop ecx
    pop es
;
    push cx
    mov cx,gs:ued_maxsize
    call fword ptr ds:rel_packet_proc
    pop cx
    clc

rpkDone:
    pop ds
    ret
ReadPacket      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetUsbPacketPipe
;
;       description:    Get USB packet pipe
;
;       parameters:     BX        Handle
;                       DL        Pipe #
;                       ES:(E)DI  Buffer
;
;       returns:        CX        Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_packet_pipe_name DB 'Get Usb Packet Pipe', 0

ReadPipe        Proc near
    push ds
    push es
    push fs
    push gs
    push eax
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    mov bp,es
    mov ax,USB_DEV_HANDLE
    DerefHandle
    jc rupDone
;
    mov ds,ds:[ebx].udh_dev_sel
    EnterSection ds:udd_section
    mov al,ds:udd_deleted
    or al,al
    stc
    jnz rupLeave
;
    mov es,ds:udd_sel    
;
    test dl,80h
    stc
    jz rupLeave
;
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov bx,es:[si].usbd_in_pipe_arr
    or bx,bx
    stc
    jz rupLeave
;
    mov gs,bx
    mov bx,gs:usbp_packet_sel
    or bx,bx
    jz rupNotPacket
;
    call ReadPacket
    jmp rupLeave

rupNotPacket:
    stc

rupLeave:
    LeaveSection ds:udd_section

rupDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    pop gs
    pop fs
    pop es
    pop ds    
    ret
ReadPipe Endp

get_usb_packet_pipe32 Proc far
    call ReadPipe
    retf32
get_usb_packet_pipe32 Endp

get_usb_packet_pipe16 Proc far
    push edi
    movzx edi,di
    call ReadPipe
    pop edi
    retf32
get_usb_packet_pipe16 Endp

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
    push es
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
    jmp bwfpLeaveSignal

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
    mov cx,gs:usbp_packet_sel
    or cx,cx
    jz bwfpLeaveSignal
;
    test gs:usbp_flags,PIPE_FLAG_FAULT
    jnz bwfpLeaveSignal
;
    mov gs:usbp_wait,bx
    mov es,cx
    mov cx,es:usbpk_wr_ptr
    cmp cx,es:usbpk_rd_ptr
    jz bwfpLeave

bwfpCheckSignal:
    xor bx,bx
    xchg bx,gs:usbp_wait
    or bx,bx
    jz bwfpLeave

bwfpLeaveSignal:
    mov es,bx
    SignalWait

bwfpLeave:
    LeaveSection ds:udd_section
;
    popad
    pop gs
    pop es
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
    push ds
    push es
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
    jnz swfpLeave
;
    mov es,ds:udd_sel    
;
    mov ax,flat_sel
    mov fs,ax
;
    test dl,80h
    jnz swfpIn

swfpOut:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov si,es:[si].usbd_out_pipe_arr
    or si,si
    jz swfpLeave
;
    mov gs,si
    mov gs:usbp_wait,0
    jmp swfpLeave

swfpIn:
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    mov si,es:[si].usbd_in_pipe_arr
    or si,si
    jz swfpLeave
;
    mov gs,si
    mov gs:usbp_wait,0

swfpLeave:
    LeaveSection ds:udd_section
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
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
    push es
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
    mov gs:usbp_wait,0
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
    mov gs:usbp_wait,0

cwfpLeave:
    LeaveSection ds:udd_section
;
    popad
    pop gs
    pop fs
    pop es
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
    push es
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
    pop es
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
    InitSection ds:usb_addr_section
    mov ds:usb_reset_bitmap,0
    mov ds:usb_oc_bitmap,0
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
    btr ds:usb_addr_bitmap,eax
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
;       NAME:               GetUsbAddress
;
;       description:        Get USB address
;
;       parameters:         BX       Controller #
;                           AL       Device port #
;
;       Returns:            AL       Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_address_name DB 'Get USB Address', 0

get_usb_address  Proc far
    push ds
    push es
    push ebx
    push esi
;
    mov si,SEG data
    mov ds,si
    mov si,ds:usb_func_count
    cmp bx,si
    jae guaFail
;
    mov si,bx
    add si,si
    mov si,ds:[si].usb_func_arr
    or si,si
    jz guaFail
;
    mov ds,si
    cmp al,MAX_USB_HUB_PORTS
    jae guaFail
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz guaFail
;
    mov es,si
    mov al,es:usbd_address
    clc
    jmp guaDone

guaFail:
    xor ax,ax
    stc

guaDone:        
    pop esi
    pop ebx
    pop es
    pop ds
    retf32
get_usb_address  Endp

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
;
    mov ds,si
    cmp al,MAX_USB_HUB_PORTS
    jae crrDone
;    
    movzx si,al
    add si,si
    mov si,ds:[si].usb_dev_arr
    or si,si
    jz crrDone
;
    push es
    mov es,si
    mov es:usbd_my_hub,cx
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
;       NAME:           InitDevice
;
;       description:    Init device
;
;       parameters:     ES      Device sel
;                       AL      Address
;                       AH      Speed
;                       BX      Hub selector
;                       DL      Port #
;
;       Returns:        ES     Dev sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitDevice Proc near
    push ax
    push cx
    push di
;
    mov es:usbd_parent_hub,bx
    mov es:usbd_my_hub,0
    mov es:usbd_port,dl
    mov es:usbd_address,al
    mov es:usbd_speed,ah
    mov es:usbd_flags,0
    mov es:usbd_maxlen,8
    mov es:usbd_curr_config,0
    mov es:usbd_thread,0
;
    push bx
    CreateWaitDev
    mov es:usbd_wait_dev,bx
    pop bx
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
    jz idNoHub
;
    mov es:usbd_func_sel,bx

idNoHub:
    pop di
    pop cx
    pop ax
    ret
InitDevice Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddDevice
;
;       Description:    Add device
;
;       Parameters:     DS      USB function selector
;                       ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice       Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ds,es:usbd_func_sel
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
    ret
AddDevice  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadDescriptors
;
;       Description:    Read descriptors
;
;       Parameters:     DS      USB function selector
;                       ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDescriptors       Proc near
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
    ret
ReadDescriptors   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NotifyAttach
;
;       Description:    Notify attach
;
;       Parameters:     DS      USB function selector
;                       ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyAttach       Proc near
    push ds
    push es
    pushad
;
    mov bx,ds:usb_controller_id
    movzx si,es:usbd_port
    mov ax,USB_EVENT_ATTACH
    mov dl,-1
    call DistEvent
;       
    mov bx,ds:usb_controller_id
    mov al,es:usbd_port
    mov cx,SEG data
    mov es,cx
    mov cx,es:usb_attach_hooks
    or cx,cx
    je naDone
    
    mov si,OFFSET usb_attach_arr

naLoop:
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
    loop naLoop

naDone:
    popad
    pop es
    pop ds
    ret
NotifyAttach   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopHub
;
;           description:    Stop Hub
;
;       parameters:         DS      USB function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopHub       Proc near
    push es
    pushad
;
    mov bx,OFFSET hub_status_arr
    mov cx,ds:hub_ports
    xor ax,ax

shStatusLoop:
    mov ds:[bx],ax
    add bx,2
    loop shStatusLoop
;
    mov si,OFFSET usb_thread_arr
    mov cx,ds:hub_ports
    xor ax,ax

shLoop:
    mov bx,ds:[si]
    or bx,bx
    jz shNext
;
    Signal

shNext:
    add si,2
    loop shLoop
;
    popad
    pop es
    ret
StopHub   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopDevice
;
;           description:    Stop USB device
;
;       parameters:         DS      USB function selector
;                           ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopDevice       Proc near
    push ds
    pushad
;
    mov ax,es:usbd_my_hub
    or ax,ax
    jz sdHubDone
;
    push ds
    mov ds,ax
    call StopHub
    pop ds

sdHubDone:
    popad
    pop ds
    ret
StopDevice    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlinkDevice
;
;           description:    Unlink USB device
;
;       parameters:         DS      USB function selector
;                           ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkDevice       Proc near
    push ds
    pushad
;
    lock or es:usbd_flags,DEV_FLAG_DETACHED
    movzx bx,es:usbd_port
    add bx,bx
    xor ax,ax
    mov ds:[bx].usb_dev_arr,ax
    xchg ax,ds:[bx].usb_handle_arr
    or ax,ax
    jz udDeviceDone
;
    push ds
    mov ds,ax
    mov ds:udd_deleted,1
    EnterSection ds:udd_section
    LeaveSection ds:udd_section
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

udInLoop:
    mov bx,es:[si]
    or bx,bx
    jz udInNext
;
    push es
    mov es,bx
    xor bx,bx
    xchg bx,es:usbp_wait
    or bx,bx
    jz udInPop
;
    mov es,bx
    SignalWait

udInPop:
    pop es

udInNext:
    add si,2
    loop udInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

udOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz udOutNext
;
    push es
    mov es,bx
    xor bx,bx
    xchg bx,es:usbp_wait
    or bx,bx
    jz udOutPop
;
    mov es,bx
    SignalWait

udOutPop:
    pop es

udOutNext:
    add si,2
    loop udOutLoop
;
    lock sub ds:udd_ref_count,1
    pop ds
    jnz udDeviceDone
;
    push es
    mov es,ax
    FreeMem
    pop es

udDeviceDone:
    call fword ptr ds:unlink_proc
;
    popad
    pop ds
    ret
UnlinkDevice    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NotifyDetach
;
;           description:    Notify detach event
;
;       parameters:         DS      USB function selector
;                           ES      USB device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyDetach       Proc near
    push ds
    push es
    pushad
; 
    mov bx,ds:usb_controller_id
    movzx si,es:usbd_port
    mov ax,USB_EVENT_DETACH
    mov dl,-1
    call DistEvent
;
    mov bx,ds:usb_controller_id
    mov al,es:usbd_port
    mov cx,SEG data
    mov es,cx
    mov cx,es:usb_detach_hooks
    or cx,cx
    je ndDone
    
    mov si,OFFSET usb_detach_arr

ndLoop:
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
    loop ndLoop

ndDone:
    popad
    pop es
    pop ds
    ret
NotifyDetach   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetActivePorts
;
;       Description:    Return # of active ports
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;       RETURNS:        AX      Active ports
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetActivePorts       Proc near
    mov ax,es:usbd_my_hub
    or ax,ax
    jz hapDone
;
    push ds
    push bx
    push cx
    push dx
;
    mov ds,ax
    mov bx,OFFSET usb_thread_arr
    mov cx,ds:hub_ports
    xor dx,dx

hapLoop:
    mov ax,ds:[bx]
    or ax,ax
    jz hapNext
;
    inc dx

hapNext:
    add bx,2
    loop hapLoop
;
    mov ax,dx
;
    pop dx
    pop cx
    pop bx
    pop ds

hapDone:
    ret
GetActivePorts     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CleanupPipes
;
;       Description:    Cleanup pipes
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupPipes       Proc near
    push gs
    push bx
    push cx
    push si
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

clpInLoop:
    mov bx,es:[si]
    or bx,bx
    jz clpInNext
;
    mov gs,bx
    call ClearPipe

clpInNext:
    add si,2
    loop clpInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

clpOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz clpOutNext
;
    mov gs,bx
    call ClearPipe

clpOutNext:
    add si,2
    loop clpOutLoop
;
    pop si
    pop cx
    pop bx
    pop gs
    ret
CleanupPipes  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeConfig
;
;       Description:    Free configurations
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeConfig       Proc near
    push ax
    push bx
    push cx
;
    mov cx,16
    mov bx,OFFSET usbd_config_sel

fcLoop:
    xor ax,ax
    xchg ax,es:[bx]
    or ax,ax
    jz fcNext
;
    push es
    mov es,ax
    FreeMem
    pop es

fcNext:
    add bx,2
    loop fcLoop    
;
    pop cx
    pop bx
    pop ax
    ret
FreeConfig   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreePipes
;
;       Description:    Free pipes
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePipes       Proc near
    push bx
    push cx
    push si
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

fpInLoop:
    xor bx,bx
    xchg bx,es:[si]
    or bx,bx
    jz fpInNext
;
    push es
    mov es,bx
    FreeMem
    pop es

fpInNext:
    add si,2
    loop fpInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

fpOutLoop:
    xor bx,bx
    xchg bx,es:[si]
    or bx,bx
    jz fpOutNext
;
    push es
    mov es,bx
    FreeMem
    pop es

fpOutNext:
    add si,2
    loop fpOutLoop
;
    pop si
    pop cx
    pop bx
    ret
FreePipes  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CleanupDev
;
;       Description:    Cleanup device
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupDev       Proc near
    call CleanupPipes
    call fword ptr ds:free_dev_proc
    call FreeConfig
    call FreePipes
    ret
CleanupDev       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeDev
;
;       Description:    Free device
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDev       Proc near
    push ax
    push bx
;
    mov bx,es:usbd_wait_dev
    CloseWaitDev
;
    mov al,es:usbd_address
    call fword ptr ds:free_address_proc
    FreeMemBlk
;
    pop bx
    pop ax
    ret
FreeDev       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandlerThread
;
;       description:    USB server thread
;
;       parameters:     BP      Function sel
;                       BX      Hub selector
;                       DL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handler_thread:
    mov ds,bp
    xor bp,bp
    movzx edi,dl
    add edi,edi
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[edi].usb_thread_arr,ax
    LeaveSection ds:usb_section

uaAttach:
    xor cx,cx
    mov es,cx
    call fword ptr ds:lock_proc
    call fword ptr ds:reset_port_proc
    jc uaLockedError
;
    mov cl,al
;
    call fword ptr ds:allocate_address_proc
    jc uaLockedError
;
    mov ah,cl
    call fword ptr ds:create_dev_proc
    call InitDevice
    call fword ptr ds:create_control_proc
    call fword ptr ds:address_device_proc
    jc uaLockedError
;
    call fword ptr ds:change_address_proc
    call AddDevice
    call fword ptr ds:unlock_proc
    call ReadDescriptors
    jc uaDetach
;
    GetThread
    mov es:usbd_thread,ax
;
    call NotifyAttach
    or es:usbd_flags,DEV_FLAG_ATTACHED

uaConnected:
    WaitForSignal
;
    test es:usbd_flags,DEV_FLAG_DETACHED
    jnz uaDetach
;
    test es:usbd_flags,DEV_FLAG_FAULT
    jnz uaDetach
;
    call fword ptr ds:is_dev_connected_proc
    jc uaDetach
;
    mov cl,es:usbd_port
    mov eax,1
    shl eax,cl
    test eax,ds:usb_oc_bitmap
    jnz uaDetach
;
    test eax,ds:usb_reset_bitmap
    jz uaConnected
;
    not eax
    lock and ds:usb_reset_bitmap,eax

uaDetach:
    mov es:usbd_thread,0
;
    call fword ptr ds:lock_proc
    jmp uaDetachLocked

uaLockedError:
    mov bp,ds
    mov ax,es
    or ax,ax
    jnz uaDisableDev
;
    call fword ptr ds:disable_port_proc
    call fword ptr ds:unlock_proc
    jmp uaDone

uaDisableDev:
    call fword ptr ds:disable_device_proc

uaDetachLocked:
    call StopDevice
    call fword ptr ds:unlock_proc

uaWaitExit:
    call GetActivePorts
    or ax,ax
    jz uaUnlink
;
    WaitForSignal
    jmp uaWaitExit

uaUnlink:
    call UnlinkDevice
;
    test es:usbd_flags,DEV_FLAG_ATTACHED
    jz uaNotified
;
    call NotifyDetach

uaNotified:
    mov ax,10
    WaitMilliSec
;
    call CleanupDev
;
    mov ax,10
    WaitMilliSec
;
    mov ax,es:usbd_parent_thread
    call FreeDev
;
    call fword ptr ds:is_port_connected_proc
    jnc uaAttach

uaDone:
    EnterSection ds:usb_section
    mov ds:[edi].usb_thread_arr,0
    LeaveSection ds:usb_section
;
    or ax,ax
    jz uaExit
;
    mov bx,ax
    Signal

uaExit:
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
;       NAME:           NotifyUsbPortState
;
;       description:    Notify USB port state
;
;       parameters:     DS      Function
;                       BX      Hub sel
;                       DL      Port
;                       AX      State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_usb_port_state_name DB 'Notify USB Port State', 0

name_base DB 'USB Dev ', 0

notify_usb_port_state Proc far
    push eax
    push ebx
    push ecx
    push esi
    push edi
;
    movzx edi,dl
    add edi,edi
;
    test al,8
    jz npsNoOc

npsOc:
    movzx cx,dl
    lock bts word ptr ds:usb_oc_bitmap,cx
    jc npsOcOk
;
    call fword ptr ds:power_off_port_proc
;
    pushad
    mov bx,ds:usb_controller_id
    movzx si,dl
    mov ax,USB_EVENT_OVER_CURRENT
    mov dl,-1
    call DistEvent
;
    mov bx,ds:[edi].usb_thread_arr
    or bx,bx
    jz npsSignalDone
;
    cmp bx,-1
    je npsSignalDone
;
    Signal

npsSignalDone: 
    popad
    jmp npsOcOk

npsNoOc:
    movzx cx,dl
    lock btr word ptr ds:usb_oc_bitmap,cx
    jnc npsOcOk
;
    call fword ptr ds:power_on_port_proc

npsOcOk:
    test al,1
    jz npsDetach
    
npsAttach:
    mov si,ds:[edi].usb_thread_arr
    or si,si
    jnz npsDone
;
    mov ds:[edi].usb_thread_arr,-1
;    
    push ds
    push es
    pushad
;
    mov bp,ds
;
    mov esi,OFFSET name_base
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi

npsCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz npsCopyDone
;
    stosb
    jmp npsCopyLoop

npsCopyDone:
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
    xor edi,edi
    mov ax,cs
    mov ds,ax
    mov esi,OFFSET handler_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    FreeMem
;
    popad
    pop es
    pop ds
    jmp npsDone

npsDetach:
    EnterSection ds:usb_section
    mov bx,ds:[edi].usb_thread_arr
    or bx,bx
    jz npsLeave
;    
    Signal

npsLeave:
    LeaveSection ds:usb_section

npsDone:
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    retf32
notify_usb_port_state Endp

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
    mov ds:usb_func_count,0
    mov ds:usb_attach_hooks,0
    mov ds:usb_detach_hooks,0
    InitSection ds:usb_event_section
    mov ds:usb_event_list,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ax,USB_DEV_HANDLE
    mov edi,OFFSET delete_dev_handle
    RegisterHandle
;
    mov ax,USB_EVENT_HANDLE
    mov edi,OFFSET delete_event_handle
    RegisterHandle
;
    mov esi,OFFSET init_usb_function
    mov edi,OFFSET init_usb_function_name
    xor cl,cl
    mov ax,init_usb_function_nr
    RegisterOsGate
;
    mov esi,OFFSET get_hub_descr
    mov edi,OFFSET get_hub_descr_name
    xor cl,cl
    mov ax,get_usb_hub_descriptor_nr
    RegisterOsGate
;
    mov esi,OFFSET config_usb_hub
    mov edi,OFFSET config_usb_hub_name
    xor cl,cl
    mov ax,config_usb_hub_nr
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
    mov esi,OFFSET report_usb_func_event
    mov edi,OFFSET report_usb_func_event_name
    xor cl,cl
    mov ax,report_usb_func_event_nr
    RegisterOsGate
;
    mov esi,OFFSET report_usb_dev_event
    mov edi,OFFSET report_usb_dev_event_name
    xor cl,cl
    mov ax,report_usb_dev_event_nr
    RegisterOsGate
;
    mov esi,OFFSET report_usb_pipe_event
    mov edi,OFFSET report_usb_pipe_event_name
    xor cl,cl
    mov ax,report_usb_pipe_event_nr
    RegisterOsGate
;
    mov esi,OFFSET report_usb_reg_pipe_event
    mov edi,OFFSET report_usb_reg_pipe_event_name
    xor cl,cl
    mov ax,report_usb_reg_pipe_event_nr
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
    mov esi,OFFSET notify_usb_port_state
    mov edi,OFFSET notify_usb_port_state_name
    xor cl,cl
    mov ax,notify_usb_port_state_nr
    RegisterOsGate
;
    mov esi,OFFSET open_usb_raw_pipe
    mov edi,OFFSET open_usb_raw_pipe_name
    xor cl,cl
    mov ax,open_usb_raw_pipe_nr
    RegisterOsGate
;
    mov esi,OFFSET post_usb_raw_pipe
    mov edi,OFFSET post_usb_raw_pipe_name
    xor cl,cl
    mov ax,post_usb_raw_pipe_nr
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
    mov esi,OFFSET get_usb_address
    mov edi,OFFSET get_usb_address_name
    xor dx,dx
    mov ax,get_usb_address_nr
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
    mov esi,OFFSET is_usb_dev_connected
    mov edi,OFFSET is_usb_dev_connected_name
    xor dx,dx
    mov ax,is_usb_dev_connected_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET send_usb_dev_control_msg16
    mov esi,OFFSET send_usb_dev_control_msg32
    mov edi,OFFSET send_usb_dev_control_msg_name
    mov dx,virt_es_in
    mov ax,send_usb_dev_control_msg_nr
    RegisterUserGate
;
    mov esi,OFFSET open_usb_packet_pipe
    mov edi,OFFSET open_usb_packet_pipe_name
    xor dx,dx
    mov ax,open_usb_packet_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_usb_pipe
    mov edi,OFFSET close_usb_pipe_name
    xor dx,dx
    mov ax,close_usb_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_dev_pipe
    mov edi,OFFSET add_wait_for_dev_pipe_name
    xor dx,dx
    mov ax,add_wait_for_usb_dev_pipe_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_used_usb_buffers
    mov edi,OFFSET get_used_usb_buffers_name
    xor dx,dx
    mov ax,get_used_usb_buffers_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_free_usb_buffers
    mov edi,OFFSET get_free_usb_buffers_name
    xor dx,dx
    mov ax,get_free_usb_buffers_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_usb_buffer_size
    mov edi,OFFSET get_usb_buffer_size_name
    xor dx,dx
    mov ax,get_usb_buffer_size_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_usb_packet_pipe16
    mov esi,OFFSET get_usb_packet_pipe32
    mov edi,OFFSET get_usb_packet_pipe_name
    mov dx,virt_es_in
    mov ax,get_usb_packet_pipe_nr
    RegisterUserGate
;
    mov esi,OFFSET open_usb_event
    mov edi,OFFSET open_usb_event_name
    xor dx,dx
    mov ax,open_usb_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_usb_event
    mov edi,OFFSET close_usb_event_name
    xor dx,dx
    mov ax,close_usb_event_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET add_wait_for_usb_event
    mov edi,OFFSET add_wait_for_usb_event_name
    xor dx,dx
    mov ax,add_wait_for_usb_event_nr
    RegisterBimodalUserGate
;
    mov ebx,OFFSET get_usb_event16
    mov esi,OFFSET get_usb_event32
    mov edi,OFFSET get_usb_event_name
    mov dx,virt_es_in
    mov ax,get_usb_event_nr
    RegisterUserGate
    clc
    ret
init    Endp

code    ENDS

    END init
