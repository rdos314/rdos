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

usb_dev_base     usb_dev_struc <>

uhc_hw_phys      DD ?
uhc_hw_linear    DD ?
uhc_hw_sel       DW ?
uhc_ring_sel     DW ?

uhc_control_qh   DD ?

uhc_io_base      DW ?
uhc_pci_bus_dev  DW ?
uhc_pci_func     DB ?

uhci_func_sel    ENDS

uhci_control_pipe   STRUC

upc_pipe_base    usb_pipe_struc <>

uhci_control_pipe   ENDS

uhci_td STRUC

utd_link    DD ?
utd_control DD ?
utd_host    DD ?
utd_buf     DD ?

utd_va_link DD ?
utd_va_buf  DD ?
utd_phys    DD ?

uhci_td ENDS

uhci_qh STRUC

uqh_link    DD ?
uqh_elem    DD ?

uqh_va_link DD ?
uqh_va_elem DD ?
uqh_phys    DD ?

uhci_qh ENDS

data    STRUC

UhciList32   DD ?
UhciSection  section_typ <>
UhciIrq      DB ?
UhciCount    DW ?
UhciFunc     DW 16 DUP (?)

data    ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateBlock32
;
;		DESCRIPTION:	Allocate 32-byte block with page-alignment
;
;       PARAMETERS:     ES      Flat sel
;
;		RETURNS:		EDX		Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlock32	PROC near
    push ds
    push eax
;    
    mov ax,uhci_data_sel
    mov ds,ax
    EnterSection ds:UhciSection
    mov edx,ds:UhciList32
	or edx,edx
	jnz allocate_block32_done
;
    push ecx    
	mov eax,1000h
	AllocateBigLinear
	mov ecx,32
	mov ds:UhciList32,edx
	
allocate_block32_loop:
	mov eax,edx
	add eax,ecx
	mov es:[edx],eax
	mov edx,eax
	test dx,0FFFh
	jnz allocate_block32_loop
;
	sub edx,ecx
	mov dword ptr es:[edx],0
	mov edx,ds:UhciList32
	pop ecx

allocate_block32_done:
	mov eax,es:[edx]
	mov ds:UhciList32,eax
    LeaveSection ds:UhciSection
;
	pop eax
	pop ds
	ret
AllocateBlock32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeBlock32
;
;		DESCRIPTION:	Free 32-byte block
;
;       PARAMETERS:     ES      Flat sel
;
;		PARAMETERS:		EDX		Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBlock32	PROC near
    push ds
	push eax
;
    mov ax,uhci_data_sel
    mov ds,ax
;    
    EnterSection ds:UhciSection
	mov eax,ds:UhciList32
	mov es:[edx],eax
	mov ds:UhciList32,edx
    LeaveSection ds:UhciSection
;	
	pop eax
	pop ds
	ret
FreeBlock32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AllocateQh
;
;		DESCRIPTION:	Allocate & initialize a queue header
;
;       PARAMETERS:     ES      Flat sel
;
;		PARAMETERS:		EDX		QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQh	PROC near
    push eax
    push cx
;    
    call AllocateBlock32
    mov es:[edx].uqh_link,1
    mov es:[edx].uqh_va_link,0
    mov es:[edx].uqh_elem,1
    mov es:[edx].uqh_va_elem,0
    GetPhysicalPage
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    mov es:[edx].uqh_phys,eax
;
    pop cx   
    pop eax
    ret
AllocateQh  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AllocateTd
;
;		DESCRIPTION:	Allocate & initialize a TD block
;
;       PARAMETERS:     ES      Flat sel
;                       FS      Pipe
;                       EDI     Data buffer
;                       CX      Size of data
;
;		PARAMETERS:		EDX		TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTd	PROC near
    push eax
    push ecx
;    
    call AllocateBlock32
    mov es:[edx].utd_link,1
    mov es:[edx].utd_va_link,0
    mov es:[edx].utd_control, 38000000h
;
    movzx ecx,cx
    shl ecx,21
    movzx eax,fs:usbp_endpoint
    shl eax,15
    or ecx,eax
    or ch,fs:usbp_address
    xor cl,cl
;    
    mov al,fs:usbp_seq
    or al,al
    jz atIncSeq
;
    or ecx,80000h 
    xor al,al
    jmp atSaveSeq

atIncSeq:
    inc al

atSaveSeq:    
    mov fs:usbp_seq,al   
    mov es:[edx].utd_host,ecx
;        
    GetPhysicalPage
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    mov es:[edx].utd_phys,eax
;
    mov es:[edx].utd_va_buf,edi
    xor eax,eax
    or edi,edi
    jz atSaveBuf
;    
    push edx
    mov edx,edi
    GetPhysicalPage
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop edx

atSaveBuf:
    mov es:[edx].utd_buf,eax
;    
    pop ecx   
    pop eax
    ret
AllocateTd  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InsertElem
;
;		DESCRIPTION:	Insert TD into vertical QH
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     QH
;                       EAX     TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertElem	PROC near
    push ecx
    push edx
;
    mov ecx,es:[edx].uqh_va_elem
    or ecx,ecx
    jz ieEmpty

