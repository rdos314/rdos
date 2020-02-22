;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2020, Leif Ekblad
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
; KC705.ASM
; Xilinx ADC driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc

data    SEGMENT byte public 'DATA'

board_linear	DD ?

data	ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public 'CODE'

    assume cs:code

PciInt:
    CrashGate


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

PciVendorTab:
pci00   DW 10EEh, 0AACCh
pci07   DW 0,     0

InitPciAdapter   Proc near
    mov esi,OFFSET PciVendorTab

InitPciLoop:
    mov dx,cs:[esi]
    mov cx,cs:[esi+2]
    or dx,dx
    stc
    jz InitPciDone
;
    FindPciDevice
    jnc InitPciFound
;
    add esi,4
    jmp InitPciLoop

InitPciFound:
    PciPowerOn
;
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_busmstr
    WritePciWord
;
    GetPciMsi
    jc InitPciDone
;
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
;    
    mov dl,1
    SetupPciMsi
;    
    mov di,cs
    mov es,di
    mov edi,OFFSET PciInt
    RequestMsiHandler
    clc

InitPciDone:
    ret
InitPciAdapter   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitControlBar
;
;       DESCRIPTION:    Init control bar
;
;       PARAMETERS:     BX:CH       PCI device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitControlBar	proc near
    pushad
;
    mov cl,PCI_nbr_base_address0
    ReadPciDword
    test al,1
    jnz icbDone
;
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    xor ebx,ebx
    mov si,ax
    and ax,0F000h
    or ax,813h
    SetPageEntry
;
    and si,0FFFh
    or dx,si
    mov bx,anio_control_sel
    mov ecx,1000h
    CreateDataSelector16
    clc

icbDone:
    popad
    ret
InitControlBar	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitAdcBar
;
;       DESCRIPTION:    Init ADC bar
;
;       PARAMETERS:     BX:CH       PCI device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitAdcBar	proc near
    pushad
;
    mov cl,PCI_nbr_base_address1
    ReadPciDword
    test al,1
    jnz iabDone
;
    push eax
    mov eax,80000h
    AllocateBigLinear
    pop eax
;
    mov bx,anio_adc_sel
    mov ecx,80000h
    CreateDataSelector16
;
    or ax,813h
    xor ebx,ebx
    mov ecx,80h

iabLoop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop iabLoop

iabDone:
    popad
    ret
InitAdcBar	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           adc_thread
;
;           DESCRIPTION:    Adc thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

adc_thread_name	DB 'ADC', 0

adc_thread:
    int 3
    call InitPciAdapter
    jc atDone
;
    call InitControlBar
    call InitAdcBar
;
    mov bx,anio_adc_sel
    mov ds,bx
    xor di,di
    AllocatePhysicalDir
    mov ds:[di],eax
    mov ds:[di+4],ebx
;
    mov eax,200000h
    AllocateBigLinear
    AllocateGdt
    CreateDataSelector32
;
    or ax,813h
    xor ebx,ebx
    mov ecx,200h

atLoop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop atLoop
;
    mov bx,anio_control_sel
    mov ds,bx
    xor bx,bx
    mov al,80h
    mov ds:[bx],al
    mov ds,bx
;
    int 3



atDone:
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_thread
;
;           DESCRIPTION:    Init thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_thread    PROC far
    push ds
    push es
    pushad
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET adc_thread
    mov edi,OFFSET adc_thread_name
    mov ecx,stack0_size
    mov ax,4
    CreateThread
;
    popad
    pop es
    pop ds
    ret
init_thread    ENDP

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
    mov eax,cs
    mov es,eax
    mov edi,OFFSET init_thread
    HookInitPci
    clc
    ret
Init    Endp

code    ENDS

    END init
