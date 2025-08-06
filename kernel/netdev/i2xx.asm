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
; i2xx.ASM
; Intel i2xx driver
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

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

RX_DESCR_COUNT = 256
TX_DESCR_COUNT = 128

rx_descr        STRUC

rx_phys         DD ?,?
rx_len          DW ?
rx_checksum     DW ?
rx_status       DB ?
rx_errors       DB ?
rx_tag          DW ?

rx_descr         ENDS

tx_descr        STRUC

tx_phys         DD ?,?
tx_len          DW ?
tx_cso          DB ?
tx_cmd          DB ?
tx_sta          DB ?
tx_resv         DB ?
tx_tag          DW ?

tx_descr         ENDS

CTRL_SC     = 1 SHL 26
RCTL_RXEN   = 1 SHL 1
RCTL_BAM    = 1 SHL 15
RXDCTL_EN   = 1 SHL 25
TCTL_TXEN   = 1 SHL 1
TXDCTL_EN   = 1 SHL 25
ICR_RXDW    = 1 SHL 7

REG_CTRL    = 0
REG_STATUS  = 8
REG_RCTL    = 100h
REG_TCTL    = 400h

REG_ICR     = 1500h
REG_ICS     = 1504h
REG_IMS     = 1508h
REG_IMC     = 150Ch
REG_GPIE    = 1514h

REG_RA      = 5400h

REG_RDBA    = 0C000h
REG_RDLEN   = 0C008h
REG_RDH     = 0C010h
REG_RDT     = 0C018h
REG_RXDCTL  = 0C028h

REG_TDBA    = 0E000h
REG_TDLEN   = 0E008h
REG_TDH     = 0E010h
REG_TDT     = 0E018h
REG_TXDCTL  = 0E028h
 
data    STRUC

FuncSel      DW ?

RxRingSel    DW ?
RxRingPhys   DD ?,?
RxTail       DD ?

TxRingSel    DW ?
TxRingPhys   DD ?,?
TxTail       DD ?
TxAlloc      DD ?
TxSection    section_typ <>

Handle       DW ?

PendInt      DD ?

Mac          DB 6 DUP(?)

RxLinearArr  DD RX_DESCR_COUNT DUP(?)
TxLinearArr  DD TX_DESCR_COUNT DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NetInt
;
;           DESCRIPTION:    Network card interrupt
;
;       PARAMETERS:         DS  Ether sel
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetInt  Proc far
    mov es,ds:FuncSel

niLoop:
    mov eax,es:REG_ICR
    or eax,eax
    jz niDone
;
    lock or ds:PendInt,eax
;
    test eax,ICR_RXDW
    jz niNotRx
;
    mov bx,ds:Handle
    or bx,bx
    jz niNotRx
;
    NetReceived
    jmp niLoop

niNotRx:
;    mov bx,ds:SuperThread
;    Signal

niDone:
    ret
NetInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateFuncSel
;
;       DESCRIPTION:    Create function selector
;
;       PARAMETERS:     EBX:EAX Physical address of BAR0 
;
;       RETURNS:        ES      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFuncSel   Proc near
    push eax
    push ebx
    push ecx
;
    push eax
    mov eax,10000h
    AllocateBigLinear
    pop eax
;
    push eax
    push edx
;
    and ax,0F000h
    or ax,813h
    mov ecx,10h

cfsLoop:
    SetPageEntry
;
    add edx,1000h
    add eax,1000h
    loop cfsLoop
;
    pop edx
    pop eax
;
    and ax,0FFFh
    or dx,ax
;
    AllocateGdt
    mov ecx,10000h
    CreateDataSelector32
    mov es,bx    
;    
    pop ecx
    pop ebx
    pop eax
    ret
CreateFuncSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateRxRing
;
;           DESCRIPTION:    Create RX ring
;
;           PARAMETERS:     DS  Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRxRing    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
    mov eax,RX_DESCR_COUNT SHL 4
    AllocateBigLinear
    AllocatePhysical64
    mov ds:RxRingPhys,eax
    mov ds:RxRingPhys+4,ebx
    or al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,RX_DESCR_COUNT SHL 4
    CreateDataSelector16
    mov ds:RxRingSel,bx
