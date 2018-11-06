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
#   Name       : TJsonObject::TJsonObject
#
#   Purpose....: Constructor for TJsonObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject::TJsonObject(TString &FieldName)
 : FFieldName(FieldName)
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
#   Name       : TJsonObject::GetFieldName
#
#   Purpose....: Get field name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString &TJsonObject::GetFieldName()
{
    return FFieldName;
}

/*##########################################################################
#
#   Name       : TJsonObject::GetText
#
#   Purpose....: Get text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString &TJsonObject::GetText()
{
    return FText;
}

/*##########################################################################
#
#   Name       : TJsonObject::IsCollection
#
#   Purpose....: Is collection?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonObject::IsCollection()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonObject::GetBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonObject::GetBoolean()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonObject::GetInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonObject::GetInt()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TJsonObject::GetDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonObject::GetDouble()
{
    return 0.0;
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::TJsonCollectionData
#
#   Purpose....: Constructor for TJsonCollectionData
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollectionData::TJsonCollectionData()
{
    FObjArraySize = 0;
    FObjArrayCount = 0;
    FObjArr = 0;
}

/*##########################################################################
#
#   Name       : TJsonCollection::~TJsonCollection
#
#   Purpose....: Destructor for TJsonCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollectionData::~TJsonCollectionData()
{
    if (FObjArr)
        delete FObjArr;
}

/*##########################################################################
#
#   Name       : TJsonCollection::Grow
#
#   Purpose....: Grow array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollectionData::Grow()
{
    int i;
    int NewSize;
    TJsonObject **NewArr;    

    if (FObjArr)
    {
        NewSize = 2 * FObjArraySize;
        NewArr = new TJsonObject *[NewSize];

        for (i = 0; i < FObjArrayCount; i++)
            NewArr[i] = FObjArr[i];

        for (i = FObjArrayCount; i < NewSize; i++)
            NewArr[i] = 0;

        delete FObjArr;
    }
    else
    {
        NewSize = 10;
        NewArr = new TJsonObject *[NewSize];

        for (i = 0; i < NewSize; i++)
            NewArr[i] = 0;
    }

    FObjArr = NewArr;
    FObjArraySize = NewSize;
}

/*##########################################################################
#
#   Name       : TJsonCollection::TJsonCollection
#
#   Purpose....: Constructor for TJsonCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection::TJsonCollection(TString &FieldName)
 : TJsonObject(FieldName)
{
}

/*##########################################################################
#
#   Name       : TJsonCollection::~TJsonCollection
#
#   Purpose....: Destructor for TJsonCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection::~TJsonCollection()
{
}

/*##########################################################################
#
#   Name       : TJsonCollection::IsCollection
#
#   Purpose....: Is collection?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonCollection::IsCollection()
{
    return true;
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
TJsonArray::TJsonArray(TString &FieldName)
 : TJsonObject(FieldName)
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
TJsonInt::TJsonInt(TString &FieldName, long long v)
 : TJsonObject(FieldName)
{
    Val = v;

    FText.printf("%lld", v);
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
#   Name       : TJsonInt::GetBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonInt::GetBoolean()
{
    if (Val == 0)
        return false;
    else
        return true;
}

/*##########################################################################
#
#   Name       : TJsonInt::GetInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonInt::GetInt()
{
    return Val;
}

/*##########################################################################
#
#   Name       : TJsonInt::GetDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonInt::GetDouble()
{
    return (double)Val;
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
TJsonDouble::TJsonDouble(TString &FieldName, double v, TString &text)
 : TJsonObject(FieldName)
{
    Val = v;
    FText = text;
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
TJsonDouble::TJsonDouble(TString &FieldName, double v, int decimals)
 : TJsonObject(FieldName)
{
    double temp;
    int digits;
    bool done = false;
    char str[80];

    if (decimals < 1)
        decimals = 1;

    Val = v;

    if (v == INFINITY)
    {
        if (v == -INFINITY)
            FText = "nan";
        else
            FText = "infinity";
        done = true;
    }

    if (!done && v == -INFINITY)
    {
        FText = "-infinity";
        done = true;
    }

    if (!done)
    {
        temp = v;

        if (temp < 0)
        {
            digits = 2;
            temp = -temp;
        }
        else
            digits = 1;

        if (temp >= 1e+16)
        {
            FText.printf("%Lf", v);
            done = true;
        }
    }

    if (!done)
    {

        while (temp >= 10.0)
        {
            digits++;
            temp = temp / 10.0;
        }

        sprintf(str, "%%%d.%dLf", digits + decimals + 1, decimals);

        FText.printf(str, v);
    }
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
#   Name       : TJsonDouble::GetBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDouble::GetBoolean()
{
    if (Val > 0)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TJsonDouble::GetInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonDouble::GetInt()
{
    double temp = Val;
 
    if (temp >= 0.0)
    {
        if (temp > (double)0x7FFFFFFFFFFFFFFF)
            return 0x7FFFFFFFFFFFFFFF;
        else
            return (long long)(Val + 0.5);
    }
    else
    {
        temp = -temp;

        if (temp > (double)0x7FFFFFFFFFFFFFFF)
            return -0x7FFFFFFFFFFFFFFF;
        else
            return (long long)(Val - 0.5);
    }
}

/*##########################################################################
#
#   Name       : TJsonDouble::GetDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonDouble::GetDouble()
{
    return Val;
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
TJsonBoolean::TJsonBoolean(TString &FieldName, bool v)
 : TJsonObject(FieldName)
{
    Val = v;

    if (v)
        FText = "true";
    else
        FText = "false";
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
#   Name       : TJsonBoolean::GetBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonBoolean::GetBoolean()
{
    return Val;
}

/*##########################################################################
#
#   Name       : TJsonBoolean::GetInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonBoolean::GetInt()
{
    if (Val)
        return 1;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TJsonBoolean::GetDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonBoolean::GetDouble()
{
    if (Val)
        return 1.0;
    else
        return 0.0;
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
TJsonString::TJsonString(TString &FieldName, TString &text)
 : TJsonObject(FieldName)
{
    FText = text;
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
}

/*##########################################################################
#
#   Name       : TJsonString::GetBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonString::GetBoolean()
{
    if (!strcmp(FText.GetData(), "true"))
        return true;

    if (!strcmp(FText.GetData(), "false"))
        return false;

    if (FText.GetSize() == 0)
        return false;

    if (!strcmp(FText.GetData(), "0"))
        return false;
    else
        return true;
}

/*##########################################################################
#
#   Name       : TJsonString::GetInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonString::GetInt()
{
    char *end = NULL;

    return strtoll(FText.GetData(), &end, 10);
}

/*##########################################################################
#
#   Name       : TJsonString::GetDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonString::GetDouble()
{
    char *end;

    return strtod(FText.GetData(), &end);
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
    if (*FDataPtr)
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
    if (*FDataPtr)
    {
        FDataPtr++;
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
    while (isspace(*FDataPtr)) 
    {
	if (!AdvanceChar() || !PeekChar())
	    return json_ret_out;
    }

    if (*FDataPtr == '/') 
    {
        FData.Reset();
	FData += *FDataPtr;
	FState = json_tokener_state_comment_start;
    } 
    else 
    {
        FState = FSavedState;
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
    switch (*FDataPtr) 
    {
        case '{':
            if (!doc->IsArrayData())
                doc->StartNesting();

	    FState = json_tokener_state_eatws;
	    FSavedState = json_tokener_state_object_field_start;
            return json_ret_break;

        case '[':
            FIsArray = true;
            doc->StartNesting();

            FState = json_tokener_state_eatws;
            FSavedState = json_tokener_state_array;
            return json_ret_break;

        case 'I':
        case 'i':
            FState = json_tokener_state_inf;
            FData.Reset();
            return json_ret_redo;

        case 'N':
        case 'n':
	    FState = json_tokener_state_null; // or NaN
            FData.Reset();
	    return json_ret_redo;

        case '\'':
        case '"':
	    FState = json_tokener_state_string;
	    FData.Reset();
	    FQuoteChar = *FDataPtr;
            return json_ret_break;

        case 'T':
        case 't':
	    FState = json_tokener_state_true;
	    FData.Reset();
	    return json_ret_redo;

        case 'F':
        case 'f':
	    FState = json_tokener_state_false;
	    FData.Reset();
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
	    FState = json_tokener_state_number;
	    FData.Reset();
            FIsDouble = false;
	    return json_ret_redo;

        default:
	    doc->FErr = json_tokener_error_parse_unexpected;
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
    int i = 0;
    char inf_char;
    const char *inf_str = "infinity";
    int len = strlen(inf_str);

    for (i = 0; i < len; i++)
    {
	inf_char = tolower((int)(*FDataPtr));
        if (inf_char != inf_str[i])
        {
            doc->FErr = json_tokener_error_parse_unexpected;
            return json_ret_out;
        }

	AdvanceChar();
        if (!PeekChar())		
            return json_ret_out;
    }

    if (FData.GetSize() > 0 && FData[0] == '-')
        doc->AddDouble(-INFINITY, 0);
    else
        doc->AddDouble(INFINITY, 0);

    FSavedState = json_tokener_state_finish;
    FState = json_tokener_state_eatws;
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
	
    AdvanceChar();
    if (!PeekChar())		
        return json_ret_out;

    ch = tolower((int)(*FDataPtr));

    switch (ch)
    {
        case 'a':
            AdvanceChar();
            if (!PeekChar())		
                return json_ret_out;
            
            ch = tolower((int)(*FDataPtr));
            if (ch == 'n')
            {
                doc->AddDouble(NAN, 0);

    	        FSavedState = json_tokener_state_finish;
    	        FState = json_tokener_state_eatws;
                return json_ret_break;
            }
            else
            {
                doc->FErr = json_tokener_error_parse_null;
                return json_ret_out;
            }

        case 'u':
            for (i = 0; i < 2; i++)
            {
                AdvanceChar();
                if (!PeekChar())		
                    return json_ret_out;
            
                ch = tolower((int)(*FDataPtr));
                if (ch != 'l')
                {
                    doc->FErr = json_tokener_error_parse_null;
                    return json_ret_out;
                }
            }
	    FSavedState = json_tokener_state_finish;
	    FState = json_tokener_state_eatws;
	    return json_ret_break;

        default:
            doc->FErr = json_tokener_error_parse_null;
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
    if (*FDataPtr == '*') 
        FState = json_tokener_state_comment;
    else if(*FDataPtr == '/') 
        FState = json_tokener_state_comment_eol;
    else 
    {
        doc->FErr = json_tokener_error_parse_comment;
	return json_ret_out;
    }

    FData += *FDataPtr;
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
    const char *case_start = FDataPtr;

    while(*FDataPtr != '*') 
    {
        if (!AdvanceChar() || !PeekChar()) 
        {
            FData.Append(case_start, FDataPtr - case_start);
            return json_ret_out;
        }
    }

    FData.Append(case_start, 1 + FDataPtr - case_start);
    FState = json_tokener_state_comment_end;
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
    const char *case_start = FDataPtr;

    while (*FDataPtr != '\n')
    {
        if (!AdvanceChar() || !PeekChar()) 
        {
            FData.Append(case_start, FDataPtr - case_start);
	    return json_ret_out;
        }
    }

    FData.Append(case_start, FDataPtr - case_start);
    FState = json_tokener_state_eatws;
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
    FData += *FDataPtr;

    if (*FDataPtr == '/')
        FState = json_tokener_state_eatws;
    else
        FState = json_tokener_state_comment;

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
    const char *case_start = FDataPtr;
    char *val_str;
    int size;

    for (;;)
    {
        if(*FDataPtr == FQuoteChar) 
        {
            FData.Append(case_start, FDataPtr - case_start);
            doc->AddString(FData);

	    FSavedState = json_tokener_state_finish;
	    FState = json_tokener_state_eatws;
            return json_ret_break;
        } 
        else if (*FDataPtr == '\\') 
        {
            FData.Append(case_start, FDataPtr - case_start);
	    FSavedState = json_tokener_state_string;
	    FState = json_tokener_state_string_escape;
	    return json_ret_break;
        }

        if (!AdvanceChar() || !PeekChar()) 
        {
            FData.Append(case_start, FDataPtr - case_start);
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
    switch (*FDataPtr) 
    {
        case '"':
        case '\\':
        case '/':
            FData += *FDataPtr;
            break;

        case 'b':
            FData += '\b';
            break;

        case 'n':
            FData += '\n';
            break;

        case 'r':
            FData += '\r';
            break;

        case 't':
            FData += '\t';
            break;

        case 'f':
            FData += '\f';
            break;

        default:
	    doc->FErr = json_tokener_error_parse_string;
	    return json_ret_out;
    }

    FState = FSavedState;
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
	ch = tolower((int)(*FDataPtr));
        if (ch != comp_str[i])
        {
            doc->FErr = json_tokener_error_parse_boolean;
            return json_ret_out;
        }

	AdvanceChar();
        if (!PeekChar())		
            return json_ret_out;
    }

    doc->AddBoolean(true);

    FSavedState = json_tokener_state_finish;
    FState = json_tokener_state_eatws;
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
	ch = tolower((int)(*FDataPtr));
        if (ch != comp_str[i])
        {
            doc->FErr = json_tokener_error_parse_boolean;
            return json_ret_out;
        }

	AdvanceChar();
        if (!PeekChar())		
            return json_ret_out;
    }

    doc->AddBoolean(false);

    FSavedState = json_tokener_state_finish;
    FState = json_tokener_state_eatws;
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
    const char *ptr = FData.GetData();

    val = strtoll(ptr, &end, 10);
    if (end != ptr)
    {
        doc->AddInt(val);

        FSavedState = json_tokener_state_finish;
        FState = json_tokener_state_eatws;
        return json_ret_redo;
    }
    else
    {
        doc->FErr = json_tokener_error_parse_number;
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

    val = strtod(FData.GetData(), &end);

    doc->AddDouble(val, FData);

    FSavedState = json_tokener_state_finish;
    FState = json_tokener_state_eatws;
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
    const char *case_start = FDataPtr;
    int case_len = 0;
    bool is_exponent = false;
    int negativesign_next_possible_location=0;
    bool done = false;

    while (!done)	
    {
        switch (*FDataPtr)
        {
            case '.':
                if (FIsDouble) 
                {
                    doc->FErr = json_tokener_error_parse_number;
                    return json_ret_out;
                }
                FIsDouble = true;
                break;

            case 'e':
            case 'E':
                if (is_exponent) 
                {
                    doc->FErr = json_tokener_error_parse_number;
                    return json_ret_out;
                }

                is_exponent = true;
                FIsDouble = true;
	        negativesign_next_possible_location = case_len + 1;
                break;

            case '-':
                if (case_len != negativesign_next_possible_location) 
                {
                    doc->FErr = json_tokener_error_parse_number;
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
                FData.Append(case_start, case_len);
	        return json_ret_out;
            }
        }
    }

    if (case_len > 0)
        FData.Append(case_start, case_len);
        
    if (FData[0] == '-' && case_len <= 1 && (*FDataPtr == 'i' || *FDataPtr == 'I'))
    {
        FState = json_tokener_state_inf;
        return json_ret_redo;
    }
 
    if (FIsDouble)
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
    if (*FDataPtr == ']') 
    {
        FIsArray = false;
        doc->EndNesting();

        FSavedState = json_tokener_state_finish;
        FState = json_tokener_state_eatws;
        return json_ret_break;
    } 
    else 
    {
	FState = json_tokener_state_array_add;
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

    FSavedState = json_tokener_state_array_sep;
    FState = json_tokener_state_eatws;
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
    switch (*FDataPtr)
    {
        case ']':
            FIsArray = false;
            doc->EndNesting();

            FSavedState = json_tokener_state_finish;
            FState = json_tokener_state_eatws;
            break;

        case ',': 
            FSavedState = json_tokener_state_array_after_sep;
            FState = json_tokener_state_eatws;
            break;

        default:
            doc->FErr = json_tokener_error_parse_array;
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
    switch (*FDataPtr)
    {
        case '}': 
            FSavedState = json_tokener_state_finish;
            FState = json_tokener_state_eatws;
            break;

        case '"':
        case '\'':
            FQuoteChar = *FDataPtr;
            FData.Reset();
            FState = json_tokener_state_object_field;
            break;

        default:
            doc->FErr = json_tokener_error_parse_object_key_name;
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
    const char *case_start = FDataPtr;
	
    while (true) 
    {
        if (*FDataPtr == FQuoteChar) 
        {
            FData.Append(case_start, FDataPtr - case_start);
            doc->SetFieldName(FData);

	    FSavedState = json_tokener_state_object_field_end;
	    FState = json_tokener_state_eatws;
	    return json_ret_break;
        } 
        else if (*FDataPtr == '\\') 
        {
            FData.Append(case_start, FDataPtr - case_start);
	    FSavedState = json_tokener_state_object_field;
	    FState = json_tokener_state_string_escape;
	    return json_ret_break;
        }

        if (!AdvanceChar() || !PeekChar()) 
        {
            FData.Append(case_start, FDataPtr - case_start);
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
    if (*FDataPtr == ':') 
    {
        FSavedState = json_tokener_state_object_value;
        FState = json_tokener_state_eatws;
    } 
    else 
    {
        doc->FErr = json_tokener_error_parse_object_key_sep;
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
    FState = json_tokener_state_object_value_add;
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
    FSavedState = json_tokener_state_object_sep;
    FState = json_tokener_state_eatws;
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
    switch (*FDataPtr)
    {
        case '}':
            if (!doc->IsArrayData())
                doc->EndNesting();

            FSavedState = json_tokener_state_finish;
            FState = json_tokener_state_eatws;
            break;

        case ',': 
            FSavedState = json_tokener_state_object_field_start_after_sep;
            FState = json_tokener_state_eatws;
            break;

        default:
            doc->FErr = json_tokener_error_parse_object_value_sep;
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

    FDataPtr = data;

    doc->FErr = json_tokener_success;
    FQuoteChar = 0;
    FIsDouble = false;

    if (start_state)
    {
        FState = json_tokener_state_eatws;
        FSavedState = start_state;
    }

    while (PeekChar()) 
    {

redo_char:

        switch (FState) 
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

    FDepth = 0;
    FErr = 0;

    FStartState = json_tokener_state_start;
    FDocPtr = doc;

    ok = AddLevel();

    while (ok)
    {
        entry = StackArr[FDepth - 1];
        ret = entry->Parse(this, FDocPtr, FStartState);

        switch (ret)
        {
            case json_ret_add:
                FStartState = json_tokener_state_start;
                FDocPtr = entry->FDataPtr;
                ok = AddLevel();
                break;

            case json_ret_sub:
                FStartState = 0;
                FDocPtr = entry->FDataPtr;
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

    if (FDepth < MAX_JSON_DEPTH)
    {
        entry = StackArr[FDepth];

        if (entry == 0)
        {
            entry = new TJsonStackEntry;
            StackArr[FDepth] = entry;
        }

        entry->FIsArray = false;
        
        FDepth++;
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
    if (FDepth)
        FDepth--;

    if (FDepth)
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

    if (FDepth > 1)
    {
        ind = FDepth - 2;
        if (StackArr[ind]->FIsArray)
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
void TJsonDocument::SetFieldName(TString &str)
{
    FObjFieldName = str;
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
    TJsonCollection *c = new TJsonCollection(FObjFieldName);

    printf("%s: object nesting\r\n", FObjFieldName.GetData());
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
void TJsonDocument::AddString(TString &str)
{
    TJsonString *obj = new TJsonString(FObjFieldName, str);

    printf("%s: %s\r\n", obj->GetFieldName().GetData(), obj->GetText().GetData());
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
    TJsonInt *obj = new TJsonInt(FObjFieldName, val);

    long long v = obj->GetInt();
    printf("%s: %lld\r\n", obj->GetFieldName().GetData(), v);
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
void TJsonDocument::AddDouble(double val, TString &text)
{
    TJsonDouble *obj = new TJsonDouble(FObjFieldName, val, text);

    printf("%s: %s\r\n", obj->GetFieldName().GetData(), obj->GetText().GetData());
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
void TJsonDocument::AddDouble(double val, int decimals)
{
    TJsonDouble *obj = new TJsonDouble(FObjFieldName, val, decimals);

    printf("%s: %s\r\n", obj->GetFieldName().GetData(), obj->GetText().GetData());
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
    TJsonBoolean *obj = new TJsonBoolean(FObjFieldName, val);

    bool v = obj->GetBoolean();

    if (v)
        printf("%s: true\r\n", obj->GetFieldName().GetData());
    else
        printf("%s: false\r\n", obj->GetFieldName().GetData());
}
