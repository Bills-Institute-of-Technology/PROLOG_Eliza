:- module(eliza_engine,
    [ eliza_engine_reply/3,
      eliza_engine_reset/1
    ]).

:- dynamic reassembly_cursor/4.

eliza_engine_reset(ScriptModule) :-
    retractall(reassembly_cursor(ScriptModule, _, _, _)).

eliza_engine_reply(ScriptModule, Input, Response) :-
    input_tokens(Input, Tokens0),
    normalize_tokens(ScriptModule, Tokens0, Tokens),
    keyword_candidates(ScriptModule, Tokens, Candidates),
    (   try_candidates(ScriptModule, Candidates, Tokens, ResponseTokens)
    ->  true
    ;   try_none(ScriptModule, Tokens, ResponseTokens)
    ),
    response_tokens_string(ResponseTokens, Response).

input_tokens(Input, Tokens) :-
    (   is_list(Input)
    ->  maplist(downcase_atom, Input, Tokens)
    ;   atom(Input)
    ->  atom_string(Input, String),
        string_tokens(String, Tokens)
    ;   string(Input)
    ->  string_tokens(Input, Tokens)
    ;   term_string(Input, String),
        string_tokens(String, Tokens)
    ).

string_tokens(String, Tokens) :-
    string_lower(String, Lower),
    string_codes(Lower, Codes),
    maplist(clean_code, Codes, CleanCodes),
    string_codes(Clean, CleanCodes),
    split_string(Clean, " ", " ", Parts),
    maplist(atom_string, Tokens, Parts).

clean_code(Code, Code) :-
    code_type(Code, alnum), !.
clean_code(0'', 0'') :- !.
clean_code(_, 0' ).

normalize_tokens(_, [], []).
normalize_tokens(ScriptModule, [Token|Rest], [Norm|NormRest]) :-
    (   token_norm(ScriptModule, Token, Norm)
    ->  true
    ;   Norm = Token
    ),
    normalize_tokens(ScriptModule, Rest, NormRest).

token_norm(ScriptModule, Token, Norm) :-
    call(ScriptModule:normalize(Token, Norm)).

keyword_candidates(ScriptModule, Tokens, Sorted) :-
    findall(candidate(Key, Rank, Pos),
        ( nth1(Pos, Tokens, Token),
          call(ScriptModule:keyword(Token, Rank)),
          Key = Token
        ),
        Raw),
    sort_candidates(Raw, Sorted).

sort_candidates(Candidates, Sorted) :-
    map_list_to_pairs(candidate_sort_key, Candidates, Pairs),
    keysort(Pairs, SortedPairs),
    pairs_values(SortedPairs, Sorted).

candidate_sort_key(candidate(_, Rank, Pos), Key) :-
    NegRank is -Rank,
    Key = NegRank-Pos.

try_candidates(_, [], _, _) :-
    fail.
try_candidates(ScriptModule, [candidate(Key, _, _)|Rest], Tokens, ResponseTokens) :-
    (   try_keyword(ScriptModule, Key, Tokens, ResponseTokens)
    ->  true
    ;   try_candidates(ScriptModule, Rest, Tokens, ResponseTokens)
    ).

try_keyword(ScriptModule, Key, Tokens, ResponseTokens) :-
    call(ScriptModule:decomp(Key, RuleId, Pattern, Responses)),
    match_pattern(Pattern, Tokens, Captures),
    select_reassembly(ScriptModule, Key, RuleId, Responses, Action),
    run_action(ScriptModule, Key, Tokens, Captures, Action, ResponseTokens),
    !.

try_none(ScriptModule, Tokens, ResponseTokens) :-
    call(ScriptModule:decomp(none, RuleId, Pattern, Responses)),
    match_pattern(Pattern, Tokens, Captures),
    select_reassembly(ScriptModule, none, RuleId, Responses, Action),
    run_action(ScriptModule, none, Tokens, Captures, Action, ResponseTokens).

run_action(ScriptModule, _, _, Captures, text(Template), ResponseTokens) :-
    instantiate_template(Template, Captures, ScriptModule, ResponseTokens).
run_action(ScriptModule, _, Tokens, _, goto(OtherKey), ResponseTokens) :-
    try_keyword(ScriptModule, OtherKey, Tokens, ResponseTokens).
run_action(_, _, _, _, newkey, _) :-
    fail.

match_pattern(Pattern, Tokens, Captures) :-
    match_pattern_(Pattern, Tokens, [], RevCaptures),
    reverse(RevCaptures, Captures).

match_pattern_([], [], Captures, Captures).
match_pattern_(['*'|PatRest], Tokens, Captures0, Captures) :-
    append(Capture, Remain, Tokens),
    match_pattern_(PatRest, Remain, [Capture|Captures0], Captures).
match_pattern_([exact(N)|PatRest], Tokens, Captures0, Captures) :-
    length(Capture, N),
    append(Capture, Remain, Tokens),
    match_pattern_(PatRest, Remain, [Capture|Captures0], Captures).
match_pattern_([Word|PatRest], [Word|TokRest], Captures0, Captures) :-
    atom(Word),
    match_pattern_(PatRest, TokRest, Captures0, Captures).

select_reassembly(ScriptModule, Key, RuleId, Responses, Action) :-
    length(Responses, Len),
    Len > 0,
    (   retract(reassembly_cursor(ScriptModule, Key, RuleId, Index0))
    ->  true
    ;   Index0 = 1
    ),
    nth1(Index0, Responses, Action),
    (   Index0 >= Len
    ->  Index = 1
    ;   Index is Index0 + 1
    ),
    asserta(reassembly_cursor(ScriptModule, Key, RuleId, Index)).

instantiate_template([], _, _, []).
instantiate_template([slot(N)|Rest], Captures, ScriptModule, Output) :-
    nth1(N, Captures, Capture),
    reflect_tokens(ScriptModule, Capture, Reflected),
    instantiate_template(Rest, Captures, ScriptModule, Tail),
    append(Reflected, Tail, Output).
instantiate_template([Token|Rest], Captures, ScriptModule, [Token|Tail]) :-
    Token \= slot(_),
    instantiate_template(Rest, Captures, ScriptModule, Tail).

reflect_tokens(_, [], []).
reflect_tokens(ScriptModule, [T|Ts], [R|Rs]) :-
    (   call(ScriptModule:reflect(T, R))
    ->  true
    ;   R = T
    ),
    reflect_tokens(ScriptModule, Ts, Rs).

response_tokens_string(Tokens, Response) :-
    maplist(atom_string, Tokens, Strings),
    atomic_list_concat(Strings, ' ', JoinedAtom),
    atom_string(JoinedAtom, Joined),
    string_upper(Joined, Response).
