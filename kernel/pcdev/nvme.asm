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
MAX_NSID            = 8

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

id0_struc   STRUC

id0_nsze         DD ?,?
id0_ncap         DD ?,?
id0_nuse         DD ?,?
id0_nsfeat       DB ?
id0_nlbaf        DB ?
id0_flbas        DB ?
id0_mc           DB ?
id0_dpc          DB ?
id0_dps          DB ?
id0_nmic         DB ?
id0_rescap       DB ?
id0_fpi          DB ?
id0_dlfeat       DB ?
id0_nawun        DW ?
id0_nawupf       DW ?
id0_nacwu        DW ?
id0_nabsn        DW ?
id0_nabo         DW ?
id0_nabspf       DW ?
id0_noiob        DW ?
id0_nvmcap       DD ?,?,?,?
id0_npwg         DW ?
id0_npwa         DW ?
id0_npdg         DW ?
id0_npda         DW ?
id0_nows         DW ?
id0_mssrl        DW ?
id0_mcl          DD ?
id0_msrc         DB ?
id0_resv1        DB 11 DUP(?)
id0_anagrpid     DD ?
id0_resv2        DB 3 DUP(?)
id0_nsattr       DB ?
id0_nvmsetid     DW ?
id0_endgid       DW ?
id0_nguid        DD ?,?,?,?
id0_eui64        DD ?,?
id0_ms           DW ?
id0_lbads        DB ?
id0_flags        DB ?

id0_struc   ENDS

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
; Name space struc
;

ns_struc       STRUC

ns_sectors               DD ?,?
ns_nsid                  DD ?
ns_bytes_per_sector      DW ?
ns_nvmsetid              DW ?

ns_dev_sel               DW ?
ns_door_sel              DW ?
ns_queue_entries         DW ?

ns_complete_sel          DW ?
ns_rd_sel                DW ?
ns_wr_sel                DW ?

ns_complete_ptr          DW ?
ns_rd_head               DW ?
ns_rd_tail               DW ?
ns_wr_head               DW ?
ns_wr_tail               DW ?

ns_complete_queue        DB ?
ns_rd_queue              DB ?
ns_wr_queue              DB ?

ns_door_shift            DB ?
ns_submit_shift          DB ?
ns_complete_shift        DB ?

ns_struc       ENDS

;
; NVME device
;

nvme_device_struc   STRUC

nd_admin_submit_phys     DD ?,?
nd_admin_complete_phys   DD ?,?

nd_config_sel            DW ?
nd_door_sel              DW ?
nd_admin_submit_sel      DW ?
nd_admin_complete_sel    DW ?

nd_admin_submit_ptr      DW ?
nd_admin_complete_ptr    DW ?

nd_queue_entries         DW ?
nd_submit_queues         DW ?
nd_complete_queues       DW ?

nd_nsid_count            DW ?
nd_nsid_arr              DW MAX_NSID DUP(?)

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
    mov al,3
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
;   RETURNS:        NC
;                       FS  Name space sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetId0  Proc near
    push ds
    push es
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
    mov al,3
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov gs,bx
;
    mov ds,es:nd_admin_submit_sel
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
    mov eax,gs:id0_nuse
    or eax,gs:id0_nuse+4
    stc
    jz gid0Done
;
    push es
    mov eax,SIZE ns_struc
    AllocateSmallGlobalMem
;
    xor edi,edi
    mov ecx,SIZE ns_struc
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov es:ns_nsid,ebp
    mov eax,gs:id0_nuse
    mov es:ns_sectors,eax
    mov eax,gs:id0_nuse+4
    mov es:ns_sectors+4,eax
;
    mov ax,1
    mov cl,gs:id0_lbads
    shl ax,cl
    mov es:ns_bytes_per_sector,ax
;
    mov ax,gs:id0_nvmsetid
    mov es:ns_nvmsetid,ax
;
    mov eax,es
    mov fs,eax
    pop es
