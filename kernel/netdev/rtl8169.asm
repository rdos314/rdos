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
INCLUDE ..\acpi\pci.inc
INCLUDE ..\os\core.inc
INCLUDE ..\os\net.inc

RX_DESCR_COUNT = 256
TX_DESCR_COUNT = 128

OCP_STD_PHY_BASE = 0A400h

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

PHY_10      = 4
PHY_100     = 8
PHY_1000    = 10h

ADV_10_HALF     = 20h
ADV_10_FULL     = 40h
ADV_100_HALF    = 80h
ADV_100_FULL    = 100h
ADV_1000_HALF   = 400h
ADV_1000_FULL   = 800h

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

REG_GPHY_OCP = 0B8h

REG_RMS = 0DAh
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

mem_struc       STRUC

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
mem_eriar     DD ?                   
mem_res3      DD ?, ?, ?, ?, ?, ?    
mem_res4      DD ?, ?, ?, ?          
mem_res5      DD ?, ?, ?, ?          
mem_res6      DD ?, ?                
mem_gphy_ocp  DD ?, ?
mem_res7      DD ?, ?, ?, ?          
mem_res8      DW ?, ?, ?, ?, ?       
mem_rms       DW ?                   
mem_res9      DD ?
mem_ccr       DW ?, ?
mem_rdsar     DD ?, ?
mem_mtps      DB ?, ?, ?, ?             
mem_res10     DD ?, ?, ?, ?

mem_struc       ENDS

data    STRUC

IoBase              DW ?
MemSel              DW ?
Gphy                DW ?
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

WritePhy8169    Proc near
    push ax
    mov ax,ds:MemSel
    or ax,ax
    pop ax
    jz IoWritePhy8169
    jmp MemWritePhy8169

WritePhy8169    Endp

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

ReadPhy8169     Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadPhy8169
    jmp MemReadPhy8169

ReadPhy8169     Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoWritePhy8169g
;
;           DESCRIPTION:    Write to phy, 8169g version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoWritePhy8169g    Proc near
    push eax
    push cx
    push dx
;    
    movzx eax,ax
    rol eax,16
    mov ax,ds:Gphy
    shr ax,1
    or ax,8000h
    add al,dl
    ror eax,16
;    
    mov dx,ds:IoBase
    add dx,REG_GPHY_OCP
;
    out dx,eax
    xor cx,cx

iowpWait8169g:    
    pause
    in eax,dx
    test eax,80000000h
    jz iowpDone8169g
    loop iowpWait8169g

iowpDone8169g:
    mov ax,20
    WaitMicroSec
;    
    pop dx
    pop cx
    pop eax
    ret
IoWritePhy8169g    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemWritePhy8169g
;
;           DESCRIPTION:    Write to phy, 8169g version
;
;           PARAMETERS:     FS      Registers
;                           DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemWritePhy8169g    Proc near
    push eax
    push cx
;    
    movzx eax,ax
    rol eax,16
    mov ax,ds:Gphy
    shr ax,1
    or ax,8000h
    add al,dl
    ror eax,16
;
    mov fs:mem_gphy_ocp,eax
    xor cx,cx

mwpWait8169g:    
    pause
    mov eax,fs:mem_gphy_ocp
    test eax,80000000h
    jz mwpDone8169g
    loop mwpWait8169g

mwpDone8169g:
    mov ax,20
    WaitMicroSec
;    
    pop cx
    pop eax
    ret
MemWritePhy8169g    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePhy8169g
;
;           DESCRIPTION:    Write to phy, 8169g version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePhy8169g    Proc near
    cmp dl,1Fh
    jne WritePhy8169gNorm
;
    or ax,ax
    jnz WritePhy8169gSpec
;
    mov ax,0A400h
    mov ds:Gphy,ax
    ret

WritePhy8169gSpec:
    shl ax,4
    sub ax,10h
    mov ds:Gphy,ax
    ret

WritePhy8169gNorm:
    push ax
    mov ax,ds:MemSel
    or ax,ax
    pop ax
    jz IoWritePhy8169g
    jmp MemWritePhy8169g

WritePhy8169g   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           IoReadPhy8169g
;
;           DESCRIPTION:    Read from phy, 8169g version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IoReadPhy8169g    Proc near
    push cx
    push dx
;    
    mov ax,ds:Gphy
    shr ax,1
    add al,dl
    shl eax,16
;    
    mov dx,ds:IoBase
    add dx,REG_GPHY_OCP
;
    out dx,eax
    xor cx,cx

iorpWait8169g:    
    pause
    in eax,dx
    test eax,80000000h
    jnz iorpDone8169g
;
    loop iorpWait8169g

iorpDone8169g:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop dx
    pop cx
    ret
IoReadPhy8169g    Endp    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           MemReadPhy8169g
;
;           DESCRIPTION:    Read from phy, 8169g version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MemReadPhy8169g    Proc near
    push cx
;    
    mov ax,ds:Gphy
    shr ax,1
    add al,dl
    shl eax,16
;
    mov fs:mem_gphy_ocp,eax
    xor cx,cx

mrpWait8169g:    
    pause
    mov eax,fs:mem_gphy_ocp
    test eax,80000000h
    jnz mrpDone8169g
;
    loop mrpWait8169g

mrpDone8169g:
    push eax
    mov ax,20
    WaitMicroSec
    pop eax
