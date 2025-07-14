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
; NE2000.ASM
; NE2000 network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WORD_MODE		EQU 1
MEM_MODE 		EQU 2
DWORD_MODE		EQU 4
OVERFLOW_MODE	EQU 8
LOOPBACK_MODE	EQU 10h

BUFFER_START	EQU 40h

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc

outb	Macro port, val
	mov dx,ds:IoBase
	add dx,port
	mov al,val
	out dx,al
	jmp short $+2
		Endm

outw	Macro port, val
	mov dx,ds:IoBase
	add dx,port
	mov ax,val
	out dx,al
	inc dx
	mov al,ah
	out dx,al
		Endm

inb		Macro port
	mov dx,ds:IoBase
	add dx,port
	in al,dx
		Endm

inw		Macro port
	mov dx,ds:IoBase
	add dx,port
	in al,dx
	inc dx
	mov ah,al
	in al,dx
	xchg al,ah
		Endm

ConfigRegA				EQU 10
ConfigRegB				EQU 11

Control1				EQU -16
ATDetect				EQU -15
Control2				EQU -11
NodeAddr				EQU -8

CommandReg				EQU 0
PageStartReg			EQU 1
PageStopReg				EQU 2
BoundaryPtrReg			EQU 3
TransmitStatusReg		EQU 4
TransmitPageReg			EQU 4
TransmitCountReg		EQU 5
InterruptStatusReg		EQU 7
RemoteAddressReg		EQU 8
RemoteCountReg			EQU 10
ReceiveConfigReg		EQU 12
ReceiveStatusReg		EQU 12
TransmitConfigReg		EQU 13
DataConfigReg			EQU 14
InterruptMaskReg		EQU 15

PhysicalAddressReg		EQU 1
CurrentPageReg			EQU 7
MulticastReg			EQU 8

IoReg					EQU 10h
ResetReg				EQU 18h

CommandStart	EQU 22h
CommandStop		EQU 21h
CommandTransmit	EQU 24h
CommandRead		EQU 08h
CommandWrite	EQU 10h
CommandPage0	EQU 20h
CommandPage1	EQU 60h
CommandPage2	EQU 0A0h

DataConfigReset		EQU 50h
DataConfigNormal	EQU 48h

ReceiveConfigReset	EQU 20h
ReceiveConfigNormal	EQU 0Eh

TransmitConfigNormal	EQU 0
TransmitConfigLoopback	EQU 2

InterruptStatusReceiveOk		= 1
InterruptStatusTransmitOk		= 2
InterruptStatusReceiveError		= 4
InterruptStatusTransmitError	= 8
InterruptStatusOverwrite		= 10h
InterruptStatusCounterError		= 20h
InterruptStatusDmaComplete		= 40h
InterruptStatusReset			= 80h
InterruptStatusReceive			= InterruptStatusReceiveOk OR InterruptStatusReceiveError
InterruptStatusTransmit			= InterruptStatusTransmitOk OR InterruptStatusTransmitError
InterruptStatusActive			= InterruptStatusReceive OR InterruptStatusTransmit OR InterruptStatusOverwrite

InterruptMaskEnable		= InterruptStatusActive
InterruptMaskDisable	= 0

send_header	STRUC

sh_size		DW ?
sh_next		DB ?

send_header	ENDS
 
data	SEGMENT AT 0

IoBase				DW ?
Mode				DB ?
MemSize				DW ?
EthernetAddress		DB 6 DUP(?)
Handle				DW ?
SendSection			section_typ <>
OverflowData		DB ?
PageStop			DB ?
NextPacket			DB ?
SendStart			DB ?
SendStop			DB ?
SendCurrent			DB ?
SendPending			DB ?
SendHeader			DD 256 DUP(?)

SourceAddress	DB 6 DUP(?)

ISR				DB ?
IMR				DB ?

LastConfirm		DD ?,?

net_seg_size	DB ?

data	ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ConfirmTransmit
;
;		DESCRIPTION:    Confirm transmit
;
;		RETURN:			DS	ether_data_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfirmTransmit	proc near
	inb TransmitStatusReg
	movzx bx,ds:SendCurrent
	shl bx,2
	mov al,ds:[bx].SendHeader.sh_next
	mov ds:SendCurrent,al
	GetSystemTime
	mov ds:LastConfirm,eax
	mov ds:LastConfirm+4,edx
	ret
ConfirmTransmit	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			StartTransmit
;
;		DESCRIPTION:    Start transmitting data
;
;		RETURN:			DS	ether_data_sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartTransmit	proc near
	cli
	movzx bx,ds:SendCurrent
	cmp bl,ds:SendPending
	je start_transmit_done
;
	test ds:Mode, OVERFLOW_MODE
	jnz start_transmit_done
;
	shl bx,2
	mov cx,ds:[bx].SendHeader.sh_size
	cmp cx,60
	jnc start_transmit_config
	mov cx,60
start_transmit_config:
	mov bl,ds:SendCurrent
	outb CommandReg, CommandPage0
	outw TransmitCountReg,cx
	outb TransmitPageReg,bl
	outb CommandReg, CommandTransmit OR CommandStart

start_transmit_done:
	sti
	ret
StartTransmit	endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OverflowTimeout
;
;		DESCRIPTION:    1.6ms overflow passed
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OverflowTimeout	Proc far
	mov ax,ether_data_sel
	mov ds,ax
;
	outw RemoteCountReg,0
	inb InterruptStatusReg
	test ds:OverflowData, CommandTransmit
	jz overflow_transmit_ok
;
	test al,InterruptStatusTransmit
	jnz overflow_transmit_ok
;
	call ConfirmTransmit

overflow_transmit_ok:
	or ds:Mode, LOOPBACK_MODE
	outb TransmitConfigReg,TransmitConfigLoopback
	outb CommandReg,CommandStart OR CommandPage0
	mov bx, ds:Handle
	NetReceived
	ret
OverflowTimeout	Endp

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
	cli
	mov ax,ether_data_sel
	mov es,ax
;
	outb CommandReg, CommandPage0
;
	inb InterruptStatusReg
NetIntLoop:
	mov ds:ISR,al
;
	sti
	test ds:ISR, InterruptStatusOverwrite
	jz NetIntNotOverflow
;
	test ds:Mode, OVERFLOW_MODE
	jnz NetIntNext
;
	or ds:Mode, OVERFLOW_MODE
	inb CommandReg
	mov ds:OverflowData,al
	outb CommandReg, CommandStop
;
	cli
	mov ah,ds:IMR
	and ah, NOT InterruptStatusOverwrite
	mov ds:IMR,ah
	outb InterruptMaskReg,ah
	sti
;
	GetSystemTime
	add eax,1800
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET OverflowTimeout
	mov bx,cs
	StopTimer
	StartTimer
	jmp NetIntNext

NetIntNotOverflow:
	test ds:ISR, InterruptStatusTransmitOk
	jz NetIntNotTransmitOk
;
	call ConfirmTransmit
	outb InterruptStatusReg, InterruptStatusTransmitOk
	call StartTransmit

NetIntNotTransmitOk:
	test ds:ISR, InterruptStatusTransmitError
	jz NetIntNotTransmitError
;
	inb TransmitStatusReg
	push ax
	outb InterruptStatusReg, InterruptStatusTransmitError
	pop ax
	test al,28h
	jz NetIntNotTransmitError
;
	call ConfirmTransmit
	call StartTransmit

NetIntNotTransmitError:
	test ds:ISR, InterruptStatusReceive
	jz NetIntNext
;
	cli
	mov ah,ds:IMR
	and ah, NOT InterruptStatusReceive
	mov ds:IMR,ah
	outb InterruptMaskReg,ah
	sti
