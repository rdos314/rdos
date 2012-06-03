#include p18f2423.inc

#DEFINE PAGE0   BCF 3,5
#DEFINE PAGE1   BSF 3,5

FLAG_SOLAR12_U_INCREASE       EQU 0
FLAG_SOLAR12_POWER_INCREASE   EQU 1
FLAG_SOLAR24_U_INCREASE       EQU 2
FLAG_SOLAR24_POWER_INCREASE   EQU 3
FLAG_SOLAR24_CHARGE           EQU 4

temp0	EQU 0x0
temp1   EQU 0x1
temp2   EQU 0x2
temp3   EQU 0x3
ad_cnt	EQU 0x4

ad_conf	EQU 0x5

ad_vall	EQU 0x6
ad_valh	EQU 0x7

ad_cur	EQU 0x8

solar12_low_lsb     EQU 0x9
solar12_low_msb     EQU 0xa
solar12_high_lsb    EQU 0xb
solar12_high_msb    EQU 0xc

solar12_u_lsb	    EQU 0xd
solar12_u_msb		EQU 0xe

solar12_i_lsb		EQU 0xf
solar12_i_msb		EQU 0x10

solar24_low_lsb     EQU 0x11
solar24_low_msb     EQU 0x12
solar24_high_lsb    EQU 0x13
solar24_high_msb    EQU 0x14

solar24_u_lsb		EQU 0x15
solar24_u_msb		EQU 0x16

solar24_i_lsb		EQU 0x17
solar24_i_msb		EQU 0x18

flags			    EQU 0x19

solar12_ref_lsb	    EQU 0x1a
solar12_ref_msb	    EQU 0x1b

solar12_cp_0        EQU 0x1c
solar12_cp_1        EQU 0x1d
solar12_cp_2        EQU 0x1e

solar12_yloop       EQU 0x1f
solar12_iloop       EQU 0x20

solar12_p0		    EQU 0x21
solar12_p1		    EQU 0x22
solar12_p2		    EQU 0x23
solar12_p3		    EQU 0x24

solar12_pp0         EQU 0x25
solar12_pp1         EQU 0x26
solar12_pp2         EQU 0x27
solar12_pp3         EQU 0x28

solar24_ref_lsb	    EQU 0x29
solar24_ref_msb	    EQU 0x2a

solar24_cp_0        EQU 0x2b
solar24_cp_1        EQU 0x2c
solar24_cp_2        EQU 0x2d

solar24_yloop       EQU 0x2e
solar24_iloop       EQU 0x2f

solar24_p0		    EQU 0x30
solar24_p1		    EQU 0x31
solar24_p2		    EQU 0x32
solar24_p3		    EQU 0x33

solar24_pp0         EQU 0x34
solar24_pp1         EQU 0x35
solar24_pp2         EQU 0x36
solar24_pp3         EQU 0x37

solar12_ps0         EQU 0x38
solar12_ps1         EQU 0x39
solar12_ps2         EQU 0x3a
solar12_ps3         EQU 0x3b

solar24_ps0         EQU 0x3c
solar24_ps1         EQU 0x3d
solar24_ps2         EQU 0x3e
solar24_ps3         EQU 0x3f

bat_u_lsb           EQU 0x40
bat_u_msb           EQU 0x41

sec_lsb             EQU 0x42
sec_msb             EQU 0x43

val0			    EQU 0x44
val1			    EQU 0x45
val2			    EQU 0x46
val3			    EQU 0x47

tx_count		    EQU 0x48

; serial buffer page (1)

ser_buf         EQU 0x100

    goto ResetStart

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tables (first 255 words)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

w12_1:
    DW 0
    DW 0x2710

w12_0:
    DW 0
    DW 0x3E8

mw12_2:
    DW 0
    DW 0x64

mw12_1:
    DW 0
    DW 0xA

mw12_0:    
    DW 0
    DW 1

w24_2:
    DW 0
    DW 0x30D4

w24_1:
    DW 0
    DW 0x4E2

w24_0:
    DW 0
    DW 0x7D

