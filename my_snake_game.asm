######################################################################
#                           SNAKE-GAME                               #
######################################################################
#                Amanda Carolina Messer Siebeneichler                #
######################################################################
#       Keyboard and Display MMIO                                    #
#       Bitmap Display                                               #
#                                                                    #
#       Configurações do Bitmap Display:                             #
#       Unit Width in Pixels:     8                                  #
#       Unit Height in Pixels:    8                                  #
#       Display Width in Pixels:  512                                #
#       Display Height in Pixels: 512                                #
#       Base Address for Display: 0x10008000 ($gp)                   #
######################################################################

.data

larguraTela:          .word 64
alturaTela:           .word 64
verdeClaro:           .word 0x0022CC22
branco:               .word 0xFFFFFFFF
verdeEscuro:          .word 0xFF003300
vermelho:             .word 0xF23A0F
inicioCobraX:         .word 32
inicioCobraY:         .word 32
inicioCaudaX:         .word 32
inicioCaudaY:         .word 36
posicaoX:             .word 32
posicaoY:             .word 32
posicaoCaudaX:        .word 32
posicaoCaudaY:        .word 36
speed:                .word 150
direcao:              .word 0
frutaX:               .word 0
frutaY:               .word 0
posicaoEscritaArray:  .word 16
direcaoCauda:         .word 119
posicaoArray:         .word 0
direcaoArray:         .word 0:100
pontuacao:            .word 0
gameOver:             .asciiz "Você morreu... Sua pontuação: "
replay:               .asciiz "Você gostaria de tentar novamente?"

.text
###################################################################################
#                            Mapa de registradores                                #
###################################################################################
#  Nome    Descrição                                                              #
#  $t0     Posição X da cauda, incremento em crescimento para a direita/esquerda. #
#  $t1     Posição Y da cauda, incremento em crescimento para cima/baixo,         #
#               posição X da cobra e verificar direção da cauda                   #
#  $t2     Usado para armazenar a posição Y da cobra em verificaColisaoFruta.     #
#  $t3     Posição X da fruta (frutaX), a posição atual do array de posições      #
#               e para manipulação de valores no placar.                          #
#  $t4     Usado para armazenar a posição Y da fruta e no cálculo do placar.      #
#  $t5     Contador da pontuação.                                                 #
#  $a0     Usado como argumento para syscall e procedimentos.                     #
#  $a1     Usado como argumento para syscall, posição Y e pontuação em placar.    #
#  $a2     Usado para carregar a cor da cobra ou cor do fundo ao desenhar na tela,#
#               e argumento para syscall (som).                                   #
#  $a3     Usado para armazenar o valor do pixel da posição da fruta              #
#               e argumento para syscall (som).                                   #
#  $v0     Usado para armazenar valores de retorno de funções e syscalls          #
#  $gp     Base do Bitmap display e cálculo de endereços na tela.                 # 
#  $ra     Usado para armazenar o endereço de retorno para as funções.            #
###################################################################################

.include "numbers.asm"

main:
    lw $a0, larguraTela          # Carrega a largura da tela em unidades (64)
    lw $a1, alturaTela           # Carrega a altura da tela em unidades (64)
    mul $a1, $a1, $a0            # Calcula o número total de unidades (64 * 64), resultado em $a1
    mul $a1, $a1, 4              # Calcula em $a1 o total de bytes (número de unidades * 4 bytes por pixel)
    add $a1, $a1, $gp            # Define o endereço final do buffer de vídeo ($a1 = $a1 + $gp)
    lw $a0, verdeEscuro          # Carrega a cor de fundo em $a0
    jal preencheFundo            # Chama a função preencheFundo
    addi $t5, $zero, -1          # Inicializa $t5 com -1 (contador da pontuação)

bordaHorizontal:
    lw $t1, larguraTela          # Carrega a largura da tela em $t1
    mul $t1, $t1, 4              # Calcula o tamanho em bytes da largura da tela (largura * 4)
    addi $t3, $zero, 56          # Inicializa $t3 com 56 (valor fixo do campo de jogo) 
    mul $t3, $t3, 256            # Multiplica $t3 por 256 (n de bytes, 64 * 4), resultado em $t3
    lw $a3, verdeClaro           # Carrega a cor das bordas em $a3
    add $a0, $gp, $zero          # Inicializa $a0 com o valor de $gp (endereço inicial do buffer de vídeo)
    addi $t2, $zero, 0           # Inicializa $t2 com 0 (usado como contador no loop)

