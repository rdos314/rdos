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
; CONSOLE.ASM
; 32-bit kernel32.dll console support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  console

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\os\user.def

UserGate      MACRO gate_nr
	db 66h
	db 9Ah
	dw 0
	dw 200Bh + (gate_nr SHL 4)
			ENDM

STD_HANDLE = 3AB80000h
STD_IN = STD_HANDLE
STD_OUT = STD_HANDLE + 1
STD_ERR = STD_HANDLE + 2

tib_data	STRUC

pvFirstExcept		DD ?
pvStackUserTop		DD ?
pvStackUserBottom	DD ?
pvLastError			DD ?
pvResv1				DD ?
pvArbitrary			DD ?
pvTEB				DD ?
pvResv2				DD ?
pvThreadHandle		DD ?
pvModuleHandle		DD ?
pvTLSBitmap			DD ?
pvTLSArray			DD ?

tib_data	ENDS

INPUT_EVENT_SIZE = 20
MAX_INPUT_EVENTS = 32

COORD		STRUC

X			dw ?
Y			dw ?

COORD		ENDS

SMALL_RECT	STRUC

Left		dw ?
Top			dw ?
Right		dw ?
Bottom		dw ?

SMALL_RECT	ENDS

CONSOLE_CURSOR_INFO STRUC 
		
dwCursorSize	dd	?
bVisible		dd	?

CONSOLE_CURSOR_INFO ENDS 

ENABLE_PROCESSED_INPUT		EQU	1
ENABLE_LINE_INPUT      		EQU	2
ENABLE_ECHO_INPUT      		EQU	4
ENABLE_WINDOW_INPUT    		EQU	8
ENABLE_MOUSE_INPUT     		EQU	10h

ENABLE_PROCESSED_OUTPUT    	EQU	1
ENABLE_WRAP_AT_EOL_OUTPUT  	EQU	2

MOUSE_MOVED = 1
DOUBLE_CLICK = 2

KEY_EVENT = 1

KEY_EVENT_RECORD	STRUC

wKeyEventType		dd ?
bKeyDown			dd ?
wRepeatCount		dw ?
wVirtualKeyCode		dw ? 
wVirtualScanCode	dw ?
wAsciiChar			dw ? 
dwControlKeyState	dd ?

KEY_EVENT_RECORD	ENDS

MOUSE_EVENT = 2

MOUSE_EVENT_RECORD	STRUC 

wMouseEventType		dd ?
dwMousePosition		COORD <> 
dwButtonState		dd ? 
dwKbControlKeyState	dd ? 
dwEventFlags		dd ? 

MOUSE_EVENT_RECORD	ENDS

ALT EQU 2
CTRL EQU 8
SHIFT EQU 16

.model flat

.data
	align  DWORD

InputMode dd ENABLE_LINE_INPUT + ENABLE_ECHO_INPUT + ENABLE_PROCESSED_INPUT
OutputMode dd ENABLE_PROCESSED_OUTPUT + ENABLE_WRAP_AT_EOL_OUTPUT
ErrorMode dd ENABLE_PROCESSED_OUTPUT + ENABLE_WRAP_AT_EOL_OUTPUT

MouseButtons dd 2

CurrMouseButtons	DW ?
CurrMouseX			DW ?
CurrMouseY			DW ?

EventHead	DD ?
EventTail	DD ?
EventBuf	DB MAX_INPUT_EVENTS * INPUT_EVENT_SIZE DUP(?)

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ConvertKeyboardState
;
;       DESCRIPTION:    Convert to win32 keyboard state
;
;		PARAMETERS:		AX		Rdos keyboard state
;
;		RETURNS:		EAX		Keyboard state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; RDOS key states

num_active		EQU 200h
caps_active		EQU 100h
print_pressed	EQU 20h
scroll_pressed	EQU 10h
pause_pressed	EQU 8
ctrl_pressed	EQU 4
alt_pressed		EQU 2
shift_pressed	EQU 1

ConvertKeyboardState	Proc near
	push dx
	mov dx,ax
	xor eax,eax
	test dx,shift_pressed
	jz cksShiftDone
	or al,10h

