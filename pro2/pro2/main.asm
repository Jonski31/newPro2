;
; pro2.asm
;
; Created: 30/05/2017 10:16:41 PM
; Author : asafp
;

.include "m2560def.inc"


.def temp = r16
.def temp1 = r17
.def temp2 = r18

//KEYPAD REGISTERS
.def row = r19 ; current row number
.def col = r20 ; current column number
.def rmask = r21 ; mask for current row during scan
.def cmask = r22 ; mask for current column during scan


//KEYPAD CONSTANTS
.equ PORTLDIR = 0xF0 ; PD7-4: output, PD3-0, input
.equ INITCOLMASK = 0xEF ; scan from the rightmost column,
.equ INITROWMASK = 0x01 ; scan from the top row
.equ ROWMASK = 0x0F ; for obtaining input from Port D

.equ secondline = 0b10101000

.include "macros.asm"


.dseg
	menu: .byte 1 ; menu screen 1-7
	coins: .byte 1 ;keeps track of number of coins entered so far
// TIMERS //
TimeCounter:
	.byte 2 ; Two-byte counter for counting seconds.
TempCounter:; Counts quater seconds 
	.byte 2 ; Temporary counter. Used to determine
timer1:		; for start screen
	.byte 1
timer3:		; for Out of stock screen
	.byte 1
timer6:     ; Used for entering admin mode
	.byte 1

// KEYPAD
numPressed:		; current number pressed
	.byte 1
prevNum:		; previous number pressed
	.byte 1

sound:			; beep static for 250ms
	.byte 1
//INSERT COIN
initialLeft: .byte 1
turnedRight: .byte 1
;finalLeft: .byte 1
inserted: .byte 1
coinsForReturn : .byte 1
coinReturnTime: .byte 1
currentStock:
	.byte 1
currentCost:
	.byte 1
pattern:
	.byte 1 //pattern for leds atm flash only

//INTERUPTS
.cseg
	.org 0
		jmp RESET
	.org INT0addr
		jmp EXT_INT0
	.org INT1addr
		jmp EXT_INT1   ;push button interrupt
	.org OVF0addr
		jmp Timer0OVF ; Jump to the interrupt handler for
						; Timer0 overflow.
	.org 0x003A		  ;Address of ADC
		jmp EXT_POT



.include "keypad.asm"
.include "inventory.asm"
.include "pot.asm"
RESET:
	// INTIATE STACK
	ldi r16, low(RAMEND)
	out SPL, r16
	ldi r16, high(RAMEND)
	out SPH, r16

	// LCD RESET
	ser r16
	out DDRF, r16
	out DDRC, r16
	out DDRA, r16
	out DDRG, r16
	clr r16
	out PORTF, r16
	out PORTA, r16
	out PORTC, r16
	out PORTG, r16

	// TIMER RESET//
	clear TempCounter ; Initialize the temporary counter to 0
	clear TimeCounter ; Initialize the second counter to 0
	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000010
	out TCCR0B, temp ; Prescaling value=8
	ldi temp, 1<<TOIE0 ; = 128 microseconds
	sts TIMSK0, temp ; T/C0 interrupt enable


	// KEYPAD RESET
	ldi temp1, PORTLDIR ; PA7:4/PA3:0, out/in
	sts DDRL, temp1

	// PUSH BUTTON INITIALISATION 
	ldi temp, (2<<ISC00)	;set INT0 as falling edge triggered interupt
	sts EICRA, temp
	in temp, EIMSK			;enable INT0 & INT1
	ori temp, (1<<INT0)
	ori temp, (1<<INT1)
	out EIMSK, temp

	// ADC INIT
	ldi temp, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0)
	sts ADMUX, temp
	ldi temp, (1 << MUX5)
	sts ADCSRB, temp
	ldi temp, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0)
	sts ADCSRA, temp

	ser temp              //MOTOR IS PIN 3
	out DDRE, temp
	clr temp
	out PORTE, temp
	ser temp              //SOUND IS PIN 0
	out DDRB, temp
	clr temp
	out PORTB, temp

	sei ; Enable global interrupt

	// INVENTORY INITIALISATION
	setInventory

	// CONSTANTS
	ldi temp, 0
	sts coins, temp
	sts coinsForReturn, temp
	sts coinReturnTime,temp

	rcall startScreen
	rjmp main			;go to main to start polling, reset finished

startScreen: ;start screen is part of reset function
	setMenu 1
	;out portc, temp

	resetLCD

	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data '2'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data '1'
	do_lcd_data '7'
	do_lcd_data 's'
	do_lcd_data '1'
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_data 'A'
	do_lcd_data '4'

	do_lcd_command secondLine

	do_lcd_data 'V'
	do_lcd_data 'e'
	do_lcd_data 'n'
	do_lcd_data 'd'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'M'
	do_lcd_data 'a'
	do_lcd_data 'c'
	do_lcd_data 'h'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'e'

	ldi temp, 12	; for 3 seconds, intitilise to 13, because every 0.25s x 4 = 1 *3 = 12;
	sts timer1, temp
	ret

