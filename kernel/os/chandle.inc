;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2017, Leif Ekblad
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
; CHANDLE.INC
; C handle definitions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; handle types
;

C_HANDLE_FILE   = 1

;
; iomode constants
;

IO_READ         = 1
IO_WRITE        = 2
IO_EOF          = 10h
IO_BINARY       = 40h
IO_APPEND       = 80h
IO_FBF          = 100h
IO_LBF          = 200h
IO_NBF          = 400h
IO_ISTTY        = 1000h

;
; open constants
;

O_RDONLY        = 0
O_WRONLY        = 1
O_RDWR          = 2
O_APPEND        = 10h
O_CREAT         = 20h
O_TRUNC         = 40h
O_NOINHERIT     = 80h
O_TEXT          = 100h
O_BINARY        = 200h
O_EXCL          = 400h

SYS_HANDLE_COUNT      = 1024
SYS_BITMAP_COUNT      = SYS_HANDLE_COUNT SHR 5

handle_entry_struc    STRUC

he_type          DW ?
he_sel           DW ?
he_io_mode       DW ?
he_ref_count     DW ?

handle_entry_struc    ENDS

handle_data_struc       STRUC

hd_bitmap        DD SYS_BITMAP_COUNT DUP(?)
hd_data          DB SYS_HANDLE_COUNT * SIZE handle_entry_struc DUP(?)

handle_data_struc       ENDS
