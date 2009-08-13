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

hid_device_struc   STRUC

hid_prev            DW ?
hid_next            DW ?

hid_controller      DW ?
hid_device          DB ?

hid_device_struc   ENDS

hid_data STRUC

hid_section         section_typ <>
hid_thread          DW ?
hid_dev_list        DW ?

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
    push es
;
    mov es,bx
    FreeMem
;
    pop es        
    ret
FreeHidSel Endp

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
    pop ds 
    ret
RemoveHidSel Endp

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
    int 3    
    ConfigUsbDevice
    call CreateHidSel
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
    int 3
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
