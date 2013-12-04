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
; SDCARD.ASM
; SD card driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc
INCLUDE ..\os\protseg.def
INCLUDE pci.inc

MAX_SD_DEVICES      = 32
MAX_NAME_SIZE       = 24

REG_BLOCK_SIZE          = 4
REG_STATE               = 24h
REG_CONTROL             = 28h
REG_POWER               = 29h
REG_CLK_CONTROL         = 2Ch
REG_RESET               = 2Fh
REG_INT_STATUS          = 30h
REG_INT_STATUS_ENABLE   = 34h
REG_INT_SIG_ENABLE      = 38h
REG_CAP                 = 40h

sd_device_struc STRUC

sd_reg_sel      DW ?
sd_serv_thread  DW ?
sd_pend_int     DB ?
sd_pci_bus      DB ?
sd_pci_device   DB ?
sd_pci_function DB ?

sd_device_struc ENDS

data    SEGMENT byte public 'DATA'

sd_dev_count   DW ?
sd_dev_arr     DW MAX_SD_DEVICES DUP (?)

serv_name_ptr        DW ?
serv_name_str        DB MAX_NAME_SIZE DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SdInt
;
;       DESCRIPTION:    IRQ handler
;
;       PARAMETERS:     DS      Device selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SdInt  Proc far
    mov es,ds:sd_reg_sel
    mov ax,es:REG_INT_STATUS
    or ds:sd_pend_int,al
;    
    and word ptr es:REG_INT_STATUS_ENABLE, NOT 100h    
    mov es:REG_INT_STATUS,al
    or word ptr es:REG_INT_STATUS_ENABLE, 100h
;
    mov bx,ds:sd_serv_thread
    Signal    
    retf32
SdInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddDevice
;
;       DESCRIPTION:    Add an AHCI-device
;
;       PARAMETERS:     FS      Register selector
;                       EDX     Register linear
;                       BH      PCI Bus
;                       BL      PCI Device
;                       CH      PCI Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddDevice   Proc near
    push es
    pushad
;
    push ax
    mov eax,SIZE sd_device_struc
    AllocateSmallGlobalMem
    pop ax
    mov es:sd_reg_sel,fs
    mov es:sd_pci_bus,bh
    mov es:sd_pci_device,bl
    mov es:sd_pci_function,ch
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:sd_dev_count
    shl bx,1
    mov ds:[bx].sd_dev_arr,es    
    inc ds:sd_dev_count
;
    popad
    pop es
    ret
AddDevice   Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciDev
;
;           DESCRIPTION:    Init PCI SD-card devices
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitPciDev Proc near
    mov ax,SEG data
    mov ds,ax
    mov ds:sd_dev_count,0
;    
    xor si,si

ipdLoop: 
    mov ax,si
    mov bh,8
    mov bl,5
    FindPciClassAll
    jc ipdDone
;
    push cx
    mov eax,1000h
    AllocateBigLinear
    pop cx
;    
    mov cl,PCI_nbr_base_address0
    ReadPciDword
;    
    push eax
    and ax,0F000h
    push ebx
    xor ebx,ebx
    mov al,67h
    SetPageEntry
    pop ebx
    pop eax
;
    and eax,0E00h
    add edx,eax
;        
    push bx
    AllocateGdt
    push cx
    mov ecx,200h
    CreateDataSelector16
    pop cx
    mov fs,bx
    mov byte ptr fs:REG_RESET,1
    pop bx
    call AddDevice
;
    inc si
    jmp ipdLoop

ipdDone:
    ret
InitPciDev  Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup device ints
;
;           PARAMETERS:     DS     Device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts Proc near
    pushad
;    
    mov bh,ds:sd_pci_bus
    mov bl,ds:sd_pci_device
    mov ch,ds:sd_pci_function
    GetPciMsi
    jc siIrq
;    
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc siIrq    
;    
    SetupPciMsi
    mov di,cs
    mov es,di
    mov edi,OFFSET SdInt
    RequestMsiHandler
    jmp siOk

siIrq:
    GetPciIrqNr
    mov ah,14h
    mov di,cs
    mov es,di
    mov edi,OFFSET SdInt
    RequestIrqHandler

siOk:    
    popad
    ret
SetupInts   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetSdClock
;
;           DESCRIPTION:    Set SDIO clk rate
;
;           PARAMETERS:     FS      SD io space
;                           CX      Frequency, MHz
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSdClock  Proc near
    mov eax,fs:REG_CAP
    shr ax,8
    and ax,3Fh
    xor dx,dx
    div cx
;
    or dx,dx
    jz sscMultOk
;
    inc ax

sscMultOk:
    xor cl,cl

sscExpLoop:
    test ax,8000h
    jnz sscExpOk
;
    shl ax,1
    inc cl
;
    or ax,ax
    jnz sscExpLoop                

sscExpOk:
    test ax,7FFFh
    jz sscWhole
