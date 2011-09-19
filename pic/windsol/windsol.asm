#include p18f2423.inc

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

FLAG_WIND_U_INCREASE        EQU 0
FLAG_WIND_POWER_INCREASE    EQU 1
FLAG_WIND_WAIT_LOAD			EQU 2
FLAG_WIND_WAIT_UNLOAD		EQU 3
FLAG_SOLAR_U_INCREASE       EQU 4
FLAG_SOLAR_POWER_INCREASE   EQU 5
FLAG_SKIP_TX				EQU 6

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
wind_p4			EQU 0x1D

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

wind_cp_0       EQU 0x28
wind_cp_1       EQU 0x29
wind_cp_2       EQU 0x2A

load_delay_lsb	EQU 0x2B
load_delay_msb	EQU 0x2C

solar_ref_lsb	EQU 0x2D
solar_ref_msb	EQU 0x2E

solar_cp_0      EQU 0x2F
solar_cp_1      EQU 0x30
solar_cp_2      EQU 0x31

solar_yloop     EQU 0x32
solar_iloop     EQU 0x33

solar_p0		EQU 0x34
solar_p1		EQU 0x35
solar_p2		EQU 0x36
solar_p3		EQU 0x37

solar_pp0       EQU 0x38
solar_pp1       EQU 0x39
solar_pp2       EQU 0x3A
solar_pp3       EQU 0x3B

wind_ps0        EQU 0x3C
wind_ps1        EQU 0x3D
wind_ps2        EQU 0x3E
wind_ps3		EQU 0x3F

solar_ps0       EQU 0x40
solar_ps1       EQU 0x41
solar_ps2       EQU 0x42
solar_ps3       EQU 0x43

sec_lsb         EQU 0x46
sec_msb         EQU 0x47

val0			EQU 0x48
val1			EQU 0x49
val2			EQU 0x4A
val3			EQU 0x4B

; serial buffer page (1)

ser_buf         EQU 0x100

    goto ResetStart

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tables (first 255 words)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

w2:
    DW 0
    DW 0x9C4

w1:
    DW 0
    DW 0xFA

w0:
    DW 0
    DW 0x19

mw2:
    DW 0x8000
    DW 2 

mw1:
    DW 0x4000
    DW 0

mw0:    
    DW 0x0667
    DW 0

ui2:
    DW 0xFA0

ui1:
    DW 0x190

ui0:
    DW 0x28

mui2:
    DW 0x4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tables (first 255 words)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetStart:
    movlw b'00000001'
    movwf PORTA
    movwf LATA
;
    movlw b'11111110'
    movwf TRISA
;
	movlw b'00001100'
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
    movlw b'11010000'
    movwf TRISC
;
    movlw b'10000111'
    movwf T0CON
;
    movlw b'11111111'
    movwf OSCCON
;
    movlw 0xCF
    movwf SPBRG
;
    movlw 0
    movwf SPBRGH
;
    movlw b'00001000'
    movwf BAUDCON
;
	movlw b'00100100'
    movwf TXSTA
;
    movlw b'10010000'
    movwf RCSTA
;
    clrf TBLPTRH
    clrf TBLPTRU
;
	clrf wind_p0
    clrf wind_p1
    clrf wind_p2
    clrf wind_p3
    clrf wind_p4
;
	clrf solar_p0
    clrf solar_p1
    clrf solar_p2
    clrf solar_p3
;
	clrf wind_ps0
    clrf wind_ps1
    clrf wind_ps2
    clrf wind_ps3
;
	clrf solar_ps0
    clrf solar_ps1
    clrf solar_ps2
    clrf solar_ps3
;
    clrf sec_lsb
    movlw 4
    movwf sec_msb
;
    lfsr 2,ser_buf
    clrf INDF2
;
    movlw 0x0
    movwf wind_ref_lsb
    movlw 0x5
    movwf wind_ref_msb
    call SetupWind
    bsf flags,FLAG_WIND_U_INCREASE
;
    movlw 0x0
    movwf solar_ref_lsb
    movlw 0x2
    movwf solar_ref_msb
    call SetupSolar
    bsf flags,FLAG_SOLAR_U_INCREASE
   
HandleLoop:
    bsf LATA,0
    call WaitForSample
	call Sample
	call PollWind
    call PollSolar
    call PollStat
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
    movlw 0x80
    movwf wind_yloop
;
    movlw 0x80
    movwf wind_iloop

PollWindNotUnload:
    call CalcWindPower
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
; CalcWindPower
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcWindPower:
    clrf wind_cp_0
    clrf wind_cp_1
    clrf wind_cp_2
