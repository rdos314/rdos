
page 40,130
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		FILNAMN:		SWAP.ASM
;
;		PROGRAMMERARE:	LE
;
;		DATUM:			97-12-28
;
;		[NDAM]L:		Swap support
;
;		BESKRIVNING:
;
;		[NDRINGAR:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PAGE

		NAME  swap

.386c
.model flat

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			SwapWord
;
;		DESCRIPTION:	Swap word
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SwapWord

SwapWord	PROC
	push ebp
	mov ebp,esp
;
	mov al,[ebp+9]
	mov ah,[ebp+8]
;
	pop ebp
	ret 4
SwapWord	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		NAME:			SwapDword
;
;		DESCRIPTION:	Swap dword
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SwapDword

SwapDword	PROC
	push ebp
	mov ebp,esp
;
	mov al,[ebp+8]
	shl eax,8
	mov al,[ebp+9]
	shl eax,8
	mov al,[ebp+10]
	shl eax,8
	mov al,[ebp+11]
;
	pop ebp
	ret 4
SwapDword	ENDP

        END
