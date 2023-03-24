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



ServGate    MACRO gate_nr
    db 55h
    db 67h
    db 9Ah
    dd gate_nr
    dw 4
    db 5Dh
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
IsVfsActive  MACRO
    ServGate is_vfs_active_nr
                    ENDM

; IN  EBX              VFS handle
; OUT AH               Disc #
; OUT AL               Part #
GetVfsDiscPart  MACRO
    ServGate get_vfs_disc_part_nr
                    ENDM

; IN  EBX              VFS handle
; OUT EDX:EAX          Sectors
GetVfsSectors  MACRO
    ServGate get_vfs_sectors_nr
                    ENDM

; IN  EBX              VFS handle
; OUT EDX:EAX          Start sector
GetVfsStartSector  MACRO
    ServGate get_vfs_start_sector_nr
                    ENDM

; IN  EBX              VFS handle
; OUT AX               Bytes per sector
GetVfsBytesPerSector  MACRO
    ServGate get_vfs_bytes_per_sector_nr
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
AddVfsSectors  MACRO
    ServGate add_vfs_sectors_nr
                    ENDM

; IN  EBX              Req handle
; IN  EAX              Req #
RemoveVfsSectors  MACRO
    ServGate remove_vfs_sectors_nr
                    ENDM

; IN  EBX              Req handle
; IN  EAX              Req #
; OUT EDX              Offset to buffer
MapVfsReq  MACRO
    ServGate map_vfs_req_nr
                    ENDM

; IN  EBX              Req handle
; IN  EAX              Req #
UnmapVfsReq  MACRO
    ServGate unmap_vfs_req_nr
                    ENDM

; IN  EBX              Req handle
StartVfsReq  MACRO
    ServGate start_vfs_req_nr
                    ENDM

; IN  EBX              Req handle
IsVfsReqDone  MACRO
    ServGate is_vfs_req_done_nr
                    ENDM

; IN  AX               Req handle
; IN  BX               Wait handle
; IN  ECX              Object ID
AddWaitForVfsReq       MACRO
    ServGate add_wait_for_vfs_req_nr
                     ENDM

; IN  EBX              VFS handle
; OUT EDX              Cmd
WaitForVfsCmd  MACRO
    ServGate wait_for_vfs_cmd_nr
                    ENDM

; IN  EBX              VFS handle
ReplyVfsCmd  MACRO    
    ServGate reply_vfs_cmd_nr
                    ENDM

; IN  EBX              VFS handle
; IN  EDX              Flat block address
ReplyVfsBlockCmd  MACRO    
    ServGate reply_vfs_block_cmd_nr
                    ENDM

; IN  EBX              VFS handle
ReplyVfsDataCmd  MACRO    
    ServGate reply_vfs_data_cmd_nr
                    ENDM

; OUT EDX              Flat address
CreateServShareBlock  MACRO    
    ServGate create_serv_share_block_nr
                    ENDM

; IN  EDX              Flat address
FreeServShareBlock  MACRO    
    ServGate free_serv_share_block_nr
                    ENDM

; IN  EDX              Flat address
; OUT EDX              Flat address
GrowServShareBlock  MACRO    
    ServGate grow_serv_share_block_nr
                    ENDM

; IN  EDX              Flat address
; OUT EDX              Flat address
ForkServShareBlock  MACRO    
    ServGate fork_serv_share_block_nr
                    ENDM

; IN  EDX              Flat address
; OUT ES               selector
ServToSystemShareBlock  MACRO    
    ServGate serv_to_system_share_block_nr
                    ENDM

; IN  EBX              VFS handle
; IN  ECX              Req block
; IN  EDX              File info
; OUT BX               Kernel handle
ServOpenVfsFile  MACRO
    ServGate serv_open_file_nr
                    ENDM

; IN  BX               Kernel handle
ServWaitVfsFileQueue  MACRO
    ServGate serv_wait_file_queue_nr
                    ENDM

; IN  BX               Kernel handle
; IN  EDX              Req #
ServFreeVfsFileReq  MACRO
    ServGate serv_free_file_req_nr
                    ENDM

; IN  BX               Kernel handle
ServCloseVfsFile  MACRO
    ServGate serv_close_file_nr
                    ENDM

; IN  EBX              VFS handle
; OUT EAX              Req count
; OUT EBX              Wait count
; OUT ECX              Block count
; OUT EDX              Phys count
ServVfsFileInfo  MACRO
    ServGate serv_file_info_nr
                    ENDM

; IN  BX               Kernel handle
; IN  EDX              Req index
; IN  ECX              Sector count
; IN  ES:EDI           Sector buffer
; OUT EAX              File req handle
ServAddVfsFileReq  MACRO
    ServGate serv_add_file_req_nr
                    ENDM

; IN  EBX              Kernel handle
ReplyVfsPost  MACRO
    ServGate reply_vfs_post_nr
                    ENDM
