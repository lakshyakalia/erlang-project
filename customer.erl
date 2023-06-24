-module(customer).
-export([request_amount_from_bank/6]).


    request_amount_from_bank(CustomerName, CustomerRequestedAmount, CustomerMap, BankMap, BankDict, OriginalRequestedAmount) ->
        receive
            {"Started", Sender} ->
                timer:sleep(200),
                % io:fwrite("Sleeped"),
                self() ! {Sender, CustomerName},
                request_amount_from_bank(CustomerName, CustomerRequestedAmount, CustomerMap, BankMap, BankDict, OriginalRequestedAmount);
            {Sender, CustomerName} ->
                
                % random:seed(now()),
                BankKeySet = maps:keys(BankMap),
                RandomKeyIndex = rand:uniform(length(BankKeySet)),   
                RandomBank = lists:nth(RandomKeyIndex,maps:keys(BankMap)),
                % random:seed(now()),

                if CustomerRequestedAmount > 0 ->
                    if CustomerRequestedAmount > 50 ->
                        RandomAmountRequested = rand:uniform(50) + 1,
                        Sender ! {"TransactionRequest", CustomerName, RandomAmountRequested, RandomBank},
                        case maps:get(RandomBank, BankDict) of
                            undefined ->
                                io:fwrite("Bank not found in dictionary\n");
                            Pid ->
                                Pid ! {Sender, self(), CustomerName, RandomAmountRequested}
                        end;
                    true ->
                        RandomAmountRequested = rand:uniform(CustomerRequestedAmount),
                        Sender ! {"TransactionRequest", CustomerName, RandomAmountRequested, RandomBank},
                        case maps:get(RandomBank, BankDict) of
                            undefined ->
                                io:fwrite("Bank not found in dictionary\n");
                            Pid ->
                                Pid ! {Sender, self(), CustomerName, RandomAmountRequested}
                        end
                    end;
                true ->
                    % io:fwrite("Stopped"),
                    ok
                end,

                request_amount_from_bank(CustomerName, CustomerRequestedAmount, CustomerMap, BankMap, BankDict, OriginalRequestedAmount);
                

            {"TransactionApproved", CustomerName, RandomAmountRequested, BankName, ParentSender} ->

                NewAmount = CustomerRequestedAmount - RandomAmountRequested,
                CustomerPid = whereis(CustomerName),

                CustomerPid ! {ParentSender, CustomerName},
                request_amount_from_bank(CustomerName, NewAmount, CustomerMap, BankMap, BankDict, OriginalRequestedAmount);

            {"TransactionRejected", CustomerName, RandomAmountRequested, BankName, ParentSender} ->
                % io:fwrite("~w bank, ~w Cus, denied",[BankName,CustomerName]),
                
                TempBankMap = maps:remove(BankName, BankMap),
                MapSize = maps:size(TempBankMap),
                if MapSize > 0 ->
                    CustomerPid = whereis(CustomerName),

                    CustomerPid ! {ParentSender, CustomerName};
                    true ->
                        % io:fwrite("Stopped"),
                        ok
                    end,
                request_amount_from_bank(CustomerName, CustomerRequestedAmount, CustomerMap, TempBankMap, BankDict, OriginalRequestedAmount)

            after 900 ->
                % io:fwrite("Ended!!!!"),
                ParentSender = whereis(moneyPid),
                ParentSender ! {"CustomerThreadEnded", CustomerName, OriginalRequestedAmount - CustomerRequestedAmount, OriginalRequestedAmount},
                exit(self(),ok)

        end.

    