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
INCLUDE ..\os\proc.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE usb.inc
INCLUDE usbdev.inc
INCLUDE hub.inc

MAX_USB_DEVICES = 16

; ehc_flags

EHC_PORT_IND    = 1
EHC_COMPANION       = 2
EHC_PORT_POWER      = 4


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

usb_dev_base        usb_dev_struc <>

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

ehc_pipe_list       DW ?
ehc_async_head_va   DD ?

ehc_pipe_section    section_typ <>
ehc_enum_section    section_typ <>
ehc_hub_section     section_typ <>

ehc_hub_port_arr    DD 256 DUP(?)

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

ehci_func_sel    ENDS

ESP_FLAG_TRANSFER_PENDING   = 1
ESP_FLAG_TRANSFER_OK        = 2
ESP_FLAG_SINGLE             = 4

ehci_pipe   STRUC

esp_pipe_base   usb_pipe_struc <>
esp_qh          DD ?
esp_prev        DW ?
esp_next        DW ?
esp_table       DW ?
esp_entry       DW ?
esp_table_size  DW ?

esp_pending     DD ?
esp_first       DD ?
esp_current     DD ?
esp_size        DW ?
esp_flags       DB ?
esp_done        DB ?

ehci_pipe   ENDS

; this structure should be kept less than 128 bytes long!

qtd_struc       STRUC

; HC part

qtd_next        DD ?
qtd_alt         DD ?
qtd_status      DB ?
qtd_flags       DB ?
qtd_size        DW ?
qtdl_page0      DD ?
qtdl_page1      DD ?
qtdl_page2      DD ?
qtdl_page3      DD ?
qtdl_page4      DD ?

qtdu_page0      DD ?
qtdu_page1      DD ?
qtdu_page2      DD ?
qtdu_page3      DD ?
qtdu_page4      DD ?

; driver part

qtd_my_phys     DD ?
qtd_my_va       DD ?
qtd_next_va     DD ?
qtd_alt_va      DD ?
qtd_buffer_va   DD ?
qtd_buffer_size DW ?

qtd_struc       ENDS

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

EhciList128     DD ?
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
    test al,6
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
    test al,6
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
;       NAME:           AllocateBlock128
;
;       DESCRIPTION:    Allocate 128-byte block with page-alignment
;
;       PARAMETERS:     ES      Flat sel
;
;       RETURNS:        EDX         Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlock128 PROC near
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:EhciSection
    mov edx,ds:EhciList128
    or edx,edx
    jnz allocate_block128_done
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
    mov ds:EhciList128,edx
    
allocate_block128_loop:
    mov eax,edx
    add eax,ecx
    mov es:[edx],eax
    mov edx,eax
    test dx,0FFFh
    jnz allocate_block128_loop
;
    sub edx,ecx
    mov dword ptr es:[edx],0
    mov edx,ds:EhciList128
    pop ecx

allocate_block128_done:
    mov eax,es:[edx]
    mov ds:EhciList128,eax
    LeaveSection ds:EhciSection
;
    pop eax
    pop ds
    ret
AllocateBlock128 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeBlock128
;
;       DESCRIPTION:    Free 128-byte block
;
;       PARAMETERS:     ES      Flat sel
;
;       PARAMETERS:         EDX         Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBlock128     PROC near
    push ds
    push eax
;
    mov ax,SEG data
    mov ds,ax
;    
    EnterSection ds:EhciSection
    mov eax,ds:EhciList128
    mov es:[edx],eax
    mov ds:EhciList128,edx
    LeaveSection ds:EhciSection
;       
    pop eax
    pop ds
    ret
FreeBlock128     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InsertPipe
;
;       DESCRIPTION:    Insert pipe into function pipe-list
;
;       PARAMETERS:     DS      Function
;                       FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertPipe  Proc near
    push di
    EnterSection ds:ehc_pipe_section
    mov di,ds:ehc_pipe_list
    or di,di
    je ipEmpty
;       
    push ds
    push si
    mov ds,di
    mov si,ds:esp_prev
    mov ds:esp_prev,fs
    mov ds,si
    mov ds:esp_next,fs
    mov fs:esp_next,di
    mov fs:esp_prev,si
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
    LeaveSection ds:ehc_pipe_section
    ret
InsertPipe  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RemovePipe
;
;       DESCRIPTION:    Remove pipe from function pipe-list
;
;       PARAMETERS:     DS      Function
;                       FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemovePipe  Proc near
    push si
    push di
;       
    EnterSection ds:ehc_pipe_section
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
    LeaveSection ds:ehc_pipe_section
    pop di
    pop si
    ret
RemovePipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupHub
;
;       DESCRIPTION:    Setup hub in pipe
;
;       PARAMETERS:     DS      Device
;                       ES      Function
;                       FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupHub  Proc near
    push ax
    push si
;    
    mov fs:usbp_hub_sel,0
    mov al,es:usbf_port
    cmp al,ds:ehc_ports
    jb shDone

shHub:
    movzx si,al
    shl si,2
    mov ax,word ptr ds:[si].ehc_hub_port_arr
    mov fs:usbp_hub_sel,ax
;    
    mov ax,word ptr ds:[si+2].ehc_hub_port_arr
    mov fs:usbp_hub_port,ax

shDone:    
    pop si
    pop ax
    ret
SetupHub    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitQh
;
;       DESCRIPTION:    Initialize an already allocated qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       EDX     QH
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitQh  PROC near
    mov es:[edx].qh_link,1
    mov es:[edx].qh_adress,0
    mov es:[edx].qh_endpoint,0
    mov es:[edx].qh_max_packet,3000h
    mov es:[edx].qh_s_mask,0
    mov es:[edx].qh_c_mask,0
    mov es:[edx].qh_hub_port,4000h
    mov es:[edx].qh_current_qtd,0
    mov es:[edx].qh_next_qtd,1
    mov es:[edx].qh_alt_qtd,1
    mov es:[edx].qh_status,0
    mov es:[edx].qh_flags,0
    mov es:[edx].qh_size,0
    mov es:[edx].qhl_page0,0    
    mov es:[edx].qhl_page1,0    
    mov es:[edx].qhl_page2,0    
    mov es:[edx].qhl_page3,0    
    mov es:[edx].qhl_page4,0
    mov es:[edx].qhu_page0,0    
    mov es:[edx].qhu_page1,0    
    mov es:[edx].qhu_page2,0    
    mov es:[edx].qhu_page3,0    
    mov es:[edx].qhu_page4,0
    mov es:[edx].qh_my_va,edx
    mov es:[edx].qh_link_va,0
    mov es:[edx].qh_next_va,0
    mov es:[edx].qh_alt_va,0    
    ret
