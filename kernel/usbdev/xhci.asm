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
INCLUDE ..\os\memblk.inc
INCLUDE usbdev.inc
include hub.inc

MAX_INTR_COUNT   = 4

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

xhc_params	STRUC

par_oper_offset    DD ?
par_db_offset      DD ?
par_run_offset     DD ?
par_offset         DW ?
par_intr_count     DW ?
par_scratch_count  DW ?
par_slot_count     DB ?
par_slot_size      DB ?
par_port_count     DB ?
par_seg_count      DB ?
par_has_64         DB ?

xhc_params   ENDS

event_seg   STRUC

ev_ers        DD ?,?
ev_size       DW ?
ev_resv1      DW ?
ev_resv2      DD ?
ev_phys       DD ?,?
ev_hdr_size   DW ?
ev_thread     DW ?
ev_ccs        DW ?

event_seg   ENDS

cev_struc   STRUC

cev_thread  DW ?
cev_slot    DB ?
cev_result  DB ?

cev_struc   ENDS

CMD_OFFSET = 1000h
DEV_OFFSET = 1800h
REG_OFFSET = 2000h

xhci_func_sel   STRUC

usb_func_base           usb_function_struc <>

xhc_linear              DD ?
xhc_func_phys           DD ?,?
xhc_reg_phys            DD ?,?
xhc_cap_offset          DD ?
xhc_oper_offset         DD ?
xhc_run_offset          DD ?
xhc_db_offset           DD ?
xhc_port_offset         DD ?
xhc_intr_offset         DD ?

xhc_has_64              DB ?
xhc_int_base            DB ?

xhc_slot_count          DB ?
xhc_port_count          DB ?

xhc_crcr                DD ?,?
xhc_dcba                DD ?,?

xhc_cmd_enque           DW ?
xhc_cmd_pcs             DW ?

xhc_intr_count          DW ?
xhc_intr_arr            DW MAX_INTR_COUNT DUP(?)

xhc_port_thread         DW ?
xhc_port_change_mask    DD ?


; might not be used

xhc_hcc_sel         DW ?
xhc_reg_sel         DW ?
xhc_port_sel        DW ?
xhc_db_sel          DW ?
xhc_rts_sel         DW ?
xhc_device_ptr_sel  DW ?
xhc_cmd_ring_sel    DW ?
xhc_event_ring_sel  DW ?


xhc_context_size    DW ?
xhc_erst            DD ?,?

xhc_attach_pend     DD ?
xhc_detach_pend     DD ?

xhc_cmd_section     section_typ <>


xhc_port_slot_arr   DB 256 DUP(?)

xhc_func_sel_arr    DW 256 DUP(?)

xhci_func_sel   ENDS

xhci_dev_struc   STRUC

usb_dev_base             usb_device_struc <>

xd_device_context        DD ?
xd_dev_sel               DW ?
xd_control_trb           DW ?
xd_control_buf           DD ?
xd_control_pipe          DW ?

xd_input_context_offset  DW ?
xd_input_slot_offset     DW ?
xd_ep_size               DW ?
xd_input_ep_arr_offset   DW 32 DUP (?)

xd_ep_sel_arr            DW 32 DUP(?)

xhci_dev_struc    ENDS

xhci_pipe   STRUC

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

dump_file  DW ?
dump_buf   DB 3 DUP(?)

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
;           NAME:           AddDump
;
;           DESCRIPTION:    Create dump file
;
;           Parameters:     CS:ESI      Text
;                           ES:EDI      Data
;                           ECX         Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

my_dump_file DB 'c:/xhci.txt', 0
start_text   DB 'Start', 0dh, 0ah

AddDump Proc near
    push ds
    push es
    pushad
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:dump_file
    or bx,bx
    jnz adWrite
;
    push es
    push ecx
    push edi
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET my_dump_file
    OpenFile
    jnc adInit
;
    xor cx,cx
    CreateFile

adInit:
    mov ds:dump_file,bx
;
    GetFileSize
    SetFilePos
;
    mov ecx,7
    mov edi,OFFSET start_text
    WriteFile
;
    pop edi
    pop ecx
    pop es

adWrite:
    push es
    push ecx
    push edi
;
    mov ax,cs
    mov es,ax
    mov edi,esi
    xor ecx,ecx

adSizeLoop:
    mov al,es:[edi]
    or al,al
    jz adSizeOk
;
    inc edi
    inc ecx
    jmp adSizeLoop

adSizeOk:
    mov edi,esi
    WriteFile
;
    pop edi
    pop ecx
    pop es
;
    or ecx,ecx
    jz adCrLf

adLoop:
    mov al,es:[edi]
    mov ah,al
    and al,0F0h
    rol al,4
    cmp al,0Ah
    jb adLow1
;    
    add al,7

adLow1:
    add al,'0'
    mov ds:dump_buf,al
;
    mov al,ah
    and al,0Fh
    cmp al,0Ah
    jb adHigh1
;    
    add al,7

adHigh1:
    add al,'0'
    mov ds:dump_buf+1,al
    mov ds:dump_buf+2,' '
;
    push es
    push ecx
    push edi
;
    mov ecx,3
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET dump_buf
    WriteFile
;
    pop edi
    pop ecx
    pop es
;
    inc edi
    loop adLoop

adCrLf:
    mov ds:dump_buf,0dh
    mov ds:dump_buf+1,0ah
;
    mov ecx,2
    mov ax,SEG data
    mov es,ax
    mov edi,OFFSET dump_buf
    WriteFile
;
    popad
    pop es
    pop ds 
    ret
