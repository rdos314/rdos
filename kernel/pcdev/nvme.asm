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
; nvme.ASM
; NVMe server file system driver
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
INCLUDE pci.inc

MAX_NVME_DEVICES    = 16
MAX_QUEUES          = 2

;
; PCI BAR 0 config
;

pci_config  STRUC

pci_cap		DD ?,?
pci_vs          DD ?
pci_intms       DD ?
pci_intmc       DD ?
pci_cc          DD ?
pci_resv        DD ?
pci_csts        DD ?
pci_nssr        DD ?
pci_aqa         DD ?
pci_asq         DD ?,?
pci_acq         DD ?,?
pci_cmbloc      DD ?
pci_cmbsz       DD ?
pci_bpinfo      DD ?
pci_bprsel      DD ?
pci_bpmbl       DD ?,?
pci_cmbmsc      DD ?,?
pci_cmbsts      DD ?
pci_cmbebs      DD ?
pci_cmbswtp     DD ?
pci_nssd        DD ?
pci_crto        DD ?

pci_config  ENDS

;
; submission queue format
;

sub_struc	STRUC

sub_opc         DB ?
sub_flags	DB ?
sub_cid         DW ?
sub_nsid        DD ?
sub_cdw2	DD ?
sub_cdw3	DD ?
sub_mptr	DD ?,?
sub_prp1        DD ?,?
sub_prp2        DD ?,?
sub_cdw10       DD ?
sub_cdw11       DD ?
sub_cdw12       DD ?
sub_cdw13       DD ?
sub_cdw14       DD ?
sub_cdw15       DD ?

sub_struc       ENDS

adm_struc	STRUC

adm_opc         DB ?
adm_flags	DB ?
adm_cid         DW ?
adm_nsid        DD ?
adm_resv	DD ?,?
adm_mptr	DD ?,?
adm_prp1        DD ?,?
adm_prp2        DD ?,?
adm_ndt         DD ?
adm_ndm         DD ?
adm_cdw12       DD ?
adm_cdw13       DD ?
adm_cdw14       DD ?
adm_cdw15       DD ?

adm_struc       ENDS


;
; completion queue format
;

comp_struc      STRUC

comp_dw0        DD ?
comp_dw1        DD ?
comp_sq_head    DW ?
comp_sq_id      DW ?
comp_cid        DW ?
comp_status     DW ?

comp_struc      ENDS

;
; identify reply
;

id1_struc   STRUC

id1_vid          DW ?
id1_ssvid        DW ?
id1_sn           DB 20 DUP(?)
id1_mn           DB 40 DUP(?)
id1_fr           DB 8 DUP(?)
id1_rab          DB ?
id1_ieee         DB ?,?,?
id1_cmic         DB ?
id1_mdts         DB ?
id1_cntlid       DW ?
id1_ver          DD ?
id1_rtd3r        DD ?
id1_rtd3e        DD ?
id1_oaes         DD ?
id1_ctratt       DD ?
id1_rrls         DW ?
id1_resv1        DB 9 DUP(?)
id1_cntrltype    DB ?
id1_fguid        DB 16 DUP(?)
id1_crdt1        DW ?
id1_crdt2        DW ?
id1_crdt3        DW ?
id1_resv2        DB 119 DUP(?)
id1_nvmsr        DB ?
id1_vwci         DB ?
id1_mec          DB ?
id1_oacs         DW ?
id1_acl          DB ?
id1_aerl         DB ?
id1_frmw         DB ?
id1_lpa          DB ?
id1_elpe         DB ?
id1_npss         DB ?
id1_avscc        DB ?
id1_apsta        DB ?
id1_wctemp       DW ?
id1_cctemp       DW ?
id1_mtfa         DW ?
id1_hmpre        DD ?
id1_hmmin        DD ?
id1_tnvmcap      DD ?,?,?,?
id1_unvmcap      DD ?,?,?,?
id1_rpmbs        DD ?
id1_edstt        DW ?
id1_dsto         DB ?
id1_fwug         DB ?
id1_kas          DW ?
id1_htcma        DW ?
id1_mntmt        DW ?
id1_mxtmt        DW ?
id1_sanicap      DD ?
id1_hmminds      DD ?
id1_hmmaxd       DW ?
id1_nsetidmax    DW ?
id1_endgidmax    DW ?
id1_anatt        DB ?
id1_anacap       DB ?
id1_anagrpmax    DD ?
id1_nanagrpid    DD ?
id1_pels         DD ?
id1_di           DW ?
id1_resv3        DB 10 DUP(?)
id1_megcap       DD ?,?,?,?
id1_resv4        DB 128 DUP(?)
id1_sqes         DB ?
id1_cqes         DB ?
id1_maxcmd       DW ?
id1_nn           DD ?
id1_oncs         DW ?
id1_fuses        DW ?
id1_fna          DB ?
id1_vwc          DB ?
id1_awun         DW ?
id1_awupf        DW ?
id1_icsvscc      DB ?
id1_nwpc         DB ?
id1_acwu         DW ?
id1_cdfs         DW ?
id1_sgls         DD ?
id1_mnan         DD ?
id1_maxdna       DD ?,?,?,?
id1_maxcna       DD ?
id1_resv5        DB 204 DUP(?)
id1_subnqn       DB 256 DUP(?)

