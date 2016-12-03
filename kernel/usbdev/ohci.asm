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
INCLUDE ..\os\proc.inc
INCLUDE ..\pcdev\pci.inc
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

; this structure should be kept less than 32 bytes long!

ohc_es_struc    STRUC

;HC part

oes_fa_en       DW ?
oes_mps     DW ?
oes_tailp       DD ?
oes_headp       DD ?
oes_nexted      DD ?

;driver part

oes_my_va       DD ?
oes_tail_va     DD ?
oes_head_va     DD ?
oes_next_va     DD ?

ohc_es_struc    ENDS


; this structure should be kept less than 32 bytes long!

ohc_td_struc    STRUC

;HC part

otd_resv    DW ?
otd_flags       DW ?
otd_cbp     DD ?
otd_next_td     DD ?
otd_be      DD ?

;driver part

otd_phys        DD ?
otd_next_va     DD ?
otd_buffer_va   DD ?
otd_buffer_size DW ?
otd_spare       DW ?

ohc_td_struc    ENDS

OSP_FLAG_TRANSFER_PENDING   = 1
OSP_FLAG_TRANSFER_OK    = 2

ohci_pipe   STRUC

osp_pipe_base       usb_pipe_struc <>
osp_ed          DD ?
osp_prev        DW ?
osp_next        DW ?
osp_signal      DW ?
osp_intr_list       DW ?
osp_intr_count      DW ?
osp_data_size       DW ?
osp_setup_linear    DD ?
osp_flags       DB ?

ohci_pipe   ENDS

ohci_func_sel   STRUC

usb_dev_base    usb_dev_struc <>

ohc_reg_sel     DW ?
ohc_map_sel     DW ?
ohc_map_linear      DD ?
ohc_int_status      DD ?
ohc_linear      DD ?
ohc_phys        DD ?
ohc_control_linear  DD ?
ohc_bulk_linear     DD ?
ohc_pipe_list       DW ?
ohc_thread          DW ?

ohc_pipe_section    section_typ <>
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

data    SEGMENT byte public 'DATA'

OhciUsedBlocks  DD ?
OhciCloseCount  DD ?
OhciList32      DD ?
OhciSection     section_typ <>

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
;           NAME:           AllocateBlock32
;
;           DESCRIPTION:    Allocate 32-byte block with page-alignment
;
;       PARAMETERS:     ES      Flat sel
;
;           RETURNS:        EDX         Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlock32 PROC near
    push ds
    push eax
;    
    mov ax,SEG data
    mov ds,ax
    EnterSection ds:OhciSection
    inc ds:OhciUsedBlocks
    mov edx,ds:OhciList32
    or edx,edx
    jnz allocate_block32_done
;
    push ecx    
    mov eax,1000h
    AllocateBigLinear
;
    push ebx    
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    pop ebx
;    
    mov ecx,32
    mov ds:OhciList32,edx
;
    push ebx    
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    pop ebx
    
allocate_block32_loop:
    mov eax,edx
    add eax,ecx
    mov es:[edx],eax
    mov edx,eax
    test dx,0FFFh
    jnz allocate_block32_loop
;
    sub edx,ecx
    mov dword ptr es:[edx],0
    mov edx,ds:OhciList32
    pop ecx

allocate_block32_done:
    mov eax,es:[edx]
    mov ds:OhciList32,eax
    LeaveSection ds:OhciSection
;
    pop eax
    pop ds
    ret
AllocateBlock32 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeBlock32
;
;           DESCRIPTION:    Free 32-byte block
;
;       PARAMETERS:     ES      Flat sel
;
;           PARAMETERS:         EDX         Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBlock32     PROC near
    push ds
    push eax
;
    mov ax,SEG data
    mov ds,ax
;    
    EnterSection ds:OhciSection
    dec ds:OhciUsedBlocks
    mov eax,ds:OhciList32
    mov es:[edx],eax
    mov ds:OhciList32,edx
    LeaveSection ds:OhciSection
;       
    pop eax
    pop ds
    ret
FreeBlock32     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InsertPipe
;
;           DESCRIPTION:    Insert pipe into function pipe-list
;
;       PARAMETERS:     DS      Function
;               FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertPipe  Proc near
    push di
    EnterSection ds:ohc_pipe_section
;
    mov di,ds:ohc_pipe_list
    or di,di
    je ipEmpty
;       
    push ds
    push si
    mov ds,di
    mov si,ds:osp_prev
    mov ds:osp_prev,fs
    mov ds,si
    mov ds:osp_next,fs
    mov fs:osp_next,di
    mov fs:osp_prev,si
    pop si
    pop ds
    pop di
    jmp ipDone
    
ipEmpty:
    mov fs:osp_next,fs
    mov fs:osp_prev,fs
    pop di
    mov ds:ohc_pipe_list,fs

ipDone:
    mov fs:osp_signal,0
    mov fs:osp_flags,0
    LeaveSection ds:ohc_pipe_section
    ret
InsertPipe  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           RemovePipe
;
;           DESCRIPTION:    Remove pipe from function pipe-list
;
;       PARAMETERS:     DS      Function
;               FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemovePipe  Proc near
    push si
    push di
;       
    EnterSection ds:ohc_pipe_section
    push ds
    mov si,fs:osp_prev
    mov di,fs:osp_next
    mov ds,di
    mov ds:osp_prev,si
    mov ds,si
    mov ds:osp_next,di
    pop ds
;
    mov si,fs
    cmp si,ds:ohc_pipe_list
    jne rpDone
