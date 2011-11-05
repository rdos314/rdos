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
MAX_NAME_SIZE       = 16

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

part_struc      STRUC

part_status             DB ?
part_start_head         DB ?
part_start_cyl_sector   DW ?
part_type               DB ?
part_end_head           DB ?
part_end_cyl_sector     DW ?
part_start_sector       DD ?
part_sectors            DD ?

part_struc      ENDS

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

as_slots        DW ?
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

ap_entries          DW ?
ap_notify_thread    DW ?

ap_flags            DW ?
ap_is               DD ?
ap_errors           DD ?

ap_spinlock         spinlock_typ <>
ap_slot_mask        DD ?
ap_reserved_mask    DD ?
ap_active_mask      DD ?

ap_sector_count     DD ?
ap_sectors_per_unit DW ?
ap_units            DW ?
ap_disc_sel         DW ?
ap_disc_nr          DB ?

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

acl_flags           DW ?
acl_prdtl           DW ?
acl_transfer_count  DD ?
acl_ctba            DD ?,?
acl_resv1           DD ?,?
acl_resv2           DW ?
acl_thread          DW ?
acl_total_count     DD ?

ahci_command_list_struc  ENDS


;
; device structure
;

ahci_device_struc   STRUC

ad_hba_sel          DW ?
ad_port_arr         DW 32 DUP(?)

ad_msi_address      DD ?
ad_msi_data         DW ?
ad_msi_ints         DW ?

ad_pci_bus          DB ?
ad_pci_device       DB ?
ad_pci_function     DB ?

ahci_device_struc   ENDS

data    SEGMENT byte public 'DATA'

ahci_dev_count      DW ?
ahci_dev_arr        DW MAX_AHCI_DEVICES DUP(?)
ahci_port_count     DW ?
ahci_port_arr       DW MAX_AHCI_PORTS DUP(?)

req_name_ptr        DW ?
req_name_str        DB MAX_NAME_SIZE DUP(?)

notify_name_ptr     DW ?
notify_name_str     DB MAX_NAME_SIZE DUP(?)

data    ENDS


IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

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
;       PARAMETERS:     DS      Device sel
;                       ES      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IrqPort  Proc near
    mov ds,es:ap_hba_sel
    mov eax,ds:hba_pxis
    mov ds:hba_pxis,eax
    or es:ap_is,eax
    test eax,HBA_PXI_FATAL OR HBA_PXI_INFO
    jz ipNotError
;
    mov ds,es:ap_cmd_sel
    xor si,si
    mov cx,32

ipSignalLoop:
    xor bx,bx
    xchg bx,ds:[si].acl_thread
    or bx,bx
    jz ipSignalNext
;    
    Signal

ipSignalNext:
    add si,20h
    loop ipSignalLoop
;
    mov ds,es:ap_hba_sel
    mov eax,ds:hba_pxserr
    mov ds:hba_pxserr,eax
    or es:ap_errors,eax
    jmp ipDone

ipNotError:    
    test eax,HBA_PXI_DP
    jz ipDone
;
    RequestSpinlock es:ap_spinlock
    mov edx,ds:hba_pxci
    mov eax,es:ap_active_mask
    xor eax,edx
    and eax,es:ap_active_mask
    ReleaseSpinlock es:ap_spinlock       
;
    and eax,es:ap_slot_mask
    jz ipDone
;
    mov ds,es:ap_cmd_sel
    xor si,si

ipSlotLoop:
    shr eax,1
    jnc ipSlotNext
;
    mov edx,ds:[si].acl_transfer_count
    cmp edx,ds:[si].acl_total_count
    jb ipSlotNext
;
    xor bx,bx
    xchg bx,ds:[si].acl_thread
    or bx,bx
    jz ipSlotNext
;    
    Signal

ipSlotNext:
    add si,20h
    or eax,eax
    jnz ipSlotLoop

ipDone:    
    ret
IrqPort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AhciInt
;
;       DESCRIPTION:    IRQ handler
;
;       PARAMETERS:     DS      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AhciInt  Proc far
    mov fs,ds:ad_hba_sel

aiRetry:    
    mov eax,fs:hba_is
    and eax,fs:hba_pi
    jz aiDone
;
    mov si,OFFSET ad_port_arr
    mov edx,1

aiHandlePort:    
    shr eax,1
    jnc aiHandleNext
;
    push ds
    push es
    push eax
    push edx
    push si
    mov es,ds:[si]
    call IrqPort    
    pop si
    pop edx
    pop eax
    pop es
    pop ds
    mov fs:hba_is,edx

aiHandleNext:
    or eax,eax
    jz aiRetry
;    
    shl edx,1
    add si,2
    jmp aiHandlePort        

aiDone:        
    retf32
AhciInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AhciPortInt
;
;       DESCRIPTION:    Port-based IRQ handler
;
;       PARAMETERS:     DS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AhciPortInt  Proc far
    mov es,ds:ap_hba_sel
    mov eax,es:hba_pxis
    mov es:hba_pxis,eax
    or ds:ap_is,eax
    test eax,HBA_PXI_FATAL OR HBA_PXI_INFO
    jz apiNotError
