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
; HANDLE.INC
; Handle definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ADC_HANDLE =	015FCh 
SPRITE_HANDLE = 02CF5h
FILE_HANDLE = 	03AB6h
SERIAL_HANDLE = 05A45h
WAIT_HANDLE =   06AFEh
IPC_HANDLE =	07B5Ah
FONT_HANDLE =	09AF4h
DIR_HANDLE = 	0A765h
XMS_HANDLE =	0A560h
MEMMAP_HANDLE =	0BA54h
BITMAP_HANDLE =	0DB57h

handle_header	STRUC

hh_sign			DW ?
hh_handle		DW ?

handle_header	ENDS
