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
; FILEDISC.ASM
; File based disc driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\driver.def
INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE ..\drive.inc

boot_media_struc    STRUC

boot_bytes_per_sector       DW 512
boot_resv1                      DB 0
boot_mapping_sectors        DW 1
boot_resv3                      DB 0
boot_resv4                      DW 0
boot_small_sectors              DW 0
boot_media                      DB 0F8h
boot_resv6                      DW 0
boot_sectors_per_cyl        DW 1
boot_heads                      DW 1
boot_hidden_sectors             DD 1
boot_sectors                DD 0
boot_drive_nr               DB 0,0
boot_signature              DB 0 
boot_serial                     DD 0
boot_volume                     DB 11 DUP(0)
boot_fs                     DB 8 DUP(0)

boot_media_struc        ENDS

file_header     STRUC

boot_jmp                    DB ?,?,?
boot_name                       DB 8 DUP(?)
boot_param          boot_media_struc <>

file_header     ENDS

file_disc_data_seg  STRUC

fd_header           file_header <>

fd_disc_sel         DW ?
fd_disc_nr          DB ?
fd_drive_nr         DB ?

fd_access_drive     DW ?
fd_selector         DW ?

fd_handle                   DW ?

fd_sectors_per_unit     DW ?
fd_units        DW ?
fd_size         DD ?

file_disc_data_seg  ENDS

    .386p

code    SEGMENT byte public use16 'CODE'

    assume cs:code

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           read_drive
;
;           DESCRIPTION:    Read drive
;
;           PARAMETERS:         FS          Disc selector
;                           ESI         Disc handle array
;                           ECX         Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

read_drive      Proc near
    mov bx,fs:fd_handle
    movzx edx,es:[edi].dh_unit
    movzx eax,fs:fd_sectors_per_unit
    mul edx
    movzx edx,es:[edi].dh_sector
    add eax,edx
    shl eax,9
    SetFilePos

read_drive_loop:
    push ecx
    push edi
    mov edi,es:[edi].dh_data
    mov ecx,200h
    mov bx,fs:fd_handle
    OldUserGateForce32 read_file_nr
    pop edi
    pop ecx
    jnc read_drive_ok

read_drive_fail:
    mov es:[edi].dh_state,STATE_BAD
    mov bx,fs:fd_disc_sel
    DiscRequestCompleted
    jmp read_drive_next

read_drive_ok:
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,fs:fd_disc_sel
    DiscRequestCompleted

read_drive_next:
    add esi,4
    mov edi,es:[esi]
    sub cx,1
    jnz read_drive_loop
;           
    ret
read_drive      Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           write_drive
;
;           DESCRIPTION:    Perform a write request
;
;           PARAMETERS:         DS          Disc selector
;                           ESI         Disc handle array
;                           ECX         Entries
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

write_drive     Proc near
    mov bx,fs:fd_handle
    movzx edx,es:[edi].dh_unit
    movzx eax,fs:fd_sectors_per_unit
    mul edx
    movzx edx,es:[edi].dh_sector
    add eax,edx
    shl eax,9
    SetFilePos

write_drive_loop:
    push ecx
    push edi
    mov edi,es:[edi].dh_data
    mov ecx,200h
    mov bx,fs:fd_handle
    OldUserGateForce32 write_file_nr
    pop edi
    pop ecx
    jnc write_drive_ok

write_drive_fail:
    mov es:[edi].dh_state,STATE_BAD
    mov bx,fs:fd_disc_sel
    DiscRequestCompleted
    jmp write_drive_next

write_drive_ok:
    mov eax,es:[edi].dh_data
    mov es:[edi].dh_state,STATE_USED
    mov bx,fs:fd_disc_sel
    DiscRequestCompleted

write_drive_next:
    add esi,4
    mov edi,es:[esi]
    sub cx,1
    jnz write_drive_loop
;           
    ret
write_drive     Endp

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           perform_one
;
;           DESCRIPTION:    Perform one request
;
;           PARAMETERS:         FS          Disc selector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

