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
; EMARITHM.ASM
; Arithmetric functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME emarithm

GateSize = 16

	.386p

include emulate.inc
include emcom.inc
include emmem.inc

ByteRegMem	Macro op

	public Em&op&ByteRegMem

Em&op&ByteRegMem	Proc near
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadByteReg
	pop bx
	push bx
	push ax
	call LoadByteMemReg
	mov bl,al
	pop ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al,bl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop bx
	call SaveByteReg
	ret
Em&op&ByteRegMem	Endp
			Endm

WordRegMem	Macro op

	public Em&op&WordRegMem

Em&op&WordRegMem	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordRegMem
;
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadWordReg
	pop bx
	push bx
	push ax
	call LoadWordMemReg
	mov dx,ax
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov ax,bx
	pop bx
	call SaveWordReg
	ret
Em&op&WordRegMem	Endp

Em&op&DwordRegMem	Proc near
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadDwordReg
	pop bx
	push bx
	push eax
	call LoadDwordMemReg
	mov edx,eax
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov eax,ebx
	pop bx
	call SaveDwordReg
	ret
Em&op&DwordRegMem	Endp

			Endm

ByteMemReg	Macro op

	public Em&op&ByteMemReg

Em&op&ByteMemReg	Proc near
	call ReadCodeByte
	mov bl,al
;
	push bx
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&ByteMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&ByteMemReg16
	or bl,40h	
Em&op&ByteMemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	pop ax
	push si
	push ebx
	push ax
	call ReadByte
	pop bx
	push ax
	call LoadByteReg
	mov bl,al
	pop ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al,bl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop ebx
	pop si
	call WriteByte
	ret

Em&op&ByteMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].ByteRegTab
	mov al,[bp+si]
	pop bx
	push si
	push ax
	call LoadByteReg
	mov bl,al
	pop ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al,bl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop si
	mov [bp+si],al
	ret
Em&op&ByteMemReg	Endp
			Endm

WordMemReg	Macro op

	public Em&op&WordMemReg

Em&op&WordMemReg	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordMemReg
;
	call ReadCodeByte
	mov bl,al
	push bx
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&WordMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&WordMemReg16
	or bl,40h	
Em&op&WordMemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	pop ax
	push si
	push ebx
	push ax
	call ReadWord
	pop bx
	push ax
	call LoadWordReg
	mov dx,ax
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov ax,bx
	pop ebx
	pop si
	call WriteWord
	ret

Em&op&WordMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].WordRegTab
	mov ax,[bp+si]
	pop bx
	push si
	push ax
	call LoadWordReg
	mov dx,ax
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop si
	mov [bp+si],bx
	ret
Em&op&WordMemReg	Endp

Em&op&DwordMemReg	Proc near
	call ReadCodeByte
	mov bl,al
	push bx
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&DwordMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&DwordMemReg16
	or bl,40h	
Em&op&DwordMemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	pop ax
	push si
	push ebx
	push ax
	call ReadDword
	pop bx
	push eax
	call LoadDwordReg
	mov edx,eax
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov eax,ebx
	pop ebx
	pop si
	call WriteDword
	ret

Em&op&DwordMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov eax,[bp+si]
	pop bx
	push si
	push eax
	call LoadDwordReg
	mov edx,eax
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop si
	mov [bp+si],ebx
	ret
Em&op&DwordMemReg	Endp

			Endm

ByteMem	Macro op

	public Em&op&ByteMem

Em&op&ByteMem	Proc near
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&ByteMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&ByteMem16
	or bl,40h	
Em&op&ByteMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadByte
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop ebx
	pop si
	call WriteByte
	ret

Em&op&ByteMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].ByteRegTab
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op byte ptr [bp+si]
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&ByteMem	Endp

			Endm

WordMem	Macro op

	public Em&op&WordMem

Em&op&WordMem	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordMem
;
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&WordMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&WordMem16
	or bl,40h	
Em&op&WordMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadWord
	mov dx,ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov ax,dx
	pop ebx
	pop si
	call WriteWord
	ret

Em&op&WordMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].WordRegTab
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op word ptr [bp+si]
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&WordMem	Endp

Em&op&DwordMem	Proc near
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&DwordMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&DwordMem16
	or bl,40h	
Em&op&DwordMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadDword
	mov edx,eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov eax,edx
	pop ebx
	pop si
	call WriteDword
	ret

