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
; MCAN.ASM
; MCAN-bus driver
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

SIDF_ELEMENT_SIZE = 4
XIDF_ELEMENT_SIZE = 8
RXF0_ELEMENT_SIZE = 16
RXF1_ELEMENT_SIZE = 16
RXB_ELEMENT_SIZE = 16
TXE_ELEMENT_SIZE = 8
TXB_ELEMENT_SIZE = 16

RXF_SHIFT = 4

SIDF_ENTRIES = 16
XIDF_ENTRIES = 0
RXF0_ENTRIES = 64
RXF1_ENTRIES = 64
RXB_ENTRIES = 0
TXE_ENTRIES = 0
TXB_ENTRIES = 32

can_struc   STRUC

can_crel        DD ?
can_endn        DD ?
can_cust        DD ?
can_dbtp        DD ?
can_test        DD ?
can_rwd         DD ?
can_cccr        DD ?
can_btp         DD ?
can_tscc        DD ?
can_tscv        DD ?
can_tocc        DD ?
can_tocv        DD ?
can_resv1       DD ?,?,?,?
can_ecr         DD ?
can_psr         DD ?
can_tdcr        DD ?
can_resv2       DD ?
can_ir          DD ?
can_ie          DD ?
can_ils         DD ?
can_ile         DD ?
can_resv3       DD 8 DUP(?)
can_gfc         DD ?
can_sidfc       DD ?
can_xidfc       DD ?
can_resv4       DD ?
can_xidam       DD ?
can_hpms        DD ?
can_ndat1       DD ?
can_ndat2       DD ?
can_rxf0c       DD ?
can_rxf0s       DD ?
can_rxf0a       DD ?
can_rxbc        DD ?
can_rxf1c       DD ?
can_rxf1s       DD ?
can_rxf1a       DD ?
can_rxesc       DD ?
can_txbc        DD ?
can_txfqs       DD ?
can_txesc       DD ?
can_txbrp       DD ?
can_txbar       DD ?
can_txbcr       DD ?
can_txbto       DD ?
can_txbcf       DD ?
can_txbtie      DD ?
can_txbcie      DD ?
can_resv5       DD ?,?
can_txefc       DD ?
can_txefs       DD ?
can_txefa       DD ?

can_struc  ENDS 

can_dev_struc   STRUC

cd_bar_phys     DD ?,?
cd_bar_linear   DD ?
cd_ram_size     DD ?
cd_irqs         DD ?
cd_pend_tx      DD ?
cd_server       DW ?
cd_reg          DW ?
cd_filter_sel   DW ?
cd_rx0_sel      DW ?
cd_rx1_sel      DW ?
cd_tx_sel       DW ?
cd_tx_notify    DW TXB_ENTRIES DUP(?)

cd_ver          DB ?
cd_rel          DB ?

// ram config settings
cd_sidf_offset  DD ?
cd_sidf_count   DD ?
cd_xidf_count   DD ?
cd_rxf0_count   DD ?
cd_rxf1_count   DD ?
cd_rxb_count    DD ?
cd_txe_count    DD ?
cd_txb_count    DD ?

can_dev_struc   ENDS


capture_block   STRUC

cc_prev     DD ?
cc_next     DD ?
cc_time     DD ?,?
cc_id       DD ?
cc_data     DD ?,?
cc_size     DB ?

capture_block   ENDS


id_hook_struc   STRUC

ih_id       DD ?
ih_mask     DD ?
ih_offset   DD ?
ih_sel      DW ?
ih_param    DW ?

id_hook_struc   ENDS

data    SEGMENT byte public 'DATA'

can_sel                 DW ?
can_thread              DW ?

can_rec_section         section_typ <>
can_send_section        section_typ <>

capture_handle          DW ?
capture_thread          DW ?
capture_list            DD ?
capture_section         section_typ <>

can_id_hook_arr         DD 16 * 4 DUP(?)

can_bar0                DD ?,?

data    ENDS


IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CanInt
;
;   DESCRIPTION:    CAN int
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CanInt   Proc far
    mov es,ds:cd_reg
    mov eax,es:can_ir
    and eax,1FFFFFFFh
    jz ciDone

ciRetry:
    lock or es:can_ir,eax
    or ds:cd_irqs,eax
;
    mov eax,es:can_ir
    and eax,1FFFFFFFh
    jnz ciRetry
;
    mov bx,ds:cd_server
    Signal

ciDone:
    ret
CanInt   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupBitTiming
;
;   DESCRIPTION:    Setup bit timing
;
;   PARAMETERS:     ES      CAN reg sel
;                   AL      TSEG1
;                   AH      TSEG2
;                   CL      Baud divisor
;                   BL      SJW
;
;   RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupBitTiming  Proc near
    pushad
