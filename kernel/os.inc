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

OsGate16	MACRO gate_nr
	db 9Ah
	dw 0
	dw 1800h + (gate_nr SHL 3)
			ENDM

OsGate32	MACRO gate_nr
	db 66h
	db 9Ah
	dw 0
	dw 1800h + (gate_nr SHL 3)
			ENDM

OsGate	MACRO gate_nr
IF GateSize EQ 32
	OsGate32 gate_nr
ELSE
	OsGate16 gate_nr
ENDIF
			ENDM


;	AX		GATE NUMBER
;	DS:SI	GATE CALL ADDRESS
;	ES:DI	GATE NAME ADDRESS
RegisterOsGate	MACRO
	OsGate register_osgate_nr

					ENDM

;	AX		GATE NUMBER
IsValidOsGate	MACRO
	OsGate is_valid_osgate_nr

					ENDM

;	AX		GATE NUMBER
;	DS:SI	GATE CALL ADDRESS
;	ES:DI	GATE NAME ADDRESS
RegisterUserGate	MACRO
	OsGate register_usergate_nr
						ENDM

;	AX		GATE NUMBER
;	DS:SI	GATE CALL ADDRESS
;	ES:DI	GATE NAME ADDRESS
RegisterUserGate16	MACRO
	OsGate register_usergate16_nr
						ENDM

;	AX		GATE NUMBER
;	DS:ESI	GATE CALL ADDRESS
;	ES:EDI	GATE NAME ADDRESS
RegisterUserGate32	MACRO
	OsGate register_usergate32_nr
						ENDM

;	AX		GATE NUMBER
;	DX		SEGMENT TRANSFER 
;	DS:SI	GATE CALL ADDRESS
;	DS:DI	GATE NAME ADDRESS
RegisterVirtGate	MACRO
	OsGate register_virtgate_nr
					ENDM

;	AX		GATE NUMBER IN USERGATE
;	BX		GATE NUMBER IN VIRTGATE
;	DX		SEGMENT TRANSFER 
;	DS:SI	GATE CALL ADDRESS
;	DS:DI	GATE NAME ADDRESS
RegisterVirtUserGate	MACRO
	OsGate register_vugate_nr
					ENDM

;	BX		DESCRIPTOR
;	EDX		BASE
;	ECX		LIMIT
CreateDataSelector16	MACRO
	OsGate create_data_sel16_nr
					ENDM

;	BX		DESCRIPTOR
;	EDX		BASE
;	ECX		LIMIT
CreateDataSelector32	MACRO
	OsGate create_data_sel32_nr
					ENDM

;	BX		DESCRIPTOR
;	EDX		BASE
;	ECX		LIMIT
CreateCodeSelector16	MACRO
	OsGate create_code_sel16_nr
					ENDM

;	BX		DESCRIPTOR
;	EDX		BASE
;	ECX		LIMIT
CreateCodeSelector32	MACRO
	OsGate create_code_sel32_nr
					ENDM

;	BX		DESCRIPTOR
;	EDX		BASE
;	ECX		LIMIT
CreateConformSelector16	MACRO
	OsGate create_conform_sel16_nr
					ENDM

;	BX		DESCRIPTOR
;	EDX		BASE
;	ECX		LIMIT
CreateConformSelector32	MACRO
	OsGate create_conform_sel32_nr
					ENDM

;	BX		DESCRIPTOR
;	EDX		BASE
;	CX		LIMIT
CreateLdtSelector	MACRO
	OsGate create_ldt_sel_nr
					ENDM

;	BX		DESCRIPTOR
;	EDX		BASE
;	ECX		LIMIT
CreateTssSelector	MACRO
	OsGate create_tss_sel_nr
					ENDM

;	BX		DESCRIPTOR
;	DS:SI	ENTRY POINT
;	CL		16-BIT WORDS TO MOVE
CreateCallGateSelector16	MACRO
	OsGate create_call_gate_sel16_nr
							ENDM

;	BX		DESCRIPTOR
;	DS:ESI	ENTRY POINT
;	CL		32-BIT WORDS TO MOVE
CreateCallGateSelector32	MACRO
	OsGate create_call_gate_sel32_nr
							ENDM

;	BX		DESCRIPTOR
;	DX		TSS SELECTOR
CreateTaskGateSelector	MACRO
	OsGate create_task_gate_sel_nr
							ENDM

;	AL		INT #
;	BL		DPL
;	DS:ESI	ENTRY POINT
CreateIntGateSelector	MACRO
	OsGate create_int_gate_sel_nr
							ENDM

;	AL		INT #
;	BL		DPL
;	DS:ESI	ENTRY POINT
CreateTrapGateSelector	MACRO
	OsGate create_trap_gate_sel_nr
							ENDM

;	BX		CODE SELECTOR
InitDevice	MACRO
	OsGate init_device_nr
					ENDM

