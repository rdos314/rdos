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
; FATBOOT.ASM
; Second stage boot-loader for FAT12, FAT16 and FAT32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME  FatBoot

;;;;;;;;; INTERNAL PROCEDURES ;;;;;;;;;;;

.model Small

DATA_SEG = 6000h

boot_struc	STRUC

boot_jmp					DB ?,?,?
boot_name					DB 8 DUP(?)
boot_bytes_per_sector		DW ?
boot_sectors_per_cluster	DB ?
boot_resv_sectors			DW ?
boot_fats					DB ?
boot_root_dirs				DW ?
boot_sectors16				DW ?
boot_media					DB ?
boot_fat_sectors16			DW ?
boot_sectors_per_cyl		DW ?
boot_heads					DW ?
boot_hidden_sectors			DD ?
boot_sectors				DD ?
boot_fat_sectors			DD ?
boot_ext_flags				DW ?
boot_fs_version				DW ?
boot_root_cluster			DD ?
boot_info_sector			DW ?
boot_backup_sector			DW ?

boot_struc		ENDS

fat_dir_struc	STRUC

fat_base		DB 8 DUP(?)
fat_ext			DB 3 DUP(?)
fat_attrib		DB ?
fat_case		DB ?
fat_cr_time_ms	DB ?
fat_cr_time		DW ?
fat_cr_date		DW ?
fat_acc_date	DW ?
fat_cluster_hi	DW ?
fat_time		DW ?
fat_date		DW ?
fat_cluster		DW ?
fat_file_size	DD ?

fat_dir_struc	ENDS

	extrn Init:near

.code

	.386p

	public BootLoadInit

BootLoadInit:
	jmp Start

ReadCount	    	DW 0
RdosSectors		    DW 0,0
CurrSector		    DW 0,0
SectorsPerCyl	    DW 15
Heads			    DW 2
DriveNr			    DB 80h
BootSector          DD 0
FatSector           DD 0
RootSector          DD 0
DataSector          DD 0
SectorsPerFat       DD 0
CurrentCluster      DD 0
RootEntries         DW 0
PartType            DB 0
FatSize             DB 0
SafeBoot            DB 0
SectorsPerCluster   DW 0
ImageSize           DD 0
CurrSector2         DD 0

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
;		DESCRIPTION:	Read a sector (to DATA_SEG:0)
;
;		PARAMETERS:		EAX	Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector	Proc near
    push es
    pusha
;
    push eax
    pop ax
    pop dx
;    
	push ax
	mov ax,cs:ReadCount
	inc cs:ReadCount
	and ax,0Fh
	jnz ReadSectorNoLog
;	
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
	mov bx,DATA_SEG
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
	popa
	pop es
	ret
ReadSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ReadSector2
;
;		DESCRIPTION:	Read a sector (to DATA_SEG:200)
;
;		PARAMETERS:		EAX	Sector #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector2	Proc near
    push es
    pusha
;
    cmp eax,cs:CurrSector2
    clc
    je ReadSectorOk2
;    
    mov cs:CurrSector2,eax
    push eax
    pop ax
    pop dx
;    
	push ax
	mov ax,cs:ReadCount
	inc cs:ReadCount
	and ax,0Fh
	jnz ReadSectorNoLog2
;	
	mov al,'.'
	mov ah,0Eh
	mov bx,7
	int 10h
ReadSectorNoLog2:
	pop ax
;
	mov cx,3
ReadSectorRetry2:
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
	mov bx,DATA_SEG
	mov es,bx
	mov bx,200h
	int 13h
	pop dx
	pop cx
	pop ax
;
	jnc ReadSectorOk2
	push ax
	mov ax,0
	int 13h
	pop ax
	loop ReadSectorRetry2	
	stc

ReadSectorOk2:
	popa
	pop es
	ret
