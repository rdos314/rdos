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
; RTC.ASM
; RTC chip interface & emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME rtc

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\protseg.def
INCLUDE ..\driver.def
INCLUDE ..\os\port.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

rtc_init	EQU 0
rtc_sync	EQU 1
rtc_ready	EQU 2

data    SEGMENT byte public 'DATA'

cmos_tics_base	DD ?,?

data    ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RTC_INT
;
;		DESCRIPTION:	RTC INTERRUPT
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rtc_int:
	push ds
	push es
	pushad
;
	mov al,20h
	out INT0_CONTROL,al
;
    mov bx,system_data_sel
    mov ds,bx
;
	out INT1_CONTROL,al
;
    mov al,0Ch
    out 70h,al
	jmp short $+2
;
    in al,71h	
    test al,40h
    jz rtc_int_done
;        
    mov eax,ds:last_time
    or eax,ds:last_time+4
    jz rtc_int_first

rtc_int_update:
    GetSystemTime
    mov ecx,ds:last_time
    mov ds:last_time,eax
    mov ds:last_time+4,edx
    sub eax,ecx
    sub eax,1193182 / 2
    mov ds:time_drift,eax
    NotifyTimeDrift
    jmp rtc_int_done

rtc_int_first:    
    GetSystemTime
    mov ds:last_time,eax
    mov ds:last_time+4,edx

rtc_int_done:
	popad
	pop es
	pop ds
	iretd

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			setup_int
;
;		DESCRIPTION:	Set up 2Hz interrupt for system time survailance
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_int	PROC near
    mov bx,system_data_sel
	mov ds,bx
    mov ds:last_time,0
    mov ds:last_time+4,0
    mov ds:time_drift,0
;    
	mov ax,cs
	mov ds,ax
	mov al,38h
	mov bl,0
	mov esi,OFFSET rtc_int 
	CreateIntGateSelector
;	
	cli
;
    mov al,0Ch
    out 70h,al
	jmp short $+2
;
    in al,71h	
	jmp short $+2
;
	mov al,0Ah
	out 70h,al
	jmp short $+2
;	
    in al,71h
    mov ah,al
	jmp short $+2
;    
	mov al,0Ah
	out 70h,al
	jmp short $+2
;
    mov al,ah
    or al,0Fh
    out 71h,al    
	jmp short $+2
;
	mov al,0Bh
	out 70h,al
	jmp short $+2
;
    in al,71h
    mov ah,al
	jmp short $+2
;    
	mov al,0Bh
	out 70h,al
	jmp short $+2
;
    mov al,ah
    or al,40h
    out 71h,al
    sti
    ret
setup_int   Endp
    
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			get_cmos_time
;
;		DESCRIPTION:	Get RTC time
;
;		RETURNS:		DX		YEAR
;						CH		MONTH
;						CL		DAY
;						BH		HOUR
;						BL		MINUTE
;						AH		SECONDS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_cmos_time	PROC near
	cli
get_cmos_wait_update:
	mov al,0Ah
	out 70h,al
	jmp short $+2
	in al,71h
	test al,80h
	jz get_cmos_wait_update

get_cmos_wait_idle:
	mov al,0Ah
	out 70h,al
	jmp short $+2
	in al,71h
	test al,80h
	jnz get_cmos_wait_idle
;	
	mov al,0
	out 70h,al
	jmp short $+2
	in al,71h
	mov ah,al
	mov al,2
	out 70h,al
	jmp short $+2
	in al,71h
	mov bl,al
	mov al,4
	out 70h,al
	jmp short $+2
	in al,71h
	mov bh,al
	mov al,7
	out 70h,al
	jmp short $+2
	in al,71h
	mov cl,al
	mov al,8
	out 70h,al
	jmp short $+2
	in al,71h
	mov ch,al
	mov al,9
	out 70h,al
	jmp short $+2
	in al,71h
	mov dl,al
	sti
get_time_decode:
	mov al,ah
	and ah,0Fh
	and al,0F0h
	shr al,1
	add ah,al
	shr al,2
	add ah,al
;	
	mov al,bl
	and bl,0Fh
	and al,0F0h
	shr al,1
	add bl,al
	shr al,2
	add bl,al