;
    mov es,ds:ap_cmd_sel
    xor si,si
    mov cx,32

apiSignalLoop:
    xor bx,bx
    xchg bx,es:[si].acl_thread
    or bx,bx
    jz apiSignalNext
;    
    Signal

apiSignalNext:
    add si,20h
    loop apiSignalLoop
;
    mov es,ds:ap_hba_sel
    mov eax,es:hba_pxserr
    mov es:hba_pxserr,eax
    or ds:ap_errors,eax
    jmp apiDone

apiNotError:    
    test eax,HBA_PXI_DP
    jz apiDone
;
    RequestSpinlock ds:ap_spinlock
    mov edx,es:hba_pxci
    mov eax,ds:ap_active_mask
    xor eax,edx
    and eax,ds:ap_active_mask
    ReleaseSpinlock ds:ap_spinlock       
;
    and eax,ds:ap_slot_mask
    jz apiDone
;
    mov es,ds:ap_cmd_sel
    xor si,si

apiSlotLoop:
    shr eax,1
    jnc apiSlotNext
;
    mov eax,es:[si].acl_transfer_count
    cmp eax,es:[si].acl_total_count
    jb apiSlotNext
;
    xor bx,bx
    xchg bx,es:[si].acl_thread
    or bx,bx
    jz apiSlotNext
;    
    Signal

apiSlotNext:
    add si,20h
    or eax,eax
    jnz apiSlotLoop

apiDone:    
    retf32
AhciPortInt Endp

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
    mov ds:ap_entries,ax
;
    mov cx,32
    sub cx,es:as_slots
    mov eax,0FFFFFFFFh
    shr eax,cl
    mov ds:ap_slot_mask,eax
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
    mov ds:ap_active_mask,0
    mov ds:ap_reserved_mask,0
    mov ds:ap_is,0
    mov ds:ap_errors,0
    InitSpinlock ds:ap_spinlock
;
    pop ax
    mov ds:ap_hba_sel,ax
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
;       PARAMETERS:     FS      HBA selector
;                       EDX     HBA linear
;                       BH      PCI Bus
;                       BL      PCI Device
;                       CH      PCI Function

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice   Proc near
    push es
    pushad
;
    or dword ptr fs:hba_bohc,2
    push ax
    mov eax,SIZE ahci_device_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:ad_hba_sel,fs
    mov es:ad_pci_bus,bh
    mov es:ad_pci_device,bl
    mov es:ad_pci_function,ch
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
    push bx
    AllocateGdt
    push cx
    mov ecx,100h
    CreateDataSelector16
    pop cx
    mov fs,bx
    pop bx
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
    ret
StartPort Endp

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
    mov bh,ds:ad_pci_bus
    mov bl,ds:ad_pci_device
    mov ch,ds:ad_pci_function
    mov al,5
    FindPciCapability
    jc siIrq
;
    mov cl,al
    add cl,2
    ReadPciWord
    or al,1
    WritePciWord
;    test al,1
;    jz siIrq
;    
    mov si,cx
    mov cl,al
    shr cl,1
    and cl,7
    mov dx,1
    shl dx,cl
    mov cx,dx
    cmp cx,1
    je siAllocOne

siAllocMany:
    AllocateMsiInts
    jc siAllocOne
;    
    mov ds:ad_msi_address,edx
    mov ds:ad_msi_data,ax
    mov ds:ad_msi_ints,cx
;
    mov cx,si
    ReadPciWord
    and al,8Fh
    mov dl,al
    and dl,0Eh
    shl dl,3
    or al,dl
    WritePciWord        
    jmp siAllocDone

siAllocOne:
    mov cx,1
    AllocateMsiInts
    jc siIrq
;    
    mov ds:ad_msi_address,edx
    mov ds:ad_msi_data,ax
    mov ds:ad_msi_ints,1
;
    mov cx,si
    ReadPciWord
    and al,8Fh
    WritePciWord        

siAllocDone:        
    test ax,100h
    jnz siMsiVector
;
    test ax,80h
    jnz siMsi64

siMsi32:
    add cl,2
    mov eax,ds:ad_msi_address
    WritePciDword
;
    add cl,4    
    mov ax,ds:ad_msi_data
    WritePciWord
    jmp siMsiHandlers

siMsi64:
    add cl,2
    mov eax,ds:ad_msi_address
    WritePciDword
;
    add cl,4
    xor eax,eax
    WritePciDword
;    
    add cl,4    
    mov ax,ds:ad_msi_data
    WritePciWord
    jmp siMsiHandlers

siMsiVector:
    add cl,2
    mov eax,ds:ad_msi_address
    WritePciDword
;
    add cl,4
    xor eax,eax
    WritePciDword
;    
    add cl,4    
    mov ax,ds:ad_msi_data
    WritePciWord

siMsiHandlers:
    mov cx,ds:ad_msi_ints
    cmp cx,1
    je siMsiSingle

