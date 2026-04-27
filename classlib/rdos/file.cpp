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
# file.cpp
# File class
#
########################################################################*/

#ifndef __RDOS__
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

#include <string.h>
#include "file.h"

/**
 * @brief Constructs a TFile object and opens the specified file for read/write access.
 *
 * This constructor initializes the TFile instance with the given file name and attempts
 * to open the file in read/write mode. If the file cannot be opened, the internal file
 * handle is set to 0. On platforms such as RDOS, additional initialization for file mapping
 * may take place.
 *
 * @param FileName A constant character pointer to the name (or path) of the file to be opened.
 *                 The file name should be null-terminated.
 *
 * @return None. This constructor does not return a value but initializes internal
 *         variables and state of the TFile object.
 */
TFile::TFile(const char *FileName)
    : FFileName(FileName)
{
#ifdef __RDOS__
    int len;

    FHandle = RdosOpenHandle(FileName, O_RDWR);

    if (FHandle < 0)
        FHandle = 0;

    if (FHandle)
        FMap = RdosGetHandleMap(FHandle, &FMapIndex);
    else
        FMap = 0;

    FLastIndex = -1;

#else
    FHandle = open(FileName, O_RDWR);
    if (FHandle < 0)
        FHandle = 0;
#endif
}

/**
 * @brief Constructs a TFile object and opens or creates a file.
 *
 * This constructor initializes a new TFile object by opening or creating a file with
 * the specified file name and attributes. On RDOS, it utilizes platform-specific
 * functionality for file handling and mapping. On non-RDOS platforms, it uses standard
 * low-level file APIs.
 *
 * @param FileName The name of the file to open or create.
 * @param Attrib The file attribute or permission flags for the file (platform-specific).
 * @return A newly constructed TFile object representing the specified file.
 *
 * @note On RDOS, additional file mapping structures are set up for efficient
 *       file operations. If the file cannot be created or opened, the internal
 *       handle (FHandle) is set to 0.
 */
TFile::TFile(const char *FileName, int Attrib)
{
#ifdef __RDOS__
    int len;

    FHandle = RdosOpenHandle(FileName, O_CREAT | O_RDWR);

    if (FHandle < 0)
        FHandle = 0;

    if (FHandle)
        FMap = RdosGetHandleMap(FHandle, &FMapIndex);
    else
        FMap = 0;

    FLastIndex = -1;

#else
    FHandle = creat(FileName, Attrib);
    if (FHandle < 0)
        FHandle = 0;
#endif
}

/**
 * @brief Copy constructor for the TFile class.
 *
 * This constructor creates a new TFile instance by copying the internal
 * state of another TFile object. It duplicates the underlying file handle
 * and associated resources, ensuring the new instance has its own valid
 * representation of the original file while maintaining platform-specific
 * behavior.
 *
 * @param file A reference to an existing TFile object to be copied.
 *
 * @return A new TFile instance with duplicated file handle and state based
 *         on the input TFile object.
 */
TFile::TFile(const TFile &file)
{
#ifdef __RDOS__

    FMap = 0;

    if (file.FHandle)
    {
        FHandle = RdosDupHandle(file.FHandle);

        if (FHandle < 0)
            FHandle = 0;

        if (FHandle)
            FMap = RdosGetHandleMap(FHandle, &FMapIndex);
    }
    else
        FHandle = 0;

    FLastIndex = file.FLastIndex;
#else
    if (FHandle > 0)
        FHandle = dup(file.FHandle);
    else
        FHandle = 0;
#endif
}

/**
 * @brief Destructor for the TFile class.
 *
 * Releases the resources associated with the internal file handle (FHandle).
 * The destructor ensures that the handle is properly closed to prevent resource
 * leaks. The behavior is platform-dependent:
 *
 * - On RDOS, the handle is closed using `RdosCloseHandle`.
 * - On other platforms, the handle is closed using the standard `close` function.
 *
 * If the file handle is not valid (e.g., when its resource has already been
 * released or it was never opened), no operation is performed.
 *
 * @note Users do not need to explicitly invoke this destructor, as it is called
 *       automatically when a TFile object goes out of scope or is deleted.
 */
TFile::~TFile()
{
#ifdef __RDOS__
    if (FHandle)
        RdosCloseHandle(FHandle);
#else
    if (FHandle)
        close(FHandle);
#endif
}

/**
 * @brief Checks if the file is currently open.
 *
 * This method verifies whether the file associated with this TFile instance
 * is open and accessible. A file is considered open if the internal file
 * handle (FHandle) is valid.
 *
 * @return true if the file is open, false otherwise.
 */
