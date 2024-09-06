//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                SonicR VSA Candlesticks.mq4                                |
//|                                                      				                         |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright @ 2012 traderathome"
#property link      "email: traderathome@msn.com"
 
/*---------------------------------------------------------------------------------------------
Overview:

This indicator creates standard candlesticks with the three features listed here and more fully
described below.
1. The candlesticks have special colors to denote special volume/price situations. 
2. The candlesticks can be set to automatically adjust width as you zoom in/out on the chart. 
3. The candlesticks can be manually widened.

1. Special Volume/Price Situations- 
   Candlesticks emphasized with special colors to denote special volume/price situations help 
   you quickly associate them with the correct volume bars.
   A. Climax Candles 
      Candles where the product of candle spread x candle volume is highest for the 20 most
      recent candles.  Bull candles are green and bear candles are red. 
   B. Rising Above Average Candles
      Candles where volume is greater than the product of 1.38 x the average volume of the 
      10 most recent candles.  These candles are blue.

2. Automatic_Zoom-
   This feature will have widths automatically adjust, with the next arriving tick, to what 
   is appropriate for the chart zoom setting.  When MT4 is first started the bar widths are 
   incorrect until the first tick arrives.  If ticks are slow coming, or if there is no live
   feed (weekend/holiday), you can force the width adjustment by switching the chart TF.  
      
   The widths are set by code based on encountered "WindowBarsPerChart( )".  As you zoom
   out, there are more.  As you zoom in there are less.  This might be affected by the 
   width capacity of the monitor.  Extra wide monitors, if showing more bars per chart
   on all zoom settings than what the code expects, can result in narrower bars displayed 
   than intended.  This is because the additional bars encountered are interpreted by the 
   code as meaning the chart has been zoomed out an extra step or more, and the code displays
   the narrower bar widths that would otherwise be appropriate.  Downsizing charts presents a 
   problem also, causing bar widths that are too wide because the fewer bars encountered are 
   interpreted by the code as meaning the chart has been zoomed in an extra step or more.  It
   therefore displays the wider bars that would otherwise be appropriate.  So, in cases of an 
   extra wide monitor or downsizing of charts, undesirable results can occur and you should 
   use the manual width adjustment.  
            
3. Manual_Zoom_01234-
   For reasons stated in #2 above, or if you tend to use only the standard zoom setting, or 
   some other single zoom setting, manually selecting the zoom setting is the best choice.  
   Selecting "0" sets widths appropriate for the two chart zoom out/"-" settings that are
   below the standard chart zoom setting.  Selecting "1" sets width appropriate for the Mt4
   standard/default chart zoom setting.  Apply "2,3, or 4" for zooming in/"+" on a chart from
   the standard zoom setting to get the wider bars that are appropriate.

To see the VSA Candlesticks displayed as intended, be sure in chart Properties on the Common 
tab you have selected "Candlesticks" and have unchecked the "Chart on foreground".  The chart 
cannot be "foreground!
     
This indicator can be turned on/off without having to remove it from the chart, preserving the 
chart settings. 
    
                                                                    - Traderathome, 04-04-2012
-----------------------------------------------------------------------------------------------
Acknowledgements:
BetterVolume.mq4 - for "climax" candle code definition (BetterVolume_v1.4).
                                                                    
----------------------------------------------------------------------------------------------
Suggested Colors            White Chart        Black Chart        
 
Candle Wicks Up             C'15,15,68'        Gray
CandleWicks Dn              C'15,15,68'        Gray
Bull Candle                 C'163,163,163'     C'163,163,163'
Bear Candle                 C'60,60,60'        C'100,100,100' 
Above Average Up            C'45,81,206'       C'62,158,255'     
Above Average Dn            C'45,81,206'       C'62,158,255'                                                             
Climax Bull                 C'0,170,85'        C'33,207,77'                             
Climax Bear                 C'222,18,80'       C'244,0,0'                              
 
Note: Suggested colors coincide with the colors in the concurrent release of the 
      SonicR VSA Histogram indicator.                                                                     
---------------------------------------------------------------------------------------------*/


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |                                                        
//+-------------------------------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 8

