;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Em486 CPU emulator
; Copyright (C) 1998-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage. For information on commercial usage,
; contact em486@rdos.net.
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
; EMSTRING.ASM
; String emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat
						
		NAME emstring

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

include ..\core\emulate.inc
include ..\core\emcom.inc
include ..\core\emmem.inc

.code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SourceAds
;
;		DESCRIPTION:	Get source operand
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SourceAds	MACRO
	local source32
	local done

	test byte ptr [ebp].em_flags,a32
	jnz source32
;
	call MemSi
	jmp done

source32:
	call MemEsi

done:
				ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SourceByte
;
;		DESCRIPTION:	Update source after byte access
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SourceByte	MACRO
	local source32
	local up16
	local done
	local up32

	test byte ptr [ebp].em_flags,a32
	jnz source32
;
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up16
;
	dec word ptr [ebp].reg_esi
	jmp done

up16:
	inc word ptr [ebp].reg_esi
	jmp done

source32:
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up32
;
	dec [ebp].reg_esi
	jmp done

up32:
	inc [ebp].reg_esi

done:
				ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SourceWord
;
;		DESCRIPTION:	Update source after word access
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SourceWord	MACRO
	local source32
	local up16
	local up32
	local done

	test byte ptr [ebp].em_flags,a32
	jnz source32
;
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up16
;
	sub word ptr [ebp].reg_esi,2
	jmp done

up16:
	add word ptr [ebp].reg_esi,2
	jmp done

source32:
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up32
;
	sub [ebp].reg_esi,2
	jmp done

up32:
	add [ebp].reg_esi,2

done:
			ENDM


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SourceDword
;
;		DESCRIPTION:	Update source after dword access
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SourceDword	MACRO
	local source32
	local up16
	local up32
	local done

	test byte ptr [ebp].em_flags,a32
	jnz source32
;
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up16
;
	sub word ptr [ebp].reg_esi,4
	jmp done

up16:
	add word ptr [ebp].reg_esi,4
	jmp done

source32:
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up32
;
	sub [ebp].reg_esi,4
	jmp done

up32:
	add [ebp].reg_esi,4

done:
		ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DestAds
;
;		DESCRIPTION:	Get dest address
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DestAds	MACRO
	local dest32
	local done

	test byte ptr [ebp].em_flags,a32
	jnz dest32
;
	mov si,OFFSET reg_es
	movzx ebx,word ptr [ebp].reg_edi
	jmp done

dest32:
	mov si,OFFSET reg_es
	mov ebx,[ebp].reg_edi

done:
				ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DestByte
;
;		DESCRIPTION:	Update destination after byte access
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DestByte	MACRO
	local dest32
	local up16
	local done
	local up32

	push ax
	test byte ptr [ebp].em_flags,a32
	jnz dest32
;
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up16
;
	dec word ptr [ebp].reg_edi
	jmp done

up16:
	inc word ptr [ebp].reg_edi
	jmp done

dest32:
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up32
;
	dec [ebp].reg_edi
	jmp done

up32:
	inc [ebp].reg_edi

done:
	pop ax
				ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DestWord
;
;		DESCRIPTION:	Update destination after word access
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DestWord	MACRO
	local dest32
	local up16
	local done
	local up32

	push ax
	test byte ptr [ebp].em_flags,a32
	jnz dest32
;
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up16
;
	sub word ptr [ebp].reg_edi,2
	jmp done

up16:
	add word ptr [ebp].reg_edi,2
	jmp done

dest32:
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up32
;
	sub [ebp].reg_edi,2
	jmp done

up32:
	add [ebp].reg_edi,2

done:
	pop ax
				ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DestDword
;
;		DESCRIPTION:	Update destination after dword access
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DestDword	MACRO
	local dest32
	local up16
	local done
	local up32

	push ax
	test byte ptr [ebp].em_flags,a32
	jnz dest32
;
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up16
;
	sub word ptr [ebp].reg_edi,4
	jmp done

up16:
	add word ptr [ebp].reg_edi,4
	jmp done

dest32:
	mov al,byte ptr [ebp+1].reg_eflags
	test al,4
	jz up32
;
	sub [ebp].reg_edi,4
	jmp done

up32:
	add [ebp].reg_edi,4

done:
	pop ax
				ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			DecCount
;
;		DESCRIPTION:	Update counter
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecCount	MACRO
	local count32
	local done

	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jz done
;
	test byte ptr [ebp].em_flags,a32
	jnz count32
;
	sub word ptr [ebp].reg_ecx,1
	jmp done

count32:
	sub dword ptr [ebp].reg_ecx,1

done:
		ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckDone
;
;		DESCRIPTION:	Check if repeat is done
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckDone	MACRO
	local count32
	local done

	test byte ptr [ebp].em_flags,a32
	jnz count32
