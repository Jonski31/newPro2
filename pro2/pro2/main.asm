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
	menu: .byte 1 ; menu screen 1-5

// TIMERS //
TimeCounter:
	.byte 2 ; Two-byte counter for counting seconds.
TempCounter:; Counts quater seconds 
	.byte 2 ; Temporary counter. Used to determine
timer1:		; for start screen
	.byte 1
timer3:		; for Out of stock screen
	.byte 1

// KEYPAD
numPressed:		; current number pressed
	.byte 1

currentStock:
	.byte 1
currentCost:
	.byte 1

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


.include "keypad.asm"
.include "inventory.asm"

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
	clr r16
	out PORTF, r16
	out PORTA, r16

	// TIMER RESET//
	clear TempCounter ; Initialize the temporary counter to 0
	clear TimeCounter ; Initialize the second counter to 0
	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000010
	out TCCR0B, temp ; Prescaling value=8
	ldi temp, 1<<TOIE0 ; = 128 microseconds
	sts TIMSK0, temp ; T/C0 interrupt enable

	ldi temp1, 0

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

	sei ; Enable global interrupt

	// INVENTORY INITIALISATION
	setInventory

	rcall startScreen
	rjmp main			;go to main to start polling, reset finished

startScreen: ;start screen is part of reset function
/*	ldi temp, 1
	sts menu, temp*/
	setMenu 1
	out portc, temp	;debug

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
	setMenu 2
	out portc, temp		;debug

	resetLCD

	do_lcd_data 'S'
	do_lcd_data 'e'
	do_lcd_data 'l'
	do_lcd_data 'e'
	do_lcd_data 'c'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'i'
	do_lcd_data 't'
	do_lcd_data 'e'
	do_lcd_data 'm'
	ret

outOfStockScreen:
	setMenu 3
	
	resetLCD

	/*do_lcd_data 'O'
	do_lcd_data 'u'
	do_lcd_data 't'
	do_lcd_data ' '
	do_lcd_data 'o'
	do_lcd_data 'f'
	do_lcd_data ' '
	do_lcd_data 's'
	do_lcd_data 't'
	do_lcd_data 'o'
	do_lcd_data 'c'
	do_lcd_data 'k'*/

	lds temp, currentStock
	subi temp, -'0'   ; 'subi -' adds the negative --> this line just converts temp to ascii
	do_lcd_data_reg temp
	do_lcd_command secondLine

	;out PORTC, temp1
	lds temp1, numPressed
	subi temp1, -'0'
	do_lcd_data_reg temp1		;temp1 holds what key was pressed, we convert it to ascii, print it out to lcd


	;We will have a check to see when this equals 6 i.e. 1.5secs to toggle led's

	ldi temp, 12	;for 3 seconds, intitilise to 12, because every 0.25s x 4 = 1 *3 = 12;
	sts timer3, temp
	ret


// MAIN LOOP TO START POLLING
main:
	ldi cmask, INITCOLMASK	; initial column mask
	clr col					; initial column
	rcall colloop			; continue poll
	rjmp main				; loop main to continue polling 


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

// Execute every 0.25 sec
	brne NotSecond //not 0.25 seconds
	
	timer1flag:
		;lds temp, menu
		;cpi temp, 1
		checkIfMenu 1
		brne timer3flag
		lds temp, timer1

		cpi temp, 0
		breq callSelectScreen ;change later
		dec temp
		sts timer1, temp
		rjmp newQsecond
		
	timer3flag:
		checkIfMenu 3 ;check if in out of stock
		brne epilogue
		lds temp, timer3

		cpi temp, 0
		breq callSelectScreen ;change later
		;cpi temp, 12

		dec temp
		sts timer3, temp
		rjmp newQsecond

	callSelectScreen:
		rcall selectScreen
		rjmp epilogue

	callOOSScreen:
		rcall outOfStockScreen
		rjmp epilogue

/*	if(menu == 1 || menu == 3)
		use timer1 (3 seconds)
	else if (menu == 2)
		use timer2 (5 seconds)*/



newQsecond: ;starts new quarter 
	clear TempCounter ; Reset the temporary counter.
	rjmp epilogue

NotSecond:
	; Store the new value of the temporary counter.
	sts TempCounter, r24
	sts TempCounter+1, r25

epilogue:
	popStack
	reti ; Return from the interrupt.


// PUSH BUTTON INTERUPTS :)
EXT_INT0: ;Right Button
	pushStack
	
	/*cpi debounceFlag0, 1 ;if still debouncing, ignore interupt
	breq END_INT0 

	ldi debounceFlag0, 1 ;set debounce flag*/

	checkIfMenu 3  ;if menu = 3, go back to select screen 
	brne END_INT0
	rcall selectScreen
	
END_INT0:
	popStack
	reti

EXT_INT1: ;Left Button
	pushStack
	
	/*cpi debounceFlag0, 1 ;if still debouncing, ignore interupt
	breq END_INT0 

	ldi debounceFlag0, 1 ;set debounce flag*/
	
	checkIfMenu 3  ;if menu = 3, go back to select screen 
	brne END_INT1
	rcall selectScreen
		
END_INT1:
	popStack
	reti


halt:
	rjmp halt

	
.include "lcd.asm"

