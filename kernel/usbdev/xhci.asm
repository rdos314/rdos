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
; XHCI.ASM
; XHCI-based USB host controller driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os\system.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\pcdev\pci.inc
INCLUDE usb.inc
INCLUDE usbdev.inc

TRB_TYPE_NORMAL         = 1
TRB_TYPE_SETUP          = 2
TRB_TYPE_DATA           = 3
TRB_TYPE_STATUS         = 4
TRB_TYPE_ISO            = 5
TRB_TYPE_LINK           = 6
TRB_TYPE_EVENT          = 7
TRB_TYPE_NO_OP          = 8
TRB_TYPE_ENABLE_SLOT    = 9
TRB_TYPE_DISABLE_SLOT   = 10
TRB_TYPE_ADDRESS_DEV    = 11
TRB_TYPE_CONFIGURE_ENDP = 12
TRB_TYPE_EVALUATE       = 13
TRB_TYPE_RESET_ENDP     = 14
TRB_TYPE_STOP_ENDP      = 15
TRB_TYPE_SET_TR         = 16
TRB_TYPE_RESET_DEV      = 17
TRB_TYPE_NO_OP_CMD      = 23
TRB_TYPE_TRANSFER       = 32
TRB_TYPE_CMD_COMPLETE   = 33
TRB_TYPE_PORT_CHANGE    = 34
TRB_TYPE_CONTROLLER     = 37
TRB_TYPE_DEV_NOTIFY     = 38
TRB_TYPE_MFI_WRAP       = 39

XP_FLAG_TRANSFER_PENDING   = 1
XP_FLAG_CLOSED             = 2
XP_FLAG_DATA               = 4
XP_FLAG_SINGLE             = 8

trb_struc   STRUC

trb_param   DD ?,?
trb_status  DD ?
trb_type    DW ?
trb_control DW ?

trb_struc   ENDS

cmd_struc   STRUC

cmd_thread  DW ?
cmd_resv    DW ?,?,?
cmd_event   DD ?,?

cmd_struc   ENDS

input_control_context_struc STRUC

icc_drop_mask   DD ?
icc_add_mask    DD ?
icc_pad1        DD 5 DUP(?)
icc_config      DB ?
icc_interface   DB ?
icc_alt         DB ?
icc_pad2        DB ?

input_control_context_struc ENDS

slot_struc  STRUC

s_misc          DD ?
s_exit_latency  DW ?
s_root_hub      DB ?
s_hub_ports     DB ?
s_tt_slot_id    DB ?
s_tt_port_nr    DB ?
s_ttt_int       DW ?
s_address       DB ?
s_pad1          DB ?
s_state         DW ?

slot_struc  ENDS

endpoint_context_struc  STRUC

ec_state        DB ?
ec_param1       DB ?
ec_interval     DB ?
ec_esit_hi      DB ?
ec_param2       DB ?
ec_burst_size   DB ?
ec_packet_size  DW ?
ec_tr_dequeue   DD ?,?
ec_avg_len      DW ?
ec_esit_low     DD ?

endpoint_context_struc  ENDS

hcc_cap_struc   STRUC

hccLen      DB ?
hccResv     DB ?
hccVersion  DW ?
hccParams1  DD ?
hccParams2  DD ?
hccParams3  DD ?
hccCap1     DD ?
hccDbOff    DD ?
hccRtsOff   DD ?
hccCap2     DD ?

hcc_cap_struc   ENDS

op_reg_struc    STRUC

orsUsbCmd   DD ?
orsUsbSts   DD ?
orsPageSize DD ?
orsResv1    DD ?,?
orsDnCtrl   DD ?
orsCrCtrl   DD ?,?
orsResv2    DD ?,?,?,?
orsDcbaap   DD ?,?
orsConfig   DD ?

op_reg_struc    ENDS

run_reg_struc   STRUC

rrsIndex    DD ?
rrsResv     DD 7 DUP(?)

rrsIman     DD ?
rrsImod     DD ?
rrsRingSize DD ?
rrsPad      DD ?
rrsBase     DD ?,?
rrsDequeue  DD ?,?

run_reg_struc   ENDS

port_stat_struc STRUC

pss_sc      DD ?
pss_pmsc    DD ?
pss_link    DD ?
pss_lpm     DD ?

port_stat_struc ENDS

xhci_func_sel   STRUC

usb_dev_base        usb_dev_struc <>

xhc_hcc_sel         DW ?
xhc_reg_sel         DW ?
xhc_port_sel        DW ?
xhc_db_sel          DW ?
xhc_rts_sel         DW ?
xhc_device_ptr_sel  DW ?
xhc_cmd_ring_sel    DW ?
xhc_event_ring_sel  DW ?

xhc_slot_count      DB ?
xhc_port_count      DB ?

xhc_context_size    DW ?
xhc_dcba            DD ?,?
xhc_crcr            DD ?,?
xhc_erst            DD ?,?
xhc_edqe            DD ?,?

xhc_cmd_enque       DW ?
xhc_cmd_pcs         DW ?

xhc_reset           DD ?

xhc_attach_pend     DD ?
xhc_detach_pend     DD ?
xhc_reset_pend      DD ?

xhc_event_thread    DW ?
xhc_cmd_section     section_typ <>
xhc_event_ccs       DW ?

xhc_port_thread         DW ?
xhc_port_change_mask    DD ?

xhc_port_slot_arr   DB 256 DUP(?)

xhc_func_sel_arr    DW 256 DUP(?)

xhci_func_sel   ENDS

xhci_dev_struc   STRUC

usb_function_base        usb_function_struc <>

xd_phys                  DD ?,?
xd_linear                DD ?

xd_dev_sel               DW ?

xd_input_context_offset  DW ?
xd_input_slot_offset     DW ?
xd_output_context_offset DW ?
xd_input_ep_arr_offset   DW 32 DUP (?)
xd_output_ep_arr_offset  DW 32 DUP (?)

xd_ep_sel_arr            DW 32 DUP(?)

xhci_dev_struc    ENDS

xhci_pipe   STRUC

xp_pipe_base   usb_pipe_struc <>

xp_ring_linear      DD ?
xp_ring_phys        DD ?,?
xp_ring_offset      DW ?

xp_dev_sel          DW ?
xp_port_sel         DW ?
xp_port_nr          DB ?
xp_slot             DB ?

xp_setup_offset     DW ?

xp_ring_enque       DW ?
xp_ring_fetch       DW ?
xp_ring_deque       DW ?
xp_ring_pcs         DW ?

xp_size             DW ?
xp_remain_size      DW ?

xp_data_head        DW ?
xp_data_last        DW ?

xp_db_target        DB ?
xp_result           DB ?

xp_flags            DB ?

xhci_pipe   ENDS

data    SEGMENT byte public 'DATA'

dummy   DB ?


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
;           NAME:           PortToSpeed
;
;           DESCRIPTION:    Convert Port SC to speed
;
;       PARAMETERS:         EAX Port SC
;
;       RETURNS:            AL  Speed 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ptsTab:
pts00 DB -1
pts01 DB 1
pts02 DB 0
pts03 DB 2
pts04 DB 3
pts05 DB -1  
pts06 DB -1  
pts07 DB -1  
pts08 DB -1  
pts09 DB -1  
pts0A DB -1  
pts0B DB -1  
pts0C DB -1  
pts0D DB -1  
pts0E DB -1  
pts0F DB -1  

PortToSpeed   Proc near
    push bx
    mov bx,ax
    shr bx,10
    and bx,0Fh
    mov al,byte ptr cs:[bx].ptsTab
    pop bx
    ret
PortToSpeed   Endp
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SpeedToPsi
;
;           DESCRIPTION:    Convert speed to PSI value
;
;       PARAMETERS:         AH  speed
;
;       RETURNS:            AL  PSI value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stpTab:
stp00 DB 2
stp01 DB 1
stp02 DB 3
stp03 DB 4
stp05 DB -1  
stp06 DB -1  
stp07 DB -1  
stp08 DB -1  
stp09 DB -1  
stp0A DB -1  
stp0B DB -1  
stp0C DB -1  
stp0D DB -1  
stp0E DB -1  
stp0F DB -1  

SpeedToPsi   Proc near
    push bx
    movzx bx,ah
    and bx,0Fh
    mov al,byte ptr cs:[bx].stpTab
    pop bx
    ret
SpeedToPsi   Endp
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetDefaultPacketSize
;
;       DESCRIPTION:    Convert speed to PSI value
;
;       PARAMETERS:     AH  speed
;
;       RETURNS:        AX  Packet size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gdpsTab:
gdps00 DW 8
gdps01 DW 8
gdps02 DW 64
gdps03 DW 512
gdps05 DW 8 
gdps06 DW 8  
gdps07 DW 8  
gdps08 DW 8  
gdps09 DW 8  
gdps0A DW 8  
gdps0B DW 8  
gdps0C DW 8  
gdps0D DW 8  
gdps0E DW 8  
gdps0F DW 8  

GetDefaultPacketSize   Proc near
    push bx
    movzx bx,ah
    and bx,0Fh
    add bx,bx
    mov ax,word ptr cs:[bx].gdpsTab
    pop bx
    ret
GetDefaultPacketSize   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateSegment
;
;       DESCRIPTION:    Allocate new segment
;
;       RETURNS:        EBX:EAX     Physical address of TRB
;                       EDX         Linear address of TRB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateSegment   Proc near
    push es
    push ecx
    push edi
;
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
;    
    AllocatePhysical64
    push eax
;
    mov al,13h
    SetPageEntry
;
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;    
    pop eax    
;        
    pop edi
    pop ecx
    pop es    
    ret
AllocateSegment   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupLinkTrb
;
;       DESCRIPTION:    Setup link TRB
;
;       PARAMETERS:     EBX:EAX     Physical link address
;                       GS:EDI      TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupLinkTrb   Proc near
    mov gs:[edi].trb_param,eax
    mov gs:[edi].trb_param+4,ebx
    mov gs:[edi].trb_status,0
    mov gs:[edi].trb_type,2 + (TRB_TYPE_LINK SHL 10)
    mov gs:[edi].trb_control,0
    ret
SetupLinkTrb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateEventRing
;
;       DESCRIPTION:    Init event ring
;
;       PARAMETERS:     ES      Function selector
;
;       RETURNS:        EDI     Event ring linear
;                       EBX:EAX Event ring physical
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEventRing   Proc near
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
    mov es:xhc_erst,eax
    mov es:xhc_erst+4,ebx
;
    mov al,13h
    SetPageEntry