;
	cmp word ptr [ebp].reg_ecx,0
	jmp done

count32:
	cmp dword ptr [ebp].reg_ecx,0

done:
		ENDM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckFlags
;
;		DESCRIPTION:	Check if flags terminate repeat
;
;		PARAMETERS:		SS:EBP	CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckFlags	MACRO
	local check_repz
	local check_repnz
	local done

	test byte ptr [ebp].em_flags,rep_z
	je check_repz

check_repnz:
	mov dl,byte ptr [ebp].reg_eflags
	and dl,40h
	jmp done

check_repz:
	mov dl,byte ptr [ebp].reg_eflags
	not dl
	and dl,40h

done:
		ENDM
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmLodsb
;
;		DESCRIPTION:	EMULATE lodsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmLodsb

EmLodsb	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepLodsb
;
	SourceAds
	call ReadByte
	mov byte ptr [ebp].reg_eax,al
	SourceByte
	ret

RepLodsb:
	CheckDone
	jnz RepLodsbDo
	ret

RepLodsbDo:
	SourceAds
	call ReadByte
	mov byte ptr [ebp].reg_eax,al
	SourceByte
	DecCount
	jnz RepLodsbMore
	ret

RepLodsbMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmLodsb	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmLodsw / EmLodsd
;
;		DESCRIPTION:	EMULATE lodsw / lodsd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmLodsw

EmLodsw	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepLodsw
;
	test byte ptr [ebp].em_flags,d32
	jnz EmLodsd
;
	SourceAds
	call ReadWord
	mov word ptr [ebp].reg_eax,ax
	SourceWord
	ret

EmLodsd:
	SourceAds
	call ReadDword
	mov [ebp].reg_eax,eax
	SourceDword
	ret

RepLodsw:
	CheckDone
	jnz RepLodswDo
	ret

RepLodswDo:
	test byte ptr [ebp].em_flags,d32
	jnz RepLodsd
;
	SourceAds
	call ReadWord
	mov word ptr [ebp].reg_eax,ax
	SourceWord
	DecCount
	jnz RepLodswMore
	ret

RepLodsd:
	SourceAds
	call ReadDword
	mov [ebp].reg_eax,eax
	SourceDword
	DecCount
	jnz RepLodswMore
	ret

RepLodswMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmLodsw	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmStosb
;
;		DESCRIPTION:	EMULATE stosb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmStosb

EmStosb	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepStosb
;
	DestAds
	mov al,byte ptr [ebp].reg_eax
	call WriteByte
	DestByte
	ret

RepStosb:
	CheckDone
	jnz RepStosbDo
	ret

RepStosbDo:
	DestAds
	mov al,byte ptr [ebp].reg_eax
	call WriteByte
	DestByte
	DecCount
	jnz RepStosbMore
	ret

RepStosbMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmStosb	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmStosw / EmStosd
;
;		DESCRIPTION:	EMULATE stosw / stosd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmStosw

EmStosw	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepStosw
;
	test byte ptr [ebp].em_flags,d32
	jnz EmStosd
;
	DestAds
	mov ax,word ptr [ebp].reg_eax
	call WriteWord
	DestWord
	ret

EmStosd:
	DestAds
	mov eax,[ebp].reg_eax
	call WriteDword
	DestDword
	ret

RepStosw:
	CheckDone
	jnz RepStoswDo
	ret

RepStoswDo:
	test byte ptr [ebp].em_flags,d32
	jnz RepStosd
;
	DestAds
	mov ax,word ptr [ebp].reg_eax
	call WriteWord
	DestWord
	DecCount
	jnz RepStoswMore
	ret

RepStosd:
	DestAds
	mov eax,[ebp].reg_eax
	call WriteDword
	DestDword
	DecCount
	jnz RepStoswMore
	ret

RepStoswMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmStosw	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmMovsb
;
;		DESCRIPTION:	EMULATE movsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmMovsb

EmMovsb	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepMovsb
;
	SourceAds
	call ReadByte
	push ax
	DestAds
	pop ax
	call WriteByte
	SourceByte
	DestByte
	ret

RepMovsb:
	CheckDone
	jnz RepMovsbDo
	ret

RepMovsbDo:
	SourceAds
	call ReadByte
	push ax
	DestAds
	pop ax
	call WriteByte
	SourceByte
	DestByte
	DecCount
	jnz RepMovsbMore
	ret

RepMovsbMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmMovsb	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmMovsw / EmMovsd
;
;		DESCRIPTION:	EMULATE movsw / movsd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmMovsw

EmMovsw	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepMovsw
;
	test byte ptr [ebp].em_flags,d32
	jnz EmMovsd