;
    dec cl
    dec bl
    dec ah
    dec al
;
    movzx edx,cl
    shl edx,16
;
    movzx esi,bl
    shl esi,25
    or edx,esi
;
    mov dl,ah
;
    mov dh,al
    mov es:can_btp,edx
;
    popad  
    ret
SetupBitTiming  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           RemapBar
;
;   DESCRIPTION:    Remap BAR with correct size
;
;   PARAMETERS:     DS      CAN sel
;                   ES      Can reg sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemapBar  Proc near
    pushad
;
    mov ecx,SIDF_ENTRIES * SIDF_ELEMENT_SIZE
    add ecx,XIDF_ENTRIES * XIDF_ELEMENT_SIZE
    add ecx,RXF0_ENTRIES * RXF0_ELEMENT_SIZE
    add ecx,RXF1_ENTRIES * RXF1_ELEMENT_SIZE
    add ecx,RXB_ENTRIES * RXB_ELEMENT_SIZE
    add ecx,TXE_ENTRIES * TXE_ELEMENT_SIZE
    add ecx,TXB_ENTRIES * TXB_ELEMENT_SIZE
    mov ds:cd_ram_size,ecx
;
    mov eax,ds:cd_bar_phys
    mov ebx,ds:cd_bar_phys+4
    add eax,ds:cd_sidf_offset
    add ecx,eax
    sub ecx,ds:cd_bar_phys
    dec ecx
    and cx,0F000h
    add ecx,1000h
;
    push ecx
    mov eax,ecx
    AllocateBigLinear
    pop ecx
    mov ds:cd_bar_linear,edx
;
    mov eax,ds:cd_bar_phys
    or ax,813h

rbInitLoop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    sub ecx,1000h
    jnz rbInitLoop
;
    mov bx,ds:cd_reg
    GetSelectorBaseSize
;
    mov ecx,1000h
    FreeLinear
;
    mov ecx,SIZE can_struc
    mov edx,ds:cd_bar_linear
    CreateDataSelector16
    mov es,bx
;
    popad
    ret
RemapBar  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateFilterSel
;
;   DESCRIPTION:    Create filter sel
;
;   PARAMETERS:     DS      CAN sel
;                   EDX     RAM linear
;
;   RETURNS:        EDX     RAM linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFilterSel  Proc near
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    AllocateGdt
    mov ecx,SIDF_ENTRIES * SIDF_ELEMENT_SIZE
    CreateDataSelector16
    mov es,bx
    xor edi,edi
    mov ecx,SIDF_ENTRIES
    mov eax,0FFFFFFFFh
    rep stosd
    mov ds:cd_filter_sel,bx
;
    mov es,ds:cd_reg
    mov eax,SIDF_ENTRIES
    shl eax,16
    mov ecx,edx
    sub ecx,ds:cd_bar_linear
    mov ax,cx
    mov es:can_sidfc,eax
;
    xor eax,eax
    mov es:can_xidfc,eax
;
    add edx,SIDF_ENTRIES * SIDF_ELEMENT_SIZE
;
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
CreateFilterSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateRx0Sel
;
;   DESCRIPTION:    Create rx0 fifo selector
;
;   PARAMETERS:     DS      CAN sel
;                   EDX     RAM linear
;
;   RETURNS:        EDX     RAM linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRx0Sel  Proc near
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    AllocateGdt
    mov ecx,RXF0_ENTRIES * RXF0_ELEMENT_SIZE
    CreateDataSelector16
    mov es,bx
    xor edi,edi
    mov ecx,RXF0_ENTRIES * RXF0_ELEMENT_SIZE / 4
    xor eax,eax
    rep stosd
    mov ds:cd_rx0_sel,bx
;
    mov es,ds:cd_reg
    mov eax,RXF0_ENTRIES
    shl eax,16
    mov ecx,edx
    sub ecx,ds:cd_bar_linear
    mov ax,cx
    mov es:can_rxf0c,eax
;
    add edx,RXF0_ENTRIES * RXF0_ELEMENT_SIZE
;
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
CreateRx0Sel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateRx1Sel
;
;   DESCRIPTION:    Create rx1 fifo selector
;
;   PARAMETERS:     DS      CAN sel
;                   EDX     RAM linear
;
;   RETURNS:        EDX     RAM linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRx1Sel  Proc near
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    AllocateGdt
    mov ecx,RXF1_ENTRIES * RXF1_ELEMENT_SIZE
    CreateDataSelector16
    mov es,bx
    xor edi,edi
    mov ecx,RXF1_ENTRIES * RXF1_ELEMENT_SIZE / 4
    xor eax,eax
    rep stosd
    mov ds:cd_rx1_sel,bx