cksShiftDone:
	test dx,alt_pressed
	jz cksAltDone
	or al,1

cksAltDone:
	test dx,ctrl_pressed
	jz cksCtrlDone
	or al,4

cksCtrlDone:
	test dx,num_active
	jz cksNumDone
	or al,20h

cksNumDone:
	test dx,caps_active
	jz cksCapsDone
	or al,80h

cksCapsDone:
	pop dx
	ret
ConvertKeyboardState	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           KeyboardHook
;
;       DESCRIPTION:    Keyboard callback
;
;		PARAMETERS:		AL		char
;						AH		scan code
;						CX		keyboard state
;						DX		virtual key codes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

KeyboardHook Proc near
	mov ebx,EventTail
	mov esi,ebx
	inc ebx
	cmp ebx,MAX_INPUT_EVENTS
	jne khCircOk
	xor ebx,ebx
khCircOk:
	push eax
	push edx
	mov eax,INPUT_EVENT_SIZE
	mul esi
	mov esi,eax
	add esi,OFFSET EventBuf
	pop edx
	pop eax
	mov word ptr [esi].wKeyEventType, KEY_EVENT
	test ah,80h
	jnz khRel

khPress:
	mov [esi].bKeyDown,1
	jmp khDownOk

khRel:
	mov [esi].bKeyDown,0

khDownOk:
	mov [esi].wRepeatCount,1
	mov [esi].wVirtualKeyCode,dx
	and ah,NOT 80h
	movzx dx,ah
	mov [esi].wVirtualScanCode,dx
	movzx dx,al
	mov [esi].wAsciiChar,dx
	mov ax,cx
	call ConvertKeyboardState
	mov [esi].dwControlKeyState,eax
;
	mov EventTail,ebx
	ret
KeyboardHook ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           MouseHook
;
;       DESCRIPTION:    Mouse callback
;
;		PARAMETERS:		AX		buttons
;						CX		delta x
;						DX		delta y
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MouseHook Proc near
	shr ecx,3
	shr edx,3
;
	mov ebx,EventTail
	mov esi,ebx
	inc ebx
	cmp ebx,MAX_INPUT_EVENTS
	jne mhCircOk
	xor ebx,ebx
mhCircOk:
	push eax
	push edx
	mov eax,INPUT_EVENT_SIZE
	mul esi
	mov esi,eax
	add esi,OFFSET EventBuf
	pop edx
	pop eax
	mov word ptr [esi].wMouseEventType, MOUSE_EVENT
;
	cmp ax,CurrMouseButtons
	je mhButtonsOk
;
	mov CurrMouseButtons,ax
	mov [esi].dwEventFlags, 0
	jmp mhFill

mhButtonsOk:
	cmp cx,CurrMouseX
	jne mhNewPos
;
	cmp dx,CurrMouseY
	je mhDone

mhNewPos:
	mov [esi].dwEventFlags, MOUSE_MOVED

mhFill:
	mov CurrMouseX,cx
	mov CurrMouseY,dx
	mov [esi].dwMousePosition.X, cx
	mov [esi].dwMousePosition.Y, dx
	movzx eax,ax
	mov [esi].dwButtonState,eax
	UserGate get_keyboard_state_nr
	call ConvertKeyboardState
	mov [esi].dwKbControlKeyState,eax
	mov EventTail,ebx

mhDone:
	ret
MouseHook Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EventCount
;
;       DESCRIPTION:    Return number of events
;
;		RETURNS:		EAX		Number of events
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EventCount	Proc near
	mov eax,EventHead
	sub eax,EventTail
	jnc ecDone
	add eax,MAX_INPUT_EVENTS
ecDone:
	ret
EventCount	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           PeekEvent
;
;       DESCRIPTION:    Peek event queue
;
;		PARAMETERS:		EDI		Pointer to buffer (if used)
;						ECX		Number of events to read
;
;		RETURNS:		EAX		Number of events
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PeekEvent	Proc near
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	xor ebx,ebx
	or ecx,ecx
	jz peDone
;
	mov esi,EventHead

peLoop:
	cmp esi,EventTail
	je peDone

peDo:
	inc ebx
	mov eax,esi
	inc eax
	cmp eax,MAX_INPUT_EVENTS
	jne peCircOk
	xor eax,eax
