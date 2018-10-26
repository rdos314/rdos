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

    void Extend(int min_size);
    void MemAppend(const char *buf, int size);
    void Memset(int offset, int charvalue, int len);

    char *FBuf;
    int FBpos;
    int FSize;
};

class TJsonTokenList
{
public:
    TJsonTokenList();
    ~TJsonTokenList();

    int state;
    int saved_state;
//    struct json_object *obj;
//    struct json_object *current;
    char *obj_field_name;
};

class TJsonDocument
{
public:
    TJsonDocument();
    TJsonDocument(const char *doc);
    ~TJsonDocument();

private:
    int state;
    int saved_state;

    char *str;
    TJsonPrintBuf *pb;
    int max_depth;
    int depth;
    int is_double;
    int st_pos;
    int char_offset;
    int err;
    unsigned int ucs_char;
    char quote_char;
    TJsonTokenList *stack;
    int flags;
};

#endif
