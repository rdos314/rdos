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

xhc_slot_count      DW ?
xhc_port_count      DW ?

xhc_context_size    DW ?
xhc_dcba            DD ?,?
xhc_crcr            DD ?,?
xhc_erst            DD ?,?
xhc_edqe            DD ?,?

xhc_cmd_enque       DW ?
xhc_cmd_pcs         DW ?

xhc_event_thread    DW ?
xhc_cmd_section     section_typ <>
xhc_event_ccs       DW ?

xhc_port_thread     DW ?

xhci_func_sel   ENDS

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
;           NAME:           CreateControl
;
;           DESCRIPTION:    Create control pipe
;
;       PARAMETERS:     DS      Device selector
;                       ES      Function selector
;                       AH      Speed
;
;       RETURNS:    FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControl   Proc far
    int 3
    stc
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
    int 3
    stc
    retf32
CreateBulk   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           CreateIntr
;
;   DESCRIPTION:    Create interrupt pipe
;
;   PARAMETERS:     DS      Function selector
;                   AL      Interval
;                   AH      Speed
;
;   RETURNS:        FS      Pipe selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateIntr   Proc far
    int 3
    stc
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
    int 3
    stc
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
    int 3
    stc
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
    int 3
    stc
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
    int 3
    stc
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
    int 3
    stc
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
    int 3
    stc
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
;       RETURNS:    NC      Transfer is done
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IsTransferDone   Proc far
    int 3
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
    int 3
    stc
    retf32
WaitForCompletion   Endp

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
    int 3
    stc
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
    int 3
    stc
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
    int 3
    stc
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
    int 3
    stc
    retf32
ClosePipe   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;   NAME:           ChangeAddress
;
;   DESCRIPTION:    Change address for pipe
;
;   PARAMETERS:     DS      Function selector
;                   FS      Pipe selector
;                   AL      Address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ChangeAddress   Proc far
    int 3
    stc
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
    int 3
    stc
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
    int 3
    stc
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
;           NAME:           AllocateHubPort
;
;           DESCRIPTION:    Allocate Hub port
;
;       PARAMETERS:         DS      Function selector
;                           GS      Hub Selector
;                           DX      Hub port
;
;       RETURNS:            AL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AllocateHubPort   Proc far
    int 3
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
;                           AL      Port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeHubPort   Proc far
    int 3
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
    int 3
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
    int 3
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
    int 3
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
    and dx,3E0h
    add ax,dx    
    or ax,ax
    jz cspDone
;
    int 3    
    
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
    AllocatePhysical64
    mov es:xhc_crcr,eax
    mov es:xhc_crcr+4,ebx
;
    mov al,13h
    SetPageEntry
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
;       RETURNS:        GS:EDI      TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForCommandTrb   Proc near
    push ds
    push ax
;
    mov ax,es
    mov ds,ax
    EnterSection ds:xhc_cmd_section    
;    
    mov gs,es:xhc_cmd_ring_sel
    movzx edi,es:xhc_cmd_enque

wfctLoop:    
    mov ax,gs:[di].trb_type
    test ax,2
    jz wfctRetry
;
    xor gs:[di].trb_type,1
    xor es:xhc_cmd_pcs,1
    xor di,di
    jmp wfctLoop

wfctRetry:    
    xor ax,es:xhc_cmd_pcs
    test al,1
    jnz wfctOk
;
    mov ax,10
    WaitMilliSec
    jmp wfctRetry        

wfctOk:
    mov ax,di
    add ax,SIZE trb_struc
    mov es:xhc_cmd_enque,ax
;
    mov gs:[di].trb_param,0
    mov gs:[di].trb_param+4,0
    mov gs:[di].trb_status,0
    mov gs:[di].trb_control,0
;
    pop ax        
    pop ds
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
;                       GS:EDI  TRB offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendCommandTrb   Proc near
    push ds
    push eax
;    
    push ax
    GetThread
    mov gs:[edi+1000h].cmd_thread,ax
    pop ax
;
    movzx ax,al
    shl ax,10
    or ax,es:xhc_cmd_pcs
    mov gs:[edi].trb_type,ax
