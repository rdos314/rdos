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
; USER.INC
; User gate macros

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FILE_ATTRIB_READONLY = 1
FILE_ATTRIB_HIDDEN = 2
FILE_ATTRIB_SYSTEM = 4
FILE_ATTRIB_LABEL = 8
FILE_ATTRIB_DIR = 10h
FILE_ATTRIB_ARC = 20h

LGOP_NULL = 0
LGOP_NONE = 1
LGOP_OR = 2
LGOP_AND = 3
LGOP_XOR = 4
LGOP_INVERT = 5   
LGOP_INVERT_OR = 6
LGOP_INVERT_AND = 7
LGOP_INVERT_XOR = 8
LGOP_ADD = 9
LGOP_SUBTRACT = 10
LGOP_MULTIPLY = 11
LGOP_STIPPLE = 12
LGOP_ALPHA = 13

;
; iomode constants
;

IO_READ         = 1
IO_WRITE        = 2
IO_EOF          = 10h
IO_APPEND       = 80h
IO_FBF          = 100h
IO_LBF          = 200h
IO_NBF          = 400h
IO_ISTTY        = 1000h

;
; open constants
;

O_RDONLY        = 0
O_WRONLY        = 1
O_RDWR          = 2
O_APPEND        = 10h
O_CREAT         = 20h
O_TRUNC         = 40h
O_NOINHERIT     = 80h
O_EXCL          = 400h

;
; Segment transfer flags bits
;

virt_ds_in              EQU 1
virt_es_in              EQU 2
virt_fs_in              EQU 4
virt_gs_in              EQU 8
;
virt_ds_out             EQU 10h
virt_es_out             EQU 20h
virt_fs_out             EQU 40h
virt_gs_out             EQU 80h
;
virt_seg_in             EQU 0Fh
virt_seg_out    EQU 0F0h

; interface data-type

user_tss_struc  STRUC

ut_cr3              DD ?
ut_eip              DD ?
ut_eflags           DD ?
ut_eax              DD ?
ut_ecx              DD ?
ut_edx              DD ?
ut_ebx              DD ?
ut_esp              DD ?
ut_ebp              DD ?
ut_esi              DD ?
ut_edi              DD ?
ut_es               DW ?
ut_cs               DW ?
ut_ss               DW ?
ut_ds               DW ?
ut_fs               DW ?
ut_gs               DW ?
ut_ldt              DW ?
ut_dr0              DD ?
ut_dr1              DD ?
ut_dr2              DD ?
ut_dr3              DD ?
ut_dr7              DD ?
ut_math_control     DD ?
ut_math_status      DD ?
ut_math_tag         DD ?
ut_math_eip                 DD ?
ut_math_cs              DW ?
ut_math_data_offs       DD ?
ut_math_data_sel        DW ?
ut_st0              DT ?
ut_st1              DT ?
ut_st2              DT ?
ut_st3              DT ?
ut_st4              DT ?
ut_st5              DT ?
ut_st6              DT ?
ut_st7              DT ?

user_tss_struc  ENDS


UserGate16      MACRO gate_nr
    db 67h
    db 66h
    db 9Ah
    dd gate_nr
    dw 1
                        ENDM

UserGate32      MACRO gate_nr
    db 3Eh
    db 67h
    db 9Ah
    dd gate_nr
    dw 3
                        ENDM

UserGate64    MACRO gate_nr
    push r15
    mov r15,usergate_linear + gate_nr SHL 5
    call fword ptr [r15]
    pop r15
            ENDM

UserGateForce32 MACRO gate_nr
    db 67h
    db 66h
    db 9Ah
    dd gate_nr
    dw 3
                        ENDM

UserGateApp     MACRO gate_nr
    db 55h
    db 67h
    db 9Ah
    dd gate_nr
    dw 3
    db 5Dh
                        ENDM

UserGate        MACRO gate_nr
IF (size $) EQ 0FF02h
    UserGate16 gate_nr
ELSE
  IFDEF rax
    UserGate64 gate_nr  
  ELSE
    UserGate32 gate_nr
  ENDIF
ENDIF
                        ENDM
                        

;   NC      Valid
IsValidUserGate MACRO
        UserGate is_valid_UserGate_nr
                                ENDM

;;;;;;;;;;;;;; MEMORY ;;;;;;;;;;;;;;;;;;;

; IN  BX                Entry #
; OUT EAX       Type
GetPhysicalEntryType    MACRO
        UserGate get_physical_entry_type_nr
                                ENDM

; IN  BX                Entry #
; OUT EBX:EAX   Base
GetPhysicalEntryBase    MACRO
        UserGate get_physical_entry_base_nr
                                ENDM

; IN  BX                Entry #
; OUT EBX:EAX   Size
GetPhysicalEntrySize    MACRO
        UserGate get_physical_entry_size_nr
                                ENDM

; NC                Has 64 bit addresses
HasPhysical64    MACRO
    UserGate has_physical64_nr
                    ENDM

; NC                Has 64 bit addresses
UsesPae    MACRO
    UserGate uses_pae_nr
                    ENDM

;       EAX             Number of free physical bytes
GetFreePhysical MACRO
        UserGate get_free_physical_nr
                                ENDM

;       AX              Number of free GDT entries
GetFreeGdt      MACRO
        UserGate get_free_gdt_nr
                                ENDM

;       AX              Number of free LDT entries
GetFreeLdt      MACRO
        UserGate get_free_ldt_nr
                                ENDM

;       EAX         Number of free bytes
AvailableBigLinear      MACRO
        UserGate available_big_linear_nr
                                        ENDM

;       EAX             Number of free bytes
AvailableSmallLinear    MACRO
        UserGate available_small_linear_nr
                                        ENDM

; IN  EAX     Number of bytes
; OUT ES      Selector
AllocateDosMem  MACRO
        UserGate allocate_dos_mem_nr
                                                ENDM

; IN  EAX     Number of bytes
; OUT ES      Selector
AllocateLocalMem        MACRO
        UserGate allocate_local_mem_nr
                                                ENDM

; IN  ES      Selector
FreeMem MACRO
        UserGate free_mem_nr
                                                ENDM

; OUT EAX     Number of bytes
AvailableSmallLocalLinear    MACRO
        UserGate available_small_local_linear_nr
                                                ENDM

; OUT EAX     Number of bytes
AvailableBigLocalLinear    MACRO
        UserGate available_big_local_linear_nr
                                                ENDM

; OUT EAX     Number of bytes
UsedLocalLinear MACRO
        UserGate used_local_linear_nr
                                                ENDM

; OUT EAX     Number of bytes
AvailableVMLinear       MACRO
        UserGate available_vm_linear_nr
                                                ENDM

; OUT EAX     Number of bytes
UsedVMLinear    MACRO
        UserGate used_vm_linear_nr
                                                ENDM

; OUT AX      Number of free handles
GetFreeHandles MACRO
        UserGate get_free_handles_nr
                                                ENDM

; OUT EAX     Amount of free handle memory
GetFreeHandleMem MACRO
        UserGate get_free_handle_mem_nr
                                                ENDM

;;;;;;;;;;; PAGING ;;;;;;;;;;;;;;

FreeV86 MACRO
        UserGate free_v86_nr
                                        ENDM

; IN  EAX       Size
; IN  BX                Owner
; IN  EDX       Flat offset
ReservePeMem MACRO
        UserGate reserve_pe_mem_nr
                                                ENDM

; IN  EAX               New size
; IN  ECX               Old size
; IN  EDX               Flat offset
; OUT EDX               Flat offset
ResizeFlatLinear        MACRO
        UserGate resize_flat_linear_nr
                                        ENDM

; IN  EAX               Number of bytes
; IN  EDX               Flat offset
SetFlatLinearValid      MACRO
        UserGate set_flat_linear_valid_nr
                                        ENDM

; IN  EAX               Number of bytes
; IN  EDX               Flat offset
SetFlatLinearInvalid    MACRO
        UserGate set_flat_linear_invalid_nr
                                        ENDM

; IN  EAX               Number of bytes
; IN  EDX               Flat offset
SetFlatLinearRead       MACRO
        UserGate set_flat_linear_read_nr
                                        ENDM

; IN  EAX               Number of bytes
;       EDX                     Flat offset
SetFlatLinearReadWrite  MACRO
        UserGate set_flat_linear_readwrite_nr
                                        ENDM

; IN  EAX               Number of bytes
; OUT EDX               Flat offset
AllocateCircularBuffer  MACRO
        UserGate allocate_circ_buf_nr
                                        ENDM

; IN  ECX               Size of buffer
; IN  EDX               Flat offset
FreeCircularBuffer  MACRO
        UserGate free_circ_buf_nr
                                        ENDM

;;;;;;;;;;;; INTERRUPT & EXCEPTION ;;;;;;;;;;;

; OUT BX:CX             V86 address to use to switch to Prot mode
; OUT SI:(E)DI  Prot mode address to use to switch to V86.
GetRawSwitchAds MACRO
        UserGate get_raw_switch_ads_nr
                                        ENDM

; IN  AX                New DS
; IN  CX                New ES
; IN  DX                New SS
; IN  (E)BX             New (E)SP
; IN  SI                New CS
; IN  (E)DI             New (E)IP
RawSwitchPm       MACRO
        UserGate raw_switch_pm_nr
                                                ENDM

; IN  AX                New DS
; IN  CX                New ES
; IN  DX                New SS
; IN  (E)BX             New (E)SP
; IN  SI                New CS
; IN  (E)DI             New (E)IP
RawSwitchVm       MACRO
        UserGate raw_switch_vm_nr
                                                ENDM

; IN  AL        Exception #
; OUT ES:(E)DI  Exception vector
GetException      MACRO
        UserGate get_exception_nr
                                                ENDM

; IN  AL        Exception #
; IN  ES:(E)DI  Exception vector
SetException      MACRO
        UserGate set_exception_nr
                                                ENDM

; IN  AL        Int #
; OUT ES:(E)DI  Int vector
GetPMInt    MACRO
        UserGate get_pm_int_nr
                                                ENDM

; IN  AL        Int #
; IN  ES:(E)DI  Int vector
SetPMInt    MACRO
        UserGate set_pm_int_nr
                                                ENDM

; IN  AL                Int #
; OUT DX:BX             Int vector
GetVMInt        MACRO
        UserGate get_vm_int_nr
                                        ENDM

; IN  AL                Int #
; IN  DX:BX             Int vector
SetVMInt        MACRO
        UserGate set_vm_int_nr
                                        ENDM

; IN  AL         Int #
; IN  CX         Words to copy on stack
; IN  DS:(E)SI   Parameters
; IN  ES:(E)DI   VM_CALL_STRUC
DpmiInt   MACRO
        UserGate dpmi_int_nr
                                        ENDM

; IN  CX         Words to copy on stack
; IN  DS:(E)SI   Parameters
; IN  ES:(E)DI   VM_CALL_STRUC
DpmiCallInt       MACRO
        UserGate dpmi_call_int_nr
                                        ENDM

; IN  CX          Words to copy on stack
; IN  DS:(E)SI    Parameters
; IN  ES:(E)DI    VM_CALL_STRUC
DpmiCall  MACRO
        UserGate dpmi_call_nr
                                        ENDM

; IN  DS:(E)SI    Callback procedure
; IN  ES:(E)DI    VM_CALL_STRUC
; OUT DX:AX       V86 address to call
AllocateVMCallback      MACRO
        UserGate allocate_vm_callback_nr
                                        ENDM

; IN  DX:AX       V86 address to call
FreeVMCallback  MACRO
        UserGate free_vm_callback_nr
                                        ENDM

;;;;;;;;;;;;;; MULTITASKING ;;;;;;;;;;;;

;  OUT AX       0 = power ok
;               1 = power failure
PowerFailure        MACRO
        UserGate power_failure_nr
                                                ENDM

;  OUT CY       Not emergency stopped
;      NC       Emergency stopped
IsEmergencyStopped        MACRO
        UserGate is_emergency_stopped_nr
                                                ENDM


SoftReset        MACRO
        UserGate soft_reset_nr
                                                ENDM

HardReset        MACRO
        UserGate hard_reset_nr
                                                ENDM

HasHardReset        MACRO
        UserGate has_hard_reset_nr
                                                ENDM

HasPowerCard        MACRO
        UserGate has_power_card_nr
                                                ENDM

; OUT AX        Active cores
GetActiveCores        MACRO
        UserGate get_active_cores_nr
                                                ENDM

; IN  AX        Core nr
; OUT EDX:EAX   Core tics
; OUT ECX:EBX   Null tics
GetCoreLoad        MACRO
        UserGate get_core_load_nr
                                                ENDM

; IN  AX        Core nr
; OUT EDX:EAX   Core tics
; OUT ECX:EBX   Total tics
GetCoreDuty        MACRO
        UserGate get_core_duty_nr
                                                ENDM

; OUT AX         Core nr
GetCoreId        MACRO
        UserGate get_core_id_nr
                                                ENDM

; IN AX          Core nr
MoveToCore        MACRO
        UserGate move_to_core_nr
                                                ENDM

; IN AX          Core nr
; IN BX          Thread #
MoveThreadToCore        MACRO
        UserGate move_thread_to_core_nr
                                                ENDM

MoveToNewCore        MACRO
        UserGate move_to_new_core_nr
                                                ENDM

; IN  AX         Number of milliseconds
WaitMilliSec        MACRO
        UserGate wait_milli_nr
                                                ENDM

; IN  AX         Number of microseconds
WaitMicroSec        MACRO
        UserGate wait_micro_nr
                                                ENDM

; IN  EDX:EAX    System time to wait until
WaitUntil       MACRO
        UserGate wait_until_nr
                                                ENDM

; IN  AL         Priority
; IN  AH         Mode, 0=PM, 1=VM
; IN  (E)CX      Stack size
; IN  DS:(E)SI   Start address
; IN  ES:(E)DI   Thread name
CreateThread   MACRO
        UserGate create_thread_nr
                                                ENDM

; IN  AL         Priority
; IN  RCX        Stack size
; IN  RDX        Param
; IN  RSI        Start address
; IN  ES:EDI     Thread name
CreateLongThread   MACRO
        UserGate create_long_thread_nr
                                                ENDM

TerminateThread        MACRO
        UserGate terminate_thread_nr
                                                ENDM

; OUT AX                Thread selector
GetThread       MACRO
        UserGate get_thread_nr
                                        ENDM

; OUT AX                Thread ID
GetThreadHandle MACRO
        UserGate get_thread_handle_nr
                                        ENDM

; OUT AX                Process ID
GetProcessHandle MACRO
        UserGate get_process_handle_nr
                                        ENDM


;   NC      Global timer
HasGlobalTimer       MACRO
        UserGate has_global_timer_nr
                                                ENDM


; IN  EBX         TLS sel passed to thread
; IN  EDX         Passed to thread
; IN  ES:EDI      Startup of thread
; OUT NC          Thread started
;     CY          Thread already running
CreateTimerThread       MACRO
        UserGate create_timer_thread_nr
                                                ENDM

; OUT NC          Has event
;     CY          Terminate thread
WaitUserTimerEvent       MACRO
        UserGate wait_timer_event_nr
                                                ENDM

; IN  EBX       Handle
; IN  EDX:EAX   Timeout
; IN  ES:EDI    Callback
; IN  DS:ESI    Param
StartUserTimer       MACRO
        UserGate start_user_timer_nr
                                                ENDM

; IN  EBX       Handle
; IN  EAX       Timeout in milliseconds
; IN  ES:EDI    Callback
; IN  DS:ESI    Param
StartUserTimeout       MACRO
        UserGate start_user_timeout_nr
                                                ENDM

; IN  EBX       Handle
; IN  EDX:EAX   Timeout
; OUT NC        Success
UpdateUserTimer       MACRO
        UserGate update_user_timer_nr
                                                ENDM

; IN  EBX       Handle
StopUserTimer       MACRO
        UserGate stop_user_timer_nr
                                                ENDM

;;;;;;;;; CRITICAL SECTIONS ;;;;;;;;;;;;


; IN  ES:(E)BX          Futex structure
AcquireFutex    MACRO
        UserGate acquire_futex_nr
                                        ENDM

; IN  ES:(E)BX          Futex structure
; IN  ES:(E)DI      Futex name
AcquireNamedFutex       MACRO
        UserGate acquire_named_futex_nr
                                        ENDM

; IN  ES:(E)BX          Futex structure
ReleaseFutex    MACRO
        UserGate release_futex_nr
                                        ENDM

; IN  ES:(E)BX          Futex structure
CleanupFutex    MACRO
        UserGate cleanup_futex_nr
                                        ENDM


; OUT EAX               Used sections
UsedUserSections       MACRO
        UserGate used_user_sections_nr
                                        ENDM

; OUT BX                Section handle
CreateUserSection       MACRO
        UserGate create_user_section_nr
                                        ENDM

; IN  ES:(E)DI  Section name
; OUT BX                Section handle
CreateNamedUserSection  MACRO
        UserGate create_named_user_section_nr
                                        ENDM

; OUT BX                Section handle
CreateBlockedUserSection        MACRO
        UserGate create_blocked_user_section_nr
                                        ENDM

; IN  BX                Section handle
DeleteUserSection       MACRO
        UserGate delete_user_section_nr
                                        ENDM

