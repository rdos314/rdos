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
; SMA.ASM
; SMA speedwire support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.inc

.386p

data    SEGMENT byte public 'DATA'

sma_volt                DD 4 DUP(?)
sma_current             DD 4 DUP(?)
sma_active_pos_power    DD 4 DUP(?)
sma_active_neg_power    DD 4 DUP(?)
sma_reactive_pos_power  DD 4 DUP(?)
sma_reactive_neg_power  DD 4 DUP(?)
sma_im_pos_power        DD 4 DUP(?)
sma_im_neg_power        DD 4 DUP(?)
sma_active_pos_energy   DD 4 DUP(?,?)
sma_active_neg_energy   DD 4 DUP(?,?)
sma_reactive_pos_energy DD 4 DUP(?,?)
sma_reactive_neg_energy DD 4 DUP(?,?)
sma_im_pos_energy       DD 4 DUP(?,?)
sma_im_neg_energy       DD 4 DUP(?,?)
sma_phi                 DD ?

sma_wait                DW ?
sma_thread              DW ?
sma_busy                DB ?
sma_msg                 DB 600 DUP (?)

data    ENDS

code    SEGMENT byte public use32 'CODE'
    
    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Volt
;
;       DESCRIPTION:    Volt L1-L3
;
;       PARAMETERS:     BL	Phase
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Volt	Proc near
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    movzx ebx,bl
    shl ebx,2
    mov ds:[ebx].sma_volt,eax
    ret
Volt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Amp
;
;       DESCRIPTION:    Amp L1-L3
;
;       PARAMETERS:     BL	Phase
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Amp	Proc near
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    movzx ebx,bl
    shl ebx,2
    mov ds:[ebx].sma_current,eax
    ret
Amp	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Phi
;
;       DESCRIPTION:    Phi
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Phi	Proc near
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:sma_phi,eax
    ret
Phi	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PosActive
;
;       DESCRIPTION:    Active+ sum,L1-L3
;
;       PARAMETERS:     BL	Phase
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PosActive	Proc near
    cmp cx,8
    je PosActiveEnergy

PosActivePower:
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    movzx ebx,bl
    shl ebx,2
    mov ds:[ebx].sma_active_pos_power,eax
    ret

PosActiveEnergy:
    movzx ebx,bl
    shl ebx,3
;
    mov eax,[esi+4]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx].sma_active_pos_energy,eax
;
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx+4].sma_active_pos_energy,eax
    ret
PosActive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NegActive
;
;       DESCRIPTION:    Active- sum, L1-L3
;
;       PARAMETERS:     BL	Phase
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NegActive	Proc near
    cmp cx,8
    je NegActiveEnergy

NegActivePower:
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    movzx ebx,bl
    shl ebx,2
    mov ds:[ebx].sma_active_neg_power,eax
    ret

NegActiveEnergy:
    movzx ebx,bl
    shl ebx,3
;
    mov eax,[esi+4]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx].sma_active_neg_energy,eax
;
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx+4].sma_active_neg_energy,eax
    ret
NegActive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PosReactive
;
;       DESCRIPTION:    Reactive+ sum,L1-L3
;
;       PARAMETERS:     BL	Phase
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PosReactive	Proc near
    cmp cx,8
    je PosReactiveEnergy

PosReactivePower:
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    movzx ebx,bl
    shl ebx,2
    mov ds:[ebx].sma_reactive_pos_power,eax
    ret

PosReactiveEnergy:
    movzx ebx,bl
    shl ebx,3
;
    mov eax,[esi+4]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx].sma_reactive_pos_energy,eax
;
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx+4].sma_reactive_pos_energy,eax
    ret
PosReactive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NegReactive
;
;       DESCRIPTION:    Reactive- sum,L1-L3
;
;       PARAMETERS:     BL	Phase
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NegReactive	Proc near
    cmp cx,8
    je NegReactiveEnergy

NegReactivePower:
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    movzx ebx,bl
    shl ebx,2
    mov ds:[ebx].sma_reactive_neg_power,eax
    ret

NegReactiveEnergy:
    movzx ebx,bl
    shl ebx,3
;
    mov eax,[esi+4]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx].sma_reactive_neg_energy,eax
;
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx+4].sma_reactive_neg_energy,eax
    ret
NegReactive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PosIm
;
;       DESCRIPTION:    Imaginary+ sum,L1-L3
;
;       PARAMETERS:     BL	Phase
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PosIm	Proc near
    cmp cx,8
    je PosImEnergy

