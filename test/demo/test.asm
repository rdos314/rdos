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
; TEST.ASM
; Test application
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME test

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

GateSize = 16

INCLUDE ..\os\system.def
INCLUDE ..\os\system.inc
INCLUDE ..\os\user.def
INCLUDE ..\os\user.inc
INCLUDE ..\os\state.def

data	SEGMENT byte public 'DATA'

float_string	DB 256 DUP(?)

buf		DW 4096 DUP(?)

data	ENDS

code    SEGMENT byte public 'CODE'

	.386p

	assume cs:code

	extrn float_to_string:near

host_name	DB 'www.rdos.net',0
host_ip		DB 192,168,12,108

val	DT 4.566

FilemapName	DB 'Test', 0

filename	DB 'e:\rdos\test\kernel.map',0

test_name	DB 'Test Section Thread', 0

draw_string	DB 'RDOS operating system', 0

int21Handler:
	int 3
	iret

int31Handler:
	int 3
	iret

test_thread:
	int 3
;
	LeaveUserSection
	EnterUserSection
	jmp test_thread

divi	DW 1111h

read_keyboard	Proc near
	ReadKeyEvent
	ret
read_keyboard	Endp

read_mouse	Proc near
	GetMousePosition
	ret
read_mouse	Endp
	
init:
        int 3
;
    CreateWait
	mov ecx,OFFSET read_keyboard
	AddWaitForKeyboard
    mov ecx,OFFSET read_mouse
    AddWaitForMouse

wait_loop:
	IsWaitIdle
    GetSystemTime
    add eax,60 * 1192000
    adc edx,0
    mov ecx,11111
    WaitWithTimeout
	push OFFSET wait_ret
	push cx
	retn

wait_ret:
	jmp wait_loop

    StopWait
    CloseWait
	GetCursorPosition
	push cx
	push dx
;
	mov ax,10
	mov cx,ax
;
	mov ax,20
	mov dx,ax
;
	SetCursorPosition
	GetCharAttrib
	push ax
	mov al,bh
	SetForeColor
	mov al,bl
	SetBackColor
	pop ax
	WriteChar
;
	int 3
	mov ax,32
	mov cx,800
	mov dx,600
	SetVideoMode
	push bx
;
	push bx
	push cx
	push dx
	CreateBitmap
	mov ax,LGOP_NONE
	SetLgop
	mov eax,0FFh
	SetDrawColor
	SetFilledStyle
;
	mov cx,50
	mov dx,100
	mov si,200
	mov di,150
	DrawRect
;
	mov eax,0FF00h
	SetDrawColor
;
	mov ax,LGOP_ADD
	SetLgop
;
	mov cx,100
	mov dx,150
	mov si,150
	mov di,200
	DrawRect
;
	SetHollowStyle
;
	mov eax,0FF0000h
	SetDrawColor
;
	mov cx,50
	mov dx,100
	mov si,200
	mov di,150
	DrawRect
;
	mov cx,350
	mov dx,100
	mov si,50
	mov di,300
	DrawLine
;
	mov cx,350
	mov dx,300
	mov si,50
	mov di,100
	DrawLine
;
	mov cx,350
	mov dx,300
	mov si,350
	mov di,100
	DrawLine
;
	mov cx,50
	mov dx,100
	mov si,50
	mov di,300
	DrawLine
;
	mov cx,350
	mov dx,100
	mov si,50
	mov di,100
	DrawLine
;
	mov cx,350
	mov dx,300
	mov si,50
	mov di,300
	DrawLine
;
    SetFilledStyle
	mov cx,200
	mov dx,300
	mov si,150
	mov di,250
	DrawRect
	mov eax,0707000h
	SetDrawColor	
	DrawEllipse
;
	SetHollowStyle
	mov ax,LGOP_NONE
	SetLgop
	mov eax,07070h
	SetDrawColor
	DrawEllipse
;
    SetFilledStyle
    mov cx,300
    mov dx,50
    mov si,250
    mov di,250
    DrawEllipse
	mov ax,bx
	pop dx
	pop cx
	pop bx
	push ax
	mov ax,LGOP_ADD
	SetLgop
	pop ax
	xor esi,esi
	xor edi,edi
	Blit
	mov cx,250
	mov dx,250
