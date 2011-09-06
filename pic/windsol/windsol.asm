#include p18f2423.inc

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

temp0	EQU 0x0
temp1   EQU 0x1
temp2   EQU 0x2
temp3   EQU 0x3
ad_cnt	EQU 0x4

ad_conf	EQU 0x5

ad_vall	EQU 0x6
ad_valh	EQU 0x7

ad_cur	EQU 0x8

wind_low_lsb    EQU 0x9
wind_low_msb    EQU 0xA
wind_high_lsb   EQU 0xB
wind_high_msb   EQU 0xC

Arg1l	EQU 0x20
Arg1h	EQU 0x21
Arg2l	EQU 0x22
Arg2h	EQU 0x23
Res0	EQU 0x24
Res1	EQU 0x25
Res2	EQU 0x26
Res3	EQU 0x27

; AD bank

ad00	EQU 0x100
ad00l	EQU 0x101
ad00h	EQU 0x102

ad01	EQU 0x104
ad01l	EQU 0x105
ad01h	EQU 0x106

ad02	EQU 0x108
ad02l	EQU 0x109
ad02h	EQU 0x10A

ad03	EQU 0x10C
ad03l	EQU 0x10D
ad03h	EQU 0x10E

ad10	EQU 0x110
ad10l	EQU 0x111
ad10h	EQU 0x112

ad11	EQU 0x114
ad11l	EQU 0x115
ad11h	EQU 0x116

ad12	EQU 0x118
ad12l	EQU 0x119
ad12h	EQU 0x11A

ad13	EQU 0x11C
ad13l	EQU 0x11D
ad13h	EQU 0x11E

    goto ResetStart

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

AdTab0:
    db b'00010000', b'00110000'
    db b'01010000', b'01110000'

AdTab1:
    db b'10000000', b'00110000'
    db b'01010000', b'01110000'


ResetStart:
    movlw b'00000001'
    movwf PORTA
    movwf LATA
;
    movlw b'11111110'
    movwf TRISA
;
	movlw b'00001000'
    movwf PORTB
    movwf LATB
;
    movlw b'11100000'
    movwf TRISB
;
    movlw b'11000011'
    movwf PORTC
    movwf LATC
;
    movlw b'10010000'
    movwf TRISC
;
    movlw b'10000111'
    movwf T0CON
;
    movlw b'11101111'
    movwf OSCCON
;
    call LoadAdTab
;
    movlw 0x20
    movwf temp0
    movlw 0x3
    movwf temp1    
    call SetupWind


HandleLoop:
    bsf LATA,0
    call WaitForSample
	call TestSample
    call UpdateWind
    goto HandleLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetupWind
; temp1:temp0 voltage reference
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupWind:
    movf temp0,W
    movwf wind_low_lsb
    movwf wind_high_lsb
;
    movf temp1,W
    movwf wind_low_msb
    movwf wind_high_msb
;
    movlw 4
    movwf temp2

swRotateLoop:
    bcf STATUS,C
    rrcf temp1,F
    rrcf temp0,F
    decfsz temp2,F
    goto swRotateLoop
;
    movlw 1
    addwf temp0,F
    movlw 0
    addwfc temp1,F
;    
    movf temp0,W
    addwf wind_high_lsb,F
    movf temp1,W
    addwfc wind_high_msb,F
;     
    comf temp0,F
    comf temp1,F
    movlw 1
    addwf temp0,F
    movlw 0
    addwfc temp1,F
;    
    movf temp0,W
    addwf wind_low_lsb,F
    movf temp1,W
    addwfc wind_low_msb,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateWind
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateWind:
    btfss LATB,0
    goto UpdateWindDumpOff

UpdateWindDumpOn:
    bcf LATA,0
    lfsr FSR0,ad01h
    btfsc INDF0,7
    goto UpdateWindTurnOff
;
    movf wind_low_msb,W
    cpfseq INDF0
    goto UpdateWindDumpOnNotEq
;
    lfsr FSR0,ad01l
    movf wind_low_lsb,W
    cpfslt INDF0
    return
    goto UpdateWindTurnOff

UpdateWindDumpOnNotEq:
    cpfslt INDF0
    return

