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
; handle types
;

C_HANDLE_FILE         = 1
C_HANDLE_STDIN        = 2
C_HANDLE_STDOUT       = 3
C_HANDLE_TCP_SOCKET   = 4
C_HANDLE_UDP_SOCKET   = 5
C_HANDLE_VFS          = 6

;
; offsets in 16-bit trapgates, vmode
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

;
; offsets in 32-bit trapgates, vmode
;
trap_gs     EQU 40
trap_fs     EQU 36
trap_ds     EQU 32
trap_es     EQU 28
trap_ss     EQU 24
trap_esp    EQU 20
trap_eflags EQU 16
trap_cs     EQU 12
trap_eip    EQU 8
trap_err    EQU 4
trap_ebp    EQU 0
trap_eax    EQU -4
trap_ebx    EQU -8
trap_state  EQU -9
trap_exc_nr EQU -10
trap_pds    EQU -12
trap_call   EQU -14

ifndef __JWASM__

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

endif    
    
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

OsGate64    MACRO gate_nr
    push r15
    mov r15,osgate_linear + gate_nr SHL 4
    call fword ptr [r15]
    pop r15
            ENDM

OsGate  MACRO gate_nr
IF (size $) EQ 0FF02h
    OsGate16 gate_nr
ELSE
  IFDEF rax
    OsGate64 gate_nr  
  ELSE
    OsGate32 gate_nr
  ENDIF
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
;       ESI         GATE CALL ADDRESS
;       EDI         GATE NAME ADDRESS
RegisterLongOsGate  MACRO
    OsGate register_long_osgate_nr
                    ENDM

;       AX          GATE NUMBER
IsValidOsGate   MACRO
    OsGate is_valid_osgate_nr
                    ENDM

;       AX          GATE NUMBER
;       DS:ESI      GATE CALL ADDRESS
;       ES:EDI      GATE NAME ADDRESS
RegisterServGate  MACRO
    OsGate register_serv_gate_nr
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

; IN  AX          GATE NUMBER
; IN  DX          SEGMENT TRANSFER
; IN  DS:EBX      16-BIT GATE CALL ADDRESS
; IN  DS:ESI      32-BIT GATE CALL ADDRESS
; IN  ES:EDI      GATE NAME ADDRESS
; OUT DX:EAX      Previous 32-bit call address
LinkUserGate    MACRO
    OsGate link_usergate_nr
                        ENDM

;       AX      Gate number
;       ECX     Syscall flags + par      
;       DX      Segment transfer
;       DS:ESI  Far call address
;       ES:EDI  Gate name
RegisterBimodalSyscall MACRO
    OsGate register_bimodal_syscall_nr
                        ENDM

;       AX      Gate number
;       ECX     Syscall flags + par      
;       DX      Segment transfer
;       DS:EBX  16-bit far call address
;       DS:ESI  32-bit far call address
;       ES:EDI  Gate name
RegisterSyscall    MACRO
    OsGate register_syscall_nr
                        ENDM

;       FS      Processor selector
StartSyscall   MACRO
    OsGate start_syscall_nr
                    ENDM

;       DS:EBX  Patch address
AppPatch   MACRO
    OsGate app_patch_nr
                    ENDM

;       AL          Exception #
EmulateOpcode   MACRO
    OsGate emulate_opcode_nr
                    ENDM

StartDev32   MACRO
    OsGate start_dev32_nr
                    ENDM

FpuException   MACRO
    OsGate fpu_exception_nr
                    ENDM

;;;;;;;; DESCRIPTORS ;;;;;;;;;;;;

;  OUT  CX      Size of GDT
;  OUT  EDX     Linear base address of GDT
CreateCoreGdt     MACRO
    OsGate create_core_gdt_nr
                    ENDM

;       BX          GDT DESCRIPTOR
AllocateGdt     MACRO
    OsGate allocate_gdt_nr
                    ENDM

;       BX          GDT DESCRIPTOR
FreeGdt MACRO
    OsGate free_gdt_nr
                    ENDM

CreatePrivateLdt     MACRO
    OsGate create_private_ldt_nr
                    ENDM

DestroyLdt     MACRO
    OsGate destroy_ldt_nr
                    ENDM

CreateSharedLdt     MACRO
    OsGate create_shared_ldt_nr
                    ENDM

DestroySharedLdt     MACRO
    OsGate destroy_shared_ldt_nr
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
CreateDownSelector32    MACRO
    OsGate create_down_sel32_nr
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
CreateLongCodeSelector    MACRO
    OsGate create_long_code_sel_nr
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

; IN  BX          DESCRIPTOR
; IN  DX          TSS SELECTOR
CreateTaskGateSelector  MACRO
    OsGate create_task_gate_sel_nr
                            ENDM

;       BX          DESCRIPTOR
;       AL          Bitness (16, 32 or 64)
GetSelectorBitness     MACRO
    OsGate get_sel_bitness_nr
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

; IN  AL        INT #
; IN  BL        DPL
; IN  DS:ESI    ENTRY POINT
SetupIntGate   MACRO
    OsGate setup_int_gate_nr
                            ENDM

; IN  AL        INT #
; IN  BL        DPL
; IN  DS:ESI    ENTRY POINT
SetupTrapGate  MACRO
    OsGate setup_trap_gate_nr
                            ENDM

; IN  AL        INT #
; IN  BL        DPL
; IN  ESI       ENTRY POINT
SetupLongIntGate   MACRO
    OsGate setup_long_int_gate_nr
                            ENDM

; IN  AL        INT #
; IN  BL        DPL
; IN  BH        IST
; IN  ESI       ENTRY POINT
SetupLongTrapGate  MACRO
    OsGate setup_long_trap_gate_nr
                            ENDM

;       BX          DESCRIPTOR
IsLongCodeSelector    MACRO
    OsGate is_long_code_sel_nr
                    ENDM

;;;;;;;;; LONG MODE ;;;;;;;;;;;;;;;;;;;;

HasLongMode MACRO
    OsGate has_long_mode_nr
                    ENDM

LongModeReset MACRO
    OsGate long_mode_reset_nr
                    ENDM

SetupLongMode MACRO
    OsGate setup_long_mode_nr
                    ENDM

StartLongMode MACRO
    OsGate start_long_mode_nr
                    ENDM

; IN  EAX  Long mode compatible CR3
SwitchToLongMode MACRO
    OsGate switch_to_long_mode_nr
                    ENDM

; IN  EAX  Protected mode compatible CR3
SwitchToProtectedMode MACRO
    OsGate switch_to_protected_mode_nr
                    ENDM

IsLongThread MACRO
    OsGate is_long_thread_nr
                    ENDM

; IN  RCX        Stack size
; IN  RDX        Param
; IN  RSI        Start address
; OUT ESI        Info block
CreateLongThreadInfo MACRO
    OsGate create_long_thread_info_nr
                    ENDM

; IN  EDX     Thread base      
; IN  EDI     TSS base
LoadLongRegs MACRO
    OsGate load_long_regs_nr
                    ENDM

; IN  EDX     Thread base      
LoadLongBreaks MACRO
    OsGate load_long_breaks_nr
                    ENDM

; IN  EDX           Offset in file
; OUT EDX           Linear address of data
; OUT EAX           Bytes read
HandleLongCodeFault MACRO
    OsGate handle_long_code_fault_nr
                    ENDM

;;;;;;;;; PAGING ;;;;;;;;;;;;;;;;;;;;

NotifyInitProcess MACRO
    OsGate notify_init_process_nr
                    ENDM

; OUT EAX          CR3
NotifyCreateProcess MACRO
    OsGate notify_create_process_nr
                    ENDM

NotifyCreateLongProcess MACRO
    OsGate notify_create_long_process_nr
                    ENDM

; OUT EAX    Flat size
GetFlatSize MACRO
    OsGate get_flat_size_nr
                    ENDM

; OUT BX     Serv sel
CreateServDir MACRO
    OsGate create_serv_dir_nr
                    ENDM

; IN  EAX    CR3
; IN  DS     Process sel
CreateFork MACRO
    OsGate create_fork_nr
                    ENDM

; IN  DS     Process sel
DeleteFork MACRO
    OsGate delete_fork_nr
                    ENDM

; IN  DS    Source process sel
; IN  ES    Destination process sel
StartFork MACRO
    OsGate start_fork_nr
                    ENDM

DetachFork MACRO
    OsGate detach_fork_nr
                    ENDM

; IN  BX     Program ID
CleanupFork MACRO
    OsGate cleanup_fork_nr
                    ENDM

; IN  BX    Program ID
; IN  DS    Removed process
RemovedProcess MACRO
    OsGate removed_process_nr
                    ENDM

;   EAX    CR3
NotifyDeleteProcess MACRO
    OsGate notify_delete_process_nr
                    ENDM


InitProcess MACRO
    OsGate init_process_nr
                    ENDM

ResetProcess MACRO
    OsGate reset_process_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
GetPageEntry MACRO
    OsGate get_page_entry_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
SetPageEntry MACRO
    OsGate set_page_entry_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
GetSysPageEntry MACRO
    OsGate get_sys_page_entry_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
SetSysPageEntry MACRO
    OsGate set_page_entry_nr
                    ENDM

; IN    EDX         Linear address
; OUT   NC          Valid 
HasPageEntry MACRO
    OsGate has_page_entry_nr
                    ENDM

; OUT   ESI         Linear space of page directory entry (200000h for PAE)
; OUT   CX          Number of entries per 32-bit paging entry (2 for PAE)
GetPageDirAttrib MACRO
    OsGate get_page_dir_attrib_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
GetPageDir MACRO
    OsGate get_page_dir_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
SetPageDir MACRO
    OsGate set_page_dir_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
GetSysPageDir MACRO
    OsGate get_sys_page_dir_nr
                    ENDM

;       EDX         LINEAR ADDRESS
CreateSysPageDir MACRO
    OsGate create_sys_page_dir_nr
                    ENDM

;       EDX         LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
SetSysPageDir MACRO
    OsGate set_sys_page_dir_nr
                    ENDM

