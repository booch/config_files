# Set some system-specific environment variables for ease of use.
# This **should** work in both Bash and Zsh, on MacOS and Linux,
# but I have only tested it in Zsh on Mac.

# NOTE: Bash (but not POSIX) sets $HOSTNAME automatically, but does not export it.
export HOSTNAME="${HOSTNAME:-$(hostname)}"

export SHELL_NAME="$(basename "$SHELL" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
export SHELL_VERSION="$($SHELL --version | head -n 1 | awk '{print $2}')"

# If running on MacOS:
if [[ "$(uname)" == "Darwin" ]]; then
    free_ram() {
        local page_size=$(sysctl -n hw.pagesize)
        local pages_free=$(sysctl -n vm.page_free_count)
        local pages_reusable=$(sysctl -n vm.page_reusable_count)
        local pages_speculative=$(sysctl -n vm.page_speculative_count)
        local pages_purgeable=$(sysctl -n vm.page_purgeable_count)
        local pages_file_backed=$(sysctl -n vm.vm_page_filecache_min)

        # NOTE: This is a little high, but it's the best I could figure out, and it closely matches
        echo "$((page_size * ( pages_free + pages_file_backed ) / 1024 / 1024 / 1024)) GiB"
    }

    export SYSTEM_OS='macOS'
    export SYSTEM_OS_VERSION="$(sw_vers -productVersion)"
    export SYSTEM_NAME="$(/usr/sbin/networksetup -getcomputername)"
    export SYSTEM_DESCRIPTION="$(ioreg -r -k product-description | awk -F '[=<>"]' '/product-description/ {print $(NF-2)}')"
    export SYSTEM_CPU_CHIP="$(system_profiler SPHardwareDataType | awk -F ': ' '/Chip/ {print $2}')"
    export SYSTEM_CPU_FREQ="$(sysctl -n hw.tbfrequency | awk '{print $0/10000000}') GHz"
    export SYSTEM_CPU_CORES="$(sysctl -n hw.physicalcpu)"
    export SYSTEM_RAM="$(sysctl -n hw.memsize | awk '{print $0/1073741824}') GiB"

    export SYSTEM_MODEL_ID="$(sysctl -n hw.model)"
    export SYSTEM_SERIAL_NUMBER="$(system_profiler SPHardwareDataType | awk -F ': ' '/Serial Number/ {print $2}')"

    # Model number and part number are surprisingly difficult to get, despite being etched on bottom of computer.
    # The best source I found was https://en.wikipedia.org/wiki/MacBook_Pro_(Apple_silicon)#Technical_specifications_2.
    if [[ "$SYSTEM_MODEL_ID" == 'Mac16,7' ]]; then
        export SYSTEM_MODEL_NUMBER='A3403'
    else
        export SYSTEM_MODEL_NUMBER='UNKNOWN - PLEASE UPDATE SCRIPT'
    fi
    if [[ "$SYSTEM_SERIAL_NUMBER" == 'HD92KMVMMV' ]]; then
        export SYSTEM_PART_NUMBER='MX2Y3LL/A' # 48 GB RAM, Space Black
    else
        export SYSTEM_PART_NUMBER='UNKNOWN - PLEASE UPDATE SCRIPT'
    fi
else
    # WARNING: This whole section is untested!
    free_ram() {
        local mem_free="$(awk '/MemFree/ {print $2}' /proc/meminfo)"
        local mem_available="$(awk '/MemAvailable/ {print $2}' /proc/meminfo)"
        local mem_buffers="$(awk '/Buffers/ {print $2}' /proc/meminfo)"
        local mem_cached="$(awk '/Cached/ {print $2}' /proc/meminfo)"

        echo "$(( ( mem_free + mem_available + mem_buffers + mem_cached ) / 1024 / 1024 )) GB"
    }

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        export SYSTEM_OS="$NAME"
        export SYSTEM_OS_VERSION="$VERSION_ID"
    elif type lsb_release >/dev/null 2>&1; then
        export SYSTEM_OS="$(lsb_release -si)"
        export SYSTEM_OS_VERSION="$(lsb_release -sr)"
    else
        export SYSTEM_OS="$(uname -s)"
        export SYSTEM_OS_VERSION="$(uname -r)"
    fi

    export SYSTEM_NAME="$HOSTNAME"
    export SYSTEM_DESCRIPTION="$(uname -s -r -m)"
    export SYSTEM_CPU_CHIP="$(lscpu | awk -F ': ' '/Model name/ {print $2}')"
    export SYSTEM_CPU_FREQ="$(sysctl -n hw.cpufrequency_max | awk '{print $0/1000000000}') GHz"
    export SYSTEM_CPU_CORES="$(lscpu | awk -F ': ' '/Core\(s\) per socket/ {print $2}')"
    export SYSTEM_RAM="$(free -h | awk '/Mem/ {print $2}')"

    if command -v dmidecode &> /dev/null; then
        export SYSTEM_MODEL_ID="$(sudo dmidecode -s system-product-name)"
        export SYSTEM_SERIAL_NUMBER="$(sudo dmidecode -s system-serial-number)"
    else
        export SYSTEM_MODEL_ID="$(cat /sys/class/dmi/id/product_name)"
        export SYSTEM_SERIAL_NUMBER="$(cat /sys/class/dmi/id/product_serial)"
    fi
fi

# Output some basic system info.
echo "HOSTNAME            = $HOSTNAME"
echo "SYSTEM_NAME         = $SYSTEM_NAME"
echo "SYSTEM_DESCRIPTION  = $SYSTEM_DESCRIPTION"
echo "CPU                 = $SYSTEM_CPU_CHIP $SYSTEM_CPU_FREQ × $SYSTEM_CPU_CORES"
echo "OS                  = $SYSTEM_OS $SYSTEM_OS_VERSION"
echo "TERMINAL            = ${TERM_PROGRAM} $TERM_PROGRAM_VERSION"
echo "SHELL               = ${SHELL_NAME} $SHELL_VERSION"
echo "UPTIME              = $(uptime | awk '{print $3 " " $4}' | tr -d ,)"
echo "FREE MEMORY         = $(free_ram) of $SYSTEM_RAM"
echo "FREE STORAGE        = $(df -h / | awk 'NR==2 {gsub("Gi", " GiB", $2); gsub("Gi", " GiB", $4); print $4 " free of " $2}')"
