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

NODEID:	.EQU $22
DELAY_TICS:	.EQU 200

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

AL:			.EQU $0C
DL:			.EQU $0D
TEMP:		.EQU $0E
LCNT:		.EQU $0F
CHAN:		.EQU $10
VAL:		.EQU $11
COUNT:		.EQU $12
BITS:   	.EQU $13
CRC:		.EQU $14
CMD:		.EQU $15
T0:			.EQU $16
T1:			.EQU $17
T2:			.EQU $18
TMRCNT		.EQU $19
CLKCNT		.EQU $1A
STATE		.EQU $1B
BIT			.EQU $1C
FLREG		.EQU $1D
SEC			.EQU $1E
FLVAL  	 	.EQU $1F

Temp		.EQU $20
Ref			.EQU $21
Motor		.EQU $22
AuxTemp		.EQU $23
LightLow	.EQU $24
LightHigh	.EQU $25
DummyVal	.EQU $26
Ambient		.EQU $27
RefType		.EQU $28
LightTemp	.EQU $29


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
			movlw DELAY_TICS
			movwf CLKCNT

			clrf STATE
			clrf SEC
;
			movlw 200
			movwf Temp
			movwf Ref
;
			movlw $80
			movwf Motor
			movwf Ambient
;
			clrf AuxTemp
			clrf LightLow
			clrf LightHigh
			clrf DummyVal
			clrf RefType
			goto ILOOP

RecRef:		movlw 0
			movwf FLREG
			movlw Ref
			movwf FSR
			call Rec0
			return

SendRef1:	movlw 0
			movwf FLREG
			movlw Ref
			movwf FSR
			call Send1
			return

RecTemp:	movlw 1
			movwf FLREG
			movlw Temp
			movwf FSR
			call Rec0
			return

RecAuxTemp:	movlw 3
			movwf FLREG
			movlw AuxTemp
			movwf FSR
			call Rec0
			return

RecMotor:	movlw 2
			movwf FLREG
			movlw Motor
			movwf FSR
			call Rec1
			return

RecLightLow:	
			movlw 4
			movwf FLREG
			movlw LightTemp
			movwf FSR
			call Rec0
			return

RecLight:	movlw 5
			movwf FLREG
			movlw LightHigh
			movwf FSR
			call Rec0
;
			movf LightTemp,W
			movwf LightLow
			return

SendTemp:	movlw 1
			movwf FLREG
			movlw Temp
			movwf FSR
			call Send1
			return

SendMotor:	movlw 2
			movwf FLREG
			movlw Motor
			movwf FSR
			call Send0
			return

SendAmbient:
            movlw 4
			movwf FLREG
			movlw Ambient
			movwf FSR
			call Send1
			return

SendRefType:
            movlw 5
			movwf FLREG
			movlw RefType
			movwf FSR
			call Send0
			return

StartTemp:	movlw 7
			movwf FLREG
			movlw DummyVal
			movwf FSR
			call Send0
			return

StartFuzzy:	movlw 7
			movwf FLREG
			movlw DummyVal
			movwf FSR
			call Send1
			return

HandlePend:
			bcf SEC,7
			movf SEC,W
			incf SEC,F
			addwf PCL,F
			goto StartTemp      ; 0
			goto StartTemp      ; 1
			goto StartTemp      ; 2
			goto StartTemp      ; 3
			goto StartTemp      ; 4
			goto StartTemp      ; 5
			goto StartTemp      ; 6
			goto StartTemp      ; 7
			goto StartTemp      ; 8
			goto StartTemp      ; 9
			goto StartTemp      ; 10
			goto StartTemp      ; 11
			goto StartTemp      ; 12
			goto StartTemp      ; 13
			goto StartTemp      ; 14
			goto StartTemp      ; 15
			goto RecTemp		; 16
			goto SendAmbient	; 17
			goto SendRefType	; 18
			goto RecRef			; 19
			goto SendRef1		; 20
			goto RecLightLow	; 21
			goto SendTemp		; 22
			goto RecAuxTemp    	; 23
			goto RecLight		; 24
			goto StartFuzzy		; 25
			return				; 26
			return				; 27
			return				; 28
			return				; 29
			return				; 30
			return				; 31
			return				; 32
			return				; 33
			return 				; 34
			return				; 35
			return				; 36
			return				; 37
			return				; 38
			return				; 39
			return				; 40
			return				; 41
			return				; 42
			return				; 43
			return 				; 44
			return				; 45
			return				; 46
			return				; 47
			return				; 48
			return				; 49
			return				; 50
			return				; 51
			return				; 52
			return				; 53
			return 				; 54
			return				; 55
			return				; 56
			goto RecMotor		; 57
			goto SendMotor		; 58
			clrf SEC			; 59
			return

