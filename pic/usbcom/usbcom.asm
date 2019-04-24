#include p18f4550.inc   

  config PLLDIV=3,  CPUDIV = OSC2_PLL3, USBDIV = 2, FOSC = HSPLL_HS, FCMEN = OFF, IESO = OFF, PWRT = ON
  config BOR = ON, BORV = 3, VREGEN = OFF, WDT = OFF, WDTPS = 32768, CCP2MX = OFF, PBADEN = ON, LPT1OSC = ON
  config MCLRE = OFF, STVREN = ON
  config LVP = OFF, ICPRT = OFF,  XINST = OFF
  config CP0=OFF, CP1=OFF, CP2=OFF, CP3=OFF, CPB=OFF, CPD=OFF
  config WRT0=OFF, WRT1=OFF, WRT2=OFF, WRT3=OFF, WRTC=OFF, WRTB=OFF, WRTD=OFF
  config EBTR0=OFF, EBTR1=OFF, EBTR2=OFF, EBTR3=OFF, EBTRB=OFF

SER_COM_SIZE       equ 0x78
SER_USB_SIZE       equ 0x40

EP0                equ 0
EP1                equ 8

ser_ram            equ 0x100
ser_buf_page       equ 1

rx_count           equ 0x100
rx_in_pos          equ 0x101
rx_out_pos         equ 0x102

tx_count           equ 0x103
tx_in_pos          equ 0x104
tx_out_pos         equ 0x105

ser_curr_count     equ 0x106
ser_rem_count      equ 0x107
ser_temp           equ 0x108

rx_buf             equ 0x110
tx_buf             equ 0x188

usb_ram            equ 0x200

usb_buf_page       equ 4

control_out_stat   equ 0x400
control_out_size   equ 0x401
control_out_low    equ 0x402
control_out_high   equ 0x403

control_in_stat    equ 0x404
control_in_size    equ 0x405
control_in_low     equ 0x406
control_in_high    equ 0x407

ser_out_stat       equ 0x408
ser_out_size       equ 0x409
ser_out_low        equ 0x40A
ser_out_high       equ 0x40B

ser_in_stat        equ 0x40C
ser_in_size        equ 0x40D
ser_in_low         equ 0x40E
ser_in_high        equ 0x40F

bus_out_stat       equ 0x410
bus_out_size       equ 0x411
bus_out_low        equ 0x412
bus_out_high       equ 0x413

bus_in_stat        equ 0x414
bus_in_size        equ 0x415
bus_in_low         equ 0x416
bus_in_high        equ 0x417

usb_cout           equ 0x420
usb_cin            equ 0x428

usb_ser_out        equ 0x430
usb_ser_in         equ 0x470

usb_bus_out        equ 0x4B0
usb_bus_in         equ 0x4D0

SER_STATE_ACTIVE   equ 0
SER_STATE_ODD      equ 1
SER_STATE_EVEN     equ 2
SER_STATE_PAR9     equ 3
SER_STATE_IN_BUSY  equ 4
SER_STATE_OUT_BUSY equ 5

DESCR_FLAG_MORE    equ 0
USB_HANDLED        equ 1
DESCR_FLAG_FULL    equ 2

SET_ADDRESS        equ 5
GET_DESCRIPTOR     equ 6
SET_CONFIGURATION  equ 9

SET_BAUD           equ 1
SET_DATA_BITS      equ 2
SET_PARITY         equ 3
START_SERIAL       equ 4
STOP_SERIAL        equ 5

    org 0

    goto ProgStart

w_isr         equ 0x60
status_isr    equ 0x61
bsr_isr       equ 0x62

counter_ms   equ 0x63
counter_ds    equ 0x64

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

ser_state     equ 0x7A
ser_mask      equ 0x7C
parity        equ 0x7D
    
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
; InitSerial
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

InitSerial:
    movlb ser_buf_page
    clrf rx_count
    clrf rx_in_pos 
    clrf rx_out_pos
    clrf tx_count
    clrf tx_in_pos
    clrf tx_out_pos
    movlb 0
    clrf ser_state
    bsf ser_state, SER_STATE_PAR9
    movlw 0xFF
    movwf ser_mask
    clrf RCSTA
    clrf TXSTA
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
    movlw SER_USB_SIZE
    movwf ser_out_size
    movlw low usb_ser_out
    movwf ser_out_low
    movlw high usb_ser_out
    movwf ser_out_high
    movlw 0x88
    movwf ser_out_stat
