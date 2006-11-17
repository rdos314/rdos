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
; VIAUSB11.ASM
; VIA USB 1.1 driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME viausb11

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\pci.inc
INCLUDE ..\os\usb.inc

UsbCommandReg = 0
UsbStatusReg = 2
UsbIntReg = 4
FrameNumberReg = 6
FrameBaseReg = 8
SofReg = 12
PortscReg1 = 16
PortscReg2 = 18

usb_func_sel    STRUC

uf_hw_phys      DD ?
uf_hw_linear    DD ?
uf_hw_sel       DW ?
uf_ring_sel     DW ?

uf_io_base      DW ?

uf_sel1         DW ?
uf_sel2         DW ?

usb_func_sel    ENDS

data    STRUC

IoBase1     DW ?
IoBase2     DW ?

UsbSel1     DW ?
UsbSel2     DW ?
UsbSel3     DW ?
UsbSel4     DW ?

UsbFunc1    DW ?
UsbFunc2    DW ?

data    ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UsbInt
;
;		DESCRIPTION:    Usb interrupt
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UsbInt	Proc far
    ret
UsbInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateUsbFunction
;
;		DESCRIPTION:    Create USB function
;
;       PARAMETERS:     DX      IO base
;
;       RETURNS:        ES      USB function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateUsbFunction  Proc near
    push ds
    pushad
;    
    mov eax,SIZE usb_func_sel
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    mov ds:uf_io_base,dx
;        
    mov eax,1000h
	AllocateBigLinear
	mov ds:uf_hw_linear,edx
	mov ecx,eax
	AllocateGdt
	CreateDataSelector16
    mov ds:uf_hw_sel,bx
    mov es,bx
    xor di,di
    mov eax,1
    mov cx,1024
    rep stosd
;
    GetPhysicalPage
    and ax,0F000h
    mov ds:uf_hw_phys,eax    
;
    mov eax,800h
    AllocateSmallGlobalMem
    mov ds:uf_ring_sel,es
    xor di,di
    xor ax,ax
    mov cx,1024
    rep stosw
;    
    mov ax,ds
    mov es,ax
;
    popad
    pop ds
    ret
CreateUsbFunction   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitUsbChannel
;
;		DESCRIPTION:    Init an USB channel
;
;       PARAMETERS:     DX      IO base
;                       BP      Function #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitUsbChannel  Proc near
    push es
    pushad
;
    add bp,bp
    call CreateUsbFunction
    mov ds:[bp].UsbFunc1,es
;        
    mov si,es:uf_ring_sel
    mov di,es:uf_hw_sel
    OpenUsbChannel
    mov ds:[bp].UsbSel1,bx
;    
    OpenUsbChannel
    mov ds:[bp+2].UsbSel2,bx
;
    popad
    pop es
    ret
InitUsbChannel  Endp

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
pci00	DW 1106h, 3038h
pci01	DW 1106h, 0571h
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
	mov cl,PCI_interrupt_line
	ReadPciByte
;
    IsIrqFree
    jnc init_pci_set_irq
;
    and al,0F0h
    or al,13

init_pci_irq_loop:
    IsIrqFree
    jnc init_pci_update_irq
;
    dec al
    or al,al
    jnz init_pci_irq_loop
;
    stc
    jmp init_pci_done

init_pci_update_irq:
   	mov cl,PCI_interrupt_line
	WritePciByte
        
init_pci_set_irq:	
	mov di,cs
	mov es,di
	mov di,OFFSET UsbInt	
	RequestPrivateIrqHandler
;
	mov cl,20h
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov ds:IoBase1,dx
	xor bp,bp
	call InitUsbChannel
;	
	mov ax,1
	mov dx,cs:[si]
	mov cx,cs:[si+2]
	FindPciDevice
	jc init_pci_no2
;	
	mov cl,20h
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov ds:IoBase2,dx
	mov bp,1
	call InitUsbChannel
    clc
    jmp init_pci_done

init_pci_no2:
    mov ds:IoBase2,0
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

detect_name	DB 'VIA-USB-1.1',0

detect_thread	proc far
    int 3
	mov ax,usb_dev_data_sel
	mov ds,ax
	call InitPciAdapter
	ret
detect_thread	endp
	
init_usb	Proc far
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

init_usb_done:
	popa
	pop es
	pop ds
	ret
init_usb	Endp

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
	mov bx,usb_dev_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov eax,SIZE data
	mov bx,usb_dev_data_sel
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
	mov di,OFFSET init_usb
	HookInitTasking

init_fail:
	popa
	pop es
	pop ds
	ret
Init	Endp

ENDS

	END init
