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
INCLUDE hub.inc

MAX_USB_DEVICES = 16

; ehc_flags

EHC_PORT_IND        = 1
EHC_COMPANION       = 2
EHC_PORT_POWER      = 4

; HCC flags

HCC_64              = 1

hccap   STRUC

hcp_CAPLEN      DB ?
hcp_resv    DB ?
hcp_HCIVERSION  DW ?
hcp_HCSPARAMS   DW ?,?
hcp_HCCPARAMS   DD ?
hcp_ROUTE       DB ?

hccap   ENDS

hc_reg  STRUC

HcCommand       DD ?
HcStatus        DD ?
HcInterruptEnable   DD ?
HcFrameIndex    DD ?
HcSegmentSelector   DD ?
HcPeriodicListBase  DD ?
HcAsyncList     DD ?
HcResv          DD 9 DUP(?)
HcConfig        DD ?
HcPortSc        DD ?

hc_reg  ENDS

count_struc STRUC

ehc_cnt         DD ?
ehc_qh          DD ?

count_struc ENDS

ehci_func_sel   STRUC

usb_func_base       usb_function_struc <>

ehc_dev_arr         DW MAX_USB_HUB_PORTS DUP(?)

ehc_reg_sel         DW ?
ehc_thread          DW ?

ehc_bus             DB ?
ehc_device          DB ?
ehc_function        DB ?

ehc_op_offs         DB ?
ehc_eecp            DB ?
ehc_hcc_flags       DB ?
ehc_flags           DW ?
ehc_ports           DB ?
ehc_debug_port      DB ?
ehc_version         DW ?
ehc_comp_ports      DB ?

ehc_section         section_typ <>

ehc_reset           DW ?

ehc_async_head_va   DD ?

ehc_periodic_sel    DW ?
ehc_periodic_phys   DD ?

ehc_1024            DD 1024 DUP(?,?)
ehc_512             DD 512 DUP(?,?)
ehc_256             DD 256 DUP(?,?)
ehc_128             DD 128 DUP(?,?)
ehc_64              DD 64 DUP(?,?)
ehc_32              DD 32 DUP(?,?)
ehc_16              DD 16 DUP(?,?)
ehc_8               DD 8 DUP(?,?)
ehc_4               DD 4 DUP(?,?)
ehc_2               DD 2 DUP(?,?)
ehc_1               DD ?,?

ehc_curr_cnt        DD 1024 DUP(?)

ehci_func_sel       ENDS

ehci_dev_sel        STRUC

usb_dev_base        usb_device_struc <>

dev_control_qtd     DD ?
dev_control_qh      DD ?
dev_control_thread  DW ?
dev_control_status  DB ?

ehci_dev_sel     ENDS

ehci_pipe_struc    STRUC

ep_pipe            usb_device_pipe_struc <>

ep_qh              DD ?
ep_table           DW ?
ep_table_size      DW ?
ep_entry           DW ?
ep_entry_count     DW ?
ep_rd_ptr          DW ?
ep_wr_ptr          DW ?
ep_tail_ptr        DW ?

ep_entry_arr       DD ?

ehci_pipe_struc    ENDS

qtd_struc         STRUC

qtd_next          DD ?
qtd_alt           DD ?
qtd_status        DB ?
qtd_flags         DB ?
qtd_size          DW ?
qtd_page0         DD ?
qtd_page1         DD ?
qtd_page2         DD ?
qtd_page3         DD ?
qtd_page4         DD ?

qtd_struc         ENDS

qtd32_struc       STRUC

; HC part

qtd32_base        qtd_struc <>

qtd32_struc       ENDS

qtd64_struc       STRUC

; HC part

qtd64_base        qtd_struc <>

qtdu64_page0      DD ?
qtdu64_page1      DD ?
qtdu64_page2      DD ?
qtdu64_page3      DD ?
qtdu64_page4      DD ?

qtd64_struc       ENDS

control_qtd_struc       STRUC

cq_base           qtd64_struc <>

qtd_next_va       DD ?
qtd_buffer_va     DD ?
qtd_buffer_size DW ?

control_qtd_struc        ENDS

; this structure should be kept less than 128 bytes long!

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
qhl_page0       DD ?
qhl_page1       DD ?
qhl_page2       DD ?
qhl_page3       DD ?
qhl_page4       DD ?

qhu_page0       DD ?
qhu_page1       DD ?
qhu_page2       DD ?
qhu_page3       DD ?
qhu_page4       DD ?

; driver part

qh_my_va        DD ?
qh_my_phys      DD ?
qh_link_va      DD ?
qh_next_va      DD ?
qh_alt_va       DD ?

qh_struc    ENDS


data    SEGMENT byte public 'DATA'

EhciQhList      DD ?
EhciSection     section_typ <>
PortThread      DW ?

WaitSection     section_typ <>
WaitThreadArr   DW 3 DUP(?)
Started         DB ?
UseTimer        DB ?

EhciFuncCount   DW ?
EhciFuncArr     DW MAX_USB_DEVICES DUP(?)

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
;           NAME:           EhciInt
;
;           DESCRIPTION:    EHCI interrupt
;
;       PARAMETERS:     DS      Function selector
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EhciInt Proc far    
    mov es,ds:ehc_reg_sel

eiLoop:    
    mov eax,es:HcStatus
    and al,7
    mov es:HcStatus,eax
    jz eiDone
;    
    test al,4
    jz eiSignal
;
    push ds
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:PortThread
    Signal
    pop ds
    jmp eiLoop

eiSignal:        
    NotifyIrqActivity    
    mov bx,ds:ehc_thread
    Signal
    jmp eiLoop

eiDone:
    retf32
EhciInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ehci_timer
;
;           DESCRIPTION:    Timer that scans for status change in controller
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ehci_timer  Proc far
    push edx
    push eax
;    
    mov ax,SEG data
    mov ds,ax
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
;    
    mov eax,es:HcStatus
    and al,7
    mov es:HcStatus,eax
    jz etNext
;
    test al,4
    jz etSignal
;
    push ds
    push ax
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:PortThread
    Signal
    pop ax
    pop ds
    test al,1
    jz etNext

etSignal:        
    mov bx,ds:ehc_thread
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
    GetSystemTime
    add eax,1193
    adc edx,0
    mov bx,cs
    mov es,bx
    mov bx,cs
    mov edi,OFFSET ehci_timer
    StartTimer
    retf32
ehci_timer  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitQh
;
;       DESCRIPTION:    Initialize an already allocated qh
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;                       EDX     QH linear
;                       EAX     QH physical
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitQh   Proc near
    mov fs:[edx].qh_link,1
    mov fs:[edx].qh_adress,0
    mov fs:[edx].qh_endpoint,0
    mov fs:[edx].qh_max_packet,0A000h
    mov fs:[edx].qh_s_mask,0
    mov fs:[edx].qh_c_mask,0
    mov fs:[edx].qh_hub_port,4000h
    mov fs:[edx].qh_current_qtd,0
    mov fs:[edx].qh_next_qtd,1
    mov fs:[edx].qh_alt_qtd,1
    mov fs:[edx].qh_status,0
    mov fs:[edx].qh_flags,0
    mov fs:[edx].qh_size,0
    mov fs:[edx].qhl_page0,0    
    mov fs:[edx].qhl_page1,0    
    mov fs:[edx].qhl_page2,0    
    mov fs:[edx].qhl_page3,0    
    mov fs:[edx].qhl_page4,0
    mov fs:[edx].qhu_page0,0    
    mov fs:[edx].qhu_page1,0    
    mov fs:[edx].qhu_page2,0    
    mov fs:[edx].qhu_page3,0    
    mov fs:[edx].qhu_page4,0
    mov fs:[edx].qh_my_va,edx
    mov fs:[edx].qh_link_va,0
    mov fs:[edx].qh_next_va,0
    mov fs:[edx].qh_alt_va,0    
    mov fs:[edx].qh_my_phys,eax
    ret
