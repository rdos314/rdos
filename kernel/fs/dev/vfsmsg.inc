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
; vfsmsg.inc
; VFS msg definitions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VFS_START                 = 0
VFS_STOP                  = 1

; OUT EDX:EAX   Free sectors
VFS_GET_FREE_SECTORS      = 2

; IN  EAX       Start handle
; IN            Path name
; OUT EAX       Header size
; OUT ECX       Entry count
; OUT           Block
VFS_GET_DIR               = 3

; IN  EAX       Start handle
; IN            Path name
; OUT EAX       Attribute
VFS_GET_DIR_ENTRY_ATTRIB  = 4

; IN  EAX       Start handle
; IN            Path name
; OUT EAX       Start handle
VFS_LOCK_REL_DIR          = 5

; IN  EAX       Start handle
VFS_CLONE_REL_DIR         = 6

; IN  EAX       Start handle
VFS_UNLOCK_REL_DIR        = 7

; IN  EAX       Start handle
; OUT           Path name
VFS_GET_REL_DIR           = 8

; IN  EAX       Start handle
; IN            Path name
; OUT BX        File handle
; OUT ECX       Attribute
VFS_OPEN_FILE             = 9

; IN  BX        File handle
VFS_DEREF_FILE            = 10

; IN  BX        File handle
VFS_CLOSE_FILE            = 11

; IN  EDX:EAX   Sectors
; IN            Fs name
; OUT BX        Offset
; OUT EDX:EAX   Sectors
VFS_FORMAT                = 12

; IN  EAX       Start handle
; IN            Path name
VFS_CREATE_DIR            = 13

; IN  EAX       Start handle
; IN  ECX       Attribute
; IN            Path name
; OUT BX        File handle
VFS_CREATE_FILE           = 14

; IN            Cmd
VFS_CMD                   = 15

; IN EBX       Buffer
; IN EDX:EAX   Sector
VFS_READ_SECTOR           = 16

; IN EBX       Buffer
; IN EDX:EAX   Sector
VFS_WRITE_SECTOR          = 17
