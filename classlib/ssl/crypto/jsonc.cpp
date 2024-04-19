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
# jsonc.cpp
# json C class
#
########################################################################*/

#include <memory.h>
#include <time.h>

#include "json.h"
#include "str.h"
#include "datetime.h"

#define JSON_DOC void
#define JSON_COLL void
#define JSON_STR_ARR void

extern "C" {
#include "jsonc.h"
}

JSON_DOC *CreateJson()
{
    TJsonDocument *json = new TJsonDocument;
    return (JSON_DOC *)json;
}

void DeleteJson(JSON_DOC *doc)
{
    TJsonDocument *json = (TJsonDocument *)doc;

    if (json)
        delete json;
}

JSON_COLL *GetJsonRoot(JSON_DOC *doc)
{
    TJsonDocument *json = (TJsonDocument *)doc;
    TJsonCollection *root = json->GetRoot();

    if (!root)
        root = json->CreateRoot();

    return (JSON_COLL *)root;
}

JSON_COLL *AddJsonColl(JSON_COLL *c, const char *field)
{
    TJsonCollection *cb = (TJsonCollection *)c;
    TJsonCollection *coll;

    coll = cb->GetCollection(field);

    if (!coll)
        coll = cb->AddCollection(field);

    return (JSON_COLL *)coll;
}

void AddJsonInt(JSON_COLL *c, const char *field, long long val)
{
    TJsonCollection *coll = (TJsonCollection *)c;
    coll->AddInt(field, val);
}

void AddJsonString(JSON_COLL *c, const char *field, const char *val)
{
    TJsonCollection *coll = (TJsonCollection *)c;
    coll->AddString(field, val);
}

void AddJsonTime(JSON_COLL *c, const char *field, struct tm *ts)
{
    TJsonCollection *coll = (TJsonCollection *)c;
    TDateTime time(ts->tm_year + 1900, ts->tm_mon + 1, ts->tm_mday, ts->tm_hour, ts->tm_min, ts->tm_sec);
    coll->AddDateTime(field, time, 1);
}

JSON_STR_ARR *AddJsonStringArray(JSON_COLL *c, const char *field)
{
    TJsonCollection *coll = (TJsonCollection *)c;
    TJsonStringArray *arr = coll->AddStringArray(field);

    return (JSON_STR_ARR *)arr;
}

const char *GetJsonStringArrayName(JSON_STR_ARR *a)
{
    TJsonStringArray *arr = (TJsonStringArray *)a;
    return arr->GetFieldName();
}

void AddJsonStringArrayData(JSON_STR_ARR *a, const char *val)
{
    TJsonStringArray *arr = (TJsonStringArray *)a;
    arr->Add(val);
}

int GetJsonText(JSON_DOC *doc, char *buf, int maxsize)
{
    TString str;
    int size = 0;
    TJsonDocument *json = (TJsonDocument *)doc;

    if (maxsize)
    {
        json->Write(str);

        size = str.GetSize() + 1;

        if (size > maxsize)
            size = maxsize;

        size--;

        memcpy(buf, str.GetData(), size);
        buf[size] = 0;
    }

    return size;
}
