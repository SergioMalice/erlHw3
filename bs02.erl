%%%-------------------------------------------------------------------
%%% @author sergeyb
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. Июнь 2019 20:11
%%%-------------------------------------------------------------------
-module(bs02).
-author("sergeyb").

%% API
-export([words/1]).

% words/1 разбивает бинарник на слова. Пример:
% 1> BinText = <<"Text with four words">>.
% <<"Text with four words">>
% 2> bs02:words(BinText).
% [<<"Text">>, <<"with">>, <<"four">>, <<"words">>]
%
% Перебираем вход посимвольно. Встретили пробел - записали слово в список,
% запустили рекурсию с пустым словом от остатка. При достижении конца бинарника
% возвращаем список с добавленным последним словом. Результат переворачиваем.
%
% Возможен вывод пустых слов в случае нескольких пробелов подряд, либо пробела в конце.

words(Bin) -> words(Bin, <<>>, []).

words(<<" ", Rest/binary>>, Word, Acc) -> words(Rest, <<>>, [Word|Acc]);
words(<<C/utf8, Rest/binary>>, Word, Acc) -> words(Rest, <<Word/binary, C/utf8>>, Acc);
words(<<>>, Word, Acc) -> reverse([Word|Acc]).

reverse(List) -> reverse(List, []).

reverse([], Res) -> Res;
reverse([H|T], Res) -> reverse(T, [H|Res]).