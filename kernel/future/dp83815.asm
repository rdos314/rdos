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
; DP83815.ASM
; DP83815 network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE ..\os\net.inc

; debug EQU 1

CR = 0h
CFG = 04h
MEAR = 08h
PTSCR = 0Ch
ISR = 10h
IMR = 14h
IER = 18h
TXDP = 20h
TXCFG = 24h
RXDP = 30h
RXCFG = 34h
CCSR = 3Ch
WCSR = 40h
PCR = 44h
RFCR = 48h
RFDR = 4Ch

IMR_Val = 00000041h

descriptor_struc	STRUC

dh_link				DD ?
dh_stat				DD ?
dh_data				DD ?
dh_link_linear		DD ?
dh_data_sel			DW ?

descriptor_struc	ENDS
 
data	SEGMENT AT 0

IoBase				DW ?
OperationRegSel		DW ?
EthernetAddress		DB 6 DUP(?)
FreeList			DD ?
RxList				DD ?
TxList				DD ?
Handle				DW ?
ListSection			section_typ <>

net_seg_size		DB ?

data	ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateDescriptor
;
;		DESCRIPTION:	Allocate new descriptor
;						
;		RETURNS:		EDI		Descriptor linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateDescriptor	PROC near
	push eax
	push edx
;
	mov edi,ds:FreeList
	or edi,edi
	jnz allocate_descr_get
;
	push cx
	mov eax,1000h
	AllocateBigLinear
	mov ds:FreeList,edx
	pop cx

allocate_init_descr_loop:
	add edx,32
	mov es:[edx-32].dh_link_linear,edx
	test dx,0FFFh
	jnz allocate_init_descr_loop
;
	mov es:[edx-32].dh_link_linear,0
	mov edi,ds:FreeList

allocate_descr_get:
	mov eax,es:[edi].dh_link_linear
	mov ds:FreeList,eax
;
	pop edx
	pop eax
	ret
AllocateDescriptor	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeDescriptor
;
;		DESCRIPTION:	Free descriptor
;
;		PARAMETERS:		EDI		Descriptor linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDescriptor	PROC near
	push eax
	mov eax,ds:FreeList
	mov es:[edi].dh_link_linear,eax
	mov ds:FreeList,edi
	pop eax
	ret
FreeDescriptor	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateReceiveEntry
;
;		DESCRIPTION:	Create a new receive buffer entry
;
;		PARAMETERS:		EDI		Descriptor linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateReceiveEntry	Proc near
	push es
	push eax
	push bx
	push ecx
	push edx
;
	mov ax,flat_sel
	mov es,ax
	EnterSection ds:ListSection
	call AllocateDescriptor
	LeaveSection ds:ListSection
;
	mov eax,1000h
	AllocateBigLinear
	AllocateGdt
	mov ecx,eax
	CreateDataSelector16
	mov al,es:[edx]
	GetPhysicalPage
;
	and ax,0F000h
	mov es:[edi].dh_link,0
	mov es:[edi].dh_link_linear,0
	mov es:[edi].dh_stat,0FFFh
	mov es:[edi].dh_data,eax
	mov es:[edi].dh_data_sel,bx
;
	pop edx
	pop ecx
	pop bx
	pop eax
	pop es
	ret
CreateReceiveEntry	Endp	

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeReceiveEntry
;
;		DESCRIPTION:	Free a receive buffer entry
;
;		PARAMETERS:		EDI		Descriptor linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeReceiveEntry	Proc near
	push es
	push eax
;
	mov ax,flat_sel
	mov es,ax
	EnterSection ds:ListSection
	call FreeDescriptor
	LeaveSection ds:ListSection
;
	pop eax
	pop es
	ret
FreeReceiveEntry	Endp	

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertReceiveEntry
;
;		DESCRIPTION:	Insert receive entry
;
;		PARAMETERS:		EDI		Descriptor linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertReceiveEntry	Proc near
	push es
	push eax
	push ecx
	push edx
;
	mov ax,flat_sel
	mov es,ax
;
	EnterSection ds:ListSection
	mov eax,ds:RxList
	or eax,eax
	jz ireEmpty

