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
; crohci.ASM
; Crash debugger OHCI support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE kdebug.inc

usb_struc	STRUC

sd_int		DD 32 DUP(?)
sd_frame	DW ?
sd_pad		DW ?
sd_done_head    DD ?
sd_resv         DB 120 DUP (?)

sd_hid_int      DD 4 DUP(?)

usb_struc	ENDS

    .386p

code    SEGMENT byte public use32 'CODE'

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
;           NAME:           InitOhci
;
;           DESCRIPTION:    Init OHCI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitOhci
    
InitOhci      PROC near
    push ds
    push eax
;    
    mov ax,mon_data_sel
    mov ds,ax
    mov ds:mon_ohci_count,0
;
    pop eax
    pop ds
    ret
InitOhci      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ResetOhci
;
;           DESCRIPTION:    Reset OHCI
;
;           PARAMETERS:     ES:EDX		PIC BAR0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
ResetOhci      PROC near
    push eax
    push ecx
    push edx
;
    mov eax,es:[edx+8]
    test al,1    
    stc
    jnz roResetDone
;
    or al,1
    mov es:[edx+8],eax
;
    mov ecx,100000h

roWait:
    mov eax,es:[edx+8]
    test al,1
    clc
    jz roResetDone
;
    loop roWait
;
    stc

roResetDone:
    pop edx
    pop ecx
    pop eax
    ret
ResetOhci	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddOhci
;
;           DESCRIPTION:    Add OHCI
;
;           PARAMETERS:     ECX		PCI address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public AddOhci
    
AddOhci      PROC near
    push ds
    push eax
    push ebx
    push ecx
    push edx
;    
    mov ax,mon_data_sel
    mov ds,ax
    movzx ebx,ds:mon_ohci_count
    cmp bl,10
    jae aoDone
;
    mov cl,10h
    call ReadPciDword
    or eax,eax
    jz aoDone
;    
    test al,7
    jnz aoDone
;
    and al,0F0h
    push eax
    push ebx
    xor ebx,ebx
    call MapUsbFunc
    call ResetOhci
    pop ebx
    pop eax
    jc aoDone
;
    inc ds:mon_ohci_count
    shl ebx,2
    mov ds:[ebx].mon_ohci_arr,eax

aoDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
AddOhci      ENDP

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
    xor eax,eax
    mov es:[edx+20h],eax
    mov es:[edx+28h],eax
    mov es:[edx+30h],eax
    mov edi,ds:mon_usb_linear
    mov es:[edx+18h],edi
; 
    mov ecx,32
    mov eax,OFFSET sd_hid_int
    add eax,edi
    rep stosd
;
    mov ecx,32
    xor eax,eax
    rep stosd
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET sd_hid_int
    mov eax,4000h
    stosd
    xor eax,eax
    stosd
    stosd
    stosd
;
    mov eax,es:[edx+4]
    and ax,0F83Fh
    or al,0BCh
    mov es:[edx+4],eax
;
    mov eax,es:[edx+48h]
    and ah,NOT 3
    or ah,1
    mov es:[edx+48h],eax
;    
    mov eax,es:[edx+4Ch]
    or eax,0FFFF0000h
    mov es:[edx+4Ch],eax    
;
    mov eax,es:[edx+48h]
    or al,al
    jnz cfPortsOk
;
    inc al

cfPortsOk:    
    mov ds:mon_usb_ports,al

    ret
CheckFunc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CheckOhci
;
;           DESCRIPTION:    Check OHCI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public CheckOhci
    
CheckOhci       PROC near
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
;    
    int 3
    mov ax,mon_data_sel
    mov ds,ax
    mov ax,mon_flat_sel
    mov es,ax
;
    movzx ecx,ds:mon_ohci_count
    or ecx,ecx
    jz coDone
;
    mov esi,OFFSET mon_ohci_arr

coLoop:
    xor ebx,ebx
    mov eax,[esi]
    call MapUsbFunc
    call CheckFunc
;
    add esi,4
    loop coLoop

coDone:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
CheckOhci	Endp

code    ENDS

    END
