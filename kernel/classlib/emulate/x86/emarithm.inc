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
; EMARITHM.INC
; External declarations for arithmetric group instructions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	extrn EmCmpByteRegMem:near
	extrn EmCmpWordRegMem:near
	extrn EmCmpByteMemReg:near
	extrn EmCmpWordMemReg:near
	extrn EmCmpByteImAcc:near
	extrn EmCmpWordImAcc:near
	extrn EmCmpByteImMem:near
	extrn EmCmpWordImMem:near
	extrn EmCmpWordImsxMem:near

	extrn EmTestByteMemReg:near
	extrn EmTestWordMemReg:near
	extrn EmTestByteImAcc:near
	extrn EmTestWordImAcc:near
	extrn EmTestByteImMem:near
	extrn EmTestWordImMem:near

	extrn EmBtMemReg:near
	extrn EmBtImMem:near

	extrn EmBtrMemReg:near
	extrn EmBtrImMem:near

	extrn EmBtsMemReg:near
	extrn EmBtsImMem:near

	extrn EmBtcMemReg:near
	extrn EmBtcImMem:near

	extrn EmBsf:near
	extrn EmBsr:near

	extrn EmAddByteRegMem:near
	extrn EmAddWordRegMem:near
	extrn EmAddByteMemReg:near
	extrn EmAddWordMemReg:near
	extrn EmAddByteImAcc:near
	extrn EmAddWordImAcc:near
	extrn EmAddByteImMem:near
	extrn EmAddWordImMem:near
	extrn EmAddWordImsxMem:near

	extrn EmAdcByteRegMem:near
	extrn EmAdcWordRegMem:near
	extrn EmAdcByteMemReg:near
	extrn EmAdcWordMemReg:near
	extrn EmAdcByteImAcc:near
	extrn EmAdcWordImAcc:near
	extrn EmAdcByteImMem:near
	extrn EmAdcWordImMem:near
	extrn EmAdcWordImsxMem:near

	extrn EmSubByteRegMem:near
	extrn EmSubWordRegMem:near
	extrn EmSubByteMemReg:near
	extrn EmSubWordMemReg:near
	extrn EmSubByteImAcc:near
	extrn EmSubWordImAcc:near
	extrn EmSubByteImMem:near
	extrn EmSubWordImMem:near
	extrn EmSubWordImsxMem:near

	extrn EmSbbByteRegMem:near
	extrn EmSbbWordRegMem:near
	extrn EmSbbByteMemReg:near
	extrn EmSbbWordMemReg:near
	extrn EmSbbByteImAcc:near
	extrn EmSbbWordImAcc:near
	extrn EmSbbByteImMem:near
	extrn EmSbbWordImMem:near
	extrn EmSbbWordImsxMem:near

	extrn EmAndByteRegMem:near
	extrn EmAndWordRegMem:near
	extrn EmAndByteMemReg:near
	extrn EmAndWordMemReg:near
	extrn EmAndByteImAcc:near
	extrn EmAndWordImAcc:near
	extrn EmAndByteImMem:near
	extrn EmAndWordImMem:near
	extrn EmAndWordImsxMem:near

	extrn EmOrByteRegMem:near
	extrn EmOrWordRegMem:near
	extrn EmOrByteMemReg:near
	extrn EmOrWordMemReg:near
	extrn EmOrByteImAcc:near
	extrn EmOrWordImAcc:near
	extrn EmOrByteImMem:near
	extrn EmOrWordImMem:near
	extrn EmOrWordImsxMem:near

	extrn EmXorByteRegMem:near
	extrn EmXorWordRegMem:near
	extrn EmXorByteMemReg:near
	extrn EmXorWordMemReg:near
	extrn EmXorByteImAcc:near
	extrn EmXorWordImAcc:near
	extrn EmXorByteImMem:near
	extrn EmXorWordImMem:near
	extrn EmXorWordImsxMem:near

	extrn EmIncByteMem:near
	extrn EmIncWordMem:near
	extrn EmIncAx:near
	extrn EmIncBx:near
	extrn EmIncCx:near
	extrn EmIncDx:near
	extrn EmIncSp:near
	extrn EmIncBp:near
	extrn EmIncSi:near
	extrn EmIncDi:near

	extrn EmDecByteMem:near
	extrn EmDecWordMem:near
	extrn EmDecAx:near
	extrn EmDecBx:near
	extrn EmDecCx:near
	extrn EmDecDx:near
	extrn EmDecSp:near
	extrn EmDecBp:near
	extrn EmDecSi:near
	extrn EmDecDi:near

	extrn EmNotByteMem:near
	extrn EmNotWordMem:near

	extrn EmNegByteMem:near
	extrn EmNegWordMem:near

	extrn EmRolByteMem1:near
	extrn EmRolByteMemCl:near
	extrn EmRolByteMemIm:near
	extrn EmRolWordMem1:near
	extrn EmRolWordMemCl:near
	extrn EmRolWordMemIm:near

	extrn EmRorByteMem1:near
	extrn EmRorByteMemCl:near
	extrn EmRorByteMemIm:near
	extrn EmRorWordMem1:near
	extrn EmRorWordMemCl:near
	extrn EmRorWordMemIm:near

	extrn EmRclByteMem1:near
	extrn EmRclByteMemCl:near
	extrn EmRclByteMemIm:near
	extrn EmRclWordMem1:near
	extrn EmRclWordMemCl:near
	extrn EmRclWordMemIm:near

	extrn EmRcrByteMem1:near
	extrn EmRcrByteMemCl:near
	extrn EmRcrByteMemIm:near
	extrn EmRcrWordMem1:near
	extrn EmRcrWordMemCl:near
	extrn EmRcrWordMemIm:near

	extrn EmShlByteMem1:near
	extrn EmShlByteMemCl:near
	extrn EmShlByteMemIm:near
	extrn EmShlWordMem1:near
	extrn EmShlWordMemCl:near
	extrn EmShlWordMemIm:near

	extrn EmShrByteMem1:near
	extrn EmShrByteMemCl:near
	extrn EmShrByteMemIm:near
	extrn EmShrWordMem1:near
	extrn EmShrWordMemCl:near
	extrn EmShrWordMemIm:near

	extrn EmSarByteMem1:near
	extrn EmSarByteMemCl:near
	extrn EmSarByteMemIm:near
	extrn EmSarWordMem1:near
	extrn EmSarWordMemCl:near
	extrn EmSarWordMemIm:near

	extrn EmMulByteMem:near
	extrn EmMulWordMem:near

	extrn EmImulByteMem:near
	extrn EmImulWordMem:near
	extrn EmImulWordRegMem:near
	extrn EmImulWordImMem:near
	extrn EmImulWordImsxMem:near

	extrn EmDivByteMem:near
	extrn EmDivWordMem:near

	extrn EmIdivByteMem:near
	extrn EmIdivWordMem:near

	extrn EmAaa:near
	extrn EmAas:near
	extrn EmDaa:near
	extrn EmDas:near
	extrn EmCbw:near
	extrn EmCwd:near

	extrn EmSeto:near
	extrn EmSetno:near
	extrn EmSetb:near
	extrn EmSetnb:near
	extrn EmSete:near
	extrn EmSetne:near
	extrn EmSetbe:near
	extrn EmSetnbe:near
	extrn EmSets:near
	extrn EmSetns:near
	extrn EmSetp:near
	extrn EmSetnp:near
	extrn EmSetl:near
	extrn EmSetnl:near
	extrn EmSetle:near
	extrn EmSetnle:near

    extrn EmBswap:near