;
    cmp si,di
    je rpEmpty
;
    mov ds:ohc_pipe_list,di
    jmp rpDone    

rpEmpty:
    mov ds:ohc_pipe_list,0    

rpDone:
    LeaveSection ds:ohc_pipe_section
    pop di
    pop si
    ret
RemovePipe  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitEd
;
;           DESCRIPTION:    Initialize an already allocated ED
;
;       PARAMETERS:     DS      Function sel
;               ES      Flat sel
;               EDX     ED
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitEd  PROC near
    mov es:[edx].oes_fa_en,4000h
    mov es:[edx].oes_mps,0
    mov es:[edx].oes_tailp,0
    mov es:[edx].oes_headp,0
    mov es:[edx].oes_nexted,0
    mov es:[edx].oes_my_va,edx
    mov es:[edx].oes_tail_va,0
    mov es:[edx].oes_head_va,0
    mov es:[edx].oes_next_va,0
    ret
InitEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTd
;
;           DESCRIPTION:    Initialize an already allocated TD
;
;       PARAMETERS:     ES      Flat sel
;               FS      Pipe sel
;               EDX     TD
;               EAX     Physical address of TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTd  PROC near
    mov es:[edx].otd_resv,0
    mov es:[edx].otd_flags,0E4h
    mov es:[edx].otd_cbp,0
    mov es:[edx].otd_next_td,0
    mov es:[edx].otd_be,0
    mov es:[edx].otd_phys,eax
    mov es:[edx].otd_next_va,0
    ret
InitTd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateEd
;
;           DESCRIPTION:    Allocate & initialize an endpoint descriptor
;
;       PARAMETERS:     DS      Function selector
;               ES      Flat sel
;
;           RETURNS:        EDX         Linear address of ED
;               EAX     Physical address of ED
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateEd      PROC near
    push cx
    call AllocateBlock32
    call InitEd
;
    push ebx
    GetPageEntry
    or ebx,ebx
    jz ae32
;
    int 3

ae32:    
    pop ebx
;    
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
    ret
AllocateEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AllocateTd
;
;           DESCRIPTION:    Allocate & initialize transfer descriptor
;
;       PARAMETERS:     ES      Flat sel
;                       FS      Pipe sel
;
;           RETURNS:    EDX     Linear address of TD
;                       EAX     Physical address of TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTd      PROC near
    push cx
    call AllocateBlock32
;
    push ebx
    GetPageEntry
    or ebx,ebx
    jz at32
;
    int 3

at32:    
    pop ebx
;    
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    call InitTd
;    
    pop cx
    ret
AllocateTd  ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddControlEd
;
;           DESCRIPTION:    Add control ED 
;
;       PARAMETERS:     DS      Function sel
;               ES      Flat sel
;               FS      Pipe sel
;
;       RETURNS:    EDX     Linear address of ED added
;               EAX     Physical address of ED added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddControlEd    PROC near
    push gs
    push ebx
;
    EnterSection ds:ohc_section
    call AllocateEd
    mov gs,ds:ohc_reg_sel
    mov ebx,gs:HcControlHeadEd
    mov es:[edx].oes_nexted,ebx
    mov ebx,ds:ohc_control_linear
    mov es:[edx].oes_next_va,ebx
;
    mov ds:ohc_control_linear,edx
    mov gs:HcControlHeadEd,eax
;
    mov ebx,edx
    push eax
    push edx
;    
    call AllocateTd
    mov es:[ebx].oes_headp,eax
    mov es:[ebx].oes_tailp,eax
    mov es:[ebx].oes_head_va,edx
    mov es:[ebx].oes_tail_va,edx
;    
    pop edx
    pop eax
    LeaveSection ds:ohc_section
;    
    pop ebx
    pop gs
    ret
AddControlEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddBulkEd
;
;           DESCRIPTION:    Add bulk ED 
;
;       PARAMETERS:     DS      Function sel
;               ES      Flat sel
;               FS      Pipe sel
;
;       RETURNS:    EDX     Linear address of ED added
;               EAX     Physical address of ED added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBulkEd       PROC near
    push gs
    push ebx
;
    EnterSection ds:ohc_section
    call AllocateEd
    mov gs,ds:ohc_reg_sel
    mov ebx,gs:HcBulkHeadEd
    mov es:[edx].oes_nexted,ebx
    mov ebx,ds:ohc_bulk_linear
    mov es:[edx].oes_next_va,ebx
;
    mov ds:ohc_bulk_linear,edx
    mov gs:HcBulkHeadEd,eax
;
    mov ebx,edx
    push eax
    push edx
;    
    call AllocateTd
    mov es:[ebx].oes_headp,eax
    mov es:[ebx].oes_tailp,eax
    mov es:[ebx].oes_head_va,edx
    mov es:[ebx].oes_tail_va,edx
;    
    pop edx
    pop eax
    LeaveSection ds:ohc_section
;    
    pop ebx
    pop gs
    ret
AddBulkEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetIntrEd
;
;           DESCRIPTION:    Get interrupt ED
;
;       PARAMETERS:     DS      Function sel
;               ES      Flat sel
;               FS      Pipe sel
;               CL      Interval
;
;       RETURNS:    DI      Offset to ED list entry to use
;               SI      Offset to count array
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
;           NAME:           AddIntrEd
;
;           DESCRIPTION:    Add interrupt ED 
;
;       PARAMETERS:     DS      Function sel
;               ES      Flat sel
;               FS      Pipe sel
;               CL      Interval
;
;       RETURNS:    EDX     Linear address of ED added
;               EAX     Physical address of ED added
;               SI      Interrupt count array entry
;               DI      Interrupt ED used
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntrEd       PROC near
    push ebx
