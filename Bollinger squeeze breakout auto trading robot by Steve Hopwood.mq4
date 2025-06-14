//+-------------------------------------------------------------------+
//|Bollinger squeeze breakout auto trading robot by Steve Hopwood.mq4 |
//|                                  Copyright © 2009, Steve Hopwood  |
//|                              http://www.hopwood3.freeserve.co.uk  |
//+-------------------------------------------------------------------+
#property copyright "Copyright © 2009, Steve Hopwood"
#property link      "http://www.hopwood3.freeserve.co.uk"
#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  NL    "\n"
#define  upperguidelinename "Upper guide line"
#define  lowerguidelinename "Lower guide line"



/*

----Trading----

void LookForTradingOpportunities()
bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
bool DoesTradeExist()
bool CloseTrade(ticket)
void LookForTradeClosure()

----Indicator readings----
void ReadIndicatorValues()
void GetBB(int shift)
void DrawGuideLines()
void CheckForSqueeze()


*/

extern string  gen="----General inputs----";
extern double  Lot=0.01;
extern int     TakeProfit=100;
extern int     MagicNumber=3865003;
extern string  TradeComment="BB squeeze";
extern bool    CriminalIsECN=false;
extern string  bbi="----Bollinger Band inputs----";
extern int     BbPeriod=25;
extern int     BbDeviation=2;
extern int     BbMaxSqueezeExtent=250;
extern int     BbLookBackBars=5;
extern color   BbGuidelinesColour=Yellow;
extern string  mis="----Odds and ends----";
extern int     DisplayGapSize=30;
extern bool    AlwaysDisplayBbValues=false;


//Trading variables
int            TicketNo;

//BB variables
double         BbUpper, BbMiddle, BbLower, BbExtent;
bool           SqueezeStatus;

//Misc
string         Gap, ScreenMessage;
int            OldBars;

void DisplayUserFeedback()
{
   
   if (IsTesting() && !IsVisualMode()) return;

   ScreenMessage = "";
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, NL);
   //Code for time to bar-end display from Candle Time by Nick Bilak
   double i;
   int m,s,k;
   m=Time[0]+Period()*60-CurTime();
   i=m/60.0;
   s=m%60;
   m=(m-m%60)/60;
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, m + " minutes " + s + " seconds left to bar end", NL);

   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "BB Upper line: ", DoubleToStr(BbUpper, Digits), NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "BB Middle line: ", DoubleToStr(BbMiddle, Digits), NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "BB Lower line: ", DoubleToStr(BbLower, Digits), NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "BB Lower line: ", DoubleToStr(BbLower, Digits), NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "BbMaxSqueezeExtent = ", BbMaxSqueezeExtent, NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "BbLookBackBars = ", BbLookBackBars, NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "BB jaws width = ", BbExtent, NL);
   if (SqueezeStatus == true) ScreenMessage = StringConcatenate(ScreenMessage,Gap, "Bands are in a squeeze", NL);
   else ScreenMessage = StringConcatenate(ScreenMessage,Gap, "Not a tradable squeeze", NL);
      
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, NL);      
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "Lot size: ", Lot, NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "Take profit: ", TakeProfit, " pips",  NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "Magic number: ", MagicNumber, NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "Trade comment: ", TradeComment, NL);
   if (CriminalIsECN) ScreenMessage = StringConcatenate(ScreenMessage,Gap, "CriminalIsECN = true", NL);
   else ScreenMessage = StringConcatenate(ScreenMessage,Gap, "CriminalIsECN = false", NL);
   ScreenMessage = StringConcatenate(ScreenMessage,Gap, "Criminal's minimum lot size: ", MarketInfo(Symbol(), MODE_MINLOT), NL, NL );
   
   Comment(ScreenMessage);


}//void DisplayUserFeedback()


//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
//----

   //Adapt to x digit criminals
   int multiplier;
   if(Digits == 2 || Digits == 4) multiplier = 1;
   if(Digits == 3 || Digits == 5) multiplier = 10;
   if(Digits == 6) multiplier = 100;   
   if(Digits == 7) multiplier = 1000;   
   
   TakeProfit*= multiplier;
   BbMaxSqueezeExtent*= multiplier;


   Gap="";
   if (DisplayGapSize >0)
   {
      for (int cc=0; cc< DisplayGapSize; cc++)
      {
         Gap = StringConcatenate(Gap, " ");
      }   
   }//if (DisplayGapSize >0)
   

   OldBars = Bars;
   ReadIndicatorValues();//For initial display in case user has turned of constant re-display
   DisplayUserFeedback();
   
   
