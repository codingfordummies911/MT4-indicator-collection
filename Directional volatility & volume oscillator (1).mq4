//+------------------------------------------------------------------+
//|                   Directional volatility & volume oscillator.mq4 |
//|                                        Copyright 2021,PuguForex. |
//|                          https://www.mql5.com/en/users/puguforex |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021,PuguForex."
#property link      "https://www.mql5.com/en/users/puguforex"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 9

#property indicator_label1 "Volatility Up"
#property indicator_type1  DRAW_HISTOGRAM
#property indicator_color1 clrNavy
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2

#property indicator_label2 "Volatility Down"
#property indicator_type2  DRAW_HISTOGRAM
#property indicator_color2 clrCrimson
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2

#property indicator_label3 "Volatility"
#property indicator_type3  DRAW_LINE
#property indicator_color3 clrSilver
#property indicator_style3 STYLE_SOLID
#property indicator_width3 2

#property indicator_label4 "Volume Up"
#property indicator_type4  DRAW_HISTOGRAM
#property indicator_color4 clrAqua
#property indicator_style4 STYLE_SOLID
#property indicator_width4 2

#property indicator_label5 "Volume Down"
#property indicator_type5  DRAW_HISTOGRAM
#property indicator_color5 clrYellow
#property indicator_style5 STYLE_SOLID
#property indicator_width5 2

#property indicator_label6 "Volume Up"
#property indicator_type6  DRAW_HISTOGRAM
#property indicator_color6 clrAqua
#property indicator_style6 STYLE_SOLID
#property indicator_width6 2

#property indicator_label7 "Volume Down"
#property indicator_type7  DRAW_HISTOGRAM
#property indicator_color7 clrYellow
#property indicator_style7 STYLE_SOLID
#property indicator_width7 2

#property indicator_label8 "Zone Up"
#property indicator_type8  DRAW_LINE
#property indicator_color8 clrSilver
#property indicator_style8 STYLE_SOLID
#property indicator_width8 3

#property indicator_label9 "Zone Down"
#property indicator_type9  DRAW_LINE
#property indicator_color9 clrSilver
#property indicator_style9 STYLE_SOLID
#property indicator_width9 3

input int            inpVolatilityPeriod  = 5;        //Volatility period
input ENUM_MA_METHOD inpVolatilityMethod  = MODE_SMA; //Volatility method
input int            inpVolumePeriod      = 14;       //Volume period
input ENUM_MA_METHOD inpVolumeMethod      = MODE_SMA; //Volume method
input int            inpZonePeriod        = 14;       //Zone period
input ENUM_MA_METHOD inpZoneMethod        = MODE_SMA; //Zone method

double valUp[],valDn[],val[],volUpa[],volDna[],volUpb[],volDnb[],znUp[],znDn[],volSm[],vol[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   IndicatorBuffers(11);
   SetIndexBuffer(0,valUp  ,INDICATOR_DATA);
   SetIndexBuffer(1,valDn  ,INDICATOR_DATA);
   SetIndexBuffer(2,val    ,INDICATOR_DATA);
   SetIndexBuffer(3,volUpa ,INDICATOR_DATA);
   SetIndexBuffer(4,volDna ,INDICATOR_DATA);
   SetIndexBuffer(5,volUpb ,INDICATOR_DATA);
   SetIndexBuffer(6,volDnb ,INDICATOR_DATA);
   SetIndexBuffer(7,znUp   ,INDICATOR_DATA);
   SetIndexBuffer(8,znDn   ,INDICATOR_DATA);
   SetIndexBuffer(9,volSm  ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,vol   ,INDICATOR_CALCULATIONS);
//---
   IndicatorSetString(INDICATOR_SHORTNAME,"Directional volatility & volume oscillator");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int limit=rates_total-prev_calculated+1; if (limit>=rates_total) limit=rates_total-1;  
//---
   for(int i=limit; i>=0 && !_StopFlag; i--)
     {
      double zeroLine = iMA(_Symbol,_Period,inpZonePeriod,0,inpZoneMethod,PRICE_MEDIAN,i);
      
      val[i] = iMA(_Symbol,_Period,inpVolatilityPeriod,0,inpVolatilityMethod,PRICE_CLOSE,i) - zeroLine;
      znUp[i] = iMA(_Symbol,_Period,inpZonePeriod,0,inpZoneMethod,PRICE_HIGH,i) - zeroLine;
      znDn[i] = iMA(_Symbol,_Period,inpZonePeriod,0,inpZoneMethod,PRICE_LOW,i) - zeroLine;
      
      valUp[i] = val[i]>znUp[i] ? val[i] : EMPTY_VALUE;
      valDn[i] = val[i]<znDn[i] ? val[i] : EMPTY_VALUE;
        
      vol[i] = close[i]>open[i] ? (double)tick_volume[i] : (double)-tick_volume[i];  
     }
       
   for(int i=limit; i>=0 && !_StopFlag; i--)
     {
      volSm[i] = iMAOnArray(vol,WHOLE_ARRAY,inpVolumePeriod,0,inpVolumeMethod,i);
         
      volUpa[i] = volSm[i]>0 ? znUp[i] : EMPTY_VALUE;
      volUpb[i] = volSm[i]>0 ? znDn[i] : EMPTY_VALUE;
      volDna[i] = volSm[i]<0 ? znDn[i] : EMPTY_VALUE;
      volDnb[i] = volSm[i]<0 ? znUp[i] : EMPTY_VALUE;  
     }    
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