; IN  BX                Section handle
EnterUserSection        MACRO
        UserGate enter_user_section_nr
                                        ENDM

; IN  BX                Section handle
LeaveUserSection        MACRO
        UserGate leave_user_section_nr
                                        ENDM

; OUT BX                Section handle
CreateUserReadWriteSection      MACRO
        UserGate create_user_read_write_section_nr
                                        ENDM

; IN  BX                Section handle
DeleteUserReadWriteSection      MACRO
        UserGate delete_user_read_write_section_nr
                                        ENDM

; IN  BX                Section handle
EnterUserReadSection    MACRO
        UserGate enter_user_read_section_nr
                                        ENDM

; IN  BX                Section handle
LeaveUserReadSection    MACRO
        UserGate leave_user_read_section_nr
                                        ENDM

; IN  BX                Section handle
EnterUserWriteSection   MACRO
        UserGate enter_user_write_section_nr
                                        ENDM

; IN  BX                Section handle
LeaveUserWriteSection   MACRO
        UserGate leave_user_write_section_nr
                                        ENDM

; OUT BX                Section handle
CreateSectionHandle     MACRO
        UserGate create_section_handle_nr
                                        ENDM

;;;;;;;;; WAITABLE OBJECTS ;;;;;;;;;;;;

; OUT BX                Wait handle
CreateWait      MACRO
        UserGate create_wait_nr
                                        ENDM

; IN  BX                Wait handle
; OUT ECX               Non-idle ID
IsWaitIdle      MACRO
        UserGate is_wait_idle_nr
                                        ENDM

; IN  BX                Wait handle
; OUT ECX               Signalled ID
WaitWithoutTimeout      MACRO
        UserGate wait_no_timeout_nr
                                        ENDM

; IN  BX                Wait handle
; IN  EDX:EAX   Timeout
; OUT ECX               Signalled ID
WaitWithTimeout MACRO
        UserGate wait_timeout_nr
                                        ENDM

; IN  BX                Wait handle
StopWait        MACRO
        UserGate stop_wait_nr
                                        ENDM

; IN  BX                Wait handle
; IN  ECX       Object ID
RemoveWait      MACRO
        UserGate remove_wait_nr
                                        ENDM

; IN  BX                Wait handle
CloseWait       MACRO
        UserGate close_wait_nr
                                        ENDM

; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForKeyboard       MACRO
        UserGate add_wait_for_keyboard_nr
                                                ENDM

; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForMouse       MACRO
        UserGate add_wait_for_mouse_nr
                                                ENDM

; IN  AX        Com handle
; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForCom       MACRO
        UserGate add_wait_for_com_nr
                                                ENDM

; IN  AX        Tcp connection handle
; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForTcpConnection       MACRO
        UserGate add_wait_for_tcp_connection_nr
                                                ENDM

; IN  AX        Udp connection handle
; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForUdpConnection       MACRO
        UserGate add_wait_for_udp_connection_nr
                                                ENDM

; IN  AX        Tcp listen handle
; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForTcpListen       MACRO
        UserGate add_wait_for_tcp_listen_nr
                                                ENDM

; IN  AX        Secure listen handle
; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForSecureListen       MACRO
        UserGate add_wait_for_secure_listen_nr
                                                ENDM

; IN  AX        Udp listen handle
; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForUdpListen       MACRO
        UserGate add_wait_for_udp_listen_nr
                                                ENDM

; IN  AX        Secure connection handle
; IN  BX        Wait handle
; IN  ECX       Object ID
AddWaitForSecureConnection       MACRO
        UserGate add_wait_for_secure_connection_nr
                                                ENDM

; IN  AX        USB dev handle
; IN  BX        Wait handle
; IN  DL        Pipe #
; IN  ECX       Object ID
AddWaitForUsbDevicePipe       MACRO
        UserGate add_wait_for_usb_dev_pipe_nr
                                                ENDM

; OUT BX        Signal handle
CreateSignal       MACRO
        UserGate create_signal_nr
                                                ENDM

; IN  BX        Signal handle
SetSignal       MACRO
        UserGate set_signal_nr
                                                ENDM
                                                
; IN  BX        Signal handle
ResetSignal       MACRO
        UserGate reset_signal_nr
                                                ENDM
                                                
; IN  BX        Signal handle
IsSignalled       MACRO
        UserGate is_signalled_nr
                                                ENDM

; IN  BX        Signal handle
FreeSignal       MACRO
        UserGate free_signal_nr
                                                ENDM

; IN  AX        Signal handle
; IN  BX                Wait handle
; IN  ECX       Object ID
AddWaitForSignal       MACRO
        UserGate add_wait_for_signal_nr
                                                ENDM


;;;;;;;;; Thread blocks ;;;;;;;;;;;;

; IN  ES:(E)DI    Block name
; OUT BX          Handle
CreateThreadBlock       MACRO
        UserGate create_thread_block_nr
                                                ENDM

; IN  BX          Handle
WaitThreadBlock       MACRO
        UserGate wait_thread_block_nr
                                                ENDM

; IN  BX          Handle
CloseThreadBlock       MACRO
        UserGate close_thread_block_nr
                                                ENDM

;;;;;;;;;;; RANDOM NUMBERS ;;;;


;   OUT EAX         Random number
GetRandom   MACRO
    UserGate get_random_nr
            ENDM

;   IN  ES:(E)DI      Buffer
GetMacAddress   MACRO
    UserGate get_mac_address_nr
            ENDM

;   IN  ES:(E)DI      Buffer
CreateUuid   MACRO
    UserGate create_uuid_nr
            ENDM



;;;;;;;;;;; IPC ;;;;;;;;;;;;;;;

;       IN  ES:(E)DI    Mailslot name
;       OUT BX                  Mailslot handle
GetLocalMailslot                MACRO
        UserGate get_local_mailslot_nr
                        ENDM

;       IN  EDX                 IP address
;       IN  ES:(E)DI    Mailslot name
;       OUT BX                  Mailslot handle
GetRemoteMailslot               MACRO
        UserGate get_remote_mailslot_nr
                        ENDM

;       IN  BX                  Mailslot handle
FreeMailslot            MACRO
        UserGate free_mailslot_nr
                        ENDM

;       IN  BX                          Mailslot handle
;       IN  DS:(E)SI            Message buffer
;       IN  (E)CX                       Message size
;       IN  ES:(E)DI            Reply buffer
;       IN  (E)AX                       Max reply size
;       IN  EDX                         Timeout in milliseconds
;       OUT (E)CX                       Reply size
SendMailslot            MACRO
        UserGate send_mailslot_nr
                        ENDM

;       IN  (E)CX                       Max message size
;       IN  ES:(E)DI            Mailslot name
DefineMailslot          MACRO
        UserGate define_mailslot_nr
                        ENDM

;       IN  ES:(E)DI            Message buffer
;       OUT (E)CX                       Size
ReceiveMailslot         MACRO
        UserGate receive_mailslot_nr
                        ENDM

;       IN  ES:(E)DI            Reply buffer
;       IN  (E)CX                       Reply size
ReplyMailslot           MACRO
        UserGate reply_mailslot_nr
                        ENDM

;;;;;;;;;;;; PROGRAMS & DLLS ;;;;;;;;;;;;;;;;

; IN  AL            Adapter # (0..n)
; IN  DL            Entry # (0..n)
; IN  ES:(E)DI      Header buffer
GetImageHeader  MACRO
        UserGate get_image_header_nr
                                        ENDM

; IN  AL            Adapter # (0..n)
; IN  DL            Entry # (0..n)
; IN  ES:(E)DI      Data buffer
GetImageData    MACRO
        UserGate get_image_data_nr
                                        ENDM

; IN  BX            Code selector
; IN  ES:(E)DI      Name buffer
; OUT BX            Data selector
; OUT EAX           Code limit
; OUT EDX           Data limit
GetDeviceInfo   MACRO
        UserGate get_device_info_nr
                                        ENDM

; IN  ES:(E)DI)     CPU vendor string
; OUT AL            CPU version
; OUT EBX           Frequency (MHz)
; OUT EDX           Feature flags
GetCpuVersion   MACRO
        UserGate get_cpu_version_nr
                                        ENDM

; OUT AX Minor version
; OUT DX Major version
; OUT CX Release #
GetVersion      MACRO
        UserGate get_version_nr
                                        ENDM

EmsHandler      MACRO
        UserGate ems_handler_nr
                                        ENDM

XmsHandler      MACRO
        UserGate xms_handler_nr
                                        ENDM

; IN  DS:(E)SI  Program name
Is64BitExe      MACRO
        UserGate is_64_bit_exe_nr
                                        ENDM

; IN  DS:(E)SI  Program name
; IN  ES:(E)DI  Parameters
;               +0  Command line
;               +8  Startup directory & drive
;               +12 Environment
LoadExe MACRO
        UserGate load_exe_nr
                                        ENDM

; IN  DS:(E)SI  Program name
; IN  ES:(E)DI  Parameters
;               +0  Command line
;               +8  Startup directory & drive
;               +12 Environment
; IN  DX                Debug module ID
; OUT AX                Thread ID
; OUT DX                Program ID
SpawnExe        MACRO
        UserGate spawn_exe_nr
                                        ENDM


; IN  BX        Debugged process ID
; IN  DX        Debugger process ID
; OUT AX        Thread ID
AttachDebugger        MACRO
        UserGate attach_debugger_nr
                                        ENDM

; OUT AX                Child thread id (parent) or 0 (child)
Fork    MACRO
        UserGate fork_nr
                                        ENDM

; IN  AX                Exit code
UnloadExe       MACRO
        UserGate unload_exe_nr
                                        ENDM

FatalErrorExit  MACRO
        UserGate fatal_error_exit_nr
                                        ENDM

;  IN  AX   Process handle
;  IN  BX       Wait handle
;  IN  ECX  Signalled ID
AddWaitForProcEnd MACRO
        UserGate add_wait_for_proc_end_nr
                                                ENDM

;  IN  BX   Process handle
;  OUT AX       Exit code
GetProcExitCode MACRO
        UserGate get_proc_exit_code_nr
                                        ENDM

; IN  EAX               0 = don't show text
ShowExceptionText       MACRO
        UserGate show_exception_text_nr
                                        ENDM

; OUT AX                Exit code
GetExitCode     MACRO
        UserGate get_exit_code_nr
                                        ENDM

; OUT ES:(E)DI  Program name
GetExeName      MACRO
        UserGate get_exe_name_nr
                                        ENDM

; OUT ES:(E)DI  Command line
GetCmdLine      MACRO
        UserGate get_cmd_line_nr
                                        ENDM


; OUT ES:(E)DI  Environment
GetEnvironment  MACRO
        UserGate get_env_nr
                                        ENDM

; IN  ES:(E)DI  DLL name
; OUT BX                Module handle
LoadDll MACRO
        UserGate load_dll_nr
                                        ENDM

; IN  BX                Module handle
FreeDll MACRO
        UserGate free_dll_nr
                                        ENDM

; IN  BX                Module handle
; OUT AL        Focus key
GetModuleFocusKey       MACRO
        UserGate get_module_focus_key_nr
                                        ENDM

; OUT BX                Module handle
GetCurrentDll   MACRO
        UserGate get_current_dll_nr
                                        ENDM

; IN  EBX                Module handle
; OUT EBX        Duplicated file handle
DuplModuleFileHandle    MACRO
        UserGate dupl_module_file_handle_nr
                                        ENDM

; IN  ES:(E)DI  Module name
; OUT BX                Module handle
GetModule       MACRO
        UserGate get_module_nr
                                        ENDM

; IN  BX                Module handle
; IN  ES:(E)DI  Proc name
; OUT DS:(E)SI  Proc address
GetModuleProc   MACRO
        UserGate get_module_proc_nr
                                        ENDM

; IN  BX                Module handle
; IN  (E)AX             Resource handle
; IN  (E)DX             Resource type
; OUT DS:(E)SI  Resource address
; OUT ECX       Resource size
GetModuleResource       MACRO
        UserGate get_module_resource_nr
                                        ENDM

; IN  BX                Module handle
; IN  (E)CX             Max name size
; IN  ES:(E)DI  Name buffer
; OUT (E)AX             Bytes copied
GetModuleName   MACRO
        UserGate get_module_name_nr
                                        ENDM

; IN  EAX               Number of bytes
; OUT ES / (E)DX    Selector or linear base address (depends on loader)
AllocateAppMem     MACRO
        UserGate allocate_app_mem_nr
                                                ENDM

; IN  ES / (E)DX    Selector or linear base address (depends on loader)
FreeAppMem     MACRO
        UserGate free_app_mem_nr
                                                ENDM

; IN  EAX               Number of bytes
; OUT ES / (E)DX    Selector or linear base address (depends on loader)
AllocateDebugAppMem     MACRO
        UserGate allocate_debug_app_mem_nr
                                                ENDM

; IN  ES / (E)DX    Selector or linear base address (depends on loader)
FreeDebugAppMem     MACRO
        UserGate free_debug_app_mem_nr
                                                ENDM

; OUT BX                        PSP Selector
GetPspSel       MACRO
        UserGate get_psp_sel_nr
                                        ENDM

; OUT BX            Env handle
OpenSysEnv      MACRO
        UserGate open_sys_env_nr
                ENDM

; OUT BX            Env handle
OpenProcEnv     MACRO
        UserGate open_proc_env_nr
                ENDM

; IN  BX            Env handle
CloseEnv        MACRO
        UserGate close_env_nr
                ENDM

; IN  BX            Env handle
; IN  DS:(E)SI      Env var name
; IN  ES:(E)DI      Env var data
AddEnvVar       MACRO
        UserGate add_env_var_nr
                ENDM

; IN  BX            Env handle
; IN  DS:(E)SI      Env var name
DeleteEnvVar    MACRO
        UserGate delete_env_var_nr
                ENDM

; IN  BX            Env handle
; IN  DS:(E)SI      Env var name
; IN  ES:(E)DI      Env var data
FindEnvVar      MACRO
        UserGate find_env_var_nr
                ENDM

; IN  BX            Env handle
; OUT (E)AX         Required size of data buffer
GetEnvSize      MACRO
        UserGate get_env_size_nr
                ENDM

; IN  BX            Env handle
; IN  ES:(E)DI      Env data buffer
GetEnvData      MACRO
        UserGate get_env_data_nr
                ENDM

; IN  BX            Env handle
; IN  ES:(E)DI      Env data buffer
SetEnvData      MACRO
        UserGate set_env_data_nr
                ENDM

; OUT  AX           Program count
GetProgramCount MACRO
        UserGate get_program_count_nr
                ENDM

; IN   AX           Program #
; IN   ES:(E)DI     Name buffer
; IN   (E)CX        Max name size
; OUT  DX           ID
GetProgramInfo  MACRO
        UserGate get_program_info_nr
                ENDM

; IN   AX           Program #
; IN   ES:(E)DI     Module ID buffer (2 bytes per entry)
; IN   (E)CX        Max modules
; OUT  ECX          Module count
GetProgramModules       MACRO
        UserGate get_program_modules_nr
                ENDM

; IN   AX           Program #
; IN   ES:(E)DI     Process ID buffer (2 bytes per entry)
; IN   (E)CX        Max Processes
; OUT  ECX          Process count
GetProgramProcesses       MACRO
        UserGate get_program_processes_nr
                ENDM

; OUT  AX           Module count
GetModuleCount  MACRO
        UserGate get_module_count_nr
                ENDM

; OUT  AX           Process count
GetProcessCount  MACRO
        UserGate get_process_count_nr
                ENDM

; IN   AX           Module #
; IN   ES:(E)DI     Name buffer
; IN   (E)CX        Max name size
; OUT  DX           ID
GetModuleInfo   MACRO
        UserGate get_module_info_nr
                ENDM

; IN   BX           Module ID
; OUT  AX           Selector (or 0 for long mode)
GetModuleSelector    MACRO
        UserGate get_module_sel_nr
                ENDM

; IN   BX           Module ID
; OUT  EDX:EAX      Base address
GetModuleBase   MACRO
        UserGate get_module_base_nr
                ENDM

; IN   BX           Module ID
; OUT  EDX:EAX      Size
GetModuleSize   MACRO
        UserGate get_module_size_nr
                ENDM

; IN   AX           Process #
; IN   ES:(E)DI     Name buffer
; IN   (E)CX        Max name size
; OUT  DX           ID
GetProcessInfo   MACRO
        UserGate get_process_info_nr
                ENDM

; IN   BX           Process ID
; IN   ES:(E)DI     Thread ID buffer (2 bytes per entry)
; IN   (E)CX        Max Threads
; OUT  ECX          Thread count
GetProcessThreads       MACRO
        UserGate get_process_threads_nr
                ENDM

; IN   BX           Process ID
IsProcessRunning       MACRO
        UserGate is_process_running_nr
                ENDM

; IN   BX           Process ID
; IN   ES:(E)DI     Module ID buffer (2 bytes per entry)
; IN   (E)CX        Max modules
; OUT  ECX          Module count
GetProcessModules       MACRO
        UserGate get_process_modules_nr
                ENDM

; IN   BX           Process ID
; IN   DX           Module ID
; OUT  ECX          Usage count
GetProcessModuleUsage       MACRO
        UserGate get_process_module_usage_nr
                ENDM

