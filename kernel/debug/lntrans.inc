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
; LNTRANS.INC
; External declarations for move type of instruction emulation
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn LongPushRax:near
	extrn LongPushRcx:near
	extrn LongPushRdx:near
	extrn LongPushRbx:near
	extrn LongPushRsp:near
	extrn LongPushRbp:near
	extrn LongPushRsi:near
	extrn LongPushRdi:near

        extrn LongPushf:near

	extrn LongPopRax:near
	extrn LongPopRcx:near
	extrn LongPopRdx:near
	extrn LongPopRbx:near
	extrn LongPopRsp:near
	extrn LongPopRbp:near
	extrn LongPopRsi:near
	extrn LongPopRdi:near

        extrn LongPopf:near

	extrn LongMoveWordMemToReg:near
	extrn LongMoveByteMemToReg:near
    extrn LongMoveWordImToMem:near
    
	extrn LongMoveMemToSreg:near

	extrn LongMoveAlIm:near
	extrn LongMoveBlIm:near
	extrn LongMoveClIm:near
	extrn LongMoveDlIm:near
	extrn LongMoveAhIm:near
	extrn LongMoveBhIm:near
	extrn LongMoveChIm:near
	extrn LongMoveDhIm:near
	extrn LongMoveAxIm:near
	extrn LongMoveBxIm:near
	extrn LongMoveCxIm:near
	extrn LongMoveDxIm:near
	extrn LongMoveSpIm:near
	extrn LongMoveBpIm:near
	extrn LongMoveSiIm:near
	extrn LongMoveDiIm:near

	extrn LongXchgWordRegMem:near
    extrn LongXchgByteRegMem:near