;
	mov bx, ds:Handle
	NetReceived

NetIntNext:
	cli
	inb InterruptStatusReg
	and al,ds:IMR
	jnz NetIntLoop

	retf32
NetInt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Reset
;
;		DESCRIPTION:    Reset adapter
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Reset	Proc near
	or ds:Mode,OVERFLOW_MODE
	and ds:Mode,NOT LOOPBACK_MODE
	outb CommandReg, CommandStop
	mov ds:IMR,0
	outb InterruptStatusReg,-1
	mov dx,ds:IoBase
	add dx,ResetReg
	in al,dx
	out dx,al
;
	xor cx,cx
	outb CommandReg, CommandStop
	outb InterruptMaskReg, InterruptMaskDisable
	outw RemoteCountReg, 0
WaitResetLoop:
	inb InterruptStatusReg  
	test al,80h
	clc
	jnz WaitResetDone
	loop WaitResetLoop
	stc
WaitResetDone:
	ret
Reset	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitCore
;
;		DESCRIPTION:    Initiate NIC core registers
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitCore	Proc near
	outb CommandReg, CommandPage0
	mov al,ds:Mode
	and al,1
	or al,50h
	outb DataConfigReg,al	
	outb RemoteCountReg,0
	outb RemoteCountReg+1,0
	outb ReceiveConfigReg, ReceiveConfigReset
	or ds:Mode, LOOPBACK_MODE
	outb TransmitConfigReg, TransmitConfigLoopback
	outb PageStartReg,BUFFER_START
	outb BoundaryPtrReg,BUFFER_START
	mov ds:NextPacket,BUFFER_START
	mov ax,ds:MemSize
	mov al,ah
	add al,BUFFER_START
	dec al
	mov ds:SendStop,al
	shr ah,1
	add ah,BUFFER_START
	mov ds:SendStart,ah
	mov ds:SendCurrent,ah
	mov ds:SendPending,ah
	dec ah
	mov ds:PageStop,ah
;
	outb PageStopReg,ah
	outb InterruptMaskReg,InterruptMaskDisable
	outb InterruptStatusReg,0FFh
;
	outb CommandReg, CommandPage1
	mov cx,6
	mov dx,PhysicalAddressReg
	add dx,ds:IoBase
	mov si,OFFSET EthernetAddress
set_node_loop:
	mov al,[si]
	out dx,al
	inc dx
	inc si
	loop set_node_loop
;
	mov cx,8
	mov dx,MulticastReg
	add dx,ds:IoBase
	mov al,-1
set_multicast_loop:
	out dx,al
	inc dx
	loop set_multicast_loop
;
	outb CurrentPageReg,BUFFER_START
;
	outb CommandReg,CommandPage0
	mov al,ds:Mode
	and al,1
	or al,DataConfigNormal
	outb DataConfigReg,al	
	outb TransmitConfigReg,0
	outb ReceiveConfigReg,ReceiveConfigReset
	outb InterruptStatusReg,-1
;
	ret
InitCore	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckSignature
;
;		DESCRIPTION:    Check adapter signature
;
;       PARAMETERS:     
;
;		RETURNS:		NC		Ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckSignature	Proc near
	outb InterruptMaskReg, InterruptMaskDisable
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, 1Ch
	outw RemoteCountReg, 1
	outb CommandReg, CommandRead
	inb IoReg
	cmp al,57h
	clc
	je check_signature_done
	cmp al,42h
	clc
	je check_signature_done
	stc

check_signature_done:
	ret
CheckSignature	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetIoWidth
;
;		DESCRIPTION:    Get IO access width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIoWidth	Proc near
	mov di,BUFFER_START SHL 8
	mov ds:Mode,0
;
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, di
	outw RemoteCountReg, 4
	outb CommandReg, CommandWrite
	mov dx,ds:IoBase
	add dx,IoReg
	mov ax,1A59h
	out dx,ax
	mov ax,5A73h
	out dx,ax
;
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, di
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
	mov dx,ds:IoBase
	add dx,IoReg
	in ax,dx
	ror eax,16
	in ax,dx
;
	cmp eax,1A595A73h
	jne get_io_width_done
;
	mov ds:Mode,WORD_MODE
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, di
	outw RemoteCountReg, 4
	outb CommandReg, CommandWrite
	mov dx,ds:IoBase
	add dx,IoReg
	mov eax,45AF6592h
	out dx,eax
;
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, di
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
	mov dx,ds:IoBase
	add dx,IoReg
	in eax,dx
;
	cmp eax,45AF6592h
	jne get_io_width_done
;
	mov ds:Mode,WORD_MODE OR DWORD_MODE

get_io_width_done:
	ret
GetIoWidth	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetIoSize
;
;		DESCRIPTION:    Get IO mode adapter size
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIoSize	Proc near
	mov cx,100h - BUFFER_START
	mov di,BUFFER_START SHL 8
io_reset_loop:
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, di
	outw RemoteCountReg, 4
	outb CommandReg, CommandWrite
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	test ds:Mode,DWORD_MODE
	jnz io_reset_dword
;
	test ds:Mode,WORD_MODE
	jnz io_reset_word

io_reset_byte:
	mov al,0F3h
	out dx,al
	mov al,7Ch
	out dx,al
	mov al,46h
	out dx,al
	mov al,0A5h
	out dx,al
	jmp io_reset_next

io_reset_word:
	mov ax,7CF3h
	out dx,ax
	mov ax,0A546h
	out dx,al
	jmp io_reset_next

io_reset_dword:
	mov eax,0A5467CF3h
	out dx,eax

io_reset_next:
	add di,100h
	loop io_reset_loop
;
	mov cx,100h - BUFFER_START
	mov di,BUFFER_START SHL 8
io_check_loop:
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, di
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	test ds:Mode,DWORD_MODE
	jnz io_check_dword
;
	test ds:Mode,WORD_MODE
	jnz io_check_word

io_check_byte:
	in al,dx
	ror eax,8
	in al,dx
	ror eax,8
	in al,dx
	ror eax,8
	in al,dx
	ror eax,8
	jmp io_check_do

io_check_word:
	in ax,dx
	ror eax,16
	in ax,dx
	ror eax,16
	jmp io_check_do

io_check_dword:
	in eax,dx

io_check_do:
	cmp eax,0A5467CF3h
	jne io_check_end
;
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, di
	outw RemoteCountReg, 4
	outb CommandReg, CommandWrite
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	test ds:Mode,DWORD_MODE
	jnz io_mark_dword
;
	test ds:Mode,WORD_MODE
	jnz io_mark_word

io_mark_byte:
	xor al,al
	out dx,al
	out dx,al
	out dx,al
	out dx,al
	jmp io_check_next

io_mark_word:
	xor ax,ax
	out dx,ax
	out dx,ax
	jmp io_check_next

io_mark_dword:
	xor eax,eax
	out dx,eax

io_check_next:
	add di,100h
	sub cx,1
	jnz io_check_loop

io_check_end:
	sub di,BUFFER_START SHL 8
	mov ds:MemSize,di
	dec di
	mov bx,es
	mov ax,gdt_sel
	mov es,ax
	mov es:[bx],di
	mov es,bx
	ret
GetIoSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetIoNode
;
;		DESCRIPTION:    Get IO node address from adapter
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
GetIoNode	Proc near
	test ds:Mode,WORD_MODE
	jnz get_io_node16

get_io_node8:
	mov cx,6
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, 0
	outw RemoteCountReg, cx
	outb CommandReg, CommandRead
	mov dx,IoReg
	add dx,ds:IoBase
	mov si,OFFSET EthernetAddress
get_io_node8_loop:
	in al,dx
	mov [si],al
	inc si
	loop get_io_node8_loop
	jmp get_io_node_done

