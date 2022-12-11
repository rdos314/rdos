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
; i2xx.ASM
; Intel i2xx driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE ..\os\core.inc
INCLUDE ..\os\net.inc

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

rx_descr        STRUC

rx_phys         DD ?,?
rx_len          DW ?
rx_checksum     DW ?
rx_status       DB ?
rx_errors       DB ?
rx_tag          DW ?

rx_descr         ENDS

tx_descr        STRUC

tx_phys         DD ?,?
tx_len          DW ?
tx_cso          DB ?
tx_cmd          DB ?
tx_sta          DB ?
tx_resv         DB ?
tx_tag          DW ?

tx_descr         ENDS

CTRL_SC     = 1 SHL 26
RCTL_RXEN   = 1 SHL 1
RXDCTL_EN   = 1 SHL 25
TCTL_TXEN   = 1 SHL 1
TXDCTL_EN   = 1 SHL 25

REG_CTRL    = 0
REG_RCTL    = 100h
REG_TCTL    = 400h

REG_RDBA    = 0C000h
REG_RDLEN   = 0C008h
REG_RDH     = 0C010h
REG_RDT     = 0C018h
REG_RXDCTL  = 0C028h

REG_TDBA    = 0E000h
REG_TDLEN   = 0E008h
REG_TDH     = 0E010h
REG_TDT     = 0E018h
REG_TXDCTL  = 0E028h
 
data    STRUC

FuncSel      DW ?

RxRingSel    DW ?
RxRingPhys   DD ?,?

TxRingPhys   DD ?,?
TxRingSel    DW ?

data    ENDS

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NetInt
;
;           DESCRIPTION:    Network card interrupt
;
;       PARAMETERS:         DS  Ether sel
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetInt  Proc far
    CrashGate
    ret
NetInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           CreateFuncSel
;
;       DESCRIPTION:    Create function selector
;
;       PARAMETERS:     EBX:EAX Physical address of BAR0 
;
;       RETURNS:        ES      Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateFuncSel   Proc near
    push eax
    push ebx
    push ecx
;
    push eax
    mov eax,10000h
    AllocateBigLinear
    pop eax
;
    push eax
    push edx
;
    and ax,0F000h
    or ax,813h
    mov ecx,10h

cfsLoop:
    SetPageEntry
;
    add edx,1000h
    add eax,1000h
    loop cfsLoop
;
    pop edx
    pop eax
;
    and ax,0FFFh
    or dx,ax
;
    AllocateGdt
    mov ecx,10000h
    CreateDataSelector32
    mov es,bx    
;    
    pop ecx
    pop ebx
    pop eax
    ret
CreateFuncSel  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup PCI or MSI IRQ
;
;       PARAMETERS:         BH    Bus
;                           BL    Device
;                           CH    Function
;                           DS    Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts   Proc near
    pushad
;    
    GetPciMsi
    jc siIrq

siMsi:
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc siIrq
;    
    mov dl,1
    SetupPciMsi
;    
    mov di,cs
    mov es,di
    mov edi,OFFSET NetInt
    RequestMsiHandler
    jmp siDone

siIrq:
    GetPciIrqNr
    mov ah,14h
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetInt    
    RequestIrqHandler

siDone:
    popad
    ret
SetupInts    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateRxRing
;
;           DESCRIPTION:    Create RX ring
;
;           PARAMETERS:     DS  Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRxRing    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical64
    mov ds:RxRingPhys,eax
    mov ds:RxRingPhys+4,ebx
    or al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov ds:RxRingSel,bx
;
    mov es,bx
    mov ecx,100h
    xor edi,edi

crLoop:
    mov es:[edi].rx_len,1000h
    mov es:[edi].rx_checksum,0
    mov es:[edi].rx_status,0
    mov es:[edi].rx_errors,0
    mov es:[edi].rx_tag,0
;
    AllocatePhysical64
    mov es:[edi].rx_phys,eax
    mov es:[edi].rx_phys+4,ebx
;
    add edi,16
    loop crLoop
;
    popad
    pop es
    ret
CreateRxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateTxRing
;
;           DESCRIPTION:    Create TX ring
;
;           PARAMETERS:     DS  Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateTxRing    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical64
    mov ds:TxRingPhys,eax
    mov ds:TxRingPhys+4,ebx
    or al,13h
    SetPageEntry
;
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    mov ds:TxRingSel,bx
;
    mov es,bx
    mov ecx,100h
    xor edi,edi

ctLoop:
    mov es:[edi].tx_phys,0
    mov es:[edi].tx_phys+4,0
    mov es:[edi].tx_len,0
    mov es:[edi].tx_cso,0
    mov es:[edi].tx_cmd,0Bh
    mov es:[edi].tx_sta,0
    mov es:[edi].tx_resv,0
    mov es:[edi].tx_tag,0
;
    add edi,16
    loop ctLoop
;
    popad
    pop es
    ret
CreateTxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitRx
;
;           DESCRIPTION:    Init RX
;
;           PARAMETERS:     DS  Ether sel
;                           ES  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRx  Proc near
    call CreateRxRing
