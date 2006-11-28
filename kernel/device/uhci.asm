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

uhc_status       DW ?

uhc_period_qh    DD ?
uhc_intr_qh      DD 8 DUP(?)
uhc_intr_arr     DD 8 DUP(?)

uhc_io_base      DW ?

uhc_pipe_list    DW ?

uhc_pci_bus_dev  DW ?
uhc_pci_func     DB ?

uhci_func_sel    ENDS

uhci_pipe   STRUC

upc_pipe_base   usb_pipe_struc <>
upc_qh          DD ?
upc_prev        DW ?
upc_next        DW ?

uhci_pipe   ENDS

uhci_td STRUC

utd_link    DD ?
utd_control DD ?
utd_host    DD ?
utd_buf     DD ?

utd_va_link DD ?
utd_va_buf  DD ?
utd_phys    DD ?
utd_size    DD ?

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
UhciThread   DW ?
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
;		NAME:			UhciInt
;
;		DESCRIPTION:    UHCI interrupt
;
;       PARAMETERS:     DS      Function selector
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UhciInt	Proc far
    push fs
;    
    mov dx,ds:uhc_io_base
    add dx,UsbStatusReg
    in ax,dx
    or ax,ax
    jz uiDone
;    
    or ds:uhc_status,ax
    out dx,ax
;
    mov ax,flat_sel
    mov es,ax
;    
    mov ax,ds:uhc_pipe_list
    or ax,ax
    jz uiDone
;
    mov di,ax
    mov fs,ax

uiLoop:
    mov ax,fs:usbp_wait_obj
    or ax,ax
    jz uiNext
;    
    mov edx,fs:upc_qh
    or edx,edx
    jz uiNext
;
    test byte ptr es:[edx].uqh_link,1
    jz uiNext
;    
    push es
    mov es,ax
    SignalWait
    pop es
    mov fs:usbp_wait_obj,0

uiNext:
    mov ax,fs:upc_next
    cmp ax,di
    jne uiLoop

uiDone:    
    pop fs
    ret
UhciInt  Endp

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
;		NAME:			InsertPipe
;
;		DESCRIPTION:	Insert pipe into function pipe-list
;
;       PARAMETERS:     DS      Function
;                       FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertPipe  Proc near
	push di
	mov di,ds:uhc_pipe_list
	or di,di
	je ipEmpty
;	
	push ds
	push si
	mov ds,di
	mov si,fs:upc_prev
	mov ds:upc_prev,fs
	mov ds,si
	mov ds:upc_next,fs
	mov fs:upc_next,di
	mov fs:upc_prev,si
	pop si
	pop ds
	pop di
	jmp ipDone
	
ipEmpty:
	mov fs:upc_next,fs
	mov fs:upc_prev,fs
	pop di
	mov ds:uhc_pipe_list,fs

ipDone:
	ret
InsertPipe  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemovePipe
;
;		DESCRIPTION:	Remove pipe from function pipe-list
;
;       PARAMETERS:     DS      Function
;                       FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemovePipe  Proc near
	push si
	push di
;	
    push ds
	mov si,fs:upc_prev
	mov di,fs:upc_next
	mov ds,di
	mov ds:upc_prev,si
	mov ds,si
	mov ds:upc_next,di
	pop ds
;
    mov si,fs
    cmp si,ds:uhc_pipe_list
    jne rpDone
;
    cmp si,di
    je rpEmpty
;
    mov ds:uhc_pipe_list,di
    jmp rpDone    

rpEmpty:
    mov ds:uhc_pipe_list,0    

rpDone:
	pop di
	pop si
    ret
RemovePipe  Endp

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
    dec cx
    and ecx,7FFh    
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
    mov es:[edx].utd_size,0
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
    push bx
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
    mov bl,byte ptr es:[edx].utd_link
    and bl,4
    and cl,0E0h
    or cl,bl
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

ieDone:
    pop edx
    pop ecx
    pop bx
    ret
InsertElem  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InsertQhFirst
;
;		DESCRIPTION:	Insert QH first into horizontal QH
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     QH to insert into
;                       EAX     QH to link
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertQhFirst	PROC near
    push ecx
;
    mov ecx,es:[edx].uqh_va_link
    or ecx,ecx
    jz ifEmpty
