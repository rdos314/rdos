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

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\core.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE usb.inc
INCLUDE ..\os\memblk.inc
INCLUDE usbdev.inc

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

int_64_qh       DB 64 * 32 DUP(?)
int_32_qh       DB 32 * 32 DUP(?)
int_16_qh       DB 16 * 32 DUP(?)
int_8_qh        DB 8 * 32 DUP(?)
int_4_qh        DB 4 * 32 DUP(?)
int_2_qh        DB 2 * 32 DUP(?)
int_1_qh        DB 1 * 32 DUP(?)

int_struc   ENDS

uhci_func_sel    STRUC

usb_func_base     usb_function_struc <>

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
uhc_spinlock     spinlock_typ <>
uhc_section      section_typ <>

uhc_reset        DW ?

uhc_pci_bus_dev  DW ?
uhc_pci_func     DB ?

uhc_64_cnt       DB 64 DUP(?)
uhc_32_cnt       DB 32 DUP(?)
uhc_16_cnt       DB 16 DUP(?)
uhc_8_cnt    DB 8 DUP(?)
uhc_4_cnt    DB 4 DUP(?)
uhc_2_cnt    DB 2 DUP(?)
uhc_1_cnt    DB ?

uhc_curr_cnt     DB 128 DUP(?)

uhci_func_sel    ENDS

uhci_dev_sel    STRUC

usb_dev_base     usb_device_struc <>

dev_control_qh   DD ?
dev_control_head DD ?
dev_utd_control  DD ?
dev_curr_address DB ?

uhci_dev_sel    ENDS

USP_FLAG_TRANSFER_PENDING   = 1
USP_FLAG_TRANSFER_OK    = 2
USP_FLAG_SINGLE             = 4

uhci_pipe   STRUC

usp_pipe_base       usb_pipe_struc <>
usp_qh          DD ?
usp_intr_ptr    DW ?
usp_intr_cnt    DW ?
usp_prev        DW ?
usp_next        DW ?
usp_data_size       DW ?
usp_setup_linear    DD ?
usp_flags       DB ?
usp_done        DB ?

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

UhciUsedBlocks  DD ?
UhciCloseCount  DD ?
UhciList32      DD ?
UhciSection     section_typ <>

WaitSection     section_typ <>
WaitThreadArr   DW 3 DUP(?)
Started         DB ?

UhciCount       DW ?
UhciFunc        DW 16 DUP (?)

data    ENDS

code    SEGMENT byte public 'CODE'


    assume cs:code

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdatePipeList
;
;           DESCRIPTION:    Update pipe list
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePipeList  Proc near
    push ax

uplLoop:
    RequestSpinlock ds:uhc_spinlock
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

uplElemLoop:
    mov edx,fs:usp_qh
    or edx,edx
    jz uplNext
;
    mov ebx,es:[edx].uqh_va_elem
    or ebx,ebx
    jz uplNext
;
    test fs:usp_flags, USP_FLAG_SINGLE
    jz uplMulti

uplSingle:
    mov eax,es:[edx].uqh_elem
    and al,0F0h
    cmp eax,es:[ebx].utd_phys
    jz uplNext
    jmp uplSignal

uplMulti:    
    test byte ptr es:[edx].uqh_elem,1
    jz uplNext

uplSignal:  
    mov al,1
    xchg al,fs:usp_done
;
    cmp al,1
    je uplNext
;
    mov bx,fs:usbp_signal
    or bx,bx
    jz uplSignalDone
;
    ReleaseSpinlock ds:uhc_spinlock    
    Signal
;
    mov bx,fs:usbp_wait
    or bx,bx
    jz uplRetry
;
    mov es,bx
    SignalWait
    jmp uplRetry

uplSignalDone:
    mov bx,fs:usbp_wait
    or bx,bx
    jz uplNext
;
    ReleaseSpinlock ds:uhc_spinlock    
    mov es,bx
    SignalWait

uplRetry:
    pop di
    pop dx
    pop ebx
    pop fs
    pop es    
    jmp uplLoop

uplNext:    
    mov ax,fs:usp_next
    mov fs,ax
    cmp ax,di
    jne uplElemLoop
;
    pop di
    pop dx
    pop ebx
    pop fs
    pop es    

uplDone:    
    ReleaseSpinlock ds:uhc_spinlock
    pop ax
    ret
UpdatePipeList  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           port_timer
;
;           DESCRIPTION:    Port timer
;
;       PARAMETERS:     
;
;           RETURNS:        
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
    or ds:uhc_status,ax
    out dx,ax
;
    test al,20h
    jz tNonFatal
;
    int 3

tNonFatal:
    call UpdatePipeList
;
    pop ds
    add bx,2
    loop timer_func_loop
;
    pop eax   
    pop edx
;    
    add eax,1193
    adc edx,0
    mov bx,cs
    mov es,bx
    mov bx,cs
    mov edi,OFFSET port_timer
    StartTimer
    retf32
port_timer  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateBlock32
;
;           DESCRIPTION:    Allocate 32-byte block with page-alignment
;
;       PARAMETERS:     ES      Flat sel
;
;           RETURNS:        EDX         Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlock32 PROC near
    push ds
    push eax
;
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:UhciSection
    inc ds:UhciUsedBlocks
    mov edx,ds:UhciList32
    or edx,edx
    jnz allocate_block32_done
;
    push ecx    
    mov eax,1000h
    AllocateBigLinear
;    
    push ebx
    AllocatePhysical32
    or al,67h
    SetPageEntry
    pop ebx
;    
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
;           NAME:           FreeBlock32
;
;           DESCRIPTION:    Free 32-byte block
;
;       PARAMETERS:     ES      Flat sel
;
;           PARAMETERS:         EDX         Data address
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
    dec ds:UhciUsedBlocks
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
;           NAME:           InsertPipe
;
;           DESCRIPTION:    Insert pipe into function pipe-list
;
;       PARAMETERS:     DS      Function
;               FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertPipe  Proc near
    push di
    RequestSpinlock ds:uhc_spinlock
    mov di,ds:uhc_pipe_list
    or di,di
    je ipEmpty