;	EAX		ANTAL BYTES
;	ES		SELECTOR
AllocateGlobalMem	MACRO
	OsGate allocate_global_mem_nr
					ENDM

;	EAX		ANTAL BYTES
;	ES		SELECTOR
AllocateSmallGlobalMem	MACRO
	OsGate allocate_small_global_mem_nr
					ENDM

;	EAX	ANTAL BYTE
;	ES	LINEAR BASE ADDRESS
AllocateSmallMem	MACRO
	OsGate allocate_small_mem_nr
					ENDM

;	EAX	ANTAL BYTE
;	ES	LINEAR BASE ADDRESS
AllocateBigMem	MACRO
	OsGate allocate_big_mem_nr
					ENDM

;	ES		SELECTOR
AllocatePage	MACRO
	OsGate allocate_page_nr
					ENDM

;	ES		SELECTOR
;	EAX		PHYSICAL ADDRESS
FreePage	MACRO
	OsGate free_page_nr
					ENDM

;	ES:DI		PROCEDURE
;	EDX:EAX		TID FôR ANROP
;	BX			TIMER THREAD (OWNER)
;	CX			DATA
StartTimer	MACRO
	OsGate start_timer_nr
					ENDM

;	BX			TIMER THREAD (OWNER)
StopTimer	MACRO
	OsGate stop_timer_nr
					ENDM

;	EDX:EAX		Difference between real time and system time
UpdateTime	MACRO
	OsGate update_time_nr
					ENDM

UpdateRtc	MACRO
	OsGate update_rtc_nr
					ENDM

;	EDX:EAX		SYSTEM TIME
SetSystemTime	MACRO
	OsGate set_system_time_nr
					ENDM

;       AL              PRIORITET
;       AH              MODE, 0=PM, 1=VM
;       ECX             STACK SIZE
;       DS:ESI          ADDRESS TO START AT
;       ES:EDI          PROCESS NAME
CreateProcess    MACRO
	OsGate create_process_nr
						ENDM

;	DS:SI		TRèD
;	AX			STATUS TILL TRèD
Wake	MACRO
	OsGate wake_thread_nr
					ENDM

;	DS:DI	SOVLISTA
;	AX		DATA
Sleep	MACRO
	OsGate sleep_thread_nr
					ENDM

;	DS:ESI		TRèD
;	AX			STATUS TILL TRèD
Wake32	MACRO
	OsGate wake32_thread_nr
					ENDM

;	DS:EDI	SOVLISTA
;	AX		DATA
Sleep32	MACRO
	OsGate sleep32_thread_nr
					ENDM

ClearSignal	MACRO
	OsGate clear_signal_nr
					ENDM

;	BX			THREAD TO SIGNAL
Signal	MACRO
	OsGate signal_nr
					ENDM

WaitForSignal	MACRO
	OsGate wait_for_signal_nr
					ENDM

;	BX			TRèD
;	DX			SELECTOR / SEGMENT
;	ESI			OFFSET
;	NC	ES		SELECTOR
;		CX		SIZE
;	CY	AX		ERRORCODE
;			!	FATAL ERROR
;			?	SELECTOR ERROR
;			%	NO PAGE ALLOCATED
AllocateAliasMem	MACRO
	OsGate allocate_alias_mem_nr
					ENDM

DebugCall	MACRO
	OsGate debug_call_nr
					ENDM

DebugBreak	MACRO
	OsGate debug_break_nr
					ENDM

ReflectException	MACRO
	OsGate reflect_exception_nr
					ENDM

;	AX		CODE16 SEL
;	BX		CODE32 SEL
;	SI		OFFSET TO INIT PROC
AliasCode32	MACRO
	OsGate alias_code32_nr
					ENDM

SimSti	MACRO
	OsGate sim_sti_nr
					ENDM

SimCli	MACRO
	OsGate sim_cli_nr
					ENDM

;	AX		FLAGS
GetFlags	MACRO
	OsGate sim_get_flags_nr
					ENDM

;	AX		FLAGS
SetFlags	MACRO
	OsGate sim_set_flags_nr
					ENDM

QueryXms	MACRO
	OsGate query_xms_nr
					ENDM

QueryDpmi	MACRO
	OsGate query_dpmi_nr
					ENDM

QueryDpmi16	MACRO
	OsGate query_dpmi16_nr
					ENDM

;	BX		LDT DESCRIPTOR
;	DS		LDT SELECTOR
AllocateLdt	MACRO
	OsGate allocate_ldt_nr
					ENDM

;	BX		LDT DESCRIPTOR
FreeLdt	MACRO
	OsGate free_ldt_nr
					ENDM

;	CX		ANTAL
;	BX		LDT DESCRIPTOR
AllocateMultipleLdt	MACRO
	OsGate allocate_multiple_ldt_nr
					ENDM

