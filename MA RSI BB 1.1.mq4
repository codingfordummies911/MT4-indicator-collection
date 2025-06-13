#property indicator_separate_window
#property indicator_buffers 3
#property indicator_color1  clrAqua
#property indicator_color2  clrLimeGreen
#property indicator_color3  clrDodgerBlue
#property strict

//
//
//
//
//
 
extern int    MA_period   =  2;  // MA period
extern int    RSIPeriod   = 14;  // RSI period
extern int    Level_1     = 70;  // Level 1
extern int    Level_2     = 30;  // Level 2
extern int    BandsPeriod = 20;  // Bollinger period
extern double K_Dev       = 1.5; // Bollinger deviations

double RSIBuffer[];
double PosBuffer[];
double NegBuffer[];
double Up_Buffer[];
double MovingBuffer[];
double Dn_Buffer[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int init()
{
   IndicatorBuffers(5);
   SetIndexBuffer(0,Up_Buffer);
   SetIndexBuffer(1,Dn_Buffer);
   SetIndexBuffer(2,RSIBuffer);
   SetIndexBuffer(3,PosBuffer);
   SetIndexBuffer(4,NegBuffer);
      SetLevelValue(1, Level_1);
      SetLevelValue(2, Level_2);
      SetLevelValue(3, (Level_1+Level_2)/2);
   IndicatorShortName("MA_RSI_BB("+(string)MA_period+","+(string)RSIPeriod+","+(string)BandsPeriod+","+(string)K_Dev+")"); 
   return(0);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int start()
{
   int counted_bars=IndicatorCounted();
      if(counted_bars<0) return(-1);
      if(counted_bars>0) counted_bars--;
           int limit=MathMin(Bars-counted_bars,Bars-1); 

   //
   //
   //
   //
   //

   for(int i=limit; i>=0; i--)
   {
      if (i>=Bars-1) { PosBuffer[i] = 0; NegBuffer[i] = 0; continue; }
      
      //
      //
      //
      //
      //
      
         double rel = iMA(NULL, 0, MA_period, 0, MODE_SMMA, PRICE_CLOSE, i)-iMA(NULL, 0, MA_period, 0, MODE_SMMA, PRICE_CLOSE, i+1);
         double sumn=0.0,sump=0.0;
            if(rel>0) 
                  sump = rel;
            else  sumn =-rel;
         double positive=(PosBuffer[i+1]*(RSIPeriod-1)+sump)/RSIPeriod;
         double negative=(NegBuffer[i+1]*(RSIPeriod-1)+sumn)/RSIPeriod;

         PosBuffer[i] = positive;
         NegBuffer[i] = negative;
         if(negative==0.0) 
               RSIBuffer[i] = 0.0; 
         else  RSIBuffer[i] = 100.0-100.0/(1+positive/negative);
         
         //
         //
         //
         //
         //
         
         double sum=0.0;
         for (int k=0; k<BandsPeriod && (i+k)<Bars; k++)
         {
            double newres = RSIBuffer[i+k] - 50;
            sum += newres*newres;
         }
         double deviation=K_Dev*MathSqrt(sum/BandsPeriod);
            Up_Buffer[i]= 50 + deviation;
            Dn_Buffer[i]= 50 - deviation;
      }
   return(0);
}