;
    mov es,ds:cd_reg
    mov eax,RXF1_ENTRIES
    shl eax,16
    mov ecx,edx
    sub ecx,ds:cd_bar_linear
    mov ax,cx
    mov es:can_rxf1c,eax
;
    add edx,RXF1_ENTRIES * RXF1_ELEMENT_SIZE
;
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
CreateRx1Sel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateTxSel
;
;   DESCRIPTION:    Create tx0 fifo selector
;
;   PARAMETERS:     DS      CAN sel
;                   EDX     RAM linear
;
;   RETURNS:        EDX     RAM linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateTxSel  Proc near
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    AllocateGdt
    mov ecx,TXB_ENTRIES * TXB_ELEMENT_SIZE
    CreateDataSelector16
    mov es,bx
    xor edi,edi
    mov ecx,TXB_ENTRIES * TXB_ELEMENT_SIZE / 4
    xor eax,eax
    rep stosd
    mov ds:cd_tx_sel,bx
;
    mov es,ds:cd_reg
    mov eax,TXB_ENTRIES
    shl eax,24
    mov ecx,edx
    sub ecx,ds:cd_bar_linear
    mov ax,cx
    mov es:can_txbc,eax
;
    mov eax,0FFFFFFFFh
    mov es:can_txbtie,eax
    mov es:can_txbcie,eax
;
    add edx,TXB_ENTRIES * TXB_ELEMENT_SIZE
;
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
    ret
CreateTxSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ClearIdFilter
;
;   DESCRIPTION:    Clear ID filter (empty msg)
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearIdFilter  Proc near
    push ds
    push eax
    push ebx
;
    mov ds,es:cd_filter_sel
    dec bx
    shl bx,2
    xor eax,eax
    mov ds:[bx],eax
;
    pop ebx
    pop eax
    pop ds
    ret
ClearIdFilter    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupIdFilter
;
;   DESCRIPTION:    Setup ID filter
;
;   PARAMETERS:     ES      Can sel
;                   BX      Message #
;                   EAX     ID
;                   EDX     Mask
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupIdFilter  Proc near
    push ds
    push eax
    push ebx
    push edx
;
    mov ds,es:cd_filter_sel
    dec bx
;
    shr eax,2
    shr edx,18
    mov ax,dx
    test bx,1
    jz sifEven

sifOdd:
    or eax,88000000h
    jmp sifSave

sifEven:
    or eax,90000000h

sifSave:    
    shl bx,2
    mov ds:[bx],eax
;
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
SetupIdFilter    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupDevice
;
;   DESCRIPTION:    Setup device
;
;   RETURNS:        NC      OK
;                      DS   Can sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DevName DB 'CAN', 0
can_config_name DB 'bosch,mram-cfg', 0

SetupDevice  Proc near
    int 3
    xor bx,bx
    mov ah,0Ch
    mov al,9
    FindPciClassHandle
    jc sdDone
;
    xor al,al
    GetPciBarPhys
    jc sdDone
;
    push ebx
;
    push edx
    push eax
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET DevName
    LockPciHandle
;
    mov eax,1000h    
    AllocateBigLinear
;
    pop eax
    pop ebx
;
    push ebx
    push eax
;
    and ax,0F000h
    or ax,813h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
;
    mov eax,SIZE can_dev_struc
    AllocateSmallGlobalMem
    mov es:cd_reg,bx
;
    pop eax
    pop ebx
;
    mov es:cd_bar_phys,eax
    mov es:cd_bar_phys+4,ebx
;
    push ecx
    push edx
    mov edi,OFFSET cd_tx_notify
    mov ecx,TXB_ENTRIES
    xor ax,ax
    rep stosw
    pop edx
    pop ecx
;    
    pop ebx    
;
    push es
;
    mov al,12h
    mov edi,es
    mov ds,edi
    mov edi,cs
    mov es,edi
    mov edi,OFFSET CanInt
    SetupPciHandleIrq
;
    pop es
;
    mov ax,SEG data
    mov ds,eax
    mov ds:can_sel,es
;
    mov ds,ds:can_sel
    mov ds:cd_sidf_offset,0
    mov ds:cd_sidf_count,0
    mov ds:cd_xidf_count,0
    mov ds:cd_rxf0_count,0
    mov ds:cd_rxf1_count,0
    mov ds:cd_rxb_count,0
    mov ds:cd_txe_count,0
    mov ds:cd_txb_count,0
