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
; WINKRNL.ASM
; 16-bit kernel.dll emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                                
		NAME kernel

GateSize = 16

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\user.inc

.386p

	public __ahincr
__ahincr	equ 8

	public __ahshift
__ahshift	equ 3

	public __0040
	public __A000
	public __B000
	public __B800
	public __F000

code    SEGMENT byte public use16 'CODE'

        assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitTask
;
;       DESCRIPTION:    Inits task
;
;	    RETURNS:		AX		0 for failure, 1 for success
;						CX		stack limit
;						DI		module handle
;						DX		nCmdShow (0)
;						ES		PSP address
;						ES:BX	command line
;						SI		previous module handle (0)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public InitTask

InitTask	Proc far
	mov ah,62h
	int 21h
	mov bx,es
	mov bx,80h
	mov ax,1
	mov cx,sp
	str di
	xor dx,dx
	xor si,si
	ret
InitTask	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCurrentTask
;
;       DESCRIPTION:    Get current task
;
;	    RETURNS:		AX		Current task
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetCurrentTask

GetCurrentTask	Proc far
	str ax
	ret
GetCurrentTask	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           _WaitEvent
;
;       DESCRIPTION:    Wait for event (ignored)
;
;		PARAMETERS:		TaskId		task id
;
;	    RETURNS:		0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public _WaitEvent

_WaitEvent	Proc far
	xor ax,ax
	ret 2
_WaitEvent	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetFreeSpace
;
;       DESCRIPTION:    Gets available memory in OS
;
;       PARAMETERS:     Flag       unused         
;
;	    RETURNS:		Free system memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GetFreeSpace

GetFreeSpace	Proc far
    AvailableLocalLinear
    push eax
    pop ax
    pop dx
    ret 2
GetFreeSpace	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalCompact
;
;       DESCRIPTION:    Compacts memory (not done)
;
;       PARAMETERS:     MinFree    minimum free memory   
;
;	    RETURNS:		Largest free block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalCompact

GlobalCompact	Proc far
    AvailableLocalLinear
    push eax
    pop ax
    pop dx
    ret 4
GlobalCompact	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalFlags
;
;       DESCRIPTION:    Flags for memory handle (not used)
;
;       PARAMETERS:     Mem      handle to enquire
;
;	    RETURNS:		Flags (always 0)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalFlags

GlobalFlags	Proc far
    int 3
    xor ax,ax
    ret 2
GlobalFlags	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalHandle
;
;       DESCRIPTION:    Returns handle and selector for selector
;
;       PARAMETERS:     Selector      selector to enquire
;
;	    RETURNS:		loword is handle and highword is selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalHandle

GlobalHandle	Proc far
    push bp
    mov bp,sp
    mov ax,[bp+6]
    mov dx,ax
    pop bp
    ret 2
GlobalHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalSize
;
;       DESCRIPTION:    Returns size of memory block
;
;       PARAMETERS:     Mem       handle
;
;	    RETURNS:		size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalSize

GlobalSize	Proc far
    push bp
    mov bp,sp
    lsl eax,[bp+6]
    push eax
    pop ax
    pop dx
    pop bp
    ret 2
GlobalSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalFix
;
;       DESCRIPTION:    Fixes handle in linear memory (not done)
;
;       PARAMETERS:     Mem      handle to fix
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalFix

GlobalFix	Proc far
    int 3
	xor ax,ax
    ret 2
GlobalFix	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalUndix
;
;       DESCRIPTION:    Unfixes handle in linear memory (not done)
;
;       PARAMETERS:     Mem      handle to unfix
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalUnfix

GlobalUnfix	Proc far
    int 3
	xor ax,ax
    ret 2
GlobalUnfix	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalLRUNewest
;
;       DESCRIPTION:    Ignored
;
;       PARAMETERS:     Mem       handle
;
;	    RETURNS:		handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalLRUNewest

GlobalLRUNewest	Proc far
    push bp
    mov bp,sp
    mov ax,[bp+6]
    pop bp
    ret 2
GlobalLRUNewest	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalLRUOldest
;
;       DESCRIPTION:    Ignored
;
;       PARAMETERS:     Mem       handle
;
;	    RETURNS:		handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalLRUOldest

GlobalLRUOldest	Proc far
    push bp
    mov bp,sp
    mov ax,[bp+6]
    pop bp
    ret 2
