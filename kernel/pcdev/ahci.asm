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
ATA_FPDMA_READ          = 60h
ATA_FPDMA_WRITE         = 61h

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

gpt_part_struc  STRUC

gpt_sign                DB 8 DUP(?)
gpt_rev                 DB 4 DUP(?)
gpt_header_size         DD ?
gpt_crc32               DD ?
gpt_resv                DD ?
gpt_curr_lba            DD ?,?
gpt_other_lba           DD ?,?
gpt_first_lba           DD ?,?
gpt_last_lba            DD ?,?
gpt_guid                DB 16 DUP(?)
gpt_entry_lba           DD ?,?
gpt_entry_count         DD ?
gpt_entry_size          DD ?
gpt_entry_crc32         DD ?

gpt_part_struc  ENDS

gpt_entry_struc STRUC

gpe_part_guid           DB 16 DUP(?)
gpe_unique_guid         DB 16 DUP(?)
gpe_first_lba           DD ?,?
gpe_last_lba            DD ?,?
gpe_attrib              DD ?,?
gpe_name                DB 36 DUP(?)

gpt_entry_struc ENDS

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
PORT_FLAG_ATAPI     =   4h
PORT_FLAG_TIMER     =   8h


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
ap_restart_count    DW ?

ap_spinlock         spinlock_typ <>
ap_slot_mask        DD ?
ap_reserved_mask    DD ?
ap_active_mask      DD ?

ap_sector_count     DD ?
ap_sectors_per_unit DW ?
ap_units            DW ?
ap_disc_sel         DW ?
ap_disc_nr          DB ?

ap_cap              DD ?
ap_sata_cap         DW ?

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

ad_msi              DB ?
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

fs_name             DB 10 DUP(?)

has_efi             DB ?
has_disc            DB ?

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
    mov bx,es:ap_notify_thread
    Signal
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
    mov bx,es:ap_notify_thread
    Signal
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
    mov bx,ds:ap_notify_thread
    Signal
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
    mov bx,ds:ap_notify_thread
    Signal
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
    mov edx,es:[si].acl_transfer_count
    cmp edx,es:[si].acl_total_count
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
    push ebx
;
    AllocateMultiplePhysical32
    mov al,67h
    push eax
    mov eax,ecx
    shl eax,12
    AllocateBigLinear
    pop eax
;
    push ecx

apPhysLoop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop apPhysLoop
;
    pop ecx
;
    pop ebx
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
    mov ds:ap_restart_count,0
    InitSpinlock ds:ap_spinlock
;
    mov eax,fs:hba_cap
    mov ds:ap_cap,eax
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
    push ebx
    xor ebx,ebx
    or al,67h
    SetPageEntry
    pop ebx
;
    push ebx
    xor ebx,ebx
    add eax,1000h
    add edx,1000h
    SetPageEntry
    sub edx,1000h
    pop ebx
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
    jnz ipaAdd
;
    push ax
    mov ax,ide_code_sel
    verr ax
    pop ax    
    jz ipaNext
;    
    mov fs:hba_ghc,HBA_GHC_AE
    
ipaAdd:
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
;           NAME:           StartDevice
;
;           DESCRIPTION:    Start device
;
;           PARAMETERS:     DS     Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDevice Proc near
    movzx dx,ds:ad_msi
    mov fs,ds:ad_hba_sel
;
    mov cx,32
    mov si,OFFSET ad_port_arr

sdLoop:
    mov ax,ds:[si]
    or ax,ax
    jz sdNext
;    
    push cx
    push dx
    push si
;
    mov es,ax
    or dx,dx
    jnz sdStart
;
    or es:ap_flags,PORT_FLAG_TIMER

sdStart:    
    call StartPort
;
    pop si
    pop dx
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
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup device ints
;
;           PARAMETERS:     DS     Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts Proc near
    mov ds:ad_msi,0
    mov bh,ds:ad_pci_bus
    mov bl,ds:ad_pci_device
    mov ch,ds:ad_pci_function
    GetPciMsi
    jc siIrq
;
    cmp dl,1
    je siAllocOne

siAllocMany:
    push cx
    movzx cx,dl
    mov al,14h
    AllocateInts
    pop cx
    jnc siMsiHandlers

siAllocOne:
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc siIrq    

siMsiHandlers:
    mov ds:ad_msi,1
    SetupPciMsi
