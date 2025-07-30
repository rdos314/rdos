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
; RTL8169.ASM
; RTL8168/8169/8110/8111/8136 series network driver
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE ..\os\system.def
INCLUDE ..\driver.def
INCLUDE ..\os.def
INCLUDE ..\os.inc
INCLUDE ..\user.def
INCLUDE ..\user.inc
INCLUDE ..\pcdev\pci.inc
INCLUDE ..\os\core.inc
INCLUDE ..\os\net.inc


; phy macros

write MACRO reg, val
  DW reg, val
            ENDM

write_paged MACRO sel, reg, val
  DW 01Fh, sel
  DW reg, val
  DW 01Fh, 0h 
            ENDM

modify_extpage  MACRO sel, reg, mask, val
  DW 01Fh, 7
  DW 01Eh, sel
  DW 200h + reg, val, mask
  DW 01Fh, 0h
           ENDM

set_bits  MACRO reg, mask
  DW 100h + reg, mask
          ENDM

clear_bits  MACRO reg, mask
  DW 200h + reg, 0, mask
          ENDM

modify MACRO reg, p1, p2
  DW 200h + reg, p2, p1
          ENDM

modify_paged MACRO par, reg, p1, p2
  DW 01Fh, par
  DW 200h + reg, p2, p1
         ENDM

8168d_param  MACRO reg, p1, p2
  DW 1Fh, 5
  DW 5, reg
  DW 206h, p2, p1
  DW 1Fh, 0 
             ENDM

8168g_param  MACRO reg, p1, p2
  DW 1Fh, 0A43h
  DW 13h, reg
  DW 214h, p2, p1
  DW 1Fh, 0 
             ENDM

conf_8168d  MACRO
  write 01Fh,  00001h
  write 006h,  04064h
  write 007h,  02863h
  write 008h,  0059Ch
  write 009h,  026B4h
  write 00Ah,  06A19h
  write 00Bh,  0DCC8h
  write 010h,  0F06Dh
  write 014h,  07F68h
  write 018h,  07FD9h
  write 01Ch,  0F0FFh
  write 01Dh,  03D9Ch
  write 01Fh,  00003h
  write 012h,  0F49Fh
  write 013h,  0070Bh
  write 01Ah,  005ADh
  write 014h,  094C0h

  write 01Fh,  00002h
  write 006h,  05561h
  write 01Fh,  00005h
  write 005h,  08332h
  write 006h,  05561h

  write 01Fh,  00001h
  write 017h,  00CC0h
  write 01Fh,  00000h
  write 00Dh,  0F880h
        ENDM

conf_8168f  MACRO
  8168d_param 08B80h, 0, 6
  modify_extpage 2Dh, 18h, 0, 0FFFFh, 10h
  set_bits 14h, 8000h
  8168d_param 08B86h, 0, 1
  ee_8168f
              ENDM

ee_8168g  MACRO
  modify_paged 0A43h, 11h, 0, 10h
             ENDM

ee_8168f  MACRO
  modify_extpage 20h, 15h, 0, 0FFFFh, 100h
  8168d_param 8B85h, 0, 2000h
             ENDM

call_proc  MACRO p
   DW 300h
   DW OFFSET p
           ENDM

wait_ms  MACRO ms
   DW 400h
   DW ms
         ENDM

apply_firmware_cond  MACRO p1
                     ENDM

write_mmd    MACRO adr, port, data
  DW 00Dh,  adr
  DW 00Eh,  port
  DW 00Dh,  04000h + adr
  DW 00Eh,  data
  DW 00Dh,  00000h  
             ENDM

8125_legacy  MACRO
  modify_paged 0A5Bh, 12h, 8000h, 0
             ENDM

ephy_init  MACRO reg, mask, bits
  DW 500h + reg, mask, bits
             ENDM

write_eri  MACRO reg, mask, val
  DW 600h
  DW reg
  DD mask
  DD val
             ENDM

clear_eri_bits  MACRO reg, bits
  DW 700h
  DW reg
  DD bits
  DD 0
             ENDM

set_eri_bits  MACRO reg, bits
  DW 700h
  DW reg
  DD 0
  DD bits
             ENDM

modify_eri  MACRO reg, set, clear
  DW 700h
  DW reg
  DD clear
  DD set
             ENDM

modify_config  MACRO reg, set, clear
  DW 800h + reg
  DB clear
  DB set
             ENDM

set_fifo_size  MACRO
  write_eri 0C8h, ERIAR_MASK_1111, 100002h
  write_eri 0E8h, ERIAR_MASK_1111, 100006h
               ENDM

reset_packet_filter  MACRO
  clear_eri_bits 0DCh, 1
  set_eri_bits 0DCh, 1
               ENDM

start_8168f   MACRO
  write_eri 0C0h, ERIAR_MASK_0011, 00000h
  write_eri 0B8h, ERIAR_MASK_1111, 00000h
  set_fifo_size
  reset_packet_filter
  set_eri_bits 01B0h, 10h
  set_eri_bits 01D0h, 12h
  write_eri 0CCh, ERIAR_MASK_1111, 000000050h
  write_eri 0D0h, ERIAR_MASK_1111, 000000060h
              ENDM

start_8168g   MACRO
  set_fifo_size
  reset_packet_filter
  write_eri 02F8h, ERIAR_MASK_0011, 01D8Fh
  write_eri 0C0h, ERIAR_MASK_0011, 00000h
  write_eri 0B8h, ERIAR_MASK_0011, 00000h
  modify_eri 2FCh, 1, 6
  clear_eri_bits 01B0h, 1000h
              ENDM

start_8168ep   MACRO
  set_fifo_size
  reset_packet_filter
  write_eri 0C0h, ERIAR_MASK_0011, 00000h
  write_eri 0B8h, ERIAR_MASK_0011, 00000h
  modify_eri 2FCh, 1, 6
            ENDM

disable_aspm  MACRO
  modify_config 2, 0, 80h
  modify_config 5, 0, 1
              ENDM

RX_DESCR_COUNT = 256
TX_DESCR_COUNT = 128

; The EEPROM commands include the alway-set leading bit.

EE_WRITE_CMD = 5
EE_READ_CMD = 6
EE_ERASE_CMD = 7

EE_PROGRAM    = 80h
EE_CS         = 8
EE_CLK        = 4
EE_DATA_WRITE = 2
EE_DATA_READ  = 1
EE_ENB        = EE_PROGRAM + EE_CS
EE_DIS        = EE_PROGRAM

IR_SER = 8000h
IR_Timeout = 4000h
IR_FEmp = 200h
IR_SWInt = 100h
IR_TDU = 80h
IR_FOVW = 40h
IR_LinkChg = 20h
IR_RDU = 10h
IR_TER = 8
IR_TOK = 4
IR_RER = 2
IR_ROK = 1
IR_MASK = 3FFh


ERIAR_WRITE_CMD = 80000000h
ERIAR_MASK_0001 = 01000h
ERIAR_MASK_0011 = 03000h
ERIAR_MASK_0100 = 04000h
ERIAR_MASK_0101 = 05000h
ERIAR_MASK_1111 = 0F000h

EFUSEAR_FLAG = 80000000h
EFUSEAR_WRITE_CMD = 80000000h
EFUSEAR_READ_CMD = 0
EFUSEAR_REG_MASK = 03FFh
EFUSEAR_REG_SHIFT = 8
EFUSEAR_DATA_MASK = 0FFh

OCPAR_FLAG = 80000000h
OCP_STD_PHY_BASE = 0A400h

PHY_10      = 4
PHY_100     = 8
PHY_1000    = 10h

ADV_10_HALF     = 20h
ADV_10_FULL     = 40h
ADV_100_HALF    = 80h
ADV_100_FULL    = 100h
ADV_1000_HALF   = 400h
ADV_1000_FULL   = 800h

R8168DP_1_MDIO_ACCESS_BIT = 020000h

REG_IDR0 = 0                ; Ethernet hardware address. 
REG_MAR0 = 8                ; Multicast
REG_DTCCR = 10h
REG_TNPDS = 20h
REG_THPDS = 28h
REG_CR    = 37h
REG_TPPoll = 38h
REG_IMR = 3Ch
REG_ISR = 3Eh
REG_TCR = 40h
REG_RCR = 44h
REG_TCTR = 48h
REG_MPC = 4Ch
REG_9346CR = 50h
REG_CONFIG0 = 51h
REG_CONFIG1 = 52h
REG_CONFIG2 = 53h
REG_CONFIG3 = 54h
REG_CONFIG4 = 55h
REG_CONFIG5 = 56h
REG_TimerInt = 58h
REG_PHYAR = 60h
REG_TBICSR0 = 64h
REG_TBI_ANAR = 68h
REG_TBI_LPAR = 6Ah
REG_PHYStatus = 6Ch

REG_ERIDR = 70h
REG_ERIAR = 74h

REG_EPHYAR = 80h

REG_OCPDR = 0B0h
REG_GPHY_OCP = 0B8h

REG_DP2 = 0D0h
REG_RMS = 0DAh
REG_EFUSE = 0DCh
REG_CCR = 0E0h
REG_RDSAR = 0E4h
REG_MTPS = 0ECh

RX_OWN = 8000h
RX_EOR = 4000h
RX_FS = 2000h
RX_LS = 1000h
RX_MAR = 800h
RX_PAM = 400h
RX_BAR = 200h
RX_RWT = 40h
RX_RES = 20h
RX_RUNT = 10h
RX_CRC = 8
RX_PID1 = 4
RX_PID0 = 2
RX_IPF = 1
RX_UDPF = 8000h
RX_TCPF = 4000h

rx_descr    STRUC

rx_fl_size  DW ?
rx_flags    DW ?
rx_resv     DD ?
rx_low_ads  DD ?
rx_high_ads DD ?

rx_descr    ENDS

TX_OWN = 8000h
TX_EOR = 4000h
TX_FS = 2000h
TX_LS = 1000h
TX_LGSEN = 800h
TX_IPCS = 4
TX_UDPS = 2
TX_TCPCS = 1

tx_descr    STRUC

tx_size     DW ?
tx_flags    DW ?
tx_resv     DD ?
tx_low_ads  DD ?
tx_high_ads DD ?

tx_descr    ENDS

mem_struc	STRUC

mem_idr0      DD ?
mem_idr1      DD ?
mem_mar0      DD ?
mem_mar1      DD ?
mem_dtccr     DD ?, ?, ?, ?
mem_tnpds     DD ?,?
mem_thpds     DD ?,?
mem_resv1     DB ?, ?, ?, ?, ?, ?, ?
mem_cr        DB ?
mem_tppoll    DB ?, ?, ?, ?
mem_imr       DW ?
mem_isr       DW ?
mem_tcr       DD ?
mem_rcr       DD ?
mem_tctr      DD ?
mem_mpc       DD ?
mem_9346cr    DB ?
mem_config0   DB ?
mem_config1   DB ?
mem_config2   DB ?
mem_config3   DB ?
mem_config4   DB ?
mem_config5   DB ?
mem_resv2     DB ?
mem_timerint  DD ?, ?
mem_phyar     DD ?
mem_tbicsr0   DD ?
mem_tbi_anar  DW ?
mem_tbi_lpar  DW ?
mem_phy_stat  DB ?, ?, ?, ?
mem_eridr     DD ?
mem_eriar     DD ?                   ; 74h
mem_res3      DD ?, ?                ; 78h
mem_ephyar    DD ?                   ; 80h
mem_res4      DD ?, ?, ?             ; 84h-8Fh
mem_res5      DD ?, ?, ?, ?          ; 90h-9Fh
mem_res6      DD ?, ?, ?, ?          ; A0h-AFh
mem_ocpdr     DD ?                   ; B0h-B3h
mem_res7      DD ?                   ; B04-B7h
mem_gphy      DD ?                   ; B8h-BBh
mem_res8      DD ?, ?, ?, ?, ?       ; BCh-CFh
mem_dp2       DD ?                   ; D0h-D3h
mem_res9      DW ?, ?, ?             ; D4h-D9h
mem_rms       DW ?
mem_efuse     DD ?
mem_ccr       DW ?, ?
mem_rdsar     DD ?, ?
mem_mtps      DB ?, ?, ?, ?             
mem_res10     DD ?, ?, ?, ?

mem_struc	ENDS
 
data    STRUC

IoBase              DW ?
MemSel              DW ?
IoCfg               DW ?
Handle              DW ?
Isr                 DW ?
RxRingSel           DW ?
RxRingPhys          DD ?
TxRingSel           DW ?
TxRingPhys          DD ?
RxCurrDescr         DW ?
RxCurrLinear        DD ?
TxCurrDescr         DW ?
TxLastDescr         DW ?
SuperThread         DW ?
HwId                DW ?
PhyBase             DW ?
ReadPhyProc         DW ?
WritePhyProc        DW ?
PhyTimeout          DD ?,?
TxSection           section_typ <>
EthernetAddress     DB 6 DUP(?)
EeAdrLen            DB ?
TimerStarted        DB ?

RxLinearArr         DD RX_DESCR_COUNT DUP(?)
TxLinearArr         DD TX_DESCR_COUNT DUP(?)

data    ENDS

code    SEGMENT byte public 'CODE'


    assume cs:code

IFDEF __WASM__
    .686p
    .xmm2
ELSE
    .386p
ENDIF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoReadEe
;
;           DESCRIPTION:    Read Ee location
;
;       PARAMETERS:     BX          Location
;
;           RETURNS:        AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadEe  Proc near
    push bx
    push cx
    push si
;
    mov si,bx
    mov dx,ds:IoBase
    add dx,REG_9346CR
;
    mov al,EE_DIS
    out dx,al
    mov al,EE_ENB
    out dx,al
;
    mov bx,EE_READ_CMD
    movzx cx,ds:EeAdrLen
    shl bx,cl
    or bx,si
;
    add cx,4
    mov si,1
    shl si,cl
    inc cx

ioreSetupLoop:
    test bx,si
    jz ioreSetup0
;
    mov al,EE_DATA_WRITE + EE_ENB
    out dx,al
    jmp ioreSetupShift

ioreSetup0:
    mov al,EE_ENB
    out dx,al

ioreSetupShift:
    push ax
    in eax,dx
    pop ax
;
    or al,EE_CLK
    out dx,al
    in eax,dx
;
    shr si,1
    loop ioreSetupLoop
;
    mov al,EE_ENB
    out dx,al
    in eax,dx
;
    mov cx,16
    xor bx,bx

ioreReadLoop:
    shl bx,1
;
    mov al,EE_ENB + EE_CLK
    out dx,al
    in eax,dx
;
    in al,dx
    test al,EE_DATA_READ
    jz ioreReadNext
;
    or bx,1

ioreReadNext:
    mov al,EE_ENB
    out dx,al
    in eax,dx
;
    loop ioreReadLoop
;
    mov al,NOT EE_CS
    out dx,al
;
    mov ax,bx
;
    pop si
    pop cx
    pop bx
    ret
IoReadEe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemReadEe
;
;           DESCRIPTION:    Read Ee location
;
;       PARAMETERS:         FS          Registers
;                           BX          Location
;
;           RETURNS:        AX          Result
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadEe  Proc near
    push bx
    push cx
    push si
;
    mov si,bx
;
    mov al,EE_DIS
    mov fs:mem_9346cr,al
;
    mov al,EE_ENB
    mov fs:mem_9346cr,al
;
    mov bx,EE_READ_CMD
    movzx cx,ds:EeAdrLen
    shl bx,cl
    or bx,si
;
    add cx,4
    mov si,1
    shl si,cl
    inc cx

mreSetupLoop:
    test bx,si
    jz mreSetup0
;
    mov al,EE_DATA_WRITE + EE_ENB
    mov fs:mem_9346cr,al
    jmp mreSetupShift

mreSetup0:
    mov al,EE_ENB
    mov fs:mem_9346cr,al

mreSetupShift:
    push ax
    mov al,fs:mem_9346cr
    pop ax
;
    or al,EE_CLK
    mov fs:mem_9346cr,al
    mov al,fs:mem_9346cr
;
    shr si,1
    loop mreSetupLoop
;
    mov al,EE_ENB
    mov fs:mem_9346cr,al
    mov al,fs:mem_9346cr
;
    mov cx,16
    xor bx,bx

mreReadLoop:
    shl bx,1
;
    mov al,EE_ENB + EE_CLK
    mov fs:mem_9346cr,al
    mov al,fs:mem_9346cr
;
    mov al,fs:mem_9346cr
    test al,EE_DATA_READ
    jz mreReadNext
;
    or bx,1

mreReadNext:
    mov al,EE_ENB
    mov fs:mem_9346cr,al
    mov al,fs:mem_9346cr
;
    loop mreReadLoop
;
    mov al,NOT EE_CS
    mov fs:mem_9346cr,al
;
    mov ax,bx
;
    pop si
    pop cx
    pop bx
    ret
MemReadEe  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateRxRing
;
;           DESCRIPTION:    Create RX ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateRxRing    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    or al,13h
    SetPageEntry
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    GetPageEntry
    and ax,0F000h
    mov ds:RxRingPhys,eax
;
    mov ecx,0FFFh
    AllocateGdt
    CreateDataSelector16
    mov ds:RxRingSel,bx
;
    mov es,bx
    mov cx,RX_DESCR_COUNT
    mov si,OFFSET RxLinearArr
    xor di,di

crLoop:
    mov es:[di].rx_fl_size,1FF8h
    mov es:[di].rx_flags,RX_OWN
;
    push ecx
    mov eax,2000h    
    AllocateBigLinear
    mov ds:[si],edx
;    
    mov ecx,2
    AllocateMultiplePhysical32
    pop ecx
    mov es:[di].rx_low_ads,eax
;
    mov al,13h
    SetPageEntry
    add edx,1000h
    add eax,1000h
    SetPageEntry
;
    add si,4
    add di,16
    sub cx,1
    jnz crLoop   
;
;    sub di,16
    sub di,32
    or es:[di].rx_flags,RX_EOR
;
    popad
    pop es
    ret
CreateRxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetRxRing
;
;           DESCRIPTION:    Reset RX ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetRxRing    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
;
    mov bx,ds:RxRingSel
    mov es,bx
    mov cx,RX_DESCR_COUNT
    xor di,di

rrLoop:
    mov es:[di].rx_fl_size,1FF8h
    mov es:[di].rx_flags,RX_OWN
    mov es:[di].rx_resv,0
;
    add di,16
    sub cx,1
    jnz rrLoop   
;
    sub di,32
    or es:[di].rx_flags,RX_EOR
    mov ds:RxCurrDescr,0
;
    popad
    pop es
    ret
ResetRxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateTxRing
;
;           DESCRIPTION:    Create TX ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateTxRing    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
    mov eax,1000h
    AllocateBigLinear
    AllocatePhysical32
    or al,13h
    SetPageEntry
    mov edi,edx
    mov ecx,400h
    xor eax,eax
    rep stos dword ptr es:[edi]
;
    GetPageEntry
    and ax,0F000h
    mov ds:TxRingPhys,eax
;
    mov ecx,0FFFh
    AllocateGdt
    CreateDataSelector16
    mov ds:TxRingSel,bx
;
    mov es,bx
    mov cx,TX_DESCR_COUNT
    mov si,OFFSET TxLinearArr
    xor di,di

ctLoop:
    mov es:[di].tx_flags,TX_LS OR TX_FS
;
    push ecx
    mov eax,2000h    
    AllocateBigLinear
    mov ds:[si],edx
;    
    mov ecx,2
    AllocateMultiplePhysical32
    pop ecx
    mov es:[di].tx_low_ads,eax
;
    mov al,13h
    SetPageEntry
    add edx,1000h
    add eax,1000h
    SetPageEntry
;
    add si,4
    add di,16
    sub cx,1
    jnz ctLoop   
;
    sub di,16
    or es:[di].tx_flags,TX_EOR
;
    mov ds:TxCurrDescr,0
    mov ds:TxLastDescr,di
;
    popad
    pop es
    ret
CreateTxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ResetTxRing
;
;           DESCRIPTION:    Reset TX ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetTxRing    Proc near
    push es
    pushad
;    
    mov ax,flat_sel
    mov es,ax
;
    mov bx,ds:TxRingSel
    mov es,bx
    mov cx,TX_DESCR_COUNT
    xor di,di

rtLoop:
    mov es:[di].tx_flags,TX_LS OR TX_FS
;
    add di,16
    sub cx,1
    jnz rtLoop   
;
    sub di,16
    or es:[di].tx_flags,TX_EOR
;
    mov ds:TxCurrDescr,0
    mov ds:TxLastDescr,di
;
    popad
    pop es
    ret
ResetTxRing   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoWritePhy8169
;
;           DESCRIPTION:    Write to phy, 8169 version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoWritePhy8169    Proc near
    push eax
    push cx
    push dx
;    
    movzx eax,ax
    ror eax,8
    mov ah,dl
    rol eax,8
    or eax,80000000h
;    
    mov dx,ds:IoBase
    add dx,REG_PHYAR
;
    out dx,eax
    xor cx,cx

iowpWait8169:    
    pause
    in eax,dx
    test eax,80000000h
    jz iowpDone8169
    loop iowpWait8169

iowpDone8169:
    mov ax,20
    WaitMicroSec
;    
    pop dx
    pop cx
    pop eax
    ret
IoWritePhy8169    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemWritePhy8169
;
;           DESCRIPTION:    Write to phy, 8169 version
;
;           PARAMETERS:     FS      Registers
;                           DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemWritePhy8169    Proc near
    push eax
    push cx
;    
    movzx eax,ax
    ror eax,8
    mov ah,dl
    rol eax,8
    or eax,80000000h
;
    mov fs:mem_phyar,eax
    xor cx,cx

mwpWait8169:    
    pause
    mov eax,fs:mem_phyar
    test eax,80000000h
    jz mwpDone8169
    loop mwpWait8169

mwpDone8169:
    mov ax,20
    WaitMicroSec
;    
    pop cx
    pop eax
    ret
MemWritePhy8169    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePhy8169
;
;           DESCRIPTION:    Write to phy, 8169 version
;
;           PARAMETERS:     FS      Registers
;                           DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;r8169_mdio_write

WritePhy8169	Proc near
    push ax
    mov ax,ds:MemSel
    or ax,ax
    pop ax
    jz IoWritePhy8169
    jmp MemWritePhy8169

WritePhy8169	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoReadPhy8169
;
;           DESCRIPTION:    Read from phy, 8169 version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadPhy8169    Proc near
    push cx
    push dx
;    
    xor eax,eax
    mov ah,dl
    rol eax,8
;    
    mov dx,ds:IoBase
    add dx,REG_PHYAR
;
    out dx,eax
    xor cx,cx

iorpWait8169:    
    pause
    in eax,dx
    test eax,80000000h
    jnz iorpDone8169
;
    loop iorpWait8169

iorpDone8169:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop dx
    pop cx
    ret
IoReadPhy8169    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemReadPhy8169
;
;           DESCRIPTION:    Read from phy, 8169 version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadPhy8169    Proc near
    push cx
;    
    xor eax,eax
    mov ah,dl
    rol eax,8
;
    mov fs:mem_phyar,eax
    xor cx,cx

mrpWait8169:    
    pause
    mov eax,fs:mem_phyar
    test eax,80000000h
    jnz mrpDone8169
;
    loop mrpWait8169

mrpDone8169:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop cx
    ret
MemReadPhy8169    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPhy8169
;
;           DESCRIPTION:    Read from phy, 8169 version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;r8169_mdio_read

ReadPhy8169	Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadPhy8169
    jmp MemReadPhy8169

ReadPhy8169	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoWritePhyOcp
;
;           DESCRIPTION:    Write to phy, OCP version
;
;           PARAMETERS:     DX      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoWritePhyOcp    Proc near
    push eax
    push cx
    push dx
;    
    ror eax,15
    mov ax,dx
    rol eax,15
    or eax,80000000h
;    
    mov dx,ds:IoBase
    add dx,REG_GPHY_OCP
;
    out dx,eax
    xor cx,cx

iowpWaitOcp:    
    pause
    in eax,dx
    test eax,80000000h
    jz iowpDoneOcp
    loop iowpWaitOcp

iowpDoneOcp:
    mov ax,20
    WaitMicroSec
;    
    pop dx
    pop cx
    pop eax
    ret
IoWritePhyOcp    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemWritePhyOcp
;
;           DESCRIPTION:    Write to phy, OCP version
;
;           PARAMETERS:     FS      Registers
;                           DX      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemWritePhyOcp    Proc near
    push eax
    push cx
;    
    ror eax,15
    mov ax,dx
    rol eax,15
    or eax,80000000h
;
    mov fs:mem_gphy,eax
    xor cx,cx

mwpWaitOcp:    
    pause
    mov eax,fs:mem_gphy
    test eax,80000000h
    jz mwpDoneOcp
    loop mwpWaitOcp

mwpDoneOcp:
    mov ax,20
    WaitMicroSec
;    
    pop cx
    pop eax
    ret
MemWritePhyOcp    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePhyOcp
;
;           DESCRIPTION:    Write to phy, OCP version
;
;           PARAMETERS:     DX      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePhyOcp    Proc near
    push ax
    mov ax,ds:MemSel
    or ax,ax
    pop ax
    jz IoWritePhyOcp
    jmp MemWritePhyOcp

WritePhyOcp   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoReadPhyOcp
;
;           DESCRIPTION:    Read from phy, OCP version
;
;           PARAMETERS:     DX      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadPhyOcp    Proc near
    push cx
    push dx
;    
    movzx eax,dx
    rol eax,15
;    
    mov dx,ds:IoBase
    add dx,REG_GPHY_OCP
;
    out dx,eax
    xor cx,cx

iorpWaitOcp:    
    pause
    in eax,dx
    test eax,80000000h
    jnz iorpDoneOcp
;
    loop iorpWaitOcp

iorpDoneOcp:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop dx
    pop cx
    ret
IoReadPhyOcp    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemReadPhyOcp
;
;           DESCRIPTION:    Read from phy, OCP version
;
;           PARAMETERS:     DX      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadPhyOcp    Proc near
    push cx
;    
    movzx eax,dx
    rol eax,15
;
    mov fs:mem_gphy,eax
    xor cx,cx

mrpWaitOcp:    
    pause
    mov eax,fs:mem_gphy
    test eax,80000000h
    jnz mrpDoneOcp
;
    loop mrpWaitOcp

mrpDoneOcp:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop cx
    ret
MemReadPhyOcp    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPhyOcp
;
;           DESCRIPTION:    Read from phy, OCP version
;
;           PARAMETERS:     DX      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPhyOcp    Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadPhyOcp
    jmp MemReadPhyOcp

ReadPhyOcp    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePhy8169g
;
;           DESCRIPTION:    Write from phy, 8169g version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;r8168g_mdio_write

WritePhy8169g    Proc near
    cmp dl,1Fh
    jne wpgNotSel
;
    or ax,ax
    jz wpgUseBase
;
    shl ax,4
    mov ds:PhyBase,ax
    ret

wpgUseBase:
    mov ds:PhyBase,OCP_STD_PHY_BASE
    ret

wpgNotSel:
    push bx
    push dx
;
    movzx dx,dl
    mov bx,ds:PhyBase
    cmp bx,OCP_STD_PHY_BASE
    je wpgNotDec
;
    sub dx,10h

wpgNotDec:
    add dx,dx
    add dx,ds:PhyBase
    call WritePhyOcp
;
    pop dx
    pop bx
    ret
WritePhy8169g    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPhy8169g
;
;           DESCRIPTION:    Read from phy, 8169g version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;r8168g_mdio_read

ReadPhy8169g    Proc near
    cmp dl,1Fh
    jne rpgNotSel
;
    mov ax,ds:PhyBase
    cmp ax,OCP_STD_PHY_BASE
    je rpgUseBase
;
    shr ax,4
    ret

rpgUseBase:
    xor ax,ax
    ret

rpgNotSel:
    push dx
;
    movzx dx,dl
    mov ax,ds:PhyBase
    cmp ax,OCP_STD_PHY_BASE
    je rpgNotDec
;
    sub dx,10h

rpgNotDec:
    add dx,dx
    add dx,ds:PhyBase
    call ReadPhyOcp
;
    pop dx
    ret
ReadPhy8169g    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoWritePhy8169dp2
;
;           DESCRIPTION:    Write to phy, 8169 DP2 version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoWritePhy8169dp2    Proc near
    push eax
    push cx
    push dx
;    
    push ax
    push dx
;    
    mov dx,ds:IoBase
    add dx,REG_DP2
;
    in eax,dx
    and eax,NOT R8168DP_1_MDIO_ACCESS_BIT
    out dx,eax
;
    pop dx
    pop ax
;
    movzx eax,ax
    ror eax,8
    mov ah,dl
    rol eax,8
    or eax,80000000h
;    
    mov dx,ds:IoBase
    add dx,REG_PHYAR
;
    out dx,eax
    xor cx,cx

iowpWait8169dp2:    
    pause
    in eax,dx
    test eax,80000000h
    jz iowpDone8169dp2
    loop iowpWait8169dp2

iowpDone8169dp2:
    mov ax,20
    WaitMicroSec
;
    mov dx,ds:IoBase
    add dx,REG_DP2
;
    in eax,dx
    or eax,R8168DP_1_MDIO_ACCESS_BIT
    out dx,eax
;    
    pop dx
    pop cx
    pop eax
    ret
IoWritePhy8169dp2    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemWritePhy8169dp2
;
;           DESCRIPTION:    Write to phy, 8169 DP2 version
;
;           PARAMETERS:     FS      Registers
;                           DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemWritePhy8169dp2    Proc near
    push eax
    push ecx
;    
    mov ecx,fs:mem_dp2
    and ecx,NOT R8168DP_1_MDIO_ACCESS_BIT
    mov fs:mem_dp2,ecx
;    
    movzx eax,ax
    ror eax,8
    mov ah,dl
    rol eax,8
    or eax,80000000h
;
    mov fs:mem_phyar,eax
    xor cx,cx

mwpWait8169dp2:    
    pause
    mov eax,fs:mem_phyar
    test eax,80000000h
    jz mwpDone8169dp2
    loop mwpWait8169dp2

mwpDone8169dp2:
    mov ax,20
    WaitMicroSec
;    
    mov ecx,fs:mem_dp2
    or ecx,R8168DP_1_MDIO_ACCESS_BIT
    mov fs:mem_dp2,ecx
;    
    pop ecx
    pop eax
    ret
MemWritePhy8169dp2    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePhy8168dp2
;
;           DESCRIPTION:    Write to phy, 8168dp2 version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; r8168dp_2_mdio_write

WritePhy8168dp2    Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoWritePhy8169dp2
    jmp MemWritePhy8169dp2

WritePhy8168dp2   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoReadPhy8169dp2
;
;           DESCRIPTION:    Read from phy, 8169 DP2 version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadPhy8169dp2    Proc near
    push cx
    push dx
;    
    push dx
;    
    mov dx,ds:IoBase
    add dx,REG_DP2
;
    in eax,dx
    and eax,NOT R8168DP_1_MDIO_ACCESS_BIT
    out dx,eax
;
    pop dx
;    
    xor eax,eax
    mov ah,dl
    rol eax,8
;    
    mov dx,ds:IoBase
    add dx,REG_PHYAR
;
    out dx,eax
    xor cx,cx

iorpWait8169dp2:    
    pause
    in eax,dx
    test eax,80000000h
    jnz iorpDone8169dp2
;
    loop iorpWait8169dp2

iorpDone8169dp2:
    push eax
;
    mov ax,20
    WaitMicroSec
;
    mov dx,ds:IoBase
    add dx,REG_DP2
;
    in eax,dx
    or eax,R8168DP_1_MDIO_ACCESS_BIT
    out dx,eax
;
    pop eax
;    
    pop dx
    pop cx
    ret
IoReadPhy8169dp2    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemReadPhy8169dp2
;
;           DESCRIPTION:    Read from phy, 8169 DP2 version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadPhy8169dp2    Proc near
    push cx
;    
    mov eax,fs:mem_dp2
    and eax,NOT R8168DP_1_MDIO_ACCESS_BIT
    mov fs:mem_dp2,eax
;    
    xor eax,eax
    mov ah,dl
    rol eax,8
;
    mov fs:mem_phyar,eax
    xor cx,cx

mrpWait8169dp2:    
    pause
    mov eax,fs:mem_phyar
    test eax,80000000h
    jnz mrpDone8169dp2
;
    loop mrpWait8169dp2

mrpDone8169dp2:
    push eax
;
    mov ax,20
    WaitMicroSec
;    
    mov eax,fs:mem_dp2
    or eax,R8168DP_1_MDIO_ACCESS_BIT
    mov fs:mem_dp2,eax
;
    pop eax
;    
    pop cx
    ret
MemReadPhy8169dp2    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPhy8168dp2
;
;           DESCRIPTION:    Read from phy, 8168dp2 version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; r8168dp_2_mdio_read

ReadPhy8168dp2    Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadPhy8169dp2
    jmp MemReadPhy8169dp2

ReadPhy8168dp2    Endp


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoWriteMac8169
;
;           DESCRIPTION:    Write to MAC, 8169 version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoWriteMac8169    Proc near
    push eax
    push cx
    push dx
;    
    ror eax,16
    mov ax,dx
    rol eax,16
    or eax,80000000h
;    
    mov dx,ds:IoBase
    add dx,REG_OCPDR
;
    out dx,eax
    xor cx,cx

iowmWait8169:    
    pause
    in eax,dx
    test eax,80000000h
    jz iowmDone8169
    loop iowmWait8169

iowmDone8169:
    mov ax,20
    WaitMicroSec
;    
    pop dx
    pop cx
    pop eax
    ret
IoWriteMac8169    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemWriteMac8169
;
;           DESCRIPTION:    Write to mac, 8169 version
;
;           PARAMETERS:     FS      Registers
;                           DX      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemWriteMac8169    Proc near
    push eax
    push cx
;    
    ror eax,16
    mov ax,dx
    rol eax,16
    or eax,80000000h
;
    mov fs:mem_ocpdr,eax
    xor cx,cx

mwmWait8169:    
    pause
    mov eax,fs:mem_ocpdr
    test eax,80000000h
    jz mwmDone8169
    loop mwmWait8169

mwmDone8169:
    mov ax,20
    WaitMicroSec
;    
    pop cx
    pop eax
    ret
MemWriteMac8169    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteMac8169
;
;           DESCRIPTION:    Write to mac, 8169 version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; r8168_mac_ocp_write

WriteMac8169    Proc near
    push ax
    mov ax,ds:MemSel
    or ax,ax
    pop ax
    jz IoWriteMac8169
    jmp MemWriteMac8169

WriteMac8169   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoReadMac8169
;
;           DESCRIPTION:    Read from mac, 8169 version
;
;           PARAMETERS:     DX      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadMac8169    Proc near
    push cx
    push dx
;    
    movzx eax,dx
    shl eax,16
;    
    mov dx,ds:IoBase
    add dx,REG_OCPDR
;
    out dx,eax
    xor cx,cx

iormWait8169:    
    pause
    in eax,dx
    test eax,80000000h
    jnz iormDone8169
;
    loop iormWait8169

iormDone8169:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop dx
    pop cx
    ret
IoReadMac8169    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemReadMac8169
;
;           DESCRIPTION:    Read from mac, 8169 version
;
;           PARAMETERS:     DX      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadMac8169    Proc near
    push cx
;    
    movzx eax,dx
    shl eax,16
;
    mov fs:mem_ocpdr,eax
    xor cx,cx

mrmWait8169:    
    pause
    mov eax,fs:mem_ocpdr
    test eax,80000000h
    jnz mrmDone8169
;
    loop mrmWait8169

mrmDone8169:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop cx
    ret
MemReadMac8169    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadMac8169
;
;           DESCRIPTION:    Read from mac, 8169 version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; r8168_mac_ocp_read