AddDump Endp

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
    mov bx,es:xd_input_context_offset
    mov es:[bx].icc_add_mask,0
;    
    mov ch,al
    mov bx,es:xd_input_slot_offset
    movzx eax,al
    shl eax,20
    or eax,08000000h
    mov es:[bx].s_misc,eax
    mov al,cl
    inc al
    mov es:[bx].s_root_hub,al
;
    mov dx,es:usbd_parent_hub
    or dx,dx
    jz srdDone
;
    push gs
    mov gs,dx
;
    cmp ch,3
    jae srdSpeedOk
;
    mov al,es:[bx].s_root_hub
    mov es:[bx].s_tt_port_nr,al
    mov al,gs:usb_hub_id
    mov es:[bx].s_tt_slot_id,al

srdSpeedOk:
    movzx eax,es:[bx].s_root_hub
    mov cl,gs:usb_route_depth
    shl cl,2
    shl eax,cl
    or eax,gs:usb_route_str
    and eax,0FFFFFFh
    or es:[bx].s_misc,eax
;
    mov al,gs:usb_root_port
    mov es:[bx].s_root_hub,al
;
    pop gs

srdDone:
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
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    pushad
;
    mov ah,es:usbd_speed
    call SpeedToPsi
;
    mov cl,es:usbd_port
    call SetupRootDevice
    call CreateEndpointRing
;
    push ax
    mov es:xd_control_pipe,fs
    mov fs:xp_dev_sel,es
    mov al,es:usbd_port
    mov fs:xp_port_nr,al
    mov ax,ds:xhc_port_sel
    mov fs:xp_port_sel,ax
    mov al,es:usbd_address
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

address_text DB 'Address ',0

AddressDevice   Proc far
    push es
    push gs
    pushad
;
    call WaitForCommandTrb
;    
    mov es,fs:xp_dev_sel
    mov bx,es:xd_input_context_offset
    mov es:[bx].icc_add_mask,3
    movzx eax,bx
    add eax,es:mblk_physical_base
    mov gs:[edi].trb_param,eax
    mov eax,es:mblk_physical_base+4
    mov gs:[edi].trb_param+4,eax
;
    mov ah,fs:xp_slot
    xor al,al
    mov gs:[edi].trb_control,ax
;
    mov al,TRB_TYPE_ADDRESS_DEV
    call SendCommandTrb
;
;    push esi
;    mov esi,OFFSET address_text
;    call DumpInputContext
;    pop esi
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
    popad
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
;                   CX      Hub sel
;                   DL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

config_text DB 'Config ', 0

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
    add eax,es:mblk_physical_base
    mov gs:[edi].trb_param,eax
    mov eax,es:mblk_physical_base+4
    mov gs:[edi].trb_param+4,eax
;
    mov ah,fs:xp_slot
    xor al,al
    mov gs:[edi].trb_control,ax
;
    or cx,cx
    jz cdDo
;
    push gs
;
    mov gs,ecx
    mov al,fs:xp_slot
    mov gs:usb_hub_id,al
;
    mov bx,es:xd_input_context_offset
    or es:[bx].icc_add_mask,1
;
    mov bx,es:xd_input_slot_offset
    mov eax,es:[bx].s_misc
    or eax,04000000h
    mov es:[bx].s_misc,eax
;
    mov ax,gs:hub_ports
    mov es:[bx].s_hub_ports,al
;
    mov ax,es:[bx].s_ttt_int
    or al,3
    mov es:[bx].s_ttt_int,ax
;
    pop gs

cdDo:
    mov al,TRB_TYPE_CONFIGURE_ENDP
    call SendCommandTrb
;
;    push esi
;    mov esi,OFFSET config_text
;    call DumpInputContext
;    pop esi
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
    mov ah,es:usbd_speed
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
    mov al,es:usbd_port
    mov fs:xp_port_nr,al
    mov ax,ds:xhc_port_sel
    mov fs:xp_port_sel,ax
    mov al,es:usbd_address
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
    mov ah,es:usbd_speed
    call CreateEndpointRing
;
    movzx bx,dl
    add bx,bx
    inc bx
    mov fs:xp_db_target,bl
;        
    push ax
    mov fs:xp_dev_sel,es
    mov al,es:usbd_port
    mov fs:xp_port_nr,al
    mov ax,ds:xhc_port_sel
    mov fs:xp_port_sel,ax
    mov al,es:usbd_address
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
    mov ax,fs:xp_setup_offset
    or ax,ax
    jz aoNotSetup
;
    mov si,fs:xp_data_last
    mov ax,fs:[si].trb_type
    and ax,NOT 20h
    or ax,10h     
    mov fs:[si].trb_type,ax

aoNotSetup:
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
    mov ax,fs:xp_setup_offset
    or ax,ax
    jz itNorm
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
;    IsUsbPipeConnected
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
Block  Endp

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
Unblock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ChangeAddress
;
;           DESCRIPTION:    Change address
;
;       PARAMETERS:     DS      Function selector
;                       FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    retf32
ChangeAddress  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DisablePort
;
;           DESCRIPTION:    Disable port
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisablePort   Proc far
    retf32
DisablePort Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DisableDev
;
;           DESCRIPTION:    Disable device
;
;       PARAMETERS:         DS      Function selector
;                           ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisableDev   Proc far
    push ax
    push bx
;
    movzx bx,es:usbd_port    
    mov al,ds:[bx].xhc_port_slot_arr
    call DisableSlot
;
    pop bx
    pop ax
    retf32
DisableDev Endp

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
;           NAME:           UpdateMaxLen
;
;           DESCRIPTION:    Update max len
;
;           PARAMETERS:     ES      Device selector
;                           AL      Maxlen
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMaxLen   Proc far
    push es
    push gs
    push eax
    push ebx
    push ecx
    push edi
