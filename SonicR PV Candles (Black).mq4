//+------------------------------------------------------------------------------------------+
//|                                                                                          |
//|                                  SonicR PV Candles.mq4                                   |
//|                                                                                          |
//+------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2011 traderathome"
#property link      "email:   traderathome@msn.com"

/*---------------------------------------------------------------------------------------------
Overview:

This indicator colors some candles according to the same special price and volume situations  
as the SonicR PV Histogram indicator, so you more quickly see the relationship between price 
and volume.  It works visually well for bar charts and candle charts.  

The indicator can be turned on/off without having to remove it from the chart, preserving your
chart settings.  You can specify a width to add to make wide bars, which is good for when you 
zoom in on a chart which naturally makes all the chart bars wider. You can also change colors.  
To make any such changes, modify the under the Inputs tab, close the External Inputs window 
and change the chart TF back and forth once.  Your changes are then made and appear under the 
Colors tab also.  They will be permanent for the chart until you make other changes.


There are user controls for the periods used in computing climax and rising volume, and for 
the factors that, by their settings, can "filter" to allow more or less bars be selected for 
display.  

  1. The Climax_Period is set to "20".  Decreasing the period tends to increase displayed bars 
     (less selective).  The Climax_Factor is set to "1.0", the maximum value.  A greater input
     will default to "1.0". The min/max recommeded range is "0.75 - 1.0". Decreasing the factor 
     tends to increase displayed bars (less selective.

  2. The Rising_period is set to "10".  Increasing the period tends to increase displayed bars 
     (less selective).  The Rising_Factor is set to "1.38".  A range of "1.38 - 1.62" is best. 
     Decreasing the factor tends to increase displayed bars (less selective).

When this indicator is used with the SonicR PV Histogram indicator, be sure all the settings 
are the same in both indicators!

                                                                    - Traderathome, 07-16-2011    
-----------------------------------------------------------------------------------------------
Acknowledgements:
BetterVolume.mq4 - for some core coding (BetterVolume_v1.4).

----------------------------------------------------------------------------------------------
Suggested Settings:         White Chart        Black Chart         Function

#property indicator_color1  C'33,201,83'       Lime                Climax Bull
#property indicator_color2  C'33,201,83'       Red                 Climax Bear
#property indicator_color3  C'0,0,244'         C'62,158,255'       Rising Bull             
#property indicator_color4  C'0,0,244'         C'62,158,255'       Rising Bear            
#property indicator_width1  2                  2
#property indicator_width2  2                  2
#property indicator_width3  2                  2
#property indicator_width4  2                  2           
---------------------------------------------------------------------------------------------*/


//+-------------------------------------------------------------------------------------------+
//| Indicator Global Inputs                                                                   |                                                        
//+-------------------------------------------------------------------------------------------+ 
#property indicator_chart_window
#property indicator_buffers 4
  
#property indicator_color1 Lime    
#property indicator_color2 Red 
#property indicator_color3 C'62,158,255'        
#property indicator_color4 C'62,158,255' 
#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2

//global external inputs
extern bool   Indicator_On                    = true;
extern bool   Show_Wide_Bars                  = false;
extern int    Wide_Bar_Width                  = 3;                       
extern bool   Show_Climax_Volume              = true;
extern bool   Show_Rising_Volume              = true;
extern int    Climax_Period                   = 20; 
extern double Climax_Factor                   = 1.0;  
extern int    Rising_Period                   = 10;
extern double Rising_Factor                   = 1.38; 
extern color  Volume_Climax_Bull              = Lime;
extern color  Volume_Climax_Bear              = Red;
extern color  Volume_Rising_Bull              = C'62,158,255';
extern color  Volume_Rising_Bear              = C'62,158,255';

//global buffers and variables 
bool   FLAG_deinit;  
int    va,i,j,n,shift1;
int    Volume_Rising_Width,Volume_Climax_Width; 
double Buffer1[];
double Buffer2[];
double Buffer3[];
double Buffer4[];
double av,Range,Value2,HiValue2,tempv2,open,close;

