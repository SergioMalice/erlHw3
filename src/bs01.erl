%%%-------------------------------------------------------------------
%%% @author sergeyb
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. Июнь 2019 20:11
%%%-------------------------------------------------------------------
-module(bs01).
-author("sergeyb").

%% API
-export([first_word/1]).
-define(TEST, 1).

% first_word/1 находит в бинарнике первое слово и возвращает его.
% 1> BinText = <<"Some text">>.
% <<"Some Text">>
% 2> bs01:first_word(BinText).
% <<”Some”>>
%
% Рекурсивно разбиваем вход на составляющие. Нашли пробел - порог рекурсии
% Любой другой символ, входящий в первое слово перед пробелом - рекурсия от остатка,
% записываем найденный символ в аккумулятор. Дошли до конца бинарника -
% значит, слово было одно, возвращаем его.

first_word(Bin) -> first_word(Bin, <<>>).

first_word(<<" ", _/binary>>, Acc) -> Acc;
first_word(<<C/utf8, Rest/binary>>, Acc) -> first_word(Rest, <<Acc/binary, C/utf8>>);
first_word(<<>>, Acc) -> Acc.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
bs01_test_() -> [
  ?_assert(first_word(<<"Some text">>) =:= <<"Some">>),
  ?_assert(first_word(<<"First word">>) =:= <<"First">>),
  ?_assert(first_word(<<"Need to test">>) =:= <<"Need">>)
].

-endif.