loopBordaHorizontal:
    beq $t2, $t1, bordaVertical  # Se $t2 for igual a $t1, salta para 'paredes'
    sw $a3, 0($a0)               # Armazena a cor da borda no endereço apontado por $a0
    add $a0, $gp, $t3            # Atualiza $a0 com $gp + $t3 (cálculo do próximo endereço)
    sw $a3, 0($a0)               # Armazena a cor no novo endereço apontado por $a0
    addi $t3, $t3, 4             # Incrementa $t3 em 4
    addi $t2, $t2, 4             # Incrementa $t2 em 4
    add $a0, $gp, $t2            # Atualiza $a0 com $gp + $t2
    j loopBordaHorizontal        # Volta para o início do loop

bordaVertical:
    addi $t2, $zero, 0           # Inicializa $t2 com 0
    addi $t3, $zero, 252         # Inicializa $t3 com 252 (valor fixo do campo de jogo, 256 - 4)

loopBordaVertical:
    beq $t2, 14592, obstaculosH  # Se $t2 for igual a 14592  (256 * (56 + 1)), salta para 'obstaculosH'
    add $a0, $gp, $t2            # Atualiza $a0 com o valor de $gp + $t2 (cálculo do endereço do buffer de vídeo)
    sw $a3, 0($a0)               # Armazena a cor no endereço apontado por $a0
    add $a0, $gp, $t3            # Atualiza $a0 com $gp + $t3
    sw $a3, 0($a0)               # Armazena a cor no novo endereço apontado por $a0
    addi $t2, $t2, 256           # Incrementa $t2 em 256 (pula uma linha)
    addi $t3, $t3, 256           # Incrementa $t3 em 256 (pula uma linha)
    j loopBordaVertical          # Volta para o início do loop

obstaculosH:
    addi $t2, $zero, 1560        # Inicializa $t2 com 1560 (posição dos obstáculos)
    addi $t3, $zero, 12964       # Inicializa $t3 com 12964 (posição dos obstáculos)

loopObstaculosH:
    beq $t2, 1624, obstaculosV   # Se $t2 for igual a 1624 (posição dos obstáculos), salta para 'obstaculosV'
    add $a0, $gp, $t2            # Atualiza $a0 com o valor de $gp + $t2 (cálculo do endereço do buffer de vídeo)
    sw $a3, 0($a0)               # Armazena o valor de $a3 no endereço apontado por $a0
    add $a0, $gp, $t3            # Atualiza $a0 com $gp + $t3
    sw $a3, 0($a0)               # Armazena novamente o valor de $a3 no novo endereço apontado por $a0
    addi $t2, $t2, 4             # Incrementa $t2 em 4 (avança um pixel)
    addi $t3, $t3, 4             # Incrementa $t3 em 4 (avança um pixel)
    j loopObstaculosH            # Volta para o início do loop

obstaculosV:
    addi $t2, $zero, 1560        # Inicializa $t2 com 1560 (posição dos obstáculos)
    addi $t3, $zero, 9184        # Inicializa $t3 com 9184 (posição dos obstáculos)

loopObstaculosV:
    beq $t2, 5400, geraCobra     # Se $t2 for igual a 5400, salta para 'geraCobra'
    add $a0, $gp, $t2            # Atualiza $a0 com o valor de $gp + $t2 (cálculo do endereço do buffer de vídeo)
    sw $a3, 0($a0)               # Armazena o valor de $a3 no endereço apontado por $a0
    add $a0, $gp, $t3            # Atualiza $a0 com $gp + $t3
    sw $a3, 0($a0)               # Armazena novamente o valor de $a3 no novo endereço apontado por $a0
    addi $t2, $t2, 256           # Incrementa $t2 em 256 (avança uma linha)
    addi $t3, $t3, 256           # Incrementa $t3 em 256 (avança uma linha)
    j loopObstaculosV            # Volta para o início do loop
    
preencheFundo:
    # Carrega as dimensões da tela
    lw $a1, larguraTela          # Carrega a largura da tela em $a1
    lw $a2, alturaTela           # Carrega a altura da tela em $a2
    
    # Calcula o número total de posições a serem preenchidas
    mul $a2, $a1, $a2            # Multiplica a largura pela altura
    sll $a2, $a2, 2              # Multiplica o número total por 4 (considerando 4 bytes por pixel)

    # Calcula o endereço final da área a ser preenchida
    add $a2, $a2, $gp            # Adiciona o ponteiro global ($gp) para obter o endereço final
    
    # Inicializa o ponteiro para o início da memória a ser preenchida
    add $a1, $zero, $gp          # Define $a1 como $gp (endereço inicial do buffer de vídeo)

# Loop para preencher a memória com a cor de fundo
loopPreencheFundo:    
    sw $a0, 0($a1)               # Armazena a cor (em $a0) no endereço atual apontado por $a1
    addi $a1, $a1, 4             # Incrementa o ponteiro em 4 bytes (tamanho de cada posição de memória)
    
    # Verifica se alcançou o endereço final
    blt $a1, $a2, loopPreencheFundo # Se $a1 for menor que $a2, continua preenchendo
    
    jr $ra                       # Retorna para a função chamadora

