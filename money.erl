-module(money).
-import(customer, [request_amount_from_bank/4]).
-import(bank, [withdraw_amount_from_bank/3]).
-export([start/1, customer_loop/5, bank_loop/4, initialize_banks/1, initialize_customers/3, display_message_on_screen/6]).

    % get_value(Key, Map) ->
    %     case maps:get(Key, Map) of
    %         {ok, Value} -> 
    %             Value;
    %         error ->
    %             not_found
    %     end.    

    start(Args) ->
        register(moneyPid, self()),
        CustomerFile = lists:nth(1, Args),
        BankFile = lists:nth(2, Args),
        {ok, CustomerInfo} = file:consult(CustomerFile),
        {ok, BankInfo} = file:consult(BankFile),

        CustomerMap = maps:from_list(CustomerInfo),
        BankMap = maps:from_list(BankInfo),
        
        io:fwrite("** The financial market is opening for the day **\n\n"),
        io:fwrite("Starting transaction log...\n\n"),
        BankDict = initialize_banks(BankMap),
        % BankDict = 
        initialize_customers(CustomerMap,BankMap, BankDict),
        BankCount = maps:size(BankMap),
        CustomerCount = maps:size(CustomerMap),
        display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount, [], []).
        


    initialize_banks(BankMap) ->

        Index = maps:size(BankMap),
        BankKeySet = maps:keys(BankMap),
        bank_loop(BankMap, BankKeySet, Index, #{}).

    bank_loop(BankMap, BankKeySet, 0, BankDict) ->
        BankDict;

    bank_loop(BankMap, BankKeySet, Index, BankDict) ->
        BankName = lists:nth(Index, BankKeySet),
        % BankAmount = get_value(BankName, BankMap),
        BankAmount = maps:get(BankName, BankMap),
        % io:format("Errorroror~n"),
        PId = spawn(bank, withdraw_amount_from_bank, [BankName, BankAmount, BankMap, BankAmount]),
        register(BankName, PId),
        NewBankDict = maps:put(BankName, PId, BankDict),
        PId ! {self(), BankName},
        bank_loop(BankMap, BankKeySet, Index - 1, NewBankDict).

    initialize_customers(CustomerMap, BankMap, BankDict) ->

        Index = maps:size(CustomerMap),
        CustomerKeySet = maps:keys(CustomerMap),
        customer_loop(CustomerMap, CustomerKeySet, BankMap, Index, BankDict).

    customer_loop(CustomerMap, CustomerKeySet, BankMap, 0, BankDict) ->
        done;

    customer_loop(CustomerMap, CustomerKeySet, BankMap, Index, BankDict) ->
        CustomerName = lists:nth(Index, CustomerKeySet),
        % CustomerRequestedAmount = get_value(CustomerName, CustomerMap),
        CustomerRequestedAmount = maps:get(CustomerName, CustomerMap),
        % io:format("ErrorrororCus~n"),
        PId = spawn(customer, request_amount_from_bank, [CustomerName, CustomerRequestedAmount, CustomerMap, BankMap, BankDict, CustomerRequestedAmount]),
        register(CustomerName, PId),
        PId ! {self(), CustomerName},
        customer_loop(CustomerMap, CustomerKeySet, BankMap, Index - 1, BankDict).

    print_bank_list_tuples([], Original, Loaned) ->
        io:fwrite("----\nTotal: original ~w, loaned ~w\n\n",[Original, Loaned]),
        ok;
    print_bank_list_tuples([{X, Y, Z} | Tail], Original, Loaned) ->
        io:format("~w: original ~w, balance ~w\n", [X, Z, Y]),
        print_bank_list_tuples(Tail, Original + Z, Loaned + Z - Y).

    print_customer_list_tuples([], Objective, Received) ->
        io:fwrite("----\nTotal: objective ~w, received ~w",[Objective, Received]),
        ok;
    print_customer_list_tuples([{X, Y, Z} | Tail], Objective, Received) ->
        io:format("~w: objective ~w, received ~w\n", [X, Z, Y]),
        print_customer_list_tuples(Tail, Objective + Z, Received + Y).

    display_bank_report(FinalBankList) ->
        io:fwrite("\n\nBanks:\n"),
        print_bank_list_tuples(FinalBankList, 0, 0).

    display_customer_report(FinalCustomerList) ->
        io:fwrite("Customers:\n"),
        print_customer_list_tuples(FinalCustomerList, 0 ,0).

    display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount, FinalBankList, FinalCustomerList) ->
        receive
            {"TransactionApproved", CustomerName, AmountRequested, BankName} ->
                io:fwrite("$ The ~w bank approves a loan of ~w dollar(s) to ~w\n",[BankName, AmountRequested, CustomerName]),
                display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount, FinalBankList, FinalCustomerList);
            {"TransactionRejected", CustomerName, AmountRequested, BankName} ->
                io:fwrite("$ The ~w bank denies a loan of ~w dollar(s) to ~w\n",[BankName, AmountRequested, CustomerName]),
                display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount, FinalBankList, FinalCustomerList);
            {"TransactionRequest", CustomerName, AmountRequested, BankName} ->
                io:fwrite("? ~w requests a loan of ~w dollar(s) from the ~w bank\n",[CustomerName, AmountRequested, BankName]),
                display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount, FinalBankList, FinalCustomerList);
            {"BankThreadEnded", BankName, BankAmount, OriginalAmount} ->
                CurrentBankSize = maps:size(BankMap),
                if CurrentBankSize == BankCount ->
                    TempBankMap = maps:remove(BankName, BankMap),
                    TempTuple = {BankName, BankAmount, OriginalAmount},
                    NewList = [TempTuple | FinalBankList],
                    display_message_on_screen(TempBankMap, BankCount, CustomerMap, CustomerCount, NewList, FinalCustomerList);
                true ->
                    if CurrentBankSize == 1 ->
                        TempBankMap = maps:remove(BankName, BankMap),
                        TempTuple = {BankName, BankAmount, OriginalAmount},
                        NewList = [TempTuple | FinalBankList],
                        display_bank_report(NewList),
                        display_message_on_screen(TempBankMap, BankCount, CustomerMap, CustomerCount, NewList, FinalCustomerList);
                    true ->
                        TempBankMap = maps:remove(BankName, BankMap),
                        TempTuple = {BankName, BankAmount, OriginalAmount},
                        NewList = [TempTuple | FinalBankList],
                        display_message_on_screen(TempBankMap, BankCount, CustomerMap, CustomerCount, NewList, FinalCustomerList)
                    end
                end;
                

            {"CustomerThreadEnded", CustomerName, CustomerAmount, OriginalRequestedAmount} ->
                CurrentCustomerSize = maps:size(CustomerMap),
                if CurrentCustomerSize == CustomerCount ->
                    io:fwrite("\n\n** Banking Report **\n"),
                    TempCustomerMap = maps:remove(CustomerName, CustomerMap),
                    TempTuple = {CustomerName, CustomerAmount, OriginalRequestedAmount},
                    NewList = [TempTuple | FinalCustomerList],
                    display_message_on_screen(BankMap, BankCount, TempCustomerMap, CustomerCount, FinalBankList, NewList);
                true ->
                    if CurrentCustomerSize == 1 ->
                        TempCustomerMap = maps:remove(CustomerName, CustomerMap),
                        TempTuple = {CustomerName, CustomerAmount, OriginalRequestedAmount},
                        NewList = [TempTuple | FinalCustomerList],
                        display_customer_report(NewList),
                        display_message_on_screen(BankMap, BankCount, TempCustomerMap, CustomerCount, FinalBankList, NewList);
                    true ->
                        TempCustomerMap = maps:remove(CustomerName, CustomerMap),
                        TempTuple = {CustomerName, CustomerAmount, OriginalRequestedAmount},
                        NewList = [TempTuple | FinalCustomerList],
                        display_message_on_screen(BankMap, BankCount, TempCustomerMap, CustomerCount, FinalBankList, NewList)
                    end
                end

            after 3000 ->
                io:fwrite("\n\nThe financial market is closing for the day...\n")


        end.