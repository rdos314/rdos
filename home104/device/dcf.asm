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
sd_us		DD ?

save_data_struc	ENDS


dcf_data	STRUC

int_time		DD ?,?
thread_id		DW ?
curr_level		DB ?

first_pulse		DD ?,?
curr_pulse		DD ?,?
curr_sec		DW ?

curr_year		DW ?
curr_month		DB ?
curr_day		DB ?
curr_hour		DB ?
curr_min		DB ?
curr_diff		DD ?

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
;		NAME:			WriteHexByte
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AL		Byte to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte	PROC near
	push ax
	mov ah,al
	and al,0F0h
	rol al,4
	cmp al,0Ah
	jb write_byte_low1
	add al,7
write_byte_low1:
	add al,'0'
	WriteChar
	mov al,ah
	and al,0Fh
	cmp al,0Ah
	jb write_byte_high1
	add al,7
write_byte_high1:
	add al,'0'
	WriteChar
	pop ax
	ret
WriteHexByte	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexWord
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AX		Word to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord	PROC near
	xchg al,ah
	call WriteHexByte
	xchg al,ah
	call WriteHexByte
	ret
WriteHexWord	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexDword
;
;		DESCRIPTION:	
;
;		PARAMETERS:		EAX		Dword to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexDword	PROC near
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	rol eax,8
	call WriteHexByte
	ret
WriteHexDword	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			IntToStr
;
;		DESCRIPTION:	Convert long to asciiz string
;
;		PARAMETERS:		EAX			Value
;						CX			Number of position
;						ES:DI		String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dec_tab:
	DD 1
	DD 10
	DD 100
	DD 1000
	DD 10000
	DD 100000
	DD 1000000
	DD 10000000
	DD 100000000
	DD 1000000000

IntToStr	PROC near
	push ax
	push bx
	push ecx
	push edx
	push di
	mov edx,eax
	mov ah,cl
	mov bx,cx
	dec bx
	shl bx,2
loop_omv_dec:
	mov ecx,dword ptr cs:[bx].dec_tab
	xor al,al
loop_dec_dig:
	inc al
	sub edx,ecx
	jnc loop_dec_dig
	add edx,ecx
	dec al
	sub bx,4
	add al,'0'
	stosb
	dec ah
	jne loop_omv_dec
	xor al,al
	stosb
	pop di
	pop edx
	pop ecx
	pop bx
	pop ax
	ret
IntToStr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RemoveLeading
;
;		DESCRIPTION:	Remove leading zeros
;
;		PARAMETERS:		ES:DI		STRING
;
;		RETURNS:		CY		Significant digits found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RemoveLeading	Proc near
	push ax
	push di
RemoveLeadingLoop:
	mov al,es:[di]
	or al,al
	clc
	jz RemoveLeadingDone
	cmp al,'0'
	stc
	jnz RemoveLeadingDone
	mov byte ptr es:[di],' '
	inc di
	jmp RemoveLeadingLoop
RemoveLeadingDone:
	pop di
	pop ax
	ret
RemoveLeading	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteTime
;
;		DESCRIPTION:	Write time
;
;		PARAMETERS:		EDX:EAX		Binary time
;						ES:DI		Temp storage
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteTime	Proc near
	pushad
	push eax
	mov eax,edx
	xor edx,edx
	mov ecx,24
	div ecx
	mov cx,8
	call IntToStr
	call RemoveLeading
	pushf
	WriteAsciiz
	mov al,' '
	WriteChar
	mov eax,edx
	mov cx,2
	call IntToStr
	mov al,'.'
	popf
	jc SignHour
	call RemoveLeading
	jc SignHour
	mov al,' '
SignHour:
	pushf
	WriteAsciiz
	WriteChar
	popf
	pop eax
;
	pushf
	mov edx,60
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov cx,2
	call IntToStr
	mov al,'.'
	popf
	jc MinSign
	call RemoveLeading
	jc MinSign
	mov al,' '
MinSign:
	pushf
	WriteAsciiz
	WriteChar
	popf
	pop eax
;
	pushf
	mov edx,60
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov cx,2
	call IntToStr
	mov al,','
	popf
	jc SecSign
	call RemoveLeading
	jc SecSign
	mov al,' '
SecSign:
	pushf
	WriteAsciiz
	WriteChar
	popf
	pop eax
;
	pushf
	mov edx,1000
	mul edx
	popf
	push eax
	pushf
	mov eax,edx
	mov cx,3
	call IntToStr
	mov al,' '
	popf
	jc MilliSign
	call RemoveLeading
