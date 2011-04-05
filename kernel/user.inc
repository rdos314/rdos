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
; Segment transfer flags bits
;

virt_ds_in		EQU 1
virt_es_in		EQU 2
virt_fs_in		EQU 4
virt_gs_in		EQU 8
;
virt_ds_out		EQU 10h
virt_es_out		EQU 20h
virt_fs_out		EQU 40h
virt_gs_out		EQU 80h
;
virt_seg_in		EQU 0Fh
virt_seg_out	EQU 0F0h

gate16_override	EQU 100h
gate32_override	EQU 200h

OldUserGate16	MACRO gate_nr
    db 66h
    db 9Ah
    dd gate_nr
    dw 1
    db 90h
    db 90h
			ENDM

OldUserGate32	MACRO gate_nr
    db 9Ah
    dd gate_nr
    dw 2
    db 90h
    db 90h
    db 90h
			ENDM

OldUserGateForce32 MACRO gate_nr
    db 66h
    db 9Ah
    dd gate_nr
    dw 2
    db 90h
    db 90h
			ENDM

OldUserGate        MACRO gate_nr
IF (size $) EQ 0FF02h
    OldUserGate16 gate_nr
ELSE
	OldUserGate32 gate_nr
ENDIF
			ENDM

NewUserGate16	MACRO gate_nr
    db 67h
    db 66h
    db 9Ah
    dd gate_nr
    dw 1
			ENDM

NewOldUserGate32	MACRO gate_nr
    db 3Eh
    db 67h
    db 9Ah
    dd gate_nr
    dw 1
			ENDM

NewOldUserGate        MACRO gate_nr
IF (size $) EQ 0FF02h
    NewOldUserGate16 gate_nr
ELSE
	NewOldUserGate32 gate_nr
ENDIF
			ENDM
			

;   NC      Valid
IsValidOldUserGate	MACRO
	OldUserGate is_valid_OldUserGate_nr
				ENDM

;;;;;;;;;;;;;; MEMORY ;;;;;;;;;;;;;;;;;;;

;	EAX		Number of free physical bytes
GetFreePhysical	MACRO
	OldUserGate get_free_physical_nr
				ENDM

;	AX		Number of free GDT entries
GetFreeGdt	MACRO
	OldUserGate get_free_gdt_nr
				ENDM

;	EAX	    Number of free bytes
AvailableBigLinear	MACRO
	OldUserGate available_big_linear_nr
					ENDM

;	EAX		Number of free bytes
AvailableSmallLinear	MACRO
	OldUserGate available_small_linear_nr
					ENDM

; IN  EAX     Number of bytes
; OUT ES      Selector
AllocateDosMem  MACRO
	OldUserGate allocate_dos_mem_nr
						ENDM

; IN  EAX     Number of bytes
; OUT ES      Selector
AllocateLocalMem        MACRO
	OldUserGate allocate_local_mem_nr
						ENDM

; IN  ES      Selector
FreeMem MACRO
	OldUserGate free_mem_nr
						ENDM

; OUT EAX     Number of bytes
AvailableLocalLinear    MACRO
	OldUserGate available_local_linear_nr
						ENDM

; OUT EAX     Number of bytes
UsedLocalLinear MACRO
	OldUserGate used_local_linear_nr
						ENDM

; OUT EAX     Number of bytes
AvailableVMLinear       MACRO
	OldUserGate available_vm_linear_nr
						ENDM

; OUT EAX     Number of bytes
UsedVMLinear    MACRO
	OldUserGate used_vm_linear_nr
						ENDM

; OUT AX      Number of free handles
GetFreeHandles MACRO
	OldUserGate get_free_handles_nr
						ENDM

; OUT EAX     Amount of free handle memory
GetFreeHandleMem MACRO
	OldUserGate get_free_handle_mem_nr
						ENDM

;;;;;;;;;;; PAGING ;;;;;;;;;;;;;;

FreeV86	MACRO
	OldUserGate free_v86_nr
					ENDM

; IN  EAX     	Size
; IN  BX		Owner
; IN  EDX      	Flat offset
ReservePeMem MACRO
	OldUserGate reserve_pe_mem_nr
						ENDM

; IN  EAX		New size
; IN  ECX		Old size
; IN  EDX		Flat offset
; OUT EDX		Flat offset
ResizeFlatLinear	MACRO
	OldUserGate resize_flat_linear_nr
					ENDM

; IN  EAX		Number of bytes
; IN  EDX		Flat offset
SetFlatLinearValid	MACRO
	OldUserGate set_flat_linear_valid_nr
					ENDM

; IN  EAX		Number of bytes
; IN  EDX		Flat offset
SetFlatLinearInvalid	MACRO
	OldUserGate set_flat_linear_invalid_nr
					ENDM

; IN  EAX		Number of bytes
; IN  EDX		Flat offset
SetFlatLinearRead	MACRO
	OldUserGate set_flat_linear_read_nr
					ENDM

; IN  EAX		Number of bytes
;	EDX			Flat offset
SetFlatLinearReadWrite	MACRO
	OldUserGate set_flat_linear_readwrite_nr
					ENDM

;;;;;;;;;;;; INTERRUPT & EXCEPTION ;;;;;;;;;;;

; OUT BX:CX		V86 address to use to switch to Prot mode
; OUT SI:(E)DI	Prot mode address to use to switch to V86.
GetRawSwitchAds	MACRO
	OldUserGate get_raw_switch_ads_nr
					ENDM

; IN  AX		New DS
; IN  CX		New ES
; IN  DX		New SS
; IN  (E)BX		New (E)SP
; IN  SI		New CS
; IN  (E)DI		New (E)IP
RawSwitch       MACRO
	OldUserGate raw_switch_nr
						ENDM

; IN  AL        Exception #
; OUT ES:(E)DI  Exception vector
GetException      MACRO
	OldUserGate get_exception_nr
						ENDM

; IN  AL        Exception #
; IN  ES:(E)DI  Exception vector
SetException      MACRO
	OldUserGate set_exception_nr
						ENDM

; IN  AL        Int #
; OUT ES:(E)DI	Int vector
GetPMInt    MACRO
	OldUserGate get_pm_int_nr
						ENDM

; IN  AL        Int #
; IN  ES:(E)DI  Int vector
SetPMInt    MACRO
	OldUserGate set_pm_int_nr
						ENDM

; IN  AL		Int #
; OUT DX:BX		Int vector
GetVMInt	MACRO
	OldUserGate get_vm_int_nr
					ENDM

; IN  AL		Int #
; IN  DX:BX		Int vector
SetVMInt	MACRO
	OldUserGate set_vm_int_nr
					ENDM

; IN  AL         Int #
; IN  CX         Words to copy on stack
; IN  DS:(E)SI   Parameters
; IN  ES:(E)DI   VM_CALL_STRUC
DpmiInt   MACRO
	OldUserGate dpmi_int_nr
					ENDM

; IN  CX         Words to copy on stack
; IN  DS:(E)SI   Parameters
; IN  ES:(E)DI   VM_CALL_STRUC
DpmiCallInt       MACRO
	OldUserGate dpmi_call_int_nr
					ENDM

; IN  CX          Words to copy on stack
; IN  DS:(E)SI    Parameters
; IN  ES:(E)DI    VM_CALL_STRUC
DpmiCall  MACRO
	OldUserGate dpmi_call_nr
					ENDM

; IN  DS:(E)SI    Callback procedure
; IN  ES:(E)DI    VM_CALL_STRUC
; OUT DX:AX       V86 address to call
AllocateVMCallback      MACRO
	OldUserGate allocate_vm_callback_nr
					ENDM

; IN  DX:AX       V86 address to call
FreeVMCallback  MACRO
	OldUserGate free_vm_callback_nr
					ENDM

;;;;;;;;;;;;;; MULTITASKING ;;;;;;;;;;;;

;  OUT AX       0 = power ok
;               1 = power failure
PowerFailure        MACRO
	OldUserGate power_failure_nr
						ENDM

CpuReset        MACRO
	OldUserGate cpu_reset_nr
						ENDM

; OUT AX         Processor nr
GetProcessorId        MACRO
	OldUserGate get_processor_id_nr
						ENDM

; IN  AX         Number of milliseconds
WaitMilliSec        MACRO
	OldUserGate wait_milli_nr
						ENDM

; IN  AX         Number of microseconds
WaitMicroSec        MACRO
	OldUserGate wait_micro_nr
						ENDM

; IN  EDX:EAX    System time to wait until
WaitUntil       MACRO
	OldUserGate wait_until_nr
						ENDM

; IN  AL         Priority
; IN  AH         Mode, 0=PM, 1=VM
; IN  (E)CX      Stack size
; IN  DS:(E)SI   Start address
; IN  ES:(E)DI   Thread name
CreateThread   MACRO
	OldUserGate create_thread_nr
						ENDM

TerminateThread        MACRO
	OldUserGate terminate_thread_nr
						ENDM

; OUT AX		Thread handle
GetThread	MACRO
	OldUserGate get_thread_nr
					ENDM

Swap       MACRO
	OldUserGate swap_nr
						ENDM

