;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; DCF.ASM
; DCF77 device driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME dcf

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\wait.inc
INCLUDE ..\..\kernel\handle.inc

save_data_struc	STRUC

sd_day		DD ?
sd_hour		DB ?
sd_min		DB ?
sd_fract    DD ?

save_data_struc	ENDS


dcf_data	STRUC

thread_id		DW ?
rtc_id			DW ?

fract_diff		DD ?,?
sys_diff		DD ?,?

on_time			DD ?,?
start_pulse		DD ?,?
end_pulse		DD ?,?

first_pulse		DD ?,?
curr_pulse		DD ?,?
curr_sec		DW ?
curr_sys_diff   DD ?,?

curr_year		DW ?
curr_month		DB ?
curr_day		DB ?
curr_hour		DB ?
curr_min		DB ?
curr_diff		DD ?

diff_day        DD ?
diff_hour       DB ?
diff_min        DB ?
diff_sign       DB ?

val_arr			DB 60 DUP(?)
diff_arr		DD 60 DUP(?)

save_buf		DB 20 * SIZE save_data_struc DUP(?)

temp_buf		DB 32 DUP(?)

dcf_data	ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			dcf_int
;
;		DESCRIPTION:	DCF interrupt
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dcf_int	Proc far
	GetSystemTime
	cli
	mov ebx,eax
	mov ecx,edx
;
	mov dx,28Ah
	in al,dx
;
	push ax
	mov edx,ds:on_time
	or edx,ds:on_time+4
	jz dcf_int_not_started

dcf_int_started:
	test al,2
	jz dcf_int_check_pulse
;
	mov ds:on_time,ebx
	mov ds:on_time+4,ecx
	jmp dcf_int_ack

dcf_int_check_pulse:
	mov eax,ebx
	sub eax,ds:on_time
	cmp eax,1193
	jc dcf_int_start_done
;
	mov eax,ds:start_pulse
	or eax,ds:start_pulse+4
	jz dcf_int_valid_start

dcf_int_valid_end:
	mov ds:end_pulse,ebx
	mov ds:end_pulse+4,ecx
	jmp dcf_int_start_done

dcf_int_valid_start:
	mov eax,ds:on_time
	mov ds:start_pulse,eax
	mov eax,ds:on_time+4
	mov ds:start_pulse+4,eax
;
	mov ds:end_pulse,ebx
	mov ds:end_pulse+4,ecx
;
	mov bx,ds:thread_id
	Signal

dcf_int_start_done:
	mov ds:on_time,0
	mov ds:on_time+4,0
	jmp dcf_int_ack

dcf_int_not_started:
	test al,2
	jz dcf_int_ack
;
	mov ds:on_time,ebx
	mov ds:on_time+4,ecx
	
dcf_int_ack:
	pop ax
	cli
	and al,2
	push ax
	shl al,2
	mov ah,al
	mov dx,288h
	in al,dx
	and al,NOT 8
	or al,ah
	out dx,al
;
	mov dx,280h
	mov al,2
	out dx,al
;
	pop ax
	mov ah,al
	mov dx,28Ah
	in al,dx
	and al,2
	cmp al,ah
	jne dcf_int
	ret
dcf_int	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			int_timeout
;
;		description:	Reinitialize timer chip
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

int_timeout	Proc far
    mov dx,284h
	in al,dx
	and al,NOT 2
	out dx,al
;
	mov dx,280h
	mov al,2
	out dx,al
;
	mov dx,284h
	in al,dx
	or al,2
    out dx,al
;
	mov bx,dcf_data_sel
	mov ds,bx
	GetSystemTime
	add eax,1193046 * 90
	adc edx,0
	mov bx,cs
	mov es,bx
	mov di,OFFSET int_timeout
	mov bx,ds:thread_id
	StartTimer
	ret
int_timeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForPulse
;
;		DESCRIPTION:	Wait for a single pulse
;
;		RETURNS:		EDX:EAX		Pulse time
;						CL			Pulse value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForPulse	Proc near
	mov ds:start_pulse,0	
	mov ds:start_pulse+4,0	
	mov ds:end_pulse,0	
	mov ds:end_pulse+4,0	
