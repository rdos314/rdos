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

MAX_FM_SELS = 8

fm_data_seg STRUC

fm_section      section_typ <>
fm_thread       DW ?

fm_sel_count    DW ?
fm_sel_arr      DW MAX_FM_SELS DUP(?)

fm_data_seg ENDS

fm_sel   STRUC

f_section       section_typ <>
f_note_list     DW ?
f_audio_handle  DW ?
f_sample_rate   DW ?

fm_sel   ENDS

fm_struc	STRUC

f_base		handle_header <>
f_sel		DW ?

fm_struc	ENDS

instrument_sel   STRUC

i_fm_sel        DW ?
i_c             DW ?
i_m             DW ?
i_beta_int      DD ?
i_beta_fract    DD ?
i_att_samples   DD ?
i_sus_vol_fract DW ?
i_sus_vol_ind   DW ?
i_sus_mod_fract DW ?
i_sus_mod_ind   DW ?
i_rel_vol_fract DW ?
i_rel_vol_ind   DW ?
i_rel_mod_fract DW ?
i_rel_mod_ind   DW ?

instrument_sel   ENDS

instrument_struc	STRUC

i_base		handle_header <>
i_sel		DW ?

instrument_struc	ENDS

note_struc  STRUC

n_prev          DW ?
n_next          DW ?

n_callb         DW ?

n_carrier_diff  DD ?
n_carrier_curr  DD ?

n_mod_diff      DD ?
n_mod_curr      DD ?

n_l_peak_volume DD ?
n_r_peak_volume DD ?
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
;		NAME:			InsertNoteSel
;
;		DESCRIPTION:	Insert a note selector
;
;		PARAMETERS:     DS      FM sel
;                       ES      Note sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertNoteSel	Proc near
    push ds
    push es
    push eax
    push ebx
	push di
;
    EnterSection ds:f_section
;
	mov di,ds:f_note_list
	or di,di
	je insEmpty
;
	push ds
	push si
	mov ds,di
	mov si,ds:n_prev
	mov ds:n_prev,es
	mov ds,si
	mov ds:n_next,es
	mov es:n_next,di
	mov es:n_prev,si
	pop si
	pop ds
	jmp insLeave
	
insEmpty:
	mov es:n_next,es
	mov es:n_prev,es
	mov ds:f_note_list,es

insLeave:
    LeaveSection ds:f_section
;
    pop di
    pop ebx
    pop eax
    pop es
    pop ds
    ret
InsertNoteSel Endp	

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			RemoveNoteSel
;
;		DESCRIPTION:	Remove a note selector
;
;		PARAMETERS:	    DS      FM sel
;                       ES      Note sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveNoteSel	Proc near
    push ds
    push eax
    push ebx
	push si
;
    EnterSection ds:f_section
	mov di,es
    cmp di,es:n_next
	je rnsEmpty
;
	push di
	push ds
	mov di,es:n_next
	mov ds:f_note_list,di
	mov si,es:n_prev
	mov ds,di
	mov ds:n_prev,si
	mov ds,si
	mov ds:n_next,di
	pop ds
	pop di
	jmp rnsLeave

rnsEmpty:	
	mov ds:f_note_list,0

rnsLeave:
    LeaveSection ds:f_section
;    
	pop si
    pop ebx
    pop eax
    pop ds 
    ret
RemoveNoteSel Endp

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
    push ds
    push es
    push bx
    push cx
;
    push ds
    mov ax,fm_data_sel
    mov ds,ax
    EnterSection ds:fm_section
    pop ds
;
    mov ds,[bx].f_sel
    mov bx,ds:f_audio_handle
    or bx,bx
    jz dfAudioOff
;
    CloseAudioOutChannel
    
dfAudioOff:    
    mov ax,ds:f_note_list
    or ax,ax
    jz dfNoteClosed
;
    mov es,ax
    call RemoveNoteSel
    FreeMem
    jmp dfAudioOff

dfNoteClosed:
    mov ax,ds
    mov es,ax
    mov ax,fm_data_sel
    mov ds,ax
    mov cx,ds:fm_sel_count
    mov bx,OFFSET fm_sel_arr
    or cx,cx
    jz dfFree
;
    mov ax,es    

dfFindSelLoop:
    cmp ax,[bx]
    je dfRemSelLoop
;
    add bx,2
    loop dfFindSelLoop 
;
    jmp dfFree

dfRemSelLoop:
    mov ax,[bx+2]
    mov [bx],ax
    add bx,2
    loop dfRemSelLoop