;;;;;;;;; CRITICAL SECTIONS ;;;;;;;;;;;;

; OUT BX		Section handle
CreateUserSection	MACRO
	OldUserGate create_user_section_nr
					ENDM

; OUT BX		Section handle
CreateBlockedUserSection	MACRO
	OldUserGate create_blocked_user_section_nr
					ENDM

; IN  BX		Section handle
DeleteUserSection	MACRO
	OldUserGate delete_user_section_nr
					ENDM

; IN  BX		Section handle
EnterUserSection	MACRO
	OldUserGate enter_user_section_nr
					ENDM

; IN  BX		Section handle
LeaveUserSection	MACRO
	OldUserGate leave_user_section_nr
					ENDM

; OUT BX		Section handle
CreateUserReadWriteSection	MACRO
	OldUserGate create_user_read_write_section_nr
					ENDM

; IN  BX		Section handle
DeleteUserReadWriteSection	MACRO
	OldUserGate delete_user_read_write_section_nr
					ENDM

; IN  BX		Section handle
EnterUserReadSection	MACRO
	OldUserGate enter_user_read_section_nr
					ENDM

; IN  BX		Section handle
LeaveUserReadSection	MACRO
	OldUserGate leave_user_read_section_nr
					ENDM

; IN  BX		Section handle
EnterUserWriteSection	MACRO
	OldUserGate enter_user_write_section_nr
					ENDM

; IN  BX		Section handle
LeaveUserWriteSection	MACRO
	OldUserGate leave_user_write_section_nr
					ENDM

;;;;;;;;; WAITABLE OBJECTS ;;;;;;;;;;;;

; OUT BX		Wait handle
CreateWait	MACRO
	OldUserGate create_wait_nr
					ENDM

; IN  BX		Wait handle
; OUT ECX		Non-idle ID
IsWaitIdle	MACRO
	OldUserGate is_wait_idle_nr
					ENDM

; IN  BX		Wait handle
; OUT ECX		Signalled ID
WaitWithoutTimeout	MACRO
	OldUserGate wait_no_timeout_nr
					ENDM

; IN  BX		Wait handle
; IN  EDX:EAX	Timeout
; OUT ECX		Signalled ID
WaitWithTimeout	MACRO
	OldUserGate wait_timeout_nr
					ENDM

; IN  BX		Wait handle
StopWait	MACRO
	OldUserGate stop_wait_nr
					ENDM

; IN  BX		Wait handle
; IN  ECX       Object ID
RemoveWait	MACRO
	OldUserGate remove_wait_nr
					ENDM

; IN  BX		Wait handle
CloseWait	MACRO
	OldUserGate close_wait_nr
					ENDM

; IN  BX		Wait handle
; IN  ECX       Object ID
AddWaitForKeyboard       MACRO
	OldUserGate add_wait_for_keyboard_nr
						ENDM

; IN  BX		Wait handle
; IN  ECX       Object ID
AddWaitForMouse       MACRO
	OldUserGate add_wait_for_mouse_nr
						ENDM

; IN  AX        Com handle
; IN  BX		Wait handle
; IN  ECX       Object ID
AddWaitForCom       MACRO
	OldUserGate add_wait_for_com_nr
						ENDM

; IN  AX        Tcp connection handle
; IN  BX		Wait handle
; IN  ECX       Object ID
AddWaitForTcpConnection       MACRO
	OldUserGate add_wait_for_tcp_connection_nr
						ENDM

; IN  AX        Tcp listen handle
; IN  BX		Wait handle
; IN  ECX       Object ID
AddWaitForTcpListen       MACRO
	OldUserGate add_wait_for_tcp_listen_nr
						ENDM

; IN  AX        USB pipe handle
; IN  BX		Wait handle
; IN  ECX       Object ID
AddWaitForUsbPipe       MACRO
	OldUserGate add_wait_for_usb_pipe_nr
						ENDM

; IN  AX        ADC handle
; IN  BX		Wait handle
; IN  ECX       Object ID
AddWaitForAdc       MACRO
	OldUserGate add_wait_for_adc_nr
						ENDM

; OUT BX        Signal handle
CreateSignal       MACRO
	OldUserGate create_signal_nr
						ENDM

; IN  BX        Signal handle
SetSignal       MACRO
	OldUserGate set_signal_nr
						ENDM
						
; IN  BX        Signal handle
ResetSignal       MACRO
	OldUserGate reset_signal_nr
						ENDM
						
; IN  BX        Signal handle
IsSignalled       MACRO
	OldUserGate is_signalled_nr
						ENDM

; IN  BX        Signal handle
FreeSignal       MACRO
	OldUserGate free_signal_nr
						ENDM

; IN  AX        Signal handle
; IN  BX		Wait handle
; IN  ECX       Object ID
AddWaitForSignal       MACRO
	OldUserGate add_wait_for_signal_nr
						ENDM


;;;;;;;;;;; RANDOM NUMBERS ;;;;


;   OUT EAX         Random number
GetRandom   MACRO
    OldUserGate get_random_nr
            ENDM


;;;;;;;;;;; IPC ;;;;;;;;;;;;;;;

;	IN  ES:(E)DI	Mailslot name
;	OUT BX			Mailslot handle
GetLocalMailslot		MACRO
	OldUserGate get_local_mailslot_nr
			ENDM

;	IN  EDX			IP address
;	IN  ES:(E)DI	Mailslot name
;	OUT BX			Mailslot handle
GetRemoteMailslot		MACRO
	OldUserGate get_remote_mailslot_nr
			ENDM

;	IN  BX			Mailslot handle
FreeMailslot		MACRO
	OldUserGate free_mailslot_nr
			ENDM

;	IN  BX				Mailslot handle
;	IN  DS:(E)SI		Message buffer
;	IN  (E)CX			Message size
;	IN  ES:(E)DI		Reply buffer
;	IN  (E)AX			Max reply size
;	IN  EDX				Timeout in milliseconds
;	OUT (E)CX			Reply size
SendMailslot		MACRO
	OldUserGate send_mailslot_nr
			ENDM

;	IN  (E)CX			Max message size
;	IN  ES:(E)DI		Mailslot name
DefineMailslot		MACRO
	OldUserGate define_mailslot_nr
			ENDM

;	IN  ES:(E)DI		Message buffer
;	OUT (E)CX			Size
ReceiveMailslot		MACRO
	OldUserGate receive_mailslot_nr
			ENDM

;	IN  ES:(E)DI		Reply buffer
;	IN  (E)CX			Reply size
ReplyMailslot		MACRO
	OldUserGate reply_mailslot_nr
			ENDM

;;;;;;;;;;;; PROGRAMS & DLLS ;;;;;;;;;;;;;;;;

; IN  AL            Adapter # (0..n)
; IN  DL            Entry # (0..n)
; IN  ES:(E)DI      Header buffer
GetImageHeader	MACRO
	OldUserGate get_image_header_nr
					ENDM

; IN  AL            Adapter # (0..n)
; IN  DL            Entry # (0..n)
; IN  ES:(E)DI      Data buffer
GetImageData	MACRO
	OldUserGate get_image_data_nr
					ENDM

; IN  BX            Code selector
; IN  ES:(E)DI      Name buffer
; OUT BX            Data selector
; OUT EAX           Code limit
; OUT EDX           Data limit
GetDeviceInfo	MACRO
	OldUserGate get_device_info_nr
					ENDM

; IN  ES:(E)DI)     CPU vendor string
; OUT AL            CPU version
; OUT EBX           Frequency (MHz)
; OUT EDX           Feature flags
GetCpuVersion	MACRO
	OldUserGate get_cpu_version_nr
					ENDM

; OUT AX Minor version
; OUT DX Major version
; OUT CX Release #
GetVersion	MACRO
	OldUserGate get_version_nr
					ENDM

EmsHandler	MACRO
	OldUserGate ems_handler_nr
					ENDM

XmsHandler	MACRO
	OldUserGate xms_handler_nr
					ENDM

; IN  DS:(E)SI	Program name
; IN  ES:(E)DI	Command line
; IN  GS:(E)BX	Options
LoadExe	MACRO
	OldUserGate load_exe_nr
					ENDM

; IN  DS:(E)SI	Program name
; IN  ES:(E)DI	Command line
DosExtExec	MACRO
	OldUserGate dos_ext_exec_nr
					ENDM

; IN  DS:(E)SI	Program name
; IN  ES:(E)DI	Parameters
;               +0  Command line
;               +8  Startup directory & drive
;               +12 Environment
;               +16 Options
; IN  DX		Debug module handle
; OUT AX		Thread #
; OUT DX		Process handle
SpawnExe	MACRO
	OldUserGate spawn_exe_nr
					ENDM

; IN  DS:(E)SI	New process name
; IN  ES:(E)DI	Options
; OUT AX		Process handle (parent) or 0 (child)
Fork	MACRO
	OldUserGate fork_nr
					ENDM

; IN  AX		Exit code
UnloadExe	MACRO
	OldUserGate unload_exe_nr
					ENDM