;	BX		GDT DESCRIPTOR
AllocateGdt	MACRO
	OsGate allocate_gdt_nr
					ENDM

;	BX		GDT DESCRIPTOR
FreeGdt	MACRO
	OsGate free_gdt_nr
					ENDM

;	ES		SELECTOR
FreeSelector	MACRO
	OsGate free_selector_nr
						ENDM

;	EAX	ANTAL BYTE
;	EDX	LINEAR BASE ADDRESS
;	CX	ANTAL SIDOR
AllocateBigLinear	MACRO
	OsGate allocate_big_linear_nr
					ENDM

;	EAX	ANTAL BYTE
;	EDX	LINEAR BASE ADDRESS
AllocateSmallLinear	MACRO
	OsGate allocate_small_linear_nr
					ENDM

;	EAX	ANTAL BYTE
;	NC	EDX	LINEAR BASE ADDRESS
;	CY	AL FELORSAK
AllocateDosLinear	MACRO
	OsGate allocate_dos_linear_nr
					ENDM

;	EDX	LINEAR BASE ADDRESS
;	CY	AL FELORSAK
FreeDosLinear	MACRO
	OsGate free_dos_linear_nr
					ENDM

;	EAX	NEW SIZE
;	EDX	LINEAR BASE ADDRESS
;	CY	AL FELORSAK
ResizeDosLinear	MACRO
	OsGate resize_dos_linear_nr
					ENDM

;	EAX	ANTAL BYTE
;	EDX STôRSTA BLOCK
AvailableDosLinear	MACRO
	OsGate available_dos_linear_nr
					ENDM

;	EAX	ANTAL BYTE
;	EDX	LINEAR BASE ADDRESS
AllocateLocalLinear	MACRO
	OsGate allocate_local_linear_nr
					ENDM

;	EAX	ANTAL BYTE
;	EDX	LINEAR BASE ADDRESS
ReserveLocalLinear	MACRO
	OsGate reserve_local_linear_nr
					ENDM

;	EAX	ANTAL BYTE
;	EDX	LINEAR BASE ADDRESS
AllocateVMLinear	MACRO
	OsGate allocate_vm_linear_nr
					ENDM

;	ECX		SIZE
;	EDX		LINEAR BASE ADDRESS
FreeLinear	MACRO
	OsGate free_linear_nr
					ENDM

;	EAX		NEW SIZE
;	ECX		OLD SIZE
;	EDX		LINEAR BASE ADDRESS
ResizeLinear	MACRO
	OsGate resize_linear_nr
					ENDM

;	EAX		ANTAL BYTES
AvailableBigLinear	MACRO
	OsGate available_big_linear_nr
					ENDM

;	EAX		ANTAL BYTES
AvailableSmallLinear	MACRO
	OsGate available_small_linear_nr
					ENDM

;	EAX		ANTAL BYTES
UsedBigLinear	MACRO
	OsGate used_big_linear_nr
					ENDM

;	EAX		ANTAL BYTES
UsedSmallLinear	MACRO
	OsGate used_small_linear_nr
					ENDM

;	EAX		ANTAL BYTES
UsedLocalLinearThread	MACRO
	OsGate used_local_linear_thread_nr
					ENDM

;	AX	SELECTOR
;	NC	EAX	SEGEMENT
;	CY	EAX = F000
SelectorToSegment	MACRO
	OsGate selector_to_segment_nr
					ENDM

;	BX	SEGMENT / SELECTOR
SegmentToSelector	MACRO
	OsGate segment_to_selector_nr
					ENDM
	
;	EAX		ANTAL BYTES
;	EDX		LINJéR ADDRESS
AllocateThreadLinear	MACRO
	OsGate allocate_thread_linear_nr
					ENDM

;	EAX		ANTAL BYTES
;	EDX		LINJéR ADDRESS
AllocateProcessLinear	MACRO
	OsGate allocate_process_linear_nr
					ENDM

;	EAX		ANTAL BYTES
;	EDX		LINJéR ADDRESS
AllocateSystemLinear	MACRO
	OsGate allocate_system_linear_nr
					ENDM

;	EAX		ANTAL BYTES
;	EDX		LINJéR ADDRESS
AllocateFixedVMLinear	MACRO
	OsGate allocate_fixed_vm_linear_nr
					ENDM

;	AX		Focus thread
GetFocusThread	MACRO
	OsGate get_focus_thread_nr
					ENDM

;	EAX		ANTAL BYTES
;	EDX		BAS ADDRESS
AllocateFocusLinear	MACRO
	OsGate allocate_focus_linear_nr
					ENDM

;	EAX		# BYTES
;	EDX		BASE ADDRESS
AllocateFixedAppLinear	MACRO
	OsGate allocate_fixed_app_linear_nr
					ENDM
	