selectScreen:
	
	// if coming from insertCoin screen, we need to clear coins, clear leds, and keep the value of coins in coinsforreturn
	checkIfMenu 4
	brne test
	//lds temp, coinsForReturn
	//lsl temp
	//sts coinsForReturn, temp
	//inc temp
	//out portc, temp
	//sts coinsForReturn, temp

	ldi temp, 0
	sts coins, temp
	out PORTC, temp
	setInserted 0
	setInitialLeft 0
	setTurnedRight 0

	test:
	setMenu 2
	;out portc, temp

	resetLCD

	do_lcd_data 'S'
	do_lcd_data 'e'
	do_lcd_data 'l'
	do_lcd_data 'e'
	do_lcd_data 'c'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'I'
	do_lcd_data 't'
	do_lcd_data 'e'
	do_lcd_data 'm'
	ret

//menu 3
outOfStockScreen:
	resetLCD

	do_lcd_data 'O'
	do_lcd_data 'u'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'f'
	do_lcd_data ' '
	do_lcd_data 'S'
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data 'c'
	do_lcd_data 'k'

	do_lcd_command secondLine

	;out PORTC, temp1
	lds temp1, numPressed
	subi temp1, -'0'
	do_lcd_data_reg temp1		;temp1 holds what key was pressed, we convert it to ascii, print it out to lcd


	;We will have a check to see when this equals 6 i.e. 1.5secs to toggle led's
	setMenu 3
	ldi temp, 12	;for 3 seconds, intitilise to 12, because every 0.25s x 4 = 1 *3 = 12;
	sts timer3, temp
	ldi temp, 0b00000000
	sts pattern, temp
	ret

coinScreen:
	setMenu 4

	resetLCD

	do_lcd_data 'I'
	do_lcd_data 'n'
	do_lcd_data 's'
	do_lcd_data 'e'
	do_lcd_data 'r'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'C'
	do_lcd_data 'o'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 's'

	do_lcd_command secondLine
	
	// PRINT TO LED NUMBER OF COINS BEEN ENTERED, LEAVE IN, NOT DEBUGGING!!!!!
	lds temp, coins
	out portc, temp
	// SHOW NUMBER OF COINS REMAINING = CURRENTCOST - COINS ENTERED
	lds temp1, currentCost
	lds temp, coinsForReturn
	sub temp1, temp
	cpi temp1, 1
	brlt DeliverScreen
	subi temp1, -'0'
	do_lcd_data_reg temp1
	
	ret

DeliverScreen:
	setMenu 5

	resetLCD

	do_lcd_data 'D'
	do_lcd_data 'e'
	do_lcd_data 'l'
	do_lcd_data 'i'
	do_lcd_data 'v'
	do_lcd_data 'e'
	do_lcd_data 'r'
	do_lcd_data 'i'
	do_lcd_data 'n'
	do_lcd_data 'g'
	do_lcd_data ' '
	do_lcd_data 'I'
	do_lcd_data 't'
	do_lcd_data 'e'
	do_lcd_data 'm'
	
	ldi temp2, 3    // counter
	decreaseStock
	startMotor
	timeLoop:
	ser temp1		;flash leds
	out PORTC, temp1
	out PORTG, temp1

	rcall sleep_500ms

	clr temp1		;clear leds
	out PORTC, temp1
	out PORTG, temp1

	rcall sleep_500ms

	dec temp2
	cpi temp2, 0
	brne timeLoop

	stopMotor
	clr temp
	sts coins, temp
	sts coinsForReturn, temp
	rjmp SelectScreen
	;ret

	///ADMIN MODE
enterAdminMode:
	pushTemp
	resetLCD

	setMenu 6

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

	ldi temp, 1
	sts numPressed, temp
	getInventory temp

	subi temp, -'0'
	do_lcd_data_reg temp

	do_lcd_command secondLine
	lds temp, currentStock
	;out PORTC, temp
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

	lds temp, currentCost
	subi temp, -'0'
	do_lcd_data_reg temp
	printLedAdmin
	popTemp	
	ret


// MAIN LOOP TO START POLLING
main:
	ldi cmask, INITCOLMASK	; initial column mask
	clr col					; initial column
	rcall colloop			; continue poll
	rjmp main				; loop main to continue polling 


///////////////////////////////////////////////


