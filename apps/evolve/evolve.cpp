#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dnapop.h"
#include "dnaseq.h"
#include "dnamut.h"
#include "dnaind.h"
#include "dnaeval.h"

#define FALSE	0
#define	TRUE	!FALSE

#define POP_SIZE	600
#define SEQ_SIZE	16000

int main(int argc, char **argv)
{
	TDnaSequence *ref;
	TDnaPopulation *pop1;
	TDnaPopulation *pop2;
	TDnaMutator *fastmut;
	TDnaMutator *slowmut;
	TDnaMutator *refmut;
	TDnaEvaluator *eval;
	TDnaEvaluator *eval1;
	TDnaSequence *ref1;
	TDnaEvaluator *eval2;
	TDnaSequence *ref2;
	int i;

	randomize();
	random(1000);

	refmut = new TDnaMutator(SEQ_SIZE, 0.000002);
	fastmut = new TDnaMutator(SEQ_SIZE, 0.00001);
	slowmut = new TDnaMutator(SEQ_SIZE, 0.000004);
	eval = new TDnaEvaluator(SEQ_SIZE);
	ref = eval->GetSeq();

	pop1 = new TDnaPopulation(fastmut, 100, SEQ_SIZE);
	pop1->CreateUniform(ref, 2 * POP_SIZE);

	for (i = 0; i < 200; i++)
	{
		pop1->Pairbond(4);
		if (i == 199)
			pop1->WritePairSumary(eval);

		pop1->CreateChildren(eval);
		ref->Mutate(refmut);
	}

	pop1->Set(slowmut);

	pop2 = pop1->Split(POP_SIZE);

	eval1 = new TDnaEvaluator(ref);
	ref1 = eval1->GetSeq();

	eval2 = new TDnaEvaluator(ref);
	ref2 = eval2->GetSeq();

	for (i = 0; i < 80000; i++)
	{
		printf("%d\r\n", i);
		pop1->Pairbond(4);
		if (i == 79999)
			pop1->WritePairSumary(eval);
		pop1->CreateChildren(eval1);
		ref1->Mutate(refmut);

		pop2->Pairbond(4);
		if (i == 79999)
			pop2->WritePairSumary(eval);
		pop2->CreateChildren(eval2);
		ref2->Mutate(refmut);

		ref->Mutate(refmut);
	}

	pop1->ExportRaw("raw1.dat");
	pop2->ExportRaw("raw2.dat");

	pop1->Merge(pop2);

	pop1->ExportQuiz("equiz.dat", ref, ref1, ref2);

	for (i = 0; i < 50; i++)
	{
		pop1->Pairbond(400);
		if (i == 49)
			pop1->WritePairSumary(eval);

		pop1->CreateChildren(eval);
		ref->Mutate(refmut);
	}

	pop1->ExportQuiz("quiz.dat", ref, ref1, ref2);

	return 0;
}