perform_one     Proc near

perform_one_loop:
    mov ecx,255
    GetDiscRequestArray
    jc perform_one_done
;
    mov edi,es:[esi]
    mov al,es:[edi].dh_state
    cmp al,STATE_EMPTY
    je perform_one_read
;
    cmp al,STATE_DIRTY
    je perform_one_write
;
    cmp al,STATE_SEQ
    jne perform_one_done

perform_one_write:
    call write_drive
    jmp perform_one_loop

perform_one_read:
    call read_drive
    jmp perform_one_loop

perform_one_done:
    ret
perform_one     Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DISCBUF_THREAD
;
;           DESCRIPTION:    Thread to handle disc buffer queue
;
;           PARAMETERS:         FS          Disc handle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

discbuf_name    DB 'File drive', 0

discbuf_thread:
    mov cx,fs:fd_access_drive
    mov ax,fs:fd_selector
    DuplFileInfo
    mov fs:fd_handle,bx
;
    mov ax,flat_sel
    mov es,ax
;
    mov bx,fs:fd_disc_sel

discbuf_thread_loop:
    WaitForDiscRequest
    call perform_one
    jmp discbuf_thread_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateFileDrive
;
;           DESCRIPTION:    Create file as a filesystem & return drive
;
;       PARAMETERS:     AL          Drive #
;               DS:(E)SI        Requested filesystem
;                       ES:(E)DI        Filename to use
;               ECX             Size of filesystem
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

create_file_drive_name  DB 'Create File Drive',0

create_file_drive   Proc near
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push bp
;
    mov bp,ax
    push es
    push edi
    mov eax,SIZE file_disc_data_seg
    AllocateSmallGlobalMem
;
    mov ax,es
    mov fs,ax
    mov di,OFFSET boot_param.boot_fs

cfdMoveName:
    lods byte ptr [esi]
    stosb
    or al,al
    jnz cfdMoveName
;
    mov edi,OFFSET boot_param.boot_fs
    IsFileSystemAvailable
    pop edi
    pop es
    jc cfdFreeFail
;
    push ecx
    xor cx,cx
    OldUserGateForce32 create_file_nr
    pop ecx
    jc cfdFreeFail
;
    mov ax,fs
    mov es,ax
    mov eax,ecx
    mov cx,1
    dec eax
    shr eax,9
    inc eax

cfdIterate:
    cmp eax,100000h
    jb cfdSave
;
    shl cx,1
    shr eax,1
    jmp cfdIterate

cfdSave:
    mov es:fd_sectors_per_unit,cx
    mov es:fd_units,ax
    mul cx
    push dx
    push ax
    pop eax
    shl eax,9
    mov es:fd_size,eax
;
    xor di,di
    mov cx,200h
    WriteFile
;
    mov eax,es:fd_size
    add eax,200h
    SetFileSize
;
    GetFileInfo
    mov es:fd_access_drive,cx
    mov es:fd_selector,ax
;
    mov ecx,200h
    mov bx,es
    InstallDisc
    mov es:fd_disc_sel,bx
    mov es:fd_disc_nr,al
;
    mov ax,es:fd_sectors_per_unit
    mov cx,200h
    mov dx,es:fd_units
    xor si,si
    xor di,di    
    SetDiscParam
;
    mov ax,bp
    mov es:fd_drive_nr,al
;
    mov ah,es:fd_disc_nr
    xor edx,edx
    mov ecx,es:fd_size
    shr ecx,9
    dec ecx
    OpenDrive
;
    push es
    push ecx
    mov ax,es
    mov fs,ax
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET discbuf_thread
    mov di,OFFSET discbuf_name
    mov ax,4
    mov cx,100h
    CreateThread
    pop ecx
    pop es
;
    mov al,es:fd_drive_nr
    mov edi,OFFSET boot_param.boot_fs
    FormatFileSystem
    InstallFileSystem