;
    dec ds:fm_sel_count

dfFree:
    FreeMem
;
    mov ax,fm_data_sel
    mov ds,ax
    LeaveSection ds:fm_section
    clc
;    
    pop cx
    pop bx
    pop es
    pop ds
	ret
delete_fm	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			delete_fm_instr
;
;		DESCRIPTION:	Delete FM instrument selector
;
;		PARAMETERS:		DS:BX		FM handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_fm_instr	Proc near
    push es
;
    mov es,[bx].i_sel
    FreeMem
    clc
;    
    pop es
	ret
delete_fm_instr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenFm
;
;		DESCRIPTION:	Open FM handle
;
;       PARAMETERS:     AX      Sample rate
;
;       RETURNS:        BX      FM handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_fm_name	DB 'Open FM',0

open_fm    Proc	
    push es
    push ds
    push eax
    push cx
;
	mov cx,SIZE fm_struc
	AllocateHandle
	mov ds:[bx].hh_sign,FM_HANDLE
;
    push eax
    mov eax,SIZE fm_sel
    AllocateSmallGlobalMem
    pop eax
    mov es:f_sample_rate,ax
    mov es:f_audio_handle,0
    mov es:f_note_list,0
    InitSection es:f_section
;
    push ds
    push bx
    mov ax,fm_data_sel
    mov ds,ax
    EnterSection ds:fm_section
;
    mov bx,OFFSET fm_sel_arr
    mov ax,ds:fm_sel_count
    add bx,ax
    add bx,ax
    mov ds:[bx],es
    inc ds:fm_sel_count
;
    LeaveSection ds:fm_section
    pop bx
    pop ds    
;
    mov [bx].f_sel,es
	mov bx,[bx].hh_handle
;
    pop cx
    pop eax
    pop ds
    pop es    
	retf32
open_fm    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseFm
;
;		DESCRIPTION:	Close FM handle
;
;       PARAMETERS:     BX      FM handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_fm_name	DB 'Close FM',0

close_fm    Proc	
	push ds
	push ax
	push bx
;
	mov ax,FM_HANDLE
	DerefHandle
	jc cfDone
;
  	call delete_fm

cfDone:
	pop bx
	pop ax
	pop ds
	retf32
close_fm    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FmWait
;
;		DESCRIPTION:	Wait for FM samples to complete
;
;       PARAMETERS:     BX      FM handle
;                       EAX     Samples
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fm_wait_name	DB 'FM Wait',0

fm_wait    Proc	
	retf32
fm_wait    Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateFmInstrument
;
;		DESCRIPTION:	Create a new FM instrument
;
;		PARAMETERS:		BX          FM handle
;                       AX:DX       C:M ratio
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
    push si
;
    push ax
	mov ax,FM_HANDLE
	DerefHandle
	pop ax
	jc cfiFail
;
    mov si,[bx].f_sel    
	mov cx,SIZE instrument_struc
	AllocateHandle
	mov ds:[bx].hh_sign,FM_INSTR_HANDLE
;
    push eax
    mov eax,SIZE instrument_sel
    AllocateSmallGlobalMem
    pop eax
    mov es:i_c,ax	
    mov es:i_m,dx
    mov es:i_fm_sel,si
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
	clc
	jmp cfiDone

cfiFail:
    xor bx,bx
    stc

cfiDone:
    pop si
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
	mov ax,FM_INSTR_HANDLE
	DerefHandle
	jc ffiDone
;
  	call delete_fm_instr

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
	mov ax,FM_INSTR_HANDLE
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
	mov ax,FM_INSTR_HANDLE
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
	mov ax,FM_INSTR_HANDLE
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
;                       ECX         Duration of sustain in samples
;                       EAX         Left peak volume
;                       EDX         Right peak volume
;                       ST0         Frequency (Hz)
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

play_fm_note_name	DB 'Play FM Note',0

SinSize DD 4096

play_fm_note    Proc	
	push ds
	push es
	push fs
	push ax
	push bx
	push bp
;
    push eax
	mov ax,FM_INSTR_HANDLE
	DerefHandle
	pop eax
	jc pfnDone
;
    mov fs,[bx].i_sel
    mov ds,fs:i_fm_sel
    push eax
    mov eax, SIZE note_struc
    AllocateSmallGlobalMem
    pop eax
;    
    mov es:n_sus_samples,ecx
    mov es:n_l_peak_volume,eax
    mov es:n_r_peak_volume,edx
;
    movzx eax,ds:f_sample_rate    
    push eax
    mov bp,sp
