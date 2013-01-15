#include "string.h"

#undef RDOSAPI
#define RDOSAPI static inline volatile __attribute__ ((always_inline))

struct futex_struc
{
    int handle;
    int count;
    short int val;
    short int owner;
    int sign;
};

#define FUTEX_STRUC_SIZE    16
#define FUTEX_STRUC_SHIFT   4
#define FUTEX_LINEAR        0x1FFC0000000
#define FUTEX_SIGN          0xADE35AFE
#define FUTEX_HANDLE_BIAS   0x3AB50000
#define MAX_FUTEX_COUNT     0x10000

#ifdef __x86_64__

#define RdosClobberSyscall \
  asm volatile ( \
    "\n\t" \
     : : : "rcx", "r9", "r11", "r14", "cc" \
   );

#define RdosClobberSyscallRdi \
  asm volatile ( \
    "\n\t" \
     : : : "rcx", "rdi", "r9", "r11", "r14", "cc" \
   );

#define RdosCleanupFutex(index) do { \
  register int _id asm("r14") = usergate_cleanup_futex; \
  register typeof(index) _rax asm("rax") = (index); \
  asm volatile( \
    "syscall\n\t" \
    : : "r" (_id), "r" (_rax) : "rbx", "rdx", "rsi", "rdi" \
  ); \
  RdosClobberSyscall; \
} while(0);

#define RdosAcquireFutex(index) do { \
  register int _id asm("r14") = usergate_acquire_futex; \
  register typeof(index) _rax asm("rax") = (index); \
  register char * _fp = FUTEX_LINEAR + ((index) << 4); \
  asm volatile( \
    "movq %%rsp,%%rdx\n\t" \
    "shrq $30,%%rdx\n\t" \
    "cmpw 10(%2),%%dx\n\t" \
    "jne 1f\n\t" \
    "incl 4(%2)\n\t" \
    "jmp 4f\n\t" \
    "1: \n\t" \
    "lock\n\t" \
    "addw $1, 8(%2)\n\t" \
    "jc 2f\n\t" \
    "movw $1,%%di\n\t" \
    "xchgw 8(%2), %%di\n\t" \
    "cmpw $0xFFFF, %%di\n\t" \
    "jne 3f\n\t" \
    "2: \n\t" \
    "movw %%dx,10(%2)\n\t" \
    "movl $1,4(%2)\n\t" \
    "jmp 4f\n\t" \
    "3: \n\t" \        
    "syscall\n\t" \
    "4: \n\t" \    
    : : "r" (_id), "r" (_rax), "r" (_fp) : "rbx", "rdx", "rsi", "rdi" \
  ); \
  RdosClobberSyscall; \
} while(0);

#define RdosReleaseFutex(index) do { \
  register int _id asm("r14") = usergate_release_futex; \
  register typeof(index) _rax asm("rax") = (index); \
  register char * _fp = FUTEX_LINEAR + ((index) << 4); \
  asm volatile( \
    "movq %%rsp,%%rdx\n\t" \
    "shrq $30,%%rdx\n\t" \
    "cmpw 10(%2),%%dx\n\t" \
    "jne 1f\n\t" \
    "subl $1,4(%2)\n\t" \
    "jnz 1f\n\t" \
    "movw $0,10(%2)\n\t" \
    "lock\n\t" \
    "subw $1, 8(%2)\n\t" \
    "jc 1f\n\t" \
    "movw $0xFFFF, 8(%2)\n\t" \
    "syscall\n\t" \
    "1: \n\t" \    
    : : "r" (_id), "r" (_rax), "r" (_fp) : "rbx", "rdx", "rsi", "rdi" \
  ); \
  RdosClobberSyscall; \
} while(0);

#define RdosTryAcquireFutex(index, res) do { \
  register char * _fp = FUTEX_LINEAR + ((index) << 4); \
  asm volatile( \
    "movq %%rsp,%%rdx\n\t" \
    "shrq $30,%%rdx\n\t" \
    "cmpw 10(%1),%%dx\n\t" \
    "jne 1f\n\t" \
    "incl 4(%1)\n\t" \
    "jmp 3f\n\t" \
    "1: \n\t" \
    "lock\n\t" \
    "addw $1, 8(%1)\n\t" \
    "jc 2f\n\t" \
    "movw $1,%%ax\n\t" \
    "xchgw 8(%1), %%ax\n\t" \
    "cmpw $0xFFFF, %%ax\n\t" \
    "jne 4f\n\t" \
    "2: \n\t" \
    "movw %%dx,10(%1)\n\t" \
    "movl $1,4(%1)\n\t" \
    "3: \n\t" \ 
    "movq $1,%%rax\n\t" \ 
    "jmp 5f\n\t" \
    "4: \n\t" \        
    "xorq %%rax,%%rax\n\t" \
    "5: \n\t" \  
    : "=a" (res) : "r" (_fp) : "rdx", "cc" \
  ); \
} while(0);

#define RdosUserGateRetEax(nr, res) do { \
  register int _id asm("r14") = nr; \
  asm volatile( \
    "syscall\n\t" \
    : "=a" (res) : "r" (_id) : "rbx", "rdx", "rsi", "rdi" \
  ); \
  RdosClobberSyscall; \
} while(0);

