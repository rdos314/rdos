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
						
		NAME hid

GateSize = 16

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
include ..\os\usb.inc

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

hid_country_code    DB ?
hid_descr_count     DB ?

hid_device_struc   ENDS

hid_data STRUC

hid_section         section_typ <>
hid_thread          DW ?
hid_key_sel         DW ?
hid_mouse_sel       DW ?
hid_dev_list        DW ?
hid_has_key_hook    DB ?

hid_data ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386c

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        CreateHidSel
;
;		description:	Creates a new HID device selector
;
;		Parameters:     BX      Controller #
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        FreeHidSel
;
;		description:	Free HID device selector
;
;		Parameters:     BX      HID selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeHidSel Proc near
    push ds
    push es
    push ax
;
    mov ax,hid_data_sel
    mov ds,ax
    cmp bx,ds:hid_key_sel
    jne fhsKeyOk
;
    mov ds:hid_key_sel,0

fhsKeyOk:
    cmp bx,ds:hid_mouse_sel
    jne fhsMouseOk
;
    mov ds:hid_mouse_sel,0        

fhsMouseOk:
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
    pop ds
    ret
FreeHidSel Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        InitHidSel
;
;		description:	Init hid descriptor
;
;		Parameters:     ES:DI   First interface descriptor for device
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
    and al,7Fh    
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        GetHidSel
;
;		description:	Get HID device selector from controller and device
;
;		Parameters:     BX      Controller #
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
    mov di,hid_data_sel
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        InsertHidSel
;
;		description:	Inserts a HID device selector into list of devices
;
;		Parameters:     BX      HID selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertHidSel	Proc near
    push ds
    push es
    push ax
	push di
;
    mov ax,hid_data_sel
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RemoveHidSel
;
;		DESCRIPTION:	Remove a HID device selector
;
;		PARAMETERS:	    BX      HID device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveHidSel	Proc near
    push ds
    push es
    push ax
	push si
;
    mov ax,hid_data_sel
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        GetReport
;
;		Description:	Get current input report
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
    IsUsbPipeIdle
    cmc
    jc grDone
;
    mov cx,8
    xor edi,edi
    GetUsbData
    clc
    
grDone:    
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        GetProtocol
;
;		Description:	Get active protocol
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
    IsUsbPipeIdle
    cmc
    mov al,-1
    jc gpDone
;
    mov cx,1
    mov edi,SIZE usb_setup_data
    GetUsbData
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        SetBootProtocol
;
;		Description:	Set boot protocol
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
    IsUsbPipeIdle
    cmc
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        UpdateLeds
;
;		Description:	Update keyboard LEDs
;
;       Paramters:      BX      HID selector
;                       AL      LED status
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
    IsUsbPipeIdle
    cmc
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
UpdateLeds Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        HandleShiftChange
;
;		description:	Handle shift key change from keyboard(s)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleShiftChange   Proc far
    push ds
    push ax
    push bx
;    
    mov ax,hid_data_sel
    mov ds,ax
    mov bx,ds:hid_key_sel
    or bx,bx
    jz hscDone
;
    mov ds,bx
    GetKeyboardState
;

;0 = NUM
;1 = CAPS
    mov al,3
    call UpdateLeds    
    
hscDone:
    pop bx
    pop ax
    pop ds    
    ret
HandleShiftChange   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        SetupBoot
;
;		description:	Setups boot device for keyboard or mouse
;
;		Parameters:     BX      HID selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBootInvalid    Proc near
    stc
    ret
SetupBootInvalid    Endp

SetupBootKeyboard    Proc near
    mov ds:hid_key_sel,bx
    call SetBootProtocol
;
    push es
    call GetReport
    FreeMem
    pop es
;    
    mov al,ds:hid_has_key_hook
    or al,al
    jnz sbkNotify
    jmp sbkNotify       ; test only
;    
    inc ds:hid_has_key_hook
    push es
    push di    
    mov ax,cs
    mov es,ax
    mov di,OFFSET HandleShiftChange
    HookShiftKeys
    pop di
    pop es    

sbkNotify:    
    call HandleShiftChange
    clc
    ret
SetupBootKeyboard    Endp

SetupBootMouse    Proc near
    stc
    ret
SetupBootMouse    Endp

SetupBootTab:
sbt00   DW OFFSET SetupBootInvalid
sbt01   DW OFFSET SetupBootKeyboard
sbt02   DW OFFSET SetupBootMouse

SetupBoot	Proc near
    push ds
    push es
    push ax
    push dx
;
    mov ax,hid_data_sel
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
    jc sbDone
;    
    push bx
    mov bx,es:hid_controller
    mov al,es:hid_device
    mov dl,es:hid_intr_in
    OpenUsbPipe
    mov es:hid_intr_handle,bx
;
    mov eax,8
    AllocateSmallGlobalMem
    mov cx,ax
    CreateUsbReq
    AddReadUsbDataReq
    StartUsbReq
    IsUsbReqReady
    GetUsbReqData
    UsbReqDone
    pop bx

sbDone:
    pop dx
    pop ax
    pop es
    pop ds
    ret
SetupBoot   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			HidThread
;
;		DESCRIPTION:    HID handler thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_thread_name  DB 'USB HID', 0

hid_thread_pr  Proc far
    mov ax,hid_data_sel
    mov fs,ax
    GetThread
    mov fs:hid_thread,ax
;
    WaitForSignal
    ret
hid_thread_pr  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        usb_attach
;
;		description:	USB attach callback
;
;		Parameters:     BX      Controller #
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
    int 3
    call SetupBoot
    call InsertHidSel
;    
    mov dx,hid_data_sel
    mov ds,dx
    mov dx,ds:hid_thread
    or dx,dx
    jnz uaDone
;
	mov ds:hid_thread,-1
    push ds
    push es
;    
	mov dx,cs
	mov ds,dx
	mov es,dx
	mov di,OFFSET hid_thread_name
	mov si,OFFSET hid_thread_pr
	mov ax,2
	mov cx,100h
	CreateThread
;
    pop es
    pop ds

uaDone:    
    FreeMem
;
    popad
    pop es
    pop ds
    ret
usb_attach  Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:	        usb_detach
;
;		description:	USB detach callback
;
;		Parameters:     BX      Controller #
;                       AL      Device address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_detach  Proc far
    push ds
    push es
    pushad
;    
    call GetHidSel
    jc udDone
;
    call RemoveHidSel
    call FreeHidSel
;    
    mov dx,hid_data_sel
    mov ds,dx
    mov bx,ds:hid_thread
    or bx,bx
    jz udDone
;
	mov ds:hid_thread,0
	Signal
            
udDone:    
    popad
    pop es
    pop ds
    ret
usb_detach  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init
;
;		description:	Init device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
	mov bx,hid_code_sel
	InitDevice
;
	mov eax,SIZE hid_data
	mov bx,hid_data_sel
	AllocateFixedSystemMem
	mov cx,SIZE hid_data
	xor di,di
	xor al,al
	rep stosb
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
;
	popa
	pop es
	pop ds	
	ret
init	Endp

code	ENDS

	END init
