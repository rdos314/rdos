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
INCLUDE ..\acpi\pci.inc
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


ohc_td_struc    STRUC

;HC part

otd_resv        DW ?
otd_flags       DW ?
otd_cbp         DD ?
otd_next_td     DD ?
otd_be          DD ?

;driver part

otd_next_va     DD ?
otd_link_va     DD ?
otd_buffer_va   DD ?
otd_buffer_size DW ?
otd_pipe        DB ?

ohc_td_struc    ENDS

ohci_func_sel   STRUC

usb_func_base       usb_function_struc <>

ohc_dev_arr         DW 127 DUP(?)

ohc_reg_sel         DW ?
ohc_map_sel         DW ?
ohc_map_linear      DD ?
ohc_int_status      DD ?
ohc_linear          DD ?
ohc_phys            DD ?
ohc_control_linear  DD ?
ohc_bulk_linear     DD ?
ohc_thread          DW ?

ohc_root_ports      DW ?

ohc_pci_handle      DW ?

ohc_fm_reg          DD ?

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

ohci_dev_sel   STRUC

usb_dev_base       usb_device_struc <>

dev_control_ed     DD ?
dev_control_tail   DD ?
dev_control_head   DD ?
dev_curr_addr      DB ?
dev_cc             DB ?

ohci_dev_sel   ENDS

ohci_pipe_struc    STRUC

op_pipe            usb_pipe_struc <>

op_section         section_typ <>

op_intr_count      DW ?
op_intr_list       DW ?
op_ed              DD ?
op_tail_td         DD ?

ohci_pipe_struc    ENDS

ohci_raw_sel       STRUC

or_base            usb_raw_struc <>

or_curr_count      DW ?
or_td_count        DW ?
or_td_arr          DD ?

ohci_raw_sel       ENDS

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
;       RETURNS:        CY           Activity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OhciInt Proc far
    xor cx,cx
;
    mov es,ds:ohc_reg_sel
    mov eax,es:HcInterruptStatus
    test al,2
    jz oiQueueDone
;
    inc cx
    NotifyIrqActivity
    mov bx,ds:ohc_thread
    Signal

oiQueueDone:
    test al,20h
    jz oiHubDone
;
    inc cx
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
    or cx,cx
    stc
    jnz oiExit
;
    clc

oiExit:
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
    mov fs:[edx].oes_my_va,edx
    mov fs:[edx].oes_tail_va,0
    mov fs:[edx].oes_head_va,0
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
    mov fs:[edx].otd_pipe,0
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
    mov fs:[ebx].oes_head_va,edx
    mov fs:[ebx].oes_tail_va,edx
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
;                       EDX     Head element
;
;       RETURNS:        EDX     Linear address of ED added
;                       EAX     Physical address of ED added
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddBulkEd       PROC near
    push gs
    push ebx
;
    LinearToPhysicalMemBlk
    push edx
    push eax
;
    call AllocateEd
;
    pop ebx
    mov fs:[edx].oes_headp,ebx
    mov fs:[edx].oes_tailp,ebx
;
    pop ebx
    mov fs:[edx].oes_head_va,ebx
    mov fs:[edx].oes_tail_va,ebx
;
    mov gs,ds:ohc_reg_sel
    mov ebx,gs:HcBulkHeadEd
    mov fs:[edx].oes_nexted,ebx
    mov ebx,ds:ohc_bulk_linear
    mov fs:[edx].oes_next_va,ebx
;
    mov ds:ohc_bulk_linear,edx
    mov gs:HcBulkHeadEd,eax
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
;                       EDX     Head & tail TD
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
    LinearToPhysicalMemBlk
    push edx
    push eax
;
    call AllocateEd
;
    pop ebx
    mov fs:[edx].oes_headp,ebx
    mov fs:[edx].oes_tailp,ebx
;
    pop ebx
    mov fs:[edx].oes_head_va,ebx
    mov fs:[edx].oes_tail_va,ebx
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
    push fs
    pushad
;    
    mov dx,flat_sel
    mov fs,dx
;
    EnterSection ds:ohc_section
    call AddControlEd
    LeaveSection ds:ohc_section
;
    mov es:dev_control_ed,edx
    mov eax,fs:[edx].oes_tailp
    mov es:dev_control_tail,eax
;
    popad
    pop fs
    retf32
CreateControl   Endp

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
;       NAME:           Block
;
;       DESCRIPTION:    Block
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Block   Proc far
    EnterSection ds:usb_addr_section
    retf32
Block   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Unblock
;
;       DESCRIPTION:    Unblock
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Unblock   Proc far
    LeaveSection ds:usb_addr_section
    retf32
Unblock   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IsPortConnected
;
;           DESCRIPTION:    Check if port is connected
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsPortConnected   Proc far
    push fs
    push eax
    push dx
    push si
;
    movzx si,dl
    shl si,2
    mov fs,ds:ohc_reg_sel
    mov eax,fs:[si].HcRhPortStatus
    test al,1
    stc
    jz ipcDone
;
    clc

ipcDone:
    pop si
    pop dx
    pop eax
    pop fs
    retf32
IsPortConnected Endp

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
    mov fs:[edx].otd_pipe,0
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
    mov fs:[esi].otd_pipe,0
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
    mov fs:[esi].otd_flags,0F30Ch
    mov fs:[esi].otd_cbp,0
    mov fs:[esi].otd_be,0
    mov fs:[esi].otd_pipe,0
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
    mov fs:[edi].otd_pipe,0
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
    mov fs:[edi].otd_flags,0F314h
    mov fs:[edi].otd_cbp,0
    mov fs:[edi].otd_be,0
    mov fs:[edi].otd_pipe,0
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

