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
; HDA.ASM
; HD Audio driver (Intel compatible)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\pcdev\pci.inc

hda_reg STRUC

HdaGcap         DW ?
HdaVmin         DB ?
HdaVmax         DB ?
HdaOutPay       DW ?
HdaInPay        DW ?
HdaGctl         DD ?
HdaWakeEn       DW ?
HdaStateSts     DW ?
HhaGsts         DW ?,?,?,?
HdaOutStrmPay   DW ?
HdaInStrmPay    DW ?,?,?
HdaIntCtl       DD ?
HdaIntSts       DD ?,?,?
HdaClock        DD ?,?
HdaSSync        DD ?,?
HdaCorb         DD ?,?
HdaCorbWp       DW ?
HdaCorbRp       DW ?
HdaCorbCtl      DB ?
HdaCorbSts      DB ?
HdaCorbSize     DB ?,?
HdaRirb         DD ?,?
HdaRirbWp       DW ?
HdaRintCnt      DW ?
HdaRirbCtl      DB ?
HdaRirbSts      DB ?
HdaRirbSize     DB ?,?
HdaResv60       DD ?,?,?,?
HdaDplBase      DD ?,?,?,?

hda_reg Ends

data    SEGMENT byte public 'DATA'

HdaSel      DW ?
InStreams   DW ?
OutStreams  DW ?
CodexPhys   DD ?

CorbSize    DW ?
CorbSel     DW ?

RirbSize    DW ?
RirbSel     DW ?

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenAudioOut
;
;           DESCRIPTION:    Open audio out
;
;       PARAMETERS:     AX      Sample rate
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_audio_out_name DB 'Open Audio Out',0

open_audio_out  Proc far
    stc
    retf32
open_audio_out  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseAudioOut
;
;           DESCRIPTION:    Close audio out
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_audio_out_name DB 'Close Audio Out',0

close_audio_out Proc far
    retf32
close_audio_out  Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SendAudioOut
;
;           DESCRIPTION:    Send audio out
;
;       PARAMETERS:     DS      Left channel 32-bit sample data
;               ES      Right channel
;               CX      Number of samples
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

send_audio_out_name DB 'Send Audio Out',0

send_audio_out  Proc far
    retf32
send_audio_out  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           HasAudio
;
;           DESCRIPTION:    Check if audio hardware is found & is working
;
;           RETURNS:        NC      Audio available
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

has_audio_name DB 'Has Audio',0

has_audio      Proc far
    stc
    retf32    
has_audio  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetCorbSize
;
;       DESCRIPTION:    Determine (and configure) corb size
;
;       PARAMETERS:     DS      Data
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCorbSize Proc near
    mov al,es:HdaCorbSize
    mov cx,1024
    mov ah,2
    test al,40h
    jnz gcsOk
;
    mov cx,64
    mov ah,1
    test al,20h
    jnz gcsOk
;
    mov cx,8
    mov ah,0

gcsOk:
    and al,0FCh
    or al,ah
    mov es:HdaCorbSize,al
    mov ds:CorbSize,cx
    ret
GetCorbSize Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetRirbSize
;
;       DESCRIPTION:    Determine (and configure) rirb size
;
;       PARAMETERS:     DS      Data
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRirbSize Proc near
    mov al,es:HdaRirbSize
    mov cx,2048
    mov ah,2
    test al,40h
    jnz grsOk
;
    mov cx,128
    mov ah,1
    test al,20h
    jnz grsOk
;
    mov cx,16
    mov ah,0

grsOk:
    and al,0FCh
    or al,ah
    mov es:HdaRirbSize,al
    mov ds:RirbSize,cx
    ret
GetRirbSize Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitCorbBuf
;
;       DESCRIPTION:    Init corb buffer
;
;       PARAMETERS:     DS      Data
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitCorbBuf   Proc near
    push es
    push cx
    push di
;    
    mov es,ds:CorbSel
    mov cx,ds:CorbSize
    shr cx,2
    xor eax,eax
    xor di,di
    rep stosd
;
    pop di
    pop cx
    pop es
    ret
InitCorbBuf Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           InitRirbBuf
;
;       DESCRIPTION:    Init rirb buffer
;
;       PARAMETERS:     DS      Data
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitRirbBuf   Proc near
    push es
    push cx
    push di
;    
    mov es,ds:RirbSel
    mov cx,ds:RirbSize
    shr cx,2
    xor eax,eax
    xor di,di
    rep stosd
;
    pop di
    pop cx
    pop es
    ret
InitRirbBuf Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetupCodecBuf
;
;       DESCRIPTION:    Setup codex corb and rirb buffers
;
;       PARAMETERS:     DS      Data
;                       ES      HDA registers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupCodecBuf   Proc near
    AllocatePhysical32
    mov ds:CodexPhys,eax
    mov es:HdaCorb,eax
    add eax,800h
    mov es:HdaRirb,eax
;    
    mov eax,1000h
    AllocateBigLinear
;
    AllocateGdt
    movzx ecx,ds:CorbSize
    CreateDataSelector16
    mov ds:CorbSel,bx
;
    add edx,800h
    AllocateGdt
    movzx ecx,ds:RirbSize
    CreateDataSelector16
    mov ds:RirbSel,bx
;
    sub edx,800h
    mov eax,ds:CodexPhys
    xor ebx,ebx
    or ax,803h
    SetPageEntry
;              
    call InitCorbBuf
    call InitRirbBuf
    ret
SetupCodecBuf   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           AddFunction
;
;       DESCRIPTION:    Add HDA function
;
;       PARAMETERS:     BX      Bus/device
;                       CH      Function
;                       EAX     Register base
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AddFunction  Proc near
    push es
    pushad
;    
    int 3
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    xor ebx,ebx
    or ax,803h
    SetPageEntry
;
    push ecx
    AllocateGdt
    mov ecx,1000h
    CreateDataSelector16
    pop ecx
    mov ds:HdaSel,bx
;    
    mov es,bx
    call GetCorbSize
    call GetRirbSize            
    call SetupCodecBuf
;
    popad
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
    mov ax,SEG data
    mov ds,ax
    mov ds:HdaSel,0
;    
    xor ax,ax
    mov bh,4
    mov bl,3
    xor ch,ch
    FindPciClass
    jc init_pci_done
;
    mov cl,10h
    ReadPciDword
    test al,1
    jnz init_pci_done
;    
    and ax,0FFF0h
    call AddFunction
    
init_pci_done:
    ret
InitPciAdapter  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           hda_thread
;
;           DESCRIPTION:    HDA thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

hda_thread_name DB 'HDA Thread', 0

hda_thread:
    int 3
    call InitPciAdapter

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT_DEV
;
;           DESCRIPTION:    Init_dev
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dev    Proc far
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET hda_thread
    mov di,OFFSET hda_thread_name
    mov ax,3
    mov cx,stack0_size
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_dev       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init HDA
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET init_dev
    HookInitTasking
;
    mov esi,OFFSET has_audio
    mov edi,OFFSET has_audio_name
    xor dx,dx
    mov ax,has_audio_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET open_audio_out
    mov edi,OFFSET open_audio_out_name
    xor cl,cl
    mov ax,open_audio_out_nr
    RegisterOsGate
;
    mov esi,OFFSET close_audio_out
    mov edi,OFFSET close_audio_out_name
    xor cl,cl
    mov ax,close_audio_out_nr
    RegisterOsGate
;
    mov esi,OFFSET send_audio_out
    mov edi,OFFSET send_audio_out_name
    xor cl,cl
    mov ax,send_audio_out_nr
    RegisterOsGate
    clc
    ret
init    ENDP

code    ENDS

    END init
