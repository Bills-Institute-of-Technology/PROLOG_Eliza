:- module(eliza_doctor_script,
    [ keyword/2,
      decomp/4,
      normalize/2,
      reflect/2
    ]).

keyword(remember, 5).
keyword(if, 3).
keyword(dreamed, 4).
keyword(dream, 4).
keyword(hello, 1).
keyword(computer, 50).
keyword(am, 1).
keyword(are, 1).
keyword(your, 2).
keyword(my, 2).
keyword(i, 2).
keyword(you, 2).
keyword(can, 1).
keyword(what, 1).
keyword(because, 1).
keyword(why, 1).
keyword(everyone, 2).
keyword(everybody, 2).
keyword(nobody, 2).
keyword(noone, 2).
keyword(always, 1).
keyword(alike, 10).
keyword(same, 10).
keyword(yes, 1).
keyword(no, 1).
keyword(perhaps, 1).
keyword(sorry, 1).

normalize(dont, 'don''t').
normalize(cant, 'can''t').
normalize(wont, 'won''t').
normalize(dreamt, dreamed).
normalize(dreams, dream).
normalize(machines, computer).
normalize(machine, computer).
normalize(computers, computer).
normalize(everybody, everyone).
normalize(nobody, everyone).
normalize(noone, everyone).
normalize(perhaps, perhaps).

reflect(am, are).
reflect(are, am).
reflect(i, you).
reflect(me, you).
reflect(my, your).
reflect(your, my).
reflect(myself, yourself).
reflect(yourself, myself).
reflect(you, i).

% decomp(+Keyword, +RuleId, +Pattern, +Responses)
% Pattern: '*' matches any span, exact(N) matches exact N tokens.
% Responses: text([...]), goto(Key), newkey.

decomp(sorry, 1, ['*'], [
    text([please, do, not, apologize]),
    text([apologies, are, not, necessary]),
    text([what, feelings, do, you, have, when, you, apologize])
]).

decomp(remember, 1, ['*', you, remember, '*'], [
    text([do, you, often, think, of, slot(2)]),
    text([does, thinking, of, slot(2), bring, anything, else, to, mind]),
    text([what, else, do, you, remember])
]).

decomp(remember, 2, ['*', do, i, remember, '*'], [
    text([did, you, think, i, would, forget, slot(2)]),
    text([why, do, you, think, i, should, recall, slot(2), now]),
    goto(what)
]).

decomp(remember, 3, ['*'], [newkey]).

decomp(if, 1, ['*', if, '*'], [
    text([do, you, think, it, is, likely, that, slot(2)]),
    text([do, you, wish, that, slot(2)]),
    text([what, do, you, think, about, slot(2)])
]).

decomp(dreamed, 1, ['*', you, dreamed, '*'], [
    text([really, slot(2)]),
    text([have, you, ever, fantasized, slot(2), while, you, were, awake]),
    text([have, you, dreamed, slot(2), before])
]).

decomp(dreamed, 2, ['*'], [goto(dream), newkey]).

decomp(dream, 1, ['*'], [
    text([what, does, that, dream, suggest, to, you]),
    text([do, you, dream, often]),
    text([what, persons, appear, in, your, dreams])
]).

decomp(hello, 1, ['*'], [
    text([how, do, you, do, please, tell, me, your, problem])
]).

decomp(computer, 1, ['*'], [
    text([do, computers, worry, you]),
    text([why, do, you, mention, computers]),
    text([what, do, you, think, machines, have, to, do, with, your, problem])
]).

decomp(am, 1, ['*', are, you, '*'], [
    text([do, you, believe, you, are, slot(2)]),
    goto(what)
]).

decomp(am, 2, ['*'], [newkey]).

decomp(are, 1, ['*', are, i, '*'], [
    text([why, are, you, interested, in, whether, i, am, slot(2), or, not]),
    text([would, you, prefer, if, i, were, not, slot(2)]),
    goto(what)
]).

decomp(are, 2, ['*', are, '*'], [
    text([did, you, think, they, might, not, be, slot(2)]),
    text([would, you, like, it, if, they, were, not, slot(2)]),
    text([what, if, they, were, not, slot(2)])
]).

decomp(your, 1, ['*', my, '*'], [
    text([why, are, you, concerned, over, my, slot(2)]),
    text([what, about, your, own, slot(2)]),
    text([are, you, worried, about, someone, elses, slot(2)])
]).

decomp(your, 2, ['*'], [newkey]).

decomp(my, 1, ['*', your, '*', family, '*'], [
    text([tell, me, more, about, your, family]),
    text([who, else, in, your, family, slot(3)]),
    text([what, else, comes, to, mind, when, you, think, of, your, slot(3)])
]).

decomp(my, 2, ['*', your, '*'], [
    text([your, slot(2)]),
    text([why, do, you, say, your, slot(2)]),
    text([is, it, important, to, you, that, slot(2)])
]).

