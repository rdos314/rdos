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

UserGateVm      MACRO gate_nr
	db 0Fh
	db 0Bh
	cmpsw
	dw gate_nr
			ENDM

UserGate16      MACRO gate_nr
	db 9Ah
	dw 0
	dw 2803h + (gate_nr SHL 4)
			ENDM

UserGate32      MACRO gate_nr
	db 66h
	db 9Ah
	dw 0
	dw 280Bh + (gate_nr SHL 4)
			ENDM

UserGateForce32 MACRO gate_nr
	db 9Ah
	dw 0
	dw 280Bh + (gate_nr SHL 4)
			ENDM

UserGate        MACRO gate_nr
IF GateSize EQ 16
	UserGate16 gate_nr
ELSE
	IF GateSize EQ 32
		UserGate32 gate_nr
	ELSE
		UserGateVm gate_nr
	ENDIF
ENDIF
			ENDM

; EAX     		Number of bytes
; ES / (E)DX    Selector or linear base address (depends on loader)
AllocateAppMem     MACRO
	UserGate allocate_app_mem_nr
						ENDM

; ES / (E)DX    Selector or linear base address (depends on loader)
FreeAppMem     MACRO
	UserGate free_app_mem_nr
						ENDM

;       EAX     ANTAL BYTE
;       ES      LINEAR BASE ADDRESS
AllocateDosMem  MACRO
	UserGate allocate_dos_mem_nr
						ENDM

;       EAX     ANTAL BYTE
;       ES      LINEAR BASE ADDRESS
AllocateLocalMem        MACRO
	UserGate allocate_local_mem_nr
						ENDM

;       ES              SELECTOR
FreeMem MACRO
	UserGate free_mem_nr
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

;       EAX      SIZE
;		BX		 OWNER
;       EDX      FLAT OFFSET ADDRESS
ReservePeMem MACRO
	UserGate reserve_pe_mem_nr
						ENDM

;	EAX		ANTAL BYTE
;	EDX		FLAT OFFSET ADDRESS
SetFlatLinearValid	MACRO
	UserGate set_flat_linear_valid_nr
					ENDM

;	EAX		ANTAL BYTE
;	EDX		FLAT OFFSET ADDRESS
SetFlatLinearInvalid	MACRO
	UserGate set_flat_linear_invalid_nr
					ENDM

;	EAX		ANTAL BYTE
;	EDX		FLAT OFFSET ADDRESS
SetFlatLinearRead	MACRO
	UserGate set_flat_linear_read_nr
					ENDM

;	EAX		ANTAL BYTE
;	EDX		FLAT OFFSET ADDRESS
SetFlatLinearReadWrite	MACRO
	UserGate set_flat_linear_readwrite_nr
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

;       EAX     ANTAL BYTE
AvailableLocalLinear    MACRO
	UserGate available_local_linear_nr
						ENDM

;       EAX     ANTAL BYTE
UsedLocalLinear MACRO
	UserGate used_local_linear_nr
						ENDM

;       EAX     ANTAL BYTE
AvailableVMLinear       MACRO
	UserGate available_vm_linear_nr
						ENDM

;       EAX     ANTAL BYTE
UsedVMLinear    MACRO
	UserGate used_vm_linear_nr
						ENDM

;       AX              ANTAL MILLISEKUNDER
WaitMilliSec        MACRO
	UserGate wait_milli_nr
						ENDM

;       AX              ANTAL MIKROSEKUNDER
WaitMicroSec        MACRO
	UserGate wait_micro_nr
						ENDM

;       EDX:EAX         TIDPUNKT FôR èTERSTART
WaitUntil       MACRO
	UserGate wait_until_nr
						ENDM

;	BX			PSP SELECTOR
GetPspSel	MACRO
	UserGate get_psp_sel_nr
					ENDM

;       AL              PRIORITET
;       AH              MODE, 0=PM, 1=VM
;       (E)CX           STACK SIZE
;       DS:(E)SI        ADDRESS TO START AT
;       ES:(E)DI        THREAD NAME
CreateThread   MACRO
	UserGate create_thread_nr
						ENDM

