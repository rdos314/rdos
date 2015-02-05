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