;
    mov es:[eax].uqh_va_link,ecx
    mov ecx,es:[ecx].uqh_phys
    mov es:[eax].uqh_link,ecx
;
    mov es:[edx].uqh_va_link,eax
    mov ecx,es:[eax].uqh_phys
    or cl,2
    mov es:[edx].uqh_link,ecx    
    jmp ifDone
    
ifEmpty:
    mov es:[eax].uqh_va_link,0
    mov es:[eax].uqh_link,1
    mov es:[edx].uqh_va_link,eax
    mov ecx,es:[eax].uqh_phys
    or cl,2
    mov es:[edx].uqh_link,ecx

ifDone:
    pop ecx
    ret
InsertQhFirst  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    RemoveQh
;
;		DESCRIPTION:	Remove QH from horizontal QH
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     QH to search in
;                       EAX     QH to delink
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveQh	PROC near
    push ecx
    push edx

rqSearch:
    mov ecx,es:[edx].uqh_va_link
    or ecx,ecx
    jz rqDone
;
    cmp eax,ecx
    je rqRemove
;
    mov edx,ecx
    jmp rqSearch         

rqRemove:
    mov ecx,es:[eax].uqh_va_link
    or ecx,ecx
    jz rqEmpty
;    
    mov es:[edx].uqh_va_link,ecx
    mov ecx,es:[ecx].uqh_phys
    mov es:[edx].uqh_link,ecx
    jmp rqDone

rqEmpty:
    mov es:[edx].uqh_va_link,0
    mov es:[edx].uqh_link,1

rqDone:
    pop edx
    pop ecx
    ret
RemoveQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    FreeVaElem
;
;		DESCRIPTION:	Free all Tds in vertical va-linked list
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeVaElem	PROC near
    push ebx
    push ecx
    push edx
    push esi
;
    mov es:[edx].uqh_elem,1
    xor ebx,ebx
    xchg ebx,es:[edx].uqh_va_elem
    mov edx,ebx

fveLoop:
    or edx,edx
    jz fveDone
;
    mov ebx,edx
    mov esi,es:[ebx].utd_va_link
    mov ecx,es:[edx].utd_size
    mov edx,es:[edx].utd_va_buf
    or edx,edx
    jz fveBufDone
;
    or ecx,ecx
    jz fveBufDone
;
    dec ecx
    and cx,0F000h
    add ecx,1000h    
    FreeLinear

fveBufDone:
    mov edx,ebx
    call FreeBlock32
    mov edx,esi
    jmp fveLoop
            
fveDone:    
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
FreeVaElem  Endp

PAGE
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetQhData
;
;		DESCRIPTION:    Get data from transfer
;
;       PARAMETERS:     EDX     Qh
;                       ES:EDI  Data buffer
;
;       RETURNS:        CX      Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetQhData	PROC near
    push ds
    push eax
    push edx
    push esi
    push edi
;    
    xor cx,cx
    mov ax,flat_sel
    mov ds,ax
    mov edx,[edx].uqh_va_elem

gqdLoop:
    or edx,edx
    jz gqdDone
;
    mov al,byte ptr [edx].utd_host
    cmp al,PID_IN
    jne gqdNext
;    
    mov esi,[edx].utd_va_buf
    or esi,esi
    jz gqdNext
;
    mov ax,word ptr [edx].utd_control
    inc ax
    and ax,7FFh
    add cx,ax
    push cx
    movzx ecx,ax
    shr ecx,2
    rep movs dword ptr es:[edi],[esi]
    mov cx,ax
    and ecx,3
    rep movs byte ptr es:[edi],[esi]
    pop cx

gqdNext:
    mov edx,[edx].utd_va_link
    jmp gqdLoop
            
gqdDone:    
    pop edi
    pop esi
    pop edx
    pop eax
    pop ds
    ret
GetQhData  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateFrameVa
;
;		DESCRIPTION:	Create frame pointer VA
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFrameVa	PROC near
    push es
    push eax
    push cx
    push di
;    
    mov eax,1000h
    AllocateGlobalMem
    mov ds:uhc_ring_sel,es
    xor di,di
    xor eax,eax
    mov cx,1024
    rep stosd
;
    pop di
    pop cx
    pop eax
    pop es    
    ret
