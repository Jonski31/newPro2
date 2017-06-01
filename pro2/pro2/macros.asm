// LCD MACROS /////////
.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro do_lcd_data_reg
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro clear
	ldi YL, low(@0) ; load the memory address to Y
	ldi YH, high(@0)
	clr temp
	st Y+, temp ; clear the two bytes at @0 in SRAM
	st Y, temp
.endmacro

.macro resetLCD
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001100 ; Cursor on, bar, no blink
.endmacro
///////////////////////////////////////////////////////////

// STACK MACROS //////////////////////
.macro pushStack
	push temp
	push temp1
	push temp2
	in temp, SREG
	push temp ; Prologue starts.
	push YH ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 ; Prologue ends.
.endmacro


.macro popStack
	pop r24 ; Epilogue starts;
	pop r25 ; Restore all conflict registers from the stack.
	pop YL
	pop YH
	pop temp
	out SREG, temp
	pop temp2
	pop temp1
	pop temp
.endmacro
///////////////////////////////////////////////////////////////////////////////////

///////////		INVENTORY MACROS //////////////////////////////////
.macro setInventory  
	;arranges items in 2 byte blocks, 1st byte = stock, 2nd byte = cost
	ldi YL, low(inventory)
	ldi YH, high(inventory)
	ldi temp, 1 ;1
	st Y+, temp
	ldi temp, 1 
	st Y+, temp
	ldi temp, 0 ;2	;  set to 0 for debug, change back to 2 when done
	st Y+, temp
	ldi temp, 2 
	st Y+, temp
	ldi temp, 3 ;3
	st Y+, temp
	ldi temp, 1 
	st Y+, temp
	ldi temp, 4 ;4
	st Y+, temp
	ldi temp, 2 
	st Y+, temp
	ldi temp, 0 ;5
	st Y+, temp
	ldi temp, 1 
	st Y+, temp
	ldi temp, 6 ;6
	st Y+, temp
	ldi temp, 2 
	st Y+, temp
	ldi temp, 7 ;7
	st Y+, temp
	ldi temp, 1 
	st Y+, temp
	ldi temp, 8 ;8
	st Y+, temp
	ldi temp, 2 
	st Y+, temp
	ldi temp, 9 ;9
	st Y+, temp
	ldi temp, 1 
	st Y+, temp
	ldi YL, low(inventory)
	ldi YH, high(inventory)
.endmacro

// Compares menu to given input
.macro checkIfMenu 
	lds temp, menu
	cpi temp, @0
.endMacro

// Set menu to given input
.macro setMenu
	push temp
	ldi temp, @0
	sts menu, temp
	pop temp
.endMacro

.macro getInventory
// push all registers onto the stack //

ldi YH, high(inventory)
ldi YL, low(inventory)
 
 mov temp, @0
 dec temp
 lsl temp // temp = 2(temp1 - 1)
 clr temp2


 // increment loop to 2(temp1-1) desired item number //
increment:

	// stores the current item's stock //
	ld temp1, Y+
	sts currentStock, temp1
	// stores the current item's cost //
	ld temp1, Y
	sts currentCost, temp1

	cp temp, temp2
	breq return

	inc temp2
	rjmp increment
return:
.endMacro

.macro isStockEmpty 
	getInventory @0
	lds temp2, currentStock
	cpi temp2, 0
.endMacro
////////////////////////////////////////

/////	COIN SCREEN MACROS //////////
.macro incrementCoins
	lds temp, coins
	inc temp
	sts coins, temp
	clr temp
.endMacro

.macro decrementCoins
	lds temp, coins
	dec temp
	sts coins, temp
	clr temp
.endMacro



////////////////////////////////////

///// ADC MACROS /////////////////
.macro setInitialLeft
	push temp
	ldi temp, @0
	sts initialLeft, temp
	pop temp
.endMacro

.macro setTurnedRight
	push temp
	ldi temp, @0
	sts turnedRight, temp
	pop temp
.endMacro

.macro setFinalLeft
	push temp
	ldi temp, @0
	sts finalLeft, temp
	pop temp
.endMacro

.macro setInserted
	push temp
	ldi temp, @0
	sts inserted, temp
	pop temp
.endMacro

.macro checkIfInitialLeft
	lds temp, initialLeft
	cpi temp, @0
.endMacro

.macro checkIfFinalLeft
	lds temp, finalLeft
	cpi temp, @0
.endMacro

.macro checkIfTurnedRight
	lds temp, turnedRight
	cpi temp, @0
.endMacro

.macro checkIfInserted
	lds temp, inserted
	cpi temp, @0
.endMacro
///////////////////////////////
//MOTOR

.macro startMotor
	push temp

	//ldi temp, (1<<TOIE1)
	//sts TIMSK0, temp
	/*ldi temp, low(0xFF)
	sts OCR3AH, temp
	ldi temp, high(0xFF)
	sts OCR3AL, temp
	*/


	ldi temp, 0b00010000
	//ldi temp, 0b00010000
	out PORTE, temp

	pop temp
.endMacro

.macro stopMotor
	push temp

	ldi temp, 0b00000000
	out PORTE, temp

	pop temp
.endmacro