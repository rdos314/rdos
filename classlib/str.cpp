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
# str.cpp
# String class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdarg.h>

#include "str.h"
#include "section.h"

#ifdef __RDOS__
#include "rdos.h"
#endif

/**
 * @brief Constructs a `TSection` object and initializes a section with the specified name.
 *
 * This instance of `TSection` is used for synchronization purposes,
 * allowing controlled access to shared resources in a multithreaded environment.
 * The section's name is used to identify and reference the section during runtime.
 *
 * @param Name A null-terminated string representing the name of the section. The name must not exceed 32 characters;
 * any longer strings will be truncated to fit within the internal buffer.
 *
 * @note The name is stored in a fixed-size internal buffer with a maximum length of 33 characters
 * (including the null-terminator).
 *
 * @warning The behavior is undefined if `Name` is a null pointer or not null-terminated.
 */
TSection Section("String");

#define ZEROPAD 1               /* pad with zero */
#define SIGN    2               /* unsigned/signed long */
#define PLUS    4               /* show plus */
#define SPACE   8               /* space if plus */
#define LEFT    16              /* left justified */
#define SPECIAL 32              /* 0x */
#define LARGE   64              /* use 'ABCDEF' instead of 'abcdef' */

/**
 * @brief Callback function used for custom printf-like behavior.
 *
 * This function appends a single character to a TString object.
 * It is designed to be used as a helper function where a callback
 * for character processing is needed.
 *
 * @param param Pointer to a TString object. This parameter is cast
 *              internally to a TString before the operation.
 * @param ch    The character to be appended to the TString object.
 */
#ifdef __RDOS__
static void PrintfCallback(void *param, char ch)
{
    TString *str = (TString *)param;
    str->Append(ch);
}

#endif

/**
 * @brief Default constructor for the TString class.
 *
 * Initializes a new instance of the TString class with no data.
 * The resulting object represents an empty string.
 *
 * @return A new TString instance with no initial content.
 */
TString::TString()
{
}

/**
 * @brief Copy constructor for the TString class.
 *
 * @details Constructs a new TString object as a copy of an existing TString object.
 *          This constructor initializes the newly constructed object by copying the
 *          data and state from the provided source object.
 *
 * @param src Reference to the TString object to be copied.
 */
TString::TString(const TString &src)
 : TShareObject(src)
{
}

/**
 * @brief Constructs a TString object by initializing it with the provided C-style string.
 *
 * @param str A pointer to a null-terminated C-style string used to initialize the TString object.
 */
TString::TString(const char *str)
 : TShareObject(str, strlen(str) + 1)
{
}

/**
 * Constructor for the TString class.
 *
 * @param str A pointer to a null-terminated character array used to initialize the string.
 * @param size The size of the string content (excluding null-terminator).
 * @return None. This is a constructor and does not return a value.
 */
TString::TString(const char *str, int size)
 : TShareObject(str, size + 1)
{
    FBuf[size] = 0;
}

/**
 * @brief Destructor for the TString class.
 *
 * The destructor releases resources associated with the TString object,
 * if any. This method ensures proper cleanup of the object upon its
 * destruction.
 */
TString::~TString()
{
}

/**
 * Allocates memory and copies a portion of the current string into the destination string.
 *
 * @param dest The destination TString object where the substring will be copied.
 * @param CopyLen The length of the substring to copy from the current string.
 * @param CopyIndex The starting index in the current string from where the copying begins.
 * @param ExtraLen Additional length to allocate in addition to the copied substring.
 */
void TString::AllocCopy(TString& dest, int CopyLen, int CopyIndex, int ExtraLen) const
{
    int NewLen = CopyLen + ExtraLen;

    dest.FSection.Enter();

    dest.AllocBuffer(NewLen + 1);
    memcpy(dest.FBuf, FBuf+CopyIndex, CopyLen);
    *(dest.FBuf+CopyLen) = 0;

    dest.FSection.Leave();
}

/**
 * Copies and concatenates two character arrays into the current string buffer.
 *
 * @param str1 Pointer to the first character array.
 * @param len1 Length of the first character array.
 * @param str2 Pointer to the second character array.
 * @param len2 Length of the second character array.
 */
