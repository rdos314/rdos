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
; EHCI.ASM
; EHCI-based USB host controller driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME ehci

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\pci.inc
INCLUDE ..\os\usb.inc

MAX_USB_DEVICES = 16

; ehc_flags

EHC_PORT_IND        = 1
EHC_COMPANION       = 2
EHC_PORT_POWER      = 4


hccap   STRUC

hcp_CAPLEN      DB ?
hcp_resv        DB ?
hcp_HCIVERSION  DW ?
hcp_HCSPARAMS   DW ?,?
hcp_HCCPARAMS   DD ?
hcp_ROUTE       DB ?

hccap   ENDS

hc_reg  STRUC

HcCommand           DD ?
HcStatus            DD ?
HcInterruptEnable   DD ?
HcFrameIndex        DD ?
HcSegmentSelector   DD ?
HcPeriodicListBase  DD ?
HcAsyncList         DD ?
HcResv              DD 9 DUP(?)
HcConfig            DD ?
HcPortSc            DD ?

hc_reg  ENDS

ehci_func_sel   STRUC

usb_dev_base    usb_dev_struc <>

ehc_reg_sel         DW ?
ehc_map_sel         DW ?
ehc_map_linear      DD ?
ehc_linear          DD ?
ehc_phys            DD ?

ehc_op_offs         DB ?
ehc_flags           DW ?
ehc_ports           DB ?
ehc_debug_port      DB ?
ehc_comp_ports      DB ?

ehc_section         section_typ <>

ehc_pipe_list       DW ?
ehc_async_head_va   DD ?

ehci_func_sel    ENDS

ehci_pipe   STRUC

esp_pipe_base   usb_pipe_struc <>
esp_qh          DD ?
esp_prev        DW ?
esp_next        DW ?

esp_pending     DD ?

ehci_pipe   ENDS

; this structure should be kept less than 64 bytes long!

qtd_struc       STRUC

; HC part

qtd_next        DD ?
qtd_alt         DD ?
qtd_status      DB ?
qtd_flags       DB ?
qtd_size        DW ?
qtd_page0       DD ?
qtd_page1       DD ?
qtd_page2       DD ?
qtd_page3       DD ?
qtd_page4       DD ?

; driver part

qtd_my_phys     DD ?
qtd_my_va       DD ?
qtd_next_va     DD ?
qtd_alt_va      DD ?
qtd_buffer_va   DD ?
qtd_buffer_size DW ?

qtd_struc       ENDS

; this structure should be kept less than 64 bytes long!

qh_struc       STRUC

; HC part

qh_link         DD ?
qh_adress       DB ?
qh_endpoint     DB ?
qh_max_packet   DW ?
qh_s_mask       DB ?
qh_c_mask       DB ?
qh_hub_port     DW ?
qh_current_qtd  DD ?
qh_next_qtd     DD ?
qh_alt_qtd      DD ?
qh_status       DB ?
qh_flags        DB ?
qh_size         DW ?
qh_page0        DD ?
qh_page1        DD ?
qh_page2        DD ?
qh_page3        DD ?
qh_page4        DD ?

; driver part

qh_my_va        DD ?
qh_link_va      DD ?
qh_next_va      DD ?
qh_alt_va       DD ?

qh_struc    ENDS

data    STRUC

EhciList64      DD ?
EhciSection     section_typ <>
EhciThread      DW ?
EhciFuncCount   DW ?
EhciFuncArr     DW MAX_USB_DEVICES (?)

data    ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateBlock64
;
;		DESCRIPTION:	Allocate 64-byte block with page-alignment
;
;       PARAMETERS:     ES      Flat sel
;
;		RETURNS:		EDX		Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlock64	PROC near
    push ds
    push eax
;    
    mov ax,ehci_data_sel
    mov ds,ax
    EnterSection ds:EhciSection
    mov edx,ds:EhciList64
	or edx,edx
	jnz allocate_block64_done
