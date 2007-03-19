/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# quiz5.cpp
# Quiz 5 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quiz5.h"
#include "file.h"
#include "quizdb5.h"

#define IQ_INTERVAL 1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

struct TIqValArr
{
	int val;
};

class TIqEntry
{
public:
	TIqEntry();
	~TIqEntry();
	void Add(TQuizRow *Row);
	void Write(TFile &file);

	long double GetMean();
	long double GetSd();

protected:
	int Sum;
	int Count;
	int Increment;
	int MaxSize;
	int *ValArr;
};

class TIqAge
{
public:
	TIqAge();
	void Add(TQuizRow *Row);
	void WriteRow(TFile &file, const char *text);

	static void WriteHeader(TFile &file);

	TIqEntry MaleSlowMat;
	TIqEntry FemaleSlowMat;
	TIqEntry MaleHighAs;
	TIqEntry MaleAs;
	TIqEntry MaleNt;
	TIqEntry MaleHighNt;
	TIqEntry FemaleHighAs;
	TIqEntry FemaleAs;
	TIqEntry FemaleNt;
	TIqEntry FemaleHighNt;
};

/*##########################################################################
#
#   Name       : TQuiz5::TQuiz5
#
#   Purpose....: Constructor for TQuiz5
#
#   In params..: Filename to load quiz 5 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz5::TQuiz5(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd)
  : TQuiz(113),
	FDataFile(FileName)
{
    DefineCross(0, QuizI);
    DefineCross(1, QuizII);
    DefineCross(2, QuizIII);
    DefineCross(3, QuizNd);

    SetupTexts();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	LoadPopulations();
    SetupCross(QuizI, QuizII, QuizIII, QuizNd);
    Calculate();
}

/*##########################################################################
#
#   Name       : TQuiz5::~TQuiz5
#
#   Purpose....: Destructor for TQuiz5
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz5::~TQuiz5()
{
}

/*##################  TQuiz5::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz5::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuiz5::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz5::WriteName(TFile &File)
{
    File.Write("5");
}

/*##########################################################################
#
#   Name       : TQuiz5::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz5::SetupTexts()
{
	Quiz[23].Reverse = TRUE;
	Quiz[24].Reverse = TRUE;
	Quiz[25].Reverse = TRUE;
	Quiz[29].Reverse = TRUE;
	Quiz[30].Reverse = TRUE;
	Quiz[37].Reverse = TRUE;
	Quiz[39].Reverse = TRUE;
	Quiz[40].Reverse = TRUE;
	Quiz[58].Reverse = TRUE;
	Quiz[63].Reverse = TRUE;
	Quiz[65].Reverse = TRUE;
	Quiz[67].Reverse = TRUE;
	Quiz[68].Reverse = TRUE;
	Quiz[73].Reverse = TRUE;
	Quiz[75].Reverse = TRUE;
	Quiz[76].Reverse = TRUE;
	Quiz[77].Reverse = TRUE;
	Quiz[78].Reverse = TRUE;
	Quiz[79].Reverse = TRUE;
	Quiz[80].Reverse = TRUE;
	Quiz[81].Reverse = TRUE;
	Quiz[86].Reverse = TRUE;
	Quiz[90].Reverse = TRUE;
	Quiz[91].Reverse = TRUE;
	Quiz[95].Reverse = TRUE;
	Quiz[97].Reverse = TRUE;
	Quiz[101].Reverse = TRUE;
	Quiz[107].Reverse = TRUE;
	Quiz[111].Reverse = TRUE;
	Quiz[112].Reverse = TRUE;

	Quiz[0].MyGroup = GROUP_SENSORY;
	Quiz[1].MyGroup = GROUP_SENSORY;
	Quiz[2].MyGroup = GROUP_SENSORY;
	Quiz[3].MyGroup = GROUP_SENSORY;
	Quiz[4].MyGroup = GROUP_SENSORY;
	Quiz[5].MyGroup = GROUP_SENSORY;
	Quiz[6].MyGroup = GROUP_SENSORY;
	Quiz[7].MyGroup = GROUP_ASPIE_COMM;
	Quiz[8].MyGroup = GROUP_SENSORY;
	Quiz[9].MyGroup = GROUP_ASPIE_COMM;
	Quiz[10].MyGroup = GROUP_SENSORY;
	Quiz[11].MyGroup = GROUP_SENSORY;
	Quiz[12].MyGroup = GROUP_ASPIE_COMM;
	Quiz[13].MyGroup = GROUP_SENSORY;
	Quiz[14].MyGroup = GROUP_ASPIE_COMM;
	Quiz[15].MyGroup = GROUP_SENSORY;
	Quiz[16].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[17].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[18].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[19].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[20].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[21].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[22].MyGroup = GROUP_NONVERBAL;
	Quiz[23].MyGroup = GROUP_NONVERBAL;
	Quiz[24].MyGroup = GROUP_NONVERBAL;
	Quiz[25].MyGroup = GROUP_NONVERBAL;
	Quiz[26].MyGroup = GROUP_NONVERBAL;
	Quiz[27].MyGroup = GROUP_NONVERBAL;
	Quiz[28].MyGroup = GROUP_NONVERBAL;
	Quiz[29].MyGroup = GROUP_NONVERBAL;
	Quiz[30].MyGroup = GROUP_NONVERBAL;
	Quiz[31].MyGroup = GROUP_NONVERBAL;
	Quiz[32].MyGroup = GROUP_NONVERBAL;
	Quiz[33].MyGroup = GROUP_NONVERBAL;
	Quiz[34].MyGroup = GROUP_NONVERBAL;
	Quiz[35].MyGroup = GROUP_NONVERBAL;
	Quiz[36].MyGroup = GROUP_NONVERBAL;
	Quiz[37].MyGroup = GROUP_NONVERBAL;
	Quiz[38].MyGroup = GROUP_NONVERBAL;
	Quiz[39].MyGroup = GROUP_NONVERBAL;
	Quiz[40].MyGroup = GROUP_NONVERBAL;
	Quiz[41].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[42].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[43].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[44].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[45].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[46].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[47].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[48].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[49].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[51].MyGroup = GROUP_ASPIE_COMM;
	Quiz[52].MyGroup = GROUP_ASPIE_COMM;
	Quiz[53].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[54].MyGroup = GROUP_ASPIE_COMM;
	Quiz[55].MyGroup = GROUP_ASPIE_COMM;
	Quiz[56].MyGroup = GROUP_ASPIE_COMM;
	Quiz[57].MyGroup = GROUP_ASPIE_COMM;
	Quiz[58].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[59].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[60].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[61].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[62].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[63].MyGroup = GROUP_NONVERBAL;
	Quiz[64].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[65].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[66].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[67].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[68].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[69].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[70].MyGroup = GROUP_NONVERBAL;
	Quiz[71].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[72].MyGroup = GROUP_ASPIE_COMM;
	Quiz[73].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[74].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[75].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[76].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[77].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[78].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[79].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[80].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[81].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[82].MyGroup = GROUP_NT_TALENT;
	Quiz[83].MyGroup = GROUP_NONVERBAL;
	Quiz[84].MyGroup = GROUP_NT_TALENT;
	Quiz[85].MyGroup = GROUP_NT_TALENT;
	Quiz[86].MyGroup = GROUP_NT_TALENT;
	Quiz[87].MyGroup = GROUP_NT_TALENT;
	Quiz[88].MyGroup = GROUP_NT_TALENT;
	Quiz[89].MyGroup = GROUP_ASPIE_COMM;
	Quiz[90].MyGroup = GROUP_NT_TALENT;
	Quiz[91].MyGroup = GROUP_NT_TALENT;
	Quiz[92].MyGroup = GROUP_NT_TALENT;
	Quiz[93].MyGroup = GROUP_NT_TALENT;
	Quiz[94].MyGroup = GROUP_NT_TALENT;
	Quiz[95].MyGroup = GROUP_NT_TALENT;
	Quiz[96].MyGroup = GROUP_NT_TALENT;
	Quiz[97].MyGroup = GROUP_NT_TALENT;
	Quiz[98].MyGroup = GROUP_NONVERBAL;
	Quiz[99].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[100].MyGroup = GROUP_ASPIE_COMM;
	Quiz[101].MyGroup = GROUP_NONVERBAL;
	Quiz[102].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[103].MyGroup = GROUP_ASPIE_COMM;
	Quiz[104].MyGroup = GROUP_ASPIE_COMM;
	Quiz[105].MyGroup = GROUP_ASPIE_COMM;
	Quiz[106].MyGroup = GROUP_ASPIE_COMM;
	Quiz[107].MyGroup = GROUP_NONVERBAL;
	Quiz[108].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[109].MyGroup = GROUP_ASPIE_COMM;
	Quiz[110].MyGroup = GROUP_ASPIE_COMM;
	Quiz[111].MyGroup = GROUP_NONVERBAL;
	Quiz[112].MyGroup = GROUP_MIXED;

#ifdef ENGLISH

	Quiz[0].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
	Quiz[1].Text = "Do you feel strongly attracted to, or appalled by, certain tastes, smells, sounds, colours, shapes, textures or materials?";
	Quiz[2].Text = "Do you squint now or have done in the past?";
	Quiz[3].Text = "Do certain phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
	Quiz[4].Text = "Are you irritated by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' textures/material?";
	Quiz[5].Text = "Are you over-or under-sensitive to heat, cold, wind, humidity etc?";
	Quiz[6].Text = "Do you have a very acute sense of smell and/or taste?";
	Quiz[7].Text = "Do you blink or roll your eyes?";
	Quiz[8].Text = "Are you sensitive to electromagnetic fields?";
	Quiz[9].Text = "Do you stammer when stressed?";
	Quiz[10].Text= "Do you see yourself as sensitive?";
	Quiz[11].Text = "Are you bothered by fluorescent light?";
	Quiz[12].Text = "Do you sniff involuntary?";
	Quiz[13].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
	Quiz[14].Text = "Are you hypo- or hypersensitive to physical pain, or even enjoy some types of pain?";
	Quiz[15].Text = "Do you often use peripheral vision?";
	Quiz[16].Text = "Do you have a tendency to drop things?";
	Quiz[17].Text = "Do you have difficulty with throwing or catching a ball?";
	Quiz[18].Text = "Are you the last one to finish manual tasks?";
	Quiz[19].Text = "Do you have difficulties judging distances, height, depth or speed?";
	Quiz[20].Text = "Do you have difficulty hopping, skipping or riding a bike?";
	Quiz[21].Text = "Are you often injured?";
	Quiz[22].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
	Quiz[23].Text = "Can you read between the lines?";
	Quiz[24].Text = "Do you have an intuitive sense of when to do the right thing socially?";
	Quiz[25].Text = "Do you read people well?";
	Quiz[26].Text = "Are you usually unaware of social rules & boundaries unless they are specifically spelled out?";
	Quiz[27].Text = "Do others often misunderstand you?";
	Quiz[28].Text = "Do you forget you are in a social situation when something gets your attention?";
	Quiz[29].Text = "Is it easy for you to interpret body language?";
	Quiz[30].Text = "Can you spot hidden agendas with ease?";
	Quiz[31].Text = "Are you often surprised what people's motives are?";
	Quiz[32].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
	Quiz[33].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
	Quiz[34].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
	Quiz[35].Text = "Have you taken initiative only to find out it was not wanted?";
	Quiz[36].Text = "Do you have difficulty summarizing and reporting conversations or describing events?";
	Quiz[37].Text = "Are you intuitive about what people need from you?";
	Quiz[38].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly instructed?";
	Quiz[39].Text = "Do you understand figures of speech, parodies, allegories, irony etc with ease?";
	Quiz[40].Text = "Do you sense the boundaries of others without being told?";
	Quiz[41].Text = "Do you have unconventional, often unique ways of solving problems?";
	Quiz[42].Text = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
	Quiz[43].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
	Quiz[44].Text = "Do you focus on one interest at a time and become an expert on that subject?";
	Quiz[45].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
	Quiz[46].Text = "Do you have one special talent which you have emphasised and worked on?";
	Quiz[47].Text = "Is you imagination unusual, with unique ideas that others don't have?";
	Quiz[48].Text = "Are you very gifted in one or more areas?";
	Quiz[49].Text = "Are you fascinated by dates and/or numbers?";
	Quiz[50].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
	Quiz[51].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed, or if an activity that is important to you gets interrupted?";
	Quiz[52].Text = "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?";
	Quiz[53].Text = "Do you see the value in owning one of a kind?";
	Quiz[54].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
	Quiz[55].Text = "Do you have a need for comfort items like blankets, stuffed animals etc?";
	Quiz[56].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to prepare yourself mentally first?";
	Quiz[57].Text = "Do you have certain simple & logical routines which you need to follow?";
	Quiz[58].Text = "Do you find yourself at ease in romantic situations?";
	Quiz[59].Text = "Do you feel awkward in romantic situations?";
	Quiz[60].Text = "Do you find preferable/easier to understand & communicate with computers, animals or unusual people?";
	Quiz[61].Text = "Do you have difficulty compared to others your age in developing relationships and friendships?";
	Quiz[62].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
	Quiz[63].Text = "Can you keep a healthy balance between what you need to do and treating your associates/guests with due attention?";
	Quiz[64].Text = "Does an unplanned hug make you jump out of your skin?";
	Quiz[65].Text = "Are you energised by being in the company of others?";
	Quiz[66].Text = "Have you felt different from others for most of your life?";
	Quiz[67].Text = "Do you enjoy team sport and group endeavours?";
	Quiz[68].Text = "Are you good at party games?";
	Quiz[69].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
	Quiz[70].Text = "Have you been bullied, abused or taken advantage of in various situations?";
	Quiz[71].Text = "Do you mostly prefer to play/work/do things on your own - unsupervised?";
	Quiz[72].Text = "Do you easily get frustrated and upset when you are stressed, tired, hungry, interrupted, questioned, over-stimulated, or when things don't go as you had anticipated?";
	Quiz[73].Text = "Do your friends mean more to you than hobbies and interests?";
	Quiz[74].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
	Quiz[75].Text = "Do you have an interest for fashions?";
	Quiz[76].Text = "Is your style and image important to you?";
	Quiz[77].Text = "Do you enjoy gossip?";
	Quiz[78].Text = "Do you talk to put others at ease even when you really have nothing to say?";
	Quiz[79].Text = "Do you spend more time getting to know others than yourself?";
	Quiz[80].Text = "Is creating a social identity important for you?";
	Quiz[81].Text = "Is other people's image of you important to you?";
	Quiz[82].Text = "Do you find it difficult to read written material unless it is very interesting or very easy?";
	Quiz[83].Text = "Do you have poor concept of time?";
	Quiz[84].Text = "Do you find it difficult to taking notes in lectures?";
	Quiz[85].Text = "Do you have trouble reading clocks?";
	Quiz[86].Text = "Do you have things so well in hand that you've anticipate what will be asked for?";
	Quiz[87].Text = "Do you fail to carry a number through to the next part of the calculation?";
	Quiz[88].Text = "Do you often make spelling errors?";
	Quiz[89].Text = "Do you often forget were you put things?";
	Quiz[90].Text = "Can you easily remember sequences of past events?";
	Quiz[91].Text = "Do you enjoy reading?";
	Quiz[92].Text = "Do you have difficulty remembering scores during games?";
	Quiz[93].Text = "Do you find it hard to recognise phone numbers when said in a different way?";
	Quiz[94].Text = "Do you find it difficult to calculate change received from a purchase?";
	Quiz[95].Text = "Do find it easy to remember math formulas?";
	Quiz[96].Text = "Are you a slow reader?";
	Quiz[97].Text = "Do you find it easy to sequence ideas in writing?";
	Quiz[98].Text = "Do you find instructions confusing - - especially several at the same time?";
	Quiz[99].Text = "Do you dislike touch?";
	Quiz[100].Text= "Are you easily distracted or overwhelmed?";
	Quiz[101].Text= "Do you know when you are expected to offer an apology?";
	Quiz[102].Text= "Do you look, feel or act younger than your biological age?";
	Quiz[103].Text= "Do you get surprised and disappointed when people are unfriendly and don't seem to understand or accept you as you are?";
	Quiz[104].Text= "Do you need to see, touch or do things yourself in order to remember them?";
	Quiz[105].Text= "Do you find it very hard to learn things that you are not interested in?";
	Quiz[106].Text= "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
	Quiz[107].Text= "Do you get a firm feel for the big picture, before noticing details?";
	Quiz[108].Text= "Do you often work through lunch or breaks to fix mistakes and get things done on time?";
	Quiz[109].Text= "Do you prefer being told the bottom line rather than having to find your own way there?";
	Quiz[110].Text= "Do you feel an urge to peel skin-flakes off yourself and /or others?";
	Quiz[111].Text= "Are you gracious about criticism, correction and direction?";
	Quiz[112].Text = "Nonverbal IQ";

#endif

#ifdef SWEDISH
	Quiz[0].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
	Quiz[1].Text = "Brukar du känna stark lust eller häftigt obehag av vissa färger, former, dofter, smaker, material eller konsistenser?";
	Quiz[2].Text = "Skelar du eller har gjort det?";
	Quiz[3].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
	Quiz[4].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda av 'fel' material?";
	Quiz[5].Text = "Är du känslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
	Quiz[6].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
	Quiz[7].Text = "Blinkar eller rullar du med ögona?";
	Quiz[8].Text = "Är du känslig för elektromagnetiska fält?";
	Quiz[9].Text = "Stammar du när du blir stressad?";
	Quiz[10].Text= "Anser du att du är känslig?";
	Quiz[11].Text = "Är du känslig för vissa typer av ljus, t.ex lysrörsljus?";
	Quiz[12].Text = "Sniffar du ofrivilligt?";
	Quiz[13].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
	Quiz[14].Text = "Är du över- eller underkänslig för smärta eller t.o.m tycker om vissa sorters smärta?";
	Quiz[15].Text = "Använder du ofta periferseende?";
	Quiz[16].Text = "Har du en tendens att tappa saker?";
	Quiz[17].Text = "Har du svårt för att kasta eller fånga en boll?";
	Quiz[18].Text = "Är du sist med att avsluta manuella uppgifter?";
	Quiz[19].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och hastighet?";
	Quiz[20].Text = "Har du svårt för att hoppa eller cykla?";
	Quiz[21].Text = "Skadar du dig ofta?";
	Quiz[22].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
	Quiz[23].Text = "Kan du läsa mellan raderna?";
	Quiz[24].Text = "Känner du intuitivt av vad som är rätt socialt?";
	Quiz[25].Text = "Läser du av folk bra?";
	Quiz[26].Text = "Är du oftast omedveten om outtalade sociala regler?";
	Quiz[27].Text = "Missförstår andra ofta dig?";
	Quiz[28].Text = "Glömmer du bort att du är i en social situation när något annat fångar ditt intresse?";
	Quiz[29].Text = "Har du lätt för att tolka kroppsspråk?";
	Quiz[30].Text = "Kan du lätt avslöja dolda motiv?";
	Quiz[31].Text = "Blir du ofta överraskad av vad folks motiv är?";
	Quiz[32].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
	Quiz[33].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
	Quiz[34].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
	Quiz[35].Text = "Tar du ibland initiativ som inte visar sig önskade?";
	Quiz[36].Text = "Har du problem med att redogöra för konversationer eller händelser och att sammanfatta?";
	Quiz[37].Text = "Känner du intuitivt av vad folk behöver från dig?";
	Quiz[38].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
	Quiz[39].Text = "Har du lätt för att förstå talesätt, allegorier, parodier, ironi och liknande?";
	Quiz[40].Text = "Känner du av andras gränser utan att någon talar om dem?";
	Quiz[41].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
	Quiz[42].Text = "Brukar du bli så absorberad av dina projekt att du glömmer/struntar i allting annat (äta, duscha, sova, andra människor etc.)?";
	Quiz[43].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
	Quiz[44].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert på det?";
	Quiz[45].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
	Quiz[46].Text = "Har du en speciell talang som du har jobbat med?";
	Quiz[47].Text = "Är din fantasi ovanlig med unika idéer som andra inte har?";
	Quiz[48].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
	Quiz[49].Text = "Är du fascinerad av datum och/eller siffror?";
	Quiz[50].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
	Quiz[51].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer, rutiner eller som avbryter dig mitt i en för dig viktig aktivitet?";
	Quiz[52].Text = "Har du en tendens att lätt bli stressad och få panik eller kortslutning i hjärnan i nya och kravfyllda situationer?";
	Quiz[53].Text = "Tycker du det finns ett värde i att äga en sak av varje sort?";
	Quiz[54].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
	Quiz[55].Text = "Har du ibland behov av gosefilt, kramdjur eller liknande?";
	Quiz[56].Text = "Innan du gör något eller går någonstans, behöver du ha en inre bild av vad som kommer att hända så du kan förbereda dig?";
	Quiz[57].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
	Quiz[58].Text = "Trivs du med romantiska situationer?";
	Quiz[59].Text = "Känner du dig obekväm i romantiska situationer?";
	Quiz[60].Text = "Tycker du det är att föredra/lättare att förstå och kommunicera med datorer, djur eller udda människor?";
	Quiz[61].Text = "Har du svårare än dina jämnåriga att få vänner och/eller partners?";
	Quiz[62].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
	Quiz[63].Text = "Kan du hålla balans mellan dina behov och samtidigt ge kolleger och gäster lämplig uppmärksamhet?";
	Quiz[64].Text = "Gör en oplanerad kram att du vill hoppa ur ditt skinn?";
	Quiz[65].Text = "Får du energi av att vara i sällskap med andra?";
	Quiz[66].Text = "Har du känt dig annorlunda största delen av ditt liv?";
	Quiz[67].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
	Quiz[68].Text = "Är du bra på sällskapsspel?";
	Quiz[69].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
	Quiz[70].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
	Quiz[71].Text = "Föredrar du att mestadels leka/arbeta/göra saker på egen hand - utan övervakning?";
	Quiz[72].Text = "Blir du lätt frustrerad och upprörd när du blir stressad, trött, hungrig, ifrågasatt, avbruten, överstimulerad, eller när saker inte går som du har tänkt dig och ställt in dig på?";
	Quiz[73].Text = "Betyder vänner mer för dig än hobbies och intressen?";
	Quiz[74].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
	Quiz[75].Text = "Är du intressad av mode?";
	Quiz[76].Text = "Är din stil och image viktig för dig?";
	Quiz[77].Text = "Tycker du om skvaller?";
	Quiz[78].Text = "Pratar du för att andra ska känna sig väl till mods även om du inte har något att säga?";
	Quiz[79].Text = "Använder du mer tid för att lära känna andra än dig själv?";
	Quiz[80].Text = "Är det viktigt för dig att skapa en social identitet?";
	Quiz[81].Text = "Är andra människors syn på dig viktigt för dig?";
	Quiz[82].Text = "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
	Quiz[83].Text = "Har du dålig tidsuppfattning?";
	Quiz[84].Text = "Har du svårt att göra anteckningar under föreläsningar?";
	Quiz[85].Text = "Har du svårigheter att läsa av klockor?";
	Quiz[86].Text = "Har du allting med som du kan tänkas bli ombedd att visa?";
	Quiz[87].Text = "Glömmer du föra över ett tal till nästa del i en beräkning?";
	Quiz[88].Text = "Gör du ofta stavfel?";
	Quiz[89].Text = "Glömmer du ofta var du lagt saker?";
	Quiz[90].Text = "Kan du enkelt komma ihåg sekvenser av gångna händelser?";
	Quiz[91].Text = "Tycker du om att läsa?";
	Quiz[92].Text = "Har du svårt för att komma ihåg poängställningar under spel?";
	Quiz[93].Text = "Har du svårt att känna igen telefonnummer om de sägs på ett annat sätt?";
	Quiz[94].Text = "Tycker du det är svårt att beräkna växel på ett köp?";
	Quiz[95].Text = "Tycker du det är enkelt att komma ihåg matematiska formler?";
	Quiz[96].Text = "Läser du sakta?";
	Quiz[97].Text = "Tycker du det är lätt att skriva ned sekvenser av idéer?";
	Quiz[98].Text = "Blir du förvirrad av instruktioner - särskilt flera på en gång?";
	Quiz[99].Text = "Ogillar du beröring?";
	Quiz[100].Text= "Är du lätt att distrahera eller överväldiga?";
	Quiz[101].Text= "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
	Quiz[102].Text= "Ser du ut, uppträder eller agerar som om du vore yngre än din biologiska ålder?";
	Quiz[103].Text= "Blir du förvånad och besviken när folk är ovänliga och inte tycks förstå eller acceptera dig som du är?";
	Quiz[104].Text= "Har du behov av att SE, ta i, eller själv bearbeta saker för att riktigt minnas dem?";
	Quiz[105].Text= "Är det svårt för dig att lära dig sånt som du inte är intresserad av?";
	Quiz[106].Text= "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
	Quiz[107].Text= "Tar du först in helheten innan du upptäcker detaljer?";
	Quiz[108].Text= "Jobbar du ofta över lunch och/eller raster för att rätta till misstag och/eller bli klar i tid?";
	Quiz[109].Text= "Föredrar du att få veta av andra hur saker fungerar snarare än att ta reda på det på ditt eget sätt?";
	Quiz[110].Text= "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
	Quiz[111].Text= "Accepterar du lätt kritik, tillrättavisningar och instruktioner?";
	Quiz[112].Text = "Ickeverbal IQ";

#endif
}

/*##########################################################################
#
#   Name       : TQuiz5::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz5::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("kolozzeum.com", "kolozzeum.com/kolozzeum/showthread.php?t=65633");
	AddReferer("aspalsta.net", "aspalsta.net/viewtopic.php?t=1951");
	AddReferer("wikipedia.org/wiki/As", "en.wikipedia.org/wiki/Aspergers");
	AddReferer("whoa.nu", "whoa.nu");
	AddReferer("forum.rpg.net", "forum.rpg.net/showthread.php?t=268587");
	AddReferer("99musik.se", "99musik.se/forum/showthread.php?t=12719");
	AddReferer("ufs.fi", "forum.ufs.fi/showthread.php?t=1873");
 }

/*##########################################################################
#
#   Name       : TQuiz5::UpdateReferer
#
#   Purpose....: Update a referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz5::UpdateReferer(TReferer *ref, int AsResult, int NtResult)
{
	int diff;

	ref->Count++;
	ref->AsResult += AsResult;
	ref->NtResult += NtResult;

	diff = AsResult - NtResult;

	if (diff >= 35)
		ref->ResultAs++;
	else
	{
		if (diff <= -35)
			ref->ResultNt++;
		else
			ref->ResultMixed++;
	}
}

/*##################  TQuiz5::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz5::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

		ref = 0;

		if (Row.Autism == 1 || Row.Aspie == 1)
			ref = &SelfAsRef;

		if (Row.ADHD == 1)
			ref = &SelfAddRef;

		if (Row.Aspie == 2 || Row.Autism == 2)
			ref = &DxAsRef;

		if (Row.ADHD == 2)
			ref = &DxAddRef;

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

		ref = 0;

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				ref = &MaleAsRef;
			else
				ref = &FemaleAsRef;
		}

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

	}
}

/*##########################################################################
#
#   Name       : TQuiz5::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz5::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;

	for (i = 0; i < N; i++)
		Quiz[i].NoAnswer = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		Row.Quiz[112] = Row.IqResult;

		for (i = 0; i < N - 1; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;

		}

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Gender == 1)
				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

			if (Row.Autism == 2 || Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.IqResult <= 10)
			LowIQ.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (Row.IQ >= 120)
			HighIQ.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}
		else

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuiz5::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz5::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("kolozzeum.com");
	DefineNt("rdos.net/sv");
	DefineNt("whoa.nu");
	DefineNt("99musik.se");
	DefineNt("ufs.fi");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("xmission.com/~winter");
	DefineAspie("delphiforums.com");
	DefineAspie("assupportgrouponline.co.uk");
}

/*##########################################################################
#
#   Name       : TQuiz5::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz5::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd)
{
	DefineCross(QuizIII, 0, 0);
	DefineCross(QuizIII, 1, 1);
	DefineCross(QuizNd,  2, 5);
	DefineCross(QuizNd,  3, 2);
	DefineCross(QuizNd,  4, 7);
	DefineCross(QuizNd,  5, 4);
	DefineCross(QuizNd,  6, 3);
	DefineCross(QuizNd,  7, 53);
	DefineCross(QuizNd,  8, 9);
	DefineCross(QuizNd,  9, 57);
	DefineCross(QuizNd,  10, 16);
	DefineCross(QuizNd,  11, 8);
	DefineCross(QuizNd,  12, 55);
	DefineCross(QuizNd,  13, 12);
	DefineCross(QuizNd,  14, 13);
	DefineCross(QuizNd,  15, 6);
	DefineCross(QuizNd,  16, 18);
	DefineCross(QuizNd,  17, 20);
	DefineCross(QuizNd,  18, 27);
	DefineCross(QuizNd,  19, 177);
	DefineCross(QuizNd,  20, 17);
	DefineCross(QuizNd,  21, 26);
	DefineCross(QuizNd,  22, 28);
	DefineCross(QuizNd,  23, 131);
	DefineCross(QuizNd,  24, 103);
	DefineCross(QuizNd,  25, 47);
	DefineCross(QuizNd,  26, 31);
	DefineCross(QuizNd,  27, 32);
	DefineCross(QuizNd,  28, 123);
	DefineCross(QuizNd,  29, 29);
	DefineCross(QuizNd,  30, 132);
	DefineCross(QuizNd,  31, 49);
	DefineCross(QuizNd,  32, 33);
	DefineCross(QuizNd,  33, 30);
	DefineCross(QuizNd,  34, 1);
	DefineCross(QuizNd,  35, 50);
	DefineCross(QuizNd,  36, 38);
	DefineCross(QuizNd,  37, 48);
	DefineCross(QuizNd,  38, 40);
	DefineCross(QuizNd,  39, 41);
	DefineCross(QuizNd,  40, 39);
	DefineCross(QuizNd,  41, 58);
	DefineCross(QuizNd,  42, 61);
	DefineCross(QuizNd,  43, 66);
	DefineCross(QuizNd,  44, 59);
	DefineCross(QuizNd,  45, 65);
	DefineCross(QuizNd,  46, 68);
	DefineCross(QuizNd,  47, 64);
	DefineCross(QuizNd,  48, 67);
	DefineCross(QuizNd,  49, 71);
	DefineCross(QuizIII, 50, 80);
	DefineCross(QuizIII, 51, 79);
	DefineCross(QuizI,   52, 27);
	DefineCross(QuizNd,  53, 87);
	DefineCross(QuizNd,  54, 82);
	DefineCross(QuizNd,  55, 78);
	DefineCross(QuizNd,  56, 83);
	DefineCross(QuizNd,  57, 77);
	DefineCross(QuizNd,  58, 91);
	DefineCross(QuizNd,  59, 195);
	DefineCross(QuizNd,  60, 126);
	DefineCross(QuizNd,  61, 127);
	DefineCross(QuizNd,  62, 93);
	DefineCross(QuizNd,  63, 124);
	DefineCross(QuizNd,  64, 112);
	DefineCross(QuizNd,  65, 92);
	DefineCross(QuizNd,  66, 113);
	DefineCross(QuizNd,  67, 129);
	DefineCross(QuizNd,  68, 137);
	DefineCross(QuizNd,  69, 97);
	DefineCross(QuizNd,  70, 98);
	DefineCross(QuizNd,  71, 99);
	DefineCross(QuizNd,  72, 101);
	DefineCross(QuizNd,  73, 120);
	DefineCross(QuizNd,  74, 108);
	DefineCross(QuizII,  75, 73);
	DefineCross(QuizIII, 76, 54);
	DefineCross(QuizIII, 77, 57);
	DefineCross(QuizNd,  78, 197);
	DefineCross(QuizNd,  79, 94);
	DefineCross(QuizIII, 80, 62);
	DefineCross(QuizIII, 81, 59);
	DefineCross(QuizNd,  82, 173);
	DefineCross(QuizNd,  83, 176);
	DefineCross(QuizNd,  84, 165);
	DefineCross(QuizNd,  85, 156);
	DefineCross(QuizNd,  86, 144);
	DefineCross(QuizNd,  87, 159);
	DefineCross(QuizNd,  88, 164);
	DefineCross(QuizNd,  89, 140);
	DefineCross(QuizNd,  90, 193);
	DefineCross(QuizNd,  91, 167);
	DefineCross(QuizNd,  92, 161);
	DefineCross(QuizNd,  93, 162);
	DefineCross(QuizNd,  94, 160);
	DefineCross(QuizNd,  95, 158);
	DefineCross(QuizNd,  96, 163);
	DefineCross(QuizNd,  97, 194);
	DefineCross(QuizNd,  98, 180);
	DefineCross(QuizNd,  99, 11);
	DefineCross(QuizNd,  100, 149);
	DefineCross(QuizNd,  101, 104);
	DefineCross(QuizNd,  102, 182);
	DefineCross(QuizNd,  103, 106);
	DefineCross(QuizNd,  104, 175);
	DefineCross(QuizNd,  105, 70);
	DefineCross(QuizNd,  106, 46);
	DefineCross(QuizNd,  107, 135);
	DefineCross(QuizNd,  108, 147);
	DefineCross(QuizNd,  109, 72);
	DefineCross(QuizNd,  110, 179);
	DefineCross(QuizNd,  111, 85);
	DefineGlobalId(      112, 357);
}

/*##########################################################################
#
#   Name       : TQuiz5::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz5::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
		    pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz);
}

/*##################  IsPca ##########################
*   Purpose....: Check quiz row against pca-type                 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int IsPca(TQuizRow *row, int PcaType)
{
    switch (PcaType)
	{
		case PCA_TYPE_ALL:
		case PCA_TYPE_MIXED:
            return TRUE;

        case PCA_TYPE_MALE:
			if (row->Gender == 1)
                return TRUE;
			else
                return FALSE;

        case PCA_TYPE_FEMALE:
            if (row->Gender == 2)
				return TRUE;
            else
                return FALSE;

        case PCA_TYPE_YOUNG:
            if (row->BirthYear >= 1980)
                return TRUE;
            else
				return FALSE;

		case PCA_TYPE_OLD:
			if (row->BirthYear <= 1965)
                return TRUE;
            else
				return FALSE;

        case PCA_TYPE_AS:
				if (row->Autism == 2 || row->Aspie == 2)
                return TRUE;
            else
                return FALSE;
                
    }
	return FALSE;
}

/*##################  TQuiz5::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz5::ExportExcelCase(const char *filename, int PcaType)
{
	TQuizRow Row;
	int i;
	int ival;
	char str[80];
	TFile file(filename, 0);

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < N; i++)
	{
		if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
		{
			file.Write("\"");

//  	      strncpy(str, Quiz[i].Text, 35);
//      	  str[35] = 0;
			sprintf(str, "#%d", i + 1);
			file.Write(str);

			file.Write("\"");
			if (i != N - 1)
				file.Write(", ");
		}
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (IsPca(&Row, PcaType))
		{
			sprintf(str, "\"%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < N; i++)
			{
				if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
				{
					if (i == 112)
					{
						ival = 100 * (Row.Quiz[i] - 3) / 9;
						sprintf(str, "\"%d.%02d\"", ival / 100, ival % 100);
						file.Write(str);
					}
					else
					{
						ival = Row.Quiz[i];
						if (ival)
							ival--;

						if (ival > 2)
							ival = 0;

						sprintf(str, "\"%d\"", ival);
						file.Write(str);
						if (i != N - 1)
							file.Write(", ");
					}
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuiz5::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz5::ExportExcelGroups(const char *filename)
{
	TQuizRow Row;
	int i;
	int ival;
	int group;
	int ok;
	char str[80];
	TFile file(filename, 0);
	int GroupSum[GROUP_COUNT];
	int GroupCount[GROUP_COUNT];

	file.Write("\"\", ");
	file.Write("\"\", ");

	for (i = 0; i < GROUP_COUNT; i++)
	{
		file.Write("\"");

		strncpy(str, Group[i].PosName, 35);
		str[35] = 0;
//        sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != GROUP_COUNT - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		for (i = 0; i < GROUP_COUNT; i++)
		{
			GroupSum[i] = 0;
			GroupCount[i] = 0;
		}

		for (i = 0; i < N; i++)
		{
			ival = Row.Quiz[i];
			if (ival > 2 && i < 112)
				ival = 0;

			if (ival)
			{
				if (Quiz[i].Reverse)
					ival = 3 - ival;
				else
					ival--;
				group = Quiz[i].MyGroup;
				GroupSum[group] += ival;
				GroupCount[group]++;
			}
		}

		ok = TRUE;
		for (i = 0; i < GROUP_COUNT; i++)
			if (GroupCount[i] == 0)
				ok = FALSE;

		if (ok)
		{
			sprintf(str, "\%d\", ", Row.AsResult);
			file.Write(str);

				sprintf(str, "\"%d\", ", Row.NtResult);
			file.Write(str);

			for (i = 0; i < GROUP_COUNT; i++)
			{
				ival = round(100.0 * (long double)GroupSum[i] / (long double)GroupCount[i]);
				sprintf(str, "\"%d\"", ival);
				file.Write(str);
				if (i != GROUP_COUNT - 1)
					file.Write(", ");
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuiz5::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz5::ImportMvsp(const char *filename, int PcaType)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2, d3, d4;
	int q;
	int count;
	TFile infile(filename);

	while (size = infile.Read(buf, MAX_IN_ROW))
	{
		buf[size] = 0;
		rowstr = strstr(buf, "#");
		if (rowstr)
		{
			rowstr++;
			ptr = strstr(rowstr, "\r");
			if (ptr)
				 *ptr = 0;
			else
				 rowstr = 0;
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (rowstr)
		{
		    for (i = 0; i < strlen(rowstr); i++)
			{
				switch (rowstr[i])
				{
					case ',':
						rowstr[i] = '.';
						break;

					case 0x9:
					case 0xd:
						rowstr[i] = ' ';
						break;
				}
			}

			if (sscanf(rowstr, "%d %Lf %Lf %Lf %Lf", &q, &d1, &d2, &d3, &d4) == 5)
			{
				if (PcaType != PCA_TYPE_MIXED)
				{
					if (PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_FEMALE)
						d2 = -d2;

//				    if (PcaType == PCA_TYPE_ALL)
//				        d3 = -d3;

				    if (PcaType == PCA_TYPE_ALL)
				        d4 = -d4;

//					if (d1 > 0 && d2 > 0)
//					{
//						if (d1 > d2)
//						{
//							d1 = d1 - d2;
//							d2 = 0;
//						}
//						else
//						{
//							d2 = d2 - d1;
//							d1 = 0;
//						}
//					}
				}

				switch (PcaType)
				{
					case PCA_TYPE_ALL:
						Quiz[q - 1].Pca[0] = d1;
						Quiz[q - 1].Pca[1] = d2;
						Quiz[q - 1].Pca[2] = d3;
						Quiz[q - 1].Pca[3] = d4;
						break;

					case PCA_TYPE_MALE:
						Quiz[q - 1].MalePca[0] = d1;
						Quiz[q - 1].MalePca[1] = d2;
						Quiz[q - 1].MalePca[2] = d3;
						Quiz[q - 1].MalePca[3] = d4;
						break;

					case PCA_TYPE_FEMALE:
						Quiz[q - 1].FemalePca[0] = d1;
						Quiz[q - 1].FemalePca[1] = d2;
						Quiz[q - 1].FemalePca[2] = d3;
						Quiz[q - 1].FemalePca[3] = d4;
						break;

					case PCA_TYPE_YOUNG:
						Quiz[q - 1].YoungPca[0] = d1;
						Quiz[q - 1].YoungPca[1] = d2;
						Quiz[q - 1].YoungPca[2] = d3;
						Quiz[q - 1].YoungPca[3] = d4;
						break;

					case PCA_TYPE_OLD:
						Quiz[q - 1].OldPca[0] = d1;
						Quiz[q - 1].OldPca[1] = d2;
						Quiz[q - 1].OldPca[2] = d3;
						Quiz[q - 1].OldPca[3] = d4;
						break;

					case PCA_TYPE_AS:
						Quiz[q - 1].AsPca[0] = d1;
						Quiz[q - 1].AsPca[1] = d2;
						Quiz[q - 1].AsPca[2] = d3;
						Quiz[q - 1].AsPca[3] = d4;
						break;

					case PCA_TYPE_MIXED:
						Quiz[q - 1].MixedPca[0] = d1;
						Quiz[q - 1].MixedPca[1] = d2;
						Quiz[q - 1].MixedPca[2] = d3;
						Quiz[q - 1].MixedPca[3] = d4;
						break;
				}
			}
		}
	}
}

/*##################  TIqEntry::TIqEntry ##########################
*   Purpose....: Initialize TIqEntry                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TIqEntry::TIqEntry()
{
	ValArr = 0;
	MaxSize = 0;

	Count = 0;
	Sum = 0;
}

/*##################  TIqEntry::~TIqEntry ##########################
*   Purpose....: Destructor for TIqEntry                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TIqEntry::~TIqEntry()
{
	if (ValArr)
		delete ValArr;
}

/*##################  TIqEntry::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TIqEntry::Add(TQuizRow *Row)
{
	 int val;
	 int i;
	 int *NewArr;

	 val = Row->IqResult;

	 if (ValArr == 0)
	 {
		  MaxSize = 8;
		  ValArr = new int[MaxSize];
	 }

	 if (Count >= MaxSize)
	 {
		  MaxSize = 3 * MaxSize / 2;
		  NewArr = new int[MaxSize];

		  for (i = 0; i < Count; i++)
				NewArr[i] = ValArr[i];

		  delete ValArr;
		  ValArr = NewArr;
	 }

	 ValArr[Count] = val;
	 Sum += val;
	 Count++;
}

/*##########################################################################
#
#   Name       : TIqEntry::GetMean
#
#   Purpose....: Get mean
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TIqEntry::GetMean()
{
	if (Count)
		return (long double)Sum / Count;
	else
		return 0;
}

/*##########################################################################
#
#   Name       : TIqEntry::GetSd
#
#   Purpose....: Get standard deviation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long double TIqEntry::GetSd()
{
	int e;
	int ival;
	long double val;
	long double rsum = 0;
	long double mean = GetMean();

	for (e = 0; e < Count; e++)
	{
		ival = ValArr[e];
		val = (long double)ival - mean;
		rsum += val * val;
	}

	if (Count > 1)
		return sqrtl(rsum / ((long double)Count - 1));
	else
		return 0;
}

/*##################  round ##########################
*   Purpose....: round long double to int       	   					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int round(long double val)
{
	return (int)(val + 0.5);
}

/*##################  WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
	char str[80];

	sprintf(str, "\n<td width=\"%d%\" colspan=2 valign=top>\n", RelWidth);
	File.Write(str);

	File.Write("<p align=\"center\">\n");
	File.Write("<b>\n");
}

/*##################  WriteFieldFooter ##########################
*   Purpose....: Write field footer for table    			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteFieldFooter(TFile &File)
{
	File.Write("\n</b>\n");
	File.Write("</p>\n");

	File.Write("</td>\n");
}

/*##################  TIqEntry::Write ##########################
*   Purpose....: Write a value                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TIqEntry::Write(TFile &file)
{
	long double mean;
	long double sd;
	long double dev;
	long double val;
	int ival;
	char str[80];

	if (Count > 1)
	{
		mean = GetMean();

#ifdef IQ_INTERVAL
		sd = GetSd();

		dev = 1.96 * sd / sqrtl(Count);

		val = mean - dev;
		if (val < 0.0)
			val = 0.0;

		ival = round(10.0 * val);

		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);

		val = mean + dev;
		if (val > 18.0)
			val = 18.0;

		ival = round(10.0 * val);

		sprintf(str, "-%d.%01d", ival / 10, ival % 10);
		file.Write(str);
#else
		ival = round(10.0 * mean);
		sprintf(str, "%d.%01d", ival / 10, ival % 10);
		file.Write(str);
#endif

	}
	else
		file.Write("-----");
}

/*##################  TIqAge::TIqAge ##########################
*   Purpose....: Initialize TIqAge                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
TIqAge::TIqAge()
{
}

/*##################  TIqAge::Add ##########################
*   Purpose....: Add an answer                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TIqAge::Add(TQuizRow *Row)
{
	int diff = Row->AsResult - Row->NtResult;


	if (Row->Gender == 1)
	{
		if (Row->Quiz[102] >= 2)
			MaleSlowMat.Add(Row);

		if (diff > 0)
		{
			MaleAs.Add(Row);

			if (diff > 50)
				MaleHighAs.Add(Row);
		}
		else
		{
			MaleNt.Add(Row);

			if (diff < -50)
				MaleHighNt.Add(Row);
		}
	}
	else
	{
		if (Row->Quiz[102] >= 2)
			FemaleSlowMat.Add(Row);

		if (diff > 0)
		{
			FemaleAs.Add(Row);

			if (diff > 50)
				FemaleHighAs.Add(Row);
		}
		else
        {
            FemaleNt.Add(Row);

            if (diff < -50)
                FemaleHighNt.Add(Row);
        }
    }
}

/*##################  TIqAge::WriteHeader ##########################
*   Purpose....: Write header in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TIqAge::WriteHeader(TFile &file)
{
	file.Write("<tr style='height:24.75pt'>");

	WriteCenteredFieldHeader(file, 25);
	file.Write("Age group");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("Slow mat.<br>M/F");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("High AS<br>M/F");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("AS<br>M/F");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("NT<br>M/F");
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	file.Write("High NT<br>M/F");
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TIqAge::Write ##########################
*   Purpose....: Write row in table                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TIqAge::WriteRow(TFile &file, const char *text)
{
	file.Write("<tr style='height:24.75pt'>");
	WriteCenteredFieldHeader(file, 25);
	file.Write(text);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	MaleSlowMat.Write(file);
	file.Write("<br>");
	FemaleSlowMat.Write(file);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	MaleHighAs.Write(file);
	file.Write("<br>");
	FemaleHighAs.Write(file);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	MaleAs.Write(file);
	file.Write("<br>");
	FemaleAs.Write(file);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	MaleNt.Write(file);
	file.Write("<br>");
	FemaleNt.Write(file);
	WriteFieldFooter(file);

	WriteCenteredFieldHeader(file, 12);
	MaleHighNt.Write(file);
	file.Write("<br>");
	FemaleHighNt.Write(file);
	WriteFieldFooter(file);

	file.Write("</tr>");
}

/*##################  TQuiz5::WriteIQ ##########################
*   Purpose....: Write IQ report                   			     	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz5::WriteIQ(const char *filename)
{
	TQuizRow Row;
    int i;
	int ival;
    char str[80];
    int age;
	TFile file(filename, 0);

	TIqAge iq_14;
	TIqAge iq_15_19;
	TIqAge iq_20_24;
	TIqAge iq_25_29;
	TIqAge iq_30_34;
	TIqAge iq_35_39;
	TIqAge iq_40;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		age = 2006 - Row.BirthYear;

		if (age < 15)
			iq_14.Add(&Row);
		else
	    {
	        if (age < 20)
	            iq_15_19.Add(&Row);
	        else
	        {
	            if (age < 25)
	                iq_20_24.Add(&Row);
	            else
	            {
	                if (age < 30)
	                    iq_25_29.Add(&Row);
	                else
	                {
	                    if (age < 35)
	                        iq_30_34.Add(&Row);
	                    else
						{
	                        if (age < 40)
	                            iq_35_39.Add(&Row);
							else
	                            iq_40.Add(&Row);
	                    }
	                }
	            }
	        }
	    }
	}

	file.Write("<table border=3 cellspacing=0 cellpadding=0>");

	TIqAge::WriteHeader(file);
        
	iq_14.WriteRow(file, "-14");
	iq_15_19.WriteRow(file, "15-19");
	iq_20_24.WriteRow(file, "20-24");
	iq_25_29.WriteRow(file, "25-29");
	iq_30_34.WriteRow(file, "30-34");
	iq_35_39.WriteRow(file, "35-39");
	iq_40.WriteRow(file, "40-");

	file.Write("</table>");
	
}
