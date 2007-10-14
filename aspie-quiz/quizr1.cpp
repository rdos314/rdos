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
# quizr1.cpp
# Quiz R1 class
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "quizr1.h"
#include "file.h"
#include "quizdbr1.h"

#define CI	1

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizR1::TQuizR1
#
#   Purpose....: Constructor for TQuizR1
#
#   In params..: Filename to load quiz 9 from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR1::TQuizR1(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9)
  : TQuiz(130),
	FDataFile(FileName)
{
	DefineCross(0, QuizI);
	DefineCross(1, QuizII);
	DefineCross(2, QuizIII);
	DefineCross(3, QuizNd);
	DefineCross(4, Quiz5);
	DefineCross(5, Quiz6);
	DefineCross(6, Quiz7);
	DefineCross(7, Quiz8);
	DefineCross(8, Quiz9);

	SetupTexts();
	DefineQuiz();
	InitReferers();
	LoadReferers();
    SetupControlGroups();
	SortReferers();
	SetupCross(QuizI, QuizII, QuizIII, QuizNd, Quiz5, Quiz6, Quiz7, Quiz8, Quiz9);
	LoadPopulations();
	Calculate();
}

/*##########################################################################
#
#   Name       : TQuizR1::~TQuizR1
#
#   Purpose....: Destructor for TQuizR1
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizR1::~TQuizR1()
{
}

/*##################  TQuizR1::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizR1::GetPcaCount()
{
	return 4;
}

/*##########################################################################
#
#   Name       : TQuizR1::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::WriteName(TFile &File)
{
	 File.Write("R1");
}

/*##################  TQuizR1::DefineQuiz ##########################
*   Purpose....: Define global IDs in quiz                	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::DefineQuiz()
{
}

/*##########################################################################
#
#   Name       : TQuizR1::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::SetupTexts()
{
  Quiz[14].Reverse = TRUE;
  Quiz[15].Reverse = TRUE;
  Quiz[16].Reverse = TRUE;
  Quiz[17].Reverse = TRUE;
  Quiz[18].Reverse = TRUE;
  Quiz[19].Reverse = TRUE;
  Quiz[20].Reverse = TRUE;
  Quiz[21].Reverse = TRUE;
  Quiz[32].Reverse = TRUE;
  Quiz[33].Reverse = TRUE;
  Quiz[34].Reverse = TRUE;
  Quiz[35].Reverse = TRUE;
  Quiz[36].Reverse = TRUE;
  Quiz[108].Reverse = TRUE;
  Quiz[109].Reverse = TRUE;

  Quiz[0].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[1].MyGroup = GROUP_MIXED;
  Quiz[2].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[3].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[4].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[5].MyGroup = GROUP_MIXED;
  Quiz[6].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[7].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[8].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[9].MyGroup = GROUP_ENVIRONMENT;
  Quiz[10].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[11].MyGroup = GROUP_NONVERBAL;
  Quiz[12].MyGroup = GROUP_NONVERBAL;
  Quiz[13].MyGroup = GROUP_SEX;
  Quiz[14].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[15].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[16].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[17].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[18].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[19].MyGroup = GROUP_NONVERBAL;
  Quiz[20].MyGroup = GROUP_NONVERBAL;
  Quiz[21].MyGroup = GROUP_MIXED;
  Quiz[22].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[23].MyGroup = GROUP_NONVERBAL;
  Quiz[24].MyGroup = GROUP_ASPIE_NVC;
  Quiz[25].MyGroup = GROUP_NONVERBAL;
  Quiz[26].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[27].MyGroup = GROUP_MIXED;
  Quiz[28].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[29].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[30].MyGroup = GROUP_NONVERBAL;
  Quiz[31].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[32].MyGroup = GROUP_NONVERBAL;
  Quiz[33].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[34].MyGroup = GROUP_NONVERBAL;
  Quiz[35].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[36].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[37].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[38].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[39].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[40].MyGroup = GROUP_MIXED;
  Quiz[41].MyGroup = GROUP_MIXED;
  Quiz[42].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[43].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[44].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[45].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[46].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[47].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[48].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[49].MyGroup = GROUP_MIXED;
  Quiz[50].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[51].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[52].MyGroup = GROUP_MIXED;
  Quiz[53].MyGroup = GROUP_OCD;
  Quiz[54].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[55].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[56].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[57].MyGroup = GROUP_NT_TALENT;
  Quiz[58].MyGroup = GROUP_OCD;
  Quiz[59].MyGroup = GROUP_OCD;
  Quiz[60].MyGroup = GROUP_OCD;
  Quiz[61].MyGroup = GROUP_OCD;
  Quiz[62].MyGroup = GROUP_OCD;
  Quiz[63].MyGroup = GROUP_OCD;
  Quiz[64].MyGroup = GROUP_OCD;
  Quiz[65].MyGroup = GROUP_ENVIRONMENT;
  Quiz[66].MyGroup = GROUP_OCD;
  Quiz[67].MyGroup = GROUP_MIXED;
  Quiz[68].MyGroup = GROUP_SENSORY;
  Quiz[69].MyGroup = GROUP_SENSORY;
  Quiz[70].MyGroup = GROUP_SENSORY;
  Quiz[71].MyGroup = GROUP_MIXED;
  Quiz[72].MyGroup = GROUP_SENSORY;
  Quiz[73].MyGroup = GROUP_SENSORY;
  Quiz[74].MyGroup = GROUP_SENSORY;
  Quiz[75].MyGroup = GROUP_SENSORY;
  Quiz[76].MyGroup = GROUP_ASPIE_BIOLOGY;
  Quiz[77].MyGroup = GROUP_SENSORY;
  Quiz[78].MyGroup = GROUP_MIXED;
  Quiz[79].MyGroup = GROUP_SENSORY;
  Quiz[80].MyGroup = GROUP_SENSORY;
  Quiz[81].MyGroup = GROUP_SENSORY;
  Quiz[82].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[83].MyGroup = GROUP_SENSORY;
  Quiz[84].MyGroup = GROUP_SEX;
  Quiz[85].MyGroup = GROUP_ASPIE_NVC;
  Quiz[86].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[87].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[88].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[89].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[90].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[91].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[92].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[93].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[94].MyGroup = GROUP_NT_BIOLOGY;
  Quiz[95].MyGroup = GROUP_NT_TALENT;
  Quiz[96].MyGroup = GROUP_ASPIE_SOCIAL;
  Quiz[97].MyGroup = GROUP_ENVIRONMENT;
  Quiz[98].MyGroup = GROUP_NT_TALENT;
  Quiz[99].MyGroup = GROUP_NONVERBAL;
  Quiz[100].MyGroup = GROUP_NT_TALENT;
  Quiz[101].MyGroup = GROUP_NT_TALENT;
  Quiz[102].MyGroup = GROUP_MIXED;
  Quiz[103].MyGroup = GROUP_NT_TALENT;
  Quiz[104].MyGroup = GROUP_NT_TALENT;
  Quiz[105].MyGroup = GROUP_ASPIE_TALENT;
  Quiz[106].MyGroup = GROUP_NT_TALENT;
  Quiz[107].MyGroup = GROUP_NONVERBAL;
  Quiz[108].MyGroup = GROUP_NONVERBAL;
  Quiz[109].MyGroup = GROUP_NONVERBAL;
  Quiz[110].MyGroup = GROUP_INSTINCT;
  Quiz[111].MyGroup = GROUP_SENSORY;
  Quiz[112].MyGroup = GROUP_SENSORY;
  Quiz[113].MyGroup = GROUP_MIXED;
  Quiz[114].MyGroup = GROUP_MIXED;
  Quiz[115].MyGroup = GROUP_ASPIE_NVC;
  Quiz[116].MyGroup = GROUP_INSTINCT;
  Quiz[117].MyGroup = GROUP_ASPIE_NVC;
  Quiz[118].MyGroup = GROUP_ASPIE_NVC;
  Quiz[119].MyGroup = GROUP_ASPIE_NVC;
  Quiz[120].MyGroup = GROUP_ASPIE_NVC;
  Quiz[121].MyGroup = GROUP_ASPIE_NVC;
  Quiz[122].MyGroup = GROUP_INSTINCT;
  Quiz[123].MyGroup = GROUP_ASPIE_NVC;
  Quiz[124].MyGroup = GROUP_ASPIE_NVC;
  Quiz[125].MyGroup = GROUP_ASPIE_NVC;
  Quiz[126].MyGroup = GROUP_MIXED;
  Quiz[127].MyGroup = GROUP_INSTINCT;
  Quiz[128].MyGroup = GROUP_INSTINCT;
  Quiz[129].MyGroup = GROUP_INSTINCT;

#ifdef ENGLISH
  Quiz[0].Text = "Have you felt different from others for most of your life?";
  Quiz[1].Text = "Do you feel much younger inside than your biological age?";
  Quiz[2].Text = "Are you more of an observer than one who participates in life?";
  Quiz[3].Text = "Have you had more difficulties than others of the same age when it comes to making friends or getting into relationships?";
  Quiz[4].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
  Quiz[5].Text = "Do you prefer the company of those older or youger than yourself to that of your peers?";
  Quiz[6].Text = "Do you mostly prefer playing/working/doing things on your own - in your own way and at your own pace?";
  Quiz[7].Text = "Do you get very tired after socializing, and need to regenerate alone?";
  Quiz[8].Text = "Do you dislike it when people drop by to visit you uninvited?";
  Quiz[9].Text = "Have you been bullied, abused or taken advantage of in various situations?";
  Quiz[10].Text = "Do you tend to feel nervous, shy, confused or left out in various social situations?";
  Quiz[11].Text = "Do you find it difficult to figure out how to behave in various situations?";
  Quiz[12].Text = "Do you tend to say or do things that are considered socially inappropriate?";
  Quiz[13].Text = "Have you had difficulties fitting into expected gender stereotypes, perhaps having interests and behaviors that are atypical for your gender?";
  Quiz[14].Text = "Is a large social network important to you?";
  Quiz[15].Text = "Do your friends mean more to you than hobbies and interests?";
  Quiz[16].Text = "Are you comfortable in social situations and with new people?";
  Quiz[17].Text = "Do you enjoy team sport and group endeavours?";
  Quiz[18].Text = "Is your image and social identity a priority to you?";
  Quiz[19].Text = "Are you intuitive about what people need from you?";
  Quiz[20].Text = "Do you have a good sense for what is the right thing to do socially?";
  Quiz[21].Text = "Can you easily remember people's names when you meet new people?";
  Quiz[22].Text = "Is it difficult or tiresome for you to talk?";
  Quiz[23].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
  Quiz[24].Text = "Do you stutter when stressed?";
  Quiz[25].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
  Quiz[26].Text = "Do you find it easier to communicate online than in real life?";
  Quiz[27].Text = "If asked to describe yourself, would you do so in a detached way, as if you were describing someone else?";
  Quiz[28].Text = "Do you tend to be more blunt and straightforward than others?";
  Quiz[29].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
  Quiz[30].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
  Quiz[31].Text = "Do you have problems with eye-contact (e.g. preferring to avoid it or staring 'too much')?";
  Quiz[32].Text = "Can you 'read between the lines'?";
  Quiz[33].Text = "Do you find it easy to describe your feelings?";
  Quiz[34].Text = "Do you know when you are expected to offer an apology?";
  Quiz[35].Text = "Do you talk to put others at ease even if you don't have anything special to convey?";
  Quiz[36].Text = "Are you good at small talk?";
  Quiz[37].Text = "Do you look younger than your biological age??";
  Quiz[38].Text = "Were you precocious as a child?";
  Quiz[39].Text = "Was your play more directed towards sorting, building or taking things apart than towards social games with other kids?";
  Quiz[40].Text = "Are you naturally nocturnal, i.e. do you tend to be most alert at night?";
  Quiz[41].Text = "Do you find the norms of hygiene too strict?";
  Quiz[42].Text = "Is your sense of humor different from mainstream or considered odd?";
  Quiz[43].Text = "Do you find yourself more attracted to things, ideas, music, computers, animals, buildings or vehicles than to people and social exchange?";
  Quiz[44].Text = "Are you very gifted in one or more areas?";
  Quiz[45].Text = "Do you have unconventional, often unique ways of solving problems?";
  Quiz[46].Text = "Do you hyperfocus on one interest at a time and become an expert on that subject?";
  Quiz[47].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
  Quiz[48].Text = "Do you have excellent vocabulary and/or a fascination with words?";
  Quiz[49].Text = "Did you learn to read on your own before you were taught in school?";
  Quiz[50].Text = "Are you fascinated by dates and/or numbers?";
  Quiz[51].Text = "Do you enjoy figuring out how things work?";
  Quiz[52].Text = "Are you punctual, conscientious and a perfectionist?";
  Quiz[53].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
  Quiz[54].Text = "Have you been called a 'know-it-all' because you feel compelled to correct people with accurate facts?";
  Quiz[55].Text = "Do you have strong sense of ethics and a tendency to stand up for your ideals & beliefs even if it means social or economical disadvantages?";
  Quiz[56].Text = "Do you tend to get so absorbed by your special interests that you forget everything else?";
  Quiz[57].Text = "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?";
  Quiz[58].Text = "Do you have certain routines which you need to follow?";
  Quiz[59].Text = "Does it cause chaos in you if your plans, environment or daily routines suddenly get changed?";
  Quiz[60].Text = "Do you have a need for symmetry, order and/or precision?";
  Quiz[61].Text = "Do you have strong attachments to certain objects?";
  Quiz[62].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
  Quiz[63].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
  Quiz[64].Text = "Before doing something or going somewhere, do you need to visualize the place you're going to or rehearse possible scenarios in your mind so as to prepare yourself?";
  Quiz[65].Text = "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?";
  Quiz[66].Text = "Do you sometimes have a need for comfort items like a blanket, stuffed animals etc?";
  Quiz[67].Text = "Do you self-harm, or have you done so in the past?";
  Quiz[68].Text = "Are you easily overexcited, stressed and overwhelmed by things like noise, crowds, clutter, patterns, flicker and movement?";
  Quiz[69].Text = "Do you have extra sensitive hearing?";
  Quiz[70].Text = "Do you have difficulties filtering out background noises when talking to someone?";
  Quiz[71].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
  Quiz[72].Text = "Do you have a very acute sense of taste?";
  Quiz[73].Text = "Do you have to be particular about what you eat and/or how it is combined on the plate in order to be able to eat?";
  Quiz[74].Text = "Do you have a very acute sense of smell?";
  Quiz[75].Text = "Are your eyes extra sensitive to stong light and glare?";
  Quiz[76].Text = "Do you have poor night vision?";
  Quiz[77].Text = "Do you have a well-developed sense of colour?";
  Quiz[78].Text = "Do you have (or have you had) a problem with squinting?";
  Quiz[79].Text = "Do you feel uncomfortable in fluorescent light?";
  Quiz[80].Text = "Are you sensitive to weather changes?";
  Quiz[81].Text = "Do you feel tortured by clothes tags, clothes that are too tight or are made in the 'wrong' material?";
  Quiz[82].Text = "Do you dislike being touched or hugged unless you're prepared or have asked for it?";
  Quiz[83].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
  Quiz[84].Text = "Are you fairly insensitive to physical pain, or even enjoy some types of pain?";
  Quiz[85].Text = "Do you have an odd posture or gait?";
  Quiz[86].Text = "Do you have poor balance, e.g. difficulty riding a bicycle, skating, standing on one leg?";
  Quiz[87].Text = "Do you have poor awareness or body control and a tendency to fall, stumble or bump into things?";
  Quiz[88].Text = "Do you have difficulties imitating & timing the movements of others, e.g. when learning new dance steps or in gym class?";
  Quiz[89].Text = "Do you have problems with ball sports?";
  Quiz[90].Text = "Do you have difficulties with two-handed tasks, e.g. eating with knife & fork, knitting, typing or playing an instrument?";
  Quiz[91].Text = "Do you have difficulties with activities requiring manual dexterity and precision, e.g drawing, sewing, tying shoe-laces, fastening buttons and handling small objects?";
  Quiz[92].Text = "Do you have difficulty writing by hand (dysgraphia)?";
  Quiz[93].Text = "Do you have a poor sense of how much pressure to apply when doing things with your hands and a tendency to drop, spill or break things by mistake?";
  Quiz[94].Text = "Do you have difficulties judging distances, height, depth or speed?";
  Quiz[95].Text = "Do you have poor concept of time?";
  Quiz[96].Text = "Do you have a tendency to be passive and not initiate things yourself?";
  Quiz[97].Text = "Has it been harder for you to make it on your own, than it seems to be for most others of the same age?";
  Quiz[98].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
  Quiz[99].Text = "Do you have a tendency to interpret things literally and difficulties understanding figures of speech, idioms, allegories etc?";
  Quiz[100].Text = "Are you easily distracted and/or bored?";
  Quiz[101].Text = "Do you find it hard to focus on or learn things you are not interested in?";
  Quiz[102].Text = "Are you somewhat of a daydreamer, often lost in your own thoughts?";
  Quiz[103].Text = "Do you tend to be hyperactive and restless?";
  Quiz[104].Text = "Do you tend to be impatient and impulsive, e.g. having trouble waiting for your turn?";
  Quiz[105].Text = "Do you have a hyperactive mind?";
  Quiz[106].Text = "Do have difficulties keeping things tidy ?";
  Quiz[107].Text = "Do you have problems recognizing faces when you meet people out of their usual environment (prosopagnosia)?";
  Quiz[108].Text = "Do you enjoy snuggling with people you like?";
  Quiz[109].Text = "Do you find it easy to understand and sympathise with those who function very differently from yourself?";
  Quiz[110].Text = "Are you sometimes fearless in situations that can be dangerous?";
  Quiz[111].Text = "Do you dislike shaking hands due to disliking the feel of skin-contact with others?";
  Quiz[112].Text = "Do you dislike shaking hands due to germophobia?";
  Quiz[113].Text = "Do you dislike shaking hands because handshakes feel unnatural?";
  Quiz[114].Text = "Do you dislike shaking hands for other reason?";
  Quiz[115].Text = "Do you talk to yourself?";
  Quiz[116].Text = "Do you have an urge to climb?";
  Quiz[117].Text = "Do you do any of the following when you're thinking, restless or bored: pacing; bouncing leg or foot; tapping fingers, pen or other object; doodling; fiddling with object e.g clicking pen; chewing on something?";
  Quiz[118].Text = "Do you do any of the following when you're happy: singing, humming or whistling to yourself?";
  Quiz[119].Text = "Do you do any of the following when anxious: twisting hands or fingers; rubbing hands, arms or thighs; biting lip, cheek or tongue?";
  Quiz[120].Text = "Do you do any of the following when bored: cracking joints; picking skin or scabs; peeling skin flakes; picking nose; pulling hairs; biting nails or fingertips; pulling cuticle?";
  Quiz[121].Text = "Do you do any of the following in order to calm yourself when excited, overwhelmed or overstimulated: rocking; flapping hands; tapping ears; pressing eyes?";
  Quiz[122].Text = "Do you do any of the following for fun: spin in circles; walk on toes; watch a spinning, blinking or glittering object?";
  Quiz[123].Text = "Do you clap your hands when excited?";
  Quiz[124].Text = "Do you grind your teeth when stressed or anxious?";
  Quiz[125].Text = "Do you clench your fists when angry?";
  Quiz[126].Text = "Do you suck your thumb for comfort?";
  Quiz[127].Text = "Do you wobble your hand slightly to indicate so-so?";
  Quiz[128].Text = "Do you enjoy lying on the ground looking at the sky?";
  Quiz[129].Text = "Are you good at sneaking up on people or animals?";
#endif

#ifdef SWEDISH
  Quiz[0].Text = "Har du känt dig annorlunda största delen av ditt liv?";
  Quiz[1].Text = "Känner du dig mycket yngre än din biologiska ålder?";
  Quiz[2].Text = "Känner du dig mer som en observatör än som en deltagare i livet?";
  Quiz[3].Text = "Har du haft svårare än dina jämnåriga att få vänner eller partners?";
  Quiz[4].Text = "Föredrar du bara att umgås med folk du känner väl, och helst på tu man hand eller i en mindre grupp?";
  Quiz[5].Text = "Brukar du föredra att umgås med människor som är äldre eller yngre än du själv framför jämnåriga?";
  Quiz[6].Text = "Brukar du föredra att leka/arbeta/göra saker själv - på ditt eget sätt och i din egen takt?";
  Quiz[7].Text = "Brukar du blir väldigt trött av att umgås med folk och efteråt behöva vila ut ifred?";
  Quiz[8].Text = "Ogillar du när folk kommer och hälsar på utan att ha blivit inbjudna?";
  Quiz[9].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
  Quiz[10].Text = "Brukar du bli nervös, blyg, förvirrad eller utanför i olika sociala situationer?";
  Quiz[11].Text = "Är det svårt att veta hur du ska bete dig i olika situationer?";
  Quiz[12].Text = "Brukar du säga eller göra saker som anses socialt opassande?";
  Quiz[13].Text = "Har du haft svårigheter att passa in i traditionella könsroller, kanske haft intressen och uppförande som är otypiska för ditt kön?";
  Quiz[14].Text = "Är ett stort socialt nätverk viktigt för dig?";
  Quiz[15].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
  Quiz[16].Text = "Känner du dig hemma i sociala situationer med nya människor?";
  Quiz[17].Text = "Tycker du om lagsporter och andra gruppaktiviteter?";
  Quiz[18].Text = "Är din image och sociala identitet väldigt viktig för dig?";
  Quiz[19].Text = "Känner du intuitivt vad folk behöver från dig?";
  Quiz[20].Text = "Har du en bra känla för vad som är rätt socialt?";
  Quiz[21].Text = "Har du lätt att komma ihåg vad folk heter när du möter nya människor?";
  Quiz[22].Text = "Finner du det svårt eller tröttsamt att tala?";
  Quiz[23].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
  Quiz[24].Text = "Stammar du när du blir stressad?";
  Quiz[25].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
  Quiz[26].Text = "Tycker du att det är lättare att kommunicera via dator än i verkliga livet?";
  Quiz[27].Text = "Om du blev ombedd att beskriva dig själv, skulle du då göra det på objektivt sätt, som om du beskrev någon annan?";
  Quiz[28].Text = "Brukar du vara mer rak och rättfram i din kommunikation än andra?";
  Quiz[29].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
  Quiz[30].Text = "Brukar du ha svårt att tolka kroppsspråk och ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
  Quiz[31].Text = "Har du problem med ögonkontakt (t ex att du föredrar att undvika det eller stirrar 'för mycket')?";
  Quiz[32].Text = "Kan du 'läsa mellan raderna'?";
  Quiz[33].Text = "Är det lätt för dig att beskriva dina känslor?";
  Quiz[34].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
  Quiz[35].Text = "Brukar du prata för att få andra att känna sig väl till mods även om du inte har nåt speciellt att berätta?";
  Quiz[36].Text = "Är du bra på kallprat?";
  Quiz[37].Text = "Ser du yngre ut än din biologiska ålder?";
  Quiz[38].Text = "Var du \"lillgammal\" som barn?";
  Quiz[39].Text = "Brukade dina lekar mer bestå i att sortera, bygga eller ta isär saker än i sociala lekar med andra barn?";
  Quiz[40].Text = "Är du en nattmänniska, d.v.s. brukar du vara som piggast på kvällen/natten?";
  Quiz[41].Text = "Tycker du att normerna för hygien är för strikta?";
  Quiz[42].Text = "Är ditt sinne för humor annorlunda än andras eller ansett som udda?";
  Quiz[43].Text = "Är du i grunden mer intresserad av saker, idéer, filmer, datorer, musik, djur, hus, fordon el dyl, än av människor och social samvaro?";
  Quiz[44].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
  Quiz[45].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
  Quiz[46].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
  Quiz[47].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
  Quiz[48].Text = "Har du utmärkt vokabulär och intresse för språk?";
  Quiz[49].Text = "Lärde du dig att läsa själv innan du började skolan?";
  Quiz[50].Text = "Är du fascinerad av datum och/eller siffror?";
  Quiz[51].Text = "Tycker du om att lista ut hur saker fungerar?";
  Quiz[52].Text = "Är du punktlig, noggrann och perfektionistisk?";
  Quiz[53].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
  Quiz[54].Text = "Har du blivit kallad 'besserwisser' för att du känner dig manad att korrigera andra med korrekta fakta?";
  Quiz[55].Text = "Har du stark känsla för etik och en tendens att hålla fast vid dina ideal, övertygelser och principer även om det är till din nackdel, t ex socialt eller ekonomiskt?";
  Quiz[56].Text = "Brukar du bli så absorberad av dina specialintressen att du glömmer allting annat?";
  Quiz[57].Text = "Har du svårt att göra flera saker samtidigt, snabbt skifta fokus från en sak till en annan och därför behöver göra klart det du håller på med innan du kan ta itu med något annat?";
  Quiz[58].Text = "Har du vissa rutiner som du har behov av att följa?";
  Quiz[59].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer eller rutiner?";
  Quiz[60].Text = "Har du ett behov av symmetri, ordning och/eller precision?";
  Quiz[61].Text = "Är du exceptionellt fäst vid vissa saker?";
  Quiz[62].Text = "Har du behov av att sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
  Quiz[63].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
  Quiz[64].Text = "Innan du gör något eller åker någonstans, behöver du ha en inre bild av platsen eller mentalt öva på tänkbara scenarier för att förbereda dig?";
  Quiz[65].Text = "Brukar du bli stressad och få panik eller kortslutning i hjärnan i nya och kravfyllda situationer?";
  Quiz[66].Text = "Har du ibland behov av gosefilt, kramdjur eller liknande?";
  Quiz[67].Text = "Brukar du ägna dig åt självskadande beteende, eller har du gjort det tidigare?";
  Quiz[68].Text = "Blir du lätt överstimulerad och stressad av för mycket ljud, mönster, flimmer, oreda, trängsel och rörelse?";
  Quiz[69].Text = "Har du extra känslig hörsel?";
  Quiz[70].Text = "Har du svårt att filtrera bort bakgrundsljud när du talar med någon?";
  Quiz[71].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
  Quiz[72].Text = "Har du extra känsligt smaksinne?";
  Quiz[73].Text = "Måste du vara petig med vad du äter och/eller hur maten kombineras på tallriken för att kunna äta?";
  Quiz[74].Text = "Har du extra känsligt luktsinne?";
  Quiz[75].Text = "Är dina ögon extra känsliga för starkt ljus och bländning?";
  Quiz[76].Text = "Har du dåligt mörkerseende?";
  Quiz[77].Text = "Har du välutvecklat färgseende?";
  Quiz[78].Text = "Har du (eller har du haft) problem med skelning?";
  Quiz[79].Text = "Är du känslig för lyrsrörsljus?";
  Quiz[80].Text = "Är du känslig för väderomslag?";
  Quiz[81].Text = "Pinas du av skavande sömmar och etiketter, kläder som sitter åt eller som är gjorda i 'fel' material?";
  Quiz[82].Text = "Ogillar du att bli tagen i eller kramad om du inte är beredd eller bett om det?";
  Quiz[83].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
  Quiz[84].Text = "Är du okänslig för smärta eller till och med tycker om viss sorts smärta?";
  Quiz[85].Text = "Har du ovanlig kroppshållning eller gångstil?";
  Quiz[86].Text = "Har du dåligt balanssinne, t ex svårt att cykla, åka skridskor, stå på ett ben?";
  Quiz[87].Text = "Har du dålig koll på eller kontroll över kroppen och tendens att ramla, snubbla eller springa in i saker?";
  Quiz[88].Text = "Har du svårt att imitera och tamja andras rörelser, t ex när du ska lära dig nya danssteg eller göra gymnastikpass i grupp?";
  Quiz[89].Text = "Har du problem med med bollsporter?";
  Quiz[90].Text = "Har du svårt med aktiviteter där man använder båda händerna samtidigt, t ex äta med kniv & gaffel, sticka, skriva maskin eller spela ett instrument?";
  Quiz[91].Text = "Har du svårigheter med aktiviteter som kräver finmotorisk precision, t ex att rita, sy, knyta skosnören, knäppa knappar och hantera små föremål?";
  Quiz[92].Text = "Har du svårt att skriva för hand (dysgrafi)?";
  Quiz[93].Text = "Har du svårt att avgöra hur hårt man bör ta i när man gör saker med händerna och en tendens att tappa, spilla eller ha sönder saker av misstag?";
  Quiz[94].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och fart?";
  Quiz[95].Text = "Har du dålig tidsuppfattning?";
  Quiz[96].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
  Quiz[97].Text = "Har du haft svårare att klara dig själv än andra i samma ålder?";
  Quiz[98].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden??";
  Quiz[99].Text = "Har du en tendens att tolka saker bokstavligt och svårigheter att förstå talesätt, idiom, allegorier o dyl?";
  Quiz[100].Text = "Blir du lätt distraherad och/eller uttråkad?";
  Quiz[101].Text = "Har du svårt att koncenterera dig på eller lära dig saker du inte är intresserad av?";
  Quiz[102].Text = "Är du lite av en dagdrömmare, ofta borta i dina egna tankar?";
  Quiz[103].Text = "Brukar du vara hyperaktiv och rastlös?";
  Quiz[104].Text = "Brukar du vara otålig och impulsiv och t ex ha svårt att vänta på din tur?";
  Quiz[105].Text = "Är du mentalt hyperaktiv?";
  Quiz[106].Text = "Har du svårt att hålla ordning omkring dig?";
  Quiz[107].Text = "Har du svårt att känna igen ansikten när du möter folk på andra ställen än där du är van att se dem?";
  Quiz[108].Text = "Gillar du att mysa ihop med personer du tycker om?";
  Quiz[109].Text = "Har du lätt att förstå och känna sympati även för dem som fungerar väldigt annorlunda än du själv?";
  Quiz[110].Text = "Händer det att du är orädd i situationer som faktiskt kan vara farliga?";
  Quiz[111].Text = "Ogillar du att ta i hand pga att du inte gillar känslan av hudkontakt med andra?";
  Quiz[112].Text = "Ogillar du att ta i hand pga bacillskräck?";
  Quiz[113].Text = "Ogillar du att ta i hand för att handslag känns onaturligt?";
  Quiz[114].Text = "Ogillar du att ta i hand av annan orsak?";
  Quiz[115].Text = "Pratar du med dig själv?";
  Quiz[116].Text = "Har du ett behov av att klättra?";
  Quiz[117].Text = "Brukar du göra något av följande när du tänker, är rastlös eller uttråkad: vanka; vippa foten eller benet; trumma med fingrarna, en penna eller annat objekt; kludda; klicka penna, pilla eller tugga på något?";
  Quiz[118].Text = "Brukar du göra något av följande när du är glad: sjunga, nynna eller vissla för dig själv?";
  Quiz[119].Text = "Brukar du göra något av följande när du är orolig: vrida dina händer eller fingar; gnugga händer, överarmar eller lår; bita dig i läppen, kinden eller tungan?";
  Quiz[120].Text = "Brukar du göra något av följande när du är uttråkad: knäcka leder; pila på huden; dra hudflagor; plocka sårskorpor; peta näsan; dra ut hårstrån; bita på naglarna eller fingertopparna; dra i nagelbanden?";
  Quiz[121].Text = "Brukar du göra något av följande för att lugna ner dig när du blivit upphetsad, stressad eller överstimulerad: gunga med överkroppen, flaxa med händerna, slå på öronen, pressa händerna mot ögonen?";
  Quiz[122].Text = "Brukar du göra något av följande för att det är roligt: snurra runt, runt; gå på tå; titta på ett snurrande, blinkande eller glittrande föremål?";
  Quiz[123].Text = "Klappar du med händerna när du är upprymd?";
  Quiz[124].Text = "Gnisslar du med tänderna när du är stressad eller har ångest?";
  Quiz[125].Text = "Knyter du nävarna när du är arg?";
  Quiz[126].Text = "Suger du på tummen när du behöver tröst?";
  Quiz[127].Text = "Brukar du vippa handen lite för att indikera \"sådär\"?";
  Quiz[128].Text = "Gillar du att ligga på marken och studera himlen?";
  Quiz[129].Text = "Är du bra att smyga på människor eller djur?";
#endif

}

/*##########################################################################
#
#   Name       : TQuizR1::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("aspalsta.net", "aspalsta.net/viewtopic.php?t=1951");
	AddReferer("circvsmaximvs.com", "circvsmaximvs.com/showthread.php?t=14129");
	AddReferer("panterachat.com", "panterachat.com/phpBB/viewtopic.php?t=24332");
	AddReferer("kaytastrophe.com", "kaytastrophe.com/index.php?topic=708.0");
}

/*##################  TQuizR1::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::LoadReferers()
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
			UpdateReferer(ref, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism == 1 || Row.Aspie == 1)
			UpdateReferer(&SelfAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 1)
			UpdateReferer(&SelfAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Aspie == 2 || Row.Autism == 2)
			UpdateReferer(&DxAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.ADHD == 2)
			UpdateReferer(&DxAddRef, Row.AsResult, Row.NtResult, Row.GroupResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.Gender == 1)
				UpdateReferer(&MaleAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);
			else
				UpdateReferer(&FemaleAsRef, Row.AsResult, Row.NtResult, Row.GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizR1::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::LoadPopulations()
{
	TQuizRow Row;
	int i;
	TReferer *ref;
	int aspie;
	int id;
	char score;
	int IdArr[MAX_QUESTIONS];

	for (i = 0; i < N; i++)
	{
		Quiz[i].NoAnswer = 0;
		IdArr[i] = GetGlobalId(i);
    }

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
        BirthMonth.Add(Row.AsResult, Row.NtResult, Row.BirthMonth);

		for (i = 0; i < N; i++)
		{
			if (Row.Quiz[i] == 0)
				Quiz[i].NoAnswer++;
		    else
			{
			    score = Row.Quiz[i] - 1;
			    id = IdArr[i];
			    
			    DsmAutism.Add(Row.Autism, id, score);
			    DsmAs.Add(Row.Aspie, id, score);
			    DsmAdd.Add(Row.ADHD, id, score);
			    DsmTs.Add(Row.TS, id, score);
			    DsmDyslexia.Add(Row.Dyslexia, id, score);
			    DsmDyscalculia.Add(Row.Dyscalculia, id, score);
			    DsmOCD.Add(Row.OCD, id, score);
				DsmBipolar.Add(Row.Bipolar, id, score);
				DsmSocialPhobia.Add(Row.Social, id, score);
			}
		}

		aspie = FALSE;

		if (Row.Autism || Row.Aspie)
			aspie = TRUE;

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (Row.Autism || Row.Aspie)
		{
			if (Row.AsResult < Row.NtResult)
				LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Gender == 1)
			{
				if (Row.BirthYear > 1986)
					YoungMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

				AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			}
			else
			{
				if (Row.BirthYear > 1986)
					YoungFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

				AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			}

			if (Row.Autism == 2)
				Autism.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Aspie == 2)
				As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

			if (Row.Autism == 1 || Row.Aspie == 1)
				AspieControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.ADHD)
		{
			Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (strlen(Row.Referer) == 0)
		{
			Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizR1::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::SetupControlGroups()
{
	DefineNt("flashback.info");
	DefineNt("rdos.net/sv");
	DefineNt("circvsmaximvs.com");
	DefineNt("panterachat.com");
	DefineNt("kaytastrophe.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("assupportgrouponline.co.uk");
	DefineAspie("neurodiversity.com/diagnostic_instruments.html");
}

/*##########################################################################
#
#   Name       : TQuizR1::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9)
{
    DefineCross(Quiz9, 0, 51);
    DefineCross(QuizII, 1, 20);
    DefineCross(QuizI, 2, 66);
    DefineCross(Quiz9, 3, 50);
    DefineCross(QuizI, 4, 33);
    DefineCross(QuizI, 5, 32);
    DefineCross(Quiz8, 6, 69);
    DefineCross(Quiz9, 7, 55);
    DefineCross(Quiz6, 8, 118);
    DefineCross(Quiz7, 9, 119);
    DefineCross(Quiz9, 10, 54);
  DefineGlobalId( 11, 486);
  DefineGlobalId( 12, 487);
  DefineGlobalId( 13, 488);
    DefineCross(Quiz9, 14, 74);
    DefineCross(Quiz8, 15, 70);
    DefineCross(Quiz9, 16, 69);
    DefineCross(Quiz9, 17, 65);
  DefineGlobalId( 18, 489);
    DefineCross(Quiz6, 19, 35);
    DefineCross(Quiz9, 20, 100);
  DefineGlobalId( 21, 490);
    DefineCross(QuizI, 22, 13);
    DefineCross(Quiz9, 23, 105);
    DefineCross(Quiz8, 24, 8);
    DefineCross(Quiz9, 25, 98);
    DefineCross(Quiz9, 26, 59);
  DefineGlobalId( 27, 491);
  DefineGlobalId( 28, 492);
    DefineCross(Quiz9, 29, 64);
    DefineCross(QuizIII, 30, 25);
  DefineGlobalId( 31, 493);
    DefineCross(Quiz9, 32, 102);
  DefineGlobalId( 33, 494);
    DefineCross(Quiz9, 34, 109);
    DefineCross(Quiz7, 35, 66);
	DefineCross(QuizNd, 36, 36);
    DefineCross(QuizI, 37, 41);
  DefineGlobalId( 38, 495);
  DefineGlobalId( 39, 496);
  DefineGlobalId( 40, 497);
    DefineCross(Quiz6, 41, 139);
    DefineCross(Quiz9, 42, 61);
    DefineCross(QuizI, 43, 68);
    DefineCross(Quiz9, 44, 35);
    DefineCross(Quiz9, 45, 30);
	 DefineCross(Quiz9, 46, 31);
    DefineCross(Quiz9, 47, 34);
    DefineCross(Quiz9, 48, 36);
    DefineCross(Quiz7, 49, 143);
    DefineCross(Quiz7, 50, 117);
    DefineCross(Quiz9, 51, 37);
    DefineCross(QuizII, 52, 69);
    DefineCross(Quiz9, 53, 115);
  DefineGlobalId( 54, 498);
    DefineCross(QuizI, 55, 98);
    DefineCross(Quiz8, 56, 120);
    DefineCross(QuizI, 57, 26);
    DefineCross(Quiz9, 58, 117);
    DefineCross(Quiz9, 59, 110);
    DefineCross(Quiz9, 60, 118);
    DefineCross(Quiz9, 61, 116);
    DefineCross(Quiz9, 62, 114);
    DefineCross(Quiz9, 63, 112);
  DefineGlobalId( 64, 499);
    DefineCross(Quiz7, 65, 83);
    DefineCross(Quiz7, 66, 90);
  DefineGlobalId( 67, 500);
    DefineCross(QuizNd, 68, 10);
  DefineGlobalId( 69, 501);
    DefineCross(Quiz9, 70, 106);
    DefineCross(Quiz8, 71, 3);
    DefineCross(Quiz9, 72, 21);
    DefineCross(QuizI, 73, 58);
    DefineCross(Quiz9, 74, 24);
  DefineGlobalId( 75, 502);
  DefineGlobalId( 76, 503);
  DefineGlobalId( 77, 504);
    DefineCross(Quiz9, 78, 20);
    DefineCross(Quiz9, 79, 26);
  DefineGlobalId( 80, 505);
	 DefineCross(Quiz8, 81, 6);
  DefineGlobalId( 82, 506);
    DefineCross(Quiz9, 83, 27);
    DefineCross(Quiz9, 84, 29);
    DefineCross(Quiz6, 85, 31);
  DefineGlobalId( 86, 507);
  DefineGlobalId( 87, 508);
  DefineGlobalId( 88, 509);
  DefineGlobalId( 89, 510);
  DefineGlobalId( 90, 511);
  DefineGlobalId( 91, 512);
    DefineCross(Quiz8, 92, 25);
  DefineGlobalId( 93, 513);
    DefineCross(Quiz9, 94, 11);
    DefineCross(Quiz7, 95, 122);
    DefineCross(QuizI, 96, 31);
    DefineCross(QuizI, 97, 30);
    DefineCross(QuizI, 98, 5);
    DefineCross(QuizIII, 99, 32);
    DefineCross(QuizII, 100, 64);
  DefineGlobalId( 101, 514);
  DefineGlobalId( 102, 515);
  DefineGlobalId( 103, 516);
  DefineGlobalId( 104, 517);
  DefineGlobalId( 105, 518);
  DefineGlobalId( 106, 519);
    DefineCross(Quiz6, 107, 36);
  DefineGlobalId( 108, 520);
  DefineGlobalId( 109, 521);
  DefineGlobalId( 110, 522);
  DefineGlobalId( 111, 523);
  DefineGlobalId( 112, 524);
  DefineGlobalId( 113, 525);
  DefineGlobalId( 114, 526);
    DefineCross(Quiz9, 115, 88);
	 DefineCross(Quiz9, 116, 93);
  DefineGlobalId( 117, 527);
  DefineGlobalId( 118, 528);
  DefineGlobalId( 119, 529);
  DefineGlobalId( 120, 530);
  DefineGlobalId( 121, 531);
  DefineGlobalId( 122, 532);
  DefineGlobalId( 123, 533);
  DefineGlobalId( 124, 534);
  DefineGlobalId( 125, 535);
  DefineGlobalId( 126, 536);
  DefineGlobalId( 127, 537);
  DefineGlobalId( 128, 538);
  DefineGlobalId( 129, 540);

}

/*##########################################################################
#
#   Name       : TQuizR1::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizR1::GetReferer(const char *referer, TPopulation *pop)
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
			pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz, Row.GroupResult);
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

/*##################  TQuizR1::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::ExportExcelCase(const char *filename, int PcaType)
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
			file.Write("\n");
		}
	}
}

/*##################  TQuizR1::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::ExportExcelAspie(const char *filename)
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
		file.Write("\"");

		sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != N - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		sprintf(str, "\"%d\", ", Row.AsResult);
		file.Write(str);

		sprintf(str, "\"%d\", ", Row.NtResult);
		file.Write(str);

		for (i = 0; i < N; i++)
		{
			ival = Row.Quiz[i];

			if (ival)
			{
				if (Quiz[i].Reverse)
					ival = 3 - ival;
				else
					ival--;
			}


			if (ival > 2)
				ival = 0;

			sprintf(str, "\"%d\"", ival);
			file.Write(str);
			if (i != N - 1)
				file.Write(", ");
		}
		file.Write("\n");
	}
}

/*##################  TQuizR1::ExportExcelGroups ##########################
*   Purpose....: Export group cases in excel format             	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::ExportExcelGroups(const char *filename)
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

/*##################  TQuizR1::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizR1::ImportMvsp(const char *filename, int PcaType)
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
//					if (PcaType == PCA_TYPE_FEMALE)
//						d2 = -d2;

					if (PcaType == PCA_TYPE_ALL)
						d3 = -d3;

//					if (PcaType == PCA_TYPE_ALL)
//						d4 = -d4;

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
