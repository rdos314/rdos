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
; EMMEM.INC
; External declarations of memory address decoding for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn ByteRegTab:near
	extrn WordRegTab:near
	extrn DwordRegTab:near

	extrn MemTab:near
	extrn SegDsTab:near

	extrn MemBx:near
	extrn MemSi:near
	extrn MemDi:near
	extrn MemD16:near

	extrn MemEbx:near
	extrn MemEsi:near
	extrn MemEdi:near
	extrn MemD32:near

	extrn LoadByteMemReg:near
	extrn LoadWordMemReg:near
	extrn LoadDwordMemReg:near

	extrn SaveByteMemReg:near
	extrn SaveWordMemReg:near
	extrn SaveDwordMemReg:near

	extrn LoadByteMem:near
	extrn LoadWordMem:near
	extrn LoadDwordMem:near
	extrn LoadFwordMem:near
	extrn LoadQwordMem:near
	extrn LoadTbyteMem:near

	extrn SaveByteMem:near
	extrn SaveWordMem:near
	extrn SaveDwordMem:near
	extrn SaveFwordMem:near
	extrn SaveQwordMem:near
	extrn SaveTbyteMem:near

	extrn LoadByteReg:near
	extrn LoadWordReg:near
	extrn LoadDwordReg:near

	extrn SaveByteReg:near
	extrn SaveWordReg:near
	extrn SaveDwordReg:near