;	EAX		ANTAL BYTES
;	BX		SELECTOR IN
;	ES		SELECTOR UT
AllocateFixedThreadMem	MACRO
	OsGate allocate_fixed_thread_mem_nr
					ENDM

;	EAX		ANTAL BYTES
;	BX		SELECTOR IN
;	ES		SELECTOR UT
AllocateFixedProcessMem	MACRO
	OsGate allocate_fixed_process_mem_nr
					ENDM

;	EAX		ANTAL BYTES
;	BX		SELECTOR IN
;	ES		SELECTOR UT
AllocateFixedSystemMem	MACRO
	OsGate allocate_fixed_system_mem_nr
					ENDM

;	EAX		ANTAL BYTES
;	BX		LOCAL SELECTOR IN
;	DX		FOCUS SELECTOR IN
;	ES		LOCAL SELECTOR UT
AllocateFixedFocusMem	MACRO
	OsGate allocate_fixed_focus_mem_nr
					ENDM
	
;	EAX		ANTAL BYTES
;	BX		SELECTOR IN
;	ES		SELECTOR UT
AllocateFixedAppMem	MACRO
	OsGate allocate_fixed_app_mem_nr
					ENDM

;	EAX		FYSISK ADDRESS
AllocatePhysical	MACRO
	OsGate allocate_physical_nr
					ENDM

;	EAX		FYSISK ADDRESS
FreePhysical	MACRO
	OsGate free_physical_nr
					ENDM

;	EAX		ANTAL BYTE LEDIGT MINNE
GetFreePhysical	MACRO
	OsGate get_free_physical_nr
					ENDM

;	EDX		LINEAR ADDRESS
;	EAX		PAGE ENTRY
GetPhysicalPage	MACRO
	OsGate get_physical_page_nr
					ENDM

;	EDX		LINEAR ADDRESS
;	EAX		PAGE ENTRY
SetPhysicalPage	MACRO
	OsGate set_physical_page_nr
					ENDM

;	BX		TRèD
;	EDX		LINEAR ADDRESS
;	EAX		PAGE ENTRY
GetThreadPhysicalPage	MACRO
	OsGate get_thread_physical_page_nr
					ENDM

;	BX		TRèD
;	EDX		LINEAR ADDRESS
;	EAX		PAGE ENTRY
SetThreadPhysicalPage	MACRO
	OsGate set_thread_physical_page_nr
					ENDM

;	DX:ESI	ADDRESS TO READ
;	BX		TRèD
;	NC		VALID
;	AL		DATA OR ERROR REASON
ReadThreadSelector	MACRO
	OsGate read_thread_selector_nr
					ENDM

;	DX:ESI	ADDRESS TO WRITE
;	BX		TRèD
;	NC		VALID
;	AL		DATA TO WRITE
WriteThreadSelector	MACRO
	OsGate write_thread_selector_nr
					ENDM

;	DX:ESI	ADDRESS TO READ
;	BX		TRèD
;	NC		VALID
;	AL		DATA OR ERROR REASON
ReadThreadSegment	MACRO
	OsGate read_thread_segment_nr
					ENDM

;	DX:ESI	ADDRESS TO WRITE
;	BX		TRèD
;	NC		VALID
;	AL		DATA TO WRITE
WriteThreadSegment	MACRO
	OsGate write_thread_segment_nr
					ENDM

;	AL		PRIORITET
;	FS:BX	TASK GATE SELECTOR IN IDT OR GDT
;	DS:SI	START ADDRESS OF TASK
;	ES:DI	TASK NAME	
CreateTask	MACRO
	OsGate create_task_nr
					ENDM

;	AX			CALLING THREAD
InitTask	MACRO
	OsGate init_task_nr
					ENDM

;	AX			CALLING THREAD
WaitRunTask	MACRO
	OsGate wait_run_task_nr
					ENDM

;	AX			CALLING THREAD
;	DS:DI		SOVLISTA
WaitSleepTask	MACRO
	OsGate wait_sleep_task_nr
					ENDM

;	AX			THREAD TO DEBUG
ChangeEnviroment	MACRO
	OsGate change_enviroment_nr
					ENDM

;	ES:DI		ADDRESS TILL CALLBACK
HookCreateThread	MACRO
	OsGate hook_create_thread_nr
					ENDM


;	ES:DI		ADDRESS TILL CALLBACK
HookCreateProcess	MACRO
	OsGate hook_create_process_nr
					ENDM


;	ES:DI		ADDRESS TILL CALLBACK
HookInitTasking	MACRO
	OsGate hook_init_tasking_nr
					ENDM

;	ES:DI		ADDRESS TO CALLBACK
HookOpenApp	MACRO
	OsGate hook_open_app_nr
					ENDM

