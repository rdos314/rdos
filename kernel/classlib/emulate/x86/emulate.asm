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
; EMULATE.ASM
; Main emulator module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat

	NAME emulate

include ..\core\emulate.inc
include ..\core\emcom.inc
include ..\core\emseg.inc
include ..\core\emarithm.inc
include ..\core\emtrans.inc
include ..\core\emcontr.inc
include ..\core\emstring.inc
include ..\core\emprot.inc
include ..\core\em387.inc

.code

   extrn setvalue:near
   extrn GetIntVector:near
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmNop
;
;		DESCRIPTION:	nop
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmNop	Proc near
	ret
EmNop	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmHlt
;
;		DESCRIPTION:	hlt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmHlt	Proc near
	mov eax,[ebp].org_eip
	mov [ebp].reg_eip,eax
	mov eax,[ebp].org_esp
	mov [ebp].reg_esp,eax
	mov eax,[ebp].org_stack
	mov esp,eax
	ret
EmHlt	Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOverrideData
;
;		DESCRIPTION:	change size of data between 16 & 32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideData:
	xor byte ptr [ebp].em_flags,d32
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOverrideAdr
;
;		DESCRIPTION:	change size of address between 16 & 32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideAdr:
	xor byte ptr [ebp].em_flags,a32
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOverrideCs
;
;		DESCRIPTION:	Use cs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideCs:
	mov byte ptr [ebp].em_sreg,seg_cs
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOverrideSS
;
;		DESCRIPTION:	Use ss for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideSs:
	mov byte ptr [ebp].em_sreg,seg_ss
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOverrideDS
;
;		DESCRIPTION:	Use ds for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideDs:
	mov byte ptr [ebp].em_sreg,seg_ds
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOverrideES
;
;		DESCRIPTION:	Use es for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideEs:
	mov byte ptr [ebp].em_sreg,seg_es
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOverrideFS
;
;		DESCRIPTION:	Use fs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideFs:
	mov byte ptr [ebp].em_sreg,seg_fs
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmOverrideGS
;
;		DESCRIPTION:	Use gs for addressing
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmOverrideGs:
	mov byte ptr [ebp].em_sreg,seg_gs
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmREPE
;
;		DESCRIPTION:	EMULATE repe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmRepe:
	or byte ptr [ebp].em_flags,rep_z
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmREPNE
;
;		DESCRIPTION:	EMULATE repne
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmRepne:
	or byte ptr [ebp].em_flags,rep_nz
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].EmulateTab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM0F00
;
;		DESCRIPTION:	EMULATE 0F00 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0F00Tab:
em0F00_000	DD OFFSET EmSldtMem
em0F00_001	DD OFFSET EmStrMem
em0F00_010	DD OFFSET EmLldtMem
em0F00_011	DD OFFSET EmLtrMem
em0F00_100	DD OFFSET EmVerrMem
em0F00_101	DD OFFSET EmVerwMem
em0F00_110	DD OFFSET EmulateError
em0F00_111	DD OFFSET EmulateError

Em0F00:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].Em0F00Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM0F01
;
;		DESCRIPTION:	EMULATE 0F01 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0F01Tab:
em0F01_000	DD OFFSET EmSgdtMem
em0F01_001	DD OFFSET EmSidtMem
em0F01_010	DD OFFSET EmLgdtMem
em0F01_011	DD OFFSET EmLidtMem
em0F01_100	DD OFFSET EmSmswMem
em0F01_101	DD OFFSET EmulateError
em0F01_110	DD OFFSET EmLmswMem
em0F01_111	DD OFFSET EmulateError

Em0F01:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].Em0F01Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM0FBA
;
;		DESCRIPTION:	EMULATE 0FBA instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0FBATab:
em0FBA_000	DD OFFSET EmulateError
em0FBA_001	DD OFFSET EmulateError
em0FBA_010	DD OFFSET EmulateError
em0FBA_011	DD OFFSET EmulateError
em0FBA_100	DD OFFSET EmBtImMem
em0FBA_101	DD OFFSET EmBtsImMem
em0FBA_110	DD OFFSET EmBtrImMem
em0FBA_111	DD OFFSET EmBtcImMem