id1_struc   ENDS

;
; NVME device
;

nvme_device_struc   STRUC

nd_admin_submit_phys     DD ?,?
nd_admin_complete_phys   DD ?,?

nd_submit_phys           DD MAX_QUEUES DUP(?,?)
nd_complete_phys         DD MAX_QUEUES DUP(?,?)

nd_config_sel            DW ?
nd_door_sel              DW ?
nd_admin_submit_sel      DW ?
nd_admin_complete_sel    DW ?

nd_submit_sel            DW MAX_QUEUES DUP(?)
nd_complete_sel          DW MAX_QUEUES DUP(?)

nd_admin_submit_ptr      DW ?
nd_admin_complete_ptr    DW ?

nd_queue_entries         DW ?
nd_submit_queues         DW ?
nd_complete_queues       DW ?

nd_nsid_count            DW ?

nd_pci_bus               DB ?
nd_pci_device            DB ?
nd_pci_function          DB ?

nd_door_shift            DB ?
nd_submit_shift          DB ?
nd_complete_shift        DB ?

nvme_device_struc   ENDS


data    SEGMENT byte public 'DATA'

nvme_dev_count      DW ?
nvme_dev_arr        DW MAX_NVME_DEVICES DUP(?)

data    ENDS


IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public use32 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NvmeInt
;
;       DESCRIPTION:    IRQ handler
;
;       PARAMETERS:     DS      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NvmeInt  Proc far
    ret
NvmeInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SignalSubmitDoor
;
;   DESCRIPTION:    Signal submit door
;
;   PARAMETERS:     ES             Device sel
;                   EBX            Door #
;                   EAX            Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignalSubmitDoor  Proc near
    push ds
    push ebx
    push ecx
;
    mov ds,es:nd_door_sel
    mov cl,es:nd_door_shift
    add ebx,ebx
    shl ebx,cl
    mov ds:[ebx],eax
;
    pop ecx
    pop ebx
    pop ds
    ret
SignalSubmitDoor   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SignalCompleteDoor
;
;   DESCRIPTION:    Signal complete door
;
;   PARAMETERS:     ES             Device sel
;                   EBX            Door #
;                   EAX            Position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignalCompleteDoor  Proc near
    push ds
    push ebx
    push ecx
;
    mov ds,es:nd_door_sel
    mov cl,es:nd_door_shift
    add ebx,ebx
    inc ebx
    shl ebx,cl
    mov ds:[ebx],eax
;
    pop ecx
    pop ebx
    pop ds
    ret