TerminateThread        MACRO
	UserGate terminate_thread_nr
						ENDM

;	AX			AKTUELL TRèD
GetThread	MACRO
	UserGate get_thread_nr
					ENDM

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

;	BX			Thread
;	EDX:EAX		Used CPU time
GetCpuTime	MACRO
	UserGate get_cpu_time_nr
					ENDM

;       ES:(E)DI        STATE RETURNED
;       AX              THREAD #
;		NC				THREAD EXISTS
GetState     MACRO
	UserGate get_state_nr
						ENDM

;       AX              THREAD #
;		NC				PAUSED
Pause     MACRO
	UserGate pause_nr
						ENDM

;       ES:(E)DI        TSS DATA RETURNED
;       AX              THREAD ID
GetDebugTss     MACRO
	UserGate get_debug_tss_nr
						ENDM

;       AX               THREAD ID
GetDebugThread MACRO
	UserGate get_debug_thread_nr
						ENDM

;       BX                THREAD ID
;       AX                SELECTOR / ORDINAL SEGMENT #
TranslateSymbolSegment  MACRO
	UserGate translate_symbol_segment_nr
						ENDM

;       BX                  THREAD ID
;       AX                  FILE HANDLE
GetSymbolHandle MACRO
	UserGate get_symbol_handle_nr
						ENDM

;       BX                  THREAD ID
;       ES                  SYMBOL DIR
;       CX                  NUMBER OF DIRS
GetSymbolDirs   MACRO
	UserGate get_symbol_dir_nr
						ENDM

;       BX                    THREAD ID
;       ES                    SYMBOL SEGMENTS
;       CX                    NUMBER OF SEGMENTS
GetSymbolSegments       MACRO
	UserGate get_symnol_segment_nr
						ENDM

;       BX                     THREAD ID
;       ES                     SYMBOL LINES
;       CX                     NUMBER OF LINENUMBERS
GetSymbolLines  MACRO
	UserGate get_symnol_line_nr
						ENDM

;       BX                      THREAD ID
;       ES                      SYMBOL PROCEDURES
;       CX                      NUMBER OF PROCEDURES
GetSymboProcedures      MACRO
	UserGate get_symnol_procedure_nr
						ENDM

;       BX                      THREAD ID
;       ES                      SYMBOL TYPES
;       CX                      NUMBER OF TYPES
GetSymboTypes   MACRO
	UserGate get_symnol_type_nr
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

Swap       MACRO
	UserGate swap_nr
						ENDM

;       AL                      EXCEPTION NR
;       ES:(E)DI        EXCEPTION PROCEDURE
GetException      MACRO
	UserGate get_exception_nr
						ENDM

;       AL                      EXCEPTION NR
;       ES:(E)DI        EXCEPTION PROCEDURE
SetException      MACRO
	UserGate set_exception_nr
						ENDM

;       AL                      INT NR
;       ES:(E)DI	 	       INT PROCEDURE
GetPMInt    MACRO
	UserGate get_pm_int_nr
						ENDM

;       AL                      INT NR
;       ES:(E)DI        INT PROCEDURE
SetPMInt    MACRO
	UserGate set_pm_int_nr
						ENDM

;	AL			INT NUMMER
;	DX:BX		ADDRESS
GetVMInt	MACRO
	UserGate get_vm_int_nr
					ENDM

;	DX:BX		ADDRESS
;	AL			INT NUMMER
SetVMInt	MACRO
	UserGate set_vm_int_nr
					ENDM

;       AL                      INT NUMBER
;       CX                      WORDS TO COPY
;       DS:(E)SI        OFFSET TO PARAMETERS
;       ES:(E)DI        OFFSET TO VM_CALL_STRUC
DpmiInt   MACRO
	UserGate dpmi_int_nr
					ENDM