;
    movlw SER_USB_SIZE
    movwf ser_in_size
    movlw low usb_ser_in
    movwf ser_in_low
    movlw high usb_ser_in
    movwf ser_in_high
    movlw 0x48
    movwf ser_in_stat
;
    movlw 0x20
    movwf bus_out_size
    movlw low usb_bus_out
    movwf bus_out_low
    movlw high usb_bus_out
    movwf bus_out_high
    movlw 0x88
    movwf bus_out_stat
;
    movlw 0x20
    movwf bus_in_size
    movlw low usb_bus_in
    movwf bus_in_low
    movlw high usb_bus_in
    movwf bus_in_high
    movlw 0x8
    movwf bus_in_stat
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
    movlw 0x1E
    movwf UEP1
;
    movlw 0x1E
    movwf UEP2
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
    bcf usb_flags, DESCR_FLAG_FULL
    movwf temp
    movf b_len_high, W
    btfss STATUS, Z
    goto DecideWhole
;
    movf b_len_low, w
    cpfseq temp
    goto DecideCompLow
    goto DecideFull

DecideCompLow:
    cpfslt temp
    goto DecideFull
    goto DecideWhole

DecideFull:
    bsf usb_flags, DESCR_FLAG_FULL
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
    btfss STATUS,Z
    goto gdCopy
;
    btfsc usb_flags, DESCR_FLAG_FULL
    return
;
    goto gdSetup

gdCopy:
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
; HandleSetConfig
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetConfig:
    btfsc b_req_type, 7
    return
;
    movlw 1
    cpfseq b_val_low
    return
;
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetBaud
;
;  Value = ser baud
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetBaud:
    btfsc b_req_type, 7
    return
;
    bsf BAUDCON, BRG16
    bsf TXSTA, BRGH
;
    movf b_val_low, W
    movwf SPBRG
;
    movf b_val_high, W
    movwf SPBRGH
;
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetDataBits
;
;  Value = ser data bits (7 or 8)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetDataBits:
    btfsc b_req_type, 7
    return
;
    movlw 7
    cpfseq b_val_low
    goto NotData7

Data7:
    movlw 0x7F
    movwf ser_mask
    bcf ser_state, SER_STATE_PAR9
    goto HandleBitsOk

NotData7:
    movlw 8
    cpfseq b_val_low
    return

Data8:
    movlw 0xFF
    movwf ser_mask
    bsf ser_state, SER_STATE_PAR9

HandleBitsOk:
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSetParity
;
;  Value = ser parity ('n', 'e', 'o')
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSetParity:
    btfsc b_req_type, 7
    return
;
    movlw 'n'
    cpfseq b_val_low
    goto NotLowerNone
    goto HandleParNone

NotLowerNone:
    movlw 'N'
    cpfseq b_val_low
    goto NotUpperNone

HandleParNone:
    bcf ser_state, SER_STATE_ODD
    bcf ser_state, SER_STATE_EVEN
    goto HandleParOk

NotUpperNone:
    movlw 'e'
    cpfseq b_val_low
    goto NotLowerEven
    goto HandleParEven

NotLowerEven:
    movlw 'E'
    cpfseq b_val_low
    goto NotUpperEven

HandleParEven:
    bcf ser_state, SER_STATE_ODD
    bsf ser_state, SER_STATE_EVEN
    goto HandleParOk

NotUpperEven:
    movlw 'o'
    cpfseq b_val_low
    goto NotLowerOdd
    goto HandleParOdd

NotLowerOdd:
    movlw 'O'
    cpfseq b_val_low
    return

HandleParOdd:
    bsf ser_state, SER_STATE_ODD
    bcf ser_state, SER_STATE_EVEN

HandleParOk:
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleStartSerial
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleStartSerial:
    btfsc b_req_type, 7
    return
;
    btfsc ser_state, SER_STATE_PAR9
    goto StartData8

StartData7:
    btfsc ser_state, SER_STATE_ODD
    goto Start8
;
    btfss ser_state, SER_STATE_EVEN
    return
    goto Start8