SignalCompleteDoor   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AdminSession
;
;   DESCRIPTION:    Admin session
;
;   PARAMETERS:     ES      Device sel
;                   DS:EBX  Submit entry
;
;   RETURNS:        EDX:EAX Dword 0 & 1
;                   CL      Result code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdminSession  Proc near
    push ds
    push ebx
;
    mov cx,ds:[ebx].adm_cid
    movzx eax,es:nd_admin_submit_ptr
    inc eax
    cmp ax,40h
    jb asSubUpd
;
    xor eax,eax

asSubUpd:
    mov es:nd_admin_submit_ptr,ax
;
    xor ebx,ebx
    call SignalSubmitDoor
;
    mov ds,es:nd_admin_complete_sel
    movzx ebx,es:nd_admin_complete_ptr
    shl ebx,4

asCompCheck:
    mov ax,ds:[ebx].comp_status
    test al,1
    jnz asCompOk
;
    mov ax,10
    WaitMilliSec
    jmp asCompCheck

asCompOk:
    cmp cx,ds:[ebx].comp_cid
    stc
    jne asDone
;
    xor cx,cx
    xchg cx,ds:[ebx].comp_status
    mov eax,ds:[ebx].comp_dw0
    mov edx,ds:[ebx].comp_dw1
    push eax
;
    movzx eax,es:nd_admin_complete_ptr
    inc eax
    cmp ax,100h
    jb asCompUpd
;
    xor eax,eax

asCompUpd:
    mov es:nd_admin_complete_ptr,ax
;
    xor ebx,ebx
    call SignalCompleteDoor
;
    pop eax
    shr cl,1
    or cl,cl
    clc
    jz asDone
;
    stc

asDone:
    pop ebx
    pop ds
    ret
AdminSession  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetId1
;
;   DESCRIPTION:    Get ID 1 info
;
;   PARAMETERS:     ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetId1  Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov esi,eax
    mov edi,ebx
;
    mov al,63h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov gs,bx
;
    mov ds,es:nd_admin_submit_sel
    mov fs,es:nd_config_sel
    movzx ebx,es:nd_admin_submit_ptr
    shl ebx,6
    mov ds:[ebx].adm_opc,6
    mov ds:[ebx].adm_flags,0
    mov ds:[ebx].adm_cid,1
    mov ds:[ebx].adm_nsid,0
    mov ds:[ebx].adm_resv,0
    mov ds:[ebx].adm_resv+4,0
    mov ds:[ebx].adm_mptr,0
    mov ds:[ebx].adm_mptr+4,0
;
    mov ds:[ebx].adm_prp1,esi
    mov ds:[ebx].adm_prp1+4,edi
;
    mov ds:[ebx].adm_prp2,0
    mov ds:[ebx].adm_prp2+4,0
;
    mov ds:[ebx].adm_ndt,1
    mov ds:[ebx].adm_ndm,0
;
    mov ds:[ebx].adm_cdw12,0
    mov ds:[ebx].adm_cdw13,0
    mov ds:[ebx].adm_cdw14,0
    mov ds:[ebx].adm_cdw15,0
    call AdminSession
    jc gid1Done
;
    mov al,gs:id1_sqes
    and al,0Fh
    mov es:nd_submit_shift,al
;
    mov al,gs:id1_cqes
    and al,0Fh
    mov es:nd_complete_shift,al
;
    xor ax,ax
    mov al,es:nd_complete_shift
    shl al,4
    or al,es:nd_submit_shift
    shl eax,16
    mov ax,1
    mov fs:pci_cc,eax
;
    mov eax,gs:id1_nn
    mov es:nd_nsid_count,ax

gid1Done:
    mov eax,gs
    mov es,eax
    xor eax,eax
    mov gs,eax
    FreeMem
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
GetId1  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetId0
;
;   DESCRIPTION:    Get ID 0 info
;
;   PARAMETERS:     ES      Device sel
;                   EAX     NSID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetId0  Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ebp,eax
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov esi,eax
    mov edi,ebx