;
    dec cl

sscWhole:
    mov ax,0FFFFh
    shr ax,cl
    inc ax
    shr ax,2
;
    mov ah,al
    mov al,1
    mov fs:REG_CLK_CONTROL,ax
    mov cx,100    

sscWait:
    mov ax,1
    WaitMilliSec
;
    mov ax,fs:REG_CLK_CONTROL
    test al,2
    jnz sscOk
;
    loop sscWait
;
    stc
    jmp sscDone

sscOk:
    or ax,4
    mov fs:REG_CLK_CONTROL,ax       
    clc
    
sscDone:
    ret
SetSdClock  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetPower
;
;           DESCRIPTION:    Turn on power
;
;           PARAMETERS:     FS      SD io space
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetPower  Proc near
    mov eax,fs:REG_CAP
    mov al,0Eh
    test eax,1000000h
    jnz spDo
;
    mov al,0Ch
    test eax,2000000h    
    jnz spDo
;
    mov al,0Ah

spDo:
    mov ah,fs:REG_POWER
    or ah,al
    mov al,fs:REG_CONTROL
    and al,NOT 9Fh
    mov fs:REG_CONTROL,ax
;
    or ah,1
    mov fs:REG_CONTROL,ax
    clc
    ret
SetPower    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ServThread
;
;           DESCRIPTION:    SDIO device server thread
;
;           PARAMETERS:     FS      SD device sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

serv_thread_name   DB 'SDIO ',0

serv_thread:
    mov ax,fs
    mov ds,ax
    GetThread
    mov ds:sd_serv_thread,ax
    mov ds:sd_pend_int,0
;    
    mov fs,ds:sd_reg_sel
    mov dword ptr fs:REG_BLOCK_SIZE,200h
    mov word ptr fs:REG_INT_STATUS_ENABLE,1FFh
    mov word ptr fs:REG_INT_SIG_ENABLE,1FFh

stOff:
    test dword ptr fs:REG_STATE,10000h
    jnz stInserted
;
    WaitForSignal    
    jmp stOff

stInserted:
    mov cx,25
    call SetSdClock
    jc stFailed
;
    int 3 
    call SetPower
    jc stFailed

stFailed: 
    mov byte ptr fs:REG_RESET,1
;    
    WaitForSignal
    test dword ptr fs:REG_STATE,10000h
    jnz stFailed
    jmp stOff       
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupDev
;
;           DESCRIPTION:    Setup device
;
;           PARAMETERS:     DS      Device sel
;                           DL      Device #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDev    Proc near
    mov fs,ds:sd_reg_sel
    mov al,fs:REG_RESET
    and al,1
    jz stdResetOk
;
    mov ax,100
    WaitMilliSec
    mov al,fs:REG_RESET
    and al,1
    jnz stdDone

stdResetOk:
    mov ax,ds
    mov fs,ax
    mov ax,cs
    mov ds,ax
    mov ax,SEG data    
    mov es,ax
;    
    mov al,dl
    add al,'0'
    mov si,es:serv_name_ptr
    mov es:[si],al
    mov edi,OFFSET serv_name_str
    mov esi,OFFSET serv_thread
    mov ax,2
    mov cx,stack0_size
    CreateThread
    
stdDone:    
    ret
SetupDev    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           StartDevices
;
;           DESCRIPTION:    Start SD device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartDevices Proc near
    mov ax,SEG data
    mov ds,ax
    mov cx,ds:sd_dev_count
    mov bx,OFFSET sd_dev_arr
    xor dl,dl
    or cx,cx
    jz sdvDone

sdvLoop:
    push ds
    push bx
    push cx
    push dx
;
    mov ds,ds:[bx]
    call SetupInts
    call SetupDev
;
    pop dx
    pop cx
    pop bx
    pop ds
;
    add bx,2
    inc dl
    loop sdvLoop

sdvDone:
    ret
StartDevices    Endp        

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           init_sd_thread
;
;           DESCRIPTION:    SD init thread
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sd_name DB 'SD Card',0

init_sd_thread:
    mov ax,SEG data
    mov ds,ax
    mov es,ax
;    
    mov di,OFFSET serv_name_str
    mov si,OFFSET serv_thread_name

stdNameLoop:    
    lods byte ptr cs:[si]
    stosb
    or al,al
    jnz stdNameLoop
;
    dec di
    mov ds:serv_name_ptr,di
    mov al,'0'
    stosb
    xor al,al
    stosb
;    
    call InitPciDev
    call StartDevices
    TerminateThread
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_sd
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_sd    Proc far
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov di,OFFSET init_sd_name
    mov si,OFFSET init_sd_thread
    mov ax,4
    mov cx,stack0_size
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_sd    Endp

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

init    PROC far
    mov ax,SEG data
    mov ds,ax
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_sd
    HookInitPci
    clc
    ret
init    ENDP

code    ENDS

    END init
