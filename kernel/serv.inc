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
; Shared.INC
; Shared gate macros

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ServGate16    MACRO gate_nr
    db 67h
    db 66h
    db 9Ah
    dd gate_nr
    dw 4
            ENDM

ServGate32    MACRO gate_nr
    db 3Eh
    db 67h
    db 9Ah
    dd gate_nr
    dw 4
            ENDM

ServGate  MACRO gate_nr
IF (size $) EQ 0FF02h
    ServGate16 gate_nr
ELSE
    ServGate32 gate_nr
ENDIF
            ENDM


;;;;;;;;;; REGISTRATION / HOOKS ;;;;;;;;;;;

TestServ  MACRO
    ServGate test_serv_nr
                    ENDM

; OUT EBX              VFS handle
GetVfsHandle  MACRO
    ServGate get_vfs_handle_nr
                    ENDM

; IN  EBX              VFS handle
; OUT EDX:EAX          Sectors
GetVfsSectors  MACRO
    ServGate get_vfs_sectors_nr
                    ENDM

; IN  EBX              VFS handle
; OUT EBX              Req handle
CreateVfsReq  MACRO
    ServGate create_vfs_req_nr
                    ENDM

; IN  EBX              Req handle
CloseVfsReq  MACRO
    ServGate close_vfs_req_nr
                    ENDM

; IN  EBX              Req handle
; IN  EDX:EAX          Start sector
; IN  ECX              Sector count
; OUT EBX              Req #
ReqVfsSectors  MACRO
    ServGate req_vfs_sectors_nr
                    ENDM

; IN  EBX              Req handle
StartVfsReq  MACRO
    ServGate start_vfs_req_nr
                    ENDM
