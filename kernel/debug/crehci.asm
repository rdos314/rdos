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
    movzx edi,byte ptr es:[edx]
    add edi,edx
    mov eax,es:[edi]
    test al,1
    clc
    jz reDone
;
    and al,NOT 31h
    mov es:[edi],eax
;
    mov ecx,100000h

reLoop:
    call PollKey
    mov eax,es:[edi+4]
    test ax,1000h
    clc
    jne reDone
;
    loop reLoop
;
    stc

reDone:    
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
;
    mov ax,es:[edx+2]
    cmp ah,1
    jne aeDone
;
    mov eax,es:[edx+8]
    test al,2
    jz aeDone
;
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
;           NAME:           WaitReset
;
;           DESCRIPTION:    Wait reset
;
;           PARAMETERS:     ES:EDX	Function linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
WaitReset       PROC near
    mov ecx,1000000
    mov edi,ds:mon_usb_oper

wrLoop:
    call PollKey
    mov eax,es:[edi]
    test al,2
    clc
    jz wrDone
;
    loop wrLoop
;
    stc

wrDone:    
    ret
WaitReset       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CheckWait
;
;           DESCRIPTION:    Check wait
;
;           PARAMETERS:     ES:EDX	Function linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
CheckWait       PROC near
    mov edi,ds:mon_usb_oper
    mov ecx,1000000
    mov eax,es:[edi+0Ch]

cwLoop:
    call PollKey
    cmp eax,es:[edi+0Ch]
    clc
    jne cwDone
    loop cwLoop
;
    stc

cwDone:    
    ret
CheckWait       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WaitMs
;
;           DESCRIPTION:    Wait milliseconds
;
;           PARAMETERS:     ES:EDX	Function linear
;                           AX          Ms to wait
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
WaitMs       PROC near
    pushad
;
    movzx ecx,ax
    shl ecx,3
    mov edi,ds:mon_usb_oper
    mov eax,es:[edi+0Ch]

wmLoop:
    call PollKey
    cmp eax,es:[edi+0Ch]
    je wmLoop
;
    mov eax,es:[edi+0Ch]
    loop wmLoop
;
    popad
    ret
WaitMs       ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CheckFunc
;
;           DESCRIPTION:    Check function
;
;           PARAMETERS:     ES:EDX	Function linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
CheckFunc       PROC near
    pushad
;
    mov eax,es:[edx+4]
    and al,0Fh
    mov ds:mon_usb_ports,al
;
    movzx eax,byte ptr es:[edx]
    add eax,edx
    mov ds:mon_usb_oper,eax
;
    mov edi,eax
    mov eax,es:[edi]
    or al,2
    mov es:[edi],eax
    call WaitReset
    jc cfFail
;
    mov eax,es:[edi]
    and al,0F3h
    or al,9
    mov es:[edi],eax
;
    call CheckWait
    jc cfFail
;
    mov eax,es:[edi+40h]
    or al,1
    mov es:[edi+40h],eax
;
    movzx ecx,ds:mon_usb_ports
    add edi,44h

cfPowerLoop:
    mov eax,es:[edi]
    test ax,1000h
    jnz cfPowerOk
;
    or ax,1000h
    mov es:[edi],eax

cfPowerOk:
    add edi,4
    loop cfPowerLoop
;
    movzx ecx,ds:mon_usb_ports
    mov edi,ds:mon_usb_oper
    add edi,44h

cfConnLoop:    
    mov eax,es:[edi]
    test al,1
    jz cfConnNext
;
    mov bx,10

cfCheck:    
    mov ax,5
    call WaitMs
;
    mov eax,es:[edi]
    test al,1
    jz cfConnNext
;
    sub bx,1
    jnz cfCheck
;
    and ax,0C00h
    cmp ax,400h
    jne cfDoReset
;
    mov eax,es:[edi]
    or ax,2000h
    mov es:[edi],eax
    jmp cfConnNext

cfDoReset:
    int 3

cfConnNext:
    add edi,4
    sub ecx,1
    jnz cfConnLoop

cfStop:
   call ResetEhci

cfFail:
    popad
    ret
CheckFunc	Endp

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

ceLoop:
    xor ebx,ebx
    mov eax,[esi]
    call MapUsbFunc
    call CheckFunc
;
    add esi,4
    loop ceLoop

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
