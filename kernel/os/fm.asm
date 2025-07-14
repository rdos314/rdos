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
; FM.ASM
; FM synthesis support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE system.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\handle.inc
INCLUDE ..\apicheck.inc

MAX_FM_SELS = 8

FLAG_FM_NEW     = 1
FLAG_FM_ZERO    = 2
FLAG_FM_DELETE  = 4

FLAG_NOTE_NEW   = 1
FLAG_NOTE_DONE  = 2

fm_sel   STRUC

f_section       section_typ <>
f_note_list     DW ?
f_audio_handle  DW ?
f_sample_rate   DW ?

f_buf_size      DW ?
f_lbuf_sel      DW ?
f_rbuf_sel      DW ?

f_buf_pos       DW ?
f_thread    DW ?

f_flags     DB ?

fm_sel   ENDS

fm_struc    STRUC

f_base      handle_header <>
f_sel       DW ?

fm_struc    ENDS

instrument_sel   STRUC

i_fm_sel    DW ?
i_c         DW ?
i_m         DW ?
i_beta      DT ?
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

instrument_struc    STRUC

i_base      handle_header <>
i_sel       DW ?

instrument_struc    ENDS

note_struc  STRUC

n_prev      DW ?
n_next      DW ?

n_callb     DW ?

n_carrier_diff  DD ?
n_carrier_curr  DD ?

n_mod_diff      DD ?
n_mod_curr      DD ?

n_l_peak_volume DD ?
n_r_peak_volume DD ?
n_curr_volume   DD ?

n_att_diff      DD ?

n_sus_vol_diff  DD ?
n_sus_fm_diff   DD ?

n_rel_vol_diff  DD ?
n_rel_fm_diff   DD ?

n_vol_curr      DD ?
n_fm_curr       DD ?

n_beta_fact     DD ?
n_sus_samples   DD ?

n_buf_pos       DW ?
n_flags     DB ?

note_struc  ENDS

data    SEGMENT byte public 'DATA'

fm_section      section_typ <>
fm_thread       DW ?

fm_sel_count    DW ?
fm_sel_arr      DW MAX_FM_SELS DUP(?)

data    ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    extrn SinTab:dword
    extrn ExpTab:dword



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InterpolateSin
;
;           DESCRIPTION:    Interpolate sin-value
;
;           PARAMETERS:     EAX     Value (12-bit index + 16-bit fract)
;
;       RETURNS:    EAX     Sin value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InterpolateSin  Proc near
    push bx
    push edx
    push esi
    push edi
;    
    mov esi,eax
    movzx edi,ax
    shl edi,15
    and edi,7FFFFFFFh
    shr esi,14
    mov bx,si
    and si,3FFCh
    test bh,40h
    jz isMirrorOk
;
    not si
    and si,3FFCh
    neg edi
;
    mov eax,dword ptr cs:[si+4].SinTab
    mov edx,dword ptr cs:[si].SinTab
    sub eax,edx
    imul edi
    mov eax,edx
    shl eax,1       
    add eax,dword ptr cs:[si+4].SinTab
    jmp isCheckSign

isMirrorOk:
    mov eax,dword ptr cs:[si+4].SinTab
    mov edx,dword ptr cs:[si].SinTab
    sub eax,edx
    imul edi
    mov eax,edx
    shl eax,1       
    add eax,dword ptr cs:[si].SinTab

isCheckSign:
    test bh,80h
    jz isDone
;
    neg eax

isDone:
    pop edi
    pop esi
    pop edx
    pop bx
    ret
InterpolateSin Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InterpolateExp
;
;           DESCRIPTION:    Interpolate exp(-kt)
;
;           PARAMETERS:     EAX     Value (12-bit index + 16-bit fract)
;
;       RETURNS:    EAX     Exp value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InterpolateExp  Proc near
    push edx
    push esi
    push edi