;    
    pop cx
    ret
MemReadPhy8169g    Endp    

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

ReadPhy8169g    Proc near
    cmp dl,1Fh
    jne ReadPhy8169gNorm
;
    mov ax,ds:Gphy
    cmp ax,0A400h
    jne ReadPhy8169gSpec
;
    xor ax,ax
    ret

ReadPhy8169gSpec:
    shr ax,4
    add ax,10h
    ret

ReadPhy8169gNorm:
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadPhy8169g
    jmp MemReadPhy8169g
    ret
ReadPhy8169g    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           WritePhy8168dp1
;
;           DESCRIPTION:    Write to phy, 8168dp1 version
;
;           PARAMETERS:     DL      Register
;                           AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WritePhy8168dp1    Proc near
    int 3
    ret
WritePhy8168dp1   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           ReadPhy8168dp1
;
;           DESCRIPTION:    Read from phy, 8168dp1 version
;
;           PARAMETERS:     DL      Register
;
;           RETURNS:        AX      Data
;                           
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadPhy8168dp1    Proc near
    int 3
    ret
ReadPhy8168dp1    Endp

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

WritePhy8168dp2    Proc near
    int 3
    ret
WritePhy8168dp2   Endp

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

ReadPhy8168dp2    Proc near
    int 3
    ret
ReadPhy8168dp2    Endp

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

ReadEri Proc near
    mov ax,ds:MemSel
    or ax,ax
    jz IoReadEri
    jmp MemReadEri

ReadEri Endp

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

WriteEri        Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       NAME:          Config8169
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Wait100ms   Proc near
   mov ax,100
   WaitMilliSec
   ret
Wait100ms   ENDP

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
  DW 01Fh,  00002h
  DW 001h,  090D0h
  DW 01Fh,  00000h
  DW -1
  
Config8169scdq:
  DW 01Fh,  00001h
  DW 010h,  0F01Bh
  DW 01Fh,  00000h
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
  DW 01Fh,  00001h
  DW 116h,  00001h
  DW 010h,  0F41Bh
  DW 01Fh,  00000h
  DW -1

Config8168bef:  
  DW 01Fh,  00000h
  DW 01Dh,  00F00h
  DW 01Fh,  00002h
  DW 00Ch,  01EC8h
  DW 01Fh,  00000h
  DW -1
  
Config8168cp1: 
  DW 01Fh,  00000h
  DW 01Dh,  00F00h
  DW 01Fh,  00002h
  DW 00Ch,  01EC8h
  DW 01Fh,  00000h
  DW -1
  
Config8168cp2: 
  DW 01Fh,  00000h
  DW 114h,  00020h
  DW 10Dh,  00020h
  DW 01Fh,  00001h
  DW 01Dh,  03D98h
  DW 01Fh,  00000h
  DW -1
   
  
Config8168c1: 
  DW 01Fh,  00001h
  DW 012h,  02300h
  DW 01Fh,  00002h
  DW 000h,  088D4h
  DW 001h,  082B1h
  DW 003h,  07002h
  DW 008h,  09E30h
  DW 009h,  001F0h
  DW 00Ah,  05500h
  DW 00Ch,  000C8h
  DW 01Fh,  00003h
  DW 012h,  0C096h
  DW 016h,  0000Ah
  DW 01Fh,  00000h
  DW 01Fh,  00000h
  DW 009h,  02000h
  DW 009h,  00000h  
  DW 114h,  00020h
  DW 10Dh,  00020h
  DW 01Fh,  00000h
  DW -1
  
Config8168c2: 
  DW 01Fh,  00001h
  DW 012h,  02300h
  DW 003h,  0802Fh
  DW 002h,  04F02h
  DW 001h,  00409h
  DW 000h,  0F099h
  DW 004h,  09800h
  DW 004h,  09000h
  DW 01Dh,  03D98h
  DW 01Fh,  00002h
  DW 00Ch,  07EB8h
  DW 006h,  00761h
  DW 01Fh,  00003h
  DW 016h,  00F0Ah
  DW 01Fh,  00000h
  DW 116h,  00001h
  DW 114h,  00020h
  DW 10Dh,  00020h
  DW 01Fh,  00000h
  DW -1
     
Config8168c3: 
  DW 01Fh,  00001h
  DW 012h,  02300h
  DW 01Dh,  03D98h
  DW 01Fh,  00002h
  DW 00Ch,  07EB8h
  DW 006h,  05461h
  DW 01Fh,  00003h
  DW 016h,  00F0Ah
  DW 01Fh,  00000h
  DW 116h,  00001h
  DW 114h,  00020h
  DW 10Dh,  00020h
  DW 01Fh,  00000h
  DW -1

