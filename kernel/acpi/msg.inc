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

; IN  CX    Device
; IN  DX    Vendor
; IN  BX    Start handle
; OUT BX    Handle
FIND_PCI_DEVICE_CMD        = 2

; IN  DH    Segment
; IN  DL    Bus
; IN  AH    Device
; IN  BX    Function
; OUT BX    Handle
GET_PCI_HANDLE_CMD         = 3


; IN  BX    Handle
; OUT DH    Segment
; OUT DL    Bus
; OUT AH    Device
; OUT AL    Function
GET_PCI_PARAM_CMD          = 4

; IN  DH    Segment
; IN  DL    Bus
; OUT DL    Bus
; OUT AH    Device
; OUT AL    Function
GET_PCI_BUS_CMD            = 5

; IN  BX    Handle
; IN  AX    Index
; OUT AL    IRQ
GET_PCI_IRQ_CMD            = 6

; IN  BX    Handle
; IN  AL    Capability
; OUT AX    Register
GET_PCI_CAP_CMD            = 7

; IN  BX    Handle
;           Buffer
GET_PCI_NAME_CMD           = 8

; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
; OUT AL    Value
READ_PCI_CONFIG_BYTE_CMD   = 9

; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
; OUT AX    Value
READ_PCI_CONFIG_WORD_CMD   = 10

; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
; OUT EAX   Value
READ_PCI_CONFIG_DWORD_CMD  = 11

; IN  AL    Value
; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
WRITE_PCI_CONFIG_BYTE_CMD  = 12

; IN  AX    Value
; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
WRITE_PCI_CONFIG_WORD_CMD  = 13

; IN  EAX   Value
; IN  BX    Handle
; IN  CX    Register
; IN  DX    Issuer selector
WRITE_PCI_CONFIG_DWORD_CMD = 14

; IN  BX     Handle
; IN  DX     Issuer selector
; IN         Name
LOCK_PCI_CMD               = 15

; IN  BX     Handle
; IN  DX     Issuer selector
UNLOCK_PCI_CMD             = 16

; IN  BX     Handle
; OUT AL     Vectors
GET_PCI_MSI_CMD            = 17

; IN  BX     Handle
; OUT AL     Vectors
GET_PCI_MSIX_CMD           = 18

; IN  AH     Priority
; IN  BX     Handle
; IN  DX     Issuer selector
; IN  SI     Core ID
; OUT AL     Vector
; OUT CL     Mode, 0 = failed, 1 = IRQ, 2 = MSI or MSI-X
SETUP_PCI_IRQ_CMD         = 19

; IN  BX     Handle
; IN  AH     Priority
; IN  DX     Issuer selector
; IN  SI     Core ID
; IN  CL     Requested vectors
; OUT AL     Allocated vectors
; OUT CL     0 = MSI-X, other = MSI base vector
REQ_PCI_MSI_CMD           = 20

; IN  BX     Handle
; IN  AH     Priority
; IN  AL     Entry number
; IN  SI     Core ID
; IN  DX     Issuer selector
; OUT AL     Vector
SETUP_PCI_MSI_CMD         = 21

; IN  BX     Handle
; IN  AL     Entry number
; IN  DX     Issuer selector
ENABLE_PCI_MSI_CMD        = 22

; IN  BX     Handle
IS_PCI_LOCKED_CMD         = 23

; IN  AL      Bar #
; IN  BX      Handle
; OUT EDX:EAX Physical address
GET_PCI_BAR_PHYS_CMD      = 24

; IN  AL      Bar #
; IN  BX      Handle
; OUT DX      IO port
GET_PCI_BAR_IO_CMD        = 25

; IN  BX     Handle
; IN  ECX    Max entries
; IN         ACPI name + config Name
; OUT        Packet data
; OUT EAX    Entry count
EVAL_INT_ARR_CMD         = 26
