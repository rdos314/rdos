;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2002, Leif Ekblad
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
; AUDIO.ASM
; Audio module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME audio

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.def
INCLUDE protseg.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\driver.def
INCLUDE system.inc
INCLUDE ..\handle.inc

AMS_MAX_CHANNELS  = 16

audio_mixer_sel STRUC

ams_out_buf_pos     DW ?

ams_outl_buf_sel    DW ?
ams_outr_buf_sel    DW ?

ams_buffer_size     DW ?
ams_sample_rate     DW ?

ams_count           DW ?
ams_sel_arr         DW AMS_MAX_CHANNELS + 1 DUP(?)

audio_mixer_sel ENDS

audio_out_sel   STRUC

aos_volume          DD ?
aos_mixer           DW ?
aos_thread          DW ?
aos_sample_rate     DW ?
aos_buffer_size     DW ?
aos_bits            DB ?
aos_flags           DB ?
aos_min_val         DD ?
aos_max_val         DD ?
aos_shift           DB ?

aos_in_buf_pos      DW ?

aos_inl_buf_sel     DW ?
aos_inr_buf_sel     DW ?

audio_out_sel   ENDS

audio_out_struc	STRUC

ao_base		handle_header <>
ao_sel		DW ?

audio_out_struc	ENDS

audio_data_seg  STRUC

ads_section     section_typ <>
ads_thread      DW ?
ads_out_mixer   DW ?

audio_data_seg  ENDS

code	SEGMENT byte public use16 'CODE'

	.386

	assume cs:code

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateMixer
;
;		DESCRIPTION:	Create mixer
;
;       PARAMETERS:     CX  Sample rate
;
;		RETURNS:	    AX  Mixer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMixer Proc near
    push ds
    push es
;    
    mov eax,SIZE audio_mixer_sel
    AllocateSmallGlobalMem
    mov ax,es
    mov ds,ax
    mov ds:ams_count,0
    mov ds:ams_sample_rate,cx
;    
    shr cx,4
    mov ds:ams_buffer_size,cx
    movzx eax,cx
    shl eax,2
    AllocateSmallGlobalMem
    mov ds:ams_outl_buf_sel,es
    AllocateSmallGlobalMem
    mov ds:ams_outr_buf_sel,es
    mov ds:ams_out_buf_pos,0
    mov ax,ds
;
    pop es
    pop ds
    ret
CreateMixer Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			DeleteMixer
;
;		DESCRIPTION:	Delete mixer
;
;       PARAMETERS:     DS  Mixer sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeleteMixer Proc near
    push es
    push fs
    push ax
;    
    mov ax,audio_data_sel
    mov fs,ax
;
    mov es,ds:ams_outl_buf_sel
    FreeMem
    mov es,ds:ams_outr_buf_sel
    FreeMem
;
    mov ax,ds
    cmp ax,fs:ads_out_mixer
    jne dmNotOut
;
    mov fs:ads_out_mixer,0
    CloseAudioOut
    jmp dmFree

dmNotOut:
    int 3
    
dmFree:   
    mov es,ax
    xor ax,ax
    mov ds,ax
    FreeMem
;
    pop ax
    pop fs
    pop es
    ret
DeleteMixer Endp
    
PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CreateAudioOutChannel
;
;		DESCRIPTION:	Create audio out channel
;
;		PARAMETERS:	    AX      Sample rate
;                       CL      Bits (0..32)
;                       DX      Volume (0..65535)
;
;		RETURNS:		BX		Audio out handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_audio_out_channel_name	DB 'Create Audio Out Channel', 0

create_audio_out_channel	Proc far
    push es
    push ds
    push cx
    push edx
;
    push cx
	mov cx,SIZE audio_out_struc
	AllocateHandle
	mov ds:[bx].hh_sign,AUDIO_OUT_HANDLE
	pop cx
;
    push eax
    mov eax,SIZE audio_out_sel
    AllocateSmallGlobalMem
    pop eax
    mov es:aos_sample_rate,ax	
    shr ax,4
    mov es:aos_buffer_size,ax
    mov es:aos_bits,cl
    rol edx,16
    mov dx,-1
    mov es:aos_volume,edx
    mov [bx].ao_sel,es