;       CX                      WORDS TO COPY
;       DS:(E)SI        OFFSET TO PARAMETERS
;       ES:(E)DI        OFFSET TO VM_CALL_STRUC
DpmiCallInt       MACRO
	UserGate dpmi_call_int_nr
					ENDM

;       CX                      WORDS TO COPY
;       DS:(E)SI        OFFSET TO PARAMETERS
;       ES:(E)DI        OFFSET TO VM_CALL_STRUC
DpmiCall  MACRO
	UserGate dpmi_call_nr
					ENDM

;       DS:(E)SI        CALLBACK PROCEDURE
;       ES:(E)DI        OFFSET TO VM_CALL_STRUC
;       DX:AX           VM CALL ADDRESS
AllocateVMCallback      MACRO
	UserGate allocate_vm_callback_nr
					ENDM

;       DX:AX           VM CALL ADDRESS
FreeVMCallback  MACRO
	UserGate free_vm_callback_nr
					ENDM

;       EDX:EAX         System time
GetSystemTime   MACRO
	UserGate get_system_time_nr
					ENDM

;       EDX:EAX         Real time
GetTime   MACRO
	UserGate get_time_nr
					ENDM

;       EDX:EAX         Real time / System time
TimeToSystemTime   MACRO
	UserGate time_to_system_time_nr
					ENDM

;       EDX:EAX         System time / Real time
SystemTimeToTime   MACRO
	UserGate system_time_to_time_nr
					ENDM

;	DX		YEAR
;	CH		MONTH
;	AL		DAYS IN MONTH
DaysInMonth	MACRO
	UserGate days_in_month_nr
				ENDM

;	DX		YEAR
;	CH		MONTH
;	CL		DAY
;	BH		HOUR
;	BL		MINUTE
;	AH		SECONDS
AdjustTime	MACRO
	UserGate adjust_time_nr
				ENDM

;	DX		YEAR
;	CH		MONTH
;	CL		DAY
;	AX		ANTAL DAGAR
PassedDays	MACRO
	UserGate passed_days_nr
				ENDM


;	DX		YEAR
;	CH		MONTH
;	CL		DAY
;	BH		HOUR
;	BL		MINUTE
;	AH		SECONDS
;	EDX:EAX	BINARY TIME
TimeToBinary	MACRO
	UserGate time_to_binary_nr
				ENDM

;	DX		YEAR
;	CH		MONTH
;	CL		DAY
;	BH		HOUR
;	BL		MINUTE
;	AH		SECONDS
;	EDX:EAX	BINARY TIME
BinaryToTime	MACRO
	UserGate binary_to_time_nr
				ENDM

;	AX		Requested mode
SetVideoMode      MACRO
	UserGate set_video_mode_nr
						ENDM

;       AL              CHAR
;       AH              ATTRIBUTE
;       DL              ROW
;       DH              KOLUMN
DisplayChar     MACRO
	UserGate display_char_nr
						ENDM

SetTextMode     MACRO
	UserGate set_text_mode_nr
						ENDM

TextMode        MACRO
	UserGate text_mode_nr
			ENDM

SetVgaMode      MACRO
	UserGate set_vga_mode_nr
						ENDM

;       AL              Page number
SetPage MACRO
	UserGate set_page_nr
						ENDM

ShowMouse    MACRO
	UserGate show_mouse_nr
						ENDM

HideMouse    MACRO
	UserGate hide_mouse_nr
						ENDM

;       CX              x
;       DX              y
GetMousePosition    MACRO
	UserGate get_mouse_position_nr
						ENDM

;       CX              x
;       DX              y
SetMousePosition    MACRO
	UserGate set_mouse_position_nr
						ENDM

;		AX			start x
;		BX			start y
;       CX          end x
;       DX          end y
SetMouseWindow    MACRO
	UserGate set_mouse_window_nr
						ENDM

;       CX           mickeys in x-direction
;       DX           mickeys in y-direction
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

;       CX              x
;       DX              y
GetLeftButtonPressPosition    MACRO
	UserGate get_left_button_press_position_nr
						ENDM