GlobalLRUOldest	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalNotify
;
;       DESCRIPTION:    ignored
;
;       PARAMETERS:     NotifyProc  notification procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalNotify

GlobalNotify	Proc far
    int 3
    ret 4
GlobalNotify	Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;      NAME:           GlobalPageLock
;
;      DESCRIPTION:    ignored
;
;      PARAMETERS:     Selector      selector to lock in physical memory
;
;	   RETURNS:		   Page lock count (0)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalPageLock

GlobalPageLock		Proc far
    int 3
    xor ax,ax
    ret 2
GlobalPageLock		Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;      NAME:          GlobalPageUnlock
;
;      DESCRIPTION:   ignored
;
;      PARAMETERS:    Selector      selector to unlock in physical memory
;
;	   RETURNS:		  Page lock count (0)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalPageUnlock

GlobalPageUnlock		Proc far
    int 3
    xor ax,ax
    ret 2
GlobalPageUnlock		Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LockSegment
;
;       DESCRIPTION:    Ignored
;
;       PARAMETERS:     Selector      selector to lock in linear memory
;
;	    RETURNS:		handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public LockSegment

LockSegment	Proc far
    push bp
    mov bp,sp
    mov ax,[bp+6]
    pop bp
    ret 2
LockSegment	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnlockSegment
;
;       DESCRIPTION:    Ignored
;
;       PARAMETERS:     Selector      selector to unlock in linear memory
;
;	    RETURNS:		handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public UnlockSegment

UnlockSegment	Proc far
    push bp
    mov bp,sp
    mov ax,[bp+6]
    pop bp
    ret 2
UnlockSegment	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalAlloc
;
;       DESCRIPTION:    Allocate global memory
;
;       PARAMETERS:     Flag       type of block, ignored
;		    	        Bytes      number of bytes to allocate
;
;	    RETURNS:		Memory handle or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalAlloc

GlobalAlloc	Proc far
    push bp
    push es
    mov bp,sp
    mov eax,[bp+8]
    AllocateLocalMem
    mov ax,es
    pop es
    pop bp
    ret 6
GlobalAlloc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;      NAME:           GlobalReAlloc
;
;      DESCRIPTION:    Changes global memory block
;
;      PARAMETERS:     Mem        handle to memory block
;		   	           Bytes      number of bytes to allocate
;			           Flag       type of block, ignored
;
;	   RETURNS:		   Memory handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        public GlobalReAlloc

GlobalReAlloc		Proc far
    int 3
    xor ax,ax
    ret 8
GlobalReAlloc		Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalLock
;
;       DESCRIPTION:    Lock global memory
;
;       PARAMETERS:     Mem      handle to lock
;
;	    RETURNS:		address of block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GlobalLock

GlobalLock	Proc far
	push bp
	mov bp,sp
    mov dx,[bp+6]
    xor ax,ax
	pop bp
	ret 2
GlobalLock	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalUnlock
;
;       DESCRIPTION:    Unlock global memory
;
;       PARAMETERS:     Mem      handle to lock
;
;	    RETURNS:		always TRUE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GlobalUnlock

GlobalUnlock	Proc far
    xor ax,ax
	ret 2
GlobalUnlock	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalFree
;
;       DESCRIPTION:    Free global memory
;
;       PARAMETERS:     Mem      handle to lock
;
;	    RETURNS:		0 or original handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GlobalFree

GlobalFree	Proc far
	push bp
	mov bp,sp
	push es
	mov es,[bp+6]
	FreeMem
	pop es
    xor ax,ax
	ret 2
GlobalFree	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalDosAlloc
;
;       DESCRIPTION:    Allocate dos memory
;
;       PARAMETERS:     Bytes      number of bytes to allocate
;
;	    RETURNS:		segment in hiorder word and selector in loworder word
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GlobalDosAlloc

GlobalDosAlloc	Proc far
	push bp
	mov bp,sp
	push es
	mov eax,[bp+6]
	AllocateDosMem
    mov bx,es
    mov ax,8
    int 31h
    push cx
    push dx
	pop eax
	shr eax,4
    mov dx,ax
    mov ax,bx
	pop es
	pop bp
	ret 4
