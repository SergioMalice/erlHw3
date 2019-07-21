-module(bs04).
-author("sergeyb").

%% API
-export([decode/2]).

% Комментарии объяснят логику кода.
% Общие тесты на весь раздел домашнего задания:
% make tests в консоли

decode(<<"{", Rest/binary>>, Method) ->
  prop(clear_input(Rest, no, <<>>), key, 1, <<>>, [], case Method of proplist -> []; map -> #{} end).
% пропускаем начало входа, чтобы не было совпадения с { началом обработки "вложенного json"

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
    value ->
      prop(NewRest, value, InnerCnt, <<>>, List, case is_map(Res) of false -> [{Bin, Value}|Res]; _ -> maps:put(Bin, Value, Res) end);
    inner -> prop(NewRest, inner, InnerCnt, Bin, [Value|List], Res)
  end; %записываем кортеж в результат
prop(<<"{", Rest/binary>>, Flag, Cnt, Bin, List, Res) -> % { - начинаем парсинг "вложенного json"
  {Inner, Count} = read_inner(Rest, <<>>, 0, 0),
  InnerRes = prop(Inner, key, Cnt+1, Bin, [], case is_map(Res) of false -> []; _ -> #{} end),
  case (Cnt == 1) of
    true ->
      case Flag of
        inner -> prop(skip(Rest, Count+1), value, Cnt, Bin, [InnerRes|List], Res);
        _ ->
          case Bin == <<>> of
            false -> prop(skip(Rest, Count+1), value, Cnt, Bin, [InnerRes|List], Res);
            _ -> prop(skip(Rest, Count+1), value, Cnt, Bin, List, case is_map(Res) of false -> [InnerRes|Res]; _ -> maps:merge(Res, InnerRes) end)
          end
      end;
    _ -> case is_map(Res) of false -> {Bin, InnerRes}; _ -> #{Bin => InnerRes} end
  end;

prop(<<"}", _/binary>>, _Flag, _InnerCnt, _Bin, _List, Res) -> case is_map(Res) of false -> lists:reverse(Res); _ -> Res end; % } - заканчиваем парсинг "вложенного json"
prop(<<"[", Rest/binary>>, _Flag, InnerCnt, Bin, _List, Res) -> % [ - начинаем запись вложенного списка
  prop(Rest, inner, InnerCnt, Bin, [], Res); % начали запись значения в кортеж со значением - списком
prop(<<"]", Rest/binary>>, _Flag, InnerCnt, Bin, List, Res) -> % [ - заканчиваем запись вложенного списка
  prop(Rest, value, InnerCnt, <<>>, <<>>, case is_map(Res) of false -> [{Bin, lists:reverse(List)}|Res]; _ -> maps:put(Bin, lists:reverse(List), Res) end);
prop(<<C/utf8, Rest/binary>>, value, InnerCnt, Bin, List, Res) -> % символ с флагом значения - true, false или число
  Value = read_key(<<C/utf8, Rest/binary>>, <<>>, atom),
  ValueSize = byte_size(Value)-1,
  <<_:ValueSize/binary, NewRest/binary>> = Rest,
  prop(NewRest, value, InnerCnt, <<>>, List, case is_map(Res) of false -> [{Bin, parse_value(Value)}|Res]; _ -> maps:put(Bin, parse_value(Value), Res) end); %записываем кортеж в результат
prop(<<>>, _, _, _, _, Res) -> case is_map(Res) of false -> lists:reverse(Res); _ -> Res end.

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