;
    movzx cx,dl
    cmp cx,1
    je siMsiSingle

siMsiMulti:
    mov si,OFFSET ad_port_arr

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
    FreeInt

siMultiNext:
    inc al
    add si,2
    loop siMultiLoop
;
    jmp siOk
    
siMsiSingle:
    mov di,cs
    mov es,di
    mov edi,OFFSET AhciInt
    RequestMsiHandler
    jmp siOk

siIrq:
    GetPciIrqNr
    mov ah,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET AhciInt
    RequestIrqHandler

siOk:    
    ret
SetupInts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearSerr
;
;           DESCRIPTION:    Clear SERR
;
;           PARAMETERS:     DS     Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearSerr Proc near
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
    ret
ClearSerr Endp

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
    or fs:hba_ghc,HBA_GHC_AE
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
    call ClearSerr
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
    mov dx,100

wpdRetry:    
    mov ax,SEG data
    mov ds,ax
;    
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
    mov fs,es:ap_hba_sel
    mov eax,fs:hba_pxssts
    and al,0Fh
    cmp al,3
    jne wpdWait
;
    mov fs,es:ap_fis_sel
    mov di,OFFSET ap_rfis
    mov al,fs:[di].fdth_type
    cmp al,FIS_TYPE_DTH
    jne wpdWait
;
    mov al,fs:[di].fdth_error
    cmp al,1
    jnz wpdNext
;
    mov eax,dword ptr fs:[di].fdth_lbal
    and eax,0FFFFFFh
    cmp eax,0EB1401h
    jne wpdNext
;        
    or es:ap_flags,PORT_FLAG_ATAPI
    
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
;
    sub dx,1    
    jnz wpdRetry

wpdDone:
    ret
WaitPortDet Endp

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
    mov dl,40h
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
;       NAME:           SetupCnq
;
;       DESCRIPTION:    Setup CNQ
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

SetupCnq    Proc near
    push edx
;
    mov ds:[bx].fhtd_type,FIS_TYPE_HTD
    mov ds:[bx].fhtd_port_flags,80h
    mov ds:[bx].fhtd_command,al
    mov dword ptr ds:[bx].fhtd_lbal,edx
    mov dl,40h
    xchg dl,ds:[bx].fhtd_device
    movzx edx,dl
    mov dword ptr ds:[bx].fhtd_lbah,edx
    mov ds:[bx].fhtd_count,cx
    add bx,act_prd
;
    pop edx    
    ret
SetupCnq    Endp
        
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
    push ebp
;
    mov edx,esi
    and dx,0F000h        
    push ebx
    GetPageEntry
    mov ebp,ebx
    pop ebx
;    
    or ebp,ebp
    jz aprdDo
;
    test gs:ap_cap,HBA_CAP_S64A
    jnz aprdDo
;
    int 3    
    

aprdDo:
    and ax,0F000h
    and esi,0FFFh
    add esi,eax
    mov ds:[bx].ape_base,esi
    mov ds:[bx+4].ape_base,ebp
    mov ds:[bx].ape_handle,edi
;
    mov eax,ecx
    dec eax
    or eax,80000000h    
    mov ds:[bx].ape_byte_count,eax
    add bx,10h
;
    pop ebp
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
    mov ds:[bx].acl_flags,85h
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
    mov ds:[bx].acl_flags,0C5h
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
    push eax
    push edx
    GetSystemTime
    add eax,119300
    adc edx,0
    WaitForSignalWithTimeout
    pop edx
    pop eax
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
;   NAME:           CondWaitForCompletion
;
;   DESCRIPTION:    Conditional wait for completion
;
;   PARAMETERS:     GS      Port sel
;                   AL      Slot #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondWaitForCompletion Proc near
    push ds
    push eax
    push cx
    push edx
    push si
;
    push eax
    push edx
    GetSystemTime
    add eax,119300
    adc edx,0
    WaitForSignalWithTimeout
    pop edx
    pop eax
;
    mov ds,gs:ap_cmd_sel
    movzx si,al
    shl si,5
    mov edx,ds:[si].acl_transfer_count
    cmp edx,ds:[si].acl_total_count
    clc
    je cwfcRel
;
    stc

cwfcRel:    
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
CondWaitForCompletion    Endp

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
    push ebx
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    pop ebx
    mov esi,edx
;    
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:[bx]
    or ax,ax
    stc
    jz gdpDone
