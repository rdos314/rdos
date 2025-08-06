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
; CS5536A.ASM
; Support for AC97 Audio using Geod companion chip CS5536
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

ACC_GPIO_STATUS = 0
ACC_GPIO_CONTROL = 4
ACC_CODEC_STATUS = 8
ACC_CODEC_CONTROL = 0Ch
ACC_IRQ_STATUS = 12h
ACC_ENGINE_CONTROL = 14h
ACC_BM0 = 20h
ACC_BM1 = 28h
ACC_BM2 = 30h
ACC_BM3 = 38h
ACC_BM4 = 40h
ACC_BM5 = 48h
ACC_BM6 = 50h
ACC_BM7 = 58h

ACC_BM_CMD = 0
ACC_BM_STATUS = 1
ACC_BM_PRD = 4

AC_FLAG_RUNNING = 1

audio_channel_struc STRUC

AcCmdIo     DW ?
AcStatusIo      DW ?       
AcPrdIo     DW ?
AcPrdPhys       DD ?
AcPrd1Phys      DD ?
AcPrd2Phys      DD ?
AcPrdLinear     DD ?
AcPrd1Linear    DD ?
AcPrd2Linear    DD ?
AcCurrPrd       DD ?
AcNotify    DW ?
AcIrqStatus     DB ?
AcFlags     DB ?

audio_channel_struc ENDS

data    SEGMENT byte public 'DATA'

IoBase      DW ?

Ac0     audio_channel_struc <>
Ac1     audio_channel_struc <>
Ac2     audio_channel_struc <>
Ac3     audio_channel_struc <>
Ac4     audio_channel_struc <>
Ac5     audio_channel_struc <>
Ac6     audio_channel_struc <>
Ac7     audio_channel_struc <>

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
;           RETURNS:        CY           Activity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AudioInt    Proc far
    xor ecx,ecx

aiLoop:
    mov dx,ds:IoBase
    add dx,ACC_IRQ_STATUS
    in ax,dx
    test ax,3FCh
    jz aiDone
;
    add ecx,1
    jnc aiNotError
;
    int 3

aiNotError:
    test ax,4
    jz aiNot0
;    
    push ax
    mov dx,ds:Ac0.AcStatusIo
    in al,dx
    or ds:Ac0.AcIrqStatus,al
    mov bx,ds:Ac0.AcNotify
    Signal
    pop ax

aiNot0:
    test ax,8
    jz aiNot1
;    
    push ax
    mov dx,ds:Ac1.AcStatusIo
    in al,dx
    or ds:Ac1.AcIrqStatus,al
    mov bx,ds:Ac1.AcNotify
    Signal
    pop ax

aiNot1:
    test ax,10h
    jz aiNot2
;    
    push ax
    mov dx,ds:Ac2.AcStatusIo
    in al,dx
    or ds:Ac2.AcIrqStatus,al
    mov bx,ds:Ac2.AcNotify
    Signal
    pop ax

aiNot2:
    test ax,20h
    jz aiNot3
;    
    push ax
    mov dx,ds:Ac3.AcStatusIo
    in al,dx
    or ds:Ac3.AcIrqStatus,al
    mov bx,ds:Ac3.AcNotify
    Signal
    pop ax

aiNot3:
    test ax,40h
    jz aiNot4
;    
    push ax
    mov dx,ds:Ac4.AcStatusIo
    in al,dx
    or ds:Ac4.AcIrqStatus,al
    mov bx,ds:Ac4.AcNotify
    Signal
    pop ax

aiNot4:
    test ax,80h
    jz aiNot5
;    
    push ax
    mov dx,ds:Ac5.AcStatusIo
    in al,dx
    or ds:Ac5.AcIrqStatus,al
    mov bx,ds:Ac5.AcNotify
    Signal
    pop ax

aiNot5:
    test ax,100h
    jz aiNot6
;    
    push ax
    mov dx,ds:Ac6.AcStatusIo
    in al,dx
    or ds:Ac6.AcIrqStatus,al
    mov bx,ds:Ac6.AcNotify
    Signal
    pop ax

aiNot6:
    test ax,200h
    jz aiNot7
;    
    push ax
    mov dx,ds:Ac7.AcStatusIo
    in al,dx
    or ds:Ac7.AcIrqStatus,al
    mov bx,ds:Ac7.AcNotify
    Signal
    pop ax

