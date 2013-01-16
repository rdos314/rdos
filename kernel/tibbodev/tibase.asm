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
; TIBASE.ASM
; Basic tibbo support functions not available from RDOS device-driver interface
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\..\kernel\user.def
INCLUDE ..\..\kernel\os.def
INCLUDE ..\..\kernel\os.inc
INCLUDE ..\..\kernel\user.inc
INCLUDE ..\..\kernel\driver.def
INCLUDE ..\..\kernel\os\system.def
INCLUDE ..\..\kernel\os\proc.inc

    .386p

_TEXT    SEGMENT byte public 'CODE'

    assume cs:_TEXT

   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           UdpCallback
;
;       DESCRIPTION:    UDP callback
;
;       PARAMETERS:     EDX         IP
;                       ES:EDI      UDP request data
;                       CX          UDP request size
;
;       RETURNS:        ES:EDI      UDP reply data
;                       CX          UDP reply size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn ImplUdpCallback:near

udp_callback    Proc far
    movzx ecx,cx
    call ImplUdpCallback
    xor ecx,ecx
    ret
udp_callback    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitTibboBase
;
;           DESCRIPTION:    Initialize Tibbo base
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitTibboBase_

InitTibboBase_    Proc near
    push ds
    push es
    pushad
;    
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov edi,OFFSET udp_callback
    mov si,4095
    ListenUdpPort
;
    popad
    pop es
    pop ds
    ret
InitTibboBase_    Endp
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       
;
;       NAME:           BroadcastCallback
;
;       DESCRIPTION:    Broadcast callback
;
;       PARAMETERS:     DS          Class selector
;                       FS          Driver selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    extrn ImplBroadcast:near

broadcast_callback    Proc far
    push ds
    mov eax,fs
    call ImplBroadcast
    pop ds
    ret
broadcast_callback    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitBroadcast
;
;           DESCRIPTION:    Initialize broadcast
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public InitBroadcast_

InitBroadcast_    Proc near
    push ds
    push es
    push fs
    pushad
;    
    mov ax,cs
    mov es,ax
    mov edi,OFFSET broadcast_callback
    NetBroadcast
;
    popad
    pop fs
    pop es
    pop ds
    ret
InitBroadcast_    Endp

_TEXT    ENDS

    END
