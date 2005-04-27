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
; 8255x.ASM
; Intel 8255 series network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        NAME i8255x

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\pci.inc
INCLUDE ..\os\net.inc

RX_RING_SIZE EQU 10000h
TX_RING_SIZE EQU 4000h

Reverse	MACRO
	xchg al,ah
	rol eax,16
	xchg al,ah
		ENDM

SCBStatus       = 0
SCBCommand      = 2
SCBPointer      = 4
Port            = 8
EeControl       = 0Eh
MDIControl      = 10h
RxDMASize       = 14h

; EeControl bits

EESK        = 1
EECS        = 2
EEDI        = 4
EEDO        = 8

; The EEPROM commands include the always-set leading bit.

EE_WRITE_CMD = 5
EE_READ_CMD = 6
EE_ERASE_CMD = 7

; SCBCommands

CB_NOP      = 0
CB_IAADDR   = 1
CB_CONFIG   = 2
CB_MULTI    = 3
CB_TX       = 4
CB_UCODE    = 5
CB_DUMP     = 6
CB_TX_SF    = 8

; RU commands 

RU_NOP          = 0
RU_START        = 1
RU_RESUME       = 2
RU_DMA_REDIR    = 3
RU_ABORT        = 4
RU_HDS          = 5
RU_BASE         = 6

; CU commands

CU_NOP          = 00h
CU_START        = 10h
CU_RESUME       = 20h
CU_DUMP_CNT     = 40h
CU_DUMP_STAT    = 50h
CU_BASE         = 60h
CU_DUMP_RESET   = 70h

; SCBStatus bits

CB_COMPLETE     = 8000h
CB_OK           = 2000h

; Cmd bits

CMD_EL          = 8000h
CMD_S           = 4000h
CMD_I           = 2000h
CMD_H           = 10h
CMD_SF          = 8

; status bits

ST_C            = 8000h
ST_OK           = 2000h

; actual count bits

AC_EOF          = 8000h
AC_F            = 4000h

rfd     STRUC

rfd_status      DW ?
rfd_command     DW ?
rfd_link        DD ?
rfd_rbd         DD ?
rfd_actual_size DW ?
rfd_size        DW ?

rfd     ENDS

cb  STRUC

cb_status       DW ?
cb_command      DW ?
cb_link         DD ?

cb  ENDS

data	STRUC

MemBase             DD ?
FlashBase           DD ?
IoBase				DW ?
Handle				DW ?
WaitThread          DW ?
IntStat             DB ?
EeAdrLen            DB ?
EthernetAddress		DB 6 DUP(?)

RxRingPhys          DD ?
RxRingLinear        DD ?
RxRingSize          DD ?
RxRingSel           DW ?

TxRingPhys          DD ?
TxRingLinear        DD ?
TxRingSize          DD ?
TxRingSel           DW ?

data	ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EeDelay
;
;		DESCRIPTION:    Delay for EE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EeDelay Proc near
    push ax
    mov ax,5
    WaitMicroSec
    pop ax
    ret
EeDelay Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetEeSize
;
;		DESCRIPTION:    Determine EE size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetEeSize	Proc near
	pusha
;
	mov dx,ds:IoBase
	add dx,EeControl
;
	mov al,EECS
	out dx,al
    call EeDelay
;
	mov bx,EE_READ_CMD
	mov cx,3
	mov si,4

gesCodeLoop:
    and al,NOT EEDI
    test si,bx
    jz gesCodeWrite
;
    or al,EEDI

gesCodeWrite:
    or al,EESK
    out dx,al
    call EeDelay
;
    and al,NOT EESK
    out dx,al
    call EeDelay    
;
    shr si,1
    loop gesCodeLoop
;
    mov cx,16
    mov ds:EeAdrLen,0
    
gesAddressLoop:
    mov al,EECS OR EESK
    out dx,al
    call EeDelay
;         
    mov al,EECS
    out dx,al
    call EeDelay
;
    inc ds:EeAdrLen
    in al,dx
    test al,EEDO
    jz gesAddressDone
;
    loop gesAddressLoop 
    stc
    jmp gesDone 

gesAddressDone:
    mov cx,16