Em&op&DwordMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op dword ptr [bp+si]
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&DwordMem	Endp

			Endm

ByteImMem	Macro op

	public Em&op&ByteImMem

Em&op&ByteImMem	Proc near
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&ByteImMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&ByteImMem16
	or bl,40h	
Em&op&ByteImMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadByte
	push ax
	call ReadCodeByte
	mov bl,al
	pop ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al,bl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop ebx
	pop si
	call WriteByte
	ret

Em&op&ByteImMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].ByteRegTab
	mov al,[bp+si]
	push si
	push ax
	call ReadCodeByte
	mov bl,al
	pop ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al,bl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop si
	mov [bp+si],al
	ret
Em&op&ByteImMem	Endp
			Endm

WordImMem	Macro op

	public Em&op&WordImMem

Em&op&WordImMem	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordImMem
;
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&WordImMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&WordImMem16
	or bl,40h	
Em&op&WordImMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadWord
	push ax
	call ReadCodeWord
	mov dx,ax
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov ax,bx
	pop ebx
	pop si
	call WriteWord
	ret

Em&op&WordImMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].WordRegTab
	mov ax,[bp+si]
	push si
	push ax
	call ReadCodeWord
	mov dx,ax
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop si
	mov [bp+si],bx
	ret
Em&op&WordImMem	Endp

Em&op&DwordImMem	Proc near
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&DwordImMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&DwordImMem16
	or bl,40h	
Em&op&DwordImMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadDword
	push eax
	call ReadCodeDword
	mov edx,eax
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov eax,ebx
	pop ebx
	pop si
	call WriteDword
	ret

Em&op&DwordImMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov eax,[bp+si]
	push si
	push eax
	call ReadCodeDword
	mov edx,eax
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop si
	mov [bp+si],ebx
	ret
Em&op&DwordImMem	Endp

			Endm

ByteImAcc	Macro op

	public Em&op&ByteImAcc

Em&op&ByteImAcc	Proc near
	call ReadCodeByte
	mov bl,byte ptr [bp].reg_eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bl,al
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov byte ptr [bp].reg_eax,bl
	ret
Em&op&ByteImAcc	Endp
			Endm

WordImAcc	Macro op

	public Em&op&WordImAcc

Em&op&WordImAcc	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordImAcc
;
	call ReadCodeWord
	mov dx,ax
	mov bx,word ptr [bp].reg_eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov word ptr [bp].reg_eax,bx
	ret
Em&op&WordImAcc	Endp

Em&op&DwordImAcc	Proc near
	call ReadCodeDword
	mov edx,eax
	mov ebx,[bp].reg_eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov [bp].reg_eax,ebx
	ret
Em&op&DwordImAcc	Endp

			Endm

WordImsxMem	Macro op

	public Em&op&WordImsxMem

Em&op&WordImsxMem	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordImsxMem
;
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&WordImsxMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&WordImsxMem16
	or bl,40h	
Em&op&WordImsxMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadWord
	push ax
	call ReadCodeByte
	movsx dx,al
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov ax,bx
	pop ebx
	pop si
	call WriteWord
	ret

Em&op&WordImsxMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].WordRegTab
	mov ax,[bp+si]
	push si
	push ax
	call ReadCodeByte
	movsx dx,al
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop si
	mov [bp+si],bx
	ret
Em&op&WordImsxMem	Endp

Em&op&DwordImsxMem	Proc near
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&DwordImsxMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&DwordImsxMem16
	or bl,40h	
Em&op&DwordImsxMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadDword
	push eax
	call ReadCodeByte
	movsx edx,al
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov eax,ebx
	pop ebx
	pop si
	call WriteDword
	ret

Em&op&DwordImsxMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov eax,[bp+si]
	push si
	push eax
	call ReadCodeByte
	movsx edx,al
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop si
	mov [bp+si],ebx
	ret
Em&op&DwordImsxMem	Endp

			Endm

CheckByteMemReg	Macro op

	public Em&op&ByteMemReg

Em&op&ByteMemReg	Proc near
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadByteReg
	pop bx
	push ax
	call LoadByteMemReg
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al,bl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&ByteMemReg	Endp

				Endm

CheckWordMemReg	Macro op

	public Em&op&WordMemReg

Em&op&WordMemReg	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordMemReg
;
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadWordReg
	pop bx
	push ax
	call LoadWordMemReg
	pop bx
	mov dx,ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op dx,bx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&WordMemReg	Endp