;       CX              x
;       DX              y
GetRightButtonPressPosition    MACRO
	UserGate get_right_button_press_position_nr
						ENDM

;       CX              x
;       DX              y
GetLeftButtonReleasePosition    MACRO
	UserGate get_left_button_release_position_nr
						ENDM

;       CX              x
;       DX              y
GetRightButtonReleasePosition    MACRO
	UserGate get_right_button_release_position_nr
						ENDM

;	ES:(E)DI	Callback
;		AX		Buttons
;		CX		Delta x movement
;		DX		Delta y movement
HookMouse    MACRO
	UserGate hook_mouse_nr
						ENDM

UnhookMouse    MACRO
	UserGate unhook_mouse_nr
						ENDM

;       CX              Column number (x)
;       DX              Row number (y)
SetCursorPosition    MACRO
	UserGate set_cursor_position_nr
						ENDM

;       CX              Column number (x)
;       DX              Row number (y)
GetCursorPosition    MACRO
	UserGate get_cursor_position_nr
						ENDM

;       AL              Color number
SetForeColor        MACRO
	UserGate set_forecolor_nr
						ENDM

;       AL              Color number. 0FFh is transparent
SetBackColor        MACRO
	UserGate set_backcolor_nr
						ENDM

;       AX              Requested font height
SetFont        MACRO
	UserGate set_font_nr
						ENDM

;       AL				Char to ask about
;		CX				Width of char
GetCharWidth        MACRO
	UserGate get_char_width_nr
						ENDM

;      	ES:E(DI)		String to ask about
;		CX				Width of string
GetStringWidth        MACRO
	UserGate get_string_width_nr
						ENDM

;		AX		start x
;		BX		start y
;		CX		end x
;		DX		end y
FillRect      MACRO
	UserGate fill_rect_nr
						ENDM

;		AX		start x
;		BX		start y
;		CX		end x
;		DX		end y
;		ES:EDI	bitmap
DrawMono      MACRO
	UserGate draw_mono_nr
						ENDM

;		AL			char
;		CX			x position
;		DX			y position
DrawChar      MACRO
	UserGate draw_char_nr
						ENDM

;		CX			x position
;		DX			y position
;		ES:(E)DI	String to draw
DrawString      MACRO
	UserGate draw_string_nr
						ENDM

;       AL              Char
WriteChar       MACRO
	UserGate write_char_nr
						ENDM

;       ES:DI           Null terminerad strÑng
WriteAsciiz     MACRO
	UserGate write_asciiz_nr
						ENDM

;       ES:DI           StrÑng
;       CX                      Antal tecken
WriteSizeString MACRO
	UserGate write_size_string_nr
						ENDM

;       AX = CHAR
ReadKeyboard    MACRO
	UserGate read_keyboard_nr
						ENDM

;       NC              CHAR IN BUFFER
;       CY              BUFFER EMPTY
PollKeyboard    MACRO
	UserGate poll_keyboard_nr
						ENDM

FlushKeyboard   MACRO
	UserGate flush_keyboard_nr
						ENDM

;	ES:(E)DI	Callback
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

;       AX		Keyboard states.
GetKeyboardState    MACRO
	UserGate get_keyboard_state_nr
						ENDM

;       (E)CX           NUMBER OF CHARS
;       ES:(E)DI        BUFFER
;       (E)AX           NUMBER OF CHARS READ
ReadConsole     MACRO
	UserGate read_con_nr
						ENDM

;       AL              SWITCH KEY
EnableFocus     MACRO
	UserGate enable_focus_nr
						ENDM

;       AL              SWITCH KEY
SetFocus        MACRO
	UserGate set_focus_nr
						ENDM

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

;       AX              EVENT NR
;       DS:DI   NAME OF EVENT
RegisterEvent   MACRO
	UserGate register_event_nr
						ENDM


;       CX              SIZE OF EVENT LIST SEG
InitEventThread        MACRO
	UserGate init_event_thread_nr
						ENDM


