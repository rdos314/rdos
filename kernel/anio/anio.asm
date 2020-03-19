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

control_bar	STRUC

cb_0	DD ?
cb_clk	DD ?
cb_adc	DD ?
cb_dac  DD ?

control_bar	ENDS

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
;       NAME:           WriteSpiByte
;
;       DESCRIPTION:    Write SPI byte
;
;       PARAMETERS:     DS:BX   SPI function
;			DX      Register
;                       AL      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSpiByte	Proc near
    push edx
    or dh,10h
    shl edx,16
    movzx dx,al
    mov ds:[bx],edx
    pop edx
    ret    
WriteSpiByte	Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteSpiWord
;
;       DESCRIPTION:    Write SPI word
;
;       PARAMETERS:     DS:BX   SPI function
;			DX      Register
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSpiWord	Proc near
    push edx
    or dh,20h
    shl edx,16
    mov dx,ax
    mov ds:[bx],edx
    pop edx
    ret    
WriteSpiWord	Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadSpiWord
;
;       DESCRIPTION:    Read SPI word
;
;       PARAMETERS:     DS:BX   SPI function
;			DX      Register
;
;       RETURNS:        AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSpiWord	Proc near
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
ReadSpiWord	Endp   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           NextPn
;
;       DESCRIPTION:    Next PN value
;
;       PARAMETERS:     EAX	Value
;                       EDX     Result
;                       ECX     Rotations
;
;       RETURNS:        EAX     New value
;                       EDX     New result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextPn	proc near
    mov ebx,eax
    shr ebx,5
    xor ebx,eax
    shr ebx,17
    rcr bl,1
    rcl eax,1
    rcl edx,1
    loop NextPn
    ret
NextPn	Endp

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
;       NAME:           SetupClk
;
;       DESCRIPTION:    Setup clk driver chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupClk	proc near
    mov bx,anio_control_sel
    mov ds,ebx
    mov bx,OFFSET cb_clk
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
    mov al,11h
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
SetupClk	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupAdc
;
;       DESCRIPTION:    Setup ADC chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupAdc	proc near
    mov bx,anio_control_sel
    mov ds,ebx
    mov bx,OFFSET cb_adc
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
    mov al,7
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
    mov al,0          ; should be 10h for 600 MHz!
    call WriteSpiByte
;
    ret
SetupAdc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           VerifyData
;
;           DESCRIPTION:    Verify data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VerifyData 	Proc near
    mov bx,anio_adc_sel
    mov ds,bx
    mov bx,flat_sel
    mov es,bx
;
    xor esi,esi
    mov eax,1000h
    AllocateBigLinear
    mov edi,edx
    mov ebp,0FFFF0001h
    
vdLoop:
    mov eax,ds:[esi]
    mov ebx,ds:[esi+4]
    mov ecx,eax
    or eax,ebx
    jz vdDone
;
    mov edx,edi
    mov ecx,200h

vdMapLoop:
    mov al,67h
    SetPageEntry
;
    push eax
    push ebx
    push ecx
    push edx
;
    mov ecx,400h
;
    push ebp
    pop ax
    pop bx

vdCheckLoop:
    cmp ax,es:[edx]
    je vdCheckBx
;
    test ax,2000h
    jz vdCheckFail
;
    or ax,0C000h
    cmp ax,es:[edx]
    jne vdCheckFail

vdCheckBx:
    cmp bx,es:[edx+2]
    je vdCheckNext
;
    test bx,2000h
    jz vdCheckFail
;
    or bx,0C000h
    cmp bx,es:[edx+2]
    je vdCheckNext
    
vdCheckFail:
    int 3
    sub ax,10h
    sub bx,10h
    cmp ax,es:[edx]
    jne vdCheckNotDupl
;
    cmp bx,es:[edx+2]
    je vdCheckNext

vdCheckNotDupl:   
    int 3
    pop edx
    pop ecx
    pop ebx
    pop eax

vdCheckNext:
    inc ax
    cmp ax,0E711h
    jne vdCheckLowOk
;
    xor ax,ax

vdCheckLowOk:
    inc bx
    cmp bx,0E6E4h
    jne vdCheckHiOk
;
    xor bx,bx

vdCheckHiOk:
    add edx,4
    loop vdCheckLoop
;
    push bx
    push ax
    pop ebp
;
    pop edx
    pop ecx
    pop ebx
    pop eax
    add eax,1000h
    sub ecx,1
    jnz vdMapLoop
;
    add esi,8
    jmp vdLoop

vdDone:
    ret    
VerifyData	Endp

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
    call SetupClk
;
    int 3
    call SetupAdc

;
    mov bx,anio_adc_sel
    mov ds,bx
    xor edi,edi
    mov ecx,10h

adc_phys_loop:
    AllocatePhysicalDir
    mov ds:[edi],eax
    mov ds:[edi+4],ebx
    add edi,8
    loop adc_phys_loop
;
    xor ebx,ebx
    xor eax,eax
    mov ds:[edi],eax
    mov ds:[edi+4],ebx
;
    int 3
    mov bx,anio_control_sel
    mov ds,bx
    xor bx,bx
    mov al,80h
    mov ds:[bx],al
;
    mov ecx,10000h

adc_check_loop:
    mov al,ds:[bx]
    loop adc_check_loop
;
    int 3
    call VerifyData



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
