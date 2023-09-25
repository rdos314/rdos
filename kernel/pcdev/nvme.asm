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
INCLUDE ..\os\memblk.inc

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

ns_mem_blk               mem_blk_header <>

ns_sectors               DD ?,?
ns_nsid                  DD ?
ns_bytes_per_sector      DW ?
ns_nvmsetid              DW ?

ns_dev_sel               DW ?
ns_queue_entries         DW ?

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

NVME_DISC_DOOR   = 1000h
NVME_DISC_RD     = 2000h
NVME_DISC_WR     = 3000h
NVME_DISC_COMPL  = 4000h
NVME_DISC_SIZE   = 5000h

;
; NVME device
;

nvme_device_struc   STRUC

nd_admin_submit_phys     DD ?,?
nd_admin_complete_phys   DD ?,?
nd_door_phys             DD ?,?

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

nd_vendor                DB 41 DUP(?)

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
;
    mov esi,OFFSET id1_mn
    mov edi,OFFSET nd_vendor
    mov ecx,10
    rep movs dword ptr es:[edi],gs:[esi]
    jmp gid1NameEnd

gid1NameLoop:
    mov al,es:[edi]
    cmp al,' '
    jne gid1NameOk

gid1NameEnd:
    xor al,al
    mov es:[edi],al
    dec edi
    cmp edi,OFFSET nd_vendor
    jne gid1NameLoop

gid1Nameok:
    clc

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
    mov eax,gs:id0_ncap
    or eax,gs:id0_ncap+4
    stc
    jz gid0Done
;
    push es
;
    mov ax,64
    mov si,SIZE ns_struc
    mov cx,16
    CreateMemBlk64
;
    mov es:ns_complete_ptr,0
    mov es:ns_rd_head,0
    mov es:ns_rd_tail,0
    mov es:ns_wr_head,0
    mov es:ns_wr_tail,0
    mov es:ns_complete_queue,0
    mov es:ns_rd_queue,0
    mov es:ns_wr_queue,0
;
    mov es:ns_nsid,ebp
    mov eax,gs:id0_ncap
    mov es:ns_sectors,eax
    mov eax,gs:id0_ncap+4
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
    mov esi,es:mblk_linear_base
;
    mov eax,NVME_DISC_SIZE
    AllocateBigLinear
    mov edi,edx
;
    mov edx,esi
    GetPageEntry
    mov edx,edi
    SetPageEntry
;
    mov edx,esi
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,1000h
    FreeLinear
;
    mov ebx,es
    mov edx,edi
    mov ecx,NVME_DISC_SIZE
    CreateDataSelector16
    mov fs,ebx
    mov fs:mblk_linear_base,edx
;
    pop es
;
    mov eax,es:nd_door_phys
    mov ebx,es:nd_door_phys+4
    add edx,NVME_DISC_DOOR
    mov al,13h
    SetPageEntry
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
;                   FS      Disc sel
;                   AL      Interrupt #
;                   BL      Queue # (1..QN)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIoCompletionQueue  Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    push ebx
    push eax
;
    mov edx,fs:mblk_linear_base
    add edx,NVME_DISC_COMPL
;
    AllocatePhysical64
    mov esi,eax
    mov edi,ebx
;
    mov al,3
    SetPageEntry
;
    push es
    push edi
;
    mov eax,fs
    mov es,eax
    mov edi,NVME_DISC_COMPL
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
;
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
;                   FS      Disc sel
;                   AX      Set id
;                   BL      Queue # (1..QN)
;                   BH      Completion queue (1..QN)
;                   EDX     Queue offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIoSubmissionQueue  Proc near
    push ds
    push ebx
    push ecx
    push edx
    push esi
    push edi
;
    push ebx
    push eax
;
    push edx
;
    add edx,fs:mblk_linear_base
;
    AllocatePhysical64
    mov esi,eax
    mov edi,ebx
;
    mov al,3
    SetPageEntry
;
    pop edx
;
    push es
    push edi
;
    mov eax,fs
    mov es,eax
    mov edi,edx
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
;
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
    mov fs:ns_complete_ptr,0
;
    xchg bl,bh
    mov ax,fs:ns_nvmsetid
    mov edx,NVME_DISC_RD
    call CreateIoSubmissionQueue
    jc cnsDone
;
    mov fs:ns_rd_queue,bl
    mov fs:ns_rd_head,0
    mov fs:ns_rd_tail,0
;
    inc bl
    mov ax,fs:ns_nvmsetid
    mov edx,NVME_DISC_WR
    call CreateIoSubmissionQueue
    jc cnsXchg
;
    mov fs:ns_wr_queue,bl
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
    mov es:nd_door_phys,eax
    mov es:nd_door_phys+4,ebx
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
    movzx ebx,fs:ns_rd_tail
    mov cl,fs:ns_submit_shift
    shl ebx,cl
    add ebx,NVME_DISC_RD
;
    mov fs:[ebx].sub_opc,2
    mov fs:[ebx].sub_flags,0
    mov fs:[ebx].sub_cid,15
    mov ecx,fs:ns_nsid
    mov fs:[ebx].sub_nsid,ecx
    mov fs:[ebx].sub_cdw2,0
    mov fs:[ebx].sub_cdw2+4,0
    mov fs:[ebx].sub_mptr,0
    mov fs:[ebx].sub_mptr+4,0
;
    mov fs:[ebx].sub_prp1,esi
    mov fs:[ebx].sub_prp1+4,edi