//----
   return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
//----
   Comment("");
//----
   return(0);
}

void GetBB(int shift)
{
   //Reads BB figures into BbUpper, BbMiddle, BbLower
   
   
   BbUpper = iBands(NULL, 0, BbPeriod, BbDeviation, 0, PRICE_OPEN, MODE_UPPER, shift);
   BbLower = iBands(NULL, 0, BbPeriod, BbDeviation, 0, PRICE_OPEN, MODE_LOWER, shift);
   BbMiddle = iBands(NULL, 0, BbPeriod, BbDeviation, 0, PRICE_OPEN, MODE_MAIN, shift);
   
   BbExtent = BbUpper - BbLower;
   
}//void GetBb(int shift)

bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
{
   
   //if (StopTrading) return(true);
   /*
   if (!IsTesting())
   {   
      if (!IsTradeAllowed() ) return(false);
      if (!IsConnected() ) return(false);
      if (!IsExpertEnabled() ) return(false);
      if (!IsTradeContextBusy() ) return(false);
   }//if (!IsTesting)
   */
   
   int slippage = 10;
   if (Digits == 3 || Digits == 5) slippage = 100;
   
   color col = Red;
   if (type == OP_BUY) col = Green;
   
   if (!CriminalIsECN) int ticket = OrderSend(Symbol(),type, lotsize, price, slippage, stop, take, comment, MagicNumber, 0, col);
   
   
   //Is a 2 stage criminal
   if (CriminalIsECN)
   {
      ticket = OrderSend(Symbol(),type, lotsize, price, slippage, 0, 0, comment, MagicNumber, 0, col);
	   if (stop != 0)
	   {
		   if (ticket > 0)
		   bool result = OrderModify(ticket, OrderOpenPrice(), stop, take, 0, CLR_NONE);
		   if (!result)
		   {
		       int err=GetLastError();
             Print(Symbol(), " ", type," SL  order modify failed with error(",err,"): ",ErrorDescription(err));               
		   }//if (!result)			  
	   }//if (Sl != 0)
      
      
   }//if (CriminalIsECN)
   
   //Error trapping for both
   if (ticket < 0)
   {
      string stype;
      if (type == OP_BUY) stype = "OP_BUY";
      if (type == OP_SELL) stype = "OP_SELL";
      err=GetLastError();
      Alert(Symbol(), " ", stype," Nanningbob order send failed with error(",err,"): ",ErrorDescription(err));
      Print(Symbol(), " ", stype," Nanningbob order send failed with error(",err,"): ",ErrorDescription(err));
      return(false);
   }//if (ticket < 0)  
   
   //Got this far, so trade send succeeded
   return(true);
   
}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)

bool DoesTradeExist()
{
   
   TicketNo = 0;
   
   if (OrdersTotal() == 0) return(false);
   
   for (int cc = OrdersTotal() - 1; cc >= 0 ; cc--)
   {
      if (!OrderSelect(cc,SELECT_BY_POS)) continue;
      
      if (OrderMagicNumber()==MagicNumber && OrderSymbol() == Symbol() )      
      {
         TicketNo = OrderTicket();
         return(true);         
      }//if (OrderMagicNumber()==MagicNumber && OrderSymbol() == Symbol() )      
   }//for (int cc = OrdersTotal() - 1; cc >= 0 ; cc--)

   return(false);

}//End bool DoesTradeExist()

void LookForTradingOpportunities()
{


   RefreshRates();
   double take;
   

   //Long 
   if (Ask > BbUpper)
   {
      if (TakeProfit > 0) take = NormalizeDouble(Ask + (TakeProfit * Point), Digits);
      bool result = SendSingleTrade(OP_BUY, TradeComment, Lot, Ask, BbMiddle, take);
      if (!result) OldBars = 0;
   }//if (Ask > BbUpper)
   

   //Short
   if (Bid < BbLower)
   {
      if (TakeProfit > 0) take = NormalizeDouble(Bid - (TakeProfit * Point), Digits);
      result = SendSingleTrade(OP_SELL, TradeComment, Lot, Bid, BbMiddle, take);
      if (!result) OldBars = 0;
   }//if (Ask > BbUpper)
   


}//void LookForTradingOpportunities()