InitQh  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitQtd
;
;       DESCRIPTION:    Initialize an already allocated qTD
;
;       PARAMETERS:     ES      Flat sel
;                       FS      Pipe sel
;                       EAX     qTD physical
;                       EDX     qTD linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitQtd PROC near
    mov es:[edx].qtd_next,1
    mov es:[edx].qtd_alt,1
    mov es:[edx].qtd_status,80h
    mov es:[edx].qtd_flags,8Fh
    mov es:[edx].qtd_size,0
    mov es:[edx].qtdl_page0,0
    mov es:[edx].qtdl_page1,0
    mov es:[edx].qtdl_page2,0
    mov es:[edx].qtdl_page3,0
    mov es:[edx].qtdl_page4,0
    mov es:[edx].qtdu_page0,0
    mov es:[edx].qtdu_page1,0
    mov es:[edx].qtdu_page2,0
    mov es:[edx].qtdu_page3,0
    mov es:[edx].qtdu_page4,0
    mov es:[edx].qtd_my_va,edx
    mov es:[edx].qtd_my_phys,eax
    mov es:[edx].qtd_next_va,0
    mov es:[edx].qtd_alt_va,0
    mov es:[edx].qtd_buffer_va,0
    mov es:[edx].qtd_buffer_size,0
    ret
InitQtd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateQh
;
;       DESCRIPTION:    Allocate & initialize an qh descriptor
;
;       PARAMETERS:     DS      Function selector
;                       ES      Flat sel
;
;       RETURNS:        EDX     Linear address of qh
;                       EAX     Physical address of qh
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQh      PROC near
    push cx
    call AllocateBlock128
    call InitQh
;
    push ebx
    GetPageEntry
    pop ebx
;    
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
    mov es:[edx].qh_my_phys,eax
    ret
AllocateQh  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateQtd
;
;       DESCRIPTION:    Allocate & initialize qTD
;
;       PARAMETERS:     ES      Flat sel
;                       FS      Pipe sel
;
;       RETURNS:        EDX         Linear address of qTD
;                       EAX     Physical address of qTD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateQtd     PROC near
    push cx
    call AllocateBlock128
;
    push ebx
    GetPageEntry
    pop ebx
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
;    
    call InitQtd
    ret
AllocateQtd  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateInactiveQh
;
;       DESCRIPTION:    Allocate & initialize an inactive qh descriptor
;
;       PARAMETERS:     DS      Function selector
;                       ES      Flat sel
;
;       RETURNS:        EDX     Linear address of qh
;                       EAX     Physical address of qh
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateInactiveQh      PROC near
    call AllocateQh
    mov es:[edx].qh_adress,80h
    ret
AllocateInactiveQh  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddControlQh
;
;       DESCRIPTION:    Add control qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;
;       RETURNS:        EDX     Linear address of qh added
;                       EAX     Physical address of qh added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddControlQh    PROC near
    push gs
    push ebx
;
    EnterSection ds:ehc_section
    call AllocateQh
    mov ebx,eax
;
    mov es:[edx].qh_endpoint,60h
;    
    mov ax,3008h
    mov es:[edx].qh_max_packet,ax
;
    mov al,fs:usbp_speed
    cmp al,2
    je acqSpeedOk
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
    mov es:[edx].qh_endpoint,al
;
    mov ax,fs:usbp_hub_sel
    or ax,ax
    jz acqDone
;    
    push gs
    mov gs,ax
    mov ax,fs:usbp_hub_port
    shl ax,7
    or ax,4000h    
    or al,gs:hub_device
    pop gs        
    mov es:[edx].qh_hub_port,ax
;
    mov es:[edx].qh_c_mask,2
;    
    mov ax,3808h
    mov es:[edx].qh_max_packet,ax
    
acqSpeedOk:
    mov eax,ds:ehc_async_head_va
    or eax,eax
    jnz acqInsert
;
    or es:[edx].qh_endpoint,80h
    mov ds:ehc_async_head_va,edx
    mov eax,ebx
    or al,2
    mov es:[edx].qh_link,eax
    mov es:[edx].qh_link_va,0
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
    jmp acqDone

acqInsert:
    push esi
    push edi
;
    mov esi,eax
    mov edi,es:[esi].qh_my_phys    

acqInsLoop:
    mov esi,eax    
    mov eax,es:[esi].qh_link_va
    or eax,eax
    jnz acqInsLoop
;
    mov es:[edx].qh_link_va,0    
    mov eax,edi
    or al,2
    mov es:[edx].qh_link,eax
;
    mov es:[esi].qh_link_va,edx
    mov eax,ebx
    or al,2
    mov es:[esi].qh_link,eax
;
    pop edi
    pop esi

acqDone:
    mov eax,ebx
    LeaveSection ds:ehc_section
;    
    pop ebx
    pop gs
    ret
AddControlQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RemoveAsyncQh
;
;       DESCRIPTION:    Remove async qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;                       EDX     Linear address of qh added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveAsyncQh    PROC near
    push eax
    push edi
;
    test es:[edx].qh_endpoint,80h
    jz raqList

raqHead:
    mov edi,es:[edx].qh_link_va
    mov ds:ehc_async_head_va,edi
    or edi,edi
    jz raqHeadEmpty
;    
    mov eax,es:[edi].qh_my_phys
;
    push es
    mov es,ds:ehc_reg_sel
    mov es:HcAsyncList,eax
    pop es
    jmp raqFree

raqHeadEmpty:
    push es
    mov es,ds:ehc_reg_sel
    mov es:HcAsyncList,0
    pop es
    jmp raqFree
    
raqList:
    mov edi,ds:ehc_async_head_va

raqSearch:    
    or edi,edi
    jz raqFree
;    
    cmp edx,es:[edi].qh_link_va
    je raqFound
;
    mov edi,es:[edi].qh_link_va
    jmp raqSearch

raqFound:        
    mov eax,es:[edx].qh_link_va
    mov es:[edi].qh_link_va,eax
;
    mov eax,es:[edx].qh_link
    mov es:[edi].qh_link,eax   

raqFree:
    mov ax,10
    WaitMilliSec
    call FreeBlock128
;
    pop edi
    pop eax
    ret    
RemoveAsyncQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddBulkQh
;
;       DESCRIPTION:    Add bulk qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;
;       RETURNS:        EDX     Linear address of qh added
;                       EAX     Physical address of qh added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBulkQh    PROC near
    push gs
    push ebx
;
    EnterSection ds:ehc_section
    call AllocateQh
    mov ebx,eax
;
    mov es:[edx].qh_endpoint,20h
;    
    mov ax,3008h
    mov es:[edx].qh_max_packet,ax
;
    mov al,fs:usbp_speed
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
    mov es:[edx].qh_endpoint,al
;
    push gs
    mov ax,fs:usbp_hub_port
    shl ax,7
    or ax,4000h    
    mov gs,fs:usbp_hub_sel
    or al,gs:hub_device
    pop gs        
    mov es:[edx].qh_hub_port,ax
;
    mov es:[edx].qh_c_mask,2
;    
    mov ax,3008h
    mov es:[edx].qh_max_packet,ax
    
abqSpeedOk:
    mov eax,ds:ehc_async_head_va
    or eax,eax
    jnz abqInsert
