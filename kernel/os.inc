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
; OS.INC
; OS gate macros

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; offsets in trapgate, vmode
;
vm_gs       EQU 38
vm_fs       EQU 34
vm_ds       EQU 30
vm_es       EQU 26
vm_ss       EQU 22
vm_esp      EQU 18
vm_eflags       EQU 14
vm_cs       EQU 10
vm_eip      EQU 6
vm_err      EQU 2
vm_bp       EQU 0
vm_eax      EQU -4
vm_ebx      EQU -8
pm_ds       EQU -10
pm_call     EQU -12

section_typ     STRUC
cs_value    DW ?
cs_list     DW ?
section_typ     ENDS

read_write_section_typ  STRUC
ssync_value         DW ?
ssync_list          DW ?
sread_value         DW ?
swrite_value    DW ?
swrite_list         DW ?
read_write_section_typ  ENDS

pause   MACRO
    db 0F3h
    db 90h
    ENDM
    
cpuid   MACRO
    db 0Fh
    db 0A2h
    ENDM

rdtsc   MACRO
    db 0Fh
    db 31h
    ENDM

rdmsr   MACRO
    db 0Fh
    db 32h
    ENDM

wrmsr   MACRO
    db 0Fh
    db 30h
    ENDM
    
Retf16  MACRO
    db 66h
    db 0CBh
        ENDM

Retf32  MACRO
    db 66h
    db 0CBh
        ENDM
    
Retf16Pop  MACRO count
    db 66h
    db 0CAh
    dw count
        ENDM

Retf32Pop  MACRO count
    db 66h
    db 0CAh
    dw count
        ENDM

Callf16 MACRO   sel,offs
    db 66h
    db 9Ah
    dd sel SHL 16 + OFFSET offs
        ENDM

Callf32 MACRO   sel,offs
    db 66h
    db 9Ah
    dw OFFSET offs
    dw 0
    dw sel
        ENDM

OsGate16    MACRO gate_nr
    db 67h
    db 66h
    db 9Ah
    dd gate_nr
    dw 2
            ENDM

OsGate32    MACRO gate_nr
    db 3Eh
    db 67h
    db 9Ah
    dd gate_nr
    dw 2
            ENDM

OsGate  MACRO gate_nr
IF (size $) EQ 0FF02h
    OsGate16 gate_nr
ELSE
    OsGate32 gate_nr
ENDIF
            ENDM

;;;;;;;;;; REGISTRATION / HOOKS ;;;;;;;;;;;

;       AX          GATE NUMBER
;       DS:ESI  GATE CALL ADDRESS
;       ES:EDI  GATE NAME ADDRESS
RegisterOsGate  MACRO
    OsGate register_osgate_nr
                    ENDM

;       AX          GATE NUMBER
IsValidOsGate   MACRO
    OsGate is_valid_osgate_nr
                    ENDM

;       AX          GATE NUMBER
;       DX          SEGMENT TRANSFER
;       DS:ESI  GATE CALL ADDRESS
;       ES:EDI  GATE NAME ADDRESS
RegisterBimodalUserGate MACRO
    OsGate register_bimodal_usergate_nr
                        ENDM

;       AX          GATE NUMBER
;       DX          SEGMENT TRANSFER
;       DS:EBX  16-BIT GATE CALL ADDRESS
;       DS:ESI  32-BIT GATE CALL ADDRESS
;       ES:EDI  GATE NAME ADDRESS
RegisterOldUserGate    MACRO
    OsGate register_old_usergate_nr
                        ENDM

;       AX          GATE NUMBER
;       DX          SEGMENT TRANSFER
;       DS:ESI  16-BIT GATE CALL ADDRESS
;       ES:EDI  GATE NAME ADDRESS
RegisterOldUserGate16      MACRO
    OsGate register_old_usergate16_nr
                        ENDM

;       AX          GATE NUMBER
;       DX          SEGMENT TRANSFER
;       DS:EBX  16-BIT GATE CALL ADDRESS
;       DS:ESI  32-BIT GATE CALL ADDRESS
;       ES:EDI  GATE NAME ADDRESS
RegisterUserGate    MACRO
    OsGate register_usergate_nr
                        ENDM

;       AX          GATE NUMBER
;       DX          SEGMENT TRANSFER
;       DS:ESI  16-BIT GATE CALL ADDRESS
;       ES:EDI  GATE NAME ADDRESS
RegisterUserGate16      MACRO
    OsGate register_usergate16_nr
                        ENDM

;       AX          GATE NUMBER
;       DX          SEGMENT TRANSFER
;       DS:ESI  32-BIT GATE CALL ADDRESS
;       ES:EDI  GATE NAME ADDRESS
RegisterUserGate32      MACRO
    OsGate register_usergate32_nr
                        ENDM

;       AX          GATE NUMBER
;       DS:ESI  V86 GATE CALL ADDRESS
;       ES:EDI  GATE NAME ADDRESS
RegisterUserGateV86     MACRO
    OsGate register_usergate_v86_nr
                        ENDM

;       AL          Exception #
EmulateOpcode   MACRO
    OsGate emulate_opcode_nr
                    ENDM

;;;;;;;; DESCRIPTORS ;;;;;;;;;;;;

;       BX          GDT DESCRIPTOR
AllocateGdt     MACRO
    OsGate allocate_gdt_nr
                    ENDM

;       BX          GDT DESCRIPTOR
FreeGdt MACRO
    OsGate free_gdt_nr
                    ENDM

;       BX          LDT DESCRIPTOR
AllocateLdt     MACRO
    OsGate allocate_ldt_nr
                    ENDM

;       BX          LDT DESCRIPTOR
FreeLdt MACRO
    OsGate free_ldt_nr
                    ENDM

;       CX          ANTAL
;       BX          LDT DESCRIPTOR
AllocateMultipleLdt     MACRO
    OsGate allocate_multiple_ldt_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
GetSelectorBaseSize     MACRO
    OsGate get_selector_base_size_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
CreateDataSelector16    MACRO
    OsGate create_data_sel16_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
CreateDataSelector32    MACRO
    OsGate create_data_sel32_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
CreateAliasSelector16   MACRO
    OsGate create_alias_sel16_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
CreateCodeSelector16    MACRO
    OsGate create_code_sel16_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
CreateCodeSelector32    MACRO
    OsGate create_code_sel32_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
CreateConformSelector16 MACRO
    OsGate create_conform_sel16_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
CreateConformSelector32 MACRO
    OsGate create_conform_sel32_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       CX          LIMIT
CreateLdtSelector       MACRO
    OsGate create_ldt_sel_nr
                    ENDM

;       BX          DESCRIPTOR
;       EDX         BASE
;       ECX         LIMIT
CreateTssSelector       MACRO
    OsGate create_tss_sel_nr
                    ENDM

;       BX          DESCRIPTOR
;       DS:SI   ENTRY POINT
;       CL          16-BIT WORDS TO MOVE
CreateCallGateSelector16    MACRO
    OsGate create_call_gate_sel16_nr
                            ENDM

;       BX          DESCRIPTOR
;       DS:ESI  ENTRY POINT
;       CL          32-BIT WORDS TO MOVE
CreateCallGateSelector32    MACRO
    OsGate create_call_gate_sel32_nr
                            ENDM

;       BX          DESCRIPTOR
;       DX          TSS SELECTOR
CreateTaskGateSelector  MACRO
    OsGate create_task_gate_sel_nr
                            ENDM

;       AL          INT #
;       BL          DPL
;       DS:ESI  ENTRY POINT
CreateIntGateSelector   MACRO
    OsGate create_int_gate_sel_nr
                            ENDM

;       AL          INT #
;       BL          DPL
;       DS:ESI  ENTRY POINT
CreateTrapGateSelector  MACRO
    OsGate create_trap_gate_sel_nr
                            ENDM

;       AX      SELECTOR
;       NC      EAX     SEGEMENT
;       CY      EAX = F000
SelectorToSegment       MACRO
    OsGate selector_to_segment_nr
                    ENDM

;       BX      SEGMENT / SELECTOR
SegmentToSelector       MACRO
    OsGate segment_to_selector_nr
                    ENDM

