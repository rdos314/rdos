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

UserGate16	MACRO gate_nr
	db 0Fh
	db 0Bh
	db 0D6h
	dd gate_nr
	nop
			ENDM

UserGate32	MACRO gate_nr
	db 0Fh
	db 0Bh
	db 0D7h
	dd gate_nr
	nop
			ENDM

UserGateForce32 MACRO gate_nr
	db 0Fh
	db 0Bh
	db 0D8h
	dd gate_nr
	nop
			ENDM

UserGate        MACRO gate_nr
IF GateSize EQ 16
	UserGate16 gate_nr
ELSE
	IF GateSize EQ 32
		UserGate32 gate_nr
	ELSE
		UserGate16 gate_nr
	ENDIF
ENDIF
			ENDM

;;;;;;;;;;;;;; MEMORY ;;;;;;;;;;;;;;;;;;;

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
AvailableLocalLinear    MACRO
	UserGate available_local_linear_nr
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

;;;;;;;;;;; PAGING ;;;;;;;;;;;;;;

; IN  EAX     	Size
; IN  BX		Owner
; IN  EDX      	Flat offset
ReservePeMem MACRO
	UserGate reserve_pe_mem_nr
						ENDM

; IN  EAX		New size
; IN  ECX		Old size
; IN  EDX		Flat offset
; OUT EDX		Flat offset
ResizeFlatLinear	MACRO
	UserGate resize_flat_linear_nr
					ENDM

; IN  EAX		Number of bytes
; IN  EDX		Flat offset
SetFlatLinearValid	MACRO
	UserGate set_flat_linear_valid_nr
					ENDM

; IN  EAX		Number of bytes
; IN  EDX		Flat offset
SetFlatLinearInvalid	MACRO
	UserGate set_flat_linear_invalid_nr
					ENDM

; IN  EAX		Number of bytes
; IN  EDX		Flat offset
SetFlatLinearRead	MACRO
	UserGate set_flat_linear_read_nr
					ENDM

; IN  EAX		Number of bytes
;	EDX			Flat offset
SetFlatLinearReadWrite	MACRO
	UserGate set_flat_linear_readwrite_nr
					ENDM

;;;;;;;;;;;; INTERRUPT & EXCEPTION ;;;;;;;;;;;

; OUT BX:CX		V86 address to use to switch to Prot mode
; OUT SI:(E)DI	Prot mode address to use to switch to V86.
GetRawSwitchAds	MACRO
	UserGate get_raw_switch_ads_nr
					ENDM

; IN  AX		New DS
; IN  CX		New ES
; IN  DX		New SS
; IN  (E)BX		New (E)SP
; IN  SI		New CS
; IN  (E)DI		New (E)IP
RawSwitch       MACRO
	UserGate raw_switch_nr
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
; OUT ES:(E)DI	Int vector
GetPMInt    MACRO
	UserGate get_pm_int_nr
						ENDM

; IN  AL        Int #
; IN  ES:(E)DI  Int vector
SetPMInt    MACRO
	UserGate set_pm_int_nr
						ENDM

; IN  AL		Int #
; OUT DX:BX		Int vector
GetVMInt	MACRO
	UserGate get_vm_int_nr
					ENDM

; IN  AL		Int #
; IN  DX:BX		Int vector
SetVMInt	MACRO
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

TerminateThread        MACRO
	UserGate terminate_thread_nr
						ENDM

; OUT AX		Thread handle
GetThread	MACRO
	UserGate get_thread_nr
					ENDM

Swap       MACRO
	UserGate swap_nr
						ENDM

;;;;;;;;; CRITICAL SECTIONS ;;;;;;;;;;;;

; OUT BX		Section handle
CreateUserSection	MACRO
	UserGate create_user_section_nr
					ENDM

; OUT BX		Section handle
CreateBlockedUserSection	MACRO
	UserGate create_blocked_user_section_nr
					ENDM

; IN  BX		Section handle
DeleteUserSection	MACRO
	UserGate delete_user_section_nr
					ENDM

; IN  BX		Section handle
EnterUserSection	MACRO
	UserGate enter_user_section_nr
					ENDM

; IN  BX		Section handle
LeaveUserSection	MACRO
	UserGate leave_user_section_nr
					ENDM

;;;;;;;;;;; IPC ;;;;;;;;;;;;;;;

