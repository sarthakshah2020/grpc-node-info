#!/bin/bash

# User-editable difficulty variables
difficulty_satisfiability="[50,300]"
difficulty_vehicle_routing="[40, 250]"
difficulty_knapsack="[50,10]"

REPO_DIR="$HOME/tig-monorepo"
TIG_WORKER_PATH="$REPO_DIR/target/release/tig-worker"
RESULTS_FILE="$HOME/scripts/tig_algos_test_results.txt"
ALGO_TIMEOUT=15 # Timeout for each algorithm in seconds
SKIP_FILE="/tmp/tig_test_skip"

if [ ! -f "$TIG_WORKER_PATH" ]; then
    echo "Error: tig-worker binary not found at $TIG_WORKER_PATH"
    echo "Run: cd $REPO_DIR && cargo build -p tig-worker --release"
    exit 1
fi

# Function to kill a process and its children
kill_process_tree() {
    local pid=$1
    kill -TERM -$pid 2>/dev/null
    kill -KILL -$pid 2>/dev/null
}

# Function to run test for a single algorithm
run_test() {
    local CHALLENGE=$1
    local ALGORITHM=$2
    local CHALLENGE_ID
    local difficulty

    case $CHALLENGE in
        satisfiability)
            CHALLENGE_ID="c001"
            difficulty=$difficulty_satisfiability
            ;;
        vehicle_routing)
            CHALLENGE_ID="c002"
            difficulty=$difficulty_vehicle_routing
            ;;
        knapsack)
            CHALLENGE_ID="c003"
            difficulty=$difficulty_knapsack
            ;;
        *)
            echo "Error: Challenge '$CHALLENGE' is not recognized."
            return 1
            ;;
    esac

    local start_nonce=0
    local num_nonces=100

    local SETTINGS="{\"challenge_id\":\"$CHALLENGE_ID\",\"difficulty\":$difficulty,\"algorithm_id\":\"\",\"player_id\":\"\",\"block_id\":\"\"}"
    local num_solutions=0
    local num_invalid=0
    local num_errors=0
    local num_timeouts=0
    local total_ms=0

    echo "----------------------------------------------------------------------" | tee -a "$RESULTS_FILE"
    echo "Testing performance of $CHALLENGE/$ALGORITHM" | tee -a "$RESULTS_FILE"
    echo "Settings: $SETTINGS" | tee -a "$RESULTS_FILE"
    echo "Starting nonce: $start_nonce" | tee -a "$RESULTS_FILE"
    echo "Number of nonces: $num_nonces" | tee -a "$RESULTS_FILE"
    
    for ((nonce=start_nonce; nonce<start_nonce+num_nonces; nonce++)); do
        start_time=$(date +%s%3N)
        
        # Run tig-worker in background
        "$TIG_WORKER_PATH" compute_solution "$SETTINGS" $nonce "$REPO_DIR/tig-algorithms/wasm/$CHALLENGE/$ALGORITHM.wasm" > /tmp/tig_output 2>&1 &
        tig_pid=$!

        # Wait for tig-worker to complete or timeout
        ( sleep $ALGO_TIMEOUT; kill_process_tree $tig_pid 2>/dev/null ) &
        wait $tig_pid
        exit_code=$?

        # Check for manual skip
        if [ -f "$SKIP_FILE" ]; then
            rm "$SKIP_FILE"
            echo "Manual skip triggered for $CHALLENGE/$ALGORITHM" | tee -a "$RESULTS_FILE"
            return
        fi

        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))
        total_ms=$((total_ms + duration))
        
        if [ $exit_code -eq 0 ]; then
            num_solutions=$((num_solutions + 1))
        elif [ $exit_code -eq 137 ] || [ $exit_code -eq 143 ]; then # SIGKILL or SIGTERM exit code
            num_timeouts=$((num_timeouts + 1))
            echo "Timeout occurred for nonce $nonce" | tee -a "$RESULTS_FILE"
        else
            if grep -q "Invalid solution\|No solution found" /tmp/tig_output; then
                num_invalid=$((num_invalid + 1))
            else
                num_errors=$((num_errors + 1))
            fi
        fi
    done

    if [ $num_solutions -eq 0 ]; then
        avg_ms_per_solution=0
    else
        avg_ms_per_solution=$((total_ms / num_solutions))
    fi

    echo "Results for $CHALLENGE/$ALGORITHM:" | tee -a "$RESULTS_FILE"
    echo "  #instances: $((num_solutions + num_invalid + num_errors + num_timeouts))" | tee -a "$RESULTS_FILE"
    echo "  #solutions: $num_solutions" | tee -a "$RESULTS_FILE"
    echo "  #invalid: $num_invalid" | tee -a "$RESULTS_FILE"
    echo "  #errors: $num_errors" | tee -a "$RESULTS_FILE"
    echo "  #timeouts: $num_timeouts" | tee -a "$RESULTS_FILE"
    echo "  Average ms/solution: $avg_ms_per_solution" | tee -a "$RESULTS_FILE"
    echo "----------------------------------------------------------------------" | tee -a "$RESULTS_FILE"
}