;       ES          SELECTOR
FreeSelector    MACRO
    OsGate free_selector_nr
                        ENDM

;       BP          STACK WITH EXCEPTION INFO
SegmentNotPresent       MACRO
    OsGate segment_not_present_nr
                    ENDM

;;;;;;;;; PAGING ;;;;;;;;;;;;;;;;;;;;

;       EDX         LINEAR ADDRESS
;       EAX         PAGE ENTRY
GetPhysicalPage MACRO
    OsGate get_physical_page_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EAX         PAGE ENTRY
SetPhysicalPage MACRO
    OsGate set_physical_page_nr
                    ENDM

;       BX          TRèD
;       EDX         LINEAR ADDRESS
;       EAX         PAGE ENTRY
GetThreadPhysicalPage   MACRO
    OsGate get_thread_physical_page_nr
                    ENDM

;       BX          TRèD
;       EDX         LINEAR ADDRESS
;       EAX         PAGE ENTRY
SetThreadPhysicalPage   MACRO
    OsGate set_thread_physical_page_nr
                    ENDM

;       DX:ESI  ADDRESS TO READ
;       BX          TRèD
;       NC          VALID
;       AL          DATA OR ERROR REASON
ReadThreadSelector      MACRO
    OsGate read_thread_selector_nr
                    ENDM

;       DX:ESI  ADDRESS TO WRITE
;       BX          TRèD
;       NC          VALID
;       AL          DATA TO WRITE
WriteThreadSelector     MACRO
    OsGate write_thread_selector_nr
                    ENDM

;       DX:ESI  ADDRESS TO READ
;       BX          TRèD
;       NC          VALID
;       AL          DATA OR ERROR REASON
ReadThreadSegment       MACRO
    OsGate read_thread_segment_nr
                    ENDM

;       DX:ESI  ADDRESS TO WRITE
;       BX          TRèD
;       NC          VALID
;       AL          DATA TO WRITE
WriteThreadSegment      MACRO
    OsGate write_thread_segment_nr
                    ENDM

;       EAX         ANTAL BYTE
;       EDX         LINEAR BASE ADDRESS
SetPageEmulate  MACRO
    OsGate set_page_emulate_nr
                    ENDM

;       EAX         ANTAL BYTE
;       EDX         LINEAR BASE ADDRESS
;       ES:DI   CALLBACK ROUTINE
HookPage    MACRO
    OsGate hook_page_nr
                    ENDM

;       EAX         ANTAL BYTE
;       EDX         LINEAR BASE ADDRESS
UnhookPage      MACRO
    OsGate unhook_page_nr
                    ENDM

;;;;;;;;;;; LINEAR MEMORY MANAGEMENT ;;;;;;;;

;       EAX         Byte count
;       ES          SELECTOR
AllocateGlobalMem       MACRO
    OsGate allocate_global_mem_nr
                    ENDM

;       EAX         Byte count
;       ES          SELECTOR
AllocateSmallGlobalMem  MACRO
    OsGate allocate_small_global_mem_nr
                    ENDM

;       EAX     Byte count
;       ES      LINEAR BASE ADDRESS
AllocateSmallMem    MACRO
    OsGate allocate_small_mem_nr
                    ENDM

;       EAX     Byte count
;       ES      LDT SELECTOR WITH KERNEL ONLY ACCESS
AllocateSmallKernelMem  MACRO
    OsGate allocate_small_kernel_mem_nr
                    ENDM

;       EAX     ANTAL BYTE
;       ES      LINEAR BASE ADDRESS
AllocateBigMem  MACRO
    OsGate allocate_big_mem_nr
                    ENDM

;       EAX     ANTAL BYTE
;       EDX     LINEAR BASE ADDRESS
;       CX      ANTAL SIDOR
AllocateBigLinear       MACRO
    OsGate allocate_big_linear_nr
                    ENDM

;       EAX     ANTAL BYTE
;       EDX     LINEAR BASE ADDRESS
AllocateSmallLinear     MACRO
    OsGate allocate_small_linear_nr
                    ENDM

;       EAX     ANTAL BYTE
;       EDX     LINEAR BASE ADDRESS
AllocateLocalLinear     MACRO
    OsGate allocate_local_linear_nr
                    ENDM

;       EAX     Bytes
;       EDX     LINEAR BASE ADDRESS
AllocateDebugLocalLinear    MACRO
    OsGate allocate_debug_local_linear_nr
                    ENDM

;       EAX     ANTAL BYTE
;       EDX     LINEAR BASE ADDRESS
ReserveLocalLinear      MACRO
    OsGate reserve_local_linear_nr
                    ENDM

;       EAX     ANTAL BYTE
;       EDX     LINEAR BASE ADDRESS
AllocateVMLinear    MACRO
    OsGate allocate_vm_linear_nr
                    ENDM

;       ECX         SIZE
;       EDX         LINEAR BASE ADDRESS
FreeLinear      MACRO
    OsGate free_linear_nr
                    ENDM

;       EAX         NEW SIZE
;       ECX         OLD SIZE
;       EDX         LINEAR BASE ADDRESS
ResizeLinear    MACRO
    OsGate resize_linear_nr
                    ENDM

;       EAX         ANTAL BYTES
UsedBigLinear   MACRO
    OsGate used_big_linear_nr
                    ENDM

;       EAX         ANTAL BYTES
UsedSmallLinear MACRO
    OsGate used_small_linear_nr
                    ENDM

;       EAX         ANTAL BYTES
UsedLocalLinearThread   MACRO
    OsGate used_local_linear_thread_nr
                    ENDM

;       EAX         ANTAL BYTES
;       BX          SELECTOR IN
;       ES          SELECTOR UT
AllocateFixedProcessMem MACRO
    OsGate allocate_fixed_process_mem_nr
                    ENDM

;       EAX         ANTAL BYTES
;       BX          SELECTOR IN
;       ES          SELECTOR UT
AllocateFixedSystemMem  MACRO
    OsGate allocate_fixed_system_mem_nr
                    ENDM

;       EAX         ANTAL BYTES
;       EDX         LINJéR ADDRESS
AllocateProcessLinear   MACRO
    OsGate allocate_process_linear_nr
                    ENDM

;       EAX         ANTAL BYTES
;       EDX         LINJéR ADDRESS
AllocateSystemLinear    MACRO
    OsGate allocate_system_linear_nr
                    ENDM

;       EAX         ANTAL BYTES
;       EDX         LINJéR ADDRESS
AllocateFixedVMLinear   MACRO
    OsGate allocate_fixed_vm_linear_nr
                    ENDM

;;;;;;;;;;;;; PHYSICAL MEMORY MANAGEMENT ;;;;;;;;;;

;       EAX         FYSISK ADDRESS
AllocatePhysical    MACRO
    OsGate allocate_physical_nr
                    ENDM

;       EAX         FYSISK ADDRESS
AllocateDmaPhysical     MACRO
    OsGate allocate_dma_physical_nr
                    ENDM

;       EAX         FYSISK ADDRESS
FreePhysical    MACRO
    OsGate free_physical_nr
                    ENDM

;       IN  ECX     Number of pages
;       OUT EAX     Physical base address
AllocateMultiplePhysical    MACRO
    OsGate allocate_multiple_physical_nr
                    ENDM

;       ES:EDI      Swap callback
;       AL  Swap level (0 = highest priority, 15 = lowest priority)
RegisterSwapProc    MACRO
    OsGate register_swap_proc_nr
                    ENDM

;;;;;;;;;;; Timers ;;;;;;;;;;;;;;;;

;       ES:EDI      Callback
;       EDX:EAX     Expire time
;       BX              Selector ID (OWNER)
;       ECX             Data to callback
StartTimer      MACRO
    OsGate start_timer_nr
                    ENDM

;       BX              Selector ID (OWNER)
StopTimer       MACRO
    OsGate stop_timer_nr
                    ENDM

;;;;;;;;;;; Processor ;;;;;;;;;;;;;;;;

;   OUT EDX     APIC ID
GetApicId    MACRO
    OsGate get_apic_id_nr
                        ENDM

;   IN  ES:DI   Callback for get processor
;   OUT AX      Processor #
;   OUT ES      Processor selector
CreateProcessor    MACRO
    OsGate create_processor_nr
                        ENDM

