// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./VRFConsumerBase.sol";
import "./utils/Utils.sol";
import "./utils/SafeMath8.sol";

contract ThaiLottery is VRFConsumerBase, Utils {
    using SafeMath8 for uint8;

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    bytes32 public requestIdResult;

    uint256 public issueIndex = 0;
    address public adminAddress;

    uint8 ticketPrice = 80;
    // Total amount in THB in this round
    uint256 public ticketCount = 0;
    uint256 public totalAmount = 0;
    uint256 public totalReward = 0;

    // Time stamp of last transaction
    uint256 public lastTimestamp;

    // max number
    uint8 public maxNumber = 10;
    // max quota
    uint256 maxQuotaOfSameNumber = 50;
    // currentPrizeIndex
    uint8 currentPrizeIndex = 0;

    bool public drawed = false;
    bool public drawingPhase = false;

    uint8 private totalPrizeIndexs = 9;

    uint8 private indexFirstPrize = 0;
    uint8 private indexSecondPrize = 1;
    uint8 private indexThirdPrize = 2;
    uint8 private indexFourthPrize = 3;
    uint8 private indexFifthPrize = 4;
    uint8 private indexThreeDigitPrefix = 5;
    uint8 private indexThreeDigitSuffix = 6;
    uint8 private indexTwoDigitSuffix = 7;
    uint8 private indexFirstPrizeNeighbors = 8;

    bool private isFirstPrizeDrawed;
    bool private isSecondPrizeDrawed;
    bool private isThirdPrizeDrawed;
    bool private isFourthPrizeDrawed;
    bool private isFifthPrizeDrawed;
    bool private isThreeDigitPrefixDrawed;
    bool private isThreeDigitSuffixDrawed;
    bool private isTwoDigitSuffixDrawed;
    bool private isFirstPrizeNeighborsDrawed;

    uint8 private sizeFirstPrize = 1;
    uint8 private sizeSecondPrize = 5;
    uint8 private sizeThirdPrize = 10;
    uint8 private sizeFourthPrize = 50;
    uint8 private sizeFifthPrize = 100;
    uint8 private sizeThreeDigitPrefix = 2;
    uint8 private sizeThreeDigitSuffix = 2;
    uint8 private sizeTwoDigitSuffix = 1;
    uint8 private sizeFirstPrizeNeighbors = 2;

    // prize => item => numbers
    mapping(uint8 => mapping(uint8 => uint8[6])) public winningNumbers;

    // issueIndex => [tokenId]
    mapping(uint256 => uint256[]) public lotteryInfo;
    // issueIndex => number[numbers] => count
    mapping(uint256 => mapping(bytes => uint8)) public historyNumberCount;
    // issueIndex => ticketCount
    mapping(uint256 => uint256) public historyTicketCount;
    // issueIndex => totalAmount
    mapping(uint256 => uint256) public historyTotalAmount;
    // issueIndex => totalReward
    mapping(uint256 => uint256) public historyTotalReward;
    // issueIndex => prize => item => numbers
    mapping(uint256 => mapping(uint8 => mapping(uint8 => uint8[6])))
        public historyWinningNumber;

    // Old contructor (Use for deploy on remix)
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

    // constructor(
    //     address _vrfCoordinator,
    //     address _LINKToken,
    //     bytes32 _keyHash,
    //     uint256 _fee
    // )
    //     public
    //     VRFConsumerBase(
    //         _vrfCoordinator, // VRF Coordinator
    //         _LINKToken // LINK Token
    //     )
    // {
    //     keyHash = _keyHash;
    //     fee = _fee;
    //     adminAddress = msg.sender;
    // }

    function reset() external onlyAdmin {
        // user can buy on this phase
        require(drawed, "Not drawed");
        winningNumbers[indexFirstPrize][0][0] = 0;
        winningNumbers[indexFirstPrize][0][1] = 0;
        winningNumbers[indexFirstPrize][0][2] = 0;
        winningNumbers[indexFirstPrize][0][3] = 0;
        winningNumbers[indexFirstPrize][0][4] = 0;
        winningNumbers[indexFirstPrize][0][5] = 0;
        ticketCount = 0;
        issueIndex = issueIndex.add(1);
        totalAmount = 0;
        totalReward = 0;
        isFirstPrizeDrawed = false;
        isSecondPrizeDrawed = false;
        isThirdPrizeDrawed = false;
        isFourthPrizeDrawed = false;
        isFifthPrizeDrawed = false;
        isThreeDigitPrefixDrawed = false;
        isThreeDigitSuffixDrawed = false;
        isTwoDigitSuffixDrawed = false;
        isFirstPrizeNeighborsDrawed = false;
        drawed = false;
    }

    function enterDrawingPhase() external onlyAdmin {
        // user cannot buy on this phase
        require(!drawed && !drawingPhase, "Not drawed or not in drawing phase");
        drawingPhase = true;
        lastTimestamp = block.timestamp;
    }

    function afterDrawing(uint256 randomness) private {
        if (currentPrizeIndex == indexFirstPrize) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            uint8[6] memory firstPrizeNumbers =
                parseWinningNumber(randomness, indexFirstPrize);

            winningNumbers[indexFirstPrize][0] = firstPrizeNumbers;

            historyWinningNumber[issueIndex][indexFirstPrize][
                0
            ] = firstPrizeNumbers;
            isFirstPrizeDrawed = true;
        }
        if (currentPrizeIndex == indexSecondPrize) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            isSecondPrizeDrawed = true;
        }
        if (currentPrizeIndex == indexThirdPrize) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            isThirdPrizeDrawed = true;
        }
        if (currentPrizeIndex == indexFourthPrize) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            isFourthPrizeDrawed = true;
        }
        if (currentPrizeIndex == indexFifthPrize) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            isFifthPrizeDrawed = true;
        }
        if (currentPrizeIndex == indexThreeDigitPrefix) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            isThreeDigitPrefixDrawed = true;
        }
        if (currentPrizeIndex == indexThreeDigitSuffix) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            isThreeDigitSuffixDrawed = true;
        }
        if (currentPrizeIndex == indexTwoDigitSuffix) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            isTwoDigitSuffixDrawed = true;
        }
        if (currentPrizeIndex == indexFirstPrizeNeighbors) {
            require(!isFirstPrizeDrawed, "This prize is drawed");
            isFirstPrizeNeighborsDrawed = true;
        }

        drawed = true;
        drawingPhase = false;
        lastTimestamp = block.timestamp;
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
        lastTimestamp = block.timestamp;
    }

    // --------------------------------------------------

    function drawing(uint8 prizeIndex)
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
        require(prizeIndex <= totalPrizeIndexs, "Prize index overflow.");
        currentPrizeIndex = prizeIndex;
        return requestRandomness(keyHash, fee, lastTimestamp);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        requestIdResult = requestId;
        afterDrawing(randomness);
    }

    function withdrawLink() external onlyAdmin {
        require(
            LINK.transfer(msg.sender, LINK.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function parseWinningNumber(uint256 _randomNumber, uint8 prizeIndex)
        internal
        view
        returns (uint8[6] memory)
    {
        uint8[6] memory _winningNumbers;
        if (prizeIndex == indexFirstPrize) {
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
        }
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

    // Update admin address by the previous admin.
    function setAdmin(address _adminAddress) external onlyAdmin {
        adminAddress = _adminAddress;
    }

    function checkWonTicket(uint256 _issueIndex, uint8[6] memory _numbers)
        external
        view
        returns (bool)
    {
        return
            isWonFirstPrize(_issueIndex, _numbers) ||
            isWonSecondPrize(_issueIndex, _numbers) ||
            isWonThirdPrize(_issueIndex, _numbers) ||
            isWonFourthPrize(_issueIndex, _numbers) ||
            isWonFifthPrize(_issueIndex, _numbers) ||
            isWonThreeDigitPrefix(_issueIndex, _numbers) ||
            isWonThreeDigitSuffix(_issueIndex, _numbers) ||
            isWonTwoDigitSuffix(_issueIndex, _numbers) ||
            isWonFirstPrizeNeighbors(_issueIndex, _numbers);
    }

    function isWonFirstPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {
        return
            _numbers[0] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][0] &&
            _numbers[1] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][1] &&
            _numbers[2] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][2] &&
            _numbers[3] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][3] &&
            _numbers[4] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][4] &&
            _numbers[5] ==
            historyWinningNumber[_issueIndex][indexFirstPrize][0][5];
    }

    function isWonSecondPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {}

    function isWonThirdPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {}

    function isWonFourthPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {}

    function isWonFifthPrize(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {}

    function isWonThreeDigitPrefix(
        uint256 _issueIndex,
        uint8[6] memory _numbers
    ) public view returns (bool) {}

    function isWonThreeDigitSuffix(
        uint256 _issueIndex,
        uint8[6] memory _numbers
    ) public view returns (bool) {}

    function isWonTwoDigitSuffix(uint256 _issueIndex, uint8[6] memory _numbers)
        public
        view
        returns (bool)
    {}

    function isWonFirstPrizeNeighbors(
        uint256 _issueIndex,
        uint8[6] memory _numbers
    ) public view returns (bool) {}

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
