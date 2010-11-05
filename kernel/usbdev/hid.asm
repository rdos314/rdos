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
; HID.ASM
; Implements HID class for USB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\usbdev\usb.inc

STD_KEY = 1
CAPS_KEY = 2
FUNC_KEY = 3
NUM_KEY = 4
DEL_KEY = 5
CAPS_LOCK = 6
NUM_LOCK = 7

trans_struc STRUC

ts_ext      DB ?
ts_vk       DB ?
ts_scan     DB ?
ts_norm     DB ?
ts_shift    DB ?
ts_alt      DB ?
ts_ctrl     DB ?
ts_action   DB ?

trans_struc ENDS

MOD_LEFT_CTRL   = 1
MOD_LEFT_SHIFT  = 2
MOD_LEFT_ALT    = 4
MOD_LEFT_GUI    = 8
MOD_RIGHT_CTRL  = 10h
MOD_RIGHT_SHIFT = 20h
MOD_RIGHT_ALT   = 40h
MOD_RIGHT_GUI   = 80h

hid_key_struc   STRUC

hk_modifiers    DB ?
hk_resv         DB ?
hk_key_arr      DB 6 DUP(?)

hid_key_struc   ENDS

usb_hid_descr  STRUC

uhd_len             DB ?
uhd_type            DB ?
uhd_hid_ver         DW ?
uhd_country_code    DB ?
uhd_descr_count     DB ?
uhd_descr_arr       DB ?

usb_hid_descr  ENDS

usb_hid_arr_descr   STRUC

uhad_descr_type      DB ?
uhad_descr_len       DW ?

usb_hid_arr_descr   ENDS

hid_device_struc   STRUC

hid_prev            DW ?
hid_next            DW ?

hid_controller      DW ?
hid_device          DB ?

hid_interface       DB ?
hid_protocol        DB ?
hid_intr_in         DB ?
hid_control_handle  DW ?
hid_control_wait    DW ?
hid_intr_handle     DW ?
hid_intr_buf        DW ?
hid_intr_req        DW ?

hid_country_code    DB ?
hid_descr_count     DB ?

hid_device_struc   ENDS

data    SEGMENT byte public 'DATA'

hid_section         section_typ <>
hid_key_sel         DW ?
hid_mouse_sel       DW ?
hid_dev_list        DW ?
hid_key_thread      DW ?

hid_key_leds        DB ?
hid_key_mod         DB ?
hid_key_arr         DB 6 DUP(?)

hid_last_key        DB ?
hid_last_time       DD ?

data    ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

        assume cs:code

        .386p


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           CreateHidSel
;
;               description:    Creates a new HID device selector
;
;               Parameters:     BX      Controller #
;                       AL      Device address
;                       ES:DI   USB descriptor
;
;       Returns:        BX      HID selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateHidSel Proc near
    push fs
;    
    push es
    push ax
    mov eax,SIZE hid_device_struc
    AllocateSmallGlobalMem
    pop ax
;
    mov es:hid_controller,bx
    mov es:hid_device,al
    mov bx,es
    mov fs,bx
    pop es
;    
    pop fs    
    ret
CreateHidSel Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           FreeHidSel
;
;               description:    Free HID device selector
;
;               Parameters:     BX      HID selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeHidSel Proc near
    push es
    push ax
;
    mov es,bx
    mov bx,es:hid_control_handle
    CloseUsbPipe    
;
    mov bx,es:hid_intr_handle
    CloseUsbPipe    
;    
    mov bx,es:hid_control_wait
    CloseWait
;   
    FreeMem
;
    pop ax
    pop es        
    ret
FreeHidSel Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           InitHidSel
;
;               description:    Init hid descriptor
;
;               Parameters:     ES:DI   First interface descriptor for device
;                       BX      Hid sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitHidSel Proc near
    push ds
    push ax
    push bx
    push dx
    push si
    push di
    mov ds,bx
;
    xor si,si
    mov ds:hid_intr_in,0
    mov ds:hid_interface,0
    mov ds:hid_protocol,0
    mov ds:hid_country_code,0
    mov ds:hid_descr_count,0

ihsCheckClass:
    mov si,di
    mov al,es:[di].uid_sub_class
    cmp al,1
    jne ihsCheckNext
    jmp ihsFound

ihsCheckLoop: 
    mov al,es:[di].ucd_type
    cmp al,4
    jne ihsCheckNext
;    
    mov al,es:[di].uid_class
    cmp al,3
    je ihsCheckClass

ihsCheckNext:
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb ihsCheckLoop
;
    or si,si
    jne ihsFound    
    jmp ihsDone

ihsFound:
    mov al,es:[di].uid_id
    mov ds:hid_interface,al
    mov al,es:[di].uid_proto
    mov ds:hid_protocol,al

ihsDescrLoop:    
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jnb ihsDone
;    
    mov al,es:[di].ucd_type
    cmp al,21h
    je ihsHidDescr
;      
    cmp al,5
    je ihsEndDescr
;
    jmp ihsDone

ihsHidDescr:
    mov al,es:[di].uhd_country_code
    mov ds:hid_country_code,al
    mov al,es:[di].uhd_descr_count
    mov ds:hid_descr_count,al    
    jmp ihsDescrLoop

ihsEndDescr:    
    mov al,es:[di].ued_attrib
    and al,3
    cmp al,3
    jne ihsDescrLoop
;
    mov al,es:[di].ued_address
    test al,80h
    jz ihsDescrLoop
;
    and al,8Fh    
    mov ds:hid_intr_in,al    
    jmp ihsDescrLoop

ihsDone:    
    mov bx,ds:hid_controller
    mov al,ds:hid_device
    xor dl,dl
    OpenUsbPipe
    mov ds:hid_control_handle,bx
;
    CreateWait
    mov ds:hid_control_wait,bx
;
    pop di
    pop si
    pop dx
    pop bx
    pop ax
    pop ds
    ret
