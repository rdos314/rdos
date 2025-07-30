;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; AHCI.ASM
; AHCI SATA disk driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\core.inc
INCLUDE ..\acpi\pci.inc

MAX_DISCS           = 32

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

ap_fis_phys         DD ?
ap_cmd_phys         DD ?

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
ap_retry_count      DW ?

ap_spinlock         spinlock_typ <>
ap_slot_mask        DD ?
ap_reserved_mask    DD ?
ap_active_mask      DD ?

ap_sector_count     DD ?,?
ap_sectors_per_unit DW ?
ap_disc_sel         DW ?
ap_disc_nr          DB ?

ap_cap              DD ?
ap_sata_cap         DW ?

ap_model            DB 48 DUP(?)

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

ad_pci_handle       DW ?
ad_msi              DB ?

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

pci_name_ptr        DW ?
pci_name_str        DB MAX_NAME_SIZE DUP(?)

fs_name             DB 10 DUP(?)

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
    push gs
    mov gs,ds:ad_hba_sel

aiRetry:    
    mov eax,gs:hba_is
    and eax,gs:hba_pi
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
    mov gs:hba_is,edx

aiHandleNext:
    or eax,eax
    jz aiRetry
;    
    shl edx,1
    add si,2
    jmp aiHandlePort        

aiDone:        
    pop gs
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
    mov es:[di].acl_thread,0
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
    mov al,13h
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
    mov ds:ap_retry_count,0
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
;                       BX      PCI handle
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
    mov es:ad_pci_handle,bx
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

DevName DB 'AHCI ', 0

InitPciAhci Proc near
    mov ax,SEG data
    mov ds,ax
    mov es,ax
    mov ds:ahci_dev_count,0

    mov di,OFFSET pci_name_str
    mov si,OFFSET DevName

ipaNameLoop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz ipaNameLoop
;
    dec di
    mov ds:pci_name_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb
;    
    xor bx,bx

ipaLoop: 
    mov ah,1
    mov al,6
    FindPciClassHandle
    jc ipaDone
;
    mov al,5
    GetPciBarPhys
    jc ipaLoop
;    
    push eax
    mov ax,ds:ahci_dev_count
    add al,'0'
    mov di,ds:pci_name_ptr
    mov ds:[di],al
    mov ax,ds
    mov es,ax
    mov edi,OFFSET pci_name_str
    LockPciHandle
    pop eax
;
    push ebx
    mov ebx,edx
;
    push eax
    mov eax,2000h
    AllocateBigLinear
    pop eax
;
    or al,13h
    SetPageEntry
;
    add eax,1000h
    add edx,1000h
    SetPageEntry
    sub edx,1000h
;        
    AllocateGdt
    mov ecx,100h
    CreateDataSelector16
    mov fs,bx
    test fs:hba_ghc,HBA_GHC_AE
    jnz ipaAdd
;   
    mov fs:hba_ghc,HBA_GHC_AE
    
ipaAdd:
    pop ebx
    call AddDevice

ipaNext:
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
    mov es:ap_fis_phys,eax
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
    mov bx,ds:ad_pci_handle
    GetPciHandleMsiX
    jc siCheckMsi
;
    cmp al,1
    ja siMulti

siCheckMsi:
    GetPciHandleMsi
    jc siSingle
;
    cmp al,1
    ja siMulti

siSingle:
    mov ds:ad_msi,0
    mov al,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET AhciInt
    SetupPciHandleIrq
    jmp siDone

siMulti:
    mov ah,14h
    movzx cx,al
    ReqPciHandleMsi    
    jc siSingle
;
    mov ds:ad_msi,1
    xor edx,edx

siMultiLoop:
    mov si,ds:[2 * edx].ad_port_arr
    or si,si
    jz siMultiNext

siMultiSetup:
    push ds
    mov ds,si
    mov di,cs
    mov es,di
    mov edi,OFFSET AhciPortInt
    SetupPciHandleMsi
    pop ds

siMultiNext:
    inc al
    inc dx
    loop siMultiLoop

siDone:
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
    mov gs:ap_cmd_phys,eax
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
;                       BP:EDX  Sector #
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
    movzx edx,bp
    shl edx,8
    mov dl,40h
    xchg dl,ds:[bx].fhtd_device
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
;                       BP:EDX  Sector #
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
    movzx edx,bp
    shl edx,8
    mov dl,40h
    xchg dl,ds:[bx].fhtd_device
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
    xor bp,bp
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
    xor ebx,ebx
    mov ecx,10

gdpCopyModel:
    mov eax,es:[esi+ebx+36h]
    mov dword ptr gs:[ebx].ap_model,eax
    add ebx,4
    loop gdpCopyModel
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
;    
    mov gs:ap_sector_count,eax
    mov gs:ap_sector_count+4,edx
    clc
    jmp gdpDone

gdp24:
    mov eax,es:[esi+120]
    mov gs:ap_sector_count,eax
    mov gs:ap_sector_count+4,0
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
;       NAME:       perform_one
;
;       DESCRIPTION:    Perform one
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

action_read DB 'Read', 0
action_write DB 'Write', 0

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
    push es
    push edi
    mov di,cs
    mov es,di
    mov edi,OFFSET action_write
    SetThreadAction
    pop edi
    pop es
;    
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
    mov edx,es:[edi].dh_unit
    movzx eax,gs:ap_sectors_per_unit
    mul edx
    mov bp,dx
    movzx edx,es:[edi].dh_sector
    add edx,eax
    adc bp,0
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
    mov ds:[bx].acl_thread,0
;
    movzx ecx,cx
    shl ecx,9
    mov ds:[bx].acl_total_count,ecx
    pop ds
;
    call StartCmd
    jmp perform_one_loop