;
    mov es,bx
    mov ecx,RX_DESCR_COUNT
    mov esi,OFFSET RxLinearArr
    xor edi,edi

crLoop:
    mov es:[edi].rx_len,1000h
    mov es:[edi].rx_checksum,0
    mov es:[edi].rx_status,0
    mov es:[edi].rx_errors,0
    mov es:[edi].rx_tag,0
;
    push ecx
    mov eax,1000h    
    AllocateBigLinear
    mov ds:[esi],edx
    pop ecx
;
    AllocatePhysical64
    mov es:[edi].rx_phys,eax
    mov es:[edi].rx_phys+4,ebx
;
    mov al,13h
    SetPageEntry
;
    add esi,4
    add edi,16
    loop crLoop
;
    popad
    pop es
    ret
CreateRxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateTxRing
;
;           DESCRIPTION:    Create TX ring
;
;           PARAMETERS:     DS  Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateTxRing    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
    mov eax,TX_DESCR_COUNT SHL 4
    AllocateBigLinear
    AllocatePhysical64
    InitSection ds:TxSection
    mov ds:TxRingPhys,eax
    mov ds:TxRingPhys+4,ebx
    or al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,TX_DESCR_COUNT SHL 4
    CreateDataSelector16
    mov ds:TxRingSel,bx
    mov ds:TxTail,0
    mov ds:TxAlloc,0
;
    mov es,bx
    mov ecx,TX_DESCR_COUNT
    mov esi,OFFSET TxLinearArr
    xor edi,edi

ctLoop:
    mov es:[edi].tx_len,0
    mov es:[edi].tx_cso,0
    mov es:[edi].tx_cmd,0Bh
    mov es:[edi].tx_sta,1
    mov es:[edi].tx_resv,0
    mov es:[edi].tx_tag,0
;
    push ecx
    mov eax,1000h    
    AllocateBigLinear
    mov ds:[esi],edx
    pop ecx
;
    AllocatePhysical64
    mov es:[edi].tx_phys,eax
    mov es:[edi].tx_phys+4,ebx
;
    mov al,13h
    SetPageEntry
;
    add esi,4
    add edi,16
    loop ctLoop
;
    popad
    pop es
    ret
CreateTxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitRx
;
;           DESCRIPTION:    Init RX
;
;           PARAMETERS:     DS  Ether sel
;                           ES  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRx  Proc near
    call CreateRxRing
;
    mov eax,es:REG_RCTL
    and eax,NOT RCTL_RXEN
    or eax,RCTL_BAM
    mov es:REG_RCTL,eax
;
    mov eax,ds:RxRingPhys
    mov es:REG_RDBA,eax
    mov eax,ds:RxRingPhys+4
    mov es:REG_RDBA+4,eax
;
    mov dword ptr es:REG_RDLEN,RX_DESCR_COUNT SHL 4
;
    mov eax,es:REG_RXDCTL
    or eax,RXDCTL_EN
    mov es:REG_RXDCTL,eax
;
    mov ecx,100000h

irWaitEn:    
    pause
    mov eax,es:REG_RXDCTL
    test eax,RXDCTL_EN
    jnz irDoneEn
    loop irWaitEn

irDoneEn:
    mov eax,(RX_DESCR_COUNT - 1) SHL 4
    mov es:REG_RDT,eax
    mov ds:RxTail,0
;
    mov eax,es:REG_RCTL
    or eax,RCTL_RXEN OR RCTL_BAM
    mov es:REG_RCTL,eax
    ret
InitRx  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTx
;
;           DESCRIPTION:    Init TX
;
;           PARAMETERS:     DS  Ether sel
;                           ES  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTx  Proc near
    call CreateTxRing
;
    mov eax,es:REG_TCTL
    and eax,NOT TCTL_TXEN
    mov es:REG_TCTL,eax
;
    mov eax,ds:TxRingPhys
    mov es:REG_TDBA,eax
    mov eax,ds:TxRingPhys+4
    mov es:REG_TDBA+4,eax
;
    mov dword ptr es:REG_TDLEN,TX_DESCR_COUNT SHL 4
