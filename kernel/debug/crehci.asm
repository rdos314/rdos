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

CLEAR_TT = 8
RESET_TT = 9
GET_TT_STATE = 10
STOP_TT = 11

PORT_CONNECTION     = 0
PORT_ENABLE         = 1
PORT_SUSPEND        = 2
PORT_OVER_CURRENT   = 3
PORT_RESET          = 4
PORT_POWER          = 8
PORT_LOW_SPEED      = 9
C_PORT_CONNECTION   = 16
C_PORT_ENABLE       = 17
C_PORT_SUSPEND      = 18
C_PORT_OVER_CURRENT = 19
C_PORT_RESET        = 20
PORT_TEST           = 21
PORT_INDICATOR      = 22

usb_setup_data  STRUC

usd_type        DB ?
usd_req         DB ?
usd_value       DW ?
usd_index       DW ?
usd_len         DW ?

usb_setup_data  ENDS

usb_device_descr	STRUC

udd_len		DB ?
udd_type	DB ?
udd_usb_ver	DW ?
udd_class	DB ?
udd_sub_class	DB ?
udd_proto	DB ?
udd_maxlen	DB ?
udd_vendor	DW ?
udd_prod	DW ?
udd_device	DW ?
udd_man		DB ?
udd_prodid	DB ?
udd_num		DB ?
udd_configs	DB ?

usb_device_descr	ENDS

usb_config_descr	STRUC

ucd_len	    		DB ?
ucd_type	    	DB ?
ucd_size		    DW ?
ucd_interface_count	DB ?
ucd_config_id		DB ?
ucd_config_str		DB ?
ucd_attrib  		DB ?
ucd_power	    	DB ?

usb_config_descr	ENDS

usb_interface_descr  STRUC

uid_len             DB ?
uid_type            DB ?
uid_id              DB ?
uid_alt_id          DB ?
uid_endpoints       DB ?
uid_class           DB ?
uid_sub_class       DB ?
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

usb_hub_descr   STRUC

uhd_len             DB ?
uhd_type            DB ?
uhd_ports           DB ?
uhd_info            DW ?
uhd_power_time  DB ?
uhd_current     DB ?

usb_hub_descr   ENDS

qh_struc       STRUC

qh_link         DD ?
qh_adress       DB ?
qh_endpoint     DB ?
qh_max_packet   DW ?
qh_s_mask       DB ?
qh_c_mask       DB ?
qh_hub_port     DW ?
qh_current_qtd  DD ?
qh_next_qtd     DD ?
qh_alt_qtd      DD ?
qh_status       DB ?
qh_flags        DB ?
qh_size         DW ?
qh_page0        DD ?
qh_page1        DD ?
qh_page2        DD ?
qh_page3        DD ?
qh_page4        DD ?

qh_space        DB 16 DUP(?)

qh_struc      ENDS

qtd_struc       STRUC

qtd_next        DD ?
qtd_alt         DD ?
qtd_status      DB ?
qtd_flags       DB ?
qtd_size        DW ?
qtd_page0       DD ?
qtd_page1       DD ?
qtd_page2       DD ?
qtd_page3       DD ?
qtd_page4       DD ?

qtd_struc       ENDS

usb_struc	STRUC

u_per		DB 1024 DUP (?)

root_dev        qtd_struc <>
hub_dev         qtd_struc <>

control_setup   DD 8 DUP(?)
control_data    DD 8 DUP(?)
control_status  DD 8 DUP(?)

descr           DB 8 * 64 DUP(?)
control_msg     DB 8 DUP(?)
port_state      DD ?

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
;           NAME:           CreateControl
;
;           DESCRIPTION:    Create control
;
;           PARAMETERS:     ES:EDX	Function linear
;                           AL          Address
;
;           RETURNS:        ES:EDI      QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl	Proc near    
    mov ds:mon_usb_adr,al
;
    cmp al,1
    je ccRoot
;
    cmp al,2
    je ccHub
;
    stc
    jmp ccDone