;;;;;;;;;;;; C Handles ;;;;;;;;;;;;;;;;

; OUT ECX           Handle count
GetHandleCount      MACRO
        UserGate get_handle_count_nr
                                        ENDM

; IN  ES:(E)DI      Name
; IN  CX            Mode
; OUT EBX           Handle
OpenHandle      MACRO
        UserGate open_handle_nr
                                        ENDM

; IN  BX            Handle
CloseHandle     MACRO
        UserGate close_handle_nr
                                        ENDM

; IN  BX            Handle
; OUT EAX           Index
; OUT EDI           Flat address of file info
GetHandleMap        MACRO
        UserGate get_handle_map_nr
                                                ENDM

; IN  BX            Handle
; IN  EDX:EAX       File position
; IN  ECX           Size
MapHandle        MACRO
        UserGate map_handle_nr
                                                ENDM

; IN  BX            Handle
UpdateHandle        MACRO
        UserGate update_handle_nr
                                                ENDM

; IN  BX            Handle
; IN  EDX:EAX       File position
; IN  ECX           Size
GrowHandle        MACRO
        UserGate grow_handle_nr
                                                ENDM

; IN  BX        Handle
; IN  ES:(E)DI  Buffer
; IN  (E)CX     Number of bytes to read
; OUT (E)AX     Number of bytes read
PollHandle        MACRO
        UserGate poll_handle_nr
                                        ENDM

; IN  BX        Handle
; IN  ES:(E)DI  Buffer
; IN  (E)CX     Number of bytes to read
; OUT (E)AX     Number of bytes read
ReadHandle        MACRO
        UserGate read_handle_nr
                                        ENDM

; IN  BX        Handle
; IN  ES:(E)DI  Buffer
; IN  (E)CX     Number of bytes to write
; OUT (E)AX     Number of bytes written
WriteHandle       MACRO
        UserGate write_handle_nr
                                                ENDM

; IN  BX        Handle
; OUT EBX       New handle
DupHandle       MACRO
        UserGate dup_handle_nr
                                                ENDM

; IN  BX        Src handle
; IN  AX        Dest handle
; OUT EBX       New handle
Dup2Handle       MACRO
        UserGate dup2_handle_nr
                                                ENDM

; IN    BX      Handle
; OUT   EAX     Filesize
GetHandleSize32     MACRO
        UserGate get_handle_size32_nr
                                                ENDM


; IN    BX          Handle
; IN    EAX         Filesize
; OUT   EAX         Result
SetHandleSize32     MACRO
        UserGate set_handle_size32_nr
                                                ENDM

; IN    BX          Handle
; OUT   EDX:EAX     Filesize
GetHandleSize64     MACRO
        UserGate get_handle_size64_nr
                                                ENDM


; IN    BX          Handle
; IN    EDX:EAX     Filesize
; OUT   EDX:EAX     Result
SetHandleSize64     MACRO
        UserGate set_handle_size64_nr
                                                ENDM

; IN    BX          Handle
DeleteHandle     MACRO
        UserGate delete_handle_nr
                                                ENDM

; IN    BX      Handle
; OUT   EAX     Mode
GetHandleMode     MACRO
        UserGate get_handle_mode_nr
                                                ENDM


; IN    BX      Handle
; IN    EAX     Mode
; OUT   EAX     Result
SetHandleMode     MACRO
        UserGate set_handle_mode_nr
                                                ENDM


; IN    BX      Handle
; OUT   EAX     Position
GetHandlePos32     MACRO
        UserGate get_handle_pos32_nr
                                                ENDM


; IN    BX      Handle
; IN    EAX     Position
; OUT   EAX     Result
SetHandlePos32     MACRO
        UserGate set_handle_pos32_nr
                                                ENDM

; IN    BX          Handle
; OUT   EDX:EAX     Position
GetHandlePos64     MACRO
        UserGate get_handle_pos32_nr
                                                ENDM


; IN    BX          Handle
; IN    EDX:EAX     Position
; OUT   EDX:EAX     Result
SetHandlePos64     MACRO
        UserGate set_handle_pos64_nr
                                                ENDM


; IN  BX        Handle
; OUT EAX       Eof status
EofHandle       MACRO
        UserGate eof_handle_nr
                                                ENDM

; IN  BX        Handle
; OUT NC        Device
IsHandleDevice       MACRO
        UserGate is_handle_device_nr
                                                ENDM

; IN    BX              Handle
; OUT   EDX:EAX         Time
GetHandleCreateTime     MACRO
        UserGate get_handle_create_time_nr
                                                ENDM

; IN    BX              Handle
; OUT   EDX:EAX         Time
GetHandleModifyTime     MACRO
        UserGate get_handle_modify_time_nr
                                                ENDM

; IN    BX              Handle
; OUT   EDX:EAX         Time
GetHandleAccessTime     MACRO
        UserGate get_handle_access_time_nr
                                                ENDM

; IN    BX              Handle
; IN    EDX:EAX         Time
; OUT   EAX             Result
SetHandleModifyTime      MACRO
        UserGate set_handle_modify_time_nr
                                                ENDM

; IN    BX              Handle
; OUT   ECX             Buffer count
GetHandleReadBufferCount     MACRO
        UserGate get_handle_read_buf_count_nr
                                                ENDM

; IN    BX              Handle
; OUT   ECX             Buffer space
GetHandleWriteBufferSpace     MACRO
        UserGate get_handle_write_buf_space_nr
                                                ENDM

; IN    BX              Handle
HasHandleException     MACRO
        UserGate has_handle_exception_nr
                                                ENDM

; IN  AX        Handle
; IN  BX        Wait handle
; IN  ECX       Object ID
AddWaitForHandleRead       MACRO
        UserGate add_wait_for_handle_read_nr
                                                ENDM

; IN  AX        Handle
; IN  BX        Wait handle
; IN  ECX       Object ID
AddWaitForHandleWrite       MACRO
        UserGate add_wait_for_handle_write_nr
                                                ENDM

; IN  AX        Handle
; IN  BX        Wait handle
; IN  ECX       Object ID
AddWaitForHandleException       MACRO
        UserGate add_wait_for_handle_exception_nr
                                                ENDM


; IN  ES:(E)DI          read, write and exception masks
; IN  ECX               number of bytes in mask
; OUT ECX               number of non-blocking handles
SelectBase               MACRO
    UserGate select_nr
                        ENDM

; IN    BX              Handle
SetHandleBlockingMode     MACRO
        UserGate set_handle_blocking_mode_nr
                                                ENDM


; IN    BX              Handle
SetHandleNonblockingMode     MACRO
        UserGate set_handle_nonblocking_mode_nr
                                                ENDM


;;;;;;;;;;;;;; INI FILE HANDLING ;;;;;;;;;;;

; OUT BX            Ini handle
OpenSysIni      MACRO
        UserGate open_sys_ini_nr
                ENDM

; IN  ES:(E)DI      Ini file name
; OUT BX            Ini handle
OpenIni MACRO
        UserGate open_ini_nr
                ENDM

; IN  BX            Ini handle
CloseIni        MACRO
        UserGate close_ini_nr
                ENDM

; IN  BX            In handle
; OUT BX            Out handle
DupIni  MACRO
        UserGate dup_ini_nr
                ENDM

; IN  BX            Ini handle
; IN  ES:(E)DI      Section name
GotoIniSection  MACRO
        UserGate goto_ini_section_nr
                ENDM

; IN  BX            Ini handle
; IN  ES:(E)DI      Section name
RemoveIniSection        MACRO
        UserGate remove_ini_section_nr
                ENDM

; IN  BX            Ini handle
; IN  DS:(E)SI      Var name
; IN  ES:(E)DI      Buffer
; IN  (E)CX         Max size
ReadIni MACRO
        UserGate read_ini_nr
                ENDM

; IN  BX            Ini handle
; IN  DS:(E)SI      Var name
; IN  ES:(E)DI      String
WriteIni        MACRO
        UserGate write_ini_nr
                ENDM

; IN  BX            Ini handle
; IN  DS:(E)SI      Var name
DeleteIni       MACRO
        UserGate delete_ini_nr
                ENDM

; IN  BX            Ini handle
GotoFirstIniVar MACRO
        UserGate goto_first_inivar_nr
                ENDM

; IN  BX            Ini handle
GotoNextIniVar  MACRO
        UserGate goto_next_inivar_nr
                ENDM

; IN  BX            Ini handle
; IN  ES:(E)DI      Var name
; IN  (E)CX         Max var size
GetCurrIniVar   MACRO
        UserGate get_curr_inivar_nr
                ENDM

;;;;;;;;;;;;;; DEBUGGING ;;;;;;;;;;;

; IN  EDX           IP address (0 = local)
RemoteGui      MACRO
        UserGate remote_gui_nr
                                                ENDM

; IN  EDX           IP address (0 = local)
RemoteDebug      MACRO
        UserGate remote_debug_nr
                                                ENDM

; OUT AX               Thread ID
;GetDebugThread MACRO
;       UserGate get_debug_thread_nr
;                                               ENDM

DebugTrace      MACRO
        UserGate debug_trace_nr
                                                ENDM

DebugPace       MACRO
        UserGate debug_pace_nr
                                                ENDM

DebugGo MACRO
        UserGate debug_go_nr
                                                ENDM

DebugRun MACRO
        UserGate debug_run_nr
                                                ENDM

DebugNext       MACRO
        UserGate debug_next_nr
                                                ENDM

; IN  ES:(E)DI          Action buffer
SetThreadAction     MACRO
        UserGate set_thread_action_nr
                                                ENDM


; IN  AX                Thread count
GetThreadCount     MACRO
        UserGate get_thread_count_nr
                                                ENDM

; IN  ES:(E)DI          State buffer
; IN  AX                Thread #
GetThreadState     MACRO
        UserGate get_thread_state_nr
                                                ENDM

; IN  ES:(E)DI          Action state buffer
; IN  AX                Thread #
GetThreadActionState     MACRO
        UserGate get_thread_action_state_nr
                                                ENDM

; IN  AX            Thread ID
SuspendThread     MACRO
        UserGate suspend_thread_nr
                                                ENDM

; IN  AX            Thread ID
SuspendAndSignalThread     MACRO
        UserGate suspend_and_signal_thread_nr
                                                ENDM

;  IN  AX   Process ID
;  IN  BX   Wait handle
;  IN  ECX  Signalled ID
AddWaitForDebugEvent MACRO
        UserGate add_wait_for_debug_event_nr
                                                ENDM

;  IN  BX   Process ID
;  OUT AX   Thread ID
;  OUT BL   Event type  
GetDebugEvent MACRO
        UserGate get_debug_event_nr
                                                ENDM

;  IN  BX       Process ID
;  IN  ES:EDI   Event buffer
GetDebugEventData MACRO
        UserGate get_debug_event_data_nr
                                                ENDM

;  IN  BX       Process ID
ClearDebugEvent MACRO
        UserGate clear_debug_event_nr
                                                ENDM

;  IN  BX       Process ID
;  IN  EAX      Thread ID
ContinueDebugEvent MACRO
        UserGate continue_debug_event_nr
                                                ENDM

;  IN  BX       Process ID
AbortDebug MACRO
        UserGate abort_debug_nr
                                                ENDM

;  IN  EBP      Exception frame
;  IN  EAX      Exception code
NotifyPeException MACRO
        UserGate notify_pe_exception_nr
                                                ENDM

;  IN  DX:ESI   Selector:Offset
;  IN  BX               Thread #
;  OUT EDX      Linear address
GetThreadLinear MACRO
        UserGate get_thread_linear_nr
                                        ENDM

;  IN  (E)CX    Number of bytes
;  IN  DX:ESI   Address to read at
;  IN  ES:(E)DI Buffer
;  IN  BX               Thread #
;  OUT (E)AX    Bytes read
ReadThreadMem   MACRO
        UserGate read_thread_mem_nr
                                        ENDM

;  IN  (E)CX    Number of bytes
;  IN  DX:ESI   Address to write at
;  IN  ES:(E)DI Buffer
;  IN  BX               Thread #
;  OUT (E)AX    Bytes written
WriteThreadMem  MACRO
        UserGate write_thread_mem_nr
                                        ENDM

;  IN  ES:(E)DI Buffer
;  IN  BX               Thread #
GetThreadTss    MACRO
        UserGate get_thread_tss_nr
                                        ENDM

;  IN  ES:(E)DI Buffer
;  IN  BX               Thread #
SetThreadTss    MACRO
        UserGate set_thread_tss_nr
                                        ENDM

;  IN  AL       Disc #
;  IN  EDX      Start sector #
;  IN  ECX      Number of sectors
DefineFaultSave     MACRO
        UserGate define_fault_save_nr
                                                ENDM

ClearFaultSave     MACRO
        UserGate clear_fault_save_nr
                                                ENDM

; IN  ES:(E)DI      State buffer
; IN  AX                Fault thread #
GetFaultThreadState     MACRO
        UserGate get_fault_thread_state_nr
                                                ENDM

; IN  ES:(E)DI      TSS data buffer
; IN  AX                Fault thread #
GetFaultThreadTss     MACRO
        UserGate get_fault_thread_tss_nr
                                                ENDM

HasCrashInfo     MACRO
        UserGate has_crash_info_nr
                                                ENDM

; IN  AX            Core #
; IN  ES:(E)DI      Data buffer
GetCrashCoreInfo     MACRO
        UserGate get_crash_core_info_nr
                                                ENDM

; IN  BX            Selector
; OUT ECX           Limit
; OUT AL            Bitness (16 or 32)
GetSelectorInfo     MACRO
        UserGate get_selector_info_nr
                                                ENDM

;;;;;;;;;;; TIME & DATE ;;;;;;;;;;;;;

; IN  BX                        Thread handle
; OUT EDX:EAX           Used CPU time
GetCpuTime      MACRO
        UserGate get_cpu_time_nr
                                        ENDM

; OUT EDX:EAX       System time
GetSystemTime   MACRO
        UserGate get_system_time_nr
                                        ENDM

; OUT EDX:EAX         Real time
GetTime   MACRO
        UserGate get_time_nr
                                        ENDM

; OUT EDX:EAX       System time
UserGetSystemTime   MACRO
        UserGate user_get_system_time_nr
                                        ENDM

; OUT EDX:EAX         Real time
UserGetTime   MACRO
        UserGate user_get_time_nr
                                        ENDM

TimeToSystemTime   MACRO
        UserGate time_to_system_time_nr
                                        ENDM

; IN  EDX:EAX         System time
; OUT EDX:EAX         Real time
SystemTimeToTime   MACRO
        UserGate system_time_to_time_nr
                                        ENDM


; IN  EDX:EAX           Difference between real time and system time
UpdateTime      MACRO
        UserGate update_time_nr
                                        ENDM

; IN  DX                Year
; IN  CH                Month
; OUT AL                Days in month
DaysInMonth     MACRO
        UserGate days_in_month_nr
                                ENDM

; IN  DX                Year
; IN  CH                Month
; IN  CL                Day
; IN  BH                Hour
; IN  BL                Minute
; IN  AH                Seconds
; OUT DX                Year
; OUT CH                Month
; OUT CL                Day
; OUT BH                Hour
; OUT BL                Minute
; OUT AH                Seconds
AdjustTime      MACRO
        UserGate adjust_time_nr
                                ENDM

; IN  DX                Year
; IN  CH                Month
; IN  CL                Day
; OUT AX                Passed days
PassedDays      MACRO
        UserGate passed_days_nr
                                ENDM


; IN  DX                Year
; IN  CH                Month
; IN  CL                Day
; IN  BH                Hour
; IN  BL                Minute
; IN  AH                Seconds
; OUT EDX:EAX   Binary time
TimeToBinary    MACRO
        UserGate time_to_binary_nr
                                ENDM

; IN  EDX:EAX   Binary time
; OUT DX                Year
; OUT CH                Month
; OUT CL                Day
; OUT BH                Hour
; OUT BL                Minute
; OUT AH                Seconds
BinaryToTime    MACRO
        UserGate binary_to_time_nr
                                ENDM

; IN  EDX               NTP IP address
SyncTime                MACRO
        UserGate sync_time_nr
                        ENDM

;;;;;;;;;;; CONSOLE ;;;;;;;;;;;

; IN  AL        Switch key
EnableFocus     MACRO
        UserGate enable_focus_nr
                                                ENDM

; IN  AL        Switch key
SetFocus        MACRO
        UserGate set_focus_nr
                                                ENDM

;;;;;;;;;;;;; NETWORK ;;;;;;;;;;;


; IN  AL                Adapter #
; OUT EAX               Hardware ID
GetNetHwId  MACRO
        UserGate get_net_hw_id_nr
                                ENDM

; OUT EAX               Primary DNS IP address (or 0)
; OUT EDX               Secondary DNS IP address (or 0)
GetDns  MACRO
        UserGate get_dns_nr
                                ENDM

; OUT EAX               Primary DNS IP address (or 0)
; OUT EDX               Secondary DNS IP address (or 0)
GetPppDns       MACRO
        UserGate get_ppp_dns_nr
                                ENDM

; IN  AX            max connections
; IN  ECX                       buffer size
; IN  SI                        local port
; OUT BX            listen handle
CreateTcpListen MACRO
        UserGate create_tcp_listen_nr
                        ENDM