control_text DB 'USB Control', 0

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
    test es:usbd_flags,DEV_FLAG_DETACHED
    stc
    jnz rcDone
;
    call fword ptr ds:is_dev_connected_proc
    jc rcDone
;
    lock or es:usbd_flags,DEV_FLAG_CONTROL_ACTIVE
    mov es:dev_cc,0Fh
;
    push es
    mov bx,es:usbd_wait_dev
    mov ax,cs
    mov es,ax
    mov edi,OFFSET control_text
    PrepareWaitDev
    pop es
;
    push ds
    mov ds,ds:ohc_reg_sel
    mov eax,ds:HcCommandStatus
    or al,2
    mov ds:HcCommandStatus,eax
    pop ds
;
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForDev
    lock and es:usbd_flags,NOT DEV_FLAG_CONTROL_ACTIVE
;
    mov al,es:dev_cc
    cmp al,0Fh
    stc
    je rcDone
;
    or al,al
    clc
    jz rcDone
;
    stc

rcDone:
    popad
    ret
RunControl Endp

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
    call CopyControlIn
    jmp cmDone
    
cmDataOut:
    call SetupControlOut
    jc cmFail
;
    call RunControl
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
;
;       RETURNS:        BX      Pipe sel
;                       EDX     Head TD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePipe    Proc near
    push ds
    push eax
;
    push es
    mov eax,SIZE ohci_pipe_struc
    AllocateSmallGlobalMem
;
    mov ax,es
    mov ds,ax
    pop es
;
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
    mov fs:[edx].otd_resv,0
    mov fs:[edx].otd_cbp,0
    mov fs:[edx].otd_be,0
    mov fs:[edx].otd_next_td,0
    mov fs:[edx].otd_next_va,0
    mov fs:[edx].otd_buffer_va,0
    mov ds:op_tail_td,edx
    mov bx,ds
;
    pop eax
    pop ds
    ret
AllocatePipe    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateBulkPipe
;
;       DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     ES      Device
;                       CX      Buffer count
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulkPipe   Proc far
    push ds
    push fs
    push eax
    push edx
;
    mov ax,flat_sel
    mov fs,ax
;
    EnterSection ds:ohc_section
    call AllocatePipe
    call AddBulkEd
    LeaveSection ds:ohc_section
;
    mov ds,bx
    mov ds:op_intr_count,0
    mov ds:op_intr_list,0
    mov ds:op_ed,edx
    clc
;
    pop edx
    pop eax
    pop fs
    pop ds
    retf32
CreateBulkPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateIntrPipe
;
;       DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     ES      Device
;                       CX      Buffer count
;                       DH      Interval
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntrPipe   Proc far
    push ds
    push fs
    push eax
    push edx
    push esi
    push edi
;
    mov ax,flat_sel
    mov fs,ax
;
    EnterSection ds:ohc_section
    push dx
    call AllocatePipe
    pop cx
    mov cl,ch
    call AddIntrEd
    LeaveSection ds:ohc_section
;
    mov ds,bx
    mov ds:op_intr_count,si
    mov ds:op_intr_list,di
    mov ds:op_ed,edx
    clc
;
    pop edi
    pop esi
    pop edx
    pop eax
    pop fs
    pop ds
    retf32
CreateIntrPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SignalStart
;
;       DESCRIPTION:    Signal start
;
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SignalStart Proc near
    push eax
;
    mov al,gs:ued_attrib
    and al,3
    cmp al,2
    jne ssDone
;
    mov ds,ds:ohc_reg_sel
    mov eax,ds:HcCommandStatus
    or al,4
    mov ds:HcCommandStatus,eax

ssDone:
    pop eax
    ret
SignalStart Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StopTds
;
;       DESCRIPTION:    Stop TDs
;
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopTds Proc near
    push fs
    push eax
    push ebx
    push edx
;
    lock and gs:usbp_flags,NOT PIPE_FLAG_ACTIVE
;
    mov ax,flat_sel
    mov fs,ax
    mov edx,gs:op_ed
    mov fs:[edx].oes_fa_en,4000h
;
    mov ax,5
    WaitMilliSec
;
    mov eax,fs:[edx].oes_tailp
    mov fs:[edx].oes_headp,eax
;
    pop edx
    pop ebx
    pop eax
    pop fs
    ret
StopTds Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreePacketTds
;
;       DESCRIPTION:    Free packet TDs
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device selector
;                       FS      Flat sel
;                       GS      Pipe selector
;                       BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePacketTds     Proc near
    push ds
    pushad
;
    mov ebp,gs:op_tail_td
    mov ds,bx
    mov si,SIZE usb_packet_struc
    mov cx,ds:usbpk_entry_count
    xor edi,edi

ftdLoop:
    mov edx,ds:[si+4]
    or edx,edx
    jz ftdBufFree
;
    push cx
    mov cx,gs:ued_maxsize
    FreeLinearMemBlk
    pop cx

ftdBufFree:
    mov edx,ds:[si]
    or edx,edx
    jz ftdNext
;
    cmp edx,ebp
    jz ftdNext
;
    push cx
    mov cx,SIZE ohc_td_struc
    FreeLinearMemBlk
    pop cx

ftdNext:
    add si,8
    sub cx,1
    jnz ftdLoop
;
    popad
    pop ds
    ret