;   
    btfsc wind_u_msb,7
    return
;
	btfsc wind_i_msb,7
    return
;
    movf wind_u_lsb,W
    mulwf wind_i_lsb
    movf PRODL,W
    addwf wind_cp_0,F
    movf PRODH,W
    addwfc wind_cp_1,F
;
    movf wind_u_lsb,W
    mulwf wind_i_msb
    movf PRODL,W
    addwf wind_cp_1,F
    movf PRODH,W
    addwfc wind_cp_2,F
;    
    movf wind_u_msb,W
    mulwf wind_i_lsb
    movf PRODL,W
    addwf wind_cp_1,F
    movf PRODH,W
    addwfc wind_cp_2,F
;
    movf wind_u_msb,W
    mulwf wind_i_msb
    movf PRODL,W
    addwf wind_cp_2,F
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
    movlw 6
    cpfslt wind_p4
    goto WindControlDecrease
;
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
    bcf flags,FLAG_WIND_U_INCREASE
	movlw 0xEC
    addwf wind_ref_lsb,F
    movlw 0xFF
    addwfc wind_ref_msb,F
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
	movf wind_ref_msb,W
    btfss STATUS,Z
    goto SetupWindInRange
;
    movlw 0
    movwf wind_ref_lsb
    movlw 1
    movwf wind_ref_msb

SetupWindInRange:
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
    movf wind_cp_0,W
    addwf wind_p0,F
;
    movf wind_cp_1,W
    addwfc wind_p1,F
;
    movf wind_cp_2,W
    addwfc wind_p2,F
;
    movlw 0
    addwfc wind_p3,F
    addwfc wind_p4,F
;    
    movf wind_cp_0,W
    addwf wind_ps0,F
;
    movf wind_cp_1,W
    addwfc wind_ps1,F
;
    movf wind_cp_2,W
    addwfc wind_ps2,F
;
    movlw 0
    addwfc wind_ps3,F
	return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PollSolar
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollSolar:
    call UpdateSolarCharger
    call CalcSolarPower
    call UpdateSolarPower
;
    decfsz solar_iloop,F
    return
;
    movlw 0x80
    movwf solar_iloop
;
    decfsz solar_yloop,F
    return
;
    call SolarPowerCompare
    call SolarControl
    call SetupSolar    
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CalcSolarPower
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcSolarPower:
    clrf solar_cp_0
    clrf solar_cp_1
    clrf solar_cp_2
;   
    btfsc solar_u_msb,7
    return
;
	btfsc solar_i_msb,7
    return
;
    movf solar_u_lsb,W
    mulwf solar_i_lsb
    movf PRODL,W
    addwf solar_cp_0,F
    movf PRODH,W
    addwfc solar_cp_1,F
;
    movf solar_u_lsb,W
    mulwf solar_i_msb
    movf PRODL,W
    addwf solar_cp_1,F
    movf PRODH,W
    addwfc solar_cp_2,F
;    
    movf solar_u_msb,W
    mulwf solar_i_lsb
    movf PRODL,W
    addwf solar_cp_1,F
    movf PRODH,W
    addwfc solar_cp_2,F
;
    movf solar_u_msb,W
    mulwf solar_i_msb
    movf PRODL,W
    addwf solar_cp_2,F
    return            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateSolarPower
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSolarPower:
    movf solar_cp_0,W
    addwf solar_p0,F
;
    movf solar_cp_1,W
    addwfc solar_p1,F
;
    movf solar_cp_2,W
    addwfc solar_p2,F
;    
    movlw 0
    addwfc solar_p3,F
;    
    movf solar_cp_0,W
    addwf solar_ps0,F
;
    movf solar_cp_1,W
    addwfc solar_ps1,F
;
    movf solar_cp_2,W
    addwfc solar_ps2,F
;    
    movlw 0
    addwfc solar_ps3,F
	return
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SolarPowerCompare
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SolarPowerCompare:
    movf solar_p3,W
    cpfseq solar_pp3
    goto SolarPower3Ne
	goto SolarPower3Eq

SolarPower3Ne:
    cpfsgt solar_pp3
    goto SolarNewLarger
    goto SolarOldLarger

SolarPower3Eq:
    movf solar_p2,W
    cpfseq solar_pp2
    goto SolarPower2Ne
	goto SolarPower2Eq

SolarPower2Ne:
    cpfsgt solar_pp2
    goto SolarNewLarger
    goto SolarOldLarger

SolarPower2Eq:
    movf solar_p1,W
    cpfseq solar_pp1
    goto SolarPower1Ne
    goto SolarPower1Eq

