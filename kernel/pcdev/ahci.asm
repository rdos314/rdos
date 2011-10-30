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
MAX_AHCI_PORTS      = 32

ATA_DMA_READ            = 25h
ATA_DMA_WRITE           = 35h
ATA_PIO_IDENTIFY        = 0ECh

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

HBA_GHC_AE          = 80000000h
HBA_GHC_MRSM        =        4h
HBA_GHC_IE          =        2h
HBA_GHC_HR          =        1h

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

HBA_PXCMD_ASP   =  8000000h
HBA_PXCMD_ALPE  =  4000000h
HBA_PXCMD_DLAE  =  2000000h
HBA_PXCMD_ATAPI =  1000000h
HBA_PXCMD_APSTE =   800000h
HBA_PXCMD_FBSCP =   400000h
HBA_PXCMD_ESP   =   200000h
HBA_PXCMD_CPD   =   100000h
HBA_PXCMD_MPSP  =    80000h
HBA_PXCMD_HPCP  =    40000h
HBA_PXCMD_PMA   =    20000h
HBA_PXCMD_CPS   =    10000h
HBA_PXCMD_CR    =     8000h
HBA_PXCMD_FR    =     4000h
HBA_PXCMD_MPSS  =     2000h
HBA_PXCMD_FRE   =       10h
HBA_PXCMD_CLO   =        8h
HBA_PXCMD_POD   =        4h
HBA_PXCMD_SUD   =        2h
HBA_PXCMD_ST    =        1h

HBA_PXI_CPD    = 80000000h
HBA_PXI_TFE    = 40000000h
HBA_PXI_HBF    = 20000000h
HBA_PXI_HBD    = 10000000h
HBA_PXI_IF     =  8000000h
HBA_PXI_INF    =  4000000h
HBA_PXI_OF     =  1000000h
HBA_PXI_IPM    =   800000h
HBA_PXI_PRC    =   400000h
HBA_PXI_DPM    =       80h
HBA_PXI_PC     =       40h
HBA_PXI_DP     =       20h
HBA_PXI_UF     =       10h
HBA_PXI_SDB    =        8h
HBA_PXI_DS     =        4h
HBA_PXI_PS     =        2h
HBA_PXI_DHR    =        1h

HBA_PXI_FATAL  = 78000000h
HBA_PXI_INFO   = 814000C0h
HBA_PXI_FIS    =       1Fh

HBA_PXI_ENABLE = HBA_PXI_FATAL OR HBA_PXI_INFO OR HBA_PXI_DP

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
as_slot_mask    DD ?
as_index_arr    DW 32 DUP(?)

ahci_slot_struc  ENDS

;
; port structure
;

PORT_FLAG_ATA       =   1h
PORT_FLAG_48_BIT    =   2h


ahci_port_struc     STRUC

ap_linear           DD ?
ap_physical         DD ?
ap_pages            DW ?
ap_device           DW ?

ap_hba_sel          DW ?
ap_fis_sel          DW ?
ap_cmd_sel          DW ?
ap_slot_sel         DW ?

ap_flags            DW ?

ap_sector_count     DD ?

ap_thread_arr       DW 32 DUP(?)

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
ahci_port_count     DW ?
ahci_port_arr       DW MAX_AHCI_PORTS DUP(?)

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
;       NAME:           IrqPort
;
;       DESCRIPTION:    IRQ port handler
;
;       PARAMETERS:     DS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IrqPort  Proc near
    mov es,ds:ap_hba_sel
    mov eax,es:hba_pxis
    mov es:hba_pxis,eax
    ret
IrqPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IrqHandler
;
;       DESCRIPTION:    IRQ handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IrqHandler  Proc near

ihRetry:    
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:ahci_dev_count
    mov si,OFFSET ahci_dev_arr

ihLoop:
    mov es,ds:[si]
    mov fs,es:ad_hba_sel
    mov eax,fs:hba_is
    and eax,fs:hba_pi
    jz ihNext

ihHandle:
    mov si,OFFSET ad_port_arr
    mov edx,1