;	ES:DI		ADDRESS TO CALLBACK
HookCloseApp	MACRO
	OsGate hook_close_app_nr
					ENDM

;	ES:DI		ADDRESS TILL CALLBACK
;	DX			PORT NUMMER
HookIn	MACRO
	OsGate hook_in_nr
					ENDM

;	ES:DI		ADDRESS TILL CALLBACK
;	DX			PORT NUMMER
HookOut	MACRO
	OsGate hook_out_nr
					ENDM

;	ES:DI		PROCEDURE TO CALL
HookState	MACRO
	OsGate hook_state_nr
					ENDM

;	AL			IRQ NR
;	DS			DATA PASSED TO HANDLER
;	ES:DI		HANDLER ADDRESS
RequestPrivateIrqHandler	MACRO
	OsGate request_private_irq_handler_nr
					ENDM

;	AL			IRQ NR
ReleasePrivateIrqHandler	MACRO
	OsGate release_private_irq_handler_nr
					ENDM

InitMouse	MACRO
	OsGate init_mouse_nr
					ENDM

;	AX		Button status
;	CX		Delta X
;	DX		Delta Y
UpdateMouse	MACRO
	OsGate update_mouse_nr
					ENDM

;	ES:DI		HANDLER ADDRESS
HookLoadExe	MACRO
	OsGate hook_load_exe_nr
					ENDM

;	ES:DI		HANDLER ADDRESS
HookLoadDosExe	MACRO
	OsGate hook_load_dos_exe_nr
					ENDM

;	AL			16 or 32 bit app
SetBitness	MACRO
	OsGate set_bitness_nr
					ENDM

OpenApp	MACRO
	OsGate open_app_nr
					ENDM

CloseApp	MACRO
	OsGate close_app_nr
					ENDM

;	BX			Offset to context on locked stack
SaveContext	MACRO
	OsGate save_context_nr
					ENDM

;	BX			Offset to context on locked stack
RestoreContext	MACRO
	OsGate restore_context_nr
					ENDM

;	Stack		Address of real mode code to call
CallVM	MACRO
	OsGate call_vm_nr
					ENDM

;	Stack		Address of protected mode ring 3 code to call
CallPM16	MACRO
	OsGate call_pm16_nr
					ENDM

;	Stack		Address of protected mode ring 3 code to call
CallPM32	MACRO
	OsGate call_pm32_nr
					ENDM

;	AL			INT NUMMER
;	DS:DI		ADDRESS TILL CALLBACK
HookVMInt	MACRO
	OsGate hook_vm_int_nr
					ENDM

;	AL			INT NUMMER
;	DS:DI		ADDRESS TILL CALLBACK
HookProt16Int	MACRO
	OsGate hook_pm16_int_nr
					ENDM

;	AL			INT NUMMER
;	DS:EDI		ADDRESS TILL CALLBACK
HookProt32Int	MACRO
	OsGate hook_pm32_int_nr
					ENDM

;	ES:DI		ADDRESS TILL CALLBACK
;	AL			INT NUMMER
HookException	MACRO
	OsGate hook_exception_nr
					ENDM

;	ES:DI		HANDLER ADDRESS
;	AL			INT NUMMER
HookGetVMInt	MACRO
	OsGate hook_get_vm_int_nr
					ENDM

;	ES:DI		HANDLER ADDRESS
;	AL			INT NUMMER
HookSetVMInt	MACRO
	OsGate hook_set_vm_int_nr
					ENDM

;	ES:DI		HANDLER ADDRESS
;	AL			INT NUMMER
HookGetProt16Int	MACRO
	OsGate hook_get_pm16_int_nr
					ENDM

;	ES:DI		HANDLER ADDRESS
;	AL			INT NUMMER
HookSetProt16Int	MACRO
	OsGate hook_set_pm16_int_nr
					ENDM

;	ES:EDI		HANDLER ADDRESS
;	AL			INT NUMMER
HookGetProt32Int	MACRO
	OsGate hook_get_pm32_int_nr
					ENDM

;	ES:EDI		HANDLER ADDRESS
;	AL			INT NUMMER
HookSetProt32Int	MACRO
	OsGate hook_set_pm32_int_nr
					ENDM

;	BX			OFFSET I BIOS SEGMENT
;	AL			DATA
GetBiosData	MACRO
	OsGate get_bios_data_nr
					ENDM

;	BX			OFFSET I BIOS SEGMENT
;	AL			DATA
SetBiosData	MACRO
	OsGate set_bios_data_nr
					ENDM

;	BX			OFFSET I BIOS SEGMENT
;	ES:DI		HANDLER ADDRESS
HookGetBiosData	MACRO
	OsGate hook_get_bios_data_nr
					ENDM

;	BX			OFFSET I BIOS SEGMENT
;	ES:DI		HANDLER ADDRESS
HookSetBiosData	MACRO
	OsGate hook_set_bios_data_nr
					ENDM

