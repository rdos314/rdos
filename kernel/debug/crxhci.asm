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

trb_struc   STRUC

trb_param   DD ?,?
trb_status  DD ?
trb_type    DW ?
trb_control DW ?

trb_struc   ENDS

input_control_context_struc STRUC

icc_drop_mask   DD ?
icc_add_mask    DD ?
icc_pad1        DD 5 DUP(?)
icc_config      DB ?
icc_interface   DB ?
icc_alt         DB ?
icc_pad2        DB ?

input_control_context_struc ENDS

slot_struc  STRUC

s_misc          DD ?
s_exit_latency  DW ?
s_root_hub      DB ?
s_hub_ports     DB ?
s_tt_slot_id    DB ?
s_tt_port_nr    DB ?
s_ttt_int       DW ?
s_address       DB ?
s_pad1          DB ?
s_state         DW ?

slot_struc  ENDS

endpoint_context_struc  STRUC

ec_state        DB ?
ec_param1       DB ?
ec_interval     DB ?
ec_esit_hi      DB ?
ec_param2       DB ?
ec_burst_size   DB ?
ec_packet_size  DW ?
ec_tr_dequeue   DD ?,?
ec_avg_len      DW ?
ec_esit_low     DD ?

endpoint_context_struc  ENDS


usb_struc	STRUC

dc1             DB 100h DUP(?)
erst1           DB 100h DUP(?)
input_context   DB 100h DUP(?)
control_ring    DB 100h DUP(?)
cmd             DB 40h DUP(?)
erst            DB 10h DUP(?)

dcba            DD ?,?

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
;           NAME:           CheckWait
;
;           DESCRIPTION:    Check wait
;
;           PARAMETERS:     ES:EDX	Function linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
CheckWait       PROC near
    mov edi,ds:mon_xhci_runtime
    mov ecx,1000000
    mov eax,es:[edi]

cwLoop:
    cmp eax,es:[edi]
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
    mov edi,ds:mon_xhci_runtime
    mov eax,es:[edi]

wmLoop:
    cmp eax,es:[edi]
    je wmLoop
;
    mov eax,es:[edi]
    loop wmLoop
;
    popad
    ret
WaitMs       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetEvent
;
;       DESCRIPTION:    Get event
;
;       RETURNS:        AL		Event ID
;                       ES:EDI          Event data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEvent   Proc near
    push edx
    push esi
;
    mov esi,ds:mon_event_deque
    mov eax,es:[esi+12]
    mov dx,ds:mon_event_ccs
    and al,1
    xor dl,al
    stc
    jnz geDone
;
    shr ax,10
    and ax,3Fh
    mov dl,al
;    
    mov edi,esi
    add esi,10h
    mov eax,esi
    sub eax,ds:mon_usb_linear
    sub eax,OFFSET erst1
    cmp eax,100h
    jne geSave
;
    xor ds:mon_event_ccs,1
    mov eax,ds:mon_usb_linear
    add eax,OFFSET erst1

geSave:
    mov ds:mon_event_deque,esi
    mov eax,esi
    or al,8
    mov esi,ds:mon_xhci_runtime
    mov es:[esi+38h],eax
    mov al,dl
    clc

geDone:
    pop esi
    pop edx
    ret
GetEvent   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClearEvents
;
;       DESCRIPTION:    Clear events
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearEvents   Proc near
    push eax
    push edi

ceLoop:
    call GetEvent
    jnc ceLoop
;
    pop edi
    pop eax
    ret
ClearEvents  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetCommandTrb
;
;       DESCRIPTION:    Get empty command TRB
;
;       RETURNS:        ES:EDI     TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCommandTrb   Proc near
    push eax
;
    mov edi,ds:mon_cmd_enque
    mov eax,edi
    add eax,SIZE trb_struc
    mov ds:mon_cmd_enque,eax
;
    mov es:[edi].trb_param,0
    mov es:[edi].trb_param+4,0
    mov es:[edi].trb_status,0
    mov es:[edi].trb_control,0
;
    pop eax        
    ret
GetCommandTrb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendCommandTrb
;
;       DESCRIPTION:    Send command TRB
;
;       PARAMETERS:     AL      TRB type
;                       ES:EDI  TRB offset
;
;       RETURNS:        ES:EDI  Event data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCommandTrb   Proc near
    push eax
;
    movzx ax,al
    shl ax,10
    or ax,ds:mon_cmd_pcs
    mov es:[edi].trb_type,ax
;
    mov edi,ds:mon_xhci_door_bell
    xor eax,eax
    mov es:[edi],eax
;
    mov ax,1
    call WaitMs

sctWait:
    call GetEvent
    jc sctDone
;
    cmp al,21h
    jnz sctWait

sctDone:
    pop eax
    ret
SendCommandTrb  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EnableSlot
;
;       DESCRIPTION:    Enable slot
;
;       RETURNS:        AL	Slot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableSlot   Proc near
    push edi
;
    call GetCommandTrb
    mov al,TRB_TYPE_ENABLE_SLOT
    call SendCommandTrb
    jc esDone
;
    mov al,es:[edi+15]
    clc

esDone:
    pop edi
    ret
EnableSlot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisableSlot
;
;       DESCRIPTION:    Disable slot
;
;       PARAMETERS:     AL      Slot ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisableSlot  Proc near
    push edx
    push edi
;
    mov dl,al
    call GetCommandTrb
    mov ah,dl
    xor al,al
    mov es:[edi].trb_control,ax
    mov al,TRB_TYPE_DISABLE_SLOT
    call SendCommandTrb
    jc dsDone
;
    cmp dl,es:[edi+15]
    stc 
    jne dsDone
;
    clc

dsDone:
    pop edi
    pop edx
    ret