;       
    push ds
    push si
    mov ds,di
    mov si,ds:usp_prev
    mov ds:usp_prev,fs
    mov ds,si
    mov ds:usp_next,fs
    mov fs:usp_next,di
    mov fs:usp_prev,si
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
    ReleaseSpinlock ds:uhc_spinlock
    mov fs:usp_done,0
    ret
InsertPipe  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemovePipe
;
;           DESCRIPTION:    Remove pipe from function pipe-list
;
;       PARAMETERS:     DS      Function
;               FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemovePipe  Proc near
    push si
    push di
;       
    RequestSpinlock ds:uhc_spinlock
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
    ReleaseSpinlock ds:uhc_spinlock
    pop di
    pop si
    ret
RemovePipe  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitQh
;
;           DESCRIPTION:    Initialize a queue header
;
;       PARAMETERS:     ES      Flat sel
;               EDX         QH
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
;    
    push ebx
    GetPageEntry
    or ebx,ebx
    jz iq32
;
    int 3
   
iq32:        
    pop ebx
;    
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
;           NAME:           AllocateQh
;
;           DESCRIPTION:    Allocate & initialize a queue header
;
;       PARAMETERS:     ES      Flat sel
;
;           PARAMETERS:         EDX         QH
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
;
    push ebx
    GetPageEntry
    or ebx,ebx
    jz aq32
;
    int 3

aq32:
    pop ebx
;
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
;           NAME:           AllocateTd
;
;           DESCRIPTION:    Allocate & initialize a TD block
;
;       PARAMETERS:     DS      Function selector
;               ES      Flat sel
;               FS      Pipe
;               EDI     Data buffer
;               CX      Size of data
;
;           PARAMETERS:         EDX         TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTd      PROC near
    push eax
    push ecx
;    
    call AllocateBlock32
    mov es:[edx].utd_link,1
    mov es:[edx].utd_va_link,0
    mov es:[edx].utd_control, 19000000h
    cmp fs:usbp_speed,0
    jnz atSpeedOk
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
    push ebx
    GetPageEntry
    or ebx,ebx
    jz at32
;
    int 3    

at32:    
    pop ebx
;
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
;    
    push ebx
    GetPageEntry
    or ebx,ebx
    jz atd32
;
    int 3    

atd32:    
    pop ebx
;    
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
;           NAME:           InsertElem
;
;           DESCRIPTION:    Insert TD into vertical QH
;
;       PARAMETERS:     ES      Flat sel
;               EDX     QH
;               EAX     TD
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
;           NAME:           InsertTdFirst
;
;           DESCRIPTION:    Insert QH first into TD list
;
;       PARAMETERS:     ES      Flat sel
;               EDX     TD to insert into
;               EAX     QH to link
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
;           NAME:           InsertTdLast
;
;           DESCRIPTION:    Insert QH last into TD list
;
;       PARAMETERS:     ES      Flat sel
;               EDX     TD to insert into
;               EAX     QH to link
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
;           NAME:           Remove
;
;           DESCRIPTION:    Remove QH from TD list
;
;       PARAMETERS:     ES      Flat sel
;               EDX     TD list
;               EAX     QH to delink
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveTd    PROC near
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
;           NAME:           InsertIntr
;
;           DESCRIPTION:    Insert QH into interrupt list
;
;       PARAMETERS:     ES      Flat sel
;               GS:DI   Intr list
;               EAX     QH to link
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
;           NAME:           RemoveIntr
;
;           DESCRIPTION:    Remove QH from interrupt list
;
;       PARAMETERS:     ES      Flat sel
;               GS:DI   Intr list
;               EAX     QH to delink
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
;           NAME:           FreeVaElem
;
;           DESCRIPTION:    Free all Tds in vertical va-linked list
;
;       PARAMETERS:     ES      Flat sel
;               EDX     QH
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
;           NAME:           GetQhDataSize
;
;           DESCRIPTION:    Get data size from transfer
;
;       PARAMETERS:     EDX     Qh
;
;       RETURNS:    CX      Size of data
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
;           NAME:           CreateIntrQueue
;
;           DESCRIPTION:    Create interrupt queue
;
;       PARAMETERS:     DS      Function sel
;               ES      Flat sel
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
    AllocatePhysical32
    or al,67h
    SetPageEntry
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
    GetPageEntry
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
;           NAME:           CreatePeriodTd
;
;           DESCRIPTION:    Create periodic interrupt td
;
;       PARAMETERS:     DS      Function sel
;               ES      Flat sel
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
;           NAME:           GetIntrQh
;
;           DESCRIPTION:    Get interrupt QH
;
;       PARAMETERS:     DS      Function sel
;               ES      Flat sel
;               FS      Pipe sel
;               CL      Interval
;
;       RETURNS:    BX      Offset to count entry
;               DI      Offset to QH list entry to use
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
;           NAME:           CreateControl
;
;           DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CreateControl   Proc far
    push gs
    pushad
;    
    push es
    mov ah,es:usbd_speed
    push ax
    mov ax,es
    mov gs,ax
    mov eax,SIZE uhci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    pop ax
    mov es:usbp_speed,ah
;
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    mov al,13h
    SetPageEntry
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
    mov gs:dev_control_qh,eax
    call InsertTdFirst
    call InsertPipe
;
    pop es
    mov es:dev_curr_address,0
    InitUsbControlPipe
;
    popad
    pop gs
    retf32
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateBulk
;
;           DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       DL      Pipe # (bit 7, IN)
;                       CX      Max data size
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    push es
    pushad
;    
    mov ah,es:usbd_speed
    push ax
    mov eax,SIZE uhci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    pop ax
    mov es:usbp_speed,ah
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
    retf32
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateIntr
;
;           DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       AL      Interval
;                       DL      Pipe # (bit 7, IN)
;                       CX      Max data size
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    push es
    push gs
    pushad
