;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