geraCobra:
    lw $a0, inicioCobraX         # Carrega a posição inicial X da cobra em $a0
    lw $a1, inicioCobraY         # Carrega a posição inicial Y da cobra em $a1
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço do inicio da cobra
    add $a0, $v0, $zero          # Copia o valor de $v0 (resultado de 'pegaEndereco') para $a0
    lw $a2, verdeClaro           # Carrega a cor da cobra em $a2 
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel no endereço definido por $a0

    lw $a0, inicioCobraX         # Carrega novamente a posição inicial X da cobra em $a0
    addi $a1, $a1, 1             # Incrementa a posição Y da cobra em 1 (movimento vertical)
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o novo endereço
    add $a0, $v0, $zero          # Copia o valor de $v0 para $a0
    lw $a2, verdeClaro           # Carrega a cor da cobra em $a2 
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel

    lw $a0, inicioCobraX         # Carrega novamente a posição inicial X da cobra em $a0
    addi $a1, $a1, 1             # Incrementa a posição Y da cobra em 1
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o novo endereço
    add $a0, $v0, $zero          # Copia o valor de $v0 para $a0
    lw $a2, verdeClaro           # Carrega a cor da cobra em $a2 
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel

    lw $a0, inicioCobraX         # Carrega novamente a posição inicial X da cobra em $a0
    addi $a1, $a1, 1             # Incrementa a posição Y da cobra em 1
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o novo endereço
    add $a0, $v0, $zero          # Copia o valor de $v0 para $a0
    lw $a2, verdeClaro           # Carrega a cor da cobra em $a2 
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel

    addi $t1, $zero, 119         # Inicializa $t1 com o valor 119 (direção inicial da cobra)
    sw $t1, direcao              # Armazena o valor de $t1 em 'direcao' (direção da cobra)
    j iniciaDados                # Salta para 'iniciaDados'

iniciaDados:
    addi $t0, $zero, 0           # Inicializa $t0 com 0 (índice do array de direções)
    sw $t1, direcaoArray($t0)    # Armazena o valor de $t1 na posição do array 'direcaoArray' no índice $t0
    addi $t0, $t0, 4             # Incrementa $t0 em 4 (próximo índice do array)
    sw $t1, direcaoArray($t0)    # Armazena o valor de $t1 na próxima posição do array 'direcaoArray'
    addi $t0, $t0, 4             # Incrementa $t0 em 4 (próximo índice do array)
    sw $t1, direcaoArray($t0)    # Armazena o valor de $t1 na próxima posição do array 'direcaoArray'
    addi $t0, $t0, 4             # Incrementa $t0 em 4 (próximo índice do array)
    sw $t1, direcaoArray($t0)    # Armazena o valor de $t1 na próxima posição do array 'direcaoArray'
    j geraCauda                  # Salta para 'geraCauda'

geraCauda:
    lw $a0, inicioCaudaX         # Carrega a posição inicial X da cauda em $a0
    lw $a1, inicioCaudaY         # Carrega a posição inicial Y da cauda em $a1
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço do inicio da cauda
    add $a0, $v0, $zero          # Copia o valor de $v0 para $a0 (endereço de memória para desenhar a cauda)
    lw $a2, verdeEscuro          # Carrega a cor de fundo em $a2
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel
    j criaFruta                  # Salta para 'criaFruta'

pintaPixel:
    sw $a2, 0($a0)               # Armazena o valor de $a2 (cor) no endereço apontado por $a0
    jr $ra                       # Retorna para a função chamadora

pegaEndereco:
    lw $v0, alturaTela           # Carrega a altura da tela em $v0
    mul $v0, $v0, $a1            # Calcula a posição vertical ($alturaTela * $a1)
    add $v0, $v0, $a0            # Adiciona a posição horizontal ($a0)
    mul $v0, $v0, 4              # Multiplica por 4 (cada unidade tem 4 bytes)
    add $v0, $v0, $gp            # Adiciona a posição base ($gp)
    jr $ra                       # Retorna para a função chamadora