ireGetTail:
	mov edx,eax
	mov eax,es:[eax].dh_link_linear
	or eax,eax
	jnz ireGetTail
;
	mov es:[edx].dh_link_linear,edi
	push edx
	mov edx,edi
	and dx,0F000h
	GetPhysicalPage
	and ax,0F000h
	mov dx,di
	and dx,0FFFh
	or ax,dx
	pop edx
	mov es:[edx].dh_link,eax
	jmp ireDone

ireEmpty:
	mov ds:RxList,edi
    mov eax,cr3
    mov cr3,eax
;
	mov edx,edi
	and dx,0F000h
	GetPhysicalPage
	and ax,0F000h
	mov dx,di
	and dx,0FFFh
	or ax,dx
	mov ecx,eax
;
	mov dx,ds:IoBase
	add dx,RXDP
	in eax,dx
	or eax,eax
	jnz ireDone
;
	mov eax,ecx
	out dx,eax

ireDone:
	LeaveSection ds:ListSection
	pop edx
	pop ecx
	pop eax
	pop es
	ret
InsertReceiveEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateSendEntry
;
;		DESCRIPTION:	Create a new send buffer entry
;
;		PARAMETERS:		EDI		Descriptor linear
;						ES		Send selector
;						ECX		Size of send data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSendEntry	Proc near
	push es
	push eax
	push bx
	push ecx
	push edx
;	
	mov bx,es
	mov ax,flat_sel
	mov es,ax
	EnterSection ds:ListSection
	call AllocateDescriptor
	LeaveSection ds:ListSection
;
	push ecx
	GetSelectorBaseSize
	pop ecx
	GetPhysicalPage
	and ax,0F000h
	and ecx,0FFFh
	or ecx,80000000h
	mov es:[edi].dh_link,0
	mov es:[edi].dh_link_linear,0
	mov es:[edi].dh_stat,ecx
	mov es:[edi].dh_data,eax
	mov es:[edi].dh_data_sel,bx
;
	pop edx
	pop ecx
	pop bx
	pop eax
	pop es
	ret
CreateSendEntry	Endp	

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertSendEntry
;
;		DESCRIPTION:	Insert send entry
;
;		PARAMETERS:		EDI		Descriptor linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertSendEntry	Proc near
	push es
	push eax
	push ecx
	push edx
;
	mov ax,flat_sel
	mov es,ax

iteSendLoop:
	EnterSection ds:ListSection
	mov eax,ds:TxList
	or eax,eax
	jz iteEmpty
;
	mov edx,es:[eax].dh_stat
	test edx,80000000h
	jnz iteGetTail
;
    push edi
	mov edi,ds:TxList
	mov eax,es:[edi].dh_link_linear
	mov ds:TxList,eax
	LeaveSection ds:ListSection
	call FreeSendEntry
	pop edi
    jmp iteSendLoop

iteGetTail:
	mov edx,eax
	mov eax,es:[eax].dh_link_linear
	or eax,eax
	jnz iteGetTail
;
	mov es:[edx].dh_link_linear,edi
	push edx
	mov edx,edi
	and dx,0F000h
	GetPhysicalPage
	and ax,0F000h
	mov dx,di
	and dx,0FFFh
	or ax,dx
	pop edx
	mov es:[edx].dh_link,eax
	jmp iteDone

iteEmpty:
	mov ds:TxList,edi
	mov edi,ds:TxList
	mov edx,edi
	and dx,0F000h
	GetPhysicalPage
	and ax,0F000h
	mov dx,di
	and dx,0FFFh
	or ax,dx
;
	mov dx,ds:IoBase
	add dx,TXDP
	out dx,eax
		
iteDone:	
    mov dx,ds:IoBase
	add dx,CR
	mov eax,1
	out dx,eax
;
	LeaveSection ds:ListSection
	pop edx
	pop ecx
	pop eax
	pop es
	ret
InsertSendEntry	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeSendEntry
;
;		DESCRIPTION:	Free a send buffer entry
;
;		PARAMETERS:		EDI		Descriptor linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeSendEntry	Proc near
	push es
	push eax