;
    push es
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    call AllocateSegment
;
    mov es:[edi],eax
    mov es:[edi+4],ebx
    mov ecx,256
    mov es:[edi+8],ecx
    xor ecx,ecx
    mov es:[edi+12],ecx
    pop es
;    
    mov es:xhc_edqe,eax
    mov es:xhc_edqe+4,ebx    
    ret
CreateEventRing   Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateScratchPad
;
;       DESCRIPTION:    Create scratch pad area (if needed)
;
;       PARAMETERS:     ES      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateScratchPad   Proc near
    push ds
;    
    mov bx,xhci_hcc_sel
    mov ds,bx
    mov eax,ds:hccParams2
    mov edx,eax
    shr edx,27
    and dx,1Fh
    shr eax,16
    and ax,3E0h
    add ax,dx    
    or ax,ax
    jz cspDone
;
    push es
    pushad
;
    push ax
    mov eax,2000h
    AllocateBigLinear
    AllocatePhysical64
    mov al,13h
    SetPageEntry
    xor al,al
    mov si,xhci_device_ptr_sel
    mov es,si
    xor si,si
    mov es:[si],eax
    mov es:[si+4],ebx
    pop cx
;
    mov ax,flat_sel
    mov es,ax
;
    mov ebp,edx
    add edx,1000h
        
cspLoop:
    AllocatePhysical64
    mov es:[ebp],eax
    mov es:[ebp+4],ebx
;
    push ecx
    mov al,13h
    SetPageEntry
;
    mov edi,edx
    xor eax,eax
    mov ecx,400h
    rep stos dword ptr es:[edi]
    pop ecx
;
    add ebp,8
    loop cspLoop
;
    popad
    pop es    
        
cspDone:    
    pop ds
    ret
CreateScratchPad   Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateCommandRing
;
;       DESCRIPTION:    Create command ring
;
;       PARAMETERS:     ES      Function selector
;
;       RETURNS:        EDX     Ring linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCommandRing   Proc near
    push gs
    push edi
;
    mov ax,flat_sel
    mov gs,ax    
;
    mov eax,2000h
    AllocateBigLinear
;
    mov ecx,2
    AllocateMultiplePhysical64
    mov es:xhc_crcr,eax
    mov es:xhc_crcr+4,ebx
;
    mov al,13h
    SetPageEntry
;
    push eax
    push edx
    add eax,1000h
    add edx,1000h
    SetPageEntry
    pop edx
    pop eax
;
    push es
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    mov ecx,800h
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop es
;
    mov edi,edx
    add edi,0FF0h
    mov eax,es:xhc_crcr
    mov ebx,es:xhc_crcr+4
    call SetupLinkTrb
;
    mov es:xhc_cmd_enque,0
    mov es:xhc_cmd_pcs,1
;
    pop edi
    pop gs    
    ret
CreateCommandRing   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForCommandTrb
;
;       DESCRIPTION:    Wait for empty command TRB
;
;       PARAMETERS:     DS          Function sel
;
;       RETURNS:        GS:EDI      TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCommandTrb   Proc near
    push ax
;
    EnterSection ds:xhc_cmd_section    
;    
    mov gs,ds:xhc_cmd_ring_sel
    movzx edi,ds:xhc_cmd_enque

wfctLoop:    
    mov ax,gs:[di].trb_type
    test ax,2
    jz wfctRetry
;
    xor gs:[di].trb_type,1
    xor ds:xhc_cmd_pcs,1
    xor di,di
    jmp wfctLoop

wfctRetry:    
    xor ax,ds:xhc_cmd_pcs
    test al,1
    jnz wfctOk
;
    mov ax,10
    WaitMilliSec
    jmp wfctRetry        

wfctOk:
    mov ax,di
    add ax,SIZE trb_struc
    mov ds:xhc_cmd_enque,ax
;
    mov gs:[di].trb_param,0
    mov gs:[di].trb_param+4,0
    mov gs:[di].trb_status,0
    mov gs:[di].trb_control,0
;
    pop ax        
    ret
WaitForCommandTrb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SendCommandTrb
;
;       DESCRIPTION:    Send command TRB
;
;       PARAMETERS:     AL      TRB type
;                       DS      Function sel
;                       GS:EDI  TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCommandTrb   Proc near
    push eax
;    
    push ax
    GetThread
    mov gs:[edi+1000h].cmd_thread,ax
    pop ax
;
    movzx ax,al
    shl ax,10
    or ax,ds:xhc_cmd_pcs
    mov gs:[edi].trb_type,ax
;
    push ds
    mov ds,ds:xhc_db_sel
    xor eax,eax
    mov ds:[0],eax
    pop ds
;
    LeaveSection ds:xhc_cmd_section    

sctWait:
    WaitForSignal
    mov ax,gs:[edi+1000h].cmd_thread
    or ax,ax
    jnz sctWait
;
    pop eax
    ret
SendCommandTrb  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EnableSlot
;
;       DESCRIPTION:    Enable slot
;
;       PARAMETERS:     DS      Function sel
;
;       RETRURNS:       AL      Slot ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnableSlot  Proc near
    push gs
    push edi
;
    call WaitForCommandTrb
    mov al,TRB_TYPE_ENABLE_SLOT
    call SendCommandTrb
;
    mov al,gs:[edi+100Bh]
    cmp al,1
    stc
    jne esDone
;
    mov al,gs:[edi+100Fh]
    clc        

esDone:
    pop edi
    pop gs    
    ret
EnableSlot  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisableSlot
;
;       DESCRIPTION:    Disable slot
;
;       PARAMETERS:     DS      Function sel
;                       AL      Slot ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisableSlot  Proc near
    push gs
    push edi
;
    push ax
    call WaitForCommandTrb
    pop dx
;    
    xor eax,eax
    mov gs:[edi].trb_param,eax
    mov gs:[edi].trb_param+4,eax
;
    mov ah,dl
    xor al,al
    mov gs:[edi].trb_control,ax
    mov al,TRB_TYPE_DISABLE_SLOT
    call SendCommandTrb
;
    mov al,gs:[edi+100Bh]
    cmp al,1
    stc
    jne dsDone
;
    mov al,gs:[edi+100Fh]
    clc        

dsDone:
    pop edi
    pop gs    
    ret
DisableSlot  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ResetSlot
;
;       DESCRIPTION:    Reset slot
;
;       PARAMETERS:     DS      Function sel
;                       AL      Slot ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetSlot  Proc near
    push gs
    push ax
    push edi
;
    push ax
    call WaitForCommandTrb
    pop dx
;    
    xor eax,eax
    mov gs:[edi].trb_param,eax
    mov gs:[edi].trb_param+4,eax
;
    mov ah,dl
    xor al,al
    mov gs:[edi].trb_control,ax
    mov al,TRB_TYPE_RESET_DEV
    call SendCommandTrb
;
    mov al,gs:[edi+100Bh]
    cmp al,1
    stc
    jne rsDone
;
    clc        

rsDone:
    pop edi
    pop ax
    pop gs    
    ret
ResetSlot  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateDevice
;
;       DESCRIPTION:    Allocate device
;
;       PARAMETERS:     DS      Device sel
;                       AL      Speed
;
;       RETURNS:        ES      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateDevice    Proc near
    pushad
;
    push eax
    mov eax,1000h
    AllocateBigLinear
;    
    AllocatePhysical64
    push ebx
    push eax
;
    mov al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es,bx
;    
    xor edi,edi
    mov ecx,400h
    xor eax,eax
    rep stosd
;
    pop eax
    pop ebx
    mov es:xd_phys,eax
    mov es:xd_phys+4,ebx
    mov es:xd_linear,edx
    mov es:xd_dev_sel,ds
;
    pop eax
    mov es:usbf_speed,al
;    
    mov bx,SIZE xhci_dev_struc
    add bx,40h
    dec bx
    and bx,0FFC0h
    mov dx,ds:xhc_context_size
;    
    mov es:xd_input_context_offset,bx
;
    add bx,dx
    mov es:xd_input_slot_offset,bx
    mov di,OFFSET xd_input_ep_arr_offset
    mov cx,32

adiEpLoop:
    add bx,dx
    mov es:[di],bx
    add di,2 
    loop adiEpLoop      
;
    add bx,dx
    add bx,40h
    dec bx
    and bx,0FFC0h
;    
    mov es:xd_output_context_offset,bx
    mov di,OFFSET xd_output_ep_arr_offset
    mov cx,32

adoEpLoop:
    add bx,dx
    mov es:[di],bx
    add di,2 
    loop adoEpLoop      
;
    add bx,dx
    add bx,40h
    dec bx
    and bx,0FFC0h
;    
    movzx ecx,bx
    mov edx,es:xd_linear
    mov bx,es
    CreateDataSelector16
    mov es,bx
;
    popad
    ret
AllocateDevice    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupRootDevice
;
;       DESCRIPTION:    Setup root device context
;
;       PARAMETERS:     DS      Device sel
;                       ES      Function sel
;                       CL      Port #
;                       AL      PSI speed value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupRootDevice    Proc near
    pushad
;    
;
    mov bx,es:xd_input_context_offset
    mov es:[bx].icc_add_mask,0
;    
    mov bx,es:xd_input_slot_offset
    movzx eax,al
    shl eax,20
    or eax,08000000h
    mov es:[bx].s_misc,eax
    mov al,cl
    inc al
    mov es:[bx].s_root_hub,al
;    
    popad
    ret
SetupRootDevice     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddConfigEp
;
;       DESCRIPTION:    Add config EP
;
;       PARAMETERS:     DS      Device sel
;                       ES      Function sel
;                       FS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddConfigEp Proc near
    pushad
;
    mov bx,es:xd_input_context_offset
    mov eax,es:[bx].icc_add_mask
    test al,2
    jz aceNoReset
;
    mov eax,1

aceNoReset:    
    mov cl,fs:xp_db_target
    mov edx,1
    shl edx,cl
    or eax,edx
    mov es:[bx].icc_add_mask,eax
;
    mov bx,es:xd_input_slot_offset    
    mov eax,es:[bx].s_misc
    shr eax,27
    cmp al,fs:xp_db_target
    ja aceCountOk
;
    mov ecx,es:[bx].s_misc
    and ecx,07FFFFFFh
    mov al,fs:xp_db_target
    inc al
    shl eax,27
    or eax,ecx
    mov es:[bx].s_misc,eax

aceCountOk:
    popad
    ret
AddConfigEp Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateEndpointRing
;
;       DESCRIPTION:    Create endpoint ring
;
;       RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEndpointRing   Proc near
    push es
    push gs
    pushad
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical64
;
    push ebx
    push eax
    mov al,13h
    SetPageEntry
