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
; RTL8139.ASM
; RTL8139 series network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\acpi\pci.inc
INCLUDE ..\os\core.inc
INCLUDE ..\os\net.inc

; debug EQU 1

MAC0 = 0                ; Ethernet hardware address. 
MAR0 = 8                ; Multicast filter. 
TxStatus0 = 10h         ; Transmit status (Four 32bit registers). 
TxAddr0 = 20h           ; Tx descriptors (also four 32bit). 
RxBuf = 30h
RxEarlyCnt = 34h
RxEarlyStatus = 36h
ChipCmd = 37h
RxBufPtr = 38h
RxBufAddr = 3Ah
IntrMask = 3Ch
IntrStatus = 3Eh
TxConfig = 40h
RxConfig = 44h
Timer = 48h                 ; A general-purpose counter.
RxMissed = 4Ch          ; 24 bits valid, write clears.
Cfg9346 = 50h
Config0 = 51h
Config1 = 52h
FlashReg = 54h
MediaReg = 58h
GPPinDir = 59h
MII_SMI = 5Ah
HltClk = 5Bh
MultiIntr = 5Ch
TxSummary = 60h
MII_BMCR = 62h
MII_BMSR = 64h
NWayAdvert = 66h
NWayLPAR = 68h
NWayExpansion = 6Ah
FIFOTMS = 70h           ; FIFO Control and test.
CSCR = 74h                  ; Chip Status and Configuration Register.
PARA78 = 78h
PARA7C = 7ch

CmdReset = 10h
CmdRxEnb = 8
CmdTxEnb = 4
RxBufEmpty = 1

PCIErr = 8000h
PCSTimeout = 4000h
RxFIFOOver = 40h
RxUnderrun = 20h
RxOverflow = 10h
TxErr = 8
TxOK = 4
RxErr = 2
RxOK = 1

TxHostOwns = 2000h
TxUnderrun = 4000h
TxStatOK = 8000h
TxOutOfWindow EQU 20000000h
TxAborted EQU 40000000h
TxCarrierLost EQU 80000000h

RxMulticast = 8000h
RxPhysical = 4000h
RxBroadcast = 2000h
RxBadSymbol = 20h
RxRunt = 10h
RxTooLong = 8
RxCRCErr = 4
RxBadAlign = 2
RxStatusOK = 1

AcceptErr = 20h
AcceptRunt = 10h
AcceptBroadcast = 8
AcceptMulticast = 4
AcceptMyPhys = 2
AcceptAllPhys = 1

RX_FIFO_THRESH = 4
RX_DMA_BURST = 3
TX_DMA_BURST = 3

TX_FIFO_THRESH = 256

; The EEPROM commands include the alway-set leading bit.

EE_WRITE_CMD = 5
EE_READ_CMD = 6
EE_ERASE_CMD = 7

;  EEPROM_Ctrl bits.

EE_SHIFT_CLK    = 4     ; EEPROM shift clock. 
EE_CS           = 8     ; EEPROM chip select. 
EE_DATA_WRITE   = 2     ; EEPROM chip data in.
EE_WRITE_0          = 0
EE_WRITE_1          = 2
EE_DATA_READ    = 1     ; EEPROM chip data out.
EE_ENB          = 80h + EE_CS
EE_DIS          = 80h

RX_BUF_LEN_IDX  = 3 ;   0 = 8k, 1 = 16k, 2 = 32k, 3 = 64k
TX_BUF_SIZE         = 2048
 
data    STRUC

IoBase              DW ?
Handle              DW ?
RxRingPhys              DD ?
RxRingLinear        DD ?
RxRingSize              DD ?
RxRingSel               DW ?
RxRingPtr       DW ?
TxSelArr        DW 4 DUP(?)
TxBufPtr        DW 0
MediaStatus     DB ?
TxThread        DW ?
TxSection       section_typ <>
EthernetAddress     DB 6 DUP(?)
EeAdrLen            DB ?

data    ENDS

code    SEGMENT byte public 'CODE'


    assume cs:code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadEe
;
;           DESCRIPTION:    Read Ee location
;
;       PARAMETERS:     BX          Location
;
;           RETURNS:        AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEe  Proc near
    push bx
    push cx
    push si
