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
INCLUDE ..\acpi\pci.inc
INCLUDE usb.inc
INCLUDE ..\os\memblk.inc
INCLUDE usbdev.inc
include hub.inc

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

trb_struc   STRUC

trb_param   DD ?,?
trb_status  DD ?
trb_type    DW ?
trb_control DW ?

trb_struc   ENDS

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

xhc_params      STRUC

par_oper_offset    DD ?
par_db_offset      DD ?
par_run_offset     DD ?
par_cap_offset     DD ?
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
ev_flag       DB ?

event_seg   ENDS

cev_struc   STRUC

cev_thread  DW ?
cev_slot    DB ?
cev_result  DB ?

cev_struc   ENDS

CMD_COUNT  = 7Fh

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

xhc_pci_handle          DW ?

xhc_has_64              DB ?
xhc_pad1                DB ?

xhc_slot_count          DB ?
xhc_port_count          DB ?

xhc_crcr                DD ?,?
xhc_dcba                DD ?,?

xhc_cmd_section         section_typ <>
xhc_cmd_enque           DW ?
xhc_cmd_pcs             DW ?
xhc_cmd_arr             DD CMD_COUNT DUP(?)

xhc_intr_sel            DW ?

xhc_context_size        DW ?
xhc_slot_sel_arr        DW 256 DUP(?)

xhci_func_sel   ENDS

xhci_input_struc   STRUC

xi_phys_base         DD ?

xi_input_offset      DW ?
xi_slot_offset       DW ?
xi_control_offset    DW ?
xi_pipe_arr_offset   DW 30 DUP (?)

xhci_input_struc   ENDS

xhci_dev_struc   STRUC

usb_dev_base                 usb_device_struc <>

xd_func_sel                  DW ?
xd_control_trb               DW ?
xd_control_buf               DD ?
xd_control_pipe              DW ?
xd_control_offset            DW ?
xd_control_enque             DW ?
xd_control_deque             DW ?
xd_control_pcs               DW ?
xd_control_size              DW ?
xd_control_remain_size       DW ?
xd_control_result            DB ?
xd_slot                      DB ?

xd_input_sel                 DW ?

xd_dummy_ring_linear         DD ?
xd_slot_context_offset       DW ?
xd_control_context_offset    DW ?
xd_pipe_context_arr_offset   DW 30 DUP (?)

xd_pipe_sel_arr              DW 30 DUP(?)

xhci_dev_struc    ENDS

xhci_pipe   STRUC

xp_base             usb_pipe_struc <>

xp_ring_linear      DD ?
xp_ring_phys        DD ?,?
xp_ring_entries     DW ?
xp_ring_pcs         DW ?

xp_slot             DB ?
xp_db_target        DB ?

xhci_pipe   ENDS

xhci_raw_struc     STRUC

xr_base            usb_raw_struc <>

xr_pos             DW ?
xr_remain          DW ?
xr_res             DB ?

xhci_raw_struc     ENDS

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
;       NAME:           WaitForCommandTrb
;
;       DESCRIPTION:    Wait for empty command TRB
;
;       PARAMETERS:     DS          Function sel
;
;       RETURNS:        DI          TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCommandTrb   Proc near
    push ax
;
    EnterSection ds:xhc_cmd_section    
;    
    mov di,ds:xhc_cmd_enque

wfctLoop:    
    mov ax,ds:[di].trb_type
    test ax,2
    jz wfctRetry
;
    xor ds:[di].trb_type,1
    xor ds:xhc_cmd_pcs,1
    mov di,CMD_OFFSET
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
    mov ds:[di].trb_param,0
    mov ds:[di].trb_param+4,0
    mov ds:[di].trb_status,0
    mov ds:[di].trb_control,0
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
;                       DI      TRB offset
;
;       RETURNS:        SI      Result offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SendCommandTrb   Proc near
    push eax
    push ebx
;    
    push ax
    mov si,di
    sub si,CMD_OFFSET
    shr si,2
    add si,OFFSET xhc_cmd_arr
    GetThread
    mov ds:[si].cev_thread,ax
    pop ax
;
    movzx ax,al
    shl ax,10
    or ax,ds:xhc_cmd_pcs
    mov ds:[di].trb_type,ax
;
    mov ebx,ds:xhc_db_offset
    xor eax,eax
    mov ds:[ebx],eax
;
    LeaveSection ds:xhc_cmd_section    

sctWait:
    WaitForSignal
    mov ax,ds:[si].cev_thread
    or ax,ax
    jnz sctWait
;
    pop ebx
    pop eax
    ret
SendCommandTrb  Endp

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
;       NAME:           IsRunning
;
;       DESCRIPTION:    Check if running
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsRunning   Proc far
    push edi
;
    mov edi,ds:xhc_oper_offset
;
    test ds:[edi].orsUsbSts,1
    jnz isrHalted
;
    clc
    jmp isrDone

isrHalted:
    int 3
    stc

isrDone:
    pop edi
    retf32
IsRunning   Endp

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
    push esi
;
    movzx esi,dl
    shl esi,4
    add esi,ds:xhc_port_offset
    mov eax,ds:[si]
    test al,1
    clc
    jnz ipcDone
;    
    stc

ipcDone:
    pop esi
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
    push esi
;
    movzx esi,es:usbd_port
    shl esi,4
    add esi,ds:xhc_port_offset
    mov eax,ds:[esi]
    test al,1
    clc
    jnz idcDone
;    
    stc

idcDone:
    pop esi
    pop eax
    pop fs
    pop es
    retf32
IsDeviceConnected Endp

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
    push ecx
    push edi
;    
    movzx edi,dl
    shl edi,4
    add edi,ds:xhc_port_offset
;    
    mov eax,ds:[edi]
    test al,1
    jz rpFail
;
    and eax,0EE03E1h
    or ax,200h
    mov ds:[edi],eax
;
    pop edi
    pop ecx
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
    push ecx
    push edi
;    
    movzx edi,dl
    shl edi,4
    add edi,ds:xhc_port_offset
;    
    mov eax,ds:[edi]
    test al,1
    jz rpFail
;
    and eax,0EE03E1h
    or al,10h
    mov ds:[edi],eax

rpCheckResetLoop:
    mov eax,ds:[edi]
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
    mov cx,100

rpSlotLoop:
    mov eax,ds:[edi]
    call PortToSpeed
    cmp al,-1
    jne rpOk
;
    mov ax,25
    WaitMilliSec
    loop rpSlotLoop    

rpFail:
    stc
    jmp rpDone

rpOk:
    push ax
    mov ax,250
    WaitMilliSec
    pop ax
    clc

rpDone:
    pop edi
    pop ecx
    retf32
ResetPort   Endp

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
    push esi
    push edi
;
    call WaitForCommandTrb
    mov al,TRB_TYPE_ENABLE_SLOT
    call SendCommandTrb
;
    mov al,ds:[si].cev_result
    cmp al,1
    stc
    jne esDone
;
    mov al,ds:[si].cev_slot
    clc        

esDone:
    pop edi
    pop esi
    retf32   
AllocateAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ZeroContext
;
;       DESCRIPTION:    Zero context struct
;
;       PARAMETERS:     CX      Size
;                       EDX     Context linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ZeroContext    Proc near
    push es
    push eax
    push ecx
    push edi
;
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    movzx ecx,cx
    shr ecx,2
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop edi
    pop ecx
    pop eax
    pop es
    ret
ZeroContext    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateInput
;
;       DESCRIPTION:    Allocate input
;
;       PARAMETERS:     DS      Device sel
;
;       RETURNS:        BX      Input sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateInput    Proc near
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;
    mov ax,flat_sel
    mov es,ax
;
    mov eax,1000h
    AllocateBigLinear
;
    AllocatePhysical32
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
    mov es:[edx].xi_phys_base,eax
;
    AllocateGdt
    mov cx,1000h
    CreateDataSelector16
    mov es,bx
