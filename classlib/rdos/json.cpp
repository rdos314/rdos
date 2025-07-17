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
#include "sockobj.h"
#include "rdos.h"

#define MIN_BLOCK_SIZE	0x1000

#define json_tokener_success                            1
#define json_tokener_continue                           2
#define json_tokener_error_depth                        3
#define json_tokener_error_parse_eof                    4
#define json_tokener_error_parse_unexpected             5
#define json_tokener_error_parse_null                   6
#define json_tokener_error_parse_boolean                7
#define json_tokener_error_parse_number                 8
#define json_tokener_error_parse_array                  9
#define json_tokener_error_parse_object_key_name        10
#define json_tokener_error_parse_object_key_sep         11
#define json_tokener_error_parse_object_value_sep       12
#define json_tokener_error_parse_string                 13
#define json_tokener_error_parse_comment                14
#define json_tokener_error_size                         15

#define json_tokener_state_eatws                        1
#define json_tokener_state_start                        2
#define json_tokener_state_finish                       3
#define json_tokener_state_null                         4
#define json_tokener_state_comment_start                5
#define json_tokener_state_comment                      6
#define json_tokener_state_comment_eol                  7
#define json_tokener_state_comment_end                  8
#define json_tokener_state_string                       9
#define json_tokener_state_string_escape                10
#define json_tokener_state_true                         11
#define json_tokener_state_false                        12
#define json_tokener_state_number                       13
#define json_tokener_state_array                        14
#define json_tokener_state_array_add                    15
#define json_tokener_state_array_sep                    16
#define json_tokener_state_object_field_start           17
#define json_tokener_state_object_field                 18
#define json_tokener_state_object_field_end             19
#define json_tokener_state_object_value                 20
#define json_tokener_state_object_value_add             21
#define json_tokener_state_object_sep                   22
#define json_tokener_state_array_after_sep              23
#define json_tokener_state_object_field_start_after_sep 24
#define json_tokener_state_inf                          25

#define json_ret_out                                    1
#define json_ret_redo                                   2
#define json_ret_break                                  3
#define json_ret_add                                    4
#define json_ret_sub                                    5