; IN  BX            listen handle
; OUT AX            connection handle
GetTcpListen    MACRO
        UserGate get_tcp_listen_nr
                        ENDM

; IN  BX                listen handle
CloseTcpListen  MACRO
        UserGate close_tcp_listen_nr
                        ENDM

; IN  AX            max connections
; IN  ECX                       buffer size
; IN  SI                        local port
; OUT BX            listen handle
CreateSecureListen MACRO
        UserGate create_secure_listen_nr
                        ENDM

; IN  BX            listen handle
; OUT AX            connection handle
GetSecureListen    MACRO
        UserGate get_secure_listen_nr
                        ENDM

; IN  BX            listen handle
; IN  DS:(E)SI      certificate filename
; IN  ES:(E)DI      key filename
; IN  ES:(E)DX      chain filename
SetSecureCertificate    MACRO
        UserGate set_secure_cert_nr
                        ENDM

; IN  BX                listen handle
CloseSecureListen  MACRO
        UserGate close_secure_listen_nr
                        ENDM

; IN  EAX               Timeout in milliseconds for connection
; IN  ECX               buffer size
; IN  EDX               ip address
; IN  SI                local port (0 for dynamic port)
; IN  DI                remote port
; OUT BX                connection handle
OpenTcpConnection       MACRO
        UserGate open_tcp_connection_nr
                        ENDM

; IN  BX                connection handle
; IN  EAX               timeout in milliseconds
WaitForTcpConnection    MACRO
        UserGate wait_for_tcp_connection_nr
                        ENDM

; IN  BX                connection handle
CloseTcpConnection      MACRO
        UserGate close_tcp_connection_nr
                        ENDM

; IN  BX                connection handle
DeleteTcpConnection     MACRO
        UserGate delete_tcp_connection_nr
                        ENDM

; IN  BX                connection handle
IsTcpConnectionClosed   MACRO
        UserGate is_tcp_connection_closed_nr
                        ENDM

; IN  BX                connection handle
; OUT NC        Idle
IsTcpConnectionIdle     MACRO
        UserGate is_tcp_connection_idle_nr
                        ENDM

; IN  BX                connection handle
; OUT EAX       IP
GetRemoteTcpConnectionIP        MACRO
        UserGate get_remote_tcp_connection_ip_nr
                        ENDM

; IN  BX                connection handle
; OUT AX        port
GetRemoteTcpConnectionPort      MACRO
        UserGate get_remote_tcp_connection_port_nr
                        ENDM

; IN  BX                connection handle
; OUT AX        port
GetLocalTcpConnectionPort       MACRO
        UserGate get_local_tcp_connection_port_nr
                        ENDM

; IN  BX                connection handle
AbortTcpConnection      MACRO
        UserGate abort_tcp_connection_nr
                        ENDM

; IN  EAX                       timeout in ms for receive
; IN  BX                        connection handle
; IN  (E)CX             wanted number of bytes
; IN  ES:E(DI)  data buffer
; OUT (E)AX             size of received data
ReadTcpConnection       MACRO
        UserGate read_tcp_connection_nr
                        ENDM

; IN  BX                        connection handle
; IN  (E)CX             buffer size
; IN  ES:(E)DI  data buffer
WriteTcpConnection              MACRO
        UserGate write_tcp_connection_nr
                        ENDM

; IN  BX                connection handle
PushTcpConnection               MACRO
        UserGate push_tcp_connection_nr
                        ENDM

; IN  BX                connection handle
; OUT (E)AX     number of available bytes in buffer
PollTcpConnection               MACRO
        UserGate poll_tcp_connection_nr
                        ENDM

; IN  BX                connection handle
; OUT (E)AX             number of free bytes in write buffer
GetTcpConnectionWriteSpace               MACRO
        UserGate get_tcp_connection_write_space_nr
                        ENDM

; IN  BX                connection handle
WaitForTcpConnectionWriteSpace               MACRO
        UserGate wait_for_tcp_connection_write_space_nr
                        ENDM

; OUT EDX               My IP address
GetIpAddress    MACRO
        UserGate get_ip_address_nr
                                                ENDM

; OUT EDX               My IP address
GetGateway      MACRO
        UserGate get_gateway_nr
                                                ENDM

; OUT EDX           IP mask
GetIpMask       MACRO
        UserGate get_ip_mask_nr
                                                ENDM


; IN  AX                Entry #
; OUT EBX               Entry IP address
; OUT EDX:EAX           Last update
GetDhcpEntry    MACRO
        UserGate get_dhcp_entry_nr
                                                ENDM


; IN  ES:(E)DI          Host name
; OUT EDX                       IP address
NameToIP                MACRO
        UserGate name_to_ip_nr
                        ENDM

; IN  EDX                               IP address
; IN  (E)CX                     Size of buffer
; IN  ES:(E)DI          Host name buffer
; OUT (E)AX                     Length of host name
IPToName                MACRO
        UserGate ip_to_name_nr
                        ENDM

; IN  EDX               IP address
; IN  ES:(E)DI          Mac buffer
IPToMac                MACRO
        UserGate ip_to_mac_nr
                        ENDM

; IN  EAX                               Timeout in ms
; IN  EDX                               IP address
Ping            MACRO
        UserGate ping_nr
                        ENDM

; IN  SI        source port
; IN  BX        destination port
; IN  EDX       IP-address
; IN  (E)CX     Number of bytes to send
; IN  ES:(E)DI  Data buffer
SendUdp    MACRO
    UserGate send_udp_nr
            ENDM

; IN  SI          Source port
; IN  BX          Destination port
; IN  (E)CX       Number of bytes to send
; IN  ES:(E)DI    Data buffer
BroadcastUdp      MACRO
    UserGate broadcast_udp_nr
                        ENDM

; IN  EDX         Timeout in ms
; IN  (E)CX       Size of setup message
; IN  DS:(E)SI    Request buffer  
; IN  ES:(E)DI    Answer buffer
; IN  BX          Destination port
; OUT EAX         Answer size
; OUT EDX         IP
BroadcastQueryUdp      MACRO
    UserGate broadcast_query_udp_nr
                        ENDM

; IN  AX            max number of outstanding messages
; IN  SI                        local port
; OUT BX            listen handle
CreateUdpListen MACRO
        UserGate create_udp_listen_nr
                        ENDM

; IN  BX            listen handle
; OUT EAX           data size
GetUdpListenSize        MACRO
        UserGate get_udp_listen_size_nr
                        ENDM

; IN  BX            listen handle
; OUT EAX           IP
GetUdpListenIp  MACRO
        UserGate get_udp_listen_ip_nr
                        ENDM

; IN  BX            listen handle
; OUT AX            Port
GetUdpListenPort        MACRO
        UserGate get_udp_listen_port_nr
                        ENDM

; IN  BX            listen handle
; IN  (E)CX         buffer size
; IN  ES:(E)DI      buffer
GetUdpListenData        MACRO
        UserGate get_udp_listen_data_nr
                        ENDM

; IN  BX            listen handle
ClearUdpListenData      MACRO
        UserGate clear_udp_listen_data_nr
                        ENDM

; IN  BX                listen handle
CloseUdpListen  MACRO
        UserGate close_udp_listen_nr
                        ENDM

; IN  EDX               ip address
; IN  SI                local port
; IN  DI                remote port
; OUT BX                connection handle
OpenUdpConnection       MACRO
        UserGate open_udp_connection_nr
                        ENDM

; IN  BX                connection handle
CloseUdpConnection      MACRO
        UserGate close_udp_connection_nr
                        ENDM

; IN  BX        connection handle
; IN  ES:(E)DI  Data buffer
; IN  (E)CX     Number of bytes to send
SendUdpConnection    MACRO
    UserGate send_udp_connection_nr
            ENDM

; IN  BX        connection handle
; OUT (E)CX     Bytes available
PeekUdpConnection    MACRO
    UserGate read_udp_connection_nr
            ENDM

; IN  BX        connection handle
; IN  ES:(E)DI  Data buffer
; IN  (E)CX     Buffer size
; OUT (E)AX     Bytes read
ReadUdpConnection    MACRO
    UserGate read_udp_connection_nr
            ENDM

; OUT BX                socket handle
CreateTcpSocket               MACRO
    UserGate create_tcp_socket_nr
                        ENDM

; OUT BX                socket handle
CreateUdpSocket               MACRO
    UserGate create_udp_socket_nr
                        ENDM

; IN  BX                socket handle
IsIpv4Socket               MACRO
    UserGate is_ipv4_socket_nr
                        ENDM

; IN  BX                socket handle
; IN  EDX               IP
; IN  SI                port
ConnectIpv4Socket               MACRO
    UserGate connect_ipv4_socket_nr
                        ENDM

; IN  BX                socket handle
; IN  SI                port
BindIpv4Socket               MACRO
    UserGate bind_ipv4_socket_nr
                        ENDM

; IN  BX                socket handle
; IN  ECX               max connections
ListenSocket               MACRO
    UserGate listen_socket_nr
                        ENDM

; IN  BX                socket handle
; OUT EDX               IP
; OUT AX                port
AcceptIpv4Socket               MACRO
    UserGate accept_ipv4_socket_nr
                        ENDM

; OUT EBX                session handle
CreateSecureSession       MACRO
        UserGate create_secure_session_nr
                        ENDM

; IN  EBX                session handle
CloseSecureSession       MACRO
        UserGate close_secure_session_nr
                        ENDM

; IN  EAX               Timeout in milliseconds for connection
; IN  EBX               Session handle
; IN  ECX               buffer size
; IN  EDX               ip address
; IN  SI                local port (0 for dynamic port)
; IN  DI                remote port
; OUT BX                connection handle
CreateSecureConnection       MACRO
        UserGate create_secure_connection_nr
                        ENDM

; IN  EBX               connection handle
CloseSecureConnection       MACRO
        UserGate close_secure_connection_nr
                        ENDM

; IN  BX                connection handle
; IN  EAX               timeout in milliseconds
WaitForSecureConnection    MACRO
        UserGate wait_for_secure_connection_nr
                        ENDM

; IN  BX                connection handle
IsSecureConnectionClosed   MACRO
        UserGate is_secure_connection_closed_nr
                        ENDM

; IN  EAX               timeout in ms for receive
; IN  BX                connection handle
; IN  (E)CX             wanted number of bytes
; IN  ES:E(DI)          data buffer
; OUT (E)AX             size of received data
ReadSecureConnection       MACRO
        UserGate read_secure_connection_nr
                        ENDM

; IN  BX                connection handle
; IN  (E)CX             buffer size
; IN  ES:(E)DI          data buffer
WriteSecureConnection              MACRO
        UserGate write_secure_connection_nr
                        ENDM

; IN  BX                connection handle
; OUT (E)AX             number of available bytes in buffer
PollSecureConnection               MACRO
        UserGate poll_secure_connection_nr
                        ENDM

; IN  BX                connection handle
; OUT (E)AX             number of free bytes in write buffer
GetSecureConnectionWriteSpace               MACRO
        UserGate get_secure_write_space_nr
                        ENDM

; IN  BX                connection handle
PushSecureConnection               MACRO
        UserGate push_secure_connection_nr
                        ENDM

; IN  BX                connection handle
; OUT NC                Idle
IsSecureConnectionIdle     MACRO
        UserGate is_secure_connection_idle_nr
                        ENDM

; IN  BX                connection handle
; OUT EAX               IP
GetRemoteSecureConnectionIP        MACRO
        UserGate get_remote_secure_ip_nr
                        ENDM

; IN  BX                connection handle
; OUT AX                port
GetRemoteSecureConnectionPort      MACRO
        UserGate get_remote_secure_port_nr
                        ENDM

; IN  BX                connection handle
; OUT AX                port
GetLocalSecureConnectionPort       MACRO
        UserGate get_local_secure_port_nr
                        ENDM

; IN  BX                connection handle
; IN  ES:(E)DI          JSON
; IN  (E)CX             max size
; OUT ECX               actual size
GetSecureConnectionCertificate       MACRO
        UserGate get_secure_connection_cert_nr
                        ENDM

; IN  DS:(E)SI          filename
; IN  ES:(E)DI          JSON
; IN  (E)CX             max size
; OUT ECX               actual size
GetCertificateJson       MACRO
        UserGate get_cert_json_nr
                        ENDM

;;;;;;;;;;;;; LOW-LEVEL DISCS ;;;;;;;;;;;;;


; IN   AL                       Disc #
SyncDiscPart     MACRO
        UserGate sync_disc_part_nr
                                                ENDM

; IN   BL           Unit #
; OUT  AL                       Disc #
GetIdeDisc     MACRO
        UserGate get_ide_disc_nr
                                                ENDM

; IN   BL           Unit #
; OUT  AL                       Disc #
GetFloppyDisc     MACRO
        UserGate get_floppy_disc_nr
                                                ENDM

;       IN      AL                      Disc #
;   OUT NC          Idle
IsDiscIdle     MACRO
        UserGate is_disc_idle_nr
                                                ENDM

;       IN      AL                      Disc #
;       OUT     CX                      Bytes / sector
;       OUT     EDX:EAX     Total # of sectors
;       OUT SI                  BIOS sectors / cylinder
;       OUT DI                  BIOS heads
GetDiscInfo     MACRO
        UserGate get_disc_info_nr
                                                ENDM

; IN   AL           Disc #
; IN   CX                       Bytes / sector
; IN   EDX          Total # of sectors
; IN   SI           BIOS sectors / cylinder
; IN   DI           BIOS heads
SetDiscInfo     MACRO
        UserGate set_disc_info_nr
                                                ENDM

;       IN      AL                      Disc #
;   IN  ES:(E)DI    Buffer
;   IN  (E)CX       Buffer size
GetDiscVendorInfo     MACRO
        UserGate get_disc_vendor_info_nr
                                                ENDM

; IN   AL              Disc #
IsVfsDisc     MACRO
        UserGate is_vfs_disc_nr
                                               ENDM

; IN   AL              Disc #
; OUT EDX:EAX          Cached bytes
GetDiscCache     MACRO
        UserGate get_disc_cache_nr
                                               ENDM

; IN   AL              Disc #
; OUT EDX:EAX          Locked bytes
GetDiscLocked     MACRO
        UserGate get_disc_locked_nr
                                               ENDM

;       IN      AL              Disc #
;       OUT     EAX             Cached sectors
GetDiscCacheSize     MACRO
        UserGate get_disc_cache_size_nr
                                                ENDM


;       IN      AL                      Disc #
ResetDisc     MACRO
        UserGate reset_disc_nr
                                                ENDM

;       OUT     EAX             Cached size
GetFileCacheSize     MACRO
        UserGate get_file_cache_size_nr
                                                ENDM


;       IN      AL              Drive #
AllocateFixedDrive      MACRO
        UserGate allocate_fixed_drive_nr
                                        ENDM

;       IN      AL                      Drive #
RemoveDrive     MACRO
        UserGate remove_drive_nr
                                                ENDM

;       IN      AL              Drive #
DemandLoadDrive MACRO
        UserGate demand_load_drive_nr
                                        ENDM

;       IN      AL                      Disc #
;       IN      EDX                     Start sector
;       IN      ECX                     Number of sectors
;       IN      ES:(E)DI        File system name
FormatDrive     MACRO
        UserGate format_drive_nr
                                                ENDM

;       IN DS:(E)SI             Main key buffer
;       IN ES:(E)DI             Selection key buffer
;       IN GS:(E)BX             Extent size buffer
GetRdfsInfo     MACRO
        UserGate get_rdfs_info_nr
                                                ENDM

;       IN      AL                      Disc #
;       IN      EDX                     Sector #
;       IN      (E)CX           Size
;       IN      ES:(E)DI        Buffer
ReadShortDisc     MACRO
        UserGate read_short_disc_nr
                                                ENDM

;       IN      AL                      Disc #
;       IN      EDX                     Sector #
;       IN      (E)CX           Size
;       IN      ES:(E)DI        Buffer
WriteShortDisc     MACRO
        UserGate write_short_disc_nr
                                                ENDM

;       IN      BL                      Disc #
;       IN      EDX:EAX         Sector #
;       IN      (E)CX           Size
;       IN      ES:(E)DI        Buffer
ReadLongDisc     MACRO
        UserGate read_long_disc_nr
                                                ENDM

;       IN      BL                      Disc #
;       IN      EDX:EAX         Sector #
;       IN      (E)CX           Size
;       IN      ES:(E)DI        Buffer
WriteLongDisc     MACRO
        UserGate write_long_disc_nr
                                                ENDM

;       IN      AL                      Disc #
;       IN      EDX                     Sector #
;       IN      (E)CX       Number of sectors to erase
EraseDiscSectors     MACRO
        UserGate erase_disc_sectors_nr
                                                ENDM

;       IN      AL                      Drive #
;       OUT     EAX                     Free units
;       OUT     CX                      bytes / unit
;       OUT     EDX                     total # of units
GetDriveInfo     MACRO
        UserGate get_drive_info_nr
                                                ENDM

;       IN      AL                      Drive #
;   OUT AL          Disc #
;   OUT ECX         Total # of sectors
;   OUT EDX         Start sector
GetDriveDiscParam     MACRO
        UserGate get_drive_disc_param_nr
                                                ENDM