Em&op&DwordMemReg	Proc near
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadDwordReg
	pop bx
	push eax
	call LoadDwordMemReg
	pop ebx
	mov edx,eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op edx,ebx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&DwordMemReg	Endp

				Endm

CheckByteRegMem	Macro op

	public Em&op&ByteRegMem

Em&op&ByteRegMem	Proc near
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadByteReg
	pop bx
	push ax
	call LoadByteMemReg
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bl,al
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&ByteRegMem	Endp

				Endm

CheckWordRegMem	Macro op

	public Em&op&WordRegMem

Em&op&WordRegMem	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordRegMem
;
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadWordReg
	pop bx
	push ax
	call LoadWordMemReg
	pop bx
	mov dx,ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&WordRegMem	Endp

Em&op&DwordRegMem	Proc near
	call ReadCodeByte
	mov bl,al
	push bx
	call LoadDwordReg
	pop bx
	push eax
	call LoadDwordMemReg
	pop ebx
	mov edx,eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&DwordRegMem	Endp

			Endm

CheckByteImMem	Macro op

	public Em&op&ByteImMem

Em&op&ByteImMem	Proc near
	mov bl,al
	call LoadByteMemReg
	push ax
	call ReadCodeByte
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bl,al
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&ByteImMem	Endp

			Endm


CheckWordImMem	Macro op

	public Em&op&WordImMem

Em&op&WordImMem	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordImMem
;
	mov bl,al
	call LoadWordMemReg
	push ax
	call ReadCodeWord
	mov dx,ax
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&WordImMem	Endp

Em&op&DwordImMem	Proc near
	mov bl,al
	call LoadDwordMemReg
	push eax
	call ReadCodeDword
	mov edx,eax
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&DwordImMem	Endp

			Endm

CheckByteImAcc	Macro op

	public Em&op&ByteImAcc

Em&op&ByteImAcc	Proc near
	call ReadCodeByte
	mov bl,byte ptr [bp].reg_eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bl,al
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&ByteImAcc	Endp

			Endm

CheckWordImAcc	Macro op

	public Em&op&WordImAcc

Em&op&WordImAcc	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordImAcc
;
	call ReadCodeWord
	mov dx,ax
	mov bx,word ptr [bp].reg_eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&WordImAcc	Endp

Em&op&DwordImAcc	Proc near
	call ReadCodeDword
	mov edx,eax
	mov ebx,[bp].reg_eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&DwordImAcc	Endp

			Endm

CheckWordImsxMem	Macro op

	public Em&op&WordImsxMem

Em&op&WordImsxMem	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordImsxMem
;
	mov bl,al
	call LoadWordMemReg
	push ax
	call ReadCodeByte
	movsx dx,al
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&WordImsxMem	Endp

Em&op&DwordImsxMem	Proc near
	mov bl,al
	call LoadDwordMemReg
	push eax
	call ReadCodeByte
	movsx edx,al
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&DwordImsxMem	Endp

		Endm

RotateByteMem	Macro op, count

	public Em&op&ByteMem&count

Em&op&ByteMem&count	Proc near
	mov bl,al
;
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&ByteMemReg&count
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&ByteMem&count&16
	or bl,40h	
Em&op&ByteMem&count&16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadByte
	mov ah,byte ptr [bp].reg_eflags
	mov cl,byte ptr [bp].reg_ecx
	sahf
	&op al,&count
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop ebx
	pop si
	call WriteByte
	ret

Em&op&ByteMemReg&count:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].ByteRegTab
	mov ah,byte ptr [bp].reg_eflags
	mov cl,byte ptr [bp].reg_ecx
	sahf
	&op byte ptr [bp+si], &count
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&ByteMem&count	Endp
			Endm

RotateWordMem	Macro op, count

	public Em&op&WordMem&count

Em&op&WordMem&count	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordMem&count
;
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&WordMemReg&count
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&WordMem&count&16
	or bl,40h	
Em&op&WordMem&count&16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadWord
	mov bx,ax
	mov ah,byte ptr [bp].reg_eflags
	mov cl,byte ptr [bp].reg_ecx
	sahf
	&op bx,&count
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov ax,bx
	pop ebx
	pop si
	call WriteWord
	ret

