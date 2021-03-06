-module(clojerl_cli).

-export([start/0]).

-type options() :: #{ compile       => boolean()
                    , compile_path  => string()
                    , compile_opts  => clj_compiler:options()
                    , files         => [string()]
                    , main          => boolean()
                    , main_args     => [string()]
                    , version       => boolean()
                    }.

-spec start() -> no_return().
start() ->
  Args = init:get_plain_arguments(),
  Opts = parse_args(Args),
  ok   = clojerl:start(),
  ok   = run_commands(Opts),

  erlang:halt(0).

-spec default_options() -> options().
default_options() ->
  #{ compile      => false
   , compile_path => "ebin"
   , compile_opts => #{ time    => false
                      , verbose => false
                      }
   , files        => []
   , main         => false
   , main_args    => []
   , version      => false
   }.

-spec parse_args([string()]) -> options().
parse_args(Args) ->
  parse_args(Args, default_options()).

-spec parse_args([string()], options()) -> options().
parse_args([], Opts) ->
  Opts;
parse_args(["-v" | Rest], Opts) ->
  parse_args(Rest, Opts#{version => true});
parse_args(["-o", CompilePath | Rest], Opts) ->
  parse_args(Rest, Opts#{compile_path => CompilePath});
parse_args([Compile | Rest], Opts)
  when Compile =:= "-c"; Compile =:= "--compile" ->
  parse_args(Rest, Opts#{compile => true});
parse_args([TimeOpt | Rest], #{compile_opts := CompileOpts} = Opts)
  when TimeOpt =:= "-t"; TimeOpt =:= "--time" ->
  parse_args(Rest, Opts#{compile_opts := CompileOpts#{time := true}});
parse_args([VerboseOpt | Rest], #{compile_opts := CompileOpts} = Opts)
  when VerboseOpt =:= "-vv"; VerboseOpt =:= "--verbose" ->
  parse_args(Rest, Opts#{compile_opts := CompileOpts#{verbose := true}});
parse_args([File | Rest], Opts = #{files := Files, compile := true}) ->
  parse_args(Rest, Opts#{files => [File | Files]});
parse_args([Arg | Rest], Opts = #{main_args := MainArgs}) ->
  parse_args(Rest, Opts#{ main      => true
                        , main_args => [Arg | MainArgs]
                        }).

-spec run_commands(options()) -> ok.
run_commands(#{version := true}) ->
  ErlangVersion  = erlang:system_info(system_version),
  ClojerlVersion = 'clojure.core':'clojure-version'(),
  io:format("~s~nClojerl ~s~n", [ErlangVersion, ClojerlVersion]),
  erlang:halt(0);
run_commands(#{ compile      := true
              , files        := Files
              , compile_path := CompilePath
              , compile_opts := CompileOpts
              } = Opts) ->

  CompilePathBin = list_to_binary(CompilePath),
  Bindings       = #{ <<"#'clojure.core/*compile-path*">>  => CompilePathBin
                    , <<"#'clojure.core/*compile-files*">> => true
                    },
  FilesBin       = [list_to_binary(F) || F <- Files],
  try
    ok = 'clojerl.Var':push_bindings(Bindings),
    [clj_compiler:compile_file(F, CompileOpts) || F <- FilesBin]
  catch Type:Reason ->
      io:format( "[~p] ~s~n~p"
               , [Type, clj_rt:str(Reason), erlang:get_stacktrace()]
               ),
      erlang:halt(1)
  after
    ok = 'clojerl.Var':pop_bindings()
  end,
  run_commands(Opts#{compile := false});
run_commands(#{main := true, main_args := Args} = Opts) ->
  ArgsBin = [erlang:list_to_binary(Arg) || Arg <- lists:reverse(Args)],
  'clojure.main':main(ArgsBin),
  run_commands(Opts#{main := false});
run_commands(_) ->
  ok.