;
    mov bx,es:xd_input_ep_arr_offset
    mov es:[bx].ec_avg_len,ax
    mov es:[bx].ec_packet_size,ax
    call WaitForCommandTrb
;    
    mov bx,es:xd_input_context_offset
    mov es:[bx].icc_add_mask,2
    movzx eax,bx
    add eax,es:mblk_physical_base
    mov gs:[edi].trb_param,eax
    mov eax,es:mblk_physical_base+4
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
;           NAME:           IsPortConnected
;
;           DESCRIPTION:    Check if port is connected
;
;       PARAMETERS:         DS      Function selector
;                           DL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsPortConnected   Proc far
    push es
    push fs
    push eax
    push si
;
    movzx si,dl
    shl si,4
    mov eax,es:[si]
    test al,1
    clc
    jnz ipcDone
;    
    stc

ipcDone:
    pop si
    pop eax
    pop fs
    pop es
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
    push es
    push fs
    push eax
    push si
;
    movzx si,es:usbd_port
    shl si,4
    mov eax,es:[si]
    test al,1
    clc
    jnz idcDone
;    
    stc

idcDone:
    pop si
    pop eax
    pop fs
    pop es
    retf32
IsDeviceConnected Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControlIn
;
;       DESCRIPTION:    Setup control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Pipe sel
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControlIn   Proc near
    pushad
;
    call WaitForEndpointTrb
    mov es:xd_control_trb,si
    mov eax,dword ptr es:usbd_control_buf
    mov fs:[si].trb_param,eax
    mov eax,dword ptr es:usbd_control_buf+4
    mov fs:[si].trb_param+4,eax
;
    mov eax,8
    mov fs:[si].trb_status,eax    
;
    mov ax,TRB_TYPE_SETUP SHL 10
    or ax,fs:xp_ring_pcs
    or al,40h
    mov fs:[si].trb_type,ax
    mov fs:[si].trb_control,0
;
    mov fs:xp_size,cx
;
    or cx,cx
    jz sciStatusOut
;
    mov fs:[si].trb_control,3
    AllocateMemBlk
    mov es:xd_control_buf,edx
;
    call WaitForEndpointTrb
    mov fs:[si].trb_param,eax
    mov fs:[si].trb_param+4,ebx
;
    movzx eax,cx
    mov fs:[si].trb_status,eax    
    mov ax,TRB_TYPE_DATA SHL 10
    or ax,fs:xp_ring_pcs
    mov fs:[si].trb_type,ax
    mov fs:[si].trb_control,1

sciStatusOut: 
    call WaitForEndpointTrb
    mov ax,TRB_TYPE_STATUS SHL 10
    or ax,fs:xp_ring_pcs
    or al,20h
    mov fs:[si].trb_type,ax
    clc

sciDone:
    popad
    ret
SetupControlIn	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CopyControlIn
;
;       DESCRIPTION:    Copy control IN
;
;       PARAMETERS:     ES      Usb device
;                       FS      Control pipe
;                       CX      Size
;                       GS:EDI  Buffer
;
;       RETURNS:        CX      Size returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyControlIn   Proc near
    push eax
;
    mov al,fs:xp_result
    or cx,cx
    jz cciNoData

cciData:
    cmp al,1
    stc 
    jne cciDone
;
    push ds
    push es
    pushad
;
    mov esi,es:xd_control_buf
    movzx ecx,fs:xp_size
    sub cx,fs:xp_remain_size
    mov ax,gs
    mov es,ax
    mov ax,flat_sel
    mov ds,ax
    rep movs byte ptr es:[edi],ds:[esi]
;
    popad
    pop es
    pop ds
;
    mov cx,fs:xp_size
    sub cx,fs:xp_remain_size
    clc
    jmp cciDone

cciNoData:
    cmp al,0Dh
    stc
    jne cciDone
;
    clc

cciDone:
    pop eax
    ret
CopyControlIn   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControlOut
;
;       DESCRIPTION:    Setup control OUT
;
;       PARAMETERS:     ES      Usb device
;                       FS      Pipe sel
;                       CX      Size
;                       GS:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControlOut   Proc near
    pushad
;
    call WaitForEndpointTrb
    mov es:xd_control_trb,si
    mov eax,dword ptr es:usbd_control_buf
    mov fs:[si].trb_param,eax
    mov eax,dword ptr es:usbd_control_buf+4
    mov fs:[si].trb_param+4,eax
;
    mov eax,8
    mov fs:[si].trb_status,eax    
;
    mov ax,TRB_TYPE_SETUP SHL 10
    or ax,fs:xp_ring_pcs
    or al,40h
    mov fs:[si].trb_type,ax
    mov fs:[si].trb_control,0
;
    mov fs:xp_size,cx
;
    or cx,cx
    jz scoStatusIn
;
    mov fs:[si].trb_control,2
    AllocateMemBlk
    mov es:xd_control_buf,edx
;
    push ds
    push es
    pushad
;
    mov esi,edi
    mov edi,es:xd_control_buf
    mov ax,gs
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
    rep movs byte ptr es:[edi],ds:[esi]
;
    popad
    pop es
    pop ds
;
    call WaitForEndpointTrb
    mov fs:[si].trb_param,eax
    mov fs:[si].trb_param+4,ebx
;
    movzx eax,cx
    mov fs:[si].trb_status,eax    
    mov ax,TRB_TYPE_DATA SHL 10
    or ax,fs:xp_ring_pcs
    mov fs:[si].trb_type,ax
    mov fs:[si].trb_control,0

