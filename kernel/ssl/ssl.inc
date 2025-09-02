;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RDOS operating system
; Copyright (C) 1988-2025, Leif Ekblad
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;
; The author of this program may be contacted at leif@rdos.net
;
; SERV.INC
; Server gate macros
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



ServGate    MACRO gate_nr
    db 55h
    db 67h
    db 9Ah
    dd gate_nr
    dw 4
    db 5Dh
            ENDM

;;;;;;;;;; REGISTRATION / HOOKS ;;;;;;;;;;;

;;;;;;;;; SSL ;;;;;;;;;;;;;;;;;;

; IN  EBX              SSL handle
; OUT EDX              Cmd
WaitForSslCmd  MACRO
    ServGate wait_for_ssl_cmd_nr
                    ENDM

; IN  EBX              SSL handle
ReplySslCmd  MACRO    
    ServGate reply_ssl_cmd_nr
                    ENDM

; IN  EBX              VFS handle
ReplySslDataCmd  MACRO    
    ServGate reply_ssl_data_cmd_nr
                    ENDM

; IN  EBX              Connection index
; IN  EDX              IP
; IN  SI               Local port
; IN  DI               Remote port
; IN  ECX              Buffer size
CreateSslConnection  MACRO    
    ServGate create_ssl_conn_nr
                    ENDM

; IN  EBX              Connection index
DeleteSslConnection  MACRO    
    ServGate delete_ssl_conn_nr
                    ENDM

; IN  EBX              Connection index
; IN  EAX              Socket handler
StartSsl               MACRO
    ServGate ssl_start_nr
                        ENDM

; IN  EBX              Connection index
; IN  EAX              Socket handler
SslStop               MACRO
    ServGate ssl_stop_nr
                        ENDM

; IN  EBX              Listen index
; IN  SI               Local port
; IN  ECX              Buffer size
CreateSslListen  MACRO    
    ServGate create_ssl_listen_nr
                    ENDM

; IN  EBX              Listen index
DeleteSslListen  MACRO    
    ServGate delete_ssl_listen_nr
                    ENDM

; IN  EBX              Listen index
; IN  EAX              Connection entry
AddSslListen  MACRO    
    ServGate add_ssl_listen_nr
                    ENDM
