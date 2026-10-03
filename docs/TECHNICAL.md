# Notas técnicas

## Formato do patch

O manifesto define:

```text
COPY_INSERT_V1_GZIP
```

Cada arquivo traduzido é reconstruído localmente a partir do arquivo original compatível e de um delta comprimido `.json.gz`.

## Dados do release v1.0.0

- Arquivos modificados: **160**
- Origem total: **33.604.782 bytes**
- Resultado total: **33.708.272 bytes**
- Patches comprimidos: **1.264.200 bytes**
- Dados inseridos: **1.555.261 bytes**
- Dados reaproveitados por cópia: **32.153.011 bytes**

## Integridade

Cada entrada do manifesto contém, entre outros dados:

- caminho do arquivo do jogo;
- SHA-256 da origem;
- SHA-256 do resultado;
- tamanho da origem;
- tamanho do resultado;
- caminho do patch;
- SHA-256 do patch;
- tamanho do patch.

Os 160 patches presentes neste repositório foram conferidos contra o manifesto antes da preparação deste pacote GitHub.

## Segurança operacional

O fluxo implementado pelo instalador inclui:

1. identificação da instalação;
2. classificação do estado dos arquivos;
3. bloqueio de arquivos desconhecidos;
4. backup;
5. aplicação do delta;
6. verificação do resultado;
7. rollback em caso de falha.

## Validação existente

O relatório original de validação está preservado em:

```text
docs/VALIDATION_REPORT.json
```

Ele registra validação offline do round-trip dos 160 arquivos e testes do fluxo de instalação/desinstalação em fixture Windows PowerShell 5.1.

O próprio relatório também registra que um teste de runtime do instalador no jogo não foi executado pelo builder naquela etapa.
