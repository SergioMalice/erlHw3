%%%-------------------------------------------------------------------
%%% @author sergeyb
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. Июнь 2019 20:11
%%%-------------------------------------------------------------------
-module(bs04).
-author("sergeyb").

%% API
-export([decode/2]).

% успел сделать парсер в проплисты. Тест для копирования ниже. Комментарии объяснят логику кода
% bs04:decode(<<"{'squadName': 'Super hero squad','homeTown': 'Metro City','formed': 2016,'secretBase': 'Super tower','active': true,'members': [{'name': 'Molecule Man','age': 29,'secretIdentity': 'Dan Jukes','powers': ['Radiation resistance','Turning tiny','Radiation blast']},{'name': 'Madame Uppercut','age': 39,'secretIdentity': 'Jane Wilson','powers': ['Million tonne punch','Damage resistance','Superhuman reflexes']},{'name': 'Eternal Flame','age': 1000000,'secretIdentity': 'Unknown','powers': ['Immortality','Heat Immunity','Inferno','Teleportation','Interdimensional travel']}] } ">>, proplist).

decode(<<"{", Rest/binary>>, Method) when Method == proplist -> prop(clear_input(Rest, no, <<>>), key, 1, <<>>, [], []).
% пропускаем начало входа, чтобы не было совпадения с { началом обработки "вложенного json"
%%decode(Json, Method) -> map(Json, map)

prop(<<C, Rest/binary>>, Flag, InnerCnt, Bin, List, Res) when (C == 58) or (C == 44) -> %двоеточие и , смена флага
  NewFlag = case Flag of
    key -> value;
    value -> key;
    inner -> inner
  end,
  prop(Rest, NewFlag, InnerCnt, Bin, List, Res);
prop(<<"'", Rest/binary>>, key, InnerCnt, _Bin, List, Res) -> %кавычка с флагом ключа
  Key = read_key(Rest, <<>>, string),
  KeySize = byte_size(Key)+1,
  <<_:KeySize/binary, NewRest/binary>> = Rest,
  prop(NewRest, key, InnerCnt, Key, List, Res); % - во временную строку записываем ключ
prop(<<"'", Rest/binary>>, Flag, InnerCnt, Bin, List, Res) when (Flag == value) or (Flag == inner) -> %кавычка с флагом значения - строка
  Value = read_key(Rest, <<>>, string),
  ValueSize = byte_size(Value)+1,
  <<_:ValueSize/binary, NewRest/binary>> = Rest,
  case Flag of
    value -> prop(NewRest, value, InnerCnt, <<>>, List, [{Bin, Value}|Res]);
    inner -> prop(NewRest, inner, InnerCnt, Bin, [Value|List], Res)
  end; %записываем кортеж в результат
prop(<<"{", Rest/binary>>, Flag, Cnt, Bin, List, Res) -> % { - начинаем парсинг "вложенного json"
  {Inner, Count} = read_inner(Rest, <<>>, 0, 0),
  InnerRes = prop(Inner, key, Cnt+1, Bin, [], []),
  case (Cnt == 1) of
    true ->
      case Flag of
        inner -> prop(skip(Rest, Count+1), value, Cnt, Bin, [InnerRes|List], Res);
        _ ->
          case Bin == <<>> of
            false -> prop(skip(Rest, Count+1), value, Cnt, Bin, [InnerRes|List], Res);
            _ -> prop(skip(Rest, Count+1), value, Cnt, Bin, List, [InnerRes|Res])
          end
      end;
    _ -> {Bin, InnerRes}
  end;

prop(<<"}", _/binary>>, _Flag, _InnerCnt, _Bin, _List, Res) -> reverse(Res); % } - заканчиваем парсинг "вложенного json"
prop(<<"[", Rest/binary>>, _Flag, InnerCnt, Bin, _List, Res) -> % [ - начинаем запись вложенного списка
  prop(Rest, inner, InnerCnt, Bin, [], Res); % начали запись значения в кортеж со значением - списком
prop(<<"]", Rest/binary>>, _Flag, InnerCnt, Bin, List, Res) -> % [ - заканчиваем запись вложенного списка
  prop(Rest, value, InnerCnt, <<>>, <<>>, [{Bin, reverse(List)}|Res]);
prop(<<C/utf8, Rest/binary>>, value, InnerCnt, Bin, List, Res) -> % символ с флагом значения - true, false или число
  Value = read_key(<<C/utf8, Rest/binary>>, <<>>, atom),
  ValueSize = byte_size(Value)-1,
  <<_:ValueSize/binary, NewRest/binary>> = Rest,
  prop(NewRest, value, InnerCnt, <<>>, List, [{Bin, parse_value(Value)}|Res]); %записываем кортеж в результат
prop(<<>>, _, _, _, _, Res) -> reverse(Res).

% убираем все пробелы, кроме тех, что в ключах/значениях и переводы строк на входе
clear_input(<<" ", Rest/binary>>, no, _Res) -> clear_input(Rest, no, _Res);
clear_input(<<"'", Rest/binary>>, NeedSpace, Res) ->
  clear_input(Rest, case NeedSpace of yes -> no; _ -> yes end, <<Res/binary, "'">>);
clear_input(<<" ", Rest/binary>>, yes, Res) -> clear_input(Rest, yes, <<Res/binary, " ">>);
clear_input(<<13, Rest/binary>>, _NeedSpace, _Res) -> clear_input(Rest, _NeedSpace, _Res);
clear_input(<<C/utf8, Rest/binary>>, _NeedSpace, Res) -> clear_input(Rest, _NeedSpace, <<Res/binary, C>>);
clear_input(<<>>, _NeedSpace, Res) -> Res.

read_inner(<<"}">>, Res, Cnt, _) -> {Res, Cnt};
read_inner(<<"}", _/binary>>, Res, Cnt, 0) -> {Res, Cnt};
read_inner(<<"}", Rest/binary>>, Res, Cnt, InnerCnt) -> read_inner(Rest, <<Res/binary, "}">>, Cnt+1, InnerCnt-1);
read_inner(<<"{", Rest/binary>>, Res, Cnt, InnerCnt) -> read_inner(Rest, <<Res/binary, "{">>, Cnt+1, InnerCnt+1);
read_inner(<<C/utf8, Rest/binary>>, Res, Cnt, InnerCnt) -> read_inner(Rest, <<Res/binary, C/utf8>>, Cnt+1, InnerCnt);
read_inner(<<>>, Res, Cnt, _) -> {Res, Cnt}.

skip(String, Cnt) -> <<_:Cnt/binary, Rest/binary>> = String, Rest.

read_key(<<"'", _/binary>>, Key, string) -> Key; % поиск строки. Конец - кавычка
read_key(<<",", _/binary>>, Key, atom) -> Key; % поиск true false или числа. Конец - запятая или конец json
read_key(<<"}", _/binary>>, Key, _Flag) -> Key; % поиск true false или числа. Конец - запятая или конец json
read_key(<<"}">>, Key, _Flag) -> Key; % поиск true false или числа. Конец - запятая или конец json
read_key(<<C/utf8, Rest/binary>>, Key, _Flag) -> read_key(Rest, <<Key/binary, C/utf8>>, _Flag);
read_key(<<>>, Key, atom) -> Key.

parse_value(Word) -> % преобразовываем строку в true false или число, если можно
  case binary_to_atom(Word, utf8) of
    true -> true;
    false -> false;
    _ -> try list_to_integer(binary_to_list(Word))
         catch
           _:_ -> Word
         end
  end.

reverse(List) -> reverse(List, []).

reverse([], Res) -> Res;
reverse([H|T], Res) -> reverse(T, [H|Res]).