#define RdosUserGateEdiEcxPar0RetEbx(nr, rdi, rcx, size, res) do { \
  register int _id asm("r14") = nr; \
  register typeof(rdi) _rdi asm("rdi") = (rdi); \
  register typeof(rcx) _rcx asm("r8") = (rcx); \
  register int _size asm("r12") = (size); \
  asm volatile ( \
    "syscall\n\t" \
    "jc 1f\n\t" \
    "movzx %%bx,%%rax\n\t" \
    "jmp 2f\n\t" \
    "1: \n\t" \
    "xorq %%rax,%%rax\n\t" \
    "2: \n\t" \
    : "=a" (res) : "r" (_id), "r" (_rdi), "r" (_rcx), "r" (_size) : "rbx", "rdx", "rsi" \
  ); \
  RdosClobberSyscallRdi; \
} while(0);

#define RdosUserGateEbxEdiEcxParRetEax(nr, rbx, rdi, rcx, res) do { \
  register int _id asm("r14") = nr; \
  register typeof(rbx) _rbx asm("rbx") = (rbx); \
  register typeof(rdi) _rdi asm("rdi") = (rdi); \
  register typeof(rcx) _rcx asm("r8") = (rcx); \
  register int _size asm("r12") = (rcx); \
  asm volatile ( \
    "syscall\n\t" \
    "jnc 1f\n\t" \
    "xorq %%rax,%%rax\n\t" \
    "1: \n\t" \
    : "=a" (res) :  "r" (_id), "r" (_rbx), "r" (_rdi), "r" (_rcx), "r" (_size) : "rdx", "rsi" \
  ); \
  RdosClobberSyscallRdi; \
} while(0);

#define RdosUserGateEbx(nr, rbx) do { \
  register int _id asm("r14") = nr; \
  register typeof(rbx) _rbx asm("rbx") = (rbx); \
  asm volatile ( \
    "syscall\n\t" \
    : : "r" (_id), "r" (_rbx) : "rax", "rdx", "rsi", "rdi" \
  ); \
  RdosClobberSyscall; \
} while(0);

#else

#define RdosUserGateRetEax(nr, res) do { \
  asm volatile( \
    ".byte 0x67\n\t" \
    ".byte 0x9A\n\t" \
    ".long %0\n\t" \
    ".word 0x3\n\t" \
    : "=a" (res) : "n" (nr) : "cc" \
  ); \
} while(0);

#define RdosUserGateEdiEcxRetEbx(nr, edi, ecx, res) do { \
  register typeof(edi) _edi asm("edi") = (edi); \
  register typeof(ecx) _ecx asm("ecx") = (ecx); \
  asm volatile ( \
    ".byte 0x67\n\t" \
    ".byte 0x9A\n\t" \
    ".long %0\n\t" \
    ".word 0x3\n\t" \
    "jc 1f\n\t" \
    "movzx %%bx,%%eax\n\t" \
    "jmp 2f\n\t" \
    "1: \n\t" \
    "xorl %%eax,%%eax\n\t" \
    "2: \n\t" \
    : "=a" (res) :  "n" (nr), "r" (_edi), "r" (_ecx) : "cc" \
  ); \
} while(0);

#define RdosUserGateEbxEdiEcxParRetEax(nr, ebx, edi, ecx, res) do { \
  register typeof(ebx) _ebx asm("ebx") = (ebx); \
  register typeof(edi) _edi asm("edi") = (edi); \
  register typeof(ecx) _ecx asm("ecx") = (ecx); \
  asm volatile ( \
    ".byte 0x67\n\t" \
    ".byte 0x9A\n\t" \
    ".long %0\n\t" \
    ".word 0x3\n\t" \
    "jnc 1f\n\t" \
    "xorl %%eax,%%eax\n\t" \
    "1: \n\t" \
    : "=a" (res) :  "n" (nr), "r" (_ebx), "r" (_edi), "r" (_ecx) : "cc" \
  ); \
} while(0);

#define RdosUserGateEbx(nr, ebx) do { \
  register typeof(ebx) _ebx asm("ebx") = (ebx); \
  asm volatile ( \
    ".byte 0x67\n\t" \
    ".byte 0x9A\n\t" \
    ".long %0\n\t" \
    ".word 0x3\n\t" \
    : :  "n" (nr), "r" (_ebx) : "cc" \
  ); \
} while(0);


#endif

RDOSAPI short int RdosSwapShort(short int val) 
{
  long res;
  
  asm ( \
    "xchgb %%ah, %%al\n\t" \
    : "=a" (res) : "a" (val) \
    );

  return (short int)res;    
}

RDOSAPI int RdosSwapLong(int val) 
{
  long res;
  
  asm ( \
    "bswap %%eax\n\t" \
    : "=a" (res) : "a" (val) \
    );

  return (int)res;    
}

#ifdef __x86_64__

