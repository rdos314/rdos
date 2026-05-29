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
#include "file.h"

#ifdef __RDOS__
#include "rdos.h"
#include "direntry.h"
#else
#include <iostream>
#include <unistd.h>
#include <limits.h> // For PATH_MAX
#include <stdlib.h> // For realpath
#include <sys/stat.h>
#include <dirent.h>
#endif

/**
 * Constructor for TPathName using current working directory.
 */
TPathName::TPathName()
{
#ifdef __RDOS__
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
#else
    char cwd[PATH_MAX];

    if (getcwd(cwd, sizeof(cwd)) != nullptr)
        FPathName = cwd;
    else
        FPathName = "/";
#endif
}

/**
 * Constructor for TPathName with path name.
 *
 * @param PathName The path name to be managed by the TPathName object.
 */
TPathName::TPathName(const char *PathName)
{
    Init(PathName);
}

/**
 * Constructor for TPathName with path name.
 *
 * @param PathName The path name to be managed by the TPathName object.
 */
TPathName::TPathName(const TString &PathName)
{
    Init(PathName.GetData());
}

#ifdef __RDOS__
/**
 * Constructor for TPathName with drive and default directory.
 *
 * @param Drive The drive letter for which the path name is to be retrieved.
 */
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

/**
 * @class TPathName
 * @brief Represents and manages file or directory path names in a structured manner.
 *
 * The TPathName class provides functionality to handle and manipulate file system
 * paths. It allows for operations such as retrieving components of the path,
 * normalizing paths, and constructing platform-independent path strings.
 *
 * This class is designed to simplify path management tasks, ensuring correctness
 * and ease of use when dealing with file system paths across various systems.
 *
 * @param Drive The drive letter for which the path name is to be retrieved.
 * @param PathName The path name to be managed by the TPathName object.
 */
TPathName::TPathName(int Drive, const TString &PathName)
{
    char str[4];

    str[0] = (char)Drive + 'a';
    str[1] = ':';
    str[2] = 0;

    FPathName = str;
    FPathName += PathName;
}

/**
 * Constructor for TPathName with drive, directory and entry names.
 *
 * @param Drive The object for which the path name is to be retrieved.
 * @param DirName The directory name component of the path.
 * @param EntryName The entry name component of the path.
 */
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
#endif

/**
 * @class TPathName
 * @brief Represents and manages a filesystem path name.
 *
 * The TPathName class provides functionality to create, manipulate, and query
 * filesystem path names. It is designed to simplify operations involving
 * directory and file paths, such as joining path components, retrieving file
 * extensions, and normalizing paths.
 *
 * This class ensures portability and proper handling of path separators
 * across different operating systems.
 *
 * Key functionalities include:
 * - Managing path components.
 * - Handling file extensions.
 * - Normalizing relative and absolute paths.
 * - Supporting operations for file and directory paths.
 */
TPathName::TPathName(const TPathName &PathName)
  : FPathName(PathName.FPathName)
{
}

/**
 * @brief Destructor for TPathName.
 */
TPathName::~TPathName()
{
}

/**
 * @brief Initializes the necessary components or settings for the object.
 *
 */
void TPathName::Init(const char *PathName)
{
#ifdef __RDOS__
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
#else
    char *buf = new char[strlen(PathName) + 1];

    strcpy(buf, PathName);
    for (char *p = buf; *p; p++)
        if (*p == '\\') *p = '/';

    if (buf[0] == '/')
        FPathName = buf;
    else
    {
        char cwd[PATH_MAX];

        if (getcwd(cwd, sizeof(cwd)) != nullptr)
        {
            FPathName = cwd;
            FPathName += "/";
            FPathName += buf;
        }
        else
            FPathName = buf;
    }
    delete[] buf;
#endif
}

/**
 * Overloads the operator for the specified functionality.
 *
 * @param lhs The left-hand side operand of the operation.
 * @param rhs The right-hand side operand of the operation.
 * @return The result of applying the operator to the operands.
 */
