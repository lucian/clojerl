-module('clojerl.SortedSet').

-include("clojerl.hrl").

-behavior('clojerl.Counted').
-behavior('clojerl.IColl').
-behavior('clojerl.IEquiv').
-behavior('clojerl.IFn').
-behavior('clojerl.IHash').
-behavior('clojerl.IMeta').
-behavior('clojerl.ISet').
-behavior('clojerl.Seqable').
-behavior('clojerl.Stringable').

-export([?CONSTRUCTOR/1]).
-export([count/1]).
-export([ cons/2
        , empty/1
        ]).
-export([equiv/2]).
-export([apply/2]).
-export([hash/1]).
-export([ meta/1
        , with_meta/2
        ]).
-export([ disjoin/2
        , contains/2
        , get/2
        ]).
-export([ seq/1
        , to_list/1
        ]).
-export([str/1]).

-type type() :: #?TYPE{}.

-spec ?CONSTRUCTOR(list()) -> type().
?CONSTRUCTOR(Values) when is_list(Values) ->
  #?TYPE{data = ordsets:from_list(Values)}.

%%------------------------------------------------------------------------------
%% Protocols
%%------------------------------------------------------------------------------

%% clojerl.Counted

count(#?TYPE{name = ?M, data = Set}) -> ordsets:size(Set).

%% clojerl.IColl

cons(#?TYPE{name = ?M, data = Set} = S, X) ->
  case ordsets:is_element(X, Set) of
    true  -> S;
    false -> S#?TYPE{data = ordsets:add_element(X, Set)}
  end.

empty(_) -> ?CONSTRUCTOR([]).

%% clojerl.IEquiv

equiv( #?TYPE{name = ?M, data = X}
     , #?TYPE{name = ?M, data = Y}
     ) ->
  clj_core:equiv(X, Y);
equiv(_, _) ->
  false.

%% clojerl.IFn

apply(#?TYPE{name = ?M, data = Set}, [Item]) ->
  case ordsets:is_element(Item, Set) of
    true  -> Item;
    false -> undefined
  end;
apply(_, Args) ->
  CountBin = integer_to_binary(length(Args)),
  throw(<<"Wrong number of args for set, got: ", CountBin/binary>>).

%% clojerl.IHash

hash(#?TYPE{name = ?M, data = Set}) ->
  clj_murmur3:unordered(ordsets:to_list(Set)).

%% clojerl.IMeta

meta(#?TYPE{name = ?M, info = Info}) ->
  maps:get(meta, Info, undefined).

with_meta(#?TYPE{name = ?M, info = Info} = Set, Metadata) ->
  Set#?TYPE{info = Info#{meta => Metadata}}.

%% clojerl.ISet

disjoin(#?TYPE{name = ?M, data = Set} = S, Value) ->
  S#?TYPE{data = ordsets:del_element(Value, Set)}.

contains(#?TYPE{name = ?M, data = Set}, Value) ->
  ordsets:is_element(Value, Set).

get(#?TYPE{name = ?M, data = Set}, Value) ->
  case ordsets:is_element(Value, Set) of
    true  -> Value;
    false -> undefined
  end.

%% clojerl.Seqable

seq(#?TYPE{name = ?M, data = Set}) ->
  case ordsets:size(Set) of
    0 -> undefined;
    _ -> ordsets:to_list(Set)
  end.

to_list(#?TYPE{name = ?M, data = Set}) ->
  ordsets:to_list(Set).

%% clojerl.Stringable

str(#?TYPE{name = ?M, data = Set}) ->
  Items = lists:map(fun clj_core:str/1, ordsets:to_list(Set)),
  Strs  = 'clojerl.String':join(Items, <<" ">>),
  <<"#{", Strs/binary, "}">>.