siMsiMulti:
    mov si,OFFSET ad_port_arr
    mov ax,ds:ad_msi_data

siMultiLoop:
    mov dx,ds:[si]
    or dx,dx
    jz siMultiFree

siMultiSetup:
    push ds
    mov ds,dx
    mov di,cs
    mov es,di
    mov edi,OFFSET AhciPortInt
    RequestMsiHandler
    pop ds
    jmp siMultiNext

siMultiFree:
    FreeMsiInt

siMultiNext:
    inc ax    
    add si,2
    loop siMultiLoop
;
    jmp siOk
    
siMsiSingle:
    mov ax,ds:ad_msi_data
    mov di,cs
    mov es,di
    mov edi,OFFSET AhciInt
    RequestMsiHandler
    jmp siOk

siIrq:
    GetPciIrqNr
    mov al,14       ; fix before ACPI is ready
    mov di,cs
    mov es,di
    mov edi,OFFSET AhciInt
    RequestSharedIrqHandler

siOk:    
    ret
SetupInts Endp

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
;
    call SetupInts
    call StartDevice    
;    
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
;
    mov eax,es:hba_pxis
    mov es:hba_pxis,eax
;    
    mov eax,HBA_PXI_ENABLE
    mov es:hba_pxie,eax
    
cpsNext:
    add si,2
    loop cpsPort
;
    mov fs,ds:ad_hba_sel
;    
    mov eax,fs:hba_pi
    mov fs:hba_is,eax
;    
    or fs:hba_ghc,HBA_GHC_IE
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
    push esi
;
    xor al,al
    xor bx,bx
    mov esi,1
    mov es,gs:ap_hba_sel
;
    RequestSpinlock gs:ap_spinlock
    mov edx,gs:ap_reserved_mask
    not edx
    and edx,gs:ap_slot_mask
    jnz asLoop
;
    ReleaseSpinlock gs:ap_spinlock
    stc
    jmp asDone

asLoop:
    rcr edx,1
    jc asFound
;
    add bx,2
    inc al
    shl esi,1
    jmp asLoop

asFound:
    or gs:ap_reserved_mask,esi
    ReleaseSpinlock gs:ap_spinlock
;    
    mov ds,gs:ap_slot_sel
    mov bx,ds:[bx].as_index_arr
    clc

asDone:
    pop esi
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
    push ax
    push bx
    push ecx
;
    mov ds,gs:ap_cmd_sel
    movzx bx,al
    shl bx,5
    mov ds:[bx].acl_prdtl,cx
    mov ds:[bx].acl_flags,485h
    mov ds:[bx].acl_transfer_count,0
;
    movzx ecx,cx
    shl ecx,9
    mov ds:[bx].acl_total_count,ecx
;
    ClearSignal
    GetThread
    mov ds:[bx].acl_thread,ax        
;
    pop ecx
    pop bx    
    pop ax
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
    push ax
    push bx
    push ecx
;
    mov ds,gs:ap_cmd_sel
    movzx bx,al
    shl bx,5
    mov ds:[bx].acl_prdtl,cx
    mov ds:[bx].acl_flags,4C5h
    mov ds:[bx].acl_transfer_count,0
;
    movzx ecx,cx
    shl ecx,9
    mov ds:[bx].acl_total_count,ecx
;
    ClearSignal
    GetThread
    mov ds:[bx].acl_thread,ax        
;
    pop ecx
    pop bx    
    pop ax
    pop ds
    ret
SetupWriteCmd    Endp

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
;
    RequestSpinlock gs:ap_spinlock
    mov ds:hba_pxci,edx
    or gs:ap_active_mask,edx
    ReleaseSpinlock gs:ap_spinlock
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
    push ds
    push eax
    push cx
    push edx
    push si

wfcLoop:
    WaitForSignal
;
    mov ds,gs:ap_cmd_sel
    movzx si,al
    shl si,5
    mov edx,ds:[si].acl_transfer_count
    cmp edx,ds:[si].acl_total_count
    clc
    je wfcRel
;    
    mov dx,ds:[si].acl_thread
    or dx,dx
    jnz wfcLoop
;
    stc

wfcRel:    
    pushf
    mov cl,al
    mov edx,1
    shl edx,cl
    not edx
;
    RequestSpinlock gs:ap_spinlock
    and gs:ap_active_mask,edx
    and gs:ap_reserved_mask,edx
    ReleaseSpinlock gs:ap_spinlock
    popf
;
    pop si
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
;
    push ax
    xor edx,edx
    mov cx,1
    mov al,0ECh
    call SetupAta
    pop ax
;    
    xor edi,edi
    mov ecx,200h
    call AddPrdEntry
;
    mov cx,1
    call SetupReadCmd
    call StartCmd
    call WaitForCompletion
    jc gdpDone
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
;       NAME:           CalcParam
;
;       DESCRIPTION:    Calculate various parameters
;
;       PARAMETERS:     DS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcParam       Proc near
    pushad
;
    mov eax,1
    mov edx,ds:ap_sector_count