;    
    mov ah,es:usbd_speed
    push ax
    mov eax,SIZE uhci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    pop ax
    mov es:usbp_speed,ah
    mov cl,al
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
    retf32
CreateIntr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddBuffer
;
;           DESCRIPTION:    Allocate input/output buffer
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               EDX     QH
;               CX      Size
;               ES:EDI  Data
;               AL      PID
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
    mov bx,es
    cmp bx,flat_sel
    je abLoop
;    
    push ecx
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
    cmp ax,cx
    jae abLast
;    
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
    jmp abLoop

abLast:    
    call AllocateTd
    mov ax,si
    or byte ptr es:[edx].utd_link,4
    or byte ptr es:[edx].utd_host,al
    or es:[edx].utd_control,800000h
    mov eax,edx
    mov edx,ebp
    call InsertElem       
    
abDone:
    popad
    pop es
    ret
AddBuffer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddOut
;
;           DESCRIPTION:    Add out transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               CX      Buffer size
;               ES:EDI  Buffer
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
    retf32
AddOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddIn
;
;           DESCRIPTION:    Add in transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               CX      Buffer size
;               ES:EDI  Buffer
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
    retf32
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IssueTransfer
;
;           DESCRIPTION:    Issue transfer
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               EDX     Queue handle
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
    mov fs:usp_done,0
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
    retf32
IssueTransfer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalIsTransferDone
;
;           DESCRIPTION:    Check if transfer is done
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalIsTransferDone   Proc near
    push es
    push eax
    push ebx
    push edx
;
    test fs:usp_flags, USP_FLAG_TRANSFER_PENDING
    jz itdOk
;    
    IsUsbPipeConnected
    jc itdOk
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov al,fs:usp_done
    or al,al
    jz itdFail
;    
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je itdControlBulk
;
    cmp al,MODE_BULK
    jne itdOk

itdControlBulk:
    mov edx,fs:usp_qh
;
    test fs:usp_flags, USP_FLAG_SINGLE
    jz itdMulti

itdSingle:
    mov eax,es:[edx].uqh_va_elem
    test es:[eax].utd_control,400000h    
    jnz itdRecover
;
    mov ebx,es:[edx].uqh_elem
    and bl,0F0h
    cmp ebx,es:[eax].utd_phys
    jz itdFail
    jmp itdOk

itdMulti:
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
    pop ebx
    pop eax
    pop es
    ret
LocalIsTransferDone   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsTransferDone
;
;           DESCRIPTION:    Check if transfer is done
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsTransferDone   Proc far
    call LocalIsTransferDone
    retf32
IsTransferDone   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForCompletion
;
;           DESCRIPTION:    Wait for transfer to complete
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion   Proc far
    push eax
;
    test fs:usp_flags, USP_FLAG_TRANSFER_PENDING
    jz wfcDone

wfcWait:
    call LocalIsTransferDone
    jnc wfcDone
;
    WaitForSignal
    jmp wfcWait

wfcDone:
    call LocalEndTransfer
;    
    pop eax
    retf32
WaitForCompletion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WasTransferOk
;
;           DESCRIPTION:    Check if last transfer was ok
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;       RETURNS:    NC      Transfer was ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WasTransferOk   Proc far
    test fs:usp_flags, USP_FLAG_TRANSFER_PENDING
    jz wtoNotPending
;
    call LocalEndTransfer

wtoNotPending:
    test fs:usp_flags, USP_FLAG_TRANSFER_OK
    jnz wtoOk
;    
    stc
    jmp wtoDone

wtoOk:
    clc

wtoDone:
    retf32
WasTransferOk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalEndTransfer
;
;           DESCRIPTION:    End transfer and get input data
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalEndTransfer   Proc near
    push es
    push ax
    push ecx
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
    pop ecx
    pop ax
    pop es
    ret
LocalEndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EndTransfer
;
;           DESCRIPTION:    End transfer and get input data
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndTransfer   Proc far
    call LocalEndTransfer
    retf32
EndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDataSize
;
;           DESCRIPTION:    Get input data size for last transfer
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;       RETURNS:    CX      Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDataSize   Proc far
    xor cx,cx
    test fs:usp_flags, USP_FLAG_TRANSFER_OK
    jz gdsDone
;    
    mov cx,fs:usp_data_size

gdsDone:
    retf32
GetDataSize   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClosePipe
;
;           DESCRIPTION:    Close pipe
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePipe   Proc far
    push es
    push eax
    push edx
;    
    push ds
    mov ax,SEG data
    mov ds,ax
    inc ds:UhciCloseCount
    pop ds
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
    mov edx,fs:usp_qh
    call FreeVaElem
;
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
    retf32
ClosePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ChangeAddress
;
;           DESCRIPTION:    Change address for pipe
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    push ax
    mov al,es:usbd_address
    mov es:dev_curr_address,al
    pop ax
    retf32
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsConnected
;
;           DESCRIPTION:    Check if pipe is connected
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsConnected   Proc far
    push es
    push ax
    push dx
    push si
;    
    mov es,fs:usbp_dev_sel
    movzx si,es:usbd_port
;    
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,si
    add dx,si
;
    in ax,dx
    test al,1
    jz icFail
;
    test ax,200h
    clc
    jz icDone

icFail:
    stc

icDone:
    pop si
    pop dx
    pop ax
    pop es
    retf32
IsConnected   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetDev
;
;           DESCRIPTION:    Reset device
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetDev   Proc far
    push ax
    push cx
;    
    mov cl,es:usbd_port
    mov ax,1
    shl ax,cl
    lock or ds:uhc_reset,ax
;
    pop cx
    pop ax
    retf32
ResetDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockEnum
;
;           DESCRIPTION:    Lock enumeration process
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockEnum   Proc far
    EnterSection ds:uhc_section
    retf32
LockEnum   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockEnum
;
;           DESCRIPTION:    Unlock enumeration process
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockEnum   Proc far
    LeaveSection ds:uhc_section
    retf32
