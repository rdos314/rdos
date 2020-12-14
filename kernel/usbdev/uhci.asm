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
int_per_td      DB 32 DUP(?)

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

uhc_thread       DW ?

uhc_io_base      DW ?

uhc_pci_bus_dev  DW ?
uhc_pci_func     DB ?
uhc_irq          DB ?

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


; this structure is always allocated as 32 bytes!

uhci_td STRUC

utd_link    DD ?
utd_control DD ?
utd_host    DD ?
utd_buf     DD ?

utd_va_link DD ?

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
;           NAME:           UhciInt
;
;           DESCRIPTION:    UHCI interrupt
;
;       PARAMETERS:     DS      Register selector
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UhciInt Proc far
    mov dx,ds:uhc_io_base
    add dx,UsbStatusReg
;
    in ax,dx    
    or ds:uhc_status,ax
    out dx,ax
;
    mov bx,ds:uhc_thread
    Signal
;
    retf32
UhciInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitIntrQh
;
;       DESCRIPTION:    Initialize a queue header in interrupt list
;
;       PARAMETERS:     ES      Flat sel
;                       EDX         QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitIntrQh  PROC near
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
InitIntrQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateIntrQueue
;
;       DESCRIPTION:    Create interrupt queue
;
;       PARAMETERS:     DS      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntrQueue PROC near
    push fs
    push gs
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
    call InitIntrQh
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
    call InitIntrQh
    
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
    call InitIntrQh
    
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
    call InitIntrQh
    
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
    call InitIntrQh
    
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
    call InitIntrQh
    
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
    call InitIntrQh
    mov fs:[bx].uqh_link,eax
    mov fs:[bx].uqh_va_link,edx
    add bx,32
    loop ci1Loop
;
    mov eax,OFFSET int_per_td
    mov edx,eax
    add edx,ds:uhc_int_linear
    add eax,ds:uhc_int_phys
    mov ds:uhc_period_td,edx
;
    mov es:[edx].utd_link,1
    mov es:[edx].utd_va_link,0
    mov es:[edx].utd_control, 18000000h
    mov es:[edx].utd_host,0
    mov es:[edx].utd_buf,0
;    
    mov bx,OFFSET int_1_qh
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
    pop gs
    pop fs
    ret
CreateIntrQueue Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InsertTdFirst
;
;       DESCRIPTION:    Insert QH first into TD list
;
;       PARAMETERS:     FS      Flat sel
;                       EDX     TD to insert into
;                       EAX     QH to link
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertTdFirst   PROC near
    push ecx
;
    mov ecx,fs:[edx].utd_va_link
    or ecx,ecx
    jz itdEmpty
;
    mov fs:[eax].uqh_va_link,ecx
    mov ecx,fs:[edx].utd_link
    mov fs:[eax].uqh_link,ecx
;
    mov fs:[edx].utd_va_link,eax
    mov ecx,fs:[eax].uqh_phys
    or cl,2
    mov fs:[edx].utd_link,ecx    
    jmp itdDone
    
itdEmpty:
    mov fs:[eax].uqh_va_link,0
    mov fs:[eax].uqh_link,1
    mov fs:[edx].utd_va_link,eax
    mov ecx,fs:[eax].uqh_phys
    or cl,2
    mov fs:[edx].utd_link,ecx

itdDone:
    pop ecx
    ret
InsertTdFirst  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InsertTdLast
;
;       DESCRIPTION:    Insert QH last into TD list
;
;       PARAMETERS:     FS      Flat sel
;                       EDX     TD to insert into
;                       EAX     QH to link
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertTdLast    PROC near
    push edx
    push ecx
;
    mov fs:[eax].uqh_va_link,0
    mov fs:[eax].uqh_link,1
;
    mov edx,fs:[edx].utd_va_link    

itlLoop:
    mov ecx,fs:[edx].uqh_va_link
    or ecx,ecx
    jz itlDo
;
    mov edx,ecx
    jmp itlLoop

