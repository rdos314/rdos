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
# shareobj.h
# Shareable object class
#
########################################################################*/

#ifndef _SHAREOBJ_H
#define _SHAREOBJ_H

#include "section.h"

/**
 * @class TShareObjectData
 * @brief Represents the internal data structure for shared objects, used by the TShareObject class.
 *
 * This class contains metadata about a shared object, including reference count,
 * allocated size, and actual data size. Instances of this class are meant to be
 * managed and manipulated internally by TShareObject to handle memory allocation
 * and reference counting in a shared object context.
 *
 * @note This class is a friend of TShareObject and TString, allowing those classes
 *       direct access to its members. It is not intended for standalone use.
 */
class TShareObjectData
{
    /**
     * @class TShareObject
     * @brief Represents a shared object that manages data and provides mechanisms for
     *        reference counting, data manipulation, and comparison.
     *
     * TShareObject is designed to handle reference counting for shared data, allowing
     * multiple objects to access the same data without the need for redundant copies.
     * It provides methods to allocate, release, and manipulate data while ensuring
     * proper memory management. The class also supports comparison operators for
     * object equivalence and ordering.
     *
     * The class is extensible and allows derived classes to override specific behavior,
     * such as destruction of shared data. A protected function pointer (`OnCreate`)
     * is available for customized creation of shared data objects.
     *
     * Key features include:
     * - Reference counting for shared data.
     * - Data allocation, copying, and comparison support.
     * - Thread safety through internal usage of TSection.
     * - Virtual methods for customization in derived classes.
     */
    friend class TShareObject;
    /**
     * @class TString
     * @brief Represents a string type that offers additional functionalities for memory management and shared behavior.
     *
     * The TString class facilitates advanced string manipulation and memory handling mechanisms.
     * It has been declared as a friend class within specific underlying supportive classes to
     * allow for close integration, particularly for operations requiring access to private or
     * protected members of related classes. TString may interoperate with internal shared
     * objects to optimize resource usage and support dynamic allocation strategies.
     *
     * @note This class has friend-level access to TShareObjectData and can operate
     *       directly with its internal members for memory and reference management.
     */
    friend class TString;
    /**
     * @var FRefs
     * @brief Reference counter for shared objects.
     *
     * This variable keeps track of the number of references to a shared object. It is incremented
     * when a new reference to the object is created and decremented when a reference is released.
     * When the counter reaches zero, the associated object is destroyed.
     *
     * @note Managed internally by the TShareObject and TShareObjectData classes to ensure proper
     * memory management for shared data buffers.
     */
public:
    int FRefs;
    /**
     * @brief Represents the size of the user data stored within the shared object.
     *
     * The `FDataSize` variable specifies the amount of data, in bytes, that is
     * currently used in the shared object's buffer. It is updated whenever data
     * is set or modified in the buffer and reflects the actual size of meaningful
     * content, excluding any additional allocated space.
     *
     * @note This variable is managed internally by the `TShareObject` class and
     * its associated methods, ensuring proper synchronization and updates
     * in multi-threaded environments using the `TSection` synchronization mechanism.
     */
    int FDataSize;
    /**
     * @brief Represents the allocation size for a shared object buffer.
     *
     * This variable specifies the total memory allocated for storing data in the
     * associated shared object. It is typically used to manage and track the size
     * of the allocated memory during buffer operations like creation, reallocation,
     * and release.
     *
     * The value of `FAllocSize` is updated when a new buffer is allocated or resized,
     * and it ensures that memory operations are performed within the allocated bounds.
     * It plays a critical role in preventing buffer overflows and managing efficient
     * memory usage for the `TShareObjectData` structure.
     *
     * @note `FAllocSize` is expressed in bytes.
     */
    int FAllocSize;
};

/**
 * @class TShareObject
 * @brief Represents a shared object that handles data sharing and reference counting.
 *
 * The TShareObject class provides functionalities to manage shared memory
 * across objects, with support for reference counting to handle memory lifecycle.
 * It includes comparison operators for object comparison and methods for
 * managing and manipulating the underlying shared data.
 *
 * The class is thread-safe with synchronization mechanisms when accessing
 * or modifying shared data.
 */
class TShareObject
{
friend class TStorageListNode;
friend class TString;
public:
	TShareObject();
	TShareObject(const void *x, int size);
	TShareObject(const TShareObject &source);
	virtual ~TShareObject();