PosImPower:
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    movzx ebx,bl
    shl ebx,2
    mov ds:[ebx].sma_im_pos_power,eax
    ret

PosImEnergy:
    movzx ebx,bl
    shl ebx,3
;
    mov eax,[esi+4]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx].sma_im_pos_energy,eax
;
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx+4].sma_im_pos_energy,eax
    ret
PosIm	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NegIm
;
;       DESCRIPTION:    Imaginary- sum,L1-L3
;
;       PARAMETERS:     BL	Phase
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NegIm	Proc near
    cmp cx,8
    je NegImEnergy

NegImPower:
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    movzx ebx,bl
    shl ebx,2
    mov ds:[ebx].sma_im_neg_power,eax
    ret

NegImEnergy:
    movzx ebx,bl
    shl ebx,3
;
    mov eax,[esi+4]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx].sma_im_neg_energy,eax
;
    mov eax,[esi]
    xchg al,ah
    rol eax,16
    xchg al,ah
    mov ds:[ebx+4].sma_im_neg_energy,eax
    ret
NegIm	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Voltx
;
;       DESCRIPTION:    Volt L1-L3
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VoltL1:
    mov bl,1
    jmp Volt

VoltL2:
    mov bl,2
    jmp Volt

VoltL3:
    mov bl,3
    jmp Volt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Ampc
;
;       DESCRIPTION:    Amp L1-L3
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AmpL1:
    mov bl,1
    jmp Amp

AmpL2:
    mov bl,2
    jmp Amp

AmpL3:
    mov bl,3
    jmp Amp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PosActivec
;
;       DESCRIPTION:    Active+ L1-L3
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PosActiveSum:
    mov bl,0
    jmp PosActive

PosActiveL1:
    mov bl,1
    jmp PosActive

PosActiveL2:
    mov bl,2
    jmp PosActive

PosActiveL3:
    mov bl,3
    jmp PosActive

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NegActivec
;
;       DESCRIPTION:    Active- L1-L3
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NegActiveSum:
    mov bl,0
    jmp NegActive

NegActiveL1:
    mov bl,1
    jmp NegActive

NegActiveL2:
    mov bl,2
    jmp NegActive

NegActiveL3:
    mov bl,3
    jmp NegActive

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PosReactivec
;
;       DESCRIPTION:    Reactive+ L1-L3
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PosReactiveSum:
    mov bl,0
    jmp PosReactive

PosReactiveL1:
    mov bl,1
    jmp PosReactive

PosReactiveL2:
    mov bl,2
    jmp PosReactive

PosReactiveL3:
    mov bl,3
    jmp PosReactive

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NegReactivec
;
;       DESCRIPTION:    Reactive- L1-L3
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NegReactiveSum:
    mov bl,0
    jmp NegReactive

NegReactiveL1:
    mov bl,1
    jmp NegReactive

NegReactiveL2:
    mov bl,2
    jmp NegReactive

NegReactiveL3:
    mov bl,3
    jmp NegReactive

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PosImc
;
;       DESCRIPTION:    Imaginary+ L1-L3
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PosImSum:
    mov bl,0
    jmp PosIm

PosImL1:
    mov bl,1
    jmp PosIm

PosImL2:
    mov bl,2
    jmp PosIm

PosImL3:
    mov bl,3
    jmp PosIm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NegImc
;
;       DESCRIPTION:    Imaginary- L1-L3
;
;       PARAMETERS:     DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NegImSum:
    mov bl,0
    jmp NegIm

NegImL1:
    mov bl,1
    jmp NegIm

NegImL2:
    mov bl,2
    jmp NegIm

NegImL3:
    mov bl,3
    jmp NegIm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleData
;
;       DESCRIPTION:    Handle data
;
;       PARAMETERS:     BL      Channel
;                       ECX     Message size
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ignore	Proc near
    ret
ignore  Endp