const TPathName &TPathName::operator=(const TPathName &src)
{
    FPathName = src.FPathName;
    return *this;
}

/**
 * Overloads the operator for a specific operation between objects.
 *
 * @param other The object to be operated on with the current instance.
 * @return The result of the operation between the current instance and the other object.
 */
const TPathName &TPathName::operator=(const TString &src)
{
    FPathName = src;
    return *this;
}

/**
 * Overloads the operator for custom behavior.
 *
 * @param other The object to be used in the operation.
 * @return The result of the operator applied to the current instance and the passed object.
 */
const TPathName &TPathName::operator+=(const TString &str)
{
    const char *path;
    const char *ptr;
    int pos;

    path = FPathName.GetData();
    ptr = str.GetData();

#ifdef __RDOS__
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
#else
    while (*ptr == '/')
        ptr++;

    pos = strlen(path);
    if (pos)
        pos--;

    switch (path[pos])
    {
        case '/':
            FPathName += ptr;
            break;

        default:
            if (*path)
                FPathName += "/" + TString(ptr);
            else
                FPathName += ptr;
            break;
    }
#endif
    return *this;
}

/**
 * Overloads the operator to provide custom behavior for a specific operation.
 *
 * @param lhs The left-hand side operand of the operation.
 * @param rhs The right-hand side operand of the operation.
 * @return The result of the operation after applying the overloaded operator.
 */
const TPathName &TPathName::operator+=(const char *str)
{
    const char *path;
    int pos;

    path = FPathName.GetData();

#ifdef __RDOS__
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
#else
    while (*str == '/')
        str++;

    pos = strlen(path);
    if (pos)
        pos--;

    switch (path[pos])
    {
        case '/':
            FPathName += TString(str);
            break;

        default:
            if (*path)
                FPathName += "/" + TString(str);
            else
                FPathName += TString(str);
            break;
    }
#endif
    return *this;
}

/**
 * Overloads the operator for a specific functionality.
 *
 * @param lhs The left-hand side operand of the operator.
 * @param rhs The right-hand side operand of the operator.
 * @return The result produced by applying the overloaded operator to lhs and rhs.
 */
TPathName operator+(const TPathName& path, const TString& str)
{
    TPathName p(path);
    p += str;
    return p;
}

/**
 * Overloads the operator for the specified operation.
 *
 * @param lhs The left-hand side operand of the operator.
 * @param rhs The right-hand side operand of the operator.
 * @return The result of applying the operator to the given operands.
 */
TPathName operator+(const TPathName& path, const char *str)
{
    TPathName p(path);
    p += str;
    return p;
}

/**
 * Retrieves the pathname as a TString object.
 *
 * @param key The key whose associated value is to be retrieved.
 * @return Pathname as TString object.
 */
TString TPathName::Get() const
{
    return FPathName;
}

#ifdef __RDOS__
/**
 * Checks if the system or entity has an attached drive.
 *
 * This method determines whether a drive is present and operational
 * for the given context or system. It can be used to verify the
 * presence of storage or processing capabilities associated with
 * a drive.
 *
 * @return Returns true if a drive is present and functioning;
 *         otherwise, returns false.
 */
int TPathName::HasDrive() const
{
    int size;
    const char *str;

    size = FPathName.GetSize();
    if (size >= 2)
    {
        str = FPathName.GetData();
        if (str[1] == ':')
            return true;
        else
            return false;
    }
    else
        return false;
}

/**
 * Retrieves the drive associated with the specified identifier or configuration.
 *
 * This method is used to access and manage the drive that corresponds to
 * the given parameters. The specific implementation may vary depending on
 * the system or application requirements.
 *
 * @return The drive object or reference representing the retrieved drive.
 */
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

#endif

