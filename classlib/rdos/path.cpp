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
# path.cpp
# Directory class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include "path.h"
#include "rdos.h"
#include "file.h"
#include "direntry.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName()
{
    char *str;
    int drive;

    str = new char[512];

    drive = RdosGetCurDrive();
    str[0] = drive + 'a';
    str[1] = ':';
    str[2] = '\\';
    str[3] = 0;
    RdosGetCurDir(drive, str + 3);

    if (str[3] == '\\')
        str[3] = 0;

    FPathName = str;

    delete str;
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(int Drive)
{
    char *str;

    str = new char[512];

    str[0] = Drive + 'a';
    str[1] = ':';
    str[2] = '\\';
    str[3] = 0;
    RdosGetCurDir(Drive, str + 3);

    if (str[3] == '\\')
        str[3] = 0;

    FPathName = str;

    delete str;
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(const char *PathName)
{
    Init(PathName);
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(const TString &PathName)
{
    Init(PathName.GetData());
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(int Drive, const TString &PathName)
{
    char str[4];

    str[0] = (char)Drive + 'a';
    str[1] = ':';
    str[2] = 0;

    FPathName = str;
    FPathName += PathName;
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(int Drive, const TString &DirName, const TString &EntryName)
{
    char str[4];

    str[0] = (char)Drive + 'a';
    str[1] = ':';
    str[2] = 0;

    FPathName = str;
    FPathName += DirName;
    FPathName += "/";
    FPathName += EntryName;
}

/*##########################################################################
#
#   Name       : TPathName::TPathName
#
#   Purpose....: Copy constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::TPathName(const TPathName &PathName)
  : FPathName(PathName.FPathName)
{
}

/*##########################################################################
#
#   Name       : TPathName::~TPathName
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName::~TPathName()
{
}

/*##########################################################################
#
#   Name       : TPathName::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPathName::Init(const char *PathName)
{
    char *str;
    int drive;

    if (strlen(PathName) == 1 && PathName[0] == '.')
    {
        str = new char[512];

        drive = RdosGetCurDrive();
        str[0] = drive + 'a';
        str[1] = ':';
        str[2] = '\\';
        str[3] = 0;
        RdosGetCurDir(drive, str + 3);

        if (str[3] == '\\')
            str[3] = 0;

        FPathName = str;

        delete str;

        return;
    }

    if (strlen(PathName) == 2 && PathName[1] == ':')
    {
        str = new char[512];

        drive = PathName[0];
        drive = toupper(drive) - 'A';
        
        str[0] = PathName[0];
        str[1] = ':';
        str[2] = '\\';
        str[3] = 0;
        RdosGetCurDir(drive, str + 3);

        if (str[3] == '\\')
            str[3] = 0;

        FPathName = str;

        delete str;

        return;
    }

    if (strlen(PathName) == 3 && PathName[1] == ':' && PathName[2] == '.')
    {
        str = new char[512];

        drive = PathName[0];
        drive = toupper(drive) - 'A';
        str[0] = PathName[0];
        str[1] = ':';
        str[2] = '\\';
        str[3] = 0;
        RdosGetCurDir(drive, str + 3);

        if (str[3] == '\\')
            str[3] = 0;

        FPathName = str;

        delete str;

        return;
    }

    FPathName = PathName;
}

/*##########################################################################
#
#   Name       : TPathName::operator=
#
#   Purpose....: Assignment 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TPathName::operator=(const TPathName &src)
{
    FPathName = src.FPathName;
    return *this;
}

/*##########################################################################
#
#   Name       : TPathName::operator=
#
#   Purpose....: Assignment 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TPathName::operator=(const TString &src)
{
    FPathName = src;
    return *this;
}

/*##########################################################################
#
#   Name       : TPathName::operator+=
#
#   Purpose....: Assignment addition 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TPathName::operator+=(const TString &str)
{
    const char *path;
    const char *ptr;
    int pos;

    path = FPathName.GetData();
    ptr = str.GetData();

    while (*ptr == '\\' || *ptr == '/')
        ptr++;

    if (!strcmp(path, "."))
        FPathName = str;
    else
    {
        pos = strlen(path);
        if (pos)
            pos--;

        switch (path[pos])
        {
            case '\\':
            case '/':
                FPathName += ptr;
                break;
    
            default:
                if (*path && *ptr != '.')
                    FPathName += "\\" + TString(ptr);
                else
                    FPathName += ptr;
                break;
        }   
    }
    return *this;
}

/*##########################################################################
#
#   Name       : TPathName::operator+=
#
#   Purpose....: Assignment addition 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TPathName &TPathName::operator+=(const char *str)
{
    const char *path;
    int pos;

    path = FPathName.GetData();

    while (*str == '\\' || *str == '/')
        str++;

    if (!strcmp(path, "."))
        FPathName = TString(str);
    else
    {

        pos = strlen(path);
        if (pos)
            pos--;

        switch (path[pos])
        {
            case '\\':
            case '/':
                FPathName += TString(str);
                break;

            default:
                if (*path && *str != '.')
                    FPathName += "\\" + TString(str);
                else
                    FPathName += TString(str);
                break;
        }   
    }
    return *this;
}

/*##########################################################################
#
#   Name       : operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: path
#                str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName operator+(const TPathName& path, const TString& str)
{
    TPathName p(path);
    p += str;
    return p;
}

/*##########################################################################
#
#   Name       : operator+
#
#   Purpose....: Concatenation operator
#
#   In params..: path
#                str
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName operator+(const TPathName& path, const char *str)
{
    TPathName p(path);
    p += str;
    return p;
}

/*##########################################################################
#
#   Name       : TPathName::Get
#
#   Purpose....: Get path
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TPathName::Get() const
{
    return FPathName;
}

/*##########################################################################
#
#   Name       : TPathName::HasDrive
#
#   Purpose....: Check if pathname specifies drive
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::HasDrive() const
{
    int size;
    const char *str;

    size = FPathName.GetSize();
    if (size >= 2)
    {
        str = FPathName.GetData();
        if (str[1] == ':')
            return TRUE;
        else
            return FALSE;
    }           
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TPathName::HasFullPath
#
#   Purpose....: Check if pathname starts at root
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::HasFullPath() const
{
    int size;
    const char *str;

    size = FPathName.GetSize();

    if (size >= 2)
    {
        str = FPathName.GetData();
        if (str[1] == ':')
        {
            if (size >= 3)
                if (str[2] == '\\')
                    return TRUE;
        }
        else
            if (str[0] == '\\')
                return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TPathName::GetDrive
#
#   Purpose....: Get drive of pathname
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::GetDrive() const
{
    int size;
    const char *str;

    size = FPathName.GetSize();
    if (size >= 2)
    {
        str = FPathName.GetData();
        if (str[1] == ':')
            if (isalpha(*str))
                return tolower(*str) - 'a';         
    }
    return RdosGetCurDrive();
}

/*##########################################################################
#
#   Name       : TPathName::GetBaseName
#
#   Purpose....: Get base path name. Strips last component. Returns empty
#                string if no path separator is found
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TPathName::GetBaseName() const
{
    TString s;
    char *newstr;
    const char *str;
    const char *ptr;
    int size;
    char ch;
    
    size = FPathName.GetSize();
    str = FPathName.GetData();
    ptr = str;

    if (size > 2)
        if (*(str+1) == ':' && isalpha(*str))
        {
            str += 2;
            size -= 2;
        }

    while (size)
    {
        size--;
        ch = *(str + size);
        if (ch == '\\' || ch == '/')
            break;
    }

    if (size == 0)
    {
        ch = *str;
        if (ch == '\\' || ch == '/')
            size++;
    }

    size += str - ptr;
    newstr = new char[size + 1];
    memcpy(newstr, ptr, size);
    *(newstr + size) = 0;
    s = newstr;
    delete newstr;

    return s;
}

/*##########################################################################
#
#   Name       : TPathName::GetEntryName
#
#   Purpose....: Get entry path name. Strips path component.
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TPathName::GetEntryName() const
{
    const char *str;
    int size;
    char ch;

    size = FPathName.GetSize();
    str = FPathName.GetData();

    if (size > 2)
        if (*(str+1) == ':' && isalpha(*str))
        {
            str += 2;
            size -= 2;
        }

    size--;
    str += size;
    while (size)
    {
        size--;
        ch = *str;
        if (ch == '\\' || ch == '/')
        {
            str++;
            break;
        }
        else
            str--;
    }

    ch = *str;
    if (ch == '\\' || ch == '/')
        str++;

    return TString(str);
}

/*##########################################################################
#
#   Name       : TPathName::GetFullPathName
#
#   Purpose....: Get full path name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TPathName::GetFullPathName() const
{
    TString s;
    const char *str;
    char *path;
    int drive;
    char drive_str[3];
    int size;
    int add;
    
    size = FPathName.GetSize();

    if (size <= 2)
        add = TRUE;
    else
    {
        str = FPathName.GetData();
        if (*(str+1) == ':' && isalpha(*str))
            add = FALSE;
        else
            add = TRUE;
    }       

    if (add)
    {
        drive_str[0] = (char)RdosGetCurDrive() + 'a';
        drive_str[1] = ':';
        drive_str[2] = 0;
        s = drive_str + FPathName;
    }
    else
        s = FPathName;

    size = s.GetSize();

    if (size <= 2)
        add = TRUE;
    else
    {
        str = s.GetData();
        if (*(str+2) == '\\')
            add = FALSE;
        else
            add = TRUE;
    }

    if (add)
    {
        str = s.GetData();
        memcpy(drive_str, str, 2);
        drive_str[2] = 0;
        drive_str[0] = tolower(drive_str[0]);
        str += 2;

        path = new char[0x200];
        drive = drive_str[0] - 'a';
        RdosGetCurDir(drive, path);
        if (*str)
            s = TString(drive_str) + "\\" + path + "\\" + str;
        else
            s = TString(drive_str) + "\\" + path;
        delete path;
    }
    return s;
}

/*##########################################################################
#
#   Name       : TPathName::GetAttribute
#
#   Purpose....: Get file attribute
#
#   In params..: *
#   Out params.: *
#   Returns....: attribute
#
##########################################################################*/
int TPathName::GetAttribute() const
{
    int attrib;

    if (RdosGetFileAttribute(FPathName.GetData(), &attrib))
        return attrib;
    else
        return -1;
}

/*##########################################################################
#
#   Name       : TPathName::SetAttribute
#
#   Purpose....: Set file attribute
#
#   In params..: attribute
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::SetAttribute(int Attribute) const
{
    return RdosSetFileAttribute(FPathName.GetData(), Attribute);
}

/*##########################################################################
#
#   Name       : TPathName::IsFile
#
#   Purpose....: Check if pathname is a file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::IsFile() const
{
    int Attrib;
    
    if (RdosGetFileAttribute(FPathName.GetData(), &Attrib))
        if (Attrib != FILE_ATTRIBUTE_DIRECTORY)
            return TRUE;
        
    return FALSE;
}

/*##########################################################################
#
#   Name       : TPathName::OpenFile
#
#   Purpose....: Open path as file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile TPathName::OpenFile() const
{
    return TFile(FPathName.GetData());
}

/*##########################################################################
#
#   Name       : TPathName::CreateFile
#
#   Purpose....: Create path as file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile TPathName::CreateFile(int Attrib) const
{
    return TFile(FPathName.GetData(), Attrib);
}

/*##########################################################################
#
#   Name       : TPathName::DeleteFile
#
#   Purpose....: Delete file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::DeleteFile() const
{
    return RdosDeleteFile(FPathName.GetData());
}

/*##########################################################################
#
#   Name       : TPathName::MoveFile
#
#   Purpose....: Move a file to a new name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::MoveFile(const TPathName &NewName) const
{
    TFile *src;
    TFile *dst;
    int ok;
    char *buf;
    int size;
    TDateTime ftime;
    int attrib;
    TPathName *destpath;

    ok = FALSE;
    dst = 0;
    src = new TFile(FPathName.GetData());
    if (src->IsOpen())
    {
        ftime = src->GetTime();
        attrib = GetAttribute();

        if (NewName.IsDir())
            destpath = new TPathName(NewName + GetEntryName());
        else
            destpath = new TPathName(NewName.FPathName);

        dst = new TFile(destpath->FPathName.GetData(), 0);

        if (dst->IsOpen())
        {
            ok = TRUE;
            buf = new char[0x1000];

            size = src->Read(buf, 0x1000);
            while (ok && size)
            {
                ok = (size == dst->Write(buf, size));
                if (ok)
                    size = src->Read(buf, 0x1000);
            }

            if (ok)
            {
                delete src;
                src = 0;
                DeleteFile();

                dst->SetTime(ftime);
                destpath->SetAttribute(attrib);
            }

            delete buf;
        }

        delete destpath;

        if (!ok)
        {
            delete dst;
            dst = 0;
            NewName.DeleteFile();
        }
    }

    if (src)
        delete src;

    if (dst)
        delete dst;

    return ok;
}

/*##########################################################################
#
#   Name       : TPathName::CopyFile
#
#   Purpose....: Copy a file to a new name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::CopyFile(const TPathName &NewName) const
{
    TFile *src;
    TFile *dst;
    int ok;
    char *buf;
    int size;
    TDateTime ftime;
    int attrib;
    TPathName *destpath;

    ok = FALSE;
    dst = 0;
    src = new TFile(FPathName.GetData());
    if (src->IsOpen())
    {
        ftime = src->GetTime();
        attrib = GetAttribute();

        if (NewName.IsDir())
            destpath = new TPathName(NewName + GetEntryName());
        else
            destpath = new TPathName(NewName.FPathName);

        dst = new TFile(destpath->FPathName.GetData(), 0);

        if (dst->IsOpen())
        {
            ok = TRUE;
            buf = new char[0x1000];

            size = src->Read(buf, 0x1000);
            while (ok && size)
            {
                ok = (size == dst->Write(buf, size));
                if (ok)
                    size = src->Read(buf, 0x1000);
            }

            if (ok)
            {
                dst->SetTime(ftime);
                destpath->SetAttribute(attrib);
            }

            delete buf;
        }

        delete destpath;

        if (!ok)
        {
            delete dst;
            dst = 0;
            NewName.DeleteFile();
        }
    }

    if (src)
        delete src;
        
    if (dst)
        delete dst;

    return ok;
}

/*##########################################################################
#
#   Name       : TPathName::AppendFile
#
#   Purpose....: Append a file to a new name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::AppendFile(const TPathName &NewName) const
{
    TFile *src;
    TFile *dst;
    int ok;
    char *buf;
    int size;
    long long fsize;

    ok = FALSE;
    dst = 0;
    src = new TFile(FPathName.GetData());
    if (src->IsOpen())
    {
        dst = new TFile(NewName.FPathName.GetData());
        if (dst->IsOpen())
        {
            fsize = dst->GetSize();
            dst->SetPos(fsize);

            ok = TRUE;
            buf = new char[0x1000];
 
            size = src->Read(buf, 0x1000);
            while (ok && size)
            {
                ok = (size == dst->Write(buf, size));
                if (ok)
                    size = src->Read(buf, 0x1000);
            }
                        
            delete buf;
        }

        if (!ok)
            dst->SetSize(fsize);
    }

    if (src)
        delete src;
        
    if (dst)
        delete dst;

    return ok;
}

/*##########################################################################
#
#   Name       : TPathName::IsDir
#
#   Purpose....: Check if pathname is a directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::IsDir() const
{
    int Attrib;
    
    if (RdosGetFileAttribute(FPathName.GetData(), &Attrib))
        if (Attrib & FILE_ATTRIBUTE_DIRECTORY)
            return TRUE;
        
    return FALSE;
}

/*##########################################################################
#
#   Name       : TPathName::RemoveDir
#
#   Purpose....: Remove directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::RemoveDir() const
{
    return RdosRemoveDir(FPathName.GetData());
}

/*##########################################################################
#
#   Name       : TPathName::MakeDir
#
#   Purpose....: Create directory and all it's components
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::MakeDir() const
{
    int Attrib;
    
    if (RdosGetFileAttribute(FPathName.GetData(), &Attrib))
    {
        if (Attrib & FILE_ATTRIBUTE_DIRECTORY)
            return TRUE;
        else
            return FALSE;
    }

    TString Base = GetBaseName();

    if (Base.GetSize())
    {
        if (RdosGetFileAttribute(Base.GetData(), &Attrib))
        {
            if (Attrib != FILE_ATTRIBUTE_DIRECTORY)
                return FALSE;
        }    
        else
        {   
            TPathName SubPath(Base);

            if (!SubPath.MakeDir())
                return FALSE;
        }
    }

    return RdosMakeDir(FPathName.GetData());
}

/*##########################################################################
#
#   Name       : TPathName::WipeDir
#
#   Purpose....: Wipe directory and all its contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPathName::WipeDir() const
{
    int Attrib;
    int ok;
    
    if (RdosGetFileAttribute(FPathName.GetData(), &Attrib))
    {
        if (Attrib != FILE_ATTRIBUTE_DIRECTORY)
            return FALSE;
    }

    TDirList DirList = Find();

    if (DirList.GetSize())
    {
        ok = DirList.GotoFirst();

        while (ok)
        {
            TDirEntry DirEntry = DirList.Get();
            TPathName PathName = DirEntry.GetPathName();

            if (PathName.IsFile())
                PathName.DeleteFile();
            else
            {
                if (!PathName.WipeDir())
                    return FALSE;
            }
            ok = DirList.GotoNext();
        }
    }

    return RdosRemoveDir(FPathName.GetData());
}

/*##########################################################################
#
#   Name       : TPathName::Find
#
#   Purpose....: Find directory entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList TPathName::Find() const
{
    return TDirList(FPathName);
}

/*##########################################################################
#
#   Name       : TPathName::Find
#
#   Purpose....: Find directory entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList TPathName::Find(const char *SearchString) const
{
    TPathName path(*this);

    path += SearchString;

    return TDirList(path);
}

/*##########################################################################
#
#   Name       : TPathName::Find
#
#   Purpose....: Find directory entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirList TPathName::Find(const TString &SearchString) const
{
    TPathName path(*this);

    path += SearchString;

    return TDirList(path);
}