decomp(i, 1, ['*', you, want, '*'], [
    text([what, would, it, mean, to, you, if, you, got, slot(2)]),
    text([why, do, you, want, slot(2)]),
    text([suppose, you, got, slot(2), soon])
]).

decomp(i, 2, ['*', you, are, '*'], [
    text([did, you, come, to, me, because, you, are, slot(2)]),
    text([how, long, have, you, been, slot(2)]),
    text([do, you, believe, it, is, normal, to, be, slot(2)])
]).

decomp(i, 3, ['*', you, feel, '*'], [
    text([tell, me, more, about, such, feelings]),
    text([do, you, often, feel, slot(2)]),
    text([do, you, enjoy, feeling, slot(2)])
]).

decomp(i, 4, ['*', you, '*', i, '*'], [
    goto(you)
]).

decomp(i, 5, ['*'], [
    text([you, say, slot(1)]),
    text([can, you, elaborate, on, that]),
    text([that, is, quite, interesting])
]).

decomp(you, 1, ['*', i, remind, you, of, '*'], [
    goto(alike)
]).

decomp(you, 2, ['*', i, are, '*'], [
    text([what, makes, you, think, i, am, slot(2)]),
    text([does, it, please, you, to, believe, i, am, slot(2)]),
    text([do, you, sometimes, wish, you, were, slot(2)])
]).

decomp(you, 3, ['*', i, '*', you, '*'], [
    text([why, do, you, think, i, slot(2), you]),
    text([what, makes, you, think, i, slot(2), you]),
    text([suppose, i, did, slot(2), you, what, would, that, mean])
]).

decomp(you, 4, ['*', i, '*'], [
    text([we, were, discussing, you, not, me]),
    text([oh, i, slot(2)]),
    text([you, are, not, really, talking, about, me, are, you])
]).

decomp(you, 5, ['*'], [newkey]).

decomp(yes, 1, ['*'], [
    text([you, seem, quite, positive]),
    text([you, are, sure]),
    text([i, understand])
]).

decomp(no, 1, ['*'], [
    text([are, you, saying, no, just, to, be, negative]),
    text([you, are, being, a, bit, negative]),
    text([why, not])
]).

decomp(can, 1, ['*', can, i, '*'], [
    text([you, believe, i, can, slot(2), dont, you]),
    text([you, want, me, to, be, able, to, slot(2)]),
    text([perhaps, you, would, like, to, be, able, to, slot(2), yourself])
]).

decomp(can, 2, ['*', can, you, '*'], [
    text([whether, or, not, you, can, slot(2), depends, on, you, more, than, on, me]),
    text([do, you, want, to, be, able, to, slot(2)]),
    text([perhaps, you, do, not, want, to, slot(2)])
]).

decomp(can, 3, ['*'], [goto(what)]).

decomp(what, 1, ['*'], [
    text([why, do, you, ask]),
    text([does, that, question, interest, you]),
    text([what, answer, would, please, you, most]),
    text([what, do, you, think])
]).

decomp(because, 1, ['*'], [
    text([is, that, the, real, reason]),
    text([do, not, any, other, reasons, come, to, mind]),
    text([what, other, reasons, might, there, be])
]).

decomp(why, 1, ['*', why, do, not, i, '*'], [
    text([do, you, believe, i, do, not, slot(2)]),
    text([perhaps, i, will, slot(2), in, good, time]),
    goto(what)
]).

decomp(why, 2, ['*', why, cant, you, '*'], [
    text([do, you, think, you, should, be, able, to, slot(2)]),
    text([do, you, want, to, be, able, to, slot(2)]),
    goto(what)
]).

decomp(why, 3, ['*'], [goto(what)]).

decomp(everyone, 1, ['*', everyone, '*'], [
    text([really, slot(2)]),
    text([surely, not, slot(2)]),
    text([can, you, think, of, anyone, in, particular]),
    text([who, for, example])
]).

decomp(everyone, 2, ['*'], [newkey]).

decomp(always, 1, ['*'], [
    text([can, you, think, of, a, specific, example]),
    text([when]),
    text([really, always])
]).

decomp(alike, 1, ['*'], [
    text([in, what, way]),
    text([what, resemblance, do, you, see]),
    text([how])
]).

decomp(same, 1, ['*'], [goto(alike)]).

decomp(perhaps, 1, ['*'], [
    text([you, do, not, seem, quite, certain]),
    text([why, the, uncertain, tone]),
    text([can, you, be, more, positive])
]).

decomp(none, 1, ['*'], [
    text([i, am, not, sure, i, understand, you, fully]),
    text([please, go, on]),
    text([what, does, that, suggest, to, you]),
    text([do, you, feel, strongly, about, discussing, such, things])
]).