; IN    EAX         Allocation limit
; IN    ECX         Number of entries
; IN    EDX         Start linear address
; OUT   EDX         Linear address
AllocatePageEntries MACRO
    OsGate allocate_page_entries_nr
                    ENDM

; IN    ECX         Number of entries
; IN    EDX         Start linear address
ReservePageEntries MACRO
    OsGate reserve_page_entries_nr
                    ENDM

; IN    EAX         Free bits
; IN    ECX         Number of entries
; IN    EDX         Linear address
FreePageEntries MACRO
    OsGate free_page_entries_nr
                    ENDM

; IN    EAX         Free bits
; IN    ECX         Number of entries
; IN    EDX         Linear address
ClearPageEntries MACRO
    OsGate clear_page_entries_nr
                    ENDM

; IN    EAX         Free bits
; IN    ECX         Number of entries
; IN    EDX         Linear address
FreeServPageEntries MACRO
    OsGate free_serv_page_entries_nr
                    ENDM

; IN    ECX         Number of entries
; IN    ESI         Source linear address
; IN    EDI         Dest linear address
CopyPageEntries MACRO
    OsGate copy_page_entries_nr
                    ENDM

; IN    ECX         Number of entries
; IN    ESI         Source linear address
; IN    EDI         Dest linear address
CopySysPageEntries MACRO
    OsGate copy_sys_page_entries_nr
                    ENDM

; IN    ECX         Number of entries
; IN    ESI         Source linear address
; IN    EDI         Dest linear address
MovePageEntries MACRO
    OsGate move_page_entries_nr
                    ENDM

;       BP          Thread
;       CX:EDX      LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
GetThreadPageEntry   MACRO
    OsGate get_thread_page_entry_nr
                    ENDM

;       BP          Thread
;       CX:EDX      LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
SetThreadPageEntry   MACRO
    OsGate set_thread_page_entry_nr
                    ENDM

;       BP          Thread
;       CX:EDX      LINEAR ADDRESS
;       EBX:EAX     PAGE ENTRY
GetThreadPageDir   MACRO
    OsGate get_thread_page_dir_nr
                    ENDM

;       DX:ESI      Address to validate
;       BX          Thread
;       NC          Valid
;       EAX         Page attributes
GetThreadSelectorPage      MACRO
    OsGate get_thread_selector_page_nr
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

;       DX:ESI      ADDRESS TO READ
;       BX          Thread
;       NC          VALID
;       AL          DATA OR ERROR REASON
ReadThread64      MACRO
    OsGate read_thread64_nr
                    ENDM

;       DX:ESI      ADDRESS TO WRITE
;       BX          Thread
;       NC          VALID
;       AL          DATA TO WRITE
WriteThread64     MACRO
    OsGate write_thread64_nr
                    ENDM

;       EAX         ANTAL BYTE
;       EDX         LINEAR BASE ADDRESS
SetPageEmulate  MACRO
    OsGate set_page_emulate_nr
                    ENDM

; IN  EAX         Size
; IN  EDX         Linear address
; IN  ES          Loader selector
HookPage    MACRO
    OsGate hook_page_nr
                    ENDM

; IN  EAX         Size
; IN  EDX         Linear address
UnhookPage      MACRO
    OsGate unhook_page_nr
                    ENDM

;;;;;;;;;;; LINEAR MEMORY MANAGEMENT ;;;;;;;;

InitProcessMem     MACRO
    OsGate init_process_mem_nr
                    ENDM

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


; OUT ES           Selector
CreateShareBlock      MACRO
    OsGate create_share_block_nr
                    ENDM

; IN  BX           Selector
; OUT ES           Selector
CreateFixedShareBlock      MACRO
    OsGate create_fixed_share_block_nr
                    ENDM

; IN  ES           Selector
GrowShareBlock      MACRO
    OsGate grow_share_block_nr
                    ENDM

; IN  ES           Selector
FreeShareBlock      MACRO
    OsGate free_share_block_nr
                    ENDM

;       EAX     Bytes
;       EDX     Linear base
AllocateLongBuf     MACRO
    OsGate allocate_long_buf_nr
                    ENDM

;       ECX     Size
;       EDX     Linear base
FreeLongBuf     MACRO
    OsGate free_long_buf_nr
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

; IN  EAX          Bytes
; OUT ES           LDT selector
AllocateSmallServ    MACRO
    OsGate allocate_small_serv_nr
                    ENDM

; IN  ES           LDT selector
FreeSmallServ    MACRO
    OsGate free_small_serv_nr
                    ENDM

; IN  EAX          Bytes
; OUT EDX          Offset in serv flat sel
AllocateBigServ    MACRO
    OsGate allocate_big_serv_nr
                    ENDM

; IN  ECX          Bytes
; IN  EDX          Offset in serv flat sel
FreeBigServ    MACRO
    OsGate free_big_serv_nr
                    ENDM

; IN  EAX          Bytes
; OUT ES           LDT selector
AllocateBigServSel    MACRO
    OsGate allocate_big_serv_sel_nr
                    ENDM

; IN  ES           LDT selector
FreeBigServSel    MACRO
    OsGate free_big_serv_sel_nr
                    ENDM

; IN  EDX          Offset in serv flat sel
; IN  EBX:EAX      Physical address
; OUT EDX          Updated offset
MapServEntry    MACRO
    OsGate map_serv_entry_nr
                    ENDM

;;;;;;;;;;;;; MEMORY BLOCK MANAGEMENT ;;;;;;;;;;


;  IN  AX      Base allocation size
;  IN  SI      Total header size
;  OUT DS      Memory block selector
CreateBlk         MACRO
    OsGate create_blk_nr
                    ENDM

;  IN  DS      Memory block selector
DeleteBlk    MACRO
    OsGate delete_blk_nr
                    ENDM

;  IN  DS      Memory block selector
;  IN  CX      Allocation size
;  OUT EDX     Offset
AllocateBlk    MACRO
    OsGate allocate_blk_nr
                    ENDM

;  IN  DS      Memory block selector
;  IN  EDX     Offset
;  IN  CX      Allocation size
FreeBlk    MACRO
    OsGate free_blk_nr
                    ENDM

;  IN  AX      Base allocation size
;  IN  CX      Minimum additional blocks
;  IN  SI      Reserved size
;  OUT ES      Memory block selector
CreateMemBlk32    MACRO
    OsGate create_mem_blk32_nr
                    ENDM

;  IN  AX      Base allocation size
;  IN  CX      Minimum additional blocks
;  IN  SI      Reserved size
;  OUT ES      Memory block selector
CreateMemBlk64    MACRO
    OsGate create_mem_blk64_nr
                    ENDM

;  IN  ES      Memory block selector
;  IN  CX      Allocation size
;  OUT EDX     Linear address
;  OUT EBX:EAX Physical address
AllocateMemBlk    MACRO
    OsGate allocate_mem_blk_nr
                    ENDM

;  IN  ES      Memory block selector
;  IN  EBX:EAX Physical address
;  OUT EDX     Linear address
PhysicalToLinearMemBlk    MACRO
    OsGate physical_to_linear_mem_blk_nr
                    ENDM

;  IN  ES      Memory block selector
;  IN  EDX     Linear address
;  OUT EBX:EAX Physical address
LinearToPhysicalMemBlk    MACRO
    OsGate linear_to_physical_mem_blk_nr
                    ENDM

;  IN  ES      Memory block selector
;  IN  EBX:EAX Physical address
;  IN  CX      Allocation size
FreePhysicalMemBlk    MACRO
    OsGate free_physical_mem_blk_nr
                    ENDM

;  IN  ES      Memory block selector
;  IN  EDX     Linear address
;  IN  CX      Allocation size
FreeLinearMemBlk    MACRO
    OsGate free_linear_mem_blk_nr
                    ENDM

;  IN  ES      Memory block selector
FreeMemBlk    MACRO
    OsGate free_mem_blk_nr
                    ENDM

;;;;;;;;;;;;; PHYSICAL MEMORY MANAGEMENT ;;;;;;;;;;

;       EAX         FYSISK ADDRESS
;AllocateOldPhysical    MACRO
;    OsGate allocate_old_physical_nr
;                    ENDM

;       EAX         FYSISK ADDRESS
AllocateDmaPhysical     MACRO
    OsGate allocate_dma_physical_nr
                    ENDM

;       EAX         FYSISK ADDRESS
;FreeOldPhysical    MACRO
;    OsGate free_old_physical_nr
;                    ENDM

;       IN  ECX     Number of pages
;       OUT EAX     Physical base address
;AllocateOldMultiplePhysical    MACRO
;    OsGate allocate_old_multiple_physical_nr
;                    ENDM

; IN  ECX           Number of pages
; OUT EBX:EAX       Physical base address
AllocateMultiplePhysical32    MACRO
    OsGate allocate_multiple_physical32_nr
                    ENDM

; IN  ECX           Number of pages
; OUT EBX:EAX       Physical base address
AllocateMultiplePhysical64    MACRO
    OsGate allocate_multiple_physical64_nr
                    ENDM

; OUT EBX:EAX       Physical base address
AllocatePhysical32    MACRO
    OsGate allocate_physical32_nr
                    ENDM

; OUT EBX:EAX       Physical base address
AllocatePhysical64    MACRO
    OsGate allocate_physical64_nr
                    ENDM

; IN  EBX:EAX       Physical base address
FreePhysical    MACRO
    OsGate free_physical_nr
                    ENDM

; OUT EBX:EAX       Physical base address
Allocate2MPhysical64    MACRO
    OsGate allocate_2m_physical_64_nr
                    ENDM

; OUT EBX:EAX       Physical base address
Allocate2MPhysical32    MACRO
    OsGate allocate_2m_physical_32_nr
                    ENDM

; IN  EBX:EAX       Physical base address
Free2MPhysical    MACRO
    OsGate free_2m_physical_nr
                    ENDM

; OUT EBX:EAX       Highest physical address
GetHighestPhysical    MACRO
    OsGate get_highest_physical_nr
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


FaultReset    MACRO
    OsGate fault_reset_nr
                        ENDM

;   IN  AL      Global int #
;   OUT EDX:EAX IO-APIC state
GetIoApicState    MACRO
    OsGate get_ioapic_state_nr
                        ENDM

