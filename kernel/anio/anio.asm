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
;ac0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE ..\os\core.inc

control_bar     STRUC

cb_adc_control    DB ?          ; 0
cd_resv1          DB ?,?,?
cb_spi_clk        DD ?          ; 1
cb_spi_adc        DD ?          ; 2
cb_spi_dac        DD ?          ; 3
cb_adc_irq        DB ?          ; 4
cb_adc_test_mode  DB ?
cb_adc_index      DW ?
cb_adc_phase_incr DD ?          ; 5
cb_adc_window     DB ?,?,?,?    ; 6

control_bar     ENDS

data    SEGMENT byte public 'DATA'

board_linear    DD ?

adc_buf_sel     DW ?
adc_index       DW ?
adc_pages       DW ?

start_thread    DW ?


data    ENDS

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

code    SEGMENT byte public 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AdcBarInt
;
;           DESCRIPTION:    Adc bar interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdcBarInt Proc far
    ret
AdcBarInt       Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           AdcBlockInt
;
;           DESCRIPTION:    Adc block interrupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdcBlockInt Proc far
    mov bx,SEG data
    mov ds,ebx
    inc ds:adc_index
    ret
AdcBlockInt     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteSpiByte
;
;       DESCRIPTION:    Write SPI byte
;
;       PARAMETERS:     DS:BX   SPI function
;                       DX      Register
;                       AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSpiByte    Proc near
    push edx
    or dh,10h
    shl edx,16
    movzx dx,al
    mov ds:[bx],edx
    pop edx
    ret    
WriteSpiByte    Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteSpiWord
;
;       DESCRIPTION:    Write SPI word
;
;       PARAMETERS:     DS:BX   SPI function
;                       DX      Register
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSpiWord    Proc near
    push edx
    or dh,20h
    shl edx,16
    mov dx,ax
    mov ds:[bx],edx
    pop edx
    ret    
WriteSpiWord    Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadSpiWord
;
;       DESCRIPTION:    Read SPI word
;
;       PARAMETERS:     DS:BX   SPI function
;                       DX      Register
;
;       RETURNS:        AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSpiWord     Proc near
    mov ax,dx
    or ah,0C0h
    mov ds:[bx+2],ax

rswWait:
    mov al,ds:[bx+3]
    or al,al
    jnz rswWait
;
    mov ax,ds:[bx]
    ret    
ReadSpiWord     Endp   

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

InitControlBar  proc near
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
InitControlBar  Endp

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

InitAdcBar      proc near
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
    or ax,80Bh
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
InitAdcBar      Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitClk
;
;       DESCRIPTION:    Init clk driver chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitClk proc near
    mov bx,anio_control_sel
    mov ds,ebx
    mov bx,OFFSET cb_spi_clk
;
    mov dx,10h
    mov al,1
    call WriteSpiByte
;
    mov dx,12h
    mov al,1
    call WriteSpiByte
;
    mov dx,16h
    mov al,1
    call WriteSpiByte
;
    mov dx,18h
    mov al,80h
    call WriteSpiByte
;
    mov dx,1Ah
    mov al,5
    call WriteSpiByte
;
    mov dx,1Bh
    mov al,60h
    call WriteSpiByte
;
    mov dx,1Ch
    mov al,84h
    call WriteSpiByte
;
    mov dx,1Dh
    mov al,1h
    call WriteSpiByte
;
    mov dx,0F0h
    mov al,76h
    call WriteSpiByte
;
    mov dx,0F1h
    mov al,6h
    call WriteSpiByte
;
    mov dx,0F2h
    mov al,13h
    call WriteSpiByte
;
    mov dx,0F3h
    mov al,2h
    call WriteSpiByte
;
    mov dx,0F4h
    mov al,11h   ; 750 MHz
;    mov al,22h   ; 600 MHz
    call WriteSpiByte
;
    mov dx,0F5h
    mov al,3Ah
    call WriteSpiByte
