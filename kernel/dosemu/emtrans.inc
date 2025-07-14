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
; EMTRANS.INC
; External declarations of transaction group functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn EmMoveByteMemToReg:near
	extrn EmMoveWordMemToReg:near
	extrn EmMoveByteRegToMem:near
	extrn EmMoveWordRegToMem:near
	extrn EmMoveByteMemToAcc:near
	extrn EmMoveWordMemToAcc:near
	extrn EmMoveByteAccToMem:near
	extrn EmMoveWordAccToMem:near
	extrn EmMoveByteImToMem:near
	extrn EmMoveWordImToMem:near
	extrn EmMoveSregToMem:near
	extrn EmMoveMemToSreg:near

	extrn EmMoveAlIm:near
	extrn EmMoveBlIm:near
	extrn EmMoveClIm:near
	extrn EmMoveDlIm:near
	extrn EmMoveAhIm:near
	extrn EmMoveBhIm:near
	extrn EmMoveChIm:near
	extrn EmMoveDhIm:near
	extrn EmMoveAxIm:near
	extrn EmMoveBxIm:near
	extrn EmMoveCxIm:near
	extrn EmMoveDxIm:near
	extrn EmMoveSpIm:near
	extrn EmMoveBpIm:near
	extrn EmMoveSiIm:near
	extrn EmMoveDiIm:near

	extrn EmMovzxByteMem:near
	extrn EmMovzxWordMem:near
	extrn EmMovsxByteMem:near
	extrn EmMovsxWordMem:near

	extrn EmLea:near
	extrn EmLds:near
	extrn EmLes:near
	extrn EmLfs:near
	extrn EmLgs:near
	extrn EmLss:near

	extrn EmEnter:near
	extrn EmLeave:near

	extrn EmPushMem:near
	extrn EmPushAx:near
	extrn EmPushCx:near
	extrn EmPushDx:near
	extrn EmPushBx:near
	extrn EmPushSp:near
	extrn EmPushBp:near
	extrn EmPushSi:near
	extrn EmPushDi:near
	extrn EmPushDs:near
	extrn EmPushEs:near
	extrn EmPushCs:near
	extrn EmPushSs:near
	extrn EmPushFs:near
	extrn EmPushGs:near
	extrn EmPushIm:near
	extrn EmPusha:near
	extrn EmPushImsx:near

	extrn EmPopMem:near
	extrn EmPopAx:near
	extrn EmPopCx:near
	extrn EmPopDx:near
	extrn EmPopBx:near
	extrn EmPopSp:near
	extrn EmPopBp:near
	extrn EmPopSi:near
	extrn EmPopDi:near
	extrn EmPopDs:near
	extrn EmPopEs:near
	extrn EmPopFs:near
	extrn EmPopGs:near
	extrn EmPopSs:near
	extrn EmPopa:near

	extrn EmXchgByteRegMem:near
	extrn EmXchgWordRegMem:near
	extrn EmXchgAxBx:near
	extrn EmXchgAxCx:near
	extrn EmXchgAxDx:near
	extrn EmXchgAxSp:near
	extrn EmXchgAxBp:near
	extrn EmXchgAxSi:near
	extrn EmXchgAxDi:near

	extrn EmInByteIm:near
	extrn EmInByteDx:near
	extrn EmInWordIm:near
	extrn EmInWordDx:near
	extrn EmOutByteIm:near
	extrn EmOutByteDx:near
	extrn EmOutWordIm:near
	extrn EmOutWordDx:near

	extrn EmPushf:near
	extrn EmPopf:near

	extrn EmClc:near
	extrn EmStc:near
	extrn EmCmc:near
	extrn EmStd:near
	extrn EmCld:near
	extrn EmLahf:near
	extrn EmSahf:near
