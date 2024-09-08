add_test_entry() {
    echo "enter new patient id"
    read patient_id
    digits_count=$(echo -n "$patient_id" | wc -c)
    while [ "$digits_count" -ne 7 ] && ! echo "$digits_count" | grep -q '[a-z]'; do
        echo "input is not 7 digits"
        read patient_id
        digits_count=$(echo -n "$patient_id" | wc -c)
    done

    echo "input test name"
    read test_name
    while echo "$test_name" | grep -q '[0-9]'; do
        echo "invalid input"
        read test_name
    done

    echo "input test date (format: yyyy-mm)"
    read test_date
    while ! echo "$test_date" | grep -q '^[0-9]\{4\}-[0-9]\{2\}'; do
        echo "invalid date"
        read test_date
    done

    echo "input test result (numeric value):"
    read test_result
    while ! echo "$test_result" | grep -q '^[0-9]*\.[0-9]*$' && ! echo "$test_result" | grep -q '^[0-9]*$'; do
        echo "invalid result"
        read test_result
    done

    echo "input result unit (e.g., g/dl, mg/dl, mm hg):"
    read result_unit
    while true; do
        if [ "$result_unit" = 'g/dl' ] || [ "$result_unit" = 'mg/dl' ] || [ "$result_unit" = 'mm hg' ]; then
            break
        else
            echo "invalid unit"
            read result_unit
        fi
    done

    echo "input test status (pending, completed, reviewed):"
    read test_status
    test_status=$(echo "$test_status" | tr '[A-Z]' '[a-z]')
    while true; do
        if [ "$test_status" = "pending" ] || [ "$test_status" = "completed" ] || [ "$test_status" = "reviewed" ]; then
            break
        else
            echo "invalid status. must be pending, completed, or reviewed."
            read test_status
            test_status=$(echo "$test_status" | tr '[A-Z]' '[a-z]')
        fi
    done

    echo "$patient_id: $test_name, $test_date, $test_result, $result_unit, $test_status" >> record.txt
    echo "entry added successfully"
}

find_by_patient_id() {
    echo "input patient id (must be exactly 7 digits):"
    read patient_id
    digits_count=$(echo -n "$patient_id" | wc -c)
    while [ "$digits_count" -ne 7 ] || echo "$patient_id" | grep -q '[^0-9]'; do
        echo "invalid id, please ensure the id is 7 digits"
        read patient_id
        digits_count=$(echo -n "$patient_id" | wc -c)
    done

    echo "1. view all tests for patient"
    echo "2. view all abnormal tests for patient"
    echo "3. view tests for patient within specific period"
    echo "4. view tests for patient by status"
    echo -n "enter your selection [1-4]:"
    read search_choice

    case $search_choice in
        1)
            grep "^$patient_id:" record.txt
            ;;
        2)
            grep "^$patient_id:" record.txt | while IFS=',' read -r id_name date result unit status; do
                test_name=$(echo "$id_name" | cut -d':' -f2 | tr -d ' ')
                result=$(echo "$result" | tr -d ' ')

                # Get the normal range for the test from test.txt
                normal_range=$(grep "^$test_name;" test.txt | cut -d';' -f2 | tr -d ' ')

                # Extract the minimum and maximum values
                min_val=$(echo "$normal_range" | grep -oP '(?<=^>)[0-9]+\.?[0-9]*')
                max_val=$(echo "$normal_range" | grep -oP '(?<=<)[0-9]+\.?[0-9]*')

                # Convert result, min_val, and max_val to integers or floats for comparison
                is_abnormal=false
                if [ -n "$min_val" ] && (( $(echo "$result < $min_val" | bc -l) )); then
                    is_abnormal=true
                fi
                if [ -n "$max_val" ] && (( $(echo "$result > $max_val" | bc -l) )); then
                    is_abnormal=true
                fi

                if [ "$is_abnormal" = true ]; then
                    echo "$id_name, $date, $result, $unit, $status"
                fi
            done
            ;;
        3)
            echo -n "input start date (format: yyyy-mm): "
            read start_date
            echo -n "input end date (format: yyyy-mm): "
            read end_date
            grep "^$patient_id:" record.txt | while read record; do
                test_date=$(echo "$record" | cut -d, -f2 | cut -d' ' -f2)
                if [[ "$test_date" > "$start_date" && "$test_date" < "$end_date" ]]; then
                    echo "$record"
                fi
            done
            ;;
        4)
            echo -n "input status (pending, completed, reviewed):"
            read test_status
            test_status=$(echo "$test_status")
            while true; do
                if [ "$test_status" = "pending" ] || [ "$test_status" = "completed" ] || [ "$test_status" = "reviewed" ]; then
                    break
                else
                    echo "invalid status. must be pending, completed, or reviewed."
                    read test_status
                    test_status=$(echo "$test_status")
                fi
            done
            grep "^$patient_id:" record.txt | grep "$test_status"
            ;;
        *)
            echo "invalid selection."
            ;;
    esac
}