;
	push es
	push bx
	push di
	GetSystemTime
	mov ax,cs
	mov es,ax
	add eax,1193046 * 5
	adc edx,0
	mov di,OFFSET int_timeout
	mov bx,ds:thread_id
	StopTimer
	StartTimer
	WaitForSignal
	StopTimer
	pop di
	pop bx
	pop es
;
	mov ax,400
	WaitMilliSec
;
	mov eax,ds:start_pulse
	or eax,ds:start_pulse+4
	jz WaitForPulse
;
	mov eax,ds:end_pulse
	or eax,ds:end_pulse+4
	jz WaitForPulse
;
	xor cl,cl
	mov eax,ds:end_pulse
	sub eax,ds:start_pulse
	cmp eax,1193 * 130
	jc wait_for_pulse_time
;
	inc cl

wait_for_pulse_time:
	mov eax,ds:start_pulse
	mov edx,ds:start_pulse+4
	ret
WaitForPulse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SyncToDcf
;
;		DESCRIPTION:	Synchronize to DCF
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SyncToDcf	Proc near
	pushad
;
	call WaitForPulse

sync_dcf_loop:
	push eax
	call WaitForPulse
	mov ebx,eax
	pop esi
	sub ebx,esi
	cmp ebx,1192 * 1800
	jb sync_dcf_loop
;
	cmp ebx,1192 * 2200
	ja sync_dcf_loop
;
	mov ds:first_pulse,eax
	mov ds:first_pulse+4,edx
	mov ds:curr_sec,0
;
	popad
	ret
SyncToDcf	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetSample
;
;		DESCRIPTION:	Get a sample (after sync is achieved)
;
;		RETURNS:		BX		Offset with minute
;						CL		Value (pulse length)					
;						EBP		Diff from reference (in tics)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSample	Proc near
	push eax
	push edx
	push si
	push edi

get_sample_loop:
	call WaitForPulse
	mov ds:curr_pulse,eax
	mov ds:curr_pulse+4,edx
;
	sub eax,ds:first_pulse		; eax = curr_pulse - first_pulse
	mov edi,eax					; edi = curr_pulse - first_pulse
	xor edx,edx
	mov ebx,3600
	mul ebx                     ; edx:eax = 3600 * (curr_pulse - first_pulse)
	mov si,dx                   ; si = seconds since first pulse
;
	mov ebx,1000000
	mul ebx                     ; edx:eax = 3600 * 1e6 * (curr_pulse - first_pulse)
	mov eax,edx                 ; eax = pulse diff in microseconds
;
	cmp eax,200000
	jb get_sample_valid
;
	cmp eax,800000
	jb get_sample_loop
;
	inc si

get_sample_valid:
	mov bx,si
	movzx eax,bx
	mov edx,1193046
	mul edx				    	; eax = curr_sec as timedate
	sub edi,eax				    ; edi = diff from curr_sec as timedate
	mov ebp,edi				    ; ebp = diff from curr_sec
;
	pop edi
	pop si
	pop edx
	pop eax
	ret
GetSample	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ProcessMinSamples
;
;		DESCRIPTION:	Process a full minute of samples
;
;		RETURNS:		NC
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessMinSamples	Proc near
	pushad
;
	mov al,ds:val_arr
	or al,al
	jnz process_ms_failed
;
	mov al,ds:val_arr+20
	mov dx,1
	or al,al
	jz process_ms_failed
;
	mov cx,2000
	xor ah,ah
	mov al,ds:val_arr+53
	add al,al
	add al,ds:val_arr+52
	add al,al
	add al,ds:val_arr+51
	add al,al
	add al,ds:val_arr+50
	add cx,ax
;
	mov al,ds:val_arr+57
	add al,al
	mov al,ds:val_arr+56
	add al,al
	mov al,ds:val_arr+55
	add al,al
	add al,ds:val_arr+54
	mov ah,10
	mul ah
	add cx,ax
	mov ds:curr_year,cx
