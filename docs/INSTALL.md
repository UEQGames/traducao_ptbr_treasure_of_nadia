# Instalação

## Requisitos

- Treasure of Nadia para Windows.
- Cópia legítima e compatível com os hashes do manifesto incluído.
- Windows PowerShell disponível no sistema.

## Passo a passo

1. Feche o jogo.
2. Baixe o pacote da versão desejada na área **Releases** do GitHub.
3. Extraia **todo** o conteúdo do ZIP para uma pasta.
4. Execute `1_VERIFICAR_PTBR.cmd`.
5. Aguarde a verificação dos arquivos.
6. Se a verificação for aprovada, execute `2_INSTALAR_PTBR.cmd`.
7. Caso seja solicitado, informe a pasta principal de Treasure of Nadia.

A pasta correta contém:

```text
www\data\System.json
```

8. Concluída a instalação, abra o jogo normalmente.

## Não force a instalação

O instalador bloqueia a operação quando encontra:

- uma build diferente da suportada;
- arquivos ausentes;
- arquivos modificados por outro mod;
- estado misto entre arquivos originais e traduzidos.

Esse bloqueio é intencional e evita corrupção da instalação.

## Desinstalação

1. Feche o jogo.
2. Execute `3_DESINSTALAR_PTBR.cmd`.
3. Informe a mesma pasta do jogo, se solicitado.

O backup fica em:

```text
.ptbr-nadia-backup\1.0.0
```

O desinstalador restaura os arquivos originais a partir desse backup.