;   OUT EDX     APIC ID
GetApicId    MACRO
    OsGate get_apic_id_nr
                        ENDM

;   OUT CX      Core count
GetCoreCount    MACRO
    OsGate get_core_count_nr
                        ENDM

;   IN  EDX     Base of core GDT
;   OUT AX      Core #
;   OUT ES      Core selector
CreateCore    MACRO
    OsGate create_core_nr
                        ENDM

;   OUT FS      Core selector
GetCore    MACRO
    OsGate get_core_nr
                        ENDM

;   IN  AX      Core #
;   OUT FS      Core selector
GetCoreNumber    MACRO
    OsGate get_core_num_nr
                        ENDM

RunApCore    MACRO
    OsGate run_ap_core_nr
                        ENDM

UseOwnPreemptTimer    MACRO
    OsGate use_own_preempt_timer_nr
                        ENDM

PreemptExpired    MACRO
    OsGate preempt_expired_nr
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

;   IN  FS      Processor selector
StartCore    MACRO
    OsGate start_core_nr
                    ENDM

ShutdownCore    MACRO
    OsGate shutdown_core_nr
                    ENDM

;   OUT AX     Processor #
AllocateRealtimeCore    MACRO
    OsGate allocate_realtime_core_nr
                    ENDM

;   IN  AX      Processor #
FreeRealtimeCore    MACRO
    OsGate free_realtime_core_nr
                    ENDM

;   IN  FS      Processor #
DebugRealtime    MACRO
    OsGate debug_realtime_nr
                    ENDM

;   IN  FS      Processor #
RunRealtime    MACRO
    OsGate run_realtime_nr
                    ENDM

;   IN  AL      Apic ID
;   IN  EBX     CR3
;   IN  ES:EDI  Boot startup code
BootRealtimeCore    MACRO
    OsGate boot_realtime_core_nr
                    ENDM

EnterC3    MACRO
    OsGate enter_c3_nr
                    ENDM

InitFreq    MACRO
    OsGate init_freq_nr
                    ENDM

;  EAX  Difference  (-1 = decrease, +1 = increase)  
UpdateFreq    MACRO
    OsGate update_freq_nr
                    ENDM

;   OUT AX      Thread ID
CreateThreadId    MACRO
    OsGate create_thread_id_nr
                        ENDM

;  IN  ES   Thread sel
;  IN  AX   Core #
SetThreadCore    MACRO
    OsGate set_thread_core_nr
                    ENDM

;  OUT AX   TID
CreatePid    MACRO
    OsGate create_pid_nr
                    ENDM

;  IN  EBX      Selector
;  OUT AX       PID
ProgramCreated    MACRO
    OsGate program_created_nr
                    ENDM

;  IN  EBX      Selector
ProgramTerminated    MACRO
    OsGate program_terminated_nr
                    ENDM

;  IN  EBX      Program ID
;  OUT AX       Selector
GetProgramSel    MACRO
    OsGate get_program_sel_nr
                    ENDM

;  IN  EAX      Program #
;  OUT AX       ID
GetProgramId    MACRO
    OsGate get_program_id_nr
                    ENDM

;  IN  EBX      Selector
;  OUT AX       MID
ModuleLoaded    MACRO
    OsGate module_loaded_nr
                    ENDM

;  IN  EBX      Selector
ModuleUnloaded    MACRO
    OsGate module_unloaded_nr
                    ENDM

;  IN  EAX      Module #
;  OUT AX       ID
GetModuleId    MACRO
    OsGate get_module_id_nr
                    ENDM

;  IN  EBX      Selector
;  OUT AX       PID
ProcessCreated    MACRO
    OsGate process_created_nr
                    ENDM

;  IN  EBX      Selector
;  IN  EAX      Exit code
ProcessTerminated    MACRO
    OsGate process_terminated_nr
                    ENDM

; IN  EBX       Process ID
; OUT BX        Selector
ProcessIdToSel       MACRO
    OsGate process_id_to_sel_nr
                    ENDM

;  IN  EAX      Process #
;  OUT AX       ID
GetProcessId    MACRO
    OsGate get_process_id_nr
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

; OUT BX      Wait dev handle
CreateWaitDev    MACRO
    OsGate create_wait_dev_nr
                    ENDM

; IN  BX      Wait dev handle
CloseWaitDev    MACRO
    OsGate close_wait_dev_nr
                    ENDM

; IN  BX      Wait dev handle
; IN  ES:EDI  Dev name
PrepareWaitDev    MACRO
    OsGate prepare_wait_dev_nr
                    ENDM

; IN  BX      Wait dev handle
; IN  EDX:EAX Timeout
WaitForDev    MACRO
    OsGate wait_for_dev_nr
                    ENDM

; IN  BX      Wait dev handle
SignalWaitDev    MACRO
    OsGate signal_wait_dev_nr
                    ENDM

; IN  AX      Extra bytes needed in wait object
; IN  BX      Wait handle
; IN  ES:EDI  Method table (init, abort, peek)
; OUT ES      Wait object
AddWait MACRO
    OsGate add_wait_nr
                    ENDM

; IN  AX      Extra bytes needed in wait object
; IN  BX      Wait handle
; IN  ES:EDI  Method table (init, abort, peek & delete)
; OUT ES      Wait object
AddWaitDelete MACRO
    OsGate add_wait_del_nr
                    ENDM

; IN  ES      Wait object
SignalWait      MACRO
    OsGate signal_wait_nr
                    ENDM

;;;;;;;;;;; Spinlocks ;;;;;;;;;;;;;;;;

InitSpinlock     MACRO spinlock
    mov spinlock.sl_value,0
                        ENDM

RequestSpinlock MACRO spinlock
    local rs_lock
    local rs_get
    local rs_done
    local rs_pause

    push ax
    push cx
;
    xor cx,cx

rs_lock:    
    mov ax,spinlock.sl_value
    or ax,ax
    je rs_get
;
    sti
    add cx,1
    jnc rs_pause
;
    CrashGate

rs_pause:    
    pause
    jmp rs_lock

rs_get:
    cli
    inc ax
    xchg ax,spinlock.sl_value
    or ax,ax
    je rs_done
;
    jmp rs_lock

rs_done:
    pop cx
    pop ax
    ENDM


ReleaseSpinlock MACRO spinlock
    mov spinlock.sl_value,0
    sti
    ENDM

ReleaseSpinlockNoSti MACRO spinlock
    mov spinlock.sl_value,0
    ENDM

;;;;;;;;;;; Critical section ;;;;;;;;;;;;;;;;

InitSection     MACRO section
    mov section.cs_value,0
    mov section.cs_list,0
    mov section.cs_lock,0
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


EnterGsSection    MACRO section
    LOCAL enter_section_donep

    pushf
    lock sub section.cs_value,1
    jc enter_section_donep
;
    push ds
    push esi
;
    mov si,gs
    mov ds,si
    lea esi,section
    OsGate enter_section_nr
;
    pop esi
    pop ds

enter_section_donep:
    popf
                        ENDM

LeaveGsSection    MACRO section
    LOCAL leave_section_donep

    pushf
    lock add section.cs_value,1
    jc leave_section_donep
;
    push ds
    push esi
;
    mov si,gs
    mov ds,si
    lea esi,section
    OsGate leave_section_nr
;
    pop esi
    pop ds

leave_section_donep:
    popf
                        ENDM

CondEnterSection    MACRO section
    LOCAL enter_section_donep
    lock sub section.cs_value,1
    jc enter_section_donep
    push esi
    lea esi,section
    OsGate cond_enter_section_nr
    pop esi
enter_section_donep:
                        ENDM

InitReadWriteSection    MACRO section
    mov section.ssync_value,0
    mov section.ssync_list,0
    mov section.ssync_lock,0
    mov section.sread_value,0
    mov section.swrite_value,0
    mov section.swrite_list,0
    mov section.swrite_lock,0
                        ENDM

EnterReadSection    MACRO section
    LOCAL enter_sync_ok,enter_read_ok,enter_read_done
    pushf
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
    lock add section.swrite_value,1
    jc leave_section_done
    push esi
    mov esi,OFFSET section.swrite_value
    OsGate leave_section_nr
    pop esi
leave_section_done:
    popf
                        ENDM

;  AX       Futex ID
SetFutexId MACRO
    OsGate set_futex_id_nr
                    ENDM

;  EDX:EAX       TLS linear
SetLongTlsLinear MACRO
    OsGate set_long_tls_linear_nr
                    ENDM

;;;;;;;;;;; MULTITASKING ;;;;;;;;;;;;;;;;

SetupSmpPatch MACRO
    OsGate setup_smp_patch_nr
                    ENDM

NotifyThreadSuspend MACRO
    OsGate notify_thread_suspend_nr
                    ENDM

StartTasking MACRO
    OsGate start_tasking_nr
                    ENDM

;       ES:EDI       ADDRESS TILL CALLBACK
HookInitTasking MACRO
    OsGate hook_init_tasking_nr
                    ENDM

;       ES:EDI       ADDRESS TILL CALLBACK
HookCreateProcess       MACRO
    OsGate hook_create_process_nr
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

StartPreemptTimer    MACRO
    OsGate start_preempt_timer_nr
                        ENDM

;   IN  AX      Tic count
ReloadPreemptTimer    MACRO
    OsGate reload_preempt_timer_nr
                        ENDM

StartSysPreemptTimer    MACRO
    OsGate start_sys_preempt_timer_nr
                        ENDM

;   IN  AX      Tic count
ReloadSysPreemptTimer    MACRO
    OsGate reload_sys_preempt_timer_nr
                        ENDM

;   OUT AX      Lock counter
GetSchedulerLockCounter    MACRO
    OsGate get_scheduler_lock_counter_nr
                        ENDM

;   IN AL       Irq # (-1 for timer/non-specific)
EnterInt    MACRO
    local eiOk

    cli
    mov bx,core_data_sel
    mov fs,bx
    mov fs,fs:cs_sel
    mov bx,fs:cs_irq_count
    cmp bx,MAX_IRQ_NESTING
    jb eiOk
;
    CrashGate

