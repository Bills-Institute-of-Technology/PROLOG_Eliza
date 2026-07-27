%%  eliza(+Stimuli, -Response) is det.
%   @param  Stimuli is a list of atoms (words).
%   @author Richard A. O'Keefe (The Craft of Prolog)

:- module(eliza,
    [ eliza/2,
      eliza_run/0,
      eliza_reset/0,
      eliza_start/0
    ]).

:- use_module(library(readutil)).
:- use_module('src/eliza_engine').
:- use_module('scripts/eliza_doctor_script').

eliza_start :-
    writeln("HOW DO YOU DO. PLEASE TELL ME YOUR PROBLEM.").

eliza_reset :-
    eliza_engine:eliza_engine_reset(eliza_doctor_script).

eliza(Input, Response) :-
    eliza_engine:eliza_engine_reply(eliza_doctor_script, Input, Response).

eliza_run :-
    eliza_reset,
    eliza_start,
    eliza_loop.

eliza_loop :-
    write('You: '),
    flush_output,
    read_line_to_string(user_input, Input),
    (   Input == end_of_file
    ->  writeln('ELIZA: Goodbye.')
    ;   is_exit_input(Input)
    ->  writeln('ELIZA: Goodbye.')
    ;   eliza(Input, Response),
        format('ELIZA: ~s~n', [Response]),
        eliza_loop
    ).

is_exit_input(Input) :-
    string_lower(Input, Lower),
    memberchk(Lower, ["bye", "bye."]).











/** <examples>

?- eliza("I am very unhappy", Response).
?- eliza([i, feel, sad], Response).
?- eliza_run.

*/