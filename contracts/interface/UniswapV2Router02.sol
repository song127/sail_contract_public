pragma solidity ^0.8.0;

interface UniswapV2Router02 {
    function factory() external pure returns (address);

    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function WETH() external pure returns (address);

    // ETH to DAI
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    // DAI to ETH
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}