Config8168d1_d2: 
  DW 01Fh,  00001h
  DW 006h,  04064h
  DW 007h,  02863h
  DW 008h,  0059Ch
  DW 009h,  026B4h
  DW 00Ah,  06A19h
  DW 00Bh,  0DCC8h
  DW 010h,  0F06Dh
  DW 014h,  07F68h
  DW 018h,  07FD9h
  DW 01Ch,  0F0FFh
  DW 01Dh,  03D9Ch
  DW 01Fh,  00003h
  DW 012h,  0F49Fh
  DW 013h,  0070Bh
  DW 01Ah,  005ADh
  DW 014h,  094C0h

  DW 01Fh,  00002h
  DW 006h,  05561h
  DW 01Fh,  00005h
  DW 005h,  08332h
  DW 006h,  05561h

  DW 01Fh,  00001h
  DW 017h,  00CC0h
  DW 01Fh,  00000h
  DW 00Dh,  0F880h
  DW 01Fh,  00002h
  DW 202h,  00100h,  00600h
  DW 203h,  00000h,  0E000h
  DW 01Fh,  00002h
  DW 10Fh,  00017h
  DW 01Fh,  00005h
  DW 005h,  0001Bh
  DW 01Fh,  00000h
  DW -1

Config8168d3: 
  DW 01Fh,  00002h
  DW 010h,  00008h
  DW 00Dh,  0006Ch

  DW 01Fh,  00000h
  DW 00Dh,  0F880h

  DW 01Fh,  00001h
  DW 017h,  00CC0h

  DW 01Fh,  00001h
  DW 00Bh,  0A4D8h
  DW 009h,  0281Ch
  DW 007h,  02883h
  DW 00Ah,  06B35h
  DW 01Dh,  03DA4h
  DW 01Ch,  0EFFDh
  DW 014h,  07F52h
  DW 018h,  07FC6h
  DW 008h,  00601h
  DW 006h,  04063h
  DW 010h,  0F074h

  DW 01Fh,  00003h
  DW 013h,  00789h
  DW 012h,  0F4BDh
  DW 01Ah,  004FDh
  DW 01Fh,  00000h
  DW 000h,  09200h

  DW 01Fh,  00005h
  DW 001h,  00340h

  DW 01Fh,  00001h
  DW 004h,  04000h
  DW 003h,  01D21h
  DW 002h,  00C32h
  DW 001h,  00200h
  DW 000h,  05554h
  DW 004h,  04800h
  DW 004h,  04000h
  DW 004h,  0F000h
  DW 003h,  0DF01h
  DW 002h,  0DF20h
  DW 001h,  0101Ah
  DW 000h,  0A0FFh
  DW 004h,  0F800h
  DW 004h,  0F000h
  DW 01Fh,  00000h

  DW 01Fh,  00007h
  DW 01Eh,  00023h
  DW 016h,  00000h
  DW 01Fh,  00000h
  DW -1

Config8168d4:
  DW 01Fh,  00001h
  DW 017h,  00CC0h

  DW 01Fh,  00007h
  DW 01Eh,  0002Dh
  DW 018h,  00040h
  DW 01Fh,  00000h
  DW 10Dh,  00020h
  DW -1 

Config8168e1:
  DW 01Fh,  00005h
  DW 005h,  08B80h
  DW 006h,  0C896h
  DW 01Fh,  00000h

  DW 01Fh,  00001h
  DW 00Bh,  06C20h
  DW 007h,  02872h
  DW 01Ch,  0EFFFh
  DW 01Fh,  00003h
  DW 014h,  06420h
  DW 01Fh,  00000h

  DW 01Fh,  00007h
  DW 01Eh,  0002Fh
  DW 015h,  01919h
  DW 01Fh,  00000h

  DW 01Fh,  00007h
  DW 01Eh,  000ACh
  DW 018h,  00006h
  DW 01Fh,  00000h

  DW 01Fh,  00007h
  DW 01Eh,  00023h
  DW 217h,  00006h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00002h
  DW 01Eh,  0002Dh
  DW 218h,  00050h,  00000h
  DW 01Fh,  00000h
  DW 214h,  08000h,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B85h
  DW 206h,  00000h,  02000h

  DW 01Fh,  00007h
  DW 01Eh,  00020h
  DW 215h,  00000h,  01100h

  DW 01Fh,  00006h
  DW 000h,  05A00h
  DW 01Fh,  00000h
  DW 00Dh,  00007h
  DW 00Eh,  0003Ch
  DW 00Dh,  04007h
  DW 00Eh,  00000h
  DW 00Dh,  00000h  
  DW -1

Config8168e2:
  DW 01Fh,  00004h
  DW 01Fh,  00007h
  DW 01Eh,  000ACh
  DW 018h,  00006h
  DW 01Fh,  00002h
  DW 01Fh,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00003h
  DW 009h,  0A20Fh
  DW 01Fh,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B5Bh
  DW 006h,  09222h
  DW 005h,  08B6Dh
  DW 006h,  08000h
  DW 005h,  08B76h
  DW 006h,  08000h
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B80h
  DW 217h,  00006h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00004h
  DW 01Fh,  00007h
  DW 01Eh,  0002Dh
  DW 218h,  00010h,  00000h
  DW 01Fh,  00002h
  DW 01Fh,  0000h
  DW 214h,  08000h,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B86h
  DW 206h,  00001h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B85h
  DW 206h,  04000h,  00000h
  DW 01Fh,  00000h

  DW 500h,  001B0h
  DD ERIAR_MASK_1111,  00000h,  00003h

  DW 01Fh,  00005h
  DW 005h,  08B85h
  DW 206h,  00000h,  02000h
  DW 01Fh,  00004h
  DW 01Fh,  00007h
  DW 01Eh,  00020h
  DW 215h,  00000h,  00100h
  DW 01Fh,  00002h
  DW 01Fh,  00000h
  DW 00Dh,  00007h
  DW 00Eh,  0003Ch
  DW 00Dh,  04007h
  DW 00Eh,  00000h
  DW 00Dh,  00000h

  DW 01Fh,  00003h
  DW 219h,  00000h,  00001h
  DW 210h,  00000h,  00400h
  DW 01Fh,  00000h 
  DW -1