;    
    mov esi,eax
    movzx edi,ax
    shl edi,15
    and edi,7FFFFFFFh
    shr esi,14
    and si,03FFCh
;    
    mov eax,dword ptr cs:[si+4].ExpTab
    mov edx,dword ptr cs:[si].ExpTab
    sub eax,edx
    imul edi
    mov eax,edx
    shl eax,1       
    add eax,dword ptr cs:[si].ExpTab
;
    pop edi
    pop esi
    pop edx
    ret
InterpolateExp Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           InsertNoteSel
;
;           DESCRIPTION:    Insert a note selector
;
;           PARAMETERS:     DS      FM sel
;               ES      Note sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InsertNoteSel   Proc near
    push ds
    push es
    push eax
    push ebx
    push di
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
    pop di
    pop ebx
    pop eax
    pop es
    pop ds
    ret
InsertNoteSel Endp      



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           RemoveNoteSel
;
;           DESCRIPTION:    Remove a note selector
;
;           PARAMETERS:     DS      FM sel
;               ES      Note sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveNoteSel   Proc near
    push ds
    push eax
    push ebx
    push si
;
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
    pop si
    pop ebx
    pop eax
    pop ds 
    ret
RemoveNoteSel Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_fm
;
;           DESCRIPTION:    Delete FM selector
;
;           PARAMETERS:         DS:EBX       FM handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_fm       Proc near
    push ds
    push bx
    push cx
;
    mov ds,[ebx].f_sel

dfLoop:
    mov cx,ds:f_note_list
    or cx,cx
    jz dfFree
;    
    mov cx,ds:f_buf_size
    mov ds:f_buf_pos,cx
;
    GetThread
    mov ds:f_thread,ax
;   
    or ds:f_flags,FLAG_FM_NEW
    push ds
    mov cx,SEG data
    mov ds,cx
    mov bx,ds:fm_thread
    Signal
    WaitForSignal      
    pop ds
    jmp dfLoop

dfFree:
    or ds:f_flags,FLAG_FM_DELETE
    mov cx,SEG data
    mov ds,cx
    mov bx,ds:fm_thread
    Signal
    clc
;    
    pop cx
    pop bx
    pop ds
    ret
delete_fm       Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_fm_instr
;
;           DESCRIPTION:    Delete FM instrument selector
;
;           PARAMETERS:         DS:EBX       FM handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_fm_instr Proc near
    push es
;
    mov es,[ebx].i_sel
    FreeMem
    FreeHandle
    clc
;    
    pop es
    ret
delete_fm_instr Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenFm
;
;           DESCRIPTION:    Open FM handle
;
;       PARAMETERS:     AX      Sample rate
;
;       RETURNS:    BX      FM handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_fm_name    DB 'Open FM',0

open_fm    Proc 
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi

    push es
    push ds
    push eax
    push cx
;
    mov cx,SIZE fm_struc
    AllocateHandle
    mov ds:[ebx].hh_sign,FM_HANDLE
;
    push eax
    mov eax,SIZE fm_sel
    AllocateSmallGlobalMem
    pop eax
    mov es:f_sample_rate,ax
    mov es:f_audio_handle,0
    mov es:f_note_list,0
    mov es:f_buf_size,0
    mov es:f_lbuf_sel,0
    mov es:f_rbuf_sel,0
    mov es:f_buf_pos,0
    mov es:f_thread,0
    mov es:f_flags,0
    push ds
    mov ax,es
    mov ds,ax
    InitSection ds:f_section
    pop ds
;
    push ds
    push ebx
    mov ax,SEG data
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
    pop ebx
    pop ds    
;
    mov [ebx].f_sel,es
    mov bx,[ebx].hh_handle
;
    pop cx
    pop eax
    pop ds
    pop es    

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
open_fm    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CloseFm
;
;           DESCRIPTION:    Close FM handle
;
;       PARAMETERS:     BX      FM handle
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