;
    push ecx    
	mov eax,1000h
	AllocateBigLinear
	mov ecx,64
	mov ds:EhciList64,edx
	
allocate_block64_loop:
	mov eax,edx
	add eax,ecx
	mov es:[edx],eax
	mov edx,eax
	test dx,0FFFh
	jnz allocate_block64_loop
;
	sub edx,ecx
	mov dword ptr es:[edx],0
	mov edx,ds:EhciList64
	pop ecx

allocate_block64_done:
	mov eax,es:[edx]
	mov ds:EhciList64,eax
    LeaveSection ds:EhciSection
;
	pop eax
	pop ds
	ret
AllocateBlock64	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeBlock64
;
;		DESCRIPTION:	Free 64-byte block
;
;       PARAMETERS:     ES      Flat sel
;
;		PARAMETERS:		EDX		Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBlock64	PROC near
    push ds
	push eax
;
    mov ax,ehci_data_sel
    mov ds,ax
;    
    EnterSection ds:EhciSection
	mov eax,ds:EhciList64
	mov es:[edx],eax
	mov ds:EhciList64,edx
    LeaveSection ds:EhciSection
;	
	pop eax
	pop ds
	ret
FreeBlock64	ENDP

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
	mov di,ds:ehc_pipe_list
	or di,di
	je ipEmpty
;	
	push ds
	push si
	mov ds,di
	cli
	mov si,ds:esp_prev
	mov ds:esp_prev,fs
	mov ds,si
	mov ds:esp_next,fs
	mov fs:esp_next,di
	mov fs:esp_prev,si
	sti
	pop si
	pop ds
	pop di
	jmp ipDone
	
ipEmpty:
	mov fs:esp_next,fs
	mov fs:esp_prev,fs
	pop di
	mov ds:ehc_pipe_list,fs

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
	mov si,fs:esp_prev
	mov di,fs:esp_next
	mov ds,di
	mov ds:esp_prev,si
	mov ds,si
	mov ds:esp_next,di
	pop ds
;
    mov si,fs
    cmp si,ds:ehc_pipe_list
    jne rpDone
;
    cmp si,di
    je rpEmpty
;
    mov ds:ehc_pipe_list,di
    jmp rpDone    

rpEmpty:
    mov ds:ehc_pipe_list,0    

rpDone:
	pop di
	pop si
    ret
RemovePipe  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InitQh
;
;		DESCRIPTION:    Initialize an already allocated qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       EDX     QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitQh	PROC near
    mov es:[edx].qh_link,1
    mov es:[edx].qh_adress,0
    mov es:[edx].qh_endpoint,0
    mov es:[edx].qh_max_packet,0
    mov es:[edx].qh_s_mask,0
    mov es:[edx].qh_c_mask,0
    mov es:[edx].qh_hub_port,0C000h
    mov es:[edx].qh_current_qtd,0
    mov es:[edx].qh_next_qtd,1
    mov es:[edx].qh_alt_qtd,1
    mov es:[edx].qh_status,0
    mov es:[edx].qh_flags,0
    mov es:[edx].qh_size,0
    mov es:[edx].qh_page0,0    
    mov es:[edx].qh_page1,0    
    mov es:[edx].qh_page2,0    
    mov es:[edx].qh_page3,0    
    mov es:[edx].qh_page4,0
    mov es:[edx].qh_my_va,edx
    mov es:[edx].qh_link_va,0
    mov es:[edx].qh_next_va,0
    mov es:[edx].qh_alt_va,0    
    ret
