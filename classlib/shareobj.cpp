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
# shareobj.cpp
# Shareable object class
#
########################################################################*/

#include <string.h>
#include "shareobj.h"

/**
 * @brief Default constructor for TShareObject.
 *
 * Initializes an instance of the TShareObject class. This constructor
 * creates a new TSection object with the name "ShareObj" and calls the
 * Init function to initialize internal members.
 *
 * @note The TSection object acts as a synchronization mechanism, ensuring
 * thread safety when accessing shared resources within TShareObject.
 *
 * @note The Init function is responsible for initializing class members
 * such as FBuf, FData, and OnCreate to their default values.
 */
TShareObject::TShareObject()
 : FSection("ShareObj")
{
    Init();
}

/**
 * @brief Constructs a TShareObject instance and initializes it with a buffer.
 *
 * This constructor creates a TShareObject and initializes it with data provided
 * through the parameter `x`. It also sets up the internal buffer (`FBuf`) by allocating
 * the required memory and copying the input data into it. The initialization process
 * includes invoking the `Init` method to reset internal state, allocating buffer space
 * through `AllocBuffer`, and finally copying the specified data to the allocated memory.
 *
 * @param x A pointer to the data that will be used to initialize the TShareObject.
 *          The memory pointed to by this parameter is copied into the internal buffer.
 *          It is the responsibility of the caller to ensure the validity of this pointer.
 * @param size The size of the data (in bytes) provided by the parameter `x`.
 *             This value determines the amount of memory allocated for the internal buffer.
 *             A value of 0 is valid and results in an uninitialized buffer.
 */
TShareObject::TShareObject(const void *x, int size)
 : FSection("ShareObj")
{
    Init();
    
    AllocBuffer(size);
    memcpy(FBuf, x, size);
}

/**
 * @brief Constructs a new TShareObject by copying data from an existing TShareObject.
 *
 * This constructor initializes a new TShareObject instance with the data from the specified
 * source object. It ensures thread-safe access to the source object's data during the copy
 * operation, incrementing reference counters for shared resources as needed.
 *
 * @param src The source TShareObject from which data will be copied.
 *            This object provides the data and state to initialize the new object.
 *            Thread-safe access is maintained during the copying process.
 *
 * @return A new TShareObject instance, initialized with the data from the source object.
 */
TShareObject::TShareObject(const TShareObject &src)
 : FSection("ShareObj")
{
    Init();

    src.FSection.Enter();
    
    FData = src.FData;
    if (FData)
    {
        FBuf = src.FBuf;
        src.FData->FRefs++;
    }

    src.FSection.Leave();
}

/**
 * @brief Destructor for the TShareObject class.
 *
 * This destructor ensures that any resources associated with the object are
 * properly released and cleaned up. It enters a critical section to ensure
 * thread safety during the release process. This includes decrementing reference
 * counts for the associated data and destroying the data if no other references exist.
 *
 * The destructor functionality is encapsulated in the following steps:
 * - Enters the critical section by calling FSection.Enter().
 * - Invokes the Release() method to handle cleanup and reference counting.
 * - Leaves the critical section by calling FSection.Leave().
 *
 * The use of a critical section ensures that the cleanup process is thread-safe,
 * preventing race conditions in multi-threaded applications.
 */
TShareObject::~TShareObject()
{
    FSection.Enter();
    Release();
    FSection.Leave();
}

/**
 * @brief Initializes the TShareObject to its default state.
 *
 * This method sets the internal buffer pointer (FBuf), data pointer (FData),
 * and creation callback (OnCreate) to null values (0). Typically called during
 * object construction or when resetting internal state.
 */
void TShareObject::Init()
{
    FBuf = 0;
    FData = 0;
    OnCreate = 0;
}

/**
 * @brief Creates a new TShareObjectData instance with the specified size.
 *
 * Attempts to create a new TShareObjectData instance by invoking the OnCreate
 * callback if it is set. If the callback is not defined, the method allocates
 * memory directly for a TShareObjectData object of the specified size.
 *
 * @param size The size of the data buffer to be created in bytes.
 * @return A pointer to the newly created TShareObjectData instance; otherwise,
 *         null if the memory allocation fails.
 */