;
    mov eax,es:REG_TXDCTL
    or eax,TXDCTL_EN
    mov es:REG_TXDCTL,eax
;
    mov ecx,100000h

itWaitEn:    
    pause
    mov eax,es:REG_TXDCTL
    test eax,TXDCTL_EN
    jnz itDoneEn
    loop itWaitEn

itDoneEn:
    mov eax,es:REG_TCTL
    or eax,TCTL_TXEN
    mov es:REG_TCTL,eax
    ret
InitTx  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitFunc
;
;           DESCRIPTION:    Init function
;
;           PARAMETERS:     DS  Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitFunc    Proc near
    push es
    pushad
;
    mov ds:PendInt,0
;
    mov es,ds:FuncSel
    mov eax,es:REG_CTRL
    or eax,CTRL_SC
    mov es:REG_CTRL,eax
;
    mov ecx,100000h

ifWaitReset:    
    pause
    mov eax,es:REG_CTRL
    test eax,CTRL_SC
    jz ifDoneReset
    loop ifWaitReset

ifDoneReset:
    call InitRx
    call InitTx
;
    mov eax,es:REG_RA
    mov dword ptr ds:Mac,eax
    mov ax,es:REG_RA+4
    mov word ptr ds:Mac+4,ax
;
    mov eax,014004D5h
    mov es:REG_IMS,eax
;
    popad
    pop es
    ret
InitFunc        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemPreview
;
;           DESCRIPTION:    Return size of block or no more data
;
;           RETURNS:        NC          Data available
;                           ECX         Size of data (0)
;                           DX          Packet type
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preview  Proc near
    push es
    push ebx
;
    mov es,ds:RxRingSel
    mov ebx,ds:RxTail
    shl ebx,4
    mov al,es:[ebx].rx_status
    test al,1
    stc
    jz pDone
;
    mov ecx,flat_sel
    mov es,ecx
    mov ebx,ds:RxTail
    mov ebx,ds:[4*ebx].RxLinearArr
    mov dx,es:[ebx+12]
    xchg dl,dh
    xor ecx,ecx
    clc
    
pDone:
    pop ebx
    pop es
    ret
Preview  Endp

Preview1  Proc far
    push ds
    mov ecx,ether_data_sel
    mov ds,ecx
    call Preview
    pop ds
    ret
Preview1  Endp

Preview2  Proc far
    push ds
    mov ecx,ether_data2_sel
    mov ds,ecx
    call Preview
    pop ds
    ret
Preview2  Endp

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

Receive  Proc near
    push ebx
    push edx
;
    mov es,ds:RxRingSel
    mov ebx,ds:RxTail
    mov edx,ds:[4*ebx].RxLinearArr
    shl ebx,4
    movzx ecx,es:[ebx].rx_len
;
    AllocateGdt
    CreateAliasSelector16
    xor edi,edi
    mov es,bx
    NotifyEthernetPacket
    mov edi,14
    sub ecx,14
;
    pop edx
    pop ebx
    ret
Receive   Endp

Receive1  Proc far
    push ds
    push eax
;
    mov eax,ether_data_sel
    mov ds,eax
    call Receive
;
    pop eax
    pop ds
    ret
Receive1  Endp

Receive2  Proc far
    push ds
    push eax
;
    mov eax,ether_data2_sel
    mov ds,eax
    call Receive
;
    pop eax
    pop ds
    ret
Receive2  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Remove
;
;           DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Remove  Proc near
    push es
    push ebx
    push edx
;
    mov es,ds:RxRingSel
    mov ebx,ds:RxTail
    shl ebx,4
    mov es:[ebx].rx_status,0
    mov es:[ebx].rx_errors,0
;
    mov es,ds:FuncSel
    mov ebx,ds:RxTail
    mov es:REG_RDT,ebx
;
    inc ebx
    cmp ebx,RX_DESCR_COUNT
    jne rUpd
;
    xor ebx,ebx

rUpd:
    mov ds:RxTail,ebx
;
    pop edx
    pop ebx
    pop es
    ret
Remove   Endp

Remove1  Proc far
    push ds
    push eax