scoStatusIn: 
    call WaitForEndpointTrb
    mov ax,TRB_TYPE_STATUS SHL 10
    or ax,fs:xp_ring_pcs
    or al,20h
    mov fs:[si].trb_type,ax
    mov fs:[si].trb_control,1
    clc

scoDone:
    popad
    ret
SetupControlOut	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunControl
;
;       DESCRIPTION:    Run control
;
;       PARAMETERS:     DS      Usb function
;                       ES      Usb device
;                       FS      Control pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunControl   Proc near
    push ds
    pushad
;
    test es:usbd_flags,FLAG_DETACHED
    stc
    jnz rcDone
;
    call fword ptr ds:is_dev_connected_proc
    jc rcDone
;
    mov fs:xp_result,-1
;
    push ds
    mov ds,ds:xhc_db_sel
    movzx si,fs:xp_slot
    shl si,2
    movzx eax,fs:xp_db_target
    mov ds:[si],eax
    pop ds
;
    mov cx,100

rcWait:
    mov ax,4
    WaitMilliSec
;
    test es:usbd_flags,FLAG_DETACHED
    stc
    jnz rcDone
;
    call fword ptr ds:is_dev_connected_proc
    jc rcDone
;
    mov al,fs:xp_result
    cmp al,-1
    jne rcCheck
;
    loop rcWait
;
    stc
    jmp rcDone

rcCheck:
    clc

rcDone:
    popad
    pop ds
    ret
RunControl   Endp
    
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
    push edx
    push ebp
;
    mov cx,es:usbd_control_buf.usd_len
    mov fs:xp_size,0
    mov es:xd_control_buf,0
    mov fs,es:xd_control_pipe
;
    test es:usbd_control_buf.usd_type,80h
    jz cmDataOut
;
    call SetupControlIn
    jc cmDone
;
    call RunControl
    jc cmDone
;
    call CopyControlIn
    jmp cmDone

cmDataOut:
    call SetupControlOut
    jc cmDone
;
    call RunControl
    jmp cmDone

cmDone:
    pushf
    push ecx
    push edx
;
    xor cx,cx
    xchg cx,fs:xp_size
    or cx,cx
    jz cmFreeOk
;
    xor edx,edx
    xchg edx,es:xd_control_buf
    or edx,edx
    jz cmFreeOk
;
    FreeLinearMemBlk

cmFreeOk:
    pop edx
    pop ecx
    popf
;
    pop ebp
    pop edx
    pop eax
    pop fs
    retf32
ControlMsg   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateBulkPipe
;
;       DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     ES      Device
;                       CX      Buffer count
;                       DL      Pipe #
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CreateBulkPipe   Proc far
    int 3
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
;                       DL      Pipe #
;                       DH      Interval
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntrPipe   Proc far
    int 3
    retf32
CreateIntrPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           EnablePipe
;
;       DESCRIPTION:    Enable pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EnablePipe   Proc far
    int 3
    retf32
EnablePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           DisablePipe
;
;       DESCRIPTION:    Disable pipe
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DisablePipe   Proc far
    int 3
    retf32
DisablePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UsedBuffers
;
;       DESCRIPTION:    Return used buffers
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;       RETURN:         CX      Buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UsedBuffers   Proc far
    int 3
    retf32
UsedBuffers   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreeBuffers
;
;       DESCRIPTION:    Return free buffers
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe sel
;
;       RETURN:         CX      Buffers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeBuffers   Proc far
    int 3
    retf32
FreeBuffers   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReqBuffer
;
;       DESCRIPTION:    Req buffer
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;       RETURNS:        EDX     Buffer linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReqBuffer   Proc far
    int 3
    retf32
ReqBuffer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RelBuffer
;
;       DESCRIPTION:    Release buffer
;
;       PARAMETERS:     ES      Device
;                       GS      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RelBuffer   Proc far
    int 3
    retf32
RelBuffer   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IsRunning
;
;       DESCRIPTION:    Check if running
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsRunning   Proc far
    stc
    retf32
IsRunning   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           UnlinkPipes
;
;       DESCRIPTION:    Unlink pipes
;
;       PARAMETERS:     ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkPipes   Proc far
    int 3
    retf32
UnlinkPipes   Endp

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
AllocateAddress   Endp

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
FreeAddress       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateDevice
;
;       DESCRIPTION:    Allocate device
;
;       PARAMETERS:     DS      Device sel
;
;       RETURNS:        ES      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateDevice    Proc near
    pushad
;
    mov ax,ds:xhc_context_size
    mov si,SIZE xhci_dev_struc
    mov cx,16
    CreateMemBlk64
;    
    mov cx,ds:xhc_context_size
    AllocateMemBlk
    sub edx,es:mblk_linear_base
    mov es:xd_input_context_offset,dx
;
    mov cx,ds:xhc_context_size
    AllocateMemBlk
    sub edx,es:mblk_linear_base
    mov es:xd_input_slot_offset,dx
;
    mov di,OFFSET xd_input_ep_arr_offset
    mov bp,32

adiEpLoop:
    mov cx,ds:xhc_context_size
    AllocateMemBlk
    sub edx,es:mblk_linear_base
    mov es:[di],dx
    add di,2 
    sub bp,1
    jnz adiEpLoop      
;
    popad
    ret
AllocateDevice    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateDeviceContext
;
;       DESCRIPTION:    Allocate device context
;
;       RETURNS:        EBX:EAX		Physical address
;                       EDX             Device context linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateDeviceContext    Proc near
    push es
    push ecx
    push edi