InitQh  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InitQtd
;
;		DESCRIPTION:    Initialize an already allocated qTD
;
;       PARAMETERS:     ES      Flat sel
;                       FS      Pipe sel
;                       EAX     qTD physical
;                       EDX     qTD linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitQtd	PROC near
    mov es:[edx].qtd_next,1
    mov es:[edx].qtd_alt,1
    mov es:[edx].qtd_status,0
    mov es:[edx].qtd_flags,0Fh
    mov es:[edx].qtd_size,0
    mov es:[edx].qtd_page0,0
    mov es:[edx].qtd_page1,0
    mov es:[edx].qtd_page2,0
    mov es:[edx].qtd_page3,0
    mov es:[edx].qtd_page4,0
    mov es:[edx].qtd_my_va,edx
    mov es:[edx].qtd_my_phys,eax
    mov es:[edx].qtd_next_va,0
    mov es:[edx].qtd_alt_va,0
    mov es:[edx].qtd_buffer_va,0
    mov es:[edx].qtd_buffer_size,0
    ret
InitQtd  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AllocateQh
;
;		DESCRIPTION:	Allocate & initialize an qh descriptor
;
;       PARAMETERS:     DS      Function selector
;                       ES      Flat sel
;
;		RETURNS:		EDX		Linear address of qh
;                       EAX     Physical address of qh
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQh	PROC near
    push cx
    call AllocateBlock64
    call InitQh
;
    GetPhysicalPage
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
    ret
AllocateQh  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AllocateQtd
;
;		DESCRIPTION:	Allocate & initialize qTD
;
;       PARAMETERS:     ES      Flat sel
;                       FS      Pipe sel
;
;		RETURNS:		EDX		Linear address of qTD
;                       EAX     Physical address of qTD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQtd	PROC near
    push cx
    call AllocateBlock64
;
    GetPhysicalPage
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
;    
    call InitQtd
    ret
AllocateQtd  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddControlQh
;
;		DESCRIPTION:	Add control qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;
;       RETURNS:        EDX     Linear address of qh added
;                       EAX     Physical address of qh added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddControlQh	PROC near
    push gs
    push ebx
;
    EnterSection ds:ehc_section
    call AllocateQh
    mov ebx,eax
;    
    mov al,fs:usbp_address
    mov es:[edx].qh_adress,al
;
    mov al,fs:usbp_endpoint
    or al,20h
    mov es:[edx].qh_endpoint,al
;        
    mov ax,3008h
    mov es:[edx].qh_max_packet,ax
;
    mov eax,ds:ehc_async_head_va
    or eax,eax
    jnz acqInsert
;
    or es:[edx].qh_endpoint,80h
    mov ds:ehc_async_head_va,edx
    mov eax,ebx
    or al,2
    mov es:[edx].qh_link,eax
    mov es:[edx].qh_link_va,edx
;
    mov gs,ds:ehc_reg_sel
    mov gs:HcAsyncList,ebx
;
    mov eax,gs:HcCommand
    or al,20h
    mov gs:HcCommand,eax
    jmp acqDone

acqInsert:
    push esi
;    
    mov esi,eax
    mov eax,es:[esi].qh_link
    mov es:[edx].qh_link,eax
    mov eax,es:[esi].qh_link_va
    mov es:[edx].qh_link_va,eax
    mov eax,esi

acqFindEnd:
    cmp esi,es:[eax].qh_link_va
    je acqEndFound
;    
    mov eax,es:[eax].qh_link_va
    jmp acqFindEnd

acqEndFound:
    mov esi,ebx
    or si,2
    mov es:[eax].qh_link,esi
    mov es:[eax].qh_link_va,edx
;
    pop esi        

acqDone:
    mov eax,ebx
    LeaveSection ds:ehc_section
;    
    pop ebx
    pop gs
    ret
AddControlQh  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AllocateFillQtd
;
;		DESCRIPTION:    Allocate and fill qtd buffer pointers from buffer
;
;       PARAMETERS:     DS      Function selector
;                       ES:EDI  Data buffer
;                       CX      Size of data
;
;       RETURNS:        EDX     Allocated & filled qTD 
;                       EAX     qTD physical
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateFillQtd	PROC near
    push es
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
;   
    push ecx 
    mov bx,es
    GetSelectorBaseSize
    add edx,edi
    mov cx,flat_sel
    mov es,cx
    pop ecx