void TString::ConcatCopy(const char *str1, int len1, const char *str2, int len2)
{
    int NewLen = len1 + len2;

    FSection.Enter();

    AllocBuffer(NewLen + 1);
    memcpy(FBuf, str1, len1);
    memcpy(FBuf+len1, str2, len2);
    *(FBuf+len1+len2) = 0;

    FSection.Leave();
}

/**
 * Appends a given string to the current string in place. If the current string
 * requires reallocation or the reference count is greater than one, a new backing
 * store is created.
 *
 * @param str Pointer to the string to be concatenated.
 * @param size The length of the string to be concatenated.
 */
void TString::ConcatInPlace(const char *str, int size)
{
    FSection.Enter();

    if (FData == 0)
        AssignCopy(str, size + 1);
    else
    {
        if (size)
        {
            if (FData->FRefs > 1 || FData->FDataSize + size > FData->FAllocSize)
            {
                TShareObjectData* OldData = FData;
                ConcatCopy(GetData(), GetSize(), str, size);
                Release(OldData);
            }
            else
            {
                memcpy(FBuf + FData->FDataSize - 1, str, size);
                FData->FDataSize += size;
                *(FBuf+FData->FDataSize - 1) = 0;
            }
        }
    }
    FSection.Leave();
}

/**
 * Assigns the content of the given TString object to this TString object.
 *
 * @param src The source TString object whose content will be assigned to this TString.
 * @return A reference to this TString object after assignment.
 */
const TString &TString::operator=(const TString &src)
{
    Load(src);
    return *this;
}

/**
 * Compares the current string with another string object.
 *
 * The comparison is done lexicographically. If either of the strings' buffers
 * is uninitialized, the method handles it gracefully and returns appropriate
 * comparison results.
 *
 * @param str The string object to compare with the current string.
 * @return An integer indicating the comparison result:
 *         - Returns 0 if the strings are equal.
 *         - Returns a positive value if the current string is greater.
 *         - Returns a negative value if the current string is lesser.
 */
int TString::Compare(const TShareObject &str) const
{
    int res;

    FSection.Enter();

    if (FBuf == 0 || str.FBuf == 0)
    {
        if (FBuf == 0)
        {
            if (str.FBuf == 0)
                res = 0;
            else
                res = 1;
        }
        else
            res = -1;
    }
    else
        res = strcmp(FBuf, str.FBuf);

    FSection.Leave();

    return res;
}

/**
 * Assigns the given C-style string to this TString object.
 *
 * @param str Pointer to a null-terminated C-style string to be assigned.
 * @return Reference to the updated TString object.
 */
const TString &TString::operator=(const char *str)
{
    AssignCopy(str, strlen(str) + 1);
    return *this;
}

/**
 * @brief Compares the current TString object with another TString object for equality.
 *
 * This operator checks whether the current TString object is equal to the given TString object
 * by comparing their contents.
 *
 * @param str The TString object to compare with the current object.
 * @return true if the contents of both TString objects are equal, false otherwise.
 */
bool TString::operator==(const TString &str) const
{
    if (Compare(str) == 0)
        return true;
    else
        return false;
}

/**
 * Compares the current TString object with another TString object for inequality.
 *
 * @param str The TString object to compare against.
 * @return True if the two TString objects are not equal, otherwise false.
 */
bool TString::operator!=(const TString &str) const
{
    if (Compare(str) == 0)
        return false;
    else
        return true;
}

/**
 * Compares the current TString object with another TString object to determine
 * if it is lexicographically greater.
 *
 * @param dest The TString object to compare with the current TString object.
 * @return True if the current TString object is lexicographically greater than
 *         the provided TString object, otherwise false.
 */
bool TString::operator>(const TString &dest) const
{
    if (Compare(dest) > 0)
        return true;
    else
        return false;
}

/**
 * Compares this TString object with another TString object to determine
 * if it is lexicographically less than the provided TString.
 *
 * @param dest The TString object to compare against.
 * @return true if this TString is lexicographically less than the provided TString, false otherwise.
 */