Em0FBA:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].Em0FBATab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM0F
;
;		DESCRIPTION:	EMULATE 0F instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em0FTab:
em0F00	DD OFFSET Em0F00,				OFFSET Em0F01
em0F02	DD OFFSET EmLarRegMem,			OFFSET EmLslRegMem
em0F04	DD OFFSET EmulateError,			OFFSET EmulateError
em0F06	DD OFFSET EmulateError,			OFFSET EmulateError
em0F08	DD OFFSET EmulateError,			OFFSET EmNop
em0F0A	DD OFFSET EmulateError,			OFFSET OpcodeFault
em0F0C	DD OFFSET EmulateError,			OFFSET EmulateError
em0F0E	DD OFFSET EmulateError,			OFFSET EmulateError
em0F10	DD OFFSET EmulateError,			OFFSET EmulateError
em0F12	DD OFFSET EmulateError,			OFFSET EmulateError
em0F14	DD OFFSET EmulateError,			OFFSET EmulateError
em0F16	DD OFFSET EmulateError,			OFFSET EmulateError
em0F18	DD OFFSET EmulateError,			OFFSET EmulateError
em0F1A	DD OFFSET EmulateError,			OFFSET EmulateError
em0F1C	DD OFFSET EmulateError,			OFFSET EmulateError
em0F1E	DD OFFSET EmulateError,			OFFSET EmulateError
em0F20	DD OFFSET EmMoveRegCr,			OFFSET EmMoveRegDr
em0F22	DD OFFSET EmMoveCrReg,			OFFSET EmMoveDrReg
em0F24	DD OFFSET EmulateError,			OFFSET EmulateError
em0F26	DD OFFSET EmulateError,			OFFSET EmulateError
em0F28	DD OFFSET EmulateError,			OFFSET EmulateError
em0F2A	DD OFFSET EmulateError,			OFFSET EmulateError
em0F2C	DD OFFSET EmulateError,			OFFSET EmulateError
em0F2E	DD OFFSET EmulateError,			OFFSET EmulateError
em0F30	DD OFFSET EmulateError,			OFFSET EmulateError
em0F32	DD OFFSET EmulateError,			OFFSET EmulateError
em0F34	DD OFFSET EmulateError,			OFFSET EmulateError
em0F36	DD OFFSET EmulateError,			OFFSET EmulateError
em0F38	DD OFFSET EmulateError,			OFFSET EmulateError
em0F3A	DD OFFSET EmulateError,			OFFSET EmulateError
em0F3C	DD OFFSET EmulateError,			OFFSET EmulateError
em0F3E	DD OFFSET EmulateError,			OFFSET EmulateError
em0F40	DD OFFSET EmulateError,			OFFSET EmulateError
em0F42	DD OFFSET EmulateError,			OFFSET EmulateError
em0F44	DD OFFSET EmulateError,			OFFSET EmulateError
em0F46	DD OFFSET EmulateError,			OFFSET EmulateError
em0F48	DD OFFSET EmulateError,			OFFSET EmulateError
em0F4A	DD OFFSET EmulateError,			OFFSET EmulateError
em0F4C	DD OFFSET EmulateError,			OFFSET EmulateError
em0F4E	DD OFFSET EmulateError,			OFFSET EmulateError
em0F50	DD OFFSET EmulateError,			OFFSET EmulateError
em0F52	DD OFFSET EmulateError,			OFFSET EmulateError
em0F54	DD OFFSET EmulateError,			OFFSET EmulateError
em0F56	DD OFFSET EmulateError,			OFFSET EmulateError
em0F58	DD OFFSET EmulateError,			OFFSET EmulateError
em0F5A	DD OFFSET EmulateError,			OFFSET EmulateError
em0F5C	DD OFFSET EmulateError,			OFFSET EmulateError
em0F5E	DD OFFSET EmulateError,			OFFSET EmulateError
em0F60	DD OFFSET EmulateError,			OFFSET EmulateError
em0F62	DD OFFSET EmulateError,			OFFSET EmulateError
em0F64	DD OFFSET EmulateError,			OFFSET EmulateError
em0F66	DD OFFSET EmulateError,			OFFSET EmulateError
em0F68	DD OFFSET EmulateError,			OFFSET EmulateError
em0F6A	DD OFFSET EmulateError,			OFFSET EmulateError
em0F6C	DD OFFSET EmulateError,			OFFSET EmulateError
em0F6E	DD OFFSET EmulateError,			OFFSET EmulateError
em0F70	DD OFFSET EmulateError,			OFFSET EmulateError
em0F72	DD OFFSET EmulateError,			OFFSET EmulateError
em0F74	DD OFFSET EmulateError,			OFFSET EmulateError
em0F76	DD OFFSET EmulateError,			OFFSET EmulateError
em0F78	DD OFFSET EmulateError,			OFFSET EmulateError
em0F7A	DD OFFSET EmulateError,			OFFSET EmulateError
em0F7C	DD OFFSET EmulateError,			OFFSET EmulateError
em0F7E	DD OFFSET EmulateError,			OFFSET EmulateError
em0F80	DD OFFSET EmJoNear,				OFFSET EmJnoNear
em0F82	DD OFFSET EmJbNear,				OFFSET EmJnbNear
em0F84	DD OFFSET EmJeNear,				OFFSET EmJneNear
em0F86	DD OFFSET EmJbeNear,			OFFSET EmJnbeNear
em0F88	DD OFFSET EmJsNear,				OFFSET EmJnsNear
em0F8A	DD OFFSET EmJpNear,				OFFSET EmJnpNear
em0F8C	DD OFFSET EmJlNear,				OFFSET EmJnlNear
em0F8E	DD OFFSET EmJleNear,			OFFSET EmJnleNear
em0F90	DD OFFSET EmSeto,				OFFSET EmSetno
em0F92	DD OFFSET EmSetb,				OFFSET EmSetnb
em0F94	DD OFFSET EmSete,				OFFSET EmSetne
em0F96	DD OFFSET EmSetbe,				OFFSET EmSetnbe
em0F98	DD OFFSET EmSets,				OFFSET EmSetns
em0F9A	DD OFFSET EmSetp,				OFFSET EmSetnp
em0F9C	DD OFFSET EmSetl,				OFFSET EmSetnl
em0F9E	DD OFFSET EmSetle,				OFFSET EmSetnle
em0FA0	DD OFFSET EmPushFs,				OFFSET EmPopFs
em0FA2	DD OFFSET OpcodeFault,			OFFSET EmBtMemReg
em0FA4	DD OFFSET EmulateError,			OFFSET EmulateError
em0FA6	DD OFFSET EmulateError,			OFFSET EmulateError
em0FA8	DD OFFSET EmPushGs,				OFFSET EmPopGs
em0FAA	DD OFFSET EmulateError,			OFFSET EmBtsMemReg
em0FAC	DD OFFSET EmulateError,			OFFSET EmulateError
em0FAE	DD OFFSET EmulateError,			OFFSET EmImulWordRegMem
em0FB0	DD OFFSET EmulateError,			OFFSET EmulateError
em0FB2	DD OFFSET EmLss,				OFFSET EmBtrMemReg
em0FB4	DD OFFSET EmLfs,				OFFSET EmLgs
em0FB6	DD OFFSET EmMovzxByteMem,		OFFSET EmMovzxWordMem
em0FB8	DD OFFSET EmulateError,			OFFSET EmulateError
em0FBA	DD OFFSET Em0FBA,				OFFSET EmBtcMemReg
em0FBC	DD OFFSET EmBsf,    			OFFSET EmBsr
em0FBE	DD OFFSET EmMovsxByteMem,		OFFSET EmMovsxWordMem
em0FC0	DD OFFSET EmulateError,			OFFSET EmulateError
em0FC2	DD OFFSET EmulateError,			OFFSET EmulateError
em0FC4	DD OFFSET EmulateError,			OFFSET EmulateError
em0FC6	DD OFFSET EmulateError,			OFFSET EmulateError
em0FC8	DD OFFSET EmBswap,				OFFSET EmBswap
em0FCA	DD OFFSET EmBswap,				OFFSET EmBswap
em0FCC	DD OFFSET EmBswap,				OFFSET EmBswap
em0FCE	DD OFFSET EmBswap,				OFFSET EmBswap
em0FD0	DD OFFSET EmulateError,			OFFSET EmulateError
em0FD2	DD OFFSET EmulateError,			OFFSET EmulateError
em0FD4	DD OFFSET EmulateError,			OFFSET EmulateError
em0FD6	DD OFFSET EmulateError,			OFFSET EmulateError
em0FD8	DD OFFSET EmulateError,			OFFSET EmulateError
em0FDA	DD OFFSET EmulateError,			OFFSET EmulateError
em0FDC	DD OFFSET EmulateError,			OFFSET EmulateError
em0FDE	DD OFFSET EmulateError,			OFFSET EmulateError
em0FE0	DD OFFSET EmulateError,			OFFSET EmulateError
em0FE2	DD OFFSET EmulateError,			OFFSET EmulateError
em0FE4	DD OFFSET EmulateError,			OFFSET EmulateError
em0FE6	DD OFFSET EmulateError,			OFFSET EmulateError
em0FE8	DD OFFSET EmulateError,			OFFSET EmulateError
em0FEA	DD OFFSET EmulateError,			OFFSET EmulateError
em0FEC	DD OFFSET EmulateError,			OFFSET EmulateError
em0FEE	DD OFFSET EmulateError,			OFFSET EmulateError
em0FF0	DD OFFSET EmulateError,			OFFSET EmulateError
em0FF2	DD OFFSET EmulateError,			OFFSET EmulateError
em0FF4	DD OFFSET EmulateError,			OFFSET EmulateError
em0FF6	DD OFFSET EmulateError,			OFFSET EmulateError
em0FF8	DD OFFSET EmulateError,			OFFSET EmulateError
em0FFA	DD OFFSET EmulateError,			OFFSET EmulateError
em0FFC	DD OFFSET EmulateError,			OFFSET EmulateError
em0FFE	DD OFFSET EmulateError,			OFFSET EmulateError