MilliSign:
	pushf
	WriteAsciiz
	WriteChar
	popf
	pop eax
;
	pushf
	mov edx,1000
	mul edx
	mov eax,edx
	mov cx,3
	call IntToStr
	popf
	jc MikroSign
	call RemoveLeading
MikroSign:
	WriteAsciiz
	popad
	ret
WriteTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			dcf_timeout
;
;		DESCRIPTION:	DCF timeout. Check level + wake-up processing thread
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dcf_timeout	Proc far
	push ds
;
	mov ax,dcf_data_sel
	mov ds,ax
;
	mov dx,28Ah
	in al,dx
	and al,10h
	jz dcf_long

dcf_short:
	mov ds:curr_level,0
	jmp dcf_timeout_signal

dcf_long:
	mov ds:curr_level,1

dcf_timeout_signal:
	mov bx,ds:thread_id
	Signal
;
	pop ds
	ret
dcf_timeout	Endp

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
	mov ds:int_time,eax
	mov ds:int_time+4,edx
;
	mov dx,28Ah
	in al,dx
	and al,2
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
	ret
dcf_int	Endp

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
	WaitForSignal
;
	mov eax,ds:int_time
	mov edx,ds:int_time+4
	mov cl,ds:curr_level
;
	push ax
	push dx

wait_pulse_clear_wait:
	mov dx,28Ah
	in al,dx
	test al,10h
	jnz wait_pulse_clear_int
;
	mov ax,50
	WaitMilliSec
	jmp wait_pulse_clear_wait

wait_pulse_clear_int:
	mov dx,280h
	mov al,2
	out dx,al	
;
	pop dx
	pop ax
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
	cmp ebx,1192 * 800
	jb sync_dcf_loop
;
	cmp ebx,1192 * 1200
	ja sync_dcf_loop
;
	mov ds:first_pulse,eax
	mov ds:first_pulse+4,edx
;
	popad
	ret
SyncToDcf	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ClearSamples
;
;		DESCRIPTION:	Clear samples
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ClearSample	Proc near
	pushad
	xor cx,cx
	xor dx,dx	
	SetCursorPosition
;
	mov cx,30
	mov al,' '

clear_sample0:
	WriteChar
	loop clear_sample0
;
	xor cx,cx
	mov dx,1
	SetCursorPosition
;
	mov cx,30
	mov al,' '

clear_sample1:
	WriteChar
	loop clear_sample1
;
	popad	
	ret
ClearSample	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ShowSample
;
;		DESCRIPTION:	Show a sample
;
;		PARAMETERS:		BX		Offset within minute
;						CL		Value (pulse length)					
;						EBP		Diff from normal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowSample	Proc near
	pushad
;
	push cx
;
	xor cx,cx
	mov dx,6
	SetCursorPosition
;
	test ebp,80000000h
	jz show_sample_diff
;
	mov al,'-'
	WriteChar
	neg ebp

show_sample_diff:
	mov eax,ebp
	xor edx,edx
	mov di,OFFSET temp_buf
	call WriteTime
;
	mov al,' '
	WriteChar
;
	xor dx,dx
	cmp bx,30
	jb show_sample_pos_ok
;
	sub bx,30
	inc dx

show_sample_pos_ok:
	mov cx,bx
	SetCursorPosition
;
	pop ax
	add al,'0'
	WriteChar
;
	popad	
	ret
ShowSample	Endp

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
	sub eax,ds:first_pulse
	mov edi,eax	
	xor edx,edx
	mov ebx,3600
	mul ebx
	mov si,dx
;
	mov ebx,1000000
	mul ebx
	mov eax,edx
;
	cmp eax,200000
	jb get_sample_valid
;
	inc si
	cmp eax,800000
	ja get_sample_valid
;
	jmp get_sample_loop

get_sample_valid:
	mov ax,si
	xor dx,dx
	mov bx,60
	div bx
	mov bx,dx
;
	movzx eax,bx
	mov edx,1193000
	mul edx
	sub edi,eax
	mov ebp,edi
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
;		NAME:			ProcessSamples
;
;		DESCRIPTION:	Process a full minute of samples
;
;		RETURNS:		NC
;						EDX:EAX		Diff
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProcessSamples	Proc near
	push ebx
	push ecx
	push esi
	push edi
;
	mov al,ds:val_arr
	or al,al
	jnz process_samples_failed
