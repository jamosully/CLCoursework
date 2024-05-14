%%% Definite Clause Grammer for prolexa utterances %%%

utterance(C) --> sentence(C).
utterance(C) --> question(C).
utterance(C) --> command(C).

:- op(600, xfy, '=>').
:- op(900, fy, not).


%%% lexicon, driven by predicates %%%

adjective(_,M)		--> [Adj],    {pred2gr(_P,1,a/Adj, M)}.
noun(s,M)			--> [Noun],   {pred2gr(_P,1,n/Noun,M)}.
noun(p,M)			--> [Noun_p], {pred2gr(_P,1,n/Noun,M),noun_s2p(Noun,Noun_p)}.
iverb(s,M)			--> [Verb_s], {pred2gr(_P,1,v/Verb,M),verb_p2s(Verb,Verb_s)}.
iverb(p,M)			--> [Verb],   {pred2gr(_P,1,v/Verb,M)}.

% unary predicates for adjectives, nouns and verbs
pred(human,   1,[a/human,n/human]).
pred(mortal,  1,[a/mortal,n/mortal]).
%pred(man,     1,[a/male,n/man]).
%pred(woman,   1,[a/female,n/woman]).
%pred(married, 1,[a/married]).
%pred(bachelor,1,[n/bachelor]).
%pred(mammal,  1,[n/mammal]).
pred(bird,    1,[n/bird]).
%pred(bat,     1,[n/bat]).
pred(penguin, 1,[n/penguin]).
pred(sparrow, 1,[n/sparrow]).
pred(fly,     1,[v/fly]).
pred(teacher, 1,[n/teacher]).
pred(happy,   1,[a/happy]).
pred(playful, 1,[a/playful]).
pred(energetic,1,[a/energetic]).
pred(animal,  1,[n/animal]).

pred2gr(P,1,C/W,X=>Lit):-
	pred(P,1,L),
	member(C/W,L),
	Lit=..[P,X].

noun_s2p(Noun_s,Noun_p):-
	( Noun_s=woman -> Noun_p=women
	; Noun_s=man -> Noun_p=men
	; atom_concat(Noun_s,s,Noun_p)
	).

verb_p2s(Verb_p,Verb_s):-
	( Verb_p=fly -> Verb_s=flies
	; 	atom_concat(Verb_p,s,Verb_s)
	).


%%% sentences %%%

sentence(C) --> sword,sentence1(C).

sword --> [].
sword --> [that]. 

% most of this follows Simply Logical, Chapter 7
sentence1(C) --> determiner(N,M1,M2,C),noun(N,M1),verb_phrase(N,M2).
sentence1([(L:-true)]) --> proper_noun(N,X),verb_phrase(N,X=>L).

% sentence extensions for negation
sentence1([(H:-not(B))]) --> determiner(N,M1,M2,[(H:-B)]),noun(N,M1),verb_phrase(N,not(M2)).
sentence1([(not(L):-true)]) --> proper_noun(N,X),verb_phrase(N,not(X=>L)).

% sentence extensions for default rules
sentence1(C) --> determiner(N,M1,M2,M3,C),noun(N,M1),verb_phrase(N,M2),[except],noun(N,M3).
sentence1(C) --> determiner(N,M1,M2,M3,C),noun(N,M1),verb_phrase(N,M2),[except],proper_noun(N,M3).

% sentence extensions for existential quantification
sentence1([([L1,L2]:-true)]) --> determiner(N,M1,M2,[(L1:-true),(L2:-true)]),noun(N,M1),verb_phrase(N,M2).

verb_phrase(s,M) --> [is],property(s,M).
verb_phrase(p,M) --> [are],property(p,M).

% verb phrase extensions for negation
verb_phrase(s,not(M)) --> [is,not],property(s,M).
verb_phrase(p,not(M)) --> [are,not],property(p,M).
verb_phrase(s,not(M)) --> [does,not],property(s,M)
						 ;[does,not],iverb(p,M).
verb_phrase(p,not(M)) --> [not],property(p,M).

% verb phrase extensions for default rules
% verb_phrase(s,not(M)) --> [does,not],iverb(p,M),
% verb_phrase(p,not(M)) --> [do,not],iverb(p,M),

verb_phrase(N,M) --> iverb(N,M).
verb_phrase(N,M) --> iverb(N,M),[prizes].

property(N,M) --> adjective(N,M).
property(s,M) --> [a],noun(s,M).
property(p,M) --> noun(p,M).

determiner(s,X=>B,X=>H,[(H:-B)]) --> [every].
determiner(p,X=>B,X=>H,[(H:-B)]) --> [all].
determiner(p,X=>B,X=>H,[(H:-B)]) --> [].
determiner(p,X=>B,X=>H,X=>E,[(H:-B,not(E))]) --> [most].

% existential quantification using skolem constants 
determiner(p, sk=>H1, sk=>H2, [(H1:-true),(H2 :- true)]) -->[some].
determiner(p, sk=>H1, sk=>H2, [(H2:-true),(H1:-true)]) -->[some].
% determiner(p,X=>B,X=>H,[(default(H:-B))]) --> [most].