ReadMac8169    Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadMac8169
    jmp MemReadMac8169

ReadMac8169    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoWriteEphy
;
;           DESCRIPTION:    Write to ephy
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoWriteEphy    Proc near
    push eax
    push cx
    push dx
;    
    movzx eax,ax
    ror eax,8
    mov ah,dl
    rol eax,8
    or eax,80000000h
;    
    mov dx,ds:IoBase
    add dx,REG_EPHYAR
;
    out dx,eax
    xor cx,cx

iowepWait:   
    pause
    in eax,dx
    test eax,80000000h
    jz iowepDone
    loop iowepWait

iowepDone:
    mov ax,20
    WaitMicroSec
;    
    pop dx
    pop cx
    pop eax
    ret
IoWriteEphy    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemWriteEphy
;
;           DESCRIPTION:    Write to ephy
;
;           PARAMETERS:     FS      Registers
;                           DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemWriteEphy    Proc near
    push eax
    push cx
;    
    movzx eax,ax
    ror eax,8
    mov ah,dl
    rol eax,8
    or eax,80000000h
;
    mov fs:mem_ephyar,eax
    xor cx,cx

mwepWait:    
    pause
    mov eax,fs:mem_ephyar
    test eax,80000000h
    jz mwepDone
    loop mwepWait

mwepDone:
    mov ax,20
    WaitMicroSec
;    
    pop cx
    pop eax
    ret
MemWriteEphy    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteEphy
;
;           DESCRIPTION:    Write to ephy
;
;           PARAMETERS:     FS      Registers
;                           DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;rtl_ephy_write

WriteEphy	Proc near
    push ax
    mov ax,ds:MemSel
    or ax,ax
    pop ax
    jz IoWriteEphy
    jmp MemWriteEphy

WriteEphy	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoReadEphy
;
;           DESCRIPTION:    Read from ephy
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadEphy    Proc near
    push cx
    push dx
;    
    xor eax,eax
    mov ah,dl
    rol eax,8
;    
    mov dx,ds:IoBase
    add dx,REG_EPHYAR
;
    out dx,eax
    xor cx,cx

iorepWait:    
    pause
    in eax,dx
    test eax,80000000h
    jnz iorepDone
;
    loop iorepWait

iorepDone:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop dx
    pop cx
    ret
IoReadEphy    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemReadEphy
;
;           DESCRIPTION:    Read from ephy
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadEphy    Proc near
    push cx
;    
    xor eax,eax
    mov ah,dl
    rol eax,8
;
    mov fs:mem_ephyar,eax
    xor cx,cx

mrepWait:    
    pause
    mov eax,fs:mem_ephyar
    test eax,80000000h
    jnz mrepDone
;
    loop mrepWait

mrepDone:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop cx
    ret
MemReadEphy    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadEphy
;
;           DESCRIPTION:    Read from ephy
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;rtl_ephy_read

ReadEphy	Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadEphy
    jmp MemReadEphy

ReadEphy	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IoReadEri
;
;       DESCRIPTION:    Read eri register
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                       CX      Type
;
;                      
;       RETURNS:        EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadEri   Proc near
    mov dx,ds:IoBase
    add dx,REG_ERIAR
    mov ax,cx
    shl eax,16
    or ax,bx
    or ax,ERIAR_MASK_1111
    out dx,eax
;
    xor cx,cx

ioreWait:    
    pause
    in eax,dx
    test eax,80000000h
    jnz ioreDone
;
    loop ioreWait

ioreDone:
    mov ax,1
    WaitMilliSec
;    
    mov dx,ds:IoBase
    add dx,REG_ERIDR
    in eax,dx       
    ret
IoReadEri     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           MemReadEri
;
;       DESCRIPTION:    Read eri register
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                       CX      Type
;
;                      
;       RETURNS:        EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadEri   Proc near
    mov ax,cx
    shl eax,16
    or ax,bx
    or ax,ERIAR_MASK_1111
    mov fs:mem_eriar,eax
;
    xor cx,cx

mreWait:    
    pause
    mov eax,fs:mem_eriar
    test eax,80000000h
    jnz mreDone
;
    loop mreWait

mreDone:
    mov ax,1
    WaitMilliSec
;    
    mov eax,fs:mem_eridr
    ret
MemReadEri     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadEri
;
;       DESCRIPTION:    Read eri register
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                       CX      Type
;
;                      
;       RETURNS:        EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEri	Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadEri
    jmp MemReadEri

ReadEri	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IoWriteEri
;
;       DESCRIPTION:    Write eri register
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                       ECX     Type & mask
;                       EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoWriteEri   Proc near
    mov dx,ds:IoBase
    add dx,REG_ERIDR
    out dx,eax
;    
    mov dx,ds:IoBase
    add dx,REG_ERIAR
    mov eax,ecx
    or ax,bx
    or eax,ERIAR_WRITE_CMD
    out dx,eax
;
    xor cx,cx

ioweWait:    
    pause
    in eax,dx
    test eax,80000000h
    jz ioweDone
;
    loop ioweWait

ioweDone:
    mov ax,1
    WaitMilliSec
    ret
IoWriteEri     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           MemWriteEri
;
;       DESCRIPTION:    Write eri register
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                       ECX     Type & mask
;                       EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemWriteEri   Proc near
    mov fs:mem_eridr,eax
;    
    mov eax,ecx
    or ax,bx
    or eax,ERIAR_WRITE_CMD
    mov fs:mem_eriar,eax
    out dx,eax
;
    xor cx,cx

mweWait:    
    pause
    mov eax,fs:mem_eriar
    test eax,80000000h
    jz mweDone
;
    loop mweWait

mweDone:
    mov ax,1
    WaitMilliSec
    ret
MemWriteEri     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           WriteEri
;
;       DESCRIPTION:    Write eri register
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                       ECX     Type & mask
;                       EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteEri   Proc near
    push ax
    mov ax,ds:MemSel
    or ax,ax
    pop ax
    jz IoWriteEri
    jmp MemWriteEri

WriteEri	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IoReadEfuse
;
;       DESCRIPTION:    Read efuse
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                      
;       RETURNS:        EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadEfuse   Proc near
    mov dx,ds:IoBase
    add dx,REG_EFUSE
    movzx eax,bx
    and eax,EFUSEAR_REG_MASK
    shl eax,EFUSEAR_REG_SHIFT
    out dx,eax
;
    mov ax,1
    WaitMilliSec
;    
    mov dx,ds:IoBase
    add dx,REG_EFUSE
    in eax,dx       
    and eax,EFUSEAR_DATA_MASK
    ret
IoReadEfuse     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           MemReadEfuse
;
;       DESCRIPTION:    Read efuse
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                      
;       RETURNS:        EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadEfuse   Proc near
    movzx eax,bx
    and eax,EFUSEAR_REG_MASK
    shl eax,EFUSEAR_REG_SHIFT
    mov fs:mem_efuse,eax
;
    mov ax,1
    WaitMilliSec
;    
    mov eax,fs:mem_efuse
    and eax,EFUSEAR_DATA_MASK
    ret
MemReadEfuse     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           ReadEfuse
;
;       DESCRIPTION:    Read efuse
;
;       PARAMETERS:     DS      Ether sel
;                       BX      Register #
;                      
;       RETURNS:        EAX     Value
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEfuse	Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadEfuse
    jmp MemReadEfuse

ReadEfuse	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoWriteByteReg
;
;           DESCRIPTION:    Write to reg, IO version
;
;           PARAMETERS:     DX      Register
;                           AL      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoWriteByteReg    Proc near
    push dx
;    
    add dx,ds:IoBase
    out dx,al
;    
    pop dx
    ret
IoWriteByteReg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemWriteByteReg
;
;           DESCRIPTION:    Write to reg, mem version
;
;           PARAMETERS:     FS      Registers
;                           DX      Register
;                           AL      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemWriteByteReg    Proc near
    push edx
;    
    movzx edx,dx
    mov fs:[edx],al
;    
    pop edx
    ret
MemWriteByteReg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WriteByteReg
;
;           DESCRIPTION:    Write to reg
;
;           PARAMETERS:     FS      Registers
;                           DX      Register
;                           AL      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteByteReg	Proc near
    push ax
    mov ax,ds:MemSel
    or ax,ax
    pop ax
    jz IoWriteByteReg
    jmp MemWriteByteReg

WriteByteReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoReadByteReg
;
;           DESCRIPTION:    Read from reg, IO version
;
;           PARAMETERS:     DX      Register
;
;           RETURNS:        AL      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadByteReg    Proc near
    push dx
;    
    add dx,ds:IoBase
    in al,dx
;    
    pop dx
    ret
IoReadByteReg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemReadByteReg
;
;           DESCRIPTION:    Read from reg, mem version
;
;           PARAMETERS:     FS      Registers
;                           DX      Register
;
;           RETURNS:        AL      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadByteReg    Proc near
    push edx
;    
    movzx edx,dx
    mov al,fs:[edx]
;    
    pop edx
    ret
MemReadByteReg    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadByteReg
;
;           DESCRIPTION:    Read from reg
;
;           PARAMETERS:     FS      Registers
;                           DX      Register
;
;           RETURNS:        AL      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadByteReg	Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadByteReg
    jmp MemReadByteReg

ReadByteReg	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           LockConf
;
;           DESCRIPTION:    Lock config registers
;
;           PARAMETERS:     DS      Registers
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LockConf	Proc near
    mov dx,REG_9346CR
    xor al,al
    call WriteByteReg
    ret
LockConf	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           UnlockConf
;
;           DESCRIPTION:    Unlock config registers
;
;           PARAMETERS:     DS      Registers
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UnlockConf	Proc near
    mov dx,REG_9346CR
    mov al,0Ch
    call WriteByteReg
    ret
UnlockConf	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           RunTableCommands
;
;       DESCRIPTION:    Run table commands
;
;       PARAMETERS:     DS      Ether sel
;                       CS:SI   Table
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RunTableCommands   Proc near

rtcLoop:
    mov ax,cs:[si]
    cmp ah,0
    je rtcWrite
;
    cmp ah,1
    je rtcPatch
;
    cmp ah,2
    je rtcMerge
;
    cmp ah,3
    je rtcProc
;
    cmp ah,4
    je rtcWait
;
    cmp ah,5
    je rtcEphy
;
    cmp ah,6
    je rtcSetEri
;
    cmp ah,7
    je rtcModifyEri
;
    cmp ah,8
    je rtcModifyConfig
;        
    jmp rtcDone

rtcWrite:
    mov dl,al
    mov ax,cs:[si+2]
    call ds:WritePhyProc
    add si,4
    jmp rtcLoop

rtcPatch:
    mov dl,al
    call ds:ReadPhyProc
    or ax,cs:[si+2]
    call ds:WritePhyProc
    add si,4
    jmp rtcLoop

rtcMerge:
    mov dl,al
    call ds:ReadPhyProc
    mov cx,cs:[si+4]
    not cx
    and ax,cx
    or ax,cs:[si+2]
    call ds:WritePhyProc
    add si,6
    jmp rtcLoop

rtcProc:
    call word ptr cs:[si+2]
    add si,4
    jmp rtcLoop

rtcWait:
    mov ax,cs:[si+2]
    WaitMilliSec
    add si,4
    jmp rtcLoop

rtcEphy:
    mov dl,al
    call ReadEphy 
    mov cx,cs:[si+2]
    not cx
    and ax,cx
    or ax,cs:[si+4]
    call WriteEphy
    add si,6
    jmp rtcLoop

rtcSetEri:
    mov bx,cs:[si+2]
    mov ecx,cs:[si+4]
    mov eax,cs:[si+8]
    call WriteEri
    add si,12
    jmp rtcLoop

rtcModifyEri:
    mov bx,cs:[si+2]
    call ReadEri
;
    mov ecx,cs:[si+4]
    not ecx
    and eax,ecx
    or eax,cs:[si+8]
    mov ecx,ERIAR_MASK_1111
    call WriteEri
    add si,12
    jmp rtcLoop

rtcModifyConfig:
    movzx dx,cs:[si]
    add dx,REG_CONFIG0
    call ReadByteReg
    mov ah,cs:[si+2]
    not ah
    and al,ah
    or al,cs:[si+3]
    call WriteByteReg
    add si,4
    jmp rtcLoop

rtcDone:
    ret
RunTableCommands  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:        ApplyFirmware
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ApplyFirmware	Proc near
    ret
ApplyFirmware   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:        CondD1Common
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CondD1Common  Proc near
    mov dl,0Dh
    call ds:ReadPhyProc
    cmp al,6Ch
    je cd1Done
;
    mov bh,ah
    mov al,65h
    mov ah,bh
    mov dl,0Dh
    call ds:WritePhyProc
;
    mov al,66h
    mov ah,bh
    mov dl,0Dh
    call ds:WritePhyProc
;
    mov al,67h
    mov ah,bh
    mov dl,0Dh
    call ds:WritePhyProc
;
    mov al,68h
    mov ah,bh
    mov dl,0Dh
    call ds:WritePhyProc
;
    mov al,69h
    mov ah,bh
    mov dl,0Dh
    call ds:WritePhyProc
;
    mov al,6Ah
    mov ah,bh
    mov dl,0Dh
    call ds:WritePhyProc
;
    mov al,6Bh
    mov ah,bh
    mov dl,0Dh
    call ds:WritePhyProc
;
    mov al,6Ch
    mov ah,bh
    mov dl,0Dh
    call ds:WritePhyProc

cd1Done:
    ret
CondD1Common  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:        Cond8168d1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

d_common:
  write_paged 2, 5, 669Ah
  8168d_param 08330h, 0FFFFh, 669Ah
  write 001Fh,  000002h
  call_proc CondD1Common
  DW -1

d1_def:
  write_paged 2, 5, 6662h
  8168d_param 08330h, 0FFFFh, 6662h
  DW -1

Cond8168d1	Proc near
    push si
;
    mov bx,1
    call ReadEfuse
    mov si,OFFSET d_common
    cmp al,0B1h
    je d1Do
;
    mov si,OFFSET d1_def

d1Do:
    call RunTableCommands
;
    pop si
    ret
Cond8168d1      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:        Cond8168d2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

d2_def:
  write_paged 2, 5, 2642h
  8168d_param 08330h, 0FFFFh, 2642h
  DW -1

Cond8168d2	Proc near
    push si
;
    mov bx,1
    call ReadEfuse
    mov si,OFFSET d_common
    cmp al,0B1h
    je d2Do
;
    mov si,OFFSET d2_def

d2Do:
    call RunTableCommands
;
    pop si
    ret
Cond8168d2      Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:        Cond8168g1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Cond8168g1	Proc near
    mov dl,1Fh
    mov ax,0A46h
    call ds:WritePhyProc
;
    mov dl,10h
    call ds:ReadPhyProc
;
    test ax,100h
    jz cg1Clear1

cg1Set1:
    mov dl,1Fh
    mov ax,0BCCh
    call ds:WritePhyProc
;
    mov dl,12h
    call ds:ReadPhyProc
;
    mov cx,8000h
    not cx
    and ax,cx
    call ds:WritePhyProc
    jmp cg1Next

cg1Clear1:
    mov dl,1Fh
    mov ax,0BCCh
    call ds:WritePhyProc
;
    mov dl,12h
    call ds:ReadPhyProc
;
    or ax,8000h
    call ds:WritePhyProc
    
cg1Next:
    mov dl,1Fh
    mov ax,0A46h
    call ds:WritePhyProc
;
    mov dl,13h
    call ds:ReadPhyProc
;
    test ax,100h
    jz cg1Clear2

cg1Set2:
    mov dl,1Fh
    mov ax,0C41h
    call ds:WritePhyProc
;
    mov dl,15h
    call ds:ReadPhyProc
;
    mov cx,2
    not cx
    and ax,cx
    call ds:WritePhyProc
    jmp cg1Done

cg1Clear2:
    mov dl,1Fh
    mov ax,0C41h
    call ds:WritePhyProc
;
    mov dl,15h
    call ds:ReadPhyProc
;
    or ax,2
    call ds:WritePhyProc

cg1Done:
    ret
Cond8168g1   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:        GetAdcBiasOffset
;
;       RETURNS:     AX Offset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAdcBiasOffset  Proc near
    mov dx,0DD02h
    mov ax,807Dh
    call WriteMac8169
;
    mov dx,0DD02h
    call ReadMac8169
    push ax
;
    mov dx,0DD00h
    call ReadMac8169
    mov dl,al
    shr ax,1
    and ax,7FF8h
    and dl,7
    or al,dl
;
    pop dx
    and dl,80h
    shl dx,8
    or ax,dx
;    
    ret
GetAdcBiasOffset  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:        Cond8168h2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Cond8168h2	Proc near
    call GetAdcBiasOffset
    or ax,ax
    je ch2Skip
;
    push ax
    mov dl,1Fh
    mov ax,0BCFh
    call ds:WritePhyProc
    pop ax
;
    mov dl,16h
    call ds:WritePhyProc

ch2Skip:
    mov dl,1Fh
    mov ax,0BCDh
    call ds:WritePhyProc
;
    mov dl,16h
    call ds:ReadPhyProc
    and ax,0Fh
;
    xor dx,dx
    cmp ax,3
    jbe ch2Low
;
    mov dx,ax
    sub dx,3

ch2Low:
    mov ax,dx
    shl dx,4
    or ax,dx
    shl dx,4
    or ax,dx
    shl edx,4
    or ax,dx
;
    push ax
    mov dl,1Fh
    mov ax,0BCDh
    call ds:WritePhyProc
    pop ax
;
    mov dl,17h
    call ds:WritePhyProc
    ret
Cond8168h2	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:          Config8169
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConfigNone:
  DW -1

