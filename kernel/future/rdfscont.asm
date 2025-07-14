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
; RDFSCONT.ASM
; Control sector support for RDFS (RDOS File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GateSize = 16

INCLUDE ..\user.def
INCLUDE ..\os.def
INCLUDE ..\user.inc
INCLUDE ..\os.inc
INCLUDE system.def
INCLUDE int.def
INCLUDE system.inc
INCLUDE rdfs.inc

	extrn AllocateSectors:near

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code
;
; Table is generated using 1.1777758960 as factor
;

	public ExtentSizeTab

ExtentSizeTab:
es00	DD 00000001h, 00000001h, 00000001h, 00000001h
es04	DD 00000001h, 00000002h, 00000002h, 00000003h
es08	DD 00000003h, 00000004h, 00000005h, 00000006h
es0C	DD 00000007h, 00000008h, 00000009h, 0000000Bh
es10	DD 0000000Dh, 00000010h, 00000013h, 00000016h
es14	DD 0000001Ah, 0000001Fh, 00000024h, 0000002Bh
es18	DD 00000032h, 0000003Bh, 00000046h, 00000052h
es1C	DD 00000061h, 00000073h, 00000087h, 0000009Fh
es20	DD 000000BBh, 000000DDh, 00000104h, 00000133h
es24	DD 00000169h, 000001A9h, 000001F5h, 0000024Eh
es28	DD 000002B7h, 00000333h, 000003C5h, 00000470h
es2C	DD 0000053Ah, 00000628h, 00000741h, 0000088Bh
es30	DD 00000A10h, 00000BDAh, 00000DF5h, 00001071h
es34	DD 0000135Dh, 000016CEh, 00001ADCh, 00001FA3h
es38	DD 00002543h, 00002BE2h, 000033B0h, 00003CE0h
es3C	DD 000047B3h, 00005472h, 00006375h, 00007524h
es40	DD 000089F7h, 0000A27Eh, 0000BF61h, 0000E166h
es44	DD 00010979h, 000138ABh, 00017040h, 0001B1B8h
es48	DD 0001FED3h, 000259A3h, 0002C497h, 00034290h
es4C	DD 0003D6EDh, 000485ABh, 00055379h, 000645DEh
es50	DD 0007635Ah, 0008B397h, 000A3F9Ah, 000C1204h
es54	DD 000E3759h, 0010BE56h, 0013B858h, 001739D1h
es58	DD 001B5AD7h, 002037C7h, 0025F208h, 002CB0F4h
es5C	DD 0034A2E1h, 003DFE63h, 004903C3h, 0055FEB5h
es60	DD 00654864h, 007749D5h, 008C7EB9h, 00A578BEh
es64	DD 00C2E376h, 00E588F6h, 010E573Eh, 013E669Fh
es68	DD 0177013Fh, 01B9ABF4h, 020830B6h, 0264AAE6h
es6C	DD 02D195C9h, 0351DD94h, 03E8F37Eh, 049AE569h
es70	DD 056C79B7h, 0663501Ch, 0786083Ah, 08DC6F2Ah
es74	DD 0A6FB509h, 0C4AAC1Ch, 0E7A1325h, 110CECF1h
es78	DD 1414E773h, 17A6D53Ch, 1BDB3C7Eh, 20CEFF8Bh
es7C	DD 26A4233Dh, 2D82B8A6h

;
; This table is the sum of the ExtentSizeTab
; The total sum is 2^23
;

ExtentPosTab:
ep00	DD 00000000h, 00000001h, 00000002h, 00000003h
ep04	DD 00000004h, 00000005h, 00000007h, 00000009h
ep08	DD 0000000Ch, 0000000Fh, 00000013h, 00000018h
ep0C	DD 0000001Eh, 00000025h, 0000002Dh, 00000036h
ep10	DD 00000041h, 0000004Eh, 0000005Eh, 00000071h
ep14	DD 00000087h, 000000A1h, 000000C0h, 000000E4h
ep18	DD 0000010Fh, 00000141h, 0000017Ch, 000001C2h
ep1C	DD 00000214h, 00000275h, 000002E8h, 0000036Fh
ep20	DD 0000040Eh, 000004C9h, 000005A6h, 000006AAh
ep24	DD 000007DDh, 00000946h, 00000AEFh, 00000CE4h
ep28	DD 00000F32h, 000011E9h, 0000151Ch, 000018E1h
ep2C	DD 00001D51h, 0000228Bh, 000028B3h, 00002FF4h
ep30	DD 0000387Fh, 0000428Fh, 00004E69h, 00005C5Eh
ep34	DD 00006CCFh, 0000802Ch, 000096FAh, 0000B1D6h
ep38	DD 0000D179h, 0000F6BCh, 0001229Eh, 0001564Eh
ep3C	DD 0001932Eh, 0001DAE1h, 00022F53h, 000292C8h
ep40	DD 000307ECh, 000391E3h, 00043461h, 0004F3C2h
ep44	DD 0005D528h, 0006DEA1h, 0008174Ch, 0009878Ch
ep48	DD 000B3944h, 000D3817h, 000F91BAh, 00125651h
ep4C	DD 001598E1h, 00196FCEh, 001DF579h, 002348F2h
ep50	DD 00298ED0h, 0030F22Ah, 0039A5C1h, 0043E55Bh
ep54	DD 004FF75Fh, 005E2EB8h, 006EED0Eh, 0082A566h
ep58	DD 0099DF37h, 00B53A0Eh, 00D571D5h, 00FB63DDh
ep5C	DD 012814D1h, 015CB7B2h, 019AB615h, 01E3B9D8h
ep60	DD 0239B88Dh, 029F00F1h, 03164AC6h, 03A2C97Fh
ep64	DD 0448423Dh, 050B25B3h, 05F0AEA9h, 06FF05E7h
ep68	DD 083D6C86h, 09B46DC5h, 0B6E19B9h, 0D764A6Fh
ep6C	DD 0FDAF555h, 12AC8B1Eh, 15FE68B2h, 19E75C30h
ep70	DD 1E824199h, 23EEBB50h, 2A520B6Ch, 31D813A6h
ep74	DD 3AB482D0h, 452437D9h, 516EE3F5h, 5FE8F71Ah
ep78	DD 70F5E40Bh, 850ACB7Eh, 9CB1A0BAh, 0B88CDD38h
ep7C	DD 0D95BDCC3h, 0FFFFFFFFh

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateControlSector
;
;		DESCRIPTION:	Create control sector
;
;		PARAMETERS:		DS			Drive
;						AX			Disc seq handle
;						EDX			Sector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateControlSector	Proc near
	pushad
;
	push ax
	mov al,ds:drive_nr
	NewSector
	mov edi,esi
	mov ecx,128
	xor eax,eax
	rep stos dword ptr es:[edi]
	pop ax
	ModifySeqSector
	UnlockSector
;
	inc edx
	push ax
	mov al,ds:drive_nr
	NewSector
	mov edi,esi
	mov ecx,128
	xor eax,eax
	rep stos dword ptr es:[edi]
	pop ax
	ModifySeqSector
	UnlockSector
	PerformDiscSeq
;
	popad
	ret
CreateControlSector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			CreateRootDir
;
;		DESCRIPTION:	Create root dir on drive
;
;		PARAMETERS:		DS			Drive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public CreateRootDir

CreateRootDir	Proc near
	mov ecx,2
	mov eax,-1
	EnterSection ds:alloc_section
	mov ds:info_sector.ri_target_sector,0
	mov ds:info_sector.ri_target_offset,0
	mov ds:info_sector.ri_state,INFO_STATE_ALLOC
	mov ds:info_sector.ri_count,ecx
	call AllocateSectors
	LeaveSection ds:alloc_section
	jc create_root_fail
;
	call CreateControlSector

create_root_fail:
	ret
CreateRootDir	Endp

code	ENDS

	END

