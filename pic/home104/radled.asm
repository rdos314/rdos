#include p16f84a.inc

	__config 0x3FF3

;RADLED.ASM

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

TEMP		EQU 0x0C
COUNT		EQU 0x0D
V0			EQU 0x0E
V1			EQU 0x0F
D0			EQU 0x10
D1			EQU 0x11
D2			EQU 0x12
REF			EQU 0x13
Ch0Low		EQU 0x14
Ch0High		EQU 0x15
Ch1Low		EQU 0x16
Ch1High		EQU 0x17
Ch2Low		EQU 0x18
Ch2High		EQU 0x19
Ch3Low		EQU 0x1A
Ch3High		EQU 0x1B
MOT			EQU 0x1C
REG			EQU 0x1D
VAL			EQU 0x1E
BIT			EQU 0x1F
INTEN		EQU 0x20
AdcLsb		EQU 0x21
AdcMsb		EQU 0x22
RefType		EQU 0x23
DelayMs		EQU 0x24
TState		EQU 0x25
Stable		EQU 0x26
AdcLow0		EQU 0x27
AdcHigh0	EQU 0x28
AdcLow1		EQU 0x29
AdcHigh1	EQU 0x2A
AdcLow2		EQU 0x2B
AdcHigh2	EQU 0x2C
AdcLow3		EQU 0x2D
AdcHigh3	EQU 0x2E

	        org 4
    	    org 5

RESET:		PAGE1
			movlw 0x18
			movwf TRISA

			movlw b'11110010'
			movwf TRISB
			PAGE0
			clrf PORTA
;
			movlw b'00001000'
			movwf PORTB
;
			clrf RefType
;
			call READEE
			movf REF,W
			movwf AdcLow0
			clrf AdcHigh0
;
			clrf Ch0Low
			clrf Ch0High
			clrf Ch1Low
			clrf Ch1High
			clrf Ch2Low
			clrf Ch2High
			clrf Ch3Low
			clrf Ch3High
;
			clrf AdcLow1
			clrf AdcHigh1
			clrf AdcLow2
			clrf AdcHigh2
			clrf AdcLow3
			clrf AdcHigh3
;
			movlw 0x80
			movwf MOT
;
			movlw 12
			movwf INTEN
;
			movlw 0xFF
			movwf DelayMs
			clrf TState
			movlw .10
			movwf Stable

LP:			call INITLED
			call WRITEREF
			call WRITETEM
			call WRITEMOT
			call Wait
			goto LP

STOP:		goto STOP
			
GETSEG:		andlw 0xF
			addwf PCL,F
			retlw b'01111110'	; 0
			retlw b'00110000' ; 1
			retlw b'01101101' ; 2
			retlw b'01111001' ; 3
			retlw b'00110011' ; 4
			retlw b'01011011' ; 5
			retlw b'01011111' ; 6
			retlw b'01110000' ; 7
			retlw b'01111111' ; 8
			retlw b'01111011' ; 9
			retlw b'01110111' ; A
			retlw b'00011111' ; B
			retlw b'01001110' ; C
			retlw b'00111101' ; D
			retlw b'01001111' ; E
			retlw b'01000111' ; F

GETMOT10:	andlw 0xF
			addwf PCL,F
			retlw .0	  ; 0.0
			retlw .25  ; 1.0
			retlw .50  ; 2.0
			retlw .75  ; 3.0
			retlw .100 ; 4.0
			retlw .125 ; 5.0
			retlw .150 ; 6.0
			retlw .175 ; 7.0
			retlw .200 ; 8.0
			retlw .225 ; 9.0
			retlw .250 ; 10.0
			retlw .255 

GETMOT1:	andlw 0xF
			addwf PCL,F
			retlw .0	  ; 0.0
			retlw .3	  ; 0.1
			retlw .5	  ; 0.2
			retlw .8   ; 0.3
			retlw .10  ; 0.4
			retlw .13  ; 0.5
			retlw .15  ; 0.6
			retlw .18  ; 0.7
			retlw .20  ; 0.8
			retlw .23  ; 0.9			
			retlw .255

SetVal:		movf REG,W
			addwf PCL,F
			goto SetRef		; 0
			return			; 1
			goto SetMotor	; 2
			return			; 3
			return			; 4
			goto SetRefType	; 5
			return			; 6
			goto GetAdc		; 7

GetVal:		movf REG,W
			addwf PCL,F
			goto GetRef			; 0
			goto GetTemp		; 1
			return				; 2
			goto GetTemp1		; 3
			goto GetLightLow 	; 4
			goto GetLightHigh	; 5
			return				; 6
			return				; 7

INITLED:	movlw 0xC
			call SENDBYTE
			movlw 1
			call SENDBYTE
			call LOADLED
