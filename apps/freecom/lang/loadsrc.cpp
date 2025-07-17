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
# loadsrc.cpp
# Load a FreeCom .lng file
#
########################################################################*/

#include <ctype.h>
//#include <dir.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "loadsrc.h"

#define FALSE 0
#define TRUE !FALSE

#define SCANCODE(key)   (key | 256)
#define ASCIICODE(key)  (key)

#define KEY_F1  SCANCODE(59)
#define KEY_F2  SCANCODE(60)
#define KEY_F3  SCANCODE(61)
#define KEY_F4  SCANCODE(62)
#define KEY_F5  SCANCODE(63)
#define KEY_F6  SCANCODE(64)
#define KEY_F7  SCANCODE(65)
#define KEY_F8  SCANCODE(66)
#define KEY_F9  SCANCODE(67)
#define KEY_F10 SCANCODE(68)
#define KEY_F11 SCANCODE(133)
#define KEY_F12 SCANCODE(134)

#define KEY_LEFT        SCANCODE(75)
#define KEY_RIGHT       SCANCODE(77)
#define KEY_UP  SCANCODE(72)
#define KEY_DOWN        SCANCODE(80)
#define KEY_INS SCANCODE(82)
#define KEY_INSERT      SCANCODE(82)
#define KEY_DEL SCANCODE(83)
#define KEY_DELETE      SCANCODE(83)
#define KEY_HOME        SCANCODE(71)
#define KEY_END SCANCODE(79)
#define KEY_PUP SCANCODE(73)
#define KEY_PDOWN       SCANCODE(81)

#define KEY_TAB ASCIICODE('\t')
#define KEY_NL  ASCIICODE(0xFF)
#define KEY_CR  ASCIICODE(0xFE)
#define KEY_ENTER       ASCIICODE(0xFE)
#define KEY_BS  ASCIICODE('\b')
#define KEY_ESC ASCIICODE(27)

#define KEY_CTL_A       ASCIICODE(1)
#define KEY_CTL_B       ASCIICODE(2)
#define KEY_CTL_C       ASCIICODE(3)
#define KEY_CTL_D       ASCIICODE(4)
#define KEY_CTL_E       ASCIICODE(5)
#define KEY_CTL_F       ASCIICODE(6)
#define KEY_CTL_G       ASCIICODE(7)
#define KEY_CTL_H       ASCIICODE(8)
#define KEY_CTL_I       ASCIICODE(9)
#define KEY_CTL_J       ASCIICODE(10)
#define KEY_CTL_K       ASCIICODE(11)
#define KEY_CTL_L       ASCIICODE(12)
#define KEY_CTL_M       ASCIICODE(13)
#define KEY_CTL_N       ASCIICODE(14)
#define KEY_CTL_O       ASCIICODE(15)
#define KEY_CTL_P       ASCIICODE(16)
#define KEY_CTL_Q       ASCIICODE(17)
#define KEY_CTL_R       ASCIICODE(18)
#define KEY_CTL_S       ASCIICODE(19)
#define KEY_CTL_T       ASCIICODE(20)
#define KEY_CTL_U       ASCIICODE(21)
#define KEY_CTL_V       ASCIICODE(22)
#define KEY_CTL_W       ASCIICODE(23)
#define KEY_CTL_X       ASCIICODE(24)
#define KEY_CTL_Y       ASCIICODE(25)
#define KEY_CTL_Z       ASCIICODE(26)

const char id[]="FreeDOS STRINGS v";
        /* all prompts within *.LNG files start with */
const char promptID[] = "PROMPT_";
#define promptIDlen (sizeof(promptID) - 1)

struct symKey
{
        int keycode;
        char *keyname;
};

static const char besFromChar[] =
 "abcdefghijklmnopqrstuvwxyz,.[{}]\\?0";
static const char besToChar[] =
 "\a\b\c\d\e\f\g\h\i\j\k\l\m\n\o\p\q\r\s\t\u\v\w\x\y\z,.[{}]\\?";