gesDataLoop:
    mov al,EECS OR EESK
    out dx,al
    call EeDelay
;    
    in al,dx
;
    mov al,EECS
    out dx,al
    call EeDelay
;
    loop gesDataLoop
;
    xor al,al
    out dx,al
    call EeDelay
    clc

gesDone:           
    popa
	ret
GetEeSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadEe
;
;		DESCRIPTION:    Read from EE
;
;       PARAMETERS:     BX		Location
;
;		RETURNS:		AX		Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEe	Proc near
    push cx
	push dx
	push si
;
	mov dx,ds:IoBase
	add dx,EeControl
;
	mov al,EECS
	out dx,al
    call EeDelay
;
    push bx
	mov bx,EE_READ_CMD
	mov cx,3
	mov si,4

reCodeLoop:
    and al,NOT EEDI
    test si,bx
    jz reCodeWrite
;
    or al,EEDI

reCodeWrite:
    or al,EESK
    out dx,al
    call EeDelay
;
    and al,NOT EESK
    out dx,al
    call EeDelay    
;
    shr si,1
    loop reCodeLoop
;
    pop bx
    movzx cx,ds:EeAdrLen
    mov si,1
    shl si,cl
    shr si,1
    
reAddressLoop:
    and al,NOT EEDI
    test si,bx
    jz reAddressWrite
;
    or al,EEDI

reAddressWrite:
    or al,EESK
    out dx,al
    call EeDelay
;         
    and al,NOT EESK
    out dx,al
    call EeDelay
;
    shr si,1
    loop reAddressLoop 
;
    xor si,si
    mov cx,16

reDataLoop:
    shl si,1
    mov al,EECS OR EESK
    out dx,al
    call EeDelay
;    
    in al,dx
    test al,EEDO
    jz reDataNext
;
    or si,1

reDataNext:
    mov al,EECS
    out dx,al
    call EeDelay
;
    loop reDataLoop
;
    xor al,al
    out dx,al
    call EeDelay
;
    mov ax,si
;    
    pop si
    pop dx
    pop cx
	ret
ReadEe	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadEthernetAddress
;
;		DESCRIPTION:    Read the ethernet address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEthernetAddress	Proc near
	xor bx,bx
	mov si,OFFSET EthernetAddress

reaReadLoop:
	call ReadEe
	mov ds:[si],ax
	add si,2
	inc bx
	cmp bx,3
	jne reaReadLoop
;
	ret
ReadEthernetAddress	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForAccept
;
;		DESCRIPTION:    Wait for RU / CU command acceptance
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForAccept	Proc near
    mov dx,ds:IoBase
    add dx,SCBCommand

wfaLoop:
    in al,dx
    or al,al
    jz wfaDone
;
    mov ax,1
    WaitMilliSec
    jmp wfaLoop    

wfaDone: 
    ret
WaitForAccept   Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitTx
;
;		DESCRIPTION:    Init command ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTx	Proc near
	mov ecx,TX_RING_SIZE SHR 12
	AllocateMultiplePhysical
	jc itDone
;
	mov ds:TxRingPhys,eax
	mov eax,TX_RING_SIZE
	AllocateBigLinear
	mov ds:TxRingLinear,edx
	mov ds:TxRingSize,eax
;
	mov eax,ds:TxRingPhys
	or al,7
	mov ecx,TX_RING_SIZE SHR 12

it_ring_loop:
	SetPhysicalPage
	add eax,1000h
	add edx,1000h
	loop it_ring_loop
;
	mov ecx,ds:TxRingSize
	mov edx,ds:TxRingLinear
	AllocateGdt
	CreateDataSelector16
	mov ds:TxRingSel,bx
;
    mov eax,ds:TxRingPhys
    mov dx,ds:IoBase
    add dx,SCBPointer     
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,CU_BASE
    out dx,al
    call WaitForAccept    
	clc

itDone:
	ret
InitTx	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetupEthernetAddress
;
;		DESCRIPTION:    Setup ethernet address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupEthernetAddress	Proc near
    mov es,ds:TxRingSel
    mov es:cb_status,0
    mov es:cb_command,CB_IAADDR OR CMD_S
    mov es:cb_link,-1