eiOk:
    mov fs:[bx].cs_irq_stack,al
    inc fs:cs_irq_count
    movzx bx,al
    shl bx,2
    inc fs:[bx].cs_irq_arr_counter
    lock add fs:cs_nesting,1
                        ENDM

LeaveInt    MACRO
    local tucRetry
    local tucHandleTimer
    local tucTimerOk
    local tucFlush
    local tucSched
    local tucDone
    local tucSwap
    local tucTlbDone
    local tucLeave

    dec fs:cs_irq_count

tucRetry:    
    cli    
    lock sub fs:cs_nesting,1
    jnc tucDone
;
    test fs:cs_flags,CS_FLAG_TIMER_EXPIRED
    jz tucTimerOk
;
    lock add fs:cs_nesting,1
    jc tucHandleTimer
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz tucHandleTimer
;    
    CrashGate

tucHandleTimer:
    sti
    OsGate timer_expired_nr
    jmp tucRetry
    
tucTimerOk:      
    mov ax,fs:cs_curr_thread
    or ax,ax
    jz tucDone
;
    mov eax,fs:cs_tlb.pt32_used
    or eax,eax
    jz tucTlbDone
;
    lock add fs:cs_nesting,1
    jc tucFlush
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz tucFlush
;    
    CrashGate

tucFlush:
    sti
    OsGate do_flush_tlb_nr
    jmp tucRetry

tucTlbDone:    
    test fs:cs_flags,CS_FLAG_PREEMPT
    jnz tucSwap
;    
    mov ax,fs:cs_wakeup_count
    or ax,ax
    jz tucDone

tucSwap:
    lock add fs:cs_nesting,1
    jc tucSched
;
    mov ax,fs:cs_nesting
    or ax,ax
    jz tucSched
;    
    CrashGate    

tucSched:
    sti
    OsGate irq_schedule_nr
    jmp tucLeave

tucDone:
    sti

tucLeave:
                        ENDM



;  OUT FS       Core sel
TryLockTask    MACRO
    OsGate try_lock_task_nr
                        ENDM

LockTask    MACRO
    OsGate lock_task_nr
                        ENDM

UnlockTask    MACRO
    OsGate unlock_task_nr
                        ENDM

;  OUT  AX Locked core
EnterLongInt    MACRO
    OsGate enter_long_int_nr
                        ENDM

;  IN   AX Locked core
LeaveLongInt    MACRO
    OsGate leave_long_int_nr
                        ENDM

LongTimerHandler    MACRO
    OsGate long_timer_handler_nr
                        ENDM

LongHpetHandler    MACRO
    OsGate long_hpet_handler_nr
                        ENDM

UpdatePstate  MACRO                        
    OsGate update_pstate_nr
                        ENDM

; IN CX    Number of entries
; IN EDX   Linear base
FlushTlb    MACRO
    OsGate flush_tlb_nr
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

; IN  AL          PRIORITET
; IN  AH          MODE, 0=Protected mode, 1=V86 mode, 2=Long mode
; IN  BX          Program ID
; IN  ECX         STACK SIZE
; IN  DS:ESI      ADDRESS TO START AT
; IN  ES:EDI      PROCESS NAME
CreateProcess    MACRO
    OsGate create_process_nr
                        ENDM

; IN  AL          Priority
; IN  DS:ESI      Start address
; IN  ES:EDI      Process name
CreateServerProcess    MACRO
    OsGate create_serv_proc_nr
                        ENDM

; IN  AL          Priority
; IN  BH          Device #
; IN  BL          Unit #
; IN  DS:ESI      Parameters
; IN  ES:EDI      Server name
; OUT BX          Server app sel
LoadServer        MACRO
    OsGate load_serv_nr
                        ENDM

; IN  BX          Program #
; IN  ES          Server app sel
CreateServerApp        MACRO
    OsGate create_serv_app_nr
                        ENDM

; IN  BX          Program #
; IN  ES          Server app sel
ExecServer        MACRO
    OsGate exec_serv_nr
                        ENDM

; IN  BX    Thread #
; OUT BX    Thread sel
ThreadToSel     MACRO
    OsGate thread_to_sel_nr
            ENDM

; OUT  AX       0 = child
ForkProcess    MACRO
    OsGate fork_process_nr
                        ENDM

; IN  ECX       Stack size
CreateAppThread MACRO
    OsGate create_app_thread_nr
                    ENDM
; IN  EBP                Thread stack
;        +0              EBP
;        +4              EIP
;        +12             ESP 
TerminateAppThread MACRO
    OsGate terminate_app_thread_nr
                    ENDM

;;;;;;;;;;; Crash handler ;;;;;;;;;;;;;;;;

SetupNmiCoreDump       MACRO
    OsGate setup_nmi_core_dump_nr
                    ENDM

; IN  AL        IRQ #
SetupLongNmiCoreDump   MACRO
    OsGate setup_long_nmi_core_dump_nr
                    ENDM
StartSmpCoreDump       MACRO
    OsGate start_smp_core_dump_nr
                    ENDM

;  OUT DS:EBP   Address of core-dump
StartCoreDump       MACRO
    OsGate start_core_dump_nr
                    ENDM

;  IN  DS:EBP   Address of core-dump
NotifyCoreDump       MACRO
    OsGate notify_core_dump_nr
                    ENDM

CrashGate       MACRO
    int 84h
                    ENDM

;;;;;;;;;;; Debugger ;;;;;;;;;;;;;;;;

;   FS      Core
DebugBlock    MACRO
    OsGate debug_block_nr
                        ENDM

;   SS:EBP     Exception stack
DebugException    MACRO
    OsGate debug_exception_nr
                        ENDM

;   SS:EBP     Exception stack
LockedDebugException    MACRO
    OsGate locked_debug_exception_nr
                        ENDM

DebugExcBreak      MACRO
    OsGate debug_exc_break_nr
                    ENDM

; OUT AX           Thread ID
GetDebugThreadSel MACRO
    OsGate get_debug_thread_sel_nr
                        ENDM

; IN  GS           Program selector
; IN  ES           Event  
SendDebugEvent MACRO
    OsGate send_debug_event_nr
                        ENDM

; IN  ES           Thread
KernelDebugEvent MACRO
    OsGate kernel_debug_event_nr
                        ENDM

;;;;;;; INTERRUPTS & EXCEPTIONS ;;;;;;;;

InitTrapGates  MACRO
    OsGate init_trap_gates_nr
                    ENDM

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

; IN  ES:EDI       Serio function table
; IN  DH           Device #
AddSerIoDevice  MACRO
    OsGate add_serio_device_nr
                    ENDM

;;;;;;;;;; IRQ ;;;;;;;;;;;;;;;;;;;

IrqSchedule    MACRO
    OsGate irq_schedule_nr
                    ENDM

; IN  CX        Number of ints (1,2,4,8,16 or 32)
; IN  AL        Priority (0..31)
; OUT AL        Int base
AllocateInts    MACRO
    OsGate allocate_ints_nr
                    ENDM

; IN  AL        Int #
FreeInt    MACRO
    OsGate free_int_nr
                    ENDM

;       AL              IRQ NR
SendEoi MACRO
    OsGate send_eoi_nr
                    ENDM

;       AL              IRQ NR
NotifyIrq MACRO
    OsGate notify_irq_nr
                    ENDM

; OUT EAX     Active IRQ lines
DisableAllIrq   MACRO
    OsGate disable_all_irq_nr
                    ENDM

; IN  AL        IRQ
; IN  FS        Core
; OUT EDX       MSI address
; OUT AX        MSI data
GetMsiVector    MACRO
    OsGate get_msi_vector_nr
                    ENDM

; IN  AL        Int base
; IN  AH        Priority
; IN  DS        Data passed to handler
; IN  ES:EDI    Handler address
RequestMsiHandler    MACRO
    OsGate request_msi_handler_nr
                    ENDM

; IN  AL        Global int #
; IN  AH        Priority
; IN  DS        Data passed to handler
; IN  ES:EDI    Handler address
RequestIrqHandler    MACRO
    OsGate request_irq_handler_nr
                    ENDM

; IN  DS        Data passed to handler
; IN  ES:EDI    Handler address
SetupNmiHandler    MACRO
    OsGate setup_nmi_handler_nr
                    ENDM

; IN  AL        Global int #
ForceLevelIrq    MACRO
    OsGate force_level_irq_nr
                    ENDM

SetupIrqDetect  MACRO
    OsGate setup_irq_detect_nr
                    ENDM

;   EDX:EAX      Detected IRQs
PollIrqDetect   MACRO
    OsGate poll_irq_detect_nr
                    ENDM

; IN  AL        IRQ #
; OUT ESI       IRQ entrypoint
CreateLongIrq   MACRO
    OsGate create_long_irq_nr
                    ENDM

; IN  ESI       IRQ entrypoint
; IN  DS        Handler data
; IN  ES:EDI    Handler address
AddLongIrq   MACRO
    OsGate add_long_irq_nr
                    ENDM

; OUT ESI       Handler address
CreateLongMsi   MACRO
    OsGate create_long_msi_nr
                    ENDM

; IN  ESI       MSI entrypoint
; IN  DS        Handler data
; IN  ES:EDI    Handler address
AddLongMsi   MACRO
    OsGate add_long_msi_nr
                    ENDM

; IN  AL        IRQ #
SetupLongSpuriousInt   MACRO
    OsGate setup_long_spurious_int_nr
                    ENDM

; IN  AL        IRQ #
SetupLongScheduleInt   MACRO
    OsGate setup_long_schedule_int_nr
                    ENDM

; IN  AL        IRQ #
SetupLongTimerInt   MACRO
    OsGate setup_long_timer_int_nr
                    ENDM

; IN  AL        IRQ #
SetupLongPreemptInt   MACRO
    OsGate setup_long_preempt_int_nr
                    ENDM

; IN  AL        IRQ #
SetupLongHpetInt   MACRO
    OsGate setup_long_hpet_int_nr
                    ENDM

; IN  AL        IRQ #
SetupLongCrashGate   MACRO
    OsGate setup_long_crash_gate_nr
                    ENDM

;;;;;;;;; TIME & DATE ;;;;;;;;;;;;;