itlDo:
    mov ecx,fs:[eax].uqh_phys
    or cl,2
    mov fs:[edx].uqh_link,ecx
    mov fs:[edx].uqh_va_link,eax
;    
    pop edx
    pop ecx
    ret
InsertTdLast  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Remove
;
;       DESCRIPTION:    Remove QH from TD list
;
;       PARAMETERS:     FS      Flat sel
;                       EDX     TD list
;                       EAX     QH to delink
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveTd    PROC near
    push ebx
    push ecx
    push edx
;
    mov ecx,fs:[edx].utd_va_link
    cmp ecx,eax
    jne rtdSearch
;
    mov ecx,fs:[eax].uqh_va_link
    or ecx,ecx
    jz rtdEmptyList
;
    mov fs:[edx].utd_va_link,ecx
    mov ecx,fs:[eax].uqh_link
    mov fs:[edx].utd_link,ecx
    jmp rtdDone

rtdEmptyList:
    mov fs:[edx].utd_va_link,0
    mov fs:[edx].utd_link,1    
    jmp rtdDone

rtdSearch:
    or ecx,ecx
    jz rtdDone
;
    cmp eax,ecx
    je rtdRemove
;
    mov edx,ecx
    mov ecx,fs:[edx].uqh_va_link
    jmp rtdSearch

rtdRemove:
    mov ecx,fs:[eax].uqh_va_link
    or ecx,ecx
    jz rtdEmpty
;   
    mov fs:[edx].uqh_va_link,ecx
    mov ecx,fs:[eax].uqh_link
    mov fs:[edx].uqh_link,ecx
    jmp rtdDone

rtdEmpty:
    mov fs:[edx].uqh_va_link,0
    mov fs:[edx].uqh_link,1

rtdDone:
    pop edx
    pop ecx
    pop ebx
    ret
RemoveTd  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateQh
;
;       DESCRIPTION:    Allocate & initialize a QH object
;
;       PARAMETERS:     FS      Flat sel
;                       
;       RETURNS:        EDX     QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQh      PROC near
    push eax
    push ecx
;    
    mov cx,SIZE uhci_qh
    AllocateMemBlk
;
    mov fs:[edx].uqh_link,1
    mov fs:[edx].uqh_va_link,0
    mov fs:[edx].uqh_elem,1
    mov fs:[edx].uqh_va_elem,0
    mov fs:[edx].uqh_phys,eax
;
    pop ecx   
    pop eax
    ret
AllocateQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateTd
;
;       DESCRIPTION:    Allocate & initialize a TD object
;
;       PARAMETERS:     ES      Device sel
;                       FS      Flat sel
;                       DL      Pipe #
;
;       RETURNS:        EDX     QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTd    Proc near
    push eax
    push ecx
    pop ecx
    pop eax
    ret
AllocateTd  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InsertIntr
;
;       DESCRIPTION:    Insert QH into interrupt list
;
;       PARAMETERS:     FS      Flat sel
;                       GS:DI   Intr list
;                       EAX     QH to link
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertIntr      PROC near
    push ecx
    push edx
;    
    mov fs:[eax].uqh_va_link,0
    mov fs:[eax].uqh_link,1
;
    mov edx,gs:[di].uqh_va_elem
    or edx,edx
    jz iiEmpty

iiLastLoop:
    mov ecx,fs:[edx].uqh_va_link
    or ecx,ecx
    jz iiDoLast
;
    mov edx,ecx
    jmp iiLastLoop

iiDoLast:
    mov ecx,fs:[eax].uqh_phys
    or cl,2
    mov fs:[edx].uqh_link,ecx
    mov fs:[edx].uqh_va_link,eax
    jmp iiDone

iiEmpty:
    mov ecx,fs:[eax].uqh_phys
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
;       NAME:           RemoveIntr
;
;       DESCRIPTION:    Remove QH from interrupt list
;
;       PARAMETERS:     FS      Flat sel
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
    mov ecx,fs:[eax].uqh_va_link
    or ecx,ecx
    jz riEmptyList
