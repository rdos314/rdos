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
; EMSEG.INC
; External declarations for segment register and fault emulations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn ValidateSegment:near
	extrn LoadTr:near
	extrn LoadLdt:near
	extrn JmpFar:near
	extrn CallFar16:near
	extrn CallFar32:near
	extrn RetFar16:near
	extrn RetFar32:near
	extrn IntFar:near
	extrn HwInt:near
	extrn IretFar16:near
	extrn IretFar32:near
	extrn IretTss:near
	extrn LoadSegment:near
	extrn ValidateTssLdt:near
	extrn ValidateTssCs:near

	extrn TrapFault:near
	extrn EmulateError:near
	extrn DivFault:near
	extrn SegmentFault:near
	extrn StackFault:near
	extrn ProtectionFault:near
	extrn PageFault:near
	extrn LoadFault:near
	extrn AccessFault:near
	extrn PrivilegeFault:near
	extrn FpFault:near