;
    push edx
    call AllocateQtd
    mov esi,edx
    mov edi,eax
    pop edx
;
    mov es:[esi].qtd_size,cx
    or cx,cx
    jz afqDone
;
    mov al,es:[edx]
    GetPhysicalPage
    and ax,0F000h
    mov bx,dx
    and bx,0FFFh
    or ax,bx
    mov es:[esi].qtd_page0,eax
;
    mov ax,1000h
    sub ax,bx
    sub cx,ax
    jc afqDone
;
    movzx ebx,ax
    add edx,ebx
    mov ebx,OFFSET qtd_page1

afqLoop:    
    mov al,es:[edx]
    GetPhysicalPage
    and ax,0F000h
    mov es:[esi+ebx],eax
    sub cx,1000h
    jc afqDone
;
    add edx,1000h
    add ebx,4
    jmp afqLoop    

afqDone:    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax   
    pop es
    ret
AllocateFillQtd   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InsertQtd
;
;		DESCRIPTION:    Insert qTD into pipe schedule
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       AL      PID code
;                       EDX     qTD linear 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertQtd	PROC near
    push es
    push ax
    push ebx
;
    mov bx,flat_sel
    mov es,bx
;        
    and al,3
    or al,0Ch
    mov es:[edx].qtd_flags,cl
;
    mov ebx,fs:esp_pending
    mov fs:esp_pending,edx
    or ebx,ebx
    jz iqEmpty
;    
    mov es:[edx].qtd_next_va,ebx
    mov ebx,es:[ebx].qtd_my_phys
    mov es:[edx].qtd_next,ebx
    jmp iqLinked

iqEmpty:
    mov es:[edx].qtd_next_va,0
    mov es:[edx].qtd_next,1

iqLinked:
    pop ebx
    pop ax
    pop es
    ret
InsertQtd   Endp

PAGE

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
    pushad
;    
    mov eax,SIZE ehci_pipe
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
    call AddControlQh
    mov fs:esp_qh,edx
    call InsertPipe
;
    popad
    pop es
    ret
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateBulk
;
;		DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     DS      Function selector
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    int 3
    ret
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateIntr
;
;		DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     DS      Function selector
;                       AL      Interval
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    int 3
    ret
CreateIntr  Endp

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
    int 3
    push eax
    push edx
;    
    call AllocateFillQtd
;
    mov al,2    
    call InsertQtd
;
    pop edx
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
;		NAME:		    AddStatusOut
;
;		DESCRIPTION:    Add status OUT transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusOut    Proc far
    int 3
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
    int 3
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
    int 3
    ret
IssueTransfer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    IsTransferDone
;
;		DESCRIPTION:    Check if transfer is done
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        NC      Transfer is done
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsTransferDone   Proc far
    int 3
    stc
    ret
IsTransferDone   Endp

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
    int 3
    stc
    ret
WaitForCompletion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    EndTransfer
;
;		DESCRIPTION:    End transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndTransfer   Proc far
    int 3
    ret
EndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    WasTransferOk
;
;		DESCRIPTION:    Was transfer ok
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        NC      Transfer ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WasTransferOk   Proc far
    int 3
    stc
    ret
WasTransferOk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetDataSize
;
;		DESCRIPTION:    Get data size
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        CX      Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDataSize   Proc far
    int 3
    ret
GetDataSize   Endp

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
    int 3
    ret
ClosePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    ChangeAddress
;
;		DESCRIPTION:    Change address for pipe
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    int 3
    ret
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    IsConnected
;
;		DESCRIPTION:    Check if pipe is connected
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsConnected   Proc far
    int 3
    stc
    ret
IsConnected Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    UpdatePort
;
;		DESCRIPTION:    Update root-hub port status
;
;       PARAMETERS:     DS      Function selector
;                       CL      Port # (0..EHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push es
    push ax
    push bx
    push cx
    push dx
    push si
    push di
