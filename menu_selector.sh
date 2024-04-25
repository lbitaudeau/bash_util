# AEC = ANSI Escape Code

_AEC_RST="\e[0m"
_AEC_RED="\e[31m"
_AEC_BLUE="\e[34m"

_AEC_KEY_UP="A"
_AEC_KEY_DOWN="B"
_AEC_KEY_LEFT="D"
_AEC_KEY_RIGHT="C"

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
    # echo -e "$ms_header"
    printf "$ms_header"
    print_list_with_bound "$min" "$max" "$prefix" "$suffix" "${txt[@]}"
    # echo -e "$ms_footer"
    printf "$ms_footer"
}

function ms_handle_down()
{
    # rock bottom
    if [[ $position -eq $(( count - 1 )) ]]; then
        return
    fi
     # go down
    if [[ $position -eq $pos_max ]]; then
         # increase min/max positions
        pos_min=$(( pos_min+1 ))
        pos_max=$(( pos_max+1 ))

        # Replace the cursor : the easy way
        AEC_U
        AEC_PREV_LINE $(( size+footer_size+header_size ))
        print_menu_screen "$(( position-size+2 ))" "$(( position+1 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
        AEC_PREV_LINE $(( footer_size+1 ))
    else
        AEC_DOWN
    fi
    position=$(( position + 1))
}


function ms_handle_up()
{
    # sky is the limit
    if [[ $position -eq 0 ]]; then
        return
    fi
     # go down
    if [[ $position -eq $pos_min ]]; then
        # increase cursor pos as we need to display =====
         # decrease min/max positions
        pos_min=$(( pos_min-1 ))
        pos_max=$(( pos_max-1 ))

        # Replace the cursor : the easy way
        AEC_U
        AEC_PREV_LINE $(( size+footer_size+header_size ))
        print_menu_screen "$(( position-1 ))" "$(( position+size-2 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
        AEC_PREV_LINE $(( size+footer_size ))
    else
        AEC_UP
    fi
    position=$(( position - 1))
}

function ms_handle_left()
{
    :
}

function ms_handle_right()
{
    :
}

function menu_selector()
{
    # Display options' number
    local ms_list_num=1
    # Give the possibility to remove the header when the window is too small
    local ms_remove_header=
    # Give the possibility to adjuste the size
    local ms_adjuste_size=

    # Force the menu to start. It may remove header/footer and resize the menu
    local ms_always_start=1

    local ms_list_prefix=" - $_AEC_BLUE"
    local ms_list_suffix="$_AEC_RST"
    # give the ability to redefine ms_handle_up, ms_handle_down, etc.
    local ms_function_pack="ms"
    # printed before and after the menu
    local ms_header="=\na\nb\nc\n="
    local ms_footer="="

    local header_size=0
    local footer_size=0

    if [[ ! -z $ms_header ]]; then
        ms_header="${ms_header}\n"
        header_size=$(printf "$ms_header" | wc -l)
    fi

    if [[ ! -z $ms_footer ]]; then
        ms_footer="${ms_footer}\n"
        footer_size=$(printf "$ms_footer" | wc -l)
    fi



    local inputs=()
    local size=$1
    local w_size=$(( size + header_size + footer_size))
    local cols=$(tput cols)
    local lines=$(tput lines)
    local pos_min=0
    local pos_max=$(( size - 1 ))
    local RET=0

    # check if console is long enough
    if [[ $w_size -gt $lines ]]; then
        if [[ ! -z $ms_always_start ]]; then
            ms_remove_header=1
            ms_adjuste_size=1
        fi

        if [[ ! -z $ms_remove_header ]]; then
            ms_header=""
            ms_footer=""
            header_size=0
            footer_size=0
            w_size=$(( size + header_size + footer_size))
        fi

        if [[ ! -z $ms_adjuste_size ]]; then
            size=$(( size - w_size + lines - 1 ))
            pos_max=$(( size - 1 ))
            w_size=$(( size + header_size + footer_size))
        fi

        if [[ $w_size -gt $lines ]]; then
            echo -e "${_AEC_RED}Unable to start menu_selector${_AEC_RST}"
            return
        fi
    fi

    for elem in "${@:2}"; do
        inputs+=("$elem")
    done
    local count=${#inputs[@]}


    local position=0
    local stop=0
    local user_input
    local line_shift=$(( w_size + header_size ))

    print_menu_screen "$position" "$(( position+size-1 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
    AEC_S
    AEC_PREV_LINE $(( size+footer_size ))
    trap -- 'AEC_U;trap - INT;return 1' SIGINT
    # Add a way to reset with screen position
    while [[ $stop -eq 0 ]]; do
        
        read -rsn1 user_input # wait for user input
        
        case $user_input in
            "q")
                stop=1
                RET=1
                ;;
            "$_AEC_KEY_UP")
                ${ms_function_pack}_handle_up
                ;;
            "$_AEC_KEY_DOWN")
                ${ms_function_pack}_handle_down
                ;;
            "$_AEC_KEY_LEFT")
                ${ms_function_pack}_handle_left
                ;;
            "$_AEC_KEY_RIGHT")
                ${ms_function_pack}_handle_right
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
    return $RET
}