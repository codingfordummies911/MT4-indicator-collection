//+------------------------------------------------------------------+
//|                                           UltimateVolatility.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
double GetATR130(int i, int period)
{
   return iCustom(NULL,0,"Ultimate Volatility Indicator 130",bars,VolatilityType,"",period,"","",vol1_Alpha,"","",
            vol2_AutoCalc,vol2_Lambda,vol2_EmaPeriod,"","",vol4_Yang_Zhang_extension,"","",e_type_data,e_reverse_data,e_alpha,
            e_beta,MA_Period,MA_Method,multi,"","","",MAType,"","",MAMode,"","",jurikPhase,jurikDouble,"","",MAModeZLMA,   0,i);

}
double GetATR140(int i, int period, int bars__)
{
   return iCustom(NULL,0,"Ultimate Volatility Indicator 130",bars__,VolatilityType,"",period,"","",vol1_Alpha,"","",
            vol2_AutoCalc,vol2_Lambda,vol2_EmaPeriod,"","",vol4_Yang_Zhang_extension,"","",e_type_data,e_reverse_data,e_alpha,
            e_beta,MA_Period,MA_Method,multi,"","","",MAType,"","",MAMode,"","",jurikPhase,jurikDouble,"","",MAModeZLMA,   0,i);

}
double GetATR150(int i, int period, int bars__)
{
   return iCustom(NULL,0,"Ultimate Volatility Indicator 150",bars__,VolatilityType,"",period,"","",vol1_Alpha,"","",
            vol2_AutoCalc,vol2_Lambda,vol2_EmaPeriod,"","",vol4_Yang_Zhang_extension,"","",e_type_data,e_reverse_data,e_alpha,
            e_beta,period,MA_Method,multi,"","","",MAType,"","",MAMode,"","",jurikPhase,jurikDouble,"","",MAModeZLMA,   0,i);

}
double GetATR160(int i, int period, int bars__)
{
   return iCustom(NULL,0,"Ultimate Volatility Indicator 160",bars__,VolatilityType,"",period,"","",vol1_Alpha,"","",
            vol2_AutoCalc,vol2_Lambda,vol2_EmaPeriod,"","",vol4_Yang_Zhang_extension,"","",e_type_data,e_reverse_data,e_alpha,
            e_beta,period,MA_Method,multi,"","","",MAType,"","",MAMode,"","",jurikPhase,jurikDouble,"","",MAModeZLMA,   0,i);

}
double GetATR_UVI(int i, int period, int version_, int nbars)
{
   switch(version_)
   {
      case 130 : return GetATR130(i, period);
               break;
      case 140 : return GetATR140(i, period, nbars);
               break;
      case 150 : return GetATR150(i, period, nbars);
               break;
      case 160 : return GetATR160(i, period, nbars);
               break;
   }
   
   return -1;
}