;    
    movzx si,cl
    shl si,2
    movzx di,cl
    add di,di
;    
    mov es,ds:ehc_reg_sel
    mov eax,es:[si].HcPortSc
    test al,2
    jz upDone
;
    mov es:[si].HcPortSc,eax        ; reset change bit!    
; 
    test al,1
    jz upDetach
    
upAttach:
    mov bx,ds:[di].usb_port_sel_arr
    or bx,bx
    jnz upDone
;
    mov ax,50
    WaitMilliSec
;
    mov eax,es:[si].HcPortSc
    test al,1
    jz upDone
;
    and ax,0C00h
    cmp ax,400h
    jne upDoReset
;
    test ds:ehc_flags,EHC_COMPANION
    jz upDone
;
    cmp cl,ds:ehc_comp_ports
    jae upDone
;    
    mov eax,es:[si].HcPortSc
    or ax,2000h
    mov es:[si].HcPortSc,eax
    jmp upDone
    
upDoReset:    
    mov eax,es:[si].HcPortSc
    and al,NOT 4
    or ax,100h
    mov es:[si].HcPortSc,eax
;
    mov ax,25
    WaitMilliSec
;
    mov eax,es:[si].HcPortSc
    and ax,NOT 100h
    mov es:[si].HcPortSc,eax
    
upResetLoop:
    mov eax,es:[si].HcPortSc
    test al,1
    jz upDone
;    
    test ax,100h
    jz upResetDone
;
    mov ax,5
    WaitMilliSec
    jmp upResetLoop

upResetDone:
    mov ax,2
    WaitMilliSec
;
    mov eax,es:[si].HcPortSc
    test al,4
    jnz upNotify
;    
    test ds:ehc_flags,EHC_COMPANION
    jz upDone
;
    cmp cl,ds:ehc_comp_ports
    jae upDone
;    
    mov eax,es:[si].HcPortSc
    or ax,2000h
    mov es:[si].HcPortSc,eax
    jmp upDone
            
upNotify:
    mov ax,200
    WaitMilliSec
;    
    xor ah,ah
    mov al,cl
    NotifyUsbAttach
    jmp upDone

upDetach:
    mov bx,ds:[di].usb_port_sel_arr
    or bx,bx
    jz upDone
;    
    mov al,cl
    NotifyUsbDetach
                    
upDone:    
    pop di
    pop si    
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    ret
UpdatePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    UpdateAllPorts
;
;		DESCRIPTION:    Update all root-hub port status
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateAllPorts   Proc near
    push cx
;    
    xor cl,cl

uaPortLoop:
    cmp cl,ds:ehc_ports
    jae uaPortDone
;    
    push cx
    call UpdatePort
    pop cx
;
    inc cl
    jmp uaPortLoop    

uaPortDone:
    pop cx
    ret
UpdateAllPorts  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UpdateUsb
;
;		DESCRIPTION:    Update USB status
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateUsb  Proc near
    mov ax,ehci_data_sel
    mov ds,ax
    mov cx,ds:EhciFuncCount
    or cx,cx
    jz uuDone
;
    mov si,OFFSET EhciFuncArr

uuLoop:    
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
    mov es,ds:ehc_reg_sel
    mov eax,es:HcStatus
    and al,7
    mov es:HcStatus,eax
;
    test al,1
    jz uuIocDone
;
    int 3

uuIocDone:
    test al,2
    jz uuErrorDone
;
    int 3

uuErrorDone:
    test al,4 
    jz uuNext
;           
    call UpdateAllPorts

uuNext:    
    pop si
    pop cx
    pop ds
;
    add si,2
    loop uuLoop    
    
uuDone:    
    ret
UpdateUsb   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ehci_timer
;
;		DESCRIPTION:    Timer that scans for status change in controller
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ehci_timer  Proc far
    push edx
    push eax
;    
    mov ax,ehci_data_sel
    mov ds,ax
	mov bx,ds:EhciThread
