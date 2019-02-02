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

b_req_type    equ 0x68
b_req         equ 0x69
b_val_low     equ 0x6A
b_val_high    equ 0x6B
b_index_low   equ 0x6C
b_index_high  equ 0x6D
b_len_low     equ 0x6E
b_len_high    equ 0x6F

setup_len     equ 0x70
descr_low     equ 0x71
descr_high    equ 0x72
descr_size    equ 0x73
count         equ 0x74

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
    clrf UIE
    clrf UIR
;
    movlw 0x14
    movwf UCFG
;
    movlw 8
    movwf UCON
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleUsbError
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleUsbError:
    movlb 0xF
    clrf UEIR
    bcf UIR, UERRIF
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleUsbReset
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleUsbReset:
    movlb 0xF
    bcf UIR, TRNIF
    bcf UIR, TRNIF
    bcf UIR, TRNIF
    bcf UIR, TRNIF
;
    clrf UEP0
    clrf UEP1
    clrf UEP2
    clrf UEP3
    clrf UEP4
    clrf UEP5
    clrf UEP6
    clrf UEP7
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
    clrf UIR
;
    movlw 0x16
    movwf UEP0
;
    movlb 0xF
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupDeviceDescr
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupDeviceDescr:
    movlw low DeviceDescr
    movwf TBLPTRL
    movlw high DeviceDescr
    movwf TBLPTRH
    movlw upper DeviceDescr
    movwf TBLPTRU
    tblrd *
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupConfigDescr
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupConfigDescr:
    movlw low ConfigTotalSize
    movwf TBLPTRL
    movlw high ConfigTotalSize
    movwf TBLPTRH
    movlw upper ConfigTotalSize
    movwf TBLPTRU
    tblrd *
;
    movlw low ConfigDescr
    movwf TBLPTRL
    movlw high ConfigDescr
    movwf TBLPTRH
    movlw upper ConfigDescr
    movwf TBLPTRU
;
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupString0
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupString0:
    movlw low String0
    movwf TBLPTRL
    movlw high String0
    movwf TBLPTRH
    movlw upper String0
    movwf TBLPTRU
    tblrd *
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupString1
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupString1:
    movlw low String1
    movwf TBLPTRL
    movlw high String1
    movwf TBLPTRH
    movlw upper String1
    movwf TBLPTRU
    tblrd *
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetupString2
;
; OUT: W size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetupString2:
    movlw low String2
    movwf TBLPTRL
    movlw high String2
    movwf TBLPTRH
    movlw upper String2
    movwf TBLPTRU
    tblrd *
    movf TABLAT, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DecideSize
;
; IN:  W object size
; OUT: W used size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecideSize:
    movlb 0
    movwf temp
    movf b_len_high, W
    btfss STATUS, Z
    goto DecideWhole
;
    movf b_len_low, w
    cpfsgt temp
    return

DecideWhole:
    movf temp, W
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
    movlw 6
    cpfseq b_req
    goto NotGetDescr
;
    movlw 1
    cpfseq b_val_low
    goto NotGetDeviceDescr
    goto HandleGetDeviceDescr

NotGetDeviceDescr:
    return

NotGetDescr:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DecodeUsabSetup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecodeUsbSetup:
    movff usb_cout, b_req_type
    movff usb_cout+1, b_req
    movff usb_cout+2, b_val_low
    movff usb_cout+3, b_val_high
    movff usb_cout+4, b_index_low
    movff usb_cout+5, b_index_high
    movff usb_cout+6, b_len_low
    movff usb_cout+7, b_len_high
;
    movlb 0
    btfss b_req_type, 7
    goto DecodeHostSetup

DecodeDeviceSetup:
    movlw 0x80
    cpfseq b_req_type
    goto DecodeNotGetDescr
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
    movlb 0xF
    btfsc UIR, UERRIF
    call HandleUsbError
;
    btfsc UIR, SOFIF
    bcf UIR, SOFIF
;
    btfsc UIR, IDLEIF
    bcf UIR, IDLEIF
;
    btfsc UIR, ACTVIF
    bcf UIR, ACTVIF
;
    btfsc UIR, STALLIF
    bcf UIR, STALLIF
;
    btfsc UIR, URSTIF
    call HandleUsbReset
;
    btfsc UIR, TRNIF
    call HandleUsbComplete
;
    movlb 0
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
    db 0x12        ; len
    db 1           ; device descriptor
    db 0x10, 1     ; USB ver (full speed)
    db 0           ; class
    db 0           ; sub class
    db 0           ; no device protocol
    db 8           ; 8 byte packet size for control endpoint
    db 0x4D, 0x5   ; vendor id 
    db 1, 0x10     ; product id
    db 0, 1        ; version
    db 1           ; manufacturer id
    db 2           ; product id
    db 0           ; no serial #
    db 1           ; one configuration

ConfigDescr:
    db 0x9         ; len
    db 2           ; config descriptor

ConfigTotalSize:
    db ConfigEnd - ConfigDescr, 0   ; total size (must be less than 256 bytes)
    db 1           ; number of interfaces
    db 1           ; configuration value
    db 0           ; config string id
    db 0x80        ; bus powered
    db 0x32        ; max 100mA 

Interface:
    db 0x9         ; len
    db 4           ; interface descriptor
    db 0           ; interface #
    db 0           ; alt setting
    db 0           ; endpoint entries
    db 0xFF        ; class
    db 0           ; subclass
    db 0xFF        ; vendor protocol
    db 0           ; interface string id

Endpoint1:

ConfigEnd:

String0:
    db String1 - String0
    db 3
    db 0x9, 0xC

String1:
    db String2 - String1
    db 3
    db 'R', 0
    db 'D', 0
    db 'O', 0
    db 'S', 0
    db ' ', 0
    db 'D', 0
    db 'e', 0
    db 'v', 0
    db 'e', 0
    db 'l', 0
    db 'o', 0
    db 'p', 0
    db 'm', 0
    db 'e', 0
    db 'n', 0
    db 't', 0
    db '.', 0
String2:
    db String3 - String2
    db 3
    db 'S', 0
    db 'e', 0
    db 'r', 0
    db 'i', 0
    db 'a', 0
    db 'l', 0
    db ' ', 0
    db 'b', 0
    db 'u', 0
    db 's', 0
String3:

    end