;
    mov si,bx
    mov dx,ds:IoBase
    add dx,Cfg9346
;
    mov al,EE_DIS
    out dx,al
    mov al,EE_ENB
    out dx,al
;
    mov bx,EE_READ_CMD
    movzx cx,ds:EeAdrLen
    shl bx,cl
    or bx,si
;
    add cx,4
    mov si,1
    shl si,cl
    inc cx

reSetupLoop:
    test bx,si
    jz reSetup0
;
    mov al,EE_DATA_WRITE + EE_ENB
    out dx,al
    jmp reSetupShift

reSetup0:
    mov al,EE_ENB
    out dx,al

reSetupShift:
    push ax
    in eax,dx
    pop ax
;
    or al,EE_SHIFT_CLK
    out dx,al
    in eax,dx
;
    shr si,1
    loop reSetupLoop
;
    mov al,EE_ENB
    out dx,al
    in eax,dx
;
    mov cx,16
    xor bx,bx

reReadLoop:
    shl bx,1
;
    mov al,EE_ENB + EE_SHIFT_CLK
    out dx,al
    in eax,dx
;
    in al,dx
    test al,EE_DATA_READ
    jz reReadNext
;
    or bx,1

reReadNext:
    mov al,EE_ENB
    out dx,al
    in eax,dx
;
    loop reReadLoop
;
    mov al,NOT EE_CS
    out dx,al
;
    mov ax,bx
;
    pop si
    pop cx
    pop bx
    ret
ReadEe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadEthernetAddress
;
;           DESCRIPTION:    Read the ethernet address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEthernetAddress     Proc near
    mov ds:EeAdrLen,8 
    xor bx,bx
    call ReadEe
    cmp ax,8129h
    jz reaReadAdr
;
    mov ds:EeAdrLen,6

reaReadAdr:
    mov bx,7
    mov si,OFFSET EthernetAddress

reaReadLoop:
    call ReadEe
    mov ds:[si],ax
    add si,2
    inc bx
    cmp bx,10
    jne reaReadLoop
;
    ret
ReadEthernetAddress     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateRing
;
;           DESCRIPTION:    Allocate buffer rings
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateRing    Proc near
    mov ds:RxRingPtr,0
    mov ecx,(2 SHL RX_BUF_LEN_IDX) + 1
    AllocateMultiplePhysical32
    jc arDone
;
    mov ds:RxRingPhys,eax
    mov eax,ecx
    dec eax
    shl eax,12
    add eax,eax
    AllocateBigLinear
    mov ds:RxRingLinear,edx
    shr eax,1
    mov ds:RxRingSize,eax
;
    mov eax,ds:RxRingPhys
    or al,13h
    mov ecx,2 SHL RX_BUF_LEN_IDX

al_rxring_loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop al_rxring_loop
;
    mov ecx,2 SHL RX_BUF_LEN_IDX
    mov eax,ds:RxRingPhys
    or al,13h

al_arxring_loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop al_arxring_loop
;
    mov ecx,ds:RxRingSize
    add ecx,ecx
    mov edx,ds:RxRingLinear
    AllocateGdt
    CreateDataSelector16
    mov ds:RxRingSel,bx

arDone:
    ret
AllocateRing    Endp

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
    add dx,ChipCmd
    mov al,CmdReset
    out dx,al
;
    mov cx,10000

ihResetWait:
    in al,dx
    test al,CmdReset
    jz ihResetDone
    loop ihResetWait
;
    stc
    jmp ihDone

ihResetDone:
    mov dx,ds:IoBase
    add dx,Cfg9346
    mov al,0C0h
    out dx,al
;
    mov dx,ds:IoBase
    add dx,MAC0
    mov eax,dword ptr ds:EthernetAddress
    out dx,eax
    add dx,4
    mov ax,word ptr ds:EthernetAddress+4
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,ChipCmd
    mov al,CmdRxEnb OR CmdTxEnb
    out dx,al
;
    mov dx,ds:IoBase
    add dx,RxConfig
    mov eax,RX_FIFO_THRESH SHL 13
    or eax,RX_BUF_LEN_IDX SHL 11
    or eax,RX_DMA_BURST SHL 8
    mov ebx,eax
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,TxConfig
    mov eax,TX_DMA_BURST SHL 8
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,Cfg9346
    xor al,al
    out dx,al
