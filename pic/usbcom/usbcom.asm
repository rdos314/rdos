#include p18f14k50.inc   

 config CPUDIV=NOCLKDIV, USBDIV=OFF, FOSC=HS, PLLEN=ON, PCLKEN=ON, FCMEN=OFF, IESO=OFF, PWRTEN=OFF
 config BOREN=SBORDIS, BORV=19, WDTEN=OFF, WDTPS=32768, HFOFST=ON, MCLRE=ON, STVREN=ON, LVP=OFF, BBSIZ=OFF, XINST=OFF
 config CP0=OFF, CP1=OFF, CPB=OFF, CPD=OFF, WRT0=OFF, WRT1=OFF, WRTC=OFF, WRTB=OFF, WRTD=OFF, EBTR0=OFF, EBTR1=OFF, EBTRB=OFF

usb_ram   equ 0x200
usb_cout  equ 0x240
usb_cin   equ 0x248

    org 0

    goto ProgStart

    org 0x8

    goto Intr

    org 0x18

    goto Intr

w_isr         equ 0x60
status_isr    equ 0x61
bsr_isr       equ 0x62

counter_low   equ 0x63
counter_ov    equ 0x64

counter_mid   equ 0x65
counter_high  equ 0x66

temp          equ 0x67

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Interupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Intr:	
    movwf w_isr
    movff STATUS, status_isr
    movff BSR, bsr_isr
;
    movlw 0
    movwf BSR
;
    btfss PIR1,TMR2IF
    bra NotTmr2
;
    bcf PIR1,TMR2IF
    decf counter_low,f
    bnz NotTmr2
;
    incf counter_ov,f
    movlw 0x64
    movwf counter_low

NotTmr2:
    movff bsr_isr, BSR
    movf w_isr, W
    movff status_isr, STATUS
    retfie
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code starts here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; position dependent code ends here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TestTblr:
    movlw low ConfigDescr
    movwf TBLPTRL
    movlw high ConfigDescr
    movwf TBLPTRH
    movlw upper ConfigDescr
    movwf TBLPTRU
    tblrd *+
    movf TABLAT,W
    return

InitUsb:
    movlw 0xF
    movwf BSR
    movlw 0x17
    movwf UCFG
    lfsr 0, usb_ram
    movlw 0x88
    movwf POSTINC0
    movlw 8
    movwf POSTINC0
    movlw low usb_cout
    movwf POSTINC0
    movlw high usb_cout
    movwf POSTINC0
;
    movlw 0x88
    movwf POSTINC0
    movlw 8
    movwf POSTINC0
    movlw low usb_cin
    movwf POSTINC0
    movlw high usb_cin
    movwf POSTINC0
;
    movlw 0x16
    movwf UEP0
;
    movlw 0x48
    movwf UCON
;
    movlw 0
    movwf BSR
    return

ProgStart:
    clrf counter_ov
    movlw 0x64
    movwf counter_low
    movwf counter_mid
    movwf counter_high
;
    movlw 0xF0
    movwf TRISC
    movlw 0
    movwf PORTC
    movlw 0
    movwf BSR
    movlw 0xD
    movwf T2CON
    movlw 0x96
    movwf PR2
    bsf PIE1,TMR2IE
    bcf PIR1,TMR2IF
    movlw 0xC0
    movwf INTCON
    movlw 0
    movwf temp
;
    call InitUsb
    
Loop:
    movf counter_ov,W
    bz Loop
;
    decf counter_ov,f
;
    decf counter_mid,f
    bnz Loop
;
    movlw 0x64
    movwf counter_mid
;


    btg temp,0
    movf temp,W
    movwf PORTC


    decf counter_high,f
    bnz Loop
;
    movlw 0x64
    movwf counter_high
;
    goto Loop

ConfigDescr:
    db 0x55

    end
