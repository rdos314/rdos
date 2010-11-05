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

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE usb.inc

MAX_USB_DEVICES = 16

UsbCommandReg = 0
UsbStatusReg = 2
UsbIntReg = 4
FrameNumberReg = 6
FrameBaseReg = 8
SofReg = 12
PortscReg1 = 16
PortscReg2 = 18

; this structure should be smaller than or equal to one page (4k)

int_struc   STRUC

int_64_qh           DB 64 * 32 DUP(?)
int_32_qh           DB 32 * 32 DUP(?)
int_16_qh           DB 16 * 32 DUP(?)
int_8_qh            DB 8 * 32 DUP(?)
int_4_qh            DB 4 * 32 DUP(?)
int_2_qh            DB 2 * 32 DUP(?)
int_1_qh            DB 1 * 32 DUP(?)

int_struc   ENDS

uhci_func_sel    STRUC

usb_dev_base     usb_dev_struc <>

uhc_hw_phys      DD ?
uhc_hw_linear    DD ?
uhc_hw_sel       DW ?

uhc_int_phys     DD ?
uhc_int_linear   DD ?
uhc_int_sel      DW ?

uhc_status       DW ?

uhc_period_td    DD ?

uhc_io_base      DW ?

uhc_pipe_list    DW ?

uhc_pci_bus_dev  DW ?
uhc_pci_func     DB ?

uhc_64_cnt       DB 64 DUP(?)
uhc_32_cnt       DB 32 DUP(?)
uhc_16_cnt       DB 16 DUP(?)
uhc_8_cnt        DB 8 DUP(?)
uhc_4_cnt        DB 4 DUP(?)
uhc_2_cnt        DB 2 DUP(?)
uhc_1_cnt        DB ?

uhc_curr_cnt     DB 128 DUP(?)

uhci_func_sel    ENDS

USP_FLAG_TRANSFER_PENDING   = 1
USP_FLAG_TRANSFER_OK        = 2

uhci_pipe   STRUC

usp_pipe_base       usb_pipe_struc <>
usp_qh              DD ?
usp_intr_ptr        DW ?
usp_intr_cnt        DW ?
usp_prev            DW ?
usp_next            DW ?
usp_signal          DW ?
usp_data_size       DW ?
usp_setup_linear    DD ?
usp_flags           DB ?

uhci_pipe   ENDS

; this structure is always allocated as 32 bytes!

uhci_td STRUC

utd_link    DD ?
utd_control DD ?
utd_host    DD ?
utd_buf     DD ?

utd_va_link DD ?
utd_phys    DD ?

uhci_td ENDS

; this structure is always allocated as 32 bytes!

uhci_qh STRUC

uqh_link    DD ?
uqh_elem    DD ?

uqh_va_link DD ?
uqh_va_elem DD ?
uqh_phys    DD ?

uhci_qh ENDS

data    SEGMENT byte public 'DATA'

UhciList32   DD ?
UhciSection  section_typ <>
UhciThread   DW ?
UhciCount    DW ?
UhciFunc     DW 16 DUP (?)

data    ENDS

code    SEGMENT byte public 'CODE'


        assume cs:code

.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   UpdatePipeList
;
;               DESCRIPTION:    Update pipe list
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePipeList  Proc near
    push ax
;    
    mov ax,ds:uhc_pipe_list
    or ax,ax
    jz uplDone
;
    push es
    push fs
    push ebx
    push dx
    push di
;
    mov di,ax
    mov fs,ax
;
    mov ax,flat_sel
    mov es,ax

uplLoop:
    mov edx,fs:usp_qh
    or edx,edx
    jz uplNext
;
    mov ebx,es:[edx].uqh_va_elem
    or ebx,ebx
    jz uplNext
;    
    test byte ptr es:[edx].uqh_elem,1
    jz uplNext
;    
    xor bx,bx
    xchg bx,fs:usp_signal
    Signal

uplNext:    
    mov ax,fs:usp_next
    mov fs,ax
    cmp ax,di
    jne uplLoop
;
    pop di
    pop dx
    pop ebx
    pop fs
    pop es    

uplDone:    
    pop ax
    ret
UpdatePipeList  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   UhciInt
;
;               DESCRIPTION:    UHCI interrupt
;
;       PARAMETERS:     DS      Function selector
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UhciInt Proc far    
    mov dx,ds:uhc_io_base
    add dx,UsbStatusReg
;
    in ax,dx
    or ax,ax
    jz uiDone
;    
    or ds:uhc_status,ax
    out dx,ax
;    
    call UpdatePipeList

uiDone:
    ret
