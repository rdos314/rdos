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
INCLUDE ..\acpi\pci.inc
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

ehc_dev_arr         DW 127 DUP(?)

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
dev_control_status  DB ?

ehci_dev_sel     ENDS

ehci_pipe_struc    STRUC

ep_pipe            usb_pipe_struc <>

ep_qh              DD ?
ep_table           DW ?
ep_table_size      DW ?
ep_entry           DW ?

ehci_pipe_struc    ENDS

ehci_raw_sel       STRUC

er_base            usb_raw_struc <>

er_td              DD ?
er_size            DW ?

ehci_raw_sel       ENDS

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
    call InitQh
;
    pop ecx
    pop ebx
    pop ds
    ret
AllocateQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeQh
;
;       DESCRIPTION:    Free QH
;
;       PARAMETERS:     FS      Flat sel
;
;       PARAMETERS:     EDX     QH linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeQh     PROC near
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
FreeQh     ENDP

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
;       NAME:           FreeQtd
;
;       DESCRIPTION:    Free qTD
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       EDX     Linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeQtd     PROC near
    push ecx
;
    test ds:ehc_hcc_flags,HCC_64
    jz fqt32

fqt64:
    mov cx,SIZE qtd64_struc
    FreeLinearMemBlk
    jmp fqtDone

fqt32:    
    mov cx,SIZE qtd32_struc
    FreeLinearMemBlk

fqtDone:
    pop ecx
    ret
FreeQtd  ENDP

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
    mov gs,es:usbd_parent_hub
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
    mov gs,es:usbd_parent_hub
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
;       NAME:           AllocateInactiveIntQh
;
;       DESCRIPTION:    Allocate inactive int QH
;
;       RETURNS:        EDX     Linear address
;                       EAX     Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateInactiveIntQh PROC near
    call AllocateQh
    mov fs:[edx].qh_adress,80h
    ret
AllocateInactiveIntQh ENDP

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
    push ax
    mov si,ax
    shl si,3
    mov edx,ds:[bx+si].ehc_qh
    mov al,fs:[edx].qh_adress
    test al,80h
    jnz aieQhOk
;
    call AllocateQh 

aieQhOk:
    pop ax
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
    mov gs,es:usbd_parent_hub
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
    mov fs:[edx].qh_link_va,eax
    mov eax,fs:[ecx].qh_link
    mov fs:[edx].qh_link,eax    
;    
    mov fs:[edi].qh_link_va,edx
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
    EnterSection ds:ehc_section
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
    LeaveSection ds:ehc_section
;
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
;                       EDX     QH linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkIntrQh    PROC near
    pushad
;
    mov bx,gs:ep_table
    mov si,gs:ep_entry
    shl si,3
    mov bp,gs:ep_table_size
    mov cx,bp
    shr cx,4
;    
    mov edi,ds:[bx+si].ehc_qh
    cmp edx,edi
    jne uiqSearch
;
    mov fs:[edx].qh_current_qtd,0
    mov fs:[edx].qh_next_qtd,1
    mov fs:[edx].qh_alt_qtd,1
    mov fs:[edx].qh_status,0
    mov fs:[edx].qh_adress,80h
    jmp uiqUpdate
        
uiqSearch:    
    or edi,edi
    jz uiqUpdate
;    
    cmp edx,fs:[edi].qh_link_va
    je uiqUpdate
;
    mov edi,fs:[edi].qh_link_va
    jmp uiqSearch

uiqFound:        
    mov eax,fs:[edx].qh_link_va
    mov fs:[edi].qh_link_va,eax
;
    mov eax,fs:[edx].qh_link
    mov fs:[edi].qh_link,eax   

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
;           NAME:           IsPortConnected
;
;           DESCRIPTION:    Check if port is connected
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsPortConnected   Proc far
    push es
    push eax
    push esi
;    
    movzx si,dl
    shl si,2
    mov es,ds:ehc_reg_sel
    mov eax,es:[si].HcPortSc
    test al,1
    clc
    jnz ipcDone

ipcFail:   
    stc

ipcDone:
    pop esi
    pop eax
    pop es
    retf32
IsPortConnected Endp

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
SetupControl    Endp

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
SetupControlIn  Endp

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
CopyControlIn   Endp

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
SetupControlOut Endp

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

control_text DB 'USB Control', 0

RunControl   Proc near
    push ds
    pushad