proper_noun(s,tweety) --> [tweety].
proper_noun(s,peter) --> [peter].
proper_noun(s,donald) --> [donald].


%%% questions %%%

question(Q) --> qword,question1(Q).

qword --> [].
%qword --> [if]. 
%qword --> [whether]. 

question1(Q) --> [who],verb_phrase(s,_X=>Q).
question1(Q) --> [is],proper_noun(N,X),property(N,X=>Q).
question1(Q) --> [does],proper_noun(_,X),verb_phrase(_,X=>Q).

% question extensions for negation
question1(not(Q)) --> [is],proper_noun(N,X),[not],property(N,not(X=>Q)).
question1(not(Q)) --> [does],proper_noun(_,X),[not],verb_phrase(_,not(X=>Q)).

% question extensions with skolem constants
question1((Q1,Q2)) --> [do],[some],noun(p,sk=>Q1),verb_phrase(p,sk=>Q2).
question1((Q1,Q2)) --> [are],[some],noun(p,sk=>Q1),property(p,sk=>Q2).

%%% commands %%%

% These DCG rules have the form command(g(Goal,Answer)) --> <sentence>
% The idea is that if :-phrase(command(g(Goal,Answer)),UtteranceList). succeeds,
% it will instantiate Goal; if :-call(Goal). succeeds, it will instantiate Answer.
% See case C. in prolexa.pl
% Example: 
%	command(g(random_fact(Fact),Fact)) --> [tell,me,anything].
% means that "tell me anything" will trigger the goal random_fact(Fact), 
% which will generate a random fact as output for prolexa.

command(g(retractall(prolexa:stored_rule(_,C)),"I erased it from my memory")) --> forget,sentence(C). 
command(g(retractall(prolexa:stored_rule(_,_)),"I am a blank slate")) --> forgetall. 
command(g(all_rules(Answer),Answer)) --> kbdump. 
command(g(all_answers(PN,Answer),Answer)) --> tellmeabout,proper_noun(s,PN).
command(g(explain_question(Q,_,Answer),Answer)) --> [explain,why],sentence1([(Q:-true)]).
% explain Q for existential quantification
command(g(explain_question([Q1,Q2],_,Answer),Answer)) --> [explain],[why],sentence1([(Q1:-true),(Q2:-true)]).
command(g(random_fact(Fact),Fact)) --> getanewfact.
%command(g(pf(A),A)) --> peterflach. 
%command(g(iai(A),A)) --> what. 
command(g(rr(A),A)) --> thanks.

% The special form
%	command(g(true,<response>)) --> <sentence>. 
% maps specific input sentences to specific responses.

command(g(true,"I can do a little bit of logical reasoning. You can talk with me about humans and birds.")) --> [what,can,you,do,for,me,minerva]. 
%command(g(true,"Your middle name is Adriaan")) --> [what,is,my,middle,name]. 
%command(g(true,"Today you can find out about postgraduate study at the University of Bristol. This presentation is about the Centre for Doctoral Training in Interactive Artificial Intelligence")) --> today. 
%command(g(true,"The presenter is the Centre Director, Professor Peter Flach")) --> todaysspeaker. 

thanks --> [thank,you].
thanks --> [thanks].
thanks --> [great,thanks].

getanewfact --> getanewfact1.
getanewfact --> [tell,me],getanewfact1.

getanewfact1 --> [anything].
getanewfact1 --> [a,random,fact].
getanewfact1 --> [something,i,'don\'t',know].

kbdump --> [spill,the,beans].
kbdump --> [tell,me],allyouknow.

forget --> [forget].

forgetall --> [forget],allyouknow.

allyouknow --> all.
allyouknow --> all,[you,know].

all --> [all].
all --> [everything].

tellmeabout --> [tell,me,about].
tellmeabout --> [tell,me],all,[about].

rr(A):-random_member(A,["no worries","the pleasure is entirely mine","any time, peter","happy to be of help"]).

random_fact(X):-
	random_member(X,["walruses can weigh up to 1900 kilograms", "There are two species of walrus - Pacific and Atlantic", "Walruses eat molluscs", "Walruses live in herds","Walruses have two large tusks"]).


%%% various stuff for specfic events

% today --> [what,today,is,about].
% today --> [what,is,today,about].
% today --> [what,is,happening,today].
% 
% todaysspeaker --> [who,gives,'today\'s',seminar].
% todaysspeaker --> [who,gives,it].
% todaysspeaker --> [who,is,the,speaker].
% 
% peterflach --> [who,is],hepf.
% peterflach --> [tell,me,more,about],hepf.
% 
% what --> [what,is],iai.
% what --> [tell,me,more,about],iai.
% 
% hepf --> [he].
% hepf --> [peter,flach].
% 
% iai --> [that].
% iai --> [interactive,'A.I.'].
% iai --> [interactive,artificial,intelligence].
% 
% pf("According to Wikipedia, Pieter Adriaan Flach is a Dutch computer scientist and a Professor of Artificial Intelligence in the Department of Computer Science at the University of Bristol.").
% 
% iai("The Centre for Doctoral Training in Interactive Artificial Intelligence will train the next generation of innovators in human-in-the-loop AI systems, enabling them to responsibly solve societally important problems. You can ask Peter for more information.").
% 