Em&op&WordMemReg&count:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].WordRegTab
	mov ah,byte ptr [bp].reg_eflags
	mov cl,byte ptr [bp].reg_ecx
	sahf
	&op word ptr [bp+si], &count
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&WordMem&count	Endp

Em&op&DwordMem&count	Proc near
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&DwordMemReg&count
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&DwordMem&count&16
	or bl,40h	
Em&op&DwordMem&count&16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadDword
	mov ebx,eax
	mov ah,byte ptr [bp].reg_eflags
	mov cl,byte ptr [bp].reg_ecx
	sahf
	&op ebx,&count
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov eax,ebx
	pop ebx
	pop si
	call WriteDword
	ret

Em&op&DwordMemReg&count:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov ah,byte ptr [bp].reg_eflags
	mov cl,byte ptr [bp].reg_ecx
	sahf
	&op dword ptr [bp+si], &count
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&DwordMem&count	Endp

			Endm

RotateByteMemIm	Macro op

	public Em&op&ByteMemIm

Em&op&ByteMemIm	Proc near
	mov bl,al
;
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&ByteMemRegIm
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&ByteMemIm16
	or bl,40h	
Em&op&ByteMemIm16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadByte
	push ax
	call ReadCodeByte
	mov cl,al
	pop ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al,cl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	pop ebx
	pop si
	call WriteByte
	ret

Em&op&ByteMemRegIm:
	push bx
	call ReadCodeByte
	mov cl,al
	pop bx
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].ByteRegTab
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op byte ptr [bp+si], cl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&ByteMemIm	Endp
			Endm

RotateWordMemIm	Macro op

	public Em&op&WordMemIm

Em&op&WordMemIm	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordMemIm
;
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&WordMemRegIm
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&WordMemIm16
	or bl,40h	
Em&op&WordMemIm16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadWord
	push ax
	call ReadCodeByte
	mov cl,al
	pop bx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op bx,cl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov ax,bx
	pop ebx
	pop si
	call WriteWord
	ret

Em&op&WordMemRegIm:
	push bx
	call ReadCodeByte
	mov cl,al
	pop bx
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].WordRegTab
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op word ptr [bp+si],cl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&WordMemIm	Endp

Em&op&DwordMemIm	Proc near
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&DwordMemRegIm
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&DwordMemIm16
	or bl,40h	
Em&op&DwordMemIm16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	push si
	push ebx
	call ReadDword
	push eax
	call ReadCodeByte
	mov cl,al
	pop ebx
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ebx,cl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov eax,ebx
	pop ebx
	pop si
	call WriteDword
	ret

Em&op&DwordMemRegIm:
	push bx
	call ReadCodeByte
	mov cl,al
	pop bx
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op dword ptr [bp+si],cl
	lahf
	mov byte ptr [bp].reg_eflags,ah
	ret
Em&op&DwordMemIm	Endp

			Endm

FlagsRegOne	MACRO op, reg, name

	public Em&op&name

Em&op&name	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&E&reg
;
	mov dx,word ptr [bp].reg_e&reg
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op dx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov word ptr [bp].reg_e&reg,dx
	ret

Em&op&E&reg:
	mov edx,[bp].reg_e&reg
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op edx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov [bp].reg_e&reg,edx
	ret
Em&op&name	Endp

		Endm

FlagsReg	Macro	op

	FlagsRegOne op, ax, Ax
	FlagsRegOne op, bx, Bx
	FlagsRegOne op, cx, Cx
	FlagsRegOne op, dx, Dx
	FlagsRegOne op, sp, Sp
	FlagsRegOne op, bp, Bp
	FlagsRegOne op, si, Si
	FlagsRegOne op, di, Di

			Endm

ExtByteMem	Macro op

	public Em&op&ByteMem

Em&op&ByteMem	Proc near
	mov bl,al
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&ByteMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&ByteMem16
	or bl,40h	
Em&op&ByteMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadByte
	mov dl,al
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov al,byte ptr [bp].reg_eax
	&op dl
	mov cx,ax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov word ptr [bp].reg_eax,cx
	ret

Em&op&ByteMemReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].ByteRegTab
	mov dl,[bp+si]
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov al,byte ptr [bp].reg_eax
	&op dl
	mov cx,ax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov word ptr [bp].reg_eax,cx
	ret
Em&op&ByteMem	Endp
			Endm

ExtWordMem	Macro op

	public Em&op&WordMem

