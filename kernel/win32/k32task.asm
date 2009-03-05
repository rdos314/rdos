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
; K32TASK.ASM
; 32-bit kernel32.dll tasking support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  k32task

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\user.def

UserGate	MACRO gate_nr
	db 9Ah
	dd gate_nr
	dw 2
			ENDM

tib_data	STRUC

pvFirstExcept		DD ?
pvStackUserTop		DD ?
pvStackUserBottom	DD ?
pvLastError			DD ?
pvResv1				DD ?
pvArbitrary			DD ?
pvTEB				DD ?
pvProcessHandle		DD ?
pvThreadHandle		DD ?
pvModuleHandle		DD ?
pvTLSBitmap			DD ?
pvTLSArray			DD ?

tib_data	ENDS

THREAD_HANDLE	EQU 7ABC0000h
PROCESS_HANDLE	EQU 0BCE50000h

.code

    extrn SetDebugHandle:near
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InterlockedIncrement
;
;       DESCRIPTION:   	Increment var
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InterlockedIncrement

InterlockedIncrement Proc near
	mov eax,[esp + 4]
	inc dword ptr [eax]
	jz iliZero
;
	jns iliPos

iliNeg:
	mov eax,-1
	jmp iliDone

iliPos:
	mov eax,1
	jmp iliDone

iliZero:
	xor eax,eax

iliDone:
	ret 4
InterlockedIncrement ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InterlockedDecrement
;
;       DESCRIPTION:   	Decrement var
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InterlockedDecrement

InterlockedDecrement Proc near
	mov eax,[esp + 4]
	dec dword ptr [eax]
	jz ildZero
;
	jns ildPos

ildNeg:
	mov eax,-1
	jmp ildDone

ildPos:
	mov eax,1
	jmp ildDone

ildZero:
	xor eax,eax

ildDone:
	ret 4
InterlockedDecrement ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InterlockedExchange
;
;       DESCRIPTION:   	Exchange vars
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InterlockedExchange

InterlockedExchange Proc near
	mov edx,[esp + 4]
	mov eax,[esp + 8]
	xchg eax,[edx]
	ret 8
InterlockedExchange ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           Sleep
;
;       DESCRIPTION:   	Sleep
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public Sleep

Sleep Proc near
	mov eax,[esp + 4]
	UserGate wait_milli_nr
	ret 4
Sleep Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForSingelObject
;
;       DESCRIPTION:   	Wait for single object
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WaitForSingleObject

WaitForSingleObject Proc near
	int 3
	xor eax,eax
	ret 8
WaitForSingleObject ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitializeCriticalSection
;
;       DESCRIPTION:    InitCritical section.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InitializeCriticalSection

icsPtr	EQU 8

InitializeCriticalSection	Proc near
	push ebp
	mov ebp,esp
	push bx
;
	mov edx,[ebp].icsPtr
	UserGate create_user_section_nr
	mov [edx],bx
;
	pop bx
	pop ebp
	ret 4
InitializeCriticalSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DeleteCriticalSection
;
;       DESCRIPTION:    DeleteCritical section.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DeleteCriticalSection

dcsPtr	EQU 8

DeleteCriticalSection	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov edx,[ebp].dcsPtr
	mov bx,[edx]
	UserGate delete_user_section_nr
;
	pop ebx
	pop ebp
	ret 4
DeleteCriticalSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           EnterCriticalSection
;
;       DESCRIPTION:    EnterCritical section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EnterCriticalSection

ecsPtr	EQU 8

EnterCriticalSection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov edx,[ebp].ecsPtr
	mov bx,[edx]
	UserGate enter_user_section_nr
;	
	pop ebx
	pop ebp
	ret 4
EnterCriticalSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           LeaveCriticalSection
;
;       DESCRIPTION:    LeaveCritical section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LeaveCriticalSection

lcsPtr	EQU 8

LeaveCriticalSection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov edx,[ebp].lcsPtr
	mov bx,[edx]
	UserGate leave_user_section_nr
;
	pop ebx
	pop ebp
	ret 4
LeaveCriticalSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ExitThread
;
;       DESCRIPTION:    Exit a thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 public ExitThread

ExitThread:
	UserGate terminate_thread_nr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateThread
;
;       DESCRIPTION:    Create a new thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 public CreateThread

ThreadName DB 'Win32 Thread',0

ctSec	EQU 8
ctStack	EQU 12
ctStart	EQU 16
ctParam	EQU 20
ctFlags	EQU 24
ctId	EQU 28

ThreadStartup Proc near
	mov ax,ds
	mov es,ax
	push dword ptr [edx]
	push OFFSET ExitThread
	push dword ptr [edx+4]
	push ebx
	mov [edx+16],fs
