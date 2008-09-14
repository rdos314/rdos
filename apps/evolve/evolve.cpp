#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dnapop.h"
#include "dnaseq.h"
#include "dnamut.h"
#include "dnaind.h"

#define FALSE	0
#define	TRUE	!FALSE

int main(int argc, char **argv)
{
	TDnaPopulation *pop;
	TDnaIndividual *mother;
	TDnaIndividual *father;
	TDnaIndividual *child1;
	TDnaIndividual *child2;
	TDnaMutator *mut;
	int i;

	randomize();
	random(1000);

	mut = new TDnaMutator(70, 0.01);

	mother = new TDnaIndividual(70);
	father = new TDnaIndividual(70);
	child1 = new TDnaIndividual(*mother, *father, mut, 40);
	child2 = new TDnaIndividual(*mother, *father, mut, 40);

	mother->Write();
	father->Write();
	child1->Write();
	child2->Write();

	return 0;
}
