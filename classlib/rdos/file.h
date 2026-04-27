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
# file.h
# File class
#
########################################################################*/

#ifndef _FILE_H
#define _FILE_H

#include "datetime.h"
#include "str.h"

#ifdef __RDOS__
#include "rdos.h"
#endif

/**
 * @class TFile
 * @brief Represents a file abstraction for performing file operations.
 *
 * The TFile class provides methods to interact with files, including reading,
 * writing, setting file size, accessing file attributes, and file position management.
 * Additionally, it includes platform-specific support for RDOS.

 * @note The platform-dependent RDOS functionality is enabled via preprocessor directives.
 */
class TFile
{
public:
    TFile(const char *FileName);
    TFile(const char *FileName, int Attrib);
    TFile(const TFile &file);
    ~TFile();

    bool IsOpen();
    bool IsDevice();
    bool IsFile();
    const char *GetFileName();

    long long GetSize();
    void SetSize(long long Size);
    long long GetPos();
    void SetPos(long long Pos);
    TDateTime GetTime();
    void SetTime(const TDateTime &time);

    int Read(void *Buf, int Size);
    int Write(const void *Buf, int Size);
    int Write(const char *str);

protected:
#ifdef __RDOS__
    int VfsReadOne(int index, char *Buf, long long Pos, int Size);
    int VfsWriteOne(int index, char *Buf, long long Pos, int Size);
    int VfsFind(long long Pos);
    int VfsRead(void *Buf, int Size);
    int VfsWrite(const void *Buf, int Size);
#endif

private:
    /**
     * @variable FHandle
     * @brief Internal file handle used for low-level file operations.
     *
     * FHandle represents a platform-specific handle or descriptor used internally
     * to manage and interact with a file or device resource. It is initialized during
     * the construction of a TFile object and is subject to platform-dependent behavior
     * based on the target operating system.
     *
     * @note On certain platforms (e.g., RDOS), FHandle is associated with additional
     *       file mapping structures to enable efficient file management.
     */
    int FHandle;
    /**
     * @var TString FFileName
     * @brief Stores the name of the file associated with the TFile instance.
     *
     * This variable holds the file name as a string, which is used internally to
     * identify the file for various file operations within the TFile class.
     * It acts as a key reference to the file during tasks such as reading,
     * writing, and managing file attributes.
     */
    TString FFileName;

#ifdef __RDOS__
    struct RdosFileMap *FMap;
    int FMapIndex;
    int FLastIndex;
#endif
};

#endif