;
    int 3
    push ds
    mov eax,ds
    mov es,eax
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET can_config_name
    mov edi,OFFSET cd_sidf_offset
    mov eax,8
    GetPciHandleDsdConfig
    pop ds
;
    mov eax,ds:cd_rxf0_count
    or eax,eax
    jz sdFail
;
    mov es,ds:cd_reg
    mov edi,500h
    mov eax,es:[edi+8]
    or eax,eax
    jnz sdIntMapped
;
    mov eax,1
    mov es:[edi+8],eax

sdIntMapped:
    mov eax,es:can_crel
    shr eax,24
    mov ah,al
    and al,0Fh
    mov ds:cd_rel,al
    and ah,0F0h
    shr ah,4
    mov ds:cd_ver,ah
;
    mov al,ds:cd_ver
    cmp al,3
    jne sdFail
;
    mov al,ds:cd_rel
    cmp al,3
    ja sdFail
;
    call RemapBar
    clc
    jmp sdDone

sdFail:
    FreeMem
    mov eax,ds
    mov es,eax
    FreeMem
    stc

sdDone:
    ret
SetupDevice Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           NotifyMsg
;
;   Description:    Notify reception of ethernet packet
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyMsg  Proc near
    push ds
    push si
;
    mov si,SEG data
    mov ds,si
    EnterSection ds:capture_section
    mov si,ds:capture_thread
    or si,si
    jz nmLeave
;    
    push es
    pushad
;    
    push eax
    push edx
    mov dx,flat_sel
    mov es,dx
    mov eax,SIZE capture_block
    AllocateSmallLinear
    mov edi,edx
    GetTime
    mov es:[edi].cc_time,eax
    mov es:[edi].cc_time+4,edx
    pop edx
    pop eax
;    
    mov es:[edi].cc_id,ebx
    mov es:[edi].cc_data,eax
    mov es:[edi].cc_data+4,edx
    mov es:[edi].cc_size,cl
    mov edx,edi
;
    mov bx,SEG data
    mov ds,bx
;
    mov eax,ds:capture_list
    or eax,eax
    jne nmQueue

nmEmpty:
    mov es:[edx].cc_prev,edx
    mov es:[edx].cc_next,edx
    mov ds:capture_list,edx
    jmp nmSignal

nmQueue:
    mov ebx,es:[eax].cc_prev
    mov es:[eax].cc_prev,edx
    mov es:[ebx].cc_next,edx
    mov es:[edx].cc_prev,ebx
    mov es:[edx].cc_next,eax    

nmSignal:
    mov bx,ds:capture_thread
    Signal
;
    popad
    pop es

nmLeave:
    LeaveSection ds:capture_section
;    
    pop si
    pop ds    
    ret
NotifyMsg  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetCanBuffers
;
;   DESCRIPTION:    Reset CAN 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_can_buffers_name   DB 'Reset CAN Buffers', 0

reset_can_buffers    Proc far
    stc
    ret
reset_can_buffers    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendCanBusMsg
;
;   DESCRIPTION:    Send CAN bus message
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_can_bus_msg_name   DB 'Send CAN Bus Message', 0

send_can_bus_msg    Proc far
    push ds
    push es
    push ecx
    push esi
    push edi
    push ebp
;
    call NotifyMsg    
;
    mov ebp,2000
    mov esi,SEG data
    mov ds,esi
    mov es,ds:can_sel
    mov es,es:cd_reg

scbRetry:
    EnterSection ds:can_send_section
;
    mov esi,es:can_txfqs
    and si,3Fh
    or si,si
    jz scbWait
;
    shr esi,16
    test si,20h
    jnz scbFail
    jmp scbOk

scbWait:
    LeaveSection ds:can_send_section
;
    push eax
    mov ax,1
    WaitMilliSec
    pop eax
;
    sub ebp,1
    jnz scbRetry
;
    jmp scbFail

scbOk:
    mov ds,ds:can_sel
;
    mov edi,esi
    and edi,1Fh
    shl edi,4
    mov es,ds:cd_tx_sel
    mov es:[edi],ebx
    add edi,4
;
    movzx ecx,cl
    shl ecx,16
    mov es:[edi],ecx
    add edi,4
;
    mov es:[edi],eax
    add edi,4
;
    mov es:[edi],edx
;
    mov cx,si
    mov esi,1
    shl esi,cl
    mov es,ds:cd_reg
    test esi,es:can_txbar
    jz scbAdd
;
    int 3

