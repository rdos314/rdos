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
# section.h
# Critical section class
#
########################################################################*/

#ifndef _SECTION_H
#define _SECTION_H

#ifdef __RDOS__
#include "rdos.h"
#else
#include <pthread.h>
#endif

/**
 * @class TSection
 * @brief A synchronization utility for managing mutually exclusive access to shared resources.
 *
 * The TSection class provides functionality to ensure that critical sections of code
 * are accessed by only one thread at a time. It abstracts platform-specific synchronization
 * mechanisms, either using `pthread_mutex_t` on non-RDOS systems or `struct RdosFutex` on RDOS systems.
 *
 * The synchronization block is identified by a name with a maximum length of 32 characters.
 *
 * @note On RDOS systems, this class makes use of a Futex-based mechanism for synchronization.
 */
class TSection
{
public:
    TSection(const char *Name);
    ~TSection();

    void Enter() const;
    void Leave() const;

private:
#ifdef __RDOS__
 /**
  * @brief Represents a futex (fast user-space mutex) structure.
  *
  * The `RdosFutex` is used for synchronization at the user-space level to
  * avoid kernel transitions in certain operating systems (such as __RDOS__).
  * It is a lightweight mechanism designed to handle contention efficiently when
  * dealing with threads attempting to gain access to a shared resource.
  *
  * This structure is platform-specific and is typically enclosed as part of
  **/
    struct RdosFutex Futex;
#else
 /**
  * @brief Mutex used for thread synchronization.
  *
  * This mutex is used to control access to a shared resource in a multithreaded
  * environment, ensuring that only one thread can access the resource at a time.
  * It is part of the TSection class implementation on non-RDOS systems and is
  * initialized with `PTHREAD_MUTEX_INITIALIZER`. The mutex is locked and unlocked
  * using `pthread_mutex_lock` and `pthread_mutex_unlock` respectively to manage
  * critical sections.
  *
  * @note This variable is only available on systems that do not use RDOS.
  */
    mutable pthread_mutex_t Mutex;
#endif
 /**
  * @brief A fixed-size character array to store the name of a section.
  *
  * This variable is used to hold the name of a synchronization section up to 32 characters
  * long, with a null-terminating character at the end. It is initialized during the
  * construction of the TSection object and is used as a human-readable identifier in
  * certain system-specific operations.
  *
  * @note The size of the array is 33 to accommodate the null-terminator character, ensuring
  * that names with a maximum length of 32 characters are safely stored.
  */
 char FName[33];
};

#endif
