-module(clojerl_Numbers_SUITE).

-include("clj_test_utils.hrl").

-export([ all/0
        , init_per_suite/1
        , end_per_suite/1
        ]).

-export([hash/1]).
-export([str/1]).

-spec all() -> [atom()].
all() -> clj_test_utils:all(?MODULE).

-spec init_per_suite(config()) -> config().
init_per_suite(Config) -> clj_test_utils:init_per_suite(Config).

-spec end_per_suite(config()) -> config().
end_per_suite(Config) -> Config.

%%------------------------------------------------------------------------------
%% Test Cases
%%------------------------------------------------------------------------------

-spec hash(config()) -> result().
hash(_Config) ->
  ct:comment("Check the hash of an integer"),
  HashInt1 = 'clojerl.IHash':hash(42),
  HashInt2 = 'clojerl.IHash':hash(100),
  true = HashInt1 =/= HashInt2,

  ct:comment("Check the hash of a float"),
  HashFloat1 = 'clojerl.IHash':hash(3.14),
  HashFloat2 = 'clojerl.IHash':hash(3.1416),
  HashFloat3 = 'clojerl.IHash':hash(3.14159265),

  true = HashFloat1 =/= HashFloat2
    andalso HashFloat2 =/= HashFloat3
    andalso HashFloat1 =/= HashFloat3,

  ct:comment("Check that the hash of a float is different form an integer"),
  HashFloat4 = 'clojerl.IHash':hash(42.0),
  true = HashInt1 =/= HashFloat4,

  {comments, ""}.

-spec str(config()) -> result().
str(_Config) ->
  ct:comment("Check the string representation of an integer"),
  <<"42">> = clj_rt:str(42),

  ct:comment("Check the string representation of a float"),
  <<"3.14">> = clj_rt:str(3.14),
  <<"3.1416">> = clj_rt:str(3.1416),
  <<"3.14159265">> = clj_rt:str(3.14159265),

  {comments, ""}.