;
    mov al,es:nd_submit_shift
    mov fs:ns_submit_shift,al
;
    mov al,es:nd_complete_shift
    mov fs:ns_complete_shift,al
;
    mov al,es:nd_door_shift
    mov fs:ns_door_shift,al
;
    mov ax,es:nd_door_sel
    mov fs:ns_door_sel,ax
;
    mov ax,es:nd_queue_entries
    mov fs:ns_queue_entries,ax
;
    mov fs:ns_dev_sel,es
    clc

gid0Done:
    pushf
    mov eax,gs
    mov es,eax
    xor eax,eax
    mov gs,eax
    FreeMem
    popf
;
    popad
    pop gs
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
;                   AL      Interrupt #
;                   BL      Queue # (1..QN)
;
;   RETURNS:        AX      Queue sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIoCompletionQueue  Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    push ebx
    push eax
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov esi,eax
    mov edi,ebx
;
    mov al,3
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov bp,bx
;
    push es
    push edi
;
    mov es,ebp
    xor edi,edi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop edi
    pop es
;
    pop edx
    pop ecx
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
    mov ds:[ebx].adm_prp1,esi
    mov ds:[ebx].adm_prp1+4,edi
;
    mov ds:[ebx].adm_prp2,0
    mov ds:[ebx].adm_prp2+4,0
;
    movzx eax,es:nd_queue_entries
    dec ax
    shl eax,16
    movzx ax,cl
    mov ds:[ebx].adm_ndt,eax
;
    movzx eax,dl
    shl eax,16
    mov ax,3
    mov ds:[ebx].adm_ndm,eax
;
    mov ds:[ebx].adm_cdw12,0
    mov ds:[ebx].adm_cdw13,0
    mov ds:[ebx].adm_cdw14,0
    mov ds:[ebx].adm_cdw15,0
    call AdminSession
    mov ax,bp
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
CreateIoCompletionQueue  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateIoSubmissionQueue
;
;   DESCRIPTION:    Create IO submission queue
;
;   PARAMETERS:     ES      Device sel
;                   AX      Set id
;                   BL      Queue # (1..QN)
;                   BH      Completion queue (1..QN)
;
;   RETURNS:        AX      Queue sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIoSubmissionQueue  Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
;
    push ebx
    push eax
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov esi,eax
    mov edi,ebx
;
    mov al,3
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov bp,bx
;
    push es
    push edi
;
    mov es,ebp
    xor edi,edi
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop edi
    pop es
;
    pop edx
    pop ecx
;
    mov ds,es:nd_admin_submit_sel
    movzx ebx,es:nd_admin_submit_ptr
    shl ebx,6
    mov ds:[ebx].adm_opc,1
    mov ds:[ebx].adm_flags,0
    mov ds:[ebx].adm_cid,4
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
    movzx eax,es:nd_queue_entries
    dec ax
    shl eax,16
    movzx ax,cl
    mov ds:[ebx].adm_ndt,eax
;
    movzx eax,ch
    shl eax,16
    mov ax,1
    mov ds:[ebx].adm_ndm,eax
;
    movzx eax,dx
    mov ds:[ebx].adm_cdw12,eax
    mov ds:[ebx].adm_cdw13,0
    mov ds:[ebx].adm_cdw14,0
    mov ds:[ebx].adm_cdw15,0
    call AdminSession
    mov ax,bp
;
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ds
    ret
CreateIoSubmissionQueue  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateNameSpace
;
;   DESCRIPTION:    Create namespace
;
;   PARAMETERS:     ES      Device sel
;                   AL      Int #
;                   BL      Completion queue
;                   BH      Submission queue
;                   DX      NSID
;
;    RETURNS:       AX      Namespace sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateNameSpace  Proc near
    push fs
;
    push eax
    mov ax,dx
    call GetId0
    pop eax
    jc cnsDone
;
    call CreateIoCompletionQueue
    jc cnsDone
