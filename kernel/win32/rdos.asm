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
; 32-bit interface for RDOS API for Win32 compilers
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  rdos

	.386
	.model flat

include \rdos\kernel\user.def

tib_data	STRUC

pvFirstExcept		DD ?
pvStackUserTop		DD ?
pvStackUserBottom	DD ?
pvLastError			DD ?
pvStackUserSize		DD ?
pvArbitrary			DD ?
pvTEB				DD ?
pvProcessHandle		DD ?
pvThreadHandle		DD ?
pvModuleHandle		DD ?
pvTLSBitmap			DD ?
pvTLSArray			DD ?

tib_data	ENDS

UserGate	MACRO gate_nr
	db 9Ah
	dd gate_nr
	dw 2
			ENDM

		NAME system

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

    
	.code

PAGE

    jnc short tok
;
    xor esi,esi

tok:    


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDebug
;
;                       Put thread in debug-mode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RdosDebug

RdosDebug  Proc
    int 3
    ret
RdosDebug Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetLongRandom
;
;                       Return random 32 bit number using linear congruential method.
;
;       returns:        EAX     out value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RdosGetLongRandom

RdosGetLongRandom  Proc
    ret
RdosGetLongRandom Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetRandom
;
;                       Return random number [0..n] using linear congruential method.
;
;       returns:        EAX     out value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public RdosGetRandom
    
RdosGetRandom  Proc
    push ebp
    mov ebp,esp
    push ecx
;    
    mov ecx,[ebp+8]
    UserGate get_random_nr
    inc ecx
    jz rgrDone
;
    mul ecx
    mov eax,edx

rgrDone:
    pop ecx
    pop ebp
    ret 4
RdosGetRandom   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSwapShort
;
;		description:	Byte reverse a short int
;
;		returns:		Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSwapShort

RdosSwapShort	Proc
	push ebp
	mov ebp,esp
	mov ax,[ebp+8]
	xchg al,ah
	pop ebp
	ret 4
RdosSwapShort	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSwapLong
;
;		description:	Byte reverse a long int
;
;		returns:		Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSwapLong

RdosSwapLong	Proc
	push ebp
	mov ebp,esp
;	
    mov eax,[ebp+8]
	xchg al,ah
	rol eax,16
	xchg al,ah
;
	pop ebp
	ret 4
RdosSwapLong	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LocalToNetworkLong
;
;		description:	Convert a local long to network format
;
;		returns:		Network format
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _LocalToNetworkLong

_LocalToNetworkLong	Proc
	push ebp
	mov ebp,esp
	mov eax,[ebp+8]
	xchg al,ah
	rol eax,16
	xchg al,ah
	pop ebp
	ret
_LocalToNetworkLong	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NetworkToLocalLong
;
;		description:	Convert a network long to local format
;
;		returns:		Local format
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _NetworkToLocalLong

_NetworkToLocalLong	Proc
	push ebp
	mov ebp,esp
	mov eax,[ebp+8]
	xchg al,ah
	rol eax,16
	xchg al,ah
	pop ebp
	ret
_NetworkToLocalLong	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LocalToNetworkShort
;
;		description:	Convert a local short to network format
;
;		returns:		Network format
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _LocalToNetworkShort

_LocalToNetworkShort	Proc
	push ebp
	mov ebp,esp
	mov ax,[ebp+8]
	xchg al,ah
	pop ebp
	ret
_LocalToNetworkShort	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NetworkToLocalShort
;
;		description:	Convert a network short to local format
;
;		returns:		Local format
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public _NetworkToLocalShort

_NetworkToLocalShort	Proc
	push ebp
	mov ebp,esp
	mov ax,[ebp+8]
	xchg al,ah
	pop ebp
	ret
_NetworkToLocalShort	Endp

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

task_start	proc
	mov ax,ds
	mov es,ax
	push fs:pvArbitrary
	push OFFSET task_end
	push edx
	ret
task_start	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateThread
;
;		description:	Create a new thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateThread

task_callb	EQU 8
task_name	EQU 12
task_data	EQU 16
task_stack	EQU 20

RdosCreateThread	PROC
	push ebp
	mov ebp,esp
	push ds
	pushad
;
	mov edx,[ebp].task_callb
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET task_start
	mov ecx,[ebp].task_stack
	mov edi,[ebp].task_name
	mov eax,[ebp].task_data
	mov fs:pvArbitrary,eax
	mov bx,fs
	mov ax,2
	UserGate create_thread_nr
;
	mov eax,10
	UserGate wait_milli_nr
;
	popad
	pop ds
	pop ebp
	ret 16
RdosCreateThread	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreatePrioThread
;
;		description:	Create a new thread, higher priority
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreatePrioThread

tp_callb	EQU 8
tp_prio     EQU 12
tp_name	    EQU 16
tp_data     EQU 20
tp_stack	EQU 24

RdosCreatePrioThread	PROC
	push ebp
	mov ebp,esp
	push ds
	pushad
;
	mov edx,[ebp].tp_callb
	mov ax,cs
	mov ds,ax
	mov esi,OFFSET task_start
	mov ecx,[ebp].tp_stack
	mov edi,[ebp].tp_name
	mov eax,[ebp].tp_data
	mov fs:pvArbitrary,eax
	mov bx,fs
	mov ax,[ebp].tp_prio
	UserGate create_thread_nr
;
	mov eax,10
	UserGate wait_milli_nr
;
	popad
	pop ds
	pop ebp
	ret 20
RdosCreatePrioThread	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetThreadHandle
;
;		description:	Get current thread handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetThreadHandle

RdosGetThreadHandle	PROC
	UserGate get_thread_nr
	movzx eax,ax
	ret
RdosGetThreadHandle	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetThreadState
;
;		description:	Get thread state
;
;       parameters:     Thread #
;                       State buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetThreadState

RdosGetThreadState	PROC
	push ebp
	mov ebp,esp
	push edi
;	
    mov eax,[ebp+8]
    mov edi,[ebp+12]
	UserGate get_thread_state_nr
	jc rgtsFail
;	
    mov eax,1
    jmp rgtsDone
    
rgtsFail:
    xor eax,eax

rgtsDone:
	pop edi
	pop ebp
	ret 8
	ret
RdosGetThreadState	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSuspendThread
;
;		description:	Suspend thread
;
;       parameters:     Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSuspendThread

RdosSuspendThread	PROC
	push ebp
	mov ebp,esp
;	
    mov eax,[ebp+8]
	UserGate suspend_thread_nr
	jc rsfFail
;	
    mov eax,1
    jmp rsfDone
    
rsfFail:
    xor eax,eax

rsfDone:
	pop ebp
	ret 4
	ret
RdosSuspendThread	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSuspendAndSignalThread
;
;		description:	Suspend and signal thread
;
;       parameters:     Thread ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSuspendAndSignalThread

RdosSuspendAndSignalThread	PROC
	push ebp
	mov ebp,esp
;	
    mov eax,[ebp+8]
	UserGate suspend_and_signal_thread_nr
	jc rssfFail
;	
    mov eax,1
    jmp rssfDone
    
rssfFail:
    xor eax,eax

rssfDone:
	pop ebp
	ret 4
	ret
RdosSuspendAndSignalThread	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosExec
;
;		description:	Execute a program
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosExec

RdosExec	PROC
	push ebp
	mov ebp,esp
	push esi
	push edi
;
	mov esi,[ebp+8]
	mov edi,[ebp+12]
	UserGate load_exe_nr
	UserGate get_exit_code_nr
;
	pop edi
	pop esi
	pop ebp
	ret 8
RdosExec	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSpawn
;
;		description:    Create new process and run a program
;
;       parameters:     exe name
;                       cmd line
;                       start directory
;                       &thread handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSpawn

RdosSpawn	PROC
	push ebp
	mov ebp,esp
	push fs
	push ebx
	push edx
	push esi
	push edi
;
    mov dx,ds
    mov fs,dx
    xor edx,edx
	mov esi,[ebp+8]
	mov edi,[ebp+12]
    mov ebx,[ebp+16]
	UserGate spawn_exe_nr
	jc rsFail
;	
    mov ebx,[ebp+20]
    movzx eax,ax
    mov [ebx],eax
;
    movzx eax,dx
    jmp rsDone
    
rsFail:
    xor eax,eax

rsDone:
	pop edi
	pop esi
	pop edx
	pop ebx
	pop fs
	pop ebp
	ret 16
RdosSpawn	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSpawnDebug
;
;		description:    Detach new process and put it into debug state
;
;       parameters:     exe name
;                       cmd line
;                       start directory
;                       &thread handle
;
;       returns:        Process handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSpawnDebug

RdosSpawnDebug	PROC
	push ebp
	mov ebp,esp
	push fs
	push ebx
	push edx
	push esi
	push edi
;
    mov edx,fs:pvModuleHandle
    mov bx,ds
    mov fs,bx
	mov esi,[ebp+8]
	mov edi,[ebp+12]
    mov ebx,[ebp+16]
	UserGate spawn_exe_nr
	jc rsdFail
;	
    mov ebx,[ebp+20]
    movzx eax,ax
    mov [ebx],eax
;
    movzx eax,dx
    jmp rsdDone
    
rsdFail:
    xor eax,eax

rsdDone:
	pop edi
	pop esi
	pop edx
	pop ebx
	pop fs
	pop ebp
	ret 16
RdosSpawnDebug	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCpuReset
;
;		description:    Cpu reset
;
;       parameters:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCpuReset

RdosCpuReset	PROC
	UserGate cpu_reset_nr
	ret
RdosCpuReset  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetVersion
;
;		description:    Get RDOS version
;
;       parameters:     &major
;                       &minor
;                       &release
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetVersion

RdosGetVersion	PROC
	push ebp
	mov ebp,esp
	push eax
	push ecx
	push edx
	push edi
;
	UserGate get_version_nr
;
    movzx edx,dx
    mov edi,[ebp+8]
    mov [edi],edx
;
    movzx eax,ax
    mov edi,[ebp+12]
    mov [edi],eax
;
    movzx eax,cx
    mov edi,[ebp+16]
    mov [edi],eax
;
	pop edi
	pop edx
	pop ecx
	pop eax
	pop ebp
	ret 12
RdosGetVersion  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetFreeHandles
;
;		description:	Get free handles
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFreeHandles

RdosGetFreeHandles	Proc
	UserGate get_free_handles_nr
	movzx eax,ax
	ret
RdosGetFreeHandles	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetFreePhysical
;
;		description:	Get free physical memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFreePhysical

RdosGetFreePhysical	Proc
	UserGate get_free_physical_nr
	ret
RdosGetFreePhysical	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetFreeGdt
;
;		description:	Get free GDT entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFreeGdt

RdosGetFreeGdt	Proc
	UserGate get_free_gdt_nr
	movzx eax,ax
	ret
RdosGetFreeGdt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetFreeSmallKernelLinear
;
;		description:	Get free small memory pool in kernel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFreeSmallKernelLinear

RdosGetFreeSmallKernelLinear	Proc
	UserGate available_small_linear_nr
	ret
RdosGetFreeSmallKernelLinear	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetFreeBigKernelLinear
;
;		description:	Get free big memory pool in kernel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFreeBigKernelLinear

RdosGetFreeBigKernelLinear	Proc
	UserGate available_big_linear_nr
	ret
RdosGetFreeBigKernelLinear	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAllocateMem
;
;		description:	Allocate memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAllocateMem

RdosAllocateMem	Proc
	push ebp
	mov ebp,esp
	push edx
;
	mov eax,[ebp+8]
	UserGate allocate_app_mem_nr
	mov eax,edx
;
	pop edx
	pop ebp
	ret 4
RdosAllocateMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosFreeMem
;
;		description:	Free memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosFreeMem

RdosFreeMem	Proc
	push ebp
	mov ebp,esp
	push edx
;
	mov edx,[ebp+8]
	UserGate free_app_mem_nr
;
	pop edx
	pop ebp
	ret 4
RdosFreeMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAppDebug
;
;		description:	App debug
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAppDebug

RdosAppDebug	Proc
	UserGate app_debug_nr
	ret
RdosAppDebug	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetThreadLinear
;
;		description:	Get thread linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetThreadLinear

RdosGetThreadLinear	Proc
	push ebp
	mov ebp,esp
	push ebx
	push esi
;
	mov bx,[ebp+8]
	mov dx,[ebp+12]
	mov esi,[ebp+16]
	UserGate get_thread_linear_nr
	jc gthlFail
;
    mov eax,edx
    jmp gthlDone

gthlFail:
    xor eax,eax

gthlDone:
	pop esi
	pop ebx
	pop ebp
	ret 12
RdosGetThreadLinear	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosReadThreadMem
;
;		description:	Read thread memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadThreadMem

RdosReadThreadMem	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov dx,[ebp+12]
	mov esi,[ebp+16]
	mov edi,[ebp+20]
	mov ecx,[ebp+24]
	UserGate read_thread_mem_nr
;
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosReadThreadMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWriteThreadMem
;
;		description:	Write thread memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteThreadMem

RdosWriteThreadMem	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov dx,[ebp+12]
	mov esi,[ebp+16]
	mov edi,[ebp+20]
	mov ecx,[ebp+24]
	UserGate write_thread_mem_nr
;
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosWriteThreadMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetDebugThread
;
;		description:	Get debug thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetDebugThread

RdosGetDebugThread	Proc
	UserGate get_debug_thread_nr
	ret
RdosGetDebugThread	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetThreadTss
;
;		description:	Read thread TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetThreadTss

RdosGetThreadTss	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	UserGate get_thread_tss_nr
;
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosGetThreadTss	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetThreadTss
;
;		description:	Write thread TSS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetThreadTss

RdosSetThreadTss	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	UserGate set_thread_tss_nr
;
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosSetThreadTss	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitMilli
;
;		description:	Wait a number of milliseconds
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitMilli

RdosWaitMilli	Proc
	push ebp
	mov ebp,esp
	push eax
;
	mov eax,[ebp+8]
	UserGate wait_milli_nr
;
	pop eax
	pop ebp
	ret 4
RdosWaitMilli	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitMicro
;
;		description:	Wait a number of microseconds
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitMicro

RdosWaitMicro	Proc
	push ebp
	mov ebp,esp
	push eax
;
	mov eax,[ebp+8]
	UserGate wait_micro_nr
;
	pop eax
	pop ebp
	ret 4
RdosWaitMicro	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitUntil
;
;		description:	Wait until tics expires
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitUntil

RdosWaitUntil	Proc
	push ebp
	mov ebp,esp
	push eax
	push edx
;
	mov edx,[ebp+8]
	mov eax,[ebp+4]
	UserGate wait_until_nr
;
    pop edx
	pop eax
	pop ebp
	ret 8
RdosWaitUntil	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateSection
;
;		description:	Create section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateSection

RdosCreateSection	Proc
	push ebx
	UserGate create_user_section_nr
	movzx eax,bx
	pop ebx
	ret
RdosCreateSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDeleteSection
;
;		description:	Delete section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDeleteSection

RdosDeleteSection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate delete_user_section_nr
;
	pop ebx
	pop ebp
	ret 4
RdosDeleteSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosEnterSection
;
;		description:	Enter section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosEnterSection

RdosEnterSection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate enter_user_section_nr
;
	pop ebx
	pop ebp
	ret 4
RdosEnterSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosLeaveSection
;
;		description:	Leave section
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosLeaveSection

RdosLeaveSection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate leave_user_section_nr
;
	pop ebx
	pop ebp
	ret 4
