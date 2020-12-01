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
; OHCI.ASM
; OHCI-based USB host controller driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\core.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE ..\os\memblk.inc
INCLUDE usb.inc
INCLUDE usbdev.inc

MAX_USB_DEVICES = 16

hc_reg  STRUC

HcRevision      DD ?
HcControl       DD ?
HcCommandStatus     DD ?
HcInterruptStatus   DD ?
HcInterruptEnable   DD ?
HcInterruptDisable  DD ?
HcHCCA          DD ?
HcPeriodCurrentED   DD ?
HcControlHeadED     DD ?
HcControlCurrentED  DD ?
HcBulkHeadED    DD ?
HcBulkCurrentED     DD ?
HcDoneHeadED    DD ?
HcFmInterval    DD ?
HcFmRemain      DD ?
HcFmNumber      DD ?
HcPeriodicStart     DD ?
HcLSThreshold       DD ?
HcRhDescriptorA     DD ?
HcRhDescriptorB     DD ?    
HcRhStatus      DD ?
HcRhPortStatus      DD ?

hc_reg  ENDS

ohc_es_struc    STRUC

;HC part

oes_fa_en       DW ?
oes_mps         DW ?
oes_tailp       DD ?
oes_headp       DD ?
oes_nexted      DD ?

;driver part

oes_next_va     DD ?

ohc_es_struc    ENDS


ohc_td_struc    STRUC

;HC part

otd_resv        DW ?
otd_flags       DW ?
otd_cbp         DD ?
otd_next_td     DD ?
otd_be          DD ?

;driver part

otd_next_va     DD ?
otd_buffer_va   DD ?
otd_buffer_size DW ?

ohc_td_struc    ENDS

ohci_func_sel   STRUC

usb_func_base    usb_function_struc <>

ohc_reg_sel     DW ?
ohc_map_sel     DW ?
ohc_map_linear      DD ?
ohc_int_status      DD ?
ohc_linear      DD ?
ohc_phys        DD ?
ohc_control_linear  DD ?
ohc_bulk_linear     DD ?
ohc_thread          DW ?

ohc_enum_section    section_typ <>

ohc_root_ports      DW ?
ohc_reset           DW ?

ohc_usb_bus         DB ?
ohc_usb_dev         DB ?
ohc_usb_func        DB ?
ohc_irq             DB ?

ohc_fm_reg          DD ?

ohc_section     section_typ <>

ohc_32_cnt      DB 32 DUP(?)
ohc_16_cnt      DB 16 DUP(?)
ohc_8_cnt       DB 8 DUP(?)
ohc_4_cnt       DB 4 DUP(?)
ohc_2_cnt       DB 2 DUP(?)
ohc_1_cnt       DB ?

ohc_curr_cnt    DB 32 DUP(?)

ohci_func_sel    ENDS


; this should be at 700h in the ohci_func_sel, interrupt ES descriptors

ohc_int_base   = 700h

ohc_int_struc   STRUC

ohc_32_es       DB 32 * 32 DUP(?)
ohc_16_es       DB 16 * 32 DUP(?)
ohc_8_es        DB 8 * 32 DUP(?)
ohc_4_es        DB 4 * 32 DUP(?)
ohc_2_es        DB 2 * 32 DUP(?)
ohc_1_es        DB 1 * 32 DUP(?)
ohc_iso_es      DB 1 * 32 DUP(?)

ohc_int_struc   ENDS

ohc_hca_base   = 0F00h      ; HCCA is at the end (F00h) of ohci_func_sel

hcca_struc  STRUC

hcca_int_table      DD 32 DUP(?)
hcca_frame_number   DW ?
hcca_pad1       DW ?
hcca_done_head      DD ?

hcca_struc  ENDS

ohci_pipe_struc    STRUC

op_descr        DB 8 DUP(?)

op_rd_ptr       DW ?
op_wr_ptr       DW ?
op_entry_count  DW ?
op_intr_count   DW ?
op_intr_list    DW ?
op_ed           DD ?
op_tail         DD ?

op_entry_arr    DD ?

ohci_pipe_struc    ENDS

ohci_dev_sel   STRUC

usb_dev_base       usb_device_struc <>

dev_control_ed     DD ?
dev_control_tail   DD ?
dev_control_head   DD ?
dev_curr_addr      DB ?
dev_pad            DB ?,?,?

dev_in_ep_arr      DW 15 DUP(?)
dev_out_ep_arr     DW 15 DUP(?)

ohci_dev_sel   ENDS

data    SEGMENT byte public 'DATA'

WaitSection     section_typ <>
WaitThreadArr   DW 3 DUP(?)
PortThread      DW ?
Started         DB ?
UseTimer        DB ?

OhciFuncCount   DW ?
OhciFuncArr     DW MAX_USB_DEVICES DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'


    assume cs:code

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OhciInt
;
;           DESCRIPTION:    OHCI interrupt
;
;       PARAMETERS:     DS      Register selector
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OhciInt Proc far
    mov es,ds:ohc_reg_sel
    mov eax,es:HcInterruptStatus
    test al,2
    jz oiQueueDone
;
    NotifyIrqActivity
    call UpdateQueue

oiQueueDone:
    test al,20h
    jz oiHubDone
;
    push ds
    mov bx,SEG data
    mov ds,bx
    mov bx,ds:PortThread
    Signal
    pop ds

oiHubDone:        
    mov es,ds:ohc_reg_sel
    mov es:HcInterruptStatus,eax
    or ds:ohc_int_status,eax
;
    retf32
OhciInt  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitEd
;
;           DESCRIPTION:    Initialize an already allocated ED
;
;           PARAMETERS:     DS      Function sel
;                           FS      Flat sel
;                           EDX     ED
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitEd  PROC near
    mov fs:[edx].oes_fa_en,4000h
    mov fs:[edx].oes_mps,0
    mov fs:[edx].oes_tailp,0
    mov fs:[edx].oes_headp,0
    mov fs:[edx].oes_nexted,0
    mov fs:[edx].oes_next_va,0
    ret
InitEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitTd
;
;       DESCRIPTION:    Initialize an already allocated TD
;
;       PARAMETERS:     DS      Function
;                       FS      Flat sel
;                       EDX     TD
;                       EAX     Physical address of TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTd  PROC near
    mov fs:[edx].otd_resv,0
    mov fs:[edx].otd_flags,0E4h
    mov fs:[edx].otd_cbp,0
    mov fs:[edx].otd_next_td,0
    mov fs:[edx].otd_be,0
    mov fs:[edx].otd_next_va,0
    ret
InitTd  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateEd
;
;           DESCRIPTION:    Allocate & initialize an endpoint descriptor
;
;           PARAMETERS:     DS      Function selector
;                           FS      Flat sel
;
;           RETURNS:        EDX     Linear address of ED
;                           EAX     Physical address of ED
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateEd      PROC near
    push ebx
    push ecx
;
    mov cx,SIZE ohc_es_struc
    AllocateMemBlk
;
    call InitEd
;
    pop ecx
    pop ebx
    ret
AllocateEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateTd
;
;           DESCRIPTION:    Allocate & initialize transfer descriptor
;
;           PARAMETERS:     FS      Flat sel
;
;           RETURNS:        EDX     Linear address of TD
;                           EAX     Physical address of TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTd      PROC near
    push ebx
    push ecx
;
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk

    call InitTd
;    
    pop ecx
    pop ebx
    ret
AllocateTd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddControlEd
;
;       DESCRIPTION:    Add control ED 
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;
;       RETURNS:        EDX     Linear address of ED added
;                       EAX     Physical address of ED added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddControlEd    PROC near
    push gs
    push ebx
;
    call AllocateEd
    mov gs,ds:ohc_reg_sel
    mov ebx,gs:HcControlHeadEd
    mov fs:[edx].oes_nexted,ebx
    mov ebx,ds:ohc_control_linear
    mov fs:[edx].oes_next_va,ebx
;
    mov ds:ohc_control_linear,edx
    mov gs:HcControlHeadEd,eax
;
    mov ebx,edx
    push eax
    push edx
;    
    call AllocateTd
    mov fs:[ebx].oes_headp,eax
    mov fs:[ebx].oes_tailp,eax
;    
    pop edx
    pop eax
;    
    pop ebx
    pop gs
    ret
AddControlEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddBulkEd
;
;       DESCRIPTION:    Add bulk ED 
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;
;       RETURNS:        EDX     Linear address of ED added
;                       EAX     Physical address of ED added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBulkEd       PROC near
    push gs
    push ebx
;
    call AllocateEd
    mov gs,ds:ohc_reg_sel
    mov ebx,gs:HcBulkHeadEd
    mov fs:[edx].oes_nexted,ebx
    mov ebx,ds:ohc_bulk_linear
    mov fs:[edx].oes_next_va,ebx
;
    mov ds:ohc_bulk_linear,edx
    mov gs:HcBulkHeadEd,eax
;
    mov ebx,edx
    push eax
    push edx
;    
    call AllocateTd
    mov fs:[ebx].oes_headp,eax
    mov fs:[ebx].oes_tailp,eax
;    
    pop edx
    pop eax
;    
    pop ebx
    pop gs
    ret
AddBulkEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetIntrEd
;
;       DESCRIPTION:    Get interrupt ED
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;
;       RETURNS:        DI      Offset to ED list entry to use
;                       SI      Offset to count array
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIntrEd       PROC near
    push ax
    push bx
    push cx
    push bp
;
    cmp cl,1
    jbe gie1
;
    cmp cl,3
    jbe gie2
;
    cmp cl,7
    jbe gie4
;
    cmp cl,15
    jbe gie8
;
    cmp cl,31
    jbe gie16

gie32:
    mov bx,OFFSET ohc_32_cnt
    mov si,OFFSET ohc_32_es
    mov cx,32
    jmp gieLnkOk

gie16:
    mov bx,OFFSET ohc_16_cnt
    mov si,OFFSET ohc_16_es
    mov cx,16
    jmp gieLnkOk

gie8:
    mov bx,OFFSET ohc_8_cnt
    mov si,OFFSET ohc_8_es
    mov cx,8
    jmp gieLnkOk

gie4:
    mov bx,OFFSET ohc_4_cnt
    mov si,OFFSET ohc_4_es
    mov cx,4
    jmp gieLnkOk

gie2:
    mov bx,OFFSET ohc_2_cnt
    mov si,OFFSET ohc_2_es
    mov cx,2
    jmp gieLnkOk

gie1:
    mov bx,OFFSET ohc_1_cnt
    mov si,OFFSET ohc_1_es
    mov cx,1

gieLnkOk:
    push cx
    mov di,OFFSET ohc_curr_cnt
    xor al,al

gieInitCnt:
    mov [di],al
    inc di
    loop gieInitCnt
;    
    pop cx
;
    push bx
    push cx
    push si
;   
    mov si,1

gieAddListLoop:    
    push cx
    mov di,OFFSET ohc_curr_cnt

gieAddCount:
    mov al,[bx]
    mov bp,si    

gieAddLoop:
    add [di],al
    inc di
    sub bp,1
    jnz gieAddLoop
;    
    inc bx
    loop gieAddCount
;
    pop cx
;
    shl si,1
    shr cx,1
    or cx,cx
    jnz gieAddListLoop    
;
    pop si
    pop cx
    pop bx
;
    mov ah,0FFh
    mov di,OFFSET ohc_curr_cnt

gieSmallestLoop:
    mov al,[di]
    cmp al,ah
    jae gieSmallestNext
;
    mov ah,al
    mov bp,di

gieSmallestNext:
    inc di
    loop gieSmallestLoop
;
    mov di,bp
    sub di,OFFSET ohc_curr_cnt
;
    add bx,di
    inc byte ptr [bx]
    shl di,5
    add di,si
    add di,ohc_int_base
    mov si,bx
;    
    pop bp
    pop cx
    pop bx
    pop ax
    ret
GetIntrEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddIntrEd
;
;       DESCRIPTION:    Add interrupt ED 
;
;       PARAMETERS:     DS      Function sel
;                       FS      Flat sel
;                       CL      Interval
;
;       RETURNS:        EDX     Linear address of ED added
;                       EAX     Physical address of ED added
;                       SI      Interrupt count array entry
;                       DI      Interrupt ED used
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntrEd       PROC near
    push ebx
;
    call AllocateEd
;
    call GetIntrEd
    mov ebx,ds:[di].oes_next_va
    mov fs:[edx].oes_next_va,ebx
    mov ebx,ds:[di].oes_nexted
    mov fs:[edx].oes_nexted,ebx
;
    mov ds:[di].oes_next_va,edx
    mov ds:[di].oes_nexted,eax
;
    mov ebx,edx
    push eax
    push edx
;    
    call AllocateTd
    mov fs:[ebx].oes_headp,eax
    mov fs:[ebx].oes_tailp,eax
;    
    pop edx
    pop eax
;    
    pop ebx
    ret
AddIntrEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateInterrupt
;
;       DESCRIPTION:    Create interrupt queues
;
;       PARAMETERS:     DS  Function selector
;                       FS  Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateInterrupt PROC near
    push fs
    push eax
    push ebx
    push ecx
    push edx
;    
    mov ax,flat_sel
    mov fs,ax
;
    mov cx,32
    mov bx,ohc_hca_base + OFFSET hcca_int_table
    mov eax,ohc_int_base + OFFSET ohc_32_es
    mov edx,eax
    add eax,ds:ohc_phys
    add edx,ds:ohc_linear

ci_int32:
    call InitEd
    mov ds:[bx],eax
    add eax,32
    add edx,32
    add bx,4
    loop ci_int32
;
    mov cx,32
    mov bx,ohc_int_base + OFFSET ohc_32_es
    mov eax,ohc_int_base + OFFSET ohc_16_es
    mov edx,eax
    add eax,ds:ohc_phys
    add edx,ds:ohc_linear

ci_int16_init:
    call InitEd

ci_int16_link:
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
    add bx,32
;
    test cx,1
    jz ci_int16_link_next
;    
    add eax,32
    add edx,32
    loop ci_int16_init
;    
    jmp ci_int16_done

ci_int16_link_next:    
    loop ci_int16_link

ci_int16_done:
    mov cx,16
    mov bx,ohc_int_base + OFFSET ohc_16_es
    mov eax,ohc_int_base + OFFSET ohc_8_es
    mov edx,eax
    add eax,ds:ohc_phys
    add edx,ds:ohc_linear

ci_int8_init:
    call InitEd

ci_int8_link:
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
    add bx,32
;
    test cx,1
    jz ci_int8_link_next
;    
    add eax,32
    add edx,32
    loop ci_int8_init
;    
    jmp ci_int8_done

ci_int8_link_next:    
    loop ci_int8_link

ci_int8_done:
    mov cx,8
    mov bx,ohc_int_base + OFFSET ohc_8_es
    mov eax,ohc_int_base + OFFSET ohc_4_es
    mov edx,eax
    add eax,ds:ohc_phys
    add edx,ds:ohc_linear

ci_int4_init:
    call InitEd

ci_int4_link:
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
    add bx,32
;
    test cx,1
    jz ci_int4_link_next
;    
    add eax,32
    add edx,32
    loop ci_int4_init
;    
    jmp ci_int4_done

ci_int4_link_next:    
    loop ci_int4_link

ci_int4_done:
    mov bx,ohc_int_base + OFFSET ohc_4_es
    mov eax,ohc_int_base + OFFSET ohc_2_es
    mov edx,eax
    add eax,ds:ohc_phys
    add edx,ds:ohc_linear
;    
    call InitEd
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
;
    add bx,32
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
;    
    add eax,32
    add edx,32
    call InitEd
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
;
    add bx,32
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
;    
    mov bx,ohc_int_base + OFFSET ohc_2_es
    mov eax,ohc_int_base + OFFSET ohc_1_es
    mov edx,eax
    add eax,ds:ohc_phys
    add edx,ds:ohc_linear
;    
    call InitEd
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
;
    add bx,32
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
;    
    mov bx,ohc_int_base + OFFSET ohc_1_es
    mov eax,ohc_int_base + OFFSET ohc_iso_es
    mov edx,eax
    add eax,ds:ohc_phys
    add edx,ds:ohc_linear
;    
    call InitEd
    mov ds:[bx].oes_nexted,eax
    mov ds:[bx].oes_next_va,edx
;   
    mov cx,32+16+8+4+2+1
    mov bx,OFFSET ohc_32_cnt
    xor al,al

