;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 2000, Leif Ekblad
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
; LOAD.ASM
; OS loader from real-mode DOS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		NAME  load

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

.386c

exeh_seg	STRUC
exeh_signature		DW ?
exeh_size_lsb		DW ?
exeh_size_msb		DW ?
exeh_reloc_ant		DW ?
exeh_size_header	DW ?
exeh_minalloc		DW ?
exeh_maxalloc		DW ?
exeh_ss				DW ?
exeh_sp				DW ?
exeh_checksum		DW ?
exeh_ip				DW ?
exeh_cs				DW ?
exeh_reloc_offs		DW ?
exeh_ov_nr			DW ?
exeh_seg	ENDS

boot_struc	STRUC

VECT_SIGN	= 0A567AD32h

boot_jmp					DB ?,?,?
boot_name					DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_resv1					DB ?
boot_mapping_sectors		DW ?
boot_resv3					DB ?
boot_resv4					DW ?
boot_small_sectors			DW ?
boot_media					DB ?
boot_resv6					DW ?
boot_sectors_per_cyl		DW ?
boot_heads					DW ?
boot_hidden_sectors			DD ?
boot_sectors				DD ?
boot_drive_nr				DB ?,?
boot_signature				DB ?
boot_serial					DD ?
boot_volume					DB 11 DUP(?)
boot_fs						DB 8 DUP(?)

boot_struc		ENDS

.stack
.data

VectName	DB '\vect.dat',0

CurrentSector	DW ?

BootBuf		DB 512 DUP(?)

BootSector	DB 512 Dup(0)

BinHandle   DW ?

Buffer      DB 8000h DUP(?)

.code

.386p

	extrn BootVectInit:near

vect_error	DB 'Cannot find original BIOS vectors',0Dh, 0Ah,24h
bin_error   DB 'Cannot find .bin fil',0Dh,0Ah,24h
read_boot_error	DB 'cannot read bootsector',0Dh,0Ah,24h
write_boot_error	DB 'cannot write bootsector',0Dh,0Ah,24h
write_sector_error	DB 'cannot write sector',0Dh,0Ah,24h
exe_error   DB 'cannot find bootvect.exe',0Dh,0Ah,24h
disk_msg	DB 0Dh, 0Ah
			DB 'RDOS needs to capture the default interupt vectors', 0Dh, 0Ah
			DB 'Press B to create boot-vector capture disk', 0Dh, 0Ah
			DB 'Press R to read previously captured vectors',0Dh, 0Ah, 24h
		
read_vect_error		DB 'cannot read vectors',0Dh,0Ah,24h
create_vect_error	DB 'cannot create vector file',0Dh,0Ah,24h
write_vect_error	DB 'cannot write vectors',0Dh,0Ah,24h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			Log
;
;		DESCRIPTION:	Log error
;
;       PARAMETERS:     DX      offset to error message
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Log Proc near
    push ds
    pushf
    push ax
    mov ax,cs
    mov ds,ax
    mov ah,9
	int 21h
    pop ax
    popf
    pop ds
    ret
Log Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadSector
;
;		DESCRIPTION:	Read sector from disc
;
;		PARAMETERS:		DX		Sector #
;						ES:BX	Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector	Proc near
	push cx
;
	mov cx,3
read_sector_loop:
	push ax
	push cx
	push dx
;
	push bx
	mov ax,dx
	xor dx,dx
	mov bx,12h
	div bx
	inc dl
	mov cl,dl
	xor dx,dx
	mov bl,2
	div bl
	pop bx
	mov dh,dl
	mov ch,al
	mov dl,0
	mov ax,0201h
	int 13h
	pop dx
	pop cx
	pop ax
	jnc read_sector_done
	push ax
	push dx
	mov ax,0
	mov dl,0
	int 13h
	pop dx
	pop ax
	loop read_sector_loop
read_sector_done:
	pop cx
	ret
ReadSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteSector
;
;		DESCRIPTION:	Write sector to disc
;
;		PARAMETERS:		DX		Sector #
;						ES:BX	Buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteSector	Proc near
	push cx
;
	mov cx,3
write_sector_loop:
	push ax
	push cx
	push dx
;
	mov ax,dx
	xor dx,dx
	div BootSector.boot_sectors_per_cyl
	inc dl
	mov cl,dl
	xor dx,dx
	div BootSector.boot_heads
	mov dh,dl
	mov ch,al
	mov dl,0
	mov ax,0301h
	int 13h
	pop dx
	pop cx
	pop ax
	jnc write_sector_done
	push ax
	push dx
	mov ax,0
	mov dl,0
	int 13h
	pop dx
	pop ax
	loop write_sector_loop
write_sector_done:
	pop cx
	ret
WriteSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitBootRecord
;
;		DESCRIPTION:	Init bootrecord buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

rdfs_name	DB 'RDFS    '

InitBootRecord	Proc near
	mov edx,2880
	mov BootSector.boot_bytes_per_sector,200h
	mov BootSector.boot_sectors_per_cyl,12h
	mov BootSector.boot_heads,2
	mov BootSector.boot_small_sectors,dx
	mov BootSector.boot_media,0
	mov BootSector.boot_sectors,edx
	mov ah,2Ch
	int 21h
	mov word ptr BootSector.boot_serial,cx
	mov word ptr BootSector.boot_serial+2,dx
	mov di,OFFSET BootSector.boot_fs
	mov cx,8
	mov si,OFFSET rdfs_name
	rep movs byte ptr es:[di],cs:[si]
	ret
InitBootRecord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadBoot
;
;		DESCRIPTION:	Load bootvect app into buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadBoot	Proc near
	push ds
	push es
;
	mov ax,cs
	mov ds,ax
	mov si,OFFSET BootVectInit
	mov ax,SEG @data
	mov es,ax
	mov di,OFFSET BootBuf
	mov cx,80h
	rep movsd
;
	pop es
	pop ds
	ret
LoadBoot	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MergeBootRecord
;
;		DESCRIPTION:	Merge boot.exe with boot-record
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MergeBootRecord	Proc near
	mov di,OFFSET BootSector
	mov si,OFFSET BootBuf
	mov cx,11
	rep movsb
	add si,33h
	add di,33h
	mov cx,200h - 3Eh
	rep movsb
;
	mov di,OFFSET BootSector
	movzx edx,CurrentSector
	mov es:[di].boot_hidden_sectors,edx
;
	mov edx,2880
	sub dx,CurrentSector
	shr edx,12
	inc dx
	mov es:[di].boot_mapping_sectors,dx
	ret
MergeBootRecord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			SaveBootRecord
;
;		DESCRIPTION:	Save bootrecord from buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SaveBootRecord	Proc near
	mov bx,OFFSET BootSector
	mov ax,301h
	mov cx,1
	mov dx,0
	int 13h
	jnc save_boot_record_done
    mov dx,OFFSET write_boot_error
    call Log
	stc
save_boot_record_done:
	ret
SaveBootRecord	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadVect
;
;		DESCRIPTION:	Read vectors to buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadVect	Proc near
	mov bx,OFFSET Buffer
	mov dx,1
;
	mov cx,8

read_vect_loop:
	call ReadSector
	jc read_vect_done
;
	add bx,200h
	inc dx
	loop read_vect_loop
	clc

read_vect_done:
	ret
ReadVect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteVect
;
;		DESCRIPTION:	write vectors to file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteVect	Proc near
	mov dx,OFFSET VectName
	mov ax,3C00h
	xor cx,cx
	int 21h
    jnc write_vect_ok
    mov dx,OFFSET create_vect_error
    call Log
	stc
    jmp write_vect_done
write_vect_ok:
	mov bx,ax
	mov dx,OFFSET Buffer
	mov si,dx
	mov cx,1000h
	mov ah,40h
	int 21h
	mov ah,3Eh
	int 21h
	clc
write_vect_done:
	ret
WriteVect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckMedia
;
;		DESCRIPTION:	Check if vectors are saved on disk
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckMedia	Proc near
	mov ax,SEG _data
	mov ds,ax
	mov es,ax
	mov bx,OFFSET Buffer
	xor dx,dx
	call ReadSector
	jc check_media_done
;
	mov eax,dword ptr [bx].boot_name
	cmp eax,VECT_SIGN
	stc
	jne check_media_done
;
	clc

check_media_done:
	ret
CheckMedia	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CheckVect
;
;		DESCRIPTION:	Check if bios vectors are in place
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CheckVect	Proc near
	mov ax,_data
	mov ds,ax
	mov es,ax
;
	mov dx,OFFSET VectName
	mov ax,3D00h
	int 21h
    jnc load_boot_ok

load_boot_retry:
	mov dx,OFFSET disk_msg
	call Log
;
	mov ah,7
	int 21h
;
	cmp al,'r'
	je load_boot_move
;
	cmp al,'R'
	je load_boot_move
;
	cmp al,'b'
	je load_boot_create
;
	cmp al,'B'
	jne load_boot_retry

load_boot_create:
	call InitBootRecord
	call LoadBoot
	call MergeBootRecord
	call SaveBootRecord
	jc load_boot_retry
;
	mov eax,cr0
	or eax,80000001h
	mov cr0,eax

load_boot_move:
	call CheckMedia
	jc load_boot_retry
;
	mov ax,_data
	mov ds,ax
	mov es,ax
	call ReadVect
	call WriteVect
	jc load_boot_retry