;	IN  ES:(E)DI	Mailslot name
;	OUT BX			Mailslot handle
GetLocalMailslot		MACRO
	UserGate get_local_mailslot_nr
			ENDM

;	IN  EDX			IP address
;	IN  ES:(E)DI	Mailslot name
;	OUT BX			Mailslot handle
GetRemoteMailslot		MACRO
	UserGate get_remote_mailslot_nr
			ENDM

;	IN  BX			Mailslot handle
FreeMailslot		MACRO
	UserGate free_mailslot_nr
			ENDM

;	IN  BX				Mailslot handle
;	IN  DS:(E)SI		Message buffer
;	IN  (E)CX			Message size
;	IN  ES:(E)DI		Reply buffer
;	IN  (E)AX			Max reply size
;	IN  EDX				Timeout in milliseconds
;	OUT (E)CX			Reply size
SendMailslot		MACRO
	UserGate send_mailslot_nr
			ENDM

;	IN  (E)CX			Max message size
;	IN  ES:(E)DI		Mailslot name
DefineMailslot		MACRO
	UserGate define_mailslot_nr
			ENDM

;	IN  ES:(E)DI		Message buffer
;	OUT (E)CX			Size
ReceiveMailslot		MACRO
	UserGate receive_mailslot_nr
			ENDM

;	IN  ES:(E)DI		Reply buffer
;	IN  (E)CX			Reply size
ReplyMailslot		MACRO
	UserGate reply_mailslot_nr
			ENDM

;;;;;;;;;;;; PROGRAMS & DLLS ;;;;;;;;;;;;;;;;

EmsHandler	MACRO
	UserGate ems_handler_nr
					ENDM

XmsHandler	MACRO
	UserGate xms_handler_nr
					ENDM

; IN  DS:(E)SI	Program name
; IN  ES:(E)DI	Command line
LoadExe	MACRO
	UserGate load_exe_nr
					ENDM

; IN  DS:(E)SI	Program name
; IN  ES:(E)DI	Command line
; IN  FS:(E)BX	Startup directory & drive
; IN  EDX		Debug thread handle
; OUT AX		Thread handle
; OUT DX		Application handle
SpawnExe	MACRO
	UserGate spawn_exe_nr
					ENDM

; IN  AX		Exit code
UnloadExe	MACRO
	UserGate unload_exe_nr
					ENDM

; OUT AX		Exit code
GetExitCode	MACRO
	UserGate get_exit_code_nr
					ENDM

; OUT ES:(E)DI	Program name
GetExeName	MACRO
	UserGate get_exe_name_nr
					ENDM

; OUT ES:(E)DI	Command line
GetCmdLine	MACRO
	UserGate get_cmd_line_nr
					ENDM

; OUT ES:(E)DI	Environment
GetEnvironment	MACRO
	UserGate get_env_nr
					ENDM

; IN  ES:(E)DI	DLL name
; OUT (E)BX		DLL handle
LoadDll	MACRO
	UserGate load_dll_nr
					ENDM

; IN  (E)BX		DLL handle
FreeDll	MACRO
	UserGate free_dll_nr
					ENDM

; IN  (E)BX		DLL handle
; IN  ES:(E)DI	Proc name
; OUT DS:(E)SI	Proc address
GetDllProc	MACRO
	UserGate get_dll_proc_nr
					ENDM

; IN  (E)BX		DLL handle
; IN  (E)AX		Resource handle
; IN  (E)DX		Resource type
; OUT DS:(E)SI	Resource address
GetDllResource	MACRO
	UserGate get_dll_resource_nr
					ENDM

; IN  (E)BX		DLL handle
; IN  (E)CX		Max name size
; IN  ES:(E)DI	DLL name buffer
; OUT (E)AX		Bytes copied
GetDllName	MACRO
	UserGate get_dll_name_nr
					ENDM

; IN  ES:(E)DI	DLL name
; OUT (E)BX		DLL handle
GetDll	MACRO
	UserGate get_dll_nr
					ENDM

; IN  EAX     		Number of bytes
; OUT ES / (E)DX    Selector or linear base address (depends on loader)
AllocateAppMem     MACRO
	UserGate allocate_app_mem_nr
						ENDM

; IN  ES / (E)DX    Selector or linear base address (depends on loader)
FreeAppMem     MACRO
	UserGate free_app_mem_nr
						ENDM