get_io_node16:
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, 0
	outw RemoteCountReg, 12
	outb CommandReg, CommandRead
	mov dx,IoReg
	add dx,ds:IoBase
	mov cx,6
	mov si,OFFSET EthernetAddress
get_io_node16_loop:
	in ax,dx
	mov [si],al
	inc si
	loop get_io_node16_loop

get_io_node_done:
	ret
GetIoNode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ConfigIoMode
;
;		DESCRIPTION:    Try to configure to IO mode
;
;		RETURNS:		CY,	failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigIoMode	Proc near
	call GetIoWidth
	call GetIoSize
	call GetIoNode
	clc
	ret
ConfigIoMode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetMemWidth
;
;		DESCRIPTION:    Get memory access width
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMemWidth	Proc near
	xor di,di
	mov ds:Mode,MEM_MODE
	mov ax,1A59h
	mov es:[di],ax
	mov word ptr es:[di+2],0AC3Ch
	cmp ax,es:[di]
	jne get_mem_width_done
;
	mov ds:Mode,MEM_MODE OR WORD_MODE

get_mem_width_done:
	ret
GetMemWidth	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetMemSize
;
;		DESCRIPTION:    Get mem mode RAM size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMemSize	Proc near
	mov ax,ether_mem_sel
	mov es,ax
	mov cx,100h
	mov eax,0A5467CF3h
	xor di,di
mem_reset_loop:
	mov es:[di],eax
	add di,100h
	loop mem_reset_loop
;
	mov cx,100h
	xor di,di
mem_check_loop:
	mov eax,es:[di]
	cmp eax,0A5467CF3h
	jne mem_check_end
	mov dword ptr es:[di],0
	add di,100h
	loop mem_check_loop

mem_check_end:
	mov ds:MemSize,di
	dec di
	mov bx,es
	mov ax,gdt_sel
	mov es,ax
	mov es:[bx],di
	mov es,bx
	ret
GetMemSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetMemNode
;
;		DESCRIPTION:    Get mem mode adapter address
;
;       PARAMETERS:   
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMemNode	Proc near
	mov dx,ds:IoBase
	add dx,NodeAddr
	mov cx,6
	mov bx,OFFSET EthernetAddress
mem_addr_loop:
	in al,dx
	mov [bx],al
	inc dx
	inc bx
	loop mem_addr_loop
	ret
GetMemNode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ConfigMemMode
;
;		DESCRIPTION:    Try to configure to memory mode
;
;		RETURNS:		CY,	failed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

memtab:
m0	DW 0C000h
m1	DW 0C400h
m2	DW 0C800h
m3	DW 0CC00h
m4	DW 0D000h
m5	DW 0D400h
m6	DW 0D800h
m7	DW 0DC00h

ConfigMemMode	Proc near
	inb ConfigRegA
	or al,80h
	outb ConfigRegA, al
	add ds:IoBase,10h
	inb ATDetect
	mov ds:Mode,al
;
	mov eax,10000h
	AllocateBigLinear
;
	mov ax,flat_sel
	mov es,ax
	mov bx,OFFSET memtab
	mov cx,8
config_mem_loop:
	movzx eax,word ptr cs:[bx]
	shl eax,4
	or al,7
	SetPhysicalPage
	mov eax,cr3
	mov cr3,eax
	mov al,es:[edx]
	cmp al,-1
	jne config_mem_next
	mov byte ptr es:[edx],0
	mov al,es:[edx]
	cmp al,-1
	jne config_mem_next
	mov ax,word ptr cs:[bx]
	shr ax,9
	push dx
	outb Control1,al
	mov al,ds:Mode
	test al,WORD_MODE
	jz config_mem8
	outb Control2,0C1h
	jmp config_mem_test
config_mem8:
	outb Control2,1
config_mem_test:	
	pop dx
	mov al,2Ah
	mov es:[edx],al
	cmp al,es:[edx]
	je config_mem_ok

config_mem_next:
	add bx,2
	loop config_mem_loop
;
	mov ecx,10000h
	FreeLinear
;
	inb ConfigRegA
	and al,NOT 80h
	outb ConfigRegA, al
	sub ds:IoBase,10h
	stc
	jmp config_mem_done

config_mem_ok:
	mov ax,gdt_sel
	mov es,ax
	push bx
	push edx
	mov bx,ether_mem_sel
	mov word ptr es:[bx],0FFFFh
	mov es:[bx+2],edx
	mov byte ptr es:[bx+5],92h
	shr edx,16
	xor dl,dl
	mov es:[bx+6],dx
	mov es,bx
	pop edx
	pop bx
	movzx eax,word ptr cs:[bx]
	shl eax,4
	or al,7
	mov cx,15
config_mem_phys_loop:
	add eax,1000h
	add edx,1000h
	SetPhysicalPage
	loop config_mem_phys_loop
;
	mov ax,ether_mem_sel
	mov es,ax
	call GetMemWidth
	call GetMemSize
	call GetMemNode
	clc

config_mem_done:
	ret
ConfigMemMode	Endp

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

PciVendorTab:
pci00 DW 10ECh, 8029h
pci01 DW 1050h, 940h
pci02 DW 11F6h, 1401h
pci03 DW 8E2Eh, 3000h
pci04 DW 4A14h, 5000h
pci05 DW 1106h, 926h
pci06 DW 10BDh, 0E34h
pci07 DW 1050h, 5A5Ah
pci08 DW 12C3h, 58h
pci09 DW 12C3h, 5598h
pci0A DW 0,		0

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
	xor ch,ch
	mov cl,PCI_card_ExCa_base
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
;
	xor ch,ch
	mov cl,PCI_command_reg
	ReadPciWord
	or al,PCI_command_IO
	WritePciWord
;
	xor ch,ch
	mov cl,PCI_interrupt_line
	ReadPciByte
;
	mov ds:IoBase,dx
	push ax
	outb InterruptStatusReg,-1
	pop ax
;
	mov bx,cs
	mov es,bx
	mov di,OFFSET NetInt	
	RequestPrivateIrqHandler
;
	call CheckSignature
	jc init_pci_done
;
	call Reset
	jc init_pci_done
;
	call ConfigIoMode
	clc

init_pci_done:
	ret
InitPciAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitIsaAdapter
;
;		DESCRIPTION:    Init ISA adapter if found
;
;       PARAMETERS:     
;
;		RETURNS:		NC		Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoTab:
io0	DW 300h
io1	DW 0
io2	DW 240h
io3	DW 280h
io4	DW 2C0h
io5	DW 320h
io6	DW 340h
io7	DW 360h

IrqTab:
i0	DB 3
i1	DB 4
i2	DB 5
i3	DB 9
i4	DB 10
i5	DB 11
i6	DB 12
i7	DB 15

InitIsaAdapter	Proc near
	xor bx,bx
	mov cx,8
init_isa_loop:
	mov dx,word ptr cs:[bx].IoTab
	or dx,dx
	jz init_isa_next
;
	mov ds:IoBase,dx
	outb InterruptStatusReg,-1
	inb ConfigRegA
	mov ah,al
	and al,7
	add al,al
	cmp al,bl
	jne init_isa_next
	and ah,NOT 80h
	outb ConfigRegA, ah
	inb ConfigRegA
	cmp al,ah
	je init_isa_ok

init_isa_next:
	add bx,2
	loop init_isa_loop
	stc

init_isa_ok:
	inb ConfigRegA
	shr al,3
	and al,7
	movzx bx,al
	mov al,byte ptr cs:[bx].IrqTab
	mov bx,cs
	mov es,bx
	mov di,OFFSET NetInt	
	RequestPrivateIrqHandler