;
    mov eax,1000h
    AllocateBigLinear
;    
    AllocatePhysical64
    push eax
;
    mov al,13h
    SetPageEntry
;    
    mov ax,flat_sel
    mov es,ax
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
AllocateDeviceContext	Endp

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
    movzx di,al
    shl di,3
;
    call AllocateDevice
;
    mov es:xd_dev_sel,ds
    mov es:usbd_speed,al
    mov es:usbd_parent_thread,0
;
    pushad
;
    mov bx,ds:xhc_context_size
    mov es:xd_ep_size,bx
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
    call AllocateDeviceContext
    mov es:xd_device_context,edx
    mov fs:[di],eax
    mov fs:[di+4],ebx
    mov es:usbd_func_sel,ds
;
    popad
;
    mov ax,25
    WaitMilliSec
;
    popad
    pop fs
    retf32   
CreateDev       Endp

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
    mov gs,ds:xhc_port_sel
    movzx di,dl
    shl di,4
;    
    mov eax,gs:[di]
    test al,1
    jz rpFail
;
    and eax,0EE03E1h
    or al,10h
    mov gs:[di],eax

rpCheckResetLoop:
    mov eax,gs:[di]
    test al,1
    jz rpFail
;
    test al,10h
    jz rpResetDone    
;
    mov ax,25
    WaitMilliSec
    jmp rpCheckResetLoop    

rpResetDone:
    mov ax,25
    WaitMilliSec
;
    mov bx,ds:xhc_port_thread
    Signal
;
    mov cx,100

rpSlotLoop:
    mov eax,gs:[di]
    call PortToSpeed
    cmp al,-1
    clc
    jne rpDone
;
    mov ax,25
    WaitMilliSec
    loop rpSlotLoop    

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
;           DESCRIPTION:    Update port
;
;       PARAMETERS:         DS  Function sel
;                           CL  Port #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdatePort  Proc near
    push eax
    push esi
;
    movzx esi,dl
    shl esi,4
    add esi,ds:xhc_port_offset
    mov eax,ds:[esi]
    NotifyUsbPortState
;
    pop esi
    pop eax
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
    push esi
;        
    movzx esi,cl
    shl esi,4
    add esi,ds:xhc_port_offset
;    
    mov eax,ds:[esi]
    and eax,0EE03E1h
    or ax,200h
    mov ds:[esi],eax
;
    pop esi
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

; port change ???
    
;    
    movzx di,cl
    shl di,4
    mov fs,es:xhc_port_sel
;
    mov eax,fs:[di]
    and eax,0EE03E1h
    mov fs:[di],eax


port_thread:
    mov ds,bx
    GetThread
    mov ds:xhc_port_thread,ax
;
    xor cl,cl

ptPowerLoop:    
    call SetPortPower

ptPowerNext:
    inc cl
    cmp cl,ds:xhc_port_count
    jb ptPowerLoop
;
    mov ax,750
    WaitMilliSec
    
ptLoop:
    WaitForSignal
    int 3

ptRetry:    
    xor eax,eax
    xchg eax,ds:xhc_port_change_mask
    or eax,eax
    jz ptLoop
;
    xor dl,dl

ptPortLoop:    
    test al,1
    jz ptPortNext
;
    call UpdatePort

ptPortNext:
    inc dl
    shr eax,1
    jnz ptPortLoop   
;
    jmp ptLoop    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreatePortThread
;
;       DESCRIPTION:    Create port thread
;
;       PARAMETERS:     DS  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xhci_name   DB 'XHCI ', 0

CreatePortThread   Proc near
    push ds
    push es
    pushad
;
    mov si,di
    mov eax,100h
    AllocateSmallGlobalMem
    xor di,di
    mov si,OFFSET xhci_name

cptXhciLoop:
    mov al,cs:[si]
    inc si
    or al,al
    jz cptXhciDone
;
    stosb
    jmp cptXhciLoop

cptXhciDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    mov bx,ds
    mov ax,cs
    mov ds,ax
    xor di,di
    mov si,OFFSET port_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    FreeMem
;
    popad    
    pop es
    pop ds
    ret
CreatePortThread   Endp

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
;       PARAMETERS:     DS     Function sel
;                       ES:SI  Event TRB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

command_event Proc near
    int 3
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
;       NAME:           transfer_event
;
;       DESCRIPTION:    Transfer event
;
;       PARAMETERS:     DS     Function sel
;                       ES:SI  Event TRB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

transfer_event Proc near
    int 3
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
;    mov bx,fs:usbp_signal
    or bx,bx
    jz teSignalDone
;
    Signal

teSignalDone:
;    mov bx,fs:usbp_wait
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
;
;       NAME:           port_event
;
;       DESCRIPTION:    Port status change event
;
;       PARAMETERS:     DS     Function sel
;                       ES:SI  Event TRB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

port_event Proc near
    mov cl,es:[si+3]
    or cl,cl
    jz peDone
;
    dec cl
    cmp cl,ds:xhc_port_count
    jae peDone
;    
    mov eax,1
    shl eax,cl
    lock or ds:xhc_port_change_mask,eax
;
    mov bx,ds:xhc_port_thread
    Signal

peDone:
    ret
port_event Endp

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
;                           DL  Interrupter #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

event_thread:
    mov ds,bx
    movzx si,dl
    shl si,1
    mov es,ds:[si].xhc_intr_arr
    GetThread
    mov es:ev_thread,ax
;
    mov es:ev_ccs,1
    mov si,es:ev_hdr_size

etWait:
    WaitForSignal

etNext:    
    mov eax,es:[si+12]
    mov dx,es:ev_ccs
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
    xor es:ev_ccs,1
    mov si,es:ev_hdr_size
    jmp etNext

