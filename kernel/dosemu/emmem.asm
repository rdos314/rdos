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
; EMMEM.ASM
; Memory address decoding for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.386p

include emulate.inc
include emcom.inc
include emseg.inc

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			segment register override tables
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SegDsTab

SegDsTab:
dst0	DW OFFSET reg_es
dst1	DW OFFSET reg_cs
dst2	DW OFFSET reg_ss
dst3	DW OFFSET reg_ds
dst4	DW OFFSET reg_fs
dst5	DW OFFSET reg_gs
dst6	DW OFFSET reg_ds
dst7	DW OFFSET reg_ds

SegSsTab:
sst0	DW OFFSET reg_es
sst1	DW OFFSET reg_cs
sst2	DW OFFSET reg_ss
sst3	DW OFFSET reg_ds
sst4	DW OFFSET reg_fs
sst5	DW OFFSET reg_gs
sst6	DW OFFSET reg_ss
sst7	DW OFFSET reg_ss

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			memory addressing procedures
;
;		RETURNS:		SI		segment
;						EBX		offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemBxSi	PROC near
	movzx ebx,word ptr [bp].reg_ebx
	add bx,word ptr [bp].reg_esi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBxSi	ENDP

MemBxDi	PROC near
	movzx ebx,word ptr [bp].reg_ebx
	add bx,word ptr [bp].reg_edi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBxDi	ENDP

MemBpSi	PROC near
	movzx ebx,word ptr [bp].reg_ebp
	add bx,word ptr [bp].reg_esi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemBpSi	ENDP

MemBpDi	PROC near
	movzx ebx,word ptr [bp].reg_ebp
	add bx,word ptr [bp].reg_edi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemBpDi	ENDP

	public MemSi

MemSi	PROC near
	movzx ebx,word ptr [bp].reg_esi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemSi	ENDP

	public MemDi

MemDi	PROC near
	movzx ebx,word ptr [bp].reg_edi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemDi	ENDP

	public MemD16

MemD16	PROC near
	call ReadCodeWord
	movzx ebx,ax
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemD16	ENDP

	public MemBx

MemBx	PROC near
	movzx ebx,word ptr [bp].reg_ebx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBx	ENDP

MemBxSiD8	PROC near
	call ReadCodeByte
	movsx bx,al
	add bx,word ptr [bp].reg_ebx
	add bx,word ptr [bp].reg_esi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBxSiD8	ENDP

MemBxDiD8	PROC near
	call ReadCodeByte
	movsx bx,al
	add bx,word ptr [bp].reg_ebx
	add bx,word ptr [bp].reg_edi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBxDiD8	ENDP

MemBpSiD8	PROC near
	call ReadCodeByte
	movsx bx,al
	add bx,word ptr [bp].reg_ebp
	add bx,word ptr [bp].reg_esi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemBpSiD8	ENDP

MemBpDiD8	PROC near
	call ReadCodeByte
	movsx bx,al
	add bx,word ptr [bp].reg_ebp
	add bx,word ptr [bp].reg_edi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemBpDiD8	ENDP

MemSiD8	PROC near
	call ReadCodeByte
	movsx bx,al
	add bx,word ptr [bp].reg_esi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemSiD8	ENDP

MemDiD8	PROC near
	call ReadCodeByte
	movsx bx,al
	add bx,word ptr [bp].reg_edi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemDiD8	ENDP

MemBpD8	PROC near
	call ReadCodeByte
	movsx bx,al
	add bx,word ptr [bp].reg_ebp
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemBpD8	ENDP

MemBxD8	PROC near
	call ReadCodeByte
	movsx bx,al
	add bx,word ptr [bp].reg_ebx
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBxD8	ENDP

MemBxSiD16	PROC near
	call ReadCodeWord
	mov bx,ax
	add bx,word ptr [bp].reg_ebx
	add bx,word ptr [bp].reg_esi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBxSiD16	ENDP

MemBxDiD16	PROC near
	call ReadCodeWord
	mov bx,ax
	add bx,word ptr [bp].reg_ebx
	add bx,word ptr [bp].reg_edi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBxDiD16	ENDP

MemBpSiD16	PROC near
	call ReadCodeWord
	mov bx,ax
	add bx,word ptr [bp].reg_ebp
	add bx,word ptr [bp].reg_esi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemBpSiD16	ENDP

