 # This code for Patient Record Management System for managing test entries.
# Add New Test Entry:
Prompts for a patient ID (7 digits), test name (no numbers), test date (in yyyy-mm format), test result (numeric), result unit (e.g., g/dl, mg/dl, mm hg), and test status (pending, completed, or reviewed).
Appends the entered data to a record.txt file.
# Find Test by Patient ID:
Searches test records by a given 7-digit patient ID and offers four options:
View all tests for the patient.
View only abnormal tests (based on normal range in test.txt).
View tests within a specific period.
View tests by status (pending, completed, or reviewed).
# Modify Test Result:

Allows updating a specific test result for a patient by removing the existing record and appending the updated result to record.txt.
# Compute Average Test Values:

Calculates and displays the average test result for each test type in record.txt.
# Delete Test Entry:

Deletes a specific test entry for a patient by removing the corresponding record from record.txt.
# Menu System:

Displays a menu to choose the above operations, looping until the user exits
