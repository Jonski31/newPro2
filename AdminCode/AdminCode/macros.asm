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
	;ldi YL, low(inventory)
	;ldi YH, high(inventory)
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
	ldi temp, 36
	do_lcd_data_reg temp

	lds temp, currentCost			;now write cost
	subi temp, -'0'
	do_lcd_data_reg temp
	popTemp
.endMacro
////////////////////////////////////

.macro getInventory
	pushTemp
	ldi YH, high(inventory)
	ldi YL, low(inventory)

;we want to increment 2(n-1)-1 times as we have to increment Y each time
; accept n as an integer
	clr temp2		;use temp2 as counter
	mov temp, @0
	dec temp
;branch case for input of 1, i.e. dont shift just store
	cpi temp, 0
	breq store

	lsl temp
	dec temp ;in order to get the address 

increment:
	ld temp1, Y+
	;sts currentStock, temp1
	ld temp1, Y
	;sts currentCost, temp1

	cp temp, temp2
	breq store
	inc temp2			;increment counter
	rjmp increment
store:
	ld temp1, Y
	sts currentStock, temp1
	ld temp1, Y + 
	sts currentCost, temp1

	popTemp
.endMacro


// we want to take current stock value, add one to it and store it in Y
// Y value is obtained by calling getInventory
.macro increaseStock 
	pushTemp
	lds temp2, currentStock

	cpi temp2, 10   ;check if stock is larger than 10
	breq exit

	inc temp2		;add one to current stock
	sts currentStock, temp2
	st Y, temp2	
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
	st Y, temp2	
exit:
	popTemp
.endMacro

.macro increaseCost
	pushTemp	
	lds temp2, currentCost	
	cpi temp2, 3		;check if equal to 3
	breq exit
	inc temp2			;Increase cost by one

	sts currentCost, temp2		;update inventory and currentCost
	std Y + 1, temp2
exit:
	popTemp
.endMacro

.macro decreaseCost 
	pushTemp
	lds temp2, currentCost
	cpi temp2, 1
	breq exit
	dec temp2
	sts currentCost, temp2		;update inventory and currentCost
	std Y + 1, temp2
exit:
	popTemp
.endMacro