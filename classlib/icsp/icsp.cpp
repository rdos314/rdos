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
# icsp.cpp
# In-circuit programming base class
#
########################################################################*/

#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h> 

#include "rdos.h"
#include "icsp.h"

#define FALSE   0
#define TRUE    !FALSE

typedef struct
{
    char           *_dest;
    short           _flags;         // flags (see below)
    short           _version;       // structure version # (2.0 --> 200)
    int             _fld_width;     // field width
    int             _prec;          // precision
    int             _output_count;  // # of characters outputted for %n
    int             _n0;            // number of chars to deliver first
    int             _nz0;           // number of zeros to deliver next
    int             _n1;            // number of chars to deliver next
    int             _nz1;           // number of zeros to deliver next
    int             _n2;            // number of chars to deliver next
    int             _nz2;           // number of zeros to deliver next
    char            _character;     // format character
    char            _pad_char;
    char            _padding[2];    // to keep struct aligned
} _SPECS;

typedef void (slib_callback_t)(_SPECS *, int);

extern "C" int 
            __prtf( void  *dest,         /* parm for use by out_putc */
            const char *format,          /* pointer to format string */
            va_list args,                /* pointer to pointer to args*/
            slib_callback_t *out_putc ); /* char output routine */


/*##########################################################################
#
#   Name       : TIcsp::TIcsp
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIcsp::TIcsp()
{
    FFile = 0;
    FHandle = 0;
}

/*##########################################################################
#
#   Name       : TIcsp::~TIcsp
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIcsp::~TIcsp()
{
}

/*##########################################################################
#
#   Name       : string_putc
#
#   Purpose....: __prtf callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void string_putc( _SPECS *specs, int op_char )
{
    *( specs->_dest++ ) = op_char;
    specs->_output_count++;
}

/*##########################################################################
#
#   Name       : TIcsp::Info
#
#   Purpose....: Info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TIcsp::Info(const char *format, ...)
{
    va_list ap;
    int len;

    va_start(ap, format);

    if (OnInfo)
    {
        len = __prtf(FLogBuf, format, ap, string_putc );
        FLogBuf[len] = 0;
        (*OnInfo)(this, FLogBuf);
    }
}

/*##########################################################################
#
#   Name       : TIcsp::Program
#
#   Purpose....: Program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp::Program(const char *filename, int devid)
{
    int ok = FALSE;
    
        FFile = new TFile(filename);

        if (FFile->IsOpen())
        {
            FHandle = RdosOpenICSP(devid);

                if (FHandle)
                {
                        ok = DoProgram();
                        RdosCloseICSP(FHandle);                 
                }
                else
                        Info("Invalid device-id or no ICSP available\r\n");
        }
        else
                Info("File not found\r\n");

    delete FFile;
    FFile = 0;

        return ok;
}

/*##########################################################################
#
#   Name       : TIcsp::ChipErase
#
#   Purpose....: ChipErase
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp::ChipErase(int devid)
{
    int ok = FALSE;
    
    FHandle = RdosOpenICSP(devid);

    if (FHandle)
    {
        ok = DoChipErase();
        RdosCloseICSP(FHandle);                 
    }
    else
        Info("Invalid device-id or no ICSP available\r\n");

    return ok;
}

/*##########################################################################
#
#   Name       : TIcsp::Verify
#
#   Purpose....: Verify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp::Verify(const char *filename, int devid)
{
    int ok = FALSE;
    
    FFile = new TFile(filename);

    if (FFile->IsOpen())
    {
        FHandle = RdosOpenICSP(devid);

        if (FHandle)
        {
            ok = DoVerify();
            RdosCloseICSP(FHandle);                 
        }
    }

    delete FFile;
    FFile = 0;

    return ok;
}

/*##########################################################################
#
#   Name       : TIcsp::DoVerify
#
#   Purpose....: Do ICSP verify
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIcsp::DoVerify()
{
    return TRUE;
}