Config8169s:
  DW 01Fh,  00001h
  DW 006h,  0006Eh 
  DW 008h,  00708h
  DW 015h,  04000h
  DW 018h,  065C7h

  DW 01Fh,  00001h
  DW 003h,  000A1h
  DW 002h,  00008h
  DW 001h,  00120h
  DW 000h,  01000h
  DW 004h,  00800h
  DW 004h,  00000h

  DW 003h,  0FF41h
  DW 002h,  0DF60h
  DW 001h,  00140h
  DW 000h,  00077h
  DW 004h,  07800h
  DW 004h,  07000h

  DW 003h,  0802Fh
  DW 002h,  04F02h
  DW 001h,  00409h
  DW 000h,  0F0F9h
  DW 004h,  09800h
  DW 004h,  09000h

  DW 003h,  0DF01h
  DW 002h,  0DF20h
  DW 001h,  0FF95h
  DW 000h,  0BA00h
  DW 004h,  0A800h
  DW 004h,  0A000h

  DW 003h,  0FF41h
  DW 002h,  0DF20h
  DW 001h,  00140h
  DW 000h,  000BBh
  DW 004h,  0B800h
  DW 004h,  0B000h

  DW 003h,  0DF41h
  DW 002h,  0DC60h
  DW 001h,  06340h
  DW 000h,  0007Dh
  DW 004h,  0D800h
  DW 004h,  0D000h

  DW 003h,  0DF01h
  DW 002h,  0DF20h
  DW 001h,  0100Ah
  DW 000h,  0A0FFh
  DW 004h,  0F800h
  DW 004h,  0F000h

  DW 01Fh,  00000h
  DW 00Bh,  00000h
  DW 000h,  09200h
  DW -1

Config8169sb:
  write_paged 2, 1, 90D0h
  DW -1
        
Config8169scd:
  DW 01Fh,  00001h
  DW 004h,  00000h

  DW 003h,  000A1h
  DW 002h,  00008h
  DW 001h,  00120h
  DW 000h,  01000h
  DW 004h,  00800h
  DW 004h,  09000h

  DW 003h,  0802Fh
  DW 002h,  04F02h
  DW 001h,  00409h
  DW 000h,  0F099h
  DW 004h,  09800h
  DW 004h,  0A000h

  DW 003h,  0DF01h
  DW 002h,  0DF20h
  DW 001h,  0FF95h
  DW 000h,  0BA00h
  DW 004h,  0A800h
  DW 004h,  0F000h

  DW 003h,  0DF01h
  DW 002h,  0DF20h
  DW 001h,  0101Ah
  DW 000h,  0A0FFh
  DW 004h,  0F800h
  DW 004h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00001h
  DW 010h,  0F41Bh
  DW 014h,  0FB54h
  DW 018h,  0F5C7h
  DW 01Fh,  00000h

  DW 01Fh,  00001h
  DW 017h,  00CC0h
  DW 01Fh,  00000h
  DW -1
      
Config8169sce:
  DW 01Fh,  00001h
  DW 004h,  00000h

  DW 003h,  000A1h
  DW 002h,  00008h
  DW 001h,  00120h
  DW 000h,  01000h
  DW 004h,  00800h
  DW 004h,  09000h

  DW 003h,  0802Fh
  DW 002h,  04F02h
  DW 001h,  00409h
  DW 000h,  0F099h
  DW 004h,  09800h
  DW 004h,  0A000h

  DW 003h,  0DF01h
  DW 002h,  0DF20h
  DW 001h,  0FF95h
  DW 000h,  0BA00h
  DW 004h,  0A800h
  DW 004h,  0F000h

  DW 003h,  0DF01h
  DW 002h,  0DF20h
  DW 001h,  0101Ah
  DW 000h,  0A0FFh
  DW 004h,  0F800h
  DW 004h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00001h
  DW 00Bh,  08480h
  DW 01Fh,  00000h

  DW 01Fh,  00001h
  DW 018h,  067C7h
  DW 004h,  02000h
  DW 003h,  0002Fh
  DW 002h,  04360h
  DW 001h,  00109h
  DW 000h,  03022h
  DW 004h,  02800h
  DW 01Fh,  00000h

  DW 01Fh,  00001h
  DW 017h,  00CC0h
  DW 01Fh,  00000h
  DW -1

Config8168bb:
  Write 01Fh, 1
  set_bits 16h, 1
  write 10h, 0F41Bh
  write 01Fh, 0
  DW -1

Config8168bef:  
  write_paged 1, 10h, 0F41Bh
  DW -1
  
Config8168cp1: 
  write 01Dh, 00F00h
  write_paged 2, 0Ch, 1EC8h
  DW -1
  
Config8168cp2: 
  set_bits 14h, 20h
  set_bits 0Dh, 20h
  write_paged 1, 1Dh, 3D98h
  DW -1
   
  
Config8168c1: 
  write 01Fh,  00001h
  write 012h,  02300h
  write 01Fh,  00002h
  write 000h,  088D4h
  write 001h,  082B1h
  write 003h,  07002h
  write 008h,  09E30h
  write 009h,  001F0h
  write 00Ah,  05500h
  write 00Ch,  000C8h
  write 01Fh,  00003h
  write 012h,  0C096h
  write 016h,  0000Ah
  write 01Fh,  00000h
  write 01Fh,  00000h
  write 009h,  02000h
  write 009h,  00000h  
  set_bits 14h, 20h
  set_bits 0Dh, 20h
  DW -1
  
Config8168c2: 
  write 01Fh,  00001h
  write 012h,  02300h
  write 003h,  0802Fh
  write 002h,  04F02h
  write 001h,  00409h
  write 000h,  0F099h
  write 004h,  09800h
  write 004h,  09000h
  write 01Dh,  03D98h
  write 01Fh,  00002h
  write 00Ch,  07EB8h
  write 006h,  00761h
  write 01Fh,  00003h
  write 016h,  00F0Ah
  write 01Fh,  00000h
  set_bits 16h, 1
  set_bits 14h, 20h
  set_bits 0Dh, 20h
  DW -1
     
Config8168c3: 
  write 01Fh,  00001h
  write 012h,  02300h
  write 01Dh,  03D98h
  write 01Fh,  00002h
  write 00Ch,  07EB8h
  write 006h,  05461h
  write 01Fh,  00003h
  write 016h,  00F0Ah
  write 01Fh,  00000h
  set_bits 16h, 1
  set_bits 14h, 20h
  set_bits 0Dh, 20h
  DW -1

Config8168d1: 
  conf_8168d

  write 01Fh,  00002h
  modify 0Bh, 0EFh, 10h
  modify 0Ch, 05D00h, 0A200h

  call_proc Cond8168d1

  write 01Fh,  00002h
  set_bits 0Dh, 300h
  set_bits 0Fh, 10h

  write 01Fh,  00002h
  modify 2, 600h, 100h
  clear_bits 3, 0E000h
  write 01Fh,  00000h

  apply_firmware_cond 0BF00h
  DW -1

Config8168d2: 
  conf_8168d

  call_proc Cond8168d2

  write 01Fh,  00002h
  modify 2, 600h, 100h
  clear_bits 3, 0E000h
  write 01Fh,  00000h

  modify_paged 2, 0Fh, 0, 17h
  apply_firmware_cond 0B300h
  DW -1

Config8168d4:
  write_paged 1, 17h, 0CC0h
  modify_extpage 2Dh, 18h, 0FFFFh, 40h
  set_bits 0Dh, 20h
  DW -1 

Config8168e1:
  call_proc ApplyFirmware
  8168d_param 08B80h, 0FFFFh, 0C896h

  write 01Fh,  00001h
  write 00Bh,  06C20h
  write 007h,  02872h
  write 01Ch,  0EFFFh
  write 01Fh,  00003h
  write 014h,  06420h
  write 01Fh,  00000h

  modify_extpage 2Fh, 15h, 0FFFFh, 1919h
  modify_extpage 0ACh, 18h, 0FFFFh, 6
  modify_extpage 23h, 17h, 0, 6
  modify_paged 2, 8, 7F00h, 8000h
  modify_extpage 2Dh, 18h, 0, 50h
  set_bits 14h, 8000h
  8168d_param 8B86h, 0, 1
  8168d_param 8B85h, 2000h, 0
  modify_extpage 20h, 15h, 1100h, 0
  write_paged 6, 0, 5A00h
  write_mmd 7, 60, 0
  DW -1

Config8168e2:
  call_proc ApplyFirmware
  modify_extpage 0ACh, 18h, 0FFFFh, 6
  write_paged 3, 9, 0A20Fh
  8168d_param 08B5Bh, 0FFFFh, 09222h
  8168d_param 08B6Dh, 0FFFFh, 08000h
  8168d_param 08B76h, 0FFFFh, 08000h

  write 01Fh,  00005h
  write 005h,  08B80h
  set_bits 17h, 6
  write 01Fh,  00000h

  modify_extpage 2Dh, 18h, 0, 10h
  set_bits 14h, 8000h

  8168d_param 08B86h, 0, 1
  8168d_param 08B85h, 0, 4000h
  ee_8168f

  write 01Fh,  00003h
  set_bits 19h, 1
  set_bits 10h, 400h
  write 01Fh,  00000h
  modify_paged 5, 1, 0, 100h
  DW -1
  
Config8168f1:
  call_proc ApplyFirmware
  write_paged 3, 9, 0A20Fh

  8168d_param 08B55h, 0FFFFh, 0
  8168d_param 08B5Eh, 0FFFFh, 0
  8168d_param 08B67h, 0FFFFh, 0
  8168d_param 08B70h, 0FFFFh, 0

  modify_extpage 78h, 17h, 0FFFFh, 0
  modify_extpage 78h, 19h, 0FFFFh, 0FBh

  8168d_param 08B79h, 0FFFFh, 0AA00h
  write_paged 3, 1, 328Ah

  conf_8168f

  8168d_param 08B85h, 0, 4000h
  DW -1

Config8168f2:
  call_proc ApplyFirmware
  conf_8168f
  DW -1
	  
Config8411:
  call_proc ApplyFirmware
  conf_8168f

  8168d_param 08B85h, 0, 4000h
  write_paged 3, 9, 0A20Fh

  8168d_param 08B55h, 0FFFFh, 0
  8168d_param 08B5Eh, 0FFFFh, 0
  8168d_param 08B67h, 0FFFFh, 0
  8168d_param 08B70h, 0FFFFh, 0

  modify_extpage 78h, 17h, 0FFFFh, 0
  modify_extpage 78h, 19h, 0FFFFh, 0AAh

  8168d_param 08B79h, 0FFFFh, 0AA00h
  write_paged 3, 1, 328Ah

  8168d_param 08B54h, 800h, 0
  8168d_param 08B5Dh, 800h, 0
  8168d_param 08A7Ch, 100h, 0
  8168d_param 08A7Fh, 0, 100h
  8168d_param 08A82h, 100h, 0
  8168d_param 08A85h, 100h, 0
  8168d_param 08A88h, 100h, 0

  8168d_param 08B85h, 0, 8000h

  write 01Fh,  00003h
  clear_bits 19h, 1
  clear_bits 10h, 400h
  write 01Fh,  00000h 
  DW -1
   
Config8168g1:
  call_proc ApplyFirmware
  call_proc Cond8168g1

  modify_paged 0A4Bh, 11h, 0, 4

  8168g_param 8012h, 0, 8000h
  modify_paged 0C42h, 11h, 2000h, 4000h
  
  write 01Fh,  0BCDh
  write 014h,  05065h
  write 014h,  0D065h

  write 01Fh,  00BC8h
  write 011h,  05655h

  write 01Fh,  00BCDh
  write 014h,  01065h
  write 014h,  09065h
  write 014h,  01065h
  write 01Fh,  00000h

  ee_8168g
  DW -1
    
Config8168g2:
  call_proc ApplyFirmware
  ee_8168g
  DW -1
  
Config8168h2:
  call_proc ApplyFirmware

  8168g_param 808Ah, 3Fh, 0Ah
  8168g_param 811h, 0, 800h
  modify_paged 0A42h, 16h, 0, 2

  call_proc Cond8168h2

  modify_paged 0A44h, 11h, 80h, 0
  ee_8168g
  DW -1

Config8168ep2:
  modify_paged 0C42h, 11h, 2000h, 4000h

  8168g_param 80F3h, 0FF00h, 8B00h
  8168g_param 80F0h, 0FF00h, 3A00h
  8168g_param 80EFh, 0FF00h, 500h
  8168g_param 80F6h, 0FF00h, 6E00h
  8168g_param 80ECh, 0FF00h, 6800h
  8168g_param 80EDh, 0FF00h, 7C00h
  8168g_param 80F2h, 0FF00h, 0F400h
  8168g_param 80F4h, 0FF00h, 8500h
  8168g_param 8110h, 0FF00h, 0A800h
  8168g_param 810Fh, 0FF00h, 1D00h
  8168g_param 8111h, 0FF00h, 0F500h
  8168g_param 8113h, 0FF00h, 6100h
  8168g_param 8115h, 0FF00h, 9200h
  8168g_param 810Eh, 0FF00h, 400h
  8168g_param 810Ch, 0FF00h, 7C00h
  8168g_param 810Bh, 0FF00h, 5A00h
  8168g_param 80D1h, 0FF00h, 0FF00h
  8168g_param 80CDh, 0FF00h, 9E00h
  8168g_param 80D3h, 0FF00h, 0E00h
  8168g_param 80D5h, 0FF00h, 0CA00h
  8168g_param 80D7h, 0FF00h, 8400h

  write 01Fh,  00BCDh
  write 014h,  05065h
  write 014h,  0D065h
  write 01Fh,  00BC8h
  write 012h,  000EDh
  write 01Fh,  00BCDh
  write 014h,  01065h
  write 014h,  09065h
  write 014h,  01065h
  write 01Fh,  00000h

  ee_8168g
  DW -1

Config8117:
  8168g_param 808Eh, 0FF00h, 4800h
  8168g_param 8090h, 0FF00h, 0CC00h
  8168g_param 8092h, 0FF00h, 0B000h

  8168g_param 8088h, 0FF00h, 6000h
  8168g_param 808Bh, 03F00h, 0B000h
  8168g_param 808Dh, 01F00h, 600h
  8168g_param 808Ch, 0FF00h, 0B000h
  8168g_param 80A0h, 0FF00h, 2800h
  8168g_param 80A2h, 0FF00h, 5000h
  8168g_param 809Bh, 0F800h, 0B000h
  8168g_param 809Ah, 0FF00h, 4B00h
  8168g_param 809Dh, 03F00h, 800h
  8168g_param 80A1h, 0FF00h, 7000h
  8168g_param 809Fh, 01F00h, 300h
  8168g_param 809Eh, 0FF00h, 8800h
  8168g_param 80B2h, 0FF00h, 2200h
  8168g_param 80ADh, 0F800h, 9800h
  8168g_param 80AFh, 03F00h, 800h
  8168g_param 80B3h, 0FF00h, 6F00h
  8168g_param 80B1h, 01F00h, 300h
  8168g_param 80B0h, 0FF00h, 9300h

  8168g_param 8011h, 0, 800h
  8168g_param 8016h, 0, 400h

  ee_8168g
  DW -1
  
Config8102e:
  set_bits 11h, 1000h
  set_bits 19h, 2000h
  set_bits 10h, 8000h

  write 01Fh,  00003h
  write 008h,  0441Dh
  write 001h,  09100h
  write 01Fh,  00000h
  DW -1

Config8401:
  set_bits 11h, 1000h
  modify_paged 2, 0Fh, 0, 3
  DW -1

Config8105e:
  call_proc ApplyFirmware

  write_paged 5, 1Ah, 0
  write_paged 4, 1Ch, 0
  write_paged 1, 15h, 7701h
  DW -1

Config8402:
  call_proc ApplyFirmware

  write 01Fh,  00004h
  write 010h,  0401Fh
  write 019h,  07030h
  write 01Fh,  00000h
  DW -1

Config8106e:
  call_proc ApplyFirmware

  write 01Fh,  00004h
  write 010h,  0C07Fh
  write 019h,  07030h
  write 01Fh,  00000h
  DW -1

Config8125:
  modify_paged 5ABh, 12h, 8000h, 0
  DW -1

Config8125a2:
  modify_paged 0AD4h, 17h, 0, 10h
  modify_paged 0AD1h, 13h, 3FFh, 3FFh
  modify_paged 0AD3h, 11h, 3Fh, 6
  modify_paged 0AC0h, 14h, 1100h, 0
  modify_paged 0ACCh, 10h, 3, 2
  modify_paged 0AD4h, 10h, 0E7h, 44h
  modify_paged 0AC1h, 12h, 80h, 0
  modify_paged 0AC8h, 10h, 300h, 0
  modify_paged 0AC5h, 17h, 7, 2
  write_paged 0AD4h, 16h, 0A8h
  write_paged 0AC5h, 16h, 1FFh
  modify_paged 0AC8h, 15h, 0F0h, 30h

  write 01Fh,  00B87h
  write 016h,  080A2h
  write 017h,  00153h
  write 016h,  0809Ch
  write 017h,  00153h
  write 01Fh,  00000h

  write 01Fh,  00A43h
  write 013h,  0B1B3h
  write 014h,  00043h
  write 014h,  000A7h
  write 014h,  000D6h
  write 014h,  000ECh
  write 014h,  000F6h
  write 014h,  000FBh
  write 014h,  000FDh
  write 014h,  000FFh
  write 014h,  000BBh
  write 014h,  00058h
  write 014h,  00029h
  write 014h,  00013h
  write 014h,  00009h
  write 014h,  00004h
  write 014h,  00002h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 014h,  00000h
  write 01Fh,  00000h

  8168g_param 8257h, 0FFFFh, 20Fh
  8168g_param 80EAh, 0FFFFh, 7843h
  call_proc ApplyFirmware

  modify_paged 0D06h, 14h, 0, 2000h
  8168g_param 81A2h, 0, 100h

  modify_paged 0B54h, 16h, 0FF00h, 0DB00h
  modify_paged 0A45h, 12h, 1, 0
  modify_paged 0A5Dh, 12h, 0, 20h
  modify_paged 0AD4h, 17h, 10h, 0
  modify_paged 0A86h, 15h, 1, 0

  ee_8168g
  DW -1

