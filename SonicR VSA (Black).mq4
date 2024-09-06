//+-------------------------------------------------------------------------------------------+
//|                                                                                           |
//|                                      SonicR VSA.mq4                                       |
//|                                                                                           |
//+-------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2011 traderathome"
#property link      "email:   traderathome@msn.com"

/*---------------------------------------------------------------------------------------------
Overview:

This indicator produces a multi-colored volume histogram.  The colors represent catagories of
volume described as follows: 
 
Green -  
Bar volume is of the highest activity over "Analysis_GoBack" period, and is for a bull candle.  
Activity is defined as bar volume*candle spread.

Red -  
Bar volume is of the highest activity over "Analysis_GoBack" period, and is for a bear candle.  
Activity is defined as bar volume*candle spread.

Blue -
Bar volume is >= the period average volume by the input volume factor.  For example, if the
period is 10 and the factor is 1.38, then any bar with volume that is >= 1.38 times the average
volume of the last 10 bars will be blue, if not already qualified as a green or red bar. 

Gray -
All other volume histogram bars are displayed.

This indicator includes a voice alert "Volume!" that will trigger one time per TF (TFs > M1) 
at the first qualification of the bar as green or red.  On M1 TFs multiple alerts can happen 
during the minute. 
                                        
The indicator can be turned on/off without having to remove it from the chart, preserving your
chart settings.  You can specify narrow or wide bars be displayed.  You can specify a range of 
time frames beyond which the indicator will not display.

The indicator ShortName in the study sub-window shows the numbers input for the "GoBack" time 
for candle analysis, the averaging period, and the volume factor.  The ShortName can be turned 
off to allow an unobstructed study when multiple small charts are simultaneously displayed in 
the MT4 main window. 

                                                                    - Traderathome, 05-15-2011 
-----------------------------------------------------------------------------------------------
Acknowledgements:
BetterVolume.mq4 - for some core coding (BetterVolume_v1.4).
     
-----------------------------------------------------------------------------------------------
Suggested Settings:         White Chart        Black Chart         Function

//---- Narrow Candles
#property indicator_color1  C'30,183,75'       Lime                ClimaxUp
#property indicator_color2  Crimson            Red                 ClimaxDn
#property indicator_color3  CornflowerBlue     C'62,158,255'       HiOverAvg
#property indicator_color4  LightGray          DimGray             VolumeBar
#property indicator_width1  2                  2
#property indicator_width2  2                  2
#property indicator_width3  2                  2
#property indicator_width4  2                  2           
#property indicator_width5  2                  2  
    
//---- Wide Candles
#property indicator_color5  C'30,183,75'       Lime                ClimaxUp  
#property indicator_color6  Crimson            Red                 ClimaxDn 
#property indicator_color7  CornflowerBlue     C'62,158,255'       HiOverAvg    
#property indicator_color8  LightGray          DimGray             VolumeBar   
#property indicator_width5  3                  3
#property indicator_width6  3                  3
#property indicator_width7  3                  3
#property indicator_width8  3                  3
                                                        
---------------------------------------------------------------------------------------------*/

#property indicator_separate_window
#property indicator_buffers 8

//---- Narrow Candles
#property indicator_color1  Lime        
#property indicator_color2  Red 
#property indicator_color3  C'62,158,255'         
#property indicator_color4  DimGray             
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_width4  2

//---- Wide Candles
#property indicator_color5  Lime         
#property indicator_color6  Red 
#property indicator_color7  C'62,158,255'         
#property indicator_color8  DimGray             
#property indicator_width5  3
#property indicator_width6  3
#property indicator_width7  3
#property indicator_width8  3

//Global External Inputs 
extern bool   Indicator_On                    = true;
extern int    Averaging_Period                = 10;
extern double Over_Average_Factor             = 1.38;
extern bool   Show_Narrow_vs_Wide_Bars        = true;
extern bool   Voice_Alert_On                  = false;
extern bool   Text_Alert_On                   = false;
extern bool   Show_Indicator_ShortName        = true;
extern int    Analysis_GoBack                 = 20;
extern int    Display_Min_TF                  = 1;
extern int    Display_Max_TF                  = 43200;
extern string TF_Choices_1                    = "M1 - H4 =  1, 5, 15, 30, 60, 240";
extern string TF_Choices_2                    = "D  W  M =  1440,  10080,  43200";