;
    mov dx,0F7h
    mov al,1h
    call WriteSpiByte
;
    mov dx,190h
    mov al,20h
    call WriteSpiByte
;
    mov dx,193h
    mov al,3h
    call WriteSpiByte
;
    mov dx,194h
    mov al,0h
    call WriteSpiByte
;
    mov dx,196h
    mov al,20h
    call WriteSpiByte
;
    mov dx,199h
    mov al,20h
    call WriteSpiByte
;
    mov dx,19Ch
    mov al,3h
    call WriteSpiByte
;
    mov dx,19Dh
    mov al,1h
    call WriteSpiByte
;
    mov dx,19Fh
    mov al,3h
    call WriteSpiByte
;
    mov dx,1A0h
    mov al,7Fh
    call WriteSpiByte
;
    mov dx,1A2h
    mov al,3h
    call WriteSpiByte
;
    mov dx,1A3h
    mov al,7Fh
    call WriteSpiByte
;
    mov dx,1A5h
    mov al,3h
    call WriteSpiByte
;
    mov dx,1A6h
    mov al,7Fh
    call WriteSpiByte
;
    mov dx,1A8h
    mov al,3h
    call WriteSpiByte
;
    mov dx,1A9h
    mov al,7Fh
    call WriteSpiByte
;
    mov dx,1ABh
    mov al,3h
    call WriteSpiByte
;
    mov dx,1ACh
    mov al,1h
    call WriteSpiByte
;
    mov dx,1AEh
    mov al,20h
    call WriteSpiByte
;
    mov dx,1B1h
    mov al,20h
    call WriteSpiByte
;
    mov dx,1B4h
    mov al,20h
    call WriteSpiByte
;
    mov dx,1B7h
    mov al,3h
    call WriteSpiByte
;
    mov dx,1B8h
    mov al,0h
    call WriteSpiByte
;
    mov dx,230h
    mov al,2h
    call WriteSpiByte
;
    mov dx,231h
    mov al,3h
    call WriteSpiByte
;
    mov dx,233h
    mov al,0h
    call WriteSpiByte
;
    mov dx,234h
    mov al,1h
    call WriteSpiByte
;
    ret
InitClk Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitAdc
;
;       DESCRIPTION:    Init ADC chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitAdc proc near
    mov bx,anio_control_sel
    mov ds,ebx
    mov bx,OFFSET cb_spi_adc
;
    mov dx,580h
    mov al,0
    call WriteSpiByte
;
    mov dx,581h
    mov al,1
    call WriteSpiByte
;
    mov dx,570h
    mov al,88h
    call WriteSpiByte
;
    mov dx,583h
    mov al,0
    call WriteSpiByte
;
    mov dx,584h
    mov al,1
    call WriteSpiByte
;
    mov dx,585h
    mov al,2
    call WriteSpiByte
;
    mov dx,586h
    mov al,3
    call WriteSpiByte
;
    mov dx,5B2h
    mov al,0
    call WriteSpiByte
;
    mov dx,5B3h
    mov al,11h
    call WriteSpiByte
;
    mov dx,5B5h
    mov al,22h
    call WriteSpiByte
;
    mov dx,5B6h
    mov al,33h
    call WriteSpiByte
;
    mov dx,58Bh
    mov al,83h
    call WriteSpiByte
;
    mov dx,58Dh
    mov al,31
    call WriteSpiByte
;
    mov dx,58Eh
    mov al,1
    call WriteSpiByte
;
    mov dx,58Fh
    mov al,13
    call WriteSpiByte
;
    mov dx,590h
    mov al,2Fh
    call WriteSpiByte
;
    mov dx,26Fh
    mov al,1
    call WriteSpiByte
;
    mov dx,550h
    mov al,0
    call WriteSpiByte
;
    mov dx,120h
    mov al,0
    call WriteSpiByte