Config8125b:
  call_proc ApplyFirmware

  modify_paged 0A44h, 11h, 0, 800h
  modify_paged 0AC4h, 13h, 0F0h, 90h
  modify_paged 0AD3h, 10h, 3, 1

  write 01Fh,  00B87h
  write 016h,  080F5h
  write 017h,  0760Eh
  write 016h,  08107h
  write 017h,  0360Eh
  write 016h,  08551h
  modify 17h, 0FF00h, 800h
  write 01Fh,  00000h

  modify_paged 0BF0h, 10h, 0E000h, 0A000h
  modify_paged 0BF4h, 13h, 0F00h, 300h

  8168g_param 8044h, 0FFFFh, 2417h
  8168g_param 804Ah, 0FFFFh, 2417h
  8168g_param 8050h, 0FFFFh, 2417h
  8168g_param 8056h, 0FFFFh, 2417h
  8168g_param 805Ch, 0FFFFh, 2417h
  8168g_param 8062h, 0FFFFh, 2417h
  8168g_param 8068h, 0FFFFh, 2417h
  8168g_param 806Eh, 0FFFFh, 2417h
  8168g_param 8074h, 0FFFFh, 2417h
  8168g_param 807Ah, 0FFFFh, 2417h

  modify_paged 0A4Ch, 15h, 0, 40h
  modify_paged 0BF8h, 12h, 0E000h, 0A000h
  8125_legacy
  ee_8168g
  DW -1

ConfigTab:
ct00 DW OFFSET ConfigNone
ct01 DW OFFSET ConfigNone
ct02 DW OFFSET Config8169s
ct03 DW OFFSET Config8169s
ct04 DW OFFSET Config8169sb
ct05 DW OFFSET Config8169scd
ct06 DW OFFSET Config8169sce
ct07 DW OFFSET Config8102e
ct08 DW OFFSET Config8102e
ct09 DW OFFSET Config8102e
ct10 DW OFFSET ConfigNone
ct11 DW OFFSET Config8168bb
ct12 DW OFFSET ConfigNone
ct13 DW OFFSET ConfigNone
ct14 DW OFFSET Config8401
ct15 DW OFFSET ConfigNone
ct16 DW OFFSET ConfigNone
ct17 DW OFFSET Config8168bef
ct18 DW OFFSET Config8168cp1
ct19 DW OFFSET Config8168c1
ct20 DW OFFSET Config8168c2
ct21 DW OFFSET Config8168c3
ct22 DW OFFSET Config8168c3
ct23 DW OFFSET Config8168cp2
ct24 DW OFFSET Config8168cp2
ct25 DW OFFSET Config8168d1
ct26 DW OFFSET Config8168d2
ct27 DW OFFSET ConfigNone
ct28 DW OFFSET Config8168d4
ct29 DW OFFSET Config8105e
ct30 DW OFFSET Config8105e
ct31 DW OFFSET ConfigNone
ct32 DW OFFSET Config8168e1
ct33 DW OFFSET Config8168e1
ct34 DW OFFSET Config8168e2
ct35 DW OFFSET Config8168f1
ct36 DW OFFSET Config8168f2
ct37 DW OFFSET Config8402
ct38 DW OFFSET Config8411
ct39 DW OFFSET Config8106e
ct40 DW OFFSET Config8168g1
ct41 DW OFFSET ConfigNone
ct42 DW OFFSET Config8168g2
ct43 DW OFFSET Config8168g2
ct44 DW OFFSET Config8168g2
ct45 DW OFFSET ConfigNone
ct46 DW OFFSET Config8168h2
ct47 DW OFFSET ConfigNone
ct48 DW OFFSET Config8168h2
ct49 DW OFFSET ConfigNone
ct50 DW OFFSET ConfigNone
ct51 DW OFFSET Config8168ep2
ct52 DW OFFSET Config8117
ct53 DW OFFSET Config8117
ct54 DW OFFSET ConfigNone
ct55 DW OFFSET ConfigNone
ct56 DW OFFSET ConfigNone
ct57 DW OFFSET ConfigNone
ct58 DW OFFSET ConfigNone
ct59 DW OFFSET ConfigNone
ct60 DW OFFSET ConfigNone
ct61 DW OFFSET Config8125a2
ct62 DW OFFSET ConfigNone
ct63 DW OFFSET Config8125b

Config  Proc near
    mov si,ds:HwId
    add si,si
    mov si,cs:[si].ConfigTab
    call RunTableCommands
;
    call LockConf
    ret
Config  Endp            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:          Start8169
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartNone:
  DW -1

Start8168b:
  modify_config 4, 0, 1
  modify_config 3, 0, 1
  DW -1

Start8168cp1:
  ephy_init 1,   00000h, 00001h
  ephy_init 2,   00800h, 01000h
  ephy_init 3,   00000h, 00042h
  ephy_init 6,   00080h, 00000h
  ephy_init 7,   00000h, 02000h

  modify_config 1, 10h, 0
  modify_config 3, 0, 1

  modify_config 3, 0, 4
  modify_config 4, 0, 2
  DW -1

Start8168cp2:
  modify_config 3, 0, 1

  modify_config 3, 0, 4
  modify_config 4, 0, 2
  DW -1

Start8168cp3:
  modify_config 3, 0, 1

  modify_config 3, 0, 4
  modify_config 4, 0, 2
  DW -1

Start8168c1:
  ephy_init 2,   00800h, 01000h
  ephy_init 3,   00000h, 00002h
  ephy_init 6,   00080h, 00000h

  modify_config 1, 10h, 0
  modify_config 3, 0, 1

  modify_config 3, 0, 4
  modify_config 4, 0, 2
  DW -1

Start8168c2:
  ephy_init 1,   00000h, 00001h
  ephy_init 3,   00400h, 00020h

  modify_config 1, 10h, 0
  modify_config 3, 0, 1

  modify_config 3, 0, 4
  modify_config 4, 0, 2
  DW -1

Start8168c4:
  modify_config 1, 10h, 0
  modify_config 3, 0, 1

  modify_config 3, 0, 4
  modify_config 4, 0, 2
  DW -1

Start8168d:
  modify_config 3, 0, 4
  modify_config 4, 0, 2
  DW -1

Start8168d4:
  ephy_init 0Bh, 00000h, 00048h
  ephy_init 19h, 00020h, 00050h
  ephy_init 0Ch, 00100h, 00020h
  ephy_init 10h, 00004h, 00000h
  modify_config 3, 0, 4
  DW -1

Start8168e1:
  ephy_init 0,   00200h, 00100h
  ephy_init 0,   00000h, 00004h
  ephy_init 6,   00002h, 00001h
  ephy_init 6,   00000h, 00030h
  ephy_init 7,   00000h, 02000h
  ephy_init 0,   00000h, 00020h
  ephy_init 3,   05800h, 02000h
  ephy_init 3,   00000h, 00001h
  ephy_init 1,   00800h, 01000h
  ephy_init 7,   00000h, 04000h
  ephy_init 1Eh, 00000h, 02000h
  ephy_init 19h, 0FFFFh, 0FE6ch
  ephy_init 0Ah, 00000h, 00040h

  modify_config 5, 0, 8
  modify_config 1, 0DCh, 3
  modify_config 3, 0, 1
  DW -1

Start8168e2:
  disable_aspm
  ephy_init 9,   00000h, 00080h
  ephy_init 19h, 00000h, 00224h
  ephy_init 0,   00000h, 00004h
  ephy_init 0Ch, 03DF0h, 00200h

  write_eri 0C0h, ERIAR_MASK_0011, 00000h
  write_eri 0B8h, ERIAR_MASK_1111, 00000h
  set_fifo_size
  set_eri_bits 01D0h, 2
  reset_packet_filter
  set_eri_bits 01B0h, 10h
  write_eri 0CCh, ERIAR_MASK_1111, 000000050h
  write_eri 0D0h, ERIAR_MASK_1111, 007FF0060h

  modify_config 5, 0, 8
  modify_config 1, 0Ch, 3
  modify_config 3, 0, 1
  DW -1

Start8168f1:
  start_8168f

  ephy_init 6,   000C0h, 00020h
  ephy_init 8,   00001h, 00002h
  ephy_init 9,   00000h, 00080h
  ephy_init 19h, 00000h, 00224h
  ephy_init 0,   00000h, 00008h
  ephy_init 0Ch, 03DF0h, 00200h

  modify_config 5, 0, 8
  DW -1

Start8411:
  start_8168f

  ephy_init 6,   000C0h, 00020h
  ephy_init 0Fh, 0FFFFh, 05200h
  ephy_init 19h, 00000h, 00224h
  ephy_init 0,   00000h, 00008h
  ephy_init 0Ch, 03DF0h, 00200h

  modify_config 5, 0, 8
  DW -1

Start8168g1:
  start_8168g
  disable_aspm

  ephy_init 0,   00008h, 00000h
  ephy_init 0Ch, 03FF0h, 00820h
  ephy_init 1Eh, 00000h, 00001h
  ephy_init 19h, 08000h, 00000h
  DW -1

Start8168g2:
  start_8168g
  disable_aspm

  ephy_init 0,   00008h, 00000h
  ephy_init 0Ch, 0x3FF0h, 00820h
  ephy_init 19h, 0FFFFh, 07C00h
  ephy_init 1Eh, 0FFFFh, 020EBh
  ephy_init 0Dh, 0FFFFh, 01666h
  ephy_init 0,   0FFFFh, 010A3h
  ephy_init 6,   0FFFFh, 0F050h
  ephy_init 4,   00000h, 00010h
  ephy_init 1Dh, 04000h, 00000h
  DW -1

Start8411_2:
  start_8168g
  disable_aspm

  ephy_init 0,   00008h, 00000h
  ephy_init 0Ch, 037D0h, 00820h
  ephy_init 1Eh, 00000h, 00001h
  ephy_init 19h, 08021h, 00000h
  ephy_init 1Eh, 00000h, 02000h
  ephy_init 0Dh, 00100h, 00200h
  ephy_init 0,   00000h, 00080h
  ephy_init 6,   00000h, 00010h
  ephy_init 4,   00000h, 00010h
  ephy_init 1Dh, 00000h, 04000h
  DW -1

Start8168h1:
  disable_aspm
  ephy_init 1Eh, 00800h, 00001h
  ephy_init 1Dh, 00000h, 00800h
  ephy_init 5,   0FFFFh, 02089h
  ephy_init 6,   0FFFFh, 05881h
  ephy_init 4,   0FFFFh, 0854Ah
  ephy_init 1,   0FFFFH, 0068bh

  set_fifo_size
  reset_packet_filter
  set_eri_bits 0DCh, 0001Ch
  write_eri 05F0h, ERIAR_MASK_0011, 04F87h
  write_eri 0C0h, ERIAR_MASK_0011, 00000h
  write_eri 0B8h, ERIAR_MASK_0011, 00000h
  clear_eri_bits 01B0h, 1000h
  DW -1

Start8168ep3:
  disable_aspm
  ephy_init 0,   00000h, 00080h
  ephy_init 0Dh, 00100h, 00200h
  ephy_init 19h, 08021h, 00000h
  ephy_init 1Eh, 00000h, 02000h

  start_8168ep
  DW -1

Start8117:
  disable_aspm
  ephy_init 19h, 00040h, 01100h
  ephy_init 59h, 00040h, 01100h

  set_fifo_size
  reset_packet_filter
  set_eri_bits 0D4h, 00010h
  write_eri 05F0h, ERIAR_MASK_0011, 04F87h
  write_eri 0C0h, ERIAR_MASK_0011, 00000h
  write_eri 0B8h, ERIAR_MASK_0011, 00000h
  clear_eri_bits 01B0h, 1000h
  DW -1

Start8102e1:
  ephy_init 1,   00000h, 06E65h
  ephy_init 2,   00000h, 0091Fh
  ephy_init 3,   00000h, 0C2F9h
  ephy_init 6,   00000h, 0AFB5h
  ephy_init 7,   00000h, 00E00h
  ephy_init 19h, 00000h, 0EC80h
  ephy_init 1,   00000h, 02E65h
  ephy_init 1,   00000h, 06E65h
  modify_config 3, 0, 4
  modify_config 4, 0, 1
  DW -1

Start8102e2:
  modify_config 3, 0, 4
  modify_config 4, 0, 1
  DW -1

Start8102e3:
  ephy_init 3,   0FFFFh, 0C2F9h
  Dw -1

Start8401:
  ephy_init 1,   0FFFFh, 06FE5h
  ephy_init 3,   0FFFFh, 00599h
  ephy_init 6,   0FFFFh, 0AF25h
  ephy_init 7,   0FFFFh, 08E68h
  modify_config 3, 0, 1
  DW -1

Start8105e1:
  ephy_init 7,   00000h, 04000h
  ephy_init 19h, 00000h, 00200h
  ephy_init 19h, 00000h, 00020h
  ephy_init 1Eh, 00000h, 02000h
  ephy_init 3,   00000h, 00001h
  ephy_init 19h, 00000h, 00100h
  ephy_init 19h, 00000h, 00004h
  ephy_init 0Ah, 00000h, 00020h
  DW -1

Start8105e2:
  ephy_init 7,   00000h, 04000h
  ephy_init 19h, 00000h, 00200h
  ephy_init 19h, 00000h, 00020h
  ephy_init 1Eh, 00000h, 02000h
  ephy_init 3,   00000h, 00001h
  ephy_init 19h, 00000h, 00100h
  ephy_init 19h, 00000h, 00004h
  ephy_init 0Ah, 00000h, 00020h
  ephy_init 1Eh, 0FFFFh, 08000h
  DW -1

Start8402:
  ephy_init 19h, 0FFFFh, 0FF64h
  ephy_init 1Eh, 00000h, 04000h

  set_fifo_size
  reset_packet_filter

  write_eri 0C0h, ERIAR_MASK_0011, 00000h
  write_eri 0B8h, ERIAR_MASK_0011, 00000h
  modify_eri 0D4h, 0E00h, 0FF00h
  write_eri 01B0h, ERIAR_MASK_0011, 00000h
  DW -1

Start8106:
  disable_aspm
  write_eri 01D0h, ERIAR_MASK_0011, 00000h
  write_eri 01B0h, ERIAR_MASK_0011, 00000h
  DW -1

Start8125a2:
  disable_aspm
  ephy_init 4,   0FFFFh, 0D000h
  ephy_init 0Ah, 0FFFFh, 08653h
  ephy_init 23h, 0FFFFh, 0AB66h
  ephy_init 20h, 0FFFFh, 09455h
  ephy_init 21h, 0FFFFh, 099FFh
  ephy_init 29h, 0FFFFh, 0FE04h
  ephy_init 44h, 0FFFFh, 0D000h
  ephy_init 4Ah, 0FFFFh, 08653h
  ephy_init 63h, 0FFFFh, 0AB66h
  ephy_init 60h, 0FFFFH, 09455h
  ephy_init 61h, 0FFFFh, 099FFh
  ephy_init 69h, 0FFFFh, 0FE04h

  modify_config 1, 0, 10h
  DW -1

Start8125b:
  disable_aspm
  ephy_init 0Bh, 0FFFFh, 0A908h
  ephy_init 1Eh, 0FFFFh, 020EBh
  ephy_init 4Bh, 0FFFFh, 0A908h
  ephy_init 5Eh, 0FFFFh, 020EBh
  ephy_init 22h, 00030h, 00020h
  ephy_init 62h, 00030h, 00020h

  modify_config 1, 0, 10h
  DW -1

StartTab:
st00 DW OFFSET StartNone
st01 DW OFFSET StartNone
st02 DW OFFSET StartNone
st03 DW OFFSET StartNone
st04 DW OFFSET StartNone
st05 DW OFFSET StartNone
st06 DW OFFSET StartNone
st07 DW OFFSET Start8102e1
st08 DW OFFSET Start8102e3
st09 DW OFFSET Start8102e2
st10 DW OFFSET StartNone
st11 DW OFFSET Start8168b
st12 DW OFFSET StartNone
st13 DW OFFSET StartNone
st14 DW OFFSET Start8401
st15 DW OFFSET StartNone
st16 DW OFFSET StartNone
st17 DW OFFSET Start8168b
st18 DW OFFSET Start8168cp1
st19 DW OFFSET Start8168c1
st20 DW OFFSET Start8168c2
st21 DW OFFSET Start8168c2
st22 DW OFFSET Start8168c4
st23 DW OFFSET Start8168cp2
st24 DW OFFSET Start8168cp3
st25 DW OFFSET Start8168d
st26 DW OFFSET Start8168d
st27 DW OFFSET StartNone
st28 DW OFFSET Start8168d4
st29 DW OFFSET Start8105e1
st30 DW OFFSET Start8105e2
st31 DW OFFSET Start8168d
st32 DW OFFSET Start8168e1
st33 DW OFFSET Start8168e1
st34 DW OFFSET Start8168e2
st35 DW OFFSET Start8168f1
st36 DW OFFSET Start8168f1
st37 DW OFFSET Start8402
st38 DW OFFSET Start8411
st39 DW OFFSET Start8106
st40 DW OFFSET Start8168g1
st41 DW OFFSET StartNone
st42 DW OFFSET Start8168g2
st43 DW OFFSET Start8168g2
st44 DW OFFSET Start8411_2
st45 DW OFFSET StartNone
st46 DW OFFSET Start8168h1
st47 DW OFFSET StartNone
st48 DW OFFSET Start8168h1
st49 DW OFFSET StartNone
st50 DW OFFSET StartNone
st51 DW OFFSET Start8168ep3
st52 DW OFFSET Start8117
st53 DW OFFSET Start8117
st54 DW OFFSET StartNone
st55 DW OFFSET StartNone
st56 DW OFFSET StartNone
st57 DW OFFSET StartNone
st58 DW OFFSET StartNone
st59 DW OFFSET StartNone
st60 DW OFFSET StartNone
st61 DW OFFSET Start8125a2
st62 DW OFFSET StartNone
st63 DW OFFSET Start8125b

StartHw  Proc near
    mov si,ds:HwId
    add si,si
    mov si,cs:[si].StartTab
    call RunTableCommands
    ret