bool TString::operator<(const TString &dest) const
{
    if (Compare(dest) < 0)
        return true;
    else
        return false;
}

/**
 * Compares two TString objects to determine if the current object
 * is greater than or equal to the values of another TString object.
 *
 * @param dest The TString object to compare with the current object.
 * @return true if the current TString object is greater than or equal to dest, false otherwise.
 */
bool TString::operator>=(const TString &dest) const
{
    if (Compare(dest) >= 0)
        return true;
    else
        return false;
}

/**
 * Compares the current TString object with the given TString object to determine
 * if it is less than or equal to the other.
 *
 * @param dest The TString object to compare with the current TString object.
 * @return true if the current TString object is less than or equal to the given TString object,
 *         otherwise false.
 */
bool TString::operator<=(const TString &dest) const
{
    if (Compare(dest) <= 0)
        return true;
    else
        return false;
}

/**
 * Overloads the subscript operator to access a character at a given index.
 *
 * This method provides read-only access to the character at the specified
 * index of the string. Thread-safety is managed using internal locking mechanisms.
 *
 * @param n The index of the character to access. It must be non-negative
 *          and less than the size of the string.
 * @return The character at the specified index if the index is valid.
 *         Returns 0 if the index is out of bounds or the string data is null.
 */
char TString::operator[](int n) const
{
    char ch = 0;

    FSection.Enter();

    if (FData && FData->FDataSize > n)
        ch = FBuf[n];

    FSection.Leave();

    return ch;
}

/**
 * Concatenates two TString objects and returns the resulting TString.
 *
 * @param str1 The first TString to concatenate.
 * @param str2 The second TString to concatenate.
 * @return A new TString object that is the concatenation of str1 and str2.
 */
TString operator+(const TString& str1, const TString& str2)
{
    TString s;
    s.ConcatCopy(str1.GetData(), str1.GetSize(), str2.GetData(), str2.GetSize());
    return s;
}

/**
 * Concatenates a TString object and a C-style string, returning a new TString object.
 *
 * @param str The TString object to be concatenated.
 * @param cstr The null-terminated C-style string to be concatenated.
 * @return A new TString object that is the result of concatenating the given TString and C-style string.
 */
TString operator+(const TString& str, const char *cstr)
{
    TString s;
    s.ConcatCopy(str.GetData(), str.GetSize(), cstr, strlen(cstr));
    return s;
}

/**
 * Concatenates a C-style string with a TString object to produce a new TString.
 *
 * @param cstr A null-terminated C-style string to be concatenated.
 * @param str A reference to a TString object to be concatenated.
 * @return A new TString instance containing the result of concatenating cstr and str.
 */
TString operator+(const char *cstr, const TString& str)
{
    TString s;
    s.ConcatCopy(cstr, strlen(cstr), str.GetData(), str.GetSize());
    return s;
}

/**
 * @brief Appends a C-style string to the current TString object.
 *
 * This operator appends the content of the given null-terminated
 * character array to the existing TString, modifying the object
 * in place.
 *
 * @param str A pointer to the null-terminated C-style string to be appended.
 * @return A reference to the modified TString object.
 */
const TString &TString::operator+=(const char *str)
{
    ConcatInPlace(str, strlen(str));
    return *this;
}

/**
 * @brief Appends a single character to the end of the current TString instance.
 *
 * This operator overload appends the specified character to the current string by
 * creating a temporary string representation of the character and concatenating it
 * to the existing string in-place.
 *
 * @param ch The character to append to the string.
 * @return A reference to the updated TString instance.
 */
const TString &TString::operator+=(char ch)
{
    char str[2];

    str[0] = ch;
    str[1] = 0;

    ConcatInPlace(str, 1);
    return *this;
}

/**
 * @brief Appends the content of the given TString object to the current TString object.
 *
 * This operator modifies the current TString by appending the data contained in the
 * provided TString instance. The operation is performed in-place.
 *
 * @param str The TString object whose content will be appended.
 * @return A reference to the updated TString object.
 */