perform_one_read:
    push es
    push edi
    mov di,cs
    mov es,di
    mov edi,OFFSET action_read
    SetThreadAction
    pop edi
    pop es
;    
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
    mov edx,es:[edi].dh_unit
    movzx eax,gs:ap_sectors_per_unit
    mul edx
    mov bp,dx
    movzx edx,es:[edi].dh_sector
    add edx,eax
    adc bp,0
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
    mov ds:[bx].acl_thread,0
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

action_wait DB 'Idle', 0

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
    push es
    push edi
    mov di,cs
    mov es,di
    mov edi,OFFSET action_wait
    SetThreadAction
    pop edi
    pop es
;
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
;       NAME:           RetryCmdList
;
;       DESCRIPTION:    Retry command list
;
;       PARAMETERS:     ES      Flat sel
;                       GS      Port sel
;                       AL      CMD list #
;                       CX      Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RetryCmdList   Proc near
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
    jz rclDone

rclLoop:
    xor edi,edi
    xchg edi,ds:[si].ape_handle
    or edi,edi
    jz rclNext
;
    mov bx,gs:ap_disc_sel
    DiscRequestRetry

rclNext:
    add si,10h
    loop rclLoop
        
rclDone:
    pop edi
    pop si    
    pop bx
    pop ds
    ret
RetryCmdList   Endp

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
    GetSystemTime
    add eax,1193 * 100
    adc edx,0
    WaitForSignalWithTimeout

notify_discbuf_retry:
    mov ds,gs:ap_hba_sel
    mov eax,HBA_PXI_DP OR HBA_PXI_DHR
    mov ds:hba_pxis,eax
;    
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
    jz notify_discbuf_has_data
;
    mov edx,ds:hba_pxci
    or edx,edx
    jnz notify_discbuf_has_data
;    
    mov eax,gs:ap_active_mask
    or eax,eax
    jnz notify_discbuf_has_active
;    
    mov gs:ap_retry_count,0
    jmp notify_discbuf_loop

notify_discbuf_has_active:
    mov ax,gs:ap_retry_count
    cmp ax,100
    ja notify_discbuf_try_reset
;
    inc gs:ap_retry_count
    jmp notify_discbuf_loop

notify_discbuf_has_data:
    mov gs:ap_retry_count,0
    jmp notify_discbuf_loop

notify_discbuf_try_reset:
    int 3
    mov gs:ap_retry_count,0
;    
    mov ds,gs:ap_hba_sel
    and ds:hba_pxcmd,NOT HBA_PXCMD_ST
;    
    RequestSpinlock gs:ap_spinlock
    mov eax,gs:ap_slot_mask
    mov gs:ap_reserved_mask,eax
    mov eax,gs:ap_active_mask
    ReleaseSpinlock gs:ap_spinlock       
;
    xor cx,cx
    mov ds,gs:ap_cmd_sel
    xor si,si
    mov ebx,1

notify_retry_loop:
    shr eax,1
    jnc notify_retry_next
;
    push eax
    push cx
    mov ax,si
    shr ax,5
    mov cx,ds:[si].acl_prdtl
    call RetryCmdList
    pop cx
    pop eax
    
notify_retry_next:
    shl ebx,1
    add si,20h
    or eax,eax
    jnz notify_retry_loop

notify_do_reset:
    mov ds,gs:ap_hba_sel

notify_wait_reset:
    mov ax,25
    WaitMilliSec
    test ds:hba_pxcmd,HBA_PXCMD_ST
    jnz notify_wait_reset        
;
    and ds:hba_pxcmd,NOT HBA_PXCMD_FRE

notify_wait_idle:
    mov ax,25
    WaitMilliSec
    test ds:hba_pxcmd,HBA_PXCMD_FR
    jnz notify_wait_idle
;
    mov eax,gs:ap_fis_phys
    mov ds:hba_pxfb,eax
    mov ds:hba_pxfbu,0
    mov eax,ds:hba_pxfb
    or ds:hba_pxcmd,HBA_PXCMD_FRE OR HBA_PXCMD_SUD

notify_wait_frrun:
    mov ax,25
    WaitMilliSec
    test ds:hba_pxcmd,HBA_PXCMD_FR
    jz notify_wait_frrun
;
    mov eax,gs:ap_cmd_phys
    mov ds:hba_pxclb,eax
    mov ds:hba_pxclbu,0
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
    xor eax,eax
    mov gs:ap_active_mask,eax
    mov gs:ap_reserved_mask,eax
    jmp notify_discbuf_loop

notify_cmd_check:
    mov gs:ap_retry_count,0
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
    RequestSpinlock gs:ap_spinlock
    and gs:ap_active_mask,eax
    and gs:ap_reserved_mask,eax
    ReleaseSpinlock gs:ap_spinlock
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
    InstallStaticDisc
;
    mov ds:ap_disc_sel,bx
    mov ds:ap_disc_nr,al
;
    mov cx,512
    mov eax,ds:ap_sector_count
    mov edx,ds:ap_sector_count+4
    mov bx,ds:ap_disc_sel
    SetDiscLbaParam
    mov ds:ap_sectors_per_unit,ax
;
    GetDiscVendorInfoBuf
    mov al,'S'
    stosb
    mov al,'A'
    stosb
    mov al,'T'
    stosb
    mov al,'A'
    stosb
    mov al,':'
    stosb
;    
    mov cx,10
    mov si,OFFSET ap_model
    rep movsd
    xor al,al
    stosb
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
;       NAME:           SetupAhci
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

SetupAhci Proc near
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
    ret
SetupAhci Endp  

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
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:ahci_dev_count
    or cx,cx
    jz iaFail
;
    call SetupAhci
    jmp iaDone

iaFail:
    mov ax,wd_code_sel
    verr ax
    jnz iaDone
;
    SoftReset
    
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