UhciInt  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   AllocateBlock32
;
;               DESCRIPTION:    Allocate 32-byte block with page-alignment
;
;       PARAMETERS:     ES      Flat sel
;
;               RETURNS:                EDX             Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlock32 PROC near
    push ds
    push eax
;    
    mov ax,SEG data
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
AllocateBlock32 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   FreeBlock32
;
;               DESCRIPTION:    Free 32-byte block
;
;       PARAMETERS:     ES      Flat sel
;
;               PARAMETERS:             EDX             Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBlock32     PROC near
    push ds
        push eax
;
    mov ax,SEG data
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
FreeBlock32     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   InsertPipe
;
;               DESCRIPTION:    Insert pipe into function pipe-list
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
        cli
        mov si,ds:usp_prev
        mov ds:usp_prev,fs
        mov ds,si
        mov ds:usp_next,fs
        mov fs:usp_next,di
        mov fs:usp_prev,si
        sti
        pop si
        pop ds
        pop di
        jmp ipDone
        
ipEmpty:
        mov fs:usp_next,fs
        mov fs:usp_prev,fs
        pop di
        mov ds:uhc_pipe_list,fs

ipDone:
    mov fs:usp_signal,0
        ret
InsertPipe  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   RemovePipe
;
;               DESCRIPTION:    Remove pipe from function pipe-list
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
        mov si,fs:usp_prev
        mov di,fs:usp_next
        mov ds,di
        mov ds:usp_prev,si
        mov ds,si
        mov ds:usp_next,di
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               InitQh
;
;               DESCRIPTION:    Initialize a queue header
;
;       PARAMETERS:     ES      Flat sel
;                       EDX             QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitQh  PROC near
    push eax
    push cx
;    
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
InitQh  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               AllocateQh
;
;               DESCRIPTION:    Allocate & initialize a queue header
;
;       PARAMETERS:     ES      Flat sel
;
;               PARAMETERS:             EDX             QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQh      PROC near
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               AllocateTd
;
;               DESCRIPTION:    Allocate & initialize a TD block
;
;       PARAMETERS:     DS      Function selector
;                       ES      Flat sel
;                       FS      Pipe
;                       EDI     Data buffer
;                       CX      Size of data
;
;               PARAMETERS:             EDX             TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTd      PROC near
    push eax
    push ecx
;    
    call AllocateBlock32
    mov es:[edx].utd_link,1
    mov es:[edx].utd_va_link,0
    mov es:[edx].utd_control, 18000000h
    test fs:usbp_speed,USB_LOW_SPEED
    jz atSpeedOk
;
    or es:[edx].utd_control, 4000000h
    
atSpeedOk:
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
;               NAME:               InsertElem
;
;               DESCRIPTION:    Insert TD into vertical QH
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     QH
;                       EAX     TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertElem      PROC near
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               InsertTdFirst
;
;               DESCRIPTION:    Insert QH first into TD list
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     TD to insert into
;                       EAX     QH to link
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertTdFirst   PROC near
    push ecx
;
    mov ecx,es:[edx].utd_va_link
    or ecx,ecx
    jz itdEmpty
;
    mov es:[eax].uqh_va_link,ecx
    mov ecx,es:[edx].utd_link
    mov es:[eax].uqh_link,ecx
;
    mov es:[edx].utd_va_link,eax
    mov ecx,es:[eax].uqh_phys
    or cl,2
    mov es:[edx].utd_link,ecx    
    jmp itdDone
    
itdEmpty:
    mov es:[eax].uqh_va_link,0
    mov es:[eax].uqh_link,1
    mov es:[edx].utd_va_link,eax
    mov ecx,es:[eax].uqh_phys
    or cl,2
    mov es:[edx].utd_link,ecx

itdDone:
    pop ecx
    ret
InsertTdFirst  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               InsertTdLast
;
;               DESCRIPTION:    Insert QH last into TD list
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     TD to insert into
;                       EAX     QH to link
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertTdLast    PROC near
    push edx
    push ecx
;
    mov es:[eax].uqh_va_link,0
    mov es:[eax].uqh_link,1
;
    mov edx,es:[edx].utd_va_link    

itlLoop:
    mov ecx,es:[edx].uqh_va_link
    or ecx,ecx
    jz itlDo
;
    mov edx,ecx
    jmp itlLoop

itlDo:
    mov ecx,es:[eax].uqh_phys
    or cl,2
    mov es:[edx].uqh_link,ecx
    mov es:[edx].uqh_va_link,eax
;    
    pop edx
    pop ecx
    ret
InsertTdLast  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               Remove
;
;               DESCRIPTION:    Remove QH from TD list
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     TD list
;                       EAX     QH to delink
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveTd        PROC near
    push ebx
    push ecx
    push edx
;
    mov ecx,es:[edx].utd_va_link
    cmp ecx,eax
    jne rtdSearch