InitQh   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitQtd32
;
;       DESCRIPTION:    Initialize an already allocated qTD
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;                       EDX     qTD linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitQtd32 PROC near
    mov fs:[edx].qtd_next,1
    mov fs:[edx].qtd_alt,1
    mov fs:[edx].qtd_status,80h
    mov fs:[edx].qtd_flags,8Fh
    mov fs:[edx].qtd_size,0
    mov fs:[edx].qtd_page0,0
    mov fs:[edx].qtd_page1,0
    mov fs:[edx].qtd_page2,0
    mov fs:[edx].qtd_page3,0
    mov fs:[edx].qtd_page4,0
    ret
InitQtd32  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitQtd64
;
;       DESCRIPTION:    Initialize an already allocated qTD
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;                       EDX     qTD linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitQtd64 PROC near
    mov fs:[edx].qtd_next,1
    mov fs:[edx].qtd_alt,1
    mov fs:[edx].qtd_status,80h
    mov fs:[edx].qtd_flags,8Fh
    mov fs:[edx].qtd_size,0
    mov fs:[edx].qtd_page0,0
    mov fs:[edx].qtd_page1,0
    mov fs:[edx].qtd_page2,0
    mov fs:[edx].qtd_page3,0
    mov fs:[edx].qtd_page4,0
    mov fs:[edx].qtdu64_page0,0
    mov fs:[edx].qtdu64_page1,0
    mov fs:[edx].qtdu64_page2,0
    mov fs:[edx].qtdu64_page3,0
    mov fs:[edx].qtdu64_page4,0
    ret
InitQtd64  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateQh
;
;       DESCRIPTION:    Allocate & initialize an qh descriptor
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;
;       RETURNS:        EDX     Linear address of qh
;                       EAX     Physical address of qh
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQh      PROC near
    push ebx
    push ecx
;
    mov cx,SIZE qh_struc
    AllocateMemBlk
    call InitQh
;
    pop ecx
    pop ebx
    ret
AllocateQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateQtd
;
;       DESCRIPTION:    Allocate & initialize qTD
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;
;       RETURNS:        EDX     Linear address of qTD
;                       EAX     Physical address of qTD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQtd     PROC near
    push ebx
    push ecx
;
    test ds:ehc_hcc_flags,HCC_64
    jz aqt32

aqt64:
    mov cx,SIZE qtd64_struc
    AllocateMemBlk
    call InitQtd64
    jmp aqtDone

aqt32:    
    mov cx,SIZE qtd32_struc
    AllocateMemBlk
    call InitQtd32

aqtDone:
    pop ecx
    pop ebx
    ret
AllocateQtd  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddAsyncQh
;
;       DESCRIPTION:    Add async qh
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       EDX     QH linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddAsyncQh    PROC near
    push gs
    pushad
;
    mov ebx,fs:[edx].qh_my_phys
    mov eax,ds:ehc_async_head_va
    or eax,eax
    jnz aaqInsert
;
    or fs:[edx].qh_endpoint,80h
    mov ds:ehc_async_head_va,edx
    mov eax,ebx
    or al,2
    mov fs:[edx].qh_link,eax
    mov fs:[edx].qh_link_va,0
;
    mov gs,ds:ehc_reg_sel
    mov gs:HcAsyncList,ebx
;
    mov ax,25
    WaitMilliSec    
;
    mov eax,gs:HcCommand
    or al,20h
    mov gs:HcCommand,eax
    jmp aaqDone

aaqInsert:
    mov esi,eax
    mov edi,fs:[esi].qh_my_phys    

aaqInsLoop:
    mov esi,eax    
    mov eax,fs:[esi].qh_link_va
    or eax,eax
    jnz aaqInsLoop
;
    mov fs:[edx].qh_link_va,0    
    mov eax,edi
    or al,2
    mov fs:[edx].qh_link,eax
;
    mov fs:[esi].qh_link_va,edx
    mov eax,ebx
    or al,2
    mov fs:[esi].qh_link,eax

aaqDone:
    popad
    pop gs
    ret
AddAsyncQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkAsyncQh
;
;       DESCRIPTION:    Unlink async qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;                       EDX     Linear address of qh to remove
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkAsyncQh    PROC near
    push gs
    pushad
;
    test fs:[edx].qh_endpoint,80h
    jz uaqList

uaqHead:
    mov edi,fs:[edx].qh_link_va
    mov ds:ehc_async_head_va,edi
    or edi,edi
    jz uaqHeadEmpty
;    
    mov eax,fs:[edi].qh_my_phys
;
    mov gs,ds:ehc_reg_sel
    mov gs:HcAsyncList,eax
    jmp uaqDone

uaqHeadEmpty:
    mov gs,ds:ehc_reg_sel
    mov eax,gs:HcCommand
    and al,NOT 20h
    mov gs:HcCommand,eax
    mov gs:HcAsyncList,0
    jmp uaqDone
    
uaqList:
    mov edi,ds:ehc_async_head_va

uaqSearch:    
    or edi,edi
    jz uaqDone
;    
    cmp edx,fs:[edi].qh_link_va
    je uaqFound
;
    mov edi,fs:[edi].qh_link_va
    jmp uaqSearch

uaqFound:        
    mov eax,fs:[edx].qh_link_va
    mov fs:[edi].qh_link_va,eax
;
    mov eax,fs:[edx].qh_link
    mov fs:[edi].qh_link,eax   

uaqDone:
    popad
    pop gs   
    ret    
UnlinkAsyncQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddControlQh
;
;       DESCRIPTION:    Add control qh
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;
;      RETURNS:         EDX     QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddControlQh    PROC near
    push gs
    push eax
;
    EnterSection ds:ehc_section
    call AllocateQh
;
    mov fs:[edx].qh_endpoint,60h
;    
    mov ax,0A008h
    mov fs:[edx].qh_max_packet,ax
;
    mov al,es:usbd_speed
    cmp al,2
    je acqAdd
;
    cmp al,0
    je acqLowSpeed

acqFullSpeed:
    mov ah,0
    jmp acqSetSpeed

acqLowSpeed:
    mov ah,10h

acqSetSpeed:    
    mov al,40h
    or al,ah
    mov fs:[edx].qh_endpoint,al
;
    movzx ax,es:usbd_port
    inc ax
    shl ax,7
    or ax,4000h    
    mov gs,es:usbd_hub_sel
    or al,gs:hub_address
    mov fs:[edx].qh_hub_port,ax
    mov fs:[edx].qh_c_mask,2
;    
    mov ax,0A808h
    mov fs:[edx].qh_max_packet,ax
    
acqAdd:
    call AddAsyncQh
    LeaveSection ds:ehc_section
;    
    pop eax
    pop gs
    ret
AddControlQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddBulkQh
;
;       DESCRIPTION:    Add bulk qh
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBulkQh    PROC near
    push eax
    push edx
;
    EnterSection ds:ehc_section
    call AllocateQh
;
    mov fs:[edx].qh_endpoint,20h
;    
    mov al,es:usbd_speed
    cmp al,2
    je abqSpeedOk
;
    cmp al,0
    je abqLowSpeed

abqFullSpeed:
    mov ah,0
    jmp abqSetSpeed

abqLowSpeed:
    mov ah,10h

abqSetSpeed:    
    mov al,ah
    mov fs:[edx].qh_endpoint,al
;
    movzx ax,es:usbd_port
    inc ax
    shl ax,7
    or ax,4000h    
    push gs
    mov gs,es:usbd_hub_sel
    or al,gs:hub_address
    pop gs
    mov fs:[edx].qh_hub_port,ax
;
    mov fs:[edx].qh_c_mask,2
    
abqSpeedOk:
    call AddAsyncQh
    LeaveSection ds:ehc_section
;
    mov gs:ep_qh,edx
;    
    pop edx
    pop eax
    ret
AddBulkQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateIntQh
;
;       DESCRIPTION:    Allocate int QH
;
;       RETURNS:        EDX     Linear address
;                       EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateIntQh PROC near
    push ds
    push ebx
    push ecx
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:EhciSection
    mov edx,ds:EhciQhList
    or edx,edx
    jnz aiqOk