close_fm_name   DB 'Close FM',0

close_fm    Proc    
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push ebx
;
    mov ax,FM_HANDLE
    DerefHandle
    jc cfDone
;
    call delete_fm
    FreeHandle

cfDone:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
close_fm    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FmWait
;
;           DESCRIPTION:    Wait for FM samples to complete
;
;       PARAMETERS:     BX      FM handle
;               EAX     Samples
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fm_wait_name    DB 'FM Wait',0

fm_wait    Proc 
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push eax
    push ebx
    push ecx
    push edx
;
    push ax
    mov ax,FM_HANDLE
    DerefHandle
    pop ax
    jc fwDone
;
    mov ds,[ebx].f_sel

fwLoop:
    mov cx,ds:f_note_list
    or cx,cx
    jz fwDirectWait
;    
    mov cx,ds:f_buf_size
    sub cx,ds:f_buf_pos
    movzx ecx,cx
    cmp eax,ecx
    ja fwFillAll
;
    add ds:f_buf_pos,ax
    jmp fwDone

fwFillAll:
    sub eax,ecx
    mov cx,ds:f_buf_size
    mov ds:f_buf_pos,cx
;
    push ax
    GetThread
    mov ds:f_thread,ax
    pop ax
;   
    or ds:f_flags,FLAG_FM_NEW
    push ds
    mov cx,SEG data
    mov ds,cx
    mov bx,ds:fm_thread
    Signal
    WaitForSignal      
    pop ds
    jmp fwLoop

fwDirectWait:
    mov ecx,1000
    mul ecx
    movzx ecx,ds:f_sample_rate
    div ecx
    WaitMilliSec

fwDone:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
fm_wait    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateFmInstrument
;
;           DESCRIPTION:    Create a new FM instrument
;
;           PARAMETERS:         BX      FM handle
;               AX:DX       C:M ratio
;               ST0     Beta (modulation rate) 
;
;       RETURNS:    BX      Handle     
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_fm_instrument_name       DB 'Create FM Instrument',0

rmaxint DT 1073741824.0

create_fm_instrument    Proc    
    ApiSaveEax
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
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
    mov si,[ebx].f_sel    
    mov cx,SIZE instrument_struc
    AllocateHandle
    mov ds:[ebx].hh_sign,FM_INSTR_HANDLE
;
    push eax
    mov eax,SIZE instrument_sel
    AllocateSmallGlobalMem
    pop eax
    mov es:i_c,ax       
    mov es:i_m,dx
    mov es:i_fm_sel,si
    fstp es:i_beta
;    
    mov es:i_att_samples,0
    mov es:i_sus_vol_ind,0
    mov es:i_sus_vol_fract,0
    mov es:i_sus_mod_ind,0
    mov es:i_sus_mod_fract,0
    mov es:i_rel_vol_ind,0FFFFh
    mov es:i_rel_vol_fract,0
    mov es:i_rel_mod_ind,0
    mov es:i_rel_mod_fract,0
;
    mov [ebx].i_sel,es
    mov bx,[ebx].hh_handle
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

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEax
    retf32
create_fm_instrument    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           FreeFmInstrument
;
;           DESCRIPTION:    Free FM instrument
;
;           PARAMETERS:         BX      FM handle     
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

free_fm_instrument_name DB 'Free FM Instrument',0

free_fm_instrument    Proc      
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push ebx
;
    mov ax,FM_INSTR_HANDLE
    DerefHandle
    jc ffiDone
;
    call delete_fm_instr

ffiDone:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
free_fm_instrument    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetFmAttack
;
;           DESCRIPTION:    Set attack
;
;           PARAMETERS:         BX      FM handle     
;               EAX     Time in samples until full volume (attack)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_fm_attack_name      DB 'Set FM Attack',0

set_fm_attack    Proc   
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push ebx
;
    push eax
    mov ax,FM_INSTR_HANDLE
    DerefHandle
    pop eax
    jc sfaDone