;
    mov dx,121h
    mov al,0Fh
    call WriteSpiByte
;
    mov dx,120h
    mov al,0Ah
    call WriteSpiByte
;
    mov dx,56Eh
    mov al,0          ; 750 MHz
;    mov al,10h         ; 600 MHz
    call WriteSpiByte
;
    ret
InitAdc Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DevName DB 'ANIO', 0

PciVendorTab:
pci00   DW 10EEh, 0AACCh
pci07   DW 0,     0

InitPciAdapter   Proc near
    xor ax,ax
    mov esi,OFFSET PciVendorTab

InitPciLoop:
    xor ax,ax
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
    mov ax,cs
    mov es,ax
    mov edi,OFFSET DevName
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
    mov cx,2
    mov al,14h
    AllocateInts
    pop cx
;    
    mov dl,2
    SetupPciMsi
;    
    mov di,cs
    mov es,di
    mov edi,OFFSET AdcBarInt
    RequestMsiHandler
;    
    inc al
    mov di,cs
    mov es,di
    mov edi,OFFSET AdcBlockInt
    RequestMsiHandler
    
    clc

InitPciDone:
    ret
InitPciAdapter   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           setup_adc
;
;       DESCRIPTION:    Setup ADC
;
;       PARAMETERS:     AL      Test mode
;                       AH      Speed
;                       ECX     2M buffer pages
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_adc_name  DB 'Setup ADC', 0

setup_adc  Proc far
    push ds
    push es
    push eax
    push ebx
    push ecx
    push edi
;
    mov bx,SEG data
    mov ds,ebx
    mov ds:adc_pages,cx
;
    mov bx,anio_control_sel
    mov ds,ebx
    mov ds:cb_adc_test_mode,al
;
    mov bx,SEG data
    mov ds,ebx
;
    mov es,ds:adc_buf_sel
    FreeMem
;
    mov eax,ecx
    shl eax,3
    AllocateGlobalMem
    mov ds:adc_buf_sel,es   
;
    mov bx,anio_adc_sel
    mov ds,bx
    xor edi,edi
;
    mov ax,25
    WaitMilliSec

setup_adc_phys_loop:
    Allocate2MPhysical64
    mov ds:[edi],eax
    mov ds:[edi+4],ebx
    mov es:[edi],eax
    mov es:[edi+4],ebx
    add edi,8
    loop setup_adc_phys_loop
;
    xor eax,eax
    mov ds:[edi],eax
    mov ds:[edi+4],eax
;
    pop edi
    pop ecx
    pop ebx
    pop eax
    pop es
    pop ds
    ret
setup_adc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           adc_thread
;
;           DESCRIPTION:    Adc thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

adc_thread_name DB 'ADC', 0

adc_thread:
    mov ax,SEG data
    mov ds,eax
    mov cx,ds:adc_pages

adc_wait_signal:
    mov ax,ds:adc_index
    or ax,ax
    jz adc_wait_signal
;
    mov bx,ds:start_thread
    Signal

adc_loop:
    mov ax,1
    WaitMilliSec
    cmp cx,ds:adc_index
    jne adc_loop
;
    TerminateThread

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           set_adc_trigger
;
;       DESCRIPTION:    Set ADC trigger
;
;       PARAMETERS:     EAX     Phase incr
;                       CL      Window bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_adc_trigger_name    DB 'Set ADC Trigger', 0

set_adc_trigger  Proc far
    push ds
    push ebx
;
    mov bx,anio_control_sel
    mov ds,ebx
    mov ds:cb_adc_phase_incr,eax
    mov ds:cb_adc_window,cl
;
    pop ebx
    pop ds
    ret
set_adc_trigger Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           start_adc
;
;       DESCRIPTION:    Start ADC
;
;       RETURNS:        NC      OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

start_adc_name  DB 'Start ADC', 0