;
    AllocateGdt
    mov cx,1000h
    CreateDataSelector16
    mov es,bx
    mov fs,bx
    mov gs,bx
;
    xor di,di
    mov cx,400h
    xor eax,eax
    rep stosd
    pop eax
    pop ebx
;
    mov edx,SIZE xhci_pipe
    add dx,10h
    dec dx
    and dx,0FFF0h
    mov fs:xp_ring_offset,dx    
    mov fs:xp_ring_enque,dx
    mov fs:xp_ring_deque,dx
    mov fs:xp_ring_fetch,0
    mov fs:xp_ring_pcs,1
;    
    add eax,edx
    mov fs:xp_ring_phys,eax
    mov fs:xp_ring_phys+4,ebx
;
    mov edi,0FF0h
    call SetupLinkTrb
;
    popad
    pop gs
    pop es
    ret
CreateEndpointRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForEndpointTrb
;
;       DESCRIPTION:    Wait for empty endpoint TRB
;
;       PARAMETERS:     FS          Pipe sel
;
;       RETURNS:        FS:ESI      TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForEndpointTrb   Proc near
    push ax
;    
    movzx esi,fs:xp_ring_enque

wfetLoop:    
    mov ax,fs:[si].trb_type
    test ax,2
    jz wfetRetry
;
    xor fs:[si].trb_type,1
    xor fs:xp_ring_pcs,1
    mov si,fs:xp_ring_offset
    jmp wfetLoop

wfetRetry:    
    xor ax,fs:xp_ring_pcs
    test al,1
    jnz wfetOk
;
    mov ax,10
    WaitMilliSec
    jmp wfetRetry        

wfetOk:
    mov ax,si
    add ax,SIZE trb_struc
    mov fs:xp_ring_enque,ax
;
    mov fs:[si].trb_param,0
    mov fs:[si].trb_param+4,0
    mov fs:[si].trb_status,0
    mov fs:[si].trb_control,0
;
    pop ax        
    ret
WaitForEndpointTrb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           StopEndpoint
;
;   DESCRIPTION:    Stop endpoint
;
;   PARAMETERS:     DS      Function selector
;                   FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopEndpoint   Proc near
    push es
    push gs
    push eax
    push edi
;
    call WaitForCommandTrb
;    
    mov es,fs:xp_dev_sel
    xor eax,eax
    mov gs:[edi].trb_param,eax
    mov gs:[edi].trb_param+4,eax
;
    mov ah,fs:xp_slot
    mov al,fs:xp_db_target
    mov gs:[edi].trb_control,ax
;
    mov al,TRB_TYPE_STOP_ENDP
    call SendCommandTrb
;
    mov al,gs:[edi+100Bh]
    cmp al,1
    stc
    jne seDone
;
    mov al,gs:[edi+100Fh]
    clc        

seDone:
    pop edi
    pop eax
    pop gs    
    pop es
    ret
StopEndpoint   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateControl
;
;           DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Device selector
;                       ES      Function selector
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    pushad
;
    mov ah,es:usbf_speed
    call SpeedToPsi
    mov cl,es:usbf_port
    call SetupRootDevice
    call CreateEndpointRing
;
    push ax
    mov fs:xp_dev_sel,es
    mov al,es:usbf_port
    mov fs:xp_port_nr,al
    mov ax,ds:xhc_port_sel
    mov fs:xp_port_sel,ax
    mov al,es:usbf_address
    mov fs:xp_slot,al
    mov fs:xp_db_target,1
    mov es:xd_ep_sel_arr,fs
    pop ax
; 
    mov bx,es:xd_input_ep_arr_offset
    call GetDefaultPacketSize
    mov es:[bx].ec_packet_size,ax
    mov es:[bx].ec_avg_len,ax
;
    mov eax,fs:xp_ring_phys
    or al,1
    mov es:[bx].ec_tr_dequeue,eax
    mov eax,fs:xp_ring_phys+4
    mov es:[bx].ec_tr_dequeue+4,eax        
;
    mov al,3 SHL 1
    or al,4 SHL 3
    mov es:[bx].ec_param2,al
    clc
;
    popad
    retf32
CreateControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddressDevice
;
;   DESCRIPTION:    Address device
;
;   PARAMETERS:     DS      Function selector
;                   FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddressDevice   Proc far
    push es
    push gs
    push eax
    push bx
    push edi
;
    call WaitForCommandTrb
;    
    mov es,fs:xp_dev_sel
    mov bx,es:xd_input_context_offset
    mov es:[bx].icc_add_mask,3
    movzx eax,bx
    add eax,es:xd_phys
    mov gs:[edi].trb_param,eax
    mov eax,es:xd_phys+4
    mov gs:[edi].trb_param+4,eax
;
    mov ah,fs:xp_slot
    xor al,al
    mov gs:[edi].trb_control,ax
;
    mov al,TRB_TYPE_ADDRESS_DEV
    call SendCommandTrb
;
    mov bx,es:xd_input_context_offset
    mov es:[bx].icc_add_mask,0
;
    mov al,gs:[edi+100Bh]
    cmp al,1
    je adOk
;
    stc
    jmp adDone

adOk:
    mov al,gs:[edi+100Fh]
    clc        

adDone:
    pop edi
    pop bx
    pop eax
    pop gs    
    pop es
    retf32
AddressDevice   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ConfigDevice
;
;   DESCRIPTION:    Configure device endpoints
;
;   PARAMETERS:     DS      Device selector
;                   ES      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigDevice   Proc far
    push es
    push gs
    push eax
    push ebx
    push ecx
    push edi
;
    call WaitForCommandTrb
    movzx eax,es:xd_input_context_offset
    add eax,es:xd_phys
    mov gs:[edi].trb_param,eax
    mov eax,es:xd_phys+4
    mov gs:[edi].trb_param+4,eax
;
    mov ah,fs:xp_slot
    xor al,al
    mov gs:[edi].trb_control,ax
;
    mov al,TRB_TYPE_CONFIGURE_ENDP
    call SendCommandTrb
;
    mov al,gs:[edi+100Bh]
    cmp al,1
    stc
    jne ceDone
;
    mov al,gs:[edi+100Fh]
    clc        

ceDone:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop gs    
    pop es
    retf32
ConfigDevice   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateBulk
;
;           DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     DS      Device selector
;                       ES      Function selector
;                       DL      Pipe #, bit 7 IN.
;                       CX      Max data size
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateBulk   Proc far
    pushad
;   
    mov ah,es:usbf_speed
    call CreateEndpointRing
;
    movzx bx,dl
    and bl,7Fh
    add bx,bx
    test dl,80h
    jz cbDirOk
;    
    inc bx

cbDirOk:    
    mov fs:xp_db_target,bl
;        
    mov fs:xp_dev_sel,es
    mov al,es:usbf_port
    mov fs:xp_port_nr,al
    mov ax,ds:xhc_port_sel
    mov fs:xp_port_sel,ax
    mov al,es:usbf_address
    mov fs:xp_slot,al
;
    dec bx
    add bx,bx    
    mov es:[bx].xd_ep_sel_arr,fs
; 
    mov bx,es:[bx].xd_input_ep_arr_offset
    mov eax,fs:xp_ring_phys
    or al,1
    mov es:[bx].ec_tr_dequeue,eax
    mov eax,fs:xp_ring_phys+4
    mov es:[bx].ec_tr_dequeue+4,eax        
    mov es:[bx].ec_avg_len,cx
    mov es:[bx].ec_packet_size,cx
;
    mov al,3 SHL 1
    or al,2 SHL 3
    test dl,80h
    jz cbTypeOk
;    
    or al,4 SHL 3

cbTypeOk:    
    mov es:[bx].ec_param2,al        
    call AddConfigEp
;
    popad
    retf32
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateIntr
;
;   DESCRIPTION:    Create interrupt pipe
;
;   PARAMETERS:     DS      Device selector
;                   ES      Function selector
;                   AL      Interval
;                   DL      Pipe #
;                   CX      Max packet size
;
;   RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    pushad
;   
    mov ah,es:usbf_speed
    call CreateEndpointRing
;
    movzx bx,dl
    add bx,bx
    inc bx
    mov fs:xp_db_target,bl
;        
    push ax
    mov fs:xp_dev_sel,es
    mov al,es:usbf_port
    mov fs:xp_port_nr,al
    mov ax,ds:xhc_port_sel
    mov fs:xp_port_sel,ax
    mov al,es:usbf_address
    mov fs:xp_slot,al
    pop ax
;
    dec bx
    add bx,bx    
    mov es:[bx].xd_ep_sel_arr,fs
; 
    mov bx,es:[bx].xd_input_ep_arr_offset
;
    mov ah,3

ciIntLoop:
    shr al,1
    jz ciIntOk
;
    inc ah
    jmp ciIntLoop

ciIntOk:    
    mov es:[bx].ec_interval,ah
    mov eax,fs:xp_ring_phys
    or al,1
    mov es:[bx].ec_tr_dequeue,eax
    mov eax,fs:xp_ring_phys+4
    mov es:[bx].ec_tr_dequeue+4,eax        
    mov es:[bx].ec_avg_len,8
    mov es:[bx].ec_packet_size,cx
    movzx ecx,cx
    mov es:[bx].ec_esit_low,ecx
;
    mov al,3 SHL 1
    or al,7 SHL 3
    mov es:[bx].ec_param2,al        
    call AddConfigEp
;
    popad
    retf32
CreateIntr  Endp

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
    push eax
    push si
;    
    mov fs:xp_size,0
    call WaitForEndpointTrb
    mov eax,es:[edi]
    mov fs:[si].trb_param,eax
    mov eax,es:[edi+4]
    mov fs:[si].trb_param+4,eax
;
    mov eax,8
    mov fs:[si].trb_status,eax    
;
    mov ax,TRB_TYPE_SETUP SHL 10
    or ax,fs:xp_ring_pcs
    or al,40h
    mov fs:[si].trb_type,ax
;
    mov fs:xp_setup_offset,si
    clc
;
    pop si
    pop eax
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
    push es
    pushad
;    
    test fs:xp_flags,XP_FLAG_DATA
    jz aoFirst
;
    mov si,fs:xp_data_last
    mov ax,fs:[si].trb_type
    and ax,NOT 20h
    or ax,10h     
    mov fs:[si].trb_type,ax
;
    add fs:xp_size,cx
    push cx
    mov bx,es
    GetSelectorBaseSize
    add edx,edi
    mov cx,flat_sel
    mov es,cx
    mov al,es:[edx]
    GetPageEntry
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
;
    call WaitForEndpointTrb
    mov fs:[si].trb_param,eax
    mov fs:[si].trb_param+4,ebx