; OUT BX			PSP Selector
GetPspSel	MACRO
	UserGate get_psp_sel_nr
					ENDM

;;;;;;;;;;;;;; DEBUGGING ;;;;;;;;;;;

; IN  ES:(E)DI        TSS data buffer
; IN  AX              Thread ID
GetDebugTss     MACRO
	UserGate get_debug_tss_nr
						ENDM

; OUT AX               Thread ID
GetDebugThread MACRO
	UserGate get_debug_thread_nr
						ENDM

DebugTrace      MACRO
	UserGate debug_trace_nr
						ENDM

DebugPace       MACRO
	UserGate debug_pace_nr
						ENDM

DebugGo MACRO
	UserGate debug_go_nr
						ENDM

DebugNext       MACRO
	UserGate debug_next_nr
						ENDM

; IN  ES:(E)DI   	State buffer
; IN  AX           	Thread #
GetState     MACRO
	UserGate get_state_nr
						ENDM

; IN  AX            Thread #
Pause     MACRO
	UserGate pause_nr
						ENDM

;  IN  EAX	Timeout in milliseconds
;  IN  EDI	Event record
WaitForPeDebug MACRO
	UserGate wait_for_pe_debug_nr
						ENDM

;  IN  EAX	Thread ID
;  IN  EBX	Process ID
;  IN  EDX	Status
ContinuePeDebug MACRO
	UserGate continue_pe_debug_nr
						ENDM

;  IN  EBP	Exception frame
;  IN  EAX	Exception code
NotifyPeException MACRO
	UserGate notify_pe_exception_nr
						ENDM

;  IN  (E)CX	Number of bytes
;  IN  DX:ESI	Address to read at
;  IN  ES:(E)DI	Buffer
;  IN  BX		Thread
;  OUT (E)AX	Bytes read
ReadThreadMem	MACRO
	UserGate read_thread_mem_nr
					ENDM

;  IN  (E)CX	Number of bytes
;  IN  DX:ESI	Address to write at
;  IN  ES:(E)DI	Buffer
;  IN  BX		Thread
;  OUT (E)AX	Bytes written
WriteThreadMem	MACRO
	UserGate write_thread_mem_nr
					ENDM

;  IN  ES:(E)DI	Buffer
;  IN  BX		Thread
GetThreadTss	MACRO
	UserGate get_thread_tss_nr
					ENDM

;  IN  ES:(E)DI	Buffer
;  IN  BX		Thread
SetThreadTss	MACRO
	UserGate set_thread_tss_nr
					ENDM

;;;;;;;;;;; TIME & DATE ;;;;;;;;;;;;;

; IN  BX			Thread handle
; OUT EDX:EAX		Used CPU time
GetCpuTime	MACRO
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

TimeToSystemTime   MACRO
	UserGate time_to_system_time_nr
					ENDM

; IN  EDX:EAX         System time
; OUT EDX:EAX         Real time
SystemTimeToTime   MACRO
	UserGate system_time_to_time_nr
					ENDM

; IN  DX		Year
; IN  CH		Month
; OUT AL		Days in month
DaysInMonth	MACRO
	UserGate days_in_month_nr
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
	UserGate adjust_time_nr
				ENDM

; IN  DX		Year
; IN  CH		Month
; IN  CL		Day
; OUT AX		Passed days
PassedDays	MACRO
	UserGate passed_days_nr
				ENDM


; IN  DX		Year
; IN  CH		Month
; IN  CL		Day
; IN  BH		Hour
; IN  BL		Minute
; IN  AH		Seconds
; OUT EDX:EAX	Binary time
TimeToBinary	MACRO
	UserGate time_to_binary_nr
				ENDM

; IN  EDX:EAX	Binary time
; OUT DX		Year
; OUT CH		Month
; OUT CL		Day
; OUT BH		Hour
; OUT BL		Minute
; OUT AH		Seconds
BinaryToTime	MACRO
	UserGate binary_to_time_nr
				ENDM

SyncTime		MACRO
	UserGate sync_time_nr
			ENDM

;;;;;;;;;;; CONSOLE ;;;;;;;;;;;

; IN  AL      	Switch key
EnableFocus     MACRO
	UserGate enable_focus_nr
						ENDM

; IN  AL    	Switch key
SetFocus        MACRO
	UserGate set_focus_nr
						ENDM