;   OUT FS      Processor selector
GetProcessor    MACRO
    OsGate get_processor_nr
                        ENDM

;   IN  AX      Processor #
;   OUT FS      Processor selector
GetProcessorNumber    MACRO
    OsGate get_processor_num_nr
                        ENDM

StartProcessor    MACRO
    OsGate start_processor_nr
                        ENDM

;   IN  FS      Processor selector
ResumeProcessor    MACRO
    OsGate resume_processor_nr
                        ENDM

;   IN  FS      Processor selector
IsProcessorBlocked    MACRO
    OsGate is_processor_blocked_nr
                        ENDM

;   IN  FS      Processor selector
UnblockProcessor    MACRO
    OsGate unblock_processor_nr
                        ENDM

DoUnblockProcessor    MACRO
    OsGate do_unblock_processor_nr
                        ENDM

;   IN  FS      Processor selector
SendNmi    MACRO
    OsGate send_nmi_nr
                ENDM

;   IN  AL      Int #
;   IN  FS      Processor selector
SendInt    MACRO
    OsGate send_int_nr
                ENDM

StartApCores    MACRO
    OsGate start_ap_cores_nr
                    ENDM

;;;;;;;;;;; Signal & waits ;;;;;;;;;;;;;;;;

ClearSignal     MACRO
    OsGate clear_signal_nr
                    ENDM

;       BX              THREAD TO SIGNAL
Signal  MACRO
    OsGate signal_nr
                    ENDM

WaitForSignal   MACRO
    OsGate wait_for_signal_nr
                    ENDM

WaitForSignalWithTimeout    MACRO
    OsGate wait_for_signal_timeout_nr
                    ENDM

; IN  AX      Extra bytes needed in wait object
; IN  BX      Wait handle
; IN  ES:EDI  Method table (init, abort, peek)
; OUT ES      Wait object
AddWait MACRO
    OsGate add_wait_nr
                    ENDM

; IN  ES      Wait object
SignalWait      MACRO
    OsGate signal_wait_nr
                    ENDM

;;;;;;;;;;; Critical section ;;;;;;;;;;;;;;;;

InitSection     MACRO section
    mov section.cs_value,0
    mov section.cs_list,0
                        ENDM

EnterSection    MACRO section
    LOCAL enter_section_donep
    pushf
    lock sub section.cs_value,1
    jc enter_section_donep
    push esi
    lea esi,section
    OsGate enter_section_nr
    pop esi
enter_section_donep:
    popf
                        ENDM

LeaveSection    MACRO section
    LOCAL leave_section_donep
    pushf
    lock add section.cs_value,1
    jc leave_section_donep
    push esi
    lea esi,section
    OsGate leave_section_nr
    pop esi
leave_section_donep:
    popf
                        ENDM

InitReadWriteSection    MACRO section
    mov section.ssync_value,0
    mov section.ssync_list,0
    mov section.sread_value,0
    mov section.swrite_value,0
    mov section.swrite_list,0
                        ENDM

EnterReadSection    MACRO section
    LOCAL enter_sync_ok,enter_read_ok,enter_read_done
    pushf
    cli
    lock sub section.ssync_value,1
    jc enter_sync_ok
    push esi
    mov esi,OFFSET section.ssync_value
    OsGate enter_section_nr
    pop esi
enter_sync_ok:
    lock sub section.sread_value,1
    jnc enter_read_ok
    lock sub section.swrite_value,1
    jc enter_read_ok
    push esi
    mov esi,OFFSET section.swrite_value
    OsGate enter_section_nr
    pop esi
enter_read_ok:
    lock add section.ssync_value,1
    jc enter_read_done
    push esi
    mov esi,OFFSET section.ssync_value
    OsGate leave_section_nr
    pop esi
enter_read_done:
    popf
                        ENDM

LeaveReadSection    MACRO section
    LOCAL leave_sync_ok,leave_read_ok,leave_read_done
    pushf
    cli
    lock sub section.ssync_value,1
    jc leave_sync_ok
    push esi
    mov esi,OFFSET section.ssync_value
    OsGate enter_section_nr
    pop esi
leave_sync_ok:
    lock add section.sread_value,1
    jnc leave_read_ok
    lock add section.swrite_value,1
    jc leave_read_ok
    push esi
    mov esi,OFFSET section.swrite_value
    OsGate leave_section_nr
    pop esi
leave_read_ok:
    lock add section.ssync_value,1
    jc leave_read_done
    push esi
    mov esi,OFFSET section.ssync_value
    OsGate leave_section_nr
    pop esi
leave_read_done:
    popf
                        ENDM

EnterWriteSection       MACRO section
    LOCAL enter_section_done
    pushf
    cli
    lock sub section.swrite_value,1
    jc enter_section_done
    push esi
    mov esi,OFFSET section.swrite_value
    OsGate enter_section_nr
    pop esi
enter_section_done:
    popf
                        ENDM

LeaveWriteSection       MACRO section
    LOCAL leave_section_done
    pushf
    cli
    lock add section.swrite_value,1
    jc leave_section_done
    push esi
    mov esi,OFFSET section.swrite_value
    OsGate leave_section_nr
    pop esi
leave_section_done:
    popf
                        ENDM

;;;;;;;;;;; MULTITASKING ;;;;;;;;;;;;;;;;

;       ES:EDI       ADDRESS TILL CALLBACK
HookInitTasking MACRO
    OsGate hook_init_tasking_nr
                    ENDM

;       ES:EDI       ADDRESS TILL CALLBACK
HookCreateProcess       MACRO
    OsGate hook_create_process_nr
                    ENDM

;       ES:EDI       ADDRESS TILL CALLBACK
HookTerminateProcess    MACRO
    OsGate hook_terminate_process_nr
                    ENDM

;       ES:EDI       ADDRESS TILL CALLBACK
HookCreateThread    MACRO
    OsGate hook_create_thread_nr
                    ENDM

;       ES:EDI       ADDRESS TILL CALLBACK
HookTerminateThread     MACRO
    OsGate hook_terminate_thread_nr
                    ENDM

;       ES:EDI       PROCEDURE TO CALL
HookState       MACRO
    OsGate hook_state_nr
                    ENDM

;   OUT EAX      Update tics
StartSysTimer    MACRO
    OsGate start_sys_timer_nr
                        ENDM

;   IN  AX      Tic count
ReloadSysTimer    MACRO
    OsGate reload_sys_timer_nr
                        ENDM

EnterInt    MACRO
    OsGate enter_int_nr
                        ENDM

LeaveInt    MACRO
    OsGate leave_int_nr
                        ENDM

LockTask    MACRO
    OsGate lock_task_nr
                        ENDM

UnlockTask    MACRO
    OsGate unlock_task_nr
                        ENDM

;    DS:SI       Thread
;    AX          Status to thread
Wake MACRO
    OsGate wake_thread_nr
                    ENDM

;    DS:DI      Sleep list
;    AX         Status from wake
Sleep    MACRO
    OsGate sleep_thread_nr
                    ENDM

;       AL          PRIORITET
;       AH          MODE, 0=PM, 1=VM
;       ECX         STACK SIZE
;       DS:ESI      ADDRESS TO START AT
;       ES:EDI      PROCESS NAME
CreateProcess    MACRO
    OsGate create_process_nr
                        ENDM

; IN  BX    Thread #
; OUT BX    Thread sel
ThreadToSel     MACRO
    OsGate thread_to_sel_nr
            ENDM

;;;;;;;;;;; Crash handler ;;;;;;;;;;;;;;;;

CrashGate       MACRO
    OsGate crash_gate_nr
                    ENDM

;   SS:BP       Fault stack
CrashFault      MACRO
    OsGate crash_fault_nr
                    ENDM

;   DS      TSS alias
CrashTss    MACRO
    OsGate crash_tss_nr
                    ENDM

;;;;;;;;;;; Debugger ;;;;;;;;;;;;;;;;

;   SS:BP     Exception stack
DebugException    MACRO
    OsGate debug_exception_nr
                        ENDM