StartData8:
    btfsc ser_state, SER_STATE_ODD
    goto Start9
;
    btfsc ser_state, SER_STATE_EVEN
    goto Start9

Start8:
    bcf RCSTA, RX9
    bcf TXSTA, TX9
    goto StartSerial

Start9:
    bsf RCSTA, RX9
    bsf TXSTA, TX9

StartSerial:
    bsf RCSTA, SPEN
    bsf RCSTA, CREN
    bsf TXSTA, TXEN
    bsf ser_state, SER_STATE_ACTIVE
;
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleStopSerial
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleStopSerial:
    btfsc b_req_type, 7
    return
;
    call InitSerial
;
    call SendEmpty
    bsf usb_flags, USB_HANDLED
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlVendor
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlVendor:
    movlw SET_BAUD
    cpfseq b_req
    goto NotSetBaud
;
    call HandleSetBaud
    return

NotSetBaud:
    movlw SET_DATA_BITS
    cpfseq b_req
    goto NotSetDataBits
;
    call HandleSetDataBits
    return

NotSetDataBits:
    movlw SET_PARITY
    cpfseq b_req
    goto NotSetParity
;
    call HandleSetParity
    return

NotSetParity:
    movlw START_SERIAL
    cpfseq b_req
    goto NotStartSerial
;
    call HandleStartSerial
    return

NotStartSerial:
    movlw STOP_SERIAL
    cpfseq b_req
    goto NotStopSerial
;
    call HandleStopSerial
    return

NotStopSerial:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleControlSetup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleControlSetup:
    btfsc b_req_type,5
    return
;
    btfsc b_req_type,6
    goto HandleControlVendor
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
    movlw SET_CONFIGURATION
    cpfseq b_req
    goto NotSetConf
;
    call HandleSetConfig
    return

NotSetConf:
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
; BufferToUsb
;
; Move serial buffer to USB device
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BufferToUsb:
    movlb ser_buf_page
    movf rx_count, W
    btfsc STATUS, Z
    goto btuRet
;
    lfsr 0,rx_buf
    movf rx_in_pos, W
    addwf FSR0L, F
    lfsr 1,usb_ser_in
;
    movlw SER_USB_SIZE
    movwf ser_rem_count
    clrf ser_curr_count

btuLoop:
    movf POSTINC0, W
    movwf POSTINC1
;
    incf rx_in_pos, F
    movlw SER_COM_SIZE
    cpfseq rx_in_pos
    goto btuNext
;
    lfsr 0,rx_buf
    clrf rx_in_pos

btuNext:        
    incf ser_curr_count, F
;
    decfsz rx_count, F
    goto btuMore
    goto btuDone

btuMore:
    decfsz ser_rem_count, F
    goto btuLoop

btuDone:
    movf ser_curr_count, W
    movlb usb_buf_page
    movwf ser_in_size
;
    movlw 0x40
    xorwf ser_in_stat,W
    andlw 0x40
    iorlw 0x88
    movwf ser_in_stat
;
    movlb 0
    bsf ser_state, SER_STATE_IN_BUSY
    return

btuRet:
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; UsbToBuffer
;
; Move USB data to com buffer
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

UsbToBuffer:
    movlb ser_buf_page
    movf tx_count, W
    movwf ser_curr_count
;
    movlb usb_buf_page
    movf ser_out_size, W
    movlb ser_buf_page
    movwf ser_rem_count
    addwf ser_curr_count, F
;
    movlw SER_COM_SIZE
    cpfsgt ser_curr_count
    goto utbProcess
;
    movlb 0
    return

utbProcess:
    lfsr 0,usb_ser_out
    lfsr 1,tx_buf
    movf tx_out_pos, W
    addwf FSR1L, F

utbLoop:
    movf POSTINC0, W
    movwf POSTINC1
;
    incf tx_out_pos, F
    movlw SER_COM_SIZE
    cpfseq tx_out_pos
    goto utbNext
;
    lfsr 1,tx_buf
    clrf tx_out_pos

utbNext:        
    incf tx_count, F
    decfsz ser_rem_count, F
    goto utbLoop
;
    movlb usb_buf_page
    movlw SER_USB_SIZE
    movwf ser_out_size