;
    mov cx,ds:EhciFuncCount
    or cx,cx
    jz etDone
;
    mov si,OFFSET EhciFuncArr

etLoop:
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
    mov es,ds:ehc_reg_sel
    mov eax,es:HcStatus
    and al,7
    jz etNext
;    
	Signal

etNext:
    pop si
    pop cx
    pop ds
;
    add si,2
    loop etLoop

etDone:    
    pop eax   
    pop edx
;    
	add eax,1193
	adc edx,0
	mov bx,cs
	mov es,bx
	mov bx,cs
	mov di,OFFSET ehci_timer
	StartTimer
    ret
ehci_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InitFunction
;
;		DESCRIPTION:    Init EHCI function
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ehci_tab:
et00 DW OFFSET CreateControl,   	ehci_code_sel
et01 DW OFFSET CreateBulk,      	ehci_code_sel
et02 DW OFFSET CreateIntr,      	ehci_code_sel
et03 DW OFFSET AddSetup,    	    ehci_code_sel
et04 DW OFFSET AddOut,      	    ehci_code_sel
et05 DW OFFSET AddIn,        	    ehci_code_sel
et06 DW OFFSET AddStatusOut,        ehci_code_sel
et07 DW OFFSET AddStatusIn,        	ehci_code_sel
et08 DW OFFSET IssueTransfer,       ehci_code_sel
et09 DW OFFSET IsTransferDone,      ehci_code_sel
et10 DW OFFSET EndTransfer,         ehci_code_sel
et11 DW OFFSET WasTransferOk,       ehci_code_sel
et12 DW OFFSET GetDataSize,         ehci_code_sel
et13 DW OFFSET ClosePipe,           ehci_code_sel
et14 DW OFFSET WaitForCompletion,   ehci_code_sel
et15 DW OFFSET ChangeAddress,       ehci_code_sel
et16 DW OFFSET IsConnected,         ehci_code_sel

InitFunction    Proc near
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov es,ax   
;    
    mov si,OFFSET ehci_tab
    xor di,di
    mov cx,17

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbDevice
    InitSection ds:ehc_section
;
    mov fs,ds:ehc_reg_sel
    mov fs:HcSegmentSelector,0
;
    mov eax,fs:HcCommand
    or al,80h
    mov fs:HcCommand,eax

ifWaitReset:
    mov eax,fs:HcCommand
    test al,80h
    jz ifResetDone
;
    mov ax,10
    WaitMilliSec
    jmp ifWaitReset    

ifResetDone:
    mov eax,fs:HcCommand
    and al,NOT 0Ch
    mov fs:HcCommand,eax
;
    or al,1
    mov fs:HcCommand,eax
    mov fs:HcConfig,1
;
    xor cl,cl

ifPortLoop:
    cmp cl,ds:ehc_ports
    jae ifPortDone
;    
    movzx si,cl
    shl si,2
;    
    mov eax,fs:[si].HcPortSc
    test ax,1000h
    jnz ifPowerOk
;
    or ax,1000h
    mov fs:[si].HcPortSc,eax

ifPowerOk:   
    inc cl
    jmp ifPortLoop    

ifPortDone:
    popad
    pop fs
    pop es
    ret
InitFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddFunction
;
;		DESCRIPTION:    Add EHCI function
;
;       PARAMETERS:     BX      Bus/device
;                       CH      Function
;                       EAX     Register base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFunction  Proc near
    push es
    push ds
    push eax
    push bx
    push edx
    push di
    push bp
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
	or ax,803h
    SetPhysicalPage
;
    push ecx
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
    mov bp,bx
;         
    mov eax,1000h
	AllocateBigLinear
	mov ecx,eax
	AllocateGdt
	CreateDataSelector16
	mov ds,bx
	mov es,bx
	xor di,di
	xor eax,eax
	mov cx,400h
	rep stosd
;
    mov ds:ehc_reg_sel,bp
    mov ds:ehc_linear,edx
    GetPhysicalPage
    and ax,0F000h
    mov ds:ehc_phys,eax