calc_param_norm_loop:
    shl eax,1
    shr edx,1
    cmp eax,edx
    jc calc_param_norm_loop
;
    cmp edx,10000h
    jc calc_param_in_range
;
    shr edx,1

calc_param_in_range:    
    mov esi,edx
    mov ebx,edx
    mov ecx,edx

calc_param_loop:
    xor edx,edx
    mov eax,ds:ap_sector_count
    div esi
    cmp ecx,edx
    jc calc_param_next
;       
    mov ecx,edx
    mov ebx,esi
    or edx,edx
    jz calc_param_ok

calc_param_next:
    inc esi
    cmp esi,eax
    jbe calc_param_loop
;
    xor edx,edx
    mov eax,ds:ap_sector_count
    div ebx

calc_param_ok:
    mov ds:ap_sectors_per_unit,bx
    mov ds:ap_units,ax
    mul bx
    push dx
    push ax
    pop ds:ap_sector_count
;
    popad
    ret
CalcParam       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadSector
;
;       DESCRIPTION:    Read a single sector
;
;       PARAMETERS:     GS      Port sel
;                       EDX     Sector
;                       EDI     4k-aligned linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector  Proc near
    push es
    pushad
;    
    mov esi,edi
    call AllocateSlot
;
    push ax
    mov al,25h
    test gs:ap_flags,PORT_FLAG_48_BIT
    jnz rsOpOk
;    
    mov al,0C8h

rsOpOk:
    mov cx,1
    call SetupAta
    pop ax
;    
    xor edi,edi
    mov ecx,200h
    call AddPrdEntry
;
    mov cx,1
    call SetupReadCmd
    call StartCmd
    call WaitForCompletion
;
    popad
    pop es
    ret
ReadSector  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallPartition
;
;       DESCRIPTION:    Install partition
;
;       PARAMETERS:     GS      Port sel
;                       ES      flat sel
;                       CL      Partition type
;                       EDX     Start sector
;                       EAX     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fs_unknown      DB 'UNKNOWN '
fs_fat12        DB 'FAT12   '
fs_fat16        DB 'FAT16   '
fs_fat32        DB 'FAT32   '
fs_hpfs         DB 'HPFS    '
fs_rdfs         DB 'RDFS    '
fs_flashfs      DB 'FLASHFS '