ihHandlePort:    
    shr eax,1
    jnc ihHandleNext
;
    push es
    push fs
    push eax
    push edx
    push si
    mov ds,es:[si]
    call IrqPort    
    pop si
    pop edx
    pop eax
    pop fs
    pop es
    mov fs:hba_is,edx

ihHandleNext:
    or eax,eax
    jz ihRetry
;    
    shl edx,1
    add si,2
    jmp ihHandlePort        

ihNext:
    add si,2
    loop ihLoop

ihDone:        
    ret
IrqHandler  Endp

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
;       NAME:           CreatePortFis
;
;       DESCRIPTION:    Create port FIS area
;
;       PARAMETERS:     DS      Port sel
;                       FS      HBA sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePortFis   Proc near
    push es
    push eax
    push bx
    push ecx
    push edx
;    
    mov eax,fs:hba_cap
    test eax,HBA_CAP_FBSS
    jz cpfInHeader

cpfLastPage:
    movzx edx,ds:ap_pages
    dec edx
    shl edx,12
    mov ecx,1000h
    jmp cpfDo

cpfInHeader:
    mov edx,ap_fis
    mov ecx,ap_fis_size

cpfDo:
    mov eax,ds:ap_linear
    add edx,eax
    AllocateGdt
    CreateDataSelector16
    mov ds:ap_fis_sel,bx    
;    
    pop edx
    pop ecx
    pop bx
    pop eax
    pop es   
    ret
CreatePortFis   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreatePortCmdList
;
;       DESCRIPTION:    Create port command list
;
;       PARAMETERS:     DS      Port sel
;                       FS      HBA sel
;                       CS:BX   Slot entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePortCmdList   Proc near
    push es
    pushad
;    
    push cs:[bx].prd_size
    push cs:[bx].prd_slots
;    
    mov ecx,ap_cmd_size
    mov edx,ap_cmd
    add edx,ds:ap_linear
    AllocateGdt
    CreateDataSelector16
    mov ds:ap_cmd_sel,bx    
;
    pop cx
    pop dx
;
    mov es,ds:ap_cmd_sel
    xor di,di
    mov eax,ds:ap_physical
    add eax,1000h
    movzx edx,dx

cpclLoop:
    mov es:[di].acl_ctba,eax
    mov es:[di].acl_flags,5
    add di,20h
    add eax,edx
    loop cpclLoop    
; 
    popad
    pop es       
    ret
CreatePortCmdList   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreatePortSlots
;
;       DESCRIPTION:    Create port slot area
;
;       PARAMETERS:     DS      Port sel
;                       FS      HBA sel
;                       CS:BX   Slot entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePortSlots Proc near
    push es
    pushad
;    
    push bx
    mov edx,ds:ap_linear
    add edx,1000h - SIZE ahci_slot_struc
    movzx ecx,cs:[bx].prd_pages
    shl ecx,12
    add ecx,SIZE ahci_slot_struc
    AllocateGdt
    CreateDataSelector16    
    mov ds:ap_slot_sel,bx
    mov es,bx
    pop bx    
;
    mov ax,cs:[bx].prd_slots
    mov es:as_slots,ax
    mov ax,cs:[bx].prd_entries
    mov es:as_entries,ax
;
    mov cx,32
    sub cx,es:as_slots
    mov eax,0FFFFFFFFh
    shr eax,cl
    mov es:as_slot_mask,eax
;    
    mov cx,es:as_slots
    mov ax,SIZE ahci_slot_struc
    mov dx,cs:[bx].prd_size
    mov di,OFFSET as_index_arr        

cpsLoop:
    stosw
    add ax,dx
    loop cpsLoop
;
    popad
    pop es    
    ret
CreatePortSlots Endp

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
    AllocateGdt
    mov ecx,80h
    CreateDataSelector16
    push bx
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
    push es
    push eax
    push ecx
    push edi
;    
    mov edi,edx
    mov ax,flat_sel
    mov es,ax
    xor eax,eax
    shr ecx,2
    rep stos dword ptr es:[edi]