bool TFile::IsOpen()
{
    if (FHandle)
        return true;
    else
        return false;
}

/**
 * @brief Determines whether the object represents a device.
 *
 * This method checks if the underlying file handle corresponds to a device
 * rather than a standard file. The behavior is specific to the RDOS
 * platform where device handles are distinguishable.
 *
 * @return True if the file handle is associated with a device, false otherwise.
 */
bool TFile::IsDevice()
{
#ifdef __RDOS__
    if (FHandle)
        return RdosIsHandleDevice(FHandle);
    else
        return false;
#else
    return false;
#endif
}

/**
 * @brief Determines if the current TFile instance represents a regular file.
 *
 * This method checks whether the TFile instance is associated with a regular file
 * as opposed to other types of handles, such as device handles. On specific platforms
 * like RDOS, it explicitly determines whether the internal handle points to a device
 * and returns false in such cases.
 *
 * @return true if the TFile instance represents a regular file; false otherwise.
 */
bool TFile::IsFile()
{
#ifdef __RDOS__
    if (FHandle)
        return !RdosIsHandleDevice(FHandle);
    else
        return false;
#else
    return true;
#endif
}

/**
 * @brief Retrieves the name of the file associated with the TFile object.
 *
 * This method returns the file name stored in the TFile instance.
 * The file name identifies the file being managed or operated upon.
 *
 * @return A constant character pointer representing the file name.
 */
const char *TFile::GetFileName()
{
    return FFileName.GetData();
}

/**
 * @brief Retrieves the current size of the file.
 *
 * This method returns the size of the file in bytes. The implementation
 * is platform-dependent and uses system-specific APIs to determine the
 * file size.
 *
 * On RDOS:
 * - If the file is memory-mapped (FMap is not null), the size is obtained
 *   from the file mapping structure (FMap->Info->CurrSize).
 * - If the file handle (FHandle) is valid but not memory-mapped, the size
 *   is retrieved using the RdosGetHandleSize function.
 * - If neither of the above conditions is true, returns 0.
 *
 * On non-RDOS platforms:
 * - If FHandle is a valid file descriptor, the size is obtained via the
 *   POSIX `fstat` function, which populates a `stat` structure with the
 *   file size.
 * - If FHandle is not valid, returns 0.
 *
 * @return The size of the file in bytes, or 0 if the size cannot be
 *         determined or the file is not open.
 */
long long TFile::GetSize()
{
#ifdef __RDOS__
    if (FMap)
        return FMap->Info->CurrSize;
    else
    {
        if (FHandle)
            return RdosGetHandleSize(FHandle);
        else
            return 0;
    }
#else
    struct stat statbuf;
    if (FHandle > 0)
    {
        fstat(FHandle, &statbuf);
        return statbuf.st_size;
    }
    else
        return 0;
#endif
}

/**
 * @brief Sets the size of the file.
 *
 * Adjusts the size of the file associated with the current TFile instance.
 * If the file is open, the size is modified accordingly based on the target
 * platform. On RDOS, it uses `RdosSetHandleSize` and updates the file handle
 * if required. On non-RDOS platforms, it uses `ftruncate` to resize the file.
 *
 * @param Size The new size of the file in bytes.
 *
 * @note On RDOS, if a file map is associated (`FMap`) and its `Update` flag
 *       is set, the file handle is updated using `RdosUpdateHandle`.
 * @note On non-RDOS platforms, the modification requires a valid file handle
 *       (FHandle > 0).
 */
void TFile::SetSize(long long Size)
{
#ifdef __RDOS__
    if (FHandle)
    {
        RdosSetHandleSize(FHandle, Size);

        if (FMap && FMap->Update)
            RdosUpdateHandle(FHandle);
    }
#else
    if (FHandle > 0)
        ftruncate(FHandle, Size);
#endif
}

/**
 * @brief Retrieves the current position of the file pointer within the file.
 *
 * This method returns the current position of the file pointer, which indicates
 * the offset (in bytes) from the beginning of the file. If the file is managed
 * by the RDOS system and mapped in memory, the position is retrieved from the
 * file map. Otherwise, the position is determined using platform-specific
 * functionality.
 *
 * @return The current position of the file pointer in bytes. If the file is not
 *         open or no valid handle is available, the method may return 0.
 */
long long TFile::GetPos()
{
#ifdef __RDOS__
    if (FMap)
        return FMap->Handle->PosArr[FMapIndex - 1];
    else
    {
        if (FHandle)
            return RdosGetHandlePos(FHandle);
        else
            return 0;
    }
#else
    return lseek(FHandle, 0, SEEK_CUR);
#endif
}