mw24_2:
    DW 0x8000
    DW 0xC

mw24_1:
    DW 0x2000
    DW 1

mw24_0:    
    DW 0x2000
    DW 0

u12_2:
    DW 0x4E20

u12_1:
    DW 0x7D0

u12_0:
    DW 0xC8

mu12_2:
    DW 0x14

u24_2:
    DW 0x2710

u24_1:
    DW 0x3E8

u24_0:
    DW 0x64

mu24_2:
    DW 0xA

i24_2:
    DW 0x2710

i24_1:
    DW 0x3E8

i24_0:
    DW 0x64

mi24_2:
    DW 0xA

i12_1:
    DW 0xFA0

i12_0:
    DW 0x190

mi12_2:
    DW 0x28

mi12_1:
    DW 0x4

h4:
    DW 0x2710

h3:
    DW 0x3E8

h2:
    DW 0x64

h1:
    DW 0xA

h0:
    DW 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tables (first 255 words)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ResetStart:
    movlw b'00000000'
    movwf PORTA
    movwf LATA
;
    movlw b'11111111'
    movwf TRISA
;
	movlw b'00000000'
    movwf PORTB
    movwf LATB
;
    movlw b'0001000'
    movwf TRISB
;
    movlw b'10100101'
    movwf PORTC
    movwf LATC
;
    movlw b'10011000'
    movwf TRISC
;
    movlw b'10000111'
    movwf T0CON
;
    movlw b'11111111'
    movwf OSCCON
;
    movlw 0x40
    movwf SPBRG
;
    movlw 3
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
	clrf solar12_p0
    clrf solar12_p1
    clrf solar12_p2
    clrf solar12_p3
;
	clrf solar24_p0
    clrf solar24_p1
    clrf solar24_p2
    clrf solar24_p3
;
	clrf solar12_ps0
    clrf solar12_ps1
    clrf solar12_ps2
    clrf solar12_ps3
;
	clrf solar24_ps0
    clrf solar24_ps1
    clrf solar24_ps2
    clrf solar24_ps3
;
	movlw 6
    movwf tx_count
;
    clrf sec_lsb
    movlw 4
    movwf sec_msb
;
    lfsr 2,ser_buf
    clrf INDF2
;
    movlw 0x0
    movwf solar12_ref_lsb
    movlw 0xa
    movwf solar12_ref_msb
    call SetupSolar12
    bsf flags,FLAG_SOLAR12_U_INCREASE
;
    movlw 0x0
    movwf solar24_ref_lsb
    movlw 0xc
    movwf solar24_ref_msb
    call SetupSolar24
    bsf flags,FLAG_SOLAR24_U_INCREASE
   
HandleLoop:
    call WaitForSample
	call Sample
    call PollSolar12
    call PollSolar24
    call PollStat
    goto HandleLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PollSolar12
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollSolar12:
    call UpdateSolarCharger12
    call CalcSolarPower12
    call UpdateSolarPower12
;
    decfsz solar12_iloop,F
    return
;
    movlw 0x80
    movwf solar12_iloop
;
    decfsz solar12_yloop,F
    return
;
    call SolarPowerCompare12
;    call SolarControl12
    call SetupSolar12
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CalcSolarPower12
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcSolarPower12:
    clrf solar12_cp_0
    clrf solar12_cp_1
    clrf solar12_cp_2
;   
    btfsc solar12_u_msb,7
    return
;
	btfsc solar12_i_msb,7
    return
;
    movf solar12_u_lsb,W
    mulwf solar12_i_lsb
    movf PRODL,W
    addwf solar12_cp_0,F
    movf PRODH,W
    addwfc solar12_cp_1,F
;
    movf solar12_u_lsb,W
    mulwf solar12_i_msb
    movf PRODL,W
    addwf solar12_cp_1,F
    movf PRODH,W
    addwfc solar12_cp_2,F
;    
    movf solar12_u_msb,W
    mulwf solar12_i_lsb
    movf PRODL,W
    addwf solar12_cp_1,F
    movf PRODH,W
    addwfc solar12_cp_2,F