;       EDX:EAX     SYSTEM TIME
SetSystemTime   MACRO
    OsGate set_system_time_nr
                    ENDM

NotifyTimeDrift MACRO
    OsGate notify_time_drift_nr
                    ENDM

UpdateRtc   MACRO
    OsGate update_rtc_nr
                    ENDM


;;;;;;;;;; Kernel log ;;;;;;;;;;;;;;;;;;

; IN ES:EDI    Log section
LockLog  MACRO
    OsGate lock_log_nr
                    ENDM

UnlockLog  MACRO
    OsGate unlock_log_nr
                    ENDM

LogThread  MACRO
    OsGate log_thread_nr
                    ENDM

LogMemory  MACRO
    OsGate log_memory_nr
                    ENDM

LogSmallMemory  MACRO
    OsGate log_small_mem_nr
                    ENDM

LogBigMemory  MACRO
    OsGate log_big_mem_nr
                    ENDM

; IN ES:EDI    Text to log
LogText  MACRO
    OsGate log_text_nr
                    ENDM

; IN AL        Value
LogHexByte  MACRO
    OsGate log_hex_byte_nr
                    ENDM

; IN AX        Value
LogHexWord  MACRO
    OsGate log_hex_word_nr
                    ENDM

; IN EAX        Value
LogHexDword  MACRO
    OsGate log_hex_dword_nr
                    ENDM

;;;;;;;;;; HANDLES ;;;;;;;;;;;;;;;;;;

CreateHandleData  MACRO
    OsGate create_handle_data_nr
                    ENDM

DestroyHandleData  MACRO
    OsGate destroy_handle_data_nr
                    ENDM

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


;;;;;;;;;;;;;; sys handle  ;;;;;;;;;;;;;;;;;;

; IN  ES       New process thread
CreateProcHandle MACRO
    OsGate create_proc_handle_nr
                    ENDM

; IN  ES       New process thread
CloneProcHandle MACRO
    OsGate clone_proc_handle_nr
                    ENDM

ApplyProcHandle MACRO
    OsGate apply_proc_handle_nr
                    ENDM

; IN  ES       Delete process thread
DeleteProcHandle MACRO
    OsGate delete_proc_handle_nr
                    ENDM

;;;;;;;;;;;;;; Application / process  ;;;;;;;;;;;;;;;;;;

ExecApp MACRO
    OsGate exec_app_nr
                    ENDM

;  DS:ESI       Program name
;  ES:EDI       Cmd line
InitLongExe     MACRO
    OsGate init_long_exe_nr
                    ENDM

StartLongExe     MACRO
    OsGate start_long_exe_nr
                    ENDM


; OUT  DS:ESI   Startup procedure
GetExeStart32     MACRO
    OsGate get_exe_start32_nr
                    ENDM

; IN  BX        Process ID
; IN  AX        Entry #
; OUT BX        Module ID
GetModuleByIndex    MACRO
    OsGate get_module_by_index_nr
                    ENDM

; IN  BX        Process ID
; IN  EDX       Address
; OUT AX        Entry #
; OUT BX        Module ID
FindModuleByAddress    MACRO
    OsGate find_module_by_address_nr
                    ENDM

; IN  BX        Process ID
; IN  FS:ESI    Module name
; OUT AX        Entry #
; OUT BX        Module ID
FindModuleByName    MACRO
    OsGate find_module_by_name_nr
                    ENDM

; IN  EBX    Module ID
; OUT BX    Lib sel
ModuleIdToSel       MACRO
    OsGate module_id_to_sel_nr
                    ENDM

; IN  BX    Lib sel
; OUT BX    Module handle
AliasModuleHandle       MACRO
    OsGate alias_module_handle_nr
                    ENDM

; IN  ES        Handle sel
InitHandle  MACRO
    OsGate init_handle_nr
                    ENDM

; IN  ES       Sys interface
InitSysHandle MACRO
    OsGate init_sys_handle_nr
                    ENDM

; IN  DS         Sys interface
; IN  EAX        Size of object
; IN  EDX        Linear address of object        
; OUT AX         Kernel interface
CreateKernelHandle MACRO
    OsGate create_kernel_handle_nr
                    ENDM


; IN  DS       Sys interface
; OUT EBX      Sys handle
AllocateSysHandle MACRO
    OsGate allocate_sys_handle_nr
                    ENDM

; IN  ES:EDI      Filename
; IN  CX          Mode
; OUT DS          Sys handle obj
OpenLegacyHandle  MACRO
    OsGate open_legacy_handle_nr
                    ENDM

; OUT AX        Handle sel
CreateInputHandle  MACRO
    OsGate create_input_handle_nr
                    ENDM

; OUT AX        Handle sel
CreateOutputHandle  MACRO
    OsGate create_output_handle_nr
                    ENDM


; OUT AX        C handle selector
CreateCHandle MACRO
    OsGate create_c_handle_nr
                    ENDM

; IN  AX        C handle selector to clone
; OUT AX        New C handle selector
CloneCHandle MACRO
    OsGate clone_c_handle_nr
                    ENDM

; IN  AX        C handle selector
DeleteCHandle MACRO
    OsGate delete_c_handle_nr
                    ENDM

; IN  AX        Entry type
; IN  DX        Selector
; OUT BX        Entry handle
AllocateCHandle MACRO
    OsGate allocate_c_handle_nr
                    ENDM

; IN  BX        Handle
SignalReadHandle MACRO
    OsGate signal_read_handle_nr
                    ENDM

; IN  BX        Handle
SignalWriteHandle MACRO
    OsGate signal_write_handle_nr
                    ENDM

; IN  BX        Handle
SignalExceptionHandle MACRO
    OsGate signal_exc_handle_nr
                    ENDM

; IN  AX        Entry type
; IN  BX        Entry handle
; IN  DX        Selector
; OUT BX        Entry handle
RefCHandle MACRO
    OsGate ref_c_handle_nr
                    ENDM

; IN  ES:EDI    Filename
; IN  CX        Mode
; OUT BX        Entry handle
OpenLegacyFile MACRO
    OsGate open_legacy_file_nr
                    ENDM

; IN  BX        File selector
; IN  EDX:EAX   Position
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT ECX       Read size
; OUT EDX:EAX   New position
ReadLegacyFile MACRO
    OsGate read_legacy_file_nr
                    ENDM

; IN  BX        File selector
; IN  EDX       Position
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT EAX       Written size
; OUT EDX       New position
WriteLegacyFile MACRO
    OsGate write_legacy_file_nr
                    ENDM

; IN  BX        File selector
; OUT EAX       File size
GetLegacyFileSize MACRO
    OsGate get_legacy_file_size_nr
                    ENDM

; IN  BX        File selector
; IN  EAX       File size
SetLegacyFileSize MACRO
    OsGate set_legacy_file_size_nr
                    ENDM

; IN  BX            File selector
; OUT EDX:EAX       File time
GetLegacyFileTime MACRO
    OsGate get_legacy_file_time_nr
                    ENDM

; IN  BX            File selector
; IN  EDX:EAX       File time
SetLegacyFileTime MACRO
    OsGate set_legacy_file_time_nr
                    ENDM

; IN  BX        File selector
; IN  AX        Handle
StartReadLegacyFile               MACRO
    OsGate start_read_legacy_file_nr
                        ENDM

; IN  BX        File selector
StopReadLegacyFile               MACRO
    OsGate stop_read_legacy_file_nr
                        ENDM

; IN  BX        File selector
CloseLegacyFile MACRO
    OsGate close_legacy_file_nr
                    ENDM

; IN  ES:EDI    Filename
; IN  CX        Mode
; OUT BX        Handle
OpenLegacyKernelFile MACRO
    OsGate open_legacy_kernel_file_nr
                    ENDM

; IN  BX        File selector
; OUT BX        Handle
RefLegacyKernelFile MACRO
    OsGate ref_legacy_kernel_file_nr
                    ENDM

; IN  BX        C handle
; IN  CX        Mode
; OUT BX        Process handle
AllocateCProcHandle MACRO
    OsGate allocate_c_proc_handle_nr
                    ENDM

; IN  ES:EDI    Filename
; IN  CX        Mode
; OUT BX        Handle
OpenKernelHandle MACRO
    OsGate open_kernel_handle_nr
                    ENDM

; IN  BX        Kernel handle
; OUT BX        New user handle
DuplKernelHandle MACRO
    OsGate dupl_kernel_handle_nr
                    ENDM

; IN  BX        Handle
; IN  EDX:EAX   Position
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT ECX       Read size
; OUT EDX:EAX   New position
ReadKernelHandle MACRO
    OsGate read_kernel_handle_nr
                    ENDM

; IN  BX        Handle
; IN  EDX       Position
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT ECX       Written size
; OUT EDX:EAX   New position
WriteKernelHandle MACRO
    OsGate write_kernel_handle_nr
                    ENDM

; IN  BX        Handle
CloseKernelHandle MACRO
    OsGate close_kernel_handle_nr
                    ENDM

; OUT BX       Console selector
GetFocusConsole MACRO
    OsGate get_focus_console_nr
                    ENDM

; IN  BX       Console selector
SetFocusConsole MACRO
    OsGate set_focus_console_nr
                    ENDM

; OUT BX       Console selector
CreateConsole MACRO
    OsGate create_console_nr
                    ENDM

; IN  BX       Console selector
CloseConsole MACRO
    OsGate close_console_nr
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

;  ES:EDI       Command line
GetDeviceCmdLine  MACRO
    OsGate get_device_cmd_line_nr
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

; IN  AX        Handle
StartReadStdin               MACRO
    OsGate start_read_stdin_nr
                        ENDM

StopReadStdin               MACRO
    OsGate stop_read_stdin_nr
                        ENDM

;;;;;;;;;; Environment ;;;;;;;;;;;;;


; OUT AX        Env selector
CreateEnvSel      MACRO
    OsGate create_env_sel_nr
            ENDM

; IN  AX        Env selector to clone
; OUT AX        New env selector
CloneEnvSel      MACRO
    OsGate clone_env_sel_nr
            ENDM

; IN  AX        Env selector
DeleteEnvSel      MACRO
    OsGate delete_env_sel_nr
            ENDM

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