;    
    mov gs,ax
    test gs:ap_flags,PORT_FLAG_ATAPI
    stc
    jnz gdpDone
;    
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
    call CondWaitForCompletion
    jc gdpDone
;    
    mov ax,es:[esi+152]
    test gs:ap_cap,HBA_CAP_SNCQ
    jnz gdpSataCapOk
;
    and ax,0FFh    

gdpSataCapOk:    
    mov gs:ap_sata_cap,ax
    or gs:ap_flags,PORT_FLAG_ATA
;
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
;    
    test gs:ap_flags,PORT_FLAG_48_BIT
    jz rsOpOld
;
    test gs:ap_sata_cap,100h
;    jz rsOpDma
    jmp rsOpDma

rsOpCnq:
    mov al,ATA_FPDMA_READ    
    mov cx,1
    call SetupCnq
    jmp rsSetupOk

rsOpOld:    
    mov al,0C8h
    jmp rsOpOk

rsOpDma:    
    mov al,ATA_DMA_READ

rsOpOk:
    mov cx,1
    call SetupAta

rsSetupOk:    
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
;       NAME:       CalcCrc32
;
;       DESCRIPTION:    Calc CRC32
;
;       PARAMETERS:     ES:EDI  Buffer
;                       ECX     Size
;
;       RETURNS:        EAX     CRC32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crc32_tab: 
  DD 000000000h, 077073096h, 0ee0e612ch, 0990951bah, 0076dc419h, 0706af48fh
  DD 0e963a535h, 09e6495a3h, 00edb8832h, 079dcb8a4h, 0e0d5e91eh, 097d2d988h
  DD 009b64c2bh, 07eb17cbdh, 0e7b82d07h, 090bf1d91h, 01db71064h, 06ab020f2h
  DD 0f3b97148h, 084be41deh, 01adad47dh, 06ddde4ebh, 0f4d4b551h, 083d385c7h
  DD 0136c9856h, 0646ba8c0h, 0fd62f97ah, 08a65c9ech, 014015c4fh, 063066cd9h
  DD 0fa0f3d63h, 08d080df5h, 03b6e20c8h, 04c69105eh, 0d56041e4h, 0a2677172h
  DD 03c03e4d1h, 04b04d447h, 0d20d85fdh, 0a50ab56bh, 035b5a8fah, 042b2986ch
  DD 0dbbbc9d6h, 0acbcf940h, 032d86ce3h, 045df5c75h, 0dcd60dcfh, 0abd13d59h
  DD 026d930ach, 051de003ah, 0c8d75180h, 0bfd06116h, 021b4f4b5h, 056b3c423h
  DD 0cfba9599h, 0b8bda50fh, 02802b89eh, 05f058808h, 0c60cd9b2h, 0b10be924h
  DD 02f6f7c87h, 058684c11h, 0c1611dabh, 0b6662d3dh, 076dc4190h, 001db7106h
  DD 098d220bch, 0efd5102ah, 071b18589h, 006b6b51fh, 09fbfe4a5h, 0e8b8d433h
  DD 07807c9a2h, 00f00f934h, 09609a88eh, 0e10e9818h, 07f6a0dbbh, 0086d3d2dh
  DD 091646c97h, 0e6635c01h, 06b6b51f4h, 01c6c6162h, 0856530d8h, 0f262004eh
  DD 06c0695edh, 01b01a57bh, 08208f4c1h, 0f50fc457h, 065b0d9c6h, 012b7e950h
  DD 08bbeb8eah, 0fcb9887ch, 062dd1ddfh, 015da2d49h, 08cd37cf3h, 0fbd44c65h
  DD 04db26158h, 03ab551ceh, 0a3bc0074h, 0d4bb30e2h, 04adfa541h, 03dd895d7h
  DD 0a4d1c46dh, 0d3d6f4fbh, 04369e96ah, 0346ed9fch, 0ad678846h, 0da60b8d0h
  DD 044042d73h, 033031de5h, 0aa0a4c5fh, 0dd0d7cc9h, 05005713ch, 0270241aah
  DD 0be0b1010h, 0c90c2086h, 05768b525h, 0206f85b3h, 0b966d409h, 0ce61e49fh
  DD 05edef90eh, 029d9c998h, 0b0d09822h, 0c7d7a8b4h, 059b33d17h, 02eb40d81h
  DD 0b7bd5c3bh, 0c0ba6cadh, 0edb88320h, 09abfb3b6h, 003b6e20ch, 074b1d29ah
  DD 0ead54739h, 09dd277afh, 004db2615h, 073dc1683h, 0e3630b12h, 094643b84h
  DD 00d6d6a3eh, 07a6a5aa8h, 0e40ecf0bh, 09309ff9dh, 00a00ae27h, 07d079eb1h
  DD 0f00f9344h, 08708a3d2h, 01e01f268h, 06906c2feh, 0f762575dh, 0806567cbh
  DD 0196c3671h, 06e6b06e7h, 0fed41b76h, 089d32be0h, 010da7a5ah, 067dd4acch
  DD 0f9b9df6fh, 08ebeeff9h, 017b7be43h, 060b08ed5h, 0d6d6a3e8h, 0a1d1937eh
  DD 038d8c2c4h, 04fdff252h, 0d1bb67f1h, 0a6bc5767h, 03fb506ddh, 048b2364bh
  DD 0d80d2bdah, 0af0a1b4ch, 036034af6h, 041047a60h, 0df60efc3h, 0a867df55h
  DD 0316e8eefh, 04669be79h, 0cb61b38ch, 0bc66831ah, 0256fd2a0h, 05268e236h
  DD 0cc0c7795h, 0bb0b4703h, 0220216b9h, 05505262fh, 0c5ba3bbeh, 0b2bd0b28h
  DD 02bb45a92h, 05cb36a04h, 0c2d7ffa7h, 0b5d0cf31h, 02cd99e8bh, 05bdeae1dh
  DD 09b64c2b0h, 0ec63f226h, 0756aa39ch, 0026d930ah, 09c0906a9h, 0eb0e363fh
  DD 072076785h, 005005713h, 095bf4a82h, 0e2b87a14h, 07bb12baeh, 00cb61b38h
  DD 092d28e9bh, 0e5d5be0dh, 07cdcefb7h, 00bdbdf21h, 086d3d2d4h, 0f1d4e242h
  DD 068ddb3f8h, 01fda836eh, 081be16cdh, 0f6b9265bh, 06fb077e1h, 018b74777h
  DD 088085ae6h, 0ff0f6a70h, 066063bcah, 011010b5ch, 08f659effh, 0f862ae69h
  DD 0616bffd3h, 0166ccf45h, 0a00ae278h, 0d70dd2eeh, 04e048354h, 03903b3c2h
  DD 0a7672661h, 0d06016f7h, 04969474dh, 03e6e77dbh, 0aed16a4ah, 0d9d65adch
  DD 040df0b66h, 037d83bf0h, 0a9bcae53h, 0debb9ec5h, 047b2cf7fh, 030b5ffe9h
  DD 0bdbdf21ch, 0cabac28ah, 053b39330h, 024b4a3a6h, 0bad03605h, 0cdd70693h
  DD 054de5729h, 023d967bfh, 0b3667a2eh, 0c4614ab8h, 05d681b02h, 02a6f2b94h
  DD 0b40bbe37h, 0c30c8ea1h, 05a05df1bh, 02d02ef8dh