;
    EnterSection ds:ohc_section
    call AllocateEd
;
    call GetIntrEd
    mov ebx,ds:[di].oes_next_va
    mov es:[edx].oes_next_va,ebx
    mov ebx,ds:[di].oes_nexted
    mov es:[edx].oes_nexted,ebx
;
    mov ds:[di].oes_next_va,edx
    mov ds:[di].oes_nexted,eax
;
    mov ebx,edx
    push eax
    push edx
;    
    call AllocateTd
    mov es:[ebx].oes_headp,eax
    mov es:[ebx].oes_tailp,eax
    mov es:[ebx].oes_head_va,edx
    mov es:[ebx].oes_tail_va,edx
;    
    pop edx
    pop eax
    LeaveSection ds:ohc_section
;    
    pop ebx
    ret
AddIntrEd  ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPipeEd
;
;           DESCRIPTION:    Init endpoint descriptor from pipe
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               ES      Flat sel
;               EDX     ED linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPipeEd  Proc near
    push eax
    push edx
;
    mov ax,fs:usbp_maxlen
    cmp ax,800h
    jb init_pipe_size_ok
;    
    mov ax,7FFh

init_pipe_size_ok:
    mov es:[edx].oes_mps,ax
;
    mov ah,fs:usbp_endpoint
    xor al,al
    shr ax,1
    or al,fs:usbp_address
;    
    cmp fs:usbp_speed,0
    jnz init_pipe_speed_ok
;
    or ah,20h

init_pipe_speed_ok:    
    mov es:[edx].oes_fa_en,ax

init_pipe_done:
    pop edx
    pop eax
    ret
InitPipeEd  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddPipeTd
;
;           DESCRIPTION:    Add TD to pipe
;
;       PARAMETERS:     DS      Function selector
;               ES      Flat sel
;               FS      Pipe
;               EDI     Data buffer
;               CX      Size of data
;               AX      Flags field of TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPipeTd       PROC near
    push eax
    push ebx
    push ecx
    push edx
;    
    mov edx,fs:osp_ed
    mov ebx,es:[edx].oes_tail_va
    or ebx,ebx
    jz add_pipe_done
;    
    or ax,0F000h
    mov es:[ebx].otd_flags,ax
    mov es:[ebx].otd_buffer_size,cx
    mov es:[ebx].otd_buffer_va,edi
;
    or cx,cx
    jnz add_pipe_has_buffer
;
    mov eax,1
    jmp add_pipe_buf_ads_ok    

add_pipe_has_buffer:    
    push cx
    push edx
    mov al,es:[edi]
    mov edx,edi    
;
    push ebx
    GetPageEntry
    or ebx,ebx
    jz apt32
;
    int 3

apt32:
    pop ebx
;    
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop edx
    pop cx

add_pipe_buf_ads_ok:
    movzx ecx,cx
;
    mov es:[ebx].otd_cbp,eax
    add eax,ecx
    dec eax
    mov es:[ebx].otd_be,eax
;
    call AllocateTd
    mov es:[ebx].otd_next_td,eax
    mov es:[ebx].otd_next_va,edx    
;
    mov ebx,fs:osp_ed
    mov es:[ebx].oes_tail_va,edx
    mov es:[ebx].oes_tailp,eax

add_pipe_done:    
    pop edx
    pop ecx
    pop ebx
    pop eax   
    ret
AddPipeTd   Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateInterrupt
;
;           DESCRIPTION:    Create interrupt queues
;
;       PARAMETERS:     DS  Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateInterrupt PROC near
    push eax
    push bx
    push cx
    push edx
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
    pop cx
    pop bx
    pop eax
    ret
CreateInterrupt Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateControl
;
;           DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Function selector
;                       AH      Speed
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    push es
    pushad
;    
    push ax
    mov eax,SIZE ohci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    pop ax
    mov es:usbp_speed,ah
;
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    mov al,13h
    SetPageEntry
    mov es:osp_setup_linear,edx
;    
    mov ax,es
    mov fs,ax
    mov dx,flat_sel
    mov es,dx
    call AddControlEd
    mov fs:osp_ed,edx
    call InsertPipe
;
    popad
    pop es
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
;                       AH      Speed
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    push es
    pushad
;    
    push ax
    mov eax,SIZE ohci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    pop ax
    mov es:usbp_speed,ah
;    
    mov ax,es
    mov fs,ax
    mov dx,flat_sel
    mov es,dx
    call AddBulkEd
    mov fs:osp_ed,edx
    call InsertPipe
;
    popad
    pop es
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
;                       AL      Interval
;                       AH      Speed
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    push es
    pushad
;    
    push ax
    mov eax,SIZE ohci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    pop ax
    mov es:usbp_speed,ah
    mov cl,al
;    
    mov ax,es
    mov fs,ax
    mov dx,flat_sel
    mov es,dx
    call AddIntrEd
    mov fs:osp_ed,edx
    mov fs:osp_intr_count,si
    mov fs:osp_intr_list,di
    call InsertPipe
;
    popad
    pop es
    retf32
CreateIntr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddBuffer
;
;           DESCRIPTION:    Allocate input/output buffer
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               CX      Size
;               ES:EDI  Buffer
;               AX      Flags field of TD

;             
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBuffer    Proc near
    push es
    pushad
