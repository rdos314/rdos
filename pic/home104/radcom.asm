;SERDA.ASM

#DEFINE PAGE0   BCF $03,5
#DEFINE PAGE1   BSF $03,5

INDF:	.EQU 0
TMR0:	.EQU 1
OPTION: .EQU 1
PCL:    .EQU 2
STATUS: .EQU 3
FSR:	.EQU 4
PORTA:  .EQU 5
PORTB:  .EQU 6
TRISA:  .EQU 5
TRISB:  .EQU 6

NODEID:	.EQU $20

W:      .EQU 0          ;Working
F:      .EQU 1          ;File
C:      .EQU 0          ;Carry
Z:      .EQU 2          ;Zero

EEDATA: .EQU $08        ;eeprom data value register
EECON1: .EQU $08        ;eeprom write register 1
EEADR:  .EQU $09        ;eeprom data address register
EECON2: .EQU $09        ;eeprom write register 2
INTCON: .EQU $0B

WR:     .EQU 1          ;eeprom write initiate flag
WREN:   .EQU 2          ;eeprom write enable flag
RD:     .EQU 0          ;eeprom read enable flag

AL:		.EQU $0F
DL:		.EQU $10
TEMP:	.EQU $11
LCNT:	.EQU $12
CHAN:	.EQU $13
VAL:	.EQU $14
COUNT:	.EQU $15
BITS:   .EQU $16
CRC:	.EQU $17
CMD:	.EQU $18
T0:		.EQU $19
T1:		.EQU $1A
T2:		.EQU $1B
TMRCNT	.EQU $1C
CLKCNT	.EQU $1D
STATE0	.EQU $1E
STATE1	.EQU $1F
BIT0	.EQU $20
BIT1	.EQU $21
FLREG0	.EQU $22
FLREG1	.EQU $23

VAL0:	.EQU $28
VAL1:	.EQU $29
VAL2:	.EQU $2A
VAL3:	.EQU $2B
VAL4:	.EQU $2C
VAL5:	.EQU $2D
VAL6:	.EQU $2E
VAL7:	.EQU $2F

	        .ORG 4
    	    .ORG 5

RESET:		PAGE1
			movlw $03
			movwf TRISA

			movlw %11100100
			movwf TRISB

	        movlw %10000100 ;move ratio value into W
    	    movwf OPTION    ;set timer ratio to 1:32 (TMR0 rate)

			PAGE0
			clrf PORTA
			clrf PORTB
;
			movlw 152
			movwf TMRCNT
			bcf INTCON,2
;
			movlw $FF
			movwf TEMP
;
			movlw 16
			movwf CLKCNT

			clrf STATE0
			clrf STATE1
			clrf VAL0
			clrf VAL1
			clrf VAL2
			clrf VAL3
			clrf VAL4
			clrf VAL5
			clrf VAL6
			clrf VAL7

ILOOP:		call POLLTIMER
			btfss PORTA,0
			goto ILOOP

REMOTE:		clrf PORTA

			movlw 7
			movwf COUNT

PREAMP:		btfss PORTA,1
			goto ILOOP

			call WAITCLK
			
			decfsz COUNT,F
			goto PREAMP

WAITST:		btfss PORTA,1
			goto STARTID

			call WAITCLK
			goto WAITST

STARTID:	clrf CRC
			clrf VAL
			movlw 6
			movwf COUNT

IDLOOP:		call WAITCLK
			call UPDATEVAL
			call UPDATECRC

			decfsz COUNT,F
			goto IDLOOP

IDDONE:		call WAITCLK

			btfsc PORTA,1
			goto LOOPHI

			bcf STATUS,C
			rrf VAL,F
			rrf VAL,F
			movlw NODEID
			xorwf VAL,W
			btfss STATUS,Z
			goto LOOPHI

			movlw 6
			movwf COUNT
			clrf VAL

IDCRCLOOP:	call WAITCLK
			call UPDATEVAL

			decfsz COUNT,F
			goto IDCRCLOOP

