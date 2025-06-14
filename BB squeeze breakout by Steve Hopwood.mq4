//+------------------------------------------------------------------+
//|                                #1 BUY 25 BB by Steve Hopwood.mq4 |
//|                                  Copyright © 2010, Steve Hopwood |
//|                              http://www.hopwood3.freeserve.co.uk |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, Steve Hopwood"
#property link      "http://www.hopwood3.freeserve.co.uk"
#include <WinUser32.mqh>
#include <stdlib.mqh>
#define  buy "Buy"
#define  sell "Sell"

/*
bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)
bool DoesTradeExist()

*/

extern double  Lot=0.01;
extern int     MagicNumber=999;
extern string  TradeComment="BB squeeze breakout";
extern bool    CriminalIsECN=true;
extern bool    UseSafetyFeature=true;
extern bool    TradeLong=true;
extern bool    TradeShort=true;
extern string  tpi="----Take profit and stop loss inputs----";
extern int     TakeProfit=100;



double         BbUpper, BbLower, BbMiddle;
bool           RobotSuspended;
int            OldBars;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
//----


   //Accommodate different quote sizes
   double multiplier;
   if(Digits == 2 || Digits == 4) multiplier = 1;
   if(Digits == 3 || Digits == 5) multiplier = 10;
   if(Digits == 6) multiplier = 100;   
   TakeProfit*= multiplier;
   
   if (UseSafetyFeature)
   {
      
      int retval = MessageBox(Symbol() + ": do you wish to continue to use this robot?", "Question", MB_YESNO|MB_ICONQUESTION);
      if (retval == IDNO) RobotSuspended = true;
      else RobotSuspended = false;   
   }//if (UseSafetyFeature)
   
   if (TradeComment == "") TradeComment = " ";

   OldBars = Bars;
   
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
   if (type == OP_BUY || type == OP_BUYSTOP) col = Green;
   
   int expiry = 0;
   //if (SendPendingTrades) expiry = TimeCurrent() + (PendingExpiryMinutes * 60);
   
   
   
   if (!CriminalIsECN) int ticket = OrderSend(Symbol(),type, lotsize, price, slippage, stop, take, comment, MagicNumber, expiry, col);
   
   
   //Is a 2 stage criminal
   if (CriminalIsECN)
   {
      ticket = OrderSend(Symbol(),type, lotsize, price, slippage, 0, 0, comment, MagicNumber, expiry, col);
	   if (ticket > -1)
      {
         if (stop >0 && take > 0) bool result = OrderModify(OrderTicket(), OrderOpenPrice(), stop, take, OrderExpiration(), CLR_NONE);
         //Stop loss but no take profit
         if (stop >0 && take == 0) result = OrderModify(OrderTicket(), OrderOpenPrice(), stop, OrderTakeProfit(), OrderExpiration(), CLR_NONE);
         //Take profit but no stop loss
         if (stop ==0 && take > 0) result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), take, OrderExpiration(), CLR_NONE);
         if (!result)
         {
             int err=GetLastError();
             Print(Symbol(), " ", type," SL  order modify failed with error(",err,"): ",ErrorDescription(err));
         }//if (!result)			  
      }//if (ticket > -1)
      
   }//if (CriminalIsECN)
   
   //Error trapping for both
   if (ticket < 0)
   {
      string stype;
      if (type == OP_BUY) stype = "OP_BUY";
      if (type == OP_BUYSTOP) stype = "OP_BUYSTOP";
      if (type == OP_SELL) stype = "OP_SELL";
      if (type == OP_SELLSTOP) stype = "OP_SELLSTOP";
      err=GetLastError();
      //Alert(Symbol(), " ", stype," Nanningbob order send failed with error(",err,"): ",ErrorDescription(err));
      Print(Symbol(), " ", stype," #1 Buy Nanningbob order send failed with error(",err,"): ",ErrorDescription(err));
      return(false);
   }//if (ticket < 0)  
   
   //Got this far, so trade send succeeded
   return(true);
   
}//End bool SendSingleTrade(int type, string comment, double lotsize, double price, double stop, double take)

bool DoesTradeExist()
{
   
   
   if (OrdersTotal() == 0) return(false);
   
   for (int cc = OrdersTotal() - 1; cc >= 0 ; cc--)
   {
      if (!OrderSelect(cc,SELECT_BY_POS)) continue;
      
      if (OrderMagicNumber()==MagicNumber && OrderSymbol() == Symbol() )      
      {
         return(true);         
      }//if (OrderMagicNumber()==MagicNumber && OrderSymbol() == Symbol() )      
   }//for (int cc = OrdersTotal() - 1; cc >= 0 ; cc--)

   return(false);

}//End bool DoesTradeExist()


//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
//----
   
   if (RobotSuspended)
   {
      Comment("......................This robot is suspended.................");
      return;
   }//if (RobotSuspended)
   
   
   if (DoesTradeExist()) return;
   
   BbLower = iBands(NULL, PERIOD_H4,  25, 2, 0, PRICE_CLOSE, MODE_LOWER, 0); 

   BbMiddle = iBands(NULL, PERIOD_H4,  25, 2, 0, PRICE_CLOSE, MODE_MAIN, 0); 

   BbUpper = iBands(NULL, PERIOD_H4,  25, 2, 0, PRICE_CLOSE, MODE_UPPER, 0);
 
   
   if (OldBars == Bars) return;
   OldBars = Bars;
 
   RefreshRates();
   //Long
   if (Ask > BbUpper && TradeLong)
   {
      double take = NormalizeDouble(Ask + (TakeProfit * Point),Digits);
      if (TakeProfit == 0) take = 0;
      bool result = SendSingleTrade(OP_BUY, TradeComment, Lot, Ask, BbMiddle, take);
      if (!result) 
      {
         OldBars = 0;
         return;
      }//if (!result) 
      
      if (result && UseSafetyFeature) 
      {
         RobotSuspended = true;
         Alert(Symbol() + " NB BB squeeze EA has sent a trade and suspended itself");
      }//if (result)       
   }//if (Bid > BbUpper)
   
   
   //Short
   if (Bid < BbLower && TradeShort)
   {
      take = NormalizeDouble(Bid - (TakeProfit * Point),Digits);
      if (TakeProfit == 0) take = 0;
      result = SendSingleTrade(OP_SELL, TradeComment, Lot, Bid, BbMiddle, take);
      if (!result) 
      {
         OldBars = 0;
         return;
      }//if (!result) 
      if (result && UseSafetyFeature) 
      {
         RobotSuspended = true;
         Alert(Symbol() + " NB BB squeeze EA has sent a trade and suspended itself");
      }//if (result)       
   }//if (Bid < BbLower)
   
   
    

//----
   return(0);
}
//+------------------------------------------------------------------+