FreePacketTds  Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartPacketTds
;
;       DESCRIPTION:    Start packet TDs
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device selector
;                       FS      Flat sel
;                       GS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartPacketTds     Proc near
    push ds
    pushad
;
    mov ds,gs:usbp_packet_sel
    mov si,SIZE usb_packet_struc
    mov cx,ds:usbpk_entry_count
    xor edi,edi

spbLoop:
    or edi,edi
    jz spbFirst
;
    mov edx,ds:[si]
    or edx,edx
    jnz spbSetup
;
    push cx
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
    pop cx
;
    mov fs:[edx].otd_resv,0
    mov fs:[edx].otd_cbp,0
    mov fs:[edx].otd_be,0
    mov fs:[edx].otd_next_td,0
    mov fs:[edx].otd_next_va,0
    mov fs:[edx].otd_buffer_va,0
    mov fs:[edi].otd_next_td,eax    
;
    mov ds:[si],edx
    jmp spbNext

spbSetup:
    LinearToPhysicalMemBlk
    mov fs:[edi].otd_next_td,eax

spbFirst:
    xor edx,edx
    xchg edx,gs:op_tail_td
    mov ds:[si],edx

spbNext:
    mov edi,edx
    mov fs:[edi].otd_flags,0F004h
;
    mov edx,ds:[si+4]
    or edx,edx
    jnz spbConv
;
    push cx
    mov cx,gs:ued_maxsize
    AllocateMemBlk
    pop cx
    mov ds:[si+4],edx
    jmp spbSave

spbConv:
    LinearToPhysicalMemBlk

spbSave:
    mov fs:[edi].otd_cbp,eax
    movzx ebx,gs:ued_maxsize
    add eax,ebx
    dec eax
    mov fs:[edi].otd_be,eax
    mov al,gs:ued_address
    mov fs:[edi].otd_pipe,al
    add si,8
    sub cx,1
    jnz spbLoop
;
    mov bx,ds:usbpk_entry_count
    dec bx
    mov ds:usbpk_tail_ptr,bx
;
    mov si,bx
    shl si,3
    add si,SIZE usb_packet_struc
    xor edx,edx
    xchg edx,ds:[si]
    mov gs:op_tail_td,edx
    mov fs:[edx].otd_next_td,0
;
    LinearToPhysicalMemBlk
    mov fs:[edi].otd_next_td,eax
    mov edx,gs:op_ed
    mov fs:[edx].oes_tailp,eax
;
    mov esi,gs:op_ed
    mov ax,gs:ued_maxsize
    mov fs:[esi].oes_mps,ax
;
    mov dl,gs:ued_address
    mov ah,dl
    and ah,0Fh
    xor al,al
    shr ax,1
    mov dh,es:usbd_address
    and dh,7Fh
    or al,dh
;
    cmp es:usbd_speed,0
    jnz spbSpeedOk
;
    or ah,20h

spbSpeedOk:    
    or ah,10h
    lock or gs:usbp_flags,PIPE_FLAG_ACTIVE
    mov fs:[esi].oes_fa_en,ax
;
    popad
    pop ds
    ret
StartPacketTds     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenPacket
;
;       DESCRIPTION:    Open packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;                       CX      Packet count
;
;       RETURNS:        BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenPacket   Proc far
    push es
    push eax
    push ecx
    push edi
;
    inc cx
    mov esi,edi
    movzx eax,cx
    shl ax,3
    add ax,SIZE usb_packet_struc
    AllocateSmallGlobalMem
    mov es:usbpk_entry_count,cx
;
    mov edi,SIZE usb_packet_struc
    xor eax,eax
    movzx ecx,cx
    add ecx,ecx
    rep stos dword ptr es:[edi]
;
    mov es:usbpk_tail_ptr,0
    mov bx,es
    clc
;
    pop edi
    pop ecx
    pop eax
    pop es
    retf32
OpenPacket    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClosePacket
;
;       DESCRIPTION:    Close packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;                       BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClosePacket   Proc far
    push ds
    push fs
    push ax
    push bx
;
    mov ax,flat_sel
    mov fs,ax
;
    call StopTds
    call FreePacketTds
;
    push es
    mov es,bx
    FreeMem
    pop es
;
    pop bx
    pop ax
    pop fs
    pop ds
    retf32
ClosePacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartPacket
;
;       DESCRIPTION:    Start packet interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartPacket   Proc far
    push ds
    push fs
    push ax
    push bx
;
    mov ax,flat_sel
    mov fs,ax
;
    call StartPacketTds
    call SignalStart
    clc
;
    pop bx
    pop ax
    pop fs
    pop ds
    retf32
StartPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReqPacket
;
;       DESCRIPTION:    Req packet
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;       RETURNS:        EDX     Buffer linear address
;                       CX      Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqPacket   Proc far
    push ds
    push fs
    push eax
    push ebx
    push esi
;
    mov ax,flat_sel
    mov fs,ax
    mov ds,gs:usbp_packet_sel
    mov bx,ds:usbpk_rd_ptr
    cmp bx,ds:usbpk_wr_ptr
    jne rqpkGet
;
    stc
    jmp rqpkDone

rqpkGet:
    shl bx,3
    add bx,SIZE usb_packet_struc
    mov esi,ds:[bx]
    mov eax,fs:[esi].otd_cbp
    or eax,eax
    jnz rqpkCalc
;
    mov edx,ds:[bx+4]
    movzx ecx,gs:ued_maxsize
    clc
    jmp rqpkDone

rqpkCalc:
    push bx
    xor ebx,ebx
    PhysicalToLinearMemBlk
    pop bx