IDCRCDONE:	call WAITCLK

			btfsc PORTA,1
			goto LOOPHI

			bcf STATUS,C
			rrf VAL,F
			rrf VAL,F
			movf CRC,W
			andlw $3F
			xorwf VAL,W
			btfss STATUS,Z
			goto LOOPHI

			movlw $0C
			movwf PORTA

			movlw 6
			movwf COUNT
			clrf VAL
			clrf CRC

DEVLOOP:	call WAITCLK
			call UPDATEVAL
			call UPDATECRC

			decfsz COUNT,F
			goto DEVLOOP

			call WAITCLK

			btfsc PORTA,1
			goto LOOPHI

			bcf STATUS,C
			rrf VAL,F
			rrf VAL,F

			movf VAL,W
			andlw 7
			movwf CMD

			movf VAL,W
			movwf CHAN
			rrf CHAN,F
			rrf CHAN,F
			rrf CHAN,W
			andlw 7
			movwf CHAN

			movlw 6
			movwf COUNT
			clrf VAL

DEVCRCLOOP:	call WAITCLK
			call UPDATEVAL

			decfsz COUNT,F
			goto DEVCRCLOOP

DEVCRCDONE:	call WAITCLK

			btfsc PORTA,1
			goto LOOPHI

			bcf STATUS,C
			rrf VAL,F
			rrf VAL,F
			movf CRC,W
			andlw $3F
			xorwf VAL,W
			btfss STATUS,Z
			goto LOOPHI

DEVDONE:	movlw 2
			xorwf CMD,W
			btfsc STATUS,Z
			call READCMD

			movlw 3
			xorwf CMD,W
			btfsc STATUS,Z
			call WRITECMD

LOOPHI:		clrf PORTA

LOOPH:		call POLLTIMER
			btfsc PORTA,0
			goto LOOPH
			goto ILOOP

HANDLEST0:	movf STATE0,W
			addwf PCL,F
			goto SCLK0
			goto RCLKOP0
			goto SCLK0
			goto RCLKREG0

SCLK0:		incf STATE0,F
			bsf PORTB,0
			return

RCLKOP0:	incf STATE0,F
			btfss FLREG0,0
			goto RCLKOPC

			bsf PORTB,1
			goto RCLKOPD

RCLKOPC:	bcf PORTB,1
RCLKOPD:	rrf FLREG0,F
			movlw 3
			movwf BIT0
			return

RCLKREG0:	decf STATE0,F
			decfsz BIT0,F
			goto RCLKREGM
;
			clrf STATE0
			bcf PORTB,0
			bcf PORTB,3
			return

RCLKREGM:	btfss FLREG0,0
			goto RCLKREGC

			bsf PORTB,1
			goto RCLKREGD

RCLKREGC:	bcf PORTB,1
RCLKREGD:	rrf FLREG0,F
			return

HANDLEST1:	movf STATE1,W
			addwf PCL,F
			goto SETCLK1
			goto RESCLK1

SETCLK1:	incf STATE1,F
			bsf PORTB,0
			return

RESCLK1:	clrf STATE1
			bcf PORTB,0
			bcf PORTB,4
			return
			
POLLTIMER:	decfsz CLKCNT,F
			goto POLLTIM
;
			movlw 16
			movwf CLKCNT
;
			btfsc PORTB,3
			call HANDLEST0
;
			btfsc PORTB,4
			call HANDLEST1

POLLTIM:	btfss INTCON,2
			return

			bcf INTCON,2
;
			decfsz TMRCNT,F
			return
;
			movlw 16
			movwf CLKCNT
			
			movlw 153
			movwf TMRCNT
;
			movlw 0
			movwf FLREG0
			bsf FLREG0,7
			bsf PORTB,1
;
			bsf PORTB,3
			incf VAL0,F
			return

DELAY:		return

UPDATECRC:	andlw 1
			movwf BITS
			clrf TEMP
			bcf STATUS,C
			rlf CRC,F
			rlf TEMP,W
			xorwf BITS,W
			btfsc STATUS,Z
			return

			movlw $26
			xorwf CRC,F
			return

WAITCLK:	call POLLTIMER
			btfsc PORTA,0
			goto WAITCLK

WCLKLOW:	call POLLTIMER
			btfss PORTA,0
			goto WCLKLOW
			return