;       AX              EVENT_NR
;       BX              HANDLE / ID
RegisterEventThread    MACRO
	UserGate register_event_thread_nr
						ENDM

WaitEvent       MACRO
	UserGate wait_event_nr
						ENDM

;       AX              EVENT NR
;       EDX             DATA
GlobalEvent     MACRO
	UserGate global_event_nr
						ENDM

;       AX              EVENT NR
;       BX              THREAD ID
;       EDX             DATA
FireEvent       MACRO
	UserGate fire_event_nr
						ENDM

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

;		ES:(E)DI		Buffer of data to send
SendSerial	MACRO
	UserGate send_serial_nr
			ENDM

;		ES:(E)DI		Buffer for received data
ReceiveSerial	MACRO
	UserGate receive_serial_nr
			ENDM

ResetSerial	MACRO
	UserGate reset_serial_nr
			ENDM

;       AL              NODE #
GetSerialNode	MACRO
	UserGate get_serial_node_nr
			ENDM

;       AL              Serial state
GetSerialState	MACRO
	UserGate get_serial_state_nr
			ENDM

;       AL              Serial activity
GetSerialActivity	MACRO
	UserGate get_serial_activity_nr
			ENDM

;	DS:(E)SI	NAME OF FILE
;	ES:(E)DI	COMMAND LINE
;	NC			OK
;	CY			FAIL
LoadExe	MACRO
	UserGate load_exe_nr
					ENDM

;	AX			Exit code
UnloadExe	MACRO
	UserGate unload_exe_nr
					ENDM

;	AX			Exit code
GetExitCode	MACRO
	UserGate get_exit_code_nr
					ENDM

;	ES:(E)DI	EXE FILE NAME
GetExeName	MACRO
	UserGate get_exe_name_nr
					ENDM

;	ES:(E)DI	COMMAND LINE
GetCmdLine	MACRO
	UserGate get_cmd_line_nr
					ENDM

;	ES:(E)DI	ENVIRONMENT
GetEnvironment	MACRO
	UserGate get_env_nr
					ENDM

; IN  DS:(E)SI	Program name
; IN  ES:(E)DI	Command line
; IN  FS:(E)BX	Startup directory & drive
; IN  EDX		Bit 0 = debug flag
; OUT AX		Thread handle
; OUT DX		Application handle
SpawnExe	MACRO
	UserGate spawn_exe_nr
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

;	IN	AL			DISC #
;	OUT	CX			BYTES / SECTOR
;	OUT	EDX			TOTAL # OF SECTORS
;	OUT SI			BIOS SECTORS / CYL
;	OUT DI			BIOS HEADS
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

;	IN	AL			DRIVE NR
;	OUT	EAX			FREE UNITS
;	OUT	CX			BYTES / UNIT
;	OUT	EDX			TOTAL # OF UNITS
;	OUT NC			SUCCESS
GetDriveInfo     MACRO
	UserGate get_drive_info_nr
						ENDM

; 	IN	AL              DRIVE NR
SetCurDrive     MACRO
	UserGate set_cur_drive_nr
						ENDM

;	OUT	AL              DRIVE NR
GetCurDrive     MACRO
	UserGate get_cur_drive_nr
						ENDM


;	IN	ES:(E)DI                PATH NAME
SetCurDir       MACRO
	UserGate set_cur_dir_nr
						ENDM

;	IN	AL                      DRIVE
;	IN	ES:(E)DI                PATH NAME
GetCurDir       MACRO
	UserGate get_cur_dir_nr
						ENDM

;	IN	ES:(E)DI                PATH NAME
MakeDir MACRO
	UserGate make_dir_nr
						ENDM

;	IN	ES:(E)DI                PATH NAME
RemoveDir       MACRO
	UserGate remove_dir_nr
						ENDM

;	IN	DS:(E)SI				CURRENT NAME
;	IN	ES:(E)DI                NEW NAME
RenameFile      MACRO
	UserGate rename_file_nr
						ENDM