;
			movlw 0x9
			call SENDBYTE
			movlw 0
			call SENDBYTE
			call LOADLED
;
			movlw 0xA
			call SENDBYTE
			movf INTEN,W
			call SENDBYTE
			call LOADLED
;
			movlw 0xB
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
			movlw 0x1
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
			movlw 0x2
			call SENDBYTE
			movf D1,W
			call GETSEG
			addlw 0x80
			call SENDBYTE
			call LOADLED
;
			movlw 0x3
			call SENDBYTE
			movf D0,W
			call GETSEG
			call SENDBYTE
			call LOADLED
			return

WRITETEM:	movf AdcLow0,W
			movwf V0
			movf AdcHigh0,W
			movwf V1
			call DECODE
;
			movlw 0x4
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
			movlw 0x5
			call SENDBYTE
			movf D1,W
			call GETSEG
			addlw 0x80
			call SENDBYTE
			call LOADLED
;
			movlw 0x6
			call SENDBYTE
			movf D0,W
			call GETSEG
			call SENDBYTE
			call LOADLED
			return

WRITEMOT:	call DECMOT
;
			movlw 0x7
			call SENDBYTE
			movf D1,W
			call GETSEG
			addlw 0x80
			call SENDBYTE
			call LOADLED
;
			movlw 0x8
			call SENDBYTE
			movf D0,W
			call GETSEG
			call SENDBYTE
			call LOADLED
			return

AdcDelay:	return

ReadAdc0:	movlw b'10001000'
			goto ReadAdc

ReadAdc1:	movlw b'10011000'
			goto ReadAdc

ReadAdc2:	movlw b'10101000'
			goto ReadAdc

ReadAdc3:	movlw b'10111000'

ReadAdc:	movwf TEMP
			movlw 7
			movwf COUNT
;
			movlw b'00001100'
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

GetAdc0:	call ReadAdc0
			movf AdcLsb,W
			addwf Ch0Low,F
			btfsc STATUS,C
			incf Ch0High,F
			movf AdcMsb,W
			addwf Ch0High,F
			return

GetAdc1:	call ReadAdc1
			movf AdcLsb,W
			addwf Ch1Low,F
			btfsc STATUS,C
			incf Ch1High,F
			movf AdcMsb,W
			addwf Ch1High,F
			return

GetAdc2:	call ReadAdc2
			movf AdcLsb,W
			addwf Ch2Low,F
			btfsc STATUS,C
			incf Ch2High,F
			movf AdcMsb,W
			addwf Ch2High,F
			return

GetAdc3:	call ReadAdc3
			movf AdcLsb,W
			addwf Ch3Low,F
			btfsc STATUS,C
			incf Ch3High,F
			movf AdcMsb,W
			addwf Ch3High,F
			return

GetAdc:		call GetAdc0
			call GetAdc1
			call GetAdc2
			call GetAdc3
			return

WaitClk:	call Poll
WaitClkHi:	btfss PORTB,7
			return

			btfsc PORTB,4
			goto WaitClk

WaitClkLow:	call Poll
			btfss PORTB,7
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

SetRefType:	movf VAL,W
			movwf RefType
			call READEE
			return

GetRef:		movf REF,W
			movwf VAL
			return

SaveAdc0:	bcf STATUS,C
			rrf Ch0High,F
			rrf Ch0Low,F	
;
			bcf STATUS,C
			rrf Ch0High,F
			rrf Ch0Low,F	
;
			bcf STATUS,C
			rrf Ch0High,F
			rrf Ch0Low,F	
;
			bcf STATUS,C
			rrf Ch0High,F
			rrf Ch0Low,F	
;
			movf Ch0Low,W
			movwf AdcLow0
			movf Ch0High,W
			movwf AdcHigh0
;
			clrf Ch0Low
			clrf Ch0High
			return

SaveAdc1:	bcf STATUS,C
			rrf Ch1High,F
			rrf Ch1Low,F	
;
			bcf STATUS,C
			rrf Ch1High,F
			rrf Ch1Low,F	
;
			bcf STATUS,C
			rrf Ch1High,F
			rrf Ch1Low,F	
;
			bcf STATUS,C
			rrf Ch1High,F
			rrf Ch1Low,F	
;
			movf Ch1Low,W
			movwf AdcLow1
			movf Ch1High,W
			movwf AdcHigh1
;
			clrf Ch1Low
			clrf Ch1High
			return

SaveAdc2:	bcf STATUS,C
			rrf Ch2High,F
			rrf Ch2Low,F	
;
			bcf STATUS,C
			rrf Ch2High,F
			rrf Ch2Low,F	
;
			bcf STATUS,C
			rrf Ch2High,F
			rrf Ch2Low,F	