;
	call CheckSignature
	jc init_isa_done
;
	call Reset
	jc init_isa_done
;
	call ConfigMemMode
	jnc init_isa_done
;
	call ConfigIoMode
	clc

init_isa_done:
	ret
InitIsaAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitAdapter
;
;		DESCRIPTION:    Init adapter if found
;
;       PARAMETERS:     
;
;		RETURNS:		NC		Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitAdapter	Proc near
	call InitPciAdapter
	jnc init_adapter_ok
;	
	call InitIsaAdapter
	jc init_adapter_done

init_adapter_ok:
	call InitCore
	clc

init_adapter_done:
	ret
InitAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckPointer
;
;		DESCRIPTION:    Check pointer of receive buffer
;
;		PARAMETERS:		CX		Size of data according to card
;						SI		First two bytes of header
;
;		RETURNS:		NC		OK
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPointer	Proc near
	mov ax,si
	mov bx,cx
	dec bx
	mov bl,ds:NextPacket
	inc bl
	add bh,bl
	cmp bh,ds:PageStop
	jb check_pointer_nowrap
;
	sub bh,ds:PageStop
	add bh,BUFFER_START

check_pointer_nowrap:
	cmp bh,ah
	je check_pointer_ok
;
	stc
	jmp check_pointer_done

check_pointer_ok:
	clc

check_pointer_done:
	ret
CheckPointer	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckPacket
;
;		DESCRIPTION:    Check packet of receive buffer
;
;		PARAMETERS:		CX		Size of data according to card
;						SI		First two bytes of header
;
;		RETURNS:		NC		OK
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPacket	Proc near
	mov ax,si
	and al,0Fh
	cmp al,1
	clc
	je check_packet_done
;
	mov ds:NextPacket,ah
	dec ah
	cmp ah,BUFFER_START
	jne check_packet_remove
;
	mov ah,ds:PageStop
	dec ah

check_packet_remove:
	cli
	outb CommandReg, CommandPage0
	outb BoundaryPtrReg, ah
	sti
	stc

check_packet_done:
	ret
CheckPacket	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReceiveEnd
;
;		DESCRIPTION:    End of receive occured
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveEnd	Proc near
	mov ah,ds:IMR
	or ah,ah
	jz receive_end_done
;
	test ds:Mode, OVERFLOW_MODE
	jnz receive_end_overflow
;
	cli
	outb InterruptStatusReg, InterruptStatusReceive
	mov ah,ds:IMR
	or ah, InterruptStatusOverwrite OR InterruptStatusReceive
	mov ds:IMR,ah
	outb InterruptMaskReg,ah
	sti
	jmp receive_end_done

receive_end_overflow:
	test ds:Mode, LOOPBACK_MODE
	jz receive_end_done
;
	cli
	and ds:Mode, NOT (OVERFLOW_MODE OR LOOPBACK_MODE)
	outb TransmitConfigReg, TransmitConfigNormal
	outb InterruptStatusReg, InterruptStatusReceive OR InterruptStatusOverwrite
	mov ah,ds:IMR
	or ah, InterruptStatusOverwrite OR InterruptStatusReceive
	mov ds:IMR,ah
	outb InterruptMaskReg,ah
	sti
	call StartTransmit

receive_end_done:
	ret
ReceiveEnd	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PreviewIo32
;
;		DESCRIPTION:    Return size of block or no more data
;
;		RETURNS:		NC		Data available
;						ECX		Size of data
;						DX		Packet type
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PreviewIo32	Proc far
	push ds
	push eax
	push bx
	push si
;
	mov ax,ether_data_sel
	mov ds,ax

prev_io32_loop:
	cli
	outb CommandReg, CommandPage1
	inb CurrentPageReg
	mov bl,al
	outb CommandReg, CommandPage0
	cmp bl,ds:NextPacket
	jne prev_io32_data
;
	call ReceiveEnd
	sti
	stc
	jmp prev_io32_done

prev_io32_data:
	sti
	mov bh,ds:NextPacket
	xor bl,bl
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in eax,dx
	sti
	mov si,ax
	shr eax,16
	movzx ecx,ax
;
	mov bl,16
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in eax,dx
	sti
	mov dx,ax
	xchg dl,dh
;
	call CheckPointer
	jc prev_io32_done
;
	call CheckPacket
	jc prev_io32_loop
;
	sub cx,18

prev_io32_done:
	sti
	pop si
	pop bx
	pop eax
	pop ds
	retf32
PreviewIo32	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PreviewIo16
;
;		DESCRIPTION:    Return size of block or no more data
;
;		RETURNS:		NC		Data available
;						ECX		Size of data
;						DX		Packet type
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PreviewIo16	Proc far
	push ds
	push ax
	push bx
	push si
;
	mov ax,ether_data_sel
	mov ds,ax

prev_io16_loop:
	cli
	outb CommandReg, CommandPage1
	inb CurrentPageReg
	mov bl,al
	outb CommandReg, CommandPage0
	cmp bl,ds:NextPacket
	jne prev_io16_data
;
	call ReceiveEnd
	sti
	stc
	jmp prev_io16_done

prev_io16_data:
	sti
	mov bh,ds:NextPacket
	xor bl,bl
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in ax,dx
	mov si,ax
	in ax,dx
	sti
	movzx ecx,ax
;
	mov bl,16
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 2
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in ax,dx
	sti
	mov dx,ax
	xchg dl,dh
;
	call CheckPointer
	jc prev_io16_done
;
	call CheckPacket
	jc prev_io16_loop
;
	sub cx,18

prev_io16_done:
	pop si
	pop bx
	pop ax
	pop ds
	retf32
PreviewIo16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PreviewIo8
;
;		DESCRIPTION:    Return size of block or no more data
;
;		RETURNS:		NC		Data available
;						ECX		Size of data
;						DX		Packet type
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PreviewIo8	Proc far
	push ds
	push ax
	push bx
	push si
;
	mov ax,ether_data_sel
	mov ds,ax

prev_io8_loop:
	cli
	outb CommandReg, CommandPage1
	inb CurrentPageReg
	mov bl,al
	outb CommandReg, CommandPage0
	cmp bl,ds:NextPacket
	jne prev_io8_data
;
	call ReceiveEnd
	sti
	stc
	jmp prev_io8_done

prev_io8_data:
	sti
	mov bh,ds:NextPacket
	xor bl,bl
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in al,dx
	mov ah,al
	in al,dx
	xchg al,ah
	mov si,ax
	in al,dx
	mov ah,al
	in al,dx
	sti
	xchg al,ah
	movzx ecx,ax
;
	mov bl,16
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 2
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in al,dx
	mov ah,al
	in al,dx
	sti
	mov dx,ax
;
	call CheckPointer
	jc prev_io8_done
;
	call CheckPacket
	jc prev_io8_loop
;
	sub cx,18

prev_io8_done:
	pop si
	pop bx
	pop ax
	retf32
PreviewIo8	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PreviewMem16
;
;		DESCRIPTION:    Return size of block or no more data
;
;		RETURNS:		NC		Data available
;						ECX		Size of data
;						DX		Packet type
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PreviewMem16	Proc far
	push ds
	push ax
	push bx
	push si
;
	mov ax,ether_data_sel
	mov ds,ax

prev_mem16_loop:
	cli
	outb CommandReg, CommandPage1
	inb CurrentPageReg
	mov bl,al
	outb CommandReg, CommandPage0
	cmp bl,ds:NextPacket
	jne prev_mem16_data
;
	call ReceiveEnd
	sti
	stc
	jmp prev_mem16_done

