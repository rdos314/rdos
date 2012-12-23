#undef RDOSAPI
#define RDOSAPI static inline volatile __attribute__ ((always_inline))

#define UserGate(nr) \
  asm ( \
    "pushq %%r15\n\t" \
    "movq %0, %%r15\n\t" \
    "syscall\n\t" \
    "popq %%r15\n\t" \
    : : "i" (nr) \
    );

#define UserGateVol(nr) \
  asm volatile ( \
    "pushq %%r15\n\t" \
    "movq %0, %%r15\n\t" \
    "syscall\n\t" \
    "popq %%r15\n\t" \
    : : "i" (nr) \
    );

#define UserGateRet(nr, ret) \
  asm ( \
    "pushq %%r15\n\t" \
    "movq %1, %%r15\n\t" \
    "syscall\n\t" \
    "popq %%r15\n\t" \
    : "=a" (ret) : "i" (nr) \
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
    UserGateRet(usergate_get_random, res);
    return res;
}

RDOSAPI long RdosGetRandom(long range)
{
    long res;

    UserGateRet(usergate_get_random, res);

    res = res * range;
    res = res >> 32;    
    return res;
}