;
    or es:[edx].qh_endpoint,80h
    mov ds:ehc_async_head_va,edx
    mov eax,ebx
    or al,2
    mov es:[edx].qh_link,eax
    mov es:[edx].qh_link_va,0
;
    mov gs,ds:ehc_reg_sel
    mov gs:HcAsyncList,ebx
;
    mov eax,gs:HcCommand
    or al,20h
    mov gs:HcCommand,eax
    jmp abqDone

abqInsert:
    push esi
    push edi
;
    mov esi,eax
    mov edi,es:[esi].qh_my_phys    

abqInsLoop:
    mov esi,eax    
    mov eax,es:[esi].qh_link_va
    or eax,eax
    jnz abqInsLoop
;
    mov es:[edx].qh_link_va,0    
    mov eax,edi
    or al,2
    mov es:[edx].qh_link,eax
;
    mov es:[esi].qh_link_va,edx
    mov eax,ebx
    or al,2
    mov es:[esi].qh_link,eax
;
    pop edi
    pop esi

abqDone:
    mov eax,ebx
    LeaveSection ds:ehc_section
;    
    pop ebx
    pop gs
    ret
AddBulkQh  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetIntrEntry
;
;       DESCRIPTION:    Get intr entry
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
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
;                       ES      Flat sel
;                       BX      Table offset
;                       AX      Entry
;                       BP      Table size
;
;       RETURNS:        EDX     QH linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntrEntry    PROC near
    push eax
    push esi
    push edi
;    
    mov si,ax
    shl si,3
    mov edx,ds:[bx+si].ehc_qh
    mov al,es:[edx].qh_adress
    test al,80h
    jnz aieQhOk
;
    call AllocateQh 

aieQhOk:
    mov fs:esp_table,bx
    mov fs:esp_entry,si
    mov fs:esp_table_size,bp
;    
    mov es:[edx].qh_s_mask,1    
    mov es:[edx].qh_c_mask,2
;
    mov es:[edx].qh_endpoint,20h
;    
    mov ax,3008h
    mov es:[edx].qh_max_packet,ax
;
    mov al,fs:usbp_speed
    cmp al,2
    je aieSpeedOk
;
    mov es:[edx].qh_c_mask,1Ch
    cmp al,0
    je aieLowSpeed

aieFullSpeed:
    mov ah,0
    jmp aieSetSpeed

aieLowSpeed:
    mov ah,10h

aieSetSpeed:    
    mov es:[edx].qh_endpoint,ah
;
    push gs
    mov ax,fs:usbp_hub_port
    shl ax,7
    or ax,4000h    
    mov gs,fs:usbp_hub_sel
    or al,gs:hub_device
    pop gs        
    mov es:[edx].qh_hub_port,ax
    
aieSpeedOk:
    inc ds:[bx+si].ehc_cnt
;
    cmp edx,ds:[bx+si].ehc_qh
    je aieDone
;
    mov edi,ds:[bx+si].ehc_qh
    mov eax,es:[edi].qh_link_va
    mov es:[edx].qh_link_va,eax
    mov eax,es:[ecx].qh_link
    mov es:[edx].qh_link,eax    
;    
    mov es:[edi].qh_link_va,edx
    mov eax,es:[edx].qh_my_phys
    or al,2
    mov es:[edi].qh_link,eax    
    
aieDone:
    pop edi
    pop esi        
    pop eax
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
;                       ES      Flat sel
;                       BX      Table offset
;                       CX      Table size / 2
;                       AX      Entry
;                       EDX     QH linear
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
;                       ES      Flat sel
;                       FS      Pipe sel
;                       AL      Interval
;
;       RETURNS:        EDX     Linear address of qh added
;                       EAX     Physical address of qh added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntrQh   PROC near
    push fs
    push bx
    push cx
    push bp
;    
    mov cx,1024
    movzx ax,al
    mov bx,OFFSET ehc_1024
    mov bp,8 * 1024

aiqLoop:    
    cmp ax,cx
    jae aiqFound
;
    add bx,bp
    shr bp,1
    shr cx,1
    jnz aiqLoop    

aiqFound:
    call GetIntrEntry
    call AddIntrEntry
;    
    cmp bx,OFFSET ehc_1024
    je aiqDone
;
    shl bp,1
    sub bx,bp
    call AddIntrProp    
;
    add ax,cx
    call AddIntrProp

aiqDone:
    pop bp
    pop cx
    pop bx
    pop fs    
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
;                       ES      Flat sel
;                       BX      Table offset
;                       CX      Table size / 2
;                       AX      Entry
;                       EDX     QH linear
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
;       NAME:           RemoveIntrQh
;
;       DESCRIPTION:    Remove intr qh
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;                       EDX     Linear address of qh added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveIntrQh    PROC near
    pushad
;
    mov bx,fs:esp_table
    mov si,fs:esp_entry
    mov bp,fs:esp_table_size
    mov cx,bp
    shr cx,4
;    
    mov edi,ds:[bx+si].ehc_qh
    cmp edx,edi
    jne riqSearch
;
    mov eax,es:[edx].qh_link_va
    or eax,eax
    jnz riqFirst
;
    mov es:[edx].qh_current_qtd,0
    mov es:[edx].qh_next_qtd,1
    mov es:[edx].qh_alt_qtd,1
    mov es:[edx].qh_status,0
    mov es:[edx].qh_adress,80h
    jmp riqUpdate

riqFirst:
    int 3
        
riqSearch:    
    or edi,edi
    jz riqFree
;    
    cmp edx,es:[edi].qh_link_va
    je riqFound
;
    mov edi,es:[edi].qh_link_va
    jmp riqSearch

riqFound:        
    mov eax,es:[edx].qh_link_va
    mov es:[edi].qh_link_va,eax
;
    mov eax,es:[edx].qh_link
    mov es:[edi].qh_link,eax   

riqFree:
    call FreeBlock128

riqUpdate:
    mov ax,si
    shr ax,3
;    
    cmp bx,OFFSET ehc_1024
    je riqDone
;
    shl bp,1
    sub bx,bp
    call RemoveIntrProp    
;
    add ax,cx
    call RemoveIntrProp

riqDone:    
    popad
    ret
RemoveIntrQh    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateFillQtd
;
;       DESCRIPTION:    Allocate and fill qtd buffer pointers from buffer
;
;       PARAMETERS:     DS      Function selector
;                       ES:EDI  Data buffer
;                       CX      Size of data
;
;       RETURNS:        EDX     Allocated & filled qTD 
;                       EAX     qTD physical
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateFillQtd PROC near
    push es
    push ebx
    push ecx
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
    mov es:[esi].qtd_buffer_size,cx
    or cx,cx
    jz afqDone
;
    mov al,es:[edx]
    push ebx
    GetPageEntry
    mov es:[esi].qtdu_page0,ebx
    pop ebx
    and ax,0F000h
    mov bx,dx
    and bx,0FFFh
    or ax,bx
    mov es:[esi].qtdl_page0,eax
;
    mov ax,1000h
    sub ax,bx
    sub cx,ax
    jc afqDone
