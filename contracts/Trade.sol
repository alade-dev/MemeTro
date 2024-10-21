// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TransferHelper.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract TradingContract is Ownable {
    uint256 public slippage;
    uint256 public tokenThreshold;
    uint256 public totalTokenBought;
    address public router;
    address public token;

    event TradeSuccessful(uint amount, address token, address receiver);
    event SlippageUpdated(uint previousSlippage, uint newSlippage);
    event RouterUpdated(address previousRouter, address newRouter);
    event TokenBought(uint amount, address buyer, uint totalBought);
    event TokenThresholdReached(uint totalBought, uint threshold);

    constructor(address _router, address _token, uint256 _tokenThreshold) {
        router = _router;
        token = _token;
        tokenThreshold = _tokenThreshold;
    }

    /**
        * @notice - This function allows users to buy the token using the native cryptocurrency.
        *           Tokens cannot be swapped until the total amount reaches the threshold.
        * @param _amount - The amount of the token to buy.
     */
    function buyToken(uint256 _amount) public payable {
        require(totalTokenBought < tokenThreshold, "Threshold reached, no more buying allowed!");
        
        uint256 _checkedTokenAmount = msg.value;

        address[] memory _path;
        _path = new address[](2);
        _path[0] = IUniswapV2Router02(router).WETH();
        _path[1] = token;

        uint256 _tokenAmount = requiredTokenAmount(_checkedTokenAmount);
        require(msg.value >= _tokenAmount, "Insufficient amount!");

        IUniswapV2Router02(router).swapETHForExactTokens{value: _tokenAmount}(
            _checkedTokenAmount,
            _path,
            address(this),
            block.timestamp
        );

        totalTokenBought += _checkedTokenAmount;

        emit TradeSuccessful(_checkedTokenAmount, msg.sender, address(this));
        emit TokenBought(_checkedTokenAmount, msg.sender, totalTokenBought);

        if (totalTokenBought >= tokenThreshold) {
            emit TokenThresholdReached(totalTokenBought, tokenThreshold);
        }
    }

    /**
        * @notice - Function to swap tokens after the threshold is met.
        * @param _amount - Amount of tokens to swap.
     */
    function swapTokens(uint _amount) public {
        require(totalTokenBought >= tokenThreshold, "Threshold not reached, cannot swap tokens yet!");

        address[] memory _path;
        _path = new address[](2);
        _path[0] = IUniswapV2Router02(router).WETH();
        _path[1] = token;

        TransferHelper.safeTransferFrom(IUniswapV2Router02(router).WETH(), msg.sender, address(this), _amount);
        _swap(_amount, _amount, _path, msg.sender);
    }

    function requiredTokenAmount(uint _amount) public view returns (uint _tokenAmount) {
        address;
        _path[0] = IUniswapV2Router02(router).WETH();
        _path[1] = token;

        uint256[] memory _tokenAmounts = IUniswapV2Router02(router).getAmountsIn(_amount, _path);
        _tokenAmount = _tokenAmounts[0] + ((_tokenAmounts[0] * slippage) / 100);
    }

    function updateRouter(address _router) public onlyOwner {
        address prevRouter = router;
        router = _router;
        emit RouterUpdated(prevRouter, router);
    }

    function updateSlippage(uint _slippage) public onlyOwner {
        uint prevSlippage = slippage;
        slippage = _slippage;
        emit SlippageUpdated(prevSlippage, slippage);
    }

    function updateTokenThreshold(uint _newThreshold) public onlyOwner {
        tokenThreshold = _newThreshold;
    }

    // Internal swap function
    function _swap(
        uint _tokenAmount,
        uint _amount,
        address[] memory _path,
        address _receiver
    ) internal returns (uint[] memory _amountOut) {
        TransferHelper.safeApprove(_path[0], router, _tokenAmount);
        _amountOut = IUniswapV2Router02(router).swapTokensForExactTokens(
            _amount,
            _tokenAmount,
            _path,
            _receiver,
            block.timestamp
        );
    }
}
