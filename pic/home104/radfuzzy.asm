;RADLED.ASM

#DEFINE PAGE0   BCF $03,5
#DEFINE PAGE1   BSF $03,5

INDF:	.EQU 0
PCL:    .EQU 2
STATUS: .EQU 3
FSR:	.EQU 4
PORTA:  .EQU 5
PORTB:  .EQU 6
TRISA:  .EQU 5
TRISB:  .EQU 6

W:      .EQU 0          ;Working
F:      .EQU 1          ;File
C:      .EQU 0          ;Carry
Z:      .EQU 2          ;Zero

EEDATA: .EQU $08        ;eeprom data value register
EECON1: .EQU $08        ;eeprom write register 1
EEADR:  .EQU $09        ;eeprom data address register
EECON2: .EQU $09        ;eeprom write register 2

WR:     .EQU 1          ;eeprom write initiate flag
WREN:   .EQU 2          ;eeprom write enable flag
RD:     .EQU 0          ;eeprom read enable flag

INTCON: .EQU $0B

RefVal	    .EQU $0F
TempVal		.EQU $10
MotorVal	.EQU $11
AmbientVal  .EQU $12
Da1			.EQU $13
Reg			.EQU $14
Val			.EQU $15
Bit			.EQU $16
Contr		.EQU $17

TempSumLow	.EQU $18
TempSumHigh	.EQU $19
TempRemain	.EQU $1A

FuzzyIndex	.EQU $1D
FuzzyCount	.EQU $1E
FuzzyVal	.EQU $1F

TempError	.EQU $22
TempDelta	.EQU $23
Ambient		.EQU $24

ErrorIndex	.EQU $25
DeltaIndex	.EQU $26
AmbientIndex .EQU $27

FuzzyTemp	.EQU $28
Resultant	.EQU $29

NumLow		.EQU $2A
NumHigh		.EQU $2B
DenomLow	.EQU $2C
DenomHigh	.EQU $2D
NumDivLow	.EQU $2E
NumDivHigh	.EQU $2F

PrevErrorIndex	.EQU $30

	.ORG 4
 	.ORG 5

Reset:
	goto Main

; All PCL relative code must be here (in the first 256 words)

SetVal:
	movf Reg,W
	addwf PCL,F
	goto SetRef	    	; 0
	goto SetTemp	    ; 1
	return		    	; 2
	return	    		; 3
	goto SetAmbient	    ; 4
	return		    	; 5
	return	    		; 6
	goto UpdateFuzzy    ; 7

GetVal:	
	movf Reg,W
	addwf PCL,F
	goto GetRef 		; 0
	goto GetTemp    	; 1
	goto GetMotor	    ; 2
	return	    		; 3
	goto GetAmbient  	; 4
	return			    ; 5
	return	    		; 6
	return		    	; 7

RuleNLC:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPXL
	goto TempOutputPXL
	goto TempOutputPXL
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM

RuleNMC:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPXL
	goto TempOutputPXL
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNL

RuleZC:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPXL
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNL
	goto TempOutputNXL

RulePMC:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNL
	goto TempOutputNXL
	goto TempOutputNXL

RulePLC:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNL
	goto TempOutputNXL
	goto TempOutputNXL
	goto TempOutputNXL

RuleC:
	movf TempDelta, W
	addwf PCL, F
	goto RuleNLC
	goto RuleNMC
	goto RuleZC
	goto RulePMC
	goto RulePLC

RuleNLM:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPXL
	goto TempOutputPXL
	goto TempOutputPL
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM

RuleNMM:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPXL
	goto TempOutputPL
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNL

RuleZM:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPXL
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNL
	goto TempOutputNXL

RulePMM:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNL
	goto TempOutputNL
	goto TempOutputNXL

RulePLM:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNL
	goto TempOutputNL
	goto TempOutputNXL
	goto TempOutputNXL

RuleM:
	movf TempDelta, W
	addwf PCL, F
	goto RuleNLM
	goto RuleNMM
	goto RuleZM
	goto RulePMM
	goto RulePLM

RuleNLH:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPXL
	goto TempOutputPL
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM

RuleNMH:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPL
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNM

RuleZH:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPL
	goto TempOutputPM
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNM
	goto TempOutputNL

RulePMH:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPM
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNM
	goto TempOutputNL
	goto TempOutputNL