;
	mov ax,flat_sel
	mov es,ax
	push es
	mov es,es:[edi].dh_data_sel
	FreeMem
	pop es
	EnterSection ds:ListSection
	call FreeDescriptor
	LeaveSection ds:ListSection
;
	pop eax
	pop es
	ret
FreeSendEntry	Endp	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NetInt
;
;		DESCRIPTION:    Network card interrupt
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetInt	Proc far
niLoop:
	mov dx,ds:IoBase
	add dx,ISR
	in eax,dx
	or eax,eax
	jz niDone
;
	test al,1
	jz niNotReceive
;
	mov bx,ds:Handle
	or bx,bx
	jz niNotReceive
;
	NetReceived

niNotReceive:
	test al,40h
	jz niNotSend
;
	mov bx,ds:Handle
	NetReceived
	jmp niLoop

niNotSend:

niDone:
	retf32
NetInt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForNegotiate
;
;		DESCRIPTION:    Wait until auto-negotiate is done
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForNegotiate	Proc near
	push eax
	push cx
	push dx
;
	xor cx,cx

wfnLoop:
	mov dx,ds:IoBase
	add dx,CFG
	in eax,dx
	test eax,08000000h
	clc
	jnz wfnDone
;
	push cx
	xor cx,cx
wfnDelay:
	loop wfnDelay
	pop cx
;
	loop wfnLoop
;
	stc	

wfnDone:
	pop dx
	pop cx
	pop eax
	ret
WaitForNegotiate	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitAddress
;
;		DESCRIPTION:    Init ethernet address
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitAddress	Proc near
	push eax
	push ecx
	push dx
;
	mov dx,ds:IoBase
	add dx,RFCR
	in eax,dx
	and eax, NOT 3FFh
	mov ecx,eax
	out dx,eax
;
	add dx,4
	in eax,dx
	mov word ptr ds:EthernetAddress,ax
	sub dx,4
;
	add cx,2
	mov eax,ecx
	out dx,eax
;
	add dx,4
	in eax,dx
	mov word ptr ds:EthernetAddress+2,ax
	sub dx,4
;
	add cx,2
	mov eax,ecx
	out dx,eax
;
	add dx,4
	in eax,dx
	mov word ptr ds:EthernetAddress+4,ax
;
	pop dx
	pop ecx
	pop eax
	ret
InitAddress	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitRegisters
;
;		DESCRIPTION:    Init registers
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRegisters	Proc near
	push eax
	push ecx
	push dx
;
	mov dx,ds:IoBase
	add dx,CFG
	in eax,dx
	mov ecx,eax
;
	mov dx,ds:IoBase
	add dx,0CCh
	mov ax,1
	out dx,ax
;
	mov dx,ds:IoBase
	add dx,0E4h
	mov ax,189Ch
	out dx,ax
;
	mov dx,ds:IoBase
	add dx,0FCh
	mov ax,0h
	out dx,ax
;
	mov dx,ds:IoBase
	add dx,0F4h
	mov ax,5040h
	out dx,ax
;
	mov dx,ds:IoBase
	add dx,0F8h
	mov ax,008Ch
	out dx,ax
;
	mov dx,ds:IoBase
	add dx,0C0h
	in ax,dx
;
	mov dx,ds:IoBase
	add dx,0C4h
	mov ax,0002h
	out dx,ax
;
	mov dx,ds:IoBase
	add dx,ISR
	in eax,dx
;
	mov dx,ds:IoBase
	add dx,TXCFG
	mov eax,10D01002h				; MXDMA = 64, FLT = 512, DRTH = 64
	test ecx,20000000h
	jz init_tx_not_full
;
	or eax,0C0000000h

init_tx_not_full:
	out dx,eax
;
	mov dx,ds:IoBase
	add dx,RXCFG
	mov eax,48500020h				; MXDMA = 64, DRTH = 256
	test ecx,20000000h
	jz init_rx_not_full
;
	or eax,10000000h

init_rx_not_full:
	out dx,eax
;
	mov dx,ds:IoBase
	add dx,CCSR
	in eax,dx
	and ax,NOT 10h
	out dx,eax