peCircOk:
	push eax
	mov eax,INPUT_EVENT_SIZE
	mul esi
	mov esi,eax
	add esi,OFFSET EventBuf
	push ecx
	mov ecx,INPUT_EVENT_SIZE
	rep movsb
	pop ecx
	pop esi
	loop peLoop

peDone:
	mov eax,ebx
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret
PeekEvent	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadEvent
;
;       DESCRIPTION:    Read a event from queue
;
;		PARAMETERS:		ECX		Number of events to read
;						EDI		Pointer to event record buffer
;
;		RETURNS:		EAX		Number of read events
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEvent	Proc near
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	xor ebx,ebx
	or ecx,ecx
	jz reDone

reLoop:
	mov esi,EventHead
	cmp esi,EventTail
	je reDone

reDo:
	inc ebx
	mov eax,esi
	inc eax
	cmp eax,MAX_INPUT_EVENTS
	jne reCircOk
	xor eax,eax
reCircOk:
	mov EventHead,eax
	mov eax,INPUT_EVENT_SIZE
	mul esi
	mov esi,eax
	add esi,OFFSET EventBuf
	push ecx
	mov ecx,INPUT_EVENT_SIZE
	rep movsb
	pop ecx
	loop reLoop

reDone:
	mov eax,ebx
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	ret
ReadEvent	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitConsole
;
;       DESCRIPTION:    Init console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InitConsole

InitConsole Proc near
	mov EventHead,0
	mov EventTail,0
;
	xor ax,ax
	xor bx,bx
	mov cx,639
	mov dx,199
	UserGate set_mouse_window_nr
	ret
InitConsole ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteConsole
;
;       DESCRIPTION:    Write to console
;
;		PARAMETERS:		EBX		Console handle
;						EDI		buffer
;						ECX		count
;
;		RETURNS:		EAX		count written
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteConsole

WriteConsole Proc near
	push ebx
	UserGate hide_mouse_nr
	mov bx,1
	UserGate write_file_nr
	UserGate show_mouse_nr
	pop ebx
	ret
WriteConsole ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadConsole
;
;       DESCRIPTION:    Read from console
;
;		PARAMETERS:		EBX		Console handle
;						EDI		buffer
;						ECX		count
;
;		RETURNS:		EAX		count read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadConsole

ReadConsole Proc near
	push ebx
	mov bx,1
	UserGate read_file_nr
	pop ebx
	ret
ReadConsole ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteConsole
;
;       DESCRIPTION:    Write to console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteConsoleA

wcHandle	EQU 8
wcBuf		EQU 12
wcCount		EQU 16
wcWritten	EQU 20
wcOverlap	EQU 24

WriteConsoleA Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	UserGate hide_mouse_nr
	mov eax,[ebp].wcHandle
	mov bx,ax
	xor ax,ax
	cmp eax,STD_HANDLE
	mov eax,6
	jne wcFailed
;
	mov edi,[ebp].wcBuf
	mov ecx,[ebp].wcCount
	call WriteConsole
	jc short wcFailed
;
	mov ecx,[ebp].wcWritten
	mov [ecx],eax
	mov eax,1
	jmp wcDone

wcFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

wcDone:
	UserGate show_mouse_nr
	pop edi
	pop ebx
	pop ebp
	ret 20
WriteConsoleA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadConsole
;
;       DESCRIPTION:    Read from console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadConsoleA

rcHandle	EQU 8
rcBuf		EQU 12
rcCount		EQU 16
rcRead		EQU 20
rcOverlap	EQU 24

ReadConsoleA Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov eax,[ebp].rcHandle
	mov bx,ax
	xor ax,ax
	cmp eax,STD_HANDLE
	mov eax,6
	jne rcFailed
;
	mov edi,[ebp].rcBuf
	mov ecx,[ebp].rcCount
	call ReadConsole
	jc short rcFailed
;
	mov ecx,[ebp].rcRead
	mov [ecx],eax
	mov eax,1
	jmp rcDone

rcFailed:
	movzx eax,al
	mov fs:pvLastError,eax
	xor eax,eax

