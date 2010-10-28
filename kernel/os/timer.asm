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
; TIMER.ASM
; PIT interface & emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE protseg.def
INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE system.inc
INCLUDE ..\user.inc
INCLUDE ..\os.inc

timer_lsb	EQU 0
timer_msb	EQU 1

timer_struc	STRUC
timer_state		DB ?
timer_transfer	DB ?
timer_period	DW ?
timer_count		DW ?
timer_resvd		DW ?
timer_time		DD ?,?
timer_struc	ENDS

data    SEGMENT byte public 'DATA'

timer0		timer_struc <>

timer_int_offs	DW ?
timer_int_seg	DW ?
timer_tics_offs	DW ?
timer_tics_seg	DW ?

timer_thread		DW ?

timer_int16_offs	DW ?
timer_int16_sel		DW ?
timer_tics16_offs	DW ?
timer_tics16_sel	DW ?

timer_thread16		DW ?

data    ENDS

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

reload_timer	PROC near
	push edx
	mov ax,[bx].timer_period
	mov [bx].timer_count,ax
	GetSystemTime
	mov [bx+4].timer_time,edx
	mov [bx].timer_time,eax
	pop edx
	ret
reload_timer	ENDP

set_period	PROC near
	cmp [bx].timer_transfer,timer_msb
	je out_msb
	mov byte ptr [bx].timer_period,al
	test [bx].timer_state,20h
	jnz out_msb_next
	call reload_timer
	ret
out_msb_next:
	mov [bx].timer_transfer,timer_msb
	ret
out_msb:
	mov byte ptr [bx].timer_period+1,al
	test [bx].timer_state,10h
	jnz out_lsb_next	
	call reload_timer
	ret
out_lsb_next:
	mov [bx].timer_transfer,timer_lsb
	call reload_timer
	ret
set_period	ENDP

get_period	PROC near
	cmp [bx].timer_transfer,timer_msb
	je in_msb
	mov al,byte ptr [bx].timer_period
	test [bx].timer_state,20h
	jnz in_msb_next
	ret
in_msb_next:
	mov [bx].timer_transfer,timer_msb
	ret
in_msb:
	mov al,byte ptr [bx].timer_period+1
	test [bx].timer_state,10h
	jnz in_lsb_next	
	ret
in_lsb_next:
	mov [bx].timer_transfer,timer_lsb
	ret
get_period	ENDP


in_timer0	PROC far
	mov bx,SEG data
	mov ds,bx
	mov bx,OFFSET timer0
	call get_period
	ret
in_timer0	ENDP

out_timer0	PROC far
	mov bx,SEG data
	mov ds,bx
	mov bx,OFFSET timer0
	call set_period
	ret
out_timer0_not_msb:
	ret
out_timer0	ENDP

in_timer1	PROC far
	in al,41h
	ret
in_timer1	ENDP

out_timer1	PROC far
	ret
out_timer1	ENDP

in_timer2	PROC far
    xor al,al
	ret
in_timer2	ENDP

out_timer2	PROC far
	ret
out_timer2	ENDP

in_speaker_control	PROC far
	in al,61h
	ret
in_speaker_control	Endp

out_speaker_control	Proc far
	ret
out_speaker_control	Endp

in_control	PROC far
	int 3
	ret
in_control	ENDP

out_control	PROC far
	mov bx,SEG data
	mov ds,bx
	mov bl,al
	and bl,0C0h
	shr bl,6
	cmp bl,3
	je out_control_done
	xor bh,bh
	shl bx,4
	mov [bx].timer_state,al
	test al,10h
	jz control_msb
	mov [bx].timer_transfer,timer_lsb
	ret
control_msb:
	mov [bx].timer_transfer,timer_lsb
	ret
out_control_done:
	ret
out_control	ENDP

get_tics0	PROC far
	push bx
	push eax
	push edx
	GetSystemTime
	shr eax,16
	mov bl,al
	pop edx
	pop eax
	mov al,bl
	pop bx
	ret
get_tics0	ENDP

get_tics1	PROC far
	push bx
	push eax
	push edx
	GetSystemTime
	shr eax,24
	mov bl,al
	pop edx
	pop eax
	mov al,bl
	pop bx
	ret
get_tics1	ENDP

