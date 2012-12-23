
#define UserGate(nr) \
  asm ( \
    "pushq %%r15\n\t" \
    "movq %0, %%r15\n\t" \
    "syscall\n\t" \
    "popq %%r15\n\t" \
    : : "i" (nr) \
    );

long inline RdosGetLongRandom()
{
    int res;
    UserGate(usergate_get_random);
    asm ("movl %0, %%eax" : "=r" (res) : );
    return res;
}
   