ciInitCount:
    mov ds:[bx],al
    inc bx
    loop ciInitCount
;    
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop fs
    ret
CreateInterrupt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateControl
;
;       DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    pushad
;    
    mov dx,flat_sel
    mov fs,dx
    call AddControlEd
    mov es:dev_control_ed,edx
    mov eax,fs:[edx].oes_tailp
    mov es:dev_control_tail,eax
;
    xor ax,ax
    mov fs,ax
;
    popad
    retf32
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateBulk
;
;           DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       DL      Pipe # (bit 7, IN)
;                       CX      Max data size
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    retf32
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateIntr
;
;           DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       AL      Interval
;                       DL      Pipe # (bit 7, IN)
;                       CX      Max data size
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    retf32
CreateIntr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddOut
;
;           DESCRIPTION:    Add out transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               CX      Buffer size
;               ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddOut    Proc far
    retf32
AddOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddIn
;
;           DESCRIPTION:    Add in transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               CX      Buffer size
;               ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIn    Proc far
    retf32
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IssueTransfer
;
;           DESCRIPTION:    Issue transfer
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               EDX     Queue handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueTransfer    Proc far
    retf32
IssueTransfer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsTransferDone
;
;           DESCRIPTION:    Check if transfer is done
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsTransferDone   Proc far
    stc
    retf32
IsTransferDone   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForCompletion
;
;           DESCRIPTION:    Wait for transfer to complete
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion   Proc far
    retf32
WaitForCompletion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WasTransferOk
;
;           DESCRIPTION:    Check if transfer was ok
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;       RETURNS:    NC      Transfer ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WasTransferOk   Proc far
    stc
    retf32
WasTransferOk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EndTransfer
;
;           DESCRIPTION:    End transfer
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndTransfer   Proc far
    retf32
EndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetDataSize
;
;           DESCRIPTION:    Get data size
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;       RETURNS:    CX      Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDataSize   Proc far
    xor cx,cx
    retf32
GetDataSize   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClosePipe
;
;           DESCRIPTION:    Close pipe
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePipe   Proc far
    retf32
ClosePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ChangeAddress
;
;           DESCRIPTION:    Change address for pipe
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    push fs
    push eax
    push edx
;
    mov ax,flat_sel
    mov fs,ax
;
    mov al,es:usbd_address
    mov es:dev_curr_addr,al
    mov edx,es:dev_control_ed
    or fs:[edx].oes_fa_en,4000h
;
    pop edx
    pop eax
    pop fs
    retf32
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsConnected
;
;           DESCRIPTION:    Check if pipe is connected
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsConnected   Proc far
    push es
    push eax
    push dx
    push si
;    
    mov es,fs:usbp_dev_sel
    movzx si,es:usbd_port
;    
    shl si,2
    mov es,ds:ohc_reg_sel
    mov eax,es:[si].HcRhPortStatus
    test al,2
    jz icDisabled
;
    test al,1
    clc
    jnz icDone
    jmp icFail

icDisabled:
    push cx
    mov es,fs:usbp_dev_sel
    mov cl,es:usbd_port
    mov ax,1
    shl ax,cl
    lock or ds:ohc_reset,ax
    pop cx

icFail:
    stc

icDone:
    pop si
    pop dx
    pop eax
    pop es
    retf32
IsConnected Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetDev
;
;           DESCRIPTION:    Reset device
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetDev   Proc far
    push ax
    push cx
;    
    mov cl,es:usbd_port
    mov ax,1
    shl ax,cl
    lock or ds:ohc_reset,ax
;
    pop cx
    pop ax
    retf32
ResetDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockEnum
;
;           DESCRIPTION:    Lock enumeration process
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockEnum   Proc far
    EnterSection ds:ohc_enum_section
    retf32
LockEnum   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockEnum
;
;           DESCRIPTION:    Unlock enumeration process
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockEnum   Proc far
    LeaveSection ds:ohc_enum_section
    retf32
UnlockEnum   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Has64Bit
;
;           DESCRIPTION:    Check for 64-bit support
;
;       PARAMETERS:         DS      Function selector
;
;       RETURNS:            NC      Supports 64-bit addresses
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Has64Bit   Proc far
    stc
    retf32
Has64Bit     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsStalled
;
;           DESCRIPTION:    Check if pipe is stalled
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsStalled   Proc far
    int 3
    clc
    retf32
IsStalled   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ClearStalled
;
;           DESCRIPTION:    Clear stalled pipe
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearStalled   Proc far
    int 3
    clc
    retf32
ClearStalled   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateMaxLen
;
;           DESCRIPTION:    Update max len
;
;           PARAMETERS:     ES      Device selector
;                           AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMaxLen   Proc far
    push fs
    push edx
;
    movzx ax,al
    mov dx,flat_sel
    mov fs,dx
    mov edx,es:dev_control_ed
    mov byte ptr fs:[edx].oes_mps,al
    mov es:usbd_maxlen,ax
;
    pop edx
    pop fs
    clc
    retf32
UpdateMaxLen   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IssueOne
;
;           DESCRIPTION:    Issue one transfer
;
;       PARAMETERS:         FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IssueOne   Proc far
    retf32
IssueOne   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsDeviceConnected
;
;           DESCRIPTION:    Check if device is connected
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsDeviceConnected   Proc far
    push fs
    push eax
    push dx
    push si
;    
    test es:usbd_flags,FLAG_DETACHED
    stc
    jnz idcDone
;
    movzx si,es:usbd_port    
    shl si,2
    mov fs,ds:ohc_reg_sel
    mov eax,fs:[si].HcRhPortStatus
    test al,2
    stc
    jz idcDone
;
    test al,1
    stc
    jz idcDone
;
    mov eax,fs:HcInterruptStatus
    test al,10h
    stc
    jnz idcDone
;
    clc

idcDone:
    pop si
    pop dx
    pop eax
    pop fs
    retf32
IsDeviceConnected Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControl
;
;       DESCRIPTION:    Setup control msg
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControl   Proc near
    push eax
    push ebx
    push edx
;
    mov edx,es:dev_control_head
    mov fs:[edx].otd_resv,0
    mov fs:[edx].otd_flags,0F2E4h
    mov fs:[edx].otd_next_td,0
    mov fs:[edx].otd_next_va,0
;
    mov ebx,OFFSET usbd_control_buf
    mov eax,ebx
    add eax,es:mblk_physical_base
    mov fs:[edx].otd_cbp,eax
;    
    add eax,7
    mov fs:[edx].otd_be,eax
;
    pop edx
    pop ebx
    pop eax
    ret
SetupControl    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControlIn
;
;       DESCRIPTION:    Setup control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControlIn   Proc near
    pushad
;
    mov esi,es:dev_control_head
    or cx,cx
    jz sciStatusOut

sciLoop:
    push cx
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
    pop cx
    jc sciDone
;
    mov fs:[esi].otd_next_td,eax
    mov fs:[esi].otd_next_va,edx
    mov esi,edx
    mov fs:[esi].otd_resv,0
    mov fs:[esi].otd_flags,0F0F4h
    mov fs:[esi].otd_next_td,0
    mov fs:[esi].otd_cbp,0
    mov fs:[esi].otd_next_va,0
    mov fs:[esi].otd_buffer_va,0
;
    mov bx,cx
    cmp bx,es:usbd_maxlen
    jb sciInMinOk
;
    mov bx,es:usbd_maxlen

sciInMinOk:
    push bx
    push cx
    mov cx,bx
    AllocateMemBlk
    pop cx
    pop bx
    jc sciDone
;
    mov fs:[esi].otd_cbp,eax
    mov fs:[esi].otd_buffer_va,edx
    mov fs:[esi].otd_buffer_size,bx
;
    add ax,bx
    dec ax
    mov fs:[esi].otd_be,eax
;
    sub cx,bx
    jnz sciLoop

sciStatusOut: 
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
    jc sciDone
;
    mov fs:[esi].otd_next_td,eax
    mov fs:[esi].otd_next_va,edx
    mov esi,edx
    mov fs:[esi].otd_resv,0
    mov fs:[esi].otd_flags,0F3ECh
    mov fs:[esi].otd_cbp,0
    mov fs:[esi].otd_be,0