;
    movlw 0x40
    xorwf ser_out_stat,W
    andlw 0x40
    iorlw 0x88
    movwf ser_out_stat
    movlb 0
    bcf ser_state, SER_STATE_OUT_BUSY
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerialIn
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSerialIn:
    bcf ser_state, SER_STATE_IN_BUSY
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerialOut
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSerialOut:
    bsf ser_state, SER_STATE_OUT_BUSY
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
;
    movlw EP0
    cpfseq usb_ep
    goto HandleUsbNotControl
;
    call RecControlComplete
;
    movlb 0
    btfsc usb_flags, USB_HANDLED
    return
;
    movlb usb_buf_page
    movlw 8
    movwf control_out_size
    movlw 0x84
    movwf control_out_stat
    movwf control_in_stat
    movlb 0
    return

HandleUsbNotControl:
    movlw EP1
    cpfseq usb_ep
    goto HandleUsbNotSerial
;
    btfss usb_stat, DIR
    goto HandleSerialOut
    goto HandleSerialIn

HandleUsbNotSerial:
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetSetBits
;
; Get number of set bits
;
; IN:  W value
; OUT: W set bits
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetSetBits:
    movwf temp
    clrf parity
;
    btfss ser_state, SER_STATE_PAR9
    goto GetBits8

GetBits9:
    btfsc temp,0
    incf parity, F
    btfsc temp,1
    incf parity, F
    btfsc temp,2
    incf parity, F
    btfsc temp,3
    incf parity, F
    btfsc temp,4
    incf parity, F
    btfsc temp,5
    incf parity, F
    btfsc temp,6
    incf parity, F
    btfsc temp,7
    incf parity, F
    movf parity, W
    return

GetBits8:
    btfsc temp,0
    incf parity, F
    btfsc temp,1
    incf parity, F
    btfsc temp,2
    incf parity, F
    btfsc temp,3
    incf parity, F
    btfsc temp,4
    incf parity, F
    btfsc temp,5
    incf parity, F
    btfsc temp,6
    incf parity, F
    movf parity, W
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GetRecParity
;
; Get received parity
;
; IN:  temp = RCREG
; OUT: W parity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GetRecParity:
    btfss ser_state, SER_STATE_PAR9
    goto GetRecPar8

GetRecPar9:
    movlw 0
    btfss RCSTA, RX9D
    return
;
    movlw 1
    return

GetRecPar8:
    movlw 0
    btfss temp, 7
    return
;
    movlw 1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SetSendParity
;
; Set send parity
;
; IN:  temp = RCREG
; IN:  W parity
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SetSendParity:
    btfss ser_state, SER_STATE_PAR9
    goto SetSendPar8

SetSendPar9:
    bcf TXSTA, TX9D
    btfsc parity, 0
    bsf TXSTA, TX9D
    return

SetSendPar8:
    btfsc parity, 0
    bsf temp, 7
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerReceive
;
; Handle serial receive
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSerReceive:
    movf RCREG, W
    movwf temp
;
    movlb ser_buf_page
    movlw SER_COM_SIZE
    cpfseq rx_count
    goto SerRecSpace
;
    movlb 0
    return

SerRecSpace:
    movlb 0
    btfsc ser_state, SER_STATE_ODD
    goto SerRecOdd
;
    btfss ser_state, SER_STATE_EVEN
    goto SerRecParOk

SerRecEven:
    movf temp, W
    call GetSetBits
    call GetRecParity
    xorwf parity, F
    btfsc parity, 0
    return
;
    goto SerRecParOk

SerRecOdd:
    movf temp, W
    call GetSetBits
    call GetRecParity
    xorwf parity, F
    btfss parity, 0
    return

SerRecParOk:
    movlb 0
    movf temp, W
    andwf ser_mask, W
    movwf temp
;
    movlb ser_buf_page
    lfsr 0,rx_buf
    movf rx_out_pos, W
    addwf FSR0L, F
;
    movlb 0
    movf temp, W
    movwf INDF0
;
    movlb ser_buf_page
    incf rx_out_pos, F
    movlw SER_COM_SIZE
    cpfseq rx_out_pos
    goto SerRecOutOk
;
    clrf rx_out_pos