;
	mov al,ds:val_arr+20
	mov dx,1
	or al,al
	jz process_samples_failed
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
	mov cx,59
	xor eax,eax
	xor bx,bx

process_diff_loop:
	add eax,ds:[bx].diff_arr
	add bx,4
	loop process_diff_loop
;
	xor cx,cx
	mov dx,2
	SetCursorPosition
;
	cdq
	mov ebx,59
	idiv ebx
	cdq
	mov ds:curr_diff,eax
	add ds:first_pulse,eax
	adc ds:first_pulse+4,edx
;
	test edx,80000000h
	jz process_show_time
;
	mov al,'-'
	WriteChar
	not eax
	not edx
	add eax,1
	adc edx,0

process_show_time:
	mov di,OFFSET temp_buf
	call WriteTime	
;
	mov dx,ds:curr_year
	mov ch,ds:curr_month
	mov cl,ds:curr_day
	mov bh,ds:curr_hour
	mov bl,ds:curr_min
	xor ah,ah
	TimeToBinary
	add eax,60 * 1193000
	adc edx,0
	sub eax,ds:first_pulse
	sbb edx,ds:first_pulse+4
	clc
	jmp process_samples_done

process_samples_failed:
	mov ax,dx
	xor cx,cx
	mov dx,2
	SetCursorPosition
	call WriteHexByte
	stc

process_samples_done:
	pop edi
	pop esi
	pop ecx
	pop ebx
	ret
ProcessSamples	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RestartSample
;
;		DESCRIPTION:	Restart sampling
;
;		PARAMETERS:		EBP		Last Diff
;						CL		Last pulse value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RestartSample	Proc near
	push edx
	mov edx,ds:curr_pulse
	mov ds:first_pulse,edx
	mov edx,ds:curr_pulse+4
	mov ds:first_pulse+4,edx
	mov ds:curr_sec,0
	mov ds:val_arr,cl
	call ClearSample
	pop edx
	ret
RestartSample	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetDiff
;
;		DESCRIPTION:	Get difference from time
;
;		RETURNS:		EDX:EAX		Diff
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDiff	Proc near
	push bx
	push cx
	push esi
	push ebp

get_diff_loop:
	call GetSample
	mov dx,ds:curr_sec
	cmp dx,bx
	je get_diff_loop
;
	inc dx
	cmp dx,bx
	jne get_diff_restart

get_diff_ok:
	mov ds:curr_sec,bx
	mov ds:[bx].val_arr,cl
	mov si,bx
	shl si,2
	mov ds:[si].diff_arr,ebp
	call ShowSample
;
	cmp bx,58
	jne get_diff_loop
;
	mov ds:diff_arr,0
	call ProcessSamples
	jc get_diff_retry
;
	call RestartSample
	xor bx,bx
	call ShowSample
	jmp get_diff_done

get_diff_retry:
	call GetSample

get_diff_restart:
	call RestartSample
	xor bx,bx
	call ShowSample
	jmp get_diff_loop

get_diff_done:
	pop ebx
	pop esi
	pop cx
	pop bx
	ret
GetDiff	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveDiff
;
;		DESCRIPTION:	Save difference from time
;
;		PARAMETERS:		EDX:EAX		Diff
;						DS:SI		Buf to save in
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveDiff	Proc near
	pushad
;
	test edx,80000000h
	jz save_diff_pos
;
	push eax
	not eax
	not edx
	mov eax,edx
	xor edx,edx
	mov ecx,24
	div ecx
	inc eax
	neg eax
	mov ds:[si].sd_day,eax
	mov al,23
	sub al,dl
	mov ds:[si].sd_hour,al
	pop eax
	jmp save_diff_min

save_diff_pos:
	push eax
	mov eax,edx
	xor edx,edx
	mov ecx,24
	div ecx
	mov ds:[si].sd_day,eax
	mov ds:[si].sd_hour,dl
	pop eax

save_diff_min:
	mov edx,60
	mul edx
	mov ds:[si].sd_min,dl
;
	mov edx,60000000
	mul edx
	mov ds:[si].sd_us,edx
;
	popad
	ret
SaveDiff	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ShowDiff
;
;		DESCRIPTION:	Show difference from time
;
;		PARAMETERS:		DS:SI		Buf to saved in
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ShowDiff	Proc near
	pushad
;
	mov di,OFFSET temp_buf
	xor cx,cx
	mov dx,5
	SetCursorPosition
;
	mov eax,ds:[si].sd_day
	test eax,80000000h
	jz show_diff_do
