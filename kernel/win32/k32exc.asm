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
; K32EXC.ASM
; 32-bit kernel32.dll exception handing support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  k32exc

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\os\user.def

UserGate	MACRO gate_nr
	db 0Fh
	db 0Bh
	db 0D7h
	dd gate_nr
	nop
			ENDM

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

STATUS_BREAKPOINT		EQU	080000003h
STATUS_SINGLE_STEP		EQU	080000004h
STATUS_ACCESS_VIOLATION		EQU	0C0000005h
STATUS_NO_MEMORY		EQU	0C0000017h
STATUS_ILLEGAL_INSTRUCTION      EQU	0C000001Dh
STATUS_NONCONTINUABLE_EXCEPTION	EQU	0C0000025h
STATUS_ARRAY_BOUNDS_EXCEEDED	EQU	0C000008Ch
STATUS_INTEGER_DIVIDE_BY_ZERO	EQU	0C0000094h
STATUS_INTEGER_OVERFLOW		EQU	0C0000095h
STATUS_PRIVILEGED_INSTRUCTION	EQU	0C0000096h
STATUS_STACK_OVERFLOW		EQU	0C00000FDh
STATUS_CONTROL_C_EXIT		EQU	0C000013Ah
STATUS_FLOAT_DENORMAL_OPERAND   EQU   	0C000008Dh
STATUS_FLOAT_DIVIDE_BY_ZERO     EQU	0C000008Eh
STATUS_FLOAT_INEXACT_RESULT	EQU	0C000008Fh
STATUS_FLOAT_INVALID_OPERATION	EQU	0C0000090h
STATUS_FLOAT_OVERFLOW		EQU	0C0000091h
STATUS_FLOAT_STACK_CHECK	EQU	0C0000092h
STATUS_FLOAT_UNDERFLOW		EQU	0C0000093h
STATUS_INTEGER_DIVIDE_BY_ZERO	EQU	0C0000094h

CONTEXT_X86			EQU	10000h
CONTEXT_CONTROL			EQU	1
CONTEXT_INTEGER			EQU	2
CONTEXT_SEGMENTS		EQU	4
CONTEXT_FPU			EQU	8
CONTEXT_DREGS			EQU	10h

OUR_CNT	EQU	CONTEXT_X86+CONTEXT_CONTROL+CONTEXT_INTEGER+CONTEXT_SEGMENTS

ContextRecord	STRUC
		
ContextFlags	dd ?
DRSpace		dd 8 dup (?)	; not filled
FPUSpace	dd 28 dup (?)	; not filled
CntSegGs	dd ?
CntSegFs	dd ?
CntSegEs	dd ?
CntSegDs	dd ?
CntEdi		dd ?
CntEsi		dd ?
CntEbx		dd ?
CntEdx		dd ?
CntEcx		dd ?
CntEax		dd ?
CntEbp		dd ?
CntEip		dd ?
CntSegCs	dd ?
CntEFlags	dd ?
CntEsp		dd ?
CntSegSs	dd ?

ContextRecord	ENDS

DispatchRecord	STRUC
		pPrevious	dd ?	; DispatchRecord *pPrevious
		pEhandler	dd ?	; EHandler *pEhandler
DispatchRecord	ENDS

CONTINUABLE			EQU	0
NOT_CONTINUABLE			EQU	1
UNWINDING			EQU	2
UNWINDING_FOR_EXIT		EQU	4
UNWIND_IN_PROGRESS		EQU	6

ExceptionRecord	STRUC

ExceptionCode	dd ?	; Number of Exception
ExceptionFlags	dd ?
pOuterException	dd ?	; ExceptionRecord *pOuterException
ExceptionAddress dd ?
NumParams	dd ?	; Number of parameters following
ExceptionInfo	label near

ExceptionRecord	ENDS

.data

Cntx ContextRecord <>
Erec ExceptionRecord <>
OldExcHandlers dq 32 DUP (?)
EAddress dd 0

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           InitException
;
;       DESCRIPTION:    Init structered exception handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public InitException

InitException Proc near
	push es
	mov edx, OFFSET OldExcHandlers
	xor al,al

GetOldExc:
	UserGate get_exception_nr
	mov [edx], edi
	mov [edx+4], es
	add edx, 8
	inc al
	cmp al, 01fh
	jna GetOldExc
;
	mov ax,cs
	mov es,ax
	xor al,al
	mov edi,OFFSET StartEhand

SetNewExc:
	UserGate set_exception_nr
	inc al
	add edi, (OFFSET EndEhand - OFFSET StartEhand)/32
	cmp al, 01Fh
	jna SetNewExc
;
	pop es
	ret
InitException Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           FPUSetError
;
;       DESCRIPTION:    Set FPU error
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FPUExcTable db 90h,8dh,8eh,91h,93h,8fh,92h