UnlockEnum   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Has64Bit
;
;           DESCRIPTION:    Check for 64-bit support
;
;       PARAMETERS:         DS      Function selector
;
;       RETURNS:            NC      Supports 64-bit addresses
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Has64Bit   Proc far
    stc
    retf32
Has64Bit     Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsStalled
;
;           DESCRIPTION:    Check if pipe is stalled
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsStalled   Proc far
    int 3
    clc
    retf32
IsStalled   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearStalled
;
;           DESCRIPTION:    Clear stalled pipe
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearStalled   Proc far
    int 3
    retf32
ClearStalled   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateMaxLen
;
;           DESCRIPTION:    Update max len
;
;           PARAMETERS:     ES      Device selector
;                           AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMaxLen   Proc far
    retf32
UpdateMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IssueOne
;
;           DESCRIPTION:    Issue one transfer
;
;       PARAMETERS:         FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueOne   Proc far
    push es
    push eax
    push ecx
    push edx
;    
    mov ax,flat_sel
    mov es,ax    
    mov edx,fs:usp_qh
;    
    mov fs:usp_done,0
    test fs:usp_flags, USP_FLAG_SINGLE
    jnz iotNew
;
    and fs:usp_flags, NOT USP_FLAG_TRANSFER_OK
    or fs:usp_flags, USP_FLAG_TRANSFER_PENDING OR USP_FLAG_SINGLE
;    
    mov eax,es:[edx].uqh_va_elem    
    or eax,eax
    jz iotDone
;    
    mov eax,es:[eax].utd_phys
    mov es:[edx].uqh_elem,eax
    jmp iotDone

iotNew:
    mov ecx,es:[edx].uqh_va_elem    
    or ecx,ecx
    jz iotDone
;
    mov eax,es:[ecx].utd_va_link
    mov es:[edx].uqh_va_elem,eax
;
    mov edx,ecx
    call FreeBlock32

iotDone:
    pop edx 
    pop ecx
    pop eax
    pop es
    retf32
IssueOne   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsDeviceConnected
;
;           DESCRIPTION:    Check if device is connected
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsDeviceConnected   Proc far
    push ax
    push dx
    push si
;    
    movzx si,es:usbd_port    
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,si
    add dx,si
;
    in ax,dx
    test al,1
    stc
    jz idcDone
;
    test al,4
    stc
    jz idcDone
;
    mov dx,ds:uhc_io_base
    add dx,UsbStatusReg
    in ax,dx
    test al,20h
    stc
    jnz idcDone
;
    clc

idcDone:
    pop si
    pop dx
    pop ax
    retf32
IsDeviceConnected   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControl
;
;       DESCRIPTION:    Setup control msg
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControl   Proc near
    push eax
    push ebx
    push edx
;
    mov edx,es:dev_control_head
    mov fs:[edx].utd_link,5
    mov fs:[edx].utd_va_link,0
;
    mov eax,es:dev_utd_control
    mov fs:[edx].utd_control,eax
;
    mov eax,7 SHL 21
    or ah,es:dev_curr_address
    mov al,PID_SETUP
    mov fs:[edx].utd_host,eax
;
    mov ebx,OFFSET usbd_control_buf
    mov eax,ebx
    add eax,es:mblk_physical_base
    mov fs:[edx].utd_buf,eax
;
    pop edx
    pop ebx
    pop eax
    ret
SetupControl	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControlIn
;
;       DESCRIPTION:    Setup control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControlIn   Proc near
    pushad
;
    mov esi,es:dev_control_head
    or cx,cx
    jz sciStatusOut
;
    mov ebp,80000h 

sciLoop:
    push cx
    mov cx,SIZE uhci_td
    AllocateMemBlk
    pop cx
    jc sciDone
;
    or al,4
    mov fs:[esi].utd_link,eax
    mov fs:[esi].utd_va_link,edx
    mov esi,edx
;
    mov fs:[esi].utd_link,5
    mov fs:[esi].utd_va_link,0
;
    mov eax,es:dev_utd_control
    mov fs:[esi].utd_control,eax
    mov fs:[esi].utd_host,0
;
    mov bx,cx
    cmp bx,es:usbd_maxlen
    jb sciInMinOk
;
    mov bx,es:usbd_maxlen

sciInMinOk:
    push bx
    push cx
    mov cx,bx
    AllocateMemBlk
    pop cx
    pop bx
    jc sciDone
;
    mov fs:[esi].utd_buf,eax
    movzx eax,bx
    dec ax
    shl eax,21
    or eax,ebp
    or ah,es:dev_curr_address
    mov al,PID_IN
    mov fs:[esi].utd_host,eax
;
    xor ebp,80000h 
    sub cx,bx
    jnz sciLoop

sciStatusOut: 
    mov cx,SIZE uhci_td
    AllocateMemBlk
    jc sciDone
;
    or al,4
    mov fs:[esi].utd_link,eax
    mov fs:[esi].utd_va_link,edx
    mov esi,edx
;
    mov fs:[esi].utd_link,5
    mov fs:[esi].utd_va_link,0
;
    mov eax,es:dev_utd_control
    mov fs:[esi].utd_control,eax
;
    mov eax,0FFE80000h
    or ah,es:dev_curr_address
    mov al,PID_OUT
    mov fs:[esi].utd_host,eax
    mov fs:[esi].utd_buf,0
    clc

sciDone:
    popad
    ret
SetupControlIn	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CopyControlIn
;
;       DESCRIPTION:    Copy control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;                       GS:EDI  Buffer
;
;       RETURNS:        CX      Size returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyControlIn   Proc near
    push eax
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    xor cx,cx
    mov esi,es:dev_control_head
    mov eax,fs:[esi].utd_control
    cmp ax,7
    stc 
    jne cciDone
;
    shr eax,16
    test al,40h
    stc
    jne cciDone
;
    mov esi,fs:[esi].utd_va_link

cciCopyLoop:
    or esi,esi
    clc
    jz cciDone
;
    mov eax,fs:[esi].utd_control
    mov bp,ax
    inc bp
    shr eax,16
    test al,40h
    stc
    jne cciDone
