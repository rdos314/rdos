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
; RTL8139 network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME rtl8139

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\pci.inc
INCLUDE ..\os\net.inc

; debug EQU 1

MAC0 = 0				; Ethernet hardware address. 
MAR0 = 8				; Multicast filter. 
TxStatus0 = 10h			; Transmit status (Four 32bit registers). 
TxAddr0 = 20h			; Tx descriptors (also four 32bit). 
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
Timer = 48h				; A general-purpose counter.
RxMissed = 4Ch			; 24 bits valid, write clears.
Cfg9346 = 50h
Config0 = 51h
Config1 = 52h
FlashReg = 54h
GPPinData = 58h
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
FIFOTMS = 70h			; FIFO Control and test.
CSCR = 74h				; Chip Status and Configuration Register.
PARA78 = 78h
PARA7C = 7ch

; The EEPROM commands include the alway-set leading bit.

EE_WRITE_CMD = 5
EE_READ_CMD = 6
EE_ERASE_CMD = 7

;  EEPROM_Ctrl bits.

EE_SHIFT_CLK	= 4	; EEPROM shift clock. 
EE_CS			= 8	; EEPROM chip select. 
EE_DATA_WRITE	= 2	; EEPROM chip data in.
EE_WRITE_0		= 0
EE_WRITE_1		= 2
EE_DATA_READ	= 1	; EEPROM chip data out.
EE_ENB			= 80h + EE_CS
EE_DIS			= 80h
 
data	STRUC

IoBase				DW ?
Handle				DW ?
EthernetAddress		DB 6 DUP(?)
Is8139				DB ?
EeAdrLen			DB ?

data	ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadEe
;
;		DESCRIPTION:    Read Ee location
;
;       PARAMETERS:     BX		Location
;
;		RETURNS:		AX		Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEe	Proc near
	push bx
	push cx
	push si
;
	mov cl,ds:EeAdrLen
	mov ax,EE_READ_CMD
	shl ax,cl
	or bx,ax
;
	mov dx,ds:IoBase
	add dx,Cfg9346
;
	mov al,EE_DIS
	out dx,al
	mov al,EE_ENB
	out dx,al
;
	xor ch,ch
	add cx,4
	mov si,1
	shl si,cl

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
ReadEe	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitChip
;
;		DESCRIPTION:    Init chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitChip	Proc near
	mov ds:EeAdrLen,8 
	xor bx,bx
	call ReadEe
	cmp ax,8129
	jnz icReadAdr
;
	mov ds:EeAdrLen,6

icReadAdr:
	mov bx,7
	mov si,OFFSET EthernetAddress

icReadLoop:
	call ReadEe
	xchg al,ah
	mov ds:[si],ax
	add si,2
	inc bx
	cmp bx,10
	jne icReadLoop
;
	ret
InitChip	Endp

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
	ret
NetInt	Endp

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
	stc
	ret
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
	ret
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
	ret
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
	ret
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
	ret
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
	ret
GetAddress	Endp

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
	DW OFFSET Preview,	 	ether_code_sel
	DW OFFSET Receive,		ether_code_sel
	DW OFFSET Remove,		ether_code_sel
	DW OFFSET GetBuffer,	ether_code_sel
	DW OFFSET Send,			ether_code_sel
	DW OFFSET GetAddress,	ether_code_sel

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
pci00	DW 10ECh, 8139h, 1
pci01	DW 10ECh, 8129h, 0
pci02	DW 1113h, 1211h, 1
pci03	DW 1186h, 1300h, 1
pci04	DW 018Ah, 0106h, 1
pci05	DW 021Bh, 8139h, 1
pci06	DW 13D1h, 0AB06h, 1
pci07	DW 02ACh, 1012h, 1 
pci08	DW 1432h, 9130h, 1
pci09	DW 1186h, 1340h, 1
pci10	DW 1186h, 1300h, 1
pci11 	DW 0,	  0,     0

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
	add si,6
	jmp init_pci_loop

init_pci_found:
	mov al,cs:[si+4]
	mov ds:Is8139,al
;
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
	mov di,OFFSET NetInt	
	RequestPrivateIrqHandler
;
	call InitChip
;
	push ds
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET DispTable
	mov di,OFFSET DriverName
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

detect_name	DB 'RTL8139',0

detect_thread	proc far
	int 3
	mov ax,ether_data_sel
	mov ds,ax
	call InitPciAdapter
	ret
detect_thread	endp
	
init_net	Proc far
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
