:- module(eliza_shrader_1973,
    [ eliza_start/0,
      eliza_reset/0,
      eliza_reply/2,
      eliza_run/0
    ]).

:- use_module(library(readutil)).

:- dynamic last_input/1.
:- dynamic reply_cursor/2.

eliza_start :-
    writeln("HI! I'M ELIZA. WHAT'S YOUR PROBLEM?").

eliza_reset :-
    retractall(last_input(_)),
    retractall(reply_cursor(_, _)).

eliza_run :-
    eliza_reset,
    eliza_start,
    eliza_run_loop.

eliza_run_loop :-
    write('You: '),
    flush_output,
    read_line_to_string(user_input, Input),
    (   Input == end_of_file
    ->  writeln('ELIZA: Goodbye.')
    ;   is_exit_input(Input)
    ->  writeln('ELIZA: Goodbye.')
    ;   eliza_reply(Input, Response),
        format('ELIZA: ~s~n', [Response]),
        eliza_run_loop
    ).

is_exit_input(Input) :-
    string_lower(Input, Lower),
    memberchk(Lower, ["bye", "bye."]).

eliza_reply(Input, Response) :-
    normalize_input(Input, Normalized),
    (   contains_shut(Normalized)
    ->  Response = "SHUT UP..."
    ;   last_input(Normalized)
    ->  Response = "PLEASE DON'T REPEAT YOURSELF!"
    ;   keyword_match(Normalized, KeywordIndex, Keyword, Position)
    ->  conjugated_tail(Normalized, Keyword, Position, ConjugatedTail),
        next_reply_for_keyword(KeywordIndex, Template),
        compose_response(Template, ConjugatedTail, Response),
        retractall(last_input(_)),
        asserta(last_input(Normalized))
    ;   next_reply_for_keyword(36, Template),
        compose_response(Template, "", Response),
        retractall(last_input(_)),
        asserta(last_input(Normalized))
    ).

normalize_input(Input, Normalized) :-
    input_to_string(Input, InputString),
    string_upper(InputString, Upper),
    remove_apostrophes(Upper, NoApostrophes),
    string_concat(" ", NoApostrophes, WithLeading),
    string_concat(WithLeading, " ", Normalized).

input_to_string(Input, String) :-
    string(Input), !,
    String = Input.
input_to_string(Input, String) :-
    atom(Input), !,
    atom_string(Input, String).
input_to_string(Input, String) :-
    term_string(Input, String).

remove_apostrophes(In, Out) :-
    string_chars(In, Chars),
    exclude(is_apostrophe, Chars, Filtered),
    string_chars(Out, Filtered).

is_apostrophe('\'').

contains_shut(Text) :-
    sub_string(Text, _, 4, _, "SHUT").

keyword_match(Input, KeywordIndex, Keyword, Position1Based) :-
    keyword_data(KeywordIndex, Keyword, _, _),
    string_concat(" ", Keyword, Tmp),
    string_concat(Tmp, " ", Pattern),
    sub_string(Input, Before, _, _, Pattern),
    Position1Based is Before + 2,
    !.

conjugated_tail(Input, Keyword, Position1Based, Conjugated) :-
    string_length(Keyword, KeywordLen),
    Start0 is Position1Based - 1 + KeywordLen,
    sub_string(Input, Start0, _, 0, RawTail),
    string_concat(" ", RawTail, TailWithPadding),
    conjugate_pairs(TailWithPadding, Swapped),
    collapse_double_leading_space(Swapped, Conjugated).

conjugate_pairs(In, Out) :-
    conjugation_pairs(Pairs),
    foldl(apply_pair_swap, Pairs, In, Out).

apply_pair_swap(Src-Dst, In, Out) :-
    swap_scan(In, Src, Dst, 0, Out).

swap_scan(Current, Src, Dst, Pos, Out) :-
    string_length(Current, Len),
    (   Pos >= Len
    ->  Out = Current
    ;   string_length(Src, SrcLen),
        string_length(Dst, DstLen),
        (   sub_string(Current, Pos, SrcLen, _, Src)
        ->  replace_at(Current, Pos, SrcLen, Dst, Next),
            NextPos is Pos + DstLen,
            swap_scan(Next, Src, Dst, NextPos, Out)
        ;   sub_string(Current, Pos, DstLen, _, Dst)
        ->  replace_at(Current, Pos, DstLen, Src, Next),
            NextPos is Pos + SrcLen,
            swap_scan(Next, Src, Dst, NextPos, Out)
        ;   Pos1 is Pos + 1,
            swap_scan(Current, Src, Dst, Pos1, Out)
        )
    ).