;
    mov ds,[ebx].i_sel
    mov ds:i_att_samples,eax    

sfaDone:
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
set_fm_attack    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetFmSustain
;
;           DESCRIPTION:    Set sustain params
;
;           PARAMETERS:         BX      FM handle     
;               EAX     Time in samples until volume is halved
;               EDX     Time in samples until modulation index is halved
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_fm_sustain_name     DB 'Set FM Sustain',0

set_fm_sustain    Proc  
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
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
    mov ds,[ebx].i_sel
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

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
set_fm_sustain    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetFmRelease
;
;           DESCRIPTION:    Set release params
;
;           PARAMETERS:         BX      FM handle     
;               EAX     Time in samples until volume is halved
;               EDX     Time in samples until modulation index is halved
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_fm_release_name     DB 'Set FM Release',0

set_fm_release    Proc  
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
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
    mov ds,[ebx].i_sel
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

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
set_fm_release    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PlayFmNote
;
;           DESCRIPTION:    Schedule not for playing
;
;           PARAMETERS:         BX      FM handle     
;               ECX     Duration of sustain in samples
;               EAX     Left peak volume
;               EDX     Right peak volume
;               ST0     Frequency (Hz)
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

play_fm_note_name       DB 'Play FM Note',0

SinSize DD 4000h

play_fm_note    Proc    
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push es
    push fs
    push eax
    push ebx
    push bp
;
    push eax
    mov ax,FM_INSTR_HANDLE
    DerefHandle
    pop eax
    jc pfnDone
;
    mov fs,[ebx].i_sel
    mov ds,fs:i_fm_sel
    push eax
    mov eax, SIZE note_struc
    AllocateSmallGlobalMem
    pop eax
;    
    mov es:n_sus_samples,ecx
    mov es:n_l_peak_volume,eax
    mov es:n_r_peak_volume,edx
    mov es:n_flags, FLAG_NOTE_NEW
    mov ax,ds:f_buf_pos
    mov es:n_buf_pos,ax
;
    mov eax,dword ptr fs:i_sus_vol_fract
    mov es:n_sus_vol_diff,eax
    mov eax,dword ptr fs:i_sus_mod_fract
    mov es:n_sus_fm_diff,eax
;
    mov eax,dword ptr fs:i_rel_vol_fract
    mov es:n_rel_vol_diff,eax
    mov eax,dword ptr fs:i_rel_mod_fract
    mov es:n_rel_fm_diff,eax
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
    fld fs:i_beta
    fimul es:n_carrier_diff
    fistp es:n_beta_fact
;    
    push ebx
    push edx
    xor edx,edx
    mov eax,7FFFFFFFh
    mov ebx,fs:i_att_samples
    or ebx,ebx
    jnz pfnAttOk
;
    inc ebx
    
pfnAttOk:    
    div ebx
    mov es:n_att_diff,eax
    pop edx
    pop ebx   
;
    EnterSection ds:f_section
    mov es:n_curr_volume,0
    mov es:n_callb, OFFSET PlayAttack
    call InsertNoteSel
    LeaveSection ds:f_section
;
    mov ax,SEG data
    mov ds,ax
    mov bx,ds:fm_thread
    Signal
        
pfnDone:
    pop bp
    pop ebx
    pop eax
    pop fs
    pop es
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
play_fm_note    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           delete_fm_handle
;
;           DESCRIPTION:    BX              Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

delete_fm_handle    Proc far
    ApiSaveEax
    ApiSaveEbx
    ApiSaveEcx
    ApiSaveEdx
    ApiSaveEsi
    ApiSaveEdi
    
    push ds
    push ax
    push ebx
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
    pop ebx
    pop ax
    pop ds

    ApiCheckEdi
    ApiCheckEsi
    ApiCheckEdx
    ApiCheckEcx
    ApiCheckEbx
    ApiCheckEax
    retf32
