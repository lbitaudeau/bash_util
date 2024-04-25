# AEC = ANSI Escape Code

_AEC_RST="\e[0m"

_AEC_BLUE="\e[34m"

# save cursor pos
function AEC_S()
{
    printf "\033[s"
}

# restor cursor pos
function AEC_U()
{
    printf "\033[u"
}

# cursor go down
function AEC_DOWN()
{
    # $1 => n
    printf "\033[${1}B"
}

# cursor go up
function AEC_UP()
{
    # $1 => n
    printf "\033[${1}A"
}

# moves cursor begin prev line
function AEC_PREV_LINE()
{
    # $1 => n
    printf "\033[${1}F"
}

# clean line (check param n)
function AEC_CLEAN_LINE()
{
    # $1 => n
    # n = 2 : clean line
    # n = 1 : clean from cursor to begin of line
    # n = 0 : clean from cursor to end of line
    printf "\033[${1}K"
}

function print_list_with_bound()
{
    local min=$1
    local max=$2
    local prefix=$3
    local suffix=$4
    local txt=("${@:5}")

    for ((i = $min; i <= $max; i++)); do
        local txti="${txt[$i]}"
        if [ -z "$txti" ]; then
            AEC_CLEAN_LINE 2
            echo "" # new line
        else
            AEC_CLEAN_LINE 2
            if [[ -z $ms_list_num ]]; then
                echo -e "${prefix}${txti}${suffix}"
            else
                echo -e "${i}${prefix}${txti}${suffix}"            
            fi
            
        fi
    done
}

function print_menu_screen()
{
    local min=$1
    local max=$2
    local prefix=$3
    local suffix=$4
    local txt=("${@:5}")
    echo "============"
    print_list_with_bound "$min" "$max" "$prefix" "$suffix" "${txt[@]}"
    echo -e "============"
}

function menu_handle_down()
{
    if [[ $position -eq $(( count - 1 )) ]]; then
        return
    fi
     # go down
    if [[ $position -eq $pos_max ]]; then
         # increase min/max positions
        pos_min=$(( pos_min+1 ))
        pos_max=$(( pos_max+1 ))

        AEC_PREV_LINE $(( size ))
        print_menu_screen "$(( position-size+2 ))" "$(( position+1 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
        AEC_PREV_LINE 2
    else
        AEC_DOWN
    fi
    position=$(( position + 1))
}


function menu_handle_up()
{
    if [[ $position -eq 0 ]]; then
        return
    fi
     # go down
    if [[ $position -eq $pos_min ]]; then
        # increase cursor pos as we need to display =====
         # decrease min/max positions
        pos_min=$(( pos_min-1 ))
        pos_max=$(( pos_max-1 ))

        AEC_UP 
        print_menu_screen "$(( position-1 ))" "$(( position+size-2 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
        AEC_PREV_LINE $(( line_shift-2 ))
    else
        AEC_UP
    fi
    position=$(( position - 1))
}


function menu_selector()
{
    local inputs=()
    local size=$1
    local w_size=$(( size + 2))
    local cols=$(tput cols)
    local lines=$(tput lines)
    local pos_min=0
    local pos_max=$(( size - 1 ))

    local ms_list_num=1
    local ms_list_prefix=" - $_AEC_BLUE"
    local ms_list_suffix="$_AEC_RST"
    # Add key handler
    # Add option handler

    for elem in "${@:2}"; do
        inputs+=("$elem")
    done
    local count=${#inputs[@]}

    if [[ $w_size -gt $lines ]]; then
        echo "shell trop petit"
        return 0
    fi

    local position=0
    local stop=0
    local user_input
    local line_shift=$(( w_size + 1 ))

    print_menu_screen "$position" "$(( position+size-1 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
    AEC_S
    AEC_PREV_LINE $(( line_shift-2 ))
    trap -- 'AEC_U;return 0' SIGINT
    # Add a way to reset with screen position
    
    while [[ $stop -eq 0 ]]; do
        
        read -rsn1 user_input # wait for user input
        
        case $user_input in
            "q")
                stop=1
                ;;
            "A")
                menu_handle_up
                ;;
            "B")
                menu_handle_down
                ;;
            "")
                stop=1
                ;;
        esac
    done
    trap - INT
    AEC_U
    export __MENU_SELECTOR_POS=$position
    export __MENU_SELECTOR_RES=${inputs[$position]}
    return 0
}