;   IN  AL          Disc #
;   IN  ES:E(DI)    Command
;   OUT BX          Command handle
CreateVfsDiscCmd     MACRO
        UserGate create_vfs_disc_cmd_nr
                                                ENDM

;   IN  BX          Command handle
CloseVfsCmd     MACRO
        UserGate close_vfs_cmd_nr
                                                ENDM

;   IN  AX          Wait handle
;   IN  BX          Command handle
;   IN  ECX         Object ID
AddWaitForVfsCmd       MACRO
        UserGate add_wait_for_vfs_cmd_nr
                                                ENDM

;   IN  BX          Command handle
IsVfsCmdDone     MACRO
        UserGate is_vfs_cmd_done_nr
                                                ENDM

;   IN  BX          Command handle
;   OUT EAX         Message size
GetVfsRespSize     MACRO
        UserGate get_vfs_resp_size_nr
                                                ENDM

;   IN  BX          Command handle
;   IN  ES:E(DI)    Response buffer
;   IN  ECX         Buffer size
;   OUT EAX         Actual size
GetVfsRespData     MACRO
        UserGate get_vfs_resp_data_nr
                                                ENDM


; IN  AL              Drive #
; OUT AL              Disc #
GetVfsDriveDisc     MACRO
        UserGate get_vfs_drive_disc_nr
                                                ENDM

; IN  AL              Drive #
; OUT EDX:EAX         Start sector
GetVfsDriveStart     MACRO
        UserGate get_vfs_drive_start_nr
                                                ENDM

; IN  AL              Drive #
; OUT EDX:EAX         Sector count
GetVfsDriveSize     MACRO
        UserGate get_vfs_drive_size_nr
                                                ENDM

; IN  AL              Drive #
; OUT EDX:EAX         Free sectors
GetVfsDriveFree     MACRO
        UserGate get_vfs_drive_free_nr
                                                ENDM

; IN  ES:(E)DI        Path
IsVfsPath     MACRO
        UserGate is_vfs_path_nr
                                                ENDM

; IN  ES:(E)DI        Pathname
; IN  DS:(E)SI        Dir info     
; OUT BX              Handle
OpenDir   MACRO
        UserGate open_dir_nr
                                                ENDM

; IN  BX              Handle
CloseDir   MACRO
        UserGate close_dir_nr
                                                ENDM

;;;;;;;;;;;;;; DIRECTORY ;;;;;;;;;;;;;

;       IN      AL              Drive #
SetCurDrive     MACRO
        UserGate set_cur_drive_nr
                                                ENDM

;       OUT     AL              Drive #
GetCurDrive     MACRO
        UserGate get_cur_drive_nr
                                                ENDM


;       IN      ES:(E)DI        Pathname
SetCurDir       MACRO
        UserGate set_cur_dir_nr
                                                ENDM

;       IN      AL              Drive
;       IN      ES:(E)DI        Pathname
GetCurDir       MACRO
        UserGate get_cur_dir_nr
                                                ENDM

;       IN      ES:(E)DI        Pathname
MakeDir MACRO
        UserGate make_dir_nr
                                                ENDM

;       IN      ES:(E)DI        Pathname
RemoveDir       MACRO
        UserGate remove_dir_nr
                                                ENDM

;       IN      DS:(E)SI                Old pathname
;       IN      ES:(E)DI        New pathname
RenameFile      MACRO
        UserGate rename_file_nr
                                                ENDM

;       IN      ES:(E)DI        Pathname
DeleteFile      MACRO
        UserGate delete_file_nr
                                                ENDM

;       IN      ES:(E)DI        Pathname
;       IN      CX              File attribute
GetFileAttribute        MACRO
        UserGate get_file_attribute_nr
                                                ENDM

;       IN      ES:(E)DI        Pathname
;       IN      CX              File attribute
SetFileAttribute        MACRO
        UserGate set_file_attribute_nr
                                                ENDM


;       IN      ES:(E)DI                Pathname
;       OUT     BX                              Handle
OpenLegacyDir   MACRO
        UserGate open_legacy_dir_nr
                                                ENDM

;       IN      BX                              Handle
CloseLegacyDir   MACRO
        UserGate close_legacy_dir_nr
                                                ENDM

;       IN      BX                              Handle
;       IN      DX                              Entry #
;       IN      CX                              Max size of name
;       IN      ES:(E)DI                Buffer
;       OUT     ECX                             Filesize
;       OUT     BX                              File attribute
;       OUT     EDX:EAX                 File systemtime
ReadLegacyDir        MACRO
        UserGate read_legacy_dir_nr
                                                ENDM

;;;;;;;;;;;;;; FILES ;;;;;;;;;;;;;

;       IN      ES:(E)DI        Pathname
;       IN      CL                      Access mode
;       OUT     EBX                     Handle
OpenFile        MACRO
        UserGate open_file_nr
                                                ENDM

;       IN      ES:(E)DI        Pathname
;       IN      CX              Attribute
;       OUT     EBX             Handle
CreateFile      MACRO
        UserGate create_file_nr
                                                ENDM

;       IN      EBX             Handle
CloseFile       MACRO
        UserGate close_file_nr
                                                ENDM

;       IN      EAX                      Old handle
;       OUT     EBX                      New handle
DuplFile       MACRO
        UserGate dupl_file_nr
                                                ENDM


;       IN      EBX             Handle
;       OUT     EAX             Filesize
GetFileSize32     MACRO
        UserGate get_file_size32_nr
                                                ENDM


;       IN      EBX                     Handle
;       IN      EAX                     Filesize
SetFileSize32     MACRO
        UserGate set_file_size32_nr
                                                ENDM


;       IN      EBX             Handle
;       OUT     EDX:EAX         Filesize
GetFileSize64     MACRO
        UserGate get_file_size64_nr
                                                ENDM

; IN      EBX                     Handle
; IN      EDX:EAX                 Filesize
SetFileSize64     MACRO
        UserGate set_file_size64_nr
                                                ENDM


;       IN      EBX                     Handle
;       IN      EAX                     File position
GetFilePos32      MACRO
        UserGate get_file_pos32_nr
                                                ENDM


;       IN      EBX                     Handle
;       IN      EAX                     File position
SetFilePos32      MACRO
        UserGate set_file_pos32_nr
                                                ENDM

;       IN      EBX                     Handle
;       IN      EDX:EAX                 File position
GetFilePos64      MACRO
        UserGate get_file_pos64_nr
                                                ENDM


;       IN      EBX                     Handle
;       IN      EDX:EAX                 File position
SetFilePos64      MACRO
        UserGate set_file_pos64_nr
                                                ENDM


;       IN      EBX                     Handle
;       OUT     EDX:EAX         File system time
GetFileTime      MACRO
        UserGate get_file_time_nr
                                                ENDM

;       IN      EBX                     Handle
;       IN      EDX:EAX         File system time
SetFileTime      MACRO
        UserGate set_file_time_nr
                                                ENDM

;       IN      EBX             Handle
;       IN      ES:(E)DI        Buffer
;       IN      (E)CX           Number of bytes to read
;       OUT     (E)AX           Number of bytes read
ReadFile        MACRO
        UserGate read_file_nr
                                                ENDM

;       IN      EBX             Handle
;       IN      ES:(E)DI        Buffer
;       IN      (E)CX           Number of bytes to write
;       OUT (E)AX               Number of bytes written
WriteFile       MACRO
        UserGate write_file_nr
                                                ENDM

;;;;;;;;;;; MEMORY MAPPING ;;;;;;;;;;

;       IN EAX                  Size of mapping object
;       OUT BX                  Handle
CreateMapping        MACRO
        UserGate create_mapping_nr
                                                ENDM

;       IN EAX                  Size of mapping object
;       IN ES:(E)DI     Name for mapping
;       OUT BX                  Handle
CreateNamedMapping        MACRO
        UserGate create_named_mapping_nr
                                                ENDM

;       IN      ES:(E)DI        Name of mapping
;       OUT BX                  Handle
OpenNamedMapping        MACRO
        UserGate open_named_mapping_nr
                                                ENDM

;       IN  BX                  Handle
CloseMapping        MACRO
        UserGate close_mapping_nr
                                                ENDM

;       IN  EAX                 Offset into object
;       IN  BX                  Handle
;       IN      (E)CX           Size
;       IN  ES:(E)DI    Address to map at
MapView        MACRO
        UserGate map_view_nr
                                                ENDM

;       IN  BX                  Handle
UnmapView        MACRO
        UserGate unmap_view_nr
                                                ENDM

;;;;;;;;;;; KEYBOARD ;;;;;;;;;;;;;

;  IN  ES:(E)DI     Layout name buffer (must be at least 3 bytes)
GetKeyboardLayout    MACRO
        UserGate get_key_layout_nr
                                                ENDM

;  IN  ES:(E)DI     Layout name
SetKeyboardLayout    MACRO
        UserGate set_key_layout_nr
                                                ENDM

; OUT  AX                       Character read
ReadKeyboard    MACRO
        UserGate read_keyboard_nr
                                                ENDM

PollKeyboard    MACRO
        UserGate poll_keyboard_nr
                                                ENDM

FlushKeyboard   MACRO
        UserGate flush_keyboard_nr
                                                ENDM

; IN  AX          Keyboard code
; IN  DL          Virtual key code
; IN  DH          Scan code
PutKeyboardCode MACRO
        UserGate put_keyboard_code_nr
                                        ENDM

; OUT AX                        Character read
; OUT CX            Keyboard state
; OUT DL            Virtual key code
; OUT DH            Scan code
PeekKeyEvent    MACRO
        UserGate peek_key_event_nr
                                                ENDM

; OUT AX                        Character read
; OUT CX            Keyboard state
; OUT DL            Virtual key code
; OUT DH            Scan code
ReadKeyEvent    MACRO
        UserGate read_key_event_nr
                                                ENDM

ext_numpad_handled      EQU 800h
ext_numpad_active       EQU 400h
num_active                      EQU 200h
caps_active                     EQU 100h
print_pressed           EQU 20h
scroll_pressed          EQU 10h
pause_pressed           EQU 8
ctrl_pressed            EQU 4
alt_pressed                     EQU 2
shift_pressed           EQU 1

; OUT  AX               Keyboard states.
GetKeyboardState    MACRO
        UserGate get_keyboard_state_nr
                                                ENDM

;;;;;;;;;;;; MOUSE ;;;;;;;;;;;

ShowMouse    MACRO
        UserGate show_mouse_nr
                                                ENDM

HideMouse    MACRO
        UserGate hide_mouse_nr
                                                ENDM

; OUT CX              x
; OUT DX              y
GetMousePosition    MACRO
        UserGate get_mouse_position_nr
                                                ENDM

; IN  CX              x
; IN  DX              y
SetMousePosition    MACRO
        UserGate set_mouse_position_nr
                                                ENDM

;       IN  AX                  start x
;       IN  BX                  start y
;   IN  CX          end x
;   IN  DX          end y
SetMouseWindow    MACRO
        UserGate set_mouse_window_nr
                                                ENDM

;       IN  CX           mickeys in x-direction
;       IN  DX           mickeys in y-direction
SetMouseMickey    MACRO
        UserGate set_mouse_mickey_nr
                                                ENDM

;               NC                      button is pressed
GetLeftButton    MACRO
        UserGate get_left_button_nr
                                                ENDM

;               NC                      button is pressed
GetRightButton    MACRO
        UserGate get_right_button_nr
                                                ENDM

;       OUT CX              x
;       OUT DX              y
GetLeftButtonPressPosition    MACRO
        UserGate get_left_button_press_position_nr
                                                ENDM

;       OUT CX              x
;       OUT DX              y
GetRightButtonPressPosition    MACRO
        UserGate get_right_button_press_position_nr
                                                ENDM

;       OUT CX              x
;       OUT DX              y
GetLeftButtonReleasePosition    MACRO
        UserGate get_left_button_release_position_nr
                                                ENDM

;       OUT CX              x
;       OUT DX              y
GetRightButtonReleasePosition    MACRO
        UserGate get_right_button_release_position_nr
                                                ENDM

;       IN  ES:(E)DI    Callback
;                       AX              Buttons
;                       CX              Delta x movement
;                       DX              Delta y movement
HookMouse    MACRO
        UserGate hook_mouse_nr
                                                ENDM

UnhookMouse    MACRO
        UserGate unhook_mouse_nr
                                                ENDM

;;;;;;;;;;;;; CDROM ;;;;;;;;;;;;

LockCd  MACRO
        UserGate lock_cd_nr
                ENDM
                
UnlockCd        MACRO
        UserGate unlock_cd_nr
                        ENDM
                        
EjectCd MACRO
        UserGate eject_cd_nr
                ENDM
                
InsertCd        MACRO
        UserGate insert_cd_nr
                        ENDM

;;;;;;;;;;;;; SERIAL PORT ;;;;;;;;;;;;;

;   OUT AL      Port #
GetMaxComPort       MACRO
        UserGate get_max_com_port_nr
                                                ENDM

;       IN  AL          Port #
;   NC          Available
IsComAvailable       MACRO
        UserGate is_com_available_nr
                                                ENDM

;   IN AL      Port #
;   NC         OK
;   OUT AL     IRQ #
;   OUT DX     IO Base
;   OUT ECX    Baud base
GetStdComPar       MACRO
        UserGate get_std_com_par_nr
                                                ENDM

;   IN AL      Port #
;   NC         OK
;   OUT AX     Device type
GetUsbComPar       MACRO
        UserGate get_usb_com_par_nr
                                                ENDM


;   IN  AL     Port #
;   OUT BX     USB controller
;   OUT AX     USB device
GetUsbComDevice      MACRO
        UserGate get_usb_com_dev_nr
                        ENDM

;   IN AL      Port #
;   NC         OK
;   OUT DX     Vendor
;   OUT AX     Product
GetUsbCdcComPar       MACRO
        UserGate get_usb_cdc_com_par_nr
                                                ENDM

;   IN  AL     Port #
;   OUT BX     USB controller
;   OUT AX     USB device
GetUsbCdcComDevice      MACRO
        UserGate get_usb_cdc_com_dev_nr
                        ENDM

;   IN AL      Port #
;   NC         OK
GetUsbBusPar       MACRO
        UserGate get_usb_bus_par_nr
                                                ENDM

;       IN  AL          Port #
;       IN  AH          # of data bits
;       IN  BL          # of stop bits
;       IN  BH          parity ('N', 'E' or 'O')
;       IN  ECX         baudrate
;       IN  SI          size of transmit buffer
;       IN  DI          size of receive buffer
;       OUT BX          port handle
OpenCom       MACRO
        UserGate open_com_nr
                                                ENDM

;       IN  BX          port handle
CloseCom       MACRO
        UserGate close_com_nr
                                                ENDM

;       IN  BX          port handle
FlushCom       MACRO
        UserGate flush_com_nr
                                                ENDM

;       IN  BX          port handle
ResetCom       MACRO
        UserGate reset_com_nr
                                                ENDM

;       IN  BX          port handle
;       OUT AX          data read or -1
ReadCom       MACRO
        UserGate read_com_nr
                                                ENDM

;       IN  BX          port handle
;       OUT AL          data to send
WriteCom       MACRO
        UserGate write_com_nr
                                                ENDM

;       IN  BX          port handle
WaitForSendCompletedCom       MACRO
        UserGate wait_for_send_completed_com_nr
                                                ENDM

;       IN  BX          port handle
EnableCts       MACRO
        UserGate enable_cts_nr
                                                ENDM

;       IN  BX          port handle
DisableCts       MACRO
        UserGate disable_cts_nr
                                                ENDM

;       IN  BX          port handle
SetDtr       MACRO
        UserGate set_dtr_nr
                                                ENDM

;       IN  BX          port handle
ResetDtr       MACRO
        UserGate reset_dtr_nr
                                                ENDM

;       IN  BX          port handle
SetRts       MACRO
        UserGate set_rts_nr
                                                ENDM

;       IN  BX          port handle
ResetRts       MACRO
        UserGate reset_rts_nr
                                                ENDM

;       IN  BX          port handle
EnableAutoRts       MACRO
        UserGate enable_auto_rts_nr
                                                ENDM

;       IN  BX          port handle
DisableAutoRts       MACRO
        UserGate disable_auto_rts_nr
                                                ENDM

;       IN  BX          port handle
IsAutoRtsOn       MACRO
        UserGate is_auto_rts_on_nr
                                                ENDM

;       IN  BX          port handle
;   OUT EAX     free space
GetComReceiveSpace       MACRO
        UserGate get_com_receive_space_nr
                                                ENDM

;       IN  BX          port handle
;   OUT EAX     free space
GetComSendSpace       MACRO
        UserGate get_com_send_space_nr
                                                ENDM

;   IN  BX      Port handle
;   OUT EAX     Chars in buffer
GetComRecCount       MACRO
        UserGate get_com_rec_count_nr
                                                ENDM

;       IN  BX          port handle
;   OUT NC      ON
;   OUT CY      OFF
GetCts       MACRO
        UserGate read_cts_nr
                                                ENDM

;       IN  BX          port handle
;   OUT NC      ON
;   OUT CY      OFF
GetDsr       MACRO
        UserGate read_dsr_nr
                                                ENDM

