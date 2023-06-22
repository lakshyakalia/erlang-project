-module(customer).
-export([request_amount_from_bank/5]).
% -import(money,[start/1, customer_loop/4, bank_loop/3, initialize_banks/1, initialize_customers/2]).
% -import(bank,[withdraw_amount_from_bank/3]).

    request_amount_from_bank(CustomerName, CustomerRequestedAmount, CustomerMap, BankMap, BankDict) ->
        receive
            {Sender, CustomerName} ->
                % io:fwrite("MssssM ~w\n",[whereis('bmo')]),
                
                random:seed(now()),
                % io:fwrite("MssssM ~w",[whereis('bmo')]),
                BankKeySet = maps:keys(BankMap),
                RandomKeyIndex = random:uniform(length(BankKeySet)),   
                RandomBank = lists:nth(RandomKeyIndex,maps:keys(BankMap)),
                random:seed(now()),
                RandomAmountRequested = random:uniform(50) + 1,
                % io:fwrite("From Customer ID: ~w,~w,~w,~w\n\n", [CustomerName, CustomerRequestedAmount, self(), RandomBank])
                io:fwrite("? ~w requests a loan of ~w dollars(s) from the ~w bank\n", [CustomerName, RandomAmountRequested, RandomBank]),
                
                BankPId = erlang:whereis(RandomBank),
                io:fwrite("MscccccsssM ~w",[BankDict]),
                io:fwrite("Bank: ~w,~w\n", [BankPId,RandomBank])
        end.