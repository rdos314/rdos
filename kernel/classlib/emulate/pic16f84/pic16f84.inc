;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Em486 CPU emulator
; Copyright (C) 1998-2000, Leif Ekblad
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version. The only exception to this rule
; is for commercial usage. For information on commercial usage,
; contact em486@rdos.net.
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
; PIC16F84.INC
; External declarations for pic16f84 emulator module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STATUS_C        = 1
STATUS_DC       = 2
STATUS_Z        = 4
STATUS_PD       = 8
STATUS_TO       = 10h
STATUS_RP0      = 20h
STATUS_RP1      = 40h
STATUS_IRP      = 80h

cpu_struc	STRUC

reg_ind         DB ?
reg_tmr0        DB ?
reg_option      DB ?
reg_pcl         DB ?
reg_status      DB ?
reg_fsr         DB ?
reg_porta       DB ?
reg_trisa       DB ?
reg_portb       DB ?
reg_trisb       DB ?
reg_eedata      DB ?
reg_eeadr       DB ?
reg_eecon1      DB ?
reg_eecon2      DB ?
reg_pclath      DB ?
reg_intcon      DB ?

data_arr        DB 68 DUP(?)
code_arr        DW 1024 DUP(?)
stack_arr       DW 8 DUP(?)
ee_arr          DB 64 DUP(?)

pending_int		DB ?
total_cycles	DD ?
running			DB ?

cpu_struc	ENDS