;       IN  BX          port handle
;   NC         No support
;   CY         Support
SupporsFullDuplex       MACRO
        UserGate supports_full_duplex_nr
                                                ENDM

;       IN  BX          port handle
;       IN  AL          character count
SendComBreak       MACRO
        UserGate send_com_break_nr
                                                ENDM

;;;;;;;;;;;;;; PRINTER ;;;;;;;;;;;;

;   OUT AL      Printer #
GetMaxPrinters       MACRO
        UserGate get_max_printer_nr
                                                ENDM

;       IN  AL          Printer #
;       OUT BX          Printer handle
OpenPrinter       MACRO
        UserGate open_printer_nr
                                                ENDM

;       IN  BX          Printer handle
ClosePrinter       MACRO
        UserGate close_printer_nr
                                                ENDM

;       IN  BX          Printer handle
;   IN  ES:(E)DI      Name buffer
GetPrinterName       MACRO
        UserGate get_printer_name_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT CY      Jammed
IsPrinterJammed       MACRO
        UserGate is_printer_jammed_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT CY      Low
IsPrinterPaperLow       MACRO
        UserGate is_printer_paper_low_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT CY      End
IsPrinterPaperEnd       MACRO
        UserGate is_printer_paper_end_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT CY      Cutter jammed
IsPrinterCutterJammed       MACRO
        UserGate is_printer_cutter_jammed_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT NC      OK
IsPrinterOk       MACRO
        UserGate is_printer_ok_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT CY      Lifted
IsPrinterHeadLifted       MACRO
        UserGate is_printer_head_lifted_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT CY      Paper in presenter
HasPrinterPaperInPresenter      MACRO
        UserGate has_printer_paper_in_presenter_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT CY      Temperature error
HasPrinterTemperatureError      MACRO
        UserGate has_printer_temp_error_nr
                                                ENDM

;       IN  BX          Printer handle
;   OUT CY      Feed error
HasPrinterFeedError      MACRO
        UserGate has_printer_feed_error_nr
                                                ENDM

;       IN  BX          Printer handle
PrintTest       MACRO
        UserGate print_test_nr
                                                ENDM

;       IN  BX          Printer handle
;   IN  DX      Height
;   OUT AX      Bitmap handle
CreatePrinterBitmap       MACRO
        UserGate create_printer_bitmap_nr
                                                ENDM

;       IN  BX          Printer handle
;   IN  AX      Bitmap handle
PrintBitmap       MACRO
        UserGate print_bitmap_nr
                                                ENDM

;       IN  BX          Printer handle
;   IN  AX      Length in mm
PresentPrinterMedia       MACRO
        UserGate present_printer_media_nr
                                                ENDM

;       IN  BX          Printer handle
EjectPrinterMedia       MACRO
        UserGate eject_printer_media_nr
                                                ENDM

;       IN  BX          Printer handle
WaitForPrint       MACRO
        UserGate wait_for_print_nr
                                                ENDM

;       IN  BX          Printer handle
ResetPrinter       MACRO
        UserGate reset_printer_nr
                                                ENDM

;;;;;;;;;;;;;; Lonworks ;;;;;;;;;;;;

;   OUT AL      Lon modules #
GetLonModules       MACRO
        UserGate get_lon_modules_nr
                                                ENDM

;       IN  AL          Lon module #
;   IN  SI      Send buffers
;   IN  DI      Receive buffers
;       OUT BX          Lon handle
OpenLonModule       MACRO
        UserGate open_lon_module_nr
                                                ENDM

;       IN  AL      Lon module #
ResetLonModule       MACRO
        UserGate reset_lon_module_nr
                                                ENDM

;       IN  BX      Lon handle
CloseLonModule       MACRO
        UserGate close_lon_module_nr
                                                ENDM

; IN  BX                Wait handle
; IN  AX        Lon handle
; IN  ECX       Object ID
AddWaitForLonModule       MACRO
        UserGate add_wait_for_lon_module_nr
                                                ENDM

; IN  BX                Lon handle
; IN  ES:(E)DI  Buffer
; IN  (E)CX     Size
SendLonModuleMsg       MACRO
        UserGate send_lon_module_msg_nr
                                                ENDM

; IN  BX                Lon handle
; OUT NC        Message
HasLonModuleMsg       MACRO
        UserGate has_lon_module_msg_nr
                                                ENDM

; IN  BX                Lon handle
; IN  ES:(E)DI  Buffer
; OUT ECX       Size
ReceiveLonModuleMsg       MACRO
        UserGate receive_lon_module_msg_nr
                                                ENDM

;;;;;;;;;;;;;; CARD DEVICE ;;;;;;;;;;;;

;   OUT AL      Card device #
GetMaxCardDev       MACRO
        UserGate get_max_carddev_nr
                                                ENDM

;       IN  AL          Card device #
;       OUT BX          Card device handle
OpenCardDev       MACRO
        UserGate open_carddev_nr
                                                ENDM

;       IN  BX          Card device handle
CloseCardDev       MACRO
        UserGate close_carddev_nr
                                                ENDM

;       IN  BX                Card device handle
;   IN  ES:(E)DI      Name buffer
GetCardDevName       MACRO
        UserGate get_carddev_name_nr
                                                ENDM

;       IN  BX          Card device handle
;   OUT NC      OK
IsCardDevOk       MACRO
        UserGate is_carddev_ok_nr
                                                ENDM

;       IN  BX          Card device handle
;   OUT NC      Busy
IsCardDevBusy       MACRO
        UserGate is_carddev_busy_nr
                                                ENDM

;       IN  BX          Card device handle
;   OUT NC      Card inserted
IsCardDevInserted       MACRO
        UserGate is_carddev_inserted_nr
                                                ENDM

;       IN  BX          Card device handle
;   OUT NC      Card inserted
HadCardDevInserted       MACRO
        UserGate had_carddev_inserted_nr
                                                ENDM

;       IN  BX          Card device handle
ClearCardDevInserted       MACRO
        UserGate clear_carddev_inserted_nr
                                                ENDM

;       IN  BX                Card device handle
;   IN  ES:(E)DI      Strip buffer
WaitForCard       MACRO
        UserGate wait_for_card_nr
                                                ENDM

;   IN  BX            Card device handle
;   IN  ES:(E)DI      Track 1 buffer
GetCardDevTrack1       MACRO
        UserGate get_carddev_track1_nr
                                                ENDM

;;;;;;;;;; SCREEN, TEXT MODE ;;;;;;;;;;

ClearText    MACRO
        UserGate clear_text_nr
                                                ENDM

;       OUT CX              Columns
;       OUT DX              Rows
GetTextSize    MACRO
        UserGate get_text_size_nr
                                                ENDM

;       IN  CX              Column number (x)
;       IN  DX              Row number (y)
SetCursorPosition    MACRO
        UserGate set_cursor_position_nr
                                                ENDM

;       OUT CX              Column number (x)
;       OUT DX              Row number (y)
GetCursorPosition    MACRO
        UserGate get_cursor_position_nr
                                                ENDM

;       IN  CX              Column number (x)
;       IN  DX              Row number (y)
SetConsoleCursorPosition    MACRO
        UserGate set_console_cursor_position_nr
                                                ENDM

;       OUT CX              Column number (x)
;       OUT DX              Row number (y)
GetConsoleCursorPosition    MACRO
        UserGate get_console_cursor_position_nr
                                                ENDM

;       IN  AL              Color number
SetForeColor        MACRO
        UserGate set_forecolor_nr
                                                ENDM

;       IN  AL              Color number. 0FFh is transparent
SetBackColor        MACRO
        UserGate set_backcolor_nr
                                                ENDM

;       OUT AL          Char
;       OUT BL                  Back color
;   OUT BH                      Fore color
GetCharAttrib       MACRO
        UserGate get_char_attrib_nr
                                                ENDM

;       IN  AL              Char
WriteChar       MACRO
        UserGate write_char_nr
                                                ENDM

;       IN  ES:(E)DI           Null terminated string
WriteAsciiz     MACRO
        UserGate write_asciiz_nr
                                                ENDM

;       IN  ES:(E)DI           Buffer
;   IN  (E)CX              Count
WriteSizeString MACRO
        UserGate write_size_string_nr
                                                ENDM

;       IN  AX              Column number (x)
;       IN  DX              Row number (y)
;       IN  ES:(E)DI        Buffer
;   IN  (E)CX           Count
WriteAttributeString MACRO
        UserGate write_attrib_string_nr
                                                ENDM

;;;;;;;;;;; FONT ;;;;;;;;;;

;       IN  DS:(E)SI        ANSI string
;       IN  DS:(E)DI        UTF-8 string
;   IN  (E)CX           Buffer size
;       OUT EAX             String size
AnsiToUtf8        MACRO
        UserGate ansi_to_utf8_nr
                                                ENDM

;       IN  DS:(E)SI        UTF-8 string
;       IN  DS:(E)DI        ANSI string
;   IN  (E)CX           Buffer size
;       OUT EAX             String size
Utf8ToAnsi        MACRO
        UserGate utf8_to_ansi_nr
                                                ENDM

;       IN  DS:(E)SI        ANSI string
;       IN  DS:(E)DI        UTF-16 string
;   IN  (E)CX           Buffer size
;       OUT EAX             String size
AnsiToUtf16        MACRO
        UserGate ansi_to_utf16_nr
                                                ENDM

;       IN  DS:(E)SI        UTF-16 string
;       IN  DS:(E)DI        ANSI string
;   IN  (E)CX           Buffer size
;       OUT EAX             String size
Utf16ToAnsi        MACRO
        UserGate utf16_to_ansi_nr
                                                ENDM

;       IN  AX              Requested font height
;   IN  DX              Requested font ID
;       OUT     BX                              Font handle
OpenFont        MACRO
        UserGate open_font_nr
                                                ENDM

;       IN      BX                              Font handle
CloseFont        MACRO
        UserGate close_font_nr
                                                ENDM

;       IN  ES:E(DI)            String to ask about
;       IN      BX                              Font handle
;       OUT CX                          Width of string
;       OUT DX                          Height of char
GetStringMetrics        MACRO
        UserGate get_string_metrics_nr
                                                ENDM

;;;;;;;;;;; SCREEN, GRAPHICS MODE ;;;;;;;;;;

;       IN  AX          Requested mode
;       OUT AX          bits / pixel
;       OUT CX          x-resolution
;       OUT DX          y-resolution
QueryVideoMode      MACRO
        UserGate query_video_mode_nr
                                                ENDM

;       IN  AX          bits / pixel
;       IN  CX          x-resolution
;       IN  DX          y-resolution
;       OUT AX          Requested mode
GetVideoMode      MACRO
        UserGate get_video_mode_nr
                                                ENDM

;       IN  AX          Requested mode
;       OUT AX          bits / pixel
;       OUT BX          bitmap handle
;       OUT CX          x-resolution
;       OUT DX          y-resolution
;       OUT SI          line size
;       OUT     ES:EDI  video buffer
SetVideoMode      MACRO
        UserGate set_video_mode_nr
                                                ENDM

SetVgaMode      MACRO
        UserGate set_vga_mode_nr
                                                ENDM

;       IN  EAX                 RGB color
;       IN      BX                              Bitmap handle
SetDrawColor        MACRO
        UserGate set_drawcolor_nr
                                                ENDM

;       IN  AX              LGOP
;       IN      BX                              Bitmap handle
SetLgop        MACRO
        UserGate set_lgop_nr
                                                ENDM

;       IN      BX              Bitmap handle
;       IN      CX              min x
;       IN      DX          min y
;       IN  SI          max x
;       IN  DI      max y
SetClipRect        MACRO
        UserGate set_clip_rect_nr
                                                ENDM

;       IN      BX              Bitmap handle
ClearClipRect        MACRO
        UserGate clear_clip_rect_nr
                                                ENDM

;       IN      BX                              Bitmap handle or 0
SetHollowStyle        MACRO
        UserGate set_hollow_style_nr
                                                ENDM

;       IN      BX                              Bitmap handle or 0
SetFilledStyle        MACRO
        UserGate set_filled_style_nr
                                                ENDM

;       IN      BX              Bitmap handle or 0
;       IN  CX          x
;       IN  DX          y
;       OUT EAX         RGB value
GetPixel      MACRO
        UserGate get_pixel_nr
                                                ENDM

;       IN      BX              Bitmap handle or 0
;       IN  CX          x
;       IN  DX          y
SetPixel      MACRO
        UserGate set_pixel_nr
                                                ENDM

;       IN  AX          Source bitmap handle or 0
;       IN      BX              Dest bitmap handle or 0
;       IN      CX              Width
;       IN      DX              Height
;       IN      ESI             source x + y << 16
;       IN      EDI             dest x + y << 16
Blit      MACRO
        UserGate blit_nr
                                                ENDM

;       IN      AX              Row size
;       IN      BX              Bitmap handle or 0
;       IN      ECX             source x + y << 16
;       IN      EDX             dest x + y << 16
;       IN      ESI             width + height << 16
;       IN      ES:EDI  1-bit mask
DrawMask      MACRO
        UserGate draw_mask_nr
                                                ENDM

;       IN      BX              Bitmap handle or 0
;       IN      CX              x1
;       IN      DX              y1
;       IN  SI          x2
;       IN  DI          y2
DrawLine      MACRO
        UserGate draw_line_nr
                                                ENDM

;       IN  AX                  Font handle
;       IN  BX                  Bitmap handle or 0
SetFont      MACRO
        UserGate set_font_nr
                                                ENDM

;       IN  CX                  x position
;       IN  DX                  y position
;       IN  ES:(E)DI    String to draw
DrawString      MACRO
        UserGate draw_string_nr
                                                ENDM

;       IN      BX              Bitmap handle or 0
;       IN      CX              x
;       IN      DX              y
;       IN  SI          width
;       IN  DI          height
DrawRect      MACRO
        UserGate draw_rect_nr
                                                ENDM

;       IN      BX              Bitmap handle or 0
;       IN      CX              x
;       IN      DX              y
;       IN  SI          width
;       IN  DI          height
DrawEllipse      MACRO
        UserGate draw_ellipse_nr
                                                ENDM

;       IN  AX          Bits per pixel
;       IN  CX          Width
;       IN  DX          Height
;       OUT BX          Bitmap handle
CreateBitmap      MACRO
        UserGate create_bitmap_nr
                                                ENDM

;       IN  CX          Width
;       IN  DX          Height
;       OUT BX          Bitmap handle
CreateAlphaBitmap      MACRO
        UserGate create_alpha_bitmap_nr
                                                ENDM

;       IN  BX          Bitmap handle
;       OUT BX          Mask bitmap handle
ExtractValidBitmapMask      MACRO
        UserGate extract_valid_bitmap_mask_nr
                                                ENDM

;       IN  BX          Bitmap handle
;       OUT BX          Mask bitmap handle
ExtractInvalidBitmapMask      MACRO
        UserGate extract_invalid_bitmap_mask_nr
                                                ENDM

;       IN  BX          Bitmap handle
;       OUT BX          Mask bitmap handle
ExtractAlphaBitmap      MACRO
        UserGate extract_alpha_bitmap_nr
                                                ENDM

;       IN  BX          Bitmap handle
;       OUT BX          Duplicated bitmap handle
DuplicateBitmapHandle      MACRO
        UserGate dup_bitmap_handle_nr
                                                ENDM

;       IN  BX          Bitmap handle
CloseBitmap      MACRO
        UserGate close_bitmap_nr
                                                ENDM

;       IN  ES:E(DI)    String
;       IN  BX                  Font handle
;       OUT     BX                      Bitmap handle
CreateStringBitmap      MACRO
        UserGate create_string_bitmap_nr
                                                ENDM

;       IN  BX                  Bitmap handle
;       OUT     AL                      Bits / pixel
;       OUT CX                  Width
;       OUT DX                  Height
;       OUT     SI                      Line size in bytes
;       OUT ES:EDI              Buffer address
GetBitmapInfo      MACRO
        UserGate get_bitmap_info_nr
                                                ENDM

;   IN  AX      LGOP
;   IN  BX      Dest bitmap handle or 0
;       IN  CX          Main bitmap
;       IN  DX          Mask (1-bit bitmap)
;       OUT BX          Sprite handle
CreateSprite      MACRO
        UserGate create_sprite_nr
                                                ENDM

;       IN  BX          Sprite handle
CloseSprite      MACRO
        UserGate close_sprite_nr
                                                ENDM

;       IN  BX          Sprite handle
ShowSprite      MACRO
        UserGate show_sprite_nr
                                                ENDM

;       IN  BX          Sprite handle
HideSprite      MACRO
        UserGate hide_sprite_nr
                                                ENDM

;       IN  BX          Sprite handle
;   IN  CX      x
;   IN  DX      y
MoveSprite      MACRO
        UserGate move_sprite_nr
                                                ENDM


;   IN  AL      Test mode
;   IN  AH      Speed (0 = 750MHz, 1 = 600MHz)
;   IN  ECX     Number of 2M buffer pages
SetupAdc      MACRO
        UserGate setup_adc_nr
                                                ENDM
                                                

;   OUT AL      IRQ bits
StartAdc      MACRO
        UserGate start_adc_nr
                                                ENDM


StopAdc      MACRO
        UserGate stop_adc_nr
                                                ENDM