;
    mov eax,es:dev_control_tail
    mov fs:[esi].otd_next_td,eax
    mov fs:[esi].otd_next_va,0
    mov fs:[esi].otd_buffer_va,0
    clc

sciDone:
    popad
    ret
SetupControlIn  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CopyControlIn
;
;       DESCRIPTION:    Copy control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;                       GS:EDI  Buffer
;
;       RETURNS:        CX      Size returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyControlIn   Proc near
    push eax
    push ebx
    push edx
    push esi
    push edi
    push ebp
;
    xor cx,cx
    mov esi,es:dev_control_head
    mov esi,fs:[esi].otd_next_va

cciCopyLoop:
    or esi,esi
    clc
    jz cciDone
;
    mov edx,fs:[esi].otd_buffer_va
    or edx,edx
    jz cciCopyNext
;
    mov bp,fs:[esi].otd_buffer_size
    mov eax,fs:[esi].otd_cbp
    or eax,eax
    jz cciCopyDo
;
    PhysicalToLinearMemBlk
    jc cciCopyNext
;
    mov eax,fs:[esi].otd_buffer_va
    sub edx,eax
    mov bp,dx

cciCopyDo:
    push es
    push ecx
    push esi
    mov ax,gs
    mov es,ax
    mov esi,fs:[esi].otd_buffer_va
    movzx ecx,bp
    rep movs byte ptr es:[edi],fs:[esi]
    pop esi
    pop ecx
    pop es
;
    push cx
    mov cx,bp
    mov edx,fs:[esi].otd_buffer_va
    FreeLinearMemBlk
    pop cx
;
    add cx,bp

cciCopyNext:
    xchg edx,esi
    mov esi,fs:[edx].otd_next_va
;
    push cx
    mov cx,SIZE ohc_td_struc
    FreeLinearMemBlk
    pop cx
    jmp cciCopyLoop

cciDone:
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret
CopyControlIn   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControlOut
;
;       DESCRIPTION:    Setup control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;                       CX      Size
;                       GS:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControlOut  Proc near
    pushad
;
    mov esi,edi
    mov edi,es:dev_control_head
    or cx,cx
    jz scoStatusIn

scoLoop:
    push cx
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
    pop cx
    jc scoDone
;
    mov fs:[edi].otd_next_td,eax
    mov fs:[edi].otd_next_va,edx
    mov edi,edx
    mov fs:[edi].otd_resv,0
    mov fs:[edi].otd_flags,0F0ECh
    mov fs:[edi].otd_next_td,0
    mov fs:[edi].otd_cbp,0
    mov fs:[edi].otd_next_va,0
    mov fs:[edi].otd_buffer_va,0
;
    mov bx,cx
    cmp bx,es:usbd_maxlen
    jb scoOutMinOk
;
    mov bx,es:usbd_maxlen

scoOutMinOk:
    push bx
    push cx
    mov cx,bx
    AllocateMemBlk
    pop cx
    pop bx
    jc scoDone
;
    mov fs:[edi].otd_cbp,eax
    mov fs:[edi].otd_buffer_va,edx
    mov fs:[edi].otd_buffer_size,bx
;
    add ax,bx
    dec ax
    mov fs:[edi].otd_be,eax
;
    push es
    push ecx
    push edi
;
    mov ax,fs
    mov es,ax
    mov edi,edx
    movzx ecx,bx
    rep movs byte ptr es:[edi],gs:[esi]
;
    pop edi
    pop ecx
    pop es
;
    sub cx,bx
    jnz scoLoop

scoStatusIn: 
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
    jc scoDone
;
    mov fs:[edi].otd_next_td,eax
    mov fs:[edi].otd_next_va,edx
    mov edi,edx
    mov fs:[edi].otd_resv,0
    mov fs:[edi].otd_flags,0F3F4h
    mov fs:[edi].otd_cbp,0
    mov fs:[edi].otd_be,0
;
    mov eax,es:dev_control_tail
    mov fs:[edi].otd_next_td,eax
    mov fs:[edi].otd_next_va,0
    mov fs:[edi].otd_buffer_va,0
    clc

scoDone:
    popad
    ret
SetupControlOut Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunControl
;
;       DESCRIPTION:    Run control
;
;       PARAMETERS:     DS      Usb function
;                       ES      Usb device
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunControl   Proc near
    pushad
;
    mov edx,es:dev_control_ed
    test fs:[edx].oes_fa_en,4000h
    jz rcEnabled
;
    mov ax,es:usbd_maxlen
    cmp ax,800h
    jb rcMaxSizeOk
;    
    mov ax,7FFh

rcMaxSizeOk:
    mov fs:[edx].oes_mps,ax
;
    movzx ax,es:dev_curr_addr
    cmp es:usbd_speed,0
    jnz rcSpeedOk
;
    or ah,20h

rcSpeedOk:    
    mov fs:[edx].oes_fa_en,ax

rcEnabled:    
    mov eax,es:dev_control_tail
    mov fs:[edx].oes_tailp,eax
    mov edx,es:dev_control_head
    LinearToPhysicalMemBlk
;
    mov edx,es:dev_control_ed
    mov fs:[edx].oes_headp,eax
    and fs:[edx].oes_fa_en,NOT 4000h
;
    call fword ptr ds:is_dev_connected_proc
    jc rcDone
;
    push ds
    mov ds,ds:ohc_reg_sel
    mov eax,ds:HcCommandStatus
    or al,2
    mov ds:HcCommandStatus,eax
    pop ds
;
    mov edx,es:dev_control_ed
    mov cx,100

rcWait:
    mov ax,4
    WaitMilliSec
;
    call fword ptr ds:is_dev_connected_proc
    jc rcDone
;
    test fs:[edx].oes_fa_en,4000h
    stc
    jnz rcDone
;
    mov eax,fs:[edx].oes_headp
    test al,1
    stc
    jnz rcDone
;
    cmp eax,fs:[edx].oes_tailp
    clc
    je rcDone
;
    loop rcWait
;
    stc

rcDone:
    popad
    ret
RunControl Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckResult
;
;       DESCRIPTION:    Chech result
;
;       PARAMETERS:     ES      Usb device
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckResult   Proc near
    push eax
    push esi
;
    mov esi,es:dev_control_head

crLoop:
    mov ax,fs:[esi].otd_flags
    shr ax,12
    or ax,ax
    stc
    jnz crDone
;
    mov esi,fs:[esi].otd_next_va
    or esi,esi
    jnz crLoop
;
    clc

crDone:
    pop esi
    pop eax
    ret
CheckResult     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CleanupControl
;
;       DESCRIPTION:    Cleanup control
;
;       PARAMETERS:     DS      Usb function
;                       ES      Usb device
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CleanupControl   Proc near
    pushad
;
    mov esi,es:dev_control_head
    mov esi,fs:[esi].otd_next_va

ccLoop:
    or esi,esi
    jz ccDone
;
    mov edx,fs:[esi].otd_buffer_va
    or edx,edx
    jz ccBufferOk
;
    mov cx,fs:[esi].otd_buffer_size
    FreeLinearMemBlk

ccBufferOk:
    xchg edx,esi
    mov esi,fs:[edx].otd_next_va
;
    mov cx,SIZE ohc_td_struc
    FreeLinearMemBlk
    jmp ccLoop

ccDone:
    popad
    ret
CleanupControl  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ControlMsg
;
;       DESCRIPTION:    Send message over control pipe
;
;       PARAMETERS:     ES      Usb device
;                       GS:EDI  Buffer
;
;       RETURNS:        NC      OK
;                          CX   Transfer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ControlMsg   Proc far
    push fs
    push eax
;
    mov cx,es:usbd_control_buf.usd_len
    mov ax,flat_sel
    mov fs,ax
;
    call SetupControl
;
    test es:usbd_control_buf.usd_type,80h
    jz cmDataOut
;
    call SetupControlIn
    jc cmFail
;
    call RunControl
    jc cmFail
;
    call CheckResult
    jc cmFail
;
    call CopyControlIn
    jmp cmDone
    
cmDataOut:
    call SetupControlOut
    jc cmFail
;
    call RunControl
    jc cmFail
;
    call CheckResult
    jc cmFail
;
    call CleanupControl
    clc
    jmp cmDone