hdTable:
hd00  DD OFFSET ignore
hd01  DD OFFSET PosActiveSum
hd02  DD OFFSET NegActiveSum
hd03  DD OFFSET PosReactiveSum
hd04  DD OFFSET NegReactiveSum
hd05  DD OFFSET ignore
hd06  DD OFFSET ignore
hd07  DD OFFSET ignore
hd08  DD OFFSET ignore
hd09  DD OFFSET PosImSum
hd10  DD OFFSET NegImSum
hd11  DD OFFSET ignore
hd12  DD OFFSET ignore
hd13  DD OFFSET Phi
hd14  DD OFFSET ignore
hd15  DD OFFSET ignore
hd16  DD OFFSET ignore
hd17  DD OFFSET ignore
hd18  DD OFFSET ignore
hd19  DD OFFSET ignore
hd20  DD OFFSET ignore
hd21  DD OFFSET PosActiveL1
hd22  DD OFFSET NegActiveL1
hd23  DD OFFSET PosReactiveL1
hd24  DD OFFSET NegReactiveL1
hd25  DD OFFSET ignore
hd26  DD OFFSET ignore
hd27  DD OFFSET ignore
hd28  DD OFFSET ignore
hd29  DD OFFSET PosImL1
hd30  DD OFFSET NegImL1
hd31  DD OFFSET AmpL1
hd32  DD OFFSET VoltL1
hd33  DD OFFSET ignore
hd34  DD OFFSET ignore
hd35  DD OFFSET ignore
hd36  DD OFFSET ignore
hd37  DD OFFSET ignore
hd38  DD OFFSET ignore
hd39  DD OFFSET ignore
hd40  DD OFFSET ignore
hd41  DD OFFSET PosActiveL2
hd42  DD OFFSET NegActiveL2
hd43  DD OFFSET PosReactiveL2
hd44  DD OFFSET NegReactiveL2
hd45  DD OFFSET ignore
hd46  DD OFFSET ignore
hd47  DD OFFSET ignore
hd48  DD OFFSET ignore
hd49  DD OFFSET PosImL2
hd50  DD OFFSET NegImL2
hd51  DD OFFSET AmpL2
hd52  DD OFFSET VoltL2
hd53  DD OFFSET ignore
hd54  DD OFFSET ignore
hd55  DD OFFSET ignore
hd56  DD OFFSET ignore
hd57  DD OFFSET ignore
hd58  DD OFFSET ignore
hd59  DD OFFSET ignore
hd60  DD OFFSET ignore
hd61  DD OFFSET PosActiveL3
hd62  DD OFFSET NegActiveL3
hd63  DD OFFSET PosReactiveL3
hd64  DD OFFSET NegReactiveL3
hd65  DD OFFSET ignore
hd66  DD OFFSET ignore
hd67  DD OFFSET ignore
hd68  DD OFFSET ignore
hd69  DD OFFSET PosImL3
hd70  DD OFFSET NegImL3
hd71  DD OFFSET AmpL3
hd72  DD OFFSET VoltL3
hd73  DD OFFSET ignore
hd74  DD OFFSET ignore
hd75  DD OFFSET ignore
hd76  DD OFFSET ignore
hd77  DD OFFSET ignore
hd78  DD OFFSET ignore
hd79  DD OFFSET ignore

HandleData	Proc near
    cmp bl,80
    jae hdDone
;
    movzx ebx,bl
    shl ebx,2
    call dword ptr cs:[ebx].hdTable

hdDone:
    ret
HandleData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleTag
;
;       DESCRIPTION:    Handle tag
;
;       PARAMETERS:     BX	Tag ID
;                       CX      Message size
;                       DS:ESI  Message data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTag	Proc near
    cmp bx,10h
    jne htDone
;
    mov ax,[esi]
    xchg al,ah
    cmp ax,6069h
    jne htDone
;    
    push ecx
    push esi
;
    add esi,12
    sub cx,12

htLoop:
    lodsw
    mov bx,ax
    xchg bl,bh
;
    lodsw
    or al,al
    jz htPop
;
    push ecx
    movzx ecx,al
    call HandleData
    mov eax,ecx
    pop ecx
;
    add esi,eax
    add ax,4
    sub cx,ax
    jnz htLoop

htPop:
    pop esi
    pop ecx

htDone:
    ret
HandleTag	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleMsg
;
;       DESCRIPTION:    Handle SMA message
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sma_txt   DB 'SMA', 0

HandleMsg	Proc near
    pushad
;
    mov esi,OFFSET sma_msg
    lodsd
    cmp eax,dword ptr cs:sma_txt
    jne hmDone

hmLoop:
    lodsw
    xchg al,ah
    movzx ecx,ax
    or ecx,ecx
    jz hmDone
;
    lodsw
    xchg al,ah
    mov bx,ax
    call HandleTag
;
    add esi,ecx
    jmp hmLoop

hmDone:
    popad
    ret
HandleMsg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           sma_rec
;
;       DESCRIPTION:    SMA data received
;
;       PARAMETERS:     EDX	IP
;                       CX      Size
;                       ES:EDI  Data
;
;       RETURNS:        CX      Reply size (or 0)
;                       ES:EDI  Reply data           
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sma_rec	Proc far
    push ds
    push eax
    push ebx
    push esi
