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


	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

;
; Table is generated using 11.77480735% increments (4GB max file size)
; 18.10910802% increment can be used for 2TB file size support
;

ExtentSizeTab:
es00	DD 00000001h, 00000001h, 00000001h, 00000001h
es04	DD 00000001h, 00000001h, 00000001h, 00000002h
es08	DD 00000002h, 00000002h, 00000003h, 00000003h
es0C	DD 00000003h, 00000004h, 00000004h, 00000005h
es10	DD 00000005h, 00000006h, 00000007h, 00000008h
es14	DD 00000009h, 0000000Ah, 0000000Bh, 0000000Ch
es18	DD 0000000Eh, 00000010h, 00000012h, 00000014h
es1C	DD 00000016h, 00000019h, 0000001Ch, 0000001Fh
es20	DD 00000023h, 00000027h, 0000002Ch, 00000031h
es24	DD 00000037h, 0000003Dh, 00000044h, 0000004Ch
es28	DD 00000055h, 0000005Fh, 0000006Bh, 00000077h
es2C	DD 00000086h, 00000095h, 000000A7h, 000000BBh
es30	DD 000000D1h, 000000E9h, 00000105h, 00000124h
es34	DD 00000146h, 0000016Ch, 00000197h, 000001C7h
es38	DD 000001FDh, 00000239h, 0000027Ch, 000002C7h
es3C	DD 0000031Bh, 00000379h, 000003E1h, 00000456h
es40	DD 000004D9h, 0000056Bh, 0000060Fh, 000006C5h
es44	DD 00000792h, 00000876h, 00000975h, 00000A92h
es48	DD 00000BD1h, 00000D35h, 00000EC3h, 00001080h
es4C	DD 00001272h, 0000149Eh, 0000170Bh, 000019C2h
es50	DD 00001CCAh, 0000202Eh, 000023F8h, 00002835h
es54	DD 00002CF1h, 0000323Bh, 00003826h, 00003EC2h
es58	DD 00004626h, 00004E68h, 000057A4h, 000061F6h
es5C	DD 00006D7Fh, 00007A63h, 000088CDh, 000098E8h
es60	DD 0000AAE9h, 0000BF09h, 0000D588h, 0000EEADh
es64	DD 00010AC7h, 00012A31h, 00014D4Dh, 0001748Ch
es68	DD 0001A06Ah, 0001D173h, 00020841h, 00024583h
es6C	DD 000289FCh, 0002D685h, 00032C11h, 00038BAFh
es70	DD 0003F690h, 00046E07h, 0004F38Fh, 000588CFh
es74	DD 00062FA3h, 0006EA1Bh, 0007BA89h, 0008A380h
es78	DD 0009A7E7h, 000ACAF7h, 000C104Ch, 000D7BF1h

;
; This table is the sum of the ExtentSizeTab
;

ExtentPosTab:
ep00	DD 00000000h, 00000001h, 00000002h, 00000003h
ep04	DD 00000004h, 00000005h, 00000006h, 00000007h
ep08	DD 00000009h, 0000000Bh, 0000000Dh, 00000010h
ep0C	DD 00000013h, 00000016h, 0000001Ah, 0000001Eh
ep10	DD 00000023h, 00000028h, 0000002Eh, 00000035h
ep14	DD 0000003Dh, 00000046h, 00000050h, 0000005Bh
ep18	DD 00000067h, 00000075h, 00000085h, 00000097h
ep1C	DD 000000ABh, 000000C1h, 000000DAh, 000000F6h
ep20	DD 00000115h, 00000138h, 0000015Fh, 0000018Bh
ep24	DD 000001BCh, 000001F3h, 00000230h, 00000274h
ep28	DD 000002C0h, 00000315h, 00000374h, 000003DFh
ep2C	DD 00000456h, 000004DCh, 00000571h, 00000618h
ep30	DD 000006D3h, 000007A4h, 0000088Dh, 00000992h
ep34	DD 00000AB6h, 00000BFCh, 00000D68h, 00000EFFh
ep38	DD 000010C6h, 000012C3h, 000014FCh, 00001778h
ep3C	DD 00001A3Fh, 00001D5Ah, 000020D3h, 000024B4h
ep40	DD 0000290Ah, 00002DE3h, 0000334Eh, 0000395Dh
ep44	DD 00004022h, 000047B4h, 0000502Ah, 0000599Fh
ep48	DD 00006431h, 00007002h, 00007D37h, 00008BFAh
ep4C	DD 00009C7Ah, 0000AEECh, 0000C38Ah, 0000DA95h
ep50	DD 0000F457h, 00011121h, 0001314Fh, 00015547h
ep54	DD 00017D7Ch, 0001AA6Dh, 0001DCA8h, 000214CEh
ep58	DD 00025390h, 000299B6h, 0002E81Eh, 00033FC2h
ep5C	DD 0003A1B8h, 00040F37h, 0004899Ah, 00051267h
ep60	DD 0005AB4Fh, 00065638h, 00071541h, 0007EAC9h
ep64	DD 0008D976h, 0009E43Dh, 000B0E6Eh, 000C5BBBh
ep68	DD 000DD047h, 000F70B1h, 00114224h, 00134A65h
ep6C	DD 00158FE8h, 001819E4h, 001AF069h, 001E1C7Ah
ep70	DD 0021A829h, 00259EB9h, 002A0CC0h, 002F004Fh
ep74	DD 0034891Eh, 003AB8C1h, 0041A2DCh, 00495D65h
ep78	DD 005200E5h, 005BA8CCh, 006673C3h, 0072840Fh

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
	LockSector
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
	LockSector
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
	LockSector
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
	LockSector
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