;
    mov gs:[di].uqh_va_elem,ecx
    mov ecx,fs:[eax].uqh_link
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
    mov ecx,fs:[edx].uqh_va_link
    jmp riSearch

riRemove:
    mov ecx,fs:[eax].uqh_va_link
    or ecx,ecx
    jz riEmpty
;   
    mov fs:[edx].uqh_va_link,ecx
    mov ecx,fs:[eax].uqh_link
    mov fs:[edx].uqh_link,ecx
    jmp riDone

riEmpty:
    mov fs:[edx].uqh_va_link,0
    mov fs:[edx].uqh_link,1

riDone:
    pop ecx
    pop ebx
    ret
RemoveIntr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetIntrQh
;
;       DESCRIPTION:    Get interrupt QH
;
;       PARAMETERS:     DS      Function sel
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
;       NAME:           CreateControl
;
;       DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CreateControl   Proc far
    push fs
    pushad
;
    int 3
    mov ax,flat_sel
    mov fs,ax
;
    mov cx,SIZE uhci_td
    AllocateMemBlk
;
    mov fs:[edx].utd_link,0
    mov fs:[edx].utd_control,0
    mov fs:[edx].utd_host,0
    mov fs:[edx].utd_buf,0
    mov fs:[edx].utd_va_link,0
;
    mov eax,18800000h
    cmp es:usbd_speed,0
    jnz ccSpeedOk
;
    or eax, 4000000h
    
ccSpeedOk:
    mov es:dev_control_head,edx
    mov es:dev_utd_control,eax
;
    call AllocateQh
    mov es:dev_control_qh,edx
;
    mov edx,ds:uhc_period_td
    or edx,edx
    jnz ccLinkPeriod    
;
    call CreateIntrQueue
    mov edx,ds:uhc_period_td

ccLinkPeriod:
    mov eax,es:dev_control_qh
    call InsertTdFirst
    mov es:dev_curr_address,0
;
    popad
    pop fs
    retf32
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               Block
;
;       DESCRIPTION:        Block
;
;       PARAMETERS:         DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Block   Proc far
    EnterSection ds:usb_addr_section
    retf32
Block   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               Unblock
;
;       DESCRIPTION:        Unblock
;
;       PARAMETERS:         DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Unblock   Proc far
    LeaveSection ds:usb_addr_section
    retf32
Unblock   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               ResetPort
;
;       DESCRIPTION:        Reset port
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;       RETURNS:            AL      Speed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetPort   Proc far
    push dx
;    
    movzx di,dl
    add di,di
;
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,di    
;
    in ax,dx
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

rpLoop:
    in ax,dx
    test ax,4
    clc
    jnz rpNotify
;
    or ax,4
    out dx,ax
    loop rpLoop
;
    jmp rpFail

rpNotify:
    mov ax,200
    WaitMilliSec
;
    in ax,dx
    test al,1
    jz rpFail
;
    mov al,ah
    xor al,1
    and al,1
    clc
    jmp rpDone

rpFail:
    stc

rpDone:
    pop dx
    retf32
ResetPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DisablePort
;
;           DESCRIPTION:    Disable port
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisablePort   Proc far
    push ax
    push dx
    push di
;    
    movzx di,dl
    add di,di
;
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,di    
;
    in ax,dx
    and al,NOT 4
    out dx,ax
;
    mov ax,25
    WaitMilliSec
;
    pop di
    pop dx
    pop ax
    retf32
DisablePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DisableDev
;
;           DESCRIPTION:    Disable device
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisableDev   Proc far
    push ax
    push dx
;    
    mov dl,es:usbd_port
    movzx di,dl
    add di,di
;
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,di    
;
    in ax,dx
    and al,NOT 4
    out dx,ax
;
    mov ax,25
    WaitMilliSec
;
    pop dx
    pop ax
    retf32
DisableDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsPortConnected
;
;           DESCRIPTION:    Check if port is connected
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsPortConnected   Proc far
    push ax
    push dx
    push si
;    
    movzx si,dl
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,si
    add dx,si
