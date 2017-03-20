#!/bin/sh
# By Fat Dragon, 05/24/2016
# (Re)creates replication slot.
# NOTE: The script should be executed as postgres user

echo "create_slot - Start"

# Defining default values

slot_name="{{ primary_slot_name }}"
recreate=false

debug=true

# Ensuring that 'postgres' runs the script
if [ "$(id -u)" -ne "$(id -u postgres)" ]; then

    echo "ERROR: The script must be executed as 'postgres' user."
    exit 1

fi

if [ "$slot_name" = "" ]; then

    echo "ERROR: Slot name is mandatory. For help execute 'create_slot -h'"
    exit 2

fi

if $debug; then

    echo "DEBUG: The script will be executed with the following arguments:"
    echo "DEBUG: --name=${slot_name}"

    if $recreate; then
        echo "DEBUG: --recreate"
    fi

fi

success=false

echo "INFO: Checking if slot '${slot_name}' exists..."
slotcount=$(psql -Atc "SELECT count (*) FROM pg_replication_slots WHERE slot_name='${slot_name}';") && success=true

if ! $success ; then

    echo "ERROR: Cannot check for '${slot_name}' slot existence."
    exit 4

fi

if [ "$slotcount" = "0" ]; then

    echo "INFO: Slot not found. Creating..."

    success=false
    psql -c "SELECT pg_create_physical_replication_slot('${slot_name}');" && success=true

    if ! $success ; then

        echo "ERROR: Cannot create '${slot_name}' slot."
        exit 4

    fi

elif $recreate ; then

    echo "INFO: Slot found. Removing..."

    success=false
    psql -c "SELECT pg_drop_replication_slot('${slot_name}');" && success=true

    if ! $success ; then

        echo "ERROR: Cannot drop existing '${slot_name}' slot."
        exit 4

    fi

    echo "INFO: Re-creating the slot..."

    success=false
    psql -c "SELECT pg_create_physical_replication_slot('${slot_name}');" && success=true

    if ! $success ; then

        echo "ERROR: Cannot create '${slot_name}' slot."
        exit 4

    fi

fi

echo "create_slot - Done!"
exit 0