;
	ret

load_boot_ok:
	mov bx,ax
	mov ah,3Eh
	int 21h
	ret
CheckVect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GateA20
;
;		DESCRIPTION:	Enable A20 line
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateA20	Proc near
wait_gate1:
	in al,64h
	and al,2
	jnz wait_gate1
	mov al,0D1h
	out 64h,al
wait_gate2:
	in al,64h
	and al,2
	jnz wait_gate2
	mov al,0DFh
	out 60h,al
wait_gate3:
	in al,64h
	and al,2
	jnz wait_gate3
	xor cx,cx
gate_wait:
	inc ax
	loop gate_wait
	ret
GateA20	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			InitGdt
;
;		DESCRIPTION:	Init protected mode GDT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

source_sel	EQU 8
dest_sel	EQU 10h
flat_sel	EQU 18h

LoadGdt:
load_gdt0:
		 	DW 1Fh
			DD 0
			DW 0
load_gdt_source:
            DW 0FFFFh
            DD 92000000h
            DW 0
load_gdt_dest:
            DW 0FFFFh
            DD 92300000h
            DW 0
load_gdt_flat:
			DW 0FFFFh
			DD 92000000h
			DW 008Fh

InitGdt	Proc near
	mov ax,cs
	movzx eax,ax
	shl eax,4
	add eax,OFFSET LoadGdt
	mov dword ptr cs:load_gdt0+2,eax
	lgdt fword ptr cs:load_gdt0
	ret
InitGdt	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			MoveData
;
;		DESCRIPTION:	Move data to extended memory
;
;		PARAMETERS:		ESI		Linear source address
;						EDI		Linear dest address
;						ECX		Number of bytes to move
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MoveData	Proc near
	push ds
	push es
	pushad
;
	mov eax,esi
	mov dword ptr cs:load_gdt_source+2,eax
	mov al,92h
	xchg al,byte ptr cs:load_gdt_source+5
	mov byte ptr cs:load_gdt_source+7,al
;
	mov eax,edi
	mov dword ptr cs:load_gdt_dest+2,eax
	mov al,92h
	xchg al,byte ptr cs:load_gdt_dest+5
	mov byte ptr cs:load_gdt_dest+7,al
;
	cli
	mov eax,cr0
	or al,1
	mov cr0,eax
	jmp short $+2
;
	mov ax,source_sel
	mov ds,ax
	mov ax,dest_sel
	mov es,ax
	xor esi,esi
	xor edi,edi
	rep movs byte ptr es:[edi],[esi]
;
	mov eax,cr0
	and al,NOT 1
	mov cr0,eax
	sti
	popad
	pop es
	pop ds
	ret
MoveData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadBin
;
;		DESCRIPTION:	Load binary file to extended memory
;
;		PARAMETERS:		EDI		linear address in extended memory
;
;		RETURNS:		EDI		New linear address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadBin Proc near
	push ds
	push esi
;
	mov ax,SEG _data
	mov ds,ax
    mov bx,BinHandle
    mov ax,4200h
    xor cx,cx
    xor dx,dx
    int 21h

LoadBinLoop:
	push edi
    mov cx,8000h
    mov dx,OFFSET Buffer
    mov ah,3Fh
    int 21h
	pop edi
    or ax,ax
	jz LoadBinDone
	mov esi,SEG Buffer
	shl esi,4
	add esi,OFFSET Buffer
    movzx ecx,ax
	call MoveData
LoadBinNext:
	add edi,ecx
    jmp LoadBinLoop
LoadBinDone:
	pop esi
	pop ds
    ret
LoadBin Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetBinSize
;
;		DESCRIPTION:	Get size of bin-file
;
;		RETURNS:		ECX		Size of bin-file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBinSize Proc near
	push ds
;
	mov ax,SEG _data
	mov ds,ax
    mov bx,BinHandle
    mov ax,4202h
    xor cx,cx
    xor dx,dx
    int 21h
	push dx
	push ax
	pop ecx
;
	pop ds
    ret
GetBinSize Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			OpenBin
;
;		DESCRIPTION:	Open binary file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

opn_name    EQU -128
opn_pos     EQU -130

OpenBin   Proc near
    push bp
    mov bp,sp
    sub sp,130
    push ds
    push es
    push edi
;
	mov ax,ss
	mov es,ax
    lea di,[bp].opn_name
init_file_next:
	lodsb
	cmp al,0Dh
	je init_file_done
	cmp al,' '
	je init_file_next
	cmp al,'	'
	je init_file_next
init_file_save_next:
	stosb
	lodsb
	cmp al,0Dh
	je init_file_done
	cmp al,' '
	je init_file_done
	cmp al,'	'
	je init_file_done
	jmp init_file_save_next
