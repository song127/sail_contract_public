// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface Factory {
    function getUni() external view returns (address);

    function getAaveAllow() external view returns (address);

    function getAaveEth() external view returns (address);

    function getAavePool() external view returns (address);

    function getCommissionFee() external view returns (address);
}

interface UniswapV2Router {
    function WETH() external pure returns (address);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

    // ETH to DAI
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    // DAI to ETH
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
}

interface AaveETHRouter {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address lendingPool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address lendingPool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;
}

interface AavePoolRouter {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);
}

contract SubWallet {
    // Events
    event Deposit(address, address, uint256);
    event Withdraw(address, uint256);
    event ShortStart();
    event ShortEnd();
    event ChangeOwner();
    event Receive(address, uint256);

    // Convertor
    using SafeERC20 for IERC20;

    // Clone
    // -------------------------------------------------------------------------
    Factory private _factory;
    bool private _isBase;

    address private _owner;
    modifier onlyOwner() {
        require(msg.sender == _owner, "ERROR: Only Owner");
        _;
    }

    constructor() {// base contract
        _isBase = true;
    }

    // only use at first
    function initialize(address _initOwner) external {
        require(_isBase == false, "This is the base contract");
        require(_owner == address(0), "Already initialized");
        _factory = Factory(msg.sender);
        _owner = _initOwner;
    }

    // Wallet Field
    // -------------------------------------------------------------------------
    // User Info
    mapping(address => uint256) collateralList; // DepositToken => Collateral Amount
    mapping(address => Short) shortList; // ShortToken => Short Amount
    Commission[] commissions; // CollateralToken => Commission

    struct Short {
        address token; // 담보 토큰
        uint256 amount; // 빌린 금액 ETH
        uint256 price; // 바뀐 금액 Token / 담보 토큰과 같은 토큰
    }

    struct Commission {
        address token;
        uint256 fee;
    }

    // Token action
    // -------------------------------------------------------------------------
    function approveEth(address _token, uint16 _mode, uint _amount) external onlyOwner {
        address to;
        if (_mode == 0) {
            to = _factory.getAavePool();
        } else if (_mode == 1) {
            to = _factory.getUni();
        }
        (bool success,) = address(_token).call{gas : 200000}(
            abi.encodeWithSignature("approve(address,uint256)", to, _amount)
        );
        require(success, "FAILED");
    }

    function approveTo(address _token, uint16 _mode, uint _amount) external onlyOwner {
        address to;
        if (_mode == 0) {
            to = _factory.getAavePool();
        } else if (_mode == 1) {
            to = _factory.getUni();
        }
        (bool success,) = address(_token).call{gas : 200000}(
            abi.encodeWithSignature("approve(address,uint256)", to, _amount)
        );
        require(success, "FAILED");
    }

    function multiApproveTokens(address[] memory _tokens, uint256 _amount, uint256 _ethAmount) external onlyOwner {
        address uniswap = _factory.getUni();
        address aavePool = _factory.getAavePool();

        for (uint i = 0; i < _tokens.length; i++) {
            (bool sucUni,) = address(_tokens[i]).call{gas : 200000}(
                abi.encodeWithSignature("approve(address,uint256)", uniswap, _amount)
            );
            require(sucUni, "Uni Failed");
            (bool sucPool,) = address(_tokens[i]).call{gas : 200000}(
                abi.encodeWithSignature("approve(address,uint256)", aavePool, _amount)
            );
            require(sucPool, "Pool Failed");
        }
    }

    function multiApproveEth(address[] memory _tokens, uint256 _amount, uint256 _ethAmount) external onlyOwner {
        address uniswap = _factory.getUni();
        address aavePool = _factory.getAavePool();
        address aaveAllow = _factory.getAaveAllow();
        address aaveEth = _factory.getAaveEth();

        for (uint i = 0; i < _tokens.length; i++) {
            (bool sucUni,) = address(_tokens[i]).call{gas : 200000}(
                abi.encodeWithSignature("approve(address,uint256)", uniswap, _amount)
            );
            require(sucUni, "Uni Failed");
            (bool sucPool,) = address(_tokens[i]).call{gas : 200000}(
                abi.encodeWithSignature("approve(address,uint256)", aavePool, _amount)
            );
            require(sucPool, "Pool Failed");
        }

        (bool sucAllow,) = aaveAllow.call{gas : 200000}(
            abi.encodeWithSignature("approveDelegation(address,uint256)", aaveEth, _ethAmount)
        );
        require(sucAllow, "Allow Failed");
    }

    function depositToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit Deposit(_token, msg.sender, _amount);
    }

    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Not enough token");
        IERC20(_token).transfer(msg.sender, _amount);
        emit Withdraw(_token, _amount);
    }

    // Product action
    // -------------------------------------------------------------------------
    function shortStartETH(address _collateralToken, uint256 _collateralAmount, uint256 _ethAmount) external onlyOwner {
        AavePoolRouter pool = AavePoolRouter(_factory.getAavePool());
        bool sResult = _supply(pool, _collateralToken, _collateralAmount);
        require(sResult, "Supply Failed");
        collateralList[_collateralToken] = _collateralAmount;

        AaveETHRouter gate = AaveETHRouter(_factory.getAaveEth());
        bool bResult = _borrowEth(gate, pool, _ethAmount);
        require(bResult, "Borrow Failed");

        UniswapV2Router uni = UniswapV2Router(_factory.getUni());
        uint changeAmount = _ethToToken(uni, _collateralToken, _ethAmount)[1];
        shortList[address(this)] = Short(_collateralToken, _ethAmount, changeAmount);
    }

    // token to token
    function shortStart(address _collateralToken, uint256 _collateralAmount, address _shortToken, uint256 _shortAmount) external onlyOwner {
    }

    function _supply(AavePoolRouter router, address _token, uint256 _amount) internal returns (bool) {
        try router.deposit(_token, _amount, address(this), 0) {
            return true;
        }
        catch {
            return false;
        }
    }

    function _borrowEth(AaveETHRouter router, AavePoolRouter pool, uint256 _ethAmount) internal returns (bool) {
        try router.borrowETH(address(pool), _ethAmount, 2, 0) {
            return true;
        }
        catch {
            return false;
        }
    }

    function _borrow(address _token, uint256 _amount) internal returns (bool) {
        return false;
    }

    // ETH => DAI
    function _ethToToken(UniswapV2Router router, address _token, uint256 _ethAmount) internal returns (uint[] memory) {
        uint tokenAmount = _getAmountToken(router, _token, _ethAmount)[1];
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = _token;
        uint deadline = block.timestamp + 100;

        uint[] memory amounts = router.swapExactETHForTokens{value : uint(_ethAmount)}(tokenAmount, path, payable(address(this)), deadline);
        require(amounts[0] != 0, "ETH => TOKEN FAIL");

        return amounts;
    }

    function _getAmountToken(UniswapV2Router router, address _token, uint256 _ethAmount) internal view returns (uint[] memory) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = _token;

        return router.getAmountsOut(_ethAmount, path);
    }

    // -------------------------------------------------------------------------
    function shortEndEth() external onlyOwner {
        Short memory shorted = shortList[address(this)];

        UniswapV2Router uni = UniswapV2Router(_factory.getUni());
        _tokenToEth(uni, shorted.token, shorted.amount);

        AaveETHRouter gate = AaveETHRouter(_factory.getAaveEth());
        AavePoolRouter pool = AavePoolRouter(_factory.getAavePool());
        bool rResult = _repayEth(gate, pool, shorted.amount);
        require(rResult, "Repay Fail");

        bool wResult = _withdraw(pool, shorted.token, collateralList[shorted.token]);
        require(wResult, "Withdraw Fail");

        collateralList[shorted.token] = 0;
        shortList[address(this)] = Short(address(0), 0, 0);
    }

    // DAI to Token / ETH
    // DAI => ETH
    function _tokenToEth(UniswapV2Router router,address _token, uint256 _ethAmount) internal returns (uint[] memory) {
        uint tokenAmount = _getAmountEth(router, _token, _ethAmount)[0];

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = router.WETH();
        uint deadline = block.timestamp + 100;

        uint[] memory amounts = router.swapExactTokensForETH(tokenAmount, _ethAmount, path, address(this), deadline);
        require(amounts[0] != 0, "TOKEN => ETH FAIL");

        return amounts;
    }

    function _getAmountEth(UniswapV2Router router, address _token, uint256 _ethAmount) internal view returns (uint[] memory) {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = router.WETH();

        return router.getAmountsIn(_ethAmount, path);
    }

    function _repayEth(AaveETHRouter router, AavePoolRouter pool, uint256 _ethAmount) internal returns (bool) {
        try router.repayETH{value : _ethAmount}(address(pool), _ethAmount, 2, address(this)) {
            return true;
        }
        catch {
            return false;
        }
    }

    function _repay(uint256 amount) internal returns (bool) {
        return false;
    }

    function _withdraw(AavePoolRouter pool, address _token, uint256 _amount) internal returns (bool) {
        try pool.withdraw(_token, _amount, address(this)) {
            return true;
        }
        catch {
            return false;
        }
    }

    // View
    // -------------------------------------------------------------------------
    function getCollateral(address _token) external view returns (uint) {
        return collateralList[_token];
    }

    function getShort(address _token) external view returns (address, uint, uint) {
        Short memory shorted = shortList[_token];
        return (shorted.token, shorted.amount, shorted.price);
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }
}
