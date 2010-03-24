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

		NAME ohci

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\pci.inc
INCLUDE ..\os\usb.inc

MAX_USB_DEVICES = 16

hc_reg  STRUC

HcRevision          DD ?
HcControl           DD ?
HcCommandStatus     DD ?
HcInterruptStatus   DD ?
HcInterruptEnable   DD ?
HcInterruptDisable  DD ?
HcHCCA              DD ?
HcPeriodCurrentED   DD ?
HcControlHeadED     DD ?
HcControlCurrentED  DD ?
HcBulkHeadED        DD ?
HcBulkCurrentED     DD ?
HcDoneHeadED        DD ?
HcFmInterval        DD ?
HcFmRemain          DD ?
HcFmNumber          DD ?
HcPeriodicStart     DD ?
HcLSThreshold       DD ?
HcRhDescriptorA     DD ?
HcRhDescriptorB     DD ?    
HcRhStatus          DD ?
HcRhPortStatus      DD ?

hc_reg  ENDS

; this structure should be kept less than 32 bytes long!

ohc_es_struc    STRUC

;HC part

oes_fa_en       DW ?
oes_mps         DW ?
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

otd_resv        DW ?
otd_flags       DW ?
otd_cbp         DD ?
otd_next_td     DD ?
otd_be          DD ?

;driver part

otd_my_va       DD ?
otd_next_va     DD ?
otd_buffer_va   DD ?
otd_buffer_size DW ?
otd_pipe_sel    DW ?

ohc_td_struc    ENDS

OSP_FLAG_TRANSFER_PENDING   = 1
OSP_FLAG_TRANSFER_OK        = 2

ohci_pipe   STRUC

osp_pipe_base       usb_pipe_struc <>
osp_ed              DD ?
osp_prev            DW ?
osp_next            DW ?
osp_data_list       DD ?
osp_signal          DW ?
osp_sync_linear     DD ?
osp_intr_list       DW ?
osp_intr_count      DW ?
osp_data_size       DW ?
osp_setup_linear    DD ?
osp_flags           DB ?

ohci_pipe   ENDS

ohci_func_sel   STRUC

usb_dev_base    usb_dev_struc <>

ohc_reg_sel         DW ?
ohc_map_sel         DW ?
ohc_map_linear      DD ?
ohc_int_status      DD ?
ohc_linear          DD ?
ohc_phys            DD ?
ohc_control_linear  DD ?
ohc_bulk_linear     DD ?
ohc_pipe_list       DW ?
ohc_reclaim_list    DD ?

ohc_section         section_typ <>

ohc_32_cnt          DB 32 DUP(?)
ohc_16_cnt          DB 16 DUP(?)
ohc_8_cnt           DB 8 DUP(?)
ohc_4_cnt           DB 4 DUP(?)
ohc_2_cnt           DB 2 DUP(?)
ohc_1_cnt           DB ?

ohc_curr_cnt        DB 32 DUP(?)

ohci_func_sel    ENDS


; this should be at 700h in the ohci_func_sel, interrupt ES descriptors

ohc_int_base   = 700h

ohc_int_struc   STRUC

ohc_32_es           DB 32 * 32 DUP(?)
ohc_16_es           DB 16 * 32 DUP(?)
ohc_8_es            DB 8 * 32 DUP(?)
ohc_4_es            DB 4 * 32 DUP(?)
ohc_2_es            DB 2 * 32 DUP(?)
ohc_1_es            DB 1 * 32 DUP(?)
ohc_iso_es          DB 1 * 32 DUP(?)

ohc_int_struc   ENDS

ohc_hca_base   = 0F00h      ; HCCA is at the end (F00h) of ohci_func_sel

hcca_struc  STRUC

hcca_int_table      DD 32 DUP(?)
hcca_frame_number   DW ?
hcca_pad1           DW ?
hcca_done_head      DD ?

hcca_struc  ENDS

data    STRUC

OhciList32      DD ?
OhciSection     section_typ <>
OhciThread      DW ?
OhciFuncCount   DW ?
OhciFuncArr     DW MAX_USB_DEVICES(?)