InitHidSel  Endp        


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           GetHidSel
;
;               description:    Get HID device selector from controller and device
;
;               Parameters:     BX      Controller #
;                       AL      Device address
;
;       Returns:        NC
;                           BX      HID selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHidSel Proc near
    push ds
    push es
    push si
        push di
;
    mov di,SEG data
    mov ds,di
    EnterSection ds:hid_section
;
    mov di,ds:hid_dev_list
    or di,di
    jz ghsFail

ghsCheck:
    mov es,di
    cmp al,es:hid_device
    jne ghsNext
;
    cmp bx,es:hid_controller
    je ghsOk

ghsNext:
    mov di,es:hid_next    
    cmp di,ds:hid_dev_list
    jne ghsCheck

ghsFail:
    stc
    jmp ghsDone 

ghsOk:
    mov bx,es
    clc

ghsDone:   
    LeaveSection ds:hid_section
;    
    pop di
    pop si
    pop es
    pop ds
    ret
GetHidSel   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           InsertHidSel
;
;               description:    Inserts a HID device selector into list of devices
;
;               Parameters:     BX      HID selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertHidSel    Proc near
    push ds
    push es
    push ax
        push di
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:hid_section
;
    mov es,bx
        mov di,ds:hid_dev_list
        or di,di
        je ins_hid_sel_empty
;
        push ds
        push si
        mov ds,di
        mov si,ds:hid_prev
        mov ds:hid_prev,es
        mov ds,si
        mov ds:hid_next,es
        mov es:hid_next,di
        mov es:hid_prev,si
        pop si
        pop ds
        jmp ins_hid_sel_leave
        
ins_hid_sel_empty:
        mov es:hid_next,es
        mov es:hid_prev,es
        mov ds:hid_dev_list,es

ins_hid_sel_leave:
    LeaveSection ds:hid_section
;
    pop di
    pop ax
    pop es
    pop ds
    ret
InsertHidSel Endp       


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   RemoveHidSel
;
;               DESCRIPTION:    Remove a HID device selector
;
;               PARAMETERS:         BX      HID device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveHidSel    Proc near
    push ds
    push es
    push ax
        push si
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:hid_section
;
    mov es,bx
    cmp bx,es:hid_next
        je rem_hid_sel_empty
;       
        push di
        push ds
        mov di,es:hid_next
        mov ds:hid_dev_list,di
        mov si,es:hid_prev
        mov ds,di
        mov ds:hid_prev,si
        mov ds,si
        mov ds:hid_next,di
        pop ds
        pop di
        jmp rem_hid_sel_leave

rem_hid_sel_empty:      
        mov ds:hid_dev_list,0

rem_hid_sel_leave:
    LeaveSection ds:hid_section
        pop si
    pop ax
    pop es
    pop ds 
    ret
RemoveHidSel Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           GetReport
;
;               Description:    Get current input report
;
;       Parameters:     BX      HID selector
;
;       Returns:        ES      8-byte report data
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetReport   Proc near
    push ds
    push bx
    push cx
    push edx
    push di
;    
    mov ds,bx
    mov eax,8
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,0A1h
    mov es:usd_req,1
    mov es:usd_value,100h
    movzx ax,ds:hid_interface
    mov es:usd_index,ax
    mov es:usd_len,8
    xor di,di
    mov bx,ds:hid_control_handle
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
;
    mov cx,8
    ReqUsbData
;        
    WriteUsbStatus
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:hid_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hid_control_handle
    WasUsbTransactionOk
;    
    pushf
    UnlockUsbPipe
    popf
;
    pop di
    pop edx
    pop cx
    pop bx
    pop ds    
    ret
GetReport Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           GetProtocol
;
;               Description:    Get active protocol
;
;       Paramters:      BX      HID selector
;
;       RETURNS:        AL      Protocol
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetProtocol   Proc near
    push ds
    push es
    push bx
    push cx
    push edx
    push di
;    
    mov ds,bx
    mov eax,SIZE usb_setup_data + 1
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,0A1h
    mov es:usd_req,3
    mov es:usd_value,0
    movzx ax,ds:hid_interface
    mov es:usd_index,ax
    mov es:usd_len,1
    xor di,di
    mov bx,ds:hid_control_handle
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
;
    mov cx,1
    xor di,di
    ReqUsbData
;        
    WriteUsbStatus
    StartUsbTransaction
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:hid_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hid_control_handle
    WasUsbTransactionOk
    mov al,-1
    jc gpDone
;
    xor di,di
    mov al,es:[di]
    clc
    
gpDone:    
    pushf
    FreeMem
    UnlockUsbPipe
    popf
;
    pop di
    pop edx
    pop cx
    pop bx
    pop es
    pop ds    
    ret
GetProtocol Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SetBootProtocol
;
;               Description:    Set boot protocol
;
;       Paramters:      BX      HID selector
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetBootProtocol   Proc near
    push ds
    push es
    push eax
    push bx
    push cx
    push edx
    push di
;    
    mov ds,bx
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,21h
    mov es:usd_req,0Bh
    mov es:usd_value,0
    movzx ax,ds:hid_interface
    mov es:usd_index,ax
    mov es:usd_len,0
    xor di,di
    mov bx,ds:hid_control_handle
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    StartUsbTransaction
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:hid_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hid_control_handle
    WasUsbTransactionOk
    pushf
    UnlockUsbPipe
    popf
;
    pop di
    pop edx
    pop cx
    pop bx
    pop eax
    pop es
    pop ds    
    ret
SetBootProtocol Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SetIdle
;
;               Description:    Set idle to suitable range for auto-repeat of keys
;
;       Paramters:      BX      HID selector
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetIdle   Proc near
    push ds
    push es
    push eax
    push bx
    push cx
    push edx
    push di
;    
    mov ds,bx
    mov eax,SIZE usb_setup_data
    AllocateSmallGlobalMem
    mov cx,ax
    mov es:usd_type,21h
    mov es:usd_req,0Ah
    mov es:usd_value,0C00h  ; 12 * 4ms = 48ms (20 chars per second)
    movzx ax,ds:hid_interface
    mov es:usd_index,ax
    mov es:usd_len,0
    xor di,di
    mov bx,ds:hid_control_handle
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
    ReqUsbStatus
    StartUsbTransaction
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:hid_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hid_control_handle
    WasUsbTransactionOk
    pushf
    UnlockUsbPipe
    popf
