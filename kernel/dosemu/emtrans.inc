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