ReadSector2	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NextCluster12
;
;		DESCRIPTION:	Find next cluster for FAT12
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster12	PROC near
	push ebx
	push cx
;
    mov edx,cs:CurrentCluster
	mov cx,dx
	add dx,dx
	add dx,cx
	mov cx,dx
	movzx edx,dx
	shr edx,10
	add edx,cs:FatSector
	and cx,3FFh
	clc
	rcr cx,1
	pushf
	mov eax,edx
	call ReadSector2
	jnc nc12Locked
	popf
	stc
	jmp nc12Done

nc12Locked:
	mov bx,cx
	add bx,200h
	popf
	jc nc12High
	mov cl,[bx]
	inc bx
	test bx,1FFh
	jnz nc12LowOk
	inc edx
	mov eax,edx
	call ReadSector2
	jc nc12Done
;
    mov bx,200h

nc12LowOk:
	mov ch,[bx]
	and cx,0FFFh
	jmp nc12Ok

nc12High:
	mov ch,[bx]
	and ch,0F0h
	inc bx
	test bx,1FFh
	jnz nc12HighOk
	inc edx
	mov eax,edx
	mov bx,200h
	call ReadSector2
	jc nc12Done

nc12HighOk:
	mov cl,[bx]
	rol cx,4
nc12Ok:
	movzx edx,cx
	mov cs:CurrentCluster,edx
	cmp edx,0FF8h
	cmc

nc12Done:
	pop cx
	pop ebx
	ret
NextCluster12	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NextCluster16
;
;		DESCRIPTION:	Find next cluster for FAT16
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster16	PROC near
	push ebx
	push cx
;
    mov edx,cs:CurrentCluster
	add edx,edx
	mov cx,dx
	shr edx,9
	add edx,cs:FatSector
	and cx,1FFh
	mov eax,edx
	call ReadSector2
	jc nc16Done

	mov bx,cx
	add bx,200h
	movzx edx,word ptr [bx]
	mov cs:CurrentCluster,edx
	cmp edx,0FFF8h
	cmc

nc16Done:
	pop cx
	pop ebx
	ret
NextCluster16	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NextCluster32
;
;		DESCRIPTION:	Find next cluster for FAT32
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster32	PROC near
	push ebx
	push cx
;
    mov edx,cs:CurrentCluster
	shl edx,2
	mov cx,dx
	shr edx,9
	add edx,cs:FatSector
	and cx,1FFh
	mov eax,edx
	call ReadSector2
	jc nc32Done

	mov bx,cx
	add bx,200h
	mov edx,[bx]
	and edx,0FFFFFFFh
	mov cs:CurrentCluster,edx
	cmp edx,0FFFFFF8h
	cmc

nc32Done:
	pop cx
	pop ebx
	ret
NextCluster32	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			NextCluster
;
;		DESCRIPTION:	Find next cluster
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NextCluster	Proc near
	cmp cs:FatSize,12
	je nextc12
;
	cmp cs:FatSize,16
	je nextc16

nextc32:
	call NextCluster32
	jmp next_cluster_done

nextc16:
	call NextCluster16
	jmp next_cluster_done

nextc12:
	call NextCluster12

next_cluster_done:
	ret
NextCluster	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GetCurrentSector
;
;		DESCRIPTION:	Get current sector
;
;       RETURNS:        EDX     Sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetCurrentSector    Proc near
    mov edx,cs:CurrentCluster
	sub edx,2
	movzx eax,cs:SectorsPerCluster
	mul edx
	mov edx,eax
	add edx,cs:DataSector
	ret
GetCurrentSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ScanDir
;
;		DESCRIPTION:	Scan a directory
;
;       PARAMETERS:     DI          File to scan for
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScanDir Proc near
    push ds
    push es
    push eax
    push cx
    push bp
;    
    mov ax,cs
    mov es,ax
    mov ax,DATA_SEG
    mov ds,ax