CalcCrc32   Proc near
    push ebx
    push ecx
    push edx
    push edi
;    
    mov eax,-1
    or ecx,ecx
    jz ccDone

ccLoop:
    mov bl,es:[edi]
    inc edi
    xor bl,al
    movzx bx,bl
    shl bx,2
    mov edx,dword ptr cs:[bx].crc32_tab
    shr eax,8
    xor eax,edx
    sub ecx,1
    jnz ccLoop
    
ccDone:    
    mov edx,-1
    xor eax,edx
;
    pop edi
    pop edx
    pop ecx
    pop ebx    
    ret
CalcCrc32   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       GetFsName
;
;       DESCRIPTION:    Get MS FS name from boot record
;
;       PARAMETERS:     GS      Port sel
;                       ES:EDI  GPT Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetFsName   Proc near
    push ds
    push es
    pushad
;
    mov eax,1000h
    AllocateBigLinear
    mov esi,edx
    mov ebp,edx
    mov es:[edx],eax
;
    mov edx,es:[edi].gpe_first_lba
    mov edi,esi
    call ReadSector
;
    mov ax,SEG data
    mov es,ax
    mov ax,flat_sel
    mov ds,ax
    mov di,OFFSET fs_name
;
    mov al,ds:[esi+3]
    cmp al,'M'
    je gfnDos