;
    mov ecx,es:[eax].uqh_va_link
    or ecx,ecx
    jz rtdEmptyList
;
    mov es:[edx].utd_va_link,ecx
    mov ecx,es:[eax].uqh_link
    mov es:[edx].utd_link,ecx
    jmp rtdDone

rtdEmptyList:
    mov es:[edx].utd_va_link,0
    mov es:[edx].utd_link,1    
    jmp rtdDone

rtdSearch:
    or ecx,ecx
    jz rtdDone
;
    cmp eax,ecx
    je rtdRemove
;
    mov edx,ecx
    mov ecx,es:[edx].uqh_va_link
    jmp rtdSearch

rtdRemove:
    mov ecx,es:[eax].uqh_va_link
    or ecx,ecx
    jz rtdEmpty
;   
    mov es:[edx].uqh_va_link,ecx
    mov ecx,es:[eax].uqh_link
    mov es:[edx].uqh_link,ecx
    jmp rtdDone

rtdEmpty:
    mov es:[edx].uqh_va_link,0
    mov es:[edx].uqh_link,1

rtdDone:
    pop edx
    pop ecx
    pop ebx
    ret
RemoveTd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               InsertIntr
;
;               DESCRIPTION:    Insert QH into interrupt list
;
;       PARAMETERS:     ES      Flat sel
;                       GS:DI   Intr list
;                       EAX     QH to link
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertIntr      PROC near
    push ecx
    push edx
;    
    mov es:[eax].uqh_va_link,0
    mov es:[eax].uqh_link,1
;
    mov edx,gs:[di].uqh_va_elem
    or edx,edx
    jz iiEmpty

iiLastLoop:
    mov ecx,es:[edx].uqh_va_link
    or ecx,ecx
    jz iiDoLast
;
    mov edx,ecx
    jmp iiLastLoop

iiDoLast:
    mov ecx,es:[eax].uqh_phys
    or cl,2
    mov es:[edx].uqh_link,ecx
    mov es:[edx].uqh_va_link,eax
    jmp iiDone

iiEmpty:
    mov ecx,es:[eax].uqh_phys
    or cl,2
    mov gs:[di].uqh_elem,ecx
    mov gs:[di].uqh_va_elem,eax

iiDone:    
    pop edx
    pop ecx
    ret
InsertIntr  Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               RemoveIntr
;
;               DESCRIPTION:    Remove QH from interrupt list
;
;       PARAMETERS:     ES      Flat sel
;                       GS:DI   Intr list
;                       EAX     QH to delink
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveIntr      PROC near
    push ebx
    push ecx
;    
    mov ecx,gs:[di].uqh_va_elem
    cmp ecx,eax
    jne riSearch
;
    mov ecx,es:[eax].uqh_va_link
    or ecx,ecx
    jz riEmptyList
;
    mov gs:[di].uqh_va_elem,ecx
    mov ecx,es:[eax].uqh_link
    mov gs:[di].uqh_elem,ecx
    jmp riDone

riEmptyList:
    mov gs:[di].uqh_va_elem,0
    mov gs:[di].uqh_elem,1
    jmp riDone

riSearch:
    or ecx,ecx
    jz riDone
;
    cmp eax,ecx
    je riRemove
;
    mov edx,ecx
    mov ecx,es:[edx].uqh_va_link
    jmp riSearch

riRemove:
    mov ecx,es:[eax].uqh_va_link
    or ecx,ecx
    jz riEmpty
;   
    mov es:[edx].uqh_va_link,ecx
    mov ecx,es:[eax].uqh_link
    mov es:[edx].uqh_link,ecx
    jmp riDone

riEmpty:
    mov es:[edx].uqh_va_link,0
    mov es:[edx].uqh_link,1

riDone:
    pop ecx
    pop ebx
    ret
RemoveIntr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               FreeVaElem
;
;               DESCRIPTION:    Free all Tds in vertical va-linked list
;
;       PARAMETERS:     ES      Flat sel
;                       EDX     QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeVaElem      PROC near
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
    mov esi,es:[edx].utd_va_link
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

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               GetQhDataSize
;
;               DESCRIPTION:    Get data size from transfer
;
;       PARAMETERS:     EDX     Qh
;
;       RETURNS:        CX      Size of data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetQhDataSize   PROC near
    push ds
    push eax
    push edx
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
    mov ax,word ptr [edx].utd_control
    inc ax
    and ax,7FFh
    add cx,ax

gqdNext:
    mov edx,[edx].utd_va_link
    jmp gqdLoop
            
gqdDone:    
    pop edx
    pop eax
    pop ds
    ret
