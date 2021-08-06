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
; VFSfile.inc
; VFS file includes
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_FILE_REQ_ENTRIES = 8
MAX_FILE_REQ_COUNT   = 64
MAX_FILE_USERS       = 256

FILE_SIGN            = 'F'
REQ_SIGN             = 'R'


; shared with server user code!

file_info_struc  STRUC

fi_fs_size           DD ?,?
fi_req_size          DD ?,?
fi_access            DD ?,?
fi_modify            DD ?,?
fi_attrib            DD ?
fi_flags             DD ?
fi_uid               DD ?
fi_gid               DD ?
fi_kernel_handle     DD ?
fi_serv_handle       DD ?
fi_disc              DB ?
fi_drive             DB ?
fi_part              DB ?
fi_name              DB ?

file_info_struc  ENDS

file_part_req_struc  STRUC

fr_sel           DW ?
fr_link          DW ?

file_part_req_struc  ENDS

file_part_struc  STRUC

ff_sel           DW ?
ff_link          DW ?

file_part_struc  ENDS