Em0F:
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	jmp dword ptr [ebx].Em0FTab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM80
;
;		DESCRIPTION:	EMULATE 80 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em80Tab:
em80_000	DD OFFSET EmAddByteImMem
em80_001	DD OFFSET EmOrByteImMem
em80_010	DD OFFSET EmAdcByteImMem
em80_011	DD OFFSET EmSbbByteImMem
em80_100	DD OFFSET EmAndByteImMem
em80_101	DD OFFSET EmSubByteImMem
em80_110	DD OFFSET EmXorByteImMem
em80_111	DD OFFSET EmCmpByteImMem

Em80:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].Em80Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM81
;
;		DESCRIPTION:	EMULATE 81 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em81Tab:
em81_000	DD OFFSET EmAddWordImMem
em81_001	DD OFFSET EmOrWordImMem
em81_010	DD OFFSET EmAdcWordImMem
em81_011	DD OFFSET EmSbbWordImMem
em81_100	DD OFFSET EmAndWordImMem
em81_101	DD OFFSET EmSubWordImMem
em81_110	DD OFFSET EmXorWordImMem
em81_111	DD OFFSET EmCmpWordImMem

Em81:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].Em81Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM82
;
;		DESCRIPTION:	EMULATE 82 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em82Tab:
em82_000	DD OFFSET EmAddByteImMem
em82_001	DD OFFSET EmOrByteImMem
em82_010	DD OFFSET EmAdcByteImMem
em82_011	DD OFFSET EmSbbByteImMem
em82_100	DD OFFSET EmAndByteImMem
em82_101	DD OFFSET EmSubByteImMem
em82_110	DD OFFSET EmXorByteImMem
em82_111	DD OFFSET EmCmpByteImMem