;	AL		Exception #
EmulateOpcode	MACRO
	OsGate emulate_opcode_nr
					ENDM

;	BP		STACK WITH EXCEPTION INFO
SegmentNotPresent	MACRO
	OsGate segment_not_present_nr
					ENDM

;	EAX		ANTAL BYTE
;	EDX		LINEAR BASE ADDRESS
;	ES:DI	CALLBACK ROUTINE
HookPage	MACRO
	OsGate hook_page_nr
					ENDM

;	EAX		ANTAL BYTE
;	EDX		LINEAR BASE ADDRESS
UnhookPage	MACRO
	OsGate unhook_page_nr
					ENDM

;	EAX		ANTAL BYTE
;	EDX		LINEAR BASE ADDRESS
SetPageEmulate	MACRO
	OsGate set_page_emulate_nr
					ENDM

;	EAX		ANTAL BYTE
;	EDX		LINEAR BASE ADDRESS
SetPageKernel	MACRO
	OsGate set_page_kernel_nr
					ENDM

;	ES:DI		ADDRESS TILL CALLBACK
HookEnableFocus	MACRO
	OsGate hook_enable_focus_nr
					ENDM

;	ES:DI		ADDRESS TILL CALLBACK
HookLostFocus	MACRO
	OsGate hook_lost_focus_nr
					ENDM

;	ES:DI		ADDRESS TILL CALLBACK
HookGotFocus	MACRO
	OsGate hook_got_focus_nr
					ENDM

;	AL = CHAR OR EXTENDED CHAR
ReadKeyboardSerial	MACRO
	OsGate read_keyboard_serial_nr
					ENDM

;	NC		CHAR IN BUFFER
;	CY		BUFFER EMPTY
PollKeyboardSerial	MACRO
	OsGate poll_keyboard_serial_nr
					ENDM

;	BX			PSP SEGMENT
GetPsp	MACRO
	OsGate get_psp_nr
					ENDM

;	AX		Mode nr
;	ES:DI	Mode constructor
RegisterVideoMode	MACRO
	OsGate register_video_mode_nr
					ENDM

;	ES:EDI		ADDRESS TILL '$' TERMINERAD STRéNG
WriteDosString	MACRO
	OsGate write_dos_string_nr
					ENDM

;	AL		char
;	BX		char mask selector
;	CX		width
GetCharMask	MACRO
	OsGate get_char_mask_nr
					ENDM

;	ES:EDI	string
;	BX		string mask selector
;	CX		width
GetStringMask	MACRO
	OsGate get_string_mask_nr
					ENDM

;	Stack	Int #
V86BiosInt	MACRO
	OsGate v86_bios_int_nr
					ENDM

EnterDpmi	MACRO
	OsGate enter_dpmi_nr
					ENDM

EnterDos16	MACRO
	OsGate enter_dos16_nr
					ENDM

EnterDos32	MACRO
	OsGate enter_dos32_nr
					ENDM

ReflectPMToVM	MACRO
	OsGate reflect_pm_to_vm_nr
					ENDM

BiosPciInt	MACRO
	OsGate bios_pci_int_nr
					ENDM

; IN  BH	Bus
; IN  BL 	Device
; IN  CH	Function
; IN  CL	Register
; OUT AL	Data
ReadPciByte	MACRO
	OsGate read_pci_byte_nr
					ENDM

; IN  BH	Bus
; IN  BL 	Device
; IN  CH	Function
; IN  CL	Register
; OUT AX	Data
ReadPciWord	MACRO
	OsGate read_pci_word_nr
					ENDM

; IN  BH	Bus
; IN  BL 	Device
; IN  CH	Function
; IN  CL	Register
; OUT EAX	Data
ReadPciDword	MACRO
	OsGate read_pci_dword_nr
					ENDM

; IN  BH	Bus
; IN  BL 	Device
; IN  CH	Function
; IN  CL	Register
; IN  AL	Data
WritePciByte	MACRO
	OsGate write_pci_byte_nr
					ENDM

; IN  BH	Bus
; IN  BL 	Device
; IN  CH	Function
; IN  CL	Register
; IN  AX	Data
WritePciWord	MACRO
	OsGate write_pci_word_nr
					ENDM

; IN  BH	Bus
; IN  BL 	Device
; IN  CH	Function
; IN  CL	Register
; IN  EAX	Data
WritePciDword	MACRO
	OsGate write_pci_dword_nr
					ENDM

; IN  BH	Class
; IN  BL 	Sub class
; IN  CH	Interface
; IN  AX	Device number
; OUT BH	Bus
; OUT BL 	Device
FindPciClass	MACRO
	OsGate find_pci_class_nr
					ENDM