const TString &TString::operator+=(const TString& str)
{
    ConcatInPlace(str.GetData(), str.GetSize());
    return *this;
}

/**
 * @brief Resets the string to an empty state.
 *
 * This function assigns an empty value to the string object,
 * effectively clearing its contents and resetting it to its
 * default state.
 */
void TString::Reset()
{
    AssignCopy(0, 0);
}

/**
 * @brief Retrieves the character data stored in the TString object.
 *
 * This method returns a pointer to the string data managed by the TString
 * instance. If no data is stored (FBuf is null), an empty string is returned.
 *
 * @return A pointer to the stored string data, or an empty string if no data exists.
 */
const char *TString::GetData() const
{
    if (FBuf)
        return FBuf;
    else
        return "";
}

/**
 * Retrieves the size of the string stored in the TString object.
 * The size represents the count of characters in the string,
 * excluding the null terminator.
 *
 * This method ensures thread safety by using a critical section
 * to synchronize access to the underlying data.
 *
 * @return The size of the string, or 0 if no data is present.
 */
int TString::GetSize() const
{
    int size = 0;

    FSection.Enter();

    if (FData)
        size = FData->FDataSize - 1;

    FSection.Leave();

    return size;
}

/**
 * @brief Searches for the first occurrence of a specified character in the string.
 *
 * This function scans the string buffer for the first occurrence of the given character
 * and returns a pointer to its location. If the character is not found or if
 * the string buffer is null, the function returns a null pointer.
 *
 * @param ch The character to search for in the string.
 * @return A pointer to the first occurrence of the character in the string, or a null pointer if not found.
 */
const char *TString::Find(char ch) const
{
    if (FBuf)
        return strchr(FBuf, ch);
    else
        return 0;
}

/**
 * @brief Searches for the first occurrence of a specified substring within the TString object.
 *
 * This method checks if the TString object's internal buffer (FBuf) contains the
 * specified substring. If the buffer exists and the substring is found, it returns
 * a pointer to the first occurrence of the substring. Otherwise, it returns a null pointer.
 *
 * @param str The substring to search for within the TString object.
 * @return Pointer to the first occurrence of the substring in the TString object if found,
 *         or a null pointer if the substring is not found or the buffer is empty.
 */
const char *TString::Find(const char *str) const
{
    if (FBuf)
        return strstr(FBuf, str);
    else
        return 0;
}

/**
 * Converts the given character to its uppercase equivalent.
 *
 * This method utilizes the standard library function `toupper` to convert the input character
 * to uppercase. If the character has no uppercase equivalent or is not a valid alphabetic
 * character, it is returned unchanged.
 *
 * @param ch The character to convert to uppercase.
 * @return The uppercase equivalent of the input character, or the original character
 *         if no conversion is applicable.
 */
char TString::Upper(char ch)
{
    return toupper(ch);
}

/**
 * @brief Converts all characters in the string to uppercase.
 *
 * This method modifies the contents of the string by converting each
 * character to its uppercase equivalent. The operation is performed
 * in-place, meaning the original string is altered directly.
 *
 * The method ensures thread-safety by securing access to the string's
 * data using a critical section. Before applying the transformation,
 * it makes a copy of the current string if needed, to ensure the
 * string can be safely modified without affecting other references.
 *
 * If the string data is uninitialized or empty, the method does nothing.
 */
void TString::Upper()
{
    int i;
    char *ptr;

    FSection.Enter();

    CopyBeforeWrite();

    if (FData)
    {
        ptr = FBuf;
        for (i = 0; i < FData->FDataSize - 1; i++)
        {
            *ptr = Upper(*ptr);
            ptr++;
        }
    }

    FSection.Leave();
}

/**
 * Converts the given character to its lowercase equivalent if it is an uppercase letter.
 * If the character is not an uppercase letter, it is returned unchanged.
 *
 * @param ch The character to be converted to lowercase.
 * @return The lowercase equivalent of the input character if it is uppercase,
 *         otherwise the original character.
 */
char TString::Lower(char ch)
{
    return tolower(ch);
}