;
    mov dx,ds:IoBase
    add dx,RxBuf
    mov eax,ds:RxRingPhys
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,RxMissed
    xor eax,eax
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,RxConfig
    mov eax,ebx
    or eax,AcceptBroadcast OR AcceptMyPhys
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,ChipCmd
    mov al,CmdRxEnb OR CmdTxEnb
    out dx,al
;
    mov dx,ds:IoBase
    add dx,MediaReg
    in al,dx
    mov ds:MediaStatus,al
;
    mov dx,ds:IoBase
    add dx,IntrMask
    mov ax,RxOk OR RxErr OR TxOK OR TxErr OR RxUnderrun
    out dx,ax 
    clc

ihDone:
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
    add dx,IntrStatus
    in ax,dx
    mov bx,ax
    test bx,RxUnderrun
    jz niNotUnderrun
;
    mov dx,ds:IoBase
    add dx,MediaReg
    in al,dx
    mov ds:MediaStatus,al

niNotUnderrun:
    mov dx,ds:IoBase
    add dx,IntrStatus
    mov ax,bx
    out dx,ax
    test bx,RxOK OR RxErr OR RxUnderrun OR RxOverflow OR RxFIFOOver
    jz niNotRx
;
    NotifyIrqActivity
    mov bx,ds:Handle
    or bx,bx
    jz niNotRx
;
    NetReceived
    jmp niLoop

niNotRx:
    test bx,TxOK OR TxErr
    jz niNotTx
;
    NotifyIrqActivity
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
    mov dx,ds:IoBase
    add dx,ChipCmd
    in al,dx
    test al,1
    stc
    jnz preview_done
;    
    mov fs,ds:RxRingSel
    xor ebx,ebx
    mov bx,ds:RxRingPtr
    mov ax,fs:[ebx]
    test al,RxOK
    jnz preview_ok
;    
    mov cx,fs:[ebx+2]
    add bx,cx
    add bx,4
    dec bx
    and bx,0FFFCh
    add bx,4
    mov ds:RxRingPtr,bx
    mov ax,bx
    sub ax,16
    mov dx,ds:IoBase
    add dx,RxBufPtr
    out dx,ax
    jmp preview_loop

preview_ok:    
    mov dx,fs:[ebx+12+4]    
    xchg dl,dh
    xor ecx,ecx
    clc

preview_done:
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
    mov fs,ds:RxRingSel
    xor edx,edx
    mov dx,ds:RxRingPtr
    mov ax,fs:[edx]
    movzx ecx,word ptr fs:[edx+2]
    AllocateGdt
    add edx,4    
    add edx,ds:RxRingLinear
    CreateAliasSelector16
    xor edi,edi
    mov es,bx
    NotifyEthernetPacket
    mov edi,14
    sub ecx,14
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
    mov dx,ds:IoBase
    xor ebx,ebx
    mov bx,ds:RxRingPtr
    push ds
    mov ds,ds:RxRingSel
    mov cx,ds:[ebx+2]
    add bx,cx
    add bx,4
    dec bx
    and bx,0FFFCh
    add bx,4
    mov ax,bx
    sub ax,16
    add dx,RxBufPtr
    out dx,ax
    pop ds
    mov ds:RxRingPtr,bx
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
    clc
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
    push ds
    push eax
    push bx
    push ecx
    push dx
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
    push eax
    push bx
    push ecx
    push dx
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
    stosw
;
    add ecx,14
    cmp ecx,60
    jae sPadOk
;
    mov ecx,60

sPadOk: 
    xor edi,edi
    NotifyEthernetPacket
    mov bx,es
    push ecx
    GetSelectorBaseSize
    pop ecx
    GetPageEntry
    and ax,0F000h
    and ecx,0FFFh
    and dx,0FFFh
    or ax,dx
;
    EnterSection ds:TxSection
    or ecx,80000h
    push ecx
    push eax
;
    GetThread
    mov ds:TxThread,ax
    ClearSignal 