criaFruta:
    # Gera o valor aleatório para frutaX entre 1 e 62
    li $v0, 42                   # Syscall 42: Geração de número aleatório
    li $a1, 62                   # Limite superior (não inclusivo)
    syscall                      # $a0 agora tem um valor entre 0 e 61
    addiu $a0, $a0, 1            # Ajusta para ficar entre 1 e 62
    sw $a0, frutaX               # Armazena em frutaX

    # Gera o valor aleatório para frutaY entre 1 e 54
    li $v0, 42                   # Syscall 42: Geração de número aleatório
    li $a1, 54                   # Limite superior (não inclusivo)
    syscall                      # $a0 agora tem um valor entre 0 e 53
    addiu $a0, $a0, 1            # Ajusta para ficar entre 1 e 54
    sw $a0, frutaY               # Armazena em frutaY

    # Calcula o endereço da posição da fruta
    lw $a0, frutaX               # Carrega frutaX
    lw $a1, frutaY               # Carrega frutaY
    jal pegaEndereco             # Calcula o endereço na memória
    add $a0, $zero, $v0          # Endereço da fruta em $a0

    # Verifica se a fruta não colide com a cobra ou alguma parede
    lw $a2, verdeClaro           # Cor da cobra em $a2
    lw $a3, 0($a0)               # Valor do pixel na posição da fruta
    beq $a2, $a3, criaFruta      # Se colide com a cobra, gera outra fruta

    # Incrementa um contador (se necessário)
    addi $t5, $t5, 1             # Incrementa $t5 em 1

    # Desenha a fruta na tela
    lw $a2, vermelho             # Cor da fruta
    jal pintaPixel               # Chama a função para desenhar a fruta
    jal placar                   # Atualiza o placar

    # Ajusta a velocidade (exemplo de decremento)
    lw $t1, speed                # Carrega a velocidade atual
    addi $t1, $t1, -5            # Decrementa a velocidade em 10 unidades
    sw $t1, speed                # Armazena a nova velocidade

    # Syscall para sons
    li $v0, 31               
    li $a0, 79                
    li $a1, 150               
    li $a2, 7                 
    li $a3, 127               
    syscall                   

    li $a0, 96                
    li $a1, 250               
    li $a2, 7                 
    li $a3, 127               
    syscall                   

    # Retorna ao loop principal
    j checaEntrada               # Salta para 'checaEntrada'

checaEntrada:
    lw $t0, 0xFFFF0004           # Ler o valor da entrada de teclado

    li $t1, 100                  # Presume direita
    bne $t0, $t1, checaW         # Se não for 'D', verifica 'W'
    sw $t1, direcao              # Armazena direção 'D' se for o caso
    j processaDirecao

checaW:
    li $t1, 119                  # Presume subir
    bne $t0, $t1, checkA         # Se não for 'W', verifica 'A'
    sw $t1, direcao              # Armazena direção 'W' se for o caso
    j processaDirecao

checaA:
    li $t1, 97                   # Presume esquerda
    bne $t0, $t1, checkS         # Se não for 'A', verifica 'S'
    sw $t1, direcao              # Armazena direção 'A' se for o caso
    j processaDirecao

checaS:
    li $t1, 115                  # Presume descer
    bne $t0, $t1, processaDirecao # Se não for 'S', pula para processar direção atual
    sw $t1, direcao              # Armazena direção 'S' se for o caso
    j processaDirecao

processaDirecao:
    lw $t1, direcao              # Carrega a direção atual da memória
    beq $t1, 100, direita        # Se a direção for direita (D)
    beq $t1, 119, subir          # Se a direção for subir (W)
    beq $t1, 97, esquerda        # Se a direção for esquerda (A)
    beq $t1, 115, descer         # Se a direção for descer (S)
    j checaEntrada               # Se nenhuma tecla válida, volta a checar entrada

subir:
    lw $a0, speed                # Carrega a velocidade atual em $a0
    jal velocidade               # Debounce
    lw $a0, posicaoX             # Carrega a posição X atual em $a0
    lw $a1, posicaoY             # Carrega a posição Y atual em $a1
    lw $t0, posicaoY             # Carrega a posição Y em $t0
    addiu $t0, $t0, -1           # Decrementa $t0 (posição Y) em 1 (movimento para cima)
    sw $t0, posicaoY             # Armazena a nova posição Y
    add $a1, $t0, $zero          # Atualiza $a1 com o valor da nova posição Y
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço de memória
    add $a0, $zero, $v0          # Copia o valor de $v0 (endereço obtido) para $a0
    lw $t4, 0($a0)               # Carrega o valor no endereço de memória para $t4
    lw $a2, verdeClaro           # Carrega a cor da cobra em $a2
    beq $t4, $a2, exit           # Se as cores forem iguais salta para 'exit'
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel
    j salvaDirecao               # Salta para 'salvaDirecao'

