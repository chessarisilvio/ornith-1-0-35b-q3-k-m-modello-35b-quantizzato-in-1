# Ornith-1.0-35B Q3_K_M - Specifiche Tecniche

## Panoramica
- **Modello**: Ornith-1.0-35B (variante dense 35B, non MoE secondo post #8)
- **Famiglia**: Ornith-1.0 (rilasciata 25 giugno 2026 da DeepReinforce.AI)
- **Specializzazione**: Coding agente (agentic coding)
- **Architettura di base**: Basata su Gemma 4 e Qwen 3.5
- **Licenza**: MIT (pesi disponibili su Hugging Face: deepreinforce-ai/Ornith-1.0)
- **Quantizzazione**: Q3_K_M (~17 GB VRAM)
- **Verifica**: KLD-checked contro BF16

## Dettagli Tecnici
- **Tipo**: Dense 35B parametri (non MiE)
- **Footprint VRAM previsto**: ~17 GB con quantizzazione Q3_K_M
- **Confronti dichiarati**: Prestazioni coding/inferenza rispetto a Qwen3.6-35B
- **Caratteristiche note**: Self‑improving, self‑scaffolding, progettato per migliorare capacità di coding agente

## Fonti
- Annuncio ufficiale famiglia Ornith-1.0 (25 giugno 2026)
- Pagina modello su Hugging Face: deepreinforce-ai/Ornith-1.0
- Discussioni tecniche su benchmark preliminari contro Qwen3.6-35B

## Note per lo split GPU (P40 + RTX 3050)
- P40: 24 GB VRAM
- RTX 3050: 8 GB VRAM
- Totale disponibile: 32 GB
- Modello quantizzato Q3_K_M: ~17 GB → possibile caricamento singolo su P40 o split layer-wise se necessario.