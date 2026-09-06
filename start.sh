#!/usr/bin/env bash
# Fix Windows carriage return line-ending issues automatically
set -e
if [ -f "$0" ]; then
    sed -i -e 's/\r$//' "$0" 2>/dev/null || tr -d '\r' < "$0" > "$0.tmp" && mv "$0.tmp" "$0"
fi
cd /home/container || exit 1

# Self-update/download check on boot
if [ ! -f "./playit" ]; then
    curl -o ./playit -L https://github.com/playit-cloud/playit-agent/releases/download/v0.15.2/playit-0.15.2-x86_64-linux
    chmod +x ./playit
fi

# --- COLOR PALETTE & STYLING ---
R="\033[31m"
G="\033[32m"
Y="\033[33m"
B="\033[34m"
M="\033[35m"
C="\033[36m"
W="\033[37m"
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

# --- FANCY ANIMATED BOOT SEQUENCE ---
clear
echo -e "${C}${BOLD}"
echo "    ____  __            _      _                  "
echo "   / __ \\/ /___ ___  __(_)____(_)___ _____ _      "
echo "  / /_/ / / __ \`/ / / / / ___/ / __ \`/ __ \`/      "
echo " / ____/ / /_/ / /_/ / / /  / / /_/ / /_/ /       "
echo "(_/   /_/\\__,_/\\__, /_/_/  /_/\\__, /\\__, /        "
echo "              /____/         /____//____/         "
echo -e "${RESET}"

echo -e "${DIM}------------------------------------------------------------------${RESET}"
echo -e "${Y}${BOLD}[⚡] INITIALIZING SYSTEM CORE & SECURE TUNNEL MODULE...${RESET}"
echo -e "${DIM}------------------------------------------------------------------${RESET}"

# Smooth loading animation simulation
for i in {1..3}; do
    echo -ne "${C}[ ⏳ Loading modules phase $i/3 ]\r${RESET}"
    sleep 0.4
done
echo -e "${G}[ ✔ System Core Initialized Successfully! ]                     ${RESET}\n"

PORT="${TARGET_PORT:-25565}"

# --- START THE PLAYIT PROCESS ---
start_playit() {
    if [ -f "./playit.pid" ] && kill -0 "$(cat ./playit.pid)" 2>/dev/null; then
        echo -e "${Y}[!] Playit tunnel engine is already active.${RESET}"
        return
    fi

    echo -e "${C}[*] Booting Playit Tunnel Engine on Port: ${BOLD}$PORT${RESET}${C}...${RESET}"
    ./playit --port "$PORT" > playit.log 2>&1 &
    echo $! > ./playit.pid
    sleep 1
    echo -e "${G}[✔] Tunnel online! Check logs below or type /status.${RESET}"
}

start_playit