DisableSlot  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddressDevice
;
;   DESCRIPTION:    Address device
;
;   PARAMETERS:     AL      Slot ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


AddressDevice   Proc near
    push ecx
    push edx
    push edi
;    
    mov dl,al
    mov edi,ds:mon_usb_linear
    add edi,OFFSET control_ring
    mov ecx,3Ch
    xor eax,eax
    rep stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_ring
    stosd
    xor eax,eax
    stosd
    stosd
    mov eax,2 + (TRB_TYPE_LINK SHL 10)
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_ring
    mov ds:mon_control_enque,eax
    mov ds:mon_control_deque,eax
    mov ds:mon_control_pcs,1
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET input_context
    mov ecx,40h
    xor eax,eax
    rep stosd
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET input_context
    mov es:[edi].icc_add_mask,3
;    
    movzx eax,ds:mon_context_size
    add edi,eax
;
    mov eax,2 SHL 20
    or eax,08000000h
    mov es:[edi].s_misc,eax
    mov al,ds:mon_usb_port
    mov es:[edi].s_root_hub,al
;    
    movzx eax,ds:mon_context_size
    add edi,eax
;
    mov ax,8
    mov es:[edi].ec_packet_size,ax
    mov es:[edi].ec_avg_len,ax
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET control_ring
    or al,1
    mov es:[edi].ec_tr_dequeue,eax
    xor eax,eax
    mov es:[edi].ec_tr_dequeue+4,eax        
;
    mov al,3 SHL 1
    or al,4 SHL 3
    mov es:[edi].ec_param2,al
;
    call GetCommandTrb
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET input_context
    mov es:[edi].trb_param,eax
    xor eax,eax
    mov es:[edi].trb_param+4,eax
;
    mov ah,dl
    xor al,al
    mov es:[edi].trb_control,ax
;
    mov al,TRB_TYPE_ADDRESS_DEV
    call SendCommandTrb
    jc adDone
;
    mov al,es:[edi+11]
    cmp al,1    
    stc
    jnz adDone
;
    cmp dl,es:[edi+15]
    stc 
    jne adDone
;
    clc

adDone:
    pop edi
    pop edx
    pop ecx
    ret
AddressDevice   Endp
    
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
    mov al,es:[edx+7]
    mov ds:mon_usb_ports,al
    or al,al
    jz cfFail
;
    mov eax,es:[edx+10h]
    mov ds:mon_xhci_param,eax
;
    mov cx,20h
    test al,4
    jz cfContextSizeOk
;
    mov cx,40h

cfContextSizeOk:
    mov ds:mon_context_size,cx    
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
    mov ds:mon_cmd_enque,edi
    mov ds:mon_cmd_pcs,1
    mov ecx,0Ch
    xor eax,eax
    rep stosd
;
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
    or al,1
    mov es:[edx+18h],eax
    xor eax,eax
    mov es:[edx+1Ch],eax
;
    mov edi,ds:mon_usb_linear
    add edi,OFFSET erst1
    mov ds:mon_event_deque,edi
    mov ds:mon_event_ccs,1
    mov ecx,40h
    xor eax,eax
    rep stosd
;
    mov edi,ds:mon_usb_linear
    add eax,OFFSET erst1
    add eax,edi
    add edi,OFFSET erst
    stosd
    xor eax,eax
    stosd
    mov eax,10h
    stosd
    xor eax,eax
    stosd
;
    mov edi,ds:mon_xhci_runtime
    add edi,20h
    xor eax,eax
    stosd
    stosd
;
    mov eax,1
    stosd
    xor eax,eax
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET erst
    stosd
    xor eax,eax
    stosd
;
    mov eax,ds:mon_usb_linear
    add eax,OFFSET erst
    stosd
    xor eax,eax
    stosd
;
    mov edi,ds:mon_xhci_oper
    mov eax,es:[edi]
    or al,1
    mov es:[edi],eax
;
    movzx ecx,ds:mon_usb_ports
    mov edi,ds:mon_xhci_oper
    add edi,400h

cfPowerLoop:
    mov eax,es:[edi]
    and eax,00FE3FE3h
    or ax,202h
    mov es:[edi],eax
    add edi,10h
    loop cfPowerLoop
;
    call CheckWait
    jc cfFail
;
    movzx ecx,ds:mon_usb_ports
    mov edi,ds:mon_xhci_oper
    add edi,400h
    mov ds:mon_usb_port,1

cfConnLoop:
    mov eax,es:[edi]
    test al,1
    jz cfConnNext
;
    mov eax,210h
    mov es:[edi],eax

cfResetLoop:
    mov eax,es:[edi]
    test al,1
    jz cfDisable
;
    test al,10h
    jz cfResetDone    
;
    mov ax,25
    call WaitMs
    jmp cfResetLoop    

cfResetDone:
    call ClearEvents
;
    mov eax,es:[edi]
    shr ax,10
    and al,0Fh
    cmp al,2
    jne cfDisable
;
    mov eax,es:[edi]
    test al,2
    jz cfDisable
;
    call EnableSlot
    jc cfDisable
;
    int 3
    mov ds:mon_usb_adr,al
    call AddressDevice
    jc cfDisableSlot

cfDisableSlot:
    mov al,ds:mon_usb_adr
    call DisableSlot

cfDisable:
    mov eax,2
    mov es:[edi],eax

cfConnNext:
    inc ds:mon_usb_port
    add edi,10h
    loop cfConnLoop
;
    mov edi,ds:mon_xhci_oper
    mov eax,es:[edi]
    and al,NOT 1
    or al,2
    mov es:[edi],eax

cfWaitHlt:
    mov eax,es:[edi+4]
    test al,1
    jz cfWaitHlt
 
cfFail:
    stc

cfDone:
    popad
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