	const TShareObject &operator=(const TShareObject &src);
	bool operator==(const TShareObject &dest) const;
	bool operator!=(const TShareObject &dest) const;
	bool operator>(const TShareObject &dest) const;
	bool operator>=(const TShareObject &dest) const;
	bool operator<(const TShareObject &dest) const;
	bool operator<=(const TShareObject &dest) const;

	int GetSize() const;
	const void *GetData() const;
	void SetData(const void *x, int size);

	virtual int Compare(const TShareObject &n2) const;

    void Load(const TShareObject &src);

protected:

/**
 * @function Create
 * @brief Creates a new instance of shared object data with a specified size.
 *
 * This function initializes a TShareObjectData instance by either invoking
 * a user-defined creation callback, if provided, or allocating memory directly
 * for the object. The allocated memory includes additional space for the requested
 * size.
 *
 * @param size The size of the additional memory to be allocated for the shared object.
 * @return A pointer to the newly created TShareObjectData instance.
 *
 * @note If the `OnCreate` callback function is defined, it is executed to handle
 *       the creation process. Otherwise, memory is directly allocated for the object.
 */
    TShareObjectData *Create(int size);

/**
 * @brief Destroys a shared object data instance, releasing its allocated memory.
 *
 * This method is used to safely delete a TShareObjectData instance and free its associated resources.
 * It is intended for internal use by the TShareObject class to ensure proper memory management
 * of shared object metadata.
 *
 * @param obj Pointer to the TShareObjectData instance to be destroyed.
 *
 * @note This method assumes that the passed `obj` parameter is a valid pointer.
 *       The method is protected and intended to be called only within the context
 *       of TShareObject or its friend classes.
 */
virtual void Destroy(TShareObjectData *obj);

/**
 * @brief Initializes the internal state of the TShareObject instance.
 *
 * This method is responsible for resetting the internal member variables of
 * the TShareObject. It sets the internal buffer pointer (`FBuf`), the data
 * reference (`FData`), and the creation callback (`OnCreate`) to their default
 * initial values. It is used as a common initialization routine across
 * various constructors and methods to ensure the object starts in a consistent state.
 *
 * @note This method is primarily called internally by the TShareObject class
 *       during construction and within other methods requiring reinitialization,
 *       and it is not intended to be called directly by external code.
 */
void Init();

/**
 * @brief Allocates and initializes a buffer for the shared object of the given size.
 *
 * This method manages the allocation and initialization of the internal buffer used
 * for storing data in a shared object. It ensures thread safety by utilizing a section
 * lock and handles cases where the requested size is zero. If a non-zero size is
 * specified, a new data buffer is created, with its metadata initialized, including
 * reference count, data size, and allocated size.
 *
 * @param size The size of the buffer to be allocated. If set to 0, the internal state
 *             is reinitialized. A positive value indicates the size of the buffer
 *             to be created.
 */
void AllocBuffer(int size);

/**
 * @brief Releases the resources held by the current shared object and handles reference count decrement.
 *
 * This method ensures that the underlying shared data is properly released when
 * no other objects reference it. If the reference count (FRefs) of the associated data
 * (FData) reaches zero, the `Destroy` method is invoked to free the memory.
 * After releasing or destroying the data, the shared object is reinitialized to
 * a safe, empty state by calling the `Init` method.
 *
 * @note Access to this method is thread-safe as it uses the FSection to synchronize
 *       entry and exit from the critical section.
 *
 * @warning Improper usage may lead to data corruption or memory leaks. Ensure that
 *          this method is only used as part of controlled object lifecycle management.
 */
void Release();

/**
 * @brief Empties the current shared object's data and releases its allocated resources if necessary.
 *
 * This method ensures thread-safe execution by acquiring and releasing a lock on the shared object's
 * critical section. If the internal data buffer (`FData`) exists and has a non-zero size, the method
 * reduces the reference count and releases the resources (via `Release()`) if the reference count
 * is non-negative.
 *
 * @note This operation is crucial for managing the lifecycle of shared object data to ensure
 *       proper memory management and avoid resource leaks. It leaves the object in a state
 *       where its data is empty and no resources are held.
 */
void Empty();

/**
 * @brief Releases a shared object's internal data and manages its reference count.
 *
 * This method decreases the reference count of the provided shared object data.
 * When the reference count reaches zero, the associated memory is destroyed.
 * Access to this method is managed using a synchronization mechanism to ensure
 * thread safety during operations.
 *
 * @param Data Pointer to the TShareObjectData instance whose reference count is
 *        being decremented. If the pointer is null, no action is taken.
 */
void Release(TShareObjectData *Data);

/**
 * @brief Ensures that the internal data of the shared object is copied before modifying it.
 *
 * This method is a key part of the copy-on-write mechanism used by TShareObject.
 * If the shared data object is being referenced by multiple instances, a new copy
 * of the data is created to ensure that modifications do not affect other instances.
 * The method handles memory allocation and data copying as needed to maintain data isolation.
 *
 * @note This method is thread-safe, utilizing a critical section (FSection) to protect
 *       the integrity of shared resources during processing.
 */
void CopyBeforeWrite();

/**
 * @brief Allocates memory for the shared object before modifying its data, ensuring proper reference management.
 *
 * This method is invoked to prepare the shared object for write operations by allocating or re-allocating
 * memory if necessary. It ensures that the modifications do not affect other instances sharing
 * the same buffer, maintaining the integrity of the data. If the size is zero, it releases the
 * existing buffer. Otherwise, it handles scenarios where the current buffer is insufficient or
 * shared with other references.
 *
 * @param size The required size of the buffer in bytes. If 0, the current buffer is released.
 */
void AllocBeforeWrite(int size);

/**
 * @brief Assigns a copy of the given data to the shared object, replacing its current contents.
 *
 * This method overwrites the internal buffer of the TShareObject instance with the contents
 * provided in the input parameters. The method ensures thread safety and allocates new memory
 * if necessary before writing the data.
 *
 * @param x A pointer to the source data to copy into the shared object. This should not be null
 *          if a non-zero size is specified.
 * @param size The size, in bytes, of the data to copy. A value of 0 indicates no data will be copied.
 */
void AssignCopy(const void *x, int size);

/**
 * @var OnCreate
 * @brief Pointer to a function invoked during the creation of a shared object.
 *
 * This function pointer defines the behavior for initializing a new TShareObjectData instance
 * when a shared object is created. The provided function is expected to allocate and initialize
 * a TShareObjectData structure tailored to the specific shared object.
 *
 * @param obj A pointer to the TShareObject instance being created.
 * @param size The size of the data to be associated with the shared object.
 * @return A pointer to the newly created TShareObjectData instance.
 *
 * @note This member allows customization of how shared object data is constructed, supporting
 *       flexible memory allocation strategies and initialization routines for derived behaviors.
 */
TShareObjectData* (*OnCreate)(TShareObject *obj, int size);

/**
 * @var char* FBuf
 * @brief Pointer to a dynamically allocated buffer used for storing object data.
 *
 * This member acts as a flexible data buffer within the TShareObject class, enabling
 * the management of data storage, copying, and shared access processes. It is used
 * internally to hold the memory region containing the actual data for shared objects.
 *
 * The FBuf buffer is allocated, assigned, and released depending on the object's lifecycle
 * and operations such as copying, loading, or modifying data. It plays a crucial role in
 * ensuring the proper handling of object data and maintaining the consistency of shared
 * objects managed by TShareObject.
 *
 * @note FBuf is initialized and manipulated by methods such as Init(), AllocBuffer(),
 *       Release(), and Load(), and its proper handling is integral to object data
 *       integrity and memory management.
 */
char *FBuf;
/**
 * @var TShareObjectData* FData
 * @brief Pointer to the internal data structure for managing shared object information.
 *
 * FData is a protected member of the TShareObject class, referencing an instance
 * of TShareObjectData. This pointer is utilized for handling metadata storage,
 * reference counting, and other internal mechanisms essential for the management
 * of shared objects. It plays a vital role in ensuring efficient memory usage
 * and object sharing within the framework.
 *
 * @warning Direct access or modification of this member outside of TShareObject
 *          is not recommended, as it could violate the integrity of shared object
 *          management.
 */
TShareObjectData *FData;
/**
 * @var TSection FSection
 * @brief Synchronization section for thread-safe operations within TShareObject.
 *
 * This variable represents a section, implemented by the TSection class, used to
 * ensure thread-safe access and manipulation of shared object data within the
 * TShareObject class. It serves as a critical section guard to control concurrent
 * access to shared resources by multiple threads.
 *
 * The FSection is initialized with the name "ShareObj" to provide an identifiable
 * context for debugging or system-specific tracking mechanisms. It leverages platform-dependent
 * synchronization primitives (such as pthread_mutex_t or RdosFutex) internally to
 * manage thread access effectively.
 *
 * @note The FSection plays an integral role in the safe copying and reference management
 *       of shared object data, ensuring data integrity and preventing race conditions.
 */
TSection FSection;
};

#endif