;
    mov eax,ether_data_sel
    mov ds,eax
    call Remove
;
    pop eax
    pop ds
    ret
Remove1  Endp

Remove2  Proc far
    push ds
    push eax
;
    mov eax,ether_data2_sel
    mov ds,eax
    call Remove
;
    pop eax
    pop ds
    ret
Remove2  Endp

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

GetBuffer Proc near
    push ebx
    push edx
    push esi
    push ebp
;
    mov es,ds:TxRingSel
    EnterSection ds:TxSection
;
    mov ebx,ds:TxAlloc
    mov edx,ebx
    mov esi,ebx
    shl ebx,4
    xor ebp,ebp

gbRetry:
    mov al,es:[ebx].tx_sta
    test al,1
    jnz gbOk
;
    mov ax,5
    WaitMilliSec    
;
    inc ebp
    cmp ebp,1000
    jb gbRetry
;
    int 3
    jmp gbRetry

gbOk:
    inc edx
    cmp edx,TX_DESCR_COUNT
    jne gbUpd
;
    xor edx,edx

gbUpd:
    mov ds:TxAlloc,edx
    LeaveSection ds:TxSection
;
    add ecx,14
    mov edx,ds:[4*esi].TxLinearArr
    AllocateGdt
    CreateAliasSelector16
    mov es,bx
    mov edi,14
    mov es:[edi-2],si
    sub ecx,14
;
    pop ebp
    pop esi
    pop edx
    pop ebx
    ret
GetBuffer Endp

GetBuffer1  Proc far
    push ds
    push eax
;
    mov eax,ether_data_sel
    mov ds,eax
    call GetBuffer
;
    pop eax
    pop ds
    ret
GetBuffer1  Endp

GetBuffer2  Proc far
    push ds
    push eax
;
    mov eax,ether_data2_sel
    mov ds,eax
    call GetBuffer
;
    pop eax
    pop ds
    ret
GetBuffer2  Endp

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

Send  Proc near
    mov ax,word ptr ds:Mac
    stos word ptr es:[edi]
    mov ax,word ptr ds:Mac+2
    stos word ptr es:[edi]
    mov ax,word ptr ds:Mac+4
    stos word ptr es:[edi]
;    
    mov ax,dx
    xchg al,ah
    xchg ax,es:[di]
    add di,2
    movzx esi,ax
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
    mov es,ds:FuncSel
    mov fs,ds:TxRingSel
    shl esi,4
    mov fs:[esi].tx_len,cx
    mov fs:[esi].tx_cso,0
    mov fs:[esi].tx_cmd,0Bh
    mov fs:[esi].tx_sta,0
    mov fs:[esi].tx_resv,0
    mov fs:[esi].tx_tag,0
;
    mov esi,ds:TxTail

sMore:
    mov edi,esi
    shl edi,4
    mov al,fs:[edi].tx_sta
    or al,al
    jnz sSetTail
;
    inc esi
    cmp esi,TX_DESCR_COUNT
    jne sUpd
;
    xor esi,esi

sUpd:
    cmp esi,ds:TxAlloc
    jne sMore

sSetTail:
    mov ds:TxTail,esi
    mov es:REG_TDT,esi
;
    xor eax,eax
    mov es,eax
;
    ret
Send  Endp

Send1  Proc far
    push ds
    push fs
    pushad
;
    xor edi,edi
    movsd
    movsw

    mov eax,ether_data_sel
    mov ds,eax
    call Send
;
    popad
    pop fs
    pop ds
    ret
Send1  Endp

Send2  Proc far
    push ds
    push fs
    pushad
;
    xor edi,edi
    movsd
    movsw
;
    mov eax,ether_data2_sel
    mov ds,eax
    call Send
;
    popad
    pop fs
    pop ds
    ret
Send2  Endp

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
    mov esi,ether_data_sel
    mov ds,esi
    mov esi,OFFSET Mac
    ret
GetAddress1     Endp

GetAddress2  Proc far
    mov esi,ether_data2_sel
    mov ds,esi
    mov esi,OFFSET Mac
    ret
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
    ret
GetPktAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemGetLinkState
;
;           DESCRIPTION:    Get link state
;
;           RETURNS:        NC      Link up
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemGetLinkState1  Proc far
    push ds
    push eax
;
    mov eax,ether_data_sel
    mov ds,eax
    mov ds,ds:FuncSel
    mov eax,ds:REG_STATUS
    test al,2
    clc
    jnz mgls1Ok
;
    stc

mgls1Ok:
    pop eax
    pop ds
    ret
MemGetLinkState1     Endp

MemGetLinkState2  Proc far
    push ds
    push eax
;
    mov eax,ether_data2_sel
    mov ds,eax
    mov ds,ds:FuncSel
    mov eax,ds:REG_STATUS
    test al,2
    clc
    jnz mgls2Ok
;
    stc

mgls2Ok:
    pop eax
    pop ds
    ret
MemGetLinkState2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMac
;
;       DESCRIPTION:    Get Mac address
;
;       RETURNS:        ES:EDI    Mac
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMac1  Proc far
    mov edi,ether_data_sel
    mov es,edi
    mov edi,OFFSET Mac
    ret
GetMac1 Endp    

GetMac2  Proc far
    mov edi,ether_data2_sel
    mov es,edi
    mov edi,OFFSET Mac
    ret
GetMac2 Endp    

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

MemDispTable1:
    DD OFFSET Preview1,         SEG code
    DD OFFSET Receive1,         SEG code
    DD OFFSET Remove1,          SEG code
    DD OFFSET GetBuffer1,       SEG code
    DD OFFSET Send1,            SEG code
    DD OFFSET GetAddress1,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET MemGetLinkState1, SEG code
    DD OFFSET GetMac1,          SEG code

MemDispTable2:
    DD OFFSET Preview2,         SEG code
    DD OFFSET Receive2,         SEG code
    DD OFFSET Remove2,          SEG code
    DD OFFSET GetBuffer2,       SEG code
    DD OFFSET Send2,            SEG code
    DD OFFSET GetAddress2,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET MemGetLinkState2, SEG code
    DD OFFSET GetMac2,          SEG code

PciVendorTab:
pci00   DW 8086h, 1533h,    0
pci01   DW 8086h, 1539h,    0
pci02   DW 8086h, 157Bh,    0
pci03   DW 8086h, 15F3h,    0
pci07   DW 0,     0

DevName1 DB 'i2xx-1', 0
DevName2 DB 'i2xx-2', 0

InitPciAdapter   Proc near
    mov ax,cs
    mov es,ax
    xor ax,ax
    mov bp,ax
    mov ax,ether_data_sel
    mov ds,ax
    mov si,OFFSET PciVendorTab
    mov edi,OFFSET DevName1
    xor bx,bx
    mov ebp,OFFSET MemDispTable1

ipLoop:
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz ipDone
;
    FindPciDevice
    jnc ipFound
;
    xor bx,bx
    add si,6
    jmp ipLoop

ipFound:
    LockPciHandle
    jc ipLoop
;
    xor al,al
    GetPciBarPhys
    jc ipLoop
;
    push eax
    push edx
    push edi
;
    mov edi,cs
    mov es,edi
    mov edi,OFFSET NetInt
    mov ah,14h
    SetupPciHandleIrq
;
    pop edi
    pop edx
    pop eax
    jc ipLoop
;
    push ebx
    mov ebx,edx
;
    call CreateFuncSel
    mov ds:FuncSel,es
;
    call InitFunc
;
    push ds
    push esi
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,ebp
    mov al,1
    mov dx,0
    mov ecx,1600
    RegisterNetDriver
;
    pop esi
    pop ds
    mov ds:Handle,bx
;
    pop ebx
;
    mov ax,ds
    cmp ax,ether_data_sel
    jne ipDone
;
    mov ax,ether_data2_sel
    mov ds,ax
    mov edi,OFFSET DevName2
    mov ebp,OFFSET MemDispTable2
    jmp ipLoop

ipDone:
    ret
InitPciAdapter   Endp

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
    call InitPciAdapter
;    
    popa
    pop es
    pop ds
    ret
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
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov eax,SIZE data
    mov bx,ether_data2_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
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