RDOSAPI int RdosGetCharSize(const char *str) 
{
  long res;
  
  asm ( \
    "movb $1, %%al\n\t" \
    "movb (%0), %%ah\n\t" \
    "testb $0x80, %%ah\n\t" \
    "jz 1f\n\t" \
    "incb %%al\n\t" \
    "testb $0x20, %%ah\n\t" \
    "jz 1f\n\t" \
    "incb %%al\n\t" \
    "testb $0x10, %%ah\n\t" \
    "jz 1f\n\t" \
    "incb %%al\n\t" \
    "1: \n\t" \
    "movzx %%al, %%rax\n\t" \
    : "=a" (res) : "r" (str) : "cc" \
    );

  return res;    
}

#else

RDOSAPI int RdosGetCharSize(const char *str) 
{
  long res;
  
  asm ( \
    "movb $1, %%al\n\t" \
    "movb (%0), %%ah\n\t" \
    "testb $0x80, %%ah\n\t" \
    "jz 1f\n\t" \
    "incb %%al\n\t" \
    "testb $0x20, %%ah\n\t" \
    "jz 1f\n\t" \
    "incb %%al\n\t" \
    "testb $0x10, %%ah\n\t" \
    "jz 1f\n\t" \
    "incb %%al\n\t" \
    "1: \n\t" \
    "movzx %%al, %%eax\n\t" \
    : "=a" (res) : "r" (str) : "cc" \
    );

  return res;    
}

#endif

RDOSAPI int RdosGetLongRandom() 
{
    int res;
    RdosUserGateRetEax(usergate_get_random, res);
    return res;
}

RDOSAPI long RdosGetRandom(long range)
{
    long long res;

    RdosUserGateRetEax(usergate_get_random, res);

    res = res * range;
    res = res >> 32;    
    return res;
}

RDOSAPI int RdosOpenFile(const char *FileName, char Access)
{
    int res;
#ifdef __x86_64__    
    int size = strlen(FileName) + 1;
    RdosUserGateEdiEcxPar0RetEbx(usergate_open_file, FileName, Access, size, res);
#else
    RdosUserGateEdiEcxRetEbx(usergate_open_file, FileName, Access, res);
#endif    
    return res;
}

RDOSAPI int RdosCreateFile(const char *FileName, int Attrib)
{
    int res;
#ifdef __x86_64__    
    int size = strlen(FileName) + 1;
    RdosUserGateEdiEcxPar0RetEbx(usergate_create_file, FileName, Attrib, size, res);
#else
    RdosUserGateEdiEcxRetEbx(usergate_create_file, FileName, Attrib, res);
#endif    
    return res;
}

RDOSAPI int RdosReadFile(int Handle, void *Buf, int Size)
{
    int res;
    RdosUserGateEbxEdiEcxParRetEax(usergate_read_file, Handle, Buf, Size, res);
    return res;
}

RDOSAPI int RdosWriteFile(int Handle, void *Buf, int Size)
{
    int res;
    RdosUserGateEbxEdiEcxParRetEax(usergate_read_file, Handle, Buf, Size, res);
    return res;
}

RDOSAPI RdosCloseFile(int Handle)
{
    RdosUserGateEbx(usergate_close_file, Handle);
}

RDOSAPI int RdosCreateSection()
{
    int i;
    void *base = (void *)FUTEX_LINEAR;
    struct futex_struc *fp = (struct futex_struc *)base;

    for (i = 0; i < MAX_FUTEX_COUNT; i++)
    {
        if (fp->sign != FUTEX_SIGN)
        {
            fp->handle = 0;
            fp->count = 0;
            fp->val = -1;
            fp->owner = 0;
            fp->sign = FUTEX_SIGN;
            return i | FUTEX_HANDLE_BIAS;
        }
        else
            fp++;
    }            
    return 0;        
}

RDOSAPI RdosDeleteSection(int handle)
{
    int i;
    void *base = (void *)FUTEX_LINEAR;
    struct futex_struc *fp = (struct futex_struc *)base;

    if ((handle & 0xFFFF0000) == FUTEX_HANDLE_BIAS)
    {
        i = handle & 0xFFFF;
        fp += i;

        if (fp->handle)
            RdosCleanupFutex(i);
        
        fp->handle = 0;
        fp->count = 0;
        fp->val = 0;
        fp->owner = 0;
        fp->sign = 0;
    }
}

RDOSAPI RdosEnterSection(int handle)
{
    int i;

    if ((handle & 0xFFFF0000) == FUTEX_HANDLE_BIAS)
    {
        i = handle & 0xFFFF;
        RdosAcquireFutex(i);
    }
}

RDOSAPI RdosLeaveSection(int handle)
{
    int i;

    if ((handle & 0xFFFF0000) == FUTEX_HANDLE_BIAS)
    {
        i = handle & 0xFFFF;
        RdosReleaseFutex(i);
    }
}

RDOSAPI int RdosTryEnterSection(int handle)
{
    int i;
    int res = 0;

    if ((handle & 0xFFFF0000) == FUTEX_HANDLE_BIAS)
    {
        i = handle & 0xFFFF;
        RdosTryAcquireFutex(i, res);        
    }
    return res;
}