;         
    mov eax,1000h
	AllocateBigLinear
	mov ecx,eax
	AllocateGdt
	CreateDataSelector16
	mov ds:ehc_map_linear,edx
	mov ds:ehc_map_sel,bx
    mov ds:ehc_pipe_list,0
    mov ds:ehc_async_head_va,0
;
    mov es,bp
    mov cl,es:hcp_CAPLEN
    mov ds:ehc_op_offs,cl
    mov ds:ehc_flags,0
;
    mov ax,es:hcp_HCSPARAMS+2
    test al,1
    jz afIndOk
;
    or ds:ehc_flags,EHC_PORT_IND

afIndOk:
    shr ax,4    
    and al,0Fh
    mov ds:ehc_debug_port,al
;
    mov ax,es:hcp_HCSPARAMS
    test ax,0F000h
    jz afCompOk
;
    or ds:ehc_flags,EHC_COMPANION

afCompOk:
    and ah,0Fh
    mov ds:ehc_comp_ports,ah
    test al,10h
    jz afPowerOk
;
    or ds:ehc_flags,EHC_PORT_POWER

afPowerOk:
    and al,0Fh
    mov ds:ehc_ports,al
;
    mov bx,es
    GetSelectorBaseSize
    movzx eax,ds:ehc_op_offs
    add edx,eax
    sub ecx,eax
    CreateDataSelector16
    mov es,bx
;
    mov bx,ds
    mov ax,ehci_data_sel
    mov ds,ax
    mov di,ds:EhciFuncCount
    shl di,1
    mov ds:[di].EhciFuncArr,bx
    inc ds:EhciFuncCount
;    
    pop bp
    pop di
    pop edx
    pop bx
    pop eax    
    pop ds
    pop es
    ret
AddFunction Endp

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

InitPciAdapter	Proc near
    xor ax,ax
    mov bh,0Ch
    mov bl,3
    mov ch,20h
    FindPciClass
    jc init_pci_done
;
    mov cl,10h
    ReadPciDword
    and ax,0F000h
    mov ebp,eax
    call AddFunction
;	
	mov dx,1

init_pci_next_device:
    mov ax,dx
    mov bh,0Ch
    mov bl,3
    mov ch,20h
    FindPciClass
	jc init_pci_done
;	
	mov cl,10h
	ReadPciDword
    and ax,0F000h
	cmp eax,ebp
	je init_pci_done
;	
	call AddFunction
	inc dx
    jmp init_pci_next_device
    
init_pci_done:
	ret
InitPciAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_usb
;
;		DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ehci_name	DB 'EHCI',0

ehci_thread	proc far
    mov ax,ehci_data_sel
    mov ds,ax
    GetThread
    mov ds:EhciThread,ax
    mov ds:EhciFuncCount,0
;    
	call InitPciAdapter
    mov cx,ds:EhciFuncCount
    or cx,cx    
	jz ehci_thread_exit
;    
    mov si,OFFSET EhciFuncArr

etInitLoop:
    ClearSignal
    push ds
    push si
    mov ds,ds:[si]
    call InitFunction
    pop si
    pop ds
    add si,2
    loop etInitLoop
;    
	GetSystemTime
	add eax,11930
	adc edx,0
	mov bx,cs
	mov es,bx
	mov bx,cs
	mov di,OFFSET ehci_timer
	StartTimer
;
    mov ax,20
    WaitMilliSec

ehci_thread_loop:
    WaitForSignal
    call UpdateUsb
    jmp ehci_thread_loop

ehci_thread_exit:
	ret
ehci_thread	endp
	
init_usb	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET ehci_name
	mov si,OFFSET ehci_thread
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
	mov bx,ehci_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov eax,SIZE data
	mov bx,ehci_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov es,bx
	mov cx,ax
	xor di,di
	xor al,al
	rep stosb
;
    InitSection ds:EhciSection
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