;
	mov dx,ds:IoBase
	add dx,IMR
	mov eax,0
	out dx,eax
;
	mov dx,ds:IoBase
	add dx,IER
	mov eax,1
	out dx,eax
;
	pop dx
	pop ecx
	pop eax
	ret
InitRegisters	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitReceive
;
;		DESCRIPTION:    Init receive ring
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitReceive	Proc near
	push eax
	push cx
	push edx
;
	mov cx,64
irLoop:
	call CreateReceiveEntry
	call InsertReceiveEntry
	loop irLoop
;
	mov dx,ds:IoBase
	add dx,CR
	mov eax,4
	out dx,eax
;
	pop edx
	pop cx
	pop eax
	ret
InitReceive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Preview
;
;		DESCRIPTION:    Return size of block or no more data
;
;		RETURNS:		NC		Data available
;						ECX		Size of data (0)
;						DX		Packet type
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Preview	Proc far
	push ds
	push es
	push eax
	push edi
;
	mov ax,ether_data_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax

pvCheckTx:
	EnterSection ds:ListSection
	mov edi,ds:TxList
	or edi,edi
	jz pvCheckRx
;
	mov eax,es:[edi].dh_stat
	test eax,80000000h
	jnz pvCheckRx
;
	mov edi,ds:TxList
	mov eax,es:[edi].dh_link_linear
	mov ds:TxList,eax
	LeaveSection ds:ListSection
	call FreeSendEntry
	jmp pvCheckTx	

pvCheckRx:
	mov edi,ds:RxList
	or edi,edi
	jz pvDone
;
	mov eax,es:[edi].dh_stat
	test eax,80000000h
	stc
	jz pvDone
;	
	xor ecx,ecx
	mov es,es:[edi].dh_data_sel
	mov dx,es:[12]
	xchg dl,dh
	clc

pvDone:
	LeaveSection ds:ListSection
	pop edi
	pop eax
	pop es
	pop ds
	retf32
Preview	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Receive
;
;		DESCRIPTION:    Receive data
;
;       RETURNS: 	    ES:EDI		data buffer
;						ECX			size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive	Proc far
	push ds
	push eax
;
	mov ax,ether_data_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
;
	mov edi,ds:RxList
	mov eax,es:[edi].dh_stat
	mov ecx,eax
	and ecx,0FFFh
;	
	mov es,es:[edi].dh_data_sel
	xor edi,edi
	add ecx,14
    NotifyEthernetPacket
;	
	mov edi,14
	sub ecx,14
;
	pop eax
	pop ds
	retf32
Receive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Remove
;
;		DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Remove	Proc far
	push ds
	push es
	push eax
	push edi
;
	mov ax,ether_data_sel
	mov ds,ax
	mov ax,flat_sel
	mov es,ax
;
	mov edi,ds:RxList
	mov eax,es:[edi].dh_link_linear
	mov ds:RxList,eax
;
	call FreeReceiveEntry
	call CreateReceiveEntry
	call InsertReceiveEntry
;
	pop edi
	pop eax
	pop es
	pop ds
	retf32
Remove	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetBuffer
;
;		DESCRIPTION:    Get buffer
;
;       PARAMETERS:     ECX		size
;
;		RETURNS:		ES:EDI	data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBuffer	Proc far
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
GetBuffer	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Send
;
;		DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX		size
;						DX		packet type
;						DS:ESI	dest address
;						ES:EDI	data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Send	Proc far
	push eax
	push ecx
	push edi
	push bp
	mov bp,ds
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
;	cmp ecx,64
;	jae sSizeOk
;
;    mov ecx,64

sSizeOk:
    xor edi,edi
    NotifyEthernetPacket
;
	call CreateSendEntry
	mov ax,es
	cmp ax,bp
	jne send_keep_ds
;
    xor bp,bp

send_keep_ds:    	
	xor ax,ax
	mov es,ax
	call InsertSendEntry
;
    mov ds,bp
    pop bp
	pop edi
	pop ecx
	pop eax
	retf32