Em&op&WordMem	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordMem
;
	mov bl,al
	call LoadWordReg
	mov dx,ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov ax,word ptr [bp].reg_eax
	&op dx
	mov cx,ax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov word ptr [bp].reg_eax,cx
	mov word ptr [bp].reg_edx,dx
	ret
Em&op&WordMem	Endp

	public Em&op&WordMemReg

Em&op&WordMemReg	Proc near
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordMemReg
;
	mov bl,al
	push bx
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&WordMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&WordMemReg16
	or bl,40h	
Em&op&WordMemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadWord
	mov dx,ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov ax,word ptr [bp].reg_eax
	&op dx
	mov cx,ax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov word ptr [bp].reg_eax,cx
	mov word ptr [bp].reg_edx,dx
	ret

Em&op&WordMemRegReg:
	mov bl,al
	call LoadWordReg
	mov dx,ax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov ax,word ptr [bp].reg_eax
	&op dx
	mov cx,ax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov word ptr [bp].reg_eax,cx
	mov word ptr [bp].reg_edx,dx
	ret
Em&op&WordMemReg	Endp

Em&op&DwordMem	Proc near
	mov bl,al
	call LoadDwordReg
	mov edx,eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov eax,[bp].reg_eax
	&op edx
	mov ecx,eax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov [bp].reg_eax,ecx
	mov [bp].reg_edx,edx
	ret
Em&op&DwordMem	Endp

Em&op&DwordMemReg	Proc near
	call ReadCodeByte
	mov bl,al
	push bx
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&DwordMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&DwordMemReg16
	or bl,40h	
Em&op&DwordMemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadDword
	mov edx,eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov eax,[bp].reg_eax
	&op edx
	mov ecx,eax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov [bp].reg_eax,ecx
	mov [bp].reg_edx,edx
	ret

Em&op&DwordMemRegReg:
	mov bl,al
	call LoadDwordReg
	mov edx,eax
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov eax,[bp].reg_eax
	&op edx
	mov ecx,eax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov [bp].reg_eax,ecx
	mov [bp].reg_edx,edx
	ret
Em&op&DwordMemReg	Endp

			Endm

Adjust	Macro op

	public Em&op

Em&op	Proc near
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov ax,word ptr [bp].reg_eax
	&op
	mov cx,ax
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov word ptr [bp].reg_eax,cx
	ret
Em&op	Endp

			Endm

Setcc	Macro op

	public Em&op

Em&op	Proc near
	call ReadCodeByte
	mov bl,al
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op al
	call SaveByteMem
	ret
Em&op	Endp
			Endm

BitMemReg	Macro op

	public Em&op&MemReg

Em&op&MemReg	Proc near
	call ReadCodeByte
	mov bl,al
;
	test byte ptr [bp].em_flags,d32
	jnz Em&op&DwordMemReg

Em&op&WordMemReg:
	push bx
	call LoadWordReg
	pop bx
	movzx eax,ax
	push eax
	jmp Em&op&MemRegDo

Em&op&DwordMemReg:
	push bx
	call LoadDwordReg
	pop bx
	push eax

Em&op&MemRegDo:
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&MemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&MemReg16
	or bl,40h	
Em&op&MemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	pop eax
	mov cl,al
	and cx,7
	shr eax,3
	add ebx,eax
;
	push ebx
	push si
	push cx
	call ReadByte
	pop cx
;
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ax,cx
	lahf
	mov byte ptr [bp].reg_eflags,ah
;	
	pop si
	pop ebx
	call WriteByte
	ret

Em&op&MemRegReg:
	and bh,7
	shl bh,1
	pop ecx
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov eax,[bp+si]
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov ax,word ptr [bp].reg_eax
	&op ax,cx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov [bp+si],eax	
	ret
Em&op&MemReg	Endp

				Endm

BitImMem	Macro op

	public Em&op&ImMem

Em&op&ImMem	Proc near
	mov bl,al
	push bx
	call ReadCodeByte
	pop bx
	movzx eax,al
	push eax
;
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je Em&op&ImMemReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz Em&op&ImMem16
	or bl,40h	
Em&op&ImMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	pop eax
	mov cl,al
	and cx,7
	shr eax,3
	add ebx,eax
;
	push ebx
	push si
	push cx
	call ReadByte
	pop cx
