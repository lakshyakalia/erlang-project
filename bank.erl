-module(bank).
-export([withdraw_amount_from_bank/4]).

withdraw_amount_from_bank(BankName, BankAmount, BankMap, OriginalAmount) ->
    receive
        {Sender, BankName} ->
            % io:fwrite("From Bank ID: ~w,~w,~w,~w\n\n", [BankName, BankAmount, self(), Sender]),
            withdraw_amount_from_bank(BankName, BankAmount, BankMap, OriginalAmount);

        {ParentSender, Sender, CustomerName, RandomAmountRequested} ->
            if
                BankAmount >= RandomAmountRequested ->
                    UpdatedAmount = BankAmount - RandomAmountRequested,
                    Sender ! {"TransactionApproved", CustomerName, RandomAmountRequested, BankName, ParentSender},
                    ParentSender ! {"TransactionApproved", CustomerName, RandomAmountRequested, BankName},
                    withdraw_amount_from_bank(BankName, UpdatedAmount, BankMap, OriginalAmount);
                true ->
                    % Handle cases where BankAmount < RandomAmountRequested
                    Sender ! {"TransactionRejected", CustomerName, RandomAmountRequested, BankName, ParentSender},
                    ParentSender ! {"TransactionRejected", CustomerName, RandomAmountRequested, BankName},
                    withdraw_amount_from_bank(BankName, BankAmount, BankMap, OriginalAmount)
            end
            % io:fwrite("GG Guys!!\n"),
            

        after 900 ->
            % io:fwrite(),
            ParentSender = whereis(moneyPid),
            ParentSender ! {"BankThreadEnded", BankName, BankAmount, OriginalAmount},
            % io:fwrite("Stopped"),
            exit(self(),ok)
    end.
