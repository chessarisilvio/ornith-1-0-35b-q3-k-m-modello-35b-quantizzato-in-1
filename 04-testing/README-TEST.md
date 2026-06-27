# Benchmark Suite per Ornith-1.0-35B Q3_K_M

Questa directory contiene script e istruzioni per eseguire benchmark e test qualitativi sul modello Ornith-1.0-35B quantizzato in Q3_K_M (~17GB VRAM).

## File principali

- `benchmark-suite.sh`: Script principale per eseguire la suite di test
- `.env.example` per configurare variabili d'ambiente.

## Prerequisiti

1. **llama-server compilato**: Assicurati di avere l'eseguibile `llama-server` disponibile nel percorso specificato dalla variabile `LLAMA_SERVER` (default: `./llama-server` relativo alla directory dello script).
2. **Modello GGUF**: Il modello `ornith-1.0-35b-q3_k_m.gguf` deve essere presente nella directory specificata da `MODEL_DIR` (default: `../03-setup/models` relativo allo script).
3. **Dipendenze**:
   - `bash` (standard)
   - `curl` per le richieste HTTP
   - `jq` per il parsing JSON (opzionale ma raccomandato)
   - `nvidia-smi` per il monitoraggio della VRAM
   - `bc` per i calcoli floating point

## Configurazione

Prima di eseguire lo script, crea un file `.env` nella stessa directory di `benchmark-suite.sh` (o esporta le variabili d'ambiente) con le seguenti variabili:

```bash
# Percorso alla directory contenente il modello GGUF
MODEL_DIR=/path/to/models

# Nome del file modello (default: ornith-1.0-35b-q3_k_m.gguf)
MODEL_FILENAME=ornith-1.0-35b-q3_k_m.gguf

# Percorso all'eseguibile llama-server (default: ./llama-server)
LLAMA_SERVER=/path/to/llama-server

# Host e port per il server llama (default: 0.0.0.0:8080)
HOST=0.0.0.0
PORT=8080

# Numero di esecuzioni per ogni test (default: 3)
NUM_RUNS=3

# Parametri di generazione
MAX_TOKENS=256
TEMPERATURE=0.7
TOP_P=0.9
SEED=42

# Configurazione split GPU (se necessario)
# LLAMA_SPLIT_MODE=1
# LLAMA_SPLIT_0=28   # layers su P40
# LLAMA_SPLIT_1=20   # layers su 3050
```

Vedi `../03-setup/.env.example` per un template.

## Esecuzione

```bash
# Rendi eseguibile lo script (se necessario)
chmod +x benchmark-suite.sh

# Esegui la suite di benchmark
./benchmark-suite.sh
```

Lo script:
1. Avvierà `llama-server` con il modello specificato
2. Eseguirà una serie di test predefiniti (coding, reasoning, creativo)
3. Misurerà latenza, token al secondo e utilizzo VRAM per ogni test
4. Ripeterà ogni test `NUM_RUNS` volte per ottenere medie più affidabili
5. Salverà tutti i risultati in una directory timestampata (es. `results_20260627_140000`)
6. Arrêterà il server al termine

## Struttura dei risultati

Dopo l'esecuzione, troverai nella directory `results_<timestamp>`:

- `benchmark.log`: Log completo dell'esecuzione
- `server.log`: Log del processo llama-server
- Per ogni test (es. `coding_simple`):
  - `coding_simple_run1_output.txt`: Risposta grezza del modello
  - `coding_simple_run1_metrics.json`: Metriche dettagliate (latenza, token previsti, token/s)
  - `coding_simple_run1_nvidia_smi.log`: Log del monitoraggio VRAM durante il test
  - `coding_simple_summary.json`: Riepilogo con medie su tutti i run

## Test inclusi

La suite esegue i seguenti test qualitativi:

1. **coding_simple**: Scrivi una funzione Python che calcola il fattoriale di un numero.
2. **coding_complex**: Implementa un algoritmo di ordinamento quicksort in C++ con commenti dettagliati.
3. **reasoning_math**: Se un treno viaggia a 80 km/h e deve percorrere 320 km, quanto tempo impiega? Spiega il calcolo.
4. **reasoning_logic**: Tutti i gatti sono animali. Alcuni animali sono pelosi. Possiamo concludere che tutti i gatti sono pelosi? Perché o perché no?
5. **creative_story**: Inizia una storia di fantascienza con la seguente frase: 'L'ultimo umano sulla Terra guardò il cielo e vide...'

## Personalizzazione

Per modificare i test o aggiungerne di nuovi:
1. Modifica l'array associativo `tests` nello script `benchmark-suite.sh`
2. Ogni elemento è una coppia `chiave="prompt da inviare al modello"`
3. Lo script eseguirà automaticamente il monitoraggio e la raccolta metriche

## Note importanti

- **Privacy**: Questo script non contiene path assoluti, credenziali o informazioni personali. Utilizza esclusivamente variabili d'ambiente o path relativi.
- **VRAM**: Il monitoraggio della VRAM utilizza `nvidia-smi` e richiede privilegi sufficienti per accedere alle statistiche GPU.
- **Precisione**: La stima dei token è approssimativa (basata sulla lunghezza del testo). Per misurazioni precise, utilizzare gli strumenti di profiling integrati in llama.cpp se disponibili.
- **Sicurezza**: Lo script non salva mai credenziali o token in chiaro. Tutte le configurazioni sensibili devono essere passate tramite variabili d'ambiente.

## Troubleshooting

- **Server non si avvia**: Verifica che `llama-server` sia eseguibile e che il percorso al modello sia corretto.
- **Connessione rifiutata**: Assicurati che il server sia in ascolto sull'host e porta specificati, e che non ci siano firewall che bloccano la connessione.
- **Timeout nei test**: Aumenta il valore di timeout nella funzione `start_server` se il tuo sistema impiega più tempo a caricare il modello.
- **Mancanza di jq o bc**: Installa queste dipendenze oppure lo script funzionerà comunque con funzionalità ridotte (output meno formattato).

## Licenza

Questo script è fornito così com'è, senza garanzie. Puoi modificarlo e distribuirlo liberamente rispettando le licenze dei componenti sottostanti (llama.cpp, ecc.).