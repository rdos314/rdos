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
INCLUDE ..\acpi\pci.inc

MAX_NVME_DEVICES    = 16
MAX_NSID            = 8

;
; PCI BAR 0 config
;

pci_config  STRUC

pci_cap         DD ?,?
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

sub_struc       STRUC

sub_opc         DB ?
sub_flags       DB ?
sub_cid         DW ?
sub_nsid        DD ?
sub_cdw2        DD ?
sub_cdw3        DD ?
sub_mptr        DD ?,?
sub_prp1        DD ?,?
sub_prp2        DD ?,?
sub_cdw10       DD ?
sub_cdw11       DD ?
sub_cdw12       DD ?
sub_cdw13       DD ?
sub_cdw14       DD ?
sub_cdw15       DD ?

sub_struc       ENDS

adm_struc       STRUC

adm_opc         DB ?
adm_flags       DB ?
adm_cid         DW ?
adm_nsid        DD ?
adm_resv        DD ?,?
adm_mptr        DD ?,?
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
ns_prp_phys              DD ?,?
ns_nsid                  DD ?
ns_bytes_per_sector      DW ?
ns_nvmsetid              DW ?

ns_thread                DW ?

ns_dev_sel               DW ?
ns_submit_entries        DW ?
ns_complete_entries      DW ?

ns_complete_ptr          DW ?
ns_submit_head           DW ?
ns_submit_tail           DW ?

ns_queue                 DB ?

ns_door_shift            DB ?
ns_submit_shift          DB ?
ns_complete_shift        DB ?
ns_complete_bit          DB ?

ns_struc       ENDS

NVME_DISC_DOOR    = 1000h
NVME_DISC_SUB     = 2000h
NVME_DISC_COMPL   = 3000h
NVME_DISC_PRPLIST = 4000h
NVME_DISC_SIZE    = 5000h

;
; NVME device
;

nvme_device_struc   STRUC

nd_admin_submit_phys     DD ?,?
nd_admin_complete_phys   DD ?,?
nd_door_phys             DD ?,?

nd_thread                DW ?
nd_config_sel            DW ?
nd_door_sel              DW ?
nd_admin_submit_sel      DW ?
nd_admin_complete_sel    DW ?

nd_admin_submit_ptr      DW ?
nd_admin_complete_ptr    DW ?

nd_submit_entries        DW ?
nd_complete_entries      DW ?

nd_submit_queues         DW ?
nd_complete_queues       DW ?

nd_nsid_count            DW ?
nd_nsid_arr              DW MAX_NSID DUP(?)

nd_pci_handle            DW ?

nd_complete_bit          DB ?

nd_door_shift            DB ?
nd_submit_shift          DB ?
nd_complete_shift        DB ?

nd_int_count             DB ?
nd_curr_index            DB ?

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
;       NAME:           NvmeAdminInt
;
;       DESCRIPTION:    Admin IRQ handler
;
;       PARAMETERS:     DS      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NvmeAdminInt  Proc far
    mov bx,ds:nd_thread
    Signal
    ret
NvmeAdminInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NvmeInt
;
;       DESCRIPTION:    IRQ handler
;
;       PARAMETERS:     DS      Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NvmeInt  Proc far
    mov bx,ds:ns_thread
    Signal
    ret
NvmeInt  Endp

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
    mov ds,es:nd_door_sel
    xor ebx,ebx
    mov ds:[ebx],eax
;
    mov ds,es:nd_admin_complete_sel
    movzx ebx,es:nd_admin_complete_ptr
    shl ebx,4

asCompCheck:
    mov ax,ds:[ebx].comp_status
    xor al,es:nd_complete_bit
    test al,1
    jnz asCompOk
;
    WaitForSignal
    jmp asCompCheck

asCompOk:
    cmp cx,ds:[ebx].comp_cid
    stc
    jne asDone
;
    mov cx,ds:[ebx].comp_status
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
    xor es:nd_complete_bit,1

asCompUpd:
    mov es:nd_admin_complete_ptr,ax
;
    push ecx
    mov ds,es:nd_door_sel
    mov ebx,1
    mov cl,es:nd_door_shift
    shl ebx,cl
    mov ds:[ebx],eax
    pop ecx
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
    mov eax,gs:id0_nsze
    or eax,gs:id0_nsze+4
    stc
    jz gid0Done
;
    push es
;
    mov eax,NVME_DISC_SIZE
    AllocateGlobalMem
;
    mov es:ns_complete_ptr,0
    mov es:ns_submit_head,0
    mov es:ns_submit_tail,0
    mov es:ns_queue,0
    mov es:ns_complete_bit,0
