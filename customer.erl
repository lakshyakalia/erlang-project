-module(customer).
-export([request_amount_from_bank/5]).
% -import(money,[start/1, customer_loop/4, bank_loop/3, initialize_banks/1, initialize_customers/2]).
% -import(bank,[withdraw_amount_from_bank/3]).


    % get_pid_from_bank_dict(BankDict, BankName) ->
    %     case maps:is_key(BankName, BankDict) of
    %         true ->
    %             {ok, Pid} = maps:get(BankName, BankDict),
    %             Pid;
    %         false ->
    %             %% Handle the case when the bank name is not found in the dictionary
    %             undefined
    %     end.
    request_amount_from_bank(CustomerName, CustomerRequestedAmount, CustomerMap, BankMap, BankDict) ->
        receive
            {Sender, CustomerName} ->
                
                random:seed(now()),
                BankKeySet = maps:keys(BankMap),
                RandomKeyIndex = random:uniform(length(BankKeySet)),   
                RandomBank = lists:nth(RandomKeyIndex,maps:keys(BankMap)),
                random:seed(now()),
                RandomAmountRequested = random:uniform(50) + 1,
                io:fwrite("? ~w requests a loan of ~w dollars(s) from the ~w bank\n", [CustomerName, RandomAmountRequested, RandomBank]),
                case maps:get(RandomBank, BankDict) of
                undefined ->
                    io:fwrite("Bank not found in dictionary\n");
                Pid ->
                    io:fwrite("PID for ~w: ~w\n", [RandomBank, Pid]),
                    % io:format("Stored Pid: ~p~n", [Pid]),
                    % io:format("Is Pid: ~p~n", [is_pid(Pid)]),
                    Pid ! {self(), CustomerName, RandomAmountRequested}
                end

        end.

    