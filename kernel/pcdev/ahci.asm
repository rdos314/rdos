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

MAX_AHCI_DEVICES    = 16

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

HBA_CAP_S64A        = 80000000h
HBA_CAP_SNCQ        = 40000000h
HBA_CAP_SSNTF       = 20000000h
HBA_CAP_SMPS        = 10000000h
HBA_CAP_SSS         =  8000000h
HBA_CAP_SALP        =  4000000h
HBA_CAP_SAL         =  2000000h
HBA_CAP_SCLO        =  1000000h
HBA_CAP_SAM         =    40000h
HBA_CAP_SPM         =    20000h
HBA_CAP_FBSS        =    10000h
HBA_CAP_PMD         =     8000h
HBA_CAP_SSC         =     4000h
HBA_CAP_PSC         =     2000h
HBA_CAP_CCCS        =       80h
HBA_CAP_EMS         =       40h
HBA_CAP_SXS         =       20h

hba_struc   STRUC

hba_cap         DD ?
hba_ghc         DD ?
hba_is          DD ?
hba_pi          DD ?
hba_vs          DD ?
hba_ccc_ctl     DD ?
hba_ccc_ports   DD ?
hba_em_loc      DD ?
hba_em_ctl      DD ?
hba_cap2        DD ?
hba_bohc        DD ?

hba_struc   ENDS

hba_port_struc  STRUC

hba_pxclb       DD ?
hba_pxclbu      DD ?
hba_pxfb        DD ?
hba_pxfbu       DD ?
hba_pxis        DD ?
hba_pxie        DD ?
hba_pxcmd       DD ?
hba_resv1       DD ?
hba_pxtfd       DD ?
hba_pxsig       DD ?
hba_pxssts      DD ?
hba_pxsctl      DD ?
hba_pxserr      DD ?
hba_pxsact      DD ?
hba_pxci        DD ?
hba_pxsntf      DD ?
hba_pxfbs         DD ?

hba_port_struc  ENDS

;
; Command table
;

act_cfis        = 0
act_acmd        = 40h
act_prd         = 80h

ahci_prd_entry  STRUC

ape_base        DD ?,?
ape_handle      DD ?
ape_byte_count  DD ?

ahci_prd_entry  ENDS

;
; slot structure
;

ahci_slot_struc  STRUC

as_entries      DW ?
as_slots        DW ?
as_list_arr     DW 32 DUP(?)
as_table_arr    DW 32 DUP(?)

ahci_slot_struc  ENDS

;
; port structure
;

ahci_port_struc     STRUC

ap_linear           DD ?
ap_physical         DD ?
ap_pages            DW ?

ap_hba_sel          DW ?
ap_fis_sel          DW ?
ap_cmd_sel          DW ?
ap_slot_sel         DW ?

ahci_port_struc     ENDS

;
; Received FIS area
;

ap_fis          = 700h      ; this only applies when FIS-based switching is not used!
ap_fis_size     = 100h

ap_dsfis        = 0h
ap_psfis        = 20h
ap_rfis         = 40h
ap_sdbfis       = 58h
ap_ufis         = 60h

;
; Command list area
;

ap_cmd          = 800h
ap_cmd_size     = 400h

ahci_command_list_struc  STRUC

acl_flags        DW ?
acl_prdtl        DW ?
acl_prd_count    DD ?
acl_ctba         DD ?,?

ahci_command_list_struc  ENDS


;
; device structure
;

ahci_device_struc   STRUC

ad_hba_sel          DW ?
ad_port_arr         DW 32 DUP(?)

ahci_device_struc   ENDS

data    SEGMENT byte public 'DATA'

ahci_dev_count      DW ?
ahci_dev_arr        DW MAX_AHCI_DEVICES DUP(?)

data    ENDS

    .386p

prd_slot_table  STRUC

prd_slots       DW ?
prd_entries     DW ?
prd_size        DW ?
prd_pages       DW ?

prd_slot_table  ENDS

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetSlotEntry
;
;       DESCRIPTION:    Get slot entry to use
;
;       PARAMETERS:     FS          HBA sel
;
;       RETURNS:        CS:BX       Slot entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