;
    mov ecx,ds:[bx+4]
    sub ecx,edx
    neg ecx
    mov edx,ds:[bx+4]
    clc

rqpkDone:
    pop esi
    pop ebx
    pop eax
    pop fs
    pop ds
    retf32
ReqPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RelPacket
;
;       DESCRIPTION:    Release packet buffer
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RelPacket   Proc far
    push ds
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
    mov ds,gs:usbp_packet_sel
;
    EnterSection ds:usbpk_section
    mov bx,ds:usbpk_rd_ptr
    cmp bx,ds:usbpk_wr_ptr
    stc
    je rlpkDone
;
    inc bx
    cmp bx,ds:usbpk_entry_count
    jb rlpkOk
;
    xor bx,bx

rlpkOk:
    mov ds:usbpk_rd_ptr,bx
;
    mov bx,ds:usbpk_tail_ptr
    mov si,bx
    shl si,3
    add si,SIZE usb_packet_struc
    xor edi,edi
    xchg edi,gs:op_tail_td
    mov ds:[si],edi
    mov fs:[edi].otd_flags,0F004h
    mov edx,ds:[si+4]
    or edx,edx
    jnz rlpkConv
;
    push cx
    mov cx,gs:ued_maxsize
    AllocateMemBlk
    pop cx
    mov ds:[si+4],edx
    jmp rlpkSave

rlpkConv:
    LinearToPhysicalMemBlk

rlpkSave:
    mov fs:[edi].otd_cbp,eax
    movzx ebx,gs:ued_maxsize
    add eax,ebx
    dec eax
    mov fs:[edi].otd_be,eax
    mov al,gs:ued_address
    mov fs:[edi].otd_pipe,al
;
    mov bx,ds:usbpk_tail_ptr
    inc bx
    cmp bx,ds:usbpk_entry_count
    jb rlpkTailOk
;
    xor bx,bx

rlpkTailOk:
    mov ds:usbpk_tail_ptr,bx
;
    mov si,bx
    shl si,3
    add si,SIZE usb_packet_struc
    xor edx,edx
    xchg edx,ds:[si]
    mov gs:op_tail_td,edx
    mov fs:[edx].otd_next_td,0
;
    LinearToPhysicalMemBlk
    mov fs:[edi].otd_next_td,eax
    mov edx,gs:op_ed
    mov fs:[edx].oes_tailp,eax
;
    push ds
    mov ds,es:usbd_func_sel
    call SignalStart
    pop ds
    clc

rlpkDone:
    LeaveSection ds:usbpk_section
;
    popad
    pop fs
    pop ds
    retf32
RelPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           OpenRaw
;
;       DESCRIPTION:    Open raw interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;                       CX      Buffer size
;
;       RETURNS:        BX      Raw sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OpenRaw   Proc far
    push ds
    push fs
    pushad
;
    mov bp,gs:ued_maxsize
    mov ax,cx
    xor dx,dx
    dec ax
    add ax,bp
    cmp ax,1000h
    jbe orInRange
;
    mov ax,1000h

orInRange:
    div bp
    mov cx,ax
    mul bp
    push ax
;
    push es
    movzx eax,cx
    shl eax,2
    add eax,OFFSET or_td_arr
    AllocateSmallGlobalMem
;
    mov bx,es
    pop es
;
    mov ds,bx
    mov ds:or_td_count,cx
    mov ds:or_curr_count,0
;
    pop ax
    mov ds:usbr_buf_size,ax
;
    movzx ecx,ax
    AllocateMemBlk
    mov ds:usbr_buf_linear,edx
;
    AllocateGdt
    CreateDataSelector16
    mov ds:usbr_buf_sel,bx
;
    mov ax,flat_sel
    mov fs,ax
    mov cx,ds:or_td_count
    mov di,OFFSET or_td_arr
    xor edx,edx

orLoop:
    mov ds:[di],edx
    add di,4
    loop orLoop
;
    mov esi,gs:op_ed
    mov ax,gs:ued_maxsize
    mov fs:[esi].oes_mps,ax
;
    mov dl,gs:ued_address
    mov ah,dl
    and ah,0Fh
    xor al,al
    shr ax,1
    mov dh,es:usbd_address
    and dh,7Fh
    or al,dh
;    
    cmp es:usbd_speed,0
    jnz orSpeedOk
;
    or ah,20h

orSpeedOk:    
    test gs:ued_address,80h
    jz orOut

orIn:
    or ah,10h
    jmp orSaveEndp

orOut:
    or ah,8

orSaveEndp:
    mov fs:[esi].oes_fa_en,ax

orDone:
    popad
    mov bx,ds
;
    pop fs
    pop ds
    retf32
OpenRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CloseRaw
;
;       DESCRIPTION:    Close raw interface
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;                       BX      Raw sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseRaw   Proc far
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    call StopTds
;
    push bx
    mov gs,bx
;
    mov cx,gs:usbr_buf_size
    mov edx,gs:usbr_buf_linear
    FreeLinearMemBlk
;
    mov bx,gs:usbr_buf_sel
    FreeGdt
;
    mov cx,gs:or_curr_count
    or cx,cx
    jz frsFree
;
    mov si,OFFSET or_td_arr

frsLoop:
    mov edx,gs:[si]
    push cx
    mov cx,SIZE ohc_td_struc
    FreeLinearMemBlk
    pop cx
;
    add si,4
    loop frsLoop

frsFree:
    xor bx,bx
    mov gs,bx
    pop es
    FreeMem

frsDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    retf32
CloseRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RawIo
;
;       DESCRIPTION:    Raw IO
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RawIo   Proc near
    push ds
    push fs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
    mov ds,gs:usbp_raw_sel
;
    mov edx,ds:usbr_buf_linear
    LinearToPhysicalMemBlk
    mov ebp,eax
;
    mov si,OFFSET or_td_arr
    xor edi,edi
    xor bx,bx
    
rioLoop:
    or edi,edi
    jz rioFirst
;
    push cx
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
    pop cx
;
    mov fs:[edx].otd_resv,0
    mov fs:[edx].otd_cbp,0
    mov fs:[edx].otd_be,0
    mov fs:[edx].otd_next_td,0
    mov fs:[edx].otd_next_va,0
    mov fs:[edx].otd_buffer_va,0
    mov fs:[edi].otd_next_td,eax    
;
    mov ds:[si],edx
    jmp rioNext

rioFirst:
    xor edx,edx
    xchg edx,gs:op_tail_td
    mov ds:[si],edx

rioNext:
    mov edi,edx
    mov fs:[edi].otd_flags,0F0E4h
;
    mov eax,ebp
    mov fs:[edi].otd_cbp,eax
;
    movzx ebx,cx
    cmp bx,gs:ued_maxsize
    jb rioSizeOk
;
    mov bx,gs:ued_maxsize

rioSizeOk:
    sub cx,bx
;
    add eax,ebx
    dec eax
    mov fs:[edi].otd_be,eax
;
    movzx eax,gs:ued_maxsize
    add ebp,eax
;
    add si,4
    or cx,cx
    jnz rioLoop
;
    sub si,OFFSET or_td_arr
    shr si,2
    mov ds:or_curr_count,si
;
    mov cx,SIZE ohc_td_struc
    AllocateMemBlk
;
    mov fs:[edx].otd_resv,0
    mov fs:[edx].otd_cbp,0
    mov fs:[edx].otd_be,0
    mov fs:[edx].otd_next_td,0
    mov fs:[edx].otd_next_va,0
    mov fs:[edx].otd_buffer_va,0
    mov fs:[edi].otd_next_td,eax    
    mov fs:[edi].otd_flags,0F004h
    mov gs:op_tail_td,edx
;
    ClearSignal
    lock or gs:usbp_flags,PIPE_FLAG_ACTIVE
    mov edx,gs:op_ed
    mov fs:[edx].oes_tailp,eax
;
    push ds
    mov ds,es:usbd_func_sel
    call SignalStart
    pop ds

rioDone:
    popad
    pop fs
    pop ds
    ret
RawIo   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadRaw
;
;       DESCRIPTION:    Read raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       EDX     Linear buffer
;                       CX      Size
;
;       RETURNS:        CX      Read size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadRaw   Proc far
    call RawIo
    retf32
ReadRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteRaw
;
;       DESCRIPTION:    Write raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRaw   Proc far
    call RawIo
    retf32
WriteRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FinishRaw
;
;       DESCRIPTION:    Finish raw
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;       RETURNS:        NC
;                         CX    Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FinishRaw   Proc far
    push ds
    push fs
    push eax
    push ebx
    push edx
    push esi
    push ebp
;
    mov ax,flat_sel
    mov fs,ax
    mov ds,gs:usbp_raw_sel
;
    mov edx,ds:usbr_buf_linear
    LinearToPhysicalMemBlk
    mov ebp,eax
;
    mov edx,gs:op_ed
    mov eax,fs:[edx].oes_headp
    and al,0F0h
    cmp eax,fs:[edx].oes_tailp
    clc
    je frRel
;
    mov eax,fs:[edx].oes_headp
    test al,1
    jz frTimeout
;
    call StopTds

frTimeout:
    stc

frRel:
    pushf
    lock and gs:usbp_flags,NOT PIPE_FLAG_ACTIVE
    xor cx,cx
    xchg cx,ds:or_curr_count
    or cx,cx
    jz frDone
;
    mov si,OFFSET or_td_arr
    
frLoop:
    xor edx,edx
    xchg edx,ds:[si]
    or edx,edx
    jz frNext
;
    mov ebp,fs:[edx].otd_cbp
    or ebp,ebp
    jnz frSizeOk
;
    mov eax,fs:[edx].otd_be
    inc eax
    mov ebp,eax

frSizeOk:
    push cx
    mov cx,SIZE ohc_td_struc
    FreeLinearMemBlk
    pop cx

frNext:
    add si,4
    loop frLoop
;
    mov edx,ds:usbr_buf_linear
    LinearToPhysicalMemBlk
    sub ebp,eax
    mov cx,bp

frDone:
    popf
;
    pop ebp
    pop esi
    pop edx
    pop ebx
    pop eax
    pop fs
    pop ds
    retf32
FinishRaw   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsRunning
;
;       DESCRIPTION:    Check if controller is running
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsRunning   Proc far
    push fs
    push eax
;
    mov fs,ds:ohc_reg_sel
    mov eax,fs:HcControl
    shr eax,6
    and al,3
    cmp al,2
    stc
    jne irDone
;
    clc

irDone:
    pop eax
    pop fs
    retf32
IsRunning   Endp

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
    mov ebx,fs:[ebx].oes_next_va
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
    mov edx,fs:op_ed
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
    mov cx,flat_sel
    mov fs,cx
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
    mov ebx,ds:[di].oes_my_va
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
;       NAME:           Unlink
;
;       DESCRIPTION:    Unlink dev
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device
;                       
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Unlink   Proc far
    push eax
    push ebx
    push ecx
    push esi