;
	SourceAds
	call ReadWord
	push ax
	DestAds
	pop ax
	call WriteWord
	SourceWord
	DestWord
	ret

EmMovsd:
	SourceAds
	call ReadDword
	push eax
	DestAds
	pop eax
	call WriteDword
	SourceDword
	DestDword
	ret

RepMovsw:
	CheckDone
	jnz RepMovswDo
	ret

RepMovswDo:
	test byte ptr [ebp].em_flags,d32
	jnz RepMovsd
;
	SourceAds
	call ReadWord
	push ax
	DestAds
	pop ax
	call WriteWord
	SourceWord
	DestWord
	DecCount
	jnz RepMovswMore
	ret

RepMovsd:
	SourceAds
	call ReadDword
	push eax
	DestAds
	pop eax
	call WriteDword
	SourceDword
	DestDword
	DecCount
	jnz RepMovswMore
	ret

RepMovswMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmMovsw	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmScasb
;
;		DESCRIPTION:	EMULATE scasb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmScasb

EmScasb	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepScasb
;
	DestAds
	call ReadByte
	DestByte
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub al,byte ptr [ebp].reg_eax
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	ret

RepScasb:
	CheckDone
	jnz RepScasbDo
	ret

RepScasbDo:
	DestAds
	call ReadByte
	DestByte
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub al,byte ptr [ebp].reg_eax
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	DecCount
	jnz RepScasbNotDone
	ret

RepScasbNotDone:
	CheckFlags
	jnz RepScasbMore
	ret

RepScasbMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmScasb	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmScasw / EmScasd
;
;		DESCRIPTION:	EMULATE scasw / scasd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmScasw

EmScasw	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepScasw
;
	test byte ptr [ebp].em_flags,d32
	jnz EmScasd
;
	DestAds
	call ReadWord
	DestWord
	mov dx,ax
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub dx,word ptr [ebp].reg_eax
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	ret

EmScasd:
	DestAds
	call ReadDword
	DestDword
	mov edx,eax
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub edx,[ebp].reg_eax
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	ret

RepScasw:
	CheckDone
	jnz RepScaswDo
	ret

RepScaswDo:
	test byte ptr [ebp].em_flags,d32
	jnz RepScasd
;
	DestAds
	call ReadWord
	DestWord
	mov dx,ax
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub dx,word ptr [ebp].reg_eax
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	DecCount
	jnz RepScaswNotDone
	ret

RepScasd:
	DestAds
	call ReadDword
	DestDword
	mov edx,eax
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub edx,[ebp].reg_eax
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	DecCount
	jnz RepScaswNotDone
	ret

RepScaswNotDone:
	CheckFlags
	jnz RepScaswMore
	ret

RepScaswMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmScasw	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCmpsb
;
;		DESCRIPTION:	EMULATE cmpsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmCmpsb

EmCmpsb	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepCmpsb
;
	SourceAds
	call ReadByte
	push ax
	DestAds
	call ReadByte
	SourceByte
	DestByte
	pop dx
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub dl,al
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	ret

RepCmpsb:
	CheckDone
	jnz RepCmpsbDo
	ret

RepCmpsbDo:
	SourceAds
	call ReadByte
	push ax
	DestAds
	call ReadByte
	SourceByte
	DestByte
	pop dx
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub dl,al
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	DecCount
	jnz RepCmpsbNotDone
	ret

RepCmpsbNotDone:
	CheckFlags
	jnz RepCmpsbMore
	ret

RepCmpsbMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmCmpsb	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCmpsw / EmCmpsd
;
;		DESCRIPTION:	EMULATE cmpsw / cmpsd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmCmpsw

EmCmpsw	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepCmpsw
;
	test byte ptr [ebp].em_flags,d32
	jnz EmCmpsd
;
	SourceAds
	call ReadWord
	push ax
	DestAds
	call ReadWord
	SourceWord
	DestWord
	pop bx
	mov dx,ax
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub bx,dx
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	ret

EmCmpsd:
	SourceAds
	call ReadDword
	push eax
	DestAds
	call ReadDword
	SourceDword
	DestDword
	pop ebx
	mov edx,eax
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub ebx,edx
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	ret

RepCmpsw:
	CheckDone
	jnz RepCmpswDo
	ret

RepCmpswDo:
	test byte ptr [ebp].em_flags,d32
	jnz RepCmpsd
;
	SourceAds
	call ReadWord
	push ax
	DestAds
	call ReadWord
	SourceWord
	DestWord
	pop bx
	mov dx,ax
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub bx,dx
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	DecCount
	jnz RepCmpswNotDone
	ret

