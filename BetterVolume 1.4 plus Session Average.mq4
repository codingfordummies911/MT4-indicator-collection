
#property copyright ""
#property link      ""

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_color1 FireBrick
#property indicator_color2 DimGray
#property indicator_color3 Khaki
#property indicator_color4 PaleGreen
#property indicator_color5 Bisque
#property indicator_color6 Violet
#property indicator_color7 BurlyWood
#property indicator_color8 BurlyWood

#property indicator_width1 2
#property indicator_width2 2
#property indicator_width3 2
#property indicator_width4 2
#property indicator_width5 2
#property indicator_width6 1
#property indicator_width7 1


extern int     NumberOfBars = 500;
extern string  Note  = "NumberOfBars must be greater than MAPeriod";
extern int     MAPeriod   = 20;
extern int     LookBack   = 40;
extern bool    UseSessionAverage = true;
extern int     AsiaBegin  = 17;   // Start time of Asian session in brokers time 
extern int     AsiaEnd    = 5;   // End time of Asian session in brokers time
extern int     EurBegin   = 3;   // Start time of European session in brokers time
extern int     EurEnd     = 12;   // End time of European session in brokers time
extern int     USABegin   = 8;   // Start time of New York session in brokers time
extern int     USAEnd     = 17;   // Endtime of New York session in brokers time


double red[],blue[],yellow[],green[],white[],magenta[],v4[], s4[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
      SetIndexBuffer(0,red);
      SetIndexStyle(0,DRAW_HISTOGRAM);
      SetIndexLabel(0,"Climax High ");
      
      SetIndexBuffer(1,blue);
      SetIndexStyle(1,DRAW_HISTOGRAM);
      SetIndexLabel(1,"Neutral");
      
      SetIndexBuffer(2,yellow);
      SetIndexStyle(2,DRAW_HISTOGRAM);
      SetIndexLabel(2,"Low ");
      
      SetIndexBuffer(3,green);
      SetIndexStyle(3,DRAW_HISTOGRAM);
      SetIndexLabel(3,"HighChurn ");
      
      SetIndexBuffer(4,white);
      SetIndexStyle(4,DRAW_HISTOGRAM);
      SetIndexLabel(4,"Climax Low ");
      
      SetIndexBuffer(5,magenta);
      SetIndexStyle(5,DRAW_HISTOGRAM);
      SetIndexLabel(5,"ClimaxChurn ");
      
      SetIndexBuffer(6,v4);
      SetIndexStyle(6,DRAW_LINE,0);
      SetIndexLabel(6,"Average("+MAPeriod+")");
      
      SetIndexBuffer(7,s4);
      SetIndexStyle(7,DRAW_LINE,STYLE_DOT,1);
      SetIndexLabel(7,"StdDev("+MAPeriod+")");
      IndicatorShortName("Better Volume 1.4 + Session Average" );
      

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
  
//----
   return(0);
  }
  

int Session(datetime dt )
{
   int session = 0;
   int hour = TimeHour(dt);
   if ( (hour >=AsiaBegin)  || ( (AsiaBegin>AsiaEnd) && (hour <= AsiaEnd)) )
   { 
      session = 1;
   }
   if ( (hour >=EurBegin) || ( (EurBegin>EurEnd) && ( hour <= EurEnd)) )
   {
      session = 2;
   }
   if ( (hour>=USABegin && hour>EurEnd)  || ( (USABegin>USAEnd) && (hour <= USAEnd)) )
   { 
      session = 3;
   }
   if (session==0) { Comment("Error - CurentSession()"); }
   return (session);

}

double CalculateAverageVolume(int bar)
{
   double av, v = 0;
   for (int i=bar; i<=bar+MAPeriod; i++)
   {
      v = iVolume(NULL,Period(),i);
      av = av+v;
   }   
   return(av/MAPeriod);
}

double CalculateSessionAverageVolume(int bar)
{
   double av, v = 0;
   int i, c = 0;
   i = bar;
   while (c<MAPeriod)
   {
      if ( Session(iTime(NULL,Period(),i)) == Session(iTime(NULL,Period(),bar)) )
      {
         v = iVolume(NULL,Period(),i);
         av = av+v;
         c++;
      }
      i++;
      if (i>(2*NumberOfBars)) { break;}
   }   
   return(av/MAPeriod);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
  
   double VolLowest,Range,Value2,Value3,HiValue2,HiValue3,LoValue3,tempv2,tempv3,tempv, tempsd;
   int limit;
   int counted_bars=IndicatorCounted();
//---- last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   if ( NumberOfBars == 0 ) 
      NumberOfBars = Bars-counted_bars;
   limit=NumberOfBars; //Bars-counted_bars;
   
      
   for(int i=0; i<limit; i++)   
   {
      red[i] = 0; blue[i] = Volume[i]; yellow[i] = 0; green[i] = 0; white[i] = 0; magenta[i] = 0;
      Value2=0;Value3=0;HiValue2=0;HiValue3=0;LoValue3=99999999;tempv2=0;tempv3=0;tempv=0;
      
      
      VolLowest = Volume[iLowest(NULL,0,MODE_VOLUME,20,i)];
      if (Volume[i] == VolLowest)
      {
         yellow[i] = NormalizeDouble(Volume[i],0);
         blue[i]=0;
      }
            
      Range = (High[i]-Low[i]);
      Value2 = Volume[i]*Range;
      
      if (  Range != 0 )
         Value3 = Volume[i]/Range;
         
      // average volume
      int n;
      if (UseSessionAverage) 
      { v4[i] = NormalizeDouble(CalculateSessionAverageVolume(i),0); }
      else
      { 
         v4[i] = NormalizeDouble(CalculateAverageVolume(i),0); 
      }
            
/*      // standard deviation
      tempsd = 0;
      for ( n=i;n<i+MAPeriod;n++ )
      {
         tempsd += NormalizeDouble(MathPow(Volume[n]-v4[n],2.0),0);
      }     
      s4[i] = NormalizeDouble(MathSqrt(tempsd/MAPeriod),0);  */
      
      // better volume categorisation 
      for ( n=i;n<i+LookBack;n++)
      {
         tempv2 = Volume[n]*((High[n]-Low[n])); 
         if ( tempv2 >= HiValue2 )
            HiValue2 = tempv2;
              
         if ( Volume[n]*((High[n]-Low[n])) != 0 )
         {           
            tempv3 = Volume[n] / ((High[n]-Low[n]));
            if ( tempv3 > HiValue3 ) 
               HiValue3 = tempv3; 
            if ( tempv3 < LoValue3 )
               LoValue3 = tempv3;
         } 
      }
                                   
      if ( Value2 == HiValue2  && Close[i] > (High[i] + Low[i]) / 2 )
      {
         red[i] = NormalizeDouble(Volume[i],0);
         blue[i]=0;
         yellow[i]=0;
      }   
         
      if ( Value3 == HiValue3 )
      {
         green[i] = NormalizeDouble(Volume[i],0);                
         blue[i] =0;
         yellow[i]=0;
         red[i]=0;
      }
      if ( Value2 == HiValue2 && Value3 == HiValue3 )
      {
         magenta[i] = NormalizeDouble(Volume[i],0);
         blue[i]=0;
         red[i]=0;
         green[i]=0;
         yellow[i]=0;
      } 
      if ( Value2 == HiValue2  && Close[i] <= (High[i] + Low[i]) / 2 )
      {
         white[i] = NormalizeDouble(Volume[i],0);
         magenta[i]=0;
         blue[i]=0;
         red[i]=0;
         green[i]=0;
         yellow[i]=0;
      }           
      
    }
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+