SolarPower1Ne:
    cpfsgt solar_pp1
    goto SolarNewLarger
    goto SolarOldLarger

SolarPower1Eq:
    movf solar_p0,W
    cpfslt solar_pp0
    goto SolarOldLarger

SolarNewLarger:
    bsf flags,FLAG_SOLAR_POWER_INCREASE
    return

SolarOldLarger:
    bcf flags,FLAG_SOLAR_POWER_INCREASE
    return
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SolarControl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SolarControl:
    btfsc flags,FLAG_SOLAR_POWER_INCREASE
    goto SolarControlMorePower
;
    movf solar_p0,W
    iorwf solar_p1,W
    iorwf solar_p2,W
    iorwf solar_p3,W
    btfss STATUS,Z
    goto SolarControlLessPower

SolarControlNoPower:
    movf solar_ref_lsb,W
    iorwf solar_ref_msb,W
    btfsc STATUS,Z
    goto SolarControlIncrease
;
    movf solar_u_lsb,W
    movwf solar_ref_lsb
    movwf temp0
    movf solar_u_msb,W
    movwf solar_ref_msb
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
    addwfc solar_ref_lsb,F
    movf temp1,W
    addwfc solar_ref_msb,F    
    bcf flags,FLAG_SOLAR_U_INCREASE
    return

SolarControlMorePower:
    btfss flags,FLAG_SOLAR_U_INCREASE
    goto SolarControlDecrease

SolarControlIncrease:
	movlw 0x14
    addwf solar_ref_lsb,F
    movlw 0
    addwfc solar_ref_msb,F
    bsf flags,FLAG_SOLAR_U_INCREASE
    return

SolarControlLessPower:
    btfss flags,FLAG_SOLAR_U_INCREASE
    goto SolarControlIncrease
    
SolarControlDecrease:
	movlw 0xEC
    addwf solar_ref_lsb,F
    movlw 0xFF
    addwfc solar_ref_msb,F
    bcf flags,FLAG_SOLAR_U_INCREASE
;
    btfss STATUS,C
    goto SolarControlZero
;
    return

SolarControlZero:
    clrf solar_ref_lsb
    clrf solar_ref_msb
    bcf flags,FLAG_SOLAR_U_INCREASE
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetupSolar
; solar_ref voltage reference
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSolar:
    movf solar_ref_lsb,W
    movwf temp0
    movwf solar_low_lsb
    movwf solar_high_lsb
;
    movf solar_ref_msb,W
    movwf temp1
    movwf solar_low_msb
    movwf solar_high_msb
;
    movlw 4
    movwf temp2

ssRotateLoop:
    bcf STATUS,C
    rrcf temp1,F
    rrcf temp0,F
    decfsz temp2,F
    goto ssRotateLoop
;
    movlw 1
    addwf temp0,F
    movlw 0
    addwfc temp1,F
;    
    movf temp0,W
    addwf solar_high_lsb,F
    movf temp1,W
    addwfc solar_high_msb,F
;     
    comf temp0,F
    comf temp1,F
    movlw 1
    addwf temp0,F
    movlw 0
    addwfc temp1,F
;    
    movf temp0,W
    addwf solar_low_lsb,F
    movf temp1,W
    addwfc solar_low_msb,F
;
    movf solar_p0,W
    movwf solar_pp0
    movf solar_p1,W
    movwf solar_pp1
    movf solar_p2,W
    movwf solar_pp2
    movf solar_p3,W
    movwf solar_pp3
;
	clrf solar_p0
    clrf solar_p1
    clrf solar_p2
    clrf solar_p3
;
    movlw 0x80
    movwf solar_yloop
;
    movlw 0x80
    movwf solar_iloop        
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateSolarCharger
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSolarCharger:
    btfsc LATB,3
    goto UpdateSolarChargerOff

UpdateSolarChargerOn:
    btfsc solar_u_msb,7
    goto UpdateSolarChargerTurnOff
;
    movf solar_low_msb,W
    cpfseq solar_u_msb
    goto UpdateSolarChargerOnNotEq
;
    movf solar_low_lsb,W
    cpfslt solar_u_lsb
    return
    goto UpdateSolarChargerTurnOff

UpdateSolarChargerOnNotEq:
    cpfslt solar_u_msb
    return

UpdateSolarChargerTurnOff:
    bsf LATB,3
    return
    
UpdateSolarChargerOff:
    btfsc solar_u_msb,7
    return
;
    movf solar_high_msb,W
    cpfseq solar_u_msb
    goto UpdateSolarChargerOffNotEq
;
    movf solar_high_lsb,W
    cpfsgt solar_u_lsb
    return
    goto UpdateSolarChargerTurnOn