replace_at(Input, Pos, OldLen, Replacement, Output) :-
    sub_string(Input, 0, Pos, _, Left),
    AfterPos is Pos + OldLen,
    sub_string(Input, AfterPos, _, 0, Right),
    string_concat(Left, Replacement, Tmp),
    string_concat(Tmp, Right, Output).

collapse_double_leading_space(Input, Output) :-
    (   sub_string(Input, 0, 2, _, "  ")
    ->  sub_string(Input, 1, _, 0, Output)
    ;   Output = Input
    ).

next_reply_for_keyword(KeywordIndex, ReplyText) :-
    keyword_data(KeywordIndex, _, Start, Span),
    End is Start + Span - 1,
    ensure_cursor(KeywordIndex, Start),
    retract(reply_cursor(KeywordIndex, Current)),
    reply_text(Current, ReplyText),
    (   Current >= End
    ->  Next = Start
    ;   Next is Current + 1
    ),
    asserta(reply_cursor(KeywordIndex, Next)).

ensure_cursor(KeywordIndex, Start) :-
    (   reply_cursor(KeywordIndex, _)
    ->  true
    ;   asserta(reply_cursor(KeywordIndex, Start))
    ).

compose_response(Template, Tail, Response) :-
    (   sub_string(Template, _, 1, 0, "*")
    ->  string_length(Template, TLen),
        PrefixLen is TLen - 1,
        sub_string(Template, 0, PrefixLen, _, Prefix),
        string_concat(Prefix, Tail, Response)
    ;   Response = Template
    ).

conjugation_pairs([
    " ARE "-" AM ",
    " WERE "-" WAS ",
    " YOU "-" I ",
    " YOUR "-" MY ",
    " IVE "-" YOUVE ",
    " IM "-" YOURE "
]).

keyword_data(1,  "CAN YOU",      1,   3).
keyword_data(2,  "CAN I",        4,   2).
keyword_data(3,  "YOU ARE",      6,   4).
keyword_data(4,  "YOURE",        6,   4).
keyword_data(5,  "I DONT",      10,   4).
keyword_data(6,  "I FEEL",      14,   3).
keyword_data(7,  "WHY DONT YOU",17,   3).
keyword_data(8,  "WHY CANT I",  20,   2).
keyword_data(9,  "ARE YOU",     22,   3).
keyword_data(10, "I CANT",      25,   3).
keyword_data(11, "I AM",        28,   4).
keyword_data(12, "IM",          28,   4).
keyword_data(13, "YOU",         32,   3).
keyword_data(14, "I WANT",      35,   5).
keyword_data(15, "WHAT",        40,   9).
keyword_data(16, "HOW",         40,   9).
keyword_data(17, "WHO",         40,   9).
keyword_data(18, "WHERE",       40,   9).
keyword_data(19, "WHEN",        40,   9).
keyword_data(20, "WHY",         40,   9).
keyword_data(21, "NAME",        49,   2).
keyword_data(22, "CAUSE",       51,   4).
keyword_data(23, "SORRY",       55,   4).
keyword_data(24, "DREAM",       59,   4).
keyword_data(25, "HELLO",       63,   1).
keyword_data(26, "HI",          63,   1).
keyword_data(27, "MAYBE",       64,   5).
keyword_data(28, "NO",          69,   5).
keyword_data(29, "YOUR",        74,   2).
keyword_data(30, "ALWAYS",      76,   4).
keyword_data(31, "THINK",       80,   3).
keyword_data(32, "ALIKE",       83,   7).
keyword_data(33, "YES",         90,   3).
keyword_data(34, "FRIEND",      93,   6).
keyword_data(35, "COMPUTER",    99,   7).
keyword_data(36, "NOKEYFOUND", 106,   6).