;
    cmp al,'m'
    je gfnLinux    
;
    add esi,3
    jmp gfnCopyName

gfnLinux:
    add esi,36h
    jmp gfnCopyName

gfnDos:
    add esi,52h

gfnCopyName:
    mov cx,8

gfnCopyLoop:    
    mov al,ds:[esi]
    or al,al
    jz gfnCopyDone
;
    cmp al,' '
    jz gfnCopyDone
;
    stosb
    inc si
    loop gfnCopyLoop    

gfnCopyDone:
    xor al,al
    stosb
;    
    mov edx,ebp
    mov ecx,1000h
    FreeLinear
;
    popad
    pop es    
    pop ds
    ret
GetFsName   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallEfiPart
;
;       DESCRIPTION:    Install EFI part
;
;       PARAMETERS:     GS      Port sel
;                       ES:EDI  Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallEfiPart    Proc near
    call GetFsName
;    
    push ds
    push es
    pushad
;
    mov edx,es:[edi].gpe_first_lba
    mov ecx,es:[edi].gpe_last_lba
    sub ecx,edx
    inc ecx
;
    mov di,SEG data
    mov es,di
    mov edi,OFFSET fs_name
    IsFileSystemAvailable
    jc iefipDone
;
    mov es:has_efi,1
;    
    AllocateStaticDrive
    mov ah,gs:ap_disc_nr
    OpenDrive
;
    InstallFileSystem
    clc

iefipDone:
    popad
    pop es    
    pop ds
    ret
InstallEfiPart  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallBasicPart
;
;       DESCRIPTION:    Install basic part
;
;       PARAMETERS:     GS      Port sel
;                       ES:EDI  Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallBasicPart    Proc near
    call GetFsName
;    
    push ds
    push es
    pushad
;
    mov edx,es:[edi].gpe_first_lba
    mov ecx,es:[edi].gpe_last_lba
    sub ecx,edx
    inc ecx
;
    mov di,SEG data
    mov es,di
    mov edi,OFFSET fs_name
    IsFileSystemAvailable
    jc ibpDone
;
    AllocateStaticDrive
    mov ah,gs:ap_disc_nr
    OpenDrive
;
    InstallFileSystem

ibpDone:
    popad
    pop es    
    pop ds
    ret
InstallBasicPart  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallEfiGptEntry
;
;       DESCRIPTION:    Install EFI GPT entry
;
;       PARAMETERS:     GS      Port sel
;                       ES:EDI  Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallEfiGptEntry    Proc near
    mov eax,dword ptr es:[edi].gpe_part_guid
    cmp eax,0C12A7328h
    jne iegpeDone
;
    mov eax,dword ptr es:[edi].gpe_part_guid+4
    cmp eax,11D2F81Fh
    jne iegpeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+8
    cmp eax,0A0004BBAh
    jne iegpeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+12
    cmp eax,3BC93EC9h
    jne iegpeDone
;
    call InstallEfiPart

iegpeDone:    
    ret
InstallEfiGptEntry     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallStdGptEntry
;
;       DESCRIPTION:    Install non-EFI GPT entry
;
;       PARAMETERS:     GS      Port sel
;                       ES:EDI  Entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallStdGptEntry    Proc near
    cmp eax,0EBD0A0A2h
    jne isgpeDone
;
    mov eax,dword ptr es:[edi].gpe_part_guid+4
    cmp eax,4433B9E5h
    jne isgpeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+8
    cmp eax,0B668C087h
    jne isgpeDone
;    
    mov eax,dword ptr es:[edi].gpe_part_guid+12
    cmp eax,0C79926B7h
    jne isgpeDone
;
    call InstallBasicPart

isgpeDone:    
    ret
InstallStdGptEntry     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallGpt1
;
;       DESCRIPTION:    Install GPT partition, first pass
;
;       PARAMETERS:     GS      Port sel
;                       ES      flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallGpt1    Proc near
    push es
    pushad
;
    xor ebp,ebp
    mov ax,flat_sel
    mov es,ax
;
    mov eax,1000h
    AllocateBigLinear    
    mov edi,edx
    mov es:[edi],eax
;    
    mov edx,1
    call ReadSector
;
    mov eax,dword ptr es:[edi].gpt_sign
    cmp eax,20494645h
    jne igptDone1
