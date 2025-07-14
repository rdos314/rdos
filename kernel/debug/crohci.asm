;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
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

sd_int		DD 32 DUP(?)
sd_frame	DW ?
sd_pad		DW ?
sd_done_head    DD ?
sd_resv         DB 120 DUP (?)

sd_hid_int      DD 4 DUP(?)

control_ed      DD 4 DUP(?)
control_setup   DD 4 DUP(?)
control_data    DD 4 * 64 DUP(?)
control_status  DD 4 DUP(?)
control_end     DD 4 DUP(?)
intr_ed         DD 4 DUP(?)
intr_td         DD 4 DUP(?)
intr_end        DD 4 DUP(?)
control_msg     DB 8 DUP(?)
descr           DB 8 * 64 DUP(?)

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
    mov ecx,10000h

roWait:
    call PollKey
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
    call PollKey
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
    call PollKey
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
    mov ax,1
    call WaitMs
;
    mov eax,es:[esi]
    test al,1
    stc
    jz wcDone
;
    mov eax,es:[edi+8]
    and eax,0FFFFFFF0h
    sub eax,es:[edi+4]
    jnz wcRetry
;
    mov eax,es:[edi+8]
    test al,1
    stc
    jnz wcDone
;
    clc

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
;           NAME:           AddSetup
;
;           DESCRIPTION:    Add setup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddSetup	Proc near
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
    ret
AddSetup	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddStatusOut
;
;           DESCRIPTION:    Add status out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusOut	Proc near
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
    ret
AddStatusOut	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RunControl
;
;           DESCRIPTION:    Run control
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunControl	Proc near
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
    ret
RunControl	Endp

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
    call AddSetup
    call AddStatusOut
    call RunControl
    call WaitControl
    ret
AddressDev	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetDescr
;
;           DESCRIPTION:    Get descriptor
;
;           PARAMETERS:     ES:EDX	Function linear
;                           ES:ESI      Hub entry
;                           CX          Size
;                           AX          Descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDescr	Proc near    
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,80h
    mov es:[edi].usd_req,GET_DESCR
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,cx
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
    add eax,OFFSET control_data
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_msg
    add eax,7
    stosd
;
    mov ebx,ds:mon_usb_linear
    add ebx,OFFSET descr
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_data

gdLoop:
    mov ebp,edi
    mov ax,0F0F4h
    shl eax,16
    stosd
;
    mov eax,ebx
    stosd
;
    mov eax,ebp
    add eax,10h
    stosd
;
    mov ax,cx
    dec ax
    cmp ax,8
    jb gdSave
;
    mov ax,7

gdSave:
    movzx eax,ax
    or eax,ebx
    stosd
;
    add ebx,8
    sub cx,8
    ja gdLoop
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_status
    mov es:[ebp+8],edi
;
    mov ax,0F3ECh
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
;
    ret
GetDescr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ConfigDevice
;
;   DESCRIPTION:    Config device
;
;   PARAMETERS:     AL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigDevice   Proc near
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,0
    mov es:[edi].usd_req,SET_CONFIG
    movzx ax,al
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,0
;
    call AddSetup
    call AddStatusOut
    call RunControl
    call WaitControl
    ret
ConfigDevice	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetProtocol
;
;   DESCRIPTION:    Set protocol
;
;   PARAMETERS:     AL      Interface #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetProtocol   Proc near
    mov dx,ax
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,21h
    mov es:[edi].usd_req,SET_PROTOCOL
    mov es:[edi].usd_value,0
    movzx ax,dl
    mov es:[edi].usd_index,ax
    mov es:[edi].usd_len,0
;
    call AddSetup
    call AddStatusOut
    call RunControl
    call WaitControl
    ret
SetProtocol	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           LinkIntr
;
;   DESCRIPTION:    Link data endpoint
;
;   PARAMETERS:     AL      Endpoint #1
;                   AH      Interval
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinkIntr   Proc near
    mov edi,ds:mon_usb_linear
    add edi,OFFSET intr_ed
    movzx eax,al
    shl eax,7
    or eax,83001h
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET intr_end
    stosd
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET sd_hid_int
    stosd
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET intr_end
    mov eax,0E40000h
    stosd
    xor eax,eax
    stosd
    stosd
    stosd
;
    mov edi,ds:mon_usb_linear
    mov eax,ds:mon_usb_linear
    add eax,OFFSET intr_ed
    mov es:[edi],eax
    ret
LinkIntr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           UnlinkIntr
;
;   DESCRIPTION:    Unlink data endpoint
;
;   PARAMETERS:     AL      Endpoint #1
;                   AH      Interval
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkIntr   Proc near
    mov ecx,32
    mov edi,ds:mon_usb_linear
    mov eax,OFFSET sd_hid_int
    add eax,edi
    rep stosd
    ret
