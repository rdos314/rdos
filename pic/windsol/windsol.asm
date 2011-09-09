#include p18f2423.inc

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

FLAG_WIND_U_INCREASE        EQU 0
FLAG_WIND_POWER_INCREASE    EQU 1
FLAG_WIND_WAIT_LOAD			EQU 2
FLAG_WIND_WAIT_UNLOAD		EQU 3

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

wind_u_lsb		EQU 0xD
wind_u_msb		EQU 0xE

wind_i_lsb		EQU 0xF
wind_i_msb		EQU 0x10

solar_low_lsb   EQU 0x11
solar_low_msb   EQU 0x12
solar_high_lsb  EQU 0x13
solar_high_msb  EQU 0x14

solar_u_lsb		EQU 0x15
solar_u_msb		EQU 0x16

solar_i_lsb		EQU 0x17
solar_i_msb		EQU 0x18

wind_p0			EQU 0x19
wind_p1			EQU 0x1A
wind_p2			EQU 0x1B
wind_p3			EQU 0x1C
wind_p4         EQU 0x1D

wind_ref_lsb	EQU 0x1E
wind_ref_msb	EQU 0x1F

wind_yloop      EQU 0x20
wind_iloop      EQU 0x21

flags			EQU 0x22

wind_pp0        EQU 0x23
wind_pp1        EQU 0x24
wind_pp2        EQU 0x25
wind_pp3		EQU 0x26
wind_pp4		EQU 0x27

wind_u2_0       EQU 0x28
wind_u2_1       EQU 0x29
wind_u2_2       EQU 0x2A

load_delay_lsb	EQU 0x2B
load_delay_msb	EQU 0x2C

Arg1l	EQU 0x40
Arg1h	EQU 0x41
Arg2l	EQU 0x42
Arg2h	EQU 0x43
Res0	EQU 0x44
Res1	EQU 0x45
Res2	EQU 0x46
Res3	EQU 0x47


    goto ResetStart

ResetStart:
    movlw b'00000001'
    movwf PORTA
    movwf LATA
;
    movlw b'11111110'
    movwf TRISA
;
	movlw b'00000000'
    movwf PORTB
    movwf LATB
;
    movlw b'11100000'
    movwf TRISB
;
    movlw b'10100111'
    movwf PORTC
    movwf LATC
;
    movlw b'10010000'
    movwf TRISC
;
    movlw b'10000111'
    movwf T0CON
;
    movlw b'11111111'
    movwf OSCCON
;
	clrf wind_p0
    clrf wind_p1
    clrf wind_p2
    clrf wind_p3
    clrf wind_p4
;
    movlw 0x0
    movwf wind_ref_lsb
    movlw 0x5
    movwf wind_ref_msb
    call SetupWind
    bsf flags,FLAG_WIND_U_INCREASE
   
HandleLoop:
    bsf LATA,0
    call WaitForSample
	call Sample
	call PollWind
    goto HandleLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PollWind
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollWind:
    call UpdateWindDump
    btfss flags,FLAG_WIND_WAIT_LOAD
    goto PollWindNotLoad

PollWindLoad:
    btfsc LATB,0
    goto PollWindClearLoad
;
    decfsz load_delay_lsb,F
    return
;
    movlw 0x80
    movwf load_delay_lsb
;
    decfsz load_delay_msb,F
    return
    goto PollWindReport

PollWindClearLoad:
    bsf flags,FLAG_WIND_WAIT_UNLOAD
    bcf flags,FLAG_WIND_WAIT_LOAD
    
PollWindNotLoad:
    btfss flags,FLAG_WIND_WAIT_UNLOAD
    goto PollWindNotUnload

PollWindUnload:
    btfsc LATB,0
    return
;
    bcf flags,FLAG_WIND_WAIT_UNLOAD
    movlw 0x40
    movwf wind_yloop
;
    movlw 0x80
    movwf wind_iloop

PollWindNotUnload:
    call WindSquare
    call UpdateWindPower
;
    decfsz wind_iloop,F
    return
;
    movlw 0x80
    movwf wind_iloop
;
    decfsz wind_yloop,F
    return

PollWindReport:
    call WindPowerCompare
    call WindControl
    call SetupWind
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WindSquare
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WindSquare:
    clrf wind_u2_0
    clrf wind_u2_1
    clrf wind_u2_2
;   
    btfsc wind_u_msb,7
    return
;
    movf wind_u_lsb,W
    mulwf wind_u_lsb
    movf PRODL,W
    addwf wind_u2_0,F
    movf PRODH,W
    addwfc wind_u2_1,F