GlobalDosAlloc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GlobalDosFree
;
;       DESCRIPTION:    Free dos memory
;
;       PARAMETERS:     Selector     selector of dos memory block
;
;	    RETURNS:		0 if ok otherwise Selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GlobalDosFree

GlobalDosFree	Proc far
	push bp
	mov bp,sp
	push es
	mov es,[bp+6]
	FreeMem
	pop es
	xor ax,ax
	pop bp
	ret 2
GlobalDosFree	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LoadLibrary
;
;       DESCRIPTION:    Load DLL
;
;       PARAMETERS:     LibFileName		name of DLL to load
;
;	    RETURNS:		Instance handle or error code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public LoadLibrary

LoadLibrary	Proc far
	push bp
	mov bp,sp
	int 3
	xor ax,ax
	pop bp
	ret 4
LoadLibrary	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeLibrary
;
;       DESCRIPTION:    Unload DLL
;
;       PARAMETERS:     LibModule       Instance handle of DLL to unload
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public FreeLibrary

FreeLibrary	Proc far
	push bp
	mov bp,sp
    int 3
	xor ax,ax
	pop bp
	ret 2
FreeLibrary	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetModuleFileName
;
;       DESCRIPTION:    Get full path of module
;
;       PARAMETERS:     Module       Instance handle
;						FileName     Returned filename
;						Size         Max size of FileName
;
;	    RETURNS:     	Actual size of filename
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetModuleFileName

GetModuleFileName	Proc far
	push bp
	mov bp,sp
	xor ax,ax
	pop bp
	ret 8
GetModuleFileName	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetModuleHandle
;
;       DESCRIPTION:    Get handle of module
;
;       PARAMETERS:     ModuleName   Module name
;
;	    RETURNS:     	Module handle or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetModuleHandle

GetModuleHandle	Proc far
	push bp
	mov bp,sp
	int 3
	xor ax,ax
	pop bp
	ret 4
GetModuleHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetModuleUsage
;
;       DESCRIPTION:    Get module reference count
;
;       PARAMETERS:     Module	   Module handle
;
;	    RETURNS:     	Usage count
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetModuleUsage

GetModuleUsage	Proc far
	push bp
	mov bp,sp
    int 3
    xor ax,ax
	pop bp
	ret 2
GetModuleUsage	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProcAddress
;
;       DESCRIPTION:    Get address of process in module
;
;       PARAMETERS:     Module	   Module handle
;		                ProcName   Name of procedure or ordinal #
;
;	    RETURNS:     	Address of process or nil
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetProcAddress

GetProcAddress	Proc far
	push bp
	mov bp,sp
    int 3
    xor ax,ax
    xor dx,dx
	pop bp
	ret 6
GetProcAddress	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MakeProcInstance
;
;       DESCRIPTION:    Make instance procedure (not done)
;
;       PARAMETERS:     Proc	 	procedure
;						Instance	instance handle
;
;	    RETURNS:     	Address of procedure instance
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public MakeProcInstance

MakeProcInstance	Proc far
	push bp
	mov bp,sp
	mov ax,[bp+8]
	mov dx,[bp+10]
	pop bp
	ret 6
MakeProcInstance	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeProcInstance
;
;       DESCRIPTION:    Free instance procedure (not done)
;
;       PARAMETERS:     Proc	 	procedure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public FreeProcInstance

FreeProcInstance	Proc far
	ret 4
FreeProcInstance	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocDStoCSAlias
;
;       DESCRIPTION:    Maps data selector as code selector
;
;       PARAMETERS:     Selector   Data selector
;
;	    RETURNS:     	Code selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public AllocDStoCSAlias

AllocDStoCSAlias	Proc far
	push bp
	mov bp,sp
    mov ax,0Ah
    mov bx,[bp+6]
    int 31h
	pop bp
	ret 2
AllocDStoCSAlias	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocSelector
;
;       DESCRIPTION:    Allocates new selector and optionally inits with old
;
;       PARAMETERS:     Selector   Input selector
;
;	    RETURNS:     	New selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public AllocSelector

AllocSelector	Proc far
	push bp
	mov bp,sp
	sub sp,8
	push es
	push di
    mov cx,1
    mov ax,0
    int 31h
    push ax
    mov bx,[bp+6]
    or bx,bx
    jz AllocSelectorNew
	mov ax,ss
	mov es,ax
	lea di,[bp-8]
    mov ax,0Bh
    int 31h
    pop bx
    mov ax,0Ch
    int 31h
	jmp AllocSelectorDone
