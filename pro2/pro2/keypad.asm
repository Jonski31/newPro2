// Instead of temp1 we will use r23 to store the return of this function

colloop:
	cpi col, 4
	breq returnBridge; If all keys are scanned, repeat.
	sts PORTL, cmask ; Otherwise, scan a column.
	ldi temp1, 0xFF ; Slow down the scan operation.
delay: 
	dec temp1
	brne delay
	lds temp1, PINL ; Read PORTL
	andi temp1, ROWMASK ; Get the keypad output value
	cpi temp1, 0xF ; Check if any row is low
	breq nextcol
	; If yes, find which row is low
	ldi rmask, INITROWMASK ; Initialize for row check
	clr row ; 

rowloop:
	cpi row, 4
	breq nextcol ; the row scan is over.
	mov temp2, temp1
	and temp2, rmask ; check un-masked bit
	breq convert ; if bit is clear, the key is pressed
	inc row ; else move to the next row
	lsl rmask
	jmp rowloop

returnBridge:
	jmp returnKeypad
nextcol: ; if row scan is over
	lsl cmask
	inc col ; increase column value
	jmp colloop ; go to the next column

convert:
	checkIfMenu 1
	breq branchSelectScreen
	;rcall SelectScreen	; try make to rcall
	
	cpi col, 3 ; If the pressed key is in col.3
	breq letters ; we have a letter
	; If the key is not in col.3 and
	cpi row, 3 ; If the key is in row3,
	breq symbols ; we have a symbol or 0
	mov r23, row ; Otherwise we have a number in 1-9
	lsl r23
	add r23, row
	add r23, col ; r23 = row*3 + col
	subi r23, -1 ; r23 = row*3 + col + '1'
	
	checkIfMenu 2 //check if on menu 2 if not jump to end
	breq storeKeypad
	jmp returnKeypad

letters:
	ldi r23, 'A'
	add r23, row ; Get the ASCII value for the key
	jmp returnKeypad
symbols:
	cpi col, 0 ; Check if we have a star
	breq star
	cpi col, 1 ; or if we have zero
	breq zero
	ldi r23, '#' ; if not we have hash
	jmp returnKeypad
star:
	ldi r23, '*' ; Set to star
	jmp returnKeypad
zero:
	ldi r23, 0 ; Set to zero
	;jmp returnKeypad

branchSelectScreen:
	rcall selectScreen
	rjmp returnKeypad

branchOOSScreen:
	rcall 
	rjmp returnKeypad

// Store keypad when we need output value otherwise return
storeKeypad:
	sts numPressed, r23   //here we store r23 into numpressed just cause...
	
	checkIfMenu 2		 // check again if menu = 2 
	brne returnKeypad		//if it doesn't jump to end, if it does do macro
	
	isStockEmpty r23		//if true, branch to the out of stock screen
	breq branchOOSScreen

returnKeypad:	
	ret
	

