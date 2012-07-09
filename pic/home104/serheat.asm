#include p16f877a.inc   

	__config 0x3F72

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5
#define PAGEL   BCF 3,6
#define PAGEH   BSF 3,6

NODEID      EQU 1

FLAG_SERIAL_BIT EQU 0

; Page 0

CurrTmr1    EQU 0x20
SubMs       EQU 0x21
PollId      EQU 0x22
KeyState    EQU 0x23
StableCnt   EQU 0x24
CurrKeys    EQU 0x25

Count       EQU 0x26
Crc         EQU 0x27
Val         EQU 0x28
Temp        EQU 0x29
Bits        EQU 0x2A
Cmd         EQU 0x2B
Chan        EQU 0x2C
Attent      EQU 0x2D

Contr       EQU 0x2E
Da0         EQU 0x2F
Da1         EQU 0x30
Bit         EQU 0x31
DaVal       EQU 0x32

Adl         EQU 0x33
Adh         EQU 0x34
AdConf      EQU 0x35
AdTemp      EQU 0x36

T0		    EQU 0x36
T1		    EQU 0x37
T2		    EQU 0x38

DaVal0      EQU 0x39
DaVal1	    EQU 0x3A

BatIl       EQU 0x3B
BatIh       EQU 0x3C

ChargeIl    EQU 0x3D
ChargeIh    EQU 0x3E

BatUl       EQU 0x3F
BatUh       EQU 0x40

AdVal0l     EQU 0x41
AdVal0h     EQU 0x42

AdVal1l     EQU 0x43
AdVal1h     EQU 0x44

Flags       EQU 0x45

; common area

	org 0

	goto Reset
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Dummy:
    return

HandleCmd:
	movf Cmd,W
	addwf PCL,F
	goto Dummy          ; 0
	goto Dummy          ; 1
	goto HandleRead     ; 2
	goto WriteVal       ; 3
	goto ToggleCmd      ; 4
	goto ReadCmd        ; 5
	goto Dummy          ; 6
	goto Dummy          ; 7

HandleWrite:
	movf Chan,W
	addwf PCL,F
	goto WriteDa0       ; 0
	goto WriteDa1       ; 1
	goto Dummy          ; 2
	goto WriteCharge    ; 3
	goto Dummy          ; 4
	goto Dummy          ; 5
	goto Dummy          ; 6
	goto Dummy          ; 7

HandleRead:
	movf Chan,W
	addwf PCL,F
	goto ReadDa0        ; 0
	goto ReadDa1        ; 1
	goto ReadBatI       ; 2
	goto ReadChargeI    ; 3
	goto ReadBatU       ; 4
	goto ReadAd0        ; 5
	goto ReadAd1        ; 6
	goto Dummy          ; 7

HandlePollAd:
    incf PollId,W
    andlw 0x7
    movwf PollId
    addwf PCL,F
	goto GetBatI        ; 0
	goto GetChargeI     ; 1
	goto GetBatU        ; 2
	goto GetAd0         ; 3
	goto GetAd1         ; 4
	goto Dummy          ; 5
	goto Dummy          ; 6
	goto Dummy          ; 7

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Reset:
	PAGE1
;
    PAGEH
	clrf EECON1
    PAGEL
;	
	movlw b'00000110'
	movwf ADCON1
;
    movlw b'11110011'
	movwf TRISA
;
	movlw b'00000010'
	movwf TRISB
;
	movlw b'00000000'
	movwf TRISC
;
	movlw b'11111111'
	movwf TRISD
;
	movlw b'00000100'
	movwf TRISE
;
	PAGE0
	clrf PORTA
;
	movlw b'00111111'
	movwf PORTB
;
    call ReadEe	
;
	movlw b'00000000'
	movwf PORTE
;
    movlw 1
    movwf T1CON
;
    PAGE1
;
    movlw b'11011000'
    movwf OPTION_REG        
;
    PAGE0
	movf TMR1H,W
	movwf CurrTmr1
;
    movlw 0x32
    movwf SubMs	
;
    clrf PollId
    clrf Flags
;
    clrf CurrKeys
    movf PORTD,W
    movwf KeyState
;
    clrf T0
    clrf T1
    clrf T2
    call WriteDa0
;
    clrf T0
    clrf T1
    clrf T2
    call WriteDa1
;
    call GetBatI
    call GetChargeI
    call GetBatU
    call GetAd0
    call GetAd1
