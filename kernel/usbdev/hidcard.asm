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
INCLUDE ..\os\carddev.inc

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

data    SEGMENT byte public 'DATA'

card_dev            DW ?

data	ENDS

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code    SEGMENT byte public 'CODE'

    assume cs:code

    .386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           get_carddev_name
;
;       DESCRIPTION:    Get cardreader name
;
;       PARAMETERS:     ES:EDI      Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

usb_carddev_name DB 'USB Card Reader', 0

get_carddev_name    Proc far
    push eax
    push esi
    push edi
;
    mov esi,OFFSET usb_carddev_name

gcnLoop:
    lods byte ptr cs:[esi]
    stos byte ptr es:[edi]
    or al,al
    jnz gcnLoop
;
    pop edi
    pop esi
    pop eax
    ret
get_carddev_name    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           is_ok
;
;       DESCRIPTION:    Check if cardreader is online
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_ok    Proc far
    clc
    ret
is_ok    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           is_busy
;
;       DESCRIPTION:    Check if cardreader is busy
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_busy    Proc far
    stc
    ret
is_busy    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           is_inserted
;
;       DESCRIPTION:    Check if card is inserted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_inserted    Proc far
    stc
    ret
is_inserted    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           had_inserted
;
;       DESCRIPTION:    Check if card is inserted changed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

had_inserted    Proc far
    stc
    ret
had_inserted    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           clear_inserted
;
;       DESCRIPTION:    Clear card is inserted changed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clear_inserted    Proc far
    ret
clear_inserted    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           wait_for_card
;
;       DESCRIPTION:    Wait for card
;
;       PARAMETERS:     ES:EDI      Strip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_card    Proc far
    ret
wait_for_card    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AddCardReader
;
;       DESCRIPTION:    Add card reader device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddCardReader	Proc near
    push ds
    push es
    pushad
;
    mov eax,SIZE carddev_struc
    AllocateSmallGlobalMem
    mov es:cd_device,0
;    
    xor ax,ax
    xor dx,dx
    mov bx,es
    mov ds,bx
    AddCardDev
;
    mov word ptr es:cd_get_name_proc,OFFSET get_carddev_name
    mov word ptr es:cd_get_name_proc+2,cs
;    
    mov word ptr es:cd_ok_proc,OFFSET is_ok
    mov word ptr es:cd_ok_proc+2,cs
;    
    mov word ptr es:cd_busy_proc,OFFSET is_busy
    mov word ptr es:cd_busy_proc+2,cs
;    
    mov word ptr es:cd_inserted_proc,OFFSET is_inserted
    mov word ptr es:cd_inserted_proc+2,cs
;    
    mov word ptr es:cd_had_inserted_proc,OFFSET had_inserted
    mov word ptr es:cd_had_inserted_proc+2,cs
;    
    mov word ptr es:cd_clear_inserted_proc,OFFSET clear_inserted
    mov word ptr es:cd_clear_inserted_proc+2,cs
;    
    mov word ptr es:cd_wait_for_card_proc,OFFSET wait_for_card
    mov word ptr es:cd_wait_for_card_proc+2,cs
;
    mov ax,SEG data
    mov ds,eax
    mov ds:card_dev,es
;
    popad
    pop es
    pop ds
    ret
AddCardReader	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleGoodCard
;
;   DESCRIPTION:    Handle good card
;
;   PARAMETERS:     FS:EBX  Card strip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGoodCard   Proc near
    int 3
    ret
HandleGoodCard	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleBadCard
;
;   DESCRIPTION:    Handle bad card
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleBadCard   Proc near
    int 3
    ret
HandleBadCard	Endp

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
    int 3
    mov ax,SEG data
    mov es,eax
    mov ax,es:card_dev
    or ax,ax
    jnz heHasDev
;
    call AddCardReader

heHasDev:
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
    push es
    push eax
    push ebx
    mov es,ebx
;
    movzx ebx,es:hid_29_index
    mov al,fs:[ebx+esi]
    or al,al
    jz hhrNotGood2
;
    movzx ebx,es:hid_31_index
    add ebx,esi
    call HandleGoodCard
    jmp hhrDone

hhrNotGood2:
    movzx ebx,es:hid_38_index
    mov al,fs:[ebx+esi]
    or al,al
    jz hhrNotBad
;
    call HandleBadCard
    jmp hhrDone

hhrNotBad:
    int 3

hhrDone:
    pop ebx
    pop eax
    pop es
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
    mov ax,SEG data
    mov ds,eax
    mov ds:card_dev,0
;
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