;
    mov cx,3
    mov si,OFFSET EthernetAddress
    mov di,SIZE CB
    rep movsw
;    
    ClearSignal
    xor eax,eax
    mov dx,ds:IoBase
    add dx,SCBPointer     
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,CU_START
    out dx,al
    call WaitForAccept    
    WaitForSignal
	clc
;
    ret
SetupEthernetAddress    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitRfd
;
;		DESCRIPTION:    Init RFD block
;
;       PARAMETERS:     ES:EDX      RFD address
;                       EAX         Next RFD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRfd	Proc near
    push eax
    mov es:[edx].rfd_link,eax
    mov es:[edx].rfd_command,0
    mov es:[edx].rfd_status,0
    mov es:[edx].rfd_rbd,0
    mov ax,800h - SIZE RFD
    mov es:[edx].rfd_size,ax
    mov es:[edx].rfd_actual_size,0
    pop eax
    ret
InitRfd Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitRx
;
;		DESCRIPTION:    Init receiver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRx	Proc near
	mov ecx,RX_RING_SIZE SHR 12
	AllocateMultiplePhysical
	jc irDone
;
	mov ds:RxRingPhys,eax
	mov eax,RX_RING_SIZE
	AllocateBigLinear
	mov ds:RxRingLinear,edx
	mov ds:RxRingSize,eax
;
	mov eax,ds:RxRingPhys
	or al,7
	mov ecx,RX_RING_SIZE SHR 12

ir_rxring_loop:
	SetPhysicalPage
	add eax,1000h
	add edx,1000h
	loop ir_rxring_loop
;
	mov ecx,ds:RxRingSize
	mov edx,ds:RxRingLinear
	AllocateGdt
	CreateDataSelector16
	mov ds:RxRingSel,bx
;
    mov es,bx	
    xor edx,edx
    mov eax,800h

irInitRfd:
    call InitRfd
    mov edx,eax
    add eax,800h
    cmp eax,RX_RING_SIZE
    jne irInitRfd
;
    xor eax,eax
    call InitRfd   
;
    mov eax,ds:RxRingPhys
    mov dx,ds:IoBase
    add dx,SCBPointer     
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,RU_BASE
    out dx,al
    call WaitForAccept    
;
    mov dx,ds:IoBase
    add dx,SCBPointer
    xor eax,eax
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,SCBCommand
    mov al,RU_START
    out dx,al         
    call WaitForAccept    

irloop:
    mov dx,ds:IoBase
    add dx,SCBStatus
    in eax,dx
    int 3
    jmp irloop
	clc

irDone:
	ret
InitRx	Endp

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
    add dx,1
    in al,dx
    or ds:IntStat,al
    out dx,al
;
    mov bx,ds:WaitThread
    Signal    
    ret
NetInt  Endp

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

DriverName	DB '8255x',0

PciVendorTab:
pci00	DW 8086h, 1209h
pci01	DW 8086h, 1229h
pci02 	DW 0,	  0

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
	mov cx,10h
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov ds:MemBase,edx
;	
	mov cx,14h
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov ds:IoBase,dx
;	
	mov cx,18h
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov ds:FlashBase,edx
;
    call GetEeSize
    jc init_pci_done
;        
    GetThread
    mov ds:WaitThread,ax
    mov ds:IntStat,0
;    
	xor ch,ch
	mov cl,PCI_interrupt_line
	ReadPciByte
	mov bx,cs
	mov es,bx
	mov di,OFFSET NetInt	
	RequestPrivateIrqHandler
;
    call ReadEthernetAddress
    int 3	
    call InitTx
    call SetupEthernetAddress
;    
    mov dx,ds:IoBase
    in eax,dx
;    
    call InitRx
;
	push ds
	mov ax,cs
	mov ds,ax
	mov es,ax
;	mov si,OFFSET DispTable
;	mov di,OFFSET DriverName
	mov al,1
	mov dx,0
	mov ecx,1600
;	RegisterNetDriver
	pop ds
;	mov ds:Handle,bx
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

detect_name	DB '8255x',0

detect_thread	proc far
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