//Global Buffers & Other Inputs
bool          FLAG_deinit;
int           i,j,n;
double        ClimaxUp1[], ClimaxUp2[];
double        ClimaxDn1[], ClimaxDn2[];
double        HiOverAvg1[], HiOverAvg2[]; 
double        NormalBar1[], NormalBar2[];
double        avg,Range,Value2,HiValue2,tempv2;
datetime      dt1, dt2;

//+-------------------------------------------------------------------------------------------+
//| Custom indicator initialization function                                                  |
//+-------------------------------------------------------------------------------------------+
int init()
  {
  FLAG_deinit  = false;
  dt1 = iTime(NULL,0,1); dt2 = dt1;
  
  //Indicators
  if(Show_Narrow_vs_Wide_Bars)
    {       
    SetIndexBuffer(0, ClimaxUp1);   
    SetIndexStyle(0, DRAW_HISTOGRAM);  
    SetIndexBuffer(1, ClimaxDn1);   
    SetIndexStyle(1, DRAW_HISTOGRAM);   
    SetIndexBuffer(2, HiOverAvg1);  
    SetIndexStyle(2, DRAW_HISTOGRAM);
    SetIndexBuffer(3, NormalBar1);  
    SetIndexStyle(3, DRAW_HISTOGRAM);        
    }
    else
    {
    SetIndexBuffer(4, ClimaxUp2);   
    SetIndexStyle(4, DRAW_HISTOGRAM);  
    SetIndexBuffer(5, ClimaxDn2);   
    SetIndexStyle(5, DRAW_HISTOGRAM);     
    SetIndexBuffer(6, HiOverAvg2);  
    SetIndexStyle(6, DRAW_HISTOGRAM); 
    SetIndexBuffer(7, NormalBar2);  
    SetIndexStyle(7, DRAW_HISTOGRAM);            
    }   
  
  //Indicator subwindow data labels     
  SetIndexLabel(0,  NULL);
  SetIndexLabel(1,  NULL); 
  SetIndexLabel(2,  NULL);
  SetIndexLabel(3,  NULL);
  SetIndexLabel(4,  NULL);
  SetIndexLabel(5,  NULL);
  SetIndexLabel(6,  NULL);
  SetIndexLabel(7,  NULL);  
      
  return(0);
  }
  
//+-------------------------------------------------------------------------------------------+
//| Custom indicator deinitialization function                                                |
//+-------------------------------------------------------------------------------------------+
int deinit()
  {
  //Comment("");
  return(0);
  }
  
