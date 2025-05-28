;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; 88E80xx.ASM
; Marvell 88E80xx series network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\acpi\pci.inc
INCLUDE ..\os\net.inc

MemControlReg   = 4
PowerControlReg = 7

RxPfuControlReg = 450h
RxPfuLastIndex  = 454h
RxPfuListBase   = 458h

TxPfuControlReg = 6D0h
TxPfuLastIndex  = 6D4h
TxPfuListBase   = 6D8h

RxBmuControlReg = 434h
TxBmuControlReg = 6B4h

RxMacControlReg = 0C48h
TxMacControlReg = 0D48h

StatusBmuControlReg = 0E80h
StatusBmuLastIndex  = 0E84h
StatusBmuListBase   = 0E88h

MacControlReg   = 0F00h
PhyControlReg   = 0F04h
LinkControlReg  = 0F10h
 
data    STRUC

MemSel              DW ?

StatusBmuPhys       DD ?
StatusBmuSel        DW ?

RxPfuPhys           DD ?
RxPfuSel            DW ?

TxPfuPhys           DD ?
TxPfuSel            DW ?

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
;       NAME:           InitBase
;
;       DESCRIPTION:    Init base memory
;
;       PARAMETERS:     BH:BL:CH    PCI address
;                       DS          Ethernet selector
;
;       RETURNS:        ES          Base mem selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitBase    Proc near
    mov cx,PCI_nbr_base_address0+4
    ReadPciDword
;
    push eax
    mov cx,PCI_nbr_base_address0
    ReadPciDword
    pop ebx
    test al,4
    jnz ibPhysOk
;
    xor ebx,ebx

ibPhysOk:
    push eax
    mov eax,4000h
    AllocateBigLinear
    pop eax
    xor al,al
    or ax,13h
;
    mov ecx,4    

ibPhysLoop:
    SetPageEntry
;
    add eax,1000h
    adc ebx,0
    add edx,1000h
    loop ibPhysLoop    
;        
    AllocateGdt
    mov ecx,4000h
    sub edx,ecx
    CreateDataSelector16
;
    mov ds:MemSel,bx
    mov es,bx
    ret
InitBase    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitStatusBmu
;
;       DESCRIPTION:    Init status BMU descriptors
;
;       PARAMETERS:     DS          Ethernet sel
;                       ES          Base mem selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitStatusBmu    Proc near
    mov eax,es:StatusBmuControlReg
    and al,0E0h
    or al,16h
    mov es:StatusBmuControlReg,eax
;
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    mov ds:StatusBmuPhys,eax
    or al,13h
    SetPageEntry
;
    push es
    mov ax,flat_sel
    mov es,ax    
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop es
;
    mov ecx,0FFFh
    AllocateGdt
    CreateDataSelector16
    mov ds:StatusBmuSel,bx
;
    mov word ptr es:StatusBmuLastIndex,0FFFh
    mov eax,ds:StatusBmuPhys
    mov es:StatusBmuListBase,eax
    mov dword ptr es:StatusBmuListBase+4,0
;    
    mov eax,es:StatusBmuControlReg
    and al,0F0h
    or al,0Ah
    mov es:StatusBmuControlReg,eax    
    ret
InitStatusBmu   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitRxPfu
;
;       DESCRIPTION:    Init Rx prefetch unit
;
;       PARAMETERS:     DS          Ethernet sel
;                       ES          Base mem selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRxPfu    Proc near
    mov eax,es:RxPfuControlReg
    and al,0FCh
    or al,2
    mov es:RxPfuControlReg,eax
;
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    mov ds:RxPfuPhys,eax
    or al,13h
    SetPageEntry
;
    push es
    mov ax,flat_sel
    mov es,ax    
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop es
;
    mov ecx,0FFFh
    AllocateGdt
    CreateDataSelector16
    mov ds:RxPfuSel,bx
;
    mov word ptr es:RxPfuLastIndex,0FFFh
    mov eax,ds:RxPfuPhys
    mov es:RxPfuListBase,eax
    mov dword ptr es:RxPfuListBase+4,0
;    
    mov eax,es:RxPfuControlReg
    and al,0F0h
    or al,0Ah
    mov es:RxPfuControlReg,eax    
    ret
InitRxPfu   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitTxPfu
;
;       DESCRIPTION:    Init Tx prefetch unit
;
;       PARAMETERS:     DS          Ethernet sel
;                       ES          Base mem selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTxPfu    Proc near
    mov eax,es:TxPfuControlReg
    and al,0FCh
    or al,2
    mov es:TxPfuControlReg,eax
;
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    mov ds:TxPfuPhys,eax
    or al,13h
    SetPageEntry
;
    push es
    mov ax,flat_sel
    mov es,ax    
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
    pop es