Send	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetAddress
;
;		DESCRIPTION:    Get adapter address
;
;		RETURNS:		DS:ESI	address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAddress	Proc far
	mov si,ether_data_sel
	mov ds,si
	mov esi,OFFSET EthernetAddress	
	retf32
GetAddress	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetPktAddress
;
;		DESCRIPTION:    Get packet addresses
;
; 		PARAMETERS:		ES		Data buffer selector
;
;		RETURNS:	 	ES:ESI	Source address
;						ES:EDI	Dest address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPktAddress	Proc far
	mov esi,6
	xor edi,edi
	retf32
GetPktAddress	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DispatchTable
;
;		DESCRIPTION:    Driver dispatch table
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DispTable:
	DD OFFSET Preview,	 		ether_code_sel
	DD OFFSET Receive,			ether_code_sel
	DD OFFSET Remove,			ether_code_sel
	DD OFFSET GetBuffer,		ether_code_sel
	DD OFFSET Send,				ether_code_sel
	DD OFFSET GetAddress,		ether_code_sel
	DD OFFSET GetPktAddress,	ether_code_sel

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitPciAdapter
;
;		DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;		RETURNS:		NC		Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName	DB 'DP83815',0

PciVendorTab:
pci00 DW 100Bh, 20h
pci0B DW 0,		0

InitPciAdapter	Proc near
	mov si,OFFSET PciVendorTab
init_pci_loop:
	xor ax,ax
	mov dx,cs:[si]
	mov cx,cs:[si+2]
	or dx,dx
	stc
	jz init_pci_done
;
	FindPciDevice
	jnc init_pci_found
;
	add si,4
	jmp init_pci_loop

init_pci_found:
	mov cx,PCI_card_ExCa_base
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov ds:IoBase,dx
;
	call WaitForNegotiate
	jc init_pci_done
;
	AllocatePhysical
	mov cx,PCI_card_cap_ptr
	WritePciDword
;
	push eax
	mov eax,1000h
	AllocateBigLinear
	pop eax
	or al,7
	SetPhysicalPage
;
	push bx
	AllocateGdt
	mov ecx,1000h
	CreateDataSelector16
	mov ds:OperationRegSel,bx
	pop bx
;
	xor ch,ch
	mov cl,PCI_interrupt_line
    ReadPciByte
	mov bx,cs
	mov es,bx
	mov di,OFFSET NetInt	
	RequestPrivateIrqHandler
;
	mov dx,ds:IoBase
	add dx,ISR
	in eax,dx
;
	call InitAddress
	call InitRegisters
	call InitReceive
;
	mov dx,ds:IoBase
	add dx,IMR
	mov eax,IMR_Val
	out dx,eax
;
	push ds
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov esi,OFFSET DispTable
	mov edi,OFFSET DriverName
	mov al,1
	mov dx,0
	mov ecx,1600
	RegisterNetDriver
	pop ds
	mov ds:Handle,bx
	clc

init_pci_done:
	ret
InitPciAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_net
;
;		DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dp83815_name	DB 'DP83815-TEST',0

dp83815_thread	proc far
	int 3
	mov ax,ether_data_sel
	mov ds,ax

	mov dx,ds:IoBase
	add dx,ISR
	in eax,dx
	ret
dp83815_thread	endp
	
init_net	Proc far
	push ds
	push es
	pusha
;
	mov ax,ether_data_sel
	mov ds,ax
	call InitPciAdapter
;
	jmp init_net_done

	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET dp83815_name
	mov si,OFFSET dp83815_thread
	mov ax,4
	mov cx,100h
	CreateThread

init_net_done:
	popa
	pop es
	pop ds
	ret
init_net	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init	Proc far
	push ds
	push es
	pusha
	mov bx,ether_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov eax,OFFSET net_seg_size
	mov bx,ether_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov es,bx
	mov cx,ax
	xor di,di
	xor al,al
	rep stosb
	InitSection ds:ListSection	
	mov ds:FreeList,0
	mov ds:RxList,0
	mov ds:TxList,0
	mov ds:Handle,0
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_net
	HookInitTasking

init_fail:
	popa
	pop es
	pop ds
	ret
Init	Endp

ENDS

	END init