;
    push ecx    
    mov eax,1000h
    AllocateBigLinear
;
    push ebx
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    pop ebx
;    
    mov ecx,128
    mov ds:EhciQhList,edx
    
aiqLoop:
    mov eax,edx
    add eax,ecx
    mov fs:[edx],eax
    mov edx,eax
    test dx,0FFFh
    jnz aiqLoop
;
    sub edx,ecx
    mov dword ptr fs:[edx],0
    mov edx,ds:EhciQhList
    pop ecx

aiqOk:
    mov eax,fs:[edx]
    mov ds:EhciQhList,eax
    LeaveSection ds:EhciSection
;
    push ebx
    GetPageEntry
    pop ebx    
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
;
    call InitQh
;
    pop ecx
    pop ebx
    pop ds
    ret
AllocateIntQh ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateInactiveIntQh
;
;       DESCRIPTION:    Allocate inactive int QH
;
;       RETURNS:        EDX     Linear address
;                       EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateInactiveIntQh PROC near
    call AllocateIntQh
    mov fs:[edx].qh_adress,80h
    ret
AllocateInactiveIntQh ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeIntQh
;
;       DESCRIPTION:    Free interrupt qh
;
;       PARAMETERS:     FS      Flat sel
;
;       PARAMETERS:     EDX     QH linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeIntQh     PROC near
    push ds
    push eax
;
    mov ax,SEG data
    mov ds,ax
;    
    EnterSection ds:EhciSection
    mov eax,ds:EhciQhList
    mov fs:[edx],eax
    mov ds:EhciQhList,edx
    LeaveSection ds:EhciSection
;       
    pop eax
    pop ds
    ret
FreeIntQh     ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           LinkInterrupt
;
;       DESCRIPTION:    Link interrupts in tree
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;                       BX      Table offset
;                       CX      Table size / 2
;                       AX      Entry
;                       BP      Table size
;                       EDX     QH to link
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LinkInterrupt     PROC near
    pushad
;    
    shl cx,1    
    mov si,ax
    shl si,3    
    mov edi,[bx+si].ehc_qh
    mov fs:[edi].qh_next_va,edx
    mov edx,fs:[edx].qh_my_phys
    or dl,2
    mov fs:[edi].qh_link,edx    
;
    cmp bx,OFFSET ehc_1024
    je liDone
;   
    mov edx,edi
    shl bp,1
    sub bx,bp
    call LinkInterrupt 
;
    add ax,cx
    call LinkInterrupt

liDone:
    popad
    ret
LinkInterrupt     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateInterrupt
;
;   DESCRIPTION:    Creae interrupt lists
;
;   PARAMETERS:     DS  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateInterrupt  Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    call AllocateInactiveIntQh
    or al,3
    mov fs:[edx].qh_link,eax
;
    mov bx,OFFSET ehc_1
    push edx
    call AllocateInactiveIntQh
    mov ds:[bx].ehc_cnt,0
    mov ds:[bx].ehc_qh,edx
    pop eax
;
    mov fs:[edx].qh_next_va,eax
    mov eax,fs:[eax].qh_my_phys
    or al,3
    mov fs:[edx].qh_link,eax
;
    mov cx,2+4+8+16+32+64+128+256+512+1024 
    mov bx,OFFSET ehc_1024

ciInitLoop:
    call AllocateInactiveIntQh
    mov ds:[bx].ehc_cnt,0
    mov ds:[bx].ehc_qh,edx
;
    add bx,8
    loop ciInitLoop    

    mov bx,OFFSET ehc_1
    mov edx,ds:[bx].ehc_qh
;    
    mov bx,OFFSET ehc_2
    mov cx,1
    mov bp,2*8
    xor ax,ax
    call LinkInterrupt
;
    inc ax
    call LinkInterrupt
;    
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical32
    mov ds:ehc_periodic_phys,eax
    mov al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov gs,bx
    mov ds:ehc_periodic_sel,bx
;
    mov cx,1024    
    mov si,OFFSET ehc_1024
    xor di,di

ciLoop:    
    mov edx,ds:[si].ehc_qh
    mov edx,fs:[edx].qh_my_phys
    or dl,2
    mov gs:[di],edx
    add si,8
    add di,4
    loop ciLoop
;
    mov gs,ds:ehc_reg_sel
    mov eax,ds:ehc_periodic_phys
    mov gs:HcPeriodicListBase,eax
;    
    mov ax,25
    WaitMilliSec
;
    mov eax,gs:HcCommand    
    or al,10h
    mov gs:HcCommand,eax
;
    popad
    pop gs
    pop fs
    pop es
    pop ds    
    ret
CreateInterrupt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetIntrEntry
;
;       DESCRIPTION:    Get intr entry
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;                       BX      Table offset
;                       CX      Entry count
;
;       RETURNS:        AX      Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIntrEntry    PROC near
    push cx
    push edx
    push si
    push di
;
    xor si,si    
    xor di,di
    mov eax,80000000h

gieLoop:
    mov edx,ds:[bx+si].ehc_cnt
    cmp edx,eax
    ja gieNext
;
    mov di,si
    mov eax,edx

gieNext:
    add si,8
    loop gieLoop
;        
    mov ax,di
    shr ax,3    
;
    pop di
    pop si
    pop edx
    pop cx
    ret
GetIntrEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddIntrEntry
;
;       DESCRIPTION:    Add intr entry
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       AX      Entry
;                       BX      Table offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntrEntry    PROC near
    pushad
;    
    mov si,ax
    shl si,3
    mov edx,ds:[bx+si].ehc_qh
    mov al,fs:[edx].qh_adress
    test al,80h
    jnz aieQhOk
;
    call AllocateIntQh 

aieQhOk:
    mov gs:ep_table,bx
    mov gs:ep_entry,ax
    mov gs:ep_qh,edx
;    
    mov fs:[edx].qh_s_mask,1    
    mov fs:[edx].qh_c_mask,2
;
    mov fs:[edx].qh_endpoint,20h
    mov al,es:usbd_speed
    cmp al,2
    je aieSpeedOk
;
    mov fs:[edx].qh_c_mask,1Ch
    cmp al,0
    je aieLowSpeed

aieFullSpeed:
    mov ah,0
    jmp aieSetSpeed

aieLowSpeed:
    mov ah,10h

aieSetSpeed:    
    mov fs:[edx].qh_endpoint,ah
;
    push gs
    movzx ax,es:usbd_port
    inc ax
    shl ax,7
    or ax,4000h    
    mov gs,es:usbd_hub_sel
    or al,gs:hub_address
    pop gs        
    mov fs:[edx].qh_hub_port,ax
    
aieSpeedOk:
    inc ds:[bx+si].ehc_cnt
;
    cmp edx,ds:[bx+si].ehc_qh
    je aieDone
;
    mov edi,ds:[bx+si].ehc_qh
    mov eax,fs:[edi].qh_link_va
    mov es:[edx].qh_link_va,eax
    mov eax,fs:[ecx].qh_link
    mov es:[edx].qh_link,eax    
;    
    mov es:[edi].qh_link_va,edx
    mov eax,fs:[edx].qh_my_phys
    or al,2
    mov fs:[edi].qh_link,eax    
    
aieDone:
    popad
    ret
AddIntrEntry    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddIntrProp
;
;       DESCRIPTION:    Add intr propagate in tree
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;                       BX      Table offset
;                       CX      Table size / 2
;                       AX      Entry
;                       BP      Table size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntrProp     PROC near
    pushad
;    
    mov si,ax
    shl si,3
    inc ds:[bx+si].ehc_cnt
;    
    shl cx,1    
    cmp bx,OFFSET ehc_1024
    je aipDone
;    
    shl bp,1
    sub bx,bp
    call AddIntrProp    
;
    add ax,cx
    call AddIntrProp

aipDone:
    popad
    ret
