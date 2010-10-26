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
; DEBEVENT.INC
; Debug event message definitions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

EVENT_EXCEPTION = 1
EVENT_CREATE_THREAD = 2
EVENT_CREATE_PROCESS = 3
EVENT_TERMINATE_THREAD = 4
EVENT_TERMINATE_PROCESS = 5
EVENT_LOAD_DLL = 6
EVENT_FREE_DLL = 7
EVENT_KERNEL = 8


create_process_event_struc	STRUC

cpeFile			DD ?
cpeHandle		DD ?
cpeProcess		DD ?
cpeThread		DD ?
cpeImageBase    DD ?
cpeImageSize	DD ?
cpeObjectRva    DD ?
cpeFsLinear		DD ?
cpeStartEip		DD ?
cpeStartCs		DW ?

create_process_event_struc ENDS


terminate_process_event_struc	STRUC

tpeExitCode		DD ?

terminate_process_event_struc ENDS


create_thread_event_struc	STRUC

cteThread		DD ?
cteFsLinear		DD ?
cteStartEip		DD ?
cteStartCs		DW ?

create_thread_event_struc ENDS


load_dll_event_struc	STRUC

ldeFile			DD ?
ldeHandle		DD ?
ldeImageBase	DD ?
ldeImageSize	DD ?
ldeObjectRva    DD ?

load_dll_event_struc	ENDS


free_dll_event_struc	STRUC

fdeHandle		DD ?

free_dll_event_struc ENDS


exception_event_struc	STRUC

excCode			DD ?
excPtr			DD ?
excEip			DD ?
excCs			DW ?

exception_event_struc ENDS


kernel_exception_event_struc    STRUC

kexcVector      DW ?

kernel_exception_event_struc    ENDS
