section .data
	msg db "Hello, world!", Ah  
	len dd 14                    

section .text
	global _start

_start
	nop
