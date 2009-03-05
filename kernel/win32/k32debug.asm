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
; K32DEBUG.ASM
; 32-bit kernel32.dll debug support
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
	NAME  k32debug

;;;;;;;;; INTERNAL ProcEDURES ;;;;;;;;;;;

.386p
.model flat

include ..\user.def
include ..\debevent.inc

UserGate	MACRO gate_nr
	db 9Ah
	dd gate_nr
	dw 2
			ENDM

tss_struc	STRUC

tss_back_link	DD ?
tss_esp0		DD ?
tss_ess0		DD ?
tss_esp1		DD ?
tss_ess1		DD ?
tss_esp2		DD ?
tss_ess2		DD ?
tss_cr3			DD ?
tss_eip			DD ?
tss_eflags		DD ?
tss_eax			DD ?
tss_ecx			DD ?
tss_edx			DD ?
tss_ebx			DD ?
tss_esp			DD ?
tss_ebp			DD ?
tss_esi			DD ?
tss_edi			DD ?
tss_es			DD ?
tss_cs			DD ?
tss_ss			DD ?
tss_ds			DD ?
tss_fs			DD ?
tss_gs			DD ?
tss_ldt			DD ?
tss_t			DW ?
tss_bitmap		DW ?
tss_dr0			DD ?
tss_dr1			DD ?
tss_dr2			DD ?
tss_dr3			DD ?
tss_dr7			DD ?
math_control	DW ?,?
math_status		DW ?,?
math_tag		DW ?,?
math_eip		DD ?
math_cs			DW ?
math_op			DB ?,?
math_data_offs	DD ?
math_data_sel	DW ?,?
math_st0		DT ?
math_st1		DT ?
math_st2		DT ?
math_st3		DT ?
math_st4		DT ?
math_st5		DT ?
math_st6		DT ?
math_st7		DT ?
math_prev_op	DB ?,?

tss_guard		DB 16 DUP(?)

tss_struc		ENDS

tib_data	STRUC

pvFirstExcept		DD ?
pvStackUserTop		DD ?
pvStackUserBottom	DD ?
pvLastError			DD ?
pvResv1				DD ?
pvArbitrary			DD ?
pvTEB				DD ?
pvResv2				DD ?,?
pvModuleHandle		DD ?
pvTLSBitmap			DD ?
pvTLSArray			DD ?

tib_data	ENDS

context_all_struc	STRUC

cFlags		DD ?

cDr0		DD ?
cDr1		DD ?
cDr2		DD ?
cDr3		DD ?
cDr6		DD ?
cDr7		DD ?

cControl	DD ?
cStatus		DD ?
cTag		DD ?
cErrorOffs	DD ?
cErrorSel	DD ?
cDataOffs	DD ?
cDataSel	DD ?
cSt			DT 8 DUP(8)
cState		DD ?

cGs			DD ?
cFs			DD ?
cEs			DD ?
cDs			DD ?

cEdi		DD ?
cEsi		DD ?
cEbx		DD ?
cEdx		DD ?
cEcx		DD ?
cEax		DD ?

cEbp		DD ?
cEip		DD ?
cCs			DD ?
cEflags		DD ?
cEsp		DD ?
cSs			DD ?

context_all_struc	ENDS

event_struc STRUC

event_code		DD ?
event_proc_id	DD ?
event_thread_id	DD ?

event_struc ENDS

cp_event_struc	STRUC

cpe_basic		    event_struc <>
cpe_file			DD ?
cpe_process		    DD ?
cpe_thread		    DD ?
cpe_image_base	    DD ?
cpe_debug_offset	DD ?
cpe_debug_size	    DD ?
cpe_locale		    DD ?
cpe_start		    DD ?
cpe_name			DD ?
cpe_unicode		    DW ?

cp_event_struc ENDS

tp_event_struc	STRUC

tpe_basic	    	event_struc <>
tpe_exit_code		DD ?

tp_event_struc ENDS

ct_event_struc	STRUC

