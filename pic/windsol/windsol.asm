#include p18f2423.inc

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

temp	EQU 0x0
ad_cnt	EQU 0x1

ad_conf	EQU 0x2

ad_vall	EQU 0x3
ad_valh	EQU 0x4

ad_cur	EQU 0x5

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
;
    call LoadAdTab

HandleLoop:
	call Sample
;
    lfsr FSR0, ad01h
    btfsc INDF0,7
    goto HandleLow
;
    movlw 3
    cpfsgt INDF0
    goto HandleLow

HandleHigh:
    bcf LATB,0
    goto HandleLoop

HandleLow:
    bsf LATB,0
    goto HandleLoop

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
    movwf temp

LoadAd0:
    tblrd *+
    movf TABLAT,W
    movwf INDF0
    movlw 4
    addwf FSR0L,F
    decfsz temp
    bra LoadAd0
;
    movlw AdTab1
    movwf TBLPTRL
    lfsr FSR0,ad10
;
	movlw 4
    movwf temp

LoadAd1:
    tblrd *+
    movf TABLAT,W
    movwf INDF0
    movlw 4
    addwf FSR0L,F
    decfsz temp,F
    bra LoadAd1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WaitSample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitSample:
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
    movwf temp
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
    decfsz temp,F
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
    decfsz temp,F
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
    movwf temp

sample_pre_loop0:
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    bsf LATC,3
    btfsc PORTC,4
    bsf ad_vall,0
    bcf LATC,3
    decfsz temp,F
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
    movwf temp
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
    decfsz temp,F
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
    decfsz temp,F
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
    movwf temp

sample_last_loop:
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    bsf LATC,3
    btfsc PORTC,4
    bsf ad_vall,0
    bcf LATC,3
    decfsz temp,F
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
