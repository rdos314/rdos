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
; UHCI.ASM
; UHCI-based USB host controller driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME uhci

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\pci.inc
INCLUDE ..\os\usb.inc

MAX_USB_DEVICES = 16

UsbCommandReg = 0
UsbStatusReg = 2
UsbIntReg = 4
FrameNumberReg = 6
FrameBaseReg = 8
SofReg = 12
PortscReg1 = 16
PortscReg2 = 18

uhci_func_sel    STRUC

uhc_hw_phys      DD ?
uhc_hw_linear    DD ?
uhc_hw_sel       DW ?
uhc_ring_sel     DW ?
uhc_io_base      DW ?
uhc_pci_bus_dev  DW ?
uhc_pci_func     DB ?

uhci_func_sel    ENDS

data    STRUC

UhciIrq      DB ?
UhciCount    DW ?
UhciFunc     DW 16 DUP (?)

data    ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UhciInt
;
;		DESCRIPTION:    UHCI interrupt
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UhciInt	Proc far
    mov ax,1234h
    mov ds,ax    
    ret
UhciInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    EnablePort
;
;		DESCRIPTION:    Enable root-hub port
;
;       PARAMETERS:     DS      Function selector
;                       CL      Port # (0,1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnablePort   Proc near
    push ax
    push cx
    push dx
;    
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dl,cl
    add dl,cl
    in ax,dx
    test al,1
    stc
    jz epDone
;
    or ax,200h
    out dx,ax
;
    mov ax,50
    WaitMilliSec
;
    in ax,dx
    and ax,NOT 200h
    out dx,ax
;
    mov cx,10

 epLoop:
    in ax,dx
    test ax,4
    clc
    jnz epDone
;
    or ax,4
    out dx,ax
    loop epLoop
;
    stc
                    
epDone:        
    pop dx
    pop cx
    pop ax
    ret
EnablePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InitFunction
;
;		DESCRIPTION:    Init UHCI function
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitFunction    Proc near
    push eax
    push cx
    push dx
;
    mov dx,ds:uhc_io_base
    add dx,SofReg
    in al,dx
    mov cl,al
;
    mov dx,ds:uhc_io_base
    add dx,UsbCommandReg
    in ax,dx
    or ax,4
    out dx,ax
; 
    mov ax,20
    WaitMilliSec
;
    mov dx,ds:uhc_io_base
    add dx,UsbCommandReg
    in ax,dx
    and ax,NOT 4
    out dx,ax
;
    mov dx,ds:uhc_io_base
    add dx,UsbIntReg
    mov ax,0Fh
    out dx,ax
;
    mov dx,ds:uhc_io_base
    add dx,FrameNumberReg
    xor ax,ax
    out dx,ax
;    
    mov dx,ds:uhc_io_base
    add dx,FrameBaseReg
    mov eax,ds:uhc_hw_phys
    out dx,eax
;    
    mov dx,ds:uhc_io_base
    add dx,SofReg
    mov al,cl
    out dx,al
;
    mov dx,ds:uhc_io_base
    add dx,UsbCommandReg
    in ax,dx
    or ax,0C1h
    out dx,ax
;
    pop dx
    pop cx
    pop eax       
    ret
InitFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddFunction
;
;		DESCRIPTION:    Add UHCI function
;
;       PARAMETERS:     BX      Bus/device
;                       CH      Function
;                       DX      IO base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFunction  Proc near
    push ds
    push es
    pushad
;    
    mov eax,SIZE uhci_func_sel
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    mov ds:uhc_io_base,dx
    mov ds:uhc_pci_bus_dev,bx
    mov ds:uhc_pci_func,ch
;        
    mov eax,1000h
	AllocateBigLinear
	mov ds:uhc_hw_linear,edx
	mov ecx,eax
	AllocateGdt
	CreateDataSelector16
    mov ds:uhc_hw_sel,bx
    mov es,bx
    xor di,di
    mov eax,1
    mov cx,1024
    rep stosd
;
    GetPhysicalPage
    and ax,0F000h
    mov ds:uhc_hw_phys,eax    
;
    mov eax,800h
    AllocateSmallGlobalMem
    mov ds:uhc_ring_sel,es
    xor di,di
    xor ax,ax
    mov cx,1024
    rep stosw
;    
    mov ax,uhci_data_sel
    mov es,ax
    mov bx,es:UhciCount
    inc es:UhciCount
    add bx,bx
    mov es:[bx].UhciFunc,ds
;
    popad
    pop es
    pop ds
    ret
AddFunction   Endp

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
pci01	DW 8086h, 24D2h
pci02	DW 8086h, 24D4h
pci03	DW 8086h, 24D7h
pci04	DW 8086h, 24DEh
pci05 	DW 0,	  0

InitPciAdapter	Proc near
	mov si,OFFSET PciVendorTab
	mov ds:UhciIrq,-1

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

init_pci_next:
	add si,4
	jmp init_pci_loop

init_pci_found:
	mov cl,PCI_interrupt_line
	ReadPciByte
;	
    mov cl,ds:UhciIrq
    cmp cl,-1
    jne init_pci_irq_write
;    
    IsIrqFree
    jnc init_pci_set_irq
;
    and al,0F0h
    or al,13

init_pci_irq_loop:
    IsIrqFree
    jnc init_pci_set_irq
;
    dec al
    or al,al
    jnz init_pci_irq_loop
;
    jmp init_pci_next

init_pci_set_irq:        
    mov cl,ds:UhciIrq
    cmp cl,-1
    jne init_pci_irq_write
;
    mov ds:UhciIrq,al
	mov di,cs
	mov es,di
	mov di,OFFSET UhciInt	
	RequestPrivateIrqHandler

init_pci_irq_write:
    mov al,ds:UhciIrq
   	mov cl,PCI_interrupt_line
	WritePciByte

init_pci_irq_set_ok:
	mov cl,20h
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	mov bp,dx
	call AddFunction
;	
	mov ax,1

init_pci_next_device:
	mov dx,cs:[si]
	mov cx,cs:[si+2]
	FindPciDevice
	jc init_pci_next
;	
    push ax
	mov cl,20h
	ReadPciDword
	mov dx,ax
	and dx,0FFE0h
	pop ax
	cmp dx,bp
	je init_pci_next
;	
    mov al,ds:UhciIrq
   	mov cl,PCI_interrupt_line
	WritePciByte
;	
	call AddFunction
	inc ax
    jmp init_pci_next_device

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

uhci_name	DB 'UHCI',0

uhci_thread	proc far
    int 3
    mov ax,uhci_data_sel
    mov ds,ax
	call InitPciAdapter
;
    mov cx,ds:UhciCount	
    or cx,cx
    jz uhci_thread_exit
;
    mov bx,OFFSET UhciFunc

uhci_func_loop:
    push ds
    mov ds,[bx]
    call InitFunction
    push cx
;
    mov bx,ds:uhc_pci_bus_dev
    mov ch, ds:uhc_pci_func
    mov cl,PCI_status_reg
    ReadPciWord
;    
    mov cl,0
    call EnablePort
    mov cl,1
    call EnablePort
    pop cx
    pop ds
    add bx,2
    loop uhci_func_loop
;
    int 3    

uhci_thread_exit:
	ret
uhci_thread	endp
	
init_usb	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET uhci_name
	mov si,OFFSET uhci_thread
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
	mov bx,uhci_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov eax,SIZE data
	mov bx,uhci_data_sel
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