;  IN  AX   Process handle
;  IN  BX	Wait handle
;  IN  ECX  Signalled ID
AddWaitForProcEnd MACRO
	OldUserGate add_wait_for_proc_end_nr
						ENDM

;  IN  BX   Process handle
;  OUT AX	Exit code
GetProcExitCode	MACRO
	OldUserGate get_proc_exit_code_nr
					ENDM

; IN  BX        Process handle
FreeProcHandle	MACRO
	OldUserGate free_proc_handle_nr
					ENDM

; IN  EAX		0 = don't show text
ShowExceptionText	MACRO
	OldUserGate show_exception_text_nr
					ENDM

; OUT AX		Exit code
GetExitCode	MACRO
	OldUserGate get_exit_code_nr
					ENDM

; OUT ES:(E)DI	Program name
GetExeName	MACRO
	OldUserGate get_exe_name_nr
					ENDM

; OUT ES:(E)DI	Command line
GetCmdLine	MACRO
	OldUserGate get_cmd_line_nr
					ENDM

; OUT ES:(E)DI	Options
GetOptions	MACRO
	OldUserGate get_options_nr
					ENDM

; OUT ES:(E)DI	Environment
GetEnvironment	MACRO
	OldUserGate get_env_nr
					ENDM

; IN  ES:(E)DI	DLL name
; OUT BX		Module handle
LoadDll	MACRO
	OldUserGate load_dll_nr
					ENDM

; IN  BX		Module handle
FreeDll	MACRO
	OldUserGate free_dll_nr
					ENDM

; IN  BX		Module handle
; OUT AL        Focus key
GetModuleFocusKey	MACRO
	OldUserGate get_module_focus_key_nr
					ENDM

; OUT BX		Module handle
GetCurrentModule	MACRO
	OldUserGate get_current_module_nr
					ENDM

; IN  ES:(E)DI	Module name
; OUT BX		Module handle
GetModule	MACRO
	OldUserGate get_module_nr
					ENDM

; IN  BX		Module handle
; IN  ES:(E)DI	Proc name
; OUT DS:(E)SI	Proc address
GetModuleProc	MACRO
	OldUserGate get_module_proc_nr
					ENDM

; IN  BX		Module handle
; IN  (E)AX		Resource handle
; IN  (E)DX		Resource type
; OUT DS:(E)SI	Resource address
; OUT ECX       Resource size
GetModuleResource	MACRO
	OldUserGate get_module_resource_nr
					ENDM

; IN  BX		Module handle
; IN  (E)CX		Max name size
; IN  ES:(E)DI	Name buffer
; OUT (E)AX		Bytes copied
GetModuleName	MACRO
	OldUserGate get_module_name_nr
					ENDM

; IN  EAX     		Number of bytes
; OUT ES / (E)DX    Selector or linear base address (depends on loader)
AllocateAppMem     MACRO
	OldUserGate allocate_app_mem_nr
						ENDM

; IN  ES / (E)DX    Selector or linear base address (depends on loader)
FreeAppMem     MACRO
	OldUserGate free_app_mem_nr
						ENDM

; IN  EAX     		Number of bytes
; OUT ES / (E)DX    Selector or linear base address (depends on loader)
AllocateDebugAppMem     MACRO
	OldUserGate allocate_debug_app_mem_nr
						ENDM

; IN  ES / (E)DX    Selector or linear base address (depends on loader)
FreeDebugAppMem     MACRO
	OldUserGate free_debug_app_mem_nr
						ENDM

; OUT BX			PSP Selector
GetPspSel	MACRO
	OldUserGate get_psp_sel_nr
					ENDM

; OUT BX            Env handle
OpenSysEnv	MACRO
	OldUserGate open_sys_env_nr
	        ENDM

; OUT BX            Env handle
OpenProcEnv	MACRO
	OldUserGate open_proc_env_nr
	        ENDM

; IN  BX            Env handle
CloseEnv	MACRO
	OldUserGate close_env_nr
	        ENDM

; IN  BX            Env handle
; IN  DS:(E)SI      Env var name
; IN  ES:(E)DI      Env var data
AddEnvVar	MACRO
	OldUserGate add_env_var_nr
	        ENDM

; IN  BX            Env handle
; IN  DS:(E)SI      Env var name
DeleteEnvVar	MACRO
	OldUserGate delete_env_var_nr
	        ENDM

; IN  BX            Env handle
; IN  DS:(E)SI      Env var name
; IN  ES:(E)DI      Env var data
FindEnvVar	MACRO
	OldUserGate find_env_var_nr
	        ENDM

; IN  BX            Env handle
; OUT (E)AX         Required size of data buffer
GetEnvSize	MACRO
	OldUserGate get_env_size_nr
	        ENDM

; IN  BX            Env handle
; IN  ES:(E)DI      Env data buffer
GetEnvData	MACRO
	OldUserGate get_env_data_nr
	        ENDM

; IN  BX            Env handle
; IN  ES:(E)DI      Env data buffer
SetEnvData	MACRO
	OldUserGate set_env_data_nr
	        ENDM

;;;;;;;;;;;;;; INI FILE HANDLING ;;;;;;;;;;;

; OUT BX            Ini handle
OpenSysIni	MACRO
	OldUserGate open_sys_ini_nr
	        ENDM

; IN  ES:(E)DI      Ini file name
; OUT BX            Ini handle
OpenIni	MACRO
	OldUserGate open_ini_nr
	        ENDM

; IN  BX            Ini handle
CloseIni	MACRO
	OldUserGate close_ini_nr
	        ENDM

; IN  BX            Ini handle
; IN  ES:(E)DI      Section name
GotoIniSection	MACRO
	OldUserGate goto_ini_section_nr
	        ENDM

; IN  BX            Ini handle
; IN  ES:(E)DI      Section name
RemoveIniSection	MACRO
	OldUserGate remove_ini_section_nr
	        ENDM

; IN  BX            Ini handle
; IN  DS:(E)SI      Var name
; IN  ES:(E)DI      Buffer
; IN  (E)CX         Max size
ReadIni	MACRO
	OldUserGate read_ini_nr
	        ENDM

; IN  BX            Ini handle
; IN  DS:(E)SI      Var name
; IN  ES:(E)DI      String
WriteIni	MACRO
	OldUserGate write_ini_nr
	        ENDM

; IN  BX            Ini handle
; IN  DS:(E)SI      Var name
DeleteIni	MACRO
	OldUserGate delete_ini_nr
	        ENDM

;;;;;;;;;;;;;; DEBUGGING ;;;;;;;;;;;

; IN  ES:(E)DI        TSS data buffer
; IN  AX              Thread ID
GetDebugTss     MACRO
	OldUserGate get_debug_tss_nr
						ENDM

; OUT AX               Thread ID
;GetDebugThread MACRO
;	OldUserGate get_debug_thread_nr
;						ENDM

DebugTrace      MACRO
	OldUserGate debug_trace_nr
						ENDM

DebugPace       MACRO
	OldUserGate debug_pace_nr
						ENDM

DebugGo MACRO
	OldUserGate debug_go_nr
						ENDM

DebugNext       MACRO
	OldUserGate debug_next_nr
						ENDM

; IN  ES:(E)DI   	State buffer
; IN  AX           	Thread #
GetThreadState     MACRO
	OldUserGate get_thread_state_nr
						ENDM

; IN  AX            Thread ID
SuspendThread     MACRO
	OldUserGate suspend_thread_nr
						ENDM

; IN  AX            Thread ID
SuspendAndSignalThread     MACRO
	OldUserGate suspend_and_signal_thread_nr
						ENDM

;  IN  AX   Process handle
;  IN  BX	Wait handle
;  IN  ECX  Signalled ID
AddWaitForDebugEvent MACRO
	OldUserGate add_wait_for_debug_event_nr
						ENDM

;  IN  BX   Process handle
;  OUT AX   Thread #
;  OUT BL   Event type  
GetDebugEvent MACRO
	OldUserGate get_debug_event_nr
						ENDM

;  IN  BX       Process handle
;  IN  ES:EDI	Event buffer
GetDebugEventData MACRO
	OldUserGate get_debug_event_data_nr
						ENDM

;  IN  BX       Process handle
ClearDebugEvent MACRO
	OldUserGate clear_debug_event_nr
						ENDM

;  IN  BX       Process handle
;  IN  EAX	    Thread #
ContinueDebugEvent MACRO
	OldUserGate continue_debug_event_nr
						ENDM

;  IN  EBP	Exception frame
;  IN  EAX	Exception code
NotifyPeException MACRO
	OldUserGate notify_pe_exception_nr
						ENDM

;  IN  DX:ESI	Selector:Offset
;  IN  BX		Thread #
;  OUT EDX      Linear address
GetThreadLinear	MACRO
	OldUserGate get_thread_linear_nr
					ENDM

;  IN  (E)CX	Number of bytes
;  IN  DX:ESI	Address to read at
;  IN  ES:(E)DI	Buffer
;  IN  BX		Thread #
;  OUT (E)AX	Bytes read
ReadThreadMem	MACRO
	OldUserGate read_thread_mem_nr
					ENDM