data    ENDS

code	SEGMENT byte public 'CODE'


	assume cs:code

.386p

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OhciInt
;
;		DESCRIPTION:    OHCI interrupt
;
;       PARAMETERS:     DS      Register selector
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OhciInt	Proc far
    mov ax,ohci_data_sel
    mov es,ax
	mov bx,es:OhciThread
;
    mov cx,es:OhciFuncCount
    mov si,OFFSET OhciFuncArr

oiSignalLoop:
    push es
    mov es,es:[si]
    mov ds,es:ohc_reg_sel
    mov eax,ds:HcInterruptStatus
    mov ds:HcInterruptStatus,eax
    or es:ohc_int_status,eax
;
    and eax,52h
    jz oiNext
;    
	Signal

oiNext:
    pop es
    add si,2
    loop oiSignalLoop
;
    ret
OhciInt  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			AllocateBlock32
;
;		DESCRIPTION:	Allocate 32-byte block with page-alignment
;
;       PARAMETERS:     ES      Flat sel
;
;		RETURNS:		EDX		Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateBlock32	PROC near
    push ds
    push eax
    push esi
;    
    mov ax,ohci_data_sel
    mov ds,ax
    mov esi,OFFSET OhciSection
    EnterNewSection
;    
    mov edx,ds:OhciList32
	or edx,edx
	jnz allocate_block32_done
;
    push ecx    
	mov eax,1000h
	AllocateBigLinear
	mov ecx,32
	mov ds:OhciList32,edx
	
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
	mov esi,OFFSET OhciSection
	LeaveNewSection
;
    pop esi
	pop eax
	pop ds
	ret
AllocateBlock32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeBlock32
;
;		DESCRIPTION:	Free 32-byte block
;
;       PARAMETERS:     ES      Flat sel
;
;		PARAMETERS:		EDX		Data address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBlock32	PROC near
    push ds
	push eax
	push esi
;
    mov ax,ohci_data_sel
    mov ds,ax
;    
	mov esi,OFFSET OhciSection
	EnterNewSection
	mov eax,ds:OhciList32
	mov es:[edx],eax
	mov ds:OhciList32,edx
	LeaveNewSection
;	
    pop esi
	pop eax
	pop ds
	ret
FreeBlock32	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InsertPipe
;
;		DESCRIPTION:	Insert pipe into function pipe-list
;
;       PARAMETERS:     DS      Function
;                       FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertPipe  Proc near
	push di
	mov di,ds:ohc_pipe_list
	or di,di
	je ipEmpty
;	
	push ds
	push si
	mov ds,di
	cli
	mov si,ds:osp_prev
	mov ds:osp_prev,fs
	mov ds,si
	mov ds:osp_next,fs
	mov fs:osp_next,di
	mov fs:osp_prev,si
	sti
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
    mov fs:osp_data_list,0
    mov fs:osp_signal,0
    mov fs:osp_flags,0
	ret
InsertPipe  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemovePipe
;
;		DESCRIPTION:	Remove pipe from function pipe-list
;
;       PARAMETERS:     DS      Function
;                       FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemovePipe  Proc near
	push si
	push di
;	
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
	pop di
	pop si
    ret
RemovePipe  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InitEd
;
;		DESCRIPTION:    Initialize an already allocated ED
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       EDX     ED
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitEd	PROC near
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InitTd
;
;		DESCRIPTION:    Initialize an already allocated TD
;
;       PARAMETERS:     ES      Flat sel
;                       FS      Pipe sel
;                       EDX     TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTd	PROC near
    mov es:[edx].otd_resv,0
    mov es:[edx].otd_flags,0E4h
    mov es:[edx].otd_cbp,0
    mov es:[edx].otd_next_td,0
    mov es:[edx].otd_be,0
    mov es:[edx].otd_my_va,edx
    mov es:[edx].otd_next_va,0
    mov es:[edx].otd_pipe_sel,fs
    ret
