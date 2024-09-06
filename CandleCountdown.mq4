//+------------------------------------------------------------------+
//| CandleCountdown.mq4
//| Based on EJ_CandleTime
//| !!! this file is created with Tab size 4 and no space indentation
//+------------------------------------------------------------------+
#property copyright "Comer"
#property link		""

#property indicator_chart_window
#property indicator_buffers 0

#define OBJECT_NAME		"CandleCountdown"
#define MSG_PREFIX		"<-- "
#define MAX_VALUE		"999d hh:mm:ss"
#define DEFAULT_FONT	"Arial"
#define DEFAULT_SIZE	10
#define DEFAULT_COLOR	Gold

extern int Right_Shift_from_Bar = 4;

int		DAY_SECONDS; // constant
string	MAX_PADDING;
int		MAX_LENGTH; // constant
	
color	col			= DEFAULT_COLOR;
int		fontSize	= DEFAULT_SIZE;

int init() {
	DAY_SECONDS	= PERIOD_D1 * 60; // constant

	MAX_PADDING = "";
	/*	the coordinates for OBJ_TEXT point to the middle of the string. To make actual text begin where 
		'time' parameter is, the string must be twice longer in pixels. Using space padding to do that.
		number of spaces required = usable string length. The actual string is not known at this point,
		therefore take the maximum possible and strip extra spaces later.
	*/
	int totalSpaces = StringLen(MSG_PREFIX + MAX_VALUE);
	for( int i = totalSpaces*1.5 + 1; i > 0; i--) // see the 'start()' method for explanation of 1.5
		MAX_PADDING = StringConcatenate(MAX_PADDING, " ");
	MAX_LENGTH = StringLen(MAX_PADDING);
	
	return(0);
}
	
int deinit() {
	switch( UninitializeReason() ) {
		case REASON_CHARTCLOSE:
		case REASON_REMOVE:
		case REASON_RECOMPILE:
			Comment("");
			ObjectDelete( OBJECT_NAME );
			break;
		case REASON_CHARTCHANGE:	// leave the object the way it is if simply switching timeframes
		case REASON_PARAMETERS:
		case REASON_ACCOUNT:
			break;
	}
	return(0);
}

int start() {
	datetime	barOpenTime 	= Time[0];	// number of seconds elapsed from 00:00 January 1, 1970.
	bool		hasHours		= (Period() > PERIOD_H1);	// need to display hours if timeframe is more than 1H 
	bool		hasDays			= (Period() > PERIOD_D1);	// need to display days left 
	datetime	barCloseTime	= barOpenTime + Period()*60;
	datetime	leftUntilClose	= barCloseTime - TimeCurrent();
	string		msg				= "";
	bool		exists			= false;
	datetime	objectX			= barOpenTime + Period()*60*Right_Shift_from_Bar;
	double		objectY;
	string		fontName		= NULL;	// do not change the font
	
	if( leftUntilClose <= 0 )
		leftUntilClose = 1;
		
	if( hasDays ) {
		msg = msg + (leftUntilClose / DAY_SECONDS) + "d ";
		leftUntilClose %= DAY_SECONDS;
	}
	msg	= msg + TimeToStr( leftUntilClose, TIME_SECONDS );
	
	if( !hasHours ) // '!hasHours' and 'hasDays' can not be 'true' at the same time
		msg = StringSubstr( msg, 3 ); // strip "hh:" portion

	// the coordinates are the upper middle (wtf?) of the rectangle, so text "hangs" down. make it inside the bar by using whatever higher from open/close.
	if( Open[0] >= Close[0] )
		objectY = Open[0];
	else
		objectY = Close[0];
	
	Comment( msg + " left to bar end" );
	msg = MSG_PREFIX + msg;

	// now, as the X is the middle - exactly half of the text will be on the right of the desired point - so double the number of chars.
	// the problem is that in a proportional font the space uses less width that normal character. about 1.5 times less.
	// depends on the font, of course.
	msg = StringSubstr( MAX_PADDING, MAX_LENGTH - StringLen(msg)*1.5 ) + msg;
	
	if( ObjectFind( OBJECT_NAME ) == -1 ) {
		ObjectCreate	( OBJECT_NAME, OBJ_TEXT, 0, objectX, objectY );
		ObjectSet		( OBJECT_NAME, OBJPROP_COLOR, col );
		ObjectSetText	( OBJECT_NAME, msg, fontSize, DEFAULT_FONT );
	}
	saveProperties();
	ObjectMove		( OBJECT_NAME, 0, objectX, objectY );
	ObjectSetText	( OBJECT_NAME, msg, fontSize );

	return(0);
}

void saveProperties() {
	col			= ObjectGet( OBJECT_NAME, OBJPROP_COLOR );
	fontSize	= ObjectGet( OBJECT_NAME, OBJPROP_FONTSIZE );
}

