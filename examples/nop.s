section .data
	msg db "Hello, world!", Ah  
	len dd 14                    

section .text
	global _start

_start:
	nop

	mov eax, 1         
	mov ebx, 0
    int 80h
