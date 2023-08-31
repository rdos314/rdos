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
VFS_CLOSE_FILE            = 10

; IN  EDX:EAX   Sectors
; IN            Fs name
; OUT BX        Offset
; OUT EDX:EAX   Sectors
VFS_FORMAT                = 11

; IN  EAX       Start handle
; IN            Path name
VFS_CREATE_DIR            = 12

; IN            Cmd
VFS_CMD                   = 13

; IN EBX       Buffer
; IN EDX:EAX   Sector
VFS_READ_SECTOR           = 14

; IN EBX       Buffer
; IN EDX:EAX   Sector
VFS_WRITE_SECTOR          = 15