;
    pop di
    pop edx
    pop cx
    pop bx
    pop eax
    pop es
    pop ds    
    ret
SetIdle Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           UpdateLeds
;
;               Description:    Update keyboard LEDs
;
;       Paramters:      AL      LED status
;      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLeds   Proc near
    push ds
    push es
    push eax
    push bx
    push cx
    push edx
    push di
;    
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:hid_key_sel
    or bx,bx
    jz ulDone
;
    mov ds,bx
    push ax
    mov eax,SIZE usb_setup_data + 1
    AllocateSmallGlobalMem
    mov cx,ax
    pop ax
    mov di,SIZE usb_setup_data
    stosb
;    
    mov es:usd_type,21h
    mov es:usd_req,9
    mov es:usd_value,200h
    movzx ax,ds:hid_interface
    mov es:usd_index,ax
    mov es:usd_len,1
;   
    xor di,di
    mov bx,ds:hid_control_handle
;
    LockUsbPipe
    mov cx,8
    WriteUsbControl
;
    mov di,SIZE usb_setup_data
    mov cx,1
    WriteUsbData
;        
    ReqUsbStatus
    StartUsbTransaction
    FreeMem
;    
    GetSystemTime
    add eax,1193 * 1000
    adc edx,0
    mov bx,ds:hid_control_wait
    WaitWithTimeout
;    
    mov bx,ds:hid_control_handle
    WasUsbTransactionOk
    pushf
    UnlockUsbPipe
    popf

ulDone:
    pop di
    pop edx
    pop cx
    pop bx
    pop eax
    pop es
    pop ds    
    ret
UpdateLeds Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   GetKey
;
;               DESCRIPTION:    Get key
;
;       PARAMETERS:     AL      Scan code
;                       DL      Virtual key code
;                       DH      Scan code
;                       CX      Shift states
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetKey   Proc near
    test cx,ctrl_pressed
    jz gkNotCtrl
;
        mov ah,cs:[si].ts_ctrl
        cmp ah,-1
    jne gkCheck

gkNotCtrl:
    test cx,alt_pressed
    jz gkNotAlt
;
        mov ah,cs:[si].ts_alt
        cmp ah,-1
    jne gkCheck

gkNotAlt:
    test cx,shift_pressed
    jz gkNotShift
;
        mov ah,cs:[si].ts_shift
        cmp ah,-1
    jne gkCheck

gkNotShift:
        mov ah,cs:[si].ts_norm

gkCheck:
        or ah,ah
        jne gkNoExt
;
        movzx ax,byte ptr cs:[si].ts_ext
        
gkNoExt:
    clc
    ret
GetKey   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   IgnoreKey
;
;               DESCRIPTION:    Ignore key (not defined)
;
;       PARAMETERS:     AL      USB key
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IgnoreKey   Proc near
    xor ax,ax
    ret
IgnoreKey   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   StdKey
;
;               DESCRIPTION:    Handle standard key
;
;       PARAMETERS:     AL      USB key
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StdKey   Proc near
    push cx
    GetKeyboardState
    mov cx,ax
    mov al,dh
    call GetKey
    pop cx
    ret
StdKey   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CapsKey
;
;               DESCRIPTION:    Handle caps-lock aware key
;
;       PARAMETERS:     AL      USB key
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CapsKey   Proc near
    push cx
    GetKeyboardState
    mov cx,ax
        and cx,107h
        xor cl,ch
        and cx,7
    mov al,dh
    call GetKey
    pop cx
    ret
CapsKey   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   FuncKey
;
;               DESCRIPTION:    Handle function key
;
;       PARAMETERS:     AL      USB key
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FuncKey   Proc near
    push cx
    GetKeyboardState
    mov cx,ax
        test cx,ctrl_pressed
        jz fkNorm
;
    mov al,dh
    SetFocus
    xor ax,ax
    jmp fkDone
        
fkNorm:
    mov al,dh
    call GetKey
    xor ah,ah

fkDone:
    pop cx
    ret
FuncKey   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NumKey
;
;               DESCRIPTION:    Handle numpad key
;
;       PARAMETERS:     AL      USB key
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NumKey   Proc near
    push cx
    push si
;
    GetKeyboardState
    mov cx,ax
    mov al,dh
;
        and cx,205h
        shr ch,1
        xor cl,ch
        xor ch,ch
        add si,cx
        cmp cx,1
        jne nkNoNum
;
        mov ah,cs:[si].ts_norm
        jmp nkEnd
        
nkNoNum:
        movzx ax,byte ptr cs:[si].ts_norm

nkEnd:
    pop si
    pop cx
    ret
NumKey   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   DelKey
;
;               DESCRIPTION:    Handle DEL key on numpad
;
;       PARAMETERS:     AL      USB key
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DelKey   Proc near
    push cx
    GetKeyboardState
    mov cx,ax
;
        and cx,alt_pressed OR ctrl_pressed
        cmp cx,alt_pressed OR ctrl_pressed
        jne dkNum
;
    CpuReset

dkNum:
    pop cx
    call NumKey
    ret
DelKey  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   CapsLock
;
;               DESCRIPTION:    Handle caps lock key
;
;       PARAMETERS:     AL      USB key
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CapsLock   Proc near
    push cx
;    
    GetKeyboardState
    xor ax,caps_active
    SetKeyboardState
    xor ax,ax
;
    pop cx    
    ret
CapsLock   Endp
    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   NumLock
;
;               DESCRIPTION:    Handle num lock key
;
;       PARAMETERS:     AL      USB key
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;                       CS:SI   Table entry
;
;       RETURNS:        AX      Key code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NumLock   Proc near
    push cx
;    
    GetKeyboardState
    xor ax,num_active
    SetKeyboardState
    xor ax,ax
;
    pop cx    
    ret