descer:
    lw $a0, speed                # Carrega a velocidade atual em $a0
    jal velocidade               # Debounce
    lw $a0, posicaoX             # Carrega a posição X atual em $a0
    lw $a1, posicaoY             # Carrega a posição Y atual em $a1
    lw $t0, posicaoY             # Carrega a posição Y em $t0
    addiu $t0, $t0, 1            # Incrementa $t0 (posição Y) em 1 (movimento para baixo)
    sw $t0, posicaoY             # Armazena a nova posição Y
    add $a1, $t0, $zero          # Atualiza $a1 com o valor da nova posição Y
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço de memória
    add $a0, $zero, $v0          # Copia o valor de $v0 (endereço obtido) para $a0
    lw $t4, 0($a0)               # Carrega o valor no endereço de memória para $t4
    lw $a2, verdeClaro           # Carrega a cor da cobra em $a2
    beq $t4, $a2, exit           # Se as cores forem iguais salta para 'exit'
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel
    j salvaDirecao               # Salta para 'salvaDirecao'

direita:
    lw $a0, speed                # Carrega a velocidade atual em $a0
    jal velocidade               # Debounce
    lw $t0, posicaoX             # Carrega a posição X atual em $t0
    addiu $t0, $t0, 1            # Incrementa $t0 (posição X) em 1 (movimento para a direita)
    sw $t0, posicaoX             # Armazena a nova posição X
    add $a0, $t0, $zero          # Atualiza $a0 com o valor da nova posição X
    lw $a1, posicaoY             # Carrega a posição Y em $a1
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço de memória
    add $a0, $zero, $v0          # Copia o valor de $v0 (endereço obtido) para $a0
    lw $t4, 0($a0)               # Carrega o valor no endereço de memória para $t4
    lw $a2, verdeClaro           # Carrega a cor da cobra em $a2
    beq $t4, $a2, exit           # Se as cores forem iguais salta para 'exit'
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel
    j salvaDirecao               # Salta para 'salvaDirecao'

esquerda:
    lw $a0, speed                # Carrega a velocidade atual em $a0
    jal velocidade               # Debounce
    lw $t0, posicaoX             # Carrega a posição X atual em $t0
    addiu $t0, $t0, -1           # Decrementa $t0 (posição X) em 1 (movimento para a esquerda)
    sw $t0, posicaoX             # Armazena a nova posição X
    add $a0, $t0, $zero          # Atualiza $a0 com o valor da nova posição X
    lw $a1, posicaoY             # Carrega a posição Y em $a1
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço de memória
    add $a0, $zero, $v0          # Copia o valor de $v0 (endereço obtido) para $a0
    lw $t4, 0($a0)               # Carrega o valor no endereço de memória para $t4
    lw $a2, verdeClaro           # Carrega a cor da cobra em $a2
    beq $t4, $a2, exit           # Se as cores forem iguais salta para 'exit'
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel
    j salvaDirecao               # Salta para 'salvaDirecao'

velocidade:
    li $v0, 32                   # Syscall 32: sleep
    syscall                      # Executa o sleep
    jr $ra                       # Retorna para a função chamadora

salvaDirecao:
    lw $t0, posicaoEscritaArray  # Carrega a posição de escrita do array em $t0
    lw $t3, direcao              # Carrega a direção atual em $t3
    sw $t3, direcaoArray($t0)    # Armazena a direção atual no array 'direcaoArray' na posição $t0
    beq $t0, 396, resetPosicaoEscrita # Se $t0 for igual a 396 (fim do array, 4 * 99), salta para 'resetPosicaoEscrita'
    addi $t0, $t0, 4             # Incrementa $t0 em 4 (próxima posição no array)
    sw $t0, posicaoEscritaArray  # Armazena o valor atualizado em 'posicaoEscritaArray'
    j checaCauda                 # Salta para 'checaCauda'

resetPosicaoEscrita:
    addi $t2, $zero, 0           # Inicializa $t2 com 0
    sw $t2, posicaoEscritaArray  # Reseta a posição de escrita do array para 0
    j checaCauda                 # Salta para 'checaCauda'

checaCauda:
    jal verificaColisaoFruta     # Chama a função 'verificaColisaoFruta' para verificar se houve colisão com a fruta
    lw $t0, posicaoArray         # Carrega a posição atual da cauda do array em $t0
    lw $t1, direcaoArray($t0)    # Carrega a direção da cauda do array na posição $t0 em $t1
    sw $t1, direcaoCauda         # Armazena a direção atual em 'direcaoCauda'
    beq $t0, 396, resetPosicao   # Se $t0 for igual a 396 (fim do array), salta para 'resetPosicao'
    addi $t0, $t0, 4             # Incrementa $t0 em 4 (próxima posição no array)
    sw $t0, posicaoArray         # Armazena o valor atualizado em 'posicaoArray'
    j moveCauda                  # Salta para 'moveCauda'

resetPosicao:
    addi $t2, $zero, 0           # Inicializa $t2 com 0
    sw $t2, posicaoArray         # Reseta a posição da cauda do array para 0
    j moveCauda                  # Salta para 'moveCauda'