;
    movzx ebx,ax
    add edx,ebx
    mov edi,OFFSET qtdl_page1

afqLoop:    
    mov al,es:[edx]
    GetPageEntry
;    
    and ax,0F000h
    mov es:[esi+edi],eax
    mov es:[esi+edi+20],ebx
    sub cx,1000h
    jc afqDone
;
    add edx,1000h
    add edi,4
    jmp afqLoop    

afqDone:    
    mov edx,esi
    mov eax,es:[edx].qtd_my_phys
;    
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    ret
AllocateFillQtd   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InsertQtd
;
;       DESCRIPTION:    Insert qTD into pipe schedule
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       AL      PID code
;                       EDX     qTD linear 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertQtd       PROC near
    push es
    push eax
    push ebx
;
    mov bx,flat_sel
    mov es,bx
;    
    and al,3
    or al,8Ch
    mov es:[edx].qtd_flags,al
;
    mov ebx,fs:esp_pending
    or ebx,ebx
    jz iqEmpty

ipLoop:    
    mov eax,es:[ebx].qtd_next_va
    or eax,eax
    jz ipAdd
;
    mov ebx,eax
    jmp ipLoop

ipAdd:
    mov es:[edx].qtd_next_va,0
    mov es:[edx].qtd_next,1
;    
    mov es:[ebx].qtd_next_va,edx
    mov edx,es:[edx].qtd_my_phys
    mov es:[ebx].qtd_next,edx
    jmp iqLinked

iqEmpty:
    mov ebx,es:[edx].qtd_my_phys
    mov fs:esp_first,ebx
    mov es:[edx].qtd_next_va,0
    mov es:[edx].qtd_next,1
    mov fs:esp_pending,edx

iqLinked:
    pop ebx
    pop eax
    pop es
    ret
InsertQtd   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateControl
;
;           DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Device selector
;                       ES      Function selector
;                       AH      Speed
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    push es
    pushad
;    
    push es
    push ax
    mov eax,SIZE ehci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    mov ax,es
    mov fs,ax
    pop ax
    pop es    
    mov fs:usbp_speed,ah
;    
    call SetupHub
;    
    mov dx,flat_sel
    mov es,dx
    call AddControlQh
    mov fs:esp_qh,edx
    call InsertPipe
;
    popad
    pop es
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
;                       AH      Speed
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    push es
    pushad
;    
    push es
    push ax
    mov eax,SIZE ehci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    mov ax,es
    mov fs,ax
    pop ax
    pop es    
    mov fs:usbp_speed,ah
;    
    call SetupHub
;    
    mov dx,flat_sel
    mov es,dx
    call AddBulkQh
    mov fs:esp_qh,edx
    call InsertPipe
;
    popad
    pop es
    retf32
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateIntr
;
;   DESCRIPTION:    Create interrupt pipe
;
;   PARAMETERS:     DS      Function selector
;                   AL      Interval
;                   AH      Speed
;
;   RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    push es
    pushad
;    
    push es
    push ax
    mov eax,SIZE ehci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    mov ax,es
    mov fs,ax
    pop ax
    pop es
    mov fs:usbp_speed,ah
;    
    call SetupHub
;    
    mov dx,flat_sel
    mov es,dx
    call AddIntrQh
    mov fs:esp_qh,edx
    call InsertPipe
;
    popad
    pop es
    retf32
CreateIntr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddSetup
;
;           DESCRIPTION:    Add setup transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               CX      Buffer size
;               ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddSetup    Proc far
    push es
    push eax
    push edx
;    
    call AllocateFillQtd
;
    mov al,2    
    call InsertQtd
;
    mov ax,flat_sel
    mov es,ax
    mov edx,fs:esp_qh
    mov es:[edx].qh_size,0
;
    mov ax,es:[edx].qh_max_packet
    and ax,0F800h
    or ax,fs:usbp_maxlen
    mov es:[edx].qh_max_packet,ax
;
    pop edx
    pop eax
    pop es
    retf32
AddSetup    Endp

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
    push es
    push eax
    push edx
;    
    call AllocateFillQtd
;
    mov al,0
    call InsertQtd
;
    mov ax,flat_sel
    mov es,ax
    mov edx,fs:esp_qh
;    
    mov ax,es:[edx].qh_size
    and ax,8000h
    mov es:[edx].qh_size,ax
;
    mov al,fs:usbp_endpoint
    or al,al
    jz aoControl

aoData:    
    mov ax,es:[edx].qh_max_packet
    and ax,0F000h
    or ax,fs:usbp_maxlen
    mov es:[edx].qh_max_packet,ax
    jmp aoDone

aoControl:    
    mov ax,es:[edx].qh_max_packet
    and ax,0F800h
    or ax,fs:usbp_maxlen
    mov es:[edx].qh_max_packet,ax

aoDone:
    pop edx
    pop eax
    pop es
    retf32
AddOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddIn
;
;   DESCRIPTION:    Add in transaction to queue
;
;   PARAMETERS:     DS      Function selector
;                   FS      Pipe selector
;                   CX      Buffer size
;                   ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIn    Proc far
    push es
    push eax
    push edx
;    
    call AllocateFillQtd
;
    mov al,1
    call InsertQtd
;
    mov ax,flat_sel
    mov es,ax
    mov edx,fs:esp_qh
;    
    mov al,fs:usbp_endpoint
    or al,al
    jz aiControl

aiData:    
    mov ax,es:[edx].qh_max_packet
    and ax,0F000h
    or ax,fs:usbp_maxlen
    mov es:[edx].qh_max_packet,ax
    jmp aiDone

aiControl:    
    mov ax,es:[edx].qh_size
    and ax,8000h
    mov es:[edx].qh_size,ax
;
    mov ax,es:[edx].qh_max_packet
    and ax,0F800h
    or ax,fs:usbp_maxlen
    mov es:[edx].qh_max_packet,ax

aiDone:
    pop edx
    pop eax
    pop es
    retf32
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddStatusOut
;
;           DESCRIPTION:    Add status OUT transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusOut    Proc far
    push es
    push eax
    push cx
    push edx
;    
    xor cx,cx
    call AllocateFillQtd
;
    mov al,0
    call InsertQtd
;
    pop edx
    pop cx
    pop eax
    pop es
    retf32
AddStatusOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddStatusIn
;
;           DESCRIPTION:    Add status IN transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusIn    Proc far
    push eax
    push cx
    push edx
;    
    xor cx,cx
    call AllocateFillQtd
;
    mov al,1   
    call InsertQtd
;
    pop edx
    pop cx
    pop eax
    retf32
AddStatusIn    Endp

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
    push ebx
    push edx
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov fs:esp_done,0
    and fs:esp_flags, NOT ESP_FLAG_TRANSFER_OK
    or fs:esp_flags, ESP_FLAG_TRANSFER_PENDING
;    
    cmp fs:usbp_mode,MODE_CONTROL
    jne itDo
;
    mov dx,0
    mov ebx,fs:esp_pending
    or ebx,ebx
    jz itDo

