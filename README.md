# StudentATM
a multi-account ATM simulation written entirely in 16-bit 8086 assembly language. It's a persistent application, meaning all account data is saved to a file named ATMDATA.BIN and reloaded every time the program starts.

Core Features:

Multi-Account System: The program manages multiple user accounts (currently 3 by default). Each account has its own unique account number, PIN, balance, and status.

Persistent Storage: All transactions (deposits, withdrawals, PIN changes, and account status updates) are saved directly to the ATMDATA.BIN file, so all changes are permanent between sessions.

Authentication & Security:

It first prompts for a 4-digit Account Number. (Entering 0000 is a "secret" command to exit the program).

If the account is found, it prompts for a 4-digit PIN.

PIN entry is completely invisible (no characters or asterisks are echoed to the screen) to prevent "shoulder surfing."

It features a 3-strike PIN limit. If a user enters the wrong PIN three times, the account's status is set to "Blocked" and saved to the file, preventing any future logins for that account.

Banking Functions:

Check Balance: Displays the account's current balance.

Deposit: Allows the user to deposit funds.

Withdraw: Allows the user to withdraw funds, but only if the amount is a multiple of 100, between 200 and 50,000, and not more than the current balance.

Change PIN: Allows the user to set a new 4-digit PIN.

Logout: Exits the current account and returns to the main "Enter Account Number" screen.

16-Bit Limitation: Because it is a .MODEL SMALL 16-bit program, all amounts are handled by 16-bit registers. This means the maximum value for any balance or transaction is 65,535.