;
    movzx eax,cx
    mov fs:[si].trb_status,eax    
    mov ax,TRB_TYPE_NORMAL SHL 10
    or ax,fs:xp_ring_pcs
    or ax,20h
    mov fs:[si].trb_type,ax
    mov fs:xp_data_last,si
    jmp aoDone

aoFirst:    
    lock or fs:xp_flags, XP_FLAG_DATA
    mov fs:xp_size,cx
    push cx
    mov bx,es
    GetSelectorBaseSize
    add edx,edi
    mov cx,flat_sel
    mov es,cx
    mov al,es:[edx]
    GetPageEntry
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
;
    call WaitForEndpointTrb
    mov fs:[si].trb_param,eax
    mov fs:[si].trb_param+4,ebx
;
    movzx eax,cx
    mov fs:[si].trb_status,eax    
;  
    mov ax,fs:xp_setup_offset
    or ax,ax
    jz aoData

aoControl:
    mov ax,TRB_TYPE_DATA SHL 10
    or ax,fs:xp_ring_pcs
    mov fs:[si].trb_type,ax
    mov fs:[si].trb_control,2
    mov fs:xp_setup_offset,0
    mov fs:xp_data_head,0
    jmp aoDone

aoData:
    mov ax,TRB_TYPE_NORMAL SHL 10
    or ax,fs:xp_ring_pcs
    or ax,20h
    mov fs:[si].trb_type,ax
    mov fs:xp_data_head,si
    mov fs:xp_data_last,si
    clc

aoDone:
    popad
    pop es
    retf32
AddOut    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddIn
;
;   DESCRIPTION:    Add in transaction to queue
;
;   PARAMETERS:     DS      Function selector
;                   FS      Pipe selector
;                   CX      Buffer size
;                   ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddIn    Proc far
    push es
    pushad
;    
    test fs:xp_flags,XP_FLAG_DATA
    jz aiFirst
;
    mov si,fs:xp_data_last
    mov ax,fs:[si].trb_type
    and ax,NOT 20h
    or ax,10h     
    mov fs:[si].trb_type,ax
;
    add fs:xp_size,cx
    push cx
    mov bx,es
    GetSelectorBaseSize
    add edx,edi
    mov cx,flat_sel
    mov es,cx
    mov al,es:[edx]
    GetPageEntry
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
;
    call WaitForEndpointTrb
    mov fs:[si].trb_param,eax
    mov fs:[si].trb_param+4,ebx
;
    movzx eax,cx
    mov fs:[si].trb_status,eax    
    mov ax,TRB_TYPE_NORMAL SHL 10
    or ax,fs:xp_ring_pcs
    or ax,20h
    mov fs:[si].trb_type,ax
    mov fs:xp_data_last,si
    jmp aiDone

aiFirst:    
    lock or fs:xp_flags, XP_FLAG_DATA
    mov fs:xp_size,cx
    push cx
    mov bx,es
    GetSelectorBaseSize
    add edx,edi
    mov cx,flat_sel
    mov es,cx
    mov al,es:[edx]
    GetPageEntry
    and ax,0F000h
    mov cx,dx
    and cx,0FFFh
    or ax,cx
    pop cx
;
    call WaitForEndpointTrb
    mov fs:[si].trb_param,eax
    mov fs:[si].trb_param+4,ebx
;
    movzx eax,cx
    mov fs:[si].trb_status,eax    
;  
    mov ax,fs:xp_setup_offset
    or ax,ax
    jz aiData

aiControl:
    mov ax,TRB_TYPE_DATA SHL 10
    or ax,fs:xp_ring_pcs
    mov fs:[si].trb_type,ax
    mov fs:[si].trb_control,3
    mov fs:xp_setup_offset,0
    mov fs:xp_data_head,0
    jmp aiDone

aiData:
    mov ax,TRB_TYPE_NORMAL SHL 10
    or ax,fs:xp_ring_pcs
    or ax,20h
    mov fs:[si].trb_type,ax
    mov fs:xp_data_head,si
    mov fs:xp_data_last,si

aiDone:    
    clc
;
    popad
    pop es
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
    push si
;    
    call WaitForEndpointTrb
    mov ax,TRB_TYPE_STATUS SHL 10
    or ax,fs:xp_ring_pcs
    or al,20h
    mov fs:[si].trb_type,ax
    clc
;
    pop si
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
    push si
;    
    call WaitForEndpointTrb
    mov ax,TRB_TYPE_STATUS SHL 10
    or ax,fs:xp_ring_pcs
    or al,20h
    mov fs:[si].trb_type,ax
    mov fs:[si].trb_control,1
    clc
;
    pop si
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
    push ds
    push eax
    push si
;
    mov fs:xp_result,-1
    test fs:xp_flags,XP_FLAG_CLOSED
    jnz itDone
;
    test fs:xp_flags,XP_FLAG_DATA
    jz itNorm
;    
    mov si,fs:xp_data_head
    or si,si
    jz itNorm
;    
    cmp si,fs:xp_data_last
    je itNorm
;
    push cx
    xor cx,cx

itCountLoop:    
    mov ax,fs:[si].trb_type
    test ax,2
    jz itCountNext
;
    mov si,fs:xp_ring_offset

itCountNext:    
    cmp si,fs:xp_data_last
    je itCountDone
;
    add si,SIZE trb_struc
    inc cx
    jmp itCountLoop

itCountDone:    
    mov si,fs:xp_data_head

itMarkLoop:    
    mov ax,fs:[si].trb_type
    test ax,2
    jz itMarkNext
;
    mov si,fs:xp_ring_offset

itMarkNext:    
    cmp si,fs:xp_data_last
    je itMarkDone
;
    movzx eax,cx
    cmp ax,15
    jbe itMarkDo
;
    mov ax,15

itMarkDo:
    shl eax,17
    or fs:[si].trb_status,eax
;       
    add si,SIZE trb_struc
    dec cx
    jmp itMarkLoop

itMarkDone:    
    pop cx

itNorm:
    mov fs:xp_result,-1
    lock or fs:xp_flags, XP_FLAG_TRANSFER_PENDING
    mov ax,fs:xp_size
    mov fs:xp_remain_size,ax
;    
    mov ds,ds:xhc_db_sel
    movzx si,fs:xp_slot
    shl si,2
    movzx eax,fs:xp_db_target
    mov ds:[si],eax

itDone:
    pop si
    pop eax
    pop ds
    retf32
IssueTransfer    Endp

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
    push si
;
    test fs:xp_flags,XP_FLAG_CLOSED
    stc
    jnz licDone
;
    movzx si,fs:xp_port_nr
    shl si,4
    mov es,fs:xp_port_sel
    mov eax,es:[si]
    test al,10h
    jnz licFail
;
    test al,1
    clc
    jnz licDone

licFail:    
    stc

licDone:
    pop si
    pop eax
    pop es
    ret
LocalIsConnected Endp

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
;       RETURNS:    NC      Transfer is done
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LocalIsTransferDone   Proc near
    push es
    push eax
    push edx
;
    test fs:xp_flags, XP_FLAG_TRANSFER_PENDING
    jz itdOk
;    
    call LocalIsConnected
    jc itdOk
;
    test fs:xp_flags, XP_FLAG_SINGLE
    jz itdNotSingle
;
    mov ax,fs:xp_ring_deque
    cmp ax,fs:xp_ring_fetch
    je itdFail
    jmp itdOk

itdNotSingle:
    mov al,fs:xp_result
    cmp al,-1
    jne itdOk

itdFail:
    stc
    jmp itdEnd   

itdOk:
    clc

itdEnd:    
    pop edx
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
;       RETURNS:    NC      Transfer is done
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
    test fs:xp_flags, XP_FLAG_TRANSFER_PENDING
    jz wfcDone

wfcWait:
    call LocalIsTransferDone
    jnc wfcDone
;
    WaitForSignal
    jmp wfcWait

wfcDone:
    call LocalEndTransfer
;    
    pop eax
    retf32
WaitForCompletion   Endp

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
    lock and fs:xp_flags, NOT (XP_FLAG_TRANSFER_PENDING OR XP_FLAG_DATA)
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
    clc
    retf32
EndTransfer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WasTransferOk
;
;           DESCRIPTION:    Was transfer ok
;
;       PARAMETERS:     DS      Function selector
;               FS      Pipe selector
;
;       RETURNS:    NC      Transfer ok
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WasTransferOk   Proc far
    push ax
;
    test fs:xp_flags, XP_FLAG_TRANSFER_PENDING
    jz wtoNotPending
;    
    call LocalEndTransfer

wtoNotPending:
    mov al,fs:xp_result
    cmp al,1
    je wtoOk
;
    cmp al,0Dh
    je wtoOk    
;
    stc
    jmp wtoDone

wtoOk:
    clc

wtoDone:
    pop ax    
    retf32
WasTransferOk   Endp

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
    cmp fs:xp_result,1
    je gdsOk
;
    cmp fs:xp_result,0Dh
    jne gdsDone    
    
gdsOk:
    mov cx,fs:xp_size
    sub cx,fs:xp_remain_size

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
    mov fs:xp_result,-1
    lock or fs:xp_flags,XP_FLAG_CLOSED
;    
    mov al,fs:xp_db_target
    cmp al,1
    je cpStopped
;    
    call StopEndpoint

cpStopped:    
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    FreeMem
;    
    clc
    retf32
ClosePipe   Endp

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
    push si
;
    movzx si,fs:xp_port_nr
    shl si,4
    mov es,fs:xp_port_sel
    mov eax,es:[si]
    test al,1
    clc
    jnz icDone
;    
    stc

icDone:
    pop si
    pop eax
    pop es
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
    push bx
    push cx
;    
    mov cl,fs:xp_port_nr
    mov eax,1
    shl eax,cl
    lock or ds:xhc_reset,eax
;
    mov bx,ds:xhc_port_thread
    Signal  
;
    pop cx
    pop bx
    pop ax
    pop es
    retf32
ResetPipe Endp

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
    clc
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
;       RETURNS:            CY      Stalled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsStalled   Proc far
    int 3
    stc
    retf32
IsStalled Endp

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
;       RETURNS:            CY      Stalled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearStalled   Proc far
    int 3
    stc
    retf32
ClearStalled Endp

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
    int 3
    stc
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
    push es
    push gs
    push eax
    push ebx
    push ecx
    push edi