;    
    movzx ecx,cx    
    mov si,ax
    or cx,cx
    jnz abHasData
;
    mov ax,flat_sel
    mov es,ax
    xor edi,edi
    mov ax,si
    and ax,NOT 0E0h
    or ax,20h
    call AddPipeTd
    jmp abDone

abHasData:
    mov bx,es
    cmp bx,flat_sel
    je abLoop
;    
    push ecx
    GetSelectorBaseSize
    add edx,edi
    sub ecx,edi
    mov eax,ecx
    pop ecx
    jc abDone  
;
    cmp eax,ecx
    jb abDone
;
    mov ax,flat_sel
    mov es,ax
    mov edi,edx    

abLoop:
    mov ax,1000h
    mov dx,di
    and dx,0FFFh
    sub ax,dx
    cmp ax,fs:usbp_maxlen
    jb abMinOk
;
    mov ax,fs:usbp_maxlen

abMinOk:
    cmp ax,cx
    jae abLast
;    
    movzx eax,ax
    push ax
    push cx
    mov cx,ax
    mov ax,si
    call AddPipeTd
    pop cx
    pop ax
    add edi,eax
    sub cx,ax
    jmp abLoop

abLast:    
    mov ax,si
    and ax,NOT 0E0h
    or ax,20h
    call AddPipeTd
    
abDone:
    popad
    pop es
    ret
AddBuffer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddSetup
;
;           DESCRIPTION:    Add setup transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;               CX      Buffer size
;               ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddSetup    Proc far
    push gs
    push es
    pushad
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne asDone
;    
    mov ax,es
    mov gs,ax
    mov esi,edi
;    
    mov ax,flat_sel
    mov es,ax   
    mov edi,fs:osp_setup_linear
;
    movzx ecx,cx
    push ecx
    push ecx
    shr ecx,2
    rep movs dword ptr es:[edi],gs:[esi]
    pop ecx
    and ecx,3
    rep movs byte ptr es:[edi],gs:[esi]
    pop ecx
;
    mov edi,fs:osp_setup_linear
    mov ax,2E4h
    call AddPipeTd

asDone:
    popad
    pop es
    pop gs 
    retf32
AddSetup    Endp

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
    push eax
    push ecx
    push edx
;
    mov ax,0ECh
    call AddBuffer
;    
    pop edx
    pop ecx
    pop eax    
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
    push eax
    push ecx
    push edx
;
    mov ax,0F4h
    call AddBuffer
;    
    pop edx
    pop ecx
    pop eax    
    retf32
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddStatusOut
;
;           DESCRIPTION:    Add status OUT transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusOut    Proc far
    push eax
    push ecx
    push edx
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne asoDone
;
    xor cx,cx
    mov ax,3ECh
    call AddBuffer

asoDone:
    pop edx
    pop ecx
    pop eax    
    retf32
AddStatusOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddStatusIn
;
;           DESCRIPTION:    Add status IN transaction to queue
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddStatusIn    Proc far
    push eax
    push ecx
    push edx
;
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne asiDone
;
    xor cx,cx
    mov ax,3F4h
    call AddBuffer

asiDone:
    pop edx
    pop ecx
    pop eax    
    retf32
AddStatusIn    Endp

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
    push es
    push eax
    push edx
;    
    mov ax,flat_sel
    mov es,ax
    mov edx,fs:osp_ed
;
    ClearSignal
    GetThread
    mov fs:osp_signal,ax
    and fs:osp_flags, NOT OSP_FLAG_TRANSFER_OK
    or fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
;    
    test es:[edx].oes_fa_en,4000h
    jz issue_transfer_enabled
;
    call InitPipeEd 

issue_transfer_enabled:    
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    jne issue_not_control
;
    push ds
    mov ds,ds:ohc_reg_sel
    mov eax,ds:HcCommandStatus
    or al,2
    mov ds:HcCommandStatus,eax
    pop ds
    jmp issue_done

issue_not_control:
    cmp al,MODE_BULK
    jne issue_done
;
    push ds
    mov ds,ds:ohc_reg_sel
    mov eax,ds:HcCommandStatus
    or al,4
    mov ds:HcCommandStatus,eax
    pop ds

issue_done:
    clc
    pop edx
    pop eax
    pop es
    retf32
IssueTransfer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalIsTransferDone
;
;           DESCRIPTION:    Check if transfer is done
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalIsTransferDone   Proc near
    push es
    push eax
    push bx
    push edx
;
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz itdOk
;
    call LocalIsConnected
    jc itdOk
;    
    mov ax,flat_sel
    mov es,ax
;    
    mov bx,fs:osp_signal
    or bx,bx
    jnz itdFail
;
    mov edx,fs:osp_ed
    mov eax,es:[edx].oes_headp
    test al,1
    jnz itdOk
;
    and ax,0FFF0h    
    cmp eax,es:[edx].oes_tailp
    je itdOk

itdFail:
    stc
    jmp itdDone    

itdOk:
    clc

itdDone:
    pop edx
    pop bx
    pop eax
    pop es
    ret
LocalIsTransferDone   Endp

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
    call LocalIsTransferDone
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
    push eax
;
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz wfcDone

wfcLoop:    
    call LocalIsTransferDone
    jnc wfcDone
;    
    WaitForSignal
    jmp wfcLoop

wfcDone:
    call LocalEndTransfer
;
    pop eax
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
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz wtoNotPending
;
    call LocalEndTransfer