itLoop:    
    mov al,es:[ebx].qtd_flags
    and al,7Fh
    mov es:[ebx].qtd_flags,al
;
    mov ax,es:[ebx].qtd_size
    and ax,7FFFh
    or ax,dx
    mov es:[ebx].qtd_size,ax
;
    mov eax,es:[ebx].qtd_next_va
    or eax,eax
    jz itLast
;
    xor dx,8000h
    mov ebx,eax
    jmp itLoop

itLast:
    or es:[ebx].qtd_size,8000h
    mov al,es:[ebx].qtd_flags
    or al,80h
    mov es:[ebx].qtd_flags,al

itDo:
    mov edx,fs:esp_qh
    mov al,fs:usbp_address
    mov es:[edx].qh_adress,al
;    
    mov al,fs:usbp_endpoint
    and al,0Fh
    mov ah,es:[edx].qh_endpoint
    and ah,0F0h
    or al,ah
    mov es:[edx].qh_endpoint,al    
;
    mov eax,fs:esp_first
    mov es:[edx].qh_next_qtd,eax
;
    pop edx
    pop ebx
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
;       RETURNS:    NC      Transfer is done
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalIsTransferDone   Proc near
    push es
    push eax
    push edx
;
    test fs:esp_flags, ESP_FLAG_TRANSFER_PENDING
    jz itdOk
;    
    call LocalIsConnected
    jc itdOk
;    
    mov ax,flat_sel
    mov es,ax
;
    mov edx,fs:esp_qh
    mov eax,es:[edx].qh_current_qtd
    or eax,eax
    jz itdFail
;
    test fs:esp_flags, ESP_FLAG_SINGLE
    jz itdMulti
;
    cmp eax,fs:esp_current
    je itdFail
;
    jmp itdOk

itdMulti:
    mov al,es:[edx].qh_status
    test al,80h
    jnz itdFail
;    
    mov eax,es:[edx].qh_next_qtd
    test al,1
    jnz itdOk
;
    mov al,es:[edx].qh_status
    test al,40h
    jz itdFail
;
;    int 3
    jmp itdOk

itdFail:
    stc
    jmp itdEnd   

itdOk:
    clc

itdEnd:    
    pop edx
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
;       RETURNS:    NC      Transfer is done
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
    test fs:esp_flags, ESP_FLAG_TRANSFER_PENDING
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
;           NAME:           LocalEndTransfer
;
;           DESCRIPTION:    End transfer
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalEndTransfer   Proc near
    push es
    push eax
    push cx
    push edx
    push esi
    push edi
    push bp
;    
    test fs:esp_flags, ESP_FLAG_TRANSFER_PENDING
    jz etrDone
;
    and fs:esp_flags, NOT ESP_FLAG_TRANSFER_PENDING
;    
    mov ax,flat_sel
    mov es,ax
;
    mov edx,fs:esp_qh
    mov al,es:[edx].qh_status
    test al,40h
    jnz etrFail
;
    or fs:esp_flags, ESP_FLAG_TRANSFER_OK
    jmp etrDecode

etrFail:    
;    int 3    

etrDecode:    
    xor edx,edx
    xchg edx,fs:esp_pending
;
    xor bp,bp
    or edx,edx
    jz etrSaveOk

etrLoop:
    mov al,es:[edx].qtd_flags
    and al,3
    cmp al,1
    jne etrNext
;
    mov cx,es:[edx].qtd_buffer_size
    sub cx,es:[edx].qtd_size
    and cx,7FFFh
    add bp,cx

etrNext:
    mov edi,es:[edx].qtd_next_va
    call FreeBlock128
    mov edx,edi
    or edx,edx
    jnz etrLoop
        
etrSaveOk:
    mov fs:esp_size,bp    

etrClear:
    mov edx,fs:esp_qh
    mov es:[edx].qh_next_qtd,1
    mov es:[edx].qh_current_qtd,0
    mov es:[edx].qh_status,0    

etrDone:
    pop bp
    pop edi
    pop esi
    pop edx
    pop cx
    pop eax
    pop es
    ret
LocalEndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EndTransfer
;
;           DESCRIPTION:    End transfer
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
;           NAME:           WasTransferOk
;
;           DESCRIPTION:    Was transfer ok
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;       RETURNS:    NC      Transfer ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WasTransferOk   Proc far
    test fs:esp_flags, ESP_FLAG_TRANSFER_PENDING
    jz wtoNotPending
;    
    call LocalEndTransfer

wtoNotPending:
    test fs:esp_flags, ESP_FLAG_TRANSFER_OK
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
;           NAME:           GetDataSize
;
;           DESCRIPTION:    Get data size
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;       RETURNS:    CX      Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDataSize   Proc far
    xor cx,cx
    test fs:esp_flags, ESP_FLAG_TRANSFER_OK
    jz gdsDone
;    
    mov cx,fs:esp_size

gdsDone:
    retf32
GetDataSize   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               IssueOne
;
;       DESCRIPTION:        Issue one transfer
;
;       PARAMETERS:         FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueOne   Proc far
    push es
    push eax
    push ebx
    push edx
;    
    mov ax,flat_sel
    mov es,ax
;
    mov fs:esp_done,0
    test fs:esp_flags, ESP_FLAG_SINGLE
    jnz iotNew
;
    and fs:esp_flags, NOT ESP_FLAG_TRANSFER_OK
    or fs:esp_flags, ESP_FLAG_TRANSFER_PENDING OR ESP_FLAG_SINGLE
    mov edx,fs:esp_qh
    mov al,fs:usbp_address
    mov es:[edx].qh_adress,al
;    
    mov al,fs:usbp_endpoint
    and al,0Fh
    mov ah,es:[edx].qh_endpoint
    and ah,0F0h
    or al,ah
    mov es:[edx].qh_endpoint,al    
;
    mov eax,fs:esp_pending
    mov eax,es:[eax].qtd_my_phys
    mov es:[edx].qh_next_qtd,eax
    mov fs:esp_current,eax
    jmp iotDone

iotNew:
    mov edx,fs:esp_pending
    mov eax,es:[edx].qtd_next_va
    mov fs:esp_pending,eax
;
    mov eax,es:[eax].qtd_my_phys
    mov fs:esp_current,eax
    call FreeBlock128

iotDone:
    pop edx
    pop ebx
    pop eax
    pop es    
    retf32
IssueOne   Endp

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
    pushad
;    
    call RemovePipe
;    
    mov ax,flat_sel
    mov es,ax
;
    EnterSection ds:ehc_section
    xor edx,edx
    xchg edx,fs:esp_pending
    or edx,edx
    jz cpReqFree

cpReqLoop:
    mov edi,es:[edx].qtd_next_va
    call FreeBlock128
    mov edx,edi
    or edx,edx
    jnz cpReqLoop

cpReqFree:
    mov edx,fs:esp_qh
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je cpControl
;
    cmp al,MODE_BULK
    je cpBulk
;    
    cmp al,MODE_INTR
    je cpIntr
;    
    int 3
    jmp cpDelPipe

