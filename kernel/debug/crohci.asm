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

usb_setup_data  STRUC

usd_type        DB ?
usd_req         DB ?
usd_value       DW ?
usd_index       DW ?
usd_len         DW ?

usb_setup_data  ENDS

usb_struc	STRUC

sd_int		DD 32 DUP(?)
sd_frame	DW ?
sd_pad		DW ?
sd_done_head    DD ?
sd_resv         DB 120 DUP (?)

sd_hid_int      DD 4 DUP(?)

control_ed      DD 4 DUP(?)
control_setup   DD 4 DUP(?)
control_end     DD 4 DUP(?)
control_status  DD 4 DUP(?)
control_msg     DB 8 DUP(?)

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
;           NAME:           CheckWait
;
;           DESCRIPTION:    Check wait
;
;           PARAMETERS:     ES:EDX	Function linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
CheckWait       PROC near
    mov eax,es:[edx+4]
    and al,0C0h
    cmp al,80h
    stc
    jne cwDone
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET sd_frame
    mov ax,es:[edi]
;
    mov ecx,1000000

cwLoop:
    cmp ax,es:[edi]
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
    mov edi,ds:mon_usb_linear
    add edi,OFFSET sd_frame
    mov ax,es:[edi]

wmLoop:
    cmp ax,es:[edi]
    je wmLoop
;
    mov ax,es:[edi]
    loop wmLoop
;
    popad
    ret
WaitMs       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WaitControl
;
;           DESCRIPTION:    Wait for control completed
;
;           PARAMETERS:     ES:EDX	Function linear
;                           ES:ESI      Hub entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
WaitControl       PROC near
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_ed

wcRetry:
    mov eax,es:[esi]
    test al,1
    jz wcDone
;
    mov eax,es:[edi+4]
    sub eax,es:[edi+8]
    and eax,0FFFFFFF0h
    jnz wcRetry

wcDone:
    ret
WaitControl       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           CreateControl
;
;           DESCRIPTION:    Create control
;
;           PARAMETERS:     ES:EDX	Function linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl	Proc near    
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_end
    mov eax,0E40000h
    stosd
;
    xor eax,eax
    stosd
    stosd
    stosd
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_ed
    mov eax,82000h
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_end
    stosd
    stosd
;
    mov eax,es:[edx+20h]
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_ed
    mov es:[edx+20h],eax
;
    ret
CreateControl	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddressDev
;
;           DESCRIPTION:    Address device
;
;           PARAMETERS:     ES:EDX	Function linear
;                           ES:ESI      Hub entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddressDev	Proc near    
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,0
    mov es:[edi].usd_req,SET_ADDRESS
    mov es:[edi].usd_value,1
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,0
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_setup
;    
    mov ax,0F2E4h
    shl eax,16
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_msg
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_status
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_msg
    add eax,7
    stosd
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_status
;
    mov ax,0F3F4h
    shl eax,16
    stosd
;
    xor eax,eax
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_end
    stosd
;
    xor eax,eax
    stosd
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_ed
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_setup
    mov es:[edi+8],eax
;
    mov eax,es:[edx+8]
    or al,2
    mov es:[edx+8],eax
;
    call WaitControl
    int 3
    ret
AddressDev	Endp

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
    and ax,0F803h
    or al,94h
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
;
    movzx ecx,ds:mon_usb_ports
    mov esi,edx
    add esi,54h
    mov eax,100h

cfPowerLoop:    
    mov es:[esi],eax
    add esi,4
    loop cfPowerLoop
;
    call CheckWait
    jc cfFailed
;
    movzx ecx,ds:mon_usb_ports
    mov esi,edx
    add esi,54h
    mov eax,100h

cfConnLoop:    
    mov eax,es:[esi]
    test al,1
    jz cfConnNext
;
    mov ax,50
    call WaitMs
;
    mov eax,es:[esi]
    test al,1
    jz cfConnNext
;
    mov eax,10h
    mov es:[esi],eax

cfWaitReset:
    mov eax,es:[esi]
    test al,1
    jz cfConnNext
;
    test al,10h
    jnz cfWaitReset
;
    test ax,200h
    jz cfDisable
;
    mov eax,2
    mov es:[esi],eax
;
    mov ax,50
    call WaitMs
;
    mov eax,es:[esi]
    test al,1
    jz cfDisable
;
    call CreateControl
    call AddressDev

cfDisable:
    mov eax,1
    mov es:[esi],eax

cfCheckDisabled:
    mov eax,es:[esi]
    test al,2
    jnz cfCheckDisabled

cfConnNext:
    add esi,4
    loop cfConnLoop

cfFailed:
    stc
;
    popad
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
    jnc coFound
;
    call ResetOhci
;
    add esi,4
    loop coLoop

coFound:

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
