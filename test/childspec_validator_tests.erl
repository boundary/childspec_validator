-module(childspec_validator_tests).

-exports([run_test/0]).

-include_lib("eunit/include/eunit.hrl").

run_test() ->
    positive(),
    negative().

positive() ->
    Folsom = {folsom,
              {folsom_sup, start_link, []},
              permanent,
              5000,
              supervisor,
              [folsom_sup]
             },

    true = childspec_validator:validate(Folsom),


    Web =
        {webmachine_mochiweb,
         {webmachine_mochiweb, start, [[{dispatch,[]}]]},
         permanent,
         5000,
         worker,
         [webmachine_mochiweb]
        },

    true = childspec_validator:validate(Web).


negative() ->
    ?debugFmt("errors are expected for these tests ...", []),

    Folsom = {folsom,
              {folsom_sup, start_link, [asdf]}, % arity is zero
              permanet, % spelling
              5000,
              worker, % should be a supervisor
              [folsom_sup]
             },

    false = childspec_validator:validate(Folsom),

    Web =
        {webmachine_mochiweb,
         {webmachine_mochiweb, burrito, [[{dispatch,[]}]]}, % burrito function doesnt exist
         permanent,
         a, % not an integer
         worker,
         dynamic % should not be dynamic
        },

    false = childspec_validator:validate(Web),

    NotAtomID = {123, {m, f, []}, blah, werker, []},

    false = childspec_validator:validate(NotAtomID).
