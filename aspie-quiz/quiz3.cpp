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
# quiz3.cpp
# Quiz III class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "quiz3.h"
#include "file.h"
#include "quizdb3.h"

#define MAX_IN_ROW		1024

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizIII::TQuizIII
#
#   Purpose....: Constructor for TQuizIII
#
#   In params..: Filename to load quiz III from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizIII::TQuizIII(const char *FileName, TQuiz *QuizI, TQuiz *QuizII)
  : FDataFile(FileName)
{
    DefineCross(0, QuizI);
    DefineCross(1, QuizII);

    SetupTexts();
    InitReferers();
    LoadReferers();
    SetupControlGroups();
	SortReferers();
    LoadPopulations();
    SetupCross(QuizI, QuizII);
    Calculate();
}

/*##########################################################################
#
#   Name       : TQuizIII::~TQuizIII
#
#   Purpose....: Destructor for TQuizIII
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizIII::~TQuizIII()
{
}

/*##########################################################################
#
#   Name       : TQuizIII::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizIII::WriteName(TFile &File)
{
    File.Write("III");
}

/*##########################################################################
#
#   Name       : TQuizIII::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizIII::SetupTexts()
{
	Quiz[49].Reverse = TRUE;
    Quiz[54].Reverse = TRUE;
	Quiz[55].Reverse = TRUE;
	Quiz[56].Reverse = TRUE;
	Quiz[57].Reverse = TRUE;
	Quiz[58].Reverse = TRUE;
	Quiz[59].Reverse = TRUE;
	Quiz[61].Reverse = TRUE;
	Quiz[62].Reverse = TRUE;

	Quiz[0].MyGroup = GROUP_SENSORY;
	Quiz[1].MyGroup = GROUP_SENSORY;
	Quiz[2].MyGroup = GROUP_SENSORY;
	Quiz[3].MyGroup = GROUP_SENSORY;
	Quiz[4].MyGroup = GROUP_SENSORY;
	Quiz[5].MyGroup = GROUP_SENSORY;
	Quiz[6].MyGroup = GROUP_SENSORY;
	Quiz[7].MyGroup = GROUP_SENSORY;
	Quiz[8].MyGroup = GROUP_SENSORY;
	Quiz[9].MyGroup = GROUP_SENSORY;
	Quiz[10].MyGroup = GROUP_BIOLOGY;
	Quiz[11].MyGroup = GROUP_BIOLOGY;
	Quiz[12].MyGroup = GROUP_BIOLOGY;
	Quiz[13].MyGroup = GROUP_BIOLOGY;
	Quiz[14].MyGroup = GROUP_BIOLOGY;
	Quiz[15].MyGroup = GROUP_SENSORY;
	Quiz[16].MyGroup = GROUP_BIOLOGY;
	Quiz[17].MyGroup = GROUP_BIOLOGY;
	Quiz[18].MyGroup = GROUP_BIOLOGY;
	Quiz[19].MyGroup = GROUP_BIOLOGY;
	Quiz[20].MyGroup = GROUP_SENSORY;
	Quiz[21].MyGroup = GROUP_BIOLOGY;
	Quiz[22].MyGroup = GROUP_BIOLOGY;
	Quiz[23].MyGroup = GROUP_BIOLOGY;
	Quiz[24].MyGroup = GROUP_MIXED;
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
	Quiz[35].MyGroup = GROUP_LANGUAGE;
	Quiz[36].MyGroup = GROUP_LANGUAGE;
	Quiz[37].MyGroup = GROUP_LANGUAGE;
	Quiz[38].MyGroup = GROUP_LANGUAGE;
	Quiz[39].MyGroup = GROUP_LANGUAGE;
	Quiz[40].MyGroup = GROUP_LANGUAGE;
	Quiz[41].MyGroup = GROUP_LANGUAGE;
	Quiz[42].MyGroup = GROUP_LANGUAGE;
	Quiz[43].MyGroup = GROUP_LANGUAGE;
	Quiz[44].MyGroup = GROUP_SOCIAL;
	Quiz[45].MyGroup = GROUP_SOCIAL;
	Quiz[46].MyGroup = GROUP_SOCIAL;
	Quiz[47].MyGroup = GROUP_SOCIAL;
	Quiz[48].MyGroup = GROUP_SOCIAL;
	Quiz[49].MyGroup = GROUP_SOCIAL;
	Quiz[50].MyGroup = GROUP_SOCIAL;
	Quiz[51].MyGroup = GROUP_SOCIAL;
	Quiz[52].MyGroup = GROUP_SOCIAL;
	Quiz[53].MyGroup = GROUP_SOCIAL;
	Quiz[54].MyGroup = GROUP_NT_RELATION;
	Quiz[55].MyGroup = GROUP_NT_RELATION;
	Quiz[56].MyGroup = GROUP_NT_RELATION;
	Quiz[57].MyGroup = GROUP_NT_RELATION;
	Quiz[58].MyGroup = GROUP_NT_RELATION;
	Quiz[59].MyGroup = GROUP_NT_RELATION;
	Quiz[60].MyGroup = GROUP_MIXED;
	Quiz[61].MyGroup = GROUP_NT_RELATION;
	Quiz[62].MyGroup = GROUP_NT_RELATION;
	Quiz[63].MyGroup = GROUP_SEX;
	Quiz[64].MyGroup = GROUP_SEX;
	Quiz[65].MyGroup = GROUP_SEX;
	Quiz[66].MyGroup = GROUP_SEX;
	Quiz[67].MyGroup = GROUP_SEX;
	Quiz[68].MyGroup = GROUP_SEX;
	Quiz[69].MyGroup = GROUP_FOCUS;
	Quiz[70].MyGroup = GROUP_FOCUS;
	Quiz[71].MyGroup = GROUP_FOCUS;
	Quiz[72].MyGroup = GROUP_FOCUS;
	Quiz[73].MyGroup = GROUP_FOCUS;
	Quiz[74].MyGroup = GROUP_FOCUS;
	Quiz[75].MyGroup = GROUP_FOCUS;
	Quiz[76].MyGroup = GROUP_FOCUS;
	Quiz[77].MyGroup = GROUP_FOCUS;
	Quiz[78].MyGroup = GROUP_FOCUS;
	Quiz[79].MyGroup = GROUP_REPETITION;
	Quiz[80].MyGroup = GROUP_REPETITION;
	Quiz[81].MyGroup = GROUP_REPETITION;
	Quiz[82].MyGroup = GROUP_REPETITION;
	Quiz[83].MyGroup = GROUP_REPETITION;
	Quiz[84].MyGroup = GROUP_REPETITION;
	Quiz[85].MyGroup = GROUP_REPETITION;
	Quiz[86].MyGroup = GROUP_REPETITION;
	Quiz[87].MyGroup = GROUP_REPETITION;
	Quiz[88].MyGroup = GROUP_PHYSICAL;
	Quiz[89].MyGroup = GROUP_PHYSICAL;
	Quiz[90].MyGroup = GROUP_PHYSICAL;
	Quiz[91].MyGroup = GROUP_BIOLOGY;
	Quiz[92].MyGroup = GROUP_MIXED;
	Quiz[93].MyGroup = GROUP_MIXED;
	Quiz[94].MyGroup = GROUP_MIXED;
	Quiz[95].MyGroup = GROUP_MIXED;
	Quiz[96].MyGroup = GROUP_MIXED;
	Quiz[97].MyGroup = GROUP_MIXED;
	Quiz[98].MyGroup = GROUP_BIOLOGY;
	Quiz[99].MyGroup = GROUP_MIXED;

#ifdef ENGLISH
	Quiz[0].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
	Quiz[1].Text = "Do you feel strongly attracted to, or appalled by, certain tastes, smells, sounds, colours, shapes, textures or materials?";
	Quiz[2].Text = "Do you have a very acute sense of smell and/or taste?";
	Quiz[3].Text = "Are you sensitive to heat, cold, wind and/or changes in air-pressure, humidity etc?";
	Quiz[4].Text = "Do you feel uncomfortable in fluorescent light?";
	Quiz[5].Text = "Do you feel tortured by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' material?";
	Quiz[6].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
	Quiz[7].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
	Quiz[8].Text = "Do you often use peripheral vision?";
	Quiz[9].Text = "Are you sensitive to electromagnetic fields?";
	Quiz[10].Text= "Do you have fibromyalgia?";
	Quiz[11].Text = "Do you have difficulties with fine motor skills and/or hand-eye co-ordination?";
	Quiz[12].Text = "Do you have poor gross motor skills (= clumsiness)?";
	Quiz[13].Text = "Do you have difficulties judging distances, height, depth or speed?";
	Quiz[14].Text = "Do you have poor concept of time?";
	Quiz[15].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
	Quiz[16].Text = "Do you confuse left and right?";
	Quiz[17].Text = "Are you fairly insensitive to, or have unusual reactions to, physical pain?";
	Quiz[18].Text = "Do you have unusual sleeping patterns?";
	Quiz[19].Text = "Do you have unusual eating patterns?";
	Quiz[20].Text = "Do you prefer cold weather over warm weather?";
	Quiz[21].Text = "Do you have psoriasis?";
	Quiz[22].Text = "Do you have dandruff?";
	Quiz[23].Text = "Do you squint now or have done in the past?";
	Quiz[24].Text = "Are you slim and unable to gain in weight?";
	Quiz[25].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
	Quiz[26].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
	Quiz[27].Text = "Do you have problems recognizing faces out of their usual context (e.g. your doctor at the supermarket without his white robe)?";
	Quiz[28].Text = "Are you usually unaware of social rules & boundaries unless they are specifically spelled out?";
	Quiz[29].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
	Quiz[30].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
	Quiz[31].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly instructed?";
	Quiz[32].Text = "Do you have difficulties understanding figures of speech, parodies, allegories, irony etc?";
	Quiz[33].Text = "Do you find it hard to tell the age of people?";
	Quiz[34].Text = "Do people sometimes think you are smiling at the wrong occasion?";
	Quiz[35].Text = "Do you get confused by verbal instructions - especially several at the same time?";
	Quiz[36].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
	Quiz[37].Text = "Do others often misunderstand you?";
	Quiz[38].Text = "Do you mostly talk when you have something concrete to say?";
	Quiz[39].Text = "Do you have difficulty summarizing and reporting conversations or describing events?";
	Quiz[40].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
	Quiz[41].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
	Quiz[42].Text = "Do you find it difficult to read written material unless it is very interesting or very easy?";
	Quiz[43].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
	Quiz[44].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
	Quiz[45].Text = "Do you find it easier to understand & communicate with computers, animals and/or Aspies than with 'ordinary' people?";
	Quiz[46].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
	Quiz[47].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
	Quiz[48].Text = "Do you have more difficulties than others of the same age when it comes to making friendships and getting into relationships?";
	Quiz[49].Text = "Do you find the usual courting behavior natural?";
	Quiz[50].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
	Quiz[51].Text = "Do you mostly prefer to play/work/do things on your own - in your own way and at your own pace?";
	Quiz[52].Text = "Are you fairly self-absorbed, more interested in yourself than in others and/or an objective observer of yourself?";
	Quiz[53].Text = "Do you tend to feel get nervous, shy, confused and/or like you don't fit in, in various social situations?";
	Quiz[54].Text = "Is your style and image very important to you?";
	Quiz[55].Text = "Do you have an interest for the current fashions?";
	Quiz[56].Text = "Do you prefer romance/drama films to science fiction/documentary films?";
	Quiz[57].Text = "Do you enjoy gossip?";
	Quiz[58].Text = "Do you enjoy the status of a new car/new stereo/new TV?";
	Quiz[59].Text = "Is other people's image of you important to you?";
	Quiz[60].Text = "Would you offer somebody a favor even if you think it would be unlikely he/she would return it?";
	Quiz[61].Text = "Is making a career important to you?";
	Quiz[62].Text = "Is creating a social identity important for you?";
	Quiz[63].Text = "Do you feel like you were born with the wrong gender?";
	Quiz[64].Text = "Are you homosexual?";
	Quiz[65].Text = "Are you bisexual?";
	Quiz[66].Text = "Do you have an interest in or have practised BD/SM?";
	Quiz[67].Text = "Do you like to be naked in private?";
	Quiz[68].Text = "Do you think leather is sexy?";
	Quiz[69].Text = "Do you have unconventional, often unique ways of solving problems?";
	Quiz[70].Text = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
	Quiz[71].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
	Quiz[72].Text = "Do you focus on one interest at a time and become an expert on that subject?";
	Quiz[73].Text = "Is you imagination unusual, with unique ideas that others don't have?";
	Quiz[74].Text = "Are you fascinated by dates and/or numbers?";
	Quiz[75].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
	Quiz[76].Text = "Do you consider yourself as a very logical person that get surprised or impatient when others aren't?";
	Quiz[77].Text = "Are you very gifted in one or more areas?";
	Quiz[78].Text = "Do you like to work out how things work?";
	Quiz[79].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed, or if an activity that is important to you gets interrupted?";
	Quiz[80].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
	Quiz[81].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
	Quiz[82].Text = "Do you have very strong attachments to certain objects, e.g. a favourite cup or a favourite towel and really need to have that precise one?";
	Quiz[83].Text = "Do you have certain simple & logical routines which you need to follow?";
	Quiz[84].Text = "Do you have obsessions or compulsions (repeated irresistible impulses to do certain things)?";
	Quiz[85].Text = "Do you sometimes get very emotional about simple objects?";
	Quiz[86].Text = "Do you like to collect items to make a set?";
	Quiz[87].Text = "Do you have difficulty accepting criticism, correction, and direction?";
	Quiz[88].Text = "Do you have crooked teeth or underbite?";
	Quiz[89].Text = "Are you flat-footed?";
	Quiz[90].Text = "Did you have freckles as a child?";
	Quiz[91].Text = "Do you have a larger head (or hat size) than normal?";
	Quiz[92].Text = "Do you have brown eyes?";
	Quiz[93].Text = "Do you have loose joints that have dislocated?";
	Quiz[94].Text = "Do you have natural black hair color?";
	Quiz[95].Text = "Are you shorter than what is normal for your gender?";
	Quiz[96].Text = "Is your forefinger longer than your ringfinger?";
	Quiz[97].Text = "Do you have a prominent bulge in the rear of your skull (occipital bun)?";
	Quiz[98].Text = "Do you have a crooked spine (scoliosis)?";
	Quiz[99].Text = "Do you like animals a lot?";

#endif

#ifdef SWEDISH
	Quiz[0].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
	Quiz[1].Text = "Brukar du känna stark lust eller häftigt obehag av vissa färger, former, dofter, smaker, material eller konsistenser?";
	Quiz[2].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
	Quiz[3].Text = "Är du känslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
	Quiz[4].Text = "Är du känslig för vissa typer av ljus, t.ex lysrörsljus?";
	Quiz[5].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda av \"fel\" material?";
	Quiz[6].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
	Quiz[7].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
	Quiz[8].Text = "Tittar du ofta i ögonvrån?";
	Quiz[9].Text = "Är du känslig för elektromagnetiska fält?";
	Quiz[10].Text= "Har du fibromyalgi?";
	Quiz[11].Text = "Har du problem med finmotorik och/eller öga-hand-koordination?";
	Quiz[12].Text = "Har du problem med grovmotorik (=klumpighet)?";
	Quiz[13].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och hastighet?";
	Quiz[14].Text = "Har du dålig tidsuppfattning?";
	Quiz[15].Text = "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
	Quiz[16].Text = "Brukar du blanda ihop höger och vänster?";
	Quiz[17].Text = "Är du relativt okänslig för smärta?";
	Quiz[18].Text = "Har du ovanliga sovmönster/sovvanor?";
	Quiz[19].Text = "Har du ovanliga ätvanor?";
	Quiz[20].Text = "Trivs du bättre i kallt väder än i varmt?";
	Quiz[21].Text = "Har du psoriasis?";
	Quiz[22].Text = "Har du mjäll?";
	Quiz[23].Text = "Skelar du eller har gjort det?";
	Quiz[24].Text = "Är du smal och har svårt att öka i vikt?";
	Quiz[25].Text = "Brukar du ha svårt att tolka kroppsspråk och ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
	Quiz[26].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
	Quiz[27].Text = "Har du svårt att känna igen ansikten i oväntade sammanhang (t ex din läkare i snabbköpet utan sin vita rock?";
	Quiz[28].Text = "Är du oftast omedveten om outtalade sociala regler?";
	Quiz[29].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
	Quiz[30].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
	Quiz[31].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går?";
	Quiz[32].Text = "Har du svårt att förstå talesätt, allegorier, parodier, ironi och liknande?";
	Quiz[33].Text = "Har du svårt för att bedöma andra människors ålder?";
	Quiz[34].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
	Quiz[35].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
	Quiz[36].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
	Quiz[37].Text = "Blir du ofta missförstådd av andra?";
	Quiz[38].Text = "Brukar du tala endast när du upplever att du har nåt konkret att säga?";
	Quiz[39].Text = "Har du problem med att redogöra för konversationer eller händelser och att sammanfatta?";
	Quiz[40].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?";
	Quiz[41].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
	Quiz[42].Text = "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
	Quiz[43].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
	Quiz[44].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
	Quiz[45].Text = "Har du lättare att förstå dig på datorer, djur och/eller Aspergare än att umgås och kommunicera framgångsrikt med \"vanliga\" människor?";
	Quiz[46].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
	Quiz[47].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
	Quiz[48].Text = "Har du svårare än dina jämnåriga att få vänner och/eller partners?";
	Quiz[49].Text = "Tycker du det normala sättet att uppvakta varandra är naturligt?";
	Quiz[50].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
	Quiz[51].Text = "Brukar du föredra att leka/arbeta/göra saker själv - på ditt eget sätt och i din egen takt?";
	Quiz[52].Text = "Är du rätt självupptagen, mer intresserad av dig själv än av andra och/eller en objektiv självobservatör?";
	Quiz[53].Text = "Brukar du bli nervös, blyg, förvirrad och/eller känna dig annorlunda och utanför i olika sociala situationer?";
	Quiz[54].Text = "Är din stil och image mycket viktig för dig?";
	Quiz[55].Text = "Är du intressad av nuvarande mode?";
	Quiz[56].Text = "Föredrar du filmer om romantik / drama före filmer om vetenskap/dokumentärer?";
	Quiz[57].Text = "Tycker du om skvaller?";
	Quiz[58].Text = "Njuter du av den status som en ny bil/stereo/TV ger?";
	Quiz[59].Text = "Är andra människors syn på dig viktigt för dig?";
	Quiz[60].Text = "Skulle du göra någon en tjänst även om det vore osannolikt att han/hon skulle återgälda den?";
	Quiz[61].Text = "Är det viktigt för dig att göra karriär?";
	Quiz[62].Text = "Är det viktigt för dig att skapa en social identitet?";
	Quiz[63].Text = "Känns det som du föddes med fel kön?";
	Quiz[64].Text = "Är du homosexuell?";
	Quiz[65].Text = "Är du bisexuell?";
	Quiz[66].Text = "Har du intresse för eller har du medverkat i BD/SM?";
	Quiz[67].Text = "Tycker du om att vara naken i din privata sfär?";
	Quiz[68].Text = "Tycker du läder är sexigt?";
	Quiz[69].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
	Quiz[70].Text = "Brukar du bli så absorberad av dina projekt att du glömmer/struntar i allting annat (äta, duscha, sova, andra människor etc.)?";
	Quiz[71].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
	Quiz[72].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
	Quiz[73].Text = "Är din fantasi ovanlig med unika idéer som andra inte har?";
	Quiz[74].Text = "Är du fascinerad av datum och/eller siffror?";
	Quiz[75].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
	Quiz[76].Text = "Anser du dig själv som en väldigt logisk person som blir förvånad när andra inte är det?";
	Quiz[77].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
	Quiz[78].Text = "Tycker du om att reda ut hur saker fungerar?";
	Quiz[79].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer, rutiner eller som avbryter dig mitt i en för dig viktig aktivitet?";
	Quiz[80].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
	Quiz[81].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
	Quiz[82].Text = "Är du exceptionellt fäst vid vissa saker, t ex en favoritkopp, en favorittröja, en favorithandduk, och verkligen MÅSTE ha just den?";
	Quiz[83].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
	Quiz[84].Text = "Har du tvångssyndrom (= tvångstankar eller oemotståndliga, upprepade, irrationella impulser att göra vissa saker)?";
	Quiz[85].Text = "Brukar du ofta fästa dig vid olika föremål?";
	Quiz[86].Text = "Tycker du om att samla på saker?";
	Quiz[87].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
	Quiz[88].Text = "Har du sneda tänder eller underbett?";
	Quiz[89].Text = "Är du plattfot?";
	Quiz[90].Text = "Hade du fräknar som barn?";
	Quiz[91].Text = "Har du större huvud (eller hattstorlek) än normalt?";
	Quiz[92].Text = "Har du bruna ögon?";
	Quiz[93].Text = "Har du lösa leder som har hoppat ur led?";
	Quiz[94].Text = "Har du naturligt svart hårfärg?";
	Quiz[95].Text = "Är du kortare än vad som är normalt för ditt kön?";
	Quiz[96].Text = "Är ditt pekfinger längre än ditt ringfinger?";
	Quiz[97].Text = "Har du en knöl i bakhuvudet (occipital bun)?";
	Quiz[98].Text = "Har du sned rygg (skolios)?";
	Quiz[99].Text = "Tycker du mycket om djur?";

#endif
}

/*##########################################################################
#
#   Name       : TQuizIII::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizIII::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("lushforum.co.uk", "lushforum.co.uk");
	AddReferer("whoa.nu", "whoa.nu");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("gentlechristianmothers.com", "gentlechristianmothers.com");
	AddReferer("georgewbush.org", "georgewbush.org");
	AddReferer("aspie-forum.htm", "groups.yahoo.com/group/aspie-forum");
	AddReferer("fam.htm", "groups.yahoo.com/group/FAMSecretSociety");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("ddrsverige.com", "ddrsverige.com");
	AddReferer("nevro.info", "nevro.info");
	AddReferer("google.com", "google.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("xmission.com/~winter", "xmission.com/~winter");
	AddReferer("rdos.net/sv", "rdos.net/sv");
	AddReferer("katter.nu", "home.katter.nu/kattforum");
}

/*##################  TQuizIII::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizIII::LoadReferers()
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
		{
			ref->Count++;
			ref->AsResult += Row.AsResult;
			ref->NtResult += Row.NtResult;

			if (Row.AsResult >= Row.NtResult)
			{
				if (Row.AsResult - Row.NtResult >= 50)
					ref->ResultHighAs++;
				else
					ref->ResultLowAs++;
			}
			else
				ref->ResultNt++;
		}

		switch (Row.Diagnos)
		{
			case DX_AS:
				ref = &DxAsRef;
				break;

			case DX_TS:
				ref = &DxTsRef;
				break;

			case DX_ADD:
				ref = &DxAddRef;
				break;

			case SELF_AS:
				ref = &SelfAsRef;
				break;

			case SELF_TS:
				ref = &SelfTsRef;
				break;

			case SELF_ADD:
				ref = &SelfAddRef;
				break;

			default:
				ref = 0;
				break;
		}

		if (ref)
		{
			ref->Count++;
			ref->AsResult += Row.AsResult;
			ref->NtResult += Row.NtResult;

			if (Row.AsResult >= Row.NtResult)
			{
				if (Row.AsResult - Row.NtResult >= 50)
					ref->ResultHighAs++;
				else
					ref->ResultLowAs++;
			}
			else
				ref->ResultNt++;
		}

		switch (Row.Diagnos)
		{
			case DX_AS:
			case SELF_AS:
				if (Row.Gender == 1)
					ref = &MaleAsRef;
				else
					ref = &FemaleAsRef;
				break;

			default:
				ref = 0;
				break;
		}

		if (ref)
		{
			ref->Count++;
			ref->AsResult += Row.AsResult;
			ref->NtResult += Row.NtResult;

			if (Row.AsResult >= Row.NtResult)
			{
				if (Row.AsResult - Row.NtResult >= 50)
					ref->ResultHighAs++;
				else
					ref->ResultLowAs++;
			}
			else
				ref->ResultNt++;
		}

	}
}

/*##########################################################################
#
#   Name       : TQuizIII::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizIII::LoadPopulations()
{
	TQuizRow Row;
	int i;
    TReferer *ref;
    int aspie;

    for (i = 0; i < MAX_QUESTIONS; i++)
        Quiz[i].NoAnswer = 0;
    
	FDataFile.SetPos(0);	
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
        for (i = 0; i < MAX_QUESTIONS; i++)
        {
            if (Row.Quiz[i] == 0)
                Quiz[i].NoAnswer++;

        }

        aspie = FALSE;

        All.Add(Row.Quiz);

		switch (Row.Diagnos)
		{
		    case DX_AS:
		    case SELF_AS:
		        aspie = TRUE;

		        if (Row.AsResult < Row.NtResult)
		            LowAs.Add(Row.Quiz);
		            
				if (Row.Gender == 1)
					AsMale.Add(Row.Quiz);
				else
					AsFemale.Add(Row.Quiz);

		        if (Row.Diagnos == DX_AS)
    		        As.Add(Row.Quiz);
				break;

			case DX_ADD:
			case SELF_ADD:
			    Add.Add(Row.Quiz);
				if (Row.Gender == 1)
					AddMale.Add(Row.Quiz);
				else
					AddFemale.Add(Row.Quiz);
				break;
		}

		if (strlen(Row.Referer) == 0)
		{
		    Mix.Add(Row.Quiz);
			if (Row.Gender == 1)
				MixMale.Add(Row.Quiz);
			else
				MixFemale.Add(Row.Quiz);
		}
		else
		{
			ref = FindReferer(Row.Referer);

			if (ref)
			{
				if (ref->NT && Row.Diagnos == NO_DX)
				{
				    Nt.Add(Row.Quiz);
					if (Row.Gender == 1)
						NtMale.Add(Row.Quiz);
					else
						NtFemale.Add(Row.Quiz);
				}

                if (!aspie)
                    aspie = ref->Aspie;
			}
		}

                    
		if (aspie)
		{
				
			Aspie.Add(Row.Quiz);
			if (Row.Gender == 1)
				AspieMale.Add(Row.Quiz);
			else
				AspieFemale.Add(Row.Quiz);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizIII::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizIII::SetupControlGroups()
{
	DefineNt("lushforum.co.uk");
	DefineNt("flashback.info");
	DefineNt("whoa.nu");
	DefineNt("gentlechristianmothers.com");
	DefineNt("katter.nu");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspie-forum.htm");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("xmission.com/~winter");
}

/*##########################################################################
#
#   Name       : TQuizIII::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizIII::SetupCross(TQuiz *QuizI, TQuiz *QuizII)
{
	DefineCross(QuizII, 0, 0);
	DefineCross(QuizII, 1, 4);
	DefineCross(QuizII, 2, 3);
	DefineCross(QuizI, 3, 59);
	DefineCross(QuizII, 4, 2);
	DefineCross(QuizI, 5, 60);
	DefineCross(QuizI, 6, 62);
	DefineCross(QuizI, 7, 54);
	DefineCross(QuizII, 8, 11);
	DefineCross(QuizII, 9, 10);
	DefineCross(QuizI, 11, 43);
	DefineCross(QuizI, 12, 44);
	DefineCross(QuizII, 13, 8);
	DefineCross(QuizI, 14, 49);
	DefineCross(QuizII, 15, 87);
	DefineCross(QuizI, 16, 46);
	DefineCross(QuizI, 17, 47);
	DefineCross(QuizI, 18, 48);
	DefineCross(QuizII, 25, 23);
	DefineCross(QuizII, 26, 22);
	DefineCross(QuizII, 27, 24);
	DefineCross(QuizII, 28, 41);
	DefineCross(QuizI, 29, 85);
	DefineCross(QuizI, 30, 94);
	DefineCross(QuizI, 31, 83);
	DefineCross(QuizI, 32, 86);
	DefineCross(QuizII, 33, 21);
	DefineCross(QuizII, 34, 28);
	DefineCross(QuizII, 35, 30);
	DefineCross(QuizII, 36, 29);
	DefineCross(QuizII, 37, 49);
	DefineCross(QuizII, 38, 32);
	DefineCross(QuizII, 39, 48);
	DefineCross(QuizI, 40, 14);
	DefineCross(QuizI, 41, 15);
	DefineCross(QuizII, 42, 33);
	DefineCross(QuizI, 43, 16);
	DefineCross(QuizII, 44, 40);
	DefineCross(QuizII, 45, 25);
	DefineCross(QuizII, 46, 7);
	DefineCross(QuizII, 47, 72);
	DefineCross(QuizII, 48, 50);
	DefineCross(QuizII, 49, 54);
	DefineCross(QuizI, 50, 77);
	DefineCross(QuizI, 51, 70);
	DefineCross(QuizI, 52, 67);
	DefineCross(QuizI, 53, 80);
	DefineCross(QuizII, 54, 77);
	DefineCross(QuizII, 56, 89);
	DefineCross(QuizII, 57, 80);
	DefineCross(QuizII, 58, 74);
	DefineCross(QuizII, 63, 57);
	DefineCross(QuizII, 66, 58);
	DefineCross(QuizII, 69, 60);
	DefineCross(QuizI, 70, 25);
	DefineCross(QuizI, 71, 21);
	DefineCross(QuizI, 72, 19);
	DefineCross(QuizII, 73, 61);
	DefineCross(QuizI, 74, 7);
	DefineCross(QuizI, 75, 4);
	DefineCross(QuizI, 77, 18);
	DefineCross(QuizII, 78, 62);
	DefineCross(QuizII, 79, 68);
	DefineCross(QuizII, 80, 67);
	DefineCross(QuizI, 81, 37);
	DefineCross(QuizI, 82, 38);
	DefineCross(QuizI, 83, 35);
	DefineCross(QuizI, 84, 50);
	DefineCross(QuizII, 85, 36);
	DefineCross(QuizII, 86, 88);
	DefineCross(QuizII, 87, 94);
	DefineCross(QuizII, 88, 99);
	DefineCross(QuizII, 89, 98);
}

/*##########################################################################
#
#   Name       : TQuizIII::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizIII::GetReferer(const char *referer, TPopulation *pop)
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
		    pop->Add(Row.Quiz);
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
            if (row->Diagnos == DX_AS)
                return TRUE;
            else
                return FALSE;
                
    }
    return FALSE;
}

/*##################  TQuizIII::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizIII::ExportExcelCase(const char *filename, int PcaType)
{
	TQuizRow Row;
    int i;
    int ival;
    char str[80];
	TFile file(filename, 0);

    file.Write("\"\", ");
    file.Write("\"\", ");

	for (i = 0; i < MAX_QUESTIONS; i++)
    {
        file.Write("\"");

//        strncpy(str, Quiz[i].Text, 35);
//        str[35] = 0;
        sprintf(str, "#%d", i + 1);
        file.Write(str);
        
        file.Write("\"");
        if (i != MAX_QUESTIONS - 1)
            file.Write(", ");
    }
    file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
	    if (IsPca(&Row, PcaType))
	    {
			sprintf(str, "\%d\", ", Row.AsResult);
	        file.Write(str);

    	    sprintf(str, "\"%d\", ", Row.Diagnos);
	        file.Write(str);
	    
    		for (i = 0; i < MAX_QUESTIONS; i++)
	    	{
		        ival = Row.Quiz[i];
		        if (ival)
					ival--;
		        
		    	if (ival > 2)
			        ival = 0;

    		    sprintf(str, "\"%d\"", ival);
                file.Write(str);
                if (i != MAX_QUESTIONS - 1)
                    file.Write(", ");
    		}
	    	file.Write("\n");
	    }
	}
}

/*##################  TQuizIII::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizIII::ImportMvsp(const char *filename, int PcaType)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2, d3;
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

			if (sscanf(rowstr, "%d %Lf %Lf %Lf", &q, &d1, &d2, &d3) == 4)
			{
				if (PcaType != PCA_TYPE_FEMALE && PcaType != PCA_TYPE_YOUNG
				   && PcaType != PCA_TYPE_AS)
					d2 = -d2;

				if (d1 > 0 && d2 > 0)
				{
					if (d1 > d2)
					{
						d1 = d1 - d2;
						d2 = 0;
					}
					else
					{
						d2 = d2 - d1;
						d1 = 0;
					}
				}

				switch (PcaType)
				{
					case PCA_TYPE_ALL:
						Quiz[q - 1].Pca[0] = d1;
						Quiz[q - 1].Pca[1] = d2;
						Quiz[q - 1].Pca[2] = d3;
						break;

					case PCA_TYPE_MALE:
						Quiz[q - 1].MalePca[0] = d1;
						Quiz[q - 1].MalePca[1] = d2;
		                Quiz[q - 1].MalePca[2] = d3;
		                break;

                    case PCA_TYPE_FEMALE:		            
        		        Quiz[q - 1].FemalePca[0] = d1;
	        	        Quiz[q - 1].FemalePca[1] = d2;
		                Quiz[q - 1].FemalePca[2] = d3;
		                break;

                    case PCA_TYPE_YOUNG:		            
        		        Quiz[q - 1].YoungPca[0] = d1;
	        	        Quiz[q - 1].YoungPca[1] = d2;
		                Quiz[q - 1].YoungPca[2] = d3;
		                break;

                    case PCA_TYPE_OLD:		            
        		        Quiz[q - 1].OldPca[0] = d1;
	        	        Quiz[q - 1].OldPca[1] = d2;
		                Quiz[q - 1].OldPca[2] = d3;
		                break;

                    case PCA_TYPE_AS:		            
        		        Quiz[q - 1].AsPca[0] = d1;
	        	        Quiz[q - 1].AsPca[1] = d2;
		                Quiz[q - 1].AsPca[2] = d3;
		                break;
		        }
		    }
		}
	}
}
