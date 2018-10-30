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
TJsonStackEntry::TJsonStackEntry(TJsonObject *object)
{
    pb = new TJsonPrintBuf;
    obj = object;
    obj_field_name = 0;
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

    if (obj_field_name)
        delete obj_field_name;
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::AddLevel
#
#   Purpose....: Add level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonStackEntry::AddLevel(TJsonDocument *doc, TJsonObject *object)
{
    return doc->AddLevel(object);
}

/*##########################################################################
#
#   Name       : TJsonStackEntry::DeleteLevel
#
#   Purpose....: Delete level
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonStackEntry::DeleteLevel(TJsonDocument *doc)
{
    pb->Reset();

    if (obj_field_name)
    {
        delete obj_field_name;
        obj_field_name = 0;
    }
    doc->DeleteLevel();
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
    while (isspace(*doc->str)) 
    {
	if (!doc->AdvanceChar() || !doc->PeekChar(this))
	    return json_ret_out;
    }

    if (*doc->str == '/') 
    {
        pb->Reset();
	pb->MemAppend(doc->str, 1);
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
    TJsonObject *o;

    switch (*doc->str) 
    {
        case '{':
	    state = json_tokener_state_eatws;
	    saved_state = json_tokener_state_object_field_start;
	    o = new TJsonObject();
            if (AddLevel(doc, o))
                return json_ret_break;
            else
                return json_ret_out;

        case '[':
            state = json_tokener_state_eatws;
            saved_state = json_tokener_state_array;
	    o = new TJsonArray();
            if (AddLevel(doc, o))
                return json_ret_break;
            else
                return json_ret_out;

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
	    doc->quote_char = *doc->str;
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
    DeleteLevel(doc);    
    return json_ret_out;
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
    TJsonObject *o;
    char inf_char;
    const char *inf_str = "infinity";
    int len = strlen(inf_str);

    while (doc->st_pos < len)
    {
	inf_char = tolower((int)(*doc->str));
        if (inf_char != inf_str[doc->st_pos])
        {
            doc->err = json_tokener_error_parse_unexpected;
            return json_ret_out;
        }

        doc->st_pos++;
	doc->AdvanceChar();
        if (!doc->PeekChar(this))		
            return json_ret_out;
    }

    saved_state = json_tokener_state_finish;
    state = json_tokener_state_eatws;

    if (pb->FSize > 0 && pb->FBuf[0] == '-')
        o = new TJsonDouble(-INFINITY);
    else
        o = new TJsonDouble(INFINITY);

    if (AddLevel(doc, o))
        return json_ret_redo;
    else
        return json_ret_out;
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
    TJsonObject *o;
    char ch;
    int i;
	
    doc->st_pos++;
    doc->AdvanceChar();
    if (!doc->PeekChar(this))		
        return json_ret_out;

    ch = tolower((int)(*doc->str));

    switch (ch)
    {
        case 'a':
            doc->st_pos++;
            doc->AdvanceChar();
            if (!doc->PeekChar(this))		
                return json_ret_out;
            
            ch = tolower((int)(*doc->str));
            if (ch == 'n')
            {
                o = new TJsonDouble(NAN);

                if (AddLevel(doc, o))
                    return json_ret_redo;
                else
                    return json_ret_out;
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
                doc->AdvanceChar();
                if (!doc->PeekChar(this))		
                    return json_ret_out;
            
                ch = tolower((int)(*doc->str));
                if (ch != 'l')
                {
                    doc->err = json_tokener_error_parse_null;
                    return json_ret_out;
                }
            }
	    saved_state = json_tokener_state_finish;
	    state = json_tokener_state_eatws;
	    return json_ret_redo;

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
    if (*doc->str == '*') 
        state = json_tokener_state_comment;
    else if(*doc->str == '/') 
        state = json_tokener_state_comment_eol;
    else 
    {
        doc->err = json_tokener_error_parse_comment;
	return json_ret_out;
    }

    pb->MemAppend(doc->str, 1);
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
    const char *case_start = doc->str;

    while(*doc->str != '*') 
    {
        if (!doc->AdvanceChar() || !doc->PeekChar(this)) 
        {
            pb->MemAppend(case_start, doc->str - case_start);
            return json_ret_out;
        }
    }

    pb->MemAppend(case_start, 1 + doc->str - case_start);
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
    const char *case_start = doc->str;

    while (*doc->str != '\n')
    {
        if (!doc->AdvanceChar() || !doc->PeekChar(this)) 
        {
            pb->MemAppend(case_start, doc->str - case_start);
	    return json_ret_out;
        }
    }

    pb->MemAppend(case_start, doc->str - case_start);
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
    pb->MemAppend(doc->str, 1);

    if (*doc->str == '/')
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
    TJsonObject *o;
    const char *case_start = doc->str;

    for (;;)
    {
        if(*doc->str == doc->quote_char) 
        {
            pb->MemAppend(case_start, doc->str - case_start);
	    saved_state = json_tokener_state_finish;
	    state = json_tokener_state_eatws;

            o = new TJsonString(pb->FBuf, pb->FBpos);

            if (AddLevel(doc, o))
                return json_ret_break;
            else
                return json_ret_out;
        } 
        else if (*doc->str == '\\') 
        {
            pb->MemAppend(case_start, doc->str - case_start);
	    saved_state = json_tokener_state_string;
	    state = json_tokener_state_string_escape;
	    return json_ret_break;
        }

        if (!doc->AdvanceChar() || !doc->PeekChar(this)) 
        {
            pb->MemAppend(case_start, doc->str - case_start);
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
    switch (*doc->str) 
    {
        case '"':
        case '\\':
        case '/':
            pb->MemAppend(doc->str, 1);
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
    TJsonObject *o;
    char ch;
    const char *str = "true";
    int len = strlen(str);

    while (doc->st_pos < len)
    {
	ch = tolower((int)(*doc->str));
        if (ch != str[doc->st_pos])
        {
            doc->err = json_tokener_error_parse_boolean;
            return json_ret_out;
        }

        doc->st_pos++;
	doc->AdvanceChar();
        if (!doc->PeekChar(this))		
            return json_ret_out;
    }

    saved_state = json_tokener_state_finish;
    state = json_tokener_state_eatws;

    o = new TJsonBoolean(true);

    if (AddLevel(doc, o))
        return json_ret_redo;
    else
        return json_ret_out;
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
    TJsonObject *o;
    char ch;
    const char *str = "false";
    int len = strlen(str);

    while (doc->st_pos < len)
    {
	ch = tolower((int)(*doc->str));
        if (ch != str[doc->st_pos])
        {
            doc->err = json_tokener_error_parse_boolean;
            return json_ret_out;
        }

        doc->st_pos++;
	doc->AdvanceChar();
        if (!doc->PeekChar(this))		
            return json_ret_out;
    }

    saved_state = json_tokener_state_finish;
    state = json_tokener_state_eatws;

    o = new TJsonBoolean(false);

    if (AddLevel(doc, o))
        return json_ret_redo;
    else
        return json_ret_out;
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
    TJsonObject *o;
    long long val;
    char *end = NULL;

    val = strtoll(pb->FBuf, &end, 10);
    if (end != pb->FBuf)
    {
        o = new TJsonInt(val);

        if (AddLevel(doc, o))
            return json_ret_redo;
        else
            return json_ret_out;
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
    TJsonObject *o;
    double val;
    char *end;

    val = strtod(pb->FBuf, &end);

    o = new TJsonDouble(val);

    if (AddLevel(doc, o))
        return json_ret_redo;
    else
        return json_ret_out;
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
    const char *case_start = doc->str;
    int case_len = 0;
    bool is_exponent = false;
    int negativesign_next_possible_location=1;
    bool done = false;

    while (!done)	
    {
        case_len++;

        switch (*doc->str)
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
            if (!doc->AdvanceChar() || !doc->PeekChar(this)) 
            {
                pb->MemAppend(case_start, case_len);
	        return json_ret_out;
            }
        }
    }

    if (case_len > 0)
        pb->MemAppend(case_start, case_len);
        
    if (pb->FBuf[0] == '-' && case_len <= 1 && (*doc->str == 'i' || *doc->str == 'I'))
    {
        state = json_tokener_state_inf;
        doc->st_pos = 0;
        return json_ret_redo;
    }

    saved_state = json_tokener_state_finish;
    state = json_tokener_state_eatws;
 
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
    if (*doc->str == ']') 
    {
        saved_state = json_tokener_state_finish;
        state = json_tokener_state_eatws;
    } 
    else 
	state = json_tokener_state_array_add;

    return json_ret_break;
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
    TJsonObject *o;

    saved_state = json_tokener_state_array_sep;
    state = json_tokener_state_eatws;

    o = new TJsonArray();
    if (AddLevel(doc, o))
        return json_ret_redo;
    else
        return json_ret_out;
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
bool TJsonStackEntry::Parse(TJsonDocument *doc)
{
    int ret;

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

    }

    return true;
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
#   Name       : TJsonDocument::PeekChar
#
#   Purpose....: Peek next char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::PeekChar(TJsonStackEntry *entry)
{
    if (char_offset == len)
    {
        if (depth == 0 && entry->state == json_tokener_state_eatws && entry->saved_state == json_tokener_state_finish)
            err = json_tokener_success;
        else
            err = json_tokener_continue;

        return false;
    }
    else
        return true;
}
 
/*##########################################################################
#
#   Name       : TJsonDocument::AdvanceChar
#
#   Purpose....: Advance to next char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDocument::AdvanceChar()
{
    if (*str)
    {
        str++;
        char_offset++;
        return true;
    }
    else
        return false;
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
bool TJsonDocument::AddLevel(TJsonObject *object)
{
    TJsonStackEntry *entry;

    if (depth < MAX_JSON_DEPTH)
    {
        entry = new TJsonStackEntry(object);
        StackArr[depth] = entry;
        depth++;
        return entry->Parse(this);
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
void TJsonDocument::DeleteLevel()
{
    if (depth)
    {
        depth--;
        delete StackArr[depth];
    }
}

/*
struct json_object* json_tokener_parse_ex(struct json_tokener *tok,
					  const char *str, int len)
{
  struct json_object *obj = NULL;
  char c = '\1';

  t*ok->char_offset = 0;
  tok->err = json_tokener_success;

  if ((len < -1) || (len == -1 && strlen(str) > INT32_MAX)) {
    tok->err = json_tokener_error_size;
    return NULL;
  }

  while (PEEK_CHAR(c, tok)) 
  {

  redo_char:


      break;





    case json_tokener_state_array_sep:
      if(c == ']') 
      {
	saved_state = json_tokener_state_finish;
	state = json_tokener_state_eatws;
      } 
      else if(c == ',') 
      {
	saved_state = json_tokener_state_array_after_sep;
	state = json_tokener_state_eatws;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_array;
	goto out;
      }
      break;

    case json_tokener_state_object_field_start:
    case json_tokener_state_object_field_start_after_sep:
      if(c == '}') 
      {
		if (state == json_tokener_state_object_field_start_after_sep &&
		    (tok->flags & JSON_TOKENER_STRICT))
		{
			tok->err = json_tokener_error_parse_unexpected;
			goto out;
		}
	saved_state = json_tokener_state_finish;
	state = json_tokener_state_eatws;
      } 
      else if (c == '"' || c == '\'') 
      {
	tok->quote_char = c;
	printbuf_reset(tok->pb);
	state = json_tokener_state_object_field;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_object_key_name;
	goto out;
      }
      break;

    case json_tokener_state_object_field:
      {
	const char *case_start = str;
	while(1) 
        {
	  if(c == tok->quote_char) 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    obj_field_name = strdup(tok->pb->buf);
	    saved_state = json_tokener_state_object_field_end;
	    state = json_tokener_state_eatws;
	    break;
	  } 
          else if(c == '\\') 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    saved_state = json_tokener_state_object_field;
	    state = json_tokener_state_string_escape;
	    break;
	  }
	  if (!ADVANCE_CHAR(str, tok) || !PEEK_CHAR(c, tok)) 
          {
	    printbuf_memappend_fast(tok->pb, case_start, str-case_start);
	    goto out;
	  }
	}
      }
      break;

    case json_tokener_state_object_field_end:
      if(c == ':') 
      {
	saved_state = json_tokener_state_object_value;
	state = json_tokener_state_eatws;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_object_key_sep;
	goto out;
      }
      break;

    case json_tokener_state_object_value:
      if(tok->depth >= tok->max_depth-1) 
      {
	tok->err = json_tokener_error_depth;
	goto out;
      }
      state = json_tokener_state_object_value_add;
      tok->depth++;
      json_tokener_reset_level(tok, tok->depth);
      goto redo_char;

    case json_tokener_state_object_value_add:
      json_object_object_add(current, obj_field_name, obj);
      free(obj_field_name);
      obj_field_name = NULL;
      saved_state = json_tokener_state_object_sep;
      state = json_tokener_state_eatws;
      goto redo_char;

    case json_tokener_state_object_sep:
      if(c == '}') 
      {
	saved_state = json_tokener_state_finish;
	state = json_tokener_state_eatws;
      } 
      else if(c == ',') 
      {
	saved_state = json_tokener_state_object_field_start_after_sep;
	state = json_tokener_state_eatws;
      } 
      else 
      {
	tok->err = json_tokener_error_parse_object_value_sep;
	goto out;
      }
      break;

    }
    if (!ADVANCE_CHAR(str, tok))
      goto out;
  }

 out:
  if (c &&
     (state == json_tokener_state_finish) &&
     (tok->depth == 0) &&
     (tok->flags & JSON_TOKENER_STRICT)) 
  {
      tok->err = json_tokener_error_parse_unexpected;
  }
  if (!c) { 
    if(state != json_tokener_state_finish &&
       saved_state != json_tokener_state_finish)
      tok->err = json_tokener_error_parse_eof;
  }

  if (tok->err == json_tokener_success)
  {
    json_object *ret = json_object_get(current);
	int ii;

    for(ii = tok->depth; ii >= 0; ii--)
      json_tokener_reset_level(tok, ii);
    return ret;
  }

  return NULL;
}

*/