;;;;;;;;;;;;; NETWORK ;;;;;;;;;;;

; OUT EAX		Primary DNS IP address (or 0)
; OUT EDX		Secondary DNS IP address (or 0)
GetDns	MACRO
	UserGate get_dns_nr
				ENDM

; OUT EAX		Primary DNS IP address (or 0)
; OUT EDX		Secondary DNS IP address (or 0)
GetPppDns	MACRO
	UserGate get_ppp_dns_nr
				ENDM

; IN  EAX		Timeout in milliseconds for connection
; IN  ECX		buffer size
; IN  EDX		ip address
; IN  SI		local port (0 for dynamic port)
; IN  DI		remote port
; OUT BX		connection handle
OpenTcpConnection	MACRO
	UserGate open_tcp_connection_nr
			ENDM

; IN  ECX			buffer size
; IN  SI			local port
; IN  ES:(E)DI	callback upon new connection
ListenTcpPort	MACRO
	UserGate listen_tcp_port_nr
			ENDM

; IN  BX		connection handle
; IN  EAX		timeout in milliseconds
WaitForTcpConnection	MACRO
	UserGate wait_for_tcp_connection_nr
			ENDM

; IN  BX		connection handle
CloseTcpConnection	MACRO
	UserGate close_tcp_connection_nr
			ENDM

; IN  BX		connection handle
DeleteTcpConnection	MACRO
	UserGate delete_tcp_connection_nr
			ENDM

; IN  BX		connection handle
IsTcpConnectionClosed	MACRO
	UserGate is_tcp_connection_closed_nr
			ENDM

; IN  BX		connection handle
AbortTcpConnection	MACRO
	UserGate abort_tcp_connection_nr
			ENDM

; IN  EAX			timeout in ms for receive
; IN  BX			connection handle
; IN  (E)CX		wanted number of bytes
; IN  ES:E(DI)	data buffer
; OUT (E)AX		size of received data
ReadTcpConnection	MACRO
	UserGate read_tcp_connection_nr
			ENDM

; IN  BX			connection handle
; IN  (E)CX		buffer size
; IN  ES:(E)DI	data buffer
WriteTcpConnection		MACRO
	UserGate write_tcp_connection_nr
			ENDM

; IN  BX		connection handle
PushTcpConnection		MACRO
	UserGate push_tcp_connection_nr
			ENDM

; OUT EDX		My IP address
GetIpAddress	MACRO
	UserGate get_ip_address_nr
						ENDM

; IN  ES:(E)DI		Host name
; OUT EDX			IP address
NameToIP		MACRO
	UserGate name_to_ip_nr
			ENDM

; IN  EDX				IP address
; IN  (E)CX			Size of buffer
; IN  ES:(E)DI		Host name buffer
; OUT (E)AX			Length of host name
IPToName		MACRO
	UserGate ip_to_name_nr
			ENDM

; IN  EAX				Timeout in ms
; IN  EDX				IP address
Ping		MACRO
	UserGate ping_nr
			ENDM

;;;;;;;;;;;;; LOW-LEVEL DISCS ;;;;;;;;;;;;;

;	IN	AL			Disc #
;	OUT	CX			Bytes / sector
;	OUT	EDX			Total # of sectors
;	OUT SI			BIOS sectors / cylinder
;	OUT DI			BIOS heads
GetDiscInfo     MACRO
	UserGate get_disc_info_nr
						ENDM

;	IN	AL			Disc #
;	IN	EDX			Start sector
;	IN	ECX			Number of sectors
;	IN	ES:(E)DI	File system name
FormatDrive     MACRO
	UserGate format_drive_nr
						ENDM

;	IN DS:(E)SI		Main key buffer
;	IN ES:(E)DI		Selection key buffer
;	IN GS:(E)BX		Extent size buffer
GetRdfsInfo     MACRO
	UserGate get_rdfs_info_nr
						ENDM

;	IN	AL			Disc #
;	IN	EDX			Sector #
;	IN	(E)CX		Size
;	IN	ES:(E)DI	Buffer
ReadDisc     MACRO
	UserGate read_disc_nr
						ENDM

;	IN	AL			Disc #
;	IN	EDX			Sector #
;	IN	(E)CX		Size
;	IN	ES:(E)DI	Buffer
WriteDisc     MACRO
	UserGate write_disc_nr
						ENDM