cpControl:
    call RemoveAsyncQh
    jmp cpDelPipe

cpBulk:
    call RemoveAsyncQh
    jmp cpDelPipe

cpIntr:
    call RemoveIntrQh
    jmp cpDelPipe

cpDelPipe:
    LeaveSection ds:ehc_section
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
;
    popad
    pop es
    retf32
ClosePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ChangeAddress
;
;   DESCRIPTION:    Change address for pipe
;
;   PARAMETERS:     DS      Function selector
;                   FS      Pipe selector
;                   AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    push es
    push ax
    push edx
;
    mov ax,flat_sel
    mov es,ax
;    
    mov edx,fs:esp_qh
    mov al,fs:usbp_address
    mov es:[edx].qh_adress,al
;
    pop edx
    pop ax
    pop es
    retf32
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalIsConnected
;
;           DESCRIPTION:    Check if pipe is connected
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalIsConnected   Proc near
    push eax
    push si
;    
    mov ax,fs:usbp_hub_sel
    or ax,ax
    jz icLocal    

icHub:
    push gs
    mov gs,ax
    mov dx,fs:usbp_hub_port
    IsUsbHubPortConnected
    pop gs
    jmp icDone

icLocal:    
    push es
    mov es,fs:usbp_function_sel
    movzx si,es:usbf_port
    shl si,2
    mov es,ds:ehc_reg_sel
    mov eax,es:[si].HcPortSc
    pop es
    test al,4
    jz icFail
;
    test al,1
    clc
    jnz icDone

icFail:   
    stc

icDone:
    pop si
    pop eax
    ret
LocalIsConnected Endp

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
    call LocalIsConnected
    retf32
IsConnected Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetPipe
;
;           DESCRIPTION:    Reset port for pipe
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetPipe   Proc far
    push es
    push ax
    push cx
;    
    mov ax,fs:usbp_hub_sel
    or ax,ax
    jz repNoHub
;
    push gs
    mov gs,ax
    mov dx,fs:usbp_hub_port
    ResetUsbHubPort
    pop gs
    jmp repDone
       
repNoHub:
    int 3
    mov es,fs:usbp_function_sel
    mov cl,es:usbf_port
    mov ax,1
    shl ax,cl
    or ds:ehc_reset,ax

repDone:
    pop cx
    pop ax
    pop es
    retf32
ResetPipe Endp

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
    EnterSection ds:ehc_enum_section
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
    LeaveSection ds:ehc_enum_section
    retf32
UnlockEnum   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateHubPort
;
;           DESCRIPTION:    Allocate Hub port
;
;       PARAMETERS:         DS      Function selector
;                           GS      Hub Selector
;                           DX      Hub port
;
;       RETURNS:            AL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateHubPort   Proc far
    push bx
    push si
;    
    xor al,al
    mov bx,OFFSET ehc_hub_port_arr
    EnterSection ds:ehc_hub_section

ahpLoop:
    mov si,[bx]
    or si,si
    jz ahpOk
;
    add bx,4
    inc al
    jmp ahpLoop      

ahpOk:
    mov [bx],gs
    mov [bx+2],dx
    LeaveSection ds:ehc_hub_section
    clc
;
    pop si
    pop bx
    retf32
AllocateHubPort     Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeHubPort
;
;           DESCRIPTION:    Free Hub port
;
;       PARAMETERS:         DS      Function selector
;                           AL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeHubPort   Proc far
    push bx
;    
    movzx bx,al
    shl bx,2
    add bx,OFFSET ehc_hub_port_arr
    EnterSection ds:ehc_hub_section
    mov dword ptr [bx],0
    LeaveSection ds:ehc_hub_section
    clc
;
    pop bx
    retf32
FreeHubPort     Endp

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
    test ds:ehc_hcc_flags,1
    jz hb64Fail
;
    clc
    jmp hb64Done    

hb64Fail:    
    stc

hb64Done:    
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
;       RETURNS:            CY      Stalled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsStalled   Proc far
    push es
    push eax
    push edx
;    
    mov ax,flat_sel
    mov es,ax
;
    mov edx,fs:esp_qh
    mov al,es:[edx].qh_status
    test al,40h
    stc
    jnz issDone
;
    clc

issDone:
    pop edx
    pop eax
    pop es        
    retf32
IsStalled Endp

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
;       RETURNS:            CY      Stalled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearStalled   Proc far
    push es
    push eax
    push edx
;    
    mov ax,flat_sel
    mov es,ax
;
    mov edx,fs:esp_qh
    mov es:[edx].qh_size,0
    mov es:[edx].qh_status,80h
;
    pop edx
    pop eax
    pop es        
    retf32
ClearStalled Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetMaxLen
;
;           DESCRIPTION:    Get max len
;
;           RETURNS:        AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMaxLen   Proc far
    mov al,64
    retf32
GetMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetMaxLen
;
;           DESCRIPTION:    Set max len
;
;           PARAMETERS:     FS      Pipe
;                           AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetMaxLen   Proc far
    retf32
SetMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               CloseControlPipe
;
;       DESCRIPTION:        Close control pipe
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseControlPipe   Proc far
    push es
    pushad
;    
    mov ax,fs:usbp_hub_sel
    or ax,ax
    jz ccpNoHub
;
    push gs
    mov gs,ax
    mov dx,fs:usbp_hub_port
    ResetUsbHubPort
    pop gs
    jmp ccpDone
       
ccpNoHub:
    mov es,fs:usbp_function_sel
    mov cl,es:usbf_port
    movzx edi,cl
    add edi,edi
;
    mov eax,es:[2*edi].HcPortSc
    and al,NOT 4
    mov es:[2*edi].HcPortSc,eax

ccpDone:
    mov ax,50
    WaitMilliSec
;
    popad
    pop es
    retf32
CloseControlPipe Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AttachThread
;
;   DESCRIPTION:    Attach thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..EHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

attach_thread_name  DB 'EHCI Attach ', 0

attach_thread:
    mov cl,dl
    mov ds,bx
    mov es,ds:ehc_reg_sel
;    
    movzx edi,cl
    add edi,edi
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[edi].usb_attach_thread_arr,ax
    LeaveSection ds:usb_section
;
    mov dx,10

atCheck:    
    mov ax,5
    WaitMilliSec
;
    mov eax,es:[2*edi].HcPortSc
    test al,1
    jz atDone
;
    sub dx,1
    jnz atCheck
;
    and ax,0C00h
    cmp ax,400h
    jne atDoReset
;
    test ds:ehc_flags,EHC_COMPANION
    jz atDone
;
    cmp cl,ds:ehc_comp_ports
    jae atDone
;    
    mov eax,3000h
    mov es:[2*edi].HcPortSc,eax
    jmp atDone
    
atDoReset:    
    LockUsb
;    
    mov eax,es:[2*edi].HcPortSc
    and al,NOT 4
    or ax,100h
    mov es:[2*edi].HcPortSc,eax
;
    mov ax,25
    WaitMilliSec