AddIntrProp     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddIntrQh
;
;       DESCRIPTION:    Add interrupt qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       AL      Interval
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntrQh   PROC near
    pushad
;    
    mov cx,1024
    movzx ax,al
    mov bx,OFFSET ehc_1024
    mov bp,8 * 1024

aiqhLoop:    
    cmp ax,cx
    jae aiqhFound
;
    add bx,bp
    shr bp,1
    shr cx,1
    jnz aiqhLoop    

aiqhFound:
    mov gs:ep_table_size,bp
;
    call GetIntrEntry
    call AddIntrEntry
;    
    cmp bx,OFFSET ehc_1024
    je aiqhDone
;
    shl bp,1
    sub bx,bp
    call AddIntrProp    
;
    add ax,cx
    call AddIntrProp

aiqhDone:
    popad
    ret
AddIntrQh   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RemoveIntrProp
;
;       DESCRIPTION:    Remove intr propagate in tree
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;                       BX      Table offset
;                       CX      Table size / 2
;                       AX      Entry
;                       BP      Table size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveIntrProp     PROC near
    pushad
;    
    mov si,ax
    shl si,3
    dec ds:[bx+si].ehc_cnt
;
    shl cx,1    
    cmp bx,OFFSET ehc_1024
    je ripDone
;    
    shl bp,1
    sub bx,bp
    call RemoveIntrProp    
;
    add ax,cx
    call RemoveIntrProp

ripDone:
    popad
    ret
RemoveIntrProp     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkIntrQh
;
;       DESCRIPTION:    Unlink intr qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkIntrQh    PROC near
    pushad
;
    mov edx,gs:ep_qh
    mov bx,gs:ep_table
    mov si,gs:ep_entry
    mov bp,gs:ep_table_size
    mov cx,bp
    shr cx,4
;    
    mov edi,ds:[bx+si].ehc_qh
    cmp edx,edi
    jne uiqSearch
;
    mov eax,fs:[edx].qh_link_va
    or eax,eax
    jnz uiqFirst
;
    mov fs:[edx].qh_current_qtd,0
    mov fs:[edx].qh_next_qtd,1
    mov fs:[edx].qh_alt_qtd,1
    mov fs:[edx].qh_status,0
    mov fs:[edx].qh_adress,80h
    jmp uiqUpdate

uiqFirst:
    int 3
        
uiqSearch:    
    or edi,edi
    jz uiqUpdate
;    
    cmp edx,es:[edi].qh_link_va
    je uiqUpdate
;
    mov edi,es:[edi].qh_link_va
    jmp uiqSearch

uiqFound:        
    mov eax,es:[edx].qh_link_va
    mov es:[edi].qh_link_va,eax
;
    mov eax,es:[edx].qh_link
    mov es:[edi].qh_link,eax   

uiqUpdate:
    mov ax,si
    shr ax,3
;    
    cmp bx,OFFSET ehc_1024
    je uiqDone
;
    shl bp,1
    sub bx,bp
    call RemoveIntrProp    
;
    add ax,cx
    call RemoveIntrProp

uiqDone:    
    popad
    ret
UnlinkIntrQh    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateControl
;
;           DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    push fs
    pushad
;    
    mov ax,flat_sel
    mov fs,ax
    call AddControlQh
    mov es:dev_control_qh,edx
;
    popad
    pop fs
    retf32
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ChangeAddress
;
;   DESCRIPTION:    Change address for pipe
;
;   PARAMETERS:     DS      Function selector
;                   AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    push fs
    push ax
    push edx
;
    mov ax,flat_sel
    mov fs,ax
;    
    mov edx,es:dev_control_qh
    mov al,es:usbd_address
    mov fs:[edx].qh_adress,al
;
    pop edx
    pop ax
    pop fs
    retf32
ChangeAddress   Endp

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
    lock or ds:ehc_reset,ax
;
    pop cx
    pop ax
    retf32
ResetDev Endp

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
    push fs
    push eax
    push edx
;    
    mov ax,flat_sel
    mov fs,ax
    mov edx,es:dev_control_qh
    mov ax,fs:[edx].qh_max_packet
    and ax,0F800h
    or ax,es:usbd_maxlen
    mov fs:[edx].qh_max_packet,ax
;
    pop edx
    pop eax
    pop fs
    retf32
UpdateMaxLen   Endp

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
    push es
    push eax
    push esi
;    
    test es:usbd_flags,FLAG_DETACHED
    stc
    jnz idcFail
;
    movzx si,es:usbd_port
    shl si,2
    mov es,ds:ehc_reg_sel
    mov eax,es:[si].HcPortSc
    test al,4
    jz idcFail
;
    test al,1
    clc
    jnz idcDone

idcFail:   
    stc

idcDone:
    pop esi
    pop eax
    pop es
    retf32
IsDeviceConnected Endp

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
    push edx
;
    mov edx,es:dev_control_qtd
    mov fs:[edx].qtd_next,1
    mov fs:[edx].qtd_alt,1
    mov fs:[edx].qtd_status,80h
    mov fs:[edx].qtd_flags,0Eh
    mov fs:[edx].qtd_size,8
;
    mov eax,OFFSET usbd_control_buf
    add eax,es:mblk_physical_base
    mov fs:[edx].qtd_page0,eax
;
    mov fs:[edx].qtd_page1,0
    mov fs:[edx].qtd_page2,0
    mov fs:[edx].qtd_page3,0
    mov fs:[edx].qtd_page4,0
    mov fs:[edx].qtdu64_page0,0
    mov fs:[edx].qtdu64_page1,0
    mov fs:[edx].qtdu64_page2,0
    mov fs:[edx].qtdu64_page3,0
    mov fs:[edx].qtdu64_page4,0
    mov fs:[edx].qtd_next_va,0
    mov fs:[edx].qtd_buffer_va,0
    mov fs:[edx].qtd_buffer_size,8
;
    pop edx
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
    mov esi,es:dev_control_qtd
    or cx,cx
    jz sciStatusOut
;
    mov bp,8000h

sciLoop:
    push cx
    mov cx,SIZE control_qtd_struc
    AllocateMemBlk
    pop cx
    jc sciDone
;
    mov fs:[esi].qtd_next,eax
    mov fs:[esi].qtd_next_va,edx
;
    mov esi,edx
    mov fs:[esi].qtd_next,1
    mov fs:[esi].qtd_alt,1
    mov fs:[esi].qtd_status,80h
    mov fs:[esi].qtd_flags,0Dh
    mov fs:[esi].qtd_page0,0
    mov fs:[esi].qtd_page1,0
    mov fs:[esi].qtd_page2,0
    mov fs:[esi].qtd_page3,0
    mov fs:[esi].qtd_page4,0
    mov fs:[esi].qtdu64_page0,0
    mov fs:[esi].qtdu64_page1,0
    mov fs:[esi].qtdu64_page2,0
    mov fs:[esi].qtdu64_page3,0
    mov fs:[esi].qtdu64_page4,0
    mov fs:[esi].qtd_next_va,0
    mov fs:[esi].qtd_buffer_va,0
    mov fs:[esi].qtd_buffer_size,0
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
    mov fs:[esi].qtd_buffer_va,edx
    mov fs:[esi].qtd_buffer_size,bx
;
    mov fs:[esi].qtd_page0,eax
    mov ax,bx    
    or ax,bp
    mov fs:[esi].qtd_size,ax
;
    xor bp,8000h
    sub cx,bx
    jnz sciLoop

sciStatusOut: 
    mov cx,SIZE control_qtd_struc
    AllocateMemBlk
    jc sciDone
;
    mov fs:[esi].qtd_next,eax
    mov fs:[esi].qtd_next_va,edx