;
    movlw 0x32    
    movwf StableCnt
            
HandleLoop:
    PAGE0
    call PollHw
    call PollControl
    goto HandleLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PollHw
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollHw:
    movf TMR1H,W
	xorwf CurrTmr1,W
    btfsc STATUS,Z
    return
;
	movf TMR1H,W
	movwf CurrTmr1
;
    movf PORTD,W
    xorwf KeyState,W
    btfss STATUS,Z
    goto ReBounce
;
    decfsz StableCnt,F
    goto DebounceOk
;
    call UpdateKeyboard    
    return

ReBounce:
    movf PORTD,W
    movwf KeyState
;
    movlw 0x32    
    movwf StableCnt
    
DebounceOk:
    btfsc Flags,FLAG_SERIAL_BIT
    return
;
    decf SubMs,F
    btfss STATUS,Z
    return
;
    movlw 0x32
    movwf SubMs        
    goto HandlePollAd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WaitClk
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitClk:

WaitClkHi:
    call PollHw
	btfsc PORTA,0
	goto WaitClkHi

WaitClkLow:
    call PollHw
	btfss PORTA,0
	goto WaitClkLow
;
    return	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateVal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateVal:
    movf PORTA,W
	movwf Temp
	btfsc Temp,1
	goto ValSet

ValReset:
    bcf STATUS,C
    goto UpdateDo

ValSet:
    bsf STATUS,C    

UpdateDo:
    rrf Val,F
    rrf Temp,W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateCrc
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateCrc:
    andlw 1
    movwf Bits
;
    clrf Temp
	bcf STATUS,C
	rlf Crc,F
	rlf Temp,W
	xorwf Bits,W
	btfsc STATUS,Z
	return
;
	movlw 0x26
	xorwf Crc,F
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DecodeBits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeBits:
    movwf Count
    incf Count,F
    clrf Bits
    bsf STATUS,C

DecBitLoop:
    rlf Bits,F
	decfsz Count,F
	goto DecBitLoop
;
    movf Bits,W
    return	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ToggleCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ToggleCmd:
    movf Chan,W
    call DecodeBits
;   
    xorwf PORTC,F 
    call WriteEe
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadCmd
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadCmd:
    clrf Attent
;
    movlw 8    
	movwf Count
	movf PORTC,W
	movwf Val
	clrf Crc

ReadValLoop:
    movf Val,W
    call UpdateCrc
;
	rrf Val,F
    btfss STATUS,C
	goto ReadValReset

ReadValSet:
    bsf PORTA,2
    goto ReadValNext

ReadValReset:
    bcf PORTA,2

ReadValNext:
    call WaitClk
;
	btfsc PORTA,1
	return
;
	decfsz Count,F
	goto ReadValLoop
;
	movlw 8
	movwf Count

	movlw 0x5A
	xorwf Crc,F

ReadCrcLoop:
    movf Crc,W
	rrf Crc,F
	btfss STATUS,C
	goto ReadCrcReset

ReadCrcSet:
    bsf PORTA,2
    goto ReadCrcNext

ReadCrcReset:
    bcf PORTA,2

ReadCrcNext:
    call WaitClk
;
	btfsc PORTA,1
	return
;
	decfsz Count,F
    goto ReadCrcLoop
;			
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadDa0/ReadDa1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadDa0:
	movf DaVal0,W
	movwf T2
	clrf T1
	clrf T0

	bcf STATUS,C
	rrf T2,F
	rrf T1,F
	rrf T0,F
	goto ReadValTransfer

ReadDa1:
	movf DaVal1,W
	movwf T2
	clrf T1
	clrf T0

	bcf STATUS,C
	rrf T2,F
	rrf T1,F
	rrf T0,F
	goto ReadValTransfer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadBatI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadBatI:
	movf BatIl,W
	movwf T0
	movf BatIh,W
	movwf T1
	clrf T2
;
    btfss T1,7
    goto ReadValTransfer
;
    movlw 0xFF
    movwf T2
    goto ReadValTransfer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadChargeI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadChargeI:
	movf ChargeIl,W
	movwf T0
	movf ChargeIh,W
	movwf T1
	clrf T2
;
    btfss T1,7
    goto ReadValTransfer
;
    movlw 0xFF
    movwf T2    	
    goto ReadValTransfer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadBatU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadBatU:
	movf BatUl,W
	movwf T0
	movf BatUh,W
	movwf T1
	clrf T2