MemBpDiD16	PROC near
	call ReadCodeWord
	mov bx,ax
	add bx,word ptr [bp].reg_ebp
	add bx,word ptr [bp].reg_edi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemBpDiD16	ENDP

MemSiD16	PROC near
	call ReadCodeWord
	mov bx,ax
	add bx,word ptr [bp].reg_esi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemSiD16	ENDP

MemDiD16	PROC near
	call ReadCodeWord
	mov bx,ax
	add bx,word ptr [bp].reg_edi
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemDiD16	ENDP

MemBpD16	PROC near
	call ReadCodeWord
	mov bx,ax
	add bx,word ptr [bp].reg_ebp
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemBpD16	ENDP

MemBxD16	PROC near
	call ReadCodeWord
	mov bx,ax
	add bx,word ptr [bp].reg_ebx
	movzx ebx,bx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemBxD16	ENDP

MemEax	PROC near
	mov ebx,[bp].reg_eax
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEax	ENDP

MemEcx	PROC near
	mov ebx,[bp].reg_ecx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEcx	ENDP

MemEdx	PROC near
	mov ebx,[bp].reg_edx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEdx	ENDP

	public MemEbx

MemEbx	PROC near
	mov ebx,[bp].reg_ebx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEbx	ENDP

	public MemD32

MemD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemD32	ENDP

	public MemEsi

MemEsi	PROC near
	mov ebx,[bp].reg_esi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEsi	ENDP

	public MemEdi

MemEdi	PROC near
	mov ebx,[bp].reg_edi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEdi	ENDP

MemEsp	PROC near
	mov ebx,[bp].reg_esp
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemEsp	ENDP

MemEaxD8	PROC near
	call ReadCodeByte
	movsx ebx,al
	add ebx,[bp].reg_eax
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEaxD8	ENDP

MemEcxD8	PROC near
	call ReadCodeByte
	movsx ebx,al
	add ebx,[bp].reg_ecx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEcxD8	ENDP

MemEdxD8	PROC near
	call ReadCodeByte
	movsx ebx,al
	add ebx,[bp].reg_edx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEdxD8	ENDP

MemEbxD8	PROC near
	call ReadCodeByte
	movsx ebx,al
	add ebx,[bp].reg_ebx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEbxD8	ENDP

MemEbpD8	PROC near
	call ReadCodeByte
	movsx ebx,al
	add ebx,[bp].reg_ebp
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemEbpD8	ENDP

MemEsiD8	PROC near
	call ReadCodeByte
	movsx ebx,al
	add ebx,[bp].reg_esi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEsiD8	ENDP

MemEdiD8	PROC near
	call ReadCodeByte
	movsx ebx,al
	add ebx,[bp].reg_edi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEdiD8	ENDP

MemEspD8	PROC near
	call ReadCodeByte
	movsx ebx,al
	add ebx,[bp].reg_esp
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemEspD8	ENDP

MemEaxD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	add ebx,[bp].reg_eax
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEaxD32	ENDP

MemEcxD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	add ebx,[bp].reg_ecx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEcxD32	ENDP

MemEdxD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	add ebx,[bp].reg_edx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEdxD32	ENDP

MemEbxD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	add ebx,[bp].reg_ebx
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEbxD32	ENDP

MemEbpD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	add ebx,[bp].reg_ebp
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemEbpD32	ENDP

MemEsiD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	add ebx,[bp].reg_esi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEsiD32	ENDP

MemEdiD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	add ebx,[bp].reg_edi
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegDsTab
	ret
MemEdiD32	ENDP

MemEspD32	PROC near
	call ReadCodeDword
	mov ebx,eax
	add ebx,[bp].reg_esp
	movzx si,byte ptr [bp].em_sreg
	add si,si
	mov si,word ptr cs:[si].SegSsTab
	ret
MemEspD32	ENDP

SibIndexTab:
sit000	DW OFFSET reg_eax
sit001	DW OFFSET reg_ecx
sit010	DW OFFSET reg_edx
sit011	DW OFFSET reg_ebx
sit100	DW 0
sit101	DW OFFSET reg_ebp
sit110	DW OFFSET reg_esi
sit111	DW OFFSET reg_edi