;
    mov bx,SIZE xhci_input_struc
    dec bx
    shr bx,6
    inc bx
    shl bx,6
;
    mov si,ds:xhc_context_size
    mov es:xi_input_offset,bx
;
    add bx,si
    mov es:xi_slot_offset,bx
;
    add bx,si
    mov es:xi_control_offset,bx
;
    mov di,OFFSET xi_pipe_arr_offset
    mov cx,30

aiLoop:
    add bx,si
    mov es:[di],bx
    add di,2
    loop aiLoop
;
    mov bx,es
;
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
AllocateInput  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocateDevice
;
;       DESCRIPTION:    Allocate device
;
;       PARAMETERS:     DS      Function sel
;
;       RETURNS:        ES      Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateDevice    Proc near
    pushad
;
    mov al,ds:xhc_has_64
    or al,al
    jz adMem32

adMem64:
    mov ax,ds:xhc_context_size
    mov si,SIZE xhci_dev_struc
    mov cx,16
    CreateMemBlk64
    jmp adMemDone

adMem32:
    mov ax,ds:xhc_context_size
    mov si,SIZE xhci_dev_struc
    mov cx,16
    CreateMemBlk32

adMemDone:
    mov cx,ds:xhc_context_size
    cmp cx,64
    je adAlloc64

adAlloc32:
    mov cx,64
    AllocateMemBlk
    call ZeroContext
    sub edx,es:mblk_linear_base
    mov es:xd_slot_context_offset,dx
;
    add edx,32
    mov es:xd_control_context_offset,dx
;
    mov di,OFFSET xd_pipe_context_arr_offset
    mov bp,15

adiEpLoop32:
    mov cx,64
    AllocateMemBlk
    call ZeroContext
    sub edx,es:mblk_linear_base
    mov es:[di],dx
    add di,2 
;
    add edx,32
    mov es:[di],dx
    add di,2 
;
    sub bp,1
    jnz adiEpLoop32
    jmp adAllocDone

adAlloc64:
    mov cx,ds:xhc_context_size
    AllocateMemBlk
    call ZeroContext
    sub edx,es:mblk_linear_base
    mov es:xd_slot_context_offset,dx
;
    mov cx,ds:xhc_context_size
    AllocateMemBlk
    call ZeroContext
    sub edx,es:mblk_linear_base
    mov es:xd_control_context_offset,dx
;
    mov di,OFFSET xd_pipe_context_arr_offset
    mov bp,30

adEpLoop64:
    mov cx,ds:xhc_context_size
    AllocateMemBlk
    call ZeroContext
    sub edx,es:mblk_linear_base
    mov es:[di],dx
    add di,2 
    sub bp,1
    jnz adEpLoop64      

adAllocDone:
    popad
    ret
AllocateDevice    Endp

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
    call AllocateDevice
    call AllocateInput
    mov es:xd_input_sel,bx
;
    mov es:xd_slot,al
    mov es:xd_func_sel,ds
    mov es:usbd_speed,ah
    mov es:usbd_parent_thread,0
;
    movzx bx,al
    shl bx,1
    mov ds:[bx].xhc_slot_sel_arr,es
    mov es:usbd_func_sel,ds
;
    movzx di,al
    shl di,3
    add di,DEV_OFFSET
    movzx eax,es:xd_slot_context_offset
    add eax,es:mblk_physical_base
    mov ebx,es:mblk_physical_base+4
    mov ds:[di],eax
    mov ds:[di+4],ebx
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
    push esi
    push edi
;
    call WaitForCommandTrb
;
    mov ah,es:xd_slot
    xor al,al
    mov ds:[di].trb_control,ax
;
    mov al,TRB_TYPE_DISABLE_SLOT
    call SendCommandTrb
;
    mov al,ds:[si].cev_result
    cmp al,1
    stc
    jne fdDone
;
    clc        

fdDone:
    pop edi
    pop esi
    retf32
FreeDev   Endp
 
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
;       NAME:           SetupRootDevice
;
;       DESCRIPTION:    Setup root device context
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Input context sel
;                       CL      Port #
;                       AL      PSI speed value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupRootDevice    Proc near
    pushad
;
    mov bx,fs:xi_input_offset
    mov fs:[bx].icc_add_mask,0
;    
    mov ch,al
    mov bx,fs:xi_slot_offset
    movzx eax,al
    shl eax,20
    or eax,08000000h
    mov fs:[bx].s_misc,eax
    mov al,cl
    inc al
    mov fs:[bx].s_root_hub,al
    mov fs:[bx].s_ttt_int,0
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
    mov al,fs:[bx].s_root_hub
    mov fs:[bx].s_tt_port_nr,al
    mov al,gs:usb_hub_id
    mov fs:[bx].s_tt_slot_id,al

srdSpeedOk:
    movzx eax,fs:[bx].s_root_hub
    mov cl,gs:usb_route_depth
    shl cl,2
    shl eax,cl
    or eax,gs:usb_route_str
    and eax,0FFFFFFh
    or fs:[bx].s_misc,eax
;
    mov al,gs:usb_root_port
    mov fs:[bx].s_root_hub,al
;
    pop gs

srdDone:
    popad
    ret
SetupRootDevice     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitControlRing
;
;       DESCRIPTION:    Init control ring
;
;       PARAMETERS:     DS       Function sel
;                       ES       Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitControlRing   Proc near
    pushad
;
    mov dx,es:xd_control_offset
    mov es:xd_control_enque,dx
    mov es:xd_control_deque,dx
    mov es:xd_control_pcs,1
;
    movzx edi,dx
    mov ecx,0Ch
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    movzx eax,es:xd_control_offset
    add eax,es:mblk_physical_base
    mov ebx,es:mblk_physical_base+4
;
    mov es:[edi].trb_param,eax
    mov es:[edi].trb_param+4,ebx
    mov es:[edi].trb_status,0
    mov es:[edi].trb_type,2 + (TRB_TYPE_LINK SHL 10)
    mov es:[edi].trb_control,0
;
    popad
    ret
InitControlRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateControlRing
;
;       DESCRIPTION:    Create control ring
;
;       PARAMETERS:     DS       Function sel
;                       ES       Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControlRing   Proc near
    pushad
;
    mov cx,40h
    AllocateMemBlk
    sub edx,es:mblk_linear_base
    mov es:xd_control_offset,dx
    call InitControlRing
;
    popad
    ret
CreateControlRing   Endp
 
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
;       NAME:           CreateControl
;
;       DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Device selector
;                       ES      Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    push fs
    pushad
;
    mov ah,es:usbd_speed
    call SpeedToPsi
;
    mov fs,es:xd_input_sel
    mov cl,es:usbd_port
    call SetupRootDevice
    call CreateControlRing
;
    mov bx,fs:xi_control_offset
    call GetDefaultPacketSize
    mov fs:[bx].ec_packet_size,ax
    mov fs:[bx].ec_avg_len,ax
;
    movzx eax,es:xd_control_offset
    add eax,es:mblk_physical_base
    or al,1
    mov fs:[bx].ec_tr_dequeue,eax
    mov eax,es:mblk_physical_base+4
    mov fs:[bx].ec_tr_dequeue+4,eax        
;
    mov al,3 SHL 1
    or al,4 SHL 3
    mov fs:[bx].ec_param2,al
    clc
;
    popad
    pop fs
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
;                   ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddressDevice   Proc far
    push fs
    pushad
;
    call WaitForCommandTrb
;    

    mov fs,es:xd_input_sel
    mov bx,fs:xi_input_offset
    mov fs:[bx].icc_add_mask,3
    movzx eax,bx
    add eax,fs:xi_phys_base
    mov ds:[di].trb_param,eax
    mov ds:[di].trb_param+4,0
;
    mov ah,es:xd_slot
    xor al,al
    mov ds:[di].trb_control,ax