;
    movf solar12_u_msb,W
    mulwf solar12_i_msb
    movf PRODL,W
    addwf solar12_cp_2,F
    return            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateSolarPower12
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSolarPower12:
    movf solar12_cp_0,W
    addwf solar12_p0,F
;
    movf solar12_cp_1,W
    addwfc solar12_p1,F
;
    movf solar12_cp_2,W
    addwfc solar12_p2,F
;    
    movlw 0
    addwfc solar12_p3,F
;    
    movf solar12_cp_0,W
    addwf solar12_ps0,F
;
    movf solar12_cp_1,W
    addwfc solar12_ps1,F
;
    movf solar12_cp_2,W
    addwfc solar12_ps2,F
;    
    movlw 0
    addwfc solar12_ps3,F
	return
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SolarPowerCompare12
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SolarPowerCompare12:
    movf solar12_p3,W
    cpfseq solar12_pp3
    goto Solar12Power3Ne
	goto Solar12Power3Eq

Solar12Power3Ne:
    cpfsgt solar12_pp3
    goto Solar12NewLarger
    goto Solar12OldLarger

Solar12Power3Eq:
    movf solar12_p2,W
    cpfseq solar12_pp2
    goto Solar12Power2Ne
	goto Solar12Power2Eq

Solar12Power2Ne:
    cpfsgt solar12_pp2
    goto Solar12NewLarger
    goto Solar12OldLarger

Solar12Power2Eq:
    movf solar12_p1,W
    cpfseq solar12_pp1
    goto Solar12Power1Ne
    goto Solar12Power1Eq

Solar12Power1Ne:
    cpfsgt solar12_pp1
    goto Solar12NewLarger
    goto Solar12OldLarger

Solar12Power1Eq:
    movf solar12_p0,W
    cpfslt solar12_pp0
    goto Solar12OldLarger

Solar12NewLarger:
    bsf flags,FLAG_SOLAR12_POWER_INCREASE
    return

Solar12OldLarger:
    bcf flags,FLAG_SOLAR12_POWER_INCREASE
    return
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SolarControl12
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SolarControl12:
    btfsc flags,FLAG_SOLAR12_POWER_INCREASE
    goto Solar12ControlMorePower
;
    movf solar12_p0,W
    iorwf solar12_p1,W
    iorwf solar12_p2,W
    iorwf solar12_p3,W
    btfss STATUS,Z
    goto Solar12ControlLessPower

Solar12ControlNoPower:
    movf solar12_ref_lsb,W
    iorwf solar12_ref_msb,W
    btfsc STATUS,Z
    goto Solar12ControlIncrease
;
    movf solar12_u_lsb,W
    movwf solar12_ref_lsb
    movwf temp0
    movf solar12_u_msb,W
    movwf solar12_ref_msb
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
    addwfc solar12_ref_lsb,F
    movf temp1,W
    addwfc solar12_ref_msb,F    
    bcf flags,FLAG_SOLAR12_U_INCREASE
    return

Solar12ControlMorePower:
    btfss flags,FLAG_SOLAR12_U_INCREASE
    goto Solar12ControlDecrease

Solar12ControlIncrease:
	movlw 0x14
    addwf solar12_ref_lsb,F
    movlw 0
    addwfc solar12_ref_msb,F
    bsf flags,FLAG_SOLAR12_U_INCREASE
    return

Solar12ControlLessPower:
    btfss flags,FLAG_SOLAR12_U_INCREASE
    goto Solar12ControlIncrease
    
Solar12ControlDecrease:
	movlw 0xEC
    addwf solar12_ref_lsb,F
    movlw 0xFF
    addwfc solar12_ref_msb,F
    bcf flags,FLAG_SOLAR12_U_INCREASE
;
    btfss STATUS,C
    goto Solar12ControlZero
;
    return

