.data

A0s:	.word 61, 63, 64, 61, 64, 64, 63, 61, 63, 63, 65, 66, 63, 66, 66, 65, 63, 65, 69, 76, 71, 68, 71, 71, 69, 68, 69, 68, 71, 69, 70, 67, 69, 69, 67, 66, 63

A1s:	.word 550, 130, 350, 250, 130, 130, 130, 130, 650, 550, 160, 350, 250, 130, 130, 130, 130, 650, 350, 250, 550, 130, 130, 130, 130, 130, 350, 550, 370, 130, 450, 130, 130, 130, 130, 130, 650

.text
musiquinha:
	la t0, A0s		# endereço do inicio do vetor de A0s
	la t1, A1s		# endereço do inicio do vetor de A1s
	li t3, 0		# contador de posição do vetor
	li t4, 148
	
	li a7, 33		# syscall de esperar a nota anterior acabar para tocar outra
	li a2, 58		# syscall de instrumento
	li a3, 25		# syscall de volume
	
mf_REPEAT:	
	li a7 31
	lw a0, 0(t0)		# tocar nota gravada no vetor marcado pelo t0
	lw a1, 0(t1)		# tocar durante a duraï¿½ao gravada no vetor marcada pelo t1
	ecall
	
	mv a0,a1		# passa a duração da nota para a pausa
	li a7,32		# define a chamada de syscal 
	ecall
	
	addi t0 t0 4		# andar uma posiï¿½ao no vetor
	addi t1 t1 4		# ''	 ''	  ''	  ''
	addi t3 t3 4		# incrementar o contador pra saber quando resetar os marcadores t0 e t1
	
	beq t3, t4, mf_ZERAR	# se o contador (t3) chegar na ultima nota (posiï¿½ao LABEL + 148), retornar ao inicio do vetor
	
	j mf_REPEAT
	
mf_ZERAR:
	la t0, A0s		# retorna o marcador do vetor A0s para o inicio de A0s
	la t1, A1s		# retorna o marcador do vetor A1s para o inicio de A1s
	
	ret
	j mf_REPEAT		# voltar pra funï¿½ao de tocar as notas