Em82:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].Em82Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM83
;
;		DESCRIPTION:	EMULATE 83 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em83Tab:
em83_000	DD OFFSET EmAddWordImsxMem
em83_001	DD OFFSET EmOrWordImsxMem
em83_010	DD OFFSET EmAdcWordImsxMem
em83_011	DD OFFSET EmSbbWordImsxMem
em83_100	DD OFFSET EmAndWordImsxMem
em83_101	DD OFFSET EmSubWordImsxMem
em83_110	DD OFFSET EmXorWordImsxMem
em83_111	DD OFFSET EmCmpWordImsxMem

Em83:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].Em83Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EM8F
;
;		DESCRIPTION:	EMULATE 8F instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Em8FTab:
em8F_000	DD OFFSET EmPopMem
em8F_001	DD OFFSET EmulateError
em8F_010	DD OFFSET EmulateError
em8F_011	DD OFFSET EmulateError
em8F_100	DD OFFSET EmulateError
em8F_101	DD OFFSET EmulateError
em8F_110	DD OFFSET EmulateError
em8F_111	DD OFFSET EmulateError

Em8F:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].Em8FTab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMC0
;
;		DESCRIPTION:	EMULATE C0 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmC0Tab:
emC0_000	DD OFFSET EmRolByteMemIm
emC0_001	DD OFFSET EmRorByteMemIm
emC0_010	DD OFFSET EmRclByteMemIm
emC0_011	DD OFFSET EmRcrByteMemIm
emC0_100	DD OFFSET EmShlByteMemIm
emC0_101	DD OFFSET EmShrByteMemIm
emC0_110	DD OFFSET EmulateError
emC0_111	DD OFFSET EmSarByteMemIm

EmC0:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmC0Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMC1
;
;		DESCRIPTION:	EMULATE C1 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmC1Tab:
emC1_000	DD OFFSET EmRolWordMemIm
emC1_001	DD OFFSET EmRorWordMemIm
emC1_010	DD OFFSET EmRclWordMemIm
emC1_011	DD OFFSET EmRcrWordMemIm
emC1_100	DD OFFSET EmShlWordMemIm
emC1_101	DD OFFSET EmShrWordMemIm
emC1_110	DD OFFSET EmulateError
emC1_111	DD OFFSET EmSarWordMemIm

