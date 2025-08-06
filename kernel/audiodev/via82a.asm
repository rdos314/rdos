;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; VIA82A.ASM
; Support for AC97 Audio using VT82Cxxx chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\os\protseg.def
INCLUDE ..\os\system.def
INCLUDE ..\os\core.inc
INCLUDE ..\acpi\pci.inc

VIA_PCM_STATUS          = 0
VIA_PCM_CONTROL         = 1
VIA_PCM_TYPE        = 2
VIA_PCM_TABLE_ADDR      = 4
VIA_PCM_BLOCK_COUNT     = 0Ch

VIA_BASE0_AC97_CTRL     = 80h
VIA_BASE0_SGD_STATUS_SHADOW = 84h
VIA_BASE0_GPI_INT_ENABLE    = 8Ch

audio_channel_struc STRUC

AcStatusIo      DW ?
AcControlIo     DW ?
AcTypeIo    DW ?
AcSgdIo     DW ?
AcSgdPhys       DD ?
AcSgd1Phys      DD ?
AcSgd2Phys      DD ?
AcSgdLinear     DD ?
AcSgd1Linear    DD ?
AcSgd2Linear    DD ?
AcCurrSgd       DD ?
AcNotify    DW ?
AcIrqStatus     DB ?

audio_channel_struc ENDS

data    SEGMENT byte public 'DATA'

IoBase      DW ?

Ac0     audio_channel_struc <>
Ac1     audio_channel_struc <>
Ac2     audio_channel_struc <>

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           AudioInt
;
;           DESCRIPTION:    Audio controller interrupt
;
;       PARAMETERS:     
;
;       RETURNS:            CY           Activity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AudioInt    Proc far
    xor ecx,ecx

aiLoop:
    mov dx,ds:IoBase
    add dx,VIA_BASE0_SGD_STATUS_SHADOW
    in eax,dx
    and ax,777h
    jz aiDone
;
    add ecx,1
    jnc aiNotError
;
    int 3

aiNotError:
    test ax,111h
    jz aiNot0
;
    mov dx,ds:Ac0.AcStatusIo
    in al,dx
    and al,7
    jz aiNot0
;
    out dx,al
    or ds:Ac0.AcIrqStatus,al
    mov bx,ds:Ac0.AcNotify
    Signal
    jmp aiLoop

aiNot0:
    test ax,222h
    jz aiNot1
;    
    mov dx,ds:Ac1.AcStatusIo
    in al,dx
    and al,7
    jz aiNot1
;
    out dx,al
    or ds:Ac1.AcIrqStatus,al
    mov bx,ds:Ac1.AcNotify
    Signal
    jmp aiLoop

aiNot1:
    test ax,444h
    jz aiDone
;    
    mov dx,ds:Ac2.AcStatusIo
    in al,dx
    and al,7
    jz aiDone
;
    out dx,al
    or ds:Ac2.AcIrqStatus,al
    mov bx,ds:Ac2.AcNotify
    Signal
    jmp aiLoop

aiDone:
    or ecx,ecx
    stc
    jnz aiExit
;
    clc

aiExit:
    retf32
AudioInt    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadCodec
;
;           DESCRIPTION:    Read CODEC register
;
;       PARAMETERS:     BX      Register
;
;           RETURNS:        AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_codec_name DB 'Read CODEC',0

read_codec      Proc far
    push ds
    push cx
    push dx
;
    mov dx,SEG data
    mov ds,dx
    mov cx,100

rcCheckBusy:    
    mov dx,ds:IoBase
    add dx,VIA_BASE0_AC97_CTRL + 3
    in al,dx
    test al,1
    jz rcNotBusy
;
    mov ax,10
    WaitMilliSec
    loop rcCheckBusy
;
    stc
    jmp rcDone

rcNotBusy:
    movzx eax,bx
    and ax,7Fh
    rol eax,16
    or eax,02800000h
    mov dx,ds:IoBase
    add dx,VIA_BASE0_AC97_CTRL
    out dx,eax
;
    mov ax,20
    WaitMicroSec
    mov cx,100

rcWaitValid:    
    mov dx,ds:IoBase
    add dx,VIA_BASE0_AC97_CTRL + 3
    in al,dx
    test al,1
    jnz rcBusy
;
    test al,2
    jnz rcValidOk

rcBusy:
    mov ax,1
    WaitMicroSec 
    loop rcWaitValid       

rcValidOk:
    mov ax,25
    WaitMicroSec
;
    mov dx,ds:IoBase
    add dx,VIA_BASE0_AC97_CTRL
    in eax,dx
    clc
    
rcDone:
    pop dx
    pop cx
    pop ds    
    retf32
read_codec  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteCodec
;
;           DESCRIPTION:    Write CODEC register
;
;       PARAMETERS:     BX      Register
;                       AX      Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_codec_name DB 'Write CODEC',0

write_codec     Proc far
    push ds
    push cx
    push dx
    push si