cmFail:
    push edx
    mov edx,es:dev_control_ed
    mov eax,es:dev_control_tail
    mov fs:[edx].oes_tailp,eax
    xchg eax,fs:[edx].oes_headp
    cmp eax,es:dev_control_tail
    pop edx
    je cmCleanFail
;
    mov ax,25
    WaitMilliSec

cmCleanFail:
    call CleanupControl
    stc

cmDone:
    pop eax
    pop fs
    retf32
ControlMsg   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocatePipe
;
;       DESCRIPTION:    Allocate pipe
;
;       PARAMETERS:     FS      Flat sel
;                       CX      Buffer count
;                       AX      Buffer size
;                       GS:EDI  Descriptor
;
;       RETURNS:        BX      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePipe    Proc near
    push ds
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    mov esi,edi
    mov ax,gs:[di].ued_maxsize
    push es
    movzx eax,cx
    shl ax,2
    add ax,OFFSET op_entry_arr
    AllocateSmallGlobalMem
;
    xor edi,edi
    mov ecx,SIZE usb_endpoint_descr
    rep movs es:[edi],gs:[esi]
;
    mov es:op_rd_ptr,0
    mov es:op_wr_ptr,0
    mov es:op_entry_count,cx
    mov ax,es
    mov ds,ax
    pop es
;
    mov di,OFFSET op_entry_arr

apTdLoop:
    push cx
;
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
    mov esi,edx
;
    mov cx,ds:ued_maxsize
    AllocateMemBlk
;
    mov fs:[esi].otd_resv,0
    mov fs:[esi].otd_flags,0F0E4h
    mov fs:[esi].otd_cbp,eax
    mov fs:[esi].otd_next_td,0
    add eax,ebp
    dec eax
    mov fs:[esi].otd_be,eax
    mov fs:[esi].otd_next_va,0
    mov fs:[esi].otd_buffer_va,edx
    mov fs:[esi].otd_buffer_size,bp
;
    mov ds:[di],esi
    add di,4
    pop cx
    loop apTdLoop
;
    mov bx,ds
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop ds
    ret
AllocatePipe    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartInPipe
;
;       DESCRIPTION:    Start input pipe
;
;       PARAMETERS:     DS      Pipe sel
;                       ES      Device sel
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartInPipe     Proc near
    pushad
;
    mov si,OFFSET op_entry_arr
    mov cx,ds:op_entry_count
    xor edi,edi

sipLoop:
    mov edx,ds:[si]
    or edi,edi
    jz sipNext
;
    LinearToPhysicalMemBlk
    mov fs:[edi].otd_next_td,eax

sipNext:
    mov edi,edx
    add si,4
    loop sipLoop
;
    mov eax,ds:op_tail
    mov fs:[edi].otd_next_td,eax
;
    mov edx,ds:op_entry_arr
    LinearToPhysicalMemBlk
    mov edx,ds:op_ed
    mov fs:[edx].oes_headp,eax
;
    popad
    ret
StartInPipe     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartPipe
;
;       DESCRIPTION:    Start pipe
;
;       PARAMETERS:     DS      Pipe selector
;                       ES      Device selector
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartPipe  Proc near
    push eax
    push edx
    push esi
;
    mov esi,ds:op_ed
    mov ax,ds:ued_maxsize
    mov fs:[esi].oes_mps,ax
;
    mov dl,ds:ued_address
    mov ah,dl
    and ah,0Fh
    xor al,al
    shr ax,1
    mov dh,es:usbd_address
    and dh,7Fh
    or al,dh
;    
    cmp es:usbd_speed,0
    jnz spSpeedOk
;
    or ah,20h

spSpeedOk:    
    test dl,80h
    jz spOut

spIn:
    or ah,10h
    jmp spSave

spOut:
    or ah,8

spSave:
    mov fs:[esi].oes_fa_en,ax

spDone:
    pop esi
    pop edx
    pop eax
    ret
StartPipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ConfigPipe
;
;       DESCRIPTION:    Config pipe
;
;       PARAMETERS:     ES      Device
;                       DL      Pipe
;                       CX      Buffer count
;                       GS:EDI  Endpoint descriptor
;
;       RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigPipe   Proc far
    push ds
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    mov al,gs:[di].ued_attrib
    and al,3
    cmp al,2
    je cpBulk
;
    cmp al,3
    je cpIntr
;
    stc
    jmp cpDone

cpBulk:
    call AllocatePipe
;
    mov dl,gs:[di].ued_address
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    test dl,80h
    jz cpBulkOut

cpBulkIn:
    call AddBulkEd
    mov es:[si].dev_in_ep_arr,bx
;
    push ds
    mov ds,bx
    mov ds:op_intr_count,0
    mov ds:op_intr_list,0
    mov ds:op_ed,edx
    mov eax,fs:[edx].oes_tailp
    mov ds:op_tail,eax
;
    call StartInPipe
    call StartPipe
    pop ds
;
    mov ds,ds:ohc_reg_sel
    mov eax,ds:HcCommandStatus
    or al,4
    mov ds:HcCommandStatus,eax
    clc
    jmp cpDone

cpBulkOut:
    call AddBulkEd
    mov es:[si].dev_out_ep_arr,bx
    mov ds,bx
    mov ds:op_intr_count,0
    mov ds:op_intr_list,0
    mov ds:op_ed,edx
    mov eax,fs:[edx].oes_tailp
    mov ds:op_tail,eax
;
    call StartPipe
    clc
    jmp cpDone

cpIntr:
    call AllocatePipe
    mov dl,gs:[di].ued_address
    movzx si,dl
    and si,0Fh
    dec si
    add si,si
    test dl,80h
    jz cpIntrOut

cpIntrIn:
    push di
    call AddIntrEd
    mov es:[si].dev_in_ep_arr,bx
    mov ds,bx
    mov ds:op_intr_count,si
    mov ds:op_intr_list,di
    mov ds:op_ed,edx
    mov eax,fs:[edx].oes_tailp
    mov ds:op_tail,eax
    pop di
;
    call StartInPipe
    call StartPipe
    clc
    jmp cpDone

cpIntrOut:
    push di
    call AddIntrEd
    mov es:[si].dev_out_ep_arr,bx
    mov ds,bx
    mov ds:op_intr_count,si
    mov ds:op_intr_list,di
    mov ds:op_ed,edx
    mov eax,fs:[edx].oes_tailp
    mov ds:op_tail,eax
    pop di
;
    call StartPipe
    clc

cpDone:
    popad
    pop fs
    pop ds
    retf32
ConfigPipe   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkControl
;
;       DESCRIPTION:    Unlink control
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkControl   Proc near
    push fs
    push gs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    xor ecx,ecx
    mov ebx,ds:ohc_control_linear
    mov edx,es:dev_control_ed

ulcLoop:
    cmp ebx,edx
    je ulcUnlink
;
    mov ecx,ebx
    mov ebx,es:[ebx].oes_next_va
    or ebx,ebx
    jnz ulcLoop
;
    int 3
    jmp ulcDone

ulcUnlink:
    or ecx,ecx
    jz ulcHead
;
    mov esi,fs:[edx].oes_next_va
    mov edi,fs:[edx].oes_nexted
    mov fs:[ecx].oes_next_va,esi
    mov fs:[ecx].oes_nexted,edi
    jmp ulcDone

ulcHead:
    mov gs,ds:ohc_reg_sel
    mov esi,fs:[edx].oes_next_va
    mov edi,fs:[edx].oes_nexted
    mov ds:ohc_control_linear,esi
    mov gs:HcControlHeadEd,edi

ulcDone:
    popad
    pop gs
    pop fs
    ret
UnlinkControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkPipe
;
;       DESCRIPTION:    Unlink pipe
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device
;                       BX      Pipe sel
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkPipe   Proc near
    push fs
    push gs
    pushad
;
    mov fs,bx
    mov al,fs:ued_attrib
    and al,3
    cmp al,2
    je ulpBulk
;
    cmp al,3
    je ulpIntr
;
    int 3
    jmp ulpDone

ulpBulk:
    mov dx,flat_sel
    mov fs,dx
    xor ecx,ecx
    mov ebx,ds:ohc_bulk_linear

ulpBulkLoop:
    cmp ebx,edx
    je ulpBulkUnlink
;
    mov ecx,ebx
    mov ebx,fs:[ebx].oes_next_va
    or ebx,ebx
    jnz ulpBulkLoop