;	IN	AL			Drive #
;	OUT	EAX			Free units
;	OUT	CX			bytes / unit
;	OUT	EDX			total # of units
GetDriveInfo     MACRO
	UserGate get_drive_info_nr
						ENDM

;;;;;;;;;;;;;; DIRECTORY ;;;;;;;;;;;;;

; 	IN	AL              Drive #
SetCurDrive     MACRO
	UserGate set_cur_drive_nr
						ENDM

;	OUT	AL              Drive #
GetCurDrive     MACRO
	UserGate get_cur_drive_nr
						ENDM


;	IN	ES:(E)DI      	Pathname
SetCurDir       MACRO
	UserGate set_cur_dir_nr
						ENDM

;	IN	AL              Drive
;	IN	ES:(E)DI        Pathname
GetCurDir       MACRO
	UserGate get_cur_dir_nr
						ENDM

;	IN	ES:(E)DI        Pathname
MakeDir MACRO
	UserGate make_dir_nr
						ENDM

;	IN	ES:(E)DI        Pathname
RemoveDir       MACRO
	UserGate remove_dir_nr
						ENDM

;	IN	DS:(E)SI		Old pathname
;	IN	ES:(E)DI        New pathname
RenameFile      MACRO
	UserGate rename_file_nr
						ENDM

;	IN	ES:(E)DI        Pathname
DeleteFile      MACRO
	UserGate delete_file_nr
						ENDM

;	IN	ES:(E)DI        Pathname
;	IN	CX              File attribute
GetFileAttribute        MACRO
	UserGate get_file_attribute_nr
						ENDM

;	IN	ES:(E)DI        Pathname
;	IN	CX              File attribute
SetFileAttribute        MACRO
	UserGate set_file_attribute_nr
						ENDM


;	IN	ES:(E)DI		Pathname
;	OUT	BX				Handle
OpenDir   MACRO
	UserGate open_dir_nr
						ENDM

;	IN	BX				Handle
CloseDir   MACRO
	UserGate close_dir_nr
						ENDM

;	IN	BX				Handle
;	IN	DX				Entry #
;	IN	CX				Max size of name
;	IN	ES:(E)DI		Buffer
;	OUT	ECX				Filesize
;	OUT	BX				File attribute
;	OUT	EDX:EAX			File systemtime
ReadDir        MACRO
	UserGate read_dir_nr
						ENDM

;;;;;;;;;;;;;; FILES ;;;;;;;;;;;;;

;	IN	ES:(E)DI	Pathname
;	IN	CL			Access mode
;	OUT	BX			Handle
OpenFile        MACRO
	UserGate open_file_nr
						ENDM

;	IN	ES:(E)DI	Pathname
;	IN	CX     		Attribute
;	OUT	BX        	Handle
CreateFile      MACRO
	UserGate create_file_nr
						ENDM

;	IN	BX   		Handle
CloseFile       MACRO
	UserGate close_file_nr
						ENDM

;	IN	AX			Old handle
;	OUT	BX			New handle
DuplFile       MACRO
	UserGate dupl_file_nr
						ENDM

;	IN	BX   		Handle
;	OUT	DX  		Device data
GetIoctlData    MACRO
	UserGate get_ioctl_data_nr
						ENDM


;	IN	BX 			Handle
;	OUT	EAX 		Filesize
GetFileSize     MACRO
	UserGate get_file_size_nr
						ENDM


;	IN	BX			Handle
;	IN	EAX			Filesize
SetFileSize     MACRO
	UserGate set_file_size_nr
						ENDM


;	IN	BX			Handle
;	IN	EAX			File position
GetFilePos      MACRO
	UserGate get_file_pos_nr
						ENDM


;	IN	BX			Handle
;	IN	EAX			File position
SetFilePos      MACRO
	UserGate set_file_pos_nr
						ENDM

;	IN	BX			Handle
;	OUT	EDX:EAX		File system time
GetFileTime      MACRO
	UserGate get_file_time_nr
						ENDM

;	IN	BX			Handle
;	IN	EDX:EAX		File system time
SetFileTime      MACRO
	UserGate set_file_time_nr
						ENDM

;	IN	BX      	Handle
;	IN	ES:(E)DI	Buffer
;	IN	(E)CX		Number of bytes to read
;	OUT	(E)AX 		Number of bytes read
ReadFile        MACRO
	UserGate read_file_nr
						ENDM