EmC1:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmC1Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMD0
;
;		DESCRIPTION:	EMULATE D0 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD0Tab:
emD0_000	DD OFFSET EmRolByteMem1
emD0_001	DD OFFSET EmRorByteMem1
emD0_010	DD OFFSET EmRclByteMem1
emD0_011	DD OFFSET EmRcrByteMem1
emD0_100	DD OFFSET EmShlByteMem1
emD0_101	DD OFFSET EmShrByteMem1
emD0_110	DD OFFSET EmulateError
emD0_111	DD OFFSET EmSarByteMem1

EmD0:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmD0Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMD1
;
;		DESCRIPTION:	EMULATE D1 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD1Tab:
emD1_000	DD OFFSET EmRolWordMem1
emD1_001	DD OFFSET EmRorWordMem1
emD1_010	DD OFFSET EmRclWordMem1
emD1_011	DD OFFSET EmRcrWordMem1
emD1_100	DD OFFSET EmShlWordMem1
emD1_101	DD OFFSET EmShrWordMem1
emD1_110	DD OFFSET EmulateError
emD1_111	DD OFFSET EmSarWordMem1

EmD1:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmD1Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMD2
;
;		DESCRIPTION:	EMULATE D2 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD2Tab:
emD2_000	DD OFFSET EmRolByteMemCl
emD2_001	DD OFFSET EmRorByteMemCl
emD2_010	DD OFFSET EmRclByteMemCl
emD2_011	DD OFFSET EmRcrByteMemCl
emD2_100	DD OFFSET EmShlByteMemCl
emD2_101	DD OFFSET EmShrByteMemCl
emD2_110	DD OFFSET EmulateError
emD2_111	DD OFFSET EmSarByteMemCl

EmD2:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmD2Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMD3
;
;		DESCRIPTION:	EMULATE D3 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmD3Tab:
emD3_000	DD OFFSET EmRolWordMemCl
emD3_001	DD OFFSET EmRorWordMemCl
emD3_010	DD OFFSET EmRclWordMemCl
emD3_011	DD OFFSET EmRcrWordMemCl
emD3_100	DD OFFSET EmShlWordMemCl
emD3_101	DD OFFSET EmShrWordMemCl
emD3_110	DD OFFSET EmulateError
emD3_111	DD OFFSET EmSarWordMemCl

EmD3:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmD3Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMF6
;
;		DESCRIPTION:	EMULATE F6 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmF6Tab:
emF6_000	DD OFFSET EmTestByteImMem
emF6_001	DD OFFSET EmulateError
emF6_010	DD OFFSET EmNotByteMem
emF6_011	DD OFFSET EmNegByteMem
emF6_100	DD OFFSET EmMulByteMem
emF6_101	DD OFFSET EmImulByteMem
emF6_110	DD OFFSET EmDivByteMem
emF6_111	DD OFFSET EmIdivByteMem

EmF6:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmF6Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMF7
;
;		DESCRIPTION:	EMULATE F7 instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmF7Tab:
emF7_000	DD OFFSET EmTestWordImMem
emF7_001	DD OFFSET EmulateError
emF7_010	DD OFFSET EmNotWordMem
emF7_011	DD OFFSET EmNegWordMem
emF7_100	DD OFFSET EmMulWordMem
emF7_101	DD OFFSET EmImulWordMem
emF7_110	DD OFFSET EmDivWordMem
emF7_111	DD OFFSET EmIdivWordMem

EmF7:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmF7Tab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMFE
;
;		DESCRIPTION:	EMULATE FE instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFETab:
emFE_000	DD OFFSET EmIncByteMem
emFE_001	DD OFFSET EmDecByteMem
emFE_010	DD OFFSET EmulateError
emFE_011	DD OFFSET EmulateError
emFE_100	DD OFFSET EmulateError
emFE_101	DD OFFSET EmulateError
emFE_110	DD OFFSET EmulateError
emFE_111	DD OFFSET EmulateError

EmFE:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmFETab
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EMFF
;
;		DESCRIPTION:	EMULATE FF instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmFFTab:
emFF_000	DD OFFSET EmIncWordMem
emFF_001	DD OFFSET EmDecWordMem
emFF_010	DD OFFSET EmCallNearMem
emFF_011	DD OFFSET EmCallFarMem
emFF_100	DD OFFSET EmJmpNearMem
emFF_101	DD OFFSET EmJmpFarMem
emFF_110	DD OFFSET EmPushMem
emFF_111	DD OFFSET EmulateError