; IN  CX	Device ID
; IN  DX	Vendor ID
; IN  AX	Device number
; OUT BH	Bus
; OUT BL 	Device
FindPciDevice	MACRO
	OsGate find_pci_device_nr
					ENDM

;		ES		Serial mail to send
SendSerialMail	MACRO
	OsGate send_serial_mail_nr
			ENDM

;	ES:DI		ADDRESS OF PREVIEW CALLBACK
HookNet	MACRO
	OsGate hook_net_nr
		ENDM
			
;	ES:DI	PROCEDURE THAT INITS DISC
HookInitDisc	MACRO
	OsGate hook_init_disc_nr
					ENDM

;	IN	AX		Sub-unit #
;	IN	BX		Disc handle
;	IN	DS:SI	Disc name
;	IN	ES:DI	Disc struc
;	OUT	AL		Disc #
InstallDisc	MACRO
	OsGate install_disc_nr
					ENDM

;	IN  AX		Sectors per unit
;	IN  BX		Disc sel
;	IN  CX		Bytes per sector
;	IN  DX		Units
FlushDisc	MACRO
	OsGate flush_disc_nr
					ENDM

;	IN  BX		Disc sel
WaitForDiscRequest	MACRO
	OsGate wait_for_disc_request_nr
					ENDM

;	IN  BX		Disc sel
;	OUT	EDI		Disc handle
GetDiscRequest	MACRO
	OsGate get_disc_request_nr
					ENDM

;	IN  BX		Disc sel
;	OUT	EDI		Disc handle
PollDiscRequest	MACRO
	OsGate poll_disc_request_nr
					ENDM

;	IN  BX		Disc sel
;	IN	EDI		Disc handle
DiscRequestCompleted	MACRO
	OsGate disc_request_completed_nr
					ENDM

;	OUT	AL		Drive #
AllocateStaticDrive	MACRO
	OsGate allocate_static_drive_nr
					ENDM

;	IN	AL		Drive #
AllocateFixedDrive	MACRO
	OsGate allocate_fixed_drive_nr
					ENDM

;	OUT	AL		Drive #
AllocateDynamicDrive	MACRO
	OsGate allocate_dynamic_drive_nr
					ENDM

;	IN	AL		Drive #
;	IN	AH		Disc # or 0
;	IN	EDX		Start sector
OpenDrive	MACRO
	OsGate open_drive_nr
					ENDM

;	IN	AL		Drive #
CloseDrive	MACRO
	OsGate close_drive_nr
					ENDM

;	AL		Drive #
;	EDX		Sector
NewSector	MACRO
	OsGate new_sector_nr
					ENDM

;	AL		Drive #
;	EBX		Handle
;	EDX		Sector
;	ESI		Logical address of data
LockSector	MACRO
	OsGate lock_sector_nr
					ENDM

;	EBX		Handle
UnlockSector	MACRO
	OsGate unlock_sector_nr
					ENDM

;	EBX		Handle
ModifySector	MACRO
	OsGate modify_sector_nr
					ENDM

;	AL		Drive #
;	EBX		Handle
;	EDX		Sector
;	ESI		Logical address of data
LockSeqSector	MACRO
	OsGate lock_seq_sector_nr
					ENDM

;	EBX		Handle
UnlockSeqSector	MACRO
	OsGate unlock_seq_sector_nr
					ENDM

;	AL		Drive #
ResetDrive	MACRO
	OsGate reset_drive_nr
					ENDM

;	BX		FILE HANDLE
;	CL		ACCESS
;	AX		FILE SELECTOR
GetFileInfo	MACRO
	OsGate get_file_info_nr
					ENDM

;	CL		ACCESS
;	AX		FILE SELECTOR
;	BX		FILE HANDLE
DuplFileInfo	MACRO
	OsGate dupl_file_info_nr
					ENDM

;	DS:SI		FILE SYSTEM NAME
;	ES:DI		FILE SYSTEM STRUC
RegisterFileSystem	MACRO
	OsGate register_file_system_nr
					ENDM

;	AL			DRIVE #
;	ES:DI		FILE SYSTEM NAME
InstallFileSystem	MACRO
	OsGate install_file_system_nr
					ENDM

;	AL			DRIVE #
InitFileSystem	MACRO
	OsGate init_file_system_nr
					ENDM

;	AL			DRIVE #
;	EDX			CURRENT DIRECTORY PTR
GetCurDirPtr	MACRO
	OsGate get_cur_dir_ptr_nr
					ENDM

;	AL			DRIVE #
;	EDX			CURRENT DIRECTORY PTR
SetCurDirPtr	MACRO
	OsGate set_cur_dir_ptr_nr
					ENDM

;	DS:BX		DEVICE HEADER
;	CX			DEVICE SIZE
;	DS:SI		DEVICE READ
;	DS:DI		DEVICE WRITE
;	DX			DEVICE SEGMENT
RegisterDevice	MACRO
	OsGate register_device_nr
					ENDM