GetQhDataSize  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               CreateIntrQueue
;
;               DESCRIPTION:    Create interrupt queue
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntrQueue PROC near
    push es
    push fs
    push eax
    push bx
    push cx
    push edx
;        
    mov eax,1000h
        AllocateBigLinear
        mov ds:uhc_int_linear,edx
        mov ecx,eax
        AllocateGdt
        CreateDataSelector16
    mov ds:uhc_int_sel,bx
;
    mov ax,flat_sel
    mov es,ax
;
    mov cx,64
    mov edx,OFFSET int_64_qh
    add edx,ds:uhc_int_linear

ciQhLoop:
    call InitQh
    add edx,32
    add bx,4
    loop ciQhLoop
;
    mov edx,ds:uhc_int_linear
    GetPhysicalPage
    and ax,0F000h
    mov ds:uhc_int_phys,eax    
;
    mov fs,ds:uhc_hw_sel
    mov cx,16
    xor bx,bx

ciHwyLoop:
    push cx
    mov cx,64
    mov eax,OFFSET int_64_qh
    add eax,ds:uhc_int_phys
    or al,2

ciHwiLoop:
    mov fs:[bx],eax
    add eax,32
    add bx,4
    loop ciHwiLoop
;
    pop cx
    loop ciHwyLoop
;
    mov fs,ds:uhc_int_sel
    mov cx,64
    mov bx,OFFSET int_64_qh
    mov eax,OFFSET int_32_qh
    mov edx,eax
    add edx,ds:uhc_int_linear
    add eax,ds:uhc_int_phys
    or al,2

ci32Loop:
    call InitQh
    
ci32Link:
    mov fs:[bx].uqh_link,eax
    mov fs:[bx].uqh_va_link,edx
    add bx,32
;
    test cx,1
    jnz ci32Next
    loop ci32Link

ci32Next:    
    add eax,32
    add edx,32
    loop ci32Loop
;
    mov cx,32
    mov bx,OFFSET int_32_qh
    mov eax,OFFSET int_16_qh
    mov edx,eax
    add edx,ds:uhc_int_linear
    add eax,ds:uhc_int_phys
    or al,2

ci16Loop:
    call InitQh
    
ci16Link:
    mov fs:[bx].uqh_link,eax
    mov fs:[bx].uqh_va_link,edx
    add bx,32
;
    test cx,1
    jnz ci16Next
    loop ci16Link

ci16Next:    
    add eax,32
    add edx,32
    loop ci16Loop
;
    mov cx,16
    mov bx,OFFSET int_16_qh
    mov eax,OFFSET int_8_qh
    mov edx,eax
    add edx,ds:uhc_int_linear
    add eax,ds:uhc_int_phys
    or al,2

ci8Loop:
    call InitQh
    
ci8Link:
    mov fs:[bx].uqh_link,eax
    mov fs:[bx].uqh_va_link,edx
    add bx,32
;
    test cx,1
    jnz ci8Next
    loop ci8Link

ci8Next:    
    add eax,32
    add edx,32
    loop ci8Loop
;
    mov cx,8
    mov bx,OFFSET int_8_qh
    mov eax,OFFSET int_4_qh
    mov edx,eax
    add edx,ds:uhc_int_linear
    add eax,ds:uhc_int_phys
    or al,2

ci4Loop:
    call InitQh
    
ci4Link:
    mov fs:[bx].uqh_link,eax
    mov fs:[bx].uqh_va_link,edx
    add bx,32
;
    test cx,1
    jnz ci4Next
    loop ci4Link

ci4Next:    
    add eax,32
    add edx,32
    loop ci4Loop
;
    mov cx,4
    mov bx,OFFSET int_4_qh
    mov eax,OFFSET int_2_qh
    mov edx,eax
    add edx,ds:uhc_int_linear
    add eax,ds:uhc_int_phys
    or al,2

ci2Loop:
    call InitQh
    
ci2Link:
    mov fs:[bx].uqh_link,eax
    mov fs:[bx].uqh_va_link,edx
    add bx,32
;
    test cx,1
    jnz ci2Next
    loop ci2Link

ci2Next:    
    add eax,32
    add edx,32
    loop ci2Loop
;
    mov cx,2
    mov bx,OFFSET int_2_qh
    mov eax,OFFSET int_1_qh
    mov edx,eax
    add edx,ds:uhc_int_linear
    add eax,ds:uhc_int_phys
    or al,2

ci1Loop:
    call InitQh
    mov fs:[bx].uqh_link,eax
    mov fs:[bx].uqh_va_link,edx
    add bx,32
    loop ci1Loop
;
    mov bx,OFFSET int_1_qh
    mov edx,ds:uhc_period_td
    mov eax,es:[edx].utd_phys
    mov fs:[bx].uqh_link,eax
    mov fs:[bx].uqh_va_link,edx
