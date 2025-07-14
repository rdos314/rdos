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
