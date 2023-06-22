-module(customer).
-export([request_amount_from_bank/4]).

    request_amount_from_bank(CustomerName, CustomerRequestedAmount, CustomerMap, BankMap) ->
        receive
            {Sender, CustomerName} ->
                io:fwrite("From Customer ID: ~w,~w,~w,~w\n\n", [CustomerName, CustomerRequestedAmount, self(), Sender])
        end.