;
    call UnlinkControl
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

udvInLoop:
    mov bx,es:[si]
    or bx,bx
    jz udvInNext
;
    call UnlinkPipe

udvInNext:
    add si,2
    loop udvInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

udvOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz udvOutNext
;
    call UnlinkPipe

udvOutNext:
    add si,2
    loop udvOutLoop
;
    movzx si,es:usbd_address
    add si,si
    mov ds:[si].ohc_dev_arr,0
;
    pop esi
    pop ecx
    pop ebx
    pop eax
    retf32
Unlink     Endp

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
    push eax
    mov ax,flat_sel
    mov fs,ax
;
    mov ax,SIZE ohc_td_struc
    mov si,SIZE ohci_dev_sel
    mov cx,16
    CreateMemBlk32
    pop eax
;
    movzx di,al
    add di,di
    mov ds:[di].ohc_dev_arr,es
;
    call AllocateTd
    mov es:dev_control_head,edx
    mov es:dev_curr_addr,0
    mov es:usbd_parent_thread,0
    mov es:usbd_func_sel,ds
;
    popad
    pop fs
    retf32
CreateDev  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               FreeDev
;
;       DESCRIPTION:        Free device sel
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeDev   Proc far
    retf32
FreeDev   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               PowerOffPort
;
;       DESCRIPTION:        Power off port
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerOffPort   Proc far
    push gs
    push eax
    push edi
;
    mov gs,ds:ohc_reg_sel
;    
    movzx di,dl
    shl di,2
    add di,OFFSET HcRhPortStatus
;    
    mov eax,200h
    mov gs:[di],eax
;
    pop edi
    pop eax
    pop gs
    retf32
PowerOffPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               PowerOnPort
;
;       DESCRIPTION:        Power on port
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PowerOnPort   Proc far
    push gs
    push eax
    push edi
;
    mov gs,ds:ohc_reg_sel
;    
    movzx di,dl
    shl di,2
    add di,OFFSET HcRhPortStatus
;    
    mov eax,100h
    mov gs:[di],eax
;
    pop edi
    pop eax
    pop gs
    retf32
PowerOnPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:               ResetPort
;
;       DESCRIPTION:        Reset port
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;       RETURNS:            AL      Speed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetPort   Proc far
    push gs
    push cx
    push di
;
    mov gs,ds:ohc_reg_sel
;    
    movzx di,dl
    shl di,2
    add di,OFFSET HcRhPortStatus
;
    mov cx,10

rpCheck:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[di]
    test al,1
    jz rpFail
;
    loop rpCheck
;    
    mov eax,10h
    mov gs:[di],eax

rpResetLoop:
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[di]
    test al,1
    jz rpFail
;    
    test al,10h
    jnz rpResetLoop
; 
    mov eax,2
    mov gs:[di],eax
;
    mov cx,40

rpWaitNotify:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[di]
    test al,1
    jz rpFail
;
    loop rpWaitNotify
;    
    mov ax,25
    WaitMilliSec
;
    mov eax,gs:[di]
    shr ax,9
    and al,1
    xor al,1
    clc
    jmp rpDone

rpFail:
    stc

rpDone:
    pop di
    pop cx
    pop gs
    retf32
ResetPort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisablePort
;
;       DESCRIPTION:    Disable port
;
;       PARAMETERS:     DS      Function selector
;                       DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisablePort   Proc far
    push gs
    push eax
    push edi
;
    movzx di,dl
    shl di,2
    add di,OFFSET HcRhPortStatus
    mov gs,ds:ohc_reg_sel
;
    mov eax,gs:[di]
    test al,1
    jz dpDone
;    
    mov eax,1
    mov gs:[di],eax
;
    mov ax,25
    WaitMilliSec

dpDone:
    pop edi
    pop eax
    pop gs
    retf32
DisablePort   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisableDev
;
;       DESCRIPTION:    Disable device
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisableDev   Proc far
    push gs
    push eax
    push edi
;
    mov dl,es:usbd_port
    movzx di,dl
    shl di,2
    add di,OFFSET HcRhPortStatus
    mov gs,ds:ohc_reg_sel
;
    mov eax,gs:[di]
    test al,1
    jz ddDone
;
    mov eax,1
    mov gs:[di],eax
;
    mov ax,25
    WaitMilliSec
;
    mov eax,gs:[di]
    test al,1
    jz ddDone
;
    mov cx,10

ddWaitDisable:    
    mov ax,5
    WaitMilliSec
;
    mov eax,gs:[di]
    test al,1
    jz ddDone
;
    test al,2
    jz ddDone
;
    loop ddWaitDisable

ddDone:
    pop edi
    pop eax
    pop gs
    retf32
DisableDev   Endp

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
;       NAME:           CC table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cc_tab:
cc00 DW 0
cc01 DW USB_EVENT_CRC_ERROR
cc02 DW USB_EVENT_BIT_STUFFING_ERROR
cc03 DW USB_EVENT_DATA_TOGGLE_ERROR
cc04 DW USB_EVENT_STALL
cc05 DW USB_EVENT_NOT_RESPONDING
cc06 DW USB_EVENT_PID_FAILURE
cc07 DW USB_EVENT_UNEXPECTED_PID
cc08 DW USB_EVENT_DATA_OVERRUN
cc09 DW USB_EVENT_DATA_UNDERRUN
cc0A DW 0
cc0B DW 0
cc0C DW USB_EVENT_BUFFER_OVERRUN
cc0D DW USB_EVENT_BUFFER_UNDERRUN
cc0E DW 0
cc0F DW USB_EVENT_HALTED

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckControl
;
;       DESCRIPTION:    Check control
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckControl   Proc near
    push ebx
    push edx
    push esi