;	IN	BX    		Handle
;	IN	ES:(E)DI 	Buffer
;	IN	(E)CX		Number of bytes to write
; 	OUT (E)AX 		Number of bytes written
WriteFile       MACRO
	UserGate write_file_nr
						ENDM

;   IN  (E)CX       Number of chars
;   IN  ES:(E)DI    Buffer
;   OUT (E)AX       Number of chars read
ReadConsole     MACRO
	UserGate read_con_nr
						ENDM

;;;;;;;;;;; MEMORY MAPPING ;;;;;;;;;;

;	IN EAX			Size of mapping object
;	OUT BX			Handle
CreateMapping        MACRO
	UserGate create_mapping_nr
						ENDM

;	IN EAX			Size of mapping object
;	IN ES:(E)DI 	Name for mapping
;	OUT BX			Handle
CreateNamedMapping        MACRO
	UserGate create_named_mapping_nr
						ENDM

;	IN EAX			Size of mapping object
;	IN BX			File handle
;	OUT BX			Handle
CreateFileMapping        MACRO
	UserGate create_file_mapping_nr
						ENDM

;	IN EAX			Size of mapping object
;	IN BX			File handle
;	IN ES:(E)DI 	Name of mapping
;	OUT BX			Handle
CreateNamedFileMapping        MACRO
	UserGate create_named_file_mapping_nr
						ENDM

;	IN	ES:(E)DI 	Name of mapping
;	OUT BX			Handle
OpenNamedMapping        MACRO
	UserGate open_named_mapping_nr
						ENDM

;	IN  BX			Handle
SyncMapping        MACRO
	UserGate sync_mapping_nr
						ENDM

;	IN  BX			Handle
CloseMapping        MACRO
	UserGate close_mapping_nr
						ENDM

;	IN  EAX			Offset into object
;	IN  BX			Handle
;	IN	(E)CX		Size
;	IN  ES:(E)DI	Address to map at
MapView        MACRO
	UserGate map_view_nr
						ENDM

;	IN  BX			Handle
UnmapView        MACRO
	UserGate unmap_view_nr
						ENDM

;;;;;;;;;;; KEYBOARD ;;;;;;;;;;;;;

; OUT  AX			Character read
ReadKeyboard    MACRO
	UserGate read_keyboard_nr
						ENDM

PollKeyboard    MACRO
	UserGate poll_keyboard_nr
						ENDM

FlushKeyboard   MACRO
	UserGate flush_keyboard_nr
						ENDM

; IN  ES:(E)DI	Callback
;		AL		Char
;		AH		Scan code
;		CX		Keyboard state
;		DX		Virtual key code
HookKeyboard    MACRO
	UserGate hook_keyboard_nr
						ENDM

UnhookKeyboard    MACRO
	UserGate unhook_keyboard_nr
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

;	IN  AX			start x
;	IN  BX			start y
;   IN  CX          end x
;   IN  DX          end y
SetMouseWindow    MACRO
	UserGate set_mouse_window_nr
						ENDM

;	IN  CX           mickeys in x-direction
;	IN  DX           mickeys in y-direction
SetMouseMickey    MACRO
	UserGate set_mouse_mickey_nr
						ENDM

;		NC			button is pressed
GetLeftButton    MACRO
	UserGate get_left_button_nr
						ENDM

;		NC			button is pressed
GetRightButton    MACRO
	UserGate get_right_button_nr
						ENDM

;	OUT CX              x
;	OUT DX              y
GetLeftButtonPressPosition    MACRO
	UserGate get_left_button_press_position_nr
						ENDM

;	OUT CX              x
;	OUT DX              y
GetRightButtonPressPosition    MACRO
	UserGate get_right_button_press_position_nr
						ENDM

;	OUT CX              x
;	OUT DX              y
GetLeftButtonReleasePosition    MACRO
	UserGate get_left_button_release_position_nr
						ENDM

;	OUT CX              x
;	OUT DX              y
GetRightButtonReleasePosition    MACRO
	UserGate get_right_button_release_position_nr
						ENDM

;	IN  ES:(E)DI	Callback
;			AX		Buttons
;			CX		Delta x movement
;			DX		Delta y movement
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