scbAdd:
    lock or ds:cd_pend_tx,esi
    mov es:can_txbar,esi
    clc
    jmp scbDone

scbFail:
;    int 3
    stc

scbDone:
    mov esi,SEG data
    mov ds,esi
    LeaveSection ds:can_send_section
;
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop es
    pop ds
    ret
send_can_bus_msg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SendCanBusBlock
;
;   DESCRIPTION:    Send CAN bus message, wait for completion
;
;   PARAMETERS:     EDX:EAX     Data
;                   CL          Size (0..8)
;                   EBX         Identifier
;
;   RETURNS:        NC          Successfully transmitted
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_can_bus_block_name   DB 'Send CAN Bus Message Block', 0

send_can_bus_block    Proc far
    push ds
    push es
    push fs
    push eax
    push ecx
    push esi
    push edi
    push ebp
;
    call NotifyMsg    
;
    mov ebp,2000
    mov esi,SEG data
    mov ds,esi
    mov fs,ds:can_sel
    mov es,fs:cd_reg

scbbRetry:
    EnterSection ds:can_send_section
;
    mov esi,es:can_txfqs
    and si,3Fh
    or si,si
    jz scbbWait
;
    shr esi,16
    test si,20h
    jnz scbbLeaveFail
    jmp scbbOk

scbbWait:
    LeaveSection ds:can_send_section
;
    push eax
    mov ax,1
    WaitMilliSec
    pop eax
;
    sub ebp,1
    jnz scbbRetry
;
    jmp scbbFail

scbbOk:
    mov edi,esi
    and edi,1Fh
    shl edi,4
    mov es,fs:cd_tx_sel
    mov es:[edi],ebx
    add edi,4
;
    movzx ecx,cl
    shl ecx,16
    mov es:[edi],ecx
    add edi,4
;
    mov es:[edi],eax
    add edi,4
;
    mov es:[edi],edx
;
    mov cx,si
    mov esi,1
    shl esi,cl
    mov es,fs:cd_reg
    test esi,es:can_txbar
    jz scbbAdd
;
    int 3
    jmp scbbLeaveFail

scbbAdd:
    movzx ebx,cl
    shl ebx,1
    GetThread
    mov fs:[ebx].cd_tx_notify,ax
;
    lock or fs:cd_pend_tx,esi
    mov es:can_txbar,esi
    LeaveSection ds:can_send_section
;
    mov ebp,200

scbbWC:
    GetSystemTime
    add eax,11930
    adc edx,0
    WaitForSignalWithTimeout
;
    mov ax,fs:[ebx].cd_tx_notify
    or ax,ax
    clc
    jz scbbDone
;
    sub ebp,1
    jnz scbbWC
;
    mov fs:[ebx].cd_tx_notify,0

scbbLeaveFail:
    LeaveSection ds:can_send_section

scbbFail:
;    int 3
    stc

scbbDone:
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop eax
    pop fs
    pop es
    pop ds
    ret
send_can_bus_block    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HasCanSendBuf
;
;   DESCRIPTION:    Check if there is a free send buffer
;
;   RETURNS:        NC      Has buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_can_send_buf_name   DB 'Has CAN Send Buf', 0

has_can_send_buf    Proc far
    push ds
    push eax
;
    mov eax,SEG data
    mov ds,eax
    mov ds,ds:can_sel
    mov ds,ds:cd_reg
    mov eax,ds:can_txfqs
    and ax,3Fh
    or ax,ax
    clc
    jnz hcsbDone
;
    stc

hcsbDone:
    pop eax
    pop ds
    ret
has_can_send_buf    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HookCanBusMsg
;
;   DESCRIPTION:    Register callback for received CAN bus messages
;
;   PARAMETERS:     ES:EDI      Callback
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hook_gen_bus_msg_name   DB 'Hook General CAN Bus Message', 0

hook_gen_bus_msg    Proc far
    int 3
    clc
    ret
hook_gen_bus_msg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateCanIdHook
;
;   DESCRIPTION:    Create an id-based filter hook
;
;   PARAMETERS:     EAX       Identifier 
;                   EDX       Identifier mask
;                   DS        Param
;                   ES:EDI    Hook callback
;                       DS        Param
;                       EDX:EAX   Data
;                       CL        Size (0..8)
;                       EBX       Identifier
;
;   RETURNS:        BX        Buffer #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_id_hook_name   DB 'Create CAN ID Hook', 0

create_id_hook    Proc far
    push ds
    push es
    push ecx
    push esi
    push ebp
;    
    mov ebp,ds
    mov ebx,SEG data
    mov ds,ebx