prev_mem16_data:
	sti
	mov bh,ds:NextPacket
	sub bh,BUFFER_START
	mov ax,ether_mem_sel
	mov ds,ax
	xor bl,bl
	mov si,[bx]
	movzx ecx,word ptr [bx+2]
	movzx edx,word ptr [bx+16]
	xchg dl,dh
;
	call CheckPointer
	jc prev_mem16_done
;
	call CheckPacket
	jc prev_mem16_loop
;
	sub cx,18

prev_mem16_done:
	pop si
	pop bx
	pop ax
	pop ds
	retf32
PreviewMem16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PreviewMem8
;
;		DESCRIPTION:    Return size of block or no more data
;
;		RETURNS:		NC		Data available
;						ECX		Size of data
;						DX		Packet type
;						DS:ESI	Source address
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PreviewMem8	Proc far
	push ds
	push ax
	push bx
	push si
;
	mov ax,ether_data_sel
	mov ds,ax

prev_mem8_loop:
	cli
	outb CommandReg, CommandPage1
	inb CurrentPageReg
	mov bl,al
	outb CommandReg, CommandPage0
	cmp bl,ds:NextPacket
	jne prev_mem8_data
;
	call ReceiveEnd
	sti
	stc
	jmp prev_mem8_done

prev_mem8_data:
	sti
	mov bh,ds:NextPacket
	sub bh,BUFFER_START
	mov ax,ether_mem_sel
	mov ds,ax
	xor bl,bl
	mov al,[bx]
	mov ah,[bx+1]
	mov si,ax
	mov cl,[bx+2]
	mov ch,[bx+3]
	movzx ecx,cx
	mov dh,[bx+16]
	mov dl,[bx+17]
;
	call CheckPointer
	jc prev_mem8_done
;
	call CheckPacket
	jc prev_mem8_loop
;
	sub cx,18

prev_mem8_done:
	pop si
	pop bx
	pop ax
	pop ds
	retf32
PreviewMem8	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReceiveIo32
;
;		DESCRIPTION:    Receive data
;
;       PARAMETERS:     ES:EDI		data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveIo32	Proc far
	push ds
	push eax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ether_data_sel
	mov ds,ax
	mov bh,ds:NextPacket
;
	pushf
	cli
	xor bl,bl
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in eax,dx
	popf
	sti
;
	shr eax,16
	mov cx,ax
;
	cmp cx,100h
	ja receive_io32_large
;
	sub cx,16
	mov bl,16
	pushf
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	mov bx,cx
	and bx,0FFFCh
	add bx,4
	outw RemoteCountReg, bx
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in eax,dx
	sub cx,4
	jnc receive_io32_whole
	sti
	stosb
	jmp receive_io32_done

receive_io32_whole:
	shr eax,16
	stosw
;
	push cx
	shr cx,2
	rep insd
	pop cx
	and cx,3
	jz receive_io32_done
;
	in eax,dx
	sti
	stosb
	sub cx,1
	jz receive_io32_done
;
	shr eax,8
	stosb
	sub cx,1
	jz receive_io32_done
;
	shr eax,8
	stosb
	jmp receive_io32_done

receive_io32_large:
	sub cx,16
	mov bl,16
	pushf
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	push bx
	mov bx,0F0h
	outw RemoteCountReg, bx
	outb CommandReg, CommandRead
	pop bx
;
	mov dx,ds:IoBase
	add dx,IoReg
	in eax,dx
	sub cx,4
	shr eax,16
	stosw
;
	sub cx,0ECh
	push cx
	mov cx,0ECh SHR 2
	rep insd
	pop cx
	sti
	popf

receive_io32_large_loop:
	xor bl,bl
	inc bh
	cmp bh,ds:PageStop
	jne receive_io32_large_nowrap
;
	mov bh,BUFFER_START

receive_io32_large_nowrap:
	cmp cx,100h
	jbe receive_io32_large_last
;
	pushf
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 100h
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	sub cx,100h
	push cx
	mov cx,100h SHR 2
	rep insd
	pop cx
	popf
	sti
	jmp receive_io32_large_loop

receive_io32_large_last:
	pushf
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	mov bx,cx
	and bx,0FFFCh
	add bx,4
	outw RemoteCountReg, bx
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	push cx
	shr cx,2
	rep insd
	pop cx
	and cx,3
	jz receive_io32_done
;
	in eax,dx
	sti
	stosb
	sub cx,1
	jz receive_io32_done
;
	shr eax,8
	stosb
	sub cx,1
	jz receive_io32_done
;
	shr eax,8
	stosb
	
receive_io32_done:
	popf
	sti
;
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop eax
	pop ds
	retf32
ReceiveIo32	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReceiveIo16
;
;		DESCRIPTION:    Receive data
;
;       PARAMETERS:     ES:EDI		Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveIo16	Proc far
	push ds
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ether_data_sel
	mov ds,ax
	mov bh,ds:NextPacket
;
	cli
	mov bl,2
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 2
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in ax,dx
	sti
;
	mov cx,ax
	cmp cx,100h
	ja receive_io16_large
;
	sub cx,18
	mov bl,18
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	mov bx,cx
	and bx,0FFFEh
	add bx,2
	outw RemoteCountReg, bx
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	push cx
	shr cx,1
	rep insw
	pop cx
	and cx,1
	jz receive_io16_done
;
	in ax,dx
	sti
	stosb
	jmp receive_io16_done

receive_io16_large:
	sub cx,18
	mov bl,18
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	push bx
	mov bx,0EEh
	outw RemoteCountReg, bx
	outb CommandReg, CommandRead
	pop bx
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	sub cx,0EEh
	push cx
	mov cx,0EEh SHR 1
	rep insw
	pop cx
	sti

receive_io16_large_loop:
	xor bl,bl
	inc bh
	cmp bh,ds:PageStop
	jne receive_io16_large_nowrap
;
	mov bh,BUFFER_START

receive_io16_large_nowrap:
	cmp cx,100h
	jbe receive_io16_large_last
;
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 100h
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	sub cx,100h
	push cx
	mov cx,100h SHR 1
	rep insw
	pop cx
	sti
	jmp receive_io16_large_loop

receive_io16_large_last:
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	mov bx,cx
	and bx,0FFFEh
	add bx,2
	outw RemoteCountReg, bx
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	push cx
	shr cx,1
	rep insw
	pop cx
	and cx,1
	jz receive_io16_done
;
	in ax,dx
	sti
	stosb
	
receive_io16_done:
	sti
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	retf32
ReceiveIo16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReceiveIo8
;
;		DESCRIPTION:    Receive data
;
;       PARAMETERS:     ES:EDI		Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveIo8	Proc far
	push ds
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ether_data_sel
	mov ds,ax
	mov bh,ds:NextPacket
;
	cli
	mov bl,2
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 2
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in al,dx
	mov ah,al
	in al,dx
	sti
;
	mov ch,al
	mov cl,ah
	cmp cx,100h
	ja receive_io8_large
;
	sub cx,18
	mov bl,18
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, cx
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	rep insb
	sti
	jmp receive_io8_done

receive_io8_large:
	sub cx,18
	mov bl,18
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	push bx
	mov bx,0EEh
	outw RemoteCountReg, bx
	outb CommandReg, CommandRead
	pop bx
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	sub cx,0EEh
	push cx
	mov cx,0EEh
	rep insb
	pop cx
	sti

receive_io8_large_loop:
	xor bl,bl
	inc bh
	cmp bh,ds:PageStop
	jne receive_io8_large_nowrap
;
	mov bh,BUFFER_START

receive_io8_large_nowrap:
	cmp cx,100h
	jbe receive_io8_large_last
;
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 100h
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	sub cx,100h
	push cx
	mov cx,100h
	rep insb
	pop cx
	sti
	jmp receive_io8_large_loop