delete_fm_handle    Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CalcSin
;
;           DESCRIPTION:    Calc current sin value
;
;           PARAMETERS:         DS      FM sel
;               ES      Note sel
;               EAX     Beta factor
;
;       RETURNS:    EAX     Value
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcSin Proc near
    push edx
    push bp
;    
    push eax
    mov bp,sp
;    
    mov eax,es:n_mod_diff
    add eax,es:n_mod_curr
    mov es:n_mod_curr,eax
    call InterpolateSin
;
    imul dword ptr [bp]
    shl edx,1    
    pop eax
;
    mov eax,es:n_carrier_diff
    add eax,es:n_carrier_curr
    add eax,edx
    mov es:n_carrier_curr,eax
    call InterpolateSin
;
    pop bp
    pop edx
    ret
CalcSin Endp




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetChannels
;
;           DESCRIPTION:    Set data to Left and Right channel
;
;           PARAMETERS:         DS      FM sel
;               ES      Note sel
;               FS      Left channel
;               GS      Right channel
;               DI      Offset into buffer
;               EAX     Value
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetChannels Proc near
    push eax
    push edx
    push esi
;
    mov esi,eax
;    
    mov eax,es:n_l_peak_volume
    imul esi
    shl edx,1
    add fs:[di],edx
    jno scR
;
    test edx,80000000h
    jz scLOvPos
;
    mov edx,7FFFFFFFh
    jmp scLOvSave

scLOvPos:
    mov edx,80000000h

scLOvSave:       
    mov fs:[di],edx

scR:
    mov eax,es:n_r_peak_volume
    imul esi
    shl edx,1
    add gs:[di],edx
    jno scDone
;
    test edx,80000000h
    jz scROvPos
;
    mov edx,7FFFFFFFh
    jmp scROvSave

scROvPos:
    mov edx,80000000h

scROvSave:       
    mov gs:[di],edx

scDone:
    inc es:n_buf_pos
    add di,4
;
    pop esi
    pop edx
    pop eax    
    ret
SetChannels Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PlayRelease
;
;           DESCRIPTION:    Play release part
;
;           PARAMETERS:         DS      FM sel
;               ES      Note sel
;               CX      Buffer size
;               FS      Left channel buf
;               GS      Right channel buf
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PlayRelease  Proc near
    mov di,es:n_buf_pos
    sub cx,di
    jbe prDone
;    
    shl di,2

prLoop:    
    mov eax,es:n_rel_fm_diff
    add eax,es:n_fm_curr

prCheckFmOverflow:
    test eax,0F0000000h
    jz prNoFmOverflow
;
    sub eax,10000000h
    mov edx,es:n_beta_fact
    shr edx,1
    mov es:n_beta_fact,edx
    jmp prCheckFmOverflow

prNoFmOverflow:
    mov es:n_fm_curr,eax
    call InterpolateExp
;
    imul es:n_beta_fact
    mov eax,edx
    shl eax,1
;
    call CalcSin
    mov esi,eax
;
    mov eax,es:n_rel_vol_diff
    add eax,es:n_vol_curr

prCheckVolOverflow:
    test eax,0F0000000h
    jz prNoVolOverflow
;
    sub eax,10000000h
    mov edx,es:n_curr_volume
    shr edx,1
    mov es:n_curr_volume,edx
    or edx,edx
    jz prRelDone
;    
    jmp prCheckVolOverflow

prNoVolOverflow:
    mov es:n_vol_curr,eax
    call InterpolateExp
;
    imul esi
    mov esi,edx
    shl esi,1
;
    mov eax,es:n_curr_volume
    imul esi
    shl edx,1
;    
    mov eax,edx
    call SetChannels
;    
    sub cx,1
    jnz prLoop
    jmp prDone

prRelDone:
    or es:n_flags,FLAG_NOTE_DONE
    
prDone:
    ret
