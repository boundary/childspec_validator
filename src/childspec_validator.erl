-module(childspec_validator).

-export([validate/1]).

validate({Id, {M, F, A}, Restart, Shutdown, Type, Modules}) when is_atom(Id) ->
    MFARes = validate_and_error(check_mfa(M, F, A),
                                "Childspec validation error [~p]:"
                                " MFA check failed, the arity or"
                                " function name is incorrect.~n",
                                [Id]),

    RestartRes = validate_and_error(check_restart(Restart),
                                    "Childspec validation error [~p]:"
                                    " Restart is not permanent, temporary"
                                    " or transient.~n",
                                    [Id]),

    ShutdownRes = validate_and_error(check_shutdown(Shutdown),
                                     "Childspec validation error [~p]:"
                                     " Shutdown is not brutal_kill,"
                                     " infinity or an integer.~n",
                                     [Id]),

    TypeRes = validate_and_error(check_type(M, Type),
                                 "Childspec validation error [~p]:"
                                 " Module type mismatch, if module is"
                                 " a supervisor it should be the atom"
                                 " 'supervisor', if not it should be"
                                 " the atom 'worker'.~n",
                                 [Id]),

    ModsRes = validate_and_error(check_modules(M, Modules),
                                 "Childspec validation error [~p]:"
                                 " Modules mismatch, if gen_event it"
                                 " should be the atom 'dynamic', else"
                                 " should be a list including the"
                                 " callback module as its only"
                                 " element.~n",
                                 [Id]),

    Results = [MFARes, RestartRes, ShutdownRes, TypeRes, ModsRes],

    case lists:member(false, Results) of
        true ->
            false;
        _ ->
            true
    end;
validate(_) ->
    error_logger:error_msg("Childspec validation error:"
                           " Childspec ID is not an atom.~n", []),
    false.

%%
%% Internal functions
%%

%% Make sure the result of the check is good, if so return 'true'.
%% If not error out with a message and return 'false'.

validate_and_error(ok, _, _) ->
    true;
validate_and_error(error, Msg, Args) ->
    error_logger:error_msg(Msg, Args),
    false.

%% Check to make sure the childspec's module has the function
%% specified and the arity is right.

check_mfa(M, F, A) ->
    Exports = M:module_info(exports),
    Arity = length(A),

    case proplists:is_defined(F, Exports) of
        true ->
            case proplists:get_value(F, Exports) of
                Arity ->
                    ok;
                _ ->
                    error
            end;
        _ ->
            error
    end.

%% Make sure the restart spec is a valid option.

check_restart(permanent) ->
    ok;
check_restart(temporary) ->
    ok;
check_restart(transient) ->
    ok;
check_restart(_) ->
    error.

%% Make sure the shutdown spec is a valid option.

check_shutdown(brutal_kill) ->
    ok;
check_shutdown(infinity) ->
    ok;
check_shutdown(Timeout) when is_integer(Timeout) ->
    ok;
check_shutdown(_) ->
    error.

%% If the module is a supervisor it should be specified as one in the
%% childspec. If it is not a supervisor it should be classified as a
%% worker in the childspec.

check_type(M, Type) ->
    case worker_or_supervisor(M) of
        Type ->
            ok;
        _ ->
            error
    end.

%% If the module is a gen_event then the modules spec should be
%% 'dynamic', otherwise it should be a single element list where the
%% element is an atom of the callback module name.

check_modules(M, Modules) ->
    case check_dynamic(is_gen_event(M), Modules) of
        ok ->
            ok;
        _ ->
            error
    end.

%% Check to see if a module should be defined as a worker or a
%% supervisor in the childspec.

worker_or_supervisor(M) ->
    Attr = M:module_info(attributes),

    case proplists:is_defined(behaviour, Attr) of
        true ->
            List = proplists:get_value(behaviour, Attr),
            case lists:member(supervisor, List) of
                true ->
                    supervisor;
                _ ->
                    worker
            end;
        _ ->
            worker
    end.

%% Is the module a gen_event?

is_gen_event(M) ->
    Attr = M:module_info(attributes),

    case proplists:is_defined(behaviour, Attr) of
        true ->
            List = proplists:get_value(behaviour, Attr),
            lists:member(gen_event, List);
        _ ->
            false
    end.

%% Check for the right combination of gen_event and dynamic or
%% non-gen_event and a callback module list with single atom element.

check_dynamic(true, dynamic) ->
    ok;
check_dynamic(false, [Element]) when is_atom(Element) ->
    ok;
check_dynamic(_, _) ->
    error.