;
    mov fs:[ebx].sub_prp2,0
    mov fs:[ebx].sub_prp2+4,0
    mov fs:[ebx].sub_cdw10,eax
    mov fs:[ebx].sub_cdw11,edx
    mov fs:[ebx].sub_cdw12,8
    mov fs:[ebx].sub_cdw13,0
    mov fs:[ebx].sub_cdw14,0
    mov fs:[ebx].sub_cdw15,0
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
    mov cl,fs:ns_door_shift
    movzx ebx,fs:ns_rd_queue
    add ebx,ebx
    shl ebx,cl
    add ebx,NVME_DISC_DOOR
    mov fs:[ebx],eax
;
    movzx ebx,fs:ns_complete_ptr
    mov cl,fs:ns_complete_shift
    shl ebx,cl
    add ebx,NVME_DISC_COMPL

rsCompCheck:
    mov ax,fs:[ebx].comp_status
    test al,1
    jnz rsCompDone
;
    mov ax,10
    WaitMilliSec
    jmp rsCompCheck

rsCompDone:
    mov ax,fs:[ebx].comp_sq_id
    cmp al,fs:ns_rd_queue
    jne rsCheckWr
;
    mov ax,fs:[ebx].comp_sq_head
    mov fs:ns_rd_head,ax
    jmp rsHandled

rsCheckWr:
    cmp al,fs:ns_wr_queue
    jne rsHandled
;
    mov ax,fs:[ebx].comp_sq_head
    mov fs:ns_wr_head,ax

rsHandled:
    xor dx,dx
    xchg dx,fs:[ebx].comp_status
;
    movzx eax,fs:ns_complete_ptr
    inc eax
    cmp ax,fs:ns_queue_entries
    jb rsComUpd
;
    xor eax,eax

rsComUpd:
    mov fs:ns_complete_ptr,ax
;
    mov cl,fs:ns_door_shift
    movzx ebx,fs:ns_rd_queue
    add ebx,ebx
    inc ebx
    shl ebx,cl
    add ebx,NVME_DISC_DOOR
    mov fs:[ebx],eax
;
    shr dx,1
    or dx,dx
    stc
    jnz rsDone
;
    clc

rsDone:
    popad
    pop es
    ret
ReadSector   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitVfs
;
;       DESCRIPTION:    Init disc
;
;       PARAMETERS:     BX           Disc selector
;
;       RETURNS:        NC
;                         EDX:EAX    Sectors
;                         CX         Bytes per sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitVfs   Proc far
    int 3
    ret
InitVfs    Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ExitVfs
;
;       DESCRIPTION:    Exit VFS
;
;       PARAMETERS:     BX           Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ExitVfs   Proc far
    int 3
    ret
ExitVfs  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetVfsVendor
;
;       DESCRIPTION:    Get vendor
;
;       PARAMETERS:     BX           Disc selector
;                       ES:EDI       Vendor buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


GetVfsVendor   Proc far
    int 3
    ret
GetVfsVendor  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetBiosVfs
;
;       DESCRIPTION:    Get BIOS VFS parameters
;
;       PARAMETERS:     BX           Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


GetBiosVfs   Proc far
    stc
    ret
GetBiosVfs  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadVfs
;
;       DESCRIPTION:    Read sectors
;
;       PARAMETERS:     BX          Disc selector
;                       ECX         Sector count
;                       EDX:EAX     Start sector
;                       ES:EDI      Physical entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadVfs      Proc far
    int 3
    ret
ReadVfs  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteVfs
;
;       DESCRIPTION:    Write sectors
;
;       PARAMETERS:     BX          Disc selector
;                       CX          Sector count
;                       EDX:EAX     Start sector
;                       ES:EDI      Physical entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteVfs      Proc far
    int 3
    ret
WriteVfs  Endp

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
;   NAME:           SetupDevice
;
;   DESCRIPTION:    Setup device
;
;   RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DevName DB 'NVMe', 0

vfs_tab:
vfs00   DD OFFSET InitVfs,        DD SEG code
vfs01   DD OFFSET GetVfsVendor,   DD SEG code
vfs02   DD OFFSET ExitVfs,        DD SEG code
vfs03   DD OFFSET GetBiosVfs,     DD SEG code
vfs04   DD OFFSET ReadVfs,        DD SEG code
vfs05   DD OFFSET WriteVfs,       DD SEG code

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
    mov eax,es
    mov ds,eax
    movzx ecx,ds:nd_nsid_count
    mov ebx,OFFSET nd_nsid_arr
    xor dx,dx

sdNameLoop:
    mov ax,ds:[ebx]
    or ax,ax
    jz sdNameNext
;
    mov eax,100h
    AllocateSmallGlobalMem
;
    xor edi,edi
    mov esi,OFFSET DevName

sdCopyDev:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz sdCopyDone
;
    stos byte ptr es:[edi]
    jmp sdCopyDev

sdCopyDone:
    mov al,' '
    stos byte ptr es:[edi]
;
    push ds
    mov ax,SEG data
    mov ds,eax
    mov ax,ds:nvme_dev_count
    pop ds
    call HexToAscii
    stos word ptr es:[edi]
;
    mov al,'.'
    stos byte ptr es:[edi]
;
    mov ax,dx
    call HexToAscii
    stos word ptr es:[edi]
;
    xor al,al
    stos byte ptr es:[edi]
;
    push ds    
    push ebx
    push edx
;
    xor edi,edi
    mov bx,ds:[ebx]
    mov edx,cs
    mov ds,edx
    mov esi,OFFSET vfs_tab
    StartVfs
;
    pop edx
    pop ebx
    pop ds
;
    FreeMem

sdNameNext:
    add ebx,2
    inc dx
    sub ecx,1
    jnz sdNameLoop

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