;
    test es:usbd_flags,DEV_FLAG_CONTROL_ACTIVE
    jz cctDone
;
    mov edx,es:dev_control_head

cctLoop:
    mov bx,fs:[edx].otd_flags
    shr bx,12
    cmp bx,0Fh
    je cctDone
;
    or bx,bx
    jnz cctError
;
    mov edx,fs:[edx].otd_next_va
    or edx,edx
    jnz cctLoop
;
    mov es:dev_cc,0
    jmp cctSignal

cctError:
    mov es:dev_cc,bl
;
    add bx,bx
    mov ax,word ptr cs:[bx].cc_tab
    or ax,ax
    jz cctSignal
;
    xor dl,dl
    ReportUsbPipeEvent

cctSignal:
    mov bx,es:usbd_wait_dev
    SignalWaitDev

cctDone:
    pop esi
    pop edx
    pop ebx
    ret
CheckControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandlePacketIn
;
;       DESCRIPTION:    Handle packet IN transfer completed
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePacketIn  Proc near
    push ds
    push ebx
    push edx
    push esi
;
    mov ds,bx
    EnterSection ds:usbpk_section

hpiRetry:
    mov bx,ds:usbpk_wr_ptr
    cmp bx,ds:usbpk_tail_ptr
    je hpiDone
;
    mov si,bx
    shl si,3
    add si,SIZE usb_packet_struc
    mov edx,ds:[si]
;
    mov ax,fs:[edx].otd_flags
    shr ax,12
    cmp ax,0Fh
    je hpiDone

hpiLoop:
    inc bx
    cmp bx,ds:usbpk_entry_count
    jb hpiSave
;
    xor bx,bx

hpiSave:
    mov ds:usbpk_wr_ptr,bx
;
    or ax,ax
    jnz hpiReport
;
    cmp bx,ds:usbpk_tail_ptr
    je hpiSignal
;
    mov si,bx
    shl si,3
    add si,SIZE usb_packet_struc
    mov edx,ds:[si]
    mov ax,fs:[edx].otd_flags
    shr ax,12
    cmp ax,0Fh
    jnz hpiLoop
    jmp hpiSignal

hpiReport:
    mov ax,bx
    add bx,bx
    mov ax,word ptr cs:[bx].cc_tab
    or ax,ax
    jz hpiSignal
;
    lock or gs:usbp_flags,PIPE_FLAG_FAULT
    lock or es:usbd_flags,DEV_FLAG_FAULT
;
    push bx
    mov bx,es:usbd_thread
    Signal
    pop bx
;
    mov dl,gs:ued_address
    ReportUsbPipeEvent

hpiSignal:
    xor bx,bx
    xchg bx,gs:usbp_wait
    or bx,bx
    jz hpiDone
;
    push es
    mov es,bx
    SignalWait
    pop es

hpiDone:
    LeaveSection ds:usbpk_section
;
    pop esi
    pop edx
    pop ebx
    pop ds
    ret
HandlePacketIn  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleRawOut
;
;       DESCRIPTION:    Handle raw pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       BX      Raw sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRaw   Proc near
    push ds
    push ecx
    push edx
    push esi
    push ebp
;
    mov ds,bx
    mov bx,ds:usbr_wait_dev
;
    mov cx,ds:or_curr_count
    or cx,cx
    jz hroDone
;
    mov si,OFFSET or_td_arr

hroLoop:
    mov edx,ds:[si]
    mov ax,fs:[edx].otd_flags
    shr ax,12
    cmp ax,0Fh
    je hroDone
;
    or ax,ax
    jz hroNext
;
    push bx
    mov bx,ax
    add bx,bx
    mov ax,word ptr cs:[bx].cc_tab
    pop bx
    or ax,ax
    jz hroNext
;
    lock or gs:usbp_flags,PIPE_FLAG_FAULT
    lock or es:usbd_flags,DEV_FLAG_FAULT
;
    push bx
    mov bx,es:usbd_thread
    Signal
    pop bx
;
    mov dl,gs:ued_address
    ReportUsbPipeEvent

hroNext:
    add si,4
    loop hroLoop
;
    SignalWaitDev

hroDone:
    pop ebp
    pop esi
    pop edx
    pop ecx
    pop ds
    ret
HandleRaw  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckIn
;
;       DESCRIPTION:    Check IN pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckIn   Proc near
    push ebx
;
    test gs:usbp_flags,PIPE_FLAG_ACTIVE
    jz ciDone
;
    test gs:usbp_flags,PIPE_FLAG_FAULT
    jnz ciDone
;
    mov bx,gs:usbp_packet_sel
    or bx,bx
    jz ciNotPkt
;
    call HandlePacketIn
    jmp ciDone

ciNotPkt:
    mov bx,gs:usbp_raw_sel
    or bx,bx
    jz ciDone
;
    call HandleRaw

ciDone:
    pop ebx
    ret
CheckIn   Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckOut
;
;       DESCRIPTION:    Check OUT pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckOut   Proc near
    push ebx
;
    test gs:usbp_flags,PIPE_FLAG_ACTIVE
    jz cotDone
;
    test gs:usbp_flags,PIPE_FLAG_FAULT
    jnz cotDone
;
    mov bx,gs:usbp_raw_sel
    or bx,bx
    jz cotDone
;
    call HandleRaw

cotDone:
    pop ebx
    ret