RulePLH:
	movf TempError, W
	addwf PCL, F
	goto TempOutputPM
	goto TempOutputZ
	goto TempOutputNM
	goto TempOutputNM
	goto TempOutputNL
	goto TempOutputNL
	goto TempOutputNXL

RuleH:
	movf TempDelta, W
	addwf PCL, F
	goto RuleNLH
	goto RuleNMH
	goto RuleZH
	goto RulePMH
	goto RulePLH

CalcTempRule:
	movf Ambient, W
	addwf PCL, F
	goto RuleC
	goto RuleM
	goto RuleH

CalcTempError:
	movf TempError, W
	addwf PCL, F
	goto TempErrorNXL
	goto TempErrorNL
	goto TempErrorNM
	goto TempErrorZ
	goto TempErrorPM
	goto TempErrorPL
	goto TempErrorPXL

CalcTempDelta:
	movf TempDelta, W
	addwf PCL, F
	goto TempDeltaErrorNL
	goto TempDeltaErrorNM
	goto TempDeltaErrorZ
	goto TempDeltaErrorPM
	goto TempDeltaErrorPL

CalcTempAmbient:
	movf Ambient, W
	addwf PCL, F
	goto TempAmbientC
	goto TempAmbientM
	goto TempAmbientH

CalcLowSlope:
	incf FuzzyCount, F
CalcMidLowSlope:
	clrf FuzzyVal
CalcLowLoop:
	addwf FuzzyVal, F
	decfsz FuzzyCount, F
	goto CalcLowLoop
;
	comf FuzzyVal, W
	return

CalcMidHighSlope:
	clrf FuzzyVal
CalcMidHighLoop:
	addwf FuzzyVal, F
	incfsz FuzzyCount, F
	goto CalcMidHighLoop
;
	comf FuzzyVal, W
	return

CalcHighSlope:
	clrf FuzzyVal
CalcHighLoop:
	addwf FuzzyVal, F
	decfsz FuzzyCount, F
	goto CalcHighLoop
;
	comf FuzzyVal, W
	return

TempErrorNXL:
	movf ErrorIndex, W
	sublw 88
	btfss STATUS, C
	retlw 0
	sublw 50
	btfss STATUS, C
	retlw 255
	movwf FuzzyCount
	movlw 5
	goto CalcLowSlope

TempErrorNL:
	movf ErrorIndex, W
	sublw 120
	btfss STATUS, C
	retlw 0
	sublw 54
	btfss STATUS, C
	retlw 0
	sublw 31
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 8
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 11
	goto CalcMidHighSlope

TempErrorNM:
	movf ErrorIndex, W
	sublw 126
	btfss STATUS, C
	retlw 0
	sublw 17
	btfss STATUS, C
	retlw 0
	sublw 6
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 42
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 23
	goto CalcMidHighSlope

TempErrorZ:
	movf ErrorIndex, W
	sublw 136
	btfss STATUS, C
	retlw 0
	sublw 18
	btfss STATUS, C
	retlw 0
	sublw 9
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 28
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 28
	goto CalcMidHighSlope

TempErrorPM:
	movf ErrorIndex, W
	sublw 141
	btfss STATUS, C
	retlw 0
	sublw 12
	btfss STATUS, C
	retlw 0
	sublw 7
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 32
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 51
	goto CalcMidHighSlope

TempErrorPL:
	movf ErrorIndex, W
	sublw 167
	btfss STATUS, C
	retlw 0
	sublw 33
	btfss STATUS, C
	retlw 0
	sublw 12
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 21
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 12
	goto CalcMidHighSlope

TempErrorPXL:
	movf ErrorIndex, W
	sublw 186
	btfss STATUS, C
	retlw 255
	sublw 30
	btfss STATUS, C
	retlw 0
	sublw 31
	movwf FuzzyCount
	movlw 8
	goto CalcHighSlope

TempDeltaErrorNL:
	movf DeltaIndex, W
	sublw 122
	btfss STATUS, C
	retlw 0
	sublw 14
	btfss STATUS, C
	retlw 255
	movwf FuzzyCount
	movlw 17
	goto CalcLowSlope

TempDeltaErrorNM:
	movf DeltaIndex, W
	sublw 127
	btfss STATUS, C
	retlw 0
	sublw 13
	btfss STATUS, C
	retlw 0
	sublw 6
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 42
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 36
	goto CalcMidHighSlope