;
	xor ah,ah
	mov al,ds:val_arr+48
	add al,al
	add al,ds:val_arr+47
	add al,al
	add al,ds:val_arr+46
	add al,al
	add al,ds:val_arr+45
	mov cx,ax
;
	mov al,ds:val_arr+49
	mov ah,10
	mul ah
	add cx,ax
	mov ds:curr_month,cl
;
	xor ah,ah
	mov al,ds:val_arr+39
	add al,al
	add al,ds:val_arr+38
	add al,al
	add al,ds:val_arr+37
	add al,al
	add al,ds:val_arr+36
	mov cx,ax
;
	mov al,ds:val_arr+41
	add al,al
	add al,ds:val_arr+40
	mov ah,10
	mul ah
	add cx,ax
	mov ds:curr_day,cl
;
	xor ah,ah
	mov al,ds:val_arr+32
	add al,al
	add al,ds:val_arr+31
	add al,al
	add al,ds:val_arr+30
	add al,al
	add al,ds:val_arr+29
	mov cx,ax
;
	mov al,ds:val_arr+34
	add al,al
	add al,ds:val_arr+33
	mov ah,10
	mul ah
	add cx,ax
	mov ds:curr_hour,cl
;
	xor ah,ah
	mov al,ds:val_arr+24
	add al,al
	add al,ds:val_arr+23
	add al,al
	add al,ds:val_arr+22
	add al,al
	add al,ds:val_arr+21
	mov cx,ax
;
	mov al,ds:val_arr+27
	add al,al
	add al,ds:val_arr+26
	add al,al
	add al,ds:val_arr+25
	mov ah,10
	mul ah
	add cx,ax
	mov ds:curr_min,cl
;
	mov cx,59				; process 59 s
	xor eax,eax				; sum = 0
	xor bx,bx				; sec = 0

process_ms_loop:
	add eax,ds:[bx].diff_arr		; sum += diff[sec]
	add bx,4						; sec++
	loop process_ms_loop
;
	cdq								; edx:eax = sum
	mov ebx,59
	idiv ebx						; eax = sum / 59 (mean value of difference)
	cdq								; edx:eax = average diff
	mov ds:curr_diff,eax			; curr_diff = average diff
	add ds:first_pulse,eax
	adc ds:first_pulse+4,edx		; first_pulse += average diff
;
	mov dx,ds:curr_year
	mov ch,ds:curr_month
	mov cl,ds:curr_day
	mov bh,ds:curr_hour
	mov bl,ds:curr_min
	xor ah,ah
	TimeToBinary			; edx:eax = time in message
	add eax,60 * 1193046
	adc edx,0				; time + 1 min
	sub eax,ds:first_pulse
	sbb edx,ds:first_pulse+4	; time + 1 min - first_pulse - average-diff
;
    mov ds:curr_sys_diff,eax
    mov ds:curr_sys_diff+4,edx
	clc
	jmp process_ms_done

process_ms_failed:
	stc

process_ms_done:
	popad
	ret
ProcessMinSamples	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RestartMinSamples
;
;		DESCRIPTION:	Restart minute sampling
;
;		PARAMETERS:		EBP		Last Diff
;						CL		Last pulse value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RestartMinSamples	Proc near
	push edx
	mov edx,ds:curr_pulse
	mov ds:first_pulse,edx
	mov edx,ds:curr_pulse+4
	mov ds:first_pulse+4,edx
	mov ds:curr_sec,0
	mov ds:val_arr,cl
	pop edx
	ret
RestartMinSamples	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetMinSamples
;
;		DESCRIPTION:	Fill up diff arr of one minute
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMinSamples	Proc near
    pushad

get_ms_loop:
	call GetSample
	mov dx,ds:curr_sec
	inc dx
	cmp dx,bx
	jne get_ms_restart

get_ms_ok:
    cmp bx,59
    jae get_ms_restart
;
	mov ds:curr_sec,bx
	mov ds:[bx].val_arr,cl
	mov si,bx
	shl si,2
	mov ds:[si].diff_arr,ebp
;
	cmp bx,58
	jne get_ms_loop
