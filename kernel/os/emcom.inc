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
; EMCOM.INC
; External definitions for utility emulator functions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn GetCsBitness:near
	extrn GetSsBitness:near
	extrn init_common:near

	extrn ReadByte:near
	extrn ReadWord:near
	extrn ReadDword:near
	extrn ReadFword:near
	extrn ReadQword:near
	extrn ReadTbyte:near

	extrn WriteByte:near
	extrn WriteWord:near
	extrn WriteDword:near
	extrn WriteFword:near
	extrn WriteQword:near
	extrn WriteTbyte:near

	extrn PushWord:near
	extrn PushDword:near
	extrn PopWord:near
	extrn PopDword:near

	extrn AddToStack:near
	extrn SubFromStack:near

	extrn ReadCodeByte:near
	extrn ReadCodeWord:near
	extrn ReadCodeDword:near
	extrn ReadCodeFword:near

	extrn InByte:near
	extrn InWord:near
	extrn InDword:near

	extrn OutByte:near
	extrn OutWord:near
	extrn OutDword:near

