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

TEMP	.EQU $0F
COUNT	.EQU $10
V0		.EQU $11
V1		.EQU $12
D0		.EQU $13
D1		.EQU $14
D2		.EQU $15
REF		.EQU $16
TEM0	.EQU $18
TEM1	.EQU $19
MOT		.EQU $1A


	        .ORG 4
    	    .ORG 5

RESET:		PAGE1
			movlw $18
			movwf TRISA

			movlw %11010010
			movwf TRISB
			PAGE0
			clrf PORTA

			call WAIT
			call INITLED
;
			clrf REF
			clrf TEM0
			clrf TEM1
			clrf MOT
;
LP:			call WRITEREF
			call WRITETEM
			call WRITEMOT
			call WAIT
			incf TEM0,F
			btfsc STATUS,Z
			incf TEM1,F
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
			movlw 8
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

WAIT:		btfss PORTB,7
			goto WAIT

WAITSC:		btfss PORTB,7
			return

			btfss PORTB,4
			goto WAITSC
;
			incf REF,F
			incf MOT,F

WAITSS:		btfss PORTB,7
			return

			btfsc PORTB,4
			goto WAITSS
			goto WAITSC
			
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