RepCmpsd:
	SourceAds
	call ReadDword
	push eax
	DestAds
	call ReadDword
	SourceDword
	DestDword
	pop ebx
	mov edx,eax
	mov ah,byte ptr [ebp].reg_eflags
	sahf
	sub ebx,edx
	lahf
	mov byte ptr [ebp].reg_eflags,ah
	DecCount
	jnz RepCmpswNotDone
	ret

RepCmpswNotDone:
	CheckFlags
	jnz RepCmpswMore
	ret

RepCmpswMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmCmpsw	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmInsb
;
;		DESCRIPTION:	EMULATE insb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmInsb

EmInsb	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepInsb
;
	mov dx,word ptr [ebp].reg_edx
	call InByte
	push ax
	DestAds
	pop ax
	call WriteByte
	DestByte
	ret

RepInsb:
	CheckDone
	jnz RepInsbDo
	ret

RepInsbDo:
	mov dx,word ptr [ebp].reg_edx
	call InByte
	push ax
	DestAds
	pop ax
	call WriteByte
	DestByte
	DecCount
	jnz RepInsbMore
	ret

RepInsbMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmInsb	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmInsw / EmInsd
;
;		DESCRIPTION:	EMULATE insw / insd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmInsw

EmInsw	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepInsw
;
	test byte ptr [ebp].em_flags,d32
	jnz EmInsd
;
	mov dx,word ptr [ebp].reg_edx
	call InWord
	push ax
	DestAds
	pop ax
	call WriteWord
	DestWord
	ret

EmInsd:
	mov dx,word ptr [ebp].reg_edx
	call InDword
	push eax
	DestAds
	pop eax
	call WriteDword
	DestDword
	ret

RepInsw:
	CheckDone
	jnz RepInswDo
	ret

RepInswDo:
	test byte ptr [ebp].em_flags,d32
	jnz RepInsd
;
	mov dx,word ptr [ebp].reg_edx
	call InWord
	push ax
	DestAds
	pop ax
	call WriteWord
	DestWord
	DecCount
	jnz RepInswMore
	ret

RepInsd:
	mov dx,word ptr [ebp].reg_edx
	call InDword
	push eax
	DestAds
	pop eax
	call WriteDword
	DestDword
	DecCount
	jnz RepInswMore
	ret

RepInswMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmInsw	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOutsb
;
;		DESCRIPTION:	EMULATE outsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmOutsb

EmOutsb	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepOutsb
;
	SourceAds
	call ReadByte
	mov dx,word ptr [ebp].reg_edx
	call OutByte
	SourceByte
	ret

RepOutsb:
	CheckDone
	jnz RepOutsbDo
	ret

RepOutsbDo:
	SourceAds
	call ReadByte
	mov dx,word ptr [ebp].reg_edx
	call OutByte
	SourceByte
	DecCount
	jnz RepOutsbMore
	ret

RepOutsbMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmOutsb	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOutsw / EmOutsd
;
;		DESCRIPTION:	EMULATE outsw / outsd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmOutsw

EmOutsw	Proc near
	test byte ptr [ebp].em_flags,rep_z OR rep_nz
	jnz RepOutsw
;
	test byte ptr [ebp].em_flags,d32
	jnz EmOutsd
;
	SourceAds
	call ReadWord
	mov dx,word ptr [ebp].reg_edx
	call OutWord
	SourceWord
	ret

EmOutsd:
	SourceAds
	call ReadDword
	mov dx,word ptr [ebp].reg_edx
	call OutDword
	SourceDword
	ret

RepOutsw:
	CheckDone
	jnz RepOutswDo
	ret

RepOutswDo:
	test byte ptr [ebp].em_flags,d32
	jnz RepOutsd
;
	SourceAds
	call ReadWord
	mov dx,word ptr [ebp].reg_edx
	call OutWord
	SourceWord
	DecCount
	jnz RepMovswMore
	ret

RepOutsd:
	SourceAds
	call ReadDword
	mov dx,word ptr [ebp].reg_edx
	call OutDword
	SourceDword
	DecCount
	jnz RepOutswMore
	ret

RepOutswMore:
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	ret
EmOutsw	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmXlat
;
;		DESCRIPTION:	EMULATE xlat
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmXlat

EmXlat	Proc near
	test byte ptr [ebp].em_flags,a32
	jnz EmXlat32

EmXlat16:
	call MemBx
	movzx eax,byte ptr [ebp].reg_eax
	add ebx,eax
	call ReadByte
	mov byte ptr [ebp].reg_eax,al
	ret

EmXlat32:
	call MemEbx
	movzx eax,byte ptr [ebp].reg_eax
	add ebx,eax
	call ReadByte
	mov byte ptr [ebp].reg_eax,al
	ret
EmXlat	Endp

	END