InitTd  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AllocateEd
;
;		DESCRIPTION:	Allocate & initialize an endpoint descriptor
;
;       PARAMETERS:     DS      Function selector
;                       ES      Flat sel
;
;		RETURNS:		EDX		Linear address of ED
;                       EAX     Physical address of ED
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateEd	PROC near
    push cx
    call AllocateBlock32
    call InitEd
;
    GetPhysicalPage
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
    ret
AllocateEd  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AllocateTd
;
;		DESCRIPTION:	Allocate & initialize transfer descriptor
;
;       PARAMETERS:     ES      Flat sel
;                       FS      Pipe sel
;
;		RETURNS:		EDX		Linear address of TD
;                       EAX     Physical address of TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateTd	PROC near
    push cx
    call AllocateBlock32
    call InitTd
;
    GetPhysicalPage
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
    ret
AllocateTd  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateSyncBlock
;
;		DESCRIPTION:	Allocate sync block
;
;       PARAMETERS:     FS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSyncBlock    Proc near
    push eax
    push ecx
    push edx
;    
    mov eax,1000h
    AllocateBigLinear
    mov fs:osp_sync_linear,edx
;    
    pop edx
    pop ecx
    pop eax    
    ret
CreateSyncBlock Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    SyncHead
;
;		DESCRIPTION:	Sync head ptr in pipe
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SyncHead    Proc near
    push eax
    push ebx
    push edx
;    
    mov ebx,fs:osp_ed
    mov eax,es:[ebx].oes_headp
    mov edx,fs:osp_sync_linear
    movzx ebx,ax
    and bx,0FF0h
    and ax,0F000h
	or ax,803h
    SetPhysicalPage
    mov edx,es:[ebx+edx].otd_my_va
    mov ebx,fs:osp_ed
    mov es:[ebx].oes_head_va,edx
;    
    pop edx
    pop ebx
    pop eax
    ret
SyncHead    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddControlEd
;
;		DESCRIPTION:	Add control ED 
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;
;       RETURNS:        EDX     Linear address of ED added
;                       EAX     Physical address of ED added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddControlEd	PROC near
    push gs
    push ebx
    push esi
;
    mov esi,OFFSET ohc_section
    EnterNewSection
;    
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
;    
    mov esi,OFFSET ohc_section
    LeaveNewSection
;    
    pop esi
    pop ebx
    pop gs
    ret
AddControlEd  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddBulkEd
;
;		DESCRIPTION:	Add bulk ED 
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;
;       RETURNS:        EDX     Linear address of ED added
;                       EAX     Physical address of ED added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBulkEd	PROC near
    push gs
    push ebx
    push esi
;
    mov esi,OFFSET ohc_section
    EnterNewSection
;    
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
;    
    mov esi,OFFSET ohc_section
    LeaveNewSection
;    
    pop esi
    pop ebx
    pop gs
    ret
AddBulkEd  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetIntrEd
;
;		DESCRIPTION:	Get interrupt ED
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;                       CL      Interval
;
;       RETURNS:        DI      Offset to ED list entry to use
;                       SI      Offset to count array
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIntrEd	PROC near
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddIntrEd
;
;		DESCRIPTION:	Add interrupt ED 
;
;       PARAMETERS:     DS      Function sel
;                       ES      Flat sel
;                       FS      Pipe sel
;                       CL      Interval
;
;       RETURNS:        EDX     Linear address of ED added
;                       EAX     Physical address of ED added
;                       SI      Interrupt count array entry
;                       DI      Interrupt ED used
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIntrEd	PROC near
    push ebx
    push esi
;
    mov esi,OFFSET ohc_section
    EnterNewSection
;    
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
;    
    mov esi,OFFSET ohc_section
    LeaveNewSection
;    
    pop ebx
    ret
AddIntrEd  ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InitPipeEd
;
;		DESCRIPTION:    Init endpoint descriptor from pipe
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       ES      Flat sel
;                       EDX     ED linear address
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
    test fs:usbp_speed,USB_LOW_SPEED
    jz init_pipe_speed_ok