ccRoot:
    mov edi,ds:mon_usb_linear
    add edi,OFFSET root_dev
    mov es:[edi].qh_link,edi
    mov es:[edi].qh_adress,0
    mov es:[edi].qh_endpoint,0E0h
    mov es:[edi].qh_max_packet,0A008h
    mov es:[edi].qh_s_mask,0
    mov es:[edi].qh_c_mask,0
    mov es:[edi].qh_hub_port,4000h
    mov es:[edi].qh_current_qtd,0
    mov es:[edi].qh_next_qtd,1
    mov es:[edi].qh_alt_qtd,1
    mov es:[edi].qh_status,0
    mov es:[edi].qh_flags,0
    mov es:[edi].qh_size,0
    mov es:[edi].qh_page0,0    
    mov es:[edi].qh_page1,0    
    mov es:[edi].qh_page2,0    
    mov es:[edi].qh_page3,0    
    mov es:[edi].qh_page4,0
;
    push edi
    mov eax,edi
    mov edi,ds:mon_usb_oper
    mov es:[edi+18h],eax
    xor eax,eax
    mov es:[edi+10h],eax
    mov eax,es:[edi]
    or al,20h
    mov es:[edi],eax
    pop edi
    clc
    jmp ccDone

ccHub:
    int 3
    mov edi,ds:mon_usb_linear
    add edi,OFFSET hub_dev
    clc

ccDone:
    ret
CreateControl	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddSetup
;
;           DESCRIPTION:    Add setup
;
;           PARAMETERS:     ES:EDI	Device
;
;           RETURNS:        EDX         QTD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddSetup	Proc near
    push eax
;
    mov edx,ds:mon_usb_linear
    add edx,OFFSET control_setup
    mov es:[edx].qtd_next,1
    mov es:[edx].qtd_alt,1
    mov es:[edx].qtd_status,80h
    mov es:[edx].qtd_size,8
;
    mov al,0Eh  
    mov es:[edx].qtd_flags,al
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_msg
    mov es:[edx].qtd_page0,eax
;
    mov es:[edx].qtd_page1,0
    mov es:[edx].qtd_page2,0
    mov es:[edx].qtd_page3,0
    mov es:[edx].qtd_page4,0
;
    mov es:[edi].qh_status,0
;
    pop eax
    ret
AddSetup	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddIn
;
;           DESCRIPTION:    Add in
;
;           PARAMETERS:     ES:EDI	Device
;                           ES:ESI      Data
;                           CX          Size
;                           EDX         Prev QTD
;
;           RETURNS:        EDX         QTD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIn	Proc near
    push eax
;
    mov eax,edx
    mov edx,ds:mon_usb_linear
    add edx,OFFSET control_data
;
    mov es:[eax].qtd_next,edx
;    
    mov es:[edx].qtd_next,1
    mov es:[edx].qtd_alt,1
    mov es:[edx].qtd_status,80h
;
    mov al,0Dh  
    mov es:[edx].qtd_flags,al
;
    mov es:[edx].qtd_page0,esi
    mov es:[edx].qtd_page1,0
    mov es:[edx].qtd_page2,0
    mov es:[edx].qtd_page3,0
    mov es:[edx].qtd_page4,0
    mov ax,cx
    or ax,8000h
    mov es:[edx].qtd_size,ax
;
    pop eax
    ret
AddIn	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddStatusOut
;
;           DESCRIPTION:    Add status out
;
;           PARAMETERS:     ES:EDI	Device
;                           EDX         Prev QTD
;
;           RETURNS:        EDX         QTD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusOut	Proc near
    push eax
;
    mov eax,edx
    mov edx,ds:mon_usb_linear
    add edx,OFFSET control_status
    mov es:[eax].qtd_next,edx
;    
    mov es:[edx].qtd_next,1
    mov es:[edx].qtd_alt,1
    mov es:[edx].qtd_status,80h
    mov es:[edx].qtd_size,8000h
;
    mov al,0Dh  
    mov es:[edx].qtd_flags,al
;
    mov es:[edx].qtd_page0,0
    mov es:[edx].qtd_page1,0
    mov es:[edx].qtd_page2,0
    mov es:[edx].qtd_page3,0
    mov es:[edx].qtd_page4,0
;
    pop eax
    ret
AddStatusOut	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddStatusIn
;
;           DESCRIPTION:    Add status in
;
;           PARAMETERS:     ES:EDI	Device
;                           EDX         Prev QTD
;
;           RETURNS:        EDX         QTD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusIn	Proc near
    push eax