SerRecOutOk:
    incf rx_count, F
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSerSend
;
; Handle serial send
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSerSend:
    movlb ser_buf_page
    movf tx_count, W
    btfsc STATUS, Z
    return
;
    bsf LATC,1
;
    lfsr 0,tx_buf
    movf tx_in_pos, W
    addwf FSR0L, F
    movf INDF0, W
;
    movlb 0
    andwf ser_mask, W
    movwf temp
    btfsc ser_state, SER_STATE_ODD
    goto SendOdd
;
    btfss ser_state, SER_STATE_EVEN
    goto SerSendParOk

SendEven:
    movf temp, W
    call GetSetBits
    call SetSendParity
    goto SerSendParOk

SendOdd:
    movf temp, W
    call GetSetBits
    movlw 1
    xorwf parity,F 
    call SetSendParity

SerSendParOk:
    movf temp, W
    movwf TXREG
;
    movlb ser_buf_page
    incf tx_in_pos, F
    movlw SER_COM_SIZE
    cpfseq tx_in_pos
    goto hssNext
;
    clrf tx_in_pos

hssNext:
    decf tx_count, F
    movlb 0
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HandleSendIdle
;
; Handle serial send idle
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HandleSendIdle:
    movlb ser_buf_page
    movf tx_count, W
    btfss STATUS, Z
    return
;
    bcf LATC,1
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Program start
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ProgStart:
    movlw 0x64
    movwf counter_ms
;
    movlw 0xA
    movwf counter_ds
;
    movlw 0xFF
    movwf TRISA
;
    movlw 0xF
    movwf LATB
;
    movlw 0xF0
    movwf TRISB
;
    movlw 0x42
    movwf LATC
;
    movlw 0xBD
    movwf TRISC
;
    movlw 0xF
    movwf LATD
;
    movlw 0xF0
    movwf TRISD
;
    movlw 0x3
    movwf LATE
;
    movlw 0xFC
    movwf TRISE
;
    movlw 0
    movwf BSR
;
    movlw 0x26
    movwf T2CON
;
    movlw 0x64
    movwf PR2
;
    bcf PIR1,TMR2IF
;
    movlw 0
    movwf temp
;
    call InitUsb
    call InitSerial
    
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
    btfss ser_state, SER_STATE_ACTIVE
    goto SerDone
;
    btfss ser_state, SER_STATE_IN_BUSY
    call BufferToUsb
;
    btfsc ser_state, SER_STATE_OUT_BUSY
    call UsbToBuffer
;
    btfsc PIR1, RCIF
    call HandleSerReceive
;
    btfsc PIR1, TXIF
    call HandleSerSend
;
    btfsc TXSTA,TRMT
    call HandleSendIdle

SerDone:
    btfss PIR1,TMR2IF
    bra Loop
;
    bcf PIR1,TMR2IF
;
    decfsz counter_ms,F
    bra Loop
;
    movlw 0x64
    movwf counter_ms
;
    decfsz counter_ds,F
    bra Loop
;
    movlw 0xA
    movwf counter_ds
;
    btg LATB,1
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
    db 0x31, 0x9   ; max 100mA + interface len
    db 4, 0        ; interface descriptor + interface #
    db 0, 4        ; alt setting + endpoint entries
    db 0xFF, 0     ; class + sub class
    db 0xFF, 0     ; vendor protocol + interface string id

Endpoint1:
    db 7, 5        ; size + endpoint 1 OUT
    db 0x1, 0x2    ; OUT endpoint 1 + bulk
    db 0x40, 0     ; max packet size (64 bytes)
    db 0, 7        ; max NAKs, endpoint 1 IN 
    db 5, 0x81     ; IN endpoint 1
    db 0x2, 0x40   ; bulk + max packet size low
    db 0, 0        ; max packet size high + max NAKs

Endpoint2:
    db 7, 5        ; size + endpoint 2 OUT
    db 0x2, 0x2    ; OUT endpoint 2 + bulk
    db 0x20, 0     ; max packet size (64 bytes)
    db 0, 7        ; max NAKs, endpoint 2 IN 
    db 5, 0x82     ; IN endpoint 2
    db 0x2, 0x20   ; bulk + max packet size low
    db 0, 0        ; max packet size high + max NAKs

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
