#!/bin/sh
BASE_PATH=/home/ttn/Desktop/log4shell-poc
LOCAL_PATH=$(python3 -m site --user-base)/bin

# Ensure that the directory, which the scripts from the protection_model module
# are added to, is part of the PATH environment variable.
if [ ! $(echo $PATH | grep -E "(^|:)$LOCAL_PATH($|:)") ]
    then
        export PATH=$PATH:$LOCAL_PATH
fi

# Ensure that the sel4cp_set_up_access_rights utility is installed.
pip3 install -q $BASE_PATH/python_dependencies/protection_model-1.0.0-py2.py3-none-any.whl 

pip3 install -q $BASE_PATH/python_dependencies/colorama-0.4.6-py2.py3-none-any.whl