CreateFrameVa ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateIntrQueue
;
;		DESCRIPTION:	Create interrupt queue
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntrQueue	PROC near
    push es
    push eax
    push cx
    push edx
    push di
;
    mov ax,ds
    mov es,ax
    mov cx,8
    mov eax,ds:uhc_period_qh
    mov di,OFFSET uhc_intr_qh
    rep stosd    
;
    mov dx,flat_sel
    mov es,dx
    mov edx,es:[eax].uqh_phys
    mov es,ds:uhc_ring_sel
    xor di,di
    mov cx,1024
    rep stosd
;
    mov eax,edx
    or al,2
    mov es,ds:uhc_hw_sel
    xor di,di
    mov cx,1024
    rep stosd
;        
    pop di
    pop edx
    pop cx
    pop eax    
    pop es
    ret
CreateIntrQueue  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreatePeriodQueue
;
;		DESCRIPTION:	Create periodic interrupt queue
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePeriodQueue	PROC near
    push edx
;    
    call AllocateQh
    mov ds:uhc_period_qh,edx
;    
    call CreateFrameVa
    call CreateIntrQueue
;
    pop edx
    ret
CreatePeriodQueue  Endp

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
    push cx
    push edx
    push di
;    
    mov eax,SIZE uhci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
;    
    mov ax,es
    mov fs,ax
    mov dx,flat_sel
    mov es,dx
    call AllocateQh
    mov fs:upc_qh,edx
;
    mov edx,ds:uhc_period_qh
    or edx,edx
    jnz ccLinkPeriod    
;
    call CreatePeriodQueue
    mov edx,ds:uhc_period_qh

ccLinkPeriod:
    mov eax,fs:upc_qh
    call InsertQhFirst
    jmp ccDone

ccInsert:
    int 3

ccDone:
    call InsertPipe
;
    pop di
    pop edx
    pop cx
    pop eax    
    pop es
    ret
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddOutBuffer
;
;		DESCRIPTION:    Allocate output buffer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     QH
;                       CX      Size
;                       ES:EDI  Data
;                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddOutBuffer    Proc near
    push gs
    push es
    pushad
;    
    or cx,cx
    jnz aobHasData
;
    mov ax,flat_sel
    mov es,ax
    push edx
    xor edi,edi
    call AllocateTd
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_OUT
    or es:[edx].utd_control,800000h
    mov eax,edx
    pop edx
    call InsertElem
    jmp aobDone

aobHasData:
    movzx ebp,cx
    push es
    push edi
;    
    dec cx
    and cx,0F000h
    add cx,1000h
    movzx eax,cx
    push edx
    AllocateBigLinear
    mov ecx,eax
    mov edi,edx
    pop edx
    mov ax,flat_sel
    mov es,ax
;
    pop esi
    pop gs
;    
    mov ecx,ebp
    push edi
;    
    push ecx
    shr ecx,2
    rep movs dword ptr es:[edi],gs:[esi]
    pop ecx
    and ecx,3
    rep movs byte ptr es:[edi],gs:[esi]
;    
    pop edi
;
    push dx
    mov ax,bp
    xor dx,dx
    mov cx,fs:usbp_maxlen
    div cx
    mov cx,ax
    mov bx,dx
    pop dx
    or cx,cx
    jz aobLastPart

aobLoop:
    push cx
    mov cx,fs:usbp_maxlen     
    push edx
    call AllocateTd
    or ebp,ebp
    jz aobVaDone
;
    mov es:[edx].utd_size,ebp
    xor ebp,ebp

aobVaDone:    
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_OUT
    or es:[edx].utd_control,800000h
    mov eax,edx
    pop edx
    call InsertElem       
    movzx ecx,fs:usbp_maxlen 
    add edi,ecx
    pop cx
    loop aobLoop

aobLastPart:
    mov cx,bx
    or cx,cx
    jz aobDone
;
    push edx
    call AllocateTd
    or ebp,ebp
    jz aobVaLast
;
    mov es:[edx].utd_size,ebp

aobVaLast:    
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_OUT
    or es:[edx].utd_control,800000h
    mov eax,edx
    pop edx
    call InsertElem

aobDone:
    popad
    pop es
    pop gs    
    ret
AddOutBuffer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddInBuffer
;
;		DESCRIPTION:    Allocate input buffer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     QH
;                       CX      Size
;                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddInBuffer    Proc near
    push gs
    push es
    pushad
