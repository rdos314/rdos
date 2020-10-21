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
; crxhci.ASM
; Crash debugger XHCI support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE kdebug.inc

TRB_TYPE_NORMAL         = 1
TRB_TYPE_SETUP          = 2
TRB_TYPE_DATA           = 3
TRB_TYPE_STATUS         = 4
TRB_TYPE_ISO            = 5
TRB_TYPE_LINK           = 6
TRB_TYPE_EVENT          = 7
TRB_TYPE_NO_OP          = 8
TRB_TYPE_ENABLE_SLOT    = 9
TRB_TYPE_DISABLE_SLOT   = 10
TRB_TYPE_ADDRESS_DEV    = 11
TRB_TYPE_CONFIGURE_ENDP = 12
TRB_TYPE_EVALUATE       = 13
TRB_TYPE_RESET_ENDP     = 14
TRB_TYPE_STOP_ENDP      = 15
TRB_TYPE_SET_TR         = 16
TRB_TYPE_RESET_DEV      = 17
TRB_TYPE_NO_OP_CMD      = 23
TRB_TYPE_TRANSFER       = 32
TRB_TYPE_CMD_COMPLETE   = 33
TRB_TYPE_PORT_CHANGE    = 34
TRB_TYPE_CONTROLLER     = 37
TRB_TYPE_DEV_NOTIFY     = 38
TRB_TYPE_MFI_WRAP       = 39

    .386p

code    SEGMENT byte public use32 'CODE'

usb_struc	STRUC

dc1             DB 100h DUP(?)
cmd             DB 40h DUP(?)

dcba            DD ?,?

usb_struc	ENDS

    assume cs:code

    extrn MapUsbFunc:near

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
;           NAME:           InitXhci
;
;           DESCRIPTION:    Init XHCI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitXhci
    
InitXhci      PROC near
    push ds
    push eax
;    
    mov ax,mon_data_sel
    mov ds,ax
    mov ds:mon_xhci_count,0
;
    pop eax
    pop ds
    ret
InitXhci      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetXhci
;
;           DESCRIPTION:    Reset XHCI
;
;           PARAMETERS:     ES:EDX		PIC BAR0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
ResetXhci      PROC near
    push eax
    push ecx
    push edx
;
    movzx ecx,byte ptr es:[edx]
    add edx,ecx
    mov eax,es:[edx]
    test al,1    
    clc
    jz rxResetDone
;
    and al,NOT 1
    or al,2
    mov es:[edx],eax
;
    mov ecx,100000h

rxWait:
    mov eax,es:[edx]
    test al,2
    clc
    jz rxResetDone
;
    loop rxWait
;
    stc

rxResetDone:
    pop edx
    pop ecx
    pop eax
    ret
ResetXhci	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddXhci
;
;           DESCRIPTION:    Add XHCI
;
;           PARAMETERS:     ECX		PCI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddXhci
    
AddXhci      PROC near
    push ds
    push eax
    push ebx
    push ecx
;    
    mov ax,mon_data_sel
    mov ds,ax
    movzx ebx,ds:mon_xhci_count
    cmp bl,10
    jae axDone
;
    mov cl,14h
    call ReadPciDword
    mov edx,eax
    mov cl,10h
    call ReadPciDword
;
    test al,4
    jz axDone
;
    and al,0F0h
    push eax
    push ebx
    push edx
    mov ebx,edx
    call MapUsbFunc
    call ResetXhci
    pop edx
    pop ebx
    pop eax
    jc axDone
;
    inc ds:mon_xhci_count
    shl ebx,3
    mov ds:[ebx].mon_xhci_arr,eax
    mov ds:[ebx+4].mon_xhci_arr,edx

axDone:
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AddXhci      ENDP

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
    mov al,es:[edx+7]
    mov ds:mon_usb_ports,al
;
    mov eax,es:[edx+10h]
    mov ds:mon_xhci_param,eax
;
    mov eax,es:[edx+14h]
    add eax,edx
    mov ds:mon_xhci_door_bell,eax
;
    mov eax,es:[edx+18h]
    add eax,edx
    mov ds:mon_xhci_runtime,eax
;
    movzx eax,byte ptr es:[edx]
    add eax,edx
    mov ds:mon_xhci_oper,eax
    mov edx,eax
;
    mov eax,1
    mov es:[edx+38h],eax
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET dc1
    mov ecx,40h
    xor eax,eax
    rep stosd
;
    mov edi,ds:mon_usb_linear
    mov eax,OFFSET dc1
    add eax,edi
    mov es:[edi].dcba,eax
    xor eax,eax
    mov es:[edi+4].dcba,eax
;    
    mov eax,ds:mon_usb_linear
    add eax,OFFSET dcba
    mov es:[edx+30h],eax
    xor eax,eax
    mov es:[edx+34h],eax
;    
    mov edi,ds:mon_usb_linear
    add edi,OFFSET cmd
    mov ecx,0Ch
    xor eax,eax
    rep stosd
;
    int 3
    mov eax,ds:mon_usb_linear
    add eax,OFFSET cmd
    stosd
    xor eax,eax
    stosd
    stosd
    mov eax,2 + (TRB_TYPE_LINK SHL 10)
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET cmd
    mov es:[edx+18h],eax
    xor eax,eax
    mov es:[edx+1Ch],eax
;
    ret
CheckFunc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CheckXhci
;
;           DESCRIPTION:    Check XHCI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CheckXhci
    
CheckXhci       PROC near
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
    movzx ecx,ds:mon_xhci_count
    or ecx,ecx
    jz cxDone
;
    mov esi,OFFSET mon_xhci_arr

cxLoop:
    mov ebx,[esi+4]
    mov eax,[esi]
    call MapUsbFunc
    call CheckFunc
;
    add esi,8
    loop cxLoop

cxDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
CheckXhci	Endp

code    ENDS

    END