;
	mov ds:diff_arr,0
	call ProcessMinSamples
	jc get_ms_retry
;
    call GetSample
	call RestartMinSamples
	jmp get_ms_done

get_ms_retry:
	call GetSample

get_ms_restart:
	call RestartMinSamples
	jmp get_ms_loop

get_ms_done:
    popad
	ret
GetMinSamples	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			UpdateDiff
;
;		DESCRIPTION:	Update difference from time
;
;		PARAMETERS:		DS:SI		Buf to save in
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateDiff	Proc near
	pushad
;
    mov eax,ds:curr_sys_diff
	mov ebx,60
	mul ebx
	cdq
	idiv ebx
	mov ds:[si].sd_fract,eax
	cdq
;
	mov ebx,eax
	mov eax,ds:curr_sys_diff
	sub eax,ebx
	mov ebx,edx
    mov edx,ds:curr_sys_diff+4
	sbb edx,ebx
	add eax,2222222h
	adc edx,0
;
	push eax
	mov eax,edx
	cdq
	mov ecx,24
	idiv ecx
	mov ds:[si].sd_day,eax
	mov ds:[si].sd_hour,dl
	pop eax	

upd_diff_min:
	mov edx,60
	mul edx				
	mov ds:[si].sd_min,dl
;
	mov eax,ds:[si].sd_fract
;
	mov ebx,ds:fract_diff
	sub ebx,eax
	jc upd_diff_neg
;
	cmp ebx,2222222h
	jbe upd_diff_save
;
	add ds:sys_diff,4444444h
	adc ds:sys_diff+4,0
	jmp upd_diff_save

upd_diff_neg:
	neg ebx
	cmp ebx,2222222h
	jbe upd_diff_save
;
	sub ds:sys_diff,4444444h
	sbb ds:sys_diff+4,0

upd_diff_save:
	cdq
	mov ds:fract_diff,eax
	mov ds:fract_diff+4,edx
;
	add eax,ds:sys_diff
	adc edx,ds:sys_diff+4
	UpdateTime
;
;	mov bx,ds:rtc_id
;	Signal

upd_diff_done:
	popad
	ret
UpdateDiff	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetBestDiff
;
;		DESCRIPTION:	Get the best difference
;
;		RETURNS:		NC		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBestDiff	Proc near
	pushad
;
	mov si,OFFSET save_buf
	mov cx,20

gbd_day_loop:
	mov eax,ds:[si].sd_day
;
	push cx
	push si
	mov dx,1

gbd_day_iloop:
	add si,SIZE save_data_struc
	cmp eax,ds:[si].sd_day
	jne	gbd_day_next
;
	inc dx

gbd_day_next:
	loop gbd_day_iloop
;
	pop si
	pop cx
	cmp dx,10
	jae gbd_day_ok
;
	add si,SIZE save_data_struc
	loop gbd_day_loop
;
	jmp gbd_fail

gbd_day_ok:
	mov si,OFFSET save_buf
	mov ds:[si].sd_day,eax
	mov cx,20
	
gbd_hour_loop:
	mov al,ds:[si].sd_hour
;
	push cx
	push si
	mov dx,1

gbd_hour_iloop:
	add si,SIZE save_data_struc
	cmp al,ds:[si].sd_hour
	jne	gbd_hour_next
;
	inc dx

gbd_hour_next:
	loop gbd_hour_iloop
;
	pop si
	pop cx
	cmp dx,10
	jae gbd_hour_ok
;
	add si,SIZE save_data_struc
	loop gbd_hour_loop
;
	jmp gbd_fail

gbd_hour_ok:
	mov si,OFFSET save_buf
	mov ds:[si].sd_hour,al
	mov cx,20
	
gbd_min_loop:
	mov al,ds:[si].sd_min
;
	push cx
	push si
	mov dx,1

gbd_min_iloop:
	add si,SIZE save_data_struc
	cmp al,ds:[si].sd_min
	jne	gbd_min_next
;
	inc dx

gbd_min_next:
	loop gbd_min_iloop
;
	pop si
	pop cx
	cmp dx,10
	jae gbd_min_ok