PlayRelease Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PlaySustain
;
;           DESCRIPTION:    Play sustain part
;
;           PARAMETERS:         DS      FM sel
;               ES      Note sel
;               CX      Buffer size
;               FS      Left channel buf
;               GS      Right channel buf
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PlaySustain  Proc near
    mov di,es:n_buf_pos
    sub cx,di
    jbe psDone
;    
    shl di,2

psLoop:
    mov eax,es:n_sus_samples
    or eax,eax
    jz psSusDone
;
    dec eax
    mov es:n_sus_samples,eax    
;    
    mov eax,es:n_sus_fm_diff
    add eax,es:n_fm_curr

psCheckFmOverflow:
    test eax,0F0000000h
    jz psNoFmOverflow
;
    sub eax,10000000h
    mov edx,es:n_beta_fact
    shr edx,1
    mov es:n_beta_fact,edx
    jmp psCheckFmOverflow

psNoFmOverflow:
    mov es:n_fm_curr,eax
    call InterpolateExp
;
    imul es:n_beta_fact
    mov eax,edx
    shl eax,1
;
    call CalcSin
    mov esi,eax
;
    mov eax,es:n_sus_vol_diff
    add eax,es:n_vol_curr

psCheckVolOverflow:
    test eax,0F0000000h
    jz psNoVolOverflow
;
    sub eax,10000000h
    mov edx,es:n_curr_volume
    shr edx,1
    mov es:n_curr_volume,edx
    jmp psCheckVolOverflow

psNoVolOverflow:
    mov es:n_vol_curr,eax
    call InterpolateExp
;
    imul esi
    mov esi,edx
    shl esi,1
;
    mov eax,es:n_curr_volume
    imul esi
    shl edx,1
;    
    mov eax,edx
    call SetChannels
;    
    sub cx,1
    jnz psLoop
    jmp psDone

psSusDone:
    mov eax,es:n_fm_curr
    call InterpolateExp
;
    mov esi,es:n_beta_fact
    imul esi
    shl edx,1
    mov es:n_beta_fact,edx
    mov es:n_fm_curr,0
;
    mov eax,es:n_vol_curr
    call InterpolateExp
;
    mov esi,es:n_curr_volume
    imul esi
    shl edx,1
    mov es:n_curr_volume,edx
    mov es:n_vol_curr,0
;
    add cx,es:n_buf_pos
    mov es:n_callb,OFFSET PlayRelease
    jmp es:n_callb
    
psDone:
    ret
PlaySustain Endp



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           PlayAttack
;
;           DESCRIPTION:    Play attack part
;
;           PARAMETERS:         DS      FM sel
;               ES      Note sel
;               CX      Buffer size
;               FS      Left channel buf
;               GS      Right channel buf
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PlayAttack  Proc near
    mov di,es:n_buf_pos
    sub cx,di
    jbe paDone
;    
    shl di,2

paLoop:
    mov eax,es:n_beta_fact
    call CalcSin
    mov esi,eax
;
    mov eax,es:n_att_diff
    add eax,es:n_curr_volume
    mov es:n_curr_volume,eax
    test eax,80000000h
    jnz paAttDone
;
    imul esi
    mov eax,edx
    shl eax,1
    call SetChannels
;    
    loop paLoop
    jmp paDone

paAttDone:
    mov eax,7FFFFFFFh
    mov es:n_curr_volume,eax
;    
    call CalcSin
    call SetChannels
;    
    loop paMore
    jmp paDone

paMore:
    mov es:n_vol_curr,0
    mov es:n_fm_curr,0
    add cx,es:n_buf_pos
    mov es:n_callb,OFFSET PlaySustain
    jmp es:n_callb

paDone:   
    ret
PlayAttack  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           UpdateFmSel
;
;           DESCRIPTION:    Update FM selector
;
;           PARAMETERS:         DS      FM sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateFmSel Proc near
    mov ax,ds:f_note_list
    or ax,ax
    jz ufsSignal
