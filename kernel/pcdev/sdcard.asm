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
; SDCARD.ASM
; SD card driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc
INCLUDE ..\os\protseg.def
INCLUDE pci.inc

MAX_SD_DEVICES = 32

STATE_BAD       = 1
STATE_INIT      = 2

REG_RESET   = 2Fh

sd_device_struc STRUC

sd_reg_sel      DW ?
sd_pci_bus      DB ?
sd_pci_device   DB ?
sd_pci_function DB ?
sd_state        DB ?

sd_device_struc ENDS

data    SEGMENT byte public 'DATA'

sd_dev_count   DW ?
sd_dev_arr     DW MAX_SD_DEVICES DUP (?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SdInt
;
;       DESCRIPTION:    IRQ handler
;
;       PARAMETERS:     DS      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SdInt  Proc far
    retf32
SdInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddDevice
;
;       DESCRIPTION:    Add an AHCI-device
;
;       PARAMETERS:     FS      Register selector
;                       EDX     Register linear
;                       BH      PCI Bus
;                       BL      PCI Device
;                       CH      PCI Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice   Proc near
    push es
    pushad
;
    push ax
    mov eax,SIZE sd_device_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:sd_reg_sel,fs
    mov es:sd_pci_bus,bh
    mov es:sd_pci_device,bl
    mov es:sd_pci_function,ch
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_dev_count
    shl bx,1
    mov ds:[bx].sd_dev_arr,es    
    inc ds:sd_dev_count
;
    popad
    pop es
    ret
AddDevice   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciDev
;
;           DESCRIPTION:    Init PCI SD-card devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPciDev Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:sd_dev_count,0
;    
    xor si,si

ipdLoop: 
    mov ax,si
    mov bh,8
    mov bl,5
    FindPciClassAll
    jc ipdDone
;
    push cx
    mov eax,1000h
    AllocateBigLinear
    pop cx
;    
    mov cl,PCI_nbr_base_address0
    ReadPciDword
;    
    push eax
    and ax,0F000h
    push ebx
    xor ebx,ebx
    mov al,67h
    SetPageEntry
    pop ebx
    pop eax
;
    and eax,0E00h
    add edx,eax
;        
    push bx
    AllocateGdt
    push cx
    mov ecx,200h
    CreateDataSelector16
    pop cx
    mov fs,bx
    mov fs:REG_RESET,1
    pop bx
    call AddDevice
;
    inc si
    jmp ipdLoop

ipdDone:
    ret
InitPciDev  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup device ints
;
;           PARAMETERS:     DS     Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts Proc near
    mov bh,ds:sd_pci_bus
    mov bl,ds:sd_pci_device
    mov ch,ds:sd_pci_function
    GetPciMsi
    jc siIrq
;    
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc siIrq    
;    
    SetupPciMsi
    mov di,cs
    mov es,di
    mov edi,OFFSET SdInt
    RequestMsiHandler
    jmp siOk

siIrq:
    GetPciIrqNr
    mov ah,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET SdInt
    RequestIrqHandler

siOk:    
    ret
SetupInts   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupDev
;
;           DESCRIPTION:    Setup device
;
;           PARAMETERS:     DS     Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDev    Proc near
    int 3
    mov fs,ds:sd_reg_sel
    mov al,fs:REG_RESET
    and al,1
    jz stdResetOk
;
    mov ax,100
    WaitMilliSec
    mov al,fs:REG_RESET
    and al,1
    jz stdResetOk
;
    mov ds:sd_state, STATE_BAD    
    jmp stdDone    

stdResetOk:        
    mov ds:sd_state, STATE_INIT

stdDone:    
    ret
SetupDev    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartDevices
;
;           DESCRIPTION:    Start SD device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDevices Proc near
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:sd_dev_count
    mov bx,OFFSET sd_dev_arr
    or cx,cx
    jz sdvDone

sdvLoop:
    push ds
    push bx
    push cx
;
    mov ds,ds:[bx]
    call SetupInts
    call SetupDev
;
    pop cx
    pop bx
    pop ds
;
    add bx,2
    loop sdvLoop

sdvDone:
    ret
StartDevices    Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           sd
;
;           DESCRIPTION:    SD init thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sd_name DB 'SD Card',0

sd_thread:
    int 3
    call InitPciDev
    call StartDevices
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_sd
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sd    Proc far
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET sd_name
    mov si,OFFSET sd_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_sd    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_net
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,SEG data
    mov ds,ax
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_sd
    HookInitPci
    clc
    ret
init    ENDP

code    ENDS

    END init
