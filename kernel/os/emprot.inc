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
; EMPROT.INC
; External declarations of priviledged functions for instruction emulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn EmMoveRegCr:near
	extrn EmMoveCrReg:near
	extrn EmMoveRegDr:near
	extrn EmMoveDrReg:near

	extrn EmArplRegMem:near
	extrn EmLarRegMem:near
	extrn EmLslRegMem:near
	extrn EmVerrMem:near
	extrn EmVerwMem:near

	extrn EmLmswMem:near
	extrn EmSmswMem:near

	extrn EmLgdtMem:near
	extrn EmLidtMem:near
	extrn EmSgdtMem:near
	extrn EmSidtMem:near

	extrn EmLldtMem:near
	extrn EmLtrMem:near
	extrn EmSldtMem:near
	extrn EmStrMem:near