;
    mov eax,edx
    mov edx,ds:mon_usb_linear
    add edx,OFFSET control_status
    mov es:[eax].qtd_next,edx
;    
    mov es:[edx].qtd_next,1
    mov es:[edx].qtd_alt,1
    mov es:[edx].qtd_status,80h
    mov es:[edx].qtd_size,8000h
;
    mov al,0Ch  
    mov es:[edx].qtd_flags,al
;
    mov es:[edx].qtd_page0,0
    mov es:[edx].qtd_page1,0
    mov es:[edx].qtd_page2,0
    mov es:[edx].qtd_page3,0
    mov es:[edx].qtd_page4,0
;
    pop eax
    ret
AddStatusIn	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RunControl
;
;           DESCRIPTION:    Run control
;
;           PARAMETERS:     ES:EDI	Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunControl	Proc near
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_setup
    mov es:[edi].qh_next_qtd,eax
    ret
RunControl	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           WaitControl
;
;           DESCRIPTION:    Wait control
;
;           PARAMETERS:     ES:EDI	Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitControl	Proc near
    mov esi,ds:mon_usb_root_port

wcRetry:
    mov eax,es:[esi]
    test al,1
    stc
    jz wcDone
;
    mov ax,1
    call WaitMs
;
    mov al,es:[edi].qh_status
    test al,40h
    stc
    jnz wcDone
;
    mov eax,es:[edi].qh_next_qtd
    test al,1
    jz wcRetry
;
    clc

wcDone:
    ret
WaitControl	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AddressDev
;
;           DESCRIPTION:    Address device
;
;           PARAMETERS:     ES:EDI	Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddressDev	Proc near    
    push edi
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
    mov es:[edi].usd_type,0
    mov es:[edi].usd_req,SET_ADDRESS
    movzx ax,ds:mon_usb_adr
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,0
    pop edi
;
    call AddSetup
    call AddStatusOut
    call RunControl
    call WaitControl
    jc adDone
;
    mov al,ds:mon_usb_adr
    mov es:[edi].qh_adress,al
    clc

adDone:
    ret
AddressDev	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetDescr
;
;           DESCRIPTION:    Get descriptor
;
;           PARAMETERS:     ES:EDI	Device
;                           CX          Size
;                           AX          Descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDescr	Proc near    
    push edi
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,80h
    mov es:[edi].usd_req,GET_DESCR
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,cx
    pop edi
;
    mov esi,ds:mon_usb_linear
    add esi,OFFSET descr
    call AddSetup
    call AddIn
    call AddStatusIn
    call RunControl
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
;   PARAMETERS:     ES:EDI	Device
;                   AL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigDevice   Proc near
    push edi
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,0
    mov es:[edi].usd_req,SET_CONFIG
    movzx ax,al
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,0
    pop edi
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
;           NAME:           GetHubDescr
;
;           DESCRIPTION:    Get hub descriptor
;
;           PARAMETERS:     ES:EDI	Device
;                           CX          Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetHubDescr	Proc near    
    push edi
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,0A0h
    mov es:[edi].usd_req,GET_DESCR
    mov es:[edi].usd_value,2900h
    mov es:[edi].usd_index,0
    mov es:[edi].usd_len,cx
    pop edi
;
    mov esi,ds:mon_usb_linear
    add esi,OFFSET descr
    call AddSetup
    call AddIn
    call AddStatusIn
    call RunControl
    call WaitControl
    ret
GetHubDescr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetPortFeature
;
;   description:    Set port feature
;
;   PARAMETERS:     ES:EDI	Device
;                   DX          Port [0..ports]
;                   AX          Feature
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPortFeature  Proc near
    push edi
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,23h
    mov es:[edi].usd_req,SET_FEATURE
    mov es:[edi].usd_value,ax
    mov es:[edi].usd_index,dx
    mov es:[edi].usd_len,0
    pop edi
;
    push edx
    call AddSetup
    call AddStatusOut
    call RunControl
    call WaitControl
    pop edx
    ret
SetPortFeature Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;   NAME:           GetPortStatus
;
;   description:    Get port status
;
;   PARAMETERS:     ES:EDI	Device
;                   DX          Port [0..ports]
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPortStatus  Proc near
    push edi
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_msg
;
    mov es:[edi].usd_type,0A3h
    mov es:[edi].usd_req,GET_STATUS
    mov es:[edi].usd_value,0
    mov es:[edi].usd_index,dx
    mov es:[edi].usd_len,4
    pop edi