;
    test es:usbd_flags,DEV_FLAG_DETACHED
    stc
    jnz rcDone
;    
    push ds
    mov ds,es:usbd_func_sel
    call fword ptr ds:is_dev_connected_proc
    pop ds
    jc rcDone
;
    lock or es:usbd_flags,DEV_FLAG_CONTROL_ACTIVE
    mov es:dev_control_status,0FFh
;
    push es
    mov bx,es:usbd_wait_dev
    mov ax,cs
    mov es,ax
    mov edi,OFFSET control_text
    PrepareWaitDev
    pop es
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
    mov bx,es:usbd_wait_dev
    WaitForDev
    lock and es:usbd_flags,NOT DEV_FLAG_CONTROL_ACTIVE
;
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
    push es
    push eax
;
    mov eax,SIZE ehci_pipe_struc
    AllocateSmallGlobalMem
    mov bx,es
;
    pop eax
    pop es
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
;       NAME:           StopTds
;
;       DESCRIPTION:    Stop TDs
;
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopTds Proc near
    push fs
    push eax
    push edx
;
    lock and gs:usbp_flags,NOT PIPE_FLAG_ACTIVE
;
    mov ax,flat_sel
    mov fs,ax
    mov edx,gs:ep_qh
    mov eax,1
    xchg eax,fs:[edx].qh_next_qtd
    mov fs:[edx].qh_status,0
    test al,1
    jnz stDone
;
    mov ax,5
    WaitMilliSec

stDone:
    pop edx
    pop eax
    pop fs
    ret
StopTds Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreePacketTds
;
;       DESCRIPTION:    Free TDs in ring
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device selector
;                       FS      Flat sel
;                       GS      Pipe selector
;                       BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePacketTds Proc near
    push gs
    pushad
;
    mov bp,gs:ued_maxsize
    mov gs,bx
    mov si,SIZE usb_packet_struc
    mov cx,gs:usbpk_entry_count

ftdLoop:
    mov edx,gs:[si]
    or edx,edx
    jz ftdBuf
;
    call FreeQtd

ftdBuf:
    mov edx,gs:[si+4]
    or edx,edx
    jz ftdNext
;
    push cx
    mov cx,bp
    FreeLinearMemBlk
    pop cx

ftdNext:
    add si,8
    loop ftdLoop
;
    popad
    pop gs
    ret
FreePacketTds Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPacket
;
;       DESCRIPTION:    Open pipe packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       CX      Packet count
;
;       RETURNS:        BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPacket    Proc near
    push fs
    push gs
    push eax
    push ecx
    push edx
    push edi
;
    mov ax,flat_sel
    mov fs,ax
;
    inc cx
    movzx eax,cx
    shl ax,3
    add ax,SIZE usb_packet_struc
;
    push es
    AllocateSmallGlobalMem
    mov ax,es
    pop es
;
    mov gs,ax
    mov gs:usbpk_entry_count,cx
    mov gs:usbpk_tail_ptr,0
;
    mov di,SIZE usb_packet_struc

atdrLoop:
    call AllocateQtd
    mov gs:[di],edx
    xor edx,edx
    mov gs:[di+4],edx
    add di,8
    loop atdrLoop
;
    mov bx,gs
    clc
;
    pop edi
    pop edx
    pop ecx
    pop eax
    pop gs
    pop fs
    retf32
OpenPacket       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClosePacket
;
;       DESCRIPTION:    Close pipe packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;                       BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePacket   Proc far
    push ds
    push fs
    push ax
    push bx
;
    mov ax,flat_sel
    mov fs,ax
;
    call StopTds
    call FreePacketTds
;
    push es
    mov es,bx
    FreeMem
    pop es
;
    pop bx
    pop ax
    pop fs
    pop ds
    retf32
ClosePacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartPacket
;
;       DESCRIPTION:    Start pipe packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartPacket   Proc far
    push ds
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    mov ds,gs:usbp_packet_sel
    mov si,SIZE usb_packet_struc
    mov cx,ds:usbpk_entry_count
    dec cx
    xor edi,edi

sipLoop:
    mov edx,ds:[si]
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
    mov edx,ds:[si+4]
    or edx,edx
    jnz sipConv
;
    push cx
    mov cx,gs:ued_maxsize
    AllocateMemBlk
    mov ds:[si+4],edx
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
    mov ax,ds:usbpk_entry_count
    dec ax
    mov ds:usbpk_tail_ptr,ax
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
    lock or gs:usbp_flags,PIPE_FLAG_ACTIVE