ssRetry:
    mov dx,ds:IoBase
    add dx,TxStatus0
    mov bx,ds:TxBufPtr
    add bx,bx
    add dx,bx
    add dx,bx
    add bx,OFFSET TxSelArr
;    
    in eax,dx
    test ax,2000h
    jnz ssFound
;
    WaitForSignal
    jmp ssRetry 

ssFound:
    mov ds:TxThread,0
    mov ax,ds:[bx]
    mov ds:[bx],es
    or ax,ax
    jz ssNoPrev
;
    mov es,ax
    FreeMem

ssNoPrev:    
    xor ax,ax
    mov es,ax
    pop eax
    sub dx,TxStatus0
    add dx,TxAddr0
    out dx,eax
;
    pop eax
    sub dx,TxAddr0
    add dx,TxStatus0
    out dx,eax
;    
    mov bx,ds:TxBufPtr
    inc bx
    and bx,3
    mov ds:TxBufPtr,bx
    LeaveSection ds:TxSection
;
    pop edi
    pop dx
    pop ecx
    pop bx
    pop eax
    pop ds
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
    mov al,ds:MediaStatus
    test al,4
    clc
    jz gls1Done
;
    stc

gls1Done:
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
    mov al,ds:MediaStatus
    test al,4
    clc
    jz gls2Done
;
    stc

gls2Done:
    pop dx
    pop ax
    pop ds
    retf32
GetLinkState2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMac
;
;       DESCRIPTION:    Get Mac address
;
;       RETURNS:        ES:EDI    Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMac1 Proc far
    mov di,ether_data_sel
    mov es,di
    mov edi,OFFSET EthernetAddress  
    retf32
GetMac1 Endp

GetMac2 Proc far
    mov di,ether_data2_sel
    mov es,di
    mov edi,OFFSET EthernetAddress  
    retf32
GetMac2 Endp

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
    DD OFFSET GetMac1,          SEG code

DispTable2:
    DD OFFSET Preview2,         SEG code
    DD OFFSET Receive2,         SEG code
    DD OFFSET Remove2,          SEG code
    DD OFFSET GetBuffer,        SEG code
    DD OFFSET Send2,            SEG code
    DD OFFSET GetAddress2,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET GetLinkState2,    SEG code
    DD OFFSET GetMac2,          SEG code

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

DriverName1     DB 'RTL8139-1',0
DriverName2     DB 'RTL8139-2',0

PciVendorTab:
pci00   DW 10ECh, 8139h
pci01   DW 10ECh, 8138h
pci02   DW 1186h, 1300h
pci03   DW 1113h, 1211h
pci04   DW 1186h, 1300h
pci05   DW 018Ah, 0106h
pci06   DW 021Bh, 8139h
pci07   DW 13D1h, 0AB06h
pci08   DW 02ACh, 1012h 
pci09   DW 1432h, 9130h
pci10   DW 1186h, 1340h
pci11   DW 0,     0

InitPrimaryPciAdapter   Proc near
    mov bp,ax
    mov ax,cs
    mov es,ax
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
    mov edi,OFFSET DriverName1
    PciPowerOn
;
    mov bp,bx
    mov cl,PCI_card_ExCa_base
    ReadPciDword
    mov dx,ax
    and dx,0FFE0h
    mov ds:IoBase,dx
;
    mov cl,PCI_interrupt_line
    ReadPciByte
    mov ah,14h
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetInt    
    RequestIrqHandler
;
    call ReadEthernetAddress
    call AllocateRing
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
;
    mov ax,bp   
    clc

init_pci1_done:
    ret
InitPrimaryPciAdapter   Endp

InitSecondaryPciAdapter Proc near
    mov bp,ax
    mov ax,cs
    mov es,ax
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
    mov edi,OFFSET DriverName2
    PciPowerOn
;
    mov bp,bx
    mov cl,PCI_card_ExCa_base
    ReadPciDword
    mov dx,ax
    and dx,0FFE0h
    mov ds:IoBase,dx
;
    mov cl,PCI_interrupt_line
    ReadPciByte
    mov ah,14h
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetInt    
    RequestIrqHandler
;
    call ReadEthernetAddress
    call AllocateRing
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
;
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
;
    mov ds:EeAdrLen,8
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
;
    mov ds:EeAdrLen,8
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