;
    mov eax,fs:[esi].utd_buf
    or eax,eax
    jz cciCopyNext
;
    xor ebx,ebx
    PhysicalToLinearMemBlk
    jc cciCopyNext
;
    push es
    push ecx
    push esi
    mov ax,gs
    mov es,ax
    mov esi,edx
    movzx ecx,bp
    rep movs byte ptr es:[edi],fs:[esi]
    pop esi
    pop ecx
    pop es
;
    add cx,bp

cciCopyNext:
    xchg edx,esi
    mov esi,fs:[edx].utd_va_link
    jmp cciCopyLoop

cciDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret
CopyControlIn	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControlOut
;
;       DESCRIPTION:    Setup control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;                       GS:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControlOut  Proc near
    pushad
;
    mov esi,edi
    mov edi,es:dev_control_head
    or cx,cx
    jz scoStatusIn
;
    mov ebp,80000h 

scoLoop:
    push cx
    mov cx,SIZE uhci_td
    AllocateMemBlk
    pop cx
    jc scoDone
;
    or al,4
    mov fs:[edi].utd_link,eax
    mov fs:[edi].utd_va_link,edx
    mov edi,edx
;
    mov fs:[edi].utd_link,5
    mov fs:[edi].utd_va_link,0
;
    mov eax,es:dev_utd_control
    mov fs:[edi].utd_control,eax
    mov fs:[edi].utd_host,0
;
    mov bx,cx
    cmp bx,es:usbd_maxlen
    jb scoOutMinOk
;
    mov bx,es:usbd_maxlen

scoOutMinOk:
    push bx
    push cx
    mov cx,bx
    AllocateMemBlk
    pop cx
    pop bx
    jc scoDone
;
    mov fs:[edi].utd_buf,eax
    movzx eax,bx
    dec ax
    shl eax,21
    or eax,ebp
    or ah,es:dev_curr_address
    mov al,PID_OUT
    mov fs:[edi].utd_host,eax
;
    push es
    push ecx
    push edi
;
    mov ax,fs
    mov es,ax
    mov edi,edx
    movzx ecx,bx
    rep movs byte ptr es:[edi],gs:[esi]
;
    pop edi
    pop ecx
    pop es
;
    xor ebp,80000h 
    sub cx,bx
    jnz scoLoop

scoStatusIn: 
    mov cx,SIZE uhci_td
    AllocateMemBlk
    jc scoDone
;
    or al,4
    mov fs:[edi].utd_link,eax
    mov fs:[edi].utd_va_link,edx
    mov edi,edx
;
    mov fs:[edi].utd_link,5
    mov fs:[edi].utd_va_link,0
;
    mov eax,es:dev_utd_control
    mov fs:[edi].utd_control,eax
;
    mov eax,0FFE80000h
    or ah,es:dev_curr_address
    mov al,PID_IN
    mov fs:[edi].utd_host,eax
    mov fs:[edi].utd_buf,0
    clc

scoDone:
    popad
    ret
SetupControlOut	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckControlOut
;
;       DESCRIPTION:    Copy control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckControlOut   Proc near
    pushad
;
    mov esi,es:dev_control_head
    mov eax,fs:[esi].utd_control
    cmp ax,7
    stc 
    jne ccoDone
;
    shr eax,16
    test al,40h
    stc
    jne ccoDone
;
    mov esi,fs:[esi].utd_va_link

ccoLoop:
    or esi,esi
    clc
    jz ccoDone
;
    mov eax,fs:[esi].utd_control
    shr eax,16
    test al,40h
    stc
    jne ccoDone

ccoNext:
    xchg edx,esi
    mov esi,fs:[edx].utd_va_link
    jmp ccoLoop

ccoDone:
    popad
    ret
CheckControlOut	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunControl
;
;       DESCRIPTION:    Run control
;
;       PARAMETERS:     DS      Usb function
;                       ES      Usb device
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunControl   Proc near
    pushad
;
    mov edx,es:dev_control_head
    LinearToPhysicalMemBlk
    mov edx,es:dev_control_qh
    mov fs:[edx].uqh_elem,eax
;
    movzx si,es:usbd_port
    add si,si
    add si,ds:uhc_io_base
    add si,PortscReg1
;
    mov cx,100

rcWait:
    mov ax,4
    WaitMilliSec
;
    call fword ptr ds:is_dev_connected_proc
    jc rcDone
;
    mov edx,es:dev_control_head
    test fs:[edx].uqh_elem,1
    clc
    jnz rcDone
;
    loop rcWait
;
    stc

rcDone:
    popad
    ret
RunControl  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CleanupControl
;
;       DESCRIPTION:    Cleanup control
;
;       PARAMETERS:     DS      Usb function
;                       ES      Usb device
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupControl   Proc near
    pushad
;
    mov esi,es:dev_control_head
    mov esi,fs:[esi].utd_va_link

ccLoop:
    or esi,esi
    jz ccDone
;
    mov eax,fs:[esi].utd_buf
    or eax,eax
    jz ccBufferOk
;
    mov ecx,fs:[esi].utd_host
    shr ecx,21
    inc cx
    xor ebx,ebx
    FreePhysicalMemBlk

ccBufferOk:
    xchg edx,esi
    mov esi,fs:[edx].utd_va_link
;
    mov cx,SIZE uhci_td
    FreeLinearMemBlk
    jmp ccLoop

ccDone:
    popad
    ret
CleanupControl  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ControlMsg
;
;       DESCRIPTION:    Send message over control pipe
;
;       PARAMETERS:     ES      Usb device
;                       GS:EDI  Buffer
;
;       RETURNS:        NC      OK
;                          CX   Transfer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ControlMsg   Proc far
    push fs
    push eax
;
    mov cx,es:usbd_control_buf.usd_len
    mov ax,flat_sel
    mov fs,ax
;
    call SetupControl
;
    test es:usbd_control_buf.usd_type,80h
    jz cmDataOut
;
    call SetupControlIn
    jc cmFail
;
    call RunControl
    jc cmFail