;	
	mov al,bh
	and bh,0Fh
	and al,0F0h
	shr al,1
	add bh,al
	shr al,2
	add bh,al
;	
	mov al,cl
	and cl,0Fh
	and al,0F0h
	shr al,1
	add cl,al
	shr al,2
	add cl,al
;	
	mov al,ch
	and ch,0Fh
	and al,0F0h
	shr al,1
	add ch,al
	shr al,2
	add ch,al
;
	xor dh,dh
	mov al,dl
	and dl,0Fh
	and al,0F0h
	shr al,1
	add dl,al
	shr al,2
	add dl,al
	cmp dl,80
	jc get_time_2000
	add dx,1900
	jmp get_time_end
get_time_2000:
	add dx,2000
get_time_end:
	ret
get_cmos_time ENDP

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			set_cmos_time
;
;		DESCRIPTION:	Set RTC time
;
;		PARAMETERS:		DX		YEAR
;						CH		MONTH
;						CL		DAY
;						BH		HOUR
;						BL		MINUTE
;						AH		SECONDS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

set_cmos_time	PROC near
	sub dx,1900
	cmp dx,100
	jc set_cmos_year_ok
	sub dx,100
set_cmos_year_ok:
	mov dh,10
	mov al,ah
	xor ah,ah
	div dh
	shl al,4
	add ah,al
	push ax
;
	mov al,bl
	xor ah,ah
	div dh
	shl al,4
	add al,ah
	mov bl,al
;	
	mov al,bh
	xor ah,ah
	div dh
	shl al,4
	add al,ah
	mov bh,al
;
	mov al,cl
	xor ah,ah
	div dh
	shl al,4
	add al,ah
	mov cl,al
;	
	mov al,ch
	xor ah,ah
	div dh
	shl al,4
	add al,ah
	mov ch,al
;
	mov al,dl
	xor ah,ah
	div dh
	shl al,4
	add al,ah
	mov dl,al
;
	pop ax
	cli
;
	mov al,0Bh
	out 70h,al
	jmp short $+2
	mov al,82h
	out 71h,al
	jmp short $+2
;
	mov al,0
	out 70h,al
	jmp short $+2
	mov al,ah
	out 71h,al
	jmp short $+2
;
	mov al,2
	out 70h,al
	jmp short $+2
	mov al,bl
	out 71h,al
	jmp short $+2
;
	mov al,4
	out 70h,al
	jmp short $+2
	mov al,bh
	out 71h,al
	jmp short $+2
;
	mov al,7
	out 70h,al
	jmp short $+2
	mov al,cl
	out 71h,al
	jmp short $+2
;
	mov al,8
	out 70h,al
	jmp short $+2
	mov al,ch
	out 71h,al
	jmp short $+2
;
	mov al,9
	out 70h,al
	jmp short $+2
	mov al,dl
	out 71h,al
	jmp short $+2
;
	mov al,0Bh
	out 70h,al
	jmp short $+2
	mov al,2
	out 71h,al
	jmp short $+2
;
	sti
	ret
set_cmos_time ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			UpdateRtc
;
;		DESCRIPTION:	Update RTC clock
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

update_rtc_name	DB 'Update RTC',0

update_rtc	Proc far
	push eax
	push edx
;
	GetTime
	add eax,1200000
	adc edx,0
	BinaryToTime
	push dx
	push cx
	push bx
	push ax
	TimeToBinary
	TimeToSystemTime
	WaitUntil
	pop ax
	pop bx
	pop cx
	pop dx
	call set_cmos_time
	call get_cmos_time
;
	pop edx
	pop eax
	retf32
update_rtc	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			cmos_io
;
;		DESCRIPTION:	BIOS function 1A
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

pci_access	PROC near
	BiosPciInt
	ret
pci_access	ENDP

cmos_error	PROC near
	ret
cmos_error	ENDP

cmos_read_tics	PROC near
	push edx
	push eax
	GetTime
	sub eax,ds:cmos_tics_base
	sbb edx,ds:cmos_tics_base+4
	shr eax,16
	mov bx,ax
	pop eax
	mov cx,dx
	test edx,0FFFF0000h
	pop edx
	mov dx,bx
	mov al,0
	jz cmos_read_tics_done
	mov al,1