cte_basic		event_struc <>
cte_thread		DD ?
cte_locale		DD ?
cte_start		DD ?

ct_event_struc ENDS

tt_event_struc	STRUC

tte_basic		event_struc <>
tte_exit_code	DD ?

tt_event_struc ENDS

ld_event_struc	STRUC

lde_basic		    event_struc <>
lde_file		    DD ?
lde_image_base	    DD ?
lde_debug_offset	DD ?
lde_debug_size	    DD ?
lde_name			DD ?
lde_unicode		    DW ?

ld_event_struc	ENDS

exc_event_struc	STRUC

exc_basic		    event_struc <>
exc_code			DD ?
exc_flags		    DD ?
exc_ptr			    DD ?
exc_ads			    DD ?
exc_params		    DD ?
exc_info			DD 15 DUP(?)
exc_first_chance	DD ?

exc_event_struc ENDS


.data

DebugHandle DW ?

.code
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetDebugHandle
;
;       DESCRIPTION:    Set debug handle
;
;       PARAMETERS:     BX      Debug handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public SetDebugHandle

SetDebugHandle  Proc
    mov DebugHandle,bx
    ret
SetDebugHandle  Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CopyCreateProcessEvent
;
;       DESCRIPTION:    Copy data for create process event
;
;       PARAMETERS:     ESI     Source
;                       EDI     Dest
;                       EAX     Thread ID
;                       EDX     Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyCreateProcessEvent  Proc
	mov [edi].event_code,3
	mov [edi].event_proc_id,edx
	mov [edi].event_thread_id,eax
;
    mov ebx,[esi].cpeFile
    mov [edi].cpe_file,ebx
;    
    mov ebx,[esi].cpeProcess
    mov [edi].cpe_process,ebx
;
    mov ebx,[esi].cpeThread
    mov [edi].cpe_thread,ebx
;
    mov ebx,[esi].cpeImageBase
    mov [edi].cpe_image_base,ebx
;
    mov [edi].cpe_debug_offset,0
    mov [edi].cpe_debug_size,0
;        
    mov ebx,[esi].cpeFsLinear
    mov [edi].cpe_locale,ebx
;    
    mov ebx,[esi].cpeStartEip
    mov [edi].cpe_start,ebx
;
    mov [edi].cpe_name,0
    mov [edi].cpe_unicode,0   
    ret
CopyCreateProcessEvent  Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CopyTerminateProcessEvent
;
;       DESCRIPTION:    Copy data for terminate process event
;
;       PARAMETERS:     ESI     Source
;                       EDI     Dest
;                       EAX     Thread ID
;                       EDX     Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyTerminateProcessEvent  Proc
	mov [edi].event_code,5
	mov [edi].event_proc_id,edx
	mov [edi].event_thread_id,eax
;
    mov ebx,[esi].tpeExitCode
    mov [edi].tpe_exit_code,ebx	
    ret
CopyTerminateProcessEvent   Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CopyCreateThreadEvent
;
;       DESCRIPTION:    Copy data for create thread event
;
;       PARAMETERS:     ESI     Source
;                       EDI     Dest
;                       EAX     Thread ID
;                       EDX     Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyCreateThreadEvent  Proc
	mov [edi].event_code,2
	mov [edi].event_proc_id,edx
	mov [edi].event_thread_id,eax
;
    mov ebx,[esi].cteThread
    mov [edi].cte_thread,ebx
;
    mov ebx,[esi].cteFsLinear
    mov [edi].cte_locale,ebx    
;
    mov ebx,[esi].cteStartEip
    mov [edi].cte_start,ebx
    ret
CopyCreateThreadEvent   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CopyTerminateThreadEvent
;
;       DESCRIPTION:    Copy data for terminate thread event
;
;       PARAMETERS:     ESI     Source
;                       EDI     Dest
;                       EAX     Thread ID
;                       EDX     Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyTerminateThreadEvent  Proc
	mov [edi].event_code,4
	mov [edi].event_proc_id,edx
	mov [edi].event_thread_id,eax
;
    mov [edi].tte_exit_code,0
	ret
