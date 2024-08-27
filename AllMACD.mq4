//+------------------------------------------------------------------+
//|                                                     All MACD.mq4 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright   "mladen"
#property link        ""
#define indicatorName "All MACD"

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_color1  Green
#property indicator_color2  Green
#property indicator_color3  Red
#property indicator_color4  Red
#property indicator_color5  Gray
#property indicator_color6  Gold
#property indicator_width1  2
#property indicator_width3  2


//---- input parameters
//
//
//
//
//

extern int    FastEMA              = 12;
extern int    SlowEMA              = 26;
extern int    Signal               =  9;
extern int    PriceField           =  0;
extern string __                   = "Chose timeframes";
extern string timeFrames           = "M1;M5;M15;M30;H1;H4;D1;W1;MN";
extern int    barsPerTimeFrame     = 35;
extern bool   shiftRight           = False;
extern bool   currentFirst         = True; 
extern bool   equalize             = True;
extern color  txtColor             = Silver; 
extern color  separatorColor       = DimGray; 

//---- buffers
//
//
//
//
//

double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double ExtMapBuffer5[];
double ExtMapBuffer6[];
double ExtMapBuffer7[];

//
//
//
//
//

int    Shift; 
int    limit;
int    window;  
int    periods[];
string labels[];
string shortName;
double minValue;
double maxValue;
double maxValues[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int init()
{
      IndicatorBuffers(7);
      SetIndexBuffer(0,ExtMapBuffer1);
      SetIndexBuffer(1,ExtMapBuffer2);
      SetIndexBuffer(2,ExtMapBuffer3);
      SetIndexBuffer(3,ExtMapBuffer4);
      SetIndexBuffer(4,ExtMapBuffer5);
      SetIndexBuffer(5,ExtMapBuffer6);
      SetIndexBuffer(6,ExtMapBuffer7);
      SetIndexStyle(0,DRAW_HISTOGRAM);
      SetIndexStyle(1,DRAW_HISTOGRAM);
      SetIndexStyle(2,DRAW_HISTOGRAM);
      SetIndexStyle(3,DRAW_HISTOGRAM);
      SetIndexStyle(6,DRAW_NONE);
   
      //
      //
      //
      //
      //
      
      timeFrames = StringTrimLeft(StringTrimRight(timeFrames));
         if (StringSubstr(timeFrames,StringLen(timeFrames),1) != ";")
                          timeFrames = StringConcatenate(timeFrames,";");

         //
         //
         //
         //
         //                                   
            
         int s = 0;
         int i = StringFind(timeFrames,";",s);
         int time;
         string current;
            while (i > 0)
            {
               current = StringSubstr(timeFrames,s,i-s);
               time    = stringToTimeFrame(current);
               if (time > 0) {
                     ArrayResize(labels ,ArraySize(labels)+1);
                     ArrayResize(periods,ArraySize(periods)+1);
                                 labels[ArraySize(labels)-1] = TimeFrameToString(time); 
                                 periods[ArraySize(periods)-1] = time; }
                                 s = i + 1;
                                     i = StringFind(timeFrames,";",s);
            }

      //
      //
      //
      //
      //
   
         if (shiftRight) Shift  = 1;
         else            Shift  = 0;
               limit            = ArraySize(periods);
               barsPerTimeFrame = MathMax(barsPerTimeFrame,30);      
         for (i=0;i<7;i++)  SetIndexShift(i,Shift*(barsPerTimeFrame+1));
      
      //
      //
      //
      //
      //

      if(currentFirst)
      for (i=1;i<limit;i++)
         if (Period()==periods[i])
            {
               string tmpLbl = labels[i];
               int    tmpPer = periods[i];
               
               //
               //
               //
               //
               //
               
               for (int k=i ;k>0; k--)
                     {
                        labels[k]  = labels[k-1];
                        periods[k] = periods[k-1];
                     }                     
               labels[0]  = tmpLbl;
               periods[0] = tmpPer;
            }
      //
      //
      //
      //
      //
   
      shortName = indicatorName+" ("+FastEMA+","+SlowEMA+","+Signal+")";
      IndicatorShortName(shortName);
   return(0);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
{
   for(int l=0;l<limit;l++) {
         ObjectDelete(indicatorName+window+l);
         ObjectDelete(indicatorName+window+l+"label");
      }         
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

int start()
{
   static bool init = false;
   double koef = 1.0;
   double max;
   string on;
   int    k=0;


   //
   //
   //
   //
   //

   if (!init) {
        init      = true;
        window    = WindowFind(shortName);  
        shortName = indicatorName+window+" ("+FastEMA+","+SlowEMA+","+Signal+")";
            IndicatorShortName(shortName);
            
            //
            //
            //
            //
            //
            
            ArrayResize(maxValues,limit);
     }            
     ArrayInitialize(maxValues,0);

     //
     //
     //
     //
     //
         
            minValue =  999999;
            maxValue = -999999;
            for(int p=0; p<limit;p++)
                  {
                     for(int i=0; i<barsPerTimeFrame;i++,k++)
                           {
                              ExtMapBuffer7[k] = iMACD(NULL,periods[p],FastEMA,SlowEMA,Signal,PriceField,0,i);
                              ExtMapBuffer6[k] = iMACD(NULL,periods[p],FastEMA,SlowEMA,Signal,PriceField,1,i);
                                    checkMinMax(k,p);
                           }
                           ExtMapBuffer1[k] = EMPTY_VALUE;
                           ExtMapBuffer2[k] = EMPTY_VALUE;
                           ExtMapBuffer3[k] = EMPTY_VALUE;
                           ExtMapBuffer4[k] = EMPTY_VALUE;
                           ExtMapBuffer5[k] = EMPTY_VALUE;
                           ExtMapBuffer6[k] = EMPTY_VALUE;
                           ExtMapBuffer7[k] = EMPTY_VALUE;
                           k += 1;
                           
                           //
                           //
                           //
                           //
                           //
                           
                           on = indicatorName+window+p;
                           if(ObjectFind(on)==-1)
                              ObjectCreate(on,OBJ_TREND,window,0,0);
                              ObjectSet(on,OBJPROP_TIME1,myTime(k-Shift*(barsPerTimeFrame+1)-1));
                              ObjectSet(on,OBJPROP_TIME2,myTime(k-Shift*(barsPerTimeFrame+1)-1));
                              ObjectSet(on,OBJPROP_COLOR ,separatorColor);
                              ObjectSet(on,OBJPROP_WIDTH ,2);
                           on = indicatorName+window+p+"label";
                           if(ObjectFind(on)==-1)
                              ObjectCreate(on,OBJ_TEXT,window,0,0);
                              ObjectSet(on,OBJPROP_TIME1,myTime(k-Shift*(barsPerTimeFrame+1)-6));
                              ObjectSetText(on,labels[p],9,"Arial",txtColor);
                  }
         k = 0;

         //
         //
         //
         //
         //               

         if (equalize) for (i=0; i<limit; i++) if (max < maxValues[i]) max = maxValues[i];
         for(p=0; p<limit;p++)
            {
               on = indicatorName+window+p;
                  ObjectSet(on,OBJPROP_PRICE1,maxValue);
                  ObjectSet(on,OBJPROP_PRICE2,minValue);
               on = indicatorName+window+p+"label";
                  ObjectSet(on,OBJPROP_PRICE1,maxValue);            
               if (equalize) koef = max/maxValues[p];

               //
               //
               //
               //
               //

               for(i=0; i<barsPerTimeFrame;i++,k++)
               {
                  ExtMapBuffer5[k] = ExtMapBuffer7[k]*koef;
                  ExtMapBuffer6[k] = ExtMapBuffer6[k]*koef;
                  
                  //
                  //
                  //
                  //
                  //
                  
                  if (ExtMapBuffer7[k] >= 0)
                     {
                        ExtMapBuffer3[k] = EMPTY_VALUE;
                        ExtMapBuffer4[k] = EMPTY_VALUE;
                        if (ExtMapBuffer7[k] >= ExtMapBuffer7[k+1])    {
                              ExtMapBuffer1[k]= ExtMapBuffer7[k]*koef;
                              ExtMapBuffer2[k]= EMPTY_VALUE;           }    
                        else {ExtMapBuffer2[k] = ExtMapBuffer7[k]*koef;
                              ExtMapBuffer1[k] = EMPTY_VALUE;          }                          
                     }                  
                  else
                     {               
                        ExtMapBuffer1[k] = EMPTY_VALUE;
                        ExtMapBuffer2[k] = EMPTY_VALUE;
                        if (ExtMapBuffer7[k] < ExtMapBuffer7[k+1])     {                        
                              ExtMapBuffer3[k] = ExtMapBuffer7[k]*koef;
                              ExtMapBuffer4[k] = EMPTY_VALUE;          }
                        else {ExtMapBuffer4[k] = ExtMapBuffer7[k]*koef;
                              ExtMapBuffer3[k] = EMPTY_VALUE;          }
                      }                  
               }                   
               k += 1;
            }                  

      //
      //
      //
      //
      //
      
      for (i=0;i<7;i++) SetIndexDrawBegin(i,Bars-k);
   return(0);
}


//+------------------------------------------------------------------+
//+                                                                  +
//+------------------------------------------------------------------+

void checkMinMax(int shift,int period)
{
   double tmpMin;
   double tmpMax;
   
   tmpMin = MathMin(ExtMapBuffer7[shift],ExtMapBuffer6[shift]);
   tmpMax = MathMax(ExtMapBuffer7[shift],ExtMapBuffer6[shift]);
            minValue = MathMin(tmpMin,minValue);
            maxValue = MathMax(tmpMax,maxValue);
            maxValues[period] = MathMax(maxValues[period],MathMax(MathAbs(tmpMin),MathAbs(tmpMax)));
}

//
//
//
//
//

int myTime(int a)
{
   if(a<0)
         return(Time[0]+Period()*60*MathAbs(a));
   else  return(Time[a]);   
}


//+------------------------------------------------------------------+
//+                                                                  +
//+------------------------------------------------------------------+
//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   int tf=0;
       tfs = StringUpperCase(tfs);
       
         if (tfs=="M1" || tfs=="1")     tf=PERIOD_M1;
         if (tfs=="M5" || tfs=="5")     tf=PERIOD_M5;
         if (tfs=="M15"|| tfs=="15")    tf=PERIOD_M15;
         if (tfs=="M30"|| tfs=="30")    tf=PERIOD_M30;
         if (tfs=="H1" || tfs=="60")    tf=PERIOD_H1;
         if (tfs=="H4" || tfs=="240")   tf=PERIOD_H4;
         if (tfs=="D1" || tfs=="1440")  tf=PERIOD_D1;
         if (tfs=="W1" || tfs=="10080") tf=PERIOD_W1;
         if (tfs=="MN" || tfs=="43200") tf=PERIOD_MN1;
         
   return(tf);
}
string TimeFrameToString(int tf)
{
   string tfs="Current time frame";
   switch(tf) {
      case PERIOD_M1:  tfs="M1"  ; break;
      case PERIOD_M5:  tfs="M5"  ; break;
      case PERIOD_M15: tfs="M15" ; break;
      case PERIOD_M30: tfs="M30" ; break;
      case PERIOD_H1:  tfs="H1"  ; break;
      case PERIOD_H4:  tfs="H4"  ; break;
      case PERIOD_D1:  tfs="D1"  ; break;
      case PERIOD_W1:  tfs="W1"  ; break;
      case PERIOD_MN1: tfs="MN";
   }
   return(tfs);
}

//
//
//
//
//

string StringUpperCase(string str)
{
   string   s = str;
   int      lenght = StringLen(str) - 1;
   int      char;
   
   while(lenght >= 0)
      {
         char = StringGetChar(s, lenght);
         
         //
         //
         //
         //
         //
         
         if((char > 96 && char < 123) || (char > 223 && char < 256))
                  s = StringSetChar(s, lenght, char - 32);
          else 
              if(char > -33 && char < 0)
                  s = StringSetChar(s, lenght, char + 224);
                  
         //
         //
         //
         //
         //
                                 
         lenght--;
   }
   
   //
   //
   //
   //
   //
   
   return(s);
}