;
    mov fs:ns_complete_queue,bl
    mov fs:ns_complete_sel,ax
    mov fs:ns_complete_ptr,0
;
    xchg bl,bh
    mov ax,fs:ns_nvmsetid
    call CreateIoSubmissionQueue
    jc cnsDone
;
    mov fs:ns_rd_queue,bl
    mov fs:ns_rd_sel,ax
    mov fs:ns_rd_head,0
    mov fs:ns_rd_tail,0
    mov ax,fs
;
    inc bl
    mov ax,fs:ns_nvmsetid
    call CreateIoSubmissionQueue
    jc cnsXchg
;
    mov fs:ns_wr_queue,bl
    mov fs:ns_wr_sel,ax
    mov fs:ns_wr_head,0
    mov fs:ns_wr_tail,0
    mov ax,fs
    clc

cnsXchg:
    xchg bl,bh

cnsDone:
    pop fs
    ret
CreateNameSpace  Endp

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
    mov es:nd_admin_submit_phys,eax
    mov es:nd_admin_submit_phys+4,ebx
;
    mov al,3
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
    mov al,3
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
;   NAME:           ReadSector
;
;   DESCRIPTION:    Read a sector
;
;   PARAMETERS:     FS        Namespace sel
;                   EDX:EAX   Sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector   Proc near
    push ds
    push es
    pushad
;
    push eax
    push edx
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov esi,eax
    mov edi,ebx
;
    mov al,3
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es,bx
;
    pop edx
    pop eax
;
    mov ds,fs:ns_rd_sel
    movzx ebx,fs:ns_rd_tail
    mov cl,fs:ns_submit_shift
    shl ebx,cl
    mov ds:[ebx].sub_opc,2
    mov ds:[ebx].sub_flags,0
    mov ds:[ebx].sub_cid,15
    mov ecx,fs:ns_nsid
    mov ds:[ebx].sub_nsid,ecx
    mov ds:[ebx].sub_cdw2,0
    mov ds:[ebx].sub_cdw2+4,0
    mov ds:[ebx].sub_mptr,0
    mov ds:[ebx].sub_mptr+4,0
;
    mov ds:[ebx].sub_prp1,esi
    mov ds:[ebx].sub_prp1+4,edi
;
    mov ds:[ebx].sub_prp2,0
    mov ds:[ebx].sub_prp2+4,0
    mov ds:[ebx].sub_cdw10,eax
    mov ds:[ebx].sub_cdw11,edx
    mov ds:[ebx].sub_cdw12,8
    mov ds:[ebx].sub_cdw13,0
    mov ds:[ebx].sub_cdw14,0
    mov ds:[ebx].sub_cdw15,0
;
    movzx eax,fs:ns_rd_tail
    inc eax
    cmp ax,fs:ns_queue_entries
    jb rsSubUpd
;
    xor eax,eax

rsSubUpd:
    mov fs:ns_rd_tail,ax
;
    mov ds,fs:ns_door_sel
    mov cl,fs:ns_door_shift
    movzx ebx,fs:ns_rd_queue
    add ebx,ebx
    shl ebx,cl
    mov ds:[ebx],eax
;
    mov ds,fs:ns_complete_sel
    movzx ebx,fs:ns_complete_ptr
    mov cl,fs:ns_complete_shift
    shl ebx,cl

rsCompCheck:
    mov ax,ds:[ebx].comp_status

;
    popad
    pop es
    pop ds
    ret
ReadSector   Endp

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
    call GetQueueCount
    jc sdDone
;
    mov edi,OFFSET nd_nsid_arr
    mov al,0
    mov bl,1
    mov bh,1
    mov dx,1

sdMore:
    call CreateNameSpace
    jnc sdSave
;
    xor ax,ax

sdSave:
    stos word ptr es:[edi]
    inc dx
    cmp dx,es:nd_nsid_count
    jbe sdMore
;
    mov fs,es:nd_nsid_arr
    xor eax,eax
    xor edx,edx
    call ReadSector

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
