#include p16f877a.inc   

	__config 0x3F72

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5
#define PAGEL   BCF 3,6
#define PAGEH   BSF 3,6

; Page 0

CurrTmr1    EQU 0x20
SubMs       EQU 0x21
TenMs       EQU 0x22
KeyState    EQU 0x23
StableCnt   EQU 0x24
CurrKeys    EQU 0x25

Val:        EQU 0x26

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
;
	movlw b'00000000'
	movwf PORTA
;
	movlw b'11111111'
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
    movlw 0x32    
    movwf StableCnt
            
HandleLoop:
    PAGE0
    movf TMR1H,W
	xorwf CurrTmr1,W
    btfsc STATUS,Z
    goto HandleLoop
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
    goto HandleLoop
;
    movlw 0x32
    movwf SubMs
;        
    call UpdateTenMs
    goto HandleLoop

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