start_adc  Proc far
    push ds
    push es
    push ebx
    push ecx
    push esi
    push edi
;
    mov bx,SEG data
    mov ds,ebx
    GetThread
    mov ds:start_thread,ax
    mov ds:adc_index,0
    ClearSignal
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov esi,OFFSET adc_thread
    mov edi,OFFSET adc_thread_name
    mov ecx,stack0_size
    mov ax,1
    CreateThread
;
    mov ax,500
    WaitMilliSec
;
    mov bx,anio_control_sel
    mov es,ebx
    or es:cb_adc_control,80h
    WaitForSignal
;
    pop edi
    pop esi
    pop ecx
    pop ebx
    pop es
    pop ds
    ret
start_adc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           stop_adc
;
;       DESCRIPTION:    Stop ADC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stop_adc_name   DB 'Stop ADC', 0

stop_adc  Proc far
    push ds
    push ebx
;
    mov bx,anio_control_sel
    mov ds,ebx
    and es:cb_adc_control,7Fh
;
    pop ebx
    pop ds
    ret
stop_adc  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           map_adc_block
;
;       DESCRIPTION:    Map adc 2M block to buffer
;
;       PARAMETERS:     EAX     Block #
;                       ES:EDI  Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_adc_block_name      DB 'Map ADC Block', 0

map_adc_block  Proc far
    push ds
    pushad
;
    mov bx,SEG data
    mov ds,bx
    cmp ax,ds:adc_index
    jb mabPresent
;
    push eax
;
    sub ax,ds:adc_index
    inc ax
    mov dx,835
    mul dx
    push dx
    push ax
    pop ebx
;
    GetSystemTime
    add eax,ebx
    adc edx,0
    WaitUntil
;
    pop eax
    cmp ax,ds:adc_index
    jb mabPresent
;
    stc
    jmp mabDone

mabPresent:
    mov ds,ds:adc_buf_sel
;
    mov ebx,eax
    shl ebx,3
    mov eax,ds:[ebx]
    mov ebx,ds:[ebx+4]
    mov edx,eax
    or edx,ebx
    stc
    jz mabDone
;
    push ebx
    mov ebx,es
    GetSelectorBaseSize
    add edx,edi
    pop ebx
;
    mov al,67h
    mov ecx,200h

mabLoop:
    SetPageEntry
    add edx,1000h
    add eax,1000h
    loop mabLoop
;
    clc

mabDone:
    popad
    pop ds  
    ret
map_adc_block  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_pci
;
;           DESCRIPTION:    Init PCI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_pci    PROC far
    push ds
    push es
    pushad
;
    call InitPciAdapter
    jc ipDone
;
    call InitControlBar
    call InitAdcBar
    call InitClk
    call InitAdc
;
    mov eax,cs
    mov ds,eax
    mov es,eax
;
    mov esi,OFFSET setup_adc
    mov edi,OFFSET setup_adc_name
    xor dx,dx
    mov ax,setup_adc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET start_adc
    mov edi,OFFSET start_adc_name
    xor dx,dx
    mov ax,start_adc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET stop_adc
    mov edi,OFFSET stop_adc_name
    xor dx,dx
    mov ax,stop_adc_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET map_adc_block
    mov edi,OFFSET map_adc_block_name
    xor dx,dx
    mov ax,map_adc_block_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_adc_trigger
    mov edi,OFFSET set_adc_trigger_name
    xor dx,dx
    mov ax,set_adc_trigger_nr
    RegisterBimodalUserGate

ipDone:
    popad
    pop es
    pop ds
    ret
init_pci    ENDP

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
    mov ax,SEG data
    mov ds,eax
    mov ds:start_thread,0
    mov ds:adc_buf_sel,0
;
    mov eax,cs
    mov ds,eax
    mov es,eax
    mov edi,OFFSET init_pci
    HookInitPci
    clc
    ret
Init    Endp

code    ENDS

    END init
