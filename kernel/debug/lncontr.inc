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
; LNCONTR.INC
; External declarations for control transfer emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn LongJmpShort:near
	extrn LongJoShort:near
	extrn LongJnoShort:near
	extrn LongJbShort:near
	extrn LongJnbShort:near
	extrn LongJeShort:near
	extrn LongJneShort:near
	extrn LongJbeShort:near
	extrn LongJnbeShort:near
	extrn LongJsShort:near
	extrn LongJnsShort:near
	extrn LongJpShort:near
	extrn LongJnpShort:near
	extrn LongJlShort:near
	extrn LongJnlShort:near
	extrn LongJleShort:near
	extrn LongJnleShort:near

	extrn LongJmpNear:near
	extrn LongJoNear:near
	extrn LongJnoNear:near
	extrn LongJbNear:near
	extrn LongJnbNear:near
	extrn LongJeNear:near
	extrn LongJneNear:near
	extrn LongJbeNear:near
	extrn LongJnbeNear:near
	extrn LongJsNear:near
	extrn LongJnsNear:near
	extrn LongJpNear:near
	extrn LongJnpNear:near
	extrn LongJlNear:near
	extrn LongJnlNear:near
	extrn LongJleNear:near
	extrn LongJnleNear:near

	extrn LongRetNear:near

	extrn LongCallFarMem:near