FsTab:
fs00    DW OFFSET fs_unknown
fs01    DW OFFSET fs_fat12
fs02    DW OFFSET fs_unknown
fs03    DW OFFSET fs_unknown
fs04    DW OFFSET fs_fat16
fs05    DW OFFSET fs_unknown
fs06    DW OFFSET fs_fat16
fs07    DW OFFSET fs_hpfs
fs08    DW OFFSET fs_unknown
fs09    DW OFFSET fs_unknown
fs0A    DW OFFSET fs_unknown
fs0B    DW OFFSET fs_fat32
fs0C    DW OFFSET fs_fat32
fs0D    DW OFFSET fs_unknown
fs0E    DW OFFSET fs_unknown
fs0F    DW OFFSET fs_unknown
fs10    DW OFFSET fs_unknown
fs11    DW OFFSET fs_unknown
fs12    DW OFFSET fs_unknown
fs13    DW OFFSET fs_unknown
fs14    DW OFFSET fs_unknown
fs15    DW OFFSET fs_unknown
fs16    DW OFFSET fs_unknown
fs17    DW OFFSET fs_unknown
fs18    DW OFFSET fs_unknown
fs19    DW OFFSET fs_unknown
fs1A    DW OFFSET fs_unknown
fs1B    DW OFFSET fs_unknown
fs1C    DW OFFSET fs_unknown
fs1D    DW OFFSET fs_unknown
fs1E    DW OFFSET fs_unknown
fs1F    DW OFFSET fs_unknown
fs20    DW OFFSET fs_unknown
fs21    DW OFFSET fs_unknown
fs22    DW OFFSET fs_unknown
fs23    DW OFFSET fs_unknown
fs24    DW OFFSET fs_unknown
fs25    DW OFFSET fs_unknown
fs26    DW OFFSET fs_unknown
fs27    DW OFFSET fs_unknown
fs28    DW OFFSET fs_unknown
fs29    DW OFFSET fs_unknown
fs2A    DW OFFSET fs_unknown
fs2B    DW OFFSET fs_unknown
fs2C    DW OFFSET fs_unknown
fs2D    DW OFFSET fs_unknown
fs2E    DW OFFSET fs_unknown
fs2F    DW OFFSET fs_unknown
fs30    DW OFFSET fs_unknown
fs31    DW OFFSET fs_unknown
fs32    DW OFFSET fs_unknown
fs33    DW OFFSET fs_unknown
fs34    DW OFFSET fs_unknown
fs35    DW OFFSET fs_unknown
fs36    DW OFFSET fs_unknown
fs37    DW OFFSET fs_unknown
fs38    DW OFFSET fs_unknown
fs39    DW OFFSET fs_unknown
fs3A    DW OFFSET fs_unknown
fs3B    DW OFFSET fs_unknown
fs3C    DW OFFSET fs_unknown
fs3D    DW OFFSET fs_unknown
fs3E    DW OFFSET fs_unknown
fs3F    DW OFFSET fs_unknown
fs40    DW OFFSET fs_unknown
fs41    DW OFFSET fs_unknown
fs42    DW OFFSET fs_unknown
fs43    DW OFFSET fs_unknown
fs44    DW OFFSET fs_unknown
fs45    DW OFFSET fs_unknown
fs46    DW OFFSET fs_unknown
fs47    DW OFFSET fs_unknown
fs48    DW OFFSET fs_unknown
fs49    DW OFFSET fs_unknown
fs4A    DW OFFSET fs_unknown
fs4B    DW OFFSET fs_unknown
fs4C    DW OFFSET fs_unknown
fs4D    DW OFFSET fs_unknown
fs4E    DW OFFSET fs_unknown
fs4F    DW OFFSET fs_unknown
fs50    DW OFFSET fs_unknown
fs51    DW OFFSET fs_unknown
fs52    DW OFFSET fs_unknown
fs53    DW OFFSET fs_unknown
fs54    DW OFFSET fs_unknown
fs55    DW OFFSET fs_unknown
fs56    DW OFFSET fs_unknown
fs57    DW OFFSET fs_unknown
fs58    DW OFFSET fs_unknown
fs59    DW OFFSET fs_unknown
fs5A    DW OFFSET fs_unknown
fs5B    DW OFFSET fs_unknown
fs5C    DW OFFSET fs_unknown
fs5D    DW OFFSET fs_unknown
fs5E    DW OFFSET fs_unknown
fs5F    DW OFFSET fs_unknown
fs60    DW OFFSET fs_unknown
fs61    DW OFFSET fs_unknown
fs62    DW OFFSET fs_unknown
fs63    DW OFFSET fs_unknown
fs64    DW OFFSET fs_unknown
fs65    DW OFFSET fs_unknown
fs66    DW OFFSET fs_unknown
fs67    DW OFFSET fs_unknown
fs68    DW OFFSET fs_unknown
fs69    DW OFFSET fs_unknown
fs6A    DW OFFSET fs_unknown
fs6B    DW OFFSET fs_unknown
fs6C    DW OFFSET fs_unknown
fs6D    DW OFFSET fs_unknown
fs6E    DW OFFSET fs_unknown
fs6F    DW OFFSET fs_unknown
fs70    DW OFFSET fs_unknown
fs71    DW OFFSET fs_unknown
fs72    DW OFFSET fs_unknown
fs73    DW OFFSET fs_unknown
fs74    DW OFFSET fs_unknown
fs75    DW OFFSET fs_unknown
fs76    DW OFFSET fs_unknown
fs77    DW OFFSET fs_unknown
fs78    DW OFFSET fs_unknown
fs79    DW OFFSET fs_unknown
fs7A    DW OFFSET fs_unknown
fs7B    DW OFFSET fs_unknown
fs7C    DW OFFSET fs_unknown
fs7D    DW OFFSET fs_unknown
fs7E    DW OFFSET fs_unknown
fs7F    DW OFFSET fs_unknown
fs80    DW OFFSET fs_unknown
fs81    DW OFFSET fs_unknown
fs82    DW OFFSET fs_unknown
fs83    DW OFFSET fs_unknown
fs84    DW OFFSET fs_unknown
fs85    DW OFFSET fs_unknown
fs86    DW OFFSET fs_unknown
fs87    DW OFFSET fs_unknown
fs88    DW OFFSET fs_unknown
fs89    DW OFFSET fs_unknown
fs8A    DW OFFSET fs_unknown
fs8B    DW OFFSET fs_unknown
fs8C    DW OFFSET fs_unknown
fs8D    DW OFFSET fs_unknown
fs8E    DW OFFSET fs_unknown
fs8F    DW OFFSET fs_unknown
fs90    DW OFFSET fs_unknown
fs91    DW OFFSET fs_unknown
fs92    DW OFFSET fs_unknown
fs93    DW OFFSET fs_unknown
fs94    DW OFFSET fs_unknown
fs95    DW OFFSET fs_unknown
fs96    DW OFFSET fs_unknown
fs97    DW OFFSET fs_unknown
fs98    DW OFFSET fs_unknown
fs99    DW OFFSET fs_unknown
fs9A    DW OFFSET fs_unknown
fs9B    DW OFFSET fs_unknown
fs9C    DW OFFSET fs_unknown
fs9D    DW OFFSET fs_unknown
fs9E    DW OFFSET fs_unknown
fs9F    DW OFFSET fs_unknown
fsA0    DW OFFSET fs_unknown
fsA1    DW OFFSET fs_unknown
fsA2    DW OFFSET fs_unknown
fsA3    DW OFFSET fs_unknown
fsA4    DW OFFSET fs_unknown
fsA5    DW OFFSET fs_unknown
fsA6    DW OFFSET fs_unknown
fsA7    DW OFFSET fs_unknown
fsA8    DW OFFSET fs_unknown
fsA9    DW OFFSET fs_unknown
fsAA    DW OFFSET fs_unknown
fsAB    DW OFFSET fs_unknown
fsAC    DW OFFSET fs_unknown
fsAD    DW OFFSET fs_unknown
fsAE    DW OFFSET fs_rdfs
fsAF    DW OFFSET fs_flashfs
fsB0    DW OFFSET fs_unknown
fsB1    DW OFFSET fs_unknown
fsB2    DW OFFSET fs_unknown
fsB3    DW OFFSET fs_unknown
fsB4    DW OFFSET fs_unknown
fsB5    DW OFFSET fs_unknown
fsB6    DW OFFSET fs_unknown
fsB7    DW OFFSET fs_unknown
fsB8    DW OFFSET fs_unknown
fsB9    DW OFFSET fs_unknown
fsBA    DW OFFSET fs_unknown
fsBB    DW OFFSET fs_unknown
fsBC    DW OFFSET fs_unknown
fsBD    DW OFFSET fs_unknown
fsBE    DW OFFSET fs_unknown
fsBF    DW OFFSET fs_unknown
fsC0    DW OFFSET fs_unknown
fsC1    DW OFFSET fs_unknown
fsC2    DW OFFSET fs_unknown
fsC3    DW OFFSET fs_unknown
fsC4    DW OFFSET fs_unknown
fsC5    DW OFFSET fs_unknown
fsC6    DW OFFSET fs_unknown
fsC7    DW OFFSET fs_unknown
fsC8    DW OFFSET fs_unknown
fsC9    DW OFFSET fs_unknown
fsCA    DW OFFSET fs_unknown
fsCB    DW OFFSET fs_unknown
fsCC    DW OFFSET fs_unknown
fsCD    DW OFFSET fs_unknown
fsCE    DW OFFSET fs_unknown
fsCF    DW OFFSET fs_unknown
fsD0    DW OFFSET fs_unknown
fsD1    DW OFFSET fs_unknown
fsD2    DW OFFSET fs_unknown
fsD3    DW OFFSET fs_unknown
fsD4    DW OFFSET fs_unknown
fsD5    DW OFFSET fs_unknown
fsD6    DW OFFSET fs_unknown
fsD7    DW OFFSET fs_unknown
fsD8    DW OFFSET fs_unknown
fsD9    DW OFFSET fs_unknown
fsDA    DW OFFSET fs_unknown
fsDB    DW OFFSET fs_unknown
fsDC    DW OFFSET fs_unknown
fsDD    DW OFFSET fs_unknown
fsDE    DW OFFSET fs_unknown
fsDF    DW OFFSET fs_unknown
fsE0    DW OFFSET fs_unknown
fsE1    DW OFFSET fs_unknown
fsE2    DW OFFSET fs_unknown
fsE3    DW OFFSET fs_unknown
fsE4    DW OFFSET fs_unknown
fsE5    DW OFFSET fs_unknown
fsE6    DW OFFSET fs_unknown
fsE7    DW OFFSET fs_unknown
fsE8    DW OFFSET fs_unknown
fsE9    DW OFFSET fs_unknown
fsEA    DW OFFSET fs_unknown
fsEB    DW OFFSET fs_unknown
fsEC    DW OFFSET fs_unknown
fsED    DW OFFSET fs_unknown
fsEE    DW OFFSET fs_unknown
fsEF    DW OFFSET fs_unknown
fsF0    DW OFFSET fs_unknown
fsF1    DW OFFSET fs_unknown
fsF2    DW OFFSET fs_unknown
fsF3    DW OFFSET fs_unknown
fsF4    DW OFFSET fs_unknown
fsF5    DW OFFSET fs_unknown
fsF6    DW OFFSET fs_unknown
fsF7    DW OFFSET fs_unknown
fsF8    DW OFFSET fs_unknown
fsF9    DW OFFSET fs_unknown
fsFA    DW OFFSET fs_unknown
fsFB    DW OFFSET fs_unknown
fsFC    DW OFFSET fs_unknown
fsFD    DW OFFSET fs_unknown
fsFE    DW OFFSET fs_unknown
fsFF    DW OFFSET fs_unknown