;
    mov ds,gs:usbp_packet_sel
    mov bx,ds:usbpk_tail_ptr
    or bx,bx
    jz spDone
;
    mov si,SIZE usb_packet_struc
    mov edx,ds:[si]
    LinearToPhysicalMemBlk
    mov edx,gs:ep_qh
    mov fs:[edx].qh_next_qtd,eax

spDone:
    clc
    popad
    pop fs
    pop ds
    retf32
StartPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReqPacket
;
;       DESCRIPTION:    Req packet buffer
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;       RETURNS:        EDX     Buffer linear address
;                       CX      Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqPacket   Proc far
    push ds
    push fs
    push eax
    push ebx
    push esi
;
    mov ax,flat_sel
    mov fs,ax
;
    mov ds,gs:usbp_packet_sel
    mov bx,ds:usbpk_rd_ptr
    cmp bx,ds:usbpk_wr_ptr
    jne rqpkGet
;
    stc
    jmp rqpkDone

rqpkGet:
    shl bx,3
    add bx,SIZE usb_packet_struc
    mov edx,ds:[bx]
    mov cx,gs:ued_maxsize
    mov ax,fs:[edx].qtd_size
    and ax,7FFFh
    sub cx,ax
    mov edx,ds:[bx+4]
    clc

rqpkDone:
    pop esi
    pop ebx
    pop eax
    pop fs
    pop ds
    retf32
ReqPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RelPacket
;
;       DESCRIPTION:    Release packet buffer
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RelPacket   Proc far
    push ds
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
    mov bp,ds:ehc_thread
;
    mov ds,gs:usbp_packet_sel
    EnterSection ds:usbpk_section
;
    mov bx,ds:usbpk_rd_ptr
    cmp bx,ds:usbpk_wr_ptr
    stc
    je rlpkDone
;
    inc bx
    cmp bx,ds:usbpk_entry_count
    jb rlpkPtrOk
;
    xor bx,bx

rlpkPtrOk:
    mov ds:usbpk_rd_ptr,bx
;
    mov bx,ds:usbpk_tail_ptr
    sub bx,1
    jnc rlpkPrevOk
;
    mov bx,ds:usbpk_entry_count
    dec bx

rlpkPrevOk:
    shl bx,3
    add bx,SIZE usb_packet_struc
    mov esi,ds:[bx]
;
    mov bx,ds:usbpk_tail_ptr
    mov di,bx
    shl di,3
    add di,SIZE usb_packet_struc
;
    mov edx,ds:[di+4]
    or edx,edx
    jnz rlpkHasBuffer
;
    mov cx,gs:ued_maxsize
    AllocateMemBlk
    mov ds:[di+4],edx

rlpkHasBuffer:
    LinearToPhysicalMemBlk
;
    mov edx,ds:[di]
    mov fs:[edx].qtd_alt,1
    mov fs:[edx].qtd_status,80h
    mov fs:[edx].qtd_flags,8Dh
    mov fs:[edx].qtd_next,1
    mov fs:[edx].qtd_page0,eax
    mov ax,gs:ued_maxsize
    mov fs:[edx].qtd_size,ax
;
    LinearToPhysicalMemBlk
    mov fs:[esi].qtd_next,eax
;
    mov bx,ds:usbpk_tail_ptr
    cmp bx,ds:usbpk_wr_ptr
    pushf
;
    inc bx
    cmp bx,ds:usbpk_entry_count
    jb rlpkTailOk
;
    xor bx,bx

rlpkTailOk:
    mov ds:usbpk_tail_ptr,bx
;
    popf
    je rlpkCheckStart
;
    mov esi,gs:ep_qh
    mov al,fs:[esi].qh_status
    test al,80h
    jnz rlpkOk
;
    mov bx,bp
    Signal
    jmp rlpkOk

rlpkCheckStart:
    mov ebx,eax
    mov esi,gs:ep_qh
    mov al,fs:[esi].qh_status
    test al,80h
    jnz rlpkOk
;
    and al,7Ch
    jnz rlpkOk
;
    mov fs:[esi].qh_next_qtd,ebx
    
rlpkOk:
    clc

rlpkDone:
    LeaveSection ds:usbpk_section
;
    popad
    pop fs
    pop ds
    retf32
RelPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenRaw
;
;       DESCRIPTION:    Open pipe raw interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       CX      Buffer size
;
;       RETURNS:        BX      Raw sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenRaw   Proc far
    push fs
    push eax
    push ecx
    push edx
;
    push gs
;
    push es
    mov eax,SIZE ehci_raw_sel
    AllocateSmallGlobalMem
;
    mov bx,es
    pop es
;
    mov ax,cx
    xor dx,dx
    dec ax
    add ax,gs:ued_maxsize
    cmp ax,1000h
    jbe orInRange
;
    mov ax,1000h

orInRange:
    div gs:ued_maxsize
    mul gs:ued_maxsize
    mov cx,ax
;
    mov gs,bx
    mov gs:usbr_buf_size,cx
;
    AllocateMemBlk
    mov gs:usbr_buf_linear,edx
;
    AllocateGdt
    movzx ecx,cx
    CreateDataSelector16
    mov gs:usbr_buf_sel,bx
;
    mov ax,flat_sel
    mov fs,ax
;
    call AllocateQtd
    mov fs:[edx].qtd_status,80h
    mov gs:er_td,edx
;
    mov bx,gs
    pop gs
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
    je orIntr

orBulk:
    mov ax,gs:ued_maxsize
    or ax,0F000h
    mov fs:[edx].qh_max_packet,ax
    jmp orDone

orIntr:
    mov ax,gs:ued_maxsize
    mov fs:[edx].qh_max_packet,ax

orDone:
    pop edx
    pop ecx
    pop eax
    pop fs
    retf32
OpenRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseRaw
;
;       DESCRIPTION:    Close pipe raw interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;                       BX      Raw sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseRaw   Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    call StopTds
;
    push bx
    mov gs,bx
;
    mov bx,gs:usbr_wait_dev
    CloseWaitDev
;
    mov cx,gs:usbr_buf_size
    mov edx,gs:usbr_buf_linear
    FreeLinearMemBlk
;
    mov bx,gs:usbr_buf_sel
    FreeGdt
;
    mov edx,gs:er_td
    call FreeQtd
;
    xor bx,bx
    mov gs,bx
    pop es
    FreeMem
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    retf32
CloseRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadRaw
;
;       DESCRIPTION:    Read raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       EDX     Linear buffer
;                       CX      Size
;
;       RETURNS:        CX      Read size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadRaw   Proc far
    push ds
    push fs
    push eax
    push ebx
    push edx
;
    mov ax,flat_sel
    mov fs,ax
    mov ds,gs:usbp_raw_sel
;
    mov edx,ds:usbr_buf_linear
    LinearToPhysicalMemBlk
;
    mov ds:er_size,cx
    mov edx,ds:er_td
    mov fs:[edx].qtd_next,1
    mov fs:[edx].qtd_alt,1
    mov fs:[edx].qtd_status,80h
    mov fs:[edx].qtd_flags,8Dh
    mov fs:[edx].qtd_page0,eax
    mov fs:[edx].qtd_size,cx
    LinearToPhysicalMemBlk
;
    lock or gs:usbp_flags,PIPE_FLAG_ACTIVE
    mov edx,gs:ep_qh
    mov fs:[edx].qh_next_qtd,eax
;
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    retf32
ReadRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteRaw
;
;       DESCRIPTION:    Write raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRaw   Proc far
    push ds
    push fs
    push eax
    push ebx
    push edx
;
    mov ax,flat_sel
    mov fs,ax
    mov ds,gs:usbp_raw_sel
;
    mov edx,ds:usbr_buf_linear
    LinearToPhysicalMemBlk
;
    mov ds:er_size,cx
    mov edx,ds:er_td
    mov fs:[edx].qtd_next,1
    mov fs:[edx].qtd_alt,1
    mov fs:[edx].qtd_status,80h
    mov fs:[edx].qtd_flags,8Ch
    mov fs:[edx].qtd_page0,eax
    mov fs:[edx].qtd_size,cx
    LinearToPhysicalMemBlk
;
    ClearSignal
    lock or gs:usbp_flags,PIPE_FLAG_ACTIVE
    mov edx,gs:ep_qh
    mov fs:[edx].qh_next_qtd,eax
;
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    retf32
WriteRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FinishRaw
;
;       DESCRIPTION:    Finish raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;       RETURNS:        NC
;                         CX    Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FinishRaw   Proc far
    push ds
    push fs
    push eax
    push edx
;
    mov ax,flat_sel
    mov fs,ax
    mov ds,gs:usbp_raw_sel
