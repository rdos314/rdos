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
; RDFSMISC.ASM
; Untilty functions for RDFS (RDOS File System)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						
		NAME rdfsmisc

GateSize = 16

INCLUDE driver.def
INCLUDE protseg.def
INCLUDE user.def
INCLUDE virt.def
INCLUDE os.def
INCLUDE user.inc
INCLUDE virt.inc
INCLUDE os.inc
INCLUDE system.def
INCLUDE system.inc
INCLUDE rdfs.inc

	.386p

code	SEGMENT byte public use16 'CODE'

	assume cs:code

CryptTab:
ct000  DB 0ECh, 043h, 087h, 083h, 080h, 009h, 07Ah, 021h
ct008  DB 011h, 0FFh, 086h, 0DEh, 0F2h, 021h, 0F1h, 0C9h
ct010  DB 001h, 067h, 00Ch, 08Ch, 017h, 066h, 0B9h, 08Fh
ct018  DB 0A3h, 05Fh, 029h, 013h, 0DBh, 0D2h, 06Eh, 070h
ct020  DB 061h, 04Bh, 052h, 066h, 039h, 080h, 08Bh, 01Eh
ct028  DB 0F9h, 09Ah, 00Eh, 07Eh, 086h, 01Fh, 01Eh, 031h
ct030  DB 06Ch, 0A2h, 05Dh, 046h, 0CBh, 00Fh, 0B5h, 054h
ct038  DB 0A5h, 0FFh, 00Ah, 0C7h, 0E2h, 092h, 0DDh, 0A5h
ct040  DB 01Dh, 012h, 054h, 04Bh, 031h, 0A5h, 07Bh, 0D5h
ct048  DB 02Eh, 0E3h, 079h, 05Bh, 048h, 0D6h, 00Ch, 0B9h
ct050  DB 030h, 0DFh, 0DCh, 061h, 0C0h, 076h, 005h, 016h
ct058  DB 009h, 0D1h, 03Ah, 0D6h, 049h, 0DFh, 033h, 015h
ct060  DB 088h, 069h, 05Fh, 0A2h, 0F7h, 0B4h, 09Ah, 065h
ct068  DB 06Fh, 0E3h, 0ADh, 035h, 0A3h, 0BAh, 02Fh, 09Ah
ct070  DB 07Fh, 05Fh, 072h, 0B6h, 02Eh, 087h, 004h, 0C4h
ct078  DB 0BEh, 041h, 08Eh, 006h, 021h, 095h, 083h, 040h
ct080  DB 0DBh, 002h, 078h, 037h, 0DAh, 037h, 051h, 0C7h
ct088  DB 0DBh, 0D6h, 0D6h, 078h, 0F8h, 092h, 014h, 079h
ct090  DB 043h, 02Ah, 085h, 0EFh, 026h, 007h, 052h, 064h
ct098  DB 0CDh, 0D5h, 0FDh, 0C9h, 038h, 03Ah, 014h, 0C0h
ct0A0  DB 04Ah, 08Fh, 0C6h, 0FFh, 040h, 0C2h, 051h, 07Fh
ct0A8  DB 0E6h, 036h, 007h, 012h, 09Bh, 0CAh, 0BFh, 06Dh
ct0B0  DB 042h, 0CCh, 009h, 06Ah, 018h, 032h, 0D6h, 07Dh
ct0B8  DB 0CEh, 0B5h, 00Ah, 0BBh, 068h, 08Ch, 074h, 01Bh
ct0C0  DB 0A3h, 05Ch, 045h, 04Eh, 0AEh, 09Eh, 070h, 059h
ct0C8  DB 0AFh, 066h, 0D1h, 08Ah, 0E3h, 027h, 089h, 0AEh
ct0D0  DB 074h, 0EBh, 06Ch, 069h, 069h, 0E5h, 013h, 075h
ct0D8  DB 0B5h, 001h, 023h, 00Ch, 046h, 0A7h, 0A8h, 0E1h
ct0E0  DB 068h, 052h, 0F9h, 055h, 026h, 02Ch, 0D8h, 0FFh
ct0E8  DB 010h, 00Dh, 0E5h, 0FCh, 09Dh, 07Dh, 099h, 0C8h
ct0F0  DB 043h, 062h, 084h, 047h, 031h, 09Ch, 088h, 04Dh
ct0F8  DB 0EEh, 064h, 07Bh, 085h, 087h, 00Ah, 049h, 035h
ct100  DB 06Bh, 077h, 0A2h, 0E0h, 0C8h, 041h, 067h, 04Ah
ct108  DB 08Ch, 0C0h, 074h, 0A8h, 0F1h, 0E6h, 0F7h, 053h
ct110  DB 03Ah, 0C2h, 050h, 09Ch, 037h, 084h, 0ABh, 0C9h
ct118  DB 03Fh, 067h, 0A9h, 05Dh, 02Dh, 004h, 033h, 0CFh
ct120  DB 099h, 0E5h, 09Bh, 075h, 08Fh, 0A0h, 035h, 069h
ct128  DB 085h, 0D0h, 028h, 033h, 0D7h, 023h, 023h, 0EBh
ct130  DB 0DEh, 01Ch, 0E9h, 081h, 06Fh, 0D2h, 06Ah, 0E4h
ct138  DB 05Eh, 094h, 0DBh, 0A5h, 013h, 0C2h, 0BBh, 049h
ct140  DB 04Eh, 068h, 0A3h, 07Dh, 01Eh, 0C4h, 093h, 008h
ct148  DB 095h, 01Eh, 0AEh, 0C5h, 0C9h, 0A8h, 0F2h, 0D8h
ct150  DB 0AFh, 08Fh, 0CEh, 07Eh, 0E8h, 01Fh, 037h, 0B3h
ct158  DB 02Dh, 05Ah, 0CAh, 006h, 032h, 036h, 095h, 0A6h
ct160  DB 04Dh, 05Dh, 09Ah, 0ABh, 07Eh, 073h, 0D5h, 001h
ct168  DB 0EFh, 028h, 07Ah, 06Fh, 045h, 07Fh, 0B5h, 0D7h
ct170  DB 095h, 0EFh, 04Fh, 062h, 063h, 09Fh, 052h, 00Ch
ct178  DB 05Ch, 0B8h, 0A2h, 0BBh, 016h, 0B1h, 030h, 018h
ct180  DB 03Bh, 048h, 0BFh, 0AAh, 088h, 0ACh, 0FDh, 09Eh
ct188  DB 06Ch, 09Eh, 026h, 0FBh, 04Bh, 07Ah, 091h, 0C9h
ct190  DB 05Ch, 0F8h, 0B0h, 032h, 0E2h, 011h, 053h, 05Ah
ct198  DB 0AEh, 0C2h, 073h, 09Dh, 00Ch, 05Eh, 02Ah, 05Fh
ct1A0  DB 0E8h, 042h, 01Ah, 0ADh, 089h, 0D1h, 078h, 091h
ct1A8  DB 038h, 024h, 02Dh, 0C7h, 0DDh, 0D6h, 0D0h, 069h
ct1B0  DB 0F4h, 050h, 022h, 039h, 08Eh, 025h, 0B2h, 0B7h
ct1B8  DB 081h, 061h, 030h, 00Bh, 0D1h, 014h, 0A2h, 0C3h
ct1C0  DB 0D0h, 0B0h, 0A2h, 0B7h, 0FCh, 068h, 00Bh, 03Ch
ct1C8  DB 036h, 08Eh, 007h, 00Bh, 022h, 07Dh, 0D6h, 03Ah
ct1D0  DB 077h, 090h, 000h, 009h, 000h, 0B1h, 00Ch, 094h
ct1D8  DB 00Fh, 08Ch, 0A3h, 02Dh, 095h, 0C3h, 0A7h, 0A2h
ct1E0  DB 09Ah, 071h, 088h, 024h, 037h, 0E4h, 0F5h, 05Dh
ct1E8  DB 07Bh, 0EDh, 057h, 088h, 081h, 0CBh, 008h, 06Fh
ct1F0  DB 07Bh, 0D2h, 00Eh, 0D3h, 095h, 0EFh, 042h, 070h
ct1F8  DB 0BAh, 0A6h, 0ADh, 0E4h, 0C9h, 0DBh, 068h, 01Ah
ct200  DB 043h, 048h, 0F9h, 0FDh, 013h, 065h, 06Fh, 07Eh
ct208  DB 076h, 05Dh, 08Bh, 0FEh, 024h, 034h, 057h, 08Ah
ct210  DB 0C2h, 033h, 0E8h, 0AFh, 05Ah, 0DCh, 085h, 077h
ct218  DB 02Bh, 08Fh, 0F9h, 00Ch, 09Ch, 0FFh, 06Fh, 01Fh
ct220  DB 0D0h, 099h, 0D1h, 04Bh, 0EAh, 09Dh, 064h, 050h
ct228  DB 08Ch, 07Ch, 03Ah, 01Ah, 0BBh, 044h, 09Eh, 0BCh
ct230  DB 0C8h, 0B4h, 007h, 0BBh, 0E6h, 0B1h, 04Fh, 051h
ct238  DB 0E3h, 03Eh, 07Ch, 005h, 091h, 09Ah, 05Ah, 0D4h
ct240  DB 001h, 0C4h, 0BEh, 094h, 0AFh, 0B9h, 0DBh, 028h
ct248  DB 0D5h, 0D8h, 039h, 0E6h, 01Eh, 016h, 089h, 0B6h
ct250  DB 007h, 0A0h, 080h, 0D4h, 04Dh, 0D5h, 072h, 07Ch
ct258  DB 026h, 0D9h, 0FAh, 091h, 0BEh, 0B2h, 0BBh, 028h
ct260  DB 03Bh, 02Bh, 001h, 0E8h, 0EAh, 084h, 04Fh, 093h
ct268  DB 09Bh, 064h, 06Eh, 092h, 026h, 09Eh, 0FCh, 08Ch
ct270  DB 037h, 099h, 0BDh, 074h, 090h, 03Dh, 042h, 043h
ct278  DB 0ABh, 09Bh, 022h, 06Ch, 04Bh, 0BCh, 080h, 030h
ct280  DB 006h, 06Dh, 053h, 0A6h, 09Ah, 0F3h, 082h, 001h
ct288  DB 01Eh, 0D2h, 06Fh, 0F1h, 06Bh, 0EBh, 051h, 062h
ct290  DB 0A1h, 03Ch, 07Bh, 083h, 0B6h, 086h, 0E5h, 098h
ct298  DB 022h, 00Bh, 049h, 00Ah, 0F6h, 04Ch, 063h, 02Bh
ct2A0  DB 054h, 064h, 0C5h, 082h, 094h, 017h, 0D2h, 07Dh
ct2A8  DB 0E5h, 01Ch, 085h, 048h, 035h, 00Bh, 038h, 096h
ct2B0  DB 07Fh, 072h, 015h, 046h, 07Dh, 0FDh, 075h, 076h
ct2B8  DB 037h, 02Fh, 04Bh, 0F9h, 0BAh, 0FFh, 056h, 0F8h
ct2C0  DB 0F4h, 023h, 04Ah, 027h, 0B3h, 0CFh, 02Ah, 0B1h
ct2C8  DB 0D8h, 0B2h, 0D5h, 0AFh, 06Fh, 0FFh, 075h, 001h
ct2D0  DB 03Eh, 003h, 09Ah, 01Bh, 050h, 05Fh, 0CFh, 0DAh
ct2D8  DB 0AFh, 0FBh, 0FFh, 015h, 071h, 064h, 02Ch, 042h
ct2E0  DB 04Bh, 00Fh, 0EEh, 0ABh, 018h, 0ABh, 0D5h, 0CAh
ct2E8  DB 0B4h, 0C6h, 0E0h, 012h, 05Eh, 0F2h, 0F9h, 0F6h
ct2F0  DB 016h, 02Fh, 0DBh, 0E7h, 0D9h, 040h, 007h, 080h
ct2F8  DB 03Ch, 0B1h, 00Bh, 00Ah, 0D5h, 03Ah, 0E3h, 0FCh
ct300  DB 04Ch, 06Eh, 0D3h, 016h, 0E9h, 071h, 068h, 0E0h
ct308  DB 079h, 04Ch, 0F6h, 09Bh, 07Ch, 0F3h, 00Dh, 01Ch
ct310  DB 005h, 0A3h, 018h, 059h, 0F8h, 0EAh, 03Ah, 0A7h
ct318  DB 0ADh, 0E4h, 0D7h, 07Ch, 007h, 008h, 087h, 091h
ct320  DB 005h, 04Ah, 044h, 045h, 00Ch, 08Ch, 077h, 0D9h
ct328  DB 007h, 0F5h, 0CFh, 02Bh, 091h, 0B2h, 0C0h, 0A9h
ct330  DB 0B3h, 0EBh, 060h, 0DFh, 043h, 0D4h, 0F3h, 005h
ct338  DB 02Ch, 061h, 099h, 0BCh, 04Dh, 072h, 0A1h, 070h
ct340  DB 0BDh, 0C1h, 08Dh, 0AAh, 018h, 0EFh, 036h, 07Dh
ct348  DB 0C7h, 0CFh, 09Fh, 0B2h, 032h, 0AAh, 0A6h, 012h
ct350  DB 0C5h, 06Ah, 091h, 052h, 063h, 08Dh, 0D8h, 03Ah
ct358  DB 0CEh, 09Ch, 096h, 0ABh, 092h, 056h, 0E5h, 0A5h
ct360  DB 0D7h, 0A7h, 0A6h, 058h, 0E4h, 090h, 028h, 038h
ct368  DB 076h, 081h, 0A5h, 034h, 001h, 0B7h, 018h, 018h
ct370  DB 055h, 059h, 0E3h, 002h, 049h, 021h, 00Eh, 043h
ct378  DB 02Eh, 097h, 08Eh, 074h, 027h, 04Ch, 0AAh, 0A4h
ct380  DB 02Eh, 0D4h, 0FAh, 0ECh, 0C4h, 06Dh, 0EAh, 054h
ct388  DB 0A9h, 038h, 053h, 095h, 0B4h, 0FDh, 0A3h, 09Fh
ct390  DB 0B9h, 019h, 01Ah, 06Ah, 0E1h, 070h, 073h, 03Eh
ct398  DB 0BFh, 095h, 087h, 072h, 030h, 03Eh, 0D1h, 024h
ct3A0  DB 06Ch, 08Fh, 0EDh, 052h, 039h, 06Fh, 0A0h, 021h
ct3A8  DB 0B3h, 092h, 02Fh, 074h, 070h, 006h, 0F9h, 017h
ct3B0  DB 00Bh, 0D4h, 03Ch, 0F2h, 093h, 0FBh, 063h, 038h
ct3B8  DB 0FDh, 01Fh, 0A1h, 0ABh, 0C9h, 0EEh, 0DAh, 064h
ct3C0  DB 0B9h, 020h, 0EDh, 0C5h, 079h, 06Eh, 001h, 068h
ct3C8  DB 0ECh, 0B6h, 094h, 0B7h, 047h, 0CCh, 079h, 0A1h
ct3D0  DB 029h, 077h, 0F9h, 01Fh, 00Bh, 06Ch, 02Dh, 064h
ct3D8  DB 0EEh, 079h, 0D1h, 0CBh, 0D0h, 002h, 08Fh, 09Ah
ct3E0  DB 0BFh, 062h, 002h, 0D0h, 073h, 0C1h, 0F5h, 01Ch
ct3E8  DB 0B2h, 087h, 0D7h, 0C6h, 037h, 0D9h, 095h, 010h
ct3F0  DB 0ABh, 0B2h, 036h, 0FCh, 0EFh, 03Bh, 067h, 00Fh
ct3F8  DB 0B2h, 00Ch, 076h, 0B7h, 02Fh, 084h, 0FAh, 082h
ct400  DB 05Ch, 022h, 012h, 05Ch, 077h, 0FEh, 026h, 092h
ct408  DB 0F2h, 044h, 0FFh, 0BFh, 084h, 0BEh, 0ACh, 0B2h
ct410  DB 0EDh, 0A7h, 086h, 0E7h, 011h, 0DBh, 02Bh, 0C7h
ct418  DB 0BCh, 00Eh, 0AEh, 006h, 03Dh, 00Eh, 0F8h, 0D6h
ct420  DB 01Bh, 084h, 097h, 019h, 064h, 01Fh, 04Ch, 00Fh
ct428  DB 022h, 0B2h, 0E6h, 087h, 084h, 01Ah, 009h, 04Dh
ct430  DB 030h, 02Eh, 03Ah, 0CEh, 0B7h, 07Eh, 0B1h, 0E3h
ct438  DB 0B1h, 045h, 0A5h, 0B7h, 0DDh, 0C1h, 040h, 087h
ct440  DB 00Ah, 056h, 022h, 0B4h, 06Fh, 072h, 035h, 0E6h
ct448  DB 021h, 07Eh, 0E8h, 0DEh, 00Ah, 020h, 034h, 089h
ct450  DB 0ACh, 07Eh, 040h, 045h, 065h, 07Eh, 0B1h, 0E8h
ct458  DB 03Ch, 050h, 0ACh, 03Ah, 0D8h, 03Dh, 0D9h, 0B1h
ct460  DB 044h, 0BDh, 0ABh, 079h, 0CCh, 017h, 063h, 059h
ct468  DB 05Fh, 010h, 07Ch, 069h, 03Dh, 061h, 0B4h, 001h
ct470  DB 04Ah, 09Ah, 095h, 071h, 0ADh, 036h, 0D7h, 003h
ct478  DB 040h, 000h, 0B9h, 047h, 0A9h, 0DFh, 041h, 0CDh
ct480  DB 0B5h, 033h, 0A5h, 09Ch, 025h, 077h, 0EBh, 09Ah
ct488  DB 07Fh, 065h, 003h, 07Fh, 02Dh, 09Ah, 0C3h, 0C5h
ct490  DB 02Ch, 094h, 010h, 044h, 049h, 0AEh, 0F1h, 078h
ct498  DB 0D4h, 029h, 0D2h, 0C6h, 0D1h, 0A6h, 075h, 04Ah
ct4A0  DB 023h, 090h, 0A7h, 04Dh, 0C3h, 097h, 037h, 042h
ct4A8  DB 0F0h, 0FCh, 0F4h, 0E2h, 0C5h, 0DFh, 0B2h, 0EFh
ct4B0  DB 070h, 072h, 0B9h, 08Fh, 096h, 01Bh, 05Dh, 06Ch
ct4B8  DB 08Ch, 054h, 0F4h, 0C6h, 057h, 001h, 056h, 000h
ct4C0  DB 0C9h, 029h, 08Ah, 0EBh, 009h, 068h, 0F6h, 0C2h
ct4C8  DB 03Eh, 0B5h, 090h, 082h, 024h, 0BDh, 0DEh, 0F4h
ct4D0  DB 006h, 03Ch, 00Dh, 043h, 0FDh, 053h, 0DDh, 03Ah
ct4D8  DB 0D5h, 0D1h, 04Dh, 07Fh, 082h, 025h, 0D0h, 005h
ct4E0  DB 0DAh, 096h, 0C4h, 04Eh, 01Ch, 0A4h, 099h, 0F3h
ct4E8  DB 01Bh, 087h, 08Eh, 02Dh, 0A0h, 04Fh, 011h, 033h
ct4F0  DB 071h, 046h, 0D8h, 0ADh, 051h, 0D2h, 0E7h, 0DDh
ct4F8  DB 097h, 08Ch, 080h, 000h, 0C2h, 03Fh, 032h, 088h
ct500  DB 084h, 02Eh, 01Dh, 0C9h, 089h, 09Bh, 02Dh, 08Dh
ct508  DB 0D8h, 0A9h, 00Eh, 0C6h, 093h, 098h, 0A8h, 01Dh
ct510  DB 038h, 031h, 0B2h, 078h, 087h, 007h, 0C9h, 039h
ct518  DB 0A1h, 09Fh, 00Eh, 06Ch, 039h, 01Bh, 0F4h, 046h
ct520  DB 044h, 084h, 09Ah, 00Bh, 0D0h, 0ACh, 06Ah, 024h
ct528  DB 00Eh, 00Ah, 0E2h, 07Dh, 06Dh, 0C4h, 0B2h, 046h
ct530  DB 066h, 0C7h, 003h, 0ADh, 00Ch, 077h, 0CBh, 01Ah
ct538  DB 06Ch, 0C5h, 070h, 0ABh, 034h, 06Ch, 0FBh, 04Ah
ct540  DB 0C6h, 025h, 089h, 0EEh, 024h, 0B9h, 0F0h, 0D1h
ct548  DB 045h, 0C4h, 056h, 0B5h, 0E6h, 0BDh, 051h, 05Fh
ct550  DB 0C2h, 010h, 0E6h, 0BBh, 06Eh, 021h, 075h, 01Dh
ct558  DB 0A5h, 059h, 079h, 007h, 088h, 005h, 092h, 007h
ct560  DB 097h, 033h, 069h, 058h, 03Dh, 002h, 0B8h, 082h
ct568  DB 009h, 08Dh, 000h, 0A6h, 0DDh, 0EDh, 073h, 067h
ct570  DB 00Bh, 096h, 00Ch, 0CAh, 02Dh, 09Bh, 026h, 069h
ct578  DB 053h, 05Dh, 026h, 03Ch, 026h, 0C9h, 034h, 03Dh
ct580  DB 09Dh, 0AFh, 08Ah, 0C9h, 028h, 0B9h, 0F3h, 04Bh
ct588  DB 00Dh, 061h, 04Dh, 09Bh, 098h, 0E8h, 042h, 0ADh
ct590  DB 011h, 0FAh, 0C8h, 0CEh, 02Dh, 0B0h, 04Ah, 0BAh
ct598  DB 04Eh, 0BBh, 0BCh, 064h, 0C0h, 086h, 0BFh, 096h
ct5A0  DB 018h, 0F6h, 06Fh, 0B5h, 0B3h, 08Bh, 014h, 035h
ct5A8  DB 055h, 07Ch, 0CEh, 0B0h, 0ADh, 08Bh, 020h, 000h
ct5B0  DB 044h, 041h, 059h, 048h, 0E1h, 0A8h, 0D8h, 0E8h
ct5B8  DB 0F1h, 0F6h, 03Eh, 07Ah, 068h, 0CDh, 05Eh, 0ECh
ct5C0  DB 066h, 0BCh, 06Eh, 003h, 0CFh, 0D4h, 039h, 0EFh
ct5C8  DB 075h, 09Ch, 007h, 0C9h, 02Bh, 0BDh, 0CBh, 044h
ct5D0  DB 0FDh, 060h, 023h, 087h, 0F0h, 0A6h, 025h, 0F3h
ct5D8  DB 0C0h, 02Fh, 0A8h, 02Ah, 0D7h, 0E8h, 02Fh, 049h
ct5E0  DB 06Ah, 068h, 04Ch, 0C8h, 0A1h, 072h, 084h, 0E4h
ct5E8  DB 062h, 070h, 097h, 00Eh, 060h, 0FAh, 06Bh, 004h
ct5F0  DB 073h, 0DFh, 00Eh, 0DAh, 0ACh, 0F5h, 0CFh, 023h
ct5F8  DB 0ABh, 0C0h, 024h, 0AEh, 00Ah, 08Bh, 0E2h, 00Ah
ct600  DB 0F8h, 028h, 0C4h, 06Eh, 080h, 0C6h, 0D4h, 00Fh
ct608  DB 0EFh, 085h, 071h, 0E0h, 007h, 054h, 0E5h, 0B9h
ct610  DB 086h, 0AAh, 090h, 06Fh, 0E1h, 054h, 0CBh, 020h
ct618  DB 08Ch, 072h, 024h, 002h, 016h, 035h, 0CAh, 0BBh
ct620  DB 09Bh, 052h, 063h, 06Bh, 007h, 0B7h, 0DFh, 083h
ct628  DB 0DCh, 09Dh, 0D6h, 063h, 074h, 051h, 0DEh, 038h
ct630  DB 0FBh, 012h, 008h, 0B4h, 018h, 0F6h, 0F4h, 0E6h
ct638  DB 001h, 0D6h, 0A1h, 026h, 051h, 0C5h, 009h, 066h
ct640  DB 00Ch, 0D3h, 017h, 0E2h, 040h, 08Fh, 0CBh, 0D9h
ct648  DB 09Bh, 018h, 069h, 0E7h, 070h, 076h, 032h, 03Dh
ct650  DB 08Dh, 04Ah, 000h, 0ABh, 0D1h, 0C5h, 068h, 04Ch
ct658  DB 049h, 013h, 0B6h, 0A1h, 0F0h, 007h, 056h, 036h
ct660  DB 023h, 099h, 0DEh, 08Bh, 0E6h, 021h, 051h, 002h
ct668  DB 0C1h, 01Dh, 015h, 0CFh, 07Bh, 087h, 00Dh, 02Bh
ct670  DB 0A3h, 0FCh, 0BAh, 03Bh, 0E3h, 02Dh, 05Ch, 0DEh
ct678  DB 076h, 0CEh, 01Ch, 0B3h, 06Ch, 0BDh, 06Eh, 08Eh
ct680  DB 0BAh, 01Bh, 028h, 039h, 0A8h, 0ACh, 04Dh, 0A9h
ct688  DB 074h, 0D1h, 0B2h, 00Ch, 0EBh, 0BBh, 00Ah, 0BEh
ct690  DB 0ECh, 011h, 0EBh, 0A3h, 00Bh, 01Bh, 0FFh, 012h
ct698  DB 02Ah, 0AFh, 02Ch, 030h, 024h, 0FAh, 089h, 02Fh
ct6A0  DB 033h, 072h, 04Ah, 00Dh, 063h, 0B4h, 05Bh, 084h
ct6A8  DB 0C2h, 087h, 0CCh, 036h, 072h, 02Eh, 037h, 0D7h
ct6B0  DB 0A3h, 06Bh, 0A5h, 05Eh, 05Bh, 0E5h, 09Ch, 0CDh
ct6B8  DB 06Eh, 086h, 0B2h, 0CAh, 032h, 021h, 0B8h, 0F6h
ct6C0  DB 0A0h, 0AFh, 061h, 044h, 0A9h, 008h, 062h, 00Eh
ct6C8  DB 045h, 0FDh, 0B5h, 01Fh, 0B4h, 04Eh, 06Fh, 097h
ct6D0  DB 0D0h, 065h, 03Dh, 0C9h, 09Ah, 012h, 081h, 0F4h
ct6D8  DB 017h, 093h, 085h, 042h, 00Ch, 077h, 06Fh, 0ECh
ct6E0  DB 057h, 0E0h, 06Dh, 0CDh, 05Eh, 020h, 01Fh, 0FFh
ct6E8  DB 0F6h, 007h, 01Ch, 0DFh, 072h, 075h, 02Fh, 015h
ct6F0  DB 023h, 04Eh, 04Eh, 0E5h, 060h, 090h, 077h, 078h
ct6F8  DB 0A3h, 002h, 0EEh, 08Fh, 079h, 0C7h, 0C4h, 0A4h
ct700  DB 019h, 0CCh, 082h, 083h, 04Eh, 0A7h, 07Fh, 0E8h
ct708  DB 08Ch, 0D4h, 0F6h, 063h, 023h, 0A9h, 031h, 0C0h
ct710  DB 022h, 0B9h, 0C2h, 0A8h, 046h, 0B8h, 069h, 0B7h
ct718  DB 0BEh, 088h, 030h, 035h, 082h, 0AAh, 003h, 0D1h
ct720  DB 0C7h, 0CBh, 089h, 068h, 005h, 0F7h, 0C5h, 00Dh
ct728  DB 026h, 027h, 013h, 09Fh, 0A2h, 037h, 0E4h, 066h
ct730  DB 073h, 046h, 0F1h, 0BAh, 034h, 09Fh, 070h, 066h
ct738  DB 03Dh, 079h, 09Fh, 013h, 041h, 02Eh, 01Ch, 098h
ct740  DB 06Ah, 089h, 0E0h, 0B3h, 089h, 0D7h, 0E1h, 034h
ct748  DB 002h, 096h, 0C3h, 0A7h, 051h, 012h, 0BFh, 03Bh
ct750  DB 0B8h, 099h, 003h, 0BFh, 028h, 051h, 06Ch, 0F4h
ct758  DB 057h, 026h, 06Eh, 098h, 046h, 086h, 008h, 009h
ct760  DB 00Fh, 024h, 069h, 00Ch, 058h, 033h, 0BCh, 072h
ct768  DB 0B1h, 09Bh, 030h, 030h, 08Eh, 020h, 0FCh, 05Dh
ct770  DB 09Ch, 0D3h, 07Bh, 0A8h, 0C6h, 02Eh, 09Ch, 065h
ct778  DB 0A1h, 015h, 05Ah, 0FAh, 0D3h, 036h, 0F8h, 08Eh
ct780  DB 09Eh, 024h, 054h, 0A7h, 0CEh, 09Eh, 0D8h, 0ADh
ct788  DB 0CFh, 094h, 065h, 064h, 048h, 014h, 063h, 0B9h
ct790  DB 081h, 0BEh, 0C3h, 096h, 0CBh, 0C1h, 025h, 0A9h
ct798  DB 0F0h, 026h, 039h, 003h, 0A5h, 08Eh, 0CFh, 0FAh
ct7A0  DB 089h, 05Eh, 09Eh, 01Fh, 074h, 0CCh, 099h, 07Ch
ct7A8  DB 0C2h, 01Ah, 06Fh, 0A7h, 054h, 059h, 0CBh, 0D8h
ct7B0  DB 081h, 01Fh, 044h, 0B5h, 0BAh, 079h, 0A3h, 0A8h
ct7B8  DB 0CAh, 0D2h, 0A8h, 0ECh, 0D8h, 0AFh, 0F8h, 0F9h
ct7C0  DB 0CDh, 025h, 026h, 00Fh, 0E1h, 095h, 040h, 0BCh
ct7C8  DB 0CDh, 04Fh, 0D1h, 085h, 03Dh, 030h, 093h, 074h
ct7D0  DB 04Bh, 02Fh, 0B9h, 02Fh, 0B2h, 0F5h, 036h, 0B9h
ct7D8  DB 0B7h, 0B0h, 090h, 09Ch, 0E7h, 04Eh, 016h, 0BFh
ct7E0  DB 031h, 01Dh, 08Ch, 06Fh, 0F2h, 071h, 056h, 084h
ct7E8  DB 0CFh, 061h, 053h, 00Ch, 0FCh, 018h, 08Ah, 066h
ct7F0  DB 03Dh, 070h, 09Ah, 002h, 0A7h, 027h, 0C9h, 020h
ct7F8  DB 0FDh, 018h, 03Dh, 0D1h, 01Dh, 067h, 07Dh, 0DAh
ct800  DB 0D6h, 0E0h, 046h, 043h, 0BFh, 04Eh, 0B4h, 010h
ct808  DB 0B2h, 04Dh, 061h, 097h, 0C4h, 03Fh, 050h, 045h
ct810  DB 0DBh, 08Fh, 047h, 033h, 010h, 08Fh, 04Bh, 0E3h
ct818  DB 061h, 07Fh, 0CEh, 015h, 076h, 0B2h, 01Ah, 07Eh
ct820  DB 07Eh, 04Ah, 0AFh, 06Bh, 0DBh, 0F7h, 077h, 0E5h
ct828  DB 0A5h, 04Ah, 03Eh, 041h, 0BEh, 00Bh, 0BBh, 038h
ct830  DB 0A7h, 059h, 09Ch, 022h, 06Ch, 00Dh, 05Eh, 09Ch
ct838  DB 0C8h, 066h, 0A7h, 057h, 0F9h, 03Ch, 03Dh, 09Ah
ct840  DB 050h, 069h, 064h, 0AEh, 06Bh, 05Fh, 075h, 009h
ct848  DB 075h, 0F8h, 048h, 034h, 068h, 095h, 06Eh, 0A6h
ct850  DB 046h, 0CFh, 091h, 06Ch, 04Eh, 076h, 038h, 0B5h
ct858  DB 09Ah, 09Bh, 06Ch, 06Ch, 0EFh, 061h, 049h, 08Dh
ct860  DB 0AAh, 00Ah, 0E8h, 039h, 07Ch, 044h, 031h, 020h
ct868  DB 0B1h, 034h, 08Dh, 0A3h, 0D6h, 08Bh, 029h, 006h
ct870  DB 078h, 08Dh, 09Bh, 017h, 0D8h, 0A5h, 0E9h, 066h
ct878  DB 07Ah, 07Fh, 0D2h, 034h, 057h, 0B8h, 0DFh, 058h
ct880  DB 0FBh, 052h, 057h, 021h, 03Fh, 0F2h, 096h, 0BEh
ct888  DB 06Fh, 0A9h, 0BEh, 021h, 0A6h, 088h, 07Ah, 0E8h
ct890  DB 020h, 0F8h, 06Dh, 0C2h, 0F9h, 092h, 0F6h, 094h
ct898  DB 001h, 0F0h, 03Ch, 022h, 0B0h, 00Fh, 0E4h, 0D6h
ct8A0  DB 079h, 030h, 025h, 018h, 0D8h, 07Bh, 0CDh, 013h
ct8A8  DB 085h, 0A1h, 030h, 0DBh, 07Eh, 0E5h, 085h, 086h
ct8B0  DB 02Dh, 0A0h, 0E1h, 004h, 002h, 0D6h, 070h, 0D5h
ct8B8  DB 0F8h, 0D9h, 001h, 004h, 02Bh, 006h, 0FFh, 0D5h
ct8C0  DB 025h, 0EFh, 04Eh, 041h, 083h, 055h, 07Ah, 0ECh
ct8C8  DB 024h, 011h, 0FFh, 054h, 01Eh, 0DFh, 05Ch, 0C4h
ct8D0  DB 0C8h, 049h, 07Ah, 09Dh, 0EDh, 015h, 04Ch, 066h
ct8D8  DB 05Ah, 010h, 00Eh, 05Ch, 0AAh, 099h, 066h, 0D1h
ct8E0  DB 00Ch, 0D9h, 0A9h, 00Bh, 0CAh, 087h, 0B0h, 033h
ct8E8  DB 061h, 093h, 0F2h, 06Ah, 001h, 0BEh, 030h, 009h
ct8F0  DB 0E8h, 0FEh, 0B2h, 030h, 0B8h, 0FBh, 007h, 001h
ct8F8  DB 096h, 025h, 05Ch, 016h, 010h, 048h, 0EEh, 0ABh
ct900  DB 0B5h, 035h, 093h, 06Ah, 04Bh, 03Bh, 018h, 044h
ct908  DB 065h, 016h, 0F0h, 0A0h, 0B1h, 0D7h, 040h, 006h
ct910  DB 0B3h, 095h, 099h, 07Fh, 062h, 0C2h, 00Eh, 07Eh
ct918  DB 009h, 0CCh, 00Ch, 016h, 028h, 05Ch, 0EEh, 0C7h
ct920  DB 046h, 05Ah, 0BCh, 0C7h, 05Ah, 0A4h, 05Eh, 009h
ct928  DB 0FBh, 084h, 01Ch, 0D0h, 005h, 022h, 064h, 0EEh
ct930  DB 08Ch, 04Ah, 03Ah, 062h, 0B2h, 051h, 0A5h, 024h
ct938  DB 0FFh, 0C5h, 092h, 01Ch, 06Fh, 06Eh, 051h, 054h
ct940  DB 067h, 0F2h, 02Eh, 099h, 0D9h, 014h, 0C1h, 09Eh
ct948  DB 06Fh, 0A1h, 090h, 03Eh, 044h, 052h, 013h, 0C3h
ct950  DB 04Eh, 04Eh, 0B8h, 08Ah, 08Bh, 039h, 036h, 041h
ct958  DB 08Dh, 031h, 039h, 052h, 0BDh, 0FDh, 073h, 04Fh
ct960  DB 0F8h, 094h, 09Bh, 0EEh, 0D1h, 058h, 061h, 008h
ct968  DB 070h, 088h, 02Ch, 011h, 029h, 055h, 042h, 0FBh
ct970  DB 0AEh, 0D8h, 0D2h, 057h, 0A1h, 035h, 00Bh, 085h
ct978  DB 02Eh, 086h, 0FAh, 033h, 0CAh, 077h, 094h, 079h
ct980  DB 0D3h, 0C4h, 0D3h, 01Ah, 04Dh, 0A7h, 0F3h, 0E2h
ct988  DB 0A2h, 07Ah, 0C2h, 022h, 049h, 084h, 04Bh, 03Fh
ct990  DB 072h, 0B8h, 092h, 09Ah, 04Eh, 048h, 0A1h, 092h
ct998  DB 004h, 041h, 00Ch, 05Bh, 01Bh, 05Dh, 081h, 0F1h
ct9A0  DB 0B4h, 02Ah, 070h, 0B1h, 0E2h, 0D6h, 06Eh, 02Fh
ct9A8  DB 040h, 0F0h, 054h, 00Eh, 0EAh, 02Dh, 0BEh, 0BFh
ct9B0  DB 0A9h, 099h, 060h, 07Ch, 061h, 0D2h, 035h, 01Ah
ct9B8  DB 085h, 023h, 0B1h, 0FEh, 0BAh, 026h, 08Eh, 0D2h
ct9C0  DB 02Bh, 032h, 03Ah, 082h, 05Eh, 0CEh, 014h, 085h
ct9C8  DB 0B4h, 0FDh, 05Eh, 0FCh, 0E6h, 0D7h, 070h, 0BEh
ct9D0  DB 019h, 04Ch, 0CAh, 081h, 091h, 0DAh, 076h, 081h
ct9D8  DB 06Fh, 009h, 0F2h, 03Bh, 021h, 0B2h, 0D4h, 0BBh
ct9E0  DB 00Ah, 0BEh, 028h, 08Bh, 0F6h, 0E7h, 007h, 0EAh
ct9E8  DB 00Fh, 088h, 006h, 021h, 0ECh, 08Dh, 0BFh, 012h
ct9F0  DB 00Ch, 0FFh, 0A3h, 03Eh, 04Dh, 059h, 09Dh, 064h
ct9F8  DB 04Dh, 076h, 06Ah, 008h, 0C7h, 03Ah, 0BFh, 05Eh
ctA00  DB 0B1h, 043h, 0EBh, 048h, 0B7h, 084h, 0A3h, 080h
ctA08  DB 0DEh, 0DEh, 0E5h, 015h, 0F5h, 0A9h, 002h, 0BDh
ctA10  DB 0A7h, 055h, 0DBh, 0E3h, 077h, 045h, 06Fh, 0C5h
ctA18  DB 051h, 082h, 0EAh, 030h, 077h, 09Bh, 075h, 071h
ctA20  DB 0F5h, 01Fh, 08Ch, 04Bh, 003h, 0A7h, 009h, 0FCh
ctA28  DB 0F8h, 02Ch, 002h, 033h, 039h, 02Eh, 04Bh, 0D2h
ctA30  DB 00Eh, 0E6h, 052h, 07Ah, 037h, 032h, 0A0h, 078h
ctA38  DB 0EBh, 007h, 079h, 04Ch, 04Bh, 083h, 035h, 00Fh
ctA40  DB 07Fh, 0BEh, 021h, 0A9h, 01Fh, 0CAh, 0FFh, 0B0h
ctA48  DB 077h, 09Ah, 0FCh, 0C6h, 028h, 0B0h, 025h, 0B3h
ctA50  DB 08Ah, 0F7h, 009h, 0B1h, 03Ah, 095h, 015h, 05Ah
ctA58  DB 065h, 0FEh, 07Fh, 08Bh, 0DFh, 00Ch, 04Ch, 028h
ctA60  DB 0F0h, 0A1h, 0BFh, 0D9h, 088h, 08Eh, 06Bh, 01Dh
ctA68  DB 06Ah, 04Bh, 0A8h, 08Fh, 04Bh, 006h, 071h, 028h
ctA70  DB 092h, 0D1h, 0A2h, 0DCh, 04Dh, 0CDh, 095h, 0B5h
ctA78  DB 023h, 0EAh, 05Dh, 0FAh, 0C2h, 089h, 0A9h, 018h
ctA80  DB 02Ch, 082h, 0D1h, 082h, 0FDh, 0D7h, 025h, 0BAh
ctA88  DB 076h, 04Dh, 00Bh, 02Fh, 094h, 039h, 0E9h, 08Eh
ctA90  DB 09Ah, 0DFh, 06Ah, 046h, 04Ah, 090h, 08Dh, 0A5h
ctA98  DB 069h, 029h, 054h, 031h, 0CDh, 017h, 0ABh, 05Fh
ctAA0  DB 0EEh, 0CDh, 046h, 066h, 0BCh, 04Fh, 05Ah, 094h
ctAA8  DB 054h, 0A9h, 0C7h, 044h, 09Eh, 050h, 006h, 028h
ctAB0  DB 06Eh, 0D2h, 0B0h, 0C2h, 0B2h, 052h, 088h, 0FBh
ctAB8  DB 039h, 0D8h, 0BDh, 0C7h, 011h, 015h, 06Fh, 058h
ctAC0  DB 054h, 0E3h, 070h, 049h, 085h, 039h, 03Ah, 01Ch
ctAC8  DB 0E3h, 0B7h, 074h, 05Dh, 0C0h, 036h, 0C4h, 04Fh
ctAD0  DB 0B6h, 0E8h, 02Dh, 053h, 0C3h, 039h, 095h, 0BBh
ctAD8  DB 069h, 096h, 079h, 0A5h, 02Ch, 06Fh, 0F9h, 09Fh
ctAE0  DB 03Bh, 055h, 06Bh, 0B6h, 0A1h, 08Bh, 04Bh, 0A0h
ctAE8  DB 032h, 0F0h, 027h, 0F4h, 0EDh, 086h, 064h, 03Ch
ctAF0  DB 09Ah, 0B7h, 0E1h, 0BEh, 062h, 045h, 07Ch, 01Fh
ctAF8  DB 04Ch, 08Ch, 069h, 015h, 06Bh, 0E0h, 067h, 061h
ctB00  DB 088h, 092h, 01Eh, 02Bh, 0E3h, 021h, 075h, 04Dh
ctB08  DB 095h, 056h, 025h, 0C2h, 05Ah, 0B6h, 0D1h, 086h
ctB10  DB 025h, 05Fh, 02Ah, 0E9h, 032h, 04Ah, 01Eh, 0B0h
ctB18  DB 06Ah, 0BDh, 07Ah, 0A5h, 0D8h, 0F5h, 0C7h, 0EFh
ctB20  DB 0A2h, 0E9h, 014h, 040h, 0C9h, 08Fh, 07Dh, 063h
ctB28  DB 0CFh, 039h, 086h, 044h, 03Ch, 08Ch, 05Ah, 000h
ctB30  DB 0C8h, 00Ah, 071h, 064h, 002h, 045h, 0D0h, 0B0h
ctB38  DB 023h, 0FEh, 09Dh, 008h, 048h, 03Ch, 092h, 081h
ctB40  DB 006h, 057h, 049h, 0C7h, 03Ah, 094h, 0AAh, 0FBh
ctB48  DB 0D8h, 001h, 0CBh, 02Dh, 03Ah, 033h, 0A5h, 02Eh
ctB50  DB 0DBh, 0B6h, 084h, 024h, 008h, 0D8h, 068h, 084h
ctB58  DB 04Ch, 00Dh, 0A8h, 0F5h, 0CAh, 080h, 097h, 0C4h
ctB60  DB 04Bh, 02Ch, 09Bh, 023h, 06Ah, 044h, 073h, 0A3h
ctB68  DB 031h, 09Dh, 0F2h, 0D3h, 0A0h, 0E6h, 05Fh, 074h
ctB70  DB 0ECh, 0E7h, 0B5h, 06Eh, 035h, 075h, 065h, 01Fh
ctB78  DB 01Ch, 0E0h, 099h, 075h, 0DDh, 09Fh, 010h, 0D6h
ctB80  DB 072h, 012h, 0D7h, 055h, 07Ch, 0C2h, 00Ch, 0BDh
ctB88  DB 0E7h, 0C3h, 0A5h, 0ADh, 013h, 0DBh, 0D4h, 0DFh
ctB90  DB 0DFh, 0D9h, 0C8h, 0F4h, 072h, 010h, 03Dh, 0B2h
ctB98  DB 0B2h, 021h, 072h, 0F3h, 091h, 029h, 0A4h, 0B1h
ctBA0  DB 01Ah, 0D9h, 074h, 008h, 01Ch, 028h, 09Ch, 0DBh
ctBA8  DB 055h, 0D6h, 039h, 0DFh, 084h, 052h, 090h, 0EAh
ctBB0  DB 049h, 068h, 085h, 0F8h, 01Dh, 059h, 07Fh, 0C4h
ctBB8  DB 09Eh, 007h, 04Eh, 06Bh, 094h, 052h, 0A4h, 02Fh
ctBC0  DB 0D8h, 0EEh, 0F2h, 028h, 03Bh, 016h, 073h, 085h
ctBC8  DB 0D4h, 08Dh, 0DBh, 003h, 009h, 039h, 012h, 093h
ctBD0  DB 060h, 04Bh, 0FAh, 09Eh, 099h, 0C5h, 0E3h, 005h
ctBD8  DB 056h, 02Eh, 04Ah, 05Ah, 0B0h, 0E3h, 0E4h, 07Ch
ctBE0  DB 019h, 0BCh, 055h, 0BDh, 06Fh, 09Ch, 057h, 0BFh
ctBE8  DB 0C4h, 0BBh, 033h, 096h, 09Fh, 076h, 06Fh, 015h
ctBF0  DB 0FCh, 050h, 092h, 04Ah, 065h, 042h, 06Eh, 0A9h
ctBF8  DB 054h, 0B2h, 068h, 058h, 04Fh, 0F9h, 09Bh, 027h
ctC00  DB 061h, 047h, 0DEh, 083h, 0EBh, 06Eh, 054h, 079h
ctC08  DB 0C7h, 0A8h, 0ABh, 0BEh, 0DDh, 093h, 0C2h, 060h
ctC10  DB 052h, 075h, 057h, 02Ah, 029h, 068h, 0E4h, 0DDh
ctC18  DB 08Ch, 05Ah, 03Fh, 074h, 08Dh, 0CFh, 003h, 0B0h
ctC20  DB 0FEh, 0E2h, 0DAh, 079h, 05Eh, 089h, 049h, 00Ch
ctC28  DB 037h, 0F9h, 082h, 0A2h, 00Ch, 0E1h, 0EAh, 076h
ctC30  DB 0CEh, 037h, 085h, 079h, 02Eh, 098h, 0A0h, 091h
ctC38  DB 00Bh, 05Eh, 027h, 055h, 0CAh, 084h, 0A2h, 02Ch
ctC40  DB 008h, 023h, 0E3h, 01Ch, 057h, 006h, 042h, 00Ah
ctC48  DB 066h, 0C8h, 0A0h, 097h, 043h, 0AAh, 0B3h, 077h
ctC50  DB 0B1h, 0E6h, 082h, 013h, 0AEh, 0BBh, 0D1h, 014h
ctC58  DB 047h, 0A6h, 009h, 0C9h, 0D0h, 048h, 0D3h, 03Bh
ctC60  DB 0DCh, 09Eh, 0FCh, 08Bh, 045h, 0C8h, 0BCh, 07Dh
ctC68  DB 0B2h, 0B0h, 0A6h, 082h, 0C0h, 009h, 0ADh, 0FEh
ctC70  DB 0C3h, 010h, 058h, 059h, 05Dh, 00Dh, 0F4h, 09Ch
ctC78  DB 034h, 080h, 0F5h, 0C2h, 041h, 0A1h, 057h, 0E2h
ctC80  DB 0EFh, 09Dh, 04Ch, 056h, 0AEh, 033h, 0CFh, 0BDh
ctC88  DB 032h, 00Ch, 0AAh, 01Fh, 076h, 071h, 0B9h, 025h
ctC90  DB 033h, 05Eh, 0F8h, 041h, 06Ah, 0D4h, 0F5h, 0C4h
ctC98  DB 072h, 0E1h, 077h, 0C6h, 025h, 003h, 0E5h, 0DCh
ctCA0  DB 052h, 0D0h, 040h, 0E9h, 085h, 06Dh, 0CCh, 062h
ctCA8  DB 08Fh, 0F1h, 0A7h, 083h, 03Bh, 00Fh, 08Eh, 044h
ctCB0  DB 02Bh, 0F8h, 082h, 064h, 00Ch, 04Fh, 0D8h, 0BAh
ctCB8  DB 0DCh, 076h, 004h, 0C2h, 011h, 0B9h, 09Eh, 06Bh
ctCC0  DB 0D1h, 050h, 0C2h, 03Fh, 01Ch, 07Bh, 059h, 022h
ctCC8  DB 09Fh, 02Ah, 0ADh, 02Ah, 0FEh, 050h, 087h, 0B4h
ctCD0  DB 09Bh, 0CEh, 00Eh, 021h, 011h, 086h, 019h, 043h
ctCD8  DB 0DAh, 091h, 048h, 05Eh, 065h, 0C4h, 045h, 03Dh
ctCE0  DB 094h, 088h, 06Fh, 0EEh, 06Dh, 040h, 0DAh, 00Ch
ctCE8  DB 07Fh, 0C8h, 00Eh, 0A2h, 044h, 0C0h, 0FBh, 0F1h
ctCF0  DB 068h, 02Fh, 066h, 0EBh, 0DDh, 070h, 02Dh, 01Ah
ctCF8  DB 0CCh, 050h, 0A7h, 0C7h, 06Eh, 0BAh, 0E8h, 014h
ctD00  DB 0CCh, 0EFh, 0B2h, 051h, 01Eh, 05Eh, 04Eh, 0FDh
ctD08  DB 0E3h, 034h, 002h, 00Fh, 003h, 01Eh, 092h, 05Ah
ctD10  DB 05Ah, 027h, 0ECh, 0E8h, 0CAh, 075h, 085h, 03Ah
ctD18  DB 03Fh, 0BEh, 01Ah, 0A6h, 0CFh, 072h, 0ADh, 0D4h
ctD20  DB 0DDh, 0D1h, 0FDh, 0ABh, 092h, 00Dh, 050h, 001h
ctD28  DB 0D5h, 034h, 0C9h, 021h, 02Dh, 0DEh, 0CDh, 0A6h
ctD30  DB 086h, 0CAh, 027h, 004h, 0E2h, 05Ah, 068h, 0CDh
ctD38  DB 07Ah, 0ADh, 0C4h, 0D8h, 02Fh, 0C7h, 030h, 00Ah
ctD40  DB 0B4h, 092h, 06Ah, 0F4h, 06Dh, 09Ch, 068h, 0B9h
ctD48  DB 05Bh, 088h, 028h, 074h, 02Dh, 001h, 06Fh, 095h
ctD50  DB 0E3h, 047h, 0C8h, 040h, 08Ch, 032h, 021h, 082h
ctD58  DB 007h, 035h, 0ACh, 0BBh, 0CFh, 057h, 09Bh, 07Ah
ctD60  DB 017h, 0D4h, 0BFh, 0C3h, 099h, 018h, 047h, 029h
ctD68  DB 09Fh, 0D3h, 086h, 02Bh, 0C2h, 015h, 06Ch, 092h
ctD70  DB 099h, 09Dh, 0CAh, 067h, 09Eh, 084h, 06Fh, 0A3h
ctD78  DB 0EBh, 053h, 000h, 04Fh, 003h, 099h, 040h, 0BCh
ctD80  DB 06Ch, 058h, 0BEh, 0CFh, 027h, 021h, 08Ch, 04Ah
ctD88  DB 054h, 0E2h, 072h, 073h, 069h, 050h, 02Eh, 069h
ctD90  DB 0F0h, 0EDh, 018h, 0B4h, 05Ah, 0ACh, 076h, 0E2h
ctD98  DB 037h, 05Eh, 063h, 0CBh, 064h, 004h, 0DEh, 0BBh
ctDA0  DB 02Bh, 099h, 0EDh, 033h, 062h, 0C6h, 038h, 0E6h
ctDA8  DB 093h, 04Dh, 069h, 027h, 07Ch, 03Bh, 03Dh, 0B8h
ctDB0  DB 088h, 09Fh, 012h, 0F1h, 04Eh, 0AFh, 026h, 05Bh
ctDB8  DB 046h, 0CAh, 0A7h, 004h, 06Fh, 01Dh, 051h, 003h
ctDC0  DB 0D9h, 048h, 064h, 0B0h, 06Bh, 037h, 064h, 08Bh
ctDC8  DB 0A9h, 000h, 0C3h, 0A8h, 08Ah, 0C9h, 037h, 098h
ctDD0  DB 09Fh, 0C2h, 060h, 01Fh, 0E9h, 042h, 08Bh, 0BFh
ctDD8  DB 016h, 0B4h, 036h, 021h, 04Ch, 0FAh, 087h, 02Ch
ctDE0  DB 02Ah, 0DFh, 06Ah, 059h, 06Eh, 0F0h, 003h, 008h
ctDE8  DB 01Eh, 009h, 0F6h, 009h, 076h, 017h, 02Ah, 072h
ctDF0  DB 0F0h, 0FBh, 01Ch, 0A2h, 05Fh, 01Bh, 050h, 04Eh
ctDF8  DB 04Eh, 073h, 033h, 03Eh, 004h, 087h, 0ECh, 039h
ctE00  DB 073h, 061h, 061h, 09Eh, 070h, 0CFh, 0B3h, 026h
ctE08  DB 099h, 05Ch, 08Bh, 0FBh, 088h, 016h, 01Bh, 0B5h
ctE10  DB 069h, 00Ah, 079h, 01Eh, 0D1h, 078h, 061h, 05Dh
ctE18  DB 08Bh, 003h, 00Eh, 014h, 0B6h, 06Ch, 0C7h, 060h
ctE20  DB 0BEh, 082h, 043h, 0DCh, 05Ah, 078h, 0F8h, 09Fh
ctE28  DB 09Bh, 09Dh, 0EAh, 0E2h, 0F5h, 0E5h, 0E2h, 044h
ctE30  DB 0F5h, 09Dh, 021h, 064h, 0F4h, 038h, 015h, 026h
ctE38  DB 05Ch, 05Dh, 045h, 006h, 022h, 02Eh, 013h, 0D2h
ctE40  DB 0E6h, 0F0h, 0EEh, 029h, 07Bh, 00Ch, 02Dh, 07Eh
ctE48  DB 069h, 020h, 044h, 0A5h, 0B0h, 068h, 082h, 0F3h
ctE50  DB 084h, 06Ah, 0A7h, 04Ah, 001h, 083h, 08Ch, 01Fh
ctE58  DB 094h, 058h, 0CDh, 091h, 031h, 049h, 08Dh, 066h
ctE60  DB 032h, 0C1h, 030h, 0D8h, 029h, 046h, 0FFh, 088h
ctE68  DB 055h, 0B0h, 0ECh, 0EFh, 017h, 03Fh, 0F8h, 022h
ctE70  DB 093h, 098h, 0E6h, 026h, 00Ah, 054h, 006h, 0B2h
ctE78  DB 064h, 0FBh, 0DEh, 004h, 05Ah, 02Ah, 003h, 0E8h
ctE80  DB 005h, 0B9h, 056h, 090h, 06Eh, 06Ah, 071h, 022h
ctE88  DB 0A5h, 0D8h, 09Dh, 0ACh, 010h, 06Eh, 07Bh, 0F5h
ctE90  DB 028h, 0EEh, 0FAh, 070h, 0B3h, 020h, 0ACh, 0DDh
ctE98  DB 03Ch, 0C1h, 0A6h, 03Dh, 052h, 028h, 003h, 0F3h
ctEA0  DB 017h, 04Fh, 07Bh, 0C1h, 061h, 0FEh, 04Fh, 0AEh
ctEA8  DB 024h, 0BAh, 054h, 0E0h, 0A6h, 0CAh, 0E1h, 0FCh
ctEB0  DB 036h, 050h, 037h, 0F1h, 02Ch, 011h, 038h, 07Dh
ctEB8  DB 095h, 0FDh, 066h, 049h, 057h, 073h, 020h, 029h
ctEC0  DB 0D1h, 01Ch, 0C2h, 09Eh, 0A4h, 0C2h, 0C2h, 01Ah
ctEC8  DB 08Fh, 004h, 0A7h, 000h, 092h, 07Fh, 034h, 08Dh
ctED0  DB 0AFh, 0B6h, 0DCh, 062h, 0C4h, 054h, 03Eh, 0FBh
ctED8  DB 08Bh, 037h, 0E4h, 0BEh, 07Ah, 039h, 09Ch, 093h
ctEE0  DB 05Fh, 005h, 0CEh, 018h, 0DAh, 028h, 0D0h, 028h
ctEE8  DB 0E6h, 0EBh, 038h, 070h, 04Bh, 029h, 0CBh, 08Eh
ctEF0  DB 0BCh, 0F8h, 04Eh, 0B3h, 0A7h, 00Ah, 051h, 06Dh
ctEF8  DB 06Ah, 01Dh, 02Dh, 0CEh, 0DEh, 0EEh, 0BEh, 03Ch
ctF00  DB 007h, 093h, 089h, 05Dh, 0E9h, 0DFh, 07Ch, 00Eh
ctF08  DB 0D6h, 02Dh, 0E5h, 078h, 058h, 003h, 08Dh, 08Ah
ctF10  DB 036h, 07Ch, 0CBh, 050h, 03Ah, 045h, 01Ah, 0CFh
ctF18  DB 0DFh, 0A4h, 0D0h, 017h, 0E5h, 07Dh, 0B2h, 09Eh
ctF20  DB 099h, 063h, 0BEh, 045h, 01Bh, 03Fh, 060h, 0F2h
ctF28  DB 0B5h, 0BBh, 0A5h, 0C3h, 02Ch, 0BCh, 09Eh, 0B5h
ctF30  DB 0A2h, 0C8h, 092h, 035h, 059h, 0F4h, 0A9h, 06Ah
ctF38  DB 07Fh, 067h, 09Ch, 060h, 092h, 05Bh, 06Ch, 0FBh
ctF40  DB 0DCh, 09Ch, 001h, 08Dh, 009h, 03Eh, 093h, 032h
ctF48  DB 023h, 0AEh, 0D0h, 04Bh, 086h, 0E8h, 0DEh, 000h
ctF50  DB 067h, 0F6h, 00Ch, 0F8h, 05Dh, 0BCh, 0D9h, 0DAh
ctF58  DB 01Ch, 0AAh, 0E8h, 0F3h, 02Eh, 0E6h, 091h, 0F8h
ctF60  DB 079h, 042h, 0D9h, 029h, 0B5h, 0A4h, 078h, 0A1h
ctF68  DB 0B5h, 050h, 0EAh, 020h, 00Ah, 060h, 039h, 039h
ctF70  DB 0C2h, 056h, 0FFh, 054h, 002h, 0A3h, 0C3h, 0B3h
ctF78  DB 025h, 0F2h, 017h, 07Ah, 08Eh, 04Fh, 0B3h, 0B9h
ctF80  DB 005h, 099h, 0EBh, 04Eh, 00Ah, 08Ch, 057h, 057h
ctF88  DB 080h, 0A6h, 08Ah, 0E4h, 07Ch, 027h, 050h, 051h
ctF90  DB 0F1h, 078h, 014h, 0C0h, 078h, 094h, 0BFh, 072h
ctF98  DB 08Bh, 031h, 0E1h, 0A9h, 06Dh, 042h, 0E7h, 02Fh
ctFA0  DB 0B2h, 0E1h, 0BBh, 029h, 0C2h, 0B4h, 065h, 02Bh
ctFA8  DB 0B7h, 0F6h, 09Ch, 0EEh, 072h, 020h, 0A6h, 080h
ctFB0  DB 0D4h, 0E6h, 003h, 0AFh, 033h, 031h, 040h, 0E9h
ctFB8  DB 01Fh, 083h, 063h, 0DAh, 059h, 0ECh, 0CBh, 004h
ctFC0  DB 085h, 097h, 00Dh, 05Fh, 036h, 0A2h, 09Fh, 016h
ctFC8  DB 088h, 093h, 0E4h, 03Bh, 061h, 084h, 0CBh, 0EAh
ctFD0  DB 029h, 0BAh, 001h, 090h, 09Eh, 060h, 067h, 017h
ctFD8  DB 083h, 0B6h, 0C3h, 088h, 05Dh, 06Dh, 0FEh, 0FAh
ctFE0  DB 0CBh, 0D5h, 0A1h, 02Ch, 091h, 0D2h, 0F7h, 037h
ctFE8  DB 00Dh, 0F9h, 08Ah, 0DCh, 09Bh, 0E3h, 011h, 026h
ctFF0  DB 059h, 0F9h, 074h, 026h, 04Ah, 011h, 0A8h, 098h
ctFF8  DB 077h, 0B0h, 032h, 082h, 06Eh, 01Ah, 0E3h, 05Ch

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			LOCK_SECTOR
;
;		DESCRIPTION:	LOCK SECTOR
;
;		PARAMETERS:		AL			DRIVE
;						EDX			SECTOR
;
;		RETURNS:		EBX			HANDLE
;						ESI			LOGICAL ADDRESS
;						NC			SUCCESS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public lock_sector

lock_sector	PROC near
	LockSector
	ret
lock_sector	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;		NAME:			GET_PARAM
;
;		DESCRIPTION:	READ DRIVE PARAMS FROM BOOT RECORD
;
;		RETRUNS:		DS			ADDRESS TO DRIVE DATA
;						ES			FLAT_SEL
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	public get_param

get_param	Proc near
	push ax
	push ebx
	push ecx
	push edx
	push esi
;
	mov ds:drive_root_handle,0
	mov ds:drive_nr,al
	xor edx,edx
	LockSector
	mov edx,es:[esi].boot_hidden_sectors
	mov ds:mapping_sector,edx
	movzx ecx,es:[esi].boot_mapping_sectors
	add edx,ecx
	mov ds:data_sector,edx
	mov ecx,es:[esi].boot_sectors
	sub ecx,edx
	mov ds:sectors,ecx
	UnlockSector
;
	pop esi
	pop edx
	pop ecx
	pop ebx
	pop ax
	ret
get_param	Endp

code	ENDS

	END