FPUSetError Proc near
	push eax
	push edx
	push 0
	fnstsw [esp]
	mov eax, [esp]
	fnstcw [esp]
	fnclex
	pop edx
	not edx
	or edx, 1000000b
	and eax, 1111111b
	and edx, eax
	bsf eax, edx
	mov edx, 0c0000000h
	mov dl, FPUExcTable[eax]
	mov Erec.ExceptionCode, edx
	pop edx
	pop eax
	ret
FPUSetError Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           
;
;       DESCRIPTION:    Exception handling
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EcodeTab label dword

	dd STATUS_INTEGER_DIVIDE_BY_ZERO
	dd STATUS_SINGLE_STEP
	dd STATUS_NONCONTINUABLE_EXCEPTION
	dd STATUS_BREAKPOINT
	dd STATUS_INTEGER_OVERFLOW
	dd STATUS_ARRAY_BOUNDS_EXCEEDED
	dd STATUS_ILLEGAL_INSTRUCTION
	dd STATUS_NONCONTINUABLE_EXCEPTION
	dd STATUS_NONCONTINUABLE_EXCEPTION
	dd STATUS_NONCONTINUABLE_EXCEPTION 
	dd STATUS_NONCONTINUABLE_EXCEPTION
	dd STATUS_NONCONTINUABLE_EXCEPTION
	dd STATUS_STACK_OVERFLOW
	dd STATUS_PRIVILEGED_INSTRUCTION
	dd STATUS_ACCESS_VIOLATION

BackTrans label dword
	dd STATUS_INTEGER_DIVIDE_BY_ZERO
	dd STATUS_SINGLE_STEP
	dd STATUS_NONCONTINUABLE_EXCEPTION
	dd STATUS_BREAKPOINT
	dd STATUS_INTEGER_OVERFLOW
	dd STATUS_ARRAY_BOUNDS_EXCEEDED
	dd STATUS_ILLEGAL_INSTRUCTION
	dd STATUS_STACK_OVERFLOW
	dd STATUS_PRIVILEGED_INSTRUCTION
	dd STATUS_ACCESS_VIOLATION
	dd STATUS_NO_MEMORY
	dd STATUS_CONTROL_C_EXIT
	dd STATUS_FLOAT_DENORMAL_OPERAND
	dd STATUS_FLOAT_DIVIDE_BY_ZERO
	dd STATUS_FLOAT_INEXACT_RESULT
	dd STATUS_FLOAT_INVALID_OPERATION
	dd STATUS_FLOAT_OVERFLOW
	dd STATUS_FLOAT_STACK_CHECK
	dd STATUS_FLOAT_UNDERFLOW
	dd 0

BackString label near
	dd offset ExcStr0
	dd offset ExcStr1
	dd offset ExcStr2
	dd offset ExcStr3
	dd offset ExcStr4
	dd offset ExcStr5
	dd offset ExcStr6
	dd offset ExcStr7
	dd offset ExcStr8
	dd offset ExcStr9
	dd offset ExcStr10
	dd offset ExcStr11
	dd offset ExcStr12
	dd offset ExcStr13
	dd offset ExcStr14
	dd offset ExcStr15
	dd offset ExcStr16
	dd offset ExcStr17
	dd offset ExcStr18
	dd offset ExcStrUnavail

ExcStr0 db 'Integer divide by zero',0
ExcStr1 db 'Single step',0
ExcStr2 db 'Noncontiunuable exception',0
ExcStr3 db 'Breakpoint',0
ExcStr4 db 'Integer overflow',0
ExcStr5 db 'Array bounds exceeded',0
ExcStr6 db 'Illegal instruction',0
ExcStr7 db 'Stack overflow',0
ExcStr8 db 'Privileged instruction',0
ExcStr9 db 'Access violation',0
ExcStr10 db 'No memory',0
ExcStr11 db 'Control C exit',0
ExcStr12 db 'Float denormal operand',0
ExcStr13 db 'Float divide by zero',0
ExcStr14 db 'Float inexact result',0
ExcStr15 db 'Float invalid operation',0
ExcStr16 db 'Float overflow',0
ExcStr17 db 'Float stack check',0
ExcStr18 db 'Float underflow',0
ExcStrUnavail db '  N/A',0

StartEhand label near

i = 0
REPT 32
	elabel CATSTR <Exception>,%i
elabel:
	push i
	jmp short UnwindException
	i = i + 1
ENDM

EndEhand label near

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnwindException
;
;       DESCRIPTION:    Unwind exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ueFlags	EQU 28
ueCs	EQU 24
ueEip	EQU 20
ueCode	EQU 4

UnwindException:
	push ebp
	mov ebp,esp
	push ds
	push eax
;
	mov eax, cs
	cmp ax, [ebp].ueCs
	jne short ChainDebugger
;
	mov eax,[ebp].ueCode
	cmp eax,1
	jz short ChainDebugger

	cmp eax, 3
	jnz CheckForSecond
;
	dec dword ptr [ebp].ueEip
	jmp short ChainDebugger

CheckForSecond:
	mov eax, [ebp].ueEip
	xchg eax, EAddress
	cmp eax, EAddress
	jz short NoDebugger