rcDone:
	pop edi
	pop ebx
	pop ebp
	ret 20
ReadConsoleA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           AllocConsole
;
;       DESCRIPTION:    Allocate console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public AllocConsole

AllocConsole Proc near
	int 3
	sub eax,eax
	ret
AllocConsole Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Beep
;
;       DESCRIPTION:    Beep
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public Beep

Beep Proc near
	mov eax,1
	ret 8
Beep ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateConsoleScreenBuffer
;
;       DESCRIPTION:    Create console screen buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CreateConsoleScreenBuffer

CreateConsoleScreenBuffer Proc near
	int 3
	mov eax,-1
	ret 20
CreateConsoleScreenBuffer ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FillConsoleOutputAttribute
;
;       DESCRIPTION:    Fill console output attribute
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FillConsoleOutputAttribute

fcaConsole		EQU 8
fcaAttrib		EQU 12
fcaCount		EQU 16
fcaCoordX		EQU 20
fcaCoordY		EQU 22
fcaWritten		EQU 24
 
FillConsoleOutputAttribute Proc near
	push ebp
	mov ebp,esp
;
	int 3
	UserGate hide_mouse_nr
	mov cx,[ebp].fcaCoordX
	mov dx,[ebp].fcaCoordY
	shr cx,3
	shr dx,3
	UserGate set_cursor_position_nr
	mov ecx,[ebp].fcaCount
;
	mov eax,[ebp].fcaWritten
	mov [eax],ecx

	mov eax,[ebp].fcaAttrib
	UserGate set_forecolor_nr

fcaaloop:
;
; here we should change the attribute, but we can't!!
;
	dec ecx
	jnz fcaaloop

	UserGate show_mouse_nr
	mov eax,1
;
	pop ebp
	ret 20
FillConsoleOutputAttribute ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FillConsoleOutputCharacter
;
;       DESCRIPTION:    Fill console output character
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FillConsoleOutputCharacterA

fccConsole		EQU 8
fccChar			EQU 12
fccCount		EQU 16
fccCoordX		EQU 20
fccCoordY		EQU 22
fccWritten		EQU 24

FillConsoleOutputCharacterA Proc near
	push ebp
	mov ebp,esp
;
	int 3
	UserGate hide_mouse_nr
	mov cx,[ebp].fccCoordX
	mov dx,[ebp].fccCoordY
	shr cx,3
	shr dx,3
	UserGate set_cursor_position_nr
	mov ecx,[ebp].fccCount
;
	mov eax,[ebp].fccWritten
	mov [eax],ecx
	mov eax,[ebp].fccChar

fcacloop:
	UserGate write_char_nr
	dec ecx
	jnz fcacloop

	UserGate show_mouse_nr
	mov eax,1
	ret 20
FillConsoleOutputCharacterA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FlushConsoleInputBuffer
;
;       DESCRIPTION:    Flush input buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FlushConsoleInputBuffer

FlushConsoleInputBuffer Proc near
	UserGate flush_keyboard_nr
	mov EventHead,0
	mov EventTail,0
	mov eax,1
	ret 4
FlushConsoleInputBuffer ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FreeConsole
;
;       DESCRIPTION:    Free console
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public FreeConsole

FreeConsole Proc near
	int 3
	mov eax,1
	ret
FreeConsole ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetConsoleOutputCP
;
;       DESCRIPTION:    Get console output CP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetConsoleOutputCP

GetConsoleOutputCP Proc near
	mov eax,437
	ret
GetConsoleOutputCP Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetACP
;
;       DESCRIPTION:    Get ACP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetACP

GetACP Proc near
	mov eax,437
	ret
GetACP Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetConsoleCP
;
;       DESCRIPTION:    Get Console CP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetConsoleCP

GetConsoleCP Proc near
	mov eax,437
	ret
GetConsoleCP Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetOEMCP
;
;       DESCRIPTION:    Get Console CP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetOEMCP

GetOEMCP Proc near
	mov eax,437
	ret
GetOEMCP Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetConsoleCursorInfo
;
;       DESCRIPTION:    Get Console cursor info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	 public GetConsoleCursorInfo 

