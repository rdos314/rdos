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
; CAN.ASM
; CAN-bus driver
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

SIDF_ELEMENT_SIZE = 4
XIDF_ELEMENT_SIZE = 8
RXF0_ELEMENT_SIZE = 16
RXF1_ELEMENT_SIZE = 16
RXB_ELEMENT_SIZE = 16
TXE_ELEMENT_SIZE = 8
TXB_ELEMENT_SIZE = 16

SIDF_ENTRIES = 16
XIDF_ENTRIES = 0
RXF0_ENTRIES = 64
RXF1_ENTRIES = 64
RXB_ENTRIES = 0
TXE_ENTRIES = 0
TXB_ENTRIES = 32

can_struc   STRUC

can_crel	DD ?
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
cd_reg          DW ?
cd_filter_sel   DW ?
cd_rx0_sel      DW ?
cd_rx1_sel      DW ?
cd_tx_sel       DW ?
cd_bus          DB ?
cd_dev          DB ?
cd_func         DB ?
cd_resv         DB ?

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
    CrashGate
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
    movzx edx,bl
;
    movzx esi,ah
    shl esi,4
    or edx,esi
;
    movzx esi,al
    shl esi,8
    or edx,esi
;
    movzx esi,cl
    shl esi,16
    or edx,esi
    mov es:can_dbtp,edx
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
    sub ecx,ds:cd_sidf_offset
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
    sub ecx,ds:cd_sidf_offset
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
    sub ecx,ds:cd_sidf_offset
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
    sub ecx,ds:cd_sidf_offset
    mov ax,cx
    mov es:can_txbc,eax
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

SetupDevice  Proc near
    xor ax,ax
    mov bh,0Ch
    mov bl,9
    FindPciClass
    jc sdDone
;
    push es
    push edi
    mov ax,cs
    mov es,ax
    mov edi,OFFSET DevName
    PciPowerOn
    pop edi
    pop es
;
    push cx
    mov eax,1000h    
    AllocateBigLinear
    pop cx
;
    mov cl,4h
    ReadPciDword
    or al,6
    WritePciDword
;
    mov cl,14h
    ReadPciDword
    mov ebp,eax
;
    mov cl,10h
    ReadPciDword
;
    push ebx
    push ecx
;
    mov ebx,ebp
    xor al,al
    or ax,813h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
;
    push eax
    mov eax,SIZE can_dev_struc
    AllocateSmallGlobalMem
    mov es:cd_reg,bx
    pop eax
;
    xor al,al
    mov es:cd_bar_phys,eax
    mov es:cd_bar_phys+4,ebp
;    
    pop ecx
    pop ebx    
;
    mov es:cd_bus,bh
    mov es:cd_dev,bl
    mov es:cd_func,ch
;
    GetPciMsi
    jc sdFail

sdMsi:
    push cx
    mov cx,1
    mov al,12h
    AllocateInts
    pop cx
    jc sdFail
;    
    mov dl,1
    SetupPciMsi
;    
    push es
    mov edi,cs
    mov es,edi
    mov edi,OFFSET CanInt
    RequestMsiHandler
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
    mov bh,ds:cd_bus
    mov bl,ds:cd_dev
    mov ch,ds:cd_func
    mov eax,cs
    mov es,eax
    mov esi,OFFSET can_config_name
    mov eax,ds
    mov fs,eax
    mov edi,OFFSET cd_sidf_offset
    mov eax,8
    GetPciDsdConfig
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
;
    int 3
    mov esi,SEG data
    mov ds,esi
    mov ds,ds:can_sel
    mov es,ds:cd_reg
    mov esi,es:can_txfqs
    shr esi,16
    test si,20h
    jnz scbFail
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
    mov es:can_txbar,esi
    clc
    jmp scbDone

scbFail:
    stc

scbDone:
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
    int 3
    clc
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
    int 3
    clc
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
;           NAME:           CanThread
;
;           description:    Can thread
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

can_thread_name DB 'Can', 0
can_config_name DB 'bosch,mram-cfg', 0

can_thread_pr:
    mov ax,SEG data
    mov ds,eax
    EnterSection ds:can_rec_section
;
    int 3
    mov ds,ds:can_sel
    mov es,ds:cd_reg
;
    mov eax,3
    mov es:can_cccr,eax
;
    mov es:can_ir,3FFFFFFFh
    mov es:can_ie,1FFFFFFFh
    mov es:can_ils,0
    mov es:can_ile,3
;
    mov al,11   ; TSEG 1
    mov ah,4    ; TSEG 2
    mov bl,4    ; SJW
    mov cl,2    ; Divisor
    call SetupBitTiming
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
;
    xor eax,eax
    mov es:can_cccr,eax
;
    mov ax,SEG data
    mov ds,eax
    LeaveSection ds:can_rec_section
;
    int 3

ctDone:
    retf    

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
    ret
stop_can_capture    Endp

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
    mov ax,2
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