AllocSelectorNew:
	pop bx
AllocSelectorDone:
	mov ax,bx
	pop di
	pop es
	add sp,8
	pop bp
	ret 2
AllocSelector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeSelector
;
;       DESCRIPTION:    Free selector
;
;       PARAMETERS:     Selector   Selector to free
;
;	    RETURNS:     	0 if success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public FreeSelector

FreeSelector	Proc far
	push bp
	mov bp,sp
    mov bx,[bp+6]
    mov ax,1
    int 31h
	xor ax,ax
	pop bp
	ret 2
FreeSelector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSelectorBase
;
;       DESCRIPTION:    Get selector linear base address
;
;       PARAMETERS:     Selector   Selector
;
;	    RETURNS:     	Linear base address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetSelectorBase

GetSelectorBase	Proc far
	push bp
	mov bp,sp
    mov bx,[bp+6]
    mov ax,6
    int 31h
    mov ax,dx
    mov dx,cx
	pop bp
	ret 2
GetSelectorBase	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetSelectorBase
;
;       DESCRIPTION:    Set selector linear base address
;
;       PARAMETERS:     Selector   Selector
;		                Base       Base address
;
;	    RETURNS:     	Selector if success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public SetSelectorBase

SetSelectorBase	Proc far
	push bp
	mov bp,sp
	mov bx,[bp+10]
    mov ax,7
    mov dx,[bp+6]
    mov cx,[bp+8]
    int 31h
    mov ax,[bp+10]
	pop bp
	ret 6
SetSelectorBase	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetSelectorLimit
;
;       DESCRIPTION:    Get selector limit
;
;       PARAMETERS:     Selector   Selector
;
;	    RETURNS:     	Selector limit
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetSelectorLimit

GetSelectorLimit	Proc far
	push bp
	mov bp,sp
	lsl eax,[bp+6]
	push eax
	pop ax
	pop dx
	pop bp
	ret 2
GetSelectorLimit	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetSelectorLimit
;
;       DESCRIPTION:    Set selector limit
;
;       PARAMETERS:     Selector   Selector
;		                Limit	   Selector limit
;
;	    RETURNS:     	0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public SetSelectorLimit

SetSelectorLimit	Proc far
	push bp
	mov bp,sp
    mov bx,[bp+10]
    mov ax,8
    mov dx,[bp+6]
    mov cx,[bp+8]
    int 31h
    xor ax,ax
	pop bp
	ret 6
SetSelectorLimit	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           PrestoChangoSelector
;
;       DESCRIPTION:    Copy selector with opposite code/data attribute
;
;       PARAMETERS:     Source     Selector to copy
;		                Dest       Converted Selector
;
;	    RETURNS:     	Dest or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public PrestoChangoSelector

PrestoChangoSelector	Proc far
	push bp
	mov bp,sp
	sub sp,8
	push es
	push di
    mov bx,[bp+8]
	mov ax,ss
	mov es,ax
	lea di,[bp-8]
    mov ax,0Bh
    int 31h
    xor byte ptr es:[di+5],8
    mov bx,[bp+6]
    mov ax,0Ch
    int 31h
    mov ax,bx
	pop di
	pop es
	add sp,8
	pop bp
	ret 4
PrestoChangoSelector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Dos3Call
;
;       DESCRIPTION:    int 21 call
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public Dos3Call

Dos3Call	Proc far
	int 21h
	ret
Dos3Call	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FatalExit
;
;       DESCRIPTION:    Stop application
;
;		PARAMETERS:		Code		Exit code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public FatalExit

FatalExit:
	int 3
	mov bp,sp
	mov al,[bp+6]
	mov ah,4Ch
	int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetDOSEnviroment
;
;       DESCRIPTION:    Get DOS Enviroment strings
;
;		RETURNS:		Address to DOS enviroment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetDOSEnviroment

GetDOSEnviroment	Proc far
	push es
    mov ah,62h
    int 21h
    mov es,bx
    mov bx,2Ch
    mov dx,es:[bx]
    xor ax,ax
	pop es
	ret
GetDOSEnviroment	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetVersion
;
;       DESCRIPTION:    Get DOS and Windows version
;
;		RETURNS:		Windows version in loword and dos version in high word
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetVersion

GetVersion	Proc far
    mov ax,3000h
    int 21h
    mov dh,al
    mov dl,ah
    mov ax,1003h
	ret
GetVersion	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetWinFlags
;
;       DESCRIPTION:    Get Windows flags
;
;		RETURNS:		Windows flags
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetWinFlags

GetWinFlags	Proc far
    mov ax,0C25h
    xor dx,dx
	ret
GetWinFlags	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OpenSystemIni
;
;       DESCRIPTION:    Opens system ini file
;
;		RETURNS:		BX			ini file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SysIniName	DB 'z:\system.ini',0

OpenSystemIni	Proc near
	mov ax,cs
	mov es,ax
	mov di,OFFSET SysIniName
OpenSystemIniLoop:
	mov cl,0
	OpenFile
	jnc OpenSystemIniDone
	inc byte ptr es:[di]
	jmp OpenSystemIniLoop
OpenSystemIniDone:
	ret
OpenSystemIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniSection
;
;       DESCRIPTION:    Find section in .ini file
;
;		PARAMETERS:		BX			ini file handle
;						DS:SI		Section to find
;						ES			Buffer
;						EAX			Size of section
;						EDX			File position
;						NC			Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniSection	Proc near
	mov eax,400h
	AllocateLocalMem
	xor edx,edx
FindIniSectionNext:
	mov eax,edx
	SetFilePos
	mov cx,400h
	xor edi,edi
	ReadFile
	or ax,ax
	stc
	jz FindIniSectionDone
FindIniSectionScan:
	mov cx,ax
	mov al,'['
	repne scasb
	add edx,edi
	cmp byte ptr es:[di-1],'['
	je FindIniSectionTest
	mov eax,edx
	SetFilePos
	mov cx,400h
	xor di,di
	ReadFile
	or ax,ax
	stc
	jnz FindIniSectionScan
	jmp FindIniSectionDone
FindIniSectionTest:
	mov eax,edx
	SetFilePos
	mov cx,400h
	xor di,di
	ReadFile
	or ax,ax
	stc
	jz FindIniSectionDone
	push si
	repe cmpsb
	dec si
	dec di
	lodsb
	or al,al
	jne FindIniSectionWrongName
	mov al,es:[di]
	cmp al,']'
	jne FindIniSectionWrongName
	pop si
	inc di
	add edx,edi
	push edx
FindIniSectionSize:
	mov eax,edx
	SetFilePos
	mov cx,400h
	xor edi,edi
	ReadFile
	mov cx,ax
	mov al,'['
	repne scasb
	add edx,edi
	dec edx
	or cx,cx
	je FindIniSectionSize
	mov eax,edx
	pop edx
	sub eax,edx
	clc
	jmp FindIniSectionDone	
FindIniSectionWrongName:
	pop si
	add edx,edi
	inc edx
	jmp FindIniSectionNext
FindIniSectionDone:
	pushf
	FreeMem
	popf
	ret
FindIniSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FindIniKey
;
;       DESCRIPTION:    Find key in section
;
;		PARAMETERS:		BX			ini file handle
;						DS:SI		Key to find
;						EDX			File position
;						EAX			Size of section
;						ES:DI		Key value
;						NC			Success
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FindIniKey	Proc near
	mov cx,ax
	AllocateLocalMem
	mov eax,edx
	SetFilePos
	xor di,di
	ReadFile	
FindIniKeyControl:
	mov al,es:[di]
	cmp al,0Dh
	je FindIniKeyControlPass
	cmp al,0Ah
	je FindIniKeyControlPass
	cmp al,' '
	je FindIniKeyControlPass
	cmp al,9
	jne FindIniKeyScan
FindIniKeyControlPass:
	inc di
	loop FindIniKeyControl
	stc
	jmp FindIniKeyDone
FindIniKeyScan:
	push si
	repe cmpsb
	dec si
	dec di
	inc cx
	lodsb
	pop si
	or al,al
	jne FindIniKeyWrongName
FindIniKeySpacePass:
	mov al,es:[di]
	cmp al,'='
	je FindIniKeyCorrectName
	cmp al,' '
	je FindIniKeySpacePass
	cmp al,9
	jne FindIniKeyWrongName
	inc di
	sub cx,1
	jc FindIniKeyDone
	jmp FindIniKeySpacePass