verificaColisaoFruta:
    lw $t1, posicaoX             # Carrega a posição X da cobra em $t1
    lw $t3, frutaX               # Carrega a posição X da fruta em $t3
    lw $t2, posicaoY             # Carrega a posição Y da cobra em $t2
    lw $t4, frutaY               # Carrega a posição Y da fruta em $t4
    beq $t1, $t3, verificaColisaoFrutaY # Se a posição X da cobra for igual à da fruta, verifica Y
    addi $v0, $zero, 1           # Caso contrário, indica que não houve colisão ($v0 = 1)
    jr $ra                       # Retorna para a função chamadora

verificaColisaoFrutaY:
    beq $t2, $t4, adquiriuFruta  # Se a posição Y da cobra for igual à da fruta, a fruta foi adquirida
    addi $v0, $zero, 1           # Caso contrário, indica que não houve colisão ($v0 = 1)
    jr $ra                       # Retorna para a função chamadora

moveCauda:
    lw $t1, direcaoCauda         # Carrega a direção da cauda em $t1
    beq $t1, 119, subirCauda     # Se $t1 for igual a 119 (cima), salta para 'subirCauda'
    beq $t1, 115, descerCauda    # Se $t1 for igual a 115 (baixo), salta para 'descerCauda'
    beq $t1, 100, direitaCauda   # Se $t1 for igual a 100 (direita), salta para 'direitaCauda'
    beq $t1, 97, esquerdaCauda   # Se $t1 for igual a 97 (esquerda), salta para 'esquerdaCauda'

descerCauda:
    lw $a0, posicaoCaudaX        # Carrega a posição X da cauda em $a0
    lw $a1, posicaoCaudaY        # Carrega a posição Y da cauda em $a1
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço da posição atual
    add $a0, $zero, $v0          # Copia o valor de $v0 (endereço) para $a0
    lw $a2, verdeEscuro          # Carrega a cor de fundo em $a2
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel na posição atual
    lw $t0, posicaoCaudaY        # Carrega a posição Y da cauda em $t0
    addi $t0, $t0, 1             # Incrementa $t0 em 1 (movimento para baixo)
    sw $t0, posicaoCaudaY        # Armazena a nova posição Y da cauda
    j checaEntrada               # Salta para 'checaEntrada'

subirCauda:
    lw $a0, posicaoCaudaX        # Carrega a posição X da cauda em $a0
    lw $a1, posicaoCaudaY        # Carrega a posição Y da cauda em $a1
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço da posição atual
    add $a0, $zero, $v0          # Copia o valor de $v0 (endereço) para $a0
    lw $a2, verdeEscuro          # Carrega a cor de fundo em $a2
    jal pintaPixel               # Chama a função 'pintaPixel' para pintar o pixel na posição atual
    lw $t0, posicaoCaudaY        # Carrega a posição Y da cauda em $t0
    addiu $t0, $t0, -1           # Decrementa $t0 em 1 (movimento para cima)
    sw $t0, posicaoCaudaY        # Armazena a nova posição Y da cauda
    j checaEntrada               # Salta para 'checaEntrada'

direitaCauda:
    # Atualiza a posição da cauda primeiro
    lw $t0, posicaoCaudaX        # Carrega a posição X atual da cauda em $t0
    addiu $t0, $t0, 1            # Incrementa a posição X em 1 (movimento para a direita)
    sw $t0, posicaoCaudaX        # Armazena a nova posição X

    # Carrega as novas coordenadas
    lw $a0, posicaoCaudaX        # Carrega a nova posição X da cauda em $a0
    lw $a1, posicaoCaudaY        # Carrega a posição Y da cauda em $a1 (permanece a mesma)

    # Obtém o endereço da posição antiga
    addiu $t1, $t0, -1           # Calcula a posição X antiga (t0 - 1)
    move $a0, $t1                # Copia a posição X antiga para $a0
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço da posição antiga

    # Apaga o pixel na posição antiga
    add $a0, $zero, $v0          # Copia o valor do endereço obtido ($v0) para $a0
    lw $a2, verdeEscuro          # Carrega a cor de fundo em $a2 (usada para apagar o pixel)
    jal pintaPixel               # Chama a função 'pintaPixel' para apagar o pixel na posição antiga

    j checaEntrada               # Salta para 'checaEntrada'