;  IN  (E)CX	Number of bytes
;  IN  DX:ESI	Address to write at
;  IN  ES:(E)DI	Buffer
;  IN  BX		Thread #
;  OUT (E)AX	Bytes written
WriteThreadMem	MACRO
	OldUserGate write_thread_mem_nr
					ENDM

;  IN  ES:(E)DI	Buffer
;  IN  BX		Thread #
GetThreadTss	MACRO
	OldUserGate get_thread_tss_nr
					ENDM

;  IN  ES:(E)DI	Buffer
;  IN  BX		Thread #
SetThreadTss	MACRO
	OldUserGate set_thread_tss_nr
					ENDM

;  IN  AL       Disc #
;  IN  EDX      Start sector #
;  IN  ECX      Number of sectors
DefineFaultSave     MACRO
	OldUserGate define_fault_save_nr
						ENDM

ClearFaultSave     MACRO
	OldUserGate clear_fault_save_nr
						ENDM

; IN  ES:(E)DI      State buffer
; IN  AX           	Fault thread #
GetFaultThreadState     MACRO
	OldUserGate get_fault_thread_state_nr
						ENDM

; IN  ES:(E)DI      TSS data buffer
; IN  AX           	Fault thread #
GetFaultThreadTss     MACRO
	OldUserGate get_fault_thread_tss_nr
						ENDM

; IN  BX            Selector
; OUT ECX           Limit
; OUT AL            Bitness (16 or 32)
GetSelectorInfo     MACRO
	OldUserGate get_selector_info_nr
						ENDM

;;;;;;;;;;; TIME & DATE ;;;;;;;;;;;;;

; IN  BX			Thread handle
; OUT EDX:EAX		Used CPU time
GetCpuTime	MACRO
	OldUserGate get_cpu_time_nr
					ENDM

; OUT EDX:EAX       System time
GetSystemTime   MACRO
	OldUserGate get_system_time_nr
					ENDM

; OUT EDX:EAX         Real time
GetTime   MACRO
	OldUserGate get_time_nr
					ENDM

TimeToSystemTime   MACRO
	OldUserGate time_to_system_time_nr
					ENDM

; IN  EDX:EAX         System time
; OUT EDX:EAX         Real time
SystemTimeToTime   MACRO
	OldUserGate system_time_to_time_nr
					ENDM


; IN  EDX:EAX		Difference between real time and system time
UpdateTime	MACRO
	OldUserGate update_time_nr
					ENDM

UpdateRtc	MACRO
	OldUserGate update_rtc_nr
					ENDM

; IN  DX		Year
; IN  CH		Month
; OUT AL		Days in month
DaysInMonth	MACRO
	OldUserGate days_in_month_nr
				ENDM

; IN  DX		Year
; IN  CH		Month
; IN  CL		Day
; IN  BH		Hour
; IN  BL		Minute
; IN  AH		Seconds
; OUT DX		Year
; OUT CH		Month
; OUT CL		Day
; OUT BH		Hour
; OUT BL		Minute
; OUT AH		Seconds
AdjustTime	MACRO
	OldUserGate adjust_time_nr
				ENDM

; IN  DX		Year
; IN  CH		Month
; IN  CL		Day
; OUT AX		Passed days
PassedDays	MACRO
	OldUserGate passed_days_nr
				ENDM


; IN  DX		Year
; IN  CH		Month
; IN  CL		Day
; IN  BH		Hour
; IN  BL		Minute
; IN  AH		Seconds
; OUT EDX:EAX	Binary time
TimeToBinary	MACRO
	OldUserGate time_to_binary_nr
				ENDM

; IN  EDX:EAX	Binary time
; OUT DX		Year
; OUT CH		Month
; OUT CL		Day
; OUT BH		Hour
; OUT BL		Minute
; OUT AH		Seconds
BinaryToTime	MACRO
	OldUserGate binary_to_time_nr
				ENDM

; IN  EDX		NTP IP address
SyncTime		MACRO
	OldUserGate sync_time_nr
			ENDM

;;;;;;;;;;; CONSOLE ;;;;;;;;;;;

; IN  AL      	Switch key
EnableFocus     MACRO
	OldUserGate enable_focus_nr
						ENDM

; IN  AL    	Switch key
SetFocus        MACRO
	OldUserGate set_focus_nr
						ENDM

; OUT AL    	Switch key for current process
GetFocus        MACRO
	OldUserGate get_focus_nr
						ENDM

;;;;;;;;;;;;; NETWORK ;;;;;;;;;;;

; OUT EAX		Primary DNS IP address (or 0)
; OUT EDX		Secondary DNS IP address (or 0)
GetDns	MACRO
	OldUserGate get_dns_nr
				ENDM

; OUT EAX		Primary DNS IP address (or 0)
; OUT EDX		Secondary DNS IP address (or 0)
GetPppDns	MACRO
	OldUserGate get_ppp_dns_nr
				ENDM

; IN  AX            max connections
; IN  ECX			buffer size
; IN  SI			local port
; OUT BX            listen handle
CreateTcpListen	MACRO
	OldUserGate create_tcp_listen_nr
			ENDM

; IN  BX            listen handle
; OUT AX            connection handle
GetTcpListen	MACRO
	OldUserGate get_tcp_listen_nr
			ENDM

; IN  BX		listen handle
CloseTcpListen	MACRO
	OldUserGate close_tcp_listen_nr
			ENDM

; IN  EAX		Timeout in milliseconds for connection
; IN  ECX		buffer size
; IN  EDX		ip address
; IN  SI		local port (0 for dynamic port)
; IN  DI		remote port
; OUT BX		connection handle
OpenTcpConnection	MACRO
	OldUserGate open_tcp_connection_nr
			ENDM

; IN  BX		connection handle
; IN  EAX		timeout in milliseconds
WaitForTcpConnection	MACRO
	OldUserGate wait_for_tcp_connection_nr
			ENDM

; IN  BX		connection handle
CloseTcpConnection	MACRO
	OldUserGate close_tcp_connection_nr
			ENDM

; IN  BX		connection handle
DeleteTcpConnection	MACRO
	OldUserGate delete_tcp_connection_nr
			ENDM

; IN  BX		connection handle
IsTcpConnectionClosed	MACRO
	OldUserGate is_tcp_connection_closed_nr
			ENDM

; IN  BX		connection handle
; OUT NC        Idle
IsTcpConnectionIdle	MACRO
	OldUserGate is_tcp_connection_idle_nr
			ENDM

; IN  BX		connection handle
; OUT EAX       IP
GetRemoteTcpConnectionIP	MACRO
	OldUserGate get_remote_tcp_connection_ip_nr
			ENDM

; IN  BX		connection handle
; OUT AX        port
GetRemoteTcpConnectionPort	MACRO
	OldUserGate get_remote_tcp_connection_port_nr
			ENDM

; IN  BX		connection handle
; OUT AX        port
GetLocalTcpConnectionPort	MACRO
	OldUserGate get_local_tcp_connection_port_nr
			ENDM

; IN  BX		connection handle
AbortTcpConnection	MACRO
	OldUserGate abort_tcp_connection_nr
			ENDM

; IN  EAX			timeout in ms for receive
; IN  BX			connection handle
; IN  (E)CX		wanted number of bytes
; IN  ES:E(DI)	data buffer
; OUT (E)AX		size of received data
ReadTcpConnection	MACRO
	OldUserGate read_tcp_connection_nr
			ENDM

; IN  BX			connection handle
; IN  (E)CX		buffer size
; IN  ES:(E)DI	data buffer
WriteTcpConnection		MACRO
	OldUserGate write_tcp_connection_nr
			ENDM

; IN  BX		connection handle
PushTcpConnection		MACRO
	OldUserGate push_tcp_connection_nr
			ENDM

; IN  BX		connection handle
; OUT (E)AX     number of available bytes in buffer
PollTcpConnection		MACRO
	OldUserGate poll_tcp_connection_nr
			ENDM

; OUT EDX		My IP address
GetIpAddress	MACRO
	OldUserGate get_ip_address_nr
						ENDM

; OUT EDX		My IP address
GetGateway	MACRO
	OldUserGate get_gateway_nr
						ENDM

; OUT EDX	    IP mask
GetIpMask	MACRO
	OldUserGate get_ip_mask_nr
						ENDM

; IN  ES:(E)DI		Host name
; OUT EDX			IP address
NameToIP		MACRO
	OldUserGate name_to_ip_nr
			ENDM

; IN  EDX				IP address
; IN  (E)CX			Size of buffer
; IN  ES:(E)DI		Host name buffer
; OUT (E)AX			Length of host name
IPToName		MACRO
	OldUserGate ip_to_name_nr
			ENDM

; IN  EAX				Timeout in ms
; IN  EDX				IP address
Ping		MACRO
	OldUserGate ping_nr
			ENDM

;;;;;;;;;;;;; LOW-LEVEL DISCS ;;;;;;;;;;;;;

; IN   BL           Unit #
; OUT  AL			Disc #
GetIdeDisc     MACRO
	OldUserGate get_ide_disc_nr
						ENDM