/**
 * @brief Sets the position of the file pointer for the current file.
 *
 * This method adjusts the file pointer to a specified position for subsequent read
 * and write operations. The actual implementation of this behavior varies based
 * on the underlying operating system. For RDOS, it manages the position by updating
 * associated file mapping structures or setting the handle position directly.
 * On other platforms, it uses the `lseek` system call to set the position.
 *
 * @param Pos The desired position, in bytes, to set the file pointer.
 */
void TFile::SetPos(long long Pos)
{
#ifdef __RDOS__
    if (FMap)
        FMap->Handle->PosArr[FMapIndex - 1] = Pos;
    else
    {
        if (FHandle)
            RdosSetHandlePos(FHandle, Pos);
    }
#else
    lseek(FHandle, Pos, SEEK_SET);
#endif
}

/**
 * @brief Retrieves the modification timestamp of the file.
 *
 * This method returns the time the file was last modified. It uses platform-specific
 * methods to extract the modification time based on the file handle.
 *
 * @return A TDateTime object representing the last modification time of the file.
 * If the file handle is invalid or not available, returns a default TDateTime object.
 */
TDateTime TFile::GetTime()
{
#ifdef __RDOS__
    unsigned long msb, lsb;

    if (FHandle)
    {
        RdosGetHandleModifyTime(FHandle, &msb, &lsb);
        return TDateTime(msb, lsb);
    }

#else
    struct stat statbuf;
    int year, month, day, hour, min, sec;

    if (FHandle > 0)
    {
        fstat(FHandle, &statbuf);
        BinaryToTime(statbuf.st_mtime, &year, &month, &day, &hour, &min, &sec);
        return TDateTime(year, month, day, hour, min, sec);
    }
#endif

    return TDateTime();
}

/**
 * @brief Sets the last modification time for the file.
 *
 * This method updates the modification time of the file associated with this
 * object to the specified time. The functionality is platform-dependent and
 * currently supported only on RDOS.
 *
 * @param time The TDateTime object representing the new modification time
 *             to be set for the file.
 */
void TFile::SetTime(const TDateTime &time)
{
#ifdef __RDOS__
    long msb, lsb;

    if (FHandle)
    {
        msb = time.GetMsb();
        lsb = time.GetLsb();
        RdosSetHandleModifyTime(FHandle, msb, lsb);
    }
#endif
}

/**
 * @brief Finds the index of a mapped file section that contains the given position.
 *
 * This function searches through the sorted mapping of a file's sections
 * to identify the one that includes the specified position. It uses a binary
 * search mechanism to improve performance. If a section is found, its index
 * is returned; otherwise, -1 is returned.
 *
 * @param Pos The position in the file to search for, expressed as a long long integer.
 * @return The index of the file section containing the position, or -1 if no such section exists.
 */
#ifdef __RDOS__
int TFile::VfsFind(long long Pos)
{
    int Step = 0x80;
    int Curr = 0;
    unsigned char index;
    long long Diff;

    for (;;)
    {
        if (FMap->Update)
            RdosUpdateHandle(FHandle);

        index = FMap->SortedArr[Curr + Step];
        if (index != 0xFF)
        {
            Diff = Pos - FMap->MapArr[index].Pos;
            if (Diff >= 0)
            {
                Curr += Step;

                if (Diff < FMap->MapArr[index].Size)
                    return Curr;
            }
        }
        if (Step)
            Step = Step >> 1;
        else
            break;
    }
    return -1;
}
#endif

/**
 * Reads a specified portion of data from a virtual file system into a buffer.
 *
 * This method attempts to read `size` bytes of data starting at the given position
 * (`pos`) within the virtual file system mapped by the current file. It first checks
 * if the requested position and size are within the memory-mapped region of the file.
 * If so, it directly copies data from memory to the provided buffer. Otherwise,
 * the method utilizes lower-level file system reads.
 *
 * @param index The index of the file mapping entry to be read from.
 * @param buf A pointer to the buffer where the read data will be stored.
 * @param pos The starting position (offset) within the virtual file system to read data.
 * @param size The number of bytes to read into the buffer.
 *
 * @return The number of bytes successfully read into the buffer. Returns 0 if the requested
 *         position or size is invalid, or if no data is available to read.
 */