;
    mov eax,SEG data
    mov ds,eax
    mov al,ds:sma_busy
    or al,al
    jnz srDone
;
    cmp cx,600
    ja srDone
;
    mov esi,edi
    movzx ecx,cx
    mov eax,es
    mov ds,eax
    mov eax,SEG data
    mov es,eax
    mov edi,OFFSET sma_msg
    rep movsb
;
    mov es:sma_busy,1
    mov bx,es:sma_thread
    Signal

srDone:
    xor cx,cx
;
    pop esi
    pop ebx
    pop eax
    pop ds
    ret
sma_rec Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           sma_thread
;
;           DESCRIPTION:    SMA thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sma_name	DB 'SMA', 0

sma_pr:
    mov ax,SEG data
    mov ds,eax
    GetThread
    mov ds:sma_thread,ax
    mov ds:sma_busy,0
    mov ds:sma_wait,0
;
    mov si,9522
    mov eax,cs
    mov es,eax
    mov edi,OFFSET sma_rec
    ListenUdpPort

sLoop:
    WaitForSignal
    call HandleMsg
    mov ds:sma_busy,0
    xor bx,bx
    xchg bx,ds:sma_wait
    Signal
    jmp sLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitAcMeassure
;
;       DESCRIPTION:    Wait AC Meassure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_ac_meassure_name	DB 'Wait AC Meassure', 0

wait_ac_meassure  PROC far
    push ds
    push ebx
;
    mov ebx,SEG data
    mov ds,ebx
    GetThread
    ClearSignal
    mov ds:sma_wait,ax
    WaitForSignal
;
    pop ebx
    pop ds
    ret
wait_ac_meassure  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetAcVoltage
;
;       DESCRIPTION:    Get AC Voltage
;
;       PARAMETERS:     BL	Phase (1 = L1, 2 = L2, 3 = L3)          
;
;       RETURNS:        EAX	Voltage (mv)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ac_voltage_name	DB 'Get AC Voltage', 0

get_ac_voltage  PROC far
    push ds
    push ebx
;
    mov ax,SEG data
    mov ds,eax
;
    or bl,bl
    jz gvFail
;
    cmp bl,3
    ja gvFail
;
    movzx ebx,bl
    shl ebx,2
    mov eax,ds:[ebx].sma_volt
    clc
    jmp gvDone

gvFail:
    stc

gvDone: 
    pop ebx
    pop ds
    ret
get_ac_voltage	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetAcCurrent
;
;       DESCRIPTION:    Get AC Current
;
;       PARAMETERS:     BL	Phase (1 = L1, 2 = L2, 3 = L3)          
;
;       RETURNS:        EAX	Current (mA)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ac_current_name	DB 'Get AC Current', 0

get_ac_current  PROC far
    push ds
    push ebx
;
    mov ax,SEG data
    mov ds,eax
;
    or bl,bl
    jz gcFail
;
    cmp bl,3
    ja gcFail
;
    movzx ebx,bl
    shl ebx,2
    mov eax,ds:[ebx].sma_current
    clc
    jmp gcDone

gcFail:
    stc

gcDone: 
    pop ebx
    pop ds
    ret
get_ac_current	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetAcConsumePower
;
;       DESCRIPTION:    Get AC Consume Power
;
;       PARAMETERS:     BL	Phase (0 = total, 1 = L1, 2 = L2, 3 = L3)          
;
;       RETURNS:        EAX	Power (0.1W)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ac_consume_power_name	DB 'Get AC Consume Power', 0

get_ac_consume_power  PROC far
    push ds
    push ebx
;
    mov ax,SEG data
    mov ds,eax
;
    cmp bl,3
    ja gcpFail
;
    movzx ebx,bl
    shl ebx,2
    mov eax,ds:[ebx].sma_active_pos_power
    clc
    jmp gcpDone

gcpFail:
    stc

gcpDone: 
    pop ebx
    pop ds
    ret
get_ac_consume_power	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetAcProducePower
;
;       DESCRIPTION:    Get AC Produce Power
;
;       PARAMETERS:     BL	Phase (0 = total, 1 = L1, 2 = L2, 3 = L3)          
;
;       RETURNS:        EAX	Power (0.1W)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ac_produce_power_name	DB 'Get AC Produce Power', 0

get_ac_produce_power  PROC far
    push ds
    push ebx
;
    mov ax,SEG data
    mov ds,eax
;
    cmp bl,3
    ja gppFail
