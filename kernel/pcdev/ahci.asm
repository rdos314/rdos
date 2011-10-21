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
; AHCI.ASM
; AHCI SATA disk driver
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

FIS_TYPE_HTD            = 27h
FIS_TYPE_DTH            = 34h
FIS_TYPE_DMA_ACTIVATE   = 39h
FIS_TYPE_DMA_SETUP      = 41h
FIS_TYPE_DATA           = 46h
FIS_TYPE_BIST           = 58h
FIS_TYPE_PIO_SETUP      = 5Fh
FIS_TYPE_DEVICE_BITS    = 0A1h

fis_htd_struc   STRUC

fhtd_type       DB ?
fhtd_port_flags DB ?
fhtd_command    DB ?
fhtd_features0  DB ?
fhtd_lbal       DB ?,?,?
fhtd_device     DB ?
fhtd_lbah       DB ?,?,?
fhtd_features1  DB ?
fhtd_count      DW ?
fhtd_icc        DB ?
fhtd_control    DB ?
fhtd_aux        DW ?
fhtd_resv       DW ?

fis_htd_struc   ENDS

fis_dth_struc   STRUC

fdth_type       DB ?
fdth_port_flags DB ?
fdth_status     DB ?
fdth_error      DB ?
fdth_lbal       DB ?,?,?
fdth_device     DB ?
fdth_lbah       DB ?,?,?
fdth_resv1      DB ?
fdth_count      DW ?
fdth_resv2      DW ?,?,?

fis_dth_struc   ENDS

data    SEGMENT byte public 'DATA'

ahci_count      DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CheckPciAhci
;
;           DESCRIPTION:    Check for PCI AHCI devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckPciAhci Proc near
    mov ax,SEG data
    mov es,ax
;    
    xor ax,ax
    mov bh,1
    mov bl,6
    FindPciClassAll
    jc cpaDone
;
    push cx
    mov eax,2000h
    AllocateBigLinear
    pop cx
;    
    mov cl,PCI_nbr_base_address5
    ReadPciDword
;
    or al,67h
    SetPhysicalPage
    AllocateGdt
    push cx
    mov ecx,10FFh
    CreateDataSelector16
    pop cx
    mov es,bx
    
cpaDone:
    ret
CheckPciAhci Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ahci_thread
;
;           DESCRIPTION:    AHCI thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ahci_name DB 'AHCI',0

ahci_thread:
    int 3
    call CheckPciAhci

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_ahci
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_ahci    Proc far
    push ds
    push es
    pusha
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET ahci_name
    mov si,OFFSET ahci_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
;    EndDiscHandler
;
    popa
    pop es
    pop ds
    retf32
init_ahci    Endp

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
;    BeginDiscHandler
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_ahci
    HookInitPci
    clc
    ret
init    ENDP

code    ENDS

    END init