;
    mov eax,es:REG_RCTL
    and eax,NOT RCTL_RXEN
    mov es:REG_RCTL,eax
;
    mov eax,ds:RxRingPhys
    mov es:REG_RDBA,eax
    mov eax,ds:RxRingPhys+4
    mov es:REG_RDBA+4,eax
;
    mov dword ptr es:REG_RDLEN,1000h
;
    mov eax,es:REG_RXDCTL
    or eax,RXDCTL_EN
    mov es:REG_RXDCTL,eax
;
    mov ecx,100000h

irWaitEn:    
    pause
    mov eax,es:REG_RXDCTL
    test eax,RXDCTL_EN
    jnz irDoneEn
    loop irWaitEn

irDoneEn:
    mov eax,0FF0h
    mov es:REG_RDT,eax
;
    mov eax,es:REG_RCTL
    or eax,RCTL_RXEN
    mov es:REG_RCTL,eax
    ret
InitRx  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTx
;
;           DESCRIPTION:    Init TX
;
;           PARAMETERS:     DS  Ether sel
;                           ES  Function sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitTx  Proc near
    call CreateTxRing
;
    mov eax,es:REG_TCTL
    and eax,NOT TCTL_TXEN
    mov es:REG_TCTL,eax
;
    mov eax,ds:TxRingPhys
    mov es:REG_TDBA,eax
    mov eax,ds:TxRingPhys+4
    mov es:REG_TDBA+4,eax
;
    mov dword ptr es:REG_TDLEN,1000h
;
    mov eax,es:REG_TXDCTL
    or eax,TXDCTL_EN
    mov es:REG_TXDCTL,eax
;
    mov ecx,100000h

itWaitEn:    
    pause
    mov eax,es:REG_TXDCTL
    test eax,TXDCTL_EN
    jnz itDoneEn
    loop itWaitEn

itDoneEn:
    mov eax,es:REG_TCTL
    or eax,TCTL_TXEN
    mov es:REG_TCTL,eax
    ret
InitTx	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitFunc
;
;           DESCRIPTION:    Init function
;
;           PARAMETERS:     DS  Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitFunc    Proc near
    push es
    pushad
;
    mov es,ds:FuncSel
    mov eax,es:REG_CTRL
    or eax,CTRL_SC
    mov es:REG_CTRL,eax
;
    mov ecx,100000h

ifWaitReset:    
    pause
    mov eax,es:REG_CTRL
    test eax,CTRL_SC
    jz ifDoneReset
    loop ifWaitReset

ifDoneReset:
    int 3
    call InitRx
    call InitTx
;
    popad
    pop es
    ret
InitFunc        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     AX      Device number
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName1     DB 'Net i2xx-1',0
DriverName2     DB 'Net i2xx-2',0

SupervisorName1 DB 'Super i2xx-1',0
SupervisorName2 DB 'Super i2xx-2',0

PciVendorTab:
pci00   DW 8086h, 1539h,    0
pci07   DW 0,     0

InitPrimaryPciAdapter   Proc near
    mov bp,ax
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
    add si,6
    jmp init_pci1_loop

init_pci1_found:
    PciPowerOn
;
    mov bp,bx
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_busmstr OR PCI_command_IO OR PCI_command_mem
    WritePciWord
;
    mov cl,PCI_card_ExCa_base
    ReadPciDword
    test al,1
    stc
    jnz init_pci1_done
;
    push eax
    call SetupInts
;
    mov cl,PCI_card_ExCa_base+4
    ReadPciDword
;
    mov ebx,eax
    pop eax
;
    call CreateFuncSel
    mov ds:FuncSel,es
;
    call InitFunc

io_pci1:
    mov ax,bp   
    clc
    jmp init_pci1_done

init_pci1_done:
    ret
InitPrimaryPciAdapter   Endp

InitSecondaryPciAdapter Proc near
    mov bp,ax
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
    add si,6
    jmp init_pci2_loop

init_pci2_found:
    PciPowerOn
;
    mov bp,bx
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_busmstr OR PCI_command_IO OR PCI_command_mem
    WritePciWord
;
    mov cl,PCI_card_ExCa_base
    ReadPciDword
    test al,1
    stc
    jnz init_pci2_done
;
    push eax
    call SetupInts
;
    mov cl,PCI_card_ExCa_base+4
    ReadPciDword
;
    mov ebx,eax
    pop eax
;
    call CreateFuncSel
    mov ds:FuncSel,es
;
    call InitFunc

io_pci2:
    mov ax,bp   
    clc
    jmp init_pci2_done

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
    
init_net    Proc far
    push ds
    push es
    pusha
;
    xor ax,ax
    call InitPrimaryPciAdapter
;
    inc ax
    call InitSecondaryPciAdapter
;    
    popa
    pop es
    pop ds
    ret
init_net    Endp

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
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov eax,SIZE data
    mov bx,ether_data2_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov ecx,eax
    xor edi,edi
    xor al,al
    rep stos byte ptr es:[edi]
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_net
    HookInitPci
    clc
    ret
Init    Endp

code    ENDS

    END init
