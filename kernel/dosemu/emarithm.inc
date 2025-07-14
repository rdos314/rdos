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
; EMARITHM.INC
; External definitions of arithmetric functions for instruction emulator
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