CopyTerminateThreadEvent    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CopyLoadDllEvent
;
;       DESCRIPTION:    Copy data for load DLL event
;
;       PARAMETERS:     ESI     Source
;                       EDI     Dest
;                       EAX     Thread ID
;                       EDX     Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyLoadDllEvent  Proc
	mov [edi].event_code,6
	mov [edi].event_proc_id,edx
	mov [edi].event_thread_id,eax
;
    mov ebx,[esi].ldeFile
    mov [edi].lde_file,ebx
;
    mov ebx,[esi].ldeImageBase
    mov [edi].lde_image_base,ebx
;
    mov [edi].lde_debug_offset,0
    mov [edi].lde_debug_size,0
    mov [edi].lde_name,0
    mov [edi].lde_unicode,0            
	ret
CopyLoadDllEvent    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           CopyExceptionEvent
;
;       DESCRIPTION:    Copy data for exception event
;
;       PARAMETERS:     ESI     Source
;                       EDI     Dest
;                       EAX     Thread ID
;                       EDX     Process ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyExceptionEvent  Proc
	mov [edi].event_code,1
	mov [edi].event_proc_id,edx
	mov [edi].event_thread_id,eax
;
    mov ebx,[esi].excCode
    mov [edi].exc_code,ebx	
;
    mov [edi].exc_flags,0
;   
    mov ebx,[esi].excPtr
    mov [edi].exc_ptr,ebx
;
    mov ebx,[esi].excEip
    mov [edi].exc_ads,ebx
;
    mov [edi].exc_params,0
    mov [edi].exc_first_chance,1    
    ret
CopyExceptionEvent  Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WaitForDebugEvent
;
;       DESCRIPTION:    Wait for a debug event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WaitForDebugEvent

wfdeEvent	EQU 8
wfdeTimeout	EQU 12

EventTable:
et01 DD OFFSET CopyExceptionEvent
et02 DD OFFSET CopyCreateThreadEvent
et03 DD OFFSET CopyCreateProcessEvent
et04 DD OFFSET CopyTerminateThreadEvent
et05 DD OFFSET CopyTerminateProcessEvent
et06 DD OFFSET CopyLoadDllEvent

WaitForDebugEvent Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
    mov bx,DebugHandle
    UserGate get_module_focus_key_nr
;
    UserGate set_focus_nr    

wfdeRetry:
	mov eax,[ebp].wfdeTimeout
    mov bx,DebugHandle
	UserGate wait_for_debug_event_nr
;
    movzx ebx,bl
    or ebx,ebx
    jz wfdeRemove
;    
    cmp ebx,6
    jbe wfdeHandle

wfdeRemove:
    mov bx,DebugHandle
	UserGate continue_debug_event_nr
    jmp wfdeRetry

wfdeHandle:
    dec ebx
;
    push eax
    push edx
    mov eax,1000h
    UserGate allocate_app_mem_nr
    mov edi,edx
    pop edx
    pop eax
;   
    push ebx     
    mov bx,DebugHandle
	UserGate get_debug_event_data_nr
	pop ebx
;
	mov esi,edi
   	mov edi,[ebp].wfdeEvent	
	call cs:dword ptr [4 * ebx].EventTable
;
    mov edx,esi
    UserGate free_app_mem_nr
;
    UserGate get_focus_nr
    UserGate set_focus_nr
;        
	mov eax,1
;
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
WaitForDebugEvent Endp
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ContinueDebugEvent
;
;       DESCRIPTION:    Continue debug event
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ContinueDebugEvent

cdeProcessId	EQU 8
cdeThreadId		EQU 12
cdeStatus		EQU 16

ContinueDebugEvent Proc near
	push ebp
	mov ebp,esp
	push ebx
;
	mov eax,[ebp].cdeThreadId
    mov bx,DebugHandle
	UserGate continue_debug_event_nr
	mov eax,1
;
	pop ebx
	pop ebp
	ret 12
ContinueDebugEvent Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetThreadContext
;
;       DESCRIPTION:    Get context of thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetThreadContext

gtcHandle	EQU 8
gtcContext	EQU 12

GetThreadContext Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
	sub esp,SIZE tss_struc
	mov edi,esp
;
	mov ebx,[ebp].gtcHandle
	mov esi,[ebp].gtcContext
	mov edx,[esi]
	test edx,10000h
	jz gtcFail
;
	UserGate get_thread_tss_nr
	jc gtcFail
;
	xchg esi,edi
	add edi,4
	test edx,10h
	jz gtcDebugDone
;
	mov eax,[esi].tss_dr0
	stosd
	mov eax,[esi].tss_dr1
	stosd
	mov eax,[esi].tss_dr2
	stosd
	mov eax,[esi].tss_dr3
	stosd
	xor eax,eax
	stosd
	mov eax,[esi].tss_dr7
	stosd

gtcDebugDone:
	test edx,8
	jz gtcFpuDone
;
	movzx eax,[esi].math_control
	stosd
	movzx eax,[esi].math_status
	stosd
	movzx eax,[esi].math_tag
	stosd
	mov eax,[esi].math_eip
	stosd
	movzx eax,[esi].math_cs
	stosd
	mov eax,[esi].math_data_offs
	stosd
	movzx eax,[esi].math_data_sel
	stosd
	push esi
	lea esi,[esi].math_st0
	mov ecx,20
	rep movsd
	pop esi
	xor eax,eax
	stosd
	jmp gtcFpuDone

gtcFpuDefault:
	xor eax,eax
	mov ecx,28
	rep stosd

gtcFpuDone:
	test edx,4
	jz gtcSegmentsDone
;
	mov eax,[esi].tss_gs
	stosd
	mov eax,[esi].tss_fs
	stosd
	mov eax,[esi].tss_es
	stosd
	mov eax,[esi].tss_ds
	stosd

gtcSegmentsDone:
	test edx,2
	jz gtcIntegerDone
;
	mov eax,[esi].tss_edi
	stosd
	mov eax,[esi].tss_esi
	stosd
	mov eax,[esi].tss_ebx
	stosd
	mov eax,[esi].tss_edx
	stosd
	mov eax,[esi].tss_ecx
	stosd
	mov eax,[esi].tss_eax
	stosd

gtcIntegerDone:
	test edx,1
	jz gtcControlDone
;
	mov eax,[esi].tss_ebp
	stosd
	mov eax,[esi].tss_eip
	stosd
	mov eax,[esi].tss_cs
	stosd
	mov eax,[esi].tss_eflags
	stosd
	mov eax,[esi].tss_esp
	stosd
	mov eax,[esi].tss_ss
	stosd

gtcControlDone:
	mov eax,1
	jmp gtcDone

gtcFail:
;	int 3
	xor eax,eax

gtcDone:
	add esp,SIZE tss_struc
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
GetThreadContext Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           SetThreadContext
;
;       DESCRIPTION:    Set context of thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public SetThreadContext

stcHandle	EQU 8
stcContext	EQU 12

SetThreadContext Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
	sub esp,SIZE tss_struc
	mov edi,esp
;
	mov ebx,[ebp].stcHandle
	mov esi,[ebp].stcContext
	mov edx,[esi]
	test edx,10000h
	jz stcFail
;
	UserGate get_thread_tss_nr
	jc stcFail
;
	add esi,4
	test edx,10h
	jz stcDebugDone
;
	lodsd
	mov [edi].tss_dr0,eax
	lodsd
	mov [edi].tss_dr1,eax
	lodsd
	mov [edi].tss_dr2,eax
	lodsd
	mov [edi].tss_dr3,eax
	lodsd
	lodsd
	mov [edi].tss_dr7,eax

stcDebugDone:
	test edx,8
	jz stcFpuDone