;    
    or cx,cx
    jnz aibHasData
;
    mov ax,flat_sel
    mov es,ax
    push edx
    xor edi,edi
    call AllocateTd
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_IN
    or es:[edx].utd_control,800000h
    mov eax,edx
    pop edx
    call InsertElem
    jmp aibDone

aibHasData:
    movzx ebp,cx
    push edx
    dec cx
    and cx,0F000h
    add cx,1000h
    movzx eax,cx
    AllocateBigLinear
    mov ecx,eax
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
    mov ecx,ebp    
    shr ecx,2
    xor eax,eax    
    rep stos dword ptr es:[edi]
    mov ecx,ebp
    and ecx,3
    rep stos byte ptr es:[edi]
    mov edi,edx
    pop edx
;    
    push dx
    mov ax,bp
    xor dx,dx
    mov cx,fs:usbp_maxlen
    div cx
    mov cx,ax
    mov bx,dx
    pop dx
    or cx,cx
    jz aibLastPart

aibLoop:
    push cx
    mov cx,fs:usbp_maxlen     
    push edx
    call AllocateTd
    or ebp,ebp
    jz aibVaDone
;
    mov es:[edx].utd_size,ebp
    xor ebp,ebp

aibVaDone:
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_IN
    or es:[edx].utd_control,800000h
    mov eax,edx
    pop edx
    call InsertElem       
    movzx ecx,fs:usbp_maxlen 
    add edi,ecx
    pop cx
    loop aibLoop

aibLastPart:
    mov cx,bx
    or cx,cx
    jz aibDone
;
    push edx
    call AllocateTd
    or ebp,ebp
    jz aibVaLast
;
    mov es:[edx].utd_size,ebp

aibVaLast:
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_IN
    or es:[edx].utd_control,800000h
    mov eax,edx
    pop edx
    call InsertElem

aibDone:
    popad
    pop es
    pop gs    
    ret
AddInBuffer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddSetup
;
;		DESCRIPTION:    Add setup transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddSetup    Proc far
    push gs
    push es
    pushad
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne asDone
;    
    mov ax,es
    mov gs,ax
    mov esi,edi
;    
    mov eax,1000h
    push ecx
    AllocateBigLinear
    pop ecx
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
;
    movzx ecx,cx
    push ecx
    push ecx
    shr ecx,2
    rep movs dword ptr es:[edi],gs:[esi]
    pop ecx
    and ecx,3
    rep movs byte ptr es:[edi],gs:[esi]
    mov edi,edx
    pop ecx
;
    mov fs:usbp_seq,0
    call AllocateTd
    mov es:[edx].utd_size,ecx
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_SETUP
    or es:[edx].utd_control,800000h
    mov eax,edx
    mov edx,fs:upc_qh
    call InsertElem    

asDone:
    popad
    pop es
    pop gs
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
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddOut    Proc far
    push eax
    push edx
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne aoDone
;   
    mov edx,fs:upc_qh 
    call AddOutBuffer

aoDone:
    pop edx
    pop eax    
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
;                       CX      Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIn    Proc far
    push eax
    push edx
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne aiDone
;   
    mov edx,fs:upc_qh 
    call AddInBuffer

aiDone:
    pop edx
    pop eax    
    ret
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddStatusOut
;
;		DESCRIPTION:    Add status OUT transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusOut    Proc far
    push eax
    push ecx
    push edx
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne asoDone
;
    mov fs:usbp_seq,1   
    mov edx,fs:upc_qh 
    xor ecx,ecx
    call AddOutBuffer

asoDone:
    pop edx
    pop ecx
    pop eax    
    ret
AddStatusOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddStatusIn
;
;		DESCRIPTION:    Add status IN transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusIn    Proc far
    push eax
    push ecx
    push edx
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne asiDone
;
    mov fs:usbp_seq,1
    mov edx,fs:upc_qh
    xor ecx,ecx
    call AddInBuffer

asiDone:
    pop edx
    pop ecx
    pop eax    
    ret
AddStatusIn    Endp

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
    push es
    push eax
    push edx
;    
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je itControl
;
    int 3
    jmp itDone

itControl:
    mov ax,flat_sel
    mov es,ax    
    mov edx,fs:upc_qh