;
    mov bx,ds:f_audio_handle
    or bx,bx
    jnz ufsHasHandle
;
    mov ax,ds:f_sample_rate
    mov cl,32
    mov dx,0FFFFh
    CreateAudioOutChannel
    mov ds:f_audio_handle,bx
    
ufsHasHandle:
    mov bx,ds:f_audio_handle
    IsAudioOutCompleted
    jc ufsDone
;
    mov cx,ds:f_buf_size
    or cx,cx
    jnz ufsCheckZero
;    
    GetAudioOutBuffers
    mov ds:f_buf_size,cx
    mov ds:f_lbuf_sel,si
    mov ds:f_rbuf_sel,di
    or ds:f_flags, FLAG_FM_ZERO

ufsCheckZero:
    test ds:f_flags,FLAG_FM_ZERO
    jz ufsHasBuffers
;    
    and ds:f_flags, NOT FLAG_FM_ZERO
    mov es,ds:f_rbuf_sel
    xor di,di
    xor eax,eax
    mov cx,ds:f_buf_size
    rep stosd
;
    mov es,ds:f_lbuf_sel
    xor di,di
    xor eax,eax
    mov cx,ds:f_buf_size
    rep stosd        
;
    mov ax,ds:f_note_list
    or ax,ax
    jz ufsDone
;
    EnterSection ds:f_section
    mov ax,ds:f_note_list
    mov si,ax

ufsSetLoop:    
    mov es,ax
    or es:n_flags, FLAG_NOTE_NEW
;
    mov ax,es:n_next
    cmp ax,si
    jne ufsSetLoop
;
    xor ax,ax
    mov es,ax
    LeaveSection ds:f_section

ufsHasBuffers:
    EnterSection ds:f_section

ufsRestart:
    mov ax,ds:f_note_list
    mov si,ax
;
    or ax,ax    
    jz ufsLeave
;
    mov fs,ds:f_lbuf_sel
    mov gs,ds:f_rbuf_sel
    mov cx,ds:f_buf_size

ufsLoop:    
    mov es,ax
    test es:n_flags, FLAG_NOTE_NEW
    jz ufsNext    

ufsDoThis:
    push ds
    push cx
    push si
;
    call es:n_callb
;
    pop si
    pop cx
    pop ds
;
    and es:n_flags, NOT FLAG_NOTE_NEW    

ufsNext:    
    test es:n_flags, FLAG_NOTE_DONE
    jz ufsKeep
;
    call RemoveNoteSel
    FreeMem
    jmp ufsRestart

ufsKeep:    
    mov ax,es:n_next
    cmp ax,si
    jne ufsLoop

ufsLeave:
    xor ax,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    LeaveSection ds:f_section
;    
    mov bx,ds:f_thread
    Signal

ufsSignal:
    test ds:f_flags,FLAG_FM_DELETE
    jnz ufsNewData
;
    test ds:f_flags,FLAG_FM_NEW
    jz ufsDone

ufsNewData:
    mov bx,ds:f_audio_handle
    or bx,bx
    jz ufsDone
;    
    IsAudioOutCompleted
    jc ufsDone
;
    test ds:f_flags,FLAG_FM_NEW
    jz ufsPostDone
;    
    PostAudioOutBuffers
    and ds:f_flags, NOT FLAG_FM_NEW    

ufsPostDone:    
    mov ax,ds:f_note_list
    or ax,ax
    jz ufsFreeAudio
;
    EnterSection ds:f_section
    or ds:f_flags,FLAG_FM_ZERO
    mov ds:f_buf_pos,0
;
    mov ax,ds:f_note_list
    mov si,ax

ufsClearLoop:    
    mov es,ax
    test es:n_flags, FLAG_NOTE_NEW
    jnz ufsClearNext