;
    movzx ebx,bl
    shl ebx,2
    mov eax,ds:[ebx].sma_active_neg_power
    clc
    jmp gppDone

gppFail:
    stc

gppDone: 
    pop ebx
    pop ds
    ret
get_ac_produce_power	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetAcConsumeEnergy
;
;       DESCRIPTION:    Get AC Consume Energy
;
;       PARAMETERS:     BL	Phase (0 = total, 1 = L1, 2 = L2, 3 = L3)          
;
;       RETURNS:        EDX:EAX	Energy (Ws)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ac_consume_energy_name	DB 'Get AC Consume Energy', 0

get_ac_consume_energy  PROC far
    push ds
    push ebx
;
    mov ax,SEG data
    mov ds,eax
;
    cmp bl,3
    ja gceFail
;
    movzx ebx,bl
    shl ebx,3
    mov eax,ds:[ebx].sma_active_pos_energy
    mov edx,ds:[ebx+4].sma_active_pos_energy
    clc
    jmp gceDone

gceFail:
    stc

gceDone: 
    pop ebx
    pop ds
    ret
get_ac_consume_energy	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetAcProduceEnergy
;
;       DESCRIPTION:    Get AC Produce Energy
;
;       PARAMETERS:     BL	Phase (0 = total, 1 = L1, 2 = L2, 3 = L3)          
;
;       RETURNS:        EDX:EAX	Energy (Ws)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ac_produce_energy_name	DB 'Get AC Produce Energy', 0

get_ac_produce_energy  PROC far
    push ds
    push ebx
;
    mov ax,SEG data
    mov ds,eax
;
    cmp bl,3
    ja gpeFail
;
    movzx ebx,bl
    shl ebx,3
    mov eax,ds:[ebx].sma_active_neg_energy
    mov edx,ds:[ebx+4].sma_active_neg_energy
    clc
    jmp gpeDone

gpeFail:
    stc

gpeDone: 
    pop ebx
    pop ds
    ret
get_ac_produce_energy	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetAcEnergy
;
;       DESCRIPTION:    Get AC Energy
;
;       PARAMETERS:     BL	Phase (0 = total, 1 = L1, 2 = L2, 3 = L3)          
;
;       RETURNS:        EDX:EAX	Energy (Ws)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_ac_energy_name	DB 'Get AC Energy', 0

get_ac_energy  PROC far
    push ds
    push ebx
;
    mov ax,SEG data
    mov ds,eax
;
    cmp bl,3
    ja geFail
;
    movzx ebx,bl
    shl ebx,3
    mov eax,ds:[ebx].sma_active_pos_energy
    mov edx,ds:[ebx+4].sma_active_pos_energy
    sub eax,ds:[ebx].sma_active_neg_energy
    sbb eax,ds:[ebx+4].sma_active_neg_energy
    clc
    jmp geDone

geFail:
    stc

geDone: 
    pop ebx
    pop ds
    ret
get_ac_energy	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_sma
;
;           DESCRIPTION:    Init sma
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sma      PROC far
    push ds
    push es
    pushad
;    
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET sma_pr
    mov edi,OFFSET sma_name
    mov cx,stack0_size
    mov ax,3
    CreateThread
;    
    popad
    pop es
    pop ds
    ret
init_sma      ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov eax,cs
    mov ds,eax
    mov es,eax  
    mov edi,OFFSET init_sma
    HookInitTasking
;
    mov esi,OFFSET wait_ac_meassure
    mov edi,OFFSET wait_ac_meassure_name
    xor dx,dx
    mov ax,wait_ac_meassure_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_ac_voltage
    mov edi,OFFSET get_ac_voltage_name
    xor dx,dx
    mov ax,get_ac_voltage_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_ac_current
    mov edi,OFFSET get_ac_current_name
    xor dx,dx
    mov ax,get_ac_current_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_ac_consume_power
    mov edi,OFFSET get_ac_consume_power_name
    xor dx,dx
    mov ax,get_ac_consume_power_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_ac_produce_power
    mov edi,OFFSET get_ac_produce_power_name
    xor dx,dx
    mov ax,get_ac_produce_power_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_ac_consume_energy
    mov edi,OFFSET get_ac_consume_energy_name
    xor dx,dx
    mov ax,get_ac_consume_energy_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_ac_produce_energy
    mov edi,OFFSET get_ac_produce_energy_name
    xor dx,dx
    mov ax,get_ac_produce_energy_nr
    RegisterBimodalUserGate
    ret
init    ENDP
    

code    ENDS

    END init