;    
    mov al,32
    sub al,cl
    mov es:aos_shift,al            
;
    dec cl
    mov eax,1
    shl eax,cl
    dec eax
    mov es:aos_max_val,eax
    neg eax
    mov es:aos_min_val,eax
;    
    push ds
    mov ax,es
    mov ds,ax
;    
    mov ds:aos_flags,0
    mov ds:aos_thread,0
    movzx eax,ds:aos_buffer_size
    shl eax,2
    AllocateSmallGlobalMem
    mov ds:aos_inl_buf_sel,es
    AllocateSmallGlobalMem
    mov ds:aos_inr_buf_sel,es
    mov ds:aos_in_buf_pos,0
;    
    mov dx,ds
    mov cx,ds:aos_sample_rate
;    
    mov ax,audio_data_sel
    mov ds,ax
    push esi
    mov esi,OFFSET ads_section
    EnterNewSection
    pop esi
;    
    mov ax,ds:ads_out_mixer
    or ax,ax
    jnz caocHasMixer
;
    mov ax,cx
    SetAudioDacRate
    GetAudioDacRate
    mov cx,ax
    call CreateMixer
    mov ds:ads_out_mixer,ax    
    OpenAudioOut

caocHasMixer:
    push bx
    mov es,ax
    mov bx,OFFSET ams_sel_arr
    mov ax,es:ams_count
    shl ax,1
    add bx,ax
    mov es:[bx],dx
    mov ds,dx
    mov ds:aos_mixer,es
    inc es:ams_count
;    
    mov ax,audio_data_sel
    mov ds,ax
    push esi
    mov esi,OFFSET ads_section
    LeaveNewSection
    pop esi
    pop bx    
    pop ds
;	
	mov bx,[bx].hh_handle
	pop edx
	pop cx
	pop ds
	pop es
	clc
	retf32
create_audio_out_channel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FreeMixerChannel
;
;		DESCRIPTION:	Free a mixer channel
;
;		PARAMETERS:	    DS      Channel sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FreeMixerChannel	Proc near
    push ds
    push es
    push fs
    push ax
    push bx
    push cx
    push dx
;    
    mov fs,ds:aos_mixer
    mov dx,ds
;    
	mov ax,audio_data_sel
	mov ds,ax
    push esi
    mov esi,OFFSET ads_section
    EnterNewSection
    pop esi
;    
    mov cx,fs:ams_count
    mov bx,OFFSET ams_sel_arr

fmcFind:
    cmp dx,fs:[bx]
    je fmcCopy
;
    add bx,2
    loop fmcFind    
;
    jmp fmcDone

fmcCopy:
    mov ax,fs:[bx+2]
    mov fs:[bx],ax
;
    add bx,2
    loop fmcCopy    
;    
    dec fs:ams_count

fmcDone:        
    xor ax,ax
    mov fs,ax
    push esi
    mov esi,OFFSET ads_section
    LeaveNewSection
    pop esi
;	
    pop dx
    pop cx
    pop bx
    pop ax
    pop fs
    pop es
    pop ds
    ret
FreeMixerChannel    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			FlushChannel
;
;		DESCRIPTION:	Flush channel
;
;		PARAMETERS:	    DS      Channel sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FlushChannel    Proc near
    push ds
    push es
    pushad

    mov cx,ds:aos_buffer_size
    sub cx,ds:aos_in_buf_pos
    or cx,cx
    jz fcDone
;
    movzx ecx,cx
    movzx edi,ds:aos_in_buf_pos
    shl edi,2
    xor eax,eax
    push ecx
    push edi
    mov es,ds:aos_inl_buf_sel
    rep stos dword ptr es:[edi]
    pop edi
    pop ecx
;
    mov es,ds:aos_inr_buf_sel
    rep stos dword ptr es:[edi]
;
    mov cx,ds:aos_buffer_size
    mov ds:aos_in_buf_pos,cx