;
    mov esi,edx
    mov fs:[esi].qtd_next,1
    mov fs:[esi].qtd_alt,1
    mov fs:[esi].qtd_status,80h
    mov fs:[esi].qtd_flags,8Ch
    mov fs:[esi].qtd_size,8000h
    mov fs:[esi].qtd_page0,0
    mov fs:[esi].qtd_page1,0
    mov fs:[esi].qtd_page2,0
    mov fs:[esi].qtd_page3,0
    mov fs:[esi].qtd_page4,0
    mov fs:[esi].qtdu64_page0,0
    mov fs:[esi].qtdu64_page1,0
    mov fs:[esi].qtdu64_page2,0
    mov fs:[esi].qtdu64_page3,0
    mov fs:[esi].qtdu64_page4,0
    mov fs:[esi].qtd_next_va,0
    mov fs:[esi].qtd_buffer_va,0
    mov fs:[esi].qtd_buffer_size,0
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
    mov esi,es:dev_control_qtd
    mov esi,fs:[esi].qtd_next_va

cciCopyLoop:
    or esi,esi
    clc
    jz cciDone
;
    mov edx,fs:[esi].qtd_buffer_va
    or edx,edx
    jz cciCopyNext
;
    mov bp,fs:[esi].qtd_buffer_size
    push es
    push ecx
    push esi
    mov ax,gs
    mov es,ax
    mov esi,fs:[esi].qtd_buffer_va
    movzx ecx,bp
    rep movs byte ptr es:[edi],fs:[esi]
    pop esi
    pop ecx
    pop es
;
    push cx
    mov cx,bp
    mov edx,fs:[esi].qtd_buffer_va
    FreeLinearMemBlk
    pop cx
;
    add cx,bp

cciCopyNext:
    xchg edx,esi
    mov esi,fs:[edx].qtd_next_va
;
    push cx
    mov cx,SIZE control_qtd_struc
    FreeLinearMemBlk
    pop cx
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
;       DESCRIPTION:    Setup control OUT
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;                       GS:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControlOut   Proc near
    pushad
;
    mov esi,edi
    mov edi,es:dev_control_qtd
    or cx,cx
    jz scoStatusIn
;
    mov bp,8000h

scoLoop:
    push cx
    mov cx,SIZE control_qtd_struc
    AllocateMemBlk
    pop cx
    jc scoDone
;
    mov fs:[edi].qtd_next,eax
    mov fs:[edi].qtd_next_va,edx
;
    mov edi,edx
    mov fs:[edi].qtd_next,1
    mov fs:[edi].qtd_alt,1
    mov fs:[edi].qtd_status,80h
    mov fs:[edi].qtd_flags,0Ch
    mov fs:[edi].qtd_page0,0
    mov fs:[edi].qtd_page1,0
    mov fs:[edi].qtd_page2,0
    mov fs:[edi].qtd_page3,0
    mov fs:[edi].qtd_page4,0
    mov fs:[edi].qtdu64_page0,0
    mov fs:[edi].qtdu64_page1,0
    mov fs:[edi].qtdu64_page2,0
    mov fs:[edi].qtdu64_page3,0
    mov fs:[edi].qtdu64_page4,0
    mov fs:[edi].qtd_next_va,0
    mov fs:[edi].qtd_buffer_va,0
    mov fs:[edi].qtd_buffer_size,0
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
    jc sciDone
;
    mov fs:[edi].qtd_buffer_va,edx
    mov fs:[edi].qtd_buffer_size,bx
;
    mov fs:[edi].qtd_page0,eax
    mov ax,bx    
    or ax,bp
    mov fs:[edi].qtd_size,ax
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
    xor bp,8000h
    sub cx,bx
    jnz scoLoop

scoStatusIn: 
    mov cx,SIZE control_qtd_struc
    AllocateMemBlk
    jc scoDone
;
    mov fs:[edi].qtd_next,eax
    mov fs:[edi].qtd_next_va,edx
;
    mov edi,edx
    mov fs:[edi].qtd_next,1
    mov fs:[edi].qtd_alt,1
    mov fs:[edi].qtd_status,80h
    mov fs:[edi].qtd_flags,8Dh
    mov fs:[edi].qtd_size,8000h
    mov fs:[edi].qtd_page0,0
    mov fs:[edi].qtd_page1,0
    mov fs:[edi].qtd_page2,0
    mov fs:[edi].qtd_page3,0
    mov fs:[edi].qtd_page4,0
    mov fs:[edi].qtdu64_page0,0
    mov fs:[edi].qtdu64_page1,0
    mov fs:[edi].qtdu64_page2,0
    mov fs:[edi].qtdu64_page3,0
    mov fs:[edi].qtdu64_page4,0
    mov fs:[edi].qtd_next_va,0
    mov fs:[edi].qtd_buffer_va,0
    mov fs:[edi].qtd_buffer_size,0
    clc

scoDone:
    popad
    ret
SetupControlOut	Endp

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
    push ds
    pushad
;
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:is_dev_connected_proc
    pop ds
    jc rcDone
;
    GetThread
    mov es:dev_control_thread,ax
    mov es:dev_control_status,0FFh
;
    mov edx,es:dev_control_qtd
    LinearToPhysicalMemBlk
    mov edx,es:dev_control_qh
    mov fs:[edx].qh_status,0
    mov fs:[edx].qh_current_qtd,0
    mov fs:[edx].qh_next_qtd,eax
;
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
    mov es:dev_control_thread,0
    mov al,es:dev_control_status
    or al,al
    stc
    jnz rcDone
;
    clc

rcDone:
    popad
    pop ds
    ret
RunControl Endp

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
    mov esi,es:dev_control_qtd
    mov esi,fs:[esi].qtd_next_va

ccLoop:
    or esi,esi
    jz ccDone
;
    mov edx,fs:[esi].qtd_buffer_va
    or edx,edx
    jz ccBufferOk
;
    mov cx,fs:[esi].qtd_buffer_size
    FreeLinearMemBlk

ccBufferOk:
    xchg edx,esi
    mov esi,fs:[edx].qtd_next_va
;
    mov cx,SIZE control_qtd_struc
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
    jmp cmDone

cmDataOut:
    call SetupControlOut
    jc cmFail
;
    call RunControl
    jc cmFail
;
    call CleanupControl
    clc
    jmp cmDone

cmFail:
    push edx
    mov edx,es:dev_control_qh
    mov fs:[edx].qh_status,0
    mov eax,1
    xchg eax,fs:[edx].qh_next_qtd
    test al,1
    pop edx
    jnz cmFailClean
;
    mov ax,25
    WaitMilliSec

cmFailClean:
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
;       NAME:           AllocatePipe
;
;       DESCRIPTION:    Allocate pipe
;
;       PARAMETERS:     FS      Flat sel
;                       CX      Buffer count
;
;       RETURNS:        BX      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePipe    Proc near
    push gs
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    inc cx
    mov esi,edi
    push es
    movzx eax,cx
    shl ax,3
    add ax,OFFSET ep_entry_arr
    AllocateSmallGlobalMem
;
    mov es:ep_entry_count,cx
    mov ax,es
    mov gs,ax
    pop es
;
    mov di,OFFSET ep_entry_arr

apTdLoop:
    call AllocateQtd
    mov gs:[di],edx
    xor edx,edx
    mov gs:[di+4],edx
    add di,8
    loop apTdLoop
;
    mov bx,gs
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop gs
    ret
AllocatePipe    Endp

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
    push fs
    push gs
    push eax
    push edx
;
    mov ax,flat_sel
    mov fs,ax
    call AllocatePipe
    mov gs,bx
    call AddBulkQh
;
    mov gs:ep_rd_ptr,0
    mov gs:ep_wr_ptr,0
    mov gs:ep_tail_ptr,0
    clc
;
    pop edx
    pop eax
    pop gs
    pop fs
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
    push fs
    push gs
    push eax
    push edx
;
    mov ax,flat_sel
    mov fs,ax
    call AllocatePipe
    mov gs,bx
    mov al,dh
    call AddIntrQh
;
    mov gs:ep_rd_ptr,0
    mov gs:ep_wr_ptr,0
    mov gs:ep_tail_ptr,0
    clc
;
    pop edx
    pop eax
    pop gs
    pop fs
    retf32
CreateIntrPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartInPipe
;
;       DESCRIPTION:    Start input pipe
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device selector
;                       FS      Flat sel
;                       GS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartInPipe     Proc near
    pushad