Config8168f:
  DW 01Fh,  00005h
  DW 005h,  08B80h
  DW 206h,  00006h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00007h
  DW 01Eh,  0002Dh
  DW 218h,  00010h,  00000h
  DW 01Fh,  00000h
  DW 214h,  08000h,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B86h
  DW 206h,  00001h,  00000h
  DW 01Fh,  00000h
  DW -1
  
Config8168f1_f2:
  DW 01Fh,  00003h
  DW 009h,  0A20Fh
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B55h
  DW 006h,  00000h
  DW 005h,  08B5Eh
  DW 006h,  00000h
  DW 005h,  08B67h
  DW 006h,  00000h
  DW 005h,  08B70h
  DW 006h,  00000h
  DW 01Fh,  00000h
  DW 01Fh,  00007h
  DW 01Eh,  00078h
  DW 017h,  00000h
  DW 019h,  000FBh
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B79h
  DW 006h,  0AA00h
  DW 01Fh,  00000h

  DW 01Fh,  00003h
  DW 001h,  0328Ah
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B85h
  DW 206h,  04000h,  00000h
  DW 01Fh,  00000h
  DW -1
  
Config8411:
  DW 01Fh,  00005h
  DW 005h,  08B80h
  DW 206h,  00006h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00007h
  DW 01Eh,  0002Dh
  DW 218h,  00010h,  00000h
  DW 01Fh,  00000h
  DW 214h,  08000h,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B86h
  DW 206h,  00001h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B85h
  DW 206h,  04000h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00003h
  DW 009h,  0A20Fh
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B55h
  DW 006h,  00000h
  DW 005h,  08B5Eh
  DW 006h,  00000h
  DW 005h,  08B67h
  DW 006h,  00000h
  DW 005h,  08B70h
  DW 006h,  00000h
  DW 01Fh,  00000h
  DW 01Fh,  00007h
  DW 01Eh,  00078h
  DW 017h,  00000h
  DW 019h,  000AAh
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B79h
  DW 006h,  0AA00h
  DW 01Fh,  00000h

  DW 01Fh,  00003h
  DW 001h,  0328Ah
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B54h
  DW 206h,  00000h,  00800h
  DW 005h,  08B5Dh
  DW 206h,  00000h,  00800h
  DW 005h,  08A7Ch
  DW 206h,  00000h,  00100h
  DW 005h,  08A7Fh
  DW 206h,  00100h,  00000h
  DW 005h,  08A82h
  DW 206h,  00000h,  00100h
  DW 005h,  08A85h
  DW 206h,  00000h,  00100h
  DW 005h,  08A88h
  DW 206h,  00000h,  00100h
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B85h
  DW 206h,  08000h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00005h
  DW 005h,  08B85h
  DW 206h,  00000h,  02000h
  DW 01Fh,  00004h
  DW 01Fh,  00007h
  DW 01Eh,  00020h
  DW 215h,  00000h,  00100h
  DW 01Fh,  00000h
  DW 00Dh,  00007h
  DW 00Eh,  0003Ch
  DW 00Dh,  04007h
  DW 00Eh,  00000h
  DW 00Dh,  00000h

  DW 01Fh,  00003h
  DW 219h,  00000h,  00001h
  DW 210h,  00000h,  00400h
  DW 01Fh,  00000h 
  DW -1
   
Config8168g1:
  DW 01Fh,  00A44h
  DW 211h,  0000Ch,  00000h

  DW 01Fh,  00BCCh
  DW 214h,  00100h,  00000h
  DW 01Fh,  00A44h
  DW 211h,  000C0h,  00000h
  DW 01Fh,  00A43h
  DW 013h,  08084h
  DW 214h,  00000h,  06000h
  DW 210h,  01003h,  00000h

  DW 01Fh,  00A4Bh
  DW 211h,  00004h,  00000h

  DW 01Fh,  00A43h
  DW 013h,  08012h
  DW 214h,  08000h,  00000h

  DW 01Fh,  00C42h
  DW 211h,  04000h,  02000h

  DW 01Fh,  00BCDh
  DW 014h,  05065h
  DW 014h,  0D065h
  DW 01Fh,  00BC8h
  DW 011h,  05655h
  DW 01Fh,  00BCDh
  DW 014h,  01065h
  DW 014h,  09065h
  DW 014h,  01065h

  DW 01Fh,  00000h
  DW -1
    
Config8168g2:
  DW -1