p1   prd_slot_table <1, 1F8h, 2000h, 2>
p2   prd_slot_table <2, 0F8h, 1000h, 2>
p3   prd_slot_table <3, 0A0h, 0A80h, 2>
p4   prd_slot_table <4, 78h, 800h, 2>
p5   prd_slot_table <5, 90h, 980h, 3>
p6   prd_slot_table <6, 78h, 800h, 3>
p7   prd_slot_table <7, 88h, 900h, 4>
p8   prd_slot_table <8, 78h, 800h, 4>
p9   prd_slot_table <9, 68h, 700h, 4>
p10  prd_slot_table <10, 58h, 600h, 4>
p11  prd_slot_table <11, 50h, 580h, 4>
p12  prd_slot_table <12, 48h, 500h, 4>
p13  prd_slot_table <12, 48h, 500h, 4>
p14  prd_slot_table <14, 40h, 480h, 4>
p15  prd_slot_table <14, 40h, 480h, 4>
p16  prd_slot_table <16, 38h, 400h, 4>
p17  prd_slot_table <16, 38h, 400h, 4>
p18  prd_slot_table <18, 30h, 380h, 4>
p19  prd_slot_table <18, 30h, 380h, 4>
p20  prd_slot_table <18, 30h, 380h, 4>
p21  prd_slot_table <21, 28h, 300h, 4>
p22  prd_slot_table <21, 28h, 300h, 4>
p23  prd_slot_table <21, 28h, 300h, 4>
p24  prd_slot_table <21, 28h, 300h, 4>
p25  prd_slot_table <25, 20h, 280h, 4>
p26  prd_slot_table <25, 20h, 280h, 4>
p27  prd_slot_table <25, 20h, 280h, 4>
p28  prd_slot_table <25, 20h, 280h, 4>
p29  prd_slot_table <25, 20h, 280h, 4>
p30  prd_slot_table <25, 20h, 280h, 4>
p31  prd_slot_table <25, 20h, 280h, 4>
p32  prd_slot_table <32, 20h, 280h, 5>

GetSlotEntry     Proc near
    push eax
    push dx
;    
    mov eax,fs:hba_cap
    shr ax,8
    and ax,1Fh
    mov bx,SIZE prd_slot_table
    mul bx
    mov bx,OFFSET p1
    add bx,ax
;
    pop dx    
    pop eax
    ret
GetSlotEntry     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddPort
;
;       DESCRIPTION:    Add an AHCI port
;
;       PARAMETERS:     FS          HBA selector
;                       ES:DI       Device entry
;                       EDX         Port linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPort     Proc near
    push ds
    pushad
;    
    call GetSlotEntry
    movzx ecx,cs:[bx].prd_pages
    inc cx
    mov eax,fs:hba_cap
    test eax,HBA_CAP_FBSS
    jz apPagesOk
;
    inc cx

apPagesOk:
    AllocateMultiplePhysical
    mov al,67h
    push eax
    mov eax,ecx
    shl eax,12
    AllocateBigLinear
    pop eax
;
    push ecx

apPhysLoop:
    SetPhysicalPage
    add eax,1000h
    add edx,1000h
    loop apPhysLoop
;
    pop ecx
;        
    push cx
    shl ecx,12
    sub eax,ecx
    sub edx,ecx
    xor al,al
;                
    push bx
    AllocateGdt
    mov ecx,SIZE ahci_port_struc
    CreateDataSelector16    
    mov ds,bx
    mov es:[di],bx
    pop bx
    pop cx
;
    mov ds:ap_linear,edx
    mov ds:ap_physical,eax
    mov ds:ap_pages,cx
;
    popad
    pop ds    
    ret
AddPort     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddDevice
;
;       DESCRIPTION:    Add an AHCI-device
;
;       PARAMETERS:     FS          HBA selector
;                       EDX         HBA linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice   Proc near
    push es
    pushad
;
    mov eax,SIZE ahci_device_struc
    AllocateSmallGlobalMem
    mov es:ad_hba_sel,fs
;
    mov cx,32
    mov eax,fs:hba_pi
    mov di,OFFSET ad_port_arr
    add edx,100h

adPortAddLoop:
    mov word ptr es:[di],0
    rcr eax,1
    jnc adPortAddNext
;
    call AddPort

adPortAddNext:
    add edx,80h
    add di,2
    loop adPortAddLoop        
;
    mov bx,ds:ahci_dev_count
    add bx,bx
    add bx,OFFSET ahci_dev_arr
    mov ds:[bx],es
    inc ds:ahci_dev_count
;
    popad
    pop es    
    ret
AddDevice   Endp

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
    mov ds,ax
    mov ds:ahci_dev_count,0
;    
    xor si,si

cpaLoop: 
    mov ax,si
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
;
    add eax,1000h
    add edx,1000h
    SetPhysicalPage
    sub edx,1000h
;        
    AllocateGdt
    push cx
    mov ecx,100h
    CreateDataSelector16
    pop cx
    mov fs,bx
    test fs:hba_ghc,80000000h
    jz cpaNext
;
    call AddDevice

cpaNext:
    inc si
    jmp cpaLoop
    
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