;
    push edx
    mov esi,ds:mon_usb_linear
    add esi,OFFSET port_state
    call AddSetup
    call AddIn
    call AddStatusIn
    call RunControl
    call WaitControl
    pop edx
    ret
GetPortStatus Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;   NAME:           CheckHub
;
;   DESCRIPTION:    Check hub
;
;   PARAMETERS:     ES:EDI	Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckHub	Proc near    
    pushad
;
    mov edx,ds:mon_usb_linear
    add edx,OFFSET descr
;
    mov al,es:[edx].uhd_ports
    mov ds:mon_usb_ports,al
;
    mov al,es:[edx].uhd_power_time
    mov ds:mon_hub_power,al
;
    movzx ecx,ds:mon_usb_ports
    xor dx,dx

chPowerLoop:
    mov ax,PORT_POWER
    call SetPortFeature    
;
    inc dx
    loop chPowerLoop

    int 3
;
    movzx ecx,ds:mon_usb_ports
    xor dx,dx

chStateLoop:
    call GetPortStatus
    int 3
;
    inc dx
    loop chStateLoop

chDone:
    popad
    ret
CheckHub	Endp

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
    mov ds:mon_usb_root_port,edi
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
    mov eax,es:[edi]
    and al,NOT 4
    or ax,100h
    mov es:[edi],eax
;
    mov ax,25
    call WaitMs
;
    mov eax,es:[edi]
    and ax,NOT 100h
    mov es:[edi],eax
;
    mov ax,25
    call WaitMs
;
    mov eax,es:[edi]
    test al,1
    jz cfConnNext
;
    test al,4
    jz cfConnNext
;
    mov bx,10

cfWaitEnable:    
    mov ax,1
    call WaitMs
;
    mov eax,es:[edi]
    test al,1
    jz cfConnNext
;
    test al,4
    jz cfConnNext
;
    test ax,100h
    jz cfEnabled
;
    sub bx,1
    jnz cfWaitEnable
    jmp cfConnNext

cfEnabled:
    mov al,1
    call CreateControl
    jc cfDisable
;
    call AddressDev
    jc cfDisable
;
    push ecx
    mov cx,8
    mov ax,100h
    call GetDescr 
    pop ecx
    jc cfDisable
;    
    mov edx,ds:mon_usb_linear
    add edx,OFFSET descr
    movzx ax,es:[edx].udd_maxlen
    or ax,ax
    jz cfDisable
;
    or ax,0A000h
    mov es:[edi].qh_max_packet,ax
;
    mov edx,ds:mon_usb_linear
    add edx,OFFSET descr
    movzx ax,byte ptr es:[edx]
    cmp ax,es:[edi].qh_max_packet
    ja cfDisable
;
    push ecx
    mov cx,ax
    mov ax,100h
    call GetDescr 
    pop ecx
    jc cfDisable
;
    mov edx,ds:mon_usb_linear
    add edx,OFFSET descr
    mov al,es:[edx].udd_class
    cmp al,9
    jne cfDisable
;
    push ecx
    mov cx,8
    mov ax,200h
    call GetDescr
    pop ecx
    jc cfDisable
;
    mov edx,ds:mon_usb_linear
    add edx,OFFSET descr
    mov ax,es:[edx+2]
;
    push ecx
    mov cx,ax
    mov ax,200h
    call GetDescr
    pop ecx
;
    jc cfDisable

cfConfig:
    mov edx,ds:mon_usb_linear
    add edx,OFFSET descr
    mov al,es:[edx].ucd_config_id
    call ConfigDevice
    jc cfDisable
;
    push ecx
    mov cx,SIZE usb_hub_descr
    call GetHubDescr
    pop ecx
    jc cfDisable
;
    call CheckHub

cfDisable:
    mov eax,es:[edi]
    and al,NOT 4
    mov es:[edi],eax
;
    mov bx,10

cfWaitDisable:    
    mov ax,1
    call WaitMs
;
    mov eax,es:[edi]
    test al,1
    jz cfConnNext
;
    test al,4
    jz cfConnNext
;
    sub bx,1
    jnz cfWaitDisable

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