;
    mov al,63h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov gs,bx
;
    mov ds,es:nd_admin_submit_sel
    mov fs,es:nd_config_sel
    movzx ebx,es:nd_admin_submit_ptr
    shl ebx,6
    mov ds:[ebx].adm_opc,6
    mov ds:[ebx].adm_flags,0
    mov ds:[ebx].adm_cid,1
    mov ds:[ebx].adm_nsid,ebp
    mov ds:[ebx].adm_resv,0
    mov ds:[ebx].adm_resv+4,0
    mov ds:[ebx].adm_mptr,0
    mov ds:[ebx].adm_mptr+4,0
;
    mov ds:[ebx].adm_prp1,esi
    mov ds:[ebx].adm_prp1+4,edi
;
    mov ds:[ebx].adm_prp2,0
    mov ds:[ebx].adm_prp2+4,0
;
    mov ds:[ebx].adm_ndt,0
    mov ds:[ebx].adm_ndm,0
;
    mov ds:[ebx].adm_cdw12,0
    mov ds:[ebx].adm_cdw13,0
    mov ds:[ebx].adm_cdw14,0
    mov ds:[ebx].adm_cdw15,0
    call AdminSession
    jc gid0Done
;

gid0Done:
    mov eax,gs
    mov es,eax
    xor eax,eax
    mov gs,eax
    FreeMem
;
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret
GetId0  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetQueueCount
;
;   DESCRIPTION:    Read number of queues
;
;   PARAMETERS:     ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetQueueCount  Proc near
    push ds
    pushad
;
    mov ds,es:nd_admin_submit_sel
    movzx ebx,es:nd_admin_submit_ptr
    shl ebx,6
    mov ds:[ebx].adm_opc,0Ah
    mov ds:[ebx].adm_flags,0
    mov ds:[ebx].adm_cid,2
    mov ds:[ebx].adm_nsid,0
    mov ds:[ebx].adm_resv,0
    mov ds:[ebx].adm_resv+4,0
    mov ds:[ebx].adm_mptr,0
    mov ds:[ebx].adm_mptr+4,0
;
    mov ds:[ebx].adm_prp1,0
    mov ds:[ebx].adm_prp1+4,0
;
    mov ds:[ebx].adm_prp2,0
    mov ds:[ebx].adm_prp2+4,0
;
    mov ds:[ebx].adm_ndt,7
    mov ds:[ebx].adm_ndm,0
;
    mov ds:[ebx].adm_cdw12,0
    mov ds:[ebx].adm_cdw13,0
    mov ds:[ebx].adm_cdw14,0
    mov ds:[ebx].adm_cdw15,0
    call AdminSession
;
    inc ax
    mov es:nd_submit_queues,ax
    shr eax,16
    inc ax
    mov es:nd_complete_queues,ax
;
    popad
    pop ds
    ret
GetQueueCount  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateIoCompletionQueue
;
;   DESCRIPTION:    Create IO completion queue
;
;   PARAMETERS:     ES      Device sel
;                   AX      Queue # (1..QN)
;                   DL      Interrupt #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIoCompletionQueue  Proc near
    push ds
    pushad
;
    movzx edi,dl
    movzx esi,ax
    dec esi
    add esi,esi
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    xor al,al
    mov es:[4*esi].nd_complete_phys,eax
    mov es:[4*esi].nd_complete_phys+4,ebx
;
    mov al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
;
    push es
    push ecx
    push edi
;
    mov es,ebx
    xor edi,edi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop edi
    pop ecx
    pop es
;
    mov es:[esi].nd_complete_sel,bx