;    
    mov es:n_buf_pos,0
    or es:n_flags, FLAG_NOTE_NEW

ufsClearNext:
    mov ax,es:n_next
    cmp ax,si
    jne ufsClearLoop
;
    xor ax,ax
    mov es,ax
    LeaveSection ds:f_section
    jmp ufsDone

ufsFreeAudio:
    IsAudioOutCompleted
    jc ufsDone
;    
    mov bx,ds:f_audio_handle
    CloseAudioOutChannel
    mov ds:f_audio_handle,0
    mov ds:f_lbuf_sel,0
    mov ds:f_rbuf_sel,0
    mov ds:f_buf_size,0
        
ufsDone:    
    ret
UpdateFmSel Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init_fm_thread
;
;           DESCRIPTION:    Init FM thread
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fm_name DB 'FM',0

fm_thread_pr:
    mov ax,SEG data
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

fm_free_restart:
    mov bx,OFFSET fm_sel_arr
    mov cx,ds:fm_sel_count
    or cx,cx
    jz fm_leave

fm_free_loop:
    mov es,ds:[bx]
    test es:f_flags,FLAG_FM_DELETE
    jz fm_free_next
;
    mov ax,es:f_audio_handle
    or ax,ax
    jnz fm_free_next
;    
    FreeMem    

fm_free_move_loop:    
    mov ax,ds:[bx+2]
    mov ds:[bx],ax
    add bx,2
    loop fm_free_move_loop
;
    dec ds:fm_sel_count
    jmp fm_free_restart

fm_free_next:
    add bx,2
    loop fm_free_loop    

fm_leave:
    LeaveSection ds:fm_section
    jmp fm_wait_loop    


init_fm_thread  Proc far
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
    mov cx,stack0_size
    CreateThread
;
    popa
    pop es
    pop ds
    retf32
init_fm_thread  Endp
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           init
;
;           DESCRIPTION:    Init FM
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_fm
    
init_fm Proc near
    mov ax,cs
    mov ds,ax
    mov es,ax
;    
    mov ax,FM_INSTR_HANDLE
    mov edi,OFFSET delete_fm_handle
    RegisterHandle
;
    mov ax,FM_HANDLE
    mov edi,OFFSET delete_fm_handle
    RegisterHandle
;
    mov edi,OFFSET init_fm_thread
    HookInitTasking
;
    mov esi,OFFSET open_fm
    mov edi,OFFSET open_fm_name
    xor dx,dx
    mov ax,open_fm_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET close_fm
    mov edi,OFFSET close_fm_name
    xor dx,dx
    mov ax,close_fm_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET fm_wait
    mov edi,OFFSET fm_wait_name
    xor dx,dx
    mov ax,fm_wait_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET create_fm_instrument
    mov edi,OFFSET create_fm_instrument_name
    xor dx,dx
    mov ax,create_fm_instrument_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET free_fm_instrument
    mov edi,OFFSET free_fm_instrument_name
    xor dx,dx
    mov ax,free_fm_instrument_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_fm_attack
    mov edi,OFFSET set_fm_attack_name
    xor dx,dx
    mov ax,set_fm_attack_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_fm_sustain
    mov edi,OFFSET set_fm_sustain_name
    xor dx,dx
    mov ax,set_fm_sustain_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET set_fm_release
    mov edi,OFFSET set_fm_release_name
    xor dx,dx
    mov ax,set_fm_release_nr
    RegisterBimodalUserGate
;
    mov esi,OFFSET play_fm_note
    mov edi,OFFSET play_fm_note_name
    xor dx,dx
    mov ax,play_fm_note_nr
    RegisterBimodalUserGate
;
    mov bx,SEG data
    mov es,bx
    mov es:fm_thread,0
    mov es:fm_sel_count,0
    mov ax,es
    mov ds,ax
    InitSection ds:fm_section
    ret
init_fm Endp

code    ENDS

    END
