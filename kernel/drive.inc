;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
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
dh_unit				DD ?
dh_sector			DW ?
dh_wait				DW ?
dh_thread			DW ?
dh_lock_count		DB ?
dh_state			DB ?
dh_usage			DB ?
dh_flags			DB ?
dh_buf_sel			DW ?
dh_time_lsb			DD ?
dh_data				DD ?

discbuf_handle		ENDS