;
    btfss T1,7
    goto ReadValTransfer
;
    movlw 0xFF
    movwf T2
    goto ReadValTransfer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadAd0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadAd0:
	movf AdVal0l,W
	movwf T0
	movf AdVal0h,W
	movwf T1
	clrf T2
;
    btfss T1,7
    goto ReadValTransfer
;
    movlw 0xFF
    movwf T2
    goto ReadValTransfer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadAd1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadAd1:
	movf AdVal1l,W
	movwf T0
	movf AdVal1h,W
	movwf T1
	clrf T2
;
    btfss T1,7
    goto ReadValTransfer
;
    movlw 0xFF
    movwf T2
    goto ReadValTransfer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadValTransfer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadValTransfer:
    movlw 0x18
	movwf Count
	clrf Crc

ReadRawValLoop:
    movf T0,W
	call UpdateCrc
;
	rrf T2,F
	rrf T1,F
	rrf T0,F
	btfss STATUS,C
	goto ReadRawValReset

ReadRawValSet:
    bsf PORTA,2
    goto ReadRawValNext

ReadRawValReset:
    bcf PORTA,2

ReadRawValNext:
    call WaitClk
	btfsc PORTA,1
	return

ReadRawValCont:
    decfsz Count,F
    goto ReadRawValLoop
;
	movlw 8
	movwf Count
;
	movlw 0xA5
	xorwf Crc,F

ReadRawValCrcLoop:
    movf Crc,W
	rrf Crc,F
	btfss STATUS,C
	goto ReadRawValCrcReset

ReadRawValCrcSet:
    bsf PORTA,2
    goto ReadRawValCrcNext

ReadRawValCrcReset:
    bcf PORTA,2

ReadRawValCrcNext:
    call WaitClk
;
	btfsc PORTA,1
	return

ReadRawValCrcCont:
	decfsz Count,F
	goto ReadRawValCrcLoop
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateRawVal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateRawVal:
    movf PORTA,W
    movwf Temp
;
	btfsc Temp,1
	goto UpdateRawValSet

UpdateRawValReset:
    bcf STATUS,C
    goto UpdateRawValDo

UpdateRawValSet:    
	bsf STATUS,C

UpdateRawValDo:	
	rrf T2,F
	rrf T1,F
	rrf T0,F
	rrf Temp,W
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteVal
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteVal:
    clrf T0
	clrf T1
	clrf T2
	clrf Crc
;
	movlw 6
	movwf Count

WriteRawValLoop1:
    call WaitClk
    call UpdateRawVal
    call UpdateCrc
;
	decfsz Count,F
    goto WriteRawValLoop1
;
	call WaitClk
;
	btfsc PORTA,1
	return

WriteRawNext1:
    movlw 6
	movwf Count

WriteRawValLoop2:
    call WaitClk
    call UpdateRawVal
    call UpdateCrc
;
	decfsz Count,F
	goto WriteRawValLoop2
;
    call WaitClk
;
	btfsc PORTA,1
	return

WriteRawNext2:
	movlw 6
	movwf Count

WriteRawValLoop3:
    call WaitClk
    call UpdateRawVal
    call UpdateCrc
;
	decfsz Count,F
	goto WriteRawValLoop3
;
    call WaitClk
;
	btfsc PORTA,1
	return

WriteRawNext3:
	movlw 6
	movwf Count

WriteRawValLoop4:
    call WaitClk
    call UpdateRawVal
    call UpdateCrc
;
	decfsz Count,F
	goto WriteRawValLoop4
;
    call WaitClk
;
	btfsc PORTA,1
	return

WriteRawNext4:
	movlw 6
	movwf Count
	clrf Val

WriteRawCrcLoop:
    call WaitClk
    call UpdateVal
;
	decfsz Count,F
	goto WriteRawCrcLoop

WriteRawCrcDone:
    call WaitClk
;
	btfsc PORTA,1
	return
	
WriteRawCrcCont:
    bcf STATUS,C
	rrf Val,F
	rrf Val,F
	movf Crc,W
	andlw 0x3F
	xorwf Val,W
    btfss STATUS,Z
	return

WriteRawCrcOk:	
    goto HandleWrite

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PollControl
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollControl:
    btfss PORTA,0
    return
;
    bsf Flags,FLAG_SERIAL_BIT
	clrf PORTA