;
    or ah,20h

init_pipe_speed_ok:    
    mov es:[edx].oes_fa_en,ax

init_pipe_done:
    pop edx
    pop eax
    ret
InitPipeEd  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddPipeTd
;
;		DESCRIPTION:	Add TD to pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Flat sel
;                       FS      Pipe
;                       EDI     Data buffer
;                       CX      Size of data
;                       AX      Flags field of TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddPipeTd	PROC near
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
    GetPhysicalPage
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateInterrupt
;
;		DESCRIPTION:	Create interrupt queues
;
;       PARAMETERS:     DS  Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateInterrupt	PROC near
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

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateControl
;
;		DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Function selector
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    push es
    pushad
;    
    mov eax,SIZE ohci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
;
    mov eax,1000h
    AllocateBigLinear
    mov es:osp_setup_linear,edx
;    
    mov ax,es
    mov fs,ax
    mov dx,flat_sel
    mov es,dx
    call AddControlEd
    mov fs:osp_ed,edx
    call CreateSyncBlock
    call InsertPipe
;
    popad
    pop es
    ret
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateBulk
;
;		DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     DS      Function selector
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    push es
    pushad
;    
    mov eax,SIZE ohci_pipe
    AllocateSmallGlobalMem
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
;    
    mov ax,es
    mov fs,ax
    mov dx,flat_sel
    mov es,dx
    call AddBulkEd
    mov fs:osp_ed,edx
    call CreateSyncBlock
    call InsertPipe
;
    popad
    pop es
    ret
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    CreateIntr
;
;		DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     DS      Function selector
;                       AL      Interval
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    push es
    pushad
;    
    mov cl,al
    mov eax,SIZE ohci_pipe
    AllocateSmallGlobalMem
    push cx
    xor di,di
    mov cx,ax
    xor al,al
    rep stosb
    pop cx
;    
    mov ax,es
    mov fs,ax
    mov dx,flat_sel
    mov es,dx
    call AddIntrEd
    mov fs:osp_ed,edx
    mov fs:osp_intr_count,si
    mov fs:osp_intr_list,di
;
    call CreateSyncBlock
    call InsertPipe
;
    popad
    pop es
    ret
CreateIntr  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddBuffer
;
;		DESCRIPTION:    Allocate input/output buffer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Size
;                       ES:EDI  Buffer
;                       AX      Flags field of TD

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
    push ecx
    mov bx,es
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
;		NAME:		    AddSetup
;
;		DESCRIPTION:    Add setup transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Buffer size
;                       ES:EDI  Buffer
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
    ret
AddSetup    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddOut
;
;		DESCRIPTION:    Add out transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Buffer size
;                       ES:EDI  Buffer
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
    ret
AddOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddIn
;
;		DESCRIPTION:    Add in transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       CX      Buffer size
;                       ES:EDI  Buffer
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
    ret
AddIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddStatusOut
;
;		DESCRIPTION:    Add status OUT transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
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
    ret
AddStatusOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddStatusIn
;
;		DESCRIPTION:    Add status IN transaction to queue
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
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
    ret
AddStatusIn    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    IssueTransfer
;
;		DESCRIPTION:    Issue transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;                       EDX     Queue handle
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
    ret
IssueTransfer    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    IsTransferDone
;
;		DESCRIPTION:    Check if transfer is done
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsTransferDone   Proc far
    push es
    push eax
    push bx
    push edx
;
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz itdOk
;
    call IsConnected
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
IsTransferDone   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    WaitForCompletion
;
;		DESCRIPTION:    Wait for transfer to complete
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCompletion   Proc far
    push eax
;
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz wfcDone

wfcLoop:    
    call IsTransferDone
    jnc wfcDone
;    
    WaitForSignal
    jmp wfcLoop

wfcDone:
    call EndTransfer
;
    pop eax
    ret
WaitForCompletion   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    WasTransferOk
;
;		DESCRIPTION:    Check if transfer was ok
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        NC      Transfer ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WasTransferOk   Proc far
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz wtoNotPending
;
    call EndTransfer