TShareObjectData *TShareObject::Create(int size)
{
    if (OnCreate)
        return (*OnCreate)(this, size);
    else
        return (TShareObjectData *)new char[sizeof(TShareObjectData) + size];
}

/**
 * @brief Destroys a given TShareObjectData object by deallocating its memory.
 *
 * This method is responsible for properly releasing the memory used by a
 * TShareObjectData object. It must be called when the object's reference count
 * has reached zero, ensuring that no resources are leaked.
 *
 * @param obj Pointer to the TShareObjectData object to be destroyed.
 * It must be a valid pointer to a TShareObjectData instance or nullptr.
 */
void TShareObject::Destroy(TShareObjectData *obj)
{
    delete obj;
}

/**
 * @brief Loads the data from the given TShareObject into the current object.
 *
 * This method ensures thread-safe copying of the data buffer and associated metadata
 * from the source object to the current object. The reference count of the shared data
 * is incremented during the operation to ensure proper reference tracking. If the source
 * object's buffer differs from the current object's buffer, the existing resources in
 * the current object are released before copying the new data.
 *
 * @param src The source TShareObject from which data will be loaded.
 */
void TShareObject::Load(const TShareObject &src)
{
    src.FSection.Enter();
    FSection.Enter();

    if (FBuf != src.FBuf)
    {
        Release();
        FBuf = src.FBuf;
        FData = src.FData;
        if (FData)
            FData->FRefs++;
    }

    FSection.Leave();
    src.FSection.Leave();
}

/**
 * Retrieves the size of the shared object's data.
 *
 * This method returns the size of the data managed by the shared object.
 * It ensures thread-safe access by entering and leaving a critical section.
 * If no data is present, the size will be zero.
 *
 * @return The size of the data in bytes, or 0 if no data is present.
 */
int TShareObject::GetSize() const
{
    int size = 0;

    FSection.Enter();
    
    if (FData)
        size = FData->FDataSize;

    FSection.Leave();

    return size;
}

/**
 * @brief Retrieves the data associated with the share object.
 *
 * The method provides access to the data contained within the share object.
 * Access to the data is synchronized using a section lock to ensure thread safety.
 * If no data is available, an empty pointer is returned.
 *
 * @return A pointer to the data contained within the share object. If the
 *         object does not contain data, an empty pointer is returned.
 */
const void *TShareObject::GetData() const
{
    const void *data = "";

    FSection.Enter();
    
    if (FData)
        data = FBuf;

    FSection.Leave();

    return data;
}

/**
 * @brief Sets the data for the TShareObject instance, copying the specified data into the internal buffer.
 *
 * This method ensures thread-safe access to the internal buffer and allocates sufficient memory
 * before copying the data. If the given size is zero, it will handle buffer cleanup.
 *
 * @param x A pointer to the data to be set. If `x` is nullptr, no data is copied.
 * @param size The size of the data to be copied, in bytes. If `size` is zero, any existing buffer will be released.
 */
void TShareObject::SetData(const void *x, int size)
{
    FSection.Enter();
    
    AllocBeforeWrite(size);
    if (size)
    {
        memcpy(FBuf, x, size);
        FData->FDataSize = size;
    }

    FSection.Leave();
}

/**
 * Allocates a buffer of the specified size and initializes internal structures.
 * If the size is zero, the object is initialized without allocating memory.
 * Otherwise, a new buffer is created, and necessary fields are set to their defaults.
 * The method ensures thread safety by locking and unlocking a critical section
 * during the operation.
 *
 * @param size The size of the buffer to allocate. If zero, no buffer is allocated
 *             and the object is initialized with default values.
 */