;
    mov es:ns_nsid,ebp
    mov eax,gs:id0_nsze
    mov es:ns_sectors,eax
    mov eax,gs:id0_nsze+4
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
;
    pop es
;
    mov ebx,fs
    GetSelectorBaseSize
    add edx,NVME_DISC_DOOR
    mov eax,es:nd_door_phys
    mov ebx,es:nd_door_phys+4
    mov al,13h
    SetPageEntry
;
    sub edx,NVME_DISC_DOOR
    add edx,NVME_DISC_PRPLIST
    AllocatePhysical64
    mov fs:ns_prp_phys,eax
    mov fs:ns_prp_phys+4,ebx
;
    mov al,3
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
    mov ax,es:nd_submit_entries
    mov fs:ns_submit_entries,ax
;
    mov ax,es:nd_complete_entries
    mov fs:ns_complete_entries,ax
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
    mov ebx,fs
    GetSelectorBaseSize
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
    movzx eax,es:nd_complete_entries
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
;                   BL      Queue # (1..QN)
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
;
    mov ebx,fs
    GetSelectorBaseSize
    add edx,NVME_DISC_SUB
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
    mov edi,NVME_DISC_SUB
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop edi
    pop es
;
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
    movzx eax,es:nd_submit_entries
    dec ax
    shl eax,16
    movzx ax,cl
    mov ds:[ebx].adm_ndt,eax
;
    movzx eax,cl
    shl eax,16
    mov ax,1
    mov ds:[ebx].adm_ndm,eax
;
    movzx eax,fs:ns_nvmsetid
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
;                   BL      Queue #
;                   DX      NSID
;
;    RETURNS:       AX      Namespace sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateNameSpace  Proc near
    push fs
;
    mov al,es:nd_int_count
    or al,al
    stc
    jz cnsDone
;
    mov ax,dx
    call GetId0
    jc cnsDone
;
    push ds
    push es
    push eax
    push ebx
    push edx
    push edi
;
    mov bx,es:nd_pci_handle
    movzx dx,es:nd_curr_index
    mov eax,fs
    mov ds,eax
    mov eax,cs
    mov es,eax
    mov edi,OFFSET NvmeInt
    SetupPciHandleMsi
;
    pop edi
    pop edx
    pop ebx
    pop eax
    pop es
    pop ds
;
    mov al,es:nd_curr_index
    call CreateIoCompletionQueue
    jc cnsDone
;
    dec es:nd_int_count
    inc es:nd_curr_index
;
    mov fs:ns_queue,bl
    mov fs:ns_complete_ptr,0
;
    mov ax,fs:ns_nvmsetid
    call CreateIoSubmissionQueue
    jc cnsDone
;
    mov fs:ns_submit_head,0
    mov fs:ns_submit_tail,0
;
    inc bl
    mov ax,fs
    clc

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
    cmp ax,1Fh 
    jbe cdSubQueueOk
;
    mov ax,1Fh

cdSubQueueOk:
    add ax,1
    mov es:nd_submit_entries,ax
;
    mov eax,ds:pci_cap
    cmp ax,2Fh 
    jbe cdCompQueueOk
;
    mov ax,2Fh

cdCompQueueOk:
    add ax,1
    mov es:nd_complete_entries,ax
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
    mov eax,-1
    mov ds:pci_intmc,eax
;
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
;   NAME:           CreateDevice
;
;   DESCRIPTION:    Create device
;
;   PARAMETERS:     BX          PCI handle
;                   EDX:EAX     Physical address
;
;   RETURNS:        ES          Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDevice  Proc near
    push ds
    pushad
;
    push eax
;
    mov ax,SEG data
    mov ds,eax
    mov eax,SIZE nvme_device_struc
    AllocateSmallGlobalMem
;
    pop eax
;
    mov es:nd_pci_handle,bx
    mov es:nd_complete_bit,0
;
    push edx
    push eax
;
    mov eax,2000h    
    AllocateBigLinear
;
    pop eax
    pop ebx
;
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

cdExit:
    popad
    pop ds
    ret
CreateDevice   Endp

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
    mov bx,es:nd_pci_handle
    GetPciHandleMsiX
    jc siCheckMsi
;
    cmp al,1
    ja siMulti

siCheckMsi:    
    GetPciHandleMsi
    jc siDone
;
    cmp al,1
    jbe siDone

siMulti:
    mov ah,14h
    movzx cx,al
    ReqPciHandleMsi    
    jc siDone
;
    dec cl
    mov es:nd_int_count,cl
    mov es:nd_curr_index,1
;
    push es
    mov edx,es
    mov ds,edx
    mov edx,cs
    mov es,edx
    mov edi,OFFSET NvmeAdminInt
    xor dx,dx
    SetupPciHandleMsi
    pop es