;
    mov si,OFFSET ep_entry_arr
    mov cx,gs:ep_entry_count
    xor edi,edi

sipLoop:
    mov edx,gs:[si]
    or edi,edi
    jz sipNext
;
    LinearToPhysicalMemBlk
    mov fs:[edi].qtd_next,eax

sipNext:
    mov edi,edx
    mov fs:[edi].qtd_next,1
    mov fs:[edi].qtd_alt,1
    mov fs:[edi].qtd_status,80h
    mov fs:[edi].qtd_flags,8Dh
;
    mov edx,gs:[si+4]
    or edx,edx
    jnz sipConv
;
    push cx
    mov cx,gs:ued_maxsize
    AllocateMemBlk
    mov gs:[si+4],edx
    pop cx
    jmp sipSave

sipConv:
    LinearToPhysicalMemBlk

sipSave:
    mov fs:[edi].qtd_page0,eax
    mov ax,gs:ued_maxsize
    mov fs:[edi].qtd_size,ax
    add si,8
    loop sipLoop
;
    mov ax,gs:ep_entry_count
    dec ax
    mov gs:ep_tail_ptr,ax
;
    popad
    ret
StartInPipe     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartPipe
;
;       DESCRIPTION:    Start pipe
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device selector
;                       FS      Flat sel
;                       GS      Pipe selector
;                       
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartPipe  Proc near
    push eax
    push ebx
    push edx
;
    mov edx,gs:ep_qh
    mov al,es:usbd_address
    mov fs:[edx].qh_adress,al
    mov al,gs:ued_address
    and al,0Fh
    mov ah,fs:[edx].qh_endpoint
    and ah,0B0h
    or al,ah
    mov fs:[edx].qh_endpoint,al

;
    mov al,gs:ued_attrib
    and al,3
    cmp al,3
    je spIntr

spBulk:
    mov ax,gs:ued_maxsize
    or ax,0F000h
    mov fs:[edx].qh_max_packet,ax
    jmp spDo

spIntr:
    mov ax,gs:ued_maxsize
    mov fs:[edx].qh_max_packet,ax

spDo:
    mov bx,gs:ep_tail_ptr
    or bx,bx
    jz spDone
;
    mov edx,gs:ep_entry_arr
    LinearToPhysicalMemBlk
    mov edx,gs:ep_qh
    mov fs:[edx].qh_next_qtd,eax

spDone:
    pop edx
    pop ebx
    pop eax
    ret
StartPipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EnablePipe
;
;       DESCRIPTION:    Enable pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnablePipe   Proc far
    push ds
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    mov dl,gs:ued_address
    test dl,80h
    jnz epIn

epOut:
    call StartPipe
    clc
    jmp epDone

epIn:
    call StartInPipe
    call StartPipe
    clc

epDone:
    popad
    pop fs
    pop ds
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
    push fs
    push eax
    push edx
;
    mov ax,flat_sel
    mov fs,ax
    mov edx,gs:ep_qh
    mov fs:[edx].qh_next_qtd,1
    mov fs:[edx].qh_status,0
;
    pop edx
    pop eax
    pop fs
    retf32
DisablePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UsedBuffers
;
;       DESCRIPTION:    Used buffers in pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
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
;       DESCRIPTION:    Free buffers in pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
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
;       NAME:           IsRunning
;
;       DESCRIPTION:    Check if conntroller is running
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsRunning   Proc far
    push gs
    push eax
;
    mov gs,ds:ehc_reg_sel
    mov eax,gs:HcCommand
    test al,1
    stc
    jz irDone
;
    clc

irDone:
    pop eax
    pop gs
    retf32
IsRunning   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkControl
;
;       DESCRIPTION:    Unlink control
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkControl   Proc near
    mov edx,es:dev_control_qh
    call UnlinkAsyncQh
    ret
UnlinkControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkPipe
;
;       DESCRIPTION:    Unlink pipe
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device
;                       BX      Pipe sel
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkPipe   Proc near
    ret
UnlinkPipe      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Unlink
;
;       DESCRIPTION:    Unlink dev
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Unlink   Proc far
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    call UnlinkControl
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

udvInLoop:
    mov bx,es:[si]
    or bx,bx
    jz udvInNext
;
    call UnlinkPipe

udvInNext:
    add si,2
    loop udvInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

udvOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz udvOutNext
;
    call UnlinkPipe

udvOutNext:
    add si,2
    loop udvOutLoop
;
    movzx si,es:usbd_port
    add si,si
    mov ds:[si].ehc_dev_arr,0
;
    popad
    pop fs
    retf32
Unlink     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               AllocateAddress
;
;       DESCRIPTION:        Allocate address
;
;       PARAMETERS:         DS      Function selector
;
;       RETURNS:            AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateAddress   Proc far
    AllocateUsbAddress    
    retf32
AllocateAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               FreeAddress
;
;       DESCRIPTION:        Free address
;
;       PARAMETERS:         DS      Function selector
;                           AL      Address
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
    push fs
    pushad
;
    push dx
    mov ax,flat_sel
    mov fs,ax
;
    test ds:ehc_hcc_flags,HCC_64
    jz cd32

cd64:
    mov ax,SIZE qtd64_struc
    jmp cdCreate

cd32:
    mov ax,SIZE qtd32_struc

cdCreate:
    mov si,SIZE ehci_dev_sel
    mov cx,16
    CreateMemBlk32
;
    mov cx,SIZE control_qtd_struc
    AllocateMemBlk
    call InitQtd64
    mov es:dev_control_qtd,edx
    mov es:dev_control_thread,0
;
    pop di
    add di,di
    mov ds:[di].ehc_dev_arr,es
;
    popad
    pop fs
;
    InitUsbDev
    retf32
CreateDev  Endp

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
;                           DL      Config #
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
;                   DL      Port # (0..EHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handler_thread_name  DB 'EHCI Dev ', 0

handler_thread:
    mov cl,dl
    mov ds,bx
    mov gs,ds:ehc_reg_sel
;    
    movzx edi,cl
    add edi,edi
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[edi].usb_thread_arr,ax
    LeaveSection ds:usb_section

htTryAttach:
    mov dx,10

htCheck:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[2*edi].HcPortSc
    test al,1
    jz htDetached
;
    sub dx,1
    jnz htCheck
;
    and ax,0C00h
    cmp ax,400h
    jne htDoReset
;
    test ds:ehc_flags,EHC_COMPANION
    jz htDetached
;
    cmp cl,ds:ehc_comp_ports
    jae htDetached
;    
    mov eax,3000h
    mov gs:[2*edi].HcPortSc,eax
    jmp htDetached
    
htDoReset:    
    LockUsb
;    
    mov eax,gs:[2*edi].HcPortSc
    and al,NOT 4
    or ax,100h
    mov gs:[2*edi].HcPortSc,eax
;
    mov ax,25
    WaitMilliSec
;    
    mov eax,gs:[2*edi].HcPortSc
    and ax,NOT 100h
    mov gs:[2*edi].HcPortSc,eax
;
    mov ax,25
    WaitMilliSec
;
    mov eax,gs:[2*edi].HcPortSc
    test al,1
    jz htUnlock
;    
    test al,4
    jnz htHighSpeed
;
    test ds:ehc_flags,EHC_COMPANION
    jz htUnlock
;
    cmp cl,ds:ehc_comp_ports
    jae htUnlock
;    
    mov ax,3000h
    mov gs:[2*edi].HcPortSc,eax
    jmp htUnlock
        
htHighSpeed:    
    and ax,NOT 100h
    mov gs:[2*edi].HcPortSc,eax
    
htResetLoop:
    mov eax,gs:[2*edi].HcPortSc
    test al,1
    jz htUnlock
;    
    test ax,100h
    jz htResetDone
;
    mov ax,5
    WaitMilliSec
    jmp htResetLoop

htResetDone:
    mov ax,2
    WaitMilliSec
