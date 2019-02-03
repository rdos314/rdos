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

DESCR_FLAG_MORE    equ 0
USB_HANDLED        equ 1
DESCR_FLAG_FULL    equ 2

SET_ADDRESS        equ 5
GET_DESCRIPTOR     equ 6

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

d_curr_stat   equ 0x68
d_curr_count  equ 0x69
d_curr_low    equ 0x6A
d_curr_high   equ 0x6B

b_req_type    equ 0x6C
b_req         equ 0x6D
b_val_low     equ 0x6E
b_val_high    equ 0x6F
b_index_low   equ 0x70
b_index_high  equ 0x71
b_len_low     equ 0x72
b_len_high    equ 0x73

remain_size   equ 0x74
count         equ 0x75
usb_flags     equ 0x76
usb_stat      equ 0x77
usb_ep        equ 0x78
usb_adr       equ 0x79

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Interupt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Intr:
    movff STATUS, status_isr
    movff BSR, bsr_isr
    movlb 0
    movwf w_isr
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
    movf w_isr, W
    movff bsr_isr, BSR
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
;
    movlb 0
    clrf usb_flags
    clrf usb_adr
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
    movlw 0xFF
    movwf UIE
;
    movlw 0x16
    movwf UEP0
;
    movlb 0
    clrf usb_flags
    clrf usb_adr
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
    bsf usb_flags, DESCR_FLAG_MORE
    movwf temp
    movf b_len_high, W
    btfss STATUS, Z
    goto DecideWhole
;
    movf b_len_low, w
    cpfslt temp
    return

DecideWhole:
    movf temp, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DecideFragSize
;
; OUT: W used size
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DecideFragSize:
    movlw 8
    cpfslt remain_size
    return

DecideFragWhole:
    movf remain_size, W
    bcf usb_flags, DESCR_FLAG_MORE
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetDescr:
    movlb 0
    call DecideFragSize
    movwf temp
    movwf count
;
    movf count, W
    btfsc STATUS,Z
    goto gdSetup
;
    lfsr 0,usb_cin

gdLoop:
    tblrd *+
    movf TABLAT,W
    movwf POSTINC0
    decf remain_size, F
;
    decfsz temp,F
    goto gdLoop

gdSetup:
    movff count,control_in_size
;
    movlb usb_buf_page
    movlw 0x40
    xorwf control_in_stat,W
    andlw 0x40
    iorlw 0x88
    movwf control_in_stat
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SendEmpty
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SendEmpty:
    movlb usb_buf_page
    clrf control_in_size
    movlw 0xC8
    movwf control_in_stat
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetAddr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetAddr:
    btfsc b_req_type, 7
    return
;
    movf b_val_low, W
    movwf usb_adr
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetDeviceDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetDeviceDescr:
    call SetupDeviceDescr
    call DecideSize
    movwf remain_size
    call GetDescr
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetConfigDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetConfigDescr:
    call SetupConfigDescr
    call DecideSize
    movwf remain_size
    call GetDescr
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetStringDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetStringDescr:
    movlw 0
    cpfseq b_val_low
    goto NotGetString0
;
    call SetupString0
    goto HandleSendString

NotGetString0:
    movlw 1
    cpfseq b_val_low
    goto NotGetString1
;
    call SetupString1
    goto HandleSendString

NotGetString1:
    movlw 2
    cpfseq b_val_low
    goto NotGetString2
;
    call SetupString2
    goto HandleSendString

NotGetString2:
    return

HandleSendString:
    call DecideSize
    movwf remain_size
    call GetDescr
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleGetDescr
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleGetDescr:
    btfss b_req_type, 7
    return
;
    movlw 1
    cpfseq b_val_high
    goto NotGetDeviceDescr
;
    call HandleGetDeviceDescr
    return

NotGetDeviceDescr:
    movlw 2
    cpfseq b_val_high
    goto NotGetConfigDescr
;
    call HandleGetConfigDescr
    return

NotGetConfigDescr:
    movlw 3
    cpfseq b_val_high
    goto NotGetStringDescr
;
    call HandleGetStringDescr
    return

NotGetStringDescr:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlSetup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlSetup:
    btfsc b_req_type,6
    return
;
    btfsc b_req_type,5
    return