;
	lodsd
	mov [edi].math_control,ax
	lodsd
	mov [edi].math_status,ax
	lodsd
	mov [edi].math_tag,ax
	lodsd
	mov [edi].math_eip,eax
	lodsd
	mov [edi].math_cs,ax
	lodsd
	mov [edi].math_data_offs,eax
	lodsd
	mov [edi].math_data_sel,ax
	push edi
	lea edi,[edi].math_st0
	mov ecx,20
	rep movsd
	pop edi
	lodsd
	jmp stcFpuDone

stcFpuIgnore:
	add esi,28*4

stcFpuDone:
	test edx,4
	jz stcSegmentsDone
;
	lodsd
	mov [edi].tss_gs,eax
	lodsd
	mov [edi].tss_fs,eax
	lodsd
	mov [edi].tss_es,eax
	lodsd
	mov [edi].tss_ds,eax

stcSegmentsDone:
	test edx,2
	jz stcIntegerDone
;
	lodsd
	mov [edi].tss_edi,eax
	lodsd
	mov [edi].tss_esi,eax
	lodsd
	mov [edi].tss_ebx,eax
	lodsd
	mov [edi].tss_edx,eax
	lodsd
	mov [edi].tss_ecx,eax
	lodsd
	mov [edi].tss_eax,eax

stcIntegerDone:
	test edx,1
	jz stcControlDone
;
	lodsd
	mov [edi].tss_ebp,eax
	lodsd
	mov [edi].tss_eip,eax
	lodsd
	mov [edi].tss_cs,eax
	lodsd
	mov [edi].tss_eflags,eax
	lodsd
	mov [edi].tss_esp,eax
	lodsd
	mov [edi].tss_ss,eax

stcControlDone:
	mov edi,esp
	UserGate set_thread_tss_nr
	mov eax,1
	jmp stcDone

stcFail:
	int 3
	xor eax,eax

stcDone:
	add esp,SIZE tss_struc
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 8
SetThreadContext Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           GetThreadSelectorEntry
;
;       DESCRIPTION:    Get thread selector entry
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public GetThreadSelectorEntry

gtseHandle		EQU 8
gtseIndex		EQU 12
gtseDescriptor	EQU 16

GetThreadSelectorEntry Proc near
	push ebp
	mov ebp,esp
;
	int 3
	xor eax,eax
;
	pop ebp
	ret 12
GetThreadSelectorEntry Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           ReadProcessMemory
;
;       DESCRIPTION:    Read process memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public ReadProcessMemory

rpmHandle	EQU 8
rpmAddress	EQU 12
rpmBuf		EQU 16
rpmSize		EQU 20
rpmRead		EQU 24

ReadProcessMemory Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov ebx,[ebp].rpmHandle
	mov esi,[ebp].rpmAddress
	mov dx,ds
	mov edi,[ebp].rpmBuf
	mov ecx,[ebp].rpmSize
	UserGate read_thread_mem_nr
	mov ecx,[ebp].rpmRead
	or ecx,ecx
	jz rpmOk
;
	mov [ecx],eax

rpmOk:
	mov eax,1
;
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 20
ReadProcessMemory Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           WriteProcessMemory
;
;       DESCRIPTION:    Write process memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public WriteProcessMemory

wpmHandle	EQU 8
wpmAddress	EQU 12
wpmBuf		EQU 16
wpmSize		EQU 20
wpmWritten	EQU 24

WriteProcessMemory Proc near
	push ebp
	mov ebp,esp
	push ebx
	push esi
	push edi
;
	mov ebx,[ebp].wpmHandle
	mov esi,[ebp].wpmAddress
	mov dx,ds
	mov edi,[ebp].wpmBuf
	mov ecx,[ebp].wpmSize
	UserGate write_thread_mem_nr
	mov ecx,[ebp].wpmWritten
	or ecx,ecx
	jz wpmOk
;
	mov [ecx],eax

wpmOk:
	mov eax,1
;
	pop edi
	pop esi
	pop ebx
	pop ebp
	ret 20
WriteProcessMemory Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           OutputDebugString
;
;       DESCRIPTION:    Output debug string
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public OutputDebugString

OutputDebugString Proc near
	int 3
	ret 4
OutputDebugString Endp

		END
