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
; HINT.INC
; Handle interfaces
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SYS_HANDLE_COUNT      = 1024    ; must be a power of 2

USER_HANDLE_COUNT     = 512
USER_BITMAP_COUNT     = USER_HANDLE_COUNT SHR 5

handle_user_interface    STRUC

;  IN	DS                Handle entry interface
;  OUT  AX                New interface
hui_dup_proc              DD ?,?

;  IN	DS                Handle entry interface
hui_delete_proc           DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX               New linear handle base
hui_clone1_proc           DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX               New linear handle base
;  OUT  AX                New interface
hui_clone2_proc           DD ?,?

;  IN	DS                Handle entry interface
hui_exec1_proc            DD ?,?

;  IN	DS                Handle entry interface
hui_exec2_proc            DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EAX               Map index
;  OUT  EDI               Map linear address
hui_get_map_proc          DD ?,?

;  IN	DS                Handle entry interface
;  IN  EDX:EAX            File position
;  IN  ECX                Size
hui_map_proc              DD ?,?

;  IN	DS                Handle entry interface
hui_update_map_proc       DD ?,?

;  IN	DS                Handle entry interface
;  IN  EDX:EAX            File position
;  IN  ECX                Size
hui_grow_map_proc         DD ?,?

;  IN	DS                Handle entry interface
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  EAX               Read count
hui_poll_proc             DD ?,?

;  IN	DS                Handle entry interface
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  EAX               Read count
hui_read_proc             DD ?,?

;  IN	DS                Handle entry interface
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  EAX               Written count
hui_write_proc            DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Size
hui_get_size_proc         DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX:EAX           Size
hui_set_size_proc         DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Pos
hui_get_pos_proc          DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX:EAX           Pos
hui_set_pos_proc          DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Tics
hui_get_create_time_proc  DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Tics
hui_get_modify_time_proc  DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Tics
hui_get_access_time_proc  DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX:EAX           Tics
hui_set_modify_time_proc  DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EAX               -1 = error, 0 = not eof, 1 = eof
hui_is_eof_proc           DD ?,?

;  IN	DS                Handle entry interface
;  OUT  NC                Device
hui_is_device_proc        DD ?,?

;  IN	DS                Handle entry interface
;  OUT  NC                IP ver4
hui_is_ip4_proc           DD ?,?

;  IN	DS                Handle entry interface
;  OUT  ECX               Bytes in input buffer
hui_input_size_proc       DD ?,?

;  IN	DS                Handle entry interface
;  OUT  ECX               Available bytes in output buffer
hui_output_size_proc      DD ?,?

;  IN	DS                Handle entry interface
hui_free_proc             DD ?,?

hui_io_mode               DW ?
hui_ref_count             DW ?

handle_user_interface    ENDS

handle_kernel_interface    STRUC

;  IN	DS                Handle kernel interface
;  IN   EDX:EAX           Position
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  ECX               Read count
;  OUT  EDX:EAX           New position
hki_read_proc             DD ?,?

;  IN	DS                Handle kernel interface
;  IN   EDX:EAX           Position
;  IN   ES:EDI            Buffer
;  IN   ECX               Size
;  OUT  ECX               Written count
;  OUT  EDX:EAX           New position
hki_write_proc            DD ?,?

;  IN	DS                Handle kernel interface
;  OUT  AX                New user handle interface
hki_dup_proc              DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Size
hki_get_size_proc         DD ?,?

;  IN	DS                Handle entry interface
;  IN   EDX:EAX           Size
hki_set_size_proc         DD ?,?

;  IN	DS                Handle entry interface
;  OUT  EDX:EAX           Time
hki_get_time_proc         DD ?,?

;  IN	DS                Handle kernel interface
hki_free_proc             DD ?,?

hki_ref_count             DW ?
hki_file_sel              DW ?

handle_kernel_interface    ENDS

proc_handle_struc    STRUC

ph_linear        DD ?
ph_section       section_typ <>
ph_bitmap        DD USER_BITMAP_COUNT DUP(?)
ph_sel_arr       DW USER_HANDLE_COUNT DUP(?)
ph_use_arr       DW USER_HANDLE_COUNT DUP(?)
ph_wait_arr      DW USER_HANDLE_COUNT DUP(?)

proc_handle_struc    ENDS