// TIMER 0 INTERUPT
Timer0OVF: ; interrupt subroutine to Timer0
	
	pushStack
	; Load the value of the temporary counter.
	lds r24, TempCounter
	lds r25, TempCounter+1
	adiw r25:r24, 1 ; Increase the temporary counter by one.

	cpi r24, low(1953) ; Check if (r25:r24) = 7812
	ldi temp, high(1953) ; 7812 = 10^6/128
	cpc r25, temp
	brne NotSecond //not 0.25 seconds

	////////sound stuff
	lds temp, sound
	cpi temp, 1
	brsh outputSound 
	ldi temp2, 0b00000000
	out PORTB, temp2  //Set no sound
	
	
	rjmp returnFlag

	outputSound:
		ldi temp2, 0b10000000
		out PORTB, temp2
		lds temp2, sound
		dec temp2
		sts sound, temp2


	//////////////

	rjmp returnflag
NotSecond:
	; Store the new value of the temporary counter.
	sts TempCounter, r24
	sts TempCounter+1, r25
	rjmp epilogue

	// Execute every 0.25 sec
	returnFlag:
		lds temp2, coinReturnTime // check if we need to return coins
		cpi temp2, 0
		breq timer1flag 
		//out portc, temp2
		andi temp2, 0b00000001
		//out portc, temp2
		cpi temp2,0 // and so we can check if number is odd or even
		brne odd
		startmotor
		rjmp reducecoins
		odd: 
		stopmotor

		reducecoins:
		lds temp2, coinReturnTime 
		dec temp2                   //reduce coin number and store back
		sts coinReturnTime, temp2
		rjmp newQsecond

	timer1flag:
		checkIfMenu 1
		brne timer6flag
		lds temp, timer1
		cpi temp, 0
		breq callSelectScreen 
		dec temp
		sts timer1, temp
		rjmp newQsecond
	timer6flag:
		checkIfMenu 2		;admin mode can only be entered in menu 2
		brne timer3flag		;ELSE move on

		lds temp, prevNum   ;only enter loop if '*' is pressed
		cpi temp, '*'
		brne timer3flag

		lds temp, timer6       ;load timer 6 = 20 = 5secs

		cpi temp, 0			   ;when timer runs down to 0, decrement
		breq callAdminMode 
		;out portc, temp ; DEBUG DISPLAY TIMER6, (IT WORKS)
		dec temp
		sts timer6, temp
		rjmp newQsecond

	timer3flag:
		checkIfMenu 3 ;check if in out of stock screen
		brne epilogue
		lds temp, timer3
		;out portc, temp
		cpi temp, 0
		breq callSelectScreen ;change later
	
		//FLASH LEDS
		mov temp2, temp //load time into temp
		andi temp2, 0b00000001 //and to get either a 1 or 0 in the last bit
		cpi temp2, 0 //0 = even, 1 = odd
		brne continue //If odd skip
		ser temp1
		lds temp2, pattern
		eor temp2, temp1 //Invert pattern
		sts pattern, temp2
		out portc, temp2
		out portg, temp2

		continue:
		dec temp
		;out portc, temp
		sts timer3, temp
		rjmp newQsecond
	
	callSelectScreen:
		rcall selectScreen
		rjmp epilogue

	callAdminMode:
		rcall enterAdminMode
		rjmp epilogue

newQsecond: ;starts new quarter 
	clear TempCounter ; Reset the temporary counter.
	rjmp epilogue

epilogue:
	popStack
	reti ; Return from the interrupt.
/*
// PUSH BUTTON INTERUPTS :)
EXT_INT0: ;Right Button
	pushStack
	clr temp
	out PORTC, temp
	out PORTG, temp
	
	checkIfMenu 6
	breq incStock

	checkIfMenu 3  ;if menu = 3, go back to select screen 
	brne endBridge0
	rcall selectScreen
	rjmp ENT_INT1

//CHECK FOR LATER
endBridge0:
	jmp END_INT0
	rcall selectScreen
	rjmp END_INT1
END_INT0:
	popStack
	reti
incStock:
	increaseStock
	updateAdminScreen
*/
EXT_INT0: ;Right Button
	pushStack
	
	clr temp
	out PORTC, temp
	out PORTG, temp
	
	checkIfMenu 6
	breq incStock
	
	checkIfMenu 3  ;if menu = 3, go back to select screen 
	brne bridgeENDINT0
	rcall selectScreen
	jmp END_INT0
bridgeENDINT0:
	jmp END_INT0
incStock:
	updateAdminScreen
	increaseStock
	updateAdminScreen
END_INT0:
	popStack
	reti


EXT_INT1: ;Left Button
	pushStack
	
	clr temp
	out PORTC, temp
	out PORTG, temp
	
	checkIfMenu 6
	breq decStock
	
	checkIfMenu 3  ;if menu = 3, go back to select screen 
	brne bridgeENDINT1
	rcall selectScreen
	jmp END_INT1
bridgeENDINT1:
	jmp END_INT1
decStock:
	updateAdminScreen
	decreaseStock
	updateAdminScreen
END_INT1:
	popStack
	reti



halt:
	rjmp halt

	
.include "lcd.asm"