TempDeltaErrorZ:
	movf DeltaIndex, W
	sublw 128
	btfss STATUS, C
	retlw 0
	sublw 2
	btfss STATUS, C
	retlw 0
	sublw 1
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 128
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 255
	goto CalcMidHighSlope

TempDeltaErrorPM:
	movf DeltaIndex, W
	sublw 134
	btfss STATUS, C
	retlw 0
	sublw 6
	btfss STATUS, C
	retlw 0
	sublw 3
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 64
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 64
	goto CalcMidHighSlope

TempDeltaErrorPL:
	movf DeltaIndex, W
	sublw 138
	btfss STATUS, C
	retlw 255
	sublw 8
	btfss STATUS, C
	retlw 0
	sublw 9
	movwf FuzzyCount
	movlw 28
	goto CalcHighSlope

TempAmbientC:
	movf AmbientIndex, W
	sublw 111
	btfss STATUS, C
	retlw 0
	sublw 8
	btfss STATUS, C
	retlw 255
	movwf FuzzyCount
	movlw 26
	goto CalcLowSlope

TempAmbientM:
	movf AmbientIndex, W
	sublw 121
	btfss STATUS, C
	retlw 0
	sublw 14
	btfss STATUS, C
	retlw 0
	sublw 5
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 51
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 26
	goto CalcMidHighSlope

TempAmbientH:
	movf AmbientIndex, W
	sublw 121
	btfss STATUS, C
	retlw 255
	sublw 4
	btfss STATUS, C
	retlw 0
	sublw 5
	movwf FuzzyCount
	movlw 51
	goto CalcHighSlope

TempOutputNXL:
	movf FuzzyIndex, W
	sublw 9
	btfss STATUS, C
	retlw 0
	sublw 4
	btfss STATUS, C
	retlw 255
	movwf FuzzyCount
	movlw 51
	goto CalcLowSlope

TempOutputNL:
	movf FuzzyIndex, W
	sublw 15
	btfss STATUS, C
	retlw 0
	sublw 8
	btfss STATUS, C
	retlw 0
	sublw 1
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 128
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 36
	goto CalcMidHighSlope

TempOutputNM:
	movf FuzzyIndex, W
	sublw 16
	btfss STATUS, C
	retlw 0
	sublw 6
	btfss STATUS, C
	retlw 0
	sublw 3
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 64
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 85
	goto CalcMidHighSlope

TempOutputZ:
	movf FuzzyIndex, W
	sublw 17
	btfss STATUS, C
	retlw 0
	sublw 2
	btfss STATUS, C
	retlw 0
	sublw 1
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 128
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 255
	goto CalcMidHighSlope

TempOutputPM:
	movf FuzzyIndex, W
	sublw 21
	btfss STATUS, C
	retlw 0
	sublw 4
	btfss STATUS, C
	retlw 0
	sublw 1
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 128
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 85
	goto CalcMidHighSlope

TempOutputPL:
	movf FuzzyIndex, W
	sublw 26
	btfss STATUS, C
	retlw 0
	sublw 6
	btfss STATUS, C
	retlw 0
	sublw 1
	btfsc STATUS, Z
	retlw 255
	movwf FuzzyCount
	movlw 128
	btfsc STATUS, C
	goto CalcMidLowSlope
	movlw 51
	goto CalcMidHighSlope

TempOutputPXL:
	movf FuzzyIndex, W
	sublw 27
	btfss STATUS, C
	retlw 255
	sublw 4
	btfss STATUS, C
	retlw 0
	sublw 5
	movwf FuzzyCount
	movlw 51
	goto CalcHighSlope

UpdateFuzzy:
    movf RefVal,W
    subwf AmbientVal,W
    addlw 127
    movwf AmbientIndex
;    
    movf RefVal,W
	subwf TempVal, W
	addlw 127
	movwf ErrorIndex
;
	movf PrevErrorIndex, W
	subwf ErrorIndex, W
	addlw 127
	movwf DeltaIndex
;
	movf ErrorIndex, W
	movwf PrevErrorIndex
;
	clrf FuzzyIndex
	clrf DenomLow
	clrf DenomHigh
	clrf NumLow
	clrf NumHigh

UpdateFuzzyIndex:
	clrf Resultant
	clrf TempError
	clrf TempDelta
	clrf Ambient

UpdateFuzzyLoop:
	call CalcTempError
	movwf FuzzyTemp
	movf FuzzyTemp, W
	btfsc STATUS, Z
	goto UpdateFuzzyNext

