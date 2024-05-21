# Copyright (c) 2024 Luca Bitaudeau

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


source menu_selector.sh

function tcd_handle_up()
{
    ms_handle_up
}

function tcd_handle_down()
{
    ms_handle_down
}

function tcd_handle_left()
{
    stop=1
    left_or_right=1
    left=1
}

function tcd_handle_right()
{
    stop=1
    left_or_right=1
    right=1
}

function tcd()
{
    local dir="$(pwd)"
    local left_or_right=1
    local folders=()
    local f_filter="[^.]*"
    local cur_dir="$(pwd)"
    local prev_directory
    local menu_index=0

    if [[ $1 == '-a' ]]; then
        f_filter="*"
    fi


    while [[ $left_or_right -eq 1 ]]; do

        left_or_right=0
        left=0
        right=0
        cur_dir="$(pwd)"

        local folders=('.')
        local flrs="$(find "$cur_dir" -mindepth 1 -maxdepth 1 -type d -name "$f_filter" -printf "%f\n" | sort)"

        local index=1
        while read -r line; do
            folders+=("$line")
            if [[ "$line" == "$prev_directory" ]]; then
                menu_index=$index
            fi
            index=$(( index + 1 ))

        done < <(printf '%s\n' "$flrs")


        local args=()
        AEC_HIDE
        menu_selector -L ${#folders[@]} -i "$menu_index" -crlS -H "Current directory : ${_AEC_GREEN}${cur_dir}${_AEC_RST}" -p "- ${_AEC_BLUE}" -s "${_AEC_RST}"  -f "tcd" -C "${folders[@]}"
        AEC_HIDE
        local ret=$?

        if [[ $ret -eq 1 ]]; then
            builtin cd "$dir"
            AEC_SHOW
            return 1
        fi

        if [[ $left -eq 1 ]]; then
            prev_directory="$(basename "$PWD")"
            builtin cd ..
        fi

        if [[ $right -eq 1 ]]; then
            prev_directory=''
            builtin cd "$__MENU_SELECTOR_RES"
        fi

        menu_index=0
    done
    AEC_SHOW

    builtin cd "$cur_dir"
}