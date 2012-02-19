
struct TQuizRow
{
    long ID;
    long LsbTime;
    long MsbTime;
    int  BirthYear;
    int  BirthMonth;
	char Gender;
	char Hair;
	char Eye;
    char Lang;
	char Autism;
	char Aspie;
	char ADHD;
	char ABO;
	char Parkinson;
	char Alzheimer;
	char CFTR;
	char HFE;
	char Leiden;
	char RA;
	char Fibromyalgia;
	char AltruismAlt;
	char AltruismAnswerAlt;
	char AltruismChoice;
	long AsResult;
	long NtResult;
	char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
	char Stim[40];
};

