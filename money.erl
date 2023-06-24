-module(money).
-import(customer, [request_amount_from_bank/4]).
-import(bank, [withdraw_amount_from_bank/3]).
-export([start/1, customer_loop/5, bank_loop/4, initialize_banks/1, initialize_customers/3, display_message_on_screen/4]).

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
        display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount).
        


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

    display_bank_report(BankName, BankAmount, OriginalAmount) ->
        io:fwrite("~w: original ~w, balance ~w\n",[BankName, OriginalAmount, BankAmount]).

    display_customer_report(CustomerName, CustomerAmount, OriginalRequestedAmount) ->
        io:fwrite("~w: objective ~w, received ~w\n",[CustomerName, OriginalRequestedAmount, CustomerAmount]).

    display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount) ->
        receive
            {"TransactionApproved", CustomerName, AmountRequested, BankName} ->
                io:fwrite("$ The ~w bank approves a loan of ~w dollar(s) to ~w\n",[BankName, AmountRequested, CustomerName]),
                display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount);
            {"TransactionRejected", CustomerName, AmountRequested, BankName} ->
                io:fwrite("$ The ~w bank denies a loan of ~w dollar(s) to ~w\n",[BankName, AmountRequested, CustomerName]),
                display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount);
            {"TransactionRequest", CustomerName, AmountRequested, BankName} ->
                io:fwrite("? ~w requests a loan of ~w dollar(s) from the ~w bank\n",[CustomerName, AmountRequested, BankName]),
                display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount);
            {"BankThreadEnded", BankName, BankAmount, OriginalAmount} ->
                CurrentBankSize = maps:size(BankMap),
                if CurrentBankSize == BankCount ->
                    io:fwrite("\n\nBanks:\n"),
                    TempBankMap = maps:remove(BankName, BankMap),
                    display_bank_report(BankName, BankAmount, OriginalAmount),
                    display_message_on_screen(TempBankMap, BankCount, CustomerMap, CustomerCount);
                true ->
                    display_bank_report(BankName, BankAmount, OriginalAmount),
                    display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount)
                end;
                

            {"CustomerThreadEnded", CustomerName, CustomerAmount, OriginalRequestedAmount} ->
                CurrentCustomerSize = maps:size(CustomerMap),
                if CurrentCustomerSize == CustomerCount ->
                    io:fwrite("\n\n** Banking Report **\n"),
                    io:fwrite("\n\nCustomers:\n"),
                    TempCustomerMap = maps:remove(CustomerName, CustomerMap),
                    display_customer_report(CustomerName, CustomerAmount, OriginalRequestedAmount),
                    display_message_on_screen(BankMap, BankCount, TempCustomerMap, CustomerCount);
                true ->
                    display_customer_report(CustomerName, CustomerAmount, OriginalRequestedAmount),
                    display_message_on_screen(BankMap, BankCount, CustomerMap, CustomerCount)
                end

            after 5000 ->
                io:fwrite("\n\nThe financial market is closing for the day...\n")


        end.