#ifdef __RDOS__
int TFile::VfsReadOne(int index, char *buf, long long pos, int size)
{
    long long diff;
    int count = 0;
    char *src;
    struct RdosFileMapEntry *entry;

    index = FMap->SortedArr[index];

    if (index >= 0)
    {
        entry = &FMap->MapArr[index];
        diff = pos - entry->Pos;

        if (((long)entry->Base & 0xFFF) != 0 || (entry->Size & 0xFFF) != 0)
        {
            SetPos(pos);
            count = RdosReadHandle(FHandle, buf, size);
        }
        else
        {
            if (entry->Base && diff >= 0 && diff < 0x10000000)
            {
                count = entry->Size - (int)diff;

                if (count > 0)
                {
                    src = entry->Base + (int)diff;
                    if (count > size)
                        count = size;

                    memcpy(buf, src, count);
                }
                else
                    count = 0;
            }
        }
    }

    return count;
}
#endif

/**
 * @brief Reads data from a virtual file system (VFS) into a buffer.
 *
 * This method reads a specified amount of data from the current position in the virtual
 * file system (VFS) into the provided buffer, handling advanced cases such as mapping
 * chunks of the file into memory and updating internal file position tracking.
 *
 * If the requested size exceeds the amount of available data, the method will read up
 * to the end of the file. If the file mappings need to be updated, the method attempts
 * to resolve the mappings multiple times before failing gracefully.
 *
 * @param Buf Pointer to the buffer where data will be written.
 * @param Size Number of bytes to read into the buffer.
 * @return The actual number of bytes read. If an error occurs or EOF is reached, this
 *         may be less than the requested size.
 */
#ifdef __RDOS__
int TFile::VfsRead(void *Buf, int Size)
{
    long long Pos = GetPos();
    long long TotalSize = GetSize();
    long long ldiff;
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;

    if (FMap->Update)
        RdosUpdateHandle(FHandle);

    if (Pos + Size > TotalSize)
    {
        ldiff = TotalSize - Pos;
        if (ldiff > 0x10000000)
            Size = 0x10000000;
        else
            Size = (int)ldiff;
    }

    if (Size < 0)
        Size = 0;

    RdosEnterFutex(&FMap->Handle->Futex);

    if (FLastIndex < 0)
        FLastIndex = VfsFind(Pos);

    while (Size)
    {
        if (FLastIndex >= 0)
        {
            count = VfsReadOne(FLastIndex, ptr, Pos, Size);
            ptr += count;
            Size -= count;
            ret += count;
            Pos += count;
        }

        if (Size)
        {
            for (i = 0; i < 10; i++)
            {
                RdosLeaveFutex(&FMap->Handle->Futex);

                RdosMapHandle(FHandle, Pos, Size);

                RdosEnterFutex(&FMap->Handle->Futex);
                FLastIndex = VfsFind(Pos);
                if (FLastIndex >= 0)
                    break;
            }

            if (FLastIndex < 0)
                break;
        }
    }

    RdosLeaveFutex(&FMap->Handle->Futex);

    SetPos(Pos);
    return ret;
}
#endif

/**
 * Reads data from the file into a specified buffer.
 *
 * This method attempts to read data from the current position in the file
 * into the provided buffer. The number of bytes read is determined by the
 * value of the `Size` parameter. On platforms that support RDOS, specialized
 * functions are used for file handling; otherwise, standard low-level file
 * operations are utilized.
 *
 * @param Buf A pointer to the buffer where the data will be stored. The buffer
 *            must be large enough to hold the specified number of bytes.
 * @param Size The number of bytes to read from the file into the buffer.
 * @return The number of bytes successfully read. If the end of the file is reached
 *         or an error occurs, the return value may be less than the requested size
 *         or zero.
 */
int TFile::Read(void *Buf, int Size)
{
#ifdef __RDOS__
    if (FMap)
        return VfsRead(Buf, Size);
    else
    {
        if (FHandle)
            return RdosReadHandle(FHandle, Buf, Size);
    }
#else
    if (FHandle > 0)
        return read(FHandle, Buf, Size);
#endif
    return 0;
}

/**
 * Writes data to a virtual file system entry at the specified position.
 *
 * This method updates the contents of a file or memory-mapped segment
 * based on the given buffer and its size. It determines whether
 * the data should be written directly to the file or into a mapped memory
 * region, depending on the configuration of the file mapping.
 *
 * @param index The index of the file mapping entry within the sorted array.
 * @param buf A pointer to the buffer containing the data to be written.
 * @param pos The position within the file where the write operation is to begin.
 * @param size The size of the data to write, in bytes.
 *
 * @return The number of bytes successfully written. Returns 0 if the write fails
 *         or if the specified position is outside the mapped file region.
 */