/**
 * @brief Converts all characters in the string to their lowercase equivalents.
 *
 * This method iterates through all characters in the internal string buffer
 * and converts each character to lowercase using the `Lower` function. The
 * operation is performed within a thread-safe critical section to ensure
 * data integrity when accessed concurrently. Before performing the conversion,
 * the function ensures the string is properly copied for modification.
 *
 * @note This method modifies the string in place.
 */
void TString::Lower()
{
    int i;
    char *ptr;

    FSection.Enter();

    CopyBeforeWrite();

    if (FData)
    {
        ptr = FBuf;
        for (i = 0; i < FData->FDataSize - 1; i++)
        {
            *ptr = Lower(*ptr);
            ptr++;
        }
    }

    FSection.Leave();
}

/**
 * @brief Removes trailing carriage return (CR) and line feed (LF) characters from the string.
 *
 * This method checks the end of the string for the presence of CR (0x0D) or LF (0x0A) characters
 * and removes them. The method ensures thread safety with the use of a section lock, and it also
 * creates a copy of the data before modifying it when necessary to preserve data integrity. If the
 * string becomes empty after CR and LF removal, the internal resources are released.
 *
 * @note This method modifies the string in place. It assumes that FBuf points to a buffer
 * containing the string data and that FData contains metadata about the string, including
 * its size (FDataSize).
 */
void TString::RemoveCrLf()
{
    char *ptr;

    FSection.Enter();

    if (FData)
    {
        ptr = FBuf + FData->FDataSize - 2;
        if (*ptr == 0xd || *ptr == 0xa)
        {
            CopyBeforeWrite();

            while (*ptr == 0xd || *ptr == 0xa)
            {
                *ptr = 0;
                FData->FDataSize--;

                if (ptr == FBuf)
                {
                    Release();
                    break;
                }
                else
                    ptr--;
            }
        }
    }

    FSection.Leave();
}

#ifndef __RDOS__

/**
 * @brief Converts an initial portion of the provided string to an integer.
 *
 * This function reads the input string and converts the leading digits into
 * an integer. It advances the string pointer past the processed digits.
 *
 * @param s A double pointer to the input string. The pointer will be updated
 *          to point to the character immediately following the last processed digit.
 * @return The integer value represented by the leading digits of the string.
 *
 * Example behavior:
 * Input string "123abc" will result in an integer value of 123, and the
 * string pointer will be updated to point to "abc".
 */
static int skip_atoi(const char **s)
{
    int i = 0;

    while (isdigit(**s))
        i = i*10 + *((*s)++) - '0';
    return i;
}

#endif

/**
 * Appends a single character to the end of this TString instance.
 *
 * @param ch The character to be appended.
 */
void TString::Append(char ch)
{
    char str[2];

    str[0] = ch;
    str[1] = 0;

    ConcatInPlace(str, 1);
}

/**
 * @brief Appends the given string to the current string.
 *
 * This method concatenates a portion of the provided string to the current
 * TString instance. The size parameter determines how many characters are
 * appended from the given string.
 *
 * @param str The string to be appended to the current TString instance.
 * @param size The number of characters to append from the provided string.
 */
void TString::Append(const char *str, int size)
{
    if (size)
    {
        ConcatInPlace(str, size);
        FBuf[FData->FDataSize - 1] = 0;
    }

}

/**
 * Replaces a single occurrence of a substring within the provided string with another substring.
 *
 * This method updates the given string by replacing an occurrence of the `src` substring
 * (starting at the pointer `ptr`) with the `dest` substring. Adjustments are made to the
 * string's internal buffer size as necessary to accommodate the new content.
 *
 * @param ptr Pointer to the starting position where the replacement should occur in the string.
 * @param src The substring to be replaced.
 * @param dest The substring to replace the `src` substring with.
 */
