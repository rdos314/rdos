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

;;;;;;;;; uACPI ;;;;;;;;;;;;;;;;;;

; OUT EDX:EAX          ACPI physical address
GetUacpiAcpi  MACRO
    ServGate uacpi_get_acpi_nr
                    ENDM

; IN  EDX:EAX          Physical address
; IN  ECX              Size
; OUT EAX              Linear address 
UacpiMap  MACRO
    ServGate uacpi_map_nr
                    ENDM

; IN  EDX              Linear address
; IN  ECX              Size
UacpiUnmap  MACRO
    ServGate uacpi_unmap_nr
                    ENDM

; IN  EDX               Base
; IN  ECX               Size
UacpiEnableIo  MACRO
    ServGate uacpi_enable_io_nr
                    ENDM

; IN  EDX               Base
; IN  ECX               Size
UacpiDisableIo  MACRO
    ServGate uacpi_disable_io_nr
                    ENDM

UacpiStartPci  MACRO
    ServGate uacpi_start_pci_nr
                    ENDM

UacpiHasApic  MACRO
    ServGate uacpi_has_apic_nr
                    ENDM

; IN  EBX              Dev handle
; OUT EDX              Cmd
WaitForDevCmd  MACRO
    ServGate wait_for_dev_cmd_nr
                    ENDM

; IN  EBX              Dev handle
ReplyDevCmd  MACRO    
    ServGate reply_dev_cmd_nr
                    ENDM

; IN  EBX              Dev handle
ReplyDevDataCmd  MACRO    
    ServGate reply_dev_data_cmd_nr
                    ENDM