;
	movlw 7
	movwf Count

Preamp:
    btfss PORTA,1
    goto WaitHi
;    
	call WaitClk
;			
	decfsz Count,F
	goto Preamp
	
WaitSt:
    btfss PORTA,1
    goto StartId	
;
    call WaitClk
	goto WaitSt

StartId:
	clrf Crc
	clrf Val
;	
	movlw 6
	movwf Count

IdLoop:	
    call WaitClk
	call UpdateVal
	call UpdateCrc
;
	decfsz Count,F
    goto IdLoop

IdDone:
    call WaitClk    
;
	btfsc PORTA,1
	goto WaitHi

	bcf STATUS,C
	rrf Val,F
	rrf Val,F
	movlw NODEID
	xorwf Val,W
	btfss STATUS,Z
	goto WaitHi
;
    movlw 6
    movwf Count
    clrf Val

IdCrcLoop:
    call WaitClk
    call UpdateVal
;
	decfsz Count,F
	goto IdCrcLoop

IdCrcDone:
    call WaitClk
	btfsc PORTA,1
	goto WaitHi
;
	bcf STATUS,C
	rrf Val,F
	rrf Val,F
	movf Crc,W
	andlw 0x3F
	xorwf Val,W
	btfss STATUS,Z
	goto WaitHi

	movlw 0xC
	movwf PORTA
;
	movlw 6
	movwf Count
	clrf Val
	clrf Crc

DevLoop:
    call WaitClk
    call UpdateVal
    call UpdateCrc
;
	decfsz Count,F
	goto DevLoop
;
    call WaitClk
	btfsc PORTA,1
	goto WaitHi
;
	bcf STATUS,C
	rrf Val,F
    rrf Val,F
;
	movf Val,W
	andlw 7
	movwf Cmd
;
	movf Val,W
    movwf Chan
	rrf Chan,F
	rrf Chan,F
	rrf Chan,W
	andlw 7
	movwf Chan
;
	movlw 6
	movwf Count
	clrf Val

DevCrcLoop:
    call WaitClk	
	call UpdateVal
;
	decfsz Count,F
	goto DevCrcLoop

DevCrcDone:	
    call WaitClk
;
	btfsc PORTA,1
	goto WaitHi
;
	bcf STATUS,C
	rrf Val,F
    rrf Val,F
	movf Crc,W
	andlw 0x3F
	xorwf Val,W
	btfss STATUS,Z
	goto WaitHi

DevDone:	
    call HandleCmd

WaitDone:
    bcf Flags,FLAG_SERIAL_BIT
    call PollHw
	btfsc PORTA,0
	goto WaitDone

WaitHi:
    bcf Flags,FLAG_SERIAL_BIT
    clrf PORTA

WaitLoopHi:
    call PollHw
	btfsc PORTA,0
	goto WaitLoopHi
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateKeyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateKeyboard:
    movf KeyState,W
    xorwf CurrKeys,W
    andwf KeyState,W
    btfsc STATUS,Z
    goto update_key_done
;    
    xorwf PORTC,F
    call WriteEe

update_key_done:
    movf KeyState,W
    movwf CurrKeys    
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteDa0/1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteDa0:	
	movlw b'00001001'
	movwf Contr
;
	bcf STATUS,C
	rlf T0,F
	rlf T1,F
	rlf T2,F
	btfss STATUS,C
	goto LoadDaPos0
;
	clrf DaVal
	clrf DaVal0
	goto LoadDa

LoadDaPos0:
    movf T2,W
	movwf DaVal
	movwf DaVal0
	goto LoadDa

WriteDa1:	
	movlw b'00001010'
	movwf Contr
;
	bcf STATUS,C
	rlf T0,F
	rlf T1,F
	rlf T2,F
	btfss STATUS,C
	goto LoadDaPos1
;
	clrf DaVal
	clrf DaVal1
	goto LoadDa

LoadDaPos1:
    movf T2,W
	movwf DaVal
	movwf DaVal1

LoadDa:	
	bcf PORTB,7
	call PollHw
	bcf PORTB,5
;
	movlw 8
	movwf Bit

LoadDaContrLoop:
	btfss Contr,7
	goto LoadDaContrRes

LoadDaContrSet:
	bsf PORTB,6
	goto LoadDaContrNext

LoadDaContrRes:
	bcf PORTB,6

