/* Copyright (C) 2014 by John Cronin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <efi.h>
#include <efilib.h>

void *malloc(int size)
{
        void *buf;
        EFI_STATUS s = BS->AllocatePool(EfiLoaderData, (UINTN)(size + sizeof(int)), &buf);
        if(EFI_ERROR(s))
        {
                fprintf(stderr, "malloc(%d) failed: %d\n", size, s);
                return NULL;
        }
        else
        {
                //fprintf(stderr, "malloc(%d) succeeded: returning %x\n", size, buf);
                *(int *)buf = size;
                return (void *)((uintptr_t)buf + sizeof(int));
        }
}

void *calloc(int nmemb, int size)
{
        void *buf = malloc(size * nmemb);
        if(buf == NULL)
                return NULL;

        memset(buf, 0, size * nmemb);
        return buf;
}

void *realloc(void *ptr, int size)
{
        if(ptr == NULL)
                return malloc(size);
        if(size == 0)
        {
                free(ptr);
                return NULL;
        }

        /* Get the size of the current buffer */
        int cur_buf_size = *(int *)((uintptr_t)ptr - sizeof(int));
        
        /* If new size is smaller, do nothing */
        if(size <= cur_buf_size)
                return ptr;

        /* Else, allocate a new buffer and copy the data there */
        void *buf;
        EFI_STATUS s = BS->AllocatePool(EfiLoaderData, (UINTN)size + sizeof(int), &buf);
        if(EFI_ERROR(s))
                return NULL;

        *(int *)buf = size;
        memcpy((void *)((uintptr_t)buf + sizeof(int)), ptr, cur_buf_size);
        free(ptr);
        return (void *)((uintptr_t)buf + sizeof(int));
}

void free(void *buf)
{
        if(buf == NULL)
                return;
        BS->FreePool((void *)((uintptr_t)buf - sizeof(int)));
}