esquerdaCauda:
    # Atualiza a posição da cauda primeiro
    lw $t0, posicaoCaudaX        # Carrega a posição X atual da cauda em $t0
    addiu $t0, $t0, -1           # Decrementa a posição X em 1 (movimento para a esquerda)
    sw $t0, posicaoCaudaX        # Armazena a nova posição X

    # Carrega as novas coordenadas
    lw $a0, posicaoCaudaX        # Carrega a nova posição X da cauda em $a0
    lw $a1, posicaoCaudaY        # Carrega a posição Y da cauda em $a1 (permanece a mesma)

    # Obtém o endereço da posição antiga
    addiu $t1, $t0, 1            # Calcula a posição X antiga (t0 + 1)
    move $a0, $t1                # Copia a posição X antiga para $a0
    jal pegaEndereco             # Chama a função 'pegaEndereco' para obter o endereço da posição antiga

    # Apaga o pixel na posição antiga
    add $a0, $zero, $v0          # Copia o valor do endereço obtido ($v0) para $a0
    lw $a2, verdeEscuro          # Carrega a cor de fundo em $a2 (usada para apagar o pixel)
    jal pintaPixel               # Chama a função 'pintaPixel' para apagar o pixel na posição antiga

    j checaEntrada               # Salta para 'checaEntrada'

adquiriuFruta:
    move $a0, $t3                # Move a posição X da fruta para $a0
    lw $t3, posicaoArray         # Carrega a posição atual do array de posições
    beqz $t3, vaiProFimDoArray   # Se $t3 for zero, salta para o fim do array (vaiProFimDoArray)
    addi $t3, $t3, -4            # Caso contrário, decrementa $t3 em 4
    j cresceCobra                # Salta

vaiProFimDoArray:
    addi $t3, $zero, 396         # Inicializa $t3 com 396 (para indicar o fim do array)
    j cresceCobra
    
cresceCobra:
    sw $t3, posicaoArray         # Armazena a posição atual da cobra em 'posicaoArray'
    lw $t1, direcaoCauda         # Carrega a direção atual da cauda em $t1
    beq $t1, 119, cresceParaBaixo # Se $t1 for W, salta para 'cresceParaBaixo'
    beq $t1, 115, cresceParaCima  # Se $t1 for S, salta para 'cresceParaCima'
    beq $t1, 100, cresceParaEsquerda # Se $t1 for D, salta para 'cresceParaEsquerda'
    beq $t1, 97, cresceParaDireita # Se $t1 for A, salta para 'cresceParaDireita'

cresceParaBaixo:
    # Atualiza a posição da cauda
    lw $t1, posicaoCaudaY
    addiu $t1, $t1, 1            # Incrementa posicaoCaudaY
    sw $t1, posicaoCaudaY

    # Carrega as coordenadas da nova posição
    lw $a0, posicaoCaudaX        # $a0 = posicaoCaudaX (posição X da cauda permanece a mesma)
    move $a1, $t1                # $a1 = posicaoCaudaY (nova posição Y da cauda)
 
    # Obtém o endereço da nova posição da cauda
    jal pegaEndereco
    move $a0, $v0                # $a0 = endereço da nova posição

    # Gera uma nova fruta e continua o jogo
    jal criaFruta
    j checaEntrada

cresceParaCima:
    # Atualiza a posição da cauda
    lw $t1, posicaoCaudaY
    addiu $t1, $t1, -1           # Decrementa posicaoCaudaY
    sw $t1, posicaoCaudaY

    # Carrega as coordenadas da nova posição
    lw $a0, posicaoCaudaX        # $a0 = posicaoCaudaX (posição X da cauda permanece a mesma)
    move $a1, $t1                # $a1 = posicaoCaudaY (nova posição Y da cauda)

    # Obtém o endereço da nova posição da cauda
    jal pegaEndereco
    move $a0, $v0                # $a0 = endereço da nova posição

    # Gera uma nova fruta e continua o jogo
    jal criaFruta
    j checaEntrada

cresceParaDireita:
    # Atualiza a posição da cauda
    lw $t0, posicaoCaudaX
    addiu $t0, $t0, 1            # Incrementa posicaoCaudaX
    sw $t0, posicaoCaudaX

    # Carrega as coordenadas da nova posição
    move $a0, $t0                # $a0 = posicaoCaudaX (nova posição X da cauda)
    lw $a1, posicaoCaudaY        # $a1 = posicaoCaudaY (posição Y da cauda permanece a mesma)

    # Obtém o endereço da nova posição da cauda
    jal pegaEndereco
    move $a0, $v0                # $a0 = endereço da nova posição

    # Gera uma nova fruta e continua o jogo
    jal criaFruta
    j checaEntrada

