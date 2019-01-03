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
; HIDCARD.ASM
; Implements HID card class
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

include ..\os.def
include ..\os.inc
include ..\user.def
include ..\user.inc
include ..\driver.def
INCLUDE ..\os\protseg.def
include ..\usbdev\usb.inc
INCLUDE ..\handle.inc
include hid.inc

hid_card   STRUC

hid_report_offset   DD ?
hid_report_sel      DW ?

hid_20_index        DW ?
hid_21_index        DW ?
hid_22_index        DW ?
hid_28_index        DW ?
hid_29_index        DW ?
hid_2A_index        DW ?
hid_38_index        DW ?
hid_30_index        DW ?
hid_31_index        DW ?
hid_32_index        DW ?

hid_card   ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_begin
;
;   DESCRIPTION:    Begin initialization
;
;   Parameters:     FS:ESI    Report struct
;                   GS:EBX    Device
;
;   RETURNS:        BX        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_begin   Proc far
    push es
    push eax
    push ecx
    push edi
;
    mov eax,SIZE usb_device_descr
    AllocateSmallGlobalMem
;
    mov bx,gs:hid_controller
    mov al,gs:hid_device
;
    mov ecx,SIZE usb_device_descr
    xor edi,edi
    GetUsbDevice
    cmp eax,ecx
    jne hbFail
;
    mov ax,es:udd_vendor
    cmp ax,801h
    jne hbFail
;
    mov ax,es:udd_prod
    cmp ax,3
    jne hbFail
;
    FreeMem
;    
    mov eax,SIZE hid_card
    AllocateSmallGlobalMem
;
    mov es:hid_report_offset,esi
    mov es:hid_report_sel,fs    
    mov es:hid_20_index,-1
    mov es:hid_21_index,-1
    mov es:hid_22_index,-1
    mov es:hid_28_index,-1
    mov es:hid_29_index,-1
    mov es:hid_2A_index,-1
    mov es:hid_38_index,-1
    mov es:hid_30_index,-1
    mov es:hid_31_index,-1
    mov es:hid_32_index,-1
    mov ebx,es
    jmp hbDone

hbFail:
    FreeMem
    xor ebx,ebx

hbDone:
    pop edi
    pop ecx
    pop eax
    pop es
    ret
hid_begin   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_define
;
;   DESCRIPTION:    Define entry
;
;   PARAMETERS:     BX      Handle
;                   SI      Entry #
;                   AL      Usage ID low
;                   AH      Usage ID high
;                   CL      Usage page
;                   EDX     Item params
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_define   Proc far
    push ds
    push ebx
    mov ds,ebx
;
    cmp cx,0FF00h
    jne hdDone
;
    cmp al,20h
    jne hdNot20
;
    mov bx,ds:hid_20_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_20_index,si
    jmp hdDone

hdNot20:
    cmp al,21h
    jne hdNot21
;
    mov bx,ds:hid_21_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_21_index,si
    jmp hdDone

hdNot21:
    cmp al,22h
    jne hdNot22
;
    mov bx,ds:hid_22_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_22_index,si
    jmp hdDone

hdNot22:
    cmp al,28h
    jne hdNot28
;
    mov bx,ds:hid_28_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_28_index,si
    jmp hdDone

hdNot28:
    cmp al,29h
    jne hdNot29
;
    mov bx,ds:hid_29_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_29_index,si
    jmp hdDone

hdNot29:
    cmp al,2Ah
    jne hdNot2A
;
    mov bx,ds:hid_2A_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_2A_index,si
    jmp hdDone

hdNot2A:
    cmp al,38h
    jne hdNot38
;
    mov bx,ds:hid_38_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_38_index,si
    jmp hdDone

hdNot38:
    cmp al,30h
    jne hdNot30
;
    mov bx,ds:hid_30_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_30_index,si
    jmp hdDone

hdNot30:
    cmp al,31h
    jne hdNot31
;
    mov bx,ds:hid_31_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_31_index,si
    jmp hdDone

hdNot31:
    cmp al,32h
    jne hdDone
;
    mov bx,ds:hid_32_index
    cmp bx,-1
    jne hdDone
;
    mov ds:hid_32_index,si

hdDone:
    pop ebx
    pop ds
    ret
hid_define   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_end
;
;   DESCRIPTION:    End initialization
;
;   PARAMETERS:     BX      Handle
;
;   RETURNS:        NC      Use
;                   CY      Discard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_end   Proc far
    int 3
    push es
    push eax
    mov es,ebx
;
    mov ax,es:hid_20_index
    and ax,es:hid_21_index
    and ax,es:hid_22_index
    and ax,es:hid_28_index
    and ax,es:hid_29_index
    and ax,es:hid_2A_index
    and ax,es:hid_38_index
    and ax,es:hid_30_index
    and ax,es:hid_31_index
    and ax,es:hid_32_index
    cmp ax,-1
    je heFail
;
    clc
    jmp heDone

heFail:
    FreeMem
    stc
        
heDone:
    pop eax    
    pop es
    ret
hid_end   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_close
;
;   DESCRIPTION:    Close
;
;   PARAMETERS:     BX      Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_close   Proc far
    push es
    mov es,ebx
    FreeMem
    pop es
    ret
hid_close   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           hid_handle_report
;
;   DESCRIPTION:    Handle report
;
;   PARAMETERS:     BX      Handle
;                   FS:ESI  Report data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hid_handle_report   Proc far
    int 3
    ret
hid_handle_report   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           valid_custom_hid
;
;   DESCRIPTION:    Check for custom hid device
;
;   PARAMETERS:     FS:ESI  Hid device
;
;   RETURNS:        NC		Accept
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

valid_custom_hid   Proc far
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    mov eax,SIZE usb_device_descr
    AllocateSmallGlobalMem
;
    mov bx,fs:hid_controller
    mov al,fs:hid_device
;
    mov ecx,SIZE usb_device_descr
    xor edi,edi
    GetUsbDevice
    cmp eax,ecx
    jne vchFail
;
    mov ax,es:udd_vendor
    cmp ax,801h
    jne vchFail
;
    mov ax,es:udd_prod
    cmp ax,3
    jne vchFail
;
    FreeMem
    clc
    jmp vchDone

vchFail:
    FreeMem
    stc

vchDone:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
valid_custom_hid   Endp

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

hid_tab:
h00 DD OFFSET hid_begin,        SEG code
h01 DD OFFSET hid_define,       SEG code
h02 DD OFFSET hid_end,          SEG code
h03 DD OFFSET hid_close,        SEG code
h04 DD OFFSET hid_handle_report,SEG code

Init    Proc far
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov edi,OFFSET valid_custom_hid
    RegisterCustomHid
;
    mov edi,OFFSET hid_tab
    RegisterHidInput
    ret
Init    Endp
        
code    ENDS

    END Init