; IN  EAX     Phase increment (0..3FFFF)
; IN  CL      Window bits    
SetAdcTrigger     MACRO
        UserGate set_adc_trigger_nr
                                                ENDM

; IN  EBX     Device
; IN  EDX     Channel
; IN  EAX     Frequency i Hz
; IN  ECX     Periods
; OUT EAX     Samples used in analysis
ConfigAdcChannel      MACRO
        UserGate config_adc_chan_nr
                                                ENDM

; IN  EBX     Device
; IN  EAX     Min amplitude
SetAdcAmpLimit      MACRO
        UserGate set_adc_amp_limit_nr
                                                ENDM

; IN  EBX     Device
; IN  EAX     Max phase divergence
SetAdcPhaseLimit      MACRO
        UserGate set_adc_phase_limit_nr
                                                ENDM

; IN  EBX     Device
; IN  EAX     Min channels
SetAdcChannels      MACRO
        UserGate set_adc_channels_nr
                                                ENDM

; IN  EBX     Device
StartAdcFreq      MACRO
        UserGate start_adc_freq_nr
                                                ENDM

; IN  EBX     Device
; OUT EDI     2k buffer
ReadAdcFreq      MACRO
        UserGate read_adc_freq_nr
                                                ENDM

;   IN  DH          Device #
;   OUT AL          State
ReadSerialLines      MACRO
        UserGate read_serial_lines_nr
                                                ENDM

;       IN  DH          Device #
;       IN  DL          Line #
ToggleSerialLine      MACRO
        UserGate toggle_serial_line_nr
                                                ENDM

;       IN  DH          Device #
;       IN  DL          Line #
ResetSerialLine      MACRO
        UserGate reset_serial_line_nr
                                                ENDM

;       IN  DH          Device #
;       IN  DL          Line #
SetSerialLine      MACRO
        UserGate set_serial_line_nr
                                                ENDM


;       IN  DH          Device #
;       IN      DL              Line #
;       OUT EAX         Value
ReadSerialVal      MACRO
        UserGate read_serial_val_nr
                                                ENDM

;       IN  DH          Device #
;       IN  DL          Line #
;       IN  EAX         Value
WriteSerialVal      MACRO
        UserGate write_serial_val_nr
                                                ENDM

EnableStatusLED      MACRO
        UserGate enable_status_led_nr
                                                ENDM

DisableStatusLED      MACRO
        UserGate disable_status_led_nr
                                                ENDM

;   IN  EAX     Timeout in milli seconds
StartWatchdog      MACRO
        UserGate start_watchdog_nr
                                                ENDM

KickWatchdog      MACRO
        UserGate kick_watchdog_nr
                                                ENDM

StopWatchdog      MACRO
        UserGate stop_watchdog_nr
                                                ENDM

;   OUT EAX     Maximum tics between kicks. If 0, watchdog not running.
GetWatchdogTics      MACRO
        UserGate get_watchdog_tics_nr
                                                ENDM

;   IN  EAX     Timeout in milli seconds
StartDebugger      MACRO
        UserGate start_debugger_nr
                                                ENDM

StopDebugger      MACRO
        UserGate stop_debugger_nr
                                                ENDM

KickDebugger      MACRO
        UserGate kick_debugger_nr
                                                ENDM
                                                
;       IN  EBX         File handle
StartNetCapture      MACRO
        UserGate start_net_capture_nr
                                                ENDM
                                                
StopNetCapture      MACRO
        UserGate stop_net_capture_nr
                                                ENDM
                                                
;       IN  EBX          File handle
StartCanCapture      MACRO
        UserGate start_can_capture_nr
                                                ENDM
                                                
StopCanCapture      MACRO
        UserGate stop_can_capture_nr
                                                ENDM
                                                
;       IN  EBX          File handle
StarLonCapture      MACRO
        UserGate start_lon_capture_nr
                                                ENDM
                                                
StopLonCapture      MACRO
        UserGate stop_lon_capture_nr
                                                ENDM

;   IN  AX          CRC polynom
;   OUT BX          CRC handle
CreateCrc      MACRO
        UserGate create_crc_nr
                                                ENDM

;   IN  BX          CRC handle
CloseCrc      MACRO
        UserGate close_crc_nr
                                                ENDM

;   IN  BX          CRC handle
;   IN  AX          CRC value
;   IN  ES:(E)DI    Data
;   IN  (E)CX       Size
;   OUT AX          CRC value
CalcCrc      MACRO
        UserGate calc_crc_nr
                                                ENDM

;   IN  EAX         CRC value
;   IN  ES:(E)DI    Data
;   IN  (E)CX       Size
;   OUT EAX         CRC value
CalcCrc32      MACRO
        UserGate calc_crc32_nr
                                                ENDM

;   IN  BX          Controller #
;   IN  AL          Port #
;   OUT BX          Handle
OpenUsbDevice      MACRO
        UserGate open_usb_dev_nr
                                                ENDM

;   IN  BX          Handle
CloseUsbDevice      MACRO
        UserGate close_usb_dev_nr
                                                ENDM

;   IN  BX          Handle
IsUsbDeviceConnected      MACRO
        UserGate is_usb_dev_connected_nr
                                                ENDM

;   IN  BX          Handle
ResetUsbDevice      MACRO
        UserGate reset_usb_dev_nr
                                                ENDM

;   IN  BX          Handle
;   IN  AL          Msg
;   IN  AH          Type
;   IN  DX          Value
;   IN  SI          Index
;   IN  CX          Size
;   IN  ES:(E)DI    Buffer
SendUsbDeviceControlMsg      MACRO
        UserGate send_usb_dev_control_msg_nr
                                                ENDM

;   IN  BX          Device handle
;   IN  DL          Pipe #
;   IN  CX          Buffered packet count
OpenUsbPacketPipe      MACRO
        UserGate open_usb_packet_pipe_nr
                                                ENDM

;   IN  BX          Device handle
;   IN  DL          Pipe #
;   IN  ES(E)DI     Packet buffer
;   OUT CX          Packet size
GetUsbPacketPipe      MACRO
        UserGate get_usb_packet_pipe_nr
                                                ENDM

;   IN  BX          Device handle
;   IN  DL          Pipe #
CloseUsbPipe      MACRO
        UserGate close_usb_pipe_nr
                                                ENDM

;   IN  BX          Device handle
;   IN  DL          Pipe #
;   OUT CX          Buffers
GetUsedUsbBuffers      MACRO
        UserGate get_used_usb_buffers_nr
                                                ENDM

;   IN  BX          Device handle
;   IN  DL          Pipe #
;   OUT CX          Buffers
GetFreeUsbBuffers      MACRO
        UserGate get_free_usb_buffers_nr
                                                ENDM

;   IN  BX          Device handle
;   IN  DL          Pipe #
;   OUT CX          Buffer size
GetUsbBufferSize      MACRO
        UserGate get_usb_buffer_size_nr
                                                ENDM

;   IN  BX          Device handle
;   IN  DL          Pipe #
;   IN  ES(E)DI     Buffer
;   IN  CX          Write size
WriteUsbPipe      MACRO
        UserGate write_usb_pipe_nr
                                                ENDM


;   IN  BX          Controller #
;   IN  AL          Port #
;   OUT AL          Address
GetUsbAddress      MACRO
        UserGate get_usb_address_nr
                                                ENDM

;   IN  BX          Controller #
;   IN  AL          Port #
;   IN  (E)CX       Buffer size
;   IN  ES:(E)DI    Buffer
;   OUT (E)AX       Size of descriptor
GetUsbDevice      MACRO
        UserGate get_usb_device_nr
                                                ENDM

;   IN  BX          Controller #
;   IN  AL          Port #
;   IN  DL          Config #
;   IN  (E)CX       Buffer size
;   IN  ES:(E)DI    Buffer
;   OUT (E)AX       Size of descriptor
GetUsbConfig      MACRO
        UserGate get_usb_config_nr
                                                ENDM

;   IN  BX          Controller #
;   IN  AL          Port #
;   IN  DL          Configuration id
ConfigUsbDevice      MACRO
        UserGate config_usb_device_nr
                                                ENDM

;   IN  CX          Max attaches
;   OUT BX          Handle
OpenUsbEvent      MACRO
        UserGate open_usb_event_nr
                                                ENDM

;   IN  BX          Handle
CloseUsbEvent      MACRO
        UserGate close_usb_event_nr
                                                ENDM

; IN  AX        Event handle
; IN  BX        Wait handle
; IN  ECX       Object ID
AddWaitForUsbEvent      MACRO
        UserGate add_wait_for_usb_event_nr
                                                ENDM

;   IN  BX          Handle
;   IN  ES:(E)DI    Event buffer
GetUsbEvent      MACRO
        UserGate get_usb_event_nr
                                                ENDM

;   OUT NC          Fatal error
HasUsbCardReaderError      MACRO
        UserGate has_usb_card_reader_error_nr
                                                ENDM

;   OUT NC          Has device RESET
HasUsbCardDevReset      MACRO
        UserGate has_usb_card_dev_reset_nr
                                                ENDM

;   OUT NC          Has USB RESET
HasUsbCardUsbReset      MACRO
        UserGate has_usb_card_usb_reset_nr
                                                ENDM
;;;;;;;;;;; ICSP (In-circuit serial programming) ;;;;;;;;;;

HasICSP      MACRO
        UserGate has_icsp_nr
                                                ENDM

;   IN  AL          Device #
;   OUT BX          Handle
OpenICSP      MACRO
        UserGate open_icsp_nr
                                                ENDM

;   IN  BX          Handle
CloseICSP      MACRO
        UserGate close_icsp_nr
                                                ENDM

;   IN BX          Handle
ResetICSP      MACRO
        UserGate reset_icsp_nr
                                                ENDM

;   IN  BX          Handle
;   IN  EAX         Command
WriteICSPCommand      MACRO
        UserGate write_icsp_cmd_nr
                                                ENDM

;   IN  BX          Handle
;   IN  EAX         Data
WriteICSPData      MACRO
        UserGate write_icsp_data_nr
                                                ENDM

;   IN  BX          Handle
;   OUT EAX         Data
ReadICSPData      MACRO
        UserGate read_icsp_data_nr
                                                ENDM

;;;;;;;;;;; Audio ;;;;;;;;;;

;   OUT NC          Audio hardware available
HasAudio      MACRO
        UserGate has_audio_nr
                                                ENDM

;   IN  AL          GPIO 0 value
SetCodecGpio0      MACRO
        UserGate set_codec_gpio0_nr
                                                ENDM

;   OUT EAX          Left
;   OUT EDX          Right
GetOutputVolume      MACRO
        UserGate get_output_volume_nr
                                                ENDM

;   IN  EAX         Left
;   IN  EDX         Right
SetOutputVolume      MACRO
        UserGate set_output_volume_nr
                                                ENDM

;   OUT AL          Left
;   OUT AH          Right
GetMasterVolume      MACRO
        UserGate get_master_volume_nr
                                                ENDM

;   IN  AL          Left
;   IN  AH          Right
SetMasterVolume      MACRO
        UserGate set_master_volume_nr
                                                ENDM

;   OUT AL          Left
;   OUT AH          Right
GetLineOutVolume      MACRO
        UserGate get_line_out_volume_nr
                                                ENDM

;   IN  AL          Left
;   IN  AH          Right
SetLineOutVolume      MACRO
        UserGate set_line_out_volume_nr
                                                ENDM

;   IN  AX          Sample rate
;   IN  CL          Bits
;   IN  DX          Volume
;   OUT BX          Handle
CreateAudioOutChannel      MACRO
        UserGate create_audio_out_channel_nr
                                                ENDM

;   IN  BX          Handle
CloseAudioOutChannel      MACRO
        UserGate close_audio_out_channel_nr
                                                ENDM

;   IN  BX          Handle
;   IN  ECX         Buffer size
;   IN  DS:ESI      Left channel data
;   IN  ES:EDI      Right channel data
WriteAudio      MACRO
        UserGate write_audio_nr
                                                ENDM

;   OUT ECX         Device count
GetAudioDeviceCount      MACRO
        UserGate get_audio_device_count_nr
                        ENDM

;   IN  EAX         Device #
;   OUT ECX         Device count
GetAudioCodecCount      MACRO
        UserGate get_audio_codec_count_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   IN  ES:(E)DI    Info buffer
;   OUT AL          Device type
GetAudioWidgetInfo      MACRO
        UserGate get_audio_widget_info_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   OUT DX          Vendor ID
;   OUT AX          Device ID
GetAudioCodecVersion      MACRO
        UserGate get_audio_codec_version_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   IN  ES:(E)DI    Connection list array
;   OUT ECX         Connection count
GetAudioWidgetConnectionList      MACRO
        UserGate get_audio_widget_connection_list_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   OUT EAX         Selected connection
GetSelectedAudioConnection      MACRO
        UserGate get_selected_audio_connection_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   OUT EAX         Min setting (1/4 db)
;   OUT EDX         Max setting (1/4 db)
GetAudioInputAmpCap      MACRO
        UserGate get_audio_input_amp_cap_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   OUT EAX         Min setting (1/4 db)
;   OUT EDX         Max setting (1/4 db)
GetAudioOutputAmpCap      MACRO
        UserGate get_audio_output_amp_cap_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   OUT NC          Supported
HasAudioInputMute      MACRO
        UserGate has_audio_input_mute_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   OUT NC          Supported
HasAudioOutputMute      MACRO
        UserGate has_audio_output_mute_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   IN  ECX         Channel
;   IN  EDX         Input
;   OUT EAX         Current setting
ReadAudioInputAmp      MACRO
        UserGate read_audio_input_amp_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   IN  ECX         Channel
;   OUT EAX         Current setting
ReadAudioOutputAmp      MACRO
        UserGate read_audio_output_amp_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   IN  ECX         Channel
;   IN  EDX         Input
;   OUT NC          Muted
IsAudioInputAmpMuted      MACRO
        UserGate is_audio_input_amp_muted_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Codec #
;   IN  EBX         Node #
;   IN  ECX         Channel
;   OUT NC          Muted
IsAudioOutputAmpMuted      MACRO
        UserGate is_audio_output_amp_muted_nr
                        ENDM

;   OUT EAX         Device #
;   OUT EDX         Codec #
;   OUT ECX         Node #
GetFixedAudioOutput      MACRO
        UserGate get_fixed_audio_output_nr
                        ENDM

;   IN  EBX         Jack #
;   OUT EAX         Device #
;   OUT EDX         Codec #
;   OUT ECX         Node #
GetJackAudioOutput      MACRO
        UserGate get_jack_audio_output_nr
                        ENDM

;   IN  EBX         Jack #
;   OUT EAX         Device #
;   OUT EDX         Codec #
;   OUT ECX         Node #
GetJackAudioInput      MACRO
        UserGate get_jack_audio_input_nr
                        ENDM

;;;;;;;;;;; FM synthesis ;;;;;;;;;;

;   IN  AX          Sample rate
;   OUT BX          FM handle
OpenFm      MACRO
        UserGate open_fm_nr
                        ENDM

;   IN  BX          FM handle
CloseFm      MACRO
        UserGate close_fm_nr
                        ENDM

;   IN  BX          FM handle
;   IN  EAX         Samples to wait
FmWait      MACRO
        UserGate fm_wait_nr
                        ENDM

;   IN  BX          FM handle
;   IN  AX:DX       C:M ratio
;   IN  ST0         Beta (modulation rate) 
;   OUT BX          Handle         
CreateFmInstrument      MACRO
        UserGate create_fm_instrument_nr
                        ENDM

;   IN  BX          Handle         
FreeFmInstrument      MACRO
        UserGate free_fm_instrument_nr
                        ENDM

;   IN  BX          Handle         
;   IN  EAX         Time in samples until full volume (attack)
SetFmAttack      MACRO
        UserGate set_fm_attack_nr
                        ENDM

;   IN  BX          Handle         
;   IN  EAX         Time in samples until volume is halved
;   IN  EDX         Time in samples until modulation index is halved
SetFmSustain      MACRO
        UserGate set_fm_sustain_nr
                        ENDM

;   IN  BX          Handle         
;   IN  EAX         Time in samples until volume is halved
;   IN  EDX         Time in samples until modulation index is halved
SetFmRelease      MACRO
        UserGate set_fm_release_nr
                        ENDM

;   IN  BX          Instrument handle         
;   IN  ECX         Duration of sustain in samples
;   IN  EAX         Peak left volume
;   IN  EDX         Peak right volume
;   IN  ST0         Frequency
PlayFmNote      MACRO
        UserGate play_fm_note_nr
                        ENDM


;;;;;;;;;;; syslog ;;;;;;;;;;

;   IN  SI          Severity (LSB), Facility (MSB)
;   IN  EDX:EAX     Time
;   IN  (E)CX       Msg size
;   IN  ES:(E)DI    Msg buf
AddSyslog      MACRO
        UserGate add_syslog_nr
                        ENDM

;   OUT BX          Handle 
OpenSyslog      MACRO
        UserGate open_syslog_nr
                        ENDM

;   IN  BX          Handle 
CloseSyslog      MACRO
        UserGate close_syslog_nr
                        ENDM

;   IN  BX          Handle 
;   IN  (E)CX       Buf size
;   IN  ES:(E)DI    Msg buf
;   OUT SI          Severity (LSB), Facility (MSB)
;   OUT EDX:EAX     Time
GetSyslog      MACRO
        UserGate get_syslog_nr
                        ENDM

