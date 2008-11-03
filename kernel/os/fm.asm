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
; FM.ASM
; FM synthesis support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME fm

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc

SAMPLE_RATE = 48000

instrument_sel   STRUC

i_c             DW ?
i_m             DW ?
i_beta_int      DD ?
i_beta_fract    DD ?
i_att_samples   DD ?
i_sus_vol_ind   DW ?
i_sus_vol_fract DW ?
i_sus_mod_ind   DW ?
i_sus_mod_fract DW ?
i_rel_vol_ind   DW ?
i_rel_vol_fract DW ?
i_rel_mod_ind   DW ?
i_rel_mod_fract DW ?

instrument_sel   ENDS

instrument_struc	STRUC

i_base		handle_header <>
i_sel		DW ?

instrument_struc	ENDS

note_struc  STRUC

n_callb         DW ?

n_carrier_ind   DW ?
n_carrier_fract DD ?
n_carrier_curr  DD ?

n_mod_ind       DW ?
n_mod_fract     DD ?
n_mod_curr      DD ?

n_peak_volume   DD ?
n_curr_volume   DD ?

n_att_samples   DD ?
n_sus_samples   DD ?

note_struc  ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

	extrn SinTab:dword
	extrn ExpTab:dword

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_fm
;
;		DESCRIPTION:	Delete FM selector
;
;		PARAMETERS:		DS:BX		FM handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_fm	Proc near
    push es
;
    mov es,[bx].i_sel
    FreeMem
    clc
;    
    pop es
	ret
delete_fm	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetFmSampleRate
;
;		DESCRIPTION:	Get FM sample rate
;
;       RETURNS:        AX      Sample rate
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_fm_sample_rate_name	DB 'Get FM Sample Rate',0

get_fm_sample_rate    Proc	
    mov ax,SAMPLE_RATE
	retf32
get_fm_sample_rate    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateFmInstrument
;
;		DESCRIPTION:	Create a new FM instrument
;
;		PARAMETERS:		AX:DX       C:M ratio
;                       ST0         Beta (modulation rate) 
;
;       RETURNS:        BX          Handle         
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_fm_instrument_name	DB 'Create FM Instrument',0

rmaxint DT 1073741824.0

create_fm_instrument    Proc	
    push es
    push ds
    push eax
    push cx
;
	mov cx,SIZE instrument_struc
	AllocateHandle
	mov ds:[bx].hh_sign,FM_HANDLE
;
    push eax
    mov eax,SIZE instrument_sel
    AllocateSmallGlobalMem
    pop eax
    mov es:i_c,ax	
    mov es:i_m,dx
;
    fist es:i_beta_int
    fisub es:i_beta_int 
;
    fld rmaxint
    fmulp st(1),st(0)
    fistp es:i_beta_fract
;
    mov eax,es:i_beta_fract
    test eax,80000000h
    jz cfiAdjOk
;
    dec es:i_beta_int
    add es:i_beta_fract,40000000h
        
cfiAdjOk:
    shl es:i_beta_fract,2
;    
    mov ds:i_att_samples,0
    mov ds:i_sus_vol_ind,0
    mov ds:i_sus_vol_fract,0
    mov ds:i_sus_mod_ind,0
    mov ds:i_sus_mod_fract,0
    mov ds:i_rel_vol_ind,0FFFFh
    mov ds:i_rel_vol_fract,0
    mov ds:i_rel_mod_ind,0
    mov ds:i_rel_mod_fract,0
;
    mov [bx].i_sel,es
	mov bx,[bx].hh_handle
;
	pop cx
    pop eax
    pop ds
    pop es
	retf32
create_fm_instrument    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeFmInstrument
;
;		DESCRIPTION:	Free FM instrument
;
;		PARAMETERS:		BX          FM handle         
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_fm_instrument_name	DB 'Free FM Instrument',0

free_fm_instrument    Proc	
	push ds
	push ax
	push bx
;
	mov ax,FM_HANDLE
	DerefHandle
	jc ffiDone
;
  	call delete_fm