;
    call CopyControlIn
;
    pushf
    call CleanupControl
    popf
    jmp cmDone

cmDataOut:
    call SetupControlOut
    jc cmFail
;
    call RunControl
    jc cmFail
;
    call CheckControlOut
    jc cmFail
;
    call CleanupControl
    clc
    jmp cmDone

cmFail:
    push edx
    mov edx,es:dev_control_qh
    mov eax,1
    xchg eax,fs:[edx].uqh_elem
    test al,1
    pop edx
    jnz cmCleanFail
;
    mov ax,25
    WaitMilliSec

cmCleanFail:
    call CleanupControl
    stc

cmDone:
    pop eax
    pop fs
    retf32
ControlMsg   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           PollPipe
;
;       DESCRIPTION:    Poll pipe
;
;       PARAMETERS:     FS      Pipe selector
;
;       RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollPipe   Proc far
    int 3
    retf32
PollPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadPipe
;
;       DESCRIPTION:    Read pipe
;
;       PARAMETERS:     FS        Pipe selector
;                       EAX       Timeout i ms
;                       ES:EDI    Buffer
;                       CX        Max size
;
;       RETURNS:        NC        OK
;                           CX    Actual size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPipe   Proc far
    int 3
    retf32
ReadPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WritePipe
;
;       DESCRIPTION:    Write pipe
;
;       PARAMETERS:     FS        Pipe selector
;                       EAX       Timeout i ms
;                       ES:EDI    Buffer
;                       CX        Size
;
;       RETURNS:        NC        OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePipe   Proc far
    int 3
    retf32
WritePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateAddress
;
;       DESCRIPTION:    Allocate address
;
;       PARAMETERS:     DS      Function sel
;
;       RETURNS:        AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateAddress   Proc far
    AllocateUsbAddress
    retf32
AllocateAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeAddress
;
;       DESCRIPTION:    Free address
;
;       PARAMETERS:     DS      Function sel
;                       AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeAddress   Proc far
    FreeUsbAddress
    retf32
FreeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               CreateDev
;
;       DESCRIPTION:        Create device sel
;
;       PARAMETERS:         DS      Function selector
;                           AL      Address
;                           AH      Speed
;                           BX      Hub selector
;                           DX      Port #
;
;       RETURNS:            ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDev   Proc far
    pushad
;
    mov ax,SIZE uhci_td
    mov si,SIZE uhci_dev_sel
    mov cx,16
    CreateMemBlk32
;
    popad
;
    InitUsbDev
;
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;    
    mov cx,SIZE uhci_td
    AllocateMemBlk
    mov fs:[edx].utd_link,0
    mov fs:[edx].utd_control,0
    mov fs:[edx].utd_host,0
    mov fs:[edx].utd_buf,0
    mov fs:[edx].utd_va_link,0
    mov fs:[edx].utd_phys,0
    mov es:dev_control_head,edx
;
    mov eax,18800000h
    cmp es:usbd_speed,0
    jnz cdSpeedOk
;
    or eax, 4000000h
    
cdSpeedOk:
    mov es:dev_utd_control,eax
;
    popad
    pop fs
    retf32
CreateDev  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               FreeDev
;
;       DESCRIPTION:        Free device sel
;
;       PARAMETERS:         ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDev   Proc far
    FreeMemBlk
    retf32
FreeDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               AddressDev
;
;       DESCRIPTION:        Address usb dev
;
;       PARAMETERS:         DS      Function selector
;                           AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddressDev   Proc far
    AddressUsbDev    
    retf32
AddressDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               ConfigDev
;
;       DESCRIPTION:        Config usb dev
;
;       PARAMETERS:         DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigDev   Proc far
    clc
    retf32
ConfigDev   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandlerThread
;
;   DESCRIPTION:    Handler thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..OHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handler_thread_name  DB 'UHCI Dev ', 0

handler_thread:
    mov ds,bx
    mov cl,dl
    mov bl,dl
;    
    movzx di,cl
    add di,di
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[di].usb_thread_arr,ax
    LeaveSection ds:usb_section
;
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,di    

htTryAttach:
    in ax,dx
    or ax,200h
    out dx,ax
;
    mov ax,50
    WaitMilliSec
;
    LockUsb
;
    in ax,dx
    and ax,NOT 200h
    out dx,ax
;
    push cx
    mov cx,10

htLoop:
    in ax,dx
    test ax,4
    clc
    jnz htNotify
;
    or ax,4
    out dx,ax
    loop htLoop
;
    pop cx
    jmp htUnlock

htNotify:
    pop cx
;    
    mov ax,200
    WaitMilliSec
;
    in ax,dx
    test al,1
    jz htUnlock
;
    xor ah,1
    and ah,1
    mov bh,ah
;
    call fword ptr ds:allocate_address_proc
    jc htUnlock
;
    push bx
    push dx
;
    mov ah,bh
    movzx dx,bl
    xor bx,bx
    call fword ptr ds:create_dev_proc
;
    pop dx
    pop bx
;
    call fword ptr ds:create_control_proc
    call fword ptr ds:address_device_proc
    jc htUnlock
;
    call fword ptr ds:change_address_proc
    AddUsbDevice
    UnlockUsb
    ReadUsbDescriptors
    jc htDetach
;
    mov al,bl
    NotifyUsbAttach

htAttached:
    WaitForSignal
;
    call fword ptr ds:is_dev_connected_proc
    jc htDetach
;
    mov cl,bl
    mov ax,1
    shl ax,cl
    test ax,ds:uhc_reset
    jz htHandle
;
    not ax
    lock and ds:uhc_reset,ax
    jmp htDetach

htHandle:
    jmp htAttached

htUnlock:
    in ax,dx
    test al,1
    jz htDoUnlock
;
    in ax,dx
    and al,NOT 4
    out dx,ax
;
    mov ax,25
    WaitMilliSec

htDoUnlock:
    UnlockUsb
    jmp htDetached

htDetach:
    mov al,bl
    NotifyUsbDetach
;
    in ax,dx
    test al,1
    jz htDone