;
    mov bx,OFFSET can_id_hook_arr
    mov ecx,16

cihLoop:
    mov si,ds:[bx].ih_sel
    or si,si
    jz cihFound
;
    add bx,16        
    loop cihLoop
;
    stc
    jmp cihDone

cihFound:
    EnterSection ds:can_rec_section
    mov ds:[bx].ih_id,eax
    mov ds:[bx].ih_mask,edx
    mov ds:[bx].ih_param,bp
    mov ds:[bx].ih_offset,edi
    mov ds:[bx].ih_sel,es
;            
    sub bx,OFFSET can_id_hook_arr
    shr bx,4
    inc bx
;
    mov es,ds:can_sel
    call SetupIdFilter
    LeaveSection ds:can_rec_section    
    clc
    
cihDone:
    pop ebp
    pop esi
    pop ecx
    pop es
    pop ds    
    ret
create_id_hook    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           DeleteCanIdHook
;
;   DESCRIPTION:    Delete an id-based filter hook
;
;   PARAMETERS:     BX        Buffer #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_id_hook_name   DB 'Delete CAN ID Hook', 0

delete_id_hook    Proc far    
    or bx,bx
    jz dihDone
;
    cmp bx,16
    jae dihDone
;        
    push ds
    push es
    push eax
    push ebx
;    
    mov eax,SEG data
    mov ds,eax
    EnterSection ds:can_rec_section
    mov es,ds:can_sel
    call ClearIdFilter
;    
    dec bx
    shl bx,4
    add bx,OFFSET can_id_hook_arr
    mov ds:[bx].ih_id,0
    mov ds:[bx].ih_mask,0
    mov ds:[bx].ih_param,0
    mov ds:[bx].ih_offset,0
    mov ds:[bx].ih_sel,0
;
    LeaveSection ds:can_rec_section    
;    
    pop ebx
    pop eax
    pop es
    pop ds    
    
dihDone:
    clc
    ret
delete_id_hook    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CaptureThread
;
;           description:    Capture thread
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

capture_thread_name DB 'Can Capture', 0

capture_thread_pr proc far
    mov bx,SEG data
    mov ds,bx
    GetThread
    mov ds:capture_thread,ax
    LeaveSection ds:capture_section
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov bx,ds:capture_handle
    xor eax,eax
    SetFilePos32
    SetFileSize32

ctpLoop:
    WaitForSignal

ctpMore:
    EnterSection ds:capture_section    
    mov ax,ds:capture_thread
    or ax,ax
    jz ctpExit
;
    mov edx,ds:capture_list
    or edx,edx
    jz ctpNext
;
    push ebx
    mov eax,es:[edx].cc_next
    mov ebx,es:[edx].cc_prev
    mov es:[ebx].cc_next,eax
    mov es:[eax].cc_prev,ebx
    pop ebx
    cmp eax,edx
    jne ctpUnlink
;
    mov ds:capture_list,0
    jmp ctpWrite

ctpUnlink:
    mov ds:capture_list,eax

ctpWrite:       
    LeaveSection ds:capture_section
;    
    mov edi,edx
    add edi,OFFSET cc_time
    mov ecx,SIZE capture_block - OFFSET cc_time
    WriteFile
;
    mov ecx,SIZE capture_block
    FreeLinear    
    jmp ctpMore
    
ctpNext:
    LeaveSection ds:capture_section
    jmp ctpLoop

ctpExit:  
    mov ds:capture_thread,0
    LeaveSection ds:capture_section
    ret
capture_thread_pr       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartCanCapture
;
;           description:    Start capturing CAN-packets
;
;       parameters:     BX      File handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_can_capture_name DB 'Start Can Capture', 0

start_can_capture       Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push esi
    push edi
;    
    mov ax,SEG data
    mov ds,eax
    EnterSection ds:capture_section
;
    mov ds:capture_handle,bx
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET capture_thread_pr
    mov edi,OFFSET capture_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;       
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
start_can_capture       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StopCanCapture
;
;           description:    Stop capturing can-packets
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_can_capture_name DB 'Stop Can Capture', 0

stop_can_capture    Proc far
    push ds
    push bx
;    
    mov bx,SEG data
    mov ds,bx
    EnterSection ds:capture_section
    xor bx,bx
    xchg bx,ds:capture_thread
    or bx,bx
    jz sncThreadDone
;    
    Signal
    mov bx,ds:capture_handle
    CloseFile

sncThreadDone:
    mov ds:capture_handle,0
    LeaveSection ds:capture_section    
;
    pop bx
    pop ds    
    ret
