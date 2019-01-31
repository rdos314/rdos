#include p18f14k50.inc   

 config CPUDIV=NOCLKDIV, USBDIV=OFF, FOSC=HS, PLLEN=ON, PCLKEN=ON, FCMEN=OFF, IESO=OFF, PWRTEN=OFF
 config BOREN=SBORDIS, BORV=19, WDTEN=OFF, WDTPS=32768, HFOFST=ON, MCLRE=ON, STVREN=ON, LVP=OFF, BBSIZ=OFF, XINST=OFF
 config CP0=OFF, CP1=OFF, CPB=OFF, CPD=OFF, WRT0=OFF, WRT1=OFF, WRTC=OFF, WRTB=OFF, WRTD=OFF, EBTR0=OFF, EBTR1=OFF, EBTRB=OFF

usb_ram            equ 0x200

usb_buf_page       equ 2

control_out_stat   equ 0x200
control_out_size   equ 0x201
control_out_low    equ 0x202
control_out_high   equ 0x203

control_in_stat    equ 0x204
control_in_size    equ 0x205
control_in_low     equ 0x206
control_in_high    equ 0x207

usb_cout           equ 0x240
usb_cin            equ 0x248


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

setup_len     equ 0x68
descr_low     equ 0x69
descr_high    equ 0x6A
descr_size    equ 0x6B
count         equ 0x6C

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; InitUsb
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitUsb:
    movlb 0xF
    movlw 0x14
    movwf UCFG
;
    movlw 8
    movwf UCON
;
    bcf UIR, TRNF
    bcf UIR, TRNF
    bcf UIR, TRNF
    bcf UIR, TRNF
;
    clrf UEP0
    clrf UEP1
    clrf UEP2
    clrf UEP3
    clrf UEP4
    clrf UEP5
    clrf UEP6
    clrf UEP7
    clrf UEP8
    clrf UEP9
    clrf UEP10
    clrf UEP11
    clrf UEP12
    clrf UEP13
    clrf UEP14
    clrf UEP15
;
    movlb usb_buf_page
    movlw 8
    movwf control_out_size
    movlw low usb_cout
    movwf control_out_low
    movlw high usb_cout
    movwf control_out_high
    movlw 0x88
    movwf control_out_stat
;
    movlw 8
    movwf control_in_size
    movlw low usb_cin
    movwf control_in_low
    movlw high usb_cin
    movwf control_in_high
    movlw 0x8
    movwf control_in_stat
;
    movlb 0xF
    clrf UADDR
;
    movlw 0x16
    movwf UEP0
;
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; CopyDescr
;
; W  bytes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CopyDescr:
    movwf temp

cdLoop:
    tblrd *+
    movf TABLAT,W
    movwf POSTINC0
;
    incf count,F
;
    decfsz setup_len,F
    bra cdNext
    bra cdDone

cdNext:
    decfsz temp,F
    bra cdLoop

cdDone:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDescr:
    tblrd *+
    movf TABLAT,W
    movwf descr_size
;
    lfsr 0,usb_cin
    movwf POSTINC0
    decf descr_size
;
    movlw 1
    movwf count
    decf setup_len,F
;
    movlw 7
    call CopyDescr
;
    movff TBLPTRL, descr_low
    movff TBLPTRH, descr_high
;
    movlb usb_buf_page
    movff count,control_in_size
;
    movlw 0x40
    xorwf control_in_stat,W
    andlw 0x40
    iorlw 0x88
    movwf control_in_stat
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetDeviceDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetDeviceDescr:
    movlw low DeviceDescr
    movwf TBLPTRL
    movlw high DeviceDescr
    movwf TBLPTRH
    movlw upper DeviceDescr
    movwf TBLPTRU
    goto GetDescr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetDescr:
    movf POSTINC0, W
    movlw 6
    cpfseq POSTINC0
    return
;
    movf POSTINC0, W
    decfsz INDF0,F
    bra NotGetDeviceDescr
;
    goto HandleGetDeviceDescr

NotGetDeviceDescr:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DecodeUsabSetup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeUsbSetup:
    lfsr 0, usb_cout+6
    movff INDF0, setup_len
;
    lfsr 0, usb_cout
    btfss INDF0, 7
    bra DecodeHostSetup

DecodeDeviceSetup:
    movlw 0x80
    cpfseq INDF0
    bra DecodeNotGetDescr
    goto HandleGetDescr
    
DecodeNotGetDescr: 
    return

DecodeHostSetup:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlComplete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlComplete:
    btfss USTAT, DIR
    goto HandleControlOut

HandleControlIn:
    lfsr 0, usb_ram+4
    goto HandleUsbCompleteDone

HandleControlOut:
    lfsr 0, usb_ram
    btfsc INDF0,5
    goto HandleControlSetup
    goto HandleUsbCompleteDone

HandleControlSetup:
    call DecodeUsbSetup
    lfsr 0, usb_ram
    bsf INDF0, 7
    goto HandleUsbCompleteDone

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleUsbComplete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleUsbComplete:
    movf USTAT, W
    andlw 0x38
    bz HandleControlComplete

HandleUsbCompleteDone:
    bcf UIR, TRNIF
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Program start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    btfsc UIR, TRNIF
    call HandleUsbComplete
;
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

DeviceDescr:
    db 0x12   ; len
    db 1      ; device descriptor
    db 0
    db 1      ; full speed
    db 0xFF   ; vendor class
    db 0      ; sub class
    db 0      ; no device protocol
    db 8      ; max 8 byte packet size for control endpoint
    db 0x56 
    db 0x65   ; vendor id
    db 0xAA
    db 0xAA   ; product id
    db 0
    db 1      ; device version
    db 0      ; no manufacturer id
    db 0      ; no product id
    db 0      ; no serial #
    db 1      ; one configuration

ConfigDescr:
    db 0x55

    end