;   SS:BP     Exception stack
LockedDebugException    MACRO
    OsGate locked_debug_exception_nr
                        ENDM

DebugBreak      MACRO
    OsGate debug_break_nr
                    ENDM

; OUT AX           Thread ID
GetDebugThreadSel MACRO
    OsGate get_debug_thread_sel_nr
                        ENDM

;;;;;;; INTERRUPTS & EXCEPTIONS ;;;;;;;;

SimSti  MACRO
    OsGate sim_sti_nr
                    ENDM

SimCli  MACRO
    OsGate sim_cli_nr
                    ENDM

;       AX          FLAGS
GetFlags    MACRO
    OsGate sim_get_flags_nr
                    ENDM

;       AX          FLAGS
SetFlags    MACRO
    OsGate sim_set_flags_nr
                    ENDM

;       BX              Stack selector
GetExceptionStack16     MACRO
    OsGate get_exception_stack16_nr
                    ENDM

;       BX              Stack selector
GetExceptionStack32     MACRO
    OsGate get_exception_stack32_nr
                    ENDM

;       BX              Offset to context on locked stack
SaveContext     MACRO
    OsGate save_context_nr
                    ENDM

;       BX              Offset to context on locked stack
RestoreContext  MACRO
    OsGate restore_context_nr
                    ENDM

;       Stack       Address of real mode code to call
CallVM  MACRO
    OsGate call_vm_nr
                    ENDM

;       Stack       Address of protected mode ring 3 code to call
CallPM16    MACRO
    OsGate call_pm16_nr
                    ENDM

;       Stack       Address of protected mode ring 3 code to call
CallPM32    MACRO
    OsGate call_pm32_nr
                    ENDM

;       AL           INT NUMMER
;       DS:EDI       ADDRESS TILL CALLBACK
HookVMInt       MACRO
    OsGate hook_vm_int_nr
                    ENDM

;       AL           INT NUMMER
;       DS:EDI       ADDRESS TILL CALLBACK
HookProt16Int   MACRO
    OsGate hook_pm16_int_nr
                    ENDM

;       AL          INT NUMMER
;       DS:EDI      ADDRESS TILL CALLBACK
HookProt32Int   MACRO
    OsGate hook_pm32_int_nr
                    ENDM

;       ES:EDI       ADDRESS TILL CALLBACK
;       AL           INT NUMMER
HookException   MACRO
    OsGate hook_exception_nr
                    ENDM

;       ES:EDI       HANDLER ADDRESS
;       AL              INT NUMMER
HookGetVMInt    MACRO
    OsGate hook_get_vm_int_nr
                    ENDM

;       ES:EDI       HANDLER ADDRESS
;       AL              INT NUMMER
HookSetVMInt    MACRO
    OsGate hook_set_vm_int_nr
                    ENDM

;       ES:EDI       HANDLER ADDRESS
;       AL              INT NUMMER
HookGetProt16Int    MACRO
    OsGate hook_get_pm16_int_nr
                    ENDM

;       ES:EDI       HANDLER ADDRESS
;       AL              INT NUMMER
HookSetProt16Int    MACRO
    OsGate hook_set_pm16_int_nr
                    ENDM

;       ES:EDI      HANDLER ADDRESS
;       AL              INT NUMMER
HookGetProt32Int    MACRO
    OsGate hook_get_pm32_int_nr
                    ENDM

;       ES:EDI      HANDLER ADDRESS
;       AL              INT NUMMER
HookSetProt32Int    MACRO
    OsGate hook_set_pm32_int_nr
                    ENDM

ReflectException    MACRO
    OsGate reflect_exception_nr
                    ENDM

ReflectPMToVM   MACRO
    OsGate reflect_pm_to_vm_nr
                    ENDM

;       Stack   Int #
V86BiosInt      MACRO
    OsGate v86_bios_int_nr
                    ENDM

;       AL              16 or 32 bit app
SetBitness      MACRO
    OsGate set_bitness_nr
                    ENDM

;;;;;;;;;;;;; IO ;;;;;;;;;;;;;;;;;;;;

;       ES:EDI       ADDRESS TILL CALLBACK
;       DX              PORT NUMMER
HookIn  MACRO
    OsGate hook_in_nr
                    ENDM

;       ES:EDI       ADDRESS TILL CALLBACK
;       DX              PORT NUMMER
HookOut MACRO
    OsGate hook_out_nr
                    ENDM

;;;;;;;;;; IRQ ;;;;;;;;;;;;;;;;;;;

;       AL              IRQ NR
SendEoi MACRO
    OsGate send_eoi_nr
                    ENDM

;       AL              IRQ NR
IsIrqFree       MACRO
    OsGate is_irq_free_nr
                    ENDM

; OUT EAX     Active IRQ lines
DisableAllIrq   MACRO
    OsGate disable_all_irq_nr
                    ENDM

;       AL              IRQ NR
;       DS              DATA PASSED TO HANDLER
;       ES:EDI       HANDLER ADDRESS
RequestPrivateIrqHandler    MACRO
    OsGate request_private_irq_handler_nr
                    ENDM

;       AL              IRQ NR
ReleasePrivateIrqHandler    MACRO
    OsGate release_private_irq_handler_nr
                    ENDM

;       AL              IRQ NR
;       DS              DATA PASSED TO HANDLER
;       ES:EDI       HANDLER ADDRESS
RequestSharedIrqHandler MACRO
    OsGate request_shared_irq_handler_nr
                    ENDM

SetupIrqDetect  MACRO
    OsGate setup_irq_detect_nr
                    ENDM

;   AX      Detected IRQs
PollIrqDetect   MACRO
    OsGate poll_irq_detect_nr
                    ENDM

;;;;;;;;; TIME & DATE ;;;;;;;;;;;;;

;       EDX:EAX     SYSTEM TIME
SetSystemTime   MACRO
    OsGate set_system_time_nr
                    ENDM

NotifyTimeDrift MACRO
    OsGate notify_time_drift_nr
                    ENDM

;;;;;;;;;; HANDLES ;;;;;;;;;;;;;;;;;;

; IN  AX        Signature
; IN  ES:EDI    Delete handle callback
RegisterHandle  MACRO
    OsGate register_handle_nr
                    ENDM

; IN  AX        Signature
; IN  CX        Size of data
; OUT DS:EBX    Handle data
AllocateHandle  MACRO
    OsGate allocate_handle_nr
                    ENDM

; IN  DS:EBX    Handle data
FreeHandle      MACRO
    OsGate free_handle_nr
                    ENDM

; IN  AX        Signature
; IN  BX        Handle
; OUT DS:EBX    Handle data
DerefHandle     MACRO
    OsGate deref_handle_nr
                    ENDM

; OUT DS    Cloned handle sel
; OUT ES    Cloned handle mem sel
CloneHandleMem  MACRO
    OsGate clone_handle_mem_nr
                    ENDM

;;;;;;;;;;;;;; Application / process  ;;;;;;;;;;;;;;;;;;

;       ES:EDI       ADDRESS TO CALLBACK
HookOpenApp     MACRO
    OsGate hook_open_app_nr
                    ENDM

;       ES:EDI       ADDRESS TO CALLBACK
HookCloseApp    MACRO
    OsGate hook_close_app_nr
                    ENDM

;       ES:EDI       HANDLER ADDRESS
HookLoadExe     MACRO
    OsGate hook_load_exe_nr
                    ENDM

OpenApp MACRO
    OsGate open_app_nr
                    ENDM

CloseApp    MACRO
    OsGate close_app_nr
                    ENDM

;    ES     Clone selector
CloneApp    MACRO
    OsGate clone_app_nr
                    ENDM

; IN  ES    Module selector
SetModule       MACRO
    OsGate set_module_nr
                    ENDM

ResetModule     MACRO
    OsGate reset_module_nr
                    ENDM

; IN  ES    Module selector
CreateModule    MACRO
    OsGate create_module_nr
                    ENDM

; IN  ES    Module selector
FreeModule      MACRO
    OsGate free_module_nr
                    ENDM

; IN  BX    Module handle
; OUT BX    Lib sel
DerefModuleHandle       MACRO
    OsGate deref_module_handle_nr
                    ENDM