get_tics2	PROC far
	push bx
	push eax
	push edx
	GetSystemTime
	mov bl,dl
	pop edx
	pop eax
	mov al,bl
	pop bx
	ret
get_tics2	ENDP

get_tics3	PROC far
	push bx
	push eax
	push edx
	GetSystemTime
	mov bl,dh
	pop edx
	pop eax
	mov al,bl
	pop bx
	ret
get_tics3	ENDP

timer_name	DB 'Timer Emulator',0

timer_pr:
	mov ax,SEG data
	mov ds,ax
	GetThread
	mov ds:timer_thread,ax
	GetSystemTime
	mov ds:timer0.timer_time,eax
	mov ds:timer0.timer_time+4,edx
	mov eax,110h
	AllocateVMLinear
	add edx,10h
	shr edx,4
; gs
	push 0
	push 0F000h
; fs
	push 0
	push 0F000h
; ds
	push 0
	push 0F000h
; es
	push 0
	push 0F000h
; ss
	push edx
; esp
	push 0
	push 0FAh
; eflags
	push 2
	push 200h
; cs
	push 0
	push 0
; eip
	push 0
	push 0
;
	sub sp,4
	push bp
	mov bp,sp
	push eax
	push ebx
	push ds
	sub sp,6
timer_tics_entry:
	SimSti
	mov ax,SEG data
	mov ds,ax
	GetThread
	cmp ax,ds:timer_thread
	je timer_wait_loop
	TerminateThread
timer_wait_loop:
	mov eax,ds:timer0.timer_time
	mov edx,ds:timer0.timer_time+4
	movzx ecx,ds:timer0.timer_period
	mov ds:timer0.timer_count,cx
	add ecx,eax
	mov ds:timer0.timer_time,ecx
	mov ecx,0
	adc ecx,edx
	mov ds:timer0.timer_time+4,ecx
	WaitUntil
;
	mov ax,ds:timer_int_seg
	cmp ax,0E000h
	jz timer_tics
	mov [bp].vm_cs,ax
	mov ax,ds:timer_int_offs
	mov [bp].vm_eip,ax
;
	mov ax,flat_sel
	mov ds,ax
	movzx edx,word ptr [bp].vm_ss
	shl edx,4
	mov word ptr [edx+0FAh],8*4
	mov word ptr [edx+0FCh],0E000h
	mov word ptr [edx+0FEh],200h
	mov word ptr [bp].vm_esp,0FAh
	add sp,6
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4
	iretd
;
timer_int_entry:
	SimSti
	mov ax,SEG data
	mov ds,ax
	GetThread
	cmp ax,ds:timer_thread
	je timer_tics
	TerminateThread
timer_tics:
	mov ax,ds:timer_tics_seg
	cmp ax,0E000h
	jz timer_wait_loop
	mov [bp].vm_cs,ax
	mov ax,ds:timer_tics_offs
	mov [bp].vm_eip,ax
;
	mov ax,flat_sel
	mov ds,ax
	movzx edx,word ptr [bp].vm_ss
	shl edx,4
	mov word ptr [edx+0FAh],1Ch*4
	mov word ptr [edx+0FCh],0E000h
	mov word ptr [edx+0FEh],200h
	mov word ptr [bp].vm_esp,0FAh
	add sp,6
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4
	iretd
;
	jmp timer_tics_entry

check_timer_state	PROC near
	cmp ds:timer_int_seg,0E000h
	jnz check_timer_on
	cmp ds:timer_tics_seg,0E000h
	jnz check_timer_on
check_timer_off:
	mov ds:timer_thread,0
	ret
check_timer_on:
	cmp ds:timer_thread,0
	jz check_timer_start
	ret
check_timer_start:
	dec ds:timer_thread
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET timer_pr
	mov di,OFFSET timer_name
	mov cx,100h
	mov ax,3
	CreateThread
	popa
	pop es
	pop ds
	ret
check_timer_state	ENDP

get_vm_timer	PROC far
	mov bx,SEG data
	mov ds,bx
	mov bx,ds:timer_int_offs
	mov dx,ds:timer_int_seg
	ret
get_vm_timer	ENDP

set_vm_timer	PROC far
	push ax
	mov ax,SEG data
	mov ds,ax
	pop ax
	mov ds:timer_int_offs,bx
	mov ds:timer_int_seg,dx
	call check_timer_state
	ret