wtoNotPending:
    test fs:osp_flags, OSP_FLAG_TRANSFER_OK
    jnz wtoOk
;    
    stc
    jmp wtoDone

wtoOk:
    clc

wtoDone:
    retf32
WasTransferOk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalEndTransfer
;
;           DESCRIPTION:    End transfer
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalEndTransfer   Proc near
    push es
    pushad
;    
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz etDone
;
    mov fs:osp_data_size,0     
    and fs:osp_flags, NOT OSP_FLAG_TRANSFER_PENDING
    and fs:osp_flags, NOT OSP_FLAG_TRANSFER_OK
;
    mov ax,flat_sel
    mov es,ax
    xor bp,bp

etLoop:
    mov eax,fs:osp_ed
    mov edx,es:[eax].oes_head_va
    or edx,edx
    jz etOk
;    
    mov ebx,es:[edx].otd_phys
    cmp ebx,es:[eax].oes_headp
    je etOk
;
    cmp ebx,es:[eax].oes_tailp
    je etOk
;
    mov ax,es:[edx].otd_flags
    and ax,18h
    cmp ax,10h
    jne etNext
;
    mov esi,es:[edx].otd_buffer_va
    or esi,esi
    jz etNext
;    
    mov ecx,es:[edx].otd_cbp
    or ecx,ecx
    jz etFull
;
    sub ecx,es:[edx].otd_buffer_va
    and ecx,0FFFh
    jmp etSizeOk   

etFull:
    movzx ecx,es:[edx].otd_buffer_size

etSizeOk:
    add bp,cx

etNext:
    mov edi,es:[edx].otd_next_va        
    call FreeBlock32
;
    mov ebx,edi
    mov eax,es:[edi].otd_phys
    and ax,0FFFh
    and bx,0FFFh
    cmp ax,bx
    je etValid
;
    int 3

etValid:
    mov edx,fs:osp_ed
    mov es:[edx].oes_head_va,edi
    jmp etLoop

etOk:
    mov fs:osp_data_size,bp
    or fs:osp_flags, OSP_FLAG_TRANSFER_OK

etReset:
    mov edx,fs:osp_ed
    or es:[edx].oes_fa_en,4000h

etDone:
    popad
    pop es
    ret
LocalEndTransfer   Endp

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
    call LocalEndTransfer
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
    test fs:osp_flags, OSP_FLAG_TRANSFER_OK
    jz gdsDone
;    
    mov cx,fs:osp_data_size

gdsDone:
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
    push es
    pushad
;    
    push ds
    mov ax,SEG data
    mov ds,ax
    inc ds:OhciCloseCount
    pop ds
;    
    call RemovePipe
;
    EnterSection ds:ohc_section
    mov edx,fs:osp_ed
    mov al,fs:usbp_mode
    cmp al,MODE_CONTROL
    je cpControl
;
    cmp al,MODE_BULK
    je cpBulk
;    
    cmp al,MODE_INTR
    je cpIntr
;    
    int 3
    jmp cpFreeEdList

cpControl:
    mov ax,flat_sel
    mov es,ax
;
    xor ecx,ecx
    mov ebx,ds:ohc_control_linear

cpControlLoop:
    cmp ebx,edx
    je cpControlUnlink
;
    mov ecx,ebx
    mov ebx,es:[ebx].oes_next_va
    or ebx,ebx
    jnz cpControlLoop
    jmp cpFreeEdList

cpControlUnlink:
    or ecx,ecx
    jz cpControlHead
;
    mov esi,es:[edx].oes_next_va
    mov edi,es:[edx].oes_nexted
    mov es:[ecx].oes_next_va,esi
    mov es:[ecx].oes_nexted,edi
    jmp cpFreeEdList

cpControlHead:
    push gs
    mov gs,ds:ohc_reg_sel
    mov esi,es:[edx].oes_next_va
    mov edi,es:[edx].oes_nexted
    mov ds:ohc_control_linear,esi
    mov gs:HcControlHeadEd,edi
    pop gs
    jmp cpFreeEdList    

cpBulk:
    mov ax,flat_sel
    mov es,ax
;
    xor ecx,ecx
    mov ebx,ds:ohc_bulk_linear

cpBulkLoop:
    cmp ebx,edx
    je cpBulkUnlink
;
    mov ecx,ebx
    mov ebx,es:[ebx].oes_next_va
    or ebx,ebx
    jnz cpBulkLoop
    jmp cpFreeEdList

cpBulkUnlink:
    or ecx,ecx
    jz cpBulkHead
;
    mov esi,es:[edx].oes_next_va
    mov edi,es:[edx].oes_nexted
    mov es:[ecx].oes_next_va,esi
    mov es:[ecx].oes_nexted,edi
    jmp cpFreeEdList

cpBulkHead:
    push gs
    mov gs,ds:ohc_reg_sel
    mov esi,es:[edx].oes_next_va
    mov edi,es:[edx].oes_nexted
    mov ds:ohc_bulk_linear,esi
    mov gs:HcBulkHeadEd,edi
    pop gs
    jmp cpFreeEdList

cpIntr:
    mov ax,flat_sel
    mov es,ax
    mov di,fs:osp_intr_count
    dec byte ptr ds:[di]
;
    mov di,fs:osp_intr_list
    mov ebx,ds:[di].oes_my_va
    xor ecx,ecx

cpIntrLoop:
    cmp ebx,edx
    je cpIntrUnlink
;
    mov ecx,ebx
    mov ebx,es:[ebx].oes_next_va
    or ebx,ebx
    jnz cpIntrLoop
    jmp cpFreeEdList