cresceParaEsquerda:
    # Atualiza a posição da cauda
    lw $t0, posicaoCaudaX
    addiu $t0, $t0, -1           # Decrementa posicaoCaudaX
    sw $t0, posicaoCaudaX

    # Carrega as coordenadas da nova posição
    move $a0, $t0                # $a0 = posicaoCaudaX (nova posição X da cauda)
    lw $a1, posicaoCaudaY        # $a1 = posicaoCaudaY (posição Y da cauda permanece a mesma)

    # Obtém o endereço da nova posição da cauda
    jal pegaEndereco
    move $a0, $v0                # $a0 = endereço da nova posição

   # Gera uma nova fruta e continua o jogo
    jal criaFruta
    j checaEntrada

placar:
    div $t4, $t5, 10             # Divide $t5 por 10 e armazena o resultado em $t4 (parte inteira da divisão)
    mul $t3, $t4, 10             # Multiplica $t4 por 10 e armazena o resultado em $t3
    sub $t3, $t5, $t3            # Subtrai $t3 de $t5 para obter o resto (módulo da divisão por 10)

    add $a0, $gp, $zero          # Define $a0 como $gp 
    lw $a2, branco               # Carrega a cor da cobra em $a2
    lw $a3, verdeEscuro          # Carrega a cor do fundo em $a3

    # Verifica o valor do resto e, se for igual a qualquer número entre 0 e 9, salta para o rótulo 'zero'
    beq $t3, 0, zero
    beq $t3, 1, zero
    beq $t3, 2, zero
    beq $t3, 3, zero
    beq $t3, 4, zero
    beq $t3, 5, zero
    beq $t3, 6, zero
    beq $t3, 7, zero
    beq $t3, 8, zero
    beq $t3, 9, zero

placar2:
    div $t4, $t5, 10
    add $a0, $gp, $zero
    lw $a2, branco
    lw $a3, verdeEscuro
    beq $t4, 0, zero2
    beq $t4, 1, zero2
    beq $t4, 2, zero2
    beq $t4, 3, zero2
    beq $t4, 4, zero2
    beq $t4, 5, zero2
    beq $t4, 6, zero2
    beq $t4, 7, zero2
    beq $t4, 8, zero2
    beq $t4, 9, zero2

exit:
    # Syscall 31: Gera sons
    li $v0, 31
    li $a0, 28
    li $a1, 250
    li $a2, 32
    li $a3, 127
    syscall                      # Executa o syscall 31 para gerar som

    # Outro som gerado
    li $a0, 33
    li $a1, 250
    li $a2, 32
    li $a3, 127
    syscall                      # Executa o syscall 31 para gerar som

    # Outro som gerado
    li $a0, 47
    li $a1, 1000
    li $a2, 32
    li $a3, 127
    syscall                      # Executa o syscall 31 para gerar som

    # Mensagem de fim de jogo
    li $v0, 56                   # Syscall para imprimir mensagem
    la $a0, gameOver             # Carrega o endereço da mensagem "gameOver" em $a0
    sw $t5, pontuacao            # Armazena o valor de $t5 (pontuação) em 'pontuacao'
    lw $a1, pontuacao            # Carrega a pontuação em $a1
    syscall                      # Executa o syscall para imprimir "gameOver" e a pontuação
    
    li $v0, 50                   # Syscall de sim/não
    la $a0, replay               # Carrega o endereço da mensagem "replay" em $a0
    syscall

    beqz $a0, resetGame
    
    li $v0, 10
    syscall

resetGame:
    li $t0, 32                   # Carrega o valor 32 em $t0
    sw $t0, posicaoX             # Reseta posicaoX para 32
    sw $t0, posicaoY             # Reseta posicaoY para 32
    sw $t0, posicaoCaudaX        # Reseta posicaoCaudaX para 32
    
    li $t0, 36                   # Carrega o valor 36 em $t0
    sw $t0, posicaoCaudaY        # Reseta posicaoCaudaY para 36

    li $t0, 150                  # Carrega o valor 150 em $t0
    sw $t0, speed                # Reseta speed para 150

    li $t0, 0                    # Carrega o valor 0 em $t0
    sw $t0, frutaX               # Reseta frutaX para 0
    sw $t0, frutaY               # Reseta frutaY para 0
    sw $t0, posicaoEscritaArray  # Reseta posicaoEscritaArray para 0
    sw $t0, posicaoArray         # Reseta posicaoArray para 0
    sw $t0, direcaoArray         # Reseta direcaoArray para 0

    li $t0, 16                   # Carrega o valor 16 em $t0
    sw $t0, posicaoEscritaArray  # Reseta posicaoEscritaArray para 16

    li $t0, 119                  # Carrega o valor 87 em $t0
    sw $t0, direcao              # Reseta direcao para 0 (parado)
    sw $t0, direcaoCauda         # Reseta direcaoCauda para 87 (W)

    li $t0, 0                    # Carrega o valor 0 em $t0
    sw $t0, pontuacao            # Reseta pontuação para 0

    j main                       # Retorna da função
