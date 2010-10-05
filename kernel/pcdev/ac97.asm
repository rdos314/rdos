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
; AC97.ASM
; AC97 audio module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                
                NAME ac97

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

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
;               NAME:                   GetMasterVolume
;
;               DESCRIPTION:    Get audio master volume
;
;               RETURNS:                AL      Left channel volume
;                       AH      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_master_volume_name                  DB 'Get Master Volume',0

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
;               NAME:                   SetMasterVolume
;
;               DESCRIPTION:    Set audio master volume
;
;               PARAMETERS:             AL      Left channel volume
;                       AH      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_master_volume_name                  DB 'Set Master Volume',0

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
;               NAME:                   GetLineOutVolume
;
;               DESCRIPTION:    Get line out volume
;
;               RETURNS:                AL      Left channel volume
;                       AH      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_line_out_volume_name                        DB 'Get Line Out Volume',0

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
;               NAME:                   SetLineOutVolume
;
;               DESCRIPTION:    Set line out volume
;
;               PARAMETERS:             AL      Left channel volume
;                       AH      Right channel volume
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_line_out_volume_name                        DB 'Set Line Out Volume',0

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
;               NAME:                   GetDacRate
;
;               DESCRIPTION:    Get audio DAC rate
;
;               RETURNS:                AX      Sampling rate in Hz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_dac_rate_name                       DB 'Get Audio DAC Rate',0

get_dac_rate    PROC far
    push bx
;    
    mov bx,2Ch
    ReadCodec
;    
    pop bx    
        ret
get_dac_rate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SetDacRate
;
;               DESCRIPTION:    Set audio DAC rate
;
;               PARAMETERS:             AX      Sampling rate in Hz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_dac_rate_name                       DB 'Set Audio DAC Rate',0

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
        ret
set_dac_rate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   GetAdcRate
;
;               DESCRIPTION:    Get audio ADC rate
;
;               RETURNS:                AX      Sampling rate in Hz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_adc_rate_name                       DB 'Get Audio ADC Rate',0

get_adc_rate    PROC far
    push bx
;    
    mov bx,32h
    ReadCodec
;    
    pop bx    
        ret
get_adc_rate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SetAdcRate
;
;               DESCRIPTION:    Set audio ADC rate
;
;               PARAMETERS:             AX      Sampling rate in Hz
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_adc_rate_name                       DB 'Set Audio ADC Rate',0

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
        ret
set_adc_rate    ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;               NAME:                   SetCodecGpio0
;
;               DESCRIPTION:    Set Codec GPIO 0 pin
;
;               PARAMETERS:             AL      Pin value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_codec_gpio0_name                    DB 'Set Codec GPIO 0',0

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
;               NAME:               Init
;
;               DESCRIPTION:    Module initialization
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init    PROC far
        mov ax,cs
        mov ds,ax
        mov es,ax
;
        mov si,OFFSET get_dac_rate
        mov di,OFFSET get_dac_rate_name
        xor cl,cl
        mov ax,get_audio_dac_rate_nr
        RegisterOsGate
;
        mov si,OFFSET set_dac_rate
        mov di,OFFSET set_dac_rate_name
        xor cl,cl
        mov ax,set_audio_dac_rate_nr
        RegisterOsGate
;
        mov si,OFFSET get_adc_rate
        mov di,OFFSET get_adc_rate_name
        xor cl,cl
        mov ax,get_audio_adc_rate_nr
        RegisterOsGate
;
        mov si,OFFSET set_adc_rate
        mov di,OFFSET set_adc_rate_name
        xor cl,cl
        mov ax,set_audio_adc_rate_nr
        RegisterOsGate
;
        mov si,OFFSET get_master_volume
        mov di,OFFSET get_master_volume_name
        xor dx,dx
        mov ax,get_master_volume_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET set_master_volume
        mov di,OFFSET set_master_volume_name
        xor dx,dx
        mov ax,set_master_volume_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET get_line_out_volume
        mov di,OFFSET get_line_out_volume_name
        xor dx,dx
        mov ax,get_line_out_volume_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET set_line_out_volume
        mov di,OFFSET set_line_out_volume_name
        xor dx,dx
        mov ax,set_line_out_volume_nr
        RegisterBimodalUserGate
;
        mov si,OFFSET set_codec_gpio0
        mov di,OFFSET set_codec_gpio0_name
        xor dx,dx
        mov ax,set_codec_gpio0_nr
        RegisterBimodalUserGate
;
        ret
init    ENDP

code    ENDS

        END init
