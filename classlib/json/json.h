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
    double c_double;
    long long c_int64;
//    struct lh_table *c_object;
//    struct array_list *c_array;
    char *str;
    int len;
};

class TJsonArray : public TJsonObject
{
public:
    TJsonArray();
    ~TJsonArray();
};

class TJsonDocument;

class TJsonTokenList
{
friend class TJsonDocument;

public:
    TJsonTokenList();
    ~TJsonTokenList();

    int HandleEatWs(TJsonDocument *doc);
    int HandleStart(TJsonDocument *doc);

protected:
    TJsonPrintBuf pb;
    TJsonObject *obj;
    TJsonObject *current;
    TJsonTokenList *stack;
    char *obj_field_name;

    int char_offset;
    int depth;
    int err;
    int st_pos;
    unsigned int ucs_char;
    char quote_char;
    int max_depth;
    int is_double;
    int flags;
};

class TJsonDocument
{
friend class TJsonTokenList;

public:
    TJsonDocument();
    TJsonDocument(const char *doc);
    ~TJsonDocument();

protected:
    bool PeekChar(TJsonTokenList *token);
    bool AdvanceChar(TJsonTokenList *token);

private:
    char *str;
    int len;

    int state;
    int saved_state;
};

#endif
