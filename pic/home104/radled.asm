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

TEMP		.EQU $0F
COUNT		.EQU $10
V0			.EQU $11
V1			.EQU $12
D0			.EQU $13
D1			.EQU $14
D2			.EQU $15
REF			.EQU $16
AD0			.EQU $17
AD1			.EQU $18
SumLow1		.EQU $19
SumHi1		.EQU $1A
TEM0		.EQU $1B
TEM1		.EQU $1C
MOT			.EQU $1D
REG			.EQU $1E
VAL			.EQU $1F
BIT			.EQU $20
INTEN		.EQU $21
AdcLsb		.EQU $22
AdcMsb		.EQU $23


	        .ORG 4
    	    .ORG 5

RESET:		PAGE1
			movlw $18
			movwf TRISA

			movlw %11110010
			movwf TRISB
			PAGE0
			clrf PORTA
;
			movlw %00001000
			movwf PORTB
;
			clrf REF
;
			movlw 40
			movwf TEM0
			clrf TEM1
;
			clrf SumLow1
			clrf SumHi1
;
			movlw $C0
			movwf MOT
;
			movlw 12
			movwf INTEN

LP:			call Wait
			call INITLED
			call WRITEREF
			call WRITETEM
			call WRITEMOT
			goto LP

STOP:		goto STOP
			
GETSEG:		andlw $F
			addwf PCL,F
			retlw %01111110	; 0
			retlw %00110000 ; 1
			retlw %01101101 ; 2
			retlw %01111001 ; 3
			retlw %00110011 ; 4
			retlw %01011011 ; 5
			retlw %01011111 ; 6
			retlw %01110000 ; 7
			retlw %01111111 ; 8
			retlw %01111011 ; 9
			retlw %01110111 ; A
			retlw %00011111 ; B
			retlw %01001110 ; C
			retlw %00111101 ; D
			retlw %01001111 ; E
			retlw %01000111 ; F

GETMOT10:	andlw $F
			addwf PCL,F
			retlw 0	  ; 0.0
			retlw 25  ; 1.0
			retlw 50  ; 2.0
			retlw 75  ; 3.0
			retlw 100 ; 4.0
			retlw 125 ; 5.0
			retlw 150 ; 6.0
			retlw 175 ; 7.0
			retlw 200 ; 8.0
			retlw 225 ; 9.0
			retlw 250 ; 10.0
			retlw 255 

GETMOT1:	andlw $F
			addwf PCL,F
			retlw 0	  ; 0.0
			retlw 3	  ; 0.1
			retlw 5	  ; 0.2
			retlw 8   ; 0.3
			retlw 10  ; 0.4
			retlw 13  ; 0.5
			retlw 15  ; 0.6
			retlw 18  ; 0.7
			retlw 20  ; 0.8
			retlw 23  ; 0.9			
			retlw 255

SetVal:		movf REG,W
			addwf PCL,F
			goto SetRef		; 0
			return			; 1
			goto SetMotor	; 2
			goto SetInten	; 3
			return			; 4
			return			; 5
			return			; 6
			goto GetAdc		; 7

GetVal:		movf REG,W
			addwf PCL,F
			goto GetRef		; 0
			goto GetTemp	; 1
			goto GetMotor	; 2
			return			; 3
			return			; 4
			return			; 5
			return			; 6
			return			; 7

INITLED:	movlw $C
			call SENDBYTE
			movlw 1
			call SENDBYTE
			call LOADLED
;
			movlw $9
			call SENDBYTE
			movlw 0
			call SENDBYTE
			call LOADLED
;
			movlw $A
			call SENDBYTE
			movf INTEN,W
			call SENDBYTE
			call LOADLED
;
			movlw $B
			call SENDBYTE
			movlw 7
			call SENDBYTE
			call LOADLED
			return

WRITEREF:	movf REF,W
			movwf V0
			clrf V1
			call DECODE
;
			movlw $1
			call SENDBYTE
			movf D2,W
			btfss STATUS,Z
			goto WRREFSEG
;
			movlw 0
			goto WRREFDO
			
