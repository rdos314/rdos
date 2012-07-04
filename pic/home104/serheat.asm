#include p16f877a.inc   

	__config 0x3F72

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5
#define PAGEL   BCF 3,6
#define PAGEH   BSF 3,6

NODEID      EQU 1

; Page 0

CurrTmr1    EQU 0x20
SubMs       EQU 0x21
TenMs       EQU 0x22
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

; common area

	org 0

	goto Reset
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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
    movlw 0x64
    movwf TenMs
;
    clrf CurrKeys
    movf PORTD,W
    movwf KeyState
;
    movlw 0x7F
    movwf Da0
    call LoadDa0
;
    movlw 0xFF
    movwf Da1    
    call LoadDa1
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
    goto DebounceOk

ReBounce:
    movf PORTD,W
    movwf KeyState
;
    movlw 0x32    
    movwf StableCnt
    
DebounceOk:
    decf SubMs,F
    btfss STATUS,Z
    return
;
    movlw 0x32
    movwf SubMs
;        
    goto UpdateTenMs

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
; PollControl
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollControl:
    btfss PORTA,0
    return
;
	clrf PORTA
;
	movlw 7
	movwf Count

Preamp:
    btfss PORTA,1
    return
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
    movlw 4
	xorwf Cmd,W
	btfsc STATUS,Z
	call ToggleCmd
;
    movlw 5
	xorwf Cmd,W
	btfsc STATUS,Z
	call ReadCmd

WaitDone:
    call PollHw
	btfsc PORTA,0
	goto WaitDone

WaitHi:
    clrf PORTA

WaitLoopHi:
    call PollHw
	btfsc PORTA,0
	goto WaitLoopHi
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateTenMs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateTenMs:		
    decf TenMs,F
    btfss STATUS,Z
    return
;
    movlw 0x64
    movwf TenMs
    goto UpdateSec
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateSec
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSec:		
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
; LoadDa0/1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadDa0:	
	movlw b'00001001'
	movwf Contr
	movf Da0,W
	movwf DaVal
	goto LoadDa

LoadDa1:	
	movlw b'00001010'
	movwf Contr
	movf Da1,W
	movwf DaVal

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