fcWait:
    GetThread
    mov ds:aos_thread,ax
;
    mov ax,audio_data_sel
    mov ds,ax
	mov bx,ds:ads_thread
    Signal        
;
    GetSystemTime
    add eax,1193 * 100
    adc edx,0
    WaitForSignalWithTimeout

fcDone:
    popad
    pop es
    pop ds
    ret
FlushChannel    Endp        

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_out_channel
;
;		DESCRIPTION:	Delete out channel
;
;		PARAMETERS:		DS:BX		Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_out_channel	Proc near
    push es
;
    push ds
    mov ds,[bx].ao_sel
    call FlushChannel
    call FreeMixerChannel
    mov es,ds:aos_inl_buf_sel
    FreeMem
    mov es,ds:aos_inr_buf_sel
    FreeMem
    mov ax,ds
    mov es,ax
    pop ds
;    
    FreeMem
	FreeHandle
;
	clc
    pop es
	ret
delete_out_channel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			CloseAudioOutChannel
;
;		DESCRIPTION:	Close audio out channel
;
;		PARAMETERS:		BX		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_audio_out_channel_name	DB 'Close Audio Out Channel', 0

close_audio_out_channel	Proc far
	push ds
	push ax
	push bx
;
	mov ax,AUDIO_OUT_HANDLE
	DerefHandle
	jc caicDone
;
	call delete_out_channel

caicDone:
	pop bx
	pop ax
	pop ds
	retf32
close_audio_out_channel	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			AddAudio
;
;		DESCRIPTION:	Add audio data to channel
;
;		PARAMETERS:		DS          Channel sel
;                       ECX         Size
;                       ES:ESI      Left
;                       FS:EDI      Right
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

add_audio   Proc near
    push fs
    push gs
    pushad

aaMoreData:
    or ecx,ecx
    jz aaDone
;    
    push ecx
;    
    mov ax,ds:aos_buffer_size
    sub ax,ds:aos_in_buf_pos
    movzx eax,ax
;
    cmp ecx,eax
    jbe aaWhole
;
    mov ecx,eax

aaWhole:    
    or ecx,ecx
    jnz aaDo
;
    pop ecx
    GetThread
    mov ds:aos_thread,ax
;
    push ds
    mov ax,audio_data_sel
    mov ds,ax
	mov bx,ds:ads_thread
	pop ds
    Signal    
;    
    WaitForSignal
    jmp aaMoreData
        
aaDo:
    movzx ebx,ds:aos_in_buf_pos
    shl ebx,2
;    
    mov gs,ds:aos_inl_buf_sel
    mov ebp,ecx
    push ecx

aaLLoop:    
    mov eax,es:[esi]
    cmp eax,ds:aos_max_val
    jl aaLMaxOk
;
    mov eax,ds:aos_max_val

aaLMaxOk:
    cmp eax,ds:aos_min_val
    jg aaLMinOk
;
    mov eax,ds:aos_min_val

aaLMinOk:
    mov cl,ds:aos_shift
    shl eax,cl
    mul ds:aos_volume
    add eax,80000000h
    adc edx,0
    mov gs:[ebx],edx
    add bx,4
    add esi,4
    sub ebp,1
    jnz aaLLoop
;
    pop ecx
    movzx ebx,ds:aos_in_buf_pos
    shl ebx,2
;    
    mov gs,ds:aos_inr_buf_sel
    mov ebp,ecx
    push ecx
    
aaRLoop:    
    mov eax,fs:[edi]
    cmp eax,ds:aos_max_val
    jl aaRMaxOk
;
    mov eax,ds:aos_max_val

aaRMaxOk:
    cmp eax,ds:aos_min_val
    jg aaRMinOk
;
    mov eax,ds:aos_min_val

aaRMinOk:
    mov cl,ds:aos_shift
    shl eax,cl
    mul ds:aos_volume
    add eax,80000000h
    adc edx,0
    mov gs:[ebx],edx
    add bx,4
    add edi,4
    sub ebp,1
    jnz aaRLoop             
;    
    pop eax
    add ds:aos_in_buf_pos,ax
