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
# ini.h
# Ini-file class
#
########################################################################*/

#ifndef APP_INI_H
#define APP_INI_H

#include "str.h"

class TAppIniVar
{
    friend class TAppIniSection;
    friend class TAppIniFile;
public:
    TAppIniVar(const char *Name, const char *Val);
    ~TAppIniVar();

    bool IsMatch(const char *Name);
    const char *GetName();
    const char *GetData();
    void SetData(const char *Val);

    int GetSize();
    char *Format(char *buf);

protected:
    TString FName;
    TString FVal;
    TAppIniVar *FNextVar;
};

class TAppIniSection
{
    friend class TAppIniFile;
public:
    TAppIniSection(const char *Name);
    ~TAppIniSection();

    bool IsMatch(const char *Name);

    int GetSize();
    char *Format(char *buf);

    TAppIniVar *FindVar(const char *Name);
    void AddVar(const char *Name, const char *Val);
    bool DeleteVar(const char *name);

protected:
    void ClearVars();
    bool CheckDelim(char ch);
    char *Trim(char *str);
    char *FindStartOfLine(char *ptr);
    void DecodeLine(char *ptr);
    void Parse(char *ptr);

    TString FName;
    TAppIniVar *FCurrVar;
    TAppIniVar *FVarList;
    TAppIniSection *FNextSection;
};

class TAppIniFile
{
public:
    TAppIniFile(const char *IniName);
    TAppIniFile(const TAppIniFile &ini);
    ~TAppIniFile();

    bool GotoSection(const char *name);
    bool DeleteSection(const char *name);

    bool ReadVar(const char *var, char *str, int maxsize);
    bool WriteVar(const char *var, const char *str);
    bool DeleteVar(const char *var);

    bool GotoFirstVar();
    bool GotoNextVar();
    bool GetCurrVar(char *var, int maxsize);

    void Update();

protected:
    void ClearSections();
    TAppIniSection *FindSection(const char *Name);
    TAppIniSection *AddSection(const char *Name);

    char *FindSectionStart(char *ptr);
    void DecodeSection(char *ptr);
    void Parse(char *ptr);

    TString FName;
    TString FSection;
    bool FModified;
    TAppIniSection *FSectionList;
    TAppIniSection *FCurrSection;
    TAppIniVar *FCurrVar;
};

#endif
