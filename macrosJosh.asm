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

.macro pushTemp
	push temp
	push temp1
	push temp2
	in temp, SREG
	push temp ; Prologue starts.
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


.macro popTemp
	pop temp
	out SREG, temp
	pop temp2
	pop temp1
	pop temp
.endmacro

///////////////////////////////////////////////////////////////////////////////////

///////////		INVENTORY MACROS //////////////////////////////////
.macro setInventory  
	;pushTemp
	;arranges items in 2 byte blocks, 1st byte = stock, 2nd byte = cost
	ldi YL, low(inventory)
	ldi YH, high(inventory)
	ldi temp, 1 ;1
	st Y+, temp
	ldi temp, 1 
	st Y+, temp
	ldi temp, 2 ;2	;  set to 0 for debug, change back to 2 when done
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
	;popTemp
.endmacro

// Compares menu to given input
.macro checkIfMenu
	;pushTemp 
	lds temp, menu
	cpi temp, @0
	;popTemp
.endMacro

// Set menu to given input
.macro setMenu
	;pushTemp
	ldi temp, @0
	sts menu, temp
	;popTemp
.endMacro

.macro getInventory
// push all registers onto the stack //
	pushTemp
ldi YH, high(inventory)
ldi YL, low(inventory)
 
	mov temp, @0
	dec temp

	;out portc, temp
	cpi temp, 0
	breq skip		;boundary condition when on item 1

	lsl temp // temp = 2(temp1 - 1)
	jmp increment
skip:
	
	ld temp1, Y+
	sts currentStock, temp1
	ld temp1, Y
	sts currentCost, temp1
	clr temp2
	jmp return

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
	popTemp
.endMacro

.macro increaseStock 
	pushTemp
	lds temp2, currentStock

	cpi temp2, 10   ;check if stock is larger than 10
	breq exit

	inc temp2		;add one to current stock
	sts currentStock, temp2		
exit:
	popTemp
.endMacro

.macro decreaseStock 
	pushTemp
	lds temp2, currentStock
	cpi temp2, 0    ;check if equal to zero
	breq exit
	dec temp2		;decrease stock by one
	sts currentStock, temp2
exit:
	popTemp
.endMacro

.macro increaseCost 
	pushTemp	
	lds temp2, currentCost	
	cpi temp2, 3		;check if equal to 3
	breq exit
	inc temp2			;Increase cost by one
	sts currentCost, temp2
exit:
	popTemp
.endMacro

.macro decreaseCost 
	pushTemp
	lds temp2, currentCost
	cpi temp2, 1
	breq exit
	dec temp2
	sts currentCost, temp2
	exit:
	popTemp
.endMacro

.macro isStockEmpty
	;pushTemp 
	getInventory @0
	lds temp2, currentStock
	cpi temp2, 0
	;popTemp
.endMacro
////////////////////////////////////////

/////	COIN SCREEN MACROS //////////
.macro incrementCoins
	;pushTemp
	lds temp, coins
	inc temp
	sts coins, temp
	clr temp
	;popTemp
.endMacro

.macro decrementCoins
	;pushTemp
	lds temp, coins
	dec temp
	sts coins, temp
	clr temp
	;popTemp
.endMacro

// THIS MACRO UPDATES THE ADMIN SCREEN WHEN WE WANT TO INCREMENT AND DECREMENT
.macro updateAdminScreen
	pushTemp
	resetLCD			;First we reset LCD screen

	do_lcd_data 'A'
	do_lcd_data 'd'
	do_lcd_data 'm'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data ' '
	do_lcd_data 'M'
	do_lcd_data 'o'
	do_lcd_data 'd'
	do_lcd_data 'e'
	do_lcd_data ' '


	
	lds temp, numPressed			;load in current item and print number
	subi temp, -'0'
	do_lcd_data_reg temp

	do_lcd_command secondLine		;This writes on the second line
	lds temp, currentStock			;now write current stock
	subi temp, -'0'
	do_lcd_data_reg temp

	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '

	lds temp, currentCost			;now write cost
	subi temp, -'0'
	do_lcd_data_reg temp
	popTemp
.endMacro
////////////////////////////////////