// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant CFRUB = 1e18;

contract Cifrubsafe {
    address public owner;
    address public constant strategicReserve = 0x2fb074fa59c9294c71246825c1c9a0c7782d41a4;

    uint256[15] public cellNominals = [
        7800 * CFRUB,
        10600 * CFRUB,
        25200 * CFRUB,
        49100 * CFRUB,
        83300 * CFRUB,
        124000 * CFRUB,
        276300 * CFRUB,
        386800 * CFRUB,
        718400 * CFRUB,
        197200 * CFRUB,
        621300 * CFRUB,
        1155000 * CFRUB,
        443800 * CFRUB,
        880200 * CFRUB,
        1635000 * CFRUB
    ];
    uint256 public constant cellRateBP = 5;
    uint256 public constant referralBonusBP = 8;

    struct Status { 
        uint256 minActiveReferrals; 
        uint256 bonusBP; 
    }
    Status[] public statuses;

    struct Cell {
        uint8 cellType;
        uint256 amount;
        uint256 depositTime;
        uint256 lastDividendTime;
    }
    mapping(address => Cell[]) public userCells;

    struct UserProfile {
        string cardInfo;
        string trc20Wallet;
        string fullName;
        bool verified;
    }
    mapping(address => UserProfile) public userProfiles;

    mapping(address => uint256) public availableBalance;
    mapping(address => uint256) public withdrawableBalance;
    mapping(address => uint256) public dividendBalance;
    function totalCellBalance(address user) public view returns (uint256 sum) {
        Cell[] memory cells = userCells[user];
        for (uint256 i = 0; i < cells.length; i++) {
            sum += cells[i].amount;
        }
    }
    function totalBalance(address user) external view returns (uint256) {
        return availableBalance[user] + withdrawableBalance[user] + dividendBalance[user] + totalCellBalance(user);
    }

    mapping(address => address[]) public activeReferrals;
    mapping(address => uint256) public lastMonthlyTransfer;

    struct FiatRequest { 
        uint256 amount; 
        string cardInfo; 
        uint256 requestTime; 
        bool processed; 
    }
    mapping(address => FiatRequest[]) public fiatDepositRequests;
    mapping(address => FiatRequest[]) public fiatWithdrawalRequests;

    event FundsDeposited(address indexed user, uint256 amount);
    event CellPurchased(address indexed user, uint8 cellType, uint256 amount);
    event ReferralBonusPaid(address indexed referrer, address indexed referral, uint256 amount, uint8 level);
    event DividendAccrued(address indexed user, uint256 amount);
    event MonthlyTransfer(address indexed user, uint256 amount);
    event WithdrawalProcessed(address indexed user, uint256 amount);
    event TransferToAvailable(address indexed user, uint256 amount);
    event ProfileUpdated(address indexed user, string cardInfo, string trc20Wallet, string fullName, bool verified);
    event FiatDepositRequested(address indexed user, uint256 amount, string cardInfo, uint256 requestTime);
    event FiatDepositProcessed(address indexed user, uint256 amount, uint256 requestTime);
    event FiatWithdrawalRequested(address indexed user, uint256 amount, string cardInfo, uint256 requestTime);
    event FiatWithdrawalProcessed(address indexed user, uint256 amount, uint256 requestTime);
    event CurrencyConversion(address indexed user, string currencyCode, uint256 amount, uint256 convertedAmount);
    event OfflinePayment(address indexed sender, address indexed recipient, uint256 amount);
    event SellOrderPlaced(address indexed seller, uint256 amount, uint256 pricePerUnit);
    event BuyOrderPlaced(address indexed buyer, uint256 amount, uint256 pricePerUnit);

    modifier onlyOwner() { 
        require(msg.sender == owner, "Only owner"); 
        _; 
    }

    constructor() {
        owner = msg.sender;
        statuses.push(Status(3, 50));
        statuses.push(Status(9, 90));
        statuses.push(Status(15, 130));
        statuses.push(Status(20, 180));
        statuses.push(Status(30, 230));
        statuses.push(Status(38, 280));
        statuses.push(Status(45, 330));
        statuses.push(Status(75, 400));
        statuses.push(Status(100, 450));
        statuses.push(Status(120, 530));
    }

    function depositFunds() external payable {
        require(msg.value > 0, "Must send some ether");
        availableBalance[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function purchaseCell(uint8 cellType, address referrer) external {
        require(cellType >= 1 && cellType <= 15, "Invalid cell type");
        uint256 requiredAmount = cellNominals[cellType - 1];
        require(availableBalance[msg.sender] >= requiredAmount, "Insufficient available balance");
        availableBalance[msg.sender] -= requiredAmount;
        Cell memory newCell = Cell({
            cellType: cellType,
            amount: requiredAmount,
            depositTime: block.timestamp,
            lastDividendTime: block.timestamp
        });
        userCells[msg.sender].push(newCell);
        emit CellPurchased(msg.sender, cellType, requiredAmount);
        if (referrer != address(0) && referrer != msg.sender) {
            bool exists = false;
            for (uint256 i = 0; i < activeReferrals[referrer].length; i++) {
                if (activeReferrals[referrer][i] == msg.sender) { 
                    exists = true; 
                    break; 
                }
            }
            if (!exists) {
                activeReferrals[referrer].push(msg.sender);
                uint256 bonusAmount = (requiredAmount * 10) / 100;
                emit ReferralBonusPaid(referrer, msg.sender, bonusAmount, 1);
            }
        }
    }

    function transferToAvailableBalance(uint256 amount) external {
        require(withdrawableBalance[msg.sender] >= amount, "Insufficient withdrawable balance");
        withdrawableBalance[msg.sender] -= amount;
        availableBalance[msg.sender] += amount;
        emit TransferToAvailable(msg.sender, amount);
    }

    function totalCellBalance(address user) public view returns (uint256 sum) {
        Cell[] memory cells = userCells[user];
        for (uint256 i = 0; i < cells.length; i++) { 
            sum += cells[i].amount; 
        }
    }
    
    function totalBalance(address user) external view returns (uint256) {
        return availableBalance[user] + withdrawableBalance[user] + dividendBalance[user] + totalCellBalance(user);
    }

    function computeDailyDividends(address user) public view returns (uint256 totalDividends) {
        Cell[] memory cells = userCells[user];
        uint256 daysPassed;
        for (uint256 i = 0; i < cells.length; i++) {
            daysPassed = (block.timestamp - cells[i].lastDividendTime) / 1 days;
            if (daysPassed > 0) {
                uint256 dividend = (cells[i].amount * cellRateBP * daysPassed) / 10000;
                totalDividends += dividend;
            }
        }
        uint256 totalCellSum = totalCellBalance(user);
        uint256 extraBonus = (totalCellSum * referralBonusBP * _minDaysPassed(user)) / 10000;
        totalDividends += extraBonus;
    }

    function _minDaysPassed(address user) internal view returns (uint256 minDays) {
        Cell[] memory cells = userCells[user];
        if (cells.length == 0) return 0;
        minDays = type(uint256).max;
        for (uint256 i = 0; i < cells.length; i++) {
            uint256 daysPassed = (block.timestamp - cells[i].lastDividendTime) / 1 days;
            if (daysPassed < minDays) { 
                minDays = daysPassed; 
            }
        }
    }

    function claimDividends() external {
        uint256 dividends = computeDailyDividends(msg.sender);
        require(dividends > 0, "No dividends accrued");
        for (uint256 i = 0; i < userCells[msg.sender].length; i++) {
            userCells[msg.sender][i].lastDividendTime = block.timestamp;
        }
        dividendBalance[msg.sender] += dividends;
        emit DividendAccrued(msg.sender, dividends);
    }

    function monthlyTransfer() external {
        require(block.timestamp >= lastMonthlyTransfer[msg.sender] + 90 days, "Transfer not available yet");
        uint256 amount = dividendBalance[msg.sender];
        require(amount > 0, "No dividends to transfer");
        dividendBalance[msg.sender] = 0;
        withdrawableBalance[msg.sender] += amount;
        lastMonthlyTransfer[msg.sender] = block.timestamp;
        emit MonthlyTransfer(msg.sender, amount);
    }

    function withdraw() external {
        require(_isWithdrawalWindow(), "Withdrawals allowed only on Tue/Thu between 15:00 and 21:00 MSK");
        uint256 amount = withdrawableBalance[msg.sender];
        require(amount > 0, "No funds to withdraw");
        withdrawableBalance[msg.sender] = 0;
        _maskedTransfer(msg.sender, amount);
        emit WithdrawalProcessed(msg.sender, amount);
    }

    function _isWithdrawalWindow() internal view returns (bool) {
        uint256 dayOfWeek = ((block.timestamp / 86400) + 4) % 7;
        bool validDay = (dayOfWeek == 2 || dayOfWeek == 4);
        uint256 localTime = (block.timestamp + 3 * 3600) % 86400;
        bool validTime = (localTime >= 54000 && localTime <= 75600);
        return validDay && validTime;
    }

    function _maskedTransfer(address recipient, uint256 amount) internal {
        uint256 part = amount / 3;
        (bool success1, ) = recipient.call{value: part}("");
        require(success1, "Transfer part 1 failed");
        (bool success2, ) = recipient.call{value: part}("");
        require(success2, "Transfer part 2 failed");
        uint256 remaining = amount - (part * 2);
        (bool success3, ) = recipient.call{value: remaining}("");
        require(success3, "Transfer part 3 failed");
    }

    function fiatDepositRequest(uint256 amount, string calldata cardInfo) external {
        fiatDepositRequests[msg.sender].push(FiatRequest({
            amount: amount,
            cardInfo: cardInfo,
            requestTime: block.timestamp,
            processed: false
        }));
        emit FiatDepositRequested(msg.sender, amount, cardInfo, block.timestamp);
    }
    
    function processFiatDepositRequest(address user, uint256 requestIndex) external onlyOwner {
        require(requestIndex < fiatDepositRequests[user].length, "Invalid request index");
        FiatRequest storage req = fiatDepositRequests[user][requestIndex];
        require(!req.processed, "Request already processed");
        withdrawableBalance[user] += req.amount * 1 ether;
        req.processed = true;
        emit FiatDepositProcessed(user, req.amount, req.requestTime);
    }
    
    function fiatWithdrawalRequest(uint256 amount, string calldata cardInfo) external {
        require(withdrawableBalance[msg.sender] >= amount * 1 ether, "Insufficient funds");
        fiatWithdrawalRequests[msg.sender].push(FiatRequest({
            amount: amount,
            cardInfo: cardInfo,
            requestTime: block.timestamp,
            processed: false
        }));
        emit FiatWithdrawalRequested(msg.sender, amount, cardInfo, block.timestamp);
    }
    
    function processFiatWithdrawalRequest(address user, uint256 requestIndex) external onlyOwner {
        require(requestIndex < fiatWithdrawalRequests[user].length, "Invalid request index");
        FiatRequest storage req = fiatWithdrawalRequests[user][requestIndex];
        require(!req.processed, "Request already processed");
        require(withdrawableBalance[user] >= req.amount * 1 ether, "Insufficient funds");
        withdrawableBalance[user] -= req.amount * 1 ether;
        req.processed = true;
        emit FiatWithdrawalProcessed(user, req.amount, req.requestTime);
    }

    function updateProfile(string calldata cardInfo, string calldata trc20Wallet, string calldata fullName, bool verified) external {
        userProfiles[msg.sender] = UserProfile({
            cardInfo: cardInfo,
            trc20Wallet: trc20Wallet,
            fullName: fullName,
            verified: verified
        });
        emit ProfileUpdated(msg.sender, cardInfo, trc20Wallet, fullName, verified);
    }

    function convertToCurrency(string calldata currencyCode, uint256 amount) external view returns (uint256 convertedAmount) {
        convertedAmount = amount;
        emit CurrencyConversion(msg.sender, currencyCode, amount, convertedAmount);
    }
    
    function offlinePayment(address recipient, uint256 amount) external {
        emit OfflinePayment(msg.sender, recipient, amount);
    }
    
    function placeSellOrder(uint256 amount, uint256 pricePerUnit) external {
        emit SellOrderPlaced(msg.sender, amount, pricePerUnit);
    }
    
    function placeBuyOrder(uint256 amount, uint256 pricePerUnit) external {
        emit BuyOrderPlaced(msg.sender, amount, pricePerUnit);
    }
    
    function ownerWithdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner).transfer(amount);
    }
    
    receive() external payable {}

    struct FiatRequest {
        uint256 amount;
        string cardInfo;
        uint256 requestTime;
        bool processed;
    }
}