;
    mov ds,es:xhc_db_sel
    xor eax,eax
    mov ds:[0],eax
;
    mov ax,es
    mov ds,ax
    LeaveSection ds:xhc_cmd_section    

sctWait:
    WaitForSignal
    mov ax,gs:[edi+1000h].cmd_thread
    or ax,ax
    jnz sctWait
;
    pop eax
    pop ds        
    ret
SendCommandTrb  Endp

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
    movzx di,cl
    shl di,4
    mov fs,es:xhc_port_sel
    mov eax,fs:[di]
    mov fs:[di],eax
;
    mov bx,es:xhc_port_thread
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
evt20 DW OFFSET error_event
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
    mov es:xhc_port_thread,ax

ptLoop:
    WaitForSignal
    jmp ptLoop    

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
et00 DD OFFSET CreateControl,       SEG code
et01 DD OFFSET CreateBulk,          SEG code
et02 DD OFFSET CreateIntr,          SEG code
et03 DD OFFSET AddSetup,        SEG code
et04 DD OFFSET AddOut,          SEG code
et05 DD OFFSET AddIn,           SEG code
et06 DD OFFSET AddStatusOut,    SEG code
et07 DD OFFSET AddStatusIn,         SEG code
et08 DD OFFSET IssueTransfer,       SEG code
et09 DD OFFSET IsTransferDone,      SEG code
et10 DD OFFSET EndTransfer,     SEG code
et11 DD OFFSET WasTransferOk,       SEG code
et12 DD OFFSET GetDataSize,     SEG code
et13 DD OFFSET ClosePipe,       SEG code
et14 DD OFFSET WaitForCompletion,   SEG code
et15 DD OFFSET ChangeAddress,       SEG code
et16 DD OFFSET IsConnected,     SEG code
et17 DD OFFSET ResetPipe,       SEG code
et18 DD OFFSET LockEnum,        SEG code
et19 DD OFFSET UnlockEnum,      SEG code
et20 DD OFFSET AllocateHubPort, SEG code
et21 DD OFFSET FreeHubPort,     SEG code
et22 DD OFFSET Has64Bit,        SEG code
et23 DD OFFSET IsStalled,       SEG code
et24 DD OFFSET ClearStalled,    SEG code
et25 DD OFFSET GetMaxLen,       SEG code

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
    or ax,200h
    mov ds:orsConfig,eax
;
    push es
    mov cx,es:xhc_slot_count
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
    mov cx,2*26

ifTabLoop:
    lods dword ptr cs:[si]
    stosd
    loop ifTabLoop    
;
    mov ax,es
    mov ds,ax
    InitUsbDevice

ifDone:
    popad
    pop fs
    pop es
    ret
InitFunction    Endp

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
    mov ecx,20h
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
    mov eax,SIZE xhci_func_sel
    mov cx,ax
    AllocateSmallGlobalMem
    xor di,di
    xor al,al
    rep stosb
;
    mov al,ds:[4]
    movzx ax,al
    mov es:xhc_slot_count,ax
;
    mov al,ds:[7]
    cmp al,0B0h
    jb cpfPortsOk
;
    mov al,0B0h

cpfPortsOk:    
    movzx ax,al
    mov es:xhc_port_count,ax
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
    mov eax,1000h
    AllocateBigLinear
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
    mov ecx,1000h
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
    mov eax,SIZE xhci_func_sel
    mov cx,ax
    AllocateSmallGlobalMem
    xor di,di
    xor al,al
    rep stosb
;
    mov al,ds:[4]
    movzx ax,al
    mov es:xhc_slot_count,ax
;
    mov al,ds:[7]
    cmp al,0B0h
    jb csfPortsOk
;
    mov al,0B0h

csfPortsOk:    
    movzx ax,al
    mov es:xhc_port_count,ax
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
    mov eax,1000h
    AllocateBigLinear
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
    mov cl,10h
    ReadPciDword
    and ax,0F000h
    cmp eax,ebp
    je init_pci_done
;       
    call CreateSecondaryFunction
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
