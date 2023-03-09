//+------------------------------------------------------------------+
//|                                                Bot_Martingal.mq4 |
//|                        Copyright 2023, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

string botName = "GogiBot";
int orderDirection = OP_SELL;
double lotSize = 0.01;
double StopLoss=0;
double TakeProfit = 500;      // point
double martingaleZone = 100;  // pips

int OnInit(){
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

// Co lenh dang chay ===>  SELL/BUY
// SELL: Tim entry point cua lenh [moi nhat] (co entry point LON nhat)
//         Tim ton so lot cua cac lenh dang chay

void OnTick(){
   int total = get_Number_of_Orders_Running_by_bot();
   
   // check khong co lenh nao dang chay ===> tu dat lenh moi
   if(total==0){
      double stopLoss = 0;
      double takeProfit = 0;
      if(orderDirection==OP_SELL){
         //stopLoss = NormalizeDouble(Ask+StopLoss*Point, Digits);
         takeProfit = NormalizeDouble(Ask-TakeProfit*Point, Digits);
      }
      if(orderDirection==OP_BUY){
         //stopLoss = NormalizeDouble(Bid-StopLoss*Point, Digits);
         takeProfit = NormalizeDouble(Bid+TakeProfit*Point, Digits);
      }
      int ticket = OrderSend(Symbol(), orderDirection, lotSize, Ask, 3, stopLoss, takeProfit, botName, 8888, 0, clrGreen);
   }
   
   
   // check co lenh Martingle dang chay
   string runningType = get_Order_Martingal_Running_by_bot();
   
   if(runningType != "EMPTY"){
   
         if(OrdersTotal()>1){
            if(get_total_Profit_of_orders_running_by_bot()>0){
               closeAll_by_bot();
            }   
         }
            
         double totalLotSize = get_total_lotSize_of_orders_running_by_bot();

         if(runningType=="SELL"){
            double maxEntry = get_maximum_entry_point_of_orders_running_by_bot();
            double currentZone = (Ask - maxEntry)*10000;
            if( currentZone > martingaleZone ){
               remove_TakeProfit__of_orders_running_by_bot();
               int ticket = OrderSend(Symbol(), OP_SELL, totalLotSize, Ask, 3, 0, 0, botName, 8888, 0, clrGreen);
            }
         }
         
   }
}

void remove_TakeProfit__of_orders_running_by_bot(){
   if( OrdersTotal()>0 ){
      for(int pos=0; pos<OrdersTotal(); pos++){
         if(OrderSelect(pos, SELECT_BY_POS)==false) continue;
         if(OrderComment()==botName && OrderTakeProfit()>0){
             OrderModify(OrderTicket(),OrderOpenPrice(),0,0,0,clrGreen);
         }   
      }
   }
}

double get_total_Profit_of_orders_running_by_bot(){
   double result = 0;
   if( OrdersTotal()>0 ){
      for(int pos=0; pos<OrdersTotal(); pos++){
         if(OrderSelect(pos, SELECT_BY_POS)==false) continue;
         if(OrderComment()==botName){
            result += OrderProfit();
         }   
      }
   }
   return result;
}


double get_total_lotSize_of_orders_running_by_bot(){
   double result = 0;
   if( OrdersTotal()>0 ){
      for(int pos=0; pos<OrdersTotal(); pos++){
         if(OrderSelect(pos, SELECT_BY_POS)==false) continue;
         if(OrderComment()==botName){
            result += OrderLots();
         }   
      }
   }
   return result;
}


double get_maximum_entry_point_of_orders_running_by_bot(){
   double result = 0;
   if( OrdersTotal()>0 ){
      for(int pos=OrdersTotal()-1; pos>=0; pos--){
         Print("Order ticket " + OrderTicket() + " " + OrdersTotal());
         if(OrderSelect(pos, SELECT_BY_POS)==false) continue;
         if(OrderComment()==botName){
            if(OrderOpenPrice()>=result){
               result = OrderOpenPrice();
            }
         }   
      }
   }
   return result;
}

double get_minimum_entry_point_of_orders_running_by_bot(){
   double result = 0;
   if( OrdersTotal()>0 ){
      for(int pos=0; pos<OrdersTotal(); pos++){
         if(OrderSelect(pos, SELECT_BY_POS)==false) continue;
         if(OrderComment()==botName){
            if(OrderOpenPrice()<=result){
               result = OrderOpenPrice();
            }
         }   
      }
   }
   return result;
}

string get_Order_Martingal_Running_by_bot(){
   int totalOrders = 0;
   string direction = "";
   if( OrdersTotal()>0 ){
      for(int pos=0; pos<OrdersTotal(); pos++){
         if(OrderSelect(pos, SELECT_BY_POS)==false) continue;
         if(OrderComment()==botName){
            totalOrders++;
            if(OrderType()==OP_BUY){direction="BUY";}
            if(OrderType()==OP_SELL){direction="SELL";}
         }   
      }

   }
   if(totalOrders==0){
      direction = "EMPTY";
   }
   
   return direction;
}

int get_Number_of_Orders_Running_by_bot(){
   int totalOrders = 0;
   if( OrdersTotal()>0 ){
      for(int pos=0; pos<OrdersTotal(); pos++){
         if(OrderSelect(pos, SELECT_BY_POS)==false) continue;
         if(OrderComment()==botName){
            totalOrders++;
         }   
      }

   }
   return totalOrders;
}

void closeAll_by_bot(){
   bool rv = false;
   for(int index = OrdersTotal() - 1; index >= 0; index--)
      {
         OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
         
         if (OrderSymbol() == Symbol() && OrderComment()==botName )
         switch (OrderType())
         {
            case OP_BUY: 
               if (!OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 0, Red))
                  rv = false;
               break;
   
            case OP_SELL:
               if (!OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 0, Red))
                  rv = false;
               break;
   
            case OP_BUYLIMIT: 
            case OP_SELLLIMIT:
            case OP_BUYSTOP: 
            case OP_SELLSTOP:
               if (!OrderDelete(OrderTicket()))
                  rv = false;
               break;
         }
      }

}

///////

int CloseAll()
{ 
   bool rv = false;
   int numOfOrders = OrdersTotal();
   int FirstOrderType = 0;
   
   for (int index = 0; index < OrdersTotal(); index++)   
     {
       OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
       if (OrderSymbol() == Symbol()) 
       {
         FirstOrderType = OrderType();
         break;
       }
     }   
         
   for(int index = numOfOrders - 1; index >= 0; index--)
   {
      OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
      
      if (OrderSymbol() == Symbol())
      switch (OrderType())
      {
         case OP_BUY: 
            if (!OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 0, Red))
               rv = false;
            break;

         case OP_SELL:
            if (!OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 0, Red))
               rv = false;
            break;

         case OP_BUYLIMIT: 
         case OP_SELLLIMIT:
         case OP_BUYSTOP: 
         case OP_SELLSTOP:
            if (!OrderDelete(OrderTicket()))
               rv = false;
            break;
      }
   }

   return(rv);
}