;
    pop edi
    pop ecx
    pop eax
    pop es
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
    mov ds:ap_device,es
    mov ds:ap_flags,0
;
    pop ax
    mov ds:ap_hba_sel,ax
;
    mov cx,32
    mov di,OFFSET ap_thread_arr
    xor ax,ax
    rep stosw
;
    call CreatePortFis
    call CreatePortCmdList
    call CreatePortSlots
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
    or dword ptr fs:hba_bohc,2
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
;           NAME:           InitPciAhci
;
;           DESCRIPTION:    Init PCI AHCI devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPciAhci Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:ahci_dev_count,0
;    
    xor si,si

ipaLoop: 
    mov ax,si
    mov bh,1
    mov bl,6
    FindPciClassAll
    jc ipaDone
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
    test fs:hba_ghc,HBA_GHC_AE
    jz ipaNext
;
    call AddDevice

ipaNext:
    inc si
    jmp ipaLoop
    
ipaDone:
    ret
InitPciAhci Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetAhci
;
;           DESCRIPTION:    Reset AHCI devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetAhci Proc near
    mov ax,SEG data
    mov ds,ax
;
    mov dx,100

raRetry:    
    mov cx,ds:ahci_dev_count
    or cx,cx
    jz raDone
;    
    mov si,OFFSET ahci_dev_arr

raCheck:
    mov fs,ds:[si]
    mov fs,fs:ad_hba_sel
    mov eax,fs:hba_bohc
    test al,1
    jnz raWait
;
    add si,2
    loop raCheck    
    jmp raCheckDone

raWait:
    sub dx,1
    jz raCheckDone
;    
    mov ax,10
    WaitMilliSec
    jmp raRetry    

raCheckDone:    
    mov cx,ds:ahci_dev_count
    mov si,OFFSET ahci_dev_arr

raReset:
    mov fs,ds:[si]
    mov fs,fs:ad_hba_sel
    or dword ptr fs:hba_ghc,HBA_GHC_HR
    add si,2
    loop raReset

raDone:
    ret
ResetAhci Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartPort
;
;           DESCRIPTION:    Start port
;
;           PARAMETERS:     DS     Device
;                           FS     HBA sel
;                           ES     Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartPort Proc near
    mov gs,es:ap_hba_sel
    mov eax,fs:hba_cap
    test eax,HBA_CAP_FBSS
    jz spInHeader

spLastPage:
    movzx edx,es:ap_pages
    dec edx
    shl edx,12
    jmp spDo

spInHeader:
    mov edx,ap_fis

spDo:
    mov eax,es:ap_physical
    add eax,edx
    mov gs:hba_pxfb,eax
    mov gs:hba_pxfbu,0
    mov eax,gs:hba_pxfb
    or gs:hba_pxcmd,HBA_PXCMD_FRE OR HBA_PXCMD_SUD
;
    mov eax,gs:hba_pxis
    mov gs:hba_pxis,eax
;    
    mov eax,HBA_PXI_ENABLE
    mov gs:hba_pxie,eax       
    ret
StartPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartDevice
;
;           DESCRIPTION:    Start device
;
;           PARAMETERS:     DS     Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDevice Proc near
    mov fs,ds:ad_hba_sel
    or fs:hba_ghc,HBA_GHC_AE
;
    mov cx,32
    mov si,OFFSET ad_port_arr

sdLoop:
    mov ax,ds:[si]
    or ax,ax
    jz sdNext
;    
    push cx
    push si
    mov es,ax
    call StartPort
    pop si
    pop cx

sdNext:
    add si,2
    loop sdLoop
;
    mov eax,fs:hba_pi
    mov fs:hba_is,eax
    ret
StartDevice Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartAhci
;
;           DESCRIPTION:    Start AHCI devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartAhci Proc near
    mov ax,SEG data
    mov ds,ax
;
    mov dx,100

saRetry:    
    mov cx,ds:ahci_dev_count
    or cx,cx
    jz saDone
