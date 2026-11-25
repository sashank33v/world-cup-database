#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -X --no-align --tuples-only --quiet -v ON_ERROR_STOP=1 -c"

echo -e "\n~~~~~ MY SALON ~~~~~"

# Display services
while true
do
    echo -e "\nWhich service would you like?"

    SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

    while IFS="|" read -r ID NAME
    do
        echo "$ID) $NAME"
    done <<< "$SERVICES"

    read SERVICE_ID_SELECTED || exit 0

    if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]
    then
        SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id::text = '$SERVICE_ID_SELECTED'")

        if [[ -n "$SERVICE_NAME" ]]
        then
            break
        fi
    fi

    echo "Please select a valid service."
done

# Read customer phone
echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE || exit 0

SAFE_PHONE=${CUSTOMER_PHONE//\'/\'\'}

# Check existing customer
CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$SAFE_PHONE'")

if [[ -z "$CUSTOMER_ID" ]]
then
    echo -e "\nWhat's your name?"
    read CUSTOMER_NAME || exit 0

    SAFE_NAME=${CUSTOMER_NAME//\'/\'\'}

    CUSTOMER_ID=$($PSQL "INSERT INTO customers(phone, name) VALUES('$SAFE_PHONE', '$SAFE_NAME') RETURNING customer_id") || exit 1
else
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID")
fi

# Read appointment time
echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME || exit 0

SAFE_TIME=${SERVICE_TIME//\'/\'\'}

# Insert appointment
$PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SAFE_TIME')" || exit 1

# Confirmation message
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."

exit 0