cpIntrUnlink:
    or ecx,ecx
    jz cpIntrHead
;
    mov esi,es:[edx].oes_next_va
    mov edi,es:[edx].oes_nexted
    mov es:[ecx].oes_next_va,esi
    mov es:[ecx].oes_nexted,edi
    jmp cpFreeEdList

cpIntrHead:
    mov esi,es:[edx].oes_next_va
    mov ecx,es:[edx].oes_nexted
    mov ds:[di].oes_next_va,esi
    mov ds:[di].oes_nexted,ecx
    jmp cpFreeEdList

cpFreeEdList:
    mov eax,es:[edx].oes_headp
    test al,1
    jnz cpFreeTd
;
    and ax,0FFF0h    
    cmp eax,es:[edx].oes_tailp
    je cpFreeTd
;    
    call LocalIsConnected
    jc cpFreeTd
;    
    mov ax,1
    WaitMilliSec
    jmp cpFreeEdList

cpFreeTd:
    call LocalEndTransfer
    mov edx,es:[edx].oes_head_va

cpTdListLoop:
    or edx,edx
    jz cpTdListOk
;
    mov eax,es:[edx].otd_next_va
    call FreeBlock32
    mov edx,eax
    jmp cpTdListLoop

cpTdListOk:    
    mov edx,fs:osp_ed
    call FreeBlock32
    
dpDone:
    mov edx,fs:osp_setup_linear
    or edx,edx
    jz rpSetupDone
;
    mov ecx,1000h
    FreeLinear

rpSetupDone:   
    mov ax,2
    WaitMilliSec
;
    LeaveSection ds:ohc_section
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
;
    popad
    pop es
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
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    push es
    push edx
;
    mov dx,flat_sel
    mov es,dx    
;
    mov edx,fs:osp_ed
    call InitPipeEd 
;
    pop edx
    pop es
    retf32
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LocalIsConnected
;
;           DESCRIPTION:    Check if pipe is connected
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalIsConnected   Proc near
    push es
    push eax
    push dx
    push si
;    
    mov es,fs:usbp_function_sel
    movzx si,es:usbf_port
;    
    shl si,2
    mov es,ds:ohc_reg_sel
    mov eax,es:[si].HcRhPortStatus
    test al,1
    clc
    jnz icDone
;    
    stc

icDone:
    pop si
    pop dx
    pop eax
    pop es
    ret
LocalIsConnected Endp

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
    call LocalIsConnected
    retf32
IsConnected Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetPipe
;
;           DESCRIPTION:    Reset port for pipe
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetPipe   Proc far
    push es
    push ax
    push cx
;    
    mov es,fs:usbp_function_sel
    mov cl,es:usbf_port
    mov ax,1
    shl ax,cl
    lock or ds:ohc_reset,ax
;
    pop cx
    pop ax
    pop es
    retf32
ResetPipe   Endp

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
;           NAME:           AllocateHubPort
;
;           DESCRIPTION:    Allocate Hub port
;
;       PARAMETERS:         DS      Function selector
;                           GS      Hub
;
;       RETURNS:            AL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateHubPort   Proc far
    stc
    retf32
AllocateHubPort     Endp
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeHubPort
;
;           DESCRIPTION:    Free Hub port
;
;       PARAMETERS:         DS      Function selector
;                           GS      Hub
;                           AL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeHubPort   Proc far
    stc
    retf32
FreeHubPort     Endp
    

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
;           NAME:           GetMaxLen
;
;           DESCRIPTION:    Get max len
;
;           RETURNS:        AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMaxLen   Proc far
    mov al,8
    retf32
GetMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetMaxLen
;
;           DESCRIPTION:    Set max len
;
;           PARAMETERS:     FS      Pipe
;                           AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetMaxLen   Proc far
    retf32
SetMaxLen   Endp

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
;   NAME:           AttachThread
;
;   DESCRIPTION:    Attach thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..OHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

attach_thread_name  DB 'OHCI Attach ', 0

attach_thread:
    mov ds,bx
    mov cl,dl
    mov es,ds:ohc_reg_sel
;    
    movzx si,cl
    shl si,2
    movzx di,cl
    add di,di
;    
    GetThread
    mov ds:[di].usb_attach_thread_arr,ax
;
    mov dx,10

atCheck:    
    mov ax,5
    WaitMilliSec
;
    mov eax,es:[si].HcRhPortStatus
    test al,1
    jz atDone
;
    sub dx,1
    jnz atCheck
;    
    LockUsb
;    
    mov eax,10h
    mov es:[si].HcRhPortStatus,eax

atResetLoop:
    mov ax,5
    WaitMilliSec
;
    mov eax,es:[si].HcRhPortStatus
    test al,1
    jz atUnlock
;    
    test al,10h
    jnz atResetLoop
; 
    mov eax,2
    mov es:[si].HcRhPortStatus,eax
;
    mov dx,40

atWaitNotify:    
    mov ax,5
    WaitMilliSec
;
    mov eax,es:[si].HcRhPortStatus
    test al,1
    jz atUnlock
;
    sub dx,1
    jnz atWaitNotify
;    
    mov ax,25
    WaitMilliSec
;
    mov eax,es:[si].HcRhPortStatus
    push eax
    push cx    
    push di
;
    mov eax,SIZE usb_function_struc
    AllocateSmallGlobalMem
    xor di,di
    mov cx,SIZE usb_function_struc
    xor al,al
    rep stosb
