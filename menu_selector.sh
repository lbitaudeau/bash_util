# AEC = ANSI Escape Code

_AEC_RST="\e[0m"
_AEC_RED="\e[31m"
_AEC_GREEN="\e[32m"
_AEC_YELLOW="\e[33m"
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

# moves cursor begin next line
function AEC_NEXT_LINE()
{
    # $1 => n
    printf "\033[${1}E"
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

# mov cursor to column n
function AEC_COL()
{
    # $1 => n
    printf "\033[${1}G"
}

# hide cursor
function AEC_HIDE()
{
    printf "\033[?25l"
}

# show cursor
function AEC_SHOW()
{
    printf "\033[?25h"
}

__REMAINING_CLR=$_AEC_YELLOW

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
            # new line
        else
            AEC_CLEAN_LINE 2
            if [[ -z $ms_list_num ]]; then
                printf -- "${prefix}%s${suffix}" "${txti}"
            else
                printf -- "${i}${over_count} ${prefix}%s${suffix}" "${txti}"
            fi
            # TODO : option to print num-end...
        fi

        if [[ $i -lt $max ]]; then
            printf "\n"
        else
            if [[ ! -z $ms_remaining ]] && [[ $max -ne $(( $count - 1 )) ]] && [[ $(( $count -1 )) -ge $size ]]; then
                AEC_CLEAN_LINE 2
                AEC_COL
                printf "${__REMAINING_CLR}%d...%d${_AEC_RST}" "$max" "$(( $count - 1 ))"
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
    printf "$ms_header"
    print_list_with_bound "$min" "$max" "$prefix" "$suffix" "${txt[@]}"
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
        AEC_PREV_LINE $(( size+footer_size+header_size-1 ))
        print_menu_screen "$(( position-size+2 ))" "$(( position+1 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
        if [[ $footer_size -eq 0 ]]; then
            AEC_COL 0
        else
            AEC_PREV_LINE $(( footer_size ))
        fi
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
        AEC_PREV_LINE $(( size+footer_size+header_size-1 ))
        print_menu_screen "$(( position-1 ))" "$(( position+size-2 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
        AEC_PREV_LINE $(( size+footer_size-1 ))
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

function debug()
{
    echo "ms_list_num=$ms_list_num"
    # Give the possibility to remove the header when the window is too small
    echo "ms_remove_header=$ms_remove_header"
    # Give the possibility to adjuste the size
    echo "ms_adjuste_size=$ms_adjuste_size"

    # Force the menu to start. It may remove header/footer and resize the menu
    echo "ms_always_start=$ms_always_start"

    # echo $ms_list_prefix=" - $_AEC_BLUE"
    # echo $ms_list_suffix="$_AEC_RST"
    echo "ms_list_prefix=$ms_list_prefix"
    echo "ms_list_suffix=$ms_list_suffix"
    # give the ability to redefine ms_handle_up, ms_handle_down, etc.
    echo "ms_function_pack=$ms_function_pack"
    # printed before and after the menu
    echo "ms_header=$ms_header"
    echo "ms_footer=$ms_footer"

    echo "ms_clean=$ms_clean"
}

function ms_helper()
{
    echo "Usage: menu_selector [OPTION]... [MENU_OPT]..."
    echo ""
    echo "Open a shell navigable menu. Caller can retreive user choise through:"
    echo "  __MENU_SELECTOR_POS: index of the selected item."
    echo "  __MENU_SELECTOR_RES: string value of the selected item."
    echo "menu_selector ignore void items"

    echo "Options:"
    echo "  -h        print this helper."
    echo "  -L        Menu size. Default: 5"
    echo "  -l        Add numbers to list."
    echo "  -c        Add total counter to list."
    echo "  -R        Remove the header if the shell size is too small."
    echo "  -r        Add an indicator of the remaining elements' count."
    echo "  -S        Adjust menu size if the sell is too small."
    echo "  -A        Always start even when it requires removing header and resizing"
    echo "            menu."
    echo "  -p        Prefix to the menu's element."
    echo "  -s        Suffix to the menu's element."
    echo "  -f        Function pack to use. This allow you change keybindings."
    echo "            Default value is 'ms'. Fonctions:"
    echo "            ms_handle_down: on arrow up"
    echo "            ms_handle_up:   on arrow down"
    echo "            ms_handle_left: on arrow left"
    echo "            ms_handle_right:on arrow right"
    echo "  -H        A header displayed before the menu."
    echo "  -F        A footer displayed after the menu."
    echo "  -C        clean the screen."

}

# TODO : add something expliciting the list continue
# TODO : use printf in a way that people can reset prefix & suffix directly
# TODO : add an optional pointer
# TODO : change the last line (n...m) remaining items
function menu_selector()
{
    # Begin index
    local ms_begin_index=0

    local ms_len=5
    # Display options' number
    local ms_list_num
    # Display num/count
    local ms_over_count
    # Give the possibility to remove the header when the window is too small
    local ms_remove_header
    # Indicate remaning element at end of menu
    local ms_remaining
    # Give the possibility to adjuste the size
    local ms_adjuste_size
    # Force the menu to start. It may remove header/footer and resize the menu
    local ms_always_start

    # local ms_list_prefix=" - $_AEC_BLUE"
    # local ms_list_suffix="$_AEC_RST"
    local ms_list_prefix
    local ms_list_suffix
    # give the ability to redefine ms_handle_up, ms_handle_down, etc.
    local ms_function_pack="ms"
    # printed before and after the menu
    local ms_header
    local ms_footer

    local ms_clean

    local header_size=0
    local footer_size=0

    local opt
    local OPTARG
    local OPTIND

    # I use getopts. long options are slower
    # Options :
    #
    local OPTSTRING=":hi:L:lcRrSAp:s:f:H:F:C"
    while getopts $OPTSTRING opt; do
        case $opt in
            h)
                ms_helper
                return 0
                ;;
            i)
                ms_begin_index="$OPTARG"
                ;;
            L)
                ms_len="$OPTARG"
                ;;
            l)
                ms_list_num=1
                ;;
            c)
                ms_over_count=1
                ;;
            R)
                ms_remove_header=1
                ;;
            r)
                ms_remaining=1
                ;;
            S)
                ms_adjuste_size=1
                ;;
            A)
                ms_always_start=1
                ;;
            p)
                ms_list_prefix="$OPTARG"
                ;;
            s)
                ms_list_suffix="$OPTARG"
                ;;
            f)
                ms_function_pack="$OPTARG"
                ;;
            H)
                ms_header="$OPTARG"
                ;;
            F)
                ms_footer="$OPTARG"
                ;;
            C)
                ms_clean=1
                ;;
            ?)
                echo $opt
                echo "ERROR"
                return 1
                ;;
        esac
    done

    if [[ ! -z $ms_header ]]; then
        ms_header="${ms_header}\n"
        header_size=$(printf "$ms_header" | wc -l)
    fi

    if [[ ! -z $ms_footer ]]; then
        ms_footer="\n${ms_footer}"
        footer_size=$(printf "$ms_footer" | wc -l)
    fi



    local inputs=()
    local size=$ms_len
    # fix the +1
    local w_size=$(( size + header_size + footer_size))
    local cols=$(tput cols)
    local lines=$(tput lines)
    local pos_min=0
    local pos_max=$(( size - 1 ))
    local RET=0

    # check if console is long enough
    if [[ $w_size -gt $lines ]]; then
        # TODO change this to adapt first
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
        # TODO ? do we need this condition
        if [[ $w_size -gt $lines ]]; then
            if [[ ! -z $ms_adjuste_size ]]; then
                size=$(( size - w_size + lines ))
                pos_max=$(( size - 1 ))
                w_size=$(( size + header_size + footer_size ))
            fi
        fi
        if [[ $w_size -gt $lines ]]; then
            echo -e "${_AEC_RED}Unable to start menu_selector${_AEC_RST}"
            return 1
        fi
    fi

    # TODO check
    if [[ ! -z $ms_clean ]]; then
        clear -x
    fi

    for elem in "${@:$OPTIND}"; do
        if [[ ! -z $elem ]]; then
            inputs+=("$elem")
        fi
    done
    local count=${#inputs[@]}
    local over_count=
    if  [[ ! -z $ms_over_count ]]; then
        over_count="/$((${count}-1))"
    fi

    if [[ $size -eq 1 ]]; then
        ms_remaining=''
    fi


    local position=0
    local stop=0
    local user_input

    AEC_HIDE
    print_menu_screen "$position" "$(( position+size-1 ))" "$ms_list_prefix" "$ms_list_suffix" "${inputs[@]}"
    AEC_S
    AEC_PREV_LINE $(( size+footer_size-1 ))

    if [[ $ms_begin_index -lt 0 ]] || [[ $ms_begin_index -gt $count ]]; then
        ms_begin_index=0
    else
        local go_down_num=$(( $ms_begin_index + $size/2 ))
        local go_up_num=$(( $size/2 ))
        local index
        for ((index = 0; index < go_down_num; index++)); do
            local prev_pos=$position
            ${ms_function_pack}_handle_down
            if [[ $prev_pos -eq $position ]]; then
                go_up_num=$(( $go_up_num-1 ))
                echo $go_up_num >> log.log
            fi

        done
        for ((i = 0; i < go_up_num; i++)); do
            ${ms_function_pack}_handle_up
        done
    fi


    trap -- 'AEC_U;printf "\n";AEC_SHOW;trap - INT;return 1' SIGINT
    while [[ $stop -eq 0 ]]; do
        
        AEC_SHOW
        read -rsn1 user_input # wait for user input
        AEC_HIDE
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
    AEC_SHOW
    # AEC_NEXT_LINE
    printf "\n"
    export __MENU_SELECTOR_POS=$position
    export __MENU_SELECTOR_RES=${inputs[$position]}
    return $RET
}