;
    mov si,ax
    mov dx,SEG data
    mov ds,dx
    mov cx,100

wcCheckBusy:    
    mov dx,ds:IoBase
    add dx,VIA_BASE0_AC97_CTRL + 3
    in al,dx
    test al,1
    jz wcNotBusy
;
    mov ax,10
    WaitMilliSec
    loop wcCheckBusy
;
    stc
    jmp wcDone

wcNotBusy:
    movzx eax,bx
    and ax,7Fh
    rol eax,16
    or eax,02000000h
    mov ax,si
    mov dx,ds:IoBase
    add dx,VIA_BASE0_AC97_CTRL
    out dx,eax
;
    mov ax,10
    WaitMicroSec
    mov cx,100

wcWaitValid:    
    mov dx,ds:IoBase
    add dx,VIA_BASE0_AC97_CTRL + 3
    in al,dx
    test al,1
    jz wcWaitOk

wcBusy:
    mov ax,15
    WaitMicroSec 
    loop wcWaitValid       

wcWaitOk:
    mov ax,25
    WaitMicroSec
    clc
    
wcDone:
    pop si
    pop dx
    pop cx
    pop ds    
    retf32
write_codec  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateSgdTable
;
;           DESCRIPTION:    Create a Sgd table
;
;       PARAMETERS:     DS:BX       Ac entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateSgdTable  Proc near    
    push es
    push eax
    push ecx
    push edx
    push esi
    push edi
;    
    mov si,bx
;    
    mov ecx,20h
    AllocateMultiplePhysical32
    jc cstDone
;
    mov ds:[si].AcSgd1Phys,eax
    add eax,10000h
    mov ds:[si].AcSgd2Phys,eax
;
    mov eax,10000h
    AllocateBigLinear
    mov ds:[si].AcSgd1Linear,edx
    mov ds:[si].AcCurrSgd,edx
;    
    mov eax,10000h
    AllocateBigLinear
    mov ds:[si].AcSgd2Linear,edx
;
    mov eax,ds:[si].AcSgd1Phys
    mov edx,ds:[si].AcSgd1Linear
    or al,7
    mov cx,10h

cstSgd1Loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop cstSgd1Loop
;
    mov eax,ds:[si].AcSgd2Phys
    mov edx,ds:[si].AcSgd2Linear
    or al,7
    mov cx,10h

cstSgd2Loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop cstSgd2Loop
;
    AllocatePhysical32
    mov ds:[si].AcSgdPhys,eax    
;    
    mov eax,1000h
    AllocateBigLinear
    mov ds:[si].AcSgdLinear,edx
;       
    mov eax,ds:[si].AcSgdPhys
    mov edx,ds:[si].AcSgdLinear
    or al,7
    SetPageEntry
;
    mov ax,flat_sel
    mov es,ax
    mov edi,ds:[si].AcSgdLinear
;
    mov eax,ds:[si].AcSgd1Phys
    stos dword ptr es:[edi]
    mov eax,40000000h
    stos dword ptr es:[edi]
;
    mov eax,ds:[si].AcSgd2Phys
    stos dword ptr es:[edi]
    mov eax,80000000h
    stos dword ptr es:[edi]

cstDone:    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
CreateSgdTable  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeSgdTable
;
;           DESCRIPTION:    Free SGD table
;
;       PARAMETERS:     DS:BX       Ac entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeSgdTable  Proc near    
    push ecx
    push edx
;
    mov edx,ds:[bx].AcSgdLinear
    or edx,edx
    jz fstDone
;    
    mov ecx,10000h
    mov edx,ds:[bx].AcSgd1Linear
    FreeLinear
    mov ds:[bx].AcSgd1Phys,0
    mov ds:[bx].AcSgd1Linear,0
;
    mov ecx,10000h
    mov edx,ds:[bx].AcSgd2Linear
    FreeLinear
    mov ds:[bx].AcSgd2Phys,0
    mov ds:[bx].AcSgd2Linear,0
;
    mov ecx,1000h
    mov edx,ds:[bx].AcSgdLinear
    FreeLinear
    mov ds:[bx].AcSgdPhys,0
    mov ds:[bx].AcSgdLinear,0

fstDone:
    pop edx
    pop ecx
    ret
FreeSgdTable  Endp


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
    push ds
    push eax
    push bx
    push dx
;
    mov ax,SEG data
    mov ds,ax
    mov bx,OFFSET Ac0
    call CreateSgdTable
;
    mov dx,ds:IoBase
    add dx,VIA_PCM_TABLE_ADDR
    mov eax,ds:Ac0.AcSgdPhys
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,VIA_PCM_TYPE
    mov al,0B7h
    out dx,al
;
    pop dx
    pop bx
    pop eax
    pop ds
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
    push ds
    push ax
    push bx
    push dx
;
    mov ax,SEG data
    mov ds,ax