;
    mov eax,dword ptr es:[edi].gpt_sign+4
    cmp eax,54524150h
    jne igptDone1
;
    xor edx,edx
    xchg edx,es:[edi].gpt_crc32
    mov ecx,es:[edi].gpt_header_size
    cmp ecx,200h
    jae igptDone1
;    
    call CalcCrc32
    cmp eax,edx
    jne igptDone1
;    
    mov eax,es:[edi].gpt_entry_size
    cmp eax,128
    jne igptDone1
;
    mov eax,es:[edi].gpt_entry_lba+4
    or eax,eax
    jnz igptDone1   
;
    mov ecx,es:[edi].gpt_entry_count
    mov eax,ecx
    shl eax,7
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateBigLinear    
    mov ebp,edx
;
    push edx
    push edi
;
    mov ecx,eax
    shr ecx,9
    mov edx,es:[edi].gpt_entry_lba
    mov edi,ebp
    xor eax,eax

igptSectorLoop1:
    mov es:[edi],eax
    call ReadSector
;
    inc edx
    add edi,200h
    loop igptSectorLoop1
;
    pop edi
    pop edx
;
    push edi
;    
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edi,ebp
    call CalcCrc32
;    
    pop edi
;
    cmp eax,es:[edi].gpt_entry_crc32
    jne igptDone1
;
    push edi
    mov ecx,es:[edi].gpt_entry_count
    mov edi,ebp
    or ecx,ecx
    jz igptEntryDone1

igptEntryLoop1:
    mov eax,es:[edi].gpe_last_lba+4
    or eax,eax
    jnz igptEntryNext1
;
    mov eax,es:[edi].gpe_first_lba+4
    or eax,eax
    jnz igptEntryNext1
;
    mov eax,es:[edi].gpe_first_lba
    or eax,eax
    jz igptEntryNext1
;
    mov edx,es:[edi].gpe_last_lba
    sub edx,eax
    jc igptEntryNext1
;
    call InstallEfiGptEntry

igptEntryNext1:
    add edi,128 
    sub ecx,1
    jnz igptEntryLoop1

igptEntryDone1:     
    pop edi
    
igptDone1:
    or ebp,ebp
    jz igptEnd1
;
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edx,ebp
    FreeLinear
        
igptEnd1:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
;
    popad
    pop es
    ret
InstallGpt1    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       InstallGpt2
;
;       DESCRIPTION:    Install GPT partition, second pass
;
;       PARAMETERS:     GS      Port sel
;                       ES      flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InstallGpt2    Proc near
    push es
    pushad
;
    xor ebp,ebp
    mov ax,flat_sel
    mov es,ax
;
    mov eax,1000h
    AllocateBigLinear    
    mov edi,edx
    mov es:[edi],eax
;    
    mov edx,1
    call ReadSector
;
    mov eax,dword ptr es:[edi].gpt_sign
    cmp eax,20494645h
    jne igptDone2
;
    mov eax,dword ptr es:[edi].gpt_sign+4
    cmp eax,54524150h
    jne igptDone2
;
    xor edx,edx
    xchg edx,es:[edi].gpt_crc32
    mov ecx,es:[edi].gpt_header_size
    cmp ecx,200h
    jae igptDone2
;    
    call CalcCrc32
    cmp eax,edx
    jne igptDone2
;    
    mov eax,es:[edi].gpt_entry_size
    cmp eax,128
    jne igptDone2
;
    mov eax,es:[edi].gpt_entry_lba+4
    or eax,eax
    jnz igptDone2
;
    mov ecx,es:[edi].gpt_entry_count
    mov eax,ecx
    shl eax,7
    dec eax
    and ax,0F000h
    add eax,1000h
    AllocateBigLinear    
    mov ebp,edx
;
    push edx
    push edi
;
    mov ecx,eax
    shr ecx,9
    mov edx,es:[edi].gpt_entry_lba
    mov edi,ebp
    xor eax,eax

igptSectorLoop2:
    mov es:[edi],eax
    call ReadSector
;
    inc edx
    add edi,200h
    loop igptSectorLoop2
;
    pop edi
    pop edx
;
    push edi
;    
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edi,ebp
    call CalcCrc32
;    
    pop edi
;
    cmp eax,es:[edi].gpt_entry_crc32
    jne igptDone2
;
    push edi
    mov ecx,es:[edi].gpt_entry_count
    mov edi,ebp
    or ecx,ecx
    jz igptEntryDone2