;
    mov eax,es:[edx].uqh_va_elem    
    or es:[eax].utd_control,1000000h
    mov eax,es:[eax].utd_phys
    mov es:[edx].uqh_elem,eax
    jmp itDone

itControlAdd:
    int 3
    jmp itDone

itDone:
    pop edx 
    pop eax
    pop es
    ret
IssueTransfer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    WaitForCompletion
;
;		DESCRIPTION:    Wait for transfer to complete
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion   Proc far
    push es
    push eax
    push edx
;
    mov ax,flat_sel
    mov es,ax
;    
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je wfcControl
;
    int 3
    stc
    jmp wfcDone    

wfcControl:
    mov edx,fs:upc_qh
    test es:[edx].uqh_elem,1
    clc
    jnz wfcDone
;
    mov eax,es:[edx].uqh_va_elem
    test es:[eax].utd_control,400000h    
    jnz wfccRecoverError
;
    mov ax,1
    WaitMilliSec
    jmp wfcControl    

wfccRecoverError:
    mov es:[edx].uqh_elem,1
    stc

wfcDone:
    pop edx
    pop eax
    pop es
    ret
WaitForCompletion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    IsPipeSignalled
;
;		DESCRIPTION:    IsPipeSignalled
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        CY      Pipe has data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsPipeSignalled   Proc far
    push es
    push edx
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov edx,fs:upc_qh
    or edx,edx
    jz ipsSig
;
    test byte ptr es:[edx].uqh_link,1
    jz ipsNoSig

ipsSig:
    stc
    jmp ipsDone

ipsNoSig:
    clc

ipsDone:
    pop edx
    pop es
    ret
IsPipeSignalled   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    EmptyQueue
;
;		DESCRIPTION:    Empty queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmptyQueue   Proc far
    push es
    push ax
    push edx
;        
    mov ax,flat_sel
    mov es,ax
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je eqControl
;
    int 3
    jmp eqDone    

eqControl:
    mov edx,fs:upc_qh
    call FreeVaElem

eqDone:
    pop edx
    pop ax
    pop es
    ret
EmptyQueue   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetData
;
;		DESCRIPTION:    Get data
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       ES:EDI  Buffer
;
;       RETURNS:        CX      Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetData   Proc far
    push ax
    push edx
;        
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je gdControl
;
    int 3
    jmp gdDone    

gdControl:
    mov edx,fs:upc_qh
    call GetQhData

gdDone:
    pop edx
    pop ax
    ret
GetData   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    ClosePipe
;
;		DESCRIPTION:    Close pipe
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePipe   Proc far
    push es
    push eax
    push edx
;        
    call RemovePipe
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je dpControl
;
    int 3
    jmp dpDone    

dpControl:
    mov ax,flat_sel
    mov es,ax
    mov edx,ds:uhc_period_qh
    mov eax,fs:upc_qh
    call RemoveQh
    mov edx,eax
    call FreeBlock32
    
dpDone:
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
;
    pop edx
    pop eax
    pop es
    ret
ClosePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    UpdatePort
;
;		DESCRIPTION:    Update root-hub port status
;
;       PARAMETERS:     DS      Function selector
;                       CL      Port # (0,1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push ax
    push bx
    push cx
    push dx
    push si
;    
    movzx si,cl
    add si,si
;    
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,si
    in ax,dx
    test al,1
    stc
    jz upDetach
    
upAttach:
    mov bx,ds:[si].usb_port_sel_arr
    or bx,bx
    jnz upDone
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
    jmp upDone

epNotify:
    pop cx
    mov al,cl
    NotifyUsbAttach
    jmp upDone

upDetach:
    mov bx,ds:[si].usb_port_sel_arr
    or bx,bx
    jz upDone
;    
    mov al,cl
    NotifyUsbDetach
                    
upDone:    
    pop si    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
