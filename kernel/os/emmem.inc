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