GetConsoleCursorInfo Proc near
	int 3
	xor eax,eax
	ret 8
GetConsoleCursorInfo ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetConsoleMode
;
;       DESCRIPTION:    Get Console mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetConsoleMode

GetConsoleMode Proc near
	mov eax,[esp+4]
;
	cmp eax,STD_IN
	je gcmInput
;
	cmp eax,STD_OUT
	je gcmOutput
;
	cmp eax,STD_ERR
	je gcmError
;
	xor eax,eax
	jmp gcmDone

gcmInput:
	mov eax,InputMode
	jmp gcmOk

gcmOutput:
	mov eax,OutputMode
	jmp gcmOk

gcmError:
	mov eax,ErrorMode

gcmOk:
	mov ecx,[esp+8]
	mov [ecx],eax
	mov eax,1

gcmDone:
	ret 8
GetConsoleMode ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetNumberOfConsoleInputEvents
;
;       DESCRIPTION:    Get # of console input events
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	 public GetNumberOfConsoleInputEvents

gnciHandle	EQU 8
gnciCount	EQU 12

GetNumberOfConsoleInputEvents Proc near
	push ebp
	mov ebp,esp
;
	call EventCount
	mov edx,[ebp].gnciCount
	mov [edx],eax
;
	mov eax,1
	pop ebp
	ret 8
GetNumberOfConsoleInputEvents ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetNumberOfConsoleMouseButtons
;
;       DESCRIPTION:    Get # of console mouse buttons
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	 public GetNumberOfConsoleMouseButtons

GetNumberOfConsoleMouseButtons Proc near
	mov eax,MouseButtons
	add eax,eax
	jz cmbdone

	mov edx,[esp + 4]
	mov [edx],eax
	dec eax

cmbdone:
	ret 4
GetNumberOfConsoleMouseButtons ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           PeekConsoleInput
;
;       DESCRIPTION:    Peek console input
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public PeekConsoleInputA

pciHandle	EQU 8
pciBuf		EQU 12
pciCount	EQU 16
pciRead		EQU 20

PeekConsoleInputA Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp].pciBuf
	mov ecx,[ebp].pciCount
	call PeekEvent
	mov ecx,[ebp].pciRead
	or ecx,ecx
	jz pciDone
	mov [ecx],eax

pciDone:
	mov eax,1
	pop edi
	pop ebp
	ret 16
PeekConsoleInputA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadConsoleInput
;
;       DESCRIPTION:    Read console input
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	 public ReadConsoleInputA

rciHandle	EQU 8
rciBuf		EQU 12
rciCount	EQU 16
rciRead		EQU 20

ReadConsoleInputA Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp].rciBuf
	mov ecx,[ebp].rciCount
	call ReadEvent
	mov ecx,[ebp].rciRead
	or ecx,ecx
	jz rciDone
	mov [ecx],eax

rciDone:
	mov eax,1
	pop edi
	pop ebp
	ret 16
ReadConsoleInputA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadConsoleOutput
;
;       DESCRIPTION:    Read console output
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	 public ReadConsoleOutputA

rcoHandle	EQU 8
rcoBuf		EQU 12
rcoSize		EQU 16
rcoCoord	EQU 20
rcoRegion	EQU 24

ReadConsoleOutputA Proc near
	int 3
	xor eax,eax
	ret 20
ReadConsoleOutputA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ScrollConsoleScreenBuffer
;
;       DESCRIPTION:    Scroll console screen buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ScrollConsoleScreenBufferA

ScrollConsoleScreenBufferA Proc near
	int 3
	xor eax,eax
	ret 20
ScrollConsoleScreenBufferA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetConsoleCursorInfo
;
;       DESCRIPTION:    Set console cursor info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetConsoleCursorInfo

SetConsoleCursorInfo Proc near
	int 3
	xor eax,eax
	ret 8
SetConsoleCursorInfo ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetConsoleCursorPosition
;
;       DESCRIPTION:    Set console cursor position
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetConsoleCursorPosition

SetConsoleCursorPosition Proc near
	int 3
	mov cx,[esp+12]
	mov dx,[esp+14]
	UserGate set_cursor_position_nr
	mov eax,1
	ret 8
