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
# json.cpp
# json class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdarg.h>
#include <math.h>

#include "json.h"
#include "rdos.h"

#define json_tokener_success				1
#define json_tokener_continue				2
#define json_tokener_error_depth			3
#define json_tokener_error_parse_eof			4
#define json_tokener_error_parse_unexpected		5
#define json_tokener_error_parse_null			6
#define json_tokener_error_parse_boolean		7
#define json_tokener_error_parse_number			8
#define json_tokener_error_parse_array			9
#define json_tokener_error_parse_object_key_name	10
#define json_tokener_error_parse_object_key_sep		11
#define json_tokener_error_parse_object_value_sep	12
#define json_tokener_error_parse_string			13
#define json_tokener_error_parse_comment		14
#define json_tokener_error_size				15

#define json_tokener_state_eatws			1
#define json_tokener_state_start			2
#define json_tokener_state_finish			3
#define json_tokener_state_null				4
#define json_tokener_state_comment_start		5
#define json_tokener_state_comment			6
#define json_tokener_state_comment_eol			7
#define json_tokener_state_comment_end			8
#define json_tokener_state_string			9
#define json_tokener_state_string_escape		10
#define json_tokener_state_true	        		11
#define json_tokener_state_false			12
#define json_tokener_state_number			13
#define json_tokener_state_array			14
#define json_tokener_state_array_add			15
#define json_tokener_state_array_sep			16
#define json_tokener_state_object_field_start		17
#define json_tokener_state_object_field			18
#define json_tokener_state_object_field_end		19
#define json_tokener_state_object_value			20
#define json_tokener_state_object_value_add		21
#define json_tokener_state_object_sep			22
#define json_tokener_state_array_after_sep		23
#define json_tokener_state_object_field_start_after_sep	24
#define json_tokener_state_inf				25

#define json_ret_out                                    1
#define json_ret_redo                                   2
#define json_ret_break                                  3
#define json_ret_add                                    4
#define json_ret_sub                                    5

