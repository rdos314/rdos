#include "string.h"

#undef RDOSAPI
#define RDOSAPI static inline volatile __attribute__ ((always_inline))

#define RdosClobberSyscall \
  asm volatile ( \
    "\n\t" \
     : : : "rcx", "r9", "r11" \
   );

#define RdosClobberSyscallRdi \
  asm volatile ( \
    "\n\t" \
     : : : "rcx", "rdi", "r9", "r11" \
   );

#define RdosUserGateRetEax(nr, res) do { \
  register int _id asm("r14") = nr; \
  asm volatile( \
    "syscall\n\t" \
    : "=a" (res) : : "rbx", "rdx", "rsi", "rdi" \
  ); \
  RdosClobberSyscall; \
} while(0);

#define RdosUserGateEdiEcxPar0RetEbx(nr, rdi, rcx, size, res) do { \
  register int _id asm("r14") = nr; \
  register typeof(rdi) _rdi asm("rdi") = (rdi); \
  register typeof(rcx) _rcx asm("r8") = (rcx); \
  register typeof(size) _size asm("r12") = (size); \
  asm volatile ( \
    "syscall\n\t" \
    "jc 1f\n\t" \
    "movzx %%bx,%%rax\n\t" \
    "jmp 2f\n\t" \
    "1: \n\t" \
    "xorq %%rax,%%rax\n\t" \
    "2: \n\t" \
    : "=a" (res) : "r" (_rdi), "r" (_rcx), "r" (_size) : "rbx", "rdx", "rsi" \
  ); \
  RdosClobberSyscallRdi; \
} while(0);

#define RdosUserGateEbxEdiEcxParRetEax(nr, rbx, rdi, rcx, res) do { \
  register int _id asm("r14") = nr; \
  register typeof(rdi) _rdi asm("rdi") = (rdi); \
  register typeof(rcx) _rcx asm("r8") = (rcx); \
  register typeof(rcx) _size asm("r12") = (rcx); \
  asm volatile ( \
    "syscall\n\t" \
    "jnc 1f\n\t" \
    "xorq %%rax,%%rax\n\t" \
    "1: \n\t" \
    : "=a" (res) : "r" (_rdi), "r" (_rcx), "r" (_size) : "rdx", "rsi" \
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

RDOSAPI int RdosGetLongRandom() 
{
    int res;
    RdosUserGateRetEax(usergate_get_random, res);
    return res;
}

RDOSAPI long RdosGetRandom(long range)
{
    long res;

    RdosUserGateRetEax(usergate_get_random, res);

    res = res * range;
    res = res >> 32;    
    return res;
}

RDOSAPI int RdosOpenFile(const char *FileName, char Access)
{
    int res;
    int size = strlen(FileName) + 1;
    RdosUserGateEdiEcxPar0RetEbx(usergate_open_file, FileName, Access, size, res);
    return res;
}

RDOSAPI int RdosCreateFile(const char *FileName, int Attrib)
{
    int res;
    int size = strlen(FileName) + 1;
    RdosUserGateEdiEcxPar0RetEbx(usergate_create_file, FileName, Attrib, size, res);
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