;    
    mov si,OFFSET ahci_dev_arr

saCheck:
    mov fs,ds:[si]
    mov fs,fs:ad_hba_sel
    test fs:hba_ghc,HBA_GHC_HR
    jnz saWait
;
    add si,2
    loop saCheck    
    jmp saCheckDone

saWait:
    sub dx,1
    jz saCheckDone
;    
    mov ax,10
    WaitMilliSec
    jmp saRetry    

saCheckDone:    
    mov cx,ds:ahci_dev_count
    mov si,OFFSET ahci_dev_arr

saStart:
    push ds
    push cx
    push si
    mov ds,ds:[si]
    call StartDevice    
    pop si
    pop cx
    pop ds
    add si,2
    loop saStart

saDone:
    ret
StartAhci Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitPortDet
;
;           DESCRIPTION:    Wait for port detect to become valid
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitPortDet Proc near
    mov ax,SEG data
    mov ds,ax
;    
    mov dx,100

wpdRetry:    
    mov cx,ds:ahci_dev_count
    mov si,OFFSET ahci_dev_arr

wpdDev:
    push ds
    push cx
    push si
;
    mov ds,ds:[si]
    mov cx,32
    mov si,OFFSET ad_port_arr

wpdPort:
    mov ax,ds:[si]
    or ax,ax
    jz wpdNext    
;
    mov es,ax
    mov es,es:ap_hba_sel
    mov eax,es:hba_pxssts
    and al,0Fh
    cmp al,3
    jne wpdWait
    
wpdNext:
    add si,2
    loop wpdPort
;    
    pop si
    pop cx
    pop ds
;
    add si,2
    loop wpdDev        
    jmp wpdDone

wpdWait:
    pop si
    pop cx
    pop ds
;
    mov ax,10
    WaitMilliSec
    jmp wpdRetry

wpdDone:
    ret
WaitPortDet Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearPortSerr
;
;           DESCRIPTION:    Clear port SERR
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearPortSerr Proc near
    mov ax,SEG data
    mov ds,ax
;    
    mov cx,ds:ahci_dev_count
    mov si,OFFSET ahci_dev_arr

cpsDev:
    push ds
    push cx
    push si
;
    mov ds,ds:[si]
    mov cx,32
    mov si,OFFSET ad_port_arr

cpsPort:
    mov ax,ds:[si]
    or ax,ax
    jz cpsNext    
;
    mov es,ax
    mov es,es:ap_hba_sel
;    
    mov eax,es:hba_pxssts
    and al,0Fh
    cmp al,3
    jne cpsNext
;
    mov eax,0FFFFFFFFh
    mov es:hba_pxserr,eax
    
cpsNext:
    add si,2
    loop cpsPort
;    
    pop si
    pop cx
    pop ds
;
    add si,2
    loop cpsDev        
;    
    ret
ClearPortSerr Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ActivatePorts
;
;           DESCRIPTION:    Activate functioning ports
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ActivatePorts Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:ahci_port_count,0
;    
    mov cx,ds:ahci_dev_count
    mov si,OFFSET ahci_dev_arr

apDev:
    push ds
    push cx
    push si
;
    mov ds,ds:[si]
    mov cx,32
    mov si,OFFSET ad_port_arr

apPort:
    mov bx,ds:[si]
    or bx,bx
    jz apNext    
;
    mov gs,bx
    mov es,gs:ap_hba_sel
;    
    mov eax,es:hba_pxssts
    and al,0Fh
    cmp al,3
    jne apNext
;
    mov eax,es:hba_pxtfd
    and al,88h
    jnz apNext
;
    mov eax,ap_cmd
    add eax,gs:ap_physical
    mov es:hba_pxclb,eax
    mov es:hba_pxclbu,0
    or es:hba_pxcmd,HBA_PXCMD_ST
;
    push ds
    push si
;    
    mov ax,SEG data
    mov ds,ax
    mov si,ds:ahci_port_count 
    add si,si
    add si,OFFSET ahci_port_arr
    mov ds:[si],bx
    inc ds:ahci_port_count