/*##########################################################################
#
#   Name       : PrintfCallback
#
#   Purpose....: Printf callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void PrintfCallback(void *param, char ch)
{
    TJsonPrintBuf *buf = (TJsonPrintBuf *)param;
    buf->MemAppend(&ch, 1);
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::TJsonPrintBuf
#
#   Purpose....: Constructor for TJsonPrintBuf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonPrintBuf::TJsonPrintBuf()
{
    FSize = 32;
    FBpos = 0;
    FBuf = new char[FSize];
    FBuf[0] = 0;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::~TJsonPrintBuf
#
#   Purpose....: Destructor for TJsonPrintBuf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonPrintBuf::~TJsonPrintBuf()
{
    delete FBuf;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::Reset
#
#   Purpose....: Reset object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonPrintBuf::Reset()
{
    FBpos = 0;
    FBuf[0] = 0;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::Extend
#
#   Purpose....: Extend buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonPrintBuf::Extend(int min_size)
{
    char *t;
    int new_size;

    if (FSize < min_size)
    {
        new_size = FSize * 2;
        if (new_size < min_size + 8)
            new_size =  min_size + 8;

        t = new char[new_size];
        memcpy(t, FBuf, FSize);
        delete FBuf;

        FSize = new_size;
        FBuf = t;
    }
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::MemAppend
#
#   Purpose....: Append
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonPrintBuf::MemAppend(const char *buf, int size)
{
    if (FSize <= FBpos + size + 1) 
        Extend(FBpos + size + 1);

    memcpy(FBuf + FBpos, buf, size);
    FBpos += size;
    FBuf[FBpos]= 0;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::MemSet
#
#   Purpose....: Set
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonPrintBuf::Memset(int offset, int charvalue, int len)
{
    int size_needed;

    if (offset == -1)
        offset = FBpos;

    size_needed = offset + len;

    if (FSize < size_needed)
        Extend(size_needed);

    memset(FBuf + offset, charvalue, len);
    if (FBpos < size_needed)
        FBpos = size_needed;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::printf
#
#   Purpose....: printf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonPrintBuf::printf(const char *fmt, va_list args)
{
    int n;

    n = RdosPrintf(&PrintfCallback, this, fmt, args);
        
    return n;
}

/*##########################################################################
#
#   Name       : TJsonPrintBuf::printf
#
#   Purpose....: printf
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonPrintBuf::printf(const char *fmt, ...)
{
    va_list args;
    int result;

    va_start(args, fmt);
    result = RdosPrintf(&PrintfCallback, this, fmt, args);
    va_end(args);

    return result;
}

/*##########################################################################
#
#   Name       : TJsonObject::TJsonObject
#
#   Purpose....: Constructor for TJsonObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject::TJsonObject()
{
}

/*##########################################################################
#
#   Name       : TJsonObject::~TJsonObject
#
#   Purpose....: Destructor for TJsonObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject::~TJsonObject()
{
}

/*##########################################################################
#
#   Name       : TJsonArray::TJsonArray
#
#   Purpose....: Constructor for TJsonArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArray::TJsonArray()
{
}

/*##########################################################################
#
#   Name       : TJsonArray::~TJsonArray
#
#   Purpose....: Destructor for TJsonArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArray::~TJsonArray()
{
}

/*##########################################################################
#
#   Name       : TJsonInt::TJsonInt
#
#   Purpose....: Constructor for TJsonInt
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonInt::TJsonInt(long long v)
{
    Val = v;
}

/*##########################################################################
#
#   Name       : TJsonInt::~TJsonInt
#
#   Purpose....: Destructor for TJsonInt
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonInt::~TJsonInt()
{
}

/*##########################################################################
#
#   Name       : TJsonDouble::TJsonDouble
#
#   Purpose....: Constructor for TJsonDouble
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDouble::TJsonDouble(double v)
{
    Val = v;
}

/*##########################################################################
#
#   Name       : TJsonDouble::~TJsonDouble
#
#   Purpose....: Destructor for TJsonDouble
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDouble::~TJsonDouble()
{
}

/*##########################################################################
#
#   Name       : TJsonBoolean::TJsonBoolean
#
#   Purpose....: Constructor for TJsonBoolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBoolean::TJsonBoolean(bool v)
{
    Val = v;
}

/*##########################################################################
#
#   Name       : TJsonBoolean::~TJsonBoolean
#
#   Purpose....: Destructor for TJsonBoolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBoolean::~TJsonBoolean()
{
}

/*##########################################################################
#
#   Name       : TJsonString::TJsonString
#
#   Purpose....: Constructor for TJsonString
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonString::TJsonString(const char *str, int size)
{
    Val = new char[size + 1];
    memcpy(Val, str, size);
    Val[size] = 0;
}

/*##########################################################################
#
#   Name       : TJsonString::~TJsonString
#
#   Purpose....: Destructor for TJsonString
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonString::~TJsonString()
{
    delete Val;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::TJsonStackEntry
#
#   Purpose....: Constructor for TJsonStackEntry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStackEntry::TJsonStackEntry()
{
    pb = new TJsonPrintBuf;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::~TJsonStackEntry
#
#   Purpose....: Destructor for TJsonStackEntry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStackEntry::~TJsonStackEntry()
{
    if (pb)
        delete pb;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::PeekChar
#
#   Purpose....: Peek next char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonStackEntry::PeekChar()
{
    if (*str)
        return true;
    else
        return false;
}
 
/*##########################################################################
#
#   Name       : TJsonStackEntry::AdvanceChar
#
#   Purpose....: Advance to next char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonStackEntry::AdvanceChar()
{
    if (*str)
    {
        str++;
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleEatWs
#
#   Purpose....: Handle eat ws state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleEatWs(TJsonDocument *doc)
{
    while (isspace(*str)) 
    {
	if (!AdvanceChar() || !PeekChar())
	    return json_ret_out;
    }

    if (*str == '/') 
    {
        pb->Reset();
	pb->MemAppend(str, 1);
	state = json_tokener_state_comment_start;
    } 
    else 
    {
        state = saved_state;
        return json_ret_redo;
    }
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleStart
#
#   Purpose....: Handle start state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleStart(TJsonDocument *doc)
{
    switch (*str) 
    {
        case '{':
            if (!doc->IsArrayData())
                doc->StartNesting();

	    state = json_tokener_state_eatws;
	    saved_state = json_tokener_state_object_field_start;
            return json_ret_break;

        case '[':
            is_array = true;
            state = json_tokener_state_eatws;
            saved_state = json_tokener_state_array;
            return json_ret_break;

        case 'I':
        case 'i':
            state = json_tokener_state_inf;
            pb->Reset();
	    doc->st_pos = 0;
            return json_ret_redo;

        case 'N':
        case 'n':
	    state = json_tokener_state_null; // or NaN
            pb->Reset();
	    doc->st_pos = 0;
	    return json_ret_redo;

        case '\'':
        case '"':
	    state = json_tokener_state_string;
	    pb->Reset();
	    doc->quote_char = *str;
            return json_ret_break;

        case 'T':
        case 't':
	    state = json_tokener_state_true;
	    pb->Reset();
	    doc->st_pos = 0;
	    return json_ret_redo;

        case 'F':
        case 'f':
	    state = json_tokener_state_false;
	    pb->Reset();
	    doc->st_pos = 0;
	    return json_ret_redo;

        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case '-':
	    state = json_tokener_state_number;
	    pb->Reset();
            doc->is_double = 0;
	    return json_ret_redo;

        default:
	    doc->err = json_tokener_error_parse_unexpected;
	    return json_ret_out;
    }
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleFinish
#
#   Purpose....: Handle finish state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleFinish(TJsonDocument *doc)
{
    return json_ret_sub;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleInfinite
#
#   Purpose....: Handle infinite state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleInfinite(TJsonDocument *doc)
{
    char inf_char;
    const char *inf_str = "infinity";
    int len = strlen(inf_str);

    while (doc->st_pos < len)
    {
	inf_char = tolower((int)(*str));
        if (inf_char != inf_str[doc->st_pos])
        {
            doc->err = json_tokener_error_parse_unexpected;
            return json_ret_out;
        }

        doc->st_pos++;
	AdvanceChar();
        if (!PeekChar())		
            return json_ret_out;
    }

    if (pb->FSize > 0 && pb->FBuf[0] == '-')
        doc->AddDouble(-INFINITY);
    else
        doc->AddDouble(INFINITY);

    saved_state = json_tokener_state_finish;
    state = json_tokener_state_eatws;
    return json_ret_redo;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleNullNan
#
#   Purpose....: Handle null or nan state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleNullNan(TJsonDocument *doc)
{
    char ch;
    int i;
	
    doc->st_pos++;
    AdvanceChar();
    if (!PeekChar())		
        return json_ret_out;

    ch = tolower((int)(*str));

    switch (ch)
    {
        case 'a':
            doc->st_pos++;
            AdvanceChar();
            if (!PeekChar())		
                return json_ret_out;
            
            ch = tolower((int)(*str));
            if (ch == 'n')
            {
                doc->AddDouble(NAN);

    	        saved_state = json_tokener_state_finish;
    	        state = json_tokener_state_eatws;
                return json_ret_break;
            }
            else
            {
                doc->err = json_tokener_error_parse_null;
                return json_ret_out;
            }

        case 'u':
            for (i = 0; i < 2; i++)
            {
                doc->st_pos++;
                AdvanceChar();
                if (!PeekChar())		
                    return json_ret_out;
            
                ch = tolower((int)(*str));
                if (ch != 'l')
                {
                    doc->err = json_tokener_error_parse_null;
                    return json_ret_out;
                }
            }
	    saved_state = json_tokener_state_finish;
	    state = json_tokener_state_eatws;
	    return json_ret_break;

        default:
            doc->err = json_tokener_error_parse_null;
            return json_ret_out;
    }
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleCommentStart
#
#   Purpose....: Handle comment start state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleCommentStart(TJsonDocument *doc)
{
    if (*str == '*') 
        state = json_tokener_state_comment;
    else if(*str == '/') 
        state = json_tokener_state_comment_eol;
    else 
    {
        doc->err = json_tokener_error_parse_comment;
	return json_ret_out;
    }

    pb->MemAppend(str, 1);
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleComment
#
#   Purpose....: Handle comment state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleComment(TJsonDocument *doc)
{
    const char *case_start = str;

    while(*str != '*') 
    {
        if (!AdvanceChar() || !PeekChar()) 
        {
            pb->MemAppend(case_start, str - case_start);
            return json_ret_out;
        }
    }

    pb->MemAppend(case_start, 1 + str - case_start);
    state = json_tokener_state_comment_end;
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleCommentEol
#
#   Purpose....: Handle comment to eol state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleCommentEol(TJsonDocument *doc)
{
    const char *case_start = str;

    while (*str != '\n')
    {
        if (!AdvanceChar() || !PeekChar()) 
        {
            pb->MemAppend(case_start, str - case_start);
	    return json_ret_out;
        }
    }

    pb->MemAppend(case_start, str - case_start);
    state = json_tokener_state_eatws;
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleCommentEnd
#
#   Purpose....: Handle comment end state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleCommentEnd(TJsonDocument *doc)
{
    pb->MemAppend(str, 1);

    if (*str == '/')
        state = json_tokener_state_eatws;
    else
        state = json_tokener_state_comment;

    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleString
#
#   Purpose....: Handle string state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleString(TJsonDocument *doc)
{
    const char *case_start = str;
    char *val_str;

    for (;;)
    {
        if(*str == doc->quote_char) 
        {
            pb->MemAppend(case_start, str - case_start);
            val_str = new char[pb->FBpos + 1];
            memcpy(val_str, pb->FBuf, pb->FBpos);
            val_str[pb->FBpos] = 0;
            doc->AddString(val_str);

	    saved_state = json_tokener_state_finish;
	    state = json_tokener_state_eatws;
            return json_ret_break;
        } 
        else if (*str == '\\') 
        {
            pb->MemAppend(case_start, str - case_start);
	    saved_state = json_tokener_state_string;
	    state = json_tokener_state_string_escape;
	    return json_ret_break;
        }

        if (!AdvanceChar() || !PeekChar()) 
        {
            pb->MemAppend(case_start, str - case_start);
	    return json_ret_out;
        }
    }
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleStringEscape
#
#   Purpose....: Handle string escape state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleStringEscape(TJsonDocument *doc)
{
    switch (*str) 
    {
        case '"':
        case '\\':
        case '/':
            pb->MemAppend(str, 1);
            break;

        case 'b':
            pb->MemAppend("\b", 1);
            break;

        case 'n':
            pb->MemAppend("\n", 1);
            break;

        case 'r':
            pb->MemAppend("\r", 1);
            break;

        case 't':
            pb->MemAppend("\t", 1);
            break;

        case 'f':
            pb->MemAppend("\f", 1);
            break;

        default:
	    doc->err = json_tokener_error_parse_string;
	    return json_ret_out;
    }

    state = saved_state;
    return json_ret_break;

}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleTrue
#
#   Purpose....: Handle true state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleTrue(TJsonDocument *doc)
{
    char ch;
    const char *comp_str = "true";
    int len = strlen(comp_str);
    int i;

    for (i = 0; i < len; i++)
    {
	ch = tolower((int)(*str));
        if (ch != comp_str[i])
        {
            doc->err = json_tokener_error_parse_boolean;
            return json_ret_out;
        }

	AdvanceChar();
        if (!PeekChar())		
            return json_ret_out;
    }

    doc->AddBoolean(true);

    saved_state = json_tokener_state_finish;
    state = json_tokener_state_eatws;
    return json_ret_redo;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleFalse
#
#   Purpose....: Handle false state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleFalse(TJsonDocument *doc)
{
    char ch;
    const char *comp_str = "false";
    int len = strlen(comp_str);
    int i;

    for (i = 0; i < len; i++)
    {
	ch = tolower((int)(*str));
        if (ch != comp_str[i])
        {
            doc->err = json_tokener_error_parse_boolean;
            return json_ret_out;
        }

	AdvanceChar();
        if (!PeekChar())		
            return json_ret_out;
    }

    doc->AddBoolean(false);

    saved_state = json_tokener_state_finish;
    state = json_tokener_state_eatws;
    return json_ret_redo;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::DecodeInt
#
#   Purpose....: Decode int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::DecodeInt(TJsonDocument *doc)
{
    long long val;
    char *end = NULL;

    val = strtoll(pb->FBuf, &end, 10);
    if (end != pb->FBuf)
    {
        doc->AddInt(val);

        saved_state = json_tokener_state_finish;
        state = json_tokener_state_eatws;
        return json_ret_redo;
    }
    else
    {
        doc->err = json_tokener_error_parse_number;
        return json_ret_out;
    }
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::DecodeDouble
#
#   Purpose....: Decode double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::DecodeDouble(TJsonDocument *doc)
{
    double val;
    char *end;

    val = strtod(pb->FBuf, &end);

    doc->AddDouble(val);

    saved_state = json_tokener_state_finish;
    state = json_tokener_state_eatws;
    return json_ret_redo;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleNumber
#
#   Purpose....: Handle number state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleNumber(TJsonDocument *doc)
{
    const char *case_start = str;
    int case_len = 0;
    bool is_exponent = false;
    int negativesign_next_possible_location=0;
    bool done = false;

    while (!done)	
    {
        switch (*str)
        {
            case '.':
                if (doc->is_double != 0) 
                {
                    doc->err = json_tokener_error_parse_number;
                    return json_ret_out;
                }
                doc->is_double = 1;
                break;

            case 'e':
            case 'E':
                if (is_exponent) 
                {
                    doc->err = json_tokener_error_parse_number;
                    return json_ret_out;
                }

                is_exponent = true;
                doc->is_double = 1;
	        negativesign_next_possible_location = case_len + 1;
                break;

            case '-':
                if (case_len != negativesign_next_possible_location) 
                {
                    doc->err = json_tokener_error_parse_number;
                    return json_ret_out;
                }
                break;

            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
            case '+':
                break;

            default:
                done = true;
                break;
        }

        if (!done)
        {
            case_len++;

            if (!AdvanceChar() || !PeekChar()) 
            {
                pb->MemAppend(case_start, case_len);
	        return json_ret_out;
            }
        }
    }

    if (case_len > 0)
        pb->MemAppend(case_start, case_len);
        
    if (pb->FBuf[0] == '-' && case_len <= 1 && (*str == 'i' || *str == 'I'))
    {
        state = json_tokener_state_inf;
        doc->st_pos = 0;
        return json_ret_redo;
    }
 
    if (doc->is_double)
        return DecodeDouble(doc);
    else
        return DecodeInt(doc);
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleArray
#
#   Purpose....: Handle array state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleArray(TJsonDocument *doc)
{
    if (*str == ']') 
    {
        is_array = false;
        saved_state = json_tokener_state_finish;
        state = json_tokener_state_eatws;
        return json_ret_break;
    } 
    else 
    {
	state = json_tokener_state_array_add;
        return json_ret_add;
    }
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleArrayAdd
#
#   Purpose....: Handle array add state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleArrayAdd(TJsonDocument *doc)
{
    doc->AddArray();

    saved_state = json_tokener_state_array_sep;
    state = json_tokener_state_eatws;
    return json_ret_redo;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleArraySep
#
#   Purpose....: Handle array sep state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleArraySep(TJsonDocument *doc)
{
    switch (*str)
    {
        case ']':
            saved_state = json_tokener_state_finish;
            state = json_tokener_state_eatws;
            break;

        case ',': 
            saved_state = json_tokener_state_array_after_sep;
            state = json_tokener_state_eatws;
            break;

        default:
            doc->err = json_tokener_error_parse_array;
	    return json_ret_out;
    }
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleObjectFieldStart
#
#   Purpose....: Handle object field start state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleObjectFieldStart(TJsonDocument *doc)
{
    switch (*str)
    {
        case '}': 
            saved_state = json_tokener_state_finish;
            state = json_tokener_state_eatws;
            break;

        case '"':
        case '\'':
            doc->quote_char = *str;
            pb->Reset();
            state = json_tokener_state_object_field;
            break;

        default:
            doc->err = json_tokener_error_parse_object_key_name;
	    return json_ret_out;
    }
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleObjectField
#
#   Purpose....: Handle object field state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleObjectField(TJsonDocument *doc)
{
    const char *case_start = str;
    char *val_str;
	
    while (true) 
    {
        if (*str == doc->quote_char) 
        {
            pb->MemAppend(case_start, str - case_start);
            val_str = new char[pb->FBpos + 1];
            memcpy(val_str, pb->FBuf, pb->FBpos);
            val_str[pb->FBpos] = 0;
            doc->SetFieldName(val_str);

	    saved_state = json_tokener_state_object_field_end;
	    state = json_tokener_state_eatws;
	    return json_ret_break;
        } 
        else if (*str == '\\') 
        {
            pb->MemAppend(case_start, str - case_start);
	    saved_state = json_tokener_state_object_field;
	    state = json_tokener_state_string_escape;
	    return json_ret_break;
        }

        if (!AdvanceChar() || !PeekChar()) 
        {
            pb->MemAppend(case_start, str - case_start);
	    return json_ret_out;
        }
    }
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleObjectFieldEnd
#
#   Purpose....: Handle object field end state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleObjectFieldEnd(TJsonDocument *doc)
{
    if (*str == ':') 
    {
        saved_state = json_tokener_state_object_value;
        state = json_tokener_state_eatws;
    } 
    else 
    {
        doc->err = json_tokener_error_parse_object_key_sep;
	return json_ret_out;
    }
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleObjectValue
#
#   Purpose....: Handle object value state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleObjectValue(TJsonDocument *doc)
{
    state = json_tokener_state_object_value_add;
    return json_ret_add;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleObjectValueAdd
#
#   Purpose....: Handle object value add state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleObjectValueAdd(TJsonDocument *doc)
{
    saved_state = json_tokener_state_object_sep;
    state = json_tokener_state_eatws;
    return json_ret_redo;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::HandleObjectSep
#
#   Purpose....: Handle object sep state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::HandleObjectSep(TJsonDocument *doc)
{
    switch (*str)
    {
        case '}':
            if (!doc->IsArrayData())
                doc->EndNesting();

            saved_state = json_tokener_state_finish;
            state = json_tokener_state_eatws;
            break;

        case ',': 
            saved_state = json_tokener_state_object_field_start_after_sep;
            state = json_tokener_state_eatws;
            break;

        default:
            doc->err = json_tokener_error_parse_object_value_sep;
            return json_ret_out;
    }
    return json_ret_break;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::Parse
#
#   Purpose....: Parse object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonStackEntry::Parse(TJsonDocument *doc, const char *data, int start_state)
{
    int ret;

    str = data;

    doc->err = json_tokener_success;

    if (start_state)
    {
        state = json_tokener_state_eatws;
        saved_state = start_state;
    }

    while (PeekChar()) 
    {

redo_char:

        switch(state) 
        {
            case json_tokener_state_eatws:
                ret = HandleEatWs(doc);
                break;

            case json_tokener_state_start:
                ret = HandleStart(doc);
                break;
    
            case json_tokener_state_finish:
                ret = HandleFinish(doc);
                break;

            case json_tokener_state_inf:
                ret = HandleInfinite(doc);
                break;

            case json_tokener_state_null:
               ret = HandleNullNan(doc);
               break;

            case json_tokener_state_comment_start:
                ret = HandleCommentStart(doc);
                break;

            case json_tokener_state_comment:
                ret = HandleComment(doc);
                break;

            case json_tokener_state_comment_eol:
                ret = HandleCommentEol(doc);
                break;

            case json_tokener_state_comment_end:
                ret = HandleCommentEnd(doc);
                break;

            case json_tokener_state_string:
                ret = HandleString(doc);
                break;

            case json_tokener_state_string_escape:
                ret = HandleStringEscape(doc);
                break;

            case json_tokener_state_true:
                ret = HandleTrue(doc);
                break;

            case json_tokener_state_false:
                ret = HandleFalse(doc);
                break;

            case json_tokener_state_number:
                ret = HandleNumber(doc);
                break;

            case json_tokener_state_array_after_sep:
            case json_tokener_state_array:
                ret = HandleArray(doc);
                break;

            case json_tokener_state_array_add:
                ret = HandleArrayAdd(doc);
                break;

            case json_tokener_state_array_sep:
                ret = HandleArraySep(doc);
                break;

            case json_tokener_state_object_field_start:
            case json_tokener_state_object_field_start_after_sep:
                ret = HandleObjectFieldStart(doc);
                break;

            case json_tokener_state_object_field:
                ret = HandleObjectField(doc);
                break;

            case json_tokener_state_object_field_end:
                ret = HandleObjectFieldEnd(doc);
                break;

            case json_tokener_state_object_value:
                ret = HandleObjectValue(doc);
                break;

            case json_tokener_state_object_value_add:
                ret = HandleObjectValueAdd(doc);
                break;

            case json_tokener_state_object_sep:
                ret = HandleObjectSep(doc);
                break;

        }

        switch (ret)
        {
            case json_ret_out:
            case json_ret_add:
            case json_ret_sub:
                return ret;

            case json_ret_redo:
                goto redo_char;
        }

        if (!AdvanceChar())
            return json_ret_out;
    }
    return json_ret_out;
}

/*##########################################################################
#
#   Name       : TJsonDocument::TJsonDocument
#
#   Purpose....: Constructor for TJsonDocument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDocument::TJsonDocument()
{
    Init();
}

/*##########################################################################
#
#   Name       : TJsonDocument::TJsonDocument
#
#   Purpose....: Constructor for TJsonDocument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDocument::TJsonDocument(const char *doc)
{
    Init();
    Parse(doc);
}

/*##########################################################################
#
#   Name       : TJsonDocument::~TJsonDocument
#
#   Purpose....: Destructor for TJsonDocument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDocument::~TJsonDocument()
{
}

/*##########################################################################
#
#   Name       : TJsonDocument::Init
#
#   Purpose....: Initialize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::Init()
{
    int level;

    for (level = 0; level < MAX_JSON_DEPTH; level++)
        StackArr[level] = 0;

    obj_field_name = 0;
}

/*##########################################################################
#
#   Name       : TJsonDocument::Parse
#
#   Purpose....: Parse
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::Parse(const char *doc)
{
    bool ok;
    TJsonStackEntry *entry;
    int ret;

    depth = 0;
    err = 0;
    st_pos = 0;
    ucs_char = 0;
    quote_char = 0;
    is_double = 0;
    flags = 0;

    start_state = json_tokener_state_start;
    ptr = doc;

    ok = AddLevel();

    while (ok)
    {
        entry = StackArr[depth - 1];
        ret = entry->Parse(this, ptr, start_state);

        switch (ret)
        {
            case json_ret_add:
                start_state = json_tokener_state_start;
                ptr = entry->str;
                ok = AddLevel();
                break;

            case json_ret_sub:
                start_state = 0;
                ptr = entry->str;
                ok = DeleteLevel();
                break;

            case json_ret_out:
                ok = false;
                break;
        }
    }

    return ok;

}

/*##########################################################################
#
#   Name       : TJsonDocument::AddLevel
#
#   Purpose....: Add new level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::AddLevel()
{
    TJsonStackEntry *entry;

    if (depth < MAX_JSON_DEPTH)
    {
        entry = StackArr[depth];

        if (entry == 0)
        {
            entry = new TJsonStackEntry;
            StackArr[depth] = entry;
        }

        entry->is_array = false;
        
        depth++;
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TJsonDocument::DeleteLevel
#
#   Purpose....: Delete level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::DeleteLevel()
{
    if (depth)
        depth--;

    if (depth)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TJsonDocument::IsArrayData
#
#   Purpose....: Is array data?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::IsArrayData()
{
    int ind;

    if (depth > 1)
    {
        ind = depth - 2;
        if (StackArr[ind]->is_array)
            return true;
    }
    return false;
}

/*##########################################################################
#
#   Name       : TJsonDocument::SetFieldName
#
#   Purpose....: Set field name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::SetFieldName(char *str)
{
    if (obj_field_name)
        delete obj_field_name;

    obj_field_name = str;
}

/*##########################################################################
#
#   Name       : TJsonDocument::StartNesting
#
#   Purpose....: Start nesting
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::StartNesting()
{
    printf("%s: object nesting\r\n", obj_field_name);
}

/*##########################################################################
#
#   Name       : TJsonDocument::EndNesting
#
#   Purpose....: End nesting
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::EndNesting()
{
    printf("Nesting end\r\n");
}

/*##########################################################################
#
#   Name       : TJsonDocument::AddArray
#
#   Purpose....: Add array element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::AddArray()
{
    printf("Add array\r\n");
}

/*##########################################################################
#
#   Name       : TJsonDocument::AddString
#
#   Purpose....: Add string object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::AddString(char *str)
{
    printf("%s: \"%s\"\r\n", obj_field_name, str);
    delete str;
}

/*##########################################################################
#
#   Name       : TJsonDocument::AddInt
#
#   Purpose....: Add int object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::AddInt(long long val)
{
   printf("%s: %lld\r\n", obj_field_name, val);
}

/*##########################################################################
#
#   Name       : TJsonDocument::AddDouble
#
#   Purpose....: Add double object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::AddDouble(double val)
{
   printf("%s: %5.3Lf\r\n", obj_field_name, val);
}

/*##########################################################################
#
#   Name       : TJsonDocument::AddBoolean
#
#   Purpose....: Add boolean object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::AddBoolean(bool val)
{
    if (val)
        printf("%s: true\r\n", obj_field_name);
    else
        printf("%s: false\r\n", obj_field_name);
}
