;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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

sma_thread  DW ?
sma_busy    DB ?
sma_msg     DB 600 DUP (?)

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
    int 3
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
    int 3
    ret
Amp	Endp

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
    mov bl,0
    jmp Volt

VoltL2:
    mov bl,1
    jmp Volt

VoltL3:
    mov bl,2
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
    mov bl,0
    jmp Amp

AmpL2:
    mov bl,1
    jmp Amp

AmpL3:
    mov bl,2
    jmp Amp

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
hd01  DD OFFSET ignore
hd02  DD OFFSET ignore
hd03  DD OFFSET ignore
hd04  DD OFFSET ignore
hd05  DD OFFSET ignore
hd06  DD OFFSET ignore
hd07  DD OFFSET ignore
hd08  DD OFFSET ignore
hd09  DD OFFSET ignore
hd10  DD OFFSET ignore
hd11  DD OFFSET ignore
hd12  DD OFFSET ignore
hd13  DD OFFSET ignore
hd14  DD OFFSET ignore
hd15  DD OFFSET ignore
hd16  DD OFFSET ignore
hd17  DD OFFSET ignore
hd18  DD OFFSET ignore
hd19  DD OFFSET ignore
hd20  DD OFFSET ignore
hd21  DD OFFSET ignore
hd22  DD OFFSET ignore
hd23  DD OFFSET ignore
hd24  DD OFFSET ignore
hd25  DD OFFSET ignore
hd26  DD OFFSET ignore
hd27  DD OFFSET ignore
hd28  DD OFFSET ignore
hd29  DD OFFSET ignore
hd30  DD OFFSET ignore
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
hd41  DD OFFSET ignore
hd42  DD OFFSET ignore
hd43  DD OFFSET ignore
hd44  DD OFFSET ignore
hd45  DD OFFSET ignore
hd46  DD OFFSET ignore
hd47  DD OFFSET ignore
hd48  DD OFFSET ignore
hd49  DD OFFSET ignore
hd50  DD OFFSET ignore
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
hd61  DD OFFSET ignore
hd62  DD OFFSET ignore
hd63  DD OFFSET ignore
hd64  DD OFFSET ignore
hd65  DD OFFSET ignore
hd66  DD OFFSET ignore
hd67  DD OFFSET ignore
hd68  DD OFFSET ignore
hd69  DD OFFSET ignore
hd70  DD OFFSET ignore
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
    jmp sLoop

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
    ret
init    ENDP
    

code    ENDS

    END init
