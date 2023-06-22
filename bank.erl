-module(bank).
-export([withdraw_amount_from_bank/3]).

    withdraw_amount_from_bank(BankName, BankAmount, BankMap) ->
        receive
            {Sender, BankName} ->
                io:fwrite("From Bank ID: ~w,~w,~w,~w\n\n", [BankName, BankAmount, self(), Sender])
                % io:fwrite("MM ~w",[whereis('bmo')])
        end.