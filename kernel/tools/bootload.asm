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
; BOOTLOAD.ASM
; Second stage boot-loader for disk / diskette
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  BootLoad

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

boot_struc	STRUC

boot_jmp					DB ?,?,?
boot_oem_name				DB 8 DUP(?)
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

	extrn Init:near

.code

	.386p

	public BootLoadInit

BootLoadInit:
	jmp Start

ReadCount		DW 0
RdosSectors		DW 0,0
CurrSector		DW 0,0
SectorsPerCyl	DW 15
Heads			DW 2
DriveNr			DB 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			singel_hex
;
;		DESCRIPTION:	
;
;		PARAMETERS:		AL		Value
;						AX		Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

singel_hex	PROC near
hex_conv_low:
	mov ah,al
	and al,0F0h
	rol al,1
	rol al,1
	rol al,1
	rol al,1
	cmp al,0Ah
	jb ok_low1
	add al,7
ok_low1:
	add al,30h
	and ah,0Fh
	cmp ah,0Ah
	jb ok_high1
	add ah,7
ok_high1:
	add ah,30h
	ret
singel_hex	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexByte
;
;		DESCRIPTION:	Write hex byte on screen
;
;		PARAMETERS:		AL		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexByte	PROC near
	push ax
	mov ah,al
	and al,0F0h
	rol al,4
	cmp al,0Ah
	jb write_byte_low1
	add al,7
write_byte_low1:
	add al,'0'
	push ax
	push bx
	mov ah,0Eh
	mov bx,7
	int 10h
	pop bx
	pop ax
	mov al,ah
	and al,0Fh
	cmp al,0Ah
	jb write_byte_high1
	add al,7
write_byte_high1:
	add al,'0'
	push bx
	mov ah,0Eh
	mov bx,7
	int 10h
	pop bx
	pop ax
	ret
WriteHexByte	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteHexWord
;
;		DESCRIPTION:	Write hex word on screen
;
;		PARAMETERS:		AX		Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteHexWord	PROC near
	xchg al,ah
	call WriteHexByte
	xchg al,ah
	call WriteHexByte
	ret
WriteHexWord	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			WriteAsciiz
;
;		DESCRIPTION:	Write text to screen
;
;		PARAMETERS:		CS:SI		Message to write
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteAsciiz	Proc near
	lods byte ptr cs:[si]
	or al,al
	jz WriteAsciizDone
	mov ah,0Eh
	mov bx,7
	int 10h
	jmp WriteAsciiz
WriteAsciizDone:
	ret
WriteAsciiz	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadSector
;
;		DESCRIPTION:	Read a sector
;
;		PARAMETERS:		DX:AX	Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector	Proc near
	push cx
;
	push ax
	mov ax,cs:ReadCount
	inc cs:ReadCount
	and ax,0Fh
	jnz ReadSectorNoLog
	mov al,'.'
	mov ah,0Eh
	mov bx,7
	int 10h
ReadSectorNoLog:
	pop ax
;
	mov cx,3
ReadSectorRetry:
	push ax
	push cx
	push dx
	div cs:SectorsPerCyl
	inc dl
	mov bl,dl
	xor dx,dx
	div cs:Heads
	mov bh,dl
	mov dx,ax
	mov ax,201h
	mov cl,6
	shl dh,cl
	or dh,bl
	mov cx,dx
	xchg ch,cl
	mov dl,cs:DriveNr
	mov dh,bh
	mov bx,1000h
	mov es,bx
	xor bx,bx
	int 13h
	pop dx
	pop cx
	pop ax
;
	jnc ReadSectorOk
	push ax
	mov ax,0
	int 13h
	pop ax
	loop ReadSectorRetry	
	stc

ReadSectorOk:
	pop cx
	ret
ReadSector	Endp

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
		 	DW 27h
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
load_gdt_cs:
			DW 0FFFFh
			DD 9A000000h
			DW 0