;
	mov ah,byte ptr [bp].reg_eflags
	sahf
	&op ax,cx
	lahf
	mov byte ptr [bp].reg_eflags,ah
;	
	pop si
	pop ebx
	call WriteByte
	ret

Em&op&ImMemReg:
	and bh,7
	shl bh,1
	pop ecx
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov eax,[bp+si]
	mov ah,byte ptr [bp].reg_eflags
	sahf
	mov ax,word ptr [bp].reg_eax
	&op ax,cx
	lahf
	mov byte ptr [bp].reg_eflags,ah
	mov [bp+si],eax	
	ret
Em&op&ImMem	Endp

				Endm

code	SEGMENT byte public use16 'CODE'

	assume cs:code
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			add
;
;		DESCRIPTION:	EMULATE add
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMemReg Add
	WordMemReg Add
	ByteRegMem Add
	WordRegMem Add
	ByteImAcc Add
	WordImAcc Add
	ByteImMem Add
	WordImMem Add
	WordImsxMem Add

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			adc
;
;		DESCRIPTION:	EMULATE adc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMemReg Adc
	WordMemReg Adc
	ByteRegMem Adc
	WordRegMem Adc
	ByteImAcc Adc
	WordImAcc Adc
	ByteImMem Adc
	WordImMem Adc
	WordImsxMem Adc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			sub
;
;		DESCRIPTION:	EMULATE sub
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMemReg Sub
	WordMemReg Sub
	ByteRegMem Sub
	WordRegMem Sub
	ByteImAcc Sub
	WordImAcc Sub
	ByteImMem Sub
	WordImMem Sub
	WordImsxMem Sub

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			sbb
;
;		DESCRIPTION:	EMULATE sbb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMemReg Sbb
	WordMemReg Sbb
	ByteRegMem Sbb
	WordRegMem Sbb
	ByteImAcc Sbb
	WordImAcc Sbb
	ByteImMem Sbb
	WordImMem Sbb
	WordImsxMem Sbb

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			and
;
;		DESCRIPTION:	EMULATE and
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMemReg And
	WordMemReg And
	ByteRegMem And
	WordRegMem And
	ByteImAcc And
	WordImAcc And
	ByteImMem And
	WordImMem And
	WordImsxMem And

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			or
;
;		DESCRIPTION:	EMULATE or
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMemReg Or
	WordMemReg Or
	ByteRegMem Or
	WordRegMem Or
	ByteImAcc Or
	WordImAcc Or
	ByteImMem Or
	WordImMem Or
	WordImsxMem Or

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			xor
;
;		DESCRIPTION:	EMULATE xor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMemReg Xor
	WordMemReg Xor
	ByteRegMem Xor
	WordRegMem Xor
	ByteImAcc Xor
	WordImAcc Xor
	ByteImMem Xor
	WordImMem Xor
	WordImsxMem Xor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			cmp
;
;		DESCRIPTION:	EMULATE cmp reg,byte ptr mem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CheckByteMemReg Cmp
	CheckWordMemReg Cmp
	CheckByteRegMem Cmp
	CheckWordRegMem Cmp
	CheckByteImAcc Cmp
	CheckWordImAcc Cmp
	CheckByteImMem Cmp
	CheckWordImMem Cmp
	CheckWordImsxMem Cmp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			TestByteImMem
;
;		DESCRIPTION:	EMULATE test byte ptr mem,im
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CheckByteMemReg Test
	CheckWordMemReg Test
	CheckByteImAcc Test
	CheckWordImAcc Test
	CheckByteImMem Test
	CheckWordImMem Test
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmInc
;
;		DESCRIPTION:	EMULATE inc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	FlagsReg Inc
	ByteMem Inc
	WordMem Inc
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmDec
;
;		DESCRIPTION:	EMULATE dec
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	FlagsReg Dec
	ByteMem Dec
	WordMem Dec
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmNot
;
;		DESCRIPTION:	EMULATE not
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMem Not
	WordMem Not
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmNeg
;
;		DESCRIPTION:	EMULATE neg
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ByteMem Neg
	WordMem Neg
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmBt
;
;		DESCRIPTION:	EMULATE bt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	BitMemReg Bt
	BitImMem Bt
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmBtr
;
;		DESCRIPTION:	EMULATE btr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	BitMemReg Btr
	BitImMem Btr
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmBts
;
;		DESCRIPTION:	EMULATE bts
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	BitMemReg Bts
	BitImMem Bts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmBtc
;
;		DESCRIPTION:	EMULATE btc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	BitMemReg Btc
	BitImMem Btc
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmMul
;
;		DESCRIPTION:	EMULATE mul
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ExtByteMem Mul
	ExtWordMem Mul
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmImul
;
;		DESCRIPTION:	EMULATE imul
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ExtByteMem Imul
	ExtWordMem Imul
	WordRegMem Imul
	WordImMem Imul
	WordImsxMem Imul
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmDiv
;
;		DESCRIPTION:	EMULATE div
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ExtByteMem Div
	ExtWordMem Div
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmIdiv
;
;		DESCRIPTION:	EMULATE idiv
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ExtByteMem Idiv
	ExtWordMem Idiv
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmRol
;
;		DESCRIPTION:	EMULATE rol
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	RotateByteMem Rol, 1
	RotateByteMem Rol, Cl
	RotateByteMemIm Rol
	RotateWordMem Rol, 1
	RotateWordMem Rol, Cl
	RotateWordMemIm Rol
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmRor
;
;		DESCRIPTION:	EMULATE ror
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	RotateByteMem Ror, 1
	RotateByteMem Ror, Cl
	RotateByteMemIm Ror
	RotateWordMem Ror, 1
	RotateWordMem Ror, Cl
	RotateWordMemIm Ror
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmRcl
;
;		DESCRIPTION:	EMULATE rcl
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	RotateByteMem Rcl, 1
	RotateByteMem Rcl, Cl
	RotateByteMemIm Rcl
	RotateWordMem Rcl, 1
	RotateWordMem Rcl, Cl
	RotateWordMemIm Rcl
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmRcr
;
;		DESCRIPTION:	EMULATE rcr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	RotateByteMem Rcr, 1
	RotateByteMem Rcr, Cl
	RotateByteMemIm Rcr
	RotateWordMem Rcr, 1
	RotateWordMem Rcr, Cl
	RotateWordMemIm Rcr
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmShl
;
;		DESCRIPTION:	EMULATE shl
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	RotateByteMem Shl, 1
	RotateByteMem Shl, Cl
	RotateByteMemIm Shl
	RotateWordMem Shl, 1
	RotateWordMem Shl, Cl
	RotateWordMemIm Shl
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmShr
;
;		DESCRIPTION:	EMULATE shr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	RotateByteMem Shr, 1
	RotateByteMem Shr, Cl
	RotateByteMemIm Shr
	RotateWordMem Shr, 1
	RotateWordMem Shr, Cl
	RotateWordMemIm Shr
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmSar
;
;		DESCRIPTION:	EMULATE sar
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	RotateByteMem Sar, 1
	RotateByteMem Sar, Cl
	RotateByteMemIm Sar
	RotateWordMem Sar, 1
	RotateWordMem Sar, Cl
	RotateWordMemIm Sar
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmSetcc
;
;		DESCRIPTION:	EMULATE setcc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	Setcc Seto
	Setcc Setno
	Setcc Setb
	Setcc Setnb
	Setcc Sete
	Setcc Setne
	Setcc Setbe
	Setcc Setnbe
	Setcc Sets
	Setcc Setns
	Setcc Setp
	Setcc Setnp
	Setcc Setl
	Setcc Setnl
	Setcc Setle
	Setcc Setnle
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmAaa, Aas, Daa, Das
;
;		DESCRIPTION:	EMULATE aaa, aas, daa, das
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	Adjust Aaa
	Adjust Aas
	Adjust Daa
	Adjust Das
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCbw
;
;		DESCRIPTION:	EMULATE cbw
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmCbw

EmCbw	Proc near
	mov al,byte ptr [bp].reg_eax
	cbw
	mov word ptr [bp].reg_eax,ax
	ret
EmCbw	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmCwd, Cdq
;
;		DESCRIPTION:	EMULATE cbw, cdq
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public EmCwd

EmCwd	Proc near
	test byte ptr [bp].em_flags,d32
	jnz EmCdq
;
	mov ax,word ptr [bp].reg_eax
	cwd
	mov word ptr [bp].reg_eax,ax
	mov word ptr [bp].reg_edx,dx
	ret

EmCdq:
	mov eax,[bp].reg_eax
	cdq
	mov [bp].reg_eax,eax
	mov [bp].reg_edx,edx
	ret
EmCwd	Endp

code	ENDS

	END
