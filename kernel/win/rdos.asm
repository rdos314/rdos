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
; RDOS.ASM
; RDOS API interface for 16-bit windoze
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

include \rdos\kernel\user.def
include \rdos\kernel\user.inc

		NAME rdos

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TASK_END
;
;		description:	Termination of task
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

task_end:
	UserGate terminate_thread_nr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TASK_START
;
;		description:	Task startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

task_start:
    movzx ebp,bp
	mov ds,bp
	push fs
	push bx
	push cs
	push OFFSET task_end
	push gs
	push dx
	xor ax,ax
	mov fs,ax
	mov gs,ax
	retf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateThread
;
;		description:	Create a new thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateThread

task_callb	EQU 6
task_name	EQU 10
task_data	EQU 14
task_stack	EQU 18

_RdosCreateThread	PROC far
	push bp
	mov bp,sp
	push ds
	push es
	push fs
	push gs
	push si
	push di
	push ds
	lfs bx,[bp].task_data
	lgs dx,[bp].task_callb
	mov ax,cs
	mov ds,ax
	mov si,OFFSET task_start
	mov cx,[bp].task_stack
	les di,[bp].task_name
	pop bp
	mov ax,2
	CreateThread
	pop di
	pop si
	pop gs
	pop fs
	pop es
	pop ds
	pop bp
	ret
_RdosCreateThread	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetThreadHandle
;
;		description:	Get current thread handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetThreadHandle

_RdosGetThreadHandle	PROC far
	GetThread
	ret
_RdosGetThreadHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosExec
;
;		description:	Execute a program
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosExec

_RdosExec	PROC far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
;
	lds si,[bp+6]
	les di,[bp+10]
	LoadExe
	GetExitCode
;
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret
_RdosExec	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCpuReset
;
;		description:	void RdosCpuReset()
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCpuReset

_RdosCpuReset	Proc far
	CpuReset
	ret
_RdosCpuReset	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetVersion
;
;		description:	void RdosGetVersion(*major,*minor, *relase)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetVersion

_RdosGetVersion	Proc far
	push bp
	mov bp,sp
	push es
    push di
    push ax
    push cx
    push dx
;
	GetVersion
	les di,[bp+6]
	mov es:[di],dx
;
    les di,[bp+10]
    mov es:[di],ax
;
    les di,[bp+14]
    mov es:[di],cx
;	
    pop dx
    pop cx
    pop ax
    pop di
    pop es
	pop bp
	ret
_RdosGetVersion	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAllocateMem
;
;		description:	void *RdosAllocateMem(size)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAllocateMem

_RdosAllocateMem	Proc far
	push bp
	mov bp,sp
	push es
	movzx eax,word ptr [bp+6]
	AllocateLocalMem
	mov dx,es
	xor ax,ax
	pop es
	pop bp
	ret
_RdosAllocateMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosFreeMem
;
;		description:	void RdosFreeMem(ptr)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosFreeMem

_RdosFreeMem	Proc far
	push bp
	mov bp,sp
	mov es,[bp+8]
	FreeMem
	pop bp
	ret
_RdosFreeMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetMemSize
;
;		description:	int GetMemSize(ptr)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _GetMemSize

_GetMemSize	Proc far
	push bp
	mov bp,sp
	lsl ax,[bp+8]
	pop bp
	ret
_GetMemSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitMilli
;
;		description:	Wait a number of milliseconds
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWaitMilli

_RdosWaitMilli	Proc far
	push bp
	mov bp,sp
	mov eax,[bp+6]
	WaitMilliSec
	pop bp
	ret
_RdosWaitMilli	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateSection
;
;		description:	Create section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateSection

_RdosCreateSection	Proc far
	push bx
	CreateUserSection
	movzx eax,bx
	pop bx
	ret
_RdosCreateSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDeleteSection
;
;		description:	Delete section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDeleteSection

_RdosDeleteSection	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	DeleteUserSection
;
	pop bx
	pop bp
	ret
_RdosDeleteSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			_RdosEnterSection
;
;		description:	Enter section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosEnterSection

_RdosEnterSection	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	EnterUserSection
;
	pop bx
	pop bp
	ret
_RdosEnterSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosLeaveSection
;
;		description:	Leave section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosLeaveSection

_RdosLeaveSection	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	LeaveUserSection
;
	pop bx
	pop bp
	ret
_RdosLeaveSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateWait
;
;		description:	int RdosCreateWait()
;
;       returns:        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateWait

_RdosCreateWait	Proc far
	push bx
;
	CreateWait
	mov ax,bx
;
	pop bx
	ret
_RdosCreateWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseWait
;
;		description:	void RdosCloseWait(int Handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCloseWait

_RdosCloseWait	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseWait
;
	pop bx
	pop bp
	ret
_RdosCloseWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCheckWait
;
;		description:	void *RdosCheckWait(int Handle)
;
;       returns:        Signalled ID or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCheckWait

_RdosCheckWait	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	mov bx,[bp+6]
	IsWaitIdle
;
    mov ax,cx
    shr ecx,16
    mov dx,cx
;
    pop cx
	pop bx
	pop bp
	ret
_RdosCheckWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitForever
;
;		description:	int RdosWaitForever(int Handle)
;
;       returns:        Signalled ID or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWaitForever

_RdosWaitForever	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	mov bx,[bp+6]
	WaitWithoutTimeout
	jc rwfFail
;
    mov ax,cx
    shr ecx,16
    mov dx,cx
    jmp rwfDone

rwfFail:
    xor ax,ax
    xor dx,dx

rwfDone:
    pop cx
	pop bx
	pop bp
	ret
_RdosWaitForever	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitTimeout
;
;		description:	int RdosWaitTimeout(int Handle, int MilliTimeout) 
;
;       returns:        Signalled ID or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWaitTimeout

_RdosWaitTimeout	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	movzx eax,word ptr [bp+8]
	mov edx,1193
	mul edx
	push edx
	push eax
	GetSystemTime
    pop ebx
    add eax,ebx
    pop ebx
    adc edx,ebx
	mov bx,[bp+6]    	
    WaitWithTimeout
	jc rwtFail
;
    mov ax,cx
    shr ecx,16
    mov dx,cx
    jmp rwtDone

rwtFail:
    xor ax,ax
    xor dx,dx

rwtDone:
    pop cx
	pop bx
	pop bp
	ret
_RdosWaitTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosStopWait
;
;		description:	void RdosStopWait(int Handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosStopWait

_RdosStopWait	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	StopWait
;
	pop bx
	pop bp
	ret
_RdosStopWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosRemoveWait
;
;		description:	void RdosRemoveWait(int Handle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosRemoveWait

_RdosRemoveWait	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	mov bx,[bp+6]
	mov ecx,[bp+8]
	RemoveWait
;
    pop cx
	pop bx
	pop bp
	ret
_RdosRemoveWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForKeyboard
;
;		description:	void RdosAddWaitForKeyboard(int Handle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddWaitForKeyboard

_RdosAddWaitForKeyboard	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	mov bx,[bp+6]
	mov ecx,[bp+8]
	AddWaitForKeyboard
;
    pop cx
	pop bx
	pop bp
	ret
_RdosAddWaitForKeyboard	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForMouse
;
;		description:	void RdosAddWaitForMouse(int Handle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddWaitForMouse

_RdosAddWaitForMouse	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	mov bx,[bp+6]
	mov ecx,[bp+8]
	AddWaitForMouse
;
    pop cx
	pop bx
	pop bp
	ret
_RdosAddWaitForMouse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForCom
;
;		description:	void RdosAddWaitForCom(int Handle, int ComHandle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddWaitForCom

_RdosAddWaitForCom	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	mov bx,[bp+6]
	mov ax,[bp+8]
	mov ecx,[bp+10]
	AddWaitForCom
;
    pop cx
	pop bx
	pop bp
	ret
_RdosAddWaitForCom	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForAdc
;
;		description:	void RdosAddWaitForAdc(int Handle, int AdcHandle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddWaitForAdc

_RdosAddWaitForAdc	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	mov bx,[bp+6]
	mov ax,[bp+8]
	mov ecx,[bp+10]
	AddWaitForAdc
;
    pop cx
	pop bx
	pop bp
	ret
_RdosAddWaitForAdc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SwapOut
;
;		description:	Swap out. Obsolete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _SwapOut

_SwapOut	Proc far
	Swap
	ret
_SwapOut	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetTextMode
;
;		description:	int RdosSetTextMode();
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetTextMode

_RdosSetTextMode	Proc far
	pusha
	mov ax,3
    SetVideoMode
	popa
	ret
_RdosSetTextMode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetVideoMode
;
;		description:	int RdosSetVideoMode(int *BitsPerPixel, 
;						int *xres, int *yres, int *linesize, void **buffer);
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetVideoMode

_RdosSetVideoMode	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push cx
	push dx
	push si
	push di
;
	les di,[bp+6]
	mov ax,es:[di]
	les di,[bp+10]
	mov cx,es:[di]
	les di,[bp+14]
	mov dx,es:[di]	
	GetVideoMode
	jc set_video_fail
;
    SetVideoMode
    jc set_video_fail
;
	push di
	les di,[bp+6]
	mov es:[di],ax
	les di,[bp+10]
	mov es:[di],cx
	les di,[bp+14]
	mov es:[di],dx
	les di,[bp+18]
	mov es:[di],si
	les di,[bp+22]
	pop ax
	mov es:[di],ax
	mov ax,bx
	jmp set_video_done

set_video_fail:
	xor ax,ax
	les di,[bp+6]
	mov es:[di],ax
	les di,[bp+10]
	mov es:[di],ax
	les di,[bp+14]
	mov es:[di],ax
	les di,[bp+18]
	mov es:[di],ax
	les di,[bp+22]
	mov es:[di],ax

set_video_done:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop es
	pop bp
	ret
_RdosSetVideoMode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetClipRect
;
;		description:	RdosSetClipRect(handle, xmin, xmax, ymin, ymax)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetClipRect

_RdosSetClipRect	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
	push si
	push di
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	mov si,[bp+12]
	mov di,[bp+14]
    SetClipRect
;
    pop di
    pop si
    pop dx
    pop cx
	pop bx
	pop bp
	ret
_RdosSetClipRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosClearClipRect
;
;		description:	RdosClearClipRect(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosClearClipRect

_RdosClearClipRect	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	ClearClipRect
;
	pop bx
	pop bp
	ret
_RdosClearClipRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetDrawColor
;
;		description:	RdosSetDrawColor(handle, color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetDrawColor

_RdosSetDrawColor	Proc far
	push bp
	mov bp,sp
	push ax
	push bx
;
	mov bx,[bp+6]
	mov eax,[bp+8]
	SetDrawColor
;
	pop bx
	pop ax
	pop bp
	ret
_RdosSetDrawColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetLGOP
;
;		description:	RdosSetLGOP(handle, lgop)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetLGOP

_RdosSetLGOP	Proc far
	push bp
	mov bp,sp
	push ax
	push bx
;
	mov bx,[bp+6]
	mov ax,[bp+8]
	SetLgop
;
	pop bx
	pop ax
	pop bp
	ret
_RdosSetLGOP	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetHollowStyle
;
;		description:	RdosSetHollowStyle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetHollowStyle

_RdosSetHollowStyle	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	SetHollowStyle
;
	pop bx
	pop bp
	ret
_RdosSetHollowStyle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetFilledStyle
;
;		description:	RdosSetFilledStyle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetFilledStyle

_RdosSetFilledStyle	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	SetFilledStyle
;
	pop bx
	pop bp
	ret
_RdosSetFilledStyle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosOpenFont
;
;		description:	RdosOpenFont(height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosOpenFont

_RdosOpenFont	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov ax,[bp+6]
	OpenFont
	mov ax,bx
;
	pop bx
	pop bp
	ret
_RdosOpenFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseFont
;
;		description:	RdosCloseFont(font)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCloseFont

_RdosCloseFont	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseFont
;
	pop bx
	pop bp
	ret
_RdosCloseFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetStringMetrics
;
;		description:	RdosGetStringMetrics(font, str, &width, &height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetStringMetrics

_RdosGetStringMetrics	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push cx
	push dx
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	GetStringMetrics
;
	les di,[bp+12]
	mov es:[di],cx
	les di,[bp+16]
	mov es:[di],dx
;
	pop di
	pop dx
	pop cx
	pop bx
	pop es
	pop bp
	ret
_RdosGetStringMetrics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetFont
;
;		description:	RdosSetFont(handle, font)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetFont

_RdosSetFont	Proc far
	push bp
	mov bp,sp
	push ax
	push bx
;
	mov bx,[bp+6]
	mov ax,[bp+8]
	SetFont
;
	pop bx
	pop ax
	pop bp
	ret
_RdosSetFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetPixel
;
;		description:	RdosGetPixel(handle, x, y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetPixel

_RdosGetPixel	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	GetPixel
;
    push eax
    pop ax
    pop dx
;
	pop cx
	pop bx
	pop bp
	ret
_RdosGetPixel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			_RdosSetPixel
;
;		description:	RdosSetPixel(handle, x, y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetPixel

_RdosSetPixel	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	SetPixel
;
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_RdosSetPixel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosBlit
;
;		description:	RdosBlit(SrcHandle, DestHandle, width, height,
;								 SrcX, SrcY, DestX, DestY);
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosBlit

_RdosBlit	Proc far
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov ax,[bp+6]
	mov bx,[bp+8]
	mov cx,[bp+10]
	mov dx,[bp+12]
	mov si,[bp+14]
	shl esi,16
	mov si,[bp+16]
	mov di,[bp+18]
	shl edi,16
	mov di,[bp+20]
	Blit
;
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
_RdosBlit	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawMask
;
;		description:	RdosDrawMask(handle, mask, RowSize, width, height,
;					 				 SrcX, SrcY, DestX, DestY); 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDrawMask

_RdosDrawMask	Proc far
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov bx,[bp+6]
	mov edi,[bp+8]
	mov ax,[bp+12]
	mov si,[bp+14]
	shl esi,16
	mov si,[bp+16]
	mov cx,[bp+18]
	shl ecx,16
	mov cx,[bp+20]
	mov dx,[bp+22]
	shl edx,16
	mov dx,[bp+24]
	Blit
;
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
_RdosDrawMask	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawLine
;
;		description:	RdosDrawLine(handle, x1, y1, x2, y2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDrawLine

_RdosDrawLine	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
	push si
	push di
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	mov si,[bp+12]
	mov di,[bp+14]
	DrawLine
;
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_RdosDrawLine	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawString
;
;		description:	RdosDrawString(handle, x, y, str)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDrawString

_RdosDrawString	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push cx
	push dx
	push di
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	mov edi,[bp+12]
	DrawString
;
	pop di
	pop dx
	pop cx
	pop bx
	pop es
	pop bp
	ret
_RdosDrawString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawRect
;
;		description:	RdosDrawRect(handle, x, y, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDrawRect

_RdosDrawRect	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
	push si
	push di
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	mov si,[bp+12]
	mov di,[bp+14]
	DrawRect
;
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_RdosDrawRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawEllipse
;
;		description:	RdosDrawEllipse(handle, x, y, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDrawEllipse

_RdosDrawEllipse	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
	push si
	push di
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	mov si,[bp+12]
	mov di,[bp+14]
    DrawEllipse
;
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_RdosDrawEllipse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateBitmap
;
;		description:	RdosCreateBitmap(BitsPerPixel, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateBitmap

_RdosCreateBitmap	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
;
	mov ax,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	CreateBitmap
	mov ax,bx
;
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_RdosCreateBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDuplicateBitmapHandle
;
;		description:	RdosDuplicateBitmapHandle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDuplicateBitmapHandle

_RdosDuplicateBitmapHandle	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	DuplicateBitmapHandle
	mov ax,bx
;
	pop bx
	pop bp
	ret
_RdosDuplicateBitmapHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseBitmap
;
;		description:	RdosCloseBitmap(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCloseBitmap

_RdosCloseBitmap	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseBitmap
;
	pop bx
	pop bp
	ret
_RdosCloseBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateStringBitmap
;
;		description:	RdosCreateStringBitmap(font, str)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateStringBitmap

_RdosCreateStringBitmap	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	CreateStringBitmap
	mov ax,bx
;
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosCreateStringBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetBitmapInfo
;
;		description:	RdosGetBitmapInfo(handle, &BitsPerPixel, &width, &height,
;					   						&linesize, &buffer)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetBitmapInfo

_RdosGetBitmapInfo	Proc far
	push bp
	mov bp,sp
	push es
	push ax
	push bx
	push cx
	push dx
	push si
	push di
;
	mov bx,[bp+6]
	GetBitmapInfo
	jc gbiFail
;
	push di
	les di,[bp+8]
	movzx ax,al
	mov es:[di],ax
	les di,[bp+12]
	mov es:[di],cx
	les di,[bp+16]
	mov es:[di],dx
	les di,[bp+20]
	mov es:[di],si
	les di,[bp+24]
	pop ax
	mov es:[di],ax
	jmp gbiDone

gbiFail:
	xor ax,ax
	les di,[bp+8]
	mov es:[di],ax
	les di,[bp+12]
	mov es:[di],ax
	les di,[bp+16]
	mov es:[di],ax
	les di,[bp+20]
	mov es:[di],ax
	les di,[bp+24]
	mov es:[di],ax

gbiDone:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	pop bp
	ret
_RdosGetBitmapInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateSprite
;
;		description:	RdosCreateSprite(dest, bitmap, mask, lgop)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateSprite

_RdosCreateSprite	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	mov ax,[bp+12]
	CreateSprite
	mov ax,bx
;
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_RdosCreateSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseSprite
;
;		description:	RdosCloseSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCloseSprite

_RdosCloseSprite	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseSprite
;
	pop bx
	pop bp
	ret
_RdosCloseSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosShowSprite
;
;		description:	RdosShowSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosShowSprite

_RdosShowSprite	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	ShowSprite
;
	pop bx
	pop bp
	ret
_RdosShowSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosHideSprite
;
;		description:	RdosHideSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosHideSprite

_RdosHideSprite	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	HideSprite
;
	pop bx
	pop bp
	ret
_RdosHideSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosMoveSprite
;
;		description:	RdosMoveSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosMoveSprite

_RdosMoveSprite	Proc far
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
;
	mov bx,[bp+6]
	mov cx,[bp+8]
	mov dx,[bp+10]
	MoveSprite
;
	pop dx
	pop cx
	pop bx
	pop bp
	ret
_RdosMoveSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetForeColor
;
;		description:	SetForeColor(color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _SetForeColor

_SetForeColor	Proc far
	push bp
	mov bp,sp
	mov al,[bp+6]
	SetForeColor
	pop bp
	ret
_SetForeColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetBackColor
;
;		description:	SetBackColor(color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _SetBackColor

_SetBackColor	Proc far
	push bp
	mov bp,sp
	mov al,[bp+6]
	SetBackColor
	pop bp
	ret
_SetBackColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetSysTime
;
;		description:	gets system time in record form
;
;		PARAMETERS:		int *year
;						int *month
;						int *day
;						int *hour
;						int *min
;						int *sec
;						int *milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetSysTime

gtrtYear	EQU 6
gtrtMonth	EQU 10
gtrtDay		EQU 14
gtrtHour	EQU 18
gtrtMin		EQU 22
gtrtSec		EQU 26
gtrtMilli	EQU 30

_RdosGetSysTime	Proc far
	push bp
	mov bp,sp
	push ds
	push si
;
	GetSystemTime
	push eax
	BinaryToTime
;
	lds si,[bp].gtrtYear
	mov [si],dx
	lds si,[bp].gtrtMonth
	mov [si],ch
	mov byte ptr [si+1],0
	lds si,[bp].gtrtDay
	mov [si],cl
	mov byte ptr [si+1],0
	lds si,[bp].gtrtHour
	mov [si],bh
	mov byte ptr [si+1],0
	lds si,[bp].gtrtMin
	mov [si],bl
	mov byte ptr [si+1],0
	lds si,[bp].gtrtSec
	mov [si],ah
	mov byte ptr [si+1],0
;
	TimeToBinary
	mov ebx,eax
	pop eax
	sub eax,ebx
	xor edx,edx
	mov ebx,1192
	div ebx
	lds si,[bp].gtrtMilli
	mov [si],ax
;
	pop si
	pop ds
	pop bp
	ret
_RdosGetSysTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetTime
;
;		description:	gets time in record form
;
;		PARAMETERS:		int *year
;						int *month
;						int *day
;						int *hour
;						int *min
;						int *sec
;						int *milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetTime

grtYear	EQU 6
grtMonth	EQU 10
grtDay		EQU 14
grtHour	EQU 18
grtMin		EQU 22
grtSec		EQU 26
grtMilli	EQU 30

_RdosGetTime	Proc far
	push bp
	mov bp,sp
	push ds
	push si
;
	GetTime
	push eax
	BinaryToTime
;
	lds si,[bp].grtYear
	mov [si],dx
	lds si,[bp].grtMonth
	mov [si],ch
	mov byte ptr [si+1],0
	lds si,[bp].grtDay
	mov [si],cl
	mov byte ptr [si+1],0
	lds si,[bp].grtHour
	mov [si],bh
	mov byte ptr [si+1],0
	lds si,[bp].grtMin
	mov [si],bl
	mov byte ptr [si+1],0
	lds si,[bp].grtSec
	mov [si],ah
	mov byte ptr [si+1],0
;
	TimeToBinary
	mov ebx,eax
	pop eax
	sub eax,ebx
	xor edx,edx
	mov ebx,1192
	div ebx
	lds si,[bp].grtMilli
	mov [si],ax
;
	pop si
	pop ds
	pop bp
	ret
_RdosGetTime	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosTicsToRecord
;
;		description:	Convert tics to record form
;
;		PARAMETERS:		int MSB
;						int LSB
;						int *year
;						int *month
;						int *day
;						int *hour
;						int *min
;						int *sec
;						int *milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosTicsToRecord

ctMSB		EQU 6
ctLSB		EQU 10
ctYear		EQU 14
ctMonth		EQU 18
ctDay		EQU 22
ctHour		EQU 26
ctMin		EQU 30
ctSec		EQU 34
ctMilli		EQU 38

_RdosTicsToRecord	Proc far
	push bp
	mov bp,sp
	push es
	pusha
;
	mov edx,[bp].ctMSB
	mov eax,[bp].ctLSB
	BinaryToTime
	push edx
;
	les si,[bp].ctYear
	mov es:[si],dx
;
	les si,[bp].ctMonth
	movzx dx,ch
	mov es:[si],dx
;
	les si,[bp].ctDay
	movzx dx,cl
	mov es:[si],dx
;
	les si,[bp].ctHour
	movzx dx,bh
	mov es:[si],dx
;
	les si,[bp].ctMin
	movzx dx,bl
	mov es:[si],dx
;
	les si,[bp].ctSec
	movzx dx,ah
	mov es:[si],dx
;
	pop edx
	TimeToBinary
	mov ebx,eax
	mov eax,[bp].ctLSB
	sub eax,ebx
	xor edx,edx
	mov ebx,1192
	div ebx
	les si,[bp].ctMilli
	mov es:[si],ax
;
	popa
	pop es
	pop bp
	ret
_RdosTicsToRecord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosRecordToTics
;
;		description:	Convert record form to tics
;
;		PARAMETERS:		int *MSB
;						int *LSB
;						int year
;						int month
;						int day
;						int hour
;						int min
;						int sec
;						int milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosRecordToTics

rtMSB		EQU 6
rtLSB		EQU 10
rtYear		EQU 14
rtMonth		EQU 16
rtDay		EQU 18
rtHour		EQU 20
rtMin		EQU 22
rtSec		EQU 24
rtMilli		EQU 26

_RdosRecordToTics	Proc far
	push bp
	mov bp,sp
	push es
	pusha
;
	movzx eax,word ptr [bp].rtMilli
	mov edx,1192
	mul edx
	push eax
	mov dx,[bp].rtYear
	mov ch,[bp].rtMonth
	mov cl,[bp].rtDay
	mov bh,[bp].rtHour
	mov bl,[bp].rtMin
	mov ah,[bp].rtSec
	TimeToBinary
	pop ebx
	add eax,ebx
	adc edx,0
;
	les si,[bp].rtMSB
	mov es:[si],edx
;
	les si,[bp].rtLSB
	mov es:[si],eax
;
	popa
	pop es
	pop bp
	ret
_RdosRecordToTics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetTics
;
;		description:	gets system time
;
;		parameters:		MSB of tics
;						LSB of tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetTics

rgtMSB	EQU 6
rgtLSB	EQU 10

_RdosGetTics	Proc far
	push bp
	mov bp,sp
	push es
	push dx
	push si
;
	GetTime
	les si,[bp].rgtMSB
	mov es:[si],edx
	les si,[bp].rgtLSB
	mov es:[si],eax
;
	pop si
	pop dx
	pop es
	pop bp
	ret
_RdosGetTics	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddTics
;
;		description:	add tics to time
;
;		PARAMETERS:		long *msb
;						long *lsb
;						long tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddTics

_RdosAddTics	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	mov eax,[bp+14]
	les di,[bp+10]
	add es:[di],eax
	les di,[bp+6]
	adc dword ptr es:[di],0	
;
    pop di
	pop es
	pop bp
	ret
_RdosAddTics	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddMilli
;
;		description:	add milli seconds
;
;		PARAMETERS:		long *msb
;						long *lsb
;						long milli
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddMilli

_RdosAddMilli	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	mov eax,[bp+14]
	mov edx,1193
	mul edx
	les di,[bp+10]
	add es:[di],eax
	les di,[bp+6]
	adc es:[di],edx
;
	pop di
	pop es
	pop bp
	ret
_RdosAddMilli	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddSec
;
;		description:	add seconds
;
;		PARAMETERS:		long *msb
;						long *lsb
;						long sec
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddSec

_RdosAddSec	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	mov eax,[bp+14]
	mov edx,1193000
	mul edx
	les di,[bp+10]
	add es:[di],eax
	les di,[bp+6]
	adc es:[di],edx
;
	pop di
	pop es
	pop bp
	ret
_RdosAddSec	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddMin
;
;		description:	add minute
;
;		PARAMETERS:		long *msb
;						long *lsb
;						long min
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddMin

_RdosAddMin	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	mov eax,[bp+14]
	mov edx,1193046*60
	mul edx
	les di,[bp+10]
	add es:[di],eax
	les di,[bp+6]
	adc es:[di],edx
;
	pop di
	pop es
	pop bp
	ret
_RdosAddMin	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddHour
;
;		description:	add hour
;
;		PARAMETERS:		long *msb
;						long *lsb
;						long hour
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddHour

_RdosAddHour	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	mov eax,[bp+14]
	les di,[bp+6]
	add es:[di],eax
;
	pop di
	pop es
	pop bp
	ret
_RdosAddHour	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddDay
;
;		description:	add days
;
;		PARAMETERS:		long *msb
;						long *lsb
;						long day
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosAddDay

_RdosAddDay	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	mov eax,[bp+14]
	mov edx,24
	mul edx
	les di,[bp+6]
	add es:[di],eax
;
	pop di
	pop es
	pop bp
	ret
_RdosAddDay	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosOpenCom
;
;		description:	Open comport
;
;		PARAMETERS:		port_base		base IO-address to com port
;						port_irq		irq to com port
;						baud_divisor	baudrate divisor
;						parity			parity 'N', 'E' or 'O'
;						data_bits		# of data bits
;						stop_bits		# of stop bits
;						send_buf_size	size of transmit buffer
;						rec_buf_size	size of receive buffer
;
;		RETURNS:		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosOpenCom

port_base		EQU 6
port_irq		EQU 8
baud_divisor	EQU 10
parity			EQU 12
data_bits		EQU 14
stop_bits		EQU 16
send_buf_size	EQU 18
rec_buf_size	EQU 20

_RdosOpenCom	Proc far
	push bp
	mov bp,sp
	push bx
	push si
	push di
;
	mov dx,[bp].port_base
	mov al,[bp].port_irq
	mov ah,[bp].data_bits
	mov bl,[bp].stop_bits
	mov bh,[bp].parity
	mov cx,[bp].baud_divisor
	mov si,[bp].send_buf_size
	mov di,[bp].rec_buf_size
	OpenCom
	mov ax,bx
;
	pop di
	pop si
	pop bx
	pop bp
	ret
_RdosOpenCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseCom
;
;		description:	Close comport
;
;		PARAMETERS:		port_handle		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCloseCom

_RdosCloseCom	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseCom
;
    pop bx
	pop bp
	ret
_RdosCloseCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosFlushCom
;
;		description:	Flush comport
;
;		PARAMETERS:		port_handle		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosFlushCom

_RdosFlushCom	Proc far
	push bp
	mov bp,sp
;
    push bx
	mov bx,[bp+6]
	FlushCom
;
    pop bx
	pop bp
	ret
_RdosFlushCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosReadCom
;
;		description:    Read a char
;
;		PARAMETERS:		hport		port handle
;
;		RETURNS:		ch			received char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReadCom

_RdosReadCom	PROC far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	ReadCom
;
	pop bx
	pop bp
	ret
_RdosReadCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWriteCom
;
;		description:	Write a char to port
;
;		PARAMETERS:		hport		port handle
;						ch			char
;
;		RETURNS:		0			success
;						-1			buffer full
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWriteCom

_RdosWriteCom	PROC far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	mov al,[bp+8]
	WriteCom
;
    pop bx
	pop bp
	ret
_RdosWriteCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetDtr
;
;		description:	Set DTR signal
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetDtr

_RdosSetDtr	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	SetDtr
;
    pop bx
	pop bp
	ret
_RdosSetDtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosResetDtr
;
;		description:	Reset DTR signal
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosResetDtr

_RdosResetDtr	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	ResetDtr
;
    pop bx
	pop bp
	ret
_RdosResetDtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetRts
;
;		description:	Set RTS signal
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetRts

_RdosSetRts	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	SetRts
;
	pop bx
	pop bp
	ret
_RdosSetRts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosResetRts
;
;		description:	Reset RTS signal
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosResetRts

_RdosResetRts	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	ResetRts
;
	pop bx
	pop bp
	ret
_RdosResetRts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetReceiveBufferSpace
;
;		description:	Get receive buffer space
;
;		PARAMETERS:		hport		port handle
;
;       RETURNS:        number of free bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetReceiveBufferSpace

_RdosGetReceiveBufferSpace	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
    GetComReceiveSpace
;
	pop bx
	pop bp
	ret
_RdosGetReceiveBufferSpace	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetSendBufferSpace
;
;		description:	Get send buffer space
;
;		PARAMETERS:		hport		port handle
;
;       RETURNS:        number of free bytes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetSendBufferSpace

_RdosGetSendBufferSpace	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	GetComSendSpace
;
	pop bx
	pop bp
	ret
_RdosGetSendBufferSpace	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenFile
;
;		DESCRIPTION:	Opens a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosOpenFile

_RdosOpenFile	PROC	FAR
	push bp
	mov bp,sp
	push es
	push bx
	push cx
	push di
;
	les di,[bp+6]
	mov cl,[bp+10]
	OpenFile
	jc OpenFileFailed
;
	mov ax,bx
	jmp OpenFileDone

OpenFileFailed:
	xor ax,ax

OpenFileDone:
	pop di
	pop cx
	pop bx
	pop es
	pop bp
	ret
_RdosOpenFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateFile
;
;		DESCRIPTION:	Creates a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateFile

_RdosCreateFile	PROC far
	push bp
	mov bp,sp
	push es
	push bx
	push cx
	push di
;
	les di,[bp+6]
	mov cx,[bp+10]
    CreateFile
	jc CreateFileFailed
;
	mov ax,bx
	jmp CreateFileDone

CreateFileFailed:
	xor ax,ax

CreateFileDone:
	pop di
	pop cx
	pop bx
	pop es
	pop bp
	ret
_RdosCreateFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseFile
;
;		DESCRIPTION:	Close a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCloseFile

_RdosCloseFile	PROC	FAR
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseFile
;
    pop bx
	pop bp
	ret
_RdosCloseFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosIsDevice
;
;		DESCRIPTION:	Check if file is a device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosIsDevice

_RdosIsDevice	PROC far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	GetIoctlData
	test dx,8000h
	jz ridFail
;
	mov ax,1
	jmp ridDone

ridFail:
	xor ax,ax

ridDone:
	pop bx
	pop bp
	ret
_RdosIsDevice	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosDuplFile
;
;		DESCRIPTION:	Duplicate file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDuplFile

_RdosDuplFile	PROC far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	DuplFile
	jc DuplFileFailed
;
	mov ax,bx
	jmp DuplFileDone

DuplFileFailed:
	xor ax,ax

DuplFileDone:
	pop bx
	pop bp
	ret
_RdosDuplFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFileSize
;
;		DESCRIPTION:	Get size of a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetFileSize

_RdosGetFileSize	PROC	FAR
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	GetFileSize
	jc GetFileSizeFail
;
	push eax
	pop ax
	pop dx
	jmp GetFileSizeDone

GetFileSizeFail:
	xor ax,ax
	xor dx,dx

GetFileSizeDone:
    pop bx
	pop bp
	ret
_RdosGetFileSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFileSize
;
;		DESCRIPTION:	Set size of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetFileSize

_RdosSetFileSize	PROC	FAR
	push bp
	mov bp,sp
    push bx
;
	mov bx,[bp+6]
	mov eax,[bp+8]
	SetFileSize
;
    pop bx
	pop bp
	ret
_RdosSetFileSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFilePos
;
;		DESCRIPTION:	Get position in a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetFilePos

_RdosGetFilePos	PROC	FAR
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	GetFilePos
	jc GetFilePosFail
;
	push eax
	pop ax
	pop dx
	jmp GetFilePosDone

GetFilePosFail:
	xor ax,ax
	xor dx,dx

GetFilePosDone:
    pop bx
	pop bp
	ret
_RdosGetFilePos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFilePos
;
;		DESCRIPTION:	Set position in file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetFilePos

_RdosSetFilePos	PROC	FAR
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	mov eax,[bp+8]
	SetFilePos
;
    pop bx
	pop bp
	ret
_RdosSetFilePos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFileTime
;
;		DESCRIPTION:	Get file date & time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetFileTime

_RdosGetFileTime	PROC far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	mov bx,[bp+6]
	GetFileTime
	jc GetFileTimeDone
;
	les di,[bp+8]
	mov es:[di],edx
;
	les di,[bp+12]
	mov es:[di],eax

GetFileTimeDone:
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosGetFileTime	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFileTime
;
;		DESCRIPTION:	Set date & time for file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetFileTime

_RdosSetFileTime	PROC far
	push bp
	mov bp,sp
	push ax
	push bx
	push dx
;
	mov bx,[bp+6]
	mov edx,[bp+8]
	mov eax,[bp+12]
	SetFileTime
;
	pop dx
	pop bx
	pop ax
	pop bp
	ret
_RdosSetFileTime	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadFile
;
;		DESCRIPTION:	Read data from file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReadFile

_RdosReadFile	PROC	FAR
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	mov cx,[bp+12]
	ReadFile
;
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosReadFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteFile
;
;		DESCRIPTION:	Write data to file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWriteFile

_RdosWriteFile	PROC	FAR
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	mov cx,[bp+12]
	WriteFile
;
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosWriteFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateMapping
;
;		DESCRIPTION:	Create file mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateMapping

_RdosCreateMapping	PROC far
	push bp
	mov bp,sp
	push bx
;
	movzx eax,word ptr [bp+6]
	CreateMapping
	mov ax,bx
;
	pop bx
	pop bp
	ret
_RdosCreateMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateNamedMapping
;
;		DESCRIPTION:	Create file named mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateNamedMapping

_RdosCreateNamedMapping	PROC far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	les di,[bp+6]
	movzx ax,[bp+10]
	CreateNamedMapping
	mov ax,bx
;
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosCreateNamedMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateNamedFileMapping
;
;		DESCRIPTION:	Create file named file mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCreateNamedFileMapping

_RdosCreateNamedFileMapping	PROC far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	les di,[bp+6]
	movzx eax,word ptr [bp+10]
	mov bx,[bp+12]
	CreateNamedFileMapping
	mov ax,bx
;
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosCreateNamedFileMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenNamedMapping
;
;		DESCRIPTION:	Open named mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosOpenNamedMapping

_RdosOpenNamedMapping	PROC far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	les di,[bp+6]
	OpenNamedMapping
	mov ax,bx
;
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosOpenNamedMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSyncMapping
;
;		DESCRIPTION:	Sync mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSyncMapping

_RdosSyncMapping	PROC far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	SyncMapping
;
	pop bx
	pop bp
	ret
_RdosSyncMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseMapping
;
;		DESCRIPTION:	Close mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCloseMapping

_RdosCloseMapping	PROC far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseMapping
;
	pop bx
	pop bp
	ret
_RdosCloseMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosMapView
;
;		DESCRIPTION:	Map view into memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosMapView

_RdosMapView	PROC far
	push bp
	mov bp,sp
	push es
	push bx
	push cx
	push di
;
	mov bx,[bp+6]
	mov eax,[bp+10]
	les di,[bp+14]
	mov cx,[bp+18]
	MapView
;
	pop di
	pop cx
	pop bx
	pop es
	pop bp
	ret
_RdosMapView	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosUnmapView
;
;		DESCRIPTION:	Unmap view from memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosUnmapView

_RdosUnmapView	PROC far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	UnmapView
;
	pop bx
	pop bp
	ret
_RdosUnmapView	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetCurDrive
;
;		DESCRIPTION:	Set current drive
;
;		PARAMETER:		Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetCurDrive

_RdosSetCurDrive	PROC far
	push bp
	mov bp,sp
;
	mov al,[bp+6]
    SetCurDrive
	jc rscdrFail

    mov ax,1
    jmp rscdrDone

rscdrFail:
    xor ax,ax

rscdrDone:
	pop bp
	ret
_RdosSetCurDrive	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetCurDrive
;
;		DESCRIPTION:	Get current drive
;
;		RETURNS:		Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetCurDrive

_RdosGetCurDrive	PROC far
	push bp
	mov bp,sp
;
    xor ax,ax
    GetCurDrive
	movzx ax,al
;
	pop bp
	ret
_RdosGetCurDrive	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetCurDir
;
;		DESCRIPTION:	Set current directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetCurDir

_RdosSetCurDir	PROC
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	SetCurDir
	jc rscdFail

    mov ax,1
    jmp rscdDone

rscdFail:
    xor ax,ax

rscdDone:
	pop di
	pop es
	pop bp
	ret
_RdosSetCurDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetCurDir
;
;		DESCRIPTION:	Get current directory
;
;		PARAMETER:		Drive
;                       Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetCurDir

_RdosGetCurDir	PROC far
	push bp
	mov bp,sp
	push es
	push di
;
    mov al,[bp+6]
	les di,[bp+8]
	GetCurDir
	jc rgcdFail

    mov ax,1
    jmp rgcdDone

rgcdFail:
    xor ax,ax

rgcdDone:
	pop di
	pop es
	pop bp
	ret
_RdosGetCurDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosMakeDir
;
;		DESCRIPTION:	Make a new directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosMakeDir

_RdosMakeDir	PROC far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	MakeDir
	jc mdFail

    mov ax,1
    jmp mdDone

mdFail:
    xor ax,ax

mdDone:
	pop di
	pop es
	pop bp
	ret
_RdosMakeDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosRemoveDir
;
;		DESCRIPTION:	Remove a directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosRemoveDir

_RdosRemoveDir	PROC far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	RemoveDir
	jc rdFail

    mov ax,1
    jmp rdDone

rdFail:
    xor ax,ax

rdDone:
	pop di
	pop es
	pop bp
	ret
_RdosRemoveDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosRenameFile
;
;		DESCRIPTION:	Rename a file
;
;		PARAMETER:		ToName
;                       FromName
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosRenameFile

_RdosRenameFile	PROC far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
;
	les di,[bp+6]
	lds si,[bp+10]
	RenameFile
	jc rfFail

    mov ax,1
    jmp rfDone

rfFail:
    xor ax,ax

rfDone:
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret
_RdosRenameFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosDeleteFile
;
;		DESCRIPTION:	Delete a file
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDeleteFile

_RdosDeleteFile	PROC far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	DeleteFile
	jc dfFail

    mov ax,1
    jmp dfDone

dfFail:
    xor ax,ax

dfDone:
	pop di
	pop es
	pop bp
	ret
_RdosDeleteFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFileAttribute
;
;		DESCRIPTION:	Get file attribute
;
;		PARAMETER:		Pathname
;                       Attribute
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetFileAttribute

_RdosGetFileAttribute	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push di
;
    les di,[bp+6]
	GetFileAttribute
	jc gfaFail
;
    les di,[bp+10]
    mov es:[di],cx
    mov ax,1
    jmp gfaDone

gfaFail:
    xor ax,ax

gfaDone:
	pop di
	pop cx
	pop es
	pop bp
	ret
_RdosGetFileAttribute	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFileAttribute
;
;		DESCRIPTION:	Set file attribute
;
;		PARAMETER:		Pathname
;                       Attribute
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetFileAttribute

_RdosSetFileAttribute	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push di
;
	les di,[bp+6]
	mov cx,[bp+10]
	SetFileAttribute
	jc sfaFail
;
    mov ax,1
    jmp sfaDone

sfaFail:
    xor ax,ax

sfaDone:
	pop di
	pop cx
	pop es
	pop bp
	ret
_RdosSetFileAttribute	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenDir
;
;		DESCRIPTION:	Open directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosOpenDir

_RdosOpenDir	PROC far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	les di,[bp+6]
	OpenDir
	jc odFail
;
    mov ax,bx
    jmp odDone

odFail:
    xor ax,ax

odDone:
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosOpenDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseDir
;
;		DESCRIPTION:	Close directory
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosCloseDir

_RdosCloseDir	PROC far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseDir
;
	pop bx
	pop bp
	ret
_RdosCloseDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadDir
;
;		DESCRIPTION:	Read a directory entry
;
;		PARAMETER:		Handle
;                       Entry #
;                       MaxNameSize
;                       Name buffer
;                       FileSize
;                       Attribute
;                       Msb time
;                       Lsb time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReadDir

_RdosReadDir	PROC far
	push bp
	mov bp,sp
	push es
	push bx
	push ecx
	push di
;
	mov bx,[bp+6]
	mov dx,[bp+8]
	mov cx,[bp+10]
	les di,[bp+12]
	UserGate read_dir_nr
	jc rdiFail
;
    les di,[bp+16]
    mov es:[di],ecx
;
    les di,[bp+20]
    mov es:[di],bx
;
    les di,[bp+24]
    mov es:[di],edx
;
    les di,[bp+28]
    mov es:[di],eax
;
    mov ax,1
    jmp rdiDone

rdiFail:
    xor ax,ax
    
rdiDone:
    pop di
    pop ecx
	pop bx
	pop es
	pop bp
	ret
_RdosReadDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFocus
;
;		DESCRIPTION:	Set focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetFocus

_RdosSetFocus	PROC far
	push bp
	mov bp,sp
	mov ax,[bp+6]
	SetFocus
	pop bp
	ret
_RdosSetFocus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosClearKeyboard
;
;		DESCRIPTION:	Clear keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosClearKeyboard

_RdosClearKeyboard	PROC far
	FlushKeyboard
	ret
_RdosClearKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPollKeyboard
;
;		DESCRIPTION:	Poll keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosPollKeyboard

_RdosPollKeyboard	PROC far
	PollKeyboard
	jc rpkEmpty
;
	mov ax,1
	ret

rpkEmpty:
	xor ax,ax
	ret
_RdosPollKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadKeyboard
;
;		DESCRIPTION:	Read keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReadKeyboard

_RdosReadKeyboard	PROC far
	ReadKeyboard
	ret
_RdosReadKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetKeyboardState
;
;		DESCRIPTION:	Get keyboard state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetKeyboardState

_RdosGetKeyboardState	PROC far
	GetKeyboardState
	ret
_RdosGetKeyboardState	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPeekKeyEvent
;
;		DESCRIPTION:	Peek keyboard event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosPeekKeyEvent

_RdosPeekKeyEvent	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
	PeekKeyEvent
	jc rpeFail
;
	les di,[bp+6]
	mov es:[di],ax
;
	les di,[bp+10]
	mov es:[di],cx
;
	les di,[bp+14]
	movzx ax,dl
	mov es:[di],ax
;
	les di,[bp+18]
	movzx ax,dh
	mov es:[di],ax
;
	mov ax,1
	jmp rpeDone

rpeFail:
	xor ax,ax

rpeDone:
	pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosPeekKeyEvent	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadKeyEvent
;
;		DESCRIPTION:	Read keyboard event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReadKeyEvent

_RdosReadKeyEvent	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
	ReadKeyEvent
	jc rkeFail
;
	les di,[bp+6]
	mov es:[di],ax
;
	les di,[bp+10]
	mov es:[di],cx
;
	les di,[bp+14]
	movzx ax,dl
	mov es:[di],ax
;
	les di,[bp+18]
	movzx ax,dh
	mov es:[di],ax
;
	mov ax,1
	jmp rkeDone

rkeFail:
	xor ax,ax

rkeDone:
	pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosReadKeyEvent	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosHideMouse
;
;		DESCRIPTION:	Hide mouse
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosHideMouse

_RdosHideMouse	PROC far
	HideMouse
	ret
_RdosHideMouse	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosShowMouse
;
;		DESCRIPTION:	Show mouse
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosShowMouse

_RdosShowMouse	PROC far
	ShowMouse
	ret
_RdosShowMouse	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetMousePosition
;
;		DESCRIPTION:	Get mouse position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetMousePosition

_RdosGetMousePosition	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
    GetMousePosition
	les di,[bp+6]
	mov es:[di],cx
	les di,[bp+10]
	mov es:[di],dx
;
    pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosGetMousePosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetMousePosition
;
;		DESCRIPTION:	Set mouse position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetMousePosition

_RdosSetMousePosition	PROC far
	push bp
	mov bp,sp
	push cx
	push dx
;
	mov cx,[bp+6]
	mov dx,[bp+8]
	SetMousePosition
;
	pop dx
	pop cx
	pop bp
	ret
_RdosSetMousePosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetMouseWindow
;
;		DESCRIPTION:	Set mouse window
;
;		PARAMETER:		start x
;						start y
;						end x
;						end y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetMouseWindow

_RdosSetMouseWindow	PROC far
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
;
	mov ax,[bp+6]
	mov bx,[bp+8]
	mov cx,[bp+10]
	mov dx,[bp+12]
	SetMouseWindow
;
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret
_RdosSetMouseWindow	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetMouseMickey
;
;		DESCRIPTION:	Set mouse mickey
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetMouseMickey

_RdosSetMouseMickey	PROC far
	push bp
	mov bp,sp
	push cx
	push dx
;
	mov cx,[bp+6]
	mov dx,[bp+8]
	SetMouseMickey
;
	pop dx
	pop cx
	pop bp
	ret
_RdosSetMouseMickey	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetCursorPosition
;
;		DESCRIPTION:	Get cursor position
;
;		PARAMETER:		row
;						col
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetCursorPosition

_RdosGetCursorPosition	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
    GetCursorPosition
	les di,[bp+6]
	mov es:[di],dx
	les di,[bp+10]
	mov es:[di],cx
;
    pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosGetCursorPosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetCursorPosition
;
;		DESCRIPTION:	Set cursor position
;
;		PARAMETER:		Row
;						Col
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSetCursorPosition

_RdosSetCursorPosition	PROC far
	push bp
	mov bp,sp
	push cx
	push dx
;
	mov dx,[bp+6]
	mov cx,[bp+8]
	SetCursorPosition
;
	pop dx
	pop cx
	pop bp
	ret
_RdosSetCursorPosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLeftButton
;
;		DESCRIPTION:	Check if left button is pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetLeftButton

_RdosGetLeftButton	PROC far
	GetLeftButton
	jc get_left_rel
;
	mov ax,1
	ret

get_left_rel:
	xor ax,ax
	ret
_RdosGetLeftButton	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRightButton
;
;		DESCRIPTION:	Check if right button is pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetRightButton

_RdosGetRightButton	PROC far
	GetRightButton
	jc get_right_rel
;
	mov ax,1
	ret

get_right_rel:
	xor ax,ax
	ret
_RdosGetRightButton	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLeftButtonPressPosition
;
;		DESCRIPTION:	Get left button press position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetLeftButtonPressPosition

_RdosGetLeftButtonPressPosition	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
    GetLeftButtonPressPosition
	les di,[bp+6]
	mov es:[di],cx
	les di,[bp+10]
	mov es:[di],dx
;
    pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosGetLeftButtonPressPosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRightButtonPressPosition
;
;		DESCRIPTION:	Get right button pressed position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetRightButtonPressPosition

_RdosGetRightButtonPressPosition	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
    GetRightButtonPressPosition
	les di,[bp+6]
	mov es:[di],cx
	les di,[bp+10]
	mov es:[di],dx
;
    pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosGetRightButtonPressPosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLeftButtonRelesePosition
;
;		DESCRIPTION:	Get left button released position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetLeftButtonReleasePosition

_RdosGetLeftButtonReleasePosition	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
    GetLeftButtonReleasePosition
	les di,[bp+6]
	mov es:[di],cx
	les di,[bp+10]
	mov es:[di],dx
;
    pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosGetLeftButtonReleasePosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRightButtonReleasePosition
;
;		DESCRIPTION:	Get right button release position
;
;		PARAMETER:		x
;						y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetRightButtonReleasePosition

_RdosGetRightButtonReleasePosition	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
    GetRightButtonReleasePosition
	les di,[bp+6]
	mov es:[di],cx
	les di,[bp+10]
	mov es:[di],dx
;
    pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosGetRightButtonReleasePosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadLine
;
;		DESCRIPTION:	Read a line from keyboard
;
;		PARAMETERS:		Buffer
;						Buffer size
;
;		RETURNS:		Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReadLine

_RdosReadLine	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push di
;
	les di,[bp+6]
	mov cx,[bp+10]
	ReadConsole
;
	pop di
	pop cx
	pop es
	pop bp
	ret
_RdosReadLine	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteChar
;
;		DESCRIPTION:	Write a single character to screen
;
;		PARAMETER:		Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWriteChar

_RdosWriteChar	PROC far
	push bp
	mov bp,sp
;
	mov al,[bp+6]
	WriteChar
;
	pop bp
	ret
_RdosWriteChar	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteSizeString
;
;		DESCRIPTION:	Write a fixed number of characters to screen
;
;		PARAMETER:		String
;						Count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWriteSizeString

_RdosWriteSizeString	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push di
;
	les di,[bp+6]
	mov cx,[bp+10]
	WriteSizeString
;
	pop di
	pop cx
	pop es
	pop bp
	ret
_RdosWriteSizeString	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteString
;
;		DESCRIPTION:	Write a string to screen
;
;		PARAMETER:		String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWriteString

_RdosWriteString	PROC far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	WriteAsciiz
;
	pop di
	pop es
	pop bp
	ret
_RdosWriteString	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosNameToIp
;
;		DESCRIPTION:	Convert host name to IP address
;
;		PARAMETER:		Pathname
;						IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosNameToIp

_RdosNameToIp	PROC far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	NameToIP
	jc rntiFail
;
	mov eax,edx
	jmp rntiDone

rntiFail:
	xor eax,eax

rntiDone:
	pop di
	pop es
	pop bp
	ret
_RdosNameToIp	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosIpToName
;
;		DESCRIPTION:	Convert IP address to host name
;
;		PARAMETER:		IP address
;						Host name
;						Max size of name
;
;		RETURNS:		Number of bytes returned
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosIpToName

_RdosIpToName	PROC far
	push bp
	mov bp,sp
	push es
	push cx
	push dx
	push di
;
	mov edx,[bp+6]
	les di,[bp+10]
	mov cx,[bp+14]
	IPToName
	jnc ritnDone

ritnFail:
	xor ax,ax

ritnDone:
	pop di
	pop dx
	pop cx
	pop es
	pop bp
	ret
_RdosIpToName	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPing
;
;		DESCRIPTION:	Ping node
;
;		PARAMETER:		Node
;						Timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosPing

_RdosPing	PROC far
	push bp
	mov bp,sp
	push edx
;
	mov edx,[bp+6]
	mov eax,[bp+10]
	Ping
	jc ping_failed
;
	mov ax,1
	jmp ping_done

ping_failed:
	xor ax,ax

ping_done:
	pop edx
	pop bp
	ret
_RdosPing	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLocalMailslot
;
;		DESCRIPTION:	Get local mailslot from name
;
;		PARAMETER:		Name
;
;		RETURNS:		Mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetLocalMailslot

_RdosGetLocalMailslot	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	les di,[bp+6]
    GetLocalMailslot
	jc rglmFail
;
	mov ax,bx
	jmp rglmDone

rglmFail:
	xor ax,ax

rglmDone:
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosGetLocalMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRemoteMailslot
;
;		DESCRIPTION:	Get remote mailslot from name
;
;		PARAMETER:		Ip
;						Name
;
;		RETURNS:		Mailslot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetRemoteMailslot

_RdosGetRemoteMailslot	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push edx
	push di
;
	mov edx,[bp+6]
	les di,[bp+10]
	GetRemoteMailslot
	jc rgrmFail
;
	mov ax,bx
	jmp rgrmDone

rgrmFail:
	xor ax,ax

rgrmDone:
	pop di
	pop edx
	pop bx
	pop es
	pop bp
	ret
_RdosGetRemoteMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosFreeMailslot
;
;		DESCRIPTION:	Free mailslot handle
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosFreeMailslot

_RdosFreeMailslot	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	FreeMailslot
;
	pop bx
	pop bp
	ret
_RdosFreeMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSendMailslot
;
;		DESCRIPTION:	Send to mailslot and wait for reply
;
;		PARAMETER:		Handle
;						Msg
;						Size
;						ReplyBuf
;						MaxReplySize
;
;		RETURNS:		Reply size or -1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosSendMailslot

_RdosSendMailslot	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push bx
	push si
	push di
;
	mov bx,[bp+6]
	lds si,[bp+8]
	mov cx,[bp+12]
	les di,[bp+14]
	mov ax,[bp+18]
	SendMailslot
	jc smFail
;
	mov ax,cx
	jmp smDone

smFail:
	mov ax,-1

smDone:
	pop di
	pop si
	pop bx
	pop es
	pop ds
	pop bp
	ret
_RdosSendMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosDefineMailslot
;
;		DESCRIPTION:	Define mailslot for current thread
;
;		PARAMETER:		Name
;						Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosDefineMailslot

_RdosDefineMailslot	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	mov cx,[bp+10]
	DefineMailslot
;
	pop di
	pop es
	pop bp
	ret
_RdosDefineMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReceiveMailslot
;
;		DESCRIPTION:	Receive from mailslot
;
;		PARAMETER:		Msg buffer
;
;		RETURNS:		Message size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReceiveMailslot

_RdosReceiveMailslot	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	ReceiveMailslot
	mov ax,cx
;
	pop di
	pop es
	pop bp
	ret
_RdosReceiveMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReplyMailslot
;
;		DESCRIPTION:	Receive from mailslot
;
;		PARAMETER:		Msg
;						Size
;
;		RETURNS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReplyMailslot

_RdosReplyMailslot	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	mov cx,[bp+10]
	ReplyMailslot
;
	pop di
	pop es
	pop bp
	ret
_RdosReplyMailslot	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetDiscInfo
;
;		DESCRIPTION:	Get disc info
;
;		PARAMETER:		Disc #
;						Bytes / sector
;						Total sectors
;						BIOS sectors / cyl
;						BIOS heads
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosGetDiscInfo

_RdosGetDiscInfo	Proc far
	push bp
	mov bp,sp
	push ds
	push bx
	push edx
	push si
	push di
;
	mov al,[bp+6]
    GetDiscInfo
	jc get_disc_info_fail
;
    lds bx,[bp+8]
    mov [bx],cx
;
    lds bx,[bp+12]
    mov [bx],edx
;
    lds bx,[bp+16]
    mov [bx],si
;
    lds bx,[bp+20]
    mov [bx],di
;
	mov ax,1
	jmp get_disc_info_done

get_disc_info_fail:
	xor ax,ax

get_disc_info_done:
	pop di
	pop si
	pop edx
	pop bx
	pop ds
	pop bp
	ret
_RdosGetDiscInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadDisc
;
;		DESCRIPTION:	Read from disc
;
;		PARAMETER:		Disc #
;						Sector #
;						Buffer
;						Size
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosReadDisc

_RdosReadDisc	Proc far
	push bp
	mov bp,sp
	push es
	push edx
	push di
;
	mov al,[bp+6]
	mov edx,[bp+8]
	les di,[bp+12]
	mov cx,[bp+16]
	ReadDisc
	jc read_disc_fail
;
	mov ax,1
	jmp read_disc_done

read_disc_fail:
	xor ax,ax

read_disc_done:
	pop di
	pop edx
	pop es
	pop bp
	ret
_RdosReadDisc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			WriteReadDisc
;
;		DESCRIPTION:	Write to disc
;
;		PARAMETER:		Disc #
;						Sector #
;						Buffer
;						Size
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _RdosWriteDisc

_RdosWriteDisc	Proc far
	push bp
	mov bp,sp
	push es
	push edx
	push di
;
	mov al,[bp+6]
	mov edx,[bp+8]
	les di,[bp+12]
	mov cx,[bp+16]
	WriteDisc
	jc write_disc_fail
;
	mov ax,1
	jmp write_disc_done

write_disc_fail:
	xor ax,ax

write_disc_done:
	pop di
	pop edx
	pop es
	pop bp
	ret
_RdosWriteDisc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenSysEnv
;
;       DESCRIPTION:    Open systen environment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosOpenSysEnv

_RdosOpenSysEnv	Proc far
	push bx
;
	OpenSysEnv
	jc oseFail
;
	mov ax,bx
	jmp oseDone

oseFail:
	xor ax,ax

oseDone:
	pop bx
	ret
_RdosOpenSysEnv	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenProcessEnv
;
;       DESCRIPTION:    Open process environment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosOpenProcessEnv

_RdosOpenProcessEnv	Proc far
	push bx
;
	OpenProcEnv
	jc opeFail
;
	mov ax,bx
	jmp opeDone

opeFail:
	xor ax,ax

opeDone:
	pop bx
	ret
_RdosOpenProcessEnv	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosCloseEnv
;
;       DESCRIPTION:    Close environment
;
;		PARAMETERS:		handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosCloseEnv

_RdosCloseEnv	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseEnv
;
	pop bx
	pop bp
	ret
_RdosCloseEnv	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosAddEnvVar
;
;       DESCRIPTION:    Add environment var
;
;		PARAMETERS:		handle
;						var
;						data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosAddEnvVar

_RdosAddEnvVar	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push bx
	push si
	push di
;
	mov bx,[bp+6]
	lds si,[bp+8]
	les di,[bp+12]
	AddEnvVar
;
	pop di
	pop si
	pop bx
	pop es
	pop ds
	pop bp
	ret
_RdosAddEnvVar	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosDeleteEnvVar
;
;       DESCRIPTION:    Delete environment var
;
;		PARAMETERS:		handle
;						var
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosDeleteEnvVar

_RdosDeleteEnvVar	Proc far
	push bp
	mov bp,sp
	push ds
	push bx
	push si
;
	mov bx,[bp+6]
	lds si,[bp+8]
	DeleteEnvVar
;
	pop si
	pop bx
	pop ds
	pop bp
	ret
_RdosDeleteEnvVar	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosFindEnvVar
;
;       DESCRIPTION:    Find environment var
;
;		PARAMETERS:		handle
;						var
;						data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosFindEnvVar

_RdosFindEnvVar	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push bx
	push si
	push di
;
	mov bx,[bp+6]
	lds si,[bp+8]
	les di,[bp+12]
	FindEnvVar
	jc fevFail
;
	mov ax,1
	jmp fevDone

fevFail:
	xor ax,ax

fevDone:
	pop di
	pop si
	pop bx
	pop es
	pop ds
	pop bp
	ret
_RdosFindEnvVar	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetEnvData
;
;       DESCRIPTION:    Get raw environment data
;
;		PARAMETERS:		handle
;						data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosGetEnvData

_RdosGetEnvData	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	GetEnvData
	jnc gedDone
;
	xor ax,ax
	stosw

gedDone:
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosGetEnvData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosSetEnvData
;
;       DESCRIPTION:    Set raw environment data
;
;		PARAMETERS:		handle
;						data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosSetEnvData

_RdosSetEnvData	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	SetEnvData
;
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosSetEnvData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosLoadDll
;
;       DESCRIPTION:    Load a DLL
;
;		PARAMETERS:		DLL name
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosLoadDll

_RdosLoadDll	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	les di,[bp+6]
	LoadDll
	jc rldllFail
;
    mov ax,bx
    jmp rldllDone

rldllFail:
    xor ax,ax

rldllDone:
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosLoadDll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosFreeDll
;
;       DESCRIPTION:    Free a DLL
;
;		PARAMETERS:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosFreeDll

_RdosFreeDll	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	FreeDll
;
	pop bx
	pop bp
	ret
_RdosFreeDll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadResource
;
;       DESCRIPTION:    Read resource
;
;		PARAMETERS:		Handle
;						ID
;						Buf
;						Size
;
;		RETURNS:		Size read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosReadResource

_RdosReadResource	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push bx
	push ecx
	push esi
	push edi
;
	mov bx,[bp+6]
	mov ax,[bp+8]
	mov dx,6
	GetDllResource
	jc read_resource_fail
;
	cmp cx,[bp+14]
	jbe read_resource_copy
;
	mov cx,[bp+14]

read_resource_copy:
	les di,[bp+10]
	movzx edi,di
	movzx ecx,cx
	mov ax,cx
	push ecx
	shr cx,2
	rep movs dword ptr es:[edi],[esi]
	pop ecx
	and ecx,3
	rep movs byte ptr es:[edi],[esi]
	jmp read_resource_done
	
read_resource_fail:
	xor eax,eax

read_resource_done:
	pop edi
	pop esi
	pop ecx
	pop bx
	pop es
	pop ds
	pop bp
	ret
_RdosReadResource	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenSysIni
;
;       DESCRIPTION:    Open system ini file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosOpenSysIni

_RdosOpenSysIni	Proc far
	push bx
;
	OpenSysIni
	jc osiFail
;
	mov ax,bx
	jmp osiDone

osiFail:
	xor ax,ax

osiDone:
	pop bx
	ret
_RdosOpenSysIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosCloseIni
;
;       DESCRIPTION:    Close ini file
;
;		PARAMETERS:		handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosCloseIni

_RdosCloseIni	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	CloseIni
;
	pop bx
	pop bp
	ret
_RdosCloseIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGotoIniSection
;
;       DESCRIPTION:    Goto ini section
;
;		PARAMETERS:		handle
;						SectionName
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosGotoIniSection

_RdosGotoIniSection	Proc far
	push bp
	mov bp,sp
	push es
	push bx
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	GotoIniSection
	jc gisFail
;
	mov ax,1
	jmp gisDone

gisFail:
	xor ax,ax

gisDone:
	pop di
	pop bx
	pop es
	pop bp
	ret
_RdosGotoIniSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosRemoveIniSection
;
;       DESCRIPTION:    Remove ini section
;
;		PARAMETERS:		handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosRemoveIniSection

_RdosRemoveIniSection	Proc far
	push bp
	mov bp,sp
	push bx
;
	mov bx,[bp+6]
	RemoveIniSection
	jc risFail
;
	mov ax,1
	jmp risDone

risFail:
	xor ax,ax

risDone:
	pop bx
	pop bp
	ret
_RdosRemoveIniSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosReadIni
;
;       DESCRIPTION:    Read ini var
;
;		PARAMETERS:		handle
;						VarName
;                       Str
;                       MaxSize
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosReadIni

_RdosReadIni	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push bx
	push cx
	push si
	push di
;
	mov bx,[bp+6]
	lds si,[bp+8]
	les di,[bp+12]
	mov cx,[bp+16]
	ReadIni
	jc riFail
;
	mov ax,1
	jmp riDone

riFail:
	xor ax,ax

riDone:
    pop di
	pop si
	pop cx
	pop bx
	pop es
	pop ds
	pop bp
	ret
_RdosReadIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosWriteIni
;
;       DESCRIPTION:    Write ini var
;
;		PARAMETERS:		handle
;						VarName
;                       Str
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosWriteIni

_RdosWriteIni	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push bx
	push si
	push di
;
	mov bx,[bp+6]
	lds si,[bp+8]
	les di,[bp+12]
	WriteIni
	jc wiFail
;
	mov ax,1
	jmp wiDone

wiFail:
	xor ax,ax

wiDone:
    pop di
	pop si
	pop bx
	pop es
	pop ds
	pop bp
	ret
_RdosWriteIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosDeleteIni
;
;       DESCRIPTION:    Delete ini var
;
;		PARAMETERS:		handle
;						VarName
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosDeleteIni

_RdosDeleteIni	Proc far
	push bp
	mov bp,sp
	push ds
	push bx
	push si
;
	mov bx,[bp+6]
	lds si,[bp+8]
	DeleteIni
	jc diFail
;
	mov ax,1
	jmp diDone

diFail:
	xor ax,ax

diDone:
	pop si
	pop bx
	pop ds
	pop bp
	ret
_RdosDeleteIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosCreateFileDrive
;
;       DESCRIPTION:    Create file drive
;
;		PARAMETERS:		Size
;						FsName
;						FileName
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosCreateFileDrive

_RdosCreateFileDrive	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push ecx
	push si
	push di
;
	mov ecx,[bp+6]
	lds si,[bp+10]
	les di,[bp+14]
	CreateFileDrive
	jnc cfdDone
;
	xor al,al

cfdDone:
	movzx ax,al
;
	pop di
	pop si
	pop cx
	pop es
	pop ds
	pop bp
	ret
_RdosCreateFileDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenFileDrive
;
;       DESCRIPTION:    Open file drive
;
;		PARAMETERS:		FileName
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _RdosOpenFileDrive

_RdosOpenFileDrive	Proc far
	push bp
	mov bp,sp
	push es
	push di
;
	les di,[bp+6]
	OpenFileDrive
	jnc ofdDone
;
	xor al,al

ofdDone:
	movzx ax,al
;
	pop di
	pop es
	pop bp
	ret
_RdosOpenFileDrive	Endp

code	ENDS

	END