HandleSt:	movf STATE,W
			addwf PCL,F
			goto SetClk
			goto ResClkOp
			goto SetClk
			goto ResClkReg
			goto SetClk
			goto ResClkVal
			goto SetClkVal
			goto ResClk

HandleRead:
			movf CHAN,W
			addwf PCL,F
			goto ReadRef        ; 0
			goto ReadTemp       ; 1
			goto ReadMotor      ; 2
			goto ReadLight      ; 3
			goto ReadAuxTemp    ; 4
			goto DummyRead      ; 5
			goto DummyRead      ; 6
			goto DummyRead      ; 7

HandleWrite:
			movf CHAN,W
			addwf PCL,F
			goto WriteRef       ; 0
			goto DummyWrite     ; 1
			goto DummyWrite     ; 2
			goto DummyWrite     ; 3
			goto WriteAmbient   ; 4
			goto WriteRefType   ; 5
			goto DummyWrite     ; 6
			goto DummyWrite     ; 7

DummyRead:
			clrf T0
			clrf T1
			clrf T2
			return

ReadRef:
			movf Ref,W
			movwf T0
			clrf T1
			clrf T2
			return

ReadTemp:
			movf Temp,W
			movwf T0
			clrf T1
			clrf T2
			return

ReadMotor:
			movf Motor,W
			movwf T0
			clrf T1
			clrf T2
			return

ReadLight:
			movf LightLow,W
			movwf T0
			movf LightHigh,W
			movwf T1
			clrf T2
			return

ReadAuxTemp:
			movf AuxTemp,W
			movwf T0
			clrf T1
			clrf T2
			return

DummyWrite:
			return

WriteRef:	movf T0,W
			movwf Ref
			return

WriteAmbient:
            movf T0,W
			movwf Ambient
			return

WriteRefType:
            movf T0,W
			movwf RefType
			return
			
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

ResClk:		decf STATE,F
			bcf PORTB,0
			return

SetClk:		incf STATE,F
			bsf PORTB,0
			return

OutFl:		btfss FLREG,0
			goto OutFlRes

			bsf PORTB,1
			goto OutFlDone

OutFlRes:	bcf PORTB,1
OutFlDone:	rrf FLREG,F
			call DELAY
			bcf PORTB,0
			return

ResClkOp:	incf STATE,F
			movlw 3
			movwf BIT
			call OutFl
			return

ResClkReg:	decfsz BIT,F
			goto ResClkRegMore
;
			movlw 8
			movwf BIT
;
			btfsc FLREG,0
			goto ResClkSend
;
			movlw 7
			movwf STATE
			clrf FLVAL
			goto ResClk

ResClkSend:
			incf STATE,F
			movf INDF,W
			movwf FLREG
			call OutFl
			return

ResClkRegMore:
			decf STATE,F
			call OutFl
			return

ResClkVal:	decfsz BIT,F
			goto ResClkValMore
;
			clrf STATE
			clrf PORTB
			return

ResClkValMore:
			decf STATE,F
			call OutFl
			return

RecBit:		incf STATE,F
			btfss PORTB,2
			return
			bsf FLVAL,7
			return

SetClkVal:	decfsz BIT,F
			goto SetClkValMore
;
			call RecBit
			movf FLVAL,W
			movwf INDF
;
			clrf STATE
			clrf PORTB
			return

SetClkValMore:
			call RecBit
			bcf STATUS,C
			rrf FLVAL,F
			bsf PORTB,0
			return
			
POLLTIMER:	decfsz CLKCNT,F
			return
;
			movlw DELAY_TICS
			movwf CLKCNT

POLLTIM:	btfss INTCON,2
			return

			bcf INTCON,2
;
			decfsz TMRCNT,F
			goto DoIdle
			goto DoSec

DoIdle:
			btfsc SEC,7
			goto HandlePend
;
			btfsc PORTB,3
			goto HandleSt
;
			btfsc PORTB,4
			goto HandleSt
			return

DoSec:
			movlw DELAY_TICS
			movwf CLKCNT
			
			movlw 153
			movwf TMRCNT
;
			bsf SEC,7
			return

Send0:		clrf STATE
			bsf FLREG,3
			movlw %00001010
			movwf PORTB
			return

Send1:		clrf STATE
			bsf FLREG,3
			movlw %00010010
			movwf PORTB
			return

Rec0:		clrf STATE
			bcf FLREG,3
			movlw %00001000
			movwf PORTB
			return

Rec1:		clrf STATE
			bcf FLREG,3
			movlw %00010000
			movwf PORTB
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
			call HandleRead
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

WRCRCOK:	call HandleWrite
			return

        .END