init_file_done:
	dec si
	mov [bp].opn_pos,di
	mov ax,'B.'
	stosw
	mov ax,'NI'
	stosw
	xor ax,ax
	stosw
;
	mov ax,ss
	mov ds,ax
	lea dx,[bp].opn_name
	mov ax,3D00h
	int 21h
    mov dx,SEG _data
    mov ds,dx
    mov BinHandle,ax
    jnc OpenBinOk
    mov dx,OFFSET bin_error
    call Log
    stc
OpenBinOk:
    pop edi
    pop es
    pop ds
    lahf
    add sp,130
    sahf
    pop bp
    ret
OpenBin   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CloseBin
;
;		DESCRIPTION:	Close binary file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CloseBin  Proc near
	push ds
	push edi
	mov ax,SEG _data
	mov ds,ax
    mov bx,BinHandle
	mov ah,3Eh
	int 21h
	pop edi
	pop ds
    ret
CloseBin   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetRamSize
;
;		DESCRIPTION:	Get size of physical memory
;
;		RETURNS:		ECX		Number of bytes of physical memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRamSize	Proc near
	push ds
	push es
	push eax
	push ebx
;	
	cli
	mov eax,cr0
	or al,1
	mov cr0,eax
	jmp short $+2
;
	mov ax,flat_sel
	mov ds,ax
	mov ebx,110000h
	mov eax,851A7EC2h

GetRamSizeLoop:
	mov [ebx],eax
	cmp eax,[ebx]
	jne GetRamSizeDone
	add ebx,1000h
	jnc GetRamSizeLoop

GetRamSizeDone:
	mov ax,source_sel
	mov ds,ax
;
	mov eax,cr0
	and al,NOT 1
	mov cr0,eax
	mov ecx,ebx
	sti
	pop ebx
	pop eax
	pop es
	pop ds
	ret
GetRamSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadAdapter
;
;		DESCRIPTION:	Load all adapters in extended memory
;
;		PARAMETERS:		EDI		Load address
;
;		RETURNS:		ECX		Bytes loaded
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadAdapter	Proc near
	push edi
;
	push edi
	mov ah,62h
	int 21h
	mov ds,bx
	mov si,81h
LoadAdapterLoop:
	mov al,[si]
	cmp al,0Dh
	je LoadAdapterDone
    call OpenBin
    jc LoadAdapterDone
	pop edi
    call LoadBin
    call CloseBin
	dec edi
	and di,0F000h
	add edi,1000h
	push edi
	jmp LoadAdapterLoop

LoadAdapterDone:
	pop ecx
	pop edi
	sub ecx,edi
	ret
LoadAdapter	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadVect
;
;		DESCRIPTION:	Load original BIOS vectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadVect	Proc near
	push ds
	push es
	pusha
;
	mov ax,SEG _data
	mov ds,ax
	mov dx,OFFSET VectName
	mov ax,3D00h
	int 21h
    jnc LoadVectOk
;
    mov dx,OFFSET vect_error
    call Log
vect_stop:
	jmp vect_stop

LoadVectOk:
	mov bx,ax
	mov ax,SEG _data
	mov ds,ax
	mov dx,OFFSET Buffer
	mov cx,1000h
	mov ah,3Fh
	int 21h
;
	mov ah,3Eh
	int 21h
;
	cli
	xor ax,ax
	mov es,ax
	xor di,di
	mov si,OFFSET Buffer
	mov cx,400h
	rep movsd
;
	popa
	pop es
	pop ds
	ret
LoadVect	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetAdapterSize
;
;		DESCRIPTION:	Get size of all adapters
;
;		RETURNS:		ECX		Size of all adapters
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAdapterSize	Proc near
	push edi
;
	mov ah,62h
	int 21h
	mov ds,bx
	mov si,81h
	xor edi,edi
GetAdapterSizeLoop:
	push edi
	mov al,[si]
	cmp al,0Dh
	je GetAdapterSizeDone
    call OpenBin
    jc GetAdapterSizeDone
	pop edi
	call GetBinSize
	add edi,ecx
    call CloseBin
	dec edi
	and di,0F000h
	add edi,1000h
	jmp GetAdapterSizeLoop

GetAdapterSizeDone:
	pop edi
	mov ecx,edi
	pop edi
	ret
GetAdapterSize	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			load
;
;		DESCRIPTION:	Startup code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	extrn init:near

load:
    mov ax,3
    int 10h
;    
	call CheckVect
	call GateA20
	call InitGdt
	call GetRamSize
	mov edi,ecx
	call GetAdapterSize
	sub edi,ecx
	push edi
	call LoadAdapter
	call LoadVect
	mov dx,3F2h
	mov al,0
	out dx,al
	pop edi
	jmp init

	END load