; IN   BL           Unit #
; OUT  AL			Disc #
GetFloppyDisc     MACRO
	OldUserGate get_floppy_disc_nr
						ENDM

;	IN	AL			Disc #
;	OUT	CX			Bytes / sector
;	OUT	EDX			Total # of sectors
;	OUT SI			BIOS sectors / cylinder
;	OUT DI			BIOS heads
GetDiscInfo     MACRO
	OldUserGate get_disc_info_nr
						ENDM

; IN   AL           Disc #
; IN   CX			Bytes / sector
; IN   EDX          Total # of sectors
; IN   SI           BIOS sectors / cylinder
; IN   DI           BIOS heads
SetDiscInfo     MACRO
	OldUserGate set_disc_info_nr
						ENDM

;	OUT	AL		Drive #
AllocateStaticDrive	MACRO
	OldUserGate allocate_static_drive_nr
					ENDM

;	IN	AL		Drive #
AllocateFixedDrive	MACRO
	OldUserGate allocate_fixed_drive_nr
					ENDM

;	OUT	AL		Drive #
AllocateDynamicDrive	MACRO
	OldUserGate allocate_dynamic_drive_nr
					ENDM

;	IN	AL		Drive #
DemandLoadDrive	MACRO
	OldUserGate demand_load_drive_nr
					ENDM

;	IN	AL			Disc #
;	IN	EDX			Start sector
;	IN	ECX			Number of sectors
;	IN	ES:(E)DI	File system name
FormatDrive     MACRO
	OldUserGate format_drive_nr
						ENDM

;	IN DS:(E)SI		Main key buffer
;	IN ES:(E)DI		Selection key buffer
;	IN GS:(E)BX		Extent size buffer
GetRdfsInfo     MACRO
	OldUserGate get_rdfs_info_nr
						ENDM

;	IN	AL			Disc #
;	IN	EDX			Sector #
;	IN	(E)CX		Size
;	IN	ES:(E)DI	Buffer
ReadDisc     MACRO
	OldUserGate read_disc_nr
						ENDM

;	IN	AL			Disc #
;	IN	EDX			Sector #
;	IN	(E)CX		Size
;	IN	ES:(E)DI	Buffer
WriteDisc     MACRO
	OldUserGate write_disc_nr
						ENDM

;	IN	AL			Disc #
;	IN	EDX			Sector #
;	IN	(E)CX	    Number of sectors to erase
EraseDiscSectors     MACRO
	OldUserGate erase_disc_sectors_nr
						ENDM

;	IN	AL			Drive #
;	OUT	EAX			Free units
;	OUT	CX			bytes / unit
;	OUT	EDX			total # of units
GetDriveInfo     MACRO
	OldUserGate get_drive_info_nr
						ENDM

;	IN	AL			Drive #
;   OUT AL          Disc #
;   OUT ECX         Total # of sectors
;   OUT EDX         Start sector
GetDriveDiscParam     MACRO
	OldUserGate get_drive_disc_param_nr
						ENDM

;   IN  AL          Drive #   
;   IN  ECX 	    Size of filesystem
;	IN	DS:(E)SI	File system name
;	IN	ES:(E)DI	Filename
CreateFileDrive     MACRO
	OldUserGate create_file_drive_nr
						ENDM

;   IN  AL          Drive #   
;	IN	ES:(E)DI	Filename
OpenFileDrive     MACRO
	OldUserGate open_file_drive_nr
						ENDM

;;;;;;;;;;;;;; DIRECTORY ;;;;;;;;;;;;;

; 	IN	AL              Drive #
SetCurDrive     MACRO
	OldUserGate set_cur_drive_nr
						ENDM

;	OUT	AL              Drive #
GetCurDrive     MACRO
	OldUserGate get_cur_drive_nr
						ENDM


;	IN	ES:(E)DI      	Pathname
SetCurDir       MACRO
	OldUserGate set_cur_dir_nr
						ENDM

;	IN	AL              Drive
;	IN	ES:(E)DI        Pathname
GetCurDir       MACRO
	OldUserGate get_cur_dir_nr
						ENDM

;	IN	ES:(E)DI        Pathname
MakeDir MACRO
	OldUserGate make_dir_nr
						ENDM

;	IN	ES:(E)DI        Pathname
RemoveDir       MACRO
	OldUserGate remove_dir_nr
						ENDM

;	IN	DS:(E)SI		Old pathname
;	IN	ES:(E)DI        New pathname
RenameFile      MACRO
	OldUserGate rename_file_nr
						ENDM

;	IN	ES:(E)DI        Pathname
DeleteFile      MACRO
	OldUserGate delete_file_nr
						ENDM

;	IN	ES:(E)DI        Pathname
;	IN	CX              File attribute
GetFileAttribute        MACRO
	OldUserGate get_file_attribute_nr
						ENDM

;	IN	ES:(E)DI        Pathname
;	IN	CX              File attribute
SetFileAttribute        MACRO
	OldUserGate set_file_attribute_nr
						ENDM


;	IN	ES:(E)DI		Pathname
;	OUT	BX				Handle
OpenDir   MACRO
	OldUserGate open_dir_nr
						ENDM

;	IN	BX				Handle
CloseDir   MACRO
	OldUserGate close_dir_nr
						ENDM

;	IN	BX				Handle
;	IN	DX				Entry #
;	IN	CX				Max size of name
;	IN	ES:(E)DI		Buffer
;	OUT	ECX				Filesize
;	OUT	BX				File attribute
;	OUT	EDX:EAX			File systemtime
ReadDir        MACRO
	OldUserGate read_dir_nr
						ENDM

;;;;;;;;;;;;;; FILES ;;;;;;;;;;;;;

;	IN	ES:(E)DI	Pathname
;	IN	CL			Access mode
;	OUT	BX			Handle
OpenFile        MACRO
	OldUserGate open_file_nr
						ENDM

;	IN	ES:(E)DI	Pathname
;	IN	CX     		Attribute
;	OUT	BX        	Handle
CreateFile      MACRO
	OldUserGate create_file_nr
						ENDM

;	IN	BX   		Handle
CloseFile       MACRO
	OldUserGate close_file_nr
						ENDM

;	IN	AX			Old handle
;	OUT	BX			New handle
DuplFile       MACRO
	OldUserGate dupl_file_nr
						ENDM

;	IN	BX   		Handle
;	OUT	DX  		Device data
GetIoctlData    MACRO
	OldUserGate get_ioctl_data_nr
						ENDM


;	IN	BX 			Handle
;	OUT	EAX 		Filesize
GetFileSize     MACRO
	OldUserGate get_file_size_nr
						ENDM


;	IN	BX			Handle
;	IN	EAX			Filesize
SetFileSize     MACRO
	OldUserGate set_file_size_nr
						ENDM


;	IN	BX			Handle
;	IN	EAX			File position
GetFilePos      MACRO
	OldUserGate get_file_pos_nr
						ENDM


;	IN	BX			Handle
;	IN	EAX			File position
SetFilePos      MACRO
	OldUserGate set_file_pos_nr
						ENDM

;	IN	BX			Handle
;	OUT	EDX:EAX		File system time
GetFileTime      MACRO
	OldUserGate get_file_time_nr
						ENDM

;	IN	BX			Handle
;	IN	EDX:EAX		File system time
SetFileTime      MACRO
	OldUserGate set_file_time_nr
						ENDM

;	IN	BX      	Handle
;	IN	ES:(E)DI	Buffer
;	IN	(E)CX		Number of bytes to read
;	OUT	(E)AX 		Number of bytes read
ReadFile        MACRO
	OldUserGate read_file_nr
						ENDM

;	IN	BX    		Handle
;	IN	ES:(E)DI 	Buffer
;	IN	(E)CX		Number of bytes to write
; 	OUT (E)AX 		Number of bytes written
WriteFile       MACRO
	OldUserGate write_file_nr
						ENDM

;   IN  (E)CX       Number of chars
;   IN  ES:(E)DI    Buffer
;   OUT (E)AX       Number of chars read
ReadConsole     MACRO
	OldUserGate read_con_nr
						ENDM

;;;;;;;;;;; MEMORY MAPPING ;;;;;;;;;;

;	IN EAX			Size of mapping object
;	OUT BX			Handle
CreateMapping        MACRO
	OldUserGate create_mapping_nr
						ENDM

;	IN EAX			Size of mapping object
;	IN ES:(E)DI 	Name for mapping
;	OUT BX			Handle
CreateNamedMapping        MACRO
	OldUserGate create_named_mapping_nr
						ENDM

;	IN EAX			Size of mapping object
;	IN BX			File handle
;	OUT BX			Handle
CreateFileMapping        MACRO
	OldUserGate create_file_mapping_nr
						ENDM

;	IN EAX			Size of mapping object
;	IN BX			File handle
;	IN ES:(E)DI 	Name of mapping
;	OUT BX			Handle
CreateNamedFileMapping        MACRO
	OldUserGate create_named_file_mapping_nr
						ENDM

