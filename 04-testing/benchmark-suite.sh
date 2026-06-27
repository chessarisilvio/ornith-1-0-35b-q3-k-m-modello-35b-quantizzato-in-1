#!/usr/bin/env bash
# benchmark-suite.sh
# Suite di benchmark e test qualitativi per Ornith-1.0-35B Q3_K_M
# Da eseguire manualmente quando la GPU è libera.
# Utilizza variabili d'ambiente per la configurazione (vedi .env.example).

set -euo pipefail

# Default values (can be overridden by environment)
: "${MODEL_DIR:=$(pwd)/../03-setup/models}"
: "${MODEL_FILENAME:=ornith-1.0-35b-q3_k_m.gguf}"
: "${LLAMA_SERVER:=./llama-server}"  # eseguibile nella PATH o specificare percorso relativo
: "${HOST:=0.0.0.0}"
: "${PORT:=8080}"
: "${NUM_RUNS:=3}"  # numero di esecuzioni per ogni test per mediare
: "${MAX_TOKENS:=256}"
: "${TEMPERATURE:=0.7}"
: "${TOP_P:=0.9}"
: "${SEED:=42}"

MODEL_PATH="${MODEL_DIR}/${MODEL_FILENAME}"
RESULTS_DIR="results_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${RESULTS_DIR}/benchmark.log"

# Funzione di logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# Funzione per avviare il server llama
start_server() {
    log "Avvio llama-server con modello: ${MODEL_PATH}"
    # Variabili per split GPU (se necessario)
    export LLAMA_SPLIT_MODE=${LLAMA_SPLIT_MODE:-0}
    export LLAMA_SPLIT_0=${LLAMA_SPLIT_0:-0}
    export LLAMA_SPLIT_1=${LLAMA_SPLIT_1:-0}

    # Avvia il processo in background
    "${LLAMA_SERVER}" -m "${MODEL_PATH}" --host "${HOST}" --port "${PORT}" \
        --ctx-size 32768 --batch-size 512 --threads 6 \
        > "${RESULTS_DIR}/server.log" 2>&1 &
    SERVER_PID=$!

    # Attendi che il server sia pronto
    local timeout=30
    while ! curl -s "http://${HOST}:${PORT}/health" > /dev/null 2>&1; do
        sleep 1
        ((timeout--))
        if [[ $timeout -eq 0 ]]; then
            log "ERRORE: Timeout nell'avvio del server"
            stop_server
            exit 1
        fi
    done
    log "Server avviato (PID: ${SERVER_PID})"
}

# Funzione per fermare il server
stop_server() {
    if [[ -n "${SERVER_PID:-}" ]]; then
        log "Arresto server (PID: ${SERVER_PID})"
        kill "${SERVER_PID}" 2>/dev/null || true
        wait "${SERVER_PID}" 2>/dev/null || true
        unset SERVER_PID
    fi
}