void TShareObject::AllocBuffer(int size)
{
    FSection.Enter();

    if (size == 0)
        Init();
    else
    {
        FData = Create(size);
        FData->FRefs = 1;
        FData->FDataSize = size;
        FData->FAllocSize = size;
        FBuf = (char *)FData + sizeof(TShareObjectData);
    }

    FSection.Leave();
}

/**
 * @brief Releases the resources associated with the shared object, including
 * decrementing the reference count and freeing the data if no references remain.
 *
 * The method enters a critical section to ensure thread safety, decrements the
 * reference count of the shared data, and destroys the data if the reference count
 * reaches zero. After handling the references, it reinitializes the shared object.
 * The method exits the critical section before returning.
 *
 * @details
 * - If the associated data (`FData`) is not null, the method decrements the reference
 *   count (`FRefs`) and checks if it has reached zero.
 * - When `FRefs` is zero, the method invokes `Destroy(FData)` to free the resources
 *   associated with the shared object.
 * - Finally, it calls `Init()` to reset the object state.
 *
 * This method ensures proper cleanup of shared resources to avoid memory leaks
 * or dangling references in multi-threaded environments.
 */
void TShareObject::Release()
{
    FSection.Enter();

    if (FData)
    {
        FData->FRefs--;
        if (FData->FRefs <= 0)
            Destroy(FData);
    }
    Init();

    FSection.Leave();
}

/**
 * @brief Releases a shared object and decreases its reference count.
 *
 * This method reduces the reference count of the given shared object data.
 * If the reference count becomes zero, the shared object is destroyed.
 * The operation is thread-safe as it locks the section before modifying
 * the reference count and unlocking it after completion.
 *
 * @param Data A pointer to the shared object data whose reference count
 *             needs to be decreased. If the reference count becomes zero,
 *             the object is destroyed. If null, no action is taken.
 */
void TShareObject::Release(TShareObjectData *Data)
{
    FSection.Enter();
    
    if (Data)
    {
        Data->FRefs--;
        if (Data->FRefs <= 0)
            Destroy(Data);
    }

    FSection.Leave();
}

/**
 * @brief Empties the shared object data if it is currently allocated.
 *
 * This method ensures that the object's shared data is released if it meets certain conditions.
 * The release process involves decrementing the reference count and freeing the data if no further
 * references exist.
 *
 * The method utilizes thread-safe operations by entering and leaving a critical section to
 * protect the integrity of shared data during modification.
 *
 * @details
 * The method performs the following steps:
 * - Enters the critical section using the `FSection` object.
 * - Checks if the shared data (`FData`) is not null.
 * - If shared data is present and its size (`FDataSize`) is non-zero:
 *   - Checks if the reference count (`FRefs`) is greater than or equal to zero.
 *   - Calls the `Release` method to decrement the reference count and potentially destroy
 *     the shared data.
 * - Leaves the critical section after the operations are complete.
 */
void TShareObject::Empty()
{
    FSection.Enter();
    
    if (FData)
    {
        if (FData->FDataSize)
        {
            if (FData->FRefs >= 0)
                Release();
        }
    }

    FSection.Leave();
}

/**
 * @brief Creates a private copy of the shared data buffer before modifying it.
 *
 * The `CopyBeforeWrite` method ensures that any modifications to the shared data
 * occur on a private copy rather than on the shared buffer. If the shared buffer
 * is referenced by more than one owner (i.e., `FRefs > 1`), it performs the following:
 * - Creates a duplicate of the shared data buffer.
 * - Decrements the reference count of the shared buffer and releases it if applicable.
 * - Allocates a new buffer and copies the content of the original shared buffer to it.
 *
 * The method uses a critical section to ensure thread safety during the buffer duplication
 * and ensures that sensitive operations are protected from concurrent access.
 *
 * @note If the `FRefs` count is 1 or the buffer is `nullptr`, no duplication occurs.
 *
 * @pre The `TSection::Enter()` method is called to enter the critical section.
 * @post The `TSection::Leave()` method is called to leave the critical section.
 */