;
    int 3
    jmp ulpDone

ulpBulkUnlink:
    or ecx,ecx
    jz ulpBulkHead
;
    mov esi,fs:[edx].oes_next_va
    mov edi,fs:[edx].oes_nexted
    mov fs:[ecx].oes_next_va,esi
    mov fs:[ecx].oes_nexted,edi
    jmp ulpDone

ulpBulkHead:
    mov gs,ds:ohc_reg_sel
    mov esi,fs:[edx].oes_next_va
    mov edi,fs:[edx].oes_nexted
    mov ds:ohc_bulk_linear,esi
    mov gs:HcBulkHeadEd,edi
    jmp ulpDone

ulpIntr:
    mov di,fs:op_intr_count
    dec byte ptr ds:[di]
;
    mov di,fs:op_intr_list
    mov ebx,ds:[di].oes_next_va
    xor ecx,ecx
    mov ax,flat_sel
    mov fs,ax

ulpIntrLoop:
    cmp ebx,edx
    je ulpIntrUnlink
;
    mov ecx,ebx
    mov ebx,fs:[ebx].oes_next_va
    or ebx,ebx
    jnz ulpIntrLoop
;
    int 3
    jmp ulpDone

ulpIntrUnlink:
    or ecx,ecx
    jz ulpIntrHead
;
    mov esi,fs:[edx].oes_next_va
    mov edi,fs:[edx].oes_nexted
    mov fs:[ecx].oes_next_va,esi
    mov fs:[ecx].oes_nexted,edi
    jmp ulpDone

ulpIntrHead:
    mov esi,fs:[edx].oes_next_va
    mov ecx,fs:[edx].oes_nexted
    mov ds:[di].oes_next_va,esi
    mov ds:[di].oes_nexted,ecx

ulpDone:
    popad
    pop gs
    pop fs
    ret
UnlinkPipe      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkPipes
;
;       DESCRIPTION:    Unlink pipes
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkPipes   Proc near
    push ebx
    push ecx
    push esi
;
    call UnlinkControl
;
    mov cx,15
    mov si,OFFSET dev_in_ep_arr

upInLoop:
    mov bx,es:[si]
    or bx,bx
    jz upInNext
;
    call UnlinkPipe

upInNext:
    add si,2
    loop upInLoop
;
    mov cx,15
    mov si,OFFSET dev_out_ep_arr

upOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz upOutNext
;
    call UnlinkPipe

upOutNext:
    add si,2
    loop upOutLoop
;
    pop esi
    pop ecx
    pop ebx
    ret
UnlinkPipes     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateAddress
;
;       DESCRIPTION:    Allocate address
;
;       PARAMETERS:     DS          Function sel
;
;       RETURNS:        AL          Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateAddress   Proc far
    AllocateUsbAddress
    retf32
AllocateAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeAddress
;
;       DESCRIPTION:    Free address
;
;       PARAMETERS:     DS          Function sel
;                       AL          Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeAddress   Proc far
    FreeUsbAddress
    retf32
FreeAddress   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               CreateDev
;
;       DESCRIPTION:        Create device sel
;
;       PARAMETERS:         DS      Function selector
;                           AL      Address
;                           AH      Speed
;                           BX      Hub selector
;                           DX      Port #
;
;       RETURNS:            ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDev   Proc far
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    mov ax,SIZE ohc_td_struc
    mov si,SIZE ohci_dev_sel
    mov cx,16
    CreateMemBlk32
;
    xor ax,ax
    mov cx,15
    mov di,OFFSET dev_in_ep_arr
    rep stosw
;
    mov cx,15
    mov di,OFFSET dev_out_ep_arr
    rep stosw
;
    call AllocateTd
    mov es:dev_control_head,edx
    mov es:dev_curr_addr,0
;
    popad
    pop fs
;
    InitUsbDev
    retf32
CreateDev  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               FreeDev
;
;       DESCRIPTION:        Free device sel
;
;       PARAMETERS:         ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDev   Proc far
    FreeMemBlk
    retf32
FreeDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               AddressDev
;
;       DESCRIPTION:        Address usb dev
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device selector
;                           AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddressDev   Proc far
    AddressUsbDev    
    jc adDone
;
    push fs
    push edx
;
    mov dx,flat_sel
    mov fs,dx
    mov edx,es:dev_control_ed
    mov byte ptr fs:[edx].oes_fa_en,al
;
    pop edx
    pop fs
    clc

adDone:
    retf32
AddressDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               ConfigDev
;
;       DESCRIPTION:        Config usb dev
;
;       PARAMETERS:         DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigDev   Proc far
    clc
    retf32
ConfigDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateQueue
;
;           DESCRIPTION:    Update done queue
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateQueue   Proc near
    push eax
    push bx
;    
    xor eax,eax
    mov bx,ohc_hca_base + OFFSET hcca_done_head
    lock xchg eax,ds:[bx]
    and al,NOT 1
    or eax,eax
    jz update_queue_done
;
    mov bx,ds:ohc_thread
    Signal

update_queue_done:
    pop bx
    pop eax
    ret
UpdateQueue   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           HandlerThread
;
;   DESCRIPTION:    Handler thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..OHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handler_thread_name  DB 'OHCI Dev ', 0

handler_thread:
    mov ds,bx
    mov cl,dl
    mov gs,ds:ohc_reg_sel
;    
    movzx si,cl
    shl si,2
    movzx di,cl
    add di,di
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[di].usb_thread_arr,ax
    LeaveSection ds:usb_section

htTryAttach:
    mov dx,10

htCheck:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[si].HcRhPortStatus
    test al,1
    jz htDetached
;
    sub dx,1
    jnz htCheck
;    
    LockUsb
;    
    mov eax,10h
    mov gs:[si].HcRhPortStatus,eax

htResetLoop:
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[si].HcRhPortStatus
    test al,1
    jz htUnlock
;    
    test al,10h
    jnz htResetLoop
; 
    mov eax,2
    mov gs:[si].HcRhPortStatus,eax
;
    mov dx,40

htWaitNotify:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[si].HcRhPortStatus
    test al,1
    jz htUnlock
;
    sub dx,1
    jnz htWaitNotify
;    
    mov ax,25
    WaitMilliSec
;
    call fword ptr ds:allocate_address_proc
    jc htUnlock
;
    mov dl,al
    mov eax,gs:[si].HcRhPortStatus
    shr ah,1
    and ah,1
    xor ah,1
    mov al,dl
    movzx dx,cl
    call fword ptr ds:create_dev_proc
;
    call fword ptr ds:create_control_proc
    call fword ptr ds:address_device_proc
    jc htUnlock
;
    call fword ptr ds:change_address_proc
    AddUsbDevice
    UnlockUsb
    ReadUsbDescriptors
    jc htDetach
;
    mov al,cl
    NotifyUsbAttach

htAttached:
    WaitForSignal
;
    call fword ptr ds:is_dev_connected_proc
    jc htDetach
;
    mov ax,1
    shl ax,cl
    test ax,ds:ohc_reset
    jz htHandle
;
    not ax
    lock and ds:ohc_reset,ax
    jmp htDetach

htHandle:
    jmp htAttached

htUnlock:
    mov eax,gs:[si].HcRhPortStatus
    test al,1
    jz htDoUnlock
;
    mov eax,1
    mov gs:[si].HcRhPortStatus,eax
;
    mov ax,25
    WaitMilliSec

htDoUnlock:
    UnlockUsb
    jmp htDetached

htDetach:
    call UnlinkPipes
;
    mov al,cl
    NotifyUsbDetach
;
    mov eax,gs:[si].HcRhPortStatus
    test al,1
    jz htDone
;
    mov eax,1
    mov gs:[si].HcRhPortStatus,eax
;
    mov ax,25
    WaitMilliSec

htDetached:
    mov eax,gs:[si].HcRhPortStatus
    test al,1
    jz htDone
;
    mov dx,10

htWaitDisable:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[si].HcRhPortStatus
    test al,1
    jz htDone
;
    test al,2
    jz htTryAttach
;
    sub dx,1
    jnz htWaitDisable
    jmp htTryAttach

htDone:    
    EnterSection ds:usb_section
    mov ds:[edi].usb_thread_arr,0
    LeaveSection ds:usb_section
