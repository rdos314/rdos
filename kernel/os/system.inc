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
; SYSTEM.INC
; System gate & commonly used bitness macros

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Retf16	MACRO
	db 66h
	db 0CBh
		ENDM

Retf32	MACRO
	db 66h
	db 0CBh
		ENDM

Callf16	MACRO	sel,offs
	db 66h
	db 9Ah
	dd sel SHL 16 + OFFSET offs
		ENDM

Callf32	MACRO	sel,offs
	db 66h
	db 9Ah
	dw OFFSET offs
	dw 0
	dw sel
		ENDM

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