;	IN	ES:(E)DI 	Name of mapping
;	OUT BX			Handle
OpenNamedMapping        MACRO
	OldUserGate open_named_mapping_nr
						ENDM

;	IN  BX			Handle
SyncMapping        MACRO
	OldUserGate sync_mapping_nr
						ENDM

;	IN  BX			Handle
CloseMapping        MACRO
	OldUserGate close_mapping_nr
						ENDM

;	IN  EAX			Offset into object
;	IN  BX			Handle
;	IN	(E)CX		Size
;	IN  ES:(E)DI	Address to map at
MapView        MACRO
	OldUserGate map_view_nr
						ENDM

;	IN  BX			Handle
UnmapView        MACRO
	OldUserGate unmap_view_nr
						ENDM

;;;;;;;;;;; KEYBOARD ;;;;;;;;;;;;;

;  IN  ES:(E)DI     Layout name buffer (must be at least 3 bytes)
GetKeyboardLayout    MACRO
	OldUserGate get_key_layout_nr
						ENDM

;  IN  ES:(E)DI     Layout name
SetKeyboardLayout    MACRO
	OldUserGate set_key_layout_nr
						ENDM

; OUT  AX			Character read
ReadKeyboard    MACRO
	OldUserGate read_keyboard_nr
						ENDM

PollKeyboard    MACRO
	OldUserGate poll_keyboard_nr
						ENDM

FlushKeyboard   MACRO
	OldUserGate flush_keyboard_nr
						ENDM

; IN  AX          Keyboard code
; IN  DL          Virtual key code
; IN  DH          Scan code
PutKeyboardCode	MACRO
	OldUserGate put_keyboard_code_nr
					ENDM

; OUT AX			Character read
; OUT CX            Keyboard state
; OUT DL            Virtual key code
; OUT DH            Scan code
PeekKeyEvent    MACRO
	OldUserGate peek_key_event_nr
						ENDM

; OUT AX			Character read
; OUT CX            Keyboard state
; OUT DL            Virtual key code
; OUT DH            Scan code
ReadKeyEvent    MACRO
	OldUserGate read_key_event_nr
						ENDM

ext_numpad_handled	EQU 800h
ext_numpad_active	EQU 400h
num_active			EQU 200h
caps_active			EQU 100h
print_pressed		EQU 20h
scroll_pressed		EQU 10h
pause_pressed		EQU 8
ctrl_pressed		EQU 4
alt_pressed			EQU 2
shift_pressed		EQU 1

; OUT  AX		Keyboard states.
GetKeyboardState    MACRO
	OldUserGate get_keyboard_state_nr
						ENDM

;;;;;;;;;;;; MOUSE ;;;;;;;;;;;

ShowMouse    MACRO
	OldUserGate show_mouse_nr
						ENDM

HideMouse    MACRO
	OldUserGate hide_mouse_nr
						ENDM

; OUT CX              x
; OUT DX              y
GetMousePosition    MACRO
	OldUserGate get_mouse_position_nr
						ENDM

; IN  CX              x
; IN  DX              y
SetMousePosition    MACRO
	OldUserGate set_mouse_position_nr
						ENDM

;	IN  AX			start x
;	IN  BX			start y
;   IN  CX          end x
;   IN  DX          end y
SetMouseWindow    MACRO
	OldUserGate set_mouse_window_nr
						ENDM

;	IN  CX           mickeys in x-direction
;	IN  DX           mickeys in y-direction
SetMouseMickey    MACRO
	OldUserGate set_mouse_mickey_nr
						ENDM

;		NC			button is pressed
GetLeftButton    MACRO
	OldUserGate get_left_button_nr
						ENDM

;		NC			button is pressed
GetRightButton    MACRO
	OldUserGate get_right_button_nr
						ENDM

;	OUT CX              x
;	OUT DX              y
GetLeftButtonPressPosition    MACRO
	OldUserGate get_left_button_press_position_nr
						ENDM

;	OUT CX              x
;	OUT DX              y
GetRightButtonPressPosition    MACRO
	OldUserGate get_right_button_press_position_nr
						ENDM

;	OUT CX              x
;	OUT DX              y
GetLeftButtonReleasePosition    MACRO
	OldUserGate get_left_button_release_position_nr
						ENDM

;	OUT CX              x
;	OUT DX              y
GetRightButtonReleasePosition    MACRO
	OldUserGate get_right_button_release_position_nr
						ENDM

;	IN  ES:(E)DI	Callback
;			AX		Buttons
;			CX		Delta x movement
;			DX		Delta y movement
HookMouse    MACRO
	OldUserGate hook_mouse_nr
						ENDM

UnhookMouse    MACRO
	OldUserGate unhook_mouse_nr
						ENDM

;;;;;;;;;;;;; CDROM ;;;;;;;;;;;;

LockCd  MACRO
	OldUserGate lock_cd_nr
		ENDM
		
UnlockCd        MACRO
	OldUserGate unlock_cd_nr
			ENDM
			
EjectCd MACRO
	OldUserGate eject_cd_nr
		ENDM
		
InsertCd        MACRO
	OldUserGate insert_cd_nr
			ENDM

;;;;;;;;;;;;; SERIAL PORT ;;;;;;;;;;;;;

;   OUT AL      Port #
GetMaxComPort       MACRO
	OldUserGate get_max_com_port_nr
						ENDM

;	IN  AL		Port #
;	IN  AH		# of data bits
;	IN  BL		# of stop bits
;	IN  BH		parity ('N', 'E' or 'O')
;	IN  ECX		baudrate
;	IN  SI		size of transmit buffer
;	IN  DI		size of receive buffer
;	OUT BX		port handle
OpenCom       MACRO
	OldUserGate open_com_nr
						ENDM

;	IN  BX		port handle
CloseCom       MACRO
	OldUserGate close_com_nr
						ENDM

;	IN  BX		port handle
FlushCom       MACRO
	OldUserGate flush_com_nr
						ENDM

;	IN  BX		port handle
;	OUT AX		data read or -1
ReadCom       MACRO
	OldUserGate read_com_nr
						ENDM

;	IN  BX		port handle
;	OUT AL		data to send
WriteCom       MACRO
	OldUserGate write_com_nr
						ENDM

;	IN  BX		port handle
WaitForSendCompletedCom       MACRO
	OldUserGate wait_for_send_completed_com_nr
						ENDM

;	IN  BX		port handle
EnableCts       MACRO
	OldUserGate enable_cts_nr
						ENDM

;	IN  BX		port handle
DisableCts       MACRO
	OldUserGate disable_cts_nr
						ENDM

;	IN  BX		port handle
SetDtr       MACRO
	OldUserGate set_dtr_nr
						ENDM

;	IN  BX		port handle
ResetDtr       MACRO
	OldUserGate reset_dtr_nr
						ENDM

;	IN  BX		port handle
SetRts       MACRO
	OldUserGate set_rts_nr
						ENDM

;	IN  BX		port handle
ResetRts       MACRO
	OldUserGate reset_rts_nr
						ENDM

;	IN  BX		port handle
EnableAutoRts       MACRO
	OldUserGate enable_auto_rts_nr
						ENDM

;	IN  BX		port handle
DisableAutoRts       MACRO
	OldUserGate disable_auto_rts_nr
						ENDM

;	IN  BX		port handle
;   OUT EAX     free space
GetComReceiveSpace       MACRO
	OldUserGate get_com_receive_space_nr
						ENDM

;	IN  BX		port handle
;   OUT EAX     free space
GetComSendSpace       MACRO
	OldUserGate get_com_send_space_nr
						ENDM

;;;;;;;;;;;;;; PRINTER ;;;;;;;;;;;;

;   OUT AL      Printer #
GetMaxPrinters       MACRO
	OldUserGate get_max_printer_nr
						ENDM

;	IN  AL		Printer #
;	OUT BX		Printer handle
OpenPrinter       MACRO
	OldUserGate open_printer_nr
						ENDM

;	IN  BX		Printer handle
ClosePrinter       MACRO
	OldUserGate close_printer_nr
						ENDM

;	IN  BX		Printer handle
;   OUT CY      Jammed
IsPrinterJammed       MACRO
	OldUserGate is_printer_jammed_nr
						ENDM

;	IN  BX		Printer handle
;   OUT CY      Low
IsPrinterPaperLow       MACRO
	OldUserGate is_printer_paper_low_nr
						ENDM

;	IN  BX		Printer handle
;   OUT CY      End
IsPrinterPaperEnd       MACRO
	OldUserGate is_printer_paper_end_nr
						ENDM

;	IN  BX		Printer handle
;   OUT NC      OK
IsPrinterOk       MACRO
	OldUserGate is_printer_ok_nr
						ENDM

;	IN  BX		Printer handle
;   OUT CY      Lifted
IsPrinterHeadLifted       MACRO
	OldUserGate is_printer_head_lifted_nr
						ENDM

;	IN  BX		Printer handle
;   OUT CY      Paper in presenter
HasPrinterPaperInPresenter      MACRO
	OldUserGate has_printer_paper_in_presenter_nr
						ENDM

;	IN  BX		Printer handle
PrintTest       MACRO
	OldUserGate print_test_nr
						ENDM