UpdateSolarChargerOffNotEq:
    cpfsgt solar_u_msb
    return

UpdateSolarChargerTurnOn:
    bcf LATB,3
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Conv2One
;    FSR0:  2 byte power
;    FSR1:  Buffer in/out
;    TBLPTR: Table to use
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Conv2One:
    tblrd *+
    movf TABLAT,W
    movwf temp0
;    
    tblrd *+
    movf TABLAT,W
    movwf temp1
;
    movlw '0'
    movwf INDF1

Conv2OneLoop:
    movf temp0,W
    subwf val0,F
;
    movf temp1,W
    subwfb val1,F
; 
    btfss STATUS,C
    goto Conv2OneRevert

Conv2OneIncDec:
    incf INDF1
    goto Conv2OneLoop

Conv2OneRevert:
    movf temp0,W
    addwf val0,F
;
    movf temp1,W
    addwfc val1,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Conv4One
;    FSR0:  4 byte power
;    FSR1:  Buffer in/out
;    TBLPTR: Table to use
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Conv4One:
    tblrd *+
    movf TABLAT,W
    movwf temp0
;    
    tblrd *+
    movf TABLAT,W
    movwf temp1
;
    tblrd *+
    movf TABLAT,W
    movwf temp2
;    
    tblrd *+
    movf TABLAT,W
    movwf temp3
;
    movlw '0'
    movwf INDF1

Conv4OneLoop:
    movf temp0,W
    subwf val0,F
;
    movf temp1,W
    subwfb val1,F
;
    movf temp2,W
    subwfb val2,F
;
    movf temp3,W
    subwfb val3,F
; 
    btfss STATUS,C
    goto Conv4OneRevert

Conv4OneIncDec:
    incf INDF1
    goto Conv4OneLoop

Conv4OneRevert:
    movf temp0,W
    addwf val0,F
;
    movf temp1,W
    addwfc val1,F
;
    movf temp2,W
    addwfc val2,F
;
    movf temp3,W
    addwfc val3,F
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ConvPower
;    FSR0:  4 byte power
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvPower:
    movf INDF0,W
    movwf val0
    incf FSR0L,F
;
    movf INDF0,W
    movwf val1
    incf FSR0L,F
;
    movf INDF0,W
    movwf val2
    incf FSR0L,F
;
    movf INDF0,W
    movwf val3
;
    movlw w2
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw w1
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw w0
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw '.'
    movwf INDF1
;
    incf FSR1L,F
    movlw mw2
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw mw1
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw mw0
    movwf TBLPTRL
    call Conv4One    
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ConvUI
;    FSR0:  2 byte voltage / current
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvUI:
    movf INDF0,W
    movwf val0
    incf FSR0L,F
;
    movf INDF0,W
    movwf val1
    incf FSR0L,F
;
    movlw ui2
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw ui1
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw ui0
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw '.'
    movwf INDF1
;
    incf FSR1L,F
    movlw mui2
    movwf TBLPTRL
    call Conv2One
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CreateStat
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateStat:
    lfsr 0,wind_ps0
    lfsr 1,ser_buf
    call ConvPower
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar_ps0
    call ConvPower
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,wind_ref_lsb
    call ConvUI
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar_ref_lsb
    call ConvUI
;
    incf FSR1L,F
    movlw 0xD
    movwf INDF1
;
    incf FSR1L,F
    movlw 0xA
    movwf INDF1
;
    incf FSR1L,F
    clrf INDF1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PollStat
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollStat:
    decfsz sec_lsb,F
    return
;
    decfsz sec_msb,F
    return
;
    movlw 4
    movwf sec_msb
    call CreateStat
;
	clrf wind_ps0
    clrf wind_ps1
    clrf wind_ps2
    clrf wind_ps3
;
	clrf solar_ps0
    clrf solar_ps1
    clrf solar_ps2
    clrf solar_ps3
;
    lfsr 2,ser_buf
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WaitForSample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForSample:
    btfsc flags, FLAG_SKIP_TX
    goto WaitForSampleSkip    
;
    movf INDF2,W
    btfsc STATUS,Z
    goto WaitForSampleLoop
;
    movwf TXREG
    incf FSR2L,F
;
    bsf flags, FLAG_SKIP_TX
    goto WaitForSampleLoop

WaitForSampleSkip:
    bcf flags, FLAG_SKIP_TX

WaitForSampleLoop:
    btfsc TMR0L,1
    goto WaitForSampleLoop
;
    btfsc TMR0L,2
    goto WaitForSampleLoop
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
