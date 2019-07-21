%%%-------------------------------------------------------------------
%%% @author sergeyb
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. Июль 2019 18:37
%%%-------------------------------------------------------------------
-module('EUnit').
-author("sergeyb").

-include_lib("eunit/include/eunit.hrl").

bs01_test_() -> [
  ?_assert(bs01:first_word(<<"Some text">>) =:= <<"Some">>),
  ?_assert(bs01:first_word(<<"First word">>) =:= <<"First">>),
  ?_assert(bs01:first_word(<<"Need to test">>) =:= <<"Need">>)
].

bs02_test_() -> [
  ?_assert(bs02:words(<<"Text with four words">>) =:= [<<"Text">>, <<"with">>, <<"four">>, <<"words">>]),
  ?_assert(bs02:words(<<"Next test">>) =:= [<<"Next">>, <<"test">>]),
  ?_assert(bs02:words(<<"Need to test">>) =:= [<<"Need">>, <<"to">>, <<"test">>])
].

bs03_test() -> ?assert(bs03:split(<<"Col1-:-Col2-:-Col3-:-Col4-:-Col5">>, "-:-") =:= [<<"Col1">>, <<"Col2">>, <<"Col3">>, <<"Col4">>, <<"Col5">>]).

bs04_test_() -> [
  ?_assert(bs04:decode(<<"{'squadName': 'Super hero squad','homeTown': 'Metro City','formed': 2016,'secretBase': 'Super tower','active': true,'members': [{'name': 'Molecule Man','age': 29,'secretIdentity': 'Dan Jukes','powers': ['Radiation resistance','Turning tiny','Radiation blast']},{'name': 'Madame Uppercut','age': 39,'secretIdentity': 'Jane Wilson','powers': ['Million tonne punch','Damage resistance','Superhuman reflexes']},{'name': 'Eternal Flame','age': 1000000,'secretIdentity': 'Unknown','powers': ['Immortality','Heat Immunity','Inferno','Teleportation','Interdimensional travel']}] } ">>, proplist) ==
    [{<<"squadName">>,<<"Super hero squad">>},
      {<<"homeTown">>,<<"Metro City">>},
      {<<"formed">>,2016},
      {<<"secretBase">>,<<"Super tower">>},
      {<<"active">>,true},
      {<<"members">>,
        [[{<<"name">>,<<"Molecule Man">>},
          {<<"age">>,29},
          {<<"secretIdentity">>,<<"Dan Jukes">>},
          {<<"powers">>,
            [<<"Radiation resistance">>,<<"Turning tiny">>,
              <<"Radiation blast">>]}],
          [{<<"name">>,<<"Madame Uppercut">>},
            {<<"age">>,39},
            {<<"secretIdentity">>,<<"Jane Wilson">>},
            {<<"powers">>,
              [<<"Million tonne punch">>,<<"Damage resistance">>,
                <<"Superhuman reflexes">>]}],
          [{<<"name">>,<<"Eternal Flame">>},
            {<<"age">>,1000000},
            {<<"secretIdentity">>,<<"Unknown">>},
            {<<"powers">>,
              [<<"Immortality">>,<<"Heat Immunity">>,<<"Inferno">>,
                <<"Teleportation">>,<<"Interdimensional travel">>]}]]}]),
  ?_assert(bs04:decode(<<"{'squadName': 'Super hero squad','homeTown': 'Metro City','formed': 2016,'secretBase': 'Super tower','active': true,'members': [{'name': 'Molecule Man','age': 29,'secretIdentity': 'Dan Jukes','powers': ['Radiation resistance','Turning tiny','Radiation blast']},{'name': 'Madame Uppercut','age': 39,'secretIdentity': 'Jane Wilson','powers': ['Million tonne punch','Damage resistance','Superhuman reflexes']},{'name': 'Eternal Flame','age': 1000000,'secretIdentity': 'Unknown','powers': ['Immortality','Heat Immunity','Inferno','Teleportation','Interdimensional travel']}] } ">>, map) ==
    #{<<"active">> => true,<<"formed">> => 2016,
      <<"homeTown">> => <<"Metro City">>,
      <<"members">> =>
      [#{<<"age">> => 29,<<"name">> => <<"Molecule Man">>,
        <<"powers">> =>
        [<<"Radiation resistance">>,<<"Turning tiny">>,
          <<"Radiation blast">>],
        <<"secretIdentity">> => <<"Dan Jukes">>},
        #{<<"age">> => 39,<<"name">> => <<"Madame Uppercut">>,
          <<"powers">> =>
          [<<"Million tonne punch">>,<<"Damage resistance">>,
            <<"Superhuman reflexes">>],
          <<"secretIdentity">> => <<"Jane Wilson">>},
        #{<<"age">> => 1000000,<<"name">> => <<"Eternal Flame">>,
          <<"powers">> =>
          [<<"Immortality">>,<<"Heat Immunity">>,<<"Inferno">>,
            <<"Teleportation">>,<<"Interdimensional travel">>],
          <<"secretIdentity">> => <<"Unknown">>}],
      <<"secretBase">> => <<"Super tower">>,
      <<"squadName">> => <<"Super hero squad">>})].

fib_test_() -> [
  ?_assert(fib:fib(0) =:= 1),
  ?_assert(fib:fib(1) =:= 1),
  ?_assert(fib:fib(2) =:= 2),
  ?_assert(fib:fib(3) =:= 3),
  ?_assert(fib:fib(4) =:= 5),
  ?_assert(fib:fib(5) =:= 8),
  ?_assertException(error, function_clause, fib:fib(-1)),
  ?_assert(fib:fib(31) =:= 2178309)].