aiNot7:

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
    add dx,ACC_CODEC_CONTROL
    in eax,dx
    test eax,10000h
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
    ror eax,8
    or eax,80010000h
    out dx,eax
;
    mov cx, 100    

rcDataLoop:
    mov dx,ds:IoBase
    add dx,ACC_CODEC_STATUS
    in eax,dx
    test eax,20000h
    jnz rcDataOk
;
    mov ax,10
    WaitMilliSec    
    loop rcDataLoop

rcFail:
    stc
    jmp rcDone    

rcDataOk:
    mov edx,eax
    rol edx,8
    cmp dl,bl
    jne rcFail
;    
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
    push eax
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
    add dx,ACC_CODEC_CONTROL
    in eax,dx
    test eax,10000h
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
    ror eax,8
    or eax,10000h
    mov ax,si
    out dx,eax
    clc

wcDone:    
    pop si
    pop dx
    pop cx
    pop eax
    pop ds
    retf32
write_codec  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreatePrdTable
;
;           DESCRIPTION:    Create a PRD table
;
;       PARAMETERS:     DS:BX       Ac entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreatePrdTable  Proc near    
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
    jc cptDone
;
    mov ds:[si].AcPrd1Phys,eax
    add eax,10000h
    mov ds:[si].AcPrd2Phys,eax
;
    mov eax,10000h
    AllocateBigLinear
    mov ds:[si].AcPrd1Linear,edx
    mov ds:[si].AcCurrPrd,edx
;    
    mov eax,10000h
    AllocateBigLinear
    mov ds:[si].AcPrd2Linear,edx
;
    mov eax,ds:[si].AcPrd1Phys
    mov edx,ds:[si].AcPrd1Linear
    or al,7
    mov cx,10h

cptPrd1Loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop cptPrd1Loop
;
    mov eax,ds:[si].AcPrd2Phys
    mov edx,ds:[si].AcPrd2Linear
    or al,7
    mov cx,10h

cptPrd2Loop:
    SetPageEntry
    add eax,1000h
    add edx,1000h
    loop cptPrd2Loop
;
    AllocatePhysical32
    mov ds:[si].AcPrdPhys,eax    
;    
    mov eax,1000h
    AllocateBigLinear
    mov ds:[si].AcPrdLinear,edx
;       
    mov eax,ds:[si].AcPrdPhys
    mov edx,ds:[si].AcPrdLinear
    or al,7
    SetPageEntry
;
    mov ax,flat_sel
    mov es,ax
    mov edi,ds:[si].AcPrdLinear
;
    mov eax,ds:[si].AcPrd1Phys
    stos dword ptr es:[edi]
    mov eax,40000000h
    stos dword ptr es:[edi]
;
    mov eax,ds:[si].AcPrd2Phys
    stos dword ptr es:[edi]
    mov eax,40000000h
    stos dword ptr es:[edi]
;
    mov eax,ds:[si].AcPrdPhys
    stos dword ptr es:[edi]
    mov eax,20000000h
    stos dword ptr es:[edi]            
;
    mov ds:[si].AcFlags,0    

cptDone:    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    pop es
    ret
CreatePrdTable  Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreePrdTable
;
;           DESCRIPTION:    Free PRD table
;
;       PARAMETERS:     DS:BX       Ac entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreePrdTable  Proc near    
    push ecx
    push edx
;
    mov edx,ds:[bx].AcPrdLinear
    or edx,edx
    jz fptDone
;    
    mov ecx,10000h
    mov edx,ds:[bx].AcPrd1Linear
    FreeLinear
    mov ds:[bx].AcPrd1Phys,0
    mov ds:[bx].AcPrd1Linear,0
;
    mov ecx,10000h
    mov edx,ds:[bx].AcPrd2Linear
    FreeLinear
    mov ds:[bx].AcPrd2Phys,0
    mov ds:[bx].AcPrd2Linear,0
;
    mov ecx,1000h
    mov edx,ds:[bx].AcPrdLinear
    FreeLinear
    mov ds:[bx].AcPrdPhys,0
    mov ds:[bx].AcPrdLinear,0

fptDone:
    pop edx
    pop ecx
    ret