;
    mov ds,es:nd_admin_submit_sel
    movzx ebx,es:nd_admin_submit_ptr
    shl ebx,6
    mov ds:[ebx].adm_opc,5
    mov ds:[ebx].adm_flags,0
    mov ds:[ebx].adm_cid,3
    mov ds:[ebx].adm_nsid,0
    mov ds:[ebx].adm_resv,0
    mov ds:[ebx].adm_resv+4,0
    mov ds:[ebx].adm_mptr,0
    mov ds:[ebx].adm_mptr+4,0
;
    mov eax,es:[4*esi].nd_complete_phys
    mov ds:[ebx].adm_prp1,eax
    mov eax,es:[4*esi].nd_complete_phys+4
    mov ds:[ebx].adm_prp1+4,eax
;
    mov ds:[ebx].adm_prp2,0
    mov ds:[ebx].adm_prp2+4,0
;
    movzx eax,es:nd_queue_entries
    dec ax
    shl eax,16
    mov ax,si
    shr ax,1
    inc ax
    mov ds:[ebx].adm_ndt,eax
;
    mov eax,edi
    shl eax,16
    mov ax,3
    mov ds:[ebx].adm_ndm,eax
;
    mov ds:[ebx].adm_cdw12,0
    mov ds:[ebx].adm_cdw13,0
    mov ds:[ebx].adm_cdw14,0
    mov ds:[ebx].adm_cdw15,0
    call AdminSession
;
    popad
    pop ds
    ret
CreateIoCompletionQueue  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ConfigDevice
;
;   DESCRIPTION:    Config device
;
;   PARAMETERS:     ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigDevice  Proc near
    push ds
    pushad
;
    mov ds,es:nd_config_sel
    mov eax,ds:pci_cap+4
    shr eax,16
    mov ah,al
    and al,0Fh
    or al,al
    jnz cdFail
;
    mov al,ah
    shr al,4
    and al,0Fh
;
    mov eax,ds:pci_cap+4
    and al,0Fh
    add al,2
    mov es:nd_door_shift,al
;
    mov eax,ds:pci_cap+4
    test ax,1000h
    jnz cdFail
;
    test al,20h
    jz cdFail
;
    mov eax,ds:pci_cap
    cmp ax,3Fh 
    jbe cdQueueOk
;
    mov ax,3Fh

cdQueueOk:
    add ax,1
    mov es:nd_queue_entries,ax
;
    mov eax,ds:pci_cc
    and al,NOT 1
    mov ds:pci_cc,eax

cdWaitReset:
    mov eax,ds:pci_csts
    test al,1
    jz cdResetDone
;
    mov ax,10
    WaitMilliSec
    jmp cdWaitReset

cdResetDone:
    xor eax,eax
    mov ds:pci_cc,eax
;
    mov eax,00FF003Fh
    mov ds:pci_aqa,eax
;
    mov eax,es:nd_admin_submit_phys
    mov ds:pci_asq,eax
    mov eax,es:nd_admin_submit_phys+4
    mov ds:pci_asq+4,eax
;
    mov eax,es:nd_admin_complete_phys
    mov ds:pci_acq,eax
    mov eax,es:nd_admin_complete_phys+4
    mov ds:pci_acq+4,eax
;
    push es
    mov es,es:nd_admin_submit_sel
    xor edi,edi
    xor eax,eax
    mov ecx,400h
    rep stos dword ptr es:[edi]
    pop es
;
    push es
    mov es,es:nd_admin_complete_sel
    xor edi,edi
    xor eax,eax
    mov ecx,400h
    rep stos dword ptr es:[edi]
    pop es
;
    mov eax,ds:pci_cc
    or al,1
    mov ds:pci_cc,eax

cdWaitStart:
    mov eax,ds:pci_csts
    test al,1
    jnz cdStartDone
;
    mov ax,10
    WaitMilliSec
    jmp cdWaitStart

cdStartDone:
    mov es:nd_admin_submit_ptr,0
    mov es:nd_admin_complete_ptr,0
    clc
    jmp cdDone

cdFail:
    stc

cdDone:
    popad
    pop ds
    ret
