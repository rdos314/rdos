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
; RTL8169.ASM
; RTL8168/8169/8110/8111/8136 series network driver
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
 
data    STRUC

pad  DB ?

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
    jz init_pci1_done

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
    jz init_pci2_done

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
    mov edi,OFFSET init_net
    HookInitPci
    clc
    ret
Init    Endp

code    ENDS

    END init