;
    in ax,dx
    and al,NOT 4
    out dx,ax
;
    mov ax,25
    WaitMilliSec

htDetached:
    in ax,dx
    test al,1
    jnz htTryAttach

htDone:    
    in ax,dx
    or al,4
    out dx,ax
;
    EnterSection ds:usb_section
    mov ds:[di].usb_thread_arr,0
    LeaveSection ds:usb_section
;
    TerminateThread
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HexToAscii
;
;   DESCRIPTION:    
;
;   PARAMETERS:     AL      Number to convert
;
;   RETURNS:        AX      Ascii result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HexToAscii      PROC near
    mov ah,al
    and al,0F0h
    rol al,1
    rol al,1
    rol al,1
    rol al,1
    cmp al,0Ah
    jb ok_low1
;
    add al,7

ok_low1:
    add al,30h
    and ah,0Fh
    cmp ah,0Ah
    jb ok_high1
;
    add ah,7

ok_high1:
    add ah,30h
    ret
HexToAscii      ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdatePort
;
;           DESCRIPTION:    Update root-hub port status
;
;       PARAMETERS:     DS      Function selector
;               CL      Port # (0,1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push ds
    push es
    push fs
    pushad
;    
    movzx si,cl
    add si,si
    movzx edi,cl
    add edi,edi
;    
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,si
;    
    in ax,dx
    test al,1
    jz upDetach

upAttach:
    mov bx,ds:[edi].usb_thread_arr
    or bx,bx
    jnz upCheckReset
;
    mov ds:[edi].usb_thread_arr,-1
;    
    mov bx,ds
    mov dx,cx
;
    mov esi,OFFSET handler_thread_name
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi

upCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz upCopyDone
;
    stosb
    jmp upCopyLoop

upCopyDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,cl
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;   
    xor edi,edi
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET handler_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    FreeMem
    jmp upDone

upCheckReset:
    mov ax,1
    shl ax,cl
    test ax,ds:uhc_reset
    jz upDone
;
    Signal
    jmp upDone

upDetach:
    EnterSection ds:usb_section
    mov bx,ds:[edi].usb_thread_arr
    or bx,bx
    jz upLeave
;    
    Signal

upLeave:
    LeaveSection ds:usb_section

upDone:    
    popad
    pop fs
    pop es
    pop ds
    ret
UpdatePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           BiosHandoff
;
;           DESCRIPTION:    Do BIOS handoff
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BiosHandoff    Proc near
    pushad
;
    mov bx,ds:uhc_pci_bus_dev
    mov ch,ds:uhc_pci_func
    mov cl,0C0h
    mov ax,8F00h
    WritePciWord    
;
    popad
    ret
BiosHandoff Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitFunction
;
;           DESCRIPTION:    Init UHCI function
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uhci_tab:
ut00 DD OFFSET AllocateAddress,     SEG code
ut01 DD OFFSET FreeAddress,         SEG code
ut02 DD OFFSET CreateDev,           SEG code
ut03 DD OFFSET FreeDev,             SEG code
ut04 DD OFFSET CreateControl,       SEG code
ut05 DD OFFSET CreateBulk,          SEG code
ut06 DD OFFSET CreateIntr,          SEG code
ut07 DD OFFSET AddOut,              SEG code
ut08 DD OFFSET AddIn,               SEG code
ut09 DD OFFSET IssueTransfer,       SEG code
ut0A DD OFFSET IsTransferDone,      SEG code
ut0B DD OFFSET EndTransfer,         SEG code
ut0C DD OFFSET WasTransferOk,       SEG code
ut0D DD OFFSET GetDataSize,         SEG code
ut0E DD OFFSET ClosePipe,           SEG code
ut0F DD OFFSET WaitForCompletion,   SEG code
ut10 DD OFFSET ChangeAddress,       SEG code
ut11 DD OFFSET IsConnected,         SEG code
ut12 DD OFFSET ResetDev,            SEG code
ut13 DD OFFSET LockEnum,            SEG code
ut14 DD OFFSET UnlockEnum,          SEG code
ut15 DD OFFSET Has64Bit,            SEG code
ut16 DD OFFSET IsStalled,           SEG code
ut17 DD OFFSET ClearStalled,        SEG code
ut18 DD OFFSET AddressDev,          SEG code
ut19 DD OFFSET ConfigDev,           SEG code
ut1A DD OFFSET UpdateMaxLen,        SEG code
ut1B DD OFFSET IssueOne,            SEG code
ut1C DD OFFSET IsDeviceConnected,   SEG code
ut1D DD OFFSET ControlMsg,          SEG code
ut1E DD OFFSET PollPipe,            SEG code
ut1F DD OFFSET ReadPipe,            SEG code
ut20 DD OFFSET WritePipe,           SEG code

InitFunction    Proc near
    push ds
    push es
    push fs
    pushad
;
    mov bx,ds:uhc_pci_bus_dev
    mov ch,ds:uhc_pci_func
    cmp ch,2
    jne ifNotLegacy
;
    mov cl,0C0h
    xor ax,ax
    WritePciWord   
    
ifNotLegacy:    

ifIntDone:
    mov si,OFFSET uhci_tab
    xor di,di
    mov cx,2*21h

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbFunction
;
    WaitForEhci
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
    mov ax,200
    WaitMilliSec
    WaitForEhci
;
    mov dx,ds:uhc_io_base
    add dx,UsbCommandReg
    in ax,dx
    and ax,NOT 4
    out dx,ax
;
    mov dx,ds:uhc_io_base
    add dx,UsbIntReg
    xor ax,ax
    out dx,ax
;
    mov dx,ds:uhc_io_base
    add dx,UsbStatusReg
    in ax,dx
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
    pop fs
    pop es
    pop ds
    ret
InitFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddFunction
;
;           DESCRIPTION:    Add UHCI function
;
;       PARAMETERS:     BX      Bus/device
;               CH      Function
;               DX      IO base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFunction  Proc near
    push ds
    push es
    pushad
