#include p16f873a.inc   

	__config 0x3F72

#define PAGE0   BCF 3,5
#define PAGE1   BSF 3,5

; FLAG bits

FLAG_CHARGE_ON		EQU 0

; Page 0

SolarLsb    EQU 0x20
SolarMsb    EQU 0x21
BatLsb      EQU 0x22
BatMsb      EQU 0x23
Led         EQU 0x24
AdcChan     EQU 0x25
Flags		EQU 0x26

; page 2

; page 3

	org 0

	goto Reset

	org 0x4

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Reset:
	PAGE0
;
	movlw b'00000000'
	movwf PORTA
;
	movlw b'00000011'
	movwf PORTB
;
	movlw b'00001111'
	movwf PORTC
;
	PAGE1
	movlw b'10000100'
	movwf ADCON1
;
	movlw b'11111111'
	movwf TRISA
;
	movlw b'11111110'
	movwf TRISB
;
	movlw b'11110000'
	movwf TRISC
;
	PAGE0
    movlw b'00000001'
    movwf T1CON
;
    PAGE1
    movlw b'11011000'
    movwf OPTION_REG
;
    PAGE0
    movlw b'00000000'
    movwf INTCON      
;
    clrf AdcChan    
	clrf Flags

HandleLoop:
    call GetSolarVoltage
    call GetBatVoltage
    call UpdateLoad
    call UpdateRegulator
;
    PAGE0
    movf BatMsb,W
    movwf Led
    rlf Led,F
    rlf Led,F
    movlw b'00001100'
    andwf Led,F
;    
    movf SolarMsb,W
    andlw b'00000011'
    iorwf Led,F
;
    movf PORTC,W
    andlw b'11110000'
    iorwf Led,W
	xorlw b'00001111'
    movwf PORTC    
    goto HandleLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetSolarVoltage
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSolarVoltage:
    PAGE0
    movlw b'10000001'
    movwf ADCON0
;
    btfsc AdcChan,0
    goto gsvStart
;
    call WaitAdcSettle
    movlw b'00000001'
    movwf AdcChan

gsvStart:
    bsf ADCON0,2

gsvWait:
    btfsc ADCON0,2
    goto gsvWait
;
    PAGE1
    movf ADRESL,W
    PAGE0
    movwf SolarLsb
    movf ADRESH,W
    movwf SolarMsb
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetBatVoltage
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetBatVoltage:
    PAGE0
    movlw b'10001001'
    movwf ADCON0
;
    btfsc AdcChan,1
    goto gbvStart
;
    call WaitAdcSettle
    movlw b'00000010'
    movwf AdcChan

gbvStart:
    bsf ADCON0,2

gbvWait:
    btfsc ADCON0,2
    goto gbvWait
;
    PAGE1
    movf ADRESL,W
    PAGE0
    movwf BatLsb
    movf ADRESH,W
    movwf BatMsb
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; WaitAdcSettle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitAdcSettle:
    PAGE0
    bcf T1CON,0
    movlw 0xFF
    movwf TMR1H
    movlw 0x90
    movwf TMR1L
    bcf PIR1,0
    bsf T1CON,0    

wasLoop:
    btfss PIR1,0
    goto wasLoop
;
    return    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateLoad
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateLoad:
    PAGE0
    movf SolarMsb,F
    btfss STATUS,Z
    goto SetLoad

ClearLoad:
    PAGE1
	bsf TRISB,1
    goto LoadDone

SetLoad:
    PAGE1
	bcf TRISB,1

LoadDone:
	PAGE0
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UpdateRegulator
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateRegulator:
    PAGE0
    btfsc Flags,FLAG_CHARGE_ON
    goto RegChargeOn

RegChargeOff:
    movf BatMsb,F
    btfss STATUS,Z
    return
;
    movf SolarMsb,F
    btfss STATUS,Z
    goto StartCharge
;
	movlw 8
	addwf SolarLsb,W
    btfss STATUS,C
    return
	goto StartCharge

RegChargeOn:
    movf BatMsb,F
    btfss STATUS,Z
    goto StopCharge
;
    movf SolarMsb,F
    btfss STATUS,Z
    return
;
	movlw 0x10
	addwf SolarLsb,W
    btfsc STATUS,C
    return
	goto StopCharge

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; StartCharge
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StartCharge:
	PAGE1
	bsf TRISB,0
;
    PAGE0
	bsf Flags,FLAG_CHARGE_ON
	return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; StopCharge
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

StopCharge:
	PAGE1
	bcf TRISB,0
;
    PAGE0
	bcf Flags,FLAG_CHARGE_ON
	return

    end