igptEntryLoop2:
    mov eax,es:[edi].gpe_last_lba+4
    or eax,eax
    jnz igptEntryNext2
;
    mov eax,es:[edi].gpe_first_lba+4
    or eax,eax
    jnz igptEntryNext2
;
    mov eax,es:[edi].gpe_first_lba
    or eax,eax
    jz igptEntryNext2
;
    mov edx,es:[edi].gpe_last_lba
    sub edx,eax
    jc igptEntryNext2
;
    call InstallStdGptEntry

igptEntryNext2:
    add edi,128 
    sub ecx,1
    jnz igptEntryLoop2   

igptEntryDone2:     
    pop edi
    
igptDone2:
    or ebp,ebp
    jz igptEnd2
;
    mov ecx,es:[edi].gpt_entry_count
    shl ecx,7
    mov edx,ebp
    FreeLinear
        
igptEnd2:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
;
    popad
    pop es
    ret
InstallGpt2    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:       perform_one
;
;       DESCRIPTION:    Perform one
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
    call AllocateSlot
    jnc perform_write_has_slot
;
    mov bx,gs:ap_notify_thread
    Signal
;
    mov ax,10
    WaitMilliSec
    jmp perform_one_write

perform_write_has_slot:
    push ax
    mov al,ATA_DMA_WRITE
    test gs:ap_flags,PORT_FLAG_48_BIT
    jnz perform_write_op_ok
;    
    mov al,0CAh

perform_write_op_ok:
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

perform_write_queue_loop:
    mov edi,es:[esi]
    push ecx
    push esi
    mov esi,es:[edi].dh_data
    mov ecx,200h
    call AddPrdEntry
    pop esi
    pop ecx
    add esi,4
    loop perform_write_queue_loop
;
    pop cx
;
    push ds    
    mov ds,gs:ap_cmd_sel
    movzx bx,al
    shl bx,5
    mov ds:[bx].acl_prdtl,cx
    mov ds:[bx].acl_flags,0C5h
    mov ds:[bx].acl_transfer_count,0
;
    movzx ecx,cx
    shl ecx,9
    mov ds:[bx].acl_total_count,ecx
    pop ds
;
    call StartCmd
    jmp perform_one_loop

perform_one_read:
    call AllocateSlot
    jnc perform_read_has_slot
;
    mov bx,gs:ap_notify_thread
    Signal
;
    mov ax,10
    WaitMilliSec
    jmp perform_one_read

perform_read_has_slot:
    push ax
    mov al,ATA_DMA_READ
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
    mov cl,es:[esi]
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
    mov ds:[bx].acl_flags,85h
    mov ds:[bx].acl_transfer_count,0
;
    movzx ecx,cx
    shl ecx,9
    mov ds:[bx].acl_total_count,ecx
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
    test gs:ap_cap,HBA_CAP_S64A
    jnz req_discbuf_loop
;
    SetDiscUse32

req_discbuf_loop:
    WaitForDiscRequest
    call perform_one
    jmp req_discbuf_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NotifyCmdList
;
;       DESCRIPTION:    Notify command list
;
;       PARAMETERS:     ES      Flat sel
;                       GS      Port sel
;                       AL      CMD list #
;                       CX      Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyCmdList   Proc near
    push ds
    push bx
    push si
    push edi
;
    mov ds,gs:ap_slot_sel
    movzx si,al
    add si,si
    mov si,ds:[si].as_index_arr
    add si,act_prd
    or cx,cx
    jz nclDone

nclLoop:
    xor edi,edi
    xchg edi,ds:[si].ape_handle
    or edi,edi
    jz nclNext
;
    mov es:[edi].dh_state,STATE_USED
    mov bx,gs:ap_disc_sel
    DiscRequestCompleted

nclNext:
    add si,10h
    loop nclLoop
        
nclDone:
    pop edi
    pop si    
    pop bx
    pop ds
    ret
NotifyCmdList   Endp

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

notify_discbuf_retry:
    mov ds,gs:ap_hba_sel
    RequestSpinlock gs:ap_spinlock
    mov edx,ds:hba_pxci
    mov eax,gs:ap_active_mask
    xor eax,edx
    and eax,gs:ap_active_mask
    ReleaseSpinlock gs:ap_spinlock       
;
    and eax,gs:ap_slot_mask
    jnz notify_cmd_check