;	ES:EDI		FILENAME
;	AL			DRIVE IN / OUT
CheckDevice	MACRO
	OsGate check_device_nr
					ENDM

;	AX		EVENT NR
;	BX		THREAD ID
;	EDX		DATA
;	DS:DI	SOVLISTA
FireEventSleep	MACRO
	OsGate fire_event_sleep_nr
						ENDM

;	AX		EVENT NR
;	BX		THREAD ID
;	EDX		DATA
;	DS:EDI	SOVLISTA
FireEventSleep32	MACRO
	OsGate fire_event_sleep32_nr
						ENDM

;	AL		class id
;	CX		Size of address
;	DS:SI	Broadcast address
RegisterNetClass	MACRO
	OsGate register_net_class_nr
					ENDM

;	CX		Size of address
;	DX		Packet type
;	DS:SI	My address
;	ES:DI	receiver callback
;				ECX		size
;				DX		packet type
;				DS:SI	source address
;				ES		data selector
;	BX		Protocol handle
RegisterNetProtocol	MACRO
	OsGate register_net_protocol_nr
						ENDM

;	AL		CLASS
;	ECX		MAX DATA SIZE
;	DS:SI	DISPATCH TABLE
;	ES:DI	DRIVER NAME
;	BX		HANDLE
RegisterNetDriver	MACRO
	OsGate register_net_driver_nr
						ENDM

;	DS:SI	DISPATCH TABLE
;	BX		HANDLE
RegisterPppDriver	MACRO
	OsGate register_ppp_driver_nr
						ENDM

;	BX		PROTOCOL HANDLE
;	ECX		SIZE
;	DS:ESI	DEST ADDRESS
;	ES		DATA
;	NC		SUCCESS
SendNet	MACRO
	OsGate send_net_nr
						ENDM

;	ECX		SIZE
;	ES		DATA
;	NC		SUCCESS
SendPpp	MACRO
	OsGate send_ppp_nr
						ENDM

;	BX		HANDLE
NetReceived	MACRO
	OsGate net_received_nr
						ENDM

;	AL		Protocol
;	ES:DI	Receiver callback
;		AX		Size of options
;		ECX		Size of data
;		EDX		Source IP address
;		DS:ESI	Options
;		ES:EDI	IP Data
HookIp	MACRO
	OsGate hook_ip_nr
						ENDM

;	AL		Protocol
;	AH		Time to live
;	ECX		Size of data
;	EDX		Destination IP address
;	DS:ESI	Options
;	ES:EDI	IP Data
CreateIpHeader	MACRO
	OsGate create_ip_header_nr
						ENDM

;	ES		Datagram to send
SendIp	MACRO
	OsGate send_ip_data_nr
						ENDM

;	ES:DI	New IP cache entry callback
;		ES	IP cache selector
HookIpCache	MACRO
	OsGate hook_ip_cache_nr
						ENDM

;	AX		Size of IP cache data
;	BX		Offset within IP cache data for
AllocateIpCacheMem	MACRO
	OsGate allocate_ip_cache_mem_nr
						ENDM

;	EDX		IP address
;	ES		IP cache entry
;	DI		Host name offset
LookupIpCache	MACRO
	OsGate lookup_ip_cache_nr
						ENDM

;	DS		IP cache entry
;	EAX		Timeout in system tics
GetHostTimeout	MACRO
	OsGate get_host_timeout_nr
						ENDM

;	DS		IP cache entry
;	EAX		Round trip time in system tics
UpdateRoundTripTime	MACRO
	OsGate update_round_trip_time_nr
						ENDM

;	EDX		My PPP IP address
GetPppIp	MACRO
	OsGate get_ppp_ip_nr
				ENDM

OpenPpp	MACRO
	OsGate open_ppp_nr
			ENDM

ClosePpp	MACRO
	OsGate close_ppp_nr
			ENDM

; IN  EAX		timeout in ms
; IN  BX		destination port
; IN  EDX		IP-address
; IN  CX		Number of bytes to send
; IN  ES:EDI	Data buffer
; OUT ES:DI 	Answer buffer
; OUT CX		Number of bytes received
QueryUdp	MACRO
	OsGate query_udp_nr
			ENDM

; IN  SI		local port
; IN  ES:DI		callback upon request
; IN	CX		UDP request size
; IN	ES:DI	UDP request data
; OUT	CX		UDP reply size
; OUT	ES		UDP reply data
ListenUdpPort	MACRO
	OsGate listen_udp_port_nr
			ENDM

;	ES:EDI		ADDRESS TILL '$' TERMINERAD STRéNG
NewWriteDosString	MACRO
	OsGate new_write_dos_string_nr
					ENDM