NumLock   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   TranslateKey
;
;               DESCRIPTION:    Translate key to RDOS internal key mappings
;
;       PARAMETERS:     AL      USB key
;
;       RETURNS:        AX      Key code
;                       DL      Virtual key code
;                       DH      Scan code
;                       CL      Action code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ActionTab:
at0 DW OFFSET IgnoreKey
at1 DW OFFSET StdKey
at2 DW OFFSET CapsKey
at3 DW OFFSET FuncKey
at4 DW OFFSET NumKey
at5 DW OFFSET DelKey
at6 DW OFFSET IgnoreKey
at7 DW OFFSET IgnoreKey

TranslateTab:
;           Ext     VK      Scan     Normal Shift   Alt     Ctrl    Action   Key descr
tk00    DB  0,      0,      0,       0,     0,      0,      0,      0        ; No key
tk01    DB  0,      0,      0,       0,         0,      0,      0,              0        ; Roll-over error
tk02    DB  0,      0,      0,       0,         0,      0,      0,              0        ; Post fail
tk03    DB  0,      0,      0,       0,         0,      0,      0,              0        ; Undefined error
tk04    DB  1Eh,    'A',    1Eh,     'a',   'A',    0,      -1,     CAPS_KEY ; VK_A
tk05    DB  30h,    'B',    30h,     'b',   'B',    0,      2,          CAPS_KEY ; VK_B
tk06    DB  2Eh,    'C',    2Eh,     'c',   'C',    0,      3,          CAPS_KEY ; VK_C
tk07    DB  20h,    'D',    20h,     'd',       'D',    0,      4,              CAPS_KEY ; VK_D
tk08    DB  12h,    'E',    12h,     'e',       'E',    0,      5,              CAPS_KEY ; VK_E
tk09    DB  21h,    'F',    21h,     'f',       'F',    0,      6,              CAPS_KEY ; VK_F
tk0A    DB  22h,    'G',    22h,     'g',       'G',    0,      7,              CAPS_KEY ; VK_G
tk0B    DB  23h,    'H',    23h,     'h',       'H',    0,      8,              CAPS_KEY ; VK_H
tk0C    DB  17h,    'I',    17h,     'i',       'I',    0,      9,              CAPS_KEY ; VK_I
tk0D    DB  24h,    'J',    24h,     'j',       'J',    0,      0Ah,    CAPS_KEY ; VK_J
tk0E    DB  25h,    'K',    25h,     'k',       'K',    0,      0Bh,    CAPS_KEY ; VK_K
tk0F    DB  26h,    'L',    26h,     'l',       'L',    0,      0Ch,    CAPS_KEY ; VK_L
tk10    DB  32h,    'M',    32h,     'm',       'M',    0,      0Dh,    CAPS_KEY ; VK_M
tk11    DB  31h,    'N',    31h,     'n',       'N',    0,      0Eh,    CAPS_KEY ; VK_N
tk12    DB  18h,    'O',    18h,     'o',       'O',    0,      0Fh,    CAPS_KEY ; VK_O
tk13    DB  19h,    'P',    19h,     'p',       'P',    0,      10h,    CAPS_KEY ; VK_P
tk14    DB  10h,    'Q',    10h,     'q',       'Q',    0,      11h,    CAPS_KEY ; VK_Q
tk15    DB  13h,    'R',    13h,     'r',       'R',    0,      12h,    CAPS_KEY ; VK_R
tk16    DB  1Fh,    'S',    1Fh,     's',       'S',    0,      13h,    CAPS_KEY ; VK_S
tk17    DB  14h,    'T',    14h,     't',       'T',    0,      14h,    CAPS_KEY ; VK_T
tk18    DB  16h,    'U',    16h,     'u',       'U',    0,      15h,    CAPS_KEY ; VK_U
tk19    DB  2Fh,    'V',    2Fh,     'v',       'V',    0,      16h,    CAPS_KEY ; VK_V
tk1A    DB  11h,    'W',    11h,     'w',       'W',    0,      17h,    CAPS_KEY ; VK_W
tk1B    DB  2Dh,    'X',    2Dh,     'x',       'X',    0,      18h,    CAPS_KEY ; VK_X
tk1C    DB  15h,    'Y',    15h,     'y',       'Y',    0,      19h,    CAPS_KEY ; VK_Y
tk1D    DB  2Ch,    'Z',    2Ch,     'z',       'Z',    0,      1Ah,    CAPS_KEY ; VK_Z
tk1E    DB  78h,    '1',    02h,     '1',       '!',    -1,     -1,             STD_KEY  ; VK_1
tk1F    DB  79h,    '2',    03h,     '2',       22h,   '@',    -1,              STD_KEY  ; VK_2
tk20    DB  7Ah,    '3',    04h,     '3',       '#',    'ú',    -1,             STD_KEY  ; VK_3
tk21    DB  7Bh,    '4',    05h,     '4',       'œ',    '$',    -1,             STD_KEY  ; VK_4
tk22    DB  7Ch,    '5',    06h,     '5',       '%',    -1,     -1,             STD_KEY  ; VK_5
tk23    DB  7Dh,    '6',    07h,     '6',       '&',    -1,     -1,             STD_KEY  ; VK_6
tk24    DB  7Eh,    '7',    08h,     '7',       '/',    '{',    -1,             STD_KEY  ; VK_7
tk25    DB  7Fh,    '8',    09h,     '8',       '(',    '[',    -1,             STD_KEY  ; VK_8
tk26    DB  80h,    '9',    0Ah,     '9',       ')',    ']',    -1,             STD_KEY  ; VK_9
tk27    DB  81h,    '0',    0Bh,     '0',       '=',    '}',    -1,             STD_KEY  ; VK_0
tk28    DB  -1,     0Dh,    1Ch,     0Dh,       0Dh,    0Dh,    0Ah,    STD_KEY  ; VK_RETURN
tk29    DB  -1 ,    1Bh,    01h,     1Bh,       1Bh,    1Bh,    1Bh,    STD_KEY  ; VK_ESCAPE
tk2A    DB  -1,     08h,    0Eh,     08h,       08h,    08h,    08h,    STD_KEY  ; VK_BACK
tk2B    DB  0Fh,    09h,    0Fh,     09h,       0,      09h,    09h,    STD_KEY  ; VK_TAB
tk2C    DB  -1,     ' ',    39h,     ' ',   ' ',    ' ',    ' ',    STD_KEY      ; VK_SPACE
tk2D    DB  -1,     '-',    0Ch,     '-',       '_',    -1,     -1,             STD_KEY  ; -, _
tk2E    DB  -1,     0DBh,   0Dh,     27h,       60h,    -1,     -1,             STD_KEY  ; =, + 
tk2F    DB  -1,     0DDh,   1Ah,     'Ü',       'è',    0,      -1,             CAPS_KEY ; [, {
tk30    DB  -1,     0BAh,   1Bh,     '\',       '^',    '~',    -1,             STD_KEY  ; ], }
tk31    DB  -1,     '\',    2Bh,     '\',       '|',    -1,     -1,             STD_KEY  ; \, |
tk32    DB  -1,     2Bh,    2Bh,     27h,       '*',    -1,     -1,             STD_KEY  ; #, ~
tk33    DB  -1,     0C0h,   27h,     'î',       'ô',    0,      -1,             CAPS_KEY ; ;, :
tk34    DB  -1,     0DEh,   28h,     'Ñ',   'é',    0,      -1,         CAPS_KEY ;
tk35    DB  -1,     0DCh,   29h,     '¯',       '´',    0,      -1,             STD_KEY  ;
tk36    DB  -1,     ',',    33h,     ',',       ';',    -1,     -1,             STD_KEY  ; ;, <
tk37    DB  -1,     0BEh,   34h,     '.',       ':',    -1,     -1,             STD_KEY  ; . >
tk38    DB  -1,     0BDh,   35h,     '-',       '_',    -1,     -1,             STD_KEY  ; /, ?
tk39    DB  -1,     14h,    3Ah,     0,     0,      0,      0,      CAPS_LOCK; VK_CAPITAL
tk3A    DB  70h,    70h,    3Bh,     3Bh,       54h,    68h,    5Eh,    FUNC_KEY ; VK_F1
tk3B    DB  71h,    71h,    3Ch,     3Ch,       55h,    69h,    5Fh,    FUNC_KEY ; VK_F2
tk3C    DB  72h,    72h,    3Dh,     3Dh,       56h,    6Ah,    60h,    FUNC_KEY ; VK_F3
tk3D    DB  73h,    73h,    3Eh,     3Eh,       57h,    6Bh,    61h,    FUNC_KEY ; VK_F4
tk3E    DB  74h,    74h,    3Fh,     3Fh,       58h,    6Ch,    62h,    FUNC_KEY ; VK_F5
tk3F    DB  75h,    75h,    40h,     40h,       59h,    6Dh,    63h,    FUNC_KEY ; VK_F6
tk40    DB  76h,    76h,    41h,     41h,       5Ah,    6Eh,    64h,    FUNC_KEY ; VK_F7
tk41    DB  77h,    77h,    42h,     42h,       5Bh,    6Fh,    65h,    FUNC_KEY ; VK_F8
tk42    DB  78h,    78h,    43h,     43h,       5Ch,    70h,    66h,    FUNC_KEY ; VK_F9
tk43    DB  79h,    79h,    44h,     44h,       5Dh,    71h,    67h,    FUNC_KEY ; VK_F10
tk44    DB  7Ah,    7Ah,    57h,     57h,       5Eh,    8Bh,    89h,    FUNC_KEY ; VK_F11
tk45    DB  7Bh,    7Bh,    58h,     58h,       5Fh,    8Ch,    8Ah,    FUNC_KEY ; VK_F12
tk46    DB  -1,     2Ah,    0,       0,     0,      0,      0,          0                ; VK_PRINT
tk47    DB  -1,     91h,    46h,     0,     0,      0,      0,      STD_KEY  ; VK_SCROLL
tk48    DB  -1,     13h,    0,       0,     0,      0,      0,          0                ; VK_PAUSE
tk49    DB  -1,     2Dh,    52h,     52h,   52h,    -1,     -1,         STD_KEY  ; VK_INSERT
tk4A    DB  -1,     24h,    47h,     47h,       47h,    -1,     -1,             STD_KEY  ; VK_HOME
tk4B    DB  -1,     26h,    49h,     49h,       49h,    -1,     -1,         STD_KEY  ; VK_UP (page up)
tk4C    DB  -1,     2Eh,    53h,     53h,       53h,    -1,     -1,             DEL_KEY  ; VK_DELETE
tk4D    DB  -1,     23h,    4Fh,     4Fh,       4Fh,    -1,     -1,             STD_KEY  ; VK_END
tk4E    DB  -1,     28h,    51h,     51h,       51h,    -1,     -1,             STD_KEY  ; VK_DOWN (page down)
tk4F    DB  -1,     27h,    4Dh,     4Dh,       4Dh,    -1,     -1,             STD_KEY  ; VK_RIGHT
tk50    DB  -1,     25h,    4Bh,     4Bh,       4Bh,    -1,     -1,             STD_KEY  ; VK_LEFT
tk51    DB  -1,     28h,    50h,     50h,       50h,    -1,     -1,             STD_KEY  ; VK_DOWN
tk52    DB  -1,     26h,    48h,     48h,       48h,    -1,     -1,             STD_KEY  ; VK_UP
tk53    DB  -1,     90h,    45h,     0,     0,      0,      0,      NUM_LOCK ; VK_NUMLOCK
tk54    DB  -1,     6Fh,    35h,     '/',       '/',    '/',    -1,             STD_KEY  ; VK_DIVIDE
tk55    DB  -1,     6Ah,    37h,     '*',       '*',    '*',    -1,             STD_KEY  ; VK_MULTIPLY  
tk56    DB  -1,     6Dh,    4Ah,     '-',       '-',    '-',    -1,             STD_KEY  ; VK_SUBTRACT
tk57    DB  -1,     6Bh,    4Eh,     '+',       '+',    '+',    -1,             STD_KEY  ; VK_ADD
tk58    DB  0Dh,    0Dh,    0Dh,     0Dh,       0Dh,    0Dh,    0Ah,    STD_KEY  ; ENTER
tk59    DB  -1,     61h,    4Fh,     4Fh,       '1',    -1,     75h,    NUM_KEY  ; VK_NUMPAD1
tk5A    DB  -1,     62h,    50h,     50h,       '2',    -1,     -1,             NUM_KEY  ; VK_NUMPAD2
tk5B    DB  -1,     63h,    51h,     51h,       '3',    -1,     76h,    NUM_KEY  ; VK_NUMPAD3
tk5C    DB  -1,     64h,    4Bh,     4Bh,       '4',    -1,     73h,    NUM_KEY  ; VK_NUMPAD4
tk5D    DB  -1,     65h,    4Ch,     '5',       '5',    -1,     -1,             NUM_KEY  ; VK_NUMPAD5
tk5E    DB  -1,     66h,    4Dh,     4Dh,       '6',    -1,     74h,    NUM_KEY  ; VK_NUMPAD6
tk5F    DB  -1,     67h,    47h,     47h,       '7',    -1,     77h,    NUM_KEY  ; VK_NUMPAD7
tk60    DB  -1,     68h,    48h,     48h,       '8',    -1,     -1,             NUM_KEY  ; VK_NUMPAD8
tk61    DB  -1,     69h,    49h,     49h,       '9',    -1,     84h,    NUM_KEY  ; VK_NUMPAD9
tk62    DB  -1,     60h,    52h,     52h,       '0',    -1,     -1,             NUM_KEY  ; VK_NUMPAD0
tk63    DB  -1,     6Eh,    53h,     53h,       '-',    -1,     -1,             DEL_KEY  ; VK_DECIMAL
tk64    DB  -1,     0E2h,   56h,     '<',       '>',    '|',    -1,             STD_KEY  ; <>|
tk65    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk66    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk67    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk68    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk69    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk6A    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk6B    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk6C    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk6D    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk6E    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk6F    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk70    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk71    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk72    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk73    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk74    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk75    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk76    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk77    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk78    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk79    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk7A    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk7B    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk7C    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk7D    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk7E    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk7F    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk80    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk81    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk82    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk83    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk84    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk85    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk86    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk87    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk88    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk89    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk8A    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk8B    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk8C    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk8D    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk8E    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk8F    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk90    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk91    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk92    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk93    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk94    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk95    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk96    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk97    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk98    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk99    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk9A    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk9B    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk9C    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk9D    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk9E    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tk9F    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA0    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA1    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA2    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA3    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA4    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA5    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA6    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA7    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA8    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkA9    DB  0,      0,      0,       0,     0,      0,      0,          0                ; 
tkAA    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkAB    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkAC    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkAD    DB  0,      0,      0,       0,     0,      0,      0,          0                ; 
tkAE    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkAF    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB0    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB1    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB2    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB3    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB4    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB5    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB6    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB7    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB8    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkB9    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkBA    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkBB    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkBC    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkBD    DB  0,      0,      0,       0,     0,      0,      0,          0                ; 
tkBE    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkBF    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC0    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC1    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC2    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC3    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC4    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC5    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC6    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC7    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC8    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkC9    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkCA    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkCB    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkCC    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkCD    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkCE    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkCF    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD0    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD1    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD2    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD3    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD4    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD5    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD6    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD7    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD8    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkD9    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkDA    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkDB    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkDC    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkDD    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkDE    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkDF    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE0    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE1    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE2    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE3    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE4    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE5    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE6    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE7    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE8    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkE9    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkEA    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkEB    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkEC    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkED    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkEE    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkEF    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF0    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF1    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF2    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF3    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF4    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF5    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF6    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF7    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF8    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkF9    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkFA    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkFB    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkFC    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkFD    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkFE    DB  0,      0,      0,       0,     0,      0,      0,          0                ;
tkFF    DB  0,      0,      0,       0,     0,      0,      0,          0                ;

TranslateKey    Proc near
    push bx
    push si
;    
    movzx si,al
    shl si,3
    add si,OFFSET TranslateTab
    mov dl,cs:[si].ts_vk
    mov dh,cs:[si].ts_scan
    mov cl,cs:[si].ts_action
    and cl,7
    movzx bx,cl
    add bx,bx
    call word ptr cs:[bx].ActionTab
;
    pop si
    pop bx
    ret
TranslateKey    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ReportKeyPress
;
;               DESCRIPTION:    Report a key is pressed
;
;       PARAMETERS:     AL      USB key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendPress   Proc near
    or ax,ax
    jz spDone
;
    PutKeyboardCode

spDone:
    ret
SendPress   Endp

PressTab:
ap0 DW OFFSET SendPress
ap1 DW OFFSET SendPress
ap2 DW OFFSET SendPress
ap3 DW OFFSET SendPress
ap4 DW OFFSET SendPress
ap5 DW OFFSET SendPress
ap6 DW OFFSET CapsLock
ap7 DW OFFSET NumLock

ReportKeyPress  Proc near
    push ax
    push bx
    push cx
    push dx
;
    call TranslateKey
    movzx bx,cl
    add bx,bx
    call word ptr cs:[bx].PressTab
;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ReportKeyPress  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   ReportKeyRelease
;
;               DESCRIPTION:    Report a key is release
;
;       PARAMETERS:     AL      USB key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IgnoreRelease   Proc near
    ret
IgnoreRelease   Endp

SendRelease   Proc near
    or ax,ax
    jz srDone
;
    or al,80h
    or dh,80h
    PutKeyboardCode

srDone:
    ret
SendRelease   Endp

ReleaseTab:
ar0 DW OFFSET SendRelease
ar1 DW OFFSET SendRelease
ar2 DW OFFSET SendRelease
ar3 DW OFFSET SendRelease
ar4 DW OFFSET SendRelease
ar5 DW OFFSET SendRelease
ar6 DW OFFSET IgnoreRelease
ar7 DW OFFSET IgnoreRelease

ReportKeyRelease  Proc near
    push ax
    push bx
    push cx
    push dx
;
    call TranslateKey
    movzx bx,cl
    add bx,bx
    call word ptr cs:[bx].ReleaseTab
;
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ReportKeyRelease  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   UpdateShiftState
;
;               DESCRIPTION:    Update shift-key state
;
;       PARAMETERS:     AL      Modifier keys
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateShiftState  Proc near
    push ax
    push bx
    push cx
;    
    mov bl,al
    GetKeyboardState
    mov cx,ax
    and ax,NOT (shift_pressed OR alt_pressed OR ctrl_pressed)
;     
    test bl,MOD_LEFT_CTRL OR MOD_RIGHT_CTRL
    jz ussCtrlOK
;
    or ax,ctrl_pressed

ussCtrlOk:
    test bl,MOD_LEFT_SHIFT OR MOD_RIGHT_SHIFT
    jz ussShiftOk
;
    or ax,shift_pressed

ussShiftOk:
    test bl,MOD_LEFT_ALT OR MOD_RIGHT_ALT
    jz ussAltOk
;
    or ax,alt_pressed

ussAltOk: 
    cmp ax,cx
    je ussDone
;
    SetKeyboardState
;
    xor cx,ax
    test cx,shift_pressed
    jz ussShiftDone
;
    mov dl,10h
    mov dh,2Ah
    test ax,shift_pressed
    jz ussShiftRel

ussShiftPress:
    push ax
    xor ax,ax
    PutKeyboardCode
    pop ax
    jmp ussShiftDone

ussShiftRel:
    push ax
    or dh,80h
    mov ax,80h
    PutKeyboardCode
    pop ax

ussShiftDone:
    test cx,alt_pressed
    jz ussAltDone
;
    mov dl,12h
    mov dh,38h
    test ax,alt_pressed
    jz ussAltRel

ussAltPress:
    push ax
    xor ax,ax
    PutKeyboardCode
    pop ax
    jmp ussAltDone

ussAltRel:
    push ax
    or dh,80h
    mov ax,80h
    PutKeyboardCode
    pop ax

ussAltDone:
    test cx,ctrl_pressed
    jz ussDone
;
    mov dl,11h
    mov dh,1Dh
    test ax,ctrl_pressed
    jz ussCtrlRel

ussCtrlPress:
    push ax
    xor ax,ax
    PutKeyboardCode
    pop ax
    jmp ussDone

ussCtrlRel:
    push ax
    or dh,80h
    mov ax,80h
    PutKeyboardCode
    pop ax

ussDone:
    pop cx
    pop bx
    pop ax    
    ret
UpdateShiftState    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               HandlePressed
;
;               DESCRIPTION:    Handle newly pressed keys
;
;       PARAMETERS:     ES      USB report
;                       FS      HID data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePressed  Proc near
    push cx
    push si
    push di
;
    mov si,OFFSET hk_key_arr
    mov cx,6

hpLoop:
    mov al,es:[si]
    or al,al
    jz hpDone
;
    push cx
    mov di,OFFSET hid_key_arr
    mov cx,6

hpFindLoop:
    mov ah,fs:[di]
    or ah,ah
    je hpNew
;
    cmp al,ah
    je hpNext
;
    inc di
    loop hpFindLoop

hpNew:
    push eax
    push edx
    GetSystemTime
    mov fs:hid_last_time,eax
    pop edx
    pop eax
;
    mov fs:hid_last_key,al
    call ReportKeyPress

hpNext:
    pop cx
    inc si
    loop hpLoop

hpDone:
    pop di
    pop si
    pop cx
    ret
HandlePressed  Endp    
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   HandleReleased
;
;               DESCRIPTION:    Handle newly released keys
;
;       PARAMETERS:     ES      USB report
;                       FS      HID data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleReleased  Proc near
    push cx
    push si
    push di
;
    mov si,OFFSET hid_key_arr
    mov cx,6

hrLoop:
    mov al,fs:[si]
    or al,al
    jz hrDone
;
    push cx
    mov di,OFFSET hk_key_arr
    mov cx,6

hrFindLoop:
    mov ah,es:[di]
    or ah,ah
    je hrNew
;
    cmp al,ah
    je hrNext
;
    inc di
    loop hrFindLoop

hrNew:
    cmp al,fs:hid_last_key
    jne hrReport
;
    mov fs:hid_last_key,0

hrReport:    
    call ReportKeyRelease

hrNext:
    pop cx
    inc si
    loop hrLoop

hrDone:
    pop di
    pop si
    pop cx
    ret
HandleReleased  Endp    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   HandleKeyReport
;
;               DESCRIPTION:    Handles keyboard report
;
;       PARAMETERS:     ES      USB report
;                       FS      HID data sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleKeyReport Proc near
    mov cx,6
    xor si,si
    xor di,di

hkpCompLoop:
    mov al,es:[si].hk_key_arr
    cmp al,fs:[di].hid_key_arr
    jne hkpChanged
;
    or al,al
    jz hkpRepeat
;
    inc si
    inc di
    loop hkpCompLoop
;
    jmp hkpDone    

hkpChanged:
    call HandleReleased
    call HandlePressed
;    
    mov cx,6
    xor si,si
    xor di,di

hkpCopyLoop:
    mov al,es:[si].hk_key_arr
    mov fs:[di].hid_key_arr,al
    inc si
    inc di
    loop hkpCopyLoop

hkpRepeat:
    mov al,fs:hid_last_key
    or al,al
    jz hkpDone
;
    mov al,fs:hid_key_arr
    or al,al
    jz hkpDone
;
    GetSystemTime
    sub eax,fs:hid_last_time
    cmp eax,1193 * 500
    jc hkpDone
;
    mov al,fs:hid_last_key
    call ReportKeyPress

hkpDone:
    ret
HandleKeyReport Endp   


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   HidKeyThread
;
;               DESCRIPTION:    USB keyboard handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_key_thread_name  DB 'USB Keyboard', 0

hid_key_thread_pr  Proc far
    mov ax,SEG data
    mov fs,ax
    GetThread
    mov fs:hid_key_thread,ax
;    
    mov ax,fs:hid_key_sel
    or ax,ax
    jz hktDone
;
    mov al,3
    call UpdateLeds    
    mov fs:hid_key_leds,al
;
    mov ax,200
    WaitMilliSec
;
    mov ax,fs:hid_key_sel
    or ax,ax
    jz hktDone
;    
    mov ds,ax    
    mov bx,ds:hid_controller
    mov al,ds:hid_device
    mov dl,ds:hid_intr_in
    OpenUsbPipe
    mov ds:hid_intr_handle,bx
;
    mov eax,8
    AllocateSmallGlobalMem
    mov ds:hid_intr_buf,es
    mov cx,ax
    CreateUsbReq
    mov ds:hid_intr_req,bx
    AddReadUsbDataReq
    xor ax,ax
    mov es,ax

hktDataLoop:
    mov ax,fs:hid_key_sel
    or ax,ax
    jz hktExit
;            
    GetKeyboardState
    mov cx,ax
    xor al,al
    test cx,num_active
    jz hktNumOk
;
    or al,1

hktNumOk:
    test cx,caps_active
    jz hktCapsOk
;
    or al,2

hktCapsOk:
    cmp al,fs:hid_key_leds
    je hktLedsOK
;    
    mov fs:hid_key_leds,al
    mov al,fs:hid_key_leds
    call UpdateLeds

hktLedsOk:
    GetThread
    StartUsbReq
    WaitForSignal
;       
    IsUsbReqReady
    jc hktDataLoop
;    
    GetUsbReqData
    cmp cx,8
    jne hktDataLoop
;
    push es
    mov es,ds:hid_intr_buf
    mov al,es:hk_modifiers
    cmp al,fs:hid_key_mod
    je hktModHandled
;
    mov fs:hid_key_mod,al
    call UpdateShiftState

hktModHandled:
    call HandleKeyReport
    pop es
    jmp hktDataLoop

hktExit:
    xor ax,ax
    mov es,ax
    mov bx,ds:hid_intr_req
    CloseUsbReq
    mov ds:hid_intr_req,0
    mov ds:hid_intr_buf,0
;
    mov bx,ds:hid_intr_handle
    CloseUsbPipe    
    mov ds:hid_intr_handle,0
    
hktDone:
    mov fs:hid_key_mod,0
    mov fs:hid_key_arr,0
    mov fs:hid_key_thread,0
    ret
hid_key_thread_pr  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           SetupBoot
;
;               description:    Setups boot device for keyboard or mouse
;
;               Parameters:     BX      HID selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBootInvalid    Proc near
    stc
    ret
SetupBootInvalid    Endp

SetupBootKeyboard    Proc near
    mov ds:hid_key_sel,bx
    call SetBootProtocol
    call SetIdle
;    
    mov ax,ds:hid_key_thread
    or ax,ax
    jnz sbkDone
;
        mov ds:hid_key_thread,-1
    push ds
    push es
    push cx
    push si
    push di
;    
        mov dx,cs
        mov ds,dx
        mov es,dx
        mov di,OFFSET hid_key_thread_name
        mov si,OFFSET hid_key_thread_pr
        mov ax,2
        mov cx,100h
        CreateThread
;
    pop di
    pop si
    pop cx
    pop es
    pop ds

sbkDone:    
    ret
SetupBootKeyboard    Endp

SetupBootMouse    Proc near
    ret
SetupBootMouse    Endp

SetupBootTab:
sbt00   DW OFFSET SetupBootInvalid
sbt01   DW OFFSET SetupBootKeyboard
sbt02   DW OFFSET SetupBootMouse

SetupBoot       Proc near
    push ds
    push es
    push ax
    push dx
;
    mov ax,SEG data
    mov ds,ax
    mov es,bx
    mov al,es:hid_protocol
    or al,al
    jz sbDone
;
    cmp al,3
    jae sbDone
;    
    movzx di,es:hid_protocol
    add di,di
    call word ptr cs:[di].SetupBootTab

sbDone:
    pop dx
    pop ax
    pop es
    pop ds
    ret
SetupBoot   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:           usb_attach
;
;               description:    USB attach callback
;
;               Parameters:     BX      Controller #
;                       AL      Device address
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
    or cl,cl
    je uaPossibleHid
;    
    cmp cl,3
    jne uaDone

uaPossibleHid:
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
    cmp cl,3
    je uaFound

uaCheckNext:
    movzx cx,es:[di].ucd_len
    add di,cx
    cmp di,es:ucd_size
    jb uaCheckLoop
    jmp uaDone

uaFound:
    ConfigUsbDevice
    call CreateHidSel
    call InitHidSel
    call SetupBoot
    call InsertHidSel

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
;               NAME:           usb_detach
;
;               description:    USB detach callback
;
;               Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    mov dx,SEG data
    mov ds,dx
;    
    call GetHidSel
    jc udDone
;
    cmp bx,ds:hid_key_sel
    jne udKeyOk
;
    mov ds:hid_key_sel,0
    mov ax,ds:hid_key_thread
        or ax,ax
        jz udKeyOk

udStopKey:
    push bx
    mov bx,ds:hid_key_thread
        Signal
    or bx,bx
    pop bx
    jz udKeyOk
;    
    mov ax,10
    WaitMilliSec
    jmp udStopKey       
        
udKeyOk:
    call RemoveHidSel
    call FreeHidSel
            
udDone:    
    popad
    pop es
    pop ds
    ret
usb_detach  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   init
;
;               description:    Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    Proc far
        mov bx,SEG data
    mov ds,bx
    InitSection ds:hid_section
;       
        mov ax,cs
        mov ds,ax
        mov es,ax
;
    mov di,OFFSET usb_attach
    HookUsbAttach
;
    mov di,OFFSET usb_detach
    HookUsbDetach
    clc
        ret
init    Endp

code    ENDS

        END init