InstallPartition    Proc near
    push es
    pushad
;
    mov di,cs
    mov es,di
    movzx di,cl
    shl di,1

install_part_test_avail:
    mov ecx,eax
    mov di,word ptr cs:[di].FsTab
    movzx edi,di
    IsFileSystemAvailable
    jc install_part_done
;
    AllocateStaticDrive
    mov ah,gs:ap_disc_nr
    OpenDrive
;
    InstallFileSystem
    clc

install_part_done:
    popad
    pop es
    ret
InstallPartition    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Perform_one
;
;       DESCRIPTION:    Perform one request
;
;       PARAMETERS:     GS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one     Proc near

perform_one_loop:
    mov bx,gs:ap_disc_sel
    movzx ecx,gs:ap_entries
    GetDiscRequestArray
    jc perform_one_done
;
    mov edi,es:[esi]
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je perform_one_read
;
    cmp al,STATE_DIRTY
    je perform_one_write
;
    cmp al,STATE_SEQ
    jne perform_one_done

perform_one_write:
    int 3
    jmp perform_one_loop

perform_one_read:
    call AllocateSlot
    jnc perform_read_has_slot
;
    mov ax,10
    WaitMilliSec
    jmp perform_one_read

perform_read_has_slot:
    push ax
    mov al,25h
    test gs:ap_flags,PORT_FLAG_48_BIT
    jnz perform_read_op_ok