set_vm_timer	ENDP

get_vm_timer_tick	PROC far
	mov bx,SEG data
	mov ds,bx
	mov bx,ds:timer_tics_offs
	mov dx,ds:timer_tics_seg
	ret
get_vm_timer_tick	ENDP

set_vm_timer_tick	PROC far
	push ax
	mov ax,SEG data
	mov ds,ax
	pop ax
	mov ds:timer_tics_offs,bx
	mov ds:timer_tics_seg,dx
	call check_timer_state
	ret
set_vm_timer_tick	ENDP

timer16_pr:
	mov ax,SEG data
	mov ds,ax
	GetThread
	mov ds:timer_thread16,ax
	GetSystemTime
	mov ds:timer0.timer_time,eax
	mov ds:timer0.timer_time+4,edx
	mov eax,100h
	AllocateLocalMem
; ss
	push 0
	push es
; esp
	push 0
	push 0FAh
; eflags
	push 0
	push 200h
; cs
	push 0
	push 0
; eip
	push 0
	push 0
;
	sub sp,4
	push bp
	mov bp,sp
	push eax
	push ebx
	push ds
	sub sp,6
timer_tics16_entry:
	mov ax,SEG data
	mov ds,ax
	GetThread
	cmp ax,ds:timer_thread16
	je timer_wait16_loop
	TerminateThread
timer_wait16_loop:
	mov eax,ds:timer0.timer_time
	mov edx,ds:timer0.timer_time+4
	movzx ecx,ds:timer0.timer_period
	mov ds:timer0.timer_count,cx
	add ecx,eax
	mov ds:timer0.timer_time,ecx
	mov ecx,0
	adc ecx,edx
	mov ds:timer0.timer_time+4,ecx
	WaitUntil
;
	mov ax,ds:timer_int16_sel
	cmp ax,callb_int16_sel
	jz timer_tics16
	mov [bp].vm_cs,ax
	mov ax,ds:timer_int16_offs
	mov [bp].vm_eip,ax
;
	mov ds,[bp].vm_ss
	xor bx,bx
	mov word ptr [bx+0FAh],8*4
	mov word ptr [bx+0FCh],callb_int16_sel
	mov word ptr [bx+0FEh],200h
	mov word ptr [bp].vm_esp,0FAh
	add sp,6
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4
	iretd
;
timer_int16_entry:
	mov ax,SEG data
	mov ds,ax
	GetThread
	cmp ax,ds:timer_thread16
	je timer_tics16
	TerminateThread
timer_tics16:
	mov ax,ds:timer_tics16_sel
	cmp ax,callb_int16_sel
	jz timer_wait16_loop
	mov [bp].vm_cs,ax
	mov ax,ds:timer_tics16_offs
	mov [bp].vm_eip,ax
;
	mov ds,[bp].vm_ss
	xor bx,bx
	mov word ptr [bx+0FAh],1Ch*4
	mov word ptr [bx+0FCh],callb_int16_sel
	mov word ptr [bx+0FEh],200h
	mov word ptr [bp].vm_esp,0FAh
	add sp,6
	pop ds
	pop ebx
	pop eax
	pop bp
	add sp,4
	iretd
	jmp timer_tics16_entry

check_timer16_state	PROC near
	cmp ds:timer_int16_sel,callb_int16_sel
	jnz check_timer16_on
	cmp ds:timer_tics16_sel,callb_int16_sel
	jnz check_timer16_on
check_timer16_off:
	mov ds:timer_thread16,0
	ret
check_timer16_on:
	cmp ds:timer_thread16,0
	jz check_timer16_start
	ret
check_timer16_start:
	dec ds:timer_thread16
	push ds
	push es
	pusha
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET timer16_pr
	mov di,OFFSET timer_name
	mov cx,100h
	mov ax,3
	CreateThread
	popa
	pop es
	pop ds
	ret
check_timer16_state	ENDP

get_pm_timer	PROC far
	mov bx,SEG data
	mov ds,bx
	mov bx,ds:timer_int16_offs
	mov dx,ds:timer_int16_sel
	ret
get_pm_timer	ENDP