;
    in ax,dx
    test al,1
    stc
    jz ipcDone
;
    clc

ipcDone:
    pop si
    pop dx
    pop ax
    retf32
IsPortConnected   Endp

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
;       NAME:           IsTRunning
;
;       DESCRIPTION:    Check if controller is running
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsRunning   Proc far
    push ax
    push dx
;
    mov dx,ds:uhc_io_base
    add dx,UsbStatusReg
    in ax,dx
    test al,20h
    stc
    jnz irDone
;
    clc

irDone:
    pop dx
    pop ax
    retf32
IsRunning   Endp

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
    mov es:usbd_parent_thread,0
    mov es:usbd_func_sel,ds
;
    popad
    retf32
CreateDev  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               FreeDev
;
;       DESCRIPTION:        Free device sel
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDev   Proc far
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
;       NAME:           ChangeAddress
;
;       DESCRIPTION:    Change address for pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device selector
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
;       NAME:           UnlinkPipes
;
;       DESCRIPTION:    Unlink pipes
;
;       PARAMETERS:     ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkPipes   Proc far
    int 3
    retf32
UnlinkPipes   Endp

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
    test es:usbd_flags,FLAG_DETACHED
    stc
    jnz rcDone
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
;       NAME:           CreateBulkPipe
;
;       DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     ES      Device
;                       CX      Buffer count
;                       DL      Pipe #
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CreateBulkPipe   Proc far
    int 3
    retf32
CreateBulkPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateIntrPipe
;
;       DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     ES      Device
;                       CX      Buffer count
;                       DL      Pipe #
;                       DH      Interval
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntrPipe   Proc far
    int 3
    retf32
CreateIntrPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EnablePipe
;
;       DESCRIPTION:    Enable pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnablePipe   Proc far
    int 3
    retf32
EnablePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisablePipe
;
;       DESCRIPTION:    Disable pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisablePipe   Proc far
    int 3
    retf32
DisablePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UsedBuffers
;
;       DESCRIPTION:    Return used buffers in pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;       RETURNS:        CX      Buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UsedBuffers   Proc far
    int 3
    retf32
UsedBuffers   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeBuffers
;
;       DESCRIPTION:    Return free buffers in pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;       RETURNS:        CX      Buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBuffers   Proc far
    int 3
    retf32
FreeBuffers   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReqBuffer
;
;       DESCRIPTION:    Req buffer
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;       RETURNS:        EDX     Buffer linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqBuffer   Proc far
    int 3
    retf32
ReqBuffer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RelBuffer
;
;       DESCRIPTION:    Release buffer
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RelBuffer   Proc far
    int 3
    retf32
RelBuffer   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdatePort
;
;           DESCRIPTION:    Update root-hub port status
;
;       PARAMETERS:     DS      Function selector
;                       DL      Port # (0,1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push ax
    push si
;    
    movzx si,dl
    add si,si
;    
    push dx
    mov dx,ds:uhc_io_base
    add dx,PortscReg1
    add dx,si    
    in ax,dx
    pop dx
;
    xor bx,bx
    NotifyUsbPortState
;
    pop si
    pop ax
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
;           NAME:           UHCI function handler
;
;           DESCRIPTION:    UHCI function thread
;
;       PARAMETERS:         BX      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

uhci_function_handler:
    mov ds,bx
    GetThread
    mov ds:uhc_thread,ax
;
    mov ax,flat_sel
    mov fs,ax

ufhLoop:
    mov bx,ds:usb_controller_id
    cmp bx,2
    jne ufhWait
;
    call fword ptr ds:is_running_proc
    jnc ufhWaitMs
;
    mov ax,USB_EVENT_CONTROLLER_ERROR
    ReportUsbFunctionEvent
    int 3

ufhWaitMs:
    mov ax,25
    WaitMilliSec
    jmp ufhLoop

ufhWait:
    WaitForSignal    
;
    call fword ptr ds:is_running_proc
    jnc ufhRunning