;	IN  BX		Printer handle
;   IN  DX      Height
;   OUT AX      Bitmap handle
CreatePrinterBitmap       MACRO
	OldUserGate create_printer_bitmap_nr
						ENDM

;	IN  BX		Printer handle
;   IN  AX      Bitmap handle
PrintBitmap       MACRO
	OldUserGate print_bitmap_nr
						ENDM

;	IN  BX		Printer handle
;   IN  AX      Length in mm
PresentPrinterMedia       MACRO
	OldUserGate present_printer_media_nr
						ENDM

;	IN  BX		Printer handle
EjectPrinterMedia       MACRO
	OldUserGate eject_printer_media_nr
						ENDM

;;;;;;;;;; SCREEN, TEXT MODE ;;;;;;;;;;

;	IN  CX              Column number (x)
;	IN  DX              Row number (y)
SetCursorPosition    MACRO
	OldUserGate set_cursor_position_nr
						ENDM

;	OUT CX              Column number (x)
;	OUT DX              Row number (y)
GetCursorPosition    MACRO
	OldUserGate get_cursor_position_nr
						ENDM

;	IN  AL              Color number
SetForeColor        MACRO
	OldUserGate set_forecolor_nr
						ENDM

;	IN  AL              Color number. 0FFh is transparent
SetBackColor        MACRO
	OldUserGate set_backcolor_nr
						ENDM

;	OUT AL       	Char
;	OUT BL			Back color
;   OUT BH			Fore color
GetCharAttrib       MACRO
	OldUserGate get_char_attrib_nr
						ENDM

;	IN  AL              Char
WriteChar       MACRO
	OldUserGate write_char_nr
						ENDM

;	IN  ES:(E)DI           Null terminated string
WriteAsciiz     MACRO
	OldUserGate write_asciiz_nr
						ENDM

;	IN  ES:(E)DI           Buffer
;   IN  (E)CX              Count
WriteSizeString MACRO
	OldUserGate write_size_string_nr
						ENDM

;;;;;;;;;;; FONT ;;;;;;;;;;

;	IN  AX              Requested font height
;	OUT	BX				Font handle
OpenFont        MACRO
	OldUserGate open_font_nr
						ENDM

;	IN	BX				Font handle
CloseFont        MACRO
	OldUserGate close_font_nr
						ENDM

;	IN  ES:E(DI)		String to ask about
;	IN	BX				Font handle
;	OUT CX				Width of string
;	OUT DX				Height of char
GetStringMetrics        MACRO
	OldUserGate get_string_metrics_nr
						ENDM

;;;;;;;;;;; SCREEN, GRAPHICS MODE ;;;;;;;;;;

;	IN  AX		bits / pixel
;	IN  CX		x-resolution
;	IN  DX		y-resolution
;	OUT AX		Requested mode
GetVideoMode      MACRO
	OldUserGate get_video_mode_nr
						ENDM

;	IN  AX		Requested mode
;	OUT AX		bits / pixel
;	OUT BX		bitmap handle
;	OUT CX		x-resolution
;	OUT DX		y-resolution
;	OUT SI		line size
;	OUT	ES:EDI	video buffer
SetVideoMode      MACRO
	OldUserGate set_video_mode_nr
						ENDM

SetVgaMode      MACRO
	OldUserGate set_vga_mode_nr
						ENDM

;	IN  EAX           	RGB color
;	IN	BX				Bitmap handle
SetDrawColor        MACRO
	OldUserGate set_drawcolor_nr
						ENDM

;	IN  AX              LGOP
;	IN	BX				Bitmap handle
SetLgop        MACRO
	OldUserGate set_lgop_nr
						ENDM

;	IN	BX		Bitmap handle
;	IN	CX		min x
;	IN	DX	    min y
;	IN  SI		max x
;	IN  DI	    max y
SetClipRect        MACRO
	OldUserGate set_clip_rect_nr
						ENDM

;	IN	BX		Bitmap handle
ClearClipRect        MACRO
	OldUserGate clear_clip_rect_nr
						ENDM

;	IN	BX				Bitmap handle or 0
SetHollowStyle        MACRO
	OldUserGate set_hollow_style_nr
						ENDM

;	IN	BX				Bitmap handle or 0
SetFilledStyle        MACRO
	OldUserGate set_filled_style_nr
						ENDM

;	IN	BX		Bitmap handle or 0
;	IN  CX		x
;	IN  DX		y
;	OUT EAX		RGB value
GetPixel      MACRO
	OldUserGate get_pixel_nr
						ENDM

;	IN	BX		Bitmap handle or 0
;	IN  CX		x
;	IN  DX		y
SetPixel      MACRO
	OldUserGate set_pixel_nr
						ENDM

;	IN  AX		Source bitmap handle or 0
;	IN	BX		Dest bitmap handle or 0
;	IN	CX		Width
;	IN	DX		Height
;	IN	ESI		source x + y << 16
;	IN 	EDI		dest x + y << 16
Blit      MACRO
	OldUserGate blit_nr
						ENDM

;	IN	AX		Row size
;	IN	BX		Bitmap handle or 0
;	IN	ECX		source x + y << 16
;	IN	EDX		dest x + y << 16
;	IN	ESI		width + height << 16
;	IN	ES:EDI	1-bit mask
DrawMask      MACRO
	OldUserGate draw_mask_nr
						ENDM

;	IN	BX		Bitmap handle or 0
;	IN	CX		x1
;	IN	DX		y1
;	IN  SI		x2
;	IN  DI		y2
DrawLine      MACRO
	OldUserGate draw_line_nr
						ENDM

;	IN  AX			Font handle
;	IN  BX			Bitmap handle or 0
SetFont      MACRO
	OldUserGate set_font_nr
						ENDM

;	IN  CX			x position
;	IN  DX			y position
;	IN  ES:(E)DI	String to draw
DrawString      MACRO
	OldUserGate draw_string_nr
						ENDM

;	IN	BX		Bitmap handle or 0
;	IN	CX		x
;	IN	DX		y
;	IN  SI		width
;	IN  DI		height
DrawRect      MACRO
	OldUserGate draw_rect_nr
						ENDM

;	IN	BX		Bitmap handle or 0
;	IN	CX		x
;	IN	DX		y
;	IN  SI		width
;	IN  DI		height
DrawEllipse      MACRO
	OldUserGate draw_ellipse_nr
						ENDM

;	IN  AX		Bits per pixel
;	IN  CX		Width
;	IN  DX		Height
;	OUT BX		Bitmap handle
CreateBitmap      MACRO
	OldUserGate create_bitmap_nr
						ENDM

;	IN  BX		Bitmap handle
;	OUT BX		Duplicated bitmap handle
DuplicateBitmapHandle      MACRO
	OldUserGate dup_bitmap_handle_nr
						ENDM

;	IN  BX		Bitmap handle
CloseBitmap      MACRO
	OldUserGate close_bitmap_nr
						ENDM

;	IN  ES:E(DI)	String
;	IN  BX			Font handle
;	OUT	BX			Bitmap handle
CreateStringBitmap      MACRO
	OldUserGate create_string_bitmap_nr
						ENDM

;	IN  BX			Bitmap handle
;	OUT	AL			Bits / pixel
;	OUT CX			Width
;	OUT DX			Height
;	OUT	SI			Line size in bytes
;	OUT ES:EDI		Buffer address
GetBitmapInfo      MACRO
	OldUserGate get_bitmap_info_nr
						ENDM

;   IN  AX      LGOP
;   IN  BX      Dest bitmap handle or 0
;	IN  CX		Main bitmap
;	IN  DX		Mask (1-bit bitmap)
;	OUT BX		Sprite handle
CreateSprite      MACRO
	OldUserGate create_sprite_nr
						ENDM

;	IN  BX		Sprite handle
CloseSprite      MACRO
	OldUserGate close_sprite_nr
						ENDM

;	IN  BX		Sprite handle
ShowSprite      MACRO
	OldUserGate show_sprite_nr
						ENDM

;	IN  BX		Sprite handle
HideSprite      MACRO
	OldUserGate hide_sprite_nr
						ENDM

;	IN  BX		Sprite handle
;   IN  CX      x
;   IN  DX      y
MoveSprite      MACRO
	OldUserGate move_sprite_nr
						ENDM

;	IN  AX		Adc channel
;	OUT BX		Adc handle
OpenAdc      MACRO
	OldUserGate open_adc_nr
						ENDM
						
;	IN  BX		Adc handle
CloseAdc      MACRO
	OldUserGate close_adc_nr
						ENDM
						
;	IN  BX		Adc handle
;   IN  EDX:EAX	Time to do next ADC conversion
DefineAdcTime      MACRO
	OldUserGate define_adc_time_nr
						ENDM
												
;	IN  BX		Adc handle
;   OUT	EAX     Value
ReadAdc      MACRO
	OldUserGate read_adc_nr
						ENDM

;	IN  DH		Device #
;	OUT AL		State
ReadSerialLines      MACRO
	OldUserGate read_serial_lines_nr
						ENDM