EmFF:
	call ReadCodeByte
	movzx ebx,al
	shr bl,2
	and bl,0Eh
	jmp dword ptr [2*ebx].EmFFTab

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			EmulateTab
;
;		description:	emulate instruction
;
;		PARAMETERS:		SS:BP		CPU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EmulateTab:
emt00	DD OFFSET EmAddByteMemReg,		OFFSET EmAddWordMemReg
emt02	DD OFFSET EmAddByteRegMem,		OFFSET EmAddWordRegMem
emt04	DD OFFSET EmAddByteImAcc,		OFFSET EmAddWordImAcc
emt06	DD OFFSET EmPushEs,				OFFSET EmPopEs
emt08	DD OFFSET EmOrByteMemReg,		OFFSET EmOrWordMemReg
emt0A	DD OFFSET EmOrByteRegMem,		OFFSET EmOrWordRegMem
emt0C	DD OFFSET EmOrByteImAcc,		OFFSET EmOrWordImAcc
emt0E	DD OFFSET EmPushCs,				OFFSET Em0F
emt10	DD OFFSET EmAdcByteMemReg,		OFFSET EmAdcWordMemReg
emt12	DD OFFSET EmAdcByteRegMem,		OFFSET EmAdcWordRegMem
emt14	DD OFFSET EmAdcByteImAcc,		OFFSET EmAdcWordImAcc
emt16	DD OFFSET EmPushSs,				OFFSET EmPopSs
emt18	DD OFFSET EmSbbByteMemReg,		OFFSET EmSbbWordMemReg
emt1A	DD OFFSET EmSbbByteRegMem,		OFFSET EmSbbWordRegMem
emt1C	DD OFFSET EmSbbByteImAcc,		OFFSET EmSbbWordImAcc
emt1E	DD OFFSET EmPushDs,				OFFSET EmPopDs
emt20	DD OFFSET EmAndByteMemReg,		OFFSET EmAndWordMemReg
emt22	DD OFFSET EmAndByteRegMem,		OFFSET EmAndWordRegMem
emt24	DD OFFSET EmAndByteImAcc,		OFFSET EmAndWordImAcc
emt26	DD OFFSET EmOverrideEs,			OFFSET EmDaa
emt28	DD OFFSET EmSubByteMemReg,		OFFSET EmSubWordMemReg
emt2A	DD OFFSET EmSubByteRegMem,		OFFSET EmSubWordRegMem
emt2C	DD OFFSET EmSubByteImAcc,		OFFSET EmSubWordImAcc
emt2E	DD OFFSET EmOverrideCs,			OFFSET EmDas
emt30	DD OFFSET EmXorByteMemReg,		OFFSET EmXorWordMemReg
emt32	DD OFFSET EmXorByteRegMem,		OFFSET EmXorWordRegMem
emt34	DD OFFSET EmXorByteImAcc,		OFFSET EmXorWordImAcc
emt36	DD OFFSET EmOverrideSs,			OFFSET EmAaa
emt38	DD OFFSET EmCmpByteMemReg,		OFFSET EmCmpWordMemReg
emt3A	DD OFFSET EmCmpByteRegMem,		OFFSET EmCmpWordRegMem
emt3C	DD OFFSET EmCmpByteImAcc,		OFFSET EmCmpWordImAcc
emt3E	DD OFFSET EmOverrideDs,			OFFSET EmAas
emt40	DD OFFSET EmIncAx,				OFFSET EmIncCx
emt42	DD OFFSET EmIncDx,				OFFSET EmIncBx
emt44	DD OFFSET EmIncSp,				OFFSET EmIncBp
emt46	DD OFFSET EmIncSi,				OFFSET EmIncDi
emt48	DD OFFSET EmDecAx,				OFFSET EmDecCx
emt4A	DD OFFSET EmDecDx,				OFFSET EmDecBx
emt4C	DD OFFSET EmDecSp,				OFFSET EmDecBp
emt4E	DD OFFSET EmDecSi,				OFFSET EmDecDi
emt50	DD OFFSET EmPushAx,				OFFSET EmPushCx
emt52	DD OFFSET EmPushDx,				OFFSET EmPushBx
emt54	DD OFFSET EmPushSp,				OFFSET EmPushBp
emt56	DD OFFSET EmPushSi,				OFFSET EmPushDi
emt58	DD OFFSET EmPopAx,				OFFSET EmPopCx
emt5A	DD OFFSET EmPopDx,				OFFSET EmPopBx
emt5C	DD OFFSET EmPopSp,				OFFSET EmPopBp
emt5E	DD OFFSET EmPopSi,				OFFSET EmPopDi
emt60	DD OFFSET EmPusha,				OFFSET EmPopa
emt62	DD OFFSET EmulateError,			OFFSET EmArplRegMem
emt64	DD OFFSET EmOverrideFs,			OFFSET EmOverrideGs
emt66	DD OFFSET EmOverrideData,		OFFSET EmOverrideAdr
emt68	DD OFFSET EmPushIm,				OFFSET EmImulWordImMem
emt6A	DD OFFSET EmPushImsx,			OFFSET EmImulWordImsxMem
emt6C	DD OFFSET EmInsb,				OFFSET EmInsw
emt6E	DD OFFSET EmOutsb,				OFFSET EmOutsw
emt70	DD OFFSET EmJoShort,			OFFSET EmJnoShort
emt72	DD OFFSET EmJbShort,			OFFSET EmJnbShort
emt74	DD OFFSET EmJeShort,			OFFSET EmJneShort
emt76	DD OFFSET EmJbeShort,			OFFSET EmJnbeShort
emt78	DD OFFSET EmJsShort,			OFFSET EmJnsShort
emt7A	DD OFFSET EmJpShort,			OFFSET EmJnpShort
emt7C	DD OFFSET EmJlShort,			OFFSET EmJnlShort
emt7E	DD OFFSET EmJleShort,			OFFSET EmJnleShort
emt80	DD OFFSET Em80,					OFFSET Em81
emt82	DD OFFSET Em82,					OFFSET Em83
emt84	DD OFFSET EmTestByteMemReg,		OFFSET EmTestWordMemReg
emt86	DD OFFSET EmXchgByteRegMem,		OFFSET EmXchgWordRegMem
emt88	DD OFFSET EmMoveByteRegToMem,	OFFSET EmMoveWordRegToMem
emt8A	DD OFFSET EmMoveByteMemToReg,	OFFSET EmMoveWordMemToReg
emt8C	DD OFFSET EmMoveSregToMem,		OFFSET EmLea
emt8E	DD OFFSET EmMoveMemToSreg,		OFFSET Em8F
emt90	DD OFFSET EmNop,				OFFSET EmXchgAxCx
emt92	DD OFFSET EmXchgAxDx,			OFFSET EmXchgAxBx
emt94	DD OFFSET EmXchgAxSp,			OFFSET EmXchgAxBp
emt96	DD OFFSET EmXchgAxSi,			OFFSET EmXchgAxDi
emt98	DD OFFSET EmCbw,				OFFSET EmCwd
emt9A	DD OFFSET EmCallFar,			OFFSET EmWait
emt9C	DD OFFSET EmPushf,				OFFSET EmPopf
emt9E	DD OFFSET EmSahf,				OFFSET EmLahf
emtA0	DD OFFSET EmMoveByteMemToAcc,	OFFSET EmMoveWordMemToAcc
emtA2	DD OFFSET EmMoveByteAccToMem,	OFFSET EmMoveWordAccToMem
emtA4	DD OFFSET EmMovsb,				OFFSET EmMovsw
emtA6	DD OFFSET EmCmpsb,				OFFSET EmCmpsw
emtA8	DD OFFSET EmTestByteImAcc,		OFFSET EmTestWordImAcc
emtAA	DD OFFSET EmStosb,				OFFSET EmStosw
emtAC	DD OFFSET EmLodsb,				OFFSET EmLodsw
emtAE	DD OFFSET EmScasb,				OFFSET EmScasw
emtB0	DD OFFSET EmMoveAlIm,			OFFSET EmMoveClIm
emtB2	DD OFFSET EmMoveDlIm,			OFFSET EmMoveBlIm
emtB4	DD OFFSET EmMoveAhIm,			OFFSET EmMoveChIm
emtB6	DD OFFSET EmMoveDhIm,			OFFSET EmMoveBhIm
emtB8	DD OFFSET EmMoveAxIm,			OFFSET EmMoveCxIm
emtBA	DD OFFSET EmMoveDxIm,			OFFSET EmMoveBxIm
emtBC	DD OFFSET EmMoveSpIm,			OFFSET EmMoveBpIm
emtBE	DD OFFSET EmMoveSiIm,			OFFSET EmMoveDiIm
emtC0	DD OFFSET EmC0,					OFFSET EmC1
emtC2	DD OFFSET EmRetNearN,			OFFSET EmRetNear
emtC4	DD OFFSET EmLes,				OFFSET EmLds
emtC6	DD OFFSET EmMoveByteImToMem,	OFFSET EmMoveWordImToMem
emtC8	DD OFFSET EmEnter,				OFFSET EmLeave
emtCA	DD OFFSET EmRetFarN,			OFFSET EmRetFar
emtCC	DD OFFSET EmInt3,				OFFSET EmInt
emtCE	DD OFFSET EmulateError,			OFFSET EmIret
emtD0	DD OFFSET EmD0,					OFFSET EmD1
emtD2	DD OFFSET EmD2,					OFFSET EmD3
emtD4	DD OFFSET EmulateError,			OFFSET EmulateError
emtD6	DD OFFSET EmulateError,			OFFSET EmXlat
emtD8	DD OFFSET EmD8,					OFFSET EmD9
emtDA	DD OFFSET EmDA,					OFFSET EmDB
emtDC	DD OFFSET EmDC,					OFFSET EmDD
emtDE	DD OFFSET EmDE,					OFFSET EmDF
emtE0	DD OFFSET EmLoopnzShort,		OFFSET EmLoopzShort
emtE2	DD OFFSET EmLoopShort,			OFFSET EmJcxzShort
emtE4	DD OFFSET EmInByteIm,	 		OFFSET EmInWordIm
emtE6	DD OFFSET EmOutByteIm,			OFFSET EmOutWordIm
emtE8	DD OFFSET EmCallNear,			OFFSET EmJmpNear
emtEA	DD OFFSET EmJmpFar,				OFFSET EmJmpShort
emtEC	DD OFFSET EmInByteDx,			OFFSET EmInWordDx
emtEE	DD OFFSET EmOutByteDx,			OFFSET EmOutWordDx
emtF0	DD OFFSET EmulateError,			OFFSET EmulateError
emtF2	DD OFFSET EmRepne,				OFFSET EmRepe
emtF4	DD OFFSET EmHlt,				OFFSET EmCmc
emtF6	DD OFFSET EmF6,					OFFSET EmF7
emtF8	DD OFFSET EmClc,				OFFSET EmStc
emtFA	DD OFFSET EmCli,				OFFSET EmSti
emtFC	DD OFFSET EmCld,				OFFSET EmStd
emtFE	DD OFFSET EmFE,					OFFSET EmFF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Emulate
;
;		description:	Emulate an instruction
;
;		PARAMETERS:		CPU registers, must be on stack
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public Emulate