; IN  BX    Lib sel
; OUT BX    Module handle
AliasModuleHandle       MACRO
    OsGate alias_module_handle_nr
                    ENDM

; IN  ES    Options selector
SetOptions      MACRO
    OsGate set_options_nr
                    ENDM

; IN  AX    Lib sel
; IN  DX    Process descriptor
; OUT BX    Process handle
CreateProcHandle    MACRO
    OsGate create_proc_handle_nr
                    ENDM

; IN  BX    Process handle
; OUT AX    Lib sel
; OUT DX    Process descriptor
DerefProcHandle MACRO
    OsGate deref_proc_handle_nr
                    ENDM

;;;;;;;;;;;;; Dos ;;;;;;;;;;;;;;;;;;;

;       EAX     Bytes
;       NC      EDX     linear address
;       CY      AL      Error code
AllocateDosLinear       MACRO
    OsGate allocate_dos_linear_nr
                    ENDM

;       EDX             LINEAR BASE ADDRESS
;       CY      AL      Error code
FreeDosLinear   MACRO
    OsGate free_dos_linear_nr
                    ENDM

;       EAX             NEW SIZE
;       EDX             LINEAR BASE ADDRESS
;       CY      AL      Error code
ResizeDosLinear MACRO
    OsGate resize_dos_linear_nr
                    ENDM

;       EAX         Bytes available
;       EDX         Largest block
AvailableDosLinear      MACRO
    OsGate available_dos_linear_nr
                    ENDM

QueryXms    MACRO
    OsGate query_xms_nr
                    ENDM

QueryDpmi       MACRO
    OsGate query_dpmi_nr
                    ENDM

QueryDpmi16     MACRO
    OsGate query_dpmi16_nr
                    ENDM

EnterDpmi       MACRO
    OsGate enter_dpmi_nr
                    ENDM

EnterDos16      MACRO
    OsGate enter_dos16_nr
                    ENDM

EnterDos32      MACRO
    OsGate enter_dos32_nr
                    ENDM

;       BX              Offset in BDA
;       AL              Value
GetBiosData     MACRO
    OsGate get_bios_data_nr
                    ENDM

;       BX              Offset in BDA
;       AL              Value
SetBiosData     MACRO
    OsGate set_bios_data_nr
                    ENDM

;       BX          Offset in BDA
;       ES:EDI      Handler callback
HookGetBiosData MACRO
    OsGate hook_get_bios_data_nr
                    ENDM

;       BX          Offset in BDA
;       ES:EDI      Handler callback
HookSetBiosData MACRO
    OsGate hook_set_bios_data_nr
                    ENDM

; IN  BX        File handle
; IN  DS:ESI    Program name
; IN  ES:EDI    Command line
LoadDosExe      MACRO
    OsGate load_dos_exe_nr
                    ENDM

;       ES:EDI       HANDLER ADDRESS
HookLoadDosExe  MACRO
    OsGate hook_load_dos_exe_nr
                    ENDM

;       BX              PSP SEGMENT
GetPsp  MACRO
    OsGate get_psp_nr
                    ENDM

;       BX              PSP SEGMENT
SetPsp  MACRO
    OsGate set_psp_nr
                    ENDM

;       DS:BX       DEVICE HEADER
;       CX          DEVICE SIZE
;       DS:SI       DEVICE READ
;       DS:DI       DEVICE WRITE
;       DX          DEVICE SEGMENT
RegisterDosDevice  MACRO
    OsGate register_dos_device_nr
                    ENDM

;       ES:EDI      Adress to '$' terminated string
WriteDosString  MACRO
    OsGate write_dos_string_nr
                    ENDM

;;;;;;;;;;;;; Keyboard ;;;;;;;;;;;;;;;;;;;

;       AL      Scan code
ProcessKeyScan  MACRO
    OsGate process_key_scan_nr
                    ENDM

;       AX      Keyboard state
SetKeyboardState    MACRO
    OsGate set_keyboard_state_nr
                    ENDM

;       AL = CHAR OR EXTENDED CHAR
ReadKeyboardSerial      MACRO
    OsGate read_keyboard_serial_nr
                    ENDM

;       NC          CHAR IN BUFFER
;       CY          BUFFER EMPTY
PollKeyboardSerial      MACRO
    OsGate poll_keyboard_serial_nr
                    ENDM

;;;;;;;;;; Environment ;;;;;;;;;;;;;

; OUT BX    Env sys sel
LockSysEnv      MACRO
    OsGate lock_sys_env_nr
            ENDM

UnlockSysEnv    MACRO
    OsGate unlock_sys_env_nr
            ENDM

; OUT BX    Env process sel
LockProcEnv     MACRO
    OsGate lock_proc_env_nr
            ENDM

UnlockProcEnv   MACRO
    OsGate unlock_proc_env_nr
            ENDM

;;;;;;;;;;;; Focus ;;;;;;;;;;;;;

;       ES:EDI       Address to callback
HookEnableFocus MACRO
    OsGate hook_enable_focus_nr
                    ENDM

;       ES:EDI       Address to callback
HookLostFocus   MACRO
    OsGate hook_lost_focus_nr
                    ENDM

;       ES:EDI       Address to callback
HookGotFocus    MACRO
    OsGate hook_got_focus_nr
                    ENDM

;       AX          Focus thread
GetFocusThread  MACRO
    OsGate get_focus_thread_nr
                    ENDM

;       BX          Thread
;   AL      Switch key
GetThreadFocusKey     MACRO
    OsGate get_thread_focus_key_nr
                        ENDM

; IN    EAX         Number of bytes
; OUT   EDX         Base address
AllocateFocusLinear     MACRO
    OsGate allocate_focus_linear_nr
                    ENDM

; IN    EAX         Number of bytes
; IN    BX          Local selector
; IN    DX          Focus selector
; OUT   ES          Local selector
AllocateFixedFocusMem   MACRO
     OsGate allocate_fixed_focus_mem_nr
                    ENDM

;;;;;;;;;; Network ;;;;;;;;;;;;;

;       AL          Class id
;       CX          Size of address
;       DS:ESI      Broadcast address
RegisterNetClass    MACRO
    OsGate register_net_class_nr
                    ENDM

;       CX          Size of address
;       DX          Packet type
;       DS:ESI      My address
;       ES:EDI      receiver callback
;                       ECX         size
;                       DX          packet type
;                       DS:ESI      source address
;                       ES          data selector
;       BX          Protocol handle
RegisterNetProtocol     MACRO
    OsGate register_net_protocol_nr
                        ENDM

;       AL          CLASS
;       ECX         MAX DATA SIZE
;       DS:ESI      DISPATCH TABLE
;       ES:EDI      DRIVER NAME
;       BX          HANDLE
RegisterNetDriver       MACRO
    OsGate register_net_driver_nr
                        ENDM

;       DS:ESI       DISPATCH TABLE
;       BX          HANDLE
RegisterPppDriver       MACRO
    OsGate register_ppp_driver_nr
                        ENDM

; IN  BX        PROTOCOL HANDLE
; IN  FS:ESI    LOGICAL ADDRESS
; OUT NC        SUCCESS
; OUT BX        DRIVER HANDLE
GetNetDriver    MACRO
    OsGate get_net_driver_nr
                        ENDM

; IN  BX        PROTOCOL HANDLE
; IN  ECX       SIZE
; IN  DS:ESI    DEST ADDRESS
; OUT ES:EDI    DATA BUFFER TO USE
; OUT NC        SUCCESS
GetNetBuffer    MACRO
    OsGate get_net_buffer_nr
                        ENDM

; IN  BX        PROTOCOL HANDLE
; IN  DS:ESI    DEST ADDRESS
; OUT NC        SUCCESS
IsNetAddressValid       MACRO
    OsGate is_net_address_valid_nr
                        ENDM

; IN  BX        PROTOCOL HANDLE
; IN  ECX       SIZE
; IN  DS:ESI    DEST ADDRESS
; IN  ES        DATA
; OUT NC        SUCCESS
SendNet MACRO
    OsGate send_net_nr
                        ENDM

; IN  BX        PROTOCOL HANDLE
; IN  DS:ESI    ADDRESS
DefineProtocolAddress   MACRO
    OsGate define_protocol_addr_nr
                        ENDM

