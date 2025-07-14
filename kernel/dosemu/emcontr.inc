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
; EMCONTROL.INC
; External declarations of control transfer functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn EmCli:near
	extrn EmSti:near

	extrn EmJmpShort:near
	extrn EmJoShort:near
	extrn EmJnoShort:near
	extrn EmJbShort:near
	extrn EmJnbShort:near
	extrn EmJeShort:near
	extrn EmJneShort:near
	extrn EmJbeShort:near
	extrn EmJnbeShort:near
	extrn EmJsShort:near
	extrn EmJnsShort:near
	extrn EmJpShort:near
	extrn EmJnpShort:near
	extrn EmJlShort:near
	extrn EmJnlShort:near
	extrn EmJleShort:near
	extrn EmJnleShort:near

	extrn EmJcxzShort:near
	extrn EmLoopShort:near
	extrn EmLoopzShort:near
	extrn EmLoopnzShort:near

	extrn EmJmpNear:near
	extrn EmJoNear:near
	extrn EmJnoNear:near
	extrn EmJbNear:near
	extrn EmJnbNear:near
	extrn EmJeNear:near
	extrn EmJneNear:near
	extrn EmJbeNear:near
	extrn EmJnbeNear:near
	extrn EmJsNear:near
	extrn EmJnsNear:near
	extrn EmJpNear:near
	extrn EmJnpNear:near
	extrn EmJlNear:near
	extrn EmJnlNear:near
	extrn EmJleNear:near
	extrn EmJnleNear:near

	extrn EmJmpNearMem:near
	extrn EmCallNear:near
	extrn EmCallNearMem:near
	extrn EmRetNear:near
	extrn EmRetNearN:near

	extrn EmJmpFar:near
	extrn EmJmpFarMem:near

	extrn EmCallFar:near
	extrn EmCallFarMem:near
	extrn EmRetFar:near

	extrn EmInt3:near
	extrn EmInt:near
	extrn EmIret:near