set_pm_timer	PROC far
	push ax
	mov ax,SEG data
	mov ds,ax
	pop ax
	mov ds:timer_int16_offs,bx
	mov ds:timer_int16_sel,dx
	call check_timer16_state
	ret
set_pm_timer	ENDP

get_pm_timer_tick	PROC far
	mov bx,SEG data
	mov ds,bx
	mov di,ds:timer_tics16_offs
	mov es,ds:timer_tics16_sel
	ret
get_pm_timer_tick	ENDP

set_pm_timer_tick	PROC far
	push ax
	mov ax,SEG data
	mov ds,ax
	pop ax
	mov ds:timer_tics16_offs,di
	mov ds:timer_tics16_sel,es
	call check_timer16_state
	ret
set_pm_timer_tick	ENDP

init_timer_process	PROC far
	mov ax,SEG data
	mov ds,ax
	GetSystemTime
	mov ds:timer0.timer_state,36h
	mov ds:timer0.timer_transfer,timer_lsb
	mov ds:timer0.timer_period,0FFFFh
	mov ds:timer0.timer_count,0FFFFh
	mov ds:timer0.timer_time,eax
	mov ds:timer0.timer_time+4,edx
	mov ds:timer_int_seg,0E000h
	mov ds:timer_int_offs,8*4
	mov ds:timer_tics_seg,0E000h
	mov ds:timer_tics_offs,1Ch*4
	mov ds:timer_thread,0
	mov ds:timer_int16_sel,callb_int16_sel
	mov ds:timer_int16_offs,8*4
	mov ds:timer_tics16_sel,callb_int16_sel
	mov ds:timer_tics16_offs,1Ch*4
	mov ds:timer_thread16,0
	ret
init_timer_process	ENDP

    public init_timer

init_timer	PROC near
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov di,OFFSET init_timer_process
	HookCreateProcess
;
	mov di,OFFSET in_timer0
	mov dx,40h
	HookIn
;
	mov di,OFFSET out_timer0
	mov dx,40h
	HookOut
;
	mov di,OFFSET in_timer1
	mov dx,41h
	HookIn
;
	mov di,OFFSET out_timer1
	mov dx,41h
	HookOut
;
	mov di,OFFSET in_timer2
	mov dx,42h
	HookIn
;
	mov di,OFFSET out_timer2
	mov dx,42h
	HookOut
;
	mov di,OFFSET in_control
	mov dx,43h
	HookIn
;
	mov di,OFFSET out_control
	mov dx,43h
	HookOut
;
	mov di,OFFSET in_speaker_control
	mov dx,61h
	HookIn
;
	mov di,OFFSET out_speaker_control
	mov dx,61h
	HookOut
;
	mov di,OFFSET get_vm_timer
	mov al,8
	HookGetVMInt
;
	mov di,OFFSET set_vm_timer
	mov al,8
	HookSetVMInt
;
	mov di,OFFSET get_vm_timer_tick
	mov al,1Ch
	HookGetVMInt
;
	mov di,OFFSET set_vm_timer_tick
	mov al,1Ch
	HookSetVMInt
;
	mov di,OFFSET get_pm_timer
	mov al,8
	HookGetProt16Int
;
	mov di,OFFSET set_pm_timer
	mov al,8
	HookSetProt16Int
;
	mov di,OFFSET get_pm_timer_tick
	mov al,1Ch
	HookGetProt16Int
;
	mov di,OFFSET set_pm_timer_tick
	mov al,1Ch
	HookSetProt16Int
;
	mov di,OFFSET get_tics0
	mov bx,6Ch
	HookGetBiosData
;
	mov di,OFFSET get_tics1
	mov bx,6Dh
	HookGetBiosData
;
	mov di,OFFSET get_tics2
	mov bx,6Eh
	HookGetBiosData
;
	mov di,OFFSET get_tics3
	mov bx,6Fh
	HookGetBiosData
;
	mov ax,cs
	mov ds,ax
;
	mov di,OFFSET timer_int_entry
	mov al,8
	HookVMInt
;
	mov di,OFFSET timer_tics_entry
	mov al,1Ch
	HookVMInt
;
	mov di,OFFSET timer_int16_entry
	mov al,8
	HookProt16Int
;
	mov di,OFFSET timer_tics16_entry
	mov al,1Ch
	HookProt16Int
	ret
init_timer	ENDP

code	ENDS

	END