UpdateFuzzyDelta:
	call CalcTempDelta
	subwf FuzzyTemp, W
	btfss STATUS, C
	goto UpdateFuzzyAmbient
;
	subwf FuzzyTemp, W
	movwf FuzzyTemp
	movf FuzzyTemp, W
	btfsc STATUS, Z
	goto UpdateFuzzyNext

UpdateFuzzyAmbient:
	call CalcTempAmbient
	subwf FuzzyTemp, W
	btfss STATUS, C
	goto UpdateFuzzyOutput
;
	subwf FuzzyTemp, W
	movwf FuzzyTemp
	movf FuzzyTemp, W
	btfsc STATUS, Z
	goto UpdateFuzzyNext

UpdateFuzzyOutput:
	call CalcTempRule
	subwf FuzzyTemp, W
	btfss STATUS, C
	goto UpdateFuzzyResult
;
	subwf FuzzyTemp, W
	movwf FuzzyTemp

UpdateFuzzyResult:
	movf FuzzyTemp, W
	subwf Resultant, W
	btfsc STATUS, C
	goto UpdateFuzzyNext
;
	movf FuzzyTemp, W
	movwf Resultant

UpdateFuzzyNext:
	incf TempError, F
	movf TempError, W
	sublw 7
	btfss STATUS, Z
	goto UpdateFuzzyLoop
;
	clrf TempError
	incf TempDelta, F
	movf TempDelta, W
	sublw 5
	btfss STATUS, Z
	goto UpdateFuzzyLoop
;
	clrf TempDelta
	incf Ambient, F
	movf Ambient, W
	sublw 3
	btfss STATUS, Z
	goto UpdateFuzzyLoop
;
	movf FuzzyIndex, W
	btfsc STATUS, Z
	goto NumDone
;
	movwf FuzzyTemp
	movf Resultant, W

NumLoop:
	addwf NumLow, F
	btfsc STATUS, C
	incf NumHigh, F
	decfsz FuzzyTemp, F
	goto NumLoop

NumDone:
	movf Resultant, W
	addwf DenomLow, F
	btfsc STATUS, C
	incf DenomHigh, F
;
	incf FuzzyIndex, F
	movf FuzzyIndex, W
	sublw 33
	btfss STATUS, Z
	goto UpdateFuzzyIndex

DenomDownLoop:
	movf DenomHigh, F
	btfsc STATUS, Z
	goto DenomUpLoop
;
	bcf STATUS, C
	rrf DenomHigh, F
	rrf DenomLow, F
;
	bcf STATUS, C
	rrf NumHigh, F
	rrf NumLow, F
	goto DenomDownLoop

DenomUpLoop:
	btfsc DenomLow, 7
	goto DenomOk
;
	bsf STATUS, C
	rlf DenomLow, F
;
	bsf STATUS, C
	rlf NumLow, F
	rlf NumHigh, F
	goto DenomUpLoop

DenomOk:
	movf NumHigh, W
	movwf NumDivHigh
	movf NumLow, W
	movwf NumDivLow
	movf DenomLow, W
	movwf DenomHigh

DivLoop:
	bcf STATUS, C
	rrf DenomHigh, F
;
	bcf STATUS, C
	rrf NumDivHigh, F
	rrf NumDivLow, F
;
	movf DenomHigh, W
	addwf DenomLow, W
	btfsc STATUS, C
	goto DivNext
;
	movwf DenomLow
	movf NumDivLow, W
	addwf NumLow, F
	btfsc STATUS, C
	incf NumHigh, F
	movf NumDivHigh, W
	addwf NumHigh, F

DivNext:
	movf DenomHigh, F
	btfss STATUS, Z
	goto DivLoop
;
	movf NumHigh, W
	sublw 16
	btfsc STATUS, C
	goto IncMotor
;
DecMotor:
	addwf MotorVal, F
	btfss STATUS, C
	clrf MotorVal
	goto MotorDone

IncMotor:
	addwf MotorVal, F
	btfss STATUS, C
	goto MotorDone
;
	movlw 255
	movwf MotorVal

MotorDone:
    call LoadMotor0
	return

Main:
	PAGE1
	movlw %11110000
	movwf TRISB
	PAGE0

	movlw %00001100
	movwf PORTB
;
	clrf RefVal
	clrf TempVal
	clrf Da1
;
	movlw 127
	movwf ErrorIndex
	movwf PrevErrorIndex
	movwf DeltaIndex
	movwf AmbientIndex
	clrf MotorVal