;
	push bx
	mov bx,ax
	CloseBitmap
	pop bx
	mov ax,bx
	mov si,100 ; src y
	shl esi,16
	mov si,50 ; src x
	mov di,300 ; dest y
	shl edi,16
	mov di,450 ; dest x
	Blit
;
	push bx
	mov ax,50
	OpenFont
	mov ax,cs
	mov es,ax
	mov di,OFFSET draw_string
	mov ax,bx
	pop bx
	SetFont
	mov ax,LGOP_NONE
	SetLgop
	mov eax,0FFFFh
	SetDrawColor
	mov cx,40
	mov dx,111
	DrawString
;
	int 3
	mov bx,4
	push bx
    mov ax,1
    mov cx,30
    mov dx,30
    CreateBitmap
    mov ax,LGOP_NONE
    SetLgop
	SetFilledStyle
    push cx
    push dx
    mov si,cx
    mov di,dx
    xor cx,cx
    xor dx,dx
    DrawEllipse
    pop dx
    pop cx
    push bx
;
    mov ax,16
    CreateBitmap
    mov ax,LGOP_NONE
    SetLgop
    mov eax,07000h
    SetDrawColor
	SetFilledStyle
    push cx
    push dx
    mov si,cx
    mov di,dx
    xor cx,cx
    xor dx,dx
    DrawEllipse
    pop dx
    pop cx
;
    pop ax
    pop si
    push bx
    push cx
    push dx
    mov cx,bx
    mov dx,ax
    mov bx,si
    mov ax,LGOP_NONE
    CreateSprite
;
    mov cx,100
    mov dx,100
    MoveSprite
    ShowSprite
    mov cx,102

sprite_loop:
    mov dx,102
    MoveSprite
	mov dx,104
	MoveSprite
	mov dx,100
	MoveSprite
	mov cx,102
	MoveSprite
	mov cx,104
	MoveSprite
	mov cx,100
	MoveSprite
	jmp sprite_loop
	HideSprite
    CloseSprite    
    pop bx
    pop dx
    pop cx

;
	int 3
	mov ax,3
	SetVideoMode
	mov ax,-5050
	mov bl,-4
;	div cs:divi
	idiv bl
	CreateBlockedUserSection
;
	mov ax,cs
	mov ds,ax
	mov es,ax
	mov si,OFFSET test_thread
	mov di,OFFSET test_name
	mov ax,2
	mov cx,1000h
	CreateThread
;	
	EnterUserSection
	EnterUserSection
	LeaveUserSection
	LeaveUserSection
	int 3
;
	DeleteUserSection
	mov ax,cs
	mov es,ax
	mov di,OFFSET filename
	OpenFile
;
	mov eax,22222h
	SetFileSize
;
	mov eax,22221h
	SetFileSize
;
	mov eax,22223h
	SetFileSize
;
	mov eax,1C001h
	SetFileSize
;
	mov eax,1C000h
	SetFileSize
;
	mov eax,1C001h
	SetFileSize
;
	CloseFile
;
	xor cx,cx
	mov ax,cs
	mov es,ax
	mov di,OFFSET filename
	CreateFile
;
	mov eax,12345h
	SetFilePos
;
	mov ax,cs
	mov es,ax
	mov di,OFFSET host_name
	mov cx,13
	WriteFile
;
	mov eax,12345h
	SetFilePos
;
	mov ax,SEG data
	mov es,ax
	mov di,OFFSET buf
	mov cx,13
	ReadFile
;
	CloseFile
;
	mov eax,3000h
	CreateMapping
	push bx
	mov ax,cs
	mov es,ax
	mov di,OFFSET FilemapName
	mov eax,3000h
	CreateNamedMapping
	push bx
	OpenNamedMapping
	CloseMapping
	pop bx
	mov eax,3000h
	AllocateAppMem
	xor di,di
	xor eax,eax
	mov ecx,3000h
	MapView
	mov di,1FFFh
	mov ax,2345h
	stosw
	SyncMapping
	UnmapView
	FreeMem
	CloseMapping
	pop bx
	CloseMapping
	int 3

	mov ax,cs
	mov es,ax
	mov di,OFFSET host_name
	NameToIp
	int 3
;
	mov eax,6000
	mov edx,dword ptr cs:host_ip
	mov ecx,4000h
	xor si,si
	mov di,80
	OpenTcpConnection
;
	mov eax,50
	WaitMilliSec
	jmp init

code    ENDS

	END init