Emulate	Proc near
	push ebp
	mov ebp,esp
	sub	esp,Tprog_position_		;de l'espace pour fabriquer la structure
	pushad
	lea	ebx,[ebp-Tprog_position_]
	mov ebp,[ebp+8]
	mov	eax,[ebp].reg_eip
	mov	[ebx].p_offset,eax
	mov	ax,[ebp].reg_cs.d_selector
	mov	[ebx].p_segment,ax
	push	ebx
	call	setvalue
;
	mov [ebp].running,1
	and [ebp].em_debug, NOT DEBUG_BREAK
	mov al,[ebp].reg_cs.d_access
	and al,ACCESS_RPL
	mov [ebp].em_pl,al
;
	test [ebp].reg_cs.d_access,ACCESS_SIZE
	jz emulate16

emulate32:
	mov [ebp].em_flags,a32 OR d32
	jmp emulate_start

emulate16:
	mov [ebp].em_flags,0

emulate_start:
	mov [ebp].em_sreg,seg_def
;	
	mov eax,[ebp].reg_eip
	mov [ebp].org_eip,eax
	mov eax,[ebp].reg_esp
	mov [ebp].org_esp,eax
	mov eax,esp
	sub eax,4
	mov [ebp].org_stack,eax
;
	test [ebp].reg_eflags,EFLAGS_IF
	jz emulate_no_int
;
	mov al,[ebp].pending_int
	or al,al
	jz emulate_no_int
;
	push ebp
	call GetIntVector
	call HwInt
	jmp emulate_done

emulate_no_int:
	test [ebp].reg_eflags,EFLAGS_TF
	jz emulate_no_trap
;
	mov al,1
	call IntFar
	jmp emulate_done

emulate_no_trap:
	call ReadCodeByte
	movzx ebx,al
	shl ebx,2
	call dword ptr [ebx].EmulateTab
	test [ebp].em_debug, DEBUG_BREAK
	jnz emulate_done
;
	and [ebp].em_debug, NOT DEBUG_RESUME

emulate_done:
	mov [ebp].running,0
;
	popad
	add	esp,Tprog_position_		;de l'espace pour fabriquer la structure
	pop ebp
	ret 4
Emulate	Endp

	END