Config8168h1:
  DW 01Fh,  00A43h
  DW 013h,  0809Bh
  DW 214h,  08000h,  0F800h
  DW 013h,  080A2h
  DW 214h,  08000h,  0FF00h
  DW 013h,  080A4h
  DW 214h,  08500h,  0FF00h
  DW 013h,  0809Ch
  DW 214h,  0BD00h,  0FF00h

  DW 01Fh,  00A43h
  DW 013h,  080ADh
  DW 214h,  07000h,  0F800h
  DW 013h,  080B4h
  DW 214h,  05000h,  0FF00h
  DW 013h,  080ACh
  DW 214h,  04000h,  0FF00h
  DW 01Fh,  00000h

  DW 01Fh,  00A43h
  DW 013h,  0808Eh
  DW 214h,  01200h,  0FF00h
  DW 013h,  08090h
  DW 214h,  0E500h,  0FF00h
  DW 013h,  08092h
  DW 214h,  09F00h,  0FF00h
  DW 01Fh,  00000h

  DW 01Fh,  00A44h
  DW 211h,  00800h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00BCAh
  DW 217h,  04000h,  03000h
  DW 01Fh,  00000h

  DW 01Fh,  00A43h
  DW 013h,  0803Fh
  DW 214h,  00000h,  03000h
  DW 013h,  08047h
  DW 214h,  00000h,  03000h
  DW 013h,  0804Fh
  DW 214h,  00000h,  03000h
  DW 013h,  08057h
  DW 214h,  00000h,  03000h
  DW 013h,  0805Fh
  DW 214h,  00000h,  03000h
  DW 013h,  08067h
  DW 214h,  00000h,  03000h
  DW 013h,  0806Fh
  DW 214h,  00000h,  03000h
  DW 01Fh,  00000h

  DW 01Fh,  00A44h
  DW 214h,  00000h,  00080h
  DW 01Fh,  00000h
  DW -1  
  
Config8168h2:
  DW 01Fh,  00A43h
  DW 013h,  0808Ah
  DW 214h,  0000Ah,  0003Fh
  DW 01Fh,  00000h

  DW 01Fh,  00A44h
  DW 013h,  00811h
  DW 214h,  00800h,  00000h

  DW 01Fh,  00A43h
  DW 013h,  00016h
  DW 214h,  00002h,  00000h

  DW 01Fh,  00A45h
  DW 013h,  00011h
  DW 214h,  00000h,  00080h

  DW 01Fh,  00A44h
  DW 013h,  00010h
  DW 214h,  00000h,  00001h

  DW 01Fh,  00A44h
  DW 013h,  00010h
  DW 214h,  00000h,  00004h

  DW 01Fh,  00000h
  DW -1

Config8168ep1:
  DW 01Fh,  00A44h
  DW 211h,  0000Ch,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00BCCh
  DW 214h,  00000h,  00100h
  DW 01Fh,  00A44h
  DW 211h,  000C0h,  00000h
  DW 01Fh,  00A43h
  DW 013h,  08084h
  DW 214h,  00000h,  06000h
  DW 210h,  01003h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00A4Bh
  DW 211h,  00004h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00A43h
  DW 013h,  08012h
  DW 214h,  08000h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00C42h
  DW 211h,  04000h,  02000h
  DW 01Fh,  00000h
  DW -1

Config8168ep2:
  DW 01Fh,  00BCCh
  DW 214h,  00000h,  00100h
  DW 01Fh,  00A44h
  DW 211h,  000C0h,  00000h
  DW 01Fh,  00A43h
  DW 013h,  08084h
  DW 214h,  00000h,  06000h
  DW 210h,  01003h,  00000h

  DW 01Fh,  00A43h
  DW 013h,  08012h
  DW 214h,  08000h,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00C42h
  DW 211h,  04000h,  02000h
  DW 01Fh,  00000h

  DW 01Fh,  00A43h
  DW 013h,  080F3h
  DW 214h,  08B00h,  07400h
  DW 013h,  080F0h
  DW 214h,  03A00h,  0C500h
  DW 013h,  080EFh
  DW 214h,  00500h,  0FA00h
  DW 013h,  080F6h
  DW 214h,  06E00h,  09100h
  DW 013h,  080ECh
  DW 214h,  06800h,  09700h
  DW 013h,  080EDh
  DW 214h,  07C00h,  08300h
  DW 013h,  080F2h
  DW 214h,  0F400h,  00B00h
  DW 013h,  080F4h
  DW 214h,  08500h,  07A00h
  DW 01Fh,  00A43h
  DW 013h,  08110h
  DW 214h,  0A800h,  05700h
  DW 013h,  0810Fh
  DW 214h,  01D00h,  0E200h
  DW 013h,  08111h
  DW 214h,  0F500h,  00A00h
  DW 013h,  08113h
  DW 214h,  06100h,  09E00h
  DW 013h,  08115h
  DW 214h,  09200h,  06D00h
  DW 013h,  0810Eh
  DW 214h,  00400h,  0FB00h
  DW 013h,  0810Ch
  DW 214h,  07C00h,  08300h
  DW 013h,  0810Bh
  DW 214h,  05A00h,  0A500h
  DW 01Fh,  00A43h
  DW 013h,  080D1h
  DW 214h,  0FF00h,  00000h
  DW 013h,  080CDh
  DW 214h,  09E00h,  06100h
  DW 013h,  080D3h
  DW 214h,  00E00h,  0F100h
  DW 013h,  080D5h
  DW 214h,  0CA00h,  03500h
  DW 013h,  080D7h
  DW 214h,  08400h,  07B00h

  DW 01Fh,  00BCDh
  DW 014h,  05065h
  DW 014h,  0D065h
  DW 01Fh,  00BC8h
  DW 012h,  000EDh
  DW 01Fh,  00BCDh
  DW 014h,  01065h
  DW 014h,  09065h
  DW 014h,  01065h
  DW 01Fh,  00000h
  DW -1
  
