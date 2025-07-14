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
; AC97.ASM
; AC97 audio module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE ..\os\system.inc

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetVolume
;
;           DESCRIPTION:    Get audio volume
;
;           RETURNS:        EAX      Left channel volume
;                           EDX      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_volume_name          DB 'Get Volume',0

get_volume       PROC far
    push bx
    push cx
;    
    mov bx,2
    ReadCodec
;
    test ah,80h
    jnz gvMute
;
    xchg al,ah
    and ax,1F1Fh
    shl ax,2
    jmp gvConv

gvMute:
    mov ax,8080h

gvConv:
    mov cx,ax
    mov dl,7Fh
    sub dl,al
    movsx edx,dl    
    mov eax,200
    imul edx
    sar eax,8
    push eax
    mov dl,7Fh
    sub dl,ch
    movsx edx,dl
    mov eax,200
    imul edx
    sar eax,8
    pop edx
;    
    pop cx
    pop bx    
    retf32
get_volume       ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetVolume
;
;           DESCRIPTION:    Set audio volume
;
;           PARAMETERS:     EAX     Left channel volume
;                           EDX     Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_volume_name          DB 'Set Volume',0

set_volume       PROC far
    pushad
;
    mov ecx,edx
    mov esi,eax
    xor edx,edx
    shl eax,8
    sbb edx,0
    mov esi,200
    idiv esi
    mov bl,7Fh
    sub bl,al
    adc bl,0
    mov eax,ecx
    mov esi,eax
    xor edx,edx
    shl eax,8
    sbb edx,0
    mov esi,200
    idiv esi
    mov bh,0x7F
    sub bh,al
    adc bh,0
    mov ax,bx
;
    cmp ax,8080h
    je svSet
;
    and ax,7F7Fh
    shr ax,2

svSet:    
    mov bx,2
    WriteCodec
;    
    mov bx,4
    WriteCodec
;    
    mov bx,6
    WriteCodec
;
    popad
    retf32
set_volume       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetMasterVolume
;
;           DESCRIPTION:    Get audio master volume
;
;           RETURNS:        AL      Left channel volume
;               AH      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_master_volume_name          DB 'Get Master Volume',0

get_master_volume       PROC far
    push bx
;    
    mov bx,2
    ReadCodec
;
    test ah,80h
    jnz gmvMute
;
    xchg al,ah
    and ax,1F1Fh
    shl ax,2
    jmp gmvDone    

gmvMute:
    mov ax,8080h

gmvDone:
    pop bx    
    retf32
get_master_volume       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetMasterVolume
;
;           DESCRIPTION:    Set audio master volume
;
;           PARAMETERS:         AL      Left channel volume
;               AH      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_master_volume_name          DB 'Set Master Volume',0

set_master_volume       PROC far
    push ax
    push bx
;
    cmp ax,8080h
    je smvSet
;
    and ax,7F7Fh
    shr ax,2

smvSet:    
    mov bx,2
    WriteCodec
;    
    mov bx,4
    WriteCodec
;    
    mov bx,6
    WriteCodec
;
    pop bx    
    pop ax
    retf32
set_master_volume       ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetLineOutVolume
;
;           DESCRIPTION:    Get line out volume
;
;           RETURNS:        AL      Left channel volume
;               AH      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_line_out_volume_name            DB 'Get Line Out Volume',0

get_line_out_volume     PROC far
    push bx
;    
    mov bx,18h
    ReadCodec
;
    test ah,80h
    jnz glovMute
;
    xchg al,ah
    and ax,1F1Fh
    shl ax,2
    jmp glovDone    

glovMute:
    mov ax,8080h

glovDone:
    pop bx    
    retf32
get_line_out_volume     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetLineOutVolume
;
;           DESCRIPTION:    Set line out volume
;
;           PARAMETERS:         AL      Left channel volume
;               AH      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_line_out_volume_name            DB 'Set Line Out Volume',0

set_line_out_volume     PROC far
    push ax
    push bx
;
    cmp ax,8080h
    je slovSet
;
    and ax,7F7Fh
    shr ax,2

slovSet:    
    xor ax,ax
;    mov ax,0808h
    mov bx,18h
    WriteCodec