;
    pop di
    pop cx
    pop eax
;
    shr ah,1
    and ah,1
    xor ah,1
    mov es:usbf_speed,ah
;
    mov es:usbf_port,cl
    mov es:usbf_slot,0
    mov es:usbf_address,0
    NotifyUsbAttach
    jmp atDone

atUnlock:
    UnlockUsb    

atDone:
    mov ds:[di].usb_attach_thread_arr,0
    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           DetachThread
;
;   DESCRIPTION:    Detach thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..OHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

detach_thread_name  DB 'OHCI Detach ', 0

detach_thread:
    mov cl,dl
    mov ds,bx
    mov es,ds:ohc_reg_sel
;    
    movzx si,cl
    shl si,2
    movzx di,cl
    add di,di
;    
    GetThread
    mov ds:[di].usb_detach_thread_arr,ax
;    
    mov al,cl
    NotifyUsbDetach
;
    mov ds:[di].usb_detach_thread_arr,0
    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetThread
;
;   DESCRIPTION:    Reset thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..OHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_thread_name  DB 'OHCI Reset ', 0

reset_thread:
    mov cl,dl
    mov ds,bx
    mov es,ds:ohc_reg_sel
;    
    movzx si,cl
    shl si,2
    movzx di,cl
    add di,di
;    
    GetThread
    mov ds:[di].usb_reset_thread_arr,ax
;
    mov eax,10h
    mov es:[si].HcRhPortStatus,eax
;    
    mov al,cl
    NotifyUsbDetach
;    
    LockUsb

rtWaitRes:        
    mov ax,5
    WaitMilliSec
;
    mov eax,es:[si].HcRhPortStatus
    test al,1
    jz rtUnlock
;
    test al,10h
    jnz rtWaitRes
;    
    mov eax,2
    mov es:[si].HcRhPortStatus,eax
;
    mov dx,40

rtWaitNotify:    
    mov ax,5
    WaitMilliSec
;
    mov eax,es:[si].HcRhPortStatus
    test al,1
    jz rtUnlock
;
    sub dx,1
    jnz rtWaitNotify
;    
    mov eax,es:[si].HcRhPortStatus
    push eax
    push cx    
    push di
;
    mov eax,SIZE usb_function_struc
    AllocateSmallGlobalMem
    xor di,di
    mov cx,SIZE usb_function_struc
    xor al,al
    rep stosb
;
    pop di
    pop cx
    pop eax
;
    shr ah,1
    and ah,1
    xor ah,1
    mov es:usbf_speed,ah
;
    mov es:usbf_port,cl
    mov es:usbf_slot,0
    mov es:usbf_address,0
    NotifyUsbAttach
    jmp rtDone

rtUnlock:
    UnlockUsb    

rtDone:
    mov ds:[di].usb_reset_thread_arr,0
    TerminateThread
        

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
    movzx di,cl
    add di,di
    mov es,ds:ohc_reg_sel
;    
    mov ax,1
    shl ax,cl
    test ax,ds:ohc_reset
    jz upNoReset
;
    not ax
    lock and ds:ohc_reset,ax
;        
    mov eax,es:[si].HcRhPortStatus
    test al,1
    jz upNoReset
;
    mov bx,ds:[di].usb_port_sel_arr
    or bx,bx
    jz upNoReset
;    
    mov bx,ds:[di].usb_attach_thread_arr
    or bx,ds:[di].usb_detach_thread_arr
    or bx,ds:[di].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[di].usb_reset_thread_arr,-1
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    shl di,1
    mov ds:[di].usb_timeout_arr,eax
    mov ds:[di].usb_timeout_arr+4,edx
;
    mov dx,cx
    mov si,OFFSET reset_thread
    mov di,OFFSET reset_thread_name
    mov ax,2
    call StartThread
    jmp upDone
    
upNoReset:
    mov eax,es:[si].HcRhPortStatus
    test al,1
    stc
    jz upDetach
    
upAttach:
    mov bx,ds:[di].usb_port_sel_arr
    or bx,bx
    jnz upCheckTimeout
;
    mov bx,ds:[di].usb_attach_thread_arr
    or bx,ds:[di].usb_detach_thread_arr
    or bx,ds:[di].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[di].usb_attach_thread_arr,-1
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    shl di,1
    mov ds:[di].usb_timeout_arr,eax
    mov ds:[di].usb_timeout_arr+4,edx
;    
    mov dx,cx
    mov si,OFFSET attach_thread
    mov di,OFFSET attach_thread_name
    mov ax,2
    call StartThread
    jmp upDone

upDetach:
    mov bx,ds:[di].usb_port_sel_arr
    or bx,bx
    jz upCheckTimeout
;    
    mov bx,ds:[di].usb_attach_thread_arr
    or bx,ds:[di].usb_detach_thread_arr
    or bx,ds:[di].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[di].usb_detach_thread_arr,-1    
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    shl di,1
    mov ds:[di].usb_timeout_arr,eax
    mov ds:[di].usb_timeout_arr+4,edx
;    
;
    mov dx,cx
    mov si,OFFSET detach_thread
    mov di,OFFSET detach_thread_name
    mov ax,2
    call StartThread
    jmp upDone

upCheckTimeout:
    mov bx,ds:[di].usb_attach_thread_arr
    or bx,bx
    jz upCheckDetach
;
    shl di,1
    GetSystemTime
    sub eax,ds:[di].usb_timeout_arr
    sbb edx,ds:[di].usb_timeout_arr+4
    jc upDone
