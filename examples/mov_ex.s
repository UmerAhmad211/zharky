section .data
    msg db 53

section .text
    global _start

_start:
    mov eax, 9dh    
    mov ebx, eax    
    nop             
    mov ecx, 4c00h     
    mov eax, 1         
    mov ebx, 0      
    int 80h          
