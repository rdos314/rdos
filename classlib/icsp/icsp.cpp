/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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