; IN  FS        Driver handle
; IN  ECX       Size
; OUT ES:EDI    Data buffer to use
; OUT NC        Success
GetBroadcastBuffer      MACRO
    OsGate get_broadcast_buffer_nr
                        ENDM

; IN  BX        Protocol handle
; IN  FS        Driver handle
; IN  ECX           Size
; IN  ES        Data buffer
; OUT NC        Success
SendBroadcast   MACRO
    OsGate send_broadcast_nr
                        ENDM

; IN  ES:EDI         Callback for each driver
;                           DS          class selector
;                           FS          driver handle
;                           GS          passed unchanged
;                           EDX         passed unchanged
;                           ESI         passed unchanged
;                           EBP         passed unchanged
NetBroadcast    MACRO
    OsGate net_broadcast_nr
                ENDM

; IN  ECX       SIZE
; OUT ES:EDI    DATA BUFFER TO USE
; OUT NC        SUCCESS
GetPppBuffer    MACRO
    OsGate get_ppp_buffer_nr
                        ENDM

; IN  ECX       SIZE
; IN  ES        DATA
; OUT NC        SUCCESS
SendPpp MACRO
    OsGate send_ppp_nr
                        ENDM

;       BX          HANDLE
NetReceived     MACRO
    OsGate net_received_nr
                        ENDM

;       IN  BX      protocol handle
;       IN  FS      driver
;       IN  ES      packet
;       IN  EDI     source address offset
;       BX          HANDLE
AddNetSourceAddress     MACRO
    OsGate add_net_source_address_nr
                        ENDM

; IN  AL          Protocol
; IN  ES:EDI      Receiver callback
;           AX          Size of options
;           ECX         Size of data
;           EDX         Source IP address
;           DS:ESI      Options
;           ES:EDI      IP Data
HookIp  MACRO
    OsGate hook_ip_nr
                        ENDM

; IN  AL          Protocol
; IN  AH          Time to live
; IN  ECX         Size of data
; IN  EDX         Destination IP address
; IN  DS:ESI    Options
; OUT ES:EDI    IP Data
CreateIpHeader  MACRO
    OsGate create_ip_header_nr
                        ENDM

; IN  ES          Datagram to send
SendIp  MACRO
    OsGate send_ip_data_nr
                        ENDM

; IN  AL        Protocol
; IN  AH        Time to live
; IN  ECX           Size of data
; IN  FS        Driver selector
; IN  DS:ESI    Options
; OUT ES:EDI    IP Data
CreateBroadcastIp       MACRO
    OsGate create_broadcast_ip_nr
                        ENDM

; IN  ES        Datagram to send
; IN  FS        Driver selector
SendBroadcastIp MACRO
    OsGate send_broadcast_ip_nr
                        ENDM

; IN  AL        Option code
; IN  ES:EDI    Callback for option data
;        ECX    Size of option data
;        ES:EDI Received option data
AddDhcpOption   MACRO
    OsGate add_dhcp_option_nr
                        ENDM

; IN  ES:EDI    New IP cache entry callback
;        ES     IP cache selector
HookIpCache     MACRO
    OsGate hook_ip_cache_nr
                        ENDM

; IN  AX          Size of IP cache data
; OUT BX          Offset within IP cache data for
AllocateIpCacheMem      MACRO
    OsGate allocate_ip_cache_mem_nr
                        ENDM

; IN  EDX         IP address
; OUT ES          IP cache entry
; OUT EDI         Host name offset
LookupIpCache   MACRO
    OsGate lookup_ip_cache_nr
                        ENDM

; IN  DS          IP cache entry
; OUT EAX         Timeout in system tics
GetHostTimeout  MACRO
    OsGate get_host_timeout_nr
                        ENDM

; IN  DS          IP cache entry
; IN  EAX         Round trip time in system tics
UpdateRoundTripTime     MACRO
    OsGate update_round_trip_time_nr
                        ENDM

; OUT EDX         My PPP IP address
GetPppIp    MACRO
    OsGate get_ppp_ip_nr
                ENDM

OpenPpp MACRO
    OsGate open_ppp_nr
            ENDM

ClosePpp    MACRO
    OsGate close_ppp_nr
            ENDM

; IN  EAX       timeout in ms
; IN  BX        destination port
; IN  EDX       IP-address
; IN  CX        Number of bytes to send
; IN  ES:EDI    Data buffer
; OUT ES:EDI    Answer buffer
; OUT CX        Number of bytes received
QueryUdp    MACRO
    OsGate query_udp_nr
            ENDM

; IN  SI        local port
; IN  ES:EDI    callback upon request
; IN    CX      UDP request size
; IN    ES:EDI  UDP request data
; OUT   CX      UDP reply size
; OUT   ES:EDI  UDP reply data
ListenUdpPort   MACRO
    OsGate listen_udp_port_nr
            ENDM

; IN  ES:EDI  Pointer to data
; IN  ECX     Size of data
NotifyEthernetPacket    MACRO
    OsGate notify_ethernet_packet_nr
                    ENDM

;;;;;;;;;;; DRIVE ;;;;;;;;;;;;
            
;       ES:EDI   Disc system table
HookInitDisc    MACRO
    OsGate hook_init_disc_nr
                    ENDM

;       IN      BX          Handle
;       IN      ECX         Read-ahead
;       OUT     AL          Disc #
;       OUT     BX          Disc sel
InstallDisc     MACRO
    OsGate install_disc_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      ES:EDI   Disc change procedure
RegisterDiscChange      MACRO
    OsGate register_disc_change_nr
                    ENDM

;       IN  BX      Disc sel
StartDisc       MACRO
    OsGate start_disc_nr
                    ENDM

;       IN  BX      Disc sel
StopDisc    MACRO
    OsGate stop_disc_nr
                    ENDM

;       IN  AX      Sectors per unit
;       IN  BX      Disc sel
;       IN  CX      Bytes per sector
;       IN  DX      Units
;       IN  SI      BIOS sectors / cylinder
;       IN  DI      BIOS heads
SetDiscParam    MACRO
    OsGate set_disc_param_nr
                    ENDM

;       IN      BX      Disc sel
WaitForDiscRequest      MACRO
    OsGate wait_for_disc_request_nr
                    ENDM

;       IN      BX      Disc sel
;       OUT     EDI     Disc handle
GetDiscRequest  MACRO
    OsGate get_disc_request_nr
                    ENDM

;       IN      BX      Disc sel
;       OUT     EDI     Disc handle
PollDiscRequest MACRO
    OsGate poll_disc_request_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      EDI     Disc handle
DiscRequestCompleted    MACRO
    OsGate disc_request_completed_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      AX      Sector
;       IN      DX      Unit
;       OUT     EDI     Disc handle
NewDiscRequest  MACRO
    OsGate new_disc_request_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      AX      Sector
;       IN      DX      Unit
;       OUT     EDI     Disc handle
LockDiscRequest MACRO
    OsGate lock_disc_request_nr
                    ENDM

;       IN      EDI     Disc handle
ModifyDiscRequest       MACRO
    OsGate modify_disc_request_nr
                    ENDM

;       IN      EDI     Disc handle
UnlockDiscRequest       MACRO
    OsGate unlock_disc_request_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      ECX     Max number of entries
;       OUT     ESI     Disc handle array
;       OUT     ECX     Number of entries
GetDiscRequestArray     MACRO
    OsGate get_disc_request_array_nr
                    ENDM

;       IN      AL          Drive #
;       IN      AH          Disc # or 0
;       IN      EDX         Start sector
;       IN      ECX         Number of sectors
OpenDrive       MACRO
    OsGate open_drive_nr
                    ENDM

;       IN      AL          Drive #
CloseDrive      MACRO
    OsGate close_drive_nr
                    ENDM

;       IN      AL          Drive #
FlushDrive      MACRO
    OsGate flush_drive_nr
                    ENDM

;       IN      AL          Drive #
;       OUT     EAX         Readahead
;       OUT     ECX     Size
;       OUT     SI      Sectors per unit
;       OUT     DI      Units
GetDriveParam   MACRO
    OsGate get_drive_param_nr
                    ENDM