wtoNotPending:
    test fs:osp_flags, OSP_FLAG_TRANSFER_OK
    jnz wtoOk
;    
    stc
    jmp wtoDone

wtoOk:
    clc

wtoDone:
    ret
WasTransferOk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    EndTransfer
;
;		DESCRIPTION:    End transfer
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EndTransfer   Proc far
    push es
    push eax
    push cx
    push edx
    push esi
    push edi
    push bp
;    
    test fs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz etDone
;
    mov fs:osp_data_size,0     
    and fs:osp_flags, NOT OSP_FLAG_TRANSFER_PENDING
    and fs:osp_flags, NOT OSP_FLAG_TRANSFER_OK
;    
    mov edx,fs:osp_data_list
    or edx,edx
    jz etDone
;
    mov ax,flat_sel
    mov es,ax
;    
    xor bp,bp
    mov edx,fs:osp_data_list

etLoop:
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
    mov edx,edi
    or edx,edx
    jnz etLoop
;
    mov fs:osp_data_size,bp
    mov fs:osp_data_list,0
    or fs:osp_flags, OSP_FLAG_TRANSFER_OK
;
    mov edx,fs:osp_ed
    or es:[edx].oes_fa_en,4000h

etDone:
    pop bp
    pop edi
    pop esi
    pop edx
    pop cx
    pop eax
    pop es
    ret
EndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    GetDataSize
;
;		DESCRIPTION:    Get data size
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;       RETURNS:        CX      Bytes read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDataSize   Proc far
    xor cx,cx
    test fs:osp_flags, OSP_FLAG_TRANSFER_OK
    jz gdsDone
;    
    mov cx,fs:osp_data_size

gdsDone:
    ret
GetDataSize   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    ClosePipe
;
;		DESCRIPTION:    Close pipe
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePipe   Proc far
    push es
    pushad
;        
    call RemovePipe
;
    mov esi,OFFSET ohc_section
    EnterNewSection
;    
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
    call IsConnected
    jc cpFreeTd
;    
    mov ax,1
    WaitMilliSec
    jmp cpFreeEdList

cpFreeTd:
    call EndTransfer
    call SyncHead    
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
    mov edx,fs:osp_sync_linear
    xor eax,eax
    SetPhysicalPage
;    
    mov ecx,1000h
    FreeLinear
;
    mov ax,2
    WaitMilliSec
;
    mov esi,OFFSET ohc_section
    LeaveNewSection
;    
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
;
    popad
    pop es
    ret
ClosePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    ChangeAddress
;
;		DESCRIPTION:    Change address for pipe
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
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
    ret
ChangeAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    IsConnected
;
;		DESCRIPTION:    Check if pipe is connected
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsConnected   Proc far
    push es
    push ax
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
    pop ax
    pop es
    ret
IsConnected Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    UpdateQueue
;
;		DESCRIPTION:    Update done queue
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateQueue   Proc near
    push es
    push fs
    push gs
    push eax
    push bx
    push ecx
    push edx
;    
    xor eax,eax
    mov bx,ohc_hca_base + OFFSET hcca_done_head
    xchg eax,ds:[bx]
    or eax,eax
    jz update_queue_done
;   
    mov dx,flat_sel
    mov es,dx
    mov fs,ds:ohc_map_sel

update_reverse_loop:
    mov bx,ax
    and ax,0F000h
    and bx,0FFFh
	or ax,803h
	mov edx,ds:ohc_map_linear
	SetPhysicalPage
    mov edx,fs:[bx].otd_my_va
;
    mov ax,es:[edx].otd_pipe_sel
    or ax,ax
    jz update_insert_reclaim

update_insert_pipe:
    mov gs,ax
    test gs:osp_flags, OSP_FLAG_TRANSFER_PENDING
    jz update_insert_reclaim
;    
    mov ecx,gs:osp_data_list
    mov es:[edx].otd_next_va,ecx
    mov gs:osp_data_list,edx