;   IN  AX          Syslog handle 
;   IN  BX          Wait handle
;   IN  ECX         Signalled ID
AddWaitForSyslog      MACRO
        UserGate add_wait_for_syslog_nr
                        ENDM


;;;;;;;;;;; PCI ;;;;;;;;;;

;   IN  AH          Class
;   IN  AL          Sub class
;   IN  BX          Start 
;   OUT BX          Handle                   
FindPciClass      MACRO
        UserGate find_pci_class_nr
                        ENDM

;   IN  AH          Class
;   IN  AL          Sub class
;   IN  DL          Protocol
;   IN  BX          Start 
;   OUT BX          Handle                   
FindPciProtocol      MACRO
        UserGate find_pci_prot_nr
                        ENDM

;   IN  CX          Device
;   IN  DX          Vendor
;   IN  BX          Start
;   OUT BX          Handle                   
FindPciDevice        MACRO
        UserGate find_pci_device_nr
                        ENDM

;   IN  DH          Segment
;   IN  DL          Bus
;   IN  AH          Device
;   IN  AL          Function
;   OUT BX          Handle                   
GetPciHandle      MACRO
        UserGate get_pci_handle_nr
                        ENDM

;   IN  BX          Pci handle
;   IN  DS:E(SI)    ACPI name + config name
;   IN  ES:E(DI)    Buffer
;   IN  E(CX)       Max entries
;   OUT EAX         Entry count
EvalPciHandleIntArr      MACRO
        UserGate eval_pci_int_arr_nr
                        ENDM

;   IN  BX          Handle
;   OUT DH          Segment
;   OUT DL          Bus
;   OUT AH          Device
;   OUT AL          Function                   
GetPciParam      MACRO
        UserGate get_pci_param_nr
                        ENDM

;   IN  BX          Handle
;   IN  AX          Irq number
;   OUT AL          IRQ                   
GetPciIrq      MACRO
        UserGate get_pci_irq_nr
                        ENDM

;   IN  BX          Handle
;   OUT AL          Number of vectors                   
GetPciMsiIrqs      MACRO
        UserGate get_pci_msi_irqs_nr
                        ENDM

;   IN  BX          Handle
;   OUT AL          Number of vectors                   
GetPciMsiXIrqs      MACRO
        UserGate get_pci_msix_irqs_nr
                        ENDM

;   IN  BX          Handle
;   IN  AL          Capability
;   OUT AX          Register                  
GetPciCapability      MACRO
        UserGate get_pci_cap_nr
                        ENDM
                        
;   IN  BX          Handle
;   IN  CX          Register
;   OUT AL          Value                  
ReadPciConfigByte      MACRO
        UserGate read_pci_config_byte_nr
                        ENDM

;   IN  BX          Handle
;   IN  CX          Register
;   OUT AX          Value                  
ReadPciConfigWord      MACRO
        UserGate read_pci_config_word_nr
                        ENDM

;   IN  BX          Handle
;   IN  CX          Register
;   OUT EAX         Value                  
ReadPciConfigDword      MACRO
        UserGate read_pci_config_dword_nr
                        ENDM

;   IN  AL          Value                  
;   IN  BX          Handle
;   IN  CX          Register
WritePciConfigByte      MACRO
        UserGate write_pci_config_byte_nr
                        ENDM

;   IN  AX          Value                  
;   IN  BX          Handle
;   IN  CX          Register
WritePciConfigWord      MACRO
        UserGate write_pci_config_word_nr
                        ENDM

;   IN  EAX         Value                  
;   IN  BX          Handle
;   IN  CX          Register
WritePciConfigDword      MACRO
        UserGate write_pci_config_dword_nr
                        ENDM

;   IN  BX          Handle
;   IN  ES:EDI      Name
LockPci      MACRO
        UserGate lock_pci_nr
                        ENDM

;   IN  BX          Handle
UnlockPci      MACRO
        UserGate unlock_pci_nr
                        ENDM

;   IN  BX          Handle
IsPciLocked      MACRO
        UserGate is_pci_locked_nr
                        ENDM

;   IN  DH          Segment
;   IN  DL          Bus
;   OUT DL          Bus #
;   OUT AH          Device #
;   OUT AL          Function #
GetPciBus      MACRO
        UserGate get_pci_bus_nr
                        ENDM


;   IN  BX          Handle
;   IN  ES:E(DI)    ACPI name buffer
GetPciDeviceName      MACRO
        UserGate get_pci_device_name_nr
                        ENDM

;;;;;;;;;;; ACPI ;;;;;;;;;;

;   OUT EAX         ACPI status
GetAcpiStatus      MACRO
        UserGate get_acpi_status_nr
                        ENDM

;   IN  EAX         Object #
;   IN  ES:(E)DI    ACPI name buffer
GetAcpiObject      MACRO
        UserGate get_acpi_object_nr
                        ENDM

;   IN  EAX         Object #
;   IN  EDX         Method #
;   IN  ES:(E)DI    ACPI name buffer
GetAcpiMethod      MACRO
        UserGate get_acpi_method_nr
                        ENDM

;   IN  EAX         Device #
;   IN  ES:(E)DI    ACPI name buffer
GetAcpiDevice      MACRO
        UserGate get_acpi_device_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         IRQ #
;   OUT AL          Global IRQ #
;   OUT AH          Sharable (0, 1)
;   OUT DL          Polarity (-1, +1)
;   OUT DH          Trigger mode (0 = level, 1 = edge)
GetAcpiDeviceIrq      MACRO
        UserGate get_acpi_device_irq_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         IO #
;   OUT SI          Start port
;   OUT DI          End port
;   OUT CX          Address len
GetAcpiDeviceIo      MACRO
        UserGate get_acpi_device_io_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         IO #
;   OUT ESI         Start address
;   OUT EDI         End address
;   OUT ECX          Address len
GetAcpiDeviceMem      MACRO
        UserGate get_acpi_device_mem_nr
                        ENDM

;   OUT EAX         Temperature in tenth of degrees Kelvin
GetCpuTemperature      MACRO
        UserGate get_cpu_temperature_nr
                        ENDM

;;;;;;;;;;; HID ;;;;;;;;;;

;   IN  EAX         Device #
;   OUT BX          USB controller
;   OUT AX          USB device
GetHidDevice      MACRO
        UserGate get_hid_device_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EDX         Item #
;   IN  ES:(E)DI    HID item buffer
GetHidReportItem      MACRO
        UserGate get_hid_report_item_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EBX         Report #
;   IN  EDX         Entry #
;   IN  ES:(E)DI    HID data buffer
GetHidReportInputData      MACRO
        UserGate get_hid_report_input_data_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EBX         Report #
;   IN  EDX         Entry #
;   IN  ES:(E)DI    HID data buffer
GetHidReportOutputData      MACRO
        UserGate get_hid_report_output_data_nr
                        ENDM

;   IN  EAX         Device #
;   IN  EBX         Report #
;   IN  EDX         Entry #
;   IN  ES:(E)DI    HID data buffer
GetHidReportFeatureData      MACRO
        UserGate get_hid_report_feature_data_nr
                        ENDM

;;;;;;;;;;; Touch ;;;;;;;;;;

;   OUT NC          Touch hardware available
HasTouch      MACRO
        UserGate has_touch_nr
                                                ENDM

ResetTouchCalibrate      MACRO
        UserGate reset_touch_calibrate_nr
                                                ENDM

;  IN  EDX          Dividend
SetTouchCalibrateDividend      MACRO
        UserGate set_touch_calibrate_dividend_nr
                                                ENDM

;  IN  EDX          x offset
;  IN  ESI          xx factor
;  IN  EDI          xy factor
SetTouchCalibrateX      MACRO
        UserGate set_touch_calibrate_x_nr
                                                ENDM

;  IN  EDX          y offset
;  IN  ESI          yx factor
;  IN  EDI          yy factor
SetTouchCalibrateY      MACRO
        UserGate set_touch_calibrate_y_nr
                                                ENDM

;;;;;;;;;;; Can modules ;;;;;;;;;;

IsCanOnline      MACRO
        UserGate is_can_online_nr
                                                ENDM

;   OUT BX      Bitmap handle
CreateCanModuleBitmap       MACRO
        UserGate create_can_module_bitmap_nr
                                                ENDM

;   IN  EAX         Device #
;   OUT CX          Number of com ports
;   OUT DX          Module type
GetCanModuleInfo      MACRO
        UserGate get_can_module_info_nr
                                                ENDM

;       IN  AL              Serial port #
;   OUT EAX         Can module
;   OUT EDX         Can port
CheckCanSerialPort      MACRO
        UserGate check_can_serial_port_nr
                                                ENDM

;   IN  EAX         Device #
;   OUT AL          Minor version
;   OUT AH          Major version
;   OUT DL          Sub version
GetCanModuleVersion      MACRO
        UserGate get_can_module_version_nr
                                                ENDM

;   IN  EAX         Device #
;   OUT AL          Minor version
;   OUT AH          Major version
;   OUT DL          Sub version
GetCanLoaderVersion      MACRO
        UserGate get_can_loader_version_nr
                                                ENDM

;   IN  EAX         Device #
;   IN  ES:(E)DI    Buffer
GetCanSerialNumber      MACRO
        UserGate get_can_serial_number_nr
                                                ENDM

;   IN  EAX         Device #
;   OUT ECX         Restart count
GetCanModuleRestarts      MACRO
        UserGate get_can_module_restarts_nr
                                                ENDM

;   IN  EAX         Device #
;   IN  ES:(E)DI    Program file
ProgramCanModule      MACRO
        UserGate program_can_module_nr
                                                ENDM

;   IN  EAX         Device #
;   OUT AX          Result (0 = ok)
;   OUT DX          Error code
;   OUT ECX         Position 
WaitForCanModuleProgramming      MACRO
        UserGate wait_for_can_module_progamming_nr
                                                ENDM

;   IN  EAX         Device #
;   OUT NC          Online
IsCanModuleOnline      MACRO
        UserGate is_can_module_online_nr
                                                ENDM

;   OUT AL          Minor version
;   OUT AH          Major version
;   OUT DL          Sub version
GetCanBridgeVersion      MACRO
        UserGate get_can_bridge_version_nr
                                                ENDM

;   IN  ES:(E)DI    Program file
ProgramCanBridge      MACRO
        UserGate program_can_bridge_nr
                                                ENDM

;   OUT AX          Result (0 = ok)
;   OUT DX          Error code
;   OUT ECX         Position 
WaitForCanBridgeProgramming      MACRO
        UserGate wait_for_can_bridge_progamming_nr
                                                ENDM

;;;;;;;;;;; Big numbers ;;;;;;;;;;

; OUT BX            Bignum handle
CreateBigNum    MACRO
        UserGate create_bignum_nr
                ENDM

; IN  BX            Bignum handle
DeleteBigNum    MACRO
        UserGate delete_bignum_nr
                ENDM

; IN  BX            Bignum handle 1
; IN  AX            Bignum handle 2
; OUT BX            Result bignum handle
AddBigNum       MACRO
        UserGate add_bignum_nr
                ENDM

; IN  BX            Bignum handle 1
; IN  AX            Bignum handle 2
; OUT BX            Result bignum handle
SubBigNum       MACRO
        UserGate sub_bignum_nr
                ENDM

; IN  BX            Bignum handle 1
; IN  AX            Bignum handle 2
; OUT BX            Result bignum handle
MulBigNum       MACRO
        UserGate mul_bignum_nr
                ENDM

; IN  BX            Bignum handle 1
; IN  AX            Bignum handle 2
; OUT BX            Result bignum handle
DivBigNum       MACRO
        UserGate div_bignum_nr
                ENDM

; IN  BX            Bignum handle 1
; IN  AX            Bignum handle 2
; OUT BX            Result bignum handle
ModBigNum       MACRO
        UserGate mod_bignum_nr
                ENDM

; IN  BX            Base handle
; IN  AX            Exp handle
; IN  DX            Mod handle
; OUT BX            Result bignum handle
PowModBigNum    MACRO
        UserGate pow_mod_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      Buffer
; IN  ECX           Size
LoadSignedBigNum        MACRO
        UserGate load_signed_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      Buffer
; IN  ECX           Size
LoadUnsignedBigNum      MACRO
        UserGate load_unsigned_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      Buffer
; IN  ECX           Size
SaveSignedBigNum        MACRO
        UserGate save_signed_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      Buffer
; IN  ECX           Size
SaveUnsignedBigNum      MACRO
        UserGate save_unsigned_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      String
LoadDecStrBigNum        MACRO
        UserGate load_dec_str_bignum_nr
                ENDM

; IN  BX            Bignum handle
; OUT ECX           Bytes required for base 10 buffer
GetDecStrSizeBigNum     MACRO
        UserGate get_dec_str_size_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  (E)CX         Buffer size
; IN  ES:(E)DI      Buffer
SaveDecStrBigNum        MACRO
        UserGate save_dec_str_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      String
LoadHexStrBigNum        MACRO
        UserGate load_hex_str_bignum_nr
                ENDM

; IN  BX            Bignum handle
; OUT ECX           Bytes required for base 16 buffer
GetHexStrSizeBigNum     MACRO
        UserGate get_hex_str_size_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  (E)CX         Buffer size
; IN  ES:(E)DI      Buffer
SaveHexStrBigNum        MACRO
        UserGate save_hex_str_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      Buffer
; IN  ECX           Size
AddSignedBigNum MACRO
        UserGate add_signed_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      Buffer
; IN  ECX           Size
AddUnsignedBigNum       MACRO
        UserGate add_unsigned_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      Buffer
; IN  ECX           Size
SubSignedBigNum MACRO
        UserGate sub_signed_bignum_nr
                ENDM

; IN  BX            Bignum handle
; IN  ES:(E)DI      Buffer
; IN  ECX           Size
SubUnsignedBigNum       MACRO
        UserGate sub_unsigned_bignum_nr
                ENDM


; IN  ECX           Number of bits
; OUT BX            Bignum handle
CreateRandomBigNum      MACRO
        UserGate create_random_bignum_nr
                ENDM

; IN  ECX           Number of bits
; OUT BX            Bignum handle
CreateRandomOddBigNum   MACRO
        UserGate create_random_odd_bignum_nr
                ENDM


; IN  BX            Bignum handle to factor
; OUT BX            Bignum handle remainder
; OUT ECX           Exponent
FactorPow2BigNum        MACRO
        UserGate factor_pow2_bignum_nr
                ENDM

;;;;;;;;;;; AC ;;;;;;;;;;

WaitAcMeassure    MACRO
        UserGate wait_ac_meassure_nr
                ENDM

; IN  BL             Phase (1-3)
; OUT EAX            Voltage (mV)
GetAcVoltage    MACRO
        UserGate get_ac_voltage_nr
                ENDM

; IN  BL             Phase (1-3)
; OUT EAX            Current (mA)
GetAcCurrent    MACRO
        UserGate get_ac_current_nr
                ENDM

; IN  BL             Phase (0 = sum, 1-3)
; OUT EAX            Power (0.1W)
GetAcConsumePower    MACRO
        UserGate get_ac_consume_power_nr
                ENDM

; IN  BL             Phase (0 = sum, 1-3)
; OUT EAX            Power (0.1W)
GetAcProducePower    MACRO
        UserGate get_ac_produce_power_nr
                ENDM

; IN  BL             Phase (0 = sum, 1-3)
; OUT EDX:EAX        Energy (Ws)
GetAcConsumeEnergy    MACRO
        UserGate get_ac_consume_energy_nr
                ENDM

; IN  BL             Phase (0 = sum, 1-3)
; OUT EDX:EAX        Energy (Ws)
GetAcProduceEnergy    MACRO
        UserGate get_ac_produce_energy_nr
                ENDM

;;;;;;;;;;; Realtime ;;;;;;;;;;

; OUT BX            Realtime handle
CreateRealtime    MACRO
        UserGate create_realtime_nr
                ENDM

; IN  BX            Realtime handle
; IN  ES:(E)DI      Realtime 64-bit executable
; OUT AX            Core #
AddRealtimeCore    MACRO
        UserGate add_realtime_core_nr
                ENDM

; IN  BX            Realtime handle
WaitForRealtimeSignal    MACRO
        UserGate wait_for_realtime_signal_nr
                ENDM

; IN  BX            Realtime handle
; OUT AX            Core #
; OUT CX            Signal #
GetRealtimeSignal    MACRO
        UserGate get_realtime_signal_nr
                ENDM

; IN  BX            Realtime handle
; IN  EDX:EAX       Size
; OUT AX            Realtime buffer handle
AllocateRealtimeBuffer    MACRO
        UserGate allocate_realtime_buf_nr
                ENDM

; IN  BX            Realtime buffer handle
; IN  EDX:EAX       Offset
; IN  ECX           Size
; OUT ES:EDI        Mapped location   
MapRealtimeBuffer    MACRO
        UserGate map_realtime_buf_nr
                ENDM

; IN  BX            Realtime buffer handle
UnmapRealtimeBuffer    MACRO
        UserGate unmap_realtime_buf_nr
                ENDM


; IN  AL            IRQ #
WaitAnio    MACRO
        UserGate wait_anio_nr
                ENDM