WRREFSEG:	call GETSEG
WRREFDO:	call SENDBYTE
			call LOADLED
;
			movlw $2
			call SENDBYTE
			movf D1,W
			call GETSEG
			addlw $80
			call SENDBYTE
			call LOADLED
;
			movlw $3
			call SENDBYTE
			movf D0,W
			call GETSEG
			call SENDBYTE
			call LOADLED
			return

WRITETEM:	movf TEM0,W
			movwf V0
			movf TEM1,W
			movwf V1
			call DECODE
;
			movlw $4
			call SENDBYTE
			movf D2,W
			btfss STATUS,Z
			goto WRTEMSEG
;
			movlw 0
			goto WRTEMDO
			
WRTEMSEG:	call GETSEG
WRTEMDO:	call SENDBYTE
			call LOADLED
;
			movlw $5
			call SENDBYTE
			movf D1,W
			call GETSEG
			addlw $80
			call SENDBYTE
			call LOADLED
;
			movlw $6
			call SENDBYTE
			movf D0,W
			call GETSEG
			call SENDBYTE
			call LOADLED
			return

WRITEMOT:	call DECMOT
;
			movlw $7
			call SENDBYTE
			movf D1,W
			call GETSEG
			addlw $80
			call SENDBYTE
			call LOADLED
;
			movlw $8
			call SENDBYTE
			movf D0,W
			call GETSEG
			call SENDBYTE
			call LOADLED
			return

AdcDelay:	return

ReadAdc0:	movlw %10001000
			goto ReadAdc

ReadAdc1:	movlw %10011000

ReadAdc:	movwf TEMP
			movlw 7
			movwf COUNT
;
			movlw %00001100
			movwf PORTB
			call AdcDelay
;
			bcf PORTB,3
			call AdcDelay

AdcControlLoop:
			btfss TEMP,7
			goto ResAdcControl

SetAdcControl:
			bsf PORTB,2
			goto NextAdcControl

ResAdcControl:
			bcf PORTB,2
			
NextAdcControl:
			rlf TEMP,F
;
			bsf PORTB,0
			call AdcDelay
;
			bcf PORTB,0
;
			decfsz COUNT,F
			goto AdcControlLoop
;
			clrf AdcMsb
			movlw 4
			movwf COUNT

AdcMsbLoop:
			bcf STATUS,C
			rlf AdcMsb,F
;
			btfsc PORTB,1
			bsf AdcMsb,0
;
			bsf PORTB,0
			call AdcDelay
			bcf PORTB,0
;
			decfsz COUNT,F
			goto AdcMsbLoop

			clrf AdcLsb
			movlw 8
			movwf COUNT

AdcLsbLoop:
			bcf STATUS,C
			rlf AdcLsb,F
;
			btfsc PORTB,1
			bsf AdcLsb,0
;
			bsf PORTB,0
			call AdcDelay
			bcf PORTB,0
;
			decfsz COUNT,F
			goto AdcLsbLoop
;
			bsf PORTB,3
			return

GetAdc:		call ReadAdc1
			movf AdcLsb,W
			addwf SumLow1,F
			btfsc STATUS,C
			incf SumHi1,F
			movf AdcMsb,W
			addwf SumHi1,F
			return

WaitClk:
WaitClkHi:	btfss PORTB,7
			return

			btfsc PORTB,4
			goto WaitClk

WaitClkLow:	btfss PORTB,7
			return

			btfss PORTB,4
			goto WaitClkLow

			return

SetRef:		movf VAL,W
			movwf REF
			return

SetMotor:	movf VAL,W
			movwf MOT
			return

SetInten:	rrf VAL,F
			rrf VAL,F
			rrf VAL,F
			rrf VAL,W
			andlw $F
			movwf INTEN
			return

GetRef:		movf REF,W
			movwf VAL
			return

GetTemp:	bcf STATUS,C
			rrf SumHi1,F
			rrf SumLow1,F	
;
			bcf STATUS,C
			rrf SumHi1,F
			rrf SumLow1,F	
;
			bcf STATUS,C
			rrf SumHi1,F
			rrf SumLow1,F	
