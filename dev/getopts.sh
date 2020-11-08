#!/bin/bash

while getopts ":hp:" opt;do
    case "$opt" in
        h)
            echo "help option"
            ;;
        p)
            echo "proxy option"
            echo "argument: $OPTARG"
            ;;
        :)
            echo "need argument: $OPTARG"
            ;;
        \?)
            echo "Unknown option: $OPTARG"
            ;;
    esac
done