ChainDebugger:
	mov eax,[ebp].ueCode
	mov eax,[4*eax].ECodeTab
	UserGate notify_pe_exception_nr
	pop eax
	pop ds
	pop ebp
	xchg eax, [esp]
	push dword ptr cs:[8*eax].OldExcHandlers
	mov eax, dword ptr cs:[8*eax+4].OldExcHandlers
	xchg eax, [esp+4]
	retf

NoDebugger:
;
; Save general registers
;
	mov Cntx.CntEax, eax
	mov Cntx.CntEbx, ebx
	mov Cntx.CntEcx, ecx
	mov Cntx.CntEdx, edx
	mov Cntx.CntEsi, esi
	mov Cntx.CntEdi, edi
	mov Cntx.CntEbp, ebp
;
; Save segment registers
;
	mov eax, [esp]
	mov Cntx.CntSegDs, eax
	mov Cntx.CntSegEs, es
	mov Cntx.CntSegFs, fs
	mov Cntx.CntSegGs, gs
;
; Get things pushed on stack by the DPMI host
;
	mov eax, [esp+20]
	mov Cntx.CntEip, eax
	mov Erec.ExceptionAddress, eax
	mov eax, [esp+24]
	mov Cntx.CntSegCs, eax
	mov eax, [esp+28]
	mov Cntx.CntEflags, eax
	mov eax, [esp+32]
	mov Cntx.CntEsp, eax
	mov eax, [esp+36]
	mov Cntx.CntSegSs, eax
;
; Get exception number
;
	mov eax, [esp+4]

; translate into Win32 exception code

	mov eax, ECodeTab[eax*4]
	mov Erec.ExceptionCode, eax

	mov Erec.NumParams, 1
	mov eax, [esp+16]
	mov DWORD PTR ds:[offset Erec.ExceptionInfo], eax

ExcNocode:
	mov DWORD PTR [esp+20], offset CPUExceptionHandler
	add esp, 8  ; skip exception number and ds
	retf  ; terminate exception handler


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CPUExceptionHandler
;
;       DESCRIPTION:    CPU exception handler
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CPUExceptionHandler Proc near
	push offset Erec.ExceptionInfo
	push Erec.Numparams
	push NOT_CONTINUABLE
	push Erec.ExceptionCode
	call RaiseException
;
	push offset Erec
	push offset Cntx
	xor eax,eax
	UserGate unload_exe_nr
CPUExceptionHandler Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RaiseException
;
;       DESCRIPTION:    Raise an exception
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RaiseException

RaiseException Proc near
	push ebp
	mov ebp, esp
	int 3
;
; Build ExceptionRecord on Stack
;
	mov edx, [ebp+20] ; pointer to arguments
	mov ecx, [ebp+16] ; number of arguments
	mov eax, ecx
	jecxz ReNoCpy

ReDoCpy:
	push DWORD PTR [ecx*4-4+edx]
	loop short ReDoCpy

ReNoCpy:
	push eax  ; Num args
	push Cntx.CntEip
	push 0
	push DWORD PTR [ebp+12] ; flags
	push DWORD PTR [ebp+8] ; code

	; traverse handler chain

	mov edx, fs: [ecx]

ReCallHandler:
	cmp edx, -1
	jz ReNoHandler ; should never happen

	mov eax, esp
	push edx
	push edx
	push offset Cntx
	push edx
	push eax
	call pEhandler[edx]
	add esp, 16
	pop edx
	mov edx, pPrevious[edx]
	test eax, eax ; did the handler do something?
	jnz short ReCallHandler

ReNoHandler:
	mov esp, ebp
	pop ebp
	ret 16
RaiseException Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UnhandledExceptionFilter
;
;       DESCRIPTION:    Unhandled exception filter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public UnhandledExceptionFilter

UnhandledExceptionFilter Proc near
	int 3
	xor eax,eax
	ret 4
UnhandledExceptionFilter Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetUnhandledExceptionFilter
;
;       DESCRIPTION:    Set unhandled exception filter
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetUnhandledExceptionFilter

SetUnhandledExceptionFilter Proc near
	xor eax,eax
	ret 4
SetUnhandledExceptionFilter Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           RtlUnwind
;
;       DESCRIPTION:    Rtl unwind
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public RtlUnwind

RtlUnwind Proc near
	int 3
	cmp dword ptr [esp+4], 1
	sbb dword ptr [esp+4], 0
	pop edx
	mov edx, [esp+8]
	test edx, edx
	jnz short UnwindChain

UnwindDone:
	pop dword ptr fs:[0]
	ret 8

UnwindChain:
	mov ecx, fs:[0]

UnwindNext:
	cmp ecx, [esp]
	jz short UnwindDone

	push ecx
	push edx
	push ecx
	push 0 
	push ecx
	push edx 
	call pEHandler[ecx]
	add esp, 16
	pop edx
	pop ecx
	mov ecx, pPrevious[ecx]
	jmp short UnwindNext
RtlUnwind Endp

	END