;	IN  DH		Device #
;	IN  DL		Line #
ToggleSerialLine      MACRO
	OldUserGate toggle_serial_line_nr
						ENDM

;	IN  DH		Device #
;	IN	DL		Line #
;	OUT EAX		Value
ReadSerialVal      MACRO
	OldUserGate read_serial_val_nr
						ENDM

;	IN  DH		Device #
;	IN  DL		Line #
;	IN  EAX		Value
WriteSerialVal      MACRO
	OldUserGate write_serial_val_nr
						ENDM

EnableStatusLED      MACRO
	OldUserGate enable_status_led_nr
						ENDM

DisableStatusLED      MACRO
	OldUserGate disable_status_led_nr
						ENDM

;   IN  EAX     Timeout in milli seconds
StartWatchdog      MACRO
	OldUserGate start_watchdog_nr
						ENDM

KickWatchdog      MACRO
	OldUserGate kick_watchdog_nr
						ENDM

StopWatchdog      MACRO
	OldUserGate stop_watchdog_nr
						ENDM

;   OUT EAX     Maximum tics between kicks. If 0, watchdog not running.
GetWatchdogTics      MACRO
	OldUserGate get_watchdog_tics_nr
						ENDM
						
;	IN  BX		File handle
StartNetCapture      MACRO
	OldUserGate start_net_capture_nr
						ENDM
						
StopNetCapture      MACRO
	OldUserGate stop_net_capture_nr
						ENDM

;   IN  AX          CRC polynom
;   OUT BX          CRC handle
CreateCrc      MACRO
	OldUserGate create_crc_nr
						ENDM

;   IN  BX          CRC handle
CloseCrc      MACRO
	OldUserGate close_crc_nr
						ENDM

;   IN  BX          CRC handle
;   IN  AX          CRC value
;   IN  ES:(E)DI    Data
;   IN  (E)CX       Size
;   OUT AX          CRC value
CalcCrc      MACRO
	OldUserGate calc_crc_nr
						ENDM

;   IN  BX          Controller #
;   IN  AL          Device address (1..128)
;   IN  (E)CX       Buffer size
;   IN  ES:(E)DI    Buffer
;   OUT (E)AX       Size of descriptor
GetUsbDevice      MACRO
	OldUserGate get_usb_device_nr
						ENDM

;   IN  BX          Controller #
;   IN  AL          Device address (1..128)
;   IN  DL          Config #
;   IN  (E)CX       Buffer size
;   IN  ES:(E)DI    Buffer
;   OUT (E)AX       Size of descriptor
GetUsbConfig      MACRO
	OldUserGate get_usb_config_nr
						ENDM

;   IN  BX          Controller #
;   IN  AL          Device address (1..128)
;   IN  DL          Configuration id
ConfigUsbDevice      MACRO
	OldUserGate config_usb_device_nr
						ENDM

;   IN  BX          Controller #
;   IN  AL          Device address (1..128)
;   IN  DL          Pipe #
;   OUT BX          Handle
OpenUsbPipe      MACRO
	OldUserGate open_usb_pipe_nr
						ENDM

;   IN  BX          Handle
CloseUsbPipe      MACRO
	OldUserGate close_usb_pipe_nr
						ENDM

;   IN  BX          Handle
LockUsbPipe      MACRO
	OldUserGate lock_usb_pipe_nr
						ENDM

;   IN  BX          Handle
UnlockUsbPipe      MACRO
	OldUserGate unlock_usb_pipe_nr
						ENDM

;   IN  BX          Handle
;   IN  CX          Size of data
;   IN  ES:(E)DI    Buffer
WriteUsbControl      MACRO
	OldUserGate write_usb_control_nr
						ENDM

;   IN  BX          Handle
;   IN  CX          Size of data
;   IN  ES:(E)DI    Buffer
ReqUsbData      MACRO
	OldUserGate req_usb_data_nr
						ENDM

;   IN  BX          Handle
;   OUT (E)AX       Read size
GetUsbDataSize      MACRO
	OldUserGate get_usb_data_size_nr
						ENDM

;   IN  BX          Handle
;   IN  CX          Size of data
;   IN  ES:(E)DI    Buffer
WriteUsbData      MACRO
	OldUserGate write_usb_data_nr
						ENDM

;   IN  BX          Handle
ReqUsbStatus      MACRO
	OldUserGate req_usb_status_nr
						ENDM

;   IN  BX          Handle
WriteUsbStatus      MACRO
	OldUserGate write_usb_status_nr
						ENDM

;   IN  BX          Handle
StartUsbTransaction      MACRO
	OldUserGate start_usb_transaction_nr
						ENDM

;   IN  BX          Handle
;   IN  CY          Transaction pending
;   IN  NC          Transaction done
IsUsbTransactionDone      MACRO
	OldUserGate is_usb_trans_done_nr
						ENDM

;   IN  BX          Handle
;   IN  CY          Transaction failed
;   IN  NC          Transaction ok
WasUsbTransactionOk      MACRO
	OldUserGate was_usb_trans_ok_nr
						ENDM

;;;;;;;;;;; ICSP (In-circuit serial programming) ;;;;;;;;;;

;   IN  AL          Device #
;   OUT BX          Handle
OpenICSP      MACRO
	OldUserGate open_icsp_nr
						ENDM

;   IN  BX          Handle
CloseICSP      MACRO
	OldUserGate close_icsp_nr
						ENDM

;   IN  BX          Handle
;   IN  EAX         Command
WriteICSPCommand      MACRO
	OldUserGate write_icsp_cmd_nr
						ENDM

;   IN  BX          Handle
;   IN  EAX         Data
WriteICSPData      MACRO
	OldUserGate write_icsp_data_nr
						ENDM

;   IN  BX          Handle
;   OUT EAX         Data
ReadICSPData      MACRO
	OldUserGate read_icsp_data_nr
						ENDM

;;;;;;;;;;; Audio ;;;;;;;;;;

;   IN  AL          GPIO 0 value
SetCodecGpio0      MACRO
	OldUserGate set_codec_gpio0_nr
						ENDM

;   OUT AL          Left
;   OUT AH          Right
GetMasterVolume      MACRO
	OldUserGate get_master_volume_nr
						ENDM

;   IN  AL          Left
;   IN  AH          Right
SetMasterVolume      MACRO
	OldUserGate set_master_volume_nr
						ENDM

;   OUT AL          Left
;   OUT AH          Right
GetLineOutVolume      MACRO
	OldUserGate get_line_out_volume_nr
						ENDM

;   IN  AL          Left
;   IN  AH          Right
SetLineOutVolume      MACRO
	OldUserGate set_line_out_volume_nr
						ENDM

;   IN  AX          Sample rate
;   IN  CL          Bits
;   IN  DX          Volume
;   OUT BX          Handle
CreateAudioOutChannel      MACRO
	OldUserGate create_audio_out_channel_nr
						ENDM

;   IN  BX          Handle
CloseAudioOutChannel      MACRO
	OldUserGate close_audio_out_channel_nr
						ENDM

;   IN  BX          Handle
;   IN  ECX         Buffer size
;   IN  DS:ESI      Left channel data
;   IN  ES:EDI      Right channel data
WriteAudio      MACRO
	OldUserGate write_audio_nr
						ENDM

;;;;;;;;;;; FM synthesis ;;;;;;;;;;

;   IN  AX          Sample rate
;   OUT BX          FM handle
OpenFm      MACRO
	OldUserGate open_fm_nr
	                ENDM

;   IN  BX          FM handle
CloseFm      MACRO
	OldUserGate close_fm_nr
	                ENDM

;   IN  BX          FM handle
;   IN  EAX         Samples to wait
FmWait      MACRO
	OldUserGate fm_wait_nr
	                ENDM

;   IN  BX          FM handle
;   IN  AX:DX       C:M ratio
;   IN  ST0         Beta (modulation rate) 
;   OUT BX          Handle         
CreateFmInstrument      MACRO
	OldUserGate create_fm_instrument_nr
	                ENDM

;   IN  BX          Handle         
FreeFmInstrument      MACRO
	OldUserGate free_fm_instrument_nr
	                ENDM

;   IN  BX          Handle         
;   IN  EAX         Time in samples until full volume (attack)
SetFmAttack      MACRO
	OldUserGate set_fm_attack_nr
	                ENDM

;   IN  BX          Handle         
;   IN  EAX         Time in samples until volume is halved
;   IN  EDX         Time in samples until modulation index is halved
SetFmSustain      MACRO
	OldUserGate set_fm_sustain_nr
	                ENDM

;   IN  BX          Handle         
;   IN  EAX         Time in samples until volume is halved
;   IN  EDX         Time in samples until modulation index is halved
SetFmRelease      MACRO
	OldUserGate set_fm_release_nr
	                ENDM

;   IN  BX          Instrument handle         
;   IN  ECX         Duration of sustain in samples
;   IN  EAX         Peak left volume
;   IN  EDX         Peak right volume
;   IN  ST0         Frequency
PlayFmNote      MACRO
	OldUserGate play_fm_note_nr
	                ENDM

