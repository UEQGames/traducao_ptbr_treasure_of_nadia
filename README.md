# Treasure of Nadia — Tradução PT-BR

Tradução não oficial de **Treasure of Nadia** para **Português Brasileiro (PT-BR)**.

Este projeto distribui apenas **patches delta de tradução**. Ele não contém o jogo nem arquivos completos do jogo e requer uma cópia legítima e compatível de Treasure of Nadia.

## Status

- Versão da tradução: **1.0.0**
- Plataforma suportada: **Windows**
- Engine identificada: **RPG Maker MV 1.6.1**
- Arquivos modificados por delta: **160**
- Rotas textuais consolidadas no fechamento do projeto: **33.809**
- Instalação: manual, com verificação, backup e rollback

## Download

Para instalar a tradução, use o pacote pronto disponível em **GitHub Releases**.

Não é necessário baixar o código-fonte do repositório para instalar a tradução.

## Instalação rápida

1. Feche Treasure of Nadia.
2. Baixe a versão mais recente em **Releases**.
3. Extraia todo o conteúdo do ZIP.
4. Execute `1_VERIFICAR_PTBR.cmd`.
5. Se a verificação for aprovada, execute `2_INSTALAR_PTBR.cmd`.
6. Quando solicitado, informe a pasta principal do jogo — a pasta correta contém `www\data\System.json`.
7. Abra o jogo normalmente.

Consulte [docs/INSTALL.md](docs/INSTALL.md) para instruções completas.

## O que a tradução cobre

- diálogos e escolhas;
- itens e termos recorrentes;
- grande parte da interface, menus, mensagens e opções;
- revisão de consistência e terminologia;
- revisão de personalidade e resíduos em inglês;
- correções finais de interface;
- centralização do menu principal.

Alguns créditos, marcas e textos incorporados diretamente em imagens, além de casos sem método seguro de reinjeção, podem permanecer no idioma original.

## Segurança do patch

O instalador:

- verifica hashes SHA-256 antes de modificar arquivos;
- bloqueia builds desconhecidas ou arquivos já alterados por outros mods;
- cria backup dos arquivos afetados;
- valida o resultado após aplicar os deltas;
- executa rollback se ocorrer falha durante a instalação;
- permite restaurar os arquivos originais pelo desinstalador;
- não altera saves nem dados pessoais do jogador.

O instalador é um script PowerShell legível em `installer/ptbr-installer.ps1`. Não há executável `.exe` neste projeto.

## Compatibilidade

A tradução usa correspondência exata por hashes do jogo original. Se sua instalação não corresponder à build suportada, a operação será bloqueada por segurança.

Veja [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md).

## Desinstalação

Execute `3_DESINSTALAR_PTBR.cmd` usando a mesma cópia do pacote.

O backup é criado em:

```text
.ptbr-nadia-backup\1.0.0
```

## Estrutura técnica

O projeto usa patches delta no formato `COPY_INSERT_V1_GZIP`.

Resumo do manifesto:

| Item | Valor |
|---|---:|
| Arquivos modificados | 160 |
| Bytes de origem | 33.604.782 |
| Bytes finais | 33.708.272 |
| Patches comprimidos | 1.264.200 |
| Bytes inseridos | 1.555.261 |
| Bytes copiados | 32.153.011 |

Detalhes em [docs/TECHNICAL.md](docs/TECHNICAL.md).

## Suporte / bugs

Ao relatar um problema, informe:

- mensagem completa exibida pelo verificador/instalador;
- onde o jogo foi adquirido e qual build está instalada;
- arquivo indicado como incompatível;
- captura de tela, quando o problema for visual.

Use a aba **Issues** do GitHub.

## Direitos e distribuição

Treasure of Nadia, personagens, marcas, imagens, áudio, código e demais elementos do jogo pertencem aos respectivos detentores.

Este repositório contém uma tradução não oficial criada por fãs e os deltas necessários para aplicá-la a uma cópia legítima compatível.

Consulte [LICENSE_NOTICE.md](LICENSE_NOTICE.md) antes de redistribuir ou modificar este projeto.

## Aviso

Projeto independente e não oficial. Não possui afiliação ou endosso da NLT Media.