etDeq:
    mov edi,ds:xhc_run_offset
    mov eax,es:ev_phys
    mov ebx,es:ev_phys+4
    or ax,si
    or al,8
    mov ds:[edi].rrsDequeue,eax
    mov ds:[edi].rrsDequeue+4,ebx    
    jmp etWait

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateEventThread
;
;       DESCRIPTION:    Create event thread
;
;       PARAMETERS:     DS  Function sel
;                       DL  Interrupter #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEventThread   Proc near
    push ds
    push es
    pushad
;
    mov si,di
    mov eax,100h
    AllocateSmallGlobalMem
    xor di,di
    mov si,OFFSET xhci_name

cetXhciLoop:
    mov al,cs:[si]
    inc si
    or al,al
    jz cetXhciDone
;
    stosb
    jmp cetXhciLoop

cetXhciDone:
    mov ax,ds:usb_controller_id
    call HexToAscii
    stosw
;
    mov al,'.'
    stosb
;
    mov al,dl
    call HexToAscii
    stosw
;
    xor al,al
    stosb
;
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov si,OFFSET event_thread
    xor di,di
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    FreeMem
;
    popad    
    pop es
    pop ds
    ret
CreateEventThread   Endp
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           XhciInt
;
;       DESCRIPTION:    XHCI interrupt
;
;       PARAMETERS:     DS      Event selector
;
;       RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

XhciInt Proc far 
    mov bx,ds:ev_thread
    Signal
    retf32
XhciInt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocatePhysicalPage
;
;       DESCRIPTION:    Allocate physical page
;
;       PARAMETERS:     DS      Function selector
;
;       RETURNS:        EBX:EAX Physical address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePhysicalPage   Proc near
    mov al,ds:xhc_has_64
    jz app32

app64:
    AllocatePhysical64
    jmp appDone

app32:
    AllocatePhysical32

appDone:
    ret
AllocatePhysicalPage   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateScratchPad
;
;       DESCRIPTION:    Create scratch pad area (if needed)
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateScratchPad   Proc near
    mov ebx,ds:xhc_cap_offset
    mov eax,ds:[ebx].hccParams2
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
;
    call AllocatePhysicalPage
    mov al,13h
    SetPageEntry
;
    xor al,al
    mov esi,DEV_OFFSET
    mov ds:[esi],eax
    mov ds:[esi+4],ebx
    pop cx
;
    mov ax,flat_sel
    mov es,ax
;
    mov ebp,edx
    add edx,1000h
        
cspLoop:
    call AllocatePhysicalPage
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
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    sub edx,1000h
    SetPageEntry
;
    mov ecx,2000h
    FreeLinear
;
    popad
    pop es    
        
cspDone:    
    ret
CreateScratchPad   Endp   


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddFunction
;
;           DESCRIPTION:    Add XHCI function
;
;       PARAMETERS:         DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xhci_tab:
et00 DD OFFSET Block,               SEG code
et01 DD OFFSET Unblock,             SEG code
et02 DD OFFSET ResetPort,           SEG code
et03 DD OFFSET DisablePort,         SEG code
et04 DD OFFSET DisableDev,          SEG code
et05 DD OFFSET IsPortConnected,     SEG code
et06 DD OFFSET IsRunning,           SEG code
et07 DD OFFSET AllocateAddress,     SEG code
et08 DD OFFSET FreeAddress,         SEG code
et09 DD OFFSET CreateDev,           SEG code
et0A DD OFFSET UnlinkPipes,         SEG code
et0B DD OFFSET IsDeviceConnected,   SEG code
et0C DD OFFSET FreeDev,             SEG code
et0D DD OFFSET CreateControl,       SEG code
et0E DD OFFSET CreateBulkPipe,      SEG code
et0F DD OFFSET CreateIntrPipe,      SEG code
et10 DD OFFSET AddressDevice,       SEG code
et11 DD OFFSET ChangeAddress,       SEG code
et12 DD OFFSET UpdateMaxLen,        SEG code
et13 DD OFFSET ControlMsg,          SEG code
et14 DD OFFSET ConfigDevice,        SEG code
et15 DD OFFSET EnablePipe,          SEG code
et16 DD OFFSET DisablePipe,         SEG code
et17 DD OFFSET UsedBuffers,         SEG code
et18 DD OFFSET FreeBuffers,         SEG code
et19 DD OFFSET ReqBuffer,           SEG code
et1A DD OFFSET RelBuffer,           SEG code

AddFunction    Proc near
    push es
    push fs
    pushad
;
    InitSection ds:xhc_cmd_section
;
    mov edi,ds:xhc_oper_offset
    and ds:[edi].orsUsbCmd,NOT 1

ifWaitStop:
    test ds:[edi].orsUsbSts,1
    jnz ifWaitStopped
;
    mov ax,10
    WaitMilliSec
    jmp ifWaitStop

ifWaitStopped:    
    or ds:[edi].orsUsbCmd,2

ifWaitReset:
    test ds:[edi].orsUsbCmd,2
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
    mov cx,ds:xhc_intr_count
    mov al,14h
    AllocateInts
    pop cx
    jnc ifMsiSetup
;
    mov ds:xhc_intr_count,1
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc ifIrq

ifMsiSetup:
    mov ds:xhc_int_base,al
    mov dx,ds:xhc_intr_count
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
    mov cx,ds:xhc_intr_count
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
    mov di,ds:xhc_intr_arr
    mov ds,di
    mov di,cs
    mov es,di
    mov edi,OFFSET XhciInt
    RequestMsiHandler
    pop es
    pop ds
    jmp ifIntDone

