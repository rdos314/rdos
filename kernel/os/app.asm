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
; APP.ASM
; Application handling module
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE protseg.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\driver.def
INCLUDE int.def
INCLUDE system.def
INCLUDE system.inc

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitApp
;
;           DESCRIPTION:    Init module
;
;           PARAMETERS:     
;                           
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_app

init_app    PROC near
    push ds
    push es
    pusha
;
    mov ax,cs
    mov ds,ax
    mov es,ax
    xor ebx,ebx
    xor esi,esi
    xor edi,edi
;
    mov esi,OFFSET exec_app
    mov edi,OFFSET exec_app_name
    xor cl,cl
    mov ax,exec_app_nr
    RegisterOsGate
;
    popa
    pop es
    pop ds
    ret
init_app    ENDP
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;           NAME:           ExecApp
;
;           DESCRIPTION:    Exec app
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

exec_app_name   DB 'Exec App',0

exec_app    PROC far
    xor ax,ax
    mov es,ax
    mov gs,ax
;
    GetThread
    mov es,ax
    lock and es:p_flags,NOT THREAD_FLAG_FORKED
;
    xor ax,ax
    mov es,ax
;
    ResetProcess
    retf32
exec_app    ENDP
    
code    ENDS

END