/**
 * Checks if the provided file path is a full (absolute) path.
 *
 * A full path is a complete path specification that typically starts
 * from the root directory, depending on the operating system.
 * For example, on Unix-like systems, a full path starts with "/".
 *
 * @return True if the file path is an absolute path; false otherwise.
 */
bool TPathName::HasFullPath() const
{
    int size;
    const char *str;

#ifdef __RDOS__
    size = FPathName.GetSize();

    if (size >= 2)
    {
        str = FPathName.GetData();
        if (str[1] == ':')
        {
            if (size >= 3)
                if (str[2] == '\\')
                    return true;
        }
        else
            if (str[0] == '\\')
                return true;
    }
    return false;
#else
    str = FPathName.GetData();

    if (*str == '/')
        return true;
    else
        return false;
#endif
}

/**
 * Extracts the base name from a given file path or full name.
 *
 * The base name refers to the name of the file or directory without the
 * preceding directory path or file extension.
 *                 the base name will be extracted.
 * @return A string containing the base name of the provided file path or name.
 */
TString TPathName::GetBaseName() const
{
#ifdef __RDOS__
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
#else
    TString s;
    char *newstr;
    const char *str;
    int size;
    int i;

    str = FPathName.GetData();
    size = FPathName.GetSize();

    i = size - 1;
    while (i >= 0 && str[i] != '/')
        i--;

    if (i >= 0)
    {
        if (i == 0)
            s = "/";
        else
        {
            newstr = new char[i + 1];
            memcpy(newstr, str, i);
            *(newstr + i) = 0;
            s = newstr;
            delete newstr;
        }
    }
    else
        s = "";

    return s;
#endif
}

/**
 * Retrieves the name of the entry.
 *
 * This method returns the name associated with a specific entry.
 * The returned name is typically a string identifier corresponding
 * to the entry being queried.
 *
 * @return A string representing the name of the entry.
 */
TString TPathName::GetEntryName() const
{
#ifdef __RDOS__
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
#else
    const char *str = FPathName.GetData();
    int i = FPathName.GetSize() - 1;

    while (i >= 0 && str[i] != '/')
        i--;

    return TString(str + i + 1);
#endif
}

/**
 * Retrieves the full path and filename for a specified file, combining the current directory
 * and the specified file name. This method resolves partial paths, relative paths,
 * and references such as "." or "..".
 *
 * @return The full path and filename as a TString object.
 */