;  IN   AL          DRIVE #
;  IN   EDX         SECTOR
;  OUT  EBX         Handle
;  OUT  ESI         Logical address of data
LockSector      MACRO
    OsGate lock_sector_nr
                    ENDM

;  IN   EBX         Handle
UnlockSector    MACRO
    OsGate unlock_sector_nr
                    ENDM

;  IN   EBX         Handle
ModifySector    MACRO
    OsGate modify_sector_nr
                    ENDM

;  IN   EBX         Handle
FlushSector     MACRO
    OsGate flush_sector_nr
                    ENDM

;  IN   AL          Drive #
;  IN   EDX         Sector
;  OUT  EBX         Handle
;  OUT  ESI         Logical address of data
NewSector       MACRO
    OsGate new_sector_nr
                    ENDM

;  IN   AL          DRIVE #
;  IN   EDX         SECTOR
;  IN   ESI         Logical address of data
;  OUT  EBX         Handle
ReqSector       MACRO
    OsGate req_sector_nr
                    ENDM

;  IN   AL          DRIVE #
;  IN   EDX         SECTOR
;  IN   ESI         Logical address of data
;  OUT  EBX         Handle
DefineSector    MACRO
    OsGate define_sector_nr
                    ENDM

;  IN   CX          Max number of entries
;  OUT  AX          Seq handle
CreateDiscSeq   MACRO
    OsGate create_disc_seq_nr
                    ENDM

;  IN   AX          Seq handle
;  IN   EBX         Handle
ModifySeqSector MACRO
    OsGate modify_seq_sector_nr
                    ENDM

;  IN   AX          Seq handle
PerformDiscSeq  MACRO
    OsGate perform_disc_seq_nr
                    ENDM

;  IN   AL          Drive #
;  IN   ECX         Number of sectors
;  IN   EDX         Start sector
EraseSectors    MACRO
    OsGate erase_sectors_nr
                    ENDM

;  IN   EBX         Handle
WaitForSector   MACRO
    OsGate wait_for_sector_nr
                    ENDM

;  IN   AL          Drive #
ResetDrive      MACRO
    OsGate reset_drive_nr
                    ENDM

;;;;;;;;;;;; File system ;;;;;;;;;;;;

;  IN   DS:ESI       Device read
;  IN   ES:EDI       Device write
;  IN   FS:EBX       Device name
InstallDeviceFile  MACRO
    OsGate install_device_file_nr
                    ENDM

;  IN   ES:EDI      FILENAME
;  IO   AL              DRIVE IN / OUT
CheckDeviceFile     MACRO
    OsGate check_device_file_nr
                    ENDM

;  IN  ES:EDI      INIT CALLBACK
HookInitFileSystem      MACRO
    OsGate hook_init_file_system_nr
                    ENDM

;  IN   DS:ESI       File system name
;  IN   ES:EDI       File system table
RegisterFileSystem      MACRO
    OsGate register_file_system_nr
                    ENDM

;       AL              DRIVE #
;       BX              HANDLE
;       ES:EDI       MEDIA CHECK PROCEDURE
DefineMediaCheck    MACRO
    OsGate define_media_check_nr
                    ENDM

;  IN   AL              DRIVE #
DemandLoadFileSystem    MACRO
    OsGate demand_load_file_system_nr
                    ENDM

;  IN   ES:EDI       FILE SYSTEM NAME
IsFileSystemAvailable   MACRO
    OsGate is_file_system_available_nr
                    ENDM

;  IN   AL              DRIVE #
;  IN   ES:EDI          FILE SYSTEM NAME
InstallFileSystem       MACRO
    OsGate install_file_system_nr
                    ENDM

;  IN   AL              Drive #
;  IN   ES:EDI          File system name
;  IN   FS:EDX          Format data
FormatFileSystem    MACRO
    OsGate format_file_system_nr
                    ENDM

;  IN   AL          Drive #
;  IN   ECX         Number of sectors
;  IN   FS:EDX      Mount data
StartFileSystem MACRO
    OsGate start_file_system_nr
                    ENDM

;  IN   AL              DRIVE #
StopFileSystem  MACRO
    OsGate stop_file_system_nr
                    ENDM

;  IN   BX              File selector
;  IN   EDX             Position
;  OUT  EAX             File list entry
GetFileListEntry    MACRO
    OsGate get_file_list_entry_nr
                    ENDM

;  IN   BX              File selector
;  IN   EDI             File list entry
FreeFileListEntry       MACRO
    OsGate free_file_list_entry_nr
                    ENDM

;  IN   BX              DIR SELECTOR
;  IN   EDX             DIR ENTRY
;  OUT  BX              Cached dir sel
CacheDir    MACRO
    OsGate cache_dir_nr
                    ENDM

;  IN   BX              DIR SELECTOR
;  IN   EDX             DIR ENTRY
InsertDirEntry  MACRO
    OsGate insert_dir_entry_nr
                    ENDM

;  IN   BX              DIR SELECTOR
;  IN   EDX             FILE ENTRY
InsertFileEntry MACRO
    OsGate insert_file_entry_nr
                    ENDM

;;;;;;;;;;;; FILE ;;;;;;;;;;;

;  IN   BX          File handle
;  OUT  CL          Acess
;  OUT  CH          Drive
;  OUT  AX          File selector
GetFileInfo     MACRO
    OsGate get_file_info_nr
                    ENDM

;  IN   CL          Access
;  IN   CH          Drive
;  IN   AX          File selector
;  OUT  BX          File handle
DuplFileInfo    MACRO
    OsGate dupl_file_info_nr
                    ENDM

;;;;;;;;;;;; VIDEO ;;;;;;;;;;;

;  IN   AL          char
;  IN   BX          font handle
;  OUT  CX          width
;  OUT  DX          height
;  OUT  SI          row size
;  OUT  ES:EDI      1-bit string bitmap
GetCharMask     MACRO
    OsGate get_char_mask_nr
                    ENDM

;  IN  AX      Mode nr
;  IN  BL      bits / pixel
;  IN  CX      x-resolution
;  IN  DX      y-resolution
;  IN  ES:EDI  Mode constructor
RegisterVideoMode       MACRO
    OsGate register_video_mode_nr
                    ENDM

;  IN  AL      Bits per pixel
;  IN  CX      Width
;  IN  DX      Height
;  IN  ES      Video / bitmap selector
;  OUT BX      Bitmap handle
InitVideoBitmap MACRO
    OsGate init_video_bitmap_nr
                    ENDM

;   IN  AX      size
;   IN  CX      x
;   IN  DX      y
;   IN  ES:EDI  buffer
;   IN  DS      bitmap
HideSpriteLine  MACRO
    OsGate hide_sprite_line_nr
                    ENDM

;   IN  DS      bitmap
ShowSpriteLine  MACRO
    OsGate show_sprite_line_nr
                    ENDM

;;;;;;;;;; MOUSE ;;;;;;;;;

InitMouse       MACRO
    OsGate init_mouse_nr
                    ENDM

;   IN  AX          Button status
;   IN  CX          Delta X
;   IN  DX          Delta Y
UpdateMouse     MACRO
    OsGate update_mouse_nr
                    ENDM

;   IN  CX          Delta X
;   IN  DX          Delta Y
InvertMouse     MACRO
    OsGate invert_mouse_nr
                    ENDM


;   IN  AX          Button status
;   IN  CX          Abs X (0..32767)
;   IN  DX          Abs Y (0..32767)
SetMouse    MACRO
    OsGate set_mouse_nr
                    ENDM

;   IN  CX          Max x-position
;   IN  DX          Max y-position
SetMouseLimit   MACRO
    OsGate set_mouse_limit_nr
                    ENDM

;;;;;;;;;;;;; PnP ;;;;;;;;;;;;;;

; IN  CH    Function
; IN  CL    Register
; OUT AL    Data
ReadPnpByte     MACRO
    OsGate read_pnp_byte_nr
                    ENDM

; IN  CH    Function
; IN  CL    Register
; IN  AL    Data
WritePnpByte     MACRO
    OsGate write_pnp_byte_nr
                    ENDM

;;;;;;;;;;;;; PCI ;;;;;;;;;;;;;;