symKey symkeys[] = {            /* symbolic keynames, uppercased! */
         { KEY_CTL_C,   "BREAK" }               /* Pseudo-^Break */
        ,{ KEY_CTL_C,   "CBREAK" }
        ,{ KEY_NL,      "LF" }
        ,{ KEY_NL,      "NL" }
        ,{ KEY_NL,      "LINEFEED" }
        ,{ KEY_NL,      "NEWLINE" }
        ,{ KEY_CR,      "CR" }
        ,{ KEY_CR,      "ENTER" }
        ,{ KEY_ESC,     "ESC" }
        ,{ KEY_ESC,     "ESCAPE" }
        ,{ ASCIICODE('\f'),     "FF" }
        ,{ ASCIICODE('\f'),     "FORMFEED" }
        ,{ ASCIICODE('\a'),     "ALARM" }
        ,{ ASCIICODE('\a'),     "BELL" }
        ,{ ASCIICODE('\a'),     "BEEP" }
        ,{ KEY_BS,      "BS" }
        ,{ KEY_BS,      "BACKSPACE" }
        ,{ KEY_TAB,     "HT" }
        ,{ KEY_TAB,     "TAB" }
        ,{ ASCIICODE('\v'),     "VT" }
        ,{ ASCIICODE('\0'),     "NUL" }
        ,{ ASCIICODE('\x1'),    "SOH" }
        ,{ ASCIICODE('\x2'),    "STX" }
        ,{ ASCIICODE('\x3'),    "ETX" }
        ,{ ASCIICODE('\x4'),    "EOT" }
        ,{ ASCIICODE('\x5'),    "ENQ" }
        ,{ ASCIICODE('\x6'),    "ACK" }
        ,{ ASCIICODE('\x7'),    "BEL" }
                /* 8 -> BS, 9 -> HT, A -> LF, B ->VT, C -> FF, D -> CR */
        ,{ ASCIICODE('\xe'),    "SO" }
        ,{ ASCIICODE('\xf'),    "SI" }
        ,{ ASCIICODE('\x10'),   "DLE" }
        ,{ ASCIICODE('\x11'),   "DC1" }
        ,{ ASCIICODE('\x12'),   "DC2" }
        ,{ ASCIICODE('\x13'),   "DC3" }
        ,{ ASCIICODE('\x14'),   "DC4" }
        ,{ ASCIICODE('\x15'),   "NAK" }
        ,{ ASCIICODE('\x16'),   "SYN" }
        ,{ ASCIICODE('\x17'),   "ETB" }
        ,{ ASCIICODE('\x18'),   "CAN" }
        ,{ ASCIICODE('\x19'),   "EM" }
        ,{ ASCIICODE('\x1a'),   "SUB" }
                /* 1b -> ESC */
        ,{ ASCIICODE('\x1c'),   "FS" }
        ,{ ASCIICODE('\x1d'),   "GS" }
        ,{ ASCIICODE('\x1e'),   "RS" }
        ,{ ASCIICODE('\x1f'),   "US" }

        ,{ KEY_F1, "F1" }
        ,{ KEY_F2, "F2" }
        ,{ KEY_F3, "F3" }
        ,{ KEY_F4, "F4" }
        ,{ KEY_F5, "F5" }
        ,{ KEY_F6, "F6" }
        ,{ KEY_F7, "F7" }
        ,{ KEY_F8, "F8" }
        ,{ KEY_F9, "F9" }
        ,{ KEY_F10, "F10" }
        ,{ KEY_F11, "F11" }
        ,{ KEY_F12, "F12" }

        ,{ KEY_LEFT, "LEFT" }
        ,{ KEY_RIGHT, "RIGHT" }
        ,{ KEY_UP, "UP" }
        ,{ KEY_DOWN, "DOWN" }
        ,{ KEY_INS, "INS" }
        ,{ KEY_DEL, "DEL" }
        ,{ KEY_HOME, "HOME" }
        ,{ KEY_END, "END" }
        ,{ KEY_PUP, "PUP" }
        ,{ KEY_PDOWN, "PDOWN" }

        ,{ 0, ""}
};

#define app(s)  appStr(text, (s))
#define appStr(vs,s) appMem((vs), (s), strlen((s)))
#define appMem(vs,s,l) appMem_(&(vs), (s), (l))
#define join(s1,s2)     strcpy(stpcpy(temp, s1), s2);

/*
 * Append the passed in string onto strg[cnt].text
 */