FreePrdTable  Endp


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
    mov dx,ds:IoBase
    add dx,ACC_BM0 + ACC_BM_PRD
    mov eax,ds:Ac0.AcPrdPhys
    out dx,eax
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
    mov dx,ds:Ac0.AcCmdIo
    in al,dx
    and al,NOT 3
    out dx,al
;    
    mov dx,ds:IoBase
    add dx,ACC_BM0 + ACC_BM_PRD
    xor eax,eax
    out dx,eax
;    
    and ds:Ac0.AcFlags,NOT AC_FLAG_RUNNING
    mov ds:Ac0.AcNotify,0
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
    test ds:Ac0.AcFlags, AC_FLAG_RUNNING
    jnz saoWait
;
    or ds:Ac0.AcFlags, AC_FLAG_RUNNING
    mov ds:Ac0.AcIrqStatus,0
    jmp saoBuffer

saoWait:    
    mov dx,ds:Ac0.AcCmdIo
    in al,dx
    and al,3
    cmp al,1
    je saoWaitLoop
;
    and al,NOT 7
    or al,1
    out dx,al
;
    mov ax,1
    WaitMilliSec    

saoWaitLoop:
    GetThread
    mov ds:Ac0.AcNotify,ax
;    
    mov dx,ds:IoBase
    add dx,ACC_BM0 + ACC_BM_PRD
    in eax,dx
;
    mov edi,ds:Ac0.AcCurrPrd
    cmp edi,ds:Ac0.AcPrd1Linear
    je saoWait1

saoWait2:
    test ax,8
    jnz saoBuffer
;
    jmp saoWaitAgain    

saoWait1:
    test ax,8
    jz saoBuffer

saoWaitAgain:    
    WaitForSignal
    mov ds:Ac0.AcIrqStatus,0
    mov ds:Ac0.AcNotify,0
    jmp saoWaitLoop

saoBuffer:
    or cx,cx
    jz saoStop
;    
    mov esi,2
    push cx
    mov edi,ds:Ac0.AcCurrPrd

saoDataLoop:    
    mov ax,fs:[esi]
    stos word ptr es:[edi]
    mov ax,gs:[esi]
    stos word ptr es:[edi]
    add esi,4
    loop saoDataLoop
;
    pop cx
;    
    mov ax,cx
    shl ax,2
    mov edx,ds:Ac0.AcPrdLinear
    mov edi,ds:Ac0.AcCurrPrd
    cmp edi,ds:Ac0.AcPrd1Linear
    je saoPrd1

saoPrd2:
    add edx,8
    mov es:[edx+4],ax
    mov edi,ds:Ac0.AcPrd1Linear
    mov ds:Ac0.AcCurrPrd,edi
    jmp saoDone

saoPrd1:
    mov es:[edx+4],ax
    mov edi,ds:Ac0.AcPrd2Linear
    mov ds:Ac0.AcCurrPrd,edi
    jmp saoDone

saoStop:
    mov dx,ds:Ac0.AcCmdIo
    in al,dx
    and al,3
    out dx,al
    and ds:Ac0.AcFlags,NOT AC_FLAG_RUNNING
        
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

DevName DB 'CS5536a', 0

PciVendorTab:
pci00   DW 1022h, 2093h
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
;    
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
    LockPci
    mov ds:IoBase,dx
;
    mov al,1Ah
    mov di,cs
    mov es,di
    mov edi,OFFSET AudioInt
    SetupPciIrq
;
    mov dx,ds:IoBase
    mov cx,8
    mov bx,OFFSET Ac0
    mov ax,ACC_BM0

init_ch_loop:
    mov si,ax
    add si,dx
    mov ds:[bx].AcCmdIo,si
    inc si
    mov ds:[bx].AcStatusIo,si
    add si,3
    mov ds:[bx].AcPrdIo,si
;
    mov ds:[bx].AcPrdPhys,0
    mov ds:[bx].AcPrd1Phys,0
    mov ds:[bx].AcPrd2Phys,0
    mov ds:[bx].AcPrdLinear,0
    mov ds:[bx].AcPrd1Linear,0
    mov ds:[bx].AcPrd2Linear,0
    mov ds:[bx].AcIrqStatus,0
    mov ds:[bx].AcNotify,0
;
    add bx,SIZE audio_channel_struc
    add ax,8
    loop init_ch_loop
;
    mov ax,SEG data
    mov ds,ax
    mov bx,OFFSET Ac0
    call CreatePrdTable

ipDone:
;
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
