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
; RDFSTAB.ASM
; Tables for RDFS (RDOS File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME rdfstab

GateSize = 16

INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE system.def
INCLUDE int.def
INCLUDE system.inc
INCLUDE rdfs.inc

	extrn lock_sector:near

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;
;  table is generated using 1.113550787 as factor
;

ExtentSizeTab:
es00	DD  00000001h, 00000001h, 00000001h, 00000001h
es04	DD  00000001h, 00000001h, 00000001h, 00000002h
es08	DD  00000002h, 00000002h, 00000002h, 00000003h
es0C	DD  00000003h, 00000004h, 00000004h, 00000005h
es10	DD  00000005h, 00000006h, 00000006h, 00000007h
es14	DD  00000008h, 00000009h, 0000000Ah, 0000000Bh
es18	DD  0000000Dh, 0000000Eh, 00000010h, 00000012h
es1C	DD  00000014h, 00000016h, 00000019h, 0000001Ch
es20	DD  0000001Fh, 00000022h, 00000026h, 0000002Bh
es24	DD  00000030h, 00000035h, 0000003Bh, 00000042h
es28	DD  00000049h, 00000052h, 0000005Bh, 00000065h
es2C	DD  00000071h, 0000007Eh, 0000008Ch, 0000009Ch
es30	DD  000000AEh, 000000C2h, 000000D8h, 000000F1h
es34	DD  0000010Ch, 0000012Ah, 0000014Ch, 00000172h
es38	DD  0000019Ch, 000001CBh, 000001FFh, 0000023Ah
es3C	DD  0000027Ah, 000002C2h, 00000313h, 0000036Ch
es40	DD  000003CFh, 0000043Eh, 000004BAh, 00000543h
es44	DD  000005DCh, 00000687h, 00000744h, 00000818h
es48	DD  00000903h, 00000A09h, 00000B2Dh, 00000C72h
es4C	DD  00000DDBh, 00000F6Eh, 0000112Fh, 00001322h
es50	DD  0000154Fh, 000017BAh, 00001A6Ch, 00001D6Ch
es54	DD  000020C3h, 0000247Ch, 000028A0h, 00002D3Dh
es58	DD  00003260h, 00003819h, 00003E77h, 0000458Fh
es5C	DD  00004D75h, 00005641h, 0000600Dh, 00006AF5h
es60	DD  0000771Ah, 000084A0h, 000093AFh, 0000A475h
es64	DD  0000B721h, 0000CBEDh, 0000E315h, 0000FCDEh
es68	DD  00011994h, 0001398Dh, 00015D28h, 000184CEh
es6C	DD  0001B0F4h, 0001E21Eh, 000218DCh, 000255D2h
es70	DD  000299B5h, 0002E54Ch, 00033979h, 00039735h
es74	DD  0003FF95h, 000473D0h, 0004F53Dh, 0005855Ch
es78	DD  000625D9h, 0006D890h, 00079F91h, 00087D2Bh
es7C	DD  000973EFh, 000A86B8h, 000BB8B5h, 000D0D70h

;
; table is the sum of ExtentSizeTab
; total sum i 2^23
;

ExtentPosTab:
ep00	DD  00000000h, 00000001h, 00000002h, 00000003h
ep04	DD  00000004h, 00000005h, 00000006h, 00000007h
ep08	DD  00000009h, 0000000Bh, 0000000Dh, 0000000Fh
ep0C	DD  00000012h, 00000015h, 00000019h, 0000001Dh
ep10	DD  00000022h, 00000027h, 0000002Dh, 00000033h
ep14	DD  0000003Ah, 00000042h, 0000004Bh, 00000055h
ep18	DD  00000060h, 0000006Dh, 0000007Bh, 0000008Bh
ep1C	DD  0000009Dh, 000000B1h, 000000C7h, 000000E0h
ep20	DD  000000FCh, 0000011Bh, 0000013Dh, 00000163h
ep24	DD  0000018Eh, 000001BEh, 000001F3h, 0000022Eh
ep28	DD  00000270h, 000002B9h, 0000030Bh, 00000366h
ep2C	DD  000003CBh, 0000043Ch, 000004BAh, 00000546h
ep30	DD  000005E2h, 00000690h, 00000752h, 0000082Ah
ep34	DD  0000091Bh, 00000A27h, 00000B51h, 00000C9Dh
ep38	DD  00000E0Fh, 00000FABh, 00001176h, 00001375h
ep3C	DD  000015AFh, 00001829h, 00001AEBh, 00001DFEh
ep40	DD  0000216Ah, 00002539h, 00002977h, 00002E31h
ep44	DD  00003374h, 00003950h, 00003FD7h, 0000471Bh
ep48	DD  00004F33h, 00005836h, 0000623Fh, 00006D6Ch
ep4C	DD  000079DEh, 000087B9h, 00009727h, 0000A856h
ep50	DD  0000BB78h, 0000D0C7h, 0000E881h, 000102EDh
ep54	DD  00012059h, 0001411Ch, 00016598h, 00018E38h
ep58	DD  0001BB75h, 0001EDD5h, 000225EEh, 00026465h
ep5C	DD  0002A9F4h, 0002F769h, 00034DAAh, 0003ADB7h
ep60	DD  000418ACh, 00048FC6h, 00051466h, 0005A815h
ep64	DD  00064C8Ah, 000703ABh, 0007CF98h, 0008B2ADh
ep68	DD  0009AF8Bh, 000AC91Fh, 000C02ACh, 000D5FD4h
ep6C	DD  000EE4A2h, 00109596h, 001277B4h, 00149090h
ep70	DD  0016E662h, 00198017h, 001C6563h, 001F9EDCh
ep74	DD  00233611h, 002735A6h, 002BA976h, 00309EB3h
ep78	DD  0036240Fh, 003C49E8h, 00432278h, 004AC209h
ep7C	DD  00533F34h, 005CB323h, 006739DBh, 0072F290h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;		DESCRIPTION:	Helpers for allocate_sectors and free_sectors
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BitTab:
mbt0	DB 00000000b
mbt1	DB 00000001b
mbt2	DB 00000011b
mbt3	DB 00000111b
mbt4	DB 00001111b
mbt5	DB 00011111b
mbt6	DB 00111111b
mbt7	DB 01111111b
mbt8	DB 11111111b

InvBitTab:
ibt0	DB 00000000b
ibt1	DB 10000000b
ibt2	DB 11000000b
ibt3	DB 11100000b
ibt4	DB 11110000b
ibt5	DB 11111000b
ibt6	DB 11111100b
ibt7	DB 11111110b
ibt8	DB 11111111b

StartBitTab:
bbt0	DB 11111111b
bbt1	DB 11111110b
bbt2	DB 11111100b
bbt3	DB 11111000b
bbt4	DB 11110000b
bbt5	DB 11100000b
bbt6	DB 11000000b
bbt7	DB 10000000b

StopBitTab:
ebt0	DB 00000001b
ebt1	DB 00000011b
ebt2	DB 00000111b
ebt3	DB 00001111b
ebt4	DB 00011111b
ebt5	DB 00111111b
ebt6	DB 01111111b
ebt7	DB 11111111b

HighBitTab:
ht00 db 8, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4
ht10 db 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
ht20 db 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
ht30 db 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2
ht40 db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
ht50 db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
ht60 db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
ht70 db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
ht80 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ht90 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
htA0 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
htB0 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
htC0 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
htD0 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
htE0 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
htF0 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

LowBitTab:
lt00 db 8, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt10 db 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt20 db 5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt30 db 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt40 db 6, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt50 db 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt60 db 5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt70 db 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt80 db 7, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
lt90 db 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
ltA0 db 5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
ltB0 db 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
ltC0 db 6, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
ltD0 db 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
ltE0 db 5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0
ltF0 db 4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0

MidBitTab:
mt00 db 8, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4
mt10 db 4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
mt20 db 5, 4, 3, 3, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2
mt30 db 4, 3, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2
mt40 db 6, 5, 4, 4, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2
mt50 db 4, 3, 2, 2, 2, 1, 1, 1, 3, 2, 1, 1, 2, 1, 1, 1
mt60 db 5, 4, 3, 3, 2, 2, 2, 2, 3, 2, 1, 1, 2, 1, 1, 1
mt70 db 4, 3, 2, 2, 2, 1, 1, 1, 3, 2, 1, 1, 2, 1, 1, 1
mt80 db 7, 6, 5, 5, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 3, 3
mt90 db 4, 3, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2
mtA0 db 5, 4, 3, 3, 2, 2, 2, 2, 3, 2, 1, 1, 2, 1, 1, 1
mtB0 db 4, 3, 2, 2, 2, 1, 1, 1, 3, 2, 1, 1, 2, 1, 1, 1
mtC0 db 6, 5, 4, 4, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2
mtD0 db 4, 3, 2, 2, 2, 1, 1, 1, 3, 2, 1, 1, 2, 1, 1, 1
mtE0 db 5, 4, 3, 3, 2, 2, 2, 2, 3, 2, 1, 1, 2, 1, 1, 1
mtF0 db 4, 3, 2, 2, 2, 1, 1, 1, 3, 2, 1, 1, 2, 1, 1, 0

GotoNext	Macro
	local goto_next_done
	inc esi
	test si,1FFh
	clc
	jnz goto_next_done
	UnlockSector
	inc edx
	cmp edx,ds:data_sector
	stc
	je goto_next_done
	push ax
	mov al,ds:drive_nr
	call lock_sector
	pop ax
goto_next_done:
			Endm

GotoPrev	Macro
	local goto_prev_dec
	local goto_prev_done
	test si,1FFh
	jnz goto_prev_dec
	UnlockSector
	cmp edx,ds:mapping_sector
	stc
	je goto_prev_done
	dec edx
	push ax
	mov al,ds:drive_nr
	call lock_sector
	pop ax
	jmp goto_prev_done
goto_prev_dec:
	dec esi
goto_prev_done:
			Endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			ALLOCATE_SECTORS
;
;		DESCRIPTION:	ALLOCATES A NUMBER OF SECTORS
;
;		PARAMETERS:		AL			DRIVE
;						ECX			NUMBER OF SECTORS
;
;		RETURNS			EDX			LOGICAL SECTOR #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public allocate_sectors

allocate_sectors	PROC near
	push eax
	push ebx
	push ecx
	push esi
	push edi
	push ebp
;
	mov edx,ds:mapping_sector
	xor ebp,ebp
	mov al,ds:drive_nr
	call lock_sector
	push bx

allocate_sector_loop:
	mov bx,OFFSET MidBitTab
	movzx eax,byte ptr es:[esi]
	xlat byte ptr cs:MidBitTab
	cmp eax,ecx
	jnc allocate_take_one
	mov bx,OFFSET HighBitTab
	mov al,es:[esi]
	xlat byte ptr cs:HighBitTab
	movzx edi,al

allocate_try_next:
	pop bx
	GotoNext
	jc allocate_sector_done
	add ebp,8
	push bx
;
	mov bx,OFFSET LowBitTab
	movzx eax,byte ptr es:[esi]
	xlat byte ptr cs:LowBitTab
	add edi,eax
	cmp edi,ecx
	jnc allocate_take_many
	cmp al,8
	je allocate_try_next
	jmp allocate_sector_loop
	
allocate_take_one:
	mov al,cl
	mov bx,OFFSET BitTab
	xlat byte ptr cs:BitTab
	mov bl,es:[esi]
	not bl
allocate_take_one_search:
	mov ah,bl
	and ah,al
	cmp ah,al
	je allocate_take_one_do
	shl al,1
	inc ebp
	jmp allocate_take_one_search
allocate_take_one_do:
	or es:[esi],al
	pop bx
	ModifySector
	UnlockSector
	mov edx,ebp
	clc
	jmp allocate_sector_done

allocate_take_many:
	sub ebp,ecx
	movzx eax,byte ptr es:[esi]
	mov bx,OFFSET LowBitTab
	xlat byte ptr cs:LowBitTab
	add ebp,eax
	sub ecx,eax
	jnc allocate_take_many_more
	add al,cl
	mov bx,OFFSET BitTab
	xlat byte ptr cs:BitTab
	or es:[esi],al
	pop bx
	ModifySector
	UnlockSector
	mov edx,ebp
	clc
	jmp allocate_sector_done

allocate_take_many_more:
	mov bx,OFFSET BitTab
	xlat byte ptr cs:BitTab
	or es:[esi],al
;
allocate_take_many_more_loop:
	pop bx
	ModifySector
	GotoPrev
	push bx
;
	movzx eax,byte ptr es:[esi]
	mov bx,OFFSET HighBitTab
	xlat byte ptr cs:HighBitTab
	cmp eax,ecx
	jae allocate_take_many_last
	cmp al,8
	stc
	jne allocate_sector_done
	mov byte ptr es:[esi],0FFh
	jmp allocate_take_many_more_loop

allocate_take_many_last:
	mov al,cl
	mov bx,OFFSET InvBitTab
	xlat byte ptr cs:InvBitTab
	or es:[esi],al	
	pop bx
	ModifySector
	UnlockSector
	mov edx,ebp
	clc
		
allocate_sector_done:
	pop ebp
	pop edi
	pop esi
	pop ecx
	pop ebx
	pop eax
	ret
allocate_sectors	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			FREE_SECTORS
;
;		DESCRIPTION:	FREE A NUMBER OF SECTORS
;
;		PARAMETERS:		AL			DRIVE
;						ECX			NUMBER OF SECTORS
;						EDX			LOGICAL SECTOR #
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public free_sectors

free_sectors	PROC near
	push eax
	push ebx
	push ecx
	push edx
	push esi
;
	push dx
	shr edx,3
	push dx
	shr edx,9
	add edx,ds:mapping_sector
	mov al,ds:drive_nr
	call lock_sector
	pop ax
	and ax,1FFh
	or si,ax
	pop ax
	and al,7
	mov ah,al
	neg ah
	add ah,8
;
	push bx
	mov bx,OFFSET StartBitTab
	xlat byte ptr cs:StartBitTab
	mov bl,al
;
	movzx eax,ah

free_sector_loop:
	sub ecx,eax
	ja free_sector_more

free_sector_last:
	mov ah,bl
	dec al
	mov bx,OFFSET StopBitTab
	xlat byte ptr cs:StopBitTab
	and al,ah
	not al
	and es:[esi],al
	pop bx
	ModifySector
	UnlockSector
	clc
	jmp free_sector_done

free_sector_more:
	mov al,bl
	not al
	and es:[esi],al
	pop bx
	ModifySector
	GotoNext
	push bx
	mov bl,0FFh
	sub ecx,8
	ja free_sector_more
	mov al,8
	jmp free_sector_last
	
free_sector_done:
;
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop eax
	ret
free_sectors	Endp

code	ENDS

	END