;    
    pop ecx
    sub ecx,eax
    jnz aaMoreData
    
aaDone:
    popad
    pop gs
    pop fs
    ret
add_audio   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			WriteAudio
;
;		DESCRIPTION:	Write audio data
;
;		PARAMETERS:		BX		    Handle
;                       (E)CX       Size
;                       DS:(E)SI    Left
;                       ES:(E)DI    Right
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_audio_name	DB 'Write Audio', 0

write_audio	Proc near
	push ds
	push es
	push fs
	push ax
	push bx
;
    mov ax,es
    mov fs,ax
    mov ax,ds
    mov es,ax
;    
	mov ax,AUDIO_OUT_HANDLE
	DerefHandle
	jc waDone
;
    mov ds,[bx].ao_sel
    call add_audio

waDone:
    pop bx
    pop ax
    pop fs
    pop es
    pop ds
    ret
write_audio Endp

write_audio32	Proc far
	call write_audio
	retf32
write_audio32	Endp

write_audio16	Proc far
    push esi
	push edi
;
    movzx esi,si
	movzx edi,di
	call write_audio
;	
	pop edi
	pop esi
	ret
write_audio16	Endp	

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetAudioOutBuffers
;
;		DESCRIPTION:	Get audio out buffer selectors
;
;		PARAMETERS:		BX          Handle
;
;       RETURNS:        CX          Buffer size
;                       SI          Left channel sel
;                       DI          Right channel sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_audio_out_buf_name	DB 'Get Audio Out Buffers', 0

get_audio_out_buf   Proc far
    push ds
    push ax
    push bx
;    
    xor si,si
    xor di,di
;    
	mov ax,AUDIO_OUT_HANDLE
	DerefHandle
	jc gaobDone
;
    mov ds,[bx].ao_sel
    mov si,ds:aos_inl_buf_sel
    mov di,ds:aos_inr_buf_sel
    mov cx,ds:aos_buffer_size
;
    GetThread
    mov ds:aos_thread,ax

gaobDone:
    pop bx
    pop ax
    pop ds
    ret
get_audio_out_buf   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			PostAudioOutBuffers
;
;		DESCRIPTION:	Post audio out buffers
;
;		PARAMETERS:		BX          Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

post_audio_out_buf_name	DB 'Post Audio Out Buffers', 0

post_audio_out_buf   Proc far
    push ds
    push ax
    push bx
;    
	mov ax,AUDIO_OUT_HANDLE
	DerefHandle
	jc paobDone
;
    mov ds,[bx].ao_sel
    mov ax,ds:aos_buffer_size
    mov ds:aos_in_buf_pos,ax
;    
    mov ax,audio_data_sel
    mov ds,ax
	mov bx,ds:ads_thread
    Signal

paobDone:
    pop bx
    pop ax
    pop ds
    ret
post_audio_out_buf   Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			IsAudioOutCompleted
;
;		DESCRIPTION:	Check if audio out buffers are free
;
;		PARAMETERS:		BX          Handle
;
;       RETURNS:        NC          Completed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

is_audio_out_completed_name	DB 'Is Audio Out Completed', 0

is_audio_out_completed   Proc far
    push ds
    push ax
    push bx
;    
	mov ax,AUDIO_OUT_HANDLE
	DerefHandle
	jc iaocDone
;
    mov ds,[bx].ao_sel
    mov ax,ds:aos_in_buf_pos
    or ax,ax
    clc
    jz iaocDone
;
    stc

iaocDone:
    pop bx
    pop ax
    pop ds
    ret
is_audio_out_completed   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_out_handle
;
;		DESCRIPTION:	BX			Bitmap handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_out_handle	Proc far
	push ds
	push ax
	push bx
;
	mov ax,AUDIO_OUT_HANDLE
	DerefHandle
	jc delete_out_handle_done
;
	call delete_out_channel

delete_out_handle_done:
	pop bx
	pop ax
	pop ds
	ret
