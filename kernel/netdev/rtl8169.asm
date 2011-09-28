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
; RTL8169.ASM
; RTL8169S series network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE ..\os\net.inc

IR_SER = 8000h
IR_Timeout = 4000h
IR_SWInt = 100h
IR_TDU = 80h
IR_FOVW = 40h
IR_LinkChg = 20h
IR_RDU = 10h
IR_TER = 8
IR_TOK = 4
IR_RER = 2
IR_ROK = 1

REG_IDR0 = 0                ; Ethernet hardware address. 
REG_MAR0 = 8                ; Multicast
REG_DTCCR = 10h
REG_TNPDS = 20h
REG_THPDS = 28h
REG_CR    = 37h
REG_TPPoll = 38h
REG_IMR = 3Ch
REG_ISR = 3Eh
REG_TCR = 40h
REG_RCR = 44h
REG_TCTR = 48h
REG_MPC = 4Ch
REG_9346CR = 50h
REG_CONFIG0 = 51h
REG_CONFIG1 = 52h
REG_CONFIG2 = 53h
REG_CONFIG3 = 54h
REG_CONFIG4 = 55h
REG_CONFIG5 = 56h
REG_TimerInt = 58h
REG_PHYAR = 60h
REG_TBICSR0 = 64h
REG_TBI_ANAR = 68h
REG_TBI_LPAR = 6Ah
REG_PHYStatus = 6Ch

REG_RMS = 0DAh
REG_CCR = 0E0h
REG_RDSAR = 0E4h
REG_MTPS = 0ECh

 
data    STRUC

IoBase              DW ?
Handle              DW ?
EthernetAddress     DB 6 DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'


    assume cs:code

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateBufferRings
;
;           DESCRIPTION:    Create buffer rings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBufferRings    Proc near
    ret
CreateBufferRings   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitHardware
;
;           DESCRIPTION:    Initialize hardware
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitHardware    Proc near
    mov dx,ds:IoBase
    add dx,REG_CR
    in al,dx
    or al,10h
    out dx,al
;
    mov cx,10000

ihResetWait:
    in al,dx
    test al,10h
    jz ihResetDone
;
    pause
    loop ihResetWait
;
    stc
    jmp ihDone

ihResetDone:
    mov dx,ds:IoBase
    add dx,REG_IDR0
    in eax,dx
    mov dword ptr ds:EthernetAddress,eax
    add dx,4
    in ax,dx
    mov word ptr ds:EthernetAddress+4,ax
;
    mov dx,ds:IoBase
    add dx,REG_9346CR
    mov al,0C0h
    out dx,al
;    
    mov dx,ds:IoBase
    add dx,REG_IMR
    mov ax,IR_SER OR IR_TOK OR IR_ROK OR IR_LinkChg
    out dx,ax    
;
    mov dx,ds:IoBase
    add dx,REG_RMS
    mov ax,3FFFh
    out dx,ax
;
    mov dx,ds:IoBase
    add dx,REG_CCR
    in ax,dx
    and ax,NOT 218h
    out dx,ax 
;
    mov dx,ds:IoBase
    add dx,REG_MTPS
    mov al,3Bh
    out dx,al           
;
    mov dx,ds:IoBase
    add dx,REG_9346CR
    mov al,0
    out dx,al
;
    call CreateBufferRings
;    
    mov dx,ds:IoBase
    add dx,REG_CR
    in al,dx
    or al,0Ch
    out dx,al
    
    mov dx,ds:IoBase
    add dx,REG_TCR
    in eax,dx
    or eax,10000h
    and ax,NOT 700h
    or ax,400h
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,REG_RCR
    in eax,dx
    or eax,10000h
    and ax,NOT 0E000h    
    or ax,8000h
    and ax,NOT 700h
    or ax,400h
    and al,3Fh
    or al,0Ah
    out dx,eax
    clc

ihDone:
    ret
InitHardware    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Preview
;
;           DESCRIPTION:    Return size of block or no more data
;
;           RETURNS:        NC          Data available
;                           ECX         Size of data (0)
;                           DX          Packet type
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preview1:
    push ds
    push fs
    push ebx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp preview_loop
    
Preview2:
    push ds
    push fs
    push ebx
;
    mov ax,ether_data2_sel
    mov ds,ax

preview_loop:
    pop ebx
    pop fs
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Receive
;
;           DESCRIPTION:    Receive data
;
;       RETURNS:        ES:EDI          data buffer
;                           ECX             size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive1:
    push ds
    push fs
    push bx
    push edx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp receive_do

Receive2:
    push ds
    push fs
    push bx
    push edx
;
    mov ax,ether_data2_sel
    mov ds,ax
    
receive_do:
;
    pop edx
    pop bx
    pop fs
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Remove
;
;           DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Remove1:
    push ds
    push ebx
    push cx
    push dx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp remove_do

Remove2:
    push ds
    push ebx
    push cx
    push dx
;
    mov ax,ether_data2_sel
    mov ds,ax

remove_do:
;
    pop dx
    pop cx
    pop ebx
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBuffer
;
;           DESCRIPTION:    Get buffer
;
;       PARAMETERS:     ECX         size
;
;           RETURNS:        ES:EDI  data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBuffer       Proc far
    push eax
    mov eax,14
    add eax,ecx
    cmp eax,64
    jae gbSizeOk

    mov eax,64