Solar12ControlZero:
    clrf solar12_ref_lsb
    clrf solar12_ref_msb
    bcf flags,FLAG_SOLAR12_U_INCREASE
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetupSolar12
; solar_ref voltage reference
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSolar12:
    movf solar12_ref_lsb,W
    movwf temp0
    movwf solar12_low_lsb
    movwf solar12_high_lsb
;
    movf solar12_ref_msb,W
    movwf temp1
    movwf solar12_low_msb
    movwf solar12_high_msb
;
    movlw 4
    movwf temp2

ssRotateLoop12:
    bcf STATUS,C
    rrcf temp1,F
    rrcf temp0,F
    decfsz temp2,F
    goto ssRotateLoop12
;
    movlw 1
    addwf temp0,F
    movlw 0
    addwfc temp1,F
;    
    movf temp0,W
    addwf solar12_high_lsb,F
    movf temp1,W
    addwfc solar12_high_msb,F
;     
    comf temp0,F
    comf temp1,F
    movlw 1
    addwf temp0,F
    movlw 0
    addwfc temp1,F
;    
    movf temp0,W
    addwf solar12_low_lsb,F
    movf temp1,W
    addwfc solar12_low_msb,F
;
    movf solar12_p0,W
    movwf solar12_pp0
    movf solar12_p1,W
    movwf solar12_pp1
    movf solar12_p2,W
    movwf solar12_pp2
    movf solar12_p3,W
    movwf solar12_pp3
;
	clrf solar12_p0
    clrf solar12_p1
    clrf solar12_p2
    clrf solar12_p3
;
    movlw 0x80
    movwf solar12_yloop
;
    movlw 0x80
    movwf solar12_iloop        
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateSolarCharger12
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSolarCharger12:
    btfsc LATB,2
    goto UpdateSolar12ChargerOff

UpdateSolar12ChargerOn:
    btfsc solar12_u_msb,7
    goto UpdateSolar12ChargerTurnOff
;
    movf solar12_low_msb,W
    cpfseq solar12_u_msb
    goto UpdateSolar12ChargerOnNotEq
;
    movf solar12_low_lsb,W
    cpfslt solar12_u_lsb
    return
    goto UpdateSolar12ChargerTurnOff

UpdateSolar12ChargerOnNotEq:
    cpfslt solar12_u_msb
    return

UpdateSolar12ChargerTurnOff:
    bsf LATB,2
    return    
    
UpdateSolar12ChargerOff:
    btfsc solar12_u_msb,7
    return
;
    movf solar12_high_msb,W
    cpfseq solar12_u_msb
    goto UpdateSolar12ChargerOffNotEq
;
    movf solar12_high_lsb,W
    cpfsgt solar12_u_lsb
    return
    goto UpdateSolar12ChargerTurnOn

UpdateSolar12ChargerOffNotEq:
    cpfsgt solar12_u_msb
    return

UpdateSolar12ChargerTurnOn:
    bcf LATB,2
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PollSolar24
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PollSolar24:
    call UpdateSolarCharger24
    call CalcSolarPower24
    call UpdateSolarPower24
;
    decfsz solar24_iloop,F
    return
;
    movlw 0x80
    movwf solar24_iloop
;
    decfsz solar24_yloop,F
    return
;
    call SolarPowerCompare24
;    call SolarControl24
    call SetupSolar24
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CalcSolarPower24
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CalcSolarPower24:
    clrf solar24_cp_0
    clrf solar24_cp_1
    clrf solar24_cp_2
;   
    btfsc solar24_u_msb,7
    return
;
	btfsc solar24_i_msb,7
    return
;
    movf solar24_u_lsb,W
    mulwf solar24_i_lsb
    movf PRODL,W
    addwf solar24_cp_0,F
    movf PRODH,W
    addwfc solar24_cp_1,F
;
    movf solar24_u_lsb,W
    mulwf solar24_i_msb
    movf PRODL,W
    addwf solar24_cp_1,F
    movf PRODH,W
    addwfc solar24_cp_2,F
;    
    movf solar24_u_msb,W
    mulwf solar24_i_lsb
    movf PRODL,W
    addwf solar24_cp_1,F
    movf PRODH,W
    addwfc solar24_cp_2,F