FindIniKeyWrongName:
	mov al,es:[di]
	cmp al,0Dh
	je FindIniKeyControl
	inc di	
	sub cx,1
	jc FindIniKeyDone
	jmp FindIniKeyWrongName
FindIniKeyCorrectName:
	inc di
	clc
FindIniKeyDone:
	ret
FindIniKey	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	
;
;		NAME:			GetIniInt
;
;		DESCRIPTION:	Read ini file key as integer
;
;		PARAMETERS:		ES:DI	String
;						(E)AX	Size of section
;						AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetIniInt	PROC near
	push bx
	mov bx,ax
	xor ax,ax
	xor ch,ch
GetIniIntPass:
	mov cl,es:[di]
	inc di
	sub bx,1
	jz GetIniIntEnd
	cmp cl,' '
	je GetIniIntPass
	cmp cl,'	'
	je GetIniIntPass
	cmp cl,'+'
	je GetIniIntPass
	cmp cl,'-'
	jne GetIniIntDecode
	mov ch,80h
	jmp GetIniIntPass
GetIniIntDecode:
	dec di
	inc bx
GetIniIntLoop:
	mov cl,es:[di]
	sub cl,30h
	jc GetIniIntEnd
	cmp cl,0Ah
	jnc GetIniIntEnd
	mov dx,10
	mul dx
	add al,cl
	adc ah,0
	inc di
	sub bx,1
	jnz GetIniIntLoop
GetIniIntEnd:
	test ch,80h
	jz GetIniIntPos
	neg ax
GetIniIntPos:
	pop bx
	ret
GetIniInt	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProfileInt
;
;       DESCRIPTION:    Get .ini file integer
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetProfileInt

GetProfileInt	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
	call OpenSystemIni
	lds si,[bp+12]
	call FindIniSection
	jc GetProfileIntSectionFail
	lds si,[bp+8]
	call FindIniKey
	jc GetProfileIntKeyFail
	call GetIniInt
	FreeMem
	jmp GetProfileIntEnd
GetProfileIntKeyFail:
	FreeMem
GetProfileIntSectionFail:
	mov ax,[bp+6]
GetProfileIntEnd:
	push ax
	CloseFile
	pop ax
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret 10
GetProfileInt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetProfileString
;
;       DESCRIPTION:    Get .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Default		default value
;						ReturnedStr	returned string
;						Size		size of ReturnedStr string 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public GetProfileString

GetProfileString	Proc far
	push bp
	mov bp,sp
	push ds
	push es
	push si
	push di
	call OpenSystemIni
	lds si,[bp+20]
	call FindIniSection
	jc GetProfileStringSectionFail
	lds si,[bp+16]
	call FindIniKey
	jc GetProfileStringKeyFail
	mov cx,ax
	xor dx,dx
	cmp cx,[bp+6]
	jc GetProfileStringWhole
	mov cx,[bp+6]
	dec cx
GetProfileStringWhole:
	push es
	mov ax,es
	mov ds,ax
	mov si,di
	les di,[bp+8]
GetProfileStringCopy:
	lodsb
	cmp al,0Dh
	je GetProfileStringCopied
	cmp al,0Ah
	je GetProfileStringCopied
	inc dx
	stosb
	loop GetProfileStringCopy
GetProfileStringCopied:
	xor ax,ax
	stosb
	mov ds,ax
	pop es
	FreeMem
	jmp GetProfileStringEnd
GetProfileStringKeyFail:
	FreeMem
GetProfileStringSectionFail:
	lds si,[bp+12]
	les di,[bp+8]
	mov cx,[bp+6]
	dec cx
	xor dx,dx
GetProfileStringDefault:
	lodsb
	stosb
	or al,al
	je GetProfileStringEnd
	inc dx
	loop GetProfileStringDefault
GetProfileStringEnd:
	CloseFile
	mov ax,dx
	pop di
	pop si
	pop es
	pop ds
	pop bp
	ret 18
GetProfileString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteProfileInt
;
;       DESCRIPTION:    Write .ini file string
;
;		PARAMETERS:		AppName		name of section
;						KeyName		name of key
;						Value		value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public WriteProfileString

WriteProfileString	Proc far
	xor ax,ax
	ret 12
WriteProfileString	Endp

init	Proc far
	ret
init	Endp

code	ENDS

	END init