;
    mov edx,ds:er_td
    mov al,fs:[edx].qtd_status
    test al,80h
    jz frOk
;
    call StopTds
    stc
    jmp frDone

frOk:
    lock and gs:usbp_flags,NOT PIPE_FLAG_ACTIVE
;
    mov cx,ds:er_size
    mov ax,fs:[edx].qtd_size
    and ax,7FFFh
    sub cx,ax
    clc

frDone:
    pop edx
    pop eax
    pop fs
    pop ds
    retf32
FinishRaw   Endp

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
;       NAME:           Block
;
;       DESCRIPTION:    Block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Block   Proc far
    EnterSection ds:usb_addr_section
    retf32
Block   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Unblock
;
;       DESCRIPTION:    Unblock
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Unblock   Proc far
    LeaveSection ds:usb_addr_section
    retf32
Unblock   Endp

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
    EnterSection ds:ehc_section
;
    mov edx,es:dev_control_qh
    call UnlinkAsyncQh
;
    LeaveSection ds:ehc_section
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
    push fs
    push gs
    pushad
;   
    mov gs,bx
    mov edx,gs:ep_qh
    mov ax,flat_sel
    mov fs,ax
;
    mov al,gs:ued_attrib
    and al,3
    cmp al,2
    je ulpBulk
;
    cmp al,3
    je ulpIntr
;
    int 3
    jmp ulpDone

ulpBulk:
    EnterSection ds:ehc_section
    call UnlinkAsyncQh
    LeaveSection ds:ehc_section
    jmp ulpDone

ulpIntr:
    EnterSection ds:ehc_section
    call UnlinkIntrQh
    LeaveSection ds:ehc_section

ulpDone:
    popad
    pop gs
    pop fs
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
    movzx si,es:usbd_address
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
    push ax
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
    mov es:usbd_parent_thread,0
;
    pop ax
    movzx di,al
    add di,di
    mov ds:[di].ehc_dev_arr,es
    mov es:usbd_func_sel,ds
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
;       PARAMETERS:         DS      Function selector
;                           ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDev   Proc far
    push fs
    push gs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    mov edx,es:dev_control_qh
    call FreeQh
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

fdvInLoop:
    mov bx,es:[si]
    or bx,bx
    jz fdvInNext
;
    mov gs,bx
    mov edx,gs:ep_qh
    mov al,gs:ued_attrib
    and al,3
    cmp al,3
    jne fdvInFree
;
    test fs:[edx].qh_adress,80h
    jnz fdvInNext

fdvInFree:
    call FreeQh
 
fdvInNext:
    add si,2
    loop fdvInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

fdvOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz fdvOutNext
;
    mov gs,bx
    mov edx,gs:ep_qh
    mov al,gs:ued_attrib
    and al,3
    cmp al,3
    jne fdvOutFree
;
    test fs:[edx].qh_adress,80h
    jnz fdvOutNext

fdvOutFree:
    call FreeQh

fdvOutNext:
    add si,2
    loop fdvOutLoop
;
    popad
    pop gs
    pop fs
    retf32
FreeDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               PowerOffPort
;
;       DESCRIPTION:        Power off port
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerOffPort   Proc far
    push gs
    push eax
    push ecx
    push edi
;
    mov gs,ds:ehc_reg_sel
    movzx edi,dl
    shl edi,2
    add edi,OFFSET HcPortSc
    mov eax,gs:[edi]
    and ax,NOT 1000h
    mov gs:[edi],eax
;
    pop edi
    pop ecx
    pop eax
    pop gs
    retf32
PowerOffPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               PowerOnPort
;
;       DESCRIPTION:        Power on port
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerOnPort   Proc far
    push gs
    push eax
    push ecx
    push edi
;
    mov gs,ds:ehc_reg_sel
    movzx edi,dl
    shl edi,2
    add edi,OFFSET HcPortSc
    mov eax,gs:[edi]
    or ax,1000h
    mov gs:[edi],eax
;
    pop edi
    pop ecx
    pop eax
    pop gs
    retf32
PowerOnPort   Endp

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
    push gs
    push ecx
    push edi
;
    mov gs,ds:ehc_reg_sel
    movzx edi,dl
    shl edi,2
    add edi,OFFSET HcPortSc
;
    mov cx,10

rpCheck:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[edi]
    test al,1
    jz rpFail
;
    loop rpCheck
