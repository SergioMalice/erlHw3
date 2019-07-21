% Общие тесты на весь раздел домашнего задания:
% make tests в консоли

-module(fib).
-export([fib/1]).

fib(0) -> 1;
fib(1) -> 1;
fib(N) when N > 1 -> fib(1, 1, N).

fib(A, B, 2) -> A+B;
fib(A, B, N) -> fib(B, A+B, N-1).