ifIrq:
    mov ds:xhc_intr_count,1
    push ds
    push es
    GetPciIrqNr
    mov ah,14h
    mov di,ds:xhc_intr_arr
    mov ds,di
    mov di,cs
    mov es,di
    mov edi,OFFSET XhciInt
    RequestIrqHandler
    pop es
    pop ds

ifIntDone:    
    mov edi,ds:xhc_oper_offset
    movzx eax,ds:xhc_slot_count
    mov ds:[edi].orsConfig,eax
;    
    mov eax,ds:xhc_dcba
    mov ds:[edi].orsDcbaap,eax
    mov eax,ds:xhc_dcba+4
    mov ds:[edi].orsDcbaap+4,eax
;    
    call CreateScratchPad
;
    mov eax,ds:xhc_crcr
    or al,1
    mov ds:[edi].orsCrCtrl,eax
    mov eax,ds:xhc_crcr+4
    mov ds:[edi].orsCrCtrl+4,eax
;
    mov edi,ds:xhc_run_offset    
    mov es,ds:xhc_intr_arr
    mov eax,es:ev_phys
    mov ebx,es:ev_phys+4
    add ax,es:ev_hdr_size
    mov ds:[edi].rrsDequeue,eax
    mov ds:[edi].rrsDequeue+4,ebx    
;    
    mov eax,es:ev_phys
    mov ebx,es:ev_phys+4
    mov ds:[edi].rrsBase,eax
    mov ds:[edi].rrsBase+4,ebx    
;    
    mov ds:[edi].rrsRingSize,1
;
    mov ds:[edi].rrsImod,400
    mov ds:[edi].rrsIman,3
;
    mov ax,ds
    mov es,ax
    mov si,OFFSET xhci_tab
    xor di,di
    mov cx,2*1Bh

ifTabLoop:
    lods dword ptr cs:[si]
    stosd
    loop ifTabLoop    
;
    InitUsbFunction
;
    xor dl,dl
    call CreateEventThread
    call CreatePortThread
;    
    mov edi,ds:xhc_oper_offset
    or ds:[edi].orsUsbCmd,4    
    or ds:[edi].orsUsbCmd,1

ifDone:
    popad
    pop fs
    pop es
    ret
AddFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CalcRegSize
;
;       DESCRIPTION:    Calc size of registers
;
;       PARAMETERS:     EBX:EAX Register base
;
;       RETURNS:        ECX     Size
;                       ES      Params struc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcRegSize	Proc near
    push ds
    push eax
    push ebx
    push edx
;
    push eax
    mov eax,SIZE xhc_params
    AllocateSmallGlobalMem
    pop eax
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
    and ax,0FFFh
    mov es:par_offset,ax
    or dx,ax
;
    mov ax,flat_sel
    mov ds,ax
    movzx ebx,ds:[edx].hccLen
    mov es:par_oper_offset,ebx
;
    mov eax,ds:[edx].hccParams1
    mov es:par_slot_count,al
    shr eax,8
    and ax,7FFh
    mov es:par_intr_count,ax
    shr eax,16
    mov es:par_port_count,al
;
    mov eax,ds:[edx].hccParams2
    shr eax,4
    and al,0Fh
    mov es:par_seg_count,al
    shr eax,17
    mov bl,al
    and bx,1Fh
    shl bx,6
    shr ax,16
    and al,1Fh
    or bl,al
    mov es:par_scratch_count,bx
;
    mov eax,ds:[edx].hccCap1
    test al,1
    jz crsPhys32

crsPhys64:
    mov es:par_has_64,1
    jmp crsPhysOk

crsPhys32:
    mov es:par_has_64,0

crsPhysOk:
    test al,4
    jz crsSlot32

crsSlot64:
    mov es:par_slot_size,64
    jmp crsSlotOk

crsSlot32:
    mov es:par_slot_size,32

crsSlotOk:
    mov eax,ds:[edx].hccDbOff
    mov es:par_db_offset,eax
;
    mov eax,ds:[edx].hccRtsOff
    mov es:par_run_offset,eax
;
    xor eax,eax
    xor ebx,ebx
    SetPageEntry
;
    mov ecx,1000h
    FreeLinear
;
    mov ecx,es:par_oper_offset
    movzx eax,es:par_slot_count
    shl eax,4
    add eax,es:par_db_offset
    cmp ecx,eax
    ja crsDbOk
;
    mov ecx,eax

crsDbOk:
    movzx eax,es:par_intr_count
    inc eax
    shl eax,5
    add eax,es:par_run_offset
;
    cmp ecx,eax
    ja crsRunOk
;
    mov ecx,eax

crsRunOk:
    movzx eax,es:par_offset
    add ecx,eax
;
    dec ecx
    and cx,0F000h
    add ecx,1000h
;
    pop edx
    pop ebx
    pop eax
    pop ds
    ret
CalcRegSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateFuncSel
;
;       DESCRIPTION:    Create function selector
;
;       PARAMETERS:     ES      Param
;                       ECX     Reg size
;
;       RETURNS:        DS      Function sel
;                       EDX     Function linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFuncSel	Proc near
    push eax
    push ebx
    push ecx
;
    push eax
    push ecx
    mov eax,ecx
    add eax,REG_OFFSET
    AllocateBigLinear
    pop ecx
    pop eax
;
    push ecx
    push edx
;
    add edx,REG_OFFSET
    shr ecx,12
    and ax,0F000h
    or ax,813h

cfsLoop:
    SetPageEntry
;
    add edx,1000h
    add eax,1000h
    loop cfsLoop