/*##################  TJsonMem:TJsonMem  ###############
*   Purpose....: Constructor for JSON memory block                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TJsonMem::TJsonMem(int MaxSize)
{
    FSize = MaxSize;
    FPos = 0;
    FArr = new char[MaxSize];
}

/*##################  TJsonMem::~TJsonMem  ###############
*   Purpose....: Destructor for JSON memory block                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TJsonMem::~TJsonMem()
{
    if (FArr)
        delete FArr;
}

/*##################  TJsonMem::Allocate  ###############
*   Purpose....: Allocate a memory segment                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TJsonMem::Allocate(int size)
{
    char *p;
    
    if (FPos + size <= FSize)
    {
        p = FArr + FPos;
        FPos += size;
        return p;
    }
    else
        return 0;
}

/*##################  TJsonAlloc:TJsonAlloc  ###############
*   Purpose....: Constructor for JSON allocation                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TJsonAlloc::TJsonAlloc()
{
    FMemCount = 0;
    FMemSize = 0;
}

/*##################  TJsonAlloc::~TJsonAlloc  ###############
*   Purpose....: Destructor for JSON allocation                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TJsonAlloc::~TJsonAlloc()
{
    Reset();
}

/*##################  TJsonAlloc::Allocate  ###############
*   Purpose....: Allocate a memory segment                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TJsonAlloc::Allocate(int size)
{
    int i;
    void *blk = 0;
    TJsonMem **nmema;
    int asize;
    int nsize;

    for (i = 0; i < FMemCount && !blk; i++)
        blk = FArr[i]->Allocate(size);

    if (!blk)
    {
        if (FMemCount == FMemSize)
        {
            if (FMemCount)
            {
                nsize = 2 * FMemSize;
                nmema = new TJsonMem *[nsize];

                for (i = 0; i < FMemSize; i++)
                    nmema[i] = FArr[i];

                for (i = FMemSize; i < nsize; i++)
                    nmema[i] = 0;

                delete FArr;
            }
            else
            {
                nsize = 10;
                nmema = new TJsonMem *[nsize];

                for (i = 0; i < nsize; i++)
                    nmema[i] = 0;
            }

            FArr = nmema;
            FMemSize = nsize;
        }

        if (size < MIN_BLOCK_SIZE)
            asize = MIN_BLOCK_SIZE;
        else
            asize = size;

        FArr[FMemCount] = new TJsonMem(asize);
        blk = FArr[FMemCount]->Allocate(size);        
        FMemCount++;
    }

    return blk;
}

/*##################  TJsonAlloc::Reset  ###############
*   Purpose....: Reset allocator                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TJsonAlloc::Reset()
{
    int i;

    for (i = 0; i < FMemCount; i++)
        if (FArr[i])
            delete FArr[i];

    if (FMemCount && FArr)
        delete FArr;

    FMemSize = 0;
    FMemCount = 0;
}

/*##########################################################################
#
#   Name       : TJsonFormString::TJsonFormString
#
#   Purpose....: Constructor for TJsonFormString
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonFormString::TJsonFormString()
{
}

/*##########################################################################
#
#   Name       : TJsonFormString::TJsonFormString
#
#   Purpose....: Constructor for TJsonFormString
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonFormString::TJsonFormString(const char *str)
{
   Reformat(str);
}

/*##########################################################################
#
#   Name       : TJsonFormString::TJsonFormString
#
#   Purpose....: Constructor for TJsonFormString
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonFormString::TJsonFormString(const TString &src)
{
   Reformat(src.GetData());
}

/*##########################################################################
#
#   Name       : TJsonFormString::~TJsonFormString
#
#   Purpose....: Destructor for TJsonFormString
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonFormString::~TJsonFormString()
{
}

/*##########################################################################
#
#   Name       : TJsonFormString::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TJsonFormString &TJsonFormString::operator=(const TString &src)
{
    Reformat(src.GetData());
    return *this;
}

/*##########################################################################
#
#   Name       : TJsonFormString::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TJsonFormString &TJsonFormString::operator=(const char *str)
{
    Reformat(str);
    return *this;
}

/*##########################################################################
#
#   Name       : TJsonFormString::Reformat
#
#   Purpose....: Reformat for JSON text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonFormString::Reformat(const char *str)
{
    while (*str)
    {
        switch (*str)
        {
            case 0x22:
                Append(0x5C);
                Append(0x22);
                str++;
                break;

            case 0xd:
                Append(0x5C);
                Append("n");
                str++;
                if (*str == 0xa)
                    str++;
                break;
                
            case 0xa:
                Append(0x5C);
                Append("n");
                str++;
                if (*str == 0xd)
                    str++;
                break;

            case 0x5C:
                Append(0x5C);
                Append(0x5C);
                str++;
                break;

            default:
                Append(*str);
                str++;
                break;
        }
    }
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
TJsonObject::TJsonObject(const char *FieldName, TJsonAlloc *Alloc)
{
    int len = strlen(FieldName);

    FAlloc = Alloc;

    FFieldName = (char *)Allocate(len + 1);
    strcpy(FFieldName, FieldName);

    FSize = 0;
    FText = "";
}

/*##########################################################################
#
#   Name       : TJsonObject::TJsonObject
#
#   Purpose....: Copy constructor for TJsonObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject::TJsonObject(const TJsonObject &src, TJsonAlloc *Alloc)
{
    int len;

    FAlloc = Alloc;

    len = strlen(src.FFieldName);
    FFieldName = (char *)Allocate(len + 1);
    strcpy(FFieldName, src.FFieldName);

    if (src.FSize)
    {
        len = strlen(src.FText);
        FSize = len + 1;
        FText = (char *)Allocate(len + 1);
        strcpy(FText, src.FText);
    }
    else
    {
        FSize = 0;
        FText = "";
    }
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
    Free(FFieldName);
}

/*##########################################################################
#
#   Name       : TJsonObject::Allocate
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void *TJsonObject::Allocate(int size)
{
    return FAlloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonObject::Free
#
#   Purpose....: free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::Free(void *ptr)
{
}

/*##########################################################################
#
#   Name       : TJsonObject::new
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void *TJsonObject::operator new(size_t size, TJsonAlloc *alloc)
{
    return alloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonObject::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonObject::Clone(TJsonAlloc *Alloc)
{
    return CloneObj(Alloc);
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
const char *TJsonObject::GetFieldName()
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
const char *TJsonObject::GetText()
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
#   Name       : TJsonObject::IsArrayObject
#
#   Purpose....: Is array object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonObject::IsArrayObject()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonObject::Rename
#
#   Purpose....: Rename object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::Rename(const char *NewFieldName)
{
    int CurrLen = strlen(FFieldName);
    int NewLen = strlen(NewFieldName);

    if (NewLen > CurrLen)
    {
        Free(FFieldName);
        FFieldName = (char *)Allocate(NewLen + 1);
    }

    strcpy(FFieldName, NewFieldName);
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
    return GetBaseBoolean();
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
    return GetBaseInt();
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
    return GetBaseDouble();
}

/*##########################################################################
#
#   Name       : TJsonObject::GetDateTime
#
#   Purpose....: Get date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TJsonObject::GetDateTime()
{
    return GetBaseDateTime();
}

/*##########################################################################
#
#   Name       : TJsonObject::CodeBoolean
#
#   Purpose....: Code boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::CodeBoolean(bool v)
{
    const char *ptr;

    if (v)
        ptr = "true";
    else
        ptr = "false";

    SetBaseString(ptr);
}

/*##########################################################################
#
#   Name       : TJsonObject::CodeInt
#
#   Purpose....: Code int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::CodeInt(long long v)
{
    char str[80];

    sprintf(str, "%lld", v);
    SetBaseString(str);
}

/*##########################################################################
#
#   Name       : TJsonObject::CodeDouble
#
#   Purpose....: Set value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::CodeDouble(double v, int decimals)
{
    double temp;
    int digits;
    bool done = false;
    char str[80];
    char formstr[40];

    if (decimals < 1)
        decimals = 1;

    if (v == INFINITY)
    {
        if (v == -INFINITY)
            SetBaseString("nan");
        else
            SetBaseString("infinity");
        done = true;
    }

    if (!done && v == -INFINITY)
    {
        SetBaseString("-infinity");
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
            sprintf(str, "%Lf", v);
            SetBaseString(str);
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

        sprintf(formstr, "%%%d.%dLf", digits + decimals + 1, decimals);
        sprintf(str, formstr, v);
        SetBaseString(str);
    }
}

/*##########################################################################
#
#   Name       : TJsonObject::CodeDateTime
#
#   Purpose....: Code date&time object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::CodeDateTime(TDateTime &time)
{
    char str[80];

    sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());
    SetBaseString(str);
}

/*##########################################################################
#
#   Name       : TJsonObject::CodeDateTimeZone
#
#   Purpose....: Code date&time object with timezone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::CodeDateTimeZone(TDateTime &time, int UtcDiff)
{
    char str[80];

    if (UtcDiff == 0)
        sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02dZ", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());
    else if (UtcDiff > 0)
        sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02d+%02d:%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec(), UtcDiff / 60, UtcDiff % 60);
    else
    {
        UtcDiff = -UtcDiff;
        sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02d-%02d:%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec(), UtcDiff / 60, UtcDiff % 60);
    }
    SetBaseString(str);
}

/*##########################################################################
#
#   Name       : TJsonObject::DecodeBoolean
#
#   Purpose....: Decode boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonObject::DecodeBoolean()
{
    if (!strcmp(FText, "true"))
        return true;

    if (!strcmp(FText, "false"))
        return false;

    if (FText[0] == 0)
        return false;

    if (!strcmp(FText, "0"))
        return false;
    else
        return true;
}

/*##########################################################################
#
#   Name       : TJsonObject::DecodeInt
#
#   Purpose....: Decode int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonObject::DecodeInt()
{
    char *end = NULL;

    return strtoll(FText, &end, 10);
}

/*##########################################################################
#
#   Name       : TJsonObject::DecodeDouble
#
#   Purpose....: Decode double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonObject::DecodeDouble()
{
    char *end;

    return strtod(FText, &end);
}

/*##########################################################################
#
#   Name       : TJsonObject::DecodeDateTime
#
#   Purpose....: Decode date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TJsonObject::DecodeDateTime()
{
    int year, month, day;
    int hour, min, sec;
    int count;

    year = 1970;
    month = 1;
    day = 1;
    hour = 0;
    min = 0;
    sec = 0;

    count = sscanf(FText, "%04d-%02d-%02dT%02d:%02d:%02d", &year, &month, &day, &hour, &min, &sec);

    TDateTime time(year, month, day, hour, min, sec);
    return time;
}

/*##########################################################################
#
#   Name       : TJsonObject::SetBoolean
#
#   Purpose....: Set boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetBoolean(bool val)
{
    SetBaseBoolean(val);
}

/*##########################################################################
#
#   Name       : TJsonObject::SetInt
#
#   Purpose....: Set int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetInt(long long val)
{
    SetBaseInt(val);
}

/*##########################################################################
#
#   Name       : TJsonObject::SetDouble
#
#   Purpose....: Set double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetDouble(double val, int decimals)
{
    SetBaseDouble(val, decimals);
}

/*##########################################################################
#
#   Name       : TJsonObject::SetDateTime
#
#   Purpose....: Set date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetDateTime(TDateTime &val)
{
    SetBaseDateTime(val);
}

/*##########################################################################
#
#   Name       : TJsonObject::SetDateTimeZone
#
#   Purpose....: Set date & time with timezone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetDateTimeZone(TDateTime &val, int diff)
{
    SetBaseDateTimeZone(val, diff);
}

/*##########################################################################
#
#   Name       : TJsonObject::SetString
#
#   Purpose....: Set string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetString(const char *Str)
{
    SetBaseString(Str);
}

/*##########################################################################
#
#   Name       : TJsonObject::GetBaseBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonObject::GetBaseBoolean()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonObject::GetBaseInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonObject::GetBaseInt()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TJsonObject::GetBaseDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonObject::GetBaseDouble()
{
    return 0.0;
}

/*##########################################################################
#
#   Name       : TJsonObject::GetBaseDateTime
#
#   Purpose....: Get date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TJsonObject::GetBaseDateTime()
{
    TDateTime time;
    return time;
}

/*##########################################################################
#
#   Name       : TJsonObject::SetBaseBoolean
#
#   Purpose....: Set boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetBaseBoolean(bool val)
{
}

/*##########################################################################
#
#   Name       : TJsonObject::SetBaseInt
#
#   Purpose....: Set int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetBaseInt(long long val)
{
}

/*##########################################################################
#
#   Name       : TJsonObject::SetBaseDouble
#
#   Purpose....: Set double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetBaseDouble(double val, int decimals)
{
}

/*##########################################################################
#
#   Name       : TJsonObject::SetBaseDateTime
#
#   Purpose....: Set date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetBaseDateTime(TDateTime &val)
{
}

/*##########################################################################
#
#   Name       : TJsonObject::SetBaseDateTimeZone
#
#   Purpose....: Set date & time with timezone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetBaseDateTimeZone(TDateTime &val, int diff)
{
}

/*##########################################################################
#
#   Name       : TJsonObject::SetBaseString
#
#   Purpose....: Set string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::SetBaseString(const char *Str)
{
    int len = strlen(Str);

    if (len)
    {
        if (len + 1 > FSize)
        {
            if (FSize)
                Free(FText);

            FSize = len + 1;
            FText = (char *)Allocate(len + 1);
        }
    }
    else
    {
        if (FSize)
            Free(FText);

        FSize = 0;
        FText = "";
    }

    if (FSize)
        strcpy(FText, Str);
}

/*##########################################################################
#
#   Name       : TJsonObject::AddIndent
#
#   Purpose....: Add indention
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::AddIndent(TJsonDocument *doc, int indent, TString &str)
{
    doc->AddIndent(indent, str);
}

/*##########################################################################
#
#   Name       : TJsonObject::NewLine
#
#   Purpose....: Add new line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::NewLine(TJsonDocument *doc, TString &str)
{
    doc->NewLine(str);
}

/*##########################################################################
#
#   Name       : TJsonObject::Write
#
#   Purpose....: Write object data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonObject::Write(TJsonDocument *doc, int indent, TString &str)
{
    TJsonFormString EscStr(FText);

    AddIndent(doc, indent, str);
    str += "\"";
    str += FFieldName;
    str += "\": ";
    str += EscStr;
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::TJsonArrayObject
#
#   Purpose....: Constructor for TJsonArrayObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayObject::TJsonArrayObject(const char *FieldName, TJsonAlloc *Alloc)
 : TJsonObject(FieldName, Alloc)
{
    FArraySize = 0;
    FArrayCount = 0;
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::TJsonArrayObject
#
#   Purpose....: Copy constructor for TJsonArrayObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayObject::TJsonArrayObject(const TJsonArrayObject &src, TJsonAlloc *Alloc)
 : TJsonObject(src, Alloc)
{
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::~TJsonArrayObject
#
#   Purpose....: Destructor for TJsonArrayObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayObject::~TJsonArrayObject()
{
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayObject *TJsonArrayObject::Clone(TJsonAlloc *Alloc)
{
    return (TJsonArrayObject *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::Count
#
#   Purpose....: Elements 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonArrayObject::Count()
{
    return FArrayCount;
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::IsArrayObject
#
#   Purpose....: Is array object?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonArrayObject::IsArrayObject()
{
    return true;
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::IsBooleanArray
#
#   Purpose....: Is boolean array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonArrayObject::IsBooleanArray()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::IsIntArray
#
#   Purpose....: Is int array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonArrayObject::IsIntArray()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::IsDoubleArray
#
#   Purpose....: Is double array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonArrayObject::IsDoubleArray()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonArrayObject::IsStringArray
#
#   Purpose....: Is string array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonArrayObject::IsStringArray()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::TJsonBooleanArray
#
#   Purpose....: Constructor for TJsonBooleanArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBooleanArray::TJsonBooleanArray(const char *FieldName, TJsonAlloc *Alloc)
 : TJsonArrayObject(FieldName, Alloc)
{
    FArr = 0;
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::TJsonBooleanArray
#
#   Purpose....: Copy constructor for TJsonBooleanArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBooleanArray::TJsonBooleanArray(const TJsonBooleanArray &src, TJsonAlloc *Alloc)
 : TJsonArrayObject(src, Alloc)
{
    int i;

    if (src.FArrayCount)
    {
        FArraySize = src.FArrayCount;
        FArrayCount = src.FArrayCount;
        FArr = AllocateArr(FArraySize);

        for (i = 0; i < FArrayCount; i++)
            FArr[i] = src.FArr[i];
    }
    else
    {
        FArraySize = 0;
        FArrayCount = 0;
        FArr = 0;
    }
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::~TJsonBooleanArray
#
#   Purpose....: Destructor for TJsonBooleanArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBooleanArray::~TJsonBooleanArray()
{
    FreeArr(FArr);
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::AllocateArr
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool *TJsonBooleanArray::AllocateArr(int count)
{
    int size = count * sizeof(bool);

    return (bool *)FAlloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::FreeArr
#
#   Purpose....: free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBooleanArray::FreeArr(bool *arr)
{
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonBooleanArray::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonBooleanArray(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBooleanArray *TJsonBooleanArray::Clone(TJsonAlloc *Alloc)
{
    return (TJsonBooleanArray *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::IsBooleanArray
#
#   Purpose....: Is boolean array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonBooleanArray::IsBooleanArray()
{
    return true;
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::Grow
#
#   Purpose....: Grow array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBooleanArray::Grow()
{
    int i;
    int NewSize; 
    bool *NewArr;

    if (FArr)
    {
        NewSize = 2 * FArraySize;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < FArrayCount; i++)
            NewArr[i] = FArr[i];

        for (i = FArrayCount; i < NewSize; i++)
            NewArr[i] = false;

        FreeArr(FArr);
    }
    else
    {
        NewSize = 10;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < NewSize; i++)
            NewArr[i] = false;
    }

    FArr = NewArr;
    FArraySize = NewSize;
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::Get
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonBooleanArray::Get(int Pos)
{
    if (Pos < FArrayCount)
        return FArr[Pos];
    else
        return false;
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::Add
#
#   Purpose....: Add value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBooleanArray::Add(bool val)
{
    if (FArraySize == FArrayCount)
        Grow();

    FArr[FArrayCount] = val;
    FArrayCount++;
}

/*##########################################################################
#
#   Name       : TJsonBooleanArray::Write
#
#   Purpose....: Write object data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBooleanArray::Write(TJsonDocument *doc, int indent, TString &str)
{
    int i;

    AddIndent(doc, indent, str);
    str += "\"";
    str += FFieldName;
    str += "\": [";

    for (i = 0; i < FArrayCount; i++)
    {
        if (i)
            str += ",";

        if (FArr[i])
            str += "true";
        else
            str += "false";
    }

    str += "]";
}

/*##########################################################################
#
#   Name       : TJsonIntArray::TJsonIntArray
#
#   Purpose....: Constructor for TJsonIntArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonIntArray::TJsonIntArray(const char *FieldName, TJsonAlloc *Alloc)
 : TJsonArrayObject(FieldName, Alloc)
{
    FArraySize = 0;
    FArrayCount = 0;
    FArr = 0;
}

/*##########################################################################
#
#   Name       : TJsonIntArray::TJsonIntArray
#
#   Purpose....: Copy constructor for TJsonIntArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonIntArray::TJsonIntArray(const TJsonIntArray &src, TJsonAlloc *Alloc)
 : TJsonArrayObject(src, Alloc)
{
    int i;

    if (src.FArrayCount)
    {
        FArraySize = src.FArrayCount;
        FArrayCount = src.FArrayCount;
        FArr = AllocateArr(FArraySize);

        for (i = 0; i < FArrayCount; i++)
            FArr[i] = src.FArr[i];
    }
    else
    {
        FArraySize = 0;
        FArrayCount = 0;
        FArr = 0;
    }
}

/*##########################################################################
#
#   Name       : TJsonIntArray::~TJsonIntArray
#
#   Purpose....: Destructor for TJsonIntArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonIntArray::~TJsonIntArray()
{
    FreeArr(FArr);
}

/*##########################################################################
#
#   Name       : TJsonIntArray::AllocateArr
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long *TJsonIntArray::AllocateArr(int count)
{
    int size = count * sizeof(long long);

    return (long long *)FAlloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonIntArray::FreeArr
#
#   Purpose....: free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonIntArray::FreeArr(long long *arr)
{
}

/*##########################################################################
#
#   Name       : TJsonIntArray::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonIntArray::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonIntArray(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonIntArray::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonIntArray *TJsonIntArray::Clone(TJsonAlloc *Alloc)
{
    return (TJsonIntArray *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonIntArray::IsIntArray
#
#   Purpose....: Is int array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonIntArray::IsIntArray()
{
    return true;
}

/*##########################################################################
#
#   Name       : TJsonIntArray::Grow
#
#   Purpose....: Grow array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonIntArray::Grow()
{
    int i;
    int NewSize;
    long long *NewArr;

    if (FArr)
    {
        NewSize = 2 * FArraySize;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < FArrayCount; i++)
            NewArr[i] = FArr[i];

        for (i = FArrayCount; i < NewSize; i++)
            NewArr[i] = 0;

        FreeArr(FArr);
    }
    else
    {
        NewSize = 10;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < NewSize; i++)
            NewArr[i] = 0;
    }

    FArr = NewArr;
    FArraySize = NewSize;
}

/*##########################################################################
#
#   Name       : TJsonIntArray::Get
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonIntArray::Get(int Pos)
{
    if (Pos < FArrayCount)
        return FArr[Pos];
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TJsonIntArray::Add
#
#   Purpose....: Add value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonIntArray::Add(long long val)
{
    if (FArraySize == FArrayCount)
        Grow();

    FArr[FArrayCount] = val;
    FArrayCount++;
}

/*##########################################################################
#
#   Name       : TJsonIntArray::Write
#
#   Purpose....: Write object data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonIntArray::Write(TJsonDocument *doc, int indent, TString &str)
{
    int i;
    char buf[40];

    AddIndent(doc, indent, str);
    str += "\"";
    str += FFieldName;
    str += "\": [";

    for (i = 0; i < FArrayCount; i++)
    {
        if (i)
            str += ",";

        sprintf(buf, "%lld", FArr[i]);
        str += buf;
    }

    str += "]";
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::TJsonDoubleArray
#
#   Purpose....: Constructor for TJsonDoubleArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDoubleArray::TJsonDoubleArray(const char *FieldName, TJsonAlloc *Alloc, int Decimals)
 : TJsonArrayObject(FieldName, Alloc)
{
    FArraySize = 0;
    FArrayCount = 0;
    FArr = 0;

    if (Decimals < 1)
        FDecimals = 1;
    else
        FDecimals = Decimals;
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::TJsonDoubleArray
#
#   Purpose....: Copy constructor for TJsonDoubleArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDoubleArray::TJsonDoubleArray(const TJsonDoubleArray &src, TJsonAlloc *Alloc)
 : TJsonArrayObject(src, Alloc)
{
    int i;

    if (src.FArrayCount)
    {
        FArraySize = src.FArrayCount;
        FArrayCount = src.FArrayCount;
        FArr = AllocateArr(FArraySize);

        for (i = 0; i < FArrayCount; i++)
            FArr[i] = src.FArr[i];
    }
    else
    {
        FArraySize = 0;
        FArrayCount = 0;
        FArr = 0;
    }
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::~TJsonDoubleArray
#
#   Purpose....: Destructor for TJsonDoubleArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDoubleArray::~TJsonDoubleArray()
{
    FreeArr(FArr);
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::AllocateArr
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double *TJsonDoubleArray::AllocateArr(int count)
{
    int size = count * sizeof(double);

    return (double *)FAlloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::FreeArr
#
#   Purpose....: free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDoubleArray::FreeArr(double *arr)
{
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonDoubleArray::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonDoubleArray(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDoubleArray *TJsonDoubleArray::Clone(TJsonAlloc *Alloc)
{
    return (TJsonDoubleArray *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::IsDoubleArray
#
#   Purpose....: Is double array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDoubleArray::IsDoubleArray()
{
    return true;
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::Grow
#
#   Purpose....: Grow array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDoubleArray::Grow()
{
    int i;
    int NewSize;
    double *NewArr;

    if (FArr)
    {
        NewSize = 2 * FArraySize;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < FArrayCount; i++)
            NewArr[i] = FArr[i];

        for (i = FArrayCount; i < NewSize; i++)
            NewArr[i] = INFINITY;

        FreeArr(FArr);
    }
    else
    {
        NewSize = 10;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < NewSize; i++)
            NewArr[i] = INFINITY;
    }

    FArr = NewArr;
    FArraySize = NewSize;
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::Get
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonDoubleArray::Get(int Pos)
{
    if (Pos < FArrayCount)
        return FArr[Pos];
    else
        return 0.0;
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::Add
#
#   Purpose....: Add value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDoubleArray::Add(double val)
{
    if (FArraySize == FArrayCount)
        Grow();

    FArr[FArrayCount] = val;
    FArrayCount++;
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::AddNone
#
#   Purpose....: Add none
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDoubleArray::AddNone()
{
    if (FArraySize == FArrayCount)
        Grow();

    FArr[FArrayCount] = INFINITY;
    FArrayCount++;
}

/*##########################################################################
#
#   Name       : TJsonDoubleArray::Write
#
#   Purpose....: Write object data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDoubleArray::Write(TJsonDocument *doc, int indent, TString &str)
{
    int i;
    double temp;
    int digits;
    bool done = false;
    char buf[80];
    char format[20];

    AddIndent(doc, indent, str);
    str += "\"";
    str += FFieldName;
    str += "\": [";

    for (i = 0; i < FArrayCount; i++)
    {
        if (i)
            str += ",";

        if (FArr[i] == INFINITY)
            str += "null";
        else
        {
            temp = FArr[i];

            if (temp < 0)
            {
                digits = 2;
                temp = -temp;
            }
            else
                digits = 1;

            if (temp >= 1e+16)
                sprintf(buf, "%Lf", FArr[i]);
            else
            {
                while (temp >= 10.0)
                {
                    digits++;
                    temp = temp / 10.0;
                }

                sprintf(format, "%%%d.%dLf", digits + FDecimals + 1, FDecimals);
                sprintf(buf, format, FArr[i]);
            }
            str += buf;
        }
    }

    str += "]";
}

/*##########################################################################
#
#   Name       : TJsonStringArray::TJsonStringArray
#
#   Purpose....: Constructor for TJsonStringArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStringArray::TJsonStringArray(const char *FieldName, TJsonAlloc *Alloc)
 : TJsonArrayObject(FieldName, Alloc)
{
    FArraySize = 0;
    FArrayCount = 0;
    FArr = 0;
}

/*##########################################################################
#
#   Name       : TJsonStringArray::TJsonStringArray
#
#   Purpose....: Copy constructor for TJsonStringArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStringArray::TJsonStringArray(const TJsonStringArray &src, TJsonAlloc *Alloc)
 : TJsonArrayObject(src, Alloc)
{
    int i;
    int len;

    if (src.FArrayCount)
    {
        FArraySize = src.FArrayCount;
        FArrayCount = src.FArrayCount;
        FArr = AllocateArr(FArraySize);

        for (i = 0; i < FArrayCount; i++)
        {
            if (src.FArr[i])
            {
                len = strlen(src.FArr[i]);
                 FArr[i] = new(Alloc) char[len + 1];
                 strcpy(FArr[i], src.FArr[i]);
            }
            else
                FArr[i] = 0;
        }
    }
    else
    {
        FArraySize = 0;
        FArrayCount = 0;
        FArr = 0;
    }
}

/*##########################################################################
#
#   Name       : TJsonStringArray::~TJsonStringArray
#
#   Purpose....: Destructor for TJsonStringArray
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStringArray::~TJsonStringArray()
{
    Free(FArr);
}

/*##########################################################################
#
#   Name       : TJsonStringArray::AllocateArr
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char **TJsonStringArray::AllocateArr(int count)
{
    int size = count * sizeof(char *);

    return (char **)FAlloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonStringArray::FreeArr
#
#   Purpose....: free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonStringArray::FreeArr(char **arr)
{
}

/*##########################################################################
#
#   Name       : TJsonStringArray::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonStringArray::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonStringArray(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonStringArray::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStringArray *TJsonStringArray::Clone(TJsonAlloc *Alloc)
{
    return (TJsonStringArray *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonStringArray::IsStringArray
#
#   Purpose....: Is string array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonStringArray::IsStringArray()
{
    return true;
}

/*##########################################################################
#
#   Name       : TJsonStringArray::Grow
#
#   Purpose....: Grow array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonStringArray::Grow()
{
    int i;
    int NewSize;
    char **NewArr;

    if (FArr)
    {
        NewSize = 2 * FArraySize;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < FArrayCount; i++)
            NewArr[i] = FArr[i];

        for (i = FArrayCount; i < NewSize; i++)
            NewArr[i] = 0;

        FreeArr(FArr);
    }
    else
    {
        NewSize = 10;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < NewSize; i++)
            NewArr[i] = 0;
    }

    FArr = NewArr;
    FArraySize = NewSize;
}

/*##########################################################################
#
#   Name       : TJsonStringArray::Get
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TJsonStringArray::Get(int Pos)
{
    if (Pos < FArrayCount)
        return FArr[Pos];
    else
        return "";
}

/*##########################################################################
#
#   Name       : TJsonStringArray::Add
#
#   Purpose....: Add value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonStringArray::Add(const char *str)
{
    int size = strlen(str);
    char *s;

    s = (char *)Allocate(size + 1);
    strcpy(s, str);         

    if (FArraySize == FArrayCount)
        Grow();

    FArr[FArrayCount] = s;
    FArrayCount++;
}

/*##########################################################################
#
#   Name       : TJsonStringArray::Write
#
#   Purpose....: Write object data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonStringArray::Write(TJsonDocument *doc, int indent, TString &str)
{
    int i;

    AddIndent(doc, indent, str);
    str += "\"";
    str += FFieldName;
    str += "\": [";

    for (i = 0; i < FArrayCount; i++)
    {
        if (i)
            str += ",";

        str += "\"";

        if (FArr[i])
            str += FArr[i];

        str += "\"";
    }

    str += "]";
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
TJsonCollectionData::TJsonCollectionData(TJsonAlloc *Alloc)
{
    FObjArraySize = 0;
    FObjArrayCount = 0;
    FObjArr = 0;
    FAlloc = Alloc;
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::TJsonCollectionData
#
#   Purpose....: Copy constructor for TJsonCollectionData
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollectionData::TJsonCollectionData(const TJsonCollectionData &src, TJsonAlloc *Alloc)
{
    int i;

    FAlloc = Alloc;

    if (src.FObjArrayCount)
    {
        FObjArraySize = src.FObjArrayCount;
        FObjArrayCount = src.FObjArrayCount;
        FObjArr = AllocateArr(FObjArraySize);

        for (i = 0; i < FObjArrayCount; i++)
            if (src.FObjArr[i])
                FObjArr[i] = src.FObjArr[i]->Clone(Alloc);
            else
                FObjArr[i] = 0;
    }
    else
    {
        FObjArraySize = 0;
        FObjArrayCount = 0;
        FObjArr = 0;
    }
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::~TJsonCollectionData
#
#   Purpose....: Destructor for TJsonCollectionData
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollectionData::~TJsonCollectionData()
{
    FreeArr(FObjArr);
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::AllocateArr
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject **TJsonCollectionData::AllocateArr(int count)
{
    int size = count * sizeof(TJsonObject *);

    return (TJsonObject **)FAlloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::FreeArr
#
#   Purpose....: free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollectionData::FreeArr(TJsonObject **arr)
{
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::new
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void *TJsonCollectionData::operator new(size_t size, TJsonAlloc *alloc)
{
    return alloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::Grow
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
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < FObjArrayCount; i++)
            NewArr[i] = FObjArr[i];

        for (i = FObjArrayCount; i < NewSize; i++)
            NewArr[i] = 0;

        FreeArr(FObjArr);
    }
    else
    {
        NewSize = 10;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < NewSize; i++)
            NewArr[i] = 0;
    }

    FObjArr = NewArr;
    FObjArraySize = NewSize;
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::Insert
#
#   Purpose....: Insert object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollectionData::Insert(TJsonObject *obj)
{
    if (FObjArraySize == FObjArrayCount)
        Grow();

    FObjArr[FObjArrayCount] = obj;
    FObjArrayCount++;
}

/*##########################################################################
#
#   Name       : TJsonCollectionData::Remove
#
#   Purpose....: Remove object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonCollectionData::Remove(TJsonObject *obj)
{
    int i;
    bool found = false;

    for (i = 0; i < FObjArrayCount; i++)
        if (found)
            FObjArr[i - 1] = FObjArr[i];
        else
            if (FObjArr[i] == obj)
                found = true;

    if (found)
    {
        FObjArrayCount--;
        FObjArr[FObjArrayCount] = 0;
    }

    return found;
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
TJsonCollection::TJsonCollection(const char *FieldName, TJsonAlloc *Alloc)
 : TJsonObject(FieldName, Alloc)
{
    FParent = 0;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::TJsonCollection
#
#   Purpose....: Copy constructor for TJsonCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection::TJsonCollection(const TJsonCollection &src, TJsonAlloc *Alloc)
 : TJsonObject(src, Alloc)
{
    FParent = 0;
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
#   Name       : TJsonCollection::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection *TJsonCollection::Clone(TJsonAlloc *Alloc)
{
    return (TJsonCollection *)CloneObj(Alloc);
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
#   Name       : TJsonCollection::RemoveObj
#
#   Purpose....: Remove object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonCollection::RemoveObj(const char *FieldName)
{
    bool ok = false;
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        ok = Remove(obj);

    return ok;
}

/*##########################################################################
#
#   Name       : TJsonCollection::RemoveCollection
#
#   Purpose....: Remove collection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonCollection::RemoveCollection(const char *FieldName)
{
    bool ok = false;
    TJsonObject *obj = GetCollection(FieldName);

    if (obj)
        ok = Remove(obj);

    return ok;
}

/*##########################################################################
#
#   Name       : TJsonCollection::DetachObj
#
#   Purpose....: Detach object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonCollection::DetachObj(const char *FieldName)
{
    bool ok = false;
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        ok = Remove(obj);

    if (ok)
        return obj;
    else
       return 0;
}

/*##########################################################################
#
#   Name       : TJsonCollection::DetachCollection
#
#   Purpose....: Detach collection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection *TJsonCollection::DetachCollection(const char *FieldName)
{
    bool ok = false;
    TJsonCollection *coll = GetCollection(FieldName);

    if (coll)
        ok = Remove(coll);

    if (ok)
        return coll;
    else
       return 0;
}

/*##########################################################################
#
#   Name       : TJsonCollection::GetBoolean
#
#   Purpose....: Get field as boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonCollection::GetBoolean(const char *FieldName, bool Default)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        return obj->GetBoolean();
    else
        return Default;
}

/*##########################################################################
#
#   Name       : TJsonCollection::GetInt
#
#   Purpose....: Get field as int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonCollection::GetInt(const char *FieldName, long long Default)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        return obj->GetInt();
    else
        return Default;
}

/*##########################################################################
#
#   Name       : TJsonCollection::GetDouble
#
#   Purpose....: Get field as double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonCollection::GetDouble(const char *FieldName, double Default)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        return obj->GetDouble();
    else
        return Default;
}

/*##########################################################################
#
#   Name       : TJsonCollection::GetDateTime
#
#   Purpose....: Get field as date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TJsonCollection::GetDateTime(const char *FieldName, TDateTime &Default)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        return obj->GetDateTime();
    else
        return Default;
}

/*##########################################################################
#
#   Name       : TJsonCollection::GetText
#
#   Purpose....: Get field as text
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TJsonCollection::GetText(const char *FieldName, const char *Default)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        return obj->GetText();
    else
        return Default;
}

/*##########################################################################
#
#   Name       : TJsonCollection::SetBoolean
#
#   Purpose....: Set field as boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollection::SetBoolean(const char *FieldName, bool Val)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        obj->SetBoolean(Val);
    else
        AddBoolean(FieldName, Val);
}

/*##########################################################################
#
#   Name       : TJsonCollection::SetInt
#
#   Purpose....: Set field as int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollection::SetInt(const char *FieldName, long long Val)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        obj->SetInt(Val);
    else
        AddInt(FieldName, Val);
}

/*##########################################################################
#
#   Name       : TJsonCollection::SetDouble
#
#   Purpose....: Set field as double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollection::SetDouble(const char *FieldName, double Val, int Decimals)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        obj->SetDouble(Val, Decimals);
    else
        AddDouble(FieldName, Val, Decimals);
}

/*##########################################################################
#
#   Name       : TJsonCollection::SetDateTime
#
#   Purpose....: Set field as date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollection::SetDateTime(const char *FieldName, TDateTime &Val, int UseText)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        obj->SetDateTime(Val);
    else
        AddDateTime(FieldName, Val, UseText);
}

/*##########################################################################
#
#   Name       : TJsonCollection::SetDateTimeZone
#
#   Purpose....: Set field as date & time with timezone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollection::SetDateTimeZone(const char *FieldName, TDateTime &Val, int UtcDiff)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        obj->SetDateTimeZone(Val, UtcDiff);
    else
        AddDateTimeZone(FieldName, Val, UtcDiff);
}

/*##########################################################################
#
#   Name       : TJsonCollection::SetString
#
#   Purpose....: Set field as string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonCollection::SetString(const char *FieldName, const char *Str)
{
    TJsonObject *obj = GetObj(FieldName);

    if (obj)
        obj->SetString(Str);
    else
        AddString(FieldName, Str);
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::AddCollection
#
#   Purpose....: Add new collection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonSingleCollection *TJsonCollection::AddCollection(const char *FieldName)
{
    TJsonSingleCollection *col = new(FAlloc) TJsonSingleCollection(FieldName, FAlloc);
    Insert(col);
    return col;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddArrayCollection
#
#   Purpose....: Add new array collection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayCollection *TJsonCollection::AddArrayCollection(const char *FieldName)
{
    TJsonArrayCollection *col = new(FAlloc) TJsonArrayCollection(FieldName, FAlloc);
    Insert(col);
    return col;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddBooleanArray
#
#   Purpose....: Add new boolean array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBooleanArray *TJsonCollection::AddBooleanArray(const char *FieldName)
{
    TJsonBooleanArray *arr = new(FAlloc) TJsonBooleanArray(FieldName, FAlloc);
    Insert(arr);
    return arr;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddIntArray
#
#   Purpose....: Add new int array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonIntArray *TJsonCollection::AddIntArray(const char *FieldName)
{
    TJsonIntArray *arr = new(FAlloc) TJsonIntArray(FieldName, FAlloc);
    Insert(arr);
    return arr;

}

/*##########################################################################
#
#   Name       : TJsonCollection::AddDoubleArray
#
#   Purpose....: Add new double array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDoubleArray *TJsonCollection::AddDoubleArray(const char *FieldName, int Decimals)
{
    TJsonDoubleArray *arr = new(FAlloc) TJsonDoubleArray(FieldName, FAlloc, Decimals);
    Insert(arr);
    return arr;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddStringArray
#
#   Purpose....: Add new string array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonStringArray *TJsonCollection::AddStringArray(const char *FieldName)
{
    TJsonStringArray *arr = new(FAlloc) TJsonStringArray(FieldName, FAlloc);
    Insert(arr);
    return arr;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddBoolean
#
#   Purpose....: Add new boolean object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonCollection::AddBoolean(const char *FieldName, bool Val)
{
    TJsonObject *obj = new(FAlloc) TJsonBoolean(FieldName, FAlloc, Val);
    Insert(obj);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddInt
#
#   Purpose....: Add new int object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonCollection::AddInt(const char *FieldName, long long Val)
{
    TJsonObject *obj = new(FAlloc) TJsonInt(FieldName, FAlloc, Val);
    Insert(obj);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddDouble
#
#   Purpose....: Add new double object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonCollection::AddDouble(const char *FieldName, double Val, int Decimals)
{
    TJsonObject *obj = new(FAlloc) TJsonDouble(FieldName, FAlloc, Val, Decimals);
    Insert(obj);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddDateTime
#
#   Purpose....: Add new date&time object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonCollection::AddDateTime(const char *FieldName, TDateTime &time, int UseText)
{
    TJsonObject *obj;
    char str[80];

    if (UseText)
    {
        sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());
        obj = new(FAlloc) TJsonString(FieldName, FAlloc, str);
    }
    else
        obj = new(FAlloc) TJsonInt(FieldName, FAlloc, time.GetLinuxMilliTimestamp());

    Insert(obj);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddDateTimeZone
#
#   Purpose....: Add new date&time object with timezone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonCollection::AddDateTimeZone(const char *FieldName, TDateTime &time, int UtcDiff)
{
    TJsonObject *obj;
    char str[80];

    if (UtcDiff == 0)
        sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02dZ", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec());
    else if (UtcDiff > 0)
        sprintf(str, "%04d-%02d-%02dT%02d:%02d:%02d+%02d:%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec(), UtcDiff / 60, UtcDiff % 60);
    else
    {
        UtcDiff = -UtcDiff;
        sprintf(str,"%04d-%02d-%02dT%02d:%02d:%02d-%02d:%02d", time.GetYear(), time.GetMonth(), time.GetDay(), time.GetHour(), time.GetMin(), time.GetSec(), UtcDiff / 60, UtcDiff % 60);
    }
        
    obj = new(FAlloc) TJsonString(FieldName, FAlloc, str);
    Insert(obj);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonCollection::AddString
#
#   Purpose....: Add new string object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonCollection::AddString(const char *FieldName, const char *Str)
{
    TJsonObject *obj = new(FAlloc) TJsonString(FieldName, FAlloc, Str);
    Insert(obj);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::TJsonSingleCollection
#
#   Purpose....: Constructor for TJsonSingleCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonSingleCollection::TJsonSingleCollection(const char *FieldName, TJsonAlloc *Alloc)
 : TJsonCollection(FieldName, Alloc),
   FData(Alloc)
{
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::TJsonSingleCollection
#
#   Purpose....: Copy constructor for TJsonSingleCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonSingleCollection::TJsonSingleCollection(const TJsonSingleCollection &src, TJsonAlloc *Alloc)
 : TJsonCollection(src, Alloc),
   FData(src.FData, Alloc)
{
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::~TJsonSingleCollection
#
#   Purpose....: Destructor for TJsonSingleCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonSingleCollection::~TJsonSingleCollection()
{
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonSingleCollection::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonSingleCollection(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonSingleCollection *TJsonSingleCollection::Clone(TJsonAlloc *Alloc)
{
    return (TJsonSingleCollection *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::IsArray
#
#   Purpose....: Is array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonSingleCollection::IsArray()
{
    return false;
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::Insert
#
#   Purpose....: Insert object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonSingleCollection::Insert(TJsonObject *obj)
{
    FData.Insert(obj);
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::Remove
#
#   Purpose....: Remove object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonSingleCollection::Remove(TJsonObject *obj)
{
    return FData.Remove(obj);
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::Write
#
#   Purpose....: Write object data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonSingleCollection::Write(TJsonDocument *doc, int indent, TString &str)
{
    int i;
    int size;
    TJsonObject *obj;

    if (FFieldName[0])
    {
        AddIndent(doc, indent, str);
        str += "\"";
        str += FFieldName;
        str += "\":";
        NewLine(doc, str);
    }

    AddIndent(doc, indent, str);
    str += "{";
    NewLine(doc, str);

    size = FData.FObjArrayCount;

    for (i = 0; i < size; i++)
    {
        obj = FData.FObjArr[i];
        obj->Write(doc, indent + 1, str);

        if (size != i + 1)
            str += ",";
        NewLine(doc, str);
     }

    AddIndent(doc, indent, str);
    str += "}";
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::GetArrayCount
#
#   Purpose....: Get # of arrays
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonSingleCollection::GetArrayCount()
{
    return 1;
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::GetObjCount
#
#   Purpose....: Get # of objects
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonSingleCollection::GetObjCount()
{
    return FData.FObjArrayCount;
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::GetObj
#
#   Purpose....: Get an object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonSingleCollection::GetObj(int n)
{
    if (n >= 0 && n < FData.FObjArrayCount)
        return FData.FObjArr[n];
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::GetObj
#
#   Purpose....: Get an object with a given name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonSingleCollection::GetObj(const char *FieldName)
{
    int n;
    TJsonObject *obj;

    for (n = 0; n < FData.FObjArrayCount; n++)
    {
        obj = FData.FObjArr[n];
        if (!obj->IsCollection())
            if (!strcmp(obj->GetFieldName(), FieldName))
                return obj;
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TJsonSingleCollection::GetCollection
#
#   Purpose....: Get a collection with a given name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection *TJsonSingleCollection::GetCollection(const char *FieldName)
{
    int n;
    TJsonObject *obj;

    for (n = 0; n < FData.FObjArrayCount; n++)
    {
        obj = FData.FObjArr[n];
        if (obj->IsCollection())
            if (!strcmp(obj->GetFieldName(), FieldName))
                return (TJsonCollection *)obj;
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::TJsonArrayCollection
#
#   Purpose....: Constructor for TJsonArrayCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayCollection::TJsonArrayCollection(const char *FieldName, TJsonAlloc *Alloc)
 : TJsonCollection(FieldName, Alloc)
{
    FArrayCount = 0;
    FArraySize = 0;
    FArray = 0;
    FCurrInd = 0;

    AddArray();
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::TJsonArrayCollection
#
#   Purpose....: Copy constructor for TJsonArrayCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayCollection::TJsonArrayCollection(const TJsonArrayCollection &src, TJsonAlloc *Alloc)
 : TJsonCollection(src, Alloc)
{
    int i;

    FReqAdd = false;
    FCurrInd = 0;

    FArrayCount = src.FArrayCount;
    FArraySize = src.FArrayCount;

    if (FArrayCount)
    {
        FArray = AllocateArr(FArrayCount);

        for (i = 0; i < FArrayCount; i++)
        {
            if (src.FArray[i])
                FArray[i] = new(Alloc) TJsonCollectionData(*src.FArray[i], Alloc);
            else
                FArray[i] = 0;
        }
    }
    else
        FArray = 0;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::~TJsonArrayCollection
#
#   Purpose....: Destructor for TJsonArrayCollection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayCollection::~TJsonArrayCollection()
{
    FreeArr(FArray);
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::AllocateArr
#
#   Purpose....: new
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollectionData **TJsonArrayCollection::AllocateArr(int count)
{
    int size = count * sizeof(TJsonCollectionData *);

    return (TJsonCollectionData **)FAlloc->Allocate(size);
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::FreeArr
#
#   Purpose....: free
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonArrayCollection::FreeArr(TJsonCollectionData **arr)
{
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonArrayCollection::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonArrayCollection(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonArrayCollection *TJsonArrayCollection::Clone(TJsonAlloc *Alloc)
{
    return (TJsonArrayCollection *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::IsArray
#
#   Purpose....: Is array?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonArrayCollection::IsArray()
{
    return true;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::Grow
#
#   Purpose....: Grow array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonArrayCollection::Grow()
{
    int i;
    int NewSize;
    TJsonCollectionData **NewArr;

    if (FArray)
    {
        NewSize = 2 * FArraySize;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < FArrayCount; i++)
            NewArr[i] = FArray[i];

        for (i = FArrayCount; i < NewSize; i++)
            NewArr[i] = 0;

        FreeArr(FArray);
    }
    else
    {
        NewSize = 10;
        NewArr = AllocateArr(NewSize);

        for (i = 0; i < NewSize; i++)
            NewArr[i] = 0;
    }

    FArray = NewArr;
    FArraySize = NewSize;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::DoAdd
#
#   Purpose....: Do add array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonArrayCollection::DoAdd()
{
    TJsonCollectionData *entry = new(FAlloc) TJsonCollectionData(FAlloc);

    if (FArrayCount == FArraySize)
        Grow();

    FArray[FArrayCount] = entry;
    FCurrInd = FArrayCount;
    FArrayCount++;

    FReqAdd = false;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::AddArray
#
#   Purpose....: Add array element
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonArrayCollection::AddArray()
{
    FReqAdd = true;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::Insert
#
#   Purpose....: Insert object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonArrayCollection::Insert(TJsonObject *obj)
{
    if (FReqAdd)
        DoAdd();

    FArray[FCurrInd]->Insert(obj);
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::Remove
#
#   Purpose....: Remove object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonArrayCollection::Remove(TJsonObject *obj)
{
    return FArray[FCurrInd]->Remove(obj);
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::Write
#
#   Purpose....: Write object data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonArrayCollection::Write(TJsonDocument *doc, int indent, TString &str)
{
    int a;
    int i;
    int size;
    TJsonObject *obj;

    AddIndent(doc, indent, str);
    str += "\"";
    str += FFieldName;
    str += "\":";
    NewLine(doc, str);

    AddIndent(doc, indent, str);
    str += "[\r\n";

    for (a = 0; a < FArrayCount; a++)
    {
        size = FArray[a]->FObjArrayCount;

        AddIndent(doc, indent + 1, str);
        str += "{";
        NewLine(doc, str);

        for (i = 0; i < size; i++)
        {
            obj = FArray[a]->FObjArr[i];
            obj->Write(doc, indent + 2, str);

            if (size != i + 1)
                str += ",";
            NewLine(doc, str);
        }

        AddIndent(doc, indent + 1, str);
        if (FArrayCount == a + 1)
            str += "}";
        else
            str += "},";
        NewLine(doc, str);
    }

    AddIndent(doc, indent, str);
    str += "]";
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::SelectArray
#
#   Purpose....: Select current array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonArrayCollection::SelectArray(int n)
{
    if (n >= 0 && n < FArrayCount)
        FCurrInd = n;
    else
        FCurrInd = 0;

    FReqAdd = false;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::GetObjCount
#
#   Purpose....: Get # of objects
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonArrayCollection::GetObjCount()
{
    if (FReqAdd)
    {
        FCurrInd = 0;
        FReqAdd = false;
    }

    return FArray[FCurrInd]->FObjArrayCount;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::GetObj
#
#   Purpose....: Get an object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonArrayCollection::GetObj(int n)
{
    if (FReqAdd)
    {
        FCurrInd = 0;
        FReqAdd = false;
    }

    if (FArray)
    {
        if (n >= 0 && n < FArray[FCurrInd]->FObjArrayCount)
           return FArray[FCurrInd]->FObjArr[n];
        else
            return 0;
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::GetObj
#
#   Purpose....: Get an object with a given name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonArrayCollection::GetObj(const char *FieldName)
{
    int n;
    TJsonObject *obj;

    if (FReqAdd)
    {
        FCurrInd = 0;
        FReqAdd = false;
    }

    if (FArray)
    {
        for (n = 0; n < FArray[FCurrInd]->FObjArrayCount; n++)
        {
            obj = FArray[FCurrInd]->FObjArr[n];
            if (!obj->IsCollection())
                if (!strcmp(obj->GetFieldName(), FieldName))
                    return obj;
        }
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::GetCollection
#
#   Purpose....: Get a collection with a given name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection *TJsonArrayCollection::GetCollection(const char *FieldName)
{
    int n;
    TJsonObject *obj;

    if (FReqAdd)
    {
        FCurrInd = 0;
        FReqAdd = false;
    }

    if (FArray)
    {
        for (n = 0; n < FArray[FCurrInd]->FObjArrayCount; n++)
        {
            obj = FArray[FCurrInd]->FObjArr[n];
            if (obj->IsCollection())
                if (!strcmp(obj->GetFieldName(), FieldName))
                    return (TJsonCollection *)obj;
        }
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TJsonArrayCollection::GetArrayCount
#
#   Purpose....: Get array count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TJsonArrayCollection::GetArrayCount()
{
    return FArrayCount;
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
TJsonInt::TJsonInt(const char *FieldName, TJsonAlloc *Alloc, long long v)
 : TJsonObject(FieldName, Alloc)
{
    SetValue(v);
}

/*##########################################################################
#
#   Name       : TJsonInt::TJsonInt
#
#   Purpose....: Copy constructor for TJsonInt
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonInt::TJsonInt(const TJsonInt &src, TJsonAlloc *Alloc)
 : TJsonObject(src, Alloc)
{
    Val = src.Val;
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
#   Name       : TJsonInt::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonInt::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonInt(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonInt::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonInt *TJsonInt::Clone(TJsonAlloc *Alloc)
{
    return (TJsonInt *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonInt::SetValue
#
#   Purpose....: Set value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonInt::SetValue(long long v)
{
    Val = v;
    CodeInt(v);
}

/*##########################################################################
#
#   Name       : TJsonInt::GetBaseBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonInt::GetBaseBoolean()
{
    if (Val == 0)
        return false;
    else
        return true;
}

/*##########################################################################
#
#   Name       : TJsonInt::GetBaseInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonInt::GetBaseInt()
{
    return Val;
}

/*##########################################################################
#
#   Name       : TJsonInt::GetBaseDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonInt::GetBaseDouble()
{
    return (double)Val;
}

/*##########################################################################
#
#   Name       : TJsonInt::GetBaseDateTime
#
#   Purpose....: Get date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TJsonInt::GetBaseDateTime()
{
    TDateTime time;

    if (Val > 5000000000)
        time.SetLinuxMilliTimestamp(Val);
    else
        time.SetLinuxTimestamp(Val);

    return time;
}

/*##########################################################################
#
#   Name       : TJsonInt::SetBaseBoolean
#
#   Purpose....: Set boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonInt::SetBaseBoolean(bool v)
{
    if (v)
        SetValue(1);
    else
        SetValue(0);
}

/*##########################################################################
#
#   Name       : TJsonInt::SetBaseInt
#
#   Purpose....: Set int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonInt::SetBaseInt(long long v)
{
    SetValue(v);
}

/*##########################################################################
#
#   Name       : TJsonInt::SetBaseDouble
#
#   Purpose....: Set double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonInt::SetBaseDouble(double v, int decimals)
{
    SetValue((long long)v);
}

/*##########################################################################
#
#   Name       : TJsonInt::SetBaseDateTime
#
#   Purpose....: Set date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonInt::SetBaseDateTime(TDateTime &v)
{
    SetValue(v.GetLinuxMilliTimestamp());
}

/*##########################################################################
#
#   Name       : TJsonInt::SetBaseDateTimeZone
#
#   Purpose....: Set date & time with timezone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonInt::SetBaseDateTimeZone(TDateTime &v, int diff)
{
    SetValue(v.GetLinuxMilliTimestamp());
}

/*##########################################################################
#
#   Name       : TJsonInt::SetBaseString
#
#   Purpose....: Set string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonInt::SetBaseString(const char *Str)
{
    TJsonObject::SetBaseString(Str);
    Val = DecodeInt();
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
TJsonDouble::TJsonDouble(const char *FieldName, TJsonAlloc *Alloc, double v, const char *text)
 : TJsonObject(FieldName, Alloc)
{
    TJsonObject::SetBaseString(text);
    Val = v;
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
TJsonDouble::TJsonDouble(const char *FieldName, TJsonAlloc *Alloc, double v, int decimals)
 : TJsonObject(FieldName, Alloc)
{
    SetValue(v, decimals);
}

/*##########################################################################
#
#   Name       : TJsonDouble::TJsonDouble
#
#   Purpose....: Copy constructor for TJsonDouble
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDouble::TJsonDouble(const TJsonDouble &src, TJsonAlloc *Alloc)
 : TJsonObject(src, Alloc)
{
    Val = src.Val;
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
#   Name       : TJsonDouble::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonDouble::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonDouble(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonDouble::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonDouble *TJsonDouble::Clone(TJsonAlloc *Alloc)
{
    return (TJsonDouble *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonDouble::SetValue
#
#   Purpose....: Set value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDouble::SetValue(double v, int decimals)
{
    Val = v;
    CodeDouble(v, decimals);
}

/*##########################################################################
#
#   Name       : TJsonDouble::GetBaseBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonDouble::GetBaseBoolean()
{
    if (Val > 0)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TJsonDouble::GetBaseInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonDouble::GetBaseInt()
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
#   Name       : TJsonDouble::GetBaseDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonDouble::GetBaseDouble()
{
    return Val;
}

/*##########################################################################
#
#   Name       : TJsonDouble::GetBaseDateTime
#
#   Purpose....: Get date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TJsonDouble::GetBaseDateTime()
{
    TDateTime time((long double)Val);
    return time;
}

/*##########################################################################
#
#   Name       : TJsonDouble::SetBaseBoolean
#
#   Purpose....: Set boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDouble::SetBaseBoolean(bool v)
{
    if (v)
        SetValue(1, 0);
    else
        SetValue(0, 0);
}

/*##########################################################################
#
#   Name       : TJsonDouble::SetBaseInt
#
#   Purpose....: Set int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDouble::SetBaseInt(long long v)
{
    SetValue((double)v, 0);
}

/*##########################################################################
#
#   Name       : TJsonDouble::SetBaseDouble
#
#   Purpose....: Set double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDouble::SetBaseDouble(double v, int decimals)
{
    SetValue(v, decimals);
}

/*##########################################################################
#
#   Name       : TJsonDouble::SetBaseDateTime
#
#   Purpose....: Set date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDouble::SetBaseDateTime(TDateTime &v)
{
    SetValue((double)v, 0);
}

/*##########################################################################
#
#   Name       : TJsonDouble::SetBaseDateTimeZone
#
#   Purpose....: Set date & time with timezone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDouble::SetBaseDateTimeZone(TDateTime &v, int diff)
{
    SetValue((double)v, 0);
}

/*##########################################################################
#
#   Name       : TJsonDouble::SetBaseString
#
#   Purpose....: Set string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDouble::SetBaseString(const char *Str)
{
    TJsonObject::SetBaseString(Str);
    Val = DecodeDouble();
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
TJsonBoolean::TJsonBoolean(const char *FieldName, TJsonAlloc *Alloc, bool v)
 : TJsonObject(FieldName, Alloc)
{
    SetValue(v);
}

/*##########################################################################
#
#   Name       : TJsonBoolean::TJsonBoolean
#
#   Purpose....: Copy constructor for TJsonBoolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBoolean::TJsonBoolean(const TJsonBoolean &src, TJsonAlloc *Alloc)
 : TJsonObject(src, Alloc)
{
    Val = src.Val;
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
#   Name       : TJsonBoolean::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonBoolean::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonBoolean(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonBoolean::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonBoolean *TJsonBoolean::Clone(TJsonAlloc *Alloc)
{
    return (TJsonBoolean *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonBoolean::SetValue
#
#   Purpose....: Set value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBoolean::SetValue(bool v)
{
    Val = v;
    CodeBoolean(v);
}

/*##########################################################################
#
#   Name       : TJsonBoolean::GetBaseBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonBoolean::GetBaseBoolean()
{
    return Val;
}

/*##########################################################################
#
#   Name       : TJsonBoolean::GetBaseInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonBoolean::GetBaseInt()
{
    if (Val)
        return 1;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TJsonBoolean::GetBaseDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonBoolean::GetBaseDouble()
{
    if (Val)
        return 1.0;
    else
        return 0.0;
}

/*##########################################################################
#
#   Name       : TJsonBoolean::GetBaseDateTime
#
#   Purpose....: Get date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TJsonBoolean::GetBaseDateTime()
{
    TDateTime time;
    return time;
}

/*##########################################################################
#
#   Name       : TJsonBoolean::SetBaseBoolean
#
#   Purpose....: Set boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBoolean::SetBaseBoolean(bool v)
{
    SetValue(v);
}

/*##########################################################################
#
#   Name       : TJsonBoolean::SetBaseInt
#
#   Purpose....: Set int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBoolean::SetBaseInt(long long v)
{
    if (v)
        SetValue(true);
    else
        SetValue(false);
}

/*##########################################################################
#
#   Name       : TJsonBoolean::SetBaseDouble
#
#   Purpose....: Set double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBoolean::SetBaseDouble(double v, int decimals)
{
    if (v <= 0.0)
        SetValue(false);
    else
        SetValue(true);
}

/*##########################################################################
#
#   Name       : TJsonBoolean::SetBaseDateTime
#
#   Purpose....: Set date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBoolean::SetBaseDateTime(TDateTime &v)
{
    if (v.HasExpired())
        SetValue(true);
    else
        SetValue(false);
}

/*##########################################################################
#
#   Name       : TJsonBoolean::SetBaseDateTimeZone
#
#   Purpose....: Set date & time with timezone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBoolean::SetBaseDateTimeZone(TDateTime &v, int diff)
{
    if (v.HasExpired())
        SetValue(true);
    else
        SetValue(false);
}

/*##########################################################################
#
#   Name       : TJsonBoolean::SetBaseString
#
#   Purpose....: Set string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonBoolean::SetBaseString(const char *Str)
{
    TJsonObject::SetBaseString(Str);
    Val = DecodeBoolean();
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
TJsonString::TJsonString(const char *FieldName, TJsonAlloc *Alloc, const char *text)
 : TJsonObject(FieldName, Alloc)
{
    TJsonObject::SetBaseString(text);
}

/*##########################################################################
#
#   Name       : TJsonString:TJsonString
#
#   Purpose....: Copy constructor for TJsonString
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonString::TJsonString(const TJsonString &src, TJsonAlloc *Alloc)
 : TJsonObject(src, Alloc)
{
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
#   Name       : TJsonString::CloneObj
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonObject *TJsonString::CloneObj(TJsonAlloc *Alloc)
{
    TJsonObject *obj = new(Alloc) TJsonString(*this, Alloc);
    return obj;
}

/*##########################################################################
#
#   Name       : TJsonString::Clone
#
#   Purpose....: Clone object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonString *TJsonString::Clone(TJsonAlloc *Alloc)
{
    return (TJsonString *)CloneObj(Alloc);
}

/*##########################################################################
#
#   Name       : TJsonString::GetBaseBoolean
#
#   Purpose....: Get boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TJsonString::GetBaseBoolean()
{
    return DecodeBoolean();
}

/*##########################################################################
#
#   Name       : TJsonString::GetBaseInt
#
#   Purpose....: Get int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long long TJsonString::GetBaseInt()
{
    return DecodeInt();
}

/*##########################################################################
#
#   Name       : TJsonString::GetBaseDouble
#
#   Purpose....: Get double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TJsonString::GetBaseDouble()
{
    return DecodeDouble();
}

/*##########################################################################
#
#   Name       : TJsonString::GetBaseDateTime
#
#   Purpose....: Get date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TJsonString::GetBaseDateTime()
{
    return DecodeDateTime();
}

/*##########################################################################
#
#   Name       : TJsonString::SetBaseBoolean
#
#   Purpose....: Set boolean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonString::SetBaseBoolean(bool v)
{
    CodeBoolean(v);
}

/*##########################################################################
#
#   Name       : TJsonString::SetBaseInt
#
#   Purpose....: Set int
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonString::SetBaseInt(long long v)
{
    CodeInt(v);
}

/*##########################################################################
#
#   Name       : TJsonString::SetBaseDouble
#
#   Purpose....: Set double
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonString::SetBaseDouble(double v, int decimals)
{
    CodeDouble(v, decimals);
}

/*##########################################################################
#
#   Name       : TJsonString::SetBaseDateTime
#
#   Purpose....: Set date & time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonString::SetBaseDateTime(TDateTime &v)
{
    CodeDateTime(v);
}

/*##########################################################################
#
#   Name       : TJsonString::SetBaseDateTimeZone
#
#   Purpose....: Set date & time with time zone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonString::SetBaseDateTimeZone(TDateTime &v, int diff)
{
    CodeDateTimeZone(v, diff);
}

/*##########################################################################
#
#   Name       : TJsonString::Write
#
#   Purpose....: Write object data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonString::Write(TJsonDocument *doc, int indent, TString &str)
{
    TJsonFormString EscStr(FText);

    AddIndent(doc, indent, str);
    str += "\"";
    str += FFieldName;
    str += "\": \"";
    str += EscStr;
    str += "\"";
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
            doc->StartArray();

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
        case ',':
        case '.':
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

    for (;;)
    {
        if(*FDataPtr == FQuoteChar)
        {
            FData.Append(case_start, FDataPtr - case_start);
            doc->AddString(FData.GetData());

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

    doc->AddDouble(val, FData.GetData());

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

    if (FData.GetSize())
    {
        if (FData[0] == '-')
        {
            if (case_len <= 1 && (*FDataPtr == 'i' || *FDataPtr == 'I'))
            {
                FState = json_tokener_state_inf;
                return json_ret_redo;
            }
            else if (FData.GetSize() == 1)
            {
                doc->AddInt(0);

                FSavedState = json_tokener_state_finish;
                FState = json_tokener_state_eatws;
                return json_ret_redo;
            }
        }

        if (FIsDouble)
            return DecodeDouble(doc);
        else
            return DecodeInt(doc);
    }
    else
    {
        doc->AddInt(0);

        FSavedState = json_tokener_state_finish;
        FState = json_tokener_state_eatws;
        return json_ret_redo;
    }
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
            if (!doc->IsArrayData())
                doc->EndNesting();

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
            doc->SetFieldName(FData.GetData());

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
    Reset();
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

    FRootCollection = 0;
    FCurrCollection = 0;
}

/*##########################################################################
#
#   Name       : TJsonDocument::Reset
#
#   Purpose....: Reset document
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::Reset()
{
    int level;

    for (level = 0; level < MAX_JSON_DEPTH; level++)
    {
        if (StackArr[level])
            delete StackArr[level];
        StackArr[level] = 0;
    }

    FRootCollection = 0;
    FCurrCollection = 0;

    FAlloc.Reset();
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
void TJsonDocument::SetFieldName(const char *str)
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
    TJsonSingleCollection *c;

    if (FCurrCollection)
    {
        c = new(&FAlloc) TJsonSingleCollection(FObjFieldName.GetData(), &FAlloc);
        FCurrCollection->Insert(c);
        c->FParent = FCurrCollection;
        FCurrCollection = c;
    }
    else
    {
        if (!FRootCollection)
        {
            c = new(&FAlloc) TJsonSingleCollection(FObjFieldName.GetData(), &FAlloc);
            FRootCollection = c;
        }
        FCurrCollection = c;
    }
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
    if (FCurrCollection)
        FCurrCollection = FCurrCollection->FParent;
}

/*##########################################################################
#
#   Name       : TJsonDocument::StartArray
#
#   Purpose....: Start array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::StartArray()
{
    TJsonArrayCollection *c;

    if (FCurrCollection)
    {
        c = new(&FAlloc) TJsonArrayCollection(FObjFieldName.GetData(), &FAlloc);
        FCurrCollection->Insert(c);
        c->FParent = FCurrCollection;
        FCurrCollection = c;
    }
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
    TJsonArrayCollection *arr;

    if (FCurrCollection && FCurrCollection->IsArray())
    {
        arr = (TJsonArrayCollection *)FCurrCollection;
        arr->AddArray();
    }
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
void TJsonDocument::AddString(const char *str)
{
    TJsonString *obj;

    if (FCurrCollection)
    {
        obj = new(&FAlloc) TJsonString(FObjFieldName.GetData(), &FAlloc, str);
        FCurrCollection->Insert(obj);
    }
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
    TJsonInt *obj;

    if (FCurrCollection)
    {
        obj = new(&FAlloc) TJsonInt(FObjFieldName.GetData(), &FAlloc, val);
        FCurrCollection->Insert(obj);

        long long v = obj->GetInt();
    }
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
void TJsonDocument::AddDouble(double val, const char *text)
{
    TJsonDouble *obj;

    if (FCurrCollection)
    {
        obj = new(&FAlloc) TJsonDouble(FObjFieldName.GetData(), &FAlloc, val, text);
        FCurrCollection->Insert(obj);
    }
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
    TJsonDouble *obj;

    if (FCurrCollection)
    {
        obj = new(&FAlloc) TJsonDouble(FObjFieldName.GetData(), &FAlloc, val, decimals);
        FCurrCollection->Insert(obj);
    }
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
    TJsonBoolean *obj;

    if (FCurrCollection)
    {
        obj = new(&FAlloc) TJsonBoolean(FObjFieldName.GetData(), &FAlloc, val);
        FCurrCollection->Insert(obj);
    }
}

/*##########################################################################
#
#   Name       : TJsonDocument::CreateRoot
#
#   Purpose....: Create root collection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection *TJsonDocument::CreateRoot()
{
    if (!FRootCollection)
        FRootCollection = new(&FAlloc) TJsonSingleCollection("", &FAlloc);

    return FRootCollection;
}

/*##########################################################################
#
#   Name       : TJsonDocument::GetRoot
#
#   Purpose....: Get root collection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonCollection *TJsonDocument::GetRoot()
{
    return FRootCollection;
}

/*##########################################################################
#
#   Name       : TJsonDocument::GetAlloc
#
#   Purpose....: Get allocator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonAlloc *TJsonDocument::GetAlloc()
{
    return &FAlloc;
}

/*##########################################################################
#
#   Name       : TJsonDocument::Write
#
#   Purpose....: Write document
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::Write(TString &str)
{
    FCompact = false;

    if (FRootCollection)
    {
        FRootCollection->Write(this, 0, str);
        NewLine(str);
    }
}

/*##########################################################################
#
#   Name       : TJsonDocument::WriteCompact
#
#   Purpose....: Write document without newlines & indentions
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::WriteCompact(TString &str)
{
    FCompact = true;

    if (FRootCollection)
    {
        FRootCollection->Write(this, 0, str);
    }
}

/*##########################################################################
#
#   Name       : TJsonDocument::NewLine
#
#   Purpose....: New line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::NewLine(TString &str)
{
    if (!FCompact)
        str += "\r\n";
}

/*##########################################################################
#
#   Name       : TJsonDocument::AddIndent
#
#   Purpose....: Add indent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TJsonDocument::AddIndent(int indent, TString &str)
{
    int i;

    if (!FCompact)
        for (i = 0; i < indent; i++)
            str += "  ";
}

/*##########################################################################
#
#   Name       : TJsonHttpClient::TJsonHttpClient
#
#   Purpose....: Http client contructor using host
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TJsonHttpClient::TJsonHttpClient(const char *host)
  : FHost(host)
{
    FSocket = 0;
}