LoadDaContrNext:
	rlf Contr,F
	bsf PORTB,7
	call PollHw
	bcf PORTB,7
;
	decfsz Bit,F
	goto LoadDaContrLoop
;
	movlw 8
	movwf Bit

LoadDaDataLoop:
	btfss DaVal,7
	goto LoadDaDataRes

LoadDaDataSet:
	bsf PORTB,6
	goto LoadDaDataNext

LoadDaDataRes:
	bcf PORTB,6

LoadDaDataNext:
	rlf DaVal,F
	bsf PORTB,7
	call PollHw
	bcf PORTB,7
;
	decfsz Bit,F
	goto LoadDaDataLoop
;
	bsf PORTB,5
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteCharge
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteCharge:	
	movf T2,W
	iorwf T0,W
	btfsc STATUS,Z
    goto WriteChargeOff

WriteChargeOn:
    bcf PORTE,1
    return

WriteChargeOff:
    bsf PORTE,1
    return    	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SampleOne
; IN   W   config word
; OUT  adl, adh
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SampleOne:
    bcf PORTB,3
    movwf AdConf
;
    movlw 4
    movwf AdTemp
    goto sample_one_loop1

sample_one_set0:
    bcf PORTB,2
    goto sample_one_clk0

sample_one_loop0:
    bsf PORTB,0
    rlf AdConf,F

sample_one_a_bit0:
    btfsc STATUS,C
    goto sample_one_set1

sample_one_clk0:
    bcf PORTB,0
    decfsz AdTemp,F
    goto sample_one_loop0
;
    goto sample_one_setup_ok

sample_one_set1:
    bsf PORTB,2
    goto sample_one_clk1

sample_one_loop1:
    bsf PORTB,0
    rlf AdConf,F

sample_one_bit1:
    btfss STATUS,C
    goto sample_one_set0

sample_one_clk1:
    bcf PORTB,0
    decfsz AdTemp,F
    goto sample_one_loop1

sample_one_setup_ok:
    bsf PORTB,0
    nop
;
    bcf PORTB,0
    nop
;
    bsf PORTB,0
    clrf Adl
    clrf Adh
    movlw 0xE
    movwf AdTemp
    bsf PORTB,2
;
    bcf PORTB,0

sample_one_loop:
    bcf STATUS,C
    rlf Adl,F
    rlf Adh,F
    bsf PORTB,0
    nop
    nop
    btfsc PORTB,1
    bsf Adl,0
    bcf PORTB,0
    decfsz AdTemp,F
    goto sample_one_loop
;
    movlw 0x1F
    andwf Adh,F
    movlw 0xE0
    btfsc Adh,4
    iorwf Adh,F
;    
    bsf PORTB,3
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetBatI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBatI:
    movlw 0x10
    call SampleOne
;
    movf Adl,W
    movwf BatIl
;
    movf Adh,W
    movwf BatIh
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetChargeI
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetChargeI:
    movlw 0xA0
    call SampleOne
;
    movf Adl,W
    movwf ChargeIl
;
    movf Adh,W
    movwf ChargeIh
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetBatU
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBatU:
    movlw 0xB0
    call SampleOne
;
    movf Adl,W
    movwf BatUl
;
    movf Adh,W
    movwf BatUh
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetAd0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAd0:
    movlw 0x50
    call SampleOne
;
    movf Adl,W
    movwf AdVal0l
;
    movf Adh,W
    movwf AdVal0h
;
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetAd1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetAd1:
    movlw 0x70
    call SampleOne
;
    movf Adl,W
    movwf AdVal1l
;
    movf Adh,W
    movwf AdVal1h
;
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ReadEe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadEe:		
    PAGEH
    clrf EEADR
    PAGE1
    bsf EECON1,RD
    PAGE0
    movf EEDATA,W
    PAGEL
	movwf PORTC
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WriteEe
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WriteEe:	
    PAGEH
    clrf EEADR
	PAGE1
	bsf EECON1,WREN
	PAGE0
	PAGEL
    movf PORTC,W
    PAGEH
	movwf EEDATA
;
    PAGE1
    movlw 0x55
	movwf EECON2
	movlw 0xAA
	movwf EECON2
    bsf EECON1,WR

ChkWrt:		
    btfsc EECON1,WR
	goto ChkWrt

    bcf EECON1,WREN 
 	PAGE0
 	PAGEL
    return

    end