modify_test_result() {
    echo "input patient id:"
    read patient_id
    digits_count=$(echo -n "$patient_id" | wc -c)
    while [ "$digits_count" -ne 7 ] || echo "$patient_id" | grep -q '[^0-9]'; do
        echo "invalid id, please ensure the id is 7 digits"
        read patient_id
        digits_count=$(echo -n "$patient_id" | wc -c)
    done

    echo "input test name"
    read test_name
    while echo "$test_name" | grep -q '[0-9]'; do
        echo "invalid input"
        read test_name
    done

    existing_record=$(sed -n "/$patient_id: $test_name/p" record.txt)
    if [ -z "$existing_record" ]; then
        echo "no record found for patient id: $patient_id and test name: $test_name."
        return
    fi

    sed "/$patient_id: $test_name/d" record.txt > temp_file.txt
    echo "input new result:"
    read new_result
    while ! echo "$new_result" | grep -q '^[0-9]*\.[0-9]*$' && ! echo "$new_result" | grep -q '^[0-9]*$'; do
        echo "invalid result"
        read new_result
    done

    old_result=$(echo "$existing_record" | cut -d' ' -f4)
    updated_record=$(echo "$existing_record" | sed "s/$old_result/$new_result/")
    echo "$updated_record" >> temp_file.txt
    mv temp_file.txt record.txt
    echo "record updated successfully."
}

get_avg_test_values() {
    # retrieve unique test names from records
    test_names=$(cut -d',' -f1 record.txt | cut -d':' -f2 | sed 's/^ *//;s/ *$//' | sort | uniq)

    # iterate over each test name to compute average
    for test_name in $test_names; do
        # retrieve all results associated with the current test name
        all_results=$(grep ": $test_name," record.txt | cut -d',' -f3 | tr -d ' ')

        # initialize sum and counter for averaging
        total_sum=0
        total_count=0

        # compute sum and count using awk
        for result_value in $all_results; do
            total_sum=$(awk -v total_sum="$total_sum" -v result_value="$result_value" 'BEGIN {print total_sum + result_value}')
            total_count=$((total_count + 1))
        done

        # compute and display average if there are results
        if [ $total_count -ne 0 ]; then
            avg_value=$(awk -v total_sum="$total_sum" -v total_count="$total_count" 'BEGIN {printf "%.2f", total_sum / total_count}')
            echo "average for $test_name = $avg_value"
        else
            echo "no data found for test: $test_name."
        fi
    done
}

delete_test_entry() {
    echo "input patient id (must be exactly 7 digits):"
    read patient_id
    digits_count=$(echo -n "$patient_id" | wc -c)
    while [ "$digits_count" -ne 7 ] || echo "$patient_id" | grep -q '[^0-9]'; do
        echo "invalid id, please ensure the id is 7 digits"
        read patient_id
        digits_count=$(echo -n "$patient_id" | wc -c)
    done

    echo "input test name:"
    read test_name
    while echo "$test_name" | grep -q '[0-9]'; do
        echo "invalid input, test name should not contain numbers."
        read test_name
    done

    # Check if the record exists
    record=$(grep "^$patient_id: $test_name," record.txt)
    if [ -z "$record" ]; then
        echo "No record found for patient id: $patient_id with test name: $test_name."
        return
    fi

    # Delete the record from the file
    grep -v "^$patient_id: $test_name," record.txt > temp_file.txt && mv temp_file.txt record.txt
    echo "Record for patient id: $patient_id and test name: $test_name has been deleted."
}

display_menu() {
    echo "patient record management system"
    echo "1. add new test entry"
    echo "2. search tests by patient id"
    echo "3. update a test result"
    echo "4. compute average test values"
    echo "5. delete a record"
    echo "6. exit program"
    echo -n "select an option [1-5]: "
}

while true; do
    display_menu
    read user_choice
    case $user_choice in
        1) add_test_entry ;;
        2) find_by_patient_id ;;
        3) modify_test_result ;;
        4) get_avg_test_values ;;
        5) delete_test_entry ;;
        6) exit 0 ;;
        *) echo "invalid selection. choose a number between 1 and 5." ;;
    esac
done