;
	mov ebx,[edx+8]
	UserGate leave_user_section_nr
;
	mov ebx,[edx+12]
	UserGate enter_user_section_nr
;
	mov ebx,[edx+8]
	UserGate delete_user_section_nr
;
	mov ebx,[edx+12]
	UserGate delete_user_section_nr
;
	mov eax,1000h
	UserGate free_app_mem_nr
	mov eax,ecx
	pop ebx
	ret
ThreadStartup Endp
	
CreateThread Proc near
	push ebp
	mov ebp,esp
	push ds
	push ebx
	push esi
	push edi
;
	mov eax,1000h
	UserGate allocate_app_mem_nr
	mov eax,[ebp].ctParam
	mov [edx],eax
	mov eax,[ebp].ctStart
	mov [edx+4],eax
;
	UserGate create_blocked_user_section_nr
	mov [edx+8],bx
;
	UserGate create_blocked_user_section_nr
	mov [edx+12],bx
;	
	mov ax,cs
	mov ds,ax
	mov eax,2
	mov bx,fs
	mov ecx,[ebp].ctStack
	mov esi, OFFSET ThreadStartup
	mov edi, OFFSET ThreadName
	UserGate create_thread_nr
;
	mov ax,es
	mov ds,ax
	mov bx,[edx+8]
	UserGate enter_user_section_nr
;
	push ds
	mov ds,es:[edx+16]
	mov ecx,[ebp].ctId
	or ecx,ecx
	jz ctIdDone
;
	mov eax,ds:pvTEB
	mov eax,es:[eax+24h]
	mov es:[ecx],eax

ctIdDone:
	mov ecx,ds:pvThreadHandle
	pop ds
;
	mov bx,[edx+12]
	UserGate leave_user_section_nr
;
	pop edi
	pop esi
	pop ebx
	pop ds
	pop ebp
	ret 24
CreateThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCurrentThreadId
;
;       DESCRIPTION:    Get current thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetCurrentThreadId

GetCurrentThreadId Proc near
	mov eax,fs:pvThreadHandle
	ret
GetCurrentThreadId Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCurrentThread
;
;       DESCRIPTION:    Get current thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetCurrentThread

GetCurrentThread Proc near
	mov eax,fs:pvThreadHandle
	ret
GetCurrentThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetThreadPriority
;
;       DESCRIPTION:    Get thread priority
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetThreadPriority

gtpHandle	EQU 8

GetThreadPriority Proc near
	push ebp
	mov ebp,esp
	mov eax,[ebp].gtpHandle
	xor eax,eax
	pop ebp
	ret 4
GetThreadPriority Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ResumeThread
;
;       DESCRIPTION:    Resume thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ResumeThread

rtHandle	EQU 8

ResumeThread Proc near
	push ebp
	mov ebp,esp
	mov eax,[ebp].rtHandle
	mov eax,-1
	pop ebp
	ret 4
ResumeThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SuspendThread
;
;       DESCRIPTION:    Suspend thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SuspendThread

stHandle	EQU 8

SuspendThread Proc near
	push ebp
	mov ebp,esp
	mov eax,[ebp].stHandle
	mov eax,-1
	pop ebp
	ret 4
SuspendThread Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CreateProcessA
;
;       DESCRIPTION:    Create a new process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 public CreateProcessA

cpPath			EQU 8
cpCmdLine		EQU 12
cpProcAttr		EQU 16
cpThreadAttr	EQU 20
cpInhHandles	EQU 24
cpFlags			EQU 28
cpEnv			EQU 32
cpCurrDir		EQU 36
cpStartup		EQU 40
cpInfo			EQU 44
cpDir			EQU -256

CreateProcessA Proc near
	push ebp
	mov ebp,esp
	sub esp,256
	push fs
	push ebx
	push esi
	push edi
;
	mov esi,[ebp].cpPath
	mov edi,[ebp].cpCmdLine

cpCmdLoop:
	mov al,[edi]
	or al,al
	jz cpCmdOk
;
	cmp al,' '
	je cpCmdOk
;
	inc edi
	jmp cpCmdLoop

cpCmdOk:
	mov edx,[ebp].cpFlags
	test dl,1
	jz cpNoDebug
;
	mov edx,fs:pvModuleHandle
	jmp cpCreate

cpNoDebug:
	xor edx,edx

cpCreate:
	mov ax,ds
	mov fs,ax
	mov ebx,[ebp].cpCurrDir
	or ebx,ebx
	jnz cpSpawnIt
;
	push edi
	lea edi,[ebp].cpDir
	UserGate get_cur_drive_nr
	push eax
	add al,'A'
	stosb
	mov ax,'\:'
	stosw
	pop eax
	UserGate get_cur_dir_nr
	pop edi
	lea ebx,[ebp].cpDir