bool CloseTrade(int ticket)
{
   bool result = OrderClose(ticket, OrderLots(), OrderClosePrice(), 1000, CLR_NONE);

}//End bool CloseTrade(ticket)

void CheckForSqueeze()
{
   SqueezeStatus = true;
   
   for (int cc = 1; cc < BbLookBackBars; cc++)
   {
      GetBB(cc);
      if (BbExtent > (BbMaxSqueezeExtent * Point) )
      {
         SqueezeStatus = false;
         return;
      }
   }//for (int cc = 1; cc < BbLookBackBars; cc++)
   

}//void CheckForSqueeze()

void DrawGuideLines()
{

      if (ObjectFind(upperguidelinename) > -1) ObjectDelete(upperguidelinename);   
      if (ObjectFind(lowerguidelinename) > -1) ObjectDelete(lowerguidelinename);   
      
      ObjectCreate(upperguidelinename,OBJ_HLINE,0,TimeCurrent(),NormalizeDouble(BbMiddle + ((BbMaxSqueezeExtent * Point) / 2), Digits) );      
      ObjectSet(upperguidelinename,OBJPROP_COLOR,BbGuidelinesColour);
      ObjectSet(upperguidelinename,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSet(upperguidelinename,OBJPROP_WIDTH,1);     

   
      ObjectCreate(lowerguidelinename,OBJ_HLINE,0,TimeCurrent(),NormalizeDouble(BbMiddle - ((BbMaxSqueezeExtent * Point) / 2), Digits) );      
      ObjectSet(lowerguidelinename,OBJPROP_COLOR,BbGuidelinesColour);
      ObjectSet(lowerguidelinename,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSet(lowerguidelinename,OBJPROP_WIDTH,1);     

   
}//void DrawGuideLines()


void ReadIndicatorValues()
{

   CheckForSqueeze();
   GetBB(0);//Bollinger Bands
   DrawGuideLines();
   
}//void ReadIndicatorValues()

void LookForTradeClosure()
{
   //Close the trade if the new candle opens inside the bands
   
   if (!OrderSelect(TicketNo, SELECT_BY_TICKET) ) return;
   
   if (OrderType() == OP_BUY)
   {
      if (Ask < BbUpper)
      {
         bool result = CloseTrade(TicketNo);
         if (!result) OldBars = 0;         
      }//if (Ask < BbUpper)      
   }//if (OrderType() == OP_BUY)
   
   
   if (OrderType() == OP_SELL)
   {
      if (Bid > BbLower)
      {
         result = CloseTrade(TicketNo);
         if (!result) OldBars = 0;         
      }//if (Bid > BbLower)
   }//if (OrderType() == OP_SELL)
   
   
   
}//void LookForTradeClosure()

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
//----

   if (OrdersTotal() == 0)
   {
      TicketNo = 0;
   }//if (OrdersTotal() == 0)


   if (AlwaysDisplayBbValues) 
   {
      ReadIndicatorValues();
      DisplayUserFeedback();
   }//if (AlwaysDisplayBbValues) 
   
   if (OldBars != Bars)
   {
      
      OldBars = Bars;
      
      ///////////////////////////////////////////////////////////////////////////////////////////////
      //Find open trades
      if (OrdersTotal() > 0)
      {
         if (DoesTradeExist() )
         {
            LookForTradeClosure();
         }//if (DoesTradeExist() )                  
      }//if (OrdersTotal() > 0)
   
      ///////////////////////////////////////////////////////////////////////////////////////////////
   
    
      ///////////////////////////////////////////////////////////////////////////////////////////////         
      //Trading
      if (TicketNo == 0)
      {
         LookForTradingOpportunities();
      }//if (TicketNo == 0)
      ///////////////////////////////////////////////////////////////////////////////////////////////      
   
      DisplayUserFeedback();
   }//if (OldBars != Bars)
   
//----
   return(0);
}
//+------------------------------------------------------------------+