StartHw  Endp            
          
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IoInitHardware
;
;       DESCRIPTION:    Initialize hardware
;
;       PARAMETERS:         BH    Bus
;                           BL    Device
;                           CH    Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoInitHardware    Proc near
    mov dx,ds:IoBase
    add dx,REG_CR
    in al,dx
    and al,NOT 0Ch
    or al,10h
    out dx,al
;
    push cx
    mov cx,10000

ioihResetWait:
    in al,dx
    test al,10h
    jz ioihResetDone
;
    pause
    loop ioihResetWait
;
    pop cx
    stc
    jmp ioihDone

ioihResetDone:
    pop cx
;
    mov dx,ds:IoBase
    add dx,REG_MAR0
    mov eax,-1
    out dx,eax
    add edx,4
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,REG_IDR0
    in eax,dx
    mov dword ptr ds:EthernetAddress,eax
    add dx,4
    in eax,dx
    mov word ptr ds:EthernetAddress+4,ax
;
    call UnlockConf
;
    mov dx,ds:IoBase
    add dx,REG_CCR
    in ax,dx
    and ax,NOT 260h
    or al,8
    out dx,ax 
;
    call CreateRxRing
    mov dx,ds:IoBase
    add dx,REG_RDSAR + 4
    xor eax,eax
    out dx,eax
;
    sub dx,4
    mov eax,ds:RxRingPhys
    out dx,eax
;
    call CreateTxRing    
    mov dx,ds:IoBase
    add dx,REG_TNPDS + 4
    xor eax,eax
    out dx,eax
;
    sub dx,4
    mov eax,ds:TxRingPhys
    out dx,eax
;    
    mov dx,ds:IoBase
    add dx,REG_IMR
    mov ax,IR_MASK
    out dx,ax    
;
    mov dx,ds:IoBase
    add dx,REG_RMS
    mov ax,2000h
    out dx,ax
;
    mov dx,ds:IoBase
    add dx,REG_MTPS
    mov al,3Bh
    out dx,al           
;
    mov dx,ds:IoBase
    add dx,REG_CONFIG1
    in al,dx
    and al,NOT 1
    out dx,al
;
    mov dx,ds:IoBase
    add dx,REG_CONFIG3
    in al,dx
    or al,40h
    out dx,al
;    
    mov dx,ds:IoBase
    add dx,REG_CR
    in al,dx
    or al,0Ch
    out dx,al
;    
    mov dx,ds:IoBase
    add dx,REG_TCR
    in eax,dx
    and ax,NOT 700h
    or ax,600h
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,REG_RCR
    in eax,dx
    or eax,10000h
    and ax,1FFFh    
    or ax,0E000h
    and ax,NOT 700h
    or ax,600h
    and al,0C0h
    or al,0Eh
    out dx,eax
    clc

ioihDone:
    mov ds:Isr,0
    mov ds:RxCurrDescr,0
;    
;    mov dx,ds:IoBase
;    add dx,REG_PHYAR
;    mov eax,80008000h
;    out dx,eax
;
    mov dx,ds:IoBase
    add dx,REG_TPPoll
    mov al,1
    out dx,al    
    ret
IoInitHardware    Endp
      
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           MemInitHardware
;
;       DESCRIPTION:    Initialize hardware
;
;       PARAMETERS:         BH    Bus
;                           BL    Device
;                           CH    Function
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemInitHardware    Proc near
    mov al,fs:mem_cr
    and al,NOT 0Ch
    or al,10h
    mov fs:mem_cr,al
;
    push cx
    mov cx,10000

mihResetWait:
    mov al,fs:mem_cr
    test al,10h
    jz mihResetDone
;
    pause
    loop mihResetWait
;
    pop cx
    stc
    jmp mihDone

mihResetDone:
    pop cx
;
    mov eax,-1
    mov fs:mem_mar0,eax
    mov fs:mem_mar1,eax
;
    mov eax,fs:mem_idr0
    mov dword ptr ds:EthernetAddress,eax
    mov eax,fs:mem_idr1
    mov word ptr ds:EthernetAddress+4,ax
;
    call UnlockConf
;
    mov ax,fs:mem_ccr
    and ax,NOT 260h
    or al,8
    mov fs:mem_ccr,ax
;
    call CreateRxRing
    mov eax,ds:RxRingPhys
    mov fs:mem_rdsar,eax
    xor eax,eax
    mov fs:mem_rdsar+4,eax
;
    call CreateTxRing    
    mov eax,ds:TxRingPhys
    mov fs:mem_tnpds,eax
    xor eax,eax
    mov fs:mem_tnpds+4,eax
;    
    mov ax,IR_MASK
    mov fs:mem_imr,ax
;
    mov ax,2000h
    mov fs:mem_rms,ax
;
    mov al,3Bh
    mov fs:mem_mtps,al
;
    mov al,fs:mem_config3
    or al,40h
    mov fs:mem_config3,al
;    
    mov al,0
    mov fs:mem_9346cr,al
;    
    mov al,fs:mem_cr
    or al,0Ch
    mov fs:mem_cr,al
;    
    mov eax,fs:mem_tcr
    and ax,NOT 700h
    or ax,600h
    mov fs:mem_tcr,eax
;
    mov eax,fs:mem_rcr
    or eax,10000h
    and ax,1FFFh    
    or ax,0E000h
    and ax,NOT 700h
    or ax,600h
    and al,0C0h
    or al,0Eh
    mov fs:mem_rcr,eax
    clc

mihDone:
    mov ds:Isr,0
    mov ds:RxCurrDescr,0
;
    mov al,1
    mov fs:mem_tppoll,al
    ret
MemInitHardware    Endp
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           FindHardware
;
;       DESCRIPTION:    Find hardware
;
;       PARAMETERS:     DS driver data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mac_tab:
mt30 DW 07CF0h, 6410h, 63, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt2F DW 07CF0h, 6090h, 61, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt2E DW 07CF0h, 54B0h, 53, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt2D DW 07CF0h, 54A0h, 52, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt2C DW 07CF0h, 5020h, 51, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt2B DW 07CF0h, 5410h, 46, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt2A DW 07CF0h, 5C80h, 44, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt29 DW 07CF0h, 5090h, 42, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt28 DW 07CF0h, 4C00h, 40, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt27 DW 07C80h, 4880h, 38, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt26 DW 07CF0h, 4810h, 36, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt25 DW 07CF0h, 4800h, 35, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt24 DW 07C80h, 2C80h, 34, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt23 DW 07CF0h, 2C10h, 32, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt22 DW 07C80h, 2C00h, 33, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt21 DW 07CF0h, 2810h, 25, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt20 DW 07C80h, 2800h, 26, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1F DW 07CF0h, 28A0h, 28, OFFSET ReadPhy8168dp2,  OFFSET WritePhy8168dp2
mt1E DW 07CF0h, 28B0h, 31, OFFSET ReadPhy8168dp2,  OFFSET WritePhy8168dp2
mt1D DW 07CF0h, 3C90h, 23, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1C DW 07CF0h, 3C80h, 18, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1B DW 07C80h, 3C80h, 24, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1A DW 07CF0h, 3C00h, 19, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt19 DW 07CF0h, 3C20h, 20, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt18 DW 07CF0h, 3C30h, 21, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt17 DW 07C80h, 3C00h, 22, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt16 DW 07CF0h, 3800h, 12, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt15 DW 07C80h, 3800h, 17, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt14 DW 07C80h, 3000h, 11, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt13 DW 07C80h, 4480h, 39, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt12 DW 0FC80h, 4400h, 37, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt11 DW 07CF0h, 4090h, 29, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt10 DW 07C80h, 4080h, 30, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0F DW 07CF0h, 3490h, 8,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0E DW 07CF0h, 2490h, 8,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0D DW 07CF0h, 3480h, 7,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0C DW 07CF0h, 2480h, 7,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0B DW 07CF0h, 3400h, 13, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0A DW 07CF0h, 2400h, 14, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt09 DW 07CF0h, 3430h, 10, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt08 DW 07CF0h, 3420h, 16, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt07 DW 07C80h, 3480h, 9,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt06 DW 07C80h, 2480h, 9,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt05 DW 07C80h, 3400h, 16, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt04 DW 0FC80h, 9800h, 6,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt03 DW 0FC80h, 1800h, 5,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt02 DW 0FC80h, 1000h, 4,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt01 DW 0FC80h, 0400h, 3,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt00 DW 0FC80h, 0080h, 2,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mtxx DW     -1,    -1, 0,                   0,                       0

IoFindHardware    Proc near
    mov dx,ds:IoBase
    add dx,REG_TCR
    in eax,dx
    shr eax,16
    mov bx,OFFSET mac_tab

iofhLoop:    
    mov dx,cs:[bx]
    cmp dx,-1
    je iofFailed
;
    and dx,ax
    cmp dx,cs:[bx+2]
    je iofhOk
;
    add bx,10  
    jmp iofhLoop

iofFailed:
    mov ds:HwId,0
    mov ds:ReadPhyProc,0
    mov ds:WritePhyProc,0
    stc
    ret

iofhOk:
    mov ax,cs:[bx+4]
    mov ds:HwId,ax
    mov ax,cs:[bx+6]
    mov ds:ReadPhyProc,ax
    mov ax,cs:[bx+8]
    mov ds:WritePhyProc,ax
    mov ds:PhyBase,OCP_STD_PHY_BASE
    clc
    ret
IoFindHardware   Endp

MemFindHardware    Proc near
    mov eax,fs:mem_tcr
    shr eax,16
    mov bx,OFFSET mac_tab

mfhLoop:    
    mov dx,cs:[bx]
    cmp dx,-1
    je mfFailed
;
    and dx,ax
    cmp dx,cs:[bx+2]
    je mfhOk
;
    add bx,10  
    jmp mfhLoop

mfFailed:
    mov ds:HwId,0
    mov ds:ReadPhyProc,0
    mov ds:WritePhyProc,0
    stc
    ret

mfhOk:
    mov ax,cs:[bx+4]
    mov ds:HwId,ax
    mov ax,cs:[bx+6]
    mov ds:ReadPhyProc,ax
    mov ax,cs:[bx+8]
    mov ds:WritePhyProc,ax
    mov ds:PhyBase,OCP_STD_PHY_BASE
    clc
    ret
MemFindHardware   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           IoResetHardware
;
;       DESCRIPTION:    Reset hardware
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoResetHardware    Proc near
    mov ds:Isr,0
;
    mov dx,ds:IoBase
    add dx,REG_CR
    in al,dx
    and al,NOT 0Ch
    or al,10h
    out dx,al
;
    push cx
    mov cx,10000

iorhResetWait:
    in al,dx
    test al,10h
    jz iorhResetDone
;
    pause
    loop iorhResetWait
;
    pop cx
    stc
    jmp iorhDone

iorhResetDone:
    pop cx

iorhDone:    
    call ResetRxRing
    call ResetTxRing        
;
    mov dx,ds:IoBase
    add dx,REG_RDSAR + 4
    xor eax,eax
    out dx,eax
;
    sub dx,4
    mov eax,ds:RxRingPhys
    out dx,eax
;
    mov dx,ds:IoBase
    add dx,REG_TNPDS + 4
    xor eax,eax
    out dx,eax
;
    sub dx,4
    mov eax,ds:TxRingPhys
    out dx,eax
;    
    mov dx,ds:IoBase
    add dx,REG_IMR
    mov ax,IR_MASK
    out dx,ax    
;
    mov dx,ds:IoBase
    add dx,REG_RMS
    mov ax,2000h
    out dx,ax
;
    mov dx,ds:IoBase
    add dx,REG_MTPS
    mov al,3Bh
    out dx,al           
;
    mov dx,ds:IoBase
    add dx,REG_CR
    in al,dx
    or al,0Ch
    out dx,al
;    
    mov dx,ds:IoBase
    add dx,REG_ISR
    in ax,dx
    out dx,ax
    xor ax,ax
    out dx,ax
;
    mov dx,ds:IoBase
    add dx,REG_TPPoll
    mov al,40h
    out dx,al    
;
    mov ds:RxCurrDescr,0
    mov ds:Isr,0
    mov dx,ds:IoBase
    add dx,REG_ISR
    in ax,dx
    ret
IoResetHardware    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           MemResetHardware
;
;       DESCRIPTION:    Reset hardware
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemResetHardware    Proc near
    mov ds:Isr,0
;
    mov al,fs:mem_cr
    and al,NOT 0Ch
    or al,10h
    mov fs:mem_cr,al
;
    push cx
    mov cx,10000

mrhResetWait:
    mov al,fs:mem_cr
    test al,10h
    jz mrhResetDone
;
    pause
    loop mrhResetWait
;
    pop cx
    stc
    jmp mrhDone

mrhResetDone:
    pop cx

mrhDone:    
    call ResetRxRing
    call ResetTxRing        
;
    mov eax,ds:RxRingPhys
    mov fs:mem_rdsar,eax
    xor eax,eax
    mov fs:mem_rdsar+4,eax
;
    mov eax,ds:TxRingPhys
    mov fs:mem_tnpds,eax
    xor eax,eax
    mov fs:mem_tnpds+4,eax
;    
    mov ax,IR_MASK
    mov fs:mem_imr,ax
;
    mov ax,2000h
    mov fs:mem_rms,ax
;
    mov al,3Bh
    mov fs:mem_mtps,al
;
    mov al,fs:mem_cr
    or al,0Ch
    mov fs:mem_cr,al
;    
    mov ax,fs:mem_isr
    mov fs:mem_isr,ax
    xor ax,ax
    mov fs:mem_isr,ax
;
    mov al,40h
    mov fs:mem_tppoll,al
;
    mov ds:RxCurrDescr,0
    mov ds:Isr,0
    mov ax,fs:mem_isr
    ret
MemResetHardware    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NetInt
;
;           DESCRIPTION:    Network card interrupt
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetInt  Proc far
    mov ax,ds:MemSel
    or ax,ax
    jz IoInt

MemInt:
    push fs
    mov fs,ax
    mov ax,fs:mem_imr
    mov di,ax
    xor ax,ax
    mov fs:mem_imr,ax

mniLoop:
    mov ax,fs:mem_isr
    or ax,ax
    jz mniDone
;
    mov si,1
    mov fs:mem_isr,ax
    and ax,di
    or ds:Isr,ax
    test ax,IR_RDU OR IR_FOVW
    jz mniNotOv
;
    and di,NOT (IR_RDU OR IR_ROK OR IR_FOVW)
    mov bx,ds:SuperThread
    Signal

mniNotOv:    
    test ax,IR_ROK OR IR_SER
    jz mniNotRx
;    
    mov bx,ds:Handle
    or bx,bx
    jz mniNotRx
;
    NetReceived
    jmp mniLoop

mniNotRx:
    test ax,IR_LinkChg
    jz mniDone
;
    mov bx,ds:SuperThread
    Signal

mniDone:
    mov ax,di
    mov fs:mem_imr,ax
    pop fs
    retf32

IoInt:
    mov dx,ds:IoBase
    add dx,REG_IMR
    in ax,dx
    mov di,ax
    xor ax,ax
    out dx,ax

ioniLoop:
    mov dx,ds:IoBase
    add dx,REG_ISR
    in ax,dx
    or ax,ax
    jz ioniDone
;
    mov si,1
    out dx,ax
    and ax,di
    or ds:Isr,ax
    test ax,IR_RDU OR IR_FOVW
    jz ioniNotOv
;
    and di,NOT (IR_RDU OR IR_ROK OR IR_FOVW)
    mov bx,ds:SuperThread
    Signal

ioniNotOv:    
    test ax,IR_ROK OR IR_SER
    jz ioniNotRx
;    
    mov bx,ds:Handle
    or bx,bx
    jz ioniNotRx
;
    NetReceived
    jmp ioniLoop

ioniNotRx:
    test ax,IR_LinkChg
    jz ioniDone
;
    mov bx,ds:SuperThread
    Signal
        
ioniDone:
    mov dx,ds:IoBase
    add dx,REG_IMR
    mov ax,di
    out dx,ax
    retf32
NetInt  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           NetTimeout
;
;           DESCRIPTION:    Network card timeout (used with IRQ malfunctions)
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NetTimeout  Proc far
    push eax
    push cx
    push edx
;
    mov di,ds:MemSel
    or di,di
    jz IoTimeout

MemTimeout:
    push fs
    mov fs,di
    mov ds,cx
;
    mov ax,fs:mem_imr
    mov di,ax
    xor ax,ax
    mov fs:mem_imr,ax

mntLoop:
    mov ax,fs:mem_isr
    or ax,ax
    jz mntDone
;
    mov si,1
    or ds:Isr,ax
    mov fs:mem_isr,ax
    test ax,IR_RDU OR IR_FOVW
    jz mntNotOv
;
    int 3
    mov bx,ds:SuperThread
    Signal

mntNotOv:    
    test ax,IR_ROK OR IR_SER
    jz mntNotRx
;
    mov bx,ds:Handle
    or bx,bx
    jz mntNotRx
;
    NetReceived
    jmp mntLoop

mntNotRx:
    test ax,IR_LinkChg
    jz mntDone
;
    mov bx,ds:SuperThread
    Signal
        
mntDone:
    mov ax,di
    mov fs:mem_imr,ax
    pop fs
    jmp ntRet

IoTimeout:    
    mov ds,cx
    mov dx,ds:IoBase
    add dx,REG_IMR
    in ax,dx
    mov di,ax
    xor ax,ax
    out dx,ax

iontLoop:
    mov dx,ds:IoBase
    add dx,REG_ISR
    in ax,dx
    or ax,ax
    jz iontDone
;
    mov si,1
    or ds:Isr,ax
    out dx,ax
    test ax,IR_RDU OR IR_FOVW
    jz iontNotOv
;
    int 3
    mov bx,ds:SuperThread
    Signal

iontNotOv:    
    test ax,IR_ROK OR IR_SER
    jz iontNotRx
;
    mov bx,ds:Handle
    or bx,bx
    jz iontNotRx
;
    NetReceived
    jmp iontLoop