# Main execution
echo "Starting automated algorithm testing" | tee "$RESULTS_FILE"
echo "Timestamp: $(date)" | tee -a "$RESULTS_FILE"
echo "----------------------------------------------------------------------" | tee -a "$RESULTS_FILE"
echo "To manually skip to the next algorithm, run: touch $SKIP_FILE" | tee -a "$RESULTS_FILE"
echo "----------------------------------------------------------------------" | tee -a "$RESULTS_FILE"

# List of all algorithms to test
algorithms=(
    "satisfiability/sprint_sat"
    "satisfiability/schnoing"
    "satisfiability/dpll_backtracking"
    "satisfiability/genetic_sat"
    "satisfiability/walk_sat"
    "satisfiability/satisfiapilled"
    "satisfiability/i_cant_get_no"
    "satisfiability/need_for_speed"
    "satisfiability/walk_sat_adapt_tabu"
    "satisfiability/fast_walk_sat"
    "satisfiability/sprint_sat"
    "satisfiability/faster_walk_sat"
    "satisfiability/fastest_walk_sat"
    "satisfiability/filter_sat"
    "satisfiability/sprintier_sat"
    "satisfiability/inbound"
    "satisfiability/double_optimized"
    "satisfiability/fast_cdcl_sat_solver"
    "satisfiability/hybrid_ultra_fast"
    "satisfiability/optimized_sprint_sat"
    "satisfiability/sat_allocd"
    "satisfiability/mt_sat"
    "vehicle_routing/clarke_wright"
    "vehicle_routing/vrp_solver"
    "vehicle_routing/ant_colony"
    "vehicle_routing/genetic_algorithm"
    "vehicle_routing/tabu_search"
    "vehicle_routing/simulated_annealing"
    "vehicle_routing/limitless"
    "vehicle_routing/dynamic_colonies"
    "vehicle_routing/lazier_cw"
    "vehicle_routing/guided_clarke_wright"
    "vehicle_routing/aco_sbas"
    "vehicle_routing/fast_exit_clarke"
    "vehicle_routing/filter_cw"
    "vehicle_routing/vehicles_routed"
    "vehicle_routing/cw_optimised"
    "vehicle_routing/overloded"
    "vehicle_routing/clarke_wright_fast"
    "vehicle_routing/clarke_wright_opt"
    "vehicle_routing/clarke_wright_who"
    "vehicle_routing/cw_two_opt_ls"
    "vehicle_routing/super_heaped"
    "vehicle_routing/enhanced_annealing"
    "vehicle_routing/optimized_clarke"
    "vehicle_routing/adaptive_cluster"
    "vehicle_routing/quantum_swarm"
    "vehicle_routing/compact_gcw"
    "vehicle_routing/fast_exit_cw_topt_ls"
    "vehicle_routing/inbound"
    "vehicle_routing/compact_gcw_turbo"
    "vehicle_routing/improv_clarke_wright"
    "knapsack/dynamic"
    "knapsack/greedy"
    "knapsack/branch_and_bound"
    "knapsack/genetic"
    "knapsack/tabu_search"
    "knapsack/knapmaxxing"
    "knapsack/better_in_twos"
    "knapsack/tinhat_pete"
    "knapsack/knapsplorify"
    "knapsack/dual_descent"
    "knapsack/ironhat_pete"
    "knapsack/flat_dp"
    "knapsack/filter_knapmaxxing"
    "knapsack/better_knapp"
    "knapsack/better_knapm"
    "knapsack/optimised_knapmax"
    "knapsack/overlodes_sack"
    "knapsack/knapheudp"
    "knapsack/knapsack_para"
    "knapsack/over_knapmaxxed"
    "knapsack/needaknap"
    "knapsack/sack_o_potatoes"
    "knapsack/fast_knapsack"
    "knapsack/lightning_knapsack"
    "knapsack/neural_knapsack"
    "knapsack/quantum_knapsack"
    "knapsack/ultra_fast_knapsack"
    "knapsack/sackophone"
)

for algo in "${algorithms[@]}"; do
    challenge=$(dirname "$algo")
    algorithm=$(basename "$algo")
    run_test "$challenge" "$algorithm"
done

echo "All tests completed." | tee -a "$RESULTS_FILE"
echo "Results saved in $RESULTS_FILE" | tee -a "$RESULTS_FILE"
