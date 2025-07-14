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
; ACPI.DEF
; ACPI types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

acpi_header STRUC

acpi_sign       DD ?
acpi_size       DD ?

acpi_rev        DB ?
acpi_sum        DB ?

acpi_oem        DB 6 DUP(?)
acpi_oem_id     DD ?, ?
acpi_oem_rev    DD ?
acpi_cr_id      DD ?
acpi_cr_rev     DD ?

acpi_header ENDS

acpi_table  STRUC

act_next        DW ?
act_size        DW ?
act_sign        DD ?
act_oem_id      DD ?, ?

acpi_table  ENDS

IRQ_TYPE_ISA    = 5Ch
IRQ_TYPE_PCI    = 9Ah

; PCI IRQs active low, edge triggered

apic_struc  STRUC

apic_type       DB ?
apic_len        DB ?

apic_struc  ENDS

apic_processor_struc  STRUC

ap_base         apic_struc <>

ap_acpi_id      DB ?
ap_apic_id      DB ?
ap_flags        DD ?

apic_processor_struc  ENDS

apic_ioapic_struc   STRUC

aio_base        apic_struc <>

aio_apic_id     DB ?
aio_resv        DB ?
aio_phys        DD ?
aio_int_base    DD ?

apic_ioapic_struc   ENDS

apic_override_struc STRUC

ao_base         apic_struc <>

ao_bus          DB ?
ao_source       DB ?
ao_int          DD ?
ao_flags        DW ?

apic_override_struc ENDS

apic_table  STRUC

apic_base       acpi_table <>

apic_phys       DD ?
apic_flags      DD ?

apic_entries    DB ?

apic_table  ENDS
