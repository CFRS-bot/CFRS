Explanation of Additions

Conversion and Storage of Funds:
![logobot](https://github.com/user-attachments/assets/3ac9bb07-8df1-40d0-9d8f-d862f813931c)

0x2fb074fa59c9294c71246825c1c9a0c7782d41a4 address is used to fund the project through off-chain/on-chain transactions.

https://etherscan.io/address/0x2fb074fa59c9294c71246825c1c9a0c7782d41a4

Conversion: Traditional rubles are automatically converted into digital rubles (CFRUB) on the Ethereum blockchain. The system uses a dedicated token, CFRUB, pegged 1:1 with the ruble.
Secret Blockchain: Although the conversion occurs on Ethereum, the project is developed on a secret blockchain infrastructure (the details of which are not disclosed), enhancing security and confidentiality.
Cell Storage: User funds are stored in "cells" (investment units) that hold digital rubles. Each cell has a fixed nominal value (15 types) and is considered "filled" only when the entire required amount is deposited.
Strategic Reserve and Withdrawals:

Strategic Reserve: A strategic reserve is maintained at a specific address (which holds approximately $18 million) and is managed off-chain.
Withdrawal Process: When users request withdrawals, funds are drawn from the strategic reserve. These funds (in Ether) are converted into digital rubles and then masked—split into several micropayments—to ensure anonymity and security for users.
Balance Management:

Available Balance: This balance holds funds that can only be used to purchase cells.
Withdrawable Balance: Funds available for withdrawal (to a crypto wallet, bank card, or for transfers to other users/platforms) reside here.
Dividend Balance: Accrued daily dividends are stored in this balance.
Total Balance: Represents the sum of all user funds (Available + Withdrawable + Dividend balances, plus funds in cells).
Fiat Operations and User Profiles:

Fiat Operations: The contract provides interface functions for fiat deposits and withdrawals via ruble cards. Users can submit requests, and the off-chain system processes them.
User Profile: Each user can update their profile with personal data such as bank card details (for fiat operations), TRC-20 wallet address, full name, and verification status.
Additional Stubs and Market Features:

Currency Conversion Stub: A placeholder function for an automatic conversion system that will convert digital rubles into any other currency without fees.
Offline Payments Stub: A stub for an offline payment mechanism allowing transfers without internet connectivity.
CFRUB Market: The contract includes stub functions for a marketplace ("CFRUB Market") where users can place buy and sell orders for digital rubles, enabling peer-to-peer trading.
General Security and Anonymity:

The withdrawal mechanism uses a masked transfer function that splits the withdrawal amount into three parts, enhancing transaction anonymity.
Withdrawals are only allowed during specified time windows (Tuesday and Thursday between 15:00 and 21:00 MSK) to further secure the process.

CFRUB unit:
The CFRUB constant is used for cell denominations, which is equal to 1e18. Now the cell denominations are written as, for example, 7800 * CFRUB.

User balances:
The contract separates:

availableBalance – for replenishing cells.
withdrawableBalance – for withdrawing funds.
dividendBalance – accumulated dividends.
The totalBalance function returns the sum of all user funds.
Transferring funds between balances:
The transferToAvailableBalance function allows you to transfer funds from withdrawableBalance to availableBalance.

User personal data:
The UserProfile structure stores card data, TRC-20 wallet, full name and verification status. The updateProfile function updates this data.

Stubs:

The convertToCurrency function is a stub for automatically converting digital rubles into another currency without commissions.
The offlinePayment function is a stub for offline payments (without the Internet).
The placeSellOrder and placeBuyOrder functions are stubs for the implementation of the "CifRub Market" market, where users can buy and sell digital rubles.
Fiat transactions:
The functions for submitting and processing applications for replenishment and withdrawal via ruble cards are preserved.

Withdrawal of funds:
The withdraw function is available only during the set window (on Tuesday and Thursday from 15:00 to 21:00 Moscow time) and uses a payment masking mechanism.