;    
    fild fs:i_c
    fmul st(0), st(1)
    fidivr dword ptr [bp]
    fidivr word ptr cs:SinSize
;
    fist word ptr es:n_carrier_diff+2
    fisub word ptr es:n_carrier_diff+2
;
    fld cs:rmaxint
    fmulp st(1),st(0)
    fistp dword ptr [bp]
    pop eax
    test eax,80000000h
    jz pfnCarrierOk
;
    dec word ptr es:n_carrier_diff+2
    add eax,40000000h

pfnCarrierOk:
    shr eax,14
    mov word ptr es:n_carrier_diff,ax
    mov es:n_carrier_curr,0
;
    movzx eax,ds:f_sample_rate    
    push eax
    mov bp,sp
;    
    fimul fs:i_m
    fidivr dword ptr [bp]
    fidivr word ptr cs:SinSize
;
    fist word ptr es:n_mod_diff+2
    fisub word ptr es:n_mod_diff+2
;
    fld cs:rmaxint
    fmulp st(1),st(0)
    fistp dword ptr [bp]
    pop eax
    test eax,80000000h
    jz pfnModOk
;
    dec word ptr es:n_mod_diff+2
    add eax,40000000h

pfnModOk:
    shr eax,14
    mov word ptr es:n_mod_diff,ax
    mov es:n_mod_curr,0
;
    mov eax,fs:i_att_samples
    mov es:n_att_samples,eax
;
    mov es:n_curr_volume,0
    mov es:n_callb, OFFSET PlayAttack
    call InsertNoteSel
;
    mov ax,fm_data_sel
    mov ds,ax
    mov bx,ds:fm_thread
    Signal
            
pfnDone:
    pop bp
	pop bx
	pop ax
	pop fs
	pop es
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
	push si
;
    mov si,bx
	mov ax,FM_INSTR_HANDLE
	DerefHandle
	jc delete_fm_not_instr
;
	call delete_fm_instr
	jmp delete_fm_handle_done

delete_fm_not_instr:
    mov bx,si
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
;		PARAMETERS:		DS      FM sel
;                       ES      Note sel
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PlayAttack  Proc near
    ret
PlayAttack  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdateFmSel
;
;		DESCRIPTION:	Update FM selector
;
;		PARAMETERS:		DS      FM sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateFmSel Proc near
    mov ax,ds:f_note_list
    or ax,ax
    jz ufsDone
;
    EnterSection ds:f_section
    mov si,ax

ufsLoop:    
    mov es,ax
    push ds
    push si
;
    call es:n_callb
;
    pop si
    pop ds
    mov ax,es:n_next
    cmp ax,si
    jne ufsLoop
;
    LeaveSection ds:f_section
    
ufsDone:    
    ret
UpdateFmSel Endp

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

fm_thread_pr:
    int 3
    mov ax,fm_data_sel
    mov ds,ax
    GetThread
    mov ds:fm_thread,ax

fm_wait_loop:
    WaitForSignal
;
    mov cx,ds:fm_sel_count
    mov bx,OFFSET fm_sel_arr
    or cx,cx
    jz fm_wait_loop
;    
    EnterSection ds:fm_section
    mov cx,ds:fm_sel_count

fm_handle_loop:
    push ds
    push bx
    push cx
;    
    mov ds,ds:[bx]
    call UpdateFmSel
;
    pop cx
    pop bx
    pop ds
    add bx,2
    loop fm_handle_loop    
;
    LeaveSection ds:fm_section
    jmp fm_wait_loop    


init_fm	Proc far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET fm_name
	mov si,OFFSET fm_thread_pr
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
	mov ax,FM_INSTR_HANDLE
	mov di,OFFSET delete_fm_handle
	RegisterHandle
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
	mov si,OFFSET open_fm
	mov di,OFFSET open_fm_name
	xor dx,dx
	mov ax,open_fm_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET close_fm
	mov di,OFFSET close_fm_name
	xor dx,dx
	mov ax,close_fm_nr
	RegisterBimodalUserGate
;
	mov si,OFFSET fm_wait
	mov di,OFFSET fm_wait_name
	xor dx,dx
	mov ax,fm_wait_nr
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
	mov eax,SIZE fm_data_seg
	mov bx,fm_data_sel
	AllocateFixedSystemMem
	mov es:fm_thread,0
	mov es:fm_sel_count,0
	InitSection es:fm_section
;
	popa
	pop es
	pop ds
	ret
init	Endp

code	ENDS

	END init
