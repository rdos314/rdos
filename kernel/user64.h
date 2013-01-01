#include "string.h"

#undef RDOSAPI
#define RDOSAPI static inline volatile __attribute__ ((always_inline))

#define RdosClobberRdi \
  asm volatile ( \
    "\n\t" \
     : : : "rdi" \
   );

#define RdosSetupRcx(val) \
  asm volatile ( \
    "movl %0, %%r8d\n\t" \
     : : "g" (val) : "r8" \
   );

#define RdosSetupPar0(val) \
  asm volatile ( \
    "movl %0, %%r12d\n\t" \
     : : "g" (val) : "r12" \
   );

#define RdosSetupParRcx(val) \
  asm volatile ( \
    "movl %0, %%r8d\n\t" \
    "movl %0, %%r12d\n\t" \
     : : "g" (val) : "r8", "r12" \
   );

#define RdosUserGateSetup(nr) \
  asm volatile ( \
    "movl %0, %%r14d\n\t" \
     : : "g" (nr) : "rcx", "r9", "r11", "r14", "cc" \
   );

#define RdosUserGateNoPar(nr) \
  RdosUserGateSetup(nr) \
  asm volatile ( \
    "syscall\n\t" \
    : : : "rax", "rbx", "rdx", "rsi", "rdi" \
    );

#define RdosUserGateRetEax(nr, res) \
  RdosUserGateSetup(nr) \
  asm volatile( \
    "syscall\n\t" \
    : "=a" (res) : : "rbx", "rdx", "rsi", "rdi" \
  );

#define RdosUserGateEdiRetEbx(nr, rdi, res) \
  RdosUserGateSetup(nr) \
  asm volatile ( \
    "syscall\n\t" \
    "jc 1f\n\t" \
    "movzx %%bx,%%rax\n\t" \
    "jmp 2f\n\t" \
    "1: \n\t" \
    "xorq %%rax,%%rax\n\t" \
    "2: \n\t" \
    : "=a" (res) : "D" (rdi) : "rbx", "rdx", "rsi" \
  ); \
  RdosClobberRdi;

#define RdosUserGateEbxEdiRetEax(nr, rbx, rdi, res) \
  RdosUserGateSetup(nr) \
  asm volatile ( \
    "syscall\n\t" \
    "jnc 1f\n\t" \
    "xorq %%rax,%%rax\n\t" \
    "1: \n\t" \
    : "=a" (res) : "b" (rbx), "D" (rdi) : "rdx", "rsi" \
  ); \
  RdosClobberRdi;

#define RdosUserGateEbx(nr, rbx) \
  RdosUserGateSetup(nr) \
  asm volatile ( \
    "syscall\n\t" \
    : : "b" (rbx) : "rax", "rdx", "rsi", "rdi" \
  );

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
    RdosSetupPar0(size);    
    RdosSetupRcx(Access);
    RdosUserGateEdiRetEbx(usergate_open_file, FileName, res);
    return res;
}

RDOSAPI int RdosCreateFile(const char *FileName, int Attrib)
{
    int res;
    int size = strlen(FileName) + 1;
    RdosSetupPar0(size);   
    RdosSetupRcx(Attrib);
    RdosUserGateEdiRetEbx(usergate_create_file, FileName, res);
    return res;
}

RDOSAPI int RdosReadFile(int Handle, void *Buf, int Size)
{
    int res;
    RdosSetupParRcx(Size);    
    RdosUserGateEbxEdiRetEax(usergate_read_file, Handle, Buf, res);
    return res;
}

RDOSAPI int RdosWriteFile(int Handle, void *Buf, int Size)
{
    int res;
    RdosSetupParRcx(Size);    
    RdosUserGateEbxEdiRetEax(usergate_write_file, Handle, Buf, res);
    return res;
}

RDOSAPI RdosCloseFile(int Handle)
{
    RdosUserGateEbx(usergate_close_file, Handle);
}