;
    mov dx,ds:Ac0.AcControlIo
    mov al,40h
    out dx,al
;
    mov bx,OFFSET Ac0
    call FreeSgdTable
;
    pop dx
    pop bx
    pop ax
    pop ds
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
    push ds
    push es
    push fs
    push gs
    pushad
;
    mov ax,ds
    mov fs,ax
    mov ax,es
    mov gs,ax
    mov ax,SEG data
    mov ds,ax
    mov ax,flat_sel
    mov es,ax
;
    mov esi,2
    push cx
    mov edi,ds:Ac0.AcCurrSgd

saoDataLoop:    
    mov ax,fs:[esi]
    stos word ptr es:[edi]
    mov ax,gs:[esi]
    stos word ptr es:[edi]
    add esi,4
    loop saoDataLoop
;
    pop cx
    mov ax,cx
    shl ax,2
    mov edx,ds:Ac0.AcSgdLinear
    mov edi,ds:Ac0.AcCurrSgd
    cmp edi,ds:Ac0.AcSgd1Linear
    je saoPrd1

saoPrd2:
    add edx,8
    mov es:[edx+4],ax
    mov edi,ds:Ac0.AcSgd1Linear
    mov ds:Ac0.AcCurrSgd,edi
    jmp saoPrdOk

saoPrd1:
    mov es:[edx+4],ax
    mov edi,ds:Ac0.AcSgd2Linear
    mov ds:Ac0.AcCurrSgd,edi
    add edx,8
    mov ax,es:[edx+4]
    or ax,ax
    jz saoDone

saoPrdOk:
    GetThread
    mov ds:Ac0.AcNotify,ax
;    
    mov dx,ds:Ac0.AcStatusIo
    in al,dx
    test al,80h
    jnz saoRunning
;
    mov dx,ds:Ac0.AcControlIo
    mov al,80h
    out dx,al

saoRunning:
    WaitForSignal
    mov al,ds:Ac0.AcIrqStatus
    test al,3
    jz saoRunning
;
    mov ds:Ac0.AcIrqStatus,0
        
saoDone:              
    popad
    pop gs
    pop fs
    pop es
    pop ds    
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
    push ds
    push ax
;
    mov ax,SEG data
    mov ds,ax
    mov ax,ds:IoBase
    or ax,ax
    stc
    jz haDone
;
    clc

haDone:
    pop ax
    pop ds
    retf32    
has_audio  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_dev
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DevName DB 'Via82a', 0

PciVendorTab:
pci00   DW 1106h, 3058h
pci01   DW 0,     0
    
init_dev    Proc far
    push ds
    push es
    pusha
;
    mov ax,cs
    mov es,ax
    mov ax,SEG data
    mov ds,ax
    mov ds:IoBase,0
    mov si,OFFSET PciVendorTab
    xor bx,bx

ipLoop:
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz ipDone
;
    FindPciDevice
    jnc ipFound
;
    add si,4
    jmp ipLoop

ipFound:
    xor al,al
    GetPciBarIo
    jc ipLoop
;
    mov edi,OFFSET DevName
    LockPciHandle
    mov ds:IoBase,dx
;
    mov cl,41h
    ReadPciConfigByte
;
    mov al,0CCh
    WritePciConfigByte
; 
    mov al,1Ah
    mov di,cs
    mov es,di
    mov edi,OFFSET AudioInt
    SetupPciIrq
;
    mov dx,ds:IoBase
    mov cx,3
    mov bx,OFFSET Ac0
    xor ax,ax

init_ch_loop:
    mov si,ax
    add si,dx
    mov ds:[bx].AcStatusIo,si
    inc si
    mov ds:[bx].AcControlIo,si
    inc si
    mov ds:[bx].AcTypeIo,si
    add si,2
    mov ds:[bx].AcSgdIo,si
;
    mov ds:[bx].AcSgdPhys,0
    mov ds:[bx].AcSgd1Phys,0
    mov ds:[bx].AcSgd2Phys,0
    mov ds:[bx].AcSgdLinear,0
    mov ds:[bx].AcSgd1Linear,0
    mov ds:[bx].AcSgd2Linear,0
    mov ds:[bx].AcNotify,0
    mov ds:[bx].AcIrqStatus,0
;
    add bx,SIZE audio_channel_struc
    add ax,10h
    loop init_ch_loop

ipDone:
    popa
    pop es
    pop ds
    retf32
init_dev    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init AC97 on chipset
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET init_dev
    HookInitPci
;
    mov esi,OFFSET has_audio
    mov edi,OFFSET has_audio_name
    xor dx,dx
    mov ax,has_audio_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET read_codec
    mov edi,OFFSET read_codec_name
    xor cl,cl
    mov ax,read_codec_nr
    RegisterOsGate
;
    mov esi,OFFSET write_codec
    mov edi,OFFSET write_codec_name
    xor cl,cl
    mov ax,write_codec_nr
    RegisterOsGate
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