;    
    mov eax,es:[2*edi].HcPortSc
    and ax,NOT 100h
    mov es:[2*edi].HcPortSc,eax
;
    mov ax,25
    WaitMilliSec
;
    mov eax,es:[2*edi].HcPortSc
    test al,1
    jz atUnlock
;    
    test al,4
    jnz atHighSpeed
;
    test ds:ehc_flags,EHC_COMPANION
    jz atUnlock
;
    cmp cl,ds:ehc_comp_ports
    jae atUnlock
;    
    mov ax,3000h
    mov es:[2*edi].HcPortSc,eax
    jmp atUnlock
        
atHighSpeed:    
    and ax,NOT 100h
    mov es:[2*edi].HcPortSc,eax
    
atResetLoop:
    mov eax,es:[2*edi].HcPortSc
    test al,1
    jz atUnlock
;    
    test ax,100h
    jz atResetDone
;
    mov ax,5
    WaitMilliSec
    jmp atResetLoop

atResetDone:
    mov ax,2
    WaitMilliSec
;
    mov eax,es:[2*edi].HcPortSc
    test al,1
    jz atUnlock
;    
    test al,4
    jnz atNotify
;    
    test ds:ehc_flags,EHC_COMPANION
    jz atUnlock
;
    cmp cl,ds:ehc_comp_ports
    jae atUnlock
;    
    mov eax,3000h
    mov es:[2*edi].HcPortSc,eax
    jmp atUnlock
        
atNotify:
    mov dx,40

atWaitNotify:    
    mov ax,10
    WaitMilliSec
;
    mov eax,es:[2*edi].HcPortSc
    test al,1
    jz atUnlock
;
    sub dx,1
    jnz atWaitNotify
;
    push es
    push cx    
    push edi
    mov eax,SIZE usb_function_struc
    AllocateSmallGlobalMem
    xor di,di
    mov cx,SIZE usb_function_struc
    xor al,al
    rep stosb
    pop edi
    pop cx
;    
    mov es:usbf_port,cl
    mov es:usbf_slot,0
    mov es:usbf_address,0
    mov es:usbf_speed,2
    NotifyUsbAttach
    pop es
    jnc atDone
;
    mov eax,es:[2*edi].HcPortSc
    and al,NOT 4
    mov es:[2*edi].HcPortSc,eax
;
    NotifyUsbDetach
    jmp atDone

atUnlock:
    UnlockUsb

atDone:
    EnterSection ds:usb_section
    mov ds:[edi].usb_attach_thread_arr,0
    LeaveSection ds:usb_section
    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           DetachThread
;
;   DESCRIPTION:    Detach thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..EHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

detach_thread_name  DB 'EHCI Detach ', 0

detach_thread:
    mov cl,dl
    mov ds,bx
    mov es,ds:ehc_reg_sel
;
    movzx edi,cl
    add edi,edi
;    
    EnterSection ds:usb_section
    GetThread
    mov ds:[edi].usb_detach_thread_arr,ax
    LeaveSection ds:usb_section
;    
    push edi
    mov al,cl
    NotifyUsbDetach
    pop edi
;
    EnterSection ds:usb_section
    mov ds:[edi].usb_detach_thread_arr,0
    LeaveSection ds:usb_section    
    TerminateThread

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetThread
;
;   DESCRIPTION:    Reset thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..OHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_thread_name  DB 'EHCI Reset ', 0

reset_thread:
    mov cl,dl
    mov ds,bx
    mov es,ds:ehc_reg_sel
;    
    movzx edi,cl
    add edi,edi
;    
    EnterSection ds:usb_section
    GetThread
    mov ds:[edi].usb_reset_thread_arr,ax
    LeaveSection ds:usb_section
;    
    mov eax,es:[2*edi].HcPortSc
    and al,NOT 4
    or ax,100h
    mov es:[2*edi].HcPortSc,eax
;    
    mov al,cl
    NotifyUsbDetach
;    
    LockUsb
;
    mov ax,25
    WaitMilliSec
;    
    mov eax,es:[2*edi].HcPortSc
    and ax,NOT 100h
    mov es:[2*edi].HcPortSc,eax
;
    mov dx,40

rtWaitNotify:    
    mov ax,10
    WaitMilliSec
;
    mov eax,es:[2*edi].HcPortSc
    test al,1
    jz rtUnlock
;
    sub dx,1
    jnz rtWaitNotify
;
    push es
    push cx    
    push edi
    mov eax,SIZE usb_function_struc
    AllocateSmallGlobalMem
    xor di,di
    mov cx,SIZE usb_function_struc
    xor al,al
    rep stosb
    pop edi
    pop cx
;    
    mov es:usbf_port,cl
    mov es:usbf_slot,0
    mov es:usbf_address,0
    mov es:usbf_speed,2
    NotifyUsbAttach
    pop es
    jnc rtDone
;
    mov eax,es:[2*edi].HcPortSc
    and al,NOT 4
    mov es:[2*edi].HcPortSc,eax
;
    NotifyUsbDetach
    jmp rtDone

rtUnlock:
    UnlockUsb    

rtDone:
    EnterSection ds:usb_section
    mov ds:[edi].usb_reset_thread_arr,0
    LeaveSection ds:usb_section
    TerminateThread
        
        
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
    mov ax,1
    shl ax,cl
    test ax,ds:ehc_reset
    jz upNoReset
;
    not ax
    lock and ds:ehc_reset,ax
;        
    mov eax,es:[2*edi].HcPortSc
    test al,1
    jz upNoReset
;
    mov bx,ds:[edi].usb_port_arr
    or bx,bx
    jz upNoReset
;
    mov fs,bx
    mov bx,fs:usb_function_sel
    or bx,bx
    jz upNoReset
;    
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_reset_thread_arr,-1
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov dx,cx
    mov si,OFFSET reset_thread
    mov di,OFFSET reset_thread_name
    mov ax,2
    call StartThread
    jmp upDone
    
upNoReset:
    mov eax,es:[2*edi].HcPortSc
    test ax,2000h
    jnz upDone
;    
    test al,1
    jz upDetach
    
upAttach:
    mov bx,ds:[edi].usb_port_arr
    or bx,bx
    jz upCheckAttach
;
    mov fs,bx
    mov bx,fs:usb_function_sel
    jnz upCheckTimeout

upCheckAttach:
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_attach_thread_arr,-1
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov dx,cx
    mov si,OFFSET attach_thread
    mov di,OFFSET attach_thread_name
    mov ax,2
    call StartThread
    jmp upDone

upDetach:
    mov bx,ds:[edi].usb_port_arr
    or bx,bx
    jz upCheckTimeout
;
    mov fs,bx
    mov bx,fs:usb_function_sel
    or bx,bx
    jz upCheckTimeout
;    
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_detach_thread_arr,-1    
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov dx,cx
    mov si,OFFSET detach_thread
    mov di,OFFSET detach_thread_name
    mov ax,2
    call StartThread
    jmp upDone