;
    clc

siDone:
    popad
    pop es
    pop ds
    ret
SetupInts Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupPrp
;
;       DESCRIPTION:    Setup PRP field
;
;       PARAMETERS:     DS:EBX           Submit descriptor
;                       ES:EDI           Physical sector array
;                       ECX              Sector count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupPrp   Proc near
    mov esi,NVME_DISC_PRPLIST
    movzx ebp,ds:ns_bytes_per_sector
;
    mov eax,es:[edi]
    mov edx,es:[edi+4]
    mov ds:[ebx].sub_prp1,eax
    mov ds:[ebx].sub_prp1+4,edx

PrpNext:
    add edi,8
    sub ecx,1
    jz PrpSetup
;
    mov eax,es:[edi]
    mov edx,es:[edi+4]
    test ax,0FFFh
    jnz PrpNext

PrpSave:
    mov ds:[esi],eax
    mov ds:[esi+4],edx
    add esi,8
    jmp PrpNext

PrpSetup:
    sub esi,NVME_DISC_PRPLIST
    mov eax,esi
    mov esi,NVME_DISC_PRPLIST
    or eax,eax
    je PrpDone
;
    cmp eax,8
    je PrpTwo

PrpList:
    mov eax,ds:ns_prp_phys
    mov edx,ds:ns_prp_phys+4
    mov ds:[ebx].sub_prp2,eax
    mov ds:[ebx].sub_prp2+4,edx
    jmp PrpDone

PrpTwo:
    mov eax,ds:[esi]
    mov edx,ds:[esi+4]
    mov ds:[ebx].sub_prp2,eax
    mov ds:[ebx].sub_prp2+4,edx

PrpDone:
    ret
SetupPrp   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForCompletion
;
;       DESCRIPTION:    Wait for completion
;
;       PARAMETERS:     DS          Disc sel
;
;       RETURNS:        CY
;                         AX        Error code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion   Proc near
    movzx eax,ds:ns_submit_tail
    inc eax
    cmp ax,ds:ns_submit_entries
    jb wfcSubUpd
;
    xor eax,eax

wfcSubUpd:
    mov ds:ns_submit_tail,ax
;
    mov cl,ds:ns_door_shift
    movzx ebx,ds:ns_queue
    add ebx,ebx
    shl ebx,cl
    add ebx,NVME_DISC_DOOR
    mov ds:[ebx],eax

wfcWait:
    movzx ebx,ds:ns_complete_ptr
    mov cl,ds:ns_complete_shift
    shl ebx,cl
    add ebx,NVME_DISC_COMPL

wfcCheck:
    mov ax,ds:[ebx].comp_status
    xor al,ds:ns_complete_bit
    test al,1
    jnz wfcValidate
;
    WaitForSignal
    jmp wfcCheck

wfcValidate:
    mov ax,ds:[ebx].comp_sq_id
    cmp al,ds:ns_queue
    jne wfcFatal
;
    mov ax,ds:[ebx].comp_sq_head
    mov ds:ns_submit_head,ax
    jmp wfcHandled

wfcFatal:
    int 3
    stc

wfcHandled:
    mov dx,ds:[ebx].comp_status
;
    movzx eax,ds:ns_complete_ptr
    inc eax
    cmp ax,ds:ns_complete_entries
    jb wfcComUpd
;
    xor eax,eax
    xor ds:ns_complete_bit,1

wfcComUpd:
    mov ds:ns_complete_ptr,ax

wfcUpdate:
    mov cl,ds:ns_door_shift
    movzx ebx,ds:ns_queue
    add ebx,ebx
    inc ebx
    shl ebx,cl
    add ebx,NVME_DISC_DOOR
    mov ds:[ebx],eax
;
    mov ax,dx
    shr ax,1
    or ax,ax
    clc
    jz wfcDone
;
    int 3
    stc

wfcDone:
    ret
WaitForCompletion   Endp
 
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
;                         BX         Max sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitVfs   Proc far
    push ds
;
    mov ds,ebx
    GetThread
    mov ds:ns_thread,ax
;
    mov eax,200000h
    xor edx,edx
    movzx ecx,ds:ns_bytes_per_sector
    div ecx
    dec ax
    mov bx,ax
;
    mov eax,ds:ns_sectors
    mov edx,ds:ns_sectors+4
    mov cx,ds:ns_bytes_per_sector
;
    pop ds
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
    push ds
    push esi
    push edi
;
    mov ds,ebx
    mov ds,ds:ns_dev_sel
    mov esi,OFFSET nd_vendor

