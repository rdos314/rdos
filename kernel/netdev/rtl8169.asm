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
; RTL8169.ASM
; RTL8169S/8110 series network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE ..\os\net.inc

RX_DESCR_COUNT = 32
TX_DESCR_COUNT = 32

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

RX_OWN = 8000h
RX_EOR = 4000h
RX_FS = 2000h
RX_LS = 1000h
RX_MAR = 800h
RX_PAM = 400h
RX_BAR = 200h
RX_RWT = 40h
RX_RES = 20h
RX_RUNT = 10h
RX_CRC = 8
RX_PID1 = 4
RX_PID0 = 2
RX_IPF = 1
RX_UDPF = 8000h
RX_TCPF = 4000h

rx_descr    STRUC

rx_fl_size  DW ?
rx_flags    DW ?
rx_resv     DD ?
rx_low_ads  DD ?
rx_high_ads DD ?

rx_descr    ENDS

TX_OWN = 8000h
TX_EOR = 4000h
TX_FS = 2000h
TX_LS = 1000h
TX_LGSEN = 800h
TX_IPCS = 4
TX_UDPS = 2
TX_TCPCS = 1

tx_descr    STRUC

tx_size     DW ?
tx_flags    DW ?
tx_resv     DD ?
tx_low_ads  DD ?
tx_high_ads DD ?

tx_descr    ENDS
 
data    STRUC

IoBase              DW ?
Handle              DW ?
Isr                 DW ?
RxRingSel           DW ?
RxRingPhys          DD ?
TxRingSel           DW ?
TxRingPhys          DD ?
TxThread            DW ?
RxCurrDescr         DW ?
RxCurrLinear        DD ?
TxCurrDescr         DW ?
TxLastDescr         DW ?
TxSection           section_typ <>
EthernetAddress     DB 6 DUP(?)

RxLinearArr         DD RX_DESCR_COUNT DUP(?)
TxLinearArr         DD TX_DESCR_COUNT DUP(?)

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
;           NAME:           CreateRxRing
;
;           DESCRIPTION:    Create RX ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRxRing    Proc near
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    GetPhysicalPage
    and ax,0F000h
    mov ds:RxRingPhys,eax
;
    mov ecx,0FFFh
    AllocateGdt
    CreateDataSelector16
    mov ds:RxRingSel,bx
;
    mov es,bx
    mov cx,RX_DESCR_COUNT
    mov si,OFFSET RxLinearArr
    xor di,di

crLoop:
    mov es:[di].rx_fl_size,1FF8h
    mov es:[di].rx_flags,RX_OWN
;
    push ecx
    mov eax,2000h    
    AllocateBigLinear
    mov ds:[si],edx
;    
    mov ecx,2
    AllocateMultiplePhysical
    pop ecx
    mov es:[di].rx_low_ads,eax
;
    mov al,67h
    SetPhysicalPage
    add edx,1000h
    add eax,1000h
    SetPhysicalPage
;
    add si,4
    add di,16
    sub cx,1
    jnz crLoop   
;
    sub di,16
    or es:[di].rx_flags,RX_EOR
    ret
CreateRxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateTxRing
;
;           DESCRIPTION:    Create TX ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateTxRing    Proc near
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    GetPhysicalPage
    and ax,0F000h
    mov ds:TxRingPhys,eax
;
    mov ecx,0FFFh
    AllocateGdt
    CreateDataSelector16
    mov ds:TxRingSel,bx
;
    mov es,bx
    mov cx,TX_DESCR_COUNT
    mov si,OFFSET TxLinearArr
    xor di,di

ctLoop:
    mov es:[di].tx_flags,TX_LS OR TX_FS
;
    push ecx
    mov eax,2000h    
    AllocateBigLinear
    mov ds:[si],edx
;    
    mov ecx,2
    AllocateMultiplePhysical
    pop ecx
    mov es:[di].tx_low_ads,eax
;
    mov al,67h
    SetPhysicalPage
    add edx,1000h
    add eax,1000h
    SetPhysicalPage
;
    add si,4
    add di,16
    sub cx,1
    jnz ctLoop   
;
    sub di,16
    or es:[di].tx_flags,TX_EOR
;
    mov ds:TxCurrDescr,0
    mov ds:TxLastDescr,di
    ret
CreateTxRing   Endp

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
    add dx,REG_CCR
    in ax,dx
    and ax,NOT 200h
    or al,8
    out dx,ax 
;
    call CreateRxRing
    mov dx,ds:IoBase
    add dx,REG_RDSAR + 4
    xor eax,eax
    out dx,eax
;
    sub dx,4
    mov eax,ds:RxRingPhys
    out dx,eax
;
    call CreateTxRing    
    mov dx,ds:IoBase
    add dx,REG_TNPDS + 4
    xor eax,eax
    out dx,eax
;
    sub dx,4
    mov eax,ds:TxRingPhys
    out dx,eax
;    
    mov dx,ds:IoBase
    add dx,REG_IMR
    mov ax,IR_SER OR IR_TOK OR IR_ROK OR IR_LinkChg
    out dx,ax    
