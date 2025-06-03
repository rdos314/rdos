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
; uACPI msg definitions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; IN  AH    Class
; IN  AL    Sub class
; IN  BX    Start handle
; OUT BX    Handle
FIND_PCI_CLASS_CMD         = 0

; IN  AH    Class
; IN  AL    Sub class
; IN  DL    Protocol
; IN  BX    Start handle
; OUT BX    Handle
FIND_PCI_PROTOCOL_CMD      = 1

; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
; OUT AL    Value
READ_PCI_CONFIG_BYTE_CMD   = 2

; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
; OUT AX    Value
READ_PCI_CONFIG_WORD_CMD   = 3

; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
; OUT EAX   Value
READ_PCI_CONFIG_DWORD_CMD  = 4

; IN  AL    Value
; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
WRITE_PCI_CONFIG_BYTE_CMD  = 5

; IN  AX    Value
; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
WRITE_PCI_CONFIG_WORD_CMD  = 6

; IN  EAX   Value
; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
WRITE_PCI_CONFIG_DWORD_CMD = 7