LP:
	call Wait
	goto LP

WaitClk:
WaitClkHi:
	btfss PORTB,7
	return

	btfsc PORTB,4
	goto WaitClk

WaitClkLow:
	btfss PORTB,7
	return

	btfss PORTB,4
	goto WaitClkLow

	return

SetRef:	
	movf Val,W
	movwf RefVal
	return

SetTemp:
	movf Val,W
	movwf TempVal
	return

SetAmbient:
	movf Val,W
	movwf AmbientVal
	return

GetRef:
	movf RefVal,W
	movwf Val
	return

GetTemp:
	movf TempVal,W
	movwf Val
	return

GetMotor:
	movf MotorVal,W
	movwf Val
	return

GetAmbient:
	movf AmbientVal,W
	movwf Val
	return
			
Wait:		
	btfss PORTB,7
	goto Wait
;			
	PAGE1
	movlw %10110000
	movwf TRISB
	PAGE0
;
	clrf Val
	clrf Reg

	call WaitClk
	btfss PORTB,5
	goto WaitRec

WaitSend:
	call WaitClk
	btfsc PORTB,5
	bsf Reg,0

	call WaitClk
	btfsc PORTB,5
	bsf Reg,1

	call WaitClk
	btfsc PORTB,5
	bsf Reg,2
;
	call WaitClk
	btfsc PORTB,5
	bsf Val,0

	call WaitClk
	btfsc PORTB,5
	bsf Val,1

	call WaitClk
	btfsc PORTB,5
	bsf Val,2

	call WaitClk
	btfsc PORTB,5
	bsf Val,3

	call WaitClk
	btfsc PORTB,5
	bsf Val,4

	call WaitClk
	btfsc PORTB,5
	bsf Val,5

	call WaitClk
	btfsc PORTB,5
	bsf Val,6

	call WaitClk
	btfsc PORTB,5
	bsf Val,7

	btfss PORTB,7
	goto WaitEnd

	call SetVal
	goto WaitEnd

WaitRec:
	call WaitClk
	btfsc PORTB,5
	bsf Reg,0

	call WaitClk
	btfsc PORTB,5
	bsf Reg,1

	call WaitClk
	btfsc PORTB,5
	bsf Reg,2
;
	call GetVal
;
	movlw 8
	movwf Bit

	btfss PORTB,7
	goto WaitEnd

WaitRecLoop:
	btfss Val,0
	goto WaitRecReset

	bsf PORTB,6
	goto WaitRecShift

WaitRecReset:
	bcf PORTB,6

WaitRecShift:
	rrf Val,F

WaitRecHi:
	btfss PORTB,7
	goto WaitEnd

	btfsc PORTB,4
	goto WaitRecHi

WaitRecLow:	
	btfss PORTB,7
	goto WaitEnd

	btfss PORTB,4
	goto WaitRecLow

	decfsz Bit,F
	goto WaitRecLoop

WaitEnd:
	PAGE1
	movlw %11110000
	movwf TRISB
	PAGE0

WaitHi:
	btfss PORTB,7
	return
	goto WaitHi

Delay:		
	return

LoadMotor0:	
	movlw %00001001
	movwf Contr
	movf MotorVal,W
	movwf Val
	goto LoadMotor

LoadMotor1:	
	movlw %00001010
	movwf Contr
	movf Da1,W
	movwf Val

LoadMotor:	
	bcf PORTB,0
	call Delay
	bcf PORTB,2
;
	movlw 8
	movwf Bit

LoadContrLoop:
	btfss Contr,7
	goto LoadContrRes

LoadContrSet:
	bsf PORTB,1
	goto LoadContrNext

LoadContrRes:
	bcf PORTB,1

LoadContrNext:
	rlf Contr,F
	bsf PORTB,0
	call Delay
	bcf PORTB,0
;
	decfsz Bit,F
	goto LoadContrLoop
;
	movlw 8
	movwf Bit

LoadDataLoop:
	btfss Val,7
	goto LoadDataRes

LoadDataSet:
	bsf PORTB,1
	goto LoadDataNext

LoadDataRes:
	bcf PORTB,1

LoadDataNext:
	rlf Val,F
	bsf PORTB,0
	call Delay
	bcf PORTB,0
;
	decfsz Bit,F
	goto LoadDataLoop
;
	bsf PORTB,2
	return

        .END