;
    pop si
    pop ds
    
apNext:
    add si,2
    loop apPort
;    
    pop si
    pop cx
    pop ds
;
    add si,2
    loop apDev        
;    
    ret
ActivatePorts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AllocateSlot
;
;   DESCRIPTION:    Allocate a slot
;
;   PARAMETERS:     GS      Port sel
;
;   RETURNS:        AL      Slot #
;                   DS:BX   PRDT entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateSlot Proc near
    push es
    push edx
;
    mov es,gs:ap_hba_sel
    mov ds,gs:ap_slot_sel
    mov edx,es:hba_pxci
    not edx
    and edx,ds:as_slot_mask
    stc
    jz asDone        
;
    mov bx,OFFSET as_index_arr
    xor al,al

asLoop:
    rcr edx,1
    jc asFound
;
    add bx,2
    inc al
    jmp asLoop

asFound:
    mov bx,ds:[bx]
    clc

asDone:
    pop edx
    pop es               
    ret
AllocateSlot    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupAta
;
;       DESCRIPTION:    Setup ATA
;
;       PARAMETERS:     GS      Port sel
;                       DS:BX   PRDT entry 
;                       AL      Command code
;                       EDX     Sector #
;                       CX      Sectors
;
;       RETURNS:        DS:BX   First PRD entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupAta    Proc near
    push edx
;
    mov ds:[bx].fhtd_type,FIS_TYPE_HTD
    mov ds:[bx].fhtd_port_flags,80h
    mov ds:[bx].fhtd_command,al
    mov dword ptr ds:[bx].fhtd_lbal,edx
    xor dl,dl
    xchg dl,ds:[bx].fhtd_device
    movzx edx,dl
    mov dword ptr ds:[bx].fhtd_lbah,edx
    mov ds:[bx].fhtd_count,cx
    add bx,act_prd
;
    pop edx    
    ret
SetupAta    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddPrdEntry
;
;       DESCRIPTION:    Add a single PRD entry
;
;       PARAMETERS:     GS      Port sel
;                       DS:BX   PRD entry
;                       ECX     Size
;                       ESI     Linear base
;                       EDI     Disc handle
;                       
;       RETURNS:        DS:BX   Next PRD entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPrdEntry     Proc near
    push eax
    push edx
    push esi
;
    mov edx,esi
    and dx,0F000h        
    GetPhysicalPage
    and ax,0F000h
    and esi,0FFFh
    add esi,eax
    mov ds:[bx].ape_base,esi
    mov ds:[bx+4].ape_base,0
    mov ds:[bx].ape_handle,edi
;
    mov eax,ecx
    dec eax
    or eax,80000000h    
    mov ds:[bx].ape_byte_count,eax
    add bx,10h
;
    pop esi
    pop edx
    pop eax        
    ret
AddPrdEntry     Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupReadCmd
;
;       DESCRIPTION:    Setup read command
;
;       PARAMETERS:     GS      Port sel
;                       AL      Slot #
;                       CX      Sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupReadCmd    Proc near
    push ds
    push bx
;
    mov ds,gs:ap_cmd_sel
    movzx bx,al
    shl bx,5
    mov ds:[bx].acl_prdtl,cx
    mov ds:[bx].acl_flags,485h
    mov ds:[bx].acl_prd_count,0
;
    pop bx    
    pop ds
    ret
SetupReadCmd    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupWriteCmd
;
;       DESCRIPTION:    Setup write command
;
;       PARAMETERS:     GS      Port sel
;                       AL      Slot #
;                       CX      Sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupWriteCmd    Proc near
    push ds
    push bx
;
    mov ds,gs:ap_cmd_sel
    movzx bx,al
    shl bx,5
    mov ds:[bx].acl_prdtl,cx
    mov ds:[bx].acl_flags,4C5h
    mov ds:[bx].acl_prd_count,0
;
    pop bx    
    pop ds
    ret
