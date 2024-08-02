//+------------------------------------------------------------------+
//|                                                    SQXInfoScript |
//|                            Copyright 2024, Javier Luque Sanabria |
//+------------------------------------------------------------------+
#property strict

struct SQXData {
    string symbol;
    double pointValue;
    double pipTickStep;
    double orderSizeStep;
    double pipTickSize;

    double currentSpread;
    double averageSpread;
    double percentile50Spread;
    double percentile75Spread;
    double percentile90Spread;
    double percentile99Spread;
    double modeSpread;
    double maximumSpread;
    double minimumSpread;

    double swapLong;
    double swapShort;
    string tripleSwapDay;
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart() {
    SQXData sqxData;
    int spreads_int [];
    int bars = iBars(_Symbol, PERIOD_M1);
    int num_spreads = CopySpread(_Symbol, PERIOD_M1, 0, bars, spreads_int);

    // Ensure we have enough ticks
    if(num_spreads < 1) {
        Print("No tick data available for the specified period.");
        return;
    }

    // Variables for calculating spread statistics
    double total_spread = 0.0;
    double max_spread = 0.0;
    double min_spread = DBL_MAX;
    double spread_array[];

    ArrayResize(spread_array, num_spreads, num_spreads);

    // Iterate over the ticks and calculate spreads
    for(int i = 0; i < num_spreads; i++) {
        double spread = spreads_int[i];
        total_spread += spread;

        // Determine maximum and minimum spread
        if(spread > max_spread)
            max_spread = spread;
        if(spread < min_spread)
            min_spread = spread;

        // Add the spread to the array
        spread_array[ArraySize(spread_array) - 1 - i] = spread;
    }


    ArraySort(spread_array);


    double tickWeight = GetTickWeight();
    sqxData.symbol = _Symbol;
    sqxData.currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) / tickWeight;
    sqxData.maximumSpread = max_spread / tickWeight;
    sqxData.minimumSpread = min_spread / tickWeight;
    sqxData.averageSpread = (total_spread / num_spreads) / tickWeight;
    sqxData.percentile50Spread = Percentile(spread_array, 50) / tickWeight;
    sqxData.percentile75Spread = Percentile(spread_array, 75) / tickWeight;
    sqxData.percentile90Spread = Percentile(spread_array, 90) / tickWeight;
    sqxData.percentile99Spread = Percentile(spread_array, 99) / tickWeight;
    sqxData.modeSpread = CalculateMode(spread_array) / tickWeight;