int appMem_(TDynString *vs, char *s, int length)
{
        vs->text = (char *)realloc(vs->text, 1 + vs->length + length);
        if (vs->text != 0)
        {
                char *p;

                p = vs->text + vs->length;
                if(length)
                        memcpy(p, s, length);
                p[length] = 0;
                vs->length += length;
                return 1;
        }

        fputs("Out of memory\n", stderr);
        return 0;
}

/*##########################################################################
#
#   Name       : fromxdigit
#
#   Purpose....: fromxdigit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static unsigned fromxdigit(int ch)
{
        if(isdigit(ch))
                return ch - '0';
        return toupper(ch) - 'A';
}

/*##########################################################################
#
#   Name       : mapBSEscape
#
#   Purpose....: map a backslash sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int mapBSEscape(char ** const s)
{
        char *p, *q;
        int ch;

        p = *s;
        if((ch = *p++) == 0)    /* Don't advance pointer */
                return 0;

        if(ch == 'x') { /* Hexadecimal */
                if(isxdigit(*p)) {
                        ch = fromxdigit(*p++);
                        if(isxdigit(*p))
                                ch = (ch << 4) | fromxdigit(*p++);
                } else
                        ch = 0;
        } else if((q = (char *)strchr(besFromChar, ch)) != 0) {
                ch = besToChar[(unsigned)(q - besFromChar)];
        } /* else  ch remains the character behind the backslash */

        *s = p;                 /* Advance pointer */
        return ch;
}

/*##########################################################################
#
#   Name       : mapSymKey
#
#   Purpose....: map a symbolic key
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static int mapSymKey(char * const p)
{       
        symKey *q;

        strupr(p);              /* Uppercase here to speed up process later */
        q = symkeys;
        do if(strcmp(q->keyname, p) == 0)       /* found */
                break;
        while((q++)->keycode);

        return q->keycode;
}

/*##########################################################################
#
#   Name       : TLang::TLang
#
#   Purpose....: Constructor for TLang
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLang::TLang()
{
        int i;

        for (i = 0; i < MAXSTRINGS; i++)
        {
                strg[i].flags = 0;
                strg[i].name = 0;
                strg[i].text = 0;
                strg[i].version = 0;
                strg[i].vstring = 0;

                string[i].index = 0;
                string[i].size = 0;
        }

        in_file = 0;
        cnt = 0;
    maxCnt = 0;
        error = 0;
        state = LOOKING_FOR_START;
}

/*##########################################################################
#
#   Name       : TLang::~TLang
#
#   Purpose....: Destructor for TLang
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLang::~TLang()
{
}

/*##########################################################################
#
#   Name       : TLang::pxerror
#
#   Purpose....: pxerror
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLang::pxerror(const char *msg1, const char *msg2)
{
        join(msg1, msg2);
        perror(temp);
}

/*##########################################################################
#
#   Name       : TLang::HandleStart
#
#   Purpose....: Handle start
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLang::HandleStart()
{
        char *vers;

        switch(*temp)
        {
                case ':': 
                        if((vers = strchr(temp + 1, '#')) != 0)
                                *vers = '\0';

                        /* Locate the string name */
                        for(cnt = 0; cnt < maxCnt; ++cnt)
                                if(strcmp(strg[cnt].name, temp + 1) == 0)
                                        goto strnameFound;

                        /* string name was not found --> create a new one */
                        ++maxCnt;
strnameFound:

                        if(!strg[cnt].name)
                        {
                                if((strg[cnt].name = strdup(temp + 1)) == 0)
                                {
                                        fputs("Out of memory\n", stderr);
                                        error = 80;
                                        return;
                                }
                        }
                        vstring.length = text.length = 0;
                        version = (vers && *++vers)? atoi(vers): 0;
                        if(vers && strchr(vers, '%'))
                                strg[cnt].flags |= PERFORM_VALIDATION;

                        if(memcmp(strg[cnt].name, promptID, promptIDlen) == 0)
                                state = GETTING_PROMPT_LINE_1;
                        else
                                state = GETTING_STRING;
                        break;

                default:
                        while(ldptr >= temp && isspace(*ldptr)) 
                                --ldptr;
                                                
                        if(ldptr >= temp)
                        {
                                fprintf(stderr, "Syntax error in line #%lu\n", linenr);
                                error = 44;
                                return;
                        }

                        /** fall through **/
                case '\0':
                case '#':
                        break;
        }
}