;
    movf solar24_u_msb,W
    mulwf solar24_i_msb
    movf PRODL,W
    addwf solar24_cp_2,F
    return            

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateSolarPower24
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSolarPower24:
    movf solar24_cp_0,W
    addwf solar24_p0,F
;
    movf solar24_cp_1,W
    addwfc solar24_p1,F
;
    movf solar24_cp_2,W
    addwfc solar24_p2,F
;    
    movlw 0
    addwfc solar24_p3,F
;    
    movf solar24_cp_0,W
    addwf solar24_ps0,F
;
    movf solar24_cp_1,W
    addwfc solar24_ps1,F
;
    movf solar24_cp_2,W
    addwfc solar24_ps2,F
;    
    movlw 0
    addwfc solar24_ps3,F
	return
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SolarPowerCompare24
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SolarPowerCompare24:
    movf solar24_p3,W
    cpfseq solar24_pp3
    goto Solar24Power3Ne
	goto Solar24Power3Eq

Solar24Power3Ne:
    cpfsgt solar24_pp3
    goto Solar24NewLarger
    goto Solar24OldLarger

Solar24Power3Eq:
    movf solar24_p2,W
    cpfseq solar24_pp2
    goto Solar24Power2Ne
	goto Solar24Power2Eq

Solar24Power2Ne:
    cpfsgt solar24_pp2
    goto Solar24NewLarger
    goto Solar24OldLarger

Solar24Power2Eq:
    movf solar24_p1,W
    cpfseq solar24_pp1
    goto Solar24Power1Ne
    goto Solar24Power1Eq

Solar24Power1Ne:
    cpfsgt solar24_pp1
    goto Solar24NewLarger
    goto Solar24OldLarger

Solar24Power1Eq:
    movf solar24_p0,W
    cpfslt solar24_pp0
    goto Solar24OldLarger

Solar24NewLarger:
    bsf flags,FLAG_SOLAR24_POWER_INCREASE
    return

Solar24OldLarger:
    bcf flags,FLAG_SOLAR24_POWER_INCREASE
    return
         
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SolarControl24
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SolarControl24:
    btfsc flags,FLAG_SOLAR24_POWER_INCREASE
    goto Solar24ControlMorePower
;
    movf solar24_p0,W
    iorwf solar24_p1,W
    iorwf solar24_p2,W
    iorwf solar24_p3,W
    btfss STATUS,Z
    goto Solar24ControlLessPower

Solar24ControlNoPower:
    movf solar24_ref_lsb,W
    iorwf solar24_ref_msb,W
    btfsc STATUS,Z
    goto Solar24ControlIncrease
;
    movf solar24_u_lsb,W
    movwf solar24_ref_lsb
    movwf temp0
    movf solar24_u_msb,W
    movwf solar24_ref_msb
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
    addwfc solar24_ref_lsb,F
    movf temp1,W
    addwfc solar24_ref_msb,F    
    bcf flags,FLAG_SOLAR24_U_INCREASE
    return

Solar24ControlMorePower:
    btfss flags,FLAG_SOLAR24_U_INCREASE
    goto Solar24ControlDecrease

Solar24ControlIncrease:
	movlw 0x14
    addwf solar24_ref_lsb,F
    movlw 0
    addwfc solar24_ref_msb,F
    bsf flags,FLAG_SOLAR24_U_INCREASE
    return

Solar24ControlLessPower:
    btfss flags,FLAG_SOLAR24_U_INCREASE
    goto Solar24ControlIncrease
    
Solar24ControlDecrease:
	movlw 0xEC
    addwf solar24_ref_lsb,F
    movlw 0xFF
    addwfc solar24_ref_msb,F
    bcf flags,FLAG_SOLAR24_U_INCREASE
;
    btfss STATUS,C
    goto Solar24ControlZero
;
    return