stop_can_capture    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleRx
;
;   DESCRIPTION:    Handle RX FIFO
;
;   PARAMETERS:     DS:EBX  Buffer
;                   ES      CAN reg sel
;                   FS      CAN sel
;                   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRx    Proc near
    push ds
    push es
    push eax
    push ecx
    push edx
    push esi
;
    mov eax,SEG data
    mov es,eax
;
    mov al,ds:[ebx+7]
    test al,80h
    jnz hrxDone
;
    movzx esi,al
    shl esi,4
    add esi,OFFSET can_id_hook_arr
;
    mov ax,es:[esi].ih_sel
    or ax,ax
    jz hrxDone
;
    mov cl,ds:[ebx+6]
    and cl,0Fh
    mov eax,ds:[ebx+8]
    mov edx,ds:[ebx+12]
    mov ebx,ds:[ebx]
    mov ds,es:[esi].ih_param
    call NotifyMsg
    call fword ptr es:[esi].ih_offset

hrxDone:
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    pop ds
    ret
HandleRx    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleRx0
;
;   DESCRIPTION:    Handle RX 0 FIFO
;
;   PARAMETERS:     DS      Data
;                   ES      CAN reg sel
;                   FS      CAN sel                   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRx0    Proc near
    push ds
    push ebx
    push edx
;
    mov ds,fs:cd_rx0_sel

hrxLoop0:
    mov edx,es:can_rxf0s
    or dl,dl
    jz hrxDone0
;
    movzx ebx,dh
    shl ebx,RXF_SHIFT
    call HandleRx
;
    movzx eax,dh
    mov es:can_rxf0a,eax
    jmp hrxLoop0

hrxDone0:
    pop edx
    pop ebx
    pop ds
    ret
HandleRx0   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleRx1
;
;   DESCRIPTION:    Handle RX 1 FIFO
;
;   PARAMETERS:     DS      Data
;                   ES      CAN reg sel
;                   FS      CAN sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRx1    Proc near
    push ds
    push ebx
    push edx
;
    mov ds,fs:cd_rx1_sel

hrxLoop1:
    mov edx,es:can_rxf1s
    or dl,dl
    jz hrxDone1
;
    movzx ebx,dh
    shl ebx,RXF_SHIFT
    call HandleRx
;
    movzx eax,dh
    mov es:can_rxf1a,eax
    jmp hrxLoop1

hrxDone1:
    pop edx
    pop ebx
    pop ds
    ret
HandleRx1   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           NotifyTxDone
;
;   DESCRIPTION:    Notify TX done
;
;   PARAMETERS:     DS      Data
;                   ES      CAN reg sel
;                   FS      CAN sel
;                   EBX     FIFO entry
;                   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NotifyTxDone    Proc near
    push ebx
;
    xor ax,ax
    xchg ax,fs:[2*ebx].cd_tx_notify
    or ax,ax
    jz ntdDone
;
    push ebx
    mov ebx,eax
    Signal
    pop ebx

ntdDone:
    pop eax
    ret
NotifyTxDone    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleTxComplete
;
;   DESCRIPTION:    Handle TX complete
;
;   PARAMETERS:     DS      Data
;                   ES      CAN reg sel
;                   FS      CAN sel
;                   EAX     complete mask
;                   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTxComplete    Proc near
    push ebx
    push ecx
;
    and eax,fs:cd_pend_tx
    lock xor fs:cd_pend_tx,eax
;
    xor ebx,ebx
    mov ecx,TXB_ENTRIES

htxcLoop:
    test eax,1
    jz htcxNext
;
    call NotifyTxDone

htcxNext:
    ror eax,1
    inc ebx
    loop htxcLoop
;
    pop ecx
    pop ebx
    ret
HandleTxComplete    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleTxOk
;
;   DESCRIPTION:    Handle TX ok
;
;   PARAMETERS:     DS      Data
;                   ES      CAN reg sel
;                   FS      CAN sel
;                   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTxOk    Proc near
    push eax
;
    EnterSection ds:can_send_section
;
    mov eax,es:can_txbto
    call HandleTxComplete
;
    LeaveSection ds:can_send_section
;
    pop eax
    ret
HandleTxOk    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandleTxCancel
;
;   DESCRIPTION:    Handle TX cancel
;
;   PARAMETERS:     DS      Data
;                   ES      CAN reg sel
;                   FS      CAN sel
;                   
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleTxCancel    Proc near
    push eax
;
    EnterSection ds:can_send_section
;
    mov eax,es:can_txbcf
    call HandleTxComplete
;
    LeaveSection ds:can_send_section
;
    pop eax
    ret
