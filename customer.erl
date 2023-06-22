-module(customer).
-export([request_amount_from_bank/4]).

    request_amount_from_bank(CustomerName, CustomerRequestedAmount, CustomerMap, BankMap) ->
        receive
            {Sender, CustomerName} ->
                % RandomBank = get_random_key(BankMap),
                % io:fwrite("hwhwh"),
                random:seed(now()),
                BankKeySet = maps:keys(BankMap),
                RandomKeyIndex = random:uniform(length(BankKeySet)),   
                RandomBank = lists:nth(RandomKeyIndex,maps:keys(BankMap)),
                random:seed(now()),
                RandomAmountRequested = random:uniform(50) + 1,
                % io:fwrite("From Customer ID: ~w,~w,~w,~w\n\n", [CustomerName, CustomerRequestedAmount, self(), RandomBank])
                io:fwrite("? ~w requests a loan of ~w dollars(s) from the ~w bank\n", [CustomerName, RandomAmountRequested, RandomBank])
        end.