cpSpawnIt:
	UserGate spawn_exe_nr
	jc cpFail
;
	mov ecx,[ebp].cpFlags
	test cl,1
    jz cpSpawnNoDebugHandle
;
    mov bx,dx
    call SetDebugHandle
    
cpSpawnNoDebugHandle:
	mov ecx,[ebp].cpInfo
	or ecx,ecx
	jz cpOk
;
	movzx eax,ax
	or eax,THREAD_HANDLE
	mov [ecx+4],eax
	mov [ecx+12],eax
;
	movzx eax,ax
	or eax,PROCESS_HANDLE
	mov [ecx],eax
	mov [ecx+8],eax
	jmp cpOk

cpFail:
	xor eax,eax
	jmp cpDone

cpOk:
	mov eax,1

cpDone:
	pop edi
	pop esi
	pop ebx
	pop fs
	add esp,256
	pop ebp
	ret 40
CreateProcessA Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TerminateProcess
;
;       DESCRIPTION:   	Terminate process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public TerminateProcess

TerminateProcess Proc near
	int 3
	pop eax
	pop edx
	push eax
	cmp edx,fs:pvProcessHandle
	jnz tpFailed
;
	xor eax,eax
	UserGate unload_exe_nr

tpFailed:
	sub eax,eax
	ret 4
TerminateProcess Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCurrentProcess
;
;       DESCRIPTION:   	Get current process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetCurrentProcess

GetCurrentProcess Proc near
	mov eax,fs:pvProcessHandle
	ret
GetCurrentProcess Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetCurrentProcessID
;
;       DESCRIPTION:   	Get current process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetCurrentProcessId

GetCurrentProcessId Proc near
	mov eax,fs:pvModuleHandle
	ret
GetCurrentProcessId Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetExitCodeProcess
;
;       DESCRIPTION:    Get exit code for process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetExitCodeProcess

GetExitCodeProcess Proc near
	int 3
	UserGate get_exit_code_nr
	mov edx,[esp + 8]
	movzx eax,ax
	mov [edx],eax
	mov eax,1
	ret 8
GetExitCodeProcess Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ExitProcess
;
;       DESCRIPTION:    Exit process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ExitProcess

ExitProcess Proc near
	mov eax, [esp+4]
	UserGate unload_exe_nr
ExitProcess Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           DebugActiveProcess
;
;       DESCRIPTION:   	Debug an active process
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public DebugActiveProcess

dapId	EQU 8

DebugActiveProcess Proc near
	push ebp
	mov ebp,esp
;
	int 3
	mov eax,1
;
	pop ebp
	ret 4
DebugActiveProcess Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TlsAlloc
;
;       DESCRIPTION:    Allocate TLS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public TlsAlloc

TlsAlloc Proc near
	mov ecx,fs:pvTLSBitmap
	bsf eax, dword ptr [ecx]
	jnz short TlsAllocSuccess

	bsf eax, dword ptr [ecx+4]
	lea eax, [eax+32]
	jnz short TlsAllocSuccess

	mov eax,-1
	jmp TlsAllocDone

TlsAllocSuccess:
	btr dword ptr [ecx], eax

TlsAllocDone:
	ret
TlsAlloc Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TlsFree
;
;       DESCRIPTION:    Free TLS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public TlsFree

TlsFree Proc near
	mov ecx, [esp + 4]
	cmp ecx, 64
	sbb eax, eax
	jnc TlsFreeError

	mov eax,fs:pvTLSBitmap
	bts dword ptr [eax],ecx
	mov eax,1
	jmp TlsFreeDone

TlsFreeError:
	xor eax,eax

TlsFreeDone:
	ret 4
TlsFree Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TlsSetValue
;
;       DESCRIPTION:    Set TLS value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public TlsSetValue

TlsSetValue Proc near
	mov ecx, [esp + 4]
	cmp ecx, 64
	jnc TlsSetError

	mov edx, fs:pvTlsArray
	mov eax, [esp + 8]
	mov [edx + ecx * 4], eax
	mov eax,1
	jmp TlsSetDone

TlsSetError:
	xor eax,eax

TlsSetDone:
	ret 8
TlsSetValue Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           TlsGetValue
;
;       DESCRIPTION:    Get TLS value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public TlsGetValue

TlsGetValue Proc near
	mov ecx, [esp + 4]
	mov fs:pvLastError, -1 
	xor eax, eax
	cmp ecx, 64
	jnc TlsGetError

	mov fs:pvLastError, eax
	mov edx, fs:pvTlsArray
	mov eax, [edx + ecx * 4]

TlsGetError:
	ret 4
TlsGetValue Endp

END