;
    movlw SET_ADDRESS
    cpfseq b_req
    goto NotSetAddr
;
    call HandleSetAddr
    return

NotSetAddr:
    movlw GET_DESCRIPTOR
    cpfseq b_req
    goto NotGetDescr
;
    call HandleGetDescr
    return

NotGetDescr:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlIn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlIn:
    btfss b_req_type, 7
    goto HandleControlToDevice

HandleControlFromDevice:
    bsf usb_flags, USB_HANDLED
;
    movlw GET_DESCRIPTOR
    cpfseq b_req
    goto NotGetDescrIn
;
    btfsc usb_flags, DESCR_FLAG_MORE
    call GetDescr

NotGetDescrIn:
    return

HandleControlToDevice:
    bsf usb_flags, USB_HANDLED
;
    movlw SET_ADDRESS
    cpfseq b_req
    goto NotSetAddrIn
;
    movf usb_adr, W
    movlb 0xF
    movwf UADDR
    movlb 0
    return

NotSetAddrIn:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlOut
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlOut:
    movlb usb_buf_page
    movlw 8
    movwf control_out_size
    movlw 0x88
    movwf control_out_stat
    movlb 0
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; RecControlComplete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RecControlComplete:
    btfss usb_stat, DIR
    goto RecControlOut

RecControlIn:
    call HandleControlIn
    return

RecControlOut:
    btfsc d_curr_stat,5
    goto RecControlSetup
;
    call HandleControlOut
    return

RecControlSetup:
    movff usb_cout, b_req_type
    movff usb_cout+1, b_req
    movff usb_cout+2, b_val_low
    movff usb_cout+3, b_val_high
    movff usb_cout+4, b_index_low
    movff usb_cout+5, b_index_high
    movff usb_cout+6, b_len_low
    movff usb_cout+7, b_len_high
;
    movlb usb_buf_page
    movlw 8
    movwf control_out_size
    movlw 0xC8
    movwf control_out_stat
    bcf UCON, PKTDIS
    bcf control_in_stat,6
;
    movlb 0
    call HandleControlSetup
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleUsbComplete
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleUsbComplete:
    movlb 0
    bcf usb_flags, USB_HANDLED
;
    movlw usb_buf_page
    movwf FSR0H
    movf USTAT, W
    movwf usb_stat
    andlw 0x7C
    movwf FSR0L
;
    movf POSTINC0, W
    movwf d_curr_stat
;
    movf POSTINC0, W
    movwf d_curr_count
;
    movf POSTINC0, W
    movwf d_curr_low
;
    movf POSTINC0, W
    movwf d_curr_high
;
    bcf UIR, TRNIF
;
    movf usb_stat, W
    andlw 0x38
    movwf usb_ep

retry:
    movlw 0
    cpfseq usb_ep
    goto HandleUsbNotControl
;
    call RecControlComplete
    goto HandleUsbCompleteDone

HandleUsbNotControl:

HandleUsbCompleteDone:
    movlb 0
    btfsc usb_flags, USB_HANDLED
    return
;
    goto retry
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
    lfsr 1,0x250
   
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
    db 0x12, 1     ; len + device descriptor
    db 0x10, 1     ; USB ver (full speed)
    db 0, 0        ; class + sub class
    db 0, 8        ; no device protocol + 8 byte packet size
    db 0x4D, 0x5   ; vendor id 
    db 1, 0x10     ; product id
    db 0, 1        ; version
    db 1, 2        ; manufacturer id + product id
    db 0, 1        ; no serial # + one configuration

ConfigDescr:
    db 0x9, 2      ; len + config descriptor

ConfigTotalSize:
    db ConfigEnd - ConfigDescr, 0   ; total size (must be less than 256 bytes)
    db 1, 1        ; number of interfaces + config value
    db 0, 0x80     ; config string id + bus powered
    db 0x32, 0x9   ; max 100mA + interface len
    db 4, 0        ; interface descriptor + interface #
    db 0, 0        ; alt setting + endpoint entries
    db 0xFF, 0     ; class + sub class
    db 0xFF, 0     ; vendor protocol + interface string id

Endpoint1:

ConfigEnd:

String0:
    db String1 - String0, 3
    db 0x9, 0xC

String1:
    db String2 - String1, 3
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
    db String3 - String2, 3
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