;    
    push cx
    mov eax,SIZE uhci_func_sel
    AllocateSmallGlobalMem
    mov cx,ax
    xor al,al
    xor di,di
    rep stosb
    pop cx
;    
    mov ax,es
    mov ds,ax
    mov ds:uhc_io_base,dx
    mov ds:uhc_pci_bus_dev,bx
    mov ds:uhc_pci_func,ch
    mov ds:uhc_pipe_list,0
    InitSpinlock ds:uhc_spinlock
    mov ds:uhc_reset,0
    InitSection ds:uhc_section
;    
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    or al,7
    SetPageEntry
;    
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
    GetPageEntry
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
;           NAME:           PollFunction
;
;           DESCRIPTION:    Poll UHCI function
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollFunction  Proc near
    pusha
;    
    mov cl,0
    call UpdatePort
;    
    mov cl,1
    call UpdatePort
;
    popa
    ret
PollFunction    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPciAdapter  Proc near
    xor ax,ax
    mov bh,0Ch
    mov bl,3
    mov ch,0
    FindPciClass
    jc init_pci_done
;
    mov cl,20h
    ReadPciDword
    mov dx,ax
    and dx,0FFE0h
    mov bp,ax
    call AddFunction
;       
    mov dx,1

init_pci_next_device:
    mov ax,dx
    mov bh,0Ch
    mov bl,3
    mov ch,0
    FindPciClass
    jc init_pci_done
;       
    mov cl,20h
    ReadPciDword
    cmp ax,bp
    je init_pci_done
;       
    push dx
    mov dx,ax
    and dx,0FFE0h
    call AddFunction
    pop dx
    inc dx
    jmp init_pci_next_device
    
init_pci_done:
    ret
InitPciAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UHCI thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uhci_name       DB 'UHCI',0

uhci_thread:
    mov ax,SEG data
    mov ds,ax
    GetThread
;    
    mov si,OFFSET UhciFunc
    mov cx,ds:UhciCount 

utHandoffLoop:
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
    call BiosHandoff
;
    pop si
    pop cx    
    pop ds
;
    add si,2
    loop utHandoffLoop
;    
    mov ax,50
    WaitMilliSec
;
    mov ds:Started,1
;
    EnterSection ds:WaitSection
    mov bx,ds:WaitThreadArr
    Signal
    mov bx,ds:WaitThreadArr+2
    Signal
    mov bx,ds:WaitThreadArr+4
    Signal
    LeaveSection ds:WaitSection 
;    
    mov bx,OFFSET UhciFunc
    mov cx,ds:UhciCount 

uhci_func_loop:
    push ds
    push bx
    push cx
    mov ds,[bx]
    call InitFunction
    pop cx
    pop bx
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
    mov edi,OFFSET port_timer
    StartTimer

uhci_handle_loop:
    mov ax,250
    WaitMilliSec
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_usb
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_usb    Proc far
    push ds
    push es
    pusha
;    
    mov ax,SEG data
    mov ds,ax
    call InitPciAdapter    
    mov cx,ds:UhciCount 
    or cx,cx
    jz init_usb_done
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET uhci_name
    mov si,OFFSET uhci_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread

init_usb_done:
    popa
    pop es
    pop ds
    retf32
init_usb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetAllocatedUsbBlocks
;
;           DESCRIPTION:    Get allocated USB blocks
;
;       PARAMETERS:     
;
;           RETURNS:        EAX     Number of blocks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_allocated_usb_blocks_name       DB 'Get Allocated USB Blocks',0

get_allocated_usb_blocks    Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov eax,ds:UhciUsedBlocks
    pop ds
    retf32
get_allocated_usb_blocks    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetUsbClosedCount
;
;           DESCRIPTION:    Get closed count
;
;       PARAMETERS:     
;
;           RETURNS:        EAX     Number of blocks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_close_count_name       DB 'Get USB Close Count',0

get_usb_close_count    Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov eax,ds:UhciCloseCount
    pop ds
    retf32
get_usb_close_count    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForUhci
;
;           DESCRIPTION:    Wait for UHCI to initialize
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_uhci_name  DB 'Wait For Uhci', 0

wait_for_uhci   Proc far
    push ds
    push ax
    push bx
;
    mov ax,SEG data
    mov ds,ax
;
    EnterSection ds:WaitSection
    mov al,ds:Started
    or al,al
    jnz wfuDone    
;
    mov bx,OFFSET WaitThreadArr

wfuLoop:
    mov ax,ds:[bx]
    or ax,ax
    jz wfuFound
;
    add bx,2
    jmp wfuLoop

wfuFound:        
    GetThread
    mov ds:[bx],ax    
    LeaveSection ds:WaitSection   

wfuSignal:
    WaitForSignal
;    
    EnterSection ds:WaitSection    
    mov al,ds:Started
    or al,al
    jz wfuSignal
    
wfuDone:
    LeaveSection ds:WaitSection
;    
    pop bx
    pop ax
    pop ds
    retf32
wait_for_uhci   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov bx,SEG data
    mov ds,bx
    InitSection ds:UhciSection
    mov ds:UhciUsedBlocks,0
    mov ds:UhciCloseCount,0
;
    InitSection ds:WaitSection
    mov ds:WaitThreadArr,0
    mov ds:WaitThreadArr+2,0
    mov ds:WaitThreadArr+4,0
    mov ds:Started,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET wait_for_uhci
    mov edi,OFFSET wait_for_uhci_name
    xor cl,cl
    mov ax,wait_for_uhci_nr
    RegisterOsGate
;    
    mov edi,OFFSET init_usb
    HookInitPci
;
    mov esi,OFFSET get_allocated_usb_blocks
    mov edi,OFFSET get_allocated_usb_blocks_name
    xor dx,dx
    mov ax,get_allocated_usb_blocks_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_usb_close_count
    mov edi,OFFSET get_usb_close_count_name
    xor dx,dx
    mov ax,get_usb_close_count_nr
    RegisterBimodalUserGate
    clc
    ret
Init    Endp

code ENDS

    END init