CheckOut   Endp
        
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
;                       DL      Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort   Proc near
    push es
    push eax
    push ebx
    push esi
;    
    movzx si,dl
    shl si,2
    mov es,ds:ohc_reg_sel
;
    mov eax,es:HcRhStatus
    test al,2
    mov eax,es:[si].HcRhPortStatus
    jz upDo
;
    or al,8

upDo:
    xor bx,bx
    NotifyUsbPortState
;
    pop esi
    pop ebx
    pop eax
    pop es
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
    xor dx,dx
    mov cx,ds:ohc_root_ports

uuPortLoop:    
    call UpdatePort
    inc dx
    loop uuPortLoop
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
    push bx
    mov bx,ds:ohc_thread
    Signal
    pop bx

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
    and al,3Fh   ; NOT 0C0h
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
;
    mov ax,flat_sel
    mov fs,ax

ofhLoop:
    WaitForSignal    
;
    call fword ptr ds:is_running_proc
    jnc ofhRunning
;
    mov ax,USB_EVENT_CONTROLLER_ERROR
    ReportUsbFunctionEvent

ofhRunning:
    mov cx,127
    mov bx,OFFSET ohc_dev_arr

ofhDevLoop:
    mov ax,ds:[bx]
    or ax,ax
    jz ofhDevNext
;
    mov es,ax
    call CheckControl

ofhDevPipes:
    push ebx
    push ecx
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

ofhDevInLoop:
    mov bx,es:[si]
    or bx,bx
    jz ofhDevInNext
;
    mov gs,bx
    call CheckIn

ofhDevInNext:
    add si,2
    loop ofhDevInLoop
;
    mov cx,15
    mov si,OFFSET usbd_out_pipe_arr

ofhDevOutLoop:
    mov bx,es:[si]
    or bx,bx
    jz ofhDevOutNext
;
    mov gs,bx
    call CheckOut

ofhDevOutNext:
    add si,2
    loop ofhDevOutLoop
;
    pop ecx
    pop ebx

ofhDevNext:
    add bx,2
    loop ofhDevLoop
;
    mov es,ds:ohc_reg_sel
    mov eax,es:HcInterruptStatus
    and al,NOT 2
    mov es:HcInterruptStatus,eax
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
    xor edi,edi
    mov bx,ds:ohc_pci_handle
    LockPciHandle
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
ot00 DD OFFSET Block,               SEG code
ot01 DD OFFSET Unblock,             SEG code
ot02 DD OFFSET PowerOffPort,        SEG code
ot03 DD OFFSET PowerOnPort,         SEG code
ot04 DD OFFSET ResetPort,           SEG code
ot05 DD OFFSET DisablePort,         SEG code
ot06 DD OFFSET DisableDev,          SEG code
ot07 DD OFFSET IsPortConnected,     SEG code
ot08 DD OFFSET IsRunning,           SEG code
ot09 DD OFFSET AllocateAddress,     SEG code
ot0A DD OFFSET FreeAddress,         SEG code
ot0B DD OFFSET CreateDev,           SEG code
ot0C DD OFFSET Unlink,              SEG code
ot0D DD OFFSET IsDeviceConnected,   SEG code
ot0E DD OFFSET FreeDev,             SEG code
ot0F DD OFFSET CreateControl,       SEG code
ot10 DD OFFSET CreateBulkPipe,      SEG code
ot11 DD OFFSET CreateIntrPipe,      SEG code
ot12 DD OFFSET AddressDev,          SEG code
ot13 DD OFFSET ChangeAddress,       SEG code
ot14 DD OFFSET UpdateMaxLen,        SEG code
ot15 DD OFFSET ControlMsg,          SEG code
ot16 DD OFFSET ConfigDev,           SEG code
ot17 DD OFFSET OpenPacket,          SEG code
ot18 DD OFFSET ClosePacket,         SEG code
ot19 DD OFFSET StartPacket,         SEG code
ot1A DD OFFSET ReqPacket,           SEG code
ot1B DD OFFSET RelPacket,           SEG code
ot1C DD OFFSET OpenRaw,             SEG code
ot1D DD OFFSET CloseRaw,            SEG code
ot1E DD OFFSET ReadRaw,             SEG code
ot1F DD OFFSET WriteRaw,            SEG code
ot20 DD OFFSET FinishRaw,           SEG code

InitFunction    Proc near
    push ds
    push es
    push fs
    pushad
;
    mov bx,ds:ohc_pci_handle
    mov al,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET OhciInt
    SetupPciHandleIrq
    jc ifIrqFail
;
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
    mov cx,2*21h

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbFunction
    InitSection ds:ohc_section
;    
    push es
    mov ax,ds
    mov es,ax
    mov di,OFFSET ohc_dev_arr
    mov cx,127
    xor ax,ax
    rep stosw
    pop es
;
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
;       PARAMETERS:         BX      PCI handle
;                           EAX     Register base
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
    mov ds:ohc_reg_sel,bp
    mov ds:ohc_int_status,0
    mov ds:ohc_linear,edx
    mov bp,bx
;
    pop cx
    pop bx
;    
    mov ds:ohc_pci_handle,bx
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
    mov ax,cs
    mov es,ax
    xor bx,bx

ipLoop:
    mov ah,0Ch
    mov al,3
    mov dl,10h
    FindPciProtocolHandle
    jc ipDone
;
    xor al,al
    GetPciBarPhys
    jc ipLoop
;
    mov edi,OFFSET ohci_name
    LockPciHandle
;
    call AddFunction
    jmp ipLoop
    
ipDone:
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