//+-------------------------------------------------------------------------------------------+
//| Indicator Initialization                                                                  |                                                        
//+-------------------------------------------------------------------------------------------+   
int init()
  {
  FLAG_deinit = false;
  
  if (Climax_Factor > 1) {Climax_Factor = 1;}
   
  Volume_Rising_Width= 2;
  Volume_Climax_Width= 2;
      
  if (Show_Wide_Bars)
    {
    Volume_Rising_Width= Wide_Bar_Width;
    Volume_Climax_Width= Wide_Bar_Width;
    }
    
  if (Show_Climax_Volume)
    {    
    SetIndexStyle(0,DRAW_HISTOGRAM, 0, Volume_Climax_Width, Volume_Climax_Bull);  
    SetIndexBuffer(0, Buffer1);
    SetIndexStyle(1,DRAW_HISTOGRAM, 0, Volume_Climax_Width, Volume_Climax_Bear);
    SetIndexBuffer(1, Buffer2);
    } 
     
  if (Show_Rising_Volume)
    {      
    SetIndexStyle(2,DRAW_HISTOGRAM, 0, Volume_Rising_Width, Volume_Rising_Bull);
    SetIndexBuffer(2, Buffer3);
    SetIndexStyle(3,DRAW_HISTOGRAM, 0, Volume_Rising_Width, Volume_Rising_Bear);   
    SetIndexBuffer(3, Buffer4);
    }
  
  
  
  return(0);
  }
  
//+-------------------------------------------------------------------------------------------+
//| Indicator De-initialization                                                               |                                                        
//+-------------------------------------------------------------------------------------------+ 
int deinit()
  {   
  return(0);   
  }
  
//+-------------------------------------------------------------------------------------------+
//| Indicator Start                                                                           |                                                        
//+-------------------------------------------------------------------------------------------+ 
int start()
  {
  //If indicator is "Off" deinitialize only once, not every tick.  
  if (!Indicator_On)    
    {
    if (!FLAG_deinit) {deinit(); FLAG_deinit = true;}
    return(0);
    }

  //Otherwise indicator is "On", so proceed.   
  deinit(); FLAG_deinit = false;
   
  //Count visible chart bars
  for(i = Bars-1-IndicatorCounted(); i >= 0; i--)        
    {
    //Clear buffers
    Buffer1[i] = 0;
    Buffer2[i] = 0;
    Buffer3[i] = 0;
    Buffer4[i] = 0;
    HiValue2   = 0; 
    tempv2     = 0;
    av = 0;
    va = 0;
                
    //Volume spread calculations                     
    Range = (High[i]-Low[i]);
    Value2 = Volume[i]*Range;                 
    for (n=i;n<i+Climax_Period;n++)
      {
      tempv2 = Volume[n]*((High[n]-Low[n])); 
      if (tempv2 >= HiValue2) {HiValue2 = tempv2;}    
      }             

    //Get average Volume     
    for (j = i; j < (i+Rising_Period); j++) av = av + Volume[j];
    av = av / Rising_Period;
            
    //Determine candle overlay color     
    if(Value2 >= HiValue2 * Climax_Factor) {va= 1;}
    else
      { 
      if (Volume[i] >= av * Rising_Factor) {va= 2;}   
      } 
             
    //Apply candle overlay color
    if (va==1)
      {
      Buffer1[i]=iClose(0,0,i);
      Buffer2[i]=iOpen(0,0,i);       
      }
    else if (va==2)
      {
      Buffer3[i]=iClose(0,0,i);
      Buffer4[i]=iOpen(0,0,i);      
       }
                                  
    }//End "for i" loop      
     
  return(0);
  }

//+-------------------------------------------------------------------------------------------+
//| Indicator End                                                                             |                                                        
//+-------------------------------------------------------------------------------------------+    