;
    TerminateThread
        
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
;           NAME:           UpdatePort
;
;           DESCRIPTION:    Update root-hub port status
;
;       PARAMETERS:     DS      Function selector
;               CL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push ds
    push es
    push fs
    pushad
;    
    movzx si,cl
    shl si,2
    movzx edi,cl
    add edi,edi
    mov es,ds:ohc_reg_sel
;
    mov eax,es:[si].HcRhPortStatus
    test al,1
    stc
    jz upDetach
    
upAttach:
    mov bx,ds:[edi].usb_thread_arr
    or bx,bx
    jnz upCheckReset
;
    mov ds:[edi].usb_thread_arr,-1
;    
    mov bx,ds
    mov dx,cx
;
    mov esi,OFFSET handler_thread_name
    mov eax,100h
    AllocateSmallGlobalMem
    xor edi,edi

upCopyLoop:
    mov al,cs:[esi]
    inc esi
    or al,al
    jz upCopyDone
;
    stosb
    jmp upCopyLoop

upCopyDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,cl
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;   
    xor edi,edi
    mov eax,cs
    mov ds,eax
    mov esi,OFFSET handler_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
;
    FreeMem
    jmp upDone

upCheckReset:
    mov ax,1
    shl ax,cl
    test ax,ds:ohc_reset
    jz upDone
;
    Signal
    jmp upDone

upDetach:
    EnterSection ds:usb_section
    mov bx,ds:[edi].usb_thread_arr
    or bx,bx
    jz upLeave
;    
    Signal

upLeave:
    LeaveSection ds:usb_section
            
upDone:    
    popad
    pop fs
    pop es
    pop ds    
    ret
UpdatePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdateUsb
;
;           DESCRIPTION:    Update USB status
;
;       PARAMETERS:         DS          Function
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateUsb  Proc near
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:OhciFuncCount
    or cx,cx
    jz uuDone
;    
    mov si,OFFSET OhciFuncArr

uuLoop:    
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
;    
    xor cx,cx

uuPortLoop:    
    call UpdatePort
    inc cx
    cmp cx,ds:ohc_root_ports
    jb uuPortLoop   
;
    pop si
    pop cx
    pop ds
;
    add si,2
    loop uuLoop    
    
uuDone:    
    ret
UpdateUsb   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ohci_timer
;
;           DESCRIPTION:    Timer that scans for status change in controller
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ohci_timer  Proc far
    push edx
    push eax
;    
    mov ax,SEG data
    mov ds,ax
;
    mov cx,ds:OhciFuncCount
    or cx,cx
    jz otDone
;
    mov si,OFFSET OhciFuncArr

otLoop:
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
    mov es,ds:ohc_reg_sel
    mov eax,es:HcInterruptStatus
    test al,2
    jz otQueueDone
;
    call UpdateQueue

otQueueDone:
    test al,20h
    jz otHubDone
;
    push ds
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:PortThread
    Signal
    pop ds

otHubDone:        
    mov es,ds:ohc_reg_sel
    mov es:HcInterruptStatus,eax
    or ds:ohc_int_status,eax

otNext:
    pop si
    pop cx
    pop ds
;
    add si,2
    loop otLoop

otDone:    
    pop eax   
    pop edx
;    
    GetSystemTime
    add eax,1193
    adc edx,0
    mov bx,cs
    mov es,bx
    mov bx,cs
    mov edi,OFFSET ohci_timer
    StartTimer
    retf32
ohci_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           BiosHandoff
;
;           DESCRIPTION:    Do BIOS handoff
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BiosHandoff    Proc near
    push fs
    push eax
;
    mov fs,ds:ohc_reg_sel
    test fs:HcControl,100h
    jz bhDone
;
    or fs:HcCommandStatus,8    

bhWait:
    test fs:HcControl,100h    
    jnz bhWait
        
bhDone: 
    mov eax,fs:HcFmInterval
    mov ds:ohc_fm_reg,eax
;
    mov eax,0C000007Fh    
    mov fs:HcInterruptStatus,eax
;    
    or fs:HcCommandStatus,1
;
    mov ax,5
    WaitMilliSec
    mov eax,fs:HcControl
    and al,NOT 0C0h
    or al,40h
    mov fs:HcControl,eax
;
    pop eax
    pop fs
    ret
BiosHandoff    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OHCI function handler
;
;           DESCRIPTION:    OHCI function thread
;
;       PARAMETERS:         BX      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ohci_function_handler:
    mov ds,bx
    GetThread
    mov ds:ohc_thread,ax

ofhLoop:
    WaitForSignal    
    jmp ofhLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartThread
;
;       DESCRIPTION:    Start thread
;
;       PARAMETERS:     DS      Function sel (passed as bx)
;                       DX      Passed through
;                       AX      Prio
;                       SI      Entry
;                       DI      Name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartThread Proc near
    push es            
    push ax
    push si
;
    mov si,di
    mov eax,100h
    AllocateSmallGlobalMem
    xor di,di

sfCopyLoop:
    mov al,cs:[si]
    inc si
    or al,al
    jz sfCopyDone
;
    stosb
    jmp sfCopyLoop

sfCopyDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;   
    pop si         
    mov bx,ds
    xor di,di
    mov ax,cs
    mov ds,ax
    pop ax
    mov cx,stack0_size
    CreateThread
;
    FreeMem
    pop es
    ret
StartThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartFunctionThread
;
;           DESCRIPTION:    Start OHCI function thread
;
;       PARAMETERS:         DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

func_name    DB 'OHCI ', 0

StartFunctionThread Proc near
    mov si,OFFSET ohci_function_handler
    mov di,OFFSET func_name
    mov ax,5
    call StartThread
    ret
StartFunctionThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitFunction
;
;           DESCRIPTION:    Init OHCI function
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ohci_tab:
ot00 DD OFFSET AllocateAddress,     SEG code
ot01 DD OFFSET FreeAddress,         SEG code
ot02 DD OFFSET CreateDev,           SEG code
ot03 DD OFFSET FreeDev,             SEG code
ot04 DD OFFSET CreateControl,       SEG code
ot05 DD OFFSET CreateBulk,          SEG code
ot06 DD OFFSET CreateIntr,          SEG code
ot07 DD OFFSET AddOut,              SEG code
ot08 DD OFFSET AddIn,               SEG code
ot09 DD OFFSET IssueTransfer,       SEG code
ot0A DD OFFSET IsTransferDone,      SEG code
ot0B DD OFFSET EndTransfer,         SEG code
ot0C DD OFFSET WasTransferOk,       SEG code
ot0D DD OFFSET GetDataSize,         SEG code
ot0E DD OFFSET ClosePipe,           SEG code
ot0F DD OFFSET WaitForCompletion,   SEG code
ot10 DD OFFSET ChangeAddress,       SEG code
ot11 DD OFFSET IsConnected,         SEG code
ot12 DD OFFSET ResetDev,            SEG code
ot13 DD OFFSET LockEnum,            SEG code
ot14 DD OFFSET UnlockEnum,          SEG code
ot15 DD OFFSET Has64Bit,            SEG code
ot16 DD OFFSET IsStalled,           SEG code
ot17 DD OFFSET ClearStalled,        SEG code
ot18 DD OFFSET AddressDev,          SEG code
ot19 DD OFFSET ConfigDev,           SEG code
ot1A DD OFFSET UpdateMaxLen,        SEG code
ot1B DD OFFSET IssueOne,            SEG code
ot1C DD OFFSET IsDeviceConnected,   SEG code
ot1D DD OFFSET ControlMsg,          SEG code
ot1E DD OFFSET ConfigPipe,          SEG code

InitFunction    Proc near
    push ds
    push es
    push fs
    pushad
;
    mov bh,ds:ohc_usb_bus
    mov bl,ds:ohc_usb_dev
    mov ch,ds:ohc_usb_func
    GetPciMsi
    jc ifIrq
;
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc ifIrq    
;
    SetupPciMsi
;    
    mov di,cs
    mov es,di
    mov edi,OFFSET OhciInt
    RequestMsiHandler
    jmp ifIntDone

ifIrq:
    mov ds:ohc_irq,0
    GetPciIrqNr
    jc ifIrqFail
;    
    mov ds:ohc_irq,al
    mov ah,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET OhciInt
    RequestIrqHandler