; IN  DS:(E)SI      Env var name
; IN  ES:(E)DI      Env var data
AddSysEnvVar    MACRO
        OsGate add_sys_env_var_nr
                ENDM

; IN  DS:(E)SI      Env var name
DeleteSysEnvVar MACRO
        OsGate delete_sys_env_var_nr
                ENDM

; IN  DS:(E)SI      Env var name
; IN  ES:(E)DI      Env var data
FindSysEnvVar   MACRO
        OsGate find_sys_env_var_nr
                ENDM

;;;;;;;;;;;; Focus ;;;;;;;;;;;;;

;       AX          Focus thread
GetFocusThread  MACRO
    OsGate get_focus_thread_nr
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

;       BX          Protocol handle
;       ES:EDI      Address to check
SetupNetCachable     MACRO
    OsGate setup_net_cachable_nr
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

; IN  BX        Protocol handle
; IN  DS:ESI    Logical address
; OUT ES:EDI    Physical address
; OUT ECX       Size of address
; OUT NC        OK
GetNetAddress    MACRO
    OsGate get_net_address_nr
                        ENDM

; IN  BX        Protocol handle
; IN  DS:ESI    Gateway logical address
; IN  ES:EDI    Mac buffer
; OUT NC        SUCCESS
GetNetMac    MACRO
    OsGate get_net_mac_nr
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

; IN  FS        Driver handle
; IN  ECX       Size
; OUT ES:EDI    Data buffer to use
; OUT NC        Success
GetNetDriverBuffer      MACRO
    OsGate get_net_driver_buffer_nr
                        ENDM

; IN  BX        Protocol handle
; IN  FS        Driver handle
; IN  ECX       Size
; IN  ES        Data buffer
; IN  DS:ESI    Dest address
; OUT NC        Success
SendNetDriver   MACRO
    OsGate send_net_driver_nr
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

; IN  BX        Protocol handle
; IN  FS        Driver sel
; IN  DS:ESI    Logical destination
ReqArp    MACRO
    OsGate req_arp_nr
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

; IN  ES:EDI       Net link up callback
;           FS     Driver sel
HookNetLinkUp  MACRO
    OsGate hook_net_link_up_nr
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

; IN  AL        Protocol
; IN  AH        Time to live
; IN  ECX       Size of data
; IN  EDX       IP
; IN  FS        Driver selector
; IN  DS:ESI    Options
; OUT ES:EDI    IP Data
CreateDriverIp       MACRO
    OsGate create_driver_ip_nr
                        ENDM

; IN  ES        Datagram to send
; IN  FS        Driver selector
; IN  DS:ESI    Destination address
SendDriverIp MACRO
    OsGate send_driver_ip_nr
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
; IN    EDX     IP source
; IN    CX      UDP request size
; IN    ES:EDI  UDP request data
; OUT   CX      UDP reply size
; OUT   ES:EDI  UDP reply data
ListenUdpPort   MACRO
    OsGate listen_udp_port_nr
            ENDM

; IN  SI        source port
; IN  BX        destination port
; IN  CX        Number of bytes to send
; IN  FS        Driver sel
; IN  ES:EDI    Data buffer
BroadcastDriverUdp    MACRO
    OsGate broadcast_driver_udp_nr
            ENDM

; IN  AX        source port
; IN  BX        destination port
; IN  CX        Number of bytes to send
; IN  EDX       IP address
; IN  FS        Driver sel
; IN  DS:ESI    Destination address
; IN  ES:EDI    Data buffer
SendDriverUdp    MACRO
    OsGate send_driver_udp_nr
            ENDM

; IN  ES:EDI  Pointer to data
; IN  ECX     Size of data
NotifyEthernetPacket    MACRO
    OsGate notify_ethernet_packet_nr
                    ENDM

; IN  EDX       Remote IP
; IN  DI        Remote port
; IN  CX        New MTU
UpdateTcpMtu    MACRO
    OsGate update_tcp_mtu_nr
                    ENDM

; IN  EDX       IP
; IN  SI        port
; OUT AX        Tcp selector
ConnectTcpSocket               MACRO
    OsGate connect_tcp_socket_nr
                        ENDM

; IN  BX        Tcp selector
CloseTcpSocket MACRO
    OsGate close_tcp_socket_nr
                    ENDM

; IN  BX        Tcp selector
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT EAX       Read size
PollTcpSocket MACRO
    OsGate poll_tcp_socket_nr
                    ENDM

; IN  BX        Tcp selector
; IN  EDX:EAX   Position
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT ECX       Read size
; OUT EDX:EAX   New position
ReadTcpSocket MACRO
    OsGate read_tcp_socket_nr
                    ENDM

; IN  BX        Tcp selector
; IN  EDX       Position
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT EAX       Written size
; OUT EDX       New position
WriteTcpSocket MACRO
    OsGate write_tcp_socket_nr
                    ENDM

; IN  BX        Tcp selector
; IN  AX        Handle
StartReadTcpSocket               MACRO
    OsGate start_read_tcp_socket_nr
                        ENDM

; IN  BX        Tcp selector
StopReadTcpSocket               MACRO
    OsGate stop_read_tcp_socket_nr
                        ENDM

; IN  BX        Tcp selector
; IN  AX        Handle
StartWriteTcpSocket               MACRO
    OsGate start_write_tcp_socket_nr
                        ENDM

; IN  BX        Tcp selector
StopWriteTcpSocket               MACRO
    OsGate stop_write_tcp_socket_nr
                        ENDM

; IN  BX        Tcp selector
; IN  AX        Handle
StartExceptionTcpSocket               MACRO
    OsGate start_exc_tcp_socket_nr
                        ENDM

; IN  BX        Tcp selector
StopExceptionTcpSocket               MACRO
    OsGate stop_exc_tcp_socket_nr
                        ENDM

; IN  BX        Tcp selector
; IN  ECX       Bytes in buffer
GetTcpSocketReadCount               MACRO
    OsGate tcp_socket_read_count_nr
                        ENDM

; IN  BX        Tcp selector
; IN  ECX       Space in buffer
GetTcpSocketWriteSpace               MACRO
    OsGate tcp_socket_write_space_nr
                        ENDM

; IN  BX        Tcp selector
HasTcpSocketException               MACRO
    OsGate has_tcp_socket_exc_nr
                        ENDM


; IN  BX        Connection handle
StartTcpConnectionNotify               MACRO
    OsGate start_tcp_conn_notify_nr
                        ENDM

; IN  BX        Connection handle
StopTcpConnectionNotify               MACRO
    OsGate stop_tcp_conn_notify_nr
                        ENDM

; IN  EDX       IP
; IN  SI        port
; OUT AX        Udp selector
ConnectUdpSocket               MACRO
    OsGate connect_udp_socket_nr
                        ENDM

; IN  BX        Udp selector
CloseUdpSocket MACRO
    OsGate close_udp_socket_nr
                    ENDM

; IN  BX        Udp selector
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT EAX       Read size
PollUdpSocket MACRO
    OsGate poll_udp_socket_nr
                    ENDM

; IN  BX        Udp selector
; IN  EDX:EAX   Position
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT ECX       Read size
; OUT EDX:EAX   New position
ReadUdpSocket MACRO
    OsGate read_udp_socket_nr
                    ENDM

; IN  BX        Tcp selector
; IN  EDX       Position
; IN  ES:EDI    Buffer
; IN  ECX       Size
; OUT EAX       Written size
; OUT EDX       New position
WriteUdpSocket MACRO
    OsGate write_udp_socket_nr
                    ENDM

; IN  BX        Udp selector
; IN  AX        Handle
StartReadUdpSocket               MACRO
    OsGate start_read_udp_socket_nr
                        ENDM

; IN  BX        Udp selector
StopReadUdpSocket               MACRO
    OsGate stop_read_udp_socket_nr
                        ENDM

; IN  BX        Tcp selector
; IN  ECX       Bytes in buffer
GetUdpSocketReadCount               MACRO
    OsGate udp_socket_read_count_nr
                        ENDM

;;;;;;;;;;; VFS ;;;;;;;;;;;;

WaitForVfsDiscs    MACRO
    OsGate wait_for_vfs_discs_nr
                    ENDM

;  IN  ES:ESI    Server proc
;  IN  ES:EDI    Server name
;  IN  BX        Data passed to server
;  OUT BX        VFS handle
StartVfs    MACRO
    OsGate start_vfs_nr
                    ENDM

;  IN  BX       VFS handle
StopVfs    MACRO
    OsGate stop_vfs_nr
                    ENDM

;  IN  AL              Disc #
;  OUT CX              Bytes / sector
;  OUT     EDX:EAX     Total # of sectors
;  OUT SI              BIOS sectors / cylinder
;  OUT DI              BIOS heads
GetVfsDiscInfo     MACRO
        OsGate get_vfs_disc_info_nr
                    ENDM

;  IN  AL              Disc #
;  IN  ES:EDI          Vendor buffer
;  IN  ECX             Buffer size
GetVfsDiscVendorInfo     MACRO
        OsGate get_vfs_disc_vendor_info_nr
                    ENDM

;  IN  BL              Disc #
;  IN  EDX:EAX         Sector
;  IN  ES:EDI          Buffer
;  IN  ECX             Size
ReadVfsDisc     MACRO
        OsGate read_vfs_disc_nr
                    ENDM

;  IN  BL              Disc #
;  IN  EDX:EAX         Sector
;  IN  ES:EDI          Buffer
;  IN  ECX             Size
WriteVfsDisc     MACRO
        OsGate write_vfs_disc_nr
                    ENDM

;  IN  ES:EDI          Pathname
;  OUT EAX             Attrib
GetVfsDirEntryAttrib     MACRO
        OsGate get_vfs_dir_entry_attrib_nr
                    ENDM

;  IN  ES:EDI          Pathname
SetVfsCurDir     MACRO
        OsGate set_vfs_cur_dir_nr
                    ENDM

;  IN  DS          Source dir
;  IN  ES          Dest dir
CloneVfsCurDir     MACRO
        OsGate clone_vfs_cur_dir_nr
                    ENDM