Sib0Tab:
sib0_000	DW OFFSET MemEax
sib0_001	DW OFFSET MemEcx
sib0_010	DW OFFSET MemEdx
sib0_011	DW OFFSET MemEbx
sib0_100	DW OFFSET MemEsp
sib0_101	DW OFFSET MemD32
sib0_110	DW OFFSET MemEsi
sib0_111	DW OFFSET MemEdi

Sib1Tab:
sib1_000	DW OFFSET MemEaxD8
sib1_001	DW OFFSET MemEcxD8
sib1_010	DW OFFSET MemEdxD8
sib1_011	DW OFFSET MemEbxD8
sib1_100	DW OFFSET MemEspD8
sib1_101	DW OFFSET MemEbpD8
sib1_110	DW OFFSET MemEsiD8
sib1_111	DW OFFSET MemEdiD8

Sib2Tab:
sib2_000	DW OFFSET MemEaxD32
sib2_001	DW OFFSET MemEcxD32
sib2_010	DW OFFSET MemEdxD32
sib2_011	DW OFFSET MemEbxD32
sib2_100	DW OFFSET MemEspD32
sib2_101	DW OFFSET MemEbpD32
sib2_110	DW OFFSET MemEsiD32
sib2_111	DW OFFSET MemEdiD32
 
MemSib0	PROC near
	call ReadCodeByte
	push ax
	movzx bx,al
	and bl,7
	shl bx,1
	call word ptr cs:[bx].Sib0Tab
	pop ax
	mov cl,al
	shr cl,6
	and cl,3
	mov di,ax
	shr di,2
	and di,0Eh
	mov di,word ptr cs:[di].SibIndexTab
	or di,di
	jz MemSib0Done
;
	mov eax,[bp+di]
	shl eax,cl
	add ebx,eax

MemSib0Done:
	ret

MemSib0	ENDP
 
MemSib1	PROC near
	call ReadCodeByte
	push ax
	movzx bx,al
	and bl,7
	shl bx,1
	call word ptr cs:[bx].Sib1Tab
	pop ax
	mov cl,al
	shr cl,6
	and cl,3
	mov di,ax
	shr di,2
	and di,0Eh
	mov di,word ptr cs:[di].SibIndexTab
	or di,di
	jz MemSib1Done
;
	mov eax,[bp+di]
	shl eax,cl
	add ebx,eax

MemSib1Done:
	ret
MemSib1	ENDP

MemSib2	PROC near
	call ReadCodeByte
	push ax
	movzx bx,al
	and bl,7
	shl bx,1
	call word ptr cs:[bx].Sib2Tab
	pop ax
	mov cl,al
	shr cl,6
	and cl,3
	mov di,ax
	shr di,2
	and di,0Eh
	mov di,word ptr cs:[di].SibIndexTab
	or di,di
	jz MemSib2Done
;
	mov eax,[bp+di]
	shl eax,cl
	add ebx,eax

MemSib2Done:
	ret
MemSib2	ENDP

	public MemTab