;    
    mov al,0C8h

perform_read_op_ok:
    push ax
    movzx edx,es:[edi].dh_unit
    movzx eax,gs:ap_sectors_per_unit
    mul edx
    movzx edx,es:[edi].dh_sector
    add edx,eax
    pop ax
    call SetupAta
;
    pop ax
    push cx

perform_read_queue_loop:
    mov edi,es:[esi]
    push ecx
    push esi
    mov esi,es:[edi].dh_data
    mov ecx,200h
    call AddPrdEntry
    pop esi
    pop ecx
    add esi,4
    loop perform_read_queue_loop
;
    pop cx
;
    push ds    
    mov ds,gs:ap_cmd_sel
    movzx bx,al
    shl bx,5
    mov ds:[bx].acl_prdtl,cx
    mov ds:[bx].acl_flags,485h
    mov ds:[bx].acl_transfer_count,0
;
    movzx ecx,cx
    shl ecx,9
    mov ds:[bx].acl_total_count,ecx
;
    mov cx,gs:ap_notify_thread
    mov ds:[bx].acl_thread,cx        
    pop ds
;
    call StartCmd
    jmp perform_one_loop

perform_one_done:
    ret
perform_one     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           req_discbuf_thread
;
;       DESCRIPTION:    Thread to handle disc buffer queue
;
;       PARAMETERS:     FS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_discbuf_thread:
    mov ax,flat_sel
    mov es,ax
    mov ax,fs
    mov gs,ax
    mov bx,gs:ap_disc_sel

req_discbuf_loop:
    WaitForDiscRequest
    call perform_one
    jmp req_discbuf_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           notify_discbuf_thread
;
;       DESCRIPTION:    Thread to handle completed requests
;
;       PARAMETERS:     FS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

notify_discbuf_thread:
    mov ax,flat_sel
    mov es,ax
    mov ax,fs
    mov gs,ax
;
    GetThread
    mov gs:ap_notify_thread,ax

notify_discbuf_loop:
    WaitForSignal
    int 3
    jmp notify_discbuf_loop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           start_disc
;
;       DESCRIPTION:    Thread to StartDisc (temporary)
;
;       PARAMETERS:     FS      Port sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_thread_name   DB 'Start Disc', 0

start_thread:
    int 3
    mov ax,fs
    mov gs,ax
    mov bx,gs:ap_disc_sel
    StartDisc
    int 3
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           install_disc_unit
;
;       DESCRIPTION:    Install a disc
;
;       PARAMETERS:     AL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

install_disc_unit Proc near
    push ds
    push es
    pushad
;   
    call GetDriveParams
    jc idDone
;     
    mov dx,SEG data
    mov ds,dx
    movzx bx,al
    add bx,bx
    add bx,OFFSET ahci_port_arr
    mov bx,ds:[bx]
    mov ds,bx
;
    mov ecx,10000h
    InstallDisc
    mov ds:ap_disc_sel,bx
    mov ds:ap_disc_nr,al
;
    call CalcParam
    mov ax,ds:ap_sectors_per_unit
    mov dx,ds:ap_units
    mov cx,512
    mov si,-1
    mov di,-1
    mov bx,ds:ap_disc_sel
    SetDiscParam
;
    mov ax,ds
    mov fs,ax
    mov ax,cs
    mov ds,ax
    mov ax,SEG data    
    mov es,ax
    mov edi,OFFSET req_name_str
    mov esi,OFFSET req_discbuf_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    mov edi,OFFSET notify_name_str
    mov esi,OFFSET notify_discbuf_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET start_thread_name
    mov esi,OFFSET start_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread

idDone:
    popad
    pop es
    pop ds        
    ret
install_disc_unit   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Disc assign
;
;       DESCRIPTION:    Assign discs for AHCI
;
;       PARAMETERS:     
;
;       RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

req_disc_thread_name   DB 'Ahci Req ',0
notify_disc_thread_name   DB 'Ahci Notify ',0

disc_assign Proc far
    call ResetAhci
    call StartAhci
    call WaitPortDet
    call ClearPortSerr
    call ActivatePorts
;    
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov cx,ds:ahci_port_count
    or cx,cx
    jz disc_assign_done
;
    mov di,OFFSET req_name_str
    mov si,OFFSET req_disc_thread_name

req_disc_assign_name_loop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz req_disc_assign_name_loop
;
    dec di
    mov ds:req_name_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb
;
    mov di,OFFSET notify_name_str
    mov si,OFFSET notify_disc_thread_name