receive_io8_large_last:
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	mov bx,cx
	outw RemoteCountReg, bx
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	rep insb
	sti

receive_io8_done:
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	retf32
ReceiveIo8	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReceiveMem16
;
;		DESCRIPTION:    Receive data
;
;       PARAMETERS:     ES:EDI	Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveMem16	Proc far
	push ds
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ether_data_sel
	mov ds,ax
	mov bh,ds:NextPacket
	sub bh,BUFFER_START
;
	mov ax,ether_mem_sel
	mov ds,ax
	xor bl,bl
	mov si,bx
	mov cx,[si+2]
	cmp cx,100h
	ja receive_mem16_large
;
	sub cx,18
	add si,18
;
	push cx
	shr cx,1
	rep movsw
	pop cx
	and cx,1
	jz receive_mem16_done
;
	lodsw
	stosb
	jmp receive_mem16_done

receive_mem16_large:
	sub cx,18
	mov bl,18
;
	sub cx,0EEh
	push cx
	mov si,bx
	mov cx,0EEh SHR 1
	rep movsw
	pop cx

receive_mem16_large_loop:
	xor bl,bl
	add bh,BUFFER_START
	inc bh
	cmp bh,ds:PageStop
	jne receive_mem16_large_nowrap
;
	mov bh,BUFFER_START

receive_mem16_large_nowrap:
	sub bh,BUFFER_START
	cmp cx,100h
	jbe receive_mem16_large_last
;
	sub cx,100h
	push cx
	mov si,bx
	mov cx,100h SHR 1
	rep movsw
	pop cx
	jmp receive_mem16_large_loop

receive_mem16_large_last:
	mov si,bx
	push cx
	shr cx,1
	rep movsw
	pop cx
	and cx,1
	jz receive_mem16_done
;
	lodsw
	stosb
	
receive_mem16_done:
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	retf32
ReceiveMem16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReceiveMem8
;
;		DESCRIPTION:    Receive data
;
;       PARAMETERS:     ES:EDI	Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReceiveMem8	Proc far
	push ds
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ether_data_sel
	mov ds,ax
	mov bh,ds:NextPacket
	sub bh,BUFFER_START
;
	mov ax,ether_mem_sel
	mov ds,ax
	xor bl,bl
	mov si,bx
	mov cl,[si+2]
	mov ch,[si+3]
	cmp cx,100h
	ja receive_mem8_large
;
	sub cx,18
	add si,18
;
	rep movsb
	jmp receive_mem8_done

receive_mem8_large:
	sub cx,18
	mov bl,18
;
	sub cx,0EEh
	push cx
	mov si,bx
	mov cx,0EEh
	rep movsb
	pop cx

receive_mem8_large_loop:
	xor bl,bl
	add bh,BUFFER_START
	inc bh
	cmp bh,ds:PageStop
	jne receive_mem8_large_nowrap
;
	mov bh,BUFFER_START

receive_mem8_large_nowrap:
	sub bh,BUFFER_START
	cmp cx,100h
	jbe receive_mem8_large_last
;
	sub cx,100h
	push cx
	mov si,bx
	mov cx,100h
	rep movsb
	pop cx
	jmp receive_mem8_large_loop

receive_mem8_large_last:
	mov si,bx
	rep movsb

receive_mem8_done:
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	retf32
ReceiveMem8	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemoveIo32
;
;		DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveIo32	Proc far
	push ds
	push eax
	push bx
	push dx
;
	mov ax,ether_data_sel
	mov ds,ax
	mov bh,ds:NextPacket
;
	xor bl,bl
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 4
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in eax,dx
	sti
	mov ds:NextPacket,ah
;
	dec ah
	cmp ah,BUFFER_START
	jne rem_io32_do
;
	mov ah,ds:PageStop
	dec ah

rem_io32_do:
	cli
	outb CommandReg, CommandPage0
	outb BoundaryPtrReg, ah
	sti
;
	pop dx
	pop bx
	pop eax
	pop ds
	retf32
RemoveIo32	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemoveIo16
;
;		DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveIo16	Proc far
	push ds
	push ax
	push bx
	push dx
;
	mov ax,ether_data_sel
	mov ds,ax
	mov bh,ds:NextPacket
;
	xor bl,bl
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 2
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in ax,dx
	sti
	mov ds:NextPacket,ah
;
	dec ah
	cmp ah,BUFFER_START
	jne rem_io16_do
;
	mov ah,ds:PageStop
	dec ah

rem_io16_do:
	cli
	outb CommandReg, CommandPage0
	outb BoundaryPtrReg, ah
	sti
;
	pop dx
	pop bx
	pop ax
	pop ds
	retf32
RemoveIo16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemoveIo8
;
;		DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveIo8	Proc far
	push ds
	push ax
	push bx
	push dx
;
	mov ax,ether_data_sel
	mov ds,ax
	mov bh,ds:NextPacket
;
	mov bl,1
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 1
	outb CommandReg, CommandRead
;
	mov dx,ds:IoBase
	add dx,IoReg
	in al,dx
	sti
	mov ah,al
	mov ds:NextPacket,ah
;
	dec ah
	cmp ah,BUFFER_START
	jne rem_io8_do
;
	mov ah,ds:PageStop
	dec ah

rem_io8_do:
	cli
	outb CommandReg, CommandPage0
	outb BoundaryPtrReg, ah
	sti
;
	pop dx
	pop bx
	pop ax
	pop ds
	retf32
RemoveIo8	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemoveMem16
;
;		DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveMem16	Proc far
	push ds
	push es
	push ax
	push bx
	push dx
;
	mov ax,ether_data_sel
	mov ds,ax
	mov ax,ether_mem_sel
	mov es,ax
;
	mov bh,ds:NextPacket
	sub bh,BUFFER_START
	xor bl,bl
	mov ax,es:[bx]
	mov ds:NextPacket,ah
;
	dec ah
	cmp ah,BUFFER_START
	jne rem_mem16_do
;
	mov ah,ds:PageStop
	dec ah

rem_mem16_do:
	cli
	outb CommandReg, CommandPage0
	outb BoundaryPtrReg, ah
	sti

rem_mem16_done:
	pop dx
	pop bx
	pop ax
	pop es
	pop ds
	retf32
RemoveMem16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemoveMem8
;
;		DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveMem8	Proc far
	push ds
	push es
	push ax
	push bx
	push dx
;
	mov ax,ether_data_sel
	mov ds,ax
	mov ax,ether_mem_sel
	mov es,ax
;
	cli
	mov bh,ds:NextPacket
	sub bh,BUFFER_START
	mov bl,1
	mov ah,es:[bx]
	mov ds:NextPacket,ah
;
	dec ah
	cmp ah,BUFFER_START
	jne rem_mem8_do
;
	mov ah,ds:PageStop
	dec ah

rem_mem8_do:
	cli
	outb CommandReg, CommandPage0
	outb BoundaryPtrReg, ah
	sti
;
	pop dx
	pop bx
	pop ax
	pop es
	pop ds
	retf32
RemoveMem8	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForSendBuffer
;
;		DESCRIPTION:    Wait for a send buffer
;
;       PARAMETERS:     ECX		size
;
;		RETURNS:		BL		start page
;						AL		next page
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForSendBuffer	Proc near
	push cx
	push dx
;
	dec cx
	inc ch
	xor cl,cl

wait_for_send_loop:
	cli
	mov bl,ds:SendPending
	cmp bl,ds:SendCurrent
	ja wait_for_send_wrapping
	je wait_for_send_done
;
	mov ah,ds:SendCurrent
	sub ah,bl
	cmp ah,ch
	jae wait_for_send_done
	jmp wait_for_send_wait