UnlinkIntr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddIntr
;
;           DESCRIPTION:    Add intr TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntr	Proc near
    mov edi,ds:mon_usb_linear
    add edi,OFFSET intr_td
;    
    mov ax,0FCF4h
    shl eax,16
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET descr
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET intr_end
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET descr
    add eax,7
    stosd
    ret
AddIntr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RunIntr
;
;           DESCRIPTION:    Run intr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunIntr	Proc near
    mov edi,ds:mon_usb_linear
    add edi,OFFSET intr_ed
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET intr_td
    mov es:[edi+8],eax
;
    mov eax,es:[edx+8]
    or al,2
    mov es:[edx+8],eax
    ret
RunIntr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ReloadIntr
;
;           DESCRIPTION:    Reload intr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReloadIntr	Proc near
    mov edi,ds:mon_usb_linear
    add edi,OFFSET intr_td
;    
    mov ax,0FCF4h
    shl eax,16
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET descr
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET intr_end
    stosd
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET intr_ed
;
    mov eax,es:[edi+8]
    test al,1
    stc
    jnz riDone
;
    and eax,3
    add eax,ds:mon_usb_linear
    add eax,OFFSET intr_td
    mov es:[edi+8],eax
;
    mov eax,es:[edx+8]
    or al,2
    mov es:[edx+8],eax
    clc

riDone:
    ret
ReloadIntr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WaitData
;
;           DESCRIPTION:    Wait for intr completed
;
;           PARAMETERS:     ES:EDX	Function linear
;                           ES:ESI      Hub entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
WaitData       PROC near
    mov edi,ds:mon_usb_linear
    add edi,OFFSET intr_ed

wdRetry:
    mov ax,1
    call WaitMs
;
    mov eax,es:[esi]
    test al,1
    stc
    jz wdDone
;
    mov eax,es:[edi+8]
    and eax,0FFFFFFF0h
    sub eax,es:[edi+4]
    jnz wdRetry
;
    mov eax,es:[edi+8]
    test al,1
    stc
    jnz wdDone
;
    clc

wdDone:
    ret
WaitData       ENDP

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
    jc cfDisable
;
    mov ax,1
    call WaitMs
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_ed
    mov al,1
    mov es:[edi],al
;
    push ecx
    mov cx,8
    mov ax,100h
    call GetDescr 
    pop ecx
    jc cfDisable
;
    mov ax,1
    call WaitMs
;
    push ecx
    mov edi,ds:mon_usb_linear
    add edi,OFFSET descr
    movzx cx,byte ptr es:[edi]
    mov ax,100h
    call GetDescr 
    pop ecx
    jc cfDisable
;
    mov ax,1
    call WaitMs
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET descr
    call CheckUsbDev
    jc cfDisable
;
    movzx ebp,byte ptr es:[edi+17]
    xor bx,bx

cfConfigLoop:
    push ebx
    push ecx
    push ebp
;
    mov cx,8
    mov al,bl
    mov ah,2
    call GetDescr
;
    pop ebp
    pop ecx
    pop ebx
    jc cfDisable
;
    mov ax,1
    call WaitMs
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET descr
    mov ax,es:[edi+2]
    cmp ax,200h
    jae cfConfigNext
;
    push ebx
    push ecx
    push ebp
;
    mov cx,ax
    mov al,bl
    mov ah,2
    call GetDescr
;
    pop ebp
    pop ecx
    pop ebx
    jc cfDisable
;
    mov ax,1
    call WaitMs
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET descr
    call CheckUsbConfig
    jnc cfConfig

cfConfigNext:
    inc bx
    sub ebp,1
    jnz cfConfigLoop
    jmp cfDisable

cfConfig:
    push edi
    call ConfigDevice
    pop edi
    jc cfDisable
;
    mov ax,1
    call WaitMs
;
    push edi
    mov al,es:[edi].uid_id
    call SetProtocol
    pop edi
    jc cfDisable
;
    mov ax,1
    call WaitMs
;
    call GetUsbEp
    jc cfDisable
;
    mov al,es:[edi].ued_address
    and al,0Fh
    mov ah,es:[edi].ued_interval
    mov edx,ds:mon_usb_func_linear
    call LinkIntr

    call AddIntr
    call RunIntr

cfDataLoop:
    call WaitData
    jc cfDisableUnlink
;
    mov ax,1
    call WaitMs
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET descr
    call UpdateUsbKeyboard
    call ReloadIntr
    jnc cfDataLoop

cfDisableUnlink:
    int 3
    call UnlinkIntr

cfDisable:
    mov eax,1
    mov es:[esi],eax

cfCheckDisabled:
    mov eax,es:[esi]
    test al,2
    jnz cfCheckDisabled

cfConnNext:
    add esi,4
    sub ecx,1
    jnz cfConnLoop

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