ifIntDone:
    mov es,ds:ohc_reg_sel
    mov eax,80000002h
    mov es:HcInterruptEnable,eax    
    jmp ifIrqDone

ifIrqFail:
    mov ax,SEG data
    mov es,ax
    mov es:UseTimer,1

ifIrqDone: 
    mov ax,flat_sel
    mov es,ax   
;    
    mov si,OFFSET ohci_tab
    xor di,di
    mov cx,2*1Fh

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbFunction
;    
    InitSection ds:ohc_section
    mov fs,ds:ohc_reg_sel
;
    WaitForEhci
;    
    mov edx,ds:ohc_fm_reg
    mov fs:HcFmInterval,edx
    mov fs:HcPeriodicStart,0
;    
    mov ax,25
    WaitMilliSec    
;
    mov bx,ohc_hca_base + OFFSET hcca_done_head
    xor eax,eax
    mov ds:[bx],eax
;    
    call CreateInterrupt
;    
    mov eax,ohc_hca_base
    add eax,ds:ohc_phys
    mov fs:HcHCCA,eax
;    
    mov ds:ohc_control_linear,0
    mov fs:HcControlHeadED,0
;    
    mov ds:ohc_bulk_linear,0
    mov fs:HcBulkHeadED,0
;
    mov eax,fs:HcControl
    and ax,0F83Fh
    or al,0BCh
    mov fs:HcControl,eax
;
    mov eax,fs:HcRhDescriptorA
    and ah,NOT 3
    or ah,1
    mov fs:HcRhDescriptorA,eax
;    
    mov eax,fs:HcRhDescriptorB
    or eax,0FFFF0000h
    mov fs:HcRhDescriptorB,eax    
;
    mov eax,fs:HcRhDescriptorA
    movzx ax,al
    or ax,ax
    jnz ifPortsOk
;
    inc ax

ifPortsOk:    
    mov ds:ohc_root_ports,ax
;
    mov cx,ds:ohc_root_ports
    or cx,cx
    jz ifPowerDone
;    
    xor si,si
    mov eax,100h

ifPowerLoop:    
    mov fs:[si].HcRhPortStatus,eax
    add si,4
    loop ifPowerLoop

ifPowerDone:
    popad
    pop fs
    pop es
    pop ds
    ret
InitFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddFunction
;
;           DESCRIPTION:    Add OHCI function
;
;       PARAMETERS:     BX      Bus/device
;               CH      Function
;               EAX     Register base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFunction  Proc near
    push es
    push ds
    push eax
    push bx
    push edx
    push di
    push bp
;    
    push bx
    push cx
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    xor ebx,ebx
    or ax,813h
    SetPageEntry
;
    push ecx
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
    mov bp,bx
;     
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    mov al,13h
    SetPageEntry
;    
    mov ecx,1000h
    AllocateGdt
    CreateDataSelector16
    mov ds,bx
    mov es,bx
    xor di,di
    xor eax,eax
    mov cx,400h
    rep stosd
;
    InitSection ds:ohc_enum_section
    mov ds:ohc_reset,0
    mov ds:ohc_reg_sel,bp
    mov ds:ohc_int_status,0
    mov ds:ohc_linear,edx
    mov bp,bx
;
    pop cx
    pop bx
;    
    mov ds:ohc_usb_bus,bh
    mov ds:ohc_usb_dev,bl
    mov ds:ohc_usb_func,ch
;
    GetPageEntry
    or ebx,ebx
    jz af32
;
    int 3    

af32:    
    and ax,0F000h
    mov ds:ohc_phys,eax
;     
    mov eax,1000h
    AllocateBigLinear
    mov ecx,eax
    AllocateGdt
    CreateDataSelector16
    mov ds:ohc_map_linear,edx
    mov ds:ohc_map_sel,bx
;
    mov ax,SEG data
    mov ds,ax
    mov si,ds:OhciFuncCount
    add si,si
    mov ds:[si].OhciFuncArr,bp
    inc ds:OhciFuncCount
;    
    pop bp
    pop di
    pop edx
    pop bx
    pop eax    
    pop ds
    pop es
    ret
AddFunction Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPciAdapter  Proc near
    xor ax,ax
    mov bh,0Ch
    mov bl,3
    mov ch,10h
    FindPciClass
    jc init_pci_done
;
    mov cl,10h
    ReadPciDword
    and ax,0F000h
    mov ebp,eax
    call AddFunction
;       
    mov dx,1

init_pci_next_device:
    mov ax,dx
    mov bh,0Ch
    mov bl,3
    mov ch,10h
    FindPciClass
    jc init_pci_done
;       
    mov cl,10h
    ReadPciDword
    and ax,0F000h
    cmp eax,ebp
    je init_pci_done
;       
    call AddFunction
    inc dx
    jmp init_pci_next_device
    
init_pci_done:
    ret
InitPciAdapter  Endp

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

ohci_name       DB 'OHCI',0

ohci_thread:
    mov ax,SEG data
    mov ds,ax
    mov ds:UseTimer,0
    GetThread
    mov ds:PortThread,ax
;    
    mov si,OFFSET OhciFuncArr
    mov cx,ds:OhciFuncCount

otHandoffLoop:
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
    call BiosHandoff
;
    pop si
    pop cx    
    pop ds
;
    add si,2
    loop otHandoffLoop
;
    mov ax,20
    WaitMilliSec
;
    EnterSection ds:WaitSection
    mov ds:Started,1
    mov bx,ds:WaitThreadArr
    Signal
    mov bx,ds:WaitThreadArr+2
    Signal
    mov bx,ds:WaitThreadArr+4
    Signal
    LeaveSection ds:WaitSection 
;    
    mov si,OFFSET OhciFuncArr
    mov cx,ds:OhciFuncCount
    
otInitLoop:
    ClearSignal
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
    call InitFunction
    call StartFunctionThread
;
    pop si
    pop cx    
    pop ds
;
    add si,2
    loop otInitLoop
;
    mov al,ds:UseTimer
    or al,al
    jz otTimerStarted
;    
    GetSystemTime
    add eax,11930
    adc edx,0
    mov bx,cs
    mov es,bx
    mov bx,cs
    mov edi,OFFSET ohci_timer
    StartTimer

otTimerStarted:       
    call UpdateUsb

ohci_thread_loop:
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForSignalWithTimeout
    call UpdateUsb
    jmp ohci_thread_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_usb
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_usb    Proc far
    push ds
    push es
    pusha
;
    mov ax,SEG data
    mov ds,ax
    call InitPciAdapter
    mov cx,ds:OhciFuncCount
    or cx,cx    
    jz init_usb_done
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET ohci_name
    mov si,OFFSET ohci_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread

init_usb_done:
    popa
    pop es
    pop ds
    retf32
init_usb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WaitForOhci
;
;           DESCRIPTION:    Wait for OHCI to initialize
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

wait_for_ohci_name  DB 'Wait For Ohci', 0

wait_for_ohci   Proc far
    push ds
    push ax
    push bx
;
    mov ax,SEG data
    mov ds,ax
;
    EnterSection ds:WaitSection
    mov al,ds:Started
    or al,al
    jnz wfoDone    
;
    mov bx,OFFSET WaitThreadArr

wfoLoop:
    mov ax,ds:[bx]
    or ax,ax
    jz wfoFound
;
    add bx,2
    jmp wfoLoop

wfoFound:        
    GetThread
    mov ds:[bx],ax    
    LeaveSection ds:WaitSection   

wfoSignal:
    WaitForSignal
;    
    EnterSection ds:WaitSection    
    mov al,ds:Started
    or al,al
    jz wfoSignal
    
wfoDone:
    LeaveSection ds:WaitSection
;    
    pop bx
    pop ax
    pop ds
    retf32
wait_for_ohci   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov bx,SEG data
    mov ds,bx       
    mov ds:OhciFuncCount,0
;
    InitSection ds:WaitSection
    mov ds:WaitThreadArr,0
    mov ds:WaitThreadArr+2,0
    mov ds:WaitThreadArr+4,0
    mov ds:Started,0
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET wait_for_ohci
    mov edi,OFFSET wait_for_ohci_name
    xor cl,cl
    mov ax,wait_for_ohci_nr
    RegisterOsGate
;    
    mov edi,OFFSET init_usb
    HookInitPci
;
    clc
;
    ret
Init    Endp

code ENDS

    END init