;
    mov ax,USB_EVENT_CONTROLLER_ERROR
    ReportUsbFunctionEvent

ufhRunning:
    jmp ufhLoop
        
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
;       NAME:           StartThread
;
;       DESCRIPTION:    Start thread
;
;       PARAMETERS:     DS      Function sel (passed as bx)
;                       DX      Passed through
;                       AX      Prio
;                       SI      Entry
;                       DI      Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartThread Proc near
    push es            
    push ax
    push si
;
    mov si,di
    mov eax,100h
    AllocateSmallGlobalMem
    xor di,di

sfCopyLoop:
    mov al,cs:[si]
    inc si
    or al,al
    jz sfCopyDone
;
    stosb
    jmp sfCopyLoop

sfCopyDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;   
    pop si         
    mov bx,ds
    xor di,di
    mov ax,cs
    mov ds,ax
    pop ax
    mov cx,stack0_size
    CreateThread
;
    FreeMem
    pop es
    ret
StartThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartFunctionThread
;
;           DESCRIPTION:    Start UHCI function thread
;
;       PARAMETERS:         DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

func_name    DB 'UHCI ', 0

StartFunctionThread Proc near
    mov si,OFFSET uhci_function_handler
    mov di,OFFSET func_name
    mov ax,5
    call StartThread
    ret
StartFunctionThread Endp

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
ut00 DD OFFSET Block,               SEG code
ut01 DD OFFSET Unblock,             SEG code
ut02 DD OFFSET ResetPort,           SEG code
ut03 DD OFFSET DisablePort,         SEG code
ut04 DD OFFSET DisableDev,          SEG code
ut05 DD OFFSET IsPortConnected,     SEG code
ut06 DD OFFSET IsRunning,           SEG code
ut07 DD OFFSET AllocateAddress,     SEG code
ut08 DD OFFSET FreeAddress,         SEG code
ut09 DD OFFSET CreateDev,           SEG code
ut0A DD OFFSET UnlinkPipes,         SEG code
ut0B DD OFFSET IsDeviceConnected,   SEG code
ut0C DD OFFSET FreeDev,             SEG code
ut0D DD OFFSET CreateControl,       SEG code
ut0E DD OFFSET CreateBulkPipe,      SEG code
ut0F DD OFFSET CreateIntrPipe,      SEG code
ut10 DD OFFSET AddressDev,          SEG code
ut11 DD OFFSET ChangeAddress,       SEG code
ut12 DD OFFSET UpdateMaxLen,        SEG code
ut13 DD OFFSET ControlMsg,          SEG code
ut14 DD OFFSET ConfigDev,           SEG code
ut15 DD OFFSET EnablePipe,          SEG code
ut16 DD OFFSET DisablePipe,         SEG code
ut17 DD OFFSET UsedBuffers,         SEG code
ut18 DD OFFSET FreeBuffers,         SEG code
ut19 DD OFFSET ReqBuffer,           SEG code
ut1A DD OFFSET RelBuffer,           SEG code

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
    mov bx,ds:uhc_pci_bus_dev
    mov ch,ds:uhc_pci_func
    GetPciMsi
    jc ifIrq
;
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc ifIrq    
;
    SetupPciMsi
;    
    mov di,cs
    mov es,di
    mov edi,OFFSET UhciInt
    RequestMsiHandler
    jmp ifIntDone

ifIrq:
    mov ds:uhc_irq,0
    GetPciIrqNr
    jc ifIrqFail
;    
    mov ds:uhc_irq,al
    mov ah,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET UhciInt
    RequestIrqHandler
    jmp ifIntDone

ifIrqFail:

ifIntDone:
    mov si,OFFSET uhci_tab
    xor di,di
    mov cx,2*1Bh

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
    mov ax,0Fh
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
    mov dl,0
    call UpdatePort
;    
    mov dl,1
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
;
    call InitFunction
    call StartFunctionThread
;
    pop cx
    pop bx
    pop ds
    add bx,2
    loop uhci_func_loop
;    

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
    clc
    ret
Init    Endp

code ENDS

    END init