;   
    mov cx,64+32+16+8+4+2+1
    mov bx,OFFSET uhc_64_cnt
    xor al,al

ciInitCount:
    mov ds:[bx],al
    inc bx
    loop ciInitCount
;    
    pop edx
    pop cx
    pop bx
    pop eax
    pop fs
    pop es
    ret
CreateIntrQueue Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               CreatePeriodTd
;
;               DESCRIPTION:    Create periodic interrupt td
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePeriodTd  PROC near
    push edx
;    
    call AllocateTd
    mov ds:uhc_period_td,edx
;    
    call CreateIntrQueue
;
    pop edx
    ret
CreatePeriodTd  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               GetIntrQh
;
;               DESCRIPTION:    Get interrupt QH
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;                       CL      Interval
;
;       RETURNS:        BX      Offset to count entry
;                       DI      Offset to QH list entry to use
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIntrQh       PROC near
    push ax
    push cx
    push si
    push bp
;
    cmp cl,1
    jbe gie1
;
    cmp cl,3
    jbe gie2
;
    cmp cl,7
    jbe gie4
;
    cmp cl,15
    jbe gie8
;
    cmp cl,31
    jbe gie16
;
    cmp cl,63
    jbe gie32

gie64:
    mov bx,OFFSET uhc_64_cnt
    mov si,OFFSET int_64_qh
    mov cx,64
    jmp gieLnkOk

gie32:
    mov bx,OFFSET uhc_32_cnt
    mov si,OFFSET int_32_qh
    mov cx,32
    jmp gieLnkOk

gie16:
    mov bx,OFFSET uhc_16_cnt
    mov si,OFFSET int_16_qh
    mov cx,16
    jmp gieLnkOk

gie8:
    mov bx,OFFSET uhc_8_cnt
    mov si,OFFSET int_8_qh
    mov cx,8
    jmp gieLnkOk

gie4:
    mov bx,OFFSET uhc_4_cnt
    mov si,OFFSET int_4_qh
    mov cx,4
    jmp gieLnkOk

gie2:
    mov bx,OFFSET uhc_2_cnt
    mov si,OFFSET int_2_qh
    mov cx,2
    jmp gieLnkOk

gie1:
    mov bx,OFFSET uhc_1_cnt
    mov si,OFFSET int_1_qh
    mov cx,1

gieLnkOk:
    push cx
    mov di,OFFSET uhc_curr_cnt
    xor al,al

gieInitCnt:
    mov [di],al
    inc di
    loop gieInitCnt
;    
    pop cx
;
    push bx
    push cx
    push si
;   
    mov si,1

gieAddListLoop:    
    push cx
    mov di,OFFSET uhc_curr_cnt

gieAddCount:
    mov al,[bx]
    mov bp,si    

gieAddLoop:
    add [di],al
    inc di
    sub bp,1
    jnz gieAddLoop
;    
    inc bx
    loop gieAddCount
;
    pop cx
;
    shl si,1
    shr cx,1
    or cx,cx
    jnz gieAddListLoop    
;
    pop si
    pop cx
    pop bx
;
    mov ah,0FFh
    mov di,OFFSET uhc_curr_cnt

gieSmallestLoop:
    mov al,[di]
    cmp al,ah
    jae gieSmallestNext
;
    mov ah,al
    mov bp,di

gieSmallestNext:
    inc di
    loop gieSmallestLoop
;
    mov di,bp
    sub di,OFFSET uhc_curr_cnt
;
    add bx,di
    shl di,5
    add di,si
;    
    pop bp
    pop si
    pop cx
    pop ax
    ret
GetIntrQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               CreateControl
;
;               DESCRIPTION:    Create control pipe
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
    mov eax,SIZE uhci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
;
    mov eax,1000h
    AllocateBigLinear
    mov es:usp_setup_linear,edx
;    
    mov ax,es
    mov fs,ax
    mov dx,flat_sel
    mov es,dx
    call AllocateQh
    mov fs:usp_qh,edx
;
    mov edx,ds:uhc_period_td
    or edx,edx
    jnz ccLinkPeriod    
;
    call CreatePeriodTd
    mov edx,ds:uhc_period_td

ccLinkPeriod:
    mov eax,fs:usp_qh
    call InsertTdFirst
    call InsertPipe
;
    popad
    pop es
    ret
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               CreateBulk
;
;               DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     DS      Function selector
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    push es
    pushad
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
    mov fs:usp_qh,edx    
    mov eax,edx
    mov edx,ds:uhc_period_td
    call InsertTdLast
    call InsertPipe
;
    popad
    pop es
    ret
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               CreateIntr
;
;               DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     DS      Function selector
;                       AL      Interval
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    push es
    push gs
    pushad