UpdatePort   Endp

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
ut00 DW OFFSET CreateControl,   	uhci_code_sel
ut01 DW OFFSET AddSetup,    	    uhci_code_sel
ut02 DW OFFSET AddOut,      	    uhci_code_sel
ut03 DW OFFSET AddIn,        	    uhci_code_sel
ut04 DW OFFSET AddStatusOut,        uhci_code_sel
ut05 DW OFFSET AddStatusIn,        	uhci_code_sel
ut06 DW OFFSET IssueTransfer,       uhci_code_sel
ut07 DW OFFSET EmptyQueue,          uhci_code_sel
ut08 DW OFFSET IsPipeSignalled,     uhci_code_sel
ut09 DW OFFSET GetData,             uhci_code_sel
ut10 DW OFFSET ClosePipe,           uhci_code_sel
ut11 DW OFFSET WaitForCompletion,   uhci_code_sel

InitFunction    Proc near
    pushad
;
    mov bx,ds:uhc_pci_bus_dev
    mov ch,ds:uhc_pci_func
	mov cl,PCI_interrupt_line
	ReadPciByte
;	
	mov di,cs
	mov es,di
	mov di,OFFSET UhciInt	
	RequestSharedIrqHandler
;
    mov si,OFFSET uhci_tab
    xor di,di
    mov cx,12

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
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    in ax,dx
    or al,4
    out dx,ax
;
    mov dx,ds:uhc_io_base
    add dx,PortscReg2
    in ax,dx
    or al,4
    out dx,ax
;
    popad
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
    mov ds:uhc_pipe_list,0
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
    mov ax,ds
    mov es,ax
    mov di,OFFSET uhc_intr_qh
    mov cx,8
    xor eax,eax
    rep stosd
;
    mov di,OFFSET uhc_intr_arr
    mov cx,8
    xor eax,eax
    rep stosd        
;
    GetPhysicalPage
    and ax,0F000h
    mov ds:uhc_hw_phys,eax    
;    
    mov ds:uhc_status,0
    mov ds:uhc_ring_sel,0
    mov ds:uhc_period_qh,0
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
;		NAME:		    PollFunction
;
;		DESCRIPTION:    Poll UHCI function
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollFunction  Proc near
    pusha
;
    mov ax,ds:uhc_status
    or ax,ax
    jz pfStatusOk
;
    int 3
    mov ds:uhc_status,0

pfStatusOk:
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    in ax,dx
    mov bx,ax
    and bx,0Ah
    jz pfNotReg1
;    
    out dx,ax
    mov cl,0
    call UpdatePort

pfNotReg1:
    mov dx,ds:uhc_io_base
    add dx,PortscReg2
    in ax,dx
    mov bx,ax
    and bx,0Ah
    jz pfNotReg2
;    
    out dx,ax
    mov cl,1
    call UpdatePort

pfNotReg2:
    popa
    ret
PollFunction    Endp


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
	call AddFunction
	inc ax
    jmp init_pci_next_device

init_pci_done:
	ret
InitPciAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			port_timer
;
;		DESCRIPTION:    Port timer
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


port_timer  Proc far
    push edx
    push eax
;    
    xor si,si
    mov ax,uhci_data_sel
    mov ds,ax
;
    mov cx,ds:UhciCount	
    mov bx,OFFSET UhciFunc

timer_func_loop:
    push ds
    mov ds,[bx]
;    
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    in ax,dx
    and ax,0Ah
    jz timer_not_reg1
;    
    inc si

timer_not_reg1:
    add dx,2
    in ax,dx
    and ax,0Ah
    jz timer_not_reg2
;    
    inc si

timer_not_reg2:
    pop ds
    add bx,2
    loop timer_func_loop
;
    or si,si
    jz timer_no_action
;
    mov bx,ds:UhciThread
    Signal

timer_no_action:    
    pop eax   
    pop edx
;    
	add eax,119300
	adc edx,0
	mov bx,cs
	mov es,bx
	mov bx,cs
	mov di,OFFSET port_timer
	StartTimer
    ret
port_timer  Endp

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
    GetThread
    mov ds:UhciThread,ax
;    
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
    pop ds
    add bx,2
    loop uhci_func_loop
;
	GetSystemTime
	add eax,119300
	adc edx,0
	mov bx,cs
	mov es,bx
	mov bx,cs
	mov di,OFFSET port_timer
	StartTimer

uhci_handle_loop:
    WaitForSignal    
;    
    mov cx,ds:UhciCount	
    mov bx,OFFSET UhciFunc

uhci_poll_loop:
    push ds
    mov ds,[bx]
    call PollFunction
    pop ds
    add bx,2
    loop uhci_poll_loop
;
    jmp uhci_handle_loop    

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