# --- INTERACTIVE TERMINAL LOOP WITH EXTENDED COMMANDS ---
while true; do
    echo -n -e "${M}${BOLD}playit@pterodactyl:~# ${RESET}"
    read -r cmd args

    case "$cmd" in
        "/help"|"help")
            echo -e "\n${BOLD}${C}=== AVAILABLE PLAYIT GATEWAY COMMANDS ===${RESET}"
            echo -e "  ${G}start${RESET}          - Boot up the playit tunnel agent"
            echo -e "  ${G}stop${RESET}           - Gracefully shut down the tunnel agent"
            echo -e "  ${G}restart${RESET}        - Restart the tunnel software"
            echo -e "  ${G}status${RESET}         - Check real-time running state and PID"
            echo -e "  ${G}logs${RESET}           - View the last 20 lines of tunnel activity"
            echo -e "  ${G}add-port${RESET}       - Reassign tunnel target port dynamically"
            echo -e "  ${G}claim${RESET}          - Display account link & claim URL details"
            echo -e "  ${G}clear${RESET}          - Clear the terminal screen with animation"
            echo -e "  ${G}version${RESET}        - Show agent version and build info"
            echo -e "  ${G}diagnostics${RESET}    - Run network socket checks"
            echo -e "  ${G}sysinfo${RESET}        - Display container memory & resource usage"
            echo -e "  ${G}exit${RESET}           - Safely terminate session and container loop"
            echo -e "${DIM}------------------------------------------------------------${RESET}\n"
            ;;
        "start")
            start_playit
            ;;
        "stop")
            if [ -f "./playit.pid" ]; then
                PID=$(cat ./playit.pid)
                if kill -0 "$PID" 2>/dev/null; then
                    echo -e "${Y}[*] Shutting down agent (PID: $PID)...${RESET}"
                    kill "$PID"
                    rm -f ./playit.pid
                    echo -e "${G}[✔] Agent stopped successfully.${RESET}"
                else
                    echo -e "${R}[!] No active process found matching PID $PID.${RESET}"
                    rm -f ./playit.pid
                fi
            else
                echo -e "${R}[!] Playit is not running.${RESET}"
            fi
            ;;
        "restart")
            echo -e "${Y}[*] Cycling tunnel engine...${RESET}"
            if [ -f "./playit.pid" ]; then
                PID=$(cat ./playit.pid)
                kill "$PID" 2>/dev/null
                rm -f ./playit.pid
            fi
            sleep 1
            start_playit
            ;;
        "status")
            echo -e "\n${C}=== TUNNEL STATUS REPORT ===${RESET}"
            if [ -f "./playit.pid" ] && kill -0 "$(cat ./playit.pid)" 2>/dev/null; then
                echo -e " Status: ${G}${BOLD}ONLINE (Running)${RESET}"
                echo -e " PID:    $(cat ./playit.pid)"
                echo -e " Port:   ${B}$PORT${RESET}"
            else
                echo -e " Status: ${R}${BOLD}OFFLINE${RESET}"
            fi
            echo -e "${C}============================${RESET}\n"
            ;;
        "logs")
            echo -e "\n${DIM}--- LAST 20 LINES OF PLAYIT LOGS ---${RESET}"
            if [ -f "playit.log" ]; then
                tail -n 20 playit.log
            else
                echo -e "${R}[!] Log file not found.${RESET}"
            fi
            echo -e "${DIM}-------------------------------------${RESET}\n"
            ;;
        "add-port")
            echo -n -e "${Y}Enter the new target game port (1-65535): ${RESET}"
            read -r new_port
            if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
                PORT="$new_port"
                echo -e "${G}[✔] Target port successfully updated to $PORT! Restarting tunnel...${RESET}"
                if [ -f "./playit.pid" ]; then
                    kill "$(cat ./playit.pid)" 2>/dev/null
                    rm -f ./playit.pid
                fi
                start_playit
            else
                echo -e "${R}[!] Invalid port format. Action cancelled.${RESET}"
            fi
            ;;
        "claim")
            echo -e "\n${Y}${BOLD}[*] LOOKING FOR ACCOUNT LINK URL IN LOGS:${RESET}"
            if [ -f "playit.log" ]; then
                grep -i "https://" playit.log || echo -e "${R}[!] Claim link not generated yet. Watch logs or wait 5 seconds.${RESET}"
            else
                echo -e "${R}[!] No logs available yet.${RESET}"
            fi
            echo ""
            ;;
        "clear")
            clear
            echo -e "${C}${BOLD}=== Playit Control Center Active ===${RESET}\n"
            ;;
        "version")
            echo -e "${C}Playit Agent Version:${RESET} v0.15.2 (Custom Pterodactyl Wrapper)"
            ;;
        "diagnostics")
            echo -e "${C}[*] Running local binding diagnostic on port $PORT...${RESET}"
            nc -zvw3 127.0.0.1 "$PORT" 2>&1 || echo -e "${Y}[*] Netcat check completed.${RESET}"
            ;;
        "sysinfo")
            echo -e "\n${C}=== CONTAINER RESOURCE MONITOR ===${RESET}"
            free -m | awk 'NR==2{printf " Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }'
            df -h /home/container | awk 'NR==2{printf " Disk Space:   %s/%s (%s)\n", $3,$2,$5}'
            echo -e "${C}==================================${RESET}\n"
            ;;
        "exit"|"quit")
            echo -e "${Y}[*] Terminating background processes and exiting shell...${RESET}"
            if [ -f "./playit.pid" ]; then
                kill "$(cat ./playit.pid)" 2>/dev/null
                rm -f ./playit.pid
            fi
            exit 0
            ;;
        "")
            continue
            ;;
        *)
            echo -e "${R}[!] Unrecognized command: '$cmd'. Type ${BOLD}/help${RESET}${R} for command options.${RESET}"
            ;;
    esac
done