;
    mov dx,ds:IoBase
    add dx,REG_RMS
    mov ax,2000h
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
    mov dx,ds:IoBase
    add dx,REG_CR
    in al,dx
    or al,0Ch
    out dx,al
;    
    mov dx,ds:IoBase
    add dx,REG_TCR
    in eax,dx
    and ax,NOT 700h
    or ax,400h
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,REG_RCR
    in eax,dx
    or eax,10000h
    and ax,1FFFh    
    or ax,8000h
    and ax,NOT 700h
    or ax,400h
    and al,0C0h
    or al,0Ah
    out dx,eax
    clc

ihDone:
    mov ds:Isr,0
    ret
InitHardware    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NetInt
;
;           DESCRIPTION:    Network card interrupt
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetInt  Proc far
niLoop:
    mov dx,ds:IoBase
    add dx,REG_ISR
    in ax,dx
    or ds:Isr,ax
    out dx,ax
    test ax,IR_ROK OR IR_RDU
    jz niNotRx
;
    mov bx,ds:Handle
    or bx,bx
    jz niNotRx
;
    NetReceived
    jmp niLoop

niNotRx:
    test ax,IR_TOK OR IR_TER
    jz niNotTx
;
    mov bx,ds:TxThread
    or bx,bx
    jz niNotTx
;
    Signal
    jmp niLoop

niNotTx:
    retf32
NetInt  Endp

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
    push es
    push bx
    push si
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp preview_do
    
Preview2:
    push ds
    push es
    push bx
    push si
;
    mov ax,ether_data2_sel
    mov ds,ax

preview_do:
    mov es,ds:RxRingSel
    mov cx,RX_DESCR_COUNT
    xor bx,bx
    mov si,OFFSET RxLinearArr
    
preview_loop:
    test es:[bx].rx_flags,RX_OWN
    jz preview_found
;
    add si,4
    add bx,16
    loop preview_loop
    stc
    jmp preview_done        

preview_found:
    mov ax,flat_sel
    mov es,ax
    mov edx,ds:[si]
    mov ds:RxCurrDescr,bx
    mov ds:RxCurrLinear,edx
    mov dx,es:[edx+12]
    xchg dl,dh
    xor ecx,ecx
    clc
        
preview_done:
    pop si
    pop bx
    pop es
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Receive
;
;       DESCRIPTION:    Receive data
;
;       PARAMETERS:     ECX             size of data
;
;       RETURNS:        ES:EDI          data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive1:
    push ds
    push bx
    push edx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp receive_do

Receive2:
    push ds
    push bx
    push edx
;
    mov ax,ether_data2_sel
    mov ds,ax
    
receive_do:
    mov edx,ds:RxCurrLinear
    mov bx,ds:RxCurrDescr
    mov es,ds:RxRingSel
    mov cx,es:[bx].rx_fl_size
    and ecx,1FFFh
    AllocateGdt
    CreateAliasSelector16
    xor edi,edi
    mov es,bx
    NotifyEthernetPacket
    mov edi,14
    sub ecx,14
;
    pop edx
    pop bx
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
    push es
    push bx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp remove_do

Remove2:
    push ds
    push es
    push bx
;
    mov ax,ether_data2_sel
    mov ds,ax

remove_do:
    mov es,ds:RxRingSel
    mov bx,ds:RxCurrDescr
    mov es:[bx].rx_fl_size,1FF8h
    mov ax,es:[bx].rx_flags
    and ax,RX_EOR
    or ax,RX_OWN
    mov es:[bx].rx_flags,ax
;
    pop bx
    pop es
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

GetBuffer1:
    push ds
    push bx
    push edx
    push si
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp get_buffer

GetBuffer2:
    push ds
    push bx
    push edx
    push si
;
    mov ax,ether_data2_sel
    mov ds,ax

get_buffer:
    mov es,ds:TxRingSel
    EnterSection ds:TxSection
    mov si,ds:TxCurrDescr
    mov ax,si
    cmp ax,ds:TxLastDescr
    je get_buffer_first_descr
;
    add ax,16
    jmp get_buffer_save_curr

get_buffer_first_descr:
    xor ax,ax

get_buffer_save_curr:
    mov ds:TxCurrDescr,ax
    LeaveSection ds:TxSection
;
    mov bx,si
    shr si,2
    add si,OFFSET TxLinearArr
;
    mov ax,es:[bx].tx_size
    or ax,ax
    jz get_buffer_take
;
    xor ax,ax
    mov es,ax    
    stc
    jmp get_buffer_done

get_buffer_take:
    add cx,14
    mov es:[bx].tx_size,cx
    mov edx,ds:[si]
;    
    push bx
    AllocateGdt
    CreateAliasSelector16
    mov es,bx
    pop ax
    mov edi,14
    mov es:[edi-2],ax
    sub cx,14
    clc

get_buffer_done:
    pop si
    pop edx
    pop bx
    pop ds    
    retf32

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
    push ds
    push bx
    push dx
    push si
    push edi