Solar24ControlZero:
    clrf solar24_ref_lsb
    clrf solar24_ref_msb
    bcf flags,FLAG_SOLAR24_U_INCREASE
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetupSolar24
; solar_ref voltage reference
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupSolar24:
    movf solar24_ref_lsb,W
    movwf temp0
    movwf solar24_low_lsb
    movwf solar24_high_lsb
;
    movf solar24_ref_msb,W
    movwf temp1
    movwf solar24_low_msb
    movwf solar24_high_msb
;
    movlw 4
    movwf temp2

ssRotateLoop24:
    bcf STATUS,C
    rrcf temp1,F
    rrcf temp0,F
    decfsz temp2,F
    goto ssRotateLoop24
;
    movlw 1
    addwf temp0,F
    movlw 0
    addwfc temp1,F
;    
    movf temp0,W
    addwf solar24_high_lsb,F
    movf temp1,W
    addwfc solar24_high_msb,F
;     
    comf temp0,F
    comf temp1,F
    movlw 1
    addwf temp0,F
    movlw 0
    addwfc temp1,F
;    
    movf temp0,W
    addwf solar24_low_lsb,F
    movf temp1,W
    addwfc solar24_low_msb,F
;
    movf solar24_p0,W
    movwf solar24_pp0
    movf solar24_p1,W
    movwf solar24_pp1
    movf solar24_p2,W
    movwf solar24_pp2
    movf solar24_p3,W
    movwf solar24_pp3
;
	clrf solar24_p0
    clrf solar24_p1
    clrf solar24_p2
    clrf solar24_p3
;
    movlw 0x80
    movwf solar24_yloop
;
    movlw 0x80
    movwf solar24_iloop        
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UpdateSolarCharger24
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UpdateSolarCharger24:
    btfss LATB,1
    goto UpdateSolar24ChargerOff

UpdateSolar24ChargerOn:
    btfsc flags,FLAG_SOLAR24_CHARGE    
    goto UpdateSolar24ChargerTurnOff
;
    btfsc solar24_u_msb,7
    goto UpdateSolar24ChargerTurnOff
;
    movf solar24_low_msb,W
    cpfseq solar24_u_msb
    goto UpdateSolar24ChargerOnNotEq
;
    movf solar24_low_lsb,W
    cpfslt solar24_u_lsb
    return
    goto UpdateSolar24ChargerTurnOff

UpdateSolar24ChargerOnNotEq:
    cpfslt solar24_u_msb
    return

UpdateSolar24ChargerTurnOff:
    bcf LATB,1
    return
    
UpdateSolar24ChargerOff:
    btfsc flags,FLAG_SOLAR24_CHARGE    
    return
;
    btfsc solar24_u_msb,7
    return
;
    movf solar24_high_msb,W
    cpfseq solar24_u_msb
    goto UpdateSolar24ChargerOffNotEq
;
    movf solar24_high_lsb,W
    cpfsgt solar24_u_lsb
    return
    goto UpdateSolar24ChargerTurnOn

UpdateSolar24ChargerOffNotEq:
    cpfsgt solar24_u_msb
    return

UpdateSolar24ChargerTurnOn:
    bsf LATB,1
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
; ConvPower12
;    FSR0:  4 byte power
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvPower12:
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
  
    movlw w12_1
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw w12_0
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw '.'
    movwf INDF1
;
    incf FSR1L,F
    movlw mw12_2
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw mw12_1
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw mw12_0
    movwf TBLPTRL
    call Conv4One    
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ConvPower24
;    FSR0:  4 byte power
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvPower24:
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
    movlw w24_2
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw w24_1
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw w24_0
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw '.'
    movwf INDF1
;
    incf FSR1L,F
    movlw mw24_2
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw mw24_1
    movwf TBLPTRL
    call Conv4One
;
    incf FSR1L,F
    movlw mw24_0
    movwf TBLPTRL
    call Conv4One    
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ConvU12
;    FSR0:  2 byte voltage / current
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvU12:
    movf INDF0,W
    movwf val0
    incf FSR0L,F
;
    movf INDF0,W
    movwf val1
    incf FSR0L,F
;
    btfss val1,7
    goto ConvU12Pos