;    
    mov cl,al
;
    mov eax,SIZE uhci_pipe
    AllocateSmallGlobalMem
    push cx
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    pop cx
;    
    mov ax,es
    mov fs,ax
    mov ax,flat_sel
    mov es,ax
;    
    call AllocateQh
    mov fs:usp_qh,edx
;    
    call GetIntrQh
    mov fs:usp_intr_ptr,di
    mov fs:usp_intr_cnt,bx
    inc byte ptr ds:[bx]
;    
    mov gs,ds:uhc_int_sel
    mov eax,fs:usp_qh
    call InsertIntr
    call InsertPipe
;
    popad
    pop gs
    pop es
    ret
CreateIntr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               AddBuffer
;
;               DESCRIPTION:    Allocate input/output buffer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     QH
;                       CX      Size
;                       ES:EDI  Data
;                       AL      PID
;                     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBuffer    Proc near
    push es
    pushad
;    
    mov ebp,edx
    movzx ecx,cx    
    mov si,ax
    or cx,cx
    jnz abHasData
;
    mov ax,flat_sel
    mov es,ax
    xor edi,edi
    call AllocateTd
    or byte ptr es:[edx].utd_link,4
    mov ax,si
    or byte ptr es:[edx].utd_host,al
    or es:[edx].utd_control,800000h
    mov eax,edx
    mov edx,ebp
    call InsertElem
    jmp abDone

abHasData:
    push ecx
    mov bx,es
    GetSelectorBaseSize
    add edx,edi
    sub ecx,edi
    mov eax,ecx
    pop ecx
    jc abDone  
;
    cmp eax,ecx
    jb abDone
;
    mov ax,flat_sel
    mov es,ax
    mov edi,edx    

abLoop:
    mov ax,1000h
    mov dx,di
    and dx,0FFFh
    sub ax,dx
    cmp ax,fs:usbp_maxlen
    jb abMinOk
;
    mov ax,fs:usbp_maxlen

abMinOk:
    movzx eax,ax
    push eax
    push cx
    mov cx,ax
;
    call AllocateTd
    mov ax,si
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,al
    or es:[edx].utd_control,800000h
    mov eax,edx
    mov edx,ebp
    call InsertElem       
;
    pop cx
    pop eax
    add edi,eax
    sub cx,ax
    ja abLoop
    
abDone:
    popad
    pop es
    ret
AddBuffer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               AddSetup
;
;               DESCRIPTION:    Add setup transaction to queue
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
    mov ax,flat_sel
    mov es,ax   
    mov edi,fs:usp_setup_linear
;
    movzx ecx,cx
    push ecx
    push ecx
    shr ecx,2
    rep movs dword ptr es:[edi],gs:[esi]
    pop ecx
    and ecx,3
    rep movs byte ptr es:[edi],gs:[esi]
    pop ecx
;
    mov edi,fs:usp_setup_linear
    mov fs:usbp_seq,0
    call AllocateTd
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,PID_SETUP
    or es:[edx].utd_control,800000h
    mov eax,edx
    mov edx,fs:usp_qh
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
;               NAME:               AddOut
;
;               DESCRIPTION:    Add out transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddOut    Proc far
    push edx
;   
    mov edx,fs:usp_qh 
    mov al,PID_OUT
    call AddBuffer
;    
    pop edx
    ret
AddOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               AddIn
;
;               DESCRIPTION:    Add in transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Buffer size
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIn    Proc far
    push edx
;    
    mov edx,fs:usp_qh 
    mov al,PID_IN
    call AddBuffer
;    
    pop edx
    ret
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               AddStatusOut
;
;               DESCRIPTION:    Add status OUT transaction to queue
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
    mov edx,fs:usp_qh 
    xor ecx,ecx
    mov al,PID_OUT
    call AddBuffer

asoDone:
    pop edx
    pop ecx
    pop eax    
    ret
AddStatusOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               AddStatusIn
;
;               DESCRIPTION:    Add status IN transaction to queue
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
    mov edx,fs:usp_qh
    xor ecx,ecx
    mov al,PID_IN
    call AddBuffer

asiDone:
    pop edx
    pop ecx
    pop eax    
    ret
AddStatusIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               IssueTransfer
;
;               DESCRIPTION:    Issue transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     Queue handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueTransfer    Proc far
    push es
    push eax
    push ecx
    push edx
;    
    mov ax,flat_sel
    mov es,ax    
    mov edx,fs:usp_qh
;    
    ClearSignal
    GetThread
    mov fs:usp_signal,ax
    and fs:usp_flags, NOT USP_FLAG_TRANSFER_OK
    or fs:usp_flags, USP_FLAG_TRANSFER_PENDING
