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
; DRIVE.INC
; Block device driver interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disc_proc_struc	STRUC

;	IN	AX		Unit #
;	IN	BX		Disc handle
;	OUT	DS:SI	Disc data
;	OUT	AX		Sectors / unit
;	OUT	CX		Bytes / sector
;	OUT	DX		Units
open_disc_proc			DD ?

;	IN	BX		Disc handle
close_disc_proc		DD ?

;	IN	BX		Disc handle
check_media_proc		DD ?

;	IN	AX		Sector
;	IN	BX		Disc handle
;	IN	DX		Unit
;	IN	CX		Number of sectors
;	IN	EDI		Logical address of buffer, must be page aligned
read_disc_proc			DD ?

;	IN	AX		Sector
;	IN	BX		Disc handle
;	IN	DX		Unit
;	IN	CX		Number of sectors
;	IN	EDI		Logical address of buffer, must be page aligned
write_disc_proc		DD ?

disc_proc_struc	ENDS