;
    and ax,0C00h
    cmp ax,400h
    jne rpDoReset
;
    test ds:ehc_flags,EHC_COMPANION
    jz rpFail
;
    cmp dl,ds:ehc_comp_ports
    jae rpFail
;    
    mov eax,3000h
    mov gs:[edi],eax
    jmp rpFail

rpDoReset:    
    mov eax,gs:[edi]
    and al,NOT 4
    or ax,100h
    mov gs:[edi],eax
;
    mov ax,25
    WaitMilliSec
;    
    mov eax,gs:[edi]
    and ax,NOT 100h
    mov gs:[edi],eax
;
    mov ax,25
    WaitMilliSec
;
    mov eax,gs:[edi]
    test al,1
    jz rpFail
;    
    test al,4
    jnz rpHighSpeed
;
    test ds:ehc_flags,EHC_COMPANION
    jz rpFail
;
    cmp dl,ds:ehc_comp_ports
    jae rpFail
;    
    mov ax,3000h
    mov gs:[edi],eax
    jmp rpFail
        
rpHighSpeed:    
    and ax,NOT 100h
    mov gs:[edi],eax
    
rpResetLoop:
    mov eax,gs:[edi]
    test al,1
    jz rpFail
;    
    test ax,100h
    jz rpResetDone
;
    mov ax,5
    WaitMilliSec
    jmp rpResetLoop

rpResetDone:
    mov ax,2
    WaitMilliSec
;
    mov eax,gs:[edi]
    test al,1
    jz rpFail
;    
    test al,4
    jnz rpNotify
;    
    test ds:ehc_flags,EHC_COMPANION
    jz rpFail
;
    cmp dl,ds:ehc_comp_ports
    jae rpFail
;    
    mov eax,3000h
    mov gs:[edi],eax
    jmp rpFail
        
rpNotify:
    mov cx,40

rpWaitNotify:    
    mov ax,10
    WaitMilliSec
;
    mov eax,gs:[edi]
    test al,1
    jz rpFail
;
    loop rpWaitNotify
;
    mov al,2
    clc
    jmp rpDone

rpFail:
    stc

rpDone:
    pop edi
    pop ecx
    pop gs
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
    push gs
    push eax
    push edi
;
    mov gs,ds:ehc_reg_sel
    movzx edi,dl
    shl edi,2
    add edi,OFFSET HcPortSc
;
    mov eax,gs:[edi]
    test ax,2000h
    jnz dpDone
;
    test al,1
    jz dpDone
;
    and al,NOT 4
    mov gs:[edi],eax
;
    mov ax,5
    WaitMilliSec

dpDone:
    pop edi
    pop eax
    pop gs
    retf32
DisablePort Endp

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
    push gs
    push eax
    push ecx
    push edx
    push edi
;
    mov dl,es:usbd_port
    mov gs,ds:ehc_reg_sel
    movzx edi,dl
    shl edi,2
    add edi,OFFSET HcPortSc
;
    mov eax,gs:[edi]
    test ax,2000h
    jnz ddDone
;
    test al,1
    jz ddDone
;
    and al,NOT 4
    mov gs:[edi],eax
;
    mov cx,10

ddWaitDisable:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[edi]
    test al,1
    jz ddDone
;
    test al,4
    jz ddDone
;
    loop ddWaitDisable

ddDone:
    pop edi
    pop edx
    pop ecx
    pop eax
    pop gs
    retf32
DisableDev   Endp

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
;                       DL      Port # (0..EHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push eax
    push ebx
    push edi
;    
    movzx edi,dl
    add edi,edi
    xor bx,bx
;
    mov eax,es:[2*edi].HcPortSc
    test ax,2000h
    jnz upDone
; 
    and al,NOT 8
    test al,10h
    jz upNotify
;
    or al,8

upNotify:
    NotifyUsbPortState   
                
upDone:    
    pop edi
    pop ebx
    pop eax
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
    push dx
;    
    xor dl,dl
    mov es,ds:ehc_reg_sel
    mov eax,es:HcCommand
    test al,1
    jnz uaPortLoop
;
    int 3

uaPortLoop:
    cmp dl,ds:ehc_ports
    jae uaPortDone
;    
    call UpdatePort
;
    inc dl
    jmp uaPortLoop    

uaPortDone:
    pop dx
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
    push ds
    push ax
    push si
;
    movzx si,es:usbd_port
;
    test al,40h
    jz rsNotStalled