InitGdt	Proc near
	mov ax,cs
	movzx eax,ax
	shl eax,4
	add eax,OFFSET LoadGdt
	mov dword ptr cs:load_gdt0+2,eax
	lgdt fword ptr cs:load_gdt0
;
	mov ax,cs
	movzx eax,ax
	shl eax,4
	or dword ptr cs:load_gdt_cs+2,eax
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
	mov word ptr cs:MoveDataRmCs,cs
;
	cli
	mov eax,cr0
	or al,1
	mov cr0,eax
;
	db 0EAh
	dw OFFSET MoveDataPm
	dw 20h

MoveDataPm:
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
;
	db 0EAh
	dw OFFSET MoveDataRm
MoveDataRmCs:
	dw 0

MoveDataRm:
	sti
	popad
	pop es
	pop ds
	ret
MoveData	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LoadAdapter
;
;		DESCRIPTION:	Load adapter into extended memory
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadAdapter	Proc near
	push ds
	push esi
load_adapter_loop:
	push edi
	mov dx,cs:CurrSector+2
	mov ax,cs:CurrSector
	call ReadSector
	pop edi
	jc load_adapter_error
;
	mov esi,10000h
    mov ecx,512
	call MoveData
	add edi,ecx
	add dword ptr cs:CurrSector,1
	sub dword ptr cs:RdosSectors,1
	jnc load_adapter_loop
	jmp load_adapter_done
load_adapter_error:
	mov si,OFFSET ReadError
	call WriteAsciiz
load_adapter_done:
	pop esi
	pop ds
	ret	
LoadAdapter	Endp

LoadAdapterDone	DB 'Load adapter done',0

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
	mov word ptr cs:GetRamSizeRmCs,cs
	cli
	mov eax,cr0
	or al,1
	mov cr0,eax
;
	db 0EAh
	dw OFFSET GetRamSizePm
	dw 20h

GetRamSizePm:
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
;
	db 0EAh
	dw OFFSET GetRamSizeRm
GetRamSizeRmCs:
	dw 0

GetRamSizeRm:
	mov ecx,ebx
	sti
	pop ebx
	pop eax
	pop es
	pop ds
	ret
GetRamSize	Endp

ReadError	db 'Cannot read rdos.bin',0Dh,0Ah,0
InvFatMsg	db 0Dh,0Ah,'Unknown file-system.',0Dh,0Ah,0
LoadMsg		db 0Dh,0Ah,'Loading Rdos operating system',0


Start:
	sti
;
; test from dos
;
	mov ax,1000h
	mov es,ax
	xor bx,bx
	mov ax,201h
	mov dx,0
	mov cx,1
	int 13h
	jmp check_fs
;
	mov al,0EDh
	out 60h,al
	hlt
	hlt
	xor al,al
	out 60h,al
	hlt
	hlt
	mov al,0F4h
	out 60h,al	
;
check_fs:
	mov ax,word ptr es:boot_fs
	cmp ax,'DR'
	je LoadRdfs
	mov si,OFFSET InvFatMsg
	call WriteAsciiz
	jmp stop
LoadRdfs:
	mov cs:CurrSector,9
	mov ax,es:boot_sectors_per_cyl
	mov cs:SectorsPerCyl,ax
	mov ax,es:boot_heads
	mov cs:Heads,ax
	mov eax,es:boot_hidden_sectors
	sub eax,9
	mov dword ptr cs:RdosSectors,eax
	mov al,es:boot_drive_nr
	mov cs:DriveNr,al
LoadStart:
	mov si,OFFSET LoadMsg
	call WriteAsciiz
	call GateA20
	call InitGdt
	call GetRamSize
	mov edi,ecx
	mov ecx,dword ptr cs:RdosSectors
	shl ecx,9
	sub edi,ecx
	and di,0F000h
	push edi
	push ecx
	call LoadAdapter
	mov dx,3F2h
	mov al,0
	out dx,al
	pop ecx
	pop edi
	jmp init

stop:
	jmp stop

	END