ieTraverse:
    mov edx,ecx
    mov ecx,es:[edx].utd_va_link
    or ecx,ecx
    jnz ieTraverse
;
    mov cl,byte ptr es:[eax].utd_link
    and cl,0E4h
    or cl,1
    mov byte ptr es:[eax].utd_link,cl
;
    mov ecx,es:[eax].utd_phys
    mov cl,byte ptr es:[edx].utd_link
    and cl,0E4h
    mov es:[edx].utd_link,ecx
    mov es:[edx].utd_va_link,eax
    jmp ieDone
    
ieEmpty:
    mov cl,byte ptr es:[eax].utd_link
    and cl,0E4h
    or cl,1
    mov byte ptr es:[eax].utd_link,cl
    mov es:[eax].utd_va_link,0
;    
    mov es:[edx].uqh_va_elem,eax
    mov ecx,es:[eax].utd_phys
    mov es:[edx].uqh_elem,ecx

ieDone:
    pop edx
    pop ecx
    ret
InsertElem  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetControlQueue
;
;		DESCRIPTION:	Create control-queue if not already done, and return QH
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;
;       RETURNS:        EDX     Control QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetControlQueue	PROC near
    mov edx,ds:uhc_control_qh
    or edx,edx
    jnz gcqOk
;
    call AllocateQh
    mov ds:uhc_control_qh,edx

gcqOk:
    ret
GetControlQueue  Endp

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
;		NAME:		    CreateControl
;
;		DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Function selector
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    push es
    push eax
;    
    mov eax,SIZE uhci_control_pipe
    AllocateSmallGlobalMem
    mov ax,es
    mov fs,ax
;
    pop eax    
    pop es
    ret
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AllocateBuf
;
;		DESCRIPTION:    Allocate transfer buffer
;
;       PARAMETERS:     CX     Size
;                       ES:EDI Data
;                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBuf    Proc far
    push eax
    push ecx
    push edx
;    
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
;
    pop edx
    pop ecx
    pop eax
    ret
AllocateBuf    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    StartQueue
;
;		DESCRIPTION:    Queue a write transfer req
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        EDX     Queue handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartQueue    Proc far
    push es
    mov dx,flat_sel
    mov es,dx
    call AllocateQh
    pop es
    ret
StartQueue    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddSetup
;
;		DESCRIPTION:    Add setup transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     Queue handle
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddSetup    Proc far
    push eax
;
    int 3
    push edx
    mov fs:usbp_seq,0
    call AllocateTd
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_SETUP
    or es:[edx].utd_control,800000h
    mov eax,edx
    pop edx
    call InsertElem    
;
    pop eax    
    ret
AddSetup    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddOut
;
;		DESCRIPTION:    Add out transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     Queue handle
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddOut    Proc far
    int 3
    ret
AddOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddIn
;
;		DESCRIPTION:    Add in transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     Queue handle
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIn    Proc far
    int 3
    ret
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddStatus
;
;		DESCRIPTION:    Add status transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     Queue handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatus    Proc far
    push es
    push eax
    push cx
    push edi
;
    int 3
    mov cx,flat_sel
    mov es,cx
    xor cx,cx
    xor edi,edi
    push edx
    mov fs:usbp_seq,1
    call AllocateTd
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_IN
    or es:[edx].utd_control,1800000h
    mov eax,edx
    pop edx
    call InsertElem    
;
    pop edi
    pop cx
    pop eax    
    pop es
    ret
AddStatus    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    IssueTransfer
;
;		DESCRIPTION:    Issue transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     Queue handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueTransfer    Proc far
    int 3
    ret
IssueTransfer    Endp

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
    push cx
    mov cx,10

 epLoop:
    in ax,dx
    test ax,4
    clc
    jnz epNotify
;
    or ax,4
    out dx,ax
    loop epLoop
;
    pop cx
    stc
    jmp epDone

epNotify:
    pop cx
    mov al,cl
    NotifyUsbAttach
                    
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

uhci_tab:
ut00 DW OFFSET CreateControl,	uhci_code_sel
ut01 DW OFFSET AllocateBuf,    	uhci_code_sel
ut02 DW OFFSET StartQueue,    	uhci_code_sel
ut03 DW OFFSET AddSetup,    	uhci_code_sel
ut04 DW OFFSET AddOut,      	uhci_code_sel
ut05 DW OFFSET AddIn,        	uhci_code_sel
ut06 DW OFFSET AddStatus,       uhci_code_sel
ut07 DW OFFSET IssueTransfer,   uhci_code_sel

InitFunction    Proc near
    push eax
    push cx
    push dx
    push si
    push di
;
    mov si,OFFSET uhci_tab
    xor di,di
    mov cx,8

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbDevice
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
    pop di
    pop si
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
    mov eax,1000h
    AllocateGlobalMem
    mov ds:uhc_ring_sel,es
    xor di,di
    xor ax,ax
    mov cx,1024
    rep stosd
;    
    mov ds:uhc_control_qh,0
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
    push bx
    mov bx,ds:uhc_pci_bus_dev
    mov ch, ds:uhc_pci_func
    mov cl,PCI_status_reg
    ReadPciWord
    pop bx
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