void TShareObject::CopyBeforeWrite()
{
    TShareObjectData* OldData;
    char* OldBuf;

    FSection.Enter();

    if (FData)
    {
        if (FData->FRefs > 1)
        {
            OldData = FData;
            OldBuf = FBuf;
            Release();
            AllocBuffer(OldData->FDataSize);
            memcpy(FBuf, OldBuf, OldData->FDataSize);
        }
    }

    FSection.Leave();
}

/**
 * @brief Allocates or re-allocates memory for internal buffer before modifying the shared object.
 *
 * The method ensures that the internal buffer of the shared object is safe to modify,
 * either by releasing unnecessary resources or allocating a new buffer with the required size.
 * It is thread-safe as it employs a synchronization mechanism to avoid concurrent modification.
 *
 * @param size The required size of the buffer. If the size is 0, the internal buffer is released.
 *             If the size exceeds the current allocated size or the buffer is shared
 *             by multiple references, a new buffer is allocated.
 */
void TShareObject::AllocBeforeWrite(int size)
{
    FSection.Enter();
    
    if (FData)
    {
        if (size == 0)
            Release();
        else
        {
            if (FData->FRefs > 1 || size > FData->FAllocSize)
            {
                Release();
                AllocBuffer(size);
            }
        }
    }
    else
        if (size)
            AllocBuffer(size);

    FSection.Leave();
}

/**
 * @brief Copies data into the shared object with thread-safe operations.
 *
 * This method assigns a copy of the provided data buffer to the shared object's
 * internal buffer. It ensures thread safety by acquiring a lock on the shared
 * resource before modifying its contents. If necessary, memory is reallocated
 * to fit the specified size, and the object's reference count is managed to
 * handle concurrent access.
 *
 * @param x Pointer to the source data buffer to be copied.
 * @param size The size (in bytes) of the data to be copied. If size is 0, the
 *             object's buffer is released.
 */
void TShareObject::AssignCopy(const void *x, int size)
{
    FSection.Enter();

    AllocBeforeWrite(size);
    if (size)
    {
        memcpy(FBuf, x, size);
        FData->FDataSize = size;
    }

    FSection.Leave();
}

/**
 * @brief Compares the current TShareObject instance with another TShareObject instance.
 *
 * This function performs a byte-by-byte comparison of the data buffers of the current
 * instance and the specified TShareObject instance. It considers the size of data
 * buffers and their content for the comparison.
 *
 * @param n2 The TShareObject instance to compare with.
 * @return
 * - 0 if both instances are equal (data content and size are the same).
 * - A negative value if the current instance is smaller than `n2` (either in terms
 *   of data content or buffer size if contents are identical up to the compared size).
 * - A positive value if the current instance is greater than `n2` (either in terms
 *   of data content or buffer size if contents are identical up to the compared size).
 *
 * @note This method is thread-safe and ensures concurrent access protection by
 *       entering and leaving critical sections for both instances during the
 *       comparison operation.
 */
int TShareObject::Compare(const TShareObject &n2) const
{
    int size;
    int res;
    int ret;
    int size1;
    int size2;

    n2.FSection.Enter();
    FSection.Enter();

    size1 = FData->FDataSize;
    size2 = n2.FData->FDataSize;

    if (size1 > size2)
        size = size2;
    else
        size = size1;

    res = memcmp(FBuf, n2.FBuf, size);
    if (res == 0)
    {
        if (size1 == size2)
            ret = 0;
        else
        {
            if (size1 > size2)
                ret = 1;
            else
                ret =  -1;
        }
    }
    else
        ret = res;

    FSection.Leave();
    n2.FSection.Leave();

    return ret;
}

/**
 * @brief Overloaded assignment operator for the TShareObject class.
 *
 * This operator copies the data and buffer from the source `TShareObject`
 * (referred to as `src`) to the current object, ensuring proper reference
 * counting and mutual exclusion for thread safety.
 *
 * The source and destination objects' critical sections are locked to
 * prevent concurrent access and ensure safe operation. If the buffer (FBuf)
 * of the current object is different from that of the source, the existing
 * resources are released, and the new buffer and data structure are assigned.
 * Reference counting is updated to reflect the reference to the shared resources.
 * Finally, the lock is released for both the current and source objects.
 *
 * @param src The source object to assign from.
 * @return A reference to the current object after assignment.
 */