;
    mov al,TRB_TYPE_ADDRESS_DEV
    call SendCommandTrb
;
    mov bx,fs:xi_input_offset
    mov fs:[bx].icc_add_mask,0
;
    mov al,ds:[si].cev_result
    cmp al,1
    je adOk
;
    stc
    jmp adDone

adOk:
    clc        

adDone:
    popad
    pop fs
    retf32
AddressDevice   Endp

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
;       NAME:           FreeAddress
;
;       DESCRIPTION:    Free address (slot)
;
;       PARAMETERS:     DS        Function sel
;                       AL        Address (slot #)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeAddress   Proc far
    retf32   
FreeAddress       Endp

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
    pushad
;
    call WaitForCommandTrb
;
    mov fs,es:xd_input_sel
    mov bx,fs:xi_control_offset
    mov fs:[bx].ec_avg_len,ax
    mov fs:[bx].ec_packet_size,ax
;    
    mov bx,fs:xi_input_offset
    mov fs:[bx].icc_add_mask,2
    movzx eax,bx
    add eax,fs:xi_phys_base
    mov ds:[di].trb_param,eax
    mov ds:[di].trb_param+4,0
;
    mov ah,es:xd_slot
    xor al,al
    mov ds:[di].trb_control,ax
;
    mov al,TRB_TYPE_EVALUATE
    call SendCommandTrb
;
    mov bx,fs:xi_input_offset
    mov fs:[bx].icc_add_mask,0
;
    mov al,ds:[si].cev_result
    cmp al,1
    je smlOk
;
    stc
    jmp smlDone

smlOk:
    clc        

smlDone:
    popad
    pop fs
    retf32
UpdateMaxLen   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           GetPipeState
;
;   DESCRIPTION:    Get pipe state
;
;   PARAMETERS:     DS      Function selector
;                   ES      Device selector
;                   GS      Pipe sel
;
;   RETURNS:        AL      State
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPipeState   Proc near
    push bx
;
    movzx bx,gs:xp_db_target
    sub bx,2
    add bx,bx
    mov bx,es:[bx].xd_pipe_context_arr_offset
    mov al,es:[bx].ec_state
    and al,7
;
    pop bx
    ret
GetPipeState  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateDummyRing
;
;   DESCRIPTION:    Create dummy ring
;
;   PARAMETERS:     DS      Function selector
;                   ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateDummyRing   Proc near
    push es
    pushad
;
    mov cx,10h
    AllocateMemBlk
    mov es:xd_dummy_ring_linear,edx
;
    mov ax,flat_sel
    mov es,ax
    mov ecx,4
    mov edi,edx
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    popad
    pop es
    ret
CreateDummyRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           AddEndpoint
;
;   DESCRIPTION:    Add endpoint
;
;   PARAMETERS:     DS      Function selector
;                   ES      Device selector
;                   FS:DI   Descriptor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddEndpoint   Proc near
    push gs
    pushad
;
    mov gs,es:xd_input_sel
;
    mov dl,fs:[di].ued_address
    movzx bx,dl
    and bl,0Fh
    add bx,bx
    test dl,80h
    jz aeDirOk
;
    inc bx

aeDirOk:
    mov si,gs:xi_input_offset
    mov eax,gs:[si].icc_add_mask
    mov cl,bl
    mov edx,1
    shl edx,cl
    or eax,edx
    mov gs:[si].icc_add_mask,eax
;
    mov si,gs:xi_slot_offset
    mov eax,gs:[si].s_misc
    shr eax,27
    cmp ax,bx
    jae aeContextOk
;
    mov eax,gs:[si].s_misc
    and eax,7FFFFFFh
    movzx edx,bx
    shl edx,27
    or eax,edx
    mov gs:[si].s_misc,eax

aeContextOk:
    sub bx,2
    add bx,bx    
    mov si,gs:[bx].xi_pipe_arr_offset
;
    mov al,fs:[di].ued_attrib
    and al,3
    cmp al,2
    je aeBulk
;
    cmp al,3
    je aeIntr
;
    int 3

aeIntr:
    mov al,fs:[di].ued_interval
    mov ah,3

aeIntLoop:
    shr al,1
    jz aeIntOk
;
    inc ah
    jmp aeIntLoop

aeIntOk:    
    mov dl,fs:[di].ued_address
    test dl,80h
    jnz aeIntIn

aeIntOut:
    mov al,3
    jmp aeSetup

aeIntIn:
    mov al,7
    jmp aeSetup

aeBulk:
    xor ah,ah
    mov dl,fs:[di].ued_address
    test dl,80h
    jnz aeBulkIn

aeBulkOut:
    mov al,2
    jmp aeSetup

aeBulkIn:
    mov al,6

aeSetup:
    shl al,3
    mov gs:[si].ec_param2,al        
    mov gs:[si].ec_interval,ah
;
    mov edx,es:xd_dummy_ring_linear
    LinearToPhysicalMemBlk
    or al,1
    mov gs:[si].ec_tr_dequeue,eax
    mov gs:[si].ec_tr_dequeue+4,ebx
;
    mov ax,fs:[di].ued_maxsize
    mov gs:[si].ec_avg_len,ax
    mov gs:[si].ec_packet_size,ax
    movzx eax,ax
    mov gs:[si].ec_esit_low,eax
;
    popad
    pop gs
    ret
AddEndpoint   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetupEndpoints
;
;   DESCRIPTION:    Setup endpoints
;
;   PARAMETERS:     DS      Device selector
;                   ES      Function selector
;                   DL      Config #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupEndpoints   Proc near
    push fs
    pushad
;
    movzx si,dl
    dec si
    add si,si
    mov ax,es:[si].usbd_config_sel
    mov fs,ax
;
    xor di,di
    movzx cx,fs:ucd_len
    add di,cx

seDescrLoop:
    mov cl,fs:[di].udd_type
    cmp cl,5
    jne seDescrNext
;
    call AddEndpoint

seDescrNext:    
    movzx cx,fs:[di].ucd_len
    add di,cx
    cmp di,fs:ucd_size
    jb seDescrLoop    
;
    popad
    pop fs
    ret
SetupEndpoints Endp

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

ConfigDevice   Proc far
    push es
    push fs
    push gs
    push eax
    push ebx
    push ecx
    push edi
;
    call CreateDummyRing
    call SetupEndpoints
    call WaitForCommandTrb
;
    mov fs,es:xd_input_sel
    movzx eax,fs:xi_input_offset
    add eax,fs:xi_phys_base
    mov ds:[di].trb_param,eax
    mov ds:[di].trb_param+4,0
;
    mov ah,es:xd_slot
    xor al,al
    mov ds:[di].trb_control,ax
;
    mov bx,fs:xi_input_offset
    or fs:[bx].icc_add_mask,1
;
    or cx,cx
    jz cdDo
;
    mov gs,ecx
    mov al,es:xd_slot
    mov gs:usb_hub_id,al
;
    mov bx,fs:xi_slot_offset
    mov eax,fs:[bx].s_misc
    or eax,4000000h
    mov fs:[bx].s_misc,eax
;
    mov ax,gs:hub_ports
    mov fs:[bx].s_hub_ports,al
;
    mov ax,fs:[bx].s_ttt_int
    or al,3
    mov fs:[bx].s_ttt_int,ax

cdDo:
    mov al,TRB_TYPE_CONFIGURE_ENDP
    call SendCommandTrb
;
    push es
    mov ax,fs
    mov es,ax
    xor ax,ax
    mov fs,ax
    pop es
    mov es:xd_input_sel,0
;
    mov al,ds:[si].cev_result
    cmp al,1
    je cdDone
;
    clc        

cdDone:
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop gs    
    pop fs
    pop es
    retf32
ConfigDevice   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WaitForControlTrb
;
;       DESCRIPTION:    Wait for empty control TRB
;
;       PARAMETERS:     DS          Function sel
;                       ES          Device sel
;
;       RETURNS:        ES:SI       TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForControlTrb   Proc near
    push ax
;    
    mov si,es:xd_control_enque

wctLoop:    
    mov ax,es:[si].trb_type
    test ax,2
    jz wctRetry
;
    xor es:[si].trb_type,1
    xor es:xd_control_pcs,1
    mov si,es:xd_control_offset
    jmp wctLoop

wctRetry:    
    xor ax,es:xd_control_pcs
    test al,1
    jnz wctOk
;
    mov ax,10
    WaitMilliSec
    jmp wfctRetry        

wctOk:
    mov ax,si
    add ax,SIZE trb_struc
    mov es:xd_control_enque,ax
;
    mov es:[si].trb_param,0
    mov es:[si].trb_param+4,0
    mov es:[si].trb_status,0
    mov es:[si].trb_control,0
;
    pop ax        
    ret
WaitForControlTrb    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupControlIn
;
;       DESCRIPTION:    Setup control IN
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupControlIn   Proc near
    pushad
;
    call WaitForControlTrb
    mov es:xd_control_trb,si
    mov eax,dword ptr es:usbd_control_buf
    mov es:[si].trb_param,eax
    mov eax,dword ptr es:usbd_control_buf+4
    mov es:[si].trb_param+4,eax
;
    mov eax,8
    mov es:[si].trb_status,eax    
;
    mov ax,TRB_TYPE_SETUP SHL 10
    or ax,es:xd_control_pcs
    or al,40h
    mov es:[si].trb_type,ax
    mov es:[si].trb_control,0
;
    mov es:xd_control_size,cx
;
    or cx,cx
    jz sciStatusOut
;
    mov es:[si].trb_control,3
    AllocateMemBlk
    mov es:xd_control_buf,edx
;
    call WaitForControlTrb
    mov es:[si].trb_param,eax
    mov es:[si].trb_param+4,ebx
;
    movzx eax,cx
    mov es:[si].trb_status,eax    
    mov ax,TRB_TYPE_DATA SHL 10
    or ax,es:xd_control_pcs
    mov es:[si].trb_type,ax
    mov es:[si].trb_control,1

sciStatusOut: 
    call WaitForControlTrb
    mov es:[si].trb_status,0
;
    mov ax,TRB_TYPE_STATUS SHL 10
    or ax,es:xd_control_pcs
    or al,20h
    mov es:[si].trb_type,ax
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
;                       CX      Size
;                       GS:EDI  Buffer
;
;       RETURNS:        CX      Size returned
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyControlIn   Proc near
    push eax
;
    mov al,es:xd_control_result
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
    movzx ecx,es:xd_control_size
    sub cx,es:xd_control_remain_size
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
    mov cx,es:xd_control_size
    sub cx,es:xd_control_remain_size
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
    call WaitForControlTrb
    mov es:xd_control_trb,si
    mov eax,dword ptr es:usbd_control_buf
    mov es:[si].trb_param,eax
    mov eax,dword ptr es:usbd_control_buf+4
    mov es:[si].trb_param+4,eax
;
    mov eax,8
    mov es:[si].trb_status,eax    
;
    mov ax,TRB_TYPE_SETUP SHL 10
    or ax,es:xd_control_pcs
    or al,40h
    mov es:[si].trb_type,ax
    mov es:[si].trb_control,0
;
    mov es:xd_control_size,cx
;
    or cx,cx
    jz scoStatusIn
;
    mov es:[si].trb_control,2
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
    call WaitForControlTrb
    mov es:[si].trb_param,eax
    mov es:[si].trb_param+4,ebx
;
    movzx eax,cx
    mov es:[si].trb_status,eax    
    mov ax,TRB_TYPE_DATA SHL 10
    or ax,es:xd_control_pcs
    mov es:[si].trb_type,ax
    mov es:[si].trb_control,0

scoStatusIn: 
    call WaitForControlTrb
    mov es:[si].trb_status,0
;
    mov ax,TRB_TYPE_STATUS SHL 10
    or ax,es:xd_control_pcs
    or al,20h
    mov es:[si].trb_type,ax
    mov es:[si].trb_control,1
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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

control_text DB 'USB Control', 0

RunControl   Proc near
    push ds
    pushad
;
    test es:usbd_flags,DEV_FLAG_DETACHED
    stc
    jnz rcDone
;
    call fword ptr ds:is_dev_connected_proc
    jc rcDone
;
    lock or es:usbd_flags,DEV_FLAG_CONTROL_ACTIVE
    mov es:xd_control_result,-1
;
    push es
    mov bx,es:usbd_wait_dev
    mov ax,cs
    mov es,ax
    mov edi,OFFSET control_text
    PrepareWaitDev
    pop es
;
    movzx esi,es:xd_slot
    shl esi,2
    add esi,ds:xhc_db_offset
    mov eax,1
    mov ds:[esi],eax
;
    GetSystemTime
    add eax,1193 * 250
    adc edx,0
    WaitForDev
    lock and es:usbd_flags,NOT DEV_FLAG_CONTROL_ACTIVE
;
    mov al,es:xd_control_result
    cmp al,1
    stc
    jnz rcDone
;
    clc

rcDone:
    popad
    pop ds
    ret
RunControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ResetControl
;
;   DESCRIPTION:    Reset control
;
;   PARAMETERS:     DS      Function selector
;                   ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetControl   Proc near
    pushad
;
    call WaitForCommandTrb
;    
    mov ds:[di].trb_param,0
    mov ds:[di].trb_param+4,0
;
    mov ah,es:xd_slot
    mov al,1
    mov ds:[di].trb_control,ax
;
    mov al,TRB_TYPE_RESET_ENDP
    call SendCommandTrb
;
    mov al,ds:[si].cev_result
    cmp al,1
    je rceOk
;
    stc
    jmp rceDone

rceOk:
    clc        

rceDone:
    popad
    ret
ResetControl   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetControlTr
;
;   DESCRIPTION:    Set control TR
;
;   PARAMETERS:     DS      Function selector
;                   ES      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetControlTr   Proc near
    pushad
;
    call WaitForCommandTrb
;
    movzx eax,es:xd_control_offset
    add eax,es:mblk_physical_base
    or al,1
    mov ds:[di].trb_param,eax
    mov eax,es:mblk_physical_base+4
    mov ds:[di].trb_param+4,eax
;
    mov ah,es:xd_slot
    mov al,1
    mov ds:[di].trb_control,ax
;
    mov al,TRB_TYPE_SET_TR
    call SendCommandTrb
;
    mov al,ds:[si].cev_result
    cmp al,1
    je sctrOk
;
    stc
    jmp sctrDone

sctrOk:
    call InitControlRing
    clc        

sctrDone:
    popad
    ret
SetControlTr   Endp
    
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
    push bx
    mov bx,es:xd_control_context_offset
    mov al,es:[bx].ec_state
    and al,7
    cmp al,2
    pop bx
    jne cmNotHalted
;
    call ResetControl
    call SetControlTr

cmNotHalted:
    mov cx,es:usbd_control_buf.usd_len
    mov es:xd_control_buf,0
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
    xchg cx,es:xd_control_size
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
;   NAME:           StopPipe
;
;   DESCRIPTION:    Stop pipe
;
;   PARAMETERS:     DS      Function selector
;                   ES      Device selector
;                   GS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopPipe   Proc near
    push eax
    push esi
    push edi
;
    lock and gs:usbp_flags,NOT PIPE_FLAG_ACTIVE
;
    call GetPipeState
    cmp al,1
    jne seDone
;
    call WaitForCommandTrb
;    
    xor eax,eax
    mov ds:[di].trb_param,eax
    mov ds:[di].trb_param+4,eax
;
    mov ah,es:xd_slot
    mov al,gs:xp_db_target
    mov ds:[di].trb_control,ax
;
    mov al,TRB_TYPE_STOP_ENDP
    call SendCommandTrb
;
    mov al,ds:[si].cev_result
    cmp al,1
    je seDone
;
    clc        

seDone:
    pop edi
    pop esi
    pop eax
    ret
StopPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           SetPipeTr
;
;   DESCRIPTION:    Set pipe TR
;
;   PARAMETERS:     DS      Function selector
;                   ES      Device selector
;                   GS      Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPipeTr   Proc near
    pushad
;
    call WaitForCommandTrb
;
    mov eax,gs:xp_ring_phys
    or al,1
    mov ds:[di].trb_param,eax
    mov eax,gs:xp_ring_phys+4
    mov ds:[di].trb_param+4,eax
;
    mov ah,es:xd_slot
    mov al,gs:xp_db_target
    mov ds:[di].trb_control,ax
;
    mov al,TRB_TYPE_SET_TR
    call SendCommandTrb
;
    mov al,ds:[si].cev_result
    cmp al,1
    je sptrOk
;
    stc
    jmp sptrDone

sptrOk:
    clc        

sptrDone:
    popad
    ret
SetPipeTr   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocatePipe
;
;       DESCRIPTION:    Allocate pipe
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;                       DL      Pipe #
;
;       RETURNS:        BX      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePipe   Proc near
    push gs
    push eax
    push ecx
    push edx
    push edi
;
    push edx
;
    push es
    mov eax,SIZE xhci_pipe
    AllocateSmallGlobalMem
    mov ax,es
    mov gs,ax
    pop es
;
    mov al,es:xd_slot
    mov gs:xp_slot,al
;
    pop edx
    movzx bx,dl
    and bl,0Fh
    add bx,bx
    test dl,80h
    jz apDirOk
;
    inc bx

apDirOk:
    mov gs:xp_db_target,bl
    call StopPipe
    mov bx,gs
;
    pop edi
    pop edx
    pop ecx
    pop eax
    pop gs
    ret
AllocatePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateIntrPipe
;
;       DESCRIPTION:    Create interrupt pipe
;
;       PARAMETERS:     ES      Device
;                       DL      Pipe #
;                       DH      Interval
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntrPipe   Proc far
    push fs
    push gs
    push eax
;   
    mov ax,flat_sel
    mov fs,ax
    call AllocatePipe
;
    pop eax
    pop gs
    pop fs
    retf32
CreateIntrPipe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateBulkPipe
;
;       DESCRIPTION:    Create bulk pipe
;
;       PARAMETERS:     ES      Device
;                       DL      Pipe #
;
;       RETURNS:        NC      OK
;                         BX    Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CreateBulkPipe   Proc far
    push fs
    push gs
    push eax
;   
    mov ax,flat_sel
    mov fs,ax
    call AllocatePipe
;
    pop eax
    pop gs
    pop fs
    retf32
CreateBulkPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreatePipeRing
;
;       DESCRIPTION:    Create pipe ring
;
;       PARAMETERS:     DS       Function sel
;                       ES       Device sel
;                       GS       Pipe sel
;                       CX       Entries (excluding link)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePipeRing   Proc near
    push es
    pushad
;
    add cx,2
    mov gs:xp_ring_entries,cx
    shl cx,4
    AllocateMemBlk
    mov gs:xp_ring_linear,edx
    mov gs:xp_ring_phys,eax
    mov gs:xp_ring_phys+4,ebx
    mov gs:xp_ring_pcs,1
;
    push eax
;
    mov ax,flat_sel
    mov es,ax
    mov edi,edx
    movzx ecx,gs:xp_ring_entries
    dec ecx
    shl ecx,2
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    pop eax
;
    mov es:[edi].trb_param,eax
    mov es:[edi].trb_param+4,ebx
    mov es:[edi].trb_status,0
    mov es:[edi].trb_type,2 + (TRB_TYPE_LINK SHL 10)
    mov es:[edi].trb_control,0
;
    popad
    pop es
    ret
CreatePipeRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreePipeRing
;
;       DESCRIPTION:    Free pipe ring
;
;       PARAMETERS:     DS       Function sel
;                       ES       Device sel
;                       GS       Pipe sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePipeRing   Proc near
    pushad
;
    mov cx,gs:xp_ring_entries
    shl cx,4
    mov edx,gs:xp_ring_linear
    FreeLinearMemBlk
;
    mov gs:xp_ring_linear,0
    mov gs:xp_ring_phys,0
    mov gs:xp_ring_phys+4,0
;
    popad
    ret
FreePipeRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AllocatePacketSel
;
;       DESCRIPTION:    Allocate TD ring
;
;       PARAMETERS:     ES      Device sel
;                       FS      Flat sel
;                       CX      Buffer count
;
;       RETURNS:        BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocatePacketSel    Proc near
    push gs
    push eax
    push ecx
    push edi
;
    inc cx
    movzx eax,cx
    shl ax,2
    add ax,SIZE usb_packet_struc
;
    push es
    AllocateSmallGlobalMem
    mov ax,es
    pop es
;
    mov gs,ax
    mov gs:usbpk_entry_count,cx
    dec cx
    mov gs:usbpk_tail_ptr,cx
;
    mov di,SIZE usb_packet_struc
    xor eax,eax

atdrLoop:
    mov gs:[di],eax
    add di,4
    loop atdrLoop
;
    mov bx,gs
;
    pop edi
    pop ecx
    pop eax
    pop gs
    ret
AllocatePacketSel       Endp

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
    pushad
;
    mov esi,gs:xp_ring_linear
    mov cx,gs:xp_ring_entries
    dec cx

sptBufLoop:
    mov eax,fs:[esi].trb_param
    or eax,fs:[esi].trb_param+4
    jnz sptBufNext
;
    push cx
    mov cx,gs:ued_maxsize
    AllocateMemBlk
    pop cx
;
    mov fs:[esi].trb_param,eax
    mov fs:[esi].trb_param+4,ebx

sptBufNext:
    movzx eax,gs:ued_maxsize
    mov fs:[esi].trb_status,eax    
;
    add esi,10h
    loop sptBufLoop
;
    mov cx,gs:xp_ring_entries
    dec cx
    sub esi,10h
    mov ax,TRB_TYPE_NORMAL SHL 10
    or al,20h
    mov fs:[esi].trb_type,ax
    mov fs:[esi].trb_control,0

sptStartLoop:
    sub esi,10h
    mov ax,TRB_TYPE_NORMAL SHL 10
    or ax,gs:xp_ring_pcs
    or al,20h
    mov fs:[esi].trb_type,ax
    mov fs:[esi].trb_control,0
    loop sptStartLoop
;
    popad
    ret
StartPacketTds     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           StartPipe
;
;       DESCRIPTION:    Start pipe
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device selector
;                       FS      Flat sel
;                       GS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartPipe     Proc near
    push eax
    push esi
;
    lock or gs:usbp_flags,PIPE_FLAG_ACTIVE
;
    movzx esi,es:xd_slot
    shl esi,2
    add esi,ds:xhc_db_offset
    movzx eax,gs:xp_db_target
    mov ds:[esi],eax
;
    pop esi
    pop eax
    ret
StartPipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FreePacketTds
;
;       DESCRIPTION:    Free TDs in ring
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device selector
;                       FS      Flat sel
;                       GS      Pipe selector
;                       BX      Packet sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePacketTds Proc near
    push gs
    pushad
;
    mov esi,gs:xp_ring_linear
    mov cx,gs:xp_ring_entries
    dec cx

fptBufLoop:
    mov eax,fs:[esi].trb_param
    mov ebx,fs:[esi].trb_param+4
    or eax,eax
    jnz fptBufFree
;
    or ebx,ebx
    jz fptBufNext

fptBufFree:
    push cx
    mov cx,gs:ued_maxsize
    FreePhysicalMemBlk
    pop cx

fptBufNext:
    add esi,10h
    loop fptBufLoop
;
    popad
    pop gs
    ret
FreePacketTds Endp

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
    push ds
    push fs
    push ax
;
    mov ax,flat_sel
    mov fs,ax
;
    call CreatePipeRing
    call AllocatePacketSel
    clc
;
    pop ax
    pop fs
    pop ds
    retf32
OpenPacket  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ClosePacket
;
;       DESCRIPTION:    Close packet
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
    call StopPipe
    call FreePacketTds
    call FreePipeRing
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
;
    mov ax,flat_sel
    mov fs,ax
;
    call StartPacketTds
    call SetPipeTr
    call StartPipe
    clc
;
    pop ax
    pop fs
    pop ds
    retf32
StartPacket  Endp

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
;
    mov ax,flat_sel
    mov fs,ax
;
    mov ds,gs:usbp_packet_sel
    mov bx,ds:usbpk_rd_ptr
    cmp bx,ds:usbpk_wr_ptr
    jne rqpkGet
;
    stc
    jmp rqpkDone

rqpkGet:
    shl bx,2
    add bx,SIZE usb_packet_struc
    xor eax,eax
    xchg eax,ds:[bx]
    mov cx,gs:ued_maxsize
    sub cx,ax
    shr eax,24
    cmp al,1
    je rqpkOk
;
    cmp al,0Dh
    stc
    jne rqpkDone

rqpkOk:
    mov edx,gs:xp_ring_linear
    movzx eax,ds:usbpk_rd_ptr
    shl eax,4
    add edx,eax
    mov eax,fs:[edx].trb_param
    mov ebx,fs:[edx].trb_param+4
    PhysicalToLinearMemBlk
    clc

rqpkDone:
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
;       DESCRIPTION:    Release packet
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
;
    mov ds,gs:usbp_packet_sel
    EnterSection ds:usbpk_section
;
    mov bx,ds:usbpk_rd_ptr
    cmp bx,ds:usbpk_wr_ptr
    stc
    je rlpkDone
;
    inc bx
    cmp bx,ds:usbpk_entry_count
    jb rlpkPtrOk
;
    xor bx,bx

rlpkPtrOk:
    mov ds:usbpk_rd_ptr,bx
;
    mov bx,ds:usbpk_tail_ptr
    mov edx,gs:xp_ring_linear
    movzx eax,bx
    shl eax,4
    add edx,eax
    xor fs:[edx].trb_type,1
;
    inc bx
    cmp bx,ds:usbpk_entry_count
    jb rlpkTailOk
;
    xor bx,bx
    add edx,10h
    xor fs:[edx].trb_type,1

rlpkTailOk:
    mov ds:usbpk_tail_ptr,bx
    clc

rlpkDone:
    LeaveSection ds:usbpk_section
;
    popad
    pop fs
    pop ds
;
    call StartPipe
    retf32
RelPacket   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupRawTds
;
;       DESCRIPTION:    Setup raw TDs
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device selector
;                       GS      Pipe selector
;                       EBX:EAX Buffer physical address
;                       ECX     Buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupRawTds     Proc near
    push fs
    pushad
;
    mov bp,flat_sel
    mov fs,bp
;
    mov esi,gs:xp_ring_linear
    mov bp,gs:xp_ring_entries
    dec bp

srtBufLoop:
    mov fs:[esi].trb_param,eax
    mov fs:[esi].trb_param+4,ebx
    mov fs:[esi].trb_status,ecx
;
    mov dx,TRB_TYPE_NORMAL SHL 10
    or dl,20h
    mov fs:[esi].trb_type,dx
    mov fs:[esi].trb_control,0
;
    add esi,10h
    sub bp,1
    jnz srtBufLoop
;
    popad
    pop fs
    ret
SetupRawTds    Endp

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
    push fs
    push eax
    push ecx
    push edx
    push ebp
;
    push es
    mov eax,SIZE xhci_raw_struc
    AllocateSmallGlobalMem
;
    mov bp,es
    mov es:xr_pos,0
    pop es
;
    mov ax,cx
    xor dx,dx
    dec ax
    add ax,gs:ued_maxsize
    cmp ax,1000h
    jbe orInRange
;
    mov ax,1000h

orInRange:
    div gs:ued_maxsize
    mul gs:ued_maxsize
    mov cx,ax
;
    push gs
;
    mov gs,bp
    mov gs:usbr_buf_size,cx
;
    AllocateMemBlk
    mov gs:usbr_buf_linear,edx
;
    push bx
    AllocateGdt
    movzx ecx,cx
    CreateDataSelector16
    mov gs:usbr_buf_sel,bx
    pop bx
;
    pop gs
;
    push cx
    mov cx,3
    call CreatePipeRing
    pop cx
;
    call SetupRawTds
    call SetPipeTr

orDone:
    mov bx,bp
;
    pop ebp
    pop edx
    pop ecx
    pop eax
    pop fs
    retf32
OpenRaw  Endp

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
    call StopPipe
    call FreePipeRing
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
    push fs
    pushad
;
    mov fs,gs:usbp_raw_sel
    mov fs:xr_res,0
;
    movzx esi,fs:xr_pos
    shl esi,4
    add esi,gs:xp_ring_linear
    movzx ecx,cx
;
    mov ax,flat_sel
    mov fs,ax
    mov fs:[esi].trb_status,ecx
    xor fs:[esi].trb_type,1
;
    call StartPipe
;
    popad
    pop fs
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
;                       EDX     Linear buffer
;                       CX      Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteRaw   Proc far
    push fs
    pushad
;
    mov fs,gs:usbp_raw_sel
    mov fs:xr_res,0
;
    movzx esi,fs:xr_pos
    shl esi,4
    add esi,gs:xp_ring_linear
    movzx ecx,cx
;
    mov ax,flat_sel
    mov fs,ax
    mov fs:[esi].trb_status,ecx
    xor fs:[esi].trb_type,1
;
    call StartPipe
;
    popad
    pop fs
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
    push esi
;
    mov fs,gs:usbp_raw_sel
    mov al,fs:xr_res
    or al,al
    jnz frEval
;
    call StopPipe
    mov ax,25
    WaitMilliSec
    stc
    jmp frDone

frEval:
    lock and gs:usbp_flags,NOT PIPE_FLAG_ACTIVE
;
    mov ax,flat_sel
    mov fs,ax
    mov ds,gs:usbp_raw_sel
;
    mov bx,ds:xr_pos
    movzx esi,bx
    shl esi,4
    add esi,gs:xp_ring_linear
    mov ecx,fs:[esi].trb_status
;
    inc bx
    mov ax,gs:xp_ring_entries
    dec ax
    cmp bx,ax
    jb frPtrOk
;
    movzx esi,bx
    shl esi,4
    add esi,gs:xp_ring_linear
    xor fs:[esi].trb_type,1
;
    xor bx,bx

frPtrOk:
    mov ds:xr_pos,bx
    sub cx,ds:xr_remain
;
    mov al,ds:xr_res
    cmp al,1
    je frOk
;
    cmp al,0Dh
    stc
    jne frDone

frOk:
    clc

frDone:
    pop esi
    pop ebx
    pop eax
    pop fs
    pop ds
    retf32
FinishRaw   Endp

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
;       NAME:           UnlinkPipes
;
;       DESCRIPTION:    Unlink pipes
;
;       PARAMETERS:     ES      Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlinkPipes   Proc far
    push fs
    push gs
    pushad
;
    mov ax,flat_sel
    mov fs,ax
;
    mov cx,15
    mov si,OFFSET usbd_in_pipe_arr

udvInLoop:
    mov bx,es:[si]
    or bx,bx
    jz udvInNext
;
    mov gs,bx
    call StopPipe

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
    mov gs,bx
    call StopPipe

udvOutNext:
    add si,2
    loop udvOutLoop
;
    movzx si,es:usbd_address
    add si,si
    mov ds:[si].xhc_slot_sel_arr,0
;
    popad
    pop gs
    pop fs
    retf32
UnlinkPipes   Endp

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
    retf32
DisableDev Endp
        
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
;       NAME:           ReportPipeStatus
;
;       DESCRIPTION:    Report pipe status
;
;       PARAMETERS:     DS      Function selector
;                       FS      Device sel
;                       AL      Status
;                       DL      Pipe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rpTable:
r00 DW 0
r01 DW 0
r02 DW USB_EVENT_DATA_BUFFER_ERROR
r03 DW USB_EVENT_BABBLE
r04 DW USB_EVENT_TRANS_ERROR
r05 DW USB_EVENT_TRB_ERROR
r06 DW USB_EVENT_STALL
r07 DW 0
r08 DW USB_EVENT_BANDWIDTH_ERROR
r09 DW USB_EVENT_NO_SLOTS
r10 DW 0
r11 DW USB_EVENT_SLOT_NOT_ENABLED
r12 DW USB_EVENT_PIPE_NOT_ENABLED
r13 DW 0
r14 DW 0
r15 DW 0
r16 DW 0
r17 DW 0
r18 DW 0
r19 DW 0
r20 DW USB_EVENT_NO_PING

ReportPipeStatus   Proc near
    push es
    push fs
    push ax
    push si
;
    mov si,fs
    mov es,si
    mov si,flat_sel
    mov fs,si
;
    movzx si,al
    xor ax,ax
    cmp si,20
    ja rpsReport
;
    add si,si
    mov ax,word ptr cs:[si].rpTable

rpsReport:    
    or ax,ax
    jnz rpsCodeOk
;
    mov ax,USB_EVENT_UNKNOWN

rpsCodeOk:
    movzx si,es:usbd_port
    ReportUsbPipeEvent
;
    pop si
    pop ax
    pop fs
    pop es
    ret
ReportPipeStatus   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReportFunctionStatus
;
;       DESCRIPTION:    Report function status
;
;       PARAMETERS:     DS      Function selector
;                       AL      Status
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReportFunctionStatus   Proc near
    push fs
    push ax
    push si
;
    mov si,flat_sel
    mov fs,si
;
    movzx si,al
    xor ax,ax
    cmp si,20
    ja rfsReport
;
    add si,si
    mov ax,word ptr cs:[si].rpTable

rfsReport:    
    or ax,ax
    jnz rfsCodeOk
;
    mov ax,USB_EVENT_CONTROLLER_ERROR

rfsCodeOk:
    ReportUsbFunctionEvent
;
    pop si
    pop ax
    pop fs
    ret
ReportFunctionStatus   Endp

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
    mov eax,es:[si]
    mov ebx,es:[si+4]
    sub eax,ds:xhc_crcr
    jc ceDone
;
    sbb ebx,ds:xhc_crcr+4
    jnz ceDone
;
    cmp ax,16 * CMD_COUNT
    ja ceDone
;
    shr ax,2
    mov di,ax
    add di,OFFSET xhc_cmd_arr
;
    mov al,es:[si+11]
    cmp al,1
    je ceNotError
;
    call ReportFunctionStatus

ceNotError:
    mov ds:[di].cev_result,al
;
    mov al,es:[si+15]
    mov ds:[di].cev_slot,al
;
    xor bx,bx
    xchg bx,ds:[di].cev_thread
    Signal

ceDone:
    ret
command_event Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ControlEvent
;
;       DESCRIPTION:    Control event
;
;       PARAMETERS:     DS     Function sel
;                       ES:SI  Event TRB
;                       FS     Device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ControlEvent Proc near
    mov ax,es:[si+8]
    mov fs:xd_control_remain_size,ax
    mov al,es:[si+0Bh]
    mov fs:xd_control_result,al
    cmp al,1
    je cevNotError
;
    xor dl,dl
    call ReportPipeStatus

cevNotError:
    mov eax,es:[si]
    mov edx,es:[si+4]
    sub eax,fs:mblk_physical_base
    sbb edx,fs:mblk_physical_base+4
    jnz cevDone
;
    cmp eax,1000h
    jae cevDone
;
    sub ax,fs:xd_control_offset
    jc cevDone
;
    cmp eax,40h
    jae cevDone
;
    mov di,ax
    add di,fs:xd_control_offset
    add di,SIZE trb_struc
    mov ax,fs:[di].trb_type
    test ax,2
    jz cevSave
;
    mov di,fs:xd_control_offset

cevSave:
    mov fs:xd_control_deque,di
;
    test fs:usbd_flags,DEV_FLAG_CONTROL_ACTIVE
    jz cevDone
;
    mov bx,fs:usbd_wait_dev
    SignalWaitDev

cevDone:
    ret
ControlEvent Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandlePacketIn
;
;       DESCRIPTION:    Handle packet IN pipe
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       BX      Packet sel
;                       ECX     Status
;                       EDX     TRB linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandlePacketIn   Proc near
    push ds
    push ebx
    push edx
;
    mov ds,bx
    EnterSection ds:usbpk_section
;
    sub edx,gs:xp_ring_linear
    jc hpiLeave
;
    shr edx,4
    movzx eax,ds:usbpk_entry_count
    cmp edx,eax
    jae hpiLeave
;
    mov bx,dx
    shl bx,2
    add bx,SIZE usb_packet_struc
    mov ds:[bx],ecx
;
    inc dx
    cmp dx,ds:usbpk_entry_count
    jb hpiSave
;
    xor dx,dx

hpiSave:
    mov ds:usbpk_wr_ptr,dx
;
    mov eax,ecx
    shr eax,24
    cmp al,1
    je hpiNotError
;
    cmp al,0Dh
    je hpiNotError
;
    mov dl,gs:ued_address
    call ReportPipeStatus

hpiNotError:
    xor bx,bx
    xchg bx,gs:usbp_wait
    or bx,bx
    jz hpiLeave
;
    push es
    mov es,bx
    SignalWait
    pop es

hpiLeave:
    LeaveSection ds:usbpk_section
;
    pop edx
    pop ebx
    pop ds
    ret
HandlePacketIn Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           HandleRaw
;
;       DESCRIPTION:    Handle raw packet
;
;       PARAMETERS:     DS      Function selector
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       BX      Raw sel
;                       ECX     Status
;                       EDX     TRB linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleRaw   Proc near
    push ds
    push eax
    push ebx
    push ecx
    push edx
    push ebp
;
    mov ebp,ds
    mov ds,bx
    mov bx,ds:usbr_wait_dev
;
    sub edx,gs:xp_ring_linear
    jc hrDone
;
    shr edx,4
    movzx eax,ds:xr_pos
    cmp edx,eax
    je hrHandle
;
    mov ds,ebp
    mov dl,gs:ued_address
    movzx ebx,dl
    shl ebx,4
    add ebx,ds:xhc_port_offset
;    
    mov eax,ds:[ebx]
    test al,1
    jz hrDone
;
    and eax,0EE03E1h
    or al,10h
    mov ds:[ebx],eax
    jmp hrDone

hrHandle:
    mov ds:xr_remain,cx
;
    mov eax,ecx
    shr eax,24
    mov ds:xr_res,al
;
    cmp al,1
    je hrNotError
;
    cmp al,0Dh
    je hrNotError
;
    mov dl,gs:ued_address
    call ReportPipeStatus

hrNotError:
    SignalWaitDev

hrDone:
    pop ebp
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds
    ret
HandleRaw Endp

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
;                       ECX     Status
;                       EDX     TRB linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckIn   Proc near
    push bx
;
    mov bx,gs:usbp_packet_sel
    or bx,bx
    jz citNotPacket
;
    call HandlePacketIn
    jmp citDone

citNotPacket:
    mov bx,gs:usbp_raw_sel
    or bx,bx
    jz citDone
;
    call HandleRaw

citDone:
    pop bx
    ret
CheckIn   Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CheckOut
;
;       DESCRIPTION:    Check OUT pipe
;
;       PARAMETERS:     DS      Function sel
;                       ES      Device sel
;                       FS      Flat sel
;                       GS      Pipe sel
;                       ECX     Status
;                       EDX     TRB linear
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckOut   Proc near
    push bx
;
    mov bx,gs:usbp_raw_sel
    or bx,bx
    jz cotDone
;
    call HandleRaw

cotDone:
    pop bx
    ret
CheckOut   Endp

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
    push es
    push esi
;
    mov al,es:[si+0Fh]
    movzx bx,al
    shl bx,1
    mov ax,ds:[bx].xhc_slot_sel_arr
    or ax,ax
    jz teDone
;
    mov fs,ax
    mov al,es:[si+0Eh]
    cmp al,1
    jne tePipe

teControl:
    call ControlEvent
    jmp teDone

tePipe:
    push fs
    mov eax,es:[si].trb_param
    mov ebx,es:[si].trb_param+4
    mov ecx,es:[si].trb_status
    mov si,es:[si+0Eh]
    pop es
    PhysicalToLinearMemBlk
;
    mov bx,si
    mov bh,bl
    shr bl,1
    test bh,1
    jz teOut

teIn:
    movzx bx,bl
    dec bx
    add bx,bx
    mov ax,es:[bx].usbd_in_pipe_arr
;
    or ax,ax
    jz teDone
;
    mov gs,ax
    call CheckIn

teOut:
    movzx bx,bl
    dec bx
    add bx,bx
    mov ax,es:[bx].usbd_out_pipe_arr
;
    or ax,ax
    jz teDone
;
    mov gs,ax
    call CheckOut

teDone:    
    pop esi
    pop es
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
    mov dl,es:[si+3]
    or dl,dl
    jz peDone
;
    dec dl
    cmp dl,ds:xhc_port_count
    jae peDone
;
    push esi
    xor bx,bx
    movzx esi,dl
    shl esi,4
    add esi,ds:xhc_port_offset
    mov eax,ds:[esi]
    NotifyUsbPortState
    and eax,0EE03E1h
    mov ds:[esi],eax
    pop esi

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
;           NAME:           SetPortPower
;
;           DESCRIPTION:    Turn on power on port
;
;       PARAMETERS:         DS  Function sel
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
;           NAME:           EventThread
;
;           DESCRIPTION:    Event thread
;
;       PARAMETERS:         BX  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xhci_name   DB 'XHCI ', 0

event_thread:
    mov ds,bx
    mov es,ds:xhc_intr_sel
    GetThread
    mov es:ev_thread,ax
    mov es:ev_flag,0
;
    xor cl,cl

etPowerLoop:    
    call SetPortPower

etPowerNext:
    inc cl
    cmp cl,ds:xhc_port_count
    jb etPowerLoop
;
    mov es:ev_ccs,1
    mov si,es:ev_hdr_size

etWait:
    mov es:ev_flag,0
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
    xor al,al
    stosb
;
	xor edi,edi
    mov bx,ds:xhc_pci_handle
    LockPciHandle
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
;       RETURNS:        CY           Activity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

XhciInt Proc far 
    mov al,1
    xor al,ds:ev_flag
    or al,al
    clc
    jz xiDone
;
    mov bx,ds:ev_thread
    Signal
    stc

xiDone:
    retf32
XhciInt Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupIrq
;
;       DESCRIPTION:    Setup IRQs
;
;       PARAMETERS:     DS          Function sel
;                       BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupIrq  Proc near
    push ds
    push es
    push ebx
    push esi
    push edi
;    
    mov al,14h
    mov di,ds:xhc_intr_sel
    mov ds,di
    mov di,cs
    mov es,di
    mov edi,OFFSET XhciInt
    SetupPciHandleIrq
;
    pop edi
    pop esi
    pop ebx
    pop es
    pop ds
    ret
SetupIrq  Endp

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
    mov es:ev_flag,0
;
    popad    
    ret
CreateEventRing   Endp   

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
    or al,al
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
et02 DD OFFSET PowerOffPort,        SEG code
et03 DD OFFSET PowerOnPort,         SEG code
et04 DD OFFSET ResetPort,           SEG code
et05 DD OFFSET DisablePort,         SEG code
et06 DD OFFSET DisableDev,          SEG code
et07 DD OFFSET IsPortConnected,     SEG code
et08 DD OFFSET IsRunning,           SEG code
et09 DD OFFSET AllocateAddress,     SEG code
et0A DD OFFSET FreeAddress,         SEG code
et0B DD OFFSET CreateDev,           SEG code
et0C DD OFFSET UnlinkPipes,         SEG code
et0D DD OFFSET IsDeviceConnected,   SEG code
et0E DD OFFSET FreeDev,             SEG code
et0F DD OFFSET CreateControl,       SEG code
et10 DD OFFSET CreateBulkPipe,      SEG code
et11 DD OFFSET CreateIntrPipe,      SEG code
et12 DD OFFSET AddressDevice,       SEG code
et13 DD OFFSET ChangeAddress,       SEG code
et14 DD OFFSET UpdateMaxLen,        SEG code
et15 DD OFFSET ControlMsg,          SEG code
et16 DD OFFSET ConfigDevice,        SEG code
et17 DD OFFSET OpenPacket,          SEG code
et18 DD OFFSET ClosePacket,         SEG code
et19 DD OFFSET StartPacket,         SEG code
et1A DD OFFSET ReqPacket,           SEG code
et1B DD OFFSET RelPacket,           SEG code
et1C DD OFFSET OpenRaw,             SEG code
et1D DD OFFSET CloseRaw,            SEG code
et1E DD OFFSET ReadRaw,             SEG code
et1F DD OFFSET WriteRaw,            SEG code
et20 DD OFFSET FinishRaw,           SEG code

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
    call SetupIrq
    mov ds:xhc_pci_handle,bx
;
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
    mov es,ds:xhc_intr_sel
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
    mov cx,2*21h

ifTabLoop:
    lods dword ptr cs:[si]
    stosd
    loop ifTabLoop    
;
    InitUsbFunction
;
    call CreateEventThread
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

CalcRegSize     Proc near
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
    shr eax,16
    shl eax,2
    mov es:par_cap_offset,eax
;
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
    mov eax,es:par_cap_offset
    or eax,eax
    jz crsCapOk
;
    add eax,100h
    cmp ecx,eax
    ja crsCapOk
;
    mov ecx,eax

crsCapOk:
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
CalcRegSize     Endp

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

CreateFuncSel   Proc near
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

InitFuncSel     Proc near
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
    mov al,es:par_slot_count
    mov ds:xhc_slot_count,al
;
    mov al,es:par_port_count
    mov ds:xhc_port_count,al
;
    movzx ax,es:par_slot_size
    mov ds:xhc_context_size,ax
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
    mov ds:xhc_cmd_enque,CMD_OFFSET
    mov ds:xhc_cmd_pcs,1
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
    test byte ptr ds:[ebx+2],1
    jz bhDone

bhRetry:
    or byte ptr ds:[ebx+3],1
;
    mov ax,25
    WaitMilliSec
;
    test byte ptr ds:[ebx+2],1
    jnz bhRetry
;
    test byte ptr ds:[ebx+3],1
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
    mov ds:xhc_intr_sel,es
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

DevName   DB 'XHCI', 0

InitPciAdapter  Proc near
    mov ax,cs
    mov es,ax
    xor bx,bx
    
init_pci_loop:    
    mov ah,0Ch
    mov al,3
    mov dl,30h
    FindPciProtocolHandle
    jc init_pci_done
;
    xor al,al
    GetPciBarPhys
    jc init_pci_loop
;
    mov edi,OFFSET DevName
    LockPciHandle
;    
    call CreateFunction
    jc init_pci_loop
;
    call AddFunction
    jmp init_pci_loop
    
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