RdosLeaveSection	Endp

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

	public RdosCreateWait

RdosCreateWait	Proc
	push ebx
;
	UserGate create_wait_nr
	movzx eax,bx
;
	pop ebx
	ret
RdosCreateWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseWait
;
;		description:	void RdosCloseWait(int Handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseWait

RdosCloseWait	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_wait_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseWait	Endp

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

	public RdosCheckWait

RdosCheckWait	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	UserGate is_wait_idle_nr
;
    mov eax,ecx
;
    pop ecx
	pop ebx
	pop ebp
	ret 4
RdosCheckWait	Endp

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

	public RdosWaitForever

RdosWaitForever	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	UserGate wait_no_timeout_nr
	jc rwfFail
;
    mov eax,ecx
    jmp rwfDone

rwfFail:
    xor eax,eax

rwfDone:
    pop ecx
	pop ebx
	pop ebp
	ret 4
RdosWaitForever	Endp

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

	public RdosWaitTimeout

RdosWaitTimeout	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
   	mov eax,[ebp+12]
	mov edx,1193
	mul edx
	push edx
	push eax
    UserGate get_system_time_nr
    pop ebx
    add eax,ebx
    pop ebx
    adc edx,ebx
	mov bx,[ebp+8]    	
	UserGate wait_timeout_nr
	jc rwtFail
;
    mov eax,ecx
    jmp rwtDone

rwtFail:
    xor eax,eax

rwtDone:
    pop edx
    pop ecx
	pop ebx
	pop ebp
	ret 8
RdosWaitTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitUntilTimeout
;
;		description:	int RdosWaitUntilTimeout(int Handle, long Msb, long Lsb) 
;
;       returns:        Signalled ID or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitUntilTimeout

RdosWaitUntilTimeout	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
   	mov eax,[ebp+16]
   	mov edx,[ebp+12]
	mov bx,[ebp+8]    	
	UserGate wait_timeout_nr
	jc rwutFail
;
    mov eax,ecx
    jmp rwutDone

rwutFail:
    xor eax,eax

rwutDone:
    pop edx
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosWaitUntilTimeout	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosStopWait
;
;		description:	void RdosStopWait(int Handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosStopWait

RdosStopWait	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate stop_wait_nr
;
	pop ebx
	pop ebp
	ret 4
RdosStopWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosRemoveWait
;
;		description:	void RdosRemoveWait(int Handle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosRemoveWait

RdosRemoveWait	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	mov ecx,[ebp+12]
	UserGate remove_wait_nr
;
    pop ecx
	pop ebx
	pop ebp
	ret 8
RdosRemoveWait	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateSignal
;
;		description:	void RdosCreateSignal()
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateSignal

RdosCreateSignal	Proc
    push bx
	UserGate create_signal_nr
	movzx eax,bx
	pop bx
	ret
RdosCreateSignal	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosResetSignal
;
;		description:	void RdosResetSignal(int Handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosResetSignal

RdosResetSignal	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate reset_signal_nr
;
	pop ebx
	pop ebp
	ret 4
RdosResetSignal	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosIsSignalled
;
;		description:	void RdosIsSignalled(int Handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosIsSignalled

RdosIsSignalled	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate is_signalled_nr
	jc risdFree
;
    mov eax,1
    jmp risdDone	

risdFree:
    xor eax,eax

risdDone:
	pop ebx
	pop ebp
	ret 4
RdosIsSignalled	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetSignal
;
;		description:	void RdosSetSignal(int Handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetSignal

RdosSetSignal	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate set_signal_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSetSignal	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosFreeSignal
;
;		description:	void RdosFreeSignal(int Handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosFreeSignal

RdosFreeSignal	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate free_signal_nr
;
	pop ebx
	pop ebp
	ret 4
RdosFreeSignal	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForSignal
;
;		description:	void RdosAddWaitForSignal(int Handle, int SignalHandle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddWaitForSignal

RdosAddWaitForSignal	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	mov ecx,[ebp+16]
	UserGate add_wait_for_signal_nr
;
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosAddWaitForSignal	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForKeyboard
;
;		description:	void RdosAddWaitForKeyboard(int Handle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddWaitForKeyboard

RdosAddWaitForKeyboard	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	mov ecx,[ebp+12]
	UserGate add_wait_for_keyboard_nr
;
    pop ecx
	pop ebx
	pop ebp
	ret 8
RdosAddWaitForKeyboard	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForMouse
;
;		description:	void RdosAddWaitForMouse(int Handle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddWaitForMouse

RdosAddWaitForMouse	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	mov ecx,[ebp+12]
	UserGate add_wait_for_mouse_nr
;
    pop ecx
	pop ebx
	pop ebp
	ret 8
RdosAddWaitForMouse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForCom
;
;		description:	void RdosAddWaitForCom(int Handle, int ComHandle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddWaitForCom

RdosAddWaitForCom	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	mov ecx,[ebp+16]
	UserGate add_wait_for_com_nr
;
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosAddWaitForCom	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddWaitForAdc
;
;		description:	void RdosAddWaitForAdc(int Handle, int AdcHandle, void *ID)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddWaitForAdc

RdosAddWaitForAdc	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	mov ecx,[ebp+16]
	UserGate add_wait_for_adc_nr
;
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosAddWaitForAdc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetTextMode
;
;		description:	int RdosSetTextMode();
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetTextMode

RdosSetTextMode	Proc
	pushad
	mov ax,3
    UserGate set_video_mode_nr
	popad
	ret
RdosSetTextMode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetVideoMode
;
;		description:	int RdosSetVideoMode(int *BitsPerPixel, 
;						int *xres, int *yres, int *linesize, void **buffer);
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetVideoMode

RdosSetVideoMode	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov edi,[ebp+8]
	mov ax,[edi]
	mov edi,[ebp+12]
	mov cx,[edi]
	mov edi,[ebp+16]
	mov dx,[edi]	
	UserGate get_video_mode_nr
	jc set_video_fail
;
    UserGate set_video_mode_nr
    jc set_video_fail
;
	push edi
	mov edi,[ebp+8]
	movzx eax,ax
	mov [edi],eax
	mov edi,[ebp+12]
	movzx ecx,cx
	mov [edi],ecx
	mov edi,[ebp+16]
	movzx edx,dx
	mov [edi],edx
	mov edi,[ebp+20]
	movzx esi,si
	mov [edi],si
	pop edi
	mov eax,[ebp+24]
	mov [eax],edi
	movzx eax,bx
	jmp set_video_done

set_video_fail:
	xor eax,eax
	mov edi,[ebp+8]
	mov [edi],eax
	mov edi,[ebp+12]
	mov [edi],eax
	mov edi,[ebp+16]
	mov [edi],eax
	mov edi,[ebp+20]
	mov [edi],eax
	mov edi,[ebp+24]
	mov [edi],eax

set_video_done:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosSetVideoMode	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetClipRect
;
;		description:	RdosSetClipRect(handle, xmin, xmax, ymin, ymax)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetClipRect

RdosSetClipRect	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov si,[ebp+20]
	mov di,[ebp+24]
	UserGate set_clip_rect_nr
;
    pop edi
    pop esi
    pop edx
    pop ecx
	pop ebx
	pop ebp
	ret 20
RdosSetClipRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosClearClipRect
;
;		description:	RdosClearClipRect(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosClearClipRect

RdosClearClipRect	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate clear_clip_rect_nr
;
	pop ebx
	pop ebp
	ret 4
RdosClearClipRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetDrawColor
;
;		description:	RdosSetDrawColor(handle, color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetDrawColor

RdosSetDrawColor	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate set_drawcolor_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetDrawColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetLGOP
;
;		description:	RdosSetLGOP(handle, lgop)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetLGOP

RdosSetLGOP	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	UserGate set_lgop_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetLGOP	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetHollowStyle
;
;		description:	RdosSetHollowStyle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetHollowStyle

RdosSetHollowStyle	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate set_hollow_style_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSetHollowStyle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetFilledStyle
;
;		description:	RdosSetFilledStyle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFilledStyle

RdosSetFilledStyle	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate set_filled_style_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSetFilledStyle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosOpenFont
;
;		description:	RdosOpenFont(height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenFont

RdosOpenFont	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov ax,[ebp+8]
	UserGate open_font_nr
	movzx eax,bx
;
	pop ebx
	pop ebp
	ret 4
RdosOpenFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseFont
;
;		description:	RdosCloseFont(font)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseFont

RdosCloseFont	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_font_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetStringMetrics
;
;		description:	RdosGetStringMetrics(font, str, &width, &height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetStringMetrics

RdosGetStringMetrics	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	UserGate get_string_metrics_nr
;
	mov edi,[ebp+16]
	movzx ecx,cx
	mov [edi],ecx
	mov edi,[ebp+20]
	movzx edx,dx
	mov [edi],edx
;
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosGetStringMetrics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetFont
;
;		description:	RdosSetFont(handle, font)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFont

RdosSetFont	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	UserGate set_font_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetFont	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetPixel
;
;		description:	RdosGetPixel(handle, x, y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetPixel

RdosGetPixel	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	UserGate get_pixel_nr
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosGetPixel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetPixel
;
;		description:	RdosSetPixel(handle, x, y)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetPixel

RdosSetPixel	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	UserGate set_pixel_nr
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosSetPixel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosBlit
;
;		description:	RdosBlit(SrcHandle, DestHandle, width, height,
;								 SrcX, SrcY, DestX, DestY);
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosBlit

RdosBlit	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov ax,[ebp+8]
	mov bx,[ebp+12]
	mov cx,[ebp+16]
	mov dx,[ebp+20]
	mov si,[ebp+28]
	shl esi,16
	mov si,[ebp+24]
	mov di,[ebp+36]
	shl edi,16
	mov di,[ebp+32]
	UserGate blit_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 32
RdosBlit	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawMask
;
;		description:	RdosDrawMask(handle, mask, RowSize, width, height,
;					 				 SrcX, SrcY, DestX, DestY); 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawMask

RdosDrawMask	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ax,[ebp+16]
	mov si,[ebp+24]
	shl esi,16
	mov si,[ebp+20]
	mov cx,[ebp+32]
	shl ecx,16
	mov cx,[ebp+28]
	mov dx,[ebp+40]
	shl edx,16
	mov dx,[ebp+36]
	UserGate draw_mask_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 36
RdosDrawMask	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawLine
;
;		description:	RdosDrawLine(handle, x1, y1, x2, y2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawLine

RdosDrawLine	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov si,[ebp+20]
	mov di,[ebp+24]
	UserGate draw_line_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosDrawLine	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawString
;
;		description:	RdosDrawString(handle, x, y, str)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawString

RdosDrawString	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov edi,[ebp+20]
	UserGate draw_string_nr
;
	pop edi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosDrawString	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawRect
;
;		description:	RdosDrawRect(handle, x, y, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawRect

RdosDrawRect	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov si,[ebp+20]
	mov di,[ebp+24]
	UserGate draw_rect_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosDrawRect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDrawEllipse
;
;		description:	RdosDrawEllipse(handle, x, y, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDrawEllipse

RdosDrawEllipse	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov si,[ebp+20]
	mov di,[ebp+24]
	UserGate draw_ellipse_nr
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosDrawEllipse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateBitmap
;
;		description:	RdosCreateBitmap(BitsPerPixel, width, height)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateBitmap

RdosCreateBitmap	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov ax,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	UserGate create_bitmap_nr
	movzx eax,bx
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosCreateBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDuplicateBitmapHandle
;
;		description:	RdosDuplicateBitmapHandle(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDuplicateBitmapHandle

RdosDuplicateBitmapHandle	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate dup_bitmap_handle_nr
	movzx eax,bx
;
	pop ebx
	pop ebp
	ret 4
RdosDuplicateBitmapHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseBitmap
;
;		description:	RdosCloseBitmap(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseBitmap

RdosCloseBitmap	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_bitmap_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateStringBitmap
;
;		description:	RdosCreateStringBitmap(font, str)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateStringBitmap

RdosCreateStringBitmap	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	UserGate create_string_bitmap_nr
	movzx eax,bx
;
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosCreateStringBitmap	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetBitmapInfo
;
;		description:	RdosGetBitmapInfo(handle, &BitsPerPixel, &width, &height,
;					   						&linesize, &buffer)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetBitmapInfo

RdosGetBitmapInfo	Proc
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov bx,[ebp+8]
	UserGate get_bitmap_info_nr
	jc gbiFail
;
	push edi
	mov edi,[ebp+12]
	movzx eax,al
	mov [edi],eax
	mov edi,[ebp+16]
	movzx ecx,cx
	mov [edi],ecx
	mov edi,[ebp+20]
	movzx edx,dx
	mov [edi],edx
	mov edi,[ebp+24]
	movzx esi,si
	mov [edi],esi
	pop edi
	mov eax,[ebp+28]
	mov [eax],edi
	jmp gbiDone

gbiFail:
	xor eax,eax
	mov edi,[ebp+12]
	mov [edi],eax
	mov edi,[ebp+16]
	mov [edi],eax
	mov edi,[ebp+20]
	mov [edi],eax
	mov edi,[ebp+24]
	mov [edi],eax
	mov edi,[ebp+28]
	mov [edi],eax

gbiDone:
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 24
RdosGetBitmapInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCreateSprite
;
;		description:	RdosCreateSprite(dest, bitmap, mask, lgop)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateSprite

RdosCreateSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	mov ax,[ebp+20]
	UserGate create_sprite_nr
	movzx eax,bx
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosCreateSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCloseSprite
;
;		description:	RdosCloseSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseSprite

RdosCloseSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_sprite_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosShowSprite
;
;		description:	RdosShowSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosShowSprite

RdosShowSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate show_sprite_nr
;
	pop ebx
	pop ebp
	ret 4
RdosShowSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosHideSprite
;
;		description:	RdosHideSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosHideSprite

RdosHideSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate hide_sprite_nr
;
	pop ebx
	pop ebp
	ret 4
RdosHideSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosMoveSprite
;
;		description:	RdosMoveSprite(handle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosMoveSprite

RdosMoveSprite	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov bx,[ebp+8]
	mov cx,[ebp+12]
	mov dx,[ebp+16]
	UserGate move_sprite_nr
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosMoveSprite	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetForeColor
;
;		description:	SetForeColor(color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetForeColor

RdosSetForeColor	Proc
	push ebp
	mov ebp,esp
	push eax
;
	mov al,[ebp+8]
	UserGate set_forecolor_nr
;
	pop eax
	pop ebp
	ret 4
RdosSetForeColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetBackColor
;
;		description:	SetBackColor(color)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetBackColor

RdosSetBackColor	Proc
	push ebp
	mov ebp,esp
	push eax
;
	mov al,[ebp+8]
	UserGate set_backcolor_nr
;
	pop eax
	pop ebp
	ret 4
RdosSetBackColor	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetSysTime
;
;		description:	gets system time
;
;		PARAMETERS:		int *msb
;						int *lsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetSysTime

RdosGetSysTime	Proc
	push ebp
	mov ebp,esp
	push eax
	push edx
	push esi
;
	UserGate get_system_time_nr
;
	mov esi,[ebp+8]
	mov [esi],edx
;
	mov esi,[ebp+12]
	mov [esi],eax
;
	pop esi
	pop edx
	pop eax
	pop ebp
	ret 8
RdosGetSysTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetTime
;
;		description:	gets time
;
;		PARAMETERS:		int *msb
;						int *lsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetTime

RdosGetTime	Proc
	push ebp
	mov ebp,esp
	push eax
	push edx
	push esi
;
	UserGate get_time_nr
;
	mov esi,[ebp+8]
	mov [esi],edx
;
	mov esi,[ebp+12]
	mov [esi],eax
;
	pop esi
	pop edx
	pop eax
	pop ebp
	ret 8
RdosGetTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSetTime
;
;		description:	sets time
;
;		PARAMETERS:		int msb
;						int lsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetTime

RdosSetTime	Proc
	push ebp
	mov ebp,esp
	pushad
;    
    mov edi,[ebp+8]
    mov esi,[ebp+12]
	UserGate get_system_time_nr
    sub esi,eax
    sbb edi,edx
    mov eax,esi
    mov edx,edi
    UserGate update_time_nr
;
	popad
	pop ebp
	ret 8
RdosSetTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDosTimeDateToTics
;
;		description:	Convert DOS time & date to tics
;
;		PARAMETERS:		short date, time
;						long *msb, lsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDosTimeDateToTics

RdosDosTimeDateToTics	Proc
	push ebp
	mov ebp,esp
	pushad
;	
	mov dx,[ebp+8]
	mov ax,dx
	shr dx,9
	add dx,1980
	mov cx,ax
	shr cx,5
	mov ch,cl
	and ch,0Fh
	mov cl,al
	and cl,1Fh
	mov bx,[ebp+12]
	mov ax,bx
	shr bx,11
	mov bh,bl
	shr ax,5
	and al,3Fh
	mov bl,al
	mov ax,[ebp+12]
	mov ah,al
	add ah,ah
	and ah,3Fh
	UserGate time_to_binary_nr
;	
	mov ebx,[ebp+16]
	mov [ebx],edx
;
    mov ebx,[ebp+20]
    mov [ebx],eax
;
	popad
	pop ebp
	ret 16
RdosDosTimeDateToTics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosTicsToDosTimeDate
;
;		description:	Convert tics to DOS time & date
;
;		PARAMETERS:		long msb, lsb
;                       short* date, time
;						;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosTicsToDosTimeDate

RdosTicsToDosTimeDate	Proc
	push ebp
	mov ebp,esp
	pushad
;
    mov edx,[ebp+8]
    mov eax,[ebp+12]	
	UserGate binary_to_time_nr
	shl cl,3
	shr cx,3
	sub dx,1980
	mov dh,dl
	shl dh,1
	xor dl,dl
	or dx,cx
	mov al,ah
	shr al,1
	shl bl,2
	shl bx,3
	or bl,al
;	
	mov ebx,[ebp+16]
	mov [ebx],dx
;
    mov ebx,[ebp+20]
    mov [ebx],bx
;
	popad
	pop ebp
	ret 16
RdosTicsToDosTimeDate	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDecodeMsbTics
;
;		description:	Convert MSB tics to record form
;
;		PARAMETERS:		int MSB
;						int *year
;						int *month
;						int *day
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDecodeMsbTics

ctMSB		EQU 8
ctYear		EQU 12
ctMonth		EQU 16
ctDay		EQU 20
ctHour      EQU 24

RdosDecodeMsbTics	Proc
	push ebp
	mov ebp,esp
	pushad
;
	mov edx,[ebp].ctMSB
	xor eax,eax
	UserGate binary_to_time_nr
;
	mov esi,[ebp].ctYear
	movzx edx,dx
	mov [esi],edx
;
	mov esi,[ebp].ctMonth
	movzx edx,ch
	mov [esi],edx
;
	mov esi,[ebp].ctDay
	movzx edx,cl
	mov [esi],edx
;
	mov esi,[ebp].ctHour
	movzx edx,bh
	mov [esi],edx
;
	popad
	pop ebp
	ret 20
RdosDecodeMsbTics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDecodeLsbTics
;
;		description:	Convert LSB tics to min, sec, milli & micro
;
;		PARAMETERS:		int LSB
;						int *min
;						int *sec
;                       int *milli
;                       int *micro
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDecodeLsbTics

dltLSB		EQU 8
dltMin		EQU 12
dltSec		EQU 16
dltMilli    EQU 20
dltMicro    EQU 24

RdosDecodeLsbTics	Proc
	push ebp
	mov ebp,esp
	pushad
;
	mov eax,[ebp].dltLSB
	mov edx,60
	mul edx
    mov ebx,[ebp].dltMin
    mov [ebx],edx
;
    mov edx,60
    mul edx
    mov ebx,[ebp].dltSec
    mov [ebx],edx
;
    mov edx,1000
    mul edx
    mov ebx,[ebp].dltMilli
    mov [ebx],edx
;
    mov edx,1000
    mul edx
    mov ebx,[ebp].dltMicro
    mov [ebx],edx                
;
	popad
	pop ebp
	ret 20
RdosDecodeLsbTics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCodeMsbTics
;
;		description:	Convert record to msb tics
;
;		PARAMETERS:		int year
;						int month
;						int day
;                       int hour
;
;       RETURNS:        msb tics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCodeMsbTics

RdosCodeMsbTics	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov dx,[ebp+8]
	mov ch,[ebp+12]
	mov cl,[ebp+16]
	mov bh,[ebp+20]
	xor bl,bl
	xor ah,ah
	UserGate time_to_binary_nr
	mov eax,edx
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosCodeMsbTics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosCodeLsbTics
;
;		description:	Convert record to lsb tics
;
;		PARAMETERS:		int min
;						int sec
;						int milli
;                       int micro
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCodeLsbTics

RdosCodeLsbTics	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
    xor dx,dx
    xor cx,cx
    xor bh,bh
    mov bl,[ebp+8]
	mov ah,[ebp+12]
	UserGate time_to_binary_nr
    mov ebx,eax
    mov eax,[ebp+16]
	mov edx,1193046
    mul edx
    mov ecx,eax
    mov eax,[ebp+20]
    mov edx,1193
    mul edx
    add eax,ecx
    xor edx,edx
    mov ecx,1000
    div ecx
    add eax,ebx
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosCodeLsbTics	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDayOfWeek
;
;		description:	Get day of week
;
;		PARAMETERS:		int year
;						int month
;						int day
;
;       RETURNS:        day of week (0 = sun)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDayOfWeek

rdowYear	EQU 8
rdowMonth	EQU 12
rdowDay		EQU 16

RdosDayOfWeek	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov dx,[ebp].rdowYear
	mov ch,[ebp].rdowMonth
	mov cl,[ebp].rdowDay
    xor bx,bx
    xor ah,ah
	UserGate adjust_time_nr
	push dx
	mov eax,365
	imul dx
	push dx
	push ax
	pop ebx
	pop dx
	UserGate passed_days_nr
	dec dx
	shr dx,2
	inc dx
	add ax,dx
	add eax,ebx
    xor edx,edx
    add eax,5
    mov ebx,7
    div ebx
    movzx eax,dl
;
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosDayOfWeek	Endp

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

	public RdosAddTics

RdosAddTics	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+16]
	mov ebx,[ebp+12]
	add [ebx],eax
	mov ebx,[ebp+8]
	adc dword ptr [ebx],0	
;
	pop ebx
	pop ebp
	ret 12
RdosAddTics	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosAddMicro
;
;		description:	add micro seconds
;
;		PARAMETERS:		long *msb
;						long *lsb
;						long micro
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddMicro

RdosAddMicro	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+16]
	mov edx,1193
	imul edx
	mov ebx,1000
	xor edx,edx
	idiv ebx
	mov ebx,[ebp+12]
	add [ebx],eax
	mov ebx,[ebp+8]
	adc dword ptr [ebx],0
;
	pop ebx
	pop ebp
	ret 12
RdosAddMicro	Endp

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

	public RdosAddMilli

RdosAddMilli	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+16]
	mov edx,1193
	imul edx
	mov ebx,[ebp+12]
	add [ebx],eax
	mov ebx,[ebp+8]
	adc [ebx],edx
;
	pop ebx
	pop ebp
	ret 12
RdosAddMilli	Endp

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

	public RdosAddSec

RdosAddSec	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+16]
	mov edx,1193000
	imul edx
	mov ebx,[ebp+12]
	add [ebx],eax
	mov ebx,[ebp+8]
	adc [ebx],edx
;
	pop ebx
	pop ebp
	ret 12
RdosAddSec	Endp

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

	public RdosAddMin

RdosAddMin	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+16]
	mov edx,1193046*60
	imul edx
	mov ebx,[ebp+12]
	add [ebx],eax
	mov ebx,[ebp+8]
	adc [ebx],edx
;
	pop ebx
	pop ebp
	ret 12
RdosAddMin	Endp

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

	public RdosAddHour

RdosAddHour	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+16]
	mov ebx,[ebp+8]
	add [ebx],eax
;
	pop ebx
	pop ebp
	ret 12
RdosAddHour	Endp

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

	public RdosAddDay

RdosAddDay	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+16]
	mov edx,24
	mul edx
	mov ebx,[ebp+8]
	add [ebx],eax
;
	pop ebx
	pop ebp
	ret 12
RdosAddDay	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosSyncTime
;
;		description:	Synchronize time with NTP
;
;		PARAMETERS:		long IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSyncTime

rstIP		EQU 8

RdosSyncTime	Proc
	push ebp
	mov ebp,esp
	pushad
;
	mov edx,[ebp].dltLSB
	UserGate sync_time_nr
	jc RdosSyncTimeFail
;
	mov eax,1
	jmp RdosSyncTimeDone

RdosSyncTimeFail:
	xor eax,eax

RdosSyncTimeDone:
	popad
	pop ebp
	ret 4
RdosSyncTime	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosGetMaxComPort
;
;		description:	Get max com port id
;
;		RETURNS:		Max com port id
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetMaxComPort

RdosGetMaxComPort	Proc
	UserGate get_max_com_port_nr
	movzx eax,al
	ret
RdosGetMaxComPort	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosOpenCom
;
;		description:	Open comport
;
;		PARAMETERS:		port_id 		Port #
;						baud_rate   	baudrate
;						parity			parity 'N', 'E' or 'O'
;						data_bits		# of data bits
;						stop_bits		# of stop bits
;						send_buf_size	size of transmit buffer
;						rec_buf_size	size of receive buffer
;
;		RETURNS:		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenCom

port_id 		EQU 8
baud_rate   	EQU 12
parity			EQU 16
data_bits		EQU 20
stop_bits		EQU 24
send_buf_size	EQU 28
rec_buf_size	EQU 32

RdosOpenCom	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
	push esi
	push edi
;
	mov al,[ebp].port_id
	mov ah,[ebp].data_bits
	mov bl,[ebp].stop_bits
	mov bh,[ebp].parity
	mov ecx,[ebp].baud_rate
	mov si,[ebp].send_buf_size
	mov di,[ebp].rec_buf_size
	UserGate open_com_nr
	movzx eax,bx
;
	pop edi
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 28
RdosOpenCom	Endp

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

	public RdosCloseCom

RdosCloseCom	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_com_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseCom	Endp

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

	public RdosFlushCom

RdosFlushCom	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate flush_com_nr
;
	pop ebx
	pop ebp
	ret 4
RdosFlushCom	Endp

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

	public RdosReadCom

RdosReadCom	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate read_com_nr
;
	pop ebx
	pop ebp
	ret 4
RdosReadCom	ENDP

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

	public RdosWriteCom

RdosWriteCom	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov al,[ebp+12]
	UserGate write_com_nr
	movzx eax,al
;
	pop ebx
	pop ebp
	ret 8
RdosWriteCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosWaitForSendCompletedCom
;
;		description:	Wait until send buffer is empty
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitForSendCompletedCom

RdosWaitForSendCompletedCom	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate wait_for_send_completed_com_nr
;
	pop ebx
	pop ebp
	ret 4
RdosWaitForSendCompletedCom	ENDP

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosEnableCts
;
;		description:	Enable CTS signal
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosEnableCts

RdosEnableCts	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate enable_cts_nr
;
	pop ebx
	pop ebp
	ret 4
RdosEnableCts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDisableCts
;
;		description:	Disable CTS signal
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDisableCts

RdosDisableCts	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate disable_cts_nr
;
	pop ebx
	pop ebp
	ret 4
RdosDisableCts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosEnableAutoR
;
;		description:	Enable auto RTS signal generation for RS485
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosEnableAutoRts

RdosEnableAutoRts	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate enable_auto_rts_nr
;
	pop ebx
	pop ebp
	ret 4
RdosEnableAutoRts	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			RdosDisableAutoRts
;
;		description:	Disable auto RTS signal generation for RS485
;
;		PARAMETERS:		hport		port handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDisableAutoRts

RdosDisableAutoRts	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate disable_auto_rts_nr
;
	pop ebx
	pop ebp
	ret 4
RdosDisableAutoRts	Endp

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

	public RdosSetDtr

RdosSetDtr	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate set_dtr_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSetDtr	Endp

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

	public RdosResetDtr

RdosResetDtr	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate reset_dtr_nr
;
	pop ebx
	pop ebp
	ret 4
RdosResetDtr	Endp

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

	public RdosSetRts

RdosSetRts	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate set_rts_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSetRts	Endp

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

	public RdosResetRts

RdosResetRts	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate reset_rts_nr
;
	pop ebx
	pop ebp
	ret 4
RdosResetRts	Endp

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

	public RdosGetReceiveBufferSpace

RdosGetReceiveBufferSpace	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_com_receive_space_nr
;
	pop ebx
	pop ebp
	ret 4
RdosGetReceiveBufferSpace	Endp

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

	public RdosGetSendBufferSpace

RdosGetSendBufferSpace	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_com_send_space_nr
;
	pop ebx
	pop ebp
	ret 4
RdosGetSendBufferSpace	Endp

PAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenFile
;
;		DESCRIPTION:	Opens a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenFile

RdosOpenFile	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov edi,[ebp+8]
	mov cl,[ebp+12]
	UserGate open_file_nr
	jc OpenFileFailed
	movzx eax,bx
	jmp OpenFileDone

OpenFileFailed:
	xor eax,eax

OpenFileDone:
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 8
RdosOpenFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateFile
;
;		DESCRIPTION:	Creates a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateFile

RdosCreateFile	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov edi,[ebp+8]
	mov cx,[ebp+12]
	UserGate create_file_nr
	jc CreateFileFailed
	movzx eax,bx
	jmp CreateFileDone

CreateFileFailed:
	xor eax,eax

CreateFileDone:
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 8
RdosCreateFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseFile
;
;		DESCRIPTION:	Close a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseFile

RdosCloseFile	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_file_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosIsDevice
;
;		DESCRIPTION:	Check if file is a device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosIsDevice

RdosIsDevice	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_ioctl_data_nr
	test dx,8000h
	jz ridFail
;
	mov eax,1
	jmp ridDone

ridFail:
	xor eax,eax

ridDone:
	pop ebx
	pop ebp
	ret 4
RdosIsDevice	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosDuplFile
;
;		DESCRIPTION:	Duplicate file handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDuplFile

RdosDuplFile	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate dupl_file_nr
	jc DuplFileFailed
	movzx eax,bx
	jmp DuplFileDone

DuplFileFailed:
	xor eax,eax

DuplFileDone:
	pop ebx
	pop ebp
	ret 4
RdosDuplFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFileSize
;
;		DESCRIPTION:	Get size of a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFileSize

RdosGetFileSize	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_file_size_nr
	jnc GetFileSizeDone

GetFileSizeFail:
	xor eax,eax

GetFileSizeDone:
	pop ebx
	pop ebp
	ret 4
RdosGetFileSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFileSize
;
;		DESCRIPTION:	Set size of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFileSize

RdosSetFileSize	PROC
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate set_file_size_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetFileSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFilePos
;
;		DESCRIPTION:	Get position in a file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFilePos

RdosGetFilePos	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_file_pos_nr
	jnc GetFilePosDone

GetFilePosFail:
	xor eax,eax

GetFilePosDone:
	pop ebx
	pop ebp
	ret 4
RdosGetFilePos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFilePos
;
;		DESCRIPTION:	Set position in file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFilePos

RdosSetFilePos	PROC
	push ebp
	mov ebp,esp
	push eax
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate set_file_pos_nr
;
	pop ebx
	pop eax
	pop ebp
	ret 8
RdosSetFilePos	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFileTime
;
;		DESCRIPTION:	Get file date & time
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFileTime

RdosGetFileTime	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov bx,[ebp+8]
	UserGate get_file_time_nr
	jc GetFileTimeDone
;
	mov edi,[ebp+12]
	mov [edi],edx
;
	mov edi,[ebp+16]
	mov [edi],eax

GetFileTimeDone:
	pop edi
	pop ebx
	pop ebp
	ret 12
RdosGetFileTime	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFileTime
;
;		DESCRIPTION:	Set date & time for file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFileTime

RdosSetFileTime	PROC
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push edx
;
	mov bx,[ebp+8]
	mov edx,[ebp+12]
	mov eax,[ebp+16]
	UserGate set_file_time_nr
;
	pop edx
	pop ebx
	pop eax
	pop ebp
	ret 12
RdosSetFileTime	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadFile
;
;		DESCRIPTION:	Read data from file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadFile

RdosReadFile	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate read_file_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosReadFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteFile
;
;		DESCRIPTION:	Write data to file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteFile

RdosWriteFile	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate write_file_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosWriteFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateMapping
;
;		DESCRIPTION:	Create file mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateMapping

RdosCreateMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+8]
	UserGate create_mapping_nr
	movzx eax,bx
;
	pop ebx
	pop ebp
	ret 4
RdosCreateMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateNamedMapping
;
;		DESCRIPTION:	Create file named mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateNamedMapping

RdosCreateNamedMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	mov eax,[ebp+12]
	UserGate create_named_mapping_nr
	movzx eax,bx
;
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosCreateNamedMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateNamedFileMapping
;
;		DESCRIPTION:	Create file named file mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateNamedFileMapping

RdosCreateNamedFileMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	mov eax,[ebp+12]
	mov bx,[ebp+16]
	UserGate create_named_file_mapping_nr
	movzx eax,bx
;
	pop edi
	pop ebx
	pop ebp
	ret 12
RdosCreateNamedFileMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenNamedMapping
;
;		DESCRIPTION:	Open named mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenNamedMapping

RdosOpenNamedMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	UserGate open_named_mapping_nr
	movzx eax,bx
;
	pop edi
	pop ebx
	pop ebp
	ret 4
RdosOpenNamedMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSyncMapping
;
;		DESCRIPTION:	Sync mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSyncMapping

RdosSyncMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate sync_mapping_nr
;
	pop ebx
	pop ebp
	ret 4
RdosSyncMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseMapping
;
;		DESCRIPTION:	Close mapping
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseMapping

RdosCloseMapping	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_mapping_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseMapping	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosMapView
;
;		DESCRIPTION:	Map view into memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosMapView

RdosMapView	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate map_view_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosMapView	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosUnmapView
;
;		DESCRIPTION:	Unmap view from memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosUnmapView

RdosUnmapView	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate unmap_view_nr
;
	pop ebx
	pop ebp
	ret 4
RdosUnmapView	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetCurDrive
;
;		DESCRIPTION:	Set current drive
;
;		PARAMETER:		Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetCurDrive

RdosSetCurDrive	PROC
	push ebp
	mov ebp,esp
;
	mov al,[ebp+8]
	UserGate set_cur_drive_nr
	jc rscdrFail

    mov eax,1
    jmp rscdrDone

rscdrFail:
    xor eax,eax

rscdrDone:
	pop ebp
	ret 4
RdosSetCurDrive	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetCurDrive
;
;		DESCRIPTION:	Get current drive
;
;		RETURNS:		Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetCurDrive

RdosGetCurDrive	PROC
	push ebp
	mov ebp,esp
;
    xor eax,eax
	UserGate get_cur_drive_nr
	movzx eax,al
;
	pop ebp
	ret
RdosGetCurDrive	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetCurDir
;
;		DESCRIPTION:	Set current directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetCurDir

RdosSetCurDir	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate set_cur_dir_nr
	jc rscdFail

    mov eax,1
    jmp rscdDone

rscdFail:
    xor eax,eax

rscdDone:
	pop edi
	pop ebp
	ret 4
RdosSetCurDir	ENDP

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

	public RdosGetCurDir

RdosGetCurDir	PROC
	push ebp
	mov ebp,esp
	push edi
;
    mov al,[ebp+8]
	mov edi,[ebp+12]
	UserGate get_cur_dir_nr
	jc rgcdFail

    mov eax,1
    jmp rgcdDone

rgcdFail:
    xor eax,eax

rgcdDone:
	pop edi
	pop ebp
	ret 8
RdosGetCurDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosMakeDir
;
;		DESCRIPTION:	Make a new directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosMakeDir

RdosMakeDir	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate make_dir_nr
	jc mdFail

    mov eax,1
    jmp mdDone

mdFail:
    xor eax,eax

mdDone:
	pop edi
	pop ebp
	ret 4
RdosMakeDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosRemoveDir
;
;		DESCRIPTION:	Remove a directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosRemoveDir

RdosRemoveDir	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate remove_dir_nr
	jc rdFail

    mov eax,1
    jmp rdDone

rdFail:
    xor eax,eax

rdDone:
	pop edi
	pop ebp
	ret 4
RdosRemoveDir	ENDP

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

	public RdosRenameFile

RdosRenameFile	PROC
	push ebp
	mov ebp,esp
	push esi
	push edi
;
	mov edi,[ebp+8]
	mov esi,[ebp+12]
	UserGate rename_file_nr
	jc rfFail

    mov eax,1
    jmp rfDone

rfFail:
    xor eax,eax

rfDone:
	pop edi
	pop esi
	pop ebp
	ret 8
RdosRenameFile	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosDeleteFile
;
;		DESCRIPTION:	Delete a file
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDeleteFile

RdosDeleteFile	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate delete_file_nr
	jc dfFail

    mov eax,1
    jmp dfDone

dfFail:
    xor eax,eax

dfDone:
	pop edi
	pop ebp
	ret 4
RdosDeleteFile	ENDP

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

	public RdosGetFileAttribute

RdosGetFileAttribute	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edi
;
	mov edi,[ebp+8]
	UserGate get_file_attribute_nr
	jc gfaFail
;
    mov edi,[ebp+12]
    movzx ecx,cx
    mov [edi],ecx
    mov eax,1
    jmp gfaDone

gfaFail:
    xor eax,eax

gfaDone:
	pop edi
	pop ecx
	pop ebp
	ret 8
RdosGetFileAttribute	ENDP

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

	public RdosSetFileAttribute

RdosSetFileAttribute	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edi
;
	mov edi,[ebp+8]
	mov cx,[ebp+12]
	UserGate set_file_attribute_nr
	jc sfaFail
;
    mov eax,1
    jmp sfaDone

sfaFail:
    xor eax,eax

sfaDone:
	pop edi
	pop ecx
	pop ebp
	ret 8
RdosSetFileAttribute	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenDir
;
;		DESCRIPTION:	Open directory
;
;		PARAMETER:		Pathname
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenDir

RdosOpenDir	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	UserGate open_dir_nr
	jc odFail
;
    movzx eax,bx
    jmp odDone

odFail:
    xor eax,eax

odDone:
	pop edi
	pop ebx
	pop ebp
	ret 4
RdosOpenDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseDir
;
;		DESCRIPTION:	Close directory
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseDir

RdosCloseDir	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_dir_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseDir	ENDP

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

	public RdosReadDir

RdosReadDir	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov dx,[ebp+12]
	mov cx,[ebp+16]
	mov edi,[ebp+20]
	UserGate read_dir_nr
	jc rdiFail
;
    mov edi,[ebp+24]
    mov [edi],ecx
;
    mov edi,[ebp+28]
    movzx ebx,bx
    mov [edi],ebx
;
    mov edi,[ebp+32]
    mov [edi],edx
;
    mov edi,[ebp+36]
    mov [edi],eax
;
    mov eax,1
    jmp rdiDone

rdiFail:
    xor eax,eax
    
rdiDone:
    pop edi
    pop ecx
	pop ebx
	pop ebp
	ret 32
RdosReadDir	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFocus
;
;		DESCRIPTION:	Set focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFocus

RdosSetFocus	PROC
	push ebp
	mov ebp,esp
	mov eax,[ebp+8]
	UserGate set_focus_nr
	pop ebp
	ret 4
RdosSetFocus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFocus
;
;		DESCRIPTION:	Get focus
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFocus

RdosGetFocus	PROC
	UserGate get_focus_nr
	ret
RdosGetFocus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosClearKeyboard
;
;		DESCRIPTION:	Clear keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosClearKeyboard

RdosClearKeyboard	PROC
	UserGate flush_keyboard_nr
	ret
RdosClearKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPollKeyboard
;
;		DESCRIPTION:	Poll keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPollKeyboard

RdosPollKeyboard	PROC
	UserGate poll_keyboard_nr
	jc rpkEmpty
;
	mov eax,1
	ret

rpkEmpty:
	xor eax,eax
	ret
RdosPollKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadKeyboard
;
;		DESCRIPTION:	Read keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadKeyboard

RdosReadKeyboard	PROC
	UserGate read_keyboard_nr
	movzx eax,ax
	ret
RdosReadKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetKeyboardState
;
;		DESCRIPTION:	Get keyboard state
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetKeyboardState

RdosGetKeyboardState	PROC
	UserGate get_keyboard_state_nr
	movzx eax,ax
	ret
RdosGetKeyboardState	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPutKeyboard
;
;		DESCRIPTION:	Put code in keyboard buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPutKeyboard

RdosPutKeyboard	PROC
    push ebp
    mov ebp,esp
    push edx
;
    mov ax,[ebp+8]
    mov dl,[ebp+12]
    mov dh,[ebp+16]        
	UserGate put_keyboard_code_nr
;
    pop edx
    pop ebp
    ret 12	
RdosPutKeyboard	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPeekKeyEvent
;
;		DESCRIPTION:	Peek keyboard event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPeekKeyEvent

RdosPeekKeyEvent	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
	push edi
;
	UserGate peek_key_event_nr
	jc rpeFail
;
	mov edi,[ebp+8]
	movzx eax,ax
	mov [edi],eax
;
	mov edi,[ebp+12]
	movzx eax,cx
	mov [edi],eax
;
	mov edi,[ebp+16]
	movzx eax,dl
	mov [edi],eax
;
	mov edi,[ebp+20]
	movzx eax,dh
	mov [edi],eax
;
	mov eax,1
	jmp rpeDone

rpeFail:
	xor eax,eax

rpeDone:
	pop edi
	pop edx
	pop ecx
	pop ebp
	ret 16
RdosPeekKeyEvent	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadKeyEvent
;
;		DESCRIPTION:	Read keyboard event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadKeyEvent

RdosReadKeyEvent	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
	push edi
;
	UserGate read_key_event_nr
	jc rkeFail
;
	mov edi,[ebp+8]
	movzx eax,ax
	mov [edi],eax
;
	mov edi,[ebp+12]
	movzx eax,cx
	mov [edi],eax
;
	mov edi,[ebp+16]
	movzx eax,dl
	mov [edi],eax
;
	mov edi,[ebp+20]
	movzx eax,dh
	mov [edi],eax
;
	mov eax,1
	jmp rkeDone

rkeFail:
	xor eax,eax

rkeDone:
	pop edi
	pop edx
	pop ecx
	pop ebp
	ret 16
RdosReadKeyEvent	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosHideMouse
;
;		DESCRIPTION:	Hide mouse
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosHideMouse

RdosHideMouse	PROC
	UserGate hide_mouse_nr
	ret
RdosHideMouse	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosShowMouse
;
;		DESCRIPTION:	Show mouse
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosShowMouse

RdosShowMouse	PROC
	UserGate show_mouse_nr
	ret
RdosShowMouse	ENDP

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

	public RdosGetMousePosition

RdosGetMousePosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_mouse_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetMousePosition	ENDP

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

	public RdosSetMousePosition

RdosSetMousePosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	mov cx,[ebp+8]
	mov dx,[ebp+12]
	UserGate set_mouse_position_nr
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosSetMousePosition	ENDP

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

	public RdosSetMouseWindow

RdosSetMouseWindow	PROC
	push ebp
	mov ebp,esp
	push eax
	push ebx
	push ecx
	push edx
;
	mov ax,[ebp+8]
	mov bx,[ebp+12]
	mov cx,[ebp+16]
	mov dx,[ebp+20]
	UserGate set_mouse_window_nr
;
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop ebp
	ret 16
RdosSetMouseWindow	ENDP

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

	public RdosSetMouseMickey

RdosSetMouseMickey	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	mov cx,[ebp+8]
	mov dx,[ebp+12]
	UserGate set_mouse_mickey_nr
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosSetMouseMickey	ENDP

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

	public RdosGetCursorPosition

RdosGetCursorPosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_cursor_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],edx
	mov eax,[ebp+12]
	mov [eax],ecx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetCursorPosition	ENDP

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

	public RdosSetCursorPosition

RdosSetCursorPosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	mov dx,[ebp+8]
	mov cx,[ebp+12]
	UserGate set_cursor_position_nr
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosSetCursorPosition	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLeftButton
;
;		DESCRIPTION:	Check if left button is pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetLeftButton

RdosGetLeftButton	PROC
	UserGate get_left_button_nr
	jc get_left_rel
;
	mov eax,1
	ret

get_left_rel:
	xor eax,eax
	ret
RdosGetLeftButton	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRightButton
;
;		DESCRIPTION:	Check if right button is pressed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetRightButton

RdosGetRightButton	PROC
	UserGate get_right_button_nr
	jc get_right_rel
;
	mov eax,1
	ret

get_right_rel:
	xor eax,eax
	ret
RdosGetRightButton	ENDP

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

	public RdosGetLeftButtonPressPosition

RdosGetLeftButtonPressPosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_left_button_press_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetLeftButtonPressPosition	ENDP

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

	public RdosGetRightButtonPressPosition

RdosGetRightButtonPressPosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_right_button_press_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetRightButtonPressPosition	ENDP

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

	public RdosGetLeftButtonReleasePosition

RdosGetLeftButtonReleasePosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_left_button_release_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetLeftButtonReleasePosition	ENDP

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

	public RdosGetRightButtonReleasePosition

RdosGetRightButtonReleasePosition	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
;
	UserGate get_right_button_release_position_nr
	movzx ecx,cx
	movzx edx,dx
	mov eax,[ebp+8]
	mov [eax],ecx
	mov eax,[ebp+12]
	mov [eax],edx
;
	pop edx
	pop ecx
	pop ebp
	ret 8
RdosGetRightButtonReleasePosition	ENDP

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

	public RdosReadLine

RdosReadLine	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edi
;
	mov edi,[ebp+8]
	mov ecx,[ebp+12]
	UserGate read_con_nr
;
	pop edi
	pop ecx
	pop ebp
	ret 8
RdosReadLine	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteChar
;
;		DESCRIPTION:	Write a single character to screen
;
;		PARAMETER:		Char
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteChar

RdosWriteChar	PROC
	push ebp
	mov ebp,esp
;
	mov al,[ebp+8]
	UserGate write_char_nr
;
	pop ebp
	ret 4
RdosWriteChar	ENDP

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

	public RdosWriteSizeString

RdosWriteSizeString	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edi
;
	mov edi,[ebp+8]
	mov ecx,[ebp+12]
	UserGate write_size_string_nr
;
	pop edi
	pop ecx
	pop ebp
	ret 8
RdosWriteSizeString	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteString
;
;		DESCRIPTION:	Write a string to screen
;
;		PARAMETER:		String
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteString

RdosWriteString	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate write_asciiz_nr
;
	pop edi
	pop ebp
	ret 4
RdosWriteString	ENDP

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

	public RdosNameToIp

RdosNameToIp	PROC
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate name_to_ip_nr
	jc rntiFail
;
	mov eax,edx
	jmp rntiDone

rntiFail:
	xor eax,eax

rntiDone:
	pop edi
	pop ebp
	ret 4
RdosNameToIp	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetIp
;
;		DESCRIPTION:	Get my IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetIp

RdosGetIp	PROC
	UserGate get_ip_address_nr
	mov eax,edx
	ret
RdosGetIp	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetGateway
;
;		DESCRIPTION:	Get gateway IP address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetGateway

RdosGetGateway	PROC
	UserGate get_gateway_nr
	mov eax,edx
	ret
RdosGetGateway	ENDP

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

	public RdosIpToName

RdosIpToName	PROC
	push ebp
	mov ebp,esp
	push ecx
	push edx
	push edi
;
	mov edx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate ip_to_name_nr
	jnc ritnDone

ritnFail:
	xor eax,eax

ritnDone:
	pop edi
	pop edx
	pop ecx
	pop ebp
	ret 12
RdosIpToName	ENDP

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

	public RdosPing

RdosPing	PROC
	push ebp
	mov ebp,esp
	push edx
;
	mov edx,[ebp+8]
	mov eax,[ebp+12]
	UserGate ping_nr
	jc ping_failed
;
	mov eax,1
	jmp ping_done

ping_failed:
	xor eax,eax

ping_done:
	pop edx
	pop ebp
	ret 8
RdosPing	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenConnection
;
;		DESCRIPTION:	Open an active connection over TCP
;
;		PARAMETER:		RemoteIp
;						LocalPort
;						RemotePort
;						Timeout in ms
;						BufferSize
;
;		RETURNS:		Connection handle						
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenTcpConnection

RdosOpenTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov edx,[ebp+8]
	mov si,[ebp+12]
	mov di,[ebp+16]
	mov eax,[ebp+20]
	mov ecx,[ebp+24]
	UserGate open_tcp_connection_nr
	mov eax,0
	jc rotcDone
	mov eax,ebx
rotcDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 20
RdosOpenTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateTcpListen
;
;		DESCRIPTION:	Create listen handle
;
;		PARAMETER:		Port
;                       Max connections
;						BufferSize
;
;       RETURNS:        Listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateTcpListen

RdosCreateTcpListen	Proc
	push ebp
	mov ebp,esp
	push ebx
	push esi
;	
	mov si,[ebp+8]
	mov ax,[ebp+12]
	mov ecx,[ebp+16]
	UserGate create_tcp_listen_nr
	movzx eax,bx
	jnc ctlDone
;
    xor eax,eax

ctlDone:
	pop esi
	pop ebx
	pop ebp
	ret 12
RdosCreateTcpListen	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetTcpListen
;
;		DESCRIPTION:	Get connection from listen
;
;		PARAMETER:		Listen handle
;
;       RETURNS:        Connection handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetTcpListen

RdosGetTcpListen	Proc
	push ebp
	mov ebp,esp
	push ebx
;	
    mov bx,[ebp+8]
	UserGate get_tcp_listen_nr
	movzx eax,ax
	jnc gtlDone
;
    xor eax,eax

gtlDone:
    pop ebx
	pop ebp
	ret 4
RdosGetTcpListen	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseTcpListen
;
;		DESCRIPTION:	Close listen handle
;
;		PARAMETER:		Listen handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseTcpListen

RdosCloseTcpListen	Proc
	push ebp
	mov ebp,esp
	push ebx
;	
    mov bx,[ebp+8]
	UserGate close_tcp_listen_nr
;	
    pop ebx
	pop ebp
	ret 4
RdosCloseTcpListen	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosAddWaitForTcpListen
;
;		DESCRIPTION:	Add wait object to tcp listen
;
;		PARAMETER:		WaitHandle
;                       ConHandle
;						ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddWaitForTcpListen

RdosAddWaitForTcpListen	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	mov ecx,[ebp+16]
	UserGate add_wait_for_tcp_listen_nr
	mov eax,1
	jnc awftlDone
;
	xor eax,eax

awftlDone:
	pop ebx
	pop ebp
	ret 12
RdosAddWaitForTcpListen	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWaitForTcpConnection
;
;		DESCRIPTION:	Wait for a passive connection to establish
;
;		PARAMETER:		Handle
;						Timeout
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWaitForTcpConnection

RdosWaitForTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate wait_for_tcp_connection_nr
	mov eax,1
	jnc wftcDone
	xor eax,eax
wftcDone:
	pop ebx
	pop ebp
	ret 8
RdosWaitForTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosAddWaitForTcpConnection
;
;		DESCRIPTION:	Add wait object to tcp connection
;
;		PARAMETER:		WaitHandle
;                       ConHandle
;						ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddWaitForTcpConnection

RdosAddWaitForTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	mov ecx,[ebp+16]
	UserGate add_wait_for_tcp_connection_nr
	mov eax,1
	jnc awftcDone
	xor eax,eax
awftcDone:
	pop ebx
	pop ebp
	ret 12
RdosAddWaitForTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseTcpConnection
;
;		DESCRIPTION:	Close connection
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseTcpConnection

RdosCloseTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosDeleteTcpConnection
;
;		DESCRIPTION:	Delete connection handle
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosDeleteTcpConnection

RdosDeleteTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate delete_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosDeleteTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosAbortTcpConnection
;
;		DESCRIPTION:	Abort connection
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAbortTcpConnection

RdosAbortTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate abort_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosAbortTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPushTcpConnection
;
;		DESCRIPTION:	Push connection
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPushTcpConnection

RdosPushTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate push_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosPushTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPollTcpConnection
;
;		DESCRIPTION:	Poll connection
;
;		PARAMETER:		Handle
;
;       RETURNS:        Available bytes in receive buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPollTcpConnection

RdosPollTcpConnection	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate poll_tcp_connection_nr
;
	pop ebx
	pop ebp
	ret 4
RdosPollTcpConnection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosIsTcpConnectionClosed
;
;		DESCRIPTION:	Check if other side closed the connection
;
;		PARAMETER:		Handle
;
;		RETURNS:		FALSE		Connection still alive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosIsTcpConnectionClosed

RdosIsTcpConnectionClosed	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate is_tcp_connection_closed_nr
	jc rptcClosed
;
	xor eax,eax
	jmp rptcDone

rptcClosed:
	mov eax,1
	
rptcDone:
	pop ebx
	pop ebp
	ret 4
RdosIsTcpConnectionClosed	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosIsTcpConnectionIdle
;
;		DESCRIPTION:	Check if connection is idle (all data sent / no receive data)
;
;		PARAMETER:		Handle
;
;		RETURNS:		TRUE		Connection still idle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosIsTcpConnectionIdle

RdosIsTcpConnectionIdle	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate is_tcp_connection_idle_nr
	jnc rptiIdle
;
	xor eax,eax
	jmp rptiDone

rptiIdle:
	mov eax,1
	
rptiDone:
	pop ebx
	pop ebp
	ret 4
RdosIsTcpConnectionIdle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRemoteTcpConnectionIP
;
;		DESCRIPTION:	Get remote IP of connection
;
;		PARAMETER:		Handle
;
;		RETURNS:		IP
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetRemoteTcpConnectionIP

RdosGetRemoteTcpConnectionIP	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_remote_tcp_connection_ip_nr
	jnc grtciDone
;
	mov eax,-1
	
grtciDone:
	pop ebx
	pop ebp
	ret 4
RdosGetRemoteTcpConnectionIP	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetRemoteTcpConnectionPort
;
;		DESCRIPTION:	Get remote port of connection
;
;		PARAMETER:		Handle
;
;		RETURNS:		port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetRemoteTcpConnectionPort

RdosGetRemoteTcpConnectionPort	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_remote_tcp_connection_port_nr
	jnc grtcpDone
;
	mov eax,0
	
grtcpDone:
    movzx eax,ax
	pop ebx
	pop ebp
	ret 4
RdosGetRemoteTcpConnectionPort	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLocalTcpConnectionPort
;
;		DESCRIPTION:	Get local port of connection
;
;		PARAMETER:		Handle
;
;		RETURNS:		port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetLocalTcpConnectionPort

RdosGetLocalTcpConnectionPort	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_local_tcp_connection_port_nr
	jnc gltcpDone
;
	mov eax,0
	
gltcpDone:
    movzx eax,ax
	pop ebx
	pop ebp
	ret 4
RdosGetLocalTcpConnectionPort	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadTcpConnection
;
;		DESCRIPTION:	Read data from connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadTcpConnection

RdosReadTcpConnection	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate read_tcp_connection_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosReadTcpConnection	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteTcpConnection
;
;		DESCRIPTION:	Write data to connection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteTcpConnection

RdosWriteTcpConnection	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate write_tcp_connection_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 12
RdosWriteTcpConnection	ENDP

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

	public RdosGetLocalMailslot

RdosGetLocalMailslot	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	UserGate get_local_mailslot_nr
	jc rglmFail
;
	movzx eax,bx
	jmp rglmDone

rglmFail:
	xor eax,eax

rglmDone:
	pop edi
	pop ebx
	pop ebp
	ret 4
RdosGetLocalMailslot	Endp

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

	public RdosGetRemoteMailslot

RdosGetRemoteMailslot	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edx
	push edi
;
	mov edx,[ebp+8]
	mov edi,[ebp+12]
	UserGate get_remote_mailslot_nr
	jc rgrmFail
;
	movzx eax,bx
	jmp rgrmDone

rgrmFail:
	xor eax,eax

rgrmDone:
	pop edi
	pop edx
	pop ebx
	pop ebp
	ret 8
RdosGetRemoteMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosFreeMailslot
;
;		DESCRIPTION:	Free mailslot handle
;
;		PARAMETER:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosFreeMailslot

RdosFreeMailslot	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	UserGate free_mailslot_nr
;
	pop ebx
	pop ebp
	ret 4
RdosFreeMailslot	Endp

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

	public RdosSendMailslot

RdosSendMailslot	Proc
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov bx,[ebp+8]
	mov esi,[ebp+12]
	mov ecx,[ebp+16]
	mov edi,[ebp+20]
	mov eax,[ebp+24]
	UserGate send_mailslot_nr
	jc smFail
;
	mov eax,ecx
	jmp smDone

smFail:
	mov eax,-1

smDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 20
RdosSendMailslot	Endp

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

	public RdosDefineMailslot

RdosDefineMailslot	Proc
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	mov ecx,[ebp+12]
	UserGate define_mailslot_nr
;
	pop edi
	pop ebp
	ret 8
RdosDefineMailslot	Endp

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

	public RdosReceiveMailslot

RdosReceiveMailslot	Proc
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	UserGate receive_mailslot_nr
	mov eax,ecx
;
	pop edi
	pop ebp
	ret 4
RdosReceiveMailslot	Endp

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

	public RdosReplyMailslot

RdosReplyMailslot	Proc
	push ebp
	mov ebp,esp
	push edi
;
	mov edi,[ebp+8]
	mov ecx,[ebp+12]
	UserGate reply_mailslot_nr
;
	pop edi
	pop ebp
	ret 8
RdosReplyMailslot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetIdeDisc
;
;		DESCRIPTION:	Get IDE disc
;
;		PARAMETER:		Unit #
;
;		RETURNS:		Disc # or -1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetIdeDisc

RdosGetIdeDisc	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bl,[ebp+8]
	UserGate get_ide_disc_nr
	jc get_ide_disc_fail
;
    movzx eax,al
	jmp get_ide_disc_done

get_ide_disc_fail:
	mov eax,-1

get_ide_disc_done:
	pop ebx
	pop ebp
	ret 4
RdosGetIdeDisc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetFloppyDisc
;
;		DESCRIPTION:	Get floppy disc
;
;		PARAMETER:		Unit #
;
;		RETURNS:		Disc # or -1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetFloppyDisc

RdosGetFloppyDisc	Proc
	push ebp
	mov ebp,esp
	push ebx
;
	mov bl,[ebp+8]
	UserGate get_floppy_disc_nr
	jc get_floppy_disc_fail
;
    movzx eax,al
	jmp get_floppy_disc_done

get_floppy_disc_fail:
	mov eax,-1

get_floppy_disc_done:
	pop ebx
	pop ebp
	ret 4
RdosGetFloppyDisc	Endp

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

	public RdosGetDiscInfo

RdosGetDiscInfo	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edx
	push esi
	push edi
;
	mov al,[ebp+8]
	UserGate get_disc_info_nr
	jc get_disc_info_fail
;
	mov ebx,[ebp+12]
	movzx ecx,cx
	mov [ebx],ecx
;
	mov ebx,[ebp+16]
	mov [ebx],edx
;
	mov ebx,[ebp+20]
	movzx esi,si
	mov [ebx],esi
;
	mov ebx,[ebp+24]
	movzx edi,di
	mov [ebx],edi
;
	mov eax,1
	jmp get_disc_info_done

get_disc_info_fail:
	xor eax,eax

get_disc_info_done:
	pop edi
	pop esi
	pop edx
	pop ebx
	pop ebp
	ret 20
RdosGetDiscInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetDiscInfo
;
;		DESCRIPTION:	Set disc info
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

	public RdosSetDiscInfo

RdosSetDiscInfo	Proc
	push ebp
	mov ebp,esp
	push ebx
	push edx
	push esi
	push edi
;
	mov al,[ebp+8]
	mov ecx,[ebp+12]
	mov edx,[ebp+16]
	mov esi,[ebp+20]
	mov edi,[ebp+24]
	UserGate set_disc_info_nr
	jc set_disc_info_fail
;
	mov eax,1
	jmp set_disc_info_done

set_disc_info_fail:
	xor eax,eax

set_disc_info_done:
	pop edi
	pop esi
	pop edx
	pop ebx
	pop ebp
	ret 20
RdosSetDiscInfo	Endp

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

	public RdosReadDisc

RdosReadDisc	Proc
	push ebp
	mov ebp,esp
	push edx
	push edi
;
	mov al,[ebp+8]
	mov edx,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate read_disc_nr
	jc read_disc_fail
;
	mov eax,1
	jmp read_disc_done

read_disc_fail:
	xor eax,eax

read_disc_done:
	pop edi
	pop edx
	pop ebp
	ret 16
RdosReadDisc	Endp

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

	public RdosWriteDisc

RdosWriteDisc	Proc
	push ebp
	mov ebp,esp
	push edx
	push edi
;
	mov al,[ebp+8]
	mov edx,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate write_disc_nr
	jc write_disc_fail
;
	mov eax,1
	jmp write_disc_done

write_disc_fail:
	xor eax,eax

write_disc_done:
	pop edi
	pop edx
	pop ebp
	ret 16
RdosWriteDisc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosAllocateFixedDrive
;
;		DESCRIPTION:	Allocate fixed drive
;
;		PARAMETER:		Drive #
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAllocateFixedDrive

RdosAllocateFixedDrive	Proc
	push ebp
	mov ebp,esp
;
	mov al,[ebp+8]
	UserGate allocate_fixed_drive_nr
	jc allocate_fixed_drive_fail
;
	mov eax,1
	jmp allocate_fixed_drive_done

allocate_fixed_drive_fail:
	xor eax,eax

allocate_fixed_drive_done:
	pop ebp
	ret 4
RdosAllocateFixedDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosAllocateStaticDrive
;
;		DESCRIPTION:	Allocate static drive
;
;		RETURNS:		Drive # or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAllocateStaticDrive

RdosAllocateStaticDrive	Proc
	UserGate allocate_static_drive_nr
	jc allocate_static_drive_fail
;
    movzx eax,al
	jmp allocate_static_drive_done

allocate_static_drive_fail:
	xor eax,eax

allocate_static_drive_done:
	ret
RdosAllocateStaticDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosAllocateDynamicDrive
;
;		DESCRIPTION:	Allocate dynamic drive
;
;		RETURNS:		Drive # or 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAllocateDynamicDrive

RdosAllocateDynamicDrive	Proc
	UserGate allocate_dynamic_drive_nr
	jc allocate_dynamic_drive_fail
;
    movzx eax,al
	jmp allocate_dynamic_drive_done

allocate_dynamic_drive_fail:
	xor eax,eax

allocate_dynamic_drive_done:
	ret
RdosAllocateDynamicDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetRdfsInfo
;
;       DESCRIPTION:    Get basic RDFS info
;
;		PARAMETERS:		Crypt tab
;						Key tab
;						Extent size tab
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetRdfsInfo

RdosGetRdfsInfo	Proc near
	push ebp
	mov ebp,esp
	push gs
	push ebx
	push esi
	push edi
;
	mov esi,[ebp+8]
	mov edi,[ebp+12]
	mov ebx,[ebp+16]
	mov ax,ds
	mov gs,ax
	UserGate get_rdfs_info_nr
;
	pop edi
	pop esi
	pop ebx
	pop gs
	pop ebp
	ret 12
RdosGetRdfsInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetDriveInfo
;
;		DESCRIPTION:	Get drive info
;
;		PARAMETER:		Drive #
;						Free units
;						Bytes per unit
;						Total units
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetDriveInfo

RdosGetDriveInfo	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov al,[ebp+8]
	UserGate get_drive_info_nr
	jc get_drive_info_fail
;
	mov ebx,[ebp+12]
	mov [ebx],eax
;
	mov ebx,[ebp+16]
	movzx ecx,cx
	mov [ebx],ecx
;
	mov ebx,[ebp+20]
	mov [ebx],edx
;
	mov eax,1
	jmp get_drive_info_done

get_drive_info_fail:
	xor eax,eax

get_drive_info_done:
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosGetDriveInfo	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosDemandLoadDrive
;
;       DESCRIPTION:    Demand-load drive (removable media)
;
;		PARAMETERS:		Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosDemandLoadDrive

RdosDemandLoadDrive	Proc near
	push ebp
	mov ebp,esp
;
	mov al,[ebp+8]
	UserGate demand_load_drive_nr
;
	pop ebp
	ret 4
RdosDemandLoadDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetDriveDiscParam
;
;		DESCRIPTION:	Get drive disc param
;
;		PARAMETER:		Drive #
;                       Disc #
;						Start sector
;						Total sectors
;
;		RETURNS:		OK
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetDriveDiscParam

RdosGetDriveDiscParam	Proc
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edx
;
	mov al,[ebp+8]
	UserGate get_drive_disc_param_nr
	jc get_drive_disc_param_fail
;
	mov ebx,[ebp+12]
	movzx eax,al
	mov [ebx],eax
;
	mov ebx,[ebp+16]
	mov [ebx],edx
;
	mov ebx,[ebp+20]
	mov [ebx],ecx
;
	mov eax,1
	jmp get_drive_disc_param_done

get_drive_disc_param_fail:
	xor eax,eax

get_drive_disc_param_done:
	pop edx
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosGetDriveDiscParam	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosFormatDrive
;
;       DESCRIPTION:    Format drive
;
;		PARAMETERS:		Disc #
;						Start sector
;						Size
;						FS name
;
;       RETURNS:        Drive #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosFormatDrive

RdosFormatDrive	Proc near
	push ebp
	mov ebp,esp
	push edi
;
	mov al,[ebp+8]
	mov edx,[ebp+12]
	mov ecx,[ebp+16]
	mov edi,[ebp+20]
	UserGate format_drive_nr
	jc rfdFail
;
    movzx eax,al
    jmp rfdDone

rfdFail:
    xor eax,eax

rfdDone:
	pop edi
	pop ebp
	ret 16
RdosFormatDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetExeName
;
;       DESCRIPTION:    Get full path of executable
;
;		RETURNS:		Exe name buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetExeName

RdosGetExeName	Proc near
	push edi
;
	UserGate get_exe_name_nr
	jc rgenFail
;
    mov eax,edi
    jmp rgenDone

rgenFail:
    xor eax,eax

rgenDone:
	pop edi
	ret
RdosGetExeName	Endp

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

		public RdosLoadDll

RdosLoadDll	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	UserGate load_dll_nr
	jc rldllFail
;
    mov eax,ebx
    jmp rldllDone

rldllFail:
    xor eax,eax

rldllDone:
	pop edi
	pop ebx
	pop ebp
	ret 4
RdosLoadDll	Endp

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

		public RdosFreeDll

RdosFreeDll	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	UserGate free_dll_nr
;
	pop ebx
	pop ebp
	ret 4
RdosFreeDll	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetModuleHandle
;
;       DESCRIPTION:    Get handle of executable
;
;		PARAMETERS:		
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetModuleHandle

RdosGetModuleHandle	Proc near
	mov eax,fs:pvModuleHandle
	ret
RdosGetModuleHandle	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetModuleName
;
;       DESCRIPTION:    Get name of module or DLL
;
;		PARAMETERS:		Handle, Buf, Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetModuleName

RdosGetModuleName	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov ebx,[ebp+8]
	mov edi,[ebp+12]
	mov ecx,[ebp+16]
	UserGate get_module_name_nr
	jnc dmnDone
;
    xor eax,eax	

dmnDone:
    pop edi
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosGetModuleName	Endp

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

		public RdosReadResource

RdosReadResource	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push esi
	push edi
;
	mov ebx,[ebp+8]
	or ebx,ebx
	jnz read_resource_handle_ok
;
	mov ebx,fs:pvModuleHandle

read_resource_handle_ok:
	mov eax,[ebp+12]
	mov edx,6
	UserGate get_module_resource_nr
	jc read_resource_fail
;
	cmp ecx,[ebp+20]
	jbe read_resource_copy
;
	mov ecx,[ebp+20]

read_resource_copy:
	mov edi,[ebp+16]
	mov eax,ecx

read_resource_copy_loop:
    movs byte ptr es:[edi],[esi]
    inc esi
    loop read_resource_copy_loop
;    
	jmp read_resource_done
	
read_resource_fail:
	xor eax,eax

read_resource_done:
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosReadResource	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadBinaryResource
;
;       DESCRIPTION:    Read binary resource (type 10)
;
;		PARAMETERS:		Handle
;						ID
;						Buf
;						Size
;
;		RETURNS:		Size read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosReadBinaryResource

RdosReadBinaryResource	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push esi
	push edi
;
	mov ebx,[ebp+8]
	or ebx,ebx
	jnz read_bin_resource_handle_ok
;
	mov ebx,fs:pvModuleHandle

read_bin_resource_handle_ok:
	mov eax,[ebp+12]
	mov edx,10
	UserGate get_module_resource_nr
	jc read_bin_resource_fail
;
	cmp ecx,[ebp+20]
	jbe read_bin_resource_copy
;
	mov ecx,[ebp+20]

read_bin_resource_copy:
	mov edi,[ebp+16]
	mov eax,ecx
    rep movs byte ptr es:[edi],[esi]    
	jmp read_bin_resource_done
	
read_bin_resource_fail:
	xor eax,eax

read_bin_resource_done:
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosReadBinaryResource	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetModuleProc
;
;       DESCRIPTION:    Get module process address
;
;		PARAMETERS:		Handle
;						Name
;
;		RETURNS:		Procedure address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetModuleProc

RdosGetModuleProc	Proc near
	push ebp
	mov ebp,esp
	push ds
	push ebx
	push esi
	push edi
;
    mov ebx,[ebp+8]
    mov edi,[ebp+12]
	UserGate get_module_proc_nr
	jc rgmpFail
;
    mov eax,esi
    jmp rgmpDone

rgmpFail:
    xor eax,eax

rgmpDone:
    pop edi
    pop esi
    pop ebx
    pop ds
    pop ebp
    ret 8
RdosGetModuleProc   Endp    
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetModuleFocusKey
;
;       DESCRIPTION:    Get module focus key
;
;		PARAMETERS:		Handle
;
;		RETURNS:		Key
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetModuleFocusKey

RdosGetModuleFocusKey	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
    mov ebx,[ebp+8]
	UserGate get_module_focus_key_nr
	jnc rgmfkDone
;
    xor al,al

rgmfkDone:
    pop ebx
    pop ebp
    ret 4
RdosGetModuleFocusKey   Endp        
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosAddWaitForDebugEvent
;
;       DESCRIPTION:    add wait for debug event
;
;		PARAMETERS:		Handle
;                       Module handle
;                       ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosAddWaitForDebugEvent

RdosAddWaitForDebugEvent	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
    mov ebx,[ebp+8]
    mov eax,[ebp+12]
    mov ecx,[ebp+16]
	UserGate add_wait_for_debug_event_nr
;    
    pop ecx
    pop ebx
    pop ebp
    ret 12
RdosAddWaitForDebugEvent   Endp    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetDebugEvent
;
;       DESCRIPTION:    Get debug event
;
;		PARAMETERS:		Handle
;                       Thread
;
;		RETURNS:		Event type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetDebugEvent

RdosGetDebugEvent	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
    mov ebx,[ebp+8]
	UserGate get_debug_event_nr
	jc gdeFail
;
    mov edx,[ebp+12]
    movzx eax,ax
    mov [edx],eax
    mov al,bl
    jmp gdeDone

gdeFail:
    xor al,al
    
gdeDone:
    pop ebx
    pop ebp
    ret 8
RdosGetDebugEvent   Endp    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGetDebugEventData
;
;       DESCRIPTION:    Get debug event data
;
;		PARAMETERS:		Handle
;                       Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGetDebugEventData

RdosGetDebugEventData	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
    mov ebx,[ebp+8]
    mov edi,[ebp+12]
	UserGate get_debug_event_data_nr
;	
    pop edi
    pop ebx
    pop ebp
    ret 8
RdosGetDebugEventData   Endp    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosClearDebugEvent
;
;       DESCRIPTION:    Clear debug event
;
;		PARAMETERS:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosClearDebugEvent

RdosClearDebugEvent	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
    mov ebx,[ebp+8]
	UserGate clear_debug_event_nr
;	
    pop ebx
    pop ebp
    ret 4
RdosClearDebugEvent   Endp    
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosContinueDebugEvent
;
;       DESCRIPTION:    Continue debug event
;
;		PARAMETERS:		Handle
;                       Thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosContinueDebugEvent

RdosContinueDebugEvent	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
    mov ebx,[ebp+8]
    mov eax,[ebp+12]
	UserGate continue_debug_event_nr
;	
    pop ebx
    pop ebp
    ret 8
RdosContinueDebugEvent   Endp    
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenAdc
;
;       DESCRIPTION:    Open handle to ADC channel
;
;		PARAMETERS:		Channel
;
;		RETURNS:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosOpenAdc

RdosOpenAdc	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+8]
	UserGate open_adc_nr
	mov ax,bx
;
	pop ebx
	pop ebp
	ret 4
RdosOpenAdc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosCloseAdc
;
;       DESCRIPTION:    Close ADC handle
;
;		PARAMETERS:		Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosCloseAdc

RdosCloseAdc	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	UserGate close_adc_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseAdc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosDefineAdcTime
;
;       DESCRIPTION:    Define ADC conversion time
;
;		PARAMETERS:		Handle
;						Msb
;						Lsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosDefineAdcTime

RdosDefineAdcTime	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	mov edx,[ebp+12]
	mov eax,[ebp+16]
	UserGate define_adc_time_nr
;
	pop ebx
	pop ebp
	ret 12
RdosDefineAdcTime	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosReadAdc
;
;       DESCRIPTION:    Read ADC
;
;		PARAMETERS:		Handle
;
;		RETURNS:		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosReadAdc

RdosReadAdc	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	UserGate read_adc_nr
;
	pop ebx
	pop ebp
	ret 4
RdosReadAdc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosReadSerialLines
;
;       DESCRIPTION:    Read serial lines
;
;		PARAMETERS:		Device
;						Value ptr
;
;		RETURNS:		TRUE if successful
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosReadSerialLines

RdosReadSerialLines	Proc near
	push ebp
	mov ebp,esp
	push edx
	push esi
;
	mov dh,[ebp+8]
	UserGate read_serial_lines_nr
	jc rdsFail
;
	movzx eax,al
	mov esi,[ebp+12]
	mov [esi],eax
	mov eax,1
	jmp rdsDone

rdsFail:
	xor eax,eax

rdsDone:
	pop esi
	pop edx
	pop ebp
	ret 8
RdosReadSerialLines	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosToggleSerialLine
;
;       DESCRIPTION:    Toggle serial line
;
;		PARAMETERS:		Device
;						Line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosToggleSerialLine

RdosToggleSerialLine	Proc near
	push ebp
	mov ebp,esp
	push edx
;
	mov dh,[ebp+8]
	mov dl,[ebp+12]
	UserGate toggle_serial_line_nr
	jc rtsFail
;
	mov eax,1
	jmp rtsDone

rtsFail:
	xor eax,eax

rtsDone:
	pop edx
	pop ebp
	ret 8
RdosToggleSerialLine	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosReadSerialVal
;
;       DESCRIPTION:    Read serial value
;
;		PARAMETERS:		Device
;						Line
;						Value ptr
;
;		RETURNS:		TRUE if successful
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosReadSerialVal

RdosReadSerialVal	Proc near
	push ebp
	mov ebp,esp
	push edx
	push esi
;
	mov dh,[ebp+8]
	mov dl,[ebp+12]
	UserGate read_serial_val_nr
;
    pushf
	shl eax,8
	mov esi,[ebp+16]
	mov [esi],eax
    popf	
	jc rdvFail
;
	mov eax,1
	jmp rdvDone

rdvFail:
	xor eax,eax

rdvDone:
	pop esi
	pop edx
	pop ebp
	ret 12
RdosReadSerialVal	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosWriteSerialVal
;
;       DESCRIPTION:    Write serial value
;
;		PARAMETERS:		Device
;						Line
;						Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosWriteSerialVal

RdosWriteSerialVal	Proc near
	push ebp
	mov ebp,esp
	push edx
;
	mov dh,[ebp+8]
	mov dl,[ebp+12]
	mov eax,[ebp+16]
	sar eax,8
	UserGate write_serial_val_nr
	jc rwvFail
;
	mov eax,1
	jmp rwvDone

rwvFail:
	xor eax,eax

rwvDone:
	pop edx
	pop ebp
	ret 12
RdosWriteSerialVal	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosReadSerialRaw
;
;       DESCRIPTION:    Read serial raw
;
;		PARAMETERS:		Device
;						Line
;						Raw value ptr
;
;		RETURNS:		TRUE if successful
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosReadSerialRaw

RdosReadSerialRaw	Proc near
	push ebp
	mov ebp,esp
	push edx
	push esi
;
	mov dh,[ebp+8]
	mov dl,[ebp+12]
	UserGate read_serial_val_nr
;
    pushf
	mov esi,[ebp+16]
	mov [esi],eax
    popf	
	jc rdrFail
;
	mov eax,1
	jmp rdrDone

rdrFail:
	xor eax,eax

rdrDone:
	pop esi
	pop edx
	pop ebp
	ret 12
RdosReadSerialRaw	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosWriteSerialRaw
;
;       DESCRIPTION:    Write serial raw
;
;		PARAMETERS:		Device
;						Line
;						Raw value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosWriteSerialRaw

RdosWriteSerialRaw	Proc near
	push ebp
	mov ebp,esp
	push edx
;
	mov dh,[ebp+8]
	mov dl,[ebp+12]
	mov eax,[ebp+16]
	UserGate write_serial_val_nr
	jc rwrFail
;
	mov eax,1
	jmp rwrDone

rwrFail:
	xor eax,eax

rwrDone:
	pop edx
	pop ebp
	ret 12
RdosWriteSerialRaw	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenSysEnv
;
;       DESCRIPTION:    Open systen environment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosOpenSysEnv

RdosOpenSysEnv	Proc near
	push ebx
;
	UserGate open_sys_env_nr
	jc oseFail
;
	movzx eax,bx
	jmp oseDone

oseFail:
	xor eax,eax

oseDone:
	pop ebx
	ret
RdosOpenSysEnv	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenProcessEnv
;
;       DESCRIPTION:    Open process environment
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosOpenProcessEnv

RdosOpenProcessEnv	Proc near
	push ebx
;
	UserGate open_proc_env_nr
	jc opeFail
;
	movzx eax,bx
	jmp opeDone

opeFail:
	xor eax,eax

opeDone:
	pop ebx
	ret
RdosOpenProcessEnv	Endp

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

		public RdosCloseEnv

RdosCloseEnv	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	UserGate close_env_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseEnv	Endp

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

		public RdosAddEnvVar

RdosAddEnvVar	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov ebx,[ebp+8]
	mov esi,[ebp+12]
	mov edi,[ebp+16]
	UserGate add_env_var_nr
;
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 12
RdosAddEnvVar	Endp

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

		public RdosDeleteEnvVar

RdosDeleteEnvVar	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
;
	mov ebx,[ebp+8]
	mov esi,[ebp+12]
	UserGate delete_env_var_nr
;
	pop esi
	pop ebx
	pop ebp
	ret 8
RdosDeleteEnvVar	Endp

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

		public RdosFindEnvVar

RdosFindEnvVar	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov ebx,[ebp+8]
	mov esi,[ebp+12]
	mov edi,[ebp+16]
	UserGate find_env_var_nr
	jc fevFail
;
	mov eax,1
	jmp fevDone

fevFail:
	xor eax,eax

fevDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 12
RdosFindEnvVar	Endp

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

		public RdosGetEnvData

RdosGetEnvData	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov ebx,[ebp+8]
	mov edi,[ebp+12]
	UserGate get_env_data_nr
	jnc gedDone
;
	xor ax,ax
	stosw

gedDone:
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosGetEnvData	Endp

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

		public RdosSetEnvData

RdosSetEnvData	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov ebx,[ebp+8]
	mov edi,[ebp+12]
	UserGate set_env_data_nr
;
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosSetEnvData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenSysIni
;
;       DESCRIPTION:    Open system ini file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosOpenSysIni

RdosOpenSysIni	Proc near
	push ebx
;
	UserGate open_sys_ini_nr
	jc osiFail
;
	movzx eax,bx
	jmp osiDone

osiFail:
	xor eax,eax

osiDone:
	pop ebx
	ret
RdosOpenSysIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenIni
;
;       DESCRIPTION:    Open ini file
;
;       PARAMETERS:     Filename
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosOpenIni

RdosOpenIni	Proc near
    push ebp
    mov ebp,esp
	push ebx
	push edi
;
	mov edi,[ebp+8]
	UserGate open_ini_nr
	jc opiFail
;
	movzx eax,bx
	jmp opiDone

opiFail:
	xor eax,eax

opiDone:
    pop edi
	pop ebx
	pop ebp
	ret 4
RdosOpenIni	Endp

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

		public RdosCloseIni

RdosCloseIni	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	UserGate close_ini_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosGotoIniSection
;
;       DESCRIPTION:    Goto ini section
;
;		PARAMETERS:		handle
;					    SectionName
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosGotoIniSection

RdosGotoIniSection	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov ebx,[ebp+8]
	mov edi,[ebp+12]
	UserGate goto_ini_section_nr
	jc gisFail
;
	mov eax,1
	jmp gisDone

gisFail:
	xor eax,eax

gisDone:
	pop edi
	pop ebx
	pop ebp
	ret 8
RdosGotoIniSection	Endp

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

		public RdosRemoveIniSection

RdosRemoveIniSection	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ebx,[ebp+8]
	UserGate remove_ini_section_nr
	jc risFail
;
	mov eax,1
	jmp risDone

risFail:
	xor eax,eax

risDone:
	pop ebx
	pop ebp
	ret 4
RdosRemoveIniSection	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosReadIni
;
;       DESCRIPTION:    Read ini var
;
;		PARAMETERS:		handle
;					    VarName
;                       Str
;                       MaxSize
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosReadIni

RdosReadIni	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push esi
	push edi
;
	mov ebx,[ebp+8]
	mov esi,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate read_ini_nr
	jc riFail
;
	mov eax,1
	jmp riDone

riFail:
	xor eax,eax

riDone:
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosReadIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosWriteIni
;
;       DESCRIPTION:    Write ini var
;
;		PARAMETERS:		handle
;					    VarName
;                       Str
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosWriteIni

RdosWriteIni	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov ebx,[ebp+8]
	mov esi,[ebp+12]
	mov edi,[ebp+16]
	UserGate write_ini_nr
	jc wiFail
;
	mov eax,1
	jmp wiDone

wiFail:
	xor eax,eax

wiDone:
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 12
RdosWriteIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosDeleteIni
;
;       DESCRIPTION:    Delete ini var
;
;		PARAMETERS:		handle
;					    VarName
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosDeleteIni

RdosDeleteIni	Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
;
	mov ebx,[ebp+8]
	mov esi,[ebp+12]
	UserGate delete_ini_nr
	jc diFail
;
	mov eax,1
	jmp diDone

diFail:
	xor eax,eax

diDone:
	pop esi
	pop ebx
	pop ebp
	ret 8
RdosDeleteIni	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosCreateFileDrive
;
;       DESCRIPTION:    Create a new file drive
;
;		PARAMETERS:		Drive
;                       Size
;					    FsName
;						FileName
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosCreateFileDrive

RdosCreateFileDrive	Proc near
	push ebp
	mov ebp,esp
	push ecx
	push esi
	push edi
;
    mov al,[ebp+8]
	mov ecx,[ebp+12]
	mov esi,[ebp+16]
	mov edi,[ebp+20]
	UserGate create_file_drive_nr
	jnc cfdOk
;
    xor eax,eax
    jmp cfdDone

cfdOk:
	mov eax,1

cfdDone:
	pop edi
	pop esi
	pop ecx
	pop ebp
	ret 16
RdosCreateFileDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosOpenFileDrive
;
;       DESCRIPTION:    Open a new file drive
;
;		PARAMETERS:		Drive
;                       FsName
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosOpenFileDrive

RdosOpenFileDrive	Proc near
	push ebp
	mov ebp,esp
	push edi
;
    mov al,[ebp+8]
	mov edi,[ebp+12]
	UserGate open_file_drive_nr
	jnc ofdOk
;
	xor eax,eax
	jmp ofdDone

ofdOk:
	mov eax,1

ofdDone:
	pop edi
	pop ebp
	ret 8
RdosOpenFileDrive	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosEnableStatusLED
;
;       DESCRIPTION:    Enable status LED
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosEnableStatusLED

RdosEnableStatusLED	Proc near
	UserGate enable_status_led_nr
	ret
RdosEnableStatusLED	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosDisableStatusLED
;
;       DESCRIPTION:    Disable status LED
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosDisableStatusLED

RdosDisableStatusLED	Proc near
	UserGate disable_status_led_nr
	ret
RdosDisableStatusLED	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosStartWatchdog
;
;       DESCRIPTION:    Start watchdog
;
;		PARAMETERS:		Timeout in milliseconds
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosStartWatchdog

RdosStartWatchdog	Proc near
	push ebp
	mov ebp,esp
;
    mov ax,start_watchdog_nr
    UserGate is_valid_usergate_nr
    jc rswDone
;    
	mov eax,[ebp+8]
	UserGate start_watchdog_nr

rswDone:
	pop ebp
	ret 4
RdosStartWatchdog	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosKickWatchdog
;
;       DESCRIPTION:    Kick watchdog
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosKickWatchdog

RdosKickWatchdog	Proc near
    mov ax,kick_watchdog_nr
    UserGate is_valid_usergate_nr
    jc rkwDone
;    
	UserGate kick_watchdog_nr

rkwDone:
	ret
RdosKickWatchdog	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosStopWatchdog
;
;       DESCRIPTION:    Stop watchdog
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosStopWatchdog

RdosStopWatchdog	Proc near
    mov ax,stop_watchdog_nr
    UserGate is_valid_usergate_nr
    jc rstwDone
;    
	UserGate stop_watchdog_nr

rstwDone:	
	ret
RdosStopWatchdog	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosStartNetCapture
;
;       DESCRIPTION:    Start net-capture
;
;		PARAMETERS:		Filehandle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosStartNetCapture

RdosStartNetCapture	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate start_net_capture_nr
;
    pop ebx
	pop ebp
	ret 4
RdosStartNetCapture	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosStopNetCapture
;
;       DESCRIPTION:    Stop net-capture
;
;		PARAMETERS:		
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosStopNetCapture

RdosStopNetCapture	Proc near
	UserGate stop_net_capture_nr
	ret
RdosStopNetCapture	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosCreateCrc
;
;       DESCRIPTION:    Create CRC handle
;
;		PARAMETERS:		CrcPoly
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosCreateCrc

RdosCreateCrc	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov ax,[ebp+8]
	UserGate create_crc_nr
	movzx eax,bx
;
    pop ebx
	pop ebp
	ret 4
RdosCreateCrc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RdosCloseCrc
;
;       DESCRIPTION:    Close CRC handle
;
;		PARAMETERS:		Handle
;						
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		public RdosCloseCrc

RdosCloseCrc	Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_crc_nr
;
    pop ebx
	pop ebp
	ret 4
RdosCloseCrc	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCalcCrc
;
;		DESCRIPTION:	Calculate CRC
;
;       PARAMETERS:     Handle, Crc, Buf, Size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCalcCrc

RdosCalcCrc	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate calc_crc_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosCalcCrc	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetUsbDevice
;
;		DESCRIPTION:	Get device descriptor
;
;       PARAMETERS:     Controller, Device, Buffer, Maxsize
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetUsbDevice

RdosGetUsbDevice	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov al,[ebp+12]
	mov edi,[ebp+16]
	mov ecx,[ebp+20]
	UserGate get_usb_device_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 16
RdosGetUsbDevice	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetUsbConfig
;
;		DESCRIPTION:	Get config descriptor
;
;       PARAMETERS:     Controller, Device, Config, Buffer, Maxsize
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetUsbConfig

RdosGetUsbConfig	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov al,[ebp+12]
	mov dl,[ebp+16]
	mov edi,[ebp+20]
	mov ecx,[ebp+24]
	UserGate get_usb_config_nr
;
	pop edi
	pop ecx
	pop ebx
	pop ebp
	ret 20
RdosGetUsbConfig	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenUsbPipe
;
;		DESCRIPTION:	Open USB pipe
;
;       PARAMETERS:     Controller, Device, Pipe
;
;       RETURNS:        Pipe handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenUsbPipe

RdosOpenUsbPipe	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov al,[ebp+12]
	mov dl,[ebp+16]
	UserGate open_usb_pipe_nr
	movzx eax,bx
;
	pop ebx
	pop ebp
	ret 12
RdosOpenUsbPipe	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseUsbPipe
;
;		DESCRIPTION:	Close USB pipe
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseUsbPipe

RdosCloseUsbPipe	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_usb_pipe_nr
;
	pop ebx
	pop ebp
	ret 4
RdosCloseUsbPipe	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosLockUsbPipe
;
;		DESCRIPTION:	Lock USB pipe
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosLockUsbPipe

RdosLockUsbPipe	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate lock_usb_pipe_nr
;
	pop ebx
	pop ebp
	ret 4
RdosLockUsbPipe	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosUnlockUsbPipe
;
;		DESCRIPTION:	Unlock USB pipe
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosUnlockUsbPipe

RdosUnlockUsbPipe	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate unlock_usb_pipe_nr
;
	pop ebx
	pop ebp
	ret 4
RdosUnlockUsbPipe	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosAddWaitForUsbPipe
;
;		DESCRIPTION:	Add wait for USB pipe
;
;       PARAMETERS:     Handle, pipe handle, ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosAddWaitForUsbPipe

RdosAddWaitForUsbPipe	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	mov ax,[ebp+12]
	mov ecx,[ebp+16]
	UserGate add_wait_for_usb_pipe_nr
;
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosAddWaitForUsbPipe	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteUsbControl
;
;		DESCRIPTION:    Queue USB control data
;
;       PARAMETERS:     Handle, buffer, maxsize
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteUsbControl

RdosWriteUsbControl	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov cx,[ebp+16]
	UserGate write_usb_control_nr
;
    pop edi
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosWriteUsbControl	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReqUsbData
;
;		DESCRIPTION:	Queue request for USB-data input
;
;       PARAMETERS:     Handle, buffer, maxsize
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReqUsbData

RdosReqUsbData	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov cx,[ebp+16]
	UserGate req_usb_data_nr
;
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosReqUsbData	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetUsbDataSize
;
;		DESCRIPTION:	Get data size for previous USB input requests
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetUsbDataSize

RdosGetUsbDataSize	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate get_usb_data_size_nr
	movzx eax,ax
;
	pop ebx
	pop ebp
	ret 4
RdosGetUsbDataSize	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteUsbData
;
;		DESCRIPTION:    Queue USB output data
;
;       PARAMETERS:     Handle, buffer, maxsize
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteUsbData

RdosWriteUsbData	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+12]
	mov cx,[ebp+16]
	UserGate write_usb_data_nr
;
    pop edi
    pop ecx
	pop ebx
	pop ebp
	ret 12
RdosWriteUsbData	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReqUsbStatus
;
;		DESCRIPTION:    Queue USB status input req
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReqUsbStatus

RdosReqUsbStatus	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate req_usb_status_nr
;
	pop ebx
	pop ebp
	ret 4
RdosReqUsbStatus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteUsbStatus
;
;		DESCRIPTION:    Queue USB status output req
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteUsbStatus

RdosWriteUsbStatus	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate write_usb_status_nr
;
	pop ebx
	pop ebp
	ret 4
RdosWriteUsbStatus	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosIsUsbTransactionDone
;
;		DESCRIPTION:    Check if transaction is done
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosIsUsbTransactionDone

RdosIsUsbTransactionDone	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate is_usb_trans_done_nr
	jnc iutdOk
;
    xor eax,eax
    jmp iutdDone

iutdOk:
    mov eax,1

iutdDone:
	pop ebx
	pop ebp
	ret 4
RdosIsUsbTransactionDone	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWasUsbTransactionOk
;
;		DESCRIPTION:    Check if transaction was ok
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWasUsbTransactionOk

RdosWasUsbTransactionOk	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate was_usb_trans_ok_nr
	jnc wutoOk
;
    xor eax,eax
    jmp wutoDone

wutoOk:
    mov eax,1

wutoDone:
	pop ebx
	pop ebp
	ret 4
RdosWasUsbTransactionOk	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenICSP
;
;		DESCRIPTION:    Open ICSP device
;
;       PARAMETERS:     Device ID
;
;       RETURNS:        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenICSP

RdosOpenICSP	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp+8]
	UserGate open_icsp_nr
	jc oicspFail
;
    movzx eax,bx
    jmp oicspDone

oicspFail:
    xor eax,eax

oicspDone:
	pop ebx
	pop ebp
	ret 4
RdosOpenICSP	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseICSP
;
;		DESCRIPTION:    Close ICSP handle
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseICSP

RdosCloseICSP	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	UserGate close_icsp_nr
	mov eax,1
;	
	pop ebx
	pop ebp
	ret 4
RdosCloseICSP	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteICSPCommand
;
;		DESCRIPTION:    Write command to ICSP
;
;       PARAMETERS:     Handle
;                       Command
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteICSPCommand

RdosWriteICSPCommand	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate write_icsp_cmd_nr
	jc wicspcFail
;
    mov eax,1
    jmp wicspcDone

wicspcFail:
    xor eax,eax

wicspcDone:
	pop ebx
	pop ebp
	ret 8
RdosWriteICSPCommand	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteICSPData
;
;		DESCRIPTION:    Write data to ICSP
;
;       PARAMETERS:     Handle
;                       Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteICSPData

RdosWriteICSPData	PROC
	push ebp
	mov ebp,esp
	push ebx
;
	mov bx,[ebp+8]
	mov eax,[ebp+12]
	UserGate write_icsp_data_nr
	jc wicspdFail
;
    mov eax,1
    jmp wicspdDone

wicspdFail:
    xor eax,eax

wicspdDone:
	pop ebx
	pop ebp
	ret 8
RdosWriteICSPData	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosReadICSPData
;
;		DESCRIPTION:    Read data from ICSP
;
;       PARAMETERS:     Handle
;                       Data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosReadICSPData

RdosReadICSPData	PROC
	push ebp
	mov ebp,esp
	push ebx
	push edi
;
	mov bx,[ebp+8]
	mov edi,[ebp+16]
	UserGate read_icsp_data_nr
	jc ricspdFail
;
    mov [edi],eax
    mov eax,1
    jmp ricspdDone

ricspdFail:
    xor eax,eax

ricspdDone:
    pop edi
	pop ebx
	pop ebp
	ret 8
RdosReadICSPData	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetCodecGpio0
;
;		DESCRIPTION:    Set CODEC GPIO 0 PIN
;
;       PARAMETERS:     Value (0 or 1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetCodecGpio0

RdosSetCodecGpio0	PROC
	push ebp
	mov ebp,esp
;
    mov ax,set_codec_gpio0_nr
    UserGate is_valid_usergate_nr
    jc rscg0Done
;    
    mov al,[ebp+8]
    and al,1
    UserGate set_codec_gpio0_nr    

rscg0Done:
	pop ebp
	ret 4
RdosSetCodecGpio0	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetMasterVolume
;
;		DESCRIPTION:    Get master volume
;
;       PARAMETERS:     Left (0-100, negative = mute)
;                       Right (0-100, negative = mute)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetMasterVolume

RdosGetMasterVolume	PROC
	push ebp
	mov ebp,esp
	push edi
;
    mov edi,[ebp+8]
    mov dword ptr [edi],-1
;    
    mov edi,[ebp+12]
    mov dword ptr [edi],-1
;
    mov ax,get_master_volume_nr
    UserGate is_valid_usergate_nr
    jc rgmvDone
;    
    UserGate get_master_volume_nr
    jc rgmvDone
;    
    test al,80h
    jnz rgmvR
;    
    mov edi,[ebp+8]
    push ax
;    
    mov ah,7Fh
    sub ah,al
;    
    mov al,200
    mul ah
    movzx eax,ah    
    mov [edi],eax
    pop ax

rgmvR:
    test ah,80h
    jnz rgmvDone
;
    mov edi,[ebp+12]    
    mov al,7Fh
    sub al,ah
;    
    mov ah,200
    mul ah
    movzx eax,ah
    mov [edi],eax

rgmvDone:
    pop edi
	pop ebp
	ret 8
RdosGetMasterVolume	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetMasterVolume
;
;		DESCRIPTION:    Set master volume
;
;       PARAMETERS:     Left (0-100, negative = mute)
;                       Right (0-100, negative = mute)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetMasterVolume

RdosSetMasterVolume	PROC
	push ebp
	mov ebp,esp
	push ebx
;
    mov ax,set_master_volume_nr
    UserGate is_valid_usergate_nr
    jc rsmvDone
;    
    mov eax,[ebp+8]
    mov bl,80h
    test eax,80000000h
    jnz rsmvR
;    
    xor bl,bl
    cmp eax,100
    jae rsmvR
;
    mov ah,al
    xor al,al
    mov bl,200
    div bl
;
    mov bl,7Fh
    sub bl,al    

rsmvR:
    mov eax,[ebp+12]
    mov bh,80h
    test eax,80000000h
    jnz rsmvSet
;    
    xor bh,bh
    cmp eax,100
    jae rsmvSet
;
    mov ah,al
    xor al,al
    mov bh,200
    div bh
;
    mov bh,7Fh    
    sub bh,al

rsmvSet:
    mov ax,bx
    UserGate set_master_volume_nr    

rsmvDone:
    pop ebx
	pop ebp
	ret 8
RdosSetMasterVolume	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosGetLineOutVolume
;
;		DESCRIPTION:    Get line out volume
;
;       PARAMETERS:     Left (0-100, negative = mute)
;                       Right (0-100, negative = mute)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosGetLineOutVolume

RdosGetLineOutVolume	PROC
	push ebp
	mov ebp,esp
	push edi
;
    mov edi,[ebp+8]
    mov dword ptr [edi],-1
;    
    mov edi,[ebp+12]
    mov dword ptr [edi],-1
;
    mov ax,get_line_out_volume_nr
    UserGate is_valid_usergate_nr
    jc rglovDone
;    
    UserGate get_line_out_volume_nr
    jc rglovDone
;    
    test al,80h
    jnz rglovR
;    
    mov edi,[ebp+8]
    push ax
;    
    mov ah,7Fh
    sub ah,al
;    
    mov al,200
    mul ah
    movzx eax,ah    
    mov [edi],eax
    pop ax

rglovR:
    test ah,80h
    jnz rglovDone
;
    mov edi,[ebp+12]
;    
    mov al,7Fh
    sub al,ah
;    
    mov ah,200
    mul ah
    movzx eax,ah
    mov [edi],eax

rglovDone:
    pop edi
	pop ebp
	ret 8
RdosGetLineOutVolume	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetLineOutVolume
;
;		DESCRIPTION:    Set line out volume
;
;       PARAMETERS:     Left (0-100, negative = mute)
;                       Right (0-100, negative = mute)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetLineOutVolume

RdosSetLineOutVolume	PROC
	push ebp
	mov ebp,esp
	push ebx
;
    mov ax,set_line_out_volume_nr
    UserGate is_valid_usergate_nr
    jc rslovDone
;
    mov eax,[ebp+8]
    mov bl,80h
    test eax,80000000h
    jnz rslovR
;    
    xor bl,bl
    cmp eax,100
    jae rslovR
;
    mov ah,al
    xor al,al
    mov bl,200
    div bl
;
    mov bl,7Fh
    sub bl,al    

rslovR:
    mov eax,[ebp+12]
    xor bh,bh
    test eax,80000000h
    jnz rslovSet
;    
    mov bh,7Fh
    cmp eax,100
    jae rslovSet
;
    mov ah,al
    xor al,al
    mov bh,200
    div bh
;
    mov bh,7Fh
    sub bh,al    

rslovSet:
    mov ax,bx
    UserGate set_line_out_volume_nr    

rslovDone:
    pop ebx
	pop ebp
	ret 8
RdosSetLineOutVolume	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateAudioOutChannel
;
;		DESCRIPTION:    Create audio out channel
;
;       PARAMETERS:     Sample rate
;                       Bits
;                       Volume (0..100)
;
;       RETURNS:        Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateAudioOutChannel

RdosCreateAudioOutChannel	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;
    xor bx,bx
    mov ax,create_audio_out_channel_nr
    UserGate is_valid_usergate_nr
    jc rcaocDone
;
    mov eax,[ebp+16]    
    mov bx,0FFFFh
    cmp eax,100
    jae caocVolOk
;
    mov dx,ax
    xor ax,ax
    mov bx,100
    div bx
    mov bx,ax

caocVolOk:
    mov dx,bx
;    
    mov ax,[ebp+8]
    mov cl,[ebp+12]
    UserGate create_audio_out_channel_nr

rcaocDone:    
    movzx eax,bx    
;
    pop ecx
    pop ebx
	pop ebp
	ret 12
RdosCreateAudioOutChannel	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseAudioOutChannel
;
;		DESCRIPTION:    Close audio out channel
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseAudioOutChannel

RdosCloseAudioOutChannel	PROC
	push ebp
	mov ebp,esp
	push ebx
;
    mov bx,[ebp+8]
    or bx,bx
    jz caocDone
;    
    UserGate close_audio_out_channel_nr    

caocDone:
    pop ebx
	pop ebp
	ret 4
RdosCloseAudioOutChannel	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosWriteAudio
;
;		DESCRIPTION:    Write audio data
;
;       PARAMETERS:     Handle
;                       Size
;                       Left
;                       Right
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosWriteAudio

RdosWriteAudio	PROC
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
    mov bx,[ebp+8]
    or bx,bx
    jz waDone
;       
    mov ecx,[ebp+12]
    mov esi,[ebp+16]
    mov edi,[ebp+20]
    UserGate write_audio_nr    

waDone:
    pop edi
    pop esi
    pop ebx
	pop ebp
	ret 16
RdosWriteAudio	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosOpenFm
;
;		DESCRIPTION:    Open FM handle
;
;       PARAMETERS:     Sample rate
;
;       RETURNS:        FM handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosOpenFm

RdosOpenFm	PROC
	push ebp
	mov ebp,esp
	push ebx
;       
    mov ax,[ebp+8]
    UserGate open_fm_nr    
    movzx eax,bx
;
    pop ebx
	pop ebp
	ret 4
RdosOpenFm	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCloseFm
;
;		DESCRIPTION:    Close FM handle
;
;       PARAMETERS:     FM handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCloseFm

RdosCloseFm	PROC
	push ebp
	mov ebp,esp
	push ebx
;       
    mov bx,[ebp+8]
    UserGate close_fm_nr    
;
    pop ebx
	pop ebp
	ret 4
RdosCloseFm	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosFmWait
;
;		DESCRIPTION:    Wait for a number of samples to pass
;
;       PARAMETERS:     FM handle
;                       Samples to wait
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosFmWait

RdosFmWait	PROC
	push ebp
	mov ebp,esp
	push ebx
;       
    mov bx,[ebp+8]
    mov eax,[ebp+12]
    UserGate fm_wait_nr    
;
    pop ebx
	pop ebp
	ret 8
RdosFmWait	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosCreateFmInstrument
;
;		DESCRIPTION:    Create FM instrument
;
;       PARAMETERS:     FM handle
;                       C
;                       M
;                       Beta
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosCreateFmInstrument

RdosCreateFmInstrument	PROC
	push ebp
	mov ebp,esp
	push ebx
	push ecx
;       
    mov bx,[ebp+8]
    mov ax,[ebp+12]
    mov dx,[ebp+16]
    fld tbyte ptr [ebp+20]
    UserGate create_fm_instrument_nr    
    movzx eax,bx
;
    pop ecx
    pop ebx
	pop ebp
	ret 24
RdosCreateFmInstrument	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosFreeFmInstrument
;
;		DESCRIPTION:    Free FM instrument
;
;       PARAMETERS:     Handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosFreeFmInstrument

RdosFreeFmInstrument	PROC
	push ebp
	mov ebp,esp
	push ebx
;       
    mov bx,[ebp+8]
    UserGate free_fm_instrument_nr    
;
    pop ebx
	pop ebp
	ret 4
RdosFreeFmInstrument	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFmAttack
;
;		DESCRIPTION:    Set attack samples
;
;       PARAMETERS:     Handle
;                       Samples
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFmAttack

RdosSetFmAttack	PROC
	push ebp
	mov ebp,esp
	push ebx
;       
    mov bx,[ebp+8]
    mov eax,[ebp+12]
    UserGate set_fm_attack_nr    
;
    pop ebx
	pop ebp
	ret 8
RdosSetFmAttack	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFmSustain
;
;		DESCRIPTION:    Set FM sustain parameters
;
;       PARAMETERS:     Handle
;                       Volume half time (in samples)
;                       Beta half time (in samples)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFmSustain

RdosSetFmSustain	PROC
	push ebp
	mov ebp,esp
	push ebx
;       
    mov bx,[ebp+8]
    mov eax,[ebp+12]
    mov edx,[ebp+16]
    UserGate set_fm_sustain_nr    
;
    pop ebx
	pop ebp
	ret 12
RdosSetFmSustain	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosSetFmRelease
;
;		DESCRIPTION:    Set FM release parameters
;
;       PARAMETERS:     Handle
;                       Volume half time (in samples)
;                       Beta half time (in samples)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosSetFmRelease

RdosSetFmRelease	PROC
	push ebp
	mov ebp,esp
	push ebx
;       
    mov bx,[ebp+8]
    mov eax,[ebp+12]
    mov edx,[ebp+16]
    UserGate set_fm_release_nr    
;
    pop ebx
	pop ebp
	ret 12
RdosSetFmRelease	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			RdosPlayFmNote
;
;		DESCRIPTION:    Play FM note
;
;       PARAMETERS:     Handle
;                       Frequency
;                       Peak left volume
;                       Peak right volume
;                       Sustain (samples)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RdosPlayFmNote

RdosPlayFmNote	PROC
	push ebp
	mov ebp,esp
	push ebx
	push esi
;       
    mov bx,[ebp+8]
    fld tbyte ptr [ebp+12]
    mov eax,[ebp+24]
    mov edx,[ebp+28]    
    mov ecx,[ebp+32]    
    UserGate play_fm_note_nr    
;
    pop esi
    pop ebx
	pop ebp
	ret 28
RdosPlayFmNote	ENDP

;	extrn Startup:near

;	public _main

;_main:
;	jmp Startup

	END