;
    movf wind_u_lsb,W
    mulwf wind_u_msb
    movf PRODL,W
    addwf wind_u2_1,F
    movf PRODH,W
    addwfc wind_u2_2,F
    movf PRODL,W
    addwf wind_u2_1,F
    movf PRODH,W
    addwfc wind_u2_2,F
;
    movf wind_u_msb,W
    mulwf wind_u_msb
    movf PRODL,W
    addwf wind_u2_2,F
    return            
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WindPowerCompare
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WindPowerCompare:
    movf wind_p4,W
    cpfseq wind_pp4
    goto WindPower4Ne
	goto WindPower4Eq

WindPower4Ne:
    cpfsgt wind_pp4
    goto WindNewLarger
    goto WindOldLarger

WindPower4Eq:
    movf wind_p3,W
    cpfseq wind_pp3
    goto WindPower3Ne
	goto WindPower3Eq

WindPower3Ne:
    cpfsgt wind_pp3
    goto WindNewLarger
    goto WindOldLarger

WindPower3Eq:
    movf wind_p2,W
    cpfseq wind_pp2
    goto WindPower2Ne
	goto WindPower2Eq

WindPower2Ne:
    cpfsgt wind_pp2
    goto WindNewLarger
    goto WindOldLarger

WindPower2Eq:
    movf wind_p1,W
    cpfseq wind_pp1
    goto WindPower1Ne
    goto WindPower1Eq

WindPower1Ne:
    cpfsgt wind_pp1
    goto WindNewLarger
    goto WindOldLarger

WindPower1Eq:
    movf wind_p0,W
    cpfslt wind_pp0
    goto WindOldLarger

WindNewLarger:
    bsf flags,FLAG_WIND_POWER_INCREASE
    return

WindOldLarger:
    bcf flags,FLAG_WIND_POWER_INCREASE
    return
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WindControl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WindControl:
    btfsc flags,FLAG_WIND_POWER_INCREASE
    goto WindControlMorePower
;
    movf wind_p0,W
    iorwf wind_p1,W
    iorwf wind_p2,W
    iorwf wind_p3,W
    iorwf wind_p4,W
    btfss STATUS,Z
    goto WindControlLessPower

WindControlNoPower:
    movf wind_ref_lsb,W
    iorwf wind_ref_msb,W
    btfsc STATUS,Z
    goto WindControlIncrease
;
    movf wind_u_lsb,W
    movwf wind_ref_lsb
    movwf temp0
    movf wind_u_msb,W
    movwf wind_ref_msb
    movwf temp1
;
    bcf STATUS,C
    rrcf temp1,F
    rrcf temp0,F
    bcf STATUS,C
    rrcf temp1,F
    rrcf temp0,F
    comf temp1,F
    comf temp0,F
;
    movf temp0,W
    bsf STATUS,C
    addwfc wind_ref_lsb,F
    movf temp1,W
    addwfc wind_ref_msb,F    
    bcf flags,FLAG_WIND_U_INCREASE
    return

WindControlMorePower:
    btfss flags,FLAG_WIND_U_INCREASE
    goto WindControlDecrease

WindControlIncrease:
	movlw 0x14
    addwf wind_ref_lsb,F
    movlw 0
    addwfc wind_ref_msb,F
    bsf flags,FLAG_WIND_U_INCREASE
    return

WindControlLessPower:
    btfss flags,FLAG_WIND_U_INCREASE
    goto WindControlIncrease
    
WindControlDecrease:
	movlw 0xEC
    addwf wind_ref_lsb,F
    movlw 0xFF
    addwfc wind_ref_msb,F
    bcf flags,FLAG_WIND_U_INCREASE
;
    btfss STATUS,C
    goto WindControlZero
;
    return

WindControlZero:
    clrf wind_ref_lsb
    clrf wind_ref_msb
    bcf flags,FLAG_WIND_U_INCREASE
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetupWind
; wind_ref voltage reference
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupWind:
    movf wind_ref_lsb,W
    movwf temp0
    movwf wind_low_lsb
    movwf wind_high_lsb
;
    movf wind_ref_msb,W
    movwf temp1
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
;
    movf wind_p0,W
    movwf wind_pp0
    movf wind_p1,W
    movwf wind_pp1
    movf wind_p2,W
    movwf wind_pp2
    movf wind_p3,W
    movwf wind_pp3
    movf wind_p4,W
    movwf wind_pp4