ConvU12Neg:     
    movlw '-'
    movwf INDF1
    incf FSR1L,F
;
    comf val0,F
    comf val1,F
    movlw 1
    addwf val0,F
    movlw 0
    addwfc val1,F
    goto ConvU12Do

ConvU12Pos:        
    movlw '+'
    movwf INDF1
    incf FSR1L,F

ConvU12Do:
    movlw u12_2
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw u12_1
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw u12_0
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw '.'
    movwf INDF1
;
    incf FSR1L,F
    movlw mu12_2
    movwf TBLPTRL
    call Conv2One
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ConvU24
;    FSR0:  2 byte voltage / current
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvU24:
    movf INDF0,W
    movwf val0
    incf FSR0L,F
;
    movf INDF0,W
    movwf val1
    incf FSR0L,F
;
    btfss val1,7
    goto ConvU24Pos

ConvU24Neg:     
    movlw '-'
    movwf INDF1
    incf FSR1L,F
;
    comf val0,F
    comf val1,F
    movlw 1
    addwf val0,F
    movlw 0
    addwfc val1,F
    goto ConvU24Do

ConvU24Pos:        
    movlw '+'
    movwf INDF1
    incf FSR1L,F

ConvU24Do:
    movlw u24_2
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw u24_1
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw u24_0
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw '.'
    movwf INDF1
;
    incf FSR1L,F
    movlw mu24_2
    movwf TBLPTRL
    call Conv2One
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ConvI24
;    FSR0:  2 byte current
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvI24:
    movf INDF0,W
    movwf val0
    incf FSR0L,F
;
    movf INDF0,W
    movwf val1
    incf FSR0L,F
;
    btfss val1,7
    goto ConvI24Pos

ConvI24Neg:     
    movlw '-'
    movwf INDF1
    incf FSR1L,F
;
    comf val0,F
    comf val1,F
    movlw 1
    addwf val0,F
    movlw 0
    addwfc val1,F
    goto ConvI24Do

ConvI24Pos:        
    movlw '+'
    movwf INDF1
    incf FSR1L,F

ConvI24Do:
    movlw i24_2
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw i24_1
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw i24_0
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw '.'
    movwf INDF1
;
    incf FSR1L,F
    movlw mi24_2
    movwf TBLPTRL
    call Conv2One
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ConvI12
;    FSR0:  2 byte current
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvI12:
    movf INDF0,W
    movwf val0
    incf FSR0L,F
;
    movf INDF0,W
    movwf val1
    incf FSR0L,F
;
    btfss val1,7
    goto ConvI12Pos

ConvI12Neg:     
    movlw '-'
    movwf INDF1
    incf FSR1L,F
;
    comf val0,F
    comf val1,F
    movlw 1
    addwf val0,F
    movlw 0
    addwfc val1,F
    goto ConvI12Do

ConvI12Pos:        
    movlw '+'
    movwf INDF1
    incf FSR1L,F

ConvI12Do:
    movlw i12_1
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw i12_0
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw '.'
    movwf INDF1
;
    incf FSR1L,F
    movlw mi12_2
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw mi12_1
    movwf TBLPTRL
    call Conv2One
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ConvRaw
;    FSR0:  2 byte voltage / current
;    FSR1:  Buffer in/out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ConvRaw:
    movf INDF0,W
    movwf val0
    incf FSR0L,F
;
    movf INDF0,W
    movwf val1
    incf FSR0L,F
;
    movlw h4
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw h3
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw h2
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw h1
    movwf TBLPTRL
    call Conv2One
;
    incf FSR1L,F
    movlw h0
    movwf TBLPTRL
    call Conv2One
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CreateStat
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CreateStat:
    lfsr 0,solar12_ps0
    lfsr 1,ser_buf
    call ConvPower12
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar24_ps0
    call ConvPower24
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar12_ref_lsb
    call ConvU12
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar24_ref_lsb
    call ConvU24
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar12_u_lsb
    call ConvU12
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar24_u_lsb
    call ConvU24
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,bat_u_lsb
    call ConvU24
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar12_i_lsb
    call ConvI12