;
    xor di,di
    mov ax,ds:[esi]
    stosw
    mov ax,[esi+2]
    stosw
    mov ax,[esi+4]
    stosw
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp send_do
    
Send2:
    push ds
    push bx
    push dx
    push si
    push edi
;
    xor di,di
    mov ax,ds:[esi]
    stosw
    mov ax,[esi+2]
    stosw
    mov ax,[esi+4]
    stosw
;
    mov ax,ether_data2_sel
    mov ds,ax

send_do:
    mov ax,word ptr ds:EthernetAddress
    stosw
    mov ax,word ptr ds:EthernetAddress+2
    stosw
    mov ax,word ptr ds:EthernetAddress+4
    stosw
;    
    mov ax,dx
    xchg al,ah
    xchg ax,es:[di]
    add di,2
    mov si,ax
;
    add ecx,14
    xor edi,edi
    NotifyEthernetPacket
    FreeMem
;    
    cmp ecx,60
    jae sPadOk
;
    mov ecx,60

sPadOk: 
    mov es,ds:TxRingSel
    or es:[si].tx_flags,TX_OWN
    mov es:[si].tx_size,cx
;
    xor ax,ax
    mov es,ax
;
    mov dx,ds:IoBase
    add dx,REG_TPPoll
    mov al,40h
    out dx,al    
;
    pop edi
    pop si
    pop dx
    pop bx
    pop ax
    verr ax
    jz send_load_ds
;
    xor ax,ax
    
send_load_ds:
    mov ds,ax
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
    mov dx,ds:IoBase
    add dx,REG_PHYStatus
    in al,dx
    test al,2
    clc
    jnz gls1Ok
;
    stc

gls1Ok:
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
    mov dx,ds:IoBase
    add dx,REG_PHYStatus
    in al,dx
    test al,2
    clc
    jnz gls2Ok
;
    stc

gls2Ok:
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
    DD OFFSET GetBuffer1,       SEG code
    DD OFFSET Send1,            SEG code
    DD OFFSET GetAddress1,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET GetLinkState1,    SEG code

DispTable2:
    DD OFFSET Preview2,         SEG code
    DD OFFSET Receive2,         SEG code
    DD OFFSET Remove2,          SEG code
    DD OFFSET GetBuffer2,       SEG code
    DD OFFSET Send2,            SEG code
    DD OFFSET GetAddress2,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET GetLinkState2,    SEG code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup PCI or MSI IRQ
;
;       PARAMETERS:         BH    Bus
;                           BL    Device
;                           CH    Function
;                           DS    Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts   Proc near
    push ax
    push bx
    push cx
    push edx
    push edi
;    
    mov al,5
    FindPciCapability
    jc siIrq

siMsi:
    mov cl,al
    add cl,2
    ReadPciWord
    or al,1
    WritePciWord
;
    push cx
    mov cx,1
    AllocateMsiInts
    pop cx
    jc siIrq
;    
    push ax
    push edx
;
    ReadPciWord
    and al,8Fh
    WritePciWord
;
    test ax,100h
    jnz siVector
;
    test ax,80h
    jnz si64

si32:
    add cl,2
    pop eax
    WritePciDword
;
    add cl,4    
    pop ax
    WritePciWord
    jmp siMsiHandler

si64:
    add cl,2
    pop eax
    WritePciDword
;
    add cl,4
    xor eax,eax
    WritePciDword
;    
    add cl,4    
    pop ax
    WritePciWord
    jmp siMsiHandler

siVector:
    add cl,2
    pop eax
    WritePciDword
;
    add cl,4
    xor eax,eax
    WritePciDword
;    
    add cl,4    
    pop ax
    WritePciWord

siMsiHandler:
    mov di,cs
    mov es,di
    mov edi,OFFSET NetInt
    RequestMsiHandler
    jmp siDone

siIrq:
    GetPciIrqNr
    mov al,20 ; temporary fix before ACPI
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetInt    
    RequestSharedIrqHandler

siDone:
    pop edi
    pop edx
    pop cx
    pop bx
    pop ax
    ret
SetupInts    Endp

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
    call SetupInts
    call InitHardware
;    
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET DispTable1
    mov edi,OFFSET DriverName1
    mov al,1
    mov dx,0
    mov ecx,1600
    RegisterNetDriver
    pop ds
    mov ds:Handle,bx
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
    call SetupInts
    call InitHardware
;    
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET DispTable2
    mov edi,OFFSET DriverName2
    mov al,1
    mov dx,0
    mov ecx,1600
    RegisterNetDriver
    pop ds
    mov ds:Handle,bx
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
    
init_net    Proc far
    push ds
    push es
    pusha
;
    xor ax,ax
    call InitPrimaryPciAdapter
;
    inc ax
    call InitSecondaryPciAdapter
;    
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
    InitSection ds:TxSection
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
    InitSection ds:TxSection
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_net
    HookInitPci
    clc
    ret
Init    Endp

code    ENDS

    END init