# Funzione per eseguire un singolo test di inferenza e misurare tok/s e latenza
run_inference_test() {
    local prompt="$1"
    local test_name="$2"
    local output_file="${RESULTS_DIR}/${test_name}_output.txt"
    local metrics_file="${RESULTS_DIR}/${test_name}_metrics.json"

    log "Esecuzione test: ${test_name}"

    # Avvia il monitoraggio della VRAM in background
    local nvidia_smi_log="${RESULTS_DIR}/${test_name}_nvidia_smi.log"
    > "${nvidia_smi_log}"
    nvidia-smi --query-gpu=timestamp,memory.used,memory.total,utilization.gpu --format=csv -l 1 > "${nvidia_smi_log}" 2>&1 &
    local NVSMI_PID=$!

    # Esegui la richiesta di completamento
    local start_time=$(date +%s%3N)
    local response=$(curl -s "http://${HOST}:${PORT}/completion" \
        -H "Content-Type: application/json" \
        -d "{
            \"prompt\": \"${prompt}\",
            \"n_predict\": ${MAX_TOKENS},
            \"temperature\": ${TEMPERATURE},
            \"top_p\": ${TOP_P},
            \"seed\": ${SEED},
            \"stream\": false
        }")
    local end_time=$(date +%s%3N)

    # Ferma il monitoraggio VRAM
    kill "${NVSMI_PID}" 2>/dev/null || true
    wait "${NVSMI_PID}" 2>/dev/null || true

    # Calcola latenza e tok/s
    local latency_ms=$((end_time - start_time))
    local tokens_predicted=0
    if [[ "${response}" =~ \"content\":\"([^\"]*)\" ]]; then
        # Stima approssimativa: numero di parole / 0.75 (token per parola)
        local content="${BASH_REMATCH[1]}"
        tokens_predicted=$(( ${#content} / 4 ))  # stima molto approssimativa
    fi
    local tps=0
    if [[ $latency_ms -gt 0 && $tokens_predicted -gt 0 ]]; then
        tps=$(echo "scale=2; $tokens_predicted / ($latency_ms / 1000)" | bc)
    fi

    # Salva risultati
    echo "{\"prompt\": \"${prompt}\", \"latency_ms\": ${latency_ms}, \"tokens_predicted\": ${tokens_predicted}, \"tokens_per_second\": ${tps}}" > "${metrics_file}"
    echo "${response}" | jq . > "${output_file}" 2>/dev/null || echo "${response}" > "${output_file}"

    log "Test ${test_name} completato - Latenza: ${latency_ms}ms, Tokens previsti: ${tokens_predicted}, Tokens/s: ${tps}"
}

# Funzione per eseguire la suite di test
run_benchmark_suite() {
    mkdir -p "${RESULTS_DIR}"
    log "Inizio benchmark suite. Risultati in: ${RESULTS_DIR}"

    # Avvia server
    start_server

    # Definisci i test
    declare -A tests=(
        ["coding_simple"] "Scrivi una funzione Python che calcola il fattoriale di un numero."
        ["coding_complex"] "Implementa un algoritmo di ordinamento quicksort in C++ con commenti dettagliati."
        ["reasoning_math"] "Se un treno viaggia a 80 km/h e deve percorrere 320 km, quanto tempo impiega? Spiega il calcolo."
        ["reasoning_logic"] "Tutti i gatti sono animali. Alcuni animali sono pelosi. Possiamo concludere che tutti i gatti sono pelosi? Perché o perché no?"
        ["creative_story"] "Inizia una storia di fantascienza con la seguente frase: 'L'ultimo umano sulla Terra guardò il cielo e vide...'"
    )

    # Esegui ogni test multiple volte per mediare
    for test_name in "${!tests[@]}"; do
        local prompt="${tests[$test_name]}"
        local latencies=()
        local tps_values=()

        for ((i=1; i<=NUM_RUNS; i++)); do
            log "Esecuzione run $i/${NUM_RUNS} per ${test_name}"
            run_inference_test "${prompt}" "${test_name}_run${i}"

            # Leggi le metriche dal file appena creato
            local metrics_file="${RESULTS_DIR}/${test_name}_run${i}_metrics.json"
            if [[ -f "${metrics_file}" ]]; then
                local latency=$(jq -r '.latency_ms' "${metrics_file}")
                local tps=$(jq -r '.tokens_per_second' "${metrics_file}")
                latencies+=("${latency}")
                tps_values+=("${tps}")
            fi
        done

        # Calcola media e deviazione standard (approssimata)
        if [[ ${#latencies[@]} -gt 0 ]]; then
            local avg_latency=$(IFS=+; echo "scale=2; ($(IFS=; echo "${latencies[*]}"))/${#latencies[@]}" | bc)
            local avg_tps=$(IFS=+; echo "scale=2; ($(IFS=; echo "${tps_values[*]}"))/${#tps_values[@]}" | bc)
            echo "{\"test\": \"${test_name}\", \"avg_latency_ms\": ${avg_latency}, \"avg_tokens_per_second\": ${avg_tps}, \"runs\": ${NUM_RUNS}}" > "${RESULTS_DIR}/${test_name}_summary.json"
            log "Riepilogo ${test_name}: Latenza media=${avg_latency}ms, Tokens/s media=${avg_tps}"
        fi
    done

    # Ferma server
    stop_server

    log "Benchmark suite completata. Risultati in ${RESULTS_DIR}"
}

# Main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Se lo script è eseguito direttamente, esegui la suite
    run_benchmark_suite
fi