;
	clrf wind_p0
    clrf wind_p1
    clrf wind_p2
    clrf wind_p3
    clrf wind_p4
;
    bsf flags,FLAG_WIND_WAIT_LOAD
;
    movlw 0x80
    movwf load_delay_msb
    movwf load_delay_lsb
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateWindDump
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateWindDump:
    btfss LATB,0
    goto UpdateWindDumpOff

UpdateWindDumpOn:
    bcf LATA,0
    btfsc wind_u_msb,7
    goto UpdateWindDumpTurnOff
;
    movf wind_low_msb,W
    cpfseq wind_u_msb
    goto UpdateWindDumpOnNotEq
;
    movf wind_low_lsb,W
    cpfslt wind_u_lsb
    return
    goto UpdateWindDumpTurnOff

UpdateWindDumpOnNotEq:
    cpfslt wind_u_msb
    return

UpdateWindDumpTurnOff:
    bcf LATB,0
    return
    
UpdateWindDumpOff:
    btfsc wind_u_msb,7
    return
;
    movf wind_high_msb,W
    cpfseq wind_u_msb
    goto UpdateWindDumpOffNotEq
;
    movf wind_high_lsb,W
    cpfsgt wind_u_lsb
    return
    goto UpdateWindDumpTurnOn

UpdateWindDumpOffNotEq:
    cpfsgt wind_u_msb
    return

UpdateWindDumpTurnOn:
    bsf LATB,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateWindPower
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateWindPower:
    btfss LATB,0
	return
;
    movf wind_u2_0,W
    addwf wind_p0,F
;
    movf wind_u2_1,W
    addwfc wind_p1,F
;
    movf wind_u2_2,W
    addwfc wind_p2,F
;
    movlw 0
    addwfc wind_p3,F
    addwfc wind_p4,F
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
; WaitForSample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForSample:
    btfsc TMR0L,1
    goto WaitForSample
;
    btfsc TMR0L,2
    goto WaitForSample
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SampleOneA
; IN   W   config word
; OUT  ad_vall, ad_valh
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SampleOne:
    movwf ad_conf
;
    movlw 4
    movwf temp0
    goto sample_one_loop1

sample_one_set0:
    bcf LATC,5
    goto sample_one_clk0

sample_one_loop0:
    bsf LATC,3
    rlcf ad_conf,F

sample_one_a_bit0:
    btfsc STATUS,C
    goto sample_one_set1

sample_one_clk0:
    bcf LATC,3
    decfsz temp0,F
    bra sample_one_loop0
;
    goto sample_one_setup_ok

sample_one_set1:
    bsf LATC,5
    goto sample_one_clk1

sample_one_loop1:
    bsf LATC,3
    rlcf ad_conf,F

sample_one_bit1:
    btfss STATUS,C
    goto sample_one_set0

sample_one_clk1:
    bcf LATC,3
    decfsz temp0,F
    bra sample_one_loop1

sample_one_setup_ok:
    bsf LATC,3
    nop
;
    bcf LATC,3
    nop
;
    bsf LATC,3
    clrf ad_vall
    clrf ad_valh
    movlw 0xE
    movwf temp0
    bsf LATC,5
;
    bcf LATC,3

sample_one_loop:
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    bsf LATC,3
    btfsc PORTC,4
    bsf ad_vall,0
    bcf LATC,3
    decfsz temp0,F
    bra sample_one_loop
;
    movlw 0x1F
    andwf ad_valh,F
    movlw 0xE0
    btfsc ad_valh,4
    iorwf ad_valh,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sample:
    movlw 0x30
    bcf LATC,0
    call SampleOne
    bsf LATC,0
;
    movf ad_vall,W
    movwf wind_u_lsb
;
    movf ad_valh,W
    movwf wind_u_msb
;    
    movlw 0x50
    bcf LATC,0
    call SampleOne
    bsf LATC,0
;
    movf ad_vall,W
    movwf solar_u_lsb
;
    movf ad_valh,W
    movwf solar_u_msb
;    
    movlw 0x80
    bcf LATC,1
    call SampleOne
    bsf LATC,1
;
    movf ad_vall,W
    movwf wind_i_lsb
;
    movf ad_valh,W
    movwf wind_i_msb
;    
    movlw 0x60
    bcf LATC,0
    call SampleOne
    bsf LATC,0
;
    movf ad_vall,W
    movwf solar_i_lsb
;
    movf ad_valh,W
    movwf solar_i_msb
    return
 
    end