ConfigDevice  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddDevice
;
;   DESCRIPTION:    Add device
;
;   PARAMETERS:     BH      PCI Bus
;                   BL      PCI Device
;                   CH      PCI Function
;
;   RETURNS:        ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice  Proc near
    push ds
    pushad
;
    mov ax,SEG data
    mov ds,eax
;
    mov eax,SIZE nvme_device_struc
    AllocateSmallGlobalMem
    mov si,ds:nvme_dev_count
    shl si,1
    mov ds:[si].nvme_dev_arr,es
;
    mov es:nd_pci_bus,bh
    mov es:nd_pci_device,bl
    mov es:nd_pci_function,ch
;
    mov eax,2000h    
    AllocateBigLinear
;
    mov cl,10h
    ReadPciDword
    test al,4
    jz ad32
;
    push eax
    mov cl,14h
    ReadPciDword
    mov ebx,eax
    pop eax
    jmp adAlloc

ad32:
    xor ebx,ebx

adAlloc:
    and ax,0F000h
    mov al,13h
    SetPageEntry
;
    add edx,1000h
    add eax,1000h
    adc ebx,0
    SetPageEntry
    sub edx,1000h
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es:nd_config_sel,bx
;
    add edx,1000h
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es:nd_door_sel,bx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    xor al,al
    mov es:nd_admin_submit_phys,eax
    mov es:nd_admin_submit_phys+4,ebx
;
    mov al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es:nd_admin_submit_sel,bx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    xor al,al
    mov es:nd_admin_complete_phys,eax
    mov es:nd_admin_complete_phys+4,ebx
;
    mov al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es:nd_admin_complete_sel,bx
    clc
;
    popad
    pop ds
    ret
AddDevice   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup device ints
;
;           PARAMETERS:     ES     Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts Proc near
    push ds
    push es
    pushad
;
    mov bh,es:nd_pci_bus
    mov bl,es:nd_pci_device
    mov ch,es:nd_pci_function
    GetPciMsi
    jc siIrq
;
    cmp dl,1
    je siAllocOne
;

siAllocOne:
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc siIrq    

siMsiHandlers:
    SetupPciMsi
;
    mov edx,es
    mov ds,edx
    mov edx,cs
    mov es,edx
    mov edi,OFFSET NvmeInt
    RequestMsiHandler
    jmp siOk

siIrq:
    GetPciIrqNr
    mov ah,14h
    mov eax,es
    mov ds,eax
    mov eax,cs
    mov es,eax
    mov edi,OFFSET NvmeInt
    RequestIrqHandler

siOk:    
    clc
    popad
    pop es
    pop ds
    ret
SetupInts Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupDevice
;
;   DESCRIPTION:    Setup device
;
;   RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DevName DB 'NVMe', 0

SetupDevice  Proc near
    xor ax,ax
    mov bh,1
    mov bl,8
    FindPciClass
    jc sdDone
;
    mov eax,cs
    mov es,eax
    mov edi,OFFSET DevName
    PciPowerOn
;
    call AddDevice
    jc sdDone
;
    call ConfigDevice
    jc sdDone
;
    call SetupInts
    jc sdDone
;
    int 3
    call GetId1
    jc sdDone
;
    mov eax,1
    call GetId0
;
    call GetQueueCount
    jc sdDone
;
    mov ax,1
    mov dl,0
    call CreateIoCompletionQueue
    jc sdDone

sdDone:
    ret
SetupDevice Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_nvme
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_nvme    Proc far
    push ds
    push es
    pushad
;
    call SetupDevice
    jc inDone

inDone:
    popad
    pop es
    pop ds
    ret
init_nvme    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
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
    mov ds,eax
    mov es,eax
    mov ds:nvme_dev_count,0
;
    mov ax,cs
    mov es,ax
    mov ds,ax
    mov edi,OFFSET init_nvme
    HookInitPci
;    
    clc
    ret
init    ENDP

code    ENDS

    END init