iontNotRx:
    test ax,IR_LinkChg
    jz iontDone
;
    mov bx,ds:SuperThread
    Signal
        
iontDone:
    mov dx,ds:IoBase
    add dx,REG_IMR
    mov ax,di
    out dx,ax

ntRet:
    pop edx
    pop cx
    pop eax
;    
    add eax,1193
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetTimeout
    mov bx,cx
    StartTimer
    retf32
NetTimeout  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoPreview
;
;           DESCRIPTION:    Return size of block or no more data
;
;           RETURNS:        NC          Data available
;                           ECX         Size of data (0)
;                           DX          Packet type
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoPreview1:
    push ds
    push es
    push bx
    push si
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp iopreview_do
    
IoPreview2:
    push ds
    push es
    push bx
    push si
;
    mov ax,ether_data2_sel
    mov ds,ax

iopreview_do:
    mov es,ds:RxRingSel
    mov cx,RX_DESCR_COUNT
    mov bx,ds:RxCurrDescr
    add bx,16
    mov si,bx
    shr si,4
    
iopreview_loop:
    cmp si,RX_DESCR_COUNT
    jb iopreview_no_wrap
;
    xor bx,bx
    xor si,si

iopreview_no_wrap:    
    test es:[bx].rx_flags,RX_OWN
    jnz iopreview_next
;
    mov ax,es:[bx].rx_fl_size
    and ax,1FFFh    
    jnz iopreview_found
;
    mov es:[bx].rx_fl_size,1FF8h
    mov es:[bx].rx_flags,RX_OWN

iopreview_next:
    inc si
    add bx,16
    loop iopreview_loop
;    
    mov dx,ds:IoBase
    add dx,REG_IMR
    mov ax,IR_MASK
    out dx,ax
    stc
    jmp iopreview_done        

iopreview_found:
    shl si,2
    add si,OFFSET RxLinearArr
    mov ax,flat_sel
    mov es,ax
    mov edx,ds:[si]
    mov ds:RxCurrDescr,bx
    mov ds:RxCurrLinear,edx
    mov dx,es:[edx+12]
    xchg dl,dh
    xor ecx,ecx
    clc
        
iopreview_done:
    pop si
    pop bx
    pop es
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemPreview
;
;           DESCRIPTION:    Return size of block or no more data
;
;           RETURNS:        NC          Data available
;                           ECX         Size of data (0)
;                           DX          Packet type
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemPreview1:
    push ds
    push es
    push fs
    push bx
    push si
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp mpreview_do
    
MemPreview2:
    push ds
    push es
    push fs
    push bx
    push si
;
    mov ax,ether_data2_sel
    mov ds,ax

mpreview_do:
    mov fs,ds:MemSel
    mov es,ds:RxRingSel
    mov cx,RX_DESCR_COUNT
    mov bx,ds:RxCurrDescr
    add bx,16
    mov si,bx
    shr si,4
    
mpreview_loop:
    cmp si,RX_DESCR_COUNT
    jb mpreview_no_wrap
;
    xor bx,bx
    xor si,si

mpreview_no_wrap:    
    test es:[bx].rx_flags,RX_OWN
    jnz mpreview_next
;
    mov ax,es:[bx].rx_fl_size
    and ax,1FFFh    
    jnz mpreview_found
;
    mov es:[bx].rx_fl_size,1FF8h
    mov es:[bx].rx_flags,RX_OWN

mpreview_next:
    inc si
    add bx,16
    loop mpreview_loop
;    
 
    mov ax,IR_MASK
    mov fs:mem_imr,ax
    stc
    jmp mpreview_done        

mpreview_found:
    shl si,2
    add si,OFFSET RxLinearArr
    mov ax,flat_sel
    mov es,ax
    mov edx,ds:[si]
    mov ds:RxCurrDescr,bx
    mov ds:RxCurrLinear,edx
    mov dx,es:[edx+12]
    xchg dl,dh
    xor ecx,ecx
    clc
        
mpreview_done:
    pop si
    pop bx
    pop fs
    pop es
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           Receive
;
;       DESCRIPTION:    Receive data
;
;       PARAMETERS:     ECX             size of data
;
;       RETURNS:        ES:EDI          data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Receive1:
    push ds
    push bx
    push edx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp receive_do

Receive2:
    push ds
    push bx
    push edx
;
    mov ax,ether_data2_sel
    mov ds,ax
    
receive_do:
    mov edx,ds:RxCurrLinear
    mov bx,ds:RxCurrDescr
    mov es,ds:RxRingSel
    mov cx,es:[bx].rx_fl_size
    and ecx,1FFFh
    AllocateGdt
    CreateAliasSelector16
    xor edi,edi
    mov es,bx
    NotifyEthernetPacket
    mov edi,14
    sub ecx,14
;
    pop edx
    pop bx
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Remove
;
;           DESCRIPTION:    Remove data from buffer ring
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Remove1:
    push ds
    push es
    push bx
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp remove_do

Remove2:
    push ds
    push es
    push bx
;
    mov ax,ether_data2_sel
    mov ds,ax

remove_do:
    mov es,ds:RxRingSel
    mov bx,ds:RxCurrDescr
    mov es:[bx].rx_fl_size,1FF8h
    mov ax,es:[bx].rx_flags
    and ax,RX_EOR
    or ax,RX_OWN
    mov es:[bx].rx_flags,ax
;
    pop bx
    pop es
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetBuffer
;
;           DESCRIPTION:    Get buffer
;
;       PARAMETERS:     ECX         size
;
;           RETURNS:        ES:EDI  data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBuffer1:
    push ds
    push bx
    push edx
    push si
    push bp
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp get_buffer

GetBuffer2:
    push ds
    push bx
    push edx
    push si
    push bp
;
    mov ax,ether_data2_sel
    mov ds,ax

get_buffer:
    xor bp,bp
    mov es,ds:TxRingSel

get_buffer_retry:
    EnterSection ds:TxSection
    mov si,ds:TxCurrDescr
    mov ax,si
    cmp ax,ds:TxLastDescr
    je get_buffer_first_descr
;
    add ax,16
    jmp get_buffer_save_curr

get_buffer_first_descr:
    xor ax,ax

get_buffer_save_curr:
    mov bx,si
    shr si,2
    add si,OFFSET TxLinearArr
;
    test es:[bx].tx_flags,TX_OWN
    jz get_buffer_take
;
    LeaveSection ds:TxSection
;
    mov dx,ds:MemSel
    or dx,dx
    jz ioget_poll

mget_poll:
    push fs
    mov fs,dx
    mov al,40h
    mov fs:mem_tppoll,al
    pop fs
    jmp get_buffer_polled

ioget_poll:
    mov dx,ds:IoBase
    add dx,REG_TPPoll
    mov al,40h
    out dx,al    

get_buffer_polled:
    mov ax,5
    WaitMilliSec    
;
    inc bp
    cmp bp,1000
    jb get_buffer_retry
;
    int 3
    stc
    jmp get_buffer_done

get_buffer_take:
    mov ds:TxCurrDescr,ax
    LeaveSection ds:TxSection
;
    add cx,14
    mov es:[bx].tx_size,cx
    mov edx,ds:[si]
;    
    push bx
    AllocateGdt
    CreateAliasSelector16
    mov es,bx
    pop ax
    mov edi,14
    mov es:[edi-2],ax
    sub cx,14
    clc

get_buffer_done:
    pop bp
    pop si
    pop edx
    pop bx
    pop ds    
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoSend
;
;           DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX         size
;                           DX          packet type
;                           DS:ESI  dest address
;                           ES:EDI  data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoSend1:
    push ds
    push bx
    push dx
    push si
    push edi
;
    xor di,di
    mov ax,ds:[esi]
    stosw
    mov ax,[esi+2]
    stosw
    mov ax,[esi+4]
    stosw
;
    mov ax,ether_data_sel
    mov ds,ax
    jmp iosend_do
    
IoSend2:
    push ds
    push bx
    push dx
    push si
    push edi
;
    xor di,di
    mov ax,ds:[esi]
    stosw
    mov ax,[esi+2]
    stosw
    mov ax,[esi+4]
    stosw
;
    mov ax,ether_data2_sel
    mov ds,ax

iosend_do:
    mov ax,word ptr ds:EthernetAddress
    stosw
    mov ax,word ptr ds:EthernetAddress+2
    stosw
    mov ax,word ptr ds:EthernetAddress+4
    stosw
;    
    mov ax,dx
    xchg al,ah
    xchg ax,es:[di]
    add di,2
    mov si,ax
;
    add ecx,14
    xor edi,edi
    NotifyEthernetPacket
    FreeMem
;    
    cmp ecx,60
    jae iosPadOk
;
    mov ecx,60

iosPadOk: 
    mov es,ds:TxRingSel
    mov es:[si].tx_size,cx
    or es:[si].tx_flags,TX_OWN
;
    xor ax,ax
    mov es,ax
;
    mov dx,ds:IoBase
    add dx,REG_TPPoll
    mov al,40h
    out dx,al    
;
    pop edi
    pop si
    pop dx
    pop bx
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemSend
;
;           DESCRIPTION:    Send data
;
;       PARAMETERS:     ECX         size
;                           DX          packet type
;                           DS:ESI  dest address
;                           ES:EDI  data buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemSend1:
    push ds
    push fs
    push bx
    push dx
    push si
    push edi
;
    xor di,di
    mov ax,ds:[esi]
    stosw
    mov ax,[esi+2]
    stosw
    mov ax,[esi+4]
    stosw
;
    mov ax,ether_data_sel
    mov ds,ax
    mov fs,ds:MemSel
    jmp msend_do
    
MemSend2:
    push ds
    push fs
    push bx
    push dx
    push si
    push edi
;
    xor di,di
    mov ax,ds:[esi]
    stosw
    mov ax,[esi+2]
    stosw
    mov ax,[esi+4]
    stosw
;
    mov ax,ether_data2_sel
    mov ds,ax
    mov fs,ds:MemSel

msend_do:
    mov ax,word ptr ds:EthernetAddress
    stosw
    mov ax,word ptr ds:EthernetAddress+2
    stosw
    mov ax,word ptr ds:EthernetAddress+4
    stosw
;    
    mov ax,dx
    xchg al,ah
    xchg ax,es:[di]
    add di,2
    mov si,ax
;
    add ecx,14
    xor edi,edi
    NotifyEthernetPacket
    FreeMem
;    
    cmp ecx,60
    jae msPadOk
;
    mov ecx,60

msPadOk: 
    mov es,ds:TxRingSel
    mov es:[si].tx_size,cx
    or es:[si].tx_flags,TX_OWN
;
    xor ax,ax
    mov es,ax
;
    mov al,40h
    mov fs:mem_tppoll,al
;
    pop edi
    pop si
    pop dx
    pop bx
    pop fs
    pop ds
    retf32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetAddress
;
;           DESCRIPTION:    Get adapter address
;
;           RETURNS:        DS:ESI  address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAddress1  Proc far
    mov si,ether_data_sel
    mov ds,si
    mov esi,OFFSET EthernetAddress  
    retf32
GetAddress1     Endp

GetAddress2  Proc far
    mov si,ether_data2_sel
    mov ds,si
    mov esi,OFFSET EthernetAddress  
    retf32
GetAddress2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           GetPktAddress
;
;           DESCRIPTION:    Get packet addresses
;
;           PARAMETERS:         ES          Data buffer selector
;
;           RETURNS:        ES:ESI  Source address
;                           ES:EDI  Dest address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetPktAddress   Proc far
    mov esi,6
    xor edi,edi
    retf32
GetPktAddress   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoGetLinkState
;
;           DESCRIPTION:    Get link state
;
;           RETURNS:        NC      Link up
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoGetLinkState1  Proc far
    push ds
    push ax
    push dx
;    
    mov ax,ether_data_sel
    mov ds,ax
    mov dx,ds:IoBase
    add dx,REG_PHYStatus
    in al,dx
    test al,2
    clc
    jnz iogls1Ok
;
    stc

iogls1Ok:
    pop dx
    pop ax
    pop ds
    retf32
IoGetLinkState1     Endp

IoGetLinkState2  Proc far
    push ds
    push ax
    push dx
;    
    mov ax,ether_data2_sel
    mov ds,ax
    mov dx,ds:IoBase
    add dx,REG_PHYStatus
    in al,dx
    test al,2
    clc
    jnz iogls2Ok
;
    stc

iogls2Ok:
    pop dx
    pop ax
    pop ds
    retf32
IoGetLinkState2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemGetLinkState
;
;           DESCRIPTION:    Get link state
;
;           RETURNS:        NC      Link up
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemGetLinkState1  Proc far
    push ds
    push ax
;    
    mov ax,ether_data_sel
    mov ds,ax
    mov ds,ds:MemSel
    mov al,ds:mem_phy_stat
    test al,2
    clc
    jnz mgls1Ok
;
    stc

mgls1Ok:
    pop ax
    pop ds
    retf32
MemGetLinkState1     Endp

MemGetLinkState2  Proc far
    push ds
    push ax
;    
    mov ax,ether_data2_sel
    mov ds,ax
    mov ds,ds:MemSel
    mov al,ds:mem_phy_stat
    test al,2
    clc
    jnz mgls2Ok
;
    stc

mgls2Ok:
    pop ax
    pop ds
    retf32
MemGetLinkState2     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetMac
;
;       DESCRIPTION:    Get Mac address
;
;       RETURNS:        ES:EDI    Mac
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetMac1  Proc far
    mov di,ether_data_sel
    mov es,di
    mov edi,OFFSET EthernetAddress  
    retf32
GetMac1 Endp    

GetMac2  Proc far
    mov di,ether_data2_sel
    mov es,di
    mov edi,OFFSET EthernetAddress  
    retf32
GetMac2 Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           DispatchTable
;
;           DESCRIPTION:    Driver dispatch table
;
;       PARAMETERS:     
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoDispTable1:
    DD OFFSET IoPreview1,       SEG code
    DD OFFSET Receive1,         SEG code
    DD OFFSET Remove1,          SEG code
    DD OFFSET GetBuffer1,       SEG code
    DD OFFSET IoSend1,          SEG code
    DD OFFSET GetAddress1,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET IoGetLinkState1,  SEG code
    DD OFFSET GetMac1,          SEG code

IoDispTable2:
    DD OFFSET IoPreview2,       SEG code
    DD OFFSET Receive2,         SEG code
    DD OFFSET Remove2,          SEG code
    DD OFFSET GetBuffer2,       SEG code
    DD OFFSET IoSend2,          SEG code
    DD OFFSET GetAddress2,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET IoGetLinkState2,  SEG code
    DD OFFSET GetMac2,          SEG code

MemDispTable1:
    DD OFFSET MemPreview1,      SEG code
    DD OFFSET Receive1,         SEG code
    DD OFFSET Remove1,          SEG code
    DD OFFSET GetBuffer1,       SEG code
    DD OFFSET MemSend1,         SEG code
    DD OFFSET GetAddress1,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET MemGetLinkState1, SEG code
    DD OFFSET GetMac1,          SEG code

MemDispTable2:
    DD OFFSET MemPreview2,      SEG code
    DD OFFSET Receive2,         SEG code
    DD OFFSET Remove2,          SEG code
    DD OFFSET GetBuffer2,       SEG code
    DD OFFSET MemSend2,         SEG code
    DD OFFSET GetAddress2,      SEG code
    DD OFFSET GetPktAddress,    SEG code
    DD OFFSET MemGetLinkState2, SEG code
    DD OFFSET GetMac2,          SEG code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           SetupInts
;
;           DESCRIPTION:    Setup PCI or MSI IRQ
;
;       PARAMETERS:         BH    Bus
;                           BL    Device
;                           CH    Function
;                           DS    Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts   Proc near
    push ax
    push bx
    push cx
    push edx
    push edi
;    
    GetPciMsi
    jc siIrq

siMsi:
    push cx
    mov cx,1
    mov al,14h
    AllocateInts
    pop cx
    jc siIrq
;    
    mov dl,1
    SetupPciMsi
;    
    mov di,cs
    mov es,di
    mov edi,OFFSET NetInt
    RequestMsiHandler
    jmp siDone

siIrq:
    GetPciIrqNr
    mov ah,14h
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetInt    
    RequestIrqHandler

siDone:
    pop edi
    pop edx
    pop cx
    pop bx
    pop ax
    ret
SetupInts    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           SetSpeed
;
;       DESCRIPTION:    Set speed
;
;       PARAMETERS:     DS      Data
;                       AX      Advertiser
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSpeed  Proc near
    mov si,ax
    and si,ADV_10_HALF OR ADV_10_FULL OR ADV_100_HALF OR ADV_100_FULL
    mov di,ax
    and di,ADV_1000_HALF OR ADV_1000_FULL
;
    mov dl,1Fh
    xor ax,ax
    call ds:WritePhyProc
;
    mov dl,4
    call ds:ReadPhyProc
    and ax,NOT (ADV_10_HALF OR ADV_10_FULL OR ADV_100_HALF OR ADV_100_FULL)
    or si,ax
    or si,0C00h
;
    mov dl,9
    call ds:ReadPhyProc
    and ax,NOT (ADV_1000_HALF OR ADV_1000_FULL)
    or di,ax
;
    mov dl,4
    mov ax,si
    call ds:WritePhyProc
;
    mov dl,9
    mov ax,di
    call ds:WritePhyProc
;
    mov dl,0
    mov ax,1200h
    call ds:WritePhyProc
    ret
SetSpeed    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoUpdateLink
;
;           DESCRIPTION:    Update link state
;
;       PARAMETERS:         DS      Data
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoUpdateLink  Proc near
    push ax
;    
    call UnlockConf
;
    mov dx,ds:IoBase
    add dx,REG_PHYStatus
    in al,dx
    test al,2
    jnz ioulPatch
;
    GetSystemTime
    sub eax,ds:PhyTimeout
    sbb edx,ds:PhyTimeout+4
    jc ioulDone 
;
    mov ax,ADV_10_HALF OR ADV_10_FULL OR ADV_100_HALF OR ADV_100_FULL
    cmp ds:IoCfg,2
    je ioulNoHigh
