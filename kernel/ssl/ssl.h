/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# serv.h
# RDOS server level interface
#
########################################################################*/

#ifndef _RDOS_SSL_SERV_H
#define _RDOS_SSL_SERV_H

#pragma pack( __push, 1 )

#define RDOSAPI

#include <stdarg.h>
#include "rdssl.h"

#pragma pack( __pop )


// API functions

#ifdef __cplusplus
extern "C" {
#endif

void RDOSAPI ServCreateSslConnection(int index, long IP, int LocalPort, int RemotePort, int BufferSize);
void RDOSAPI ServDeleteSslConnection(int index);

void RDOSAPI ServCreateSslListen(int index, int Port, int BufferSize);
void RDOSAPI ServDeleteSslListen(int index);
void RDOSAPI ServAddSslListen(int index, int entry);

void RDOSAPI ServSslStart(int index, int handle);
void RDOSAPI ServSslStop(int index, int handle);

void  RDOSAPI ServSslInitStart(int index);
void  RDOSAPI ServSslInitDone(int index);
int  RDOSAPI ServSslGetReceiveSpace(int index);
void RDOSAPI ServSslAddReceiveBuf(int index, const char *buf, int size);
int RDOSAPI ServSslGetSendCount(int index);
int RDOSAPI ServSslGetSendBuf(int index, char *buf);
void RDOSAPI ServSslClearSendCount(int index, int count);
int RDOSAPI ServSslWaitForChange(int consel);

#ifdef __cplusplus
}
#endif

#ifdef __WATCOMC__
#include "owssl.h"
#endif

#endif