Config8102e:
  DW 01Fh,  00000h
  DW 111h,  01000h
  DW 119h,  02000h
  DW 110h,  08000h

  DW 01Fh,  00003h
  DW 008h,  0441Dh
  DW 001h,  09100h
  DW 01Fh,  00000h
  DW -1

Config8105e:
  DW 01Fh,  00000h
  DW 018h,  00310h

  DW 01Fh,  00005h
  DW 01Ah,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00004h
  DW 01Ch,  00000h
  DW 01Fh,  00000h

  DW 01Fh,  00001h
  DW 015h,  07701h
  DW 01Fh,  00000h
  DW -1

Config8402:
  DW 01Fh,  00000h
  DW 018h,  00310h

  DW 01Fh,  00004h
  DW 010h,  0401Fh
  DW 019h,  07030h
  DW 01Fh,  00000h
  DW -1

Config8106e:
  DW 01Fh,  00000h
  DW 018h,  00310h
  DW 400h,  OFFSET Wait100ms

  DW 300h,  001B0h
  DD ERIAR_MASK_0011,  00000h

  DW 01Fh,  00004h
  DW 010h,  0C07Fh
  DW 019h,  07030h
  DW 01Fh,  00000h

  DW 300h,  001D0h
  DD ERIAR_MASK_0011,  00000h
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
ct12 DW OFFSET Config8168bef
ct13 DW OFFSET ConfigNone
ct14 DW OFFSET ConfigNone
ct15 DW OFFSET ConfigNone
ct16 DW OFFSET ConfigNone
ct17 DW OFFSET Config8168bef
ct18 DW OFFSET Config8168cp1
ct19 DW OFFSET Config8168c1
ct20 DW OFFSET Config8168c2
ct21 DW OFFSET Config8168c3
ct22 DW OFFSET ConfigNone
ct23 DW OFFSET Config8168cp2
ct24 DW OFFSET Config8168cp2
ct25 DW OFFSET Config8168d1_d2
ct26 DW OFFSET Config8168d1_d2
ct27 DW OFFSET Config8168d3
ct28 DW OFFSET Config8168d4
ct29 DW OFFSET Config8105e
ct30 DW OFFSET Config8105e
ct31 DW OFFSET ConfigNone
ct32 DW OFFSET Config8168e1
ct33 DW OFFSET Config8168e1
ct34 DW OFFSET Config8168e2
ct35 DW OFFSET Config8168f1_f2
ct36 DW OFFSET Config8168f1_f2
ct37 DW OFFSET Config8402
ct38 DW OFFSET Config8411
ct39 DW OFFSET Config8106e
ct40 DW OFFSET Config8168g1
ct41 DW OFFSET ConfigNone
ct42 DW OFFSET Config8168g2
ct43 DW OFFSET Config8168g2
ct44 DW OFFSET Config8168g2
ct45 DW OFFSET Config8168h1
ct46 DW OFFSET Config8168h2
ct47 DW OFFSET Config8168h1
ct48 DW OFFSET Config8168h2
ct49 DW OFFSET Config8168ep1
ct50 DW OFFSET Config8168ep2
ct51 DW OFFSET Config8168ep2

Config  Proc near
    mov si,ds:HwId
    add si,si
    mov si,cs:[si].ConfigTab

cLoop:
    mov ax,cs:[si]
    cmp ah,0
    je cWrite
;
    cmp ah,1
    je cPatch
;
    cmp ah,2
    je cMerge
;
    cmp ah,3
    je cEri
;
    cmp ah,4
    je cCall
;
    cmp ah,5
    je cEriMerge
;        
    jmp cDone

cWrite:
    mov dl,al
    mov ax,cs:[si+2]
    call ds:WritePhyProc
    add si,4
    jmp cLoop

cPatch:
    mov dl,al
    call ds:ReadPhyProc
    or ax,cs:[si+2]
    call ds:WritePhyProc
    add si,4
    jmp cLoop

cMerge:
    mov dl,al
    call ds:ReadPhyProc
    mov cx,cs:[si+4]
    not cx
    and ax,cx
    or ax,cs:[si+2]
    call ds:WritePhyProc
    add si,6
    jmp cLoop

cEri:
    mov bx,cs:[si+2]
    mov ecx,cs:[si+4]
    mov eax,cs:[si+8]
    call WriteEri
    add si,12
    jmp cLoop

cEriMerge:
    mov bx,cs:[si+2]
    xor ecx,ecx
    call ReadEri
;
    mov ecx,cs:[si+8]
    not ecx
    and eax,ecx
    or eax,cs:[si+12]
    mov ecx,cs:[si+4]
    call WriteEri
    add si,16
    jmp cLoop

cCall:
    call word ptr cs:[si+2]
    add si,4
    jmp cLoop

cDone:
    ret
Config  Endp            
    
      
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
    mov dx,ds:IoBase
    add dx,REG_9346CR
    mov al,0C0h
    out dx,al
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
    add dx,REG_CONFIG3
    in al,dx
    or al,40h
    out dx,al