SetConsoleCursorPosition ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetConsoleMode
;
;       DESCRIPTION:    Set console mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetConsoleMode

SetConsoleMode Proc near
	mov eax,[esp+8]
	mov ecx,[esp+4]
;
	cmp ecx,STD_IN
	je scmInput
;
	cmp ecx,STD_OUT
	je scmOutput
;
	cmp ecx,STD_ERR
	je scmError
;
	xor eax,eax
	jmp scmDone

scmError:
	mov ErrorMode,eax
	jmp scmOk

scmOutput:
	mov OutputMode,eax
	jmp scmOk

scmInput:
	mov InputMode,eax
	test eax,ENABLE_MOUSE_INPUT OR ENABLE_WINDOW_INPUT
	jz scmNoKeyHook
;
	mov EventHead,0
	mov EventTail,0
	push es
	push edi
	mov ax,cs
	mov es,ax
	mov edi,OFFSET KeyboardHook
	UserGate hook_keyboard_nr
	pop edi
	pop es
	jmp scmKeyOk

scmNoKeyHook:
	UserGate unhook_keyboard_nr

scmKeyOk:
	test eax,ENABLE_MOUSE_INPUT
	jz scmNoMouseHook
;
	mov EventHead,0
	mov EventTail,0
	push es
	push edi
	mov ax,cs
	mov es,ax
	mov edi,OFFSET MouseHook
	UserGate hook_mouse_nr
	pop edi
	pop es
	jmp scmMouseOk

scmNoMouseHook:
	UserGate unhook_mouse_nr

scmMouseOk:

scmOk:
	mov eax,1

scmDone:
	ret 8
SetConsoleMode ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetConsoleScreenBufferSize
;
;       DESCRIPTION:    Set console screen buffer size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	 public SetConsoleScreenBufferSize

SetConsoleScreenBufferSize Proc near
	int 3
	xor eax,eax
	ret 8
SetConsoleScreenBufferSize ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetConsoleTextAttribute
;
;       DESCRIPTION:    Set console text attribute
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetConsoleTextAttribute

SetConsoleTextAttribute	Proc near
	mov eax,[esp+8]
	UserGate set_forecolor_nr
	ret 8
SetConsoleTextAttribute Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetConsoleWindowInfo
;
;       DESCRIPTION:    Set console window info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetConsoleWindowInfo

SetConsoleWindowInfo Proc near
	int 3
	xor eax,eax
	ret 12
SetConsoleWindowInfo ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteConsoleOutput
;
;       DESCRIPTION:    Write console output
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteConsoleOutputA

WriteConsoleOutputA Proc near
	int 3
	xor eax,eax
	ret 20
WriteConsoleOutputA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetConsoleScreenBufferInfo
;
;       DESCRIPTION:    Get console screen buffer info
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetConsoleScreenBufferInfo

GetConsoleScreenBufferInfo  Proc near
	int 3
	xor eax,eax
	ret 8
GetConsoleScreenBufferInfo  ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetLargestConsoleWindowSize
;
;       DESCRIPTION:    Get largest console window size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetLargestConsoleWindowSize

GetLargestConsoleWindowSize Proc near
	mov eax,320050h ; return 80 x 50
	ret 4
GetLargestConsoleWindowSize ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetConsoleTitle
;
;       DESCRIPTION:    Get console title 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetConsoleTitleA

gctBuf		EQU 8
gctSize		EQU 12

GetConsoleTitleA Proc near
	push ebp
	mov ebp,esp
;
	int 3
	xor eax,eax
;
	pop ebp
	ret 8
GetConsoleTitleA ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateEvent
;
;       DESCRIPTION:    Create an event 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CreateEventA

ceSec		EQU 8
ceManReset	EQU 12
ceState		EQU 16
ceName		EQU 20

CreateEventA Proc near
	push ebp
	mov ebp,esp
;
	int 3
;
	pop ebp
	ret 16
CreateEventA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetEvent
;
;       DESCRIPTION:    Set an event 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetEvent

seHandle	EQU 8

SetEvent Proc near
	push ebp
	mov ebp,esp
;
	int 3
;
	pop ebp
	ret 4
SetEvent Endp

	END
