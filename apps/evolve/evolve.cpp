#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dnapop.h"
#include "dnaseq.h"
#include "dnamut.h"

#define FALSE	0
#define	TRUE	!FALSE

int main(int argc, char **argv)
{
	TDnaPopulation *pop;
	TDnaSequence *seq;
	TDnaMutator *mut;
	int i;

	randomize();
	random(1000);

	mut = new TDnaMutator(79, 0.01);
	pop = new TDnaPopulation;
	seq = new TDnaSequence(pop, 79);
	seq->SetMutator(mut);

	for (i = 0; i < 500; i++)
	{
		seq->Write();
		printf("\r\n");
		seq->Mutate();
	}

	delete seq;
	delete pop;
	delete mut;

	return 0;
}