//+-------------------------------------------------------------------------------------------+
//| Custom indicator iteration function                                                       |
//+-------------------------------------------------------------------------------------------+
int start()
  {
  //If Indicator is "Off" deinitialize only once, not every tick------------------------------  
  if ((!Indicator_On) || (Period() < Display_Min_TF) || (Period() > Display_Max_TF))
    {
    if (Show_Indicator_ShortName) 
      {
      IndicatorShortName("SonicR VSA  ("+Analysis_GoBack+", "+Averaging_Period+", "+
      DoubleToStr(Over_Average_Factor,2)+")  -off.   ");
      }  
    else {IndicatorShortName("");}
    if (!FLAG_deinit) {deinit(); FLAG_deinit = true;}
    return(0);
    }  
             
  for(i = Bars-1-IndicatorCounted(); i >= 0; i--)       
    {            
    //Clear buffers                         
    ClimaxUp1[i]  = 0; 
    ClimaxUp2[i]  = 0;           
    ClimaxDn1[i]  = 0; 
    ClimaxDn2[i]  = 0;                     
    HiOverAvg1[i] = 0;                                 
    HiOverAvg2[i] = 0; 
    NormalBar1[i] = Volume[i];
    NormalBar2[i] = Volume[i];
    Value2        = 0;
    HiValue2      = 0;
    tempv2        = 0;
            
    //Compute Average Volume
    avg = 0;
    for (j = i; j < (i+Averaging_Period); j++) {avg = avg + Volume[j];}   
    avg = avg / Averaging_Period;     
               
    //Input average and current volume into ShortName
    if (Show_Indicator_ShortName)
      {      
      if((!Voice_Alert_On) && (!Text_Alert_On))
        {
        IndicatorShortName("SonicR VSA  ("+Analysis_GoBack+", "+Averaging_Period+", "+
        DoubleToStr(Over_Average_Factor,2)+")   Voice & Text Alerts off.   "); 
        }
      else {if((Voice_Alert_On) && (!Text_Alert_On))
        {
        IndicatorShortName("SonicR VSA  ("+Analysis_GoBack+", "+Averaging_Period+", "+
        DoubleToStr(Over_Average_Factor,2)+")   Voice Alert On, Text Alert off.   "); 
        }
      else {if((!Voice_Alert_On) && (Text_Alert_On))
        {
        IndicatorShortName("SonicR VSA  ("+Analysis_GoBack+", "+Averaging_Period+", "+
        DoubleToStr(Over_Average_Factor,2)+")   Voice Alert Off, Text Alert on.   ");
        }
      else {if((Voice_Alert_On) && (Text_Alert_On))
        {
        IndicatorShortName("SonicR VSA  ("+Analysis_GoBack+", "+Averaging_Period+", "+
        DoubleToStr(Over_Average_Factor,2)+")   Voice & Text Alerts on.   ");               
        } }}}
      }                                                  
    else                                 
      {
      IndicatorShortName("");
      }  
        
    //Calculations necessary for candles                 
    Range = (High[i]-Low[i]);
    Value2 = Volume[i]*Range;                 
    for (n=i;n<i+Analysis_GoBack;n++)
      {
      tempv2 = Volume[n]*((High[n]-Low[n])); 
      if (tempv2 >= HiValue2) {HiValue2 = tempv2;}    
      }
      
    if(Show_Narrow_vs_Wide_Bars)
      {
      if(Value2 == HiValue2)
        { 
        //ClimaxUp                                  
        if (Close[i] > Open[i]) 
          {
          ClimaxUp1[i] = NormalizeDouble(Volume[i],0);
          }
        //ClimaxDn  
        else if (Close[i] <= Open[i]) 
          {
          ClimaxDn1[i] = NormalizeDouble(Volume[i],0);
          }
        NormalBar1[i] = 0;
        //Voice & Text Alert
        if((Voice_Alert_On) || (Text_Alert_On))
          {  
          if((dt2 != iTime(NULL,0,0)) && (i == 0))         
            {        
            dt2 = iTime(NULL,0,0);
            if(Voice_Alert_On) {PlaySound("vol_alert.wav");}
            if(Text_Alert_On) {Alert (Symbol()+", TF "+Period()+", volume alert!");}           
            }
          }                  
        }                          
      //Volume high over average                       
      else if (Volume[i] >= avg * Over_Average_Factor)
        {
        HiOverAvg1[i] = NormalizeDouble(Volume[i],0);                
        NormalBar1[i] = 0;          
        }              
      }
               
    else
      {
      if(Value2 == HiValue2)
        { 
        //ClimaxUp                                  
        if (Close[i] > Open[i]) 
          {
          ClimaxUp2[i] = NormalizeDouble(Volume[i],0);
          }
        //ClimaxDn  
        else if (Close[i] <= Open[i]) 
          {
          ClimaxDn2[i] = NormalizeDouble(Volume[i],0);
          }
        NormalBar2[i] = 0;
        //Voice & Text Alert
        if((Voice_Alert_On) || (Text_Alert_On))
          {  
          if((dt2 != iTime(NULL,0,0)) && (i == 0))         
            {        
            dt2 = iTime(NULL,0,0);
            if(Voice_Alert_On) {PlaySound("vol_alert.wav");}
            if(Text_Alert_On) {Alert (Symbol()+", TF "+Period()+", volume alert!");}           
            }
          }  
        }                          
      //Volume high over average                 
      else if (Volume[i] >= avg * Over_Average_Factor)
        {
        HiOverAvg2[i] = NormalizeDouble(Volume[i],0);                
        NormalBar2[i] = 0;
        }                 
      }
                  
    }//End of "for" loop    
    
  return(0);
  }

//+-------------------------------------------------------------------------------------------+
//|Custom indicator end                                                                       |
//+-------------------------------------------------------------------------------------------+    
         