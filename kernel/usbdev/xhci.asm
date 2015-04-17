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

xhc_slot_count      DW ?
xhc_int_count       DW ?
xhc_port_count      DW ?

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
;           NAME:           InitFunction
;
;           DESCRIPTION:    Init EHCI function
;
;       PARAMETERS:     DS      Function selector
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

;
;           PARAMETERS:         BH          Bus
;                           BL          Device
;                           CH          Function
;               AL      Capability

InitFunction    Proc near
    push es
    push fs
    pushad
;
    int 3
    mov ax,flat_sel
    mov es,ax   
;    
    mov si,OFFSET xhci_tab
    xor di,di
    mov cx,2*26

ifTabLoop:
    lods dword ptr cs:[si]
    mov ds:[di],eax
    add di,4
    loop ifTabLoop    
;
    InitUsbDevice
    int 3

ifDone:
    popad
    pop fs
    pop es
    ret
InitFunction    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateFunction
;
;       DESCRIPTION:    Create XHCI function
;
;       PARAMETERS:     EDX:EAX Register base
;
;       RETURNS:        NC      OK
;                           ES  Function selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFunction  Proc near
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
    jnz cf64Ok
;
    HasPhysical64
    jnc cfFail

cf64Ok:        
    mov eax,SIZE xhci_func_sel
    mov cx,ax
    AllocateSmallGlobalMem
    xor di,di
    xor al,al
    rep stosb
    int 3
;
    mov al,ds:[4]
    movzx ax,al
    mov es:xhc_slot_count,ax
;
    mov ax,ds:[5]
    and ax,3FFh
    mov es:xhc_int_count,ax
;
    mov al,ds:[7]
    cmp al,0B0h
    jb cfPortsOk
;
    mov al,0B0h

cfPortsOk:    
    movzx ax,al
    mov es:xhc_port_count,ax
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
    mov ds,bx
    mov es:xhc_port_sel,ds        
    clc
    jmp cfDone

cfFail:    
    mov bx,ds
    xor ax,ax
    mov ds,ax
    FreeGdt
    pop eax
    pop edx
    stc

cfDone:
    popad
    pop ds
    ret
CreateFunction Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AddFunction
;
;           DESCRIPTION:    Add EHCI function
;
;       PARAMETERS:     BX      Bus/device
;                       CH      Function
;                       EDX:EAX Register base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFunction  Proc near
    push es
    call CreateFunction
    jc afDone

afDone:
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
    mov ch,30h
    FindPciClass
    jc init_pci_done
;
    int 3
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
    call AddFunction
;
    mov dx,1

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
    call AddFunction
    inc dx
    jmp init_pci_next_device
    
init_pci_done:
    ret
InitPciAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           XHCI thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xhci_name       DB 'XHCI',0

xhci_thread:
    call InitPciAdapter
    int 3

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
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET xhci_name
    mov si,OFFSET xhci_thread
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