;	IN  DX		basadress till com port
;	IN  AL		irq till com port
;	IN  AH		# of data bits
;	IN  BL		# of stop bits
;	IN  BH		parity ('N', 'E' or 'O')
;	IN  CX		baudrate divisor
;	IN  SI		size of transmit buffer
;	IN  DI		size of receive buffer
;	OUT BX		port handle
OpenCom       MACRO
	UserGate open_com_nr
						ENDM

;	IN  BX		port handle
CloseCom       MACRO
	UserGate close_com_nr
						ENDM

;	IN  BX		port handle
FlushCom       MACRO
	UserGate flush_com_nr
						ENDM

;	IN  BX		port handle
;	OUT AX		number of char in buffer
PollCom       MACRO
	UserGate poll_com_nr
						ENDM

;	IN  BX		port handle
;	IN  EAX		timeout in ms
WaitForCom       MACRO
	UserGate wait_for_com_nr
						ENDM

;	IN  BX		port handle
;	OUT AX		data read or -1
ReadCom       MACRO
	UserGate read_com_nr
						ENDM

;	IN  BX		port handle
;	OUT AL		data to send
WriteCom       MACRO
	UserGate write_com_nr
						ENDM

;	IN  BX		port handle
SetDtr       MACRO
	UserGate set_dtr_nr
						ENDM

;	IN  BX		port handle
ResetDtr       MACRO
	UserGate reset_dtr_nr
						ENDM

;;;;;;;;;;;;;; PRINTER ;;;;;;;;;;;;

;	IN  DX		PRINTER #
InitPrinter       MACRO
	UserGate init_printer_nr
						ENDM

;	IN  DX		PRINTER #
;   OUT AL		PRINTER STATUS
CheckPrinter       MACRO
	UserGate check_printer_nr
						ENDM

;	IN  DX		PRINTER #
;	IN  AL		CHARACTER
WritePrinter       MACRO
	UserGate write_printer_nr
						ENDM

;;;;;;;;;; SCREEN, TEXT MODE ;;;;;;;;;;

;	IN  CX              Column number (x)
;	IN  DX              Row number (y)
SetCursorPosition    MACRO
	UserGate set_cursor_position_nr
						ENDM

;	OUT CX              Column number (x)
;	OUT DX              Row number (y)
GetCursorPosition    MACRO
	UserGate get_cursor_position_nr
						ENDM

;	IN  AL              Char
WriteChar       MACRO
	UserGate write_char_nr
						ENDM

;	IN  ES:(E)DI           Null terminated string
WriteAsciiz     MACRO
	UserGate write_asciiz_nr
						ENDM

;	IN  ES:(E)DI           Buffer
;   IN  (E)CX              Count
WriteSizeString MACRO
	UserGate write_size_string_nr
						ENDM

;;;;;;;;;;; SCREEN, GRAPHICS MODE ;;;;;;;;;;

;	IN  AX		Requested mode
SetVideoMode      MACRO
	UserGate set_video_mode_nr
						ENDM

SetVgaMode      MACRO
	UserGate set_vga_mode_nr
						ENDM

;	IN  AL              Color number
SetForeColor        MACRO
	UserGate set_forecolor_nr
						ENDM

;	IN  AL              Color number. 0FFh is transparent
SetBackColor        MACRO
	UserGate set_backcolor_nr
						ENDM

;	IN  AX              Requested font height
SetFont        MACRO
	UserGate set_font_nr
						ENDM

;	IN  AL				Char to ask about
;	OUT CX				Width of char
GetCharWidth        MACRO
	UserGate get_char_width_nr
						ENDM

;	IN  ES:E(DI)		String to ask about
;	OUT CX				Width of string
GetStringWidth        MACRO
	UserGate get_string_width_nr
						ENDM

;	IN  AX		start x
;	IN  BX		start y
;	IN  CX		end x
;	IN  DX		end y
FillRect      MACRO
	UserGate fill_rect_nr
						ENDM

;	IN  AX		start x
;	IN  BX		start y
;	IN  CX		end x
;	IN  DX		end y
;	IN  ES:EDI	bitmap
DrawMono      MACRO
	UserGate draw_mono_nr
						ENDM

;	IN  AL			char
;	IN  CX			x position
;	IN  DX			y position
DrawChar      MACRO
	UserGate draw_char_nr
						ENDM

;	IN  CX			x position
;	IN  DX			y position
;	IN  ES:(E)DI	String to draw
DrawString      MACRO
	UserGate draw_string_nr
						ENDM