MemTab:
mem16_00000	DW OFFSET MemBxSi
mem16_00001	DW OFFSET MemBxDi
mem16_00010	DW OFFSET MemBpSi
mem16_00011	DW OFFSET MemBpDi
mem16_00100	DW OFFSET MemSi
mem16_00101	DW OFFSET MemDi
mem16_00110	DW OFFSET MemD16
mem16_00111	DW OFFSET MemBx
mem16_01000	DW OFFSET MemBxSiD8
mem16_01001	DW OFFSET MemBxDiD8
mem16_01010	DW OFFSET MemBpSiD8
mem16_01011	DW OFFSET MemBpDiD8
mem16_01100	DW OFFSET MemSiD8
mem16_01101	DW OFFSET MemDiD8
mem16_01110	DW OFFSET MemBpD8
mem16_01111	DW OFFSET MemBxD8
mem16_10000	DW OFFSET MemBxSiD16
mem16_10001	DW OFFSET MemBxDiD16
mem16_10010	DW OFFSET MemBpSiD16
mem16_10011	DW OFFSET MemBpDiD16
mem16_10100	DW OFFSET MemSiD16
mem16_10101	DW OFFSET MemDiD16
mem16_10110	DW OFFSET MemBpD16
mem16_10111	DW OFFSET MemBxD16
mem16_11000	DW OFFSET EmulateError
mem16_11001	DW OFFSET EmulateError
mem16_11010	DW OFFSET EmulateError
mem16_11011	DW OFFSET EmulateError
mem16_11100	DW OFFSET EmulateError
mem16_11101	DW OFFSET EmulateError
mem16_11110	DW OFFSET EmulateError
mem16_11111	DW OFFSET EmulateError
;
mem32_00000	DW OFFSET MemEax
mem32_00001	DW OFFSET MemEcx
mem32_00010	DW OFFSET MemEdx
mem32_00011	DW OFFSET MemEbx
mem32_00100	DW OFFSET MemSib0
mem32_00101	DW OFFSET MemD32
mem32_00110	DW OFFSET MemEsi
mem32_00111	DW OFFSET MemEdi
mem32_01000	DW OFFSET MemEaxD8
mem32_01001	DW OFFSET MemEcxD8
mem32_01010	DW OFFSET MemEdxD8
mem32_01011	DW OFFSET MemEbxD8
mem32_01100	DW OFFSET MemSib1
mem32_01101	DW OFFSET MemEbpD8
mem32_01110	DW OFFSET MemEsiD8
mem32_01111	DW OFFSET MemEdiD8
mem32_10000	DW OFFSET MemEaxD32
mem32_10001	DW OFFSET MemEcxD32
mem32_10010	DW OFFSET MemEdxD32
mem32_10011	DW OFFSET MemEbxD32
mem32_10100	DW OFFSET MemSib2
mem32_10101	DW OFFSET MemEbpD32
mem32_10110	DW OFFSET MemEsiD32
mem32_10111	DW OFFSET MemEdiD32
mem32_11000	DW OFFSET EmulateError
mem32_11001	DW OFFSET EmulateError
mem32_11010	DW OFFSET EmulateError
mem32_11011	DW OFFSET EmulateError
mem32_11100	DW OFFSET EmulateError
mem32_11101	DW OFFSET EmulateError
mem32_11110	DW OFFSET EmulateError
mem32_11111	DW OFFSET EmulateError

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			register load/save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ByteRegTab

ByteRegTab:
regs_11000	DW OFFSET reg_eax
regs_11001	DW OFFSET reg_ecx
regs_11010	DW OFFSET reg_edx
regs_11011	DW OFFSET reg_ebx
regs_11100	DW OFFSET reg_eax+1
regs_11101	DW OFFSET reg_ecx+1
regs_11110	DW OFFSET reg_edx+1
regs_11111	DW OFFSET reg_ebx+1

	public WordRegTab
	public DwordRegTab

WordRegTab:
DwordRegTab:
regl_11000	DW OFFSET reg_eax
regl_11001	DW OFFSET reg_ecx
regl_11010	DW OFFSET reg_edx
regl_11011	DW OFFSET reg_ebx
regl_11100	DW OFFSET reg_esp
regl_11101	DW OFFSET reg_ebp
regl_11110	DW OFFSET reg_esi
regl_11111	DW OFFSET reg_edi

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadByteMemReg
;
;		DESCRIPTION:	Load byte from memory / reg
;
;		PARAMETERS:		BL		op-code
;
;		RETURNS:		AL		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadByteMemReg

LoadByteMemReg	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je LoadByteMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadByteMemReg16
	or bl,40h	
LoadByteMemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadByte
	ret

LoadByteMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].ByteRegTab
	mov al,[bp+si]
	ret
LoadByteMemReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadWordMemReg
;
;		DESCRIPTION:	Load word from memory / reg
;
;		PARAMETERS:		BL		op code
;
;		RETURNS:		AX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadWordMemReg

LoadWordMemReg	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je LoadWordMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadWordMemReg16
	or bl,40h	
LoadWordMemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadWord
	ret

LoadWordMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].WordRegTab
	mov ax,[bp+si]
	ret
LoadWordMemReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadDwordMemReg
;
;		DESCRIPTION:	Load dword from memory / reg
;
;		PARAMETERS:		BL		op-code
;
;		RETURNS:		EAX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadDwordMemReg

LoadDwordMemReg	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je LoadDwordMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadDwordMemReg16
	or bl,40h	
LoadDwordMemReg16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadDword
	ret

LoadDwordMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov eax,[bp+si]
	ret
LoadDwordMemReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveByteMemReg
;
;		DESCRIPTION:	Save byte to memory / reg
;
;		PARAMETERS:		AL		data to save
;						BL		op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveByteMemReg

SaveByteMemReg	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je SaveByteMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveByteMemReg16
	or bl,40h	
SaveByteMemReg16:
	xor bh,bh
	push ax
	call word ptr cs:[bx].MemTab
	pop ax
	call WriteByte
	ret

SaveByteMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].ByteRegTab
	mov [bp+si],al
	ret
SaveByteMemReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveWordMemReg
;
;		DESCRIPTION:	Save word to memory / reg
;
;		PARAMETERS:		AX		data to save
;						BL		op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveWordMemReg

SaveWordMemReg	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je SaveWordMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveWordMemReg16
	or bl,40h	
SaveWordMemReg16:
	xor bh,bh
	push ax
	call word ptr cs:[bx].MemTab
	pop ax
	call WriteWord
	ret

SaveWordMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].WordRegTab
	mov [bp+si],ax
	ret
SaveWordMemReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveDwordMemReg
;
;		DESCRIPTION:	Save dword to memory / reg
;
;		PARAMETERS:		EAX		data to save
;						BL		op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveDwordMemReg

SaveDwordMemReg	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je SaveDwordMemRegReg
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveDwordMemReg16
	or bl,40h	
SaveDwordMemReg16:
	xor bh,bh
	push eax
	call word ptr cs:[bx].MemTab
	pop eax
	call WriteDword
	ret

SaveDwordMemRegReg:
	and bh,7
	shl bh,1
	movzx si,bh
	mov si,word ptr cs:[si].DwordRegTab
	mov [bp+si],eax
	ret
SaveDwordMemReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadByteMem
;
;		DESCRIPTION:	Load byte from memory
;
;		PARAMETER:		BL		op-code
;
;		RETURNS:		AL		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadByteMem

LoadByteMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadByteMem16
	or bl,40h	
LoadByteMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadByte
	ret
LoadByteMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadWordMem
;
;		DESCRIPTION:	Load word from memory
;
;		PARAMETERS:		BL		op-code
;
;		RETURNS:		AX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadWordMem

LoadWordMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadWordMem16
	or bl,40h	
LoadWordMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadWord
	ret
LoadWordMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadDwordMem
;
;		DESCRIPTION:	Load dword from memory
;
;		PARAMETERS:		BL		op-code
;
;		RETURNS:		EAX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadDwordMem

LoadDwordMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadDwordMem16
	or bl,40h	
LoadDwordMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadDword
	ret
LoadDwordMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadFwordMem
;
;		DESCRIPTION:	Load fword from memory
;
;		PARAMETERS:		BL			op-code
;
;		RETURNS:		DX:EAX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadFwordMem

LoadFwordMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadFwordMem16
	or bl,40h	
LoadFwordMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadFword
	ret
LoadFwordMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadQwordMem
;
;		DESCRIPTION:	Load qword from memory
;
;		PARAMETERS:		BL			op-code
;
;		RETURNS:		EDX:EAX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadQwordMem

LoadQwordMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadQwordMem16
	or bl,40h	
LoadQwordMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadQword
	ret
LoadQwordMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadTbyteMem
;
;		DESCRIPTION:	Load tbyte from memory
;
;		PARAMETERS:		BL				op-code
;
;		RETURNS:		CX:EDX:EAX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadTbyteMem

LoadTbyteMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz LoadTbyteMem16
	or bl,40h	
LoadTbyteMem16:
	xor bh,bh
	call word ptr cs:[bx].MemTab
	call ReadTbyte
	ret
LoadTbyteMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveByteMem
;
;		DESCRIPTION:	Save byte to memory
;
;		PARAMETERS:		AL		data to save
;						BL		op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveByteMem

SaveByteMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveByteMem16
	or bl,40h	
SaveByteMem16:
	xor bh,bh
	push ax
	call word ptr cs:[bx].MemTab
	pop ax
	call WriteByte
	ret
SaveByteMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveWordMem
;
;		DESCRIPTION:	Save word to memory
;
;		PARAMETERS:		AX		data to save
;						BL		op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveWordMem

SaveWordMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveWordMem16
	or bl,40h	
SaveWordMem16:
	xor bh,bh
	push ax
	call word ptr cs:[bx].MemTab
	pop ax
	call WriteWord
	ret
SaveWordMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveDwordMem
;
;		DESCRIPTION:	Save dword to memory
;
;		PARAMETERS:		EAX		data to save
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveDwordMem

SaveDwordMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveDwordMem16
	or bl,40h	
SaveDwordMem16:
	xor bh,bh
	push eax
	call word ptr cs:[bx].MemTab
	pop eax
	call WriteDword
	ret
SaveDwordMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveFwordMem
;
;		DESCRIPTION:	Save fword to memory
;
;		PARAMETERS:		DX:EAX		data to save
;						BL			op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveFwordMem

SaveFwordMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveFwordMem16
	or bl,40h	
SaveFwordMem16:
	xor bh,bh
	push eax
	push dx
	call word ptr cs:[bx].MemTab
	pop dx
	pop eax
	call WriteFword
	ret
SaveFwordMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveQwordMem
;
;		DESCRIPTION:	Save qword to memory
;
;		PARAMETERS:		EDX:EAX		data to save
;						BL			op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveQwordMem

SaveQwordMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveQwordMem16
	or bl,40h	
SaveQwordMem16:
	xor bh,bh
	push eax
	push edx
	call word ptr cs:[bx].MemTab
	pop edx
	pop eax
	call WriteQword
	ret
SaveQwordMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveTbyteMem
;
;		DESCRIPTION:	Save tbyte to memory
;
;		PARAMETERS:		CX:EDX:EAX		data to save
;						BL				op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveTbyteMem

SaveTbyteMem	Proc near
	mov bh,bl
	and bl,0C0h
	cmp bl,0C0h
	je EmulateError
;
	shr bl,2
	and bh,7
	shl bh,1
	or bl,bh
	test byte ptr [bp].em_flags,a32
	jz SaveTbyteMem16
	or bl,40h	
SaveTbyteMem16:
	xor bh,bh
	push eax
	push edx
	push cx
	call word ptr cs:[bx].MemTab
	pop cx
	pop edx
	pop eax
	call WriteTbyte
	ret
SaveTbyteMem	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadByteReg
;
;		DESCRIPTION:	Load byte from reg
;
;		PARAMETERS:		BL		op-code
;
;		RETURNS:		AL		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadByteReg

LoadByteReg	Proc near
	shr bl,2
	and bl,0Eh
	movzx si,bl
	mov si,word ptr cs:[si].ByteRegTab
	mov al,[bp+si]
	ret
LoadByteReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadWordReg
;
;		DESCRIPTION:	Load word from reg
;
;		PARAMETERS:		BL		op code
;
;		RETURNS:		AX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadWordReg

LoadWordReg	Proc near
	shr bl,2
	and bl,0Eh
	movzx si,bl
	mov si,word ptr cs:[si].WordRegTab
	mov ax,[bp+si]
	ret
LoadWordReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadDwordReg
;
;		DESCRIPTION:	Load dword from reg
;
;		PARAMETERS:		BL		op-code
;
;		RETURNS:		EAX		data read
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public LoadDwordReg

LoadDwordReg	Proc near
	shr bl,2
	and bl,0Eh
	movzx si,bl
	mov si,word ptr cs:[si].DwordRegTab
	mov eax,[bp+si]
	ret
LoadDwordReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveByteReg
;
;		DESCRIPTION:	Save byte to reg
;
;		PARAMETERS:		AL		data to save
;						BL		op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveByteReg

SaveByteReg	Proc near
	shr bl,2
	and bl,0Eh
	movzx si,bl
	mov si,word ptr cs:[si].ByteRegTab
	mov [bp+si],al
	ret
SaveByteReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveWordReg
;
;		DESCRIPTION:	Save word to reg
;
;		PARAMETERS:		AX		data to save
;						BL		op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveWordReg

SaveWordReg	Proc near
	shr bl,2
	and bl,0Eh
	movzx si,bl
	mov si,word ptr cs:[si].WordRegTab
	mov [bp+si],ax
	ret
SaveWordReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveDwordReg
;
;		DESCRIPTION:	Save dword to reg
;
;		PARAMETERS:		EAX		data to save
;						BL		op-code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SaveDwordReg

SaveDwordReg	Proc near
	shr bl,2
	and bl,0Eh
	movzx si,bl
	mov si,word ptr cs:[si].DwordRegTab
	mov [bp+si],eax
	ret
SaveDwordReg	Endp

code	ENDS

	END