BiosPciInt      MACRO
    OsGate bios_pci_int_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    Register
; OUT AL    Data
ReadPciByte     MACRO
    OsGate read_pci_byte_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    Register
; OUT AX    Data
ReadPciWord     MACRO
    OsGate read_pci_word_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    Register
; OUT EAX       Data
ReadPciDword    MACRO
    OsGate read_pci_dword_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    Register
; IN  AL    Data
WritePciByte    MACRO
    OsGate write_pci_byte_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    Register
; IN  AX    Data
WritePciWord    MACRO
    OsGate write_pci_word_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    Register
; IN  EAX       Data
WritePciDword   MACRO
    OsGate write_pci_dword_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  AL    Capability
; OUT AL    Index
FindPciCapability       MACRO
    OsGate find_pci_cap_nr
                    ENDM

; IN  BH    Class
; IN  BL    Sub class
; IN  CH    Interface
; IN  AX    Device number
; OUT BH    Bus
; OUT BL    Device
FindPciClass    MACRO
    OsGate find_pci_class_nr
                    ENDM

; IN  BH    Class
; IN  BL    Sub class
; IN  AX    Device number
; OUT BH    Bus
; OUT BL    Device
FindPciClassAll MACRO
    OsGate find_pci_class_all_nr
                    ENDM

; IN  CX    Device ID
; IN  DX    Vendor ID
; IN  AX    Device number
; OUT BH    Bus
; OUT BL    Device
FindPciDevice   MACRO
    OsGate find_pci_device_nr
                    ENDM

; IN  AL    Interrupt pin
; OUT AL    Interrupt line
GetPciIrqNr     MACRO
    OsGate get_pci_irq_nr
                    ENDM

;;;;;;;;;; POWER MANAGEMENT ;;;;;;;;;

;   IN  EAX     Table name
;   OUT ES      Table selector
GetAcpiTable    MACRO
    OsGate get_acpi_table_nr
                    ENDM

;;;;;;;;;; Com port ;;;;;;;;;

; IN  AX      Controller #
; IN  DX      Device #
; IN  DS      Com device selector
AddComPort      MACRO
    OsGate add_com_port_nr
                    ENDM

; IN  AL      Port #
ReserveComLine  MACRO
    OsGate reserve_com_line_nr
                    ENDM

; IN  AL      Port #
DeviceSetDtr    MACRO
    OsGate device_set_dtr_nr
                    ENDM

; IN  AL      Port #
DeviceResetDtr  MACRO
    OsGate device_reset_dtr_nr
                    ENDM

; IN   AL      Port #
; OUT  AL   Line state
WaitForLineStateChange  MACRO
    OsGate wait_for_line_state_nr
                    ENDM

; IN  AL      Port #
; IN  AL   Line state
GetLineState    MACRO
    OsGate get_line_state_nr
                    ENDM

;;;;;;;;;; USB ;;;;;;;;;

; IN  DS      Usb device selector
InitUsbDevice   MACRO
    OsGate init_usb_device_nr
                    ENDM

; IN  AL      Port #
; IN  AH      Low speed = 1, high speed / full speed = 0
; IN  DS      Usb device selector
NotifyUsbAttach MACRO
    OsGate notify_usb_attach_nr
                    ENDM

; IN  AL      Port #
; IN  DS      Usb device selector
NotifyUsbDetach MACRO
    OsGate notify_usb_detach_nr
                    ENDM

; IN  ES:EDI  Callback
;       BX    Controller #
;       AL    Device address
HookUsbAttach   MACRO
    OsGate hook_usb_attach_nr
                    ENDM

; IN  ES:EDI  Callback
;       BX    Controller #
;       AL    Device address
HookUsbDetach   MACRO
    OsGate hook_usb_detach_nr
                    ENDM

; IN  BX    Pipe handle
; OUT BX    Req handle
CreateUsbReq      MACRO
    OsGate create_usb_req_nr
                        ENDM
                        
; IN  BX    Req handle
; IN  CX    Size of data
; IN  ES    Selector (do not free)
AddWriteUsbContolReq      MACRO
    OsGate add_write_usb_control_req_nr
                        ENDM
                        
; IN  BX    Req handle
; IN  CX    Size of data
; IN  ES    Selector (do not free)
AddWriteUsbDataReq      MACRO
    OsGate add_write_usb_data_req_nr
                        ENDM

; IN  BX    Req handle
; IN  CX    Size of data
; IN  ES    Selector (do not free)
AddReadUsbDataReq      MACRO
    OsGate add_read_usb_data_req_nr
                        ENDM

; IN  BX    Req handle
AddUsbStatusInReq      MACRO
    OsGate add_usb_status_in_req_nr
                        ENDM

; IN  BX    Req handle
AddUsbStatusOutReq      MACRO
    OsGate add_usb_status_out_req_nr
                        ENDM

; IN  AX    Thread to signal on completion
; IN  BX    Req handle
; IN  CX    Size of out buffer
StartUsbReq      MACRO
    OsGate start_usb_req_nr
                        ENDM

; IN  BX    Req handle
StopUsbReq      MACRO
    OsGate stop_usb_req_nr
                        ENDM

; IN  BX    Req handle
; OUT NC    Req is started
IsUsbReqStarted      MACRO
    OsGate is_usb_req_started_nr
                        ENDM

; IN  BX    Req handle
; OUT NC    Req is done
IsUsbReqReady      MACRO
    OsGate is_usb_req_ready_nr
                        ENDM

; IN  BX    Req handle
; OUT CX    Bytes transfered
GetUsbReqData      MACRO
    OsGate get_usb_req_data_nr
                        ENDM

; IN  BX    Req handle
CloseUsbReq      MACRO
    OsGate close_usb_req_nr
                        ENDM

; IN  BX      Handle
; OUT FS      Pipe sel
; OUT DS      Function sel
GetUsbInfo      MACRO
    OsGate get_usb_info_nr
                        ENDM

;;;;;;;;;; Audio codec ;;;;;;;;;

; IN    BX Register
; OUT   AX Value
ReadCodec      MACRO
    OsGate read_codec_nr
                        ENDM

; IN    BX Register
; IN    AX Value
WriteCodec      MACRO
    OsGate write_codec_nr
                        ENDM

;;;;;;;;;; Audio ;;;;;;;;;

; OUT   AX Sample rate
GetAudioDacRate      MACRO
    OsGate get_audio_dac_rate_nr
                        ENDM


; IN    AX Sample rate
SetAudioDacRate      MACRO
    OsGate set_audio_dac_rate_nr
                        ENDM

; OUT   AX Sample rate
GetAudioAdcRate      MACRO
    OsGate get_audio_adc_rate_nr
                        ENDM

; IN    AX Sample rate
SetAudioAdcRate      MACRO
    OsGate set_audio_adc_rate_nr
                        ENDM

; IN    AX Sample rate
OpenAudioOut      MACRO
    OsGate open_audio_out_nr
                        ENDM

CloseAudioOut      MACRO
    OsGate close_audio_out_nr
                        ENDM

; IN    DS Left channel
; IN    ES Right channel
; IN    CX Samples
SendAudioOut      MACRO
    OsGate send_audio_out_nr
                        ENDM

; IN    BX  Handle
; OUT   CX  Buffer size
; OUT   SI  Left channel sel
; OUT   DI  Right channel sel
GetAudioOutBuffers      MACRO
    OsGate get_audio_out_buf_nr
                        ENDM

; IN    BX  Handle
PostAudioOutBuffers      MACRO
    OsGate post_audio_out_buf_nr
                        ENDM

; IN    BX  Handle
; OUT   NC  Completed
IsAudioOutCompleted      MACRO
    OsGate is_audio_out_completed_nr
                        ENDM

;;;;;;;;;; Printer ;;;;;;;;;

;   AX      Controller #
;   DX      Device #
;   DS      Printer device selector
AddPrinter      MACRO
    OsGate add_printer_nr
                    ENDM

;;;;;;;;;; IR ;;;;;;;;;

; IN  ES:DI     Data buffer
; IN  CX        Size
NotifyIrData      MACRO
    OsGate notify_ir_data_nr
                        ENDM