/*##########################################################################
#
#   Name       : TLang::HandlePrompt1
#
#   Purpose....: Handle prompt, part 1
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLang::HandlePrompt1(const char *fname)
{
        char *p, *q, len;
        int ch;

        if((*temp == '.' || *temp == ',') && (temp[1] == '\0'))
        {
                fprintf(stderr, "%s: %s: prompt syntax error\n"
                                , fname, strg[cnt].name);
                error = 41;
                return;
        }
        q = p = temp;
        while((ch = *p++) != 0)
                switch(ch)
                {
                        case '\\':
                                if(*p && (*q++ = mapBSEscape(&p)) == 0)
                                {
                                        fprintf(stderr
                                                         , "%s: %s: ASCII(0) is no valid key\n"
                                                         , fname, strg[cnt].name);
                                        error = 49;
                    return;
                                }
                                break;

                        case '{':
                                char *h;
                                int thisCh;

                                if((p = strchr(h = p, '}')) == 0)
                                {
                                        fprintf(stderr
                                                         , "%s: %s: invalid symbolic key\n"
                                                         , fname, strg[cnt].name);
                                        error = 46;
                                        return;
                                }

                                *p++ = 0;
                                if((thisCh = mapSymKey(h)) == 0)
                                {
                                        fprintf(stderr
                                                         , "%s: %s: unknown symbolic key\n"
                                                         , fname, strg[cnt].name);
                                        error = 47;
                                        return;
                                }

                                if(thisCh >= 256)
                                {
                                        fprintf(stderr
                                                         , "%s: %s: non-ASCII keys not supported, yet\n"
                                                         , fname, strg[cnt].name);
                                        error = 55;
                                        return;
                                }
                                *q++ = thisCh;
                                break;

                        case '[':
                                fprintf(stderr
                                                 , "%s: %s: brackets are not supported, yet\n"
                                                 , fname, strg[cnt].name);
                                error = 48;
                                return;

                        default:
                                *q++ = ch;
                                break;
                }
                                        
        *q = 0;
        if(q == temp)
        {
                fprintf(stderr
                                 , "%s: %s: empty key sequence\n"
                                 , fname, strg[cnt].name);
                error = 52;
                return;
        }

        if((unsigned)(q - temp) > 255)
        {
                fprintf(stderr
                                 , "%s: %s: too many keys\n"
                                 , fname, strg[cnt].name);
                 error = 55;
                 return;
        }

        len = (char)(q - temp);
        /* Prompts are PStrings in this form:
                LKKKKMMMM
                where number of K's == number of M's == L
                K -> key (1..255); M -> metakey (range 1..26);
                0 < L < 256
        */
        if(!appMem(text, &len, 1) || !app(temp))
        {
                error = 42;
                return;
        }

        state = GETTING_PROMPT_LINE_2;
}

/*##########################################################################
#
#   Name       : TLang::HandlePrompt2
#
#   Purpose....: Handle prompt, part 2
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLang::HandlePrompt2(const char *fname)
{
        char *p, *q;

        if ((*temp == '.' || *temp == ',') && (temp[1] == '\0'))
        {
                fprintf(stderr, "%s: %s: prompt syntax error\n"
                                 , fname, strg[cnt].name);
                error = 43;
        return;
        }

        p = q = temp;
        while((*q = *p++) != 0)
                if(*q >= 'a' && *q <= 'z') 
                {
                        *q++ -= 'a' - 1;        /* valid metakey */
                }
                else 
                        if(!isspace(*q))
                        {
                                fprintf(stderr, "%s: %s: invalid target metakey\n"
                                                 , fname, strg[cnt].name);
                                error = 44;
                                return;
                        }

        if((unsigned)(q - temp) + 1 != text.length)
        {
                fprintf(stderr
                                 , "%s: %s: number of metakeys does not match input keys\n"
                                 , fname, strg[cnt].name);
                error = 53;
                return;
        }

        if(!app(temp))
        {
                error = 54;
                return;
        }

        state = GETTING_STRING;
}