HandleTxCancel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CanThread
;
;           description:    Can thread
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

can_thread_name DB 'Can', 0

can_thread_pr:
    mov ax,SEG data
    mov ds,eax
    EnterSection ds:can_rec_section
;
    mov cl,5    ; divider
    mov al,34   ; TSEG 1
    mov ah,5    ; TSEG 2
    mov bl,1    ; SJW
;
    mov ds,ds:can_sel
    mov es,ds:cd_reg
;
    mov es:can_cccr,3
    mov es:can_ir,3FFFFFFFh
    mov es:can_ie,1FFFFFFFh
    mov es:can_ils,0
    mov es:can_ile,3
;
    call SetupBitTiming
;
    GetThread
    mov ds:cd_server,ax
    mov ds:cd_irqs,0
    mov ds:cd_pend_tx,0
;
    mov eax,3Fh
    mov es:can_gfc,eax
;
    xor eax,eax
    mov es:can_rxesc,eax

    xor eax,eax
    mov es:can_txesc,eax
;
    mov edx,ds:cd_bar_linear
    add edx,ds:cd_sidf_offset
;
    call CreateFiltersel
    call CreateRx0Sel
    call CreateRx1Sel
    call CreateTxSel

    mov edx,40h
    mov es:can_cccr,edx
;
    mov ax,SEG data
    mov ds,eax
    LeaveSection ds:can_rec_section
    mov fs,ds:can_sel

ctWait:
    WaitForSignal
;
    xor edx,edx
    xchg edx,fs:cd_irqs
;
    test edx,1
    jz ctNotRx0
;
    call HandleRx0

ctNotRx0:
    test edx,10h
    jz ctNotRx1
;
    call HandleRx1

ctNotRx1:
    test edx,200h
    jz ctNotTxOk
;
    call HandleTxOk    

ctNotTxOk:
    test edx,400h
    jz ctNotTxCancel
;
    int 3
    call HandleTxCancel

ctNotTxCancel:
    jmp ctWait

ctDone:
    retf    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_can
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_can    Proc far
    push ds
    push es
    pusha
;    
    call SetupDevice
    jc icDone
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET can_thread_name
    mov esi,OFFSET can_thread_pr
    mov ax,4
    mov cx,stack0_size
    CreateThread

icDone:
    popa
    pop es
    pop ds
    ret
init_can    Endp

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
    mov ax,SEG data
    mov ds,ax    
    mov es,ax
;
    InitSection ds:can_rec_section
    InitSection ds:can_send_section
    InitSection ds:capture_section
    mov ds:capture_handle,0
    mov ds:capture_thread,0
    mov ds:capture_list,0
;
    mov edi,OFFSET can_id_hook_arr
    mov ecx,4 * 16
    xor eax,eax
    rep stosd
;
    mov ax,cs
    mov es,ax
    mov ds,ax
    mov edi,OFFSET init_can
    HookInitPci
;
    mov esi,OFFSET reset_can_buffers
    mov edi,OFFSET reset_can_buffers_name
    mov ax,reset_can_buffers_nr
    RegisterOsGate
;
    mov esi,OFFSET send_can_bus_msg
    mov edi,OFFSET send_can_bus_msg_name
    mov ax,send_can_bus_msg_nr
    RegisterOsGate
;
    mov esi,OFFSET send_can_bus_block
    mov edi,OFFSET send_can_bus_block_name
    mov ax,send_can_bus_block_nr
    RegisterOsGate
;
    mov esi,OFFSET has_can_send_buf
    mov edi,OFFSET has_can_send_buf_name
    mov ax,has_can_send_buf_nr
    RegisterOsGate
;
    mov esi,OFFSET hook_gen_bus_msg
    mov edi,OFFSET hook_gen_bus_msg_name
    mov ax,hook_can_gen_bus_msg_nr
    RegisterOsGate
;
    mov esi,OFFSET create_id_hook
    mov edi,OFFSET create_id_hook_name
    mov ax,create_can_id_hook_nr
    RegisterOsGate
;
    mov esi,OFFSET delete_id_hook
    mov edi,OFFSET delete_id_hook_name
    mov ax,delete_can_id_hook_nr
    RegisterOsGate
;
    mov esi,OFFSET start_can_capture
    mov edi,OFFSET start_can_capture_name
    xor dx,dx
    mov ax,start_can_capture_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_can_capture
    mov edi,OFFSET stop_can_capture_name
    xor dx,dx
    mov ax,stop_can_capture_nr
    RegisterBimodalUserGate
;    
    clc
    ret
init    ENDP

code    ENDS

    END init