;
    pop edx
    pop ecx
;
    AllocateGdt
    add ecx,REG_OFFSET
    CreateDataSelector32
    mov ds,bx    
;    
    pop ecx
    pop ebx
    pop eax
    ret
CreateFuncSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitFuncSel
;
;       DESCRIPTION:    Init function selector
;
;       PARAMETERS:     DS      Function sel
;                       EDX     Function linear
;                       ES      Param
;                       EBX:EAX Register base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitFuncSel	Proc near
    push eax
    push edx
;
    push eax
    push ebx
;
    mov al,es:par_has_64
    jz ifsFunc32

ifsFunc64:
    AllocatePhysical64
    jmp ifsFuncOk

ifsFunc32:
    AllocatePhysical32

ifsFuncOk:
    push es
    push eax
    push ecx
    push edi
;
    mov al,3
    SetPageEntry
;
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop edi
    pop ecx
    pop eax
    pop es
;
    mov ds:xhc_linear,edx
    xor al,al
    mov ds:xhc_func_phys,eax
    mov ds:xhc_func_phys+4,ebx
;
    pop ebx
    pop eax    
;
    mov ds:xhc_reg_phys,eax
    mov ds:xhc_reg_phys+4,ebx
;
    movzx edx,es:par_offset
    add edx,REG_OFFSET
    mov ds:xhc_cap_offset,edx
;
    mov eax,es:par_oper_offset
    add eax,edx
    mov ds:xhc_oper_offset,eax
    add eax,400h
    mov ds:xhc_port_offset,eax
;
    mov eax,es:par_run_offset
    add eax,edx
    mov ds:xhc_run_offset,eax
    add eax,20h
    mov ds:xhc_intr_offset,eax
;
    mov eax,es:par_db_offset
    add eax,edx
    mov ds:xhc_db_offset,eax
;
    mov al,es:par_has_64
    mov ds:xhc_has_64,al
;
    mov ax,es:par_intr_count
    cmp ax,MAX_INTR_COUNT
    jb ifSaveCount
;
    mov ax,MAX_INTR_COUNT

ifSaveCount:
    mov ds:xhc_intr_count,ax
;
    mov al,es:par_slot_count
    mov ds:xhc_slot_count,al
;
    mov al,es:par_port_count
    mov ds:xhc_port_count,al
;
    FreeMem
;
    pop edx
    pop eax
    ret
InitFuncSel     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateEventRing
;
;       DESCRIPTION:    Init event ring
;
;       PARAMETERS:     DS      Function selector
;
;       RETURNS:        ES      Event ring selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateEventRing   Proc near
    pushad
;
    mov ax,flat_sel
    mov es,ax
;
    mov eax,1000h
    AllocateBigLinear
;
    call AllocatePhysicalPage
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
    mov es:[edx].ev_phys,eax
    mov es:[edx].ev_phys+4,ebx
;
    AllocateGdt
    mov cx,1000h
    CreateDataSelector16
    mov es,bx
;
    mov ecx,SIZE event_seg
    dec cx
    and cx,0FFC0h
    add cx,40h
    mov es:ev_hdr_size,cx
    mov ax,1000h
    sub ax,cx
    shr ax,4
    mov es:ev_size,ax
    mov es:ev_resv1,0
    mov es:ev_resv2,0
;
    mov eax,es:ev_phys
    add eax,ecx
    mov es:ev_ers,eax
;
    mov eax,es:ev_phys+4
    mov es:ev_ers+4,eax
    mov es:ev_thread,0
;
    popad    
    ret
CreateEventRing   Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateCommandRing
;
;       DESCRIPTION:    Create command ring
;
;       PARAMETERS:     DS      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateCommandRing   Proc near
    push es
    pushad
;
    mov ax,flat_sel
    mov es,ax    
;
    call AllocatePhysicalPage
    push eax
;
    mov edx,ds:xhc_linear
    add edx,CMD_OFFSET
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
    mov ds:xhc_crcr,eax
    mov ds:xhc_crcr+4,ebx
;
    mov edi,DEV_OFFSET - 10h
    mov ds:[edi].trb_param,eax
    mov ds:[edi].trb_param+4,ebx
    mov ds:[edi].trb_status,0
    mov ds:[edi].trb_type,2 + (TRB_TYPE_LINK SHL 10)
    mov ds:[edi].trb_control,0
;
    add eax,DEV_OFFSET - CMD_OFFSET
    mov ds:xhc_dcba,eax
    mov ds:xhc_dcba+4,ebx
;
    popad
    pop es
    ret
CreateCommandRing   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           BiosHandoff
;
;       DESCRIPTION:    Do BIOS handoff
;
;       PARAMETERS:     DS        Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BiosHandoff Proc near
    pushad
;    
    mov edx,ds:xhc_cap_offset
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
    popad
    ret
BiosHandoff Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateFunction
;
;       DESCRIPTION:    Create function
;
;       PARAMETERS:     EDX:EAX Base address
;
;       RETURNS:        NC
;                         DS    Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFunction  Proc near
    push es
    pushad
;
    mov ebx,edx
    call CalcRegSize
    cmp ecx,10000h
    jbe cfCreate
;
    FreeMem
    stc
    jmp cfDone

cfCreate:
    call CreateFuncSel
    call InitFuncSel
;
    call CreateEventRing
    mov ds:xhc_intr_arr,es
;
    call CreateCommandRing
    call BiosHandoff
    clc

cfDone:
    popad
    pop es
    ret
CreateFunction  Endp

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
    call CreateFunction
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
    call CreateFunction
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
    mov ds:dump_file,0
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
