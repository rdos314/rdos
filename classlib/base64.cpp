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