gvvLoop:
    lods byte ptr ds:[esi]
    stos byte ptr es:[edi]
    or al,al
    jnz gvvLoop
;
    pop edi
    pop esi
    pop ds
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
    push ds
    pushad
;
    push ecx
    mov ds,ebx
    movzx ebx,ds:ns_submit_tail
    mov cl,ds:ns_submit_shift
    shl ebx,cl
    add ebx,NVME_DISC_SUB
    pop ecx
;
    mov ds:[ebx].sub_opc,2
    mov ds:[ebx].sub_cid,15
    mov ds:[ebx].sub_cdw10,eax
    mov ds:[ebx].sub_cdw11,edx
    mov eax,ecx
    dec eax
    mov ds:[ebx].sub_cdw12,eax
;
    mov eax,ds:ns_nsid
    mov ds:[ebx].sub_nsid,eax
;
    call SetupPrp
    call WaitForCompletion
;
    popad
    pop ds
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
    push ds
    pushad
;
    push ecx
    mov ds,ebx
    movzx ebx,ds:ns_submit_tail
    mov cl,ds:ns_submit_shift
    shl ebx,cl
    add ebx,NVME_DISC_SUB
    pop ecx
;
    mov ds:[ebx].sub_opc,1
    mov ds:[ebx].sub_cid,16
    mov ds:[ebx].sub_cdw10,eax
    mov ds:[ebx].sub_cdw11,edx
    mov eax,ecx
    dec eax
    mov ds:[ebx].sub_cdw12,eax
;
    mov eax,ds:ns_nsid
    mov ds:[ebx].sub_nsid,eax
;
    call SetupPrp
    call WaitForCompletion
;
    popad
    pop ds
    ret
WriteVfs  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsStaticVfs
;
;       DESCRIPTION:    Check for static disc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsStaticVfs      Proc far
    clc
    ret
IsStaticVfs      Endp

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
;   NAME:           NVMe thread
;
;   DESCRIPTION:    NVMe config thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

nvme_thread:
    mov es,ebx
;
    GetThread
    mov es:nd_thread,ax
;
    push ebx
    mov bx,es:nd_pci_handle
    EnablePciHandleMsi
    pop ebx
;
    call GetId1
    jc ntDone
;
    call GetQueueCount
    jc ntDone
;
    mov edi,OFFSET nd_nsid_arr
    mov bl,1
    mov dx,1

ntMore:
    call CreateNameSpace
    jnc ntSave
;
    xor ax,ax

ntSave:
    stos word ptr es:[edi]
    inc dx
    cmp dx,es:nd_nsid_count
    jbe ntMore
;
    mov eax,es
    mov ds,eax
    movzx ecx,ds:nd_nsid_count
    mov ebx,OFFSET nd_nsid_arr
    xor dx,dx

ntNameLoop:
    mov ax,ds:[ebx]
    or ax,ax
    jz ntNameNext
;
    mov eax,100h
    AllocateSmallGlobalMem
;
    xor edi,edi
    mov esi,OFFSET DevName

ntCopyDev:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz ntCopyDone
;
    stos byte ptr es:[edi]
    jmp ntCopyDev

ntCopyDone:
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

ntNameNext:
    add ebx,2
    inc dx
    sub ecx,1
    jnz ntNameLoop
;
    WaitForSignal

ntDone:
    TerminateThread

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
vfs06   DD OFFSET IsStaticVfs,    DD SEG code

SetupDevice  Proc near
    mov ax,SEG data
    mov fs,ax
    mov fs:nvme_dev_count,0
    xor bp,bp

sdLoop:
    mov bx,bp
    mov ah,1
    mov al,8
    FindPciClassHandle
    jc sdDone
;
    xor al,al
    GetPciBarPhys
    jc sdLoop
;
    push eax
    mov eax,cs
    mov es,eax
    mov edi,OFFSET DevName
    LockPciHandle
    pop eax
;
    call CreateDevice
    jc sdNext
;
    call ConfigDevice
    jc sdNext
;
    call SetupInts
    jc sdNext
;
    movzx ebx,fs:nvme_dev_count
    add ebx,ebx
    mov fs:[ebx].nvme_dev_arr,es
    inc fs:nvme_dev_count
;
    mov ebx,es
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
    mov ax,fs:nvme_dev_count
    call HexToAscii
    stos word ptr es:[edi]
;
    xor al,al
    stos byte ptr es:[edi]
;
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET nvme_thread
    xor edi,edi
    mov ax,3
    mov cx,stack0_size
    CreateThread
;
    FreeMem

sdNext:
    jmp sdLoop

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
    EndVfsDisc
;
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
    BeginVfsDisc
;    
    clc
    ret
init    ENDP

code    ENDS

    END init