;
    mov es,fs:xp_dev_sel
    mov bx,es:xd_input_ep_arr_offset
    mov es:[bx].ec_avg_len,ax
    mov es:[bx].ec_packet_size,ax
    call WaitForCommandTrb
;    
    mov bx,es:xd_input_context_offset
    mov es:[bx].icc_add_mask,2
    movzx eax,bx
    add eax,es:xd_phys
    mov gs:[edi].trb_param,eax
    mov eax,es:xd_phys+4
    mov gs:[edi].trb_param+4,eax
;
    mov ah,fs:xp_slot
    xor al,al
    mov gs:[edi].trb_control,ax
;
    mov al,TRB_TYPE_EVALUATE
    call SendCommandTrb
;
    mov bx,es:xd_input_context_offset
    mov es:[bx].icc_add_mask,0
;
    mov al,gs:[edi+100Bh]
    cmp al,1
    stc
    jne smlDone
;
    mov al,gs:[edi+100Fh]
    clc        

smlDone:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop gs    
    pop es
    retf32
SetMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseControlPipe
;
;           DESCRIPTION:    Close control pipe
;
;       PARAMETERS:         DS      Function selector
;                           FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseControlPipe   Proc far
    push es
    push ax
    push bx
    push cx
;    
    mov cl,fs:xp_port_nr
    mov eax,1
    shl eax,cl
    lock or ds:xhc_reset,eax
;
    mov bx,ds:xhc_port_thread
    Signal  
;
    mov ax,250
    WaitMilliSec
;
    pop cx
    pop bx
    pop ax
    pop es
    retf32
CloseControlPipe Endp

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
    push ds
    push eax
    push cx
    push si
;
    test fs:xp_flags,XP_FLAG_DATA
    jz ioDone
;
    mov si,fs:xp_ring_fetch
    or si,si
    jz letFetchInit
;
    add si,SIZE trb_struc
;
    mov ax,fs:[si].trb_type
    test ax,2
    jz letFetchSave
;
    mov si,fs:xp_ring_offset

letFetchSave:
    mov fs:xp_ring_fetch,si
    jmp letFetchOk

letFetchInit:
    mov si,fs:xp_ring_offset
    mov fs:xp_ring_fetch,si

letFetchOk:
    mov si,fs:xp_data_head

ioMarkLoop:    
    mov ax,fs:[si].trb_type
    test ax,2
    jz ioMarkNext
;
    mov si,fs:xp_ring_offset

ioMarkNext:    
    and ax,NOT 10h
    or ax,20h     
    mov fs:[si].trb_type,ax
;
    cmp si,fs:xp_data_last
    je ioMarkDone
;
    add si,SIZE trb_struc
    jmp ioMarkLoop

ioMarkDone:
    lock or fs:xp_flags, XP_FLAG_TRANSFER_PENDING OR XP_FLAG_SINGLE
;    
    mov ds,ds:xhc_db_sel
    movzx si,fs:xp_slot
    shl si,2
    movzx eax,fs:xp_db_target
    mov ds:[si],eax

ioDone:
    pop si
    pop cx
    pop eax
    pop ds
    retf32