cmos_read_tics_done:
	ret
cmos_read_tics	ENDP

cmos_set_tics	PROC near
	push eax
	push ebx
	push edx
	GetTime
	mov ebx,edx
	pop edx
	mov ds:cmos_tics_base,eax
	shr eax,16
	add ax,dx
	adc ebx,0
	mov word ptr ds:cmos_tics_base+2,ax
	movzx eax,cx
	add eax,ebx
	mov ds:cmos_tics_base+4,eax
	pop ebx
	pop eax
	ret
cmos_set_tics	ENDP

cmos_read_time	PROC near
	push eax
	push edx
	GetTime
	BinaryToTime
	pop edx
	xor dl,dl
	mov al,ah
	xor ah,ah
cmos_sec_loop:
	cmp al,10
	jc cmos_sec_ok
	inc ah
	sub al,10
	jmp cmos_sec_loop
cmos_sec_ok:
	shl ah,4
	or al,ah
	mov dh,al
;
	mov al,bl
	xor ah,ah
cmos_min_loop:
	cmp al,10
	jc cmos_min_ok
	inc ah
	sub al,10
	jmp cmos_min_loop
cmos_min_ok:
	shl ah,4
	or al,ah
	mov cl,al
;
	mov al,bh
	xor ah,ah
cmos_hour_loop:
	cmp al,10
	jc cmos_hour_ok
	inc ah
	sub al,10
	jmp cmos_hour_loop
cmos_hour_ok:
	shl ah,4
	or al,ah
	mov ch,al
	pop eax
	ret
cmos_read_time	ENDP

cmos_read_date	PROC near
	push eax
	push edx
	GetTime
	BinaryToTime
	mov bx,dx
	pop edx
	mov al,ch
	xor ah,ah
cmos_month_loop:
	cmp al,10
	jc cmos_month_ok
	inc ah
	sub al,10
	jmp cmos_month_loop
cmos_month_ok:
	shl ah,4
	or al,ah
	mov dh,al
;
	mov al,cl
	xor ah,ah
cmos_day_loop:
	cmp al,10
	jc cmos_day_ok
	inc ah
	sub al,10
	jmp cmos_day_loop
cmos_day_ok:
	shl ah,4
	or al,ah
	mov dl,al
;
	mov ch,19h
	mov ax,bx
	sub ax,1900
	cmp ax,100
	jc cmos_year_decode
	mov ch,20h
	sub ax,100
cmos_year_decode:
	xor ah,ah
cmos_year_loop:
	cmp al,10
	jc cmos_year_ok
	inc ah
	sub al,10
	jmp cmos_year_loop
cmos_year_ok:
	shl ah,4
	or al,ah
	mov cl,al	
	pop eax
	ret
cmos_read_date	ENDP

cmos_io_tab:
cio00	DW OFFSET cmos_read_tics
cio01	DW OFFSET cmos_set_tics
cio02	DW OFFSET cmos_read_time
cio03	DW OFFSET cmos_error
cio04	DW OFFSET cmos_read_date
cio05	DW OFFSET cmos_error

rtc_io Proc far
	SimSti
	sti
	push ds
	mov bx,SEG data
	mov ds,bx
	mov bl,ah
	xor bh,bh
	cmp bx,5
	jc cmos_io_do
;
	cmp bl,0B1h
	jne cmos_io_done
	call pci_access
	jmp cmos_io_done
cmos_io_do:
	add bx,bx
	call word ptr cs:[bx].cmos_io_tab
cmos_io_done:
	mov bx,[bp].vm_ebx
	pop ds
	ret
rtc_io	ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			init
;
;		DESCRIPTION:	INIT RTC DEVICE
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init	Proc far
	mov ax,cs
	mov ds,ax
	mov es,ax
;
	mov si,OFFSET update_rtc
	mov di,OFFSET update_rtc_name
    xor dx,dx
	mov ax,update_rtc_nr
    RegisterBimodalUserGate
;
	mov al,1Ah
	mov di,OFFSET rtc_io
	HookVMInt
;
	call get_cmos_time
	TimeToBinary
	SetSystemTime
	call setup_int
	clc
	ret
init	Endp

code	ENDS

	END init