;
    mov ecx,es:fd_size
    shr ecx,9
    dec ecx
    StartFileSystem
    jmp cfdDone

cfdFreeFail:
    xor ax,ax
    mov fs,ax
    FreeMem
    stc
    
cfdDone:
    pop bp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
create_file_drive   Endp

create_file_drive32 Proc far
    call create_file_drive
    retf32
create_file_drive32 Endp

create_file_drive16 Proc far
    push esi
    push edi
    movzx esi,si
    movzx edi,di
    call create_file_drive
    pop edi
    pop esi
    retf32
create_file_drive16 Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           OpenFileDrive
;
;           DESCRIPTION:    Open file as a logical drive
;
;           PARAMETERS:         AL          Logical drive #
;               ES:(E)DI    Filename
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

open_file_drive_name  DB 'Open File Drive',0

open_file_drive Proc near
    push ds
    push es
    push fs
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push bp
;
    mov bp,ax
    xor cx,cx
    OldUserGateForce32 open_file_nr
    jc ofdDone
;
    mov eax,SIZE file_disc_data_seg
    mov cx,ax
    AllocateSmallGlobalMem
    xor di,di
    mov es:boot_param.boot_fs,0
    ReadFile
    jc ofdFail
;
    mov edi,OFFSET boot_param.boot_fs
    IsFileSystemAvailable
    jc ofdFail
;
    GetFileInfo
    mov es:fd_access_drive,cx
    mov es:fd_selector,ax
;
    GetFileSize
    sub eax,200h
    mov es:fd_size,eax
;    
    mov cx,1
    dec eax
    shr eax,9
    inc eax

ofdIterate:
    cmp eax,100000h
    jb ofdSave
;
    shl cx,1
    shr eax,1
    jmp ofdIterate

ofdSave:
    mov es:fd_sectors_per_unit,cx
    mov es:fd_units,ax
;
    mov ecx,200h
    mov bx,es
    InstallDisc
    mov es:fd_disc_sel,bx
    mov es:fd_disc_nr,al
;
    mov ax,es:fd_sectors_per_unit
    mov cx,200h
    mov dx,es:fd_units
    xor si,si
    xor di,di    
    SetDiscParam
;
    mov ax,bp
    mov es:fd_drive_nr,al
;
    mov ah,es:fd_disc_nr
    xor edx,edx
    mov ecx,es:fd_size
    shr ecx,9
    dec ecx
    OpenDrive
;
    push es
    mov ax,es
    mov fs,ax
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov si,OFFSET discbuf_thread
    mov di,OFFSET discbuf_name
    mov ax,4
    mov cx,100h
    CreateThread
    pop es
;
    mov al,es:fd_drive_nr
    mov edi,OFFSET boot_param.boot_fs
    InstallFileSystem
;
    mov ecx,es:fd_size
    shr ecx,9
    dec ecx
    StartFileSystem
    clc
    jmp ofdDone

ofdFail:
    FreeMem
    stc
    
ofdDone:
    pop bp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop fs
    pop es
    pop ds
    ret
open_file_drive Endp

open_file_drive32 Proc far
    call open_file_drive
    retf32
open_file_drive32 Endp

open_file_drive16 Proc far
    push edi
    movzx edi,di
    call open_file_drive
    pop edi
    retf32
open_file_drive16 Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           INIT
;
;           DESCRIPTION:    Init device
;
;           PARAMETERS:         
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    public init_filedisc
    
init_filedisc   PROC near
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov ebx,OFFSET create_file_drive16
    mov esi,OFFSET create_file_drive32
    mov edi,OFFSET create_file_drive_name
    mov dx,virt_es_in
    mov ax,create_file_drive_nr
    RegisterUserGate
;
    mov ebx,OFFSET open_file_drive16
    mov esi,OFFSET open_file_drive32
    mov edi,OFFSET open_file_drive_name
    mov dx,virt_es_in
    mov ax,open_file_drive_nr
    RegisterUserGate
    ret
init_filedisc   ENDP

code    ENDS

    END

