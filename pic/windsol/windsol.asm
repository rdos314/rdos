#include p18f2423.inc

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

Arg1l	EQU 0x20
Arg1h	EQU 0x21
Arg2l	EQU 0x22
Arg2h	EQU 0x23
Res0	EQU 0x24
Res1	EQU 0x25
Res2	EQU 0x26
Res3	EQU 0x27

ResetStart:
	movlw b'00001001'
    movwf PORTB
;
    movlw b'11100000'
    movwf TRISB
;
    movlw b'11000011'
    movwf PORTC
;
    movlw b'10010000'
    movwf TRISC
;
    movlw b'10000111'
    movwf T0CON

LowLoop:
    btfss TMR0L,7
   	bra LowLoop
;
    bsf LATB,0

HiLoop:
	btfsc TMR0L,7
    bra HiLoop
;
    bcf LATB,0     
    bra LowLoop

    movlw 15
    movwf Arg1l
    movlw 18
    movwf Arg2l
    clrf Arg1h
    movlw 0xFF
    movwf Arg2h
	call Mul16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mul16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mul16:
    movf Arg1l,W
    mulwf Arg2l
	movff PRODH, Res1
    movff PRODL, Res0
;
	movf Arg1h,W
    mulwf Arg2h
    movff PRODH, Res3
    movff PRODL, Res2
;
	movf Arg1l,W
    mulwf Arg2h
    movf PRODL,W
    addwf Res1,F
    movf PRODH,W
    addwfc Res2,F
    clrf WREG
    addwfc Res3,F
;
    movf Arg1h,W
    mulwf Arg2l
    movf PRODL,W
    addwf Res1,F
    movf PRODH,W
    addwfc Res2,F
    clrf WREG
    addwfc Res3,F
;
	btfss Arg2h,7
    bra MulSignArg1
;
	movf Arg1l,W
    subwf Res2
    movf Arg1h,w
    subwfb Res3

MulSignArg1:
    btfss Arg1h,7
    bra MulDone
;
	movf Arg2l,W
    subwf Res2
    movf Arg2h,W
    subwfb Res3

MulDone:
	return


    end
