#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dnapop.h"
#include "dnaseq.h"

#define FALSE	0
#define	TRUE	!FALSE

int main(int argc, char **argv)
{
	TDnaPopulation *pop;
	TDnaSequence *seq;

	randomize();
	random(1000);

	pop = new TDnaPopulation;
	seq = new TDnaSequence(pop, 256);

	seq->Write();
	printf("\r\n");
	delete seq;
	delete pop;

	return 0;
}