;	IN	ES:(E)DI                PATH NAME
DeleteFile      MACRO
	UserGate delete_file_nr
						ENDM

;	IN	ES:(E)DI                PATH NAME
;	IN	CX                      FILE ATTRIBUTE
GetFileAttribute        MACRO
	UserGate get_file_attribute_nr
						ENDM

;	IN	ES:(E)DI                PATH NAME
;	IN	CX                      FILE ATTRIBUTE
SetFileAttribute        MACRO
	UserGate set_file_attribute_nr
						ENDM


;	IN	ES:(E)DI	PATH NAME
;	OUT	BX			HANDLE TO DIR
OpenDir   MACRO
	UserGate open_dir_nr
						ENDM

;	IN	BX			HANDLE TO DIR
CloseDir   MACRO
	UserGate close_dir_nr
						ENDM

;	IN	BX			HANDLE TO DIR
;	IN	DX			ENTRY #
;	IN	CX			MAX SIZE OF FILENAME
;	IN	ES:(E)DI	BUFFER
;	OUT	ECX			FILE SIZE
;	OUT	BX			FILE ATTRIBUTE
;	OUT	EDX:EAX		FILE TIME/DATE
ReadDir        MACRO
	UserGate read_dir_nr
						ENDM


;	IN	ES:(E)DI	FILENAME
;	IN	CL			ACCESS CODE
;	OUT	BX			FILE HANDLE
OpenFile        MACRO
	UserGate open_file_nr
						ENDM

;	IN	ES:(E)DI	FILENAME
;	IN	CX     		ATTRIBUTE
;	OUT	BX        	HANDLE
CreateFile      MACRO
	UserGate create_file_nr
						ENDM

;	IN	BX   		HANDLE
CloseFile       MACRO
	UserGate close_file_nr
						ENDM

;	IN	AX			OLD FILE HANDLE
;	OUT	BX			NEW FILE HANDLE
DuplFile       MACRO
	UserGate dupl_file_nr
						ENDM

;	IN	BX   		HANDLE
;	OUT	DX  		DEVICE DATA
GetIoctlData    MACRO
	UserGate get_ioctl_data_nr
						ENDM


;	IN	BX 			HANDLE
;	OUT	EAX 		FILE SIZE
GetFileSize     MACRO
	UserGate get_file_size_nr
						ENDM


;	IN	BX			HANDLE
;	IN	EAX			FILE SIZE
SetFileSize     MACRO
	UserGate set_file_size_nr
						ENDM


;	IN	BX			HANDLE
;	IN	EAX			FILE POSITION
GetFilePos      MACRO
	UserGate get_file_pos_nr
						ENDM


;	IN	BX			HANDLE
;	IN	EAX			FILE POSITION
SetFilePos      MACRO
	UserGate set_file_pos_nr
						ENDM

;	IN	BX			FILE HANDLE
;	OUT	EDX:EAX		CURRENT FILE TIME
GetFileTime      MACRO
	UserGate get_file_time_nr
						ENDM

;	IN	BX			FILE HANDLE
;	IN	EDX:EAX		CURRENT FILE TIME
SetFileTime      MACRO
	UserGate set_file_time_nr
						ENDM

;	IN	ES:(E)DI	BUFFER
;	IN	BX      	HANDLE
;	IN	(E)CX		NUMBER OF BYTES TO READ
;	OUT	(E)AX 		NUMBER OF BYTES READ
ReadFile        MACRO
	UserGate read_file_nr
						ENDM

;	IN	ES:(E)DI 	BUFFER
;	IN	BX    		HANDLE
;	IN	(E)CX		NUMBER OF BYTES TO WRITE
; 	OUT (E)AX 		NUMBER OF BYTES WRITTEN
WriteFile       MACRO
	UserGate write_file_nr
						ENDM

;	IN EAX			SIZE OF MAPPING OBJECT
;	OUT BX			MAPPING HANDLE
CreateMapping        MACRO
	UserGate create_mapping_nr
						ENDM

