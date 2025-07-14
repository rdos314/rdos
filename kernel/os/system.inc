;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; SYSTEM.INC
; System gate & commonly used bitness macros

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReflectEnd	MACRO
	db 0Fh
	db 0Bh
	db 010h
					ENDM

SimVM16End	MACRO
	db 0Fh
	db 0Bh
	db 011h
					ENDM

SimVM32End	MACRO
	db 0Fh
	db 0Bh
	db 012h
					ENDM

VMCallback16	MACRO
	db 0Fh
	db 0Bh
	db 013h
					ENDM

VMCallback32	MACRO
	db 0Fh
	db 0Bh
	db 014h
					ENDM

ReflectPMToVMDone	MACRO 
	db 0Fh
	db 0Bh
	db 015h
				ENDM


ReflectPM16		MACRO int_nr
	db 0Fh
	db 0Bh
	db 16h
	db int_nr
				ENDM 

ReflectPM32		MACRO int_nr
	db 0Fh
	db 0Bh
	db 17h
	db int_nr
				ENDM 

IrqVm		MACRO int_nr
	db 0Fh
	db 0Bh
	db 18h
	db int_nr
				ENDM 

IrqProt16		MACRO int_nr
	db 0Fh
	db 0Bh
	db 19h
	db int_nr
				ENDM 

IrqProt32		MACRO int_nr
	db 0Fh
	db 0Bh
	db 1Ah
	db int_nr
				ENDM 

CallVMRet		MACRO
	db 0Fh
	db 0Bh
	db 1Ch
				ENDM 

CallPM16Ret		MACRO
	db 0Fh
	db 0Bh
	db 1Ch
				ENDM 

CallPM32Ret		MACRO
	db 0Fh
	db 0Bh
	db 1Dh
				ENDM 

DefaultException16	MACRO int_nr
	db 0Fh
	db 0Bh
	db 1Eh
	db int_nr
					ENDM

BreakException16	MACRO int_nr
	db 0Fh
	db 0Bh
	db 1Fh
	db int_nr
					ENDM

DefaultException32	MACRO int_nr
	db 0Fh
	db 0Bh
	db 20h
	db int_nr
					ENDM

BreakException32	MACRO int_nr
	db 0Fh
	db 0Bh
	db 21h
	db int_nr
					ENDM

;OsGate16	MACRO gate_nr
;	db 0Fh
;	db 0Bh
;	db 0CAh
;	dw gate_nr

;OsGate32	MACRO gate_nr
;	db 0Fh
;	db 0Bh
;	db 0CBh
;	dw gate_nr
;	nop

ReflectVMToPM	MACRO int_nr
	db 0Fh
	db 0Bh
	db 0F1h
	db int_nr
				ENDM

ReflectInt	MACRO int_nr
	db 0Fh
	db 0Bh
	db 0F2h
	dw int_nr
					ENDM

DpmiEntry	MACRO
	db 0Fh
	db 0Bh
	db 0F7h
	dw 0
					ENDM

ShutDownBoot	MACRO
	db 9Ah
	dw 0
	dw shutdown_boot_gate
			ENDM

ShutDownPreTask	MACRO
	db 9Ah
	dw 0
	dw shutdown_pretask_gate
			ENDM

ShutDownTask	MACRO
	db 9Ah
	dw 0
	dw shutdown_task_gate
			ENDM
