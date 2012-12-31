#include "string.h"

#undef RDOSAPI
#define RDOSAPI static inline volatile __attribute__ ((always_inline))

#define UserGate(nr) \
  asm ( \
    "pushq %%r15\n\t" \
    "movq %0, %%r15\n\t" \
    "syscall\n\t" \
    "popq %%r15\n\t" \
    : : "i" (nr) : "rax", "rbx", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r11" \
    );

#define UserGateVol(nr) \
  asm volatile ( \
    "pushq %%r15\n\t" \
    "movq %0, %%r15\n\t" \
    "syscall\n\t" \
    "popq %%r15\n\t" \
    : : "i" (nr) : "rax", "rbx", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r11"\
    );

#define UserGateRetEax(nr, ret) \
  asm ( \
    "pushq %%r15\n\t" \
    "movq %1, %%r15\n\t" \
    "syscall\n\t" \
    "popq %%r15\n\t" \
    : "=a" (ret) : "i" (nr) : "rbx", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r11"\
    );

#define UserGateEdiEcxRetEbx(nr, rdi, rcx, len, ret) \
  asm ( \
    "pushq %%rcx\n\t" \
    "pushq %%rdi\n\t" \
    "pushq %%r12\n\t" \
    "pushq %%r15\n\t" \
    "movq %4,%%r12\n\t" \
    "movq %1, %%r15\n\t" \
    "syscall\n\t" \
    "jc 1f\n\t" \
    "movzx %%bx,%%rax\n\t" \
    "jmp 2f\n\t" \
    "1: \n\t" \
    "xorq %%rax,%%rax\n\t" \
    "2: \n\t" \
    "popq %%r15\n\t" \
    "popq %%r12\n\t" \
    "popq %%rdi\n\t" \
    "popq %%rcx\n\t" \
    : "=a" (ret) : "i" (nr), "D" (rdi), "c" (rcx), "r" (len) : "rbx", "rdx", "rsi", "r8", "r9", "r11", "cc" \
    );

#define UserGateEbxEcxEdiRetEax(nr, rbx, rcx, rdi, ret) \
  asm ( \
    "pushq %%rcx\n\t" \
    "pushq %%rdi\n\t" \
    "pushq %%r12\n\t" \
    "pushq %%r15\n\t" \
    "movq %%rcx,%%r12\n\t" \
    "movq %%rcx,%%r8\n\t" \
    "movq %1, %%r15\n\t" \
    "syscall\n\t" \
    "jnc 1f\n\t" \
    "xorq %%rax,%%rax\n\t" \
    "1: \n\t" \
    "popq %%r15\n\t" \
    "popq %%r12\n\t" \
    "popq %%rdi\n\t" \
    "popq %%rcx\n\t" \
    : "=a" (ret) : "i" (nr), "b" (rbx), "c" (rcx), "D" (rdi) : "rdx", "rsi", "r8", "r9", "r11", "cc" \
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

RDOSAPI long RdosGetLongRandom() 
{
    long res;
    UserGateRetEax(usergate_get_random, res);
    return res;
}

RDOSAPI long RdosGetRandom(long range)
{
    long res;

    UserGateRetEax(usergate_get_random, res);

    res = res * range;
    res = res >> 32;    
    return res;
}

RDOSAPI long RdosOpenFile(const char *FileName, char Access)
{
    long res;
    long size = strlen(FileName) + 1;
    UserGateEdiEcxRetEbx(usergate_open_file, FileName, Access, size, res);
    return res;
}

RDOSAPI long RdosCreateFile(const char *FileName, int Attrib)
{
    long res;
    long size = strlen(FileName) + 1;
    UserGateEdiEcxRetEbx(usergate_create_file, FileName, Attrib, size, res);
    return res;
}

RDOSAPI long RdosReadFile(int Handle, void *Buf, int Size)
{
    long res;
    UserGateEbxEcxEdiRetEax(usergate_read_file, Handle, Size, Buf, res);
    return res;
}

RDOSAPI long RdosWriteFile(int Handle, void *Buf, int Size)
{
    long res;
    UserGateEbxEcxEdiRetEax(usergate_write_file, Handle, Size, Buf, res);
    return res;
}
