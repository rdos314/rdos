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
; HANDLE.INC
; Handle definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ADC_HANDLE =            015FCh 
FM_INSTR_HANDLE =       017DEh
DLL_HANDLE16 =          026CFh
DLL_HANDLE32 =          026DFh
SPRITE_HANDLE =         02CF5h
CRC_HANDLE =            0367Ah
BLOCK_HANDLE =          03865h
USB_DEV_HANDLE =        04AFEh
USB_EVENT_HANDLE =      04FAFh
UDP_LISTEN_HANDLE =     05236h
SERIAL_HANDLE =         05A45h
VFS_CMD_HANDLE =        05C5Ah
ENV_HANDLE =            05FAEh
FUTEX_HANDLE =          0627Ah
RW_SECTION_HANDLE =     067AFh
WAIT_HANDLE =           06AFEh
SYSLOG_HANDLE   =       0703Ah
SECTION_HANDLE =        07A87h
IPC_HANDLE =	        07B5Ah
TCP_LISTEN_HANDLE =     07FAEh
TCP_SOCKET_HANDLE =     0847Fh
SSL_LISTEN_HANDLE =     087A4h
CARDDEV_HANDLE =        08AEBh
UDP_SOCKET_HANDLE =     0935Ah
VFS_FILE_HANDLE =       095AAh
FONT_HANDLE =	        09AF4h
DIR_HANDLE = 	        0A765h
XMS_HANDLE =	        0A560h
REALTIME_HANDLE =       0ACDFh
SIGNAL_HANDLE =         0ADEFh
BIGNUM_HANDLE =         0AFAFh
PRINTER_HANDLE =        0B63Ah
MEMMAP_HANDLE =	        0BA54h
FM_HANDLE =             0BCAFh
LON_HANDLE      =       0CAF2h
AUDIO_OUT_HANDLE =      0CEDAh
HID_HANDLE =            0D736h
BITMAP_HANDLE =	        0DB57h
SSL_SESS_HANDLE =       0E254h
INI_HANDLE =	        0EAF3h
VFS_DIR_HANDLE =        0F67Ah
SSL_CONN_HANDLE =       0F9ACh


handle_header	STRUC

hh_sign			DW ?
hh_handle		DW ?

handle_header	ENDS
