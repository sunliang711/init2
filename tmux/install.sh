#!/bin/bash

this=$(cd $(dirname $BASH_SOURCE) && pwd)
cd $this

user=${SUDO_USER:-$(whoami)}
home=$(eval echo ~$user)


cat<<EOF>$home/.tmux.conf
##################################################
# enable vi mode
set-window-option -g mode-keys vi
set -g display-panes-time 10000 #10s

##################################################
# set croll history limit
set -g history-limit 8000

##################################################
# secape time: fix vim esc delay in tmux problem
set -s escape-time 0

##################################################
# split window
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

##################################################
# enable mouse
set -g mouse on

##################################################
# vi mode copy
# version 2.4+
 bind-key -T copy-mode-vi 'v' send -X begin-selection
 bind-key -T copy-mode-vi 'y' send -X copy-selection

# old version
# bind-key -t vi-copy v begin-selection;
# bind-key -t vi-copy y copy-selection;

# not work
# bind-key -T vi-copy 'v' begin-selection
# bind-key -T vi-copy 'y' copy-selection

##################################################
# select pane
bind k select-pane -U
bind j select-pane -D
bind h select-pane -L
bind l select-pane -R

##################################################
# resize pane
bind H resize-pane -L 4
bind L resize-pane -R 4
bind J resize-pane -D 4
bind K resize-pane -U 4

##################################################
# edit .tmux.conf
bind e new-window -n '~/.tmux.conf' "sh -c 'vim ~/.tmux.conf && tmux source ~/.tmux.conf'"

##################################################
# search text in current pane
bind-key / copy-mode \; send-key ?

##################################################
# reload config file
bind r source-file ~/.tmux.conf \; display "Reloaded tmux config!"

##################################################
# show options
bind o show-options -g

##################################################
#highlight active pane

 # set -g window-style 'fg=colour247,bg=colour236'
 # set -g window-active-style 'fg=colour250,bg=black'
 # set -g pane-border-bg colour235
 # set -g pane-border-fg colour238
 # set -g pane-active-border-bg colour236
 # set -g pane-active-border-fg colour51
# set -g pane-active-border-style fg=colour208,bg=default
#-------------------------------------------------------#
# Pane colours
#-------------------------------------------------------#
# set active-inactive window styles
set -g window-style 'fg=colour247,bg=colour236'
set -g window-active-style 'fg=default,bg=colour234'

# # Pane border
# set -g pane-border-bg default
# set -g pane-border-fg colour238

# # Active pane border
# set -g pane-active-border-bg default
# set -g pane-active-border-fg blue
EOF