void TString::ReplaceOne(char *ptr, const char *src, const char *dest)
{
    int srclen = strlen(src);
    int destlen = strlen(dest);
    int i;
    int pos;
    int count;
    char *srcptr;
    char *destptr;
    char *cpyptr;

    if (srclen == destlen)
    {
        for (i = 0; i < destlen; i++)
            ptr[i] = dest[i];
    }
    else
    {
        if (srclen > destlen)
        {
            for (i = 0; i < destlen; i++)
                ptr[i] = dest[i];

            srcptr = ptr + srclen;
            destptr = ptr + destlen;

            while (*srcptr)
            {
                *destptr = *srcptr;
                srcptr++;
                destptr++;
            }
            *destptr = 0;

            FData->FDataSize = FData->FDataSize + destlen - srclen;
        }
        else
        {
            if (FData->FDataSize + destlen - srclen > FData->FAllocSize)
            {
                TShareObjectData* OldData = FData;
                cpyptr = FBuf;
                pos = ptr - FBuf;

                AllocBuffer(OldData->FDataSize + 0x10 + destlen - srclen);
                memcpy(FBuf, cpyptr, OldData->FDataSize);
                FData->FDataSize = OldData->FDataSize;
                Release(OldData);

                ptr = FBuf + pos;
            }

            srcptr = FBuf + FData->FDataSize - 1;
            destptr = srcptr + destlen - srclen;

            count = srcptr - ptr;
            count = count - srclen;
            count++;

            for (i = 0; i < count; i++)
            {
                *destptr = *srcptr;
                srcptr--;
                destptr--;
            }

            for (i = 0; i < destlen; i++)
                ptr[i] = dest[i];

            FData->FDataSize = FData->FDataSize + destlen - srclen;
        }
    }
}

/**
 * Replaces all occurrences of a specified substring within the string buffer
 * with another specified substring.
 *
 * @param src The substring to search for in the string buffer.
 * @param dest The substring to replace each occurrence of `src` with.
 */
void TString::Replace(const char *src, const char *dest)
{
    char *ptr;
    int pos;

    FSection.Enter();

    if (FData)
    {
        ptr = strstr(FBuf, src);
        while (ptr)
        {
            pos = ptr - FBuf;
            ReplaceOne(ptr, src, dest);
            ptr = FBuf + pos + strlen(dest);
            ptr = strstr(ptr, src);
        }
    }

    FSection.Leave();
}

/**
 * Appends the given null-terminated string to the end of the current TString object.
 *
 * @param str A pointer to the null-terminated string to append. This must not be null.
 */
void TString::Append(const char *str)
{
    Append(str, strlen(str));
}

#ifndef __RDOS__

/**
 * Converts a number to a string representation in the specified base, applying various formatting options.
 *
 * @param num The number to be converted to a string.
 * @param base The numerical base for the conversion (valid values are from 2 to 36).
 * @param size The minimum width of the resulting string. If the formatted string is shorter, it will be padded.
 * @param precision The minimum number of digits for the number. If the number has fewer digits, it will be zero-padded.
 * @param type A combination of flags that control formatting behavior. This may include:
 *        - LARGE: Use uppercase letters for bases 11 and higher.
 *        - LEFT: Left-align the result within the width (no padding on the right).
 *        - ZEROPAD: Pad with zeroes instead of spaces.
 *        - SIGN: Always include a sign ('+' or '-') for the number.
 *        - PLUS: Include a '+' sign for positive numbers.
 *        - SPACE: Include a space for positive numbers if no '+' sign.
 *        - SPECIAL: Include base-specific prefixes (e.g., "0x" for hexadecimal, "0" for octal).
 * @return The number of characters appended to the string as a result of the conversion.
 */
