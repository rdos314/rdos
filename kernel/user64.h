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
    "movq %0, %%r15\n\t" \
    "syscall\n\t" \
    "popq %%r15\n\t" \
    : "=a" (ret) : "i" (nr) \
    );

RDOSAPI void RdosTestGate() 
{
    UserGateVol(usergate_test_gate);
}

RDOSAPI short int RdosSwapShort(short int val) 
{
  long res;
  
  asm ( \
    "xchgb %%ah, %%al" \
    : "=a" (res) : "a" (val) \
    );

  return (short int)res;    
}

RDOSAPI int RdosSwapLong(int val) 
{
  long res;
  
  asm ( \
    "bswap %%eax" \
    : "=a" (res) : "a" (val) \
    );

  return (int)res;    
}

RDOSAPI long RdosGetLongRandom() 
{
    long res;
    UserGateRet(usergate_get_random, res);
    return res;
}
