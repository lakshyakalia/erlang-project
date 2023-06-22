-module(money).
-import(customer, [request_amount_from_bank/4]).
-import(bank, [withdraw_amount_from_bank/3]).
-export([start/1, customer_loop/5, bank_loop/4, initialize_banks/1, initialize_customers/3]).

    % get_value(Key, Map) ->
    %     case maps:get(Key, Map) of
    %         {ok, Value} -> 
    %             Value;
    %         error ->
    %             not_found
    %     end.    

    start(Args) ->
        CustomerFile = lists:nth(1, Args),
        BankFile = lists:nth(2, Args),
        {ok, CustomerInfo} = file:consult(CustomerFile),
        {ok, BankInfo} = file:consult(BankFile),

        CustomerMap = maps:from_list(CustomerInfo),
        BankMap = maps:from_list(BankInfo),
        

        BankDict = initialize_banks(BankMap),
        % BankDict = 
        initialize_customers(CustomerMap,BankMap, BankDict).
        


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
        PId = spawn(bank, withdraw_amount_from_bank, [BankName, BankAmount, BankMap]),
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
        PId = spawn(customer, request_amount_from_bank, [CustomerName, CustomerRequestedAmount, CustomerMap, BankMap, BankDict]),
        register(CustomerName, PId),
        PId ! {self(), CustomerName},
        customer_loop(CustomerMap, CustomerKeySet, BankMap, Index - 1, BankDict).