    // Output results
    Comment(StringFormat("Symbol: %s", _Symbol));
    GetSQXInfo(sqxData);
    GetSwapsInfo(sqxData);
    ShowSQXData(sqxData);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowSQXData(SQXData &sqxData) {

    string data = "\nSQX INFO\n"+
                  StringFormat("Point value: %.2f USD\n", GetPointValue()) +
                  StringFormat("Pip/Tick step: %.5f\n", GetPipTickStep()) +
                  StringFormat("Order size step: %.2f\n", GetOrderSizeStep()) +
                  StringFormat("Pip/Tick size: %.5f\n", GetPipTickSize()) +
                  "\nSPREAD INFO\n"+
                  StringFormat("Current Spread: %.2f points\n", sqxData.currentSpread) +
                  StringFormat("Average Spread: %.2f points\n", sqxData.averageSpread) +
                  StringFormat("Percentile 50: %.2f points\n", sqxData.percentile50Spread) +
                  StringFormat("Percentile 75: %.2f points\n", sqxData.percentile75Spread) +
                  StringFormat("Percentile 90: %.2f points\n", sqxData.percentile90Spread) +
                  StringFormat("Percentile 99: %.2f points\n", sqxData.percentile99Spread) +
                  StringFormat("Mode Spread: %.2f points\n", sqxData.modeSpread) +
                  StringFormat("Maximum Spread: %.2f points\n", sqxData.maximumSpread) +
                  StringFormat("Minimum Spread: %.2f points\n", sqxData.minimumSpread) +
                  "\nSWAP INFO\n"+
                  StringFormat("Swap Long: %.2f USD\n", sqxData.swapLong) +
                  StringFormat("Swap Short: %.2f USD\n", sqxData.swapShort) +
                  StringFormat("Triple Swap Day: %s\n", sqxData.tripleSwapDay);
    Comment(data);
    Print(data);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetSQXInfo(SQXData &sqxData) {
    sqxData.pointValue = GetPointValue();
    sqxData.pipTickStep = GetPipTickStep();
    sqxData.orderSizeStep = GetOrderSizeStep();
    sqxData.pipTickSize = GetPipTickSize();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetSwapsInfo(SQXData &sqxData) {
    sqxData.swapLong = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_LONG);
    sqxData.swapShort = SymbolInfoDouble(_Symbol, SYMBOL_SWAP_SHORT);
    sqxData.tripleSwapDay = EnumToString((ENUM_DAY_OF_WEEK)SymbolInfoInteger(_Symbol, SYMBOL_SWAP_ROLLOVER3DAYS));
    if(StringCompare(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD") != 0) {
        sqxData.swapLong *= GetCrossRate(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD");
        sqxData.swapShort *= GetCrossRate(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD");

        if(StringCompare(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "JPY") == 0) {
            sqxData.swapLong *= 100;
            sqxData.swapShort *= 100;
        }
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPointValue() {
    double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    if(StringCompare(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD") != 0) {
        pointValue *= GetCrossRate(SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT), "USD");
    }

    return pointValue;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPipTickSize() {
    return GetTickWeight() * _Point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetPipTickStep() {
    return _Point;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetOrderSizeStep() {
    return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTickWeight() {
    ENUM_SYMBOL_CALC_MODE calcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
    int tickWeight = 1;

    if(calcMode == SYMBOL_CALC_MODE_FOREX || calcMode == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE) {
        tickWeight = 10;
    }

    return tickWeight;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Percentile(double &data[], double percentile) {
    int n = ArraySize(data);
    if(n == 0)
        return 0.0;

    // Calculate the rank of the percentile
    double rank = (percentile / 100.0) * (n - 1);
    int lower_index = (int)MathFloor(rank);
    int upper_index = (int)MathCeil(rank);

    // Interpolation
    if(upper_index >= n)
        upper_index = n - 1;

    double weight = rank - lower_index;
    return data[lower_index] * (1.0 - weight) + data[upper_index] * weight;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateMode(double &data[]) {
    int n = ArraySize(data);
    if(n == 0)
        return 0.0;

    // Use a map to count frequencies of each spread value
    double mode = data[0];
    int max_count = 0;
    int count = 1;

    // Iterate over the sorted array to find the mode
    for(int i = 1; i < n; i++) {
        if(data[i] == data[i - 1]) {
            count++;
            if(count > max_count) {
                max_count = count;
                mode = data[i];
            }
        } else {
            count = 1;
        }
    }

    return mode;
}
double GetCrossRate(string curr_prof, string curr_acc) {

    string symbol = curr_prof + curr_acc;
    if(CheckMarketWatch(symbol)) {
        double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
        if(bid != 0.0)
            return bid;
    }
    // Try the inverse symbol
    symbol = curr_acc + curr_prof;
    if(CheckMarketWatch(symbol)) {
        double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
        if(ask != 0.0)
            return 1 / ask;
    }

    Print(__FUNCTION__, ": Error, cannot get cross rate for ", curr_prof + curr_acc);
    return 0.0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckMarketWatch(string symbol) {
    ResetLastError();
    // check if symbol is selected in the MarketWatch
    if(!SymbolInfoInteger(symbol, SYMBOL_SELECT)) {
        if(GetLastError() == ERR_MARKET_UNKNOWN_SYMBOL) {
            PrintFormat(__FUNCTION__+": Unknown symbol '%s'", symbol);
            return false;
        }
        if(!SymbolSelect(symbol, true)) {
            PrintFormat(__FUNCTION__+": Error adding symbol %d", GetLastError());
            return false;
        }
        Sleep(100);
        PrintFormat(__FUNCTION__+": Symbol '%s' is added in the MarketWatch.", symbol);
    }

    return true;
}
//+------------------------------------------------------------------+