UpdateWindTurnOff:
    bcf LATB,0
    return
    
UpdateWindDumpOff:
    lfsr FSR0,ad01h
    btfsc INDF0,7
    return
;
    movf wind_high_msb,W
    cpfseq INDF0
    goto UpdateWindDumpOffNotEq
;
    lfsr FSR0,ad01l
    movf wind_low_lsb,W
    cpfsgt INDF0
    return
    goto UpdateWindTurnOn

UpdateWindDumpOffNotEq:
    cpfsgt INDF0
    return

UpdateWindTurnOn:
    bsf LATB,0
    return


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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LoadAdTab
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LoadAdTab:
    clrf TBLPTRU
    clrf TBLPTRH
;
    movlw AdTab0
    movwf TBLPTRL
    lfsr FSR0,ad00
;
	movlw 4
    movwf temp0

LoadAd0:
    tblrd *+
    movf TABLAT,W
    movwf INDF0
    movlw 4
    addwf FSR0L,F
    decfsz temp0
    bra LoadAd0
;
    movlw AdTab1
    movwf TBLPTRL
    lfsr FSR0,ad10
;
	movlw 4
    movwf temp0

LoadAd1:
    tblrd *+
    movf TABLAT,W
    movwf INDF0
    movlw 4
    addwf FSR0L,F
    decfsz temp0,F
    bra LoadAd1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WaitForSample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForSample:
;    btfsc TMR0L,3       ; decomment for 512us period
;    goto WaitForSample
;
    btfsc TMR0L,2
    goto WaitForSample
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WaitSample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitSample:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TestSample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TestSample:
    clrf ad_cur
	bsf LATC,0
    bsf LATC,1
    movlw 4
    movwf ad_cnt
    bcf LATC,3
    bsf LATC,5
    movlw 4
    movwf temp0
;
    movlw 0x30
    movwf ad_conf
;
    bcf LATC,0
    goto ad_test_loop1

ad_test_set0:
    bcf LATC,5
    goto ad_test_clk0

ad_test_loop0:
    bsf LATC,3
    rlcf ad_conf,F

ad_test_bit0:
    btfsc STATUS,C
    goto ad_test_set1

ad_test_clk0:
    bcf LATC,3
    decfsz temp0,F
    bra ad_test_loop0
;
    goto ad_test_init_done

ad_test_set1:
    bsf LATC,5
    goto ad_test_clk1

ad_test_loop1:
    bsf LATC,3
    rlcf ad_conf,F

ad_test_bit1:
    btfss STATUS,C
    goto ad_test_set0

ad_test_clk1:
    bcf LATC,3
    decfsz temp0,F
    bra ad_test_loop1

ad_test_init_done:
    bsf LATC,3
    call WaitSample
    bcf LATC,3
    nop
    nop
    nop

test_sample_start:
    bsf LATC,3
    nop
    nop
    nop
    bcf LATC,3
;
    bcf LATC,5
;
    btfsc ad_cur,0
    goto test_sample_start1

test_sample_start0:
    bcf LATC,1
    movf INDF1,W
    movwf ad_conf
    goto test_sample_started

test_sample_start1:
	bcf LATC,0
    movf INDF0,W
    movwf ad_conf

test_sample_started:
    clrf ad_vall
    clrf ad_valh
    movlw 0xE
    movwf temp0

test_sample_loop:
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    bsf LATC,3
    btfsc PORTC,4
    bsf ad_vall,0
    bcf LATC,3
    decfsz temp0,F
    bra test_sample_loop
;
    bsf LATC,0
;
    lfsr FSR0,ad01l
    movf ad_vall,W
    movwf INDF0
    incf FSR0L,F
;
    movlw 0x1F
    andwf ad_valh,F
    movlw 0xE0
    btfsc ad_valh,4
    iorwf ad_valh,F
;
    movf ad_valh,W
    movwf INDF0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sample:
    clrf ad_cur
	bsf LATC,0
    bsf LATC,1
    movlw 4
    movwf ad_cnt
    bcf LATC,3
    bsf LATC,5
    movlw 4
    movwf temp0
;
    lfsr FSR0,ad00
    lfsr FSR1,ad10
