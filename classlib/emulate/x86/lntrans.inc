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

	extrn LongPopRax:near
	extrn LongPopRcx:near
	extrn LongPopRdx:near
	extrn LongPopRbx:near
	extrn LongPopRsp:near
	extrn LongPopRbp:near
	extrn LongPopRsi:near
	extrn LongPopRdi:near

	extrn LongMoveWordMemToReg:near
	extrn LongMoveByteMemToReg:near
    extrn LongMoveWordImToMem:near
    
	extrn LongMoveMemToSreg:near

	extrn LongMoveAxIm:near
	extrn LongMoveBxIm:near
	extrn LongMoveCxIm:near
	extrn LongMoveDxIm:near
	extrn LongMoveSpIm:near
	extrn LongMoveBpIm:near
	extrn LongMoveSiIm:near
	extrn LongMoveDiIm:near

	extrn LongXchgWordRegMem:near