;
    mov ax,USB_EVENT_STALL
    ReportUsbPipeEvent
    jmp rsDone

rsNotStalled:
    test al,20h
    jz rsNotBufferError
;
    mov ax,USB_EVENT_DATA_BUFFER_ERROR
    ReportUsbPipeEvent
    jmp rsDone

rsNotBufferError:
    test al,10h
    jz rsNotBabble
;
    mov ax,USB_EVENT_BABBLE
    ReportUsbPipeEvent
    jmp rsDone

rsNotBabble:
    test al,8
    jz rsNotTransErr
;
    mov ax,USB_EVENT_TRANS_ERROR
    ReportUsbPipeEvent
    jmp rsDone

rsNotTransErr:
    test al,4
    jz rsNotMicro
;
    mov ax,USB_EVENT_MISSED_MICROFRAME
    ReportUsbPipeEvent
    jmp rsDone

rsNotMicro:
    mov ax,USB_EVENT_HALTED
    ReportUsbPipeEvent

rsDone:
    pop si
    pop ax
    pop ds
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
    test es:usbd_flags,DEV_FLAG_CONTROL_ACTIVE
    jz cctDone
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
    mov bx,es:usbd_wait_dev
    SignalWaitDev

cctDone:
    pop edx
    pop ebx
    ret
CheckControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandlePacketIn
;
;       DESCRIPTION:    Handle packet IN pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePacketIn   Proc near
    push ds
    push ebx
    push edx
    push esi
    push ebp
;
    mov bp,ds
    mov ds,bx
    EnterSection ds:usbpk_section
;
    mov bx,ds:usbpk_wr_ptr
    cmp bx,ds:usbpk_tail_ptr
    je hpiLeave
;
    mov si,bx
    shl si,3
    add si,SIZE usb_packet_struc
    mov edx,ds:[si]
    mov al,fs:[edx].qtd_status
    test al,80h
    jnz hpiCheckRun

hpiLoop:
    inc bx
    cmp bx,ds:usbpk_entry_count
    jb hpiSave
;
    xor bx,bx

hpiSave:
    mov ds:usbpk_wr_ptr,bx
;
    and al,7Ch
    jnz hpiReport
;
    cmp bx,ds:usbpk_tail_ptr
    je hpiSignal
;
    mov si,bx
    shl si,3
    add si,SIZE usb_packet_struc
    mov edx,ds:[si]
    mov al,fs:[edx].qtd_status
    test al,80h
    jz hpiLoop
    jmp hpiSignal

hpiReport:
    push ds
    push edx
;
    lock or gs:usbp_flags,PIPE_FLAG_FAULT
    lock or es:usbd_flags,DEV_FLAG_FAULT
;
    push bx
    mov bx,es:usbd_thread
    Signal
    pop bx
;
    mov ds,bp
    mov dl,gs:ued_address
    call ReportStatus
;
    pop edx
    pop ds

hpiSignal:
    xor bx,bx
    xchg bx,gs:usbp_wait
    or bx,bx
    jz hpiSignalOk
;
    push es
    mov es,bx
    SignalWait
    pop es

hpiSignalOk:
    mov bx,ds:usbpk_wr_ptr
    cmp bx,ds:usbpk_tail_ptr
    je hpiLeave

hpiCheckRun:
    mov esi,gs:ep_qh
    mov al,fs:[esi].qh_status
    test al,80h
    jnz hpiLeave
;
    and al,7Ch
    jnz hpiLeave
;
    shl bx,3
    add bx,SIZE usb_packet_struc
    mov edx,ds:[bx]
    LinearToPhysicalMemBlk
    mov fs:[esi].qh_next_qtd,eax

hpiLeave:
    LeaveSection ds:usbpk_section
;
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
HandlePacketIn Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleRaw
;
;       DESCRIPTION:    Handle raw pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       BX      Raw sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRaw   Proc near
    push ds
    push edx
    push ebp
;
    mov bp,ds
    mov ds,bx
    mov bx,ds:usbr_wait_dev
;
    mov edx,ds:er_td
    mov al,fs:[edx].qtd_status
    test al,80h
    jnz hrDone
;
    and al,7Ch
    jz hrSignal
;
    push ds
    push edx
;
    lock or gs:usbp_flags,PIPE_FLAG_FAULT
    lock or es:usbd_flags,DEV_FLAG_FAULT
;
    push bx
    mov bx,es:usbd_thread
    Signal
    pop bx
