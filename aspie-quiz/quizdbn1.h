
struct TQuizRow
{
    long ID;
    long userid;
    int  BirthYear;
    int  BirthMonth;
	char Gender;
    char Lang;
	char Autism;
	char Aspie;
	char ADHD;
	char Dyspraxia;
	char Dyslexia;
	char Dyscalculia;
	char OCD;
	char Bipolar;
	char Schizophrenia;
	char Social;
	char Referer[100];
	long AsResult;
	long NtResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
    char DxResult[DX_COUNT];
};
