/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2018, Leif Ekblad
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
# base64.cpp
# base64 support
#
########################################################################*/

#include <ctype.h>
#include <memory.h>
#include "rdos.h"

static const char base64_chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

/*##########################################################################
#
#   Name       : IsBase64
#
#   Purpose....: Check for base64 char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int IsBase64(char c)
{
    return (isalnum(c) || (c == '+') || (c == '/'));
}

/*##########################################################################
#
#   Name       : FindBase64
#
#   Purpose....: Find base64 char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int FindBase64(char c)
{
    int k;

    for (k = 0; k < 64; k++)
        if (base64_chars[k] == c)
            return k;

    return 0;
}

/*##########################################################################
#
#   Name       : DecodeBase64
#
#   Purpose....: Decode base64
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int DecodeBase64(const char *instr, char *outstr)
{
    int in_len = strlen(instr);
    int i = 0;
    int j = 0;
    int in_ = 0;
    int out_ = 0;
    char char_array_4[4];
    char char_array_3[3];

    while (in_len-- && ( instr[in_] != '=') && IsBase64(instr[in_]))
    {
        char_array_4[i++] = instr[in_];
        in_++;

        if (i == 4)
        {
            for (i = 0; i < 4; i++)
                char_array_4[i] = FindBase64(char_array_4[i]);

            char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
            char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
            char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

            for (i = 0; (i < 3); i++)
            {
                outstr[out_] = char_array_3[i];
                out_++;
            }
            
            i = 0;
        }
    }

    if (i)
    {
        for (j = i; j < 4; j++)
            char_array_4[j] = 0;

        for (j = 0; j < 4; j++)
            char_array_4[j] = FindBase64(char_array_4[j]);

        char_array_3[0] = (char_array_4[0] << 2) + ((char_array_4[1] & 0x30) >> 4);
        char_array_3[1] = ((char_array_4[1] & 0xf) << 4) + ((char_array_4[2] & 0x3c) >> 2);
        char_array_3[2] = ((char_array_4[2] & 0x3) << 6) + char_array_4[3];

        for (j = 0; (j < i - 1); j++)
        {
            outstr[out_] = (char_array_3[j]);
            out_++;
        }
    }
    outstr[out_] = 0;

    return out_;
}

/*##########################################################################
#
#   Name       : CodeOneBase64
#
#   Purpose....: Code data as Base-64
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void CodeOneBase64(const char *inp, char *outp, int size)
{
    int val;
    char ch;
    int i;
    char cp[3];

    if (size != 3)
    {
        memcpy(cp, inp, 3);

        switch (size)
        {
            case 1:
                cp[1] = 0;

            case 2:
                cp[2] = 0;
        }
        memcpy(&val, cp, 3);
    }
    else
        memcpy(&val, inp, 3);

    val = RdosSwapLong(val);
    val = val >> 8;

    for (i = 3; i >= 0; i--)
    {
        ch = (char)val & 0x3F;
        outp[i] = base64_chars[ch];
        val = val >> 6;
    }

    switch (size)
    {
        case 1:
            outp[2] = '=';

        case 2:
            outp[3] = '=';
    }
}

/*##########################################################################
#
#   Name       : CodeBase64
#
#   Purpose....: Code data as Base-64
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CodeBase64(const char *inp, char *outp, int size)
{
    while (size > 0)
    {
        CodeOneBase64(inp, outp, size);
        inp += 3;
        outp += 4;
        size -= 3;
    }
    *outp = 0;
}