IssueOne   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateAddress
;
;       DESCRIPTION:    Allocate address (slot)
;
;       PARAMETERS:     DS        Function sel
;
;       RETURNS:        AL        Address (slot #)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateAddress   Proc far
    call EnableSlot
    retf32   
AllocateAddress	  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeAddress
;
;       DESCRIPTION:    Free address (slot)
;
;       PARAMETERS:     DS        Function sel
;                       AL        Address (slot #)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeAddress   Proc far
    call DisableSlot
    retf32   
FreeAddress	  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateDev
;
;       DESCRIPTION:    Create device sel
;
;       PARAMETERS:     DS        Function sel
;                       AL        Address (slot #)
;                       AH        Speed
;                       BX        Hub sel
;                       DX        Port #
;
;       RETURNS:        ES        Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDev   Proc far
    push fs
    pushad
;
    push ax
    mov al,ah
    call AllocateDevice
    pop ax
;
    push bx
    push dx
;
    movzx bx,al
    shl bx,1
    mov ds:[bx].xhc_func_sel_arr,es
;
    movzx bx,dl    
    mov ds:[bx].xhc_port_slot_arr,al
;
    mov bx,xhci_device_ptr_sel
    mov fs,bx
    movzx bx,al
    shl bx,3
    movzx edx,es:xd_output_context_offset
    add edx,es:xd_phys
    mov fs:[bx],edx
    mov edx,es:xd_phys+4
    mov fs:[bx+4],edx
;
    pop dx
    pop bx
;
    InitUsbDev
;
    popad
    pop fs
    retf32   
CreateDev	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AttachThread
;
;   DESCRIPTION:    Attach thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..EHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

attach_thread_name  DB 'XHCI Attach', 0

attach_thread:
    mov cl,dl
    mov ds,bx
    mov es,ds:xhc_port_sel
;    
    mov eax,1
    shl eax,cl
    lock or ds:xhc_attach_pend,eax
;    
    movzx si,cl
    shl si,4
;    
    movzx edi,cl
    add edi,edi    
    push edi
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[edi].usb_attach_thread_arr,ax
    LeaveSection ds:usb_section
;    
    LockUsb
    mov eax,es:[si]
    test al,1
    jz atUnlock
;
    and eax,0EE03E1h
    or al,10h
    mov es:[si],eax

atCheckResetLoop:
    mov eax,es:[si]
    test al,1
    jz atUnlock
;
    test al,10h
    jz atResetDone    
;
    mov ax,25
    WaitMilliSec
    jmp atCheckResetLoop    

atResetDone:
    mov ax,25
    WaitMilliSec
;
    mov bx,ds:xhc_port_thread
    Signal
;    
    call fword ptr ds:allocate_address_proc
    jc atUnlock

    mov bl,al
    mov dx,100

atSlotLoop:
    mov eax,es:[si]
    call PortToSpeed
    cmp al,-1
    jne atSlotAlloc
;
    sub dx,1
    jz atUnlock
;
    mov ax,25
    WaitMilliSec
    jmp atSlotLoop    

atSlotAlloc:
    mov ah,al
    mov al,bl
    xor bx,bx
    movzx dx,cl
    call fword ptr ds:create_dev_proc
    jc atUnlock
;
    mov ax,25
    WaitMilliSec
;
    mov al,cl
    NotifyUsbAttach
    jnc atDone
;
    mov bx,ds:xhc_port_thread
    Signal
;    
    push ecx
    movzx bx,cl    
    mov al,ds:[bx].xhc_port_slot_arr
    movzx bx,al
    shl bx,1
    xor ax,ax
    xchg ax,ds:[bx].xhc_func_sel_arr
    mov bx,ax
    GetSelectorBaseSize    
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
;
    mov al,cl
    NotifyUsbDetach
;
    movzx bx,cl    
    mov al,ds:[bx].xhc_port_slot_arr
    call DisableSlot
;
    mov es,ds:xhc_port_sel
    mov eax,es:[si]
    and eax,0EE03E1h
    or al,10h
    mov es:[si],eax
    jmp atDone

atUnlock:
    UnlockUsb

atDone:
    mov eax,1
    shl eax,cl
    not eax
    lock and ds:xhc_attach_pend,eax
;
    pop edi
    EnterSection ds:usb_section
    mov ds:[edi].usb_attach_thread_arr,0
    LeaveSection ds:usb_section

    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           DetachThread
;
;   DESCRIPTION:    Detach thread
;
;   PARAMETERS:     BX      Function selector
;                   DL      Port # (0..EHCI ports)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

detach_thread_name  DB 'XHCI Detach', 0

detach_thread:
    mov cl,dl
    mov ds,bx
    mov es,ds:xhc_port_sel
;    
    mov eax,1
    shl eax,cl
    lock or ds:xhc_detach_pend,eax
;    
    movzx si,cl
    shl si,4
;    
    movzx edi,cl
    add edi,edi    
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[edi].usb_detach_thread_arr,ax
    LeaveSection ds:usb_section
;    
    mov bx,ds:xhc_port_thread
    Signal
;    
    push ecx
    movzx bx,cl    
    mov al,ds:[bx].xhc_port_slot_arr
    movzx bx,al
    shl bx,1
    xor ax,ax
    xchg ax,ds:[bx].xhc_func_sel_arr
    mov bx,ax
    GetSelectorBaseSize    
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
;    
    push edi
    mov al,cl
    NotifyUsbDetach
    pop edi
;
    movzx bx,cl    
    mov al,ds:[bx].xhc_port_slot_arr
    call DisableSlot
;
    mov eax,1
    shl eax,cl
    not eax
    lock and ds:xhc_detach_pend,eax
;    
    EnterSection ds:usb_section
    mov ds:[edi].usb_detach_thread_arr,0
    LeaveSection ds:usb_section    
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

reset_thread_name  DB 'XHCI Reset', 0

reset_thread:
    mov cl,dl
    mov ds,bx
    mov es,ds:xhc_port_sel
;    
    mov eax,1
    shl eax,cl
    lock or ds:xhc_reset_pend,eax
;        
    movzx si,cl
    shl si,4
    movzx edi,cl
    add edi,edi
;
    movzx edi,cl
    add edi,edi    
    push edi
;    
    EnterSection ds:usb_section    
    GetThread
    mov ds:[edi].usb_reset_thread_arr,ax
    LeaveSection ds:usb_section
;    
    mov bx,ds:xhc_port_thread
    Signal
;    
    push ecx
    movzx bx,cl    
    mov al,ds:[bx].xhc_port_slot_arr
    movzx bx,al
    shl bx,1
    xor ax,ax
    xchg ax,ds:[bx].xhc_func_sel_arr
    mov bx,ax
    GetSelectorBaseSize    
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
;    
    push edi
    mov al,cl
    NotifyUsbDetach
    pop edi
;
    movzx bx,cl    
    mov al,ds:[bx].xhc_port_slot_arr
    call DisableSlot
;    
    LockUsb
    mov eax,es:[si]
    test al,1
    jz rtUnlock
;
    and eax,0EE03E1h
    or al,10h
    mov es:[si],eax

rtCheckResetLoop:
    mov eax,es:[si]
    test al,1
    jz rtUnlock
;
    test al,10h
    jz rtResetDone    
;
    mov ax,25
    WaitMilliSec
    jmp rtCheckResetLoop    

rtResetDone:
    mov ax,25
    WaitMilliSec
;
    mov bx,ds:xhc_port_thread
    Signal
;    
    call fword ptr ds:allocate_address_proc
    jc rtUnlock
;
    mov bl,al
    mov dx,100

rtSlotLoop:
    mov eax,es:[si]
    call PortToSpeed
    cmp al,-1
    jne rtSlotAlloc
;
    sub dx,1
    jz rtUnlock
;
    mov ax,25
    WaitMilliSec
    jmp rtSlotLoop    

rtSlotAlloc:
    mov ah,al
    mov al,bl
    xor bx,bx
    movzx dx,cl
    call fword ptr ds:create_dev_proc
    jc rtUnlock
;
    mov ax,25
    WaitMilliSec
;
    mov al,cl
    NotifyUsbAttach
    jnc rtDone
;
    mov bx,ds:xhc_port_thread
    Signal
;    
    push ecx
    movzx bx,cl    
    mov al,ds:[bx].xhc_port_slot_arr
    movzx bx,al
    shl bx,1
    xor ax,ax
    xchg ax,ds:[bx].xhc_func_sel_arr
    mov bx,ax
    GetSelectorBaseSize    
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
;
    mov al,cl
    NotifyUsbDetach
;
    movzx bx,cl    
    mov al,ds:[bx].xhc_port_slot_arr
    call DisableSlot
;
    mov es,ds:xhc_port_sel
    mov eax,es:[si]
    and eax,0EE03E1h
    or al,10h
    mov es:[si],eax
    jmp rtDone

rtUnlock:
    UnlockUsb

rtDone:
    mov eax,1
    shl eax,cl
    not eax
    lock and ds:xhc_reset_pend,eax
;
    pop edi
    EnterSection ds:usb_section
    mov ds:[edi].usb_reset_thread_arr,0
    LeaveSection ds:usb_section
;    
    TerminateThread
        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           XhciInt
;
;           DESCRIPTION:    XHCI interrupt
;
;       PARAMETERS:     DS      Function selector
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

XhciInt Proc far 
    mov bx,ds:xhc_event_thread
    Signal
    retf32
XhciInt Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           error_event
;
;       DESCRIPTION:    Invalid event
;
;       PARAMETERS:     ES     Function sel
;                       DS:SI  Event TRB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error_event Proc near
    int 3
    ret
error_event Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           command_event
;
;       DESCRIPTION:    Command event
;
;       PARAMETERS:     ES     Function sel
;                       DS:SI  Event TRB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

command_event Proc near
    mov di,ds:[si]
    and di,0FF0h
    mov fs,es:xhc_cmd_ring_sel
    add di,1000h
;
    mov eax,ds:[si+8]
    mov fs:[di+8],eax
    mov eax,ds:[si+12]
    mov fs:[di+12],eax
;        
    xor bx,bx
    xchg bx,fs:[di].cmd_thread
    Signal
    ret
command_event Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           port_event
;
;       DESCRIPTION:    Port status change event
;
;       PARAMETERS:     ES     Function sel
;                       DS:SI  Event TRB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_event Proc near
    mov cl,ds:[si+3]
    or cl,cl
    jz peDone
;
    dec cl
    cmp cl,es:xhc_port_count
    jae peDone
;    
    mov eax,1
    shl eax,cl
    lock or es:xhc_port_change_mask,eax
;    
    movzx di,cl
    shl di,4
    mov fs,es:xhc_port_sel
;
    mov eax,fs:[di]
    and eax,0EE03E1h
    mov fs:[di],eax
;
    mov bx,es:xhc_port_thread
    Signal

peDone:
    ret
port_event Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           transfer_event
;
;       DESCRIPTION:    Transfer event
;
;       PARAMETERS:     ES     Function sel
;                       DS:SI  Event TRB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

transfer_event Proc near
    mov al,ds:[si+0Fh]
    movzx bx,al
    shl bx,1
    mov ax,es:[bx].xhc_func_sel_arr
    or ax,ax
    jz teDone
;
    mov fs,ax
    mov al,ds:[si+0Eh]
    movzx bx,al
    dec bx
    shl bx,1
    mov ax,fs:[bx].xd_ep_sel_arr
    or ax,ax
    jz teDone
;
    mov fs,ax
    mov ax,ds:[si+8]
    mov fs:xp_remain_size,ax
    mov al,ds:[si+0Bh]
    mov fs:xp_result,al
;
    mov eax,ds:[si]
    mov edx,ds:[si+4]
    sub eax,fs:xp_ring_phys
    sbb edx,fs:xp_ring_phys+4
    or edx,edx
    jnz teDequeDone
;
    cmp eax,1000h
    jae teDequeDone
;
    add ax,fs:xp_ring_offset
    mov di,ax
    add di,SIZE trb_struc
    mov ax,fs:[di].trb_type
    test ax,2
    jz teSaveDeque
;
    mov di,fs:xp_ring_offset

teSaveDeque:
    mov fs:xp_ring_deque,di

teDequeDone:
    mov bx,fs:usbp_signal
    or bx,bx
    jz teSignalDone
;
    Signal

teSignalDone:
    mov bx,fs:usbp_wait
    or bx,bx
    jz teDone
;
    push es
    mov es,bx
    SignalWait
    pop es

teDone:    
    ret
transfer_event Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Event table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EventTab:
evt00 DW OFFSET error_event
evt01 DW OFFSET error_event
evt02 DW OFFSET error_event
evt03 DW OFFSET error_event
evt04 DW OFFSET error_event
evt05 DW OFFSET error_event
evt06 DW OFFSET error_event
evt07 DW OFFSET error_event
evt08 DW OFFSET error_event
evt09 DW OFFSET error_event
evt0A DW OFFSET error_event
evt0B DW OFFSET error_event
evt0C DW OFFSET error_event
evt0D DW OFFSET error_event
evt0E DW OFFSET error_event
evt0F DW OFFSET error_event
evt10 DW OFFSET error_event
evt11 DW OFFSET error_event
evt12 DW OFFSET error_event
evt13 DW OFFSET error_event
evt14 DW OFFSET error_event
evt15 DW OFFSET error_event
evt16 DW OFFSET error_event
evt17 DW OFFSET error_event
evt18 DW OFFSET error_event
evt19 DW OFFSET error_event
evt1A DW OFFSET error_event
evt1B DW OFFSET error_event
evt1C DW OFFSET error_event
evt1D DW OFFSET error_event
evt1E DW OFFSET error_event
evt1F DW OFFSET error_event
evt20 DW OFFSET transfer_event
evt21 DW OFFSET command_event
evt22 DW OFFSET port_event
evt23 DW OFFSET error_event
evt24 DW OFFSET error_event
evt25 DW OFFSET error_event
evt26 DW OFFSET error_event
evt27 DW OFFSET error_event
evt28 DW OFFSET error_event
evt29 DW OFFSET error_event
evt2A DW OFFSET error_event
evt2B DW OFFSET error_event
evt2C DW OFFSET error_event
evt2D DW OFFSET error_event
evt2E DW OFFSET error_event
evt2F DW OFFSET error_event
evt30 DW OFFSET error_event
evt31 DW OFFSET error_event
evt32 DW OFFSET error_event
evt33 DW OFFSET error_event
evt34 DW OFFSET error_event
evt35 DW OFFSET error_event
evt36 DW OFFSET error_event
evt37 DW OFFSET error_event
evt38 DW OFFSET error_event
evt39 DW OFFSET error_event
evt3A DW OFFSET error_event
evt3B DW OFFSET error_event
evt3C DW OFFSET error_event
evt3D DW OFFSET error_event
evt3E DW OFFSET error_event
evt3F DW OFFSET error_event

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           EventThread
;
;           DESCRIPTION:    Event thread
;
;       PARAMETERS:         BX  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event_thread_name   DB 'XHCI Event', 0

event_thread:
    AddThreadInt
    mov es,bx
    GetThread
    mov es:xhc_event_thread,ax
;
    mov ds,es:xhc_event_ring_sel
    mov gs,es:xhc_rts_sel
    mov es:xhc_event_ccs,1
    xor si,si

etWait:
    WaitForSignal

etNext:    
    mov eax,ds:[si+12]
    mov dx,es:xhc_event_ccs
    and al,1
    xor dl,al
    jnz etDeq
;
    shr ax,10
    and ax,3Fh
    mov bx,ax
    shl bx,1    
    call cs:[bx].EventTab
;    
    add si,16
    cmp si,1000h
    jne etNext
;
    xor es:xhc_event_ccs,1
    xor si,si 
    jmp etNext

etDeq:
    mov eax,es:xhc_edqe
    mov ebx,es:xhc_edqe+4
    or ax,si
    or al,8
    mov gs:rrsDequeue,eax
    mov gs:rrsDequeue+4,ebx    
    jmp etWait

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateEventThread
;
;           DESCRIPTION:    Create event thread
;
;       PARAMETERS:         ES  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEventThread   Proc near
    push ds
    push es
    pushad
;
    mov bx,es
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET event_thread_name
    mov si,OFFSET event_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    popad    
    pop es
    pop ds
    ret
CreateEventThread   Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UpdatePort
;
;           DESCRIPTION:    Update port
;
;       PARAMETERS:         ES  Function sel
;                           CL  Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort  Proc near
    push ds
    push es
    push fs
    push gs
    pushad
;        
    mov ax,ds
    mov fs,ax
;
    movzx si,cl
    shl si,4
    movzx edi,cl
    add edi,edi
;    
    mov eax,1
    shl eax,cl
    test eax,es:xhc_reset
    jz upNoReset
;
    not eax
    lock and es:xhc_reset,eax
;        
    mov eax,ds:[si]
    test al,2
    jz upNoReset
;
    mov bx,es:[edi].usb_port_arr
    or bx,bx
    jz upNoReset
;
    mov gs,bx
    mov bx,gs:usb_function_sel
    or bx,bx
    jz upNoReset
;    
    mov ax,es
    mov ds,ax
;    
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_reset_thread_arr,-1
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov bx,ds
    mov dx,cx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET reset_thread_name
    mov esi,OFFSET reset_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
    jmp upDone

upNoReset:
    mov eax,ds:[si]
    test al,2
    jnz upAttach
;
    test al,1
    jz upDetach
;
    or ax,10h
    mov ds:[si],eax
    jmp upDone

upAttach:
    mov ax,es
    mov ds,ax
;
    mov bx,ds:[edi].usb_port_arr
    or bx,bx
    jz upCheckAttach
;
    mov gs,bx
    mov bx,gs:usb_function_sel
    or bx,bx
    jnz upCheckTimeout

upCheckAttach:
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_attach_thread_arr,-1
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov bx,ds
    mov dx,cx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET attach_thread_name
    mov esi,OFFSET attach_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
    jmp upDone

upDetach:
    mov ax,es
    mov ds,ax
;
    mov bx,ds:[edi].usb_port_arr
    or bx,bx
    jz upCheckTimeout
;
    mov gs,bx
    mov bx,gs:usb_function_sel
    or bx,bx
    jz upCheckTimeout
;    
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jnz upCheckTimeout
;
    mov ds:[edi].usb_detach_thread_arr,-1    
    mov ds:[edi].usb_retry_arr,0
    GetSystemTime
    add eax,1193 * 2500
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;    
    mov bx,ds
    mov dx,cx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET detach_thread_name
    mov esi,OFFSET detach_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
    jmp upDone

upCheckTimeout:
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,ds:[edi].usb_detach_thread_arr
    or bx,ds:[edi].usb_reset_thread_arr
    jz upDone
;
    GetSystemTime
    sub eax,ds:[4*edi].usb_timeout_arr
    sbb edx,ds:[4*edi].usb_timeout_arr+4
    jc upDone
;
    mov ax,ds:[edi].usb_retry_arr
    inc ax
    mov ds:[edi].usb_retry_arr,ax
;
    cmp ax,200
    jb upNotFatal
;
    int 3

upNotFatal:
    test ax,0Fh
    jnz upDoSignal
;   
    mov eax,fs:[si]
    and eax,0EE03E1h
    or al,10h
    mov fs:[si],eax

upDoSignal:
    GetSystemTime
    add eax,1193 * 400
    adc edx,0
    mov ds:[4*edi].usb_timeout_arr,eax
    mov ds:[4*edi].usb_timeout_arr+4,edx
;
    EnterSection ds:usb_section
    mov bx,ds:[edi].usb_attach_thread_arr
    or bx,bx
    jz upCheckDetach
;
    Signal
    jmp upLeave

upCheckDetach:    
    mov bx,ds:[edi].usb_detach_thread_arr
    or bx,bx
    jz upCheckReset
;
    Signal
    jmp upLeave
            
upCheckReset:    
    mov bx,ds:[edi].usb_reset_thread_arr
    or bx,bx
    jz upLeave
;
    Signal

upLeave:
    LeaveSection ds:usb_section

upDone:
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ret        
UpdatePort  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetPortPower
;
;           DESCRIPTION:    Turn on power on port
;
;       PARAMETERS:         ES  Function sel
;                           CL  Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPortPower  Proc near
    push eax
    push si
;        
    movzx si,cl
    shl si,4
;    
    mov eax,ds:[si]
    and eax,0EE03E1h
    or ax,200h
    mov ds:[si],eax
;
    pop si
    pop eax
    ret
SetPortPower    Endp
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PortThread
;
;           DESCRIPTION:    Port thread
;
;       PARAMETERS:         BX  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_thread_name   DB 'XHCI Port', 0

port_thread:
    mov es,bx
    GetThread
;        
    mov es:xhc_port_thread,ax
    mov es:xhc_reset,0
    mov es:xhc_attach_pend,0
    mov es:xhc_detach_pend,0
    mov es:xhc_reset_pend,0
    mov ds,es:xhc_port_sel
;
    xor cl,cl

ptPowerLoop:    
    push cx
    call SetPortPower
    pop cx

ptPowerNext:
    inc cl
    cmp cl,es:xhc_port_count
    jb ptPowerLoop
;
    mov ax,750
    WaitMilliSec
    
ptLoop:
    WaitForSignal

ptRetry:    
    xor eax,eax
    xchg eax,es:xhc_port_change_mask
    or eax,es:xhc_reset
    or eax,es:xhc_attach_pend
    or eax,es:xhc_detach_pend
    or eax,es:xhc_reset_pend
    jz ptLoop
;
    xor cl,cl

ptPortLoop:    
    test al,1
    jz ptPortNext
;
    push eax
    push cx
    call UpdatePort
    pop cx
    pop eax 

ptPortNext:
    inc cl
    shr eax,1
    jnz ptPortLoop   
;    
    mov eax,es:xhc_attach_pend
    or eax,es:xhc_detach_pend
    or eax,es:xhc_reset_pend
    jz ptLoop    
;
    mov ax,25
    WaitMilliSec
    jmp ptRetry    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreatePortThread
;
;           DESCRIPTION:    Create port thread
;
;       PARAMETERS:         ES  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePortThread   Proc near
    push ds
    push es
    pushad
;
    mov bx,es
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET port_thread_name
    mov si,OFFSET port_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    popad    
    pop es
    pop ds
    ret
CreatePortThread   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitFunction
;
;           DESCRIPTION:    Init EHCI function
;
;       PARAMETERS:         ES      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xhci_tab:
et00 DD OFFSET AllocateAddress,     SEG code
et01 DD OFFSET FreeAddress,         SEG code
et02 DD OFFSET CreateDev,           SEG code
et03 DD OFFSET CreateControl,       SEG code
et04 DD OFFSET CreateBulk,          SEG code
et05 DD OFFSET CreateIntr,          SEG code
et06 DD OFFSET AddSetup,            SEG code
et07 DD OFFSET AddOut,              SEG code
et08 DD OFFSET AddIn,               SEG code
et09 DD OFFSET AddStatusOut,        SEG code
et0A DD OFFSET AddStatusIn,         SEG code
et0B DD OFFSET IssueTransfer,       SEG code
et0C DD OFFSET IsTransferDone,      SEG code
et0D DD OFFSET EndTransfer,         SEG code
et0E DD OFFSET WasTransferOk,       SEG code
et0F DD OFFSET GetDataSize,         SEG code
et10 DD OFFSET ClosePipe,           SEG code
et11 DD OFFSET WaitForCompletion,   SEG code
et12 DD 0,                          0
et13 DD OFFSET IsConnected,         SEG code
et14 DD OFFSET ResetPipe,           SEG code
et15 DD OFFSET LockEnum,            SEG code
et16 DD OFFSET UnlockEnum,          SEG code
et17 DD OFFSET Has64Bit,            SEG code
et18 DD OFFSET IsStalled,           SEG code
et19 DD OFFSET ClearStalled,        SEG code
et1A DD OFFSET GetMaxLen,           SEG code
et1B DD OFFSET AddressDevice,       SEG code
et1C DD OFFSET ConfigDevice,        SEG code
et1D DD OFFSET SetMaxLen,           SEG code
et1E DD OFFSET CloseControlPipe,    SEG code
et1F DD OFFSET IssueOne,            SEG code

InitFunction    Proc near
    push es
    push fs
    pushad
;
    call CreateEventThread
    call CreatePortThread
;
    InitSection es:xhc_cmd_section
;
    mov ds,es:xhc_reg_sel
    and ds:orsUsbCmd,NOT 1

ifWaitStop:
    test ds:orsUsbSts,1
    jnz ifWaitStopped
;
    mov ax,10
    WaitMilliSec
    jmp ifWaitStop

ifWaitStopped:    
    or ds:orsUsbCmd,2

ifWaitReset:
    test ds:orsUsbCmd,2
    jz ifWaitReseted
;
    mov ax,10
    WaitMilliSec
    jmp ifWaitReset

ifWaitReseted:        
    GetPciMsi
    jc ifCheckMsiX
;
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc ifIrq    
;
    mov dl,1
    SetupPciMsi
    jmp ifReg

ifCheckMsiX:
    GetPciMsiX
    jc ifIrq
;
    push es
    EnablePciMsiX
    xor dl,dl
;
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jnc ifMsiX
;
    pop es
    jc ifIrq

ifMsiX:    
    SetupPciMsiXEntry
    pop es
    jmp ifReg

ifReg:    
    push ds
    push es
    mov di,es
    mov ds,di
    mov di,cs
    mov es,di
    mov edi,OFFSET XhciInt
    RequestMsiHandler
    pop es
    pop ds
    jmp ifIntDone

ifIrq:
    push es
    GetPciIrqNr
    mov ah,14h
    mov di,es
    mov ds,di
    mov di,cs
    mov es,di
    mov edi,OFFSET XhciInt
    RequestIrqHandler
    pop es

ifIntDone:    
    movzx eax,es:xhc_slot_count
    mov ds:orsConfig,eax
;
    push es
    movzx cx,es:xhc_slot_count
    mov es,es:xhc_device_ptr_sel
    xor di,di
    shl cx,1
    xor eax,eax
    rep stosd
    pop es
;    
    mov eax,es:xhc_dcba
    mov ds:orsDcbaap,eax
    mov eax,es:xhc_dcba+4
    mov ds:orsDcbaap+4,eax
;    
    call CreateScratchPad
;
    mov eax,es:xhc_crcr
    or al,1
    mov ds:orsCrCtrl,eax
    mov eax,es:xhc_crcr+4
    mov ds:orsCrCtrl+4,eax
;
    mov ds,es:xhc_rts_sel
;    
    mov eax,es:xhc_edqe
    mov ebx,es:xhc_edqe+4
    mov ds:rrsDequeue,eax
    mov ds:rrsDequeue+4,ebx    
;    
    mov eax,es:xhc_erst
    mov ebx,es:xhc_erst+4
    mov ds:rrsBase,eax
    mov ds:rrsBase+4,ebx    
;    
    mov ds:rrsRingSize,1
;
    mov ds:rrsImod,400
    mov ds:rrsIman,3
;    
    mov ds,es:xhc_reg_sel
    or ds:orsUsbCmd,4    
;
    or ds:orsUsbCmd,1
;    
    mov si,OFFSET xhci_tab
    xor di,di
    mov cx,2*20h

ifTabLoop:
    lods dword ptr cs:[si]
    stosd
    loop ifTabLoop    
;
    mov ax,es
    mov ds,ax
    InitUsbFunction

ifDone:
    popad
    pop fs
    pop es
    ret
InitFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           BiosHandoff
;
;       DESCRIPTION:    Do BIOS handoff
;
;       PARAMETERS:     EDX     HCC linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BiosHandoff Proc near
    push ds
    push eax
    push ebx
    push ebp
;    
    mov ax,flat_sel
    mov ds,ax
    mov ebx,ds:[edx].hccCap1
    shr ebx,16
    or bx,bx
    jz bhDone
;
    shl ebx,2
    mov ebp,ebx

bhLoop:
    mov al,ds:[edx+ebx]
    cmp al,1
    jne bhNext
;
    add ebx,edx
    test ds:[ebx+2],1
    jz bhDone

bhRetry:
    or ds:[ebx+3],1
;
    mov ax,25
    WaitMilliSec
;
    test ds:[ebx+2],1
    jnz bhRetry
;
    test ds:[ebx+3],1
    jz bhRetry
    jmp bhDone

bhNext:
    mov al,ds:[edx+ebx+1]
    or al,al
    jz bhDone
;
    movzx ebx,al
    shl ebx,2
    add ebx,ebp
    jmp bhLoop
    
bhDone:    
    pop ebp
    pop ebx
    pop eax
    pop ds
    ret
BiosHandoff Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreatePrimaryFunction
;
;       DESCRIPTION:    Create primary XHCI function
;
;       PARAMETERS:     EDX:EAX Register base
;
;       RETURNS:        NC      OK
;                           ES  Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePrimaryFunction  Proc near
    push ds
    pushad
;
    push edx
    push eax
;    
    mov ebx,edx
    push eax
    mov eax,10000h
    AllocateBigLinear
    pop eax
;
    push eax
    push edx
    mov ecx,10h
    and ax,0F000h
    or ax,813h

cpfDevLoop:
    SetPageEntry
;
    add edx,1000h
    add eax,1000h
    loop cpfDevLoop
;
    pop edx
    pop eax
    and eax,0FFFh
    or edx,eax
;
    mov ecx,10000h
    mov bx,xhci_hcc_sel
    CreateDataSelector16
    mov ds,bx
;
    mov eax,ds:hccCap1
    test al,1
    jnz cpf64Ok
;
    HasPhysical64
    jnc cpfFail

cpf64Ok:        
    call BiosHandoff
;    
    mov eax,SIZE xhci_func_sel
    mov cx,ax
    AllocateSmallGlobalMem
    xor di,di
    xor al,al
    rep stosb
;
    mov al,ds:[4]
    mov es:xhc_slot_count,al
;
    mov al,ds:[7]
    cmp al,20h
    jb cpfPortsOk
;
    mov al,20h

cpfPortsOk:    
    mov es:xhc_port_count,al
    mov es:xhc_port_change_mask,0
;
    mov cx,20h
    mov eax,ds:hccCap1
    test al,4
    jz cpfContextSizeOk
;
    mov cx,40h

cpfContextSizeOk:
    mov es:xhc_context_size,cx    
;
    mov es:xhc_hcc_sel,ds
;    
    mov al,ds:[0]
    movzx eax,al
    add edx,eax
    mov cx,40h
    mov bx,xhci_reg_sel
    CreateDataSelector16
    mov es:xhc_reg_sel,bx        
;
    pop eax
    pop ebx
;
    push ebx
    push eax
;
    mov cl,ds:[0]
    movzx ecx,cl
    add ecx,400h
    add eax,ecx
    adc ebx,0
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    push eax
    and ax,0F000h
    or ax,813h
    SetPageEntry
    pop eax
    and eax,0FFFh
    or edx,eax
;
    mov bx,xhci_port_sel
    movzx ecx,es:xhc_port_count
    shl ecx,4
    CreateDataSelector16
    mov es:xhc_port_sel,bx
;
    pop eax
    pop ebx
;
    push ebx
    push eax
;    
    mov ecx,ds:hccDbOff
    and cl,0FCh
    add eax,ecx
    adc ebx,0
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    push eax
    and ax,0F000h
    or ax,813h
    SetPageEntry
    pop eax
    and eax,0FFFh
    or edx,eax
;
    mov bx,xhci_db_sel
    movzx ecx,es:xhc_slot_count
    shl ecx,2
    CreateDataSelector16
    mov es:xhc_db_sel,bx
;
    pop eax
    pop ebx
;
    mov ecx,ds:hccRtsOff
    and cl,0FCh
    add eax,ecx
    adc ebx,0
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    push eax
    and ax,0F000h
    or ax,813h
    SetPageEntry
    pop eax
    and eax,0FFFh
    or edx,eax
;
    mov bx,xhci_rts_sel
    mov ecx,40h
    CreateDataSelector16
    mov es:xhc_rts_sel,bx        
;
    AllocatePhysical64
    mov es:xhc_dcba,eax
    mov es:xhc_dcba+4,ebx
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    mov al,13h
    SetPageEntry
;
    mov bx,xhci_device_ptr_sel
    movzx ecx,es:xhc_slot_count
    shl ecx,3
    CreateDataSelector16
    mov es:xhc_device_ptr_sel,bx
;
    call CreateCommandRing   
    mov bx,xhci_cmd_ring_sel
    mov ecx,2000h
    CreateDataSelector16
    mov es:xhc_cmd_ring_sel,bx
;
    call CreateEventRing
    mov bx,xhci_event_ring_sel
    mov ecx,1000h
    CreateDataSelector16
    mov es:xhc_event_ring_sel,bx    
    clc
    jmp cpfDone

cpfFail:    
    pop eax
    pop edx
    stc

cpfDone:
    popad
    pop ds
    ret
CreatePrimaryFunction Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateSecondaryFunction
;
;       DESCRIPTION:    Create secondary XHCI function
;
;       PARAMETERS:     EDX:EAX Register base
;
;       RETURNS:        NC      OK
;                           ES  Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSecondaryFunction  Proc near
    push ds
    pushad
;
    push edx
    push eax
;    
    mov ebx,edx
    push eax
    mov eax,10000h
    AllocateBigLinear
    pop eax
;
    push eax
    push edx
    mov ecx,10h
    and ax,0F000h
    or ax,813h

csfDevLoop:
    SetPageEntry
;
    add edx,1000h
    add eax,1000h
    loop csfDevLoop
;
    pop edx
    pop eax
    and eax,0FFFh
    or edx,eax
;
    AllocateGdt
    mov ecx,10000h
    CreateDataSelector16
    mov ds,bx
;
    mov eax,ds:hccCap1
    test al,1
    jnz csf64Ok
;
    HasPhysical64
    jnc csfFail

csf64Ok:        
    call BiosHandoff
    mov eax,SIZE xhci_func_sel
    mov cx,ax
    AllocateSmallGlobalMem
    xor di,di
    xor al,al
    rep stosb
;
    mov al,ds:[4]
    mov es:xhc_slot_count,al
;
    mov al,ds:[7]
    cmp al,20h
    jb csfPortsOk
;
    mov al,20h

csfPortsOk:    
    mov es:xhc_port_count,al
    mov es:xhc_port_change_mask,0
;
    mov cx,20h
    mov eax,ds:hccCap1
    test al,4
    jz csfContextSizeOk
;
    mov cx,40h

csfContextSizeOk:
    mov es:xhc_context_size,cx    
;
    mov es:xhc_hcc_sel,ds
;    
    mov al,ds:[0]
    movzx eax,al
    add edx,eax
    mov cx,40h
    AllocateGdt
    CreateDataSelector16
    mov es:xhc_reg_sel,bx        
;
    pop eax
    pop ebx
;
    push ebx
    push eax
;
    mov cl,ds:[0]
    movzx ecx,cl
    add ecx,400h
    add eax,ecx
    adc ebx,0
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    push eax
    and ax,0F000h
    or ax,813h
    SetPageEntry
    pop eax
    and eax,0FFFh
    or edx,eax
;
    AllocateGdt
    movzx ecx,es:xhc_port_count
    shl ecx,4
    CreateDataSelector16
    mov es:xhc_port_sel,bx
;
    pop eax
    pop ebx
;
    push ebx
    push eax
;
    mov ecx,ds:hccDbOff
    and cl,0FCh
    add eax,ecx
    adc ebx,0
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    push eax
    and ax,0F000h
    or ax,813h
    SetPageEntry
    pop eax
    and eax,0FFFh
    or edx,eax
;
    AllocateGdt
    movzx ecx,es:xhc_slot_count
    shl ecx,2
    CreateDataSelector16
    mov es:xhc_db_sel,bx
;
    pop eax
    pop ebx
;
    mov ecx,ds:hccRtsOff
    and cl,0FCh
    add eax,ecx
    adc ebx,0
;    
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    push eax
    and ax,0F000h
    or ax,813h
    SetPageEntry
    pop eax
    and eax,0FFFh
    or edx,eax
;
    AllocateGdt
    mov ecx,40h
    CreateDataSelector16
    mov es:xhc_rts_sel,bx        
;
    AllocatePhysical64
    mov es:xhc_dcba,eax
    mov es:xhc_dcba+4,ebx
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    mov al,13h
    SetPageEntry
;
    AllocateGdt
    movzx ecx,es:xhc_slot_count
    shl ecx,3
    CreateDataSelector16
    mov es:xhc_device_ptr_sel,bx
;
    call CreateCommandRing
    AllocateGdt
    mov ecx,2000h
    CreateDataSelector16
    mov es:xhc_cmd_ring_sel,bx
;
    call CreateEventRing
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov es:xhc_event_ring_sel,bx    
    clc
    jmp csfDone

csfFail:    
    mov bx,ds
    xor ax,ax
    mov ds,ax
    FreeGdt
    pop eax
    pop edx
    stc

csfDone:
    popad
    pop ds
    ret
CreateSecondaryFunction Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddFunction
;
;       DESCRIPTION:    Add EHCI function
;
;       PARAMETERS:     BX      PCI bus/device
;                       CH      PCI function
;                       ES      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFunction  Proc near
    call InitFunction
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
    mov ch,30h
    FindPciClass
    jc init_pci_done
;
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_busmstr
    WritePciWord
;
    mov cl,10h
    ReadPciDword
    xor edx,edx
    test al,4
    jz init_pci_base_ok
;
    push eax    
    mov cl,14h
    ReadPciDword
    mov edx,eax
    pop eax

init_pci_base_ok:
    and ax,0FFF0h
    mov ebp,eax
    call CreatePrimaryFunction
    mov dx,1
    jc init_pci_next_device
;
    call AddFunction
    
init_pci_next_device:
    mov ax,dx
    mov bh,0Ch
    mov bl,3
    mov ch,30h
    FindPciClass
    jc init_pci_done
;   
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_busmstr
    WritePciWord
;
    mov si,dx
    mov cl,10h
    ReadPciDword
    xor edx,edx
    test al,4
    jz init_pci_next_base_ok
;
    push eax    
    mov cl,14h
    ReadPciDword
    mov edx,eax
    pop eax

init_pci_next_base_ok:
    and ax,0FFF0h
    cmp eax,ebp
    je init_pci_done
;       
    call CreateSecondaryFunction
    mov dx,si
    inc dx
    jc init_pci_next_device
;
    call AddFunction
    jmp init_pci_next_device
    
init_pci_done:
    ret
InitPciAdapter  Endp

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
;
    popa
    pop es
    pop ds
    retf32
init_usb    Endp

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
    mov bx,SEG data
    mov ds,bx
;
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov edi,OFFSET init_usb
    HookInitPci
    clc
;       
    ret
Init    Endp

code ENDS

    END init