gbSizeOk:       
    add eax,4
    AllocateGlobalMem
    mov edi,14
    pop eax
    retf32
GetBuffer       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Send
;
;           DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX         size
;                           DX          packet type
;                           DS:ESI  dest address
;                           ES:EDI  data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Send1:
Send2:
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetAddress
;
;           DESCRIPTION:    Get adapter address
;
;           RETURNS:        DS:ESI  address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAddress1  Proc far
    mov si,ether_data_sel
    mov ds,si
    mov esi,OFFSET EthernetAddress  
    retf32
GetAddress1     Endp

GetAddress2  Proc far
    mov si,ether_data2_sel
    mov ds,si
    mov esi,OFFSET EthernetAddress  
    retf32
GetAddress2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPktAddress
;
;           DESCRIPTION:    Get packet addresses
;
;           PARAMETERS:         ES          Data buffer selector
;
;           RETURNS:        ES:ESI  Source address
;                           ES:EDI  Dest address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPktAddress   Proc far
    mov esi,6
    xor edi,edi
    retf32
GetPktAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetLinkState
;
;           DESCRIPTION:    Get link state
;
;           RETURNS:        NC      Link up
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetLinkState1  Proc far
    push ds
    push ax
    push dx
;    
    mov ax,ether_data_sel
    mov ds,ax
    clc
;
    pop dx
    pop ax
    pop ds
    retf32
GetLinkState1     Endp

GetLinkState2  Proc far
    push ds
    push ax
    push dx
;    
    mov ax,ether_data2_sel
    mov ds,ax
    clc
;
    pop dx
    pop ax
    pop ds
    retf32
GetLinkState2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DispatchTable
;
;           DESCRIPTION:    Driver dispatch table
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DispTable1:
    DD OFFSET Preview1,         SEG code
    DD OFFSET Receive1,         SEG code
    DD OFFSET Remove1,          SEG code
    DD OFFSET GetBuffer,        SEG code
    DD OFFSET Send1,            SEG code
    DD OFFSET GetAddress1,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET GetLinkState1,    SEG code

DispTable2:
    DD OFFSET Preview2,         SEG code
    DD OFFSET Receive2,         SEG code
    DD OFFSET Remove2,          SEG code
    DD OFFSET GetBuffer,        SEG code
    DD OFFSET Send2,            SEG code
    DD OFFSET GetAddress2,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET GetLinkState2,    SEG code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     AX      Device number
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName1     DB 'RTL8169-1',0
DriverName2     DB 'RTL8169-2',0

PciVendorTab:
pci00   DW 10ECh, 8129h
pci01   DW 1186h, 4300h
pci02   DW 0,     0

InitPrimaryPciAdapter   Proc near
    mov bp,ax
    mov ax,ether_data_sel
    mov ds,ax
    mov si,OFFSET PciVendorTab
init_pci1_loop:
    mov ax,bp
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci1_done
;
    FindPciDevice
    jnc init_pci1_found
;
    add si,4
    jmp init_pci1_loop

init_pci1_found:
    mov bp,bx
    mov cx,PCI_card_ExCa_base
    ReadPciDword
    mov dx,ax
    and dx,0FFE0h
    mov ds:IoBase,dx
;
    xor ch,ch
    mov cl,PCI_interrupt_line
    ReadPciByte
    mov bx,cs
    mov es,bx
;    mov edi,OFFSET NetInt    
;    RequestSharedIrqHandler
;
    call InitHardware
    mov ax,bp   
    clc

init_pci1_done:
    ret
InitPrimaryPciAdapter   Endp

InitSecondaryPciAdapter Proc near
    mov bp,ax
    mov ax,ether_data2_sel
    mov ds,ax
    mov si,OFFSET PciVendorTab
init_pci2_loop:
    mov ax,bp
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci2_done
;
    FindPciDevice
    jnc init_pci2_found
;
    add si,4
    jmp init_pci2_loop

init_pci2_found:
    mov bp,bx
    mov cx,PCI_card_ExCa_base
    ReadPciDword
    mov dx,ax
    and dx,0FFE0h
    mov ds:IoBase,dx
;
    xor ch,ch
    mov cl,PCI_interrupt_line
    ReadPciByte
    mov bx,cs
    mov es,bx
;    mov edi,OFFSET NetInt    
;    RequestSharedIrqHandler
;
    call InitHardware
    mov ax,bp   
    clc

init_pci2_done:
    ret
InitSecondaryPciAdapter Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_net
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

detect_name     DB 'RTL8169',0

detect_thread   proc far
    int 3
    xor ax,ax
    call InitPrimaryPciAdapter
;
    inc ax
    call InitSecondaryPciAdapter
    ret
detect_thread   endp
    
init_net    Proc far
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET detect_name
    mov si,OFFSET detect_thread
    mov ax,4
    mov cx,100h
    CreateThread

init_net_done:
    popa
    pop es
    pop ds
    retf32
init_net    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov eax,SIZE data
    mov bx,ether_data_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov eax,SIZE data
    mov bx,ether_data2_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_net
    HookInitTasking
    clc
    ret
Init    Endp

code    ENDS

    END init
