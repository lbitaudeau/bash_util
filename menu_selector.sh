#TODO add wrapper arround ansi escape chars

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
            echo -e "\e[2K" # ^2K => clean line
        else
            echo -e "${prefix}${txti}${suffix}\e[0K" # ^0K => clean end of line
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
    if [[ $position -ge $(( size-1 )) ]]; then
        echo "$position" > log.txt
        printf "\033[${size}F"
        print_menu_screen "$(( position-size+2 ))" "$(( position+1 ))" "- \e[34m" "\e[0m" "${inputs[@]}"
        printf "\033[2F"
        pos_min=$(( pos_min+1 ))
    else
        # printf "\033[0B"
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
        AEC_UP 
        pos_min=$(( pos_min-1 )) # decrease minimal position
        print_menu_screen "$(( position-1 ))" "$(( position+size-2 ))" "- \e[34m" "\e[0m" "${inputs[@]}"
        # printf "\033[$(( line_shift-2 ))F" # shift to the right position
        AEC_PREV_LINE $(( line_shift-2 ))
    else
        printf "\033[0A"
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

    print_menu_screen "$position" "$(( position+size-1 ))" "- \e[34m" "\e[0m" "${inputs[@]}"
    AEC_S
    printf "\033[$(( line_shift-2 ))F" # move to the first item
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
    # printf "\033[$(( w_size-position+pos_min-1 ))E"
    trap - INT
    AEC_U
    export __MENU_SELECTOR_POS=$position
    export __MENU_SELECTOR_RES=${inputs[$position]}
    return 0
}