;
    mov eax,gs:[2*edi].HcPortSc
    test al,1
    jz htUnlock
;    
    test al,4
    jnz htNotify
;    
    test ds:ehc_flags,EHC_COMPANION
    jz htUnlock
;
    cmp cl,ds:ehc_comp_ports
    jae htUnlock
;    
    mov eax,3000h
    mov gs:[2*edi].HcPortSc,eax
    jmp htUnlock
        
htNotify:
    mov dx,40

htWaitNotify:    
    mov ax,10
    WaitMilliSec
;
    mov eax,gs:[2*edi].HcPortSc
    test al,1
    jz htUnlock
;
    sub dx,1
    jnz htWaitNotify
;
    call fword ptr ds:allocate_address_proc
    jc htUnlock
;
    push dx
    mov ah,2
    xor bx,bx
    movzx dx,cl
    call fword ptr ds:create_dev_proc
    pop dx
;
    call fword ptr ds:create_control_proc
    call fword ptr ds:address_device_proc
    jc htUnlockFree
;
    call fword ptr ds:change_address_proc
    AddUsbDevice
    UnlockUsb
    ReadUsbDescriptors
    jc htDetach
;
    mov al,cl
    NotifyUsbAttach

htAttached:
    WaitForSignal
;
    call fword ptr ds:is_dev_connected_proc
    jc htDetach
;
    mov ax,1
    shl ax,cl
    test ax,ds:ehc_reset
    jz htHandle
;
    not ax
    lock and ds:ehc_reset,ax
    jmp htDetach

htHandle:
    jmp htAttached

htUnlockFree:
    UnlinkUsbDev
    FreeUsbDev

htUnlock:
    mov eax,gs:[2*edi].HcPortSc
    test ax,2000h
    jnz htDoUnlock
;
    and al,NOT 4
    mov gs:[2*edi].HcPortSc,eax

htDoUnlock:
    mov ax,5
    WaitMilliSec
;
    UnlockUsb
    jmp htDetached

htDetach:
    UnlinkUsbDev
;
    mov al,cl
    NotifyUsbDetach
;
    FreeUsbDev

htDetached:
    mov eax,gs:[2*edi].HcPortSc
    test ax,2000h
    jnz htDone
;
    and al,NOT 4
    mov gs:[2*edi].HcPortSc,eax
;
    mov dx,10

htWaitDisable:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[2*edi].HcPortSc
    test al,1
    jz htDone
;
    test al,4
    jz htTryAttach
;
    sub dx,1
    jnz htWaitDisable
    jmp htTryAttach

htDone:    
    EnterSection ds:usb_section
    mov ds:[edi].usb_thread_arr,0
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
;               CL      Port # (0..EHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push ds
    push es
    push fs
    pushad
;    
    movzx si,cl
    shl si,2
    movzx edi,cl
    add edi,edi
;
    mov eax,es:[2*edi].HcPortSc
    test ax,2000h
    jnz upDone
;    
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
    test ax,ds:ehc_reset
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
;           NAME:           UpdateAllPorts
;
;           DESCRIPTION:    Update all root-hub port status
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateAllPorts   Proc near
    push cx
;    
    xor cl,cl
    mov es,ds:ehc_reg_sel
    mov eax,es:HcCommand
    test al,1
    jnz uaPortLoop
;
    int 3

uaPortLoop:
    cmp cl,ds:ehc_ports
    jae uaPortDone
;    
    call UpdatePort
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
;           NAME:           UpdateUsb
;
;           DESCRIPTION:    Update USB status
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateUsb  Proc near
    mov ax,SEG data
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
;       NAME:           ReportStatus
;
;       DESCRIPTION:    Report status
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       AL      Status
;                       DL      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReportStatus   Proc near
    push ax
    push si
;
    movzx si,es:usbd_port
;
    test al,40h
    jz rsNotStalled
;
    mov ax,USB_EVENT_STALL
    ReportUsbRegPipeEvent
    jmp rsDone

rsNotStalled:
    test al,20h
    jz rsNotBufferError
;
    mov ax,USB_EVENT_DATA_BUFFER_ERROR
    ReportUsbRegPipeEvent
    jmp rsDone

rsNotBufferError:
    test al,10h
    jz rsNotBabble
;
    mov ax,USB_EVENT_BABBLE
    ReportUsbRegPipeEvent
    jmp rsDone

rsNotBabble:
    test al,8
    jz rsNotTransErr
;
    mov ax,USB_EVENT_TRANS_ERROR
    ReportUsbRegPipeEvent
    jmp rsDone

rsNotTransErr:
    test al,4
    jz rsNotMicro
;
    mov ax,USB_EVENT_MISSED_MICROFRAME
    ReportUsbRegPipeEvent
    jmp rsDone

rsNotMicro:
    mov ax,USB_EVENT_HALTED
    ReportUsbRegPipeEvent

rsDone:
    pop si
    pop ax
    ret
ReportStatus   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckControl
;
;       DESCRIPTION:    Check control
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckControl   Proc near
    push ebx
    push edx
;
    mov edx,es:dev_control_qtd

cctLoop:
    mov al,fs:[edx].qtd_status
    test al,80h
    jnz cctDone
;
    and al,7Ch
    jnz cctSignal
;
    mov edx,fs:[edx].qtd_next_va
    or edx,edx
    jnz cctLoop

cctSignal:
    mov es:dev_control_status,al
;    
    or al,al
    jz cctReportDone
;
    xor dl,dl
    call ReportStatus

cctReportDone:
    xor bx,bx
    xchg bx,es:dev_control_thread
    Signal

cctDone:
    pop edx
    pop ebx
    ret
CheckControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckPipe
;
;       DESCRIPTION:    Check pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPipe   Proc near
    ret
CheckPipe   Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           EHCI function handler
;
;   DESCRIPTION:    EHCI function thread
;
;   PARAMETERS:     BX      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ehci_function_handler:
    mov ds,bx
    GetThread
    mov ds:ehc_thread,ax
    mov ax,flat_sel
    mov fs,ax

efhLoop:
    WaitForSignal
;
    call fword ptr ds:is_running_proc
    jnc efhRunning
;
    mov ax,USB_EVENT_CONTROLLER_ERROR
    ReportUsbFunctionEvent

efhRunning:
    movzx cx,ds:ehc_ports
    mov bx,OFFSET ehc_dev_arr

efhDevLoop:
    mov ax,ds:[bx]
    or ax,ax
    jz efhDevNext
;
    mov es,ax
    mov ax,es:dev_control_thread
    or ax,ax
    jz efhDevPipes
;
    call CheckControl

efhDevPipes:
    push ebx
    push ecx
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

efhDevInLoop:
    mov bx,es:[si]
    or bx,bx
    jz efhDevInNext
;
    mov gs,bx
    call CheckPipe

efhDevInNext:
    add si,2
    loop efhDevInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

efhDevOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz efhDevOutNext
;
    mov gs,bx
    call CheckPipe

efhDevOutNext:
    add si,2
    loop efhDevOutLoop
;
    pop ecx
    pop ebx

efhDevNext:
    add bx,2
    loop efhDevLoop
;
    jmp efhLoop

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
;           DESCRIPTION:    Start EHCI function thread
;
;       PARAMETERS:         DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

func_name    DB 'EHCI ', 0

StartFunctionThread Proc near
    mov si,OFFSET ehci_function_handler
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
;           DESCRIPTION:    Init EHCI function
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ehci_tab:
et00 DD OFFSET AllocateAddress,    SEG code
et01 DD OFFSET FreeAddress,        SEG code
ec02 DD OFFSET CreateDev,          SEG code
et03 DD OFFSET CreateControl,      SEG code
et04 DD OFFSET ChangeAddress,      SEG code
et05 DD OFFSET ResetDev,           SEG code
et06 DD OFFSET AddressDev,         SEG code
et07 DD OFFSET ConfigDev,          SEG code
et08 DD OFFSET UpdateMaxLen,       SEG code
ec09 DD OFFSET IsDeviceConnected,  SEG code
ec0A DD OFFSET ControlMsg,         SEG code
ec0B DD OFFSET CreateBulkPipe,     SEG code
ec0C DD OFFSET CreateIntrPipe,     SEG code
ec0D DD OFFSET Unlink,             SEG code
ec0E DD OFFSET EnablePipe,         SEG code
ec0F DD OFFSET DisablePipe,        SEG code
ec10 DD OFFSET UsedBuffers,        SEG code
ec11 DD OFFSET FreeBuffers,        SEG code
ec12 DD OFFSET ReqBuffer,          SEG code
ec13 DD OFFSET RelBuffer,          SEG code
ec14 DD OFFSET IsRunning,          SEG code

