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
# cmdhelp.cpp
# Command help base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : IsEmpty
#
#   Purpose....: Return true if string is 0 or contains only spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsEmpty(const char *s)
{
        if (s)
        {
                while(*s)
                {
                        s++;
                        if (!isspace(*s))
                                return FALSE;
                }
        }
        return TRUE;
}

/*##########################################################################
#
#   Name       : IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsArgDelim(char ch)
{
        return isspace(ch) || iscntrl(ch) || strchr(",;=", ch);
}

/*##########################################################################
#
#   Name       : IsOptDelim
#
#   Purpose....: Check for option delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsOptDelim(char ch)
{
        return isspace(ch) || iscntrl(ch);
}

/*##########################################################################
#
#   Name       : IsOptChar
#
#   Purpose....: Is option char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsOptChar(char ch)
{
        return ch == '/';
}


/*##########################################################################
#
#   Name       : IsFileNameChar
#
#   Purpose....: Is filename char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsFileNameChar(char c)
{
    return !(c <= ' ' || c == 0x7f || strchr(".\"/\\[]:|<>+=;,", c));
}

/*##########################################################################
#
#   Name       : LTrimsp
#
#   Purpose....: Trim of leading spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *LTrimsp(const char *str)
{
        while (*str && isspace(*str))
            str++;
        return str;
}

/*##########################################################################
#
#   Name       : LTrim
#
#   Purpose....: Remove leading "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *LTrim(const char *str)
{
        while (*str)
        {
                if (IsArgDelim(*str))
                        str++;
                else
                        break;
        }
        return str;
}

/*##########################################################################
#
#   Name       : RTrim
#
#   Purpose....: Remove trailing "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void RTrim(char *str)
{ 
        char *p;

        p = strchr(str, 0);
        p--;

        while (p >= str && IsArgDelim(*p))
                p--;

        p[1] = 0;
}

/*##########################################################################
#
#   Name       : Unquote
#
#   Purpose....: Unquote to new string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *Unquote(const char *str, const char *end)
{
        char *h, *newStr;
        const char *q;
        int len;

        newStr = new char[end - str + 1];
        h = newStr;

        while ((q = strpbrk(str, "\"")) != 0 && q < end)
        {
                memcpy(h, str, len = q++ - str);
                h += len;
                if ((str = strchr(q, q[-1])) == 0 || str >= end)
                {
                        str = q;
                        break;
                }

                memcpy(h, q, len = str++ - q);
                h += len;
        }

        memcpy(h, str, len = end - str);
        h[len] = 0;
        return newStr;
}

/*##########################################################################
#
#   Name       : MatchToken
#
#   Purpose....: Match token at begining of line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int MatchToken(char **Xp, const char *word, int len)
{       
    char *p;
    char *q;

    p = *Xp;
        if (strnicmp(p, word, len) == 0)
        {
                p += len;
                if (*p)
                {
                        q = (char *)LTrim(p);
                        if (q == p)
                                return FALSE;
                        p = q;
                }
                *Xp = p;
                return TRUE;
        }

        return FALSE;
}
