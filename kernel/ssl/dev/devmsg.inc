;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2011, Leif Ekblad
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
; devmsg.inc
; SSL msg definitions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; OUT EBX       Session ID
SSL_OPEN_SESSION               = 0

; IN  EBX       Session ID
SSL_CLOSE_SESSION              = 1

; IN  EAX       Timeout in milliseconds for connection
; IN  EBX       Session ID
; IN  ECX       buffer size
; IN  EDX       ip address
; IN  ESI       local port (0 for dynamic port)
; IN  EDI       remote port
; OUT EBX       Connection ID
SSL_OPEN_CONNECTION            = 2

; IN  EBX       Connection ID
SSL_CLOSE_CONNECTION           = 3

; IN  EBX       Connection ID
SSL_PUSH_CONNECTION            = 4

; IN  EAX       Port
; IN  EDX       Max connections
; IN  ECX       Buffer size
; OUT EBX       Server ID
SSL_OPEN_SERVER                = 5

; IN  EBX       Server ID
SSL_CLOSE_SERVER               = 6

; IN  EBX       Server ID
; IN  EAX       Entry #
; OUT EBX       Connection ID
SSL_ACCEPT_SERVER              = 7