int TString::Number(long num, int base, int size, int precision, int type)
{
    char c, sign, tmp[16];
    const char *digits = "0123456789abcdefghijklmnopqrstuvwxyz";
    int i, n = 0;
    int ind;

    if (type & LARGE)
        digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    if (type & LEFT)
        type &= ~ZEROPAD;

    if (base < 2 || base > 36)
        return 0;

    c = (type & ZEROPAD) ? '0' : ' ';
    sign = 0;
    if (type & SIGN)
    {
        if (num < 0)
        {
            sign = '-';
            num = -num;
            size--;
        } else if (type & PLUS)
        {
            sign = '+';
            size--;
        } else if (type & SPACE)
        {
            sign = ' ';
            size--;
        }
    }

    if (type & SPECIAL)
    {
        if (base == 16)
            size -= 2;

        else if (base == 8)
            size--;
    }

    i = 0;
    if (num == 0)
        tmp[i++] = '0';
    else
        while (num != 0)
        {
            ind = ((unsigned long) num) % (unsigned) base;
            num = ((unsigned long) num) / (unsigned) base;
            tmp[i++] = digits[ind];
        }

    if (i > precision)
        precision = i;

    size -= precision;
    if (!(type & (ZEROPAD + LEFT)))
        while (size-- > 0)
        {
            Append(' ');
            n++;
        }

    if (sign)
    {
        Append(sign);
        n++;
    }

    if (type & SPECIAL)
    {
        if (base == 8)
        {
            Append('0');
            n++;
        } else if (base == 16)
        {
            Append('0');
            Append(digits[33]);
            n += 2;
        }
    }

    if (!(type & LEFT))
        while (size-- > 0)
        {
            Append(c);
            n++;
        }

    while (i < precision--)
    {
        Append('0');
        n++;
    }

    while (i-- > 0)
    {
        Append(tmp[i]);
        n++;
    }

    while (size-- > 0)
    {
        Append(' ');
        n++;
    }

    return n;
}

#endif

/**
 * Formats and appends a string based on a format specifier and a variable argument list.
 * The formatted output is appended to the current string content, and the method returns
 * the number of characters added.
 *
 * @param fmt The format string, which follows printf-style formatting rules.
 * @param args A variable argument list containing the values to be formatted and included
 *             in the output string, corresponding to the format specifiers in the `fmt` string.
 * @return The total number of characters that were appended to the string.
 */