delete_out_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MixChannel
;
;		DESCRIPTION:    Mix channel
;
;       PARAMETERS:     SI  In sample rate / size of buffer * 16
;                       DI  Out sample rate / size of buffer * 16
;                       FS  In buffer
;                       ES  Out buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

quot = -4
rest = -6
insize = -8

MixChannel  Proc near
    pushad
;    
    cmp si,di
    je mcSameRate
;
    push bp
    mov bp,sp
    sub sp,8
;
    mov ax,si
    shr ax,4
    sub ax,1
    mov [bp].insize,ax
;    
    mov cx,di
    shr cx,4
    movzx eax,si
    xor edx,edx
    movzx edi,di
    div edi
    mov [bp].quot,eax
;
    mov esi,edx
    mov edx,1
    xor eax,eax
    div edi
    mul esi
    shr eax,16
    mov [bp].rest,ax
;
    xor esi,esi
    xor edi,edi
    xor ebx,ebx
        
mcInterpLoop:
    xor eax,eax
    xor edx,edx
    cmp si,[bp].insize
    jae mcInterpAdd
;    
    movsx eax,word ptr fs:[4*esi+6]
    movsx edx,word ptr fs:[4*esi+2]
    sub eax,edx
    imul edi
    mov edx,fs:[4*esi]

mcInterpAdd:
    add eax,edx
    add es:[ebx],eax
    jno mcInterpNext
;
    test eax,80000000h
    jz mcInterpOvPos
;
    mov eax,7FFFFFFFh
    jmp mcInterpOvSave

mcInterpOvPos:
    mov eax,80000000h

mcInterpOvSave:       
    mov es:[ebx],eax

mcInterpNext:
    add ebx,4
    add di,[bp].rest
    adc esi,[bp].quot
    loop mcInterpLoop
;    
    add sp,8
    pop bp
    jmp mcDone

mcSameRate:
    mov cx,si
    shr cx,4
    xor ebx,ebx

mcSameLoop:
    mov eax,fs:[ebx]
    add es:[ebx],eax
    jno mcSameNext
;
    test eax,80000000h
    jz mcSameOvPos
;
    mov eax,7FFFFFFFh
    jmp mcSameOvSave

mcSameOvPos:
    mov eax,80000000h

mcSameOvSave:       
    mov es:[ebx],eax

mcSameNext:
    add ebx,4
    loop mcSameLoop
;

mcDone:
    popad
    ret
MixChannel  Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UpdateMixer
;
;		DESCRIPTION:    Update mixer
;
;       PARAMETERS:     AX      Mixer selector
;
;       RETURNS:        NC      New data available
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateMixer Proc near
    push ds
    push es
    pushad
;
    mov ds,ax
    mov bx,OFFSET ams_sel_arr
    mov cx,ds:ams_count
    or cx,cx
    jnz umCheckChanLoop
;
    call DeleteMixer
    stc
    jmp umDone    

umCheckChanLoop:
    mov es,ds:[bx]
    mov ax,es:aos_in_buf_pos
    cmp ax,es:aos_buffer_size
    stc
    jne umDone
;
    add bx,2
    loop umCheckChanLoop
;
    mov es,ds:ams_outl_buf_sel
    xor edi,edi
    movzx ecx,ds:ams_buffer_size
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov bx,OFFSET ams_sel_arr
    mov cx,ds:ams_count

umMoveLChanLoop:
    push ds
    push fs
    push bx
    push si
    push di
;    
    mov di,ds:ams_sample_rate
    mov ds,ds:[bx]
    mov si,ds:aos_sample_rate
    mov fs,ds:aos_inl_buf_sel
    call MixChannel
;
    pop di
    pop si    
    pop bx
    pop fs
    pop ds
;    
    add bx,2
    loop umMoveLChanLoop
;
    mov es,ds:ams_outr_buf_sel
    xor edi,edi
    movzx ecx,ds:ams_buffer_size
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    mov bx,OFFSET ams_sel_arr
    mov cx,ds:ams_count

umMoveRChanLoop:
    push ds
    push fs
    push bx
    push si
    push di
