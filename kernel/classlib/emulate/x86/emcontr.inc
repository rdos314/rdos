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
; EMCONTR.INC
; External declarations for control transfer emulations
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
	extrn EmRetFarN:near

	extrn EmInt3:near
	extrn EmInt:near
	extrn EmIret:near