UPDATEVAL:  movf PORTA,W
			movwf TEMP
			btfsc TEMP,1
			goto VALSET

VALRESET:	bcf STATUS,C
			goto UPDATEDO

VALSET:		bsf STATUS,C

UPDATEDO:	rrf VAL,F
			rrf TEMP,W
			return

READCMD:	movlw 24
			movwf COUNT

			movf CHAN,W
			addlw VAL0
			movwf FSR
			movf INDF,W
			movwf T2
			clrf T1
			clrf T0

			bcf STATUS,C
			rrf T2,F
			rrf T1,F
			rrf T0,F

			clrf CRC

RDVALLOOP:	movf T0,W
			call UPDATECRC

			rrf T2,F
			rrf T1,F
			rrf T0,F
			btfss STATUS,C
			goto RDVALRESET

RDVALSET:	bsf PORTA,2
			goto RDVALNEXT

RDVALRESET:	bcf PORTA,2

RDVALNEXT:	call WAITCLK
			btfsc PORTA,1
			return

RDVALCONT:	decfsz COUNT,F
			goto RDVALLOOP

			movlw 8
			movwf COUNT

			movlw $A5
			xorwf CRC,F

RDCRCLOOP:	movf CRC,W
			rrf CRC,F
			btfss STATUS,C
			goto RDCRCRESET

RDCRCSET:	bsf PORTA,2
			goto RDCRCNEXT

RDCRCRESET:	bcf PORTA,2

RDCRCNEXT:	call WAITCLK
			btfsc PORTA,1
			return

RDCRCCONT:	decfsz COUNT,F
			goto RDCRCLOOP
			return

UPDWRVAL:   movf PORTA,W
			movwf TEMP
			btfsc TEMP,1
			goto UPDWRSET

UPDWRCLR:	bcf STATUS,C
			goto UPDWRDO

UPDWRSET:	bsf STATUS,C

UPDWRDO:	rrf T2,F
			rrf T1,F
			rrf T0,F
			rrf TEMP,W
			return

WRITECMD:	clrf T0
			clrf T1
			clrf T2
			clrf CRC

			movlw 6
			movwf COUNT

WRLOOP1:	call WAITCLK
			call UPDWRVAL
			call UPDATECRC

			decfsz COUNT,F
			goto WRLOOP1

			call WAITCLK

			btfsc PORTA,1
			return

WRNEXT1:	movlw 6
			movwf COUNT

WRLOOP2:	call WAITCLK
			call UPDWRVAL
			call UPDATECRC

			decfsz COUNT,F
			goto WRLOOP2

			call WAITCLK

			btfsc PORTA,1
			return

WRNEXT2:	movlw 6
			movwf COUNT

WRLOOP3:	call WAITCLK
			call UPDWRVAL
			call UPDATECRC

			decfsz COUNT,F
			goto WRLOOP3

			call WAITCLK

			btfsc PORTA,1
			return

WRNEXT3:	movlw 6
			movwf COUNT

WRLOOP4:	call WAITCLK
			call UPDWRVAL
			call UPDATECRC

			decfsz COUNT,F
			goto WRLOOP4

			call WAITCLK

			btfsc PORTA,1
			return

WRNEXT4:	movlw 6
			movwf COUNT
			clrf VAL

WRCRCLOOP:	call WAITCLK
			call UPDATEVAL

			decfsz COUNT,F
			goto WRCRCLOOP

WRCRCDONE:	call WAITCLK

			btfsc PORTA,1
			return

WRCRCCONT:	bcf STATUS,C
			rrf VAL,F
			rrf VAL,F
			movf CRC,W
			andlw $3F
			xorwf VAL,W
			btfss STATUS,Z
			return

WRCRCOK:	movf CHAN,W
			addlw VAL0
			movwf FSR
;
			bcf STATUS,C
			rlf T0,F
			rlf T1,F
			rlf T2,F
			btfss STATUS,C
			goto WRPOSVAL

			clrf INDF
			clrf VAL
			goto WRVALDO

WRPOSVAL:	movf T2,W
			movwf INDF
			movwf VAL

WRVALDO:	call SENDVAL
			return

SENDVAL:	return

        .END