;
    xor bx,bx
    xchg bx,gs:osp_signal
    Signal    
    jmp update_reverse_next

update_insert_reclaim:
    mov ecx,ds:ohc_reclaim_list
    mov es:[edx].otd_next_va,ecx
    mov ds:ohc_reclaim_list,ecx

update_reverse_next:
    mov eax,es:[edx].otd_next_td
    or eax,eax
    jnz update_reverse_loop

update_queue_done:
    pop edx
    pop ecx
    pop bx
    pop eax
    pop gs
    pop fs
    pop es
    ret
UpdateQueue   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    UpdatePort
;
;		DESCRIPTION:    Update root-hub port status
;
;       PARAMETERS:     DS      Function selector
;                       CL      Port # (0,1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push es
    push ax
    push bx
    push cx
    push dx
    push si
    push di
;    
    movzx si,cl
    shl si,2
    movzx di,cl
    add di,di
;    
    mov es,ds:ohc_reg_sel
    mov eax,es:[si].HcRhPortStatus
    test al,1
    stc
    jz upDetach
    
upAttach:
    mov bx,ds:[di].usb_port_sel_arr
    or bx,bx
    jnz upDone
;
    mov ax,50
    WaitMilliSec
;    
    mov eax,10h
    mov es:[si].HcRhPortStatus,eax

upResetLoop:
    mov ax,5
    WaitMilliSec
;
    mov eax,es:[si].HcRhPortStatus
    test al,1
    jz upDone
;        
    test al,10h
    jnz upResetLoop
; 
    mov eax,2
    mov es:[si].HcRhPortStatus,eax
    
epNotify:
    mov ax,100
    WaitMilliSec
;    
    mov eax,es:[si].HcRhPortStatus
    shr ah,1
    and ah,1
    mov al,cl
    NotifyUsbAttach
    jmp upDone

upDetach:
    mov bx,ds:[di].usb_port_sel_arr
    or bx,bx
    jz upDone
;    
    mov al,cl
    NotifyUsbDetach
                    
upDone:    
    pop di
    pop si    
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    ret
UpdatePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UpdateUsb
;
;		DESCRIPTION:    Update USB status
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateUsb  Proc near
    mov ax,ohci_data_sel
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
    xor cl,cl    
    call UpdatePort
;
    mov cl,1
    call UpdatePort
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
;		NAME:			ohci_timer
;
;		DESCRIPTION:    Timer that scans for status change in controller
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ohci_timer  Proc far
    push edx
    push eax
;    
    mov ax,ohci_data_sel
    mov ds,ax
	mov bx,ds:OhciThread
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
    call UpdateQueue
;
    mov es,ds:ohc_reg_sel
    mov eax,es:HcInterruptStatus
    mov es:HcInterruptStatus,eax
    or ds:ohc_int_status,eax
;
    and eax,52h
    jz otNext
;    
	Signal
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
	add eax,1193
	adc edx,0
	mov bx,cs
	mov es,bx
	mov bx,cs
	mov di,OFFSET ohci_timer
	StartTimer
    ret
ohci_timer  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    InitFunction
;
;		DESCRIPTION:    Init OHCI function
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ohci_tab:
ot00 DW OFFSET CreateControl,   	ohci_code_sel
ot01 DW OFFSET CreateBulk,      	ohci_code_sel
ot02 DW OFFSET CreateIntr,      	ohci_code_sel
ot03 DW OFFSET AddSetup,    	    ohci_code_sel
ot04 DW OFFSET AddOut,      	    ohci_code_sel
ot05 DW OFFSET AddIn,        	    ohci_code_sel
ot06 DW OFFSET AddStatusOut,        ohci_code_sel
ot07 DW OFFSET AddStatusIn,        	ohci_code_sel
ot08 DW OFFSET IssueTransfer,       ohci_code_sel
ot09 DW OFFSET IsTransferDone,      ohci_code_sel
ot10 DW OFFSET EndTransfer,         ohci_code_sel
ot11 DW OFFSET WasTransferOk,       ohci_code_sel
ot12 DW OFFSET GetDataSize,         ohci_code_sel
ot13 DW OFFSET ClosePipe,           ohci_code_sel
ot14 DW OFFSET WaitForCompletion,   ohci_code_sel
ot15 DW OFFSET ChangeAddress,       ohci_code_sel
ot16 DW OFFSET IsConnected,         ohci_code_sel

