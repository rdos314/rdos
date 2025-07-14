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
; devmsg.inc
; SSL msg definitions
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; OUT EBX       Session ID
SSL_OPEN_SESSION               = 0

; IN  EBX       Session ID
SSL_CLOSE_SESSION              = 1

; IN  EAX       Timeout in milliseconds for connection
; IN  EBX       Session ID
; IN  ECX       buffer size
; IN  EDX       ip address
; IN  ESI       local port (0 for dynamic port)
; IN  EDI       remote port
; OUT EBX       Connection ID
SSL_OPEN_CONNECTION            = 2

; IN  EBX       Connection ID
SSL_CLOSE_CONNECTION           = 3

; IN  EBX       Connection ID
SSL_PUSH_CONNECTION            = 4

; IN  EAX       Port
; IN  EDX       Max connections
; IN  ECX       Buffer size
; OUT EBX       Server ID
SSL_OPEN_SERVER                = 5

; IN  EBX       Server ID
SSL_CLOSE_SERVER               = 6

; IN  EBX       Server ID
; IN  EAX       Entry #
; OUT EBX       Connection ID
SSL_ACCEPT_SERVER              = 7

; IN  EBX       Server ID
; IN  ESI       Key file offset
; IN  EDX       Chain file offset
; IN            Cert pathname
SSL_SERVER_CERT                = 8

; IN  EBX       Connection ID
; OUT           Certificate JSON
SSL_GET_CONNECTION_CERT        = 9

; IN            Filename
; OUT           Certificate JSON
SSL_GET_CERT_JSON              = 10