TString TPathName::GetFullPathName() const
{
#ifdef __RDOS__
    TString s;
    const char *str;
    char *path;
    int drive;
    char drive_str[3];
    int size;
    bool add;

    size = FPathName.GetSize();

    if (size <= 2)
        add = true;
    else
    {
        str = FPathName.GetData();
        if (*(str+1) == ':' && isalpha(*str))
            add = false;
        else
            add = true;
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
        add = true;
    else
    {
        str = s.GetData();
        if (*(str+2) == '\\')
            add = false;
        else
            add = true;
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
#else
    char *resolved = realpath(FPathName.GetData(), nullptr);
    if (resolved)
    {
        TString s(resolved);
        free(resolved);
        return s;
    }
    return FPathName;
#endif
}

/**
 * Retrieves the value of a specified attribute from an object or data structure.
 *
 * This method is used to fetch an attribute's value based on its identifier or key.
 * It may throw an exception or return a default/failure value if the attribute
 * is not found or cannot be accessed.
 *
 * @return File attribute value, or -1 if not found or error.
 */
int TPathName::GetAttribute() const
{
#ifdef __RDOS__
    int attrib;

    if (RdosGetFileAttribute(FPathName.GetData(), &attrib))
        return attrib;
    else
        return -1;
#else
    struct stat st;
    if (stat(FPathName.GetData(), &st) != 0)
        return -1;

    return st.st_mode;
#endif
}

/**
 * Sets the attribute of an object to the specified value.
 *
 * @param Attribute The file attribute to set.
 * @return A boolean indicating whether the operation was successful.
 */
bool TPathName::SetAttribute(int Attribute) const
{
#ifdef __RDOS__
    return RdosSetFileAttribute(FPathName.GetData(), Attribute);
#else
    return chmod(FPathName.GetData(), Attribute) == 0;
#endif
}

/**
 * Checks if the given path corresponds to an existing file.
 *
 * This method verifies whether the provided path leads
 * to a file that exists in the file system. It differentiates
 * between files and directories, returning true only for files.
 *
 * @return True if the path points to an existing file;
 *         otherwise, false.
 */
bool TPathName::IsFile() const
{
#ifdef __RDOS__
    int Attrib;

    if (RdosGetFileAttribute(FPathName.GetData(), &Attrib))
        if (Attrib != FILE_ATTRIBUTE_DIRECTORY)
            return true;

    return false;
#else
    int attr = GetAttribute();
    return (attr != -1 && !S_ISDIR(attr));
#endif
}

/**
 * Opens a file with the specified filename and mode.
 *
 * This method attempts to open a file indicated by the provided filename.
 * If successful, the file is opened with the specified access mode (e.g., read, write, append).
 * The behavior of the file opening depends on the provided mode and the existence of the file.
 *
 * @return A TFile object.
 */
TFile TPathName::OpenFile() const
{
    return TFile(FPathName.GetData());
}

/**
 * Creates a new file with the specified name and path.
 *
 * @param Attrib Attributes for the new file.
 * @return A TFile object.
 */
TFile TPathName::CreateFile(int Attrib) const
{
    return TFile(FPathName.GetData(), Attrib);
}

/**
 * Deletes the specified file from the file system.
 *
 * This method attempts to remove a file identified by the provided
 * file path. If the file does not exist or cannot be deleted due to
 * permissions or other errors, an exception may be thrown or an error
 * code returned based on the implementation.
 *
 * @return True if the file was deleted successfully; false if the
 *         file could not be deleted or does not exist.
 */
bool TPathName::DeleteFile() const
{
#ifdef __RDOS__
    return RdosDeleteFile(FPathName.GetData());
#else
    return unlink(FPathName.GetData()) == 0;
#endif
}

/**
 * Moves a file from the source path to the destination path.
 *
 * @param NewName The path where the file should be moved to, including the target filename.
 * @return True if the file was moved successfully, false otherwise.
 */
bool TPathName::MoveFile(const TPathName &NewName) const
{
    TFile *src;
    TFile *dst;
    bool ok;
    char *buf;
    int size;
    TDateTime ftime;
    int attrib;
    TPathName *destpath;

    ok = false;
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
            ok = true;
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

/**
 * Copies a file from a source path to a destination path.
 *
 * @param NewName file to be copied to.
 * @return True if the file was successfully copied; false otherwise.
 */
bool TPathName::CopyFile(const TPathName &NewName) const
{
    TFile *src;
    TFile *dst;
    bool ok;
    char *buf;
    int size;
    TDateTime ftime;
    int attrib;
    TPathName *destpath;

    ok = false;
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
            ok = true;
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

/**
 * Appends the specified content to a file at the given file path.
 *
 * @param NewName destination file to append to
 * @return True if the content was successfully appended to the file, false otherwise.
 */
bool TPathName::AppendFile(const TPathName &NewName) const
{
    TFile *src;
    TFile *dst;
    int ok;
    char *buf;
    int size;
    long long fsize;

    ok = false;
    dst = 0;
    src = new TFile(FPathName.GetData());
    if (src->IsOpen())
    {
        dst = new TFile(NewName.FPathName.GetData());
        if (dst->IsOpen())
        {
            fsize = dst->GetSize();
            dst->SetPos(fsize);

            ok = true;
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

/**
 * @brief Checks if the specified path is a directory.
 *
 * This method determines whether the given file path corresponds to a directory
 * in the file system. It verifies the existence of the path and checks if it is
 * classified as a directory.
 *
 * @return true if the path is a directory, false otherwise.
 */
bool TPathName::IsDir() const
{
#ifdef __RDOS__
    int Attrib;

    if (RdosGetFileAttribute(FPathName.GetData(), &Attrib))
        if (Attrib & FILE_ATTRIBUTE_DIRECTORY)
            return true;

    return false;
#else
    int attr = GetAttribute();
    return (attr != -1 && S_ISDIR(attr));
#endif
}

/**
 * Removes a directory and its contents from the file system.
 *
 * This method deletes the specified directory and all files and subdirectories
 * within it. If the directory does not exist, the method will take no action.
 *
 * @return True if the directory and its contents were successfully removed,
 *         false otherwise. Returns false if the directory does not exist
 *         or if an error occurs during removal.
 */
bool TPathName::RemoveDir() const
{
#ifdef __RDOS__
    return RdosRemoveDir(FPathName.GetData()) != 0;
#else
    return rmdir(FPathName.GetData()) == 0;
#endif
}

/**
 * Creates a new directory at the specified path.
 *
 * This method attempts to create a directory in the filesystem using
 * the provided path. If the directory already exists, no changes are made.
 *
 * @return True if the directory was successfully created or already exists,
 *         false if the creation failed.
 */
bool TPathName::MakeDir() const
{
#ifdef __RDOS__
    int Attrib;

    if (RdosGetFileAttribute(FPathName.GetData(), &Attrib))
    {
        if (Attrib & FILE_ATTRIBUTE_DIRECTORY)
            return true;
        else
            return false;
    }

    TString Base = GetBaseName();

    if (Base.GetSize())
    {
        if (RdosGetFileAttribute(Base.GetData(), &Attrib))
        {
            if (Attrib != FILE_ATTRIBUTE_DIRECTORY)
                return false;
        }
        else
        {
            TPathName SubPath(Base);

            if (!SubPath.MakeDir())
                return false;
        }
    }

    return RdosMakeDir(FPathName.GetData()) != 0;
#else
    return mkdir(FPathName.GetData(), 0777) == 0;
#endif
}

/**
 * Deletes all files and subdirectories within the specified directory.
 *
 * This method removes all contents of the given directory recursively,
 * including files and nested subdirectories. The directory itself is deleted.
 *
 * @return True if the operation was successful, false if an error occurred.
 */
bool TPathName::WipeDir() const
{
#ifdef __RDOS__
    int Attrib;
    int ok;

    if (RdosGetFileAttribute(FPathName.GetData(), &Attrib))
    {
        if (Attrib != FILE_ATTRIBUTE_DIRECTORY)
            return false;
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
                    return false;
            }
            ok = DirList.GotoNext();
        }
    }

    return RdosRemoveDir(FPathName.GetData()) != 0;
#else
    DIR* dir = opendir(FPathName.GetData());
    if (!dir) return false;

    struct dirent* entry;
    bool ok = true;

    while ((entry = readdir(dir)) != nullptr)
    {
        TString name(entry->d_name);
        if (name == "." || name == "..") continue;

        TPathName path(*this);
        path += name;

        if (path.IsFile())
        {
            if (!path.DeleteFile())
            {
                ok = false;
                break;
            }
        }
        else if (path.IsDir())
        {
            if (!path.WipeDir())
            {
                ok = false;
                break;
            }
        }
    }
    closedir(dir);

    return ok && RemoveDir();
#endif
}

#ifdef __RDOS__
TDirList TPathName::Find() const
{
    return TDirList(FPathName);
}TDirList TPathName::Find(const char *SearchString) const
{
    TPathName path(*this);

    path += SearchString;

    return TDirList(path);
}

TDirList TPathName::Find(const TString &SearchString) const
{
    TPathName path(*this);

    path += SearchString;

    return TDirList(path);
}
#endif