;
    mov ds,bp
    mov dl,gs:ued_address
    call ReportStatus
;
    pop edx
    pop ds

hrSignal:
    SignalWaitDev

hrDone:
    pop ebp
    pop edx
    pop ds
    ret
HandleRaw  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckIn
;
;       DESCRIPTION:    Check IN pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckIn   Proc near
    push bx
;
    test gs:usbp_flags,PIPE_FLAG_ACTIVE
    jz citDone
;
    test gs:usbp_flags,PIPE_FLAG_FAULT
    jnz citDone
;
    mov bx,gs:usbp_packet_sel
    or bx,bx
    jz citNotPacket
;
    call HandlePacketIn
    jmp citDone

citNotPacket:
    mov bx,gs:usbp_raw_sel
    or bx,bx
    jz citDone
;
    call HandleRaw

citDone:
    pop bx
    ret
CheckIn   Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckOut
;
;       DESCRIPTION:    Check OUT pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckOut   Proc near
    push bx
;
    test gs:usbp_flags,PIPE_FLAG_ACTIVE
    jz cotDone
;
    test gs:usbp_flags,PIPE_FLAG_FAULT
    jnz cotDone
;
    mov bx,gs:usbp_raw_sel
    or bx,bx
    jz cotDone
;
    call HandleRaw

cotDone:
    pop bx
    ret
CheckOut   Endp

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
    mov cx,127
    mov bx,OFFSET ehc_dev_arr

efhDevLoop:
    mov ax,ds:[bx]
    or ax,ax
    jz efhDevNext
;
    mov es,ax
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
    call CheckIn

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
    call CheckOut

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
    mov bh,ds:ehc_bus
    mov bl,ds:ehc_device
    mov ch,ds:ehc_function
    xor edi,edi
    SetPciDeviceName
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
et00 DD OFFSET Block,              SEG code
et01 DD OFFSET Unblock,            SEG code
ec02 DD OFFSET PowerOffPort,       SEG code
ec03 DD OFFSET PowerOnPort,        SEG code
ec04 DD OFFSET ResetPort,          SEG code
et05 DD OFFSET DisablePort,        SEG code
ec06 DD OFFSET DisableDev,         SEG code
ec07 DD OFFSET IsPortConnected,    SEG code
ec08 DD OFFSET IsRunning,          SEG code
et09 DD OFFSET AllocateAddress,    SEG code
et0A DD OFFSET FreeAddress,        SEG code
ec0B DD OFFSET CreateDev,          SEG code
ec0C DD OFFSET Unlink,             SEG code
ec0D DD OFFSET IsDeviceConnected,  SEG code
ec0E DD OFFSET FreeDev,            SEG code
et0F DD OFFSET CreateControl,      SEG code
ec10 DD OFFSET CreateBulkPipe,     SEG code
ec11 DD OFFSET CreateIntrPipe,     SEG code
et12 DD OFFSET AddressDev,         SEG code
et13 DD OFFSET ChangeAddress,      SEG code
et14 DD OFFSET UpdateMaxLen,       SEG code
ec15 DD OFFSET ControlMsg,         SEG code
et16 DD OFFSET ConfigDev,          SEG code
ec17 DD OFFSET OpenPacket,         SEG code
ec18 DD OFFSET ClosePacket,        SEG code
ec19 DD OFFSET StartPacket,        SEG code
ec1A DD OFFSET ReqPacket,          SEG code
ec1B DD OFFSET RelPacket,          SEG code
ec1C DD OFFSET OpenRaw,            SEG code
ec1D DD OFFSET CloseRaw,           SEG code
ec1E DD OFFSET ReadRaw,            SEG code
ec1F DD OFFSET WriteRaw,           SEG code
ec20 DD OFFSET FinishRaw,          SEG code

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
    mov cx,2*21h

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
    mov cx,127
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
;           NAME:           SetupPci
;
;           DESCRIPTION:    Setup PCI
;
;           PARAMETERS:     BH          Bus
;                           BL          Device
;                           CH          Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupPci  Proc near
    push es
    push eax
    push edi
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET ehci_name
    PciPowerOn
;
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_busmstr
    WritePciWord
;
    pop edi
    pop eax
    pop es
    ret
SetupPci  Endp

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
    FindPciClassInterface
    jc init_pci_done
;
    call SetupPci
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
    FindPciClassInterface
    jc init_pci_done
;       
    call SetupPci
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