;
    or ax,ADV_1000_HALF OR ADV_1000_FULL

ioulNoHigh:    
    call SetSpeed
;
    GetSystemTime
    add eax,1193 * 5000
    adc edx,0
    mov ds:PhyTimeout,eax
    mov ds:PhyTimeout+4,edx
    jmp ioulDone

ioulPatch:
    mov ax,ds:HwId
    cmp ax,34
    je ioul34_38
;    
    cmp ax,38
    je ioul34_38
;
    cmp ax,35
    je ioul35_36
;
    cmp ax,36
    je ioul35_36    
;    
    cmp ax,37
    je ioul37
;
    jmp ioulDone 

ioul34_38:
    mov dx,ds:IoBase
    add dx,REG_PHYStatus    
    in al,dx
    test al,PHY_1000
    jnz ioul34_38_1000
;
    test al,PHY_100
    jnz ioul34_38_100    

ioul34_38_10:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,1Fh
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,3Fh
    call WriteEri
    jmp ioulDone

ioul34_38_100:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,1Fh
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,5
    call WriteEri
    jmp ioulDone

ioul34_38_1000:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,11h
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,5h
    call WriteEri
    jmp ioulDone

ioul35_36:
    mov dx,ds:IoBase
    add dx,REG_PHYStatus    
    in al,dx
    test al,PHY_1000
    jnz ioul35_36_1000

ioul35_36_10_100:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,1Fh
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,3Fh
    call WriteEri
    jmp ioulDone

ioul35_36_1000:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,11h
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,5h
    call WriteEri
    jmp ioulDone

ioul37:
    mov dx,ds:IoBase
    add dx,REG_PHYStatus    
    in al,dx
    test al,PHY_10
    jnz ioul37_10

ioul37_100:
    mov bx,1D0h
    mov ecx,ERIAR_MASK_0011
    xor eax,eax
    call WriteEri
    jmp ioulDone

ioul37_10:
    mov bx,1D0h
    mov ecx,ERIAR_MASK_0011
    mov eax,4D02h
    call WriteEri
;
    mov bx,1DCh
    mov ecx,ERIAR_MASK_0011
    mov eax,60h
    call WriteEri

ioulDone:
    call LockConf
    pop ax
    ret
IoUpdateLink  Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemUpdateLink
;
;           DESCRIPTION:    Update link state
;
;       PARAMETERS:         DS      Data
;                           FS      Mem sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemUpdateLink  Proc near
    push ax
;    
    call UnlockConf
;
    mov al,fs:mem_phy_stat
    test al,2
    jnz mulPatch
;
    GetSystemTime
    sub eax,ds:PhyTimeout
    sbb edx,ds:PhyTimeout+4
    jc mulDone 
;
    mov ax,ADV_10_HALF OR ADV_10_FULL OR ADV_100_HALF OR ADV_100_FULL
    cmp ds:IoCfg,2
    je mulNoHigh
;
    or ax,ADV_1000_HALF OR ADV_1000_FULL

mulNoHigh:    
    call SetSpeed
;
    GetSystemTime
    add eax,1193 * 5000
    adc edx,0
    mov ds:PhyTimeout,eax
    mov ds:PhyTimeout+4,edx
    jmp mulDone

mulPatch:
    mov ax,ds:HwId
    cmp ax,34
    je mul34_38
;    
    cmp ax,38
    je mul34_38
;
    cmp ax,35
    je mul35_36
;
    cmp ax,36
    je mul35_36    
;    
    cmp ax,37
    je mul37
;
    jmp mulDone 

mul34_38:
    mov al,fs:mem_phy_stat
    test al,PHY_1000
    jnz mul34_38_1000
;
    test al,PHY_100
    jnz mul34_38_100    

mul34_38_10:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,1Fh
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,3Fh
    call WriteEri
    jmp mulDone

mul34_38_100:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,1Fh
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,5
    call WriteEri
    jmp mulDone

mul34_38_1000:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,11h
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,5h
    call WriteEri
    jmp mulDone

mul35_36:
    mov al,fs:mem_phy_stat
    test al,PHY_1000
    jnz mul35_36_1000

mul35_36_10_100:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,1Fh
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,3Fh
    call WriteEri
    jmp mulDone

mul35_36_1000:
    mov bx,1BCh
    mov ecx,ERIAR_MASK_1111
    mov eax,11h
    call WriteEri
;        
    mov bx,1DCh
    mov ecx,ERIAR_MASK_1111
    mov eax,5h
    call WriteEri
    jmp mulDone

mul37:
    mov al,fs:mem_phy_stat
    test al,PHY_10
    jnz mul37_10

mul37_100:
    mov bx,1D0h
    mov ecx,ERIAR_MASK_0011
    xor eax,eax
    call WriteEri
    jmp mulDone

mul37_10:
    mov bx,1D0h
    mov ecx,ERIAR_MASK_0011
    mov eax,4D02h
    call WriteEri
;
    mov bx,1DCh
    mov ecx,ERIAR_MASK_0011
    mov eax,60h
    call WriteEri

mulDone:
    call LockConf
    pop ax
    ret
MemUpdateLink  Endp
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IO supervisor_thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

io_super_thread:
    mov ds,bx
    GetThread
    mov ds:SuperThread,ax
;    call Config
;    
    GetSystemTime    
    add eax,119300
    adc edx,0
    mov ds:PhyTimeout,eax
    mov ds:PhyTimeout+4,edx
    
iostLoop:
    mov dx,ds:IoBase
    add dx,REG_PHYStatus
    in al,dx
    test al,2
    jnz iostNoTimeout

iostTimeout:
    mov eax,ds:PhyTimeout
    mov edx,ds:PhyTimeout+4
    WaitForSignalWithTimeout
    jmp iostHandle

iostNoTimeout:
    WaitForSignal

iostHandle:    
    xor ax,ax
    xchg ax,ds:Isr
;
    test ax,IR_FOVW
    jz iostOvOk
;
    push ax
    EnterSection ds:TxSection
    call IoResetHardware    
    LeaveSection ds:TxSection
    pop ax
    jmp iostRecOk

iostOvOk:    
    test ax,IR_RDU
    jz iostRecOk
;
    mov dx,ds:IoBase
    add dx,REG_ISR
    mov ax,IR_RDU OR IR_ROK OR IR_FOVW
    out dx,ax
;
    mov dx,ds:IoBase
    add dx,REG_IMR
    in ax,dx
    or ax,IR_RDU OR IR_ROK OR IR_FOVW
    out dx,ax
    jmp iostOvOk

iostRecOk:
    call IoUpdateLink
    jmp iostLoop
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           mem_supervisor_thread
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mem_super_thread:
    mov ds,bx
    GetThread
    mov ds:SuperThread,ax
;    call Config
;    
    GetSystemTime    
    add eax,119300
    adc edx,0
    mov ds:PhyTimeout,eax
    mov ds:PhyTimeout+4,edx
    mov fs,ds:MemSel
    
mstLoop:
    mov al,fs:mem_phy_stat
    test al,2
    jnz mstNoTimeout

mstTimeout:
    mov eax,ds:PhyTimeout
    mov edx,ds:PhyTimeout+4
    WaitForSignalWithTimeout
    jmp mstHandle

mstNoTimeout:
    WaitForSignal

mstHandle:    
    xor ax,ax
    xchg ax,ds:Isr
;
    test ax,IR_FOVW
    jz mstOvOk
;
    push ax
    EnterSection ds:TxSection
    call MemResetHardware    
    LeaveSection ds:TxSection
    pop ax
    jmp mstRecOk

mstOvOk:    
    test ax,IR_RDU
    jz mstRecOk
;
    mov ax,IR_RDU OR IR_ROK OR IR_FOVW
    mov fs:mem_isr,ax
;
    mov ax,fs:mem_imr
    or ax,IR_RDU OR IR_ROK OR IR_FOVW
    mov fs:mem_imr,ax
    jmp mstOvOk

mstRecOk:
    call MemUpdateLink
    jmp mstLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           CreateMemSel
;
;           DESCRIPTION:    Create mem sel
;
;       PARAMETERS:         EBX:EAX		Physical address
;
;       RETURNS:            BX			Mem sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMemSel	Proc near
    and ax,0FFE0h
    push eax
    mov eax,1000h
    AllocateBigLinear
    pop eax
;
    mov si,ax
    and ax,0F000h
    or ax,813h
    SetPageEntry
;
    and si,0FFFh
    or dx,si
    AllocateGdt
    mov ecx,SIZE mem_struc
    CreateDataSelector16
    ret
CreateMemSel	Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:     AX      Device number
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName1     DB 'Net RTL8169-1',0
DriverName2     DB 'Net RTL8169-2',0

SupervisorName1 DB 'Super RTL8169-1',0
SupervisorName2 DB 'Super RTL8169-2',0

PciVendorTab:
pci00   DW 10ECh, 8129h,    0
pci01   DW 10ECh, 8136h,    2
pci02   DW 10ECh, 8167h,    0
pci03   DW 10ECh, 8168h,    1
pci04   DW 10ECh, 8169h,    0
pci05   DW 1186h, 4300h,    0
pci06   DW 1186h, 4302h,    0
pci07   DW 0,     0

DevName1 DB 'RTL8169-1', 0
DevName2 DB 'RTL8169-2', 0

InitPrimaryPciAdapter   Proc near
    mov bp,ax
    mov ax,cs
    mov es,ax
    mov ax,ether_data_sel
    mov ds,ax
    mov ds:Handle,0
    mov si,OFFSET PciVendorTab
init_pci1_loop:
    mov ax,bp
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci1_done
;
    FindPciDevice
    jnc init_pci1_found
;
    add si,6
    jmp init_pci1_loop

init_pci1_found:
    mov edi,OFFSET DevName1
    PciPowerOn
;
    mov bp,bx
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_busmstr OR PCI_command_IO OR PCI_command_mem
    WritePciWord
;
    mov cl,PCI_card_ExCa_base
    ReadPciDword
    test al,1
    jz m_pci1

io_pci1:
    mov dx,ax
    and dx,0FFE0h
    mov ds:IoBase,dx
    mov ds:MemSel,0
    mov si,cs:[si+4]
    mov ds:IoCfg,si
;    
    call SetupInts
    call IoInitHardware
    call IoFindHardware
    jc init_pci1_done
;
    call Config
    call StartHw
    mov ax,25
    WaitMilliSec
;    
    mov dx,ds:IoBase
    add dx,REG_ISR
    in eax,dx
    test eax,IR_SWInt
    jz ioinit_pci1_int_ok
;
    int 3
;    
    GetSystemTime    
    add eax,1193
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetTimeout
    mov bx,ds
    mov cx,bx
    StartTimer

ioinit_pci1_int_ok:        
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET IoDispTable1
    mov edi,OFFSET DriverName1
    mov al,1
    mov dx,0
    mov ecx,1600
    RegisterNetDriver
    pop ds
    mov ds:Handle,bx
;
    push ds
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET io_super_thread
    mov edi,OFFSET SupervisorName1
    mov ax,2
    mov cx,1000h
    CreateThread
    pop ds
;    
    mov ax,bp   
    clc
    jmp init_pci1_done

m_pci1:
    push ebx
    xor ebx,ebx
    test al,4
    jz minit_pci1_next_base_ok
;
    push eax    
    mov cl,14h
    ReadPciDword
    mov ebx,eax
    pop eax

minit_pci1_next_base_ok:
    call CreateMemSel
    mov fs,bx
    mov ds:IoBase,0
    mov ds:MemSel,bx
    mov si,cs:[si+4]
    mov ds:IoCfg,si
    pop ebx
;    
    call SetupInts
    call MemInitHardware
    call MemFindHardware
    jc init_pci1_done
;
    call Config
    call StartHw
;
    mov ax,25
    WaitMilliSec
;    
    mov ax,fs:mem_isr
    test ax,IR_SWInt
    jz minit_pci1_int_ok
;
    int 3
;    
    GetSystemTime    
    add eax,1193
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetTimeout
    mov bx,ds
    mov cx,bx
    StartTimer

minit_pci1_int_ok:        
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET MemDispTable1
    mov edi,OFFSET DriverName1
    mov al,1
    mov dx,0
    mov ecx,1600
    RegisterNetDriver
    pop ds
    mov ds:Handle,bx
;
    push ds
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET mem_super_thread
    mov edi,OFFSET SupervisorName1
    mov ax,2
    mov cx,1000h
    CreateThread
    pop ds
;    
    mov ax,bp   
    clc

init_pci1_done:
    ret
InitPrimaryPciAdapter   Endp

InitSecondaryPciAdapter Proc near
    mov bp,ax
    mov ax,cs
    mov es,ax
    mov ax,ether_data2_sel
    mov ds,ax
    mov ds:Handle,0
    mov si,OFFSET PciVendorTab
init_pci2_loop:
    mov ax,bp
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci2_done
;
    FindPciDevice
    jnc init_pci2_found
;
    add si,6
    jmp init_pci2_loop

init_pci2_found:
    mov edi,OFFSET DevName2
    PciPowerOn
;
    mov bp,bx
    mov cl,PCI_command_reg
    ReadPciWord
    or al,PCI_command_busmstr OR PCI_command_IO OR PCI_command_mem
    WritePciWord
;
    mov cl,PCI_card_ExCa_base
    ReadPciDword
    test al,1
    jz m_pci2

io_pci2:
    mov dx,ax
    and dx,0FFE0h
    mov ds:IoBase,dx
    mov ds:MemSel,0
    mov si,cs:[si+4]
    mov ds:IoCfg,si
;
    call SetupInts
    call IoInitHardware
    jc init_pci2_done
;
    call Config
    call StartHw
;
    mov ax,1
    WaitMilliSec
;    
    mov dx,ds:IoBase
    add dx,REG_ISR
    in eax,dx
    test eax,IR_SWInt
    jz ioinit_pci2_int_ok
;
    GetSystemTime    
    add eax,1193
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetTimeout
    mov bx,ds
    mov cx,bx
    StartTimer

ioinit_pci2_int_ok:        
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET IoDispTable2
    mov edi,OFFSET DriverName2
    mov al,1
    mov dx,0
    mov ecx,1600
    RegisterNetDriver
    pop ds
    mov ds:Handle,bx
;
    push ds
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET io_super_thread
    mov edi,OFFSET SupervisorName2
    mov ax,2
    mov cx,1000h
    CreateThread
    pop ds
;
    mov ax,bp   
    clc
    jmp init_pci2_done

m_pci2:
    push ebx
    xor ebx,ebx
    test al,4
    jz minit_pci2_next_base_ok
;
    push eax    
    mov cl,14h
    ReadPciDword
    mov ebx,eax
    pop eax

minit_pci2_next_base_ok:
    call CreateMemSel
    mov fs,bx
    mov ds:IoBase,0
    mov ds:MemSel,bx
    mov si,cs:[si+4]
    mov ds:IoCfg,si
    pop ebx
;
    call SetupInts
    call MemInitHardware
    call MemFindHardware
    jc init_pci2_done
;
    call Config
    call StartHw
;
    mov ax,1
    WaitMilliSec
;    
    mov ax,fs:mem_isr
    test ax,IR_SWInt
    jz minit_pci2_int_ok
;
    GetSystemTime    
    add eax,1193
    adc edx,0
    mov bx,cs
    mov es,bx
    mov edi,OFFSET NetTimeout
    mov bx,ds
    mov cx,bx
    StartTimer

minit_pci2_int_ok:        
    push ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET MemDispTable2
    mov edi,OFFSET DriverName2
    mov al,1
    mov dx,0
    mov ecx,1600
    RegisterNetDriver
    pop ds
    mov ds:Handle,bx
;
    push ds
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET mem_super_thread
    mov edi,OFFSET SupervisorName2
    mov ax,2
    mov cx,1000h
    CreateThread
    pop ds
;
    mov ax,bp   
    clc

init_pci2_done:
    ret
InitSecondaryPciAdapter Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;       NAME:           GetNetHwId
;
;       DESCRIPTION:    Get network hardware ID
;
;       PARAMETERS:     AL      Ethernet port
;
;       RETURNS:        EAX     HW ID
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

get_net_hw_id_name    DB 'Get Net Hw Id', 0

get_net_hw_id Proc far
    push ds
;    
    or al,al
    jz ghwid0
;
    cmp al,1
    je ghwid1
;
    stc
    jmp ghwidDone

ghwid0:
    mov ax,ether_data_sel
    jmp ghwidDo

ghwid1:
    mov ax,ether_data2_sel

ghwidDo:
    mov ds,ax
    mov ax,ds:Handle
    or ax,ax
    stc
    jz ghwidDone
;
    movzx eax,ds:HwId
    clc

ghwidDone:
    pop ds
    retf32
get_net_hw_id Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init_net
;
;           DESCRIPTION:    inits adpater
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
init_net    Proc far
    push ds
    push es
    pusha
;
    xor ax,ax
    call InitPrimaryPciAdapter
;
    inc ax
    call InitSecondaryPciAdapter
;    
    popa
    pop es
    pop ds
    retf32
init_net    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           Init
;
;           DESCRIPTION:    init device
;
;       PARAMETERS:     
;
;           RETURNS:        
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init    Proc far
    mov ax,cs
    mov ds,ax
    mov es,ax
;
    mov esi,OFFSET get_net_hw_id
    mov edi,OFFSET get_net_hw_id_name
    xor dx,dx
    mov ax,get_net_hw_id_nr
    RegisterBimodalUserGate
;
    mov eax,SIZE data
    mov bx,ether_data_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
    InitSection ds:TxSection
;
    mov eax,SIZE data
    mov bx,ether_data2_sel
    AllocateFixedSystemMem
    mov ds,bx
    mov es,bx
    mov cx,ax
    xor di,di
    xor al,al
    rep stosb
    InitSection ds:TxSection
;
    mov ax,cs
    mov es,ax
    mov edi,OFFSET init_net
    HookInitPci
    clc
    ret
Init    Endp

code    ENDS

    END init
