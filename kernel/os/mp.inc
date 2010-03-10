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
; APIC.INC
; Offsets within APIC selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


APIC_ID = 20h
APIC_VER = 30h
APIC_TPR = 80h
APIC_APR = 90h
APIC_PPR = 0A0h
APIC_EOI = 0B0h
APIC_RRD = 0C0h
APIC_LOG_DEST = 0D0h
APIC_DEST_FORMAT = 0E0h
APIC_SPUR = 0F0h
APIC_ISR = 100h
APIC_TMR = 180h
APIC_IRR = 200h
APIC_ERROR_STATUS = 280h
APIC_CMCI = 2F0h
APIC_ICR = 300h
APIC_TIMER = 320h
APIC_THERMAL = 330h
APIC_PERF = 340h
APIC_LINT0 = 350h
APIC_LINT1 = 360h
APIC_LERROR = 370h
APIC_INIT_COUNT = 380h
APIC_CURR_COUNT = 390h
APIC_DIV_CONFIG = 3E0h

MSR_APIC_ID = 802h
MSR_APIC_VER = 803h
MSR_APIC_TPR = 808h
MSR_APIC_PPR = 80Ah
MSR_APIC_EOI = 80Bh
MSR_APIC_LOG_DEST = 80Dh
MSR_APIC_SPUR = 80Fh
MSR_APIC_ISR = 810h
MSR_APIC_TMR = 818h
MSR_APIC_IRR = 820h
MSR_APIC_ERROR_STATUS = 828h
MSR_APIC_CMCI = 82Fh
MSR_APIC_ICR = 830h
MSR_APIC_TIMER = 832h
MSR_APIC_THERMAL = 833h
MSR_APIC_PERF = 834h
MSR_APIC_LINT0 = 835h
MSR_APIC_LINT1 = 836h
MSR_APIC_LERROR = 837h
MSR_APIC_INIT_COUNT = 838h
MSR_APIC_CURR_COUNT = 839h
MSR_APIC_DIV_CONFIG = 83Eh
MSR_APIC_SELF_IPI = 83Fh