;
;           PARAMETERS:         BH          Bus
;                           BL          Device
;                           CH          Function
;               AL      Capability

InitFunction    Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov es,ax   
    mov ax,ds:ehc_version
    cmp ax,-1
    je ifDone
;    
    mov si,OFFSET ehci_tab
    xor di,di
    mov cx,2*15h

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbFunction
    InitSection ds:ehc_section
;
    push es
    mov ax,ds
    mov es,ax
    mov di,OFFSET ehc_dev_arr
    mov cx,MAX_USB_HUB_PORTS
    xor ax,ax
    rep stosw
    pop es
;
    mov bh,ds:ehc_bus
    mov bl,ds:ehc_device
    mov ch,ds:ehc_function
;    
    mov al,ds:ehc_eecp
    or al,al
    cmp al,40h
    jae ifLegacyFound

ifCheckCap:    
    mov al,1
    FindPciCapability
    jc ifLegacyOff

ifLegacyFound:
    mov cl,al
    ReadPciDword
;
    cmp al,1
    jne ifCheckCap    
;    
    shr eax,16
    add cl,2
    or al,al
    jz ifLegacyDone
;
    inc cl
    mov al,1
    WritePciByte
;
    dec cl    
    ReadPciByte
    or al,al
    jz ifLegacyDone
;
    mov ax,100
    WaitMilliSec
;    
    add cl,2
    ReadPciDword
    xor eax,eax
    WritePciDword
;    
    mov fs,ds:ehc_reg_sel
    mov fs:HcConfig,0
    jmp ifLegacyOff
    
ifLegacyDone:
    add cl,2
    ReadPciDword
    xor eax,eax
    WritePciDword
        
ifLegacyOff:
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
    mov edi,OFFSET EhciInt
    RequestMsiHandler
    jmp ifIntDone

ifIrq:
    GetPciIrqNr
    jc ifIrqFail
;    
    mov ah,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET EhciInt
    RequestIrqHandler
    jmp ifIntDone

ifIrqFail:
    mov ax,SEG data
    mov es,ax
    mov es:UseTimer,1

ifIntDone:    
    mov fs,ds:ehc_reg_sel
    mov fs:HcSegmentSelector,0
;
    mov eax,fs:HcCommand
    and al,NOT 31h
    mov fs:HcCommand,eax
;    
    mov ax,25
    WaitMilliSec
;
    mov eax,fs:HcCommand
    or al,2
    mov fs:HcCommand,eax

ifWaitReset:
    mov eax,fs:HcCommand
    test al,2
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
;
    mov ax,100
    WaitMilliSec
;    
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
    mov eax,7
    mov fs:HcInterruptEnable,eax
;    
    call CreateInterrupt

ifDone:
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
;           DESCRIPTION:    Add EHCI function
;
;       PARAMETERS:     BX      Bus/device
;               CH      Function
;               EAX     Register base
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
    push bx
    push cx
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    push eax
    and ax,0F000h
    xor ebx,ebx
    or ax,813h
    SetPageEntry
    pop eax
    and eax,0FFFh
    or edx,eax
;
    push ecx
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
    mov bp,bx
;     
    mov eax,SIZE ehci_func_sel
    mov cx,ax
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    xor di,di
    xor al,al
    rep stosb
;
    pop cx
    pop bx
;
    mov ds:ehc_bus,bh
    mov ds:ehc_device,bl
    mov ds:ehc_function,ch    
;
    mov ds:ehc_reg_sel,bp
    mov ds:ehc_reset,0
    mov ds:ehc_async_head_va,0
;
    mov es,bp
    mov cl,es:hcp_CAPLEN
    mov ds:ehc_op_offs,cl
    mov ds:ehc_flags,0
;
    mov ax,es:hcp_HCIVERSION
    mov ds:ehc_version,ax    
;
    mov al,byte ptr es:hcp_HCCPARAMS
    mov ds:ehc_hcc_flags,al
;    
    mov al,byte ptr es:hcp_HCCPARAMS+1
    mov ds:ehc_eecp,al
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
    mov al,ah
    and al,0Fh
    and ah,0F0h
    shr ah,4
    mul ah    
    mov ds:ehc_comp_ports,al
;    
    mov ax,es:hcp_HCSPARAMS
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
    mov ax,SEG data
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
    mov ch,20h
    FindPciClass
    jc init_pci_done
;
    mov cl,10h
    ReadPciDword
    and ax,0FF00h
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
InitPciAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EHCI thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ehci_name       DB 'EHCI',0

ehci_thread:
    mov ax,SEG data
    mov ds,ax
    GetThread
    mov ds:PortThread,ax
;    
    WaitForOhci
    WaitForUhci
;    
    mov si,OFFSET EhciFuncArr
    mov cx,ds:EhciFuncCount

etInitLoop:
    ClearSignal
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
    call InitFunction
    call StartFunctionThread
;
    pop si
    pop cx
    pop ds
    add si,2
    loop etInitLoop
;
    mov ax,20
    WaitMilliSec
;
    EnterSection ds:WaitSection
    mov ds:Started,1
    mov bx,ds:WaitThreadArr
    Signal
    mov bx,ds:WaitThreadArr+2
    Signal
    mov bx,ds:WaitThreadArr+4
    Signal
    LeaveSection ds:WaitSection
;
    mov ax,150
    WaitMilliSec
;
    mov al,ds:UseTimer
    or al,al
    jz ehci_thread_loop
;
    GetSystemTime
    add eax,11930
    adc edx,0
    mov bx,cs
    mov es,bx
    mov bx,cs
    mov edi,OFFSET ehci_timer
    StartTimer
    
ehci_thread_loop:
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
;
    call UpdateUsb
    jmp ehci_thread_loop

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
    mov cx,ds:EhciFuncCount
    or cx,cx    
    jz init_usb_done
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET ehci_name
    mov si,OFFSET ehci_thread
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
;           NAME:           WaitForEhci
;
;           DESCRIPTION:    Wait for EHCI to initialize
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_ehci_name  DB 'Wait For Ehci', 0

wait_for_ehci   Proc far
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
    jnz wfeDone    
;
    mov bx,OFFSET WaitThreadArr

wfeLoop:
    mov ax,ds:[bx]
    or ax,ax
    jz wfeFound
;
    add bx,2
    jmp wfeLoop

wfeFound:        
    GetThread
    mov ds:[bx],ax    
    LeaveSection ds:WaitSection   

wfeSignal:
    WaitForSignal
;    
    EnterSection ds:WaitSection    
    mov al,ds:Started
    or al,al
    jz wfeSignal
    
wfeDone:
    LeaveSection ds:WaitSection
;    
    pop bx
    pop ax
    pop ds
    retf32
wait_for_ehci   Endp

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
    mov ds:EhciFuncCount,0
    mov ds:EhciQhList,0
;
    InitSection ds:WaitSection
    mov ds:WaitThreadArr,0
    mov ds:WaitThreadArr+2,0
    mov ds:WaitThreadArr+4,0
    mov ds:Started,0
    mov ds:UseTimer,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET wait_for_ehci
    mov edi,OFFSET wait_for_ehci_name
    xor cl,cl
    mov ax,wait_for_ehci_nr
    RegisterOsGate
;
    mov edi,OFFSET init_usb
    HookInitPci
    clc
;       
    ret
Init    Endp

code ENDS

    END init