ffiDone:
	pop bx
	pop ax
	pop ds
	retf32
free_fm_instrument    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetFmAttack
;
;		DESCRIPTION:	Set attack
;
;		PARAMETERS:		BX          FM handle         
;                       EAX         Time in samples until full volume (attack)
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_fm_attack_name	DB 'Set FM Attack',0

set_fm_attack    Proc	
	push ds
	push ax
	push bx
;
    push eax
	mov ax,FM_HANDLE
	DerefHandle
	pop eax
	jc sfaDone
;
    mov ds,[bx].i_sel
    mov ds:i_att_samples,eax        

sfaDone:
	pop bx
	pop ax
	pop ds
	retf32
set_fm_attack    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetFmSustain
;
;		DESCRIPTION:	Set sustain params
;
;		PARAMETERS:		BX          FM handle         
;                       EAX         Time in samples until volume is halved
;                       EDX         Time in samples until modulation index is halved
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_fm_sustain_name	DB 'Set FM Sustain',0

set_fm_sustain    Proc	
	push ds
	push eax
	push ebx
	push edx
;
    push eax
	mov ax,FM_HANDLE
	DerefHandle
	pop eax
	jc sfsDone
;
    push edx    
    mov ds,[bx].i_sel
;    
    mov ds:i_sus_vol_ind,0FFFFh
    mov ds:i_sus_vol_fract,0
    or eax,eax
    jz sfsVolDone
;
    mov ebx,eax
    mov eax,1000h
    xor edx,edx
    div ebx
;
    mov ds:i_sus_vol_ind,ax
    push edx
    mov edx,1
    xor eax,eax
    div ebx
    pop edx
    mul edx
    shr eax,16
    mov ds:i_sus_vol_fract,ax

sfsVolDone:    
    pop eax       
;    
    mov ds:i_sus_mod_ind,0FFFFh
    mov ds:i_sus_mod_fract,0
    or eax,eax
    jz sfsDone
;
    mov ebx,eax
    mov eax,1000h
    xor edx,edx
    div ebx
;
    mov ds:i_sus_mod_ind,ax
    push edx
    mov edx,1
    xor eax,eax
    div ebx
    pop edx
    mul edx
    shr eax,16
    mov ds:i_sus_mod_fract,ax

sfsDone:
    pop edx
	pop ebx
	pop eax
	pop ds
	retf32
set_fm_sustain    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetFmRelease
;
;		DESCRIPTION:	Set release params
;
;		PARAMETERS:		BX          FM handle         
;                       EAX         Time in samples until volume is halved
;                       EDX         Time in samples until modulation index is halved
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_fm_release_name	DB 'Set FM Release',0

set_fm_release    Proc	
	push ds
	push eax
	push ebx
	push edx
;
    push eax
	mov ax,FM_HANDLE
	DerefHandle
	pop eax
	jc sfrDone
;
    push edx    
    mov ds,[bx].i_sel
;    
    mov ds:i_rel_vol_ind,0FFFFh
    mov ds:i_rel_vol_fract,0
    or eax,eax
    jz sfrVolDone
;
    mov ebx,eax
    mov eax,1000h
    xor edx,edx
    div ebx
;
    mov ds:i_rel_vol_ind,ax
    push edx
    mov edx,1
    xor eax,eax
    div ebx
    pop edx
    mul edx
    shr eax,16
    mov ds:i_rel_vol_fract,ax

sfrVolDone:    
    pop eax       
;    
    mov ds:i_rel_mod_ind,0FFFFh
    mov ds:i_rel_mod_fract,0
    or eax,eax
    jz sfrDone
;
    mov ebx,eax
    mov eax,1000h
    xor edx,edx
    div ebx
;
    mov ds:i_rel_mod_ind,ax
    push edx
    mov edx,1
    xor eax,eax
    div ebx
    pop edx
    mul edx
    shr eax,16
    mov ds:i_rel_mod_fract,ax

sfrDone:
    pop edx
	pop ebx
	pop eax
	pop ds
	retf32