;  IN  AX              Curr dir sel
FreeVfsCurDir     MACRO
        OsGate free_vfs_cur_dir_nr
                    ENDM

;;;;;;;;;;; DRIVE ;;;;;;;;;;;;

BeginDiscHandler    MACRO
    OsGate begin_disc_handler_nr
                    ENDM

EndDiscHandler    MACRO
    OsGate end_disc_handler_nr
                    ENDM

SetDiscUse32    MACRO
    OsGate set_disc_use32_nr
                    ENDM

; IN  BX          Handle
; IN  ECX         Read-ahead
; OUT AL          Disc #
; OUT BX          Disc sel
InstallStaticDisc     MACRO
    OsGate install_static_disc_nr
                    ENDM

; IN  BX          Handle
; IN  ECX         Read-ahead
; OUT AL          Disc #
; OUT BX          Disc sel
InstallDynamicDisc     MACRO
    OsGate install_dynamic_disc_nr
                    ENDM

; IN  BX          Handle
; IN  ECX         Read-ahead
; OUT AL          Disc #
; OUT BX          Disc sel
InstallFixedDisc     MACRO
    OsGate install_fixed_disc_nr
                    ENDM

BeginVfsDisc    MACRO
    OsGate begin_vfs_disc_nr
                    ENDM

EndVfsDisc    MACRO
    OsGate end_vfs_disc_nr
                    ENDM

; OUT AL          Disc #
InstallVfsDisc     MACRO
    OsGate install_vfs_disc_nr
                    ENDM

; IN  AL          Disc #
RemoveVfsDisc     MACRO
    OsGate remove_vfs_disc_nr
                    ENDM

; OUT AL          Drive #
AllocateStaticVfsDrive     MACRO
    OsGate allocate_static_vfs_drive_nr
                    ENDM

; OUT AL          Drive #
AllocateDynamicVfsDrive     MACRO
    OsGate allocate_dynamic_vfs_drive_nr
                    ENDM

; IN  AL          Drive #
AllocateFixedVfsDrive     MACRO
    OsGate allocate_fixed_vfs_drive_nr
                    ENDM

; IN  AL          Drive #
CloseVfsDrive     MACRO
    OsGate close_vfs_drive_nr
                    ENDM

; IN  AL          Drive #
CheckVfsDrive     MACRO
    OsGate check_vfs_drive_nr
                    ENDM

; IN  AL          Drive #
; IN  ES:EDI      Path name
GetVfsCurDir     MACRO
    OsGate get_vfs_cur_dir_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      ES:EDI   Disc change procedure
RegisterDiscChange      MACRO
    OsGate register_disc_change_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      ES:EDI   Demand mount procedure
RegisterDemandMount      MACRO
    OsGate register_demand_mount_nr
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
;       IN  EDX     Units
;       IN  SI      BIOS sectors / cylinder
;       IN  DI      BIOS heads
SetDiscParam    MACRO
    OsGate set_disc_param_nr
                    ENDM

;       IN  BX      Disc sel
;       IN  CX      Bytes per sector
;       IN  EDX:EAX Total sectors
;       OUT AX      Sectors per unit
;       OUT EDX     Units
SetDiscLbaParam    MACRO
    OsGate set_disc_lba_param_nr
                    ENDM

;       IN  BX      Disc sel
;       OUT ES:DI   Vendor buffer
GetDiscVendorInfoBuf    MACRO
    OsGate get_disc_vendor_info_buf_nr
                    ENDM

;       IN      BX      Disc sel
WaitForDiscRequest      MACRO
    OsGate wait_for_disc_request_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      EDI     Disc handle
DiscRequestCompleted    MACRO
    OsGate disc_request_completed_nr
                    ENDM

;       IN      BX      Disc sel
;       IN      EDI     Disc handle
DiscRequestRetry    MACRO
    OsGate disc_request_retry_nr
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

;       IN      BX      Disc sel
StopDiscRequest      MACRO
    OsGate stop_disc_request_nr
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
CheckDrive      MACRO
    OsGate check_drive_nr
                    ENDM

;       IN      AL          Drive #
;       OUT     EAX         Readahead
;       OUT     ECX     Size
;       OUT     SI      Sectors per unit
;       OUT     EDI     Units
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

;  IN   DS:ESI       File system name
;  IN   ES:EDI       File system table
RegisterFileSystem      MACRO
    OsGate register_file_system_nr
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

StartPrograms      MACRO
    OsGate start_programs_nr
                    ENDM

;  IN   BX          Loader selector
RegisterLoader      MACRO
    OsGate register_loader_nr
                    ENDM

; OUT AX        Cur dir selector
CreateCurDir MACRO
    OsGate create_cur_dir_nr
                    ENDM

; IN  AX        Cur dir selector to clone
; OUT AX        New cur dir selector
CloneCurDir MACRO
    OsGate clone_cur_dir_nr
                    ENDM

; IN  AX        Cur dir selector
DeleteCurDir MACRO
    OsGate delete_cur_dir_nr
                    ENDM

;;;;;;;;;;;; VIDEO ;;;;;;;;;;;

;  IN   AX         Mode #
;  IN   ES:EDI     Mode info
NotifyApVideoMode     MACRO
    OsGate notify_ap_video_mode_nr
                    ENDM

;  IN   ES:EDI      UTF-8 string
;  IN   BX          font handle
;  OUT  AX          start x
;  OUT  BX          start y
;  OUT  CX          bitmap width
;  OUT  DX          bitmap height
;  OUT  SI          advance x
;  OUT  ES:EDI      8-bit bitmap
GetUtf8Bitmap     MACRO
    OsGate get_utf8_bitmap_nr
                    ENDM

BeginGetVideoModes       MACRO
    OsGate begin_get_video_modes_nr
                    ENDM

EndGetVideoModes       MACRO
    OsGate end_get_video_modes_nr
                    ENDM

;  IN  AX      bits / pixel
;  IN  BX      Mode nr
;  IN  CX      x-resolution
;  IN  DX      y-resolution
;  IN  SI      line size
;  IN  EDI     LFB
AddVideoMode       MACRO
    OsGate add_video_mode_nr
                    ENDM

;  IN  BX      Mode nr
SwitchVideoMode       MACRO
    OsGate switch_video_mode_nr
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

;  IN  AL      Bits per pixel
;  IN  CX      Width
;  IN  DX      Height
;  IN  ES:EDI  Update proc
;      ECX     Number of pixels
;      ES:ESI  Bitmap buffer
;      EDI     Bitmap offset
;  OUT BX      Bitmap handle
CreatePhysBitmap MACRO
    OsGate create_phys_bitmap_nr
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
;                   bit 1 = left, bit 2 = right, bit 3 = mid
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

;  IN  ES:EDI      INIT CALLBACK
HookInitPci      MACRO
    OsGate hook_init_pci_nr
                    ENDM

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

; IN  BH      Bus
; IN  BL      Device
; IN  CH      Function
; IN  ES:EDI  Device name
SetPciDeviceName       MACRO
    OsGate set_pci_device_name_nr
                    ENDM

; IN  BH      Bus
; IN  BL      Device
; IN  CH      Function
; IN  ES:ESI  Config name
; IN  FS:EDI  Array
; IN  EAX     Max entries
; OUT EAX     Entry count
GetPciDsdConfig      MACRO
        OsGate get_pci_dsd_config_nr
                        ENDM

; IN  BH      Bus
; IN  BL      Device
; IN  CH      Function
; IN  ES:EDI  Device name
PciPowerOn       MACRO
    OsGate pci_power_on_nr
                    ENDM

; IN  BH    Class
; IN  BL    Sub class
; IN  CH    Interface
; IN  AX    Device number
; OUT BH    Bus
; OUT BL    Device
FindPciClassInterface    MACRO
    OsGate find_pci_class_interface_nr
                    ENDM

; IN  BH    Class
; IN  BL    Sub class
; IN  AX    Device number
; OUT BH    Bus
; OUT BL    Device
FindPciClass MACRO
    OsGate find_pci_class_nr
                    ENDM

; IN  CX    Device ID
; IN  DX    Vendor ID
; IN  AX    Device number
; OUT BH    Bus
; OUT BL    Device
FindPciDevice   MACRO
    OsGate find_pci_device_nr
                    ENDM

; IN  AL    IRQ
; IN  FS    Core
MovePciMsi    MACRO
    OsGate move_pci_msi_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    MSI Register base
; IN  AL    Int base
; IN  DL    Allocated vectors
SetupPciMsi    MACRO
    OsGate setup_pci_msi_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    MSI Register base
; OUT ES    Int vector selector
EnablePciMsiX    MACRO
    OsGate enable_pci_msix_nr
                    ENDM

; IN  BH    Bus
; IN  BL    Device
; IN  CH    Function
; IN  CL    MSI Register base
; IN  ES    Int vector selector
; IN  AL    Int #
; IN  DL    Entry #
SetupPciMsiXEntry    MACRO
    OsGate setup_pci_msix_entry_nr
                    ENDM

; IN  AL    Int #
; OUT AL    Base int #
; OUT DX    Core
GetPciMsiInfo    MACRO
    OsGate get_pci_msi_info_nr
                    ENDM

;;;;;;;;;; ACPI ;;;;;;;;;

;   IN  EAX     Table name
;   OUT ES      Table selector
GetAcpiTable    MACRO
    OsGate get_acpi_table_nr
                    ENDM

;   IN  EAX         PCI device #
;   IN  ES:EDI      ACPI name buffer
GetAcpiPciDeviceName      MACRO
        OsGate get_acpi_pci_device_name_nr
                        ENDM

;   IN  EAX         PCI device #
;   OUT BH          Bus
;   OUT BL          Device
;   OUT CH          Function
GetAcpiPciDeviceInfo      MACRO
        OsGate get_acpi_pci_device_info_nr
                        ENDM

;   IN  EAX         PCI device #
;   IN  EDX         Pin #
;   OUT AL          IRQ #
GetAcpiPciDeviceIrq      MACRO
        OsGate get_acpi_pci_device_irq_nr
                        ENDM

;   IN  ES:EDI      Pnp name buffer
;   OUT EAX         Memory base or 0
GetAcpiPnpDeviceMem      MACRO
        OsGate get_acpi_pnp_device_mem_nr
                        ENDM