;	IN EAX			SIZE OF MAPPING OBJECT
;	IN ES:(E)DI 	MAPPING NAME
;	OUT BX			MAPPING HANDLE
CreateNamedMapping        MACRO
	UserGate create_named_mapping_nr
						ENDM

;	IN EAX			SIZE OF MAPPING OBJECT
;	IN BX			FILE HANDLE
;	OUT BX			MAPPING HANDLE
CreateFileMapping        MACRO
	UserGate create_file_mapping_nr
						ENDM

;	IN EAX			SIZE OF MAPPING OBJECT
;	IN BX			FILE HANDLE
;	IN ES:(E)DI 	MAPPING NAME
;	OUT BX			MAPPING HANDLE
CreateNamedFileMapping        MACRO
	UserGate create_named_file_mapping_nr
						ENDM

;	IN	ES:(E)DI 	MAPPING NAME
;	OUT BX			MAPPING HANDLE
OpenNamedMapping        MACRO
	UserGate open_named_mapping_nr
						ENDM

;	IN  BX			MAPPING HANDLE
SyncMapping        MACRO
	UserGate sync_mapping_nr
						ENDM


;	IN  BX			MAPPING HANDLE
CloseMapping        MACRO
	UserGate close_mapping_nr
						ENDM

;	IN  EAX			OFFSET
;	IN  BX			MAPPING HANDLE
;	IN	(E)CX		SIZE
;	IN  ES:(E)DI	ADDRESS TO MAP AT
MapView        MACRO
	UserGate map_view_nr
						ENDM

;	IN  BX			MAPPING HANDLE
UnmapView        MACRO
	UserGate unmap_view_nr
						ENDM

;	DX		PRINTER #
;   NC		OK
InitPrinter       MACRO
	UserGate init_printer_nr
						ENDM

;	DX		PRINTER #
;   AL		PRINTER STATUS
CheckPrinter       MACRO
	UserGate check_printer_nr
						ENDM

;	DX		PRINTER #
;	AL		CHARACTER
;   NC		OK
WritePrinter       MACRO
	UserGate write_printer_nr
						ENDM

;	DX		basadress till com port
;	AL		irq till com port
;	AH		# of data bits
;	BL		# of stop bits
;	BH		parity ('N', 'E' or 'O')
;	CX		baudrate divisor
;	SI		size of transmit buffer
;	DI		size of receive buffer
;	BX		port handle
OpenCom       MACRO
	UserGate open_com_nr
						ENDM

;	BX		port handle
CloseCom       MACRO
	UserGate close_com_nr
						ENDM

;	BX		port handle
FlushCom       MACRO
	UserGate flush_com_nr
						ENDM

;	BX		port handle
;	AX		number of char in buffer
PollCom       MACRO
	UserGate poll_com_nr
						ENDM

;	BX		port handle
;	EAX		timeout in ms
WaitForCom       MACRO
	UserGate wait_for_com_nr
						ENDM

;	BX		port handle
;	AX		data read or -1
ReadCom       MACRO
	UserGate read_com_nr
						ENDM

;	BX		port handle
;	AL		data to send
WriteCom       MACRO
	UserGate write_com_nr
						ENDM

;	BX		port handle
SetDtr       MACRO
	UserGate set_dtr_nr
						ENDM

;	BX		port handle
ResetDtr       MACRO
	UserGate reset_dtr_nr
						ENDM


;	DX		basadress till cbus port
;	AL		irq till cbus port
OpenCbus       MACRO
	UserGate open_cbus_nr
						ENDM

CloseCbus       MACRO
	UserGate close_cbus_nr
						ENDM

FlushCbus       MACRO
	UserGate flush_cbus_nr
						ENDM

PollCbus       MACRO
	UserGate poll_cbus_nr
						ENDM

ReadCbus       MACRO
	UserGate read_cbus_nr
						ENDM

;	AL		char to write
WriteCbus       MACRO
	UserGate write_cbus_nr
						ENDM