set_fm_release    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PlayFmNote
;
;		DESCRIPTION:	Schedule not for playing
;
;		PARAMETERS:		BX          FM handle         
;                       EAX         Duration of sustain in samples
;                       EDX         Peak volume
;                       ST0         Frequency (Hz)
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

play_fm_note_name	DB 'Play FM Note',0

SinSize DD 4096

play_fm_note    Proc	
	push ds
	push ax
	push bx
	push bp
;
    push eax
	mov ax,FM_HANDLE
	DerefHandle
	pop eax
	jc pfnDone
;
    mov ds,[bx].i_sel
    int 3
    push eax
    mov eax, SIZE note_struc
    AllocateSmallGlobalMem
    pop eax
;    
    mov es:n_sus_samples,eax
    mov es:n_peak_volume,edx
;
    mov eax,SAMPLE_RATE
    push eax
    mov bp,sp
;    
    fild ds:i_c
    fmul st(0), st(1)
    fidivr dword ptr [bp]
    fidivr word ptr cs:SinSize
;
    fist es:n_carrier_ind
    fisub es:n_carrier_ind 
;
    fld rmaxint
    fmulp st(1),st(0)
    fistp es:n_carrier_fract
;    
    fimul ds:i_m
    fidivr dword ptr [bp]
    fidivr word ptr cs:SinSize
;
    fist es:n_mod_ind
    fisub es:n_mod_ind 
;
    fld rmaxint
    fmulp st(1),st(0)
    fistp es:n_mod_fract
;
    pop eax
;
    mov eax,ds:i_att_samples
    mov es:n_att_samples,eax
;
    mov es:n_carrier_curr,0
    mov es:n_mod_curr,0
    mov es:n_curr_volume,0
;
    mov es:n_callb, OFFSET PlayAttack
            
pfnDone:
    pop bp
	pop bx
	pop ax
	pop ds
	retf32
play_fm_note    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_fm_handle
;
;		DESCRIPTION:	BX			Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_fm_handle	Proc far
	push ds
	push ax
	push bx
;
	mov ax,FM_HANDLE
	DerefHandle
	jc delete_fm_handle_done
;
	call delete_fm

delete_fm_handle_done:
	pop bx
	pop ax
	pop ds
	ret
delete_fm_handle	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PlayAttack
;
;		DESCRIPTION:	Play attack part
;
;		PARAMETERS:		ES          Note sel
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PlayAttack  Proc near
    ret
PlayAttack  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init_fm
;
;		DESCRIPTION:	Init FM thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fm_name	DB 'FM',0

beta    DT 5.45

fm_thread	proc far
    int 3
    ret
fm_thread   endp

init_fm	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET fm_name
	mov si,OFFSET fm_thread
	mov ax,4
	mov cx,100h
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_fm	Endp
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	Init FM
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
	mov bx,fm_code_sel
	InitDevice
;
	mov ax,FM_HANDLE
	mov di,OFFSET delete_fm_handle
	RegisterHandle
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET init_fm
	HookInitTasking
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET get_fm_sample_rate
	mov di,OFFSET get_fm_sample_rate_name
	xor dx,dx
	mov ax,get_fm_sample_rate_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET create_fm_instrument
	mov di,OFFSET create_fm_instrument_name
	xor dx,dx
	mov ax,create_fm_instrument_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET free_fm_instrument
	mov di,OFFSET free_fm_instrument_name
	xor dx,dx
	mov ax,free_fm_instrument_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_fm_attack
	mov di,OFFSET set_fm_attack_name
	xor dx,dx
	mov ax,set_fm_attack_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_fm_sustain
	mov di,OFFSET set_fm_sustain_name
	xor dx,dx
	mov ax,set_fm_sustain_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET set_fm_release
	mov di,OFFSET set_fm_release_name
	xor dx,dx
	mov ax,set_fm_release_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET play_fm_note
	mov di,OFFSET play_fm_note_name
	xor dx,dx
	mov ax,play_fm_note_nr
	RegisterBimodalUserGate
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