;   IN  EAX         PCI device #
;   IN  ES:ESI      Config name
;   IN  FS:EDI      Array
;   IN  ECX         Max entries
;   OUT EAX         Entry count
GetAcpiPciDsd      MACRO
        OsGate get_acpi_pci_dsd_nr
                        ENDM

;;;;;;;;;; Com port ;;;;;;;;;

; IN  AX      Controller #
; IN  DX      Device #
; IN  DS      Com device selector
; OUT AX      Com port #
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

WaitForEhci   MACRO
    OsGate wait_for_ehci_nr
                    ENDM

WaitForOhci   MACRO
    OsGate wait_for_ohci_nr
                    ENDM

WaitForUhci   MACRO
    OsGate wait_for_uhci_nr
                    ENDM

; IN  DS      Usb function selector
InitUsbFunction   MACRO
    OsGate init_usb_function_nr
                    ENDM

; IN  ES:EDI  Callback
;       BX    Controller #
;       AL    Device address
;       AH    Device port #
HookUsbAttach   MACRO
    OsGate hook_usb_attach_nr
                    ENDM

; IN  ES:EDI  Callback
;       BX    Controller #
;       AL    Device address
;       AH    Device port #
HookUsbDetach   MACRO
    OsGate hook_usb_detach_nr
                    ENDM

; IN  DS      Function sel
; IN  AX      Event
ReportUsbFunctionEvent MACRO
    OsGate report_usb_func_event_nr
                    ENDM

; IN  DS      Function sel
; IN  ES      Device sel
; IN  AX      Event
ReportUsbDeviceEvent MACRO
    OsGate report_usb_dev_event_nr
                    ENDM

; IN  DS      Function sel
; IN  ES      Device sel
; IN  GS      Pipe sel
; IN  AX      Event
ReportUsbPipeEvent MACRO
    OsGate report_usb_pipe_event_nr
                    ENDM

; IN  DS      Function sel
; IN  SI      Port
; IN  DL      Pipe #
; IN  AX      Event
ReportUsbRegPipeEvent MACRO
    OsGate report_usb_reg_pipe_event_nr
                    ENDM

; IN  BX      Device handle
; OUT ES      Device sel
GetUsbDeviceSel   MACRO
    OsGate get_usb_dev_sel_nr
                    ENDM

; IN  ES      Device sel
; OUT BX      Device handle
OpenUsbDeviceSel   MACRO
    OsGate open_usb_dev_sel_nr
                    ENDM

; IN  BX       Controller #
; IN  AL       Device port #
; IN  CX       Buffer size
; IN  ES:EDI   Buffer
; OUT AX       Size of descriptor
GetUsbHubDescriptor MACRO
    OsGate get_usb_hub_descriptor_nr
                    ENDM

; IN  BX       Controller #
; IN  AL       Device address (1..128)
; IN  CX       Hub sel
; IN  DL       Config #
ConfigUsbHub MACRO
    OsGate config_usb_hub_nr
                    ENDM

; IN  DS      Function sel
; IN  ES      Device sel
; OUT AL      Address
AllocateUsbAddress MACRO
    OsGate allocate_usb_address_nr
                    ENDM

; IN  DS      Function sel
; IN  AL      Address
FreeUsbAddress MACRO
    OsGate free_usb_address_nr
                    ENDM

; IN  DS      Function sel
; IN  BX      Hub selector
; IN  DL      Port #
; IN  AX      Port state
NotifyUsbPortState MACRO
    OsGate notify_usb_port_state_nr
                    ENDM

; IN  DS      Usb function selector
; IN  AL      Address
AddressUsbDev   MACRO
    OsGate address_usb_dev_nr
                    ENDM

; IN  BX      Device handle
; IN  DL      Pipe #
; IN  AX      Timeout in ms
; IN  CX      Buffer size
; OUT ES      Buffer sel
OpenUsbRawPipe      MACRO
    OsGate open_usb_raw_pipe_nr
                                                ENDM

; IN  BX      Device handle
; IN  DL      Pipe #
; IN  CX      Buffer size
PostUsbRawPipe      MACRO
    OsGate post_usb_raw_pipe_nr
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

; IN    AX Sample rateo
; IN    CX Number of samples in buffers
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

;;;;;;;;;; Hid ;;;;;;;;;

; IN    ES:EDI        Check procedure
;           FS:ESI    Hid device
RegisterCustomHid      MACRO
    OsGate register_custom_hid_nr
                        ENDM

; IN    ES:EDI  Hid table
RegisterHidInput      MACRO
    OsGate register_hid_input_nr
                        ENDM

; IN    ES:EDI  Hid report
; IN    EBX     Entry #
; OUT   EAX     Value
GetHidLogMin      MACRO
    OsGate get_hid_log_min_nr
                        ENDM

; IN    ES:EDI  Hid report
; IN    EBX     Entry #
; OUT   EAX     Value
GetHidLogMax      MACRO
    OsGate get_hid_log_max_nr
                        ENDM

; IN    ES:EDI  Hid report
; IN    FS:ESI  Report data
; IN    EBX     Entry #
; OUT   EAX     Value
GetSignedHidInput      MACRO
    OsGate get_signed_hid_input_nr
                        ENDM

; IN    ES:EDI  Hid report
; IN    FS:ESI  Report data
; IN    EBX     Entry #
; OUT   EAX     Value
GetUnsignedHidInput      MACRO
    OsGate get_unsigned_hid_input_nr
                        ENDM

; IN    ES:EDI  Hid report
; IN    EAX     Value
SetHidIdle      MACRO
    OsGate set_hid_idle_nr
                        ENDM

; IN    BX      Device
ResetHid      MACRO
    OsGate reset_hid_nr
                        ENDM

; IN    BX      Device
; IN    CX      Usage page
; IN    DL      Usage ID
; OUT   NC      Found
; OUT   DX:ESI  Report
FindHidOutputReport      MACRO
    OsGate find_hid_output_report_nr
                        ENDM

; IN    FS:ESI  Report
; IN    CX      Usage page
; IN    DL      Usage ID
; IN    EAX     Value
SetHidOutput      MACRO
    OsGate set_hid_output_nr
                        ENDM

; IN    FS:ESI  Report
UpdateHidOutput      MACRO
    OsGate update_hid_output_nr
                        ENDM

; IN    BX      Device
; IN    CX      Usage page
; IN    DL      Usage ID
; OUT   NC      Found
; OUT   DX:ESI  Report
FindHidFeatureReport      MACRO
    OsGate find_hid_feature_report_nr
                        ENDM

; IN    FS:ESI  Report
; OUT   ECX     Size
GetHidReportSize      MACRO
    OsGate get_hid_report_size_nr
                        ENDM

; IN    FS:ESI  Report
; OUT   DX:EAX  Buffer
GetHidReportBuf      MACRO
    OsGate get_hid_report_buf_nr
                        ENDM

; IN    FS:ESI  Report
ReadHidFeature      MACRO
    OsGate read_hid_feature_nr
                        ENDM

; IN    FS:ESI  Report
WriteHidFeature      MACRO
    OsGate write_hid_feature_nr
                        ENDM

;;;;;;;;;; Printer ;;;;;;;;;

;   AX      Controller #
;   DX      Device #
;   DS      Printer device selector
AddPrinter      MACRO
    OsGate add_printer_nr
                    ENDM

;;;;;;;;;; Lon works ;;;;;;;;;

;   DS      Lon device selector
AddLonModule      MACRO
    OsGate add_lon_module_nr
                    ENDM

;;;;;;;;;; Card device ;;;;;;;;;

;   AX      Controller #
;   DX      Device #
;   DS      Card device selector
AddCardDev      MACRO
    OsGate add_carddev_nr
                    ENDM

;;;;;;;;;; IR ;;;;;;;;;

; IN  ES:DI     Data buffer
; IN  CX        Size
NotifyIrData      MACRO
    OsGate notify_ir_data_nr
                        ENDM


;;;;;;;;;; CAN bus ;;;;;;;;;

NotifyCanOffline      MACRO
    OsGate notify_can_offline_nr
                        ENDM

NotifyCanOnline      MACRO
    OsGate notify_can_online_nr
                        ENDM

NotifyCanModulesUp      MACRO
    OsGate notify_can_modules_up_nr
                        ENDM

ResetCanBuffers      MACRO
    OsGate reset_can_buffers_nr
                        ENDM

RestartCanModules      MACRO
    OsGate restart_can_modules_nr
                        ENDM

ResetCanModules      MACRO
    OsGate reset_can_modules_nr
                        ENDM

; OUT  NC       Has buffer
HasCanSendBuf      MACRO
    OsGate has_can_send_buf_nr
                        ENDM

; IN  EDX:EAX   Data
; IN  CL        Size (0..8)
; IN  EBX       Identifier
SendCanBusMsg      MACRO
    OsGate send_can_bus_msg_nr
                        ENDM

; IN  EDX:EAX   Data
; IN  CL        Size (0..8)
; IN  EBX       Identifier
SendCanBusBlock      MACRO
    OsGate send_can_bus_block_nr
                        ENDM

; IN  ES:EDI    Hook callback
;     IN  EDX:EAX   Data
;     IN  CL        Size (0..8)
;     IN  EBX       Identifier
;     OUT NC        Handled
HookCanGenericBusMsg      MACRO
    OsGate hook_can_gen_bus_msg_nr
                        ENDM

; IN  EAX       Identifier 
; IN  EDX       Identifier mask
; IN  DS        Param
; IN  ES:EDI    Hook callback
;     IN  DS        Param
;     IN  EDX:EAX   Data
;     IN  CL        Size (0..8)
;     IN  EBX       Identifier
; OUT BX        Buffer #
CreateCanIdHook      MACRO
    OsGate create_can_id_hook_nr
                        ENDM

; IN  BX        Buffer #
DeleteCanIdHook      MACRO
    OsGate delete_can_id_hook_nr
                        ENDM


;;;;;;;;;; LON ;;;;;;;;;

; IN ES  Lon data
NotifyLonData      MACRO
    OsGate notify_lon_data_nr
                        ENDM