;
    incf FSR1L,F
    movlw ' '
    movwf INDF1
    incf FSR1L,F
;
    lfsr 0,solar24_i_lsb
    call ConvI24
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
	clrf solar12_ps0
    clrf solar12_ps1
    clrf solar12_ps2
    clrf solar12_ps3
;
	clrf solar24_ps0
    clrf solar24_ps1
    clrf solar24_ps2
    clrf solar24_ps3
;
    lfsr 2,ser_buf
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WaitForSample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WaitForSample:
    movf INDF2,W
    btfsc STATUS,Z
    goto WaitForSampleLoop
;
    decfsz tx_count,F
    goto WaitForSampleLoop
;
    movlw 6
    movwf tx_count
;
    movf INDF2,W
    movwf TXREG
    incf FSR2L,F

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
    bcf LATC,0
    movwf ad_conf
;
    movlw 4
    movwf temp0
    goto sample_one_loop1

sample_one_set0:
    bcf LATC,2
    goto sample_one_clk0

sample_one_loop0:
    bsf LATC,1
    rlcf ad_conf,F

sample_one_a_bit0:
    btfsc STATUS,C
    goto sample_one_set1

sample_one_clk0:
    bcf LATC,1
    decfsz temp0,F
    bra sample_one_loop0
;
    goto sample_one_setup_ok

sample_one_set1:
    bsf LATC,2
    goto sample_one_clk1

sample_one_loop1:
    bsf LATC,1
    rlcf ad_conf,F

sample_one_bit1:
    btfss STATUS,C
    goto sample_one_set0

sample_one_clk1:
    bcf LATC,1
    decfsz temp0,F
    bra sample_one_loop1

sample_one_setup_ok:
    bsf LATC,1
    nop
;
    bcf LATC,1
    nop
;
    bsf LATC,1
    clrf ad_vall
    clrf ad_valh
    movlw 0xE
    movwf temp0
    bsf LATC,2
;
    bcf LATC,1

sample_one_loop:
    bcf STATUS,C
    rlcf ad_vall,F
    rlcf ad_valh,F
    bsf LATC,1
    nop
    nop
    btfsc PORTC,3
    bsf ad_vall,0
    bcf LATC,1
    decfsz temp0,F
    bra sample_one_loop
;
    movlw 0x1F
    andwf ad_valh,F
    movlw 0xE0
    btfsc ad_valh,4
    iorwf ad_valh,F
;    
    bsf LATC,0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sample
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Sample:
    movlw 0x10
    call SampleOne
;
    movf ad_vall,W
    movwf solar12_i_lsb
;
    movf ad_valh,W
    movwf solar12_i_msb
;    
    movlw 0x30
    call SampleOne
;
    movf ad_vall,W
    movwf solar12_u_lsb
;
    movf ad_valh,W
    movwf solar12_u_msb
;    
    movlw 0x50
    call SampleOne
;
    movf ad_vall,W
    movwf solar24_i_lsb
;
    movf ad_valh,W
    movwf solar24_i_msb
;    
    movlw 0xE0
    call SampleOne
;
    movf ad_vall,W
    movwf solar24_u_lsb
;
    movf ad_valh,W
    movwf solar24_u_msb
;    
    movlw 0xF0
    call SampleOne
;
    movf ad_vall,W
    movwf bat_u_lsb
;
    movf ad_valh,W
    movwf bat_u_msb
;
    movlw 0xB
    cpfseq bat_u_msb
    goto bat_check_msb

bat_check_lsb:
    movlw 0x40
    cpfsgt bat_u_lsb
    goto bat_charge_on
    goto bat_charge_off

bat_check_msb:
    cpfsgt bat_u_msb
    goto bat_charge_on

bat_charge_off:    
    bcf flags,FLAG_SOLAR24_CHARGE
    bcf LATB,0
    return

bat_charge_on:        
    bsf flags,FLAG_SOLAR24_CHARGE
    bsf LATB,0
    return
 
    end