;
			bcf STATUS,C
			rrf SumHi1,F
			rrf SumLow1,F	
;
			movf SumLow1,W
			movwf TEM0
			movf SumHi1,W
			movwf TEM1
;
			clrf SumLow1
			clrf SumHi1
;
			movf TEM0,W
			movwf VAL
			return

GetMotor:	movf MOT,W
			movwf VAL
			return
			
Wait:		btfss PORTB,7
			goto Wait
;			
			PAGE1
			movlw %10110010
			movwf TRISB
			PAGE0
;
			clrf VAL
			clrf REG

			call WaitClk
			btfss PORTB,5
			goto WaitRec

WaitSend:
			call WaitClk
			btfsc PORTB,5
			bsf REG,0

			call WaitClk
			btfsc PORTB,5
			bsf REG,1

			call WaitClk
			btfsc PORTB,5
			bsf REG,2
;
			call WaitClk
			btfsc PORTB,5
			bsf VAL,0

			call WaitClk
			btfsc PORTB,5
			bsf VAL,1

			call WaitClk
			btfsc PORTB,5
			bsf VAL,2

			call WaitClk
			btfsc PORTB,5
			bsf VAL,3

			call WaitClk
			btfsc PORTB,5
			bsf VAL,4

			call WaitClk
			btfsc PORTB,5
			bsf VAL,5

			call WaitClk
			btfsc PORTB,5
			bsf VAL,6

			call WaitClk
			btfsc PORTB,5
			bsf VAL,7

			btfss PORTB,7
			goto WaitEnd

			call SetVal
			goto WaitEnd

WaitRec:
			call WaitClk
			btfsc PORTB,5
			bsf REG,0

			call WaitClk
			btfsc PORTB,5
			bsf REG,1

			call WaitClk
			btfsc PORTB,5
			bsf REG,2
;
			call GetVal
;
			movlw 8
			movwf BIT

			btfss PORTB,7
			goto WaitEnd

WaitRecLoop:
			btfss VAL,0
			goto WaitRecReset

			bsf PORTB,6
			goto WaitRecShift

WaitRecReset:
			bcf PORTB,6

WaitRecShift:
			rrf VAL,F

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

			decfsz BIT,F
			goto WaitRecLoop

WaitEnd:
			PAGE1
			movlw %11110010
			movwf TRISB
			PAGE0

WaitHi:		btfss PORTB,7
			return
			goto WaitHi
		
DECODE:		clrf D1
			clrf D2
			movlw 100
			
DEC100:		subwf V0,F
			btfss STATUS,C
			decf V1,F
			incf D2,F 
;
			btfss V1,7
			goto DEC100
;
			decf D2,F
			addwf V0,F
			movlw 10

DEC10:		incf D1,F 
			subwf V0,F
			btfsc STATUS,C
			goto DEC10
;
			decf D1,F
			addwf V0,W
			movwf D0
			return

DECMOT:		movf MOT,W
			movwf V0
			movlw 249
			subwf V0,W
			btfss STATUS,C
			goto DECMOTIT
;
			movlw 9
			movwf D1
			movwf D0
			return

DECMOTIT:	clrf D1
			clrf D0

DECMOT10:	incf D1,W
			call GETMOT10
			subwf V0,W
			btfss STATUS,C
			goto DECMOTN
			incf D1,F
			goto DECMOT10

DECMOTN:	movf D1,W
			call GETMOT10
			subwf V0,F

DECMOT1:	incf D0,W
			call GETMOT1
			subwf V0,W
			btfss STATUS,C
			return
			incf D0,F
			goto DECMOT1

DELAY:		return

SENDBYTE:	movwf TEMP
			movlw 8
			movwf COUNT

SENDLOOP:	movlw 0
			btfsc TEMP,7
			movlw 2
			movwf PORTA
			call DELAY

			addlw 1
			movwf PORTA
			call DELAY

			rlf TEMP,F

			decfsz COUNT,F
			goto SENDLOOP

			return

LOADLED:	movlw 5
			movwf PORTA
			call DELAY

			clrf PORTA
			call DELAY

			return

        .END