upCheckTimeout:
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jz upDone
;
    GetSystemTime
    sub eax,ds:[4*edi].usb_timeout_arr
    sbb edx,ds:[4*edi].usb_timeout_arr+4
    jc upDone
;
    mov ax,ds:[edi].usb_retry_arr
    inc ax
    mov ds:[edi].usb_retry_arr,ax
;
    cmp ax,100
    jb upNotFatal
;
    int 3

upNotFatal:
    cmp ax,10
    jnz upDoSignal
;   
    mov eax,es:[2*edi].HcPortSc
    and al,NOT 4
    mov es:[2*edi].HcPortSc,eax

upDoSignal:
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;
    EnterSection ds:usb_section
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,bx
    jz upCheckDetach
;
    Signal
    jmp upLeave

upCheckDetach:    
    mov bx,ds:[edi].usb_detach_thread_arr
    or bx,bx
    jz upCheckReset
;
    Signal
    jmp upLeave
            
upCheckReset:    
    mov bx,ds:[edi].usb_reset_thread_arr
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
;       NAME:           LinkInterrupt
;
;       DESCRIPTION:    Link interrupts in tree
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
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
    mov es:[edi].qh_next_va,edx
    mov edx,es:[edx].qh_my_phys
    or dl,2
    mov es:[edi].qh_link,edx    
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
;                   FS  Reg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateInterrupt  Proc near
    push ds
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov es,ax
;
    call AllocateInactiveQh
    or al,3
    mov es:[edx].qh_link,eax
;
    mov bx,OFFSET ehc_1
    push edx
    call AllocateInactiveQh
    mov ds:[bx].ehc_cnt,0
    mov ds:[bx].ehc_qh,edx
    pop eax
;
    mov es:[edx].qh_next_va,eax
    mov eax,es:[eax].qh_my_phys
    or al,3
    mov es:[edx].qh_link,eax
;
    mov cx,2+4+8+16+32+64+128+256+512+1024 
    mov bx,OFFSET ehc_1024

ciInitLoop:
    call AllocateInactiveQh
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
    mov fs,bx
    mov ds:ehc_periodic_sel,bx
;
    mov cx,1024    
    mov si,OFFSET ehc_1024
    xor di,di

ciLoop:    
    mov edx,ds:[si].ehc_qh
    mov edx,es:[edx].qh_my_phys
    or dl,2
    mov fs:[di],edx
    add si,8
    add di,4
    loop ciLoop
;
    mov fs,ds:ehc_reg_sel
    mov eax,ds:ehc_periodic_phys
    mov fs:HcPeriodicListBase,eax
;    
    mov ax,25
    WaitMilliSec
;
    mov eax,fs:HcCommand    
    or al,10h
    mov fs:HcCommand,eax
;
    popad
    pop fs
    pop es
    pop ds    
    ret
CreateInterrupt Endp

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
    EnterSection ds:ehc_pipe_section
    mov ax,ds:ehc_pipe_list
    or ax,ax
    jz uplDone
;
    push es
    push fs
    push ebx
    push edx
    push di
;
    mov di,ax
    mov fs,ax
;
    mov ax,flat_sel
    mov es,ax

uplElemLoop:
    test fs:esp_flags, ESP_FLAG_TRANSFER_PENDING
    jz uplNext
;
    mov edx,fs:esp_qh
    or edx,edx
    jz uplNext
;    
    mov eax,es:[edx].qh_current_qtd
    or eax,eax
    jz uplNext
;    
    test fs:esp_flags, ESP_FLAG_SINGLE
    jz uplMulti
;
    cmp eax,fs:esp_current
    je uplNext
;
    jmp uplSignal

uplMulti:
    mov al,es:[edx].qh_status
    test al,80h
    jnz uplNext
;
    mov eax,es:[edx].qh_next_qtd
    test al,1
    jz uplNext

uplSignal:
    mov al,1
    xchg al,fs:esp_done
;
    cmp al,1
    je uplNext
;
    mov bx,fs:usbp_signal
    or bx,bx
    jz uplSignalDone
;
    Signal

uplSignalDone:
    mov bx,fs:usbp_wait
    or bx,bx
    jz uplNext
;
    push es
    mov es,bx
    SignalWait
    pop es

uplNext:    
    mov ax,fs:esp_next
    mov fs,ax
    cmp ax,di
    jne uplElemLoop
;
    pop di
    pop edx
    pop ebx
    pop fs
    pop es    

uplDone:    
    LeaveSection ds:ehc_pipe_section
    pop ax
    ret
UpdatePipeList  Endp
        
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
    AddThreadInt
    GetThread
    mov ds:ehc_thread,ax

efhLoop:
    WaitForSignal
    call UpdatePipeList
    jmp efhLoop
        
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
et00 DD OFFSET CreateControl,       SEG code
et01 DD OFFSET CreateBulk,          SEG code
et02 DD OFFSET CreateIntr,          SEG code
et03 DD OFFSET AddSetup,        SEG code
et04 DD OFFSET AddOut,          SEG code
et05 DD OFFSET AddIn,           SEG code
et06 DD OFFSET AddStatusOut,    SEG code
et07 DD OFFSET AddStatusIn,         SEG code
et08 DD OFFSET IssueTransfer,       SEG code
et09 DD OFFSET IsTransferDone,      SEG code
et0A DD OFFSET EndTransfer,     SEG code
et0B DD OFFSET WasTransferOk,       SEG code
et0C DD OFFSET GetDataSize,     SEG code
et0D DD OFFSET ClosePipe,       SEG code
et0E DD OFFSET WaitForCompletion,   SEG code
et0F DD OFFSET ChangeAddress,       SEG code
et10 DD OFFSET IsConnected,     SEG code
et11 DD OFFSET ResetPipe,       SEG code
et12 DD OFFSET LockEnum,        SEG code
et13 DD OFFSET UnlockEnum,      SEG code
et14 DD OFFSET AllocateHubPort, SEG code
et15 DD OFFSET FreeHubPort,     SEG code
et16 DD OFFSET Has64Bit,        SEG code
et17 DD OFFSET IsStalled,       SEG code
et18 DD OFFSET ClearStalled,    SEG code
et19 DD OFFSET GetMaxLen,       SEG code
et1A DD 0,                      0
et1B DD 0,                      0
et1C DD OFFSET SetMaxLen,       SEG code
et1D DD OFFSET CloseControlPipe, SEG code
ec1E DD OFFSET IssueOne,        SEG code

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
    mov cx,2*1Fh

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbDevice
    InitSection ds:ehc_section
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
    mov ds:ehc_pipe_list,0
    mov ds:ehc_reset,0
    mov ds:ehc_async_head_va,0
    InitSection ds:ehc_pipe_section
    InitSection ds:ehc_enum_section
    InitSection ds:ehc_hub_section
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
    movzx cx,al
    mov bx,OFFSET ehc_hub_port_arr

afAllocPorts:
    mov dword ptr ds:[bx],-1
    add bx,4
    loop afAllocPorts        
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
    AddThreadInt
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
    InitSection ds:EhciSection
    mov ds:EhciFuncCount,0
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