/*##########################################################################
#
#   Name       : TLang::HandleString
#
#   Purpose....: Handle string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLang::HandleString()
{
        if ((*temp == '.' || *temp == ',') && (temp[1] == '\0'))
        {
                if (*temp == ',' &&     text.length
                         && text.text[text.length - 1] == '\n')
                {
                        /* Cut the text as there is to always be a '\0' at the
                                end of the string */
                        text.text[--text.length] = '\0';
                }
                state = LOOKING_FOR_START;
                appMem(vstring, "", 0);         /* ensure vstring.text is != NULL */

                /* Apply the cached text */
                if((strg[cnt].flags & 3) == 0           /* New string */
                                || (strg[cnt].version == version
                                && ((strg[cnt].flags & PERFORM_VALIDATION) == 0
                                || strcmp(strg[cnt].vstring, vstring.text) == 0)))
                {
                        /* OK -> replace it */
                        strg[cnt].version = version;
                        free(strg[cnt].text);
                        strg[cnt].text = text.text;
                        string[cnt].size = text.length + 1;
                        free(strg[cnt].vstring);
                        strg[cnt].vstring = vstring.text;
                }
                else
                {
                        if(strg[cnt].version != version)
                                strg[cnt].flags |= VERSION_MISMATCH;

                        if(strcmp(strg[cnt].vstring, vstring.text) != 0)
                                strg[cnt].flags |= VALIDATION_MISMATCH;

                        /* Failed -> ignore the read text */
                        free(text.text);
                        free(vstring.text);
                }
                text.text = vstring.text = 0;
                strg[cnt].flags |= in_file;
        } 
        else
        {
                char *p, *q, ch;
                /* Fetch the '%' format sequences */
                q = temp - 1;
                while((p = strchr(q + 1, '%')) != 0)
                {
                        if((q = strpbrk(p, "%diouxXfegEGcsnp")) == 0)
                                q = strchr(p, '\0') - 1;

                        if(!appMem(vstring, p, (unsigned)(q - p) + 2))
                        {
                                error = 51;
                                return;
                        }
                }
                
                /* Replace backslash escape sequences */
                p = q = temp;
                while((ch = *p++) != 0)
                {
                        if(ch != '\\')
                                *q++ = ch;
                        else
                                if(!*p) 
                                        goto noAppendNL;
                                else
                                        *q++ = mapBSEscape(&p);
                }
                *q++ = '\n';

noAppendNL:
                if(!appMem(text, temp, (unsigned)(q - temp)))
                {
                        error = 82;
                        return;
                }
        }
}

/*##########################################################################
#
#   Name       : TLang::Load
#
#   Purpose....: Load file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TLang::Load(const char *fname)
{
        in_file++;

        text.text = vstring.text = 0;

        printf("Loading file %s\n", fname);

        join(fname, ".lng");
        if((fin = fopen(fname, "rt")) == NULL
                 && (fin = fopen(temp, "rt")) == NULL)
        {
                pxerror("opening ", fname);
                error = 33;
                return FALSE;
        }

        linenr = 0;
        while (fgets(temp, sizeof(temp), fin))
        {
                ++linenr;
                ldptr = strchr(temp, '\0');
                if(ldptr[-1] != '\n')
                {
                        fprintf(stderr, "Line %lu too long\n", linenr);
                        error = 41;
                        return FALSE;
                }
                        /* Cut trailing control characters */
                while (--ldptr >= temp && *ldptr < ' ')
                        ;

                ldptr[1] = '\0';

                switch (state)
                {
                        case LOOKING_FOR_START:
                                HandleStart();
                                if (error)
                                        return FALSE;
                                break;

                        case GETTING_PROMPT_LINE_1:
                                HandlePrompt1(fname);
                                if (error)
                                        return FALSE;
                                break;

                        case GETTING_PROMPT_LINE_2:
                                HandlePrompt2(fname);
                                if (error)
                                        return FALSE;
                                break;

                        case GETTING_STRING:
                                HandleString();
                                if (error)
                                        return FALSE;
                                break;
                }
        }

        if(ferror(fin))
        {
                pxerror("reading ", fname);
                error = 34;
                return FALSE;
        }

        fclose(fin);

        if(state != LOOKING_FOR_START)
        {
                fprintf(stderr, "%s: Last string not terminated\n", fname);
                error = 40;
                return FALSE;
        }

        return TRUE;
}