;
	add si,SIZE save_data_struc
	loop gbd_min_loop
;
	jmp gbd_fail

gbd_min_ok:
	mov si,OFFSET save_buf
	mov ds:[si].sd_min,al
	clc
	jmp gbd_done

gbd_fail:
	stc

gbd_done:
	popad
	ret
GetBestDiff	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetTimeDiff
;
;		DESCRIPTION:	Set time difference in real-time clock
;
;		PARAMETERS:		DS:SI		Buf to be saved in
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetTimeDiff	Proc near
	pushad
;
	movzx edx,ds:[si].sd_min
	xor eax,eax
	mov ebx,60
	div ebx
;
	mov ebx,eax
	mov edx,ds:[si].sd_day
	mov eax,24
	imul edx
	movsx edx,ds:[si].sd_hour
	add edx,eax
	mov eax,ebx
	mov ds:sys_diff,eax
	mov ds:sys_diff+4,edx
	add eax,ds:fract_diff
	adc edx,ds:fract_diff+4
	UpdateTime
;
	mov bx,ds:rtc_id
	Signal
;
	popad
	ret
SetTimeDiff	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			dcf_thread
;
;		DESCRIPTION:	DCF thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dcf_thread_name		DB 'DCF',0

dcf_thread:
	sti
;
	mov ax,dcf_data_sel
	mov ds,ax
;
	GetThread
	mov ds:thread_id,ax
	mov ds:fract_diff,0
	mov ds:fract_diff+4,0
	mov ds:sys_diff,0
	mov ds:sys_diff+4,0
	mov ds:on_time,0	
	mov ds:on_time+4,0	
	mov ds:start_pulse,0	
	mov ds:start_pulse+4,0	
	mov ds:end_pulse,0	
	mov ds:end_pulse+4,0	
;
	mov al,5
	mov cx,cs
	mov es,cx
	mov di,OFFSET dcf_int
	RequestPrivateIrqHandler
;
	mov ax,ds
	mov es,ax
;
    mov dx,284h
    mov al,2
    out dx,al
;
    mov dx,28Bh
    mov al,8Bh
    out dx,al
;
	mov ax,dcf_data_sel
	mov es,ax

dcf_sync_loop:
	call SyncToDcf

dcf_loop:
	mov si,OFFSET save_buf
	mov cx,20

dcf_time_loop:
	call GetMinSamples
	call UpdateDiff
	add si,SIZE save_data_struc
	loop dcf_time_loop
;
	int 3
	call GetBestDiff
	jc dcf_loop
;
	mov si,OFFSET save_buf
	call SetTimeDiff
;
	jmp dcf_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			rtc_thread
;
;		DESCRIPTION:	RTC update thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rtc_thread_name		DB 'DCF RTC',0

rtc_thread:
	sti
	mov ax,dcf_data_sel
	mov ds,ax
;
	GetThread
	mov ds:rtc_id,ax

rtc_loop:
	WaitForSignal
	mov eax,ds:fract_diff
	mov edx,ds:fract_diff+4
	add eax,ds:sys_diff
	adc edx,ds:sys_diff+4
;	UpdateTime
	UpdateRtc
	jmp rtc_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			init_dcf_thread
;
;		DESCRIPTION:	Init DCF thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_dcf_thread	PROC far
	push ds
	push es
	pusha
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET dcf_thread
	mov di,OFFSET dcf_thread_name
	mov ecx,512
	mov ax,25
	CreateThread
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET rtc_thread
	mov di,OFFSET rtc_thread_name
	mov ecx,512
	mov ax,1
	CreateThread
;
	popa
	pop es
	pop ds
	ret
init_dcf_thread	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Init
;
;		DESCRIPTION:	Initialize module
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	push ds
	push es
	pusha
;
	mov bx,dcf_code_sel
	InitDevice
;
	mov eax,SIZE dcf_data
	mov bx,dcf_data_sel
	AllocateFixedSystemMem
;
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov di,OFFSET init_dcf_thread
	HookInitTasking
;
	popa
	pop es
	pop ds
	ret
init	Endp

code    ENDS

	END init