const TShareObject &TShareObject::operator=(const TShareObject &src)
{
    src.FSection.Enter();
    FSection.Enter();
    
    if (FBuf != src.FBuf)
    {
        
        Release();
        FBuf = src.FBuf;
        FData = src.FData;
        if (FData)
            FData->FRefs++;

    }
    
    FSection.Leave();
    src.FSection.Leave();
    
    return *this;
}

/**
 * @brief Compares two TShareObject instances for equality.
 *
 * The equality comparison is performed based on the result of the Compare method.
 * If the Compare method returns 0, the two instances are considered equal.
 *
 * @param ln The TShareObject instance to compare with the current instance.
 * @return true if the two TShareObject instances are equal, false otherwise.
 */
bool TShareObject::operator==(const TShareObject &ln) const
{
    if (Compare(ln) == 0)
        return true;
    else
        return false;
}

/**
 * @brief Compares two TShareObject instances for inequality.
 *
 * This operator checks if the current TShareObject instance is not
 * equal to the specified TShareObject instance by internally using
 * the Compare function. If the Compare function returns 0, the two
 * instances are considered equal, and this operator will return false.
 * Otherwise, it returns true.
 *
 * @param ln The TShareObject instance to compare with the current instance.
 * @return true if the two TShareObject instances are not equal, false otherwise.
 */
bool TShareObject::operator!=(const TShareObject &ln) const
{
    if (Compare(ln) == 0)
        return false;
    else
        return true;
}

/**
 * @brief Compares the current TShareObject instance with another to determine if it is greater.
 *
 * This operator overload performs a comparison between the current object and the specified object
 * using the Compare method. It returns true if the current instance is greater than the specified
 * instance, and false otherwise.
 *
 * @param dest The TShareObject instance to compare against.
 * @return True if the current instance is greater than the specified instance, false otherwise.
 */
bool TShareObject::operator>(const TShareObject &dest) const
{
    if (Compare(dest) > 0)
        return true;
    else
        return false;
}

/**
 * @brief Compares two TShareObject instances to determine if the current object is less than the provided object.
 *
 * This operator evaluates the current TShareObject against the specified `dest` object using the Compare method.
 * It returns true if the current object is considered less than the `dest` object, and false otherwise.
 *
 * @param dest The TShareObject instance to compare against.
 * @return A boolean value indicating whether the current object is less than the specified object.
 */
bool TShareObject::operator<(const TShareObject &dest) const
{
    if (Compare(dest) < 0)
        return true;
    else
        return false;
}

/**
 * @brief Compares the current TShareObject with another to determine if it is greater than or equal to the specified object.
 *
 * This operator performs a comparison between the current instance and the provided `dest` object by calling the
 * `Compare` method. If the result of the comparison is greater than or equal to zero, the method returns true,
 * indicating that the current object is either greater than or equal to the specified object. Otherwise, it returns false.
 *
 * @param dest The TShareObject instance to compare with the current object.
 * @return true if the current object is greater than or equal to `dest`, false otherwise.
 */
bool TShareObject::operator>=(const TShareObject &dest) const
{
    if (Compare(dest) >= 0)
        return true;
    else
        return false;
}

/**
 * @brief Compares the current TShareObject with another TShareObject for less-than-or-equal-to relation.
 *
 * This operator determines if the current TShareObject is less than or equal to the specified TShareObject
 * by performing a comparison using the Compare method.
 *
 * @param dest The TShareObject to compare with the current object.
 * @return true if the current TShareObject is less than or equal to the specified TShareObject, false otherwise.
 */
bool TShareObject::operator<=(const TShareObject &dest) const
{
    if (Compare(dest) <= 0)
        return true;
    else
        return false;
}