;
			bcf STATUS,C
			rrf Ch2High,F
			rrf Ch2Low,F	
;
			movf Ch2Low,W
			movwf AdcLow2
			movf Ch2High,W
			movwf AdcHigh2
;
			clrf Ch2Low
			clrf Ch2High
			return

SaveAdc3:	bcf STATUS,C
			rrf Ch3High,F
			rrf Ch3Low,F	
;
			bcf STATUS,C
			rrf Ch3High,F
			rrf Ch3Low,F	
;
			bcf STATUS,C
			rrf Ch3High,F
			rrf Ch3Low,F	
;
			bcf STATUS,C
			rrf Ch3High,F
			rrf Ch3Low,F	
;
			movf Ch3Low,W
			movwf AdcLow3
			movf Ch3High,W
			movwf AdcHigh3
;
			clrf Ch3Low
			clrf Ch3High
			return

SetInten:
			movf AdcHigh3,W
			btfss STATUS,Z
			goto SetMaxInten
;
			movf AdcLow3,W
			movwf INTEN
			rrf INTEN,F
			rrf INTEN,F
			rrf INTEN,F
			rrf INTEN,W
			andlw 0xF
			addlw 2
			movwf INTEN
			btfss INTEN,4			
			return

SetMaxInten:	
			movlw 0xF
			movwf INTEN
			return

GetTemp0:	movf AdcLow0,W
			movwf VAL
			return

GetTemp1:	movf AdcLow1,W
			movwf VAL
			return

GetLightLow:	
			movf AdcLow3,W
			movwf VAL
			return

GetLightHigh:	
			movf AdcHigh3,W
			movwf VAL
			return

GetTemp:	call SaveAdc0
			call SaveAdc1
			call SaveAdc2
			call SaveAdc3
			call SetInten
			call GetTemp0
			return

GetMotor:	movf MOT,W
			movwf VAL
			return
			
Wait:		call Poll
			btfss PORTB,7
			goto Wait
;			
			PAGE1
			movlw b'10110010'
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
			call Poll
			btfss PORTB,7
			goto WaitEnd

			btfsc PORTB,4
			goto WaitRecHi

WaitRecLow:	
			call Poll
			btfss PORTB,7
			goto WaitEnd

			btfss PORTB,4
			goto WaitRecLow

			decfsz BIT,F
			goto WaitRecLoop

WaitEnd:
			PAGE1
			movlw b'11110010'
			movwf TRISB
			PAGE0

WaitHi:		call Poll
			btfss PORTB,7
			return
			goto WaitHi
		
DECODE:		clrf D1
			clrf D2
			movlw .100
			
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
			movlw .10

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
			movlw .249
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

CheckRef:	movf REF,W
			sublw .150
			btfss STATUS,C
			goto CheckRefHi
;
			movlw .150
			movwf REF
			return

CheckRefHi:
			movf REF,W
			sublw .250
			btfsc STATUS,C
			return
;
			movlw .250
			movwf REF
			return

READEE:		movf RefType,W
			movwf EEADR
        	PAGE1
        	bsf EECON1,RD
    	    PAGE0
	        movf EEDATA,W
			movwf REF
			call CheckRef
			return

WRITEEE:	movf RefType,W
			movwf EEADR
			PAGE1
	        bsf EECON1,WREN
	        PAGE0
    	    movf REF,W
	        movwf EEDATA

		 	PAGE1
     		movlw 0x55
	        movwf EECON2
	        movlw 0xAA
	        movwf EECON2
       	   	bsf EECON1,WR

CHKWRT:		btfss EECON1,4
	        goto CHKWRT

    	    bcf EECON1,WREN 
	        bcf EECON1,4
 	        PAGE0
        	bcf INTCON,6
			return

Poll:		decfsz DelayMs,F
			return
;
			movlw 0xFF
			movwf DelayMs
;
			movf PORTA,W
			andlw 0x18
			xorwf TState,W
			btfss STATUS,Z
			goto RedoDebounc
;
			decfsz Stable,F
			return
;
			movlw 8
			xorwf TState,W
			btfss STATUS,Z
			goto CheckRed

CheckBoth:	movlw 0x10
			xorwf TState,W
			btfsc STATUS,Z
			return
;
			decf REF,F
			call CheckRef
			call WRITEEE
			call WRITEREF
			return	

CheckRed:	movlw 0x10
			xorwf TState,W
			btfss STATUS,Z
			return
;
			call CheckRef
			incf REF,F
			call WRITEEE
			call WRITEREF
			return

RedoDebounc:
			movf PORTA,W
			andlw 0x18
			movwf TState
			movlw .10
			movwf Stable
			return

       end