;	EAX		Primary DNS IP address (or 0)
;	EDX		Secondary DNS IP address (or 0)
GetDns	MACRO
	UserGate get_dns_nr
				ENDM

;	EAX		Primary DNS IP address (or 0)
;	EDX		Secondary DNS IP address (or 0)
GetPppDns	MACRO
	UserGate get_ppp_dns_nr
				ENDM

;	EAX		Timeout in milliseconds for connection
;	ECX		buffer size
;	EDX		ip address
;	SI		local port (0 for dynamic port)
;	DI		remote port
;	NC		ok
;	BX		connection handle
OpenTcpConnection	MACRO
	UserGate open_tcp_connection_nr
			ENDM

;	ECX			buffer size
;	SI			local port
;	ES:(E)DI	callback upon new connection
ListenTcpPort	MACRO
	UserGate listen_tcp_port_nr
			ENDM

;	BX		connection handle
;	EAX		timeout in milliseconds
WaitForTcpConnection	MACRO
	UserGate wait_for_tcp_connection_nr
			ENDM

;	BX		connection handle
CloseTcpConnection	MACRO
	UserGate close_tcp_connection_nr
			ENDM

;	BX		connection handle
DeleteTcpConnection	MACRO
	UserGate delete_tcp_connection_nr
			ENDM

;	BX		connection handle
IsTcpConnectionClosed	MACRO
	UserGate is_tcp_connection_closed_nr
			ENDM

;	BX		connection handle
AbortTcpConnection	MACRO
	UserGate abort_tcp_connection_nr
			ENDM

;	EAX			timeout in ms for receive
;	BX			connection handle
;	(E)CX		wanted number of bytes
;	ES:E(DI)	data buffer
;	NC			ok
;	(E)AX		size of received data
;	CY			connection closed
ReadTcpConnection	MACRO
	UserGate read_tcp_connection_nr
			ENDM

;	BX			connection handle
;	(E)CX		buffer size
;	ES:(E)DI	data buffer
;	NC			ok
;	CY			connection closed
WriteTcpConnection		MACRO
	UserGate write_tcp_connection_nr
			ENDM

;	BX		connection handle
PushTcpConnection		MACRO
	UserGate push_tcp_connection_nr
			ENDM

;	EDX		My IP address
GetIpAddress	MACRO
	UserGate get_ip_address_nr
						ENDM

;	ES:(E)DI		Host name
;	EDX				IP address
NameToIP		MACRO
	UserGate name_to_ip_nr
			ENDM

;	EDX				IP address
;	(E)CX			Size of buffer
;	ES:(E)DI		Host name buffer
;	(E)AX			Length of host name
IPToName		MACRO
	UserGate ip_to_name_nr
			ENDM

;	EAX				Timeout in ms
;	EDX				IP address
Ping		MACRO
	UserGate ping_nr
			ENDM

SyncTime		MACRO
	UserGate sync_time_nr
			ENDM

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

; IN  CX		Column
; IN  DX		Row
NewSetCursorPosition	MACRO
	UserGate new_set_cursor_position_nr
			ENDM

; OUT CX		Column
; OUT DX		Row
NewGetCursorPosition	MACRO
	UserGate new_get_cursor_position_nr
			ENDM

; IN  AL		Char
NewWriteChar	MACRO
	UserGate new_write_char_nr
			ENDM

; IN  ES:(E)DI	Null terminated string
NewWriteString	MACRO
	UserGate new_write_string_nr
			ENDM

;       ES:DI           Null terminerad strÑng
NewWriteAsciiz     MACRO
	UserGate new_write_asciiz_nr
						ENDM

;       ES:DI           StrÑng
;       CX                      Antal tecken
NewWriteSizeString MACRO
	UserGate new_write_size_string_nr
						ENDM

;       AL              Color number
NewSetForeColor        MACRO
	UserGate new_set_forecolor_nr
						ENDM

;       AL              Color number. 0FFh is transparent
NewSetBackColor        MACRO
	UserGate new_set_backcolor_nr
						ENDM