;
    Signal
    jmp upDone    

upCheckDetach:    
    mov bx,ds:[di].usb_detach_thread_arr
    or bx,bx
    jz upCheckReset
;
    shl di,1
    GetSystemTime
    sub eax,ds:[di].usb_timeout_arr
    sbb edx,ds:[di].usb_timeout_arr+4
    jc upDone
;
    Signal
    jmp upDone
            
upCheckReset:    
    mov bx,ds:[di].usb_reset_thread_arr
    or bx,bx
    jz upDone
;
    shl di,1
    GetSystemTime
    sub eax,ds:[di].usb_timeout_arr
    sbb edx,ds:[di].usb_timeout_arr+4
    jc upDone
;
    Signal
            
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
;       NAME:           UpdatePipeList
;
;       DESCRIPTION:    Update pipe list
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePipeList  Proc near
    push ax

    EnterSection ds:ohc_pipe_section
    mov ax,ds:ohc_pipe_list
    or ax,ax
    jz uplDone
;
    push es
    push fs
    push ebx
    push edx
    push di
;
    mov di,ax
    mov fs,ax
;
    mov ax,flat_sel
    mov es,ax

uplElemLoop:
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz uplNext
;
    mov edx,fs:osp_ed
    mov eax,es:[edx].oes_head_va
    or eax,eax
    jz uplNext
;    
    mov ebx,es:[eax].otd_phys
    cmp ebx,es:[edx].oes_headp
    je uplNext
;
    xor bx,bx
    xchg bx,fs:osp_signal
    Signal

uplNext:    
    mov ax,fs:osp_next
    mov fs,ax
    cmp ax,di
    jne uplElemLoop
;
    pop di
    pop edx
    pop ebx
    pop fs
    pop es    

uplDone:    
    LeaveSection ds:ohc_pipe_section
    pop ax
    ret
UpdatePipeList  Endp

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
    AddThreadInt
    GetThread
    mov ds:ohc_thread,ax

ofhLoop:
    WaitForSignal    
    call UpdatePipeList
    jmp ofhLoop
        
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
ot00 DD OFFSET CreateControl,       SEG code
ot01 DD OFFSET CreateBulk,          SEG code
ot02 DD OFFSET CreateIntr,          SEG code
ot03 DD OFFSET AddSetup,        SEG code
ot04 DD OFFSET AddOut,          SEG code
ot05 DD OFFSET AddIn,           SEG code
ot06 DD OFFSET AddStatusOut,    SEG code
ot07 DD OFFSET AddStatusIn,         SEG code
ot08 DD OFFSET IssueTransfer,       SEG code
ot09 DD OFFSET IsTransferDone,      SEG code
ot0A DD OFFSET EndTransfer,     SEG code
ot0B DD OFFSET WasTransferOk,       SEG code
ot0C DD OFFSET GetDataSize,     SEG code
ot0D DD OFFSET ClosePipe,       SEG code
ot0E DD OFFSET WaitForCompletion,   SEG code
ot0F DD OFFSET ChangeAddress,       SEG code
ot10 DD OFFSET IsConnected,     SEG code
ot11 DD OFFSET ResetPipe,       SEG code
ot12 DD OFFSET LockEnum,        SEG code
ot13 DD OFFSET UnlockEnum,      SEG code
ot14 DD OFFSET AllocateHubPort,  SEG code
ot15 DD OFFSET FreeHubPort,     SEG code
ot16 DD OFFSET Has64Bit,        SEG code
ot17 DD OFFSET IsStalled,       SEG code
ot18 DD OFFSET ClearStalled,    SEG code
ot19 DD OFFSET GetMaxLen,       SEG code
ot1A DD 0,                      0
ot1B DD 0,                      0
ot1C DD OFFSET SetMaxLen,       SEG code

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
    mov cx,2*1Dh

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbDevice
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
    InitSection ds:ohc_pipe_section
    InitSection ds:ohc_enum_section
    mov ds:ohc_pipe_list,0
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
    AddThreadInt
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
;           NAME:           GetAllocatedUsbBlocks
;
;           DESCRIPTION:    Get allocated USB blocks
;
;       PARAMETERS:     
;
;           RETURNS:        EAX     Number of blocks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_allocated_usb_blocks_name       DB 'Get Allocated USB Blocks',0

get_allocated_usb_blocks    Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov eax,ds:OhciUsedBlocks
    pop ds
    retf32
get_allocated_usb_blocks    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetUsbClosedCount
;
;           DESCRIPTION:    Get closed count
;
;       PARAMETERS:     
;
;           RETURNS:        EAX     Number of blocks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_usb_close_count_name       DB 'Get USB Close Count',0

get_usb_close_count    Proc far
    push ds
    mov ax,SEG data
    mov ds,ax
    mov eax,ds:OhciCloseCount
    pop ds
    retf32
get_usb_close_count    Endp

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
    InitSection ds:OhciSection
    mov ds:OhciFuncCount,0
    mov ds:OhciUsedBlocks,0
    mov ds:OhciCloseCount,0
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
    mov esi,OFFSET get_allocated_usb_blocks
    mov edi,OFFSET get_allocated_usb_blocks_name
    xor dx,dx
    mov ax,get_allocated_usb_blocks_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_usb_close_count
    mov edi,OFFSET get_usb_close_count_name
    xor dx,dx
    mov ax,get_usb_close_count_nr
    RegisterBimodalUserGate
;
    clc
;
    ret
Init    Endp

code ENDS

    END init
