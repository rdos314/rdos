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
; crehci.ASM
; Crash debugger EHCI support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE kdebug.inc

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

SET_PROTOCOL = 11

usb_setup_data  STRUC

usd_type        DB ?
usd_req         DB ?
usd_value       DW ?
usd_index       DW ?
usd_len         DW ?

usb_setup_data  ENDS

usb_interface_descr  STRUC

uid_len             DB ?
uid_type            DB ?
uid_id              DB ?
uid_alt_id          DB ?
uid_endpoints       DB ?
uid_class           DB ?
id_sub_class       DB ?
uid_proto           DB ?
uid_interface_id    DB ?

usb_interface_descr  ENDS

usb_endpoint_descr  STRUC

ued_len             DB ?
ued_type            DB ?
ued_address         DB ?
ued_attrib          DB ?
ued_maxsize         DW ?
ued_interval        DB ?

usb_endpoint_descr  ENDS

usb_struc	STRUC


usb_struc	ENDS

    .386p

code    SEGMENT byte public use32 'CODE'

    assume cs:code

    extrn MapUsbFunc:near
    extrn CheckUsbDev:near
    extrn CheckUsbConfig:near
    extrn GetUsbEp:near
    extrn UpdateUsbKeyboard:near
    extrn PollKey:near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPciDword
;
;           DESCRIPTION:    Read PCI dword
;
;           PARAMETERS:     ECX		Pci address
;
;           RETURNS:        EAX         Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPciDword    Proc near
    push edx
;
    mov eax,ecx
    mov dx,0CF8h
    out dx,eax
    mov dx,0CFCh
    in eax,dx
;
    pop edx
    ret
ReadPciDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InitEhci
;
;           DESCRIPTION:    Init EHCI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitEhci
    
InitEhci      PROC near
    push ds
    push eax
;    
    mov ax,mon_data_sel
    mov ds,ax
    mov ds:mon_ehci_count,0
;
    pop eax
    pop ds
    ret
InitEhci      ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetEhci
;
;           DESCRIPTION:    Reset EHCI
;
;           PARAMETERS:     ES:EDX		PIC BAR0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
ResetEhci      PROC near
    push eax
    push ecx
    push edx
;
    clc

reResetDone:
    pop edx
    pop ecx
    pop eax
    ret
ResetEhci	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddEhci
;
;           DESCRIPTION:    Add EHCI
;
;           PARAMETERS:     ECX		PCI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddEhci
    
AddEhci      PROC near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;    
    int 3
    mov ax,mon_data_sel
    mov ds,ax
    movzx ebx,ds:mon_ehci_count
    cmp bl,10
    jae aeDone
;
    mov cl,10h
    call ReadPciDword
    or eax,eax
    jz aeDone
;    
    test al,7
    jnz aeDone
;
    and al,0F0h
    push eax
    push ebx
    xor ebx,ebx
    call MapUsbFunc
    call ResetEhci
    pop ebx
    pop eax
    jc aeDone
;
    inc ds:mon_ehci_count
    shl ebx,2
    mov ds:[ebx].mon_ehci_arr,eax

aeDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AddEhci      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CheckEhci
;
;           DESCRIPTION:    Check EHCI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CheckEhci
    
CheckEhci       PROC near
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;    
    mov ax,mon_data_sel
    mov ds,ax
    mov ax,mon_flat_sel
    mov es,ax
;
    movzx ecx,ds:mon_ehci_count
    or ecx,ecx
    jz ceDone
;
    mov esi,OFFSET mon_ehci_arr

ceDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
CheckEhci	Endp

code    ENDS

    END