;
    pop bx    
    pop ax
    retf32
set_line_out_volume     ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetDacRate
;
;           DESCRIPTION:    Get audio DAC rate
;
;           RETURNS:        AX      Sampling rate in Hz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dac_rate_name               DB 'Get Audio DAC Rate',0

get_dac_rate    PROC far
    push bx
;    
    mov bx,2Ch
    ReadCodec
;    
    pop bx    
    retf32
get_dac_rate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetDacRate
;
;           DESCRIPTION:    Set audio DAC rate
;
;           PARAMETERS:         AX      Sampling rate in Hz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dac_rate_name               DB 'Set Audio DAC Rate',0

set_dac_rate    PROC far
    push bx
;
    push ax
    mov bx,2Ah
    ReadCodec
    or al,1
    WriteCodec
    pop ax 
;       
    mov bx,2Ch
    WriteCodec
;    
    pop bx    
    retf32
set_dac_rate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           GetAdcRate
;
;           DESCRIPTION:    Get audio ADC rate
;
;           RETURNS:        AX      Sampling rate in Hz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_adc_rate_name               DB 'Get Audio ADC Rate',0

get_adc_rate    PROC far
    push bx
;    
    mov bx,32h
    ReadCodec
;    
    pop bx    
    retf32
get_adc_rate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetAdcRate
;
;           DESCRIPTION:    Set audio ADC rate
;
;           PARAMETERS:         AX      Sampling rate in Hz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_adc_rate_name               DB 'Set Audio ADC Rate',0

set_adc_rate    PROC far
    push bx
;    
    push ax
    mov bx,2Ah
    ReadCodec
    or al,1
    WriteCodec
    pop ax 
;    
    mov bx,32h
    WriteCodec
;    
    pop bx    
    retf32
set_adc_rate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           SetCodecGpio0
;
;           DESCRIPTION:    Set Codec GPIO 0 pin
;
;           PARAMETERS:         AL      Pin value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_codec_gpio0_name            DB 'Set Codec GPIO 0',0

set_codec_gpio0 PROC far
    push ax
    push bx
    push dx
;
    mov dh,al
    mov bx,78h
    ReadCodec
    and ah,NOT 1
    or ah,dh
    WriteCodec
;
    mov bx,76h
    ReadCodec
    or al,1
    WriteCodec    
;    
    pop dx
    pop bx    
    pop ax 
    retf32
set_codec_gpio0 ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           Init
;
;           DESCRIPTION:    Module initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_dac_rate
    mov edi,OFFSET get_dac_rate_name
    xor cl,cl
    mov ax,get_audio_dac_rate_nr
    RegisterOsGate
;
    mov esi,OFFSET set_dac_rate
    mov edi,OFFSET set_dac_rate_name
    xor cl,cl
    mov ax,set_audio_dac_rate_nr
    RegisterOsGate
;
    mov esi,OFFSET get_adc_rate
    mov edi,OFFSET get_adc_rate_name
    xor cl,cl
    mov ax,get_audio_adc_rate_nr
    RegisterOsGate
;
    mov esi,OFFSET set_adc_rate
    mov edi,OFFSET set_adc_rate_name
    xor cl,cl
    mov ax,set_audio_adc_rate_nr
    RegisterOsGate
;
    mov esi,OFFSET get_volume
    mov edi,OFFSET get_volume_name
    xor dx,dx
    mov ax,get_output_volume_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_volume
    mov edi,OFFSET set_volume_name
    xor dx,dx
    mov ax,set_output_volume_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_master_volume
    mov edi,OFFSET set_master_volume_name
    xor dx,dx
    mov ax,set_master_volume_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET get_line_out_volume
    mov edi,OFFSET get_line_out_volume_name
    xor dx,dx
    mov ax,get_line_out_volume_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_line_out_volume
    mov edi,OFFSET set_line_out_volume_name
    xor dx,dx
    mov ax,set_line_out_volume_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_codec_gpio0
    mov edi,OFFSET set_codec_gpio0_name
    xor dx,dx
    mov ax,set_codec_gpio0_nr
    RegisterBimodalUserGate
;
    ret
init    ENDP

code    ENDS

    END init