reply_text(1,   "DON'T YOU BELIEVE THAT I CAN*").
reply_text(2,   "PERHAPS YOU WOULD LIKE TO BE ABLE TO*").
reply_text(3,   "YOU WANT ME TO BE ABLE TO*").
reply_text(4,   "PERHAPS YOU DON'T WANT TO*").
reply_text(5,   "DO YOU WANT TO BE ABLE TO*").
reply_text(6,   "WHAT MAKES YOU THINK I AM*").
reply_text(7,   "DOES IT PLEASE YOU TO BELIEVE I AM*").
reply_text(8,   "PERHAPS YOU WOULD LIKE TO BE*").
reply_text(9,   "DO YOU SOMETIMES WISH YOU WERE*").
reply_text(10,  "DON'T YOU REALLY*").
reply_text(11,  "WHY DON'T YOU*").
reply_text(12,  "DO YOU WISH TO BE ABLE TO*").
reply_text(13,  "DOES THAT TROUBLE YOU?").
reply_text(14,  "TELL ME MORE ABOUT SUCH FEELINGS.").
reply_text(15,  "DO YOU OFTEN FEEL*").
reply_text(16,  "DO YOU ENJOY FEELING*").
reply_text(17,  "DO YOU REALLY BELIEVE I DON'T*").
reply_text(18,  "PERHAPS IN GOOD TIME I WILL*").
reply_text(19,  "DO YOU WANT ME TO*").
reply_text(20,  "DO YOU THINK YOU SHOULD BE ABLE TO*").
reply_text(21,  "WHY CAN'T YOU*").
reply_text(22,  "WHY ARE YOU INTERESTED IN WHETHER OR NOT I AM*").
reply_text(23,  "WOULD YOU PREFER I WERE NOT*").
reply_text(24,  "PERHAPS IN YOUR FANTASIES I AM*").
reply_text(25,  "HOW DO YOU KNOW YOU CAN'T*").
reply_text(26,  "HAVE YOU TRIED?").
reply_text(27,  "PERHAPS YOU CAN NOW*").
reply_text(28,  "DID YOU COME TO ME BECAUSE YOU ARE*").
reply_text(29,  "HOW LONG HAVE YOU BEEN*").
reply_text(30,  "DO YOU BELIEVE IT IS NORMAL TO BE*").
reply_text(31,  "DO YOU ENJOY BEING*").
reply_text(32,  "WE WERE DISCUSSING YOU- - NOT ME.").
reply_text(33,  "OH, I*").
reply_text(34,  "YOU'RE NOT REALLY TALKING ABOUT ME, ARE YOU?").
reply_text(35,  "WHAT WOULD IT MEAN TO YOU IF YOU GOT*").
reply_text(36,  "WHY DO YOU WANT*").
reply_text(37,  "SUPPOSE YOU SOON GOT*").
reply_text(38,  "WHAT IF YOU NEVER GOT*").
reply_text(39,  "I SOMETIMES ALSO WANT*").
reply_text(40,  "WHY DO YOU ASK?").
reply_text(41,  "DOES THAT QUESTION INTEREST YOU?").
reply_text(42,  "WHAT ANSWER WOULD PLEASE YOU THE MOST?").
reply_text(43,  "WHAT DO YOU THINK?").
reply_text(44,  "ARE SUCH QUESTIONS ON YOUR MIND OFTEN?").
reply_text(45,  "WHAT IS IT THAT YOU REALLY WANT TO KNOW?").
reply_text(46,  "HAVE YOU ASKED SUCH QUESTIONS BEFORE?").
reply_text(47,  "WHAT ELSE COMES TO MIND WHEN YOU ASK THAT?").
reply_text(48,  "WHAT DOES THAT QUESTION MEAN TO YOU?").
reply_text(49,  "NAMES DON'T INTEREST ME.").
reply_text(50,  "I DON'T CARE ABOUT NAMES- - PLEASE GO ON.").
reply_text(51,  "IS THAT THE REAL REASON?").
reply_text(52,  "DON'T ANY OTHER REASONS COME TO MIND?").
reply_text(53,  "DOES THAT REASON EXPLAIN ANYTHING ELSE?").
reply_text(54,  "WHAT OTHER REASONS MIGHT THERE BE?").
reply_text(55,  "PLEASE DON'T APOPLOGIZE!").
reply_text(56,  "APALOGIES ARE NOT NECESSARY.").
reply_text(57,  "WHAT FEELINGS DO YOU HAVE WHEN YOU APOLOGIZE.").
reply_text(58,  "DON'T BE SO DEFENSIVE!").
reply_text(59,  "WHAT DOES THAT DREAM SUGGEST TO YOU?").
reply_text(60,  "DO YOU DREAM OFTEN?").
reply_text(61,  "WHAT PERSONS APPEAR IN YOUR DREAMS?").
reply_text(62,  "ARE YOU DISTURBED BY YOUR DREAMS?").
reply_text(63,  "HOW DO YOU DO...PLEASE STATE YOUR PROBLEM.").
reply_text(64,  "YOU DON'T SEEM QUITE CERTAIN.").
reply_text(65,  "WHY THE UNCERTAIN TONE?").
reply_text(66,  "CAN'T YOU BE MORE POSITIVE?").
reply_text(67,  "YOU AREN'T SURE?").
reply_text(68,  "DON'T YOU KNOW?").
reply_text(69,  "ARE YOU SAYING NO JUST TO BE NEGATIVE?").
reply_text(70,  "YOU ARE BEING A BIT NEGATIVE.").
reply_text(71,  "WHY NOT?").
reply_text(72,  "ARE YOU SURE?").
reply_text(73,  "WHY NO?").
reply_text(74,  "WHY ARE YOU CONCERNED ABOUT MY*").
reply_text(75,  "WHAT ABOUT YOUR OWN*").
reply_text(76,  "CAN YOU THINK OF A SPECIFIC EXAMPLE?").
reply_text(77,  "WHEN?").
reply_text(78,  "WHAT ARE YOU THINKING OF?").
reply_text(79,  "REALLY, ALWAYS?").
reply_text(80,  "DO YOU REALLY THINK SO?").
reply_text(81,  "BUT YOU ARE NOT SURE YOU*").
reply_text(82,  "DO YOU DOUBT YOU*").
reply_text(83,  "IN WHAT WAY?").
reply_text(84,  "WHAT RESEMBLANCE DO YOU SEE?").
reply_text(85,  "WHAT DOES THE SIMILARITY SUGGEST TO YOU?").
reply_text(86,  "WHAT OTHER CONNECTIONS DO YOU SEE?").
reply_text(87,  "COULD THERE REALLY BE SOME CONNECTION?").
reply_text(88,  "HOW?").
reply_text(89,  "YOU SEEM QUITE POSITIVE.").
reply_text(90,  "ARE YOU SURE?").
reply_text(91,  "I SEE.").
reply_text(92,  "I UNDERSTAND.").
reply_text(93,  "WHY DO YOU BRING UP THE TOPIC OF FRIENDS?").
reply_text(94,  "DO YOUR FRIENDS WORRY YOU?").
reply_text(95,  "DO YOUR FRIENDS PICK ON YOU?").
reply_text(96,  "ARE YOU SURE YOU HAVE ANY FRIENDS?").
reply_text(97,  "DO YOU IMPOSE ON YOUR FRIENDS?").
reply_text(98,  "PERHAPS YOUR LOVE FOR FRIENDS WORRIES YOU?").
reply_text(99,  "DO COMPUTERS WORRY YOU?").
reply_text(100, "ARE YOU TALKING ABOUT ME IN PARTICULAR?").
reply_text(101, "ARE YOU FRIGHTENED BY MACHINES?").
reply_text(102, "WHY DO YOU MENTION COMPUTERS?").
reply_text(103, "WHAT DO YOU THINK MACHINES HAVE TO DO WITH YOUR PROBLEM?").
reply_text(104, "DON'T YOU THINK COMPUTERS CAN HELP PEOPLE?").
reply_text(105, "WHAT IS IT ABOUT MACHINES THAT WORRIES YOU?").
reply_text(106, "SAY, DO YOU HAVE ANY PSYCHOLOGICAL PROBLEMS?").
reply_text(107, "WHAT DOES THAT SUGGEST TO YOU?").
reply_text(108, "I SEE.").
reply_text(109, "I'M NOT SURE I UNDERSTAND YOU FULLY.").
reply_text(110, "COME COME ELUCIDATE YOUR THOUGHTS.").
reply_text(111, "CAN YOU ELABORATE ON THAT?").
reply_text(112, "THIS IS QUITE INTERESTING.").
