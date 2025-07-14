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
; FILEMAP.INC
; Mapping files in user space
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VFS_FILE_SIGN            = 'F'

file_info_struc  STRUC

fi_sector_count      DD ?,?
fi_fs_size           DD ?,?
fi_size              DD ?,?
fi_access            DD ?,?
fi_create            DD ?,?
fi_modify            DD ?,?
fi_attrib            DD ?
fi_flags             DD ?
fi_uid               DD ?
fi_gid               DD ?
fi_serv_handle       DD ?
fi_bytes_per_sector  DD ?
fi_name              DB ?

file_info_struc  ENDS

file_handle_struc  STRUC

fh_req_size         DD ?,?
fh_pos_arr          DD 15*8*8 DUP(?)
fh_bitmap           DD 15 DUP(?)
fh_futex            futex_struc <>

file_handle_struc  ENDS

file_map_entry  STRUC

fmb_pos             DD ?,?
fmb_size            DD ?
fmb_base            DD ?

file_map_entry  ENDS

file_map  STRUC

fm_sorted_arr       DB 241 DUP(?)
fm_resv             DW ?
fm_update           DB ?
fm_count            DD ?
fm_handle_ptr       DD ?
fm_info_ptr         DD ?
fm_entry_arr        DB 240 * 16 DUP(?)

file_map  ENDS
