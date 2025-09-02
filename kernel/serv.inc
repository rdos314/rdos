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
; SERV.INC
; Server gate macros
;
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

;;;;;;;;; VFS ;;;;;;;;;;;;;;;;;;

; IN AX              Thread ID
ServSignal  MACRO
    ServGate serv_signal_nr
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
IsVfsBusy  MACRO
    ServGate is_vfs_busy_nr
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
; OUT EAX              Part type
GetVfsPartType  MACRO
    ServGate get_vfs_part_type_nr
                    ENDM

; IN  EBX              VFS handle
; IN  EDX              IO buffer
StartVfsIoServer  MACRO
    ServGate start_vfs_io_serv_nr
                    ENDM

; IN  EBX              VFS handle
StopVfsIoServer  MACRO
    ServGate stop_vfs_io_serv_nr
                    ENDM

; IN  EBX              VFS handle
; IN  ESI              FS type
; IN  EDX:EAX          Start sector
; IN  EDI:ESI          Sector count
; OUT EBX              Partition handle
ServLoadPart  MACRO
    ServGate serv_load_part_nr
                    ENDM

; IN  EBX              VFS handle
ServInitParts  MACRO
    ServGate vfs_init_parts_nr
                    ENDM

; IN  EBX              VFS handle
ServPartsDone  MACRO
    ServGate vfs_parts_done_nr
                    ENDM

; IN  EBX              VFS handle
ServStartPart  MACRO
    ServGate serv_start_part_nr
                    ENDM

; IN  EBX              VFS handle
ServStopPart  MACRO
    ServGate serv_stop_part_nr
                    ENDM

; IN  EBX              VFS handle
ServDisablePart  MACRO
    ServGate serv_disable_part_nr
                    ENDM

; IN  EBX              VFS handle
ServClosePart  MACRO
    ServGate serv_close_part_nr
                    ENDM

; IN  EBX              VFS handle
ServFormatPart  MACRO
    ServGate serv_format_part_nr
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
; IN  EDX:EAX          Start sector
; IN  ECX              Sector count
; OUT EBX              Req #
LockVfsSectors  MACRO
    ServGate lock_vfs_sectors_nr
                    ENDM

; IN  EBX              Req handle
; IN  EDX:EAX          Start sector
; IN  ECX              Sector count
; OUT EBX              Req #
ZeroVfsSectors  MACRO
    ServGate zero_vfs_sectors_nr
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
; IN  EDX:EAX          Start sector
; IN  ECX              Sector count
WriteVfsSectors  MACRO
    ServGate write_vfs_sectors_nr
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

; IN  EBX              VFS handle
; IN  EDI              Flat block address
; OUT EDX              Flat buf address
MapVfsCmdBuf  MACRO    
    ServGate map_vfs_cmd_buf_nr
                    ENDM

; IN  EBX              VFS handle
; IN  EDI              Flat block address
; IN  EDX              Flat buf address
UnmapVfsCmdBuf  MACRO    
    ServGate unmap_vfs_cmd_buf_nr
                    ENDM

; IN  EBX              VFS handle
; IN  EDX              Flat address
ServNotifyVfsMsg  MACRO    
    ServGate notify_vfs_msg_nr
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
; IN  EDX              File info
; OUT BX               Kernel handle
ServOpenVfsFile  MACRO
    ServGate serv_open_file_nr
                    ENDM

; IN  EBX              VFS handle
; IN  EDX              Current ptr
ServWaitVfsIoServer  MACRO
    ServGate serv_wait_io_serv_nr
                    ENDM

; IN  BX               Kernel handle
ServUpdateVfsFile  MACRO
    ServGate serv_update_file_nr
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
; IN  EDX:EAX          Position
; IN  ECX              Size
ServNotifyVfsFileReq  MACRO
    ServGate serv_notify_file_req_nr
                    ENDM

; IN  BX               Kernel handle
; IN  ESI              Req index
; IN  EDX:EAX          Sector position
; IN  ECX              Sector count
; IN  ES:EDI           Sector buffer
; OUT ECX              Sector count
ServVfsFileReadReq  MACRO
    ServGate serv_file_read_req_nr
                    ENDM

; IN  BX               Kernel handle
; IN  ESI              Req index
; IN  EDX:EAX          Sector position
; IN  ECX              Sector count
; IN  ES:EDI           Sector buffer
; OUT ECX              Sector count
ServVfsFileWriteReq  MACRO
    ServGate serv_file_write_req_nr
                    ENDM

; IN  BX               Kernel handle
; IN  EDX              Req #
; IN  ESI              Offset sector
; IN  ECX              Sector count
ServUpdateVfsFileReq  MACRO
    ServGate serv_update_file_req_nr
                    ENDM

; IN  BX               Kernel handle
; IN  EDX              Req #
ServDisableVfsFileReq  MACRO
    ServGate serv_disable_file_req_nr
                    ENDM

; IN  BX               Kernel handle
; IN  EDX              Req #
ServFreeVfsFileReq  MACRO
    ServGate serv_free_file_req_nr
                    ENDM

; IN  EBX              Kernel handle
ReplyVfsPost  MACRO
    ServGate reply_vfs_post_nr
                    ENDM