;
	push ax
	mov al,'-'
	WriteChar
	pop ax

show_diff_do:
	mov cx,8
	call IntToStr
	call RemoveLeading
	WriteAsciiz
	mov al,' '
	WriteChar
;
	movzx eax,ds:[si].sd_hour
	mov cx,2
	call IntToStr
	call RemoveLeading
	WriteAsciiz
	mov al,'.'
	WriteChar
;
	movzx eax,ds:[si].sd_min
	mov cx,2
	call IntToStr
	call RemoveLeading
	WriteAsciiz
	mov al,'.'
	WriteChar
;
	mov eax,ds:[si].sd_us
	mov cx,8
	call IntToStr
	call RemoveLeading
	WriteAsciiz
;
	mov al,' '
	WriteChar
	mov al,' '
	WriteChar
	mov al,' '
	WriteChar
;
	popad
	ret
ShowDiff	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CalcMeanDiff
;
;		DESCRIPTION:	Calc the mean difference
;
;		RETURNS:		NC		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcMeanDiff	Proc near
	pushad
;
	mov si,OFFSET save_buf
	mov cx,20

calc_day_loop:
	mov eax,ds:[si].sd_day
;
	push cx
	push si
	mov dx,1

calc_day_iloop:
	add si,SIZE save_data_struc
	cmp eax,ds:[si].sd_day
	jne	calc_day_next
;
	inc dx

calc_day_next:
	loop calc_day_iloop
;
	pop si
	pop cx
	cmp dx,10
	jae calc_day_ok
;
	add si,SIZE save_data_struc
	loop calc_day_loop
;
	jmp calc_fail

calc_day_ok:
	mov si,OFFSET save_buf
	mov ds:[si].sd_day,eax
	mov cx,20
	
calc_hour_loop:
	mov al,ds:[si].sd_hour
;
	push cx
	push si
	mov dx,1

calc_hour_iloop:
	add si,SIZE save_data_struc
	cmp al,ds:[si].sd_hour
	jne	calc_hour_next
;
	inc dx

calc_hour_next:
	loop calc_hour_iloop
;
	pop si
	pop cx
	cmp dx,10
	jae calc_hour_ok
;
	add si,SIZE save_data_struc
	loop calc_hour_loop
;
	jmp calc_fail

calc_hour_ok:
	mov si,OFFSET save_buf
	mov ds:[si].sd_hour,al
	mov cx,20
	
calc_min_loop:
	mov al,ds:[si].sd_min
;
	push cx
	push si
	mov dx,1

calc_min_iloop:
	add si,SIZE save_data_struc
	cmp al,ds:[si].sd_min
	jne	calc_min_next
;
	inc dx

calc_min_next:
	loop calc_min_iloop
;
	pop si
	pop cx
	cmp dx,10
	jae calc_min_ok
;
	add si,SIZE save_data_struc
	loop calc_min_loop
;
	jmp calc_fail

calc_min_ok:
	mov si,OFFSET save_buf
	mov ds:[si].sd_min,al
	mov cx,20
;
	xor eax,eax

calc_us_loop:
	add eax,[si].sd_us
	add si,SIZE save_data_struc
	loop calc_us_loop
;
	xor edx,edx
	mov ecx,20
	div ecx
;
	mov [si].sd_us,eax
	clc
	jmp calc_done

calc_fail:
	stc

calc_done:
	popad
	ret
CalcMeanDiff	Endp

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
	mov ax,43h
	EnableFocus
	mov ax,dcf_data_sel
	mov ds,ax
;
	GetThread
	mov ds:thread_id,ax
;
	mov al,5
	mov cx,cs
	mov es,cx
	mov di,OFFSET dcf_int
	RequestPrivateIrqHandler
;
    mov dx,284h
    mov al,2
    out dx,al
;
    mov dx,28Bh
    mov al,8Bh
    out dx,al
;
	int 3

	mov ax,dcf_data_sel
	mov es,ax

dcf_sync_loop:
	call ClearSample
	call SyncToDcf
	mov ds:curr_sec,0
;
	mov si,OFFSET save_buf
	mov cx,20

dcf_time_loop:
	call GetDiff
	call SaveDiff
	call ShowDiff
	add si,SIZE save_data_struc
	loop dcf_time_loop
;
	int 3
	call CalcMeanDiff
	jc dcf_sync_loop
;
	mov si,OFFSET save_buf
	call ShowDiff
	int 3

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
	CreateProcess
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