#ifdef __RDOS__
int TFile::VfsWriteOne(int index, char *buf, long long pos, int size)
{
    long long diff;
    int count = 0;
    char *dst;
    struct RdosFileMapEntry *entry;
    long long FileSize;

    index = FMap->SortedArr[index];

    if (index >= 0)
    {
        entry = &FMap->MapArr[index];
        diff = pos - entry->Pos;

        if (((long)entry->Base & 0xFFF) != 0 || (entry->Size & 0xFFF) != 0)
        {
            SetPos(pos);
            count = RdosWriteHandle(FHandle, buf, size);
        }
        else
        {
            if (entry->Base && diff >= 0 && diff < 0x10000000)
            {
                count = entry->Size - (int)diff;

                if (count > 0)
                {
                    dst = entry->Base + (int)diff;
                    if (count > size)
                        count = size;

                    memcpy(dst, buf, count);

                    FileSize = pos + count;
                    if (FileSize > FMap->Handle->ReqSize)
                        FMap->Handle->ReqSize = FileSize;
                }
                else
                    count = 0;
            }
        }
    }

    return count;
}
#endif

/**
 * Writes data from the provided buffer to the file.
 *
 * This method writes the specified number of bytes from a given buffer
 * to the file at the current file position. It handles necessary adjustments
 * such as file growth and mapping to ensure the write operation succeeds.
 * Locks are used to ensure thread safety during the operation.
 *
 * @param Buf Pointer to the buffer containing the data to be written.
 * @param Size Number of bytes to write from the buffer to the file.
 * @return The actual number of bytes successfully written to the file.
 */
#ifdef __RDOS__
int TFile::VfsWrite(const void *Buf, int Size)
{
    long long Pos = GetPos();
    long long TotalSize = GetSize();
    int count;
    int i;
    int ret = 0;
    char *ptr = (char *)Buf;
    struct RdosFileInfo *info = FMap->Info;
    long long Grow;

    if (FMap->Update)
        RdosUpdateHandle(FHandle);

    Grow = Pos + Size - info->DiscSize;
    if (Grow > 0x10000000)
        Grow = 0x10000000;

    if (Grow > 0)
        RdosGrowHandle(FHandle, info->DiscSize, (int)Grow);

    RdosEnterFutex(&FMap->Handle->Futex);

    if (FLastIndex < 0 || Grow > 0)
        FLastIndex = VfsFind(Pos);

    while (Size)
    {
        if (FLastIndex >= 0)
        {
            count = VfsWriteOne(FLastIndex, ptr, Pos, Size);
            ptr += count;
            Size -= count;
            ret += count;
            Pos += count;
        }

        if (Size)
        {
            for (i = 0; i < 10; i++)
            {
                RdosLeaveFutex(&FMap->Handle->Futex);

                Grow = Pos + Size - info->DiscSize;
                if (Grow > 0x10000000)
                    Grow = 0x10000000;

                if (Grow > 0)
                    RdosGrowHandle(FHandle, info->DiscSize, (int)Grow);
                else
                    RdosMapHandle(FHandle, Pos, Size);

                RdosEnterFutex(&FMap->Handle->Futex);
                FLastIndex = VfsFind(Pos);
                if (FLastIndex >= 0)
                    break;
            }

            if (FLastIndex < 0)
                break;
        }
    }

    RdosLeaveFutex(&FMap->Handle->Futex);

    SetPos(Pos);
    return ret;
}
#endif

/**
 * Writes data from the provided buffer to the file.
 *
 * This method writes `Size` bytes of data from the memory location pointed to by `Buf`
 * into the file associated with the TFile instance. The exact mechanism of writing
 * depends on the underlying platform and whether the file is mapped or associated
 * with a specific handle.
 *
 * @param Buf Pointer to the buffer containing the data to be written.
 * @param Size The number of bytes to write from the buffer.
 * @return The actual number of bytes written to the file. Returns 0 if the write operation fails or no data is written.
 */
int TFile::Write(const void *Buf, int Size)
{
#ifdef __RDOS__
    if (FMap)
        return VfsWrite(Buf, Size);
    else
    {
        if (FHandle)
            return RdosWriteHandle(FHandle, Buf, Size);
    }
#else
    if (FHandle > 0)
        return write(FHandle, Buf, Size);
#endif
    return 0;
}

/**
 * Writes the specified null-terminated string to the file.
 *
 * This method uses the `Write(const void *Buf, int Size)` method to write
 * the string data to the file. The length of the string is calculated
 * using `strlen` to determine how many bytes to write.
 *
 * @param str A pointer to the null-terminated string to be written.
 *            The string must not be null.
 * @return The number of bytes successfully written to the file, or
 *         0 if the file handle is invalid or the write operation fails.
 */
int TFile::Write(const char *str)
{
    return Write(str, strlen(str));
}
