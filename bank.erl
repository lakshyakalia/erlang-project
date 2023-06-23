-module(bank).
-export([withdraw_amount_from_bank/3]).

withdraw_amount_from_bank(BankName, BankAmount, BankMap) ->
    receive
        {Sender, BankName} ->
            io:fwrite("From Bank ID: ~w,~w,~w,~w\n\n", [BankName, BankAmount, self(), Sender]),
            withdraw_amount_from_bank(BankName, BankAmount, BankMap);

        {ParentSender, Sender, CustomerName, RandomAmountRequested} ->
            if
                BankAmount >= RandomAmountRequested ->
                    UpdatedAmount = BankAmount - RandomAmountRequested,
                    io:fwrite("Bank: ~w, Amount: ~w\n", [BankName, UpdatedAmount]),
                    Sender ! {"TransactionApproved", CustomerName, RandomAmountRequested, BankName, ParentSender},
                    ParentSender ! {"TransactionApproved", CustomerName, RandomAmountRequested, BankName},
                    withdraw_amount_from_bank(BankName, UpdatedAmount, BankMap);
                true ->
                    % Handle cases where BankAmount < RandomAmountRequested
                    % UpdatedAmount = BankAmount - RandomAmountRequested,
                    io:fwrite("Bank: ~w, Amount: ~w\n", [BankName, BankAmount]),
                    Sender ! {"TransactionRejected", CustomerName, RandomAmountRequested, BankName, ParentSender},
                    ParentSender ! {"TransactionRejected", CustomerName, RandomAmountRequested, BankName},
                    withdraw_amount_from_bank(BankName, BankAmount, BankMap)
            end
            % io:fwrite("GG Guys!!\n"),
            

        after 200 ->
            % io:fwrite("GG Guys!!\n"),
            exit(self(),ok)
    end.
