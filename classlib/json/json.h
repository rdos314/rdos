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
# json.h
# json class
#
########################################################################*/

#ifndef _JSON_H
#define _JSON_H

#define MAX_JSON_DEPTH	100

class TJsonPrintBuf 
{
public:
    TJsonPrintBuf();
    ~TJsonPrintBuf();

    void Reset();

    void Extend(int min_size);
    void MemAppend(const char *buf, int size);
    void Memset(int offset, int charvalue, int len);

    int printf(const char *fmt, va_list args);
    int printf(const char *fmt, ...);

    char *FBuf;
    int FBpos;
    int FSize;
};

class TJsonObject
{
public:
    TJsonObject();
    ~TJsonObject();

    int o_type;
    int _ref_count;
    TJsonPrintBuf *pb;
    bool c_boolean;
    long long c_int64;
    char *str;
    int len;
};

class TJsonArray : public TJsonObject
{
public:
    TJsonArray();
    ~TJsonArray();
};

class TJsonDouble : public TJsonObject
{
public:
    TJsonDouble();
    ~TJsonDouble();

    void SetPosInfinite();
    void SetNegInfinite();

    double Val;
};

class TJsonDocument;

class TJsonStackEntry
{
friend class TJsonDocument;

public:
    TJsonStackEntry(TJsonObject *object);
    ~TJsonStackEntry();

    bool AddLevel(TJsonDocument *doc, TJsonObject *object);
    void DeleteLevel(TJsonDocument *doc);
    bool Parse(TJsonDocument *doc);

protected:
    int HandleEatWs(TJsonDocument *doc);
    int HandleStart(TJsonDocument *doc);
    int HandleFinish(TJsonDocument *doc);
    int HandleInfinite(TJsonDocument *doc);

    int state;
    int saved_state;

    TJsonPrintBuf *pb;
    TJsonObject *obj;
    char *obj_field_name;
};

class TJsonDocument
{
friend class TJsonStackEntry;

public:
    TJsonDocument();
    TJsonDocument(const char *doc);
    ~TJsonDocument();

protected:
    bool PeekChar(TJsonStackEntry *entry);
    bool AdvanceChar();
    bool AddLevel(TJsonObject *object);
    void DeleteLevel();

private:
    char *str;
    int len;

    int char_offset;
    int depth;
    int err;
    int st_pos;
    unsigned int ucs_char;
    char quote_char;
    int is_double;
    int flags;

    TJsonStackEntry *StackArr[MAX_JSON_DEPTH];
};

#endif