;
    movf INDF0,W
    movwf ad_conf
;
    bcf LATC,0
    goto ad_init_loop1

ad_init_set0:
    bcf LATC,5
    goto ad_init_clk0

ad_init_loop0:
    bsf LATC,3
    rlcf ad_conf,F

ad_init_bit0:
    btfsc STATUS,C
    goto ad_init_set1

ad_init_clk0:
    bcf LATC,3
    decfsz temp0,F
    bra ad_init_loop0
;
    goto ad_init_done

ad_init_set1:
    bsf LATC,5
    goto ad_init_clk1

ad_init_loop1:
    bsf LATC,3
    rlcf ad_conf,F

ad_init_bit1:
    btfss STATUS,C
    goto ad_init_set0

ad_init_clk1:
    bcf LATC,3
    decfsz temp0,F
    bra ad_init_loop1

ad_init_done:
    bsf LATC,3
    call WaitSample
    bcf LATC,3
    nop
    nop
    nop

sample_start:
    bsf LATC,3
    nop
    nop
    nop
    bcf LATC,3
;
    bcf LATC,5
;
    btfsc ad_cur,0
    goto sample_start1

sample_start0:
    bcf LATC,1
    movf INDF1,W
    movwf ad_conf
    goto sample_started

sample_start1:
	bcf LATC,0
    movf INDF0,W
    movwf ad_conf

sample_started:
    clrf ad_vall
    clrf ad_valh
    movlw 9
    movwf temp0

sample_pre_loop0:
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    bsf LATC,3
    btfsc PORTC,4
    bsf ad_vall,0
    bcf LATC,3
    decfsz temp0,F
    bra sample_pre_loop0
;            
    bsf LATC,5
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    bsf LATC,3
    btfsc PORTC,4
    bsf ad_vall,0
    bcf LATC,3
;            
	movlw 4
    movwf temp0
    goto sample_loop1

sample_set0:
    bcf LATC,5
    goto sample_clk0

sample_loop0:
    bsf LATC,3
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    rlcf ad_conf,F

sample_bit0:
    btfsc STATUS,C
    goto sample_set1

sample_clk0:
    btfsc PORTC,4
    bsf ad_vall,0
;
    bcf LATC,3
    decfsz temp0,F
    bra sample_loop0
;
    goto sample_done

sample_set1:
    bsf LATC,5
    goto sample_clk1

sample_loop1:
    bsf LATC,3
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    rlcf ad_conf,F

sample_bit1:
    btfss STATUS,C
    goto sample_set0

sample_clk1:
    btfsc PORTC,4
    bsf ad_vall,0
;
    bcf LATC,3
    decfsz temp0,F
    bra sample_loop1

sample_done:
    btfsc ad_cur,0
    goto sample_done1

sample_done0:
    bsf LATC,0
    bsf ad_cur,0
    incf FSR0L,F
    movf ad_vall,W
    movwf INDF0
    incf FSR0L,F
;
    movlw 0x1F
    andwf ad_valh,F
    movlw 0xE0
    btfsc ad_valh,4
    iorwf ad_valh,F
;
    movf ad_valh,W
    movwf INDF0
    incf FSR0L,F
    incf FSR0L,F
    decfsz ad_cnt,F
    goto sample_start
;
    bsf LATC,3
    nop
    nop
    nop
    bcf LATC,3
;
    clrf ad_vall
    clrf ad_valh
    movlw 0xE
    movwf temp0

sample_last_loop:
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    bsf LATC,3
    btfsc PORTC,4
    bsf ad_vall,0
    bcf LATC,3
    decfsz temp0,F
    bra sample_last_loop
        
sample_done1:
    bsf LATC,1
    bcf ad_cur,0
    incf FSR1L,F
    movf ad_vall,W
    movwf INDF1
    incf FSR1L,F
;
    movlw 0x1F
    andwf ad_valh,F
    movlw 0xE0
    btfsc ad_valh,4
    iorwf ad_valh,F
;
    movf ad_valh,W
    movwf INDF1
    incf FSR1L,F
    incf FSR1L,F
    movf ad_cnt,W
    btfss STATUS,Z
    goto sample_start
    return 
 
    end
