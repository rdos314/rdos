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

#include <memory.h>
#include "rdos.h"

static char Base64[] = {
                        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
                        'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
                        'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
                        'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
                        'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
                        'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
                        '8', '9', '+', '/'
                       };


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

    memcpy(&val, inp, 3);
    val = RdosSwapLong(val);
    val = val >> 8;

    for (i = 3; i >= 0; i--)
    {
        ch = (char)val & 0x3F;
        outp[i] = Base64[ch];
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
