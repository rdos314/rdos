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

include ..\os\user.def
include ..\os\user.inc
						
		NAME rdos

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

code	SEGMENT byte public 'CODE'

	assume cs:code

	.386p

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TASK_START
;
;		description:	Task startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

task_start:
	pop si
	pop di
	mov ds,bp
	push fs
	push bx
	push di
	push si
	push gs
	push dx
	xor ax,ax
	mov fs,ax
	mov gs,ax
	retf

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CREATE_TASK
;
;		description:	Create a task
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _CreateTask

task_callb	EQU 6
task_name	EQU 10
task_data	EQU 14
task_stack	EQU 18

_CreateTask	PROC far
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
_CreateTask	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitMilli
;
;		description:	Wait a number of milliseconds
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _WaitMilli

_WaitMilli	Proc far
	push bp
	mov bp,sp
	mov eax,[bp+6]
	WaitMilliSec
	pop bp
	ret
_WaitMilli	Endp

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
;		NAME:			SetVgaMode
;
;		description:	SetVgaMode()
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _SetVgaMode

_SetVgaMode	Proc far
	SetVgaMode
	ret
_SetVgaMode	Endp

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
;		NAME:			SetFont
;
;		description:	SetFont(height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _SetFont

_SetFont	Proc far
	push bp
	mov bp,sp
	mov ax,[bp+6]
	SetFont
	pop bp
	ret
_SetFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FillRect
;
;		description:	int FillRect(startX, startY, endX, endY)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _FillRect

frStartX	EQU 6
frStartY	EQU 8
frEndX		EQU 10
frEndY		EQU 12

_FillRect	Proc far
	push bp
	mov bp,sp
	mov ax,[bp].frStartX
	mov bx,[bp].frStartY
	mov cx,[bp].frEndX
	mov dx,[bp].frEndY
	FillRect
	pop bp
	ret
_FillRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DrawMonoBitmap
;
;		description:	ivoid DrawMonoBitmap(bitmap, startX, startY, endX, endY)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _DrawMonoBitmap

dmBitmap	EQU 6
dmStartX	EQU 10
dmStartY	EQU 12
dmEndX		EQU 14
dmEndY		EQU 16

_DrawMonoBitmap	Proc far
	push bp
	mov bp,sp
	push es
;
	mov ax,[bp].dmStartX
	mov bx,[bp].dmStartY
	mov cx,[bp].dmEndX
	mov dx,[bp].dmEndY
	mov es,[bp].dmBitmap+2
	DrawMono
;
	pop es
	pop bp
	ret
_DrawMonoBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetCharWidth
;
;		description:	int GetCharWidth(ch)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _GetCharWidth

_GetCharWidth	Proc far
	push bp
	mov bp,sp
	mov al,[bp+6]
	GetCharWidth
	mov ax,cx
	pop bp
	ret
_GetCharWidth	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DrawChar
;
;		description:	int DrawChar(x, y, ch)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _DrawChar

dcX		EQU 6
dcY		EQU 8
dcCh	EQU 10

_DrawChar	Proc far
	push bp
	mov bp,sp
	mov cx,[bp].dcX
	mov dx,[bp].dcY
	mov al,[bp].dcCh
	DrawChar
	mov ax,cx
	pop bp
	ret
_DrawChar	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetStringWidth
;
;		description:	int GetStringWidth(str)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _GetStringWidth

_GetStringWidth	Proc far
	push bp
	mov bp,sp
	push es
	push di
	les di,[bp+6]
	GetStringWidth
	mov ax,cx
	pop di
	pop es
	pop bp
	ret
_GetStringWidth	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DrawString
;
;		description:	int DrawString(x, y, str)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _DrawString

dsX		EQU 6
dsY		EQU 8
dsStr	EQU 10

_DrawString	Proc far
	push bp
	mov bp,sp
	push es
	push di
	mov cx,[bp].dsX
	mov dx,[bp].dsY
	les di,[bp].dsStr
	DrawString
	mov ax,cx
	pop di
	pop es
	pop bp
	ret
_DrawString	Endp

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
;		NAME:			AllocateMem
;
;		description:	void *AllocateMem(size)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _AllocateMem

_AllocateMem	Proc far
	push bp
	mov bp,sp
	push es
	mov eax,[bp+6]
	AllocateLocalMem
	mov dx,es
	xor ax,ax
	pop es
	pop bp
	ret
_AllocateMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FreeMem
;
;		description:	void FreeMem(ptr)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _FreeMem

_FreeMem	Proc far
	push bp
	mov bp,sp
	mov es,[bp+8]
	FreeMem
	pop bp
	ret
_FreeMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetSysTime
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

	public _GetSysTime

gtrtYear	EQU 6
gtrtMonth	EQU 10
gtrtDay		EQU 14
gtrtHour	EQU 18
gtrtMin		EQU 22
gtrtSec		EQU 26
gtrtMilli	EQU 30

_GetSysTime	Proc far
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
_GetSysTime	Endp

FCLK DD 1179648

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			_OpenTimer
;
;		DESCRIPTION:	opens timer system (starts counting ticks)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _OpenTimer

_OpenTimer	Proc far
	mov ax,word ptr cs:FCLK
	mov dx,word ptr cs:FCLK+2
	ret
_OpenTimer	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			_CloseTimer
;
;		DESCRIPTION:	closes timer system (stops counting ticks)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _CloseTimer

_CloseTimer	Proc far
	ret
_CloseTimer	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			_ReadTimerTicks
;
;		DESCRIPTION:	reads current number of timer ticks
;
;		RETURNS:		timer chip ticks
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _ReadTimerTicks

_ReadTimerTicks	Proc far
	GetSystemTime
	push eax
	pop ax
	pop dx
	ret
_ReadTimerTicks	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			_CheckTimerRunning
;
;		DESCRIPTION:	check if timer is running or if timeout has occured
;
;		PARAMETERS:		expire_time		expiration time
;
;		RETURNS:		TRUE if timer is running, FALSE if timeout occured
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _CheckTimerRunning

_CheckTimerRunning	Proc far
	push bp
	mov bp,sp
	push ds
	GetSystemTime
	push eax
	pop ax
	pop dx
	sub ax,[bp+6]
	sbb dx,[bp+8]
	test dh,80h
	jnz check_timer_running
	xor ax,ax
	jmp check_timer_end
check_timer_running:
	mov ax,1
check_timer_end:
	pop ds
	pop bp
	ret
_CheckTimerRunning	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenCom
;
;		description:	Open serial port
;
;		PARAMETERS:		port_base		Serial port IO base
;						port_irq		IRQ
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

	public _OpenCom

port_base		EQU 6
port_irq		EQU 8
baud_divisor	EQU 10
parity			EQU 12
data_bits		EQU 14
stop_bits		EQU 16
send_buf_size	EQU 18
rec_buf_size	EQU 20

_OpenCom	Proc far
	push bp
	mov bp,sp
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
	pop bp
	ret
_OpenCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseCom
;
;		description:	Close serial port
;
;		PARAMETERS:		port_handle		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _CloseCom

_CloseCom	Proc far
	push bp
	mov bp,sp
	mov bx,[bp+6]
	CloseCom
	pop bp
	ret
_CloseCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FlushCom
;
;		description:	Flush serial port buffers
;
;		PARAMETERS:		port_handler	Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _FlushCom

_FlushCom	Proc far
	push bp
	mov bp,sp
	mov bx,[bp+6]
	FlushCom
	pop bp
	ret
_FlushCom	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			PollCom
;
;		description:	Check if data is available
;
;		PARAMETERS:		hport		Port handle
;
;		RETURNS:		> 0			Number of bytes available
;						FALSE		buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _PollCom

_PollCom	PROC far
	push bp
	mov bp,sp
	mov bx,[bp+6]
	PollCom
	pop bp
	ret
_PollCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WaitForCom
;
;		description:	Wait for data
;
;		PARAMETERS:		hport		Port handle
;						timeout		ms timeout
;
;		RETURNS:		> 0			Number of bytes available
;						FALSE		buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _WaitForCom

_WaitForCom	PROC far
	push bp
	mov bp,sp
	mov bx,[bp+6]
	mov eax,[bp+8]
	WaitForCom
	pop bp
	ret
_WaitForCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadCom
;
;		description:	Read a byte from port
;
;		PARAMETERS:		hport		Port handle
;
;		RETURNS:		ch			received char
;						-1			buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _ReadCom

_ReadCom	PROC far
	push bp
	mov bp,sp
	mov bx,[bp+6]
	ReadCom
	pop bp
	ret
_ReadCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteCom
;
;		description:	Send a byte to port
;
;		PARAMETERS:		hport		Port handle
;						ch			Data
;
;		RETURNS:		0			OK
;						-1			buffer full
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _WriteCom

_WriteCom	PROC far
	push bp
	mov bp,sp
	mov bx,[bp+6]
	mov al,[bp+8]
	WriteCom
	pop bp
	ret
_WriteCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SetDtr
;
;		description:	Set DTR
;
;		PARAMETERS:		hport		Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _SetDtr

_SetDtr	Proc far
	push bp
	mov bp,sp
	mov bx,[bp+6]
	SetDtr
	pop bp
	ret
_SetDtr	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ResetDtr
;
;		description:	Reset DTR
;
;		PARAMETERS:		hport		Port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _ResetDtr

_ResetDtr	Proc far
	push bp
	mov bp,sp
	mov bx,[bp+6]
	ResetDtr
	pop bp
	ret
_ResetDtr	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			OpenCbus
;
;		DESCRIPTION:	Opens CBUS channel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _OpenCbus

base_addr	EQU 6
irq			EQU 8

_OpenCbus	PROC FAR
	push bp
	mov bp,sp
	mov dx,[bp].base_addr
	mov al,[bp].irq
	OpenCbus
	mov ax,bx
	pop bp
	ret
_OpenCbus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			CloseCbus
;
;		DESCRIPTION:	Closes CBUS channel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _CloseCbus

_CloseCbus	PROC FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	CloseCbus
	pop bp
	ret
_CloseCbus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			ResetCbus
;
;		DESCRIPTION:	Reset CBUS channel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _ResetCbus

_ResetCbus	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	FlushCbus
	pop bp
	ret
_ResetCbus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			PollCbus
;
;		DESCRIPTION:	Test if any char is pending in receive buffer.
;
;		RETURNS:		> 0			Number of bytes available
;						FALSE		buffer empty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _PollCbus

_PollCbus	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	PollCbus
	pop bp
	ret
_PollCbus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			ReadCbus
;
;		DESCRIPTION:	Read a byte from cbus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _ReadCbus

_ReadCbus	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	ReadCbus
	pop bp
	ret
_ReadCbus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			WriteCbus
;
;		DESCRIPTION:	Write a byte to cbus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _WriteCbus

_WriteCbus	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	mov al,[bp+8]
	WriteCbus
	pop bp
	ret
_WriteCbus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			OpenFile
;
;		DESCRIPTION:	Opens a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _OpenFile

_OpenFile	PROC	FAR
	push bp
	mov bp,sp
	push es
	push di
	les di,[bp+6]
	mov cl,[bp+10]
	OpenFile
	jc OpenFileFailed
	mov ax,bx
	jmp OpenFileDone

OpenFileFailed:
	xor ax,ax

OpenFileDone:
	pop di
	pop es
	pop bp
	ret
_OpenFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			CloseFile
;
;		DESCRIPTION:	Close a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _CloseFile

_CloseFile	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	CloseFile
	pop bp
	ret
_CloseFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			GetFileSize
;
;		DESCRIPTION:	Get size of a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _GetFileSize

_GetFileSize	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	GetFileSize
	jc GetFileSizeFail
	push eax
	pop ax
	pop dx
	jmp GetFileSizeDone

GetFileSizeFail:
	xor ax,ax
	xor dx,dx

GetFileSizeDone:
	pop bp
	ret
_GetFileSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			SetFileSize
;
;		DESCRIPTION:	Set size of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _SetFileSize

_SetFileSize	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	mov eax,[bp+8]
	SetFileSize
	pop bp
	ret
_SetFileSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			GetFilePos
;
;		DESCRIPTION:	Get position in a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _GetFilePos

_GetFilePos	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	GetFilePos
	jc GetFilePosFail
	push eax
	pop ax
	pop dx
	jmp GetFilePosDone

GetFilePosFail:
	xor ax,ax
	xor dx,dx

GetFilePosDone:
	pop bp
	ret
_GetFilePos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			SetFilePos
;
;		DESCRIPTION:	Set position in file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _SetFilePos

_SetFilePos	PROC	FAR
	push bp
	mov bp,sp
	mov bx,[bp+6]
	mov eax,[bp+8]
	SetFilePos
	pop bp
	ret
_SetFilePos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			ReadFile
;
;		DESCRIPTION:	Read data from file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _ReadFile

_ReadFile	PROC	FAR
	push bp
	mov bp,sp
	push es
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	mov cx,[bp+12]
	ReadFile
;
	pop di
	pop es
	pop bp
	ret
_ReadFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			WriteFile
;
;		DESCRIPTION:	Write data to file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _WriteFile

_WriteFile	PROC	FAR
	push bp
	mov bp,sp
	push es
	push di
;
	mov bx,[bp+6]
	les di,[bp+8]
	mov cx,[bp+12]
	WriteFile
;
	pop di
	pop es
	pop bp
	ret
_WriteFile	ENDP

code	ENDS

	END