;    
    mov eax,es:[edx].uqh_va_elem    
    or eax,eax
    jz itDone
;    
    mov eax,es:[eax].utd_phys
    mov es:[edx].uqh_elem,eax

itDone:
    pop edx 
    pop ecx
    pop eax
    pop es
    ret
IssueTransfer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               IsTransferDone
;
;               DESCRIPTION:    Check if transfer is done
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsTransferDone   Proc far
    push es
    push eax
    push edx
;
    test fs:usp_flags, USP_FLAG_TRANSFER_PENDING
    jz itdOk
;    
    call IsConnected
    jc itdOk
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov bx,fs:usp_signal
    or bx,bx
    jnz itdFail
;    
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je itdControlBulk
;
    cmp al,MODE_BULK
    jne itdOk

itdControlBulk:
    mov edx,fs:usp_qh
    test es:[edx].uqh_elem,1
    jnz itdOk
;
    mov eax,es:[edx].uqh_va_elem
    test es:[eax].utd_control,400000h    
    jnz itdRecover

itdFail:
    stc
    jmp itdEnd   

itdRecover:
    mov es:[edx].uqh_elem,1

itdOk:
    clc

itdEnd:    
    pop edx
    pop eax
    pop es
    ret
IsTransferDone   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               WaitForCompletion
;
;               DESCRIPTION:    Wait for transfer to complete
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion   Proc far
    push eax
;
    test fs:usp_flags, USP_FLAG_TRANSFER_PENDING
    jz wfcDone

wfcWait:
    call IsTransferDone
    jnc wfcDone
;
    WaitForSignal
    jmp wfcWait

wfcDone:
    call EndTransfer
;    
    pop eax
    ret
WaitForCompletion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               WasTransferOk
;
;               DESCRIPTION:    Check if last transfer was ok
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        NC      Transfer was ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WasTransferOk   Proc far
    test fs:usp_flags, USP_FLAG_TRANSFER_PENDING
    jz wtoNotPending
;
    call EndTransfer

wtoNotPending:
    test fs:usp_flags, USP_FLAG_TRANSFER_OK
    jnz wtoOk
;    
    stc
    jmp wtoDone

wtoOk:
    clc

wtoDone:
    ret
WasTransferOk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               EndTransfer
;
;               DESCRIPTION:    End transfer and get input data
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndTransfer   Proc far
    push es
    push ax
    push edx
    push edi
;    
    test fs:usp_flags, USP_FLAG_TRANSFER_PENDING
    jz etDone
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov fs:usp_data_size,0     
    and fs:usp_flags, NOT USP_FLAG_TRANSFER_PENDING
    and fs:usp_flags, NOT USP_FLAG_TRANSFER_OK
;    
    mov edx,fs:usp_qh
    or edx,edx
    jz etDataDone
;
    test byte ptr es:[edx].uqh_elem,1
    jz etDataDone
;
    or fs:usp_flags, USP_FLAG_TRANSFER_OK

etStatusOk:
    mov edx,fs:usp_qh
    call GetQhDataSize
    mov fs:usp_data_size,cx
        
etDataDone:
    mov ax,flat_sel
    mov es,ax
;    
    mov edx,fs:usp_qh
    call FreeVaElem

etDone:   
    pop edi
    pop edx
    pop ax
    pop es
    ret
EndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               GetDataSize
;
;               DESCRIPTION:    Get input data size for last transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        CX      Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDataSize   Proc far
    xor cx,cx
    test fs:usp_flags, USP_FLAG_TRANSFER_OK
    jz gdsDone
;    
    mov cx,fs:usp_data_size

gdsDone:
    ret
GetDataSize   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               ClosePipe
;
;               DESCRIPTION:    Close pipe
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
    je dpControlBulk
;
    cmp al,MODE_BULK
    je dpControlBulk
;
    cmp al,MODE_INTR
    je dpFreeIntr
;
    int 3    
    jmp dpDone    

dpControlBulk:
    mov ax,flat_sel
    mov es,ax
    mov edx,ds:uhc_period_td
    mov eax,fs:usp_qh
    call RemoveTd
    mov edx,eax
    call FreeBlock32
    jmp dpDone

dpFreeIntr:
    push gs
    push di
;    
    mov ax,flat_sel
    mov es,ax
    mov gs,ds:uhc_int_sel
    mov di,fs:usp_intr_ptr
    mov eax,fs:usp_qh
    call RemoveIntr
;    
    mov edx,eax
    call FreeBlock32
;    
    mov di,fs:usp_intr_cnt
    dec byte ptr ds:[di]
;
    pop di
    pop gs
    jmp dpDone
    