;    
    mov dx,ds:IoBase
    add dx,REG_9346CR
    mov al,0
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
    mov al,0C0h
    mov fs:mem_9346cr,al
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
mt3E DW 07CF0h, 5020h, 51, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt3D DW 07CF0h, 5010h, 50, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt3C DW 07CF0h, 5000h, 49, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt3B DW 07CF0h, 5410h, 46, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt3A DW 07CF0h, 5400h, 45, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt39 DW 07CF0h, 5C80h, 44, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt38 DW 07CF0h, 5090h, 42, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt37 DW 07CF0h, 4C10h, 41, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt36 DW 07CF0h, 4C00h, 40, OFFSET ReadPhy8169g,    OFFSET WritePhy8169g
mt35 DW 07C80h, 4880h, 38, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt34 DW 07CF0h, 4810h, 36, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt33 DW 07CF0h, 4800h, 35, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt32 DW 07C80h, 2C80h, 34, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt31 DW 07CF0h, 2C20h, 33, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt30 DW 07CF0h, 2C10h, 32, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt2F DW 07C80h, 2C00h, 33, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt2E DW 07CF0h, 2830h, 26, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt2D DW 07CF0h, 2810h, 25, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt2C DW 07C80h, 2800h, 26, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt2B DW 07CF0h, 2880h, 27, OFFSET ReadPhy8168dp1,  OFFSET WritePhy8168dp1
mt2A DW 07CF0h, 28A0h, 28, OFFSET ReadPhy8168dp2,  OFFSET WritePhy8168dp2
mt29 DW 07CF0h, 28B0h, 31, OFFSET ReadPhy8168dp2,  OFFSET WritePhy8168dp2
mt28 DW 07CF0h, 3CB0h, 24, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt27 DW 07CF0h, 3C90h, 23, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt26 DW 07CF0h, 3C80h, 18, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt25 DW 07C80h, 3C80h, 24, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt24 DW 07CF0h, 3C00h, 19, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt23 DW 07CF0h, 3C20h, 20, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt22 DW 07CF0h, 3C30h, 21, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt21 DW 07CF0h, 3C40h, 22, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt20 DW 07C80h, 3C00h, 22, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1F DW 07CF0h, 3800h, 12, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1E DW 07CF0h, 3850h, 17, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1D DW 07C80h, 3800h, 17, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1C DW 07C80h, 3000h, 11, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1B DW 07CF0h, 4490h, 39, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt1A DW 07C80h, 4480h, 39, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt19 DW 0FC80h, 4400h, 37, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt18 DW 07CF0h, 40B0h, 30, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt17 DW 07CF0h, 40A0h, 30, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt16 DW 07CF0h, 4090h, 29, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt15 DW 07C80h, 4080h, 30, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt14 DW 07CF0h, 34A0h, 9,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt13 DW 07CF0h, 24A0h, 9,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt12 DW 07CF0h, 3490h, 8,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt11 DW 07CF0h, 2490h, 8,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt10 DW 07CF0h, 3480h, 7,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0F DW 07CF0h, 2480h, 7,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0E DW 07CF0h, 3400h, 13, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0D DW 07CF0h, 3430h, 10, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0C DW 07CF0h, 3420h, 16, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0B DW 07C80h, 3480h, 9,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt0A DW 07C80h, 2480h, 9,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt09 DW 07C80h, 3400h, 16, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt08 DW 0FC80h, 3880h, 15, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt07 DW 0FC80h, 3080h, 14, OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt06 DW 0FC80h, 9800h, 6,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt05 DW 0FC80h, 1800h, 5,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt04 DW 0FC80h, 1000h, 4,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt03 DW 0FC80h, 0400h, 3,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt02 DW 0FC80h, 0080h, 2,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt01 DW 0FC80h, 0000h, 1,  OFFSET ReadPhy8169,     OFFSET WritePhy8169
mt00 DW 00000h, 0000h, 0,  OFFSET ReadPhy8169,     OFFSET WritePhy8169 

IoFindHardware    Proc near
    mov dx,ds:IoBase
    add dx,REG_TCR
    in eax,dx
    shr eax,16
    mov bx,OFFSET mac_tab

iofhLoop:    
    mov dx,ax
    and dx,cs:[bx]
    cmp dx,cs:[bx+2]
    je iofhOk
;
    add bx,10  
    jmp iofhLoop

iofhOk:
    mov ax,cs:[bx+4]
    mov ds:HwId,ax
    mov ax,cs:[bx+6]
    mov ds:ReadPhyProc,ax
    mov ax,cs:[bx+8]
    mov ds:WritePhyProc,ax
    ret
IoFindHardware   Endp

MemFindHardware    Proc near
    mov eax,fs:mem_tcr
    shr eax,16
    mov bx,OFFSET mac_tab

mfhLoop:    
    mov dx,ax
    and dx,cs:[bx]
    cmp dx,cs:[bx+2]
    je mfhOk
;
    add bx,10  
    jmp mfhLoop

mfhOk:
    mov ax,cs:[bx+4]
    mov ds:HwId,ax
    mov ax,cs:[bx+6]
    mov ds:ReadPhyProc,ax
    mov ax,cs:[bx+8]
    mov ds:WritePhyProc,ax
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
    NotifyIrqActivity
    mov si,1
    mov fs:mem_isr,ax
    and ax,di
    or ds:Isr,ax
    test ax,IR_RDU OR IR_FOVW
    jz mniNotOv
;
    CrashGate
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
    NotifyIrqActivity
    mov si,1
    out dx,ax
    and ax,di
    or ds:Isr,ax
    test ax,IR_RDU OR IR_FOVW
    jz ioniNotOv