sdClusterLoop:
    call GetCurrentSector
    mov eax,edx
    mov cx,cs:SectorsPerCluster    

sdSectorLoop:
    mov si,200h
    call ReadSector2

sdLoop:
    push cx
    push si
    push di    
    mov cx,11
    repz cmps byte ptr [si],es:[di]    
    pop di
    pop si
    pop cx
    jz sdFound
;
    add si,20h
    test si,1FFh
    jnz sdLoop
;
    inc eax
    loop sdSectorLoop
;
    call NextCluster
    jnc sdClusterLoop
    jmp sdDone

sdFound:
    movzx edx,ds:[si].fat_cluster
    cmp cs:FatSize,32
    jnz sdClustOk
;
    movzx eax,ds:[si].fat_cluster_hi
    shl eax,16
    or edx,eax

sdClustOk:       
    mov cs:CurrentCluster,edx
    mov eax,ds:[si].fat_file_size
    mov cs:ImageSize,eax
    clc

sdDone:
    pop bp
    pop cx
    pop eax
    pop es
    pop ds       
    ret
ScanDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ScanRootDir
;
;		DESCRIPTION:	Scan root directory
;
;       PARAMETERS:     DI          File to scan for
;
;       RETURNS:        EDX         Start cluster # of file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ScanRootDir Proc near
    push ds
    push es
    push eax
    push cx
;    
    mov ax,cs
    mov es,ax
    mov ax,DATA_SEG
    mov ds,ax
    xor si,si
    mov cx,cs:RootEntries
    mov eax,cs:RootSector
    call ReadSector

srdLoop:
    push cx
    push si
    push di    
    mov cx,11
    repz cmps byte ptr [si],es:[di]    
    pop di
    pop si
    pop cx
    jz srdFound
;
    add si,20h
    test si,1FFh
    jnz srdNextEntry
;
    xor si,si
    inc eax
    call ReadSector

srdNextEntry:
    loop srdLoop
;
    stc
    jmp srdDone

srdFound:
    movzx edx,ds:[si].fat_cluster
    mov cs:CurrentCluster,edx
    mov eax,ds:[si].fat_file_size
    mov cs:ImageSize,eax
    clc

srdDone:
    pop cx
    pop eax
    pop es
    pop ds       
    ret
ScanRootDir Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FindImageFile
;
;		DESCRIPTION:	Find boot image file
;
;       RETURNS:        EDX     Cluster #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NormalImage DB 'RDOS    BIN'
SafeImage   DB 'SAFE    BIN'

FindImageFile   Proc near
    mov al,cs:SafeBoot
    or al,al
    jz fifNormal
;
    mov di,OFFSET SafeImage
    jmp fifType 

fifNormal:
    mov di,OFFSET NormalImage

fifType:
    mov al,cs:FatSize
    cmp al,32
    je fif32
;
    call ScanRootDir
    ret

fif32:
    call ScanDir
    ret
FindImageFile   Endp

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
;    
    mov ax,cs
    mov es,ax
    mov ax,DATA_SEG
    mov ds,ax

laClusterLoop:
    call GetCurrentSector
    mov eax,edx
    push eax
    pop bx
    pop bx
    mov cx,cs:SectorsPerCluster    

laSectorLoop:
    xor si,si
    call ReadSector
    jc laError
;
    push eax
    push cx
	mov esi,16 * DATA_SEG
    mov ecx,512
	call MoveData
	add edi,ecx
	pop cx
	pop eax
;
    sub cs:ImageSize,200h
    jbe laDone
;
    inc eax
    loop laSectorLoop
;
    call NextCluster
    jnc laClusterLoop
    jmp laDone
    
laError:
	mov si,OFFSET ReadError
	call WriteAsciiz
	
laDone:
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

InvalidDisc db 'Cannot read partition table and / or disc', 0Dh, 0Ah, 0
BootNotFound db 'Cannot find boot image', 0Dh, 0Ah, 0