dpDone:
    mov edx,fs:usp_setup_linear
    or edx,edx
    jz rpSetupDone
;
    mov ecx,1000h
    FreeLinear

rpSetupDone:   
    mov ax,2
    WaitMilliSec
;
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
;               NAME:               ChangeAddress
;
;               DESCRIPTION:    Change address for pipe
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    ret
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               IsConnected
;
;               DESCRIPTION:    Check if pipe is connected
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsConnected   Proc far
    push es
    push ax
    push dx
    push si
;    
    mov es,fs:usbp_function_sel
    movzx si,es:usbf_port
;    
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,si
    add dx,si
;
    in ax,dx
    test al,1
    clc
    jnz icDone
;    
    stc

icDone:
    pop si
    pop dx
    pop ax
    pop es
    ret
IsConnected   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               UpdatePort
;
;               DESCRIPTION:    Update root-hub port status
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
    push ax
    mov ax,200
    WaitMilliSec
    pop ax
;    
    pop cx
    and ah,1
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
;               NAME:               InitFunction
;
;               DESCRIPTION:    Init UHCI function
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uhci_tab:
ut00 DW OFFSET CreateControl,           SEG code
ut01 DW OFFSET CreateBulk,              SEG code
ut02 DW OFFSET CreateIntr,              SEG code
ut03 DW OFFSET AddSetup,            SEG code
ut04 DW OFFSET AddOut,              SEG code
ut05 DW OFFSET AddIn,               SEG code
ut06 DW OFFSET AddStatusOut,        SEG code
ut07 DW OFFSET AddStatusIn,             SEG code
ut08 DW OFFSET IssueTransfer,       SEG code
ut09 DW OFFSET IsTransferDone,      SEG code
ut10 DW OFFSET EndTransfer,         SEG code
ut11 DW OFFSET WasTransferOk,       SEG code
ut12 DW OFFSET GetDataSize,         SEG code
ut13 DW OFFSET ClosePipe,           SEG code
ut14 DW OFFSET WaitForCompletion,   SEG code
ut15 DW OFFSET ChangeAddress,       SEG code
ut16 DW OFFSET IsConnected,         SEG code

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
;       RequestSharedIrqHandler
;
    mov si,OFFSET uhci_tab
    xor di,di
    mov cx,17

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
;    mov ax,0Fh
    xor ax,ax
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
;    mov cl,0
;    call UpdatePort    
;
;    mov cl,1
;    call UpdatePort    
;
    popad
    ret
InitFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:               AddFunction
;
;               DESCRIPTION:    Add UHCI function
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
    mov cx,ax
    xor al,al
    xor di,di
    rep stosb
;    
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
    mov ax,ds
    mov es,ax
;
    GetPhysicalPage
    and ax,0F000h
    mov ds:uhc_hw_phys,eax    
;    
    mov ds:uhc_status,0
    mov ds:uhc_period_td,0
;
    mov ax,SEG data
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
;               NAME:               PollFunction
;
;               DESCRIPTION:    Poll UHCI function
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
;               NAME:                   InitPciAdapter
;
;               DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;               RETURNS:                NC              Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PciVendorTab:
pci00   DW 1106h, 3038h
pci01   DW 8086h, 24D2h
pci02   DW 8086h, 24D4h
pci03   DW 8086h, 24D7h
pci04   DW 8086h, 24DEh
pci05   DW 8086h, 24C2h
pci06   DW 0,     0

InitPciAdapter  Proc near
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
InitPciAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   port_timer
;
;               DESCRIPTION:    Port timer
;
;       PARAMETERS:     
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_timer  Proc far
    push edx
    push eax
;    
    xor si,si
    mov ax,SEG data
    mov ds,ax
;
    mov cx,ds:UhciCount 
    mov bx,OFFSET UhciFunc

timer_func_loop:
    push ds
    mov ds,[bx]
;
    mov dx,ds:uhc_io_base
    add dx,UsbStatusReg
;
    in ax,dx    
    test al,20h
    jz tNonFatal
;
    CpuReset

tNonFatal:
    call UpdatePipeList
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
        add eax,1193
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
;               NAME:                   Init_net
;
;               DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uhci_name       DB 'UHCI',0

uhci_thread     proc far
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:UhciThread,ax
;    
        call InitPciAdapter
;
    mov ax,750
    WaitMilliSec
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
        add eax,11930
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
uhci_thread     endp
        
init_usb        Proc far
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
init_usb        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;               NAME:                   Init
;
;               DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;               RETURNS:                
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
        mov bx,SEG data
        mov ds,bx
    InitSection ds:UhciSection
;
        mov ax,cs
        mov es,ax
        mov di,OFFSET init_usb
        HookInitTasking
        clc
        ret
Init    Endp

code ENDS

        END init