wait_for_send_wrapping:
	mov ah,ds:SendStop
	sub ah,bl
	cmp ah,ch
	jae wait_for_send_done
;
	mov bl,ds:SendStart
	mov ah,ds:SendCurrent
	sub ah,bl
	cmp ah,ch
	jae wait_for_send_done

wait_for_send_wait:
	sti
	inc cl
	cmp cl,20
	je wait_for_send_reset
;
	GetSystemTime
	sub eax,ds:LastConfirm
	sbb edx,ds:LastConfirm+4
	or edx,edx
	jnz wait_for_send_reset
;
	cmp eax,50 * 1193
	ja wait_for_send_reset
;
	mov ax,10
	WaitMilliSec
	jmp wait_for_send_loop

wait_for_send_reset:
	call Reset
	call InitCore
;
	outb InterruptMaskReg,InterruptMaskEnable
	outb ReceiveConfigReg,ReceiveConfigNormal
	outb CommandReg,CommandStart
	and ds:Mode, NOT (OVERFLOW_MODE OR LOOPBACK_MODE)
	jmp wait_for_send_loop

wait_for_send_done:
	sti
	mov al,bl
	add al,ch
	cmp al,ds:SendStop
	jbe wait_for_send_end
;
	mov al,ds:SendStart

wait_for_send_end:
	pop dx
	pop cx
	ret
WaitForSendBuffer	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendIo32
;
;		DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX		size
;						DX		packet type
;						DS:ESI	dest address
;						ES:EDI	data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendIo32	Proc far
	push ds
	push fs
	push eax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ds
	mov fs,ax
	mov ax,ether_data_sel
	mov ds,ax
;
	add cx,14
	EnterSection ds:SendSection
	call WaitForSendBuffer
;
	push ax
	push dx
	movzx bx,bl
	shl bx,2
	mov ds:[bx].SendHeader.sh_size,cx
	mov ds:[bx].SendHeader.sh_next,al
	sti
;
	shl bx,6
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 12
	outb CommandReg, CommandWrite
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	mov eax,fs:[esi]
	out dx,eax
	mov ax,word ptr ds:EthernetAddress
	shl eax,16
	mov ax,fs:[esi+4]
	out dx,eax
	mov eax,dword ptr ds:EthernetAddress+2
	out dx,eax
	sti
;
	mov si,di
	sub cx,12
	mov bl,12
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	mov bx,cx
	and bx,0FFFCh
	add bx,4
	outw RemoteCountReg, bx
	outb CommandReg, CommandWrite
;
	pop ax
	xchg al,ah
	mov dx,ds:IoBase
	add dx,IoReg
	sub cx,4
	jnc send_io32_whole
	ror eax,16
	mov al,es:[si]
	rol eax,16
	out dx,eax
	jmp send_io32_done

send_io32_whole:
	ror eax,16
	mov ax,es:[si]
	rol eax,16
	out dx,eax
	add si,2
;
	push cx
	shr cx,2
	db 26h		; es override. asm can't handle this
	rep outsd
	pop cx
	and cx,3
	jz send_io32_done
;
	mov al,es:[si]
	sub cx,1
	jz send_io32_out_final
;
	mov ah,es:[si+1]
	sub cx,1
	jz send_io32_out_final
;
	ror eax,16
	mov al,es:[si+2]
	rol eax,16

send_io32_out_final:
	out dx,eax
	
send_io32_done:
	sti
	pop ax
	mov ds:SendPending,al
	LeaveSection ds:SendSection
	call StartTransmit
;
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop eax
	pop fs
	pop ds
	retf32
SendIo32	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendIo16
;
;		DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX		size
;						DX		packet type
;						DS:ESI	dest address
;						ES:EDI	data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendIo16	Proc far
	push ds
	push fs
	push eax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ds
	mov fs,ax
	mov ax,ether_data_sel
	mov ds,ax
;
	add cx,14
	EnterSection ds:SendSection
	call WaitForSendBuffer
;
	push ax
	push dx
	movzx bx,bl
	shl bx,2
	mov ds:[bx].SendHeader.sh_size,cx
	mov ds:[bx].SendHeader.sh_next,al
	sti
;
	shl bx,6
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 14
	outb CommandReg, CommandWrite
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	mov ax,fs:[esi]
	out dx,ax
	mov ax,fs:[esi+2]
	out dx,ax
	mov ax,fs:[esi+4]
	out dx,ax
	mov ax,word ptr ds:EthernetAddress
	out dx,ax
	mov ax,word ptr ds:EthernetAddress+2
	out dx,ax
	mov ax,word ptr ds:EthernetAddress+4
	out dx,ax
	pop ax
	xchg al,ah
	out dx,ax
	sti
;
	mov si,di
	sub cx,14
	mov bl,14
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	mov bx,cx
	and bx,0FFFEh
	add bx,2
	outw RemoteCountReg, bx
	outb CommandReg, CommandWrite
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	push cx
	shr cx,1
	db 26h		; es override. asm can't handle this
	rep outsw
	pop cx
	and cx,1
	jz send_io16_done
;
	mov al,es:[si]
	out dx,ax
	
send_io16_done:
	sti
	pop ax
	mov ds:SendPending,al
	LeaveSection ds:SendSection
	call StartTransmit
;
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop eax
	pop fs
	pop ds
	retf32
SendIo16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendIo8
;
;		DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX		size
;						DX		packet type
;						DS:ESI	dest address
;						ES:EDI	data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendIo8	Proc far
	push ds
	push fs
	push eax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ds
	mov fs,ax
	mov ax,ether_data_sel
	mov ds,ax
;
	add cx,14
	EnterSection ds:SendSection
	call WaitForSendBuffer
;
	push ax
	push dx
	movzx bx,bl
	shl bx,2
	mov ds:[bx].SendHeader.sh_size,cx
	mov ds:[bx].SendHeader.sh_next,al
	sti
;
	shl bx,6
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	outw RemoteCountReg, 14
	outb CommandReg, CommandWrite
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	mov al,fs:[esi]
	out dx,al
	mov al,fs:[esi+1]
	out dx,al
	mov al,fs:[esi+2]
	out dx,al
	mov al,fs:[esi+3]
	out dx,al
	mov al,fs:[esi+4]
	out dx,al
	mov al,fs:[esi+5]
	out dx,al
	mov al,byte ptr ds:EthernetAddress
	out dx,al
	mov al,byte ptr ds:EthernetAddress+1
	out dx,al
	mov al,byte ptr ds:EthernetAddress+2
	out dx,al
	mov al,byte ptr ds:EthernetAddress+3
	out dx,al
	mov al,byte ptr ds:EthernetAddress+4
	out dx,al
	mov al,byte ptr ds:EthernetAddress+5
	out dx,al
	pop ax
	xchg al,ah
	out dx,al
	mov al,ah
	out dx,al
	sti
;
	mov si,di
	sub cx,14
	mov bl,14
	cli
	outb CommandReg, CommandPage0
	outw RemoteAddressReg, bx
	mov bx,cx
	outw RemoteCountReg, bx
	outb CommandReg, CommandWrite
;
	mov dx,ds:IoBase
	add dx,IoReg
;
	db 26h		; es override. asm can't handle this
	rep outsb
	sti
	pop ax
	mov ds:SendPending,al
	LeaveSection ds:SendSection
	call StartTransmit
;
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop eax
	pop fs
	pop ds
	retf32
SendIo8	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendMem16
;
;		DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX		size
;						DX		packet type
;						DS:ESI	dest address
;						ES:EDI	data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendMem16	Proc far
	push ds
	push fs
	push gs
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ds
	mov fs,ax
	mov ax,ether_data_sel
	mov ds,ax
	mov ax,ether_mem_sel
	mov gs,ax