;
    CrashGate
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
;       PARAMETERS:         BX    PCI handle
;                           DS    Ether sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupInts   Proc near
    push eax
    push ebx
    push ecx
    push edx
    push edi
;    
    mov edi,cs
    mov es,edi
    mov edi,OFFSET NetInt
    mov ah,14h
    SetupPciHandleIrq
;
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
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
    mov dx,ds:HwId
    cmp dx,46
    jne ssUpdate
;
    xor di,di

ssUpdate:
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
    mov ax,5000
    WaitMilliSec
    int 3
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
    mov ax,5000
    WaitMilliSec
    int 3
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
;       PARAMETERS:         EBX:EAX             Physical address
;
;       RETURNS:            BX                  Mem sel
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateMemSel    Proc near
    push eax
    push ecx
    push edx
    push esi
;
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
;
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
CreateMemSel    Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitIoAdapter
;
;           DESCRIPTION:    Init IO adapter
;
;       PARAMETERS:         DS          Ether mem sel
;                           BX          PCI handle
;                           DX          IO base
;                           CX          Type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DriverName1     DB 'Net RTL8169-1',0
DriverName2     DB 'Net RTL8169-2',0

SupervisorName1 DB 'Super RTL8169-1',0
SupervisorName2 DB 'Super RTL8169-2',0

InitIoAdapter   Proc near
    push ds
    push es
    pushad
;    
    mov ds:IoBase,dx
    mov ds:MemSel,0
    mov ds:Gphy,OCP_STD_PHY_BASE
    mov ds:IoCfg,cx
;    
    call SetupInts
    call IoInitHardware
    call IoFindHardware
    call Config
    mov ax,25
    WaitMilliSec
;    
    mov dx,ds:IoBase
    add dx,REG_ISR
    in eax,dx
;
    mov ax,ds
    cmp ax,ether_data_sel
    je iia1
;
    cmp ax,ether_data2_sel
    je iia2
;
    int 3

iia1:
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
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET io_super_thread
    mov edi,OFFSET SupervisorName1
    mov ax,2
    mov cx,1000h
    CreateThread
    jmp iiaDone

iia2:
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
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET io_super_thread
    mov edi,OFFSET SupervisorName2
    mov ax,2
    mov cx,1000h
    CreateThread

iiaDone:
    popad
    pop es
    pop ds
    ret
InitIoAdapter   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitMemAdapter
;
;           DESCRIPTION:    Init IO adapter
;
;       PARAMETERS:         DS          Ether mem sel
;                           BX          PCI handle
;                           EDX:EAX     Phys base
;                           CX          Type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitMemAdapter   Proc near
    push ds
    push es
    pushad
;
    push ebx
    mov ebx,edx
    call CreateMemSel
    mov fs,bx
    mov ds:IoBase,0
    mov ds:MemSel,bx
    mov ds:Gphy,OCP_STD_PHY_BASE
    mov ds:IoCfg,cx
    pop ebx
;    
    call SetupInts
    call MemInitHardware
    call MemFindHardware
    call Config
;
    mov ax,25
    WaitMilliSec
;    
    mov ax,fs:mem_isr
;
    mov ax,ds
    cmp ax,ether_data_sel
    je ima1
;
    cmp ax,ether_data2_sel
    je ima2
;
    int 3

ima1:
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
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET mem_super_thread
    mov edi,OFFSET SupervisorName1
    mov ax,2
    mov cx,1000h
    CreateThread
    jmp imaDone

ima2:
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
    mov bx,ds
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov esi,OFFSET mem_super_thread
    mov edi,OFFSET SupervisorName2
    mov ax,2
    mov cx,1000h
    CreateThread

imaDone:
    popad
    pop es
    pop ds
    ret
InitMemAdapter   Endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;           NAME:           InitPciAdapter
;
;           DESCRIPTION:    Init PCI adapter if found
;
;       PARAMETERS:         BX          Handle
;
;           RETURNS:        NC          Adapter found
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

InitPciAdapter   Proc near
    mov ax,cs
    mov es,ax
    mov ax,ether_data_sel
    mov ds,ax
    mov ds:Handle,0
    mov si,OFFSET PciVendorTab
    xor bx,bx
    mov edi,OFFSET DevName1

init_pci_loop:
    mov dx,cs:[si]
    mov cx,cs:[si+2]
    or dx,dx
    stc
    jz init_pci_done
;
    FindPciDeviceHandle
    jnc init_pci_found
;
    xor bx,bx
    add si,6
    jmp init_pci_loop

init_pci_found:
    LockPciHandle
    jc init_pci_loop
;
    xor al,al
    GetPciBarIo
    jc m_pci1
;    
    mov cx,cs:[si+4]
    call InitIoAdapter
    jmp init_pci_next

m_pci1:
    xor al,al
    GetPciBarPhys
    jc init_pci_loop
;
    mov cx,cs:[si+4]
    call InitMemAdapter

init_pci_next:
    mov ax,ds
    cmp ax,ether_data_sel
    jne init_pci_done
;
    mov ax,ether_data2_sel
    mov ds,ax
    mov edi,OFFSET DevName2
    jmp init_pci_loop

init_pci_done:
    ret
InitPciAdapter   Endp

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
    call InitPciAdapter
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
