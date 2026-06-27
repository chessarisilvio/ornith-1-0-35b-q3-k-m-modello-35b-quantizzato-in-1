# Ornith-1.0-35B Q3_K_M: modello 35B quantizzato in 17GB VRAM

## Descrizione del progetto

Questo progetto documenta l'acquisizione, la configurazione e la valutazione iniziale del modello Ornith-1.0-35B nella variante quantizzata Q3_K_M, progettato per operare entro circa 17 GB di VRAM. Il modello Ornith-1.0-35B è un modello dense da 35 miliardi di parametri, rilasciato da DeepReinforce.AI il 25 giugno 2026, con specializzazione nel coding agente (agentic coding) e architettura ispirata a Gemma 4 e Qwen 3.5.

L'obiettivo del progetto è stato verificare la fattibilità di eseguire questo modello su una configurazione hardware ibrida composta da una NVIDIA Tesla P40 (24 GB VRAM) e una NVIDIA RTX 3050 (8 GB VRAM), sfruttando lo split delle layer tra le due GPU per rimanere entro i limiti di memoria disponibili.

## Struttura del repository

Il repository è organizzato nelle seguenti directory:

- `01-research`: contiene le specifiche tecniche raccolte dal modello (`ornith-specs.md`).
- `02-planning`: include l'analisi dello split GPU e la pianificazione dell'utilizzo della memoria (`gpu-split-config.md`).
- `03-setup`: script di download e file di configurazione per l'avvio del modello (`download-setup.sh`, `config.json`).
- `04-testing`: suite di benchmark e manuali di test per verificare le prestazioni (`benchmark-suite.sh`, `README-TEST.md`).
- `05-analysis`: rapporto comparativo teorico tra Ornith-1.0-35B e Qwen3.6-35B (`comparative-report.md`).

## Caratteristiche principali

- Modello dense 35B parametri quantizzato in formato Q3_K_M (~17 GB VRAM).
- Licenza MIT, pesi disponibili su Hugging Face sotto `deepreinforce-ai/Ornith-1.0`.
- Ottimizzato per compiti di coding agente, con capacità di self‑improving e self‑scaffolding.
- Configurazione predefinita per split layer‑wise tra P40 (layer 0‑27) e RTX 3050 (layer 28‑47) secondo il file `config.json`.
- Supporto per contesto fino a 4096 token, batch size 512 e 8 thread di CPU.
- Avvio su host `0.0.0.0` porta `8080` con logging abilitato.

## Requisiti di sistema

- GPU principale: NVIDIA Tesla P40 con almeno 24 GB VRAM.
- GPU secondaria: NVIDIA RTX 3050 con almeno 8 GB VRAM.
- Sistema operativo basato su Linux (testato su Ubuntu 24.04).
- Accesso a internet per il download iniziale dei pesi dal repository Hugging Face.
- Spazio su disco sufficiente per il file GGUF (circa 17 GB) e gli script di supporto.

## Installazione e avvio

1. Clonare questo repository oppure copiare la directory del progetto in una posizione di lavoro.
2. Assicurarsi che le due GPU siano riconosciute dal sistema e che i driver NVIDIA siano installati.
3. Eseguire lo script di download per ottenere il modello quantizzato:
   ```bash
   ./03-setup/download-setup.sh
   ```
   Lo script scarica il file `ornith-1.0-35b-q3_k_m.gguf` nella directory principale del progetto (o in una posizione specificata dallo script).
4. Verificare la presenza del file di configurazione `03-setup/config.json`. Modificare i parametri se necessario (ad esempio, contesto, batch size, porte).
5. Avviare il server di inferenza con il comando preferito (ad esempio utilizzando `llama-server` o simili) puntando al file GGUF e passando le opzioni di split indicate nel config.
6. Il modello sarà disponibile sull'endpoint HTTP specificato (default `http://0.0.0.0:8080`).

## Utilizzo

Una volta avviato, il modello può essere interrogato tramite richieste HTTP POST all'endpoint `/completion` o equivalente, a seconda del backend utilizzato. Esempio di richiesta con curl:
```bash
curl -X POST http://localhost:8080/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Scrivi una funzione Python che calcola il fattoriale di un numero", "max_tokens": 256, "temperature": 0.2}'
```
Adattare il payload in base alle specifiche del backend di inferenza scelto.

## Test e benchmark

La directory `04-testing` contiene:
- `benchmark-suite.sh`: script eseguibile che avvia una serie di prove di velocità e utilizzo della memoria.
- `README-TEST.md`: istruzioni dettagliate su come eseguire i test e interpretare i risultati.

Eseguire lo script di benchmark per ottenere metriche di throughput (token al secondo), latenza e consumo di VRAM su ciascuna GPU.

## Analisi comparativa

Nella directory `05-analysis` è presente `comparative-report.md`, che riporta un confronto teorico tra Ornith-1.0-35B e Qwen3.6-35B riguardo:
- Architettura di base e licenza.
- Prestazioni dichiarate su benchmark di coding.
- Efficienza della quantizzazione Q3_K_M rispetto ad altri formati.
- Idoneità per l'uso in configurazioni GPU eterogenee come P40 + RTX 3050.

## Risultati ottenuti

Durante le fasi di progetto completate il 27 giugno 2026:
- Il modello è stato correttamente scaricato e verificato.
- La configurazione di split GPU è stata definita e validata su carta.
- Gli script di avvio e test sono stati preparati e risultano eseguibili.
- L'analisi comparativa ha evidenziato le potenziali vantaggi di Ornith-1.0-35B in scenari di coding agente rispetto a Qwen3.6-35B.

## Prossimi passi

- Eseguire i benchmark pratici per confermare le prestazioni inferenziali.
- Ottimizzare ulteriormente i parametri di split e di batch in base alle misurazioni effettive.
- Integrare il modello in un flusso di lavoro di sviluppo assistito da AI.
- Pubblicare i risultati dettagliati su un blog o relazione tecnica.

## Licenza

Questo progetto è rilasciato sotto la licenza MIT. Si veda il file `LICENSE` per ulteriori dettagli.

## Ringraziamenti

Si ringrazia DeepReinforce.AI per aver reso disponibile il modello Ornith-1.0 sotto licenza MIT e la comunità open source per gli strumenti di quantizzazione e inferenza utilizzati.