;
    mov ecx,0FFFh
    AllocateGdt
    CreateDataSelector16
    mov ds:TxPfuSel,bx
;
    mov word ptr es:TxPfuLastIndex,0FFFh
    mov eax,ds:TxPfuPhys
    mov es:TxPfuListBase,eax
    mov dword ptr es:TxPfuListBase+4,0
;    
    mov eax,es:TxPfuControlReg
    and al,0F0h
    or al,0Ah
    mov es:TxPfuControlReg,eax    
    ret
InitTxPfu   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitController
;
;       DESCRIPTION:    Init controller
;
;       PARAMETERS:     ES          Base mem selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitController    Proc near
    mov eax,es:MemControlReg
    and al,0F0h
    or al,0Ah
    mov es:MemControlReg,eax
;
    mov ax,10
    WaitMilliSec
;
    mov al,es:PowerControlReg
    and al,0F0h
    or al,6
    mov es:PowerControlReg,al
;    
    call InitStatusBmu
    call InitRxPfu
    call InitTxPfu
;    
    mov ax,5D66h
    mov es:RxBmuControlReg,ax
;
    mov ax,10
    WaitMilliSec
;    
    mov ax,51AAh
    mov es:RxBmuControlReg,ax
;    
    mov eax,es:TxBmuControlReg
    mov ax,1D66h
    mov es:TxBmuControlReg,eax
;
    mov ax,10
    WaitMilliSec
;    
    mov eax,es:TxBmuControlReg
    mov ax,11AAh
    mov es:TxBmuControlReg,eax
    int 3
;
    mov al,es:LinkControlReg
    and al,0FCh
    or al,2
    mov es:LinkControlReg,al
;
    mov ax,10
    WaitMilliSec
;    
    mov al,es:MacControlReg
    and al,0FCh
    or al,2
    mov es:MacControlReg,al
;
    mov ax,10
    WaitMilliSec
;    
    mov al,es:PhyControlReg
    and al,0FCh
    or al,2
    mov es:PhyControlReg,al
;
    mov ax,10
    WaitMilliSec
;    
    mov eax,es:RxMacControlReg
    and al,0F0h
    or al,0Ah
    mov es:RxMacControlReg,eax
;
    mov eax,es:TxMacControlReg
    and al,0F0h
    or al,0Ah
    mov es:TxMacControlReg,eax
;
    mov ax,10
    WaitMilliSec
        
    ret
InitController   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitPciAdapter
;
;       DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     AX      Device number
;
;       RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName1     DB '88E80xx-1',0
DriverName2     DB '88E80xx-2',0

PciVendorTab:
pci00   DW 11ABh, 4380h
pci01   DW 0,     0

InitPrimaryPciAdapter   Proc near
    mov bp,ax
    mov ax,cs
    mov es,ax
    mov ax,ether_data_sel
    mov ds,ax
    mov si,OFFSET PciVendorTab
init_pci1_loop:
    mov ax,bp
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci1_done
;
    FindPciDevice
    jnc init_pci1_found
;
    add si,4
    jmp init_pci1_loop

init_pci1_found:
    mov edi,OFFSET DriverName1
    PciPowerOn
;
    mov bp,bx
    call InitBase
    call InitController
;    
    mov ax,bp   
    clc

init_pci1_done:
    ret
InitPrimaryPciAdapter   Endp

InitSecondaryPciAdapter Proc near
    mov bp,ax
    mov ax,cs
    mov es,ax
    mov ax,ether_data2_sel
    mov ds,ax
    mov si,OFFSET PciVendorTab
init_pci2_loop:
    mov ax,bp
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci2_done
;
    FindPciDevice
    jnc init_pci2_found
;
    add si,4
    jmp init_pci2_loop

init_pci2_found:
    mov edi,OFFSET DriverName2
    PciPowerOn
;
    mov bp,bx
    call InitBase
    call InitController
    mov ax,bp   
    clc

init_pci2_done:
    ret
InitSecondaryPciAdapter Endp

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

detect_name DB 'Init Marvell', 0
    
init_net    Proc far
    push ds
    push es
    pusha
;
    int 3    
    xor ax,ax
    call InitPrimaryPciAdapter
;
    inc ax
    call InitSecondaryPciAdapter
;    
    popa
    pop es
    pop ds
    retf32
init_net    Endp

init_task   Proc far
    push ds
    push es
    pusha
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET init_net
    mov edi,OFFSET detect_name
    mov ecx,1000h
    mov ax,4
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_task   Endp

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
    mov eax,SIZE data
    mov bx,ether_data_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
;
    mov eax,SIZE data
    mov bx,ether_data2_sel
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
    mov edi,OFFSET init_task
    HookInitTasking
    clc
    ret
Init    Endp

code    ENDS

    END init
