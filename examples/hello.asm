section .data
    hello_msg db "hello, world!", ah
   	len dd 14 

section .text
    global _start 

print_hello:
    mov eax, 4          
    mov ebx, 1         
    mov ecx, hello_msg
    mov edx, [len + 2] 
    int 80h
    ret

exit_program:
    mov eax, 1          
    xor ebx, ebx        
    int 80h
    ret

_start:
    call print_hello    
    call exit_program  
