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
; FS.INC
; File system interface definition
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

file_system_struc	STRUC

;	IN	DX			DRIVE DATA
mount_proc				DD ?

dismount_proc			DD ?

;	OUT	EAX			FREE UNITS
;	OUT	CX			NUMBER OF BYTES/UNIT
;	OUT	EDX			TOTAL NUMBER OF UNITS
info_proc				DD ?

;	IN	ES:EDI		PATH NAME
set_cur_dir_proc		DD ?

;	IN	ES:EDI		PATH NAME
get_cur_dir_proc		DD ?

;	IN	ES:EDI		PATH NAME
make_dir_proc			DD ?

;	IN	ES:EDI		PATH NAME
remove_dir_proc			DD ?

;	IN	ES:EDI		PATH NAME
delete_file_proc		DD ?

;	IN	FS:ESI		CURRENT NAME
;	IN	ES:EDI		NEW NAME
rename_file_proc		DD ?

;	IN	ES:EDI		PATH NAME
;	OUT	CX			FILE ATTRIBUTE
get_file_attrib_proc	DD ?

;	IN	ES:EDI		PATH NAME
;	IN	CX			FILE ATTRIBUTE
set_file_attrib_proc	DD ?

;	IN	ES:EDI		PATH NAME
;	OUT	BX			DIR HANDLE
open_dir_proc			DD ?

;	IN	BX			DIR HANDLE
close_dir_proc			DD ?

;	IN	BX			DIR HANDLE
;	IN	DX			ENTRY #
;	IN	CX			MAX SIZE OF FILENAME
;	IN	ES:EDI		FILENAME BUFFER
;	OUT	ECX			FILE SIZE
;	OUT	BX			FILE ATTRIBUTE
;	OUT	EDX:EAX		FILE TIME/DATE
read_dir_proc			DD ?

;	IN	ES:EDI		PATH NAME
;	IN	CL			ACCESS MODE
;	OUT	BX			FILE HANDLE
open_file_proc			DD ?

;	IN	ES:EDI		PATH NAME
;	IN	CX			FILE ATTRIBUTE
;	OUT	BX			FILE HANDLE
create_file_proc		DD ?

;	IN	BX			FILE HANDLE
close_file_proc			DD ?

;	IN	BX			FILE HANDLE
dupl_file_proc			DD ?

;	IN	BX			FILE HANDLE
;	OUT	DX			IOCTL DATA
get_ioctl_data_proc		DD ?

;	IN	BX			FILE HANDLE
;	OUT	EDX			FILE SIZE
get_file_size_proc		DD ?

;	IN	BX			FILE HANDLE
;	IN	EDX			FILE SIZE
set_file_size_proc		DD ?

;	IN	BX			FILE HANDLE
;	OUT	EDX:ECX		FILE TIME
get_file_time_proc		DD ?

;	IN	BX			FILE HANDLE
;	IN	EDX:ECX		FILE TIME
set_file_time_proc		DD ?

;	IN	BX			FILE HANDLE
;	IN	ECX			NUMBER OF BYTES
;	IN	EDX			POSITION
;	IN	ES:EDI		DATA BUFFER
;	OUT	EAX			NUMBER OF BYTES READ
read_file_proc			DD ?

;	IN	BX			FILE HANDLE
;	IN	ECX			NUMBER OF BYTES
;	IN	EDX			POSITION
;	IN	ES:EDI		DATA BUFFER
;	OUT	EAX			NUMBER OF BYTES WRITTEN
write_file_proc			DD ?

file_system_struc	ENDS

