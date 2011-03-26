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

STATE_DIRTY = 9Bh
STATE_USED = 5Ah
STATE_EMPTY = 0CFh
STATE_BAD = 0AAh
STATE_SEQ = 7Bh

FLAGS_READ_AHEAD = 1
FLAG_EXT_DATA = 2
FLAG_IO_PENDING = 4
FLAG_ASYNC_WRITE = 8
FLAG_IO_BUSY = 10h

BUSY_FLAGS = FLAG_IO_PENDING OR FLAG_ASYNC_WRITE OR FLAG_IO_BUSY

DISC_HANDLE_SIZE	EQU 32

discbuf_handle		STRUC

dh_next				DD ?
dh_prev				DD ?
dh_unit				DW ?
dh_sector			DW ?
dh_wait				DW ?
dh_thread			DW ?
dh_lock_count		DB ?
dh_state			DB ?
dh_usage			DB ?
dh_flags			DB ?
dh_buf_sel			DW ?
dh_time_lsb			DD ?
dh_time_msb			DW ?
dh_data				DD ?

discbuf_handle		ENDS

disc_system_struc 	STRUC

ds_disc_assign_proc	    DD ?,?

;	BX	Disc handle
ds_drive_assign1_proc	DD ?,?

;	BX	Disc handle
ds_drive_assign2_proc	DD ?,?

;	BX	Disc handle
ds_demand_mount_proc	DD ?,?

;   BX  Disc handle
;   EDX Start sector
;   ECX Number of sectors
ds_erase_proc           DD ?,?

disc_system_struc	ENDS