SetupWriteCmd    Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupWait
;
;       DESCRIPTION:    Setup wait
;
;       PARAMETERS:     GS      Port sel
;                       AL      Slot #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupWait    Proc near
    push ax
    push bx
;
    ClearSignal
;
    movzx bx,al
    add bx,bx
    GetThread
    mov gs:[bx].ap_thread_arr,ax
;
    pop bx    
    pop ax
    ret
SetupWait    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           StartCmd
;
;   DESCRIPTION:    Start a command
;
;   PARAMETERS:     GS      Port sel
;                   AL      Slot #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartCmd Proc near
    push ds
    push eax
    push cx
    push edx
;
    mov ds,gs:ap_hba_sel
    mov cl,al
    mov edx,1
    shl edx,cl
    mov ds:hba_pxci,edx
;
    pop edx
    pop cx
    pop eax
    pop ds
    ret
StartCmd    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           WaitForCompletion
;
;   DESCRIPTION:    Wait for completion
;
;   PARAMETERS:     GS      Port sel
;                   AL      Slot #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion Proc near
    int 3

wfcL:
    call IrqHandler
    jmp wfcL

    push ds
    push eax
    push cx
    push edx
;
    mov ds,gs:ap_hba_sel
    mov cl,al
    mov edx,1
    shl edx,cl

wfcLoop:
    mov eax,ds:hba_pxci
    test eax,edx
    jz wfcDone
;
    mov ax,1
    WaitMilliSec
    jmp wfcLoop        

wfcDone:
    pop edx
    pop cx
    pop eax
    pop ds
    ret
WaitForCompletion    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetDriveParams
;
;       DESCRIPTION:    Get drive param
;
;       PARAMETERS:     AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDriveParams  Proc near
    push es
    push gs
    pushad
;
    movzx bx,al
    add bx,bx
    add bx,OFFSET ahci_port_arr
;    
    mov ax,flat_sel
    mov es,ax    
    mov eax,1000h
    AllocateBigLinear
    mov esi,edx
    mov al,es:[esi]
;    
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:[bx]
    or ax,ax
    stc
    jz gdpDone
;    
    mov gs,ax
    call AllocateSlot
    push ax
;
    xor edx,edx
    mov cx,1
    mov al,0ECh
    call SetupAta
;    
    push cx
    xor edi,edi
    mov ecx,200h
    call AddPrdEntry
    pop cx
;
    pop ax
    call SetupReadCmd
    call SetupWait
    call StartCmd
    call WaitForCompletion
;
    mov ds,gs:ap_hba_sel
    mov eax,ds:hba_pxtfd
    test al,1
    stc
    jnz gdpDone
;
    mov ax,1
    WaitMilliSec
;    
    or gs:ap_flags,PORT_FLAG_ATA
    mov ax,es:[esi+166]
    test ax,4000h
    jz gdp24

gdp48:
    or gs:ap_flags,PORT_FLAG_48_BIT
    mov edx,es:[esi+204]
    mov eax,es:[esi+200]
    or edx,edx
    jz gdp48Save
;
    mov eax,0FFFFFFFFh

gdp48Save:
    mov gs:ap_sector_count,eax
    clc
    jmp gdpDone

gdp24:
    mov eax,es:[esi+120]
    mov gs:ap_sector_count,eax
    clc

gdpDone:
    pushf
    mov ecx,1000h
    mov edx,esi
    FreeLinear
    popf
;
    popad
    pop gs
    pop es
    ret
GetDriveParams  Endp

        
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
    mov cx,ds:ahci_dev_count
    or cx,cx
    jz ahci_thread_done
;    
    call ResetAhci
    call StartAhci
    call WaitPortDet
    call ClearPortSerr
    call ActivatePorts
    xor al,al
    call GetDriveParams
;    
    mov al,1
    call GetDriveParams
    int 3
    mov ax,SEG data
    mov ds,ax
    mov gs,ds:ahci_port_arr
    mov eax,gs:ap_sector_count
    mov ax,gs:ap_flags
    

ahci_thread_done:
    int 3    

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
    call InitPciAhci
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
