//pot interrupt
EXT_POT:
	pushStack
	lds ZL, ADCL
	lds ZH, ADCH

	ldi temp, (3 << REFS0) | (0 << ADLAR) | (0 << MUX0)
	sts ADMUX, temp
	ldi temp, (1 << MUX5)
	sts ADCSRB, temp
	ldi temp, (1 << ADEN) | (1 << ADSC) | (1 << ADIE) | (5 << ADPS0)
	sts ADCSRA, temp

	cpi ZL, low(0x000)		//potentiometer is turned left
	ldi temp1, high(0x000)
	cpc ZH, temp1
	breq potLeft

	cpi ZL, low(0x3FF)		//potentiometer is turned right
	ldi temp1, high(0x3FF)
	cpc ZH, temp1
	breq potRight

	returnPot:
		popStack
		reti

potLeft:
	checkIfMenu 4
	brne returnPot
	
	checkIfTurnedRight 0
	breq incInitialLeft

	checkifInserted 1
	breq coinInserted
	rjmp returnPot

potRight:
	checkIfMenu 4
	brne returnPot
	checkIfInitialLeft 1
	breq incTurnedRight 
	rjmp returnPot

coinInserted:
	lds temp, coins 
	lsl temp
	inc temp
	sts coins, temp
	out PORTC, temp
	setInserted 0
	rjmp returnPot

incTurnedRight:
	setTurnedRight 1
	setInserted 1
	rjmp returnPot
	
incInitialLeft:
	setInitialLeft 1
	rjmp returnPot


///////////////////////////////////////////