notify_disc_assign_name_loop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz notify_disc_assign_name_loop
;
    dec di
    mov ds:notify_name_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb
;
    xor al,al

disc_assign_loop:
    mov ah,al
    add ah,'0'
    mov bx,ds:req_name_ptr
    mov ds:[bx],ah
    mov bx,ds:notify_name_ptr
    mov ds:[bx],ah
;    
    call install_disc_unit
    inc al
    loop disc_assign_loop

disc_assign_done:    
    retf32
disc_assign Endp  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           drive_assigne1
;
;       DESCRIPTION:    Drive assign, pass 1
;
;       PARAMETERS:     BX      Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign1   Proc far
    mov gs,bx
;    
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov byte ptr es:[edi],0
;    
    xor edx,edx
    call ReadSector
;
    mov esi,1BEh

drive_assign_loop1:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz drive_assign_free1
;
    mov eax,es:[esi+edi].part_sectors
    mov edx,es:[esi+edi].part_start_sector
    call InstallPartition

drive_assign_next_part1:
    add si,10h
    cmp si,1FEh
    jne drive_assign_loop1

drive_assign_free1:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
    retf32
drive_assign1   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallExtended
;
;       DESCRIPTION:    Install extended partion on drive
;
;       PARAMETERS:     ES      Flat sel
;                       GS      Port sel
;                       EDX     Current sector
;                       EDI     Buffer with partition sector
;                       ESI     Partition offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallExtended Proc near
    mov ebp,edx
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov byte ptr es:[edi],0
;
    mov edx,ebp
    call ReadSector
    jc install_ext_done
;
    mov esi,1BEh

install_ext_loop1:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz install_ext_next_part1
;
    cmp cl,5
    je install_ext_next_part1
;
    cmp cl,0Fh
    je install_ext_next_part1
;
    push ebp
    push edi
;
    mov eax,es:[esi+edi].part_sectors
    mov edx,es:[esi+edi].part_start_sector
    add edx,ebp

install_ext_do:
    call InstallPartition
    pop edi
    pop ebp

install_ext_next_part1:
    add si,10h
    cmp si,1FEh
    jne install_ext_loop1
;
    mov esi,1BEh

install_ext_loop2:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz install_ext_next_part2
;
    cmp cl,5
    je install_ext_install2
;
    cmp cl,0Fh
    jne install_ext_next_part2

install_ext_install2:
    push esi
    push edi
    push ebp
;
    mov edx,es:[esi+edi].part_start_sector
    add edx,ebp

install_ext_link:
    call InstallExtended
;
    pop ebp
    pop edi
    pop esi

install_ext_next_part2:
    add si,10h
    cmp si,1FEh
    jne install_ext_loop2

install_ext_done:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
    ret
InstallExtended Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           drive_assign2
;
;       DESCRIPTION:    Assign disc drives, pass 2
;
;       PARAMETERS:     BX      Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

drive_assign2   Proc far
    mov gs,bx
;    
    mov ax,flat_sel
    mov es,ax
;
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov byte ptr es:[edi],0
;    
    xor edx,edx
    call ReadSector
;
    mov esi,1BEh

drive_assign_loop2:
    mov cl,es:[esi+edi].part_type
    or cl,cl
    jz drive_assign_next_part2
;
    cmp cl,5
    je drive_assign_install2
;
    cmp cl,0Fh
    jne drive_assign_next_part2

drive_assign_install2:
    push esi
    push edi
;
    mov edx,es:[esi+edi].part_start_sector

drive_assign_ext:
    call InstallExtended
;
    pop edi
    pop esi

drive_assign_next_part2:
    add si,10h
    cmp si,1FEh
    jne drive_assign_loop2
;
    mov ecx,1000h
    mov edx,edi
    FreeLinear
    retf32
drive_assign2   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           demand_mount
;
;       DESCRIPTION:    Mount disc drive on demand
;
;       PARAMETERS:     BX      Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

demand_mount    Proc far
    retf32
demand_mount    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           erase
;
;       DESCRIPTION:    Erase sectors
;
;       PARAMETERS:     BX      Disc handle
;                       EDX     Start sector
;                       ECX     Number of sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

erase   Proc far
    stc
    retf32
erase   Endp

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

disc_ctrl:
dct00  DD OFFSET disc_assign,      SEG code
dct01  DD OFFSET drive_assign1,    SEG code
dct02  DD OFFSET drive_assign2,    SEG code
dct03  DD OFFSET demand_mount,     SEG code
dct04  DD OFFSET erase,            SEG code


init_ahci    Proc far
    push ds
    push es
    pusha
;    
    call InitPciAhci
;
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:ahci_dev_count
    or cx,cx
    jz iaDone
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET disc_ctrl
    HookInitDisc
;
;    mov edi,OFFSET ahci_thread_name
;    mov esi,OFFSET ahci_thread
;    mov ax,2
;    mov cx,stack0_size
;    CreateThread
    
iaDone:
    EndDiscHandler
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
    BeginDiscHandler
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