#property indicator_color1  Gray      
#property indicator_color2  Gray 
#property indicator_color3  C'163,163,163'      
#property indicator_color4  C'100,100,100'  
#property indicator_color5  C'62,158,255'  
#property indicator_color6  C'62,158,255'
#property indicator_color7  C'33,207,77'  
#property indicator_color8  C'244,0,0'     
                       
#property indicator_width1  1
#property indicator_width2  1

//Global External Inputs 
extern bool   Indicator_On                    = true;
extern bool   Automatic_Zoom                  = false;
extern int    Manual_Zoom_01234               = 1;
extern bool   Show_Climax_Volume              = true;
extern bool   Show_Above_Average_Volume       = true;        

//Global Buffers and Variables
bool          FLAG_deinit;
double        Bar1[], Candle1[], Bar2[],	Candle2[];		   
double        RisingBull[],RisingBear[],ClimaxBull[], ClimaxBear[];
double        av,Range,Value2,HiValue2,tempv2,high,low,open,close,bodyHigh,bodyLow;
int           Wide_Bar_Width,va,i,j,n,shift1,shift2,time1;
int           Climax_Analysis_Period          = 20; 
int           Volume_Averaging_Period         = 10;
double        Above_Average_Volume_Factor     = 1.38; 

//Automatic Zoom Parameters
string __                              = "";
string Part_2                          = "Auto-Width_Adjustments:";
string note1                           = "Wide monitors may require";
string note2                           = "WindowsBarsPerChart be increased";
string note3                           = "for these chart zoom settings:";
int    Zoom_Out_2_Bars                 = 1200;
int    Zoom_Out_1_Bars                 = 500;
int    Zoom_Std_Bars                   = 200;
int    Zoom_In_1_Bars                  = 100;
int    Zoom_In_2_Bars                  = 60; 
  
//+-------------------------------------------------------------------------------------------+
//| Custom indicator initialization function                                                  |
//+-------------------------------------------------------------------------------------------+
int init()
  {
  FLAG_deinit = false;
  
  //Automatically Adjust Width    
  if(Automatic_Zoom)   
    {
          if (WindowBarsPerChart( ) >= Zoom_Out_2_Bars) {Wide_Bar_Width = 1;} 
    else {if (WindowBarsPerChart( ) >= Zoom_Out_1_Bars) {Wide_Bar_Width = 2;} 
    else {if (WindowBarsPerChart( ) >= Zoom_Std_Bars)   {Wide_Bar_Width = 2;} 
    else {if (WindowBarsPerChart( ) >= Zoom_In_1_Bars)  {Wide_Bar_Width = 3;} 
    else {if (WindowBarsPerChart( ) >= Zoom_In_2_Bars)  {Wide_Bar_Width = 6;} 
    else {Wide_Bar_Width = 13;} }}}}
    }
  else //Manually Adjust Width
    {
          if (Manual_Zoom_01234 <= 0) {Wide_Bar_Width = 1;}
    else {if (Manual_Zoom_01234 == 1) {Wide_Bar_Width = 2;}
    else {if (Manual_Zoom_01234 == 2) {Wide_Bar_Width = 3;}
    else {if (Manual_Zoom_01234 == 3) {Wide_Bar_Width = 6;}
    else {Wide_Bar_Width = 13;} }}}
    }

  //Indicators   
  SetIndexBuffer(0,Bar1);
  SetIndexStyle(0,DRAW_HISTOGRAM, 0, 1);
  SetIndexBuffer(1,Bar2);  
  SetIndexStyle(1,DRAW_HISTOGRAM, 0, 1);  				
  SetIndexBuffer(2,Candle1);
  SetIndexStyle(2,DRAW_HISTOGRAM, 0, Wide_Bar_Width);
  SetIndexBuffer(3,Candle2);  
  SetIndexStyle(3,DRAW_HISTOGRAM, 0, Wide_Bar_Width);  
  if(Show_Above_Average_Volume)
    {
    SetIndexBuffer(4, RisingBull);
    SetIndexStyle(4, DRAW_HISTOGRAM, 0, Wide_Bar_Width);   
    SetIndexBuffer(5, RisingBear);                            
    SetIndexStyle(5, DRAW_HISTOGRAM, 0, Wide_Bar_Width);    
    }      
  if(Show_Climax_Volume)
    {    
    SetIndexBuffer(6, ClimaxBull);
    SetIndexStyle(6, DRAW_HISTOGRAM, 0, Wide_Bar_Width);
    SetIndexBuffer(7, ClimaxBear);          
    SetIndexStyle(7, DRAW_HISTOGRAM, 0, Wide_Bar_Width);                  
    } 
    
  //Indicator ShortName   
  IndicatorShortName("SonicR VSA Candlesticks");        
 	       	 		
  return(0);
  }
   
