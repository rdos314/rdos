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
; DOS.INC
; Common types in DOS emulation driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\exec.def

dos_vm_seg      STRUC

indos_flag                      DB ?
critical_flag           DB ?
control_c_flag          DB ?
dos_callback_seg        DW ?
dos_first_dpb           DW ?,?
dos_first_sft           DW ?,?
dos_clock                       DW ?,?
dos_con                         DW ?,?

dos_vm_size                     DB ?

dos_vm_seg      ENDS

dos_process_seg STRUC

dos_mem_section         section_typ <>

dos_process_seg ENDS

psp_seg         STRUC
psp_int20               DW ?
psp_memend              DW ?
psp_res1                DB ?
psp_dispatch    DB 5 DUP(?)
psp_int22               DW ?,?
psp_int23               DW ?,?
psp_int24               DW ?,?
psp_parent              DW ?
psp_handletab   DB 20 DUP(?)
psp_enviro              DW ?
psp_res2                DW ?,?
psp_handlesize  DW ?
psp_handleads   DW ?,?
psp_parent_sp   DW ?
psp_parent_ss   DW ?
psp_ret_code    DW ?
psp_res3                DB 18 DUP(?)
psp_doscall             DW ?
psp_retf                DB ?
psp_res4                DB 9 DUP(?)
psp_fcb1                DB 16 DUP(?)
psp_fcb2                DB 20 DUP(?)
psp_line                DB 80 DUP(?)
psp_seg         ENDS

dos_program_struc  STRUC

dpr_base              program_struc <>

dpr_vm_psp_seg        DW ?
dpr_pm_psp_sel        DW ?
dpr_vm_mem_strat      DW ?
dpr_vm_dta_seg        DW ?
dpr_pm_dta_sel        DW ?
dpr_dta_offset        DD ?
dpr_psp_mode          DB ?
dpr_dta_mode          DB ?
dpr_find_sel          DW ?

dos_program_struc  ENDS