int TString::prtf(const char *fmt, va_list args)
{
    int n;

    FSection.Enter();

    Release();

#ifdef __RDOS__
    n = RdosPrintf(&PrintfCallback, this, fmt, args);
#else

    unsigned long num;
    int i, base;
    const char *s;
    int len;

    int flags; /* flags to number() */

    int field_width; /* width of output field */
    int precision; /* min. # of digits for integers; max
                                   number of chars for from string */
    int qualifier; /* 'h', 'l', or 'L' for integer fields */
    /* 'z' support added 23/7/1999 S.H.    */
    /* 'z' changed to 'Z' --davidm 1/25/99 */


    for (n = 0; *fmt; ++fmt)
    {
        if (*fmt != '%')
        {
            Append(*fmt);
            n++;
            continue;
        }

        /* process flags */
        flags = 0;
    repeat:
        ++fmt; /* this also skips first '%' */
        switch (*fmt)
        {
            case '-': flags |= LEFT;
                goto repeat;
            case '+': flags |= PLUS;
                goto repeat;
            case ' ': flags |= SPACE;
                goto repeat;
            case '#': flags |= SPECIAL;
                goto repeat;
            case '0': flags |= ZEROPAD;
                goto repeat;
        }

        /* get field width */
        field_width = -1;
        if (isdigit(*fmt))
            field_width = skip_atoi(&fmt);

        else if (*fmt == '*')
        {
            ++fmt;
            /* it's the next argument */
            field_width = va_arg(args, int);
            if (field_width < 0)
            {
                field_width = -field_width;
                flags |= LEFT;
            }
        }

        /* get the precision */
        precision = -1;
        if (*fmt == '.')
        {
            ++fmt;
            if (isdigit(*fmt))
                precision = skip_atoi(&fmt);
            else if (*fmt == '*')
            {
                ++fmt;
                /* it's the next argument */
                precision = va_arg(args, int);
            }

            if (precision < 0)
                precision = 0;
        }

        /* get the conversion qualifier */
        qualifier = -1;
        if (*fmt == 'h' || *fmt == 'l' || *fmt == 'L' || *fmt == 'Z')
        {
            qualifier = *fmt;
            ++fmt;
        }

        /* default base */
        base = 10;

        switch (*fmt)
        {
            case 'c':
                if (!(flags & LEFT))
                    while (--field_width > 0)
                    {
                        Append(' ');
                        n++;
                    }

                Append((unsigned char) va_arg(args, int));
                n++;
                while (--field_width > 0)
                {
                    Append(' ');
                    n++;
                }
                continue;

            case 's':
                s = va_arg(args, char *);
                if (!s)
                    s = "<NULL>";

                len = strlen(s);
                if (precision != -1 && len > precision)
                    len = precision;

                if (!(flags & LEFT))
                    while (len < field_width--)
                    {
                        Append(' ');
                        n++;
                    }

                for (i = 0; i < len; ++i)
                {
                    Append(*s++);
                    n++;
                }

                while (len < field_width--)
                {
                    Append(' ');
                    n++;
                }
                continue;

            case 'p':
                if (field_width == -1)
                {
                    field_width = 2 * sizeof(void *);
                    flags |= ZEROPAD;
                }
                n += Number((unsigned long) va_arg(args, void *), 16,
                            field_width, precision, flags);
                continue;

            case 'n':
                if (qualifier == 'l')
                {
                    long *ip = va_arg(args, long *);
                    *ip = n;
                } else if (qualifier == 'Z')
                {
                    size_t *ip = va_arg(args, size_t *);
                    *ip = n;
                } else
                {
                    int *ip = va_arg(args, int *);
                    *ip = n;
                }
                continue;

            case '%':
                Append('%');
                n++;
                continue;

            case 'I':
            {
                union
                {
                    /**
                     * @brief A long integer variable, primarily utilized for storage or processing of numerical data.
                     *
                     * The variable `l` may hold a signed long integer value and is often employed where
                     * a larger range than standard integer types is required. Its specific purpose and
                     * usage depend on the context in which it is integrated.
                     */
                    long l;
                    /**
                     * Represents an array of 4 bytes, typically used for storing and manipulating
                     * a sequence of unsigned 8-bit integer values (unsigned char). This can often
                     * be employed for scenarios such as storing binary data, network address components
                     * or extracting byte representations of other data types.
                     */
                    unsigned char c[4];
                } u;

                u.l = va_arg(args, long);
                printf("%d.%d.%d.%d", u.c[0], u.c[1], u.c[2], u.c[3]);
            }
                continue;

            /* integer number formats - set up the flags and "break" */
            case 'o':
                base = 8;
                break;

            case 'X':
                flags |= LARGE;

            case 'x':
                base = 16;
                break;

            case 'd':
            case 'i':
                flags |= SIGN;

            case 'u':
                break;

            default:
                Append('%');
                n++;
                if (*fmt)
                {
                    Append(*fmt);
                    n++;
                } else
                    --fmt;
                continue;
        }

        if (qualifier == 'L')
            num = va_arg(args, long);
        else if (qualifier == 'l')
        {
            num = va_arg(args, unsigned long);
            if (flags & SIGN)
                num = (signed long) num;
        } else if (qualifier == 'Z')
        {
            num = va_arg(args, size_t);
        } else if (qualifier == 'h')
        {
            num = (unsigned short) va_arg(args, int);
            if (flags & SIGN)
                num = (signed short) num;
        } else
        {
            num = va_arg(args, unsigned int);
            if (flags & SIGN)
                num = (signed int) num;
        }

        n += Number(num, base, field_width, precision, flags);
    }
#endif

    FSection.Leave();

    return n;
}

/**
 * Prints formatted data to the standard output.
 *
 * @param format The format string containing plain text and format specifiers.
 * @param ... Additional arguments corresponding to the format specifiers in the format string.
 * @return The number of characters printed, or a negative value if an error occurs.
 */
int TString::printf(const char *fmt, ...)
{
    va_list args;
    int result;

    FSection.Enter();

    va_start(args, fmt);

#ifdef __RDOS__
    Release();
    result = RdosPrintf(&PrintfCallback, this, fmt, args);
#else
    result = prtf(fmt, args);
#endif
    va_end(args);

    FSection.Leave();

    return result;
}