;
	add cx,14
	EnterSection ds:SendSection
	call WaitForSendBuffer
;
	push ax
	push dx
	movzx bx,bl
	shl bx,2
	mov ds:[bx].SendHeader.sh_size,cx
	mov ds:[bx].SendHeader.sh_next,al
	sti
;
	shl bx,6
	sub bx,BUFFER_START SHL 8
;
	mov ax,fs:[esi]
	mov gs:[bx],ax
	add bx,2
;
	mov ax,fs:[esi+2]
	mov gs:[bx],ax
	add bx,2
;
	mov ax,fs:[esi+4]
	mov gs:[bx],ax
	add bx,2
;
	mov ax,word ptr ds:EthernetAddress
	mov gs:[bx],ax
	add bx,2
;
	mov ax,word ptr ds:EthernetAddress+2
	mov gs:[bx],ax
	add bx,2
;
	mov ax,word ptr ds:EthernetAddress+4
	mov gs:[bx],ax
	add bx,2
;
	pop ax
	xchg al,ah
	mov gs:[bx],ax
	add bx,2
;
	sub cx,14
	push ds
	push es
	mov ax,es
	mov ds,ax
	mov ax,gs
	mov es,ax
	mov si,di
	mov di,bx
	push cx
	shr cx,1
	rep movsw
	pop cx
	and cx,1
	jz send_mem16_sent
	lodsb
	stosw
send_mem16_sent:
	pop es
	pop ds
	pop ax
	mov ds:SendPending,al
	LeaveSection ds:SendSection
	call StartTransmit
;
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop ax
	pop gs
	pop fs
	pop ds
	retf32
SendMem16	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SendMem8
;
;		DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX		size
;						DX		packet type
;						DS:ESI	dest address
;						ES:EDI	data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendMem8	Proc far
	push ds
	push fs
	push gs
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,ds
	mov fs,ax
	mov ax,ether_data_sel
	mov ds,ax
	mov ax,ether_mem_sel
	mov gs,ax
;
	add cx,14
	EnterSection ds:SendSection
	call WaitForSendBuffer
;
	push ax
	push dx
	movzx bx,bl
	shl bx,2
	mov ds:[bx].SendHeader.sh_size,cx
	mov ds:[bx].SendHeader.sh_next,al
	sti
;
	shl bx,6
	sub bx,BUFFER_START SHL 8
;
	mov al,fs:[esi]
	mov gs:[bx],al
	inc bx
;
	mov al,fs:[esi+1]
	mov gs:[bx],al
	inc bx
;
	mov al,fs:[esi+2]
	mov gs:[bx],al
	inc bx
;
	mov al,fs:[esi+3]
	mov gs:[bx],al
	inc bx
;
	mov al,fs:[esi+4]
	mov gs:[bx],al
	inc bx
;
	mov al,byte ptr ds:EthernetAddress
	mov gs:[bx],al
	inc bx
;
	mov al,byte ptr ds:EthernetAddress+1
	mov gs:[bx],al
	inc bx
;
	mov al,byte ptr ds:EthernetAddress+2
	mov gs:[bx],al
	inc bx
;
	mov al,byte ptr ds:EthernetAddress+3
	mov gs:[bx],al
	inc bx
;
	mov al,byte ptr ds:EthernetAddress+4
	mov gs:[bx],al
	inc bx
;
	mov al,byte ptr ds:EthernetAddress+5
	mov gs:[bx],al
	inc bx
;
	pop ax
	xchg al,ah
	mov gs:[bx],al
	inc bx
	mov al,ah
	mov gs:[bx],al
	inc bx
;
	sub cx,14
	push ds
	push es
	mov ax,es
	mov ds,ax
	mov ax,gs
	mov es,ax
	mov si,di
	mov di,bx
	rep movsb
	pop es
	pop ds
	pop ax
	mov ds:SendPending,al
	LeaveSection ds:SendSection
	call StartTransmit
;
	pop di
	pop si	
	pop dx
	pop cx
	pop bx
	pop ax
	pop gs
	pop fs
	pop ds
	retf32
SendMem8	Endp

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

Mem8Table:
	DD OFFSET PreviewMem8,	 	ether_code_sel
	DD OFFSET ReceiveMem8,		ether_code_sel
	DD OFFSET RemoveMem8,		ether_code_sel
	DD OFFSET SendMem8,			ether_code_sel
	DD OFFSET GetAddress,		ether_code_sel
	DD OFFSET GetPktAddress,	ether_code_sel

Mem16Table:
	DD OFFSET PreviewMem16,		ether_code_sel
	DD OFFSET ReceiveMem16,		ether_code_sel
	DD OFFSET RemoveMem16,		ether_code_sel
	DD OFFSET SendMem16,		ether_code_sel
	DD OFFSET GetAddress,		ether_code_sel
	DD OFFSET GetPktAddress,	ether_code_sel

Io8Table:
	DD OFFSET PreviewIo8,	 	ether_code_sel
	DD OFFSET ReceiveIo8,		ether_code_sel
	DD OFFSET RemoveIo8,		ether_code_sel
	DD OFFSET SendIo8,			ether_code_sel
	DD OFFSET GetAddress,		ether_code_sel
	DD OFFSET GetPktAddress,	ether_code_sel

Io16Table:
	DD OFFSET PreviewIo16,		ether_code_sel
	DD OFFSET ReceiveIo16,		ether_code_sel
	DD OFFSET RemoveIo16,		ether_code_sel
	DD OFFSET SendIo16,			ether_code_sel
	DD OFFSET GetAddress,		ether_code_sel
	DD OFFSET GetPktAddress,	ether_code_sel

Io32Table:
	DD OFFSET PreviewIo32,	 	ether_code_sel
	DD OFFSET ReceiveIo32,		ether_code_sel
	DD OFFSET RemoveIo32,		ether_code_sel
	DD OFFSET SendIo32,			ether_code_sel
	DD OFFSET GetAddress,		ether_code_sel
	DD OFFSET GetPktAddress,	ether_code_sel

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

ne2000_name	DB 'NE2000',0

ne2000_thread	proc far
	int 3
	mov bx,ether_data_sel
	mov ds,bx
	mov es,bx
	call InitAdapter
	ret
ne2000_thread	endp
	
init_net	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET ne2000_name
	mov si,OFFSET ne2000_thread
	mov ax,4
	mov cx,100h
	CreateThread
	jmp init_net_done

	mov ax,ether_data_sel
	mov ds,ax
	test ds:Mode,MEM_MODE
	jz init_net_io

init_net_mem:
	test ds:Mode,WORD_MODE
	mov esi,OFFSET Mem16Table
	jnz init_net_register
	mov esi,OFFSET Mem8Table
	jmp init_net_register

init_net_io:
	test ds:Mode,DWORD_MODE
	mov esi,OFFSET Io32Table
	jnz init_net_register
	test ds:Mode,WORD_MODE
	mov esi,OFFSET Io16Table
	jnz init_net_register
	mov esi,OFFSET Io8Table

init_net_register:
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov edi,OFFSET DriverName
	mov al,1
	mov dx,0
	mov ecx,1600
	RegisterNetDriver
;
	mov ax,ether_data_sel
	mov ds,ax
	mov ds:Handle,bx
	mov ds:IMR,InterruptMaskEnable
	outb InterruptMaskReg,InterruptMaskEnable
	outb ReceiveConfigReg,ReceiveConfigNormal
	outb CommandReg,CommandStart
	and ds:Mode, NOT (OVERFLOW_MODE OR LOOPBACK_MODE)

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

DriverName	DB 'NE2000',0

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
	InitSection ds:SendSection
;
;	call InitAdapter
;	jc init_fail
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