;
    mov eax,ds:hba_pxcmd
    test eax,HBA_PXCMD_CR
    jnz notify_discbuf_loop
;
    mov edx,ds:hba_pxci
    or edx,edx
    jz notify_discbuf_loop
;    
    mov ax,gs:ap_restart_count
    cmp ax,3
    jb notify_do_reset
;
    int 3
    push ds
    mov ds,gs:ap_fis_sel
    pop ds

notify_do_reset:
    inc gs:ap_restart_count            
    and ds:hba_pxcmd,NOT HBA_PXCMD_ST

notify_wait_reset:
    mov ax,25
    WaitMilliSec
    test ds:hba_pxcmd,HBA_PXCMD_ST
    jnz notify_wait_reset        
;
    or ds:hba_pxcmd,HBA_PXCMD_ST        

notify_wait_start:
    mov ax,25
    WaitMilliSec
    test ds:hba_pxcmd,HBA_PXCMD_CR
    jz notify_wait_start        
;
    mov ax,100
    WaitMilliSec
;
    mov ds:hba_pxci,edx
    jmp notify_discbuf_loop

notify_cmd_check:
    mov gs:ap_restart_count,0
    xor cx,cx
    mov ds,gs:ap_cmd_sel
    xor si,si
    mov ebx,1

notify_cmd_loop:
    shr eax,1
    jnc notify_cmd_next
;
    mov edx,ds:[si].acl_transfer_count
    cmp edx,ds:[si].acl_total_count
    jae notify_cmd_done
;
    inc cx
    jmp notify_cmd_next

notify_cmd_done:
    push eax
    push cx
    mov ax,si
    shr ax,5
    mov cx,ds:[si].acl_prdtl
    call NotifyCmdList
    mov eax,ebx
    not eax
    and gs:ap_active_mask,eax
    and gs:ap_reserved_mask,eax
    pop cx
    pop eax
    
notify_cmd_next:
    shl ebx,1
    add si,20h
    or eax,eax
    jnz notify_cmd_loop
;    
;    or cx,cx
;    jz notify_discbuf_retry
;
    mov ax,1
    WaitMilliSec
    jmp notify_discbuf_retry
        
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
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;
    mov ds:has_efi,1
;
    mov al,ds:has_disc
    or al,al
    jnz drive_assign_has_disc1
;        
    AllocateStaticDrive
    mov ds:has_disc,1
    mov ds:has_efi,0

drive_assign_has_disc1:    
    mov eax,1000h
    AllocateBigLinear
    push ebx
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    pop ebx
    mov edi,edx
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
    cmp cl,0EEh
    je drive_assign_gpt1
;
    mov ax,SEG data
    mov ds,ax
    mov al,ds:has_efi
    or al,al
    jnz drive_assign_efi_ok1
;
    mov ds:has_efi,1
    AllocateStaticDrive

drive_assign_efi_ok1:
    mov eax,es:[esi+edi].part_sectors
    mov edx,es:[esi+edi].part_start_sector
    call InstallPartition
    jmp drive_assign_next_part1

drive_assign_gpt1:
    call InstallGpt1

drive_assign_next_part1:
    add si,10h
    cmp si,1FEh
    jne drive_assign_loop1

drive_assign_free1:
    mov ecx,1000h
    mov edx,edi
    FreeLinear
;
    mov ax,SEG data
    mov ds,ax
    mov al,ds:has_efi
    or al,al
    jnz drive_assign_done1
;
    AllocateStaticDrive    

drive_assign_done1:        
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
    push ebx
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    pop ebx
    mov edi,edx
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
    push ebx
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    pop ebx
    mov edi,edx
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
    cmp cl,0EEh
    je drive_assign_gpt2
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
    jmp drive_assign_next_part2

drive_assign_gpt2:
    call InstallGpt2

drive_assign_next_part2:
    add si,10h
    cmp si,1FEh
    jne drive_assign_loop2
;
    mov ecx,1000h
    mov edx,edi
    FreeLinear
;    
;    push ax
;    mov ax,200
;    WaitMilliSec
;    pop ax
    
    mov bx,gs:ap_disc_sel
    StartDisc
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
    mov ds:has_efi,0
    mov ds:has_disc,0
    mov cx,ds:ahci_dev_count
    or cx,cx
    jz iaDone
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET disc_ctrl
    HookInitDisc
    
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
