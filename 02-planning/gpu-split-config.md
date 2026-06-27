# Configurazione Split GPU per Ornith-1.0-35B Q3_K_M

## Dati di base
- Modello: Ornith-1.0-35B (dense, non MoE)
- Quantizzazione: Q3_K_M
- Footprint VRAM stimato: ~17 GB
- GPU disponibili:
  - P40: 24 GB VRAM (cuda:0)
  - RTX 3050: 8 GB VRAM (cuda:1)
- Totale VRAM: 32 GB

## Stima layer
Architettura simile a Qwen3-35B → **48 layer** (valore di riferimento comune per modelli 35B dense).
Footprint per layer (Q3_K_M): 17 GB / 48 ≈ **0,354 GB/layer** (~360 MB).

## Possibili configurazioni

### A. Caricamento singolo su P40 (semplicità)
- Tutti i 48 layer su P40
- VRAM utilizzata: ~17 GB (lascia ~7 GB liberi su P40)
- 3050 inutilizzata
- Vantaggi: nessuna latenza di split, configurazione semplice
- Svantaggi: 3050 sprecata, carico elevato su P40

### B. Split layer-wise (bilanciamento carico)
- Distribuire layer contigui tra le due GPU
- Obiettivo: utilizzare entrambe le GPU per migliorare throughput e ridurre picco su P40

**Calcolo ottimale:**
- Capacità 3050: 8 GB → può ospitare circa **22 layer** (8 / 0,354 ≈ 22)
- Rimanenti layer su P40: 48 - 22 = **26 layer**
- VRAM stimata:
  - P40: 26 × 0,354 ≈ 9,2 GB
  - 3050: 22 × 0,354 ≈ 7,8 GB (leggermente sopra 8 GB, margine di sicurezza)
- Per stare sicuri entro 8 GB su 3050, assegnare **20 layer** a 3050 e **28 layer** a P40:
  - P40: 28 × 0,354 ≈ 9,9 GB
  - 3050: 20 × 0,354 ≈ 7,1 GB

**Configurazione consigliata (split 20/28):**
- P40 (GPU 0): 28 layer
- RTX 3050 (GPU 1): 20 layer

## Parametri llama.cpp (layer‑wise split)
Esempio di invocazione per `llama-cli` o `llama-server`:

```bash
# Variabili d'ambiente per split layer‑wise
export LLAMA_SPLIT_MODE=1          # 1 = layer-wise split
export LLAMA_SPLIT_0=28            # numero di layer sulla GPU 0 (P40)
export LLAMA_SPLIT_1=20            # numero di layer sulla GPU 1 (3050)
# oppure, se la versione usa un unico flag:
# export LLAMA_SPLIT="28:20"

# Esempio di esecuzione
./llama-cli -m ./models/ornith-1.0-35b-q3_k_m.gguf \
    -n 128 \
    --ctx-size 4096 \
    --temp 0.7 \
    --ngl 0   # ngl non usato quando split mode attivo; tenere a 0
```

> **Nota:** Alcune build richiedono di impostare `LLAMA_SPLIT_MODE=1` e poi passare lo split tramite `--split` o variabili `LLAMA_SPLIT_*`. Verificare la documentazione della propria compilazione.

## Stima delle prestazioni
- **Throughput atteso:** miglioramento rispetto al solo P40 grazie al parallelismo di layer.
- **Latenza per token:** leggermente aumentata dalla sincronizzazione tra GPU, ma compensata dal maggior numero di core CUDA attivi.
- **VRAM residua:** P40 ~14 GB liberi, 3050 ~0,9 GB liberi (possibile uso per KV cache aggiuntiva o batch più grandi).

## Raccomandazioni operative
1. Verificare che il binario llama.cpp sia compilato con supporto CUDA e split mode (`-DLLAMA_CUBLAS=on -DLLAMA_SPLIT_MODE=on`).
2.`)
2. Testare inizialmente con caricamento singolo su P40 per confermare correttezza del modello.
3. Passare alla configurazione split 20/28 e misurare tok/s con prompt standard.
4. Se si osserva instabilità, ridurre il numero di layer su 3050 (es. 16/32) finché non si ottiene stabilità.

## File di esempio .env (da non committare)
```dotenv
# .env.example – non includere in git
LLAMA_SPLIT_MODE=1
LLAMA_SPLIT_0=28
LLAMA_SPLIT_1=20
MODEL_PATH=./models/ornith-1.0-35b-q3_k_m.gguf
```

---
*Configurazione redatta il 2026-06-27 per la fase 2/6 del progetto Ornith-1.0-35B Q3_K_M.*