;    
    mov di,ds:ams_sample_rate
    mov ds,ds:[bx]
    mov si,ds:aos_sample_rate
    mov fs,ds:aos_inr_buf_sel
    call MixChannel
;
    pop di
    pop si    
    pop bx
    pop fs
    pop ds
;    
    add bx,2
    loop umMoveRChanLoop
;
    mov bx,OFFSET ams_sel_arr
    mov cx,ds:ams_count

umSignalLoop:
    push bx
    mov es,ds:[bx]
    mov es:aos_in_buf_pos,0
    mov bx,es:aos_thread
    Signal
    pop bx
;
    add bx,2
    loop umSignalLoop
;
    clc    
            
umDone:    
    popad
    pop es
    pop ds
    ret
UpdateMixer Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			audio_thread
;
;		DESCRIPTION:    Audio thread
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

audio_name	DB 'Audio',0

audio_thread:
	mov ax,audio_data_sel
	mov ds,ax
	GetThread
	mov ds:ads_thread,ax

atWait:
    mov ax,ds:ads_out_mixer
    or ax,ax
    jne atActive
;    
    WaitForSignal	
    jmp atWait

atActive:
    push esi
    mov esi,OFFSET ads_section
    EnterNewSection
    pop esi
;    
    mov ax,ds:ads_out_mixer
    or ax,ax
    jz atActiveLeave
;   
    call UpdateMixer
    pushf
    push esi
    mov esi,OFFSET ads_section
    LeaveNewSection
    pop esi
    popf
    jc atActiveWait
;
    push ds
    push es
    mov ds,ax
    mov cx,ds:ams_buffer_size
    mov es,ds:ams_outr_buf_sel
    mov ds,ds:ams_outl_buf_sel
    SendAudioOut
    pop es
    pop ds
    jmp atActive

atActiveWait:
    mov ax,10
    WaitMilliSec    
    jmp atActive
;

atActiveLeave:	
    push esi
    mov esi,OFFSET ads_section
    LeaveNewSection
    pop esi
    jmp atWait

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init_audio
;
;		DESCRIPTION:    init audio module
;
;       PARAMETERS:     
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
init_audio	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET audio_name
	mov si,OFFSET audio_thread
	mov ax,4
	mov cx,100h
	CreateThread
;	
	popa
	pop es
	pop ds
	ret
init_audio	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			Init
;
;		DESCRIPTION:	Init module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	PROC far
	mov bx,audio_code_sel
	InitDevice
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov ax,AUDIO_OUT_HANDLE
	mov di,OFFSET delete_out_handle
	RegisterHandle
;
	mov di,OFFSET init_audio
	HookInitTasking
;
	mov si,OFFSET create_audio_out_channel
	mov di,OFFSET create_audio_out_channel_name
	xor dx,dx
	mov ax,create_audio_out_channel_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_audio_out_channel
	mov di,OFFSET close_audio_out_channel_name
	xor dx,dx
	mov ax,close_audio_out_channel_nr
	RegisterBimodalUserGate
;
	mov bx,OFFSET write_audio16
	mov si,OFFSET write_audio32
	mov di,OFFSET write_audio_name
	mov dx,virt_es_in OR virt_ds_in
	mov ax,write_audio_nr
	RegisterUserGate
;
	mov si,OFFSET get_audio_out_buf
	mov di,OFFSET get_audio_out_buf_name
	mov ax,get_audio_out_buf_nr
	RegisterOsGate
;
	mov si,OFFSET post_audio_out_buf
	mov di,OFFSET post_audio_out_buf_name
	mov ax,post_audio_out_buf_nr
	RegisterOsGate
;
	mov si,OFFSET is_audio_out_completed
	mov di,OFFSET is_audio_out_completed_name
	mov ax,is_audio_out_completed_nr
	RegisterOsGate
;
	mov eax,SIZE audio_data_seg
	mov bx,audio_data_sel
	AllocateFixedSystemMem
	mov ds,bx
	mov ds:ads_out_mixer,0
	mov esi,OFFSET ads_section
	InitNewSection
;
	ret
init	ENDP

code	ENDS

	END init
