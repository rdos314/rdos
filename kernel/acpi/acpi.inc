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
    ServGate uacpi_wait_for_cmd_nr
                    ENDM

; IN  EBX              Dev handle
ReplyDevCmd  MACRO    
    ServGate uacpi_reply_cmd_nr
                    ENDM

; IN  EBX              Dev handle
ReplyDevDataCmd  MACRO    
    ServGate uacpi_reply_data_cmd_nr
                    ENDM

; OUT EAX             Pointer to task queue
UacpiGetTaskQueue  MACRO
    ServGate uacpi_get_task_queue_nr
                    ENDM

; IN  EAX             Current index in task queue
UacpiWaitTaskQueue  MACRO
    ServGate uacpi_wait_task_queue_nr
                    ENDM

; IN  EBX            Handle
; IN  ES:EDI         State buffer
UacpiGetThreadState  MACRO
    ServGate uacpi_get_thread_state_nr
                    ENDM

; IN  EBX            Handle
; IN  ES:EDI         Name buffer
UacpiGetThreadName  MACRO
    ServGate uacpi_get_thread_name_nr
                    ENDM

; IN  EBX            Handle
; IN  ES:EDI         256 bit IRQ array
UacpiGetThreadIrqArr  MACRO
    ServGate uacpi_get_thread_irq_arr_nr
                    ENDM

; IN  EBX            Handle
; IN  AL             Irq
UacpiSetThreadIrq  MACRO
    ServGate uacpi_set_thread_irq_nr
                    ENDM

; IN  EBX            Handle
; OUT EAX            Process
UacpiGetThreadProcess  MACRO
    ServGate uacpi_get_thread_process_nr
                    ENDM

; OUT EAX            Handle
UacpiGetThread  MACRO
    ServGate uacpi_get_thread_nr
                    ENDM

; OUT EAX            Core count
UacpiGetCoreCount  MACRO
    ServGate uacpi_get_core_count_nr
                    ENDM

; IN  EBX            Core #
UacpiStartCore  MACRO
    ServGate uacpi_start_core_nr
                    ENDM

; IN  EBX            Core #
UacpiStopCore  MACRO
    ServGate uacpi_stop_core_nr
                    ENDM

; IN  EBX           Thread handle
; IN  EAX           Core #
UacpiSetThreadCore  MACRO
    ServGate uacpi_set_thread_core_nr
                    ENDM