InitFunction    Proc near
    push es
    push fs
    pushad
;
    mov ax,flat_sel
    mov es,ax   
;    
    mov si,OFFSET ohci_tab
    xor di,di
    mov cx,17

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbDevice
;    
    mov esi,OFFSET ohc_section
    InitNewSection
    mov fs,ds:ohc_reg_sel
;    
    mov eax,0C000007Fh    
    mov fs:HcInterruptStatus,eax
;    
    mov edx,fs:HcFmInterval
    or fs:HcCommandStatus,1
;
    mov ax,25
    WaitMicroSec
    mov fs:HcFmInterval,edx
    mov fs:HcPeriodicStart,0
;
    or fs:HcControl,100h    
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
    popad
    pop es
    pop ds
    ret
InitFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:		    AddFunction
;
;		DESCRIPTION:    Add OHCI function
;
;       PARAMETERS:     BX      Bus/device
;                       CH      Function
;                       EAX     Register base
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
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
	or ax,803h
    SetPhysicalPage
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
	mov ecx,eax
	AllocateGdt
	CreateDataSelector16
	mov ds,bx
	mov es,bx
	xor di,di
	xor eax,eax
	mov cx,400h
	rep stosd
;
    mov ds:ohc_pipe_list,0
    mov ds:ohc_reclaim_list,0
    mov ds:ohc_reg_sel,bp
    mov ds:ohc_int_status,0
    mov ds:ohc_linear,edx
    GetPhysicalPage
    and ax,0F000h
    mov ds:ohc_phys,eax
    mov bp,bx
;         
    mov eax,1000h
	AllocateBigLinear
	mov ecx,eax
	AllocateGdt
	CreateDataSelector16
	mov ds:ohc_map_linear,edx
	mov ds:ohc_map_sel,bx
;
    mov ax,ohci_data_sel
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
;		NAME:			InitPciAdapter
;
;		DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     
;
;		RETURNS:		NC		Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPciAdapter	Proc near
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
InitPciAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_net
;
;		DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ohci_name	DB 'OHCI',0

ohci_thread	proc far
    mov ax,ohci_data_sel
    mov ds,ax
    GetThread
    mov ds:OhciThread,ax
    mov ds:OhciFuncCount,0
;    
	call InitPciAdapter
    mov cx,ds:OhciFuncCount
    or cx,cx    
	jz ohci_thread_exit
;
    mov si,OFFSET OhciFuncArr

otInitLoop:
    ClearSignal
    push ds
    push cx
    push si
;    
    mov ds,ds:[si]
    call InitFunction
;
    pop si
    pop cx    
    pop ds
;
    add si,2
    loop otInitLoop
;    
	GetSystemTime
	add eax,11930
	adc edx,0
	mov bx,cs
	mov es,bx
	mov bx,cs
	mov di,OFFSET ohci_timer
	StartTimer
;	
    call UpdateUsb

ohci_thread_loop:
    WaitForSignal
    call UpdateUsb
    jmp ohci_thread_loop

ohci_thread_exit:
	ret
ohci_thread	endp
	
init_usb	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET ohci_name
	mov si,OFFSET ohci_thread
	mov ax,4
	mov cx,100h
	CreateThread

init_usb_done:
	popa
	pop es
	pop ds
	ret
init_usb	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init	Proc far
	push ds
	push es
	pusha
	mov bx,ohci_code_sel
	InitDevice
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov eax,SIZE data
	mov bx,ohci_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov es,bx
	mov cx,ax
	xor di,di
	xor al,al
	rep stosb
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET init_usb
	HookInitTasking

init_fail:
	popa
	pop es
	pop ds
	ret
Init	Endp

ENDS

	END init