PartTypeTab:
p00 DB 0
p01 DB 12
p02 DB 0
p03 DB 0
p04 DB 16
p05 DB 0
p06 DB 16
p07 DB 0
p08 DB 0
p09 DB 0
p0A DB 0
p0B DB 32
p0C DB 32
p0D DB 0
p0E DB 0
p0F DB 0

read_part_error:
    mov si,OFFSET InvalidDisc
    call WriteAsciiz

part_stop:
    jmp part_stop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		DESCRIPTION:	Second stage boot-loader entry point
;
;		RETURNS:	    DL          Bios disc #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Start:
	sti
	mov cs:DriveNr,dl
	mov ax,DATA_SEG
	mov es,ax
	xor bx,bx
	mov ax,201h
	xor dx,dx
	mov dl,cs:DriveNr
	mov cx,1
	int 13h
;
    mov bx,1BEh
    mov si,bx
    mov al,es:[bx+4]
    mov cs:PartType,al
    mov cx,es:[bx+2]
    mov dh,es:[bx+1]
	mov ax,201h
	mov dl,cs:DriveNr
	mov bx,200h
	int 13h
	jc read_part_error
;
    mov ax,es:[bx].boot_sectors_per_cyl
    mov cs:SectorsPerCyl,ax
    mov ax,es:[bx].boot_heads
    mov cs:Heads,ax
;    
    mov al,es:[si+3]
    mov ah,es:[si+2]
    shr ah,6
    mov cx,cs:Heads
    mul cx
    add al,es:[si+1]
    adc ah,0
    mul cs:SectorsPerCyl
    mov cl,es:[si+2]
    and cl,3Fh
    dec cl
    add al,cl
    adc ah,0
    adc dx,0
;
    mov cs:CurrSector2,-1
;    
    mov word ptr cs:BootSector,ax
    mov word ptr cs:BootSector+2,dx
    mov eax,cs:BootSector
;        
    call ReadSector
    jc read_part_error
;
    mov al,cs:PartType
    cmp al,10h
    jae read_part_error
;
    mov bx,OFFSET PartTypeTab
    xlat byte ptr cs:PartTypeTab
    or al,al
    je read_part_error
;
    mov cs:FatSize,al     
;    
    movzx eax,es:boot_resv_sectors
    add eax,cs:BootSector
    mov cs:FatSector,eax
;
    movzx eax,es:boot_fat_sectors16
    or ax,ax
    jnz boot_fat_sectors_ok
;
    mov eax,es:boot_fat_sectors

boot_fat_sectors_ok:
    mov cs:SectorsPerFat,eax
    mov eax,cs:FatSector
;
    mov cl,es:boot_fats
    or cl,cl
    jz read_part_error

boot_fat_adv_loop:
    add eax,cs:SectorsPerFat
    sub es:boot_fats,1
    jnz boot_fat_adv_loop
;
    cmp cs:FatSize,32
    je boot_data_sector_ok
;
    mov cs:RootSector,eax
    movzx ecx,es:boot_root_dirs
    shr ecx,4
    add eax,ecx

boot_data_sector_ok:    
    mov cs:DataSector,eax
    mov eax,es:boot_root_cluster
    mov cs:CurrentCluster,eax
    mov ax,es:boot_root_dirs
    mov cs:RootEntries,ax
    movzx ax,es:boot_sectors_per_cluster
    mov cs:SectorsPerCluster,ax
    call FindImageFile
    jnc LoadStart
;    
    mov si,OFFSET BootNotFound
    call WriteAsciiz
    
LoadStart:
	mov si,OFFSET LoadMsg
	call WriteAsciiz
	call GateA20
	call InitGdt
	call GetRamSize
	mov edi,ecx
	mov ecx,cs:ImageSize
	dec ecx
	and cx,0F000h
	add ecx,1000h
	push ecx
	pop ax
	pop ax
	sub edi,ecx
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