//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+    
int deinit()
  {
  return(0);
  }
   
//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int start()
  {
  //If Indicator is "Off" deinitialize only once, not every tick 
  if (!Indicator_On) 
    {
    if (!FLAG_deinit) {deinit(); FLAG_deinit = true;}
    return(0);
    }

  //Otherwise indicator is "On" & chart TF is in display range, so proceed  
  if(Automatic_Zoom) {init();}
  else {deinit(); FLAG_deinit = false;}
       
  //Standard Candles loop
  for(int i = Bars-1-IndicatorCounted(); i >= 0; i--)
    {
    //First, calculate OHLC etc., to construct standard candle     
	 shift1  = iBarShift(NULL,0,Time[i]);
	 time1   = iTime    (NULL,0,shift1);
	 shift2  = iBarShift(NULL,0,time1);
	 high    = iHigh(NULL,0,shift1);
    low     = iLow(NULL,0,shift1);
	 open    = iOpen(NULL,0,shift1);
	 close   = iClose(NULL,0,shift1);
	 bodyHigh= MathMax(open,close);
	 bodyLow = MathMin(open,close);
			 
	 if(close>open)
		{
		Bar1[shift2] = high;		Candle1[shift2] = bodyHigh;
		Bar2[shift2] = low;		Candle2[shift2] = bodyLow;
		}
	 else if(close<open)
		{
	 	Bar1[shift2] = low;		Candle1[shift2] = bodyLow;
		Bar2[shift2] = high;		Candle2[shift2] = bodyHigh;
		}
	 else //(close==open)
	   {	
		Bar1[shift2] = low;		Candle1[shift2] = close;
		Bar2[shift2] = high;		Candle2[shift2] = open-0.000001;
      }
      
    //Clear buffers
    RisingBull[i] = 0;
    RisingBear[i] = 0;
    ClimaxBull[i] = 0;
    ClimaxBear[i] = 0;  
    HiValue2      = 0; 
    tempv2        = 0;
    av            = 0;
    va            = 0;
      
    //Compute Average Volume and Volume Rising Above Average   
    if(Show_Above_Average_Volume)
      {   
      for (j = i; j < (i+Volume_Averaging_Period); j++) {av = av + Volume[j];}
      av = av / Volume_Averaging_Period;
      if (Volume[i] > av * Above_Average_Volume_Factor) {va= 2;}
      }
                      
    //Compute "Climax" Parameter (HiValue2)
    if(Show_Climax_Volume)
      {                       
      Range = (High[i]-Low[i]);
      Value2 = Volume[i]*Range;                 
      for (n=i;n<i+Climax_Analysis_Period;n++)
        {
        tempv2 = Volume[n]*((High[n]-Low[n])); 
        if (tempv2 >= HiValue2) {HiValue2 = tempv2;}    
        } 
      if(Value2 >= HiValue2) {va= 1;}  
      }            
             
    //Apply Correct Color to Candle
    if (va==1)
      {
      ClimaxBull[i]=iClose(0,0,i);
      ClimaxBear[i]=iOpen(0,0,i);       
      }
    else if (va==2)
      {
      RisingBull[i]=iClose(0,0,i);
      RisingBear[i]=iOpen(0,0,i);      
      }
    }                                  
                               
  return(0);
  }

//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+    
         