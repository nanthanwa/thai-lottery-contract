// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./VRFConsumerBase.sol";
import "./utils/Utils.sol";
import "./utils/SafeMath8.sol";

contract ThaiLottery is VRFConsumerBase, Utils {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    bytes32 public requestIdResult;

    uint256 public issueIndex = 0;
    address public adminAddress;

    uint8 ticketPrice = 80;
    // Total amount in THB in this round
    uint256 public totalAmount = 0;

    // Time stamp of last transaction
    uint256 public lastTimestamp;

    // max number
    uint8 public maxNumber = 10;
    // max quota
    uint256 maxQuotaOfSameNumber = 50;

    bool public drawed = false;
    bool public drawingPhase = false;

    uint8[6] public winningNumbers;
    uint256 public ticketCount = 0;

    using SafeMath8 for uint8;

    // issueIndex => winningNumbers[numbers]
    mapping(uint256 => uint8[6]) public historyNumbers;
    // issueIndex => [tokenId]
    mapping(uint256 => uint256[]) public lotteryInfo;
    // issueIndex => number[numbers] => count
    mapping(uint256 => mapping(bytes => uint8)) public historyNumberCount;
    // issueIndex => ticketCount
    mapping(uint256 => uint256) public historyTicketCount;
    // issueIndex => totalAmount
    mapping(uint256 => uint256) public historyTotalAmount;

    constructor()
        public
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088 // LINK Token
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10**18; // 0.1 LINK
        adminAddress = msg.sender;
    }

    function reset() external onlyAdmin {
        // user can buy on this phase
        require(drawed, "Not drawed");
        winningNumbers[0] = 0;
        winningNumbers[1] = 0;
        winningNumbers[2] = 0;
        winningNumbers[3] = 0;
        winningNumbers[4] = 0;
        winningNumbers[5] = 0;
        ticketCount = 0;
        issueIndex = issueIndex + 1;
        totalAmount = 0;
        drawed = false;
    }

    function enterDrawingPhase() external onlyAdmin {
        // user cannot buy on this phase
        require(!drawed && !drawingPhase, "Not drawed or not in drawing phase");
        drawingPhase = true;
    }

    function drawing(uint256 randomness) private {
        winningNumbers = parseWinningNumber(randomness);
        historyNumbers[issueIndex] = winningNumbers;
        drawed = true;
        drawingPhase = false;
    }

    function buy(uint8[6] memory _numbers) external validNumber(_numbers) {
        require(!drawed && !drawingPhase, "Drawn or in drawing phase");
        bytes memory numberBytes = numberToBytes(_numbers);
        require(
            historyNumberCount[issueIndex][numberBytes] < maxQuotaOfSameNumber,
            "This number of ticket is exceeded quota."
        );
        historyNumberCount[issueIndex][numberBytes] = historyNumberCount[
            issueIndex
        ][numberBytes]
            .addUint8(1);
        ticketCount = ticketCount.add(1);
        historyTicketCount[issueIndex] = ticketCount;
        totalAmount = totalAmount.add(ticketPrice);
        historyTotalAmount[issueIndex] = totalAmount;
    }

    // --------------------------------------------------

    function getRandomNumber(uint256 userProvidedSeed)
        public
        onlyAdmin
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) > fee,
            "Not enough LINK - fill contract with faucet"
        );
        // user cannot buy on this phase
        require(!drawed && drawingPhase, "Not drawned or in drawing phase");

        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        requestIdResult = requestId;
        drawing(randomness);
    }

    function withdrawLink() external onlyAdmin {
        require(
            LINK.transfer(msg.sender, LINK.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function parseWinningNumber(uint256 _randomNumber)
        internal
        pure
        returns (uint8[6] memory)
    {
        uint8[6] memory _winningNumbers;
        uint8 digit;

        assembly {
            digit := div(mod(_randomNumber, 1000000), 100000)
        }
        _winningNumbers[0] = uint8(digit);

        assembly {
            digit := div(mod(_randomNumber, 100000), 10000)
        }
        _winningNumbers[1] = uint8(digit);

        assembly {
            digit := div(mod(_randomNumber, 10000), 1000)
        }
        _winningNumbers[2] = uint8(digit);

        assembly {
            digit := div(mod(_randomNumber, 1000), 100)
        }
        _winningNumbers[3] = uint8(digit);

        assembly {
            digit := div(mod(_randomNumber, 100), 10)
        }
        _winningNumbers[4] = uint8(digit);

        assembly {
            digit := mod(_randomNumber, 10)
        }
        _winningNumbers[5] = uint8(digit);

        return _winningNumbers;
    }

    function getLinkBalance() external view returns (uint256) {
        return LINK.balanceOf(address(this));
    }

    function getPhaseMessage() external view returns (string memory) {
        if (!drawed && !drawingPhase) {
            return "Buying phase, grab the tickets now!";
        }
        if (!drawed && drawingPhase) {
            return
                "Prepare for drawing, you cannot buy the ticket at this time.";
        }
        if (drawed) {
            return
                "Drawn, congrats with the winners, the tickets will be available soon.";
        }
    }

    function getTicketRemainingOfNumber(uint8[6] memory _numbers)
        external
        view
        returns (uint256)
    {
        bytes memory numberBytes = numberToBytes(_numbers);

        return
            maxQuotaOfSameNumber.sub(
                historyNumberCount[issueIndex][numberBytes]
            );
    }

    function setMaxQuotaOfSameNumber(uint256 _newMax) external onlyAdmin {
        require(_newMax != 0, "Cannot set max quota to zero");
        maxQuotaOfSameNumber = _newMax;
    }

    function setTicketPrice(uint8 _newPrice) external onlyAdmin {
        require(_newPrice != 0, "Cannot set new price to zero");
        ticketPrice = _newPrice;
    }

    modifier validNumber(uint8[6] memory _numbers) {
        require(
            _numbers[0] < maxNumber &&
                _numbers[1] < maxNumber &&
                _numbers[2] < maxNumber &&
                _numbers[3] < maxNumber &&
                _numbers[4] < maxNumber &&
                _numbers[5] < maxNumber,
            "Overflow maxNumber"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == adminAddress,
            